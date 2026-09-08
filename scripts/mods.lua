-- Local values: isReloadingDlcs, internalMods, internalScriptMods, getIsValidModDir, getIsInternalScriptMod, getIsInternalMod, getIsInternalModInfo, resolveInternalScriptModFilename
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
	["FS25_SelectableBaleCapacity"] = {
		1,
		0,
		0,
		0
	},
	["FS25_seeds_addon_crossplay"] = {
		1,
		0,
		0,
		1
	},
	["FS25_SchwesingBahnhof"] = {
		1,
		0,
		0,
		2
	},
	["FS25_simpleIC"] = {
		9,
		0,
		0,
		0
	},
	["FS25_simpleIC_fs25planet"] = {
		9,
		0,
		0,
		0
	},
	["FS25_JohnDeere7030"] = {
		1,
		1,
		0,
		0
	},
	["FS25_InfoDisplayExtension"] = {
		1,
		1,
		1,
		9
	},
	["FS25_Courseplay"] = {
		8,
		0,
		1,
		1
	},
	["Courseplay"] = {
		8,
		0,
		1,
		1
	},
	["FS25_Courseplay_FS25_main"] = {
		8,
		0,
		1,
		1
	},
	["FS25_UniversalAutoload"] = {
		0,
		4,
		5,
		7
	},
	["UniversalAutoload"] = {
		0,
		4,
		5,
		7
	},
	["FS25_UniversalAutoload_main"] = {
		0,
		4,
		5,
		8
	},
	["FS25_MUD_PARTICULES"] = {
		1,
		0,
		0,
		0
	},
	["FS25_MUD_PARTICULES__1_"] = {
		1,
		0,
		0,
		0
	},
	["FS25_MapObjectsHider"] = {
		1,
		0,
		9,
		0
	},
	["FS25_PerfectEdge"] = {
		1,
		0,
		9,
		0
	},
	["FS25_AutoDrive"] = {
		3,
		0,
		0,
		3
	},
	["FS25_ContractBoost"] = {
		1,
		0,
		9,
		0
	},
	["FS25_Financing"] = {
		1,
		0,
		0,
		1
	},
	["FS25_exhaustExtension"] = {
		1,
		0,
		0,
		2
	},
	["FS25_Contracts_Plus"] = {
		1,
		0,
		0,
		0
	},
	["FS25_precisionFarming"] = {
		1,
		3,
		1,
		0
	}
}
modOnCreate = {}
function loadDlcs()
	storeHaveDlcsChanged()
	g_modDescSchema = g_modDescSchema or createModDescSchema()
	if Platform.verboseDLCLoading then
		Logging.info("Start loading DLCs...")
	end
	local v4_ = {}
	for v5_ = 1, #g_dlcsDirectories do
		local v6_ = g_dlcsDirectories[v5_]
		if v6_.isLoaded then
			loadDlcsFromDirectory(v6_.path, v4_)
		end
	end
	if Platform.verboseDLCLoading then
		Logging.info("Finished loading DLCs.")
	end
end

-- Local values: appBasePath, files, _, v, addDLCPrefix, dlcFileHash, dlcName, xmlFilename, len, ext, dlcDir, dlcFile
function loadDlcsFromDirectory(dlcsDir, loadedDlcs)
	if Platform.verboseDLCLoading then
		Logging.info("Try to load dlcs from directory \'%s\'", dlcsDir)
	end
	local v8_ = getAppBasePath()
	if isAbsolutePath(dlcsDir) and (v8_:len() == 0 or not string.startsWith(dlcsDir, v8_)) then
		createFolder(dlcsDir)
	end
	local v9_ = Files.new(dlcsDir)
	for _, v10_ in pairs(v9_.files) do
		if Platform.verboseDLCLoading then
			Logging.info("Trying to load dlc file %s", v10_.filename)
		end
		local v11_ = false
		local v12_ = nil
		local v13_ = nil
		local v14_ = nil
		if v10_.isDirectory then
			if g_isDevelopmentVersion or not GS_PLATFORM_PC then
				v13_ = v10_.filename
				v14_ = "dlcDesc.xml"
				v11_ = true
				if not GS_PLATFORM_PC then
					v12_ = getFileMD5(dlcsDir .. v10_.filename, v13_)
				end
				if v12_ == nil and g_isDevelopmentVersion then
					v12_ = getMD5("Dev_" .. v10_.filename)
				end
			end
		else
			local v15_ = v10_.filename:len()
			if v15_ > 4 then
				local v16_ = v10_.filename:sub(v15_ - 3)
				if v16_ == ".dlc" then
					v13_ = v10_.filename:sub(1, v15_ - 4)
					v12_ = getFileMD5(dlcsDir .. v10_.filename, v13_)
					v14_ = "dlcDesc.xml"
					v11_ = true
				elseif v16_ == ".zip" or v16_ == ".gar" then
					v13_ = v10_.filename:sub(1, v15_ - 4)
					v12_ = getFileMD5(dlcsDir .. v10_.filename, v13_)
					v14_ = "modDesc.xml"
					v11_ = false
				end
			end
		end
		if v13_ ~= nil and (v14_ ~= nil and g_dlcModNameHasPrefix[v13_] == nil) then
			local v17_ = dlcsDir .. v13_ .. "/"
			local v18_ = v17_ .. v14_
			g_dlcModNameHasPrefix[v13_] = v11_
			loadModDesc(v13_, v17_, v18_, v12_, dlcsDir .. v10_.filename, v10_.isDirectory, v11_, false)
		end
	end
end
function loadAllMods()
	loadInternalMods()
	loadMods()
	haveModsChanged()
end
function loadMods()
	local v19_ = g_modsDirectory
	g_showIllegalActivityInfo = false
	local v20_ = Files.new(v19_)
	local v21_ = {}
	for _, v22_ in pairs(v20_.files) do
		local v23_ = nil
		local v24_ = nil
		if v22_.isDirectory then
			v24_ = v22_.filename
			if g_isDevelopmentVersion then
				v23_ = getMD5("DevMod_" .. v22_.filename)
			end
		else
			local v25_ = v22_.filename:len()
			if v25_ > 4 then
				local v26_ = v22_.filename:sub(v25_ - 3)
				if v26_ == ".zip" or v26_ == ".gar" then
					v24_ = v22_.filename:sub(1, v25_ - 4)
					v23_ = getFileMD5(v19_ .. v22_.filename, v24_)
				end
			end
		end
		if v24_ ~= nil then
			local v27_ = v19_ .. v24_ .. "/"
			local v28_ = v27_ .. "modDesc.xml"
			if v21_[v28_] == nil then
				loadModDesc(v24_, v27_, v28_, v23_, v19_ .. v22_.filename, v22_.isDirectory, false, false)
				v21_[v28_] = true
			end
		end
	end
	if g_showIllegalActivityInfo then
		print("Info: This game protects you from illegal activity")
	end
	g_showIllegalActivityInfo = nil
end
function loadInternalMods()
	-- upvalues: (copy) internalMods
	for _, v29_ in ipairs(internalMods) do
		local v30_ = v29_.name
		local v31_ = g_internalModsDirectory .. v30_ .. "/"
		local v32_ = v31_ .. "modDesc.xml"
		local v33_ = nil
		local v34_ = g_internalModsDirectory .. v30_ .. ".gar"
		if fileExists(v34_) then
			v33_ = getFileMD5(v34_, v30_)
		elseif (g_isDevelopmentVersion or GS_IS_CONSOLE_VERSION) and fileExists(v32_) then
			v33_ = getFileMD5(v32_, v30_)
		end
		if v33_ ~= nil then
			loadModDesc(v30_, v31_, v32_, v33_, g_internalModsDirectory .. v30_, true, false, true)
		end
	end
