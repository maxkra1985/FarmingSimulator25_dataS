SettingsModel = {}
local SettingsModel_mt = Class(SettingsModel)
SettingsModel.SETTING_CLASS = { SAVE_NONE = 0, SAVE_ENGINE_QUALITY_SETTINGS = 1, SAVE_GAMEPLAY_SETTINGS = 2, SAVE_ALL = 3 }
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
	["RESOLUTION_SCALE_3D"] = "resolutionScale3d",
}
function SettingsModel.new()
	local self = setmetatable({}, SettingsModel_mt)
	self.settings = {}
	self.sortedSettings = {}
	self.settingReaders = {}
	self.settingWriters = {}
	self.settingTexts = {}
	self.settingsRawToValues = {}
	self.settingsValueToRaws = {}
	self.settingsOnChanges = {}
	self.defaultReaderFunction = self:makeDefaultReaderFunction()
	self.defaultWriterFunction = self:makeDefaultWriterFunction()
	self.volumeTexts = {}
	self.voiceInputThresholdTexts = {}
	self.recordingVolumeTexts = {}
	self.voiceModeTexts = {}
	self.brightnessTexts = {}
	self.fovYTexts = {}
	self.indexToFovYMapping = {}
	self.fovYToIndexMapping = {}
	self.uiScaleValues = {}
	self.uiScaleTexts = {}
	self.cameraSensitivityValues = {}
	self.cameraSensitivityStrings = {}
	self.cameraSensitivityStep = 0.25
	self.vehicleArmSensitivityValues = {}
	self.vehicleArmSensitivityStrings = {}
	self.vehicleArmSensitivityStep = 0.25
	self.realBeaconLightBrightnessValues = {}
	self.realBeaconLightBrightnessStrings = {}
	self.realBeaconLightBrightnessStep = 0.1
	self.steeringBackSpeedValues = {}
	self.steeringBackSpeedStrings = {}
	self.steeringBackSpeedStep = 1
	self.steeringSensitivityValues = {}
	self.steeringSensitivityStrings = {}
	self.steeringSensitivityStep = 0.1
	self.moneyUnitTexts = {}
	self.distanceUnitTexts = {}
	self.temperatureUnitTexts = {}
	self.areaUnitTexts = {}
	self.radioModeTexts = {}
	self.resolutionScaleTexts = {}
	self.resolutionScale3dTexts = {}
	self.drsTargetFPSTexts = {}
	self.sharpnessTexts = {}
	self.scalingModeTexts = {}
	self.shadowQualityTexts = {}
	self.shadowDistanceQualityTexts = {}
	self.softShadowsTexts = {}
	self.fourStateTexts = {}
	self.lowHighTexts = {}
	self.shadowMapMaxLightsTexts = {}
	self.hdrPeakBrightnessValues = {}
	self.hdrPeakBrightnessTexts = {}
	self.hdrPeakBrightnessStep = 0.05
	self.hdrContrastValues = {}
	self.hdrContrastTexts = {}
	self.hdrContrastStep = 0.01
	self.overlayBrightnessValues = {}
	self.overlayBrightnessTexts = {}
	self.overlayBrightnessStep = 0.05
	self.percentValues = {}
	self.perentageTexts = {}
	self.percentStep = 0.05
	self.tireTracksValues = {}
	self.tireTracksTexts = {}
	self.tireTracksStep = 0.5
	self.maxMirrorsTexts = {}
	self.ssaoQualityTexts = {}
	self.resolutionTexts = {}
	self.fullscreenModeTexts = {}
	self.mpLanguageTexts = {}
	self.inputHelpModeTexts = {}
	self.directionChangeModeTexts = {}
	self.gearShiftModeTexts = {}
	self.hudSpeedGaugeTexts = {}
	self.frameLimitTexts = {}
	self.intialValues = {}
	self.deviceSettings = {}
	self.currentDevice = {}
	self.minBrightness = 0.5
	self.maxBrightness = 2
	self.brightnessStep = 0.1
	self.minSharpness = 0
	self.maxSharpness = 2
	self.sharpnessStep = 0.1
	self.qualityTexts = { OFF = g_i18n:getText("ui_off"), ON = g_i18n:getText("ui_on"), LOW = g_i18n:getText("setting_low"), MEDIUM = g_i18n:getText("setting_medium"), HIGH = g_i18n:getText("setting_high"), VERY_HIGH = g_i18n:getText("setting_veryHigh"), ULTRA = g_i18n:getText("setting_ultra"), MAX_QUALITY = g_i18n:getText("setting_maxQuality"), BALANCED_PERFORMANCE = g_i18n:getText("setting_balancedPerformance"), MAX_PERFORMANCE = g_i18n:getText("setting_maxPerformance"), ULTRA_PERFORMANCE = g_i18n:getText("setting_ultraPerformance"), ULTRA_QUALITY = g_i18n:getText("setting_ultraQuality"), ULTRA_QUALITY_PLUS = g_i18n:getText("setting_ultraQualityPlus"), QUALITY = g_i18n:getText("setting_quality"), BALANCED = g_i18n:getText("setting_balanced"), PERFORMANCE = g_i18n:getText("setting_performance") }
	self:initialize()
	return self
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
		self:addEngineQualitySetting(SettingsModel.SETTING.DLSS, DLSSQuality, getSupportsDLSSQuality, getDLSSQualityName, setDLSSQuality, getDLSSQuality, function(value, rawValue, hasChanged)
			if rawValue ~= DLSSQuality.OFF then
				self:setRawValue(SettingsModel.SETTING.RESOLUTION_SCALE, SettingsModel.getScalingStateFromResolutionScaling(1))
				self:setRawValue(SettingsModel.SETTING.RESOLUTION_SCALE_3D, SettingsModel.getScalingStateFromResolutionScaling(1))
				self:setRawValue(SettingsModel.SETTING.MSAA, MSAA.OFF)
				self:setRawValue(SettingsModel.SETTING.FIDELITYFX_SR, FidelityFxSRQuality.OFF)
				self:setRawValue(SettingsModel.SETTING.FIDELITYFX_SR_30, FidelityFxSR30Quality.OFF)
				self:setRawValue(SettingsModel.SETTING.XESS, XeSSQuality.OFF)
				self:setRawValue(SettingsModel.SETTING.POST_PROCESS_AA, PostProcessAntiAliasing.OFF)
			else
				self:setRawValue(SettingsModel.SETTING.DLSS_FRAME_GENERATION, FrameInterpolationMode.FRAME_INTERPOLATION_OFF)
			end
		end, true)
		self:addEngineQualitySetting(SettingsModel.SETTING.FIDELITYFX_SR, FidelityFxSRQuality, getSupportsFidelityFxSRQuality, getFidelityFxSRQualityName, setFidelityFxSRQuality, getFidelityFxSRQuality, function(value, rawValue, hasChanged)
			if rawValue ~= FidelityFxSRQuality.OFF then
				self:setRawValue(SettingsModel.SETTING.RESOLUTION_SCALE, SettingsModel.getScalingStateFromResolutionScaling(1))
				self:setRawValue(SettingsModel.SETTING.RESOLUTION_SCALE_3D, SettingsModel.getScalingStateFromResolutionScaling(1))
				self:setRawValue(SettingsModel.SETTING.POST_PROCESS_AA, PostProcessAntiAliasing.TAA)
				self:setRawValue(SettingsModel.SETTING.DLSS, DLSSQuality.OFF)
				self:setRawValue(SettingsModel.SETTING.FIDELITYFX_SR_30, FidelityFxSR30Quality.OFF)
				self:setRawValue(SettingsModel.SETTING.XESS, XeSSQuality.OFF)
			end
		end, true)
		self:addEngineQualitySetting(SettingsModel.SETTING.FIDELITYFX_SR_30, FidelityFxSR30Quality, getSupportsFidelityFxSR30Quality, getFidelityFxSR30QualityName, setFidelityFxSR30Quality, getFidelityFxSR30Quality, function(value, rawValue, hasChanged)
			if rawValue ~= FidelityFxSR30Quality.OFF then
				self:setRawValue(SettingsModel.SETTING.RESOLUTION_SCALE, SettingsModel.getScalingStateFromResolutionScaling(1))
				self:setRawValue(SettingsModel.SETTING.RESOLUTION_SCALE_3D, SettingsModel.getScalingStateFromResolutionScaling(1))
				self:setRawValue(SettingsModel.SETTING.MSAA, MSAA.OFF)
				self:setRawValue(SettingsModel.SETTING.DLSS, DLSSQuality.OFF)
				self:setRawValue(SettingsModel.SETTING.FIDELITYFX_SR, FidelityFxSRQuality.OFF)
				self:setRawValue(SettingsModel.SETTING.XESS, XeSSQuality.OFF)
				self:setRawValue(SettingsModel.SETTING.POST_PROCESS_AA, PostProcessAntiAliasing.OFF)
			else
				self:setValue(SettingsModel.SETTING.FIDELITYFX_SR_30_FRAME_GENERATION, FrameInterpolationMode.FRAME_INTERPOLATION_OFF)
			end
		end, true)
		self:addEngineQualitySetting(SettingsModel.SETTING.VALAR, ValarQuality, getSupportsValarQuality, getValarQualityName, setValarQuality, getValarQuality, function(value, rawValue, hasChanged)
			if rawValue ~= ValarQuality.OFF then
				g_settingsModel:setRawValue(SettingsModel.SETTING.MSAA, MSAA.OFF)
			end
		end)
		self:addEngineQualitySetting(SettingsModel.SETTING.XESS, XeSSQuality, getSupportsXeSSQuality, getXeSSQualityName, setXeSSQuality, getXeSSQuality, function(value, rawValue, hasChanged)
			if rawValue ~= XeSSQuality.OFF then
				self:setRawValue(SettingsModel.SETTING.RESOLUTION_SCALE, SettingsModel.getScalingStateFromResolutionScaling(1))
				self:setRawValue(SettingsModel.SETTING.RESOLUTION_SCALE_3D, SettingsModel.getScalingStateFromResolutionScaling(1))
				self:setRawValue(SettingsModel.SETTING.MSAA, MSAA.OFF)
				self:setRawValue(SettingsModel.SETTING.DLSS, DLSSQuality.OFF)
				self:setRawValue(SettingsModel.SETTING.FIDELITYFX_SR, FidelityFxSRQuality.OFF)
				self:setRawValue(SettingsModel.SETTING.FIDELITYFX_SR_30, FidelityFxSR30Quality.OFF)
				self:setRawValue(SettingsModel.SETTING.POST_PROCESS_AA, PostProcessAntiAliasing.OFF)
			end
		end, true)
		self:addEngineQualitySetting(SettingsModel.SETTING.MSAA, MSAA, nil, getMSAAName, setMSAA, getMSAA, function(value, rawValue, hasChanged)
			if rawValue ~= MSAA.OFF then
				self:setRawValue(SettingsModel.SETTING.DLSS, DLSSQuality.OFF)
				self:setRawValue(SettingsModel.SETTING.FIDELITYFX_SR_30, FidelityFxSR30Quality.OFF)
				self:setRawValue(SettingsModel.SETTING.XESS, XeSSQuality.OFF)
				if self:getRawValue(SettingsModel.SETTING.POST_PROCESS_AA) ~= PostProcessAntiAliasing.TAA and self:getRawValue(SettingsModel.SETTING.POST_PROCESS_AA) ~= PostProcessAntiAliasing.OFF then
					self:setRawValue(SettingsModel.SETTING.POST_PROCESS_AA, PostProcessAntiAliasing.OFF)
				end
			end
		end)
		self:addEngineQualitySetting(SettingsModel.SETTING.POST_PROCESS_AA, PostProcessAntiAliasing, getSupportsPostProcessAntiAliasing, getPostProcessAntiAliasingName, setPostProcessAntiAliasing, getPostProcessAntiAliasing, function(value, rawValue, hasChanged)
			if rawValue ~= PostProcessAntiAliasing.OFF then
				self:setRawValue(SettingsModel.SETTING.DLSS, DLSSQuality.OFF)
				self:setRawValue(SettingsModel.SETTING.DLSS_FRAME_GENERATION, FrameInterpolationMode.FRAME_INTERPOLATION_OFF)
				self:setRawValue(SettingsModel.SETTING.FIDELITYFX_SR_30, FidelityFxSR30Quality.OFF)
				self:setRawValue(SettingsModel.SETTING.XESS, XeSSQuality.OFF)
				if rawValue ~= PostProcessAntiAliasing.FSR3 then
					self:setValue(SettingsModel.SETTING.FIDELITYFX_SR_30_FRAME_GENERATION, FrameInterpolationMode.FRAME_INTERPOLATION_OFF)
				end
				if rawValue ~= PostProcessAntiAliasing.XESS then
					self:setValue(SettingsModel.SETTING.XESS_FRAME_GENERATION, FrameInterpolationMode.FRAME_INTERPOLATION_OFF)
				end
				if rawValue ~= PostProcessAntiAliasing.DLAA then
					self:setRawValue(SettingsModel.SETTING.DLSS_FRAME_GENERATION, FrameInterpolationMode.FRAME_INTERPOLATION_OFF)
				end
				if rawValue ~= PostProcessAntiAliasing.TAA then
					self:setRawValue(SettingsModel.SETTING.MSAA, MSAA.OFF)
				end
				if rawValue == PostProcessAntiAliasing.DLAA then
					self:setRawValue(SettingsModel.SETTING.FIDELITYFX_SR, FidelityFxSRQuality.OFF)
					return
				end
				if rawValue == PostProcessAntiAliasing.FSR3 then
					self:setRawValue(SettingsModel.SETTING.FIDELITYFX_SR, FidelityFxSRQuality.OFF)
				end
			else
				self:setValue(SettingsModel.SETTING.FIDELITYFX_SR_30_FRAME_GENERATION, FrameInterpolationMode.FRAME_INTERPOLATION_OFF)
				self:setValue(SettingsModel.SETTING.XESS_FRAME_GENERATION, FrameInterpolationMode.FRAME_INTERPOLATION_OFF)
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
function SettingsModel:addSetting(gameSettingsKey, readerFunction, writerFunction, restartRequired, textFunction, rawToValueFunc, valueToRawFunc, onChangeFunc)
	local initialValue = readerFunction(gameSettingsKey)
	self.settings[gameSettingsKey] = { key = gameSettingsKey, initial = initialValue, saved = initialValue, changed = initialValue, restartRequired = restartRequired }
	self.settingReaders[gameSettingsKey] = readerFunction
	self.settingWriters[gameSettingsKey] = writerFunction
	self.settingTexts[gameSettingsKey] = textFunction
	self.settingsRawToValues[gameSettingsKey] = rawToValueFunc
	self.settingsValueToRaws[gameSettingsKey] = valueToRawFunc
	self.settingsOnChanges[gameSettingsKey] = onChangeFunc
	table.insert(self.sortedSettings, self.settings[gameSettingsKey])
end
function SettingsModel:setValue(settingKey, value)
	if self.settings[settingKey] == nil then
		Logging.warning("SettingsModel key %q is not registered", settingKey)
	elseif value ~= nil then
		local oldValue = self.settings[settingKey].changed
		self.settings[settingKey].changed = value
		local rawValue = value
		local func = self.settingsValueToRaws[settingKey]
		if func ~= nil then
			rawValue = func(value)
		end
		local onChangedFunc = self.settingsOnChanges[settingKey]
		if onChangedFunc ~= nil then
			onChangedFunc(value, rawValue, oldValue ~= value)
		end
	end
end
function SettingsModel:setRawValue(settingsKey, value)
	local func = self.settingsRawToValues[settingsKey]
	if func ~= nil then
		value = func(value)
	end
	self:setValue(settingsKey, value)
end
function SettingsModel:getValue(settingKey, trueValue)
	if trueValue then
		return self.settingReaders[settingKey](settingKey)
	elseif self.settings[settingKey] == nil then
		return 0
	else
		return self.settings[settingKey].changed
	end
end
function SettingsModel:getRawValue(settingKey, trueValue)
	local value = self:getValue(settingKey, trueValue)
	local func = self.settingsValueToRaws[settingKey]
	if func ~= nil then
		value = func(value)
	end
	return value
end
function SettingsModel:getTexts(settingKey)
	local func = self.settingTexts[settingKey]
	if func ~= nil then
		return func()
	else
		return nil
	end
end
function SettingsModel:refresh()
	for settingsKey, setting in pairs(self.settings) do
		setting.initial = self.settingReaders[settingsKey](settingsKey)
		setting.changed = setting.initial
		setting.saved = setting.initial
	end
end
function SettingsModel:refreshChangedValue()
	for settingsKey, setting in pairs(self.settings) do
		setting.changed = self.settingReaders[settingsKey](settingsKey)
		setting.saved = setting.changed
	end
end
function SettingsModel:reset()
	for _, setting in pairs(self.sortedSettings) do
		local hasChanged = setting.initial ~= setting.changed or setting.initial ~= setting.saved
		setting.changed = setting.initial
		setting.saved = setting.initial
		if hasChanged then
			local writeFunction = self.settingWriters[setting.key]
			writeFunction(setting.changed, setting.key)
		end
	end
	setUserConfirmScreenMode(true)
	self:resetDeviceChanges()
end
function SettingsModel:getSettingExists(settingsKey)
	local setting = self.settings[settingsKey]
	return setting ~= nil
end
function SettingsModel:getHasValueChanged(settingKey)
	local setting = self.settings[settingKey]
	if setting == nil then
		Logging.devError("Setting '%s' is not defined!", tostring(settingKey))
		return false
	else
		return setting.initial ~= setting.changed or setting.initial ~= setting.saved
	end
end
function SettingsModel:hasChanges()
	for _, setting in pairs(self.settings) do
		if setting.initial ~= setting.changed or setting.initial ~= setting.saved then
			return true
		end
	end
	return self:hasDeviceChanges()
end
function SettingsModel:needsRestartToApplyChanges()
	for _, setting in pairs(self.settings) do
		if (setting.initial ~= setting.changed or setting.initial ~= setting.saved) and setting.restartRequired then
			return true, self:needsProcessRestartToApplyChanges()
		end
	end
	return false, false
end
function SettingsModel:needsProcessRestartToApplyChanges()
	if self:getSettingExists(SettingsModel.SETTING.RESOLUTION) and g_settingsModel:getHasValueChanged(SettingsModel.SETTING.RESOLUTION) then
		return true
	end
	if self:getSettingExists(SettingsModel.SETTING.FULLSCREEN_MODE) and g_settingsModel:getHasValueChanged(SettingsModel.SETTING.FULLSCREEN_MODE) then
		return true
	end
	return false
end
function SettingsModel:applyChanges(settingClassesToSave)
	for _, setting in pairs(self.sortedSettings) do
		local settingsKey = setting.key
		local savedValue = self.settings[settingsKey].saved
		local changedValue = self.settings[settingsKey].changed
		if savedValue ~= changedValue then
			local writeFunction = self.settingWriters[settingsKey]
			writeFunction(changedValue, settingsKey)
			self.settings[settingsKey].saved = changedValue
		end
		self.settings[settingsKey].initial = changedValue
	end
	if settingClassesToSave ~= 0 then
		self:saveChanges(settingClassesToSave)
	end
end
function SettingsModel:saveChanges(settingClassesToSave)
	if bit32.band(settingClassesToSave, SettingsModel.SETTING_CLASS.SAVE_GAMEPLAY_SETTINGS) ~= 0 then
		g_gameSettings:save()
	end
	self:saveDeviceChanges()
	if bit32.band(settingClassesToSave, SettingsModel.SETTING_CLASS.SAVE_ENGINE_QUALITY_SETTINGS) ~= 0 then
		saveHardwareScalability()
		if GS_IS_CONSOLE_VERSION or GS_IS_MOBILE_VERSION then
			executeSettingsChange()
		end
	end
end
function SettingsModel:applyPerformanceClass(value)
	local settingsKey = SettingsModel.SETTING.PERFORMANCE_CLASS
	local writeFunction = self.settingWriters[settingsKey]
	writeFunction(value, settingsKey)
	self.settings[settingsKey].changed = value
	self.settings[settingsKey].saved = value
	self:refreshChangedValue()
end
function SettingsModel:applyCustomSettings()
	for settingsKey in pairs(self.settings) do
		if settingsKey == SettingsModel.SETTING.PERFORMANCE_CLASS then
			continue
		end
		local changedValue = self.settings[settingsKey].changed
		if changedValue == self.settings[settingsKey].saved then
			continue
		end
		local writeFunction = self.settingWriters[settingsKey]
		writeFunction(changedValue, settingsKey)
		self.settings[settingsKey].saved = changedValue
	end
end
function SettingsModel:createControlDisplayValues()
	self.volumeTexts = { g_i18n:getText("ui_off"), "10%", "20%", "30%", "40%", "50%", "60%", "70%", "80%", "90%", "100%" }
	self.recordingVolumeTexts = { g_i18n:getText("ui_auto"), "50%", "60%", "70%", "80%", "90%", "100%", "110%", "120%", "130%", "140%", "150%" }
	self.voiceModeTexts = { g_i18n:getText("ui_off"), g_i18n:getText("ui_voiceActivity") }
	if Platform.supportsPushToTalk then
		table.insert(self.voiceModeTexts, g_i18n:getText("ui_pushToTalk"))
	end
	self.voiceInputThresholdTexts = { g_i18n:getText("ui_auto"), "0%", "10%", "20%", "30%", "40%", "50%", "60%", "70%", "80%", "90%", "100%" }
	for i = self.minBrightness, self.maxBrightness + 0.0001, self.brightnessStep do
		table.insert(self.brightnessTexts, string.format("%.1f", i))
	end
	local index = 1
	local min = math.deg(Platform.minFovY)
	local max = math.deg(Platform.maxFovY)
	for i = min, max do
		self.indexToFovYMapping[index] = i
		self.fovYToIndexMapping[i] = index
		table.insert(self.fovYTexts, string.format(g_i18n:getText("setting_fovyDegree"), i))
		index = index + 1
	end
	for i = 1, 16 do
		table.insert(self.uiScaleTexts, string.format("%d%%", 50 + (i - 1) * 5))
	end
	for i = 0.5, 2.1, 0.1 do
		table.insert(self.resolutionScaleTexts, string.format("%d%%", MathUtil.round(i * 100)))
	end
	for i = 0.5, 2.1, 0.1 do
		table.insert(self.resolutionScale3dTexts, string.format("%d%%", MathUtil.round(i * 100)))
	end
	for i = 0.5, 3, self.cameraSensitivityStep do
		table.insert(self.cameraSensitivityStrings, string.format("%d%%", i * 100))
		table.insert(self.cameraSensitivityValues, i)
	end
	for i = 0.5, 3, self.vehicleArmSensitivityStep do
		table.insert(self.vehicleArmSensitivityStrings, string.format("%d%%", i * 100))
		table.insert(self.vehicleArmSensitivityValues, i)
	end
	for i = 0, 1, self.realBeaconLightBrightnessStep do
		if 0 < i then
			table.insert(self.realBeaconLightBrightnessStrings, string.format("%d%%", i * 100 + 0.5))
		else
			table.insert(self.realBeaconLightBrightnessStrings, g_i18n:getText("setting_off"))
		end
		table.insert(self.realBeaconLightBrightnessValues, i)
	end
	local steeringBackSpeedSettings = Platform.gameplay.steeringBackSpeedSettings
	for i = 1, #steeringBackSpeedSettings do
		table.insert(self.steeringBackSpeedStrings, string.format("%d%%", steeringBackSpeedSettings[i] * 10))
		table.insert(self.steeringBackSpeedValues, steeringBackSpeedSettings[i])
	end
	for i = 0.5, 3.1, self.steeringSensitivityStep do
		table.insert(self.steeringSensitivityStrings, string.format("%d%%", i * 100 + 0.5))
		table.insert(self.steeringSensitivityValues, i)
	end
	self.moneyUnitTexts = { g_i18n:getText("unit_euro"), g_i18n:getText("unit_dollar"), g_i18n:getText("unit_pound") }
	self.distanceUnitTexts = { g_i18n:getText("unit_km"), g_i18n:getText("unit_miles") }
	self.temperatureUnitTexts = { g_i18n:getText("unit_celsius"), g_i18n:getText("unit_fahrenheit") }
	self.areaUnitTexts = { g_i18n:getText("unit_ha"), g_i18n:getText("unit_acre") }
	self.radioModeTexts = { g_i18n:getText("setting_radioAlways"), g_i18n:getText("setting_radioVehicleOnly") }
	self.shadowQualityTexts = { g_i18n:getText("setting_off"), g_i18n:getText("setting_medium"), g_i18n:getText("setting_high"), g_i18n:getText("setting_veryHigh") }
	self.shadowDistanceQualityTexts = { g_i18n:getText("setting_low"), g_i18n:getText("setting_medium"), g_i18n:getText("setting_high") }
	self.softShadowsTexts = { g_i18n:getText("ui_off"), g_i18n:getText("ui_on") }
	self.fourStateTexts = { g_i18n:getText("setting_low"), g_i18n:getText("setting_medium"), g_i18n:getText("setting_high"), g_i18n:getText("setting_veryHigh") }
	self.fiveStateTexts = { g_i18n:getText("setting_low"), g_i18n:getText("setting_medium"), g_i18n:getText("setting_high"), g_i18n:getText("setting_veryHigh"), g_i18n:getText("setting_ultra") }
	self.lowHighTexts = { g_i18n:getText("setting_low"), g_i18n:getText("setting_high") }
	self.ssaoQualityTexts = { g_i18n:getText("setting_low"), g_i18n:getText("setting_medium"), g_i18n:getText("setting_high"), g_i18n:getText("setting_veryHigh") }
	self.drsTargetFPSTexts = {}
	self.drsTargetFPSMapping = {}
	self.drsTargetFPSMappingReverse = {}
	for _, value in ipairs(g_gameSettings.frameLimitValues) do
		table.insert(self.drsTargetFPSTexts, tostring(value))
		self.drsTargetFPSMapping[value] = #self.drsTargetFPSTexts
		self.drsTargetFPSMappingReverse[#self.drsTargetFPSTexts] = value
	end
	for i = self.minSharpness, self.maxSharpness + 0.0001, self.sharpnessStep do
		table.insert(self.sharpnessTexts, string.format("%.1f", i))
	end
	self.scalingModeTexts = { g_i18n:getText("setting_off") }
	for index, value in pairs(FidelityFxSRQuality) do
		if value == FidelityFxSRQuality.OFF or value == FidelityFxSRQuality.NUM then
			continue
		end
		if getSupportsFidelityFxSRQuality(value) then
			table.insert(self.scalingModeTexts, g_i18n:getText("setting_fsr1"))
			break
		end
	end
	for index, value in pairs(FidelityFxSR30Quality) do
		if value == FidelityFxSR30Quality.OFF or value == FidelityFxSR30Quality.NUM then
			continue
		end
		if getSupportsFidelityFxSR30Quality(value) then
			if getFidelityFxSuperResolutionVersion() == 4 then
				table.insert(self.scalingModeTexts, g_i18n:getText("setting_fsr4"))
				break
			end
			table.insert(self.scalingModeTexts, g_i18n:getText("setting_fsr3"))
			break
		end
	end
	for index, value in pairs(DLSSQuality) do
		if value == DLSSQuality.OFF or value == DLSSQuality.NUM then
			continue
		end
		if getSupportsDLSSQuality(value) then
			table.insert(self.scalingModeTexts, g_i18n:getText("setting_DLSS"))
			break
		end
	end
	for index, value in pairs(XeSSQuality) do
		if value == XeSSQuality.OFF or value == XeSSQuality.NUM then
			continue
		end
		if getSupportsXeSSQuality(value) then
			table.insert(self.scalingModeTexts, g_i18n:getText("setting_xeSS"))
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
	for i = 0, 95 do
		local value = 50 + i * self.hdrPeakBrightnessStep
		table.insert(self.hdrPeakBrightnessTexts, string.format("%d", value))
		table.insert(self.hdrPeakBrightnessValues, value)
	end
	self.hdrContrastValues = {}
	self.hdrContrastTexts = {}
	for i = 0, 120 do
		local value = 0.8 + i * self.hdrContrastStep
		table.insert(self.hdrContrastTexts, string.format("%.2f", value))
		table.insert(self.hdrContrastValues, value)
	end
	self.overlayBrightnessValues = {}
	self.overlayBrightnessTexts = {}
	self.overlayBrightnessStep = 10
	for i = 0, 95 do
		local value = 50 + i * self.overlayBrightnessStep
		table.insert(self.overlayBrightnessTexts, string.format("%d", value))
		table.insert(self.overlayBrightnessValues, value)
	end
	self.shadowMapMaxLightsTexts = {}
	for i = 1, 10 do
		table.insert(self.shadowMapMaxLightsTexts, string.format("%d", i))
	end
	self.percentValues = {}
	self.perentageTexts = {}
	self.percentStep = 0.05
	for i = 0, 30 do
		table.insert(self.perentageTexts, string.format("%.f%%", (0.5 + i * self.percentStep) * 100))
		table.insert(self.percentValues, 0.5 + i * self.percentStep)
	end
	self.tireTracksValues = {}
	self.tireTracksTexts = {}
	self.tireTracksStep = 0.5
	for i = 0, 4, self.tireTracksStep do
		table.insert(self.tireTracksTexts, string.format("%d%%", i * 100))
		table.insert(self.tireTracksValues, i)
	end
	self.maxMirrorsTexts = {}
	for i = 0, 7 do
		table.insert(self.maxMirrorsTexts, string.format("%d", i))
	end
	self.resolutionTexts = {}
	local numR = getNumOfScreenModes()
	for i = 0, numR - 1 do
		local x, y = getScreenModeInfo(i)
		local aspect = x / y
		local aspectStr = nil
		if aspect == 1.25 then
			aspectStr = "(5:4)"
		elseif 1.3 < aspect then
			if aspect < 1.4 then
				aspectStr = "(4:3)"
			elseif 1.7 < aspect then
				if aspect < 1.8 then
					aspectStr = "(16:9)"
				elseif 2.3 < aspect then
					aspectStr = aspect < 2.4 and "(21:9)" or string.format("(%1.0f:10)", aspect * 10)
				end
			end
		end
		table.insert(self.resolutionTexts, string.format("%dx%d %s", x, y, aspectStr))
	end
	self.fullscreenModeTexts = {}
	for i = 0, FullscreenMode.NUM - 1 do
		if i == FullscreenMode.WINDOWED then
			table.insert(self.fullscreenModeTexts, g_i18n:getText("ui_windowed"))
		elseif i == FullscreenMode.WINDOWED_FULLSCREEN then
			table.insert(self.fullscreenModeTexts, g_i18n:getText("ui_windowed_fullscreen"))
		else
			table.insert(self.fullscreenModeTexts, g_i18n:getText("ui_exclusive_fullscreen"))
		end
	end
	self.mpLanguageTexts = {}
	local numL = getNumOfLanguages()
	for i = 0, numL - 1 do
		table.insert(self.mpLanguageTexts, getLanguageName(i))
	end
	self.frameLimitMapping = {}
	self.frameLimitMappingReverse = {}
	self.frameLimitTexts = {}
	for _, value in ipairs(g_gameSettings.frameLimitValues) do
		table.insert(self.frameLimitTexts, tostring(value))
		self.frameLimitMapping[value] = #self.frameLimitTexts
		self.frameLimitMappingReverse[#self.frameLimitTexts] = value
	end
	self.inputHelpModeTexts = { g_i18n:getText("ui_auto"), g_i18n:getText("ui_keyboard"), g_i18n:getText("ui_gamepad") }
	self.directionChangeModeTexts = { [VehicleMotor.DIRECTION_CHANGE_MODE_AUTOMATIC] = g_i18n:getText("ui_directionChangeModeAutomatic"), [VehicleMotor.DIRECTION_CHANGE_MODE_MANUAL] = g_i18n:getText("ui_directionChangeModeManual") }
	self.gearShiftModeTexts = { [VehicleMotor.SHIFT_MODE_AUTOMATIC] = g_i18n:getText("ui_gearShiftModeAutomatic"), [VehicleMotor.SHIFT_MODE_MANUAL] = g_i18n:getText("ui_gearShiftModeManual") }
	if not Platform.isConsole then
		self.gearShiftModeTexts[VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH] = g_i18n:getText("ui_gearShiftModeManualClutch")
	end
	self.hudSpeedGaugeTexts = { [SpeedMeterDisplay.GAUGE_MODE_RPM] = g_i18n:getText("ui_hudSpeedGaugeRPM"), [SpeedMeterDisplay.GAUGE_MODE_SPEED] = g_i18n:getText("ui_hudSpeedGaugeSpeed") }
	self.deadzoneValues = {}
	self.deadzoneTexts = {}
	self.deadzoneStep = 0.01
	for i = 0, 0.301, self.deadzoneStep do
		table.insert(self.deadzoneTexts, string.format("%d%%", math.floor(i * 100 + 0.001)))
		table.insert(self.deadzoneValues, i)
	end
	self.sensitivityValues = {}
	self.sensitivityTexts = {}
	self.sensitivityStep = 0.25
	for i = 0.5, 2, self.sensitivityStep do
		table.insert(self.sensitivityTexts, string.format("%d%%", i * 100))
		table.insert(self.sensitivityValues, i)
	end
	self.headTrackingSensitivityValues = {}
	self.headTrackingSensitivityTexts = {}
	self.headTrackingSensitivityStep = 0.05
	for i = 0, 1.001, self.headTrackingSensitivityStep do
		table.insert(self.headTrackingSensitivityTexts, string.format("%d%%", i * 100 + 0.001))
		table.insert(self.headTrackingSensitivityValues, i)
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
function SettingsModel:getDeviceHasAxisDeadzone(axisIndex)
	local settings = self.deviceSettings[self.currentDevice]
	return settings ~= nil and settings.deadzones[axisIndex] ~= nil
end
function SettingsModel:getDeviceHasAxisSensitivity(axisIndex)
	local settings = self.deviceSettings[self.currentDevice]
	return settings ~= nil and settings.sensitivities[axisIndex] ~= nil
end
function SettingsModel:getNumDevices()
	return #self.deviceSettings
end
function SettingsModel:nextDevice()
	self.currentDevice = self.currentDevice + 1
	if #self.deviceSettings < self.currentDevice then
		self.currentDevice = 1
	end
end
function SettingsModel:getCurrentDeviceName()
	local setting = self.deviceSettings[self.currentDevice]
	if setting ~= nil then
		return setting.device.deviceName
	else
		return ""
	end
end
function SettingsModel:initDeviceSettings()
	self.deviceSettings = {}
	self.currentDevice = 0
	for _, device in pairs(g_inputBinding.devicesByInternalId) do
		local deadzones = {}
		local sensitivities = {}
		local mouseSensitivity = {}
		local headTrackingSensitivity = {}
		table.insert(self.deviceSettings, { device = device, deadzones = deadzones, sensitivities = sensitivities, mouseSensitivity = mouseSensitivity, headTrackingSensitivity = headTrackingSensitivity })
		for axisIndex = 0, Input.MAX_NUM_AXES - 1 do
			if getHasGamepadAxis(axisIndex, device.internalId) then
				local deadzone = device:getDeadzone(axisIndex)
				local deadzoneValue = Utils.getValueIndex(deadzone, self.deadzoneValues)
				deadzones[axisIndex] = { current = deadzoneValue, saved = deadzoneValue }
				local sensitivity = device:getSensitivity(axisIndex)
				local sensitivityValue = Utils.getValueIndex(sensitivity, self.sensitivityValues)
				sensitivities[axisIndex] = { current = sensitivityValue, saved = sensitivityValue }
			end
		end
		if device.category == InputDevice.CATEGORY.KEYBOARD_MOUSE then
			local scale, _ = g_inputBinding:getMouseMotionScale()
			local value = Utils.getValueIndex(scale, self.sensitivityValues)
			mouseSensitivity.current = value
			mouseSensitivity.saved = value
		end
		local value = Utils.getValueIndex(getCameraTrackingSensitivity(), self.headTrackingSensitivityValues)
		headTrackingSensitivity.current = value
		headTrackingSensitivity.saved = value
		self.currentDevice = 1
	end
end
function SettingsModel:hasDeviceChanges()
	for _, settings in ipairs(self.deviceSettings) do
		for axisIndex, _ in pairs(settings.deadzones) do
			local deadzone = settings.deadzones[axisIndex]
			if deadzone.current ~= deadzone.saved then
				return true
			end
			local sensitivity = settings.sensitivities[axisIndex]
			if sensitivity.current == sensitivity.saved then
				continue
			end
			return true
		end
		if settings.device.category == InputDevice.CATEGORY.KEYBOARD_MOUSE then
			local mouseSensitivity = settings.mouseSensitivity
			if mouseSensitivity.current ~= mouseSensitivity.saved then
				return true
			end
		end
		local headTrackingSensitivity = settings.headTrackingSensitivity
		if headTrackingSensitivity.current == headTrackingSensitivity.saved then
			continue
		end
		return true
	end
	return false
end
function SettingsModel:saveDeviceChanges()
	local changedSettings = false
	for _, settings in ipairs(self.deviceSettings) do
		local device = settings.device
		for axisIndex, _ in pairs(settings.deadzones) do
			local deadzones = settings.deadzones[axisIndex]
			local deadzone = self.deadzoneValues[deadzones.current]
			deadzones.saved = deadzones.current
			device:setDeadzone(axisIndex, deadzone)
			local sensitivities = settings.sensitivities[axisIndex]
			local sensitivity = self.sensitivityValues[sensitivities.current]
			sensitivities.saved = sensitivities.current
			device:setSensitivity(axisIndex, sensitivity)
			changedSettings = true
		end
		if settings.device.category == InputDevice.CATEGORY.KEYBOARD_MOUSE then
			local mouseSensitivity = settings.mouseSensitivity
			if mouseSensitivity.current ~= mouseSensitivity.saved then
				g_inputBinding:setMouseMotionScale(self.sensitivityValues[mouseSensitivity.current])
				mouseSensitivity.saved = mouseSensitivity.current
				changedSettings = true
			end
			local headTrackingSensitivity = settings.headTrackingSensitivity
			if headTrackingSensitivity.current == headTrackingSensitivity.saved then
				continue
			end
			setCameraTrackingSensitivity(self.headTrackingSensitivityValues[headTrackingSensitivity.current])
			headTrackingSensitivity.saved = headTrackingSensitivity.current
			changedSettings = true
		end
	end
	if changedSettings then
		g_inputBinding:applyGamepadDeadzones()
		g_inputBinding:saveToXMLFile()
	end
end
function SettingsModel:resetDeviceChanges()
	for _, settings in ipairs(self.deviceSettings) do
		for axisIndex, _ in pairs(settings.deadzones) do
			local deadzone = settings.deadzones[axisIndex]
			deadzone.current = deadzone.saved
			local sensitivity = settings.sensitivities[axisIndex]
			sensitivity.current = sensitivity.saved
		end
		settings.mouseSensitivity.current = settings.mouseSensitivity.saved
		settings.headTrackingSensitivity.current = settings.headTrackingSensitivity.saved
	end
end
function SettingsModel:setDeviceDeadzoneValue(axisIndex, value)
	local settings = self.deviceSettings[self.currentDevice]
	if settings ~= nil then
		settings.deadzones[axisIndex].current = value
	end
end
function SettingsModel:getCurrentDeviceDeadzoneValue(axisIndex)
	local settings = self.deviceSettings[self.currentDevice]
	if settings ~= nil then
		return self.deadzoneValues[settings.deadzones[axisIndex].current]
	else
		return nil
	end
end
function SettingsModel:setDeviceSensitivityValue(axisIndex, value)
	local settings = self.deviceSettings[self.currentDevice]
	if settings ~= nil then
		settings.sensitivities[axisIndex].current = value
	end
end
function SettingsModel:getCurrentDeviceSensitivityValue(axisIndex)
	local settings = self.deviceSettings[self.currentDevice]
	if settings ~= nil then
		return self.sensitivityValues[settings.sensitivities[axisIndex].current]
	else
		return nil
	end
end
function SettingsModel:setMouseSensitivity(value)
	local settings = self.deviceSettings[self.currentDevice]
	if settings ~= nil then
		settings.mouseSensitivity.current = value
	end
end
function SettingsModel:setHeadTrackingSensitivity(value)
	local settings = self.deviceSettings[self.currentDevice]
	if settings ~= nil then
		settings.headTrackingSensitivity.current = value
	end
end
function SettingsModel:getDeviceAxisDeadzoneValue(axisIndex)
	local settings = self.deviceSettings[self.currentDevice]
	return settings.deadzones[axisIndex].current
end
function SettingsModel:getDeviceAxisSensitivityValue(axisIndex)
	local settings = self.deviceSettings[self.currentDevice]
	return settings.sensitivities[axisIndex].current
end
function SettingsModel:getMouseSensitivityValue(axisIndex)
	local settings = self.deviceSettings[self.currentDevice]
	return settings.mouseSensitivity.current
end
function SettingsModel:getHeadTrackingSensitivityValue(axisIndex)
	local settings = self.deviceSettings[self.currentDevice]
	return settings.headTrackingSensitivity.current
end
function SettingsModel:getIsDeviceMouse()
	local settings = self.deviceSettings[self.currentDevice]
	return settings ~= nil and settings.device.category == InputDevice.CATEGORY.KEYBOARD_MOUSE
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
	local _v4 = true
	if not (#g_availableLanguagesTable <= 1) then
		_v4 = GS_IS_STEAM_VERSION
	end
	return _v4
end
function SettingsModel:getPerformanceClassTexts()
	local class, isCustom = getPerformanceClass()
	local _, isAuto = getAutoPerformanceClass()
	local texts = {}
	table.insert(texts, g_i18n:getText("setting_veryLow"))
	table.insert(texts, g_i18n:getText("setting_low"))
	table.insert(texts, g_i18n:getText("setting_medium"))
	table.insert(texts, g_i18n:getText("setting_high"))
	table.insert(texts, g_i18n:getText("setting_veryHigh"))
	table.insert(texts, g_i18n:getText("setting_ultra"))
	if not GS_IS_MOBILE_VERSION then
		local index = Utils.getPerformanceClassIndex(class)
		if isCustom then
			texts[index] = g_i18n:getText("setting_custom")
		elseif isAuto then
			texts[index] = g_i18n:getText("setting_auto")
		end
	end
	return texts, class, isCustom
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
	return function(gameSettingsKey)
		return g_gameSettings:getValue(gameSettingsKey)
	end
end
function SettingsModel:makeDefaultWriterFunction()
	return function(value, gameSettingsKey)
		g_gameSettings:setValue(gameSettingsKey, value)
	end
end
function SettingsModel:addDirectSetting(gameSettingsKey, restartRequired)
	self:addSetting(gameSettingsKey, self.defaultReaderFunction, self.defaultWriterFunction, restartRequired)
end
function SettingsModel:addPerformanceClassSetting()
	local readValue = function()
		local perfomanceClassName, _isCustom = getPerformanceClass()
		return Utils.getPerformanceClassIndex(perfomanceClassName)
	end
	local writeValue = function(value)
		local class = Utils.getPerformanceClassFromIndex(value)
		setPerformanceClass(class)
		if g_terrainNode ~= nil then
			local foliageViewCoeff = getFoliageViewDistanceCoeff()
			local lodBlendStart, lodBlendEnd = getTerrainLodBlendDynamicDistances(g_terrainNode)
			setTerrainLodBlendDynamicDistances(g_terrainNode, lodBlendStart * foliageViewCoeff, lodBlendEnd * foliageViewCoeff)
		end
		local settings = GameSettings.PERFORMANCE_CLASS_PRESETS[Utils.getPerformanceClassId()]
		g_gameSettings:setValue(SettingsModel.SETTING.LIGHTS_PROFILE, settings[SettingsModel.SETTING.LIGHTS_PROFILE])
		g_gameSettings:setValue(SettingsModel.SETTING.MAX_MIRRORS, settings[SettingsModel.SETTING.MAX_MIRRORS])
		g_gameSettings:setValue(SettingsModel.SETTING.REAL_BEACON_LIGHTS, settings[SettingsModel.SETTING.REAL_BEACON_LIGHTS])
	end
	self:addSetting(SettingsModel.SETTING.PERFORMANCE_CLASS, readValue, writeValue)
end
function SettingsModel:addPerformanceModeSetting()
	local readValue = function()
		local isActive = getIsPerformanceModeActive()
		return isActive
	end
	local writeValue = function(value)
		setIsPerformanceModeActive(value)
	end
	self:addSetting(SettingsModel.SETTING.PERFORMANCE_MODE, readValue, writeValue)
end
function SettingsModel:addHDRPeakBrightnessSetting()
	local readValue = function()
		return Utils.getValueIndex(getBrightnessNits(), self.hdrPeakBrightnessValues)
	end
	local writeValue = function(value)
		local nits = self.hdrPeakBrightnessValues[value]
		setBrightnessNits(nits)
	end
	self:addSetting(SettingsModel.SETTING.HDR_PEAK_BRIGHTNESS, readValue, writeValue)
end
function SettingsModel:addHDRContrastSetting()
	local readValue = function()
		local hdrGamma = getHDRGamma()
		local state = Utils.getValueIndex(hdrGamma, self.hdrContrastValues)
		return state
	end
	local writeValue = function(value)
		local contrasts = self.hdrContrastValues[value]
		setHDRGamma(contrasts)
	end
	self:addSetting(SettingsModel.SETTING.HDR_CONTRAST, readValue, writeValue)
end
function SettingsModel:addOverlayBrightnessSetting()
	local readValue = function()
		return Utils.getValueIndex(getOverlayBrightnessNits(), self.overlayBrightnessValues)
	end
	local writeValue = function(value)
		local nits = self.overlayBrightnessValues[value]
		setOverlayBrightnessNits(nits)
	end
	self:addSetting(SettingsModel.SETTING.OVERLAY_BRIGHTNESS, readValue, writeValue)
end
function SettingsModel:addHDREnabledSetting()
	local readValue = function()
		return getScreenHdrOutput() or false
	end
	local writeValue = function(value)
		setScreenHdrOutput(value)
	end
	self:addSetting(SettingsModel.SETTING.HDR_ENABLED, readValue, writeValue)
end
function SettingsModel:addFidelityFxSR30FrameGenerationSetting()
	local readValue = function()
		return getFidelityFxSR30FrameInterpolation()
	end
	local writeValue = function(value)
		setFidelityFxSR30FrameInterpolation(value)
	end
	self:addSetting(SettingsModel.SETTING.FIDELITYFX_SR_30_FRAME_GENERATION, readValue, writeValue)
end
function SettingsModel:addXeSSFrameGenerationSetting()
	local readValue = function()
		return getXeSSFrameInterpolation()
	end
	local writeValue = function(value)
		setXeSSFrameInterpolation(value)
	end
	self:addSetting(SettingsModel.SETTING.XESS_FRAME_GENERATION, readValue, writeValue)
end
function SettingsModel:addDLSSFrameGenerationSetting()
	local readValue = function()
		return getDLSSFrameInterpolation()
	end
	local writeValue = function(value)
		setDLSSFrameInterpolation(value)
	end
	self:addSetting(SettingsModel.SETTING.DLSS_FRAME_GENERATION, readValue, writeValue)
end
function SettingsModel:addDRSTargetFPSSetting()
	local readValue = function()
		return self.drsTargetFPSMapping[getDRSTargetFPS()]
	end
	local writeValue = function(value)
		local newValue = self.drsTargetFPSMappingReverse[value]
		if getDRSTargetFPS() ~= newValue then
			setDRSTargetFPS(newValue)
		end
	end
	self:addSetting(SettingsModel.SETTING.DRS_TARGET_FPS, readValue, writeValue)
end
function SettingsModel:addSharpnessSetting()
	local readSharpness = function()
		local sharpness = getSharpness()
		sharpness = math.clamp(sharpness, self.minSharpness, self.maxSharpness)
		local index = MathUtil.round((sharpness - self.minSharpness) / self.sharpnessStep + 1)
		return index
	end
	local writeSharpness = function(index)
		local value = self.minSharpness + self.sharpnessStep * (index - 1)
		setSharpness(value)
	end
	self:addSetting(SettingsModel.SETTING.SHARPNESS, readSharpness, writeSharpness)
end
function SettingsModel:addShadingRateQualitySetting()
	local readValue = function()
		return getShadingRateQuality() + 1
	end
	local writeValue = function(value)
		setShadingRateQuality(math.max(value - 1, 0))
	end
	self:addSetting(SettingsModel.SETTING.SHADING_RATE_QUALITY, readValue, writeValue)
end
function SettingsModel:addSSAOQualitySetting()
	local readValue = function()
		local index = getSSAOQuality()
		return index
	end
	local writeValue = function(value)
		setSSAOQuality(value)
	end
	self:addSetting(SettingsModel.SETTING.SSAO_QUALITY, readValue, writeValue)
end
function SettingsModel:addCloudShadowsQualitySetting()
	local readValue = function()
		return getCloudShadowsQuality() == 1
	end
	local writeValue = function(value)
		setCloudShadowsQuality(value and 1 or 0)
	end
	self:addSetting(SettingsModel.SETTING.CLOUD_SHADOWS_QUALITY, readValue, writeValue)
end
function SettingsModel:addTextureResolutionSetting()
	local readValue = function()
		return SettingsModel.getTextureResolutionIndex(getTextureResolution())
	end
	local writeValue = function(value)
		setTextureResolution(SettingsModel.getTextureResolutionByIndex(value))
	end
	self:addSetting(SettingsModel.SETTING.TEXTURE_RESOLUTION, readValue, writeValue)
end
function SettingsModel:addShadowQualitySetting()
	local readValue = function()
		return SettingsModel.getShadowQualityIndex(getShadowQuality(), getHasShadowFocusBox())
	end
	local writeValue = function(value)
		setShadowQuality(SettingsModel.getShadowQualityByIndex(value), SettingsModel.getHasShadowFocusBoxByIndex(value))
	end
	self:addSetting(SettingsModel.SETTING.SHADOW_QUALITY, readValue, writeValue)
end
function SettingsModel:addShadowDistanceQualitySetting()
	local readValue = function()
		return getShadowDistanceQuality() + 1
	end
	local writeValue = function(value)
		setShadowDistanceQuality(math.max(value - 1, 0))
	end
	self:addSetting(SettingsModel.SETTING.SHADOW_DISTANCE_QUALITY, readValue, writeValue)
end
function SettingsModel:addSoftShadowsSetting()
	local readValue = function()
		return getShadowFilterQuality() + 1
	end
	local writeValue = function(value)
		setShadowFilterQuality(math.max(value - 1, 0))
	end
	self:addSetting(SettingsModel.SETTING.SOFT_SHADOWS, readValue, writeValue)
end
function SettingsModel:addShaderQualitySetting()
	local readValue = function()
		return SettingsModel.getShaderQualityIndex(getShaderQuality())
	end
	local writeValue = function(value)
		setShaderQuality(SettingsModel.getShaderQualityByIndex(value))
	end
	self:addSetting(SettingsModel.SETTING.SHADER_QUALITY, readValue, writeValue)
end
function SettingsModel:addShadowMapFilteringSetting()
	local readValue = function()
		return SettingsModel.getShadowMapFilterIndex(getShadowMapFilterSize())
	end
	local writeValue = function(value)
		setShadowMapFilterSize(SettingsModel.getShadowMapFilterByIndex(value))
	end
	self:addSetting(SettingsModel.SETTING.SHADOW_MAP_FILTERING, readValue, writeValue)
end
function SettingsModel:addShadowMaxLightsSetting()
	local readValue = function()
		return getMaxNumShadowLights()
	end
	local writeValue = function(value)
		setMaxNumShadowLights(value)
	end
	self:addSetting(SettingsModel.SETTING.MAX_LIGHTS, readValue, writeValue)
end
function SettingsModel:addTerrainQualitySetting()
	local readValue = function()
		return SettingsModel.getTerrainQualityIndex(getTerrainQuality())
	end
	local writeValue = function(value)
		setTerrainQuality(SettingsModel.getTerrainQualityByIndex(value))
	end
	self:addSetting(SettingsModel.SETTING.TERRAIN_QUALITY, readValue, writeValue)
end
function SettingsModel:addObjectDrawDistanceSetting()
	local readValue = function()
		return Utils.getValueIndex(getViewDistanceCoeff(), self.percentValues)
	end
	local writeValue = function(value)
		setViewDistanceCoeff(self.percentValues[value])
	end
	self:addSetting(SettingsModel.SETTING.OBJECT_DRAW_DISTANCE, readValue, writeValue)
end
function SettingsModel:addFoliageDrawDistanceSetting()
	local readValue = function()
		return Utils.getValueIndex(getFoliageViewDistanceCoeff(), self.percentValues)
	end
	local writeValue = function(value)
		setFoliageViewDistanceCoeff(self.percentValues[value])
	end
	self:addSetting(SettingsModel.SETTING.FOLIAGE_DRAW_DISTANCE, readValue, writeValue)
end
function SettingsModel:addFoliageShadowSetting()
	local readValue = function()
		return getAllowFoliageShadows()
	end
	local writeValue = function(value)
		setAllowFoliageShadows(value)
	end
	self:addSetting(SettingsModel.SETTING.FOLIAGE_SHADOW, readValue, writeValue)
end
function SettingsModel:addLODDistanceSetting()
	local readValue = function()
		return Utils.getValueIndex(getLODDistanceCoeff(), self.percentValues)
	end
	local writeValue = function(value)
		setLODDistanceCoeff(self.percentValues[value])
	end
	self:addSetting(SettingsModel.SETTING.LOD_DISTANCE, readValue, writeValue)
end
function SettingsModel:addTerrainLODDistanceSetting()
	local readValue = function()
		return Utils.getValueIndex(getTerrainLODDistanceCoeff(), self.percentValues)
	end
	local writeValue = function(value)
		setTerrainLODDistanceCoeff(self.percentValues[value])
	end
	self:addSetting(SettingsModel.SETTING.TERRAIN_LOD_DISTANCE, readValue, writeValue)
end
function SettingsModel:addFoliageLODDistanceSetting()
	local readValue = function()
		return Utils.getValueIndex(getFoliageLODDistanceCoeff(), self.percentValues)
	end
	local writeValue = function(value)
		setFoliageLODDistanceCoeff(self.percentValues[value])
	end
	self:addSetting(SettingsModel.SETTING.FOLIAGE_LOD_DISTANCE, readValue, writeValue)
end
function SettingsModel:addVolumeMeshTessellationSetting()
	local readValue = function()
		return Utils.getValueIndex(SettingsModel.getVolumeMeshTessellationCoeff(), self.percentValues)
	end
	local writeValue = function(value)
		SettingsModel.setVolumeMeshTessellationCoeff(self.percentValues[value])
	end
	self:addSetting(SettingsModel.SETTING.VOLUME_MESH_TESSELLATION, readValue, writeValue)
end
function SettingsModel:addMaxTireTracksSetting()
	local readValue = function()
		return Utils.getValueIndex(getTyreTracksSegmentsCoeff(), self.tireTracksValues)
	end
	local writeValue = function(value)
		setTyreTracksSegmentsCoeff(self.tireTracksValues[value])
	end
	self:addSetting(SettingsModel.SETTING.MAX_TIRE_TRACKS, readValue, writeValue)
end
function SettingsModel:addLightsProfileSetting()
	local readValue = function()
		return g_gameSettings:getValue(SettingsModel.SETTING.LIGHTS_PROFILE)
	end
	local writeValue = function(value)
		g_gameSettings:setValue(SettingsModel.SETTING.LIGHTS_PROFILE, value)
	end
	self:addSetting(SettingsModel.SETTING.LIGHTS_PROFILE, readValue, writeValue)
end
function SettingsModel:addRealBeaconLightsSetting()
	local readValue = function()
		return g_gameSettings:getValue(SettingsModel.SETTING.REAL_BEACON_LIGHTS)
	end
	local writeValue = function(value)
		g_gameSettings:setValue(SettingsModel.SETTING.REAL_BEACON_LIGHTS, value)
	end
	self:addSetting(SettingsModel.SETTING.REAL_BEACON_LIGHTS, readValue, writeValue)
end
function SettingsModel:addMaxMirrorsSetting()
	local readValue = function()
		return SettingsModel.getNumOfReflectionMapsIndex(g_gameSettings:getValue(SettingsModel.SETTING.MAX_MIRRORS))
	end
	local writeValue = function(value)
		g_gameSettings:setValue(SettingsModel.SETTING.MAX_MIRRORS, SettingsModel.getNumOfReflectionMapsByIndex(value))
	end
	self:addSetting(SettingsModel.SETTING.MAX_MIRRORS, readValue, writeValue)
end
function SettingsModel:addLanguageSetting()
	local readLanguage = function()
		return g_settingsLanguageGUI + 1
	end
	local writeLanguage = function(value)
		g_settingsLanguageGUI = value - 1
		setLanguage(g_availableLanguagesTable[value])
	end
	self:addSetting(SettingsModel.SETTING.LANGUAGE, readLanguage, writeLanguage, true)
end
function SettingsModel:addMPLanguageSetting()
	local readMPLanguage = function()
		return g_gameSettings:getValue(SettingsModel.SETTING.MP_LANGUAGE) + 1
	end
	local writeMPLanguage = function(value)
		g_gameSettings:setValue(SettingsModel.SETTING.MP_LANGUAGE, value - 1)
	end
	self:addSetting(SettingsModel.SETTING.MP_LANGUAGE, readMPLanguage, writeMPLanguage)
end
function SettingsModel:addInputHelpModeSetting()
	local readValue = function()
		return g_gameSettings:getValue(SettingsModel.SETTING.INPUT_HELP_MODE)
	end
	local writeValue = function(value)
		g_gameSettings:setValue(SettingsModel.SETTING.INPUT_HELP_MODE, value)
	end
	self:addSetting(SettingsModel.SETTING.INPUT_HELP_MODE, readValue, writeValue)
end
function SettingsModel:addFrameLimitSetting()
	local readValue = function()
		return self.frameLimitMapping[g_gameSettings:getValue(SettingsModel.SETTING.FRAME_LIMIT)]
	end
	local writeValue = function(value)
		local frameLimit = self.frameLimitMappingReverse[value]
		g_gameSettings:setValue(SettingsModel.SETTING.FRAME_LIMIT, frameLimit)
		if Platform.hasAdjustableFrameLimit and g_currentMission ~= nil then
			setFramerateLimiter(true, frameLimit)
		end
	end
	self:addSetting(SettingsModel.SETTING.FRAME_LIMIT, readValue, writeValue)
end
function SettingsModel:addBrightnessSetting()
	local readBrightness = function()
		local brightness = getBrightness()
		brightness = math.clamp(brightness, self.minBrightness, self.maxBrightness)
		local index = MathUtil.round((brightness - self.minBrightness) / self.brightnessStep + 1)
		return index
	end
	local writeBrightness = function(index)
		local value = self.minBrightness + self.brightnessStep * (index - 1)
		setBrightness(math.clamp(value, self.minBrightness, self.maxBrightness))
	end
	self:addSetting(SettingsModel.SETTING.BRIGHTNESS, readBrightness, writeBrightness)
end
function SettingsModel:addVSyncSetting()
	local readVSync = function()
		return getVsync()
	end
	local writeVSync = function(value)
		setVsync(value)
	end
	self:addSetting(SettingsModel.SETTING.V_SYNC, readVSync, writeVSync)
end
function SettingsModel:addFovYSetting()
	local readFovY = function()
		local fovY = math.deg(g_gameSettings:getValue(SettingsModel.SETTING.FOV_Y))
		return self.fovYToIndexMapping[math.min(math.max(math.floor(fovY + 0.5), math.deg(Platform.minFovY)), math.deg(Platform.maxFovY))]
	end
	local writeFovY = function(value)
		g_gameSettings:setValue(SettingsModel.SETTING.FOV_Y, math.rad(self.indexToFovYMapping[value]))
	end
	self:addSetting(SettingsModel.SETTING.FOV_Y, readFovY, writeFovY)
end
function SettingsModel:addFovYPlayerFirstPersonSetting()
	local readFovY = function()
		local fovY = math.deg(g_gameSettings:getValue(SettingsModel.SETTING.FOV_Y_PLAYER_FIRST_PERSON))
		return self.fovYToIndexMapping[math.min(math.max(math.floor(fovY + 0.5), math.deg(Platform.minFovY)), math.deg(Platform.maxFovY))]
	end
	local writeFovY = function(value)
		g_gameSettings:setValue(SettingsModel.SETTING.FOV_Y_PLAYER_FIRST_PERSON, math.rad(self.indexToFovYMapping[value]))
	end
	self:addSetting(SettingsModel.SETTING.FOV_Y_PLAYER_FIRST_PERSON, readFovY, writeFovY)
end
function SettingsModel:addFovYPlayerThirdPersonSetting()
	local readFovY = function()
		local fovY = math.deg(g_gameSettings:getValue(SettingsModel.SETTING.FOV_Y_PLAYER_THIRD_PERSON))
		return self.fovYToIndexMapping[math.min(math.max(math.floor(fovY + 0.5), math.deg(Platform.minFovY)), math.deg(Platform.maxFovY))]
	end
	local writeFovY = function(value)
		g_gameSettings:setValue(SettingsModel.SETTING.FOV_Y_PLAYER_THIRD_PERSON, math.rad(self.indexToFovYMapping[value]))
	end
	self:addSetting(SettingsModel.SETTING.FOV_Y_PLAYER_THIRD_PERSON, readFovY, writeFovY)
end
function SettingsModel:addUIScaleSetting()
	local readUIScale = function()
		return Utils.getUIScaleIndex(g_gameSettings:getValue(SettingsModel.SETTING.UI_SCALE))
	end
	local writeUIScale = function(value)
		g_gameSettings:setValue(SettingsModel.SETTING.UI_SCALE, Utils.getUIScaleFromIndex(value))
	end
	self:addSetting(SettingsModel.SETTING.UI_SCALE, readUIScale, writeUIScale)
end
function SettingsModel:addResolutionScaleSetting()
	local readResolutionScale = function()
		return SettingsModel.getScalingStateFromResolutionScaling(getResolutionScaling())
	end
	local writeResolutionScale = function(value)
		setResolutionScaling(SettingsModel.getScalingFromResolutionScalingState(value))
	end
	self:addSetting(SettingsModel.SETTING.RESOLUTION_SCALE, readResolutionScale, writeResolutionScale)
end
function SettingsModel:addResolutionScale3dSetting()
	local readResolutionScale3d = function()
		return SettingsModel.getScalingStateFromResolutionScaling(get3dResolutionScaling())
	end
	local writeResolutionScale3d = function(value)
		set3dResolutionScaling(SettingsModel.getScalingFromResolutionScalingState(value))
	end
	self:addSetting(SettingsModel.SETTING.RESOLUTION_SCALE_3D, readResolutionScale3d, writeResolutionScale3d)
end
function SettingsModel:addCameraSensitivitySetting()
	local readSensitivity = function()
		return Utils.getStateFromValues(self.cameraSensitivityValues, self.cameraSensitivityStep, g_gameSettings:getValue(SettingsModel.SETTING.CAMERA_SENSITIVITY))
	end
	local writeSensitivity = function(value)
		g_gameSettings:setValue(SettingsModel.SETTING.CAMERA_SENSITIVITY, self.cameraSensitivityValues[value])
	end
	self:addSetting(SettingsModel.SETTING.CAMERA_SENSITIVITY, readSensitivity, writeSensitivity)
end
function SettingsModel:addVehicleArmSensitivitySetting()
	local readSensitivity = function()
		return Utils.getStateFromValues(self.vehicleArmSensitivityValues, self.vehicleArmSensitivityStep, g_gameSettings:getValue(SettingsModel.SETTING.VEHICLE_ARM_SENSITIVITY))
	end
	local writeSensitivity = function(value)
		g_gameSettings:setValue(SettingsModel.SETTING.VEHICLE_ARM_SENSITIVITY, self.vehicleArmSensitivityValues[value])
	end
	self:addSetting(SettingsModel.SETTING.VEHICLE_ARM_SENSITIVITY, readSensitivity, writeSensitivity)
end
function SettingsModel:addRealBeaconLightBrightnessSetting()
	local readBrightness = function()
		return Utils.getStateFromValues(self.realBeaconLightBrightnessValues, self.realBeaconLightBrightnessStep, g_gameSettings:getValue(SettingsModel.SETTING.REAL_BEACON_LIGHT_BRIGHTNESS))
	end
	local writeBrightness = function(value)
		g_gameSettings:setValue(SettingsModel.SETTING.REAL_BEACON_LIGHT_BRIGHTNESS, self.realBeaconLightBrightnessValues[value])
	end
	self:addSetting(SettingsModel.SETTING.REAL_BEACON_LIGHT_BRIGHTNESS, readBrightness, writeBrightness)
end
function SettingsModel:addActiveCameraSuspensionSetting()
	local writeSetting = function(value)
		g_gameSettings:setValue(SettingsModel.SETTING.ACTIVE_SUSPENSION_CAMERA, value)
		g_messageCenter:publish(MessageType.SETTING_CHANGED[GameSettings.SETTING.ACTIVE_SUSPENSION_CAMERA], value)
	end
	self:addSetting(SettingsModel.SETTING.ACTIVE_SUSPENSION_CAMERA, self.defaultReaderFunction, writeSetting)
end
function SettingsModel:addCamerCheckCollisionSetting()
	local writeSetting = function(value)
		g_gameSettings:setValue(SettingsModel.SETTING.CAMERA_CHECK_COLLISION, value)
		g_messageCenter:publish(MessageType.SETTING_CHANGED[GameSettings.SETTING.CAMERA_CHECK_COLLISION], value)
	end
	self:addSetting(SettingsModel.SETTING.CAMERA_CHECK_COLLISION, self.defaultReaderFunction, writeSetting)
end
function SettingsModel:addDirectionChangeModeSetting()
	local writeSetting = function(value)
		g_gameSettings:setValue(SettingsModel.SETTING.DIRECTION_CHANGE_MODE, value)
		g_messageCenter:publish(MessageType.SETTING_CHANGED[GameSettings.SETTING.DIRECTION_CHANGE_MODE], value)
	end
	self:addSetting(SettingsModel.SETTING.DIRECTION_CHANGE_MODE, self.defaultReaderFunction, writeSetting)
end
function SettingsModel:addGearShiftModeSetting()
	local writeSetting = function(value)
		g_gameSettings:setValue(SettingsModel.SETTING.GEAR_SHIFT_MODE, value)
		g_messageCenter:publish(MessageType.SETTING_CHANGED[GameSettings.SETTING.GEAR_SHIFT_MODE], value)
	end
	self:addSetting(SettingsModel.SETTING.GEAR_SHIFT_MODE, self.defaultReaderFunction, writeSetting)
end
function SettingsModel:addHudSpeedGaugeSetting()
	local writeSetting = function(value)
		g_gameSettings:setValue(SettingsModel.SETTING.HUD_SPEED_GAUGE, value)
		g_messageCenter:publish(MessageType.SETTING_CHANGED[GameSettings.SETTING.HUD_SPEED_GAUGE], value)
	end
	self:addSetting(SettingsModel.SETTING.HUD_SPEED_GAUGE, self.defaultReaderFunction, writeSetting)
end
function SettingsModel:addWoodHarvesterAutoCutSetting()
	local writeSetting = function(value)
		g_gameSettings:setValue(SettingsModel.SETTING.WOOD_HARVESTER_AUTO_CUT, value)
		g_messageCenter:publish(MessageType.SETTING_CHANGED[GameSettings.SETTING.WOOD_HARVESTER_AUTO_CUT], value)
	end
	self:addSetting(SettingsModel.SETTING.WOOD_HARVESTER_AUTO_CUT, self.defaultReaderFunction, writeSetting)
end
function SettingsModel:addMasterVolumeSetting()
	local readVolume = function()
		return Utils.getMasterVolumeIndex(g_gameSettings:getValue(SettingsModel.SETTING.VOLUME_MASTER))
	end
	local writeVolume = function(value)
		local volume = Utils.getMasterVolumeFromIndex(value)
		g_soundMixer:setMasterVolume(volume)
		g_gameSettings:setValue(SettingsModel.SETTING.VOLUME_MASTER, volume)
	end
	self:addSetting(SettingsModel.SETTING.VOLUME_MASTER, readVolume, writeVolume)
end
function SettingsModel:addMusicVolumeSetting()
	local readVolume = function()
		return Utils.getMasterVolumeIndex(g_gameSettings:getValue(SettingsModel.SETTING.VOLUME_MUSIC))
	end
	local writeVolume = function(value)
		local volume = Utils.getMasterVolumeFromIndex(value)
		g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.MENU_MUSIC, volume)
		g_gameSettings:setValue(SettingsModel.SETTING.VOLUME_MUSIC, volume)
	end
	self:addSetting(SettingsModel.SETTING.VOLUME_MUSIC, readVolume, writeVolume)
end
function SettingsModel:addEnvironmentVolumeSetting()
	local readVolume = function()
		return Utils.getMasterVolumeIndex(g_gameSettings:getValue(SettingsModel.SETTING.VOLUME_ENVIRONMENT))
	end
	local writeVolume = function(value)
		local volume = Utils.getMasterVolumeFromIndex(value)
		g_gameSettings:setValue(SettingsModel.SETTING.VOLUME_ENVIRONMENT, volume)
		g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.ENVIRONMENT, volume)
	end
	self:addSetting(SettingsModel.SETTING.VOLUME_ENVIRONMENT, readVolume, writeVolume)
end
function SettingsModel:addVehicleVolumeSetting()
	local readVolume = function()
		return Utils.getMasterVolumeIndex(g_gameSettings:getValue(SettingsModel.SETTING.VOLUME_VEHICLE))
	end
	local writeVolume = function(value)
		local volume = Utils.getMasterVolumeFromIndex(value)
		g_gameSettings:setValue(SettingsModel.SETTING.VOLUME_VEHICLE, volume)
		g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.VEHICLE, volume)
	end
	self:addSetting(SettingsModel.SETTING.VOLUME_VEHICLE, readVolume, writeVolume)
end
function SettingsModel:addRadioVolumeSetting()
	local readVolume = function()
		return Utils.getMasterVolumeIndex(g_gameSettings:getValue(SettingsModel.SETTING.VOLUME_RADIO))
	end
	local writeVolume = function(value)
		local volume = Utils.getMasterVolumeFromIndex(value)
		g_gameSettings:setValue(SettingsModel.SETTING.VOLUME_RADIO, volume)
		g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.RADIO, volume)
	end
	self:addSetting(SettingsModel.SETTING.VOLUME_RADIO, readVolume, writeVolume)
