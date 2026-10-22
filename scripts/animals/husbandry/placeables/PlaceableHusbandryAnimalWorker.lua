PlaceableHusbandryAnimalWorker = {}
source("dataS/scripts/placeables/specializations/events/PlaceableHusbandryAnimalWorkerStateEvent.lua")
source("dataS/scripts/placeables/specializations/events/PlaceableHusbandryAnimalWorkerPerformEvent.lua")
source("dataS/scripts/placeables/specializations/events/PlaceableHusbandryAnimalWorkerPerformAnswerEvent.lua")
function PlaceableHusbandryAnimalWorker.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")
	schema:register(XMLValueType.STRING, basePath .. ".husbandry.animalWorker.task(?)#name", "Name of the hireable worker task to override the prices of")
	schema:register(XMLValueType.INT, basePath .. ".husbandry.animalWorker.task(?)#basePrice", "Fixed price charged each time the task runs, defaults to the task's own base price")
	schema:register(XMLValueType.INT, basePath .. ".husbandry.animalWorker.task(?)#pricePerAnimal", "Additional price charged per animal the task worked on, defaults to the task's own price per animal")
	schema:setXMLSpecializationType()
end
function PlaceableHusbandryAnimalWorker.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")
	schema:register(XMLValueType.STRING, basePath .. ".task(?)#name", "Name of the hireable worker task")
	schema:register(XMLValueType.BOOL, basePath .. ".task(?)#enabled", "Whether the task is enabled")
	schema:register(XMLValueType.INT, basePath .. ".task(?)#lastRunDay", "currentMonotonicDay value when the task last did something")
	schema:setXMLSpecializationType()
end
function PlaceableHusbandryAnimalWorker.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "loadAnimalWorkerPriceOverrides", PlaceableHusbandryAnimalWorker.loadAnimalWorkerPriceOverrides)
	SpecializationUtil.registerFunction(placeableType, "getAnimalWorkerTaskState", PlaceableHusbandryAnimalWorker.getAnimalWorkerTaskState)
	SpecializationUtil.registerFunction(placeableType, "getAnimalWorkerAvailableTasks", PlaceableHusbandryAnimalWorker.getAnimalWorkerAvailableTasks)
	SpecializationUtil.registerFunction(placeableType, "getAnimalWorkerTaskIsEnabled", PlaceableHusbandryAnimalWorker.getAnimalWorkerTaskIsEnabled)
	SpecializationUtil.registerFunction(placeableType, "getAnimalWorkerTaskCost", PlaceableHusbandryAnimalWorker.getAnimalWorkerTaskCost)
	SpecializationUtil.registerFunction(placeableType, "getAnimalWorkerTaskIsDue", PlaceableHusbandryAnimalWorker.getAnimalWorkerTaskIsDue)
	SpecializationUtil.registerFunction(placeableType, "applyAnimalWorkerStateFromEvent", PlaceableHusbandryAnimalWorker.applyAnimalWorkerStateFromEvent)
	SpecializationUtil.registerFunction(placeableType, "performAnimalWorkerTask", PlaceableHusbandryAnimalWorker.performAnimalWorkerTask)
end
function PlaceableHusbandryAnimalWorker.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getConditionInfos", PlaceableHusbandryAnimalWorker.getConditionInfos)
end
function PlaceableHusbandryAnimalWorker.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandryAnimalWorker)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableHusbandryAnimalWorker)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableHusbandryAnimalWorker)
	SpecializationUtil.registerEventListener(placeableType, "onHourChanged", PlaceableHusbandryAnimalWorker)
	SpecializationUtil.registerEventListener(placeableType, "onDayChanged", PlaceableHusbandryAnimalWorker)
end
function PlaceableHusbandryAnimalWorker.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(PlaceableHusbandryAnimals, specializations)
end
function PlaceableHusbandryAnimalWorker:onLoad(savegame)
	local spec = self.spec_husbandryAnimalWorker
	spec.taskStates = {}
	local taskSystem = g_currentMission.animalWorkerTaskSystem
	if taskSystem == nil then
		return
	else
		for _, task in ipairs(taskSystem:getTasks()) do
			local state = { ["enabled"] = false, ["lastRunDay"] = -1, ["basePrice"] = task.defaultBasePrice, ["pricePerAnimal"] = task.defaultPricePerAnimal }
			spec.taskStates[task.name] = state
		end
		self:loadAnimalWorkerPriceOverrides()
	end
