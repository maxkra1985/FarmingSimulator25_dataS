FarmlandManager = {}
FarmlandManager.NO_OWNER_FARM_ID = 0
FarmlandManager.NOT_BUYABLE_FARM_ID = GS_IS_MOBILE_VERSION and 15 or 255
local FarmlandManager_mt = Class(FarmlandManager, AbstractManager)
g_xmlManager:addCreateSchemaFunction(function()
	FarmlandManager.xmlSchema = XMLSchema.new("farmlands")
end)
g_xmlManager:addInitSchemaFunction(function()
	Mission00.xmlSchema:register(XMLValueType.STRING, "map.farmlands#filename", "Filename of the farmland definition config")
	local schema = FarmlandManager.xmlSchema
	schema:register(XMLValueType.STRING, "map.farmlands#infoLayer", "Name of the info layer", nil, false)
	schema:register(XMLValueType.STRING, "map.farmlands#densityMapFilename", "Filename of the info layer", nil, false)
	schema:register(XMLValueType.INT, "map.farmlands#numChannels", "Number of channels of the info layer", 8, false)
	schema:register(XMLValueType.FLOAT, "map.farmlands#pricePerHa", "Price per Ha", 60000, false)
	Farmland.registerXMLPaths(schema, "map.farmlands.farmland(?)")
end)
function FarmlandManager.new(customMt)
	local self = AbstractManager.new(customMt or FarmlandManager_mt)
	return self
end
function FarmlandManager:initDataStructures()
	self.farmlands = {}
	self.sortedFarmlands = {}
	self.sortedFarmlandIds = {}
	self.farmlandMapping = {}
	self.localMap = nil
	self.localMapWidth = 0
	self.localMapHeight = 0
	self.numberOfBits = 8
end
function FarmlandManager:loadMapData(xmlFile)
	FarmlandManager:superClass().loadMapData(self)
	return XMLUtil.loadDataFromMapXML(xmlFile, "farmlands", g_currentMission.baseDirectory, self, self.loadFarmlandData)
