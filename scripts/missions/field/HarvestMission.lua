HarvestMission = {}
source("dataS/scripts/missions/field/HarvestMissionHotspot.lua")
HarvestMission.NAME = "harvestMission"
HarvestMission.SUCCESS_FACTOR = 0.93
local HarvestMission_mt = Class(HarvestMission, AbstractFieldMission)
InitStaticObjectClass(HarvestMission, "HarvestMission")
function HarvestMission.registerXMLPaths(schema, key)
	HarvestMission:superClass().registerXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#rewardPerHa", "Reward per ha")
	schema:register(XMLValueType.STRING, key .. ".fruitType#name", "Fruit type")
	schema:register(XMLValueType.INT, key .. ".fruitType#value", "Reward per ha")
	schema:register(XMLValueType.FLOAT, key .. "#failureCostFactor", "Failure cost factor")
	schema:register(XMLValueType.FLOAT, key .. "#failureCostOfTotal", "Failure cost of total")
end
function HarvestMission.registerSavegameXMLPaths(schema, key)
	HarvestMission:superClass().registerSavegameXMLPaths(schema, key)
	local harvestKey = string.format("%s.harvest", key)
	schema:register(XMLValueType.STRING, harvestKey .. "#fruitType", "Name of the fruit type")
	schema:register(XMLValueType.FLOAT, harvestKey .. "#expectedLiters", "Expected liters")
	schema:register(XMLValueType.FLOAT, harvestKey .. "#depositedLiters", "Deposited liters")
	schema:register(XMLValueType.STRING, harvestKey .. "#sellingStationPlaceableUniqueId", "Unique id of the selling point")
	schema:register(XMLValueType.INT, harvestKey .. "#unloadingStationIndex", "Index of the unloading station")
end
function HarvestMission.new(isServer, isClient, customMt)
	local title = g_i18n:getText("contract_field_harvest_title")
	local description = g_i18n:getText("contract_field_harvest_description")
	local self = AbstractFieldMission.new(isServer, isClient, title, description, customMt or HarvestMission_mt)
	self.workAreaTypes = { [WorkAreaType.CUTTER] = true, [WorkAreaType.COMBINECHOPPER] = true, [WorkAreaType.COMBINESWATH] = true, [WorkAreaType.FRUITPREPARER] = true }
	self.pendingSellingStationId = nil
	self.sellingStation = nil
	self.fillTypeIndex = nil
	self.depositedLiters = 0
	self.expectedLiters = 0
	self.harvestCompletionFactor = 0.8
	self.reimbursementPerHa = 0
	self.lastSellChange = -1
	return self
end
function HarvestMission:init(field, fruitTypeIndex, sellingStation)
	self.fruitTypeIndex = fruitTypeIndex
	self.fillTypeIndex = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(fruitTypeIndex)
	if fruitTypeIndex ~= nil and fruitTypeIndex == FruitType.ONION then
		self.workAreaTypes[WorkAreaType.TEDDER] = true
		self.harvestCompletionFactor = 0.5
	end
	local success = HarvestMission:superClass().init(self, field)
	self:setSellingStation(sellingStation)
	return success
end
function HarvestMission:onSavegameLoaded()
	if self.field == nil then
		Logging.error("Field is not set for harvest mission")
		g_missionManager:markMissionForDeletion(self)
		return
	end
	local fieldState = self.field:getFieldState()
	if fieldState.fruitTypeIndex ~= self.fruitTypeIndex then
		local fruitType = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
		Logging.error("FruitType '%s' is not present on field '%s' for harvest mission", fruitType.name, self.field:getName())
		g_missionManager:markMissionForDeletion(self)
	else
		if not self:getIsFinished() then
			local placeable = g_currentMission.placeableSystem:getPlaceableByUniqueId(self.sellingStationPlaceableUniqueId)
			if placeable == nil then
				Logging.error("Selling station placeable with uniqueId '%s' not available for harvest mission", self.sellingStationPlaceableUniqueId)
				g_missionManager:markMissionForDeletion(self)
				return
			end
			local unloadingStation = g_currentMission.storageSystem:getPlaceableUnloadingStation(placeable, self.unloadingStationIndex)
			if unloadingStation == nil then
				Logging.error("Unable to retrieve unloadingStation %d for placeable %s for harvest mission", self.unloadingStationIndex, placeable.configFileName)
				g_missionManager:markMissionForDeletion(self)
				return
			end
			self:setSellingStation(unloadingStation)
			if self:getWasStarted() then
				unloadingStation.missions[self] = self
			end
		end
		HarvestMission:superClass().onSavegameLoaded(self)
	end
