g_modDescSchema = nil
g_uniqueDlcNamePrefix = "pdlc_"
g_modEventListeners = {}
g_dlcsDirectories = {}
g_forceNeedsDlcsAndModsReload = false
g_lastCheckDlcPaths = {}
g_modIsLoaded = {}
g_globalMods = {}
g_modNameToDirectory = {}
local isReloadingDlcs = false
g_dlcModNameHasPrefix = {}
g_internalModsDirectory = "internalMods/"
local internalMods = {}
local internalScriptMods = { "FS25_precisionFarming" }
g_outdatedMods = {
	["FS25_SelectableBaleCapacity"] = { maxVersion = { 1, 0, 0, 0 } },
	["FS25_seeds_addon_crossplay"] = { maxVersion = { 1, 0, 0, 1 } },
	["FS25_SchwesingBahnhof"] = { maxVersion = { 1, 0, 0, 2 } },
	["FS25_simpleIC"] = { maxVersion = { 9, 0, 0, 0 } },
	["FS25_simpleIC_fs25planet"] = { maxVersion = { 9, 0, 0, 0 } },
	["FS25_JohnDeere7030"] = { maxVersion = { 1, 1, 0, 0 } },
	["FS25_InfoDisplayExtension"] = { maxVersion = { 1, 1, 1, 9 } },
	["FS25_Courseplay"] = { maxVersion = { 8, 0, 1, 1 } },
	["Courseplay"] = { maxVersion = { 8, 0, 1, 1 } },
	["FS25_Courseplay_FS25_main"] = { maxVersion = { 8, 0, 1, 1 } },
	["FS25_UniversalAutoload"] = { maxVersion = { 0, 4, 5, 7 } },
	["UniversalAutoload"] = { maxVersion = { 0, 4, 5, 7 } },
	["FS25_UniversalAutoload_main"] = { maxVersion = { 0, 4, 5, 8 } },
	["FS25_MUD_PARTICULES"] = { maxVersion = { 1, 0, 0, 0 } },
	["FS25_MUD_PARTICULES__1_"] = { maxVersion = { 1, 0, 0, 0 } },
	["FS25_MapObjectsHider"] = { maxVersion = { 1, 0, 9, 0 } },
	["FS25_PerfectEdge"] = { maxVersion = { 1, 0, 9, 0 } },
	["FS25_AutoDrive"] = { maxVersion = { 3, 0, 0, 3 } },
	["FS25_ContractBoost"] = { maxVersion = { 1, 0, 9, 0 } },
	["FS25_Financing"] = { maxVersion = { 1, 0, 0, 1 } },
	["FS25_exhaustExtension"] = { maxVersion = { 1, 0, 0, 2 } },
	["FS25_Contracts_Plus"] = { maxVersion = { 1, 0, 0, 0 } },
	["FS25_precisionFarming"] = { maxVersion = { 1, 3, 1, 0 } },
}
modOnCreate = {}
function loadDlcs()
	storeHaveDlcsChanged()
	g_modDescSchema = g_modDescSchema or createModDescSchema()
	if Platform.verboseDLCLoading then
		Logging.info("Start loading DLCs...")
	end
	local loadedDlcs = {}
	for i = 1, #g_dlcsDirectories do
		local dir = g_dlcsDirectories[i]
		if dir.isLoaded then
			loadDlcsFromDirectory(dir.path, loadedDlcs)
		end
	end
	if Platform.verboseDLCLoading then
		Logging.info("Finished loading DLCs.")
	end
end
function loadDlcsFromDirectory(dlcsDir, loadedDlcs)
	if Platform.verboseDLCLoading then
		Logging.info("Try to load dlcs from directory '%s'", dlcsDir)
	end
	local appBasePath = getAppBasePath()
	if isAbsolutePath(dlcsDir) and (appBasePath:len() == 0 or not string.startsWith(dlcsDir, appBasePath)) then
		createFolder(dlcsDir)
	end
	local files = Files.new(dlcsDir)
	for _, v in pairs(files.files) do
		if Platform.verboseDLCLoading then
			Logging.info("Trying to load dlc file %s", v.filename)
		end
		local addDLCPrefix = false
		local dlcFileHash = nil
		local dlcName = nil
		local xmlFilename = nil
		if v.isDirectory then
			if g_isDevelopmentVersion or not GS_PLATFORM_PC then
				dlcName = v.filename
				xmlFilename = "dlcDesc.xml"
				addDLCPrefix = true
				if not GS_PLATFORM_PC then
					dlcFileHash = getFileMD5(dlcsDir .. v.filename, dlcName)
				end
				if dlcFileHash == nil and g_isDevelopmentVersion then
					dlcFileHash = getMD5("Dev_" .. v.filename)
				end
			end
		else
			local len = v.filename:len()
			if 4 < len then
				local ext = v.filename:sub(len - 3)
				if ext == ".dlc" then
					dlcName = v.filename:sub(1, len - 4)
					dlcFileHash = getFileMD5(dlcsDir .. v.filename, dlcName)
					xmlFilename = "dlcDesc.xml"
					addDLCPrefix = true
				elseif ext == ".zip" or ext == ".gar" then
					dlcName = v.filename:sub(1, len - 4)
					dlcFileHash = getFileMD5(dlcsDir .. v.filename, dlcName)
					xmlFilename = "modDesc.xml"
					addDLCPrefix = false
				end
			end
		end
		if dlcName == nil or xmlFilename == nil then
			continue
		end
		if g_dlcModNameHasPrefix[dlcName] == nil then
			local dlcDir = dlcsDir .. dlcName .. "/"
			local dlcFile = dlcDir .. xmlFilename
			g_dlcModNameHasPrefix[dlcName] = addDLCPrefix
			loadModDesc(dlcName, dlcDir, dlcFile, dlcFileHash, dlcsDir .. v.filename, v.isDirectory, addDLCPrefix, false)
		end
	end
end
function loadAllMods()
	loadInternalMods()
	loadMods()
	haveModsChanged()
end
function loadMods()
	local loadedMods = {}
	local modsDir = g_modsDirectory
	g_showIllegalActivityInfo = false
	local files = Files.new(modsDir)
	for _, v in pairs(files.files) do
		local modFileHash = nil
		local modName = nil
		if v.isDirectory then
			modName = v.filename
			if g_isDevelopmentVersion then
				modFileHash = getMD5("DevMod_" .. v.filename)
			end
		else
			local len = v.filename:len()
			if 4 < len then
				local ext = v.filename:sub(len - 3)
				if ext == ".zip" or ext == ".gar" then
					modName = v.filename:sub(1, len - 4)
					modFileHash = getFileMD5(modsDir .. v.filename, modName)
				end
			end
		end
		if modName == nil then
			continue
		end
		local modDir = modsDir .. modName .. "/"
		local modFile = modDir .. "modDesc.xml"
		if loadedMods[modFile] == nil then
			loadModDesc(modName, modDir, modFile, modFileHash, modsDir .. v.filename, v.isDirectory, false, false)
			loadedMods[modFile] = true
		end
	end
	if g_showIllegalActivityInfo then
		print("Info: This game protects you from illegal activity")
	end
	g_showIllegalActivityInfo = nil
