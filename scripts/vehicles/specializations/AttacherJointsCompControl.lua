AttacherJointsCompControl = {}

function AttacherJointsCompControl.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(AttacherJoints, specializations)
end
function AttacherJointsCompControl.initSpecialization()
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("AttacherJointsCompControl")
	v2_:addDelayedRegistrationFunc("AttacherJoint", function(p3_, p4_)
		p3_:register(XMLValueType.INT, p4_ .. ".dependentComponentJoint#index", "Index of component joint that will be adjusted while something is attached")
		p3_:register(XMLValueType.FLOAT, p4_ .. ".dependentComponentJoint#transSpringFactor", "Factor that will be applied to the spring values on attach", 1)
		p3_:register(XMLValueType.FLOAT, p4_ .. ".dependentComponentJoint#transDampingFactor", "Factor that will be applied to the damping values on attach", "#transSpringFactor")
		p3_:register(XMLValueType.FLOAT, p4_ .. ".dependentComponentJoint#referenceMass", "Reference mass for spring and damping adjustments. At the mass attached to the front, the full factor will be applied to the spring/damping. (to)", 1)
		p3_:register(XMLValueType.TIME, p4_ .. ".dependentComponentJoint#attachInterpolationTime", "Time for the interpolation between the damping values after attach", 1)
		p3_:register(XMLValueType.TIME, p4_ .. ".dependentComponentJoint#detachInterpolationTime", "Time for the interpolation between the damping values after detach", 0.5)
	end)
	v2_:setXMLSpecializationType()
end

function AttacherJointsCompControl.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setDependentComponentJointBaseFactors", AttacherJointsCompControl.setDependentComponentJointBaseFactors)
	SpecializationUtil.registerFunction(vehicleType, "addDependentComponentJointData", AttacherJointsCompControl.addDependentComponentJointData)
	SpecializationUtil.registerFunction(vehicleType, "updateDependentComponentJointValues", AttacherJointsCompControl.updateDependentComponentJointValues)
end

function AttacherJointsCompControl.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", AttacherJointsCompControl.addToPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAttacherJointFromXML", AttacherJointsCompControl.loadAttacherJointFromXML)
end

function AttacherJointsCompControl.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", AttacherJointsCompControl)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", AttacherJointsCompControl)
end

-- Local values: spec
function AttacherJointsCompControl:onPreLoad(savegame)
	self.spec_attacherJointsCompControl.dependentComponentJointData = {}
	if not self.isServer then
		SpecializationUtil.removeEventListener(self, "onStateChange", AttacherJointsCompControl)
	end
end

function AttacherJointsCompControl:onStateChange(state, data)
	if state == VehicleStateChange.ATTACH or state == VehicleStateChange.DETACH then
		self:updateDependentComponentJointValues()
	end
end

-- Local values: data
function AttacherJointsCompControl:setDependentComponentJointBaseFactors(componentJointIndex, transSpringFactor, transDampingFactor, overwrite)
	if self.isServer then
		local v16_ = self:addDependentComponentJointData(componentJointIndex)
		if v16_ ~= nil then
			if overwrite then
				v16_.baseTransSpringFactor = transSpringFactor or 1
				v16_.baseTransDampingFactor = transDampingFactor or 1
				return
			end
			v16_.baseTransSpringFactor = v16_.baseTransSpringFactor * (transSpringFactor or 1)
			v16_.baseTransDampingFactor = v16_.baseTransDampingFactor * (transDampingFactor or 1)
		end
	end
end

