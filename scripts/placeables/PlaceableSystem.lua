g_xmlManager:addInitSchemaFunction(function()
	local schema = Mission00.xmlSchema
	schema:register(XMLValueType.VECTOR_2, "map.placeableSystem.boundary.point(?)#translation", "Translation of the point")
end)
PlaceableSystem = {}
PlaceableSystem.TERRAIN_BORDER = 40
PlaceableSystem.UNIQUE_ID_PREFIX = "placeable"
local PlaceableSystem_mt = Class(PlaceableSystem)
function PlaceableSystem.new(mission, customMt)
	local self = setmetatable({}, customMt or PlaceableSystem_mt)
	self.mission = mission
	self.placeables = {}
	self.placableByUniqueId = {}
	self.pendingPlaceableLoadingData = {}
	self.preplacedPlaceableData = {}
	self.uniqueIdToReplacedPlaceableData = {}
	self.placeablesToDelete = {}
	self.weatherStations = {}
	self.farmhouses = {}
	self.bunkerSilos = {}
	self.boundary = nil
	self.version = 1
	self.isReloadRunning = false
	if self.mission:getIsServer() and g_addTestCommands then
		addConsoleCommand("gsPlaceablesDeleteAll", "Deletes all placeables", "consoleCommandDeleteAllPlaceables", self, nil, true)
		addConsoleCommand("gsPlaceablesReloadAll", "Reloads all placeables", "consoleCommandReloadAllPlaceables", self)
		addConsoleCommand("gsPlaceablesLoadAll", "Loads all placeables", "consoleCommandLoadAllPlaceables", self, nil, true)
	end
	if g_addTestCommands then
		addConsoleCommand("gsPlaceablesPendingLoadings", "Prints the pending placeable loadings", "consoleCommandPrintPendingLoadings", self)
		addConsoleCommand("gsPlaceableSystemDrawBoundary", "Draws the placeable map boundaries", "consoleCommandDrawMapBoundaries", self)
	end
	return self
