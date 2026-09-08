-- Local values: PrecisionFarming_mt, validateTypes, save, loadItems, unloadMapData, postInitTerrain, postSendInitialClientState
PrecisionFarming = {}
PrecisionFarming.MOD_NAME = g_currentModName
PrecisionFarming.BASE_DIRECTORY = g_currentModDirectory
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/events/AdditionalFieldBuyInfoEvent.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/events/CropSensorStateEvent.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/events/ExtendedSowingMachineRateEvent.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/events/ExtendedSprayerAmountEvent.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/events/ExtendedSprayerDefaultFruitTypeEvent.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/events/FarmlandStatisticsEvent.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/events/FarmlandStatisticsResetEvent.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/events/PurchaseSoilMapsEvent.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/events/RequestFarmlandStatisticsEvent.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/events/RequestFieldBuyInfoEvent.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/events/ResetYieldMapEvent.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/events/SoilSamplerStartEvent.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/events/SoilSamplerSendEvent.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/events/TramlineMapInitialEvent.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/events/TramlineMapSetEvent.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/densityMapUpdates/PrecisionFarmingDensityMapUpdater.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/maps/ValueMap.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/maps/SoilMap.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/maps/YieldMap.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/maps/PHMap.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/maps/NitrogenMap.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/maps/SeedRateMap.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/maps/TramlineMap.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/maps/CoverMap.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/gui/PrecisionFarmingGUI.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/gui/InGameMenuMapFrameExtension.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/gui/ShopConfigScreenExtension.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/hud/InGameMapExtension.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/hud/InputHelpDisplayExtension.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/misc/AdditionalFieldBuyInfo.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/misc/AdditionalSpecializations.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/misc/AIExtension.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/misc/CropSensorLinkageData.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/misc/ExtendedWeedControl.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/misc/FieldInfoDisplayExtension.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/misc/HarvestExtension.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/misc/HelplineExtension.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/misc/InfoDisplayBoxPrecisionFarming.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/misc/ManureSensorLinkageData.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/misc/SprayerNodeData.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/misc/Subsidies.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/misc/PrecisionFarmingDebug.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/misc/PrecisionFarmingSettings.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/misc/UsageBuffer.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/environmentalScore/EnvironmentalScore.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/specializations/configurations/VehicleConfigurationDataSprayerNodes.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/statistics/FarmlandStatistics.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/statistics/FarmlandStatistic.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/statistics/FarmlandStatisticCounter.lua")
local PrecisionFarming_mt = Class(PrecisionFarming)

-- Upvalues: PrecisionFarming_mt
-- Local values: self
function PrecisionFarming.new(customMt)
	-- upvalues: (copy) PrecisionFarming_mt
	local v3_ = customMt or PrecisionFarming_mt
	local v4_ = setmetatable({}, v3_)
	v4_.overwrittenGameFunctions = {}
	v4_.valueMaps = {}
	v4_.visualizationOverlays = {}
	v4_.precisionFarmingSettings = PrecisionFarmingSettings.new(v4_)
	v4_:registerValueMap(SoilMap.new(v4_))
	v4_:registerValueMap(PHMap.new(v4_))
	v4_:registerValueMap(NitrogenMap.new(v4_))
	v4_:registerValueMap(YieldMap.new(v4_))
	v4_:registerValueMap(SeedRateMap.new(v4_))
	v4_:registerValueMap(TramlineMap.new(v4_))
	v4_:registerValueMap(CoverMap.new(v4_))
	v4_.inGameMenuMapFrameExtension = InGameMenuMapFrameExtension.new(v4_)
	v4_.inputHelpDisplayExtension = InputHelpDisplayExtension.new(v4_)
	v4_.shopConfigScreenExtension = ShopConfigScreenExtension.new()
	v4_.inGameMapExtension = InGameMapExtension.new(v4_)
	v4_.aiExtension = AIExtension.new()
	v4_.fieldInfoDisplayExtension = FieldInfoDisplayExtension.new(v4_)
	v4_.harvestExtension = HarvestExtension.new(v4_)
	v4_.helplineExtension = HelplineExtension.new(v4_)
	v4_.farmlandStatistics = FarmlandStatistics.new(v4_)
	v4_.additionalFieldBuyInfo = AdditionalFieldBuyInfo.new(v4_)
	v4_.cropSensorLinkageData = CropSensorLinkageData.new(v4_)
	v4_.environmentalScore = EnvironmentalScore.new(v4_)
	v4_.extendedWeedControl = ExtendedWeedControl.new(v4_)
	v4_.manureSensorLinkageData = ManureSensorLinkageData.new(v4_)
	v4_.sprayerNodeData = SprayerNodeData.new(v4_)
	v4_.subsidies = Subsidies.new(v4_)
	v4_.precisionFarmingDebug = PrecisionFarmingDebug.new(v4_)
	v4_.densityMapUpdater = PrecisionFarmingDensityMapUpdater.new(v4_)
	v4_.firstTimeRun = false
	v4_.firstTimeRunDelay = 2000
	return v4_
