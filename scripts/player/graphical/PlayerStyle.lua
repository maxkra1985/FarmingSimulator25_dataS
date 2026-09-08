-- Local values: PlayerStyle_mt
PlayerStyle = {}
local PlayerStyle_mt = Class(PlayerStyle)
PlayerStyle.ATLAS_COLUMNS = 16
PlayerStyle.ATLAS_ROWS = 16
PlayerStyle.SEND_NUM_BITS = 7
PlayerStyle.CONFIG_COUNT_NUM_BITS = 4

function PlayerStyle.regsterIconGenerationXMLPaths(xmlSchema, key)
	xmlSchema:register(XMLValueType.FLOAT, key .. ".iconGeneration#cameraZoom", "")
	xmlSchema:register(XMLValueType.ANGLE, key .. ".iconGeneration#cameraRotX", "")
	xmlSchema:register(XMLValueType.ANGLE, key .. ".iconGeneration#cameraRotY", "")
	xmlSchema:register(XMLValueType.VECTOR_3, key .. ".iconGeneration#cameraOffset", "")
	xmlSchema:register(XMLValueType.BOOL, key .. ".iconGeneration#ignoreOneSide", "")
	xmlSchema:register(XMLValueType.STRING, key .. ".iconGeneration#animation", "")
	xmlSchema:register(XMLValueType.STRING, key .. ".iconGeneration.top#name", "")
	xmlSchema:register(XMLValueType.STRING, key .. ".iconGeneration.hairStyle#name", "")
	xmlSchema:register(XMLValueType.STRING, key .. ".iconGeneration.face#name", "")
	xmlSchema:register(XMLValueType.STRING, key .. ".iconGeneration.bottom#name", "")
	xmlSchema:register(XMLValueType.STRING, key .. ".iconGeneration.beard#name", "")
	xmlSchema:register(XMLValueType.STRING, key .. ".iconGeneration.glasses#name", "")
	xmlSchema:register(XMLValueType.STRING, key .. ".iconGeneration.headgear#name", "")
	xmlSchema:register(XMLValueType.STRING, key .. ".iconGeneration.gloves#name", "")
	xmlSchema:register(XMLValueType.STRING, key .. ".iconGeneration.footwear#name", "")
	xmlSchema:register(XMLValueType.STRING, key .. ".iconGeneration.onepieces#name", "")
end

-- Local values: baseKey
function PlayerStyle.registerXMLPaths(xmlSchema)
	PlayerStyle.regsterIconGenerationXMLPaths(xmlSchema, "player.playerStyle")
	PlayerStyle.registerXMLColorNode(xmlSchema, "player.playerStyle.colors.clothing")
	PlayerStyle.registerXMLColorNode(xmlSchema, "player.playerStyle.colors.hair")
	xmlSchema:register(XMLValueType.STRING, "player.playerStyle.filename", "The filename of the player\'s i3d file", nil, false)
	xmlSchema:register(XMLValueType.STRING, "player.playerStyle#neutralDiffuse", "The color applied to the player\'s skin color", nil, false)
	xmlSchema:register(XMLValueType.STRING, "player.playerStyle.bodyParts.bodyPart(?)#name", "The name of the body part", nil, false)
	xmlSchema:register(XMLValueType.STRING, "player.playerStyle.bodyParts.bodyPart(?)#node", "The body part node", nil, false)
	xmlSchema:register(XMLValueType.STRING, "player.playerStyle.attachPoints.attachPoint(?)#name", "The name of the attachment point", nil, false)
	xmlSchema:register(XMLValueType.STRING, "player.playerStyle.attachPoints.attachPoint(?)#node", "The attachment node", nil, false)
	xmlSchema:register(XMLValueType.STRING, "player.filename", "The filename of the player\'s i3d file", nil, false)
	PlayerStyleConfig.registerXMLPaths(xmlSchema)
	PlayerStylePreset.registerXMLPaths(xmlSchema)
end

function PlayerStyle.registerXMLColorNode(xmlSchema, baseKey)
	xmlSchema:register(XMLValueType.STRING, baseKey .. ".color(?)#primary", "The primary color value", nil, false)
	xmlSchema:register(XMLValueType.STRING, baseKey .. ".color(?)#secondary", "The secondary color value", nil, false)
	xmlSchema:register(XMLValueType.BOOL, baseKey .. ".color(?)#default", "True if this color is the default; otherwise false", nil, false)
