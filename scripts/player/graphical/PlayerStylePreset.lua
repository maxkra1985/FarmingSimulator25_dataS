PlayerStylePreset = {}
local PlayerStylePreset_mt = Class(PlayerStylePreset)
function PlayerStylePreset.registerXMLPaths(xmlSchema)
	local baseKey = "player.playerStyle.presets.preset(?)"
	xmlSchema:register(XMLValueType.STRING, "player.playerStyle.presets.preset(?)" .. "#name", "The name of the preset", nil, true)
	xmlSchema:register(XMLValueType.STRING, "player.playerStyle.presets.preset(?)" .. "#text", "The text of the preset", nil, true)
	xmlSchema:register(XMLValueType.STRING, "player.playerStyle.presets.preset(?)" .. "#brand", "The brand name of the preset", nil, false)
	xmlSchema:register(XMLValueType.STRING, "player.playerStyle.presets.preset(?)" .. "#iconFilename", "The icon filename of the preset", nil, true)
	xmlSchema:register(XMLValueType.BOOL, "player.playerStyle.presets.preset(?)" .. "#isSelectable", "True if this preset can be selected in the wardrobe; otherwise false", false, false)
	xmlSchema:register(XMLValueType.STRING, "player.playerStyle.presets.preset(?)" .. "#extraContentId", "The id of the extra content of this preset", nil, false)
	for configName, _ in pairs(PlayerStyleConfig.CONFIG_BASE_KEY_NAMES_BY_NAME) do
		xmlSchema:register(XMLValueType.STRING, "player.playerStyle.presets.preset(?)" .. "." .. configName .. "#name", "The name of the item", nil, false)
		xmlSchema:register(XMLValueType.INT, "player.playerStyle.presets.preset(?)" .. "." .. configName .. "#color", "The color index of the item", nil, false)
	end
end
function PlayerStylePreset.new(xmlFilename)
	local self = setmetatable({}, PlayerStylePreset_mt)
	self.xmlFilename = xmlFilename
	self.name = nil
	self.text = nil
	self.brandName = nil
	self.brand = nil
	self.iconFilename = nil
	self.isSelectable = nil
	self.extraContentId = nil
	self.configs = {}
	return self
end
function PlayerStylePreset:loadFromXMLNode(xmlFile, baseKey)
	self.name = xmlFile:getValue(baseKey .. "#name")
	self.text = xmlFile:getValue(baseKey .. "#text")
	self.isSelectable = xmlFile:getValue(baseKey .. "#isSelectable", true)
	if self.isSelectable then
		self.iconFilename = Utils.getFilename(xmlFile:getValue(baseKey .. "#iconFilename"), nil)
	end
	self.extraContentId = xmlFile:getValue(baseKey .. "#extraContentId")
	local brandName = xmlFile:getValue(baseKey .. "#brand", nil)
	if not string.isNilOrWhitespace(brandName) and g_brandManager ~= nil then
		self.brand = g_brandManager:getBrandByName(brandName)
		self.brandName = brandName
	end
	for configName, _ in pairs(PlayerStyleConfig.CONFIG_BASE_KEY_NAMES_BY_NAME) do
		local selectionName = xmlFile:getValue(baseKey .. "." .. configName .. "#name")
		if string.isNilOrWhitespace(selectionName) or selectionName == "none" then
			continue
		end
		self.configs[configName] = { selectionName = selectionName, selectionColorIndex = xmlFile:getValue(baseKey .. "." .. configName .. "#color") }
	end
end
function PlayerStylePreset.createFromStyle(playerStyle)
	local preset = PlayerStylePreset.new(playerStyle.xmlFilename)
	for configName, config in pairs(playerStyle.configs) do
		local presetConfig = preset.configs[configName]
		if presetConfig == nil then
			presetConfig = {}
			preset.configs[configName] = presetConfig
		end
		local selectedItem = config:getSelectedItem()
		if selectedItem == nil then
			continue
		end
		presetConfig.selectionName = selectedItem.name
		presetConfig.selectionColorIndex = config:getSelectedColorIndex()
	end
	return preset
end
function PlayerStylePreset:getDoesStyleUse(playerStyle)
	for configName, config in pairs(playerStyle.configs) do
		local presetConfig = self.configs[configName]
		if presetConfig == nil then
			continue
		end
		local selectedItem = config:getSelectedItem()
		if selectedItem == nil or presetConfig.selectionName ~= selectedItem.name then
			return false
		end
	end
	return true
end
function PlayerStylePreset:applyToStyle(playerStyle, forced)
	for configName, config in pairs(playerStyle.configs) do
		local presetConfig = self.configs[configName]
		if presetConfig ~= nil then
			if presetConfig.selectionName == "keepCurrent" then
				continue
			end
			config:setSelectedItemName(presetConfig.selectionName, forced)
			config:setSelectedColorIndex(presetConfig.selectionColorIndex)
		else
			if config.isHair or configName == "face" then
				continue
			end
			config:setSelectedItemIndex(0)
		end
	end
	playerStyle:updateDisabledOptions()
end
