ArticulatedAxis = {}

function ArticulatedAxis.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Drivable, specializations)
end
function ArticulatedAxis.initSpecialization()
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("ArticulatedAxis")
	v2_:register(XMLValueType.INT, "vehicle.articulatedAxis#componentJointIndex", "Index of component joint")
	v2_:register(XMLValueType.ANGLE, "vehicle.articulatedAxis#rotSpeed", "Rotation speed")
	v2_:register(XMLValueType.ANGLE, "vehicle.articulatedAxis#rotMax", "Max rotation")
	v2_:register(XMLValueType.ANGLE, "vehicle.articulatedAxis#rotMin", "Min rotation")
	v2_:register(XMLValueType.INT, "vehicle.articulatedAxis#anchorActor", "Anchor actor index", 0)
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.articulatedAxis#rotNode", "Rotation node")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.articulatedAxis#aiReverserNode", "AI reverser node")
	v2_:register(XMLValueType.FLOAT, "vehicle.articulatedAxis#maxTurningRadius", "Fixed turning radius to overwrite automatic calculations")
	v2_:register(XMLValueType.VECTOR_N, "vehicle.articulatedAxis#customWheelIndices1", "Component 1 wheel indices. Needed if wheels are not linked to component 1 directly. E.g. dolly axis")
	v2_:register(XMLValueType.VECTOR_N, "vehicle.articulatedAxis#customWheelIndices2", "Component 2 wheel indices. Needed if wheels are not linked to component 2 directly. E.g. dolly axis")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.articulatedAxis.rotatingPart(?)#node", "Rotation part node")
	v2_:register(XMLValueType.VECTOR_ROT, "vehicle.articulatedAxis.rotatingPart(?)#posRot", "Positive rotation")
	v2_:register(XMLValueType.VECTOR_ROT, "vehicle.articulatedAxis.rotatingPart(?)#negRot", "Negative rotation")
	v2_:register(XMLValueType.FLOAT, "vehicle.articulatedAxis.rotatingPart(?)#posRotFactor", "Positive rotation factor", 1)
	v2_:register(XMLValueType.FLOAT, "vehicle.articulatedAxis.rotatingPart(?)#negRotFactor", "Negative rotation factor", 1)
	v2_:register(XMLValueType.BOOL, "vehicle.articulatedAxis.rotatingPart(?)#invertSteeringAngle", "Invert steering angle", false)
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.articulatedAxis.sounds", "steering")
	v2_:setXMLSpecializationType()
end

function ArticulatedAxis.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSteeringRotTimeByCurvature", ArticulatedAxis.getSteeringRotTimeByCurvature)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTurningRadiusByRotTime", ArticulatedAxis.getTurningRadiusByRotTime)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIReverserNode", ArticulatedAxis.getAIReverserNode)
end

function ArticulatedAxis.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ArticulatedAxis)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", ArticulatedAxis)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", ArticulatedAxis)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", ArticulatedAxis)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", ArticulatedAxis)
end

