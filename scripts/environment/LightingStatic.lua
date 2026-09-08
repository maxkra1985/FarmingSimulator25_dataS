-- Local values: LightingStatic_mt
LightingStatic = {}
local LightingStatic_mt = Class(LightingStatic, Lighting)

-- Upvalues: LightingStatic_mt
-- Local values: self
function LightingStatic.new(customMt)
	-- upvalues: (copy) LightingStatic_mt
	return Lighting.new(customMt or LightingStatic_mt)
end

-- Local values: basePath, suffix
function LightingStatic:load(xmlFile, baseKey, baseDirectory)
	self.sunHeightAngle = -0.8726646259971648
	local v7_ = xmlFile:getFloat(baseKey .. ".sunRotation#heightAngleLimitRotation") or 60
	self.heightAngleLimitRotation = math.rad(v7_)
	local v8_ = xmlFile:getFloat(baseKey .. ".sunRotation#heightAngleLimitRotationStart") or 56
	self.heightAngleLimitRotationStart = math.rad(v8_)
	local v9_ = xmlFile:getFloat(baseKey .. ".sunRotation#heightAngleLimitRotationEnd") or 80
	self.heightAngleLimitRotationEnd = math.rad(v9_)
	self.moonBrightnessScale = xmlFile:getFloat(baseKey .. ".moonBrightnessScale#value")
	self.moonSizeScale = xmlFile:getFloat(baseKey .. ".moonSizeScale#value")
	self.sunIsPrimary = xmlFile:getInt(baseKey .. ".sunIsPrimary#value")
	self.sunBrightnessScale = xmlFile:getFloat(baseKey .. ".sunBrightnessScale#value")
	self.sunSizeScale = xmlFile:getFloat(baseKey .. ".sunSizeScale#value")
	self.asymmetryFactor = xmlFile:getFloat(baseKey .. ".asymmetryFactor#value")
	self.primaryExtraterrestrialColor = xmlFile:getVector(baseKey .. ".primaryExtraterrestrialColor#value", nil, 3)
	self.secondaryExtraterrestrialColor = xmlFile:getVector(baseKey .. ".secondaryExtraterrestrialColor#value", nil, 3)
	self.primaryDynamicLightingScale = xmlFile:getFloat(baseKey .. ".primaryDynamicLightingScale#value")
	self.lightScatteringRotation = xmlFile:getRadiansVector(baseKey .. ".lightScatteringRotation#value", nil, 2)
	self.autoExposure = xmlFile:getVector(baseKey .. ".autoExposure#value", nil, 3)
	self.cloudGroundAlbedo = xmlFile:getVector(baseKey .. ".cloudGroundAlbedo#value", nil, 3)
	if Platform.usesFixedExposure then
		self.fixedExposure = xmlFile:getFloat(baseKey .. ".fixedExposure#value")
	end
	self.colorGrading = Utils.getFilename(xmlFile:getString(baseKey .. ".colorGrading#filename"), baseDirectory)
	local v10_ = Utils.getFilename(xmlFile:getString(baseKey .. ".envMap#basePath"), baseDirectory)
	if not string.endsWith(v10_, "/") then
		v10_ = v10_ .. "/"
	end
	local v11_ = GS_IS_MOBILE_VERSION and "_uncompressed" or ""
	self.envMap = v10_ .. Lighting.getEnvMapBaseFilename(0, 1) .. v11_ .. ".png"
	self.albedoGroundColor = xmlFile:getVector(baseKey .. ".envAlbedoGroundColor#value", nil, 3) or { 0, 0, 0 }
	self.bloomMagnitude = xmlFile:getFloat(baseKey .. ".bloom#magnitude") or 0.5
	self.bloomThreshold = xmlFile:getFloat(baseKey .. ".bloom#threshold") or 2
	self.toneMappingCurveSlope = xmlFile:getFloat(baseKey .. ".toneMapping#slope") or 1
	self.toneMappingCurveToe = xmlFile:getFloat(baseKey .. ".toneMapping#toe") or 0.4
	self.toneMappingCurveShoulder = xmlFile:getFloat(baseKey .. ".toneMapping#shoulder") or 0.8
	self.toneMappingCurveBlackClip = xmlFile:getFloat(baseKey .. ".toneMapping#blackClip") or 0
	self.toneMappingCurveWhiteClip = xmlFile:getFloat(baseKey .. ".toneMapping#whiteClip") or 0.04
	return true
