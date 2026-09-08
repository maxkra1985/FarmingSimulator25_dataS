-- Local values: ExtraContentSystem_mt
ExtraContentSystem = {}
ExtraContentSystem.PROFILE_FILENAME = "extraContent.xml"
ExtraContentSystem.VALID_CHARS_STRING = "ABCDEFHJKLMNPQRSTWXYZ123456789"
ExtraContentSystem.VALID_CHARS_PATTERN = "[" .. ExtraContentSystem.VALID_CHARS_STRING .. "]"
ExtraContentSystem.VALID_CHARS_NOT_PATTERN = "[^" .. ExtraContentSystem.VALID_CHARS_STRING .. "]"
ExtraContentSystem.VALID_CHARS = string.split(ExtraContentSystem.VALID_CHARS_STRING, "")
ExtraContentSystem.KEY_LENGTH = 8
ExtraContentSystem.NUM_ITEM_CHARACTERS = 3
ExtraContentSystem.ITEM_INDEX_1 = 1
ExtraContentSystem.ITEM_INDEX_2 = 4
ExtraContentSystem.ITEM_INDEX_3 = 6
ExtraContentSystem.UNLOCKED = 0
ExtraContentSystem.ERROR_KEY_INVALID = 1
ExtraContentSystem.ERROR_ALREADY_UNLOCKED = 2
ExtraContentSystem.ERROR_KEY_INVALID_FORMAT = 3
local ExtraContentSystem_mt = Class(ExtraContentSystem)

-- Upvalues: ExtraContentSystem_mt
-- Local values: self
function ExtraContentSystem.new(mission, customMt)
	-- upvalues: (copy) ExtraContentSystem_mt
	local v3_ = customMt or ExtraContentSystem_mt
	local v4_ = setmetatable({}, v3_)
	v4_.items = {}
	v4_.idToItem = {}
	if g_isDevelopmentVersion then
		addConsoleCommand("gsExtraContentSystemCreateKeys", "Create keys for a given item code", "consoleCommandCreateKeys", v4_)
		addConsoleCommand("gsExtraContentSystemCreateKeysAll", "Create keys for all items", "consoleCommandCreateKeysAll", v4_)
		addConsoleCommand("gsExtraContentSystemUnlockAll", "Unlocks all items", "consoleCommandUnlockAll", v4_)
		return v4_
	end
	ExtraContentSystem.consoleCommandCreateKeys = nil
	ExtraContentSystem.consoleCommandCreateKeysAll = nil
	ExtraContentSystem.consoleCommandUnlockAll = nil
	ExtraContentSystem.createKeyItem = nil
	v4_.consoleCommandCreateKeys = nil
	v4_.consoleCommandCreateKeysAll = nil
	v4_.consoleCommandUnlockAll = nil
	v4_.createKeyItem = nil
	return v4_
end

function ExtraContentSystem:delete()
	self.items = {}
	self.idToItem = {}
	removeConsoleCommand("gsExtraContentSystemCreateKeys")
	removeConsoleCommand("gsExtraContentSystemCreateKeysAll")
	removeConsoleCommand("gsExtraContentSystemUnlockAll")
end

-- Local values: xmlFile
function ExtraContentSystem:loadFromXML(xmlFilename)
	local v_u_8_ = XMLFile.load("extraContentSystem", xmlFilename, nil)
	if v_u_8_ ~= nil then
		v_u_8_:iterate("extraContent.item", function(_, p9_)
			-- upvalues: (copy) v_u_8_, (copy) self
			local v10_ = v_u_8_:getString(p9_ .. "#id")
			local v11_ = v_u_8_:getString(p9_ .. "#code")
			local v12_ = v_u_8_:getString(p9_ .. ".title")
			local v13_ = v_u_8_:getString(p9_ .. ".description")
			local v14_ = v_u_8_:getString(p9_ .. ".imageFilename")
			local v15_ = v_u_8_:getBool(p9_ .. "#isAutoUnlocked", false)
			if v10_ == nil then
				Logging.xmlWarning(v_u_8_, "Extra content item id is missing for \'%s\'", p9_)
				return
			elseif v11_ == nil then
				Logging.xmlWarning(v_u_8_, "Extra content item code is missing for \'%s\'", p9_)
				return
			else
				local v16_ = string.upper(v11_)
				local v17_, v18_ = self:getStringHasValidCharacters(v16_)
				if v17_ then
					local v19_ = string.split(v16_, "")
					if #v19_ == ExtraContentSystem.NUM_ITEM_CHARACTERS then
						if v14_ == nil then
							Logging.xmlWarning(v_u_8_, "Extra content item imageFilename is missing for \'%s\'", p9_)
							return
						elseif v12_ == nil then
							Logging.xmlWarning(v_u_8_, "Extra content item title is missing for \'%s\'", p9_)
							return
						elseif v13_ == nil then
							Logging.xmlWarning(v_u_8_, "Extra content item description is missing for \'%s\'", p9_)
						else
							self:addItem(v10_, g_i18n:convertText(v12_), g_i18n:convertText(v13_), v14_, v19_, v15_)
						end
					else
						Logging.xmlWarning(v_u_8_, "Extra content item code needs to have %d characters for \'%s\'", ExtraContentSystem.NUM_ITEM_CHARACTERS, p9_)
						return
					end
				else
					Logging.xmlWarning(v_u_8_, "Extra content item code contains invalid charater \'%s\' for \'%s\'!", v18_, p9_)
					return
				end
			end
		end)
		v_u_8_:delete()
	end