end
function PlaceableHusbandryAnimalWorker:loadAnimalWorkerPriceOverrides()
	local spec = self.spec_husbandryAnimalWorker
	for _, taskKey in self.xmlFile:iterator("placeable.husbandry.animalWorker.task") do
		local name = self.xmlFile:getString(taskKey .. "#name")
		local state = spec.taskStates[name]
		if state == nil then
			Logging.xmlWarning(self.xmlFile, "Unknown animal worker task '%s' at '%s'", tostring(name), taskKey)
		else
			state.basePrice = self.xmlFile:getInt(taskKey .. "#basePrice", state.basePrice)
			state.pricePerAnimal = self.xmlFile:getInt(taskKey .. "#pricePerAnimal", state.pricePerAnimal)
		end
	end
end
function PlaceableHusbandryAnimalWorker:onReadStream(streamId, connection)
	local spec = self.spec_husbandryAnimalWorker
	for _, task in ipairs(g_currentMission.animalWorkerTaskSystem:getTasks()) do
		local enabled = streamReadBool(streamId)
		local state = spec.taskStates[task.name]
		if state == nil then
			continue
		end
		state.enabled = enabled
	end
end
function PlaceableHusbandryAnimalWorker:onWriteStream(streamId, connection)
	local spec = self.spec_husbandryAnimalWorker
	for _, task in ipairs(g_currentMission.animalWorkerTaskSystem:getTasks()) do
		local state = spec.taskStates[task.name]
		local _v15 = false
		if state ~= nil then
			_v15 = state.enabled
		end
		streamWriteBool(streamId, _v15)
	end
end
function PlaceableHusbandryAnimalWorker:loadFromXMLFile(xmlFile, key)
	local spec = self.spec_husbandryAnimalWorker
	for _, taskKey in xmlFile:iterator(key .. ".task") do
		local name = xmlFile:getString(taskKey .. "#name")
		if name == nil then
			continue
		end
		local state = spec.taskStates[name]
		if state == nil then
			continue
		end
		state.enabled = xmlFile:getBool(taskKey .. "#enabled", false)
		state.lastRunDay = xmlFile:getInt(taskKey .. "#lastRunDay", -1)
	end
	return true
end
function PlaceableHusbandryAnimalWorker:saveToXMLFile(xmlFile, key)
	local spec = self.spec_husbandryAnimalWorker
	local index = 0
	for _, task in ipairs(g_currentMission.animalWorkerTaskSystem:getTasks()) do
		local state = spec.taskStates[task.name]
		if state == nil then
			continue
		end
		local taskKey = string.format("%s.task(%d)", key, index)
		xmlFile:setString(taskKey .. "#name", task.name)
		xmlFile:setBool(taskKey .. "#enabled", state.enabled)
		xmlFile:setInt(taskKey .. "#lastRunDay", state.lastRunDay)
		index = index + 1
	end
end
function PlaceableHusbandryAnimalWorker:onHourChanged(hour)
	if not self.isServer then
		return
	end
	local environment = g_currentMission.environment
	if environment == nil then
		return
	else
		for _, task in ipairs(self:getAnimalWorkerAvailableTasks()) do
			local state = self:getAnimalWorkerTaskState(task)
			if state == nil then
				continue
			end
			if state.enabled then
				local hasRunToday = state.lastRunDay == environment.currentMonotonicDay
				if hasRunToday then
					continue
				end
				if self:getAnimalWorkerTaskIsDue(task, hour) then
					self:performAnimalWorkerTask(task)
				end
			end
		end
	end
end
function PlaceableHusbandryAnimalWorker:onDayChanged(currentDay)
	if g_localPlayer == nil or self:getOwnerFarmId() ~= g_localPlayer.farmId then
		return
	end
	local environment = g_currentMission.environment
	if environment == nil then
		return
	else
		for _, task in ipairs(self:getAnimalWorkerAvailableTasks()) do
			local schedule = task.schedule
			local hasReminder = schedule.notifyPeriod ~= nil and schedule.notification ~= nil
			if hasReminder and self:getAnimalWorkerTaskIsEnabled(task) then
				local isDayBefore = environment.currentPeriod == schedule.notifyPeriod and environment.currentDayInPeriod == environment.daysPerPeriod
				if isDayBefore then
					local text = g_i18n:getText(schedule.notification, task.customEnvironment)
					g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, text)
				end
			end
		end
	end
