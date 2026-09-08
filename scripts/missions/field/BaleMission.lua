-- Local values: BaleMission_mt
BaleMission = {}
BaleMission.NAME = "baleMission"
BaleMission.THRESHOLD_LITERS = 1500
local BaleMission_mt = Class(BaleMission, AbstractFieldMission)
InitStaticObjectClass(BaleMission, "BaleMission")

function BaleMission.registerXMLPaths(schema, key)
	BaleMission:superClass().registerXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#rewardPerHa", "Reward per ha")
end

function BaleMission.registerSavegameXMLPaths(schema, key)
	BaleMission:superClass().registerSavegameXMLPaths(schema, key)
	schema:register(XMLValueType.STRING, key .. "#fruitType", "Name of the bale fruit type")
	schema:register(XMLValueType.BOOL, key .. "#needRoundbaler", "If target bale type should be roundbale")
	schema:register(XMLValueType.FLOAT, key .. "#spawnedLiters", "Spawned windrow liters")
	schema:register(XMLValueType.INT, key .. "#swathSegmentIndex", "Current swath segment index")
	schema:register(XMLValueType.BOOL, key .. "#finishedSwathSpawning", "If swath spawning is finished")
	schema:register(XMLValueType.STRING, key .. ".createdBale(?)#uniqueId", "UniqueId of created bale")
end

-- Upvalues: BaleMission_mt
-- Local values: title, description, self
function BaleMission.new(isServer, isClient, customMt)
	-- upvalues: (copy) BaleMission_mt
	local v9_ = g_i18n:getText("contract_field_bale_title")
	local v10_ = g_i18n:getText("contract_field_bale_description")
	local v11_ = AbstractFieldMission.new(isServer, isClient, v9_, v10_, customMt or BaleMission_mt)
	v11_.workAreaTypes = {
		[WorkAreaType.BALER] = true
	}
	v11_.finishedSwathSpawning = false
	v11_.initializedSwathSpawning = false
	v11_.needRoundbaler = false
	v11_.spawnedLiters = 0
	v11_.bales = {}
	v11_.balesToLoadByUniqueId = {}
	return v11_
end

function BaleMission:init(field, fruitTypeIndex, needRoundbaler)
	self:setFruitType(fruitTypeIndex)
	self.needRoundbaler = needRoundbaler
	if needRoundbaler then
		self.description = g_i18n:getText("contract_field_bale_descriptionRound")
	end
	return BaleMission:superClass().init(self, field)
end

-- Local values: fieldId, baleType
function BaleMission:setField(field)
	BaleMission:superClass().setField(self, field)
	local v18_ = field:getId()
	if v18_ ~= nil then
		local v19_
		if self.needRoundbaler then
			v19_ = g_i18n:getText("fillType_roundBale")
		else
			v19_ = g_i18n:getText("fillType_squareBale")
		end
		self.progressTitle = string.format("%s (%s %d) - %s", self.title, g_i18n:getText("contract_details_field"), v18_, v19_)
	end
end

-- Local values: details, baleType
function BaleMission:getDetails()
	local v21_ = BaleMission:superClass().getDetails(self)
	local v22_
	if self.needRoundbaler then
		v22_ = g_i18n:getText("contract_details_bale_type_round")
	else
		v22_ = g_i18n:getText("contract_details_bale_type_square")
	end
	local v23_ = {
		["title"] = g_i18n:getText("contract_details_bale_type"),
		["value"] = v22_
	}
	table.insert(v21_, v23_)
	return v21_
end

function BaleMission:setFruitType(fruitTypeIndex)
	self.fruitTypeIndex = fruitTypeIndex
	self.fruitTypeTitle = g_fruitTypeManager:getFillTypeByFruitTypeIndex(fruitTypeIndex).title
	self.windrowFillTypeIndex = g_fruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(self.fruitTypeIndex)
	if self.fruitTypeIndex == FruitType.GRASS then
		self.windrowFillTypeIndex = FillType.DRYGRASS_WINDROW
	end
end

