-- Local values: Environment_mt
Environment = {}
local Environment_mt = Class(Environment)
Environment.SEASONS_IN_YEAR = 4
Environment.PERIODS_IN_YEAR = 12
Environment.JULIAN_DAYS_NORTH = {
	[Season.SPRING] = 60,
	[Season.SUMMER] = 152,
	[Season.AUTUMN] = 244,
	[Season.WINTER] = 335
}
Environment.JULIAN_DAYS_SOUTH = {
	[Season.SPRING] = 244,
	[Season.SUMMER] = 335,
	[Season.AUTUMN] = 60,
	[Season.WINTER] = 152
}
Environment.DAYTIME_TO_HOURS_MULT = 1.1574074074074074e-8
Environment.INITIAL_DAY = 6
Environment.MAX_DAYS_PER_PERIOD = 28
Environment.PERIOD_DAY_MAPPING = {
	[SeasonPeriod.EARLY_SPRING] = 80,
	[SeasonPeriod.MID_SPRING] = 110,
	[SeasonPeriod.LATE_SPRING] = 140,
	[SeasonPeriod.EARLY_SUMMER] = 170,
	[SeasonPeriod.MID_SUMMER] = 200,
	[SeasonPeriod.LATE_SUMMER] = 230,
	[SeasonPeriod.EARLY_AUTUMN] = 260,
	[SeasonPeriod.MID_AUTUMN] = 290,
	[SeasonPeriod.LATE_AUTUMN] = 320,
	[SeasonPeriod.EARLY_WINTER] = 350,
	[SeasonPeriod.MID_WINTER] = 20,
	[SeasonPeriod.LATE_WINTER] = 50
}

-- Local values: sunPath, sunChildIndex, secondSunPath, secondSunChildIndex
function Environment:onCreateSunLight(node)
	if g_currentMission ~= nil and g_currentMission.environment ~= nil then
		if g_currentMission.environment.baseLighting.sunLightId == nil then
			g_currentMission.environment.baseLighting.sunLightId = node
			g_currentMission.environment.baseLighting.sunColor = { getLightColor(node) }
			return
		end
		local v3_ = I3DUtil.getNodePath(g_currentMission.environment.lighting.sunLightId)
		local v4_ = getChildIndex(g_currentMission.environment.lighting.sunLightId)
		local v5_ = I3DUtil.getNodePath(node)
		local v6_ = getChildIndex(node)
		Logging.error("Environment:onCreateSunLight(): Sun light source was already registered \'%s\'(child %d). Please remove \'%s\' (child %d)", v3_, v4_, v5_, v6_)
	end
end

-- Local values: newMask, profileId
function Environment:onCreateWater(id)
	if getHasClassId(id, ClassIds.SHAPE) then
		if not Utils.getNoNil(getUserAttribute(id, "useShapeObjectMask"), false) then
			local v8_ = getObjectMask(id)
			local v9_ = ObjectMask.SHAPE_VIS_MIRROR
			local v10_ = bit32.bnot(v9_)
			local v11_ = bit32.band(v8_, v10_)
			setObjectMask(id, v11_)
		end
		if getShapeCastShadowmap(id) then
			Logging.i3dWarning(id, "Environment:onCreateWater(): Water plane has shadow casting active")
		end
		if not getShapeReceiveShadowmap(id) then
			Logging.i3dWarning(id, "Environment:onCreateWater(): Water plane is missing shadow receive")
		end
		local v12_ = Utils.getPerformanceClassId()
		if v12_ <= GS_PROFILE_MEDIUM or GS_IS_CONSOLE_VERSION then
			setReflectionMapScaling(id, 0, true)
		elseif v12_ <= GS_PROFILE_HIGH then
			setReflectionMapObjectMasks(id, ObjectMask.SHAPE_VIS_WATER_REFL, ObjectMask.LIGHT_VIS_WATER_REFL, true)
		else
			setReflectionMapObjectMasks(id, ObjectMask.SHAPE_VIS_WATER_REFL_VERYHIGH, ObjectMask.LIGHT_VIS_WATER_REFL_VERYHIGH, true)
		end
		if getRigidBodyType(id) ~= RigidBodyType.NONE then
			if not CollisionFlag.getHasGroupFlagSet(id, CollisionFlag.WATER) then
				Logging.i3dWarning(id, "Environment:onCreateWater(): Water plane is missing %s", CollisionFlag.getBitAndName(CollisionFlag.WATER))
			end
			if g_currentMission.shallowWaterSimulation ~= nil then
				if not g_currentMission.isLoadingMap then
					Logging.i3dWarning(id, "Environment:onCreateWater(): Cannot add shallow water simulation planes using onCreate for meshes outside the map itself, use xml config \'placeable.shallowWaterSimulation\' instead")
					return
				end
				g_currentMission.shallowWaterSimulation:addWaterPlane(id)
				g_currentMission.shallowWaterSimulation:addAreaGeometry(id)
			end
		end
	else
		Logging.i3dError(id, "Environment:onCreateWater(): Given node is not a shape, ignoring")
	end
end

