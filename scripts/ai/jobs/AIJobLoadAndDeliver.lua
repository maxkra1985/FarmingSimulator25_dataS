-- Local values: AIJobLoadAndDeliver_mt
AIJobLoadAndDeliver = {}
AIJobLoadAndDeliver.START_ERROR_LIMIT_REACHED = 1
AIJobLoadAndDeliver.START_ERROR_VEHICLE_DELETED = 2
AIJobLoadAndDeliver.START_ERROR_NO_PERMISSION = 3
AIJobLoadAndDeliver.START_ERROR_VEHICLE_IN_USE = 4
local AIJobLoadAndDeliver_mt = Class(AIJobLoadAndDeliver, AIJob)

-- Upvalues: AIJobLoadAndDeliver_mt
-- Local values: self, vehicleGroup, loadTargetGroup, unloadTargetGroup, loopingGroup
function AIJobLoadAndDeliver.new(isServer, customMt)
	-- upvalues: (copy) AIJobLoadAndDeliver_mt
	local v4_ = AIJob.new(isServer, customMt or AIJobLoadAndDeliver_mt)
	v4_.dischargeNodeInfos = {}
	v4_.loadingNodeInfos = {}
	v4_.driveToLoadingTask = AITaskDriveTo.new(isServer, v4_)
	v4_.loadingTask = AITaskLoading.new(isServer, v4_)
	v4_.driveToUnloadingTask = AITaskDriveTo.new(isServer, v4_)
	v4_.dischargeTask = AITaskDischarge.new(isServer, v4_)
	v4_:addTask(v4_.driveToLoadingTask)
	v4_:addTask(v4_.loadingTask)
	v4_:addTask(v4_.driveToUnloadingTask)
	v4_:addTask(v4_.dischargeTask)
	v4_.vehicleParameter = AIParameterVehicle.new()
	v4_.unloadingStationParameter = AIParameterUnloadingStation.new()
	v4_.loadingStationParameter = AIParameterLoadingStation.new()
	v4_.fillTypeParameter = AIParameterFillType.new()
	v4_.loopingParameter = AIParameterLooping.new()
	v4_:addNamedParameter("vehicle", v4_.vehicleParameter)
	v4_:addNamedParameter("loadingStation", v4_.loadingStationParameter)
	v4_:addNamedParameter("fillType", v4_.fillTypeParameter)
	v4_:addNamedParameter("unloadingStation", v4_.unloadingStationParameter)
	v4_:addNamedParameter("looping", v4_.loopingParameter)
	local v5_ = AIParameterGroup.new(g_i18n:getText("ai_parameterGroupTitleVehicle"))
	v5_:addParameter(v4_.vehicleParameter)
	local v6_ = AIParameterGroup.new(g_i18n:getText("ai_parameterGroupTitleLoadingStation"))
	v6_:addParameter(v4_.loadingStationParameter)
	v6_:addParameter(v4_.fillTypeParameter)
	local v7_ = AIParameterGroup.new(g_i18n:getText("ai_parameterGroupTitleUnloadingStation"))
	v7_:addParameter(v4_.unloadingStationParameter)
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

