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
function BaleMission.new(isServer, isClient, customMt)
	local title = g_i18n:getText("contract_field_bale_title")
	local description = g_i18n:getText("contract_field_bale_description")
	local self = AbstractFieldMission.new(isServer, isClient, title, description, customMt or BaleMission_mt)
	self.workAreaTypes = { [WorkAreaType.BALER] = true }
	self.finishedSwathSpawning = false
	self.initializedSwathSpawning = false
	self.needRoundbaler = false
	self.spawnedLiters = 0
	self.bales = {}
	self.balesToLoadByUniqueId = {}
	return self
end
function BaleMission:init(field, fruitTypeIndex, needRoundbaler)
	self:setFruitType(fruitTypeIndex)
	self.needRoundbaler = needRoundbaler
	if needRoundbaler then
		self.description = g_i18n:getText("contract_field_bale_descriptionRound")
	end
	return BaleMission:superClass().init(self, field)
end
function BaleMission:setField(field)
	BaleMission:superClass().setField(self, field)
	local fieldId = field:getId()
	if fieldId ~= nil then
		local baleType = nil
		if self.needRoundbaler then
			baleType = g_i18n:getText("fillType_roundBale")
		else
			baleType = g_i18n:getText("fillType_squareBale")
		end
		self.progressTitle = string.format("%s (%s %d) - %s", self.title, g_i18n:getText("contract_details_field"), fieldId, baleType)
	end
end
function BaleMission:getDetails()
	local details = BaleMission:superClass().getDetails(self)
	local baleType = nil
	if self.needRoundbaler then
		baleType = g_i18n:getText("contract_details_bale_type_round")
	else
		baleType = g_i18n:getText("contract_details_bale_type_square")
	end
	table.insert(details, { value = baleType, title = g_i18n:getText("contract_details_bale_type") })
	return details
end
function BaleMission:setFruitType(fruitTypeIndex)
	self.fruitTypeIndex = fruitTypeIndex
	self.fruitTypeTitle = g_fruitTypeManager:getFillTypeByFruitTypeIndex(fruitTypeIndex).title
	self.windrowFillTypeIndex = g_fruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(self.fruitTypeIndex)
	if self.fruitTypeIndex == FruitType.GRASS then
		self.windrowFillTypeIndex = FillType.DRYGRASS_WINDROW
	end
end
function BaleMission:saveToXMLFile(xmlFile, key)
	BaleMission:superClass().saveToXMLFile(self, xmlFile, key)
	local fruitTypeName = g_fruitTypeManager:getFruitTypeNameByIndex(self.fruitTypeIndex)
	xmlFile:setValue(key .. "#fruitType", fruitTypeName)
	xmlFile:setValue(key .. "#needRoundbaler", self.needRoundbaler)
	xmlFile:setValue(key .. "#spawnedLiters", self.spawnedLiters)
	if not self.finishedSwathSpawning and self.currentSwathSegmentIndex ~= nil then
		xmlFile:setValue(key .. "#swathSegmentIndex", self.currentSwathSegmentIndex)
	end
	xmlFile:setValue(key .. "#finishedSwathSpawning", self.finishedSwathSpawning)
	for i, bale in ipairs(self.bales) do
		local createBaleKey = string.format("%s.createdBale(%d)", key, i - 1)
		xmlFile:setValue(createBaleKey .. "#uniqueId", bale:getUniqueId())
	end
end
function BaleMission:loadFromXMLFile(xmlFile, key)
	local fruitTypeName = xmlFile:getValue(key .. "#fruitType")
	local fruitTypeIndex = g_fruitTypeManager:getFruitTypeIndexByName(fruitTypeName)
	self:setFruitType(fruitTypeIndex)
	self.needRoundbaler = xmlFile:getValue(key .. "#needRoundbaler", self.needRoundbaler)
	self.spawnedLiters = xmlFile:getValue(key .. "#spawnedLiters", self.spawnedLiters)
	if self.needRoundbaler then
		self.description = g_i18n:getText("contract_field_bale_descriptionRound")
	end
	for _, createBaleKey in xmlFile:iterator(key .. ".createdBale") do
		local baleUniqueId = xmlFile:getValue(createBaleKey .. "#uniqueId")
		table.insert(self.balesToLoadByUniqueId, baleUniqueId)
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
function BaleMission:readStream(streamId, connection)
	BaleMission:superClass().readStream(self, streamId, connection)
	local fruitTypeIndex = streamReadUIntN(streamId, FruitTypeManager.SEND_NUM_BITS)
	self:setFruitType(fruitTypeIndex)
	self.needRoundbaler = streamReadBool(streamId)
	if self.needRoundbaler then
		self.description = g_i18n:getText("contract_field_bale_descriptionRound")
	end
