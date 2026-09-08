-- Local values: MowMission_mt
MowMission = {}
MowMission.NAME = "mowMission"
local MowMission_mt = Class(MowMission, AbstractFieldMission)
InitStaticObjectClass(MowMission, "MowMission")

function MowMission.registerXMLPaths(schema, key)
	MowMission:superClass().registerXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#rewardPerHa", "Reward per ha")
end

function MowMission.registerSavegameXMLPaths(schema, key)
	MowMission:superClass().registerSavegameXMLPaths(schema, key)
	schema:register(XMLValueType.STRING, key .. "#fruitType", "Name of the fruit type")
end

-- Upvalues: MowMission_mt
-- Local values: title, description, self
function MowMission.new(isServer, isClient, customMt)
	-- upvalues: (copy) MowMission_mt
	local v9_ = g_i18n:getText("contract_field_mow_title")
	local v10_ = g_i18n:getText("contract_field_mow_description")
	local v11_ = AbstractFieldMission.new(isServer, isClient, v9_, v10_, customMt or MowMission_mt)
	v11_.workAreaTypes = {
		[WorkAreaType.MOWER] = true
	}
	v11_.fruitTypeIndex = nil
	return v11_
end

function MowMission:init(field, fruitTypeIndex)
	self.fruitTypeIndex = fruitTypeIndex
	self.fillTypeIndex = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(fruitTypeIndex)
	return MowMission:superClass().init(self, field)
end

-- Local values: fieldState, fruitType
function MowMission:onSavegameLoaded()
	if self.field == nil then
		Logging.error("Field is not set for mow mission")
		g_missionManager:markMissionForDeletion(self)
		return
	elseif self.field:getFieldState().fruitTypeIndex == self.fruitTypeIndex then
		MowMission:superClass().onSavegameLoaded(self)
	else
		local v16_ = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
		if v16_ == nil then
			Logging.error("FruitType \'%s\' is not defined for mow mission", self.fruitTypeIndex)
		else
			Logging.error("FruitType \'%s\' is not present on field \'%s\' for mow mission", v16_.name, self.field:getName())
		end
		g_missionManager:markMissionForDeletion(self)
	end
end

function MowMission:saveToXMLFile(xmlFile, key)
	MowMission:superClass().saveToXMLFile(self, xmlFile, key)
	xmlFile:setValue(key .. "#fruitType", g_fruitTypeManager:getFruitTypeNameByIndex(self.fruitTypeIndex))
end

-- Local values: fruitTypeName, fruitType
function MowMission:loadFromXMLFile(xmlFile, key)
	if not MowMission:superClass().loadFromXMLFile(self, xmlFile, key) then
		return false
	end
	local v23_ = xmlFile:getValue(key .. "#fruitType")
	local v24_ = g_fruitTypeManager:getFruitTypeByName(v23_)
	if v24_ == nil then
		Logging.xmlError(xmlFile, "FruitType \'%s\' not defined", v23_)
		return false
	end
	self.fruitTypeIndex = v24_.index
	self.fillTypeIndex = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(self.fruitTypeIndex)
	return true
end

-- Local values: fruitDesc
function MowMission:createModifier()
	local v26_ = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
	if v26_ ~= nil and v26_.terrainDataPlaneId ~= nil then
		self.completionModifier = DensityMapModifier.new(v26_.terrainDataPlaneId, v26_.startStateChannel, v26_.numStateChannels, g_terrainNode)
		self.completionFilter = DensityMapFilter.new(self.completionModifier)
		self.completionFilter:setValueCompareParams(DensityValueCompareType.EQUAL, v26_.cutState)
	end
end

-- Local values: fruitTypeDesc, fieldState, finishTask
function MowMission:getFieldFinishTask()
	local v28_ = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
	if v28_ ~= nil then
		local v29_ = self.field:getFieldState()
		v29_.fruitTypeIndex = self.fruitTypeIndex
		v29_.growthState = v28_.cutState
	end
	local v30_ = MowMission:superClass().getFieldFinishTask(self)
	if v30_ ~= nil then
		v30_:clearHeight()
	end
	return v30_
end

-- Local values: data
function MowMission:getRewardPerHa()
	return g_missionManager:getMissionTypeDataByName(MowMission.NAME).rewardPerHa
end

function MowMission:getMissionTypeName()
	return MowMission.NAME
end

function MowMission:validate(event)
	if MowMission:superClass().validate(self, event) then
		return (self:getIsFinished() or MowMission.isAvailableForField(self.field, self)) and true or false
	else
		return false
	end
end

-- Local values: data
function MowMission.loadMapData(xmlFile, key, baseDirectory)
	local v35_ = g_missionManager:getMissionTypeDataByName(MowMission.NAME)
	v35_.rewardPerHa = xmlFile:getFloat(key .. "#rewardPerHa", 2500)
	v35_.fruitTypeIndices = {}
	if FruitType.GRASS ~= nil then
		v35_.fruitTypeIndices[FruitType.GRASS] = true
	end
	return true
end
function MowMission.tryGenerateMission()
	if MowMission.canRun() then
		local v36_ = g_fieldManager:getFieldForMission()
		if v36_ == nil then
			return
		end
		if v36_.currentMission ~= nil then
			return
		end
		if not MowMission.isAvailableForField(v36_, nil) then
			return
		end
		local v37_ = v36_:getFieldState().fruitTypeIndex
		local v38_ = MowMission.new(true, g_client ~= nil)
		if v38_:init(v36_, v37_) then
			v38_:setDefaultEndDate()
			return v38_
		end
		v38_:delete()
	end
	return nil
end

-- Local values: fieldState, data, fruitTypeIndex, fruitTypeDesc, growthState, environment
function MowMission.isAvailableForField(field, mission)
	if mission == nil then
		local v41_ = field:getFieldState()
		if not v41_.isValid then
			return false
		end
		local v42_ = g_missionManager:getMissionTypeDataByName(MowMission.NAME)
		local v43_ = v41_.fruitTypeIndex
		if v42_.fruitTypeIndices[v43_] == nil then
			return false
		end
		if not g_fruitTypeManager:getFruitTypeByIndex(v43_):getIsHarvestable(v41_.growthState) then
			return false
		end
	end
	local v44_ = g_currentMission.environment
	if v44_ ~= nil then
		if v44_.currentSeason == Season.WINTER then
			return false
		end
		if v44_.currentPeriod == SeasonPeriod.EARLY_SPRING or v44_.currentPeriod == SeasonPeriod.MID_SPRING then
			return false
		end
	end
	return true
end
function MowMission.canRun()
	local v45_ = g_missionManager:getMissionTypeDataByName(MowMission.NAME)
	return v45_.numInstances < v45_.maxNumInstances
end
g_missionManager:registerMissionType(MowMission, MowMission.NAME, 3)