end
function HarvestMission:delete()
	if self.sellingStation ~= nil then
		self.sellingStation.missions[self] = nil
		self.sellingStation = nil
	end
	if self.sellingStationMapHotspot ~= nil then
		table.removeElement(self.mapHotspots, self.sellingStationMapHotspot)
		g_currentMission:removeMapHotspot(self.sellingStationMapHotspot)
		self.sellingStationMapHotspot:delete()
		self.sellingStationMapHotspot = nil
	end
	HarvestMission:superClass().delete(self)
end
function HarvestMission:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.sellingStation)
	streamWriteUIntN(streamId, self.fillTypeIndex, FillTypeManager.SEND_NUM_BITS)
	streamWriteUIntN(streamId, self.fruitTypeIndex or 0, FruitTypeManager.SEND_NUM_BITS)
	HarvestMission:superClass().writeStream(self, streamId, connection)
end
function HarvestMission:readStream(streamId, connection)
	self.pendingSellingStationId = NetworkUtil.readNodeObjectId(streamId)
	self.fillTypeIndex = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
	self.fruitTypeIndex = streamReadUIntN(streamId, FruitTypeManager.SEND_NUM_BITS)
	if self.fruitTypeIndex ~= nil and self.fruitTypeIndex == FruitType.ONION then
		self.workAreaTypes[WorkAreaType.TEDDER] = true
		self.harvestCompletionFactor = 0.5
	end
	HarvestMission:superClass().readStream(self, streamId, connection)
end
function HarvestMission:saveToXMLFile(xmlFile, key)
	local harvestKey = string.format("%s.harvest", key)
	xmlFile:setValue(harvestKey .. "#fruitType", g_fruitTypeManager:getFruitTypeNameByIndex(self.fruitTypeIndex))
	xmlFile:setValue(harvestKey .. "#expectedLiters", self.expectedLiters)
	xmlFile:setValue(harvestKey .. "#depositedLiters", self.depositedLiters)
	if self.sellingStation ~= nil then
		local sellingStationPlaceable = self.sellingStation.owningPlaceable
		if sellingStationPlaceable == nil then
			local sellingStationName = self.sellingStation.getName and self.sellingStation:getName() or "unknown"
			Logging.xmlWarning(xmlFile, "Unable to retrieve placeable of sellingStation '%s' for saving harvest mission '%s' ", sellingStationName, key)
			return
		end
		local unloadingStationIndex = g_currentMission.storageSystem:getPlaceableUnloadingStationIndex(sellingStationPlaceable, self.sellingStation)
		if unloadingStationIndex == nil then
			if not self.sellingStation.getName or not self.sellingStation:getName() then
				local sellingStationName = sellingStationPlaceable.getName and sellingStationPlaceable:getName() or "unknown"
			end
			Logging.xmlWarning(xmlFile, "Unable to retrieve unloading station index of sellingStation '%s' for saving harvest mission '%s' ", sellingStationName, key)
			return
		end
		xmlFile:setValue(harvestKey .. "#sellingStationPlaceableUniqueId", sellingStationPlaceable:getUniqueId())
		xmlFile:setValue(harvestKey .. "#unloadingStationIndex", unloadingStationIndex)
	end
	HarvestMission:superClass().saveToXMLFile(self, xmlFile, key)
end
function HarvestMission:loadFromXMLFile(xmlFile, key)
	local harvestKey = string.format("%s.harvest", key)
	local fruitTypeName = xmlFile:getValue(harvestKey .. "#fruitType")
	local fruitType = g_fruitTypeManager:getFruitTypeByName(fruitTypeName)
	if fruitType == nil then
		Logging.xmlError(xmlFile, "FruitType '%s' not defined", fruitTypeName)
		return false
	end
	self.fruitTypeIndex = fruitType.index
	self.fillTypeIndex = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(self.fruitTypeIndex)
	self.expectedLiters = xmlFile:getValue(harvestKey .. "#expectedLiters", self.expectedLiters)
	self.depositedLiters = xmlFile:getValue(harvestKey .. "#depositedLiters", self.depositedLiters)
	if self.fruitTypeIndex ~= nil and self.fruitTypeIndex == FruitType.ONION then
		self.workAreaTypes[WorkAreaType.TEDDER] = true
		self.harvestCompletionFactor = 0.5
	end
	if not HarvestMission:superClass().loadFromXMLFile(self, xmlFile, key) then
		return false
	else
		if not self:getIsFinished() then
			local sellingStationPlaceableUniqueId = xmlFile:getValue(harvestKey .. "#sellingStationPlaceableUniqueId")
			if sellingStationPlaceableUniqueId == nil then
				Logging.xmlError(xmlFile, "No sellingStationPlaceable uniqueId given for harvest mission at '%s'", harvestKey)
				return false
			end
			local unloadingStationIndex = xmlFile:getValue(harvestKey .. "#unloadingStationIndex")
			if unloadingStationIndex == nil then
				Logging.xmlError(xmlFile, "No unloadting station index given for harvest mission at '%s'", harvestKey)
				return false
			end
			self.sellingStationPlaceableUniqueId = sellingStationPlaceableUniqueId
			self.unloadingStationIndex = unloadingStationIndex
		end
		return true
	end