-- Local values: vehicle, loadingStation, unloadingStation, fillTypeIndex, _, fillUnit, fillUnitIndex, _, _, z, _, dischargeNode, _, _, z, childVehicles, _, childVehicle, _, dischargeNode, _, _, z, _, fillUnit, fillUnitIndex, _, _, z, maxDischargeOffset, maxLoadingOffset, x, z, dirX, dirZ, trigger, x, z, dirX, dirZ, trigger
function AIJobLoadAndDeliver:setValues()
	self:resetTasks()
	local v14_ = self.vehicleParameter:getVehicle()
	if v14_ == nil then
		return
	else
		local v15_ = self.loadingStationParameter:getLoadingStation()
		if v15_ == nil then
			return
		else
			local v16_ = self.unloadingStationParameter:getUnloadingStation()
			if v16_ ~= nil then
				local v17_ = self.fillTypeParameter:getFillTypeIndex()
				self.loadingTask:setVehicle(v14_)
				self.driveToUnloadingTask:setVehicle(v14_)
				self.driveToLoadingTask:setVehicle(v14_)
				self.dischargeTask:setVehicle(v14_)
				self.loadingNodeInfos = {}
				self.dischargeNodeInfos = {}
				if v14_.getAIFillUnits ~= nil then
					for _, v18_ in ipairs(v14_:getAIFillUnits()) do
						local v19_ = v18_.fillUnitIndex
						local _, _, v20_ = v14_:getAILoadingNodeZAlignedOffset(v19_, v14_)
						local v21_ = self.loadingNodeInfos
						table.insert(v21_, {
							["vehicle"] = v14_,
							["fillUnitIndex"] = v19_,
							["offsetZ"] = v20_,
							["isDirty"] = true
						})
					end
				end
				if v14_.getAIDischargeNodes ~= nil then
					for _, v22_ in ipairs(v14_:getAIDischargeNodes()) do
						local _, _, v23_ = v14_:getAIDischargeNodeZAlignedOffset(v22_, v14_)
						local v24_ = self.dischargeNodeInfos
						table.insert(v24_, {
							["vehicle"] = v14_,
							["dischargeNode"] = v22_,
							["offsetZ"] = v23_,
							["isDirty"] = true
						})
					end
				end
				local v25_ = v14_:getChildVehicles()
				for _, v26_ in ipairs(v25_) do
					if v26_.getAIDischargeNodes ~= nil then
						for _, v27_ in ipairs(v26_:getAIDischargeNodes()) do
							local _, _, v28_ = v26_:getAIDischargeNodeZAlignedOffset(v27_, v14_)
							local v29_ = self.dischargeNodeInfos
							table.insert(v29_, {
								["vehicle"] = v26_,
								["dischargeNode"] = v27_,
								["offsetZ"] = v28_,
								["isDirty"] = true
							})
						end
					end
					if v26_.getAIFillUnits ~= nil then
						for _, v30_ in ipairs(v26_:getAIFillUnits()) do
							local v31_ = v30_.fillUnitIndex
							local _, _, v32_ = v26_:getAILoadingNodeZAlignedOffset(v31_, v14_)
							local v33_ = self.loadingNodeInfos
							table.insert(v33_, {
								["vehicle"] = v26_,
								["fillUnitIndex"] = v31_,
								["offsetZ"] = v32_,
								["isDirty"] = true
							})
						end
					end
				end
				table.sort(self.dischargeNodeInfos, function(p34_, p35_)
					return p34_.offsetZ > p35_.offsetZ
				end)
				table.sort(self.loadingNodeInfos, function(p36_, p37_)
					return p36_.offsetZ > p37_.offsetZ
				end)
				local v38_ = #self.dischargeNodeInfos <= 0 and 0 or self.dischargeNodeInfos[#self.dischargeNodeInfos].offsetZ
				self.driveToUnloadingTask:setTargetOffset(-v38_)
				local v39_ = #self.loadingNodeInfos <= 0 and 0 or self.loadingNodeInfos[#self.loadingNodeInfos].offsetZ
				self.driveToLoadingTask:setTargetOffset(-v39_)
				if v17_ ~= nil then
					if v15_ ~= nil then
						local v40_, v41_, v42_, v43_, v44_ = v15_:getAITargetPositionAndDirection(v17_)
						if v44_ ~= nil then
							self.driveToLoadingTask:setTargetPosition(v40_, v41_)
							self.driveToLoadingTask:setTargetDirection(v42_, v43_)
							self.loadingTask:setLoadTrigger(v44_)
						end
					end
					if v16_ ~= nil then
						local v45_, v46_, v47_, v48_, v49_ = v16_:getAITargetPositionAndDirection(v17_)
						if v49_ ~= nil then
							self.driveToUnloadingTask:setTargetPosition(v45_, v46_)
							self.driveToUnloadingTask:setTargetDirection(v47_, v48_)
							self.dischargeTask:setUnloadTrigger(v49_)
						end
					end
					self.loadingTask:setFillType(v17_)
				end
			end
		end
	end
