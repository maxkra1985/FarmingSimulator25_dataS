GrowthSystem = {}
local GrowthSystem_mt = Class(GrowthSystem)
GrowthSystem.MAX_MS_PER_FRAME = 0.5
GrowthSystem.MAX_MS_PER_FRAME_SLEEPING = 1.5
function GrowthSystem.new(mission, isServer, customMt)
	local self = setmetatable({}, customMt or GrowthSystem_mt)
	self.mission = mission
	self.isServer = isServer
	self.fieldCropsUpdaters = {}
	self.fieldCropsUpdatersCellSize = 16
	self.growthQueue = {}
	self.currentGrowthPeriod = nil
	g_messageCenter:subscribe(MessageType.SLEEPING, self.onSleepChanged, self)
	return self
end
function GrowthSystem:delete()
	g_messageCenter:unsubscribeAll(self)
	for _, updater in pairs(self.fieldCropsUpdaters) do
		if updater.updater == nil then
			continue
		end
		delete(updater.updater)
		updater.updater = nil
	end
	if self.weedUpdater ~= nil then
		delete(self.weedUpdater)
		self.weedUpdater = nil
	end
	if self.stoneUpdater ~= nil then
		delete(self.stoneUpdater)
		self.stoneUpdater = nil
	end
	if g_addTestCommands then
		removeConsoleCommand("gsGrowNow")
	end
end
function GrowthSystem:loadMapData(mapXmlFile, missionInfo, baseDirectory)
	self.missionInfo = missionInfo
	self.environment = self.mission.environment
	if g_addTestCommands then
		addConsoleCommand("gsGrowNow", "Force growth on foliage", "consoleCommandGrowNow", self, "periodIndex")
	end
	g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.onPeriodChanged, self)
end
function GrowthSystem:loadFromXMLFile(xmlFilename)
	if xmlFilename ~= nil then
		local xmlFile = XMLFile.load("environment", xmlFilename)
		self.currentGrowthPeriod = xmlFile:getInt("environment.growth#currentPeriod")
		xmlFile:iterate("environment.growth.queue.period", function(_, key)
			local period = xmlFile:getInt(key)
			table.insert(self.growthQueue, period)
		end)
		xmlFile:delete()
	end
	if self.currentGrowthPeriod ~= nil then
		self:setMonthEngineState(self.currentGrowthPeriod)
		self.numEngineStepsActive = 0
		for _, updater in pairs(self.fieldCropsUpdaters) do
			if setApplyCropsGrowthFinishedCallback(updater.updater, "onEngineStepFinished", self) then
				self.numEngineStepsActive = self.numEngineStepsActive + 1
				setApplyCropsGrowthMaxTimePerFrame(updater.updater, self:getMaxUpdateTime())
			end
		end
		if self.weedUpdater ~= nil and (self.missionInfo.weedsEnabled and setDensityMapUpdaterApplyFinishedCallback(self.weedUpdater, "onEngineStepFinished", self)) then
			self.numEngineStepsActive = self.numEngineStepsActive + 1
			setDensityMapUpdaterApplyMaxTimePerFrame(self.weedUpdater, self:getMaxUpdateTime())
		end
		if self.stoneUpdater ~= nil and (self.missionInfo.stonesEnabled and setDensityMapUpdaterApplyFinishedCallback(self.stoneUpdater, "onEngineStepFinished", self)) then
			self.numEngineStepsActive = self.numEngineStepsActive + 1
			setDensityMapUpdaterApplyMaxTimePerFrame(self.stoneUpdater, self:getMaxUpdateTime())
		end
		if self.numEngineStepsActive == 0 then
			self.currentGrowthPeriod = nil
		end
	end
	self:setGrowthEnabled(true)