end

-- Local values: code, alreadyExists, _, existingItem, k, existingChar, item
function ExtraContentSystem:addItem(id, title, description, imageFilename, charList, isAutoUnlocked)
	if self.idToItem[id] ~= nil then
		Logging.warning("Extra content item with id \'%s\' already exists!", id)
		return
	end
	table.sort(charList, function(p27_, p28_)
		return p27_ < p28_
	end)
	local v29_ = table.concat(charList, "")
	local v30_ = true
	for _, v31_ in ipairs(self.items) do
		for v32_, v33_ in ipairs(v31_.charList) do
			if v33_ ~= charList[v32_] then
				v30_ = false
				break
			end
		end
	end
	if #self.items > 0 and v30_ then
		Logging.warning("Extra content code for \'%s\' is already used!", id)
	else
		local v34_ = {
			["id"] = id,
			["title"] = title,
			["description"] = description,
			["imageFilename"] = imageFilename,
			["charList"] = charList,
			["code"] = v29_,
			["isAutoUnlocked"] = isAutoUnlocked,
			["isUnlocked"] = false,
			["unlockedByDLC"] = false
		}
		local v35_ = self.items
		table.insert(v35_, v34_)
		self.idToItem[id] = v34_
	end
end

-- Local values: xmlFilename, hasChanges, xmlFile
function ExtraContentSystem:loadFromProfile()
	local v37_ = getUserProfileAppPath() .. ExtraContentSystem.PROFILE_FILENAME
	if fileExists(v37_) then
		local v_u_38_ = false
		local v_u_39_ = XMLFile.load("extraContentProfile", v37_, nil)
		if v_u_39_ ~= nil then
			v_u_39_:iterate("extraContent.usedKey", function(_, p40_)
				-- upvalues: (copy) v_u_39_, (ref) v_u_38_, (copy) self
				local v41_ = v_u_39_:getString(p40_)
				local v42_ = v_u_39_:getBool(p40_ .. "#unlockedByDLC")
				if v42_ == nil then
					v_u_38_ = true
				end
				if v41_ ~= nil and v42_ == false then
					local v43_, _ = self:unlockItem(v41_, v42_)
					if v43_ ~= nil then
						print("Extra Content: Unlocked \'" .. v43_.id .. "\'")
					end
				end
			end)
			v_u_39_:delete()
		end
		if v_u_38_ then
			self:saveToProfile()
		end
	end
end

-- Local values: filename, xmlFile, i, _, item
function ExtraContentSystem:saveToProfile()
	local v45_ = getUserProfileAppPath() .. ExtraContentSystem.PROFILE_FILENAME
	local v46_ = XMLFile.create("extraContentProfile", v45_, "extraContent", nil)
	local v47_ = 0
	for _, v48_ in ipairs(self.items) do
		if v48_.isUnlocked and v48_.usedKey ~= nil then
			v46_:setString(string.format("extraContent.usedKey(%d)", v47_), v48_.usedKey)
			v46_:setBool(string.format("extraContent.usedKey(%d)#unlockedByDLC", v47_), Utils.getNoNil(v48_.unlockedByDLC, false))
			v47_ = v47_ + 1
		end
	end
	v46_:save()
	v46_:delete()
	syncProfileFiles()
end

-- Local values: _, item
function ExtraContentSystem:reset()
	for _, v50_ in ipairs(self.items) do
		v50_.isUnlocked = false
		v50_.unlockedByDLC = false
		v50_.usedKey = nil
	end