end
function BaleMission:getIsPrepared()
	if not BaleMission:superClass().getIsPrepared(self) then
		return false
	else
		return self.finishedSwathSpawning
	end
end
function BaleMission:getFieldPreparingTask()
	if self.isServer then
		local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
		local fieldState = self.field:getFieldState()
		fieldState.fruitTypeIndex = self.fruitTypeIndex
		fieldState.growthState = fruitTypeDesc.cutState
		fieldState.weedState = 0
		if fruitTypeDesc.harvestGroundType ~= nil then
			fieldState.groundType = fruitTypeDesc.harvestGroundType
		end
	end
	return BaleMission:superClass().getFieldPreparingTask(self)
end
function BaleMission:getFieldFinishTask()
	local finishTask = BaleMission:superClass().getFieldFinishTask(self)
	if finishTask ~= nil then
		finishTask:clearHeight()
	end
	return finishTask
end
function BaleMission:finishField()
	if self.isServer then
		for _, bale in ipairs(self.bales) do
			bale:delete()
		end
		self.bales = {}
	end
	BaleMission:superClass().finishField(self)
end
function BaleMission:removeAccess()
	if self.isServer then
		for _, vehicle in ipairs(self.vehicles) do
			if vehicle.spec_baler == nil then
				continue
			end
			vehicle.spec_baler.dropBalesOnDelete = false
		end
	end
	BaleMission:superClass().removeAccess(self)
end
function BaleMission:update(dt)
	if self.isServer and (self.status == MissionStatus.PREPARING and ((self.fieldPreparingTask == nil or self.fieldPreparingTask:getIsFinished()) and not self.initializedSwathSpawning)) then
		local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
		local litersPerSqm = fruitTypeDesc.windrowLiterPerSqm or fruitTypeDesc.literPerSqm
		local fieldSizeHa = self.field:getAreaHa()
		local fieldSizeSqm = MathUtil.haToSqm(fieldSizeHa)
		local litersToDrop = fieldSizeSqm * litersPerSqm
		local workingWidth = 9
		if 6 < fieldSizeHa then
			workingWidth = 12
		end
		local x, z = self.field:getCenterOfFieldWorldPosition()
		local fieldCourseSettings = FieldCourseSettings.new()
		fieldCourseSettings.implementWidth = workingWidth
		fieldCourseSettings.numHeadlands = 2
		local swathSegmentIndex = 0
		local segmentFunc = function(sx, sz, ex, ez, segmentLength, headlandIndex, islandIndex, totalCourseLength)
			swathSegmentIndex = swathSegmentIndex + 1
			if self.currentSwathSegmentIndex == nil or self.currentSwathSegmentIndex < swathSegmentIndex then
				local length = MathUtil.vector2Length(ex - sx, ez - sz)
				local fillTypeIndex = self.windrowFillTypeIndex
				local radius = 0.5
				local literPerMeter = litersToDrop / totalCourseLength
				local segmentLiters = length * literPerMeter
				local fillLevel, _ = DensityMapHeightUtil.tipToGroundAroundLine(self, segmentLiters, fillTypeIndex, sx, 0, sz, ex, 0, ez, 0.5, 0.5, 0, false, nil, false, true)
				self.spawnedLiters = self.spawnedLiters + fillLevel
				self.currentSwathSegmentIndex = swathSegmentIndex
			end
		end
		local finishFunc = function()
			self.finishedSwathSpawning = true
		end
		FieldCourseIterator.new(x, z, fieldCourseSettings, segmentFunc, finishFunc)
		self.initializedSwathSpawning = true
	end
	if self.balesToLoadByUniqueId ~= nil then
		for _, baleUniqueId in ipairs(self.balesToLoadByUniqueId) do
			local bale = g_currentMission.itemSystem:getItemByUniqueId(baleUniqueId)
			if bale == nil then
				continue
			end
			table.insert(self.bales, bale)
		end
		self.balesToLoadByUniqueId = nil
	end
	BaleMission:superClass().update(self, dt)
