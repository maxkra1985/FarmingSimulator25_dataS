SettingsAdvancedFrame = {}
local SettingsAdvancedFrame_mt = Class(SettingsAdvancedFrame, TabbedMenuFrameElement)
function SettingsAdvancedFrame.register()
	local settingsAdvancedFrame = SettingsAdvancedFrame.new()
	g_gui:loadGui("dataS/gui/SettingsAdvancedFrame.xml", "SettingsAdvancedFrame", settingsAdvancedFrame, true)
end
function SettingsAdvancedFrame.new(target, custom_mt)
	local self = TabbedMenuFrameElement.new(target, custom_mt or SettingsAdvancedFrame_mt)
	self.hasCustomMenuButtons = true
	return self
end
function SettingsAdvancedFrame.createFromExistingGui(gui, guiName)
	local newGui = SettingsAdvancedFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
	newGui.hasCustomMenuButtons = gui.hasCustomMenuButtons
	return newGui
end
function SettingsAdvancedFrame:copyAttributes(src)
	SettingsAdvancedFrame:superClass().copyAttributes(self, src)
	self.hasCustomMenuButtons = src.hasCustomMenuButtons
end
function SettingsAdvancedFrame:initialize()
	self.backButtonInfo = { inputAction = InputAction.MENU_BACK }
	self.nextPageButtonInfo = { inputAction = InputAction.MENU_PAGE_NEXT, text = g_i18n:getText("ui_ingameMenuNext"), callback = self.onPageNext }
	self.prevPageButtonInfo = { inputAction = InputAction.MENU_PAGE_PREV, text = g_i18n:getText("ui_ingameMenuPrev"), callback = self.onPagePrevious }
	self.applyButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = g_i18n:getText(SettingsAdvancedFrame.L10N_SYMBOL.BUTTON_APPLY),
		callback = function()
			self:onApplySettings()
		end,
	}
	self.settingElements = {}
	local addElement = function(settingsKey, element, isMultiElement)
		local data = { settingsKey = settingsKey, element = element, isMultiElement = isMultiElement }
		self.settingElements[element] = data
		local texts = g_settingsModel:getTexts(settingsKey)
		if texts ~= nil then
			if #texts == 0 then
				table.insert(texts, g_i18n:getText("ui_unavailable"))
				element.parent:setDisabled(true)
			else
				element.parent:setDisabled(false)
			end
			if isMultiElement or #texts == 2 then
				element:setTexts(texts)
			end
		else
			element:setVisible(false)
		end
	end
	addElement(SettingsModel.SETTING.POST_PROCESS_AA, self.ppaaElement, true)
	addElement(SettingsModel.SETTING.MSAA, self.msaaElement, true)
	addElement(SettingsModel.SETTING.LENSFLARE_QUALITY, self.lensFlareQualityElement, true)
	addElement(SettingsModel.SETTING.VALAR, self.valarElement, true)
	addElement(SettingsModel.SETTING.SCREEN_SPACE_REFLECTIONS, self.screenSpaceReflectionsElement, true)
	addElement(SettingsModel.SETTING.SCREEN_SPACE_SHADOWS_QUALITY, self.screenSpaceShadowsQualityElement, false)
	addElement(SettingsModel.SETTING.DRS_QUALITY, self.drsQualityElement, true)
	addElement(SettingsModel.SETTING.ATMOSPHERE_QUALITY, self.atmosphereQualityElement, true)
	addElement(SettingsModel.SETTING.VOLUMETRIC_FOG_QUALITY, self.volumetricFogQualityElement, true)
	addElement(SettingsModel.SETTING.TEXTURE_FILTERING, self.textureFilteringElement, true)
end
function SettingsAdvancedFrame:onGuiSetupFinished()
	SettingsAdvancedFrame:superClass().onGuiSetupFinished(self)
	local oldDisableFunc = self.msaaContainer.setDisabled
	local containerDisableFunc = function(container, disabled)
		oldDisableFunc(container, disabled)
		container:getDescendantByName("iconDisabled"):setDisabled(not disabled)
	end
	for _, container in pairs(self.boxLayout.elements) do
		if container:getDescendantByName("iconDisabled") == nil then
			continue
		end
		container.setDisabled = containerDisableFunc
	end
	function self.frameGenerationContainer.getIsActiveNonRec()
		return self.frameGenerationElement:getIsActiveNonRec()
	end
	self.scalingModeNameToIndexMapping = {}
	for _, name in pairs(g_settingsModel:getScalingModeTexts()) do
		for index, scalingMode in pairs(SettingsAdvancedFrame.SCALING_MODES) do
			if g_i18n:getText(scalingMode.title) == name then
				self.scalingModeNameToIndexMapping[name] = index
				break
			end
		end
	end
