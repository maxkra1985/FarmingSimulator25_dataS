-- Local values: SoilMap_mt
SoilMap = {}
SoilMap.MOD_NAME = g_currentModName
SoilMap.MOD_DIR = g_currentModDirectory
SoilMap.GUI_ELEMENTS = g_currentModDirectory .. "gui/ui_elements.png"
SoilMap.SAMPLING_RADIUS = 35
SoilMap.SAMPLING_PROVIDER_MULTIPLIER = 1.75
source(g_currentModDirectory .. "scripts/gui/SoilSampleYesNoDialog.lua")
source(g_currentModDirectory .. "scripts/densityMapUpdates/SoilMapResetDensityMapTask.lua")
local SoilMap_mt = Class(SoilMap, ValueMap)

-- Upvalues: SoilMap_mt
-- Local values: self, width, height
function SoilMap.new(pfModule, customMt)
	-- upvalues: (copy) SoilMap_mt
	local v4_ = ValueMap.new(pfModule, customMt or SoilMap_mt)
	v4_.filename = "precisionFarming_soilMap.grle"
	v4_.name = "soilMap"
	v4_.id = "SOIL_MAP"
	v4_.label = "ui_mapOverviewSoilType"
	v4_.pendingSoilSamplesPerFarm = {}
	v4_.moneyChangeType = MoneyType.register("other", "info_samplesAnalysed", SoilMap.MOD_NAME)
	v4_.densityMapModifiersUncover = {}
	v4_.densityMapModifiersSellFarmland = nil
	v4_.mapFrame = nil
	local v5_, v6_ = getNormalizedScreenValues(85, 85)
	v4_.samplingCircleElement = g_overlayManager:createOverlay("precisionFarming.circle", 0, 0, v5_, v6_)
	v4_.samplingCircleElement:setColor(0.1, 0.5, 0.1, 0.5)
	v4_.minimapSamplingState = false
	v4_.minimapUpdateTimer = 0
	v4_.minimapLabelName = g_i18n:getText("ui_mapOverviewSoilType", SoilMap.MOD_NAME)
	return v4_
end

function SoilMap:initialize()
	SoilMap:superClass().initialize(self)
	self.pendingSoilSamplesPerFarm = {}
	self.densityMapModifiersUncover = {}
	self.densityMapModifiersFarmlandStateChange = nil
	self.loadFilename = nil
	self.coverMap = self.pfModule.coverMap
	SoilSampleYesNoDialog.register()
end