end

-- Local values: i
function PrecisionFarming:initialize()
	for v6_ = 1, #self.valueMaps do
		self.valueMaps[v6_]:initialize(self)
		self.valueMaps[v6_]:overwriteGameFunctions(self)
	end
	self.inGameMenuMapFrameExtension:initialize(self)
	self.inGameMenuMapFrameExtension:overwriteGameFunctions(self)
	self.inputHelpDisplayExtension:overwriteGameFunctions(self)
	self.shopConfigScreenExtension:overwriteGameFunctions(self)
	self.inGameMapExtension:overwriteGameFunctions(self)
	self.aiExtension:overwriteGameFunctions(self)
	self.fieldInfoDisplayExtension:overwriteGameFunctions(self)
	self.harvestExtension:overwriteGameFunctions(self)
	self.helplineExtension:overwriteGameFunctions(self)
	self.farmlandStatistics:overwriteGameFunctions(self)
	self.additionalFieldBuyInfo:overwriteGameFunctions(self)
	self.cropSensorLinkageData:overwriteGameFunctions(self)
	self.environmentalScore:overwriteGameFunctions(self)
	self.extendedWeedControl:overwriteGameFunctions(self)
	self.manureSensorLinkageData:overwriteGameFunctions(self)
	self.sprayerNodeData:overwriteGameFunctions(self)
	self.subsidies:overwriteGameFunctions(self)
	self.precisionFarmingSettings:overwriteGameFunctions(self)
end

-- Local values: xmlFile, i, i
function PrecisionFarming:loadMap(filename)
	if g_modIsLoaded[PrecisionFarming.MOD_NAME] then
		if not Utils.getNoNil(getXMLBool(g_savegameXML, "gameSettings.precisionFarming#initialized"), false) then
			self.firstTimeRun = true
			setXMLBool(g_savegameXML, "gameSettings.precisionFarming#initialized", true)
			g_gameSettings:save()
		end
		self.mapFilename = filename
		self.configFileName = Utils.getFilename("PrecisionFarming.xml", PrecisionFarming.BASE_DIRECTORY)
		local v9_ = loadXMLFile("ConfigXML", self.configFileName)
		for v10_ = 1, #self.valueMaps do
			self.valueMaps[v10_]:loadFromXML(v9_, "precisionFarming", PrecisionFarming.BASE_DIRECTORY, self.configFileName, filename)
		end
		for v11_ = 1, #self.valueMaps do
			self.valueMaps[v11_]:postLoad(v9_, "precisionFarming", PrecisionFarming.BASE_DIRECTORY, self.configFileName, filename)
		end
		self.aiExtension:loadFromXML(v9_, "precisionFarming.aiExtension", PrecisionFarming.BASE_DIRECTORY, self.configFileName, filename)
		self.fieldInfoDisplayExtension:loadFromXML(v9_, "precisionFarming.fieldInfoDisplayExtension", PrecisionFarming.BASE_DIRECTORY, self.configFileName, filename)
		self.harvestExtension:loadFromXML(v9_, "precisionFarming.harvestExtension", PrecisionFarming.BASE_DIRECTORY, self.configFileName, filename)
		self.helplineExtension:loadFromXML(v9_, "precisionFarming.helplineExtension", PrecisionFarming.BASE_DIRECTORY, self.configFileName, filename)
		self.farmlandStatistics:loadFromXML(v9_, "precisionFarming.farmlandStatistics", PrecisionFarming.BASE_DIRECTORY, self.configFileName, filename)
		self.additionalFieldBuyInfo:loadFromXML(v9_, "precisionFarming.additionalFieldBuyInfo", PrecisionFarming.BASE_DIRECTORY, self.configFileName, filename)
		self.cropSensorLinkageData:loadFromXML(v9_, "precisionFarming.cropSensorLinkageData", PrecisionFarming.BASE_DIRECTORY, self.configFileName, filename)
		self.manureSensorLinkageData:loadFromXML(v9_, "precisionFarming.manureSensorLinkageData", PrecisionFarming.BASE_DIRECTORY, self.configFileName, filename)
		self.sprayerNodeData:loadFromXML(v9_, "precisionFarming.sprayerNodeData", PrecisionFarming.BASE_DIRECTORY, self.configFileName, filename)
		self.subsidies:loadFromXML(v9_, "precisionFarming.subsidies", PrecisionFarming.BASE_DIRECTORY, self.configFileName, filename)
		self.environmentalScore:loadFromXML(v9_, "precisionFarming.environmentalScore", PrecisionFarming.BASE_DIRECTORY, self.configFileName, filename)
		self.extendedWeedControl:loadFromXML(v9_, "precisionFarming.extendedWeedControl", PrecisionFarming.BASE_DIRECTORY, self.configFileName, filename)
		delete(v9_)
	end
