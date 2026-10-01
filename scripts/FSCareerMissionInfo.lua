FSCareerMissionInfo = {}
local FSCareerMissionInfo_mt = Class(FSCareerMissionInfo, MissionInfo)
FSCareerMissionInfo.SavegameRevision = 2
if GS_PLATFORM_PLAYSTATION then
	FSCareerMissionInfo.MaxSavegameSize = 52428800
else
	FSCareerMissionInfo.MaxSavegameSize = 26214400
end
function FSCareerMissionInfo.new(baseDirectory, customEnvironment, savegameIndex, customMt)
	local self = FSCareerMissionInfo:superClass().new(baseDirectory, customEnvironment, customMt or FSCareerMissionInfo_mt)
	self.savegameIndex = savegameIndex
	self.savegameDirectory = self:getSavegameDirectory(self.savegameIndex)
	self.displayName = g_i18n:getText("ui_savegame") .. " " .. self.savegameIndex
	self.xmlKey = "careerSavegame"
	self.tipTypeMappings = {}
	return self
end
function FSCareerMissionInfo:delete()
	if self.xmlFile ~= nil then
		delete(self.xmlFile)
	end
end
function FSCareerMissionInfo:loadDefaults()
	FSCareerMissionInfo:superClass().loadDefaults(self)
	self.supportsSaving = true
	self.isValid = false
	self.initialPlatformId = getPlatformId()
	self.isCrossPlatformSavegame = true
	self.initialLoan = 0
	self.initialMoney = 100000
	self.money = nil
	self.economicDifficulty = EconomicDifficulty.NORMAL
	self.hasInitiallyOwnedFarmlands = true
	self.loadDefaultFarm = true
	self.startWithGuidedTour = true
	self.playTime = 0
	self.isInvalidUser = false
	self.isCorruptFile = false
	self.savegameName = g_i18n:getText("defaultSavegameName")
	self.saveDateFormatted = "--/--/--"
	self.creationDate = getDate("%Y-%m-%d")
	self.saveDate = nil
	self.mapId = nil
	self.stopAndGoBraking = true
	self.trailerFillLimit = false
	self.fruitDestruction = true
	self.automaticMotorStartEnabled = true
	self.isSnowEnabled = Platform.gameplay.supportSnow
	self.growthMode = Platform.gameplay.supportSeasonalGrowth and GrowthMode.SEASONAL or GrowthMode.DAILY
	self.fixedSeasonalVisuals = nil
	self.helperBuyFuel = true
	self.helperBuySeeds = true
	self.helperBuyFertilizer = true
	self.helperSlurrySource = 2
	self.helperManureSource = 2
	self.plowingRequiredEnabled = Utils.getNoNil(Platform.gameplay.defaultPlowingRequiredEnabled, false)
	self.stonesEnabled = true
	self.autoSaveInterval = AutoSaveManager.DEFAULT_INTERVAL
	self.trafficEnabled = true
	self.introductionHelpShownElements = ""
	self.introductionHelpShownHints = ""
	self.introductionHelpActive = false
	self.disasterDestructionState = DisasterDestructionState.ENABLED
	self.slotUsage = 0
	self.plannedDaysPerPeriod = 1
	self.timeScale = Platform.gameplay.defaultTimeScale
	self.timeScaleMultiplier = 1
	self.dirtInterval = 3
	self.weedsEnabled = true
	self.limeRequired = true
	self.fuelUsage = 2
	self.foundHelpIcons = "00000000000000000000"
	self.vehiclesXML = nil
	self.itemsXML = nil
	self.placeablesXML = nil
	self.handToolsXML = nil
	self.aiSystemXML = nil
	self.onCreateObjectsXML = nil
	self.environmentXML = nil
	self.vehicleSaleXML = nil
	self.economyXML = nil
	self.farmlandXML = nil
	self.npcXML = nil
	self.missionsXML = nil
	self.guidedTourXML = nil
	self.fieldsXML = nil
	self.destructibleMapObjectsXML = nil
	self.farmsXML = nil
	self.treeMarkerXML = nil
	self.playersXML = nil
	self.densityMapHeightXML = nil
	self.treePlantXML = nil
	self.navigationSystemXML = nil
	self.densityMapRevision = -1
	self.terrainTextureRevision = -1
	self.terrainLodTextureRevision = -1
	self.splitShapesRevision = -1
	self.tipCollisionRevision = -1
	self.placementCollisionRevision = -1
	self.navigationCollisionRevision = -1
	self.mapDensityMapRevision = 1
	self.mapTerrainTextureRevision = 1
	self.mapTerrainLodTextureRevision = 1
	self.mapSplitShapesRevision = 1
	self.mapTipCollisionRevision = 1
	self.mapPlacementCollisionRevision = 1
	self.mapNavigationCollisionRevision = 1
	self.tipTypeMappings = {}
	self.mods = {}
