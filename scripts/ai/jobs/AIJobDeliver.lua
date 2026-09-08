-- Local values: AIJobDeliver_mt
AIJobDeliver = {}
AIJobDeliver.START_ERROR_LIMIT_REACHED = 1
AIJobDeliver.START_ERROR_VEHICLE_DELETED = 2
AIJobDeliver.START_ERROR_NO_PERMISSION = 3
AIJobDeliver.START_ERROR_VEHICLE_IN_USE = 4
local AIJobDeliver_mt = Class(AIJobDeliver, AIJob)

-- Upvalues: AIJobDeliver_mt
-- Local values: self, vehicleGroup, unloadTargetGroup, positionGroup, loopingGroup
function AIJobDeliver.new(isServer, customMt)
	-- upvalues: (copy) AIJobDeliver_mt
	local v4_ = AIJob.new(isServer, customMt or AIJobDeliver_mt)
	v4_.dischargeNodeInfos = {}
	v4_.driveToLoadingTask = AITaskDriveTo.new(isServer, v4_)
	v4_.waitForFillingTask = AITaskWaitForFilling.new(isServer, v4_)
	v4_.driveToUnloadingTask = AITaskDriveTo.new(isServer, v4_)
	v4_.dischargeTask = AITaskDischarge.new(isServer, v4_)
	v4_:addTask(v4_.driveToLoadingTask)
	v4_:addTask(v4_.waitForFillingTask)
	v4_:addTask(v4_.driveToUnloadingTask)
	v4_:addTask(v4_.dischargeTask)
	v4_.vehicleParameter = AIParameterVehicle.new()
	v4_.unloadingStationParameter = AIParameterUnloadingStation.new()
	v4_.loopingParameter = AIParameterLooping.new()
	v4_.positionAngleParameter = AIParameterPositionAngle.new(0.08726646259971647)
	v4_:addNamedParameter("vehicle", v4_.vehicleParameter)
	v4_:addNamedParameter("unloadingStation", v4_.unloadingStationParameter)
	v4_:addNamedParameter("looping", v4_.loopingParameter)
	v4_:addNamedParameter("positionAngle", v4_.positionAngleParameter)
	local v5_ = AIParameterGroup.new(g_i18n:getText("ai_parameterGroupTitleVehicle"))
	v5_:addParameter(v4_.vehicleParameter)
	local v6_ = AIParameterGroup.new(g_i18n:getText("ai_parameterGroupTitleUnloadingStation"))
	v6_:addParameter(v4_.unloadingStationParameter)
	local v7_ = AIParameterGroup.new(g_i18n:getText("ai_parameterGroupTitleLoadingPosition"))
	v7_:addParameter(v4_.positionAngleParameter)
	local v8_ = AIParameterGroup.new(g_i18n:getText("ai_parameterGroupTitleLooping"))
	v8_:addParameter(v4_.loopingParameter)
	local v9_ = v4_.groupedParameters
	table.insert(v9_, v5_)
	local v10_ = v4_.groupedParameters
	table.insert(v10_, v6_)
	local v11_ = v4_.groupedParameters
	table.insert(v11_, v7_)
	local v12_ = v4_.groupedParameters
	table.insert(v12_, v8_)
	return v4_
end

