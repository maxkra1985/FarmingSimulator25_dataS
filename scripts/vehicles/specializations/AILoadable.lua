AILoadable = {}

function AILoadable.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(FillUnit, specializations)
end
function AILoadable.initSpecialization()
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("FillUnit")
	v2_:register(XMLValueType.BOOL, FillUnit.FILL_UNIT_XML_KEY .. "#allowAILoading", "Allows ai loading", false)
	v2_:register(XMLValueType.NODE_INDEX, FillUnit.FILL_UNIT_XML_KEY .. "#aiLoadingNode", "AI loading node", "exactFillRootNode")
	v2_:setXMLSpecializationType()
end

function AILoadable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getAILoadingNodeZAlignedOffset", AILoadable.getAILoadingNodeZAlignedOffset)
	SpecializationUtil.registerFunction(vehicleType, "getAIFillUnits", AILoadable.getAIFillUnits)
	SpecializationUtil.registerFunction(vehicleType, "aiPrepareLoading", AILoadable.aiPrepareLoading)
	SpecializationUtil.registerFunction(vehicleType, "aiFinishLoading", AILoadable.aiFinishLoading)
	SpecializationUtil.registerFunction(vehicleType, "aiStartLoadingFromTrigger", AILoadable.aiStartLoadingFromTrigger)
	SpecializationUtil.registerFunction(vehicleType, "aiStoppedLoadingFromTrigger", AILoadable.aiStoppedLoadingFromTrigger)
	SpecializationUtil.registerFunction(vehicleType, "aiCancelLoadingFromTrigger", AILoadable.aiCancelLoadingFromTrigger)
	SpecializationUtil.registerFunction(vehicleType, "aiFinishedLoadingFromTrigger", AILoadable.aiFinishedLoadingFromTrigger)
	SpecializationUtil.registerFunction(vehicleType, "getAIHasFinishedLoading", AILoadable.getAIHasFinishedLoading)
end

function AILoadable.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadFillUnitFromXML", AILoadable.loadFillUnitFromXML)
end

function AILoadable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", AILoadable)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AILoadable)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AILoadable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AILoadable)
end

-- Local values: spec
function AILoadable:onPreLoad()
	self.spec_aiLoadable.aiFillUnits = {}
end

-- Local values: spec
function AILoadable:onLoad()
	self.spec_aiLoadable.currentFillUnitIndex = nil
end

-- Local values: spec, _, aiFillUnit, _, inputAttacherJoint, x, y, z, aiRootNode
function AILoadable:onPostLoad()
	local v9_ = self.spec_aiLoadable
	if v9_.aiFillUnits ~= nil then
		for _, v10_ in ipairs(v9_.aiFillUnits) do
			v10_.inputAttacherJointOffsets = {}
			if self.getInputAttacherJoints ~= nil then
				for _, v11_ in ipairs(self:getInputAttacherJoints()) do
					local v12_, v13_, v14_ = localToLocal(v10_.aiLoadingNode, v11_.node, 0, 0, 0)
					local v15_ = v10_.inputAttacherJointOffsets
					table.insert(v15_, { v12_, v13_, v14_ })
				end
			end
			if self.getAIRootNode ~= nil then
				local v16_ = self:getAIRootNode()
				v10_.aiRootNodeOffsets = { localToLocal(v10_.aiLoadingNode, v16_, 0, 0, 0) }
			end
		end
	end
end

-- Local values: spec
function AILoadable:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v18_ = self.spec_aiLoadable
	if v18_.currentFillUnitIndex ~= nil and (not v18_.isAILoadingRunning and self:getAIHasFinishedLoading(v18_.currentFillUnitIndex)) then
		self:aiFinishedLoadingFromTrigger()
	end
end

-- Local values: spec
function AILoadable:loadFillUnitFromXML(superFunc, xmlFile, key, entry, index)
	if not superFunc(self, xmlFile, key, entry, index) then
		return false
	end
	entry.allowAILoading = xmlFile:getValue(key .. "#allowAILoading", false)
	if entry.allowAILoading then
		entry.aiLoadingNode = xmlFile:getValue(key .. "#aiLoadingNode", nil, self.components, self.i3dMappings) or entry.exactFillRootNode
		if entry.aiLoadingNode == nil then
			Logging.xmlWarning(self.xmlFile, "AILoadingNode not found for fillUnit \'%s\'!", key)
		else
			local v25_ = self.spec_aiLoadable.aiFillUnits
			table.insert(v25_, entry)
		end
	end
	return true
