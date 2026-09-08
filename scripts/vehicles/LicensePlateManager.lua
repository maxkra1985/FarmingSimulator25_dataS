-- Local values: LicensePlateManager_mt
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

-- Upvalues: LicensePlateManager_mt
function LicensePlateManager.new(customMt)
	-- upvalues: (copy) LicensePlateManager_mt
	return AbstractManager.new(customMt or LicensePlateManager_mt)
end

function LicensePlateManager:initDataStructures()
	self.licensePlates = {}
	self.colorConfigurations = {}
	self.licensePlatesAvailable = false
	self.sharedLoadRequestIds = {}
end

-- Local values: filename
function LicensePlateManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	LicensePlateManager:superClass().loadMapData(self)
	self.baseDirectory = baseDirectory
	local v7_ = getXMLString(xmlFile, "map.licensePlates#filename")
	if v7_ ~= nil then
		self.xmlFilename = Utils.getFilename(v7_, baseDirectory)
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

-- Local values: i, _, sharedLoadRequestId
function LicensePlateManager:unloadMapData()
	for v9_ = 1, #self.licensePlates do
		self.licensePlates[v9_]:delete()
	end
	if self.sharedLoadRequestIds ~= nil then
		for _, v10_ in ipairs(self.sharedLoadRequestIds) do
			g_i3DManager:releaseSharedI3DFile(v10_)
		end
		self.sharedLoadRequestIds = nil
	end
	if self.licensePlateXML ~= nil then
		self.licensePlateXML:delete()
		self.licensePlateXML = nil
	end
	LicensePlateManager:superClass().unloadMapData(self)
end

-- Local values: customEnvironment, _, defaultConfiguration, j, j, brandMaterialName, color, title, colorData, brightness, placementStr
function LicensePlateManager:loadLicensePlatesFromXML(xmlFile, baseDirectory)
	local v_u_14_, _ = Utils.getModNameAndBaseDirectory(baseDirectory)
	self.fontName = xmlFile:getValue("licensePlates.font#name", "GENERIC")
	self.customEnvironment = v_u_14_
	xmlFile:iterate("licensePlates.licensePlate", function(_, p15_)
		-- upvalues: (copy) xmlFile, (copy) self, (copy) baseDirectory, (copy) v_u_14_
		local v16_ = xmlFile:getValue(p15_ .. "#filename")
		if v16_ == nil then
			Logging.xmlError(xmlFile, "Missing filename for license plate \'%s\'", p15_)
		else
			self.xmlReferences = self.xmlReferences + 1
			local v17_ = Utils.getFilename(v16_, baseDirectory)
			local v18_ = {
				["filename"] = v17_,
				["xmlFile"] = xmlFile,
				["plateKey"] = p15_,
				["customEnvironment"] = v_u_14_
			}
			local v19_ = g_i3DManager:loadSharedI3DFileAsync(v17_, false, false, self.licensePlateI3DFileLoaded, self, v18_)
			local v20_ = self.sharedLoadRequestIds
			table.insert(v20_, v19_)
		end
	end)
	self.materialNamePlate = xmlFile:getValue("licensePlates.colorConfigurations#materialName", "licensePlateColored_mat")
	self.shaderParameterCharacters = xmlFile:getValue("licensePlates.colorConfigurations#shaderParameterCharacters", "colorScale")
	self.useDefaultColors = xmlFile:getValue("licensePlates.colorConfigurations#useDefaultColors", false)
	self.defaultColorIndex = xmlFile:getValue("licensePlates.colorConfigurations#defaultColorIndex")
	self.defaultColorMaxBrightness = xmlFile:getValue("licensePlates.colorConfigurations#defaultColorMaxBrightness", 0.55)
	local v_u_21_ = 1
	xmlFile:iterate("licensePlates.colorConfigurations.colorConfiguration", function(p22_, p23_)
		-- upvalues: (copy) xmlFile, (copy) self, (ref) v_u_21_
		local v24_ = xmlFile:getValue(p23_ .. "#name", "", self.customEnvironment, false)
		local v25_ = xmlFile:getValue(p23_ .. "#color", nil, true)
		local v26_ = xmlFile:getValue(p23_ .. "#isDefault", false)
		if v25_ ~= nil then
			if v26_ then
				v_u_21_ = p22_
			end
			local v27_ = self.colorConfigurations
			table.insert(v27_, {
				["name"] = v24_,
				["color"] = v25_,
				["isDefault"] = v26_
			})
		end
	end)
	if self.defaultColorIndex == nil then
		self.defaultColorIndex = v_u_21_
	else
		self.defaultColorIndex = self.defaultColorIndex + #self.colorConfigurations
	end
	self.colors = {}
	for v28_ = 1, #self.colorConfigurations do
		local v29_ = self.colors
		local v30_ = self.colorConfigurations[v28_]
		table.insert(v29_, v30_)
	end
	if self.useDefaultColors then
		for v31_ = 1, #VehicleConfigurationItemColor.DEFAULT_COLORS do
			local v32_ = VehicleConfigurationItemColor.DEFAULT_COLORS[v31_]
			local v33_, v34_ = g_vehicleMaterialManager:getMaterialTemplateColorAndTitleByName(v32_, v_u_14_)
			if v33_ ~= nil then
				local v35_ = {
					["name"] = v34_ or "",
					["color"] = v33_
				}
				if MathUtil.getBrightnessFromColor(v33_[1], v33_[2], v33_[3]) < self.defaultColorMaxBrightness then
					local v36_ = self.colors
					table.insert(v36_, v35_)
				end
			end
		end
	end
	self.defaultPlacementIndex = LicensePlateManager.PLACEMENT_OPTION.BOTH
	local v37_ = xmlFile:getValue("licensePlates.placement#defaultType")
	if v37_ ~= nil then
		self.defaultPlacementIndex = LicensePlateManager.PLACEMENT_OPTION[string.upper(v37_)] or self.defaultPlacementIndex
	end
