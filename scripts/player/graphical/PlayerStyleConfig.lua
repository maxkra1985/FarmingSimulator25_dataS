-- Local values: PlayerStyleConfig_mt
PlayerStyleConfig = {}
local PlayerStyleConfig_mt = Class(PlayerStyleConfig)
PlayerStyleConfig.CONFIG_BASE_KEY_NAMES_BY_NAME = {
	["hairStyle"] = ".hairStyles",
	["glasses"] = ".glasses",
	["headgear"] = ".headgear",
	["facegear"] = ".facegear",
	["face"] = ".faces",
	["beard"] = ".beards",
	["top"] = ".tops",
	["gloves"] = ".gloves",
	["bottom"] = ".bottoms",
	["footwear"] = ".footwear",
	["onepiece"] = ".onepieces"
}

function PlayerStyleConfig:ENABLED_GETTER_FILTER(index)
	return not self.playerStyle.disabledOptionsForSelection[self.name]
end

function PlayerStyleConfig:NOT_HIDDEN_GETTER_FILTER(index, gear)
	return not gear.hidden
end

function PlayerStyleConfig:NOT_FOR_HAT_GETTER_FILTER(index, hair)
	return not hair.forHat
end

function PlayerStyleConfig:SELECTED_GETTER_FILTER(index)
	return self.selectedItemIndex == index
end

function PlayerStyleConfig:NO_ONEPIECE_GETTER_FILTER(index)
	return self.playerStyle.configs.onepiece.selectedItemIndex == 0
end

function PlayerStyleConfig:BEARD_FACE_GETTER_FILTER(index, beard)
	local v10_
	if beard.faceName == nil then
		v10_ = true
	elseif self.playerStyle.configs.face:getSelectedItem() == nil then
		v10_ = false
	else
		v10_ = beard.faceName == self.playerStyle.configs.face:getSelectedItem().name
	end
	return v10_
end

-- Local values: itemName, baseKeyName
function PlayerStyleConfig.registerXMLPaths(xmlSchema)
	for v12_, v13_ in pairs(PlayerStyleConfig.CONFIG_BASE_KEY_NAMES_BY_NAME) do
		xmlSchema:register(XMLValueType.FILENAME, "player.playerStyle" .. v13_ .. "#nullIconFilename", "The icon filename to use when nothing is selected", nil, false)
		PlayerStyle.regsterIconGenerationXMLPaths(xmlSchema, "player.playerStyle" .. v13_)
		PlayerStyleItem.registerXMLPaths(xmlSchema, "player.playerStyle" .. v13_, v12_)
	end
end

function PlayerStyleConfig.registerSavegameXMLPaths(savegameXMLSchema, baseKey, configName)
	local v17_ = baseKey .. "." .. configName
	savegameXMLSchema:register(XMLValueType.STRING, v17_ .. "#name", "The name of the config item", nil, false)
	savegameXMLSchema:register(XMLValueType.INT, v17_ .. "#color", "The name of the config item color", nil, false)
end

-- Upvalues: PlayerStyleConfig_mt
-- Local values: self
function PlayerStyleConfig.new(playerStyle, name, getterFilters, getterOr, resetSelectionToOne, isHair)
	-- upvalues: (copy) PlayerStyleConfig_mt
	local v24_ = PlayerStyleConfig_mt
	local v25_ = setmetatable({}, v24_)
	v25_.playerStyle = playerStyle
	v25_.name = name
	v25_.items = {}
	v25_.itemsByName = {}
	v25_.selectedItemIndex = 0
	v25_.selectedColorIndex = 1
	v25_.getterFilters = getterFilters or {}
	v25_.getterOr = getterOr == true
	v25_.resetSelectionToOne = resetSelectionToOne == true
	v25_.isHair = isHair == true
	return v25_
end

-- Local values: itemBaseKey, i, itemKey, item, nullIconFilename, emptyItem
function PlayerStyleConfig:loadFromXMLNode(xmlFile, baseKey, defaultClothingColors, hairColors, attachmentPoints)
	local v32_ = baseKey .. PlayerStyleConfig.CONFIG_BASE_KEY_NAMES_BY_NAME[self.name]
	for _, v33_ in xmlFile:iterator(v32_ .. "." .. self.name) do
		local v34_ = PlayerStyleItem.new()
		v34_:loadFromConfigurationXMLFile(xmlFile, v33_, self.isHair and hairColors and hairColors or defaultClothingColors, attachmentPoints, self.isHair)
		self:addItem(v34_)
	end
	local v35_ = xmlFile:getValue(v32_ .. "#nullIconFilename", nil)
	if v35_ ~= nil then
		local v36_ = PlayerStyleItem.newEmpty(v35_)
		self.items[0] = v36_
		self.itemsByName[v36_.name] = v36_
	end