end

-- Local values: configName, _
function PlayerStyle.registerSavegameXMLPaths(savegameXMLSchema, baseKey)
	savegameXMLSchema:register(XMLValueType.STRING, baseKey .. "#filename", "The filename of the style", nil, true)
	for v9_, _ in pairs(PlayerStyleConfig.CONFIG_BASE_KEY_NAMES_BY_NAME) do
		PlayerStyleConfig.registerSavegameXMLPaths(savegameXMLSchema, baseKey, v9_)
	end
end

-- Local values: style, xmlFile
function PlayerStyle.defaultStyle(oldStyle)
	local v11_ = PlayerStyle.new()
	local v12_
	if oldStyle == nil or oldStyle.xmlFilename == nil then
		v12_ = next(PlayerSystem.PLAYER_STYLES_BY_FILENAME)
	else
		v12_ = oldStyle.xmlFilename
	end
	v11_.xmlFilename = v12_
	v11_:copyConfigurationFrom(PlayerSystem.PLAYER_STYLES_BY_FILENAME[v11_.xmlFilename].style)
	v11_.configs.bottom.selectedItemIndex = 1
	v11_.configs.top.selectedItemIndex = 4
	v11_.configs.footwear.selectedItemIndex = 1
	v11_.configs.hairStyle.selectedItemIndex = 2
	v11_.configs.hairStyle:setSelectedColorIndex(6)
	v11_.configs.face.selectedItemIndex = 1
	return v11_
end

-- Upvalues: PlayerStyle_mt
-- Local values: self
function PlayerStyle.new(customMt)
	-- upvalues: (copy) PlayerStyle_mt
	local v14_ = customMt or PlayerStyle_mt
	local v15_ = setmetatable({}, v14_)
	v15_.disabledOptionsForSelection = {}
	v15_.presets = {}
	v15_.presetsByName = {}
	v15_.attachPoints = {}
	v15_.bodyParts = {}
	v15_.bodyPartIndexByName = {}
	v15_.facesByName = {}
	v15_.isConfigurationLoaded = false
	v15_.configs = {}
	v15_.orderedConfigs = {}
	v15_:addConfig(PlayerStyleConfig.new(v15_, "hairStyle", { PlayerStyleConfig.NOT_FOR_HAT_GETTER_FILTER }, false, true, true))
	v15_:addConfig(PlayerStyleConfig.new(v15_, "glasses", { PlayerStyleConfig.ENABLED_GETTER_FILTER, PlayerStyleConfig.SELECTED_GETTER_FILTER }, true))
	v15_:addConfig(PlayerStyleConfig.new(v15_, "headgear", { PlayerStyleConfig.ENABLED_GETTER_FILTER, PlayerStyleConfig.NOT_HIDDEN_GETTER_FILTER }))
	v15_:addConfig(PlayerStyleConfig.new(v15_, "facegear"))
	v15_:addConfig(PlayerStyleConfig.new(v15_, "face"))
	v15_:addConfig(PlayerStyleConfig.new(v15_, "beard", { PlayerStyleConfig.ENABLED_GETTER_FILTER, PlayerStyleConfig.BEARD_FACE_GETTER_FILTER }, false, false, true))
	v15_:addConfig(PlayerStyleConfig.new(v15_, "top", { PlayerStyleConfig.ENABLED_GETTER_FILTER, PlayerStyleConfig.NO_ONEPIECE_GETTER_FILTER }))
	v15_:addConfig(PlayerStyleConfig.new(v15_, "gloves", { PlayerStyleConfig.ENABLED_GETTER_FILTER, PlayerStyleConfig.NOT_HIDDEN_GETTER_FILTER }))
	v15_:addConfig(PlayerStyleConfig.new(v15_, "bottom", { PlayerStyleConfig.ENABLED_GETTER_FILTER, PlayerStyleConfig.NO_ONEPIECE_GETTER_FILTER }))
	v15_:addConfig(PlayerStyleConfig.new(v15_, "footwear", { PlayerStyleConfig.ENABLED_GETTER_FILTER }))
	v15_:addConfig(PlayerStyleConfig.new(v15_, "onepiece", { PlayerStyleConfig.ENABLED_GETTER_FILTER, PlayerStyleConfig.SELECTED_GETTER_FILTER }, true))
	v15_.configs.hairStyle:setSelectedColorIndex(v15_.configs.hairStyle:getSelectedColorIndex())
	v15_.configs.face.selectedItemIndex = 1
	v15_.configs.hairStyle.selectedItemIndex = 2
	return v15_
