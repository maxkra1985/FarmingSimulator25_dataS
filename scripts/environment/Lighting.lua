-- Local values: Lighting_mt
Lighting = {}
local Lighting_mt = Class(Lighting)

-- Upvalues: Lighting_mt
-- Local values: self
function Lighting.new(customMt)
	-- upvalues: (copy) Lighting_mt
	local v3_ = customMt or Lighting_mt
	local v4_ = setmetatable({}, v3_)
	v4_.updateInterval = 10000
	v4_.lastUpdateDayTime = 0
	v4_.lastDaylightFactor = 1
	v4_.cloudEnvMapIndex1 = 1
	v4_.cloudEnvMapIndex2 = 1
	v4_.cloudEnvMapBlendAlpha = 0
	v4_.dayTime = 0
	v4_.sunHeightAngle = 0
	v4_.sunColor = nil
	v4_.snowHeight = 0
	v4_.snowHeightThreshold = 0.06
	v4_.dayStart = 6.55
	v4_.dayEnd = 18.1
	v4_.nightEnd = 5
	v4_.nightStart = 19.81
	v4_.currentVisualSeason = Season.SPRING
	v4_.alpha = 1
	v4_.lastSunRotation = 0
	v4_.currentSunRotation = 0
	v4_.targetSunRotation = 0
	v4_.sunUpdateDuration = 4000
	v4_.updateSunThreshold = 0.03490658503988659
	v4_.isInitialSunUpdate = true
	v4_.lastSunUpdateRotation = 0
	return v4_
end

function Lighting:delete() end