end
function loadInternalMods()
	for _, modInfo in ipairs(internalMods) do
		local modName = modInfo.name
		local modDir = g_internalModsDirectory .. modName .. "/"
		local modFile = modDir .. "modDesc.xml"
		local modFileHash = nil
		local garFile = g_internalModsDirectory .. modName .. ".gar"
		if fileExists(garFile) then
			modFileHash = getFileMD5(garFile, modName)
		elseif g_isDevelopmentVersion or GS_IS_CONSOLE_VERSION then
			if fileExists(modFile) then
				modFileHash = getFileMD5(modFile, modName)
			end
		end
		if modFileHash == nil then
			continue
		end
		loadModDesc(modName, modDir, modFile, modFileHash, g_internalModsDirectory .. modName, true, false, true)
	end
end
function postInitMods()
	for _, v in ipairs(g_modEventListeners) do
		if v.onPostInit == nil then
			continue
		end
		v:onPostInit()
	end
end
local getIsValidModDir = function(modDir)
	if modDir:len() == 0 then
		return false
	elseif string.startsWith(modDir, g_uniqueDlcNamePrefix) then
		return false
	elseif modDir:find("%d") == 1 then
		return false
	elseif modDir:find("[^%w_]") ~= nil then
		return false
	else
		return true
	end
end
local getIsInternalScriptMod = function(modName)
	for i = 1, #internalScriptMods do
		local internalModName = internalScriptMods[i]
		if modName == internalModName or modName == internalModName .. "_update" then
			return true
		end
	end
	return false
end
local getIsInternalMod = function(modName)
	for _, modInfo in ipairs(internalMods) do
		local internalModName = modInfo.name
		if modName == internalModName or modName == internalModName .. "_update" then
			return true
		end
	end
	return false
end
local getIsInternalModInfo = function(modName)
	for _, modInfo in ipairs(internalMods) do
		local internalModName = modInfo.name
		if modName == internalModName or modName == internalModName .. "_update" then
			return modInfo
		end
	end
	return nil
end
local resolveInternalScriptModFilename = function(filename, modName, modDir)
	if filename:sub(1, modDir:len()) == modDir then
		for i = 1, #internalScriptMods do
			local internalModName = internalScriptMods[i]
			if (modName == internalModName or modName == internalModName .. "_update") and (not fileExists(filename) or GS_IS_CONSOLE_VERSION) then
				return "dataS/scripts/internalMods/" .. internalModName .. "/" .. filename:sub(modDir:len() + 1)
			end
		end
	end
	return filename
