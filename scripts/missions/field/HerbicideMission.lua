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
function HerbicideMission.new(isServer, isClient, customMt)
	local title = g_i18n:getText("contract_field_herbicide_title")
	local description = g_i18n:getText("contract_field_herbicide_description")
	local self = AbstractFieldMission.new(isServer, isClient, title, description, customMt or HerbicideMission_mt)
	self.workAreaTypes = { [WorkAreaType.SPRAYER] = true }
	self.fillTypeTitle = g_fillTypeManager:getFillTypeTitleByIndex(FillType.HERBICIDE)
	return self
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
function HerbicideMission:createModifier()
	local mission = g_currentMission
	local weedMapId, weedFirstChannel, weedNumChannels = mission.weedSystem:getDensityMapData()
	local modifier = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, g_terrainNode)
	local filter = DensityMapFilter.new(modifier)
	filter:setValueCompareParams(DensityValueCompareType.EQUAL, self.targetWeedState)
	self.completionModifier = DensityMapMultiModifier.new()
	self.completionModifier:addExecuteGet("targetState", modifier, filter)
	filter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
	self.completionModifier:addExecuteGet("totalArea", modifier, filter)
	self.matchingPixels = {}
end
function HerbicideMission:getPartitionCompletion(partitionIndex)
	self:setPartitionRegion(partitionIndex)
	if self.completionModifier ~= nil then
		self.completionModifier:resetStats()
		self.completionModifier:execute(nil, self.matchingPixels, nil)
		local area = self.matchingPixels.targetState
		local totalArea = self.matchingPixels.totalArea
		return 0, area, totalArea
	else
		return 0, 0, 0
	end
end
function HerbicideMission:getFieldFinishTask()
	local fieldState = self.field:getFieldState()
	fieldState.weedState = self.targetWeedState
	return HerbicideMission:superClass().getFieldFinishTask(self)
end
function HerbicideMission:calculateReimbursement()
	HerbicideMission:superClass().calculateReimbursement(self)
	local totalWorth = 0
	for _, vehicle in pairs(self.vehicles) do
		if vehicle.spec_fillUnit == nil then
			continue
		end
		for fillUnitIndex, _ in pairs(vehicle:getFillUnits()) do
			local fillType = vehicle:getFillUnitFillType(fillUnitIndex)
			if fillType == FillType.HERBICIDE then
				local level = vehicle:getFillUnitFillLevel(fillUnitIndex)
				local fillDesc = g_fillTypeManager:getFillTypeByIndex(fillType)
				totalWorth = totalWorth + level * fillDesc.pricePerLiter
			end
		end
	end
	self.reimbursement = self.reimbursement + totalWorth * AbstractMission.REIMBURSEMENT_FACTOR
end
function HerbicideMission:getRewardPerHa()
	local data = g_missionManager:getMissionTypeDataByName(HerbicideMission.NAME)
	return data.rewardPerHa
end
function HerbicideMission:getMissionTypeName()
	return HerbicideMission.NAME
end
function HerbicideMission:validate(event)
	if not HerbicideMission:superClass().validate(self, event) then
		return false
	elseif not self:getIsFinished() and not HerbicideMission.isAvailableForField(self.field, self) then
		return false
	else
		return true
	end
end
function HerbicideMission.loadMapData(xmlFile, key, baseDirectory)
	local data = g_missionManager:getMissionTypeDataByName(HerbicideMission.NAME)
	data.rewardPerHa = xmlFile:getFloat(key .. "#rewardPerHa", 1500)
	return true
end
function HerbicideMission.tryGenerateMission()
	if HerbicideMission.canRun() then
		local field = g_fieldManager:getFieldForMission()
		if field == nil then
			return
		end
		if field.currentMission ~= nil then
			return
		end
		if not HerbicideMission.isAvailableForField(field, nil) then
			return
		end
		local fieldState = field:getFieldState()
		local weedState = fieldState.weedState
		local replacements = g_currentMission.weedSystem:getHerbicideReplacements().weed.replacements
		local replacement = replacements[weedState]
		local mission = HerbicideMission.new(true, g_client ~= nil)
		if mission:init(field, replacement) then
			mission:setDefaultEndDate()
			return mission
		end
		mission:delete()
	end
	return nil
end
function HerbicideMission.isAvailableForField(field, mission)
	if mission == nil then
		local fieldState = field:getFieldState()
		if not fieldState.isValid then
			return false
		end
		local fruitTypeIndex = fieldState.fruitTypeIndex
		if fruitTypeIndex == FruitType.UNKNOWN then
			return false
		end
		if fruitTypeIndex == FruitType.GRASS or fruitTypeIndex == FruitType.MEADOW then
			return false
		end
		local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
		if fruitTypeDesc:getIsCatchCrop() then
			return false
		end
		if fieldState.weedState == 0 then
			return false
		end
		local growthState = fieldState.growthState
		if fruitTypeDesc:getIsHarvestable(growthState) then
			return false
		end
		if fruitTypeDesc:getIsWeedable(growthState) then
			return false
		end
		if fruitTypeDesc:getIsHoeable(growthState) then
			return false
		end
		local weedState = fieldState.weedState
		local replacements = g_currentMission.weedSystem:getHerbicideReplacements().weed.replacements
		local replacement = replacements[weedState]
		if replacement == nil or replacement == 0 then
			return false
		end
	end
	local environment = g_currentMission.environment
	if environment ~= nil and environment.currentSeason == Season.WINTER then
		return false
	end
	return true
end
function HerbicideMission.canRun()
	local data = g_missionManager:getMissionTypeDataByName(HerbicideMission.NAME)
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
g_missionManager:registerMissionType(HerbicideMission, HerbicideMission.NAME, 2)