-- Local values: cloudShadowsTransmittanceBoostData, _, timeProbeKey, timeHours, envMapFile
function Lighting:load(xmlFile, baseKey, baseDirectory)
	local v9_ = xmlFile:getFloat(baseKey .. ".sunRotation#heightAngleLimitRotation", 60)
	self.heightAngleLimitRotation = math.rad(v9_)
	local v10_ = xmlFile:getFloat(baseKey .. ".sunRotation#heightAngleLimitRotationStart", 56)
	self.heightAngleLimitRotationStart = math.rad(v10_)
	local v11_ = xmlFile:getFloat(baseKey .. ".sunRotation#heightAngleLimitRotationEnd", 80)
	self.heightAngleLimitRotationEnd = math.rad(v11_)
	self.sunRotationCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".sunRotation", true)
	self.moonBrightnessScaleCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".moonBrightnessScale")
	self.moonSizeScaleCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".moonSizeScale")
	self.sunIsPrimaryCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".sunIsPrimary")
	self.sunBrightnessScaleCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".sunBrightnessScale")
	self.sunSizeScaleCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".sunSizeScale")
	self.asymmetryFactorCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".asymmetryFactor")
	self.primaryExtraterrestrialColorCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".primaryExtraterrestrialColor")
	self.secondaryExtraterrestrialColorCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".secondaryExtraterrestrialColor")
	self.primaryDynamicLightingScaleCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".primaryDynamicLightingScale")
	self.lightScatteringRotationCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".lightScatteringRotation", true)
	self.autoExposureCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".autoExposure")
	local v12_ = self:loadCurveDataFromXML(xmlFile, baseKey .. ".cloudShadowsTransmittanceBoost")
	if #v12_ > 0 then
		self.cloudShadowsTransmittanceBoostData = v12_
	end
	if Platform.usesFixedExposure then
		self.fixedExposureCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".fixedExposure")
	end
	self.colorGradingData = self:loadFileCurveDataFromXML(xmlFile, baseKey .. ".colorGrading", baseDirectory)
	self.bloomMagnitude = xmlFile:getFloat(baseKey .. ".bloom#magnitude") or 0.5
	self.bloomThreshold = xmlFile:getFloat(baseKey .. ".bloom#threshold") or 2
	self.toneMappingCurveSlope = xmlFile:getFloat(baseKey .. ".toneMapping#slope") or 1
	self.toneMappingCurveToe = xmlFile:getFloat(baseKey .. ".toneMapping#toe") or 0.4
	self.toneMappingCurveShoulder = xmlFile:getFloat(baseKey .. ".toneMapping#shoulder") or 0.8
	self.toneMappingCurveBlackClip = xmlFile:getFloat(baseKey .. ".toneMapping#blackClip") or 0
	self.toneMappingCurveWhiteClip = xmlFile:getFloat(baseKey .. ".toneMapping#whiteClip") or 0.04
	self.envMapTimes = {}
	for _, v13_ in xmlFile:iterator(baseKey .. ".envMap.timeProbe") do
		local v14_ = xmlFile:getFloat(v13_ .. "#timeHours")
		if v14_ ~= nil then
			local v15_ = self.envMapTimes
			table.insert(v15_, v14_)
		end
	end
	table.sort(self.envMapTimes)
	self.defaultEnvMap = Utils.getFilename("$shared/default_env.png", baseDirectory)
	self.envMapBasePath = xmlFile:getString(baseKey .. ".envMap#basePath")
	if self.envMapBasePath ~= nil then
		self.envMapBasePath = Utils.getFilename(self.envMapBasePath, baseDirectory)
		if not string.endsWith(self.envMapBasePath, "/") then
			self.envMapBasePath = self.envMapBasePath .. "/"
		end
		if #self.envMapTimes > 0 then
			local v16_ = self.envMapBasePath .. Lighting.getEnvMapBaseFilename(self.envMapTimes[1], 1) .. ".png"
			if not textureFileExists(v16_) then
				Logging.xmlError(xmlFile, "EnvMap \'%s\' does not exist!", v16_)
				self.envMapBasePath = nil
			end
		end
	end
	self.envMapRenderingMode = false
	self.albedoGroundColors = {
		[Season.SPRING] = xmlFile:getVector(baseKey .. ".envAlbedoGroundColors.spring#value", { 0, 0, 0 }, 3),
		[Season.SUMMER] = xmlFile:getVector(baseKey .. ".envAlbedoGroundColors.summer#value", { 0, 0, 0 }, 3),
		[Season.AUTUMN] = xmlFile:getVector(baseKey .. ".envAlbedoGroundColors.autumn#value", { 0, 0, 0 }, 3),
		[Season.WINTER] = xmlFile:getVector(baseKey .. ".envAlbedoGroundColors.winter#value", { 0, 0, 0 }, 3),
		["snow"] = xmlFile:getVector(baseKey .. ".envAlbedoGroundColors.snow#value", { 0, 0, 0 }, 3)
	}
	self.lastUpdateDayTime = 0
	self.lastDaylightFactor = 1
	return true
end

function Lighting:apply()
	setBloomMagnitude(self.bloomMagnitude)
	setBloomMaskThreshold(self.bloomThreshold)
	setToneMappingCurveSlope(self.toneMappingCurveSlope)
	setToneMappingCurveToe(self.toneMappingCurveToe)
	setToneMappingCurveShoulder(self.toneMappingCurveShoulder)
	setToneMappingCurveBlackClip(self.toneMappingCurveBlackClip)
	setToneMappingCurveWhiteClip(self.toneMappingCurveWhiteClip)
end

-- Local values: data, _, timeKey, time, values, j, value, number
function Lighting:loadCurveDataFromXML(xmlFile, baseKey, convertRadians)
	local v21_ = {}
	for _, v22_ in xmlFile:iterator(baseKey .. ".key") do
		local v23_ = xmlFile:getFloat(v22_ .. "#time")
		local v24_ = string.split(xmlFile:getString(v22_ .. "#value"), " ")
		for v25_, v26_ in ipairs(v24_) do
			local v27_ = tonumber(v26_)
			if convertRadians then
				v27_ = math.rad(v27_)
			end
			v24_[v25_] = v27_
		end
		table.insert(v21_, { v23_, v24_ })
	end
	return v21_
end