end
function loadModDesc(modName, modDir, modFile, modFileHash, absBaseFilename, isDirectory, addDLCPrefix, isInternalMod)
	if not getIsValidModDir(modName) then
		printError("Error: Invalid mod name '" .. modName .. "'! Characters allowed: (_, A-Z, a-z, 0-9). The first character must not be a digit")
		return
	end
	local origModName = modName
	if addDLCPrefix then
		modName = g_uniqueDlcNamePrefix .. modName
	end
	if g_modNameToDirectory[modName] ~= nil then
		Logging.error("Mod name '" .. modName .. "' already in use. Ignore it!")
		return
	end
	g_modNameToDirectory[modName] = modDir
	local isDLCFile = false
	local revision = nil
	local buildName = nil
	if string.endsWith(modFile, "dlcDesc.xml") then
		isDLCFile = true
		if not fileExists(modFile) then
			if GS_IS_EPIC_VERSION then
				if string.startsWith(modDir, getAppBasePath() .. "pdlc/") then
					print("Info: No license for dlc " .. modName .. ".")
				else
					printError("Error: No license for dlc " .. modName .. ". Please reinstall.")
				end
			end
			return
		end
		local settingsXML = XMLFile.loadIfExists("DLC SettingsFile", modDir .. "settings.xml")
		if settingsXML ~= nil then
			revision = settingsXML:getString("settings#revision", "Unknown")
			buildName = settingsXML:getString("settings#buildName", "Unknown")
			settingsXML:delete()
		end
	end
	setModInstalled(absBaseFilename, addDLCPrefix)
	local xmlFile = XMLFile.load("ModFile", modFile, g_modDescSchema)
	if xmlFile == nil then
		return
	end
	local modVersion = xmlFile:getString("modDesc.version")
	local versionStr = ""
	if modVersion ~= nil and modVersion ~= "" then
		versionStr = " (Version: " .. modVersion .. ")"
	end
	if isInternalMod then
		local modInfo = getIsInternalModInfo(modName)
		if modVersion ~= modInfo.version then
			printError("Error: Outdated mod version in mod " .. modName)
			xmlFile:delete()
			return
		end
	end
	local hashStr = ""
	if modFileHash ~= nil then
		hashStr = "(Hash: " .. modFileHash .. ")"
	end
	if isDLCFile then
		local buildStr = ""
		if not string.isNilOrWhitespace(buildName) then
			buildStr = string.format(" / Build: %s", buildName)
		end
		local revisionStr = ""
		if revision ~= nil then
			revisionStr = string.format(" (Revision: %s%s)", revision, buildStr)
		end
		print("Available dlc: " .. hashStr .. versionStr .. " " .. modName .. revisionStr)
	else
		print("Available mod: " .. hashStr .. versionStr .. " " .. modName)
	end
	local modDescVersion = xmlFile:getInt("modDesc#descVersion")
	if modDescVersion == nil then
		printError("Error: Missing descVersion attribute in mod " .. modName)
		xmlFile:delete()
	else
		if modDescVersion < g_minModDescVersion or g_maxModDescVersion < modDescVersion then
			printError("Error: Unsupported mod description version in mod " .. modName)
			xmlFile:delete()
			return
		end
		if _G[modName] ~= nil and not isReloadingDlcs then
			printError("Error: Invalid mod name '" .. modName .. "'")
			xmlFile:delete()
			return
		end
		if isDLCFile then
			local requiredModName = xmlFile:getString("modDesc.multiplayer#requiredModName")
			if requiredModName ~= nil and requiredModName ~= origModName then
				printError("Error: Do not rename dlcs. Name: '" .. origModName .. "'. Expect: '" .. requiredModName .. "'")
				xmlFile:delete()
				return
			end
		end
		local isSelectable = xmlFile:getBool("modDesc.isSelectable", true)
		local modEnv = {}
		if GS_IS_CONSOLE_VERSION then
			modEnv = Utils.getNoNil(_G[modName], modEnv)
		end
		g_globalsNameCheckDisabled = true
		_G[modName] = modEnv
		g_globalsNameCheckDisabled = false
		local modEnv_mt = {}
		modEnv_mt.__index = _G
		setmetatable(modEnv, modEnv_mt)
		if not isDLCFile and not isInternalMod then
			modEnv._G = modEnv
		end
		local gEnv = _G
		local orgGetfenv = getfenv
		function modEnv.getfenv(obj)
			local ret = orgGetfenv(obj)
			if ret == gEnv then
				return modEnv
			else
				return ret
			end
		end
		modEnv.g_i18n = g_i18n:addModI18N(modName)
		function modEnv.loadstring()
			printError(string.format("Error: Mod '%s' tried to compile script code at runtime (loadstring). Disabled for security reasons", modName))
			return nil, "loadstring is not available"
		end
		function modEnv.source(filename, env)
			if isAbsolutePath(filename) or isInternalMod then
				filename = resolveInternalScriptModFilename(filename, modName, modDir)
				source(filename, modName)
				return
			end
			source(filename)
		end
		function modEnv.InitEventClass(classObject, className)
			InitEventClass(classObject, modName .. "." .. className)
		end
		function modEnv.InitObjectClass(classObject, className)
			InitObjectClass(classObject, modName .. "." .. className)
		end
		function modEnv.registerObjectClassName(object, className)
			registerObjectClassName(object, modName .. "." .. className)
		end
		modEnv.g_constructionBrushTypeManager = {}
		function modEnv.g_constructionBrushTypeManager:addBrushType(typeName, className, filename, customEnvironment)
			if isAbsolutePath(filename) or isInternalMod then
				filename = resolveInternalScriptModFilename(filename, modName, modDir)
				customEnvironment = modName
				typeName = modName .. "." .. typeName
				className = modName .. "." .. className
			end
			g_constructionBrushTypeManager:addBrushType(typeName, className, filename, customEnvironment)
		end
		function modEnv.g_constructionBrushTypeManager:getClassObjectByTypeName(typeName)
			local classObj = g_constructionBrushTypeManager:getClassObjectByTypeName(typeName)
			if classObj == nil then
				classObj = g_constructionBrushTypeManager:getClassObjectByTypeName(modName .. "." .. typeName)
			end
			return classObj
		end
		setmetatable(modEnv.g_constructionBrushTypeManager, { __index = g_constructionBrushTypeManager })
		modEnv.g_specializationManager = {}
		function modEnv.g_specializationManager:addSpecialization(name, className, filename, customEnvironment, ...)
			if type(self) ~= "table" then
				Logging.error("Invalid self object given for (Vehicle) SpecializationManager.addSpecialization. Usage: 'g_specializationManager:addSpecialization(name, className, filename, customEnvironment)'")
				printCallstack()
			end
			if customEnvironment ~= nil and type(customEnvironment) ~= "string" then
				Logging.error("Invalid customEnvironment given for (Vehicle) SpecializationManager.addSpecialization. Should be a string or nil.")
				printCallstack()
			end
			if 0 < select("#", ...) then
				Logging.error("Too many arguments for (Vehicle) SpecializationManager.addSpecialization. (Arguments should be: name, className, filename, customEnvironment)")
				printCallstack()
			end
			if isAbsolutePath(filename) or isInternalMod then
				filename = resolveInternalScriptModFilename(filename, modName, modDir)
				customEnvironment = modName
				name = modName .. "." .. name
				className = modName .. "." .. className
			end
			local file = Utils.getFilenameFromPath(filename)
			if file == "AddConfig.lua" and customEnvironment ~= nil then
				Logging.error("Loading file '%s' of mod '%s' was blocked because it is not compatible with Farming Simulator 25", file, customEnvironment)
				return
			end
			g_specializationManager:addSpecialization(name, className, filename, customEnvironment)
		end
		function modEnv.g_specializationManager:getSpecializationByName(name)
			local spec = g_specializationManager:getSpecializationByName(name)
			if spec == nil then
				spec = g_specializationManager:getSpecializationByName(modName .. "." .. name)
			end
			return spec
		end
		function modEnv.g_specializationManager:getSpecializationObjectByName(name)
			local spec = g_specializationManager:getSpecializationObjectByName(name)
			if spec == nil then
				spec = g_specializationManager:getSpecializationObjectByName(modName .. "." .. name)
			end
			return spec
		end
		setmetatable(modEnv.g_specializationManager, { __index = g_specializationManager })
		modEnv.g_placeableSpecializationManager = {}
		function modEnv.g_placeableSpecializationManager:addSpecialization(name, className, filename, customEnvironment, ...)
			if type(self) ~= "table" then
				Logging.error("Invalid self object given for (Placeable) SpecializationManager.addSpecialization. Usage: 'g_placeableSpecializationManager:addSpecialization(name, className, filename, customEnvironment)'")
				printCallstack()
			end
			if customEnvironment ~= nil and type(customEnvironment) ~= "string" then
				Logging.error("Invalid customEnvironment given for (Placeable) SpecializationManager.addSpecialization. Should be a string or nil.")
				printCallstack()
			end
			if 0 < select("#", ...) then
				Logging.error("Too many arguments for (Placeable) SpecializationManager.addSpecialization. (Arguments should be: name, className, filename, customEnvironment)")
				printCallstack()
			end
			if isAbsolutePath(filename) or isInternalMod then
				filename = resolveInternalScriptModFilename(filename, modName, modDir)
				customEnvironment = modName
				name = modName .. "." .. name
				className = modName .. "." .. className
			end
			g_placeableSpecializationManager:addSpecialization(name, className, filename, customEnvironment)
		end
		function modEnv.g_placeableSpecializationManager:getSpecializationByName(name)
			local spec = g_placeableSpecializationManager:getSpecializationByName(name)
			if spec == nil then
				spec = g_placeableSpecializationManager:getSpecializationByName(modName .. "." .. name)
			end
			return spec
		end
		setmetatable(modEnv.g_placeableSpecializationManager, { __index = g_placeableSpecializationManager })
		modEnv.g_handToolSpecializationManager = {}
		function modEnv.g_handToolSpecializationManager:addSpecialization(name, className, filename, customEnvironment, ...)
			if type(self) ~= "table" then
				Logging.error("Invalid self object given for SpecializationManager.addSpecialization. Usage: 'g_handToolSpecializationManager:addSpecialization(name, className, filename, customEnvironment)'")
				printCallstack()
			end
			if customEnvironment ~= nil and type(customEnvironment) ~= "string" then
				Logging.error("Invalid customEnvironment given for (HandTool) SpecializationManager.addSpecialization. Should be a string or nil.")
				printCallstack()
			end
			if 0 < select("#", ...) then
				Logging.error("Too many arguments for (HandTool) SpecializationManager.addSpecialization. (Arguments should be: name, className, filename, customEnvironment)")
				printCallstack()
			end
			if isAbsolutePath(filename) or isInternalMod then
				filename = resolveInternalScriptModFilename(filename, modName, modDir)
				customEnvironment = modName
				name = modName .. "." .. name
				className = modName .. "." .. className
			end
			g_handToolSpecializationManager:addSpecialization(name, className, filename, customEnvironment)
		end
		function modEnv.g_handToolSpecializationManager:getSpecializationByName(name)
			local spec = g_handToolSpecializationManager:getSpecializationByName(name)
			if spec == nil then
				spec = g_handToolSpecializationManager:getSpecializationByName(modName .. "." .. name)
			end
			return spec
		end
		setmetatable(modEnv.g_handToolSpecializationManager, { __index = g_handToolSpecializationManager })
		modEnv.g_vehicleTypeManager = {}
		function modEnv.g_vehicleTypeManager:addType(typeName, className, filename, customEnvironment)
			if isAbsolutePath(filename) or isInternalMod then
				filename = resolveInternalScriptModFilename(filename, modName, modDir)
				customEnvironment = modName
				typeName = modName .. "." .. typeName
				className = modName .. "." .. className
			end
			g_vehicleTypeManager:addType(typeName, className, filename, customEnvironment)
		end
		function modEnv.g_vehicleTypeManager:addSpecialization(typeName, specName)
			local spec = g_specializationManager:getSpecializationByName(specName)
			if spec == nil and g_specializationManager:getSpecializationByName(modName .. "." .. specName) ~= nil then
				specName = modName .. "." .. specName
			end
			g_vehicleTypeManager:addSpecialization(typeName, specName)
		end
		setmetatable(modEnv.g_vehicleTypeManager, { __index = g_vehicleTypeManager })
		modEnv.g_placeableTypeManager = {}
		function modEnv.g_placeableTypeManager:addType(typeName, className, filename, customEnvironment)
			if isAbsolutePath(filename) or isInternalMod then
				filename = resolveInternalScriptModFilename(filename, modName, modDir)
				customEnvironment = modName
				typeName = modName .. "." .. typeName
				className = modName .. "." .. className
			end
			g_placeableTypeManager:addType(typeName, className, filename, customEnvironment)
		end
		function modEnv.g_placeableTypeManager:addSpecialization(typeName, specName)
			local spec = g_placeableSpecializationManager:getSpecializationByName(specName)
			if spec == nil and g_placeableSpecializationManager:getSpecializationByName(modName .. "." .. specName) ~= nil then
				specName = modName .. "." .. specName
			end
			g_placeableTypeManager:addSpecialization(typeName, specName)
		end
		setmetatable(modEnv.g_placeableTypeManager, { __index = g_placeableTypeManager })
		modEnv.g_handToolTypeManager = {}
		function modEnv.g_handToolTypeManager:addType(typeName, className, filename, customEnvironment)
			if isAbsolutePath(filename) or isInternalMod then
				filename = resolveInternalScriptModFilename(filename, modName, modDir)
				customEnvironment = modName
				typeName = modName .. "." .. typeName
				className = modName .. "." .. className
			end
			g_handToolTypeManager:addType(typeName, className, filename, customEnvironment)
		end
		function modEnv.g_handToolTypeManager:addSpecialization(typeName, specName)
			local spec = g_handToolSpecializationManager:getSpecializationByName(specName)
			if spec == nil and g_handToolSpecializationManager:getSpecializationByName(modName .. "." .. specName) ~= nil then
				specName = modName .. "." .. specName
			end
			g_handToolTypeManager:addSpecialization(typeName, specName)
		end
		setmetatable(modEnv.g_handToolTypeManager, { __index = g_handToolTypeManager })
		modEnv.g_effectManager = {}
		function modEnv.g_effectManager:registerEffectClass(className, effectClass)
			if not ClassUtil.getIsValidClassName(className) then
				printError("Error: Invalid effect class name: " .. className)
			else
				_G.g_effectManager:registerEffectClass(modName .. "." .. className, effectClass)
			end
		end
		function modEnv.g_effectManager:getEffectClass(className)
			local effectClass = _G.g_effectManager:getEffectClass(className)
			if effectClass == nil then
				effectClass = _G.g_effectManager:getEffectClass(modName .. "." .. className)
			end
			return effectClass
		end
		setmetatable(modEnv.g_effectManager, { __index = _G.g_effectManager })
		local userProfilePath = getUserProfileAppPath()
		local sub = string.sub
		local len = string.len
		local protectedDelete = function(func)
			return function(filename)
				local modSettingsDirectory = userProfilePath .. "modSettings/" .. modName
				if sub(filename, 1, len(modSettingsDirectory)) == modSettingsDirectory then
					func(filename)
				else
					printError(string.format("Error: No access to folder '%s'", filename))
					print(string.format("Info: Mod has full access in '%s'", modSettingsDirectory))
					printCallstack()
				end
			end
		end
		modEnv.g_adsSystem = {}
		modEnv.InitStaticEventClass = ""
		modEnv.InitStaticObjectClass = ""
		modEnv.loadMod = ""
		modEnv.loadModDesc = ""
		modEnv.loadDlcs = ""
		modEnv.loadDlcsFromDirectory = ""
		modEnv.loadMods = ""
		modEnv.reloadDlcsAndMods = ""
		modEnv.verifyDlcs = ""
		modEnv.deleteFile = protectedDelete(deleteFile)
		modEnv.deleteFolder = protectedDelete(deleteFolder)
		local orgGetUniqueUserId = getUniqueUserId
		local hasWarnedGetUniqueUserId = false
		function modEnv.getUniqueUserId()
			if not hasWarnedGetUniqueUserId then
				hasWarnedGetUniqueUserId = true
				Logging.warning("Mod '%s' uses the deprecated function 'getUniqueUserId()'. The function will be removed soon and the mod will no longer work. Please contact the mod author to request an update.", modName)
			end
			return orgGetUniqueUserId()
		end
		modEnv.isAbsolutePath = isAbsolutePath
		modEnv.g_isDevelopmentVersion = g_isDevelopmentVersion
		modEnv.GS_IS_CONSOLE_VERSION = GS_IS_CONSOLE_VERSION
		if not isDLCFile and not isInternalMod then
			modEnv.ClassUtil = {}
			function modEnv.ClassUtil:getClassModName(className)
				local classModName = _G.ClassUtil.getClassModName(className)
				if classModName == nil then
					classModName = _G.ClassUtil.getClassModName(modName .. "." .. className)
				end
				return classModName
			end
		end
		local onCreateUtil = {}
		onCreateUtil.onCreateFunctions = {}
		modEnv.g_onCreateUtil = onCreateUtil
		function onCreateUtil.addOnCreateFunction(name, func)
			onCreateUtil.onCreateFunctions[name] = func
		end
		function onCreateUtil.activateOnCreateFunctions()
			for name, func in pairs(onCreateUtil.onCreateFunctions) do
				modOnCreate[name] = function(id)
					func(id)
				end
			end
		end
		function onCreateUtil.deactivateOnCreateFunctions()
			for name, _ in pairs(onCreateUtil.onCreateFunctions) do
				modOnCreate[name] = nil
			end
		end
		for _, baseName in xmlFile:iterator("modDesc.l10n.text") do
			local name = xmlFile:getString(baseName .. "#name")
			local text = xmlFile:getString(baseName .. "." .. g_languageShort) or xmlFile:getString(baseName .. ".en") or xmlFile:getString(baseName .. ".de")
			if text == nil or name == nil then
				printWarning("Warning: No l10n text found for entry '" .. name .. "' in mod '" .. modName .. "'")
			else
				if modEnv.g_i18n:hasModText(name) then
					printWarning("Warning: Duplicate l10n entry '" .. name .. "' in mod '" .. modName .. "'. Ignoring this definition.")
				else
					modEnv.g_i18n:setText(name, text)
				end
			end
		end
		local l10nFilenamePrefix = xmlFile:getString("modDesc.l10n#filenamePrefix")
		if l10nFilenamePrefix ~= nil then
			local l10nFilenamePrefixFull = Utils.getFilename(l10nFilenamePrefix, modDir)
			local l10nXmlFile = nil
			local l10nFilename = nil
			local langs = { g_languageShort, "en", "de" }
			for _, lang in ipairs(langs) do
				l10nFilename = l10nFilenamePrefixFull .. "_" .. lang .. ".xml"
				if fileExists(l10nFilename) then
					l10nXmlFile = XMLFile.load("modL10n", l10nFilename)
					break
				end
			end
			if l10nXmlFile ~= nil then
				for _, key in l10nXmlFile:iterator("l10n.texts.text") do
					local name = l10nXmlFile:getString(key .. "#name")
					local text = l10nXmlFile:getString(key .. "#text")
					if name == nil or text == nil then
						continue
					end
					if modEnv.g_i18n:hasModText(name) then
						printWarning("Warning: Duplicate l10n entry '" .. name .. "' in '" .. l10nFilename .. "'. Ignoring this definition.")
					else
						modEnv.g_i18n:setText(name, text:gsub("\r\n", "\n"))
					end
				end
				for _, key in l10nXmlFile:iterator("l10n.elements.e") do
					local name = l10nXmlFile:getString(key .. "#k")
					local text = l10nXmlFile:getString(key .. "#v")
					if name == nil or text == nil then
						continue
					end
					if modEnv.g_i18n:hasModText(name) then
						printWarning("Warning: Duplicate l10n entry '" .. name .. "' in '" .. l10nFilename .. "'. Ignoring this definition.")
					else
						modEnv.g_i18n:setText(name, text:gsub("\r\n", "\n"))
					end
				end
				l10nXmlFile:delete()
			else
				printWarning(string.format("Warning: No l10n file(s) found for prefix %q' (e.g. '%sen.xml') in mod %q", l10nFilenamePrefix, l10nFilenamePrefix, modName))
			end
		end
		local title = xmlFile:getI18NValue("modDesc.title", "", modName, true)
		local desc = xmlFile:getI18NValue("modDesc.description", "", modName, true)
		local iconFilename = xmlFile:getI18NValue("modDesc.iconFilename", "", modName, true)
		if title == "" then
			printError("Error: Missing title in mod " .. modName)
			xmlFile:delete()
		elseif desc == "" then
			printError("Error: Missing description in mod " .. modName)
			xmlFile:delete()
		else
			local isMultiplayerSupported = xmlFile:getBool("modDesc.multiplayer#supported", false)
			local isOnlyMultiplayerSupported = xmlFile:getBool("modDesc.multiplayer#only", false)
			if modFileHash == nil then
				if Platform.supportsMultiplayer and isMultiplayerSupported then
					printWarning("Warning: Only zip mods are supported in multiplayer. You need to zip the mod " .. modName .. " to use it in multiplayer.")
				end
				isMultiplayerSupported = false
			end
			if not isMultiplayerSupported and isOnlyMultiplayerSupported then
				printError("Error: Both multiplayer and singleplayer are unsupported in mod " .. modName)
				xmlFile:delete()
				return
			end
			if isMultiplayerSupported and iconFilename == "" then
				printError("Error: Missing icon filename in mod " .. modName)
				xmlFile:delete()
				return
			end
			for _, baseName in xmlFile:iterator("modDesc.maps.map") do
				g_mapManager:loadMapFromXML(xmlFile, baseName, modDir, modName, isMultiplayerSupported, isDLCFile, true, isInternalMod)
			end
			local author = xmlFile:getI18NValue("modDesc.author", "", modName, true)
			if isDLCFile then
				local dlcProductId = xmlFile:getString("modDesc.productId")
				if dlcProductId == nil or modVersion == nil then
					printError("Error: invalid product id or version in DLC " .. modName)
				else
					addNotificationFilter(dlcProductId, modVersion)
				end
			end
			local hasScripts = xmlFile:hasProperty("modDesc.extraSourceFiles.sourceFile(0)") or xmlFile:hasProperty("modDesc.specializations.specialization(0)")
			local dependencies = nil
			if xmlFile:hasProperty("modDesc.dependencies.dependency(0)") then
				dependencies = {}
				for index, key in xmlFile:iterator("modDesc.dependencies.dependency") do
					local name = xmlFile:getString(key)
					if string.isNilOrWhitespace(name) then
						printWarning(string.format("Warning: mod %q has empty dependency at %q", modName, key))
					elseif string.endsWith(name, ".zip") then
						printWarning(string.format("Warning: mod %q dependency %q at %q should not include '.zip' in its name", modName, name, key))
					else
						if table.addElement(dependencies, name) then
							continue
						end
						printWarning(string.format("Warning: mod %q has duplicate dependency %q at %q", modName, name, key))
					end
				end
			end
			local uniqueType = xmlFile:getString("modDesc.uniqueType")
			for _, xmlKey in xmlFile:iterator("modDesc.extraContent.key") do
				local key = xmlFile:getString(xmlKey)
				if key == nil then
					continue
				end
				local item, errorCode = g_extraContentSystem:unlockItem(key, true)
				if item == nil then
					continue
				end
				if errorCode == ExtraContentSystem.UNLOCKED then
					print("ExtraContent: Unlocked '" .. item.id .. "'")
					g_extraContentSystem:saveToProfile()
				end
			end
			if isInternalMod then
				g_currentModDirectory = modDir
				g_currentModName = modName
				for _, key in xmlFile:iterator("modDesc.preLoadSourceFiles.sourceFile") do
					local filename = xmlFile:getString(key .. "#filename")
					if filename == nil then
						continue
					end
					modEnv.source(modDir .. filename, modName)
				end
				g_currentModDirectory = nil
				g_currentModName = nil
			end
			iconFilename = Utils.getFilename(iconFilename, modDir)
			g_modManager:addMod(title, desc, modVersion, modDescVersion, author, iconFilename, modName, modDir, modFile, isMultiplayerSupported, modFileHash, absBaseFilename, isDirectory, isDLCFile, hasScripts, dependencies, isOnlyMultiplayerSupported, isSelectable, uniqueType, getIsInternalScriptMod(modName))
			xmlFile:delete()
		end
	end