end

-- Local values: isValid, _, charList, itemChars, foundItem, lastChar, checksumChar
function ExtraContentSystem:getItemByKey(key)
	if key == nil or utf8Strlen(key) ~= ExtraContentSystem.KEY_LENGTH then
		return nil, ExtraContentSystem.ERROR_KEY_INVALID_FORMAT
	else
		local v53_, _ = self:getStringHasValidCharacters(key)
		if v53_ then
			local v54_ = string.split(key, "")
			if #v54_ == ExtraContentSystem.KEY_LENGTH then
				local v55_ = { v54_[ExtraContentSystem.ITEM_INDEX_1], v54_[ExtraContentSystem.ITEM_INDEX_2], v54_[ExtraContentSystem.ITEM_INDEX_3] }
				table.sort(v55_, function(p56_, p57_)
					return p56_ < p57_
				end)
				local v58_ = self:getItemByCode(v55_)
				if v58_ == nil then
					return nil, ExtraContentSystem.ERROR_KEY_INVALID
				elseif v54_[ExtraContentSystem.KEY_LENGTH] == self:getChecksumChar(v54_) then
					return v58_
				else
					return nil, ExtraContentSystem.ERROR_KEY_INVALID
				end
			else
				return nil, ExtraContentSystem.ERROR_KEY_INVALID_FORMAT
			end
		else
			return nil, ExtraContentSystem.ERROR_KEY_INVALID
		end
	end
end

-- Local values: foundItem, _, item, found, k, char
function ExtraContentSystem:getItemByCode(charList)
	local v61_ = nil
	for _, v62_ in ipairs(self.items) do
		local v63_ = true
		for v64_, v65_ in ipairs(v62_.charList) do
			if v65_ ~= charList[v64_] then
				v63_ = false
				break
			end
		end
		if v63_ then
			return v62_
		end
	end
	return v61_
end

-- Local values: item, errorCode
function ExtraContentSystem:unlockItem(key, unlockedByDLC)
	local v69_, v70_ = self:getItemByKey(key)
	if v69_ == nil then
		return nil, v70_
	end
	if v69_.isUnlocked then
		return v69_, ExtraContentSystem.ERROR_ALREADY_UNLOCKED
	end
	v69_.isUnlocked = true
	v69_.usedKey = key
	v69_.unlockedByDLC = unlockedByDLC
	self:saveToProfile()
	return v69_, ExtraContentSystem.UNLOCKED
end

-- Local values: item
function ExtraContentSystem:getIsItemIdUnlocked(id)
	local v73_ = self.idToItem[id]
	if v73_ ~= nil then
		return self:getIsItemUnlocked(v73_)
	end
	Logging.warning("ExtraContent item \'%s\' does not exist!", (tostring(id)))
	return false
end

function ExtraContentSystem:getIsItemUnlocked(item)
	if item == nil then
		return false
	else
		return item.isAutoUnlocked and true or item.isUnlocked
	end
end

-- Local values: unlockedItems, _, item
function ExtraContentSystem:getUnlockedItems()
	local v76_ = {}
	for _, v77_ in ipairs(self.items) do
		if self:getIsItemUnlocked(v77_) then
			table.insert(v76_, v77_)
		end
	end
	return v76_
end

-- Local values: _, item
function ExtraContentSystem:getHasLockedItems()
	for _, v79_ in ipairs(self.items) do
		if not self:getIsItemUnlocked(v79_) then
			return true
		end
	end
	return false
end

-- Local values: res
function ExtraContentSystem:getStringHasValidCharacters(text)
	local v81_ = text:match(ExtraContentSystem.VALID_CHARS_NOT_PATTERN)
	return v81_ == nil, v81_
end

-- Local values: sum, i, char, char
function ExtraContentSystem:getChecksumChar(charList)
	local v83_ = 0
	for _ = 1, ExtraContentSystem.KEY_LENGTH - 1 do
		local v84_ = charList[1]
		v83_ = v83_ + string.byte(v84_)
	end
	local v85_ = v83_ % #ExtraContentSystem.VALID_CHARS + 1
	return ExtraContentSystem.VALID_CHARS[v85_]
end

-- Local values: _, item, itemChars, key
function ExtraContentSystem:consoleCommandUnlockAll()
	for _, v87_ in ipairs(self.items) do
		self:unlockItem((self:createItemKey(v87_, (table.copyIndex(v87_.charList)))))
	end