end
function SettingsAdvancedFrame:onApplySettings()
	local needsRestart, needsProcessRestart = g_settingsModel:needsRestartToApplyChanges()
	g_settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_ALL)
	if needsRestart then
		RestartManager:setStartScreen(RestartManager.START_SCREEN_SETTINGS_ADVANCED)
		InfoDialog.show(g_i18n:getText("dialog_restartToApplyChanges"), function()
			doRestart(needsProcessRestart, "")
		end, nil)
	else
		self:setMenuButtonInfoDirty()
	end
end
function SettingsAdvancedFrame:getMenuButtonInfo()
	local buttons = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
	if g_settingsModel:hasChanges() then
		table.insert(buttons, self.applyButtonInfo)
	end
	return buttons
end
function SettingsAdvancedFrame:updateValues()
	self:updatePerformanceClass()
	for _, data in pairs(self.settingElements) do
		if data.isMultiElement then
			data.element:setState(g_settingsModel:getValue(data.settingsKey) or 1)
		else
			data.element:setIsChecked(g_settingsModel:getValue(data.settingsKey) == BinaryOptionElement.STATE_RIGHT, self.isOpening)
		end
	end
	self.performanceClassElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.PERFORMANCE_CLASS))
	self.msaaElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.MSAA))
	self.drsTargetFPSElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.DRS_TARGET_FPS))
	self.sharpnessElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.SHARPNESS))
	self.shadingRateQualityElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.SHADING_RATE_QUALITY))
	self.textureFilteringElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.TEXTURE_FILTERING))
	self.textureResolutionElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.TEXTURE_RESOLUTION))
	self.shadowQualityElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.SHADOW_QUALITY))
	self.shadowDistanceQualityElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.SHADOW_DISTANCE_QUALITY))
	self.softShadowsElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.SOFT_SHADOWS))
	self.shaderQualityElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.SHADER_QUALITY))
	self.shadowMapFilteringElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.SHADOW_MAP_FILTERING))
	self.maxLightsElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.MAX_LIGHTS))
	self.terrainQualityElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.TERRAIN_QUALITY))
	self.objectDrawDistanceElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.OBJECT_DRAW_DISTANCE))
	self.foliageDrawDistanceElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.FOLIAGE_DRAW_DISTANCE))
	self.lodDistanceElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.LOD_DISTANCE))
	self.terrainLODDistanceElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.TERRAIN_LOD_DISTANCE))
	self.foliageLODDistanceElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.FOLIAGE_LOD_DISTANCE))
	self.volumeMeshTessellationElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.VOLUME_MESH_TESSELLATION))
	self.maxTireTracksElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.MAX_TIRE_TRACKS))
	self.lightsProfileElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.LIGHTS_PROFILE) - 1)
	self.realBeaconLightsElement:setIsChecked(g_settingsModel:getValue(SettingsModel.SETTING.REAL_BEACON_LIGHTS), self.isOpening)
	self.maxMirrorsElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.MAX_MIRRORS))
	self.foliageShadowsElement:setIsChecked(g_settingsModel:getValue(SettingsModel.SETTING.FOLIAGE_SHADOW), self.isOpening)
	self.ssaoQualityElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.SSAO_QUALITY))
	self.cloudShadowsQualityElement:setIsChecked(g_settingsModel:getValue(SettingsModel.SETTING.CLOUD_SHADOWS_QUALITY), self.isOpening)
	self.resolutionScale3dElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.RESOLUTION_SCALE_3D))
	self.fovYElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.FOV_Y))
	self.fovYPlayerFirstPersonElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.FOV_Y_PLAYER_FIRST_PERSON))
	self.fovYPlayerThirdPersonElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.FOV_Y_PLAYER_THIRD_PERSON))
	local postProcessAA = g_settingsModel:getRawValue(SettingsModel.SETTING.POST_PROCESS_AA)
	local isNativeFSR3 = postProcessAA == PostProcessAntiAliasing.FSR3
	local isFSR30Active = g_settingsModel:getRawValue(SettingsModel.SETTING.FIDELITYFX_SR_30) ~= FidelityFxSR30Quality.OFF
	local isFSRActive = g_settingsModel:getRawValue(SettingsModel.SETTING.FIDELITYFX_SR) ~= FidelityFxSRQuality.OFF
	local supportsFrameGeneration = getSupportsFidelityFxFrameInterpolation(FrameInterpolationMode.FRAME_INTERPOLATION_2X)
	local _v335 = g_settingsModel
	local _v102 = SettingsModel.SETTING.FULLSCREEN_MODE
	local frameGenerationActive = supportsFrameGeneration and not isNativeFSR3 and isFSR30Active and _v335:getValue(_v102) ~= FullscreenMode.EXCLUSIVE_FULLSCREEN
	if not isNativeFSR3 then
		local _v92 = isFSR30Active
	end
	_v335:getValue(_v102)
	local supportsXeSSFrameGeneration = getSupportsXeSSFrameInterpolation(FrameInterpolationMode.FRAME_INTERPOLATION_2X)
	local isNativeXeSS = postProcessAA == PostProcessAntiAliasing.XESS
	local isXeSSActive = g_settingsModel:getRawValue(SettingsModel.SETTING.XESS) ~= XeSSQuality.OFF
	local _v228 = g_settingsModel
	local _v351 = SettingsModel.SETTING.FULLSCREEN_MODE
	local xessFrameGenerationActive = supportsXeSSFrameGeneration and not isNativeXeSS and isXeSSActive and _v228:getValue(_v351) ~= FullscreenMode.EXCLUSIVE_FULLSCREEN
	if not isNativeXeSS then
		local _v347 = isXeSSActive
	end
	_v228:getValue(_v351)
	local supportsDLSSFrameGeneration = getSupportsDLSSFrameInterpolation(FrameInterpolationMode.FRAME_INTERPOLATION_2X)
	local isDLSSActive = g_settingsModel:getRawValue(SettingsModel.SETTING.DLSS) ~= DLSSQuality.OFF
	local isDLAAActive = g_settingsModel:getRawValue(SettingsModel.SETTING.POST_PROCESS_AA) == PostProcessAntiAliasing.DLAA
	local _v114 = g_settingsModel
	local _v241 = SettingsModel.SETTING.FULLSCREEN_MODE
	local dlssFrameGenerationActive = supportsDLSSFrameGeneration and not isDLSSActive and isDLAAActive and _v114:getValue(_v241) ~= FullscreenMode.EXCLUSIVE_FULLSCREEN
	if not isDLSSActive then
		local _v237 = isDLAAActive
	end
	_v114:getValue(_v241)
	local isDRSAvailable = getIsDRSAvailable()
	self.drsQualityContainer:setDisabled(not isDRSAvailable)
	self.drsTargetFPSContainer:setDisabled(not isDRSAvailable)
	self.frameGenerationContainer:setDisabled(not (frameGenerationActive or xessFrameGenerationActive or dlssFrameGenerationActive))
	self.resolutionScale3dContainer:setDisabled(isDLSSActive or isXeSSActive or isFSR30Active or isFSRActive)
	local frameGenerationElementTexts = { getFrameInterpolationModeName(FrameInterpolationMode.FRAME_INTERPOLATION_OFF) }
	local textsFunc = getSupportsDLSSFrameInterpolation
	if xessFrameGenerationActive then
		textsFunc = getSupportsXeSSFrameInterpolation
	elseif frameGenerationActive then
		textsFunc = getSupportsFidelityFxFrameInterpolation
	end
	for i = 1, EnumUtil.getNumEntries(FrameInterpolationMode) - 1 do
		if textsFunc(i) then
			table.insert(frameGenerationElementTexts, getFrameInterpolationModeName(i))
		end
	end
	self.frameGenerationElement:setTexts(frameGenerationElementTexts)
	local frameGenerationState = math.max(g_settingsModel:getValue(SettingsModel.SETTING.FIDELITYFX_SR_30_FRAME_GENERATION), g_settingsModel:getValue(SettingsModel.SETTING.XESS_FRAME_GENERATION), g_settingsModel:getValue(SettingsModel.SETTING.DLSS_FRAME_GENERATION))
	self.frameGenerationElement:setState(frameGenerationState + 1)
	if isNativeXeSS or isXeSSActive then
		self.frameGenerationTitle:setText(g_i18n:getText("setting_xeSSFrameGeneration"))
		self.frameGenerationTooltip:setText(g_i18n:getText("toolTip_xeSSFrameGeneration"))
	else
		if isNativeFSR3 or isFSR30Active then
			self.frameGenerationTitle:setText(g_i18n:getText("setting_fidelityFxSR30FrameInterpolation"))
			self.frameGenerationTooltip:setText(g_i18n:getText("toolTip_fidelityFxSR30FrameInterpolation"))
		else
			if isDLSSActive then
				self.frameGenerationTitle:setText(g_i18n:getText("setting_dlssFrameInterpolation"))
				self.frameGenerationTooltip:setText(g_i18n:getText("toolTip_dlssFrameInterpolation"))
			else
				self.frameGenerationTitle:setText(g_i18n:getText("setting_frameGeneration"))
			end
		end
	end
	local settingsKey = nil
	for _, setting in pairs(SettingsAdvancedFrame.SCALING_MODES) do
		local currentValue = g_settingsModel:getRawValue(setting.name)
		if currentValue == nil then
			continue
		end
		if currentValue ~= setting.enum.OFF then
			local state = self.scalingModeNameToIndexMapping[g_i18n:getText(setting.title)] or 1
			self.scalingModeElement:setState(state)
			settingsKey = setting.name
			break
		end
	end
	if settingsKey ~= nil then
		local texts = g_settingsModel:getTexts(settingsKey)
		if not isDRSAvailable or g_settingsModel:getRawValue(SettingsModel.SETTING.DRS_QUALITY) == DRSQuality.OFF then
			self.scalingModeQualityElement:setTexts(texts)
			self.scalingModeQualityContainer:setDisabled(false)
			self.scalingModeQualityElement:setState(g_settingsModel:getValue(settingsKey))
		else
			self.scalingModeQualityElement:setTexts({ g_i18n:getText("ui_auto") })
			self.scalingModeQualityElement:setState(1)
			self.scalingModeQualityContainer:setDisabled(true)
		end
	else
		self.scalingModeElement:setState(1)
	end
	local sharpnessAvailable = self.ppaaElement:getState() ~= 1 or settingsKey ~= nil
	self.sharpnessContainer:setDisabled(not sharpnessAvailable)
	local isMSAAAllowed = true
	if self.ppaaElement:getState() - 1 == PostProcessAntiAliasing.TAA then
		isMSAAAllowed = self.ppaaElement:getState() - 1 ~= PostProcessAntiAliasing.OFF
	end
	self.msaaContainer:setDisabled(not isMSAAAllowed)
	self.scalingModeQualityContainer:setDisabled(settingsKey == nil)
	self:setMenuButtonInfoDirty()
	self.boxLayout:invalidateLayout()
