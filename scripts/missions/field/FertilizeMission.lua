-- Local values: FertilizeMission_mt
FertilizeMission = {}
FertilizeMission.NAME = "fertilizeMission"
local FertilizeMission_mt = Class(FertilizeMission, AbstractFieldMission)
InitStaticObjectClass(FertilizeMission, "FertilizeMission")

function FertilizeMission.registerXMLPaths(schema, key)
	FertilizeMission:superClass().registerXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#rewardPerHa", "Reward per ha")
end

function FertilizeMission.registerSavegameXMLPaths(schema, key)
	FertilizeMission:superClass().registerSavegameXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#targetSprayLevel", "Target spray level")
end

-- Upvalues: FertilizeMission_mt
-- Local values: title, description, self
function FertilizeMission.new(isServer, isClient, customMt)
	-- upvalues: (copy) FertilizeMission_mt
	local v9_ = g_i18n:getText("contract_field_fertilize_title")
	local v10_ = g_i18n:getText("contract_field_fertilize_description")
	local v11_ = AbstractFieldMission.new(isServer, isClient, v9_, v10_, customMt or FertilizeMission_mt)
	v11_.workAreaTypes = {
		[WorkAreaType.SPRAYER] = true
	}
	v11_.validFertilizerFillTypes = {}
	v11_.validFertilizerFillTypes[FillType.FERTILIZER] = true
	v11_.validFertilizerFillTypes[FillType.LIQUIDFERTILIZER] = true
	v11_.validFertilizerFillTypes[FillType.LIQUIDMANURE] = true
	v11_.validFertilizerFillTypes[FillType.MANURE] = true
	v11_.filLTypeTitle = g_fillTypeManager:getFillTypeTitleByIndex(FillType.FERTILIZER)
	v11_.targetSprayLevel = nil
	return v11_
end

function FertilizeMission:init(field, targetSprayLevel)
	self.targetSprayLevel = targetSprayLevel
	return FertilizeMission:superClass().init(self, field)
end

function FertilizeMission:saveToXMLFile(xmlFile, key)
	FertilizeMission:superClass().saveToXMLFile(self, xmlFile, key)
	xmlFile:setValue(key .. "#targetSprayLevel", self.targetSprayLevel)
end

function FertilizeMission:loadFromXMLFile(xmlFile, key)
	if not FertilizeMission:superClass().loadFromXMLFile(self, xmlFile, key) then
		return false
	end
	self.targetSprayLevel = xmlFile:getValue(key .. "#targetSprayLevel")
	return true
end

-- Local values: mission, sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels
function FertilizeMission:createModifier()
	local v22_, v23_, v24_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
	self.completionModifier = DensityMapModifier.new(v22_, v23_, v24_, g_terrainNode)
	self.completionFilter = DensityMapFilter.new(self.completionModifier)
	self.completionFilter:setValueCompareParams(DensityValueCompareType.EQUAL, self.targetSprayLevel)
end

-- Local values: fieldState
function FertilizeMission:getFieldFinishTask()
	self.field:getFieldState().sprayLevel = self.targetSprayLevel
	return FertilizeMission:superClass().getFieldFinishTask(self)
end

-- Local values: data
function FertilizeMission:getRewardPerHa()
	return g_missionManager:getMissionTypeDataByName(FertilizeMission.NAME).rewardPerHa
end

-- Local values: totalWorth, _, vehicle, fillUnitIndex, _, fillType, level, fillDesc
function FertilizeMission:calculateReimbursement()
	FertilizeMission:superClass().calculateReimbursement(self)
	local v27_ = 0
	for _, v28_ in pairs(self.vehicles) do
		if v28_.spec_fillUnit ~= nil then
			for v29_, _ in pairs(v28_:getFillUnits()) do
				local v30_ = v28_:getFillUnitFillType(v29_)
				if self.validFertilizerFillTypes[v30_] ~= nil then
					v27_ = v27_ + v28_:getFillUnitFillLevel(v29_) * g_fillTypeManager:getFillTypeByIndex(v30_).pricePerLiter
				end
			end
		end
	end
	self.reimbursement = self.reimbursement + v27_ * AbstractMission.REIMBURSEMENT_FACTOR
end

function FertilizeMission:getMissionTypeName()
	return FertilizeMission.NAME
end

function FertilizeMission:validate(event)
	if FertilizeMission:superClass().validate(self, event) then
		return (self:getIsFinished() or FertilizeMission.isAvailableForField(self.field, self)) and true or false
	else
		return false
	end
end

-- Local values: data
function FertilizeMission.loadMapData(xmlFile, key, baseDirectory)
	g_missionManager:getMissionTypeDataByName(FertilizeMission.NAME).rewardPerHa = xmlFile:getFloat(key .. "#rewardPerHa", 1500)
	return true
end
function FertilizeMission.tryGenerateMission()
	if FertilizeMission.canRun() then
		local v35_ = g_fieldManager:getFieldForMission()
		if v35_ == nil then
			return
		end
		if v35_.currentMission ~= nil then
			return
		end
		if not FertilizeMission.isAvailableForField(v35_, nil) then
			return
		end
		local v36_ = v35_:getFieldState().sprayLevel + 1
		local v37_ = FertilizeMission.new(true, g_client ~= nil)
		if v37_:init(v35_, v36_) then
			v37_:setDefaultEndDate()
			return v37_
		end
		v37_:delete()
	end
	return nil
end

-- Local values: fieldState, sprayType, fruitTypeIndex, maxLevel, growthState, fruitType, environment
function FertilizeMission.isAvailableForField(field, mission)
	if mission == nil then
		local v40_ = field:getFieldState()
		if not v40_.isValid then
			return false
		end
		if v40_.sprayType ~= FieldSprayType.NONE then
			return false
		end
		local v41_ = v40_.fruitTypeIndex
		if v41_ == FruitType.UNKNOWN then
			return false
		end
		if g_currentMission.fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL) <= v40_.sprayLevel then
			return false
		end
		local v42_ = v40_.growthState
		if v42_ ~= nil and v42_ <= 1 then
			return false
		end
		local v43_ = g_fruitTypeManager:getFruitTypeByIndex(v41_)
		if v43_:getIsCatchCrop() then
			return false
		end
		if v43_:getIsHarvestable(v42_) then
			return false
		end
	end
	local v44_ = g_currentMission.environment
	return v44_ == nil or v44_.currentSeason ~= Season.WINTER
end
function FertilizeMission.canRun()
	local v45_ = g_missionManager:getMissionTypeDataByName(FertilizeMission.NAME)
	if v45_.numInstances >= v45_.maxNumInstances then
		return false
	else
		return not g_currentMission.growthSystem:getIsGrowingInProgress()
	end
end
g_missionManager:registerMissionType(FertilizeMission, FertilizeMission.NAME, 3)
