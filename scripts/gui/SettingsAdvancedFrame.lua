-- Local values: SettingsAdvancedFrame_mt, fsr34LocaKey
SettingsAdvancedFrame = {}
local SettingsAdvancedFrame_mt = Class(SettingsAdvancedFrame, TabbedMenuFrameElement)
function SettingsAdvancedFrame.register()
	local v2_ = SettingsAdvancedFrame.new()
	g_gui:loadGui("dataS/gui/SettingsAdvancedFrame.xml", "SettingsAdvancedFrame", v2_, true)
end

-- Upvalues: SettingsAdvancedFrame_mt
-- Local values: self
function SettingsAdvancedFrame.new(target, custom_mt)
	-- upvalues: (copy) SettingsAdvancedFrame_mt
	local v5_ = TabbedMenuFrameElement.new(target, custom_mt or SettingsAdvancedFrame_mt)
	v5_.hasCustomMenuButtons = true
	return v5_
end

-- Local values: newGui
function SettingsAdvancedFrame.createFromExistingGui(gui, guiName)
	local v8_ = SettingsAdvancedFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v8_, true)
	v8_.hasCustomMenuButtons = gui.hasCustomMenuButtons
	return v8_
end

function SettingsAdvancedFrame:copyAttributes(src)
	SettingsAdvancedFrame:superClass().copyAttributes(self, src)
	self.hasCustomMenuButtons = src.hasCustomMenuButtons
end

-- Local values: addElement
function SettingsAdvancedFrame:initialize()
	self.backButtonInfo = {
		["inputAction"] = InputAction.MENU_BACK
	}
	self.nextPageButtonInfo = {
		["inputAction"] = InputAction.MENU_PAGE_NEXT,
		["text"] = g_i18n:getText("ui_ingameMenuNext"),
		["callback"] = self.onPageNext
	}
	self.prevPageButtonInfo = {
		["inputAction"] = InputAction.MENU_PAGE_PREV,
		["text"] = g_i18n:getText("ui_ingameMenuPrev"),
		["callback"] = self.onPagePrevious
	}
	self.applyButtonInfo = {
		["inputAction"] = InputAction.MENU_ACCEPT,
		["text"] = g_i18n:getText(SettingsAdvancedFrame.L10N_SYMBOL.BUTTON_APPLY),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onApplySettings()
		end
	}
	self.settingElements = {}
	local function v17_(p12_, p13_, p14_)
		-- upvalues: (copy) self
		self.settingElements[p13_] = {
			["settingsKey"] = p12_,
			["element"] = p13_,
			["isMultiElement"] = p14_
		}
		local v15_ = g_settingsModel:getTexts(p12_)
		if v15_ == nil then
			p13_:setVisible(false)
		else
			if #v15_ == 0 then
				local v16_ = g_i18n
				table.insert(v15_, v16_:getText("ui_unavailable"))
				p13_.parent:setDisabled(true)
			else
				p13_.parent:setDisabled(false)
			end
			if p14_ or #v15_ == 2 then
				p13_:setTexts(v15_)
				return
			end
		end
	end
	v17_(SettingsModel.SETTING.POST_PROCESS_AA, self.ppaaElement, true)
	v17_(SettingsModel.SETTING.MSAA, self.msaaElement, true)
	v17_(SettingsModel.SETTING.LENSFLARE_QUALITY, self.lensFlareQualityElement, true)
	v17_(SettingsModel.SETTING.VALAR, self.valarElement, true)
	v17_(SettingsModel.SETTING.SCREEN_SPACE_REFLECTIONS, self.screenSpaceReflectionsElement, true)
	v17_(SettingsModel.SETTING.SCREEN_SPACE_SHADOWS_QUALITY, self.screenSpaceShadowsQualityElement, false)
	v17_(SettingsModel.SETTING.DRS_QUALITY, self.drsQualityElement, true)
	v17_(SettingsModel.SETTING.ATMOSPHERE_QUALITY, self.atmosphereQualityElement, true)
	v17_(SettingsModel.SETTING.VOLUMETRIC_FOG_QUALITY, self.volumetricFogQualityElement, true)
	v17_(SettingsModel.SETTING.TEXTURE_FILTERING, self.textureFilteringElement, true)