-- Local values: data, _, timeKey, timeHours, filename
function Lighting:loadFileCurveDataFromXML(xmlFile, baseKey, baseDirectory)
	local v31_ = {}
	for _, v32_ in xmlFile:iterator(baseKey .. ".key") do
		local v33_ = { xmlFile:getFloat(v32_ .. "#timeHours"), (Utils.getFilename(xmlFile:getString(v32_ .. "#filename"), baseDirectory)) }
		table.insert(v31_, v33_)
	end
	return v31_
end

function Lighting:reset()
	resetAutoExposure()
end

function Lighting:setCloudEnvMapInfo(cloudEnvMapIndex1, cloudEnvMapIndex2, alpha)
	self.cloudEnvMapIndex1 = cloudEnvMapIndex1
	self.cloudEnvMapIndex2 = cloudEnvMapIndex2
	self.cloudEnvMapBlendAlpha = alpha
end

-- Local values: sunRotation, dx, dy, dz, limitAlpha, scale
function Lighting:update(dt, force)
	if self.alpha ~= 1 then
		local v40_ = self.alpha + dt / self.sunUpdateDuration
		self.alpha = math.min(v40_, 1)
		self.currentSunRotation = MathUtil.lerp(self.lastSunRotation, self.targetSunRotation, self.alpha)
		self.isSunDirty = true
	end
	if self.isSunDirty then
		local v41_ = self.currentSunRotation
		local v42_, v43_, v44_ = mathEulerRotateVector(self.sunHeightAngle, 0, v41_, 0, 0, 1)
		if v43_ < self.sunHeightLimitStart then
			if v43_ <= self.sunHeightLimitEnd then
				v43_ = self.sunHeightLimit
			else
				local v45_ = (v43_ - self.sunHeightLimitEnd) / (self.sunHeightLimitStart - self.sunHeightLimitEnd)
				v43_ = self.sunHeightLimit + v45_ * (self.sunHeightLimitStart - self.sunHeightLimit)
			end
			local v46_ = (1 - v43_ * v43_) / (v42_ * v42_ + v44_ * v44_)
			local v47_ = math.sqrt(v46_)
			v42_ = v42_ * v47_
			v44_ = v44_ * v47_
		end
		setDirection(self.sunLightId, v42_, v43_, v44_, 0, 1, 0)
		self.isSunDirty = false
	end
end

-- Local values: dayMinutes, gradingFile1, gradingFile2, gradingAlpha, dayHours
function Lighting:setDayTime(dayTime, force)
	if not force then
		local v51_ = dayTime - self.lastUpdateDayTime
		if math.abs(v51_) <= self.updateInterval then
			::l3::
			return
		end
	end
	local v52_ = dayTime / 60000
	self:updateSunLocation(dayTime, v52_)
	self:updateEnvMap(self:getHardcodedFromTime(v52_ / 60) * 60, force)
	self:updateEnvAlbedo()
	self:updateAtmosphere(v52_)
	local v53_, v54_, v55_ = self.colorGradingFileCurve:get(v52_)
	setColorGradingSettings(v53_, v54_, v55_)
	self:updateExposureSettings()
	local v56_ = v52_ / 60
	if self.dayStart < v56_ and v56_ < self.dayEnd then
		self.lastDaylightFactor = 1
	elseif self.dayEnd <= v56_ and v56_ < self.nightStart then
		self.lastDaylightFactor = 1 - (v56_ - self.dayEnd) / (self.nightStart - self.dayEnd)
	elseif self.nightStart <= v56_ or v56_ < self.nightEnd then
		self.lastDaylightFactor = 0
	elseif self.nightEnd <= v56_ and v56_ < self.dayStart then
		self.lastDaylightFactor = (v56_ - self.nightEnd) / (self.dayStart - self.nightEnd)
	else
		self.lastDaylightFactor = 0
	end
	self.lastUpdateDayTime = dayTime
	goto l3
end

