-- Local values: HarvestMission_mt
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

-- Local values: harvestKey
function HarvestMission.registerSavegameXMLPaths(schema, key)
	HarvestMission:superClass().registerSavegameXMLPaths(schema, key)
	local v6_ = string.format("%s.harvest", key)
	schema:register(XMLValueType.STRING, v6_ .. "#fruitType", "Name of the fruit type")
	schema:register(XMLValueType.FLOAT, v6_ .. "#expectedLiters", "Expected liters")
	schema:register(XMLValueType.FLOAT, v6_ .. "#depositedLiters", "Deposited liters")
	schema:register(XMLValueType.STRING, v6_ .. "#sellingStationPlaceableUniqueId", "Unique id of the selling point")
	schema:register(XMLValueType.INT, v6_ .. "#unloadingStationIndex", "Index of the unloading station")
end

-- Upvalues: HarvestMission_mt
-- Local values: title, description, self
function HarvestMission.new(isServer, isClient, customMt)
	-- upvalues: (copy) HarvestMission_mt
	local v10_ = g_i18n:getText("contract_field_harvest_title")
	local v11_ = g_i18n:getText("contract_field_harvest_description")
	local v12_ = AbstractFieldMission.new(isServer, isClient, v10_, v11_, customMt or HarvestMission_mt)
	v12_.workAreaTypes = {
		[WorkAreaType.CUTTER] = true,
		[WorkAreaType.COMBINECHOPPER] = true,
		[WorkAreaType.COMBINESWATH] = true,
		[WorkAreaType.FRUITPREPARER] = true
	}
	v12_.pendingSellingStationId = nil
	v12_.sellingStation = nil
	v12_.fillTypeIndex = nil
	v12_.depositedLiters = 0
	v12_.expectedLiters = 0
	v12_.harvestCompletionFactor = 0.8
	v12_.reimbursementPerHa = 0
	v12_.lastSellChange = -1
	return v12_
end

-- Local values: success
function HarvestMission:init(field, fruitTypeIndex, sellingStation)
	self.fruitTypeIndex = fruitTypeIndex
	self.fillTypeIndex = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(fruitTypeIndex)
	if fruitTypeIndex ~= nil and fruitTypeIndex == FruitType.ONION then
		self.workAreaTypes[WorkAreaType.TEDDER] = true
		self.harvestCompletionFactor = 0.5
	end
	local v17_ = HarvestMission:superClass().init(self, field)
	self:setSellingStation(sellingStation)
	return v17_
end

-- Local values: fieldState, fruitType, placeable, unloadingStation
function HarvestMission:onSavegameLoaded()
	if self.field == nil then
		Logging.error("Field is not set for harvest mission")
		g_missionManager:markMissionForDeletion(self)
		return
	elseif self.field:getFieldState().fruitTypeIndex == self.fruitTypeIndex then
		if not self:getIsFinished() then
			local v19_ = g_currentMission.placeableSystem:getPlaceableByUniqueId(self.sellingStationPlaceableUniqueId)
			if v19_ == nil then
				Logging.error("Selling station placeable with uniqueId \'%s\' not available for harvest mission", self.sellingStationPlaceableUniqueId)
				g_missionManager:markMissionForDeletion(self)
				return
			end
			local v20_ = g_currentMission.storageSystem:getPlaceableUnloadingStation(v19_, self.unloadingStationIndex)
			if v20_ == nil then
				Logging.error("Unable to retrieve unloadingStation %d for placeable %s for harvest mission", self.unloadingStationIndex, v19_.configFileName)
				g_missionManager:markMissionForDeletion(self)
				return
			end
			self:setSellingStation(v20_)
			if self:getWasStarted() then
				v20_.missions[self] = self
			end
		end
		HarvestMission:superClass().onSavegameLoaded(self)
	else
		local v21_ = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
		Logging.error("FruitType \'%s\' is not present on field \'%s\' for harvest mission", v21_.name, self.field:getName())
		g_missionManager:markMissionForDeletion(self)
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