-- Local values: missionInfo, savegameFilename, mapXMLFilename, customSoilMap, i, mapKey, filename, isDefault, mapIdentifier, size, _, i, typeKey, soilType
function SoilMap:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
	local v14_ = key .. ".soilMap"
	local v15_ = g_currentMission.missionInfo
	local v16_
	if v15_.savegameDirectory == nil then
		v16_ = nil
	else
		v16_ = v15_.savegameDirectory .. "/" .. self.filename
	end
	if v16_ == nil or not fileExists(v16_) then
		local v17_ = Utils.getFilename(v15_.mapXMLFilename, g_currentMission.baseDirectory)
		self.mapXMLFile = loadXMLFile("MapXML", v17_)
		local v18_
		if self.mapXMLFile == nil then
			v18_ = 0
		else
			local v19_ = getXMLString(self.mapXMLFile, "map.precisionFarming.soilMap#filename")
			if v19_ ~= nil then
				local v20_ = Utils.getFilename(v19_, g_currentMission.baseDirectory)
				if fileExists(v20_) then
					self.loadFilename = v20_
				end
			end
			delete(self.mapXMLFile)
			v18_ = 0
		end
		while true do
			local v21_ = string.format("%s.predefinedMaps.predefinedMap(%d)", v14_, v18_)
			if not hasXMLProperty(xmlFile, v21_) then
				break
			end
			local v22_ = getXMLString(xmlFile, v21_ .. "#filename")
			if v22_ == nil then
				Logging.xmlWarning(configFileName, "Unknown filename in \'%s\'", v14_)
			else
				local v23_ = Utils.getFilename(v22_, baseDirectory)
				if fileExists(v23_) then
					local v24_ = getXMLBool(xmlFile, v21_ .. "#isDefault")
					if v24_ ~= nil and (v24_ and self.loadFilename == nil) then
						self.loadFilename = v23_
					end
					local v25_ = getXMLString(xmlFile, v21_ .. "#mapIdentifier")
					if v25_ ~= nil and (mapFilename:find(v25_) ~= nil and self.loadFilename == nil) then
						self.loadFilename = v23_
					end
				else
					Logging.xmlWarning(configFileName, "Soil map \'%s\' could not be found", v14_)
				end
			end
			v18_ = v18_ + 1
		end
	else
		self.loadFilename = v16_
	end
	self.numChannels = getXMLInt(xmlFile, v14_ .. ".bitVectorMap#numChannels") or 3
	self.bitVectorMap = createBitVectorMap("SoilMap")
	if self.loadFilename ~= nil then
		if loadBitVectorMapFromFile(self.bitVectorMap, self.loadFilename, self.numChannels) then
			local v26_, _ = getBitVectorMapSize(self.bitVectorMap)
			if v26_ == 1024 then
				Logging.info("Load soil map \'%s\'", self.loadFilename)
			else
				self.loadFilename = nil
				Logging.xmlWarning(configFileName, "Found soil map with wrong size \'%s\'. Soil map needs to be 1024x1024!", self.loadFilename)
			end
		else
			Logging.xmlWarning(configFileName, "Error while loading soil map \'%s\'", self.loadFilename)
			self.loadFilename = nil
		end
	end
	if self.loadFilename == nil then
		loadBitVectorMapNew(self.bitVectorMap, 1024, 1024, self.numChannels, false)
	end
	self:addBitVectorMapToSync(self.bitVectorMap)
	self:addBitVectorMapToSave(self.bitVectorMap, self.filename)
	self:addBitVectorMapToDelete(self.bitVectorMap)
	local v27_, v28_ = getBitVectorMapSize(self.bitVectorMap)
	self.sizeX = v27_
	self.sizeY = v28_
	self.typeFirstChannel = getXMLInt(xmlFile, v14_ .. ".bitVectorMap#typeFirstChannel") or 0
	self.typeNumChannels = getXMLInt(xmlFile, v14_ .. ".bitVectorMap#typeNumChannels") or 2
	self.coverChannel = getXMLInt(xmlFile, v14_ .. ".bitVectorMap#coverChannel") or 2
	self.sampledColor = string.getVector(getXMLString(xmlFile, v14_ .. ".sampling#sampledColor"), 3) or { 0, 0, 0 }
	self.sampledColorBlind = string.getVector(getXMLString(xmlFile, v14_ .. ".sampling#sampledColorBlind"), 3) or { 0, 0, 0 }
	self.sampledText = g_i18n:convertText(getXMLString(xmlFile, v14_ .. ".sampling#name"), SoilMap.MOD_NAME)
	self.pricePerSample = string.getVector(getXMLString(xmlFile, v14_ .. ".sampling#pricePerSample"), 3) or { 50, 100, 150 }
	self.analyseTimePerSample = (getXMLFloat(xmlFile, v14_ .. ".sampling#analyseTimeSecPerSample") or 5) * 1000
	self.texts = {}
	self.texts.laboratoryIdle = g_i18n:convertText(getXMLString(xmlFile, v14_ .. ".sampling.texts#idleText") or "$l10n_ui_laboratory_idle", SoilMap.MOD_NAME)
	self.texts.laboratoryAnalyse = g_i18n:convertText(getXMLString(xmlFile, v14_ .. ".sampling.texts#analyseText") or "$l10n_ui_laboratory_analyse", SoilMap.MOD_NAME)
	self.texts.fieldInfoSoil = g_i18n:getText("fieldInfo_soil", SoilMap.MOD_NAME)
	self.texts.fieldInfoNoData = g_i18n:getText("fieldInfo_noSoilDataFound", SoilMap.MOD_NAME)
	self.texts.purchaseSoilMaps = g_i18n:getText("ui_purchaseSoilMaps", SoilMap.MOD_NAME)
	self.soilTypes = {}
	local v29_ = 0
	while true do
		local v30_ = string.format("%s.soilTypes.soilType(%d)", v14_, v29_)
		if not hasXMLProperty(xmlFile, v30_) then
			break
		end
		local v31_ = {
			["name"] = g_i18n:convertText(getXMLString(xmlFile, v30_ .. "#name"), SoilMap.MOD_NAME),
			["yieldPotential"] = getXMLFloat(xmlFile, v30_ .. "#yieldPotential") or 1,
			["color"] = string.getVector(getXMLString(xmlFile, v30_ .. "#color"), 3) or { 0, 0, 0 },
			["colorBlind"] = string.getVector(getXMLString(xmlFile, v30_ .. "#colorBlind"), 3) or { 0, 0, 0 }
		}
		local v32_ = self.soilTypes
		table.insert(v32_, v31_)
		v29_ = v29_ + 1
	end
	self.pHMap = self.pfModule.pHMap
	self.nitrogenMap = self.pfModule.nitrogenMap
	g_messageCenter:subscribe(MessageType.FARMLAND_OWNER_CHANGED, self.onFarmlandStateChanged, self)
	return true
