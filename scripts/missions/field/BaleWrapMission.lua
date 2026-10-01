BaleWrapMission = {}
BaleWrapMission.NAME = "baleWrapMission"
local BaleWrapMission_mt = Class(BaleWrapMission, AbstractFieldMission)
InitStaticObjectClass(BaleWrapMission, "BaleWrapMission")
function BaleWrapMission.registerXMLPaths(schema, key)
	BaleWrapMission:superClass().registerXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#rewardPerBale", "Reward per bale")
end
function BaleWrapMission.registerSavegameXMLPaths(schema, key)
	BaleWrapMission:superClass().registerSavegameXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#baleTypeIndex", "Bale type")
	schema:register(XMLValueType.INT, key .. "#numOfBales", "Bale count")
	schema:register(XMLValueType.STRING, key .. ".bale(?)#uniqueId", "Spawned bale")
end
function BaleWrapMission.new(isServer, isClient, customMt)
	local title = g_i18n:getText("contract_field_baleWrap_title")
	local description = g_i18n:getText("contract_field_baleWrap_description")
	local self = AbstractFieldMission.new(isServer, isClient, title, description, customMt or BaleWrapMission_mt)
	self.bales = {}
	self.balesToLoadByUniqueId = nil
	return self
end
function BaleWrapMission:init(field, baleTypeIndex, numOfBales)
	self.baleTypeIndex = baleTypeIndex
	self.numOfBales = numOfBales
	return BaleWrapMission:superClass().init(self, field)
end
function BaleWrapMission:setField(field)
	BaleWrapMission:superClass().setField(self, field)
	local fieldId = field:getId()
	if fieldId ~= nil then
		local isRoundBale = g_baleManager:getIsRoundBale(self.baleTypeIndex)
		local baleType = nil
		if isRoundBale then
			baleType = g_i18n:getText("fillType_roundBale")
		else
			baleType = g_i18n:getText("fillType_squareBale")
		end
		self.progressTitle = string.format("%s (%s %d) - %s", self.title, g_i18n:getText("contract_details_field"), fieldId, baleType)
	end
end
function BaleWrapMission:writeStream(streamId, connection)
	BaleWrapMission:superClass().writeStream(self, streamId, connection)
	streamWriteUIntN(streamId, self.baleTypeIndex, BaleManager.SEND_NUM_BITS)
	streamWriteUInt16(streamId, self.numOfBales)
end
function BaleWrapMission:readStream(streamId, connection)
	BaleWrapMission:superClass().readStream(self, streamId, connection)
	self.baleTypeIndex = streamReadUIntN(streamId, BaleManager.SEND_NUM_BITS)
	self.numOfBales = streamReadUInt16(streamId)
end
function BaleWrapMission:saveToXMLFile(xmlFile, key)
	BaleWrapMission:superClass().saveToXMLFile(self, xmlFile, key)
	for i, bale in ipairs(self.bales) do
		local baleKey = string.format("%s.bale(%d)", key, i - 1)
		xmlFile:setValue(baleKey .. "#uniqueId", bale:getUniqueId())
	end
	xmlFile:setValue(key .. "#baleTypeIndex", self.baleTypeIndex)
	xmlFile:setValue(key .. "#numOfBales", self.numOfBales)
end
function BaleWrapMission:loadFromXMLFile(xmlFile, key)
	for _, baleKey in xmlFile:iterator(key .. ".bale") do
		local baleUniqueId = xmlFile:getValue(baleKey .. "#uniqueId")
		if self.balesToLoadByUniqueId == nil then
			self.balesToLoadByUniqueId = {}
		end
		table.insert(self.balesToLoadByUniqueId, baleUniqueId)
	end
	self.baleTypeIndex = xmlFile:getValue(key .. "#baleTypeIndex")
	if self.baleTypeIndex == nil then
		return false
	end
	self.numOfBales = xmlFile:getValue(key .. "#numOfBales")
	if self.numOfBales == nil then
		return false
	else
		self.finishedBaleSpawning = true
		return BaleWrapMission:superClass().loadFromXMLFile(self, xmlFile, key)
	end
