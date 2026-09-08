SlopeCompensation = {}
SlopeCompensation.SLOPE_COLLISION_MASK = CollisionFlag.STATIC_OBJECT + CollisionFlag.TERRAIN + CollisionFlag.TERRAIN_DELTA

function SlopeCompensation.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Wheels, specializations)
end
function SlopeCompensation.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("slopeCompensation", g_i18n:getText("shop_configuration"), "slopeCompensation", VehicleConfigurationItem)
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("SlopeCompensation")
	SlopeCompensation.registerXMLPaths(v2_, "vehicle.slopeCompensation")
	SlopeCompensation.registerXMLPaths(v2_, "vehicle.slopeCompensation.slopeCompensationConfigurations.slopeCompensationConfiguration(?)")
	v2_:addDelayedRegistrationFunc("AnimatedVehicle:part", function(p3_, p4_)
		p3_:register(XMLValueType.INT, p4_ .. "#slopeCompensationNodeIndex", "Index in the XML of the slope compensation node")
		p3_:register(XMLValueType.FLOAT, p4_ .. "#startSlopeCompensationLevel", "Start slope compensation level")
		p3_:register(XMLValueType.FLOAT, p4_ .. "#endSlopeCompensationLevel", "End slope compensation level")
	end)
	v2_:setXMLSpecializationType()
	Vehicle.xmlSchemaSavegame:register(XMLValueType.ANGLE, "vehicles.vehicle(?).slopeCompensation.compensationNode(?)#lastAngle", "Last angle of compensation node")
end

-- Local values: compensationNodePath
function SlopeCompensation.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.ANGLE, basePath .. "#threshold", "Update threshold for animation", 0.1)
	schema:register(XMLValueType.BOOL, basePath .. "#highUpdateFrequency", "Defines if the angle is updated every frame or every seconds frame", false)
	local v7_ = basePath .. ".compensationNode(?)"
	schema:addDelayedRegistrationPath(v7_, "SlopeCompensation:compensationNode")
	schema:register(XMLValueType.INT, v7_ .. "#wheel1", "Wheel index 1")
	schema:register(XMLValueType.INT, v7_ .. "#wheel2", "Wheel index 2")
	schema:register(XMLValueType.NODE_INDEX, v7_ .. "#wheelNode1", "Wheel node 1")
	schema:register(XMLValueType.NODE_INDEX, v7_ .. "#wheelNode2", "Wheel node 2")
	schema:register(XMLValueType.NODE_INDICES, v7_ .. "#wheelNodes1", "List of wheel nodes 1 (center of all nodes will be used for detection)")
	schema:register(XMLValueType.NODE_INDICES, v7_ .. "#wheelNodes2", "List of wheel nodes 2 (center of all nodes will be used for detection)")
	schema:register(XMLValueType.ANGLE, v7_ .. "#maxAngle", "Max. angle", 5)
	schema:register(XMLValueType.ANGLE, v7_ .. "#minAngle", "Min. angle", "Negative #maxAngle")
	schema:register(XMLValueType.ANGLE, v7_ .. "#speed", "Move speed (degree/sec)", 5)
	schema:register(XMLValueType.BOOL, v7_ .. "#inverted", "Inverted rotation", false)
	schema:register(XMLValueType.FLOAT, v7_ .. "#inActiveHeight", "Height while the compensation node is not active", 0)
	schema:register(XMLValueType.FLOAT, v7_ .. "#initialHeight", "Height while the componensation node is active and the vehicle is fully leveled", 1)
	schema:register(XMLValueType.STRING, v7_ .. "#animationName", "Animation name")
	schema:register(XMLValueType.NODE_INDEX, v7_ .. "#referenceNode", "Node that is used to detect the current angle")
	schema:register(XMLValueType.INT, v7_ .. "#referenceAxis", "Reference angle detection axis", 1)
	schema:register(XMLValueType.NODE_INDEX, v7_ .. "#rotationNode", "Node that is rotated based on the slope angle")
	schema:register(XMLValueType.INT, v7_ .. "#rotationAxis", "Rotation axis on which the rotationNode is rotated", 1)
	schema:register(XMLValueType.NODE_INDEX, v7_ .. ".animationPart(?)#node", "Node that is adjusted")
	schema:register(XMLValueType.BOOL, v7_ .. ".animationPart(?)#isLeft", "Is left or right side node")
	schema:register(XMLValueType.VECTOR_ROT, v7_ .. ".animationPart(?)#rotMin", "Min. rotation")
	schema:register(XMLValueType.VECTOR_ROT, v7_ .. ".animationPart(?)#rotMax", "Max. rotation")
	schema:register(XMLValueType.VECTOR_TRANS, v7_ .. ".animationPart(?)#transMin", "Min. translation")
	schema:register(XMLValueType.VECTOR_TRANS, v7_ .. ".animationPart(?)#transMax", "Max. translation")
