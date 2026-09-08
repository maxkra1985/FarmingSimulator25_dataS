-- Local values: GrowthSystem_mt
GrowthSystem = {}
local GrowthSystem_mt = Class(GrowthSystem)
GrowthSystem.MAX_MS_PER_FRAME = 0.5
GrowthSystem.MAX_MS_PER_FRAME_SLEEPING = 1.5

-- Upvalues: GrowthSystem_mt
-- Local values: self
function GrowthSystem.new(mission, isServer, customMt)
	-- upvalues: (copy) GrowthSystem_mt
	local v5_ = customMt or GrowthSystem_mt
	local v6_ = setmetatable({}, v5_)
	v6_.mission = mission
	v6_.isServer = isServer
	v6_.fieldCropsUpdaters = {}
	v6_.fieldCropsUpdatersCellSize = 16
	v6_.growthQueue = {}
	v6_.currentGrowthPeriod = nil
	g_messageCenter:subscribe(MessageType.SLEEPING, v6_.onSleepChanged, v6_)
	return v6_
end

-- Local values: _, updater
function GrowthSystem:delete()
	g_messageCenter:unsubscribeAll(self)
	for _, v8_ in pairs(self.fieldCropsUpdaters) do
		if v8_.updater ~= nil then
			delete(v8_.updater)
			v8_.updater = nil
		end
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

-- Local values: xmlFile, _, updater
function GrowthSystem:loadFromXMLFile(xmlFilename)
	if xmlFilename ~= nil then
		local v_u_13_ = XMLFile.load("environment", xmlFilename)
		self.currentGrowthPeriod = v_u_13_:getInt("environment.growth#currentPeriod")
		v_u_13_:iterate("environment.growth.queue.period", function(_, p14_)
			-- upvalues: (copy) v_u_13_, (copy) self
			local v15_ = v_u_13_:getInt(p14_)
			local v16_ = self.growthQueue
			table.insert(v16_, v15_)
		end)
		v_u_13_:delete()
	end
	if self.currentGrowthPeriod ~= nil then
		self:setMonthEngineState(self.currentGrowthPeriod)
		self.numEngineStepsActive = 0
		for _, v17_ in pairs(self.fieldCropsUpdaters) do
			if setApplyCropsGrowthFinishedCallback(v17_.updater, "onEngineStepFinished", self) then
				self.numEngineStepsActive = self.numEngineStepsActive + 1
				setApplyCropsGrowthMaxTimePerFrame(v17_.updater, self:getMaxUpdateTime())
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

-- Local values: xmlFile
function GrowthSystem:saveToXMLFile(file, key)
	local v_u_20_ = XMLFile.wrap(file)
	if self.currentGrowthPeriod ~= nil then
		v_u_20_:setInt("environment.growth#currentPeriod", self.currentGrowthPeriod)
	end
	v_u_20_:setSortedTable("environment.growth.queue.period", self.growthQueue, function(p21_, p22_)
		-- upvalues: (copy) v_u_20_
		v_u_20_:setInt(p21_, p22_)
	end)
	v_u_20_:delete()
end

-- Local values: filename, updater
function GrowthSystem:saveState(directory)
	for v25_, v26_ in pairs(self.fieldCropsUpdaters) do
		saveCropsGrowthStateToFile(v26_.updater, directory .. "/" .. v25_ .. "_growthState.xml")
	end
	if self.weedUpdater ~= nil then
		saveDensityMapUpdaterStateToFile(self.weedUpdater, directory .. "/weed_growthState.xml")
	end
	if self.stoneUpdater ~= nil then
		saveDensityMapUpdaterStateToFile(self.stoneUpdater, directory .. "/stone_growthState.xml")
	end
end

