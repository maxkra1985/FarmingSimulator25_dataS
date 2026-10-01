LicensePlateManager = {}
LicensePlateManager.PLATE_TYPE = {}
LicensePlateManager.PLATE_TYPE.SQUARISH = 0
LicensePlateManager.PLATE_TYPE.ELONGATED = 1
LicensePlateManager.PLATE_POSITION = {}
LicensePlateManager.PLATE_POSITION.NONE = 0
LicensePlateManager.PLATE_POSITION.FRONT = 1
LicensePlateManager.PLATE_POSITION.BACK = 2
LicensePlateManager.PLATE_POSITION.ANY = 3
LicensePlateManager.CHARACTER_TYPE = {}
LicensePlateManager.CHARACTER_TYPE.NUMERICAL = 0
LicensePlateManager.CHARACTER_TYPE.ALPHABETICAL = 1
LicensePlateManager.CHARACTER_TYPE.SPECIAL = 2
LicensePlateManager.PLACEMENT_OPTION = {}
LicensePlateManager.PLACEMENT_OPTION.NONE = 0
LicensePlateManager.PLACEMENT_OPTION.BOTH = 1
LicensePlateManager.PLACEMENT_OPTION.BACK_ONLY = 2
LicensePlateManager.PLACEMENT_OPTION_TEXT = {}
LicensePlateManager.PLACEMENT_OPTION_TEXT[LicensePlateManager.PLACEMENT_OPTION.NONE] = "ui_licensePlatePlacementNone"
LicensePlateManager.PLACEMENT_OPTION_TEXT[LicensePlateManager.PLACEMENT_OPTION.BOTH] = "ui_licensePlatePlacementBoth"
LicensePlateManager.PLACEMENT_OPTION_TEXT[LicensePlateManager.PLACEMENT_OPTION.BACK_ONLY] = "ui_licensePlatePlacementBackOnly"
LicensePlateManager.SEND_NUM_BITS_VARIATION = 4
LicensePlateManager.SEND_NUM_BITS_COLOR = 6
LicensePlateManager.SEND_NUM_BITS_CHARACTER = 8
LicensePlateManager.SEND_NUM_BITS_PLACEMENT = 2
LicensePlateManager.xmlSchema = nil
local LicensePlateManager_mt = Class(LicensePlateManager, AbstractManager)
g_xmlManager:addInitSchemaFunction(function()
	LicensePlateManager.createLicensePlateXMLSchema()
end)
function LicensePlateManager.new(customMt)
	return AbstractManager.new(customMt or LicensePlateManager_mt)
end
function LicensePlateManager:initDataStructures()
	self.licensePlates = {}
	self.colorConfigurations = {}
	self.licensePlatesAvailable = false
	self.sharedLoadRequestIds = {}
end
function LicensePlateManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	LicensePlateManager:superClass().loadMapData(self)
	self.baseDirectory = baseDirectory
	local filename = getXMLString(xmlFile, "map.licensePlates#filename")
	if filename ~= nil then
		self.xmlFilename = Utils.getFilename(filename, baseDirectory)
		self.licensePlateXML = XMLFile.load("mapLicensePlates", self.xmlFilename, LicensePlateManager.xmlSchema)
		if self.licensePlateXML ~= nil then
			self.xmlReferences = 0
			self:loadLicensePlatesFromXML(self.licensePlateXML, baseDirectory)
			if self.licensePlateXML ~= nil and self.xmlReferences == 0 then
				self.licensePlateXML:delete()
				self.licensePlateXML = nil
			end
		end
	end
	return true
end
function LicensePlateManager:unloadMapData()
	for i = 1, #self.licensePlates do
		self.licensePlates[i]:delete()
	end
	if self.sharedLoadRequestIds ~= nil then
		for _, sharedLoadRequestId in ipairs(self.sharedLoadRequestIds) do
			g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
		end
		self.sharedLoadRequestIds = nil
	end
	if self.licensePlateXML ~= nil then
		self.licensePlateXML:delete()
		self.licensePlateXML = nil
	end
	LicensePlateManager:superClass().unloadMapData(self)