end
function resetModOnCreateFunctions()
	modOnCreate = {}
end
function loadMod(modName, modDir, modFile, modTitle)
	if g_modIsLoaded[modName] then
		return
	end
	g_modIsLoaded[modName] = true
	g_modNameToDirectory[modName] = modDir
	local modEnv = _G[modName]
	if modEnv == nil then
		return
	else
		local xmlFile = XMLFile.load("ModFile", modFile, g_modDescSchema)
		local isDLCFile = false
		if string.endsWith(modFile, "dlcDesc.xml") then
			isDLCFile = true
		else
		end
		if isDLCFile then
			print("  Load dlc: " .. modName)
		else
			print("  Load mod: " .. modName)
		end
		local allowScripts = not GS_IS_CONSOLE_VERSION or isDLCFile or g_isDevelopmentConsoleScriptModTesting or getIsInternalScriptMod(modName) or getIsInternalMod(modName)
		g_currentModDirectory = modDir
		g_currentModName = modName
		if g_modSettingsDirectory ~= nil then
			g_currentModSettingsDirectory = g_modSettingsDirectory .. modName .. "/"
		end
		if allowScripts then
			for _, key in xmlFile:iterator("modDesc.extraSourceFiles.sourceFile") do
				local filename = xmlFile:getString(key .. "#filename")
				if filename == nil then
					continue
				end
				modEnv.source(modDir .. filename, modName)
			end
		end
		for _, key in xmlFile:iterator("modDesc.brands.brand") do
			local name = xmlFile:getString(key .. "#name")
			local title = xmlFile:getString(key .. "#title")
			local image = xmlFile:getString(key .. "#image")
			local offset = xmlFile:getFloat(key .. "#imageOffset")
			g_brandManager:addBrand(name, title, image, modDir, true, nil, offset)
		end
		for _, key in xmlFile:iterator("modDesc.helpLines.category") do
			g_helpLineManager:addModCategory(xmlFile, key, modDir, modName)
		end
		if isDLCFile then
			for _, key in xmlFile:iterator("modDesc.storeCategories.storeCategory") do
				g_storeManager:loadCategoryFromXML(xmlFile, key, modDir, modName, true)
			end
		end
		for _, key in xmlFile:iterator("modDesc.specializations.specialization") do
			local specName = xmlFile:getString(key .. "#name")
			local className = xmlFile:getString(key .. "#className")
			local filename = xmlFile:getString(key .. "#filename")
			if specName == nil or className == nil or filename == nil then
				continue
			end
			filename = modDir .. filename
			if allowScripts then
				modEnv.g_specializationManager:addSpecialization(specName, className, filename, modName)
			else
				printError("Error: Can't register specialization " .. specName .. " with scripts on consoles.")
			end
		end
		for _, key in xmlFile:iterator("modDesc.vehicleTypes.type") do
			g_vehicleTypeManager:loadTypeFromXML(xmlFile.handle, key, isDLCFile, modDir, modName)
		end
		for _, key in xmlFile:iterator("modDesc.placeableSpecializations.specialization") do
			local specName = xmlFile:getString(key .. "#name")
			local className = xmlFile:getString(key .. "#className")
			local filename = xmlFile:getString(key .. "#filename")
			if specName == nil or className == nil or filename == nil then
				continue
			end
			filename = modDir .. filename
			if allowScripts then
				modEnv.g_placeableSpecializationManager:addSpecialization(specName, className, filename, modName)
			else
				printError("Error: Can't register placeable specialization " .. specName .. " with scripts on consoles.")
			end
		end
		for _, key in xmlFile:iterator("modDesc.placeableTypes.type") do
			g_placeableTypeManager:loadTypeFromXML(xmlFile.handle, key, isDLCFile, modDir, modName)
		end
		for _, key in xmlFile:iterator("modDesc.handToolSpecializations.specialization") do
			local specName = xmlFile:getString(key .. "#name")
			local className = xmlFile:getString(key .. "#className")
			local filename = xmlFile:getString(key .. "#filename")
			if specName == nil or className == nil or filename == nil then
				continue
			end
			filename = modDir .. filename
			if allowScripts then
				modEnv.g_handToolSpecializationManager:addSpecialization(specName, className, filename, modName)
			else
				printError("Error: Can't register handTool specialization " .. specName .. " with scripts on consoles.")
			end
		end
		for _, key in xmlFile:iterator("modDesc.handToolTypes.type") do
			g_handToolTypeManager:loadTypeFromXML(xmlFile.handle, key, isDLCFile, modDir, modName)
		end
		for _, key in xmlFile:iterator("modDesc.bales.bale") do
			g_baleManager:loadModBaleFromXML(xmlFile, key, modDir, modName)
		end
		for _, key in xmlFile:iterator("modDesc.jointTypes.jointType") do
			local name = xmlFile:getString(key .. "#name")
			if name == nil then
				continue
			end
			AttacherJoints.registerJointType(name)
		end
		for _, key in xmlFile:iterator("modDesc.materialHolders.materialHolder") do
			local filename = xmlFile:getString(key .. "#filename")
			if filename == nil then
				continue
			end
			filename = Utils.getFilename(filename, g_currentModDirectory)
			g_materialManager:addModMaterialHolder(filename)
		end
		g_vehicleMaterialManager:addModMaterialTemplatesToLoad(modFile, "modDesc.materialTemplates", g_currentModDirectory, modName)
		for _, key in xmlFile:iterator("modDesc.connectionHoses.connectionHose") do
			local xmlFilename = xmlFile:getString(key .. "#xmlFilename")
			if xmlFilename == nil then
				continue
			end
			xmlFilename = Utils.getFilename(xmlFilename, g_currentModDirectory)
			g_connectionHoseManager:addModConnectionHoses(xmlFilename, modName, g_currentModDirectory)
		end
		for _, key in xmlFile:iterator("modDesc.consumables.consumable") do
			local xmlFilename = xmlFile:getString(key .. "#xmlFilename")
			if xmlFilename == nil then
				continue
			end
			xmlFilename = Utils.getFilename(xmlFilename, g_currentModDirectory)
			g_consumableManager:addModConsumable(xmlFilename, modName, g_currentModDirectory)
		end
		for _, key in xmlFile:iterator("modDesc.storeItems.storeItem") do
			local storeItemXMLFilename = xmlFile:getString(key .. "#xmlFilename")
			if storeItemXMLFilename == nil then
				continue
			end
			g_storeManager:addModStoreItem(storeItemXMLFilename, modDir, modName, not isDLCFile, false, modTitle)
		end
		for _, key in xmlFile:iterator("modDesc.storePacks.storePack") do
			local name = xmlFile:getString(key .. "#name")
			local title = xmlFile:getString(key .. "#title")
			local imageFilename = xmlFile:getString(key .. "#image")
			if title ~= nil and title:sub(1, 6) == "$l10n_" then
				title = g_i18n:getText(title:sub(7))
			end
			local storeItems = {}
			for _, storeItemKey in xmlFile:iterator(key .. ".storeItem") do
				local xmlFilename = xmlFile:getString(storeItemKey)
				local fullXmlFilename = Utils.getFilename(xmlFilename, g_currentModDirectory)
				if fileExists(fullXmlFilename) then
					table.insert(storeItems, fullXmlFilename)
				else
					Logging.xmlWarning(xmlFile, "StoreItem '%s' not found for storepack '%s'", xmlFilename, name)
				end
			end
			g_storeManager:addModStorePack(name, title, imageFilename, modDir, storeItems)
		end
		local defaultIconFilename = xmlFile:getString("modDesc.constructionCategories#defaultIconFilename")
		local defaultRefSize = xmlFile:getVector("modDesc.constructionCategories#refSize", nil, 2) or { 1024, 1024 }
		for _, key in xmlFile:iterator("modDesc.constructionCategories.tab") do
			local categoryName = xmlFile:getString(key .. "#categoryName")
			local tabName = xmlFile:getString(key .. "#name")
			local tabTitle = g_i18n:convertText(xmlFile:getString(key .. "#title"), modName)
			local tabIconFilename = xmlFile:getString(key .. "#iconFilename") or defaultIconFilename
			local tabRefSize = xmlFile:getVector(key .. "#refSize", defaultRefSize, 2)
			local tabIconUVs = GuiUtils.getUVs(xmlFile:getString(key .. "#iconUVs", "0 0 1 1"), tabRefSize)
			local tabIconSliceId = xmlFile:getString(key .. "#iconSliceId")
			g_storeManager:addModConstructionTab(categoryName, tabName, tabTitle, tabIconFilename, tabRefSize, tabIconUVs, g_currentModDirectory, tabIconSliceId)
		end
		local fillTypesFilename = xmlFile:getString("modDesc.fillTypes#filename")
		if fillTypesFilename ~= nil then
			local filename, _ = Utils.getFilename(fillTypesFilename, g_currentModDirectory)
			g_fillTypeManager:addModWithFillTypes(filename, g_currentModDirectory, modName)
		end
		local densityMapHeightTypesFilename = xmlFile:getString("modDesc.densityMapHeightTypes#filename")
		if densityMapHeightTypesFilename ~= nil then
			local filename = Utils.getFilename(densityMapHeightTypesFilename, g_currentModDirectory)
			g_densityMapHeightManager:addModDensityMapHeightTypes(filename)
		end
		local motionPathEffectsFilename = xmlFile:getString("modDesc.motionPathEffects#filename")
		if motionPathEffectsFilename ~= nil then
			local filename = Utils.getFilename(motionPathEffectsFilename, g_currentModDirectory)
			g_motionPathEffectManager:loadModMotionPathEffects(filename, g_currentModDirectory, modName)
		end
		if isDLCFile then
			for _, key in xmlFile:iterator("modDesc.foliageTypes.foliageType") do
				local name = xmlFile:getString(key .. "#name")
				local filename = xmlFile:getString(key .. "#filename")
				if name == nil or filename == nil then
					continue
				end
				filename = Utils.getFilename(filename, g_currentModDirectory)
				g_fruitTypeManager:addModFoliageType(name, filename)
			end
		end
		local missionVehiclesFilename = xmlFile:getString("modDesc.missionVehicles#filename")
		if missionVehiclesFilename ~= nil then
			missionVehiclesFilename = Utils.getFilename(missionVehiclesFilename, g_currentModDirectory)
			g_missionManager:addPendingMissionVehiclesFile(missionVehiclesFilename, g_currentModDirectory)
		end
		for _, key in xmlFile:iterator("modDesc.wildlife.species") do
			local speciesFilename = xmlFile:getString(key .. "#filename")
			local groupNames = string.split(xmlFile:getString(key .. "#groups") or "", " ")
			g_wildlifeManager:registerModWildlifeFile(speciesFilename, g_currentModDirectory, groupNames)
		end
		xmlFile:delete()
		g_currentModDirectory = nil
		g_currentModName = nil
	end