end

-- Local values: spec
function AILoadable:getAIFillUnits()
	return self.spec_aiLoadable.aiFillUnits
end

-- Local values: fillUnit, index, inputAttacherOffsets, offsetX, offsetY, offsetZ, currentVehicle, nextVehicle, attacherJoint, nextInputAttacherJointIndex, offsets, x, y, z, xDir, yDir, zDir, xUp, yUp, zUp, xNorm, yNorm, zNorm, nextOffsetX, nextOffsetY, nextOffsetZ, attacherJoint, offsets, x, y, z, xDir, yDir, zDir, xUp, yUp, zUp, xNorm, yNorm, zNorm, targetOffsetX, targetOffsetY, targetOffsetZ
function AILoadable:getAILoadingNodeZAlignedOffset(fillUnitIndex, targetVehicle)
	local v30_ = self:getFillUnitByIndex(fillUnitIndex)
	if targetVehicle == self then
		return v30_.aiRootNodeOffsets[1], v30_.aiRootNodeOffsets[2], v30_.aiRootNodeOffsets[3]
	end
	local v31_ = self:getActiveInputAttacherJointDescIndex()
	local v32_ = v30_.inputAttacherJointOffsets[v31_]
	local v33_ = v32_[1]
	local v34_ = v32_[2]
	local v35_ = v32_[3]
	local v36_ = self:getAttacherVehicle()
	while targetVehicle ~= v36_ do
		local v37_ = v36_:getAttacherJointDescFromObject(self)
		local v38_ = v36_:getActiveInputAttacherJointDescIndex()
		local v39_ = v37_.inputAttacherJointOffsets[v38_]
		local v40_, v41_, v42_, v43_, v44_, v45_, v46_, v47_, v48_, v49_, v50_, v51_ = unpack(v39_)
		local v52_ = v40_ + v49_ * v33_ + v46_ * v34_ + v43_ * v35_
		local v53_ = v41_ + v50_ * v33_ + v47_ * v34_ + v44_ * v35_
		v35_ = v42_ + v51_ * v33_ + v48_ * v34_ + v45_ * v35_
		local v54_ = v36_:getAttacherVehicle()
		v34_ = v53_
		v33_ = v52_
		self = v36_
		v36_ = v54_
	end
	local v55_ = targetVehicle:getAttacherJointDescFromObject(self).aiRootNodeOffset
	local v56_, v57_, v58_, v59_, v60_, v61_, v62_, v63_, v64_, v65_, v66_, v67_ = unpack(v55_)
	return v56_ + v65_ * v33_ + v62_ * v34_ + v59_ * v35_, v57_ + v66_ * v33_ + v63_ * v34_ + v60_ * v35_, v58_ + v67_ * v33_ + v64_ * v34_ + v61_ * v35_
end

function AILoadable:aiPrepareLoading(fillUnitIndex, task) end

-- Local values: spec
function AILoadable:aiStartLoadingFromTrigger(loadTrigger, fillUnitIndex, fillType, task)
	local v73_ = self.spec_aiLoadable
	v73_.task = task
	v73_.isAILoadingRunning = true
	v73_.currentFillUnitIndex = fillUnitIndex
	loadTrigger:setIsLoading(true, self, fillUnitIndex, fillType, false)
end

function AILoadable:aiCancelLoadingFromTrigger(loadTrigger, fillUnitIndex, fillType, task)
	loadTrigger:setIsLoading(false, self, fillUnitIndex, fillType, false)
end

-- Local values: spec
function AILoadable:aiStoppedLoadingFromTrigger()
	self.spec_aiLoadable.isAILoadingRunning = false
end

-- Local values: spec
function AILoadable:aiFinishedLoadingFromTrigger()
	local v80_ = self.spec_aiLoadable
	if v80_.task ~= nil then
		v80_.task:finishedLoading()
	end
	v80_.currentFillUnitIndex = nil
	v80_.task = nil
end

function AILoadable:aiFinishLoading(fillUnitIndex, task) end

function AILoadable:getAIHasFinishedLoading(fillUnitIndex)
	return true
end
