-- Local values: PlowMission_mt
PlowMission = {}
PlowMission.NAME = "plowMission"
local PlowMission_mt = Class(PlowMission, AbstractFieldMission)
InitStaticObjectClass(PlowMission, "PlowMission")

function PlowMission.registerXMLPaths(schema, key)
	PlowMission:superClass().registerXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#rewardPerHa", "Reward per ha")
end

-- Upvalues: PlowMission_mt
-- Local values: title, description, self
function PlowMission.new(isServer, isClient, customMt)
	-- upvalues: (copy) PlowMission_mt
	local v7_ = g_i18n:getText("contract_field_plow_title")
	local v8_ = g_i18n:getText("contract_field_plow_description")
	local v9_ = AbstractFieldMission.new(isServer, isClient, v7_, v8_, customMt or PlowMission_mt)
	v9_.workAreaTypes = {
		[WorkAreaType.PLOW] = true
	}
	return v9_
end

-- Local values: mission, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, plowValue
function PlowMission:createModifier()
	local v11_, v12_, v13_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
	local v14_ = FieldGroundType.getValueByType(FieldGroundType.PLOWED)
	self.completionModifier = DensityMapModifier.new(v11_, v12_, v13_, g_terrainNode)
	self.completionFilter = DensityMapFilter.new(self.completionModifier)
	self.completionFilter:setValueCompareParams(DensityValueCompareType.EQUAL, v14_)
end

-- Local values: fieldState
function PlowMission:getFieldFinishTask()
	local v16_ = self.field:getFieldState()
	v16_.fruitTypeIndex = FruitType.UNKNOWN
	v16_.groundType = FieldGroundType.PLOWED
	return PlowMission:superClass().getFieldFinishTask(self)
end

-- Local values: data
function PlowMission:getRewardPerHa()
	return g_missionManager:getMissionTypeDataByName(PlowMission.NAME).rewardPerHa
end

function PlowMission:getMissionTypeName()
	return PlowMission.NAME
end

function PlowMission:validate(event)
	if PlowMission:superClass().validate(self, event) then
		return (self:getIsFinished() or PlowMission.isAvailableForField(self.field, self)) and true or false
	else
		return false
	end
end

-- Local values: data
function PlowMission.loadMapData(xmlFile, key, baseDirectory)
	g_missionManager:getMissionTypeDataByName(PlowMission.NAME).rewardPerHa = xmlFile:getFloat(key .. "#rewardPerHa", 2800)
	return true
end
function PlowMission.tryGenerateMission()
	if PlowMission.canRun() then
		local v21_ = g_fieldManager:getFieldForMission()
		if v21_ == nil then
			return
		end
		if v21_.currentMission ~= nil then
			return
		end
		if not PlowMission.isAvailableForField(v21_, nil) then
			return
		end
		local v22_ = PlowMission.new(true, g_client ~= nil)
		if v22_:init(v21_) then
			v22_:setDefaultEndDate()
			return v22_
		end
		v22_:delete()
	end
	return nil
end

-- Local values: fieldState, maxLevel, fruitTypeIndex, growthState, fruitTypeDesc
function PlowMission.isAvailableForField(field, mission)
	if mission == nil then
		local v25_ = field:getFieldState()
		if not v25_.isValid then
			return false
		end
		if field.grassMissionOnly then
			return false
		end
		if g_currentMission.fieldGroundSystem:getMaxValue(FieldDensityMap.PLOW_LEVEL) <= v25_.plowLevel then
			return false
		end
		local v26_ = v25_.fruitTypeIndex
		if v26_ == FruitType.UNKNOWN then
			return false
		end
		local v27_ = v25_.growthState
		local v28_ = g_fruitTypeManager:getFruitTypeByIndex(v26_)
		if v28_:getIsCatchCrop() and v27_ <= 1 then
			return false
		end
		if not (v28_:getIsCut(v27_) or v28_:getIsWithered(v27_)) then
			return false
		end
	end
	return true
end
function PlowMission.canRun()
	local v29_ = g_missionManager:getMissionTypeDataByName(PlowMission.NAME)
	return v29_.numInstances < v29_.maxNumInstances
end
g_missionManager:registerMissionType(PlowMission, PlowMission.NAME, 2)
