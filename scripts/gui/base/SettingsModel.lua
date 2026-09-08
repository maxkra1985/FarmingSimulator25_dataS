-- Local values: SettingsModel_mt
SettingsModel = {}
local SettingsModel_mt = Class(SettingsModel)
SettingsModel.SETTING_CLASS = {
	["SAVE_NONE"] = 0,
	["SAVE_ENGINE_QUALITY_SETTINGS"] = 1,
	["SAVE_GAMEPLAY_SETTINGS"] = 2,
	["SAVE_ALL"] = 3
}
SettingsModel.SETTING = {
	["PERFORMANCE_CLASS"] = "performanceClass",
	["PERFORMANCE_MODE"] = "performanceMode",
	["HDR_ENABLED"] = "hdrEnabled",
	["HDR_PEAK_BRIGHTNESS"] = "hdrPeakBrightness",
	["HDR_CONTRAST"] = "hdrContrast",
	["OVERLAY_BRIGHTNESS"] = "overlayBrightness",
	["MSAA"] = "msaa",
	["TEXTURE_FILTERING"] = "textureFiltering",
	["TEXTURE_RESOLUTION"] = "textureResolution",
	["SHADOW_QUALITY"] = "shadowQuality",
	["SHADOW_DISTANCE_QUALITY"] = "shadowDistanceQuality",
	["SOFT_SHADOWS"] = "softShadows",
	["SCREEN_SPACE_SHADOWS_QUALITY"] = "screenSpaceShadowsQuality",
	["SHADER_QUALITY"] = "shaderQuality",
	["SHADOW_MAP_FILTERING"] = "shadowMapFiltering",
	["MAX_LIGHTS"] = "maxLights",
	["TERRAIN_QUALITY"] = "terrainQuality",
	["OBJECT_DRAW_DISTANCE"] = "objectDrawDistance",
	["FOLIAGE_DRAW_DISTANCE"] = "foliageDrawDistance",
	["FOLIAGE_SHADOW"] = "foliageShadow",
	["LOD_DISTANCE"] = "lodDistance",
	["TERRAIN_LOD_DISTANCE"] = "terrainLODDistance",
	["FOLIAGE_LOD_DISTANCE"] = "foliageLODDistance",
	["VOLUME_MESH_TESSELLATION"] = "volumeMeshTessellation",
	["MAX_TIRE_TRACKS"] = "maxTireTracks",
	["LIGHTS_PROFILE"] = GameSettings.SETTING.LIGHTS_PROFILE,
	["REAL_BEACON_LIGHTS"] = GameSettings.SETTING.REAL_BEACON_LIGHTS,
	["MAX_MIRRORS"] = GameSettings.SETTING.MAX_NUM_MIRRORS,
	["POST_PROCESS_AA"] = "postProcessAntiAliasing",
	["DLSS"] = "dlss",
	["DLSS_FRAME_GENERATION"] = "dlssFrameGeneration",
	["FIDELITYFX_SR"] = "fidelityFxSR",
	["FIDELITYFX_SR_30"] = "fidelityFxSR30",
	["FIDELITYFX_SR_30_FRAME_GENERATION"] = "fidelityFxSR30FrameGeneration",
	["DRS_QUALITY"] = "drsQuality",
	["DRS_TARGET_FPS"] = "drsTargetFPS",
	["VALAR"] = "valar",
	["SCREEN_SPACE_REFLECTIONS"] = "screenSpaceReflections",
	["XESS"] = "xess",
	["XESS_FRAME_GENERATION"] = "xessFrameGeneration",
	["SHARPNESS"] = "sharpness",
	["SHADING_RATE_QUALITY"] = "shadingRateQuality",
	["SSAO_QUALITY"] = "ssaoQuality",
	["ATMOSPHERE_QUALITY"] = "atmosphereQuality",
	["VOLUMETRIC_FOG_QUALITY"] = "volumetricFogQuality",
	["CLOUD_SHADOWS_QUALITY"] = "cloudShadowsQuality",
	["LENSFLARE_QUALITY"] = "lensFlareQuality",
	["FULLSCREEN_MODE"] = "fullscreenMode",
	["INPUT_HELP_MODE"] = GameSettings.SETTING.INPUT_HELP_MODE,
	["GAMEPAD_ENABLED"] = GameSettings.SETTING.IS_GAMEPAD_ENABLED,
	["HEAD_TRACKING_ENABLED"] = GameSettings.SETTING.IS_HEAD_TRACKING_ENABLED,
	["FORCE_FEEDBACK"] = GameSettings.SETTING.FORCE_FEEDBACK,
	["LANGUAGE"] = "language",
	["MP_LANGUAGE"] = "mpLanguage",
	["VOLUME_MUSIC"] = GameSettings.SETTING.VOLUME_MUSIC,
	["UI_SCALE"] = GameSettings.SETTING.UI_SCALE,
	["RESOLUTION"] = "resolution",
	["BRIGHTNESS"] = "brightness",
	["V_SYNC"] = "vSync",
	["FOV_Y"] = GameSettings.SETTING.FOV_Y,
	["FOV_Y_PLAYER_FIRST_PERSON"] = GameSettings.SETTING.FOV_Y_PLAYER_FIRST_PERSON,
	["FOV_Y_PLAYER_THIRD_PERSON"] = GameSettings.SETTING.FOV_Y_PLAYER_THIRD_PERSON,
	["CAMERA_BOBBING"] = GameSettings.SETTING.CAMERA_BOBBING,
	["FRAME_LIMIT"] = GameSettings.SETTING.FRAME_LIMIT,
	["INVERT_Y_LOOK"] = GameSettings.SETTING.INVERT_Y_LOOK,
	["VOLUME_MASTER"] = GameSettings.SETTING.VOLUME_MASTER,
	["SHOW_HELP_MENU"] = GameSettings.SETTING.SHOW_HELP_MENU,
	["EASY_ARM_CONTROL"] = GameSettings.SETTING.EASY_ARM_CONTROL,
	["VOLUME_ENVIRONMENT"] = GameSettings.SETTING.VOLUME_ENVIRONMENT,
	["VOLUME_CHARACTER"] = GameSettings.SETTING.VOLUME_CHARACTER,
	["VOLUME_VEHICLE"] = GameSettings.SETTING.VOLUME_VEHICLE,
	["RADIO_VEHICLE_ONLY"] = GameSettings.SETTING.RADIO_VEHICLE_ONLY,
	["RADIO_IS_ACTIVE"] = GameSettings.SETTING.RADIO_IS_ACTIVE,
	["VOLUME_RADIO"] = GameSettings.SETTING.VOLUME_RADIO,
	["VOLUME_GUI"] = GameSettings.SETTING.VOLUME_GUI,
	["VOLUME_NO_FOCUS"] = GameSettings.SETTING.VOLUME_NO_FOCUS,
	["VOLUME_VOICE"] = GameSettings.SETTING.VOLUME_VOICE,
	["VOLUME_VOICE_INPUT"] = GameSettings.SETTING.VOLUME_VOICE_INPUT,
	["VOICE_MODE"] = GameSettings.SETTING.VOICE_MODE,
	["VOICE_INPUT_SENSITIVITY"] = GameSettings.SETTING.VOICE_INPUT_SENSITIVITY,
	["SHOW_HELP_ICONS"] = GameSettings.SETTING.SHOW_HELP_ICONS,
	["USE_COLORBLIND_MODE"] = GameSettings.SETTING.USE_COLORBLIND_MODE,
	["SHOW_TRIGGER_MARKER"] = GameSettings.SETTING.SHOW_TRIGGER_MARKER,
	["SHOW_HELP_TRIGGER"] = GameSettings.SETTING.SHOW_HELP_TRIGGER,
	["SHOW_FIELD_INFO"] = GameSettings.SETTING.SHOW_FIELD_INFO,
	["USE_MILES"] = GameSettings.SETTING.USE_MILES,
	["USE_FAHRENHEIT"] = GameSettings.SETTING.USE_FAHRENHEIT,
	["USE_ACRE"] = GameSettings.SETTING.USE_ACRE,
	["MONEY_UNIT"] = GameSettings.SETTING.MONEY_UNIT,
	["RESET_CAMERA"] = GameSettings.SETTING.RESET_CAMERA,
	["USE_WORLD_CAMERA"] = GameSettings.SETTING.USE_WORLD_CAMERA,
	["ACTIVE_SUSPENSION_CAMERA"] = GameSettings.SETTING.ACTIVE_SUSPENSION_CAMERA,
	["CAMERA_CHECK_COLLISION"] = GameSettings.SETTING.CAMERA_CHECK_COLLISION,
	["IS_TRAIN_TABBABLE"] = GameSettings.SETTING.IS_TRAIN_TABBABLE,
	["CAMERA_SENSITIVITY"] = GameSettings.SETTING.CAMERA_SENSITIVITY,
	["VEHICLE_ARM_SENSITIVITY"] = GameSettings.SETTING.VEHICLE_ARM_SENSITIVITY,
	["REAL_BEACON_LIGHT_BRIGHTNESS"] = GameSettings.SETTING.REAL_BEACON_LIGHT_BRIGHTNESS,
	["STEERING_BACK_SPEED"] = GameSettings.SETTING.STEERING_BACK_SPEED,
	["STEERING_SENSITIVITY"] = GameSettings.SETTING.STEERING_SENSITIVITY,
	["DIRECTION_CHANGE_MODE"] = GameSettings.SETTING.DIRECTION_CHANGE_MODE,
	["GEAR_SHIFT_MODE"] = GameSettings.SETTING.GEAR_SHIFT_MODE,
	["HUD_SPEED_GAUGE"] = GameSettings.SETTING.HUD_SPEED_GAUGE,
	["WOOD_HARVESTER_AUTO_CUT"] = GameSettings.SETTING.WOOD_HARVESTER_AUTO_CUT,
	["SHOW_MULTIPLAYER_NAMES"] = GameSettings.SETTING.SHOW_MULTIPLAYER_NAMES,
	["GYROSCOPE_STEERING"] = GameSettings.SETTING.GYROSCOPE_STEERING,
	["CAMERA_TILTING"] = GameSettings.SETTING.CAMERA_TILTING,
	["HINTS"] = GameSettings.SETTING.HINTS,
	["RESOLUTION_SCALE"] = "resolutionScale",
	["RESOLUTION_SCALE_3D"] = "resolutionScale3d"
}
function SettingsModel.new()
	-- upvalues: (copy) SettingsModel_mt
	local v2_ = SettingsModel_mt
	local v3_ = setmetatable({}, v2_)
	v3_.settings = {}
	v3_.sortedSettings = {}
	v3_.settingReaders = {}
	v3_.settingWriters = {}
	v3_.settingTexts = {}
	v3_.settingsRawToValues = {}
	v3_.settingsValueToRaws = {}
	v3_.settingsOnChanges = {}
	v3_.defaultReaderFunction = v3_:makeDefaultReaderFunction()
	v3_.defaultWriterFunction = v3_:makeDefaultWriterFunction()
	v3_.volumeTexts = {}
	v3_.voiceInputThresholdTexts = {}
	v3_.recordingVolumeTexts = {}
	v3_.voiceModeTexts = {}
	v3_.brightnessTexts = {}
	v3_.fovYTexts = {}
	v3_.indexToFovYMapping = {}
	v3_.fovYToIndexMapping = {}
	v3_.uiScaleValues = {}
	v3_.uiScaleTexts = {}
	v3_.cameraSensitivityValues = {}
	v3_.cameraSensitivityStrings = {}
	v3_.cameraSensitivityStep = 0.25
	v3_.vehicleArmSensitivityValues = {}
	v3_.vehicleArmSensitivityStrings = {}
	v3_.vehicleArmSensitivityStep = 0.25
	v3_.realBeaconLightBrightnessValues = {}
	v3_.realBeaconLightBrightnessStrings = {}
	v3_.realBeaconLightBrightnessStep = 0.1
	v3_.steeringBackSpeedValues = {}
	v3_.steeringBackSpeedStrings = {}
	v3_.steeringBackSpeedStep = 1
	v3_.steeringSensitivityValues = {}
	v3_.steeringSensitivityStrings = {}
	v3_.steeringSensitivityStep = 0.1
	v3_.moneyUnitTexts = {}
	v3_.distanceUnitTexts = {}
	v3_.temperatureUnitTexts = {}
	v3_.areaUnitTexts = {}
	v3_.radioModeTexts = {}
	v3_.resolutionScaleTexts = {}
	v3_.resolutionScale3dTexts = {}
	v3_.drsTargetFPSTexts = {}
	v3_.sharpnessTexts = {}
	v3_.scalingModeTexts = {}
	v3_.shadowQualityTexts = {}
	v3_.shadowDistanceQualityTexts = {}
	v3_.softShadowsTexts = {}
	v3_.fourStateTexts = {}
	v3_.lowHighTexts = {}
	v3_.shadowMapMaxLightsTexts = {}
	v3_.hdrPeakBrightnessValues = {}
	v3_.hdrPeakBrightnessTexts = {}
	v3_.hdrPeakBrightnessStep = 0.05
	v3_.hdrContrastValues = {}
	v3_.hdrContrastTexts = {}
	v3_.hdrContrastStep = 0.01
	v3_.overlayBrightnessValues = {}
	v3_.overlayBrightnessTexts = {}
	v3_.overlayBrightnessStep = 0.05
	v3_.percentValues = {}
	v3_.perentageTexts = {}
	v3_.percentStep = 0.05
	v3_.tireTracksValues = {}
	v3_.tireTracksTexts = {}
	v3_.tireTracksStep = 0.5
	v3_.maxMirrorsTexts = {}
	v3_.ssaoQualityTexts = {}
	v3_.resolutionTexts = {}
	v3_.fullscreenModeTexts = {}
	v3_.mpLanguageTexts = {}
	v3_.inputHelpModeTexts = {}
	v3_.directionChangeModeTexts = {}
	v3_.gearShiftModeTexts = {}
	v3_.hudSpeedGaugeTexts = {}
	v3_.frameLimitTexts = {}
	v3_.intialValues = {}
	v3_.deviceSettings = {}
	v3_.currentDevice = {}
	v3_.minBrightness = 0.5
	v3_.maxBrightness = 2
	v3_.brightnessStep = 0.1
	v3_.minSharpness = 0
	v3_.maxSharpness = 2
	v3_.sharpnessStep = 0.1
	v3_.qualityTexts = {
		["OFF"] = g_i18n:getText("ui_off"),
		["ON"] = g_i18n:getText("ui_on"),
		["LOW"] = g_i18n:getText("setting_low"),
		["MEDIUM"] = g_i18n:getText("setting_medium"),
		["HIGH"] = g_i18n:getText("setting_high"),
		["VERY_HIGH"] = g_i18n:getText("setting_veryHigh"),
		["ULTRA"] = g_i18n:getText("setting_ultra"),
		["MAX_QUALITY"] = g_i18n:getText("setting_maxQuality"),
		["BALANCED_PERFORMANCE"] = g_i18n:getText("setting_balancedPerformance"),
		["MAX_PERFORMANCE"] = g_i18n:getText("setting_maxPerformance"),
		["ULTRA_PERFORMANCE"] = g_i18n:getText("setting_ultraPerformance"),
		["ULTRA_QUALITY"] = g_i18n:getText("setting_ultraQuality"),
		["ULTRA_QUALITY_PLUS"] = g_i18n:getText("setting_ultraQualityPlus"),
		["QUALITY"] = g_i18n:getText("setting_quality"),
		["BALANCED"] = g_i18n:getText("setting_balanced"),
		["PERFORMANCE"] = g_i18n:getText("setting_performance")
	}
	v3_:initialize()
	return v3_
