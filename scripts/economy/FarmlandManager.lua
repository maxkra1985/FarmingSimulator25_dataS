-- Local values: FarmlandManager_mt
FarmlandManager = {}
FarmlandManager.NO_OWNER_FARM_ID = 0
FarmlandManager.NOT_BUYABLE_FARM_ID = GS_IS_MOBILE_VERSION and 15 or 255
local FarmlandManager_mt = Class(FarmlandManager, AbstractManager)
g_xmlManager:addCreateSchemaFunction(function()
	FarmlandManager.xmlSchema = XMLSchema.new("farmlands")
end)
g_xmlManager:addInitSchemaFunction(function()
	Mission00.xmlSchema:register(XMLValueType.STRING, "map.farmlands#filename", "Filename of the farmland definition config")
	local v2_ = FarmlandManager.xmlSchema
	v2_:register(XMLValueType.STRING, "map.farmlands#infoLayer", "Name of the info layer", nil, false)
	v2_:register(XMLValueType.STRING, "map.farmlands#densityMapFilename", "Filename of the info layer", nil, false)
	v2_:register(XMLValueType.INT, "map.farmlands#numChannels", "Number of channels of the info layer", 8, false)
	v2_:register(XMLValueType.FLOAT, "map.farmlands#pricePerHa", "Price per Ha", 60000, false)
	Farmland.registerXMLPaths(v2_, "map.farmlands.farmland(?)")
end)

-- Upvalues: FarmlandManager_mt
-- Local values: self
function FarmlandManager.new(customMt)
	-- upvalues: (copy) FarmlandManager_mt
	return AbstractManager.new(customMt or FarmlandManager_mt)
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

