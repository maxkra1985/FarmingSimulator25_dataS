-- Local values: TedderMission_mt
TedderMission = {}
TedderMission.NAME = "tedderMission"
local TedderMission_mt = Class(TedderMission, AbstractFieldMission)
InitStaticObjectClass(TedderMission, "TedderMission")

function TedderMission.registerXMLPaths(schema, key)
	TedderMission:superClass().registerXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#rewardPerHa", "Reward per ha")
end

function TedderMission.registerSavegameXMLPaths(schema, key)
	TedderMission:superClass().registerSavegameXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#spawnedLiters", "Spawned grass liters")
	schema:register(XMLValueType.INT, key .. "#grassSegmentIndex", "Current grass segment index")
	schema:register(XMLValueType.BOOL, key .. "#finishedGrassSpawning", "If grass spawning is finished")
end

-- Upvalues: TedderMission_mt
-- Local values: title, description, self
function TedderMission.new(isServer, isClient, customMt)
	-- upvalues: (copy) TedderMission_mt
	local v9_ = g_i18n:getText("contract_field_tedder_title")
	local v10_ = g_i18n:getText("contract_field_tedder_description")
	local v11_ = AbstractFieldMission.new(isServer, isClient, v9_, v10_, customMt or TedderMission_mt)
	v11_.workAreaTypes = {
		[WorkAreaType.TEDDER] = true
	}
	v11_.finishedGrassSpawning = false
	v11_.initializedGrassSpawning = false
	v11_.currentGrassSegmentIndex = nil
	v11_.spawnedLiters = 0
	return v11_
end

function TedderMission:saveToXMLFile(xmlFile, key)
	TedderMission:superClass().saveToXMLFile(self, xmlFile, key)
	xmlFile:setValue(key .. "#spawnedLiters", self.spawnedLiters)
	if not self.finishedGrassSpawning and self.currentGrassSegmentIndex ~= nil then
		xmlFile:setValue(key .. "#grassSegmentIndex", self.currentGrassSegmentIndex)
	end
	xmlFile:setValue(key .. "#finishedGrassSpawning", self.finishedGrassSpawning)
end

function TedderMission:loadFromXMLFile(xmlFile, key)
	self.spawnedLiters = xmlFile:getValue(key .. "#spawnedLiters", self.spawnedLiters)
	self.currentGrassSegmentIndex = xmlFile:getValue(key .. "#grassSegmentIndex", self.currentGrassSegmentIndex)
	self.finishedGrassSpawning = xmlFile:getValue(key .. "#finishedGrassSpawning", self.finishedGrassSpawning)
	if self.finishedGrassSpawning then
		self.initializedGrassSpawning = true
	end
	return TedderMission:superClass().loadFromXMLFile(self, xmlFile, key)
end

-- Local values: fruitType, fruitTypeDesc, fieldPreparingTask
function TedderMission:getFieldPreparingTask()
	local v19_ = FruitType.GRASS
	local v20_ = g_fruitTypeManager:getFruitTypeByIndex(v19_)
	local v21_ = FieldUpdateTask.new()
	v21_:setArea(self.field:getDensityMapPolygon())
	v21_:setField(self.field)
	v21_:setFruit(v19_, v20_.cutState)
	if v20_.harvestGroundType ~= nil then
		v21_:setGroundType(v20_.harvestGroundType)
	end
	return v21_
end

function TedderMission:getIsPrepared()
	if TedderMission:superClass().getIsPrepared(self) then
		return self.finishedGrassSpawning
	else
		return false
	end
end

-- Local values: finishTask
function TedderMission:getFieldFinishTask()
	local v24_ = TedderMission:superClass().getFieldFinishTask(self)
	if v24_ ~= nil then
		v24_:clearHeight()
	end
	return v24_
end

