-- Local values: DensityMapHeightManager_mt, sortHeightTypes, getIsPlacementAreaBlocked_modifier, getIsPlacementAreaBlocked_filter
DensityMapHeightManager = {}
DensityMapHeightManager.GENERATED_TIP_COLLISION_FILENAME = "infoLayer_tipCollisionGenerated.grle"
DensityMapHeightManager.GENERATED_PLACEMENT_COLLISION_FILENAME = "infoLayer_placementCollisionGenerated.grle"
DensityMapHeightManager.DEBUG_ENABLED = false
DensityMapHeightManager.DEBUG_TIP_COLLISIONS = false
DensityMapHeightManager.DEBUG_PLACEMENT_COLLISIONS = false
DensityMapHeightManager.DEBUG_GROUP_ID = "densityMapHeight"
g_xmlManager:addCreateSchemaFunction(function()
	DensityMapHeightManager.xmlSchema = XMLSchema.new("densityMapHeightTypes")
end)
g_xmlManager:addInitSchemaFunction(function()
	DensityMapHeightManager.registerXMLPaths(DensityMapHeightManager.xmlSchema, "map")
	local v1_ = Mission00.xmlSchema
	DensityMapHeightManager.registerXMLPaths(v1_, "map")
end)

-- Local values: typeKey
function DensityMapHeightManager.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. ".densityMapHeightTypes#firstChannel", "First channel on the density map for height types", 0)
	schema:register(XMLValueType.INT, basePath .. ".densityMapHeightTypes#numChannels", "Number of channel on the density map for height types", 6)
	schema:register(XMLValueType.FLOAT, basePath .. ".densityMapHeightTypes.freeAccessArea(?)#x", "free accees area center world space x coordinate")
	schema:register(XMLValueType.FLOAT, basePath .. ".densityMapHeightTypes.freeAccessArea(?)#z", "free accees area center world space z coordinate")
	schema:register(XMLValueType.FLOAT, basePath .. ".densityMapHeightTypes.freeAccessArea(?)#radius", "free accees area radius in meters")
	local v4_ = basePath .. ".densityMapHeightTypes.densityMapHeightType(?)"
	schema:register(XMLValueType.STRING, v4_ .. "#fillTypeName", "Name of the fill type")
	schema:register(XMLValueType.ANGLE, v4_ .. "#maxSurfaceAngle", "Max. surface angle for this fill type", 26)
	schema:register(XMLValueType.FLOAT, v4_ .. "#fillToGroundScale", "Scale factor for fill to ground", 1)
	schema:register(XMLValueType.BOOL, v4_ .. "#allowsSmoothing", "Allows smoothing", false)
	schema:register(XMLValueType.FLOAT, v4_ .. ".collision#scale", "Collision scale", 1)
	schema:register(XMLValueType.FLOAT, v4_ .. ".collision#baseOffset", "Collision base offset", 0)
	schema:register(XMLValueType.FLOAT, v4_ .. ".collision#minOffset", "Collision min offset", 0)
	schema:register(XMLValueType.FLOAT, v4_ .. ".collision#maxOffset", "Collision max offset", 1)
	schema:register(XMLValueType.BOOL, v4_ .. "#canBeTipped", "Can be tipped", true)
	schema:register(XMLValueType.INT, v4_ .. ".visualHeightMapping.mapping(?)#realValue", "Real density map value (1-64 when using 6 bits)")
	schema:register(XMLValueType.INT, v4_ .. ".visualHeightMapping.mapping(?)#visualValue", "Visual value to show when the real value is reached (1-64 when using 6 bits)")
end
local v_u_5_ = Class(DensityMapHeightManager, AbstractManager)

-- Upvalues: DensityMapHeightManager_mt
-- Local values: self
function DensityMapHeightManager.new(customMt)
	-- upvalues: (copy) v_u_5_
	local v7_ = AbstractManager.new(customMt or v_u_5_)
	v7_.modDensityHeightMapTypeFilenames = {}
	return v7_
end

function DensityMapHeightManager:initDataStructures()
	self.numHeightTypes = 0
	self.heightTypes = {}
	self.fillTypeNameToHeightType = {}
	self.fillTypeIndexToHeightType = {}
	self.heightTypeIndexToFillTypeIndex = {}
	self.freeAccessAreas = {}
	self.fixedFillTypesAreas = {}
	self.convertingFillTypesAreas = {}
	self.tipTypeMappings = {}
	if self.terrainDetailHeightUpdater ~= nil then
		delete(self.terrainDetailHeightUpdater)
		self.terrainDetailHeightUpdater = nil
	end
	if self.tipCollisionMap ~= nil then
		if self.tipCollisionMapCreated then
			delete(self.tipCollisionMap)
			self.tipCollisionMapCreated = false
		end
		self.tipCollisionMap = nil
	end
	if self.placementCollisionMap ~= nil then
		if self.placementCollisionMapCreated then
			delete(self.placementCollisionMap)
			self.placementCollisionMapCreated = false
		end
		self.placementCollisionMap = nil
	end
	self.tipCollisionMask = CollisionFlag.GROUND_TIP_BLOCKING
	self.placementCollisionMask = CollisionFlag.PLACEMENT_BLOCKING
end

-- Local values: xmlFile
function DensityMapHeightManager:loadDefaultTypes(missionInfo, baseDirectory)
	self:initDataStructures()
	local v12_ = loadXMLFile("heightTypes", "data/maps/maps_densityMapHeightTypes.xml")
	self:loadDensityMapHeightTypes(v12_, missionInfo, baseDirectory, true)
	delete(v12_)
end