end
function postInitMods()
	for _, v35_ in ipairs(g_modEventListeners) do
		if v35_.onPostInit ~= nil then
			v35_:onPostInit()
		end
	end
end
local function v_u_37_(p36_)
	if p36_:len() == 0 then
		return false
	elseif string.startsWith(p36_, g_uniqueDlcNamePrefix) then
		return false
	elseif p36_:find("%d") == 1 then
		return false
	else
		return p36_:find("[^%w_]") == nil
	end
end
local function v_u_41_(p38_)
	-- upvalues: (copy) internalScriptMods
	for v39_ = 1, #internalScriptMods do
		local v40_ = internalScriptMods[v39_]
		if p38_ == v40_ or p38_ == v40_ .. "_update" then
			return true
		end
	end
	return false
end
local function v_u_45_(p42_)
	-- upvalues: (copy) internalMods
	for _, v43_ in ipairs(internalMods) do
		local v44_ = v43_.name
		if p42_ == v44_ or p42_ == v44_ .. "_update" then
			return true
		end
	end
	return false
end
local function v_u_49_(p46_)
	-- upvalues: (copy) internalMods
	for _, v47_ in ipairs(internalMods) do
		local v48_ = v47_.name
		if p46_ == v48_ or p46_ == v48_ .. "_update" then
			return v47_
		end
	end
	return nil
end
local function v_u_55_(p50_, p51_, p52_)
	-- upvalues: (copy) internalScriptMods
	if p50_:sub(1, p52_:len()) == p52_ then
		for v53_ = 1, #internalScriptMods do
			local v54_ = internalScriptMods[v53_]
			if (p51_ == v54_ or p51_ == v54_ .. "_update") and (not fileExists(p50_) or GS_IS_CONSOLE_VERSION) then
				return "dataS/scripts/internalMods/" .. v54_ .. "/" .. p50_:sub(p52_:len() + 1)
			end
		end
	end
	return p50_
end

-- Upvalues: getIsValidModDir, getIsInternalModInfo, isReloadingDlcs, resolveInternalScriptModFilename, getIsInternalScriptMod
-- Local values: origModName, isDLCFile, revision, settingsXML, xmlFile, modVersion, versionStr, modInfo, hashStr, revisionStr, modDescVersion, requiredModName, isSelectable, modEnv, modEnv_mt, gEnv, orgGetfenv, userProfilePath, sub, len, protectedDelete, onCreateUtil, _, baseName, name, text, l10nFilenamePrefix, l10nFilenamePrefixFull, l10nXmlFile, l10nFilename, langs, _, lang, _, key, name, text, _, key, name, text, title, desc, iconFilename, isMultiplayerSupported, isOnlyMultiplayerSupported, _, baseName, author, dlcProductId, hasScripts, dependencies, index, key, name, uniqueType, _, xmlKey, key, item, errorCode, _, key, filename
function loadModDesc(modName, modDir, modFile, modFileHash, absBaseFilename, isDirectory, addDLCPrefix, isInternalMod)
	-- upvalues: (copy) v_u_37_, (copy) v_u_49_, (ref) isReloadingDlcs, (copy) v_u_55_, (copy) v_u_41_
	if not v_u_37_(modName) then
		printError("Error: Invalid mod name \'" .. modName .. "\'! Characters allowed: (_, A-Z, a-z, 0-9). The first character must not be a digit")
		return
	end
	local v64_ = modName
	if addDLCPrefix then
		modName = g_uniqueDlcNamePrefix .. modName
	end
	if g_modNameToDirectory[modName] ~= nil then
		Logging.error("Mod name \'" .. modName .. "\' already in use. Ignore it!")
		return
	end
	g_modNameToDirectory[modName] = modDir
	local v65_ = nil
	local v66_
	if string.endsWith(modFile, "dlcDesc.xml") then
		v66_ = true
		if not fileExists(modFile) then
			if GS_IS_EPIC_VERSION and string.startsWith(modDir, getAppBasePath() .. "pdlc/") then
				print("Info: No license for dlc " .. modName .. ".")
			else
				printError("Error: No license for dlc " .. modName .. ". Please reinstall.")
			end
			return
		end
		local v67_ = XMLFile.loadIfExists("DLC SettingsFile", modDir .. "settings.xml")
		if v67_ ~= nil then
			v65_ = v67_:getString("settings#revision", "Unknown")
			v67_:delete()
		end
	else
		v66_ = false
	end
	setModInstalled(absBaseFilename, addDLCPrefix)
	local v68_ = XMLFile.load("ModFile", modFile, g_modDescSchema)
	if v68_ == nil then
		return
	end
	local v69_ = v68_:getString("modDesc.version")
	local v70_ = (v69_ == nil or v69_ == "") and "" or " (Version: " .. v69_ .. ")"
	if isInternalMod and v69_ ~= v_u_49_(modName).version then
		printError("Error: Outdated mod version in mod " .. modName)
		v68_:delete()
		return
	end
	local v71_ = modFileHash == nil and "" or "(Hash: " .. modFileHash .. ")"
	if v66_ then
		local v72_ = v65_ == nil and "" or string.format(" (Revision: %s)", v65_)
		print("Available dlc: " .. v71_ .. v70_ .. " " .. modName .. v72_)
	else
		print("Available mod: " .. v71_ .. v70_ .. " " .. modName)
	end
	local v73_ = v68_:getInt("modDesc#descVersion")
	if v73_ == nil then
		printError("Error: Missing descVersion attribute in mod " .. modName)
		v68_:delete()
		return
	end
	if v73_ < g_minModDescVersion or g_maxModDescVersion < v73_ then
		printError("Error: Unsupported mod description version in mod " .. modName)
		v68_:delete()
		return
	end
	if _G[modName] ~= nil and not isReloadingDlcs then
		printError("Error: Invalid mod name \'" .. modName .. "\'")
		v68_:delete()
		return
	end
	if v66_ then
		local v74_ = v68_:getString("modDesc.multiplayer#requiredModName")
		if v74_ ~= nil and v74_ ~= v64_ then
			printError("Error: Do not rename dlcs. Name: \'" .. v64_ .. "\'. Expect: \'" .. v74_ .. "\'")
			v68_:delete()
			return
		end
	end
	local v75_ = v68_:getBool("modDesc.isSelectable", true)
	local v_u_76_ = {}
	if GS_IS_CONSOLE_VERSION then
		v_u_76_ = Utils.getNoNil(_G[modName], v_u_76_)
	end
	g_globalsNameCheckDisabled = true
	_G[modName] = v_u_76_
	g_globalsNameCheckDisabled = false
	local v77_ = {
		["__index"] = _G
	}
	setmetatable(v_u_76_, v77_)
	if not (v66_ or isInternalMod) then
		v_u_76_._G = v_u_76_
	end
	local v_u_78_ = _G
	local v_u_79_ = getfenv
	function v_u_76_.getfenv(p80_)
		-- upvalues: (copy) v_u_79_, (copy) v_u_78_, (ref) v_u_76_
		local v81_ = v_u_79_(p80_)
		if v81_ == v_u_78_ then
			return v_u_76_
		else
			return v81_
		end
	end
	v_u_76_.g_i18n = g_i18n:addModI18N(modName)
	function v_u_76_.loadstring(p82_, p83_)
		-- upvalues: (ref) modName
		local v84_ = "setfenv(1," .. modName .. "); " .. p82_
		return loadstring(v84_, p83_)
	end
	function v_u_76_.source(p85_, _)
		-- upvalues: (copy) isInternalMod, (ref) v_u_55_, (ref) modName, (copy) modDir
		if isAbsolutePath(p85_) or isInternalMod then
			local v86_ = v_u_55_(p85_, modName, modDir)
			source(v86_, modName)
		else
			source(p85_)
		end
	end
	function v_u_76_.InitEventClass(p87_, p88_)
		-- upvalues: (ref) modName
		InitEventClass(p87_, modName .. "." .. p88_)
	end
	function v_u_76_.InitObjectClass(p89_, p90_)
		-- upvalues: (ref) modName
		InitObjectClass(p89_, modName .. "." .. p90_)
	end
	function v_u_76_.registerObjectClassName(p91_, p92_)
		-- upvalues: (ref) modName
		registerObjectClassName(p91_, modName .. "." .. p92_)
	end
	v_u_76_.g_constructionBrushTypeManager = {}
	local function v97_(_, p93_, p94_, p95_, p96_)
		-- upvalues: (copy) isInternalMod, (ref) v_u_55_, (ref) modName, (copy) modDir
		if isAbsolutePath(p95_) or isInternalMod then
			p95_ = v_u_55_(p95_, modName, modDir)
			p96_ = modName
			p93_ = modName .. "." .. p93_
			p94_ = modName .. "." .. p94_
		end
		g_constructionBrushTypeManager:addBrushType(p93_, p94_, p95_, p96_)
	end
	v_u_76_.g_constructionBrushTypeManager.addBrushType = v97_
	
