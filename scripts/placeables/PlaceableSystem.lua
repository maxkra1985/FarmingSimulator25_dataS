-- Local values: PlaceableSystem_mt
g_xmlManager:addInitSchemaFunction(function()
	Mission00.xmlSchema:register(XMLValueType.VECTOR_2, "map.placeableSystem.boundary.point(?)#translation", "Translation of the point")
end)
PlaceableSystem = {}
PlaceableSystem.TERRAIN_BORDER = 40
PlaceableSystem.UNIQUE_ID_PREFIX = "placeable"
local PlaceableSystem_mt = Class(PlaceableSystem)

-- Upvalues: PlaceableSystem_mt
-- Local values: self
function PlaceableSystem.new(mission, customMt)
	-- upvalues: (copy) PlaceableSystem_mt
	local v4_ = customMt or PlaceableSystem_mt
	local v5_ = setmetatable({}, v4_)
	v5_.mission = mission
	v5_.placeables = {}
	v5_.placableByUniqueId = {}
	v5_.pendingPlaceableLoadingData = {}
	v5_.preplacedPlaceableData = {}
	v5_.uniqueIdToReplacedPlaceableData = {}
	v5_.placeablesToDelete = {}
	v5_.weatherStations = {}
	v5_.farmhouses = {}
	v5_.bunkerSilos = {}
	v5_.boundary = nil
	v5_.version = 1
	v5_.isReloadRunning = false
	if v5_.mission:getIsServer() and g_addTestCommands then
		addConsoleCommand("gsPlaceablesDeleteAll", "Deletes all placeables", "consoleCommandDeleteAllPlaceables", v5_, nil, true)
		addConsoleCommand("gsPlaceablesReloadAll", "Reloads all placeables", "consoleCommandReloadAllPlaceables", v5_)
		addConsoleCommand("gsPlaceablesLoadAll", "Loads all placeables", "consoleCommandLoadAllPlaceables", v5_, nil, true)
	end
	if g_addTestCommands then
		addConsoleCommand("gsPlaceablesPendingLoadings", "Prints the pending placeable loadings", "consoleCommandPrintPendingLoadings", v5_)
		addConsoleCommand("gsPlaceableSystemDrawBoundary", "Draws the placeable map boundaries", "consoleCommandDrawMapBoundaries", v5_)
	end
	return v5_
end

