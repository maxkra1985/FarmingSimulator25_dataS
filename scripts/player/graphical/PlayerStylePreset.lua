-- Local values: PlayerStylePreset_mt
PlayerStylePreset = {}
local PlayerStylePreset_mt = Class(PlayerStylePreset)

-- Local values: baseKey, configName, _
function PlayerStylePreset.registerXMLPaths(xmlSchema)
	xmlSchema:register(XMLValueType.STRING, "player.playerStyle.presets.preset(?)#name", "The name of the preset", nil, true)
	xmlSchema:register(XMLValueType.STRING, "player.playerStyle.presets.preset(?)#text", "The text of the preset", nil, true)
	xmlSchema:register(XMLValueType.STRING, "player.playerStyle.presets.preset(?)#brand", "The brand name of the preset", nil, false)
	xmlSchema:register(XMLValueType.STRING, "player.playerStyle.presets.preset(?)#iconFilename", "The icon filename of the preset", nil, true)
	xmlSchema:register(XMLValueType.BOOL, "player.playerStyle.presets.preset(?)#isSelectable", "True if this preset can be selected in the wardrobe; otherwise false", false, false)
	xmlSchema:register(XMLValueType.STRING, "player.playerStyle.presets.preset(?)#extraContentId", "The id of the extra content of this preset", nil, false)
	for v3_, _ in pairs(PlayerStyleConfig.CONFIG_BASE_KEY_NAMES_BY_NAME) do
		xmlSchema:register(XMLValueType.STRING, "player.playerStyle.presets.preset(?)" .. "." .. v3_ .. "#name", "The name of the item", nil, false)
		xmlSchema:register(XMLValueType.INT, "player.playerStyle.presets.preset(?)" .. "." .. v3_ .. "#color", "The color index of the item", nil, false)
	end
end

-- Upvalues: PlayerStylePreset_mt
-- Local values: self
function PlayerStylePreset.new(xmlFilename)
	-- upvalues: (copy) PlayerStylePreset_mt
	local v5_ = PlayerStylePreset_mt
	local v6_ = setmetatable({}, v5_)
	v6_.xmlFilename = xmlFilename
	v6_.name = nil
	v6_.text = nil
	v6_.brandName = nil
	v6_.brand = nil
	v6_.iconFilename = nil
	v6_.isSelectable = nil
	v6_.extraContentId = nil
	v6_.configs = {}
	return v6_
end

-- Local values: brandName, configName, _, selectionName
function PlayerStylePreset:loadFromXMLNode(xmlFile, baseKey)
	self.name = xmlFile:getValue(baseKey .. "#name")
	self.text = xmlFile:getValue(baseKey .. "#text")
	self.isSelectable = xmlFile:getValue(baseKey .. "#isSelectable", true)
	if self.isSelectable then
		self.iconFilename = Utils.getFilename(xmlFile:getValue(baseKey .. "#iconFilename"), nil)
	end
	self.extraContentId = xmlFile:getValue(baseKey .. "#extraContentId")
	local v10_ = xmlFile:getValue(baseKey .. "#brand", nil)
	if not string.isNilOrWhitespace(v10_) and g_brandManager ~= nil then
		self.brand = g_brandManager:getBrandByName(v10_)
		self.brandName = v10_
	end
	for v11_, _ in pairs(PlayerStyleConfig.CONFIG_BASE_KEY_NAMES_BY_NAME) do
		local v12_ = xmlFile:getValue(baseKey .. "." .. v11_ .. "#name")
		if not string.isNilOrWhitespace(v12_) and v12_ ~= "none" then
			self.configs[v11_] = {
				["selectionName"] = v12_,
				["selectionColorIndex"] = xmlFile:getValue(baseKey .. "." .. v11_ .. "#color")
			}
		end
	end
end

-- Local values: preset, configName, config, presetConfig, selectedItem
function PlayerStylePreset.createFromStyle(playerStyle)
	local v14_ = PlayerStylePreset.new(playerStyle.xmlFilename)
	for v15_, v16_ in pairs(playerStyle.configs) do
		local v17_ = v14_.configs[v15_]
		if v17_ == nil then
			v17_ = {}
			v14_.configs[v15_] = v17_
		end
		local v18_ = v16_:getSelectedItem()
		if v18_ ~= nil then
			v17_.selectionName = v18_.name
			v17_.selectionColorIndex = v16_:getSelectedColorIndex()
		end
	end
	return v14_
end

-- Local values: configName, config, presetConfig, selectedItem
function PlayerStylePreset:getDoesStyleUse(playerStyle)
	for v21_, v22_ in pairs(playerStyle.configs) do
		local v23_ = self.configs[v21_]
		if v23_ ~= nil then
			local v24_ = v22_:getSelectedItem()
			if v24_ == nil or v23_.selectionName ~= v24_.name then
				return false
			end
		end
	end
	return true
end

-- Local values: configName, config, presetConfig
function PlayerStylePreset:applyToStyle(playerStyle, forced)
	for v28_, v29_ in pairs(playerStyle.configs) do
		local v30_ = self.configs[v28_]
		if v30_ == nil then
			if not v29_.isHair and v28_ ~= "face" then
				v29_:setSelectedItemIndex(0)
			end
		elseif v30_.selectionName ~= "keepCurrent" then
			v29_:setSelectedItemName(v30_.selectionName, forced)
			v29_:setSelectedColorIndex(v30_.selectionColorIndex)
		end
	end
	playerStyle:updateDisabledOptions()
end