-- Upvalues: modName
-- Local values: classObj
function v_u_76_.g_constructionBrushTypeManager.getClassObjectByTypeName(self, typeName)
		-- upvalues: (ref) modName
		local v99_ = g_constructionBrushTypeManager:getClassObjectByTypeName(typeName)
		if v99_ == nil then
			v99_ = g_constructionBrushTypeManager:getClassObjectByTypeName(modName .. "." .. typeName)
		end
		return v99_
	end
	local v100_ = v_u_76_.g_constructionBrushTypeManager
	local v101_ = {
		["__index"] = g_constructionBrushTypeManager
	}
	setmetatable(v100_, v101_)
	v_u_76_.g_specializationManager = {}
	local function v108_(p102_, p103_, p104_, p105_, p106_, ...)
		-- upvalues: (copy) isInternalMod, (ref) v_u_55_, (ref) modName, (copy) modDir
		if type(p102_) ~= "table" then
			Logging.error("Invalid self object given for (Vehicle) SpecializationManager.addSpecialization. Usage: \'g_specializationManager:addSpecialization(name, className, filename, customEnvironment)\'")
			printCallstack()
		end
		if p106_ ~= nil and type(p106_) ~= "string" then
			Logging.error("Invalid customEnvironment given for (Vehicle) SpecializationManager.addSpecialization. Should be a string or nil.")
			printCallstack()
		end
		if select("#", ...) > 0 then
			Logging.error("Too many arguments for (Vehicle) SpecializationManager.addSpecialization. (Arguments should be: name, className, filename, customEnvironment)")
			printCallstack()
		end
		if isAbsolutePath(p105_) or isInternalMod then
			p105_ = v_u_55_(p105_, modName, modDir)
			p106_ = modName
			p103_ = modName .. "." .. p103_
			p104_ = modName .. "." .. p104_
		end
		local v107_ = Utils.getFilenameFromPath(p105_)
		if v107_ == "AddConfig.lua" and p106_ ~= nil then
			Logging.error("Loading file \'%s\' of mod \'%s\' was blocked because it is not compatible with Farming Simulator 25", v107_, p106_)
		else
			g_specializationManager:addSpecialization(p103_, p104_, p105_, p106_)
		end
	end
	v_u_76_.g_specializationManager.addSpecialization = v108_
	
-- Upvalues: modName
-- Local values: spec

-- Upvalues: modName
-- Local values: spec

-- Upvalues: modName
-- Local values: spec
function v_u_76_.g_specializationManager.getSpecializationByName(self, name)
		-- upvalues: (ref) modName
		local v110_ = g_specializationManager:getSpecializationByName(name)
		if v110_ == nil then
			v110_ = g_specializationManager:getSpecializationByName(modName .. "." .. name)
		end
		return v110_
	end
	
-- Upvalues: modName
-- Local values: spec
function v_u_76_.g_specializationManager.getSpecializationObjectByName(self, name)
		-- upvalues: (ref) modName
		local v112_ = g_specializationManager:getSpecializationObjectByName(name)
		if v112_ == nil then
			v112_ = g_specializationManager:getSpecializationObjectByName(modName .. "." .. name)
		end
		return v112_
	end
	local v113_ = v_u_76_.g_specializationManager
	local v114_ = {
		["__index"] = g_specializationManager
	}
	setmetatable(v113_, v114_)
	v_u_76_.g_placeableSpecializationManager = {}
	local function v120_(p115_, p116_, p117_, p118_, p119_, ...)
		-- upvalues: (copy) isInternalMod, (ref) v_u_55_, (ref) modName, (copy) modDir
		if type(p115_) ~= "table" then
			Logging.error("Invalid self object given for (Placeable) SpecializationManager.addSpecialization. Usage: \'g_placeableSpecializationManager:addSpecialization(name, className, filename, customEnvironment)\'")
			printCallstack()
		end
		if p119_ ~= nil and type(p119_) ~= "string" then
			Logging.error("Invalid customEnvironment given for (Placeable) SpecializationManager.addSpecialization. Should be a string or nil.")
			printCallstack()
		end
		if select("#", ...) > 0 then
			Logging.error("Too many arguments for (Placeable) SpecializationManager.addSpecialization. (Arguments should be: name, className, filename, customEnvironment)")
			printCallstack()
		end
		if isAbsolutePath(p118_) or isInternalMod then
			p118_ = v_u_55_(p118_, modName, modDir)
			p119_ = modName
			p116_ = modName .. "." .. p116_
			p117_ = modName .. "." .. p117_
		end
		g_placeableSpecializationManager:addSpecialization(p116_, p117_, p118_, p119_)
	end
	v_u_76_.g_placeableSpecializationManager.addSpecialization = v120_
	function v_u_76_.g_placeableSpecializationManager.getSpecializationByName(_, p121_)
		-- upvalues: (ref) modName
		local v122_ = g_placeableSpecializationManager:getSpecializationByName(p121_)
		if v122_ == nil then
			v122_ = g_placeableSpecializationManager:getSpecializationByName(modName .. "." .. p121_)
		end
		return v122_
	end
	local v123_ = v_u_76_.g_placeableSpecializationManager
	local v124_ = {
		["__index"] = g_placeableSpecializationManager
	}
	setmetatable(v123_, v124_)
	v_u_76_.g_handToolSpecializationManager = {}
	local function v130_(p125_, p126_, p127_, p128_, p129_, ...)
		-- upvalues: (copy) isInternalMod, (ref) v_u_55_, (ref) modName, (copy) modDir
		if type(p125_) ~= "table" then
			Logging.error("Invalid self object given for SpecializationManager.addSpecialization. Usage: \'g_handToolSpecializationManager:addSpecialization(name, className, filename, customEnvironment)\'")
			printCallstack()
		end
		if p129_ ~= nil and type(p129_) ~= "string" then
			Logging.error("Invalid customEnvironment given for (HandTool) SpecializationManager.addSpecialization. Should be a string or nil.")
			printCallstack()
		end
		if select("#", ...) > 0 then
			Logging.error("Too many arguments for (HandTool) SpecializationManager.addSpecialization. (Arguments should be: name, className, filename, customEnvironment)")
			printCallstack()
		end
		if isAbsolutePath(p128_) or isInternalMod then
			p128_ = v_u_55_(p128_, modName, modDir)
			p129_ = modName
			p126_ = modName .. "." .. p126_
			p127_ = modName .. "." .. p127_
		end
		g_handToolSpecializationManager:addSpecialization(p126_, p127_, p128_, p129_)
	end
	v_u_76_.g_handToolSpecializationManager.addSpecialization = v130_
	function v_u_76_.g_handToolSpecializationManager.getSpecializationByName(_, p131_)
		-- upvalues: (ref) modName
		local v132_ = g_handToolSpecializationManager:getSpecializationByName(p131_)
		if v132_ == nil then
			v132_ = g_handToolSpecializationManager:getSpecializationByName(modName .. "." .. p131_)
		end
		return v132_
	end
	local v133_ = v_u_76_.g_handToolSpecializationManager
	local v134_ = {
		["__index"] = g_handToolSpecializationManager
	}
	setmetatable(v133_, v134_)
	v_u_76_.g_vehicleTypeManager = {}
	local function v139_(_, p135_, p136_, p137_, p138_)
		-- upvalues: (copy) isInternalMod, (ref) v_u_55_, (ref) modName, (copy) modDir
		if isAbsolutePath(p137_) or isInternalMod then
			p137_ = v_u_55_(p137_, modName, modDir)
			p138_ = modName
			p135_ = modName .. "." .. p135_
			p136_ = modName .. "." .. p136_
		end
		g_vehicleTypeManager:addType(p135_, p136_, p137_, p138_)
	end
	v_u_76_.g_vehicleTypeManager.addType = v139_
	