-- Local values: xmlFile, spec, index, componentJoint, rotSpeed, rotMax, rotMin, _index, key, node, rotatingPart, customWheelIndices, customWheelIndices1Sorted, _, wheelIndex, customWheelIndices2Sorted, _, wheelIndex, maxRotTime, minRotTime, temp, maxTurningRadius, specWheels, j, rootNode, numFoundWheels, wheelIndex, wheel, wx, _, wz, dx1, dz1, x2, z2, dx2, dz2, l1, l2, intersect, _, f2, radius
function ArticulatedAxis:onLoad(savegame)
	local v6_ = self.xmlFile
	local v7_ = self.spec_articulatedAxis
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.articulatedAxis.rotatingPart(0)#index", "vehicle.articulatedAxis.rotatingPart(0)#node")
	local v8_ = v6_:getValue("vehicle.articulatedAxis#componentJointIndex")
	if v8_ ~= nil then
		if v8_ == 0 then
			Logging.xmlWarning(self.xmlFile, "Invalid component joint index \'0\' for articulatedAxis. Indices start with 1!")
		else
			local v9_ = self.componentJoints[v8_]
			local v10_ = v6_:getValue("vehicle.articulatedAxis#rotSpeed")
			local v11_ = v6_:getValue("vehicle.articulatedAxis#rotMax")
			local v12_ = v6_:getValue("vehicle.articulatedAxis#rotMin")
			if v9_ ~= nil and (v10_ ~= nil and (v11_ ~= nil and v12_ ~= nil)) then
				v7_.rotSpeed = v10_
				v7_.rotMax = v11_
				v7_.rotMin = v12_
				v7_.componentJoint = v9_
				v7_.anchorActor = v6_:getValue("vehicle.articulatedAxis#anchorActor", 0)
				v7_.rotationNode = v6_:getValue("vehicle.articulatedAxis#rotNode", nil, self.components, self.i3dMappings)
				if v7_.rotationNode == nil then
					v7_.rotationNode = v7_.componentJoint.jointNode
				end
				v7_.curRot = 0
				v7_.rotatingParts = {}
				for _, v13_ in v6_:iterator("vehicle.articulatedAxis.rotatingPart") do
					local v14_ = v6_:getValue(v13_ .. "#node", nil, self.components, self.i3dMappings)
					if v14_ == nil then
						Logging.xmlWarning(self.xmlFile, "Failed to load rotation part \'%s\'", v13_)
					else
						local v15_ = {
							["node"] = v14_,
							["defRot"] = { getRotation(v14_) },
							["posRot"] = v6_:getValue(v13_ .. "#posRot", nil, true)
						}
						if v15_.posRot == nil then
							Logging.xmlError(v6_, "Missing values for \'%s\'", v13_ .. "#posRot")
						else
							v15_.negRot = v6_:getValue(v13_ .. "#negRot", nil, true)
							if v15_.negRot == nil then
								Logging.xmlError(v6_, "Missing values for \'%s\'", v13_ .. "#negRot")
							else
								v15_.negRotFactor = v6_:getValue(v13_ .. "#negRotFactor", 1)
								v15_.posRotFactor = v6_:getValue(v13_ .. "#posRotFactor", 1)
								v15_.invertSteeringAngle = v6_:getValue(v13_ .. "#invertSteeringAngle", false)
								local v16_ = v7_.rotatingParts
								table.insert(v16_, v15_)
							end
						end
					end
				end
				local v17_ = {
					{},
					{}
				}
				local v18_ = v6_:getValue("vehicle.articulatedAxis#customWheelIndices1", nil, true)
				if v18_ ~= nil then
					for _, v19_ in ipairs(v18_) do
						v17_[1][v19_] = true
					end
				end
				local v20_ = v6_:getValue("vehicle.articulatedAxis#customWheelIndices2", nil, true)
				if v20_ ~= nil then
					for _, v21_ in ipairs(v20_) do
						v17_[2][v21_] = true
					end
				end
				local v22_ = v11_ / v10_
				local v23_ = v12_ / v10_
				if v22_ >= v23_ then
					local v24_ = v22_
					v22_ = v23_
					v23_ = v24_
				end
				if self.maxRotTime < v23_ then
					self.maxRotTime = v23_
				end
				if v22_ < self.minRotTime then
					self.minRotTime = v22_
				end
				self.maxRotation = v11_
				self.wheelSteeringDuration = math.sign(v10_) * v11_ / v10_
				v7_.aiReverserNode = v6_:getValue("vehicle.articulatedAxis#aiReverserNode", nil, self.components, self.i3dMappings)
				local v25_ = self.spec_wheels
				local v26_ = 0
				for v27_ = 1, 2 do
					local v28_ = self.components[v9_.componentIndices[v27_]].node
					local v29_ = 0
					for v30_, v31_ in ipairs(v25_.wheels) do
						if self:getParentComponent(v31_.repr) == v28_ or v17_[v27_][v30_] ~= nil then
							v29_ = v29_ + 1
							local v32_, _, v33_ = localToLocal(v31_.driveNode, v28_, 0, 0, 0)
							local v34_ = v32_ < 0 and -1 or 1
							local v35_ = v31_.physics.rotMin
							local v36_ = v31_.physics.rotMax
							local v37_ = math.max(v35_, v36_)
							local v38_ = math.tan(v37_)
							if v33_ > 0 then
								v38_ = -v38_
							end
							local v39_ = v32_ < 0 and -1 or 1
							local v40_ = math.max(v12_, v11_)
							local v41_ = math.tan(v40_)
							if v33_ < 0 then
								v41_ = -v41_
							end
							local v42_ = MathUtil.vector2Length(v34_, v38_)
							local v43_ = v34_ / v42_
							local v44_ = v38_ / v42_
							local v45_ = MathUtil.vector2Length(v39_, v41_)
							local v46_ = v39_ / v45_
							local v47_ = v41_ / v45_
							local v48_, _, v49_ = MathUtil.getLineLineIntersection2D(v32_, v33_, v43_, v44_, 0, 0, v46_, v47_)
							if v48_ then
								local v50_ = math.abs(v49_)
								v26_ = math.max(v26_, v50_)
							end
						end
					end
					if v29_ < 2 then
						Logging.warning("Could not find articulated axis wheels for component %d. Requires at least two wheels. Need to be added via \'customWheelIndices%d\' attribute if not directly inside the component.", v27_, v27_)
					end
				end
				if v26_ ~= 0 then
					self.maxTurningRadius = v26_
				end
				self.maxTurningRadius = v6_:getValue("vehicle.articulatedAxis#maxTurningRadius", self.maxTurningRadius)
			end
		end
	end
	if self.isClient then
		v7_.samples = {}
		v7_.samples.steering = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.articulatedAxis.sounds", "steering", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v7_.isSteeringSoundPlaying = false
	end
	v7_.interpolatedRotatedTime = 0
end

-- Local values: spec
function ArticulatedAxis:onPostLoad()
	if self.spec_articulatedAxis.componentJoint == nil then
		SpecializationUtil.removeEventListener(self, "onUpdate", ArticulatedAxis)
	elseif self.updateArticulatedAxisRotation ~= nil then
		self:updateArticulatedAxisRotation(0, 99999)
		return
	end
