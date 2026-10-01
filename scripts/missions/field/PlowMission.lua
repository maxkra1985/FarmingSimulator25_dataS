PlowMission = {}
PlowMission.NAME = "plowMission"
local PlowMission_mt = Class(PlowMission, AbstractFieldMission)
InitStaticObjectClass(PlowMission, "PlowMission")
function PlowMission.registerXMLPaths(schema, key)
	PlowMission:superClass().registerXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#rewardPerHa", "Reward per ha")
end
function PlowMission.new(isServer, isClient, customMt)
	local title = g_i18n:getText("contract_field_plow_title")
	local description = g_i18n:getText("contract_field_plow_description")
	local self = AbstractFieldMission.new(isServer, isClient, title, description, customMt or PlowMission_mt)
	self.workAreaTypes = { [WorkAreaType.PLOW] = true }
	return self
end
function PlowMission:createModifier()
	local mission = g_currentMission
	local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
	local plowValue = FieldGroundType.getValueByType(FieldGroundType.PLOWED)
	self.completionModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, g_terrainNode)
	self.completionFilter = DensityMapFilter.new(self.completionModifier)
	self.completionFilter:setValueCompareParams(DensityValueCompareType.EQUAL, plowValue)
end
function PlowMission:getFieldFinishTask()
	local fieldState = self.field:getFieldState()
	fieldState.fruitTypeIndex = FruitType.UNKNOWN
	fieldState.groundType = FieldGroundType.PLOWED
	return PlowMission:superClass().getFieldFinishTask(self)
end
function PlowMission:getRewardPerHa()
	local data = g_missionManager:getMissionTypeDataByName(PlowMission.NAME)
	return data.rewardPerHa
end
function PlowMission:getMissionTypeName()
	return PlowMission.NAME
end
function PlowMission:validate(event)
	if not PlowMission:superClass().validate(self, event) then
		return false
	elseif not self:getIsFinished() and not PlowMission.isAvailableForField(self.field, self) then
		return false
	else
		return true
	end
end
function PlowMission.loadMapData(xmlFile, key, baseDirectory)
	local data = g_missionManager:getMissionTypeDataByName(PlowMission.NAME)
	data.rewardPerHa = xmlFile:getFloat(key .. "#rewardPerHa", 2800)
	return true
end
function PlowMission.tryGenerateMission()
	if PlowMission.canRun() then
		local field = g_fieldManager:getFieldForMission()
		if field == nil then
			return
		end
		if field.currentMission ~= nil then
			return
		end
		if not PlowMission.isAvailableForField(field, nil) then
			return
		end
		local mission = PlowMission.new(true, g_client ~= nil)
		if mission:init(field) then
			mission:setDefaultEndDate()
			return mission
		end
		mission:delete()
	end
	return nil
end
function PlowMission.isAvailableForField(field, mission)
	if mission == nil then
		local fieldState = field:getFieldState()
		if not fieldState.isValid then
			return false
		end
		if field.grassMissionOnly then
			return false
		end
		local maxLevel = g_currentMission.fieldGroundSystem:getMaxValue(FieldDensityMap.PLOW_LEVEL)
		if maxLevel <= fieldState.plowLevel then
			return false
		end
		local fruitTypeIndex = fieldState.fruitTypeIndex
		if fruitTypeIndex == FruitType.UNKNOWN then
			return false
		end
		local growthState = fieldState.growthState
		local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
		if fruitTypeDesc:getIsCatchCrop() and growthState <= 1 then
			return false
		end
		if not fruitTypeDesc:getIsCut(growthState) and not fruitTypeDesc:getIsWithered(growthState) then
			return false
		end
	end
	return true
end
function PlowMission.canRun()
	local data = g_missionManager:getMissionTypeDataByName(PlowMission.NAME)
	if data.maxNumInstances <= data.numInstances then
		return false
	else
		return true
	end
end
g_missionManager:registerMissionType(PlowMission, PlowMission.NAME, 2)