end

-- Local values: multiModifier, updateTask
function SoilMap:initTerrain(mission, terrainId, filename)
	SoilMap:superClass().initTerrain(self, mission, terrainId, filename)
	local v37_
	if self.pHMap == nil or not self.pHMap.newBitVectorMap then
		v37_ = nil
	else
		v37_ = DensityMapMultiModifier.new()
		self.pHMap:addSetInitialState(v37_, self.bitVectorMap, self.typeFirstChannel, self.typeNumChannels)
	end
	if self.nitrogenMap ~= nil and self.nitrogenMap.newBitVectorMap then
		if v37_ == nil then
			v37_ = DensityMapMultiModifier.new()
		end
		self.nitrogenMap:addSetInitialState(v37_, self.bitVectorMap, self.typeFirstChannel, self.typeNumChannels)
	end
	if v37_ ~= nil then
		local v38_ = SoilMapResetDensityMapTask.new()
		v38_.multiModifier = v37_
		v38_:enqueue(true)
		Logging.devInfo("Initialized nitrogen and pH Map.")
	end
end

function SoilMap:delete()
	g_messageCenter:unsubscribeAll(self)
	self.samplingCircleElement:delete()
	SoilMap:superClass().delete(self)
end

function SoilMap:loadFromItemsXML(xmlFile, key)
	xmlFile:iterate((key .. ".soilMap") .. ".pendingSoilSamples", function(_, p43_)
		-- upvalues: (copy) xmlFile, (copy) self
		local v44_ = xmlFile:getInt(p43_ .. "#farmId")
		local v45_ = xmlFile:getFloat(p43_ .. "#timer", self.analyseTimePerSample)
		local v46_ = xmlFile:getInt(p43_ .. "#toAnalyse")
		local v47_ = xmlFile:getInt(p43_ .. "#totalAnalysed")
		if v44_ ~= nil and (v46_ ~= nil and v47_ ~= nil) then
			self.pendingSoilSamplesPerFarm[v44_] = {
				["toAnalyse"] = v46_,
				["totalAnalysed"] = v47_,
				["timer"] = v45_
			}
		end
	end)
end

-- Local values: i, farmId, data, baseKey
function SoilMap:saveToXMLFile(xmlFile, key, usedModNames)
	local v51_ = key .. ".soilMap"
	local v52_ = 0
	for v53_, v54_ in pairs(self.pendingSoilSamplesPerFarm) do
		local v55_ = string.format("%s.pendingSoilSamples(%d)", v51_, v52_)
		xmlFile:setInt(v55_ .. "#farmId", v53_)
		xmlFile:setFloat(v55_ .. "#timer", v54_.timer)
		xmlFile:setInt(v55_ .. "#toAnalyse", v54_.toAnalyse)
		xmlFile:setInt(v55_ .. "#totalAnalysed", v54_.totalAnalysed)
		v52_ = v52_ + 1
	end
end

-- Local values: farmId, data, price
function SoilMap:update(dt)
	for v58_, v59_ in pairs(self.pendingSoilSamplesPerFarm) do
		v59_.timer = v59_.timer - dt * g_currentMission:getEffectiveTimeScale()
		if v59_.timer <= 0 then
			v59_.toAnalyse = v59_.toAnalyse - 1
			if v59_.toAnalyse <= 0 then
				self.coverMap:uncoverAnalysedArea(v58_)
				local v60_ = self:getPricePerSoilSample() * v59_.totalAnalysed
				g_currentMission:addMoney(-v60_, v58_, self.moneyChangeType, true, true)
				self.pendingSoilSamplesPerFarm[v58_] = nil
			else
				v59_.timer = self.analyseTimePerSample
			end
			self:updateLaboratoryText()
		end
	end
	if self.minimapSamplingState then
		self.samplingCircleElement:setColor(0.5, 0.5, 0.1, IngameMap.alpha)
	end
	if self.minimapUpdateTimer > 0 then
		self.minimapUpdateTimer = self.minimapUpdateTimer - dt
		if self.minimapUpdateTimer <= 0 then
			self:setMinimapRequiresUpdate(true)
		end
	end