end
function LicensePlateManager:loadLicensePlatesFromXML(xmlFile, baseDirectory)
	local customEnvironment, _ = Utils.getModNameAndBaseDirectory(baseDirectory)
	self.fontName = xmlFile:getValue("licensePlates.font#name", "GENERIC")
	self.customEnvironment = customEnvironment
	xmlFile:iterate("licensePlates.licensePlate", function(_, plateKey)
		local filename = xmlFile:getValue(plateKey .. "#filename")
		if filename ~= nil then
			self.xmlReferences = self.xmlReferences + 1
			filename = Utils.getFilename(filename, baseDirectory)
			local arguments = { filename = filename, plateKey = plateKey }
			arguments.xmlFile = xmlFile
			arguments.customEnvironment = customEnvironment
			local sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(filename, false, false, self.licensePlateI3DFileLoaded, self, arguments)
			table.insert(self.sharedLoadRequestIds, sharedLoadRequestId)
		else
			Logging.xmlError(xmlFile, "Missing filename for license plate '%s'", plateKey)
		end
	end)
	self.materialNamePlate = xmlFile:getValue("licensePlates.colorConfigurations#materialName", "licensePlateColored_mat")
	self.shaderParameterCharacters = xmlFile:getValue("licensePlates.colorConfigurations#shaderParameterCharacters", "colorScale")
	self.useDefaultColors = xmlFile:getValue("licensePlates.colorConfigurations#useDefaultColors", false)
	self.defaultColorIndex = xmlFile:getValue("licensePlates.colorConfigurations#defaultColorIndex")
	self.defaultColorMaxBrightness = xmlFile:getValue("licensePlates.colorConfigurations#defaultColorMaxBrightness", 0.55)
	local defaultConfiguration = 1
	xmlFile:iterate("licensePlates.colorConfigurations.colorConfiguration", function(index, baseKey)
		local name = xmlFile:getValue(baseKey .. "#name", "", self.customEnvironment, false)
		local color = xmlFile:getValue(baseKey .. "#color", nil, true)
		local isDefault = xmlFile:getValue(baseKey .. "#isDefault", false)
		if color ~= nil then
			if isDefault then
				defaultConfiguration = index
			end
			table.insert(self.colorConfigurations, { name = name, color = color, isDefault = isDefault })
		end
	end)
	if self.defaultColorIndex ~= nil then
		self.defaultColorIndex = self.defaultColorIndex + #self.colorConfigurations
	else
		self.defaultColorIndex = defaultConfiguration
	end
	self.colors = {}
	for j = 1, #self.colorConfigurations do
		table.insert(self.colors, self.colorConfigurations[j])
	end
	if self.useDefaultColors then
		for j = 1, #VehicleConfigurationItemColor.DEFAULT_COLORS do
			local brandMaterialName = VehicleConfigurationItemColor.DEFAULT_COLORS[j]
			local color, title = g_vehicleMaterialManager:getMaterialTemplateColorAndTitleByName(brandMaterialName, customEnvironment)
			if color == nil then
				continue
			end
			local colorData = { color = color }
			colorData.name = title or ""
			local brightness = MathUtil.getBrightnessFromColor(color[1], color[2], color[3])
			if brightness < self.defaultColorMaxBrightness then
				table.insert(self.colors, colorData)
			end
		end
	end
	self.defaultPlacementIndex = LicensePlateManager.PLACEMENT_OPTION.BOTH
	local placementStr = xmlFile:getValue("licensePlates.placement#defaultType")
	if placementStr ~= nil then
		self.defaultPlacementIndex = LicensePlateManager.PLACEMENT_OPTION[string.upper(placementStr)] or self.defaultPlacementIndex
	end
end
function LicensePlateManager:licensePlateI3DFileLoaded(i3dNode, failedReason, args)
	local filename = args.filename
	local xmlFile = args.xmlFile
	local plateKey = args.plateKey
	local customEnvironment = args.customEnvironment
	if i3dNode ~= nil and i3dNode ~= 0 then
		local node = xmlFile:getValue(plateKey .. "#node", nil, i3dNode)
		if node ~= nil then
			unlink(node)
			local licensePlate = LicensePlate.new()
			if licensePlate:loadFromXML(node, filename, customEnvironment, xmlFile, plateKey) then
				table.insert(self.licensePlates, licensePlate)
			end
		end
		delete(i3dNode)
	end
	self.xmlReferences = self.xmlReferences - 1
	if self.xmlReferences == 0 then
		xmlFile:delete()
		self.licensePlatesAvailable = 0 < #self.licensePlates
		if xmlFile == self.licensePlateXML then
			self.licensePlateXML = nil
		end
	end
