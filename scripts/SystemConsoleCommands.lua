-- Local values: DEBUG_RENDERING_ALIASES, mode, v, customEnvMaps, setEnvMapFunc
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
	local v2_ = tonumber(steps)
	if v2_ == nil then
		g_guiHelperSteps = 0.1
		g_drawGuiHelper = false
	else
		g_guiHelperSteps = math.max(v2_, 0.001)
		g_drawGuiHelper = true
	end
	return not g_drawGuiHelper and "DrawGuiHelper = false" or "DrawGuiHelper = true (step = " .. g_guiHelperSteps .. ")"
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
	local v4_ = tonumber(sizeInMB)
	if v4_ == nil then
		setTextureStreamingMemoryBudget(0)
		return "Reset Texture Streaming Memory Budget to default"
	else
		setTextureStreamingMemoryBudget(v4_)
		return "Set Texture Streaming Memory Budget to " .. v4_ .. " MB"
	end
end

-- Local values: ret
function SystemConsoleCommands:cleanI3DCache(verbose)
	local v6_ = Utils.stringToBoolean(verbose)
	g_i3DManager:clearEntireSharedI3DFileCache(v6_)
	local v7_ = "I3D cache cleaned."
	if not v6_ then
		v7_ = v7_ .. " Use \'true\' parameter for verbose output"
	end
	return v7_
end

-- Local values: minValue, maxValue, default, usage, coeff
function SystemConsoleCommands:setHighQuality(coeffOverride, foliageCoeff)
	local v10_ = string.format("Usage \'gsSetHighQuality <factor (default=%d)>\'", 5)
	local v11_ = tonumber(coeffOverride) or 5
	local v12_ = math.clamp(v11_, 1e-6, 10)
	local v13_ = tonumber(foliageCoeff) or v12_ * 0.5
	setViewDistanceCoeff(v12_)
	setLODDistanceCoeff(v12_)
	setTerrainLODDistanceCoeff((math.clamp(v12_, 0, 2.5)))
	setFoliageViewDistanceCoeff((math.max(1, v13_)))
	return string.format("High quality activated, used factor=%f\n%s", MathUtil.round(v12_, 8), coeffOverride == nil and (" " .. v10_ or "") or "")
end

-- Local values: width, height, curScrMode, strDate, colorScreenShot, depthScreenShot
function SystemConsoleCommands:renderColorAndDepthScreenShot(inWidth, inHeight)
	local v16_, v17_
	if inWidth == nil or inHeight == nil then
		local v18_ = getScreenMode()
		v16_, v17_ = getScreenModeInfo(v18_)
	else
		v16_ = tonumber(inWidth)
		v17_ = tonumber(inHeight)
	end
	setDebugRenderingMode(DebugRendering.NONE)
	local v19_ = getDate("%Y_%m_%d_%H_%M_%S") .. ".hdr"
	local v20_ = g_screenshotsDirectory .. "fsScreen_color_" .. v19_
	print("Saving color screenshot: " .. v20_)
	renderScreenshot(v20_, v16_, v17_, v16_ / v17_, "raw_hdr", 1, 0, 0, 0, 0, 0, 15, false)
	setDebugRenderingMode(DebugRendering.DEPTH)
	local v21_ = g_screenshotsDirectory .. "fsScreen_depth_" .. v19_
	print("Saving depth screenshot: " .. v21_)
	renderScreenshot(v21_, v16_, v17_, v16_ / v17_, "raw_hdr", 1, 0, 0, 0, 0, 0, 15, false)
	setDebugRenderingMode(DebugRendering.NONE)
end
local v_u_22_ = {
	["AO"] = DebugRendering.AMBIENT_OCCLUSION,
	["BAKEDAO"] = DebugRendering.BAKED_AMBIENT_OCCLUSION,
	["SSAO"] = DebugRendering.SCREEN_SPACE_AMBIENT_OCCLUSION,
	["DIFFUSE"] = DebugRendering.DIFFUSE_LIGHTING,
	["SPECULAR"] = DebugRendering.SPECULAR_LIGHTING,
	["INDIRECT"] = DebugRendering.INDIRECT_LIGHTING,
	["DEPTH"] = DebugRendering.DEPTH_SCALED,
	["MIPS"] = DebugRendering.MIP_LEVELS,
	["VRS"] = DebugRendering.SHADING_RATE,
	["LOD"] = DebugRendering.MESH_LOD
}
for v23_, v24_ in pairs(DebugRendering) do
	if string.contains(v23_, "_") then
		v_u_22_[string.gsub(v23_, "_", "")] = v24_
	end
end