end
function FarmlandManager:loadFarmlandData(xmlFileHandle)
	local xmlFile = XMLFile.wrap(xmlFileHandle, FarmlandManager.xmlSchema)
	self.isLoadedFromTerrain = true
	local infoLayer = nil
	local infoLayerName = xmlFile:getValue("map.farmlands#infoLayer")
	if infoLayerName ~= nil then
		infoLayer = getInfoLayerFromTerrain(g_terrainNode, infoLayerName)
		if infoLayer == nil or infoLayer == 0 then
			Logging.xmlWarning(xmlFile, "No info layer '%s' defined on terrain!", infoLayerName)
		end
	end
	local bitVectorMapFilename = nil
	if infoLayer == nil then
		bitVectorMapFilename = xmlFile:getValue("map.farmlands#densityMapFilename")
		if bitVectorMapFilename == nil then
			Logging.xmlWarning(xmlFile, "Loading farmland file '%s' failed! Missing densityMapFilename", bitVectorMapFilename)
			return false
		end
		bitVectorMapFilename = Utils.getFilename(bitVectorMapFilename, g_currentMission.baseDirectory)
		local numberOfBits = xmlFile:getValue("map.farmlands#numChannels") or 8
		infoLayer = createBitVectorMap("FarmlandMap")
		local success = loadBitVectorMapFromFile(infoLayer, bitVectorMapFilename, numberOfBits)
		if not success then
			Logging.xmlWarning(xmlFile, "Loading farmland file '%s' failed!", bitVectorMapFilename)
			xmlFile:delete()
			return false
		end
		self.isLoadedFromTerrain = false
	end
	self.pricePerHa = xmlFile:getValue("map.farmlands#pricePerHa") or 60000
	FarmlandManager.NOT_BUYABLE_FARM_ID = 2 ^ self.numberOfBits - 1
	self.localMap = infoLayer
	self.numberOfBits = getBitVectorMapNumChannels(self.localMap)
	self.localMapWidth, self.localMapHeight = getBitVectorMapSize(self.localMap)
	local farmlandSizeMapping = {}
	local farmlandCenterData = {}
	local farmlandBoundingBox = {}
	local numOfFarmlands = 0
	local maxFarmlandId = 0
	local missingFarmlandDefinitions = false
	for x = 0, self.localMapWidth - 1 do
		for y = 0, self.localMapHeight - 1 do
			local value = getBitVectorMapPoint(self.localMap, x, y, 0, self.numberOfBits)
			if 0 < value then
				if self.farmlandMapping[value] == nil then
					farmlandSizeMapping[value] = 0
					farmlandCenterData[value] = { sumPosX = 0, sumPosZ = 0 }
					farmlandBoundingBox[value] = { minX = math.huge, minZ = math.huge, maxX = -math.huge, maxZ = -math.huge }
					self.farmlandMapping[value] = FarmlandManager.NO_OWNER_FARM_ID
					numOfFarmlands = numOfFarmlands + 1
					maxFarmlandId = math.max(value, maxFarmlandId)
				end
				farmlandSizeMapping[value] = farmlandSizeMapping[value] + 1
				farmlandCenterData[value].sumPosX = farmlandCenterData[value].sumPosX + (x - 0.5)
				farmlandCenterData[value].sumPosZ = farmlandCenterData[value].sumPosZ + (y - 0.5)
				local boundingBox = farmlandBoundingBox[value]
				boundingBox.minX = math.min(boundingBox.minX, x - 0.5)
				boundingBox.minZ = math.min(boundingBox.minZ, y - 0.5)
				boundingBox.maxX = math.max(boundingBox.maxX, x + 0.5)
				boundingBox.maxZ = math.max(boundingBox.maxZ, y + 0.5)
			else
				missingFarmlandDefinitions = true
			end
		end
	end
	if missingFarmlandDefinitions then
		Logging.xmlWarning(xmlFile, "Farmland-Id was not set for all pixels in farmland-infoLayer!")
	end
	local isNewSavegame = not g_currentMission.missionInfo.isValid
	for _, key in xmlFile:iterator("map.farmlands.farmland") do
		local farmland = Farmland.new()
		if farmland:load(xmlFile, key) and self.farmlands[farmland.id] == nil then
			if self.farmlandMapping[farmland.id] ~= nil then
				self.farmlands[farmland.id] = farmland
				table.insert(self.sortedFarmlands, farmland)
				table.insert(self.sortedFarmlandIds, farmland.id)
				local shouldAddDefaults = isNewSavegame and g_currentMission.missionInfo.hasInitiallyOwnedFarmlands and not g_currentMission.missionDynamicInfo.isMultiplayer
				if shouldAddDefaults and (g_currentMission:getIsServer() and farmland.defaultFarmProperty) then
					self:setLandOwnership(farmland.id, FarmManager.SINGLEPLAYER_FARM_ID, true)
				end
			else
				if self.farmlandMapping[farmland.id] == nil then
					Logging.xmlError(xmlFile, "Farmland-Id '%s' not defined in farmland info layer. Skipping farmland definition!", farmland.id)
				end
				if self.farmlands[farmland.id] ~= nil then
					Logging.xmlError(xmlFile, "Farmland-id '%s' already exists! Ignore it!", farmland.id)
				end
				farmland:delete()
			end
		end
	end
	for index, _ in pairs(self.farmlandMapping) do
		if index == FarmlandManager.NOT_BUYABLE_FARM_ID then
			continue
		end
		if self.farmlands[index] == nil then
			Logging.xmlError(xmlFile, "Farmland-Id '%d' not defined in farmland xml file!", index)
		end
	end
	local transformFactor = g_currentMission.terrainSize / self.localMapWidth
	local pixelToSqm = transformFactor * transformFactor
	for id, farmland in pairs(self.farmlands) do
		local ha = MathUtil.areaToHa(farmlandSizeMapping[id], pixelToSqm)
		farmland:setArea(ha)
		farmland:addMapHotspot()
		if farmland.xWorldPos == nil then
			local posX = (farmlandCenterData[id].sumPosX / farmlandSizeMapping[id] - self.localMapWidth * 0.5) * transformFactor
			local posZ = (farmlandCenterData[id].sumPosZ / farmlandSizeMapping[id] - self.localMapHeight * 0.5) * transformFactor
			farmland:setIndicatorPosition(posX, posZ)
		end
		local boundingBox = farmlandBoundingBox[id]
		boundingBox.minX = (boundingBox.minX - self.localMapWidth * 0.5) * transformFactor
		boundingBox.minZ = (boundingBox.minZ - self.localMapHeight * 0.5) * transformFactor
		boundingBox.maxX = (boundingBox.maxX - self.localMapWidth * 0.5) * transformFactor
		boundingBox.maxZ = (boundingBox.maxZ - self.localMapHeight * 0.5) * transformFactor
		farmland:setBoundingBox(boundingBox)
	end
	g_messageCenter:subscribe(MessageType.FARM_DELETED, self.farmDestroyed, self)
	g_messageCenter:subscribe(MessageType.FARM_SETTINGS_CHANGED, self.onFarmSettingsChanged, self)
	if g_addCheatCommands then
		if g_currentMission:getIsServer() then
			addConsoleCommand("gsFarmlandBuy", "Buys farmland with given id", "consoleCommandBuyFarmland", self)
			addConsoleCommand("gsFarmlandBuyAll", "Buys all farmlands", "consoleCommandBuyAllFarmlands", self)
			addConsoleCommand("gsFarmlandSell", "Sells farmland with given id", "consoleCommandSellFarmland", self)
			addConsoleCommand("gsFarmlandSellAll", "Sells all farmlands", "consoleCommandSellAllFarmlands", self)
		end
		addConsoleCommand("gsFarmlandShow", "Show farmlands", "consoleCommandShowFarmlands", self)
	end
	xmlFile:delete()
	return true