end
function LicensePlateManager:getAreLicensePlatesAvailable()
	return self.licensePlatesAvailable and g_materialManager:getFontMaterial(self.fontName, self.customEnvironment)
end
function LicensePlateManager:getLicensePlate(preferedType, includeFrame)
	local licensePlate = self.licensePlates[1]
	for i = 1, #self.licensePlates do
		if self.licensePlates[i].type == preferedType then
			licensePlate = self.licensePlates[i]
		end
	end
	if licensePlate ~= nil then
		return licensePlate:clone(includeFrame)
	else
		return nil
	end
end
function LicensePlateManager:getLicensePlateValues(licensePlate, variationIndex)
	local variation = licensePlate.variations[variationIndex]
	if variation ~= nil then
		return variation.values
	else
		return nil
	end
end
function LicensePlateManager:getRandomLicensePlateData()
	local licensePlate = self.licensePlates[1]
	if licensePlate ~= nil then
		local variationIndex = 1
		local characters = licensePlate:getRandomCharacters(1)
		local colorIndex = self.defaultColorIndex
		return { variation = variationIndex, characters = characters, colorIndex = colorIndex, placementIndex = self:getDefaultPlacementIndex() }
	else
		return { variation = 1, characters = nil, colorIndex = nil, placementIndex = self:getDefaultPlacementIndex() }
	end
end
function LicensePlateManager:getAvailableColors()
	return self.colors, self.defaultColorIndex
end
function LicensePlateManager:getDefaultPlacementIndex()
	return self.defaultPlacementIndex
end
function LicensePlateManager:getFont()
	return g_materialManager:getFontMaterial(self.fontName, self.customEnvironment)
end
function LicensePlateManager.readLicensePlateData(streamId, connection)
	local licensePlateData = { variation = 1, characters = nil, colorIndex = nil, placementIndex = 1 }
	local valid = streamReadBool(streamId)
	if valid then
		licensePlateData.variation = streamReadUIntN(streamId, LicensePlateManager.SEND_NUM_BITS_VARIATION)
		licensePlateData.colorIndex = streamReadUIntN(streamId, LicensePlateManager.SEND_NUM_BITS_COLOR)
		licensePlateData.placementIndex = streamReadUIntN(streamId, LicensePlateManager.SEND_NUM_BITS_PLACEMENT)
		local font = g_licensePlateManager:getFont()
		licensePlateData.characters = {}
		local numCharacters = streamReadUIntN(streamId, LicensePlateManager.SEND_NUM_BITS_CHARACTER)
		for i = 1, numCharacters do
			local index = streamReadUIntN(streamId, LicensePlateManager.SEND_NUM_BITS_CHARACTER)
			local character = font:getCharacterByCharacterIndex(index) or "_"
			table.insert(licensePlateData.characters, character)
		end
	end
	return licensePlateData