-- Local values: xmlFile, infoLayer, infoLayerName, bitVectorMapFilename, numberOfBits, success, farmlandSizeMapping, farmlandCenterData, farmlandBoundingBox, numOfFarmlands, maxFarmlandId, missingFarmlandDefinitions, x, y, value, boundingBox, isNewSavegame, _, key, farmland, shouldAddDefaults, index, _, transformFactor, pixelToSqm, id, farmland, ha, posX, posZ, boundingBox
function FarmlandManager:loadFarmlandData(xmlFileHandle)
	local v9_ = XMLFile.wrap(xmlFileHandle, FarmlandManager.xmlSchema)
	self.isLoadedFromTerrain = true
	local v10_ = v9_:getValue("map.farmlands#infoLayer")
	local v11_
	if v10_ == nil then
		v11_ = nil
	else
		v11_ = getInfoLayerFromTerrain(g_terrainNode, v10_)
		if v11_ == nil or v11_ == 0 then
			Logging.xmlWarning(v9_, "No info layer \'%s\' defined on terrain!", v10_)
		end
	end
	if v11_ == nil then
		local v12_ = v9_:getValue("map.farmlands#densityMapFilename")
		if v12_ == nil then
			Logging.xmlWarning(v9_, "Loading farmland file \'%s\' failed! Missing densityMapFilename", v12_)
			return false
		end
		local v13_ = Utils.getFilename(v12_, g_currentMission.baseDirectory)
		local v14_ = v9_:getValue("map.farmlands#numChannels") or 8
		v11_ = createBitVectorMap("FarmlandMap")
		if not loadBitVectorMapFromFile(v11_, v13_, v14_) then
			Logging.xmlWarning(v9_, "Loading farmland file \'%s\' failed!", v13_)
			v9_:delete()
			return false
		end
		self.isLoadedFromTerrain = false
	end
	self.pricePerHa = v9_:getValue("map.farmlands#pricePerHa") or 60000
	FarmlandManager.NOT_BUYABLE_FARM_ID = 2 ^ self.numberOfBits - 1
	self.localMap = v11_
	self.numberOfBits = getBitVectorMapNumChannels(self.localMap)
	local v15_, v16_ = getBitVectorMapSize(self.localMap)
	self.localMapWidth = v15_
	self.localMapHeight = v16_
	local v17_ = {}
	local v18_ = {}
	local v19_ = 0
	local v20_ = 0
	local v21_ = {}
	local v22_ = false
	for v23_ = 0, self.localMapWidth - 1 do
		for v24_ = 0, self.localMapHeight - 1 do
			local v25_ = getBitVectorMapPoint(self.localMap, v23_, v24_, 0, self.numberOfBits)
			if v25_ > 0 then
				if self.farmlandMapping[v25_] == nil then
					v21_[v25_] = 0
					v17_[v25_] = {
						["sumPosX"] = 0,
						["sumPosZ"] = 0
					}
					v18_[v25_] = {
						["minX"] = math.huge,
						["minZ"] = math.huge,
						["maxX"] = -math.huge,
						["maxZ"] = -math.huge
					}
					self.farmlandMapping[v25_] = FarmlandManager.NO_OWNER_FARM_ID
					v19_ = v19_ + 1
					v20_ = math.max(v25_, v20_)
				end
				v21_[v25_] = v21_[v25_] + 1
				v17_[v25_].sumPosX = v17_[v25_].sumPosX + (v23_ - 0.5)
				v17_[v25_].sumPosZ = v17_[v25_].sumPosZ + (v24_ - 0.5)
				local v26_ = v18_[v25_]
				local v27_ = v26_.minX
				local v28_ = v23_ - 0.5
				v26_.minX = math.min(v27_, v28_)
				local v29_ = v26_.minZ
				local v30_ = v24_ - 0.5
				v26_.minZ = math.min(v29_, v30_)
				local v31_ = v26_.maxX
				local v32_ = v23_ + 0.5
				v26_.maxX = math.max(v31_, v32_)
				local v33_ = v26_.maxZ
				local v34_ = v24_ + 0.5
				v26_.maxZ = math.max(v33_, v34_)
			else
				v22_ = true
			end
		end
	end
	if v22_ then
		Logging.xmlWarning(v9_, "Farmland-Id was not set for all pixels in farmland-infoLayer!")
	end
	local v35_ = not g_currentMission.missionInfo.isValid
	for _, v36_ in v9_:iterator("map.farmlands.farmland") do
		local v37_ = Farmland.new()
		if v37_:load(v9_, v36_) and (self.farmlands[v37_.id] == nil and self.farmlandMapping[v37_.id] ~= nil) then
			self.farmlands[v37_.id] = v37_
			local v38_ = self.sortedFarmlands
			table.insert(v38_, v37_)
			local v39_ = self.sortedFarmlandIds
			local v40_ = v37_.id
			table.insert(v39_, v40_)
			local v41_ = v35_ and g_currentMission.missionInfo.hasInitiallyOwnedFarmlands
			if v41_ then
				v41_ = not g_currentMission.missionDynamicInfo.isMultiplayer
			end
			if v41_ and (g_currentMission:getIsServer() and v37_.defaultFarmProperty) then
				self:setLandOwnership(v37_.id, FarmManager.SINGLEPLAYER_FARM_ID, true)
			end
		else
			if self.farmlandMapping[v37_.id] == nil then
				Logging.xmlError(v9_, "Farmland-Id \'%s\' not defined in farmland info layer. Skipping farmland definition!", v37_.id)
			end
			if self.farmlands[v37_.id] ~= nil then
				Logging.xmlError(v9_, "Farmland-id \'%s\' already exists! Ignore it!", v37_.id)
			end
			v37_:delete()
		end
	end
	for v42_, _ in pairs(self.farmlandMapping) do
		if v42_ ~= FarmlandManager.NOT_BUYABLE_FARM_ID and self.farmlands[v42_] == nil then
			Logging.xmlError(v9_, "Farmland-Id \'%d\' not defined in farmland xml file!", v42_)
		end
	end
	local v43_ = g_currentMission.terrainSize / self.localMapWidth
	local v44_ = v43_ * v43_
	for v45_, v46_ in pairs(self.farmlands) do
		v46_:setArea((MathUtil.areaToHa(v21_[v45_], v44_)))
		v46_:addMapHotspot()
		if v46_.xWorldPos == nil then
			v46_:setIndicatorPosition((v17_[v45_].sumPosX / v21_[v45_] - self.localMapWidth * 0.5) * v43_, (v17_[v45_].sumPosZ / v21_[v45_] - self.localMapHeight * 0.5) * v43_)
		end
		local v47_ = v18_[v45_]
		v47_.minX = (v47_.minX - self.localMapWidth * 0.5) * v43_
		v47_.minZ = (v47_.minZ - self.localMapHeight * 0.5) * v43_
		v47_.maxX = (v47_.maxX - self.localMapWidth * 0.5) * v43_
		v47_.maxZ = (v47_.maxZ - self.localMapHeight * 0.5) * v43_
		v46_:setBoundingBox(v47_)
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
	v9_:delete()
	return true