end

function SettingsModel:initialize()
	self:createControlDisplayValues()
	self:addManagedSettings()
end

function SettingsModel:addManagedSettings()
	if not Platform.isConsole then
		self:addPerformanceClassSetting()
		self:addEngineQualitySetting(SettingsModel.SETTING.ATMOSPHERE_QUALITY, AtmosphereQuality, getSupportsAtmosphereQuality, getAtmosphereQualityName, setAtmosphereQuality, getAtmosphereQuality)
		self:addEngineQualitySetting(SettingsModel.SETTING.DRS_QUALITY, DRSQuality, getSupportsDRSQuality, getDRSQualityName, setDRSQuality, getDRSQuality)
		self:addEngineQualitySetting(SettingsModel.SETTING.LENSFLARE_QUALITY, LensFlareQuality, getSupportsLensFlareQuality, getLensFlareQualityName, setLensFlareQuality, getLensFlareQuality)
		self:addEngineQualitySetting(SettingsModel.SETTING.VOLUMETRIC_FOG_QUALITY, VolumetricFogQuality, getSupportsVolumetricFogQuality, getVolumetricFogQualityName, setVolumetricFogQuality, getVolumetricFogQuality)
		self:addEngineQualitySetting(SettingsModel.SETTING.SCREEN_SPACE_REFLECTIONS, ScreenSpaceReflectionsQuality, getSupportsScreenSpaceReflectionsQuality, getScreenSpaceReflectionsQualityName, setScreenSpaceReflectionsQuality, getScreenSpaceReflectionsQuality)
		self:addEngineQualitySetting(SettingsModel.SETTING.SCREEN_SPACE_SHADOWS_QUALITY, ScreenSpaceShadowsQuality, getSupportsScreenSpaceShadowsQuality, getScreenSpaceShadowsQualityName, setScreenSpaceShadowsQuality, getScreenSpaceShadowsQuality)
		self:addEngineQualitySetting(SettingsModel.SETTING.TEXTURE_FILTERING, TEXTURE_FILTERING, nil, getTextureFilteringName, setTextureFiltering, getTextureFiltering, nil, nil, false)
		self:addEngineQualitySetting(SettingsModel.SETTING.DLSS, DLSSQuality, getSupportsDLSSQuality, getDLSSQualityName, setDLSSQuality, getDLSSQuality, function(_, p6_, _)
			-- upvalues: (copy) self
			if p6_ == DLSSQuality.OFF then
				self:setRawValue(SettingsModel.SETTING.DLSS_FRAME_GENERATION, FrameInterpolationMode.FRAME_INTERPOLATION_OFF)
			else
				self:setRawValue(SettingsModel.SETTING.RESOLUTION_SCALE, SettingsModel.getScalingStateFromResolutionScaling(1))
				self:setRawValue(SettingsModel.SETTING.RESOLUTION_SCALE_3D, SettingsModel.getScalingStateFromResolutionScaling(1))
				self:setRawValue(SettingsModel.SETTING.MSAA, MSAA.OFF)
				self:setRawValue(SettingsModel.SETTING.FIDELITYFX_SR, FidelityFxSRQuality.OFF)
				self:setRawValue(SettingsModel.SETTING.FIDELITYFX_SR_30, FidelityFxSR30Quality.OFF)
				self:setRawValue(SettingsModel.SETTING.XESS, XeSSQuality.OFF)
				self:setRawValue(SettingsModel.SETTING.POST_PROCESS_AA, PostProcessAntiAliasing.OFF)
			end
		end, true)
		self:addEngineQualitySetting(SettingsModel.SETTING.FIDELITYFX_SR, FidelityFxSRQuality, getSupportsFidelityFxSRQuality, getFidelityFxSRQualityName, setFidelityFxSRQuality, getFidelityFxSRQuality, function(_, p7_, _)
			-- upvalues: (copy) self
			if p7_ ~= FidelityFxSRQuality.OFF then
				self:setRawValue(SettingsModel.SETTING.RESOLUTION_SCALE, SettingsModel.getScalingStateFromResolutionScaling(1))
				self:setRawValue(SettingsModel.SETTING.RESOLUTION_SCALE_3D, SettingsModel.getScalingStateFromResolutionScaling(1))
				self:setRawValue(SettingsModel.SETTING.POST_PROCESS_AA, PostProcessAntiAliasing.TAA)
				self:setRawValue(SettingsModel.SETTING.DLSS, DLSSQuality.OFF)
				self:setRawValue(SettingsModel.SETTING.FIDELITYFX_SR_30, FidelityFxSR30Quality.OFF)
				self:setRawValue(SettingsModel.SETTING.XESS, XeSSQuality.OFF)
			end
		end, true)
		self:addEngineQualitySetting(SettingsModel.SETTING.FIDELITYFX_SR_30, FidelityFxSR30Quality, getSupportsFidelityFxSR30Quality, getFidelityFxSR30QualityName, setFidelityFxSR30Quality, getFidelityFxSR30Quality, function(_, p8_, _)
			-- upvalues: (copy) self
			if p8_ == FidelityFxSR30Quality.OFF then
				self:setValue(SettingsModel.SETTING.FIDELITYFX_SR_30_FRAME_GENERATION, FrameInterpolationMode.FRAME_INTERPOLATION_OFF)
			else
				self:setRawValue(SettingsModel.SETTING.RESOLUTION_SCALE, SettingsModel.getScalingStateFromResolutionScaling(1))
				self:setRawValue(SettingsModel.SETTING.RESOLUTION_SCALE_3D, SettingsModel.getScalingStateFromResolutionScaling(1))
				self:setRawValue(SettingsModel.SETTING.MSAA, MSAA.OFF)
				self:setRawValue(SettingsModel.SETTING.DLSS, DLSSQuality.OFF)
				self:setRawValue(SettingsModel.SETTING.FIDELITYFX_SR, FidelityFxSRQuality.OFF)
				self:setRawValue(SettingsModel.SETTING.XESS, XeSSQuality.OFF)
				self:setRawValue(SettingsModel.SETTING.POST_PROCESS_AA, PostProcessAntiAliasing.OFF)
			end
		end, true)
		self:addEngineQualitySetting(SettingsModel.SETTING.VALAR, ValarQuality, getSupportsValarQuality, getValarQualityName, setValarQuality, getValarQuality, function(_, p9_, _)
			if p9_ ~= ValarQuality.OFF then
				g_settingsModel:setRawValue(SettingsModel.SETTING.MSAA, MSAA.OFF)
			end
		end)
		self:addEngineQualitySetting(SettingsModel.SETTING.XESS, XeSSQuality, getSupportsXeSSQuality, getXeSSQualityName, setXeSSQuality, getXeSSQuality, function(_, p10_, _)
			-- upvalues: (copy) self
			if p10_ ~= XeSSQuality.OFF then
				self:setRawValue(SettingsModel.SETTING.RESOLUTION_SCALE, SettingsModel.getScalingStateFromResolutionScaling(1))
				self:setRawValue(SettingsModel.SETTING.RESOLUTION_SCALE_3D, SettingsModel.getScalingStateFromResolutionScaling(1))
				self:setRawValue(SettingsModel.SETTING.MSAA, MSAA.OFF)
				self:setRawValue(SettingsModel.SETTING.DLSS, DLSSQuality.OFF)
				self:setRawValue(SettingsModel.SETTING.FIDELITYFX_SR, FidelityFxSRQuality.OFF)
				self:setRawValue(SettingsModel.SETTING.FIDELITYFX_SR_30, FidelityFxSR30Quality.OFF)
				self:setRawValue(SettingsModel.SETTING.POST_PROCESS_AA, PostProcessAntiAliasing.OFF)
			end
		end, true)
		self:addEngineQualitySetting(SettingsModel.SETTING.MSAA, MSAA, nil, getMSAAName, setMSAA, getMSAA, function(_, p11_, _)
			-- upvalues: (copy) self
			if p11_ ~= MSAA.OFF then
				self:setRawValue(SettingsModel.SETTING.DLSS, DLSSQuality.OFF)
				self:setRawValue(SettingsModel.SETTING.FIDELITYFX_SR_30, FidelityFxSR30Quality.OFF)
				self:setRawValue(SettingsModel.SETTING.XESS, XeSSQuality.OFF)
				if self:getRawValue(SettingsModel.SETTING.POST_PROCESS_AA) ~= PostProcessAntiAliasing.TAA and self:getRawValue(SettingsModel.SETTING.POST_PROCESS_AA) ~= PostProcessAntiAliasing.OFF then
					self:setRawValue(SettingsModel.SETTING.POST_PROCESS_AA, PostProcessAntiAliasing.OFF)
				end
			end
		end)
		self:addEngineQualitySetting(SettingsModel.SETTING.POST_PROCESS_AA, PostProcessAntiAliasing, getSupportsPostProcessAntiAliasing, getPostProcessAntiAliasingName, setPostProcessAntiAliasing, getPostProcessAntiAliasing, function(_, p12_, _)
			-- upvalues: (copy) self
			if p12_ == PostProcessAntiAliasing.OFF then
				self:setValue(SettingsModel.SETTING.FIDELITYFX_SR_30_FRAME_GENERATION, FrameInterpolationMode.FRAME_INTERPOLATION_OFF)
				self:setValue(SettingsModel.SETTING.XESS_FRAME_GENERATION, FrameInterpolationMode.FRAME_INTERPOLATION_OFF)
			else
				self:setRawValue(SettingsModel.SETTING.DLSS, DLSSQuality.OFF)
				self:setRawValue(SettingsModel.SETTING.DLSS_FRAME_GENERATION, FrameInterpolationMode.FRAME_INTERPOLATION_OFF)
				self:setRawValue(SettingsModel.SETTING.FIDELITYFX_SR_30, FidelityFxSR30Quality.OFF)
				self:setRawValue(SettingsModel.SETTING.XESS, XeSSQuality.OFF)
				if p12_ ~= PostProcessAntiAliasing.FSR3 then
					self:setValue(SettingsModel.SETTING.FIDELITYFX_SR_30_FRAME_GENERATION, FrameInterpolationMode.FRAME_INTERPOLATION_OFF)
				end
				if p12_ ~= PostProcessAntiAliasing.XESS then
					self:setValue(SettingsModel.SETTING.XESS_FRAME_GENERATION, FrameInterpolationMode.FRAME_INTERPOLATION_OFF)
				end
				if p12_ ~= PostProcessAntiAliasing.DLAA then
					self:setRawValue(SettingsModel.SETTING.DLSS_FRAME_GENERATION, FrameInterpolationMode.FRAME_INTERPOLATION_OFF)
				end
				if p12_ ~= PostProcessAntiAliasing.TAA then
					self:setRawValue(SettingsModel.SETTING.MSAA, MSAA.OFF)
				end
				if p12_ == PostProcessAntiAliasing.DLAA then
					self:setRawValue(SettingsModel.SETTING.FIDELITYFX_SR, FidelityFxSRQuality.OFF)
					return
				end
				if p12_ == PostProcessAntiAliasing.FSR3 then
					self:setRawValue(SettingsModel.SETTING.FIDELITYFX_SR, FidelityFxSRQuality.OFF)
					return
				end
			end
		end)
		self:addSetting(SettingsModel.SETTING.RESOLUTION, getScreenMode, setScreenMode, true)
		self:addResolutionScaleSetting()
		self:addResolutionScale3dSetting()
		self:addFidelityFxSR30FrameGenerationSetting()
		self:addXeSSFrameGenerationSetting()
		self:addDLSSFrameGenerationSetting()
		self:addTextureResolutionSetting()
		self:addShadowQualitySetting()
		self:addShadowDistanceQualitySetting()
		self:addSoftShadowsSetting()
		self:addShaderQualitySetting()
		self:addShadowMapFilteringSetting()
		self:addShadowMaxLightsSetting()
		self:addTerrainQualitySetting()
		self:addObjectDrawDistanceSetting()
		self:addFoliageDrawDistanceSetting()
		self:addFoliageShadowSetting()
		self:addLODDistanceSetting()
		self:addTerrainLODDistanceSetting()
		self:addFoliageLODDistanceSetting()
		self:addVolumeMeshTessellationSetting()
		self:addMaxTireTracksSetting()
		self:addLightsProfileSetting()
		self:addMaxMirrorsSetting()
		self:addDRSTargetFPSSetting()
		self:addSharpnessSetting()
		self:addShadingRateQualitySetting()
		self:addSSAOQualitySetting()
		self:addCloudShadowsQualitySetting()
		self:addVSyncSetting()
		self:addSetting(SettingsModel.SETTING.FULLSCREEN_MODE, getFullscreenMode, setFullscreenMode, true)
	end
	self:addPerformanceModeSetting()
	self:addRealBeaconLightsSetting()
	self:addLanguageSetting()
	self:addMPLanguageSetting()
	self:addInputHelpModeSetting()
	self:addBrightnessSetting()
	self:addFovYSetting()
	self:addFovYPlayerFirstPersonSetting()
	self:addFovYPlayerThirdPersonSetting()
	self:addUIScaleSetting()
	self:addMasterVolumeSetting()
	self:addMusicVolumeSetting()
	self:addEnvironmentVolumeSetting()
	self:addVehicleVolumeSetting()
	self:addRadioVolumeSetting()
	self:addVolumeGUISetting()
	self:addVolumeNoFocusSetting()
	self:addVolumeCharacterSetting()
	self:addVoiceVolumeSetting()
	self:addVoiceInputVolumeSetting()
	self:addVoiceModeSetting()
	self:addVoiceInputSensitivitySetting()
	self:addSteeringBackSpeedSetting()
	self:addSteeringSensitivitySetting()
	self:addCameraSensitivitySetting()
	self:addVehicleArmSensitivitySetting()
	self:addRealBeaconLightBrightnessSetting()
	self:addActiveCameraSuspensionSetting()
	self:addCamerCheckCollisionSetting()
	self:addDirectionChangeModeSetting()
	self:addGearShiftModeSetting()
	self:addHudSpeedGaugeSetting()
	self:addWoodHarvesterAutoCutSetting()
	self:addForceFeedbackSetting()
	if Platform.hasAdjustableFrameLimit then
		self:addFrameLimitSetting()
	end
	if Platform.isMobile then
		self:addGyroscopeSteeringSetting()
		self:addHintsSetting()
		self:addCameraTiltingSetting()
	end
	self:addHDRPeakBrightnessSetting()
	self:addHDRContrastSetting()
	self:addOverlayBrightnessSetting()
	self:addHDREnabledSetting()
	self:addDirectSetting(SettingsModel.SETTING.USE_COLORBLIND_MODE)
	self:addDirectSetting(SettingsModel.SETTING.GAMEPAD_ENABLED)
	self:addDirectSetting(SettingsModel.SETTING.SHOW_FIELD_INFO)
	self:addDirectSetting(SettingsModel.SETTING.SHOW_HELP_MENU)
	self:addDirectSetting(SettingsModel.SETTING.RADIO_IS_ACTIVE)
	self:addDirectSetting(SettingsModel.SETTING.RESET_CAMERA)
	self:addDirectSetting(SettingsModel.SETTING.RADIO_VEHICLE_ONLY)
	self:addDirectSetting(SettingsModel.SETTING.IS_TRAIN_TABBABLE)
	self:addDirectSetting(SettingsModel.SETTING.HEAD_TRACKING_ENABLED)
	self:addDirectSetting(SettingsModel.SETTING.USE_FAHRENHEIT)
	self:addDirectSetting(SettingsModel.SETTING.USE_WORLD_CAMERA)
	self:addDirectSetting(SettingsModel.SETTING.MONEY_UNIT)
	self:addDirectSetting(SettingsModel.SETTING.USE_ACRE)
	self:addDirectSetting(SettingsModel.SETTING.EASY_ARM_CONTROL)
	self:addDirectSetting(SettingsModel.SETTING.INVERT_Y_LOOK)
	self:addDirectSetting(SettingsModel.SETTING.USE_MILES)
	self:addDirectSetting(SettingsModel.SETTING.SHOW_TRIGGER_MARKER)
	self:addDirectSetting(SettingsModel.SETTING.SHOW_MULTIPLAYER_NAMES)
	self:addDirectSetting(SettingsModel.SETTING.SHOW_HELP_TRIGGER)
	self:addDirectSetting(SettingsModel.SETTING.SHOW_HELP_ICONS)
	self:addDirectSetting(SettingsModel.SETTING.CAMERA_BOBBING)