-- Upvalues: Environment_mt
-- Local values: self, skyNode
function Environment.new(mission)
	-- upvalues: (copy) Environment_mt
	local v14_ = Environment_mt
	local v15_ = setmetatable({}, v14_)
	local v16_ = g_i3DManager:loadI3DFile("data/sky/sky.i3d", false, false)
	if v16_ ~= 0 then
		link(getRootNode(), v16_)
		v15_.skyNode = v16_
	end
	v15_.mission = mission
	v15_.daylight = Daylight.new()
	v15_.lighting = Lighting.new()
	v15_.baseLighting = v15_.lighting
	v15_.weather = Weather.new(v15_)
	v15_.environmentMaskSystem = EnvironmentMaskSystem.new(v15_.mission)
	v15_.currentDay = nil
	v15_.currentMonotonicDay = nil
	v15_.dayTime = nil
	v15_.timeUpdateInterval = 60000
	v15_.timeUpdateTime = 0
	v15_.isSunOn = true
	v15_.debugSeasonalShaderParameter = false
	if v15_.mission:getIsServer() then
		addConsoleCommand("gsTimeSet", "Sets the day time in hours", "consoleCommandSetDayTime", v15_, "timeHours; [skipDayOnly]")
		addConsoleCommand("gsEnvironmentReload", "Reloads environment", "consoleCommandReloadEnvironment", v15_)
		if g_addCheatCommands then
			addConsoleCommand("gsTakeEnvProbes", "Takes env. probes from current camera position", "consoleCommandTakeEnvProbes", v15_)
		end
	end
	addConsoleCommand("gsSetFixedExposureSettings", "Sets fixed exposure settings", "consoleCommandSetFixedExposureSettings", v15_, "keyValue; minExposure; maxExposure")
	addConsoleCommand("gsEnvironmentAutoExposureToggle", "Toggles auto exposure", "consoleCommandToggleAutoExposure", v15_)
	addConsoleCommand("gsEnvironmentExposureFixedLuminance", "Set exposure fixed luminance", "consoleCommandSetExposureFixedLuminance", v15_, "luminance")
	addConsoleCommand("gsEnvironmentSeasonalShaderSet", "Sets the seasonal shader to a forced value", "consoleCommandSetSeasonalShader", v15_)
	addConsoleCommand("gsEnvironmentSeasonalShaderDebug", "Shows the current seasonal shader parameter", "consoleCommandSeasonalShaderDebug", v15_)
	addConsoleCommand("gsEnvironmentFixedVisualsSet", "Sets the visual seasons to a fixed period", "consoleCommandSetFixedVisuals", v15_, "periodIndex")
	return v15_
end

-- Local values: xmlFile, baseKey, startHour, dayTime
function Environment:load(filename)
	self.xmlFilename = filename
	local v19_ = XMLFile.load("Environment", filename)
	if v19_ == nil then
		Logging.fatal("Could not load environment \'%s\'", filename)
	end
	self.currentDay = 1
	self.currentMonotonicDay = 1
	self.currentDayInPeriod = 1
	self.currentYear = 1
	self.currentDayInSeason = 1
	self.currentVisualDayInSeason = 1
	self.currentSeason = Season.SPRING
	self.currentPeriod = SeasonPeriod.EARLY_SPRING
	self.daysPerPeriod = 1
	self.timeAdjustment = 1 / self.daysPerPeriod
	self.plannedDaysPerPeriod = 1
	self.currentVisualSeason = Season.SPRING
	self.currentVisualPeriod = SeasonPeriod.EARLY_SPRING
	self.visualPeriodLocked = false
	self.dayLength = 86400000
	self.realHourLength = 3600000
	self.realHourTimer = self.realHourLength
	self.daylight:load(v19_, "environment")
	self:updateJulianDay()
	local v20_ = v19_:getFloat("environment#startHour", 8)
	local v21_ = v20_ == nil and 0 or v20_ * 60 * 60 * 1000
	self:setEnvironmentTime(Environment.INITIAL_DAY, Environment.INITIAL_DAY, v21_, self.daysPerPeriod, false)
	self.dayNightCycle = v19_:getBool("environment#dayNightCycle", true)
	self.lighting:load(v19_, "environment.lighting", g_currentMission.baseDirectory)
	self.lighting:setSnowHeightThreshold(SnowSystem.MIN_LAYER_HEIGHT)
	self.lighting:apply()
	self.weather:setIsRainAllowed(true)
	self.weather:load(v19_, "environment", g_currentMission.baseDirectory)
	self.environmentMaskSystem:setDayOfYear(Environment.PERIOD_DAY_MAPPING[self.currentVisualPeriod], self.currentVisualSeason)
	self.environmentMaskSystem:setIsSunOn(self.isSunOn)
	self.nightTimeScale = v19_:getFloat("environment#nightTimeScale", 2)
	self.dirtColorDefault = v19_:getVector("environment.dirtColors#default", { 0.2, 0.14, 0.08 }, 3)
	self.dirtColorSnow = v19_:getVector("environment.dirtColors#snow", { 0.95, 0.95, 0.95 }, 3)
	v19_:delete()
	g_messageCenter:unsubscribeAll(self)
	return self
end

