SystemConsoleCommands = {}
function SystemConsoleCommands.init()
	addConsoleCommand("gsGuiDrawHelper", "", "drawGuiHelper", SystemConsoleCommands, "[lineSpacing [0..1]]")
	addConsoleCommand("gsI3DCacheClean", "Removes all cached i3d files to ensure the latest versions are loaded from disk", "cleanI3DCache", SystemConsoleCommands)
	addConsoleCommand("gsSetHighQuality", "Increase draw and LOD distances of foliage, terrain and objects", "setHighQuality", SystemConsoleCommands, "coeff;[foliageCoeff: default=coeff*0.5]")
	addConsoleCommand("gsGuiSafeFrameShow", "", "showSafeFrame", SystemConsoleCommands)
	addConsoleCommand("gsGuiDebug", "", "toggleUiDebug", SystemConsoleCommands)
	addConsoleCommand("gsGuiFocusDebug", "", "toggleUiFocusDebug", SystemConsoleCommands)
	addConsoleCommand("gsRenderColorAndDepthScreenShot", "", "renderColorAndDepthScreenShot", SystemConsoleCommands)
	addConsoleCommand("gsCustomEnvMapList", "", "listCustomEnvMaps", SystemConsoleCommands)
	addConsoleCommand("gsCustomEnvMapSet", "", "setCustomEnvMap", SystemConsoleCommands, "index")
	if g_addCheatCommands then
		addConsoleCommand("gsRenderingDebugMode", "", "setDebugRenderingMode", SystemConsoleCommands)
		addConsoleCommand("gsInputDrawRaw", "", "drawRawInput", SystemConsoleCommands)
		addConsoleCommand("gsTextureStreamingSetBudget", "", "setTextureStreamingBudget", SystemConsoleCommands)
	end
	if g_addTestCommands then
		addConsoleCommand("gsLanguageSet", "Set active language", "changeLanguage", SystemConsoleCommands)
		addConsoleCommand("gsGuiReloadCurrent", "", "reloadCurrentGui", SystemConsoleCommands)
		addConsoleCommand("gsGuiReloadCurrentDialog", "", "reloadCurrentDialog", SystemConsoleCommands)
		addConsoleCommand("gsHudResetHelpSystem", "", "resetHelpSystem", SystemConsoleCommands)
		addConsoleCommand("gsHudResetHelpSystemWithDraw", "", "resetHelpSystemWithDraw", SystemConsoleCommands)
		addConsoleCommand("gsSuspendApp", "", "suspendApp", SystemConsoleCommands)
		addConsoleCommand("gsUpdateDownloadFinished", "", "updateDownloadFinished", SystemConsoleCommands)
		addConsoleCommand("gsRenderingFidelityFxSRSet", "", "setFidelityFxSR", SystemConsoleCommands)
		addConsoleCommand("gsSoftRestart", "", "softRestart", SystemConsoleCommands, nil, true)
	end
end
function SystemConsoleCommands.delete()
	removeConsoleCommand("gsGuiDrawHelper")
	removeConsoleCommand("gsI3DCacheClean")
	removeConsoleCommand("gsSetHighQuality")
	removeConsoleCommand("gsGuiSafeFrameShow")
	removeConsoleCommand("gsGuiDebug")
	removeConsoleCommand("gsGuiFocusDebug")
	removeConsoleCommand("gsRenderColorAndDepthScreenShot")
	removeConsoleCommand("gsCustomEnvMapList")
	removeConsoleCommand("gsCustomEnvMapSet")
	removeConsoleCommand("gsRenderingDebugMode")
	removeConsoleCommand("gsInputDrawRaw")
	removeConsoleCommand("gsTextureStreamingSetBudget")
	removeConsoleCommand("gsLanguageSet")
	removeConsoleCommand("gsGuiReloadCurrent")
	removeConsoleCommand("gsGuiReloadCurrentDialog")
	removeConsoleCommand("gsSuspendApp")
	removeConsoleCommand("gsUpdateDownloadFinished")
	removeConsoleCommand("gsRenderingFidelityFxSRSet")
	removeConsoleCommand("gsSoftRestart")
end
function SystemConsoleCommands:drawGuiHelper(steps)
	steps = tonumber(steps)
	if steps ~= nil then
		g_guiHelperSteps = math.max(steps, 0.001)
		g_drawGuiHelper = true
	else
		g_guiHelperSteps = 0.1
		g_drawGuiHelper = false
	end
	if g_drawGuiHelper then
		return "DrawGuiHelper = true (step = " .. g_guiHelperSteps .. ")"
	else
		return "DrawGuiHelper = false"
	end
