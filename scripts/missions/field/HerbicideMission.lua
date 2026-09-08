-- Local values: HerbicideMission_mt
HerbicideMission = {}
HerbicideMission.NAME = "herbicideMission"
local HerbicideMission_mt = Class(HerbicideMission, AbstractFieldMission)
InitStaticObjectClass(HerbicideMission, "HerbicideMission")

function HerbicideMission.registerXMLPaths(schema, key)
	HerbicideMission:superClass().registerXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#rewardPerHa", "Reward per ha")
end

function HerbicideMission.registerSavegameXMLPaths(schema, key)
	HerbicideMission:superClass().registerSavegameXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#targetWeedState", "Target weed state")
end

-- Upvalues: HerbicideMission_mt
-- Local values: title, description, self
function HerbicideMission.new(isServer, isClient, customMt)
	-- upvalues: (copy) HerbicideMission_mt
	local v9_ = g_i18n:getText("contract_field_herbicide_title")
	local v10_ = g_i18n:getText("contract_field_herbicide_description")
	local v11_ = AbstractFieldMission.new(isServer, isClient, v9_, v10_, customMt or HerbicideMission_mt)
	v11_.workAreaTypes = {
		[WorkAreaType.SPRAYER] = true
	}
	v11_.fillTypeTitle = g_fillTypeManager:getFillTypeTitleByIndex(FillType.HERBICIDE)
	return v11_
end

function HerbicideMission:init(field, targetWeedState)
	self.targetWeedState = targetWeedState
	return HerbicideMission:superClass().init(self, field)
end

function HerbicideMission:saveToXMLFile(xmlFile, key)
	HerbicideMission:superClass().saveToXMLFile(self, xmlFile, key)
	xmlFile:setValue(key .. "#targetWeedState", self.targetWeedState)
end

function HerbicideMission:loadFromXMLFile(xmlFile, key)
	self.targetWeedState = xmlFile:getValue(key .. "#targetWeedState", self.targetWeedState)
	return HerbicideMission:superClass().loadFromXMLFile(self, xmlFile, key)
end

-- Local values: mission, weedMapId, weedFirstChannel, weedNumChannels, modifier, filter
function HerbicideMission:createModifier()
	local v22_, v23_, v24_ = g_currentMission.weedSystem:getDensityMapData()
	local v25_ = DensityMapModifier.new(v22_, v23_, v24_, g_terrainNode)
	local v26_ = DensityMapFilter.new(v25_)
	v26_:setValueCompareParams(DensityValueCompareType.EQUAL, self.targetWeedState)
	self.completionModifier = DensityMapMultiModifier.new()
	self.completionModifier:addExecuteGet("targetState", v25_, v26_)
	v26_:setValueCompareParams(DensityValueCompareType.GREATER, 0)
	self.completionModifier:addExecuteGet("totalArea", v25_, v26_)
	self.matchingPixels = {}
end

-- Local values: area, totalArea
function HerbicideMission:getPartitionCompletion(partitionIndex)
	self:setPartitionRegion(partitionIndex)
	if self.completionModifier == nil then
		return 0, 0, 0
	end
	self.completionModifier:resetStats()
	self.completionModifier:execute(nil, self.matchingPixels, nil)
	return 0, self.matchingPixels.targetState, self.matchingPixels.totalArea
end

-- Local values: fieldState
function HerbicideMission:getFieldFinishTask()
	self.field:getFieldState().weedState = self.targetWeedState
	return HerbicideMission:superClass().getFieldFinishTask(self)
end