end
function SettingsAdvancedFrame:onFrameOpen()
	SettingsAdvancedFrame:superClass().onFrameOpen(self)
	self.isOpening = true
	self:updateValues()
	self:updateAlternatingSettingsBackgrounds()
	self.isOpening = false
end
function SettingsAdvancedFrame:updateAlternatingSettingsBackgrounds()
	local isAlternate = true
	for _, container in pairs(self.boxLayout.elements) do
		if container.name == "sectionHeader" then
			isAlternate = true
		elseif container:getIsVisible() then
			container:setImageColor(nil, unpack(SettingsScreen.COLOR_ALTERNATING[isAlternate]))
			isAlternate = not isAlternate
		end
	end
	self.boxLayout:invalidateLayout()
end
function SettingsAdvancedFrame:updatePerformanceClass()
	local texts, _, _ = g_settingsModel:getPerformanceClassTexts()
	self.performanceClassElement:setTexts(texts)
end
function SettingsAdvancedFrame:onCreatePerformanceClass(element)
	local texts, _, _ = g_settingsModel:getPerformanceClassTexts()
	element:setTexts(texts)
end
function SettingsAdvancedFrame:onCreatePPAAToolTip(element)
	element:setText(g_settingsModel:getPostProcessAAToolTip())
end
function SettingsAdvancedFrame:onCreateDRSTargetFPS(element)
	element:setTexts(g_settingsModel:getDRSTargetFPSTexts())
