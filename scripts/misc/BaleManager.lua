BaleManager = {}
BaleManager.baleXMLSchema = nil
BaleManager.mapBalesXMLSchema = nil
local BaleManager_mt = Class(BaleManager, AbstractManager)
function BaleManager.new(customMt)
	local self = AbstractManager.new(customMt or BaleManager_mt)
	BaleManager.baleXMLSchema = XMLSchema.new("bale")
	BaleManager.registerBaleXMLPaths(BaleManager.baleXMLSchema)
	BaleManager.mapBalesXMLSchema = XMLSchema.new("mapBales")
	BaleManager.registerMapBalesXMLPaths(BaleManager.mapBalesXMLSchema)
	return self
end
function BaleManager:initDataStructures()
	self.bales = {}
	self.modBalesToLoad = {}
	self.fermentations = {}
end
function BaleManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	BaleManager:superClass().loadMapData(self)
	local filename = getXMLString(xmlFile, "map.bales#filename")
	if filename == nil then
		Logging.xmlInfo(xmlFile, "No bales xml defined in map")
		return false
	else
		local xmlFilename = Utils.getFilename(filename, baseDirectory)
		local balesXMLFile = XMLFile.load("TempBales", xmlFilename, BaleManager.mapBalesXMLSchema)
		if balesXMLFile ~= nil then
			self:loadBales(balesXMLFile, baseDirectory)
			balesXMLFile:delete()
		end
		for i = #self.modBalesToLoad, 1, -1 do
			local bale = self.modBalesToLoad[i]
			local baleXmlFile = XMLFile.load("TempBale", bale.xmlFilename, BaleManager.baleXMLSchema)
			if baleXmlFile ~= nil then
				if self:loadBaleDataFromXML(bale, baleXmlFile, bale.baseDirectory) then
					table.insert(self.bales, bale)
				end
				baleXmlFile:delete()
			end
			table.remove(self.modBalesToLoad, i)
		end
		BaleManager.SEND_NUM_BITS = MathUtil.getNumRequiredBits(#self.bales)
		for _, bale in ipairs(self.bales) do
			bale.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(bale.i3dFilename, false, true, self.baleLoaded, self, bale)
		end
		if g_addCheatCommands then
			addConsoleCommand("gsBaleAdd", "Adds a bale", "consoleCommandAddBale", self, "[fillTypeName]; [isRoundbale]; [width]; [height]; [length]; [wrapState]; [modName]")
			addConsoleCommand("gsBaleAddAll", "Adds a bale", "consoleCommandAddBaleAll", self, "[drawSizeBox]")
			addConsoleCommand("gsBaleList", "List available bale types", "consoleCommandListBales", self)
		end
		return true
	end
end
function BaleManager:baleLoaded(i3dNode, failedReason, bale)
	if i3dNode ~= 0 then
		bale.sharedRoot = i3dNode
		local collisionPreset = CollisionPreset.BALE
		local baleId = getChildAt(i3dNode, 0)
		if getCollisionFilterGroup(baleId) ~= collisionPreset.group then
			Logging.error("Bale '%s' has wrong collision group mask. Expected: %d, got: %d", bale.xmlFilename, collisionPreset.group, getCollisionFilterGroup(baleId))
		end
		if getCollisionFilterMask(baleId) ~= collisionPreset.mask then
			Logging.error("Bale '%s' has wrong collision mask. Expected: %d, got: %d", bale.xmlFilename, collisionPreset.mask, getCollisionFilterMask(baleId))
		end
		removeFromPhysics(i3dNode)
	end
end
function BaleManager:unloadMapData()
	self:unloadBaleData()
	if g_addCheatCommands then
		removeConsoleCommand("gsBaleAdd")
		removeConsoleCommand("gsBaleList")
	end
	BaleManager:superClass().unloadMapData(self)
end
function BaleManager:unloadBaleData()
	for _, bale in ipairs(self.bales) do
		if bale.sharedLoadRequestId ~= nil then
			g_i3DManager:releaseSharedI3DFile(bale.sharedLoadRequestId)
			bale.sharedLoadRequestId = nil
		end
		if bale.sharedRoot == nil then
			continue
		end
		delete(bale.sharedRoot)
		bale.sharedRoot = nil
	end
end
function BaleManager:loadBales(xmlFile, baseDirectory)
	xmlFile:iterate("map.bales.bale", function(index, key)
		self:loadBaleFromXML(xmlFile, key, baseDirectory)
	end)
	return true
end
function BaleManager:loadBaleFromXML(xmlFile, key, baseDirectory)
	if type(xmlFile) ~= "table" then
		xmlFile = XMLFile.wrap(xmlFile)
	end
	local xmlFilename = xmlFile:getString(key .. "#filename")
	if xmlFilename ~= nil then
		local bale = {}
		bale.xmlFilename = Utils.getFilename(xmlFilename, baseDirectory)
		bale.isAvailable = xmlFile:getBool(key .. "#isAvailable", true)
		local baleXmlFile = XMLFile.load("TempBale", bale.xmlFilename, BaleManager.baleXMLSchema)
		if baleXmlFile ~= nil then
			local success = self:loadBaleDataFromXML(bale, baleXmlFile, baseDirectory)
			baleXmlFile:delete()
			if success then
				table.insert(self.bales, bale)
				return true
			end
		end
	end
	Logging.xmlError(xmlFile, "Failed to load bale from xml '%s'", key)
	return false
end
function BaleManager:loadModBaleFromXML(xmlFile, key, baseDirectory, customEnvironment)
	if type(xmlFile) ~= "table" then
		xmlFile = XMLFile.wrap(xmlFile)
	end
	local xmlFilename = xmlFile:getString(key .. "#filename")
	if xmlFilename ~= nil then
		xmlFilename = Utils.getFilename(xmlFilename, baseDirectory)
		local bale = {}
		bale.xmlFilename = xmlFilename
		bale.baseDirectory = baseDirectory
		bale.customEnvironment = customEnvironment
		bale.isAvailable = xmlFile:getBool(key .. "#isAvailable", true)
		table.insert(self.modBalesToLoad, bale)
		return true
	else
		Logging.xmlError(xmlFile, "Failed to load bale from xml '%s'", key)
		return false
	end
end
function BaleManager:loadBaleDataFromXML(bale, xmlFile, baseDirectory)
	local i3dFilename = xmlFile:getValue("bale.filename")
	if i3dFilename ~= nil then
		bale.i3dFilename = Utils.getFilename(i3dFilename, baseDirectory)
		if not fileExists(bale.i3dFilename) then
			Logging.xmlError(xmlFile, "Bale i3d file could not be found '%s'", bale.i3dFilename)
			return false
		else
			bale.isRoundbale = xmlFile:getValue("bale.size#isRoundbale", true)
			bale.width = MathUtil.round(xmlFile:getValue("bale.size#width", 0), 2)
			bale.height = MathUtil.round(xmlFile:getValue("bale.size#height", 0), 2)
			bale.length = MathUtil.round(xmlFile:getValue("bale.size#length", 0), 2)
			bale.diameter = MathUtil.round(xmlFile:getValue("bale.size#diameter", 0), 2)
			bale.maxStackHeight = xmlFile:getValue("bale.size#maxStackHeight", bale.isRoundbale and 2 or 3)
			bale.visualWidth = xmlFile:getValue("bale.size#visualWidth", bale.width)
			bale.visualHeight = xmlFile:getValue("bale.size#visualHeight", bale.height)
			bale.visualLength = xmlFile:getValue("bale.size#visualLength", bale.length)
			bale.visualDiameter = xmlFile:getValue("bale.size#visualDiameter", bale.diameter)
			if bale.isRoundbale and (bale.diameter == 0 or bale.width == 0) then
				Logging.xmlError(xmlFile, "Missing size attributes for round bale. Requires width and diameter.")
				return false
			end
			if not bale.isRoundbale and (bale.width == 0 or bale.height == 0 or bale.length == 0) then
				Logging.xmlError(xmlFile, "Missing size attributes for square bale. Requires width, height and length.")
				return false
			end
			bale.fillTypes = {}
			xmlFile:iterate("bale.fillTypes.fillType", function(index, key)
				local fillTypeName = xmlFile:getValue(key .. "#name")
				local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
				if fillTypeIndex ~= nil then
					local fillTypeData = {}
					fillTypeData.fillTypeIndex = fillTypeIndex
					fillTypeData.capacity = xmlFile:getValue(key .. "#capacity", 0)
					table.insert(bale.fillTypes, fillTypeData)
				else
					Logging.xmlWarning(xmlFile, "Unknown fill type '%s' for bale in '%s'", fillTypeName, key)
				end
			end)
			bale.variations = {}
			xmlFile:iterate("bale.variations.variation", function(index, key)
				local id = xmlFile:getValue(key .. "#id")
				if id ~= nil then
					local variationData = {}
					variationData.id = id
					table.insert(bale.variations, variationData)
				end
			end)
			if #bale.variations == 0 then
				table.insert(bale.variations, { id = "DEFAULT" })
			end
			return true
		end
	end
	Logging.xmlError(xmlFile, "No i3D file defined in bale xml.")
	return false
end
function BaleManager:update(dt)
	if g_server ~= nil then
		local numFermentations = #self.fermentations
		if 0 < numFermentations then
			local timeScale = g_currentMission:getEffectiveTimeScale()
			for i = numFermentations, 1, -1 do
				local fermentation = self.fermentations[i]
				fermentation.time = fermentation.time + dt * timeScale
				if fermentation.maxTime <= fermentation.time then
					fermentation.bale:onFermentationUpdate(1)
					fermentation.bale:onFermentationEnd()
					table.remove(self.fermentations, i)
				else
					local percentage = fermentation.time / fermentation.maxTime
					if math.floor(percentage * 100) == math.floor(fermentation.percentageSend * 100) then
						continue
					end
					fermentation.bale:onFermentationUpdate(percentage)
					fermentation.percentageSend = percentage
				end
			end
		end
	end
end
function BaleManager:registerFermentation(bale, currentTime, maxTime)
	if not Platform.gameplay.hasBaleFermentation then
		maxTime = 0
	end
	maxTime = maxTime * g_currentMission.missionInfo.economicDifficulty
	local fermentation = {}
	fermentation.bale = bale
	fermentation.time = currentTime
	fermentation.percentageSend = 0
	fermentation.maxTime = maxTime
	table.insert(self.fermentations, fermentation)
end
function BaleManager:getFermentationTime(bale)
	for i = 1, #self.fermentations do
		if self.fermentations[i].bale == bale then
			return self.fermentations[i].time
		end
	end
	return 0
end
function BaleManager:removeFermentation(bale)
	for i = #self.fermentations, 1, -1 do
		if self.fermentations[i].bale == bale then
			table.remove(self.fermentations, i)
		end
	end
end
function BaleManager:getBaleDescByIndex(baleIndex)
	return self.bales[baleIndex]
end
function BaleManager:getBaleIndex(fillTypeIndex, isRoundbale, width, height, length, diameter, customEnvironment)
	if customEnvironment ~= nil then
		for baleIndex = 1, #self.bales do
			local bale = self.bales[baleIndex]
			if bale.isAvailable and (customEnvironment == bale.customEnvironment and self:getIsBaleMatching(bale, fillTypeIndex, isRoundbale, width, height, length, diameter)) then
				return baleIndex
			end
		end
	end
	for baleIndex = 1, #self.bales do
		local bale = self.bales[baleIndex]
		if bale.isAvailable and (bale.customEnvironment == nil and self:getIsBaleMatching(bale, fillTypeIndex, isRoundbale, width, height, length, diameter)) then
			return baleIndex
		end
	end
	return nil
end
function BaleManager:getBaleInfoByXMLFilename(xmlFilename, useVisualInfomation)
	for i = 1, #self.bales do
		local bale = self.bales[i]
		if bale.xmlFilename == xmlFilename then
			if useVisualInfomation == true then
				return bale.isRoundbale, bale.visualWidth, bale.visualHeight, bale.visualLength, bale.visualDiameter, bale.maxStackHeight
			else
				return bale.isRoundbale, bale.width, bale.height, bale.length, bale.diameter, bale.maxStackHeight
			end
		end
	end
	return false, 0, 0, 0, 0, 1
end
function BaleManager:getIsBaleMatching(bale, fillTypeIndex, isRoundbale, width, height, length, diameter)
	if bale.isRoundbale == isRoundbale then
		local fillTypeMatch = false
		local _v21 = 1
		for j = 1, #bale.fillTypes, _v21 do
			if bale.fillTypes[j].fillTypeIndex == fillTypeIndex then
				fillTypeMatch = true
				break
			end
		end
		if fillTypeMatch then
			local sizeMatch = nil
			if isRoundbale then
				sizeMatch = _v21
			else
				sizeMatch = _v21
			end
			if sizeMatch then
				return true
			end
		end
	end
	return false
end
function BaleManager:getBaleXMLFilename(fillTypeIndex, isRoundbale, width, height, length, diameter, customEnvironment)
	local baleIndex = self:getBaleIndex(fillTypeIndex, isRoundbale, width, height, length, diameter, customEnvironment)
	if baleIndex ~= nil then
		return self.bales[baleIndex].xmlFilename, baleIndex
	else
		return nil
	end
end
function BaleManager:getBaleTypeIndexByXMLFilename(xmlFilename)
	for i = 1, #self.bales do
		if self.bales[i].xmlFilename == xmlFilename then
			return i
		end
	end
	return nil
end
function BaleManager:getBaleXMLFilenameByIndex(baleIndex)
	if baleIndex ~= nil and self.bales[baleIndex] ~= nil then
		return self.bales[baleIndex].xmlFilename
	end
	return nil
end
function BaleManager:getIsRoundBale(baleIndex)
	if baleIndex ~= nil and self.bales[baleIndex] ~= nil then
		return self.bales[baleIndex].isRoundbale
	end
	return nil
end
function BaleManager:getBaleCapacityByBaleIndex(baleIndex, fillTypeIndex)
	if baleIndex ~= nil then
		local bale = self.bales[baleIndex]
		if bale ~= nil then
			for j = 1, #bale.fillTypes do
				if bale.fillTypes[j].fillTypeIndex == fillTypeIndex then
					return bale.fillTypes[j].capacity
				end
			end
		end
	end
	return 0
end
function BaleManager:getPossibleCapacitiesForFillType(fillTypeIndex)
	local capacities = {}
	for _, bale in ipairs(self.bales) do
		for _, fillTypeData in ipairs(bale.fillTypes) do
			if fillTypeData.fillTypeIndex == fillTypeIndex then
				table.insert(capacities, fillTypeData.capacity)
			end
		end
	end
	return capacities
end
function BaleManager:consoleCommandAddBale(fillTypeName, isRoundbale, width, height, length, wrapState, modName)
	local usage = "gsBaleAdd fillTypeName isRoundBale [width] [height/diameter] [length] [wrapState] [modName]"
	if not g_currentMission:getIsServer() then
		Logging.error("Command only allowed on server!")
		return
	end
	fillTypeName = Utils.getNoNil(fillTypeName, "STRAW")
	isRoundbale = Utils.stringToBoolean(isRoundbale)
	width = width ~= nil and tonumber(width) or nil
	height = height ~= nil and tonumber(height) or nil
	length = length ~= nil and tonumber(length) or nil
	if wrapState ~= nil and tonumber(wrapState) == nil then
		Logging.error("Invalid wrapState '%s', number expected.\nUsage: %s", wrapState, "gsBaleAdd fillTypeName isRoundBale [width] [height/diameter] [length] [wrapState] [modName]")
		return
	end
	wrapState = tonumber(wrapState or 0)
	local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
	if fillTypeIndex == nil then
		Logging.error("Invalid fillTypeName '%s' (e.g. STRAW).\nUsage: %s", fillTypeName, "gsBaleAdd fillTypeName isRoundBale [width] [height/diameter] [length] [wrapState] [modName]")
		return
	end
	local baleXMLFilename, _ = self:getBaleXMLFilename(fillTypeIndex, isRoundbale, width, height, length, height, modName)
	if baleXMLFilename == nil then
		Logging.error("Could not find bale for given size attributes!\nUsage: %s", "gsBaleAdd fillTypeName isRoundBale [width] [height/diameter] [length] [wrapState] [modName]")
		self:consoleCommandListBales()
		return
	else
		local x, y, z = g_localPlayer:getPosition()
		local dirX, dirZ = g_localPlayer:getCurrentFacingDirection()
		x = x + dirX * 4
		z = z + dirZ * 4
		y = y + 5
		local ry = MathUtil.getYRotationFromDirection(dirX, dirZ)
		local farmId = g_currentMission:getFarmId()
		farmId = farmId ~= FarmManager.SPECTATOR_FARM_ID and farmId or 1
		local baleObject = Bale.new(g_currentMission:getIsServer(), g_currentMission:getIsClient())
		if baleObject:loadFromConfigXML(baleXMLFilename, x, y, z, 0, ry, 0) then
			baleObject:setFillType(fillTypeIndex, true)
			baleObject:setWrappingState(wrapState)
			baleObject:setOwnerFarmId(farmId, true)
			baleObject:register()
		end
		return string.format("Created bale at (%.2f, %.2f, %.2f). For specific bales use: %s", x, y, z, "gsBaleAdd fillTypeName isRoundBale [width] [height/diameter] [length] [wrapState] [modName]")
	end
end
function BaleManager:consoleCommandAddBaleAll(drawSizeBox)
	if g_server == nil then
		Logging.error("Command only allowed on server!")
	else
		drawSizeBox = string.lower(drawSizeBox or "") == "true"
		local wx = nil
		local wy = nil
		local wz = nil
		local dirX = nil
		local dirZ = nil
		if self.debugLoadPosition == nil then
			wx, wy, wz = g_localPlayer:getPosition()
			dirX, dirZ = g_localPlayer:getCurrentFacingDirection()
			self.debugLoadPosition = { wx, wy, wz, dirX, dirZ }
		else
			wx = self.debugLoadPosition[1]
			wy = self.debugLoadPosition[2]
			wz = self.debugLoadPosition[3]
			dirX = self.debugLoadPosition[4]
			dirZ = self.debugLoadPosition[5]
		end
		if self.debugBales ~= nil then
			for _, bale in ipairs(self.debugBales) do
				bale:delete()
			end
		end
		g_debugManager:removeGroup("baleManager")
		self.debugBales = {}
		self:unloadBaleData()
		g_i3DManager:clearEntireSharedI3DFileCache()
		self.bales = {}
		local xmlFilename = Utils.getFilename("data/maps/maps_bales.xml")
		local balesXMLFile = XMLFile.load("TempBales", xmlFilename, BaleManager.mapBalesXMLSchema)
		if balesXMLFile ~= nil then
			self:loadBales(balesXMLFile)
			balesXMLFile:delete()
		end
		local spawnBales = function()
			local boxColor = Color.new(0.2, 0.2, 0.2, 1)
			wx = wx + dirX * 4
			wz = wz + dirZ * 4
			local yRot = MathUtil.getYRotationFromDirection(dirX, dirZ)
			local xOffset = 0
			local zOffset = 0
			for baleIndex, bale in ipairs(self.bales) do
				for _, fillTypeData in ipairs(bale.fillTypes) do
					zOffset = (bale.isRoundbale and bale.width or bale.length) * 0.5
					for variationIndex, variationData in ipairs(bale.variations) do
						local x = wx + dirX * zOffset - dirZ * xOffset
						local z = wz + dirZ * zOffset + dirX * xOffset
						local baleHeight = bale.isRoundbale and bale.diameter or bale.height
						local y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + baleHeight * 0.5
						local baleObject = Bale.new(g_currentMission:getIsServer(), g_currentMission:getIsClient())
						if baleObject:loadFromConfigXML(bale.xmlFilename, x, y, z, 0, yRot, 0) then
							baleObject:setFillType(fillTypeData.fillTypeIndex, true)
							baleObject:setVariationIndex(variationIndex)
							baleObject:setOwnerFarmId(g_currentMission:getFarmId(), true)
							baleObject:register()
							baleObject:removeFromPhysics()
							local debugString = string.format("%s (%s - %s)", Utils.getFilenameFromPath(bale.xmlFilename), g_fillTypeManager:getFillTypeNameByIndex(fillTypeData.fillTypeIndex), variationData.id)
							local rx, ry, rz = localRotationToWorld(baleObject.nodeId, 0, 3.141592653589793, 0)
							DebugText3D.new():createWithWorldPos(x, y + baleHeight * 0.5 + 0.25, z, rx, ry, rz, debugString, 0.07):addToManager("baleManager", nil, math.huge)
							if drawSizeBox then
								local sizeX = nil
								local sizeY = nil
								local sizeZ = nil
								if bale.isRoundbale then
									sizeX = bale.diameter
									sizeY = bale.diameter
									sizeZ = bale.width
								else
									sizeX = bale.width
									sizeY = bale.height
									sizeZ = bale.length
								end
								DebugBox.new():createWithWorldPosAndRot(x, y, z, rx, ry, rz, sizeX, sizeY, sizeZ):setColor(boxColor):addToManager("baleManager", nil, math.huge)
							end
							table.insert(self.debugBales, baleObject)
						end
						zOffset = zOffset + (bale.isRoundbale and bale.width or bale.length) + 1
					end
					xOffset = xOffset + 2.5
				end
				xOffset = xOffset + 5
			end
		end
		local numBalesToLoad = #self.bales
		local baleLoaded = function(_, i3dNode, failedReason, bale)
			self:baleLoaded(i3dNode, failedReason, bale)
			numBalesToLoad = numBalesToLoad - 1
			if numBalesToLoad == 0 then
				spawnBales()
			end
		end
		for _, bale in ipairs(self.bales) do
			bale.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(bale.i3dFilename, false, true, baleLoaded, self, bale)
		end
	end
end
function BaleManager:consoleCommandListBales()
	print("Available bale types:")
	for _, bale in ipairs(self.bales) do
		local attributes = { bale.xmlFilename }
		table.insert(attributes, string.format("isRoundbale=%s", bale.isRoundbale))
		for _, sizeProperty in ipairs({ "width", "height", "length", "diameter" }) do
			if bale[sizeProperty] == nil or bale[sizeProperty] == 0 then
				continue
			end
			table.insert(attributes, string.format("%s=%s", sizeProperty, bale[sizeProperty]))
		end
		log(table.concat(attributes, "  "))
		local fillTypeNames = {}
		for _, fillTypeData in ipairs(bale.fillTypes) do
			table.insert(fillTypeNames, g_fillTypeManager:getFillTypeNameByIndex(fillTypeData.fillTypeIndex))
		end
		log("    fillTypes: ", table.concat(fillTypeNames, "  "))
	end
end
function BaleManager.registerBaleXMLPaths(schema)
	schema:register(XMLValueType.STRING, "bale.filename", "Path to i3d file")
	schema:register(XMLValueType.BOOL, "bale.size#isRoundbale", "Bale is a roundbale", true)
	schema:register(XMLValueType.FLOAT, "bale.size#width", "Bale Width", 0)
	schema:register(XMLValueType.FLOAT, "bale.size#height", "Bale Height", 0)
	schema:register(XMLValueType.FLOAT, "bale.size#length", "Bale Length", 0)
	schema:register(XMLValueType.FLOAT, "bale.size#diameter", "Bale Diameter", 0)
	schema:register(XMLValueType.INT, "bale.size#maxStackHeight", "Max. stack height for automatic spawning of bales", "2 or round bales and 3 for square bales")
	schema:register(XMLValueType.FLOAT, "bale.size#visualWidth", "Bale Width (Real size of the visuals if different)", "Same as #width")
	schema:register(XMLValueType.FLOAT, "bale.size#visualHeight", "Bale Height (Real size of the visuals if different)", "Same as #height")
	schema:register(XMLValueType.FLOAT, "bale.size#visualLength", "Bale Length (Real size of the visuals if different)", "Same as #length")
	schema:register(XMLValueType.FLOAT, "bale.size#visualDiameter", "Bale Diameter (Real size of the visuals if different)", "Same as #diameter")
	schema:register(XMLValueType.NODE_INDEX, "bale.mountableObject#triggerNode", "Trigger node")
	schema:register(XMLValueType.FLOAT, "bale.mountableObject#forceAcceleration", "Acceleration force", 4)
	schema:register(XMLValueType.FLOAT, "bale.mountableObject#forceLimitScale", "Force limit scale", 1)
	schema:register(XMLValueType.BOOL, "bale.mountableObject#axisFreeY", "Joint is free in Y direction", false)
	schema:register(XMLValueType.BOOL, "bale.mountableObject#axisFreeX", "Joint is free in X direction", false)
	schema:register(XMLValueType.STRING, "bale.uvId", "Specify that this bale model has a custom UV. This will result in baleWrapper to replace the bale if the UV is different to the defined one in the baleWrapper. So the baleWrapper will always use a bale with a UV that matches the wrapping texture.", "DEFAULT")
	schema:register(XMLValueType.NODE_INDEX, "bale.baleMeshes.baleMesh(?)#node", "Path to mesh node")
	schema:register(XMLValueType.BOOL, "bale.baleMeshes.baleMesh(?)#supportsWrapping", "Defines if the mesh is hidden while wrapping or not")
	schema:register(XMLValueType.STRING, "bale.baleMeshes.baleMesh(?)#fillTypes", "If defined this mesh is only visible if any of this fillTypes is set")
	schema:register(XMLValueType.BOOL, "bale.baleMeshes.baleMesh(?)#isTensionBeltMesh", "Defines if this mesh is detected for tension belt calculation", false)
	schema:register(XMLValueType.BOOL, "bale.baleMeshes.baleMesh(?)#isAlphaMesh", "Defines if the mesh is a alpha mesh (different material will be applied)", false)
	schema:register(XMLValueType.STRING, "bale.fillTypes.fillType(?)#name", "Name of fill type")
	schema:register(XMLValueType.FLOAT, "bale.fillTypes.fillType(?)#capacity", "Fill level of bale with this fill type")
	schema:register(XMLValueType.FLOAT, "bale.fillTypes.fillType(?)#mass", "Mass of bale with this fill type", 500)
	schema:register(XMLValueType.FLOAT, "bale.fillTypes.fillType(?)#forceAcceleration", "Force acceleration value of bale with this fill type", "bale.mountableObject#forceAcceleration")
	schema:register(XMLValueType.BOOL, "bale.fillTypes.fillType(?)#supportsWrapping", "Wrapping is allowed while this type is used")
	schema:register(XMLValueType.STRING, "bale.fillTypes.fillType(?)#materialName", "Bale material to use")
	schema:register(XMLValueType.STRING, "bale.fillTypes.fillType(?)#alphaMaterialName", "Bale material to use on alpha mesh parts")
	BaleManager.registerBaleTextureXMLPaths(schema, "bale.fillTypes.fillType(?)")
	schema:register(XMLValueType.STRING, "bale.variations.variation(?)#id", "Variation identifier")
	BaleManager.registerBaleTextureXMLPaths(schema, "bale.variations.variation(?)")
	schema:register(XMLValueType.STRING, "bale.fillTypes.fillType(?).fermenting#outputFillType", "Output fill type after fermenting")
	schema:register(XMLValueType.BOOL, "bale.fillTypes.fillType(?).fermenting#requiresWrapping", "Wrapping is required to start fermenting", true)
	schema:register(XMLValueType.FLOAT, "bale.fillTypes.fillType(?).fermenting#time", "Fermenting time in ingame days which represent months", 1)
	schema:register(XMLValueType.STRING, "bale.packedBale#singleBale", "Path to single bale xml filename")
	schema:register(XMLValueType.NODE_INDEX, "bale.packedBale.singleBale(?)#node", "Single bale spawn node")
end
function BaleManager.registerBaleTextureXMLPaths(schema, basePath)
	schema:register(XMLValueType.FILENAME, basePath .. ".diffuse#filename", "Diffuse texture to apply to all mesh nodes")
	schema:register(XMLValueType.BOOL, basePath .. ".diffuse#useFillTypeArray", "Use the fill type array texture for diffuse", false)
	schema:register(XMLValueType.FILENAME, basePath .. ".normal#filename", "Normal texture to apply to all mesh nodes")
	schema:register(XMLValueType.BOOL, basePath .. ".normal#useFillTypeArray", "Use the fill type array texture for normal", false)
	schema:register(XMLValueType.FILENAME, basePath .. ".alpha#filename", "Alpha texture to apply to all mesh nodes")
	schema:register(XMLValueType.FILENAME, basePath .. ".baleNormal#filename", "Bale normal texture to apply to all mesh nodes")
	schema:register(XMLValueType.FILENAME, basePath .. ".netWrapDiffuse#filename", "Net wrap diffuse texture to apply to all mesh nodes")
	schema:register(XMLValueType.FILENAME, basePath .. ".netWrapNormal#filename", "Net Wrap normal texture to apply to all mesh nodes")
end
function BaleManager.registerMapBalesXMLPaths(schema)
	schema:register(XMLValueType.STRING, "map.bales.bale(?)#filename", "Path to bale xml")
	schema:register(XMLValueType.STRING, "map.bales.bale(?)#isAvailable", "Bale is available for all balers to spawn")
end
g_baleManager = BaleManager.new()