end

function PlayerStyle:delete() end

-- Local values: _, config
function PlayerStyle:writeStream(streamId, connection)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.xmlFilename))
	for _, v19_ in ipairs(self.orderedConfigs) do
		v19_:writeStream(streamId, connection)
	end
end

-- Local values: _, config
function PlayerStyle:readStream(streamId, connection)
	self.xmlFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
	self:loadConfigurationIfRequired()
	for _, v23_ in ipairs(self.orderedConfigs) do
		v23_:readStream(streamId, connection)
	end
	self:updateDisabledOptions()
	self.configs.hairStyle:setSelectedColorIndex(self.configs.hairStyle:getSelectedColorIndex())
end

function PlayerStyle:addConfig(config)
	self.configs[config.name] = config
	local v26_ = self.orderedConfigs
	table.insert(v26_, config)
end

-- Local values: configName, config
function PlayerStyle:copyFrom(other)
	if other == self then
		return
	else
		self.xmlFilename = other.xmlFilename
		self.filename = other.filename
		self.attachPoints = other.attachPoints
		for v29_, v30_ in pairs(other.configs) do
			self.configs[v29_]:copyConfigurationFrom(v30_)
			self.configs[v29_]:copySelectionFrom(v30_)
		end
		self.configs.hairStyle:setSelectedColorIndex(self.configs.hairStyle:getSelectedColorIndex())
		if other.isConfigurationLoaded then
			self.faceNeutralDiffuseColor = other.faceNeutralDiffuseColor
			self.bodyParts = other.bodyParts
			self.bodyPartIndexByName = other.bodyPartIndexByName
			self.hatHairstyleIndex = other.hatHairstyleIndex
			self.presets = other.presets
			self.presetsByName = other.presetsByName
			self.isConfigurationLoaded = true
			self:updateDisabledOptions()
		else
			self.isConfigurationLoaded = false
		end
	end
end

-- Local values: configName, config
function PlayerStyle:copyConfigurationFrom(other)
	if other == self then
		return
	elseif other.isConfigurationLoaded then
		self.xmlFilename = other.xmlFilename
		self.filename = other.filename
		self.hatHairstyleIndex = other.hatHairstyleIndex
		self.faceNeutralDiffuseColor = other.faceNeutralDiffuseColor
		self.attachPoints = other.attachPoints
		self.bodyParts = other.bodyParts
		self.bodyPartIndexByName = other.bodyPartIndexByName
		self.presets = other.presets
		self.presetsByName = other.presetsByName
		for v33_, v34_ in pairs(other.configs) do
			self.configs[v33_]:copyConfigurationFrom(v34_)
		end
		self.isConfigurationLoaded = true
		self:updateDisabledOptions()
	else
		Logging.error("Cannot copy configuration from style that has not yet loaded its own configuration!")
		printCallstack()
	end
end

-- Local values: configName, config
function PlayerStyle:copySelectionFrom(other)
	if other ~= self then
		local v37_
		if self.xmlFilename == other.xmlFilename then
			v37_ = self.isConfigurationLoaded
		else
			v37_ = false
		end
		self.isConfigurationLoaded = v37_
		self.xmlFilename = other.xmlFilename
		for v38_, v39_ in pairs(other.configs) do
			self.configs[v38_]:copySelectionFrom(v39_)
		end
		self.configs.hairStyle:setSelectedColorIndex(self.configs.hairStyle:getSelectedColorIndex())
	end
end

function PlayerStyle:loadConfigurationIfRequired()
	if not self.isConfigurationLoaded then
		self:loadConfigurationXML(self.xmlFilename)
	end
end