end
function HarvestMission:update(dt)
	HarvestMission:superClass().update(self, dt)
	if self.pendingSellingStationId ~= nil then
		self:tryToResolveSellingStation()
	end
	if 0 < self.lastSellChange then
		self.lastSellChange = self.lastSellChange - 1
		if self.lastSellChange == 0 then
			local expected = self.expectedLiters * AbstractMission.SUCCESS_FACTOR
			local percentage = math.floor(self.depositedLiters / expected * 100)
			g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format(g_i18n:getText("contract_field_harvest_progress_transporting_forField"), percentage, self.field.farmland:getId()))
		end
	end
end
function HarvestMission:createModifier()
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
	if fruitDesc ~= nil and fruitDesc.terrainDataPlaneId ~= nil then
		local modifier = DensityMapModifier.new(fruitDesc.terrainDataPlaneId, fruitDesc.startStateChannel, fruitDesc.numStateChannels, g_terrainNode)
		local filter = DensityMapFilter.new(modifier)
		self.completionModifier = DensityMapMultiModifier.new()
		for cutState, _ in pairs(fruitDesc.cutStates) do
			filter:setValueCompareParams(DensityValueCompareType.EQUAL, cutState)
			self.completionModifier:addExecuteGet("cutState", modifier, filter)
		end
		filter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		self.completionModifier:addExecuteGet("totalArea", modifier, filter)
		self.matchingPixels = {}
	end
end
function HarvestMission:tryToResolveSellingStation()
	if self.pendingSellingStationId == nil or self.sellingStation ~= nil then
		return
	end
	local sellingStation = NetworkUtil.getObject(self.pendingSellingStationId)
	if sellingStation ~= nil then
		self:setSellingStation(sellingStation)
	end
end
function HarvestMission:setSellingStation(sellingStation)
	if sellingStation == nil then
		return
	else
		self.pendingSellingStationId = nil
		self.sellingStation = sellingStation
		local placeable = sellingStation.owningPlaceable
		if placeable ~= nil and placeable.getHotspot ~= nil then
			local mapHotspot = placeable:getHotspot()
			if mapHotspot ~= nil then
				self.sellingStationMapHotspot = HarvestMissionHotspot.new()
				self.sellingStationMapHotspot:setWorldPosition(mapHotspot:getWorldPosition())
				table.addElement(self.mapHotspots, self.sellingStationMapHotspot)
				if self.addSellingStationHotSpot then
					g_currentMission:addMapHotspot(self.sellingStationMapHotspot)
				end
			end
		end
	end
end
function HarvestMission:addHotspots()
	HarvestMission:superClass().addHotspots(self)
	self.addSellingStationHotSpot = true
	if self.sellingStationMapHotspot ~= nil then
		g_currentMission:addMapHotspot(self.sellingStationMapHotspot)
	end
end
function HarvestMission:removeHotspot()
	HarvestMission:superClass().removeHotspot(self)
	if self.sellingStationMapHotspot ~= nil then
		g_currentMission:removeMapHotspot(self.sellingStationMapHotspot)
	end
	self.addSellingStationHotSpot = false
end
function HarvestMission:start(spawnVehicles)
	if self.pendingSellingStationId ~= nil then
		self:tryToResolveSellingStation()
	end
	if self.sellingStation == nil then
		return false
	else
		self.sellingStation.missions[self] = self
		return HarvestMission:superClass().start(self, spawnVehicles)
	end