end

-- Local values: _, farmland
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
		for _, v49_ in pairs(self.farmlands) do
			v49_:delete()
		end
	end
	FarmlandManager:superClass().unloadMapData(self)
end

-- Local values: xmlFile, index, farmlandId, farmId, farmlandKey
function FarmlandManager:saveToXMLFile(xmlFilename)
	local v52_ = createXMLFile("farmlandsXML", xmlFilename, "farmlands")
	if v52_ == 0 then
		Logging.error("Failed to create farmlands xml file")
		return false
	end
	local v53_ = 0
	for v54_, v55_ in pairs(self.farmlandMapping) do
		local v56_ = string.format("farmlands.farmland(%d)", v53_)
		setXMLInt(v52_, v56_ .. "#id", v54_)
		setXMLInt(v52_, v56_ .. "#farmId", Utils.getNoNil(v55_, FarmlandManager.NO_OWNER_FARM_ID))
		v53_ = v53_ + 1
	end
	saveXMLFile(v52_)
	delete(v52_)
	return true
end

-- Local values: xmlFile, farmlandCounter, key, farmlandId, farmId
function FarmlandManager:loadFromXMLFile(xmlFilename)
	if xmlFilename == nil then
		return false
	end
	local v59_ = loadXMLFile("farmlandXML", xmlFilename)
	if v59_ == 0 then
		return false
	end
	local v60_ = 0
	while true do
		local v61_ = string.format("farmlands.farmland(%d)", v60_)
		local v62_ = getXMLInt(v59_, v61_ .. "#id")
		if v62_ == nil then
			break
		end
		local v63_ = getXMLInt(v59_, v61_ .. "#farmId")
		if FarmlandManager.NO_OWNER_FARM_ID < v63_ then
			self:setLandOwnership(v62_, v63_, true)
		end
		v60_ = v60_ + 1
	end
	delete(v59_)
	g_farmManager:mergeFarmlandsForSingleplayer()
	return true
end

function FarmlandManager:delete() end

function FarmlandManager:getLocalMap()
	return self.localMap
end

-- Local values: farmlandId
function FarmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, worldPosX, worldPosZ)
	if farmId == FarmlandManager.NO_OWNER_FARM_ID or farmId == nil then
		return false
	end
	local v69_ = self:getFarmlandIdAtWorldPosition(worldPosX, worldPosZ)
	return self.farmlandMapping[v69_] == farmId
end

-- Local values: length, bitmapToWorld, step, alpha, x, z, localPosX, localPosZ, farmlandId
function FarmlandManager:getIsOwnedByFarmAlongLine(farmId, worldPosX1, worldPosZ1, worldPosX2, worldPosZ2)
	if farmId == FarmlandManager.NO_OWNER_FARM_ID or farmId == nil then
		return false
	end
	if self.localMap == nil then
		return false
	end
	local v76_ = MathUtil.vector2Length(worldPosX1 - worldPosX2, worldPosZ1 - worldPosZ2)
	if v76_ == 0 then
		return self:getIsOwnedByFarmAtWorldPosition(farmId, worldPosX1, worldPosZ1)
	end
	for v77_ = 0, 1, g_currentMission.terrainSize / self.localMapWidth / v76_ * 2 do
		local v78_, v79_ = MathUtil.vector2Lerp(worldPosX1, worldPosZ1, worldPosX2, worldPosZ2, v77_)
		local v80_, v81_ = self:convertWorldToLocalPosition(v78_, v79_)
		local v82_ = getBitVectorMapPoint(self.localMap, v80_, v81_, 0, self.numberOfBits)
		if self.farmlandMapping[v82_] ~= farmId then
			return false
		end
	end
	return true
end