-- Upvalues: modName
-- Local values: spec

-- Upvalues: modName
-- Local values: spec

-- Upvalues: modName
-- Local values: spec
function v_u_76_.g_vehicleTypeManager.addSpecialization(self, typeName, specName)
		-- upvalues: (ref) modName
		if g_specializationManager:getSpecializationByName(specName) == nil and g_specializationManager:getSpecializationByName(modName .. "." .. specName) ~= nil then
			specName = modName .. "." .. specName
		end
		g_vehicleTypeManager:addSpecialization(typeName, specName)
	end
	local v142_ = v_u_76_.g_vehicleTypeManager
	local v143_ = {
		["__index"] = g_vehicleTypeManager
	}
	setmetatable(v142_, v143_)
	v_u_76_.g_placeableTypeManager = {}
	local function v148_(_, p144_, p145_, p146_, p147_)
		-- upvalues: (copy) isInternalMod, (ref) v_u_55_, (ref) modName, (copy) modDir
		if isAbsolutePath(p146_) or isInternalMod then
			p146_ = v_u_55_(p146_, modName, modDir)
			p147_ = modName
			p144_ = modName .. "." .. p144_
			p145_ = modName .. "." .. p145_
		end
		g_placeableTypeManager:addType(p144_, p145_, p146_, p147_)
	end
	v_u_76_.g_placeableTypeManager.addType = v148_
	function v_u_76_.g_placeableTypeManager.addSpecialization(_, p149_, p150_)
		-- upvalues: (ref) modName
		if g_placeableSpecializationManager:getSpecializationByName(p150_) == nil and g_placeableSpecializationManager:getSpecializationByName(modName .. "." .. p150_) ~= nil then
			p150_ = modName .. "." .. p150_
		end
		g_placeableTypeManager:addSpecialization(p149_, p150_)
	end
	local v151_ = v_u_76_.g_placeableTypeManager
	local v152_ = {
		["__index"] = g_placeableTypeManager
	}
	setmetatable(v151_, v152_)
	v_u_76_.g_handToolTypeManager = {}
	local function v157_(_, p153_, p154_, p155_, p156_)
		-- upvalues: (copy) isInternalMod, (ref) v_u_55_, (ref) modName, (copy) modDir
		if isAbsolutePath(p155_) or isInternalMod then
			p155_ = v_u_55_(p155_, modName, modDir)
			p156_ = modName
			p153_ = modName .. "." .. p153_
			p154_ = modName .. "." .. p154_
		end
		g_handToolTypeManager:addType(p153_, p154_, p155_, p156_)
	end
	v_u_76_.g_handToolTypeManager.addType = v157_
	function v_u_76_.g_handToolTypeManager.addSpecialization(_, p158_, p159_)
		-- upvalues: (ref) modName
		if g_handToolSpecializationManager:getSpecializationByName(p159_) == nil and g_handToolSpecializationManager:getSpecializationByName(modName .. "." .. p159_) ~= nil then
			p159_ = modName .. "." .. p159_
		end
		g_handToolTypeManager:addSpecialization(p158_, p159_)
	end
	local v160_ = v_u_76_.g_handToolTypeManager
	local v161_ = {
		["__index"] = g_handToolTypeManager
	}
	setmetatable(v160_, v161_)
	v_u_76_.g_effectManager = {}
	
-- Upvalues: modName
function v_u_76_.g_effectManager.registerEffectClass(self, className, effectClass)
		-- upvalues: (ref) modName
		if ClassUtil.getIsValidClassName(className) then
			_G.g_effectManager:registerEffectClass(modName .. "." .. className, effectClass)
		else
			printError("Error: Invalid effect class name: " .. className)
		end
	end
	
-- Upvalues: modName
-- Local values: effectClass
function v_u_76_.g_effectManager.getEffectClass(self, className)
		-- upvalues: (ref) modName
		local v165_ = _G.g_effectManager:getEffectClass(className)
		if v165_ == nil then
			v165_ = _G.g_effectManager:getEffectClass(modName .. "." .. className)
		end
		return v165_
	end
	local v166_ = v_u_76_.g_effectManager
	local v167_ = {
		["__index"] = _G.g_effectManager
	}
	setmetatable(v166_, v167_)
	local v_u_168_ = getUserProfileAppPath()
	local v_u_169_ = string.sub
	local v_u_170_ = string.len
	local function v174_(p_u_171_)
		-- upvalues: (copy) v_u_168_, (ref) modName, (copy) v_u_170_, (copy) v_u_169_
		return function(p172_)
			-- upvalues: (ref) v_u_168_, (ref) modName, (ref) v_u_170_, (ref) v_u_169_, (copy) p_u_171_
			local v173_ = v_u_168_ .. "modSettings/" .. modName
			if v_u_169_(p172_, 1, (v_u_170_(v173_))) == v173_ then
				p_u_171_(p172_)
			else
				printError(string.format("Error: No access to folder \'%s\'", p172_))
				print(string.format("Info: Mod has full access in \'%s\'", v173_))
				printCallstack()
			end
		end
	end
	v_u_76_.g_adsSystem = {}
	v_u_76_.InitStaticEventClass = ""
	v_u_76_.InitStaticObjectClass = ""
	v_u_76_.loadMod = ""
	v_u_76_.loadModDesc = ""
	v_u_76_.loadDlcs = ""
	v_u_76_.loadDlcsFromDirectory = ""
	v_u_76_.loadMods = ""
	v_u_76_.reloadDlcsAndMods = ""
	v_u_76_.verifyDlcs = ""
	v_u_76_.deleteFile = v174_(deleteFile)
	v_u_76_.deleteFolder = v174_(deleteFolder)
	v_u_76_.isAbsolutePath = isAbsolutePath
	v_u_76_.g_isDevelopmentVersion = g_isDevelopmentVersion
	v_u_76_.GS_IS_CONSOLE_VERSION = GS_IS_CONSOLE_VERSION
	if not (v66_ or isInternalMod) then
		v_u_76_.ClassUtil = {}
		