-- Local values: success
function DensityMapHeightManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	DensityMapHeightManager:superClass().loadMapData(self)
	if g_addCheatCommands then
		if g_server ~= nil then
			addConsoleCommand("gsTipCollisionsShow", "Shows the collisions for tipping on the ground", "consoleCommandShowTipCollisions", self)
			addConsoleCommand("gsTipCollisionsUpdate", "Updates the collisions for tipping on the ground around the current camera", "consoleCommandUpdateTipCollisions", self)
			addConsoleCommand("gsTipAnywhereAdd", "Tips a fillType", "consoleCommandTipAnywhereAdd", self, "fillTypeName; amount; [length]; [rows]; [spacing]")
			addConsoleCommand("gsTipAnywhereAddAll", "Tips a heap of every fill type that can be tipped", "consoleCommandTipAnywhereAddAll", self)
			addConsoleCommand("gsTipAnywhereClear", "Clears tip area", "consoleCommandTipAnywhereClear", self, "sizeToClearMeters")
		end
		addConsoleCommand("gsDensityMapToggleDebug", "Toggles debug mode", "consoleCommandToggleDebug", self)
		addConsoleCommand("gsPlacementCollisionsShow", "Shows the collisions for placement and terraforming", "consoleCommandShowPlacementCollisions", self)
	end
	self:loadDefaultTypes(missionInfo, baseDirectory)
	return XMLUtil.loadDataFromMapXML(xmlFile, "densityMapHeightTypes", baseDirectory, self, self.loadDensityMapHeightTypes, missionInfo, baseDirectory)
end

function DensityMapHeightManager:unloadMapData()
	DensityMapHeightManager:superClass().unloadMapData(self)
	removeConsoleCommand("gsTipAnywhereAdd")
	removeConsoleCommand("gsTipAnywhereAddAll")
	removeConsoleCommand("gsTipAnywhereClear")
	removeConsoleCommand("gsDensityMapToggleDebug")
	removeConsoleCommand("gsTipCollisionsShow")
	removeConsoleCommand("gsTipCollisionsUpdate")
	removeConsoleCommand("gsPlacementCollisionsShow")
	if self.debugBitVectorMapTipCollisionsId ~= nil then
		g_debugManager:removeElementById(self.debugBitVectorMapTipCollisionsId)
		self.debugBitVectorMapTipCollisionsId = nil
	end
	if self.debugBitVectorMapPlacementCollisionsId ~= nil then
		g_debugManager:removeElementById(self.debugBitVectorMapPlacementCollisionsId)
		self.debugBitVectorMapPlacementCollisionsId = nil
	end
end

-- Local values: rootName, _, key, _, key, x, z, radius, area
function DensityMapHeightManager:loadDensityMapHeightTypes(xmlFile, missionInfo, baseDirectory, isBaseType)
	if type(xmlFile) ~= "table" then
		xmlFile = XMLFile.wrap(xmlFile, DensityMapHeightManager.xmlSchema)
	end
	local v21_ = xmlFile:getRootName()
	self.heightTypeFirstChannel = xmlFile:getValue(v21_ .. ".densityMapHeightTypes#firstChannel", self.heightTypeFirstChannel or 0)
	local v22_ = xmlFile:getValue(v21_ .. ".densityMapHeightTypes#numChannels", self.heightTypeNumChannels or 6)
	local v23_ = self.heightTypeNumChannels or 6
	self.heightTypeNumChannels = math.max(v22_, v23_)
	for _, v24_ in xmlFile:iterator(v21_ .. ".densityMapHeightTypes.densityMapHeightType") do
		self:loadDensityMapHeightTypeFromXML(xmlFile, v24_, isBaseType)
	end
	for _, v25_ in xmlFile:iterator(v21_ .. ".densityMapHeightTypes.freeAccessArea") do
		local v26_ = xmlFile:getFloat(v25_ .. "#x")
		local v27_ = xmlFile:getFloat(v25_ .. "#z")
		local v28_ = xmlFile:getFloat(v25_ .. "#radius")
		if v26_ ~= nil and (v27_ ~= nil and v28_ ~= nil) then
			local v29_ = self.freeAccessAreas
			table.insert(v29_, {
				["x"] = v26_,
				["z"] = v27_,
				["radius"] = v28_
			})
		end
	end
	return true
end

function DensityMapHeightManager:addModDensityMapHeightTypes(xmlFilename)
	local v32_ = self.modDensityHeightMapTypeFilenames
	table.insert(v32_, xmlFilename)
end

-- Local values: i, filename, heightTypesXmlFile
function DensityMapHeightManager:loadModDensityMapHeightTypes()
	for v34_ = #self.modDensityHeightMapTypeFilenames, 1, -1 do
		local v35_ = self.modDensityHeightMapTypeFilenames[v34_]
		local v36_ = loadXMLFile("heightTypes", v35_)
		if v36_ ~= 0 then
			self:loadDensityMapHeightTypes(v36_, nil, nil, false)
			delete(v36_)
		end
		self.modDensityHeightMapTypeFilenames[v34_] = nil
	end
end

-- Local values: xmlFile
function DensityMapHeightManager:loadFromXMLFile(xmlFilename)
	if xmlFilename == nil then
		return false
	end
	local v_u_39_ = XMLFile.load("densitymapHeightXML", xmlFilename)
	if v_u_39_ == nil then
		return false
	end
	self.tipTypeMappings = {}
	v_u_39_:iterate("tipTypeMappings.tipTypeMapping", function(_, p40_)
		-- upvalues: (copy) v_u_39_, (copy) self
		local v41_ = v_u_39_:getString(p40_ .. "#fillType")
		local v42_ = v_u_39_:getInt(p40_ .. "#index")
		if v41_ ~= nil and v42_ ~= nil then
			self.tipTypeMappings[string.lower(v41_)] = v42_
		end
	end)
	v_u_39_:delete()
	return true
end

-- Local values: xmlFile, k, heightType, mappingKey
function DensityMapHeightManager:saveToXMLFile(xmlFilename)
	local v45_ = XMLFile.create("densityMapHeightXML", xmlFilename, "tipTypeMappings")
	if v45_ == nil then
		return false
	end
	for v46_, v47_ in ipairs(self.heightTypes) do
		local v48_ = string.format("tipTypeMappings.tipTypeMapping(%d)", v46_ - 1)
		v45_:setString(v48_ .. "#fillType", v47_.fillTypeName)
		v45_:setInt(v48_ .. "#index", v47_.index)
	end
	v45_:save()
	v45_:delete()
	return true
end
local function v_u_51_(p49_, p50_)
	return p49_.fillTypeIndex < p50_.fillTypeIndex
end