-- Local values: _
function Lighting:updateSunHeight()
	local _, v58_, _ = mathEulerRotateVector(self.sunHeightAngle, 0, self.heightAngleLimitRotation, 0, 0, 1)
	self.sunHeightLimit = v58_
	local _, v59_, _ = mathEulerRotateVector(self.sunHeightAngle, 0, self.heightAngleLimitRotationStart, 0, 0, 1)
	self.sunHeightLimitStart = v59_
	local _, v60_, _ = mathEulerRotateVector(self.sunHeightAngle, 0, self.heightAngleLimitRotationEnd, 0, 0, 1)
	self.sunHeightLimitEnd = v60_
end

function Lighting:setSunHeightAngle(sunHeightAngle)
	self.sunHeightAngle = sunHeightAngle
end

-- Local values: sunRotation, rotationDelta, x, y, _, fruitType
function Lighting:updateSunLocation(dayTime, dayMinutes)
	local v65_ = self.sunRotCurve:get(dayMinutes)
	local v66_ = v65_ - self.lastSunUpdateRotation
	if math.abs(v66_) > self.updateSunThreshold then
		self.lastSunRotation = self.currentSunRotation
		self.targetSunRotation = v65_
		self.lastSunUpdateRotation = v65_
		self.alpha = 0
		self.isSunDirty = true
		if self.isInitialSunUpdate then
			self.isInitialSunUpdate = false
			self.currentSunRotation = v65_
			self.alpha = 1
		end
	end
	local v67_ = 0
	local v68_
	if dayMinutes < 360 then
		v68_ = 4.713 + 1.571 * (dayMinutes / 360)
	elseif dayMinutes < 1080 then
		v68_ = 3.142 + 3.142 * (1 - (dayMinutes - 360) / 720)
	else
		v68_ = 3.142 + 1.571 * ((dayMinutes - 1080) / 360)
	end
	if dayMinutes < 480 then
		v67_ = v67_ + 1.571 * (1 - dayMinutes / 480)
	elseif dayMinutes > 960 then
		v67_ = v67_ + 1.571 * ((dayMinutes - 960) / 480)
	end
	if g_fruitTypeManager ~= nil then
		for _, v69_ in ipairs(g_fruitTypeManager:getFruitTypes()) do
			if v69_.alignsToSun and v69_.terrainDataPlaneId ~= nil then
				setFoliageShaderParameter(v69_.terrainDataPlaneId, "plantRotate", v67_, v68_, 0, 0)
			end
		end
	end
end

-- Local values: envMapTime0Cloud0, envMapTime0Cloud1, envMapTime1Cloud0, envMapTime1Cloud1, blendTime, blendCloud, dayHours, timeSecondIndex, i, time, timeFirstIndex, startTime, endTime, cloudFirstIndex, cloudSecondIndex, blendWeight0, blendWeight1, blendWeight2, blendWeight3
function Lighting:updateEnvMap(dayMinutes, force)
	if self.envMapBasePath == nil or #self.envMapTimes == 0 then
		setEnvMap(self.defaultEnvMap, self.defaultEnvMap, self.defaultEnvMap, self.defaultEnvMap, 1, 0, 0, 0, force, true)
		return
	end
	local v73_ = self.envMapBasePath .. Lighting.getEnvMapBaseFilename(self.envMapTimes[1], 1) .. ".png"
	local v74_, v75_, v76_, v77_, v78_
	if #self.envMapTimes > 1 then
		local v79_ = dayMinutes / 60
		local v80_ = 1
		for v81_, v82_ in ipairs(self.envMapTimes) do
			if v79_ < v82_ then
				v80_ = v81_
				break
			end
		end
		local v83_ = v80_ - 1
		local v84_ = v83_ <= 0 and #self.envMapTimes or v83_
		local v85_ = self.envMapTimes[v84_]
		local v86_ = self.envMapTimes[v80_]
		v74_ = MathUtil.timeLerp(v85_, v86_, v79_)
		local v87_ = self.cloudEnvMapIndex1
		local v88_ = self.cloudEnvMapIndex2
		v75_ = self.cloudEnvMapBlendAlpha
		v73_ = self.envMapBasePath .. Lighting.getEnvMapBaseFilename(self.envMapTimes[v84_], v87_) .. ".png"
		v76_ = self.envMapBasePath .. Lighting.getEnvMapBaseFilename(self.envMapTimes[v84_], v88_) .. ".png"
		v77_ = self.envMapBasePath .. Lighting.getEnvMapBaseFilename(self.envMapTimes[v80_], v87_) .. ".png"
		v78_ = self.envMapBasePath .. Lighting.getEnvMapBaseFilename(self.envMapTimes[v80_], v88_) .. ".png"
	else
		v78_ = v73_
		v77_ = v78_
		v76_ = v77_
		local v89_ = v78_
		v78_ = v76_
		v89_ = v77_
		v77_ = v78_
		v89_ = v76_
		v74_ = 0
		v75_ = 0
	end
	local v90_ = (1 - v74_) * (1 - v75_)
	local v91_ = (1 - v74_) * v75_
	local v92_ = v74_ * (1 - v75_)
	local v93_ = v74_ * v75_
	if self.envMapRenderingMode then
		setEnvMap(v73_, v76_, v77_, v78_, 0, 0, 0, 0, true, false)
	else
		setEnvMap(v73_, v76_, v77_, v78_, v90_, v91_, v92_, v93_, force or false, false)
	end