-- Local values: farmlandId, ownerFarmId
function FarmlandManager:getCanAccessLandAtWorldPosition(farmId, worldPosX, worldPosZ)
	if farmId == FarmlandManager.NO_OWNER_FARM_ID or farmId == nil then
		return false
	end
	local v87_ = self:getFarmlandIdAtWorldPosition(worldPosX, worldPosZ)
	local v88_ = self.farmlandMapping[v87_]
	return v88_ == farmId and true or g_currentMission.accessHandler:canFarmAccessOtherId(farmId, v88_)
end

function FarmlandManager:getFarmlandOwner(farmlandId)
	if farmlandId == nil or self.farmlandMapping[farmlandId] == nil then
		return FarmlandManager.NO_OWNER_FARM_ID
	else
		return self.farmlandMapping[farmlandId]
	end
end

-- Local values: localPosX, localPosZ
function FarmlandManager:getFarmlandIdAtWorldPosition(worldPosX, worldPosZ)
	if self.localMap == nil then
		return FarmlandManager.NO_OWNER_FARM_ID
	end
	local v94_, v95_ = self:convertWorldToLocalPosition(worldPosX, worldPosZ)
	return getBitVectorMapPoint(self.localMap, v94_, v95_, 0, self.numberOfBits)
end

-- Local values: farmlandId
function FarmlandManager:getFarmlandAtWorldPosition(worldPosX, worldPosZ)
	local v99_ = self:getFarmlandIdAtWorldPosition(worldPosX, worldPosZ)
	return self.farmlands[v99_]
end

-- Local values: farmlandId
function FarmlandManager:getOwnerIdAtWorldPosition(worldPosX, worldPosZ)
	return self:getFarmlandOwner((self:getFarmlandIdAtWorldPosition(worldPosX, worldPosZ)))
end

function FarmlandManager:getIsValidFarmlandId(farmlandId)
	if farmlandId == nil or (farmlandId == 0 or farmlandId < 0) then
		return false
	else
		return self:getFarmlandById(farmlandId) ~= nil
	end
end

-- Local values: farmland
function FarmlandManager:setLandOwnership(farmlandId, farmId, loadFromSavegame)
	if not self:getIsValidFarmlandId(farmlandId) then
		return false
	end
	if farmId == nil or (farmId < FarmlandManager.NO_OWNER_FARM_ID or farmId == FarmlandManager.NOT_BUYABLE_FARM_ID) then
		return false
	end
	local v109_ = self:getFarmlandById(farmlandId)
	if v109_ == nil then
		Logging.warning("Farmland id %d not defined in map!", farmlandId)
		return false
	end
	if loadFromSavegame == nil then
		loadFromSavegame = false
	end
	self.farmlandMapping[farmlandId] = farmId
	v109_:setOwnerFarmId(farmId)
	g_messageCenter:publish(MessageType.FARMLAND_OWNER_CHANGED, farmlandId, farmId, loadFromSavegame)
	return true
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

-- Local values: farmlandIds, farmlandId, farmId
function FarmlandManager:getOwnedFarmlandIdsByFarmId(id)
	local v116_ = {}
	for v117_, v118_ in pairs(self.farmlandMapping) do
		if v118_ == id then
			table.insert(v116_, v117_)
		end
	end
	return v116_
end

-- Local values: num, farmlandId, farmId
function FarmlandManager:getNumOwnedFarmlandIdsByFarmId(id)
	local v121_ = 0
	for _, v122_ in pairs(self.farmlandMapping) do
		if v122_ == id then
			v121_ = v121_ + 1
		end
	end
	return v121_
end

-- Local values: terrainSize
function FarmlandManager:convertWorldToLocalPosition(worldPosX, worldPosZ)
	local v126_ = g_currentMission.terrainSize
	local v127_ = self.localMapWidth * (worldPosX + v126_ * 0.5) / v126_
	local v128_ = math.floor(v127_)
	local v129_ = self.localMapHeight * (worldPosZ + v126_ * 0.5) / v126_
	return v128_, math.floor(v129_)
end