end
function FarmlandManager:unloadMapData()
	removeConsoleCommand("gsFarmlandBuy")
	removeConsoleCommand("gsFarmlandBuyAll")
	removeConsoleCommand("gsFarmlandSell")
	removeConsoleCommand("gsFarmlandSellAll")
	removeConsoleCommand("gsFarmlandShow")
	g_messageCenter:unsubscribeAll(self)
	if self.localMap ~= nil then
		if not self.isLoadedFromTerrain then
			delete(self.localMap)
		end
		self.localMap = nil
	end
	if self.farmlands ~= nil then
		for _, farmland in pairs(self.farmlands) do
			farmland:delete()
		end
	end
	FarmlandManager:superClass().unloadMapData(self)
end
function FarmlandManager:saveToXMLFile(xmlFilename)
	local xmlFile = createXMLFile("farmlandsXML", xmlFilename, "farmlands")
	if xmlFile == 0 then
		Logging.error("Failed to create farmlands xml file")
		return false
	else
		local index = 0
		for farmlandId, farmId in pairs(self.farmlandMapping) do
			local farmlandKey = string.format("farmlands.farmland(%d)", index)
			setXMLInt(xmlFile, farmlandKey .. "#id", farmlandId)
			setXMLInt(xmlFile, farmlandKey .. "#farmId", Utils.getNoNil(farmId, FarmlandManager.NO_OWNER_FARM_ID))
			index = index + 1
		end
		saveXMLFile(xmlFile)
		delete(xmlFile)
		return true
	end
end
function FarmlandManager:loadFromXMLFile(xmlFilename)
	if xmlFilename == nil then
		return false
	end
	local xmlFile = loadXMLFile("farmlandXML", xmlFilename)
	if xmlFile == 0 then
		return false
	else
		local farmlandCounter = 0
		while true do
			local key = string.format("farmlands.farmland(%d)", farmlandCounter)
			local farmlandId = getXMLInt(xmlFile, key .. "#id")
			if farmlandId == nil then
				break
			end
			local farmId = getXMLInt(xmlFile, key .. "#farmId")
			if FarmlandManager.NO_OWNER_FARM_ID < farmId then
				self:setLandOwnership(farmlandId, farmId, true)
			end
			farmlandCounter = farmlandCounter + 1
		end
		delete(xmlFile)
		g_farmManager:mergeFarmlandsForSingleplayer()
		return true
	end
end
function FarmlandManager:delete() end
function FarmlandManager:getLocalMap()
	return self.localMap
end
function FarmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, worldPosX, worldPosZ)
	if farmId == FarmlandManager.NO_OWNER_FARM_ID or farmId == nil then
		return false
	end
	local farmlandId = self:getFarmlandIdAtWorldPosition(worldPosX, worldPosZ)
	return self.farmlandMapping[farmlandId] == farmId