end
function SettingsModel:addVoiceVolumeSetting()
	local readVolume = function()
		return Utils.getMasterVolumeIndex(VoiceChatUtil.getOutputVolume())
	end
	local writeVolume = function(value)
		local volume = Utils.getMasterVolumeFromIndex(value)
		g_gameSettings:setValue(SettingsModel.SETTING.VOLUME_VOICE, volume)
		VoiceChatUtil.setOutputVolume(volume)
	end
	self:addSetting(SettingsModel.SETTING.VOLUME_VOICE, readVolume, writeVolume)
end
function SettingsModel:addVoiceInputVolumeSetting()
	local readVolume = function()
		return Utils.getRecordingVolumeIndex(VoiceChatUtil.getInputVolume())
	end
	local writeVolume = function(value)
		local volume = Utils.getRecordingVolumeFromIndex(value)
		g_gameSettings:setValue(SettingsModel.SETTING.VOLUME_VOICE_INPUT, volume)
		VoiceChatUtil.setInputVolume(volume)
	end
	self:addSetting(SettingsModel.SETTING.VOLUME_VOICE_INPUT, readVolume, writeVolume)
end
function SettingsModel:addVoiceModeSetting()
	local readMode = function()
		return VoiceChatUtil.getInputMode()
	end
	local writeMode = function(value)
		g_gameSettings:setValue(SettingsModel.SETTING.VOICE_MODE, value)
		VoiceChatUtil.setInputMode(value)
	end
	self:addSetting(SettingsModel.SETTING.VOICE_MODE, readMode, writeMode)