end

-- Local values: initialValue
function SettingsModel:addSetting(gameSettingsKey, readerFunction, writerFunction, restartRequired, textFunction, rawToValueFunc, valueToRawFunc, onChangeFunc)
	local v22_ = readerFunction(gameSettingsKey)
	self.settings[gameSettingsKey] = {
		["key"] = gameSettingsKey,
		["initial"] = v22_,
		["saved"] = v22_,
		["changed"] = v22_,
		["restartRequired"] = restartRequired
	}
	self.settingReaders[gameSettingsKey] = readerFunction
	self.settingWriters[gameSettingsKey] = writerFunction
	self.settingTexts[gameSettingsKey] = textFunction
	self.settingsRawToValues[gameSettingsKey] = rawToValueFunc
	self.settingsValueToRaws[gameSettingsKey] = valueToRawFunc
	self.settingsOnChanges[gameSettingsKey] = onChangeFunc
	local v23_ = self.sortedSettings
	local v24_ = self.settings[gameSettingsKey]
	table.insert(v23_, v24_)
end

-- Local values: oldValue, rawValue, func, onChangedFunc
function SettingsModel:setValue(settingKey, value)
	if self.settings[settingKey] == nil then
		Logging.warning("SettingsModel key %q is not registered", settingKey)
		return
	elseif value ~= nil then
		local v28_ = self.settings[settingKey].changed
		self.settings[settingKey].changed = value
		local v29_ = self.settingsValueToRaws[settingKey]
		local v30_
		if v29_ == nil then
			v30_ = value
		else
			v30_ = v29_(value)
		end
		local v31_ = self.settingsOnChanges[settingKey]
		if v31_ ~= nil then
			v31_(value, v30_, v28_ ~= value)
		end
	end
end

-- Local values: func
function SettingsModel:setRawValue(settingsKey, value)
	local v35_ = self.settingsRawToValues[settingsKey]
	if v35_ ~= nil then
		value = v35_(value)
	end
	self:setValue(settingsKey, value)
end

function SettingsModel:getValue(settingKey, trueValue)
	if trueValue then
		return self.settingReaders[settingKey](settingKey)
	else
		return self.settings[settingKey] == nil and 0 or self.settings[settingKey].changed
	end
end

-- Local values: value, func
function SettingsModel:getRawValue(settingKey, trueValue)
	local v42_ = self:getValue(settingKey, trueValue)
	local v43_ = self.settingsValueToRaws[settingKey]
	if v43_ ~= nil then
		v42_ = v43_(v42_)
	end
	return v42_
end

-- Local values: func
function SettingsModel:getTexts(settingKey)
	local v46_ = self.settingTexts[settingKey]
	if v46_ == nil then
		return nil
	else
		return v46_()
	end
end

-- Local values: settingsKey, setting
function SettingsModel:refresh()
	for v48_, v49_ in pairs(self.settings) do
		v49_.initial = self.settingReaders[v48_](v48_)
		v49_.changed = v49_.initial
		v49_.saved = v49_.initial
	end
end

-- Local values: settingsKey, setting
function SettingsModel:refreshChangedValue()
	for v51_, v52_ in pairs(self.settings) do
		v52_.changed = self.settingReaders[v51_](v51_)
		v52_.saved = v52_.changed
	end
end

-- Local values: _, setting, hasChanged, writeFunction
function SettingsModel:reset()
	for _, v54_ in pairs(self.sortedSettings) do
		local v55_ = v54_.initial ~= v54_.changed and true or v54_.initial ~= v54_.saved
		v54_.changed = v54_.initial
		v54_.saved = v54_.initial
		if v55_ then
			self.settingWriters[v54_.key](v54_.changed, v54_.key)
		end
	end
	setUserConfirmScreenMode(true)
	self:resetDeviceChanges()
end

-- Local values: setting
function SettingsModel:getSettingExists(settingsKey)
	return self.settings[settingsKey] ~= nil
end

-- Local values: setting
function SettingsModel:getHasValueChanged(settingKey)
	local v60_ = self.settings[settingKey]
	if v60_ ~= nil then
		return v60_.initial ~= v60_.changed and true or v60_.initial ~= v60_.saved
	end
	Logging.devError("Setting \'%s\' is not defined!", (tostring(settingKey)))
	return false
end

-- Local values: _, setting
function SettingsModel:hasChanges()
	for _, v62_ in pairs(self.settings) do
		if v62_.initial ~= v62_.changed or v62_.initial ~= v62_.saved then
			return true
		end
	end
	return self:hasDeviceChanges()
end

-- Local values: _, setting
function SettingsModel:needsRestartToApplyChanges()
	for _, v64_ in pairs(self.settings) do
		if (v64_.initial ~= v64_.changed or v64_.initial ~= v64_.saved) and v64_.restartRequired then
			return true, self:needsProcessRestartToApplyChanges()
		end
	end
	return false, false
end

function SettingsModel:needsProcessRestartToApplyChanges()
	return self:getSettingExists(SettingsModel.SETTING.RESOLUTION) and g_settingsModel:getHasValueChanged(SettingsModel.SETTING.RESOLUTION) and true or (self:getSettingExists(SettingsModel.SETTING.FULLSCREEN_MODE) and g_settingsModel:getHasValueChanged(SettingsModel.SETTING.FULLSCREEN_MODE) and true or false)
end

-- Local values: _, setting, settingsKey, savedValue, changedValue, writeFunction
function SettingsModel:applyChanges(settingClassesToSave)
	for _, v68_ in pairs(self.sortedSettings) do
		local v69_ = v68_.key
		local v70_ = self.settings[v69_].saved
		local v71_ = self.settings[v69_].changed
		if v70_ ~= v71_ then
			self.settingWriters[v69_](v71_, v69_)
			self.settings[v69_].saved = v71_
		end
		self.settings[v69_].initial = v71_
	end
	if settingClassesToSave ~= 0 then
		self:saveChanges(settingClassesToSave)
	end
end

function SettingsModel:saveChanges(settingClassesToSave)
	local v74_ = SettingsModel.SETTING_CLASS.SAVE_GAMEPLAY_SETTINGS
	if bit32.band(settingClassesToSave, v74_) ~= 0 then
		g_gameSettings:save()
	end
	self:saveDeviceChanges()
	local v75_ = SettingsModel.SETTING_CLASS.SAVE_ENGINE_QUALITY_SETTINGS
	if bit32.band(settingClassesToSave, v75_) ~= 0 then
		saveHardwareScalability()
		if GS_IS_CONSOLE_VERSION or GS_IS_MOBILE_VERSION then
			executeSettingsChange()
		end
	end
end

-- Local values: settingsKey, writeFunction
function SettingsModel:applyPerformanceClass(value)
	local v78_ = SettingsModel.SETTING.PERFORMANCE_CLASS
	self.settingWriters[v78_](value, v78_)
	self.settings[v78_].changed = value
	self.settings[v78_].saved = value
	self:refreshChangedValue()
end

-- Local values: settingsKey, changedValue, writeFunction
function SettingsModel:applyCustomSettings()
	for v80_ in pairs(self.settings) do
		if v80_ ~= SettingsModel.SETTING.PERFORMANCE_CLASS then
			local v81_ = self.settings[v80_].changed
			if v81_ ~= self.settings[v80_].saved then
				self.settingWriters[v80_](v81_, v80_)
				self.settings[v80_].saved = v81_
			end
		end
	end
end