-- Local values: xmlFile, rootKey, _, key, nodeName, name, restoreFaceSelection, configName, baseKeyName, config, selectedItem, restoreSelectionName, restoreSelectionIndex, i, i, faceConfig, _, key, nodeName, name, i, presetKey, preset, isValid, configName, configData, itemName, config
function PlayerStyle:loadConfigurationXML(xmlFilename)
	local v43_ = Utils.getFilename(xmlFilename)
	if PlayerSystem.PLAYER_STYLES_BY_FILENAME[v43_] ~= nil then
		self:copyConfigurationFrom(PlayerSystem.PLAYER_STYLES_BY_FILENAME[v43_].style)
		return
	end
	local v44_ = XMLFile.loadIfExists("player", v43_, PlayerSystem.xmlSchema)
	if v44_ == nil then
		Logging.error("Player config does not exist at %s. Loading default instead", v43_)
		v43_ = next(PlayerSystem.PLAYER_STYLES_BY_FILENAME)
		v44_ = XMLFile.loadIfExists("player", v43_, PlayerSystem.xmlSchema)
		if v44_ == nil then
			Logging.fatal("Default player config does not exist at %s", v43_)
		end
	end
	self.xmlFilename = v43_
	self.filename = v44_:getValue("player.filename", nil)
	self.hairColors = PlayerStyle.loadColors(v44_, "player.playerStyle.colors.hair")
	self.defaultClothingColors = PlayerStyle.loadColors(v44_, "player.playerStyle.colors.clothing")
	table.clear(self.attachPoints)
	for _, v45_ in v44_:iterator("player.playerStyle.attachPoints.attachPoint") do
		local v46_ = v44_:getValue(v45_ .. "#node")
		local v47_ = v44_:getValue(v45_ .. "#name", v46_)
		self.attachPoints[v47_] = v46_
	end
	local v48_
	if self.configs.face.selectedItemIndex == 0 or self.configs.face:getSelectedItem() == nil then
		v48_ = nil
	else
		v48_ = self.configs.face:getSelectedItem().name
	end
	for v49_, _ in pairs(PlayerStyleConfig.CONFIG_BASE_KEY_NAMES_BY_NAME) do
		local v50_ = self.configs[v49_]
		local v51_ = v50_:getSelectedItem()
		local v52_
		if v51_ == nil then
			v52_ = nil
		else
			v52_ = v51_.name or nil
		end
		local v53_ = v50_.selectedItemIndex
		v50_:reset()
		v50_:loadFromXMLNode(v44_, "player.playerStyle", self.defaultClothingColors, self.hairColors, self.attachPoints)
		if v52_ == nil or v50_.itemsByName[v52_] == nil then
			if v53_ > 0 and v53_ <= #v50_.items then
				v50_:setSelectedItemIndex(v53_)
			end
		else
			v50_:setSelectedItemName(v52_)
		end
	end
	for v54_ = #self.configs.hairStyle.items, 1, -1 do
		if self.configs.hairStyle.items[v54_].forHat then
			self.hatHairstyleIndex = v54_
			break
		end
	end
	table.clear(self.facesByName)
	for _, v55_ in pairs(self.configs.face.items) do
		self.facesByName[v55_.name] = v55_
	end
	if v48_ ~= nil then
		self.configs.face:setSelectedItemName(v48_)
	end
	table.clear(self.bodyParts)
	table.clear(self.bodyPartIndexByName)
	for _, v56_ in v44_:iterator("player.playerStyle.bodyParts.bodyPart") do
		local v57_ = v44_:getValue(v56_ .. "#node")
		local v58_ = v44_:getValue(v56_ .. "#name", v57_)
		if self.bodyPartIndexByName[v58_] == nil then
			local v59_ = self.bodyParts
			table.insert(v59_, {
				["nodeName"] = v57_,
				["name"] = v58_
			})
			self.bodyPartIndexByName[v58_] = #self.bodyParts
		else
			Logging.devError("Wardrobe body part name \'%s\' already used, skipping!", v58_)
		end
	end
	table.clear(self.presets)
	table.clear(self.presetsByName)
	for _, v60_ in v44_:iterator("player.playerStyle.presets.preset") do
		local v61_ = PlayerStylePreset.new(self.xmlFilename)
		v61_:loadFromXMLNode(v44_, v60_)
		local v62_ = true
		for v63_, v64_ in pairs(v61_.configs) do
			local v65_ = v64_.selectionName
			local v66_ = self.configs[v63_]
			if v65_ ~= "keepCurrent" and v66_.itemsByName[v65_] == nil then
				Logging.xmlWarning(v44_, "Style preset with name \'%s\' uses item \'%s\' for \'%s\' which does not exist!", v61_.name, v65_, v63_)
				v62_ = false
			end
		end
		if v62_ then
			if self.presetsByName[v61_.name] == nil then
				local v67_ = self.presets
				table.insert(v67_, v61_)
				self.presetsByName[v61_.name] = v61_
			else
				Logging.xmlError(v44_, "Style preset with name \'%s\' has already been defined!", v61_.name)
			end
		end
	end
	self.isConfigurationLoaded = true
	v44_:delete()
