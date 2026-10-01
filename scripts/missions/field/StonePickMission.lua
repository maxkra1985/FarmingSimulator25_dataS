StonePickMission = {}
StonePickMission.NAME = "stonePickMission"
local StonePickMission_mt = Class(StonePickMission, AbstractFieldMission)
InitStaticObjectClass(StonePickMission, "StonePickMission")
function StonePickMission.registerXMLPaths(schema, key)
	StonePickMission:superClass().registerXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#rewardPerHa", "Reward per ha")
end
function StonePickMission.new(isServer, isClient, customMt)
	local title = g_i18n:getText("contract_field_stonePick_title")
	local description = g_i18n:getText("contract_field_stonePick_description")
	local self = AbstractFieldMission.new(isServer, isClient, title, description, customMt or StonePickMission_mt)
	self.workAreaTypes = { [WorkAreaType.STONEPICKER] = true }
	self.stoneValue = 3
	self.spawnedPixels = 0
	return self
end
function StonePickMission:init(field)
	return StonePickMission:superClass().init(self, field)
end
function StonePickMission:getFieldPreparingTask()
	if self.isServer then
		local fieldState = self.field:getFieldState()
		fieldState.stoneLevel = self.stoneValue
	end
	return StonePickMission:superClass().getFieldPreparingTask(self)
end
function StonePickMission:getFieldFinishTask()
	if self.isServer then
		local fieldState = self.field:getFieldState()
		fieldState.stoneLevel = 0
		fieldState.groundType = FieldGroundType.CULTIVATED
	end
	return StonePickMission:superClass().getFieldFinishTask(self)
end
function StonePickMission:createModifier()
	local mission = g_currentMission
	local mapId, firstChannel, numChannels = mission.stoneSystem:getDensityMapData()
	local _, maxValue = g_currentMission.stoneSystem:getMinMaxValues()
	self.completionModifier = DensityMapModifier.new(mapId, firstChannel, numChannels, g_terrainNode)
	self.completionModifierUnmasked = DensityMapModifier.new(mapId, firstChannel, numChannels, g_terrainNode)
	self.completionFilter = DensityMapFilter.new(self.completionModifier)
	self.completionFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, maxValue)
	self.completionFilterMasked = DensityMapFilter.new(self.completionModifier)
	self.completionFilterMasked:setValueCompareParams(DensityValueCompareType.GREATER, 0)
	self.completionFilterUnmasked = DensityMapFilter.new(self.completionModifier)
	self.completionFilterUnmasked:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
end
function StonePickMission:getPartitionCompletion(partitionIndex)
	self:setPartitionRegion(partitionIndex)
	if self.completionModifier ~= nil then
		local sumPixels, area, totalArea = self.completionModifier:executeGet(self.completionFilter, self.completionFilterMasked)
		local _, unmaskedArea, _ = self.completionModifierUnmasked:executeGet(self.completionFilterUnmasked)
		totalArea = totalArea - unmaskedArea
		return sumPixels, area, totalArea
	else
		return 0, 0, 0
	end
end
function StonePickMission:initializeModifier()
	StonePickMission:superClass().initializeModifier(self)
	if self.completionModifierUnmasked ~= nil then
		local densityMapPolygon = self.field:getDensityMapPolygon()
		densityMapPolygon:applyToModifier(self.completionModifierUnmasked)
	end
end
function StonePickMission:setPartitionRegion(partitionIndex)
	StonePickMission:superClass().setPartitionRegion(self, partitionIndex)
	if #self.completionPartitions == 1 then
		return
	else
		if self.completionModifierUnmasked ~= nil then
			local partition = self.completionPartitions[partitionIndex]
			self.completionModifierUnmasked:setPolygonClipRegion(partition.minZ, partition.maxZ)
		end
	end
end
function StonePickMission:getRewardPerHa()
	local data = g_missionManager:getMissionTypeDataByName(StonePickMission.NAME)
	return data.rewardPerHa
end
function StonePickMission:getMissionTypeName()
	return StonePickMission.NAME
end
function StonePickMission:validate(event)
	if not StonePickMission:superClass().validate(self, event) then
		return false
	elseif not self:getIsFinished() and not StonePickMission.isAvailableForField(self.field, self) then
		return false
	else
		return true
	end
end
function StonePickMission.loadMapData(xmlFile, key, baseDirectory)
	local data = g_missionManager:getMissionTypeDataByName(StonePickMission.NAME)
	data.rewardPerHa = xmlFile:getFloat(key .. "#rewardPerHa", 2200)
	return true
end
function StonePickMission.tryGenerateMission()
	if StonePickMission.canRun() then
		local field = g_fieldManager:getFieldForMission()
		if field == nil then
			return
		end
		if field.currentMission ~= nil then
			return
		end
		if not StonePickMission.isAvailableForField(field, nil) then
			return
		end
		local mission = StonePickMission.new(true, g_client ~= nil)
		if mission:init(field) then
			mission:setDefaultEndDate()
			return mission
		end
		mission:delete()
	end
	return nil
end
function StonePickMission.isAvailableForField(field, mission)
	if mission == nil then
		local fieldState = field:getFieldState()
		if not fieldState.isValid then
			return false
		end
		local fruitTypeIndex = fieldState.fruitTypeIndex
		if fruitTypeIndex ~= FruitType.UNKNOWN then
			return false
		end
		local groundType = fieldState.groundType
		if groundType ~= FieldGroundType.PLOWED then
			return false
		end
	end
	local environment = g_currentMission.environment
	if environment ~= nil and environment.currentSeason == Season.WINTER then
		return false
	end
	return true
end
function StonePickMission.canRun()
	local data = g_missionManager:getMissionTypeDataByName(StonePickMission.NAME)
	if data.maxNumInstances <= data.numInstances then
		return false
	else
		return true
	end
end
g_missionManager:registerMissionType(StonePickMission, StonePickMission.NAME, 1)