end
function BaleWrapMission:prepareField()
	BaleWrapMission:superClass().prepareField(self)
	if self.isServer then
		local fruitType = FruitType.GRASS
		local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)
		local litersPerSqm = fruitTypeDesc.windrowLiterPerSqm or fruitTypeDesc.literPerSqm
		local fieldSizeSqm = MathUtil.haToSqm(self.field:getAreaHa())
		local litersToDrop = fieldSizeSqm * litersPerSqm
		local x, z = self.field:getCenterOfFieldWorldPosition()
		local fieldCourseSettings = FieldCourseSettings.new()
		fieldCourseSettings.implementWidth = 8
		fieldCourseSettings.numHeadlands = 2
		local baleFillTypeIndex = fruitTypeDesc.windrowFillType.index
		local baleXMLFilename = g_baleManager:getBaleXMLFilenameByIndex(self.baleTypeIndex)
		local baleCapacity = g_baleManager:getBaleCapacityByBaleIndex(self.baleTypeIndex, baleFillTypeIndex)
		local baleDesc = g_baleManager:getBaleDescByIndex(self.baleTypeIndex)
		local isRoundBale = g_baleManager:getIsRoundBale(self.baleTypeIndex)
		local nextBaleLiters = baleCapacity
		local spawnBale = function(sx, sz, ex, ez, length, percentageFromStart)
			local spawnDistanceFromStart = length * percentageFromStart
			local dirX, dirZ = MathUtil.vector2Normalize(ex - sx, ez - sz)
			local spawnPosX = sx + dirX * spawnDistanceFromStart
			local spawnPosZ = sz + dirZ * spawnDistanceFromStart
			local rotX = 0
			local rotZ = 0
			local rotY = MathUtil.getYRotationFromDirection(dirX, dirZ) + 1.5707963267948966
			local height = baleDesc.diameter
			if not isRoundBale then
				rotY = rotY + 1.5707963267948966
				height = baleDesc.height
			end
			local spawnPosY = getTerrainHeightAtWorldPos(g_terrainNode, spawnPosX, 0, spawnPosZ) + height * 0.5
			local baleObject = Bale.new(self.isServer, self.isClient)
			if baleObject:loadFromConfigXML(baleXMLFilename, spawnPosX, spawnPosY, spawnPosZ, 0, rotY, 0) then
				baleObject:setFillType(baleFillTypeIndex)
				baleObject:setFillLevel(baleCapacity)
				baleObject:setOwnerFarmId(self.field:getOwner(), true)
				baleObject:register()
				table.insert(self.bales, baleObject)
			end
		end
		local segmentLiters = 0
		local lastSx = nil
		local lastSz = nil
		local lastEx = nil
		local lastEz = nil
		local lastLength = nil
		local segmentFunc = function(sx, sz, ex, ez, segmentLength, headlandIndex, islandIndex, totalCourseLength)
			local length = MathUtil.vector2Length(ex - sx, ez - sz)
			local literPerMeter = litersToDrop / totalCourseLength
			local totalSegmentLiters = length * literPerMeter
			segmentLiters = totalSegmentLiters
			lastSx = sx
			lastSz = sz
			lastEx = ex
			lastEz = ez
			lastLength = length
			while 0 < segmentLiters do
				if segmentLiters <= nextBaleLiters then
					nextBaleLiters = nextBaleLiters - segmentLiters
					segmentLiters = 0
				else
					segmentLiters = math.abs(nextBaleLiters - segmentLiters)
					local percent = 1 - segmentLiters / totalSegmentLiters
					nextBaleLiters = baleCapacity
					spawnBale(sx, sz, ex, ez, length, percent)
				end
			end
		end
		local finishFunc = function()
			if 0 < segmentLiters then
				spawnBale(lastSx, lastSz, lastEx, lastEz, lastLength, 1)
			end
			self.finishedBaleSpawning = true
		end
		FieldCourseIterator.new(x, z, fieldCourseSettings, segmentFunc, finishFunc)
	end
end
function BaleWrapMission:getFieldPreparingTask()
	local fruitType = FruitType.GRASS
	local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)
	local fieldPreparingTask = FieldUpdateTask.new()
	fieldPreparingTask:setArea(self.field:getDensityMapPolygon())
	fieldPreparingTask:setField(self.field)
	fieldPreparingTask:setFruit(fruitType, fruitTypeDesc.cutState)
	if fruitTypeDesc.harvestGroundType ~= nil then
		fieldPreparingTask:setGroundType(fruitTypeDesc.harvestGroundType)
	end
	return fieldPreparingTask
end
function BaleWrapMission:getIsPrepared()
	if not BaleWrapMission:superClass().getIsPrepared(self) then
		return false
	else
		return self.finishedBaleSpawning
	end
end
function BaleWrapMission:finishField()
	if self.isServer then
		for _, bale in ipairs(self.bales) do
			bale:delete()
		end
		self.bales = {}
	end
	BaleWrapMission:superClass().finishField(self)
end
function BaleWrapMission:update(dt)
	if self.isServer and self.balesToLoadByUniqueId ~= nil then
		for _, baleUniqueId in ipairs(self.balesToLoadByUniqueId) do
			local bale = g_currentMission.itemSystem:getItemByUniqueId(baleUniqueId)
			if bale == nil then
				continue
			end
			table.insert(self.bales, bale)
		end
		self.balesToLoadByUniqueId = nil
		local numLoadedBales = #self.bales
		if numLoadedBales ~= self.numOfBales then
			Logging.error("Could not load all bales from savegame")
			self.numOfBales = numLoadedBales
		end
	end
	BaleWrapMission:superClass().update(self, dt)