end

-- Local values: selectedItem
function PlayerStyleConfig:saveToSavegame(xmlFile, baseKey)
	local v40_ = baseKey .. "." .. self.name
	xmlFile:setValue(v40_ .. "#color", self.selectedColorIndex)
	local v41_ = self:getSelectedItem()
	if v41_ == nil then
		xmlFile:removeProperty(v40_ .. "#name")
	else
		xmlFile:setValue(v40_ .. "#name", v41_.name)
	end
end

-- Local values: selectedItemName
function PlayerStyleConfig:loadFromSavegame(xmlFile, baseKey)
	local v45_ = baseKey .. "." .. self.name
	self.selectedColorIndex = xmlFile:getValue(v45_ .. "#color", 1)
	self.selectedItemIndex = 0
	local v46_ = xmlFile:getValue(v45_ .. "#name", nil)
	if not string.isNilOrWhitespace(v46_) then
		self.selectedItemIndex = self:getItemNameIndex(v46_)
		if self.selectedItemIndex == nil then
			Logging.xmlWarning(xmlFile, "Saved style item with name of %s could not be found!", v46_)
			self.selectedItemIndex = self.resetSelectionToOne and 1 or 0
		end
	end
end

function PlayerStyleConfig:reset()
	table.clear(self.items)
	table.clear(self.itemsByName)
	self.selectedColorIndex = 1
	self.selectedItemIndex = self.resetSelectionToOne and 1 or 0
end

function PlayerStyleConfig:writeStream(streamId, connection)
	streamWriteUInt8(streamId, self.selectedItemIndex)
	streamWriteUInt8(streamId, self.selectedColorIndex)
end

function PlayerStyleConfig:readStream(streamId, connection)
	self.selectedItemIndex = streamReadUInt8(streamId)
	self.selectedColorIndex = streamReadUInt8(streamId)
end

function PlayerStyleConfig:addItem(item)
	local v54_ = self.items
	table.insert(v54_, item)
	self.itemsByName[item.name] = item
end

-- Local values: _, item
function PlayerStyleConfig:copyConfigurationFrom(other)
	table.clear(self.items)
	table.clear(self.itemsByName)
	if other.items[0] ~= nil then
		self.items[0] = other.items[0]
		self.itemsByName[self.items[0].name] = self.items[0]
	end
	for _, v57_ in ipairs(other.items) do
		self:addItem(v57_)
	end
end

function PlayerStyleConfig:copySelectionFrom(other)
	self.selectedItemIndex = other.selectedItemIndex
	self.selectedColorIndex = other.selectedColorIndex
end

-- Local values: item
function PlayerStyleConfig:getItemNameIndex(itemName)
	if string.isNilOrWhitespace(itemName) then
		return nil
	else
		local v62_ = self.itemsByName[itemName]
		if v62_ == nil then
			return nil
		else
			return self:getItemIndex(v62_)
		end
	end
end

function PlayerStyleConfig:getItemIndex(item)
	if item == nil then
		return nil
	else
		return item == self.items[0] and 0 or table.find(self.items, item)
	end
end

function PlayerStyleConfig:getSelectedItem()
	return self.items[self.selectedItemIndex]
end

-- Local values: index
function PlayerStyleConfig:setSelectedItem(item, forced)
	self:setSelectedItemIndex(self:getItemIndex(item), forced)
end

-- Local values: item, index
function PlayerStyleConfig:setSelectedItemName(name, forced)
	self:setSelectedItemIndex(self:getItemIndex(self.itemsByName[name]), forced)
end