end

function SlopeCompensation.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadSlopeCompensationWheels", SlopeCompensation.loadSlopeCompensationWheels)
	SpecializationUtil.registerFunction(vehicleType, "loadSlopeCompensationNodeFromXML", SlopeCompensation.loadSlopeCompensationNodeFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getSlopeCompensationAngle", SlopeCompensation.getSlopeCompensationAngle)
	SpecializationUtil.registerFunction(vehicleType, "getSlopeCompensationAngleScale", SlopeCompensation.getSlopeCompensationAngleScale)
	SpecializationUtil.registerFunction(vehicleType, "updateSlopeCompensationAngle", SlopeCompensation.updateSlopeCompensationAngle)
	SpecializationUtil.registerFunction(vehicleType, "setSlopeCompensationNodeAngle", SlopeCompensation.setSlopeCompensationNodeAngle)
end

function SlopeCompensation.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", SlopeCompensation)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", SlopeCompensation)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", SlopeCompensation)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", SlopeCompensation)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterAnimationValueTypes", SlopeCompensation)
end

-- Local values: spec, _, key, compensationNode, configurationId, configKey, _, key, compensationNode
function SlopeCompensation:onLoad(savegame)
	local v11_ = self.spec_slopeCompensation
	v11_.threshold = self.xmlFile:getValue("vehicle.slopeCompensation#threshold", 0.002)
	v11_.highUpdateFrequency = self.xmlFile:getValue("vehicle.slopeCompensation#highUpdateFrequency", false)
	v11_.lastRaycastDistance = 0
	v11_.compensationNodes = {}
	for _, v12_ in self.xmlFile:iterator("vehicle.slopeCompensation.compensationNode") do
		local v13_ = {}
		if self:loadSlopeCompensationNodeFromXML(v13_, self.xmlFile, v12_) then
			local v14_ = v11_.compensationNodes
			table.insert(v14_, v13_)
		end
	end
	local v15_ = self.configurations.slopeCompensation or 1
	local v16_ = string.format("vehicle.slopeCompensation.slopeCompensationConfigurations.slopeCompensationConfiguration(%d)", v15_ - 1)
	if self.xmlFile:hasProperty(v16_) then
		for _, v17_ in self.xmlFile:iterator(v16_ .. ".compensationNode") do
			local v18_ = {}
			if self:loadSlopeCompensationNodeFromXML(v18_, self.xmlFile, v17_) then
				local v19_ = v11_.compensationNodes
				table.insert(v19_, v18_)
			end
		end
		v11_.threshold = self.xmlFile:getValue(v16_ .. "#threshold", v11_.threshold)
		v11_.highUpdateFrequency = self.xmlFile:getValue(v16_ .. "#highUpdateFrequency", v11_.highUpdateFrequency)
	end
	if #v11_.compensationNodes == 0 then
		SpecializationUtil.removeEventListener(self, "onLoadFinished", SlopeCompensation)
		SpecializationUtil.removeEventListener(self, "onUpdate", SlopeCompensation)
		SpecializationUtil.removeEventListener(self, "onUpdateTick", SlopeCompensation)
		return
	elseif v11_.highUpdateFrequency then
		SpecializationUtil.removeEventListener(self, "onUpdateTick", SlopeCompensation)
	else
		SpecializationUtil.removeEventListener(self, "onUpdate", SlopeCompensation)
	end