function Environment:delete()
	if self.skyNode ~= nil then
		delete(self.skyNode)
		self.skyNode = nil
	end
	self:resetSceneParameters()
	self.environmentMaskSystem:delete()
	self.environmentMaskSystem = nil
	self.weather:delete()
	self.weather = nil
	self.baseLighting:delete()
	self.baseLighting = nil
	self.daylight:delete()
	self.daylight = nil
	g_messageCenter:unsubscribeAll(self)
	removeConsoleCommand("gsTimeSet")
	removeConsoleCommand("gsEnvironmentReload")
	removeConsoleCommand("gsSetFixedExposureSettings")
	removeConsoleCommand("gsEnvironmentAutoExposureToggle")
	removeConsoleCommand("gsEnvironmentExposureFixedLuminance")
	removeConsoleCommand("gsEnvironmentSeasonalShaderSet")
	removeConsoleCommand("gsEnvironmentSeasonalShaderDebug")
	removeConsoleCommand("gsEnvironmentFixedVisualsSet")
	removeConsoleCommand("gsTakeEnvProbes")
end

function Environment:saveToXMLFile(xmlFile, key)
	setXMLFloat(xmlFile, key .. ".dayTime", self.dayTime / 60000)
	setXMLInt(xmlFile, key .. ".currentDay", self.currentDay)
	setXMLInt(xmlFile, key .. ".currentMonotonicDay", self.currentMonotonicDay)
	setXMLInt(xmlFile, key .. ".realHourTimer", self.realHourTimer)
	setXMLInt(xmlFile, key .. ".daysPerPeriod", self.daysPerPeriod)
	setXMLFloat(xmlFile, key .. ".lighting.toneMapping#slope", getToneMappingCurveSlope())
	setXMLFloat(xmlFile, key .. ".lighting.toneMapping#toe", getToneMappingCurveToe())
	setXMLFloat(xmlFile, key .. ".lighting.toneMapping#shoulder", getToneMappingCurveShoulder())
	setXMLFloat(xmlFile, key .. ".lighting.toneMapping#blackClip", getToneMappingCurveBlackClip())
	setXMLFloat(xmlFile, key .. ".lighting.toneMapping#whiteClip", getToneMappingCurveWhiteClip())
	self.daylight:saveToXMLFile(xmlFile, key .. ".daylight")
	self.weather:saveToXMLFile(xmlFile, key .. ".weather")
end

-- Local values: dayTime, currentDay, currentMonotonicDay, fixedPeriod
function Environment:loadFromXMLFile(xmlFile, key)
	local v29_ = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".dayTime"), 400)
	local v30_ = Utils.getNoNil(getXMLInt(xmlFile, key .. ".currentDay"), self.currentDay)
	local v31_ = Utils.getNoNil(getXMLInt(xmlFile, key .. ".currentMonotonicDay"), v30_)
	self.daysPerPeriod = Utils.getNoNil(getXMLInt(xmlFile, key .. ".daysPerPeriod"), self.daysPerPeriod)
	self.timeAdjustment = 1 / self.daysPerPeriod
	self.plannedDaysPerPeriod = self.mission.missionInfo.plannedDaysPerPeriod
	local v32_ = self.mission.missionInfo.fixedSeasonalVisuals
	if v32_ ~= nil then
		self.currentVisualPeriod = v32_
		self.currentVisualSeason = SeasonPeriod.getSeason(v32_)
		self.visualPeriodLocked = true
	end
	self.realHourTimer = Utils.getNoNil(getXMLInt(xmlFile, key .. ".realHourTimer"), 3600000)
	self.daylight:loadFromXMLFile(xmlFile, key .. ".daylight")
	self.weather:loadFromXMLFile(xmlFile, key .. ".weather")
	self:setEnvironmentTime(v31_, v30_, v29_ * 1000 * 60, self.daysPerPeriod, false)
end