end
function BaleMission:addBale(bale)
	if bale ~= nil then
		local fillType = bale:getFillType()
		if fillType == self.windrowFillTypeIndex then
			table.insert(self.bales, bale)
			bale:setOwnerFarmId(AccessHandler.NOBODY)
		end
	end
end
function BaleMission:getFieldCompletion()
	BaleMission:superClass().getFieldCompletion(self)
	local sumPixels = 0
	local allCalculated = true
	for _, partitionPercentage in ipairs(self.completionPartitions) do
		if not partitionPercentage.wasCalculated then
			allCalculated = false
		end
		sumPixels = sumPixels + partitionPercentage.sumPixels
	end
	local liters = sumPixels * g_densityMapHeightManager:getMinValidLiterValue(self.windrowFillTypeIndex)
	if allCalculated then
		self.fieldPercentageDone = math.clamp(1 - liters / self.spawnedLiters, 0, 1)
	end
	return self.fieldPercentageDone
end
function BaleMission:createModifier()
	local heightType = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(self.windrowFillTypeIndex)
	if heightType == nil then
		return
	else
		self.completionModifier = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.heightFirstChannel, DensityMapHeightUtil.heightNumChannels)
		self.completionFilter = DensityMapFilter.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.typeFirstChannel, DensityMapHeightUtil.typeNumChannels)
		self.completionFilter:setValueCompareParams(DensityValueCompareType.EQUAL, heightType.index)
	end
end
function BaleMission:getCompletion()
	return self:getFieldCompletion()
end
function BaleMission:getRewardPerHa()
	local data = g_missionManager:getMissionTypeDataByName(BaleMission.NAME)
	return data.rewardPerHa
end
function BaleMission:getMissionTypeName()
	return BaleMission.NAME
end
function BaleMission:validate(event)
	if not BaleMission:superClass().validate(self, event) then
		return false
	elseif not self:getIsFinished() and not BaleMission.isAvailableForField(self.field, self) then
		return false
	else
		return true
	end
end
function BaleMission:getIsWorkAllowed(farmId, x, z, workAreaType, vehicle)
	if not BaleMission:superClass().getIsWorkAllowed(self, farmId, x, z, workAreaType, vehicle) then
		return false
	elseif vehicle == nil or vehicle.getIsRoundBaler == nil then
		return true
	else
		return vehicle:getIsRoundBaler() == self.needRoundbaler
	end
end
function BaleMission:getVehicleVariant()
	if self.needRoundbaler then
		return "ROUNDBALER"
	else
		return "SQUAREBALER"
	end
end
function BaleMission:getVariant()
	if self.needRoundbaler then
		return "ROUNDBALER"
	else
		return "SQUAREBALER"
	end
end
function BaleMission.loadMapData(xmlFile, key, baseDirectory)
	local data = g_missionManager:getMissionTypeDataByName(BaleMission.NAME)
	data.rewardPerHa = xmlFile:getFloat(key .. "#rewardPerHa", 2200)
	return true
end
function BaleMission.tryGenerateMission()
	if BaleMission.canRun() then
		local field = g_fieldManager:getFieldForMission()
		if field == nil then
			return
		end
		if field.currentMission ~= nil then
			return
		end
		if not BaleMission.isAvailableForField(field, nil) then
			return
		end
		local fieldState = field:getFieldState()
		local needRoundbaler = 0.5 < math.random()
		local mission = BaleMission.new(true, g_client ~= nil)
		if mission:init(field, fieldState.fruitTypeIndex, needRoundbaler) then
			mission:setDefaultEndDate()
			return mission
		end
		mission:delete()
	end
	return nil
end
function BaleMission.isAvailableForField(field, mission)
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
		local growthState = fieldState.growthState
		if not fruitTypeDesc:getIsHarvestReady(growthState) then
			return false
		end
		if not fruitTypeDesc.hasWindrow then
			return false
		end
		local windrowFillTypeIndex = g_fruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(fruitTypeDesc.index)
		if windrowFillTypeIndex ~= FillType.STRAW and windrowFillTypeIndex ~= FillType.DRYGRASS_WINDROW then
			return false
		end
	end
	local environment = g_currentMission.environment
	if environment ~= nil and environment.currentSeason == Season.WINTER then
		return false
	end
	return true
end
function BaleMission.canRun()
	local data = g_missionManager:getMissionTypeDataByName(BaleMission.NAME)
	if data.maxNumInstances <= data.numInstances then
		return false
	else
		return true
	end
end
g_missionManager:registerMissionType(BaleMission, BaleMission.NAME, 3)
