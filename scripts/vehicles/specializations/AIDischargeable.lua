AIDischargeable = {}

function AIDischargeable.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Dischargeable, specializations)
end
function AIDischargeable.initSpecialization()
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("Dischargeable")
	v2_:register(XMLValueType.BOOL, "vehicle.dischargeable.dischargeNode(?)#allowAIDischarge", "Allows ai discharge", false)
	v2_:register(XMLValueType.BOOL, "vehicle.dischargeable.dischargeableConfigurations.dischargeableConfiguration(?).dischargeNode(?)#allowAIDischarge", "Allows ai discharge", false)
	v2_:register(XMLValueType.VECTOR_3, "vehicle.dischargeable.dischargeNode(?)#aiRootNodeCustomOffsets", "An additional custom offset between the ai root node and the discharge node", false)
	v2_:register(XMLValueType.VECTOR_3, "vehicle.dischargeable.dischargeableConfigurations.dischargeableConfiguration(?).dischargeNode(?)#aiRootNodeCustomOffsets", "An additional custom offset between the ai root node and the discharge node", false)
	v2_:setXMLSpecializationType()
end

function AIDischargeable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getAIDischargeNodes", AIDischargeable.getAIDischargeNodes)
	SpecializationUtil.registerFunction(vehicleType, "getAIDischargeNodeZAlignedOffset", AIDischargeable.getAIDischargeNodeZAlignedOffset)
	SpecializationUtil.registerFunction(vehicleType, "getAICanStartDischarge", AIDischargeable.getAICanStartDischarge)
	SpecializationUtil.registerFunction(vehicleType, "startAIDischarge", AIDischargeable.startAIDischarge)
	SpecializationUtil.registerFunction(vehicleType, "stoppedAIDischarge", AIDischargeable.stoppedAIDischarge)
	SpecializationUtil.registerFunction(vehicleType, "finishedAIDischarge", AIDischargeable.finishedAIDischarge)
	SpecializationUtil.registerFunction(vehicleType, "getAIHasFinishedDischarge", AIDischargeable.getAIHasFinishedDischarge)
end

function AIDischargeable.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDischargeNode", AIDischargeable.loadDischargeNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDischargeNodeAutomaticDischarge", AIDischargeable.getDischargeNodeAutomaticDischarge)
end

function AIDischargeable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", AIDischargeable)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AIDischargeable)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AIDischargeable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AIDischargeable)
	SpecializationUtil.registerEventListener(vehicleType, "onDischargeStateChanged", AIDischargeable)
end

-- Local values: spec
function AIDischargeable:onPreLoad()
	self.spec_aiDischargeable.aiDischargeNodes = {}
end

-- Local values: spec
function AIDischargeable:onLoad()
	self.spec_aiDischargeable.currentDischargeNode = nil
end

-- Local values: spec, _, dischargeNode, _, inputAttacherJoint, x, y, z, aiRootNode, offsetX, offsetY, offsetZ
function AIDischargeable:onPostLoad()
	local v9_ = self.spec_aiDischargeable
	if v9_.aiDischargeNodes ~= nil then
		for _, v10_ in ipairs(v9_.aiDischargeNodes) do
			v10_.inputAttacherJointOffsets = {}
			if self.getInputAttacherJoints ~= nil then
				for _, v11_ in ipairs(self:getInputAttacherJoints()) do
					local v12_, v13_, v14_ = localToLocal(v10_.node, v11_.node, 0, 0, 0)
					local v15_ = v10_.inputAttacherJointOffsets
					table.insert(v15_, { v12_, v13_, v14_ })
				end
			end
			if self.getAIRootNode ~= nil then
				local v16_ = self:getAIRootNode()
				local v17_, v18_, v19_
				if v10_.aiRootNodeCustomOffsets == nil then
					v17_ = 0
					v18_ = 0
					v19_ = 0
				else
					v17_ = v10_.aiRootNodeCustomOffsets[1]
					v18_ = v10_.aiRootNodeCustomOffsets[2]
					v19_ = v10_.aiRootNodeCustomOffsets[3]
				end
				v10_.aiRootNodeOffsets = { localToLocal(v10_.node, v16_, v17_, v18_, v19_) }
			end
		end
	end
end

-- Local values: spec
function AIDischargeable:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v21_ = self.spec_aiDischargeable
	if v21_.currentDischargeNode ~= nil and (not v21_.isAIDischargeRunning and self:getAIHasFinishedDischarge(v21_.currentDischargeNode)) then
		self:finishedAIDischarge()
	end
end