end

function PrecisionFarming:unloadMapData()
	self.inGameMenuMapFrameExtension:unloadMapData()
	self.shopConfigScreenExtension:unloadMapData()
	self.inGameMapExtension:unloadMapData()
	self.extendedWeedControl:unloadMapData()
end

-- Local values: i
function PrecisionFarming:initTerrain(mission, terrainId, filename)
	for v17_ = 1, #self.valueMaps do
		self.valueMaps[v17_]:initTerrain(mission, terrainId, filename)
	end
end

-- Local values: i
function PrecisionFarming:sendInitialClientState(connection, user, farm)
	for v22_ = 1, #self.valueMaps do
		if self.valueMaps[v22_].sendInitialClientState ~= nil then
			self.valueMaps[v22_]:sendInitialClientState(connection, user, farm)
		end
	end
	self.precisionFarmingSettings:sendInitialClientState(connection, user, farm)
end

-- Local values: i, i, i, reference
function PrecisionFarming:deleteMap()
	if g_modIsLoaded[PrecisionFarming.MOD_NAME] then
		for v24_ = #self.visualizationOverlays, 1, -1 do
			resetDensityMapVisualizationOverlay(self.visualizationOverlays[v24_])
			self.visualizationOverlays[v24_] = nil
		end
		for v25_ = 1, #self.valueMaps do
			self.valueMaps[v25_]:delete()
		end
		self.inGameMenuMapFrameExtension:delete()
		self.shopConfigScreenExtension:delete()
		self.inGameMapExtension:delete()
		self.aiExtension:delete()
		self.fieldInfoDisplayExtension:delete()
		self.harvestExtension:delete()
		self.helplineExtension:delete()
		self.farmlandStatistics:delete()
		self.additionalFieldBuyInfo:delete()
		self.cropSensorLinkageData:delete()
		self.manureSensorLinkageData:delete()
		self.sprayerNodeData:delete()
		self.subsidies:delete()
		self.environmentalScore:delete()
		self.precisionFarmingDebug:delete()
		for v26_ = #self.overwrittenGameFunctions, 1, -1 do
			local v27_ = self.overwrittenGameFunctions[v26_]
			v27_.object[v27_.funcName] = v27_.oldFunc
			self.overwrittenGameFunctions[v26_] = nil
		end
	end
end

-- Local values: i
function PrecisionFarming:loadFromItemsXML(xmlFile, key)
	for v31_ = #self.valueMaps, 1, -1 do
		self.valueMaps[v31_]:loadFromItemsXML(xmlFile, key)
	end
	self.farmlandStatistics:loadFromItemsXML(xmlFile, key)
	self.additionalFieldBuyInfo:loadFromItemsXML(xmlFile, key)
	self.environmentalScore:loadFromItemsXML(xmlFile, key)
	self.densityMapUpdater:loadFromItemsXML(xmlFile, key)
end

-- Local values: i
function PrecisionFarming:saveToXMLFile(xmlFile, key, usedModNames)
	for v36_ = 1, #self.valueMaps do
		self.valueMaps[v36_]:saveToXMLFile(xmlFile, key, usedModNames)
	end
	self.farmlandStatistics:saveToXMLFile(xmlFile, key, usedModNames)
	self.additionalFieldBuyInfo:saveToXMLFile(xmlFile, key, usedModNames)
	self.environmentalScore:saveToXMLFile(xmlFile, key, usedModNames)
	self.densityMapUpdater:saveToXMLFile(xmlFile, key, usedModNames)
end
function PrecisionFarming.addSetting(p37_, ...)
	p37_.precisionFarmingSettings:addSetting(...)
end

function PrecisionFarming:registerVisualizationOverlay(overlay)
	local v40_ = self.visualizationOverlays
	table.insert(v40_, overlay)
