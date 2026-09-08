-- Local values: FSCareerMissionInfo_mt
FSCareerMissionInfo = {}
local FSCareerMissionInfo_mt = Class(FSCareerMissionInfo, MissionInfo)
FSCareerMissionInfo.SavegameRevision = 2
if GS_PLATFORM_PLAYSTATION then
	FSCareerMissionInfo.MaxSavegameSize = 52428800
else
	FSCareerMissionInfo.MaxSavegameSize = 26214400
end

-- Upvalues: FSCareerMissionInfo_mt
-- Local values: self
function FSCareerMissionInfo.new(baseDirectory, customEnvironment, savegameIndex, customMt)
	-- upvalues: (copy) FSCareerMissionInfo_mt
	local v6_ = FSCareerMissionInfo:superClass().new(baseDirectory, customEnvironment, customMt or FSCareerMissionInfo_mt)
	v6_.savegameIndex = savegameIndex
	v6_.savegameDirectory = v6_:getSavegameDirectory(v6_.savegameIndex)
	v6_.displayName = g_i18n:getText("ui_savegame") .. " " .. v6_.savegameIndex
	v6_.xmlKey = "careerSavegame"
	v6_.tipTypeMappings = {}
	return v6_
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

-- Local values: key, revision, mapId, numSplitShapeFileIds, i, fileIdKey, id, mapModNameParts, i, modKey, name, filename, modKey, modName, title, version, fileHash, required
function FSCareerMissionInfo:loadFromXML(xmlFile)
	local v11_ = self.xmlKey
	if getXMLInt(xmlFile, v11_ .. "#revision") ~= FSCareerMissionInfo.SavegameRevision then
		return false
	end
	self.isValid = getXMLBool(xmlFile, v11_ .. "#valid")
	if self.isValid == nil then
		return false
	end
	if self.isValid then
		local v12_ = getXMLString(xmlFile, v11_ .. ".settings.mapId")
		if v12_ == nil then
			return false
		end
		self.mapTitle = getXMLString(xmlFile, v11_ .. ".settings.mapTitle")
		self:setMapId(v12_)
		self.isInvalidUser = false
		self.savegameName = filterText(Utils.getNoNil(getXMLString(xmlFile, v11_ .. ".settings.savegameName"), self.savegameName), true, true)
		self.creationDate = Utils.getNoNil(getXMLString(xmlFile, v11_ .. ".settings.creationDate"), self.creationDate)
		self.isCrossPlatformSavegame = Utils.getNoNil(getXMLBool(xmlFile, v11_ .. ".settings.isCrossPlatformSavegame"), false)
		self.initialPlatformId = Utils.getNoNil(PlatformId[getXMLString(xmlFile, v11_ .. ".settings.initialPlatformName")], self.initialPlatformId)
		self.economicDifficulty = EconomicDifficulty.loadFromXMLFile(xmlFile, v11_ .. ".settings.economicDifficulty") or self.economicDifficulty
		self.initialLoan = Utils.getNoNil(getXMLInt(xmlFile, v11_ .. ".settings.initialLoan"), self.initialLoan)
		self.initialMoney = Utils.getNoNil(getXMLInt(xmlFile, v11_ .. ".settings.initialMoney"), self.initialMoney)
		self.hasInitiallyOwnedFarmlands = Utils.getNoNil(getXMLBool(xmlFile, v11_ .. ".settings.hasInitiallyOwnedFarmlands"), self.hasInitiallyOwnedFarmlands)
		self.loadDefaultFarm = Utils.getNoNil(getXMLBool(xmlFile, v11_ .. ".settings.loadDefaultFarm"), self.loadDefaultFarm)
		self.startWithGuidedTour = Utils.getNoNil(getXMLBool(xmlFile, v11_ .. ".settings.startWithGuidedTour"), self.startWithGuidedTour)
		self.densityMapRevision = Utils.getNoNil(getXMLInt(xmlFile, v11_ .. ".settings.densityMapRevision"), self.densityMapRevision)
		self.terrainTextureRevision = Utils.getNoNil(getXMLInt(xmlFile, v11_ .. ".settings.terrainTextureRevision"), self.terrainTextureRevision)
		self.terrainLodTextureRevision = Utils.getNoNil(getXMLInt(xmlFile, v11_ .. ".settings.terrainLodTextureRevision"), self.terrainLodTextureRevision)
		self.splitShapesRevision = Utils.getNoNil(getXMLInt(xmlFile, v11_ .. ".settings.splitShapesRevision"), self.splitShapesRevision)
		self.tipCollisionRevision = Utils.getNoNil(getXMLInt(xmlFile, v11_ .. ".settings.tipCollisionRevision"), self.tipCollisionRevision)
		self.placementCollisionRevision = Utils.getNoNil(getXMLInt(xmlFile, v11_ .. ".settings.placementCollisionRevision"), self.placementCollisionRevision)
		self.navigationCollisionRevision = Utils.getNoNil(getXMLInt(xmlFile, v11_ .. ".settings.navigationCollisionRevision"), self.navigationCollisionRevision)
		self.mapDensityMapRevision = Utils.getNoNil(getXMLInt(xmlFile, v11_ .. ".settings.mapDensityMapRevision"), self.mapDensityMapRevision)
		self.mapTerrainTextureRevision = Utils.getNoNil(getXMLInt(xmlFile, v11_ .. ".settings.mapTerrainTextureRevision"), self.mapTerrainTextureRevision)
		self.mapTerrainLodTextureRevision = Utils.getNoNil(getXMLInt(xmlFile, v11_ .. ".settings.mapTerrainLodTextureRevision"), self.mapTerrainLodTextureRevision)
		self.mapSplitShapesRevision = Utils.getNoNil(getXMLInt(xmlFile, v11_ .. ".settings.mapSplitShapesRevision"), self.mapSplitShapesRevision)
		self.mapTipCollisionRevision = Utils.getNoNil(getXMLInt(xmlFile, v11_ .. ".settings.mapTipCollisionRevision"), self.mapTipCollisionRevision)
		self.mapPlacementCollisionRevision = Utils.getNoNil(getXMLInt(xmlFile, v11_ .. ".settings.mapPlacementCollisionRevision"), self.mapPlacementCollisionRevision)
		self.mapNavigationCollisionRevision = Utils.getNoNil(getXMLInt(xmlFile, v11_ .. ".settings.mapNavigationCollisionRevision"), self.mapNavigationCollisionRevision)
		self.stopAndGoBraking = Utils.getNoNil(getXMLBool(xmlFile, v11_ .. ".settings.stopAndGoBraking"), self.stopAndGoBraking)
		self.trailerFillLimit = Utils.getNoNil(getXMLBool(xmlFile, v11_ .. ".settings.trailerFillLimit"), self.trailerFillLimit)
		self.fruitDestruction = Utils.getNoNil(getXMLBool(xmlFile, v11_ .. ".settings.fruitDestruction"), self.fruitDestruction)
		self.plowingRequiredEnabled = Utils.getNoNil(getXMLBool(xmlFile, v11_ .. ".settings.plowingRequiredEnabled"), self.plowingRequiredEnabled)
		self.stonesEnabled = Utils.getNoNil(getXMLBool(xmlFile, v11_ .. ".settings.stonesEnabled"), self.stonesEnabled)
		self.weedsEnabled = Utils.getNoNil(getXMLBool(xmlFile, v11_ .. ".settings.weedsEnabled"), self.weedsEnabled)
		self.limeRequired = Utils.getNoNil(getXMLBool(xmlFile, v11_ .. ".settings.limeRequired"), self.limeRequired)
		self.automaticMotorStartEnabled = Utils.getNoNil(getXMLBool(xmlFile, v11_ .. ".settings.automaticMotorStartEnabled"), self.automaticMotorStartEnabled)
		self.fuelUsage = Utils.getNoNil(getXMLInt(xmlFile, v11_ .. ".settings.fuelUsage"), self.fuelUsage)
		self.helperBuyFuel = Utils.getNoNil(getXMLBool(xmlFile, v11_ .. ".settings.helperBuyFuel"), self.helperBuyFuel)
		self.helperBuySeeds = Utils.getNoNil(getXMLBool(xmlFile, v11_ .. ".settings.helperBuySeeds"), self.helperBuySeeds)
		self.helperBuyFertilizer = Utils.getNoNil(getXMLBool(xmlFile, v11_ .. ".settings.helperBuyFertilizer"), self.helperBuyFertilizer)
		self.helperSlurrySource = Utils.getNoNil(getXMLInt(xmlFile, v11_ .. ".settings.helperSlurrySource"), self.helperSlurrySource)
		self.helperManureSource = Utils.getNoNil(getXMLInt(xmlFile, v11_ .. ".settings.helperManureSource"), self.helperManureSource)
		self.saveDate = Utils.getNoNil(getXMLString(xmlFile, v11_ .. ".settings.saveDate"), nil)
		self.saveDateFormatted = Utils.getNoNil(getXMLString(xmlFile, v11_ .. ".settings.saveDateFormatted"), self.saveDate)
		self.timeScale = Utils.getNoNil(getXMLFloat(xmlFile, v11_ .. ".settings.timeScale"), Platform.gameplay.defaultTimeScale)
		self.trafficEnabled = Utils.getNoNil(getXMLBool(xmlFile, v11_ .. ".settings.trafficEnabled"), self.trafficEnabled)
		self.dirtInterval = Utils.getNoNil(getXMLInt(xmlFile, v11_ .. ".settings.dirtInterval"), self.dirtInterval)
		self.growthMode = Utils.getNoNil(getXMLInt(xmlFile, v11_ .. ".settings.growthMode"), self.growthMode)
		self.isSnowEnabled = Utils.getNoNil(getXMLBool(xmlFile, v11_ .. ".settings.isSnowEnabled"), self.isSnowEnabled)
		self.fixedSeasonalVisuals = Utils.getNoNil(getXMLInt(xmlFile, v11_ .. ".settings.fixedSeasonalVisuals"), self.fixedSeasonalVisuals)
		self.plannedDaysPerPeriod = Utils.getNoNil(getXMLInt(xmlFile, v11_ .. ".settings.plannedDaysPerPeriod"), self.plannedDaysPerPeriod)
		self.autoSaveInterval = Utils.getNoNil(getXMLFloat(xmlFile, v11_ .. ".settings.autoSaveInterval"), self.autoSaveInterval)
		self.foundHelpIcons = Utils.getNoNil(getXMLString(xmlFile, v11_ .. ".map.foundHelpIcons"), self.foundHelpIcons)
		self.playTime = Utils.getNoNil(getXMLFloat(xmlFile, v11_ .. ".statistics.playTime"), self.playTime)
		local v13_ = Utils.getNoNil
		local v14_ = getXMLString
		local v15_ = v11_ .. ".statistics.money"
		self.money = v13_(tonumber(v14_(xmlFile, v15_)), self.money)
		self.slotUsage = Utils.getNoNil(getXMLInt(xmlFile, v11_ .. ".slotSystem#slotUsage"), self.slotUsage)
		self.disasterDestructionState = DisasterDestructionState.loadFromXMLFile(xmlFile, v11_ .. ".settings.disasterDestructionState") or self.disasterDestructionState
		self.introductionHelpActive = Utils.getNoNil(getXMLBool(xmlFile, v11_ .. ".introductionHelp#active"), self.introductionHelpActive)
		self.introductionHelpShownElements = Utils.getNoNil(getXMLString(xmlFile, v11_ .. ".introductionHelp.shownElements"), self.introductionHelpShownElements)
		self.introductionHelpShownHints = Utils.getNoNil(getXMLString(xmlFile, v11_ .. ".introductionHelp.shownHints"), self.introductionHelpShownHints)
		self.mapsSplitShapeFileIds = {}
		for v16_ = 1, Utils.getNoNil(getXMLInt(xmlFile, v11_ .. ".mapsSplitShapeFileIds#count"), 0) do
			local v17_ = string.format("%s.mapsSplitShapeFileIds.id(%d)", v11_, v16_ - 1)
			local v18_ = Utils.getNoNil(getXMLInt(xmlFile, v17_ .. "#id"), -1)
			local v19_ = self.mapsSplitShapeFileIds
			table.insert(v19_, v18_)
		end
		local v20_
		if self.mapId == nil then
			v20_ = nil
		else
			v20_ = self.mapId:split(".")
		end
		self.foliageTypes = {}
		local v21_ = 0
		while true do
			local v22_ = string.format("careerSavegame.foliageTypes.foliageType(%d)", v21_)
			if not hasXMLProperty(xmlFile, v22_) then
				break
			end
			local v23_ = getXMLString(xmlFile, v22_ .. "#name")
			local v24_ = getXMLString(xmlFile, v22_ .. "#filename")
			if v23_ ~= nil and v24_ ~= nil then
				local v25_ = NetworkUtil.convertFromNetworkFilename(v24_)
				local v26_ = self.foliageTypes
				table.insert(v26_, {
					["name"] = v23_,
					["filename"] = v25_
				})
			end
			v21_ = v21_ + 1
		end
		self.mods = {}
		local v27_ = 0
		while true do
			local v28_ = v11_ .. string.format(".mod(%d)", v27_)
			if not hasXMLProperty(xmlFile, v28_) then
				break
			end
			local v29_ = getXMLString(xmlFile, v28_ .. "#modName")
			local v30_ = getXMLString(xmlFile, v28_ .. "#title")
			local v31_ = getXMLString(xmlFile, v28_ .. "#version")
			local v32_ = getXMLString(xmlFile, v28_ .. "#fileHash")
			local v33_ = Utils.getNoNil(getXMLBool(xmlFile, v28_ .. "#required"), true)
			if v29_ ~= nil and v30_ ~= nil then
				local v34_ = self.mods
				table.insert(v34_, {
					["modName"] = v29_,
					["title"] = v30_,
					["version"] = v31_,
					["fileHash"] = v32_,
					["required"] = v33_
				})
			end
			if self.mapTitle == nil and (v20_ ~= nil and (#v20_ == 2 and v29_ == v20_[1])) then
				self.mapTitle = v30_ .. " - " .. v20_[2]
			end
			v27_ = v27_ + 1
		end
	end
	return true
end

-- Local values: xmlFile, key, money, maxPlayTime, _, farm, i, id, usedModNames, mapModName, mission, environmentXMLFile, economyFile, _, modItem, modIndex, modName, _, modItem, modKey, required, isCrossPlatformMod, modId
function FSCareerMissionInfo:saveToXMLFile()
	if self.xmlFile ~= nil then
		delete(self.xmlFile)
	end
	local v36_ = createXMLFile("careerSavegameXML", "", "careerSavegame")
	if v36_ == 0 then
		Logging.error("Failed to create careerSavegame xml file")
	else
		self.xmlFile = v36_
		local v37_ = self.xmlKey
		setXMLInt(v36_, v37_ .. "#revision", FSCareerMissionInfo.SavegameRevision)
		setXMLBool(v36_, v37_ .. "#valid", self.isValid)
		if self.isValid then
			setXMLString(v36_, v37_ .. ".settings.savegameName", self.savegameName)
			setXMLString(v36_, v37_ .. ".settings.creationDate", self.creationDate)
			setXMLString(v36_, v37_ .. ".settings.mapId", self.mapId)
			setXMLString(v36_, v37_ .. ".settings.mapTitle", self.map.title)
			setXMLString(v36_, v37_ .. ".settings.saveDateFormatted", self.saveDateFormatted)
			setXMLString(v36_, v37_ .. ".settings.saveDate", self.saveDate)
			setXMLInt(v36_, v37_ .. ".settings.initialMoney", self.initialMoney)
			setXMLInt(v36_, v37_ .. ".settings.initialLoan", self.initialLoan)
			EconomicDifficulty.saveToXMLFile(v36_, v37_ .. ".settings.economicDifficulty", self.economicDifficulty)
			setXMLBool(v36_, v37_ .. ".settings.hasInitiallyOwnedFarmlands", self.hasInitiallyOwnedFarmlands)
			setXMLBool(v36_, v37_ .. ".settings.loadDefaultFarm", self.loadDefaultFarm)
			setXMLBool(v36_, v37_ .. ".settings.startWithGuidedTour", self.startWithGuidedTour)
			setXMLBool(v36_, v37_ .. ".settings.trafficEnabled", self.trafficEnabled)
			setXMLBool(v36_, v37_ .. ".settings.stopAndGoBraking", self.stopAndGoBraking)
			setXMLBool(v36_, v37_ .. ".settings.trailerFillLimit", self.trailerFillLimit)
			setXMLBool(v36_, v37_ .. ".settings.automaticMotorStartEnabled", self.automaticMotorStartEnabled)
			setXMLInt(v36_, v37_ .. ".settings.growthMode", self.growthMode)
			if self.fixedSeasonalVisuals ~= nil then
				setXMLInt(v36_, v37_ .. ".settings.fixedSeasonalVisuals", self.fixedSeasonalVisuals)
			end
			setXMLInt(v36_, v37_ .. ".settings.plannedDaysPerPeriod", self.plannedDaysPerPeriod)
			setXMLBool(v36_, v37_ .. ".settings.fruitDestruction", self.fruitDestruction)
			setXMLBool(v36_, v37_ .. ".settings.plowingRequiredEnabled", self.plowingRequiredEnabled)
			setXMLBool(v36_, v37_ .. ".settings.stonesEnabled", self.stonesEnabled)
			setXMLBool(v36_, v37_ .. ".settings.weedsEnabled", self.weedsEnabled)
			setXMLBool(v36_, v37_ .. ".settings.limeRequired", self.limeRequired)
			setXMLBool(v36_, v37_ .. ".settings.isSnowEnabled", self.isSnowEnabled)
			setXMLInt(v36_, v37_ .. ".settings.fuelUsage", self.fuelUsage)
			setXMLBool(v36_, v37_ .. ".settings.helperBuyFuel", self.helperBuyFuel)
			setXMLBool(v36_, v37_ .. ".settings.helperBuySeeds", self.helperBuySeeds)
			setXMLBool(v36_, v37_ .. ".settings.helperBuyFertilizer", self.helperBuyFertilizer)
			setXMLInt(v36_, v37_ .. ".settings.helperSlurrySource", self.helperSlurrySource)
			setXMLInt(v36_, v37_ .. ".settings.helperManureSource", self.helperManureSource)
			setXMLInt(v36_, v37_ .. ".settings.densityMapRevision", self.densityMapRevision)
			setXMLInt(v36_, v37_ .. ".settings.terrainTextureRevision", self.terrainTextureRevision)
			setXMLInt(v36_, v37_ .. ".settings.terrainLodTextureRevision", self.terrainLodTextureRevision)
			setXMLInt(v36_, v37_ .. ".settings.splitShapesRevision", self.splitShapesRevision)
			setXMLInt(v36_, v37_ .. ".settings.tipCollisionRevision", self.tipCollisionRevision)
			setXMLInt(v36_, v37_ .. ".settings.placementCollisionRevision", self.placementCollisionRevision)
			setXMLInt(v36_, v37_ .. ".settings.navigationCollisionRevision", self.navigationCollisionRevision)
			setXMLInt(v36_, v37_ .. ".settings.mapDensityMapRevision", self.mapDensityMapRevision)
			setXMLInt(v36_, v37_ .. ".settings.mapTerrainTextureRevision", self.mapTerrainTextureRevision)
			setXMLInt(v36_, v37_ .. ".settings.mapTerrainLodTextureRevision", self.mapTerrainLodTextureRevision)
			setXMLInt(v36_, v37_ .. ".settings.mapSplitShapesRevision", self.mapSplitShapesRevision)
			setXMLInt(v36_, v37_ .. ".settings.mapTipCollisionRevision", self.mapTipCollisionRevision)
			setXMLInt(v36_, v37_ .. ".settings.mapPlacementCollisionRevision", self.mapPlacementCollisionRevision)
			setXMLInt(v36_, v37_ .. ".settings.mapNavigationCollisionRevision", self.mapNavigationCollisionRevision)
			DisasterDestructionState.saveToXMLFile(v36_, v37_ .. ".settings.disasterDestructionState", self.disasterDestructionState)
			setXMLInt(v36_, v37_ .. ".settings.dirtInterval", self.dirtInterval)
			setXMLFloat(v36_, v37_ .. ".settings.timeScale", self.timeScale)
			setXMLFloat(v36_, v37_ .. ".settings.autoSaveInterval", g_autoSaveManager:getInterval())
			setXMLString(v36_, v37_ .. ".map.foundHelpIcons", self.foundHelpIcons)
			setXMLBool(v36_, v37_ .. ".introductionHelp#active", self.introductionHelpActive)
			setXMLString(v36_, v37_ .. ".introductionHelp.shownElements", self.introductionHelpShownElements)
			setXMLString(v36_, v37_ .. ".introductionHelp.shownHints", self.introductionHelpShownHints)
			local v38_ = 0
			local v39_ = 0
			for _, v40_ in ipairs(g_farmManager.farms) do
				if not v40_.isSpectator then
					v38_ = v38_ + v40_.money
					local v41_ = v40_.stats
					v39_ = math.max(v39_, v41_:getTotalValue("playTime"))
				end
			end
			local v42_ = setXMLString
			local v43_ = v37_ .. ".statistics.money"
			local v44_ = v38_ + 0.0001
			local v45_ = math.floor(v44_)
			v42_(v36_, v43_, (tostring(v45_)))
			setXMLFloat(v36_, v37_ .. ".statistics.playTime", v39_)
			setXMLInt(v36_, v37_ .. ".mapsSplitShapeFileIds#count", #self.mapsSplitShapeFileIds)
			for v46_, v47_ in ipairs(self.mapsSplitShapeFileIds) do
				setXMLInt(v36_, string.format("%s.mapsSplitShapeFileIds.id(%d)", v37_, v46_ - 1) .. "#id", v47_)
			end
			local v48_ = {}
			local v49_ = ClassUtil.getClassModName(self.mapId)
			if v49_ ~= nil then
				v48_[v49_] = v49_
			end
			local v50_ = g_currentMission
			if v50_ ~= nil then
				v50_.slotSystem:saveToXMLFile(v36_, v37_ .. ".slotSystem")
				v50_.navigationSystem:saveToXMLFile(self.navigationSystemXML)
				v50_.collectiblesSystem:saveToXMLFile(self.savegameDirectory .. "/collectibles.xml")
				local v51_ = createXMLFile("environmentXMLFile", self.environmentXML, "environment")
				if v51_ == 0 then
					Logging.error("Failed to create environment xml file")
				else
					v50_.environment:saveToXMLFile(v51_, "environment")
					v50_.snowSystem:saveToXMLFile(v51_, "environment.snow")
					v50_.growthSystem:saveToXMLFile(v51_, "environment.growth")
					saveXMLFile(v51_)
					delete(v51_)
				end
				v50_.placeableSystem:save(self.placeablesXML, v48_)
				v50_.vehicleSystem:save(self.vehiclesXML, v48_)
				v50_.handToolSystem:save(self.handToolsXML, v48_)
				v50_.itemSystem:save(self.itemsXML, v48_)
				v50_.aiSystem:save(self.aiSystemXML, v48_)
				v50_.onCreateObjectSystem:save(self.onCreateObjectsXML, v48_)
				local v52_ = createXMLFile("economyXML", self.economyXML, "economy")
				if v52_ == 0 then
					Logging.error("Failed to create economy xml file")
				else
					v50_.economyManager:saveToXMLFile(v52_, "economy")
					saveXMLFile(v52_)
					delete(v52_)
				end
				v50_.playerSystem:saveToXMLFile(self.playersXML)
				v50_.vehicleSaleSystem:saveToXMLFile(self.vehicleSaleXML)
				v50_.foliageSystem:saveToXMLFile(v36_)
				v50_.treeMarkerSystem:saveToXMLFile(self.treeMarkerXML)
				v50_.destructibleMapObjectSystem:saveToXMLFile(self.destructibleMapObjectsXML)
				for _, v53_ in pairs(v50_.missionDynamicInfo.mods) do
					v48_[v53_.modName] = v53_.modName
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
			local v54_ = 0
			for v55_, _ in pairs(v48_) do
				local v56_ = g_modManager:getModByName(v55_)
				if v56_ ~= nil then
					local v57_ = string.format("%s.mod(%d)", v37_, v54_)
					local v58_ = v55_ == v49_
					setXMLString(v36_, v57_ .. "#modName", v56_.modName)
					setXMLString(v36_, v57_ .. "#title", v56_.title)
					setXMLString(v36_, v57_ .. "#version", v56_.version)
					setXMLBool(v36_, v57_ .. "#required", v58_)
					setXMLString(v36_, v57_ .. "#fileHash", v56_.fileHash or "")
					if self.isCrossPlatformSavegame then
						local v59_ = false
						if v56_.isDLC or v56_.isInternalScriptMod then
							v59_ = true
						elseif not v56_.hasScripts then
							local v60_ = getModIdByFilename(v56_.modName)
							v59_ = v60_ ~= 0 and getModMetaAttributeString(v60_, "hash") == v56_.fileHash and true or v59_
						end
						if not v59_ then
							Logging.info("Found non-crossplay mod. Disabled savegame cross platform availability")
							self.isCrossPlatformSavegame = false
						end
					end
					v54_ = v54_ + 1
				end
			end
			setXMLBool(v36_, v37_ .. ".settings.isCrossPlatformSavegame", self.isCrossPlatformSavegame)
			setXMLString(v36_, v37_ .. ".settings.initialPlatformName", EnumUtil.getName(PlatformId, self.initialPlatformId))
			saveXMLFile(v36_)
		end
	end
end

-- Local values: _, id
function FSCareerMissionInfo:loadFromMission(mission)
	self.mapDensityMapRevision = mission.mapDensityMapRevision
	self.mapTerrainTextureRevision = mission.mapTerrainTextureRevision
	self.mapTerrainLodTextureRevision = mission.mapTerrainLodTextureRevision
	self.mapSplitShapesRevision = mission.mapSplitShapesRevision
	self.mapTipCollisionRevision = mission.mapTipCollisionRevision
	self.mapPlacementCollisionRevision = mission.mapPlacementCollisionRevision
	self.mapNavigationCollisionRevision = mission.mapNavigationCollisionRevision
	self.mapsSplitShapeFileIds = {}
	for _, v63_ in ipairs(mission.mapsSplitShapeFileIds) do
		local v64_ = self.mapsSplitShapeFileIds
		table.insert(v64_, v63_)
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
	return self.hasConflict and not self.isSoftConflict and "savegame_state_conflicted" or (self.uploadState == UploadState.UPLOADED and "savegame_state_uploaded" or (self.uploadState == UploadState.NOT_UPLOADED and "savegame_state_not_uploaded" or (self.uploadState == UploadState.UPLOADING and "savegame_state_uploading" or nil)))
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

-- Local values: map
function FSCareerMissionInfo:setMapId(mapId)
	self.mapId = mapId
	local v75_ = g_mapManager:getMapById(self.mapId)
	if v75_ == nil then
		return false
	end
	self.map = v75_
	self.mapTitle = v75_.title
	self.scriptFilename = v75_.scriptFilename
	self.scriptClass = v75_.className
	self.mapXMLFilename = v75_.mapXMLFilename
	self.defaultVehiclesXMLFilename = v75_.defaultVehiclesXMLFilename
	self.defaultHandToolsXMLFilename = v75_.defaultHandToolsXMLFilename
	self.defaultItemsXMLFilename = v75_.defaultItemsXMLFilename
	self.defaultPlaceablesXMLFilename = v75_.defaultPlaceablesXMLFilename
	self.customEnvironment = v75_.customEnvironment
	self.baseDirectory = v75_.baseDirectory
	return true
end

function FSCareerMissionInfo:getIsDensityMapValid(mission)
	local v78_ = self.isValid
	if v78_ then
		if self.densityMapRevision == g_densityMapRevision then
			v78_ = self.mapDensityMapRevision == mission.mapDensityMapRevision
		else
			v78_ = false
		end
	end
	return v78_
end

function FSCareerMissionInfo:getIsTerrainTextureValid(mission)
	local v81_ = self.isValid
	if v81_ then
		if self.terrainTextureRevision == g_terrainTextureRevision then
			v81_ = self.mapTerrainTextureRevision == mission.mapTerrainTextureRevision
		else
			v81_ = false
		end
	end
	return v81_
end

function FSCareerMissionInfo:getIsTerrainLodTextureValid(mission)
	local v84_ = self.isValid
	if v84_ then
		if self.terrainLodTextureRevision == g_terrainLodTextureRevision then
			v84_ = self.mapTerrainLodTextureRevision == mission.mapTerrainLodTextureRevision
		else
			v84_ = false
		end
	end
	return v84_
end

function FSCareerMissionInfo:getAreSplitShapesValid(mission)
	local v87_ = self.isValid
	if v87_ then
		if self.splitShapesRevision == g_splitShapesRevision then
			v87_ = self.mapSplitShapesRevision == mission.mapSplitShapesRevision
		else
			v87_ = false
		end
	end
	return v87_
end

function FSCareerMissionInfo:getIsTipCollisionValid(mission)
	local v90_ = self.isValid
	if v90_ then
		if self.tipCollisionRevision == g_tipCollisionRevision then
			v90_ = self.mapTipCollisionRevision == mission.mapTipCollisionRevision
		else
			v90_ = false
		end
	end
	return v90_
end

function FSCareerMissionInfo:getIsPlacementCollisionValid(mission)
	local v93_ = self.isValid
	if v93_ then
		if self.placementCollisionRevision == g_placementCollisionRevision then
			v93_ = self.mapPlacementCollisionRevision == mission.mapPlacementCollisionRevision
		else
			v93_ = false
		end
	end
	return v93_
end

function FSCareerMissionInfo:getIsNavigationCollisionValid(mission)
	local v96_ = self.isValid
	if v96_ then
		if self.navigationCollisionRevision == g_navigationCollisionRevision then
			v96_ = self.mapNavigationCollisionRevision == mission.mapNavigationCollisionRevision
		else
			v96_ = false
		end
	end
	return v96_
end

function FSCareerMissionInfo:getIsLoadedFromSavegame()
	return self.isValid
end

function FSCareerMissionInfo:getEffectiveTimeScale()
	return self.timeScale * (self.timeScaleMultiplier or 1)
end