-- Local values: componentJoint, spec, key, data
function AttacherJointsCompControl:addDependentComponentJointData(componentJointIndex)
	if componentJointIndex == nil then
		return nil
	end
	local v_u_19_ = self.componentJoints[componentJointIndex]
	if v_u_19_ == nil then
		Logging.xmlWarning(self.xmlFile, "Unknown component joint index \'%s\' in dependentComponentJoint", componentJointIndex)
		return nil
	end
	local v20_ = self.spec_attacherJointsCompControl
	local v21_ = "dependentComponentJoint_" .. getName(v_u_19_.jointNode)
	if v20_.dependentComponentJointData[v21_] == nil then
		local v_u_25_ = {
			["interpolatorKey"] = v21_,
			["baseTransSpringFactor"] = 1,
			["baseTransDampingFactor"] = 1,
			["curTransSpringFactor"] = 1,
			["curTransDampingFactor"] = 1,
			["targetTransSpringFactor"] = 1,
			["targetTransDampingFactor"] = 1,
			["attachInterpolationTime"] = 1,
			["detachInterpolationTime"] = 0.5,
			["interpolatorGet"] = function()
				-- upvalues: (copy) v_u_25_
				return v_u_25_.curTransSpringFactor, v_u_25_.curTransDampingFactor
			end,
			["interpolatorSet"] = function(p22_, p23_)
				-- upvalues: (copy) v_u_25_, (copy) v_u_19_
				v_u_25_.curTransSpringFactor = p22_
				v_u_25_.curTransDampingFactor = p23_
				for v24_ = 1, 3 do
					setJointTranslationLimitSpring(v_u_19_.jointIndex, v24_ - 1, v_u_19_.transLimitSpring[v24_] * p22_, v_u_19_.transLimitDamping[v24_] * p23_)
				end
			end
		}
		v20_.dependentComponentJointData[v21_] = v_u_25_
	end
	return v20_.dependentComponentJointData[v21_]
end

-- Local values: spec, i, data, jointIndex, attacherJoint, mass, implement, data, scale, springFactor, dampingFactor, key, data, interpolationTime, interpolator
function AttacherJointsCompControl:updateDependentComponentJointValues(forceUpdate, skipInterpolation)
	local v29_ = self.spec_attacherJointsCompControl
	for _, v30_ in pairs(v29_.dependentComponentJointData) do
		v30_.targetTransSpringFactor = v30_.baseTransSpringFactor
		v30_.targetTransDampingFactor = v30_.baseTransDampingFactor
	end
	for v31_, v32_ in ipairs(self:getAttacherJoints()) do
		local v33_ = self:getImplementByJointDescIndex(v31_)
		local v34_ = v33_ == nil and 0 or v33_.object:getTotalMass()
		if v32_.dependentComponentJoint ~= nil then
			local v35_ = v32_.dependentComponentJoint.data
			local v36_ = v34_ / v32_.dependentComponentJoint.referenceMass
			local v37_ = math.min(v36_, 1)
			local v38_ = (v32_.dependentComponentJoint.transSpringFactor - 1) * v37_ + 1
			local v39_ = (v32_.dependentComponentJoint.transDampingFactor - 1) * v37_ + 1
			v35_.targetTransSpringFactor = v35_.targetTransSpringFactor + (v38_ - 1)
			v35_.targetTransDampingFactor = v35_.targetTransDampingFactor + (v39_ - 1)
		end
	end
	for v40_, v41_ in pairs(v29_.dependentComponentJointData) do
		if v41_.targetTransSpringFactor ~= v41_.curTransSpringFactor or (v41_.targetTransDampingFactor ~= v41_.curTransDampingFactor or forceUpdate) then
			local v42_ = v41_.attachInterpolationTime
			if v41_.targetTransSpringFactor <= v41_.baseTransSpringFactor + 0.001 and v41_.targetTransDampingFactor <= v41_.targetTransDampingFactor + 0.001 then
				v42_ = v41_.detachInterpolationTime
			end
			if skipInterpolation then
				v41_.interpolatorSet(v41_.targetTransSpringFactor, v41_.targetTransDampingFactor)
			else
				local v43_ = ValueInterpolator.new(v40_, v41_.interpolatorGet, v41_.interpolatorSet, { v41_.targetTransSpringFactor, v41_.targetTransDampingFactor }, v42_)
				if v43_ ~= nil then
					v43_:setDeleteListenerObject(self)
				end
			end
		end
	end