end

-- Local values: i
function PrecisionFarming:update(dt)
	if g_modIsLoaded[PrecisionFarming.MOD_NAME] then
		for v43_ = 1, #self.valueMaps do
			self.valueMaps[v43_]:update(dt)
		end
		self.inGameMenuMapFrameExtension:update(dt)
		self.shopConfigScreenExtension:update(dt)
		self.inGameMapExtension:update(dt)
		self.additionalFieldBuyInfo:update(dt)
		self.harvestExtension:update(dt)
		self.environmentalScore:update(dt)
		self.densityMapUpdater:update(dt)
		if self.firstTimeRun then
			local v44_ = self.firstTimeRunDelay - dt
			self.firstTimeRunDelay = math.max(v44_, 0)
			if self.firstTimeRunDelay == 0 and self.helplineExtension:getAllowFirstTimeEvent() then
				self.helplineExtension:onFirstTimeRun()
				self.firstTimeRun = false
			end
		end
	end
end

function PrecisionFarming:draw()
	if g_modIsLoaded[PrecisionFarming.MOD_NAME] then
		self.harvestExtension:draw()
	end
end

function PrecisionFarming:registerValueMap(object)
	local v48_ = self.valueMaps
	table.insert(v48_, object)
	self[object.name] = object
	object.valueMapIndex = #self.valueMaps
end

function PrecisionFarming:getValueMaps()
	return self.valueMaps
end

function PrecisionFarming:getValueMap(index)
	return self.valueMaps[index]
end

function PrecisionFarming:updatePrecisionFarmingOverlays()
	self.inGameMapExtension:updatePrecisionFarmingOverlays()
	self.inGameMenuMapFrameExtension:updatePrecisionFarmingOverlays()
end

function PrecisionFarming:onValueMapSelectionChanged(valueMap)
	self.yieldMap:onValueMapSelectionChanged(valueMap)
end

function PrecisionFarming:onFarmlandSelectionChanged(farmlandId, fieldNumber, fieldArea)
	self.yieldMap:onFarmlandSelectionChanged(farmlandId, fieldNumber, fieldArea)
end

function PrecisionFarming:setMapFrame(mapFrame)
	if self.additionalFieldBuyInfo ~= nil then
		self.additionalFieldBuyInfo:setMapFrame(mapFrame)
	end
	if self.soilMap ~= nil then
		self.soilMap:setMapFrame(mapFrame)
	end
	if self.farmlandStatistics ~= nil then
		self.farmlandStatistics:setMapFrame(mapFrame)
	end
	if self.yieldMap ~= nil then
		self.yieldMap:setMapFrame(mapFrame)
	end
	if self.tramlineMap ~= nil then
		self.tramlineMap:setMapFrame(mapFrame)
	end
	if self.environmentalScore ~= nil then
		self.environmentalScore:setMapFrame(mapFrame)
	end
end

function PrecisionFarming:onMapFrameOpen(mapFrame)
	if self.environmentalScore ~= nil then
		self.environmentalScore:onMapFrameOpen(mapFrame)
	end
end

-- Local values: i
function PrecisionFarming:collectFieldInfos(fieldInfoDisplayExtension)
	for v65_ = 1, #self.valueMaps do
		self.valueMaps[v65_]:collectFieldInfos(fieldInfoDisplayExtension)
	end
end

-- Local values: i
function PrecisionFarming:collectFarmlandHotspotActions(farmlandHotspotActions)
	for v68_ = 1, #self.valueMaps do
		self.valueMaps[v68_]:collectFarmlandHotspotActions(farmlandHotspotActions)
	end
	self.farmlandStatistics:collectFarmlandHotspotActions(farmlandHotspotActions)
end

function PrecisionFarming:getIsMaizePlusActive()
	return g_modIsLoaded.FS25_MaizePlus
end

function PrecisionFarming:getCropSensorLinkageData(configFileName)
	return self.cropSensorLinkageData:getCropSensorLinkageData(configFileName)
end

function PrecisionFarming:getClonedCropSensorNode(typeName)
	return self.cropSensorLinkageData:getClonedCropSensorNode(typeName)
end

function PrecisionFarming:getManureSensorLinkageData(configFileName)
	return self.manureSensorLinkageData:getManureSensorLinkageData(configFileName)
end

function PrecisionFarming:getClonedManureSensorNode(typeName)
	return self.manureSensorLinkageData:getClonedManureSensorNode(typeName)
end

function PrecisionFarming:getSprayerNodeData(configFileName, configurations)
	return self.sprayerNodeData:getSprayerNodeData(configFileName, configurations)