end

-- Local values: isVehicleValid, vehicleErrorMessage, isFillTypeValid, fillTypeErrorMessage, fillTypeIndex, isLoadingStationValid, loadingStationErrorMessage, isUnloadingStationValid, unloadingStationErrorMessage, isValid, errorMessage
function AIJobLoadAndDeliver:validate(farmId)
	self:setParameterValid(true)
	local v52_, v53_ = self.vehicleParameter:validate()
	if v52_ then
		if #self.dischargeNodeInfos == 0 then
			v53_ = g_i18n:getText("ai_validationErrorNoAIDischargeNodesFound")
			v52_ = false
		elseif #self.loadingNodeInfos == 0 then
			v53_ = g_i18n:getText("ai_validationErrorNoAILoadingNodesFound")
			v52_ = false
		end
	end
	if not v52_ then
		self.vehicleParameter:setIsValid(false)
	end
	local v54_, v55_ = self.fillTypeParameter:validate()
	if not v54_ then
		self.fillTypeParameter:setIsValid(false)
	end
	local v56_ = self.fillTypeParameter:getFillTypeIndex()
	local v57_, v58_ = self.loadingStationParameter:validate(v56_, farmId)
	if not v57_ then
		self.loadingStationParameter:setIsValid(false)
	end
	local v59_, v60_ = self.unloadingStationParameter:validate(v56_, farmId)
	if not v59_ then
		self.unloadingStationParameter:setIsValid(false)
	end
	if v52_ then
		if v54_ then
			if not v57_ then
				v59_ = v57_
			end
		else
			v59_ = v54_
		end
	else
		v59_ = v52_
	end
	return v59_, v53_ or (v55_ or (v58_ or v60_))
end

-- Local values: lastJob, unloadingStations, _, unloadingStation, fillTypes, loadingStations, _, loadingStation, fillTypes, loadingStation
function AIJobLoadAndDeliver:applyCurrentState(vehicle, mission, farmId, isDirectStart)
	AIJobLoadAndDeliver:superClass().applyCurrentState(self, vehicle, mission, farmId, isDirectStart)
	self.vehicleParameter:setVehicle(vehicle)
	self.loopingParameter:setIsLooping(true)
	if vehicle.getLastJob ~= nil then
		local v66_ = vehicle:getLastJob()
		if v66_ ~= nil and v66_:isa(AIJobLoadAndDeliver) then
			self.unloadingStationParameter:setUnloadingStation(v66_.unloadingStationParameter:getUnloadingStation())
			self.loadingStationParameter:setLoadingStation(v66_.loadingStationParameter:getLoadingStation())
			self.loopingParameter:setIsLooping(v66_.loopingParameter:getIsLooping())
		end
	end
	local v67_ = {}
	for _, v68_ in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
		if g_currentMission.accessHandler:canPlayerAccess(v68_) and v68_:isa(UnloadingStation) then
			local v69_ = v68_:getAISupportedFillTypes()
			if next(v69_) ~= nil then
				table.insert(v67_, v68_)
			end
		end
	end
	table.sort(v67_, function(p70_, p71_)
		return p70_:getName() < p71_:getName()
	end)
	self.unloadingStationParameter:setValidUnloadingStations(v67_)
	local v72_ = {}
	for _, v73_ in pairs(g_currentMission.storageSystem:getLoadingStations()) do
		if g_currentMission.accessHandler:canPlayerAccess(v73_) then
			local v74_ = v73_:getAISupportedFillTypes()
			if next(v74_) ~= nil then
				table.insert(v72_, v73_)
			end
		end
	end
	table.sort(v72_, function(p75_, p76_)
		return p75_:getName() < p76_:getName()
	end)
	self.loadingStationParameter:setValidLoadingStations(v72_)
	self:updateFillTypes((self.loadingStationParameter:getLoadingStation()))