end
function reloadDlcsAndMods()
	if g_currentMission ~= nil then
		print("Dlc reloading is not supported during gameplay")
	else
		for i = g_mapManager:getNumOfMaps(), 1, -1 do
			local map = g_mapManager:getMapDataByIndex(i)
			if map.isModMap then
				g_mapManager:removeMapItem(i)
			end
		end
		while 0 < g_modManager:getNumOfMods() do
			g_modManager:removeMod(g_modManager:getModByIndex(1))
		end
		g_modIsLoaded = {}
		g_modNameToDirectory = {}
		g_dlcModNameHasPrefix = {}
		g_globalMods = {}
		isReloadingDlcs = true
		startUpdatePendingMods()
		loadDlcsDirectories()
		loadDlcs()
		if isModUpdateRunning() then
			local startedRepeat = startFrameRepeatMode()
			while isModUpdateRunning() do
				usleep(16000)
			end
			if startedRepeat then
				endFrameRepeatMode()
			end
		end
		if Platform.supportsMods then
			loadAllMods()
		end
		g_inputBinding:reloadModActions()
		isReloadingDlcs = false
	end
end
function verifyDlcs()
	local missingMods = {}
	for _, mod in ipairs(g_modManager:getMods()) do
		if fileExists(mod.modFile) then
			continue
		end
		table.insert(missingMods, mod)
	end
	return #missingMods == 0, missingMods
