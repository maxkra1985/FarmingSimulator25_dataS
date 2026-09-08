-- Local values: WeedMission_mt
WeedMission = {}
WeedMission.NAME = "weedMission"
local WeedMission_mt = Class(WeedMission, AbstractFieldMission)
InitStaticObjectClass(WeedMission, "WeedMission")

function WeedMission.registerXMLPaths(schema, key)
	WeedMission:superClass().registerXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#rewardPerHa", "Reward per ha")
end

function WeedMission.registerSavegameXMLPaths(schema, key)
	WeedMission:superClass().registerSavegameXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#totalWeedArea", "Total weed area on start")
end

-- Upvalues: WeedMission_mt
-- Local values: title, description, self
function WeedMission.new(isServer, isClient, customMt)
	-- upvalues: (copy) WeedMission_mt
	local v9_ = g_i18n:getText("contract_field_weed_title")
	local v10_ = g_i18n:getText("contract_field_weed_description")
	local v11_ = AbstractFieldMission.new(isServer, isClient, v9_, v10_, customMt or WeedMission_mt)
	v11_.workAreaTypes = {
		[WorkAreaType.WEEDER] = true
	}
	v11_.totalWeedArea = nil
	return v11_
end

function WeedMission:saveToXMLFile(xmlFile, key)
	WeedMission:superClass().saveToXMLFile(self, xmlFile, key)
	if self.totalWeedArea ~= nil then
		xmlFile:setInt(key .. "#totalWeedArea", self.totalWeedArea)
	end
end

-- Local values: targetWeedState
function WeedMission:loadFromXMLFile(xmlFile, key)
	if xmlFile:getInt(key .. "#targetWeedState") == nil then
		self.totalWeedArea = xmlFile:getInt(key .. "#totalWeedArea", self.totalWeedArea)
		if self.totalWeedArea == nil or self.totalWeedArea == 0 then
			return false
		else
			return WeedMission:superClass().loadFromXMLFile(self, xmlFile, key)
		end
	else
		return false
	end
end

-- Local values: mission, weedMapId, weedFirstChannel, weedNumChannels
function WeedMission:createModifier()
	local v19_, v20_, v21_ = g_currentMission.weedSystem:getDensityMapData()
	self.completionModifier = DensityMapModifier.new(v19_, v20_, v21_, g_terrainNode)
	self.completionFilter = DensityMapFilter.new(self.completionModifier)
	self.completionFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
end

-- Local values: densityMapPolygon, _, area, _
function WeedMission:finishedPreparing()
	WeedMission:superClass().finishedPreparing(self)
	self.field:getDensityMapPolygon():applyToModifier(self.completionModifier)
	local _, v23_, _ = self.completionModifier:executeGet(self.completionFilter)
	self.totalWeedArea = v23_
	if self.totalWeedArea == 0 then
		self:finish(MissionFinishState.FAILED)
	end
end

-- Local values: areaDone, allCalculated, _, partition
function WeedMission:updateFieldPercentageDone(totalArea)
	local v26_ = 0
	local v27_ = true
	for _, v28_ in ipairs(self.completionPartitions) do
		if not v28_.wasCalculated then
			v27_ = false
		end
		if totalArea > 0 then
			v26_ = v26_ + v28_.area
		else
			v26_ = v26_ + v28_.totalArea
		end
	end
	if v27_ then
		self.fieldPercentageDone = 1 - v26_ / self.totalWeedArea
	end
end

-- Local values: fieldState
function WeedMission:getFieldFinishTask()
	self.field:getFieldState().weedState = 0
	return WeedMission:superClass().getFieldFinishTask(self)
end

-- Local values: data
function WeedMission:getRewardPerHa()
	return g_missionManager:getMissionTypeDataByName(WeedMission.NAME).rewardPerHa
end

function WeedMission:getMissionTypeName()
	return WeedMission.NAME
end

function WeedMission:validate(event)
	if WeedMission:superClass().validate(self, event) then
		return (self:getIsFinished() or WeedMission.isAvailableForField(self.field, self)) and true or false
	else
		return false
	end
end

-- Local values: data
function WeedMission.loadMapData(xmlFile, key, baseDirectory)
	g_missionManager:getMissionTypeDataByName(WeedMission.NAME).rewardPerHa = xmlFile:getFloat(key .. "#rewardPerHa", 2000)
	return true
end
function WeedMission.tryGenerateMission()
	if WeedMission.canRun() then
		local v34_ = g_fieldManager:getFieldForMission()
		if v34_ == nil then
			return
		end
		if v34_.currentMission ~= nil then
			return
		end
		if not WeedMission.isAvailableForField(v34_, nil) then
			return
		end
		local v35_ = WeedMission.new(true, g_client ~= nil)
		if v35_:init(v34_) then
			v35_:setDefaultEndDate()
			return v35_
		end
		v35_:delete()
	end
	return nil
end

-- Local values: fieldState, fruitTypeIndex, fruitTypeDesc, weedSystem, weededState, environment
function WeedMission.isAvailableForField(field, mission)
	if mission == nil then
		local v38_ = field:getFieldState()
		if not v38_.isValid then
			return false
		end
		local v39_ = v38_.fruitTypeIndex
		if v39_ == FruitType.UNKNOWN then
			return false
		end
		local v40_ = g_fruitTypeManager:getFruitTypeByIndex(v39_)
		if v40_:getIsCatchCrop() then
			return false
		end
		if v38_.weedState == 0 then
			return false
		end
		if not v40_:getIsWeedable(v38_.growthState) then
			return false
		end
		if g_currentMission.weedSystem:getWeededState(v38_.weedState) ~= 0 then
			return false
		end
	end
	local v41_ = g_currentMission.environment
	return v41_ == nil or v41_.currentSeason ~= Season.WINTER
end
function WeedMission.canRun()
	local v42_ = g_missionManager:getMissionTypeDataByName(WeedMission.NAME)
	if v42_.numInstances >= v42_.maxNumInstances then
		return false
	elseif g_currentMission.growthSystem:getIsGrowingInProgress() then
		return false
	elseif g_currentMission.weedSystem:getMapHasWeed() then
		return g_currentMission.missionInfo.weedsEnabled and true or false
	else
		return false
	end
end
g_missionManager:registerMissionType(WeedMission, WeedMission.NAME, 2)