-- Local values: task, newDayTime, newDay, rainScale, timeTillRain, filename, renderResolution, outputResolution, ssaoQuality, numIterations, renderSun, currentData, cloudUpdater, cloudEnvMapIndex1, cloudEnvMapIndex2, alpha, dayMinutes, isNight
function Environment:update(dt)
	if self.envMapGeneration ~= nil then
		local v35_ = self.envMapGeneration.tasks[1]
		if v35_ ~= nil then
			if v35_.dayTime ~= nil then
				local v36_ = v35_.dayTime * 1000 * 60 * 60
				local v37_ = math.floor(v36_)
				local v38_ = self.currentDay
				self:setEnvironmentTime(v38_, v38_, v37_, self.daysPerPeriod, false)
				self.lighting:setDayTime(self.dayTime, true)
			end
			if v35_.cloudData ~= nil then
				self.weather.cloudUpdater:setTargetClouds(v35_.cloudData, 0)
				self.weather.cloudUpdater:setWindValues(v35_.windDirX, v35_.windDirZ, v35_.windVelocity, v35_.cirrusCloudSpeedFactor)
				self.weather.cloudUpdater:update(10000)
				if self.weather.skyBoxUpdater ~= nil then
					local v39_, v40_
					if v35_.cloudData.precipitation > 0.5 then
						v39_ = 1
						v40_ = -1000
					else
						v39_ = 0
						v40_ = math.huge
					end
					self.weather.skyBoxUpdater:update(10000, self.dayTime, v39_, v40_)
				end
			end
			if v35_.setDefaultValues then
				setSharedShaderParameter(Shader.PARAM_SHARED_SEASON, 0)
				self.baseLighting:setDaylightTimes(7, 19, 6, 20)
				self.baseLighting.envMapRenderingMode = true
				self.baseLighting:setDayTime(self.dayTime, true)
				self.baseLighting.envMapRenderingMode = false
			end
			local v41_ = v35_.filename
			if v41_ ~= nil then
				local v42_ = v35_.renderResolution
				local v43_ = v35_.outputResolution
				local v44_ = v35_.ssaoQuality
				local v45_ = v35_.numIterations
				renderEnvProbe(v42_, v43_, v44_, false, v45_, v41_)
			end
			table.remove(self.envMapGeneration.tasks, 1)
			return
		end
		local v46_ = self.envMapGeneration.currentData
		local v47_ = self.weather.cloudUpdater
		v47_.lastClouds = v46_.lastClouds
		v47_.targetClouds = v46_.targetClouds
		v47_.alpha = v46_.alpha
		v47_.duration = v46_.duration
		v47_.windDirX = v46_.windDirX
		v47_.windDirZ = v46_.windDirZ
		v47_.windVelocity = v46_.windVelocity
		v47_.cirrusCloudSpeedFactor = v46_.cirrusCloudSpeedFactor
		v47_.isDirty = true
		g_currentMission.growthSystem:setGrowthMode(v46_.growthMode, true)
		self:setEnvironmentTime(v46_.currentMonotonicDay + 12 * self.daysPerPeriod, v46_.currentDay + 12 * self.daysPerPeriod, v46_.dayTime, self.daysPerPeriod, false)
		self.envMapGeneration = nil
		print("Finished environment map generation")
	end
	self.weather:update(dt)
	self.environmentMaskSystem:update(dt)
	self.dayTime = self.dayTime + dt * self.mission:getEffectiveTimeScale()
	self:updateTimeValues(false)
	self.realHourTimer = self.realHourTimer - dt
	if self.realHourTimer <= 0 then
		g_messageCenter:publish(MessageType.REALHOUR_CHANGED)
		self.realHourTimer = self.realHourLength
	end
	if self.lighting ~= nil then
		local v48_, v49_, v50_ = self.weather:getCloudEnvMapInfo()
		self.lighting:setCloudEnvMapInfo(v48_, v49_, v50_)
		self.lighting:setSunHeightAngle(self.daylight:getSunHeightAngle())
		self.lighting:setDaylightTimes(self.daylight:getDaylightTimes())
		self.lighting:setSnowHeight(self.weather.snowHeight)
		self.lighting:setVisualSeason(self.currentVisualSeason)
		self.lighting:setDayTime(self.dayTime, g_sleepManager.isSleeping)
		self.lighting:update(dt)
	end
	self:updateSceneParameters()
	if self.debugSeasonalShaderParameter then
		renderText(0.2, 0.05, 0.015, string.format("Season Shader Parameter (cShared3): %s", self:getSeasonShaderValue()))
		if g_currentMission.snowSystem ~= nil then
			renderText(0.2, 0.035, 0.015, string.format("Snow Shader Parameter (cShared4): %s", g_currentMission.snowSystem:getSnowShaderValue()))
		end
	end
	if g_server ~= nil then
		self.timeUpdateTime = self.timeUpdateTime + dt
		if self.timeUpdateTime > self.timeUpdateInterval then
			EnvironmentTimeEvent.broadcastEvent()
			self.timeUpdateTime = 0
		end
		if Platform.gameplay.hasShortNights and not g_sleepManager:getIsSleeping() then
			local v51_ = self.dayTime / 60000
			local v52_ = self.daylight.logicalNightStartMinutes <= v51_ and true or v51_ < self.daylight.logicalNightEndMinutes
			if v52_ ~= self.lastNightState then
				self.mission:setTimeScaleMultiplier(v52_ and (self.nightTimeScale or 1) or 1)
			end
			self.lastNightState = v52_
		end
	end
end

