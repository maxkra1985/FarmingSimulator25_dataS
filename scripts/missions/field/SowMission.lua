-- Local values: SowMission_mt
SowMission = {}
SowMission.NAME = "sowMission"
local SowMission_mt = Class(SowMission, AbstractFieldMission)
InitStaticObjectClass(SowMission, "SowMission")

function SowMission.registerXMLPaths(schema, key)
	SowMission:superClass().registerXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#rewardPerHa", "Reward per ha")
end

function SowMission.registerSavegameXMLPaths(schema, key)
	SowMission:superClass().registerSavegameXMLPaths(schema, key)
	schema:register(XMLValueType.STRING, key .. "#fruitType", "Name of the fruit type")
end

-- Upvalues: SowMission_mt
-- Local values: title, description, self
function SowMission.new(isServer, isClient, customMt)
	-- upvalues: (copy) SowMission_mt
	local v9_ = g_i18n:getText("contract_field_sow_title")
	local v10_ = g_i18n:getText("contract_field_sow_description")
	local v11_ = AbstractFieldMission.new(isServer, isClient, v9_, v10_, customMt or SowMission_mt)
	v11_.workAreaTypes = {
		[WorkAreaType.SOWINGMACHINE] = true,
		[WorkAreaType.RIDGEMARKER] = true
	}
	v11_.fruitTypeIndex = nil
	v11_.fruitTypeTitle = nil
	v11_.growthState = 1
	return v11_
end

function SowMission:init(field, fruitTypeIndex)
	self.fruitTypeIndex = fruitTypeIndex
	self.fruitTypeTitle = g_fruitTypeManager:getFillTypeByFruitTypeIndex(fruitTypeIndex).title
	return SowMission:superClass().init(self, field)
end

-- Local values: fruitTypeName
function SowMission:saveToXMLFile(xmlFile, key)
	SowMission:superClass().saveToXMLFile(self, xmlFile, key)
	local v18_ = g_fruitTypeManager:getFruitTypeNameByIndex(self.fruitTypeIndex)
	xmlFile:setValue(key .. "#fruitType", v18_)
end

-- Local values: fruitTypeName
function SowMission:loadFromXMLFile(xmlFile, key)
	local v22_ = xmlFile:getValue(key .. "#fruitType")
	self.fruitTypeIndex = g_fruitTypeManager:getFruitTypeIndexByName(v22_)
	return SowMission:superClass().loadFromXMLFile(self, xmlFile, key)
end

function SowMission:writeStream(streamId, connection)
	SowMission:superClass().writeStream(self, streamId, connection)
	streamWriteUIntN(streamId, self.fruitTypeIndex or 0, FruitTypeManager.SEND_NUM_BITS)
end

function SowMission:readStream(streamId, connection)
	SowMission:superClass().readStream(self, streamId, connection)
	self.fruitTypeIndex = streamReadUIntN(streamId, FruitTypeManager.SEND_NUM_BITS)
end

-- Local values: fieldState
function SowMission:getFieldFinishTask()
	local v30_ = self.field:getFieldState()
	v30_.fruitTypeIndex = self.fruitTypeIndex
	v30_.growthState = self.growthState
	v30_.groundType = FieldGroundType.SOWN
	return SowMission:superClass().getFieldFinishTask(self)
end

-- Local values: fruitTypeIndex
function SowMission:getVehicleVariant()
	local v32_ = self.fruitTypeIndex
	if v32_ ~= nil then
		if v32_ == FruitType.SUNFLOWER or (v32_ == FruitType.MAIZE or (v32_ == FruitType.SOYBEAN or (v32_ == FruitType.SORGHUM or v32_ == FruitType.GREENBEAN))) then
			return "MAIZE"
		end
		if v32_ == FruitType.SUGARBEET then
			return "SUGARBEET"
		end
		if v32_ == FruitType.POTATO then
			return "POTATO"
		end
		if v32_ == FruitType.COTTON then
			return "COTTON"
		end
		if v32_ == FruitType.SUGARCANE then
			return "SUGARCANE"
		end
		if v32_ == FruitType.CARROT or (v32_ == FruitType.PARSNIP or v32_ == FruitType.BEETROOT) then
			return "VEGETABLES"
		end
		if v32_ == FruitType.ONION then
			return "ONION"
		end
	end
	return "GRAIN"
end

-- Local values: fruitTypeIndex
function SowMission:getVariant()
	local v34_ = self.fruitTypeIndex
	if v34_ ~= nil then
		if v34_ == FruitType.BEETROOT then
			return "BEETROOT"
		end
		if v34_ == FruitType.CARROT then
			return "CARROT"
		end
		if v34_ == FruitType.MAIZE then
			return "MAIZE"
		end
		if v34_ == FruitType.COTTON then
			return "COTTON"
		end
		if v34_ == FruitType.GREENBEAN then
			return "GREENBEAN"
		end
		if v34_ == FruitType.PARSNIP then
			return "PARSNIP"
		end
		if v34_ == FruitType.PEA then
			return "PEA"
		end
		if v34_ == FruitType.POPLAR then
			return "POPLAR"
		end
		if v34_ == FruitType.POTATO then
			return "POTATO"
		end
		if v34_ == FruitType.RICE then
			return "RICE"
		end
		if v34_ == FruitType.RICELONGGRAIN then
			return "RICELONGGRAIN"
		end
		if v34_ == FruitType.SPINACH then
			return "SPINACH"
		end
		if v34_ == FruitType.SUGARCANE then
			return "SUGARCANE"
		end
		if v34_ == FruitType.SUGARBEET then
			return "SUGARBEET"
		end
		if v34_ == FruitType.SUNFLOWER then
			return "SUNFLOWER"
		end
		if v34_ == FruitType.ONION then
			return "ONION"
		end
	end
	return "GRAIN"