end

-- Local values: colors, index, key, primary, color
function PlayerStyle.loadColors(xmlFile, rootKey)
	local v70_ = {}
	for _, v71_ in xmlFile:iterator(rootKey .. ".color") do
		local v72_ = Color.parseFromString(xmlFile:getValue(v71_ .. "#primary", nil))
		if v72_ ~= nil then
			local v73_ = {
				["primary"] = v72_,
				["secondary"] = Color.parseFromString(xmlFile:getValue(v71_ .. "#secondary", nil)),
				["isDefault"] = xmlFile:getValue(v71_ .. "#default", nil)
			}
			table.insert(v70_, v73_)
		end
	end
	return v70_
end

-- Local values: configName, config
function PlayerStyle:saveToXMLFile(xmlFile, key)
	xmlFile:setValue(key .. "#filename", self.xmlFilename)
	self:loadConfigurationIfRequired()
	for _, v77_ in pairs(self.configs) do
		v77_:saveToSavegame(xmlFile, key)
	end
end

-- Local values: xmlFilename, configName, config
function PlayerStyle:loadFromXMLFile(xmlFile, key)
	local v81_ = xmlFile:getValue(key .. "#filename")
	if string.isNilOrWhitespace(v81_) then
		Logging.xmlError(xmlFile, "Filename could not be read from %s!", key .. "#filename")
	end
	if PlayerSystem.PLAYER_STYLES_BY_FILENAME[v81_] == nil then
		Logging.xmlError(xmlFile, "PlayerStyle filename \'%s\' not available anymore!", v81_)
		return false
	end
	self.xmlFilename = v81_
	self:loadConfigurationIfRequired()
	for _, v82_ in pairs(self.configs) do
		v82_:loadFromSavegame(xmlFile, key)
	end
	self.configs.hairStyle:setSelectedColorIndex(self.configs.hairStyle:getSelectedColorIndex())
	return true
end

-- Local values: list, configName, config, item, onepieceItem
function PlayerStyle:getRequiredNodeFiles()
	local v84_ = {}
	if self.xmlFilename == nil then
		return v84_
	end
	self:loadConfigurationIfRequired()
	for _, v85_ in pairs(self.configs) do
		local v86_ = v85_:getSelectedItem()
		if v86_ ~= nil and not string.isNilOrWhitespace(v86_.filename) then
			local v87_ = v86_.filename
			table.insert(v84_, v87_)
		end
	end
	local v88_ = self.configs.onepiece:getSelectedItem()
	if self.hatHairstyleIndex ~= nil and (self.configs.headgear.selectedItemIndex ~= 0 or self.configs.onepiece.selectedItemIndex ~= 0 and v88_.disabledOptions.headgear) then
		local v89_ = self.configs.hairStyle.items[self.hatHairstyleIndex].filename
		table.insert(v84_, v89_)
	end
	return v84_
end

function PlayerStyle:getPresets()
	return self.presets
end

function PlayerStyle:getPresetByName(presetName)
	return self.presetsByName[presetName]
end

-- Local values: onepiece
function PlayerStyle:updateDisabledOptions()
	local v94_ = self.configs.onepiece:getSelectedItem()
	if v94_ == nil then
		self.disabledOptionsForSelection = {}
	else
		self.disabledOptionsForSelection = v94_.disabledOptions
	end
end

function PlayerStyle:convertSkinColorToScreenColor(r, g, b)
	return r * self.faceNeutralDiffuseColor.r, g * self.faceNeutralDiffuseColor.g, b * self.faceNeutralDiffuseColor.b
end

function PlayerStyle:getIsMale()
	return PlayerSystem.PLAYER_STYLES_BY_FILENAME[self.xmlFilename].gender == "male"