-- Local values: timeHoursF, timeHours, timeMinutes, hourChanged, dayChanged, periodChanged, seasonChanged, yearChanged, periodLengthChanged, period, season, oldDaysPerPeriod, year, currentVisualPeriod
function Environment:updateTimeValues(isInitialState)
	local v55_ = self.dayTime / 3600000 + 0.0001
	local v56_ = math.floor(v55_)
	local v57_ = (v55_ - v56_) * 60
	local v58_ = math.floor(v57_)
	self.environmentMaskSystem:setDayTime(self.dayTime)
	local v59_ = false
	local v60_ = false
	local v61_ = false
	local v62_ = false
	local v63_ = false
	local v64_ = false
	if v58_ ~= self.currentMinute then
		while v58_ ~= self.currentMinute do
			self.currentMinute = self.currentMinute + 1
			if self.currentMinute >= 60 then
				self.currentMinute = 0
			end
			if not isInitialState then
				g_messageCenter:publish(MessageType.MINUTE_CHANGED, self.currentMinute)
				self.mission:onMinuteChanged(self.currentMinute)
			end
		end
	end
	if v56_ ~= self.currentHour then
		self.currentHour = v56_
		if self.currentHour == 24 then
			self.currentHour = 0
			v59_ = true
		else
			v59_ = true
		end
	end
	if self.dayTime > 86400000 then
		self.dayTime = self.dayTime - 86400000
		self.currentDay = self.currentDay + 1
		self.currentMonotonicDay = self.currentMonotonicDay + 1
		v60_ = true
	end
	if v60_ or isInitialState then
		self.currentDayInPeriod = (self.currentDay - 1) % self.daysPerPeriod + 1
		local v65_ = ((self.currentDay - 1) % (self.daysPerPeriod * Environment.PERIODS_IN_YEAR) + 1) / self.daysPerPeriod
		local v66_ = math.ceil(v65_)
		if v66_ ~= self.currentPeriod then
			self.currentPeriod = v66_
			if self.visualPeriodLocked then
				v61_ = true
			else
				self.currentVisualPeriod = self.currentPeriod
				v61_ = true
			end
		end
		local v67_ = (self.currentDay - 1) / self:getDaysPerSeason()
		local v68_ = math.floor(v67_)
		local v69_ = Environment.SEASONS_IN_YEAR
		local v70_ = math.fmod(v68_, v69_) + 1
		if v70_ ~= self.currentSeason then
			self.currentSeason = v70_
			if not self.visualPeriodLocked then
				self.currentVisualSeason = v70_
			end
			v62_ = true
			if self.daysPerPeriod ~= self.plannedDaysPerPeriod then
				local v71_ = self.daysPerPeriod
				self.daysPerPeriod = self.plannedDaysPerPeriod
				self.timeAdjustment = 1 / self.daysPerPeriod
				local v72_ = (self.currentDay - 1) / v71_ * self.daysPerPeriod
				self.currentDay = math.floor(v72_) + 1
				self.currentDayInPeriod = (self.currentDay - 1) % self.daysPerPeriod + 1
				v64_ = true
			end
		end
		local v73_ = self.currentDay - 1
		local v74_ = self.daysPerPeriod * 3
		self.currentDayInSeason = math.fmod(v73_, v74_) + 1
		if self.visualPeriodLocked then
			local v75_ = (self.currentVisualPeriod - 1) % 1.5 * self.daysPerPeriod + 1
			self.currentVisualDayInSeason = math.floor(v75_)
		else
			self.currentVisualDayInSeason = self.currentDayInSeason
		end
		local v76_ = (self.currentDay - 1) / (self.daysPerPeriod * Environment.PERIODS_IN_YEAR)
		local v77_ = math.floor(v76_) + 1
		if v77_ ~= self.currentYear then
			self.currentYear = v77_
			v63_ = true
		end
	end
	if v60_ or isInitialState then
		self:updateJulianDay()
	end
	if v61_ or isInitialState then
		local v78_ = self.currentVisualPeriod
		self.environmentMaskSystem:setDayOfYear(Environment.PERIOD_DAY_MAPPING[v78_], self.currentVisualSeason)
	end
	if v59_ and not isInitialState then
		g_messageCenter:publish(MessageType.HOUR_CHANGED, self.currentHour)
		self.mission:onHourChanged()
	end
	if v60_ and not isInitialState then
		g_messageCenter:publish(MessageType.DAY_CHANGED, self.currentDay)
		self.mission:onDayChanged()
		if v64_ then
			g_messageCenter:publish(MessageType.PERIOD_LENGTH_CHANGED, self.daysPerPeriod, self.timeAdjustment)
		end
		if v61_ then
			g_messageCenter:publish(MessageType.PERIOD_CHANGED, self.currentPeriod, self.currentVisualPeriod)
		end
		if v62_ then
			g_messageCenter:publish(MessageType.SEASON_CHANGED, self.currentSeason)
		end
		if v63_ then
			g_messageCenter:publish(MessageType.YEAR_CHANGED, self.currentYear)
		end
	end
end

-- Local values: dayMinutes, newIsSunOn
function Environment:updateSceneParameters()
	if self.dayNightCycle and self.lighting.sunLightId ~= nil then
		local v80_ = self.dayTime / 60000
		local v81_ = self.daylight.logicalNightStartMinutes > v80_ and v80_ >= self.daylight.logicalNightEndMinutes
		if self.isSunOn ~= v81_ then
			self.isSunOn = v81_
			self.environmentMaskSystem:setIsSunOn(v81_)
			g_messageCenter:publish(MessageType.DAY_NIGHT_CHANGED)
		end
	end
	if self.forcedSeasonShaderValue == nil then
		setSharedShaderParameter(Shader.PARAM_SHARED_SEASON, self:getSeasonShaderValue())
	end
end

function Environment:resetSceneParameters()
	setSharedShaderParameter(Shader.PARAM_SHARED_SEASON, 0)
end

-- Local values: pInDay, shaderSeason, day, daysPerSeason, pInSeason, alpha
function Environment:getSeasonShaderValue()
	if self.visualPeriodLocked then
		return (self.currentVisualSeason - 2) % 4 + 0.5
	end
	local v83_ = self.dayTime * Environment.DAYTIME_TO_HOURS_MULT + 0.0001
	local v84_ = (self.currentSeason - 2) % 4
	local v85_ = self.currentDay
	local v86_ = 3 * self.daysPerPeriod
	return v84_ + ((v85_ - 1) % v86_ / v86_ + v83_ / v86_)