end
function HarvestMission:finishedPreparing()
	HarvestMission:superClass().finishedPreparing(self)
	local fieldAreaHa = nil
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
	if fruitDesc ~= nil and fruitDesc.terrainDataPlaneId ~= nil then
		local modifier = DensityMapModifier.new(fruitDesc.terrainDataPlaneId, fruitDesc.startStateChannel, fruitDesc.numStateChannels, g_terrainNode)
		local filter = DensityMapFilter.new(modifier)
		filter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		local densityMapPolygon = self.field:getDensityMapPolygon()
		densityMapPolygon:applyToModifier(modifier)
		local _, fieldArea, _ = modifier:executeGet(filter)
		fieldAreaHa = MathUtil.areaToHa(fieldArea, g_currentMission:getFruitPixelsToSqm())
	end
	self.expectedLiters = self:getMaxCutLiters(fieldAreaHa)
	if self.expectedLiters <= 0 then
		self:finish(MissionFinishState.FAILED)
	end
end
function HarvestMission:finish(success)
	HarvestMission:superClass().finish(self, success)
	if self.sellingStation ~= nil then
		self.sellingStation.missions[self] = nil
		self.sellingStation = nil
	end
end
function HarvestMission:getFieldFinishTask()
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
	local fieldState = self.field:getFieldState()
	fieldState.fruitTypeIndex = self.fruitTypeIndex
	fieldState.growthState = fruitDesc.cutState
	return HarvestMission:superClass().getFieldFinishTask(self)
end
function HarvestMission:getPartitionCompletion(partitionIndex)
	self:setPartitionRegion(partitionIndex)
	if self.completionModifier ~= nil then
		self.completionModifier:resetStats()
		self.completionModifier:execute(nil, self.matchingPixels, nil)
		local area = self.matchingPixels.cutState
		local totalArea = self.matchingPixels.totalArea
		return 0, area, totalArea
	else
		return 0, 0, 0
	end
end
function HarvestMission:getCompletion()
	local sellCompletion = 1
	if 0 < self.expectedLiters then
		sellCompletion = math.min(self.depositedLiters / self.expectedLiters / HarvestMission.SUCCESS_FACTOR, 1)
	end
	local fieldCompletion = self:getFieldCompletion()
	local harvestCompletion = math.min(fieldCompletion / AbstractMission.SUCCESS_FACTOR, 1)
	local harvestCompletionFactor = self.harvestCompletionFactor
	local deliverCompletionFactor = 1 - harvestCompletionFactor
	return math.min(1, harvestCompletionFactor * harvestCompletion + deliverCompletionFactor * sellCompletion)
end
function HarvestMission:getVehicleVariant()
	local fruitType = self.fruitTypeIndex
	if fruitType ~= nil then
		if fruitType == FruitType.SUNFLOWER or fruitType == FruitType.MAIZE then
			return "MAIZE"
		end
		if fruitType == FruitType.SUGARBEET then
			return "SUGARBEET"
		end
		if fruitType == FruitType.POTATO then
			return "POTATO"
		end
		if fruitType == FruitType.COTTON then
			return "COTTON"
		end
		if fruitType == FruitType.SUGARCANE then
			return "SUGARCANE"
		end
		if fruitType == FruitType.PEA then
			return "PEA"
		end
		if fruitType == FruitType.SPINACH then
			return "SPINACH"
		end
		if fruitType == FruitType.GREENBEAN then
			return "GREENBEAN"
		end
		if fruitType == FruitType.CARROT or fruitType == FruitType.PARSNIP or fruitType == FruitType.BEETROOT then
			return "VEGETABLES"
		end
		if fruitType == FruitType.ONION then
			return "ONION"
		end
	end
	return "GRAIN"
end
function HarvestMission:getVariant()
	local fruitTypeIndex = self.fruitTypeIndex
	if fruitTypeIndex ~= nil then
		if fruitTypeIndex == FruitType.BEETROOT then
			return "BEETROOT"
		end
		if fruitTypeIndex == FruitType.CARROT then
			return "CARROT"
		end
		if fruitTypeIndex == FruitType.MAIZE then
			return "MAIZE"
		end
		if fruitTypeIndex == FruitType.COTTON then
			return "COTTON"
		end
		if fruitTypeIndex == FruitType.GREENBEAN then
			return "GREENBEAN"
		end
		if fruitTypeIndex == FruitType.PARSNIP then
			return "PARSNIP"
		end
		if fruitTypeIndex == FruitType.PEA then
			return "PEA"
		end
		if fruitTypeIndex == FruitType.POPLAR then
			return "POPLAR"
		end
		if fruitTypeIndex == FruitType.POTATO then
			return "POTATO"
		end
		if fruitTypeIndex == FruitType.RICE then
			return "RICE"
		end
		if fruitTypeIndex == FruitType.RICELONGGRAIN then
			return "RICELONGGRAIN"
		end
		if fruitTypeIndex == FruitType.SPINACH then
			return "SPINACH"
		end
		if fruitTypeIndex == FruitType.SUGARCANE then
			return "SUGARCANE"
		end
		if fruitTypeIndex == FruitType.SUGARBEET then
			return "SUGARBEET"
		end
		if fruitTypeIndex == FruitType.SUNFLOWER then
			return "SUNFLOWER"
		end
		if fruitTypeIndex == FruitType.ONION then
			return "ONION"
		end
	end
	return "GRAIN"