end
function SettingsModel:addVoiceInputSensitivitySetting()
	local readMode = function()
		return g_gameSettings:getValue(SettingsModel.SETTING.VOICE_INPUT_SENSITIVITY)
	end
	local writeMode = function(value)
		g_gameSettings:setValue(SettingsModel.SETTING.VOICE_INPUT_SENSITIVITY, value)
		local threshold = -1
		if 1 < value then
			threshold = (value - 2) / 10
		end
		VoiceChatUtil.setInputSensitivity(threshold)
	end
	self:addSetting(SettingsModel.SETTING.VOICE_INPUT_SENSITIVITY, readMode, writeMode)
end
function SettingsModel:addVolumeGUISetting()
	local readVolume = function()
		return Utils.getMasterVolumeIndex(g_gameSettings:getValue(SettingsModel.SETTING.VOLUME_GUI))
	end
	local writeVolume = function(value)
		local volume = Utils.getMasterVolumeFromIndex(value)
		g_gameSettings:setValue(SettingsModel.SETTING.VOLUME_GUI, volume)
		g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.GUI, volume)
	end
	self:addSetting(SettingsModel.SETTING.VOLUME_GUI, readVolume, writeVolume)
end
function SettingsModel:addVolumeNoFocusSetting()
	local readVolume = function()
		return Utils.getMasterVolumeIndex(g_gameSettings:getValue(SettingsModel.SETTING.VOLUME_NO_FOCUS))
	end
	local writeVolume = function(value)
		local volume = Utils.getMasterVolumeFromIndex(value)
		g_gameSettings:setValue(SettingsModel.SETTING.VOLUME_NO_FOCUS, volume)
		setInactiveWindowAudioVolume(volume)
	end
	self:addSetting(SettingsModel.SETTING.VOLUME_NO_FOCUS, readVolume, writeVolume)