end

function Environment:setCustomLighting(lighting)
	if self.lighting ~= nil then
		self.lighting:reset()
	end
	self.lighting = lighting or self.baseLighting
	self.lighting.sunLightId = self.baseLighting.sunLightId
	self.lighting:setSunHeightAngle(self.daylight:getSunHeightAngle())
	self.lighting:setDaylightTimes(self.daylight:getDaylightTimes())
	self.lighting:setDayTime(self.dayTime, true)
	self.lighting:apply()
end

-- Local values: r, g, b
function Environment:setSunVisibility(isVisible)
	if isVisible then
		local v91_ = self.baseLighting.sunColor
		local v92_, v93_, v94_ = unpack(v91_)
		setLightColor(self.baseLighting.sunLightId, v92_, v93_, v94_)
	else
		setLightColor(self.baseLighting.sunLightId, 0, 0, 0)
	end
end

function Environment:getMinuteOfDay()
	local v96_ = self.dayTime / 1000 / 60
	return math.floor(v96_)
end

function Environment:getDayOfYear()
	return Environment.PERIOD_DAY_MAPPING[self.currentVisualPeriod]
end

-- Local values: newDayOffset, newDayTime, newDayTimeInteger
function Environment:getDayAndDayTime(dayTime, dayOffset)
	local v101_ = dayTime / self.dayLength
	local v102_, v103_ = math.modf(v101_)
	local v104_ = v103_ * self.dayLength
	local v105_ = math.round(v104_)
	return dayOffset + v102_, v105_
end

function Environment:getDaysPerSeason()
	return self.daysPerPeriod * 3
end

-- Local values: diff, seasonalDay
function Environment:getSeasonAtDay(day)
	local v109_ = day - self.currentMonotonicDay
	local v110_ = (self.currentDay + v109_ - 1) / self:getDaysPerSeason()
	local v111_ = math.floor(v110_)
	local v112_ = Environment.SEASONS_IN_YEAR
	return math.fmod(v111_, v112_) + 1
end

function Environment:getDaysPlayed()
	return self.currentMonotonicDay - Environment.INITIAL_DAY
end

function Environment:getVisualSeasonAtDay(day)
	if self.visualPeriodLocked then
		return self.currentVisualSeason
	else
		return self:getSeasonAtDay(day)
	end
end

-- Local values: timeHoursF
function Environment:setEnvironmentTime(currentMonotonicDay, currentDay, dayTime, daysPerPeriod, isDelta)
	self.currentDay = currentDay
	self.currentMonotonicDay = currentMonotonicDay
	self.dayTime = dayTime
	self.daysPerPeriod = daysPerPeriod
	if not isDelta then
		while self.dayTime > 86400000 do
			self.dayTime = self.dayTime - 86400000
			self.currentDay = self.currentDay + 1
			self.currentMonotonicDay = self.currentMonotonicDay + 1
		end
		local v122_ = self.dayTime / 3600000 + 0.0001
		self.currentHour = math.floor(v122_)
		local v123_ = (v122_ - self.currentHour) * 60
		self.currentMinute = math.floor(v123_)
	end
	self:updateTimeValues(true)
end

function Environment:getEnvironmentTime()
	return self.currentHour + self.currentMinute / 100
end

-- Local values: startDays, partInSeason
function Environment:getJulianDay()
	local v126_ = Environment.JULIAN_DAYS_NORTH
	if self.daylight.latitude < 0 then
		v126_ = Environment.JULIAN_DAYS_SOUTH
	end
	local v127_ = self.currentVisualDayInSeason / (3 * self.daysPerPeriod)
	local v128_ = v126_[self.currentVisualSeason] + v127_ * 91
	local v129_ = math.floor(v128_)
	return math.fmod(v129_, 365)
end

function Environment:getMonotonicHour()
	return self.currentMonotonicDay * 24 + self.dayTime / 3600000
end

function Environment:updateJulianDay()
	if self.daylight ~= nil then
		self.daylight:setJulianDay(self:getJulianDay())
	end
end

-- Local values: base, time
function Environment:getPeriodAndAlphaIntoPeriod()
	local v133_ = self.currentDayInPeriod - 1
	local v134_ = self.dayTime * Environment.DAYTIME_TO_HOURS_MULT
	return self.currentPeriod, (v133_ + v134_) / self.daysPerPeriod
end

function Environment:getDirtColors()
	return self.dirtColorDefault, self.dirtColorSnow
end

-- Local values: diff, seasonalDay
function Environment:getPeriodFromDay(day)
	local v138_ = day - self.currentMonotonicDay
	local v139_ = ((self.currentDay + v138_ - 1) % (self.daysPerPeriod * Environment.PERIODS_IN_YEAR) + 1) / self.daysPerPeriod
	return math.ceil(v139_)
end

-- Local values: diff, seasonalDay
function Environment:getDayInPeriodFromDay(day)
	local v142_ = day - self.currentMonotonicDay
	return (self.currentDay + v142_ - 1) % self.daysPerPeriod + 1
end