-- Upvalues: sortHeightTypes
-- Local values: i, heightType
function DensityMapHeightManager:sortHeightTypes()
	-- upvalues: (copy) v_u_51_
	table.sort(self.heightTypes, v_u_51_)
	for v53_ = 1, #self.heightTypes do
		local v54_ = self.heightTypes[v53_]
		v54_.index = v53_
		self.heightTypeIndexToFillTypeIndex[v54_.index] = v54_.fillTypeIndex
	end
end

-- Local values: fillTypeName, fillTypeIndex, heightType, maxNumHeightTypes, _, mappingKey, mapping
function DensityMapHeightManager:loadDensityMapHeightTypeFromXML(xmlFile, key, isBaseType)
	local v59_ = xmlFile:getValue(key .. "#fillTypeName")
	local v60_ = g_fillTypeManager:getFillTypeIndexByName(v59_)
	if v60_ == nil then
		Logging.xmlError(xmlFile, "\'%s\' has invalid fill type \'%s\'!", key, v59_)
		return
	elseif isBaseType and self.fillTypeNameToHeightType[v59_] ~= nil then
		Logging.error("density height map for \'%s\' already exists!", v59_)
	else
		local v61_ = self.fillTypeNameToHeightType[v59_]
		if v61_ == nil then
			local v62_ = 2 ^ g_densityMapHeightManager.heightTypeNumChannels - 1
			if v62_ <= self.numHeightTypes then
				Logging.error("addDensityMapHeightType %q: maximum number (%d) of height types already registered. Adjust densityMapHeightTypes#numChannels to allow for more", v59_, v62_)
				return
			end
			self.numHeightTypes = self.numHeightTypes + 1
			v61_ = {
				["index"] = self.numHeightTypes,
				["fillTypeName"] = v59_,
				["fillTypeIndex"] = v60_
			}
			local v63_ = self.heightTypes
			table.insert(v63_, v61_)
			self.fillTypeNameToHeightType[v59_] = v61_
			self.fillTypeIndexToHeightType[v60_] = v61_
			self.heightTypeIndexToFillTypeIndex[v61_.index] = v60_
			self:sortHeightTypes()
		end
		v61_.maxSurfaceAngle = xmlFile:getValue(key .. "#maxSurfaceAngle") or (v61_.maxSurfaceAngle or 0.4537856055185257)
		v61_.fillToGroundScale = xmlFile:getValue(key .. "#fillToGroundScale") or (v61_.fillToGroundScale or 1)
		v61_.allowsSmoothing = xmlFile:getValue(key .. "#allowsSmoothing", Utils.getNoNil(v61_.allowsSmoothing, false))
		v61_.collisionScale = xmlFile:getValue(key .. ".collision#scale") or (v61_.collisionScale or 1)
		v61_.collisionBaseOffset = xmlFile:getValue(key .. ".collision#baseOffset") or (v61_.collisionBaseOffset or 0)
		v61_.minCollisionOffset = xmlFile:getValue(key .. ".collision#minOffset") or (v61_.minCollisionOffset or 0)
		v61_.maxCollisionOffset = xmlFile:getValue(key .. ".collision#maxOffset") or (v61_.maxCollisionOffset or 1)
		v61_.canBeTipped = xmlFile:getValue(key .. "#canBeTipped", Utils.getNoNil(v61_.canBeTipped, true))
		if xmlFile:hasProperty(key .. ".visualHeightMapping") then
			v61_.visualHeightMapping = {}
			for _, v64_ in xmlFile:iterator(key .. ".visualHeightMapping.mapping") do
				local v65_ = {
					["realValue"] = xmlFile:getValue(v64_ .. "#realValue"),
					["visualValue"] = xmlFile:getValue(v64_ .. "#visualValue")
				}
				if v65_.realValue == nil or v65_.visualValue == nil then
					Logging.xmlError(xmlFile, "\'%s\' has invalid visual height mapping!", v64_)
				else
					local v66_ = v61_.visualHeightMapping
					table.insert(v66_, v65_)
				end
			end
			table.sort(v61_.visualHeightMapping, function(p67_, p68_)
				return p67_.realValue < p68_.realValue
			end)
		end
	end
end

function DensityMapHeightManager:getDensityMapHeightTypeByIndex(index)
	if index == nil then
		return nil
	else
		return self.heightTypes[index]
	end
end

function DensityMapHeightManager:getFillTypeNameByDensityHeightMapIndex(index)
	if index == nil or self.heightTypes[index] == nil then
		return nil
	else
		return self.heightTypes[index].fillTypeName
	end
end

function DensityMapHeightManager:getFillTypeIndexByDensityHeightMapIndex(index)
	if index == nil or self.heightTypes[index] == nil then
		return nil
	else
		return self.heightTypes[index].fillTypeIndex
	end
end

function DensityMapHeightManager:getDensityMapHeightTypeByFillTypeName(fillTypeName)
	if fillTypeName == nil then
		return nil
	else
		return self.fillTypeNameToHeightType[fillTypeName]
	end
end

function DensityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(fillTypeIndex)
	if fillTypeIndex == nil then
		return nil
	else
		return self.fillTypeIndexToHeightType[fillTypeIndex]
	end
end

function DensityMapHeightManager:getDensityMapHeightTypeIndexByFillTypeName(fillTypeName)
	if fillTypeName == nil or self.fillTypeNameToHeightType[fillTypeName] == nil then
		return nil
	else
		return self.fillTypeNameToHeightType[fillTypeName].index
	end
end

function DensityMapHeightManager:getDensityMapHeightTypeIndexByFillTypeIndex(fillTypeIndex)
	if fillTypeIndex == nil or self.fillTypeIndexToHeightType[fillTypeIndex] == nil then
		return nil
	else
		return self.fillTypeIndexToHeightType[fillTypeIndex].index
	end
end

function DensityMapHeightManager:getDensityMapHeightTypes()
	return self.heightTypes
end

function DensityMapHeightManager:getFillTypeToDensityMapHeightTypes()
	return self.fillTypeIndexToHeightType
end

function DensityMapHeightManager:setFixedFillTypesArea(area, fillTypes)
	self.fixedFillTypesAreas[area] = {
		["fillTypes"] = fillTypes
	}
end

function DensityMapHeightManager:removeFixedFillTypesArea(area)
	self.fixedFillTypesAreas[area] = nil
end

function DensityMapHeightManager:getFixedFillTypesAreas()
	return self.fixedFillTypesAreas