end
function SettingsModel:addVolumeCharacterSetting()
	local readVolume = function()
		return Utils.getMasterVolumeIndex(g_gameSettings:getValue(SettingsModel.SETTING.VOLUME_CHARACTER))
	end
	local writeVolume = function(value)
		local volume = Utils.getMasterVolumeFromIndex(value)
		g_gameSettings:setValue(SettingsModel.SETTING.VOLUME_CHARACTER, volume)
		g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.CHARACTER, volume)
	end
	self:addSetting(SettingsModel.SETTING.VOLUME_CHARACTER, readVolume, writeVolume)
end
function SettingsModel:addSteeringBackSpeedSetting()
	local readSpeed = function()
		return Utils.getStateFromValues(self.steeringBackSpeedValues, self.steeringBackSpeedStep, g_gameSettings:getValue(SettingsModel.SETTING.STEERING_BACK_SPEED))
	end
	local writeSpeed = function(value)
		g_gameSettings:setValue(SettingsModel.SETTING.STEERING_BACK_SPEED, self.steeringBackSpeedValues[value])
	end
	self:addSetting(SettingsModel.SETTING.STEERING_BACK_SPEED, readSpeed, writeSpeed)
end
function SettingsModel:addSteeringSensitivitySetting()
	local readSpeed = function()
		return Utils.getStateFromValues(self.steeringSensitivityValues, self.steeringSensitivityStep, g_gameSettings:getValue(SettingsModel.SETTING.STEERING_SENSITIVITY))
	end
	local writeSpeed = function(value)
		g_gameSettings:setValue(SettingsModel.SETTING.STEERING_SENSITIVITY, self.steeringSensitivityValues[value])
	end
	self:addSetting(SettingsModel.SETTING.STEERING_SENSITIVITY, readSpeed, writeSpeed)