-- Local values: fruitTypeName, i, bale, createBaleKey
function BaleMission:saveToXMLFile(xmlFile, key)
	BaleMission:superClass().saveToXMLFile(self, xmlFile, key)
	local v29_ = g_fruitTypeManager:getFruitTypeNameByIndex(self.fruitTypeIndex)
	xmlFile:setValue(key .. "#fruitType", v29_)
	xmlFile:setValue(key .. "#needRoundbaler", self.needRoundbaler)
	xmlFile:setValue(key .. "#spawnedLiters", self.spawnedLiters)
	if not self.finishedSwathSpawning and self.currentSwathSegmentIndex ~= nil then
		xmlFile:setValue(key .. "#swathSegmentIndex", self.currentSwathSegmentIndex)
	end
	xmlFile:setValue(key .. "#finishedSwathSpawning", self.finishedSwathSpawning)
	for v30_, v31_ in ipairs(self.bales) do
		xmlFile:setValue(string.format("%s.createdBale(%d)", key, v30_ - 1) .. "#uniqueId", v31_:getUniqueId())
	end
end

-- Local values: fruitTypeName, fruitTypeIndex, _, createBaleKey, baleUniqueId
function BaleMission:loadFromXMLFile(xmlFile, key)
	local v35_ = xmlFile:getValue(key .. "#fruitType")
	self:setFruitType((g_fruitTypeManager:getFruitTypeIndexByName(v35_)))
	self.needRoundbaler = xmlFile:getValue(key .. "#needRoundbaler", self.needRoundbaler)
	self.spawnedLiters = xmlFile:getValue(key .. "#spawnedLiters", self.spawnedLiters)
	if self.needRoundbaler then
		self.description = g_i18n:getText("contract_field_bale_descriptionRound")
	end
	for _, v36_ in xmlFile:iterator(key .. ".createdBale") do
		local v37_ = xmlFile:getValue(v36_ .. "#uniqueId")
		local v38_ = self.balesToLoadByUniqueId
		table.insert(v38_, v37_)
	end
	self.currentSwathSegmentIndex = xmlFile:getValue(key .. "#swathSegmentIndex", self.currentSwathSegmentIndex)
	self.finishedSwathSpawning = xmlFile:getValue(key .. "#finishedSwathSpawning", self.finishedSwathSpawning)
	if self.finishedSwathSpawning then
		self.initializedSwathSpawning = true
	end
	return BaleMission:superClass().loadFromXMLFile(self, xmlFile, key)
end

function BaleMission:writeStream(streamId, connection)
	BaleMission:superClass().writeStream(self, streamId, connection)
	streamWriteUIntN(streamId, self.fruitTypeIndex or 0, FruitTypeManager.SEND_NUM_BITS)
	streamWriteBool(streamId, self.needRoundbaler)
end

-- Local values: fruitTypeIndex
function BaleMission:readStream(streamId, connection)
	BaleMission:superClass().readStream(self, streamId, connection)
	self:setFruitType((streamReadUIntN(streamId, FruitTypeManager.SEND_NUM_BITS)))
	self.needRoundbaler = streamReadBool(streamId)
	if self.needRoundbaler then
		self.description = g_i18n:getText("contract_field_bale_descriptionRound")
	end
end

function BaleMission:getIsPrepared()
	if BaleMission:superClass().getIsPrepared(self) then
		return self.finishedSwathSpawning
	else
		return false
	end
end

-- Local values: fruitTypeDesc, fieldState
function BaleMission:getFieldPreparingTask()
	if self.isServer then
		local v47_ = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
		local v48_ = self.field:getFieldState()
		v48_.fruitTypeIndex = self.fruitTypeIndex
		v48_.growthState = v47_.cutState
		v48_.weedState = 0
		if v47_.harvestGroundType ~= nil then
			v48_.groundType = v47_.harvestGroundType
		end
	end
	return BaleMission:superClass().getFieldPreparingTask(self)
end

-- Local values: finishTask
function BaleMission:getFieldFinishTask()
	local v50_ = BaleMission:superClass().getFieldFinishTask(self)
	if v50_ ~= nil then
		v50_:clearHeight()
	end
	return v50_