-- Local values: oldItem, configName, newItem, configName
function PlayerStyleConfig:setSelectedItemIndex(index, forced)
	if index == nil then
		return
	elseif self.selectedItemIndex ~= index or forced then
		local v75_ = self:getSelectedItem()
		self.selectedItemIndex = index
		if v75_ ~= nil and v75_.hasDisabledItems then
			for v76_ in pairs(v75_.disabledOptions) do
				if string.isNilOrWhitespace(v76_) or self.playerStyle.configs[v76_] == nil then
					Logging.error("Item %s defines a disabled config %s, which does not correspond to any config!", v75_.name, v76_)
				elseif self.playerStyle.configs[v76_].selectedItemIndex == 0 then
					self.playerStyle.configs[v76_]:setSelectedItemIndex(1)
				end
			end
			self.playerStyle:updateDisabledOptions()
		end
		local v77_ = self:getSelectedItem()
		if v77_ ~= nil then
			if v77_.colorableSlots > 0 and v77_.defaultPrimaryColorIndex ~= nil then
				self:setSelectedColorIndex(v77_.defaultPrimaryColorIndex)
			end
			if v77_.hasDisabledItems then
				for v78_ in pairs(v77_.disabledOptions) do
					if string.isNilOrWhitespace(v78_) or self.playerStyle.configs[v78_] == nil then
						Logging.error("Item %s defines a disabled config %s, which does not correspond to any config!", v77_.name, v78_)
					else
						self.playerStyle.configs[v78_]:setSelectedItemIndex(0)
					end
				end
				self.playerStyle:updateDisabledOptions()
			end
		end
	end
end

function PlayerStyleConfig:getSelectedColorIndex()
	return self.selectedColorIndex
end

-- Local values: item
function PlayerStyleConfig:getSelectedColor()
	return self:getSelectedItem().possibleColors[self.selectedColorIndex]
end

-- Local values: _, config
function PlayerStyleConfig:setSelectedColorIndex(index)
	if index == nil then
		return
	elseif self.isHair then
		for _, v83_ in pairs(self.playerStyle.configs) do
			if v83_.isHair then
				v83_.selectedColorIndex = index
			end
		end
	else
		self.selectedColorIndex = index
	end
end

-- Local values: possible, index, item
function PlayerStyleConfig:getPossibleItemIndices()
	local v85_ = {}
	for v86_, v87_ in ipairs(self.items) do
		if self:calculateGetterFiltersPassFor(v86_, v87_) then
			table.insert(v85_, v86_)
		end
	end
	return v85_
end

-- Local values: count, index, item
function PlayerStyleConfig:getPossibleItemsCount()
	local v89_ = 0
	for v90_, v91_ in ipairs(self.items) do
		if self:calculateGetterFiltersPassFor(v90_, v91_) then
			v89_ = v89_ + 1
		end
	end
	return v89_
end

-- Local values: includeItem, _, filterFunction, filterSucceeded
function PlayerStyleConfig:calculateGetterFiltersPassFor(index, item)
	local v95_ = #self.getterFilters == 0 and true or not self.getterOr
	for _, v96_ in ipairs(self.getterFilters) do
		local v97_ = v96_(self, index, item)
		if self.getterOr and v97_ then
			return true
		end
		if not (self.getterOr or v97_) then
			return false
		end
	end
	return v95_
end

function PlayerStyleConfig:cloneAndEnableSelection(modelParts, skeleton, i3dMappings, extentToCompare, extentToCompare2)
	return self:cloneAndEnableItemIndex(self.selectedItemIndex, modelParts, skeleton, i3dMappings, extentToCompare, extentToCompare2)
end

-- Local values: item, itemNode, itemNode2
function PlayerStyleConfig:cloneAndEnableItemIndex(index, modelParts, skeleton, i3dMappings, extentToCompare, extentToCompare2)
	local v111_ = self.items[index]
	if v111_ == nil or string.isNilOrWhitespace(v111_.filename) then
		Logging.warning("Index %d for config style item %q does not exist in %q!", index, self.name, self.playerStyle.xmlFilename)
		return nil, nil
	end
	local v112_, v113_ = v111_:cloneAndEnable(modelParts, skeleton, i3dMappings, extentToCompare, extentToCompare2)
	if self.isHair then
		v111_:applyColorToHair(v112_, v113_, self.selectedColorIndex)
		return v112_, v113_
	end
	v111_:applyColorToNode(v112_, self.selectedColorIndex)
	if v113_ ~= nil then
		v111_:applyColorToNode(v113_, self.selectedColorIndex)
	end
	return v112_, v113_
end