end
function HarvestMission:getDetails()
	local details = HarvestMission:superClass().getDetails(self)
	local title = nil
	if self.pendingSellingStationId ~= nil then
		self:tryToResolveSellingStation()
	end
	if self.sellingStation ~= nil then
		title = self.sellingStation:getName()
	end
	if title ~= nil then
		table.insert(details, { value = title, title = g_i18n:getText("contract_details_harvesting_sellingStation") })
	end
	table.insert(details, { title = g_i18n:getText("contract_details_harvesting_crop"), value = g_fillTypeManager:getFillTypeTitleByIndex(self.fillTypeIndex) })
	return details
end
function HarvestMission:getExtraProgressText()
	if 0.1 <= self.completion then
		local title = "Unknown"
		if self.pendingSellingStationId ~= nil then
			self:tryToResolveSellingStation()
		end
		if self.sellingStation ~= nil then
			title = self.sellingStation:getName()
		end
		return string.format(g_i18n:getText("contract_field_harvest_nextUnloadDesc"), g_fillTypeManager:getFillTypeTitleByIndex(self.fillTypeIndex), title)
	else
		return ""
	end
end
function HarvestMission:fillSold(fillDelta)
	self.depositedLiters = math.min(self.depositedLiters + fillDelta, self.expectedLiters)
	local expected = self.expectedLiters * AbstractMission.SUCCESS_FACTOR
	if self.sellingStation ~= nil and expected <= self.depositedLiters then
		self.sellingStation.missions[self] = nil
	end
	self.lastSellChange = 30
end
function HarvestMission:getRewardPerHa()
	local data = g_missionManager:getMissionTypeDataByName(HarvestMission.NAME)
	return data.rewardPerFruitHa[self.fruitTypeIndex] or data.rewardPerHa
end
function HarvestMission:getStealingCosts()
	if self.finishState ~= MissionFinishState.SUCCESS and self.isServer then
		local data = g_missionManager:getMissionTypeDataByName(HarvestMission.NAME)
		local fruitType = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
		local fillTypeIndex = fruitType.fillType.index
		local litersHarvested = self.expectedLiters * self:getFieldCompletion()
		for _, vehicle in pairs(self.vehicles) do
			if vehicle.spec_fillUnit == nil then
				continue
			end
			for index, _ in pairs(vehicle:getFillUnits()) do
				local fillType = vehicle:getFillUnitFillType(index)
				if fillType == self.fillType then
					local level = vehicle:getFillUnitFillLevel(index)
					litersHarvested = litersHarvested - level
				end
			end
		end
		local diff = litersHarvested - self.depositedLiters
		if litersHarvested * data.failureCostFactor < diff then
			local _, pricePerLiter = HarvestMission.getSellingStationWithHighestPrice(fillTypeIndex)
			local farmReimbursement = diff * data.failureCostOfTotal * pricePerLiter
			return farmReimbursement
		end
	end
	return 0
end
function HarvestMission:getMaxCutLiters(fieldAreaHa)
	local fieldState = self.field:getFieldState()
	local fruitTypeIndex = fieldState.fruitTypeIndex
	local multiplier = fieldState:getHarvestScaleMultiplier()
	local areaHa = (fieldAreaHa or self.field:getAreaHa()) * multiplier
	local areaPixel = MathUtil.haToSqm(areaHa) / g_currentMission:getFruitPixelsToSqm()
	local liters = g_fruitTypeManager:getFruitTypeAreaLiters(fruitTypeIndex, areaPixel, false)
	return liters
end
function HarvestMission:getMissionTypeName()
	return HarvestMission.NAME