-- Local values: mission, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, weedSystem, densityMap, firstChannel, numChannels, minValue, maxValue, stoneSystem, densityMap, firstChannel, numChannels, minValue, maxValue, _, updater, constr, name, id, fruitType, groundTypeChangedValue, groundTypeChangeMask, _, v, value, dir, filename, updater
function GrowthSystem:onTerrainLoad(terrainRootNode)
	if self.isServer then
		local v28_ = self.mission
		local v29_, v30_, v31_ = v28_.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local v32_, v33_, v34_ = v28_.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		local v35_ = self.mission.weedSystem
		if v35_:getMapHasWeed() then
			local v36_, v37_, v38_, v39_, v40_ = v35_:getDensityMapData()
			self.weedUpdater = createDensityMapUpdater(v35_.name, v36_, v37_, v38_, v39_, v40_, 0, 0, 0, 0, 0)
			setDensityMapUpdaterMask(self.weedUpdater, v29_, v30_, v31_)
		end
		local v41_ = self.mission.stoneSystem
		if v41_:getMapHasStones() then
			local v42_, v43_, v44_ = v41_:getDensityMapData()
			local v45_, v46_ = v41_:getMinMaxValues()
			self.stoneUpdater = createDensityMapUpdater(v41_.name, v42_, v43_, v44_, v45_, v46_, 0, 0, 0, 0, 0)
		end
		for _, v47_ in pairs(self.fieldCropsUpdaters) do
			local v48_ = FieldCropsUpdaterConstructor.new(self.fieldCropsUpdatersCellSize)
			for v49_, v50_ in pairs(v47_.ids) do
				local v51_ = g_fruitTypeManager:getFruitTypeByName(v49_)
				local v52_ = FieldGroundType.getValueByType(v51_.groundTypeChangeType)
				local v53_
				if #v51_.groundTypeChangeMaskTypes > 0 then
					v53_ = 0
					for _, v54_ in ipairs(v51_.groundTypeChangeMaskTypes) do
						local v55_ = FieldGroundType.getValueByType(v54_)
						local v56_ = bit32.lshift(1, v55_)
						v53_ = bit32.bor(v53_, v56_)
					end
				else
					v53_ = 4294967295
				end
				v48_:addCropType(v50_, v51_.numGrowthStates, 0, v51_.resetsSpray, v51_.groundTypeChangeGrowthState, v52_, v53_)
			end
			v48_:setGroundTerrainDetail(v32_, v33_, v34_, v30_, v31_)
			v47_.updater = v48_:finalize("CropsUpdater")
		end
		self:setGrowthEnabled(false)
		if self.missionInfo.isValid and self.missionInfo.densityMapRevision == g_densityMapRevision then
			local v57_ = self.missionInfo.savegameDirectory
			for v58_, v59_ in pairs(self.fieldCropsUpdaters) do
				loadCropsGrowthStateFromFile(v59_.updater, v57_ .. "/" .. v58_ .. "_growthState.xml")
			end
			if self.weedUpdater ~= nil then
				loadDensityMapUpdaterStateFromFile(self.weedUpdater, v57_ .. "/weed_growthState.xml")
			end
			if self.stoneUpdater ~= nil then
				loadDensityMapUpdaterStateFromFile(self.stoneUpdater, v57_ .. "/stone_growthState.xml")
			end
		end
	end
end

-- Local values: updater
function GrowthSystem:setFruitLayer(mapName, fruitType, layerName, id)
	if self.fieldCropsUpdaters[mapName] == nil then
		self.fieldCropsUpdaters[mapName] = {
			["ids"] = {}
		}
	end
	self.fieldCropsUpdaters[mapName].ids[fruitType.layerName] = id
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

-- Local values: transitionPeriod
function GrowthSystem:onPeriodChanged()
	local v66_ = self.environment.currentPeriod - 1
	self:triggerGrowth(v66_ == 0 and 12 or v66_)
end

-- Local values: _, updater
function GrowthSystem:onSleepChanged(isSleeping)
	if self.isServer then
		for _, v68_ in pairs(self.fieldCropsUpdaters) do
			setApplyCropsGrowthMaxTimePerFrame(v68_.updater, self:getMaxUpdateTime())
		end
		if self.weedUpdater ~= nil and self.missionInfo.weedsEnabled then
			setDensityMapUpdaterApplyMaxTimePerFrame(self.weedUpdater, self:getMaxUpdateTime())
		end
		if self.stoneUpdater ~= nil and self.missionInfo.stonesEnabled then
			setDensityMapUpdaterApplyMaxTimePerFrame(self.stoneUpdater, self:getMaxUpdateTime())
		end
	end
end