-- Local values: totalWorth, _, vehicle, fillUnitIndex, _, fillType, level, fillDesc
function HerbicideMission:calculateReimbursement()
	HerbicideMission:superClass().calculateReimbursement(self)
	local v31_ = 0
	for _, v32_ in pairs(self.vehicles) do
		if v32_.spec_fillUnit ~= nil then
			for v33_, _ in pairs(v32_:getFillUnits()) do
				local v34_ = v32_:getFillUnitFillType(v33_)
				if v34_ == FillType.HERBICIDE then
					v31_ = v31_ + v32_:getFillUnitFillLevel(v33_) * g_fillTypeManager:getFillTypeByIndex(v34_).pricePerLiter
				end
			end
		end
	end
	self.reimbursement = self.reimbursement + v31_ * AbstractMission.REIMBURSEMENT_FACTOR
end

-- Local values: data
function HerbicideMission:getRewardPerHa()
	return g_missionManager:getMissionTypeDataByName(HerbicideMission.NAME).rewardPerHa
end

function HerbicideMission:getMissionTypeName()
	return HerbicideMission.NAME
end

function HerbicideMission:validate(event)
	if HerbicideMission:superClass().validate(self, event) then
		return (self:getIsFinished() or HerbicideMission.isAvailableForField(self.field, self)) and true or false
	else
		return false
	end
end

-- Local values: data
function HerbicideMission.loadMapData(xmlFile, key, baseDirectory)
	g_missionManager:getMissionTypeDataByName(HerbicideMission.NAME).rewardPerHa = xmlFile:getFloat(key .. "#rewardPerHa", 1500)
	return true
end
function HerbicideMission.tryGenerateMission()
	if HerbicideMission.canRun() then
		local v39_ = g_fieldManager:getFieldForMission()
		if v39_ == nil then
			return
		end
		if v39_.currentMission ~= nil then
			return
		end
		if not HerbicideMission.isAvailableForField(v39_, nil) then
			return
		end
		local v40_ = v39_:getFieldState().weedState
		local v41_ = g_currentMission.weedSystem:getHerbicideReplacements().weed.replacements[v40_]
		local v42_ = HerbicideMission.new(true, g_client ~= nil)
		if v42_:init(v39_, v41_) then
			v42_:setDefaultEndDate()
			return v42_
		end
		v42_:delete()
	end
	return nil
end

-- Local values: fieldState, fruitTypeIndex, fruitTypeDesc, growthState, weedState, replacements, replacement, environment
function HerbicideMission.isAvailableForField(field, mission)
	if mission == nil then
		local v45_ = field:getFieldState()
		if not v45_.isValid then
			return false
		end
		local v46_ = v45_.fruitTypeIndex
		if v46_ == FruitType.UNKNOWN then
			return false
		end
		if v46_ == FruitType.GRASS or v46_ == FruitType.MEADOW then
			return false
		end
		local v47_ = g_fruitTypeManager:getFruitTypeByIndex(v46_)
		if v47_:getIsCatchCrop() then
			return false
		end
		if v45_.weedState == 0 then
			return false
		end
		local v48_ = v45_.growthState
		if v47_:getIsHarvestable(v48_) then
			return false
		end
		if v47_:getIsWeedable(v48_) then
			return false
		end
		if v47_:getIsHoeable(v48_) then
			return false
		end
		local v49_ = v45_.weedState
		local v50_ = g_currentMission.weedSystem:getHerbicideReplacements().weed.replacements[v49_]
		if v50_ == nil or v50_ == 0 then
			return false
		end
	end
	local v51_ = g_currentMission.environment
	return v51_ == nil or v51_.currentSeason ~= Season.WINTER
end
function HerbicideMission.canRun()
	local v52_ = g_missionManager:getMissionTypeDataByName(HerbicideMission.NAME)
	if v52_.numInstances >= v52_.maxNumInstances then
		return false
	elseif g_currentMission.growthSystem:getIsGrowingInProgress() then
		return false
	elseif g_currentMission.weedSystem:getMapHasWeed() then
		return g_currentMission.missionInfo.weedsEnabled and true or false
	else
		return false
	end
end
g_missionManager:registerMissionType(HerbicideMission, HerbicideMission.NAME, 2)