end
function checkForNewDlcs()
	if Platform.isXbox then
		local hasNewPaths = false
		local newDlcPaths = {}
		local numDlcPaths = getNumDlcPaths()
		for i = 0, numDlcPaths - 1 do
			local path = getDlcPath(i)
			if path == nil then
				continue
			end
			newDlcPaths[path] = true
			if g_lastCheckDlcPaths[path] == nil then
				hasNewPaths = true
			end
		end
		g_lastCheckDlcPaths = newDlcPaths
		return hasNewPaths
	else
		return true
	end
end
checkForNewDlcs()
function loadDlcsDirectories()
	g_dlcsDirectories = {}
	local numDlcPaths = getNumDlcPaths()
	for i = 0, numDlcPaths - 1 do
		local path = getDlcPath(i)
		if path ~= nil then
			table.insert(g_dlcsDirectories, { path = path, isLoaded = true })
			if path == getAppBasePath() .. "pdlc/" then
				table.insert(g_dlcsDirectories, { path = "pdlc/", isLoaded = false })
			end
		elseif Platform.verboseDLCLoading then
			Logging.error("Could not retrieve dlc path %d of %d", i + 1, numDlcPaths)
		end
	end
end
loadDlcsDirectories()
function addModEventListener(listener)
	table.insert(g_modEventListeners, listener)