end
function SettingsAdvancedFrame:onCreateSharpness(element)
	element:setTexts(g_settingsModel:getSharpnessTexts())
end
function SettingsAdvancedFrame:onCreateScalingMode(element)
	element:setTexts(g_settingsModel:getScalingModeTexts())
end
function SettingsAdvancedFrame:onCreateScalingModeQuality(element)
	element:setTexts(g_settingsModel:getTexts(SettingsModel.SETTING.FIDELITYFX_SR))
end
function SettingsAdvancedFrame:onCreateShadingRateQuality(element)
	element:setTexts(g_settingsModel:getShadingRateQualityTexts())
end
function SettingsAdvancedFrame:onCreateShadowQuality(element)
	element:setTexts(g_settingsModel:getShadowQualityTexts())
end
function SettingsAdvancedFrame:onCreateShadowDistanceQuality(element)
	element:setTexts(g_settingsModel:getShadowDistanceQualityTexts())
end
function SettingsAdvancedFrame:onCreateSoftShadows(element)
	element:setTexts(g_settingsModel:getSoftShadowsTexts())
end
function SettingsAdvancedFrame:onCreateSSAOQuality(element)
	element:setTexts(g_settingsModel:getSSAOQualityTexts())
end
function SettingsAdvancedFrame:onCreateShaderQuality(element)
	element:setTexts(g_settingsModel:getShaderQualityTexts())