end
function FarmlandManager:getIsOwnedByFarmAlongLine(farmId, worldPosX1, worldPosZ1, worldPosX2, worldPosZ2)
	if farmId == FarmlandManager.NO_OWNER_FARM_ID or farmId == nil then
		return false
	end
	if self.localMap == nil then
		return false
	end
	local length = MathUtil.vector2Length(worldPosX1 - worldPosX2, worldPosZ1 - worldPosZ2)
	if length == 0 then
		return self:getIsOwnedByFarmAtWorldPosition(farmId, worldPosX1, worldPosZ1)
	else
		local bitmapToWorld = g_currentMission.terrainSize / self.localMapWidth
		local step = bitmapToWorld / length * 2
		for alpha = 0, 1, step do
			local x, z = MathUtil.vector2Lerp(worldPosX1, worldPosZ1, worldPosX2, worldPosZ2, alpha)
			local localPosX, localPosZ = self:convertWorldToLocalPosition(x, z)
			local farmlandId = getBitVectorMapPoint(self.localMap, localPosX, localPosZ, 0, self.numberOfBits)
			if self.farmlandMapping[farmlandId] == farmId then
				continue
			end
			return false
		end
		return true
	end
end
function FarmlandManager:getCanAccessLandAtWorldPosition(farmId, worldPosX, worldPosZ)
	if farmId == FarmlandManager.NO_OWNER_FARM_ID or farmId == nil then
		return false
	end
	local farmlandId = self:getFarmlandIdAtWorldPosition(worldPosX, worldPosZ)
	local ownerFarmId = self.farmlandMapping[farmlandId]
	if ownerFarmId == farmId then
		return true
	else
		return g_currentMission.accessHandler:canFarmAccessOtherId(farmId, ownerFarmId)
	end
end
function FarmlandManager:getFarmlandOwner(farmlandId)
	if farmlandId == nil or self.farmlandMapping[farmlandId] == nil then
		return FarmlandManager.NO_OWNER_FARM_ID
	end
	return self.farmlandMapping[farmlandId]
end
function FarmlandManager:getFarmlandIdAtWorldPosition(worldPosX, worldPosZ)
	if self.localMap == nil then
		return FarmlandManager.NO_OWNER_FARM_ID
	else
		local localPosX, localPosZ = self:convertWorldToLocalPosition(worldPosX, worldPosZ)
		return getBitVectorMapPoint(self.localMap, localPosX, localPosZ, 0, self.numberOfBits)
	end
end
function FarmlandManager:getFarmlandAtWorldPosition(worldPosX, worldPosZ)
	local farmlandId = self:getFarmlandIdAtWorldPosition(worldPosX, worldPosZ)
	return self.farmlands[farmlandId]
end
function FarmlandManager:getOwnerIdAtWorldPosition(worldPosX, worldPosZ)
	local farmlandId = self:getFarmlandIdAtWorldPosition(worldPosX, worldPosZ)
	return self:getFarmlandOwner(farmlandId)
end
function FarmlandManager:getIsValidFarmlandId(farmlandId)
	if farmlandId == nil or farmlandId == 0 or farmlandId < 0 then
		return false
	end
	if self:getFarmlandById(farmlandId) == nil then
		return false
	else
		return true
	end
end
function FarmlandManager:setLandOwnership(farmlandId, farmId, loadFromSavegame)
	if not self:getIsValidFarmlandId(farmlandId) then
		return false
	end
	if farmId == nil or farmId < FarmlandManager.NO_OWNER_FARM_ID or farmId == FarmlandManager.NOT_BUYABLE_FARM_ID then
		return false
	end
	local farmland = self:getFarmlandById(farmlandId)
	if farmland == nil then
		Logging.warning("Farmland id %d not defined in map!", farmlandId)
		return false
	else
		if loadFromSavegame == nil then
			loadFromSavegame = false
		end
		self.farmlandMapping[farmlandId] = farmId
		farmland:setOwnerFarmId(farmId)
		g_messageCenter:publish(MessageType.FARMLAND_OWNER_CHANGED, farmlandId, farmId, loadFromSavegame)
		return true
	end
end
function FarmlandManager:getFarmlandById(farmlandId)
	return self.farmlands[farmlandId]
end
function FarmlandManager:getFarmlands()
	return self.farmlands
end
function FarmlandManager:getPricePerHa()
	return self.pricePerHa
end
function FarmlandManager:getOwnedFarmlandIdsByFarmId(id)
	local farmlandIds = {}
	for farmlandId, farmId in pairs(self.farmlandMapping) do
		if farmId == id then
			table.insert(farmlandIds, farmlandId)
		end
	end
	return farmlandIds