end
function SystemConsoleCommands:showSafeFrame()
	g_showSafeFrame = not g_showSafeFrame
	return string.format("showSafeFrame = %s", g_showSafeFrame)
end
function SystemConsoleCommands:drawRawInput()
	g_showRawInput = not g_showRawInput
	return string.format("showRawInput = %s", g_showRawInput)
end
function SystemConsoleCommands:setTextureStreamingBudget(sizeInMB)
	sizeInMB = tonumber(sizeInMB)
	if sizeInMB == nil then
		setTextureStreamingMemoryBudget(0)
		return "Reset Texture Streaming Memory Budget to default"
	else
		setTextureStreamingMemoryBudget(sizeInMB)
		return "Set Texture Streaming Memory Budget to " .. sizeInMB .. " MB"
	end
end
function SystemConsoleCommands:cleanI3DCache(verbose)
	verbose = Utils.stringToBoolean(verbose)
	g_i3DManager:clearEntireSharedI3DFileCache(verbose)
	local ret = "I3D cache cleaned."
	if not verbose then
		ret = ret .. " Use 'true' parameter for verbose output"
	end
	return ret
end
function SystemConsoleCommands:setHighQuality(coeffOverride, foliageCoeff)
	local minValue = 0.000001
	local maxValue = 10
	local default = 5
	local usage = string.format("Usage 'gsSetHighQuality <factor (default=%d)>'", 5)
	local coeff = math.clamp(tonumber(coeffOverride) or default, minValue, maxValue)
	foliageCoeff = tonumber(foliageCoeff) or coeff * 0.5
	setViewDistanceCoeff(coeff)
	setLODDistanceCoeff(coeff)
	setTerrainLODDistanceCoeff(math.clamp(coeff, 0, 2.5))
	setFoliageViewDistanceCoeff(math.max(1, foliageCoeff))
	return string.format("High quality activated, used factor=%f\n%s", MathUtil.round(coeff, 8), coeffOverride == nil and " " .. usage or "")
end
function SystemConsoleCommands:renderColorAndDepthScreenShot(inWidth, inHeight)
	local width = nil
	local height = nil
	if inWidth == nil or inHeight == nil then
		local curScrMode = getScreenMode()
		width, height = getScreenModeInfo(curScrMode)
	else
		width = tonumber(inWidth)
		height = tonumber(inHeight)
	end
	setDebugRenderingMode(DebugRendering.NONE)
	local strDate = getDate("%Y_%m_%d_%H_%M_%S") .. ".hdr"
	local colorScreenShot = g_screenshotsDirectory .. "fsScreen_color_" .. strDate
	print("Saving color screenshot: " .. colorScreenShot)
	renderScreenshot(colorScreenShot, width, height, width / height, "raw_hdr", 1, 0, 0, 0, 0, 0, 15, false)
	setDebugRenderingMode(DebugRendering.DEPTH)
	local depthScreenShot = g_screenshotsDirectory .. "fsScreen_depth_" .. strDate
	print("Saving depth screenshot: " .. depthScreenShot)
	renderScreenshot(depthScreenShot, width, height, width / height, "raw_hdr", 1, 0, 0, 0, 0, 0, 15, false)
	setDebugRenderingMode(DebugRendering.NONE)
end
local DEBUG_RENDERING_ALIASES = { AO = DebugRendering.AMBIENT_OCCLUSION, BAKEDAO = DebugRendering.BAKED_AMBIENT_OCCLUSION, SSAO = DebugRendering.SCREEN_SPACE_AMBIENT_OCCLUSION, DIFFUSE = DebugRendering.DIFFUSE_LIGHTING, SPECULAR = DebugRendering.SPECULAR_LIGHTING, INDIRECT = DebugRendering.INDIRECT_LIGHTING, DEPTH = DebugRendering.DEPTH_SCALED, MIPS = DebugRendering.MIP_LEVELS, VRS = DebugRendering.SHADING_RATE, LOD = DebugRendering.MESH_LOD }
for mode, v in pairs(DebugRendering) do
	if string.contains(mode, "_") then
		DEBUG_RENDERING_ALIASES[string.gsub(mode, "_", "")] = v
	end