-- Local values: _, farmland
function FarmlandManager:farmDestroyed(farmId)
	for _, v132_ in pairs(self:getFarmlands()) do
		if self:getFarmlandOwner(v132_.id) == farmId then
			self:setLandOwnership(v132_.id, FarmlandManager.NO_OWNER_FARM_ID)
		end
	end
end

-- Local values: index, farmlandId, farmland, hotspot
function FarmlandManager:onFarmSettingsChanged(farmId)
	for _, v135_ in pairs(self:getOwnedFarmlandIdsByFarmId(farmId)) do
		local v136_ = self:getFarmlandById(v135_)
		local v137_
		if v136_ == nil then
			v137_ = nil
		else
			v137_ = v136_:getMapHotspot() or nil
		end
		if v137_ ~= nil then
			v137_:updateColors()
		end
	end
end

-- Local values: farmlandId, x, _, z, farmId
function FarmlandManager:consoleCommandBuyFarmland(farmlandIdStr)
	if not ((g_currentMission:getIsServer() or g_currentMission.isMasterUser) and g_currentMission:getIsClient()) then
		return "Command not allowed"
	end
	local v140_
	if farmlandIdStr == nil then
		local v141_, _, v142_ = g_localPlayer:getPosition()
		v140_ = self:getFarmlandIdAtWorldPosition(v141_, v142_)
		if v140_ == nil then
			printError("Error: Unable to retrieve farmland id at player position, provide farmland as argument instead")
			return
		end
	else
		v140_ = tonumber(farmlandIdStr)
		if v140_ == nil or self:getFarmlandById(v140_) == nil then
			printError(string.format("Error: Invalid farmland id %q.", farmlandIdStr))
			return "Use gsFarmlandBuy <farmlandId>"
		end
	end
	local v143_ = g_localPlayer.farmId
	if self:getFarmlandOwner(v140_) ~= v143_ then
		g_client:getServerConnection():sendEvent(FarmlandStateEvent.new(v140_, v143_, 0))
		return "Bought farmland " .. v140_
	end
	printError(string.format("Error: Farmland %d already owned by farm %d", v140_, v143_))
end

-- Local values: farmId, k, _
function FarmlandManager:consoleCommandBuyAllFarmlands()
	if not ((g_currentMission:getIsServer() or g_currentMission.isMasterUser) and g_currentMission:getIsClient()) then
		return "Command not allowed"
	end
	local v144_ = g_localPlayer.farmId
	for v145_, _ in pairs(g_farmlandManager:getFarmlands()) do
		g_client:getServerConnection():sendEvent(FarmlandStateEvent.new(v145_, v144_, 0))
	end
	return "Bought all farmlands"
end

-- Local values: farmlandId, x, _, z
function FarmlandManager:consoleCommandSellFarmland(farmlandIdStr)
	if not ((g_currentMission:getIsServer() or g_currentMission.isMasterUser) and g_currentMission:getIsClient()) then
		return "Command not allowed"
	end
	local v148_
	if farmlandIdStr == nil then
		local v149_, _, v150_ = g_localPlayer:getPosition()
		v148_ = self:getFarmlandIdAtWorldPosition(v149_, v150_)
		if v148_ == nil then
			printError("Error: Unable to retrieve farmland id at player position, provide farmland as argument instead")
			return
		end
	else
		v148_ = tonumber(farmlandIdStr)
		if v148_ == nil or self:getFarmlandById(v148_) == nil then
			printError(string.format("Error: Invalid farmland id %q", farmlandIdStr))
			return "Use gsFarmlandSell <farmlandId>"
		end
	end
	if self:getFarmlandOwner(v148_) ~= FarmlandManager.NO_OWNER_FARM_ID then
		g_client:getServerConnection():sendEvent(FarmlandStateEvent.new(v148_, FarmlandManager.NO_OWNER_FARM_ID, 0))
		return "Sold farmland " .. v148_
	end
	printError(string.format("Error: Farmland %d not owned by anyone", v148_))
end

-- Local values: k, _
function FarmlandManager:consoleCommandSellAllFarmlands()
	if not ((g_currentMission:getIsServer() or g_currentMission.isMasterUser) and g_currentMission:getIsClient()) then
		return "Command not allowed"
	end
	for v151_, _ in pairs(g_farmlandManager:getFarmlands()) do
		g_client:getServerConnection():sendEvent(FarmlandStateEvent.new(v151_, FarmlandManager.NO_OWNER_FARM_ID, 0))
	end
	return "Sold all farmlands"
