-- Local values: SavegameSettingsEvent_mt
SavegameSettingsEvent = {}
local SavegameSettingsEvent_mt = Class(SavegameSettingsEvent, Event)
InitStaticEventClass(SavegameSettingsEvent, "SavegameSettingsEvent")
function SavegameSettingsEvent.emptyNew()
	-- upvalues: (copy) SavegameSettingsEvent_mt
	return Event.new(SavegameSettingsEvent_mt)
end
function SavegameSettingsEvent.new()
	return SavegameSettingsEvent.emptyNew()
end

-- Local values: timeScale, economicDifficulty, isSnowEnabled, growthMode, fruitDestruction, plowingRequired, stonesEnabled, limeRequired, weedsEnabled, automaticMotorStartEnabled, trafficEnabled, stopAndGoBraking, trailerFillLimit, savegameName, dirtInterval, autoSaveInterval, fixedSeasonalVisuals, plannedDaysPerPeriod, fuelUsage, helperBuyFuel, helperBuySeeds, helperBuyFertilizer, helperSlurrySource, helperManureSource, disasterDestructionState, mission
function SavegameSettingsEvent:readStream(streamId, connection)
	local v5_ = streamReadFloat32(streamId)
	local v6_ = EconomicDifficulty.readStream(streamId)
	local v7_ = streamReadBool(streamId)
	local v8_ = GrowthMode.readStream(streamId)
	local v9_ = streamReadBool(streamId)
	local v10_ = streamReadBool(streamId)
	local v11_ = streamReadBool(streamId)
	local v12_ = streamReadBool(streamId)
	local v13_ = streamReadBool(streamId)
	local v14_ = streamReadBool(streamId)
	local v15_ = streamReadBool(streamId)
	local v16_ = streamReadBool(streamId)
	local v17_ = streamReadBool(streamId)
	local v18_ = streamReadString(streamId)
	local v19_ = streamReadUIntN(streamId, 3)
	local v20_ = streamReadInt32(streamId)
	local v21_ = streamReadUIntN(streamId, 4)
	if v21_ == 0 then
		v21_ = nil
	end
	local v22_ = streamReadUIntN(streamId, 5)
	local v23_ = streamReadUIntN(streamId, 2)
	local v24_ = streamReadBool(streamId)
	local v25_ = streamReadBool(streamId)
	local v26_ = streamReadBool(streamId)
	local v27_ = streamReadUIntN(streamId, 4)
	local v28_ = streamReadUIntN(streamId, 4)
	local v29_ = DisasterDestructionState.readStream(streamId)
	local v30_ = g_currentMission
	if connection:getIsServer() or v30_.userManager:getIsConnectionMasterUser(connection) then
		v30_:setTimeScale(v5_, true)
		v30_:setEconomicDifficulty(v6_, true)
		v30_:setSnowEnabled(v7_, true)
		v30_:setGrowthMode(v8_, true)
		v30_:setFruitDestructionEnabled(v9_, true)
		v30_:setPlowingRequiredEnabled(v10_, true)
		v30_:setStonesEnabled(v11_, true)
		v30_:setLimeRequired(v12_, true)
		v30_:setWeedsEnabled(v13_, true)
		v30_:setSavegameName(v18_, true)
		v30_:setDirtInterval(v19_, true)
		v30_:setAutoSaveInterval(v20_, true)
		v30_:setFixedSeasonalVisuals(v21_, true)
		v30_:setPlannedDaysPerPeriod(v22_, true)
		v30_:setAutomaticMotorStartEnabled(v14_, true)
		v30_:setTrafficEnabled(v15_, true)
		v30_:setHelperBuyFuel(v24_, true)
		v30_:setHelperBuySeeds(v25_, true)
		v30_:setHelperBuyFertilizer(v26_, true)
		v30_:setHelperSlurrySource(v27_, true)
		v30_:setHelperManureSource(v28_, true)
		v30_:setFuelUsage(v23_, true)
		v30_:setStopAndGoBraking(v16_, true)
		v30_:setTrailerFillLimit(v17_, true)
		v30_:setDisasterDestructionState(v29_, true)
		if not connection:getIsServer() then
			g_server:broadcastEvent(self, false, connection)
		end
	end
end

-- Local values: mission, missionInfo
function SavegameSettingsEvent:writeStream(streamId, connection)
	local v32_ = g_currentMission.missionInfo
	streamWriteFloat32(streamId, v32_.timeScale)
	EconomicDifficulty.writeStream(streamId, v32_.economicDifficulty)
	streamWriteBool(streamId, v32_.isSnowEnabled)
	GrowthMode.writeStream(streamId, v32_.growthMode)
	streamWriteBool(streamId, v32_.fruitDestruction)
	streamWriteBool(streamId, v32_.plowingRequiredEnabled)
	streamWriteBool(streamId, v32_.stonesEnabled)
	streamWriteBool(streamId, v32_.limeRequired)
	streamWriteBool(streamId, v32_.weedsEnabled)
	streamWriteBool(streamId, v32_.automaticMotorStartEnabled)
	streamWriteBool(streamId, v32_.trafficEnabled)
	streamWriteBool(streamId, v32_.stopAndGoBraking)
	streamWriteBool(streamId, v32_.trailerFillLimit)
	streamWriteString(streamId, v32_.savegameName)
	streamWriteUIntN(streamId, v32_.dirtInterval, 3)
	streamWriteInt32(streamId, g_autoSaveManager:getInterval())
	streamWriteUIntN(streamId, v32_.fixedSeasonalVisuals or 0, 4)
	streamWriteUIntN(streamId, v32_.plannedDaysPerPeriod, 5)
	streamWriteUIntN(streamId, v32_.fuelUsage, 2)
	streamWriteBool(streamId, v32_.helperBuyFuel)
	streamWriteBool(streamId, v32_.helperBuySeeds)
	streamWriteBool(streamId, v32_.helperBuyFertilizer)
	streamWriteUIntN(streamId, v32_.helperSlurrySource, 4)
	streamWriteUIntN(streamId, v32_.helperManureSource, 4)
	DisasterDestructionState.writeStream(streamId, v32_.disasterDestructionState)
end

function SavegameSettingsEvent:run(connection)
	printError("Error: SavegameSettingsEvent is not allowed to be executed on a local client")
end

function SavegameSettingsEvent.sendEvent(noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_currentMission:getIsServer() then
			g_server:broadcastEvent(SavegameSettingsEvent.new(), false)
			return
		end
		g_client:getServerConnection():sendEvent(SavegameSettingsEvent.new())
	end
end