end

-- Local values: fillTypes, fillTypeIndex, _
function AIJobLoadAndDeliver:updateFillTypes(loadingStation)
	local v79_ = {}
	if loadingStation ~= nil then
		for v80_, _ in pairs(loadingStation:getAISupportedFillTypes()) do
			v79_[v80_] = loadingStation:getFillLevel(v80_, g_localPlayer.farmId)
		end
	end
	self.fillTypeParameter:setValidFillTypes(v79_)
end

-- Local values: loadingStation
function AIJobLoadAndDeliver:onParameterValueChanged(parameter)
	if parameter == self.loadingStationParameter then
		self:updateFillTypes((self.loadingStationParameter:getLoadingStation()))
	end
end

-- Local values: vehicle
function AIJobLoadAndDeliver:start(farmId)
	AIJobLoadAndDeliver:superClass().start(self, farmId)
	if self.isServer then
		local v85_ = self.vehicleParameter:getVehicle()
		v85_:createAgent(self.helperIndex)
		v85_:aiJobStarted(self, self.helperIndex, farmId)
	end
end

-- Local values: vehicle
function AIJobLoadAndDeliver:stop(aiMessage)
	if self.isServer then
		local v88_ = self.vehicleParameter:getVehicle()
		v88_:deleteAgent()
		v88_:aiJobFinished()
	end
	AIJobLoadAndDeliver:superClass().stop(self, aiMessage)
	self.loadingNodeInfos = {}
	self.dischargeNodeInfos = {}
end

-- Local values: _, dischargeNodeInfo, _, loadingNodeInfo
function AIJobLoadAndDeliver:startTask(task)
	if task == self.driveToLoadingTask then
		for _, v91_ in ipairs(self.dischargeNodeInfos) do
			v91_.isDirty = true
		end
	elseif task == self.driveToUnloadingTask then
		for _, v92_ in ipairs(self.loadingNodeInfos) do
			v92_.isDirty = true
		end
	end
	AIJobLoadAndDeliver:superClass().startTask(self, task)
end

-- Local values: hasOneEmptyFillUnit, _, loadingNodeInfo, vehicle, fillUnitIndex
function AIJobLoadAndDeliver:getStartTaskIndex()
	local v94_ = false
	for _, v95_ in ipairs(self.loadingNodeInfos) do
		if v95_.vehicle:getFillUnitFillLevel(v95_.fillUnitIndex) == 0 then
			v94_ = true
			break
		end
	end
	if v94_ then
		return self.driveToLoadingTask.taskIndex
	else
		return self.driveToUnloadingTask.taskIndex
	end
end

-- Local values: hasOneEmptyFillUnit, hasSupportedFillTypeLoaded, plannedFillTypeIndex, _, loadingNodeInfo, vehicle, fillUnitIndex, fillTypeIndex
function AIJobLoadAndDeliver:canStartWork()
	local v97_ = self.fillTypeParameter:getFillTypeIndex()
	local v98_ = false
	local v99_ = false
	for _, v100_ in ipairs(self.loadingNodeInfos) do
		local v101_ = v100_.vehicle
		local v102_ = v100_.fillUnitIndex
		local v103_ = v101_:getFillUnitFillType(v102_)
		if v101_:getFillUnitFillLevel(v102_) == 0 then
			v99_ = true
			break
		end
		if v103_ == v97_ then
			v98_ = true
		end
	end
	if v99_ or v98_ then
		return true, nil
	else
		return false, AIMessageErrorNoValidFillTypeLoaded.new()
	end
end