end

function FarmlandManager:consoleCommandShowFarmlands()
	if not g_debugManager:hasDrawable(self) then
		g_debugManager:addDrawable(self)
		return "showFarmlands = true\nUse F5 to enter debug mode for enabling overlay"
	end
	g_debugManager:removeDrawable(self)
	self.debugFarmlandColors = nil
	return "showFarmlands = false"
end

-- Local values: x, _, z, farmlandId, _, color, object, terrainSizeHalf, bitmapToWorld, worldToBitmap, bitmapX, bitmapZ, range, bitmapMinX, bitmapMinZ, bitmapMaxX, bitmapMaxZ, farmlandsLegend, bitmapStepZ, bitmapStepX, farmland, color, worldX, worldZ, fontSize, i, farmland, color, defaultPropertyStr, text
function FarmlandManager:drawDebug()
	local v154_, _, v155_ = getWorldTranslation(g_cameraManager:getActiveCamera())
	if self.debugFarmlandColors == nil then
		self.debugFarmlandColors = {}
		for v156_, _ in pairs(self.farmlands) do
			local v157_ = DebugUtil.getDebugColor(v156_)
			v157_.a = 0.15
			self.debugFarmlandColors[v156_] = v157_
		end
	end
	if g_localPlayer:getCurrentVehicle() ~= nil then
		local v158_ = g_localPlayer:getCurrentVehicle()
		if g_localPlayer:getCurrentVehicle().selectedImplement ~= nil then
			v158_ = g_localPlayer:getCurrentVehicle().selectedImplement.object
		end
		local v159_
		v154_, v159_, v155_ = getWorldTranslation(v158_.components[1].node)
	end
	local v160_ = g_currentMission.terrainSize / 2
	local v161_ = g_currentMission.terrainSize / self.localMapWidth
	local v162_ = self.localMapWidth / g_currentMission.terrainSize
	local v163_ = (v154_ + v160_) * v162_
	local v164_ = math.floor(v163_)
	local v165_ = (v155_ + v160_) * v162_
	local v166_ = math.floor(v165_)
	local v167_ = v164_ - 25
	local v168_ = math.max(v167_, 0)
	local v169_ = v166_ - 25
	local v170_ = math.max(v169_, 0)
	local v171_ = v164_ + 25
	local v172_ = self.localMapWidth - 1
	local v173_ = math.min(v171_, v172_)
	local v174_ = v166_ + 25
	local v175_ = self.localMapWidth - 1
	local v176_ = {}
	for v177_ = v170_, math.min(v174_, v175_) do
		for v178_ = v168_, v173_ do
			local v179_ = self.farmlands[getBitVectorMapPoint(self.localMap, v178_, v177_, 0, self.numberOfBits)]
			if v179_ then
				local v180_ = self.debugFarmlandColors[v179_.id]
				v176_[v179_] = v180_
				local v181_ = v178_ * v161_ - v160_
				local v182_ = v177_ * v161_ - v160_
				DebugPlane.renderWithPositions(v181_, 0, v182_, v181_, 0, v182_ + v161_, v181_ + v161_, 0, v182_, v180_, true, true)
			end
		end
	end
	local v183_ = 0
	if next(v176_) == nil then
		renderText(0.3, 0.97 - v183_ * 0.015, 0.015, "No farmlands defined in vicinity")
	else
		for v184_, v185_ in pairs(v176_) do
			local v186_ = v184_.defaultFarmProperty and " | defaultFarmProperty" or ""
			local v187_ = string.format("Farmland %d | Owner: %s | Area: %.3fha | Price: %d%s", v184_.id, self:getFarmlandOwner(v184_.id), v184_.areaInHa, v184_.price, v186_)
			setTextColor(v185_[1], v185_[2], v185_[3], 1)
			renderText(0.3, 0.97 - v183_ * 0.015, 0.015, v187_)
			setTextColor(1, 1, 1, 1)
			v183_ = v183_ + 1
		end
	end
end
g_farmlandManager = FarmlandManager.new()