-- Local values: harvestKey, sellingStationPlaceable, sellingStationName, unloadingStationIndex, sellingStationName
function HarvestMission:saveToXMLFile(xmlFile, key)
	local v32_ = string.format("%s.harvest", key)
	xmlFile:setValue(v32_ .. "#fruitType", g_fruitTypeManager:getFruitTypeNameByIndex(self.fruitTypeIndex))
	xmlFile:setValue(v32_ .. "#expectedLiters", self.expectedLiters)
	xmlFile:setValue(v32_ .. "#depositedLiters", self.depositedLiters)
	if self.sellingStation ~= nil then
		local v33_ = self.sellingStation.owningPlaceable
		if v33_ == nil then
			local v34_ = self.sellingStation.getName and self.sellingStation:getName() or "unknown"
			Logging.xmlWarning(xmlFile, "Unable to retrieve placeable of sellingStation \'%s\' for saving harvest mission \'%s\' ", v34_, key)
			return
		end
		local v35_ = g_currentMission.storageSystem:getPlaceableUnloadingStationIndex(v33_, self.sellingStation)
		if v35_ == nil then
			local v36_ = self.sellingStation.getName and self.sellingStation:getName() or (v33_.getName and v33_:getName() or "unknown")
			Logging.xmlWarning(xmlFile, "Unable to retrieve unloading station index of sellingStation \'%s\' for saving harvest mission \'%s\' ", v36_, key)
			return
		end
		xmlFile:setValue(v32_ .. "#sellingStationPlaceableUniqueId", v33_:getUniqueId())
		xmlFile:setValue(v32_ .. "#unloadingStationIndex", v35_)
	end
	HarvestMission:superClass().saveToXMLFile(self, xmlFile, key)
end

-- Local values: harvestKey, fruitTypeName, fruitType, sellingStationPlaceableUniqueId, unloadingStationIndex
function HarvestMission:loadFromXMLFile(xmlFile, key)
	local v40_ = string.format("%s.harvest", key)
	local v41_ = xmlFile:getValue(v40_ .. "#fruitType")
	local v42_ = g_fruitTypeManager:getFruitTypeByName(v41_)
	if v42_ == nil then
		Logging.xmlError(xmlFile, "FruitType \'%s\' not defined", v41_)
		return false
	end
	self.fruitTypeIndex = v42_.index
	self.fillTypeIndex = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(self.fruitTypeIndex)
	self.expectedLiters = xmlFile:getValue(v40_ .. "#expectedLiters", self.expectedLiters)
	self.depositedLiters = xmlFile:getValue(v40_ .. "#depositedLiters", self.depositedLiters)
	if self.fruitTypeIndex ~= nil and self.fruitTypeIndex == FruitType.ONION then
		self.workAreaTypes[WorkAreaType.TEDDER] = true
		self.harvestCompletionFactor = 0.5
	end
	if not HarvestMission:superClass().loadFromXMLFile(self, xmlFile, key) then
		return false
	end
	if not self:getIsFinished() then
		local v43_ = xmlFile:getValue(v40_ .. "#sellingStationPlaceableUniqueId")
		if v43_ == nil then
			Logging.xmlError(xmlFile, "No sellingStationPlaceable uniqueId given for harvest mission at \'%s\'", v40_)
			return false
		end
		local v44_ = xmlFile:getValue(v40_ .. "#unloadingStationIndex")
		if v44_ == nil then
			Logging.xmlError(xmlFile, "No unloadting station index given for harvest mission at \'%s\'", v40_)
			return false
		end
		self.sellingStationPlaceableUniqueId = v43_
		self.unloadingStationIndex = v44_
	end
	return true
end