end
function SystemConsoleCommands:setDebugRenderingMode(newModeStr)
	local listModes = function()
		local modesWithAliases = {}
		for name, mode in pairs(DebugRendering) do
			modesWithAliases[name] = true
			for alias, modeAlias in pairs(DEBUG_RENDERING_ALIASES) do
				if mode == modeAlias then
					modesWithAliases[name] = nil
					modesWithAliases[alias] = true
				end
			end
		end
		local modesSorted = table.toList(modesWithAliases)
		table.sort(modesSorted)
		return "Possible modes: " .. table.concat(modesSorted, ", ")
	end
	if newModeStr == nil or newModeStr == "" then
		if getDebugRenderingMode() == DebugRendering.NONE then
			printError("Error: No debug mode given")
			return listModes()
		else
			setDebugRenderingMode(DebugRendering.NONE)
			return "Changed debug rendering mode to NONE"
		end
	end
	newModeStr = string.upper(newModeStr)
	local newModeStrNoUnderscore = string.gsub(newModeStr, "_", "")
	local debugMode = DebugRendering[newModeStr] or DebugRendering[newModeStrNoUnderscore] or DEBUG_RENDERING_ALIASES[newModeStr] or DEBUG_RENDERING_ALIASES[newModeStrNoUnderscore]
	if debugMode == nil then
		printError(string.format("Error: Unknown DebugRendering mode %q", newModeStr))
		return listModes()
	else
		setDebugRenderingMode(debugMode)
		local modeName = ""
		for name, mode in pairs(DebugRendering) do
			if mode == debugMode then
				modeName = name
				break
			end
		end
		return "Changed debug rendering mode to " .. modeName
	end
end
function SystemConsoleCommands:changeLanguage(newCode)
	local numLanguages = getNumOfLanguages()
	local newLang = -1
	if newCode == nil then
		local newIndex = g_settingsLanguageGUI + 1
		if #g_availableLanguagesTable <= newIndex then
			newIndex = 0
		end
		newLang = g_availableLanguagesTable[newIndex + 1]
	else
		for i = 0, numLanguages - 1 do
			if getLanguageCode(i) == newCode then
				newLang = i
				break
			end
		end
		if newLang < 0 then
			return "Invalid language parameter " .. tostring(newCode)
		end
	end
	if setLanguage(newLang) then
		local xmlFile = XMLFile.load("SettingsFile", "dataS/settings.xml")
		loadLanguageSettings(xmlFile)
		xmlFile:delete()
		g_i18n:load()
		return string.format("Changed language to '%s'. Note that many texts are loaded on game start and need a reboot to be updated.", getLanguageCode(newLang))
	else
		return "Invalid language parameter " .. tostring(newCode)
	end
end
function SystemConsoleCommands:reloadCurrentGui()
	if g_gui.currentGuiName ~= nil and g_gui.currentGuiName ~= "" then
		g_gui.currentlyReloading = true
		local guiName = g_gui.currentGuiName
		local guiController = g_gui.currentGui.target
		g_gui:showGui("")
		g_i18n:delete()
		g_i18n:load()
		local success = g_gui:loadProfiles("dataS/guiProfiles.xml")
		if not success then
			g_gui.currentlyReloading = false
			return "Failed to reload profiles"
		end
		local class = ClassUtil.getClassObject(guiName)
		if class == nil then
			for customEnv, _ in pairs(g_modIsLoaded) do
				for k, v in pairs(_G[customEnv]) do
					if k == guiName then
						class = v
					end
				end
			end
		end
		if class == nil then
			return "Given GUI class not found"
		else
			g_dummyGui = nil
			if class.createFromExistingGui ~= nil then
				g_dummyGui = class.createFromExistingGui(guiController, guiName)
			else
				g_dummyGui = class.new()
				g_gui.guis[guiName]:delete()
				g_gui.guis[guiName].target:delete()
				g_gui:loadGui(guiController.xmlFilename, guiName, g_dummyGui)
			end
			g_gui:showGui(guiName)
			g_gui.currentlyReloading = false
			return "Reloaded gui " .. tostring(guiName)
		end
	end
	return "No GUI active!"
end
function SystemConsoleCommands:reloadCurrentDialog()
	if g_gui.currentDialogName ~= nil and g_gui.currentDialogName ~= "" then
		g_gui.currentlyReloading = true
		local guiName = g_gui.currentDialogName
		local currentListener = g_gui.currentListener
		local guiController = currentListener.target
		g_gui:closeDialog(currentListener)
		g_i18n:delete()
		g_i18n:load()
		local success = g_gui:loadProfiles("dataS/guiProfiles.xml")
		if not success then
			g_gui.currentlyReloading = false
			return "Failed to reload profiles"
		end
		local class = ClassUtil.getClassObject(guiName)
		if class == nil then
			for customEnv, _ in pairs(g_modIsLoaded) do
				for k, v in pairs(_G[customEnv]) do
					if k == guiName then
						class = v
					end
				end
			end
		end
		if class == nil then
			return "Given GUI Dialog class not found"
		else
			g_dummyGui = nil
			if class.createFromExistingGui ~= nil then
				g_dummyGui = class.createFromExistingGui(guiController, guiName)
			else
				g_dummyGui = class.new()
				g_gui.guis[guiName]:delete()
				g_gui.guis[guiName].target:delete()
				g_gui:loadGui(guiController.xmlFilename, guiName, g_dummyGui)
			end
			g_gui.currentlyReloading = false
			return "Reloaded dialog " .. tostring(guiName)
		end
	end
	return "No Dialog active!"