end

-- Local values: oldDisableFunc, containerDisableFunc, _, container, _, name, index, scalingMode
function SettingsAdvancedFrame:onGuiSetupFinished()
	SettingsAdvancedFrame:superClass().onGuiSetupFinished(self)
	local v_u_19_ = self.msaaContainer.setDisabled
	local function v22_(p20_, p21_)
		-- upvalues: (copy) v_u_19_
		v_u_19_(p20_, p21_)
		p20_:getDescendantByName("iconDisabled"):setDisabled(not p21_)
	end
	for _, v23_ in pairs(self.boxLayout.elements) do
		if v23_:getDescendantByName("iconDisabled") ~= nil then
			v23_.setDisabled = v22_
		end
	end
	function self.frameGenerationContainer.getIsActiveNonRec()
		-- upvalues: (copy) self
		return self.frameGenerationElement:getIsActiveNonRec()
	end
	self.scalingModeNameToIndexMapping = {}
	for _, v24_ in pairs(g_settingsModel:getScalingModeTexts()) do
		for v25_, v26_ in pairs(SettingsAdvancedFrame.SCALING_MODES) do
			if g_i18n:getText(v26_.title) == v24_ then
				self.scalingModeNameToIndexMapping[v24_] = v25_
				break
			end
		end
	end
end

-- Local values: needsRestart, needsProcessRestart
function SettingsAdvancedFrame:onApplySettings()
	local v28_, v_u_29_ = g_settingsModel:needsRestartToApplyChanges()
	g_settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_ALL)
	if v28_ then
		RestartManager:setStartScreen(RestartManager.START_SCREEN_SETTINGS_ADVANCED)
		InfoDialog.show(g_i18n:getText("dialog_restartToApplyChanges"), function()
			-- upvalues: (copy) v_u_29_
			doRestart(v_u_29_, "")
		end, nil)
	else
		self:setMenuButtonInfoDirty()
	end
end

-- Local values: buttons
function SettingsAdvancedFrame:getMenuButtonInfo()
	local v31_ = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
	if g_settingsModel:hasChanges() then
		local v32_ = self.applyButtonInfo
		table.insert(v31_, v32_)
	end
	return v31_
end