end
function LicensePlateManager.writeLicensePlateData(streamId, connection, licensePlateData)
	if streamWriteBool(streamId, licensePlateData ~= nil and licensePlateData.variation ~= nil and licensePlateData.characters ~= nil and licensePlateData.colorIndex ~= nil and licensePlateData.placementIndex ~= nil) then
		streamWriteUIntN(streamId, licensePlateData.variation, LicensePlateManager.SEND_NUM_BITS_VARIATION)
		streamWriteUIntN(streamId, licensePlateData.colorIndex, LicensePlateManager.SEND_NUM_BITS_COLOR)
		streamWriteUIntN(streamId, licensePlateData.placementIndex, LicensePlateManager.SEND_NUM_BITS_PLACEMENT)
		local font = g_licensePlateManager:getFont()
		streamWriteUIntN(streamId, #licensePlateData.characters, LicensePlateManager.SEND_NUM_BITS_CHARACTER)
		for i = 1, #licensePlateData.characters do
			local index = font:getCharacterIndexByCharacter(licensePlateData.characters[i])
			streamWriteUIntN(streamId, index, LicensePlateManager.SEND_NUM_BITS_CHARACTER)
		end
	end
end
function LicensePlateManager.loadLicensePlateDataFromXML(xmlFile, key, useAbsolutePaths)
	local valid = xmlFile:hasProperty(key .. "#variation")
	if valid then
		local licensePlateData = {}
		if useAbsolutePaths then
			licensePlateData.xmlFilename = xmlFile:getString(key .. "#configuration")
		else
			licensePlateData.xmlFilename = NetworkUtil.convertFromNetworkFilename(xmlFile:getString(key .. "#configuration"))
		end
		licensePlateData.variation = xmlFile:getInt(key .. "#variation")
		licensePlateData.colorIndex = xmlFile:getInt(key .. "#color")
		licensePlateData.placementIndex = xmlFile:getInt(key .. "#placement")
		licensePlateData.characters = {}
		local characters = xmlFile:getString(key .. "#characters")
		local characterLength = characters:len()
		for i = 1, characterLength do
			table.insert(licensePlateData.characters, characters:sub(i, i))
		end
		return licensePlateData
	else
		return nil
	end
end
function LicensePlateManager.saveLicensePlateDataToXML(xmlFile, key, licensePlateData, useAbsolutePaths)
	local valid = licensePlateData ~= nil and licensePlateData.variation ~= nil and licensePlateData.characters ~= nil and licensePlateData.colorIndex ~= nil and licensePlateData.placementIndex ~= nil
	if valid then
		xmlFile:setInt(key .. "#variation", licensePlateData.variation)
		xmlFile:setInt(key .. "#color", licensePlateData.colorIndex)
		xmlFile:setInt(key .. "#placement", licensePlateData.placementIndex)
		xmlFile:setString(key .. "#characters", table.concat(licensePlateData.characters, ""))
		if useAbsolutePaths then
			xmlFile:setString(key .. "#configuration", licensePlateData.xmlFilename)
			return
		end
		xmlFile:setString(key .. "#configuration", NetworkUtil.convertToNetworkFilename(licensePlateData.xmlFilename))
	end
end
function LicensePlateManager.registerSavegameXMLpaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#variation", nil, "Variation of the license place")
	schema:register(XMLValueType.INT, basePath .. "#color", nil, "Color index of the license place")
	schema:register(XMLValueType.INT, basePath .. "#placement", nil, "Placement index of the license place")
	schema:register(XMLValueType.STRING, basePath .. "#characters", nil, "Used characters of the license place")
	schema:register(XMLValueType.STRING, basePath .. "#configuration", nil, "Configuration of the license place")
end
function LicensePlateManager.createLicensePlateAIIcons(_, numX, numY, variationIndex, positionStr)
	if LicensePlateManager.licensePlatesIconRootNode ~= nil then
		delete(LicensePlateManager.licensePlatesIconRootNode)
		LicensePlateManager.licensePlatesIconRootNode = nil
		g_cameraManager:setActiveCamera(LicensePlateManager.licensePlatesIconLastCamera)
		LicensePlateManager.licensePlatesIconLastCamera = nil
		g_currentMission.hud:setIsVisible(true)
	else
		numX = tonumber(numX) or 3
		numY = tonumber(numY) or 10
		variationIndex = tonumber(variationIndex) or 1
		local position = nil
		if positionStr ~= nil then
			position = LicensePlateManager.PLATE_POSITION[string.upper(positionStr)]
		end
		LicensePlateManager.licensePlatesIconRootNode = createTransformGroup("licensePlatesIconRootNode")
		link(getRootNode(), LicensePlateManager.licensePlatesIconRootNode)
		setTranslation(LicensePlateManager.licensePlatesIconRootNode, 0, -10, 0)
		local rootPlate = g_licensePlateManager:getLicensePlate(LicensePlateManager.PLATE_TYPE.ELONGATED)
		if rootPlate ~= nil then
			local ratio = rootPlate.height / rootPlate.width
			local availableHeight = numY * rootPlate.height
			local availableWidth = numX * rootPlate.width
			local charactersPerRow = {}
			for row = 1, numY do
				charactersPerRow[row] = {}
				local useLastRowCharacters = false
				local rowPosition = position
				if rowPosition == nil then
					if row % 2 == 0 then
						rowPosition = LicensePlateManager.PLATE_POSITION.FRONT
						useLastRowCharacters = true
					else
						rowPosition = LicensePlateManager.PLATE_POSITION.BACK
					end
				end
				for col = 1, numX do
					local licensePlate = g_licensePlateManager:getLicensePlate(LicensePlateManager.PLATE_TYPE.ELONGATED)
					if licensePlate == nil then
						continue
					end
					link(LicensePlateManager.licensePlatesIconRootNode, licensePlate.node)
					setTranslation(licensePlate.node, (col - 1) * rootPlate.width + rootPlate.width * 0.5, (row - 1) * rootPlate.height + rootPlate.height * 0.5, 0)
					setRotation(licensePlate.node, 0, 0, 0)
					local characters = nil
					if useLastRowCharacters then
						if 1 < row then
							characters = charactersPerRow[row - 1][col]
						else
							characters = licensePlate:getRandomCharacters(variationIndex)
						end
					end
					charactersPerRow[row][col] = characters
					licensePlate:updateData(variationIndex, rowPosition, table.concat(characters, ""))
				end
			end
			local cameraNode = createCamera("licensePlatesIconCamera", 3437.746770784939, 0.1, 12)
			link(LicensePlateManager.licensePlatesIconRootNode, cameraNode)
			setTranslation(cameraNode, availableWidth * 0.5, availableHeight * 0.5, 10)
			setIsOrthographic(cameraNode, true)
			setOrthographicHeight(cameraNode, availableHeight)
			LicensePlateManager.licensePlatesIconLastCamera = g_cameraManager:getActiveCamera()
			g_cameraManager:addCamera(cameraNode)
			g_cameraManager:setActiveCamera(cameraNode)
			g_currentMission.hud:setIsVisible(false)
			g_noHudModeEnabled = true
		end
	end
end
addConsoleCommand("gsLicensePlateCreateAIIcons", "Create license plate icons for AI vehicles", "createLicensePlateAIIcons", LicensePlateManager, "numX; numY; variationIndex; position")
function LicensePlateManager.createLicensePlateXMLSchema()
	if LicensePlateManager.xmlSchema == nil then
		local schema = XMLSchema.new("mapLicensePlates")
		LicensePlate.registerXMLPaths(schema, "licensePlates.licensePlate(?)")
		schema:register(XMLValueType.STRING, "licensePlates.font#name", "License plate font name", "GENERIC")
		schema:register(XMLValueType.STRING, "licensePlates.colorConfigurations#materialName", "Name of colored license plate material", "licensePlateColored_mat")
		schema:register(XMLValueType.STRING, "licensePlates.colorConfigurations#shaderParameterCharacters", "Color shader parameter of characters", "colorSale")
		schema:register(XMLValueType.BOOL, "licensePlates.colorConfigurations#useDefaultColors", "License plate can be colored with all available default colors", false)
		schema:register(XMLValueType.INT, "licensePlates.colorConfigurations#defaultColorIndex", "Default selected color")
		schema:register(XMLValueType.FLOAT, "licensePlates.colorConfigurations#defaultColorMaxBrightness", "Default colors with higher brightness will be skipped", 0.55)
		schema:register(XMLValueType.L10N_STRING, "licensePlates.colorConfigurations.colorConfiguration(?)#name", "Name of color to display")
		schema:register(XMLValueType.COLOR, "licensePlates.colorConfigurations.colorConfiguration(?)#color", "Color values")
		schema:register(XMLValueType.BOOL, "licensePlates.colorConfigurations.colorConfiguration(?)#isDefault", "Color is default selected")
		schema:register(XMLValueType.STRING, "licensePlates.placement#defaultType", "Default type of placement (none/both/back_only)", "both")
		LicensePlateManager.xmlSchema = schema
	end
end
g_licensePlateManager = LicensePlateManager.new()