end
function SettingsModel:addGyroscopeSteeringSetting()
	local read = function()
		return g_gameSettings:getValue(SettingsModel.SETTING.GYROSCOPE_STEERING)
	end
	local write = function(value)
		g_gameSettings:setValue(SettingsModel.SETTING.GYROSCOPE_STEERING, value)
	end
	self:addSetting(SettingsModel.SETTING.GYROSCOPE_STEERING, read, write)
end
function SettingsModel:addHintsSetting()
	local read = function()
		return g_gameSettings:getValue(SettingsModel.SETTING.HINTS)
	end
	local write = function(value)
		g_gameSettings:setValue(SettingsModel.SETTING.HINTS, value)
	end
	self:addSetting(SettingsModel.SETTING.HINTS, read, write)
end
function SettingsModel:addCameraTiltingSetting()
	local read = function()
		return g_gameSettings:getValue(SettingsModel.SETTING.CAMERA_TILTING)
	end
	local write = function(value)
		g_gameSettings:setValue(SettingsModel.SETTING.CAMERA_TILTING, value)
	end
	self:addSetting(SettingsModel.SETTING.CAMERA_TILTING, read, write)
end
function SettingsModel:addForceFeedbackSetting()
	local read = function()
		return Utils.getMasterVolumeIndex(g_gameSettings:getValue(SettingsModel.SETTING.FORCE_FEEDBACK))
	end
	local write = function(value)
		g_gameSettings:setValue(SettingsModel.SETTING.FORCE_FEEDBACK, Utils.getMasterVolumeFromIndex(value))
	end
	self:addSetting(SettingsModel.SETTING.FORCE_FEEDBACK, read, write)
