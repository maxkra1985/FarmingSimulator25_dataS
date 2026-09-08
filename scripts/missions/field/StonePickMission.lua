-- Local values: StonePickMission_mt
StonePickMission = {}
StonePickMission.NAME = "stonePickMission"
local StonePickMission_mt = Class(StonePickMission, AbstractFieldMission)
InitStaticObjectClass(StonePickMission, "StonePickMission")

function StonePickMission.registerXMLPaths(schema, key)
	StonePickMission:superClass().registerXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#rewardPerHa", "Reward per ha")
end

-- Upvalues: StonePickMission_mt
-- Local values: title, description, self
function StonePickMission.new(isServer, isClient, customMt)
	-- upvalues: (copy) StonePickMission_mt
	local v7_ = g_i18n:getText("contract_field_stonePick_title")
	local v8_ = g_i18n:getText("contract_field_stonePick_description")
	local v9_ = AbstractFieldMission.new(isServer, isClient, v7_, v8_, customMt or StonePickMission_mt)
	v9_.workAreaTypes = {
		[WorkAreaType.STONEPICKER] = true
	}
	v9_.stoneValue = 3
	v9_.spawnedPixels = 0
	return v9_
end

function StonePickMission:init(field)
	return StonePickMission:superClass().init(self, field)
end

-- Local values: fieldState
function StonePickMission:getFieldPreparingTask()
	if self.isServer then
		self.field:getFieldState().stoneLevel = self.stoneValue
	end
	return StonePickMission:superClass().getFieldPreparingTask(self)
end

-- Local values: fieldState
function StonePickMission:getFieldFinishTask()
	if self.isServer then
		local v14_ = self.field:getFieldState()
		v14_.stoneLevel = 0
		v14_.groundType = FieldGroundType.CULTIVATED
	end
	return StonePickMission:superClass().getFieldFinishTask(self)
end

-- Local values: mission, mapId, firstChannel, numChannels, _, maxValue
function StonePickMission:createModifier()
	local v16_, v17_, v18_ = g_currentMission.stoneSystem:getDensityMapData()
	local _, v19_ = g_currentMission.stoneSystem:getMinMaxValues()
	self.completionModifier = DensityMapModifier.new(v16_, v17_, v18_, g_terrainNode)
	self.completionModifierUnmasked = DensityMapModifier.new(v16_, v17_, v18_, g_terrainNode)
	self.completionFilter = DensityMapFilter.new(self.completionModifier)
	self.completionFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, v19_)
	self.completionFilterMasked = DensityMapFilter.new(self.completionModifier)
	self.completionFilterMasked:setValueCompareParams(DensityValueCompareType.GREATER, 0)
	self.completionFilterUnmasked = DensityMapFilter.new(self.completionModifier)
	self.completionFilterUnmasked:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
end

-- Local values: sumPixels, area, totalArea, _, unmaskedArea, _
function StonePickMission:getPartitionCompletion(partitionIndex)
	self:setPartitionRegion(partitionIndex)
	if self.completionModifier == nil then
		return 0, 0, 0
	end
	local v22_, v23_, v24_ = self.completionModifier:executeGet(self.completionFilter, self.completionFilterMasked)
	local _, v25_, _ = self.completionModifierUnmasked:executeGet(self.completionFilterUnmasked)
	return v22_, v23_, v24_ - v25_
end

-- Local values: densityMapPolygon
function StonePickMission:initializeModifier()
	StonePickMission:superClass().initializeModifier(self)
	if self.completionModifierUnmasked ~= nil then
		self.field:getDensityMapPolygon():applyToModifier(self.completionModifierUnmasked)
	end
end

-- Local values: partition
function StonePickMission:setPartitionRegion(partitionIndex)
	StonePickMission:superClass().setPartitionRegion(self, partitionIndex)
	if #self.completionPartitions ~= 1 then
		if self.completionModifierUnmasked ~= nil then
			local v29_ = self.completionPartitions[partitionIndex]
			self.completionModifierUnmasked:setPolygonClipRegion(v29_.minZ, v29_.maxZ)
		end
	end
end

-- Local values: data
function StonePickMission:getRewardPerHa()
	return g_missionManager:getMissionTypeDataByName(StonePickMission.NAME).rewardPerHa
end

function StonePickMission:getMissionTypeName()
	return StonePickMission.NAME
end

function StonePickMission:validate(event)
	if StonePickMission:superClass().validate(self, event) then
		return (self:getIsFinished() or StonePickMission.isAvailableForField(self.field, self)) and true or false
	else
		return false
	end
end

-- Local values: data
function StonePickMission.loadMapData(xmlFile, key, baseDirectory)
	g_missionManager:getMissionTypeDataByName(StonePickMission.NAME).rewardPerHa = xmlFile:getFloat(key .. "#rewardPerHa", 2200)
	return true
end
function StonePickMission.tryGenerateMission()
	if StonePickMission.canRun() then
		local v34_ = g_fieldManager:getFieldForMission()
		if v34_ == nil then
			return
		end
		if v34_.currentMission ~= nil then
			return
		end
		if not StonePickMission.isAvailableForField(v34_, nil) then
			return
		end
		local v35_ = StonePickMission.new(true, g_client ~= nil)
		if v35_:init(v34_) then
			v35_:setDefaultEndDate()
			return v35_
		end
		v35_:delete()
	end
	return nil
end

-- Local values: fieldState, fruitTypeIndex, groundType, environment
function StonePickMission.isAvailableForField(field, mission)
	if mission == nil then
		local v38_ = field:getFieldState()
		if not v38_.isValid then
			return false
		end
		if v38_.fruitTypeIndex ~= FruitType.UNKNOWN then
			return false
		end
		if v38_.groundType ~= FieldGroundType.PLOWED then
			return false
		end
	end
	local v39_ = g_currentMission.environment
	return v39_ == nil or v39_.currentSeason ~= Season.WINTER
end
function StonePickMission.canRun()
	local v40_ = g_missionManager:getMissionTypeDataByName(StonePickMission.NAME)
	return v40_.numInstances < v40_.maxNumInstances
end
g_missionManager:registerMissionType(StonePickMission, StonePickMission.NAME, 1)