-- Upvalues: DEBUG_RENDERING_ALIASES
-- Local values: listModes, newModeStrNoUnderscore, debugMode, modeName, name, mode
function SystemConsoleCommands:setDebugRenderingMode(newModeStr)
	-- upvalues: (copy) v_u_22_
	local function v32_()
		-- upvalues: (ref) v_u_22_
		local v26_ = {}
		for v27_, v28_ in pairs(DebugRendering) do
			v26_[v27_] = true
			for v29_, v30_ in pairs(v_u_22_) do
				if v28_ == v30_ then
					v26_[v27_] = nil
					v26_[v29_] = true
				end
			end
		end
		local v31_ = table.toList(v26_)
		table.sort(v31_)
		return "Possible modes: " .. table.concat(v31_, ", ")
	end
	if newModeStr == nil or newModeStr == "" then
		if getDebugRenderingMode() == DebugRendering.NONE then
			printError("Error: No debug mode given")
			return v32_()
		else
			setDebugRenderingMode(DebugRendering.NONE)
			return "Changed debug rendering mode to NONE"
		end
	end
	local v33_ = string.upper(newModeStr)
	local v34_ = string.gsub(v33_, "_", "")
	local v35_ = DebugRendering[v33_] or DebugRendering[v34_] or (v_u_22_[v33_] or v_u_22_[v34_])
	if v35_ == nil then
		printError(string.format("Error: Unknown DebugRendering mode %q", v33_))
		return v32_()
	end
	setDebugRenderingMode(v35_)
	local v36_ = ""
	for v37_, v38_ in pairs(DebugRendering) do
		if v38_ == v35_ then
			v36_ = v37_
			break
		end
	end
	return "Changed debug rendering mode to " .. v36_
end

-- Local values: numLanguages, newLang, newIndex, i, xmlFile
function SystemConsoleCommands:changeLanguage(newCode)
	local v40_ = getNumOfLanguages()
	local v41_ = -1
	if newCode == nil then
		local v42_ = g_settingsLanguageGUI + 1
		local v43_ = #g_availableLanguagesTable <= v42_ and 0 or v42_
		v41_ = g_availableLanguagesTable[v43_ + 1]
	else
		for v44_ = 0, v40_ - 1 do
			if getLanguageCode(v44_) == newCode then
				v41_ = v44_
				break
			end
		end
		if v41_ < 0 then
			return "Invalid language parameter " .. tostring(newCode)
		end
	end
	if not setLanguage(v41_) then
		return "Invalid language parameter " .. tostring(newCode)
	end
	local v45_ = XMLFile.load("SettingsFile", "dataS/settings.xml")
	loadLanguageSettings(v45_)
	v45_:delete()
	g_i18n:load()
	return string.format("Changed language to \'%s\'. Note that many texts are loaded on game start and need a reboot to be updated.", getLanguageCode(v41_))
end

-- Local values: guiName, guiController, success, class, customEnv, _, k, v
function SystemConsoleCommands:reloadCurrentGui()
	if g_gui.currentGuiName == nil or g_gui.currentGuiName == "" then
		return "No GUI active!"
	end
	g_gui.currentlyReloading = true
	local v46_ = g_gui.currentGuiName
	local v47_ = g_gui.currentGui.target
	g_gui:showGui("")
	g_i18n:delete()
	g_i18n:load()
	if not g_gui:loadProfiles("dataS/guiProfiles.xml") then
		g_gui.currentlyReloading = false
		return "Failed to reload profiles"
	end
	local v48_ = ClassUtil.getClassObject(v46_)
	if v48_ == nil then
		for v49_, _ in pairs(g_modIsLoaded) do
			for v50_, v51_ in pairs(_G[v49_]) do
				if v50_ == v46_ then
					v48_ = v51_
				end
			end
		end
	end
	if v48_ == nil then
		return "Given GUI class not found"
	end
	g_dummyGui = nil
	if v48_.createFromExistingGui == nil then
		g_dummyGui = v48_.new()
		g_gui.guis[v46_]:delete()
		g_gui.guis[v46_].target:delete()
		g_gui:loadGui(v47_.xmlFilename, v46_, g_dummyGui)
	else
		g_dummyGui = v48_.createFromExistingGui(v47_, v46_)
	end
	g_gui:showGui(v46_)
	g_gui.currentlyReloading = false
	return "Reloaded gui " .. tostring(v46_)
end

-- Local values: guiName, currentListener, guiController, success, class, customEnv, _, k, v
function SystemConsoleCommands:reloadCurrentDialog()
	if g_gui.currentDialogName == nil or g_gui.currentDialogName == "" then
		return "No Dialog active!"
	end
	g_gui.currentlyReloading = true
	local v52_ = g_gui.currentDialogName
	local v53_ = g_gui.currentListener
	local v54_ = v53_.target
	g_gui:closeDialog(v53_)
	g_i18n:delete()
	g_i18n:load()
	if not g_gui:loadProfiles("dataS/guiProfiles.xml") then
		g_gui.currentlyReloading = false
		return "Failed to reload profiles"
	end
	local v55_ = ClassUtil.getClassObject(v52_)
	if v55_ == nil then
		for v56_, _ in pairs(g_modIsLoaded) do
			for v57_, v58_ in pairs(_G[v56_]) do
				if v57_ == v52_ then
					v55_ = v58_
				end
			end
		end
	end
	if v55_ == nil then
		return "Given GUI Dialog class not found"
	end
	g_dummyGui = nil
	if v55_.createFromExistingGui == nil then
		g_dummyGui = v55_.new()
		g_gui.guis[v52_]:delete()
		g_gui.guis[v52_].target:delete()
		g_gui:loadGui(v54_.xmlFilename, v52_, g_dummyGui)
	else
		g_dummyGui = v55_.createFromExistingGui(v54_, v52_)
	end
	g_gui.currentlyReloading = false
	return "Reloaded dialog " .. tostring(v52_)