end

function DensityMapHeightManager:setConvertingFillTypeAreas(area, fillTypes, fillTypeTarget)
	self.convertingFillTypesAreas[area] = {
		["fillTypes"] = fillTypes,
		["fillTypeTarget"] = fillTypeTarget
	}
end

function DensityMapHeightManager:removeConvertingFillTypeAreas(area)
	self.convertingFillTypesAreas[area] = nil
end

function DensityMapHeightManager:getConvertingFillTypesAreas()
	return self.convertingFillTypesAreas
end

-- Local values: typeMappings, numUsedMappings, _, entry, name, oldTypeIndex, numMappings, _, _
function DensityMapHeightManager:checkTypeMappings()
	local v99_ = self.tipTypeMappings
	if v99_ ~= nil and next(v99_) ~= nil then
		local v100_ = 0
		for _, v101_ in ipairs(self.heightTypes) do
			local v102_ = v99_[g_fillTypeManager:getFillTypeNameByIndex(v101_.fillTypeIndex)]
			if v102_ == nil or v102_ ~= v101_.index then
				return false
			end
			v100_ = v100_ + 1
		end
		local v103_ = 0
		for _, _ in pairs(v99_) do
			v103_ = v103_ + 1
		end
		if v103_ ~= v100_ then
			return false
		end
	end
	return true
end