-- Local values: _, data, postProcessAA, isNativeFSR3, isFSR30Active, isFSRActive, supportsFrameGeneration, frameGenerationActive, supportsXeSSFrameGeneration, isNativeXeSS, isXeSSActive, xessFrameGenerationActive, supportsDLSSFrameGeneration, isDLSSActive, isDLAAActive, dlssFrameGenerationActive, isDRSAvailable, frameGenerationElementTexts, textsFunc, i, frameGenerationState, settingsKey, _, setting, currentValue, state, texts, sharpnessAvailable, isMSAAAllowed
function SettingsAdvancedFrame:updateValues()
	self:updatePerformanceClass()
	for _, v34_ in pairs(self.settingElements) do
		if v34_.isMultiElement then
			v34_.element:setState(g_settingsModel:getValue(v34_.settingsKey) or 1)
		else
			v34_.element:setIsChecked(g_settingsModel:getValue(v34_.settingsKey) == BinaryOptionElement.STATE_RIGHT, self.isOpening)
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
	local v35_ = g_settingsModel:getRawValue(SettingsModel.SETTING.POST_PROCESS_AA)
	local v36_ = v35_ == PostProcessAntiAliasing.FSR3
	local v37_ = g_settingsModel:getRawValue(SettingsModel.SETTING.FIDELITYFX_SR_30) ~= FidelityFxSR30Quality.OFF
	local v38_ = g_settingsModel:getRawValue(SettingsModel.SETTING.FIDELITYFX_SR) ~= FidelityFxSRQuality.OFF
	local v39_ = getSupportsFidelityFxFrameInterpolation(FrameInterpolationMode.FRAME_INTERPOLATION_2X)
	if v39_ then
		if v36_ or v37_ then
			v39_ = g_settingsModel:getValue(SettingsModel.SETTING.FULLSCREEN_MODE) ~= FullscreenMode.EXCLUSIVE_FULLSCREEN
		else
			v39_ = v37_
		end
	end
	local v40_ = getSupportsXeSSFrameInterpolation(FrameInterpolationMode.FRAME_INTERPOLATION_2X)
	local v41_ = v35_ == PostProcessAntiAliasing.XESS
	local v42_ = g_settingsModel:getRawValue(SettingsModel.SETTING.XESS) ~= XeSSQuality.OFF
	if v40_ then
		if v41_ or v42_ then
			v40_ = g_settingsModel:getValue(SettingsModel.SETTING.FULLSCREEN_MODE) ~= FullscreenMode.EXCLUSIVE_FULLSCREEN
		else
			v40_ = v42_
		end
	end
	local v43_ = getSupportsDLSSFrameInterpolation(FrameInterpolationMode.FRAME_INTERPOLATION_2X)
	local v44_ = g_settingsModel:getRawValue(SettingsModel.SETTING.DLSS) ~= DLSSQuality.OFF
	local v45_ = g_settingsModel:getRawValue(SettingsModel.SETTING.POST_PROCESS_AA) == PostProcessAntiAliasing.DLAA
	if v43_ then
		if v44_ or v45_ then
			v45_ = g_settingsModel:getValue(SettingsModel.SETTING.FULLSCREEN_MODE) ~= FullscreenMode.EXCLUSIVE_FULLSCREEN
		end
	else
		v45_ = v43_
	end
	local v46_ = getIsDRSAvailable()
	self.drsQualityContainer:setDisabled(not v46_)
	self.drsTargetFPSContainer:setDisabled(not v46_)
	self.frameGenerationContainer:setDisabled(not (v39_ or (v40_ or v45_)))
	self.resolutionScale3dContainer:setDisabled(v44_ or (v42_ or (v37_ or v38_)))
	local v47_ = { getFrameInterpolationModeName(FrameInterpolationMode.FRAME_INTERPOLATION_OFF) }
	local v48_ = getSupportsDLSSFrameInterpolation
	if v40_ then
		v48_ = getSupportsXeSSFrameInterpolation
	elseif v39_ then
		v48_ = getSupportsFidelityFxFrameInterpolation
	end
	for v49_ = 1, EnumUtil.getNumEntries(FrameInterpolationMode) - 1 do
		if v48_(v49_) then
			local v50_ = getFrameInterpolationModeName
			table.insert(v47_, v50_(v49_))
		end
	end
	self.frameGenerationElement:setTexts(v47_)
	local v51_ = g_settingsModel:getValue(SettingsModel.SETTING.FIDELITYFX_SR_30_FRAME_GENERATION)
	local v52_ = g_settingsModel:getValue(SettingsModel.SETTING.XESS_FRAME_GENERATION)
	local v53_ = g_settingsModel
	local v54_ = SettingsModel.SETTING.DLSS_FRAME_GENERATION
	local v55_ = math.max(v51_, v52_, v53_:getValue(v54_))
	self.frameGenerationElement:setState(v55_ + 1)
	if v41_ or v42_ then
		self.frameGenerationTitle:setText(g_i18n:getText("setting_xeSSFrameGeneration"))
		self.frameGenerationTooltip:setText(g_i18n:getText("toolTip_xeSSFrameGeneration"))
	elseif v36_ or v37_ then
		self.frameGenerationTitle:setText(g_i18n:getText("setting_fidelityFxSR30FrameInterpolation"))
		self.frameGenerationTooltip:setText(g_i18n:getText("toolTip_fidelityFxSR30FrameInterpolation"))
	elseif v44_ then
		self.frameGenerationTitle:setText(g_i18n:getText("setting_dlssFrameInterpolation"))
		self.frameGenerationTooltip:setText(g_i18n:getText("toolTip_dlssFrameInterpolation"))
	else
		self.frameGenerationTitle:setText(g_i18n:getText("setting_frameGeneration"))
	end
	local v56_ = nil
	for _, v57_ in pairs(SettingsAdvancedFrame.SCALING_MODES) do
		local v58_ = g_settingsModel:getRawValue(v57_.name)
		if v58_ ~= nil and v58_ ~= v57_.enum.OFF then
			local v59_ = self.scalingModeNameToIndexMapping[g_i18n:getText(v57_.title)] or 1
			self.scalingModeElement:setState(v59_)
			v56_ = v57_.name
			break
		end
	end
	if v56_ == nil then
		self.scalingModeElement:setState(1)
	else
		local v60_ = g_settingsModel:getTexts(v56_)
		if v46_ and g_settingsModel:getRawValue(SettingsModel.SETTING.DRS_QUALITY) ~= DRSQuality.OFF then
			self.scalingModeQualityElement:setTexts({ g_i18n:getText("ui_auto") })
			self.scalingModeQualityElement:setState(1)
			self.scalingModeQualityContainer:setDisabled(true)
		else
			self.scalingModeQualityElement:setTexts(v60_)
			self.scalingModeQualityContainer:setDisabled(false)
			self.scalingModeQualityElement:setState(g_settingsModel:getValue(v56_))
		end
	end
	local v61_ = self.ppaaElement:getState() ~= 1 and true or v56_ ~= nil
	self.sharpnessContainer:setDisabled(not v61_)
	local v62_ = self.ppaaElement:getState() - 1 ~= PostProcessAntiAliasing.TAA and true or self.ppaaElement:getState() - 1 ~= PostProcessAntiAliasing.OFF
	self.msaaContainer:setDisabled(not v62_)
	self.scalingModeQualityContainer:setDisabled(v56_ == nil)
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