end
function FarmlandManager:getNumOwnedFarmlandIdsByFarmId(id)
	local num = 0
	for farmlandId, farmId in pairs(self.farmlandMapping) do
		if farmId == id then
			num = num + 1
		end
	end
	return num
end
function FarmlandManager:convertWorldToLocalPosition(worldPosX, worldPosZ)
	local terrainSize = g_currentMission.terrainSize
	return math.floor(self.localMapWidth * (worldPosX + terrainSize * 0.5) / terrainSize), math.floor(self.localMapHeight * (worldPosZ + terrainSize * 0.5) / terrainSize)
end
function FarmlandManager:farmDestroyed(farmId)
	for _, farmland in pairs(self:getFarmlands()) do
		if self:getFarmlandOwner(farmland.id) == farmId then
			self:setLandOwnership(farmland.id, FarmlandManager.NO_OWNER_FARM_ID)
		end
	end
end
function FarmlandManager:onFarmSettingsChanged(farmId)
	for index, farmlandId in pairs(self:getOwnedFarmlandIdsByFarmId(farmId)) do
		local farmland = self:getFarmlandById(farmlandId)
		local hotspot = farmland ~= nil and farmland:getMapHotspot() or nil
		if hotspot == nil then
			continue
		end
		hotspot:updateColors()
	end
end
function FarmlandManager:consoleCommandBuyFarmland(farmlandIdStr)
	if (g_currentMission:getIsServer() or g_currentMission.isMasterUser) and g_currentMission:getIsClient() then
		local farmlandId = nil
		if farmlandIdStr ~= nil then
			farmlandId = tonumber(farmlandIdStr)
			if farmlandId == nil or self:getFarmlandById(farmlandId) == nil then
				printError(string.format("Error: Invalid farmland id %q.", farmlandIdStr))
				return "Use gsFarmlandBuy <farmlandId>"
			end
		else
			local x, _, z = g_localPlayer:getPosition()
			farmlandId = self:getFarmlandIdAtWorldPosition(x, z)
			if farmlandId == nil then
				printError("Error: Unable to retrieve farmland id at player position, provide farmland as argument instead")
				return
			end
		end
		local farmId = g_localPlayer.farmId
		if self:getFarmlandOwner(farmlandId) == farmId then
			printError(string.format("Error: Farmland %d already owned by farm %d", farmlandId, farmId))
			return
		else
			g_client:getServerConnection():sendEvent(FarmlandStateEvent.new(farmlandId, farmId, 0))
			return "Bought farmland " .. farmlandId
		end
	end
	return "Command not allowed"
end
function FarmlandManager:consoleCommandBuyAllFarmlands()
	if (g_currentMission:getIsServer() or g_currentMission.isMasterUser) and g_currentMission:getIsClient() then
		local farmId = g_localPlayer.farmId
		for k, _ in pairs(g_farmlandManager:getFarmlands()) do
			g_client:getServerConnection():sendEvent(FarmlandStateEvent.new(k, farmId, 0))
		end
		return "Bought all farmlands"
	end
	return "Command not allowed"
end
function FarmlandManager:consoleCommandSellFarmland(farmlandIdStr)
	if (g_currentMission:getIsServer() or g_currentMission.isMasterUser) and g_currentMission:getIsClient() then
		local farmlandId = nil
		if farmlandIdStr ~= nil then
			farmlandId = tonumber(farmlandIdStr)
			if farmlandId == nil or self:getFarmlandById(farmlandId) == nil then
				printError(string.format("Error: Invalid farmland id %q", farmlandIdStr))
				return "Use gsFarmlandSell <farmlandId>"
			end
		else
			local x, _, z = g_localPlayer:getPosition()
			farmlandId = self:getFarmlandIdAtWorldPosition(x, z)
			if farmlandId == nil then
				printError("Error: Unable to retrieve farmland id at player position, provide farmland as argument instead")
				return
			end
		end
		if self:getFarmlandOwner(farmlandId) == FarmlandManager.NO_OWNER_FARM_ID then
			printError(string.format("Error: Farmland %d not owned by anyone", farmlandId))
			return
		else
			g_client:getServerConnection():sendEvent(FarmlandStateEvent.new(farmlandId, FarmlandManager.NO_OWNER_FARM_ID, 0))
			return "Sold farmland " .. farmlandId
		end
	end
	return "Command not allowed"