end

function AttacherJointsCompControl:addToPhysics(superFunc)
	if not superFunc(self) then
		return false
	end
	if self.isServer then
		self:updateDependentComponentJointValues(true, true)
	end
	return true
end

-- Local values: componentJointIndex, data
function AttacherJointsCompControl:loadAttacherJointFromXML(superFunc, attacherJoint, xmlFile, baseName, index)
	if not superFunc(self, attacherJoint, xmlFile, baseName, index) then
		return false
	end
	if self.isServer then
		local v52_ = xmlFile:getValue(baseName .. ".dependentComponentJoint#index")
		if v52_ ~= nil then
			local v53_ = self:addDependentComponentJointData(v52_)
			if v53_ ~= nil then
				v53_.attachInterpolationTime = xmlFile:getValue(baseName .. ".dependentComponentJoint#attachInterpolationTime", v53_.attachInterpolationTime)
				v53_.detachInterpolationTime = xmlFile:getValue(baseName .. ".dependentComponentJoint#detachInterpolationTime", v53_.detachInterpolationTime)
				attacherJoint.dependentComponentJoint = {}
				attacherJoint.dependentComponentJoint.data = v53_
				attacherJoint.dependentComponentJoint.transSpringFactor = xmlFile:getValue(baseName .. ".dependentComponentJoint#transSpringFactor", 1)
				attacherJoint.dependentComponentJoint.transDampingFactor = xmlFile:getValue(baseName .. ".dependentComponentJoint#transDampingFactor", attacherJoint.dependentComponentJoint.transSpringFactor)
				attacherJoint.dependentComponentJoint.referenceMass = xmlFile:getValue(baseName .. ".dependentComponentJoint#referenceMass", 1)
			end
		end
	end
	return true
end

-- Local values: spec, jointIndex, attacherJoint, mass, implement, scale, springFactor, dampingFactor, key, data
function AttacherJointsCompControl:updateDebugValues(values)
	local v56_ = self.spec_attacherJointsCompControl
	for v57_, v58_ in ipairs(self:getAttacherJoints()) do
		local v59_ = self:getImplementByJointDescIndex(v57_)
		local v60_ = v59_ == nil and 0 or v59_.object:getTotalMass()
		if v58_.dependentComponentJoint ~= nil then
			local v61_ = {
				["name"] = "Attacher Joint",
				["value"] = tostring(v57_)
			}
			table.insert(values, v61_)
			local v62_ = v60_ / v58_.dependentComponentJoint.referenceMass
			local v63_ = math.min(v62_, 1)
			local v64_ = (v58_.dependentComponentJoint.transSpringFactor - 1) * v63_ + 1
			local v65_ = (v58_.dependentComponentJoint.transDampingFactor - 1) * v63_ + 1
			local v66_ = {
				["name"] = "Mass",
				["value"] = string.format("%.2f / %.2f to", v60_, v58_.dependentComponentJoint.referenceMass)
			}
			table.insert(values, v66_)
			local v67_ = {
				["name"] = "Spring Factors",
				["value"] = string.format("spring %.2f damping %.2f", v64_, v65_)
			}
			table.insert(values, v67_)
		end
	end
	for v68_, v69_ in pairs(v56_.dependentComponentJointData) do
		table.insert(values, {
			["name"] = "Component Joint",
			["value"] = v68_
		})
		local v70_ = {
			["name"] = "Base Factors",
			["value"] = string.format("spring %.2f damping %.2f", v69_.baseTransSpringFactor, v69_.baseTransDampingFactor)
		}
		table.insert(values, v70_)
		local v71_ = {
			["name"] = "Current Factors",
			["value"] = string.format("spring %.2f damping %.2f", v69_.curTransSpringFactor, v69_.curTransDampingFactor)
		}
		table.insert(values, v71_)
	end
end