end
function PlaceableSystem:loadMapData(xmlFileHandle, missionInfo, baseDirectory)
	local xmlFile = XMLFile.wrap(xmlFileHandle)
	if xmlFile ~= nil then
		if xmlFile:hasProperty("map.placeableSystem.boundary") then
			local boundary = {}
			for _, pointKey in xmlFile:iterator("map.placeableSystem.boundary.point") do
				local point = xmlFile:getVector(pointKey .. "#translation", nil, 2)
				if point == nil then
					continue
				end
				table.insert(boundary, point)
			end
			if 3 <= #boundary then
				self.boundary = boundary
			else
				Logging.error("PlaceableSystem: Boundary must have at least 3 points, found %d", #boundary)
			end
		end
		xmlFile:delete()
	end
end
function PlaceableSystem:delete()
	for i = #self.pendingPlaceableLoadingData, 1, -1 do
		self.pendingPlaceableLoadingData[i]:cancelLoading()
	end
	for k, placeable in pairs(self.placeablesToDelete) do
		placeable:delete(true)
		self.placeablesToDelete[k] = nil
	end
	for i = #self.placeables, 1, -1 do
		local placeable = self.placeables[i]
		placeable:delete(true)
	end
	if self.savegameXMLFile ~= nil then
		self.savegameXMLFile:delete()
		self.savegameXMLFile = nil
	end
	self.mission = nil
	self.boundary = nil
	self.placeables = {}
	self.savegameIdToPlaceable = {}
	self.farmhouses = {}
	self.bunkerSilos = {}
	self.preplacedPlaceableData = {}
	self.uniqueIdToReplacedPlaceableData = {}
	removeConsoleCommand("gsPlaceablesDeleteAll")
	removeConsoleCommand("gsPlaceablesReloadAll")
	removeConsoleCommand("gsPlaceablesLoadAll")
	removeConsoleCommand("gsPlaceablesPendingLoadings")
	removeConsoleCommand("gsPlaceableSystemDrawBoundary")
end
function PlaceableSystem:deleteAll()
	local numDeleted = #self.placeables
	for i = #self.placeables, 1, -1 do
		local placeable = self.placeables[i]
		placeable:delete()
	end
	return numDeleted
end
function PlaceableSystem:draw()
	if PlaceableSystem.DEBUG_DRAW_BOUNDARIES then
		if self.boundary ~= nil then
			for i = 1, #self.boundary - 1 do
				local point = self.boundary[i]
				local nextPoint = self.boundary[i + 1]
				local pH = getTerrainHeightAtWorldPos(g_terrainNode, point[1], 0, point[2])
				local npH = getTerrainHeightAtWorldPos(g_terrainNode, nextPoint[1], 0, nextPoint[2])
				drawDebugLine(point[1], pH, point[2], 1, 0, 0, nextPoint[1], npH, nextPoint[2], 1, 0, 0, false)
			end
		else
			local limit = g_currentMission.terrainSize * 0.5 - PlaceableSystem.TERRAIN_BORDER
			local e1x = -limit
			local e1z = -limit
			local e2x = limit
			local e2z = -limit
			local e3x = limit
			local e3z = limit
			local e4x = -limit
			local e4z = limit
			local e1y = getTerrainHeightAtWorldPos(g_terrainNode, e1x, 0, e1z)
			local e2y = getTerrainHeightAtWorldPos(g_terrainNode, e2x, 0, e2z)
			local e3y = getTerrainHeightAtWorldPos(g_terrainNode, e3x, 0, e3z)
			local e4y = getTerrainHeightAtWorldPos(g_terrainNode, e4x, 0, e4z)
			drawDebugLine(e1x, e1y, e1z, 1, 0, 0, e2x, e2y, e2z, 1, 0, 0, false)
			drawDebugLine(e2x, e2y, e2z, 1, 0, 0, e3x, e3y, e3z, 1, 0, 0, false)
			drawDebugLine(e3x, e3y, e3z, 1, 0, 0, e4x, e4y, e4z, 1, 0, 0, false)
			drawDebugLine(e4x, e4y, e4z, 1, 0, 0, e1x, e1y, e1z, 1, 0, 0, false)
		end
	end
end
function PlaceableSystem:limitPositionToBoundary(x, z)
	local newPosX = x
	local newPosZ = z
	if self.boundary == nil then
		local limit = g_currentMission.terrainSize * 0.5 - PlaceableSystem.TERRAIN_BORDER
		newPosX = math.clamp(newPosX, -limit, limit)
		newPosZ = math.clamp(newPosZ, -limit, limit)
	elseif not FieldCourseUtil.getIsPointInsideBoundary(newPosX, newPosZ, self.boundary) then
		newPosX, newPosZ = FieldCourseUtil.getClosestPositionOnBoundary(newPosX, newPosZ, self.boundary)
	end
	if PlaceableSystem.DEBUG_DRAW_BOUNDARIES then
		self:draw()
		local y = getTerrainHeightAtWorldPos(g_terrainNode, newPosX, 0, newPosZ)
		drawDebugArrow(newPosX, y, newPosZ, 0, 0, 1, 0, 1, 0, 0, 1, 0, false)
	end
	return newPosX, newPosZ
end
function PlaceableSystem:getIsInsideBoundary(x, z)
	if self.boundary == nil then
		local limit = g_currentMission.terrainSize * 0.5 - PlaceableSystem.TERRAIN_BORDER
		if x < -limit or limit < x then
			return false
		end
		if z < -limit or limit < z then
			return false
		end
		return true
	else
		return FieldCourseUtil.getIsPointInsideBoundary(x, z, self.boundary)
	end
end
function PlaceableSystem:readStreamPreplacedInfo(streamId, connection)
	local numPreplacedPlaceables = streamReadUInt16(streamId)
	for i = 1, numPreplacedPlaceables do
		local data = self.preplacedPlaceableData[i]
		local isDeleted = streamReadBool(streamId)
		if isDeleted then
			self:deletePreplacedPlaceable(data)
		end
	end
end
function PlaceableSystem:writeStreamPreplacedInfo(streamId, connection)
	streamWriteUInt16(streamId, #self.preplacedPlaceableData)
	for _, data in ipairs(self.preplacedPlaceableData) do
		streamWriteBool(streamId, data.isDeleted)
	end
end
function PlaceableSystem:addMapPlaceableNode(nodeId)
	Logging.devInfo("Adding preplaced map placeable '%s'", getName(nodeId))
	if nodeId == nil then
		Logging.error("No node given for validation")
		return
	end
	if getNumOfChildren(nodeId) == 0 then
		Logging.error("Node '%s' is not a valid preplaced placeable node. No children defined", I3DUtil.getNodePath(nodeId))
		return
	end
	local uniqueId = getUserAttribute(nodeId, "uniqueId")
	if string.isNilOrWhitespace(uniqueId) then
		Logging.error("Node '%s' is not a valid preplaced placeable node. Missing uniqueId attribute", I3DUtil.getNodePath(nodeId))
		return
	end
	local xmlFilename = getUserAttribute(nodeId, "xmlFilename")
	if string.isNilOrWhitespace(xmlFilename) then
		Logging.error("Node '%s' is not a valid preplaced placeable node. Missing xmlFilename attribute", I3DUtil.getNodePath(nodeId))
		return
	end
	xmlFilename = Utils.getFilename(xmlFilename, g_currentMission.loadingMapBaseDirectory)
	local xmlFile = XMLFile.load("Preplaced Placeable", xmlFilename, Placeable.xmlSchema)
	if xmlFile == nil then
		Logging.error("Node '%s' is not a valid preplaced placeable node. Cannot open config xml file", I3DUtil.getNodePath(nodeId))
		return
	end
	xmlFile:delete()
	local boughtWithFarmlandOverwrite = getUserAttribute(nodeId, "boughtWithFarmlandOverwrite") or false
	local customImageFilename = getUserAttribute(nodeId, "customImageFilename")
	local node = getChildAt(nodeId, 0)
	if getNumOfChildren(node) == 0 then
		Logging.error("Node '%s' is not a valid preplaced placeable node. No child nodes for 'placeable' transform group", I3DUtil.getNodePath(nodeId))
	else
		local data = { rootNode = nodeId, node = node, xmlFilename = xmlFilename, uniqueId = uniqueId, boughtWithFarmlandOverwrite = boughtWithFarmlandOverwrite, customImageFilename = customImageFilename }
		data.index = #self.preplacedPlaceableData + 1
		data.foundInSavegame = false
		data.isDeleted = false
		table.insert(self.preplacedPlaceableData, data)
		self.uniqueIdToReplacedPlaceableData[uniqueId] = data
	end
end
function PlaceableSystem:addPlaceable(placeable)
	if placeable == nil or placeable:isa(Placeable) == nil then
		Logging.error("Given object is not a placeable")
		return
	end
	local uniqueId = placeable:getUniqueId()
	if uniqueId ~= nil and self.placableByUniqueId[uniqueId] ~= nil then
		Logging.warning("Tried to add existing placeable with unique id of %s! Existing: %s, new: %s", uniqueId, tostring(self.placableByUniqueId[uniqueId]), tostring(placeable))
		return
	end
	if uniqueId == nil then
		uniqueId = Utils.getUniqueId(placeable, self.placableByUniqueId, PlaceableSystem.UNIQUE_ID_PREFIX)
		placeable:setUniqueId(uniqueId)
	end
	g_messageCenter:publish(MessageType.PLACEABLE_ADDED, placeable)
	table.addElement(self.placeables, placeable)
	self.placableByUniqueId[uniqueId] = placeable
end
function PlaceableSystem:removePlaceable(placeable)
	table.removeElement(self.placeables, placeable)
	local uniqueId = placeable:getUniqueId()
	if uniqueId ~= nil then
		self.placableByUniqueId[uniqueId] = nil
	end
	g_messageCenter:publish(MessageType.PLACEABLE_REMOVED, placeable)
end
function PlaceableSystem:addPreplacedPlaceable(placeable)
	local uniqueId = placeable:getUniqueId()
	local preplacedData = self.uniqueIdToReplacedPlaceableData[uniqueId]
	if preplacedData ~= nil then
		preplacedData.placeable = placeable
		local rootNode = preplacedData.rootNode
		local aiSplineNodePath = getUserAttribute(rootNode, "aiSplines")
		if not string.isNilOrWhitespace(aiSplineNodePath) then
			local aiSplineNode = I3DUtil.indexToObject(rootNode, aiSplineNodePath)
			if aiSplineNode ~= nil then
				for i = 0, getNumOfChildren(aiSplineNode) - 1 do
					local splineNode = getChildAt(aiSplineNode, i)
					local maxWidth, maxWidthType = getUserAttributeValueAndType(splineNode, "maxWidth")
					if maxWidth ~= nil and maxWidthType ~= UserAttributeType.FLOAT then
						maxWidth = nil
						Logging.warning("Preplaced placeable aiSpline node '%s' maxWidth attribute has wrong type. Has to be float type", getName(splineNode))
					end
					local maxTurningRadius, maxTurningRadiusType = getUserAttributeValueAndType(splineNode, "maxTurningRadius")
					if maxTurningRadius ~= nil and maxTurningRadiusType ~= UserAttributeType.FLOAT then
						maxTurningRadius = nil
						Logging.warning("Preplaced placeable aiSpline node '%s' maxTurningRadius attribute has wrong type. Has to be float type", getName(splineNode))
					end
					local maxHeight, maxHeightType = getUserAttributeValueAndType(splineNode, "maxHeight")
					if maxHeight ~= nil and maxHeightType ~= UserAttributeType.FLOAT then
						maxHeight = nil
						Logging.warning("Preplaced placeable aiSpline node '%s' maxHeight attribute has wrong type. Has to be float type", getName(splineNode))
					end
					g_currentMission.aiSystem:addRoadSpline(splineNode, maxWidth, maxTurningRadius, maxHeight)
					if preplacedData.aiSplineNodes == nil then
						preplacedData.aiSplineNodes = {}
					end
					table.insert(preplacedData.aiSplineNodes, splineNode)
				end
			end
		end
	end
end
function PlaceableSystem:removePreplacedPlaceable(placeable)
	local uniqueId = placeable:getUniqueId()
	local preplacedData = self.uniqueIdToReplacedPlaceableData[uniqueId]
	if preplacedData ~= nil then
		preplacedData.placeable = nil
		if preplacedData.aiSplineNodes ~= nil then
			for _, splineNode in ipairs(preplacedData.aiSplineNodes) do
				g_currentMission.aiSystem:removeRoadSpline(splineNode)
			end
		end
		if not placeable.isReloading then
			self:deletePreplacedPlaceable(preplacedData)
		end
	end
end
function PlaceableSystem:deletePreplacedPlaceable(data)
	if entityExists(data.rootNode) then
		Logging.devInfo("PlaceableSystem:deletePreplacedPlaceable - Deleted node '%s'", getName(data.rootNode))
		delete(data.rootNode)
	else
		Logging.devWarning("PlaceableSystem:deletePreplacedPlaceable - entity %d does not exist", data.rootNode)
	end
	data.isDeleted = true
end
function PlaceableSystem:getPreplacedNodeByIndex(index)
	local data = self.preplacedPlaceableData[index]
	if data == nil then
		return nil
	else
		return data.node
	end
end
function PlaceableSystem:getPreplacedFilenameByIndex(index)
	local data = self.preplacedPlaceableData[index]
	if data == nil then
		return nil
	else
		return data.xmlFilename
	end
end
function PlaceableSystem:getPreplacedUniqueIdByIndex(index)
	local data = self.preplacedPlaceableData[index]
	if data == nil then
		return nil
	else
		return data.uniqueId
	end
end
function PlaceableSystem:getPlaceableByUniqueId(uniqueId)
	return self.placableByUniqueId[uniqueId]
end
function PlaceableSystem:getArePlaceablesOnFarmland(farmId, farmlandId, includeBoughtWithFarmland)
	for _, placeable in ipairs(self.placeables) do
		if placeable.ownerFarmId == farmId and ((includeBoughtWithFarmland or not placeable.boughtWithFarmland) and placeable:getIsOnFarmland(farmlandId)) then
			return true
		end
	end
	return false
end
function PlaceableSystem:addPendingPlaceableLoad(placeableLoadingData)
	table.addElement(self.pendingPlaceableLoadingData, placeableLoadingData)
end
function PlaceableSystem:removePendingPlaceableLoad(placeableLoadingData)
	table.removeElement(self.pendingPlaceableLoadingData, placeableLoadingData)
end
function PlaceableSystem:getNumPendingPlaceables()
	return #self.pendingPlaceableLoadingData
end
function PlaceableSystem:canStartMission()
	for i = 1, #self.placeables do
		if self.placeables[i]:getIsSynchronized() then
			continue
		end
		return false
	end
	if 0 < #self.pendingPlaceableLoadingData then
		return false
	else
		return true
	end
end
function PlaceableSystem:addWeatherStation(weatherStation)
	table.addElement(self.weatherStations, weatherStation)
end
function PlaceableSystem:removeWeatherStation(weatherStation)
	table.removeElement(self.weatherStations, weatherStation)
end
function PlaceableSystem:addBunkerSilo(bunkerSilo)
	table.addElement(self.bunkerSilos, bunkerSilo)
end
function PlaceableSystem:removeBunkerSilo(bunkerSilo)
	table.removeElement(self.bunkerSilos, bunkerSilo)
end
function PlaceableSystem:getBunkerSilos()
	return self.bunkerSilos
end
function PlaceableSystem:getExistingPlaceableByXMLFilename(xmlFilename, ownerFarmId, excludeBoughtWithFarmland)
	for _, placeable in ipairs(self.placeables) do
		if placeable.configFileName == xmlFilename then
			if placeable.markedForDeletion then
				continue
			end
			if (ownerFarmId == nil or placeable.ownerFarmId == ownerFarmId) and (not excludeBoughtWithFarmland or not placeable.boughtWithFarmlandSavegameOverwrite) then
				return placeable
			end
		end
	end
	return nil
end
function PlaceableSystem:getHasWeatherStation(farmId)
	for _, weatherStation in ipairs(self.weatherStations) do
		if farmId == nil or weatherStation:getOwnerFarmId() == farmId then
			return true
		end
	end
	return false
end
function PlaceableSystem:addFarmhouse(farmhouse)
	table.addElement(self.farmhouses, farmhouse)
end
function PlaceableSystem:removeFarmhouse(farmhouse)
	table.removeElement(self.farmhouses, farmhouse)
end
function PlaceableSystem:getFarmhouse(farmId)
	for _, farmhouse in ipairs(self.farmhouses) do
		if farmId == nil or farmhouse:getOwnerFarmId() == farmId then
			return farmhouse
		end
	end
	return nil
end
function PlaceableSystem:deleteMarkedPlaceables()
	for k, placeable in pairs(self.placeablesToDelete) do
		placeable:delete(true)
		self.placeablesToDelete[k] = nil
	end
end
function PlaceableSystem:markPlaceableForDeletion(placeable)
	self.placeablesToDelete[placeable] = placeable
end
function PlaceableSystem:save(xmlFilename, usedModNames)
	local xmlFile = XMLFile.create("placeablesXML", xmlFilename, "placeables", Placeable.xmlSchemaSavegame)
	if xmlFile ~= nil then
		self:saveToXML(xmlFile, usedModNames)
		xmlFile:save()
		xmlFile:delete()
	end
end
function PlaceableSystem:saveToXML(xmlFile, usedModNames, savePreplaced)
	if xmlFile ~= nil then
		xmlFile:setValue("placeables#version", self.version)
		savePreplaced = Utils.getNoNil(savePreplaced, true)
		local xmlIndex = 0
		if savePreplaced then
			for _, data in ipairs(self.preplacedPlaceableData) do
				local placeableKey = string.format("placeables.placeable(%d)", xmlIndex)
				xmlFile:setValue(placeableKey .. "#isPreplaced", true)
				xmlFile:setValue(placeableKey .. "#uniqueId", data.uniqueId)
				if data.isDeleted then
					xmlFile:setValue(placeableKey .. "#isDeleted", true)
				end
				if data.boughtWithFarmlandOverwrite then
					xmlFile:setBool(placeableKey .. "#boughtWithFarmlandOverwrite", true)
				end
				if not string.isNilOrWhitespace(data.customImageFilename) then
					xmlFile:setString(placeableKey .. ".customImage#filename", data.customImageFilename)
				end
				if data.placeable ~= nil then
					data.placeable:saveToXMLFile(xmlFile, placeableKey, usedModNames)
				end
				xmlIndex = xmlIndex + 1
			end
		end
		for i, placeable in ipairs(self.placeables) do
			if placeable:getNeedsSaving() then
				if placeable.isPreplaced then
					continue
				end
				self:savePlaceableToXML(placeable, xmlFile, xmlIndex, i, usedModNames)
				xmlIndex = xmlIndex + 1
			end
		end
	end
end
function PlaceableSystem:savePlaceableToXML(placeable, xmlFile, index, i, usedModNames)
	local placeableKey = string.format("placeables.placeable(%d)", index)
	local modName = placeable.customEnvironment
	if modName ~= nil then
		if usedModNames ~= nil then
			usedModNames[modName] = modName
		end
		xmlFile:setValue(placeableKey .. "#modName", modName)
	end
	xmlFile:setValue(placeableKey .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(placeable.configFileName)))
	placeable:saveToXMLFile(xmlFile, placeableKey, usedModNames)
end
function PlaceableSystem:load(xmlFilename, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	self.savegameXMLFile = XMLFile.load("placeablesXML", xmlFilename, Placeable.xmlSchemaSavegame)
	self:loadFromXMLFile(self.savegameXMLFile, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
end
function PlaceableSystem:loadFromXMLFile(xmlFile, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	local defaultItemsToSPFarm = xmlFile:getValue("placeables#loadAnyFarmInSingleplayer", false)
	self.loadedPlaceables = {}
	self.placeablesToLoad = 0
	self.placeableLoadingState = nil
	self.asyncCallbackFunction = asyncCallbackFunction
	self.asyncCallbackObject = asyncCallbackObject
	self.asyncCallbackArguments = asyncCallbackArguments
	local usedUniqueIds = {}
	for _, key in xmlFile:iterator("placeables.placeable") do
		local isPreplaced = xmlFile:getValue(key .. "#isPreplaced")
		local isDeleted = xmlFile:getValue(key .. "#isDeleted")
		local uniqueId = xmlFile:getValue(key .. "#uniqueId")
		if uniqueId ~= nil then
			if usedUniqueIds[uniqueId] ~= nil then
				Logging.xmlError(xmlFile, "Skipping placeable '%s' because another placeable has the same uniqueId", key)
			else
				usedUniqueIds[uniqueId] = true
				local preplacedData = isPreplaced and self.uniqueIdToReplacedPlaceableData[uniqueId]
				if preplacedData ~= nil then
					preplacedData.foundInSavegame = true
				end
				if isDeleted then
					if preplacedData ~= nil then
						self:deletePreplacedPlaceable(preplacedData)
					else
						Logging.xmlWarning(xmlFile, "Only preplaced placeables can be marked as deleted. '%s'", key)
					end
				else
					local success = self:loadPlaceableFromXML(xmlFile, key, defaultItemsToSPFarm, preplacedData, self.loadPlaceableFinished, self, nil)
					if success or preplacedData == nil then
						continue
					end
					self:deletePreplacedPlaceable(preplacedData)
				end
			end
		end
	end
	for _, data in ipairs(self.preplacedPlaceableData) do
		if data.foundInSavegame then
			continue
		end
		Logging.xmlWarning(xmlFile, "No entry defined for map preplaced placeable '%s'. Deleting preplaced placeable!", data.uniqueId)
		self:deletePreplacedPlaceable(data)
	end
	if self.asyncCallbackFunction ~= nil and self.placeablesToLoad <= 0 then
		g_asyncTaskManager:addSubtask(function()
			self.asyncCallbackFunction(self.asyncCallbackObject, self.loadedPlaceables, PlaceableLoadingState.OK, self.asyncCallbackArguments)
			self.asyncCallbackFunction = nil
			self.asyncCallbackObject = nil
			self.asyncCallbackArguments = nil
		end)
	end
end
function PlaceableSystem:loadPlaceableFromXML(xmlFile, key, defaultItemsToSPFarm, preplacedData, callback, callbackTarget, callbackArguments)
	local missionInfo = g_currentMission.missionInfo
	local missionDynamicInfo = g_currentMission.missionDynamicInfo
	local defaultProperty = xmlFile:getValue(key .. "#defaultFarmProperty", false)
	local farmId = xmlFile:getValue(key .. "#farmId")
	local loadForCompetitive = defaultProperty and missionInfo.isCompetitiveMultiplayer and g_farmManager:getFarmById(farmId) ~= nil
	if defaultProperty and (missionInfo.loadDefaultFarm and not missionDynamicInfo.isMultiplayer) then
		local loadDefaultProperty = true
		if farmId ~= FarmManager.SINGLEPLAYER_FARM_ID then
			loadDefaultProperty = defaultItemsToSPFarm
		end
	end
	local allowedToLoad = missionInfo.isValid or not defaultProperty or loadDefaultProperty or loadForCompetitive
	local filename = nil
	if preplacedData ~= nil then
		filename = preplacedData.xmlFilename
	else
		filename = xmlFile:getValue(key .. "#filename")
	end
	if filename == nil then
		if xmlFile:getValue(key .. "#isPreplaced") then
			Logging.xmlInfo(xmlFile, "Preplaced placeable node is not defined anmore in the map. '%s'", key)
		else
			Logging.xmlInfo(xmlFile, "Missing filename for placeable '%s'", key)
		end
		return false
	else
		if allowedToLoad then
			if string.startsWith(filename, "$data") then
				filename = Utils.getFilename(filename)
			end
			filename = NetworkUtil.convertFromNetworkFilename(filename)
			local storeItem = g_storeManager:getItemByXMLFilename(filename)
			if storeItem ~= nil then
				local savegame = { xmlFile = xmlFile, key = key, ignoreFarmId = false }
				if loadDefaultProperty and (defaultItemsToSPFarm and farmId ~= FarmManager.SINGLEPLAYER_FARM_ID) then
					farmId = FarmManager.SINGLEPLAYER_FARM_ID
					savegame.ignoreFarmId = true
				end
				self.placeablesToLoad = self.placeablesToLoad + 1
				local data = PlaceableLoadingData.new()
				data:setStoreItem(storeItem)
				data:setSavegameData(savegame)
				if preplacedData ~= nil then
					data:setPreplacedIndex(preplacedData.index)
				end
				g_asyncTaskManager:addSubtask(function()
					data:load(callback, callbackTarget, callbackArguments)
				end)
				return true
			end
			Logging.xmlWarning(xmlFile, "Placeable '%s' not defined in store items", filename)
		end
		return false
	end
end
function PlaceableSystem:loadPlaceableFinished(placeable, loadingState, arguments)
	if loadingState == PlaceableLoadingState.OK then
		table.insert(self.loadedPlaceables, placeable)
	else
		self.placeableLoadingState = self.placeableLoadingState or loadingState
	end
	self.placeablesToLoad = self.placeablesToLoad - 1
	if self.asyncCallbackFunction ~= nil and self.placeablesToLoad <= 0 then
		g_asyncTaskManager:addTask(function()
			self.asyncCallbackFunction(self.asyncCallbackObject, self.loadedPlaceables, self.placeableLoadingState or PlaceableLoadingState.OK, self.asyncCallbackArguments)
			self.asyncCallbackFunction = nil
			self.asyncCallbackObject = nil
			self.asyncCallbackArguments = nil
			self.loadedPlaceables = nil
			self.placeableLoadingState = nil
		end, "PlaceableSystem:loadPlaceableFinished asyncCallbackFunction")
	end
end
function PlaceableSystem:consoleCommandPrintPendingLoadings()
	Logging.info("Pending Placeable Loadings:")
	for _, pendingData in ipairs(self.pendingPlaceableLoadingData) do
		Logging.info("    - %s", pendingData.storeItem ~= nil and pendingData.storeItem.xmlFilename or "Unknown")
	end
	Logging.info("Pending Placeable:")
	for _, placeable in ipairs(self.placeables) do
		if placeable:getIsSynchronized() then
			continue
		end
		Logging.info("    - LoadingState: %s | LoadingStep: %s | %s", PlaceableLoadingState.getName(placeable.loadingState), SpecializationUtil.getLoadingStepName(placeable.loadingStep), placeable.configFileName)
	end
end
function PlaceableSystem:consoleCommandDeleteAllPlaceables(includePreplaced)
	local usage = "Usage: gsPlaceablesDeleteAll [includePreplaced]"
	local numDeleted = 0
	for i = #self.placeables, 1, -1 do
		local placeable = self.placeables[i]
		if not placeable:getIsPreplaced() or includePreplaced then
			placeable:delete()
			numDeleted = numDeleted + 1
		end
	end
	if includePreplaced then
		return string.format("Deleted all %i placeables! Included preplaced ones!", numDeleted)
	else
		return string.format("Deleted %i placeables! Excluded preplaced ones.\n%s", numDeleted, "Usage: gsPlaceablesDeleteAll [includePreplaced]")
	end
end
function PlaceableSystem:consoleCommandReloadAllPlaceables()
	if self.isReloadRunning then
		return "Cannot start reloading. Another reloading is currently running"
	end
	if not g_currentMission:getIsServer() or g_currentMission.missionDynamicInfo.isMultiplayer then
		return "Placeable reloading only allowed in SP"
	end
	local xmlFile = nil
	local numPlaceables = 0
	if self.reloadPlaceableSavegame == nil then
		g_i3DManager:clearEntireSharedI3DFileCache(false)
		Logging.info("Start reloading placeables (non preplaced placables)...")
		xmlFile = XMLFile.create("placeableXMLFile", "", "placeables", Placeable.xmlSchemaSavegame)
		local usedModNames = {}
		self:saveToXML(xmlFile, usedModNames, false)
		for i = #self.placeables, 1, -1 do
			local placeable = self.placeables[i]
			if placeable.isPreplaced then
				continue
			end
			placeable.isReloading = true
			placeable:delete()
			numPlaceables = numPlaceables + 1
		end
	else
		Logging.info("Restart reloading placeables with remaining placeables...")
		xmlFile = self.reloadPlaceableSavegame
		numPlaceables = xmlFile:getNumOfElements("placeables.placeable")
	end
	function callback(_, loadedPlaceables, placeableLoadingState, args)
		for _, placeable in ipairs(loadedPlaceables) do
			local uniqueId = placeable:getUniqueId()
			for _, key in xmlFile:iterator("placeables.placeable") do
				local id = xmlFile:getValue(key .. "#uniqueId")
				if id == uniqueId then
					xmlFile:removeProperty(key)
					Logging.info("Reloaded placeable '%s'.", placeable.configFileName)
					break
				end
			end
		end
		local numElements = xmlFile:getNumOfElements("placeables.placeable")
		if numElements == 0 then
			Logging.info("Finished reloading.")
			xmlFile:delete()
			self.reloadPlaceableSavegame = nil
		else
			self.reloadPlaceableSavegame = xmlFile
			Logging.info("Finished reloading. %d placeables could not be reloaded. Please fix the config/i3d and run the command again!", numElements)
		end
		self.isReloadRunning = false
	end
	self.isReloadRunning = 0 < numPlaceables
	if 0 < numPlaceables then
		g_asyncTaskManager:addTask(function()
			self:loadFromXMLFile(xmlFile, callback, nil, nil)
		end)
		return
	else
		return "No placeables found to reload"
	end
end
function PlaceableSystem:consoleCommandLoadAllPlaceables()
	if self.isLoadAllRunning then
		return "Cannot start loading all placeables. Another loading is currently running"
	end
	if not g_currentMission:getIsServer() or g_currentMission.missionDynamicInfo.isMultiplayer then
		return "Placeable loading only allowed in SP"
	end
	local placeablesToLoad = {}
	for _, storeItem in ipairs(g_storeManager:getItems()) do
		if storeItem.brush == nil or storeItem.brush.type == "" then
			continue
		end
		if storeItem.brush.type == "fence" then
			local singletonFilename = storeItem.brush.parameters[1]
			if singletonFilename ~= nil then
				table.insert(placeablesToLoad, singletonFilename)
			else
				Logging.error("No fence singleton filename found for '%s'", storeItem.xmlFilename)
			end
		else
			table.insert(placeablesToLoad, storeItem)
		end
	end
	if #placeablesToLoad == 0 then
		return "No placeables found"
	else
		g_i3DManager:clearEntireSharedI3DFileCache(false)
		self.isLoadAllRunning = true
		Logging.info("Start loading all placeables...")
		local x = 0
		local z = 0
		local y = getTerrainHeightAtWorldPos(g_terrainNode, 0, 0, 0)
		local loadNextPlaceable = nil
		local callback = function(_, loadedPlaceable, placeableLoadingState, args)
			if placeableLoadingState ~= PlaceableLoadingState.OK then
				Logging.error("Could not load placeable '%s', PlaceableLoadingState: %s", args.filename, EnumUtil.getName(PlaceableLoadingState, placeableLoadingState))
			else
				Logging.info("Loaded placeable '%s'", loadedPlaceable.configFileName)
				loadedPlaceable:finalizePlacement()
			end
			if loadedPlaceable ~= nil then
				loadedPlaceable:delete()
			end
			table.remove(placeablesToLoad, 1)
			if #placeablesToLoad == 0 then
				self.isLoadAllRunning = false
				print("Finished loading placeables")
			else
				local nextItem = placeablesToLoad[1]
				loadNextPlaceable(nextItem)
			end
		end
		function loadNextPlaceable(storeItem)
			local data = PlaceableLoadingData.new()
			data:setStoreItem(storeItem)
			data:setSavegameData(nil)
			data:setPosition(0, y, 0)
			data:setRotation(0, 0, 0)
			data:load(callback, nil, { filename = storeItem.xmlFilename })
		end
		loadNextPlaceable(placeablesToLoad[1])
		return
	end
end
function PlaceableSystem:consoleCommandDrawMapBoundaries()
	PlaceableSystem.DEBUG_DRAW_BOUNDARIES = not PlaceableSystem.DEBUG_DRAW_BOUNDARIES
	if PlaceableSystem.DEBUG_DRAW_BOUNDARIES then
		g_currentMission:addDrawable(self)
	else
		g_currentMission:removeDrawable(self)
	end
end
