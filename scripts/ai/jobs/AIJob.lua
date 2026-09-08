-- Local values: AIJob_mt
AIJob = {}
AIJob.START_SUCCESS = 0
local AIJob_mt = Class(AIJob)

-- Upvalues: AIJob_mt
-- Local values: self
function AIJob.new(isServer, customMt)
	-- upvalues: (copy) AIJob_mt
	local v4_ = customMt or AIJob_mt
	local v5_ = setmetatable({}, v4_)
	v5_.isServer = isServer
	v5_.tasks = {}
	v5_.namedParameters = {}
	v5_.groupedParameters = {}
	v5_.currentTaskIndex = 0
	v5_.jobId = nil
	v5_.startedFarmId = nil
	v5_.isDirectStart = false
	v5_.pendingCost = 0
	return v5_
end

-- Local values: _, namedParameter, _, task
function AIJob:delete()
	for _, v7_ in ipairs(self.namedParameters) do
		v7_.parameter:delete()
	end
	for _, v8_ in ipairs(self.tasks) do
		v8_:delete()
	end
end

-- Local values: index, _, namedParameter, parameter, paramKey
function AIJob:saveToXMLFile(xmlFile, key, usedModNames)
	local v13_ = 0
	for _, v14_ in ipairs(self.namedParameters) do
		if v14_.parameter.saveToXMLFile ~= nil then
			local v15_ = string.format("%s.parameter(%d)", key, v13_)
			xmlFile:setString(v15_ .. "#name", v14_.name)
			v14_.parameter:saveToXMLFile(xmlFile, v15_, usedModNames)
			v13_ = v13_ + 1
		end
	end
	return true
end

function AIJob:loadFromXMLFile(xmlFile, key)
	xmlFile:iterate(key .. ".parameter", function(_, p19_)
		-- upvalues: (copy) xmlFile, (copy) self
		local v20_ = xmlFile:getString(p19_ .. "#name")
		if v20_ ~= nil then
			local v21_ = self:getNamedParameter(v20_)
			if v21_ ~= nil and v21_.loadFromXMLFile ~= nil then
				v21_:loadFromXMLFile(xmlFile, p19_)
			end
		end
	end)
end

-- Local values: _, namedParameter
function AIJob:readStream(streamId, connection)
	self.isDirectStart = streamReadBool(streamId)
	if streamReadBool(streamId) then
		self.jobId = streamReadInt32(streamId)
	end
	for _, v25_ in ipairs(self.namedParameters) do
		v25_.parameter:readStream(streamId, connection)
	end
	self:setValues()
	self.currentTaskIndex = streamReadUInt8(streamId)
end

-- Local values: _, namedParameter
function AIJob:writeStream(streamId, connection)
	streamWriteBool(streamId, self.isDirectStart)
	if streamWriteBool(streamId, self.jobId ~= nil) then
		streamWriteInt32(streamId, self.jobId)
	end
	for _, v29_ in ipairs(self.namedParameters) do
		v29_.parameter:writeStream(streamId, connection)
	end
	streamWriteUInt8(streamId, self.currentTaskIndex)
end

-- Local values: currentTask, canStart, aiMessage, taskIndex, task, canContinue, aiMessage, newTaskIndex, nextTask
function AIJob:update(dt)
	if self.isServer then
		local v32_ = nil
		if self.currentTaskIndex == 0 then
			local v33_, v34_ = self:canStartWork()
			if not v33_ then
				g_currentMission.aiSystem:stopJob(self, v34_)
				return
			end
			self:startTask((self:getTaskByIndex((self:getStartTaskIndex()))))
		else
			v32_ = self:getTaskByIndex(self.currentTaskIndex)
		end
		if v32_ ~= nil then
			v32_:update(dt)
			if v32_:getIsFinished() then
				local v35_, v36_ = self:canContinueWork()
				if not v35_ then
					g_currentMission.aiSystem:stopJob(self, v36_)
					return
				end
				local v37_ = self:getNextTaskIndex()
				if #self.tasks < v37_ then
					if not self:getIsLooping() then
						g_currentMission.aiSystem:stopJob(self, AIMessageSuccessFinishedJob.new())
						return
					end
					v37_ = 1
				end
				self:stopTask(v32_, false)
				self:startTask((self:getTaskByIndex(v37_)))
			end
		end
	end
end

-- Local values: price, farm
function AIJob:updateCost(dt)
	local v40_ = self:getPricePerMs()
	if v40_ > 0 then
		local v41_ = v40_ * dt * EconomyManager.getCostMultiplier()
		self.pendingCost = self.pendingCost + v41_
		local v42_ = g_farmManager:getFarmById(self.startedFarmId)
		if v42_ ~= nil and v42_:getBalance() - self.pendingCost < 0 then
			g_currentMission.aiSystem:stopJob(self, AIMessageErrorOutOfMoney.new())
		end
		if self.pendingCost > 25 then
			g_currentMission:addMoney(-self.pendingCost, self.startedFarmId, MoneyType.AI, true)
			self.pendingCost = 0
		end
	end