-- Local values: vehicle, unloadingStation, fillType, _, _, dischargeNode, _, _, z, childVehicles, _, childVehicle, _, dischargeNode, _, _, z, _, dischargeNodeInfo, maxOffset, x, z, xDir, zDir
function AIJobDeliver:setValues()
	self:resetTasks()
	local v14_ = self.vehicleParameter:getVehicle()
	if v14_ == nil then
		return
	else
		local v15_ = self.unloadingStationParameter:getUnloadingStation()
		if v15_ == nil then
			return
		else
			self.driveToUnloadingTask:setVehicle(v14_)
			self.driveToLoadingTask:setVehicle(v14_)
			self.dischargeTask:setVehicle(v14_)
			self.waitForFillingTask:setVehicle(v14_)
			self.dischargeNodeInfos = {}
			for v16_, _ in pairs(v15_:getAISupportedFillTypes()) do
				self.waitForFillingTask:addAllowedFillType(v16_)
			end
			if v14_.getAIDischargeNodes ~= nil then
				for _, v17_ in ipairs(v14_:getAIDischargeNodes()) do
					local _, _, v18_ = v14_:getAIDischargeNodeZAlignedOffset(v17_, v14_)
					local v19_ = self.dischargeNodeInfos
					table.insert(v19_, {
						["vehicle"] = v14_,
						["dischargeNode"] = v17_,
						["offsetZ"] = v18_,
						["dirty"] = true
					})
				end
			end
			local v20_ = v14_:getChildVehicles()
			for _, v21_ in ipairs(v20_) do
				if v21_.getAIDischargeNodes ~= nil then
					for _, v22_ in ipairs(v21_:getAIDischargeNodes()) do
						local _, _, v23_ = v21_:getAIDischargeNodeZAlignedOffset(v22_, v14_)
						local v24_ = self.dischargeNodeInfos
						table.insert(v24_, {
							["vehicle"] = v21_,
							["dischargeNode"] = v22_,
							["offsetZ"] = v23_,
							["dirty"] = true
						})
					end
				end
			end
			if #self.dischargeNodeInfos ~= 0 then
				table.sort(self.dischargeNodeInfos, function(p25_, p26_)
					return p25_.offsetZ > p26_.offsetZ
				end)
				for _, v27_ in ipairs(self.dischargeNodeInfos) do
					self.waitForFillingTask:addFillUnits(v27_.vehicle, v27_.dischargeNode.fillUnitIndex)
				end
				local v28_ = self.dischargeNodeInfos[#self.dischargeNodeInfos].offsetZ
				self.driveToLoadingTask:setTargetOffset(-v28_)
				self.driveToUnloadingTask:setTargetOffset(-v28_)
				local v29_, v30_ = self.positionAngleParameter:getPosition()
				if v29_ ~= nil then
					self.driveToLoadingTask:setTargetPosition(v29_, v30_)
				end
				local v31_, v32_ = self.positionAngleParameter:getDirection()
				if v31_ ~= nil then
					self.driveToLoadingTask:setTargetDirection(v31_, v32_)
				end
			end
		end
	end
end

-- Local values: isVehicleValid, vehicleErrorMessage, isUnloadingStationValid, unloadingStationErrorMessage, isPositionValid, positionErrorMessage, isValid, errorMessage
function AIJobDeliver:validate(farmId)
	self:setParameterValid(true)
	local v34_, v35_ = self.vehicleParameter:validate()
	if v34_ and #self.dischargeNodeInfos == 0 then
		v35_ = g_i18n:getText("ai_validationErrorNoAIDischargeNodesFound")
		v34_ = false
	end
	if not v34_ then
		self.vehicleParameter:setIsValid(false)
	end
	local v36_, v37_ = self.unloadingStationParameter:validate()
	if not v36_ then
		self.unloadingStationParameter:setIsValid(false)
	end
	local v38_, v39_ = self.positionAngleParameter:validate()
	if not v38_ then
		v39_ = g_i18n:getText("ai_validationErrorNoLoadingPoint")
		self.positionAngleParameter:setIsValid(false)
	end
	if v34_ then
		if not v36_ then
			v38_ = v36_
		end
	else
		v38_ = v34_
	end
	return v38_, v35_ or (v37_ or v39_)
end

-- Local values: x, z, angle, _, lastJob, dirX, _, dirZ, unloadingStations, _, unloadingStation, fillTypes
function AIJobDeliver:applyCurrentState(vehicle, mission, farmId, isDirectStart)
	AIJobDeliver:superClass().applyCurrentState(self, vehicle, mission, farmId, isDirectStart)
	self.vehicleParameter:setVehicle(vehicle)
	self.loopingParameter:setIsLooping(true)
	local v45_ = nil
	local v46_ = nil
	local v47_ = nil
	if vehicle.getLastJob ~= nil then
		local v48_ = vehicle:getLastJob()
		if v48_ ~= nil and v48_:isa(AIJobDeliver) then
			self.unloadingStationParameter:setUnloadingStation(v48_.unloadingStationParameter:getUnloadingStation())
			self.loopingParameter:setIsLooping(v48_.loopingParameter:getIsLooping())
			v45_, v46_ = v48_.positionAngleParameter:getPosition()
			v47_ = v48_.positionAngleParameter:getAngle()
		end
	end
	if v45_ == nil or v46_ == nil then
		local v49_
		v45_, v49_, v46_ = getWorldTranslation(vehicle.rootNode)
	end
	if v47_ == nil then
		local v50_, _, v51_ = localDirectionToWorld(vehicle.rootNode, 0, 0, 1)
		v47_ = MathUtil.getYRotationFromDirection(v50_, v51_)
	end
	self.positionAngleParameter:setPosition(v45_, v46_)
	self.positionAngleParameter:setAngle(v47_)
	local v52_ = {}
	for _, v53_ in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
		if g_currentMission.accessHandler:canPlayerAccess(v53_) and v53_:isa(UnloadingStation) then
			local v54_ = v53_:getAISupportedFillTypes()
			if next(v54_) ~= nil then
				table.insert(v52_, v53_)
			end
		end
	end
	table.sort(v52_, function(p55_, p56_)
		return p55_:getName() < p56_:getName()
	end)
	self.unloadingStationParameter:setValidUnloadingStations(v52_)
end

-- Local values: vehicle
function AIJobDeliver:start(farmId)
	AIJobDeliver:superClass().start(self, farmId)
	if self.isServer then
		local v59_ = self.vehicleParameter:getVehicle()
		v59_:createAgent(self.helperIndex)
		v59_:aiJobStarted(self, self.helperIndex, farmId)
	end
end

-- Local values: vehicle
function AIJobDeliver:stop(aiMessage)
	if self.isServer then
		local v62_ = self.vehicleParameter:getVehicle()
		v62_:deleteAgent()
		v62_:aiJobFinished()
	end
	AIJobDeliver:superClass().stop(self, aiMessage)
	self.dischargeNodeInfos = {}
end

-- Local values: _, dischargeNodeInfo
function AIJobDeliver:startTask(task)
	if task == self.waitForFillingTask then
		for _, v65_ in ipairs(self.dischargeNodeInfos) do
			v65_.dirty = true
		end
	end
	AIJobDeliver:superClass().startTask(self, task)
end

-- Local values: hasOneEmptyFillUnit, _, dischargeNodeInfo, vehicle, fillUnitIndex, vehicle, x, _, z, tx, tz, targetReached
function AIJobDeliver:getStartTaskIndex()
	local v67_ = false
	for _, v68_ in ipairs(self.dischargeNodeInfos) do
		if v68_.vehicle:getFillUnitFillLevel(v68_.dischargeNode.fillUnitIndex) == 0 then
			v67_ = true
			break
		end
	end
	local v69_ = self.vehicleParameter:getVehicle()
	local v70_, _, v71_ = getWorldTranslation(v69_.rootNode)
	local v72_, v73_ = self.positionAngleParameter:getPosition()
	local v74_ = v70_ - v72_
	local v75_
	if math.abs(v74_) < 1 then
		local v76_ = v71_ - v73_
		v75_ = math.abs(v76_) < 1
	else
		v75_ = false
	end
	if v75_ then
		if not v67_ then
			self.waitForFillingTask:skip()
		end
		return self.waitForFillingTask.taskIndex
	else
		if not v67_ then
			self.driveToLoadingTask:skip()
			self.waitForFillingTask:skip()
		end
		return self.driveToLoadingTask.taskIndex
	end
end

-- Local values: lastUnloadTrigger, nextFillType, nextDischargeNodeInfo, unloadingStation, _, dischargeNodeInfo, vehicle, fillUnitIndex, currentFillType, _, _, _, _, trigger, x, z, dirX, dirZ, trigger, nextTaskIndex
function AIJobDeliver:getNextTaskIndex(isSkipTask)
	if self.currentTaskIndex == self.waitForFillingTask.taskIndex or self.currentTaskIndex == self.dischargeTask.taskIndex then
		local v79_
		if self.currentTaskIndex == self.dischargeTask.taskIndex then
			v79_ = self.dischargeTask.unloadTrigger
		else
			v79_ = nil
		end
		local v80_ = self.unloadingStationParameter:getUnloadingStation()
		local v81_ = nil
		local v82_ = nil
		for _, v83_ in ipairs(self.dischargeNodeInfos) do
			if v83_.dirty then
				local v84_ = v83_.vehicle
				local v85_ = v83_.dischargeNode.fillUnitIndex
				if v84_:getFillUnitFillLevel(v85_) > 1 then
					local v86_ = v84_:getFillUnitFillType(v85_)
					if v79_ ~= nil and v79_:getIsFillTypeSupported(v86_) then
						self.dischargeTask:setDischargeNode(v84_, v83_.dischargeNode, v83_.offsetZ)
						v83_.dirty = false
						return self.currentTaskIndex
					end
					if v81_ == nil then
						local _, _, _, _, v87_ = v80_:getAITargetPositionAndDirection(v86_)
						if v87_ == nil then
							v83_.dirty = false
						else
							v82_ = v83_
							v81_ = v86_
						end
					end
				end
			end
		end
		if v81_ ~= nil then
			local v88_, v89_, v90_, v91_, v92_ = v80_:getAITargetPositionAndDirection(v81_)
			self.driveToUnloadingTask:setTargetPosition(v88_, v89_)
			self.driveToUnloadingTask:setTargetDirection(v90_, v91_)
			self.dischargeTask:setUnloadTrigger(v92_)
			self.dischargeTask:setDischargeNode(v82_.vehicle, v82_.dischargeNode, v82_.offsetZ)
			v82_.dirty = false
			return self.driveToUnloadingTask.taskIndex
		end
	end
	return AIJobDeliver:superClass().getNextTaskIndex(self, isSkipTask)
end

-- Local values: vehicle, unloadingStation, hasSpace, _, dischargeNodeInfo, dischargeVehicle, fillUnitIndex, fillTypeIndex
function AIJobDeliver:canContinueWork()
	if self.vehicleParameter:getVehicle() == nil then
		return false, AIMessageErrorVehicleDeleted.new()
	end
	local v94_ = self.unloadingStationParameter:getUnloadingStation()
	if v94_ == nil then
		return false, AIMessageErrorUnloadingStationDeleted.new()
	end
	if self.currentTaskIndex == self.waitForFillingTask.taskIndex then
		local v95_ = false
		for _, v96_ in ipairs(self.dischargeNodeInfos) do
			local v97_ = v96_.vehicle
			local v98_ = v96_.dischargeNode.fillUnitIndex
			if v97_:getFillUnitFillLevel(v98_) > 1 and v94_:getFreeCapacity(v97_:getFillUnitFillType(v98_), self.startedFarmId) > 0 then
				v95_ = true
				break
			end
		end
		if not v95_ then
			return false, AIMessageErrorUnloadingStationFull.new()
		end
	end
	return true, nil
end

-- Local values: unloadingStation, _, dischargeNodeInfo, vehicle, fillUnitIndex, fillType
function AIJobDeliver:getHasLoadedValidFillType()
	local v100_ = self.unloadingStationParameter:getUnloadingStation()
	for _, v101_ in ipairs(self.dischargeNodeInfos) do
		local v102_ = v101_.vehicle
		local v103_ = v101_.dischargeNode.fillUnitIndex
		if v102_:getFillUnitFillLevel(v103_) > 1 and v100_:getIsFillTypeAISupported((v102_:getFillUnitFillType(v103_))) then
			return true
		end
	end
	return false
end

function AIJobDeliver:getCanSkipTask()
	return self.currentTaskIndex == self.waitForFillingTask.taskIndex and (not self.waitForFillingTask.isFinished and self:getHasLoadedValidFillType()) and true or false
end

function AIJobDeliver:skipCurrentTask()
	if self.currentTaskIndex == self.waitForFillingTask.taskIndex then
		self.waitForFillingTask:skip()
	end
end

-- Local values: nodes, vehicles, _, childVehicle, nodes
function AIJobDeliver:getIsAvailableForVehicle(vehicle)
	if vehicle.createAgent == nil or (vehicle.setAITarget == nil or not vehicle:getCanStartAIVehicle()) then
		return false
	end
	if not vehicle:getIsAIJobSupported(ClassUtil.getClassNameByObject(self)) then
		return false
	end
	if vehicle.getAIDischargeNodes ~= nil then
		local v108_ = vehicle:getAIDischargeNodes()
		if next(v108_) ~= nil then
			return true
		end
	end
	local v109_ = vehicle:getChildVehicles()
	for _, v110_ in ipairs(v109_) do
		if v110_.getAIDischargeNodes ~= nil then
			local v111_ = v110_:getAIDischargeNodes()
			if next(v111_) ~= nil then
				return true
			end
		end
	end
	return false
end

-- Local values: vehicle
function AIJobDeliver:getTitle()
	local v113_ = self.vehicleParameter:getVehicle()
	return v113_ == nil and "" or v113_:getName()
end

function AIJobDeliver:getIsLooping()
	return self.loopingParameter:getIsLooping()
end

-- Local values: vehicle
function AIJobDeliver:getIsStartable(connection)
	if g_currentMission.aiSystem:getAILimitedReached() then
		return false, AIJobDeliver.START_ERROR_LIMIT_REACHED
	else
		local v117_ = self.vehicleParameter:getVehicle()
		if v117_ == nil then
			return false, AIJobDeliver.START_ERROR_VEHICLE_DELETED
		elseif g_currentMission:getHasPlayerPermission("hireAssistant", connection, v117_:getOwnerFarmId()) then
			if v117_:getIsInUse(connection) then
				return false, AIJobDeliver.START_ERROR_VEHICLE_IN_USE
			else
				return true, AIJob.START_SUCCESS
			end
		else
			return false, AIJobDeliver.START_ERROR_NO_PERMISSION
		end
	end
end

-- Local values: desc, nextTask
function AIJobDeliver:getDescription()
	local v119_ = AIJobDeliver:superClass().getDescription(self)
	local v120_ = self:getTaskByIndex(self.currentTaskIndex)
	if v120_ == self.driveToLoadingTask then
		return v119_ .. " - " .. g_i18n:getText("ai_taskDescriptionDriveToLoadingStation")
	end
	if v120_ == self.waitForFillingTask then
		return v119_ .. " - " .. g_i18n:getText("ai_taskDescriptionWaitForFilling")
	end
	if v120_ == self.driveToUnloadingTask then
		return v119_ .. " - " .. g_i18n:getText("ai_taskDescriptionDriveToUnloadingStation")
	end
	if v120_ == self.dischargeTask then
		v119_ = v119_ .. " - " .. g_i18n:getText("ai_taskDescriptionUnloading")
	end
	return v119_
end

function AIJobDeliver.getIsStartErrorText(state)
	if state == AIJobDeliver.START_ERROR_LIMIT_REACHED then
		return g_i18n:getText("ai_startStateLimitReached")
	elseif state == AIJobDeliver.START_ERROR_VEHICLE_DELETED then
		return g_i18n:getText("ai_startStateVehicleDeleted")
	elseif state == AIJobDeliver.START_ERROR_NO_PERMISSION then
		return g_i18n:getText("ai_startStateNoPermission")
	elseif state == AIJobDeliver.START_ERROR_VEHICLE_IN_USE then
		return g_i18n:getText("ai_startStateVehicleInUse")
	else
		return g_i18n:getText("ai_startStateSuccess")
	end
end