end
function GrowthSystem:saveToXMLFile(file, key)
	local xmlFile = XMLFile.wrap(file)
	if self.currentGrowthPeriod ~= nil then
		xmlFile:setInt("environment.growth#currentPeriod", self.currentGrowthPeriod)
	end
	xmlFile:setSortedTable("environment.growth.queue.period", self.growthQueue, function(periodKey, value)
		xmlFile:setInt(periodKey, value)
	end)
	xmlFile:delete()
end
function GrowthSystem:saveState(directory)
	for filename, updater in pairs(self.fieldCropsUpdaters) do
		saveCropsGrowthStateToFile(updater.updater, directory .. "/" .. filename .. "_growthState.xml")
	end
	if self.weedUpdater ~= nil then
		saveDensityMapUpdaterStateToFile(self.weedUpdater, directory .. "/weed_growthState.xml")
	end
	if self.stoneUpdater ~= nil then
		saveDensityMapUpdaterStateToFile(self.stoneUpdater, directory .. "/stone_growthState.xml")
	end
end
function GrowthSystem:onTerrainLoad(terrainRootNode)
	if not self.isServer then
		return
	else
		local mission = self.mission
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		local weedSystem = self.mission.weedSystem
		if weedSystem:getMapHasWeed() then
			local densityMap, firstChannel, numChannels, minValue, maxValue = weedSystem:getDensityMapData()
			self.weedUpdater = createDensityMapUpdater(weedSystem.name, densityMap, firstChannel, numChannels, minValue, maxValue, 0, 0, 0, 0, 0)
			setDensityMapUpdaterMask(self.weedUpdater, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		end
		local stoneSystem = self.mission.stoneSystem
		if stoneSystem:getMapHasStones() then
			local densityMap, firstChannel, numChannels = stoneSystem:getDensityMapData()
			local minValue, maxValue = stoneSystem:getMinMaxValues()
			self.stoneUpdater = createDensityMapUpdater(stoneSystem.name, densityMap, firstChannel, numChannels, minValue, maxValue, 0, 0, 0, 0, 0)
		end
		for _, updater in pairs(self.fieldCropsUpdaters) do
			local constr = FieldCropsUpdaterConstructor.new(self.fieldCropsUpdatersCellSize)
			for name, id in pairs(updater.ids) do
				local fruitType = g_fruitTypeManager:getFruitTypeByName(name)
				local groundTypeChangedValue = FieldGroundType.getValueByType(fruitType.groundTypeChangeType)
				local groundTypeChangeMask = 4294967295
				if 0 < #fruitType.groundTypeChangeMaskTypes then
					groundTypeChangeMask = 0
					for _, v in ipairs(fruitType.groundTypeChangeMaskTypes) do
						local value = FieldGroundType.getValueByType(v)
						groundTypeChangeMask = bit32.bor(groundTypeChangeMask, bit32.lshift(1, value))
					end
				end
				constr:addCropType(id, fruitType.numGrowthStates, 0, fruitType.resetsSpray, fruitType.groundTypeChangeGrowthState, groundTypeChangedValue, groundTypeChangeMask)
			end
			constr:setGroundTerrainDetail(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, groundTypeFirstChannel, groundTypeNumChannels)
			updater.updater = constr:finalize("CropsUpdater")
		end
		self:setGrowthEnabled(false)
		if self.missionInfo.isValid and self.missionInfo.densityMapRevision == g_densityMapRevision then
			local dir = self.missionInfo.savegameDirectory
			for filename, updater in pairs(self.fieldCropsUpdaters) do
				loadCropsGrowthStateFromFile(updater.updater, dir .. "/" .. filename .. "_growthState.xml")
			end
			if self.weedUpdater ~= nil then
				loadDensityMapUpdaterStateFromFile(self.weedUpdater, dir .. "/weed_growthState.xml")
			end
			if self.stoneUpdater ~= nil then
				loadDensityMapUpdaterStateFromFile(self.stoneUpdater, dir .. "/stone_growthState.xml")
			end
		end
	end
end
function GrowthSystem:setFruitLayer(mapName, fruitType, layerName, id)
	if self.fieldCropsUpdaters[mapName] == nil then
		self.fieldCropsUpdaters[mapName] = { ids = {} }
	end
	local updater = self.fieldCropsUpdaters[mapName]
	updater.ids[fruitType.layerName] = id
end
function GrowthSystem:getMaxUpdateTime()
	if g_sleepManager.isSleeping then
		return GrowthSystem.MAX_MS_PER_FRAME_SLEEPING
	else
		return GrowthSystem.MAX_MS_PER_FRAME
	end
end
function GrowthSystem:update(dt) end
function GrowthSystem:getIsGrowingInProgress()
	return self.currentGrowthPeriod ~= nil
end
function GrowthSystem:onPeriodChanged()
	local transitionPeriod = self.environment.currentPeriod - 1
	if transitionPeriod == 0 then
		transitionPeriod = 12
	end
	self:triggerGrowth(transitionPeriod)
end
function GrowthSystem:onSleepChanged(isSleeping)
	if self.isServer then
		for _, updater in pairs(self.fieldCropsUpdaters) do
			setApplyCropsGrowthMaxTimePerFrame(updater.updater, self:getMaxUpdateTime())
		end
		if self.weedUpdater ~= nil and self.missionInfo.weedsEnabled then
			setDensityMapUpdaterApplyMaxTimePerFrame(self.weedUpdater, self:getMaxUpdateTime())
		end
		if self.stoneUpdater ~= nil and self.missionInfo.stonesEnabled then
			setDensityMapUpdaterApplyMaxTimePerFrame(self.stoneUpdater, self:getMaxUpdateTime())
		end
	end
end
function GrowthSystem:setMonthEngineState(period)
	for _, updater in pairs(self.fieldCropsUpdaters) do
		for name, id in pairs(updater.ids) do
			local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByName(name)
			local growthMapping = nil
			if self.missionInfo.growthMode == GrowthMode.SEASONAL then
				local growthData = fruitTypeDesc:getSeasonalGrowthData()
				if growthData ~= nil then
					growthMapping = growthData.periods[period].growthMapping
				end
			elseif self.missionInfo.growthMode == GrowthMode.DAILY then
				local growthData = fruitTypeDesc:getNonSeasonalGrowthData()
				if growthData ~= nil then
					growthMapping = growthData.growthMapping
				end
			end
			if growthMapping ~= nil then
				for from = 1, #growthMapping do
					setCropsGrowthNextState(updater.updater, id, from, growthMapping[from])
				end
			else
				for from = 1, fruitTypeDesc.numGrowthStates - 1 do
					setCropsGrowthNextState(updater.updater, id, from, from + 1)
				end
				if fruitTypeDesc.regrows then
					setCropsGrowthNextState(updater.updater, id, fruitTypeDesc.cutState, fruitTypeDesc.firstRegrowthState)
				end
			end
		end
	end
	if self.weedUpdater ~= nil then
		for from, to in pairs(self.mission.weedSystem:getGrowthMapping()) do
			setDensityMapUpdaterNextValue(self.weedUpdater, 0, from, to)
		end
	end
	if self.stoneUpdater ~= nil then
		for _, mapping in ipairs(self.mission.stoneSystem:getGrowthMapping()) do
			if mapping.period == period then
				setDensityMapUpdaterNextValue(self.stoneUpdater, 0, mapping.from, mapping.to)
			end
		end
	end
end
function GrowthSystem:triggerGrowth(period)
	if self.currentGrowthPeriod ~= nil then
		self.growthQueue[#self.growthQueue + 1] = period
	else
		self:startEngineGrowth(period)
	end
end
function GrowthSystem:startEngineGrowth(period)
	Logging.devInfo("GrowthSystem:startEngineGrowth Period %d (%s) - Pending growth tasks %d", period, SeasonPeriod.getName(period), #self.growthQueue)
	g_messageCenter:publish(MessageType.START_GROWTH_PERIOD, period)
	self:setMonthEngineState(period)
	self.currentGrowthPeriod = period
	self.numEngineStepsActive = 0
	if self.missionInfo.growthMode == GrowthMode.DISABLED then
		self:onEngineGrowthFinished()
	else
		for _, updater in pairs(self.fieldCropsUpdaters) do
			self.numEngineStepsActive = self.numEngineStepsActive + 1
			applyCropsGrowth(updater.updater, "onEngineStepFinished", self, self:getMaxUpdateTime())
		end
		if self.weedUpdater ~= nil and self.missionInfo.weedsEnabled then
			self.numEngineStepsActive = self.numEngineStepsActive + 1
			applyDensityMapUpdater(self.weedUpdater, "onEngineStepFinished", self, self:getMaxUpdateTime())
		end
		if self.stoneUpdater ~= nil and self.missionInfo.stonesEnabled then
			self.numEngineStepsActive = self.numEngineStepsActive + 1
			applyDensityMapUpdater(self.stoneUpdater, "onEngineStepFinished", self, self:getMaxUpdateTime())
		end
		self:performScriptBasedGrowth(period)
	end
end
function GrowthSystem:onEngineGrowthFinished()
	local finishedPeriod = self.currentGrowthPeriod
	self.currentGrowthPeriod = nil
	Logging.devInfo("GrowthSystem:onEngineGrowthFinished Period %d (%s)", finishedPeriod, SeasonPeriod.getName(finishedPeriod))
	local hasPendingGrowth = 0 < #self.growthQueue
	if hasPendingGrowth then
		local period = self.growthQueue[1]
		table.remove(self.growthQueue, 1)
		self:startEngineGrowth(period)
	end
	g_messageCenter:publish(MessageType.FINISHED_GROWTH_PERIOD, finishedPeriod, hasPendingGrowth)
end
function GrowthSystem:onEngineStepFinished()
	self.numEngineStepsActive = self.numEngineStepsActive - 1
	if self.numEngineStepsActive == 0 then
		self:onEngineGrowthFinished()
	end
end
function GrowthSystem:performScriptBasedGrowth(period) end
function GrowthSystem:setGrowthMode(mode, noEventSend)
	if self.missionInfo.growthMode ~= mode then
		self.missionInfo.growthMode = mode
		SavegameSettingsEvent.sendEvent(noEventSend)
		Logging.info("Savegame Setting 'growthMode': %d", mode)
	end
end
function GrowthSystem:getGrowthMode()
	return self.missionInfo.growthMode
end
function GrowthSystem:setGrowthMask(map, firstChannel, numChannels)
	for _, updater in pairs(self.fieldCropsUpdaters) do
		if updater.updater == nil then
			continue
		end
		setCropsGrowthMask(updater.updater, map, firstChannel, numChannels)
	end
	if self.weedUpdater ~= nil then
		setDensityMapUpdaterMask(self.weedUpdater, map, firstChannel, numChannels)
	end
end
function GrowthSystem:resetGrowthMask()
	self:setGrowthMask(0, 0, 0)
end
function GrowthSystem:setIgnoreDensityChanges(ignore) end
function GrowthSystem:setIsGamePaused(isPaused) end
function GrowthSystem:setGrowthEnabled(isEnabled)
	self.growthEnabled = isEnabled
	for _, updater in pairs(self.fieldCropsUpdaters) do
		if updater.updater == nil then
			continue
		end
		setCropsEnableGrowth(updater.updater, isEnabled)
	end
	if self.weedUpdater ~= nil then
		setDensityMapUpdaterEnabled(self.weedUpdater, isEnabled)
	end
end
function GrowthSystem:onWeedGrowthChanged() end
function GrowthSystem:consoleCommandGrowNow(period)
	local usage = "Usage: gsGrowNow period(1..12)"
	period = tonumber(period)
	if period ~= nil then
		self:triggerGrowth(period)
		return "Triggered growth"
	else
		return "Error: No period given. " .. "Usage: gsGrowNow period(1..12)"
	end
end