end

-- Local values: _, bale
function BaleMission:finishField()
	if self.isServer then
		for _, v52_ in ipairs(self.bales) do
			v52_:delete()
		end
		self.bales = {}
	end
	BaleMission:superClass().finishField(self)
end

-- Local values: _, vehicle
function BaleMission:removeAccess()
	if self.isServer then
		for _, v54_ in ipairs(self.vehicles) do
			if v54_.spec_baler ~= nil then
				v54_.spec_baler.dropBalesOnDelete = false
			end
		end
	end
	BaleMission:superClass().removeAccess(self)
end

-- Local values: fruitTypeDesc, litersPerSqm, fieldSizeHa, fieldSizeSqm, litersToDrop, workingWidth, x, z, fieldCourseSettings, swathSegmentIndex, segmentFunc, finishFunc, _, baleUniqueId, bale
function BaleMission:update(dt)
	if self.isServer and (self.status == MissionStatus.PREPARING and (self.fieldPreparingTask == nil or self.fieldPreparingTask:getIsFinished())) and not self.initializedSwathSpawning then
		local v57_ = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
		local v58_ = v57_.windrowLiterPerSqm or v57_.literPerSqm
		local v59_ = self.field:getAreaHa()
		local v_u_60_ = MathUtil.haToSqm(v59_) * v58_
		local v61_ = v59_ > 6 and 12 or 9
		local v62_, v63_ = self.field:getCenterOfFieldWorldPosition()
		local v64_ = FieldCourseSettings.new()
		v64_.implementWidth = v61_
		v64_.numHeadlands = 2
		local v_u_65_ = 0
		local function v75_(p66_, p67_, p68_, p69_, _, _, _, p70_)
			-- upvalues: (ref) v_u_65_, (copy) self, (copy) v_u_60_
			v_u_65_ = v_u_65_ + 1
			if self.currentSwathSegmentIndex == nil or v_u_65_ > self.currentSwathSegmentIndex then
				local v71_ = MathUtil.vector2Length(p68_ - p66_, p69_ - p67_)
				local v72_ = self.windrowFillTypeIndex
				local v73_ = v71_ * (v_u_60_ / p70_)
				local v74_, _ = DensityMapHeightUtil.tipToGroundAroundLine(self, v73_, v72_, p66_, 0, p67_, p68_, 0, p69_, 0.5, 0.5, 0, false, nil, false, true)
				self.spawnedLiters = self.spawnedLiters + v74_
				self.currentSwathSegmentIndex = v_u_65_
			end
		end
		FieldCourseIterator.new(v62_, v63_, v64_, v75_, function()
			-- upvalues: (copy) self
			self.finishedSwathSpawning = true
		end)
		self.initializedSwathSpawning = true
	end
	if self.balesToLoadByUniqueId ~= nil then
		for _, v76_ in ipairs(self.balesToLoadByUniqueId) do
			local v77_ = g_currentMission.itemSystem:getItemByUniqueId(v76_)
			if v77_ ~= nil then
				local v78_ = self.bales
				table.insert(v78_, v77_)
			end
		end
		self.balesToLoadByUniqueId = nil
	end
	BaleMission:superClass().update(self, dt)
end

-- Local values: fillType
function BaleMission:addBale(bale)
	if bale ~= nil and bale:getFillType() == self.windrowFillTypeIndex then
		local v81_ = self.bales
		table.insert(v81_, bale)
		bale:setOwnerFarmId(AccessHandler.NOBODY)
	end
end

-- Local values: sumPixels, allCalculated, _, partitionPercentage, liters
function BaleMission:getFieldCompletion()
	BaleMission:superClass().getFieldCompletion(self)
	local v83_ = 0
	local v84_ = true
	for _, v85_ in ipairs(self.completionPartitions) do
		if not v85_.wasCalculated then
			v84_ = false
		end
		v83_ = v83_ + v85_.sumPixels
	end
	local v86_ = v83_ * g_densityMapHeightManager:getMinValidLiterValue(self.windrowFillTypeIndex)
	if v84_ then
		local v87_ = 1 - v86_ / self.spawnedLiters
		self.fieldPercentageDone = math.clamp(v87_, 0, 1)
	end
	return self.fieldPercentageDone
