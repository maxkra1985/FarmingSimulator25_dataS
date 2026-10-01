HoeMission = {}
HoeMission.NAME = "hoeMission"
local HoeMission_mt = Class(HoeMission, AbstractFieldMission)
InitStaticObjectClass(HoeMission, "HoeMission")
function HoeMission.registerXMLPaths(schema, key)
	HoeMission:superClass().registerXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#rewardPerHa", "Reward per ha")
end
function HoeMission.registerSavegameXMLPaths(schema, key)
	HoeMission:superClass().registerSavegameXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#totalWeedArea", "Total weed area on start")
end
function HoeMission.new(isServer, isClient, customMt)
	local title = g_i18n:getText("contract_field_hoe_title")
	local description = g_i18n:getText("contract_field_hoe_description")
	local self = AbstractFieldMission.new(isServer, isClient, title, description, customMt or HoeMission_mt)
	self.workAreaTypes = { [WorkAreaType.WEEDER] = true }
	self.totalWeedArea = nil
	return self
end
function HoeMission:saveToXMLFile(xmlFile, key)
	HoeMission:superClass().saveToXMLFile(self, xmlFile, key)
	if self.totalWeedArea ~= nil then
		xmlFile:setInt(key .. "#totalWeedArea", self.totalWeedArea)
	end
end
function HoeMission:loadFromXMLFile(xmlFile, key)
	local targetWeedState = xmlFile:getInt(key .. "#targetWeedState")
	if targetWeedState ~= nil then
		return false
	else
		self.totalWeedArea = xmlFile:getInt(key .. "#totalWeedArea", self.totalWeedArea)
		if self.totalWeedArea == nil or self.totalWeedArea == 0 then
			return false
		end
		return HoeMission:superClass().loadFromXMLFile(self, xmlFile, key)
	end
end
function HoeMission:createModifier()
	local mission = g_currentMission
	local weedMapId, weedFirstChannel, weedNumChannels = mission.weedSystem:getDensityMapData()
	self.completionModifier = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, g_terrainNode)
	self.completionFilter = DensityMapFilter.new(self.completionModifier)
	self.completionFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
end
function HoeMission:finishedPreparing()
	HoeMission:superClass().finishedPreparing(self)
	local densityMapPolygon = self.field:getDensityMapPolygon()
	densityMapPolygon:applyToModifier(self.completionModifier)
	local _, area, _ = self.completionModifier:executeGet(self.completionFilter)
	self.totalWeedArea = area
	if self.totalWeedArea == 0 then
		self:finish(MissionFinishState.FAILED)
	end
end
function HoeMission:updateFieldPercentageDone(totalArea)
	local areaDone = 0
	local allCalculated = true
	for _, partition in ipairs(self.completionPartitions) do
		if not partition.wasCalculated then
			allCalculated = false
		end
		if 0 < totalArea then
			areaDone = areaDone + partition.area
		else
			areaDone = areaDone + partition.totalArea
		end
	end
	if allCalculated then
		self.fieldPercentageDone = 1 - areaDone / self.totalWeedArea
	end
end
function HoeMission:getFieldFinishTask()
	local fieldState = self.field:getFieldState()
	fieldState.weedState = 0
	return HoeMission:superClass().getFieldFinishTask(self)
end
function HoeMission:getRewardPerHa()
	local data = g_missionManager:getMissionTypeDataByName(HoeMission.NAME)
	return data.rewardPerHa
end
function HoeMission:getMissionTypeName()
	return HoeMission.NAME
end
function HoeMission:validate(event)
	if not HoeMission:superClass().validate(self, event) then
		return false
	elseif not self:getIsFinished() and not HoeMission.isAvailableForField(self.field, self) then
		return false
	else
		return true
	end
end
function HoeMission.loadMapData(xmlFile, key, baseDirectory)
	local data = g_missionManager:getMissionTypeDataByName(HoeMission.NAME)
	data.rewardPerHa = xmlFile:getFloat(key .. "#rewardPerHa", 1500)
	return true
end
function HoeMission.tryGenerateMission()
	if HoeMission.canRun() then
		local field = g_fieldManager:getFieldForMission()
		if field == nil then
			return
		end
		if field.currentMission ~= nil then
			return
		end
		if not HoeMission.isAvailableForField(field, nil) then
			return
		end
		local mission = HoeMission.new(true, g_client ~= nil)
		if mission:init(field) then
			mission:setDefaultEndDate()
			return mission
		end
		mission:delete()
	end
	return nil
end
function HoeMission.isAvailableForField(field, mission)
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
		if fieldState.weedState == 0 then
			return false
		end
		if not fruitTypeDesc:getIsHoeable(fieldState.growthState) then
			return false
		end
		local weedSystem = g_currentMission.weedSystem
		local hoedState = weedSystem:getHoedState(fieldState.weedState)
		if hoedState ~= 0 then
			return false
		end
	end
	local environment = g_currentMission.environment
	if environment ~= nil and environment.currentSeason == Season.WINTER then
		return false
	end
	return true
end
function HoeMission.canRun()
	local data = g_missionManager:getMissionTypeDataByName(HoeMission.NAME)
	if data.maxNumInstances <= data.numInstances then
		return false
	end
	if g_currentMission.growthSystem:getIsGrowingInProgress() then
		return false
	end
	local weedSystem = g_currentMission.weedSystem
	if not weedSystem:getMapHasWeed() then
		return false
	elseif not g_currentMission.missionInfo.weedsEnabled then
		return false
	else
		return true
	end
end
g_missionManager:registerMissionType(HoeMission, HoeMission.NAME, 2)