end

function Lighting:setSnowHeight(snowHeight)
	self.snowHeight = snowHeight
end

function Lighting:setSnowHeightThreshold(threshold)
	self.snowHeightThreshold = threshold
end

function Lighting:setVisualSeason(season)
	self.currentVisualSeason = season
end

-- Local values: r, g, b, r, g, b
function Lighting:updateEnvAlbedo()
	if self.snowHeight >= self.snowHeightThreshold then
		local v101_ = self.albedoGroundColors.snow
		local v102_, v103_, v104_ = unpack(v101_)
		setEnvAlbedoGroundColor(v102_, v103_, v104_)
	else
		local v105_ = self.albedoGroundColors[self.currentVisualSeason]
		local v106_, v107_, v108_ = unpack(v105_)
		setEnvAlbedoGroundColor(v106_, v107_, v108_)
	end
end

-- Local values: primaryScatteringRotation, secondaryScatteringRotation, pLscX, pLscY, pLscZ, sLscX, sLscY, sLscZ, sdr, sdg, sdb, asymmetryFactor, sunSizeScale, moonSizeScale, sunIsPrimary, moonBrightnessScale, sunBrightnessScale, cloudShadowsTransmittanceBoost, dr, dg, db, dynamicLightingScale
function Lighting:updateAtmosphere(dayMinutes)
	local v111_, v112_ = self.lightScatteringRotCurve:get(dayMinutes)
	local v113_, v114_, v115_ = mathEulerRotateVector(self.sunHeightAngle, 0, v111_, 0, 0, 1)
	setLightScatteringDirection(self.sunLightId, v113_, v114_, v115_)
	local v116_, v117_, v118_ = mathEulerRotateVector(self.sunHeightAngle, 0, v112_, 0, 0, 1)
	local v119_, v120_, v121_ = self.secondaryExtraterrestrialColor:get(dayMinutes)
	setAtmosphereSecondaryLightSource(v116_, v117_, v118_, v119_, v120_, v121_)
	local v122_ = self.asymmetryFactorCurve:get(dayMinutes)
	setAtmosphereCornetteShankAsymmetryFactor(v122_)
	local v123_ = self.sunSizeScaleCurve:get(dayMinutes)
	setSunSizeScale(v123_)
	local v124_ = self.moonSizeScaleCurve:get(dayMinutes)
	setMoonSizeScale(v124_)
	local v125_ = self.sunIsPrimaryCurve:get(dayMinutes) > 0.5
	setSunIsPrimary(v125_)
	local v126_ = self.moonBrightnessScaleCurve:get(dayMinutes)
	local v127_ = self.sunBrightnessScaleCurve:get(dayMinutes)
	if self.envMapRenderingMode then
		if v125_ then
			v127_ = v127_ * 0.001
		else
			local _ = v126_ * 0.001
		end
	end
	setSunBrightnessScale(v127_)
	if self.cloudShadowsTransmittanceCurve ~= nil then
		local v128_ = self.cloudShadowsTransmittanceCurve:get(dayMinutes)
		setCloudShadowsTransmittanceBoost(v128_)
	end
	local v129_, v130_, v131_ = self.primaryExtraterrestrialColor:get(dayMinutes)
	local v132_ = self.primaryDynamicLightingScale:get(dayMinutes)
	setLightColor(self.sunLightId, v129_ * v132_, v130_ * v132_, v131_ * v132_)
	setLightScatteringColor(self.sunLightId, v129_, v130_, v131_)