-- Local values: vehicle, loadingStation, unloadingStation, fillTypeIndex, isEmpty, _, loadingNodeInfo, loadingVehicle, fillUnitIndex
function AIJobLoadAndDeliver:canContinueWork()
	if self.vehicleParameter:getVehicle() == nil then
		return false, AIMessageErrorVehicleDeleted.new()
	end
	local v105_ = self.loadingStationParameter:getLoadingStation()
	if v105_ == nil then
		return false, AIMessageErrorLoadingStationDeleted.new()
	end
	local v106_ = self.unloadingStationParameter:getUnloadingStation()
	if v106_ == nil then
		return false, AIMessageErrorUnloadingStationDeleted.new()
	end
	local v107_ = self.fillTypeParameter:getFillTypeIndex()
	if v106_:getFreeCapacity(v107_, self.startedFarmId) <= 0 then
		return false, AIMessageErrorUnloadingStationFull.new()
	end
	if self.currentTaskIndex == self.loadingTask.taskIndex and v105_:getFillLevel(v107_, self.startedFarmId) <= 0 then
		local v108_ = true
		for _, v109_ in ipairs(self.loadingNodeInfos) do
			local v110_ = v109_.vehicle
			local v111_ = v109_.fillUnitIndex
			if v110_:getFillUnitFillLevel(v111_) > 0 and v110_:getFillUnitFillType(v111_) == v107_ then
				v108_ = false
				break
			end
		end
		if v108_ then
			return false, AIMessageSuccessSiloEmpty.new()
		end
	end
	return true, nil
end

-- Local values: _, loadingNodeInfo, vehicle, fillUnitIndex, fillTypeIndex, _, dischargeNodeInfo, vehicle, fillUnitIndex, nextTaskIndex
function AIJobLoadAndDeliver:getNextTaskIndex(isSkipTask)
	if self.currentTaskIndex == self.driveToLoadingTask.taskIndex or self.currentTaskIndex == self.loadingTask.taskIndex then
		for _, v114_ in ipairs(self.loadingNodeInfos) do
			if v114_.isDirty then
				local v115_ = v114_.vehicle
				local v116_ = v114_.fillUnitIndex
				if v115_:getFillUnitFillLevel(v116_) == 0 then
					self.loadingTask:setFillUnit(v115_, v116_, v114_.offsetZ)
					v114_.isDirty = false
					return self.loadingTask.taskIndex
				end
				v114_.isDirty = false
			end
		end
	elseif self.currentTaskIndex == self.driveToUnloadingTask.taskIndex or self.currentTaskIndex == self.dischargeTask.taskIndex then
		local v117_ = self.fillTypeParameter:getFillTypeIndex()
		for _, v118_ in ipairs(self.dischargeNodeInfos) do
			if v118_.isDirty then
				local v119_ = v118_.vehicle
				local v120_ = v118_.dischargeNode.fillUnitIndex
				if v119_:getFillUnitFillLevel(v120_) > 1 and v119_:getFillUnitFillType(v120_) == v117_ then
					self.dischargeTask:setDischargeNode(v119_, v118_.dischargeNode, v118_.offsetZ)
					v118_.isDirty = false
					return self.dischargeTask.taskIndex
				end
				v118_.isDirty = false
			end
		end
	end
	return AIJobLoadAndDeliver:superClass().getNextTaskIndex(self, isSkipTask)
end