-- Upvalues: modName
-- Local values: classModName
function v_u_76_.ClassUtil.getClassModName(self, className)
			-- upvalues: (ref) modName
			local v176_ = _G.ClassUtil.getClassModName(className)
			if v176_ == nil then
				v176_ = _G.ClassUtil.getClassModName(modName .. "." .. className)
			end
			return v176_
		end
	end
	local v_u_177_ = {
		["onCreateFunctions"] = {}
	}
	v_u_76_.g_onCreateUtil = v_u_177_
	
-- Upvalues: onCreateUtil
function v_u_177_.addOnCreateFunction(name, func)
		-- upvalues: (copy) v_u_177_
		v_u_177_.onCreateFunctions[name] = func
	end
	function v_u_177_.activateOnCreateFunctions()
		-- upvalues: (copy) v_u_177_
		for v180_, v_u_181_ in pairs(v_u_177_.onCreateFunctions) do
			modOnCreate[v180_] = function(_, p182_)
				-- upvalues: (copy) v_u_181_
				v_u_181_(p182_)
			end
		end
	end
	function v_u_177_.deactivateOnCreateFunctions()
		-- upvalues: (copy) v_u_177_
		for v183_, _ in pairs(v_u_177_.onCreateFunctions) do
			modOnCreate[v183_] = nil
		end
	end
	for _, v184_ in v68_:iterator("modDesc.l10n.text") do
		local v185_ = v68_:getString(v184_ .. "#name")
		local v186_ = v68_:getString(v184_ .. "." .. g_languageShort) or (v68_:getString(v184_ .. ".en") or v68_:getString(v184_ .. ".de"))
		if v186_ == nil or v185_ == nil then
			printWarning("Warning: No l10n text found for entry \'" .. v185_ .. "\' in mod \'" .. modName .. "\'")
		elseif v_u_76_.g_i18n:hasModText(v185_) then
			printWarning("Warning: Duplicate l10n entry \'" .. v185_ .. "\' in mod \'" .. modName .. "\'. Ignoring this definition.")
		else
			v_u_76_.g_i18n:setText(v185_, v186_)
		end
	end
	local v187_ = v68_:getString("modDesc.l10n#filenamePrefix")
	if v187_ ~= nil then
		local v188_ = Utils.getFilename(v187_, modDir)
		local v189_ = { g_languageShort, "en", "de" }
		local v190_ = nil
		local v191_ = nil
		for _, v192_ in ipairs(v189_) do
			v190_ = v188_ .. "_" .. v192_ .. ".xml"
			if fileExists(v190_) then
				v191_ = XMLFile.load("modL10n", v190_)
				break
			end
		end
		if v191_ == nil then
			printWarning(string.format("Warning: No l10n file(s) found for prefix %q\' (e.g. \'%sen.xml\') in mod %q", v187_, v187_, modName))
		else
			for _, v193_ in v191_:iterator("l10n.texts.text") do
				local v194_ = v191_:getString(v193_ .. "#name")
				local v195_ = v191_:getString(v193_ .. "#text")
				if v194_ ~= nil and v195_ ~= nil then
					if v_u_76_.g_i18n:hasModText(v194_) then
						printWarning("Warning: Duplicate l10n entry \'" .. v194_ .. "\' in \'" .. v190_ .. "\'. Ignoring this definition.")
					else
						v_u_76_.g_i18n:setText(v194_, v195_:gsub("\r\n", "\n"))
					end
				end
			end
			for _, v196_ in v191_:iterator("l10n.elements.e") do
				local v197_ = v191_:getString(v196_ .. "#k")
				local v198_ = v191_:getString(v196_ .. "#v")
				if v197_ ~= nil and v198_ ~= nil then
					if v_u_76_.g_i18n:hasModText(v197_) then
						printWarning("Warning: Duplicate l10n entry \'" .. v197_ .. "\' in \'" .. v190_ .. "\'. Ignoring this definition.")
					else
						v_u_76_.g_i18n:setText(v197_, v198_:gsub("\r\n", "\n"))
					end
				end
			end
			v191_:delete()
		end
	end
	local v199_ = v68_:getI18NValue("modDesc.title", "", modName, true)
	local v200_ = v68_:getI18NValue("modDesc.description", "", modName, true)
	local v201_ = v68_:getI18NValue("modDesc.iconFilename", "", modName, true)
	if v199_ == "" then
		printError("Error: Missing title in mod " .. modName)
		v68_:delete()
		return
	elseif v200_ == "" then
		printError("Error: Missing description in mod " .. modName)
		v68_:delete()
		return
	else
		local v202_ = v68_:getBool("modDesc.multiplayer#supported", false)
		local v203_ = v68_:getBool("modDesc.multiplayer#only", false)
		if modFileHash == nil then
			if Platform.supportsMultiplayer and v202_ then
				printWarning("Warning: Only zip mods are supported in multiplayer. You need to zip the mod " .. modName .. " to use it in multiplayer.")
				v202_ = false
			else
				v202_ = false
			end
		end
		if v202_ or not v203_ then
			if v202_ and v201_ == "" then
				printError("Error: Missing icon filename in mod " .. modName)
				v68_:delete()
			else
				for _, v204_ in v68_:iterator("modDesc.maps.map") do
					g_mapManager:loadMapFromXML(v68_, v204_, modDir, modName, v202_, v66_, true, isInternalMod)
				end
				local v205_ = v68_:getI18NValue("modDesc.author", "", modName, true)
				if v66_ then
					local v206_ = v68_:getString("modDesc.productId")
					if v206_ == nil or v69_ == nil then
						printError("Error: invalid product id or version in DLC " .. modName)
					else
						addNotificationFilter(v206_, v69_)
					end
				end
				local v207_ = v68_:hasProperty("modDesc.extraSourceFiles.sourceFile(0)") or v68_:hasProperty("modDesc.specializations.specialization(0)")
				local v208_
				if v68_:hasProperty("modDesc.dependencies.dependency(0)") then
					v208_ = {}
					for _, v209_ in v68_:iterator("modDesc.dependencies.dependency") do
						local v210_ = v68_:getString(v209_)
						if string.isNilOrWhitespace(v210_) then
							printWarning(string.format("Warning: mod %q has empty dependency at %q", modName, v209_))
						elseif string.endsWith(v210_, ".zip") then
							printWarning(string.format("Warning: mod %q dependency %q at %q should not include \'.zip\' in its name", modName, v210_, v209_))
						elseif not table.addElement(v208_, v210_) then
							printWarning(string.format("Warning: mod %q has duplicate dependency %q at %q", modName, v210_, v209_))
						end
					end
				else
					v208_ = nil
				end
				local v211_ = v68_:getString("modDesc.uniqueType")
				for _, v212_ in v68_:iterator("modDesc.extraContent.key") do
					local v213_ = v68_:getString(v212_)
					if v213_ ~= nil then
						local v214_, v215_ = g_extraContentSystem:unlockItem(v213_, true)
						if v214_ ~= nil and v215_ == ExtraContentSystem.UNLOCKED then
							print("ExtraContent: Unlocked \'" .. v214_.id .. "\'")
							g_extraContentSystem:saveToProfile()
						end
					end
				end
				if isInternalMod then
					g_currentModDirectory = modDir
					g_currentModName = modName
					for _, v216_ in v68_:iterator("modDesc.preLoadSourceFiles.sourceFile") do
						local v217_ = v68_:getString(v216_ .. "#filename")
						if v217_ ~= nil then
							v_u_76_.source(modDir .. v217_, modName)
						end
					end
					g_currentModDirectory = nil
					g_currentModName = nil
				end
				local v218_ = Utils.getFilename(v201_, modDir)
				g_modManager:addMod(v199_, v200_, v69_, v73_, v205_, v218_, modName, modDir, modFile, v202_, modFileHash, absBaseFilename, isDirectory, v66_, v207_, v208_, v203_, v75_, v211_, v_u_41_(modName))
				v68_:delete()
			end
		else
			printError("Error: Both multiplayer and singleplayer are unsupported in mod " .. modName)
			v68_:delete()
			return
		end
	end