-- Local values: id, densitySize, deform, placementMapSize, litersPerMeter, maxHeight, unitLength, maxHeightDensityValue, heightFirstChannel, heightNumChannels, typeFirstChannel, typeNumChannels, densityMapHeightCollisionMask, displacementHeightCollisionMask, numUsedMappings, heightTypes, _, entry, oldTypeIndex, name, fillTypeName, forceTypeConversion, numMappings, _, _, missionInfo, collisionMapValid, savegameFilename, cleanupHeights, placementCollisionMapValid, savegameFilename, sizeX, _sizeZ, tipCollisionMapSize, tipCollisionCellsize, placementCollisionMapSize, placementCellsize
function DensityMapHeightManager:initialize(isServer, tipCollisionMap, placementCollisionMap)
	local v108_ = g_currentMission.terrainDetailHeightId
	self.tipToGroundIsAllowed = true
	local v109_ = getDensityMapSize(v108_)
	local v110_ = TerrainDeformation.new(g_terrainNode)
	local v111_ = v110_:getBlockedAreaMapSize()
	v110_:cancel()
	v110_:delete()
	self.worldToDensityMap = v109_ / g_currentMission.terrainSize
	self.densityToWorldMap = g_currentMission.terrainSize / v109_
	self.worldToPlacementMap = v111_ / g_currentMission.terrainSize
	self.placementToWorldMap = g_currentMission.terrainSize / v111_
	self.pendingCollisionRecalculateAreas = {}
	self.collisionRecalculateAreaSize = 16
	self.collisionRecalculateAreaWorldSize = self.collisionRecalculateAreaSize * self.densityToWorldMap
	local v112_ = (v109_ + self.collisionRecalculateAreaSize - 1) / self.collisionRecalculateAreaSize
	self.numCollisionRecalculateAreasPerSide = math.floor(v112_)
	local v113_ = 250
	local v114_ = getDensityMapMaxHeight(v108_)
	local v115_ = g_currentMission.terrainSize / v109_
	self.volumePerPixel = v114_ * v115_ * v115_
	self.literPerPixel = v113_ * v114_ * self.volumePerPixel
	self.fillToGroundScale = self.worldToDensityMap ^ 2 / (v113_ * v114_)
	local v116_ = 2 ^ getDensityMapHeightNumChannels(v108_) - 1
	self.minValidLiterValue = self.literPerPixel / v116_
	self.minValidVolumeValue = self.volumePerPixel / v116_
	self.heightToDensityValue = v116_ / v114_
	local v117_ = getDensityMapHeightFirstChannel(v108_)
	local v118_ = getDensityMapHeightNumChannels(v108_)
	local v119_ = self.heightTypeFirstChannel
	local v120_ = self.heightTypeNumChannels
	if v117_ < v119_ + v120_ and v119_ < v117_ + v118_ then
		Logging.warning("Density map height type channels [%d-%d] are overlapping with the density map height channels [%d-%d]. This will lead to unexpected results.", v119_, v119_ + v120_ - 1, v117_, v117_ + v118_ - 1)
	end
	local v121_ = CollisionFlag.TERRAIN_DELTA
	local v122_ = CollisionFlag.TERRAIN_DISPLACEMENT
	self.terrainDetailHeightUpdater = createDensityMapHeightUpdater("TerrainDetailHeightUpdater", v108_, v119_, v120_, v121_, v122_)
	local v123_ = 0
	local v124_ = self:getDensityMapHeightTypes()
	if v124_ ~= nil then
		for _, v125_ in ipairs(v124_) do
			local v126_ = v125_.index
			if self.tipTypeMappings ~= nil and next(self.tipTypeMappings) ~= nil then
				local v127_ = g_fillTypeManager:getFillTypeNameByIndex(v125_.fillTypeIndex)
				local v128_ = string.lower(v127_)
				v126_ = self.tipTypeMappings[v128_] or -1
				if v126_ >= 0 then
					v123_ = v123_ + 1
				end
			end
			setDensityMapHeightTypeProperties(self.terrainDetailHeightUpdater, v125_.index, v126_, v125_.maxSurfaceAngle, v125_.collisionScale, v125_.collisionBaseOffset, v125_.minCollisionOffset, v125_.maxCollisionOffset)
		end
	end
	g_fillTypeManager:constructFillTypeDistanceTextureArray(g_currentMission.terrainDetailHeightId, v119_, v120_, v124_)
	local v129_ = false
	if self.tipTypeMappings ~= nil then
		local v130_ = 0
		for _, _ in pairs(self.tipTypeMappings) do
			v130_ = v130_ + 1
		end
		if v130_ ~= v123_ then
			v129_ = true
		end
	end
	initDensityMapHeightTypeProperties(self.terrainDetailHeightUpdater, v129_)
	local v131_ = g_currentMission.missionInfo
	if isServer then
		self.tipCollisionMap = tipCollisionMap
		self.tipCollisionMapCreated = false
		if tipCollisionMap == 0 then
			self.tipCollisionMap = createBitVectorMap("CollisionMap")
			self.tipCollisionMapCreated = true
		end
		local v132_ = false
		if not GS_IS_MOBILE_VERSION and v131_:getIsTipCollisionValid(g_currentMission) then
			local v133_ = v131_.savegameDirectory .. "/" .. DensityMapHeightManager.GENERATED_TIP_COLLISION_FILENAME
			if loadBitVectorMapFromFile(self.tipCollisionMap, v133_, 2) and setDensityMapHeightCollisionMap(self.terrainDetailHeightUpdater, self.tipCollisionMap, false) then
				v132_ = true
			else
				Logging.warning("Failed to load savegame tip collision map \'" .. v133_ .. "\'. Loading default tip collision map and recreating from placeables.")
			end
		end
		if not v132_ then
			local v134_ = v131_.isValid and true or false
			if self.tipCollisionMapCreated or not setDensityMapHeightCollisionMap(self.terrainDetailHeightUpdater, self.tipCollisionMap, v134_) then
				Logging.warning("No tip collision map defined. Creating empty tip placement collision map.")
				loadBitVectorMapNew(self.tipCollisionMap, v109_, v109_, 2, false)
				setDensityMapHeightCollisionMap(self.terrainDetailHeightUpdater, self.tipCollisionMap, v134_)
			end
		end
	end
	if not GS_IS_MOBILE_VERSION then
		self.placementCollisionMap = placementCollisionMap
		self.placementCollisionMapCreated = false
		if placementCollisionMap == 0 then
			self.placementCollisionMap = createBitVectorMap("PlacementCollisionMap")
			self.placementCollisionMapCreated = true
		end
		local v135_ = false
		if v131_:getIsPlacementCollisionValid(g_currentMission) then
			local v136_ = v131_.savegameDirectory .. "/" .. DensityMapHeightManager.GENERATED_PLACEMENT_COLLISION_FILENAME
			if loadBitVectorMapFromFile(self.placementCollisionMap, v136_, 1) then
				local v137_, _ = getBitVectorMapSize(self.placementCollisionMap)
				if v137_ == v111_ then
					v135_ = true
				else
					Logging.warning("Savegame placement collision map %q size %d does not match expected size %d", v136_, v137_, v111_)
				end
			else
				Logging.warning("Failed to load savegame placement collision map \'" .. v136_ .. "\'. Loading default placement collision map and recreating from placeables.")
			end
		end
		if not v135_ and self.placementCollisionMapCreated then
			Logging.warning("No placement collision map defined. Creating empty placement collision map.")
			loadBitVectorMapNew(self.placementCollisionMap, v111_, v111_, 1, false)
		end
	end
	g_fillTypeManager:constructTerrainFillLayers(v124_, g_terrainNode)
	if self.tipCollisionMap ~= nil then
		local v_u_138_ = getBitVectorMapSize(self.tipCollisionMap)
		local v139_ = g_currentMission.terrainSize / v_u_138_
		self.debugBitVectorMapTipCollisions = DebugBitVectorMap.newSimple(10, v139_, true, 0.2, nil, true)
		self.debugBitVectorMapTipCollisions.valueToColor = {
			[0] = Color.PRESETS.GREEN:copy(),
			[1] = Color.PRESETS.BLUE:copy(),
			[2] = Color.PRESETS.RED:copy()
		}
		self.debugBitVectorMapTipCollisions:createWithCustomFunc(function(_, p140_, p141_, p142_, p143_, p144_, p145_)
			-- upvalues: (copy) v_u_138_, (copy) self
			local v146_ = (p140_ + p142_ + p144_) / 3
			local v147_ = (p141_ + p143_ + p145_) / 3
			local v148_ = g_currentMission.terrainSize
			local v149_ = 0.5 + v_u_138_ * (v146_ + v148_ * 0.5) / v148_
			local v150_ = math.floor(v149_)
			local v151_ = 0.5 + v_u_138_ * (v147_ + v148_ * 0.5) / v148_
			local v152_ = math.floor(v151_)
			return getBitVectorMapPoint(self.tipCollisionMap, v150_, v152_, 0, 2)
		end)
	end
	if self.placementCollisionMap ~= nil then
		local v_u_153_ = getBitVectorMapSize(self.placementCollisionMap)
		local v154_ = g_currentMission.terrainSize / v_u_153_
		self.debugBitVectorMapPlacementCollisions = DebugBitVectorMap.newSimple(10, v154_, true, 0.2)
		self.debugBitVectorMapPlacementCollisions.valueToColor = {
			[0] = Color.PRESETS.GREEN:copy(),
			[1] = Color.PRESETS.RED:copy()
		}
		self.debugBitVectorMapPlacementCollisions:createWithCustomFunc(function(_, p155_, p156_, p157_, p158_, p159_, p160_)
			-- upvalues: (copy) v_u_153_, (copy) self
			local v161_ = (p155_ + p157_ + p159_) / 3
			local v162_ = (p156_ + p158_ + p160_) / 3
			local v163_ = g_currentMission.terrainSize
			local v164_ = 0.5 + v_u_153_ * (v161_ + v163_ * 0.5) / v163_
			local v165_ = math.floor(v164_)
			local v166_ = 0.5 + v_u_153_ * (v162_ + v163_ * 0.5) / v163_
			local v167_ = math.floor(v166_)
			return getBitVectorMapPoint(self.placementCollisionMap, v165_, v167_, 0, 1)
		end)
	end
end

function DensityMapHeightManager:getIsValid()
	return self.terrainDetailHeightUpdater ~= nil
end

function DensityMapHeightManager:getTerrainDetailHeightUpdater()
	return self.terrainDetailHeightUpdater
end

-- Local values: heightType
function DensityMapHeightManager:getMinValidLiterValue(fillTypeIndex)
	local v172_ = self:getDensityMapHeightTypeByFillTypeIndex(fillTypeIndex)
	return v172_ == nil and 0 or self.minValidLiterValue / v172_.fillToGroundScale
end