-- Local values: vehicles, _, childVehicle, nodes, foundDischargeNodes, nodes, _, childVehicle, nodes, foundLoadingNodes, fillUnits, _, childVehicle, fillUnits
function AIJobLoadAndDeliver:getIsAvailableForVehicle(vehicle)
	if vehicle.createAgent == nil or (vehicle.setAITarget == nil or not vehicle:getCanStartAIVehicle()) then
		return false
	end
	if not vehicle:getIsAIJobSupported(ClassUtil.getClassNameByObject(self)) then
		return false
	end
	local v123_ = vehicle:getChildVehicles()
	for _, v124_ in ipairs(v123_) do
		if v124_.getAIDischargeNodes ~= nil then
			local v125_ = v124_:getAIDischargeNodes()
			if next(v125_) ~= nil then
				return true
			end
		end
	end
	local v126_ = false
	if vehicle.getAIDischargeNodes ~= nil then
		local v127_ = vehicle:getAIDischargeNodes()
		v126_ = next(v127_) ~= nil and true or v126_
	end
	if not v126_ then
		local v128_ = vehicle:getChildVehicles()
		for _, v129_ in ipairs(v128_) do
			if v129_.getAIDischargeNodes ~= nil then
				local v130_ = v129_:getAIDischargeNodes()
				if next(v130_) ~= nil then
					v126_ = true
					break
				end
			end
		end
	end
	if not v126_ then
		return false
	end
	local v131_ = false
	if vehicle.getAIFillUnits ~= nil then
		local v132_ = vehicle:getAIFillUnits()
		v131_ = next(v132_) ~= nil and true or v131_
	end
	if not v131_ then
		local v133_ = vehicle:getChildVehicles()
		for _, v134_ in ipairs(v133_) do
			if v134_.getAIFillUnits ~= nil then
				local v135_ = v134_:getAIFillUnits()
				if next(v135_) ~= nil then
					v131_ = true
					break
				end
			end
		end
	end
	return v131_ and true or false
end

-- Local values: vehicle
function AIJobLoadAndDeliver:getTitle()
	local v137_ = self.vehicleParameter:getVehicle()
	return v137_ == nil and "" or v137_:getName()
end

-- Local values: desc, nextTask
function AIJobLoadAndDeliver:getDescription()
	local v139_ = AIJobLoadAndDeliver:superClass().getDescription(self)
	local v140_ = self:getTaskByIndex(self.currentTaskIndex)
	if v140_ == self.driveToLoadingTask then
		return v139_ .. " - " .. g_i18n:getText("ai_taskDescriptionDriveToLoadingStation")
	end
	if v140_ == self.loadingTask then
		return v139_ .. " - " .. g_i18n:getText("ai_taskDescriptionLoading")
	end
	if v140_ == self.driveToUnloadingTask then
		return v139_ .. " - " .. g_i18n:getText("ai_taskDescriptionDriveToUnloadingStation")
	end
	if v140_ == self.dischargeTask then
		v139_ = v139_ .. " - " .. g_i18n:getText("ai_taskDescriptionUnloading")
	end
	return v139_
end

function AIJobLoadAndDeliver:getIsLooping()
	return self.loopingParameter:getIsLooping()
end

-- Local values: vehicle
function AIJobLoadAndDeliver:getIsStartable(connection)
	if g_currentMission.aiSystem:getAILimitedReached() then
		return false, AIJobLoadAndDeliver.START_ERROR_LIMIT_REACHED
	else
		local v144_ = self.vehicleParameter:getVehicle()
		if v144_ == nil then
			return false, AIJobLoadAndDeliver.START_ERROR_VEHICLE_DELETED
		elseif g_currentMission:getHasPlayerPermission("hireAssistant", connection, v144_:getOwnerFarmId()) then
			if v144_:getIsInUse(connection) then
				return false, AIJobLoadAndDeliver.START_ERROR_VEHICLE_IN_USE
			else
				return true, AIJob.START_SUCCESS
			end
		else
			return false, AIJobLoadAndDeliver.START_ERROR_NO_PERMISSION
		end
	end
end

function AIJobLoadAndDeliver.getIsStartErrorText(state)
	if state == AIJobLoadAndDeliver.START_ERROR_LIMIT_REACHED then
		return g_i18n:getText("ai_startStateLimitReached")
	elseif state == AIJobLoadAndDeliver.START_ERROR_VEHICLE_DELETED then
		return g_i18n:getText("ai_startStateVehicleDeleted")
	elseif state == AIJobLoadAndDeliver.START_ERROR_NO_PERMISSION then
		return g_i18n:getText("ai_startStateNoPermission")
	elseif state == AIJobLoadAndDeliver.START_ERROR_VEHICLE_IN_USE then
		return g_i18n:getText("ai_startStateVehicleInUse")
	else
		return g_i18n:getText("ai_startStateSuccess")
	end
end