end

-- Local values: heightType
function BaleMission:createModifier()
	local v89_ = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(self.windrowFillTypeIndex)
	if v89_ ~= nil then
		self.completionModifier = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.heightFirstChannel, DensityMapHeightUtil.heightNumChannels)
		self.completionFilter = DensityMapFilter.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.typeFirstChannel, DensityMapHeightUtil.typeNumChannels)
		self.completionFilter:setValueCompareParams(DensityValueCompareType.EQUAL, v89_.index)
	end
end

function BaleMission:getCompletion()
	return self:getFieldCompletion()
end

-- Local values: data
function BaleMission:getRewardPerHa()
	return g_missionManager:getMissionTypeDataByName(BaleMission.NAME).rewardPerHa
end

function BaleMission:getMissionTypeName()
	return BaleMission.NAME
end

function BaleMission:validate(event)
	if BaleMission:superClass().validate(self, event) then
		return (self:getIsFinished() or BaleMission.isAvailableForField(self.field, self)) and true or false
	else
		return false
	end
end

function BaleMission:getIsWorkAllowed(farmId, x, z, workAreaType, vehicle)
	if BaleMission:superClass().getIsWorkAllowed(self, farmId, x, z, workAreaType, vehicle) then
		return (vehicle == nil or vehicle.getIsRoundBaler == nil) and true or vehicle:getIsRoundBaler() == self.needRoundbaler
	else
		return false
	end
end

function BaleMission:getVehicleVariant()
	return self.needRoundbaler and "ROUNDBALER" or "SQUAREBALER"
end

function BaleMission:getVariant()
	return self.needRoundbaler and "ROUNDBALER" or "SQUAREBALER"
end

-- Local values: data
function BaleMission.loadMapData(xmlFile, key, baseDirectory)
	g_missionManager:getMissionTypeDataByName(BaleMission.NAME).rewardPerHa = xmlFile:getFloat(key .. "#rewardPerHa", 2200)
	return true
end
function BaleMission.tryGenerateMission()
	if BaleMission.canRun() then
		local v103_ = g_fieldManager:getFieldForMission()
		if v103_ == nil then
			return
		end
		if v103_.currentMission ~= nil then
			return
		end
		if not BaleMission.isAvailableForField(v103_, nil) then
			return
		end
		local v104_ = v103_:getFieldState()
		local v105_ = math.random() > 0.5
		local v106_ = BaleMission.new(true, g_client ~= nil)
		if v106_:init(v103_, v104_.fruitTypeIndex, v105_) then
			v106_:setDefaultEndDate()
			return v106_
		end
		v106_:delete()
	end
	return nil
end

-- Local values: fieldState, fruitTypeIndex, fruitTypeDesc, growthState, windrowFillTypeIndex, environment
function BaleMission.isAvailableForField(field, mission)
	if mission == nil then
		local v109_ = field:getFieldState()
		if not v109_.isValid then
			return false
		end
		local v110_ = v109_.fruitTypeIndex
		if v110_ == FruitType.UNKNOWN then
			return false
		end
		local v111_ = g_fruitTypeManager:getFruitTypeByIndex(v110_)
		if not v111_:getIsHarvestReady(v109_.growthState) then
			return false
		end
		if not v111_.hasWindrow then
			return false
		end
		local v112_ = g_fruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(v111_.index)
		if v112_ ~= FillType.STRAW and v112_ ~= FillType.DRYGRASS_WINDROW then
			return false
		end
	end
	local v113_ = g_currentMission.environment
	return v113_ == nil or v113_.currentSeason ~= Season.WINTER
end
function BaleMission.canRun()
	local v114_ = g_missionManager:getMissionTypeDataByName(BaleMission.NAME)
	return v114_.numInstances < v114_.maxNumInstances
end
g_missionManager:registerMissionType(BaleMission, BaleMission.NAME, 3)
