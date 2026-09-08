-- Local values: ModManager_mt
ModManager = {}
local ModManager_mt = Class(ModManager, AbstractManager)

-- Upvalues: ModManager_mt
-- Local values: self
function ModManager.new(customMt)
	-- upvalues: (copy) ModManager_mt
	return AbstractManager.new(customMt or ModManager_mt)
end

function ModManager:initDataStructures()
	self.hashToMod = {}
	self.nameToMod = {}
	self.titleToMod = {}
	self.validMods = {}
	self.multiplayerMods = {}
	self.mods = {}
	self.numMods = 0
end

-- Local values: mod
function ModManager:addMod(title, description, version, modDescVersion, author, iconFilename, modName, modDir, modFile, isMultiplayerSupported, fileHash, absBaseFilename, isDirectory, isDLC, hasScripts, dependencies, multiplayerOnly, isSelectable, uniqueType, isInternalScriptMod)
	if fileHash ~= nil and self.hashToMod[fileHash] ~= nil then
		printError("Error: Adding mod with same file hash twice. Title is " .. title .. " filehash: " .. fileHash)
		return nil
	end
	self.numMods = self.numMods + 1
	local v25_ = {
		["id"] = self.numMods,
		["title"] = title,
		["description"] = description,
		["version"] = version,
		["modDescVersion"] = modDescVersion,
		["author"] = author,
		["iconFilename"] = iconFilename,
		["isDLC"] = isDLC
	}
	local v26_
	if isInternalScriptMod then
		v26_ = author == "GIANTS Software"
	else
		v26_ = isInternalScriptMod
	end
	v25_.isFreeDLC = v26_
	v25_.fileHash = fileHash
	v25_.modName = modName
	v25_.modDir = modDir
	v25_.modFile = modFile
	v25_.absBaseFilename = absBaseFilename
	v25_.isDirectory = isDirectory
	v25_.isMultiplayerSupported = isMultiplayerSupported
	v25_.isSelectable = isSelectable
	v25_.hasScripts = hasScripts
	v25_.isInternalScriptMod = isInternalScriptMod
	v25_.dependencies = dependencies
	v25_.multiplayerOnly = multiplayerOnly
	v25_.uniqueType = uniqueType
	local v27_ = self.mods
	table.insert(v27_, v25_)
	self.nameToMod[modName] = v25_
	self.titleToMod[title] = v25_
	if fileHash ~= nil then
		local v28_ = self.validMods
		table.insert(v28_, v25_)
		self.hashToMod[fileHash] = v25_
		if isMultiplayerSupported then
			local v29_ = self.multiplayerMods
			table.insert(v29_, v25_)
		end
	end
	return v25_
end

-- Local values: index, modItem, index, modItem, index, modItem
function ModManager:removeMod(mod)
	if mod == nil then
		return false
	end
	self.nameToMod[mod.modName] = nil
	if mod.fileHash ~= nil then
		self.hashToMod[mod.fileHash] = nil
	end
	for v32_, v33_ in ipairs(self.mods) do
		if v33_ == mod then
			table.remove(self.mods, v32_)
			break
		end
	end
	for v34_, v35_ in ipairs(self.validMods) do
		if v35_ == mod then
			table.remove(self.validMods, v34_)
			break
		end
	end
	for v36_, v37_ in ipairs(self.multiplayerMods) do
		if v37_ == mod then
			table.remove(self.multiplayerMods, v36_)
			break
		end
	end
	return true
end

function ModManager:getModByFileHash(fileHash)
	return self.hashToMod[fileHash]
end

function ModManager:getModByName(modName)
	return self.nameToMod[modName]
end

function ModManager:getModByTitle(modName)
	return self.titleToMod[modName]
end

-- Local values: mod
function ModManager:getModIconByName(modName)
	local v46_ = self.nameToMod[modName]
	if v46_ == nil then
		return nil
	else
		return v46_.iconFilename
	end
end

function ModManager:getModByIndex(index)
	return self.mods[index]
end

function ModManager:getMods()
	return self.mods
end

function ModManager:getMultiplayerMods()
	return self.multiplayerMods
end

-- Local values: mods, _, mod
function ModManager:getActiveMods()
	local v52_ = {}
	for _, v53_ in ipairs(self.mods) do
		if g_modIsLoaded[v53_.modName] then
			table.insert(v52_, v53_)
		end
	end
	return v52_
end

function ModManager:getNumOfMods()
	return #self.mods
end

-- Local values: _, modItem
function ModManager:getHasSelectableMod()
	for _, v56_ in ipairs(self.mods) do
		if v56_.isSelectable then
			return true
		end
	end
	return false
end

function ModManager:getNumOfValidMods()
	return #self.validMods
end

-- Local values: _, modItem
function ModManager:getHasSelectableValidMod()
	for _, v59_ in ipairs(self.validMods) do
		if v59_.isSelectable then
			return true
		end
	end
	return false
end

-- Local values: _, modHash
function ModManager:getAreAllModsAvailable(modHashes)
	for _, v62_ in pairs(modHashes) do
		if not self:getIsModAvailable(v62_) then
			return false
		end
	end
	return true
end

-- Local values: modItem
function ModManager:getIsModAvailable(modHash)
	local v65_ = self.hashToMod[modHash]
	return v65_ ~= nil and v65_.isMultiplayerSupported and true or false
end

-- Local values: mapId, _, mapModName
function ModManager:isModMap(modName)
	for v67_, _ in pairs(g_mapManager.idToMap) do
		if g_mapManager:getModNameFromMapId(v67_) == modName then
			return true
		end
	end
	return false
end
g_modManager = ModManager.new()