-- Local values: heightType, literPerPixel
function DensityMapHeightManager:getMinValidLiterValuePerSqm(fillTypeIndex)
	local v175_ = self:getDensityMapHeightTypeByFillTypeIndex(fillTypeIndex)
	return v175_ == nil and 0 or self.minValidLiterValue / v175_.fillToGroundScale / (self.densityToWorldMap * self.densityToWorldMap)
end

-- Local values: num, terrainHalfSize, areaIndex, loopIndex, zi, xi, minX, minZ
function DensityMapHeightManager:update(dt)
	if self.terrainDetailHeightUpdater == nil then
		return
	end
	local v177_ = g_currentMission.terrainSize * 0.5
	local v178_ = 0
	for v179_, v180_ in pairs(self.pendingCollisionRecalculateAreas) do
		if v180_ <= g_updateLoopIndex then
			self.pendingCollisionRecalculateAreas[v179_] = nil
			local v181_ = v179_ / self.numCollisionRecalculateAreasPerSide
			local v182_ = math.floor(v181_)
			local v183_ = (v179_ - v182_ * self.numCollisionRecalculateAreasPerSide) * self.collisionRecalculateAreaWorldSize - v177_
			local v184_ = v182_ * self.collisionRecalculateAreaWorldSize - v177_
			self:updateCollisionMap(v183_, v184_, v183_ + self.collisionRecalculateAreaWorldSize, v184_ + self.collisionRecalculateAreaWorldSize, false)
			v178_ = v178_ + 1
			if v178_ > 6 then
				break
			end
		end
	end
end

function DensityMapHeightManager:saveCollisionMap(directory)
	if self.tipCollisionMap ~= nil then
		saveBitVectorMapToFile(self.tipCollisionMap, directory .. "/" .. DensityMapHeightManager.GENERATED_TIP_COLLISION_FILENAME)
	end
end

function DensityMapHeightManager:prepareSaveCollisionMap(directory)
	if self.tipCollisionMap ~= nil then
		prepareSaveBitVectorMapToFile(self.tipCollisionMap, directory .. "/" .. DensityMapHeightManager.GENERATED_TIP_COLLISION_FILENAME)
	end
end

function DensityMapHeightManager:savePreparedCollisionMap(callback, callbackObject)
	if self.tipCollisionMap ~= nil then
		savePreparedBitVectorMapToFile(self.tipCollisionMap, callback, callbackObject)
	end
end

function DensityMapHeightManager:savePlacementCollisionMap(directory)
	if self.placementCollisionMap ~= nil then
		saveBitVectorMapToFile(self.placementCollisionMap, directory .. "/" .. DensityMapHeightManager.GENERATED_PLACEMENT_COLLISION_FILENAME)
	end
end

function DensityMapHeightManager:prepareSavePlacementCollisionMap(directory)
	if self.placementCollisionMap ~= nil then
		prepareSaveBitVectorMapToFile(self.placementCollisionMap, directory .. "/" .. DensityMapHeightManager.GENERATED_PLACEMENT_COLLISION_FILENAME)
	end
end

function DensityMapHeightManager:savePreparedPlacementCollisionMap(callback, callbackObject)
	if self.placementCollisionMap ~= nil then
		savePreparedBitVectorMapToFile(self.placementCollisionMap, callback, callbackObject)
	end
end

-- Local values: terrainHalfSize, minXi, minZi, maxXi, maxZi, zi, xi, areaIndex, frameOffset
function DensityMapHeightManager:setCollisionMapAreaDirty(minX, minZ, maxX, maxZ, delayed)
	local v205_ = g_currentMission.terrainSize * 0.5
	local v206_ = (minX + v205_) / self.collisionRecalculateAreaWorldSize
	local v207_ = math.floor(v206_)
	local v208_ = (minZ + v205_) / self.collisionRecalculateAreaWorldSize
	local v209_ = math.floor(v208_)
	local v210_ = (maxX + v205_) / self.collisionRecalculateAreaWorldSize
	local v211_ = math.ceil(v210_)
	local v212_ = (maxZ + v205_) / self.collisionRecalculateAreaWorldSize
	for v213_ = v209_, math.ceil(v212_) do
		for v214_ = v207_, v211_ do
			local v215_ = v213_ * self.numCollisionRecalculateAreasPerSide + v214_
			self.pendingCollisionRecalculateAreas[v215_] = g_updateLoopIndex + (delayed and 2 or 0)
		end
	end
end

-- Local values: terrainHalfSize
function DensityMapHeightManager:updateCollisionMap(minX, minZ, maxX, maxZ, synchronous)
	if self.tipCollisionMap ~= nil or self.placementCollisionMap ~= nil then
		local v222_ = g_currentMission.terrainSize * 0.5
		local v223_ = -v222_
		local v224_ = math.clamp(minX, v223_, v222_)
		local v225_ = -v222_
		local v226_ = math.clamp(minZ, v225_, v222_)
		local v227_ = -v222_
		local v228_ = math.clamp(maxX, v227_, v222_)
		local v229_ = -v222_
		local v230_ = math.clamp(maxZ, v229_, v222_)
		local v231_ = synchronous == nil and true or synchronous
		if self.tipCollisionMap ~= nil then
			updateTerrainCollisionMap(self.tipCollisionMap, g_terrainNode, "tipCollision", 0, self.tipCollisionMask, v224_, v226_, v228_, v230_, v231_)
		end
		if self.placementCollisionMap ~= nil then
			updatePlacementCollisionMap(self.placementCollisionMap, g_terrainNode, "placementCollision", 0, self.placementCollisionMask, v224_, v226_, v228_, v230_, v231_)
		end
	end
end
local v_u_232_ = nil
local v_u_233_ = nil
local function v241_(p234_, p235_, p236_, p237_, p238_, p239_, p240_)
	-- upvalues: (ref) v_u_232_, (ref) v_u_233_
	if p234_.placementCollisionMap == nil then
		return false
	end
	if v_u_232_ == nil then
		v_u_232_ = DensityMapModifier.new(p234_.placementCollisionMap, 0, 1, g_terrainNode)
		v_u_233_ = DensityMapFilter.new(p234_.placementCollisionMap, 0, 1)
	end
	v_u_232_:setParallelogramWorldCoords(p235_, p236_, p237_, p238_, p239_ or p235_ + 0.05, p240_ or p236_, DensityCoordType.POINT_POINT_POINT)
	v_u_233_:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
	return v_u_232_:executeGet(v_u_233_) > 0