end
function BaleWrapMission:getCompletion()
	local wrapStateSum = 0
	local completion = 0
	local allDropped = true
	for _, bale in ipairs(self.bales) do
		wrapStateSum = wrapStateSum + bale.wrappingState
		if bale:getIsMounted() then
			allDropped = false
		end
	end
	if self.balesToLoadByUniqueId == nil then
		local totalBaleWrapState = 1
		local numBales = #self.bales
		if 0 < numBales then
			totalBaleWrapState = wrapStateSum / numBales
		end
		local percentage = totalBaleWrapState * 0.99
		if totalBaleWrapState == 1 and allDropped then
			percentage = percentage + 0.01
		end
		completion = percentage
	end
	return completion
end
function BaleWrapMission:getRewardPerHa()
	return 1
end
function BaleWrapMission:getReward()
	local data = g_missionManager:getMissionTypeDataByName(BaleWrapMission.NAME)
	local difficultyMultiplier = 1.3 - 0.1 * g_currentMission.missionInfo.economicDifficulty
	local base = BaleWrapMission:superClass().getReward(self)
	local reward = data.rewardPerBale * self.numOfBales
	return base + reward * difficultyMultiplier
end
function BaleWrapMission:getDetails()
	local details = BaleWrapMission:superClass().getDetails(self)
	local isRoundBale = g_baleManager:getIsRoundBale(self.baleTypeIndex)
	local baleType = nil
	if isRoundBale then
		baleType = g_i18n:getText("contract_details_bale_type_round")
	else
		baleType = g_i18n:getText("contract_details_bale_type_square")
	end
	table.insert(details, { value = baleType, title = g_i18n:getText("contract_details_bale_type") })
	return details
end
function BaleWrapMission:getVehicleVariant()
	local isRoundBale = g_baleManager:getIsRoundBale(self.baleTypeIndex)
	if isRoundBale then
		return "ROUNDBALE"
	else
		return "SQUAREBALE"
	end
end
function BaleWrapMission:getVariant()
	local isRoundBale = g_baleManager:getIsRoundBale(self.baleTypeIndex)
	if isRoundBale then
		return "ROUNDBALER"
	else
		return "SQUAREBALER"
	end
end
function BaleWrapMission:getMissionTypeName()
	return BaleWrapMission.NAME
end
function BaleWrapMission:validate(event)
	if not BaleWrapMission:superClass().validate(self, event) then
		return false
	elseif not self:getIsFinished() and not BaleWrapMission.isAvailableForField(self.field, self) then
		return false
	else
		return true
	end
end
function BaleWrapMission.loadMapData(xmlFile, key, baseDirectory)
	local data = g_missionManager:getMissionTypeDataByName(BaleWrapMission.NAME)
	data.rewardPerBale = xmlFile:getFloat(key .. "#rewardPerBale", 300)
	return true
end
function BaleWrapMission.tryGenerateMission()
	if BaleWrapMission.canRun() then
		local field = g_fieldManager:getFieldForMission()
		if field == nil then
			return
		end
		if field.currentMission ~= nil then
			return
		end
		if not BaleWrapMission.isAvailableForField(field, nil) then
			return
		end
		local spawnRoundbales = 0.5 < math.random()
		local baleTypeIndex = nil
		if spawnRoundbales then
			baleTypeIndex = g_baleManager:getBaleIndex(FillType.GRASS_WINDROW, true, 1.2, 0, 0, 1.5, "")
		else
			baleTypeIndex = g_baleManager:getBaleIndex(FillType.GRASS_WINDROW, false, 1.2, 0.9, 1.8, 0, "")
		end
		if baleTypeIndex == nil then
			return
		end
		local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(FruitType.GRASS)
		local litersPerSqm = fruitTypeDesc.literPerSqm
		local fieldSizeSqm = MathUtil.haToSqm(field:getAreaHa())
		local baleCapacity = g_baleManager:getBaleCapacityByBaleIndex(baleTypeIndex, FillType.GRASS_WINDROW)
		local litersToDrop = fieldSizeSqm * litersPerSqm
		local numOfBales = math.floor(litersToDrop / baleCapacity)
		if numOfBales == 0 then
			return
		end
		local mission = BaleWrapMission.new(true, g_client ~= nil)
		if mission:init(field, baleTypeIndex, numOfBales) then
			mission:setDefaultEndDate()
			return mission
		end
		mission:delete()
	end
	return nil
end
function BaleWrapMission.isAvailableForField(field, mission)
	if mission == nil then
		local fieldState = field:getFieldState()
		if not fieldState.isValid then
			return false
		end
		local fruitTypeIndex = fieldState.fruitTypeIndex
		if fruitTypeIndex ~= FruitType.GRASS then
			return false
		end
		local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
		local growthState = fieldState.growthState
		if not fruitTypeDesc:getIsHarvestable(growthState) then
			return false
		end
	end
	local environment = g_currentMission.environment
	if environment ~= nil and environment.currentSeason == Season.WINTER then
		return false
	end
	return true
end
function BaleWrapMission.canRun()
	local data = g_missionManager:getMissionTypeDataByName(BaleWrapMission.NAME)
	if data.maxNumInstances <= data.numInstances then
		return false
	else
		return true
	end
end
g_missionManager:registerMissionType(BaleWrapMission, BaleWrapMission.NAME, 2)