-- Local values: expected, percentage
function HarvestMission:update(dt)
	HarvestMission:superClass().update(self, dt)
	if self.pendingSellingStationId ~= nil then
		self:tryToResolveSellingStation()
	end
	if self.lastSellChange > 0 then
		self.lastSellChange = self.lastSellChange - 1
		if self.lastSellChange == 0 then
			local v47_ = self.expectedLiters * AbstractMission.SUCCESS_FACTOR
			local v48_ = self.depositedLiters / v47_ * 100
			local v49_ = math.floor(v48_)
			g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format(g_i18n:getText("contract_field_harvest_progress_transporting_forField"), v49_, self.field.farmland:getId()))
		end
	end
end

-- Local values: fruitDesc, modifier, filter, cutState, _
function HarvestMission:createModifier()
	local v51_ = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
	if v51_ ~= nil and v51_.terrainDataPlaneId ~= nil then
		local v52_ = DensityMapModifier.new(v51_.terrainDataPlaneId, v51_.startStateChannel, v51_.numStateChannels, g_terrainNode)
		local v53_ = DensityMapFilter.new(v52_)
		self.completionModifier = DensityMapMultiModifier.new()
		for v54_, _ in pairs(v51_.cutStates) do
			v53_:setValueCompareParams(DensityValueCompareType.EQUAL, v54_)
			self.completionModifier:addExecuteGet("cutState", v52_, v53_)
		end
		v53_:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		self.completionModifier:addExecuteGet("totalArea", v52_, v53_)
		self.matchingPixels = {}
	end
end

-- Local values: sellingStation
function HarvestMission:tryToResolveSellingStation()
	if self.pendingSellingStationId ~= nil and self.sellingStation == nil then
		local v56_ = NetworkUtil.getObject(self.pendingSellingStationId)
		if v56_ ~= nil then
			self:setSellingStation(v56_)
		end
	end
end

-- Local values: placeable, mapHotspot
function HarvestMission:setSellingStation(sellingStation)
	if sellingStation ~= nil then
		self.pendingSellingStationId = nil
		self.sellingStation = sellingStation
		local v59_ = sellingStation.owningPlaceable
		if v59_ ~= nil and v59_.getHotspot ~= nil then
			local v60_ = v59_:getHotspot()
			if v60_ ~= nil then
				self.sellingStationMapHotspot = HarvestMissionHotspot.new()
				self.sellingStationMapHotspot:setWorldPosition(v60_:getWorldPosition())
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
	end
	self.sellingStation.missions[self] = self
	return HarvestMission:superClass().start(self, spawnVehicles)
end

-- Local values: fieldAreaHa, fruitDesc, modifier, filter, densityMapPolygon, _, fieldArea, _
function HarvestMission:finishedPreparing()
	HarvestMission:superClass().finishedPreparing(self)
	local v66_ = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
	local v67_
	if v66_ == nil or v66_.terrainDataPlaneId == nil then
		v67_ = nil
	else
		local v68_ = DensityMapModifier.new(v66_.terrainDataPlaneId, v66_.startStateChannel, v66_.numStateChannels, g_terrainNode)
		local v69_ = DensityMapFilter.new(v68_)
		v69_:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		self.field:getDensityMapPolygon():applyToModifier(v68_)
		local _, v70_, _ = v68_:executeGet(v69_)
		v67_ = MathUtil.areaToHa(v70_, g_currentMission:getFruitPixelsToSqm())
	end
	self.expectedLiters = self:getMaxCutLiters(v67_)
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

-- Local values: fruitDesc, fieldState
function HarvestMission:getFieldFinishTask()
	local v74_ = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
	local v75_ = self.field:getFieldState()
	v75_.fruitTypeIndex = self.fruitTypeIndex
	v75_.growthState = v74_.cutState
	return HarvestMission:superClass().getFieldFinishTask(self)
end

-- Local values: area, totalArea
function HarvestMission:getPartitionCompletion(partitionIndex)
	self:setPartitionRegion(partitionIndex)
	if self.completionModifier == nil then
		return 0, 0, 0
	end
	self.completionModifier:resetStats()
	self.completionModifier:execute(nil, self.matchingPixels, nil)
	return 0, self.matchingPixels.cutState, self.matchingPixels.totalArea