end

-- Local values: dayMinutes, minExposure, maxExposure, keyValue, _
function Lighting:updateExposureSettings()
	local v134_ = self.dayTime / 60000
	local v135_, v136_, v137_
	if Platform.usesFixedExposure then
		if self.fixedKeyValue == nil or self.fixedMinExposure == nil then
			v135_ = self.fixedExposureCurve:get(v134_)
			v136_ = v135_
			v137_ = 0.18
		else
			v137_ = self.fixedKeyValue
			v135_ = self.fixedMinExposure
			v136_ = self.fixedMaxExposure
		end
	elseif self.fixedKeyValue == nil then
		v137_, v135_, v136_ = self.autoExposureCurve:get(v134_)
	elseif self.fixedMinExposure == nil then
		local v138_
		v138_, v135_, v136_ = self.autoExposureCurve:get(v134_)
		v137_ = self.fixedKeyValue
	else
		v137_ = self.fixedKeyValue
		v135_ = self.fixedMinExposure
		v136_ = self.fixedMaxExposure
	end
	setExposureRange(v137_, v135_, v136_)
end

function Lighting:updateCurves()
	self.lightScatteringRotCurve = self:createCurve(linearInterpolator2, self.lightScatteringRotationCurveData)
	self.asymmetryFactorCurve = self:createCurve(linearInterpolator1, self.asymmetryFactorCurveData)
	self.sunBrightnessScaleCurve = self:createCurve(linearInterpolator1, self.sunBrightnessScaleCurveData)
	self.sunSizeScaleCurve = self:createCurve(linearInterpolator1, self.sunSizeScaleCurveData)
	self.moonBrightnessScaleCurve = self:createCurve(linearInterpolator1, self.moonBrightnessScaleCurveData)
	self.moonSizeScaleCurve = self:createCurve(linearInterpolator1, self.moonSizeScaleCurveData)
	self.sunIsPrimaryCurve = self:createCurve(linearInterpolator1, self.sunIsPrimaryCurveData)
	self.primaryDynamicLightingScale = self:createCurve(linearInterpolator1, self.primaryDynamicLightingScaleCurveData)
	self.primaryExtraterrestrialColor = self:createCurve(linearInterpolator3, self.primaryExtraterrestrialColorCurveData)
	self.secondaryExtraterrestrialColor = self:createCurve(linearInterpolator3, self.secondaryExtraterrestrialColorCurveData)
	self.autoExposureCurve = self:createCurve(linearInterpolator3, self.autoExposureCurveData)
	if Platform.usesFixedExposure then
		self.fixedExposureCurve = self:createCurve(linearInterpolator1, self.fixedExposureCurveData)
	end
	if self.cloudShadowsTransmittanceBoostData ~= nil then
		self.cloudShadowsTransmittanceCurve = self:createCurve(linearInterpolator1, self.cloudShadowsTransmittanceBoostData)
	end
	self.colorGradingFileCurve = self:getColorGradingFileCurve()
	self:updateSunHeight()
	self.sunRotCurve = self:createCurve(linearInterpolator1, self.sunRotationCurveData)
end

-- Local values: curve, i, values
function Lighting:createCurve(interpolator, data)
	local v143_ = AnimCurve.new(interpolator)
	if data == nil then
		printCallstack()
	end
	for v144_ = 1, #data do
		local v145_ = data[v144_]
		local v146_ = {
			["time"] = self:getTimeFromHardcoded(v145_[1]) * 60
		}
		local v147_ = v145_[2]
		__set_list(v146_, 1, {unpack(v147_)})
		v143_:addKeyframe(v146_)
	end
	return v143_