end
function FSCareerMissionInfo:loadFromXML(xmlFile)
	local key = self.xmlKey
	local revision = getXMLInt(xmlFile, key .. "#revision")
	if revision ~= FSCareerMissionInfo.SavegameRevision then
		return false
	end
	self.isValid = getXMLBool(xmlFile, key .. "#valid")
	if self.isValid == nil then
		return false
	else
		if self.isValid then
			local mapId = getXMLString(xmlFile, key .. ".settings.mapId")
			if mapId == nil then
				return false
			end
			self.mapTitle = getXMLString(xmlFile, key .. ".settings.mapTitle")
			self:setMapId(mapId)
			self.isInvalidUser = false
			self.savegameName = filterText(Utils.getNoNil(getXMLString(xmlFile, key .. ".settings.savegameName"), self.savegameName), true, true)
			self.creationDate = Utils.getNoNil(getXMLString(xmlFile, key .. ".settings.creationDate"), self.creationDate)
			self.isCrossPlatformSavegame = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.isCrossPlatformSavegame"), false)
			self.initialPlatformId = Utils.getNoNil(PlatformId[getXMLString(xmlFile, key .. ".settings.initialPlatformName")], self.initialPlatformId)
			self.economicDifficulty = EconomicDifficulty.loadFromXMLFile(xmlFile, key .. ".settings.economicDifficulty") or self.economicDifficulty
			self.initialLoan = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.initialLoan"), self.initialLoan)
			self.initialMoney = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.initialMoney"), self.initialMoney)
			self.hasInitiallyOwnedFarmlands = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.hasInitiallyOwnedFarmlands"), self.hasInitiallyOwnedFarmlands)
			self.loadDefaultFarm = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.loadDefaultFarm"), self.loadDefaultFarm)
			self.startWithGuidedTour = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.startWithGuidedTour"), self.startWithGuidedTour)
			self.densityMapRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.densityMapRevision"), self.densityMapRevision)
			self.terrainTextureRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.terrainTextureRevision"), self.terrainTextureRevision)
			self.terrainLodTextureRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.terrainLodTextureRevision"), self.terrainLodTextureRevision)
			self.splitShapesRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.splitShapesRevision"), self.splitShapesRevision)
			self.tipCollisionRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.tipCollisionRevision"), self.tipCollisionRevision)
			self.placementCollisionRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.placementCollisionRevision"), self.placementCollisionRevision)
			self.navigationCollisionRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.navigationCollisionRevision"), self.navigationCollisionRevision)
			self.mapDensityMapRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.mapDensityMapRevision"), self.mapDensityMapRevision)
			self.mapTerrainTextureRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.mapTerrainTextureRevision"), self.mapTerrainTextureRevision)
			self.mapTerrainLodTextureRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.mapTerrainLodTextureRevision"), self.mapTerrainLodTextureRevision)
			self.mapSplitShapesRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.mapSplitShapesRevision"), self.mapSplitShapesRevision)
			self.mapTipCollisionRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.mapTipCollisionRevision"), self.mapTipCollisionRevision)
			self.mapPlacementCollisionRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.mapPlacementCollisionRevision"), self.mapPlacementCollisionRevision)
			self.mapNavigationCollisionRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.mapNavigationCollisionRevision"), self.mapNavigationCollisionRevision)
			self.stopAndGoBraking = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.stopAndGoBraking"), self.stopAndGoBraking)
			self.trailerFillLimit = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.trailerFillLimit"), self.trailerFillLimit)
			self.fruitDestruction = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.fruitDestruction"), self.fruitDestruction)
			self.plowingRequiredEnabled = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.plowingRequiredEnabled"), self.plowingRequiredEnabled)
			self.stonesEnabled = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.stonesEnabled"), self.stonesEnabled)
			self.weedsEnabled = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.weedsEnabled"), self.weedsEnabled)
			self.limeRequired = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.limeRequired"), self.limeRequired)
			self.automaticMotorStartEnabled = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.automaticMotorStartEnabled"), self.automaticMotorStartEnabled)
			self.fuelUsage = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.fuelUsage"), self.fuelUsage)
			self.helperBuyFuel = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.helperBuyFuel"), self.helperBuyFuel)
			self.helperBuySeeds = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.helperBuySeeds"), self.helperBuySeeds)
			self.helperBuyFertilizer = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.helperBuyFertilizer"), self.helperBuyFertilizer)
			self.helperSlurrySource = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.helperSlurrySource"), self.helperSlurrySource)
			self.helperManureSource = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.helperManureSource"), self.helperManureSource)
			self.saveDate = Utils.getNoNil(getXMLString(xmlFile, key .. ".settings.saveDate"), nil)
			self.saveDateFormatted = Utils.getNoNil(getXMLString(xmlFile, key .. ".settings.saveDateFormatted"), self.saveDate)
			self.timeScale = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".settings.timeScale"), Platform.gameplay.defaultTimeScale)
			self.trafficEnabled = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.trafficEnabled"), self.trafficEnabled)
			self.dirtInterval = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.dirtInterval"), self.dirtInterval)
			self.growthMode = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.growthMode"), self.growthMode)
			self.isSnowEnabled = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.isSnowEnabled"), self.isSnowEnabled)
			self.fixedSeasonalVisuals = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.fixedSeasonalVisuals"), self.fixedSeasonalVisuals)
			self.plannedDaysPerPeriod = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.plannedDaysPerPeriod"), self.plannedDaysPerPeriod)
			self.autoSaveInterval = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".settings.autoSaveInterval"), self.autoSaveInterval)
			self.foundHelpIcons = Utils.getNoNil(getXMLString(xmlFile, key .. ".map.foundHelpIcons"), self.foundHelpIcons)
			self.playTime = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".statistics.playTime"), self.playTime)
			self.money = Utils.getNoNil(tonumber(getXMLString(xmlFile, key .. ".statistics.money")), self.money)
			self.slotUsage = Utils.getNoNil(getXMLInt(xmlFile, key .. ".slotSystem#slotUsage"), self.slotUsage)
			self.disasterDestructionState = DisasterDestructionState.loadFromXMLFile(xmlFile, key .. ".settings.disasterDestructionState") or self.disasterDestructionState
			self.introductionHelpActive = Utils.getNoNil(getXMLBool(xmlFile, key .. ".introductionHelp#active"), self.introductionHelpActive)
			self.introductionHelpShownElements = Utils.getNoNil(getXMLString(xmlFile, key .. ".introductionHelp.shownElements"), self.introductionHelpShownElements)
			self.introductionHelpShownHints = Utils.getNoNil(getXMLString(xmlFile, key .. ".introductionHelp.shownHints"), self.introductionHelpShownHints)
			self.mapsSplitShapeFileIds = {}
			local numSplitShapeFileIds = Utils.getNoNil(getXMLInt(xmlFile, key .. ".mapsSplitShapeFileIds#count"), 0)
			for i = 1, numSplitShapeFileIds do
				local fileIdKey = string.format("%s.mapsSplitShapeFileIds.id(%d)", key, i - 1)
				local id = Utils.getNoNil(getXMLInt(xmlFile, fileIdKey .. "#id"), -1)
				table.insert(self.mapsSplitShapeFileIds, id)
			end
			local mapModNameParts = nil
			if self.mapId ~= nil then
				mapModNameParts = self.mapId:split(".")
			end
			self.foliageTypes = {}
			local i = 0
			while true do
				local modKey = string.format("careerSavegame.foliageTypes.foliageType(%d)", i)
				if not hasXMLProperty(xmlFile, modKey) then
					break
				end
				local name = getXMLString(xmlFile, modKey .. "#name")
				local filename = getXMLString(xmlFile, modKey .. "#filename")
				if name ~= nil and filename ~= nil then
					filename = NetworkUtil.convertFromNetworkFilename(filename)
					table.insert(self.foliageTypes, { name = name, filename = filename })
				end
				i = i + 1
			end
			self.mods = {}
			i = 0
			while true do
				local modKey = key .. string.format(".mod(%d)", i)
				if not hasXMLProperty(xmlFile, modKey) then
					break
				end
				local modName = getXMLString(xmlFile, modKey .. "#modName")
				local title = getXMLString(xmlFile, modKey .. "#title")
				local version = getXMLString(xmlFile, modKey .. "#version")
				local fileHash = getXMLString(xmlFile, modKey .. "#fileHash")
				local required = Utils.getNoNil(getXMLBool(xmlFile, modKey .. "#required"), true)
				if modName ~= nil and title ~= nil then
					table.insert(self.mods, { modName = modName, title = title, version = version, fileHash = fileHash, required = required })
				end
				if self.mapTitle == nil and (mapModNameParts ~= nil and (#mapModNameParts == 2 and modName == mapModNameParts[1])) then
					self.mapTitle = title .. " - " .. mapModNameParts[2]
				end
				i = i + 1
			end
		end
		return true
	end
end
function FSCareerMissionInfo:saveToXMLFile()
	if self.xmlFile ~= nil then
		delete(self.xmlFile)
	end
	local xmlFile = createXMLFile("careerSavegameXML", "", "careerSavegame")
	if xmlFile == 0 then
		Logging.error("Failed to create careerSavegame xml file")
	else
		self.xmlFile = xmlFile
		local key = self.xmlKey
		setXMLInt(xmlFile, key .. "#revision", FSCareerMissionInfo.SavegameRevision)
		setXMLBool(xmlFile, key .. "#valid", self.isValid)
		if self.isValid then
			setXMLString(xmlFile, key .. ".settings.savegameName", self.savegameName)
			setXMLString(xmlFile, key .. ".settings.creationDate", self.creationDate)
			setXMLString(xmlFile, key .. ".settings.mapId", self.mapId)
			setXMLString(xmlFile, key .. ".settings.mapTitle", self.map.title)
			setXMLString(xmlFile, key .. ".settings.saveDateFormatted", self.saveDateFormatted)
			setXMLString(xmlFile, key .. ".settings.saveDate", self.saveDate)
			setXMLInt(xmlFile, key .. ".settings.initialMoney", self.initialMoney)
			setXMLInt(xmlFile, key .. ".settings.initialLoan", self.initialLoan)
			EconomicDifficulty.saveToXMLFile(xmlFile, key .. ".settings.economicDifficulty", self.economicDifficulty)
			setXMLBool(xmlFile, key .. ".settings.hasInitiallyOwnedFarmlands", self.hasInitiallyOwnedFarmlands)
			setXMLBool(xmlFile, key .. ".settings.loadDefaultFarm", self.loadDefaultFarm)
			setXMLBool(xmlFile, key .. ".settings.startWithGuidedTour", self.startWithGuidedTour)
			setXMLBool(xmlFile, key .. ".settings.trafficEnabled", self.trafficEnabled)
			setXMLBool(xmlFile, key .. ".settings.stopAndGoBraking", self.stopAndGoBraking)
			setXMLBool(xmlFile, key .. ".settings.trailerFillLimit", self.trailerFillLimit)
			setXMLBool(xmlFile, key .. ".settings.automaticMotorStartEnabled", self.automaticMotorStartEnabled)
			setXMLInt(xmlFile, key .. ".settings.growthMode", self.growthMode)
			if self.fixedSeasonalVisuals ~= nil then
				setXMLInt(xmlFile, key .. ".settings.fixedSeasonalVisuals", self.fixedSeasonalVisuals)
			end
			setXMLInt(xmlFile, key .. ".settings.plannedDaysPerPeriod", self.plannedDaysPerPeriod)
			setXMLBool(xmlFile, key .. ".settings.fruitDestruction", self.fruitDestruction)
			setXMLBool(xmlFile, key .. ".settings.plowingRequiredEnabled", self.plowingRequiredEnabled)
			setXMLBool(xmlFile, key .. ".settings.stonesEnabled", self.stonesEnabled)
			setXMLBool(xmlFile, key .. ".settings.weedsEnabled", self.weedsEnabled)
			setXMLBool(xmlFile, key .. ".settings.limeRequired", self.limeRequired)
			setXMLBool(xmlFile, key .. ".settings.isSnowEnabled", self.isSnowEnabled)
			setXMLInt(xmlFile, key .. ".settings.fuelUsage", self.fuelUsage)
			setXMLBool(xmlFile, key .. ".settings.helperBuyFuel", self.helperBuyFuel)
			setXMLBool(xmlFile, key .. ".settings.helperBuySeeds", self.helperBuySeeds)
			setXMLBool(xmlFile, key .. ".settings.helperBuyFertilizer", self.helperBuyFertilizer)
			setXMLInt(xmlFile, key .. ".settings.helperSlurrySource", self.helperSlurrySource)
			setXMLInt(xmlFile, key .. ".settings.helperManureSource", self.helperManureSource)
			setXMLInt(xmlFile, key .. ".settings.densityMapRevision", self.densityMapRevision)
			setXMLInt(xmlFile, key .. ".settings.terrainTextureRevision", self.terrainTextureRevision)
			setXMLInt(xmlFile, key .. ".settings.terrainLodTextureRevision", self.terrainLodTextureRevision)
			setXMLInt(xmlFile, key .. ".settings.splitShapesRevision", self.splitShapesRevision)
			setXMLInt(xmlFile, key .. ".settings.tipCollisionRevision", self.tipCollisionRevision)
			setXMLInt(xmlFile, key .. ".settings.placementCollisionRevision", self.placementCollisionRevision)
			setXMLInt(xmlFile, key .. ".settings.navigationCollisionRevision", self.navigationCollisionRevision)
			setXMLInt(xmlFile, key .. ".settings.mapDensityMapRevision", self.mapDensityMapRevision)
			setXMLInt(xmlFile, key .. ".settings.mapTerrainTextureRevision", self.mapTerrainTextureRevision)
			setXMLInt(xmlFile, key .. ".settings.mapTerrainLodTextureRevision", self.mapTerrainLodTextureRevision)
			setXMLInt(xmlFile, key .. ".settings.mapSplitShapesRevision", self.mapSplitShapesRevision)
			setXMLInt(xmlFile, key .. ".settings.mapTipCollisionRevision", self.mapTipCollisionRevision)
			setXMLInt(xmlFile, key .. ".settings.mapPlacementCollisionRevision", self.mapPlacementCollisionRevision)
			setXMLInt(xmlFile, key .. ".settings.mapNavigationCollisionRevision", self.mapNavigationCollisionRevision)
			DisasterDestructionState.saveToXMLFile(xmlFile, key .. ".settings.disasterDestructionState", self.disasterDestructionState)
			setXMLInt(xmlFile, key .. ".settings.dirtInterval", self.dirtInterval)
			setXMLFloat(xmlFile, key .. ".settings.timeScale", self.timeScale)
			setXMLFloat(xmlFile, key .. ".settings.autoSaveInterval", g_autoSaveManager:getInterval())
			setXMLString(xmlFile, key .. ".map.foundHelpIcons", self.foundHelpIcons)
			setXMLBool(xmlFile, key .. ".introductionHelp#active", self.introductionHelpActive)
			setXMLString(xmlFile, key .. ".introductionHelp.shownElements", self.introductionHelpShownElements)
			setXMLString(xmlFile, key .. ".introductionHelp.shownHints", self.introductionHelpShownHints)
			local money = 0
			local maxPlayTime = 0
			for _, farm in ipairs(g_farmManager.farms) do
				if farm.isSpectator then
					continue
				end
				money = money + farm.money
				maxPlayTime = math.max(maxPlayTime, farm.stats:getTotalValue("playTime"))
			end
			setXMLString(xmlFile, key .. ".statistics.money", tostring(math.floor(money + 0.0001)))
			setXMLFloat(xmlFile, key .. ".statistics.playTime", maxPlayTime)
			setXMLInt(xmlFile, key .. ".mapsSplitShapeFileIds#count", #self.mapsSplitShapeFileIds)
			for i, id in ipairs(self.mapsSplitShapeFileIds) do
				setXMLInt(xmlFile, string.format("%s.mapsSplitShapeFileIds.id(%d)", key, i - 1) .. "#id", id)
			end
			local usedModNames = {}
			local mapModName = ClassUtil.getClassModName(self.mapId)
			if mapModName ~= nil then
				usedModNames[mapModName] = mapModName
			end
			local mission = g_currentMission
			if mission ~= nil then
				mission.slotSystem:saveToXMLFile(xmlFile, key .. ".slotSystem")
				mission.navigationSystem:saveToXMLFile(self.navigationSystemXML)
				mission.collectiblesSystem:saveToXMLFile(self.savegameDirectory .. "/collectibles.xml")
				local environmentXMLFile = createXMLFile("environmentXMLFile", self.environmentXML, "environment")
				if environmentXMLFile ~= 0 then
					mission.environment:saveToXMLFile(environmentXMLFile, "environment")
					mission.snowSystem:saveToXMLFile(environmentXMLFile, "environment.snow")
					mission.growthSystem:saveToXMLFile(environmentXMLFile, "environment.growth")
					saveXMLFile(environmentXMLFile)
					delete(environmentXMLFile)
				else
					Logging.error("Failed to create environment xml file")
				end
				mission.placeableSystem:save(self.placeablesXML, usedModNames)
				mission.vehicleSystem:save(self.vehiclesXML, usedModNames)
				mission.handToolSystem:save(self.handToolsXML, usedModNames)
				mission.itemSystem:save(self.itemsXML, usedModNames)
				mission.aiSystem:save(self.aiSystemXML, usedModNames)
				mission.onCreateObjectSystem:save(self.onCreateObjectsXML, usedModNames)
				local economyFile = createXMLFile("economyXML", self.economyXML, "economy")
				if economyFile ~= 0 then
					mission.economyManager:saveToXMLFile(economyFile, "economy")
					saveXMLFile(economyFile)
					delete(economyFile)
				else
					Logging.error("Failed to create economy xml file")
				end
				mission.playerSystem:saveToXMLFile(self.playersXML)
				mission.vehicleSaleSystem:saveToXMLFile(self.vehicleSaleXML)
				mission.foliageSystem:saveToXMLFile(xmlFile)
				mission.treeMarkerSystem:saveToXMLFile(self.treeMarkerXML)
				mission.destructibleMapObjectSystem:saveToXMLFile(self.destructibleMapObjectsXML)
				for _, modItem in pairs(mission.missionDynamicInfo.mods) do
					usedModNames[modItem.modName] = modItem.modName
				end
			end
			g_farmlandManager:saveToXMLFile(self.farmlandXML)
			g_guidedTourManager:saveToXMLFile(self.guidedTourXML)
			g_npcManager:saveToXMLFile(self.npcXML)
			g_fieldManager:saveToXMLFile(self.fieldsXML)
			g_missionManager:saveToXMLFile(self.missionsXML)
			g_farmManager:saveToXMLFile(self.farmsXML)
			g_densityMapHeightManager:saveToXMLFile(self.densityMapHeightXML)
			g_treePlantManager:saveToXMLFile(self.treePlantXML)
			local modIndex = 0
			for modName, _ in pairs(usedModNames) do
				local modItem = g_modManager:getModByName(modName)
				if modItem == nil then
					continue
				end
				local modKey = string.format("%s.mod(%d)", key, modIndex)
				local required = modName == mapModName
				setXMLString(xmlFile, modKey .. "#modName", modItem.modName)
				setXMLString(xmlFile, modKey .. "#title", modItem.title)
				setXMLString(xmlFile, modKey .. "#version", modItem.version)
				setXMLBool(xmlFile, modKey .. "#required", required)
				setXMLString(xmlFile, modKey .. "#fileHash", modItem.fileHash or "")
				if self.isCrossPlatformSavegame then
					local isCrossPlatformMod = false
					if modItem.isDLC or modItem.isInternalScriptMod then
						isCrossPlatformMod = true
					else
						if not modItem.hasScripts then
							local modId = getModIdByFilename(modItem.modName)
							if modId ~= 0 and getModMetaAttributeString(modId, "hash") == modItem.fileHash then
								isCrossPlatformMod = true
							end
						end
					end
					if not isCrossPlatformMod then
						Logging.info("Found non-crossplay mod. Disabled savegame cross platform availability")
						self.isCrossPlatformSavegame = false
					end
				end
				modIndex = modIndex + 1
			end
			setXMLBool(xmlFile, key .. ".settings.isCrossPlatformSavegame", self.isCrossPlatformSavegame)
			setXMLString(xmlFile, key .. ".settings.initialPlatformName", EnumUtil.getName(PlatformId, self.initialPlatformId))
			saveXMLFile(xmlFile)
		end
	end
end
function FSCareerMissionInfo:loadFromMission(mission)
	self.mapDensityMapRevision = mission.mapDensityMapRevision
	self.mapTerrainTextureRevision = mission.mapTerrainTextureRevision
	self.mapTerrainLodTextureRevision = mission.mapTerrainLodTextureRevision
	self.mapSplitShapesRevision = mission.mapSplitShapesRevision
	self.mapTipCollisionRevision = mission.mapTipCollisionRevision
	self.mapPlacementCollisionRevision = mission.mapPlacementCollisionRevision
	self.mapNavigationCollisionRevision = mission.mapNavigationCollisionRevision
	self.mapsSplitShapeFileIds = {}
	for _, id in ipairs(mission.mapsSplitShapeFileIds) do
		table.insert(self.mapsSplitShapeFileIds, id)
	end
	self.saveDate = getDate("%Y-%m-%d")
	self.saveDateFormatted = g_i18n:getCurrentDate()
end
function FSCareerMissionInfo:setSavegameDirectory(directory)
	self.savegameDirectory = directory
	if directory ~= nil then
		self.vehiclesXML = directory .. "/vehicles.xml"
		self.itemsXML = directory .. "/items.xml"
		self.placeablesXML = directory .. "/placeables.xml"
		self.handToolsXML = directory .. "/handTools.xml"
		self.aiSystemXML = directory .. "/aiSystem.xml"
		self.onCreateObjectsXML = directory .. "/onCreateObjects.xml"
		self.environmentXML = directory .. "/environment.xml"
		self.vehicleSaleXML = directory .. "/sales.xml"
		self.economyXML = directory .. "/economy.xml"
		self.farmlandXML = directory .. "/farmland.xml"
		self.npcXML = directory .. "/npc.xml"
		self.missionsXML = directory .. "/missions.xml"
		self.fieldsXML = directory .. "/fields.xml"
		self.guidedTourXML = directory .. "/guidedTour.xml"
		self.farmsXML = directory .. "/farms.xml"
		self.destructibleMapObjectsXML = directory .. "/destructibleMapObjectSystem.xml"
		self.treeMarkerXML = directory .. "/treeMarker.xml"
		self.playersXML = directory .. "/players.xml"
		self.densityMapHeightXML = directory .. "/densityMapHeight.xml"
		self.treePlantXML = directory .. "/treePlant.xml"
		self.navigationSystemXML = directory .. "/navigationSystem.xml"
	end
end
function FSCareerMissionInfo:getSavegameDirectory(index)
	return getUserProfileAppPath() .. "savegame" .. index
end
function FSCareerMissionInfo:getSavegameAutoBackupBasePath()
	return getUserProfileAppPath() .. "savegameBackup"
end
function FSCareerMissionInfo:getSavegameAutoBackupDirectoryBase(index)
	return "savegame" .. index .. "_backup"
end
function FSCareerMissionInfo:getSavegameAutoBackupLatestFilename(index)
	return "savegame" .. index .. "_backupLatest.txt"
end
function FSCareerMissionInfo:getStateI18NKey()
	if self.hasConflict and not self.isSoftConflict then
		return "savegame_state_conflicted"
	end
	if self.uploadState == UploadState.UPLOADED then
		return "savegame_state_uploaded"
	elseif self.uploadState == UploadState.NOT_UPLOADED then
		return "savegame_state_not_uploaded"
	elseif self.uploadState == UploadState.UPLOADING then
		return "savegame_state_uploading"
	else
		return nil
	end
end
function FSCareerMissionInfo:applyStartInfo(startInfo)
	self.initialLoan = startInfo.initialLoan
	self.initialMoney = startInfo.initialMoney
	self.economicDifficulty = startInfo.economicDifficulty
	self.hasInitiallyOwnedFarmlands = startInfo.hasStartFarm
	self.loadDefaultFarm = startInfo.hasStartFarm
	self.startWithGuidedTour = startInfo.startWithGuidedTour
	self:setMapId(startInfo.mapId)
end
function FSCareerMissionInfo:setMapId(mapId)
	self.mapId = mapId
	local map = g_mapManager:getMapById(self.mapId)
	if map == nil then
		return false
	else
		self.map = map
		self.mapTitle = map.title
		self.scriptFilename = map.scriptFilename
		self.scriptClass = map.className
		self.mapXMLFilename = map.mapXMLFilename
		self.defaultVehiclesXMLFilename = map.defaultVehiclesXMLFilename
		self.defaultHandToolsXMLFilename = map.defaultHandToolsXMLFilename
		self.defaultItemsXMLFilename = map.defaultItemsXMLFilename
		self.defaultPlaceablesXMLFilename = map.defaultPlaceablesXMLFilename
		self.customEnvironment = map.customEnvironment
		self.baseDirectory = map.baseDirectory
		return true
	end
end
function FSCareerMissionInfo:getIsDensityMapValid(mission)
	return self.isValid and self.densityMapRevision == g_densityMapRevision and self.mapDensityMapRevision == mission.mapDensityMapRevision
end
function FSCareerMissionInfo:getIsTerrainTextureValid(mission)
	return self.isValid and self.terrainTextureRevision == g_terrainTextureRevision and self.mapTerrainTextureRevision == mission.mapTerrainTextureRevision
end
function FSCareerMissionInfo:getIsTerrainLodTextureValid(mission)
	return self.isValid and self.terrainLodTextureRevision == g_terrainLodTextureRevision and self.mapTerrainLodTextureRevision == mission.mapTerrainLodTextureRevision
end
function FSCareerMissionInfo:getAreSplitShapesValid(mission)
	return self.isValid and self.splitShapesRevision == g_splitShapesRevision and self.mapSplitShapesRevision == mission.mapSplitShapesRevision
end
function FSCareerMissionInfo:getIsTipCollisionValid(mission)
	return self.isValid and self.tipCollisionRevision == g_tipCollisionRevision and self.mapTipCollisionRevision == mission.mapTipCollisionRevision
end
function FSCareerMissionInfo:getIsPlacementCollisionValid(mission)
	return self.isValid and self.placementCollisionRevision == g_placementCollisionRevision and self.mapPlacementCollisionRevision == mission.mapPlacementCollisionRevision
end
function FSCareerMissionInfo:getIsNavigationCollisionValid(mission)
	return self.isValid and self.navigationCollisionRevision == g_navigationCollisionRevision and self.mapNavigationCollisionRevision == mission.mapNavigationCollisionRevision
end
function FSCareerMissionInfo:getIsLoadedFromSavegame()
	return self.isValid
end
function FSCareerMissionInfo:getEffectiveTimeScale()
	return self.timeScale * (self.timeScaleMultiplier or 1)
end