end

-- Local values: isHairStyleValid, isFaceValid, isOnepieceValid, isBottomValid, isTopValid, onepiece, needsFootwear, isFootwearValid, disabledOptions, configName, config, item, name, isDisabled, configName, disabledByConfigName, config
function PlayerStyle:isValid()
	if self.xmlFilename == nil then
		Logging.warning("PlayerStyle.isValid: Missing xmlFilename")
		return false
	end
	if self.configs.footwear.selectedItemIndex == 0 and self.configs.onepiece.selectedItemIndex > 0 then
		self:loadConfigurationIfRequired()
	end
	local v101_
	if self.configs.hairStyle.selectedItemIndex > 0 then
		v101_ = self.configs.hairStyle:getSelectedItem() ~= nil
	else
		v101_ = false
	end
	if not v101_ then
		Logging.warning("PlayerStyle.isValid: Missing hairstyle")
		return false
	end
	local v102_
	if self.configs.face.selectedItemIndex > 0 then
		v102_ = self.configs.face:getSelectedItem() ~= nil
	else
		v102_ = false
	end
	if not v102_ then
		Logging.warning("PlayerStyle.isValid: Missing face")
		return false
	end
	if self.configs.onepiece.selectedItemIndex > 0 then
		if self.configs.onepiece:getSelectedItem() == nil then
			Logging.warning("PlayerStyle.isValid: Missing onepiece")
			return false
		end
	else
		local v103_
		if self.configs.bottom.selectedItemIndex > 0 then
			v103_ = self.configs.bottom:getSelectedItem() ~= nil
		else
			v103_ = false
		end
		if not v103_ then
			Logging.warning("PlayerStyle.isValid: Missing bottom")
			return false
		end
		local v104_
		if self.configs.top.selectedItemIndex > 0 then
			v104_ = self.configs.top:getSelectedItem() ~= nil
		else
			v104_ = false
		end
		if not v104_ then
			Logging.warning("PlayerStyle.isValid: Missing top")
			return false
		end
	end
	local v105_ = self.configs.onepiece:getSelectedItem()
	local v106_ = v105_ == nil and true or not v105_.disabledOptions.footwear
	local v107_
	if self.configs.footwear.selectedItemIndex > 0 then
		v107_ = self.configs.footwear:getSelectedItem() ~= nil
	else
		v107_ = false
	end
	if v106_ and not v107_ then
		Logging.warning("PlayerStyle.isValid: Missing footwear")
		return false
	end
	local v108_ = {}
	for v109_, v110_ in pairs(self.configs) do
		local v111_ = v110_:getSelectedItem()
		if v111_ ~= nil then
			for v112_, v113_ in pairs(v111_.disabledOptions) do
				if v113_ then
					v108_[v112_] = v109_
				end
			end
		end
	end
	for v114_, v115_ in pairs(v108_) do
		local v116_ = self.configs[v114_]
		if v116_ ~= nil and (v116_.selectedItemIndex > 0 and v116_:getSelectedItem() ~= nil) then
			Logging.warning("PlayerStyle.isValid: \'%s\' is not allowed because it is disabled by \'%s\'!", v114_, v115_)
			return false
		end
	end
	return true
end

-- Local values: startX, configName, config
function PlayerStyle:debugDraw(x, y, textSize)
	local v121_ = DebugUtil.renderTextLine(x, y, textSize * 1.25, "Style", nil, true)
	local v122_ = DebugUtil.renderTextLine(x, v121_, textSize, string.format("Is loaded: %s", self.isConfigurationLoaded))
	if self.isConfigurationLoaded then
		v122_ = DebugUtil.renderTextLine(x, v122_, textSize, self.xmlFilename)
	end
	local v123_ = DebugUtil.renderTextLine(x, v122_, textSize, "Config name, item id, color id:")
	local v124_ = x
	for v125_, v126_ in pairs(self.configs) do
		DebugUtil.renderTextLine(x, v123_, textSize, string.format("%s: %d %d", string.sub(v125_, 1, 4), v126_.selectedItemIndex, v126_.selectedColorIndex))
		x = x + 80 * g_pixelSizeX
		if (x - v124_) / g_pixelSizeX > 250 then
			v123_ = v123_ - textSize
			x = v124_
		end
	end
	return v123_
end