-- Local values: isAlternate, _, container
function SettingsAdvancedFrame:updateAlternatingSettingsBackgrounds()
	local v65_ = true
	for _, v66_ in pairs(self.boxLayout.elements) do
		if v66_.name == "sectionHeader" then
			v65_ = true
		elseif v66_:getIsVisible() then
			local v67_ = SettingsScreen.COLOR_ALTERNATING[v65_]
			v66_:setImageColor(nil, unpack(v67_))
			v65_ = not v65_
		end
	end
	self.boxLayout:invalidateLayout()
end

-- Local values: texts, _, _
function SettingsAdvancedFrame:updatePerformanceClass()
	local v69_, _, _ = g_settingsModel:getPerformanceClassTexts()
	self.performanceClassElement:setTexts(v69_)
end

-- Local values: texts, _, _
function SettingsAdvancedFrame:onCreatePerformanceClass(element)
	local v71_, _, _ = g_settingsModel:getPerformanceClassTexts()
	element:setTexts(v71_)
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

-- Local values: data
function SettingsAdvancedFrame:onClick(state, element)
	local v104_ = self.settingElements[element]
	g_settingsModel:setValue(v104_.settingsKey, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end

function SettingsAdvancedFrame:onClickPerformanceClass(state)
	g_settingsModel:applyPerformanceClass(state)
	self:updateValues()
end

-- Local values: data
function SettingsAdvancedFrame:onClickPPAA(state, element)
	local v110_ = self.settingElements[element]
	g_settingsModel:setValue(v110_.settingsKey, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end

function SettingsAdvancedFrame:onClickMSAA(state)
	self.sharpnessContainer:setDisabled(state ~= 1)
	g_settingsModel:setValue(SettingsModel.SETTING.MSAA, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end

-- Local values: foundSetting, settingName, name, index, setting, texts
function SettingsAdvancedFrame:onClickScalingMode(state)
	local v115_ = g_settingsModel:getScalingModeTexts()[state]
	local v116_ = nil
	for v117_, v118_ in pairs(self.scalingModeNameToIndexMapping) do
		local v119_ = SettingsAdvancedFrame.SCALING_MODES[v118_]
		if v117_ == v115_ then
			v116_ = v119_
		else
			g_settingsModel:setRawValue(v119_.name, v119_.enum.OFF)
		end
	end
	if v116_ ~= nil then
		g_settingsModel:setValue(v116_.name, 1)
		local v120_ = g_settingsModel:getTexts(v116_.name)
		self.scalingModeQualityElement:setTexts(v120_)
	end
	g_settingsModel:applyCustomSettings()
	if not getIsDRSAvailable() then
		g_settingsModel:setRawValue(SettingsModel.SETTING.DRS_QUALITY, DRSQuality.OFF)
	end
	self:updateValues()
end

-- Local values: foundSetting, settingName, name, index, setting, settingsKey
function SettingsAdvancedFrame:onClickScalingModeQuality(state)
	local v123_ = g_settingsModel:getScalingModeTexts()[self.scalingModeElement:getState()]
	local v124_ = nil
	for v125_, v126_ in pairs(self.scalingModeNameToIndexMapping) do
		local v127_ = SettingsAdvancedFrame.SCALING_MODES[v126_]
		if v125_ == v123_ then
			v124_ = v127_
			break
		end
	end
	local v128_ = v124_.name
	g_settingsModel:setValue(v128_, state)
	g_settingsModel:applyCustomSettings()
	self:updateValues()
end

-- Local values: isNativeXeSS, isXeSSActive, isDLSSActive, isNativeFSR3, isFSR30Active
function SettingsAdvancedFrame:onClickFrameGeneration(state)
	local v130_ = g_settingsModel:getRawValue(SettingsModel.SETTING.POST_PROCESS_AA) == PostProcessAntiAliasing.XESS
	local v131_ = g_settingsModel:getRawValue(SettingsModel.SETTING.XESS) ~= XeSSQuality.OFF
	local v132_ = g_settingsModel:getRawValue(SettingsModel.SETTING.DLSS) ~= DLSSQuality.OFF
	local v133_ = g_settingsModel:getRawValue(SettingsModel.SETTING.POST_PROCESS_AA) == PostProcessAntiAliasing.FSR3
	local v134_ = g_settingsModel:getRawValue(SettingsModel.SETTING.FIDELITYFX_SR_30) ~= FidelityFxSR30Quality.OFF
	if v130_ or v131_ then
		g_settingsModel:setValue(SettingsModel.SETTING.XESS_FRAME_GENERATION, self.frameGenerationElement:getState() - 1)
	elseif v132_ then
		g_settingsModel:setValue(SettingsModel.SETTING.DLSS_FRAME_GENERATION, self.frameGenerationElement:getState() - 1)
	elseif v133_ or v134_ then
		g_settingsModel:setValue(SettingsModel.SETTING.FIDELITYFX_SR_30_FRAME_GENERATION, self.frameGenerationElement:getState() - 1)
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
SettingsAdvancedFrame.L10N_SYMBOL = {
	["BUTTON_APPLY"] = "button_apply"
}
local v192_ = getFidelityFxSuperResolutionVersion() == 4 and "setting_fsr4" or "setting_fsr3"
SettingsAdvancedFrame.SCALING_MODES = {
	[2] = {
		["name"] = SettingsModel.SETTING.FIDELITYFX_SR,
		["enum"] = FidelityFxSRQuality,
		["title"] = "setting_fsr1"
	},
	[3] = {
		["name"] = SettingsModel.SETTING.FIDELITYFX_SR_30,
		["enum"] = FidelityFxSR30Quality,
		["title"] = v192_
	},
	[4] = {
		["name"] = SettingsModel.SETTING.DLSS,
		["enum"] = DLSSQuality,
		["title"] = "setting_DLSS"
	},
	[5] = {
		["name"] = SettingsModel.SETTING.XESS,
		["enum"] = XeSSQuality,
		["title"] = "setting_xeSS"
	}
}