end
function removeModEventListener(listener)
	for i, listenerI in ipairs(g_modEventListeners) do
		if listenerI == listener then
			table.remove(g_modEventListeners, i)
			return
		end
	end
end
function createModDescSchema()
	local schema = XMLSchema.new("modDesc")
	schema:register(XMLValueType.INT, "modDesc#descVersion", "Version of the modDesc, can be used to enforce a specific game version or patch level for a mod to load", nil, true)
	schema:register(XMLValueType.STRING, "modDesc.author", "Author(s) of the mod", nil, true)
	schema:register(XMLValueType.STRING, "modDesc.version", "Version number of the mod, format 'a.b.c.d'", nil, true)
	schema:register(XMLValueType.BOOL, "modDesc.isSelectable", "If the mod is selectable in the mod selection screen", true, false)
	schema:register(XMLValueType.STRING, "modDesc.uniqueType", "A unique type of the mod. Only one mod of this type may be selected", nil, false)
	local numLangs = getNumOfLanguages()
	for i = 0, numLangs - 1 do
		local langName = getLanguageCode(i)
		schema:register(XMLValueType.STRING, string.format("modDesc.title.%s", langName), "localized title", nil, false)
		schema:register(XMLValueType.STRING, string.format("modDesc.description.%s", langName), "localized description", nil, false)
	end
	schema:register(XMLValueType.STRING, "modDesc.l10n#filenamePrefix", "prefix for external loca file. Supported xml format: l10n.texts.text#name + l10n.texts.text#text or l10n.elements.e#k + l10n.elements.e#v")
	for i = 0, numLangs - 1 do
		local langName = getLanguageCode(i)
		schema:register(XMLValueType.STRING, "modDesc.l10n.text(?)#name", "loca entry name/key", nil, false)
		schema:register(XMLValueType.STRING, string.format("modDesc.l10n.text(?).%s", langName), "localized text", nil, false)
	end
	schema:register(XMLValueType.FILENAME, "modDesc.iconFilename", "Path to the icon used for the whole mod", nil, true)
	schema:register(XMLValueType.FILENAME, "modDesc.storeItems.storeItem(?)#xmlFilename", "Path to xml file of a individual store item", nil, false)
	schema:register(XMLValueType.BOOL, "modDesc.multiplayer#supported", "Mod supports multiplayer", false, false)
	schema:register(XMLValueType.BOOL, "modDesc.multiplayer#only", "Mod is only available for multiplayer games", false, false)
	schema:register(XMLValueType.FILENAME, "modDesc.wildlife.species(?)#filename", "Mods wildlife species xml path", false, false)
	schema:register(XMLValueType.STRING, "modDesc.extraSourceFiles.sourceFile(?)#filename", "additional lua file to source", nil, false)
	SpecializationManager.registerXMLPaths(schema, "modDesc.specializations.specialization(?)")
	SpecializationManager.registerXMLPaths(schema, "modDesc.placeableSpecializations.specialization(?)")
	SpecializationManager.registerXMLPaths(schema, "modDesc.handToolSpecializations.specialization(?)")
	schema:register(XMLValueType.FILENAME, "modDesc.bales.bale(?)#filename")
	schema:register(XMLValueType.FILENAME, "modDesc.jointTypes.jointType(?)#name")
	schema:register(XMLValueType.FILENAME, "modDesc.materialHolders.materialHolder(?)#filename")
	schema:register(XMLValueType.STRING, "modDesc.maps.map(?)#id", "map id", nil, false)
	schema:register(XMLValueType.STRING, "modDesc.maps.map(?)#className", "name of the lua class to initialize for this map", nil, false)
	schema:register(XMLValueType.FILENAME, "modDesc.maps.map(?)#filename", "path to the lua file to source/load for this map", nil, false)
	schema:register(XMLValueType.FILENAME, "modDesc.maps.map(?)#configFilename", "path to the xml config file", nil, false)
	schema:register(XMLValueType.FILENAME, "modDesc.maps.map(?)#defaultVehiclesXMLFilename", "path to default vehicle xml config file", nil, false)
	schema:register(XMLValueType.FILENAME, "modDesc.maps.map(?)#defaultHandToolsXMLFilename", "path to default handtool xml config file", nil, false)
	schema:register(XMLValueType.FILENAME, "modDesc.maps.map(?)#defaultPlaceablesXMLFilename", "path to default placeable xml config file", nil, false)
	schema:register(XMLValueType.FILENAME, "modDesc.maps.map(?)#defaultItemsXMLFilename", "path to default items xml config file", nil, false)
	schema:register(XMLValueType.FILENAME, "modDesc.maps.map(?).iconFilename", "path to map icon file", nil, false)
	for i = 0, numLangs - 1 do
		local langName = getLanguageCode(i)
		schema:register(XMLValueType.STRING, string.format("modDesc.maps.map(?).title.%s", langName), "localized title", nil, false)
		schema:register(XMLValueType.STRING, string.format("modDesc.maps.map(?).description.%s", langName), "localized description", nil, false)
	end
	TypeManager.registerTypeXMLPath(schema, "modDesc.vehicleTypes.type(?)")
	TypeManager.registerTypeXMLPath(schema, "modDesc.placeableTypes.type(?)")
	TypeManager.registerTypeXMLPath(schema, "modDesc.handToolTypes.type(?)")
	schema:register(XMLValueType.STRING, "modDesc.brands.brand(?)#name")
	schema:register(XMLValueType.STRING, "modDesc.brands.brand(?)#title")
	schema:register(XMLValueType.FILENAME, "modDesc.brands.brand(?)#image")
	schema:register(XMLValueType.FLOAT, "modDesc.brands.brand(?)#imageOffset")
	schema:register(XMLValueType.FILENAME, "modDesc.connectionHoses.connectionHose(?)#xmlFilename")
	schema:register(XMLValueType.FILENAME, "modDesc.consumables.consumable(?)#xmlFilename")
	schema:register(XMLValueType.FILENAME, "modDesc.fillTypes#filename", "file path to additional fillTypes xml file", nil, false)
	schema:register(XMLValueType.FILENAME, "modDesc.missionVehicles#filename", "file path to mission vehicles xml file for he included", nil, false)
	schema:register(XMLValueType.FILENAME, "modDesc.densityMapHeightTypes#filename")
	HelpLineManager.registerCategoryXMLPaths(schema, "modDesc.helpLines.category(?)")
	VehicleMaterialManager.registerXMLPaths(schema, "modDesc.materialTemplates")
	schema:register(XMLValueType.STRING, "modDesc.actions.action(?)#name")
	schema:register(XMLValueType.STRING, "modDesc.actions.action(?)#category")
	schema:register(XMLValueType.STRING, "modDesc.actions.action(?)#displayCategory")
	schema:register(XMLValueType.STRING, "modDesc.actions.action(?)#axisType")
	schema:register(XMLValueType.BOOL, "modDesc.actions.action(?)#ignoreComboMask")
	schema:register(XMLValueType.STRING, "modDesc.inputBinding.actionBinding(?)#action")
	schema:register(XMLValueType.STRING, "modDesc.inputBinding.actionBinding(?).binding(?)#device")
	schema:register(XMLValueType.STRING, "modDesc.inputBinding.actionBinding(?).binding(?)#input")
	schema:register(XMLValueType.STRING, "modDesc.inputBinding.actionBinding(?).binding(?)#axisComponent")
	schema:register(XMLValueType.STRING, "modDesc.inputBinding.actionBinding(?).binding(?)#inputComponent")
	schema:register(XMLValueType.INT, "modDesc.inputBinding.actionBinding(?).binding(?)#neutralInput")
	schema:register(XMLValueType.INT, "modDesc.inputBinding.actionBinding(?).binding(?)#index")
	schema:register(XMLValueType.STRING, "modDesc.dependencies.dependency(?)", "filename of the mod (without '.zip') to be installed for this mod to be used")
	StoreManager.registerStoreCategoriesXMLPaths(schema, "modDesc.storeCategories.storeCategory(?)")
	return schema
end