-- Local values: fruitTypeDesc, litersPerSqm, minLitersPerSqm, workingWidth, dropWidth, x, z, fieldCourseSettings, heightModifier, typeModifier, typeId, grassSegmentIndex, segmentFunc, finishFunc
function TedderMission:update(dt)
	if self.isServer and (self.status == MissionStatus.PREPARING and (self.fieldPreparingTask == nil or self.fieldPreparingTask:getIsFinished())) and not self.initializedGrassSpawning then
		local v27_ = g_fruitTypeManager:getFruitTypeByIndex(FruitType.GRASS)
		local v28_ = v27_.windrowLiterPerSqm or v27_.literPerSqm
		local v29_ = g_densityMapHeightManager:getMinValidLiterValuePerSqm(FillType.GRASS_WINDROW)
		local v_u_30_ = math.max(v28_, v29_)
		local v_u_31_ = 3
		local v32_, v33_ = self.field:getCenterOfFieldWorldPosition()
		local v34_ = FieldCourseSettings.new()
		v34_.implementWidth = 4
		v34_.numHeadlands = 1
		local v_u_35_ = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.heightFirstChannel, DensityMapHeightUtil.heightNumChannels)
		local v_u_36_ = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.typeFirstChannel, DensityMapHeightUtil.typeNumChannels)
		local v_u_37_ = g_densityMapHeightManager:getDensityMapHeightTypeIndexByFillTypeIndex(FillType.GRASS_WINDROW)
		local v_u_38_ = 0
		local function v57_(p39_, p40_, p41_, p42_, _, p43_, _, _)
			-- upvalues: (ref) v_u_38_, (copy) self, (copy) v_u_36_, (copy) v_u_35_, (copy) v_u_37_, (ref) v_u_30_, (copy) v_u_31_
			v_u_38_ = v_u_38_ + 1
			if p43_ == nil and (self.currentGrassSegmentIndex == nil or v_u_38_ > self.currentGrassSegmentIndex) then
				local v44_, v45_ = MathUtil.vector2Normalize(p41_ - p39_, p42_ - p40_)
				local v46_, _, v47_ = MathUtil.transform(p39_, 0, p40_, v44_, 0, v45_, 0, 1, 0, -1.5, 0, 0)
				local v48_, _, v49_ = MathUtil.transform(p39_, 0, p40_, v44_, 0, v45_, 0, 1, 0, 1.5, 0, 0)
				local v50_, _, v51_ = MathUtil.transform(p41_, 0, p42_, v44_, 0, v45_, 0, 1, 0, -1.5, 0, 0)
				v_u_36_:setParallelogramWorldCoords(v46_, v47_, v48_, v49_, v50_, v51_, DensityCoordType.POINT_POINT_POINT)
				v_u_35_:setParallelogramWorldCoords(v46_, v47_, v48_, v49_, v50_, v51_, DensityCoordType.POINT_POINT_POINT)
				local _, _, v52_ = v_u_36_:executeSetWithStats(v_u_37_)
				local v53_ = MathUtil.areaToHa(v52_, g_currentMission:getFruitPixelsToSqm())
				local v54_ = MathUtil.haToSqm(v53_)
				local v55_ = v_u_30_ / v54_
				v_u_35_:executeSet((math.ceil(v55_)))
				local v56_ = v_u_30_ * v54_
				self.spawnedLiters = self.spawnedLiters + v56_
				self.currentGrassSegmentIndex = v_u_38_
			end
		end
		FieldCourseIterator.new(v32_, v33_, v34_, v57_, function()
			-- upvalues: (copy) self
			self.finishedGrassSpawning = true
		end)
		self.initializedGrassSpawning = true
	end
	TedderMission:superClass().update(self, dt)
end

-- Local values: heightType
function TedderMission:createModifier()
	local v59_ = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(FillType.GRASS_WINDROW)
	if v59_ ~= nil then
		self.completionModifier = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.heightFirstChannel, DensityMapHeightUtil.heightNumChannels)
		self.completionFilter = DensityMapFilter.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.typeFirstChannel, DensityMapHeightUtil.typeNumChannels)
		self.completionFilter:setValueCompareParams(DensityValueCompareType.EQUAL, v59_.index)
	end
end

-- Local values: sumPixels, _, partitionPercentage, liters
function TedderMission:getFieldCompletion()
	TedderMission:superClass().getFieldCompletion(self)
	local v61_ = 0
	for _, v62_ in ipairs(self.completionPartitions) do
		if not v62_.wasCalculated then
			return 0
		end
		v61_ = v61_ + v62_.sumPixels
	end
	local v63_ = 1 - v61_ * g_densityMapHeightManager:getMinValidLiterValue(FillType.GRASS_WINDROW) / self.spawnedLiters
	self.fieldPercentageDone = math.clamp(v63_, 0, 1)
	return self.fieldPercentageDone
end

-- Local values: data
function TedderMission:getRewardPerHa()
	return g_missionManager:getMissionTypeDataByName(TedderMission.NAME).rewardPerHa
end

function TedderMission:getMissionTypeName()
	return TedderMission.NAME
end

function TedderMission:validate(event)
	if TedderMission:superClass().validate(self, event) then
		return (self:getIsFinished() or TedderMission.isAvailableForField(self.field, self)) and true or false
	else
		return false
	end
end

-- Local values: data
function TedderMission.loadMapData(xmlFile, key, baseDirectory)
	g_missionManager:getMissionTypeDataByName(TedderMission.NAME).rewardPerHa = xmlFile:getFloat(key .. "#rewardPerHa", 1500)
	return true
end
function TedderMission.tryGenerateMission()
	if TedderMission.canRun() then
		local v68_ = g_fieldManager:getFieldForMission()
		if v68_ == nil then
			return
		end
		if v68_.currentMission ~= nil then
			return
		end
		if not TedderMission.isAvailableForField(v68_, nil) then
			return
		end
		local v69_ = TedderMission.new(true, g_client ~= nil)
		if v69_:init(v68_) then
			v69_:setDefaultEndDate()
			return v69_
		end
		v69_:delete()
	end
	return nil
end

-- Local values: fieldState, fruitTypeIndex, fruitTypeDesc, growthState, environment
function TedderMission.isAvailableForField(field, mission)
	if mission == nil then
		local v72_ = field:getFieldState()
		if not v72_.isValid then
			return false
		end
		local v73_ = v72_.fruitTypeIndex
		if v73_ ~= FruitType.GRASS then
			return false
		end
		if not g_fruitTypeManager:getFruitTypeByIndex(v73_):getIsHarvestable(v72_.growthState) then
			return false
		end
	end
	local v74_ = g_currentMission.environment
	if v74_ ~= nil then
		if v74_.currentSeason == Season.WINTER then
			return false
		end
		if v74_.currentPeriod == SeasonPeriod.EARLY_SPRING or v74_.currentPeriod == SeasonPeriod.MID_SPRING then
			return false
		end
	end
	return true
end
function TedderMission.canRun()
	local v75_ = g_missionManager:getMissionTypeDataByName(TedderMission.NAME)
	return v75_.numInstances < v75_.maxNumInstances
end
g_missionManager:registerMissionType(TedderMission, TedderMission.NAME, 2)