end
function SettingsAdvancedFrame:onCreateTextureResolution(element)
	element:setTexts(g_settingsModel:getTextureResolutionTexts())
end
function SettingsAdvancedFrame:onCreateShadowMapFiltering(element)
	element:setTexts(g_settingsModel:getShadowMapFilteringTexts())
end
function SettingsAdvancedFrame:onCreateLightsProfile(element)
	element:setTexts(g_settingsModel:getLightsProfileTexts())
end
function SettingsAdvancedFrame:onCreateTerrainQuality(element)
	element:setTexts(g_settingsModel:getTerraingQualityTexts())
end
function SettingsAdvancedFrame:onCreateShadowMaxLights(element)
	element:setTexts(g_settingsModel:getShadowMapLightsTexts())
end
function SettingsAdvancedFrame:onCreateObjectDrawDistance(element)
	element:setTexts(g_settingsModel:getObjectDrawDistanceTexts())
end
function SettingsAdvancedFrame:onCreateFoliageDrawDistance(element)
	element:setTexts(g_settingsModel:getFoliageDrawDistanceTexts())
end
function SettingsAdvancedFrame:onCreateLODDistance(element)
	element:setTexts(g_settingsModel:getLODDistanceTexts())
end
function SettingsAdvancedFrame:onCreateTerrainLODDistance(element)
	element:setTexts(g_settingsModel:getTerrainLODDistanceTexts())
end
function SettingsAdvancedFrame:onCreateFoliageLODDistance(element)
	element:setTexts(g_settingsModel:getFoliageLODDistanceTexts())
end
function SettingsAdvancedFrame:onCreateVolumeMeshTessellation(element)
	element:setTexts(g_settingsModel:getVolumeMeshTessalationTexts())
end
function SettingsAdvancedFrame:onCreateMaxTireTracks(element)
	element:setTexts(g_settingsModel:getMaxTireTracksTexts())
end
function SettingsAdvancedFrame:onCreateMaxMirrors(element)
	element:setTexts(g_settingsModel:getMaxMirrorsTexts())
end
function SettingsAdvancedFrame:onCreateResolutionScale3d(element)
	element:setTexts(g_settingsModel:getResolutionScale3dTexts())
end
function SettingsAdvancedFrame:onCreateFovY(element)
	element:setTexts(g_settingsModel:getFovYTexts())
end
function SettingsAdvancedFrame:onCreateFovYPlayerFirstPerson(element)
	element:setTexts(g_settingsModel:getFovYTexts())
end
function SettingsAdvancedFrame:onCreateFovYPlayerThirdPerson(element)
	element:setTexts(g_settingsModel:getFovYTexts())
end
function SettingsAdvancedFrame:onCreateFrameGenerationTooltip(element)
	if getFidelityFxSuperResolutionVersion() == 4 then
		element:setText(g_i18n:getText("toolTip_frameGenerationDisabledFSR4"))
	end