-- Local values: xmlFile, boundary, _, pointKey, point
function PlaceableSystem:loadMapData(xmlFileHandle, missionInfo, baseDirectory)
	local v8_ = XMLFile.wrap(xmlFileHandle)
	if v8_ ~= nil then
		if v8_:hasProperty("map.placeableSystem.boundary") then
			local v9_ = {}
			for _, v10_ in v8_:iterator("map.placeableSystem.boundary.point") do
				local v11_ = v8_:getVector(v10_ .. "#translation", nil, 2)
				if v11_ ~= nil then
					table.insert(v9_, v11_)
				end
			end
			if #v9_ >= 3 then
				self.boundary = v9_
			else
				Logging.error("PlaceableSystem: Boundary must have at least 3 points, found %d", #v9_)
			end
		end
		v8_:delete()
	end
end

-- Local values: i, k, placeable, i, placeable
function PlaceableSystem:delete()
	for v13_ = #self.pendingPlaceableLoadingData, 1, -1 do
		self.pendingPlaceableLoadingData[v13_]:cancelLoading()
	end
	for v14_, v15_ in pairs(self.placeablesToDelete) do
		v15_:delete(true)
		self.placeablesToDelete[v14_] = nil
	end
	for v16_ = #self.placeables, 1, -1 do
		self.placeables[v16_]:delete(true)
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

-- Local values: numDeleted, i, placeable
function PlaceableSystem:deleteAll()
	local v18_ = #self.placeables
	for v19_ = #self.placeables, 1, -1 do
		self.placeables[v19_]:delete()
	end
	return v18_
end

-- Local values: i, point, nextPoint, pH, npH, limit, e1x, e1z, e2x, e2z, e3x, e3z, e4x, e4z, e1y, e2y, e3y, e4y
function PlaceableSystem:draw()
	if PlaceableSystem.DEBUG_DRAW_BOUNDARIES then
		if self.boundary ~= nil then
			for v21_ = 1, #self.boundary - 1 do
				local v22_ = self.boundary[v21_]
				local v23_ = self.boundary[v21_ + 1]
				local v24_ = getTerrainHeightAtWorldPos(g_terrainNode, v22_[1], 0, v22_[2])
				local v25_ = getTerrainHeightAtWorldPos(g_terrainNode, v23_[1], 0, v23_[2])
				drawDebugLine(v22_[1], v24_, v22_[2], 1, 0, 0, v23_[1], v25_, v23_[2], 1, 0, 0, false)
			end
			return
		end
		local v26_ = g_currentMission.terrainSize * 0.5 - PlaceableSystem.TERRAIN_BORDER
		local v27_ = -v26_
		local v28_ = -v26_
		local v29_ = -v26_
		local v30_ = -v26_
		local v31_ = getTerrainHeightAtWorldPos(g_terrainNode, v27_, 0, v28_)
		local v32_ = getTerrainHeightAtWorldPos(g_terrainNode, v26_, 0, v29_)
		local v33_ = getTerrainHeightAtWorldPos(g_terrainNode, v26_, 0, v26_)
		local v34_ = getTerrainHeightAtWorldPos(g_terrainNode, v30_, 0, v26_)
		drawDebugLine(v27_, v31_, v28_, 1, 0, 0, v26_, v32_, v29_, 1, 0, 0, false)
		drawDebugLine(v26_, v32_, v29_, 1, 0, 0, v26_, v33_, v26_, 1, 0, 0, false)
		drawDebugLine(v26_, v33_, v26_, 1, 0, 0, v30_, v34_, v26_, 1, 0, 0, false)
		drawDebugLine(v30_, v34_, v26_, 1, 0, 0, v27_, v31_, v28_, 1, 0, 0, false)
	end
end

-- Local values: newPosX, newPosZ, limit, y
function PlaceableSystem:limitPositionToBoundary(x, z)
	if self.boundary == nil then
		local v38_ = g_currentMission.terrainSize * 0.5 - PlaceableSystem.TERRAIN_BORDER
		local v39_ = -v38_
		x = math.clamp(x, v39_, v38_)
		local v40_ = -v38_
		z = math.clamp(z, v40_, v38_)
	elseif not FieldCourseUtil.getIsPointInsideBoundary(x, z, self.boundary) then
		x, z = FieldCourseUtil.getClosestPositionOnBoundary(x, z, self.boundary)
	end
	if PlaceableSystem.DEBUG_DRAW_BOUNDARIES then
		self:draw()
		local v41_ = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
		drawDebugArrow(x, v41_, z, 0, 0, 1, 0, 1, 0, 0, 1, 0, false)
	end
	return x, z
end

-- Local values: limit
function PlaceableSystem:getIsInsideBoundary(x, z)
	if self.boundary == nil then
		local v45_ = g_currentMission.terrainSize * 0.5 - PlaceableSystem.TERRAIN_BORDER
		if x < -v45_ or v45_ < x then
			return false
		else
			return z >= -v45_ and v45_ >= z
		end
	else
		return FieldCourseUtil.getIsPointInsideBoundary(x, z, self.boundary)
	end
end

-- Local values: numPreplacedPlaceables, i, data, isDeleted
function PlaceableSystem:readStreamPreplacedInfo(streamId, connection)
	for v48_ = 1, streamReadUInt16(streamId) do
		local v49_ = self.preplacedPlaceableData[v48_]
		if streamReadBool(streamId) then
			self:deletePreplacedPlaceable(v49_)
		end
	end
end

-- Local values: _, data
function PlaceableSystem:writeStreamPreplacedInfo(streamId, connection)
	streamWriteUInt16(streamId, #self.preplacedPlaceableData)
	for _, v52_ in ipairs(self.preplacedPlaceableData) do
		streamWriteBool(streamId, v52_.isDeleted)
	end
end

-- Local values: uniqueId, xmlFilename, xmlFile, boughtWithFarmlandOverwrite, customImageFilename, rootNode, node, data
function PlaceableSystem:addMapPlaceableNode(nodeId)
	Logging.devInfo("Adding preplaced map placeable \'%s\'", getName(nodeId))
	if nodeId == nil then
		Logging.error("No node given for validation")
		return
	elseif getNumOfChildren(nodeId) == 0 then
		Logging.error("Node \'%s\' is not a valid preplaced placeable node. No children defined", I3DUtil.getNodePath(nodeId))
		return
	else
		local v55_ = getUserAttribute(nodeId, "uniqueId")
		if string.isNilOrWhitespace(v55_) then
			Logging.error("Node \'%s\' is not a valid preplaced placeable node. Missing uniqueId attribute", I3DUtil.getNodePath(nodeId))
			return
		else
			local v56_ = getUserAttribute(nodeId, "xmlFilename")
			if string.isNilOrWhitespace(v56_) then
				Logging.error("Node \'%s\' is not a valid preplaced placeable node. Missing xmlFilename attribute", I3DUtil.getNodePath(nodeId))
				return
			else
				local v57_ = Utils.getFilename(v56_, g_currentMission.loadingMapBaseDirectory)
				local v58_ = XMLFile.load("Preplaced Placeable", v57_, Placeable.xmlSchema)
				if v58_ == nil then
					Logging.error("Node \'%s\' is not a valid preplaced placeable node. Cannot open config xml file", I3DUtil.getNodePath(nodeId))
					return
				else
					v58_:delete()
					local v59_ = getUserAttribute(nodeId, "boughtWithFarmlandOverwrite") or false
					local v60_ = getUserAttribute(nodeId, "customImageFilename")
					local v61_ = getChildAt(nodeId, 0)
					if getNumOfChildren(v61_) == 0 then
						Logging.error("Node \'%s\' is not a valid preplaced placeable node. No child nodes for \'placeable\' transform group", I3DUtil.getNodePath(nodeId))
					else
						local v62_ = {
							["index"] = #self.preplacedPlaceableData + 1,
							["rootNode"] = nodeId,
							["node"] = v61_,
							["xmlFilename"] = v57_,
							["uniqueId"] = v55_,
							["foundInSavegame"] = false,
							["isDeleted"] = false,
							["boughtWithFarmlandOverwrite"] = v59_,
							["customImageFilename"] = v60_
						}
						local v63_ = self.preplacedPlaceableData
						table.insert(v63_, v62_)
						self.uniqueIdToReplacedPlaceableData[v55_] = v62_
					end
				end
			end
		end
	end
end

-- Local values: uniqueId
function PlaceableSystem:addPlaceable(placeable)
	if placeable == nil or placeable:isa(Placeable) == nil then
		Logging.error("Given object is not a placeable")
		return
	else
		local v66_ = placeable:getUniqueId()
		if v66_ == nil or self.placableByUniqueId[v66_] == nil then
			if v66_ == nil then
				v66_ = Utils.getUniqueId(placeable, self.placableByUniqueId, PlaceableSystem.UNIQUE_ID_PREFIX)
				placeable:setUniqueId(v66_)
			end
			g_messageCenter:publish(MessageType.PLACEABLE_ADDED, placeable)
			table.addElement(self.placeables, placeable)
			self.placableByUniqueId[v66_] = placeable
		else
			local v67_ = Logging.warning
			local v68_ = self.placableByUniqueId[v66_]
			v67_("Tried to add existing placeable with unique id of %s! Existing: %s, new: %s", v66_, tostring(v68_), (tostring(placeable)))
		end
	end
end

-- Local values: uniqueId
function PlaceableSystem:removePlaceable(placeable)
	table.removeElement(self.placeables, placeable)
	local v71_ = placeable:getUniqueId()
	if v71_ ~= nil then
		self.placableByUniqueId[v71_] = nil
	end
	g_messageCenter:publish(MessageType.PLACEABLE_REMOVED, placeable)
end

-- Local values: uniqueId, preplacedData, rootNode, aiSplineNodePath, aiSplineNode, i, splineNode, maxWidth, maxWidthType, maxTurningRadius, maxTurningRadiusType, maxHeight, maxHeightType
function PlaceableSystem:addPreplacedPlaceable(placeable)
	local v74_ = placeable:getUniqueId()
	local v75_ = self.uniqueIdToReplacedPlaceableData[v74_]
	if v75_ ~= nil then
		v75_.placeable = placeable
		local v76_ = v75_.rootNode
		local v77_ = getUserAttribute(v76_, "aiSplines")
		if not string.isNilOrWhitespace(v77_) then
			local v78_ = I3DUtil.indexToObject(v76_, v77_)
			if v78_ ~= nil then
				for v79_ = 0, getNumOfChildren(v78_) - 1 do
					local v80_ = getChildAt(v78_, v79_)
					local v81_, v82_ = getUserAttributeValueAndType(v80_, "maxWidth")
					if v81_ ~= nil and v82_ ~= UserAttributeType.FLOAT then
						Logging.warning("Preplaced placeable aiSpline node \'%s\' maxWidth attribute has wrong type. Has to be float type", getName(v80_))
						v81_ = nil
					end
					local v83_, v84_ = getUserAttributeValueAndType(v80_, "maxTurningRadius")
					if v83_ ~= nil and v84_ ~= UserAttributeType.FLOAT then
						Logging.warning("Preplaced placeable aiSpline node \'%s\' maxTurningRadius attribute has wrong type. Has to be float type", getName(v80_))
						v83_ = nil
					end
					local v85_, v86_ = getUserAttributeValueAndType(v80_, "maxHeight")
					if v85_ ~= nil and v86_ ~= UserAttributeType.FLOAT then
						Logging.warning("Preplaced placeable aiSpline node \'%s\' maxHeight attribute has wrong type. Has to be float type", getName(v80_))
						v85_ = nil
					end
					g_currentMission.aiSystem:addRoadSpline(v80_, v81_, v83_, v85_)
					if v75_.aiSplineNodes == nil then
						v75_.aiSplineNodes = {}
					end
					local v87_ = v75_.aiSplineNodes
					table.insert(v87_, v80_)
				end
			end
		end
	end
end

-- Local values: uniqueId, preplacedData, _, splineNode
function PlaceableSystem:removePreplacedPlaceable(placeable)
	local v90_ = placeable:getUniqueId()
	local v91_ = self.uniqueIdToReplacedPlaceableData[v90_]
	if v91_ ~= nil then
		v91_.placeable = nil
		if v91_.aiSplineNodes ~= nil then
			for _, v92_ in ipairs(v91_.aiSplineNodes) do
				g_currentMission.aiSystem:removeRoadSpline(v92_)
			end
		end
		if not placeable.isReloading then
			self:deletePreplacedPlaceable(v91_)
		end
	end
end

function PlaceableSystem:deletePreplacedPlaceable(data)
	if entityExists(data.rootNode) then
		Logging.devInfo("PlaceableSystem:deletePreplacedPlaceable - Deleted node \'%s\'", getName(data.rootNode))
		delete(data.rootNode)
	else
		Logging.devWarning("PlaceableSystem:deletePreplacedPlaceable - entity %d does not exist", data.rootNode)
	end
	data.isDeleted = true
end

-- Local values: data
function PlaceableSystem:getPreplacedNodeByIndex(index)
	local v96_ = self.preplacedPlaceableData[index]
	if v96_ == nil then
		return nil
	else
		return v96_.node
	end
end

-- Local values: data
function PlaceableSystem:getPreplacedFilenameByIndex(index)
	local v99_ = self.preplacedPlaceableData[index]
	if v99_ == nil then
		return nil
	else
		return v99_.xmlFilename
	end
end

-- Local values: data
function PlaceableSystem:getPreplacedUniqueIdByIndex(index)
	local v102_ = self.preplacedPlaceableData[index]
	if v102_ == nil then
		return nil
	else
		return v102_.uniqueId
	end
end

function PlaceableSystem:getPlaceableByUniqueId(uniqueId)
	return self.placableByUniqueId[uniqueId]
end

-- Local values: _, placeable
function PlaceableSystem:getArePlaceablesOnFarmland(farmId, farmlandId, includeBoughtWithFarmland)
	for _, v109_ in ipairs(self.placeables) do
		if v109_.ownerFarmId == farmId and (includeBoughtWithFarmland or not v109_.boughtWithFarmland) and v109_:getIsOnFarmland(farmlandId) then
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

-- Local values: i
function PlaceableSystem:canStartMission()
	for v116_ = 1, #self.placeables do
		if not self.placeables[v116_]:getIsSynchronized() then
			return false
		end
	end
	return #self.pendingPlaceableLoadingData <= 0
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

-- Local values: _, placeable
function PlaceableSystem:getExistingPlaceableByXMLFilename(xmlFilename, ownerFarmId, excludeBoughtWithFarmland)
	for _, v130_ in ipairs(self.placeables) do
		if v130_.configFileName == xmlFilename and (not v130_.markedForDeletion and (ownerFarmId == nil or v130_.ownerFarmId == ownerFarmId)) and not (excludeBoughtWithFarmland and v130_.boughtWithFarmlandSavegameOverwrite) then
			return v130_
		end
	end
	return nil
end

-- Local values: _, weatherStation
function PlaceableSystem:getHasWeatherStation(farmId)
	for _, v133_ in ipairs(self.weatherStations) do
		if farmId == nil or v133_:getOwnerFarmId() == farmId then
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

-- Local values: _, farmhouse
function PlaceableSystem:getFarmhouse(farmId)
	for _, v140_ in ipairs(self.farmhouses) do
		if farmId == nil or v140_:getOwnerFarmId() == farmId then
			return v140_
		end
	end
	return nil
end

-- Local values: k, placeable
function PlaceableSystem:deleteMarkedPlaceables()
	for v142_, v143_ in pairs(self.placeablesToDelete) do
		v143_:delete(true)
		self.placeablesToDelete[v142_] = nil
	end
end

function PlaceableSystem:markPlaceableForDeletion(placeable)
	self.placeablesToDelete[placeable] = placeable
end

-- Local values: xmlFile
function PlaceableSystem:save(xmlFilename, usedModNames)
	local v149_ = XMLFile.create("placeablesXML", xmlFilename, "placeables", Placeable.xmlSchemaSavegame)
	if v149_ ~= nil then
		self:saveToXML(v149_, usedModNames)
		v149_:save()
		v149_:delete()
	end
end

-- Local values: xmlIndex, _, data, placeableKey, i, placeable
function PlaceableSystem:saveToXML(xmlFile, usedModNames, savePreplaced)
	if xmlFile ~= nil then
		xmlFile:setValue("placeables#version", self.version)
		local v154_ = 0
		if Utils.getNoNil(savePreplaced, true) then
			for _, v155_ in ipairs(self.preplacedPlaceableData) do
				local v156_ = string.format("placeables.placeable(%d)", v154_)
				xmlFile:setValue(v156_ .. "#isPreplaced", true)
				xmlFile:setValue(v156_ .. "#uniqueId", v155_.uniqueId)
				if v155_.isDeleted then
					xmlFile:setValue(v156_ .. "#isDeleted", true)
				end
				if v155_.boughtWithFarmlandOverwrite then
					xmlFile:setBool(v156_ .. "#boughtWithFarmlandOverwrite", true)
				end
				if not string.isNilOrWhitespace(v155_.customImageFilename) then
					xmlFile:setString(v156_ .. ".customImage#filename", v155_.customImageFilename)
				end
				if v155_.placeable ~= nil then
					v155_.placeable:saveToXMLFile(xmlFile, v156_, usedModNames)
				end
				v154_ = v154_ + 1
			end
		end
		for v157_, v158_ in ipairs(self.placeables) do
			if v158_:getNeedsSaving() and not v158_.isPreplaced then
				self:savePlaceableToXML(v158_, xmlFile, v154_, v157_, usedModNames)
				v154_ = v154_ + 1
			end
		end
	end
end

-- Local values: placeableKey, modName
function PlaceableSystem:savePlaceableToXML(placeable, xmlFile, index, i, usedModNames)
	local v163_ = string.format("placeables.placeable(%d)", index)
	local v164_ = placeable.customEnvironment
	if v164_ ~= nil then
		if usedModNames ~= nil then
			usedModNames[v164_] = v164_
		end
		xmlFile:setValue(v163_ .. "#modName", v164_)
	end
	xmlFile:setValue(v163_ .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(placeable.configFileName)))
	placeable:saveToXMLFile(xmlFile, v163_, usedModNames)
end

function PlaceableSystem:load(xmlFilename, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	self.savegameXMLFile = XMLFile.load("placeablesXML", xmlFilename, Placeable.xmlSchemaSavegame)
	self:loadFromXMLFile(self.savegameXMLFile, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
end

-- Local values: defaultItemsToSPFarm, usedUniqueIds, _, key, isPreplaced, isDeleted, uniqueId, preplacedData, success, _, data
function PlaceableSystem:loadFromXMLFile(xmlFile, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	local v175_ = xmlFile:getValue("placeables#loadAnyFarmInSingleplayer", false)
	self.loadedPlaceables = {}
	self.placeablesToLoad = 0
	self.placeableLoadingState = nil
	self.asyncCallbackFunction = asyncCallbackFunction
	self.asyncCallbackObject = asyncCallbackObject
	self.asyncCallbackArguments = asyncCallbackArguments
	local v176_ = {}
	for _, v177_ in xmlFile:iterator("placeables.placeable") do
		local v178_ = xmlFile:getValue(v177_ .. "#isPreplaced")
		local v179_ = xmlFile:getValue(v177_ .. "#isDeleted")
		local v180_ = xmlFile:getValue(v177_ .. "#uniqueId")
		if v180_ == nil then
			::l4::
			if v178_ then
				v178_ = self.uniqueIdToReplacedPlaceableData[v180_]
			end
			if v178_ ~= nil then
				v178_.foundInSavegame = true
			end
			if v179_ then
				if v178_ == nil then
					Logging.xmlWarning(xmlFile, "Only preplaced placeables can be marked as deleted. \'%s\'", v177_)
				else
					self:deletePreplacedPlaceable(v178_)
				end
			elseif not self:loadPlaceableFromXML(xmlFile, v177_, v175_, v178_, self.loadPlaceableFinished, self, nil) and v178_ ~= nil then
				self:deletePreplacedPlaceable(v178_)
			end
		else
			if v176_[v180_] == nil then
				v176_[v180_] = true
				goto l4
			end
			Logging.xmlError(xmlFile, "Skipping placeable \'%s\' because another placeable has the same uniqueId", v177_)
		end
	end
	for _, v181_ in ipairs(self.preplacedPlaceableData) do
		if not v181_.foundInSavegame then
			Logging.xmlWarning(xmlFile, "No entry defined for map preplaced placeable \'%s\'. Deleting preplaced placeable!", v181_.uniqueId)
			self:deletePreplacedPlaceable(v181_)
		end
	end
	if self.asyncCallbackFunction ~= nil and self.placeablesToLoad <= 0 then
		g_asyncTaskManager:addSubtask(function()
			-- upvalues: (copy) self
			self.asyncCallbackFunction(self.asyncCallbackObject, self.loadedPlaceables, PlaceableLoadingState.OK, self.asyncCallbackArguments)
			self.asyncCallbackFunction = nil
			self.asyncCallbackObject = nil
			self.asyncCallbackArguments = nil
		end)
	end
end

-- Local values: missionInfo, missionDynamicInfo, defaultProperty, farmId, loadForCompetitive, loadDefaultProperty, allowedToLoad, filename, storeItem, savegame, data
function PlaceableSystem:loadPlaceableFromXML(xmlFile, key, defaultItemsToSPFarm, preplacedData, callback, callbackTarget, callbackArguments)
	local v190_ = g_currentMission.missionInfo
	local v191_ = g_currentMission.missionDynamicInfo
	local v192_ = xmlFile:getValue(key .. "#defaultFarmProperty", false)
	local v193_ = xmlFile:getValue(key .. "#farmId")
	local v194_ = v192_ and v190_.isCompetitiveMultiplayer
	if v194_ then
		v194_ = g_farmManager:getFarmById(v193_) ~= nil
	end
	local v195_ = v192_ and (v190_.loadDefaultFarm and not v191_.isMultiplayer)
	if v195_ then
		v195_ = v193_ == FarmManager.SINGLEPLAYER_FARM_ID and true or defaultItemsToSPFarm
	end
	local v196_ = v190_.isValid or (not v192_ or (v195_ or v194_))
	local v197_
	if preplacedData == nil then
		v197_ = xmlFile:getValue(key .. "#filename")
	else
		v197_ = preplacedData.xmlFilename
	end
	if v197_ == nil then
		if xmlFile:getValue(key .. "#isPreplaced") then
			Logging.xmlInfo(xmlFile, "Preplaced placeable node is not defined anmore in the map. \'%s\'", key)
		else
			Logging.xmlInfo(xmlFile, "Missing filename for placeable \'%s\'", key)
		end
		return false
	else
		if v196_ then
			if string.startsWith(v197_, "$data") then
				v197_ = Utils.getFilename(v197_)
			end
			local v198_ = NetworkUtil.convertFromNetworkFilename(v197_)
			local v199_ = g_storeManager:getItemByXMLFilename(v198_)
			if v199_ ~= nil then
				local v200_ = {
					["xmlFile"] = xmlFile,
					["key"] = key,
					["ignoreFarmId"] = false
				}
				if v195_ and (defaultItemsToSPFarm and v193_ ~= FarmManager.SINGLEPLAYER_FARM_ID) then
					local _ = FarmManager.SINGLEPLAYER_FARM_ID
					v200_.ignoreFarmId = true
				end
				self.placeablesToLoad = self.placeablesToLoad + 1
				local v_u_201_ = PlaceableLoadingData.new()
				v_u_201_:setStoreItem(v199_)
				v_u_201_:setSavegameData(v200_)
				if preplacedData ~= nil then
					v_u_201_:setPreplacedIndex(preplacedData.index)
				end
				g_asyncTaskManager:addSubtask(function()
					-- upvalues: (copy) v_u_201_, (copy) callback, (copy) callbackTarget, (copy) callbackArguments
					v_u_201_:load(callback, callbackTarget, callbackArguments)
				end)
				return true
			end
			Logging.xmlWarning(xmlFile, "Placeable \'%s\' not defined in store items", v198_)
		end
		return false
	end
end

function PlaceableSystem:loadPlaceableFinished(placeable, loadingState, arguments)
	if loadingState == PlaceableLoadingState.OK then
		local v205_ = self.loadedPlaceables
		table.insert(v205_, placeable)
	else
		self.placeableLoadingState = self.placeableLoadingState or loadingState
	end
	self.placeablesToLoad = self.placeablesToLoad - 1
	if self.asyncCallbackFunction ~= nil and self.placeablesToLoad <= 0 then
		g_asyncTaskManager:addTask(function()
			-- upvalues: (copy) self
			self.asyncCallbackFunction(self.asyncCallbackObject, self.loadedPlaceables, self.placeableLoadingState or PlaceableLoadingState.OK, self.asyncCallbackArguments)
			self.asyncCallbackFunction = nil
			self.asyncCallbackObject = nil
			self.asyncCallbackArguments = nil
			self.loadedPlaceables = nil
			self.placeableLoadingState = nil
		end, "PlaceableSystem:loadPlaceableFinished asyncCallbackFunction")
	end
end

-- Local values: _, pendingData, _, placeable
function PlaceableSystem:consoleCommandPrintPendingLoadings()
	Logging.info("Pending Placeable Loadings:")
	for _, v207_ in ipairs(self.pendingPlaceableLoadingData) do
		Logging.info("    - %s", v207_.storeItem == nil and "Unknown" or (v207_.storeItem.xmlFilename or "Unknown"))
	end
	Logging.info("Pending Placeable:")
	for _, v208_ in ipairs(self.placeables) do
		if not v208_:getIsSynchronized() then
			Logging.info("    - LoadingState: %s | LoadingStep: %s | %s", PlaceableLoadingState.getName(v208_.loadingState), SpecializationUtil.getLoadingStepName(v208_.loadingStep), v208_.configFileName)
		end
	end
end

-- Local values: usage, numDeleted, i, placeable
function PlaceableSystem:consoleCommandDeleteAllPlaceables(includePreplaced)
	local v211_ = 0
	for v212_ = #self.placeables, 1, -1 do
		local v213_ = self.placeables[v212_]
		if not v213_:getIsPreplaced() or includePreplaced then
			v213_:delete()
			v211_ = v211_ + 1
		end
	end
	if includePreplaced then
		return string.format("Deleted all %i placeables! Included preplaced ones!", v211_)
	else
		return string.format("Deleted %i placeables! Excluded preplaced ones.\n%s", v211_, "Usage: gsPlaceablesDeleteAll [includePreplaced]")
	end
end

-- Local values: xmlFile, numPlaceables, usedModNames, i, placeable
function PlaceableSystem:consoleCommandReloadAllPlaceables()
	if self.isReloadRunning then
		return "Cannot start reloading. Another reloading is currently running"
	end
	if not g_currentMission:getIsServer() or g_currentMission.missionDynamicInfo.isMultiplayer then
		return "Placeable reloading only allowed in SP"
	end
	local v215_ = 0
	local v_u_216_
	if self.reloadPlaceableSavegame == nil then
		g_i3DManager:clearEntireSharedI3DFileCache(false)
		Logging.info("Start reloading placeables (non preplaced placables)...")
		v_u_216_ = XMLFile.create("placeableXMLFile", "", "placeables", Placeable.xmlSchemaSavegame)
		self:saveToXML(v_u_216_, {}, false)
		for v217_ = #self.placeables, 1, -1 do
			local v218_ = self.placeables[v217_]
			if not v218_.isPreplaced then
				v218_.isReloading = true
				v218_:delete()
				v215_ = v215_ + 1
			end
		end
	else
		Logging.info("Restart reloading placeables with remaining placeables...")
		v_u_216_ = self.reloadPlaceableSavegame
		v215_ = v_u_216_:getNumOfElements("placeables.placeable")
	end
	
-- Upvalues: xmlFile, self
-- Local values: _, placeable, uniqueId, _, key, id, numElements

-- Upvalues: placeablesToLoad, self, loadNextPlaceable
-- Local values: nextItem
function callback(_, loadedPlaceable, placeableLoadingState, args)
		-- upvalues: (ref) v_u_216_, (copy) self
		for _, v220_ in ipairs(loadedPlaceable) do
			local v221_ = v220_:getUniqueId()
			for _, v222_ in v_u_216_:iterator("placeables.placeable") do
				if v_u_216_:getValue(v222_ .. "#uniqueId") == v221_ then
					v_u_216_:removeProperty(v222_)
					Logging.info("Reloaded placeable \'%s\'.", v220_.configFileName)
					break
				end
			end
		end
		local v223_ = v_u_216_:getNumOfElements("placeables.placeable")
		if v223_ == 0 then
			Logging.info("Finished reloading.")
			v_u_216_:delete()
			self.reloadPlaceableSavegame = nil
		else
			self.reloadPlaceableSavegame = v_u_216_
			Logging.info("Finished reloading. %d placeables could not be reloaded. Please fix the config/i3d and run the command again!", v223_)
		end
		self.isReloadRunning = false
	end
	self.isReloadRunning = v215_ > 0
	if v215_ <= 0 then
		return "No placeables found to reload"
	end
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self, (ref) v_u_216_
		self:loadFromXMLFile(v_u_216_, callback, nil, nil)
	end)
end

-- Local values: placeablesToLoad, _, storeItem, singletonFilename, x, z, y, loadNextPlaceable, callback
function PlaceableSystem:consoleCommandLoadAllPlaceables()
	if self.isLoadAllRunning then
		return "Cannot start loading all placeables. Another loading is currently running"
	end
	if not g_currentMission:getIsServer() or g_currentMission.missionDynamicInfo.isMultiplayer then
		return "Placeable loading only allowed in SP"
	end
	local v_u_225_ = {}
	for _, v226_ in ipairs(g_storeManager:getItems()) do
		if v226_.brush ~= nil and v226_.brush.type ~= "" then
			if v226_.brush.type == "fence" then
				local v227_ = v226_.brush.parameters[1]
				if v227_ == nil then
					Logging.error("No fence singleton filename found for \'%s\'", v226_.xmlFilename)
				else
					table.insert(v_u_225_, v227_)
				end
			else
				table.insert(v_u_225_, v226_)
			end
		end
	end
	if #v_u_225_ == 0 then
		return "No placeables found"
	end
	g_i3DManager:clearEntireSharedI3DFileCache(false)
	self.isLoadAllRunning = true
	Logging.info("Start loading all placeables...")
	local v_u_228_ = 0
	local v_u_229_ = 0
	local v_u_230_ = getTerrainHeightAtWorldPos(g_terrainNode, 0, 0, 0)
	local v_u_231_ = nil
	local function v_u_235_(_, p232_, p233_, p234_)
		-- upvalues: (copy) v_u_225_, (copy) self, (ref) v_u_231_
		if p233_ == PlaceableLoadingState.OK then
			Logging.info("Loaded placeable \'%s\'", p232_.configFileName)
			p232_:finalizePlacement()
		else
			Logging.error("Could not load placeable \'%s\', PlaceableLoadingState: %s", p234_.filename, EnumUtil.getName(PlaceableLoadingState, p233_))
		end
		if p232_ ~= nil then
			p232_:delete()
		end
		table.remove(v_u_225_, 1)
		if #v_u_225_ == 0 then
			self.isLoadAllRunning = false
			print("Finished loading placeables")
		else
			v_u_231_(v_u_225_[1])
		end
	end
	v_u_231_ = function(p236_)
		-- upvalues: (copy) v_u_230_, (copy) v_u_235_, (copy) v_u_228_, (copy) v_u_229_
		local v237_ = PlaceableLoadingData.new()
		v237_:setStoreItem(p236_)
		v237_:setSavegameData(nil)
		v237_:setPosition(0, v_u_230_, 0)
		v237_:setRotation(0, 0, 0)
		v237_:load(v_u_235_, nil, {
			["filename"] = p236_.xmlFilename
		})
	end
	v_u_231_(v_u_225_[1])
end

function PlaceableSystem:consoleCommandDrawMapBoundaries()
	PlaceableSystem.DEBUG_DRAW_BOUNDARIES = not PlaceableSystem.DEBUG_DRAW_BOUNDARIES
	if PlaceableSystem.DEBUG_DRAW_BOUNDARIES then
		g_currentMission:addDrawable(self)
	else
		g_currentMission:removeDrawable(self)
	end
end