end

-- Local values: dayStart, dayEnd, nightStart, nightEnd, alpha, alpha, alpha, alpha, alpha
function Lighting:getTimeFromHardcoded(hardcoded)
	local v150_ = self.dayStart
	local v151_ = self.dayEnd
	local v152_ = self.nightStart
	local v153_ = self.nightEnd
	if hardcoded < 6 then
		return v153_ * (hardcoded / 6)
	end
	if hardcoded >= 6 and hardcoded < 7 then
		local v154_ = hardcoded - 6
		return (v150_ - v153_) * v154_ + v153_
	end
	if hardcoded >= 7 and hardcoded < 19 then
		local v155_ = (hardcoded - 7) / 12
		return (v151_ - v150_) * v155_ + v150_
	end
	if hardcoded >= 19 and hardcoded < 20 then
		local v156_ = hardcoded - 19
		return (v152_ - v151_) * v156_ + v151_
	end
	if hardcoded < 20 or hardcoded > 24 then
		return 0
	end
	local v157_ = (hardcoded - 20) / 4
	return (24 - v152_) * v157_ + v152_
end

-- Local values: dayStart, dayEnd, nightStart, nightEnd, alpha, alpha, alpha, alpha, alpha
function Lighting:getHardcodedFromTime(time)
	local v160_ = self.dayStart
	local v161_ = self.dayEnd
	local v162_ = self.nightStart
	local v163_ = self.nightEnd
	if time < v163_ then
		return 6 * (time / v163_)
	elseif v163_ <= time and time < v160_ then
		return 1 * ((time - v163_) / (v160_ - v163_)) + 6
	elseif v160_ <= time and time < v161_ then
		return 12 * ((time - v160_) / (v161_ - v160_)) + 7
	elseif v161_ <= time and time < v162_ then
		return 1 * ((time - v161_) / (v162_ - v161_)) + 19
	else
		return 4 * ((time - v162_) / (24 - v162_)) + 20
	end
end

-- Local values: curve, _, data
function Lighting:getColorGradingFileCurve()
	local v165_ = AnimCurve.new(Lighting.fileInterpolator)
	for _, v166_ in ipairs(self.colorGradingData) do
		v165_:addKeyframe({
			["time"] = self:getTimeFromHardcoded(v166_[1]) * 60,
			["file"] = v166_[2]
		})
	end
	return v165_
end

function Lighting:setDaylightTimes(dayStart, dayEnd, nightEnd, nightStart)
	if self.dayStart ~= dayStart and (self.dayEnd ~= dayEnd and (self.nightEnd ~= nightEnd and self.nightStart ~= nightStart)) then
		self.dayStart = dayStart
		self.dayEnd = dayEnd
		self.nightEnd = nightEnd
		self.nightStart = nightStart
		self:updateCurves()
	end
end

function Lighting:setFixedExposureSettings(keyValue, minExposure, maxExposure)
	if maxExposure == nil then
		maxExposure = minExposure
	end
	self.fixedKeyValue = keyValue
	self.fixedMinExposure = minExposure
	self.fixedMaxExposure = maxExposure
end

function Lighting:getDaylightFactor()
	return self.lastDaylightFactor
end

-- Local values: hours, minutesPerc, minutes, seconds
function Lighting.getEnvMapBaseFilename(dayTimeHours, cloudSetup)
	local v179_, v180_ = math.modf(dayTimeHours)
	local v181_ = v180_ * 60
	local v182_, v183_ = math.modf(v181_)
	local v184_ = v183_ * 60
	local v185_ = math.floor(v184_)
	return string.format("%d_%d_%d_C%d", v179_, v182_, v185_, cloudSetup)
end

function Lighting.fileInterpolator(first, second, alpha)
	return first.file, second.file, alpha
end