end

-- Local values: spec, _, compensationNode, updateAnimation, j, compensationNode, lastAngle, j, compensationNode
function SlopeCompensation:onLoadFinished(savegame)
	local v22_ = self.spec_slopeCompensation
	for _, v23_ in ipairs(v22_.compensationNodes) do
		if v23_.animationName ~= nil then
			local v24_ = self:getSlopeCompensationAngleScale(v23_) > 0
			self:setAnimationTime(v23_.animationName, 0, v24_)
			self:setAnimationTime(v23_.animationName, 1, v24_)
			self:setAnimationTime(v23_.animationName, 0.5, v24_)
		end
	end
	if savegame == nil then
		for _, v25_ in ipairs(v22_.compensationNodes) do
			self:setSlopeCompensationNodeAngle(v25_, 0)
		end
	else
		for v26_, v27_ in ipairs(v22_.compensationNodes) do
			self:setSlopeCompensationNodeAngle(v27_, (savegame.xmlFile:getValue(string.format("%s.slopeCompensation.compensationNode(%d)#lastAngle", savegame.key, v26_ - 1), 0)))
		end
	end
end

-- Local values: spec, i, compensationNode
function SlopeCompensation:saveToXMLFile(xmlFile, key, usedModNames)
	local v31_ = self.spec_slopeCompensation
	for v32_, v33_ in ipairs(v31_.compensationNodes) do
		xmlFile:setValue(string.format("%s.compensationNode(%d)#lastAngle", key, v32_ - 1), v33_.lastAngle)
	end
end

-- Local values: spec, _, compensationNode, angle, difference, dir, limit, speedScale, newAngle
function SlopeCompensation:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v36_ = self.spec_slopeCompensation
	for _, v37_ in ipairs(v36_.compensationNodes) do
		local v38_ = v37_.detectedAngle
		local v39_ = v37_.minAngle
		local v40_ = v37_.maxAngle
		local v41_ = math.clamp(v38_, v39_, v40_) * self:getSlopeCompensationAngleScale(v37_)
		if v37_.inverted then
			v41_ = -v41_
		end
		local v42_ = v37_.targetAngle - v41_
		if math.abs(v42_) > v36_.threshold then
			v37_.targetAngle = v41_
		end
		local v43_ = v37_.targetAngle - v37_.lastAngle
		local v44_ = math.sign(v43_)
		local v45_ = v44_ > 0 and math.min or math.max
		local v46_ = v37_.lastAngle - v41_
		local v47_ = math.abs(v46_) / (v37_.speed * 1000)
		local v48_ = math.max(v47_, 0.2)
		local v49_ = math.min(v48_, 1)
		local v50_ = v45_(v37_.lastAngle + v37_.speed * dt * v44_ * v49_, v37_.targetAngle)
		if v50_ ~= v37_.lastAngle then
			self:setSlopeCompensationNodeAngle(v37_, v50_)
		end
		self:updateSlopeCompensationAngle(v37_)
	end
end