end

function AIJob:canContinueWork()
	return true, nil
end

function AIJob:canStartWork()
	return true, nil
end

function AIJob:getPricePerMs()
	return 0.0004
end

function AIJob:getNextTaskIndex()
	return self.currentTaskIndex + 1
end

function AIJob:validate(farmId)
	return true, nil
end

function AIJob:getIsLooping()
	return false
end

function AIJob:setValues() end

function AIJob:startTask(task)
	self.currentTaskIndex = task.taskIndex
	task:start()
	if self.isServer then
		g_server:broadcastEvent(AITaskStartEvent.new(self, task))
	end
end

function AIJob:stopTask(task, wasJobStopped)
	task:stop(wasJobStopped)
	if self.isServer then
		g_server:broadcastEvent(AITaskStopEvent.new(self, task, wasJobStopped))
	end
end

-- Local values: helper
function AIJob:start(farmId)
	self.helperIndex = g_helperManager:getRandomHelper().index
	self.startedFarmId = farmId
	self.isRunning = true
	if self.isServer then
		self.currentTaskIndex = 0
	end
end

function AIJob:getCanSkipTask()
	return false
end

function AIJob:skipCurrentTask() end

-- Local values: task
function AIJob:stop(aiMessage)
	self.isRunning = false
	if self.isServer and self.currentTaskIndex ~= 0 then
		self:stopTask(self:getTaskByIndex(self.currentTaskIndex), true)
	end
	if self.pendingCost > 0 then
		g_currentMission:addMoney(-self.pendingCost, self.startedFarmId, MoneyType.AI, true)
		self.pendingCost = 0
	end
	self:showNotification(aiMessage)
	self:resetTasks()
end

function AIJob:addTask(task)
	local v55_ = task.taskIndex == nil
	assert(v55_, "Task already added")
	local v56_ = self.tasks
	table.insert(v56_, task)
	task.taskIndex = #self.tasks
end

-- Local values: _, task
function AIJob:resetTasks()
	for _, v58_ in ipairs(self.tasks) do
		v58_:reset()
	end
end

function AIJob:getTaskByIndex(taskIndex)
	return self.tasks[taskIndex]
end

-- Local values: helper
function AIJob:getTitle()
	return g_helperManager:getHelperByIndex(self.helperIndex).title
end

-- Local values: jobType
function AIJob:getDescription()
	return g_currentMission.aiJobTypeManager:getJobTypeByIndex(self.jobTypeIndex).title
end

-- Local values: helper
function AIJob:getHelperName()
	return g_helperManager:getHelperByIndex(self.helperIndex).title
end

-- Local values: helper, playerFarmId, text, errorType, notificationType
function AIJob:showNotification(aiMessage)
	if g_helperManager:getHelperByIndex(self.helperIndex) ~= nil then
		local v66_
		if g_currentMission == nil or g_localPlayer == nil then
			v66_ = nil
		else
			v66_ = g_localPlayer.farmId
		end
		if aiMessage ~= nil and self.startedFarmId == v66_ then
			local v67_ = aiMessage:getMessage(self)
			local v68_ = aiMessage:getType()
			local v69_ = FSBaseMission.INGAME_NOTIFICATION_CRITICAL
			if v68_ == AIMessageType.OK then
				v69_ = FSBaseMission.INGAME_NOTIFICATION_OK
			elseif v68_ == AIMessageType.INFO then
				v69_ = FSBaseMission.INGAME_NOTIFICATION_INFO
			end
			g_currentMission:addIngameNotification(v69_, v67_)
		end
	end
end

function AIJob:getStartTaskIndex()
	return 1
end

function AIJob:addNamedParameter(name, parameter)
	local v73_ = self.namedParameters
	table.insert(v73_, {
		["name"] = name,
		["parameter"] = parameter
	})
end

-- Local values: _, namedParameter
function AIJob:setParameterValid(isValid)
	for _, v76_ in ipairs(self.namedParameters) do
		v76_.parameter:setIsValid(isValid)
	end
end

function AIJob:getNamedParameters()
	return self.namedParameters
end

-- Local values: _, data
function AIJob:getNamedParameter(name)
	if name == nil then
		return nil
	end
	local v80_ = string.upper(name)
	for _, v81_ in ipairs(self.namedParameters) do
		if string.upper(v81_.name) == v80_ then
			return v81_.parameter
		end
	end
	return nil
end

function AIJob:getGroupedParameters()
	return self.groupedParameters
end

function AIJob:applyCurrentState(vehicle, mission, farmId, isDirectStart)
	self.isDirectStart = isDirectStart
end

function AIJob:getIsAvailableForVehicle(vehicle)
	return true
end

function AIJob:setId(id)
	self.jobId = id
end

function AIJob:onParameterValueChanged(parameter) end

function AIJob:getIsStartable(connection)
	return true, AIJob.START_SUCCESS
end