end

function SoilMap:setMapFrame(mapFrame)
	self.mapFrame = mapFrame
	self:updateLaboratoryText()
end

-- Local values: farmId
function SoilMap:updateLaboratoryText()
	if self.mapFrame ~= nil then
		local v64_ = g_currentMission:getFarmId()
		if self.pendingSoilSamplesPerFarm[v64_] ~= nil then
			self.mapFrame.laboratoryInfoText:setText(string.format(self.texts.laboratoryAnalyse, self.pendingSoilSamplesPerFarm[v64_].totalAnalysed), true)
			return
		end
		self.mapFrame.laboratoryInfoText:setText(self.texts.laboratoryIdle, true)
	end
end

-- Local values: _, vehicle
function SoilMap:sendSoilSamplesByFarm(farmId)
	for _, v66_ in pairs(g_currentMission.vehicleSystem.vehicles) do
		if SpecializationUtil.hasSpecialization(SoilSampler, v66_.specializations) and v66_:getOwnerFarmId() == farmId then
			v66_:sendTakenSoilSamples()
		end
	end
end

function SoilMap:analyseSoilSamples(farmId, numSamples)
	if self.pendingSoilSamplesPerFarm[farmId] == nil then
		self.pendingSoilSamplesPerFarm[farmId] = {
			["toAnalyse"] = numSamples,
			["totalAnalysed"] = numSamples,
			["timer"] = self.analyseTimePerSample
		}
	else
		self.pendingSoilSamplesPerFarm[farmId].toAnalyse = self.pendingSoilSamplesPerFarm[farmId].toAnalyse + numSamples
		self.pendingSoilSamplesPerFarm[farmId].totalAnalysed = self.pendingSoilSamplesPerFarm[farmId].totalAnalysed + numSamples
		self.pendingSoilSamplesPerFarm[farmId].timer = self.analyseTimePerSample
	end
	self:updateLaboratoryText()
end

function SoilMap:onAnalyseArea(densityMapShape, state, farmId)
	self.minimapUpdateTimer = 250
end

-- Local values: modifier
function SoilMap:addUncoverToMultiModifier(multiModifier, filter1, filter2, coverFilter1, coverFilter2)
	local v77_ = self.densityMapModifiersUncover.modifier
	if v77_ == nil then
		self.densityMapModifiersUncover.modifier = DensityMapModifier.new(self.bitVectorMap, self.coverChannel, 1, g_terrainNode)
		v77_ = self.densityMapModifiersUncover.modifier
	end
	if coverFilter1 ~= nil then
		multiModifier:addExecuteSet(0, v77_, coverFilter1, coverFilter2)
	end
	multiModifier:addExecuteSet(1, v77_, filter1, filter2)
end

-- Local values: updateTask
function SoilMap:onFarmlandStateChanged(farmlandId, farmId, loadFromSavegame)
	if not loadFromSavegame and farmId == 0 then
		local v81_ = SoilMapResetDensityMapTask.new()
		v81_:setData(farmlandId)
		v81_:enqueue()
	end
end

-- Local values: functionData, multiModifier, modifier, modifierCover, farmlandMask
function SoilMap:getFarmlandResetMultiModifier(farmlandId)
	local v84_ = farmlandId or -1
	local v85_ = self.densityMapModifiersFarmlandStateChange
	if v85_ == nil then
		v85_ = {
			["modifier"] = DensityMapModifier.new(self.bitVectorMap, self.coverChannel, 1, g_terrainNode),
			["modifierCover"] = DensityMapModifier.new(self.coverMap.bitVectorMap, self.coverMap.firstChannel, self.coverMap.numChannels, g_terrainNode),
			["farmlandMask"] = DensityMapFilter.new(g_farmlandManager.localMap, 0, g_farmlandManager.numberOfBits),
			["multiModifiers"] = {}
		}
		self.densityMapModifiersFarmlandStateChange = v85_
	end
	local v86_ = v85_.multiModifiers[v84_]
	if v86_ == nil then
		local v87_ = v85_.modifier
		local v88_ = v85_.modifierCover
		local v89_ = v85_.farmlandMask
		v86_ = DensityMapMultiModifier.new()
		if v84_ >= 0 then
			v89_:setValueCompareParams(DensityValueCompareType.EQUAL, v84_)
		else
			v89_ = nil
		end
		v86_:addExecuteSet(0, v87_, v89_)
		v86_:addExecuteSet(0, v88_, v89_)
		if self.pfModule.pHMap ~= nil then
			self.pfModule.pHMap:addSetInitialState(v86_, self.bitVectorMap, self.typeFirstChannel, self.typeNumChannels, v89_)
		end
		if self.pfModule.nitrogenMap ~= nil then
			self.pfModule.nitrogenMap:addSetInitialState(v86_, self.bitVectorMap, self.typeFirstChannel, self.typeNumChannels, v89_)
		end
		v85_.multiModifiers[v84_] = v86_
	end
	return v86_