end

-- Local values: spec
function ArticulatedAxis:onDelete()
	if self.isClient then
		local v53_ = self.spec_articulatedAxis
		g_soundManager:deleteSamples(v53_.samples)
	end
end

-- Local values: spec
function ArticulatedAxis:onDeactivate()
	if self.isClient then
		local v55_ = self.spec_articulatedAxis
		g_soundManager:stopSamples(v55_.samples)
		v55_.isSteeringSoundPlaying = false
	end
end

-- Local values: spec, steeringAngle, isSteering, percent, _, rotPart, rx, ry, rz
function ArticulatedAxis:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v58_ = self.spec_articulatedAxis
	if v58_.interpolatedRotatedTime < self.rotatedTime then
		local v59_ = self.rotatedTime
		local v60_ = v58_.interpolatedRotatedTime
		local v61_ = v58_.rotSpeed
		local v62_ = v60_ + math.abs(v61_) * dt / 500
		v58_.interpolatedRotatedTime = math.min(v59_, v62_)
	elseif v58_.interpolatedRotatedTime > self.rotatedTime then
		local v63_ = self.rotatedTime
		local v64_ = v58_.interpolatedRotatedTime
		local v65_ = v58_.rotSpeed
		local v66_ = v64_ - math.abs(v65_) * dt / 500
		v58_.interpolatedRotatedTime = math.max(v63_, v66_)
	end
	local v67_ = self.rotatedTime * v58_.rotSpeed
	local v68_ = v58_.rotMin
	local v69_ = v58_.rotMax
	local v70_ = math.clamp(v67_, v68_, v69_)
	if self.updateArticulatedAxisRotation ~= nil then
		v70_ = self:updateArticulatedAxisRotation(v70_, dt)
	end
	if self.isClient then
		local v71_ = v70_ - v58_.curRot
		local v72_ = math.abs(v71_) > 0.0001
		if v72_ ~= v58_.isSteeringSoundPlaying then
			if v72_ then
				g_soundManager:playSample(v58_.samples.steering)
			else
				g_soundManager:stopSample(v58_.samples.steering)
			end
			v58_.isSteeringSoundPlaying = v72_
		end
	end
	local v73_ = v70_ - v58_.curRot
	if math.abs(v73_) > 1e-6 then
		if self.isServer then
			setRotation(v58_.rotationNode, 0, v70_, 0)
			self:setComponentJointFrame(v58_.componentJoint, v58_.anchorActor)
		end
		v58_.curRot = v70_
		if self.isClient then
			local v74_ = 0
			if v70_ > 0 then
				v74_ = v70_ / v58_.rotMax
			elseif v70_ < 0 then
				v74_ = v70_ / v58_.rotMin
			end
			for _, v75_ in pairs(v58_.rotatingParts) do
				local v76_, v77_, v78_
				if v70_ > 0 and not v75_.invertSteeringAngle or v70_ < 0 and v75_.invertSteeringAngle then
					local v79_ = MathUtil.vector3ArrayLerp
					local v80_ = v75_.defRot
					local v81_ = v75_.posRot
					local v82_ = v74_ * v75_.posRotFactor
					v76_, v77_, v78_ = v79_(v80_, v81_, (math.min(1, v82_)))
				else
					local v83_ = MathUtil.vector3ArrayLerp
					local v84_ = v75_.defRot
					local v85_ = v75_.negRot
					local v86_ = v74_ * v75_.negRotFactor
					v76_, v77_, v78_ = v83_(v84_, v85_, (math.min(1, v86_)))
				end
				setRotation(v75_.node, v76_, v77_, v78_)
				if self.setMovingToolDirty ~= nil then
					self:setMovingToolDirty(v75_.node)
				end
			end
		end
	end
end

function ArticulatedAxis:getSteeringRotTimeByCurvature(superFunc, curvature)
	local v89_ = self.wheelSteeringDuration
	local v90_ = math.atan(curvature)
	local v91_ = 1 / self.maxTurningRadius
	return v89_ * (v90_ / math.atan(v91_))
end

-- Local values: spec, rotSpeed, rotMax, curvature
function ArticulatedAxis:getTurningRadiusByRotTime(superFunc, rotTime)
	local v95_ = self.spec_articulatedAxis
	if v95_.componentJoint == nil or v95_.rotSpeed == 0 then
		return superFunc(self, rotTime)
	end
	local v96_ = v95_.rotSpeed
	local v97_ = self.maxRotation
	local v98_ = rotTime / (math.sign(v96_) * v97_ / v96_)
	local v99_ = 1 / self.maxTurningRadius
	local v100_ = v98_ * math.atan(v99_)
	local v101_ = -math.tan(v100_)
	return v101_ == 0 and math.huge or 1 / v101_
end

function ArticulatedAxis:getAIReverserNode(superFunc)
	return self.spec_articulatedAxis.aiReverserNode or superFunc(self)
end