end
function resetModOnCreateFunctions()
	modOnCreate = {}
end

-- Upvalues: getIsInternalScriptMod, getIsInternalMod
-- Local values: modEnv, xmlFile, isDLCFile, allowScripts, _, key, filename, _, key, name, title, image, offset, _, key, _, key, _, key, specName, className, filename, _, key, _, key, specName, className, filename, _, key, _, key, specName, className, filename, _, key, _, key, _, key, name, _, key, filename, _, key, xmlFilename, _, key, xmlFilename, _, key, storeItemXMLFilename, _, key, name, title, imageFilename, storeItems, _, storeItemKey, xmlFilename, fullXmlFilename, defaultIconFilename, defaultRefSize, _, key, categoryName, tabName, tabTitle, tabIconFilename, tabRefSize, tabIconUVs, tabIconSliceId, fillTypesFilename, filename, _, densityMapHeightTypesFilename, filename, motionPathEffectsFilename, filename, _, key, name, filename, missionVehiclesFilename, _, key, speciesFilename, groupNames
function loadMod(modName, modDir, modFile, modTitle)
	-- upvalues: (copy) v_u_41_, (copy) v_u_45_
	if g_modIsLoaded[modName] then
		return
	else
		g_modIsLoaded[modName] = true
		g_modNameToDirectory[modName] = modDir
		local v223_ = _G[modName]
		if v223_ ~= nil then
			local v224_ = XMLFile.load("ModFile", modFile, g_modDescSchema)
			local v225_ = string.endsWith(modFile, "dlcDesc.xml") and true or false
			if v225_ then
				print("  Load dlc: " .. modName)
			else
				print("  Load mod: " .. modName)
			end
			local v226_ = not GS_IS_CONSOLE_VERSION or (v225_ or g_isDevelopmentConsoleScriptModTesting) or (v_u_41_(modName) or v_u_45_(modName))
			g_currentModDirectory = modDir
			g_currentModName = modName
			if g_modSettingsDirectory ~= nil then
				g_currentModSettingsDirectory = g_modSettingsDirectory .. modName .. "/"
			end
			if v226_ then
				for _, v227_ in v224_:iterator("modDesc.extraSourceFiles.sourceFile") do
					local v228_ = v224_:getString(v227_ .. "#filename")
					if v228_ ~= nil then
						v223_.source(modDir .. v228_, modName)
					end
				end
			end
			for _, v229_ in v224_:iterator("modDesc.brands.brand") do
				local v230_ = v224_:getString(v229_ .. "#name")
				local v231_ = v224_:getString(v229_ .. "#title")
				local v232_ = v224_:getString(v229_ .. "#image")
				local v233_ = v224_:getFloat(v229_ .. "#imageOffset")
				g_brandManager:addBrand(v230_, v231_, v232_, modDir, true, nil, v233_)
			end
			for _, v234_ in v224_:iterator("modDesc.helpLines.category") do
				g_helpLineManager:addModCategory(v224_, v234_, modDir, modName)
			end
			if v225_ then
				for _, v235_ in v224_:iterator("modDesc.storeCategories.storeCategory") do
					g_storeManager:loadCategoryFromXML(v224_, v235_, modDir, modName, true)
				end
			end
			for _, v236_ in v224_:iterator("modDesc.specializations.specialization") do
				local v237_ = v224_:getString(v236_ .. "#name")
				local v238_ = v224_:getString(v236_ .. "#className")
				local v239_ = v224_:getString(v236_ .. "#filename")
				if v237_ ~= nil and (v238_ ~= nil and v239_ ~= nil) then
					local v240_ = modDir .. v239_
					if v226_ then
						v223_.g_specializationManager:addSpecialization(v237_, v238_, v240_, modName)
					else
						printError("Error: Can\'t register specialization " .. v237_ .. " with scripts on consoles.")
					end
				end
			end
			for _, v241_ in v224_:iterator("modDesc.vehicleTypes.type") do
				g_vehicleTypeManager:loadTypeFromXML(v224_.handle, v241_, v225_, modDir, modName)
			end
			for _, v242_ in v224_:iterator("modDesc.placeableSpecializations.specialization") do
				local v243_ = v224_:getString(v242_ .. "#name")
				local v244_ = v224_:getString(v242_ .. "#className")
				local v245_ = v224_:getString(v242_ .. "#filename")
				if v243_ ~= nil and (v244_ ~= nil and v245_ ~= nil) then
					local v246_ = modDir .. v245_
					if v226_ then
						v223_.g_placeableSpecializationManager:addSpecialization(v243_, v244_, v246_, modName)
					else
						printError("Error: Can\'t register placeable specialization " .. v243_ .. " with scripts on consoles.")
					end
				end
			end
			for _, v247_ in v224_:iterator("modDesc.placeableTypes.type") do
				g_placeableTypeManager:loadTypeFromXML(v224_.handle, v247_, v225_, modDir, modName)
			end
			for _, v248_ in v224_:iterator("modDesc.handToolSpecializations.specialization") do
				local v249_ = v224_:getString(v248_ .. "#name")
				local v250_ = v224_:getString(v248_ .. "#className")
				local v251_ = v224_:getString(v248_ .. "#filename")
				if v249_ ~= nil and (v250_ ~= nil and v251_ ~= nil) then
					local v252_ = modDir .. v251_
					if v226_ then
						v223_.g_handToolSpecializationManager:addSpecialization(v249_, v250_, v252_, modName)
					else
						printError("Error: Can\'t register handTool specialization " .. v249_ .. " with scripts on consoles.")
					end
				end
			end
			for _, v253_ in v224_:iterator("modDesc.handToolTypes.type") do
				g_handToolTypeManager:loadTypeFromXML(v224_.handle, v253_, v225_, modDir, modName)
			end
			for _, v254_ in v224_:iterator("modDesc.bales.bale") do
				g_baleManager:loadModBaleFromXML(v224_, v254_, modDir, modName)
			end
			for _, v255_ in v224_:iterator("modDesc.jointTypes.jointType") do
				local v256_ = v224_:getString(v255_ .. "#name")
				if v256_ ~= nil then
					AttacherJoints.registerJointType(v256_)
				end
			end
			for _, v257_ in v224_:iterator("modDesc.materialHolders.materialHolder") do
				local v258_ = v224_:getString(v257_ .. "#filename")
				if v258_ ~= nil then
					local v259_ = Utils.getFilename(v258_, g_currentModDirectory)
					g_materialManager:addModMaterialHolder(v259_)
				end
			end
			g_vehicleMaterialManager:addModMaterialTemplatesToLoad(modFile, "modDesc.materialTemplates", g_currentModDirectory, modName)
			for _, v260_ in v224_:iterator("modDesc.connectionHoses.connectionHose") do
				local v261_ = v224_:getString(v260_ .. "#xmlFilename")
				if v261_ ~= nil then
					local v262_ = Utils.getFilename(v261_, g_currentModDirectory)
					g_connectionHoseManager:addModConnectionHoses(v262_, modName, g_currentModDirectory)
				end
			end
			for _, v263_ in v224_:iterator("modDesc.consumables.consumable") do
				local v264_ = v224_:getString(v263_ .. "#xmlFilename")
				if v264_ ~= nil then
					local v265_ = Utils.getFilename(v264_, g_currentModDirectory)
					g_consumableManager:addModConsumable(v265_, modName, g_currentModDirectory)
				end
			end
			for _, v266_ in v224_:iterator("modDesc.storeItems.storeItem") do
				local v267_ = v224_:getString(v266_ .. "#xmlFilename")
				if v267_ ~= nil then
					g_storeManager:addModStoreItem(v267_, modDir, modName, not v225_, false, modTitle)
				end
			end
			for _, v268_ in v224_:iterator("modDesc.storePacks.storePack") do
				local v269_ = v224_:getString(v268_ .. "#name")
				local v270_ = v224_:getString(v268_ .. "#title")
				local v271_ = v224_:getString(v268_ .. "#image")
				if v270_ ~= nil and v270_:sub(1, 6) == "$l10n_" then
					v270_ = g_i18n:getText(v270_:sub(7))
				end
				local v272_ = {}
				for _, v273_ in v224_:iterator(v268_ .. ".storeItem") do
					local v274_ = v224_:getString(v273_)
					local v275_ = Utils.getFilename(v274_, g_currentModDirectory)
					if fileExists(v275_) then
						table.insert(v272_, v275_)
					else
						Logging.xmlWarning(v224_, "StoreItem \'%s\' not found for storepack \'%s\'", v274_, v269_)
					end
				end
				g_storeManager:addModStorePack(v269_, v270_, v271_, modDir, v272_)
			end
			local v276_ = v224_:getString("modDesc.constructionCategories#defaultIconFilename")
			local v277_ = v224_:getVector("modDesc.constructionCategories#refSize", nil, 2) or { 1024, 1024 }
			for _, v278_ in v224_:iterator("modDesc.constructionCategories.tab") do
				local v279_ = v224_:getString(v278_ .. "#categoryName")
				local v280_ = v224_:getString(v278_ .. "#name")
				local v281_ = g_i18n:convertText(v224_:getString(v278_ .. "#title"), modName)
				local v282_ = v224_:getString(v278_ .. "#iconFilename") or v276_
				local v283_ = v224_:getVector(v278_ .. "#refSize", v277_, 2)
				local v284_ = GuiUtils.getUVs(v224_:getString(v278_ .. "#iconUVs", "0 0 1 1"), v283_)
				local v285_ = v224_:getString(v278_ .. "#iconSliceId")
				g_storeManager:addModConstructionTab(v279_, v280_, v281_, v282_, v283_, v284_, g_currentModDirectory, v285_)
			end
			local v286_ = v224_:getString("modDesc.fillTypes#filename")
			if v286_ ~= nil then
				local v287_, _ = Utils.getFilename(v286_, g_currentModDirectory)
				g_fillTypeManager:addModWithFillTypes(v287_, g_currentModDirectory, modName)
			end
			local v288_ = v224_:getString("modDesc.densityMapHeightTypes#filename")
			if v288_ ~= nil then
				local v289_ = Utils.getFilename(v288_, g_currentModDirectory)
				g_densityMapHeightManager:addModDensityMapHeightTypes(v289_)
			end
			local v290_ = v224_:getString("modDesc.motionPathEffects#filename")
			if v290_ ~= nil then
				local v291_ = Utils.getFilename(v290_, g_currentModDirectory)
				g_motionPathEffectManager:loadModMotionPathEffects(v291_, g_currentModDirectory, modName)
			end
			if v225_ then
				for _, v292_ in v224_:iterator("modDesc.foliageTypes.foliageType") do
					local v293_ = v224_:getString(v292_ .. "#name")
					local v294_ = v224_:getString(v292_ .. "#filename")
					if v293_ ~= nil and v294_ ~= nil then
						local v295_ = Utils.getFilename(v294_, g_currentModDirectory)
						g_fruitTypeManager:addModFoliageType(v293_, v295_)
					end
				end
			end
			local v296_ = v224_:getString("modDesc.missionVehicles#filename")
			if v296_ ~= nil then
				local v297_ = Utils.getFilename(v296_, g_currentModDirectory)
				g_missionManager:addPendingMissionVehiclesFile(v297_, g_currentModDirectory)
			end
			for _, v298_ in v224_:iterator("modDesc.wildlife.species") do
				local v299_ = v224_:getString(v298_ .. "#filename")
				local v300_ = string.split(v224_:getString(v298_ .. "#groups") or "", " ")
				g_wildlifeManager:registerModWildlifeFile(v299_, g_currentModDirectory, v300_)
			end
			v224_:delete()
			g_currentModDirectory = nil
			g_currentModName = nil
		end
	end