end

function SoilMap:getTypeIndexAtWorldPos(x, z)
	local v93_ = MathUtil.round((x + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeX + 0.5) - 1
	local v94_ = MathUtil.round((z + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeY + 0.5) - 1
	return not self.coverMap:getIsUncoveredAtPos(v93_, v94_) and 0 or getBitVectorMapPoint(self.bitVectorMap, v93_, v94_, self.typeFirstChannel, self.typeNumChannels) + 1
end

-- Local values: sampledColor, coverMask, soilMapId, i, soilType, color
function SoilMap:buildOverlay(overlay, valueFilter, isColorBlindMode)
	resetDensityMapVisualizationOverlay(overlay)
	setOverlayColor(overlay, 1, 1, 1, 1)
	if self.coverMap ~= nil then
		local v99_ = self.sampledColor
		if isColorBlindMode then
			v99_ = self.sampledColorBlind
		end
		setDensityMapVisualizationOverlayStateColor(overlay, self.coverMap.bitVectorMap, 0, 0, self.coverMap.firstChannel, self.coverMap.numChannels, self.coverMap.sampledValue, v99_[1], v99_[2], v99_[3])
	end
	local v100_ = self.coverChannel
	local v101_ = bit32.lshift(1, v100_)
	local v102_ = self.bitVectorMap
	for v103_ = 1, #self.soilTypes do
		if valueFilter[v103_] then
			local v104_ = self.soilTypes[v103_]
			local v105_ = v104_.color
			if isColorBlindMode then
				v105_ = v104_.colorBlind
			end
			setDensityMapVisualizationOverlayStateColor(overlay, v102_, v102_, v101_, self.typeFirstChannel, self.typeNumChannels, v103_ - 1, v105_[1], v105_[2], v105_[3])
		end
	end
end

-- Local values: i, soilType, soilTypeToDisplay, soilTypeToDisplay
function SoilMap:getDisplayValues()
	if self.valuesToDisplay == nil then
		self.valuesToDisplay = {}
		for v107_ = 1, #self.soilTypes do
			local v108_ = self.soilTypes[v107_]
			local v109_ = {
				["colors"] = {}
			}
			v109_.colors[true] = {
				{ v108_.colorBlind[1], v108_.colorBlind[2], v108_.colorBlind[3] }
			}
			v109_.colors[false] = {
				{ v108_.color[1], v108_.color[2], v108_.color[3] }
			}
			v109_.description = v108_.name
			local v110_ = self.valuesToDisplay
			table.insert(v110_, v109_)
		end
		local v111_ = {
			["colors"] = {}
		}
		v111_.colors[true] = {
			{ self.sampledColorBlind[1], self.sampledColorBlind[2], self.sampledColorBlind[3] }
		}
		v111_.colors[false] = {
			{ self.sampledColor[1], self.sampledColor[2], self.sampledColor[3] }
		}
		v111_.description = self.sampledText
		local v112_ = self.valuesToDisplay
		table.insert(v112_, v111_)
	end
	return self.valuesToDisplay
end

function SoilMap:getSoilTypeByIndex(soilTypeIndex)
	return self.soilTypes[soilTypeIndex]
end

function SoilMap:getYieldPotentialBySoilTypeIndex(soilTypeIndex)
	return self.soilTypes[soilTypeIndex] == nil and 1 or self.soilTypes[soilTypeIndex].yieldPotential
end

-- Local values: numSoilTypes, i
function SoilMap:getValueFilter()
	if self.valueFilter == nil or self.valueFilterEnabled == nil then
		self.valueFilter = {}
		self.valueFilterEnabled = {}
		local v118_ = #self.soilTypes
		for v119_ = 1, v118_ + 1 do
			local v120_ = self.valueFilter
			table.insert(v120_, true)
			local v121_ = self.valueFilterEnabled
			local v122_ = v119_ <= v118_
			table.insert(v121_, v122_)
		end
	end
	return self.valueFilter, self.valueFilterEnabled
end

-- Local values: i
function SoilMap:getMinimapValueFilter()
	if self.minimapValueFilter == nil then
		self.minimapValueFilter = {}
		for _ = 1, #self.soilTypes + 1 do
			local v124_ = self.minimapValueFilter
			table.insert(v124_, true)
		end
	end
	return self.minimapValueFilter, self.minimapValueFilter
end

function SoilMap:getMinimapAdditionalElement()
	return self.samplingCircleElement
end

function SoilMap:getMinimapZoomFactor()
	return 3
end

function SoilMap:getMinimapUpdateTimeLimit()
	return 5
end

function SoilMap:setMinimapSamplingState(state)
	self.minimapSamplingState = state
	if not state then
		self.samplingCircleElement:setColor(0.1, 0.5, 0.1, 0.5)
	end
end

function SoilMap:collectFieldInfos(fieldInfoDisplayExtension)
	fieldInfoDisplayExtension:addFieldInfo(self.texts.fieldInfoSoil, self, self.updateFieldInfoDisplay, 1)
end

-- Local values: soilTypeIndex, soilType
function SoilMap:updateFieldInfoDisplay(fieldInfo, x, z, isColorBlindMode)
	local v133_ = self:getTypeIndexAtWorldPos(x, z)
	local v134_ = self.soilTypes[v133_]
	if v134_ == nil then
		return self.texts.fieldInfoNoData
	else
		return v134_.name
	end
end

function SoilMap:getHelpLinePage()
	return 2
end

function SoilMap:collectFarmlandHotspotActions(actions)
	local v137_ = {
		["title"] = g_i18n:getText("ui_purchaseSoilMaps"),
		["callback"] = self.onPurchaseSoilInformationCallback,
		["callbackTarget"] = self
	}
	table.insert(actions, v137_)
end

-- Local values: _, fieldArea, numSamples, price
function SoilMap:onPurchaseSoilInformationCallback(farmlandId)
	local _, v140_ = self.pfModule:getFarmlandFieldInfo(farmlandId)
	if v140_ > 0 then
		local v141_ = self:getNumSoilSamplesPerHa() * v140_
		local v142_ = math.ceil(v141_)
		local v143_ = self.pricePerSample[g_currentMission.missionInfo.economicDifficulty] or 0
		SoilSampleYesNoDialog.show(self.onSoilSampleDialogCallback, self, farmlandId, v140_, v142_, v143_ * v142_, v143_ * v142_ * (SoilMap.SAMPLING_PROVIDER_MULTIPLIER - 1))
	end
end

function SoilMap:onSoilSampleDialogCallback(yes, farmlandId)
	if yes then
		if g_server == nil and g_client ~= nil then
			g_client:getServerConnection():sendEvent(PurchaseSoilMapsEvent.new(farmlandId))
			return
		end
		self:purchaseSoilMaps(farmlandId)
	end
end

function SoilMap:getNumSoilSamplesPerHa()
	return 10000 / (3.141592653589793 * SoilMap.SAMPLING_RADIUS ^ 2) * 2
end

-- Local values: fieldArea, farmland, numSamples, farmId, price
function SoilMap:purchaseSoilMaps(farmlandId)
	local v149_ = g_farmlandManager.farmlands[farmlandId]
	local v150_ = v149_ == nil and 0 or (v149_.totalFieldArea or 0)
	if v150_ > 0 then
		local v151_ = self:getNumSoilSamplesPerHa() * v150_
		local v152_ = math.ceil(v151_)
		local v153_ = g_farmlandManager:getFarmlandOwner(farmlandId)
		local v154_ = self:getPricePerSoilSample() * v152_ * SoilMap.SAMPLING_PROVIDER_MULTIPLIER
		g_currentMission:addMoney(-v154_, v153_, self.moneyChangeType, true, true)
		if self.pfModule.farmlandStatistics ~= nil then
			self.pfModule.farmlandStatistics:updateStatistic(farmlandId, "numSoilSamples", v152_)
			self.pfModule.farmlandStatistics:updateStatistic(farmlandId, "soilSampleCosts", v154_)
		end
		if self.coverMap ~= nil then
			self.coverMap:uncoverFarmlandArea(farmlandId)
		end
	end
end

function SoilMap:getPricePerSoilSample()
	return self.pricePerSample[g_currentMission.missionInfo.economicDifficulty] or 0
end

function SoilMap:overwriteGameFunctions(pfModule)
	SoilMap:superClass().overwriteGameFunctions(self, pfModule)
end