end
DensityMapHeightManager.getIsPlacementAreaBlocked = v241_

-- Local values: _, area
function DensityMapHeightManager:getIsInFreeAccessArea(sx, sz, ex, ez)
	for _, v247_ in ipairs(self.freeAccessAreas) do
		if MathUtil.vector2Length(v247_.x - sx, v247_.z - sz) <= v247_.radius and MathUtil.vector2Length(v247_.x - ex, v247_.z - ez) <= v247_.radius then
			return true
		end
	end
	return false
end

-- Local values: usage, fillTypeIndex, availableFillTypes, availableFillTypes, mission, player, controlledVehicle, x, y, z, dirX, _, dirZ, playerYaw, amountTipped, initialOffset, i, offset, lx, ly, lz, height
function DensityMapHeightManager:consoleCommandTipAnywhereAdd(fillTypeName, amount, length, rows, spacing)
	local v254_ = "Usage: gsTipAnywhereAdd fillTypeName amount [length] [rows] [spacing]"
	if fillTypeName == nil then
		printError("Error: No filltype given")
		return v254_
	end
	local v255_ = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
	if v255_ == nil then
		local v256_ = g_fillTypeManager:getFillTypeNamesByIndices(self.fillTypeIndexToHeightType)
		printError(string.format("Error: Invalid fillType \'%s\'", fillTypeName))
		return string.format("Available fillTypes: %s", table.concat(v256_, ", "))
	end
	if self.fillTypeIndexToHeightType[v255_] == nil then
		local v257_ = g_fillTypeManager:getFillTypeNamesByIndices(self.fillTypeIndexToHeightType)
		printError(string.format("Error: fillType \'%s\' not supported by tip anywhere", fillTypeName))
		return string.format("Available fillTypes: %s", table.concat(v257_, ", "))
	end
	local v258_ = tonumber(amount)
	if v258_ == nil then
		printError("Error: no amount given")
		return v254_
	end
	local v259_ = Utils.getNoNil(tonumber(length), 1)
	local v260_ = Utils.getNoNil(tonumber(rows), 1)
	local v261_ = Utils.getNoNil(tonumber(spacing), 3)
	local v262_ = g_currentMission
	local v263_ = g_localPlayer
	local v264_ = v263_:getCurrentVehicle()
	local v265_ = 0
	local v266_ = 0
	local v267_ = 0
	local v268_ = 1
	local v269_ = 0
	if v263_ == nil or not v263_:getIsControlled() then
		if v264_ ~= nil then
			v265_, v266_, v267_ = getWorldTranslation(v264_.rootNode)
			local v270_
			v268_, v270_, v269_ = localDirectionToWorld(v264_.rootNode, 0, 0, 1)
		end
	elseif v263_.rootNode ~= nil and v263_.rootNode ~= 0 then
		v265_, v266_, v267_ = getWorldTranslation(v263_.rootNode)
		local v271_ = v263_.mover:getMovementYaw() + 1.5707963267948966
		v268_ = -math.cos(v271_)
		v269_ = math.sin(v271_)
	end
	local v272_ = (v260_ - 1) * v261_ * -0.5
	local v273_ = 0
	for v274_ = 0, v260_ - 1 do
		local v275_ = v272_ + v274_ * v261_
		local v276_ = v265_ + v275_ * v269_
		local v277_ = v267_ + v275_ * -v268_
		v273_ = v273_ + DensityMapHeightUtil.tipToGroundAroundLine(v264_, v258_, v255_, v276_, v266_, v277_, v276_ + v259_ * v268_, v266_, v277_ + v259_ * v269_, 10, 40, nil, nil, nil, nil)
	end
	if v262_.controlPlayer and v263_ ~= nil then
		local v278_ = DensityMapHeightUtil.getHeightAtWorldPos(v265_, v266_, v267_)
		v263_.mover:teleportTo(v265_, v278_, v267_)
	end
	return string.format("Tipped %dl of %s", v273_, fillTypeName)
end

-- Local values: player, controlledVehicle, x, y, z, dirX, _, dirZ, playerYaw, amounts, sideOffsets, heapSpacing, heightTypeIndex, heightType, amountIndex, amount, sideOffset, x1, z1, x2, z2, debugString, yRot, debugText
function DensityMapHeightManager:consoleCommandTipAnywhereAddAll()
	local v280_ = g_localPlayer
	local v281_ = v280_:getCurrentVehicle()
	local v282_ = 0
	local v283_ = 0
	local v284_ = 0
	local v285_ = 1
	local v286_ = 0
	if v280_ == nil or not v280_:getIsControlled() then
		if v281_ ~= nil then
			v282_, v283_, v284_ = getWorldTranslation(v281_.rootNode)
			local v287_
			v285_, v287_, v286_ = localDirectionToWorld(v281_.rootNode, 0, 0, 1)
		end
	elseif v280_.rootNode ~= nil and v280_.rootNode ~= 0 then
		v282_, v283_, v284_ = getWorldTranslation(v280_.rootNode)
		local v288_ = v280_.mover:getMovementYaw() + 1.5707963267948966
		v285_ = -math.cos(v288_)
		v286_ = math.sin(v288_)
	end
	local v289_ = v282_ + v285_ * 10
	local v290_ = v284_ + v286_ * 10
	local v291_ = {
		0,
		100,
		1000,
		5000,
		10000,
		999999
	}
	local v292_ = {
		-4,
		-1.5,
		2,
		8,
		16,
		26
	}
	for v293_ = 1, #self.heightTypes do
		local v294_ = self.heightTypes[v293_]
		for v295_, v296_ in ipairs(v291_) do
			local v297_ = v292_[v295_]
			local v298_ = v289_ + v285_ * v293_ * 10
			local v299_ = v290_ + v286_ * v293_ * 10
			local v300_ = v298_ + v286_ * v297_
			local v301_ = v299_ - v285_ * v297_
			local v302_ = v300_ + v285_ * 1
			local v303_ = v301_ + v286_ * 1
			local v304_ = g_densityMapHeightManager:getMinValidLiterValue(v294_.fillTypeIndex)
			local v305_ = math.max(v304_, v296_)
			DensityMapHeightUtil.tipToGroundAroundLine(v281_, v305_, v294_.fillTypeIndex, v300_, v283_, v301_, v302_, v283_, v303_, 10, 40, nil, nil, nil, nil)
			local v306_ = string.format("%s (%.2f)", g_fillTypeManager:getFillTypeNameByIndex(v294_.fillTypeIndex), v305_)
			local v307_ = MathUtil.getYRotationFromDirection(-v285_, -v286_)
			local v308_ = DebugText3D.new():createWithWorldPos(v300_ - v285_ * 2, v283_ + 2, v301_ - v286_ * 2, 0, v307_, 0, v306_, 0.2)
			g_debugManager:addElement(v308_, nil, nil, math.huge)
		end
	end