end

function PrecisionFarming:getClonedSprayerEffectNode()
	return self.sprayerNodeData:getClonedSprayerEffectNode()
end

function PrecisionFarming:getClonedSprayerWeedSensorNode(sensorTypeId)
	return self.sprayerNodeData:getClonedSprayerWeedSensorNode(sensorTypeId)
end

function PrecisionFarming:getSprayerConfigPrices()
	return self.sprayerNodeData:getConfigPrices()
end

function PrecisionFarming:getSprayerClonedSectionSamples(name, linkNode, modifierTargetObject)
	return self.sprayerNodeData:getClonedSectionSamples(name, linkNode, modifierTargetObject)
end

-- Local values: fieldNumber, fieldArea, farmland, fields, _, field
function PrecisionFarming:getFarmlandFieldInfo(farmlandId)
	local v89_ = 0
	local v90_ = g_farmlandManager.farmlands[farmlandId]
	local v91_ = v90_ == nil and 0 or (v90_.totalFieldArea or 0)
	local v92_ = g_fieldManager:getFields()
	if v92_ ~= nil then
		for _, v93_ in pairs(v92_) do
			if v93_.farmland ~= nil and v93_.farmland.id == farmlandId then
				return v93_:getId(), v91_
			end
		end
	end
	return v89_, v91_
end

-- Local values: oldFunc, reference
function PrecisionFarming:overwriteGameFunction(object, funcName, newFunc)
	if object == nil then
		Logging.error("Failed to overwrite \'%s\'", funcName)
		printCallstack()
	else
		local v_u_98_ = object[funcName]
		if v_u_98_ ~= nil then
			object[funcName] = function(...)
				-- upvalues: (copy) newFunc, (copy) v_u_98_
				return newFunc(v_u_98_, ...)
			end
		end
		local v99_ = self.overwrittenGameFunctions
		table.insert(v99_, {
			["object"] = object,
			["funcName"] = funcName,
			["oldFunc"] = v_u_98_
		})
	end
end
g_precisionFarming = PrecisionFarming.new()
addModEventListener(g_precisionFarming)
TypeManager.validateTypes = Utils.prependedFunction(TypeManager.validateTypes, function(p100_)
	if p100_.typeName == "vehicle" and (g_modIsLoaded[PrecisionFarming.MOD_NAME] and g_iconGenerator == nil) then
		g_precisionFarming:initialize()
	end
end)
ItemSystem.save = Utils.prependedFunction(ItemSystem.save, function(_, _, p101_)
	if g_modIsLoaded[PrecisionFarming.MOD_NAME] then
		local v102_ = g_currentMission.missionInfo.savegameDirectory .. "/precisionFarming.xml"
		local v103_ = XMLFile.create("precisionFarmingXML", v102_, "precisionFarming")
		if v103_ ~= nil then
			g_precisionFarming:saveToXMLFile(v103_, "precisionFarming", p101_)
			v103_:save()
			v103_:delete()
		end
	end
end)
ItemSystem.loadItems = Utils.prependedFunction(ItemSystem.loadItems, function(_, _, ...)
	if g_modIsLoaded[PrecisionFarming.MOD_NAME] and g_currentMission.missionInfo.savegameDirectory ~= nil then
		local v104_ = g_currentMission.missionInfo.savegameDirectory .. "/precisionFarming.xml"
		if fileExists(v104_) then
			local v105_ = XMLFile.load("precisionFarmingXML", v104_)
			if v105_ ~= nil then
				g_precisionFarming:loadFromItemsXML(v105_, "precisionFarming")
				v105_:delete()
			end
		end
	end
end)
Gui.unloadMapData = Utils.prependedFunction(Gui.unloadMapData, function(_, _)
	if g_modIsLoaded[PrecisionFarming.MOD_NAME] then
		g_precisionFarming:unloadMapData()
	end
end)
FSBaseMission.initTerrain = Utils.appendedFunction(FSBaseMission.initTerrain, function(p106_, p107_, p108_)
	if g_modIsLoaded[PrecisionFarming.MOD_NAME] then
		g_precisionFarming:initTerrain(p106_, p107_, p108_)
	end
end)
FSBaseMission.sendInitialClientState = Utils.appendedFunction(FSBaseMission.sendInitialClientState, function(_, p109_, p110_, p111_)
	if g_modIsLoaded[PrecisionFarming.MOD_NAME] then
		g_precisionFarming:sendInitialClientState(p109_, p110_, p111_)
	end
end)