end
function SettingsAdvancedFrame:onClick(state, element)
	local data = self.settingElements[element]
	g_settingsModel:setValue(data.settingsKey, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickPerformanceClass(state)
	g_settingsModel:applyPerformanceClass(state)
	self:updateValues()
end
function SettingsAdvancedFrame:onClickPPAA(state, element)
	local data = self.settingElements[element]
	g_settingsModel:setValue(data.settingsKey, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickMSAA(state)
	self.sharpnessContainer:setDisabled(state ~= 1)
	g_settingsModel:setValue(SettingsModel.SETTING.MSAA, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickScalingMode(state)
	local foundSetting = nil
	local settingName = g_settingsModel:getScalingModeTexts()[state]
	for name, index in pairs(self.scalingModeNameToIndexMapping) do
		local setting = SettingsAdvancedFrame.SCALING_MODES[index]
		if name == settingName then
			foundSetting = setting
		else
			g_settingsModel:setRawValue(setting.name, setting.enum.OFF)
		end
	end
	if foundSetting ~= nil then
		g_settingsModel:setValue(foundSetting.name, 1)
		local texts = g_settingsModel:getTexts(foundSetting.name)
		self.scalingModeQualityElement:setTexts(texts)
	end
	g_settingsModel:applyCustomSettings()
	if not getIsDRSAvailable() then
		g_settingsModel:setRawValue(SettingsModel.SETTING.DRS_QUALITY, DRSQuality.OFF)
	end
	self:updateValues()
end
function SettingsAdvancedFrame:onClickScalingModeQuality(state)
	local foundSetting = nil
	local settingName = g_settingsModel:getScalingModeTexts()[self.scalingModeElement:getState()]
	for name, index in pairs(self.scalingModeNameToIndexMapping) do
		local setting = SettingsAdvancedFrame.SCALING_MODES[index]
		if name == settingName then
			foundSetting = setting
			break
		end
	end
	local settingsKey = foundSetting.name
	g_settingsModel:setValue(settingsKey, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickFrameGeneration(state)
	local isNativeXeSS = g_settingsModel:getRawValue(SettingsModel.SETTING.POST_PROCESS_AA) == PostProcessAntiAliasing.XESS
	local isXeSSActive = g_settingsModel:getRawValue(SettingsModel.SETTING.XESS) ~= XeSSQuality.OFF
	local isDLSSActive = g_settingsModel:getRawValue(SettingsModel.SETTING.DLSS) ~= DLSSQuality.OFF
	local isNativeFSR3 = g_settingsModel:getRawValue(SettingsModel.SETTING.POST_PROCESS_AA) == PostProcessAntiAliasing.FSR3
	local isFSR30Active = g_settingsModel:getRawValue(SettingsModel.SETTING.FIDELITYFX_SR_30) ~= FidelityFxSR30Quality.OFF
	if isNativeXeSS or isXeSSActive then
		g_settingsModel:setValue(SettingsModel.SETTING.XESS_FRAME_GENERATION, self.frameGenerationElement:getState() - 1)
	else
		if isDLSSActive then
			g_settingsModel:setValue(SettingsModel.SETTING.DLSS_FRAME_GENERATION, self.frameGenerationElement:getState() - 1)
		elseif isNativeFSR3 or isFSR30Active then
			g_settingsModel:setValue(SettingsModel.SETTING.FIDELITYFX_SR_30_FRAME_GENERATION, self.frameGenerationElement:getState() - 1)
		end
	end
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickDRSTargetFPS(state)
	g_settingsModel:setValue(SettingsModel.SETTING.DRS_TARGET_FPS, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickSharpness(state)
	g_settingsModel:setValue(SettingsModel.SETTING.SHARPNESS, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickShadingRateQuality(state)
	g_settingsModel:setValue(SettingsModel.SETTING.SHADING_RATE_QUALITY, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickTextureResolution(state)
	g_settingsModel:setValue(SettingsModel.SETTING.TEXTURE_RESOLUTION, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickShadowQuality(state)
	g_settingsModel:setValue(SettingsModel.SETTING.SHADOW_QUALITY, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickShadowDistanceQuality(state)
	g_settingsModel:setValue(SettingsModel.SETTING.SHADOW_DISTANCE_QUALITY, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickSoftShadows(state)
	g_settingsModel:setValue(SettingsModel.SETTING.SOFT_SHADOWS, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickShaderQuality(state)
	g_settingsModel:setValue(SettingsModel.SETTING.SHADER_QUALITY, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickShadowMapFiltering(state)
	g_settingsModel:setValue(SettingsModel.SETTING.SHADOW_MAP_FILTERING, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickShadowMaxLights(state)
	g_settingsModel:setValue(SettingsModel.SETTING.MAX_LIGHTS, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickTerrainQuality(state)
	g_settingsModel:setValue(SettingsModel.SETTING.TERRAIN_QUALITY, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickObjectDrawDistance(state)
	g_settingsModel:setValue(SettingsModel.SETTING.OBJECT_DRAW_DISTANCE, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickFoliageDrawDistance(state)
	g_settingsModel:setValue(SettingsModel.SETTING.FOLIAGE_DRAW_DISTANCE, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickLODDistance(state)
	g_settingsModel:setValue(SettingsModel.SETTING.LOD_DISTANCE, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickTerrainLODDistance(state)
	g_settingsModel:setValue(SettingsModel.SETTING.TERRAIN_LOD_DISTANCE, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickFoliageLODDistance(state)
	g_settingsModel:setValue(SettingsModel.SETTING.FOLIAGE_LOD_DISTANCE, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickVolumeMeshTessellation(state)
	g_settingsModel:setValue(SettingsModel.SETTING.VOLUME_MESH_TESSELLATION, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickMaxTireTracks(state)
	g_settingsModel:setValue(SettingsModel.SETTING.MAX_TIRE_TRACKS, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickLightsProfile(state)
	g_settingsModel:setValue(SettingsModel.SETTING.LIGHTS_PROFILE, state + 1)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickRealBeaconLights(state)
	g_settingsModel:setValue(SettingsModel.SETTING.REAL_BEACON_LIGHTS, self.realBeaconLightsElement:getIsChecked())
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickFoliageShadows(state)
	g_settingsModel:setValue(SettingsModel.SETTING.FOLIAGE_SHADOW, self.foliageShadowsElement:getIsChecked())
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickMaxMirrors(state)
	g_settingsModel:setValue(SettingsModel.SETTING.MAX_MIRRORS, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickSSAOQuality(state)
	g_settingsModel:setValue(SettingsModel.SETTING.SSAO_QUALITY, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickAtmosphereQuality(state)
	g_settingsModel:setValue(SettingsModel.SETTING.ATMOSPHERE_QUALITY, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickCloudShadowsQuality(state)
	g_settingsModel:setValue(SettingsModel.SETTING.CLOUD_SHADOWS_QUALITY, self.cloudShadowsQualityElement:getIsChecked())
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickResolutionScale3d(state)
	g_settingsModel:setValue(SettingsModel.SETTING.RESOLUTION_SCALE_3D, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickFovY(state)
	g_settingsModel:setValue(SettingsModel.SETTING.FOV_Y, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickFovYPlayerFirstPerson(state)
	g_settingsModel:setValue(SettingsModel.SETTING.FOV_Y_PLAYER_FIRST_PERSON, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickFovYPlayerThirdPerson(state)
	g_settingsModel:setValue(SettingsModel.SETTING.FOV_Y_PLAYER_THIRD_PERSON, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end
function SettingsAdvancedFrame:onClickLockedIcon() end
function SettingsAdvancedFrame:onFocusLockedIcon(icon)
	self.boxLayout:scrollToMakeElementVisible(icon)
end
SettingsAdvancedFrame.L10N_SYMBOL = { BUTTON_APPLY = "button_apply" }
local fsr34LocaKey = "setting_fsr3"
if getFidelityFxSuperResolutionVersion() == 4 then
	fsr34LocaKey = "setting_fsr4"
end
SettingsAdvancedFrame.SCALING_MODES = { [2] = { name = SettingsModel.SETTING.FIDELITYFX_SR, enum = FidelityFxSRQuality, title = "setting_fsr1" }, [3] = { title = fsr34LocaKey, name = SettingsModel.SETTING.FIDELITYFX_SR_30, enum = FidelityFxSR30Quality }, [4] = { name = SettingsModel.SETTING.DLSS, enum = DLSSQuality, title = "setting_DLSS" }, [5] = { name = SettingsModel.SETTING.XESS, enum = XeSSQuality, title = "setting_xeSS" } }