end

-- Local values: usage, size, mission, player, controlledVehicle, terrainSizeHalf, x0, z0, x1, z1, x2, z2, node, sizeHalf, _
function DensityMapHeightManager:consoleCommandTipAnywhereClear(sizeStr)
	local v310_ = "Usage: gsTipAnywhereClear sizeToClearMeters"
	if sizeStr == nil then
		printError("Error: Missing sizeToClearMeters parameter")
		return v310_
	end
	local v311_ = tonumber(sizeStr)
	if v311_ == nil then
		printError(string.format("Error: invalid size %q, provide a number", sizeStr))
		return v310_
	end
	local v312_ = g_currentMission
	local v313_ = g_localPlayer
	local v314_ = v313_:getCurrentVehicle()
	local v315_ = v312_.terrainSize * 0.5
	local v316_ = -v315_
	local v317_ = -v315_
	local v318_ = -v315_
	local v319_ = nil
	if v313_ == nil or not v313_:getIsControlled() then
		if v314_ ~= nil then
			v319_ = v314_.rootNode
		end
	elseif v313_ ~= nil and (v313_.rootNode ~= nil and v313_.rootNode ~= 0) then
		v319_ = v313_.rootNode
	end
	local v320_, v321_
	if v319_ == nil then
		v320_ = v315_
		v321_ = v320_
		local v322_ = v320_
		v320_ = v321_
		v322_ = v321_
	else
		local v323_ = v311_ * 0.5
		local v324_
		v316_, v324_, v315_ = localToWorld(v319_, -v323_, 0, v323_)
		local v325_
		v321_, v325_, v320_ = localToWorld(v319_, v323_, 0, v323_)
		local v326_
		v317_, v326_, v318_ = localToWorld(v319_, -v323_, 0, -v323_)
	end
	DensityMapHeightUtil.clearArea(v316_, v315_, v321_, v320_, v317_, v318_)
	return "Cleared area (" .. v311_ .. "m)"
end

function DensityMapHeightManager:consoleCommandToggleDebug()
	DensityMapHeightManager.DEBUG_ENABLED = not DensityMapHeightManager.DEBUG_ENABLED
	g_debugManager:setGroupVisibility(DensityMapHeightManager.DEBUG_GROUP_ID, DensityMapHeightManager.DEBUG_ENABLED)
	local v327_ = string.format
	local v328_ = DensityMapHeightManager.DEBUG_ENABLED
	return v327_("DensityMapHeightManager.DEBUG_ENABLED = %s", (tostring(v328_)))
end

function DensityMapHeightManager:consoleCommandShowTipCollisions(active)
	if StartParams.getIsSet("scriptDebug") then
		DensityMapHeightManager.DEBUG_TIP_COLLISIONS = Utils.getNoNil(active, not DensityMapHeightManager.DEBUG_TIP_COLLISIONS)
		if DensityMapHeightManager.DEBUG_TIP_COLLISIONS then
			self.debugBitVectorMapTipCollisionsId = g_debugManager:addElement(self.debugBitVectorMapTipCollisions)
		elseif self.debugBitVectorMapTipCollisionsId ~= nil then
			g_debugManager:removeElementById(self.debugBitVectorMapTipCollisionsId)
			self.debugBitVectorMapTipCollisionsId = nil
		end
		local v331_ = string.format
		local v332_ = DensityMapHeightManager.DEBUG_TIP_COLLISIONS
		return v331_("DensityMapHeightManager.DEBUG_TIP_COLLISIONS = %s\nEnable debug view (F5) to render collision information", (tostring(v332_)))
	end
	printError("Error: Game must be started with \'-scriptDebug\' parameter")
end

function DensityMapHeightManager:consoleCommandShowPlacementCollisions(active)
	if StartParams.getIsSet("scriptDebug") then
		DensityMapHeightManager.DEBUG_PLACEMENT_COLLISIONS = Utils.getNoNil(active, not DensityMapHeightManager.DEBUG_PLACEMENT_COLLISIONS)
		if DensityMapHeightManager.DEBUG_PLACEMENT_COLLISIONS then
			self.debugBitVectorMapPlacementCollisionsId = g_debugManager:addElement(self.debugBitVectorMapPlacementCollisions)
		elseif self.debugBitVectorMapPlacementCollisionsId ~= nil then
			g_debugManager:removeElementById(self.debugBitVectorMapPlacementCollisionsId)
			self.debugBitVectorMapPlacementCollisionsId = nil
		end
		local v335_ = string.format
		local v336_ = DensityMapHeightManager.DEBUG_PLACEMENT_COLLISIONS
		return v335_("DensityMapHeightManager.DEBUG_PLACEMENT_COLLISIONS = %s\nEnable debug view (F5) to render collision information", (tostring(v336_)))
	end
	printError("Error: Game must be started with \'-scriptDebug\' parameter")
end

-- Local values: x, _, z, halfWidth
function DensityMapHeightManager:consoleCommandUpdateTipCollisions(width)
	local v339_, _, v340_ = getWorldTranslation(g_cameraManager:getActiveCamera())
	local v341_ = tonumber(width) or 20
	local v342_ = math.clamp(v341_, 2, 1000)
	local v343_ = v342_ / 2
	self:updateCollisionMap(v339_ - v343_, v340_ - v343_, v339_ + v343_, v340_ + v343_)
	return string.format("Updated tipCollision in a %ix%i area around the camera. Add a number as a parameter to update a custom area", v342_, v342_)
end
g_densityMapHeightManager = DensityMapHeightManager.new()