function Environment:setFixedPeriod(period)
	if period == nil and self.visualPeriodLocked == true then
		self.visualPeriodLocked = false
		self.currentVisualPeriod = self.currentPeriod
		self.currentVisualSeason = self.currentSeason
		local v145_ = self.currentDay - 1
		local v146_ = self.daysPerPeriod * 3
		self.currentDayInSeason = math.fmod(v145_, v146_) + 1
		self.currentVisualDayInSeason = self.currentDayInSeason
		self.mission.missionInfo.fixedSeasonalVisuals = nil
		self:updateJulianDay()
		self.weather:rebuild()
	elseif period ~= nil and (self.visualPeriodLocked == false or self.currentVisualPeriod ~= period) then
		local v147_ = math.clamp(period, 1, 12)
		self.visualPeriodLocked = true
		self.currentVisualPeriod = v147_
		self.currentVisualSeason = SeasonPeriod.getSeason(v147_)
		local v148_ = self.currentDay - 1
		local v149_ = self.daysPerPeriod * 3
		self.currentDayInSeason = math.fmod(v148_, v149_) + 1
		local v150_ = (self.currentVisualPeriod - 1) % 1.5 * self.daysPerPeriod + 1
		self.currentVisualDayInSeason = math.floor(v150_)
		self.mission.missionInfo.fixedSeasonalVisuals = v147_
		self:updateJulianDay()
		self.weather:rebuild()
	end
end

function Environment:setPlannedDaysPerPeriod(numDays)
	local v153_ = Environment.MAX_DAYS_PER_PERIOD
	self.plannedDaysPerPeriod = math.clamp(numDays, 1, v153_)
	self.mission.missionInfo.plannedDaysPerPeriod = self.plannedDaysPerPeriod
end

-- Local values: newDayTime, newDay, newMonotonicDay
function Environment:consoleCommandSetDayTime(dayTime, skipDayOnly)
	if not self.mission:getIsServer() then
		return "Error: Server only command"
	end
	local v157_ = tonumber(dayTime)
	if v157_ == nil then
		return "Error: Invalid arguments. Arguments: dayTime[h] skipDayOnly[true|false]"
	end
	local v158_ = v157_ * 1000 * 60 * 60
	local v159_ = math.floor(v158_)
	local v160_ = self.currentDay
	local v161_ = self.currentMonotonicDay
	if v159_ < self.dayTime then
		if skipDayOnly then
			v160_ = v160_ + 1
			v161_ = v161_ + 1
		else
			v160_ = v160_ + 12
			v161_ = v161_ + 12
		end
	end
	self:setEnvironmentTime(v161_, v160_, v159_, self.daysPerPeriod, false)
	self.lighting:setDayTime(self.dayTime, true)
	self.weather.cheatedTime = true
	EnvironmentTimeEvent.broadcastEvent()
	return "DayTime = " .. v157_ .. ", Day = " .. v160_ .. "[" .. v161_ .. "]"
end

function Environment:consoleCommandSetFixedVisuals(period)
	if period == nil then
		self:setFixedPeriod(nil)
	else
		self:setFixedPeriod((tonumber(period)))
	end
end

function Environment:consoleCommandReloadEnvironment()
	g_messageCenter:unsubscribeAll(self)
	self:load(self.xmlFilename)
	self.lighting:setSunHeightAngle(self.daylight:getSunHeightAngle())
	self.lighting:setDaylightTimes(self.daylight:getDaylightTimes())
	self.lighting:updateCurves()
	self.lighting:setDayTime(self.dayTime, true)
	return "reloaded environment"
end

-- Local values: ret, minLuminance, maxLuminance
function Environment:consoleCommandSetFixedExposureSettings(keyValue, minExposure, maxExposure)
	local v169_ = tonumber(keyValue)
	local v170_ = tonumber(minExposure)
	local v171_ = tonumber(maxExposure)
	local v172_
	if v169_ == nil then
		v170_ = nil
		v171_ = nil
		v172_ = "Disabled fixed exposure settings"
	elseif v170_ == nil then
		v172_ = string.format("Enabled fixed exposure key %.2f", v169_)
		v171_ = nil
	else
		if v171_ == nil then
			v171_ = v170_
		end
		local v173_ = v169_ / math.pow(2, v171_)
		local v174_ = v169_ / math.pow(2, v170_)
		v172_ = string.format("Enabled fixed exposure settings (key %.2f exposure [%.2f %.2f] [%.4f %.4f])", v169_, v170_, v171_, v173_, v174_)
	end
	self.baseLighting:setFixedExposureSettings(v169_, v170_, v171_)
	if self.lighting == self.baseLighting then
		self.baseLighting:updateExposureSettings()
	end
	return v172_
end

-- Local values: setExposureRange_new
function Environment:consoleCommandToggleAutoExposure(reset)
	if self.setExposureRange_backup ~= nil then
		setExposureRange = self.setExposureRange_backup
		self.setExposureRange_backup = nil
		return "Reenabled auto exposure"
	end
	self.setExposureRange_backup = setExposureRange
	function setExposureRange() end
	if not Utils.stringToBoolean(reset) then
		return string.format("Paused exposure at current settings: middleGrayValue=%.4f  min=%.4f  max=%.4f", getExposureRange())
	end
	resetAutoExposure()
	return string.format("Disabled + reset auto exposure, current settings: middleGrayValue=%.4f  min=%.4f  max=%.4f", getExposureRange())