end
function PlaceableHusbandryAnimalWorker:getConditionInfos(superFunc)
	local infos = superFunc(self)
	local tasks = self:getAnimalWorkerAvailableTasks()
	if #tasks == 0 then
		return infos
	else
		local numEnabled = 0
		for _, task in ipairs(tasks) do
			if self:getAnimalWorkerTaskIsEnabled(task) then
				numEnabled = numEnabled + 1
			end
		end
		local info = {}
		info.title = g_i18n:getText("ui_animalWorker_statusTitle")
		info.valueText = string.format("%d / %d", numEnabled, #tasks)
		info.ratio = numEnabled / #tasks
		info.invertedBar = false
		info.disabled = numEnabled == 0
		table.insert(infos, info)
		return infos
	end
end
function PlaceableHusbandryAnimalWorker:performAnimalWorkerTask(task)
	if not self.isServer then
		return 0, 0
	end
	local state = self:getAnimalWorkerTaskState(task)
	if state == nil then
		return 0, 0
	end
	local numHandled = AnimalWorkerTaskSystem.performTask(task, self)
	if numHandled <= 0 then
		return 0, 0
	else
		local environment = g_currentMission.environment
		if environment ~= nil then
			state.lastRunDay = environment.currentMonotonicDay
		end
		local farmId = self:getOwnerFarmId()
		if farmId == nil or farmId == FarmManager.SPECTATOR_FARM_ID then
			return numHandled, 0
		end
		local cost = state.basePrice + state.pricePerAnimal * numHandled
		if 0 < cost then
			g_currentMission:addMoney(-cost, farmId, MoneyType.AI, true, true)
		end
		return numHandled, cost
	end
end
function PlaceableHusbandryAnimalWorker:applyAnimalWorkerStateFromEvent(task, enabled)
	local state = self:getAnimalWorkerTaskState(task)
	if state == nil then
		return false
	else
		state.enabled = enabled
		return state.enabled
	end
end
function PlaceableHusbandryAnimalWorker.getHasConnectionPermission(placeable, connection)
	local user = g_currentMission.userManager:getUserByConnection(connection)
	if user == nil then
		return false
	end
	local farm = g_farmManager:getFarmByUserId(user:getId())
	if farm == nil then
		return false
	elseif farm.farmId ~= placeable:getOwnerFarmId() then
		return false
	else
		return g_currentMission:getHasPlayerPermission(Farm.PERMISSION.HIRE_ASSISTANT, connection, farm.farmId)
	end
end
function PlaceableHusbandryAnimalWorker:getAnimalWorkerTaskState(task)
	if task == nil then
		return nil
	else
		return self.spec_husbandryAnimalWorker.taskStates[task.name]
	end
end
function PlaceableHusbandryAnimalWorker:getAnimalWorkerAvailableTasks()
	local spec = self.spec_husbandryAnimalWorker
	local tasks = {}
	local taskSystem = g_currentMission.animalWorkerTaskSystem
	if taskSystem == nil then
		return tasks
	else
		for _, task in ipairs(taskSystem:getTasks()) do
			if spec.taskStates[task.name] == nil then
				continue
			end
			if AnimalWorkerTaskSystem.getTaskIsAvailable(task, self) then
				table.insert(tasks, task)
			end
		end
		return tasks
	end
end
function PlaceableHusbandryAnimalWorker:getAnimalWorkerTaskIsEnabled(task)
	local state = self:getAnimalWorkerTaskState(task)
	local _v2 = false
	if state ~= nil then
		_v2 = state.enabled
	end
	return _v2
end
function PlaceableHusbandryAnimalWorker:getAnimalWorkerTaskCost(task, numAnimals)
	local state = self:getAnimalWorkerTaskState(task)
	if state == nil then
		return 0
	else
		return state.basePrice + state.pricePerAnimal * numAnimals
	end
end
function PlaceableHusbandryAnimalWorker:getAnimalWorkerTaskIsDue(task, hour)
	local environment = g_currentMission.environment
	if environment == nil then
		return false
	else
		local schedule = task.schedule
		if not AnimalWorkerTaskSystem.getTaskIsDaily(task) then
			local isScheduledDay = environment.currentPeriod == schedule.period and environment.currentDayInPeriod == schedule.dayInPeriod
			if not isScheduledDay then
				return false
			end
		end
		return (schedule.hour or AnimalWorkerTaskSystem.DEFAULT_HOUR) <= hour
	end
end