end
function SystemConsoleCommands:resetHelpSystem()
	if g_currentMission ~= nil and g_currentMission.introductionHelpSystem ~= nil then
		g_currentMission.introductionHelpSystem:resetHelpSystem()
		return "Reset Introduction Help System"
	end
	return "Not currently in a mission"
end
function SystemConsoleCommands:resetHelpSystemWithDraw()
	if g_currentMission ~= nil and g_currentMission.introductionHelpSystem ~= nil then
		g_currentMission.introductionHelpSystem:resetHelpSystemWithDraw()
		return "Reset Introduction Help System"
	end
	return "Not currently in a mission"
end
function SystemConsoleCommands:toggleUiDebug()
	if g_uiDebugEnabled then
		g_uiDebugEnabled = false
		return "UI Debug disabled"
	else
		g_uiDebugEnabled = true
		return "UI Debug enabled"
	end
end
function SystemConsoleCommands:toggleUiFocusDebug()
	if g_uiFocusDebugEnabled then
		g_uiFocusDebugEnabled = false
		return "UI Focus Debug disabled"
	else
		g_uiFocusDebugEnabled = true
		return "UI Focus Debug enabled"
	end
end
function SystemConsoleCommands:suspendApp()
	if g_appIsSuspended then
		notifyAppResumed()
	else
		notifyAppSuspended()
	end
	return "App Suspended: " .. tostring(g_appIsSuspended)
end
function SystemConsoleCommands:softRestart()
	if g_currentMission ~= nil then
		OnInGameMenuMenu()
	else
		RestartManager:setStartScreen(RestartManager.START_SCREEN_MAIN)
		doRestart(false, "")
	end
end
function SystemConsoleCommands:updateDownloadFinished()
	g_updateDownloadFinished = true
	log("g_updateDownloadFinished = true")
end
function SystemConsoleCommands:setFidelityFxSR(newQuality)
	local usage = "Usage: gsRenderingFidelityFxSRSet <qualityNumber>"
	newQuality = tonumber(newQuality)
	local currentQuality = getFidelityFxSRQuality()
	print(string.format("current setting: %s (%d)", getFidelityFxSRQualityName(currentQuality), currentQuality))
	print("Available settings:")
	for i = 0, FidelityFxSRQuality.NUM - 1 do
		local name = getFidelityFxSRQualityName(i)
		print(string.format("    %d | %s | supported=%s", i, name, tostring(getSupportsFidelityFxSRQuality(i))))
	end
	if newQuality ~= nil then
		if 0 <= newQuality and (newQuality < FidelityFxSRQuality.NUM and getSupportsFidelityFxSRQuality(newQuality)) then
			setFidelityFxSRQuality(newQuality)
			local effectiveQuality = getFidelityFxSRQuality()
			return string.format("new setting: %s (%d)", getFidelityFxSRQualityName(effectiveQuality), effectiveQuality)
		end
		return string.format("Error: Given quality '%d' not supported\n%s", newQuality, "Usage: gsRenderingFidelityFxSRSet <qualityNumber>")
	else
		return usage
	end
end
local customEnvMaps = {}
local setEnvMapFunc = setEnvMap
function SystemConsoleCommands.registerCustomEnvMap(filepath)
	table.addElement(customEnvMaps, filepath)
end
function SystemConsoleCommands:listCustomEnvMaps()
	if #customEnvMaps == 0 then
		print("No custom env maps registered")
	else
		for index, path in ipairs(customEnvMaps) do
			print(string.format("%d - %s", index, path))
		end
	end
end
function SystemConsoleCommands:setCustomEnvMap(index, weight)
	index = tonumber(index)
	if index == 0 then
		setEnvMap = setEnvMapFunc
		print("reset custom env map")
	elseif index == nil then
		printError("Error: no index given")
		print("Usage: gsCustomEnvMapSet index")
		print("Use gsCustomEnvMapList to see available env maps")
	else
		local filename = customEnvMaps[index]
		if filename == nil then
			printError("Error: no env map for index %d", index)
		end
		weight = tonumber(weight) or 1
		local setEnvMapOverride = function() end
		setEnvMap = setEnvMapOverride
		setEnvMapFunc(filename, filename, filename, filename, weight, 0, 0, 0, true, true)
		print(string.format("set custom env map to %q with a weight of %.2f", filename, weight))
	end
end