end

-- Local values: _, item, itemChars, generatedKeys, numGeneratedKeys, key
function ExtraContentSystem:consoleCommandCreateKeysAll(numKeys)
	local v90_ = tonumber(numKeys) or 1
	setFileLogPrefixTimestamp(false)
	for _, v91_ in ipairs(self.items) do
		print(string.format("Generating keys for item \'%s\':", g_i18n:convertText(v91_.title)))
		local v92_ = table.copyIndex(v91_.charList)
		local v93_ = v90_
		local v94_ = {}
		while v90_ > 0 do
			local v95_ = self:createItemKey(v91_, v92_)
			if v95_ == nil then
				return
			end
			if v94_[v95_] == nil then
				print("    " .. v95_)
				v94_[v95_] = true
				v90_ = v90_ - 1
			end
		end
		v90_ = v93_
	end
	setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
	return "Finished"
end

-- Local values: generatedKeys, xmlFile, i, isValid, _, itemChars, foundItem, key
function ExtraContentSystem:consoleCommandCreateKeys(itemCode, numKeys, file)
	local v100_ = tonumber(numKeys) or 1
	if itemCode == nil then
		return "Invalid item code"
	end
	local v_u_101_ = {}
	if file ~= nil then
		local v_u_102_ = XMLFile.load("keys", file)
		if v_u_102_ == nil then
			return "Could not load given existing key file"
		end
		local v_u_103_ = 0
		v_u_102_:iterate("keys.key", function(_, p104_)
			-- upvalues: (copy) v_u_102_, (copy) v_u_101_, (ref) v_u_103_
			local v105_ = v_u_102_:getString(p104_)
			if v105_ ~= nil then
				v_u_101_[string.trim(v105_)] = true
				v_u_103_ = v_u_103_ + 1
			end
		end)
		print(string.format("Loaded %d existing keys from file...", v_u_103_))
	end
	local v106_ = string.upper(itemCode)
	local v107_, _ = self:getStringHasValidCharacters(v106_)
	if not v107_ then
		return "Invalid item code"
	end
	local v108_ = string.split(v106_, "")
	if #v108_ ~= ExtraContentSystem.NUM_ITEM_CHARACTERS then
		return "Invalid item code"
	end
	table.sort(v108_, function(p109_, p110_)
		return p109_ < p110_
	end)
	local v111_ = self:getItemByCode(v108_)
	if v111_ == nil then
		return "Item not found in extra content system"
	end
	setFileLogPrefixTimestamp(false)
	print(string.format("Generating keys for item \'%s\':", g_i18n:convertText(v111_.title)))
	while v100_ > 0 do
		local v112_ = self:createItemKey(v111_, v108_)
		if v112_ == nil then
			return
		end
		if v_u_101_[v112_] == nil then
			print("    " .. v112_)
			v_u_101_[v112_] = true
			v100_ = v100_ - 1
		end
	end
	setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
	return "Finished"
end

-- Local values: numChars, keyChars, i, charIndex, char, checksumChar, key, foundItem, errorCode
function ExtraContentSystem:createItemKey(item, itemChars)
	local v116_ = #ExtraContentSystem.VALID_CHARS
	local v117_ = {}
	for _ = 1, ExtraContentSystem.KEY_LENGTH - ExtraContentSystem.NUM_ITEM_CHARACTERS - 1 do
		local v118_ = math.random(1, v116_)
		local v119_ = ExtraContentSystem.VALID_CHARS[v118_]
		table.insert(v117_, v119_)
	end
	Utils.shuffle(itemChars)
	local v120_ = ExtraContentSystem.ITEM_INDEX_1
	local v121_ = itemChars[1]
	table.insert(v117_, v120_, v121_)
	local v122_ = ExtraContentSystem.ITEM_INDEX_2
	local v123_ = itemChars[2]
	table.insert(v117_, v122_, v123_)
	local v124_ = ExtraContentSystem.ITEM_INDEX_3
	local v125_ = itemChars[3]
	table.insert(v117_, v124_, v125_)
	local v126_ = self:getChecksumChar(v117_)
	table.insert(v117_, v126_)
	local v127_ = table.concat(v117_, "")
	local v128_, v129_ = self:getItemByKey(v127_)
	if v128_ ~= nil and item == v128_ then
		return v127_
	end
	Logging.error("Created invalid product key (error code: %s) - %s", tostring(v129_), v127_)
	return nil
end