end
function HarvestMission:validate(event)
	if not HarvestMission:superClass().validate(self, event) then
		return false
	else
		if not self:getIsFinished() then
			if not HarvestMission.isAvailableForField(self.field, self) then
				return false
			end
			if self.sellingStation ~= nil and not self.sellingStation.isRegistered then
				return false
			end
		end
		return true
	end
end
function HarvestMission:onDeleteSellingStation(sellingStation)
	if sellingStation == self.sellingStation and (self.isServer and (self.status == MissionStatus.RUNNING and not g_currentMission.isExitingGame)) then
		Logging.warning("Finish harvest mission because selling station was removed")
		self:finish(MissionFinishState.FAILED)
	end
end
function HarvestMission.loadMapData(xmlFile, key, baseDirectory)
	local data = g_missionManager:getMissionTypeDataByName(HarvestMission.NAME)
	data.rewardPerHa = xmlFile:getFloat(key .. "#rewardPerHa", 2500)
	data.rewardPerFruitHa = {}
	xmlFile:iterate(key .. ".fruitType", function(_, rewardKey)
		local name = xmlFile:getString(rewardKey .. "#name")
		local value = xmlFile:getFloat(rewardKey .. "#value", data.rewardPerHa)
		local fruitTypeIndex = g_fruitTypeManager:getFruitTypeIndexByName(name)
		if fruitTypeIndex ~= nil then
			data.rewardPerFruitHa[fruitTypeIndex] = value
		else
			Logging.xmlWarning(xmlFile, "Harvestmission rewardPerHa fruitType '%s' is not defined for '%s'", name, rewardKey)
		end
	end)
	data.failureCostFactor = xmlFile:getFloat(key .. "#failureCostFactor", 0.1)
	data.failureCostOfTotal = xmlFile:getFloat(key .. "#failureCostOfTotal", 0.95)
	return true
end
function HarvestMission.tryGenerateMission()
	if HarvestMission.canRun() then
		local field = g_fieldManager:getFieldForMission()
		if field == nil then
			return
		end
		if field.currentMission ~= nil then
			return
		end
		if not HarvestMission.isAvailableForField(field, nil) then
			return
		end
		local fieldState = field:getFieldState()
		local fruitTypeIndex = fieldState.fruitTypeIndex
		local fillTypeIndex = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(fruitTypeIndex)
		local sellingStation, _ = HarvestMission.getSellingStationWithHighestPrice(fillTypeIndex)
		if not HarvestMission.isAvailableForSellingStation(sellingStation) then
			return
		end
		local mission = HarvestMission.new(true, g_client ~= nil)
		if mission:init(field, fruitTypeIndex, sellingStation) then
			mission:setDefaultEndDate()
			return mission
		end
		mission:delete()
	end
	return nil
end
function HarvestMission.getSellingStationWithHighestPrice(fillTypeIndex)
	local highestPrice = 0
	local sellingStation = nil
	for _, unloadingStation in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
		if unloadingStation.owningPlaceable == nil then
			continue
		end
		if unloadingStation.isSellingPoint and (unloadingStation.allowMissions and unloadingStation.acceptedFillTypes[fillTypeIndex]) then
			local price = unloadingStation:getEffectiveFillTypePrice(fillTypeIndex)
			if highestPrice < price then
				highestPrice = price
				sellingStation = unloadingStation
			end
		end
	end
	return sellingStation, highestPrice
end
function HarvestMission.isAvailableForSellingStation(sellingStation)
	if sellingStation == nil then
		return false
	else
		return true
	end
end
function HarvestMission.isAvailableForField(field, mission)
	if mission == nil then
		local fieldState = field:getFieldState()
		if not fieldState.isValid then
			return false
		end
		local fruitTypeIndex = fieldState.fruitTypeIndex
		if fruitTypeIndex == FruitType.UNKNOWN then
			return false
		end
		local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
		if fruitTypeDesc:getIsCatchCrop() then
			return false
		end
		local growthState = fieldState.growthState
		if not fruitTypeDesc:getIsHarvestReady(growthState) then
			return false
		end
	end
	return true
end
function HarvestMission.canRun()
	local data = g_missionManager:getMissionTypeDataByName(HarvestMission.NAME)
	if data.maxNumInstances <= data.numInstances then
		return false
	elseif g_currentMission.growthSystem:getIsGrowingInProgress() then
		return false
	else
		return true
	end
end
g_missionManager:registerMissionType(HarvestMission, HarvestMission.NAME, 10)