end

-- Local values: sellCompletion, fieldCompletion, harvestCompletion, harvestCompletionFactor, deliverCompletionFactor
function HarvestMission:getCompletion()
	local v79_
	if self.expectedLiters > 0 then
		local v80_ = self.depositedLiters / self.expectedLiters / HarvestMission.SUCCESS_FACTOR
		v79_ = math.min(v80_, 1)
	else
		v79_ = 1
	end
	local v81_ = self:getFieldCompletion() / AbstractMission.SUCCESS_FACTOR
	local v82_ = math.min(v81_, 1)
	local v83_ = self.harvestCompletionFactor
	local v84_ = 1 - v83_
	local v85_ = v83_ * v82_ + v84_ * v79_
	return math.min(1, v85_)
end

-- Local values: fruitType
function HarvestMission:getVehicleVariant()
	local v87_ = self.fruitTypeIndex
	if v87_ ~= nil then
		if v87_ == FruitType.SUNFLOWER or v87_ == FruitType.MAIZE then
			return "MAIZE"
		end
		if v87_ == FruitType.SUGARBEET then
			return "SUGARBEET"
		end
		if v87_ == FruitType.POTATO then
			return "POTATO"
		end
		if v87_ == FruitType.COTTON then
			return "COTTON"
		end
		if v87_ == FruitType.SUGARCANE then
			return "SUGARCANE"
		end
		if v87_ == FruitType.PEA then
			return "PEA"
		end
		if v87_ == FruitType.SPINACH then
			return "SPINACH"
		end
		if v87_ == FruitType.GREENBEAN then
			return "GREENBEAN"
		end
		if v87_ == FruitType.CARROT or (v87_ == FruitType.PARSNIP or v87_ == FruitType.BEETROOT) then
			return "VEGETABLES"
		end
		if v87_ == FruitType.ONION then
			return "ONION"
		end
	end
	return "GRAIN"
end

-- Local values: fruitTypeIndex
function HarvestMission:getVariant()
	local v89_ = self.fruitTypeIndex
	if v89_ ~= nil then
		if v89_ == FruitType.BEETROOT then
			return "BEETROOT"
		end
		if v89_ == FruitType.CARROT then
			return "CARROT"
		end
		if v89_ == FruitType.MAIZE then
			return "MAIZE"
		end
		if v89_ == FruitType.COTTON then
			return "COTTON"
		end
		if v89_ == FruitType.GREENBEAN then
			return "GREENBEAN"
		end
		if v89_ == FruitType.PARSNIP then
			return "PARSNIP"
		end
		if v89_ == FruitType.PEA then
			return "PEA"
		end
		if v89_ == FruitType.POPLAR then
			return "POPLAR"
		end
		if v89_ == FruitType.POTATO then
			return "POTATO"
		end
		if v89_ == FruitType.RICE then
			return "RICE"
		end
		if v89_ == FruitType.RICELONGGRAIN then
			return "RICELONGGRAIN"
		end
		if v89_ == FruitType.SPINACH then
			return "SPINACH"
		end
		if v89_ == FruitType.SUGARCANE then
			return "SUGARCANE"
		end
		if v89_ == FruitType.SUGARBEET then
			return "SUGARBEET"
		end
		if v89_ == FruitType.SUNFLOWER then
			return "SUNFLOWER"
		end
		if v89_ == FruitType.ONION then
			return "ONION"
		end
	end
	return "GRAIN"
end

-- Local values: details, title
function HarvestMission:getDetails()
	local v91_ = HarvestMission:superClass().getDetails(self)
	local v92_ = nil
	if self.pendingSellingStationId ~= nil then
		self:tryToResolveSellingStation()
	end
	if self.sellingStation ~= nil then
		v92_ = self.sellingStation:getName()
	end
	if v92_ ~= nil then
		local v93_ = {
			["title"] = g_i18n:getText("contract_details_harvesting_sellingStation"),
			["value"] = v92_
		}
		table.insert(v91_, v93_)
	end
	local v94_ = {
		["title"] = g_i18n:getText("contract_details_harvesting_crop"),
		["value"] = g_fillTypeManager:getFillTypeTitleByIndex(self.fillTypeIndex)
	}
	table.insert(v91_, v94_)
	return v91_