end
function reloadDlcsAndMods()
	-- upvalues: (ref) isReloadingDlcs
	if g_currentMission == nil then
		for v301_ = g_mapManager:getNumOfMaps(), 1, -1 do
			if g_mapManager:getMapDataByIndex(v301_).isModMap then
				g_mapManager:removeMapItem(v301_)
			end
		end
		while g_modManager:getNumOfMods() > 0 do
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
			local v302_ = startFrameRepeatMode()
			while isModUpdateRunning() do
				usleep(16000)
			end
			if v302_ then
				endFrameRepeatMode()
			end
		end
		if Platform.supportsMods then
			loadAllMods()
		end
		g_inputBinding:reloadModActions()
		isReloadingDlcs = false
	else
		print("Dlc reloading is not supported during gameplay")
	end
end
function verifyDlcs()
	local v303_ = {}
	for _, v304_ in ipairs(g_modManager:getMods()) do
		if not fileExists(v304_.modFile) then
			table.insert(v303_, v304_)
		end
	end
	return #v303_ == 0, v303_
end
function checkForNewDlcs()
	if not Platform.isXbox then
		return true
	end
	local v305_ = {}
	local v306_ = false
	for v307_ = 0, getNumDlcPaths() - 1 do
		local v308_ = getDlcPath(v307_)
		if v308_ ~= nil then
			v305_[v308_] = true
			if g_lastCheckDlcPaths[v308_] == nil then
				v306_ = true
			end
		end
	end
	g_lastCheckDlcPaths = v305_
	return v306_
end
checkForNewDlcs()
function loadDlcsDirectories()
	g_dlcsDirectories = {}
	local v309_ = getNumDlcPaths()
	for v310_ = 0, v309_ - 1 do
		local v311_ = getDlcPath(v310_)
		if v311_ == nil then
			if Platform.verboseDLCLoading then
				Logging.error("Could not retrieve dlc path %d of %d", v310_ + 1, v309_)
			end
		else
			local v312_ = g_dlcsDirectories
			table.insert(v312_, {
				["path"] = v311_,
				["isLoaded"] = true
			})
			if v311_ == getAppBasePath() .. "pdlc/" then
				local v313_ = g_dlcsDirectories
				table.insert(v313_, {
					["path"] = "pdlc/",
					["isLoaded"] = false
				})
			end
		end
	end
end
loadDlcsDirectories()

function addModEventListener(listener)
	local v315_ = g_modEventListeners
	table.insert(v315_, listener)
end

-- Local values: i, listenerI
function removeModEventListener(listener)
	for v317_, v318_ in ipairs(g_modEventListeners) do
		if v318_ == listener then
			table.remove(g_modEventListeners, v317_)
			return
		end
	end