end

function LightingStatic:update(dt, force) end

function LightingStatic:setDayTime(dayTime, force)
	if force then
		setEnvMap(self.envMap, self.envMap, self.envMap, self.envMap, 1, 0, 0, 0, force, true)
		setColorGradingSettings(self.colorGrading, self.colorGrading, 0)
		local v14_ = setEnvAlbedoGroundColor
		local v15_ = self.albedoGroundColor
		v14_(unpack(v15_))
		self:updateAtmosphere()
		self:updateExposureSettings()
	end
end

-- Local values: pLscX, pLscY, pLscZ, sLscX, sLscY, sLscZ, sdr, sdg, sdb, moonBrightnessScale, sunBrightnessScale, dr, dg, db, dynamicLightingScale
function LightingStatic:updateAtmosphere()
	local v17_, v18_, v19_ = mathEulerRotateVector(self.sunHeightAngle, 0, self.lightScatteringRotation[1], 0, 0, 1)
	setLightScatteringDirection(self.sunLightId, v17_, v18_, v19_)
	local v20_, v21_, v22_ = mathEulerRotateVector(self.sunHeightAngle, 0, self.lightScatteringRotation[2], 0, 0, 1)
	local v23_ = self.secondaryExtraterrestrialColor[1]
	local v24_ = self.secondaryExtraterrestrialColor[2]
	local v25_ = self.secondaryExtraterrestrialColor[3]
	setAtmosphereSecondaryLightSource(v20_, v21_, v22_, v23_, v24_, v25_)
	setAtmosphereCornetteShankAsymmetryFactor(self.asymmetryFactor)
	setSunSizeScale(self.sunSizeScale)
	setMoonSizeScale(self.moonSizeScale)
	setSunIsPrimary(self.sunIsPrimary == 1)
	local v26_ = self.moonBrightnessScale
	local v27_ = self.sunBrightnessScale
	if self.envMapRenderingMode then
		if self.sunIsPrimary == 1 then
			v27_ = v27_ * 0.001
		else
			local _ = v26_ * 0.001
		end
	end
	setSunBrightnessScale(v27_)
	local v28_ = self.primaryExtraterrestrialColor[1]
	local v29_ = self.primaryExtraterrestrialColor[2]
	local v30_ = self.primaryExtraterrestrialColor[3]
	local v31_ = self.primaryDynamicLightingScale
	setLightColor(self.sunLightId, v28_ * v31_, v29_ * v31_, v30_ * v31_)
	setLightScatteringColor(self.sunLightId, v28_, v29_, v30_)
	setCloudGroundAlbedo(self.cloudGroundAlbedo[1], self.cloudGroundAlbedo[2], self.cloudGroundAlbedo[3])
end

-- Local values: minExposure, maxExposure, keyValue
function LightingStatic:updateExposureSettings()
	local v33_, v34_, v35_
	if Platform.usesFixedExposure then
		if self.fixedKeyValue == nil or self.fixedMinExposure == nil then
			v33_ = self.fixedExposure[1]
			v34_ = v33_
			v35_ = 0.18
		else
			v35_ = self.fixedKeyValue
			v33_ = self.fixedMinExposure
			v34_ = self.fixedMaxExposure
		end
	elseif self.fixedKeyValue == nil then
		v35_ = self.autoExposure[1]
		v33_ = self.autoExposure[2]
		v34_ = self.autoExposure[3]
	elseif self.fixedMinExposure == nil then
		v33_ = self.autoExposure[2]
		v34_ = self.autoExposure[3]
		v35_ = self.fixedKeyValue
	else
		v35_ = self.fixedKeyValue
		v33_ = self.fixedMinExposure
		v34_ = self.fixedMaxExposure
	end
	setExposureRange(v35_, v33_, v34_)
end

function LightingStatic:updateCurves() end

function LightingStatic:setFixedExposureSettings(keyValue, minExposure, maxExposure)
	LightingStatic:superClass().setFixedExposureSettings(self, keyValue, minExposure, maxExposure)
	self:update(1, true)
end