-- Local values: spec, fillUnitAlreadyUsed, _, dischargeNode
function AIDischargeable:loadDischargeNode(superFunc, xmlFile, key, entry)
	if not superFunc(self, xmlFile, key, entry) then
		return false
	end
	entry.allowAIDischarge = xmlFile:getValue(key .. "#allowAIDischarge", false)
	entry.aiRootNodeCustomOffsets = xmlFile:getValue(key .. "#aiRootNodeCustomOffsets", nil, true)
	if entry.allowAIDischarge then
		local v27_ = self.spec_aiDischargeable
		local v28_ = false
		for _, v29_ in ipairs(v27_.aiDischargeNodes) do
			if v29_.fillUnitIndex == entry.fillUnitIndex then
				v28_ = true
				break
			end
		end
		if v28_ then
			Logging.xmlWarning(xmlFile, "Discharge node fill unit index already used for AI. Discharge node will be ignored for \'%s\'", key)
		else
			local v30_ = v27_.aiDischargeNodes
			table.insert(v30_, entry)
		end
	end
	return true
end

function AIDischargeable:getDischargeNodeAutomaticDischarge(superFunc, dischargeNode)
	if Platform.gameplay.automaticDischarge and self:getIsAIActive() then
		return false
	else
		return superFunc(self, dischargeNode)
	end
end

-- Local values: spec
function AIDischargeable:onDischargeStateChanged(state)
	local v36_ = self.spec_aiDischargeable
	if v36_.currentDischargeNode ~= nil and (v36_.isAIDischargeRunning and state == Dischargeable.DISCHARGE_STATE_OFF) then
		self:stoppedAIDischarge()
	end
end

-- Local values: spec
function AIDischargeable:getAIDischargeNodes()
	return self.spec_aiDischargeable.aiDischargeNodes
end

-- Local values: index, inputAttacherOffsets, offsetX, offsetY, offsetZ, currentVehicle, nextVehicle, attacherJoint, nextInputAttacherJointIndex, offsets, x, y, z, xDir, yDir, zDir, xUp, yUp, zUp, xNorm, yNorm, zNorm, nextOffsetX, nextOffsetY, nextOffsetZ, attacherJoint, offsets, x, y, z, xDir, yDir, zDir, xUp, yUp, zUp, xNorm, yNorm, zNorm, targetOffsetX, targetOffsetY, targetOffsetZ
function AIDischargeable:getAIDischargeNodeZAlignedOffset(dischargeNode, targetVehicle)
	if targetVehicle == self then
		return dischargeNode.aiRootNodeOffsets[1], dischargeNode.aiRootNodeOffsets[2], dischargeNode.aiRootNodeOffsets[3]
	end
	local v41_ = self:getActiveInputAttacherJointDescIndex()
	local v42_ = dischargeNode.inputAttacherJointOffsets[v41_]
	local v43_ = v42_[1]
	local v44_ = v42_[2]
	local v45_ = v42_[3]
	local v46_ = self:getAttacherVehicle()
	while targetVehicle ~= v46_ do
		local v47_ = v46_:getAttacherJointDescFromObject(self)
		local v48_ = v46_:getActiveInputAttacherJointDescIndex()
		local v49_ = v47_.inputAttacherJointOffsets[v48_]
		local v50_, v51_, v52_, v53_, v54_, v55_, v56_, v57_, v58_, v59_, v60_, v61_ = unpack(v49_)
		local v62_ = v50_ + v59_ * v43_ + v56_ * v44_ + v53_ * v45_
		local v63_ = v51_ + v60_ * v43_ + v57_ * v44_ + v54_ * v45_
		v45_ = v52_ + v61_ * v43_ + v58_ * v44_ + v55_ * v45_
		local v64_ = v46_:getAttacherVehicle()
		v44_ = v63_
		v43_ = v62_
		self = v46_
		v46_ = v64_
	end
	local v65_ = targetVehicle:getAttacherJointDescFromObject(self).aiRootNodeOffset
	local v66_, v67_, v68_, v69_, v70_, v71_, v72_, v73_, v74_, v75_, v76_, v77_ = unpack(v65_)
	return v66_ + v75_ * v43_ + v72_ * v44_ + v69_ * v45_, v67_ + v76_ * v43_ + v73_ * v44_ + v70_ * v45_, v68_ + v77_ * v43_ + v74_ * v44_ + v71_ * v45_
end

function AIDischargeable:getAICanStartDischarge(dischargeNode)
	return self:getCanDischargeToObject(dischargeNode)
end

-- Local values: spec
function AIDischargeable:startAIDischarge(dischargeNode, task)
	local v83_ = self.spec_aiDischargeable
	v83_.currentDischargeNode = dischargeNode
	v83_.task = task
	v83_.isAIDischargeRunning = true
	self:setDischargeState(Dischargeable.DISCHARGE_STATE_OBJECT)
end

-- Local values: spec
function AIDischargeable:stoppedAIDischarge()
	self.spec_aiDischargeable.isAIDischargeRunning = false
end

-- Local values: spec
function AIDischargeable:finishedAIDischarge()
	local v86_ = self.spec_aiDischargeable
	if v86_.task ~= nil then
		v86_.task:finishedDischarge()
	end
	v86_.currentDischargeNode = nil
	v86_.task = nil
end

function AIDischargeable:getAIHasFinishedDischarge(dischargeNode)
	return true
end