-- Local values: _, updater, name, id, fruitTypeDesc, growthMapping, growthData, growthData, from, from, from, to, _, mapping
function GrowthSystem:setMonthEngineState(period)
	for _, v71_ in pairs(self.fieldCropsUpdaters) do
		for v72_, v73_ in pairs(v71_.ids) do
			local v74_ = g_fruitTypeManager:getFruitTypeByName(v72_)
			local v75_ = nil
			if self.missionInfo.growthMode == GrowthMode.SEASONAL then
				local v76_ = v74_:getSeasonalGrowthData()
				if v76_ ~= nil then
					v75_ = v76_.periods[period].growthMapping
				end
			elseif self.missionInfo.growthMode == GrowthMode.DAILY then
				local v77_ = v74_:getNonSeasonalGrowthData()
				if v77_ ~= nil then
					v75_ = v77_.growthMapping
				end
			end
			if v75_ == nil then
				for v78_ = 1, v74_.numGrowthStates - 1 do
					setCropsGrowthNextState(v71_.updater, v73_, v78_, v78_ + 1)
				end
				if v74_.regrows then
					setCropsGrowthNextState(v71_.updater, v73_, v74_.cutState, v74_.firstRegrowthState)
				end
			else
				for v79_ = 1, #v75_ do
					setCropsGrowthNextState(v71_.updater, v73_, v79_, v75_[v79_])
				end
			end
		end
	end
	if self.weedUpdater ~= nil then
		for v80_, v81_ in pairs(self.mission.weedSystem:getGrowthMapping()) do
			setDensityMapUpdaterNextValue(self.weedUpdater, 0, v80_, v81_)
		end
	end
	if self.stoneUpdater ~= nil then
		for _, v82_ in ipairs(self.mission.stoneSystem:getGrowthMapping()) do
			if v82_.period == period then
				setDensityMapUpdaterNextValue(self.stoneUpdater, 0, v82_.from, v82_.to)
			end
		end
	end
end

function GrowthSystem:triggerGrowth(period)
	if self.currentGrowthPeriod == nil then
		self:startEngineGrowth(period)
	else
		self.growthQueue[#self.growthQueue + 1] = period
	end
end

-- Local values: _, updater
function GrowthSystem:startEngineGrowth(period)
	Logging.devInfo("GrowthSystem:startEngineGrowth Period %d (%s) - Pending growth tasks %d", period, SeasonPeriod.getName(period), #self.growthQueue)
	g_messageCenter:publish(MessageType.START_GROWTH_PERIOD, period)
	self:setMonthEngineState(period)
	self.currentGrowthPeriod = period
	self.numEngineStepsActive = 0
	if self.missionInfo.growthMode == GrowthMode.DISABLED then
		self:onEngineGrowthFinished()
	else
		for _, v87_ in pairs(self.fieldCropsUpdaters) do
			self.numEngineStepsActive = self.numEngineStepsActive + 1
			applyCropsGrowth(v87_.updater, "onEngineStepFinished", self, self:getMaxUpdateTime())
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

-- Local values: finishedPeriod, hasPendingGrowth, period
function GrowthSystem:onEngineGrowthFinished()
	local v89_ = self.currentGrowthPeriod
	self.currentGrowthPeriod = nil
	Logging.devInfo("GrowthSystem:onEngineGrowthFinished Period %d (%s)", v89_, SeasonPeriod.getName(v89_))
	local v90_ = #self.growthQueue > 0
	if v90_ then
		local v91_ = self.growthQueue[1]
		table.remove(self.growthQueue, 1)
		self:startEngineGrowth(v91_)
	end
	g_messageCenter:publish(MessageType.FINISHED_GROWTH_PERIOD, v89_, v90_)
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
		Logging.info("Savegame Setting \'growthMode\': %d", mode)
	end
end

function GrowthSystem:getGrowthMode()
	return self.missionInfo.growthMode
end

-- Local values: _, updater
function GrowthSystem:setGrowthMask(map, firstChannel, numChannels)
	for _, v101_ in pairs(self.fieldCropsUpdaters) do
		if v101_.updater ~= nil then
			setCropsGrowthMask(v101_.updater, map, firstChannel, numChannels)
		end
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

-- Local values: _, updater
function GrowthSystem:setGrowthEnabled(isEnabled)
	self.growthEnabled = isEnabled
	for _, v105_ in pairs(self.fieldCropsUpdaters) do
		if v105_.updater ~= nil then
			setCropsEnableGrowth(v105_.updater, isEnabled)
		end
	end
	if self.weedUpdater ~= nil then
		setDensityMapUpdaterEnabled(self.weedUpdater, isEnabled)
	end
end

function GrowthSystem:onWeedGrowthChanged() end

-- Local values: usage
function GrowthSystem:consoleCommandGrowNow(period)
	local v108_ = tonumber(period)
	if v108_ == nil then
		return "Error: No isPaused given. Usage: gsGrowNow isPaused(1..12)"
	end
	self:triggerGrowth(v108_)
	return "Triggered growth"
end