end

function SystemConsoleCommands:resetHelpSystem()
	if g_currentMission == nil or g_currentMission.introductionHelpSystem == nil then
		return "Not currently in a mission"
	end
	g_currentMission.introductionHelpSystem:resetHelpSystem()
	return "Reset Introduction Help System"
end

function SystemConsoleCommands:resetHelpSystemWithDraw()
	if g_currentMission == nil or g_currentMission.introductionHelpSystem == nil then
		return "Not currently in a mission"
	end
	g_currentMission.introductionHelpSystem:resetHelpSystemWithDraw()
	return "Reset Introduction Help System"
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
	local v59_ = g_appIsSuspended
	return "App Suspended: " .. tostring(v59_)
end

function SystemConsoleCommands:softRestart()
	if g_currentMission == nil then
		RestartManager:setStartScreen(RestartManager.START_SCREEN_MAIN)
		doRestart(false, "")
	else
		OnInGameMenuMenu()
	end
end

function SystemConsoleCommands:updateDownloadFinished()
	g_updateDownloadFinished = true
	log("g_updateDownloadFinished = true")
end

-- Local values: usage, currentQuality, i, name, effectiveQuality
function SystemConsoleCommands:setFidelityFxSR(newQuality)
	local v61_ = tonumber(newQuality)
	local v62_ = getFidelityFxSRQuality()
	print(string.format("current setting: %s (%d)", getFidelityFxSRQualityName(v62_), v62_))
	print("Available settings:")
	local v63_ = "Usage: gsRenderingFidelityFxSRSet <qualityNumber>"
	for v64_ = 0, FidelityFxSRQuality.NUM - 1 do
		local v65_ = getFidelityFxSRQualityName(v64_)
		local v66_ = print
		local v67_ = string.format
		local v68_ = getSupportsFidelityFxSRQuality
		v66_(v67_("    %d | %s | supported=%s", v64_, v65_, (tostring(v68_(v64_)))))
	end
	if v61_ == nil then
		return v63_
	end
	if v61_ < 0 or (v61_ >= FidelityFxSRQuality.NUM or not getSupportsFidelityFxSRQuality(v61_)) then
		return string.format("Error: Given quality \'%d\' not supported\n%s", v61_, "Usage: gsRenderingFidelityFxSRSet <qualityNumber>")
	end
	setFidelityFxSRQuality(v61_)
	local v69_ = getFidelityFxSRQuality()
	return string.format("new setting: %s (%d)", getFidelityFxSRQualityName(v69_), v69_)
end
local v_u_70_ = {}
local v_u_71_ = setEnvMap

-- Upvalues: customEnvMaps
function SystemConsoleCommands.registerCustomEnvMap(filepath)
	-- upvalues: (copy) v_u_70_
	table.addElement(v_u_70_, filepath)
end

-- Upvalues: customEnvMaps
-- Local values: index, path
function SystemConsoleCommands:listCustomEnvMaps()
	-- upvalues: (copy) v_u_70_
	if #v_u_70_ == 0 then
		print("No custom env maps registered")
	else
		for v73_, v74_ in ipairs(v_u_70_) do
			print(string.format("%d - %s", v73_, v74_))
		end
	end
end

-- Upvalues: setEnvMapFunc, customEnvMaps
-- Local values: filename, setEnvMapOverride
function SystemConsoleCommands:setCustomEnvMap(index, weight)
	-- upvalues: (copy) v_u_71_, (copy) v_u_70_
	local v77_ = tonumber(index)
	if v77_ == 0 then
		setEnvMap = v_u_71_
		print("reset custom env map")
		return
	elseif v77_ == nil then
		printError("Error: no index given")
		print("Usage: gsCustomEnvMapSet index")
		print("Use gsCustomEnvMapList to see available env maps")
	else
		local v78_ = v_u_70_[v77_]
		if v78_ == nil then
			printError("Error: no env map for index %d", v77_)
		end
		local v79_ = tonumber(weight) or 1
		function setEnvMap() end
		v_u_71_(v78_, v78_, v78_, v78_, v79_, 0, 0, 0, true, true)
		print(string.format("set custom env map to %q with a weight of %.2f", v78_, v79_))
	end
end