end
function SettingsModel:addEngineQualitySetting(key, enum, supportFunc, nameFunc, setFunc, getFunc, onChangedFunc, excludeOffText, restartRequired)
	local texts = {}
	local mapping = {}
	local mappingReverse = {}
	local enumOrdered = {}
	for name, quality in pairs(enum) do
		enumOrdered[quality + 1] = name
	end
	local numMappings = 1
	for quality, name in ipairs(enumOrdered) do
		local quality = quality - 1
		if quality == enum.NUM then
			continue
		end
		if (supportFunc == nil or supportFunc(quality)) and excludeOffText then
			if quality == enum.OFF then
				mapping[quality] = -1
				mappingReverse[-1] = quality
			else
				local text = self.qualityTexts[name]
				if text == nil and nameFunc ~= nil then
					text = nameFunc(quality)
				end
				table.insert(texts, text)
				mapping[quality] = numMappings
				mappingReverse[numMappings] = quality
				numMappings = numMappings + 1
			end
		end
	end
	local getTexts = function()
		return texts
	end
	local valueToRaw = function(value)
		return mappingReverse[value]
	end
	local rawToValue = function(value)
		return mapping[value]
	end
	local readValue = function()
		return mapping[getFunc()]
	end
	local writeValue = function(value)
		local newValue = mappingReverse[value]
		if newValue ~= nil and getFunc() ~= newValue then
			setFunc(newValue)
		end
	end
	restartRequired = Utils.getNoNil(restartRequired, false)
	self:addSetting(key, readValue, writeValue, restartRequired, getTexts, rawToValue, valueToRaw, onChangedFunc)