end

-- Local values: fruitDesc
function SowMission:createModifier()
	local v36_ = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
	if v36_ ~= nil and v36_.terrainDataPlaneId ~= nil then
		self.completionModifier = DensityMapModifier.new(v36_.terrainDataPlaneId, v36_.startStateChannel, v36_.numStateChannels, g_terrainNode)
		self.completionFilter = DensityMapFilter.new(self.completionModifier)
		self.completionFilter:setValueCompareParams(DensityValueCompareType.EQUAL, self.growthState)
	end
end

-- Local values: sumPixels, area, totalArea
function SowMission:getPartitionCompletion(partitionIndex)
	self:setPartitionRegion(partitionIndex)
	if self.completionModifier == nil then
		return 0, 0, 0
	end
	local v39_, v40_, v41_ = self.completionModifier:executeGet(self.completionFilter)
	return v39_, v40_, v41_
end

-- Local values: data
function SowMission:getRewardPerHa()
	return g_missionManager:getMissionTypeDataByName(SowMission.NAME).rewardPerHa
end

-- Local values: totalWorth, _, vehicle, fillUnitIndex, _, fillType, level, fillDesc, fruitDesc, reimbursementPerHa
function SowMission:calculateReimbursement()
	SowMission:superClass().calculateReimbursement(self)
	local v43_ = 0
	for _, v44_ in pairs(self.vehicles) do
		if v44_.spec_fillUnit ~= nil then
			for v45_, _ in pairs(v44_:getFillUnits()) do
				local v46_ = v44_:getFillUnitFillType(v45_)
				if v46_ == FillType.SEEDS then
					v43_ = v43_ + v44_:getFillUnitFillLevel(v45_) * g_fillTypeManager:getFillTypeByIndex(v46_).pricePerLiter
				end
			end
		end
	end
	local v47_ = v43_ + g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex).seedUsagePerSqm * 10000 * g_currentMission.economyManager:getCostPerLiter(FillType.SEEDS) * self.field.areaHa
	self.reimbursement = self.reimbursement + v47_ * AbstractMission.REIMBURSEMENT_FACTOR
end

-- Local values: details, fruitDesc
function SowMission:getDetails()
	local v49_ = SowMission:superClass().getDetails(self)
	local v50_ = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
	local v51_ = {
		["title"] = g_i18n:getText("contract_details_sow_crop"),
		["value"] = v50_.fillType.title
	}
	table.insert(v49_, v51_)
	return v49_
end

function SowMission:getMissionTypeName()
	return SowMission.NAME
end

-- Local values: fruitTypeDesc
function SowMission:validate(event)
	if not self:getWasStarted() then
		local v54_ = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
		if v54_ == nil or not v54_:getIsPlantableInPeriod(g_currentMission.missionInfo.growthMode, g_currentMission.environment.currentPeriod) then
			return false
		end
	end
	if SowMission:superClass().validate(self, event) then
		return (self:getIsFinished() or SowMission.isAvailableForField(self.field, self)) and true or false
	else
		return false
	end
end

-- Local values: data
function SowMission.loadMapData(xmlFile, key, baseDirectory)
	g_missionManager:getMissionTypeDataByName(SowMission.NAME).rewardPerHa = xmlFile:getFloat(key .. "#rewardPerHa", 2000)
	return true
end
function SowMission.tryGenerateMission()
	if SowMission.canRun() then
		local v57_ = g_fieldManager:getFieldForMission()
		if v57_ == nil then
			return
		end
		if v57_.currentMission ~= nil then
			return
		end
		if not SowMission.isAvailableForField(v57_, nil) then
			return
		end
		local v58_ = v57_:getPlannedFruitTypeIndex()
		local v59_ = SowMission.new(true, g_client ~= nil)
		if v59_:init(v57_, v58_) then
			v59_:setDefaultEndDate()
			return v59_
		end
		v59_:delete()
	end
	return nil
end

-- Local values: fieldState, fruitTypeIndex, plannedFruitTypeIndex, fruitTypeDesc
function SowMission.isAvailableForField(field, mission)
	local v62_ = field:getFieldState()
	if not v62_.isValid then
		return false
	end
	if v62_.fruitTypeIndex ~= FruitType.UNKNOWN then
		return false
	end
	if mission == nil then
		local v63_ = field:getPlannedFruitTypeIndex()
		if v63_ == 0 then
			return
		end
		if not g_fruitTypeManager:getFruitTypeByIndex(v63_):getIsPlantableInPeriod(g_currentMission.missionInfo.growthMode, g_currentMission.environment.currentPeriod) then
			return false
		end
	end
	return true
end
function SowMission.canRun()
	local v64_ = g_missionManager:getMissionTypeDataByName(SowMission.NAME)
	return v64_.numInstances < v64_.maxNumInstances
end
g_missionManager:registerMissionType(SowMission, SowMission.NAME, 5)