end

-- Local values: filename, xmlFile, plateKey, customEnvironment, node, licensePlate
function LicensePlateManager:licensePlateI3DFileLoaded(i3dNode, failedReason, args)
	local v41_ = args.filename
	local v42_ = args.xmlFile
	local v43_ = args.plateKey
	local v44_ = args.customEnvironment
	if i3dNode ~= nil and i3dNode ~= 0 then
		local v45_ = v42_:getValue(v43_ .. "#node", nil, i3dNode)
		if v45_ ~= nil then
			unlink(v45_)
			local v46_ = LicensePlate.new()
			if v46_:loadFromXML(v45_, v41_, v44_, v42_, v43_) then
				local v47_ = self.licensePlates
				table.insert(v47_, v46_)
			end
		end
		delete(i3dNode)
	end
	self.xmlReferences = self.xmlReferences - 1
	if self.xmlReferences == 0 then
		v42_:delete()
		self.licensePlatesAvailable = #self.licensePlates > 0
		if v42_ == self.licensePlateXML then
			self.licensePlateXML = nil
		end
	end
end

function LicensePlateManager:getAreLicensePlatesAvailable()
	local v49_ = self.licensePlatesAvailable
	if v49_ then
		v49_ = g_materialManager:getFontMaterial(self.fontName, self.customEnvironment)
	end
	return v49_
end

-- Local values: licensePlate, i
function LicensePlateManager:getLicensePlate(preferedType, includeFrame)
	local v53_ = self.licensePlates[1]
	for v54_ = 1, #self.licensePlates do
		if self.licensePlates[v54_].type == preferedType then
			v53_ = self.licensePlates[v54_]
		end
	end
	if v53_ == nil then
		return nil
	else
		return v53_:clone(includeFrame)
	end
end

-- Local values: variation
function LicensePlateManager:getLicensePlateValues(licensePlate, variationIndex)
	local v57_ = licensePlate.variations[variationIndex]
	if v57_ == nil then
		return nil
	else
		return v57_.values
	end
end

-- Local values: licensePlate, variationIndex, characters, colorIndex
function LicensePlateManager:getRandomLicensePlateData()
	local v59_ = self.licensePlates[1]
	return v59_ == nil and {
		["variation"] = 1,
		["characters"] = nil,
		["colorIndex"] = nil,
		["placementIndex"] = self:getDefaultPlacementIndex()
	} or {
		["variation"] = 1,
		["characters"] = v59_:getRandomCharacters(1),
		["colorIndex"] = self.defaultColorIndex,
		["placementIndex"] = self:getDefaultPlacementIndex()
	}
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