function SlopeCompensation:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	SlopeCompensation.onUpdate(self, dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
end

function SlopeCompensation:onRegisterAnimationValueTypes()
	self:registerAnimationValueType("slopeCompensationLevel", "startSlopeCompensationLevel", "endSlopeCompensationLevel", false, AnimationValueFloat, function(p57_, p58_, p59_)
		p57_.slopeCompensationNodeIndex = p58_:getValue(p59_ .. "#slopeCompensationNodeIndex")
		if p57_.slopeCompensationNodeIndex == nil then
			return false
		end
		local v60_ = p57_.slopeCompensationNodeIndex
		p57_:setWarningInformation("index: " .. tostring(v60_))
		p57_:addCompareParameters("slopeCompensationNodeIndex")
		return true
	end, function(p61_)
		if p61_.slopeCompensationNode == nil then
			local v62_ = p61_.vehicle.spec_slopeCompensation.compensationNodes[p61_.slopeCompensationNodeIndex]
			if v62_ == nil then
				Logging.xmlWarning(p61_.xmlFile, "Could not update slope compensation node level. No slope compensation node with index %d found!", p61_.slopeCompensationNodeIndex)
				p61_.startValue = nil
				return 0
			end
			p61_.slopeCompensationNode = v62_
		end
		return p61_.slopeCompensationNode.compensationLevel
	end, function(p63_, p64_)
		-- upvalues: (copy) self
		if p63_.slopeCompensationNode ~= nil then
			p63_.slopeCompensationNode.compensationLevel = p64_
			self:setSlopeCompensationNodeAngle(p63_.slopeCompensationNode, p63_.slopeCompensationNode.lastAngle)
		end
	end)
end

-- Local values: maxRadius, wheelNodes, wheelIndex, wheel, wheelNode, wheel, nodes, _, node, wheel
function SlopeCompensation:loadSlopeCompensationWheels(xmlFile, key, indexName, nodeName, nodesName)
	local v70_ = 0
	local v71_ = {}
	local v72_ = self.xmlFile:getValue(key .. "#" .. indexName)
	if v72_ ~= nil then
		local v73_ = self:getWheelFromWheelIndex(v72_)
		if v73_ == nil then
			Logging.xmlWarning(self.xmlFile, "Unable to find wheel index \'%d\' for compensation node \'%s\'", v72_, key)
			return false
		end
		local v74_ = v73_.physics.radius
		v70_ = math.max(v70_, v74_)
		local v75_ = v73_.driveNode
		table.insert(v71_, v75_)
	end
	local v76_ = self.xmlFile:getValue(key .. "#" .. nodeName, nil, self.components, self.i3dMappings)
	if v76_ ~= nil then
		local v77_ = self:getWheelByWheelNode(v76_)
		if v77_ == nil then
			Logging.xmlWarning(self.xmlFile, "Unable to find wheel for node \'%s\' for compensation node \'%s\'", getName(v76_), key)
			return false
		end
		local v78_ = v77_.physics.radius
		v70_ = math.max(v70_, v78_)
		local v79_ = v77_.driveNode
		table.insert(v71_, v79_)
	end
	local v80_ = self.xmlFile:getValue(key .. "#" .. nodesName, nil, self.components, self.i3dMappings, true)
	if v80_ ~= nil then
		for _, v81_ in ipairs(v80_) do
			local v82_ = self:getWheelByWheelNode(v81_)
			if v82_ == nil then
				Logging.xmlWarning(self.xmlFile, "Unable to find wheel for node \'%s\' for compensation node \'%s\'", getName(v81_), key)
				return false
			end
			local v83_ = v82_.physics.radius
			v70_ = math.max(v70_, v83_)
			local v84_ = v82_.driveNode
			table.insert(v71_, v84_)
		end
	end
	if #v71_ == 0 then
		return false
	else
		return true, v71_, v70_
	end
end

-- Local values: success1, wheelNodes1, maxRadius1, success2, wheelNodes2, maxRadius2, _, partKey, animationPart
function SlopeCompensation:loadSlopeCompensationNodeFromXML(compensationNode, xmlFile, key)
	compensationNode.useWheelReference = false
	compensationNode.raycastDistance = 0
	compensationNode.lastDistance1 = 0
	compensationNode.lastDistance2 = 0
	local v89_, v90_, v91_ = self:loadSlopeCompensationWheels(xmlFile, key, "wheel1", "wheelNode1", "wheelNodes1")
	local v92_, v93_, v94_ = self:loadSlopeCompensationWheels(xmlFile, key, "wheel2", "wheelNode2", "wheelNodes2")
	if v89_ and v92_ then
		compensationNode.wheelNodes1 = v90_
		compensationNode.wheelNodes2 = v93_
		compensationNode.hitPosition1 = { 0, 0, 0 }
		compensationNode.hitPosition1Valid = false
		function compensationNode.detectionCallback1(_, p95_, p96_, p97_, p98_, _, _, _, _, _, _, _)
			-- upvalues: (copy) compensationNode
			if p95_ ~= 0 then
				if getRigidBodyType(p95_) ~= RigidBodyType.STATIC then
					return true
				end
				local v99_ = compensationNode.hitPosition1
				local v100_ = compensationNode.hitPosition1
				local v101_ = compensationNode.hitPosition1
				v99_[1] = p96_
				v100_[2] = p97_
				v101_[3] = p98_
				compensationNode.hitPosition1Valid = true
			end
			return false
		end
		function compensationNode.detectionCallback2(_, p102_, p103_, p104_, p105_, _, _, _, _, _, _, p106_)
			-- upvalues: (copy) compensationNode
			if p102_ ~= 0 then
				if getRigidBodyType(p102_) ~= RigidBodyType.STATIC then
					return true
				end
				if compensationNode.hitPosition1Valid then
					local v107_ = compensationNode.hitPosition1[1]
					local v108_ = compensationNode.hitPosition1[2]
					local v109_ = compensationNode.hitPosition1[3]
					local v110_ = v108_ - p104_
					local v111_ = MathUtil.vector2Length(v107_ - p103_, v109_ - p105_)
					if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
						drawDebugLine(v107_, v108_, v109_, 1, 1, 0, p103_, p104_, p105_, 1, 1, 0, false)
						local v112_ = Utils.renderTextAtWorldPosition
						local v113_ = (v107_ + p103_) * 0.5
						local v114_ = (v108_ + p104_) * 0.5
						local v115_ = (v109_ + p105_) * 0.5
						local v116_ = string.format
						local v117_ = v110_ / v111_
						local v118_ = math.tan(v117_)
						v112_(v113_, v114_, v115_, v116_("Angle: %.2f\194\176", (math.deg(v118_))), 0.01)
					end
					local v119_ = compensationNode
					local v120_ = v110_ / v111_
					v119_.detectedAngle = math.tan(v120_)
					return false
				end
			end
			if p106_ then
				compensationNode.detectedAngle = 0
			end
			return false
		end
		local v121_ = v91_ + 1
		local v122_ = v94_ + 1
		compensationNode.raycastDistance = math.max(v121_, v122_)
		compensationNode.useWheelReference = true
	end
	compensationNode.referenceNode = self.xmlFile:getValue(key .. "#referenceNode", nil, self.components, self.i3dMappings)
	compensationNode.referenceAxis = self.xmlFile:getValue(key .. "#referenceAxis", 1)
	compensationNode.rotationNode = self.xmlFile:getValue(key .. "#rotationNode", nil, self.components, self.i3dMappings)
	compensationNode.rotationAxis = self.xmlFile:getValue(key .. "#rotationAxis", 1)
	if compensationNode.rotationNode ~= nil then
		compensationNode.rotationNodeRotation = { getRotation(compensationNode.rotationNode) }
	end
	compensationNode.maxAngle = self.xmlFile:getValue(key .. "#maxAngle", 5)
	local v123_ = self.xmlFile
	local v124_ = key .. "#minAngle"
	local v125_ = compensationNode.maxAngle
	compensationNode.minAngle = v123_:getValue(v124_, -math.deg(v125_))
	compensationNode.speed = self.xmlFile:getValue(key .. "#speed", 5) / 1000
	compensationNode.inverted = self.xmlFile:getValue(key .. "#inverted", false)
	if compensationNode.minAngle > compensationNode.maxAngle then
		local v126_ = compensationNode.maxAngle
		local v127_ = compensationNode.minAngle
		compensationNode.minAngle = v126_
		compensationNode.maxAngle = v127_
		compensationNode.inverted = true
	end
	compensationNode.targetAngle = 0
	compensationNode.lastAngle = 0
	compensationNode.detectedAngle = 0
	compensationNode.animationName = self.xmlFile:getValue(key .. "#animationName")
	compensationNode.inActiveHeight = xmlFile:getValue(key .. "#inActiveHeight", 0)
	local v128_ = xmlFile:getValue(key .. "#initialHeight", 1)
	compensationNode.initialHeightOffset = 1 - math.clamp(v128_, 0, 1)
	compensationNode.compensationLevel = 1
	compensationNode.animationParts = {}
	for _, v129_ in xmlFile:iterator(key .. ".animationPart") do
		local v130_ = {
			["node"] = xmlFile:getValue(v129_ .. "#node", nil, self.components, self.i3dMappings)
		}
		if v130_.node == nil then
			Logging.xmlWarning(xmlFile, "Failed to load slope compensation animation part \'%s\'. Missing node.", v129_)
		else
			v130_.isLeft = xmlFile:getValue(v129_ .. "#isLeft", false)
			v130_.rotMin = xmlFile:getValue(v129_ .. "#rotMin", nil, true)
			v130_.rotMax = xmlFile:getValue(v129_ .. "#rotMax", nil, true)
			v130_.transMin = xmlFile:getValue(v129_ .. "#transMin", nil, true)
			v130_.transMax = xmlFile:getValue(v129_ .. "#transMax", nil, true)
			if (v130_.rotMin == nil or v130_.rotMax == nil) and (v130_.transMin == nil or v130_.transMax == nil) then
				Logging.xmlWarning(xmlFile, "Failed to load slope compensation animation part \'%s\'. Missing values.", v129_)
			else
				v130_.lastAlpha = -1
				local v131_ = compensationNode.animationParts
				table.insert(v131_, v130_)
			end
		end
	end
	return true
end

function SlopeCompensation:getSlopeCompensationAngle(compensationNode)
	return compensationNode.detectedAngle
end

function SlopeCompensation:getSlopeCompensationAngleScale(compensationNode)
	return 1
end

-- Local values: numWheels1, x1, y1, z1, i, wx, wy, wz, numWheels2, x2, y2, z2, i, wx, wy, wz, x, y, z
function SlopeCompensation:updateSlopeCompensationAngle(compensationNode)
	if compensationNode.useWheelReference then
		local v134_ = #compensationNode.wheelNodes1
		local v135_ = 0
		local v136_ = 0
		local v137_ = 0
		for v138_ = 1, v134_ do
			local v139_, v140_, v141_ = getWorldTranslation(compensationNode.wheelNodes1[v138_])
			v135_ = v135_ + v139_
			v136_ = v136_ + v140_
			v137_ = v137_ + v141_
		end
		local v142_ = v135_ / v134_
		local v143_ = v136_ / v134_
		local v144_ = v137_ / v134_
		compensationNode.hitPosition1Valid = false
		raycastAllAsync(v142_, v143_, v144_, 0, -1, 0, compensationNode.raycastDistance, "detectionCallback1", compensationNode, SlopeCompensation.SLOPE_COLLISION_MASK)
		local v145_ = #compensationNode.wheelNodes2
		local v146_ = 0
		local v147_ = 0
		local v148_ = 0
		for v149_ = 1, v134_ do
			local v150_, v151_, v152_ = getWorldTranslation(compensationNode.wheelNodes2[v149_])
			v146_ = v146_ + v150_
			v147_ = v147_ + v151_
			v148_ = v148_ + v152_
		end
		local v153_ = v146_ / v145_
		local v154_ = v147_ / v145_
		local v155_ = v148_ / v145_
		raycastAllAsync(v153_, v154_, v155_, 0, -1, 0, compensationNode.raycastDistance, "detectionCallback2", compensationNode, SlopeCompensation.SLOPE_COLLISION_MASK)
	elseif compensationNode.referenceNode ~= nil then
		local v156_, v157_, v158_ = worldDirectionToLocal(compensationNode.referenceNode, 0, 1, 0)
		if compensationNode.referenceAxis == 1 then
			compensationNode.detectedAngle = math.atan2(v156_, v157_)
			return
		end
		if compensationNode.referenceAxis == 2 then
			compensationNode.detectedAngle = math.atan2(v156_, v158_)
			return
		end
		if compensationNode.referenceAxis == 3 then
			compensationNode.detectedAngle = math.atan2(v157_, v158_)
		end
	end
end

-- Local values: position, currentTime, _, animationPart, alpha, x, y, z, x, y, z
function SlopeCompensation:setSlopeCompensationNodeAngle(compensationNode, angle)
	local v162_ = (angle - compensationNode.minAngle) / (compensationNode.maxAngle - compensationNode.minAngle)
	if compensationNode.animationName ~= nil and self.setAnimationTime ~= nil then
		local v163_ = self:getAnimationTime(compensationNode.animationName)
		self:setAnimationStopTime(compensationNode.animationName, v162_)
		local v164_ = compensationNode.animationName
		local v165_ = v162_ - v163_
		self:playAnimation(v164_, math.sign(v165_), v163_, true)
		AnimatedVehicle.updateAnimationByName(self, compensationNode.animationName, 9999999, true)
	end
	if compensationNode.rotationNode ~= nil then
		local v166_ = compensationNode.rotationNodeRotation
		local v167_ = compensationNode.rotationNodeRotation
		local v168_ = compensationNode.rotationNodeRotation
		local v169_, v170_, v171_ = getRotation(compensationNode.rotationNode)
		v166_[1] = v169_
		v167_[2] = v170_
		v168_[3] = v171_
		compensationNode.rotationNodeRotation[compensationNode.rotationAxis] = angle
		setRotation(compensationNode.rotationNode, compensationNode.rotationNodeRotation[1], compensationNode.rotationNodeRotation[2], compensationNode.rotationNodeRotation[3])
		if self.setMovingToolDirty ~= nil then
			self:setMovingToolDirty(compensationNode.rotationNode)
		end
	end
	for _, v172_ in ipairs(compensationNode.animationParts) do
		local v173_
		if v172_.isLeft then
			local v174_ = (v162_ - 0.5) / 0.5 + compensationNode.initialHeightOffset
			v173_ = 1 - math.clamp(v174_, 0, 1)
		else
			local v175_ = v162_ / 0.5 - compensationNode.initialHeightOffset
			v173_ = math.clamp(v175_, 0, 1)
		end
		local v176_ = MathUtil.lerp(compensationNode.inActiveHeight, v173_, compensationNode.compensationLevel)
		v172_.lastAlpha = v176_
		if v172_.rotMin ~= nil then
			local v177_, v178_, v179_ = MathUtil.vector3ArrayLerp(v172_.rotMin, v172_.rotMax, v176_)
			setRotation(v172_.node, v177_, v178_, v179_)
			if self.setMovingToolDirty ~= nil then
				self:setMovingToolDirty(v172_.node)
			end
		end
		if v172_.transMin ~= nil then
			local v180_, v181_, v182_ = MathUtil.vector3ArrayLerp(v172_.transMin, v172_.transMax, v176_)
			setTranslation(v172_.node, v180_, v181_, v182_)
			if self.setMovingToolDirty ~= nil then
				self:setMovingToolDirty(v172_.node)
			end
		end
	end
	compensationNode.lastAngle = angle
end

-- Local values: spec, i, compensationNode, angle
function SlopeCompensation:updateDebugValues(values)
	local v185_ = self.spec_slopeCompensation
	for v186_, v187_ in ipairs(v185_.compensationNodes) do
		local v188_ = v187_.detectedAngle
		local v189_ = v187_.minAngle
		local v190_ = v187_.maxAngle
		local v191_ = math.clamp(v188_, v189_, v190_)
		if v187_.inverted then
			v191_ = -v191_
		end
		local v192_ = {
			["name"] = string.format("compNode %d", v186_),
			["value"] = string.format("%.2f\194\176", (math.deg(v191_)))
		}
		table.insert(values, v192_)
	end
end