end
function createModDescSchema()
	local v319_ = XMLSchema.new("modDesc")
	v319_:register(XMLValueType.INT, "modDesc#descVersion", "Version of the modDesc, can be used to enforce a specific game version or patch level for a mod to load", nil, true)
	v319_:register(XMLValueType.STRING, "modDesc.author", "Author(s) of the mod", nil, true)
	v319_:register(XMLValueType.STRING, "modDesc.version", "Version number of the mod, format \'a.b.c.d\'", nil, true)
	v319_:register(XMLValueType.BOOL, "modDesc.isSelectable", "If the mod is selectable in the mod selection screen", true, false)
	v319_:register(XMLValueType.STRING, "modDesc.uniqueType", "A unique type of the mod. Only one mod of this type may be selected", nil, false)
	local v320_ = getNumOfLanguages()
	for v321_ = 0, v320_ - 1 do
		local v322_ = getLanguageCode(v321_)
		v319_:register(XMLValueType.STRING, string.format("modDesc.title.%s", v322_), "localized title", nil, false)
		v319_:register(XMLValueType.STRING, string.format("modDesc.description.%s", v322_), "localized description", nil, false)
	end
	v319_:register(XMLValueType.STRING, "modDesc.l10n#filenamePrefix", "prefix for external loca file. Supported xml format: l10n.texts.text#name + l10n.texts.text#text or l10n.elements.e#k + l10n.elements.e#v")
	for v323_ = 0, v320_ - 1 do
		local v324_ = getLanguageCode(v323_)
		v319_:register(XMLValueType.STRING, "modDesc.l10n.text(?)#name", "loca entry name/key", nil, false)
		v319_:register(XMLValueType.STRING, string.format("modDesc.l10n.text(?).%s", v324_), "localized text", nil, false)
	end
	v319_:register(XMLValueType.FILENAME, "modDesc.iconFilename", "Path to the icon used for the whole mod", nil, true)
	v319_:register(XMLValueType.FILENAME, "modDesc.storeItems.storeItem(?)#xmlFilename", "Path to xml file of a individual store item", nil, false)
	v319_:register(XMLValueType.BOOL, "modDesc.multiplayer#supported", "Mod supports multiplayer", false, false)
	v319_:register(XMLValueType.BOOL, "modDesc.multiplayer#only", "Mod is only available for multiplayer games", false, false)
	v319_:register(XMLValueType.FILENAME, "modDesc.wildlife.species(?)#filename", "Mods wildlife species xml path", false, false)
	v319_:register(XMLValueType.STRING, "modDesc.extraSourceFiles.sourceFile(?)#filename", "additional lua file to source", nil, false)
	SpecializationManager.registerXMLPaths(v319_, "modDesc.specializations.specialization(?)")
	SpecializationManager.registerXMLPaths(v319_, "modDesc.placeableSpecializations.specialization(?)")
	SpecializationManager.registerXMLPaths(v319_, "modDesc.handToolSpecializations.specialization(?)")
	v319_:register(XMLValueType.FILENAME, "modDesc.bales.bale(?)#filename")
	v319_:register(XMLValueType.FILENAME, "modDesc.jointTypes.jointType(?)#name")
	v319_:register(XMLValueType.FILENAME, "modDesc.materialHolders.materialHolder(?)#filename")
	v319_:register(XMLValueType.STRING, "modDesc.maps.map(?)#id", "map id", nil, false)
	v319_:register(XMLValueType.STRING, "modDesc.maps.map(?)#className", "name of the lua class to initialize for this map", nil, false)
	v319_:register(XMLValueType.FILENAME, "modDesc.maps.map(?)#filename", "path to the lua file to source/load for this map", nil, false)
	v319_:register(XMLValueType.FILENAME, "modDesc.maps.map(?)#configFilename", "path to the xml config file", nil, false)
	v319_:register(XMLValueType.FILENAME, "modDesc.maps.map(?)#defaultVehiclesXMLFilename", "path to default vehicle xml config file", nil, false)
	v319_:register(XMLValueType.FILENAME, "modDesc.maps.map(?)#defaultHandToolsXMLFilename", "path to default handtool xml config file", nil, false)
	v319_:register(XMLValueType.FILENAME, "modDesc.maps.map(?)#defaultPlaceablesXMLFilename", "path to default placeable xml config file", nil, false)
	v319_:register(XMLValueType.FILENAME, "modDesc.maps.map(?)#defaultItemsXMLFilename", "path to default items xml config file", nil, false)
	v319_:register(XMLValueType.FILENAME, "modDesc.maps.map(?).iconFilename", "path to map icon file", nil, false)
	for v325_ = 0, v320_ - 1 do
		local v326_ = getLanguageCode(v325_)
		v319_:register(XMLValueType.STRING, string.format("modDesc.maps.map(?).title.%s", v326_), "localized title", nil, false)
		v319_:register(XMLValueType.STRING, string.format("modDesc.maps.map(?).description.%s", v326_), "localized description", nil, false)
	end
	TypeManager.registerTypeXMLPath(v319_, "modDesc.vehicleTypes.type(?)")
	TypeManager.registerTypeXMLPath(v319_, "modDesc.placeableTypes.type(?)")
	TypeManager.registerTypeXMLPath(v319_, "modDesc.handToolTypes.type(?)")
	v319_:register(XMLValueType.STRING, "modDesc.brands.brand(?)#name")
	v319_:register(XMLValueType.STRING, "modDesc.brands.brand(?)#title")
	v319_:register(XMLValueType.FILENAME, "modDesc.brands.brand(?)#image")
	v319_:register(XMLValueType.FLOAT, "modDesc.brands.brand(?)#imageOffset")
	v319_:register(XMLValueType.FILENAME, "modDesc.connectionHoses.connectionHose(?)#xmlFilename")
	v319_:register(XMLValueType.FILENAME, "modDesc.consumables.consumable(?)#xmlFilename")
	v319_:register(XMLValueType.FILENAME, "modDesc.fillTypes#filename", "file path to additional fillTypes xml file", nil, false)
	v319_:register(XMLValueType.FILENAME, "modDesc.missionVehicles#filename", "file path to mission vehicles xml file for he included", nil, false)
	v319_:register(XMLValueType.FILENAME, "modDesc.densityMapHeightTypes#filename")
	HelpLineManager.registerCategoryXMLPaths(v319_, "modDesc.helpLines.category(?)")
	VehicleMaterialManager.registerXMLPaths(v319_, "modDesc.materialTemplates")
	v319_:register(XMLValueType.STRING, "modDesc.actions.action(?)#name")
	v319_:register(XMLValueType.STRING, "modDesc.actions.action(?)#category")
	v319_:register(XMLValueType.STRING, "modDesc.actions.action(?)#displayCategory")
	v319_:register(XMLValueType.STRING, "modDesc.actions.action(?)#axisType")
	v319_:register(XMLValueType.BOOL, "modDesc.actions.action(?)#ignoreComboMask")
	v319_:register(XMLValueType.STRING, "modDesc.inputBinding.actionBinding(?)#action")
	v319_:register(XMLValueType.STRING, "modDesc.inputBinding.actionBinding(?).binding(?)#device")
	v319_:register(XMLValueType.STRING, "modDesc.inputBinding.actionBinding(?).binding(?)#input")
	v319_:register(XMLValueType.STRING, "modDesc.inputBinding.actionBinding(?).binding(?)#axisComponent")
	v319_:register(XMLValueType.STRING, "modDesc.inputBinding.actionBinding(?).binding(?)#inputComponent")
	v319_:register(XMLValueType.INT, "modDesc.inputBinding.actionBinding(?).binding(?)#neutralInput")
	v319_:register(XMLValueType.INT, "modDesc.inputBinding.actionBinding(?).binding(?)#index")
	v319_:register(XMLValueType.STRING, "modDesc.dependencies.dependency(?)", "filename of the mod (without \'.zip\') to be installed for this mod to be used")
	StoreManager.registerStoreCategoriesXMLPaths(v319_, "modDesc.storeCategories.storeCategory(?)")
	return v319_
end