end

-- Local values: title
function HarvestMission:getExtraProgressText()
	if self.completion < 0.1 then
		return ""
	end
	local v96_ = "Unknown"
	if self.pendingSellingStationId ~= nil then
		self:tryToResolveSellingStation()
	end
	if self.sellingStation ~= nil then
		v96_ = self.sellingStation:getName()
	end
	return string.format(g_i18n:getText("contract_field_harvest_nextUnloadDesc"), g_fillTypeManager:getFillTypeTitleByIndex(self.fillTypeIndex), v96_)
end

-- Local values: expected
function HarvestMission:fillSold(fillDelta)
	local v99_ = self.depositedLiters + fillDelta
	local v100_ = self.expectedLiters
	self.depositedLiters = math.min(v99_, v100_)
	local v101_ = self.expectedLiters * AbstractMission.SUCCESS_FACTOR
	if self.sellingStation ~= nil and v101_ <= self.depositedLiters then
		self.sellingStation.missions[self] = nil
	end
	self.lastSellChange = 30
end

-- Local values: data
function HarvestMission:getRewardPerHa()
	local v103_ = g_missionManager:getMissionTypeDataByName(HarvestMission.NAME)
	return v103_.rewardPerFruitHa[self.fruitTypeIndex] or v103_.rewardPerHa
end

-- Local values: data, fruitType, fillTypeIndex, litersHarvested, _, vehicle, index, _, fillType, level, diff, _, pricePerLiter, farmReimbursement
function HarvestMission:getStealingCosts()
	if self.finishState ~= MissionFinishState.SUCCESS and self.isServer then
		local v105_ = g_missionManager:getMissionTypeDataByName(HarvestMission.NAME)
		local v106_ = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex).fillType.index
		local v107_ = self.expectedLiters * self:getFieldCompletion()
		for _, v108_ in pairs(self.vehicles) do
			if v108_.spec_fillUnit ~= nil then
				for v109_, _ in pairs(v108_:getFillUnits()) do
					if v108_:getFillUnitFillType(v109_) == self.fillType then
						v107_ = v107_ - v108_:getFillUnitFillLevel(v109_)
					end
				end
			end
		end
		local v110_ = v107_ - self.depositedLiters
		if v107_ * v105_.failureCostFactor < v110_ then
			local _, v111_ = HarvestMission.getSellingStationWithHighestPrice(v106_)
			return v110_ * v105_.failureCostOfTotal * v111_
		end
	end
	return 0
end

-- Local values: fieldState, fruitTypeIndex, multiplier, areaHa, areaPixel, liters
function HarvestMission:getMaxCutLiters(fieldAreaHa)
	local v114_ = self.field:getFieldState()
	local v115_ = v114_.fruitTypeIndex
	local v116_ = v114_:getHarvestScaleMultiplier()
	local v117_ = (fieldAreaHa or self.field:getAreaHa()) * v116_
	local v118_ = MathUtil.haToSqm(v117_) / g_currentMission:getFruitPixelsToSqm()
	return g_fruitTypeManager:getFruitTypeAreaLiters(v115_, v118_, false)
end

function HarvestMission:getMissionTypeName()
	return HarvestMission.NAME
end

function HarvestMission:validate(event)
	if not HarvestMission:superClass().validate(self, event) then
		return false
	end
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

function HarvestMission:onDeleteSellingStation(sellingStation)
	if sellingStation == self.sellingStation and (self.isServer and (self.status == MissionStatus.RUNNING and not g_currentMission.isExitingGame)) then
		Logging.warning("Finish harvest mission because selling station was removed")
		self:finish(MissionFinishState.FAILED)
	end