end
function FarmlandManager:consoleCommandSellAllFarmlands()
	if (g_currentMission:getIsServer() or g_currentMission.isMasterUser) and g_currentMission:getIsClient() then
		for k, _ in pairs(g_farmlandManager:getFarmlands()) do
			g_client:getServerConnection():sendEvent(FarmlandStateEvent.new(k, FarmlandManager.NO_OWNER_FARM_ID, 0))
		end
		return "Sold all farmlands"
	end
	return "Command not allowed"
end
function FarmlandManager:consoleCommandShowFarmlands()
	if not g_debugManager:hasDrawable(self) then
		g_debugManager:addDrawable(self)
		return "showFarmlands = true\nUse F5 to enter debug mode for enabling overlay"
	else
		g_debugManager:removeDrawable(self)
		self.debugFarmlandColors = nil
		return "showFarmlands = false"
	end
end
function FarmlandManager:drawDebug()
	local x, _, z = getWorldTranslation(g_cameraManager:getActiveCamera())
	if self.debugFarmlandColors == nil then
		self.debugFarmlandColors = {}
		for farmlandId, _ in pairs(self.farmlands) do
			local color = DebugUtil.getDebugColor(farmlandId)
			color.a = 0.15
			self.debugFarmlandColors[farmlandId] = color
		end
	end
	if g_localPlayer:getCurrentVehicle() ~= nil then
		local object = g_localPlayer:getCurrentVehicle()
		if g_localPlayer:getCurrentVehicle().selectedImplement ~= nil then
			object = g_localPlayer:getCurrentVehicle().selectedImplement.object
		end
		x, _, z = getWorldTranslation(object.components[1].node)
	end
	local terrainSizeHalf = g_currentMission.terrainSize / 2
	local bitmapToWorld = g_currentMission.terrainSize / self.localMapWidth
	local worldToBitmap = self.localMapWidth / g_currentMission.terrainSize
	local bitmapX = math.floor((x + terrainSizeHalf) * worldToBitmap)
	local bitmapZ = math.floor((z + terrainSizeHalf) * worldToBitmap)
	local range = 25
	local bitmapMinX = math.max(bitmapX - 25, 0)
	local bitmapMinZ = math.max(bitmapZ - 25, 0)
	local bitmapMaxX = math.min(bitmapX + 25, self.localMapWidth - 1)
	local bitmapMaxZ = math.min(bitmapZ + 25, self.localMapWidth - 1)
	local farmlandsLegend = {}
	for bitmapStepZ = bitmapMinZ, bitmapMaxZ do
		for bitmapStepX = bitmapMinX, bitmapMaxX do
			local farmland = self.farmlands[getBitVectorMapPoint(self.localMap, bitmapStepX, bitmapStepZ, 0, self.numberOfBits)]
			if farmland then
				local color = self.debugFarmlandColors[farmland.id]
				farmlandsLegend[farmland] = color
				local worldX = bitmapStepX * bitmapToWorld - terrainSizeHalf
				local worldZ = bitmapStepZ * bitmapToWorld - terrainSizeHalf
				DebugPlane.renderWithPositions(worldX, 0, worldZ, worldX, 0, worldZ + bitmapToWorld, worldX + bitmapToWorld, 0, worldZ, color, true, true)
			end
		end
	end
	local fontSize = 0.015
	local i = 0
	if next(farmlandsLegend) ~= nil then
		for farmland, color in pairs(farmlandsLegend) do
			local defaultPropertyStr = farmland.defaultFarmProperty and " | defaultFarmProperty" or ""
			local text = string.format("Farmland %d | Owner: %s | Area: %.3fha | Price: %d%s", farmland.id, self:getFarmlandOwner(farmland.id), farmland.areaInHa, farmland.price, defaultPropertyStr)
			setTextColor(color[1], color[2], color[3], 1)
			renderText(0.3, 0.97 - i * 0.015, 0.015, text)
			setTextColor(1, 1, 1, 1)
			i = i + 1
		end
	else
		renderText(0.3, 0.97 - i * 0.015, 0.015, "No farmlands defined in vicinity")
	end
end
g_farmlandManager = FarmlandManager.new()