end

function Environment:consoleCommandSetExposureFixedLuminance(luminance)
	local v178_ = tonumber(luminance)
	if v178_ == nil or v178_ < 0 then
		setFixedLuminanceForExposure(-1)
		return "Disabled fixed luminance for exposure"
	else
		setFixedLuminanceForExposure(v178_)
		return string.format("Set fixed luminance for exposure to %.3f. Use -1 to reset", v178_)
	end
end

function Environment:consoleCommandSetSeasonalShader(val)
	if val == nil or tonumber(val) == nil then
		self.forcedSeasonShaderValue = nil
		self:updateSceneParameters()
		return "Reset the value to match the environment"
	end
	local v181_ = tonumber(val)
	local v182_ = math.max(v181_, 0)
	local v183_ = math.min(v182_, 4)
	self.forcedSeasonShaderValue = v183_
	setSharedShaderParameter(Shader.PARAM_SHARED_SEASON, v183_)
	return "Set shader parameter to " .. tostring(v183_)
end

function Environment:consoleCommandSeasonalShaderDebug()
	self.debugSeasonalShaderParameter = not self.debugSeasonalShaderParameter
end

-- Local values: renderResolution, outputResolution, envMapTimes, baseDirectory, k, cloudData, data, _, dayTime, renderData, cloudUpdater, currentData
function Environment:consoleCommandTakeEnvProbes(numIterations, mobile, outputDirectory)
	local v189_ = tonumber(numIterations)
	if v189_ == nil then
		return "Arguments: numIterations (required), mobile(optional, default: false), outputDirectory (optional, default: [map xml-path])"
	end
	if mobile == nil then
		mobile = false
	end
	local v190_ = 512
	local v191_ = mobile and 128 or 256
	local v192_, v193_
	if self.baseLighting.envMapBasePath == nil then
		v192_ = g_screenshotsDirectory .. "envProbes/"
		v193_ = { 0 }
	else
		v193_ = self.baseLighting.envMapTimes
		v192_ = self.baseLighting.envMapBasePath
	end
	if outputDirectory == nil then
		outputDirectory = v192_
	end
	if outputDirectory:sub(outputDirectory:len()) ~= "/" then
		outputDirectory = outputDirectory .. "/"
	end
	createFolder(outputDirectory)
	print("Writing env maps to " .. outputDirectory)
	if #v193_ <= 0 then
		return "Error: no envMapTimes defined in Lighting"
	end
	self.envMapGeneration = {}
	self.envMapGeneration.tasks = {}
	for v194_, v195_ in ipairs(self.weather.envMapCloudProbes) do
		local v196_ = self.envMapGeneration.tasks
		table.insert(v196_, {
			["cloudData"] = v195_,
			["setDefaultValues"] = true,
			["windDirX"] = 0,
			["windDirZ"] = 1,
			["windVelocity"] = 0,
			["cirrusCloudSpeedFactor"] = 0
		})
		local v197_ = self.envMapGeneration.tasks
		table.insert(v197_, {})
		local v198_ = self.envMapGeneration.tasks
		table.insert(v198_, {})
		local v199_ = self.envMapGeneration.tasks
		table.insert(v199_, {})
		local v200_ = self.envMapGeneration.tasks
		table.insert(v200_, {})
		local v201_ = self.envMapGeneration.tasks
		table.insert(v201_, {})
		local v202_ = self.envMapGeneration.tasks
		table.insert(v202_, {})
		for _, v203_ in ipairs(v193_) do
			local v204_ = {
				["dayTime"] = v203_,
				["renderResolution"] = v190_,
				["outputResolution"] = v191_,
				["numIterations"] = v189_
			}
			if mobile then
				v204_.cloudData = v195_
				v204_.windDirX = 0
				v204_.windDirZ = 1
				v204_.windVelocity = 0
				v204_.cirrusCloudSpeedFactor = 0
				v204_.ssaoQuality = 0
			else
				v204_.ssaoQuality = 15
			end
			v204_.filename = outputDirectory .. Lighting.getEnvMapBaseFilename(v203_, v194_)
			local v205_ = self.envMapGeneration.tasks
			table.insert(v205_, v204_)
		end
	end
	local v206_ = self.weather.cloudUpdater
	local v207_ = {
		["lastClouds"] = v206_.lastClouds:clone(),
		["targetClouds"] = v206_.targetClouds:clone(),
		["alpha"] = v206_.alpha,
		["duration"] = v206_.duration,
		["windDirX"] = v206_.windDirX,
		["windDirZ"] = v206_.windDirZ,
		["windVelocity"] = v206_.windVelocity,
		["cirrusCloudSpeedFactor"] = v206_.cirrusCloudSpeedFactor,
		["growthMode"] = g_currentMission.growthSystem:getGrowthMode(),
		["dayTime"] = self.dayTime,
		["currentMonotonicDay"] = self.currentMonotonicDay,
		["currentDay"] = self.currentDay
	}
	self.envMapGeneration.currentData = v207_
	g_currentMission.growthSystem:setGrowthMode(GrowthMode.DISABLED, true)
	return "Starting env map generation"
end