end

-- Local values: data
function HarvestMission.loadMapData(xmlFile, key, baseDirectory)
	local v_u_125_ = g_missionManager:getMissionTypeDataByName(HarvestMission.NAME)
	v_u_125_.rewardPerHa = xmlFile:getFloat(key .. "#rewardPerHa", 2500)
	v_u_125_.rewardPerFruitHa = {}
	xmlFile:iterate(key .. ".fruitType", function(_, p126_)
		-- upvalues: (copy) xmlFile, (copy) v_u_125_
		local v127_ = xmlFile:getString(p126_ .. "#name")
		local v128_ = xmlFile:getFloat(p126_ .. "#value", v_u_125_.rewardPerHa)
		local v129_ = g_fruitTypeManager:getFruitTypeIndexByName(v127_)
		if v129_ == nil then
			Logging.xmlWarning(xmlFile, "Harvestmission rewardPerHa fruitType \'%s\' is not defined for \'%s\'", v127_, p126_)
		else
			v_u_125_.rewardPerFruitHa[v129_] = v128_
		end
	end)
	v_u_125_.failureCostFactor = xmlFile:getFloat(key .. "#failureCostFactor", 0.1)
	v_u_125_.failureCostOfTotal = xmlFile:getFloat(key .. "#failureCostOfTotal", 0.95)
	return true
end
function HarvestMission.tryGenerateMission()
	if HarvestMission.canRun() then
		local v130_ = g_fieldManager:getFieldForMission()
		if v130_ == nil then
			return
		end
		if v130_.currentMission ~= nil then
			return
		end
		if not HarvestMission.isAvailableForField(v130_, nil) then
			return
		end
		local v131_ = v130_:getFieldState().fruitTypeIndex
		local v132_ = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(v131_)
		local v133_, _ = HarvestMission.getSellingStationWithHighestPrice(v132_)
		if not HarvestMission.isAvailableForSellingStation(v133_) then
			return
		end
		local v134_ = HarvestMission.new(true, g_client ~= nil)
		if v134_:init(v130_, v131_, v133_) then
			v134_:setDefaultEndDate()
			return v134_
		end
		v134_:delete()
	end
	return nil
end

-- Local values: highestPrice, sellingStation, _, unloadingStation, price
function HarvestMission.getSellingStationWithHighestPrice(fillTypeIndex)
	local v136_ = 0
	local v137_ = nil
	for _, v138_ in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
		if v138_.owningPlaceable ~= nil and (v138_.isSellingPoint and (v138_.allowMissions and v138_.acceptedFillTypes[fillTypeIndex])) then
			local v139_ = v138_:getEffectiveFillTypePrice(fillTypeIndex)
			if v136_ < v139_ then
				v137_ = v138_
				v136_ = v139_
			end
		end
	end
	return v137_, v136_
end

function HarvestMission.isAvailableForSellingStation(sellingStation)
	return sellingStation ~= nil
end

-- Local values: fieldState, fruitTypeIndex, fruitTypeDesc, growthState
function HarvestMission.isAvailableForField(field, mission)
	if mission == nil then
		local v143_ = field:getFieldState()
		if not v143_.isValid then
			return false
		end
		local v144_ = v143_.fruitTypeIndex
		if v144_ == FruitType.UNKNOWN then
			return false
		end
		local v145_ = g_fruitTypeManager:getFruitTypeByIndex(v144_)
		if v145_:getIsCatchCrop() then
			return false
		end
		if not v145_:getIsHarvestReady(v143_.growthState) then
			return false
		end
	end
	return true
end
function HarvestMission.canRun()
	local v146_ = g_missionManager:getMissionTypeDataByName(HarvestMission.NAME)
	if v146_.numInstances >= v146_.maxNumInstances then
		return false
	else
		return not g_currentMission.growthSystem:getIsGrowingInProgress()
	end
end
g_missionManager:registerMissionType(HarvestMission, HarvestMission.NAME, 10)