-- Local values: licensePlateData, valid, font, numCharacters, i, index, character
function LicensePlateManager.readLicensePlateData(streamId, connection)
	local v64_ = {
		["variation"] = 1,
		["characters"] = nil,
		["colorIndex"] = nil,
		["placementIndex"] = 1
	}
	if streamReadBool(streamId) then
		v64_.variation = streamReadUIntN(streamId, LicensePlateManager.SEND_NUM_BITS_VARIATION)
		v64_.colorIndex = streamReadUIntN(streamId, LicensePlateManager.SEND_NUM_BITS_COLOR)
		v64_.placementIndex = streamReadUIntN(streamId, LicensePlateManager.SEND_NUM_BITS_PLACEMENT)
		local v65_ = g_licensePlateManager:getFont()
		v64_.characters = {}
		for _ = 1, streamReadUIntN(streamId, LicensePlateManager.SEND_NUM_BITS_CHARACTER) do
			local v66_ = v65_:getCharacterByCharacterIndex((streamReadUIntN(streamId, LicensePlateManager.SEND_NUM_BITS_CHARACTER))) or "_"
			local v67_ = v64_.characters
			table.insert(v67_, v66_)
		end
	end
	return v64_
end

-- Local values: font, i, index
function LicensePlateManager.writeLicensePlateData(streamId, connection, licensePlateData)
	local v70_ = streamWriteBool
	local v71_
	if licensePlateData == nil or (licensePlateData.variation == nil or (licensePlateData.characters == nil or licensePlateData.colorIndex == nil)) then
		v71_ = false
	else
		v71_ = licensePlateData.placementIndex ~= nil
	end
	if v70_(streamId, v71_) then
		streamWriteUIntN(streamId, licensePlateData.variation, LicensePlateManager.SEND_NUM_BITS_VARIATION)
		streamWriteUIntN(streamId, licensePlateData.colorIndex, LicensePlateManager.SEND_NUM_BITS_COLOR)
		streamWriteUIntN(streamId, licensePlateData.placementIndex, LicensePlateManager.SEND_NUM_BITS_PLACEMENT)
		local v72_ = g_licensePlateManager:getFont()
		streamWriteUIntN(streamId, #licensePlateData.characters, LicensePlateManager.SEND_NUM_BITS_CHARACTER)
		for v73_ = 1, #licensePlateData.characters do
			local v74_ = v72_:getCharacterIndexByCharacter(licensePlateData.characters[v73_])
			streamWriteUIntN(streamId, v74_, LicensePlateManager.SEND_NUM_BITS_CHARACTER)
		end
	end
end

-- Local values: valid, licensePlateData, characters, characterLength, i
function LicensePlateManager.loadLicensePlateDataFromXML(xmlFile, key, useAbsolutePaths)
	if not xmlFile:hasProperty(key .. "#variation") then
		return nil
	end
	local v78_ = {}
	if useAbsolutePaths then
		v78_.xmlFilename = xmlFile:getString(key .. "#configuration")
	else
		v78_.xmlFilename = NetworkUtil.convertFromNetworkFilename(xmlFile:getString(key .. "#configuration"))
	end
	v78_.variation = xmlFile:getInt(key .. "#variation")
	v78_.colorIndex = xmlFile:getInt(key .. "#color")
	v78_.placementIndex = xmlFile:getInt(key .. "#placement")
	v78_.characters = {}
	local v79_ = xmlFile:getString(key .. "#characters")
	for v80_ = 1, v79_:len() do
		local v81_ = v78_.characters
		table.insert(v81_, v79_:sub(v80_, v80_))
	end
	return v78_
end

-- Local values: valid
function LicensePlateManager.saveLicensePlateDataToXML(xmlFile, key, licensePlateData, useAbsolutePaths)
	local v86_
	if licensePlateData == nil or (licensePlateData.variation == nil or (licensePlateData.characters == nil or licensePlateData.colorIndex == nil)) then
		v86_ = false
	else
		v86_ = licensePlateData.placementIndex ~= nil
	end
	if v86_ then
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

-- Local values: position, rootPlate, ratio, availableHeight, availableWidth, charactersPerRow, row, useLastRowCharacters, rowPosition, col, licensePlate, characters, cameraNode
function LicensePlateManager.createLicensePlateAIIcons(_, numX, numY, variationIndex, positionStr)
	if LicensePlateManager.licensePlatesIconRootNode == nil then
		local v93_ = tonumber(numX) or 3
		local v94_ = tonumber(numY) or 10
		local v95_ = tonumber(variationIndex) or 1
		local v96_
		if positionStr == nil then
			v96_ = nil
		else
			v96_ = LicensePlateManager.PLATE_POSITION[string.upper(positionStr)]
		end
		LicensePlateManager.licensePlatesIconRootNode = createTransformGroup("licensePlatesIconRootNode")
		link(getRootNode(), LicensePlateManager.licensePlatesIconRootNode)
		setTranslation(LicensePlateManager.licensePlatesIconRootNode, 0, -10, 0)
		local v97_ = g_licensePlateManager:getLicensePlate(LicensePlateManager.PLATE_TYPE.ELONGATED)
		if v97_ ~= nil then
			local _ = v97_.height / v97_.width
			local v98_ = v94_ * v97_.height
			local v99_ = v93_ * v97_.width
			local v100_ = {}
			for v101_ = 1, v94_ do
				v100_[v101_] = {}
				local v102_ = false
				local v103_
				if v96_ == nil then
					if v101_ % 2 == 0 then
						v103_ = LicensePlateManager.PLATE_POSITION.FRONT
						v102_ = true
					else
						v103_ = LicensePlateManager.PLATE_POSITION.BACK
					end
				else
					v103_ = v96_
				end
				for v104_ = 1, v93_ do
					local v105_ = g_licensePlateManager:getLicensePlate(LicensePlateManager.PLATE_TYPE.ELONGATED)
					if v105_ ~= nil then
						link(LicensePlateManager.licensePlatesIconRootNode, v105_.node)
						setTranslation(v105_.node, (v104_ - 1) * v97_.width + v97_.width * 0.5, (v101_ - 1) * v97_.height + v97_.height * 0.5, 0)
						setRotation(v105_.node, 0, 0, 0)
						local v106_
						if v102_ and v101_ > 1 then
							v106_ = v100_[v101_ - 1][v104_]
						else
							v106_ = v105_:getRandomCharacters(v95_)
						end
						v100_[v101_][v104_] = v106_
						v105_:updateData(v95_, v103_, table.concat(v106_, ""))
					end
				end
			end
			local v107_ = createCamera("licensePlatesIconCamera", 3437.746770784939, 0.1, 12)
			link(LicensePlateManager.licensePlatesIconRootNode, v107_)
			setTranslation(v107_, v99_ * 0.5, v98_ * 0.5, 10)
			setIsOrthographic(v107_, true)
			setOrthographicHeight(v107_, v98_)
			LicensePlateManager.licensePlatesIconLastCamera = g_cameraManager:getActiveCamera()
			g_cameraManager:addCamera(v107_)
			g_cameraManager:setActiveCamera(v107_)
			g_currentMission.hud:setIsVisible(false)
			g_noHudModeEnabled = true
		end
	else
		delete(LicensePlateManager.licensePlatesIconRootNode)
		LicensePlateManager.licensePlatesIconRootNode = nil
		g_cameraManager:setActiveCamera(LicensePlateManager.licensePlatesIconLastCamera)
		LicensePlateManager.licensePlatesIconLastCamera = nil
		g_currentMission.hud:setIsVisible(true)
	end
end
addConsoleCommand("gsLicensePlateCreateAIIcons", "Create license plate icons for AI vehicles", "createLicensePlateAIIcons", LicensePlateManager, "numX; numY; variationIndex; position")
function LicensePlateManager.createLicensePlateXMLSchema()
	if LicensePlateManager.xmlSchema == nil then
		local v108_ = XMLSchema.new("mapLicensePlates")
		LicensePlate.registerXMLPaths(v108_, "licensePlates.licensePlate(?)")
		v108_:register(XMLValueType.STRING, "licensePlates.font#name", "License plate font name", "GENERIC")
		v108_:register(XMLValueType.STRING, "licensePlates.colorConfigurations#materialName", "Name of colored license plate material", "licensePlateColored_mat")
		v108_:register(XMLValueType.STRING, "licensePlates.colorConfigurations#shaderParameterCharacters", "Color shader parameter of characters", "colorSale")
		v108_:register(XMLValueType.BOOL, "licensePlates.colorConfigurations#useDefaultColors", "License plate can be colored with all available default colors", false)
		v108_:register(XMLValueType.INT, "licensePlates.colorConfigurations#defaultColorIndex", "Default selected color")
		v108_:register(XMLValueType.FLOAT, "licensePlates.colorConfigurations#defaultColorMaxBrightness", "Default colors with higher brightness will be skipped", 0.55)
		v108_:register(XMLValueType.L10N_STRING, "licensePlates.colorConfigurations.colorConfiguration(?)#name", "Name of color to display")
		v108_:register(XMLValueType.COLOR, "licensePlates.colorConfigurations.colorConfiguration(?)#color", "Color values")
		v108_:register(XMLValueType.BOOL, "licensePlates.colorConfigurations.colorConfiguration(?)#isDefault", "Color is default selected")
		v108_:register(XMLValueType.STRING, "licensePlates.placement#defaultType", "Default type of placement (none/both/back_only)", "both")
		LicensePlateManager.xmlSchema = v108_
	end
end
g_licensePlateManager = LicensePlateManager.new()