end
function SettingsModel.getShadowQualityIndex(shadowQuality, hasShadowFocusBox)
	if shadowQuality == 1 then
		return 2
	elseif shadowQuality == 2 and hasShadowFocusBox == false then
		return 3
	elseif shadowQuality == 2 and hasShadowFocusBox == true then
		return 4
	else
		return 1
	end
end
function SettingsModel.getShadowQualityByIndex(shadowIndex)
	if shadowIndex == 2 then
		return 1
	elseif shadowIndex == 3 then
		return 2
	elseif shadowIndex == 4 then
		return 2
	else
		return 0
	end
end
function SettingsModel.getHasShadowFocusBoxByIndex(shadowIndex)
	if shadowIndex == 2 then
		return false
	elseif shadowIndex == 3 then
		return false
	elseif shadowIndex == 4 then
		return true
	else
		return false
	end
end
function SettingsModel.getShaderQualityIndex(shaderQuality)
	if shaderQuality == 1 then
		return 2
	elseif shaderQuality == 2 then
		return 3
	elseif shaderQuality == 3 then
		return 4
	else
		return 1
	end
end
function SettingsModel.getShaderQualityByIndex(shaderIndex)
	if shaderIndex == 2 then
		return 1
	elseif shaderIndex == 3 then
		return 2
	elseif shaderIndex == 4 then
		return 3
	else
		return 0
	end
end
function SettingsModel.getShadowMapFilterIndex(shadowFilter)
	if shadowFilter == 16 then
		return 2
	else
		return 1
	end
end
function SettingsModel.getShadowMapFilterByIndex(shadowFilterIndex)
	if shadowFilterIndex == 2 then
		return 16
	else
		return 4
	end
end
function SettingsModel.getTerrainQualityIndex(terrainQuality)
	return math.min(math.max(terrainQuality + 1, 1), 4)
end
function SettingsModel.getTerrainQualityByIndex(terrainQualityIndex)
	return math.min(math.max(terrainQualityIndex - 1, 0), 3)
end
function SettingsModel.getTextureResolutionIndex(textureResolution)
	if textureResolution == 0 then
		return 2
	else
		return 1
	end
end
function SettingsModel.getTextureResolutionByIndex(textureResolutionIndex)
	if textureResolutionIndex == 2 then
		return 0
	else
		return 1
	end
end
function SettingsModel.getNumOfReflectionMapsByIndex(index)
	return math.clamp(index - 1, 0, 7)
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