-- Local values: i, index, min, max, i, i, i, i, i, i, i, steeringBackSpeedSettings, i, i, _, value, i, index, value, index, value, index, value, index, value, i, value, i, value, i, value, i, i, i, i, numR, i, x, y, aspect, aspectStr, i, numL, i, _, value, i, i, i
function SettingsModel:createControlDisplayValues()
	self.volumeTexts = {
		g_i18n:getText("ui_off"),
		"10%",
		"20%",
		"30%",
		"40%",
		"50%",
		"60%",
		"70%",
		"80%",
		"90%",
		"100%"
	}
	self.recordingVolumeTexts = {
		g_i18n:getText("ui_auto"),
		"50%",
		"60%",
		"70%",
		"80%",
		"90%",
		"100%",
		"110%",
		"120%",
		"130%",
		"140%",
		"150%"
	}
	self.voiceModeTexts = { g_i18n:getText("ui_off"), g_i18n:getText("ui_voiceActivity") }
	if Platform.supportsPushToTalk then
		local v83_ = self.voiceModeTexts
		local v84_ = g_i18n
		table.insert(v83_, v84_:getText("ui_pushToTalk"))
	end
	self.voiceInputThresholdTexts = {
		g_i18n:getText("ui_auto"),
		"0%",
		"10%",
		"20%",
		"30%",
		"40%",
		"50%",
		"60%",
		"70%",
		"80%",
		"90%",
		"100%"
	}
	for v85_ = self.minBrightness, self.maxBrightness + 0.0001, self.brightnessStep do
		local v86_ = self.brightnessTexts
		local v87_ = string.format
		table.insert(v86_, v87_("%.1f", v85_))
	end
	local v88_ = Platform.minFovY
	local v89_ = math.deg(v88_)
	local v90_ = Platform.maxFovY
	local v91_ = 1
	for v92_ = v89_, math.deg(v90_) do
		self.indexToFovYMapping[v91_] = v92_
		self.fovYToIndexMapping[v92_] = v91_
		local v93_ = self.fovYTexts
		local v94_ = string.format
		local v95_ = g_i18n:getText("setting_fovyDegree")
		table.insert(v93_, v94_(v95_, v92_))
		v91_ = v91_ + 1
	end
	for v96_ = 1, 16 do
		local v97_ = self.uiScaleTexts
		local v98_ = string.format
		local v99_ = 50 + (v96_ - 1) * 5
		table.insert(v97_, v98_("%d%%", v99_))
	end
	for v100_ = 0.5, 2.1, 0.1 do
		local v101_ = self.resolutionScaleTexts
		local v102_ = string.format
		local v103_ = MathUtil.round
		local v104_ = v100_ * 100
		table.insert(v101_, v102_("%d%%", v103_(v104_)))
	end
	for v105_ = 0.5, 2.1, 0.1 do
		local v106_ = self.resolutionScale3dTexts
		local v107_ = string.format
		local v108_ = MathUtil.round
		local v109_ = v105_ * 100
		table.insert(v106_, v107_("%d%%", v108_(v109_)))
	end
	for v110_ = 0.5, 3, self.cameraSensitivityStep do
		local v111_ = self.cameraSensitivityStrings
		local v112_ = string.format
		local v113_ = v110_ * 100
		table.insert(v111_, v112_("%d%%", v113_))
		local v114_ = self.cameraSensitivityValues
		table.insert(v114_, v110_)
	end
	for v115_ = 0.5, 3, self.vehicleArmSensitivityStep do
		local v116_ = self.vehicleArmSensitivityStrings
		local v117_ = string.format
		local v118_ = v115_ * 100
		table.insert(v116_, v117_("%d%%", v118_))
		local v119_ = self.vehicleArmSensitivityValues
		table.insert(v119_, v115_)
	end
	for v120_ = 0, 1, self.realBeaconLightBrightnessStep do
		if v120_ > 0 then
			local v121_ = self.realBeaconLightBrightnessStrings
			local v122_ = string.format
			local v123_ = v120_ * 100 + 0.5
			table.insert(v121_, v122_("%d%%", v123_))
		else
			local v124_ = self.realBeaconLightBrightnessStrings
			local v125_ = g_i18n
			table.insert(v124_, v125_:getText("setting_off"))
		end
		local v126_ = self.realBeaconLightBrightnessValues
		table.insert(v126_, v120_)
	end
	local v127_ = Platform.gameplay.steeringBackSpeedSettings
	for v128_ = 1, #v127_ do
		local v129_ = self.steeringBackSpeedStrings
		local v130_ = string.format
		local v131_ = v127_[v128_] * 10
		table.insert(v129_, v130_("%d%%", v131_))
		local v132_ = self.steeringBackSpeedValues
		local v133_ = v127_[v128_]
		table.insert(v132_, v133_)
	end
	for v134_ = 0.5, 3.1, self.steeringSensitivityStep do
		local v135_ = self.steeringSensitivityStrings
		local v136_ = string.format
		local v137_ = v134_ * 100 + 0.5
		table.insert(v135_, v136_("%d%%", v137_))
		local v138_ = self.steeringSensitivityValues
		table.insert(v138_, v134_)
	end
	self.moneyUnitTexts = { g_i18n:getText("unit_euro"), g_i18n:getText("unit_dollar"), g_i18n:getText("unit_pound") }
	self.distanceUnitTexts = { g_i18n:getText("unit_km"), g_i18n:getText("unit_miles") }
	self.temperatureUnitTexts = { g_i18n:getText("unit_celsius"), g_i18n:getText("unit_fahrenheit") }
	self.areaUnitTexts = { g_i18n:getText("unit_ha"), g_i18n:getText("unit_acre") }
	self.radioModeTexts = { g_i18n:getText("setting_radioAlways"), g_i18n:getText("setting_radioVehicleOnly") }
	self.shadowQualityTexts = {
		g_i18n:getText("setting_off"),
		g_i18n:getText("setting_medium"),
		g_i18n:getText("setting_high"),
		g_i18n:getText("setting_veryHigh")
	}
	self.shadowDistanceQualityTexts = { g_i18n:getText("setting_low"), g_i18n:getText("setting_medium"), g_i18n:getText("setting_high") }
	self.softShadowsTexts = { g_i18n:getText("ui_off"), g_i18n:getText("ui_on") }
	self.fourStateTexts = {
		g_i18n:getText("setting_low"),
		g_i18n:getText("setting_medium"),
		g_i18n:getText("setting_high"),
		g_i18n:getText("setting_veryHigh")
	}
	self.fiveStateTexts = {
		g_i18n:getText("setting_low"),
		g_i18n:getText("setting_medium"),
		g_i18n:getText("setting_high"),
		g_i18n:getText("setting_veryHigh"),
		g_i18n:getText("setting_ultra")
	}
	self.lowHighTexts = { g_i18n:getText("setting_low"), g_i18n:getText("setting_high") }
	self.ssaoQualityTexts = {
		g_i18n:getText("setting_low"),
		g_i18n:getText("setting_medium"),
		g_i18n:getText("setting_high"),
		g_i18n:getText("setting_veryHigh")
	}
	self.drsTargetFPSTexts = {}
	self.drsTargetFPSMapping = {}
	self.drsTargetFPSMappingReverse = {}
	for _, v139_ in ipairs(g_gameSettings.frameLimitValues) do
		local v140_ = self.drsTargetFPSTexts
		local v141_ = tostring(v139_)
		table.insert(v140_, v141_)
		self.drsTargetFPSMapping[v139_] = #self.drsTargetFPSTexts
		self.drsTargetFPSMappingReverse[#self.drsTargetFPSTexts] = v139_
	end
	for v142_ = self.minSharpness, self.maxSharpness + 0.0001, self.sharpnessStep do
		local v143_ = self.sharpnessTexts
		local v144_ = string.format
		table.insert(v143_, v144_("%.1f", v142_))
	end
	self.scalingModeTexts = { g_i18n:getText("setting_off") }
	for _, v145_ in pairs(FidelityFxSRQuality) do
		if v145_ ~= FidelityFxSRQuality.OFF and (v145_ ~= FidelityFxSRQuality.NUM and getSupportsFidelityFxSRQuality(v145_)) then
			local v146_ = self.scalingModeTexts
			local v147_ = g_i18n
			table.insert(v146_, v147_:getText("setting_fsr1"))
			break
		end
	end
	for _, v148_ in pairs(FidelityFxSR30Quality) do
		if v148_ ~= FidelityFxSR30Quality.OFF and (v148_ ~= FidelityFxSR30Quality.NUM and getSupportsFidelityFxSR30Quality(v148_)) then
			if getFidelityFxSuperResolutionVersion() == 4 then
				local v149_ = self.scalingModeTexts
				local v150_ = g_i18n
				table.insert(v149_, v150_:getText("setting_fsr4"))
			else
				local v151_ = self.scalingModeTexts
				local v152_ = g_i18n
				table.insert(v151_, v152_:getText("setting_fsr3"))
			end
			break
		end
	end
	for _, v153_ in pairs(DLSSQuality) do
		if v153_ ~= DLSSQuality.OFF and (v153_ ~= DLSSQuality.NUM and getSupportsDLSSQuality(v153_)) then
			local v154_ = self.scalingModeTexts
			local v155_ = g_i18n
			table.insert(v154_, v155_:getText("setting_DLSS"))
			break
		end
	end
	for _, v156_ in pairs(XeSSQuality) do
		if v156_ ~= XeSSQuality.OFF and (v156_ ~= XeSSQuality.NUM and getSupportsXeSSQuality(v156_)) then
			local v157_ = self.scalingModeTexts
			local v158_ = g_i18n
			table.insert(v157_, v158_:getText("setting_xeSS"))
			break
		end
	end
	self.postProcessAntiAliasingToolTip = g_i18n:getText("toolTip_ppaa")
	if getSupportsPostProcessAntiAliasing(PostProcessAntiAliasing.TAA) then
		self.postProcessAntiAliasingToolTip = self.postProcessAntiAliasingToolTip .. " " .. g_i18n:getText("toolTip_ppaa_taa")
	end
	if getSupportsPostProcessAntiAliasing(PostProcessAntiAliasing.DLAA) then
		self.postProcessAntiAliasingToolTip = self.postProcessAntiAliasingToolTip .. " " .. g_i18n:getText("toolTip_ppaa_dlaa")
	end
	self.hdrPeakBrightnessValues = {}
	self.hdrPeakBrightnessTexts = {}
	self.hdrPeakBrightnessStep = 10
	for v159_ = 0, 95 do
		local v160_ = 50 + v159_ * self.hdrPeakBrightnessStep
		local v161_ = self.hdrPeakBrightnessTexts
		local v162_ = string.format
		table.insert(v161_, v162_("%d", v160_))
		local v163_ = self.hdrPeakBrightnessValues
		table.insert(v163_, v160_)
	end
	self.hdrContrastValues = {}
	self.hdrContrastTexts = {}
	for v164_ = 0, 120 do
		local v165_ = 0.8 + v164_ * self.hdrContrastStep
		local v166_ = self.hdrContrastTexts
		local v167_ = string.format
		table.insert(v166_, v167_("%.2f", v165_))
		local v168_ = self.hdrContrastValues
		table.insert(v168_, v165_)
	end
	self.overlayBrightnessValues = {}
	self.overlayBrightnessTexts = {}
	self.overlayBrightnessStep = 10
	for v169_ = 0, 95 do
		local v170_ = 50 + v169_ * self.overlayBrightnessStep
		local v171_ = self.overlayBrightnessTexts
		local v172_ = string.format
		table.insert(v171_, v172_("%d", v170_))
		local v173_ = self.overlayBrightnessValues
		table.insert(v173_, v170_)
	end
	self.shadowMapMaxLightsTexts = {}
	for v174_ = 1, 10 do
		local v175_ = self.shadowMapMaxLightsTexts
		local v176_ = string.format
		table.insert(v175_, v176_("%d", v174_))
	end
	self.percentValues = {}
	self.perentageTexts = {}
	self.percentStep = 0.05
	for v177_ = 0, 30 do
		local v178_ = self.perentageTexts
		local v179_ = string.format
		local v180_ = (0.5 + v177_ * self.percentStep) * 100
		table.insert(v178_, v179_("%.f%%", v180_))
		local v181_ = self.percentValues
		local v182_ = 0.5 + v177_ * self.percentStep
		table.insert(v181_, v182_)
	end
	self.tireTracksValues = {}
	self.tireTracksTexts = {}
	self.tireTracksStep = 0.5
	for v183_ = 0, 4, self.tireTracksStep do
		local v184_ = self.tireTracksTexts
		local v185_ = string.format
		local v186_ = v183_ * 100
		table.insert(v184_, v185_("%d%%", v186_))
		local v187_ = self.tireTracksValues
		table.insert(v187_, v183_)
	end
	self.maxMirrorsTexts = {}
	for v188_ = 0, 7 do
		local v189_ = self.maxMirrorsTexts
		local v190_ = string.format
		table.insert(v189_, v190_("%d", v188_))
	end
	self.resolutionTexts = {}
	for v191_ = 0, getNumOfScreenModes() - 1 do
		local v192_, v193_ = getScreenModeInfo(v191_)
		local v194_ = v192_ / v193_
		local v195_ = v194_ == 1.25 and "(5:4)" or (v194_ > 1.3 and v194_ < 1.4 and "(4:3)" or (v194_ > 1.7 and v194_ < 1.8 and "(16:9)" or (v194_ > 2.3 and v194_ < 2.4 and "(21:9)" or string.format("(%1.0f:10)", v194_ * 10))))
		local v196_ = self.resolutionTexts
		local v197_ = string.format
		table.insert(v196_, v197_("%dx%d %s", v192_, v193_, v195_))
	end
	self.fullscreenModeTexts = {}
	for v198_ = 0, FullscreenMode.NUM - 1 do
		if v198_ == FullscreenMode.WINDOWED then
			local v199_ = self.fullscreenModeTexts
			local v200_ = g_i18n
			table.insert(v199_, v200_:getText("ui_windowed"))
		elseif v198_ == FullscreenMode.WINDOWED_FULLSCREEN then
			local v201_ = self.fullscreenModeTexts
			local v202_ = g_i18n
			table.insert(v201_, v202_:getText("ui_windowed_fullscreen"))
		else
			local v203_ = self.fullscreenModeTexts
			local v204_ = g_i18n
			table.insert(v203_, v204_:getText("ui_exclusive_fullscreen"))
		end
	end
	self.mpLanguageTexts = {}
	for v205_ = 0, getNumOfLanguages() - 1 do
		local v206_ = self.mpLanguageTexts
		local v207_ = getLanguageName
		table.insert(v206_, v207_(v205_))
	end
	self.frameLimitMapping = {}
	self.frameLimitMappingReverse = {}
	self.frameLimitTexts = {}
	for _, v208_ in ipairs(g_gameSettings.frameLimitValues) do
		local v209_ = self.frameLimitTexts
		local v210_ = tostring(v208_)
		table.insert(v209_, v210_)
		self.frameLimitMapping[v208_] = #self.frameLimitTexts
		self.frameLimitMappingReverse[#self.frameLimitTexts] = v208_
	end
	self.inputHelpModeTexts = { g_i18n:getText("ui_auto"), g_i18n:getText("ui_keyboard"), g_i18n:getText("ui_gamepad") }
	self.directionChangeModeTexts = {
		[VehicleMotor.DIRECTION_CHANGE_MODE_AUTOMATIC] = g_i18n:getText("ui_directionChangeModeAutomatic"),
		[VehicleMotor.DIRECTION_CHANGE_MODE_MANUAL] = g_i18n:getText("ui_directionChangeModeManual")
	}
	self.gearShiftModeTexts = {
		[VehicleMotor.SHIFT_MODE_AUTOMATIC] = g_i18n:getText("ui_gearShiftModeAutomatic"),
		[VehicleMotor.SHIFT_MODE_MANUAL] = g_i18n:getText("ui_gearShiftModeManual")
	}
	if not Platform.isConsole then
		self.gearShiftModeTexts[VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH] = g_i18n:getText("ui_gearShiftModeManualClutch")
	end
	self.hudSpeedGaugeTexts = {
		[SpeedMeterDisplay.GAUGE_MODE_RPM] = g_i18n:getText("ui_hudSpeedGaugeRPM"),
		[SpeedMeterDisplay.GAUGE_MODE_SPEED] = g_i18n:getText("ui_hudSpeedGaugeSpeed")
	}
	self.deadzoneValues = {}
	self.deadzoneTexts = {}
	self.deadzoneStep = 0.01
	for v211_ = 0, 0.301, self.deadzoneStep do
		local v212_ = self.deadzoneTexts
		local v213_ = string.format
		local v214_ = v211_ * 100 + 0.001
		local v215_ = math.floor(v214_)
		table.insert(v212_, v213_("%d%%", v215_))
		local v216_ = self.deadzoneValues
		table.insert(v216_, v211_)
	end
	self.sensitivityValues = {}
	self.sensitivityTexts = {}
	self.sensitivityStep = 0.25
	for v217_ = 0.5, 2, self.sensitivityStep do
		local v218_ = self.sensitivityTexts
		local v219_ = string.format
		local v220_ = v217_ * 100
		table.insert(v218_, v219_("%d%%", v220_))
		local v221_ = self.sensitivityValues
		table.insert(v221_, v217_)
	end
	self.headTrackingSensitivityValues = {}
	self.headTrackingSensitivityTexts = {}
	self.headTrackingSensitivityStep = 0.05
	for v222_ = 0, 1.001, self.headTrackingSensitivityStep do
		local v223_ = self.headTrackingSensitivityTexts
		local v224_ = string.format
		local v225_ = v222_ * 100 + 0.001
		table.insert(v223_, v224_("%d%%", v225_))
		local v226_ = self.headTrackingSensitivityValues
		table.insert(v226_, v222_)
	end
end

function SettingsModel:getDeadzoneTexts()
	return self.deadzoneTexts
end

function SettingsModel:getSensitivityTexts()
	return self.sensitivityTexts
end

function SettingsModel:getHeadTrackingSensitivityTexts()
	return self.headTrackingSensitivityTexts
end

-- Local values: settings
function SettingsModel:getDeviceHasAxisDeadzone(axisIndex)
	local v232_ = self.deviceSettings[self.currentDevice]
	local v233_
	if v232_ == nil then
		v233_ = false
	else
		v233_ = v232_.deadzones[axisIndex] ~= nil
	end
	return v233_
end

-- Local values: settings
function SettingsModel:getDeviceHasAxisSensitivity(axisIndex)
	local v236_ = self.deviceSettings[self.currentDevice]
	local v237_
	if v236_ == nil then
		v237_ = false
	else
		v237_ = v236_.sensitivities[axisIndex] ~= nil
	end
	return v237_
end

function SettingsModel:getNumDevices()
	return #self.deviceSettings
end

function SettingsModel:nextDevice()
	self.currentDevice = self.currentDevice + 1
	if self.currentDevice > #self.deviceSettings then
		self.currentDevice = 1
	end
end

-- Local values: setting
function SettingsModel:getCurrentDeviceName()
	local v241_ = self.deviceSettings[self.currentDevice]
	return v241_ == nil and "" or v241_.device.deviceName
end

-- Local values: _, device, deadzones, sensitivities, mouseSensitivity, headTrackingSensitivity, axisIndex, deadzone, deadzoneValue, sensitivity, sensitivityValue, scale, _, value, value
function SettingsModel:initDeviceSettings()
	self.deviceSettings = {}
	self.currentDevice = 0
	for _, v243_ in pairs(g_inputBinding.devicesByInternalId) do
		local v244_ = {}
		local v245_ = {}
		local v246_ = {}
		local v247_ = {}
		local v248_ = self.deviceSettings
		table.insert(v248_, {
			["device"] = v243_,
			["deadzones"] = v244_,
			["sensitivities"] = v245_,
			["mouseSensitivity"] = v246_,
			["headTrackingSensitivity"] = v247_
		})
		for v249_ = 0, Input.MAX_NUM_AXES - 1 do
			if getHasGamepadAxis(v249_, v243_.internalId) then
				local v250_ = v243_:getDeadzone(v249_)
				local v251_ = Utils.getValueIndex(v250_, self.deadzoneValues)
				v244_[v249_] = {
					["current"] = v251_,
					["saved"] = v251_
				}
				local v252_ = v243_:getSensitivity(v249_)
				local v253_ = Utils.getValueIndex(v252_, self.sensitivityValues)
				v245_[v249_] = {
					["current"] = v253_,
					["saved"] = v253_
				}
			end
		end
		if v243_.category == InputDevice.CATEGORY.KEYBOARD_MOUSE then
			local v254_, _ = g_inputBinding:getMouseMotionScale()
			local v255_ = Utils.getValueIndex(v254_, self.sensitivityValues)
			v246_.current = v255_
			v246_.saved = v255_
		end
		local v256_ = Utils.getValueIndex(getCameraTrackingSensitivity(), self.headTrackingSensitivityValues)
		v247_.current = v256_
		v247_.saved = v256_
		self.currentDevice = 1
	end
end

-- Local values: _, settings, axisIndex, _, deadzone, sensitivity, mouseSensitivity, headTrackingSensitivity
function SettingsModel:hasDeviceChanges()
	for _, v258_ in ipairs(self.deviceSettings) do
		for v259_, _ in pairs(v258_.deadzones) do
			local v260_ = v258_.deadzones[v259_]
			if v260_.current ~= v260_.saved then
				return true
			end
			local v261_ = v258_.sensitivities[v259_]
			if v261_.current ~= v261_.saved then
				return true
			end
		end
		if v258_.device.category == InputDevice.CATEGORY.KEYBOARD_MOUSE then
			local v262_ = v258_.mouseSensitivity
			if v262_.current ~= v262_.saved then
				return true
			end
		end
		local v263_ = v258_.headTrackingSensitivity
		if v263_.current ~= v263_.saved then
			return true
		end
	end
	return false
end

-- Local values: changedSettings, _, settings, device, axisIndex, _, deadzones, deadzone, sensitivities, sensitivity, mouseSensitivity, headTrackingSensitivity
function SettingsModel:saveDeviceChanges()
	local v265_ = false
	for _, v266_ in ipairs(self.deviceSettings) do
		local v267_ = v266_.device
		for v268_, _ in pairs(v266_.deadzones) do
			local v269_ = v266_.deadzones[v268_]
			local v270_ = self.deadzoneValues[v269_.current]
			v269_.saved = v269_.current
			v267_:setDeadzone(v268_, v270_)
			local v271_ = v266_.sensitivities[v268_]
			local v272_ = self.sensitivityValues[v271_.current]
			v271_.saved = v271_.current
			v267_:setSensitivity(v268_, v272_)
			v265_ = true
		end
		if v266_.device.category == InputDevice.CATEGORY.KEYBOARD_MOUSE then
			local v273_ = v266_.mouseSensitivity
			if v273_.current ~= v273_.saved then
				g_inputBinding:setMouseMotionScale(self.sensitivityValues[v273_.current])
				v273_.saved = v273_.current
				v265_ = true
			end
			local v274_ = v266_.headTrackingSensitivity
			if v274_.current ~= v274_.saved then
				setCameraTrackingSensitivity(self.headTrackingSensitivityValues[v274_.current])
				v274_.saved = v274_.current
				v265_ = true
			end
		end
	end
	if v265_ then
		g_inputBinding:applyGamepadDeadzones()
		g_inputBinding:saveToXMLFile()
	end
end

-- Local values: _, settings, axisIndex, _, deadzone, sensitivity
function SettingsModel:resetDeviceChanges()
	for _, v276_ in ipairs(self.deviceSettings) do
		for v277_, _ in pairs(v276_.deadzones) do
			local v278_ = v276_.deadzones[v277_]
			v278_.current = v278_.saved
			local v279_ = v276_.sensitivities[v277_]
			v279_.current = v279_.saved
		end
		v276_.mouseSensitivity.current = v276_.mouseSensitivity.saved
		v276_.headTrackingSensitivity.current = v276_.headTrackingSensitivity.saved
	end
end

-- Local values: settings
function SettingsModel:setDeviceDeadzoneValue(axisIndex, value)
	local v283_ = self.deviceSettings[self.currentDevice]
	if v283_ ~= nil then
		v283_.deadzones[axisIndex].current = value
	end
end

-- Local values: settings
function SettingsModel:getCurrentDeviceDeadzoneValue(axisIndex)
	local v286_ = self.deviceSettings[self.currentDevice]
	if v286_ == nil then
		return nil
	else
		return self.deadzoneValues[v286_.deadzones[axisIndex].current]
	end
end

-- Local values: settings
function SettingsModel:setDeviceSensitivityValue(axisIndex, value)
	local v290_ = self.deviceSettings[self.currentDevice]
	if v290_ ~= nil then
		v290_.sensitivities[axisIndex].current = value
	end
end

-- Local values: settings
function SettingsModel:getCurrentDeviceSensitivityValue(axisIndex)
	local v293_ = self.deviceSettings[self.currentDevice]
	if v293_ == nil then
		return nil
	else
		return self.sensitivityValues[v293_.sensitivities[axisIndex].current]
	end
end

-- Local values: settings
function SettingsModel:setMouseSensitivity(value)
	local v296_ = self.deviceSettings[self.currentDevice]
	if v296_ ~= nil then
		v296_.mouseSensitivity.current = value
	end
end

-- Local values: settings
function SettingsModel:setHeadTrackingSensitivity(value)
	local v299_ = self.deviceSettings[self.currentDevice]
	if v299_ ~= nil then
		v299_.headTrackingSensitivity.current = value
	end
end

-- Local values: settings
function SettingsModel:getDeviceAxisDeadzoneValue(axisIndex)
	return self.deviceSettings[self.currentDevice].deadzones[axisIndex].current
end

-- Local values: settings
function SettingsModel:getDeviceAxisSensitivityValue(axisIndex)
	return self.deviceSettings[self.currentDevice].sensitivities[axisIndex].current
end

-- Local values: settings
function SettingsModel:getMouseSensitivityValue(axisIndex)
	return self.deviceSettings[self.currentDevice].mouseSensitivity.current
end

-- Local values: settings
function SettingsModel:getHeadTrackingSensitivityValue(axisIndex)
	return self.deviceSettings[self.currentDevice].headTrackingSensitivity.current
end

-- Local values: settings
function SettingsModel:getIsDeviceMouse()
	local v307_ = self.deviceSettings[self.currentDevice]
	local v308_
	if v307_ == nil then
		v308_ = false
	else
		v308_ = v307_.device.category == InputDevice.CATEGORY.KEYBOARD_MOUSE
	end
	return v308_
end

function SettingsModel:getResolutionTexts()
	return self.resolutionTexts
end

function SettingsModel:getFullscreenModeTexts()
	return self.fullscreenModeTexts
end

function SettingsModel:getMPLanguageTexts()
	return self.mpLanguageTexts
end

function SettingsModel:getFrameLimitTexts()
	return self.frameLimitTexts
end

function SettingsModel:getInputHelpModeTexts()
	return self.inputHelpModeTexts
end

function SettingsModel:getDirectionChangeModeTexts()
	return self.directionChangeModeTexts
end

function SettingsModel:getGearShiftModeTexts()
	return self.gearShiftModeTexts
end

function SettingsModel:getHudSpeedGaugeTexts()
	return self.hudSpeedGaugeTexts
end

function SettingsModel:getLanguageTexts()
	return g_availableLanguageNamesTable
end

function SettingsModel:getIsLanguageDisabled()
	return #g_availableLanguagesTable <= 1 and true or GS_IS_STEAM_VERSION
end

-- Local values: class, isCustom, _, isAuto, texts, index
function SettingsModel:getPerformanceClassTexts()
	local v317_, v318_ = getPerformanceClass()
	local _, v319_ = getAutoPerformanceClass()
	local v320_ = {}
	local v321_ = g_i18n
	table.insert(v320_, v321_:getText("setting_veryLow"))
	local v322_ = g_i18n
	table.insert(v320_, v322_:getText("setting_low"))
	local v323_ = g_i18n
	table.insert(v320_, v323_:getText("setting_medium"))
	local v324_ = g_i18n
	table.insert(v320_, v324_:getText("setting_high"))
	local v325_ = g_i18n
	table.insert(v320_, v325_:getText("setting_veryHigh"))
	local v326_ = g_i18n
	table.insert(v320_, v326_:getText("setting_ultra"))
	if not GS_IS_MOBILE_VERSION then
		local v327_ = Utils.getPerformanceClassIndex(v317_)
		if v318_ then
			v320_[v327_] = g_i18n:getText("setting_custom")
		elseif v319_ then
			v320_[v327_] = g_i18n:getText("setting_auto")
		end
	end
	return v320_, v317_, v318_
end

function SettingsModel:getHDRPeakBrightnessTexts()
	return self.hdrPeakBrightnessTexts
end

function SettingsModel:getHDRContrastTexts()
	return self.hdrContrastTexts
end

function SettingsModel:getOverlayBrightnessTexts()
	return self.overlayBrightnessTexts
end

function SettingsModel:getPostProcessAAToolTip()
	return self.postProcessAntiAliasingToolTip
end

function SettingsModel:getDRSTargetFPSTexts()
	return self.drsTargetFPSTexts
end

function SettingsModel:getSharpnessTexts()
	return self.sharpnessTexts
end

function SettingsModel:getScalingModeTexts()
	return self.scalingModeTexts
end

function SettingsModel:getShadingRateQualityTexts()
	return self.fourStateTexts
end

function SettingsModel:getShadowQualityTexts()
	return self.shadowQualityTexts
end

function SettingsModel:getShadowDistanceQualityTexts()
	return self.shadowDistanceQualityTexts
end

function SettingsModel:getSoftShadowsTexts()
	return self.softShadowsTexts
end

function SettingsModel:getSSAOQualityTexts()
	return self.ssaoQualityTexts
end

function SettingsModel:getShaderQualityTexts()
	return self.fourStateTexts
end

function SettingsModel:getTextureResolutionTexts()
	return self.lowHighTexts
end

function SettingsModel:getShadowMapFilteringTexts()
	return self.lowHighTexts
end

function SettingsModel:getTerraingQualityTexts()
	return self.fourStateTexts
end

function SettingsModel:getLightsProfileTexts()
	return self.fiveStateTexts
end

function SettingsModel:getShadowMapLightsTexts()
	return self.shadowMapMaxLightsTexts
end

function SettingsModel:getObjectDrawDistanceTexts()
	return self.perentageTexts
end

function SettingsModel:getFoliageDrawDistanceTexts()
	return self.perentageTexts
end

function SettingsModel:getLODDistanceTexts()
	return self.perentageTexts
end

function SettingsModel:getTerrainLODDistanceTexts()
	return self.perentageTexts
end

function SettingsModel:getFoliageLODDistanceTexts()
	return self.perentageTexts
end

function SettingsModel:getVolumeMeshTessalationTexts()
	return self.perentageTexts
end

function SettingsModel:getMaxTireTracksTexts()
	return self.tireTracksTexts
end

function SettingsModel:getMaxMirrorsTexts()
	return self.maxMirrorsTexts
end

function SettingsModel:getBrightnessTexts()
	return self.brightnessTexts
end

function SettingsModel:getFovYTexts()
	return self.fovYTexts
end

function SettingsModel:getUiScaleTexts()
	return self.uiScaleTexts
end

function SettingsModel:getAudioVolumeTexts()
	return self.volumeTexts
end

function SettingsModel:getVoiceInputSensitivityTexts()
	return self.voiceInputThresholdTexts
end

function SettingsModel:getForceFeedbackTexts()
	return self.volumeTexts
end

function SettingsModel:getRecordingVolumeTexts()
	return self.recordingVolumeTexts
end

function SettingsModel:getVoiceModeTexts()
	return self.voiceModeTexts
end

function SettingsModel:getCameraSensitivityTexts()
	return self.cameraSensitivityStrings
end

function SettingsModel:getVehicleArmSensitivityTexts()
	return self.vehicleArmSensitivityStrings
end

function SettingsModel:getRealBeaconLightBrightnessTexts()
	return self.realBeaconLightBrightnessStrings
end

function SettingsModel:getSteeringBackSpeedTexts()
	return self.steeringBackSpeedStrings
end

function SettingsModel:getSteeringSensitivityTexts()
	return self.steeringSensitivityStrings
end

function SettingsModel:getMoneyUnitTexts()
	return self.moneyUnitTexts
end

function SettingsModel:getDistanceUnitTexts()
	return self.distanceUnitTexts
end

function SettingsModel:getTemperatureUnitTexts()
	return self.temperatureUnitTexts
end

function SettingsModel:getAreaUnitTexts()
	return self.areaUnitTexts
end

function SettingsModel:getRadioModeTexts()
	return self.radioModeTexts
end

function SettingsModel:getResolutionScaleTexts()
	return self.resolutionScaleTexts
end

function SettingsModel:getResolutionScale3dTexts()
	return self.resolutionScale3dTexts
end

function SettingsModel:makeDefaultReaderFunction()
	return function(p374_)
		return g_gameSettings:getValue(p374_)
	end
end

function SettingsModel:makeDefaultWriterFunction()
	return function(p375_, p376_)
		g_gameSettings:setValue(p376_, p375_)
	end
end

function SettingsModel:addDirectSetting(gameSettingsKey, restartRequired)
	self:addSetting(gameSettingsKey, self.defaultReaderFunction, self.defaultWriterFunction, restartRequired)
end

-- Local values: readValue, writeValue
function SettingsModel:addPerformanceClassSetting()
	self:addSetting(SettingsModel.SETTING.PERFORMANCE_CLASS, function()
		local v381_, _ = getPerformanceClass()
		return Utils.getPerformanceClassIndex(v381_)
	end, function(p382_)
		local v383_ = Utils.getPerformanceClassFromIndex(p382_)
		setPerformanceClass(v383_)
		if g_terrainNode ~= nil then
			local v384_ = getFoliageViewDistanceCoeff()
			local v385_, v386_ = getTerrainLodBlendDynamicDistances(g_terrainNode)
			setTerrainLodBlendDynamicDistances(g_terrainNode, v385_ * v384_, v386_ * v384_)
		end
		local v387_ = GameSettings.PERFORMANCE_CLASS_PRESETS[Utils.getPerformanceClassId()]
		g_gameSettings:setValue(SettingsModel.SETTING.LIGHTS_PROFILE, v387_[SettingsModel.SETTING.LIGHTS_PROFILE])
		g_gameSettings:setValue(SettingsModel.SETTING.MAX_MIRRORS, v387_[SettingsModel.SETTING.MAX_MIRRORS])
		g_gameSettings:setValue(SettingsModel.SETTING.REAL_BEACON_LIGHTS, v387_[SettingsModel.SETTING.REAL_BEACON_LIGHTS])
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addPerformanceModeSetting()
	self:addSetting(SettingsModel.SETTING.PERFORMANCE_MODE, function()
		return getIsPerformanceModeActive()
	end, function(p389_)
		setIsPerformanceModeActive(p389_)
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addHDRPeakBrightnessSetting()
	self:addSetting(SettingsModel.SETTING.HDR_PEAK_BRIGHTNESS, function()
		-- upvalues: (copy) self
		return Utils.getValueIndex(getBrightnessNits(), self.hdrPeakBrightnessValues)
	end, function(p391_)
		-- upvalues: (copy) self
		local v392_ = self.hdrPeakBrightnessValues[p391_]
		setBrightnessNits(v392_)
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addHDRContrastSetting()
	self:addSetting(SettingsModel.SETTING.HDR_CONTRAST, function()
		-- upvalues: (copy) self
		local v394_ = getHDRGamma()
		return Utils.getValueIndex(v394_, self.hdrContrastValues)
	end, function(p395_)
		-- upvalues: (copy) self
		local v396_ = self.hdrContrastValues[p395_]
		setHDRGamma(v396_)
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addOverlayBrightnessSetting()
	self:addSetting(SettingsModel.SETTING.OVERLAY_BRIGHTNESS, function()
		-- upvalues: (copy) self
		return Utils.getValueIndex(getOverlayBrightnessNits(), self.overlayBrightnessValues)
	end, function(p398_)
		-- upvalues: (copy) self
		local v399_ = self.overlayBrightnessValues[p398_]
		setOverlayBrightnessNits(v399_)
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addHDREnabledSetting()
	self:addSetting(SettingsModel.SETTING.HDR_ENABLED, function()
		return getScreenHdrOutput() or false
	end, function(p401_)
		setScreenHdrOutput(p401_)
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addFidelityFxSR30FrameGenerationSetting()
	self:addSetting(SettingsModel.SETTING.FIDELITYFX_SR_30_FRAME_GENERATION, function()
		return getFidelityFxSR30FrameInterpolation()
	end, function(p403_)
		setFidelityFxSR30FrameInterpolation(p403_)
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addXeSSFrameGenerationSetting()
	self:addSetting(SettingsModel.SETTING.XESS_FRAME_GENERATION, function()
		return getXeSSFrameInterpolation()
	end, function(p405_)
		setXeSSFrameInterpolation(p405_)
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addDLSSFrameGenerationSetting()
	self:addSetting(SettingsModel.SETTING.DLSS_FRAME_GENERATION, function()
		return getDLSSFrameInterpolation()
	end, function(p407_)
		setDLSSFrameInterpolation(p407_)
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addDRSTargetFPSSetting()
	self:addSetting(SettingsModel.SETTING.DRS_TARGET_FPS, function()
		-- upvalues: (copy) self
		return self.drsTargetFPSMapping[getDRSTargetFPS()]
	end, function(p409_)
		-- upvalues: (copy) self
		local v410_ = self.drsTargetFPSMappingReverse[p409_]
		if getDRSTargetFPS() ~= v410_ then
			setDRSTargetFPS(v410_)
		end
	end)
end

-- Local values: readSharpness, writeSharpness
function SettingsModel:addSharpnessSetting()
	self:addSetting(SettingsModel.SETTING.SHARPNESS, function()
		-- upvalues: (copy) self
		local v412_ = getSharpness()
		local v413_ = self.minSharpness
		local v414_ = self.maxSharpness
		local v415_ = math.clamp(v412_, v413_, v414_)
		return MathUtil.round((v415_ - self.minSharpness) / self.sharpnessStep + 1)
	end, function(p416_)
		-- upvalues: (copy) self
		local v417_ = self.minSharpness + self.sharpnessStep * (p416_ - 1)
		setSharpness(v417_)
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addShadingRateQualitySetting()
	self:addSetting(SettingsModel.SETTING.SHADING_RATE_QUALITY, function()
		return getShadingRateQuality() + 1
	end, function(p419_)
		local v420_ = setShadingRateQuality
		local v421_ = p419_ - 1
		v420_((math.max(v421_, 0)))
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addSSAOQualitySetting()
	self:addSetting(SettingsModel.SETTING.SSAO_QUALITY, function()
		return getSSAOQuality()
	end, function(p423_)
		setSSAOQuality(p423_)
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addCloudShadowsQualitySetting()
	self:addSetting(SettingsModel.SETTING.CLOUD_SHADOWS_QUALITY, function()
		return getCloudShadowsQuality() == 1
	end, function(p425_)
		setCloudShadowsQuality(p425_ and 1 or 0)
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addTextureResolutionSetting()
	self:addSetting(SettingsModel.SETTING.TEXTURE_RESOLUTION, function()
		return SettingsModel.getTextureResolutionIndex(getTextureResolution())
	end, function(p427_)
		setTextureResolution(SettingsModel.getTextureResolutionByIndex(p427_))
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addShadowQualitySetting()
	self:addSetting(SettingsModel.SETTING.SHADOW_QUALITY, function()
		return SettingsModel.getShadowQualityIndex(getShadowQuality(), getHasShadowFocusBox())
	end, function(p429_)
		setShadowQuality(SettingsModel.getShadowQualityByIndex(p429_), SettingsModel.getHasShadowFocusBoxByIndex(p429_))
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addShadowDistanceQualitySetting()
	self:addSetting(SettingsModel.SETTING.SHADOW_DISTANCE_QUALITY, function()
		return getShadowDistanceQuality() + 1
	end, function(p431_)
		local v432_ = setShadowDistanceQuality
		local v433_ = p431_ - 1
		v432_((math.max(v433_, 0)))
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addSoftShadowsSetting()
	self:addSetting(SettingsModel.SETTING.SOFT_SHADOWS, function()
		return getShadowFilterQuality() + 1
	end, function(p435_)
		local v436_ = setShadowFilterQuality
		local v437_ = p435_ - 1
		v436_((math.max(v437_, 0)))
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addShaderQualitySetting()
	self:addSetting(SettingsModel.SETTING.SHADER_QUALITY, function()
		return SettingsModel.getShaderQualityIndex(getShaderQuality())
	end, function(p439_)
		setShaderQuality(SettingsModel.getShaderQualityByIndex(p439_))
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addShadowMapFilteringSetting()
	self:addSetting(SettingsModel.SETTING.SHADOW_MAP_FILTERING, function()
		return SettingsModel.getShadowMapFilterIndex(getShadowMapFilterSize())
	end, function(p441_)
		setShadowMapFilterSize(SettingsModel.getShadowMapFilterByIndex(p441_))
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addShadowMaxLightsSetting()
	self:addSetting(SettingsModel.SETTING.MAX_LIGHTS, function()
		return getMaxNumShadowLights()
	end, function(p443_)
		setMaxNumShadowLights(p443_)
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addTerrainQualitySetting()
	self:addSetting(SettingsModel.SETTING.TERRAIN_QUALITY, function()
		return SettingsModel.getTerrainQualityIndex(getTerrainQuality())
	end, function(p445_)
		setTerrainQuality(SettingsModel.getTerrainQualityByIndex(p445_))
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addObjectDrawDistanceSetting()
	self:addSetting(SettingsModel.SETTING.OBJECT_DRAW_DISTANCE, function()
		-- upvalues: (copy) self
		return Utils.getValueIndex(getViewDistanceCoeff(), self.percentValues)
	end, function(p447_)
		-- upvalues: (copy) self
		setViewDistanceCoeff(self.percentValues[p447_])
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addFoliageDrawDistanceSetting()
	self:addSetting(SettingsModel.SETTING.FOLIAGE_DRAW_DISTANCE, function()
		-- upvalues: (copy) self
		return Utils.getValueIndex(getFoliageViewDistanceCoeff(), self.percentValues)
	end, function(p449_)
		-- upvalues: (copy) self
		setFoliageViewDistanceCoeff(self.percentValues[p449_])
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addFoliageShadowSetting()
	self:addSetting(SettingsModel.SETTING.FOLIAGE_SHADOW, function()
		return getAllowFoliageShadows()
	end, function(p451_)
		setAllowFoliageShadows(p451_)
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addLODDistanceSetting()
	self:addSetting(SettingsModel.SETTING.LOD_DISTANCE, function()
		-- upvalues: (copy) self
		return Utils.getValueIndex(getLODDistanceCoeff(), self.percentValues)
	end, function(p453_)
		-- upvalues: (copy) self
		setLODDistanceCoeff(self.percentValues[p453_])
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addTerrainLODDistanceSetting()
	self:addSetting(SettingsModel.SETTING.TERRAIN_LOD_DISTANCE, function()
		-- upvalues: (copy) self
		return Utils.getValueIndex(getTerrainLODDistanceCoeff(), self.percentValues)
	end, function(p455_)
		-- upvalues: (copy) self
		setTerrainLODDistanceCoeff(self.percentValues[p455_])
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addFoliageLODDistanceSetting()
	self:addSetting(SettingsModel.SETTING.FOLIAGE_LOD_DISTANCE, function()
		-- upvalues: (copy) self
		return Utils.getValueIndex(getFoliageLODDistanceCoeff(), self.percentValues)
	end, function(p457_)
		-- upvalues: (copy) self
		setFoliageLODDistanceCoeff(self.percentValues[p457_])
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addVolumeMeshTessellationSetting()
	self:addSetting(SettingsModel.SETTING.VOLUME_MESH_TESSELLATION, function()
		-- upvalues: (copy) self
		return Utils.getValueIndex(SettingsModel.getVolumeMeshTessellationCoeff(), self.percentValues)
	end, function(p459_)
		-- upvalues: (copy) self
		SettingsModel.setVolumeMeshTessellationCoeff(self.percentValues[p459_])
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addMaxTireTracksSetting()
	self:addSetting(SettingsModel.SETTING.MAX_TIRE_TRACKS, function()
		-- upvalues: (copy) self
		return Utils.getValueIndex(getTyreTracksSegmentsCoeff(), self.tireTracksValues)
	end, function(p461_)
		-- upvalues: (copy) self
		setTyreTracksSegmentsCoeff(self.tireTracksValues[p461_])
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addLightsProfileSetting()
	self:addSetting(SettingsModel.SETTING.LIGHTS_PROFILE, function()
		return g_gameSettings:getValue(SettingsModel.SETTING.LIGHTS_PROFILE)
	end, function(p463_)
		g_gameSettings:setValue(SettingsModel.SETTING.LIGHTS_PROFILE, p463_)
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addRealBeaconLightsSetting()
	self:addSetting(SettingsModel.SETTING.REAL_BEACON_LIGHTS, function()
		return g_gameSettings:getValue(SettingsModel.SETTING.REAL_BEACON_LIGHTS)
	end, function(p465_)
		g_gameSettings:setValue(SettingsModel.SETTING.REAL_BEACON_LIGHTS, p465_)
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addMaxMirrorsSetting()
	self:addSetting(SettingsModel.SETTING.MAX_MIRRORS, function()
		return SettingsModel.getNumOfReflectionMapsIndex(g_gameSettings:getValue(SettingsModel.SETTING.MAX_MIRRORS))
	end, function(p467_)
		g_gameSettings:setValue(SettingsModel.SETTING.MAX_MIRRORS, SettingsModel.getNumOfReflectionMapsByIndex(p467_))
	end)
end

-- Local values: readLanguage, writeLanguage
function SettingsModel:addLanguageSetting()
	self:addSetting(SettingsModel.SETTING.LANGUAGE, function()
		return g_settingsLanguageGUI + 1
	end, function(p469_)
		g_settingsLanguageGUI = p469_ - 1
		setLanguage(g_availableLanguagesTable[p469_])
	end, true)
end

-- Local values: readMPLanguage, writeMPLanguage
function SettingsModel:addMPLanguageSetting()
	self:addSetting(SettingsModel.SETTING.MP_LANGUAGE, function()
		return g_gameSettings:getValue(SettingsModel.SETTING.MP_LANGUAGE) + 1
	end, function(p471_)
		g_gameSettings:setValue(SettingsModel.SETTING.MP_LANGUAGE, p471_ - 1)
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addInputHelpModeSetting()
	self:addSetting(SettingsModel.SETTING.INPUT_HELP_MODE, function()
		return g_gameSettings:getValue(SettingsModel.SETTING.INPUT_HELP_MODE)
	end, function(p473_)
		g_gameSettings:setValue(SettingsModel.SETTING.INPUT_HELP_MODE, p473_)
	end)
end

-- Local values: readValue, writeValue
function SettingsModel:addFrameLimitSetting()
	self:addSetting(SettingsModel.SETTING.FRAME_LIMIT, function()
		-- upvalues: (copy) self
		return self.frameLimitMapping[g_gameSettings:getValue(SettingsModel.SETTING.FRAME_LIMIT)]
	end, function(p475_)
		-- upvalues: (copy) self
		local v476_ = self.frameLimitMappingReverse[p475_]
		g_gameSettings:setValue(SettingsModel.SETTING.FRAME_LIMIT, v476_)
		if Platform.hasAdjustableFrameLimit and g_currentMission ~= nil then
			setFramerateLimiter(true, v476_)
		end
	end)
end

-- Local values: readBrightness, writeBrightness
function SettingsModel:addBrightnessSetting()
	self:addSetting(SettingsModel.SETTING.BRIGHTNESS, function()
		-- upvalues: (copy) self
		local v478_ = getBrightness()
		local v479_ = self.minBrightness
		local v480_ = self.maxBrightness
		local v481_ = math.clamp(v478_, v479_, v480_)
		return MathUtil.round((v481_ - self.minBrightness) / self.brightnessStep + 1)
	end, function(p482_)
		-- upvalues: (copy) self
		local v483_ = self.minBrightness + self.brightnessStep * (p482_ - 1)
		local v484_ = setBrightness
		local v485_ = self.minBrightness
		local v486_ = self.maxBrightness
		v484_((math.clamp(v483_, v485_, v486_)))
	end)
end

-- Local values: readVSync, writeVSync
function SettingsModel:addVSyncSetting()
	self:addSetting(SettingsModel.SETTING.V_SYNC, function()
		return getVsync()
	end, function(p488_)
		setVsync(p488_)
	end)
end

-- Local values: readFovY, writeFovY
function SettingsModel:addFovYSetting()
	self:addSetting(SettingsModel.SETTING.FOV_Y, function()
		-- upvalues: (copy) self
		local v490_ = g_gameSettings:getValue(SettingsModel.SETTING.FOV_Y)
		local v491_ = math.deg(v490_)
		local v492_ = self.fovYToIndexMapping
		local v493_ = v491_ + 0.5
		local v494_ = math.floor(v493_)
		local v495_ = Platform.minFovY
		local v496_ = math.deg(v495_)
		local v497_ = math.max(v494_, v496_)
		local v498_ = Platform.maxFovY
		local v499_ = math.deg(v498_)
		return v492_[math.min(v497_, v499_)]
	end, function(p500_)
		-- upvalues: (copy) self
		local v501_ = g_gameSettings
		local v502_ = SettingsModel.SETTING.FOV_Y
		local v503_ = self.indexToFovYMapping[p500_]
		v501_:setValue(v502_, (math.rad(v503_)))
	end)
end

-- Local values: readFovY, writeFovY
function SettingsModel:addFovYPlayerFirstPersonSetting()
	self:addSetting(SettingsModel.SETTING.FOV_Y_PLAYER_FIRST_PERSON, function()
		-- upvalues: (copy) self
		local v505_ = g_gameSettings:getValue(SettingsModel.SETTING.FOV_Y_PLAYER_FIRST_PERSON)
		local v506_ = math.deg(v505_)
		local v507_ = self.fovYToIndexMapping
		local v508_ = v506_ + 0.5
		local v509_ = math.floor(v508_)
		local v510_ = Platform.minFovY
		local v511_ = math.deg(v510_)
		local v512_ = math.max(v509_, v511_)
		local v513_ = Platform.maxFovY
		local v514_ = math.deg(v513_)
		return v507_[math.min(v512_, v514_)]
	end, function(p515_)
		-- upvalues: (copy) self
		local v516_ = g_gameSettings
		local v517_ = SettingsModel.SETTING.FOV_Y_PLAYER_FIRST_PERSON
		local v518_ = self.indexToFovYMapping[p515_]
		v516_:setValue(v517_, (math.rad(v518_)))
	end)
end

-- Local values: readFovY, writeFovY
function SettingsModel:addFovYPlayerThirdPersonSetting()
	self:addSetting(SettingsModel.SETTING.FOV_Y_PLAYER_THIRD_PERSON, function()
		-- upvalues: (copy) self
		local v520_ = g_gameSettings:getValue(SettingsModel.SETTING.FOV_Y_PLAYER_THIRD_PERSON)
		local v521_ = math.deg(v520_)
		local v522_ = self.fovYToIndexMapping
		local v523_ = v521_ + 0.5
		local v524_ = math.floor(v523_)
		local v525_ = Platform.minFovY
		local v526_ = math.deg(v525_)
		local v527_ = math.max(v524_, v526_)
		local v528_ = Platform.maxFovY
		local v529_ = math.deg(v528_)
		return v522_[math.min(v527_, v529_)]
	end, function(p530_)
		-- upvalues: (copy) self
		local v531_ = g_gameSettings
		local v532_ = SettingsModel.SETTING.FOV_Y_PLAYER_THIRD_PERSON
		local v533_ = self.indexToFovYMapping[p530_]
		v531_:setValue(v532_, (math.rad(v533_)))
	end)
end

-- Local values: readUIScale, writeUIScale
function SettingsModel:addUIScaleSetting()
	self:addSetting(SettingsModel.SETTING.UI_SCALE, function()
		return Utils.getUIScaleIndex(g_gameSettings:getValue(SettingsModel.SETTING.UI_SCALE))
	end, function(p535_)
		g_gameSettings:setValue(SettingsModel.SETTING.UI_SCALE, Utils.getUIScaleFromIndex(p535_))
	end)
end

-- Local values: readResolutionScale, writeResolutionScale
function SettingsModel:addResolutionScaleSetting()
	self:addSetting(SettingsModel.SETTING.RESOLUTION_SCALE, function()
		return SettingsModel.getScalingStateFromResolutionScaling(getResolutionScaling())
	end, function(p537_)
		setResolutionScaling(SettingsModel.getScalingFromResolutionScalingState(p537_))
	end)
end

-- Local values: readResolutionScale3d, writeResolutionScale3d
function SettingsModel:addResolutionScale3dSetting()
	self:addSetting(SettingsModel.SETTING.RESOLUTION_SCALE_3D, function()
		return SettingsModel.getScalingStateFromResolutionScaling(get3dResolutionScaling())
	end, function(p539_)
		set3dResolutionScaling(SettingsModel.getScalingFromResolutionScalingState(p539_))
	end)
end

-- Local values: readSensitivity, writeSensitivity
function SettingsModel:addCameraSensitivitySetting()
	self:addSetting(SettingsModel.SETTING.CAMERA_SENSITIVITY, function()
		-- upvalues: (copy) self
		return Utils.getStateFromValues(self.cameraSensitivityValues, self.cameraSensitivityStep, g_gameSettings:getValue(SettingsModel.SETTING.CAMERA_SENSITIVITY))
	end, function(p541_)
		-- upvalues: (copy) self
		g_gameSettings:setValue(SettingsModel.SETTING.CAMERA_SENSITIVITY, self.cameraSensitivityValues[p541_])
	end)
end

-- Local values: readSensitivity, writeSensitivity
function SettingsModel:addVehicleArmSensitivitySetting()
	self:addSetting(SettingsModel.SETTING.VEHICLE_ARM_SENSITIVITY, function()
		-- upvalues: (copy) self
		return Utils.getStateFromValues(self.vehicleArmSensitivityValues, self.vehicleArmSensitivityStep, g_gameSettings:getValue(SettingsModel.SETTING.VEHICLE_ARM_SENSITIVITY))
	end, function(p543_)
		-- upvalues: (copy) self
		g_gameSettings:setValue(SettingsModel.SETTING.VEHICLE_ARM_SENSITIVITY, self.vehicleArmSensitivityValues[p543_])
	end)
end

-- Local values: readBrightness, writeBrightness
function SettingsModel:addRealBeaconLightBrightnessSetting()
	self:addSetting(SettingsModel.SETTING.REAL_BEACON_LIGHT_BRIGHTNESS, function()
		-- upvalues: (copy) self
		return Utils.getStateFromValues(self.realBeaconLightBrightnessValues, self.realBeaconLightBrightnessStep, g_gameSettings:getValue(SettingsModel.SETTING.REAL_BEACON_LIGHT_BRIGHTNESS))
	end, function(p545_)
		-- upvalues: (copy) self
		g_gameSettings:setValue(SettingsModel.SETTING.REAL_BEACON_LIGHT_BRIGHTNESS, self.realBeaconLightBrightnessValues[p545_])
	end)
end

-- Local values: writeSetting
function SettingsModel:addActiveCameraSuspensionSetting()
	self:addSetting(SettingsModel.SETTING.ACTIVE_SUSPENSION_CAMERA, self.defaultReaderFunction, function(p547_)
		g_gameSettings:setValue(SettingsModel.SETTING.ACTIVE_SUSPENSION_CAMERA, p547_)
		g_messageCenter:publish(MessageType.SETTING_CHANGED[GameSettings.SETTING.ACTIVE_SUSPENSION_CAMERA], p547_)
	end)
end

-- Local values: writeSetting
function SettingsModel:addCamerCheckCollisionSetting()
	self:addSetting(SettingsModel.SETTING.CAMERA_CHECK_COLLISION, self.defaultReaderFunction, function(p549_)
		g_gameSettings:setValue(SettingsModel.SETTING.CAMERA_CHECK_COLLISION, p549_)
		g_messageCenter:publish(MessageType.SETTING_CHANGED[GameSettings.SETTING.CAMERA_CHECK_COLLISION], p549_)
	end)
end

-- Local values: writeSetting
function SettingsModel:addDirectionChangeModeSetting()
	self:addSetting(SettingsModel.SETTING.DIRECTION_CHANGE_MODE, self.defaultReaderFunction, function(p551_)
		g_gameSettings:setValue(SettingsModel.SETTING.DIRECTION_CHANGE_MODE, p551_)
		g_messageCenter:publish(MessageType.SETTING_CHANGED[GameSettings.SETTING.DIRECTION_CHANGE_MODE], p551_)
	end)
end

-- Local values: writeSetting
function SettingsModel:addGearShiftModeSetting()
	self:addSetting(SettingsModel.SETTING.GEAR_SHIFT_MODE, self.defaultReaderFunction, function(p553_)
		g_gameSettings:setValue(SettingsModel.SETTING.GEAR_SHIFT_MODE, p553_)
		g_messageCenter:publish(MessageType.SETTING_CHANGED[GameSettings.SETTING.GEAR_SHIFT_MODE], p553_)
	end)
end

-- Local values: writeSetting
function SettingsModel:addHudSpeedGaugeSetting()
	self:addSetting(SettingsModel.SETTING.HUD_SPEED_GAUGE, self.defaultReaderFunction, function(p555_)
		g_gameSettings:setValue(SettingsModel.SETTING.HUD_SPEED_GAUGE, p555_)
		g_messageCenter:publish(MessageType.SETTING_CHANGED[GameSettings.SETTING.HUD_SPEED_GAUGE], p555_)
	end)
end

-- Local values: writeSetting
function SettingsModel:addWoodHarvesterAutoCutSetting()
	self:addSetting(SettingsModel.SETTING.WOOD_HARVESTER_AUTO_CUT, self.defaultReaderFunction, function(p557_)
		g_gameSettings:setValue(SettingsModel.SETTING.WOOD_HARVESTER_AUTO_CUT, p557_)
		g_messageCenter:publish(MessageType.SETTING_CHANGED[GameSettings.SETTING.WOOD_HARVESTER_AUTO_CUT], p557_)
	end)
end

-- Local values: readVolume, writeVolume
function SettingsModel:addMasterVolumeSetting()
	self:addSetting(SettingsModel.SETTING.VOLUME_MASTER, function()
		return Utils.getMasterVolumeIndex(g_gameSettings:getValue(SettingsModel.SETTING.VOLUME_MASTER))
	end, function(p559_)
		local v560_ = Utils.getMasterVolumeFromIndex(p559_)
		g_soundMixer:setMasterVolume(v560_)
		g_gameSettings:setValue(SettingsModel.SETTING.VOLUME_MASTER, v560_)
	end)
end

-- Local values: readVolume, writeVolume
function SettingsModel:addMusicVolumeSetting()
	self:addSetting(SettingsModel.SETTING.VOLUME_MUSIC, function()
		return Utils.getMasterVolumeIndex(g_gameSettings:getValue(SettingsModel.SETTING.VOLUME_MUSIC))
	end, function(p562_)
		local v563_ = Utils.getMasterVolumeFromIndex(p562_)
		g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.MENU_MUSIC, v563_)
		g_gameSettings:setValue(SettingsModel.SETTING.VOLUME_MUSIC, v563_)
	end)
end

-- Local values: readVolume, writeVolume
function SettingsModel:addEnvironmentVolumeSetting()
	self:addSetting(SettingsModel.SETTING.VOLUME_ENVIRONMENT, function()
		return Utils.getMasterVolumeIndex(g_gameSettings:getValue(SettingsModel.SETTING.VOLUME_ENVIRONMENT))
	end, function(p565_)
		local v566_ = Utils.getMasterVolumeFromIndex(p565_)
		g_gameSettings:setValue(SettingsModel.SETTING.VOLUME_ENVIRONMENT, v566_)
		g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.ENVIRONMENT, v566_)
	end)
end

-- Local values: readVolume, writeVolume
function SettingsModel:addVehicleVolumeSetting()
	self:addSetting(SettingsModel.SETTING.VOLUME_VEHICLE, function()
		return Utils.getMasterVolumeIndex(g_gameSettings:getValue(SettingsModel.SETTING.VOLUME_VEHICLE))
	end, function(p568_)
		local v569_ = Utils.getMasterVolumeFromIndex(p568_)
		g_gameSettings:setValue(SettingsModel.SETTING.VOLUME_VEHICLE, v569_)
		g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.VEHICLE, v569_)
	end)
end

-- Local values: readVolume, writeVolume
function SettingsModel:addRadioVolumeSetting()
	self:addSetting(SettingsModel.SETTING.VOLUME_RADIO, function()
		return Utils.getMasterVolumeIndex(g_gameSettings:getValue(SettingsModel.SETTING.VOLUME_RADIO))
	end, function(p571_)
		local v572_ = Utils.getMasterVolumeFromIndex(p571_)
		g_gameSettings:setValue(SettingsModel.SETTING.VOLUME_RADIO, v572_)
		g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.RADIO, v572_)
	end)
end

-- Local values: readVolume, writeVolume
function SettingsModel:addVoiceVolumeSetting()
	self:addSetting(SettingsModel.SETTING.VOLUME_VOICE, function()
		return Utils.getMasterVolumeIndex(VoiceChatUtil.getOutputVolume())
	end, function(p574_)
		local v575_ = Utils.getMasterVolumeFromIndex(p574_)
		g_gameSettings:setValue(SettingsModel.SETTING.VOLUME_VOICE, v575_)
		VoiceChatUtil.setOutputVolume(v575_)
	end)
end

-- Local values: readVolume, writeVolume
function SettingsModel:addVoiceInputVolumeSetting()
	self:addSetting(SettingsModel.SETTING.VOLUME_VOICE_INPUT, function()
		return Utils.getRecordingVolumeIndex(VoiceChatUtil.getInputVolume())
	end, function(p577_)
		local v578_ = Utils.getRecordingVolumeFromIndex(p577_)
		g_gameSettings:setValue(SettingsModel.SETTING.VOLUME_VOICE_INPUT, v578_)
		VoiceChatUtil.setInputVolume(v578_)
	end)
end

-- Local values: readMode, writeMode
function SettingsModel:addVoiceModeSetting()
	self:addSetting(SettingsModel.SETTING.VOICE_MODE, function()
		return VoiceChatUtil.getInputMode()
	end, function(p580_)
		g_gameSettings:setValue(SettingsModel.SETTING.VOICE_MODE, p580_)
		VoiceChatUtil.setInputMode(p580_)
	end)
end

-- Local values: readMode, writeMode
function SettingsModel:addVoiceInputSensitivitySetting()
	self:addSetting(SettingsModel.SETTING.VOICE_INPUT_SENSITIVITY, function()
		return g_gameSettings:getValue(SettingsModel.SETTING.VOICE_INPUT_SENSITIVITY)
	end, function(p582_)
		g_gameSettings:setValue(SettingsModel.SETTING.VOICE_INPUT_SENSITIVITY, p582_)
		local v583_ = p582_ <= 1 and -1 or (p582_ - 2) / 10
		VoiceChatUtil.setInputSensitivity(v583_)
	end)
end

-- Local values: readVolume, writeVolume
function SettingsModel:addVolumeGUISetting()
	self:addSetting(SettingsModel.SETTING.VOLUME_GUI, function()
		return Utils.getMasterVolumeIndex(g_gameSettings:getValue(SettingsModel.SETTING.VOLUME_GUI))
	end, function(p585_)
		local v586_ = Utils.getMasterVolumeFromIndex(p585_)
		g_gameSettings:setValue(SettingsModel.SETTING.VOLUME_GUI, v586_)
		g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.GUI, v586_)
	end)
end

-- Local values: readVolume, writeVolume
function SettingsModel:addVolumeNoFocusSetting()
	self:addSetting(SettingsModel.SETTING.VOLUME_NO_FOCUS, function()
		return Utils.getMasterVolumeIndex(g_gameSettings:getValue(SettingsModel.SETTING.VOLUME_NO_FOCUS))
	end, function(p588_)
		local v589_ = Utils.getMasterVolumeFromIndex(p588_)
		g_gameSettings:setValue(SettingsModel.SETTING.VOLUME_NO_FOCUS, v589_)
		setInactiveWindowAudioVolume(v589_)
	end)
end

-- Local values: readVolume, writeVolume
function SettingsModel:addVolumeCharacterSetting()
	self:addSetting(SettingsModel.SETTING.VOLUME_CHARACTER, function()
		return Utils.getMasterVolumeIndex(g_gameSettings:getValue(SettingsModel.SETTING.VOLUME_CHARACTER))
	end, function(p591_)
		local v592_ = Utils.getMasterVolumeFromIndex(p591_)
		g_gameSettings:setValue(SettingsModel.SETTING.VOLUME_CHARACTER, v592_)
		g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.CHARACTER, v592_)
	end)
end

-- Local values: readSpeed, writeSpeed
function SettingsModel:addSteeringBackSpeedSetting()
	self:addSetting(SettingsModel.SETTING.STEERING_BACK_SPEED, function()
		-- upvalues: (copy) self
		return Utils.getStateFromValues(self.steeringBackSpeedValues, self.steeringBackSpeedStep, g_gameSettings:getValue(SettingsModel.SETTING.STEERING_BACK_SPEED))
	end, function(p594_)
		-- upvalues: (copy) self
		g_gameSettings:setValue(SettingsModel.SETTING.STEERING_BACK_SPEED, self.steeringBackSpeedValues[p594_])
	end)
end

-- Local values: readSpeed, writeSpeed
function SettingsModel:addSteeringSensitivitySetting()
	self:addSetting(SettingsModel.SETTING.STEERING_SENSITIVITY, function()
		-- upvalues: (copy) self
		return Utils.getStateFromValues(self.steeringSensitivityValues, self.steeringSensitivityStep, g_gameSettings:getValue(SettingsModel.SETTING.STEERING_SENSITIVITY))
	end, function(p596_)
		-- upvalues: (copy) self
		g_gameSettings:setValue(SettingsModel.SETTING.STEERING_SENSITIVITY, self.steeringSensitivityValues[p596_])
	end)
end

-- Local values: read, write
function SettingsModel:addGyroscopeSteeringSetting()
	self:addSetting(SettingsModel.SETTING.GYROSCOPE_STEERING, function()
		return g_gameSettings:getValue(SettingsModel.SETTING.GYROSCOPE_STEERING)
	end, function(p598_)
		g_gameSettings:setValue(SettingsModel.SETTING.GYROSCOPE_STEERING, p598_)
	end)
end

-- Local values: read, write
function SettingsModel:addHintsSetting()
	self:addSetting(SettingsModel.SETTING.HINTS, function()
		return g_gameSettings:getValue(SettingsModel.SETTING.HINTS)
	end, function(p600_)
		g_gameSettings:setValue(SettingsModel.SETTING.HINTS, p600_)
	end)
end

-- Local values: read, write
function SettingsModel:addCameraTiltingSetting()
	self:addSetting(SettingsModel.SETTING.CAMERA_TILTING, function()
		return g_gameSettings:getValue(SettingsModel.SETTING.CAMERA_TILTING)
	end, function(p602_)
		g_gameSettings:setValue(SettingsModel.SETTING.CAMERA_TILTING, p602_)
	end)
end

-- Local values: read, write
function SettingsModel:addForceFeedbackSetting()
	self:addSetting(SettingsModel.SETTING.FORCE_FEEDBACK, function()
		return Utils.getMasterVolumeIndex(g_gameSettings:getValue(SettingsModel.SETTING.FORCE_FEEDBACK))
	end, function(p604_)
		g_gameSettings:setValue(SettingsModel.SETTING.FORCE_FEEDBACK, Utils.getMasterVolumeFromIndex(p604_))
	end)
end

-- Local values: texts, mapping, mappingReverse, enumOrdered, name, quality, numMappings, quality, name, text, getTexts, valueToRaw, rawToValue, readValue, writeValue
function SettingsModel:addEngineQualitySetting(key, enum, supportFunc, nameFunc, setFunc, getFunc, onChangedFunc, excludeOffText, restartRequired)
	local v615_ = {}
	local v_u_616_ = {}
	local v_u_617_ = {}
	local v_u_618_ = {}
	for v619_, v620_ in pairs(enum) do
		v615_[v620_ + 1] = v619_
	end
	local v621_ = 1
	for v622_, v623_ in ipairs(v615_) do
		local v624_ = v622_ - 1
		if v624_ ~= enum.NUM and (supportFunc == nil or supportFunc(v624_)) then
			if excludeOffText and v624_ == enum.OFF then
				v_u_617_[v624_] = -1
				v_u_618_[-1] = v624_
			else
				local v625_ = self.qualityTexts[v623_]
				if v625_ == nil and nameFunc ~= nil then
					v625_ = nameFunc(v624_)
				end
				table.insert(v_u_616_, v625_)
				v_u_617_[v624_] = v621_
				v_u_618_[v621_] = v624_
				v621_ = v621_ + 1
			end
		end
	end
	self:addSetting(key, function()
		-- upvalues: (copy) v_u_617_, (copy) getFunc
		return v_u_617_[getFunc()]
	end, function(p626_)
		-- upvalues: (copy) v_u_618_, (copy) getFunc, (copy) setFunc
		local v627_ = v_u_618_[p626_]
		if v627_ ~= nil and getFunc() ~= v627_ then
			setFunc(v627_)
		end
	end, Utils.getNoNil(restartRequired, false), function()
		-- upvalues: (copy) v_u_616_
		return v_u_616_
	end, function(p628_)
		-- upvalues: (copy) v_u_617_
		return v_u_617_[p628_]
	end, function(p629_)
		-- upvalues: (copy) v_u_618_
		return v_u_618_[p629_]
	end, onChangedFunc)
end

function SettingsModel.getShadowQualityIndex(shadowQuality, hasShadowFocusBox)
	return shadowQuality == 1 and 2 or (shadowQuality == 2 and hasShadowFocusBox == false and 3 or (shadowQuality == 2 and hasShadowFocusBox == true and 4 or 1))
end

function SettingsModel.getShadowQualityByIndex(shadowIndex)
	return shadowIndex == 2 and 1 or (shadowIndex == 3 and 2 or (shadowIndex == 4 and 2 or 0))
end

function SettingsModel.getHasShadowFocusBoxByIndex(shadowIndex)
	if shadowIndex == 2 then
		return false
	elseif shadowIndex == 3 then
		return false
	else
		return shadowIndex == 4
	end
end

function SettingsModel.getShaderQualityIndex(shaderQuality)
	return shaderQuality == 1 and 2 or (shaderQuality == 2 and 3 or (shaderQuality == 3 and 4 or 1))
end

function SettingsModel.getShaderQualityByIndex(shaderIndex)
	return shaderIndex == 2 and 1 or (shaderIndex == 3 and 2 or (shaderIndex == 4 and 3 or 0))
end

function SettingsModel.getShadowMapFilterIndex(shadowFilter)
	return shadowFilter == 16 and 2 or 1
end

function SettingsModel.getShadowMapFilterByIndex(shadowFilterIndex)
	return shadowFilterIndex == 2 and 16 or 4
end

function SettingsModel.getTerrainQualityIndex(terrainQuality)
	local v639_ = terrainQuality + 1
	local v640_ = math.max(v639_, 1)
	return math.min(v640_, 4)
end

function SettingsModel.getTerrainQualityByIndex(terrainQualityIndex)
	local v642_ = terrainQualityIndex - 1
	local v643_ = math.max(v642_, 0)
	return math.min(v643_, 3)
end

function SettingsModel.getTextureResolutionIndex(textureResolution)
	return textureResolution == 0 and 2 or 1
end

function SettingsModel.getTextureResolutionByIndex(textureResolutionIndex)
	return textureResolutionIndex == 2 and 0 or 1
end

function SettingsModel.getNumOfReflectionMapsByIndex(index)
	local v647_ = index - 1
	return math.clamp(v647_, 0, 7)
end

function SettingsModel.getNumOfReflectionMapsIndex(numOfReflectionMaps)
	return math.clamp(numOfReflectionMaps, 0, 7) + 1
end
function SettingsModel.getVolumeMeshTessellationCoeff()
	return 0.5 + (2 - getVolumeMeshTessellationCoeff())
end

function SettingsModel.setVolumeMeshTessellationCoeff(coeff)
	setVolumeMeshTessellationCoeff(2 + (0.5 - coeff))
end

function SettingsModel.getScalingFromResolutionScalingState(state)
	return 0.4 + 0.1 * state
end

function SettingsModel.getScalingStateFromResolutionScaling(scaling)
	return MathUtil.round((scaling - 0.4) * 10)
end
