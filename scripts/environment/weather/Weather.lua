-- Local values: Weather_mt
Weather = {}
Weather.DEBUG_ENABLED = false
Weather.TEMPERATURE_STABLE_CHANGE = 2
Weather.SEND_BITS_NUM_OBJECTS = 8
Weather.SEND_BITS_OBJECT_INDEX = 5
Weather.SEND_BITS_OBJECT_VARIATION_INDEX = 4
Weather.SEND_BITS_WIND_INDEX = 4
Weather.SEND_BITS_TEMPERATURE = 6
Weather.SEND_BITS_DURATION = 6
Weather.SEND_BITS_STARTTIME = 11
Weather.CHANGE_DURATION = 1800000
source("dataS/scripts/environment/weather/DisasterDestructionState.lua")
source("dataS/scripts/environment/weather/WeatherType.lua")
source("dataS/scripts/environment/weather/WeatherForecast.lua")
source("dataS/scripts/environment/weather/Twister.lua")
source("dataS/scripts/environment/weather/TwisterStartEvent.lua")
source("dataS/scripts/environment/weather/TwisterStopEvent.lua")
source("dataS/scripts/environment/weather/TwisterDestructionNotificationEvent.lua")
source("dataS/scripts/environment/weather/CloudSettings.lua")
source("dataS/scripts/environment/weather/CloudUpdater.lua")
source("dataS/scripts/environment/weather/TemperatureUpdater.lua")
source("dataS/scripts/environment/weather/RainSettings.lua")
source("dataS/scripts/environment/weather/RainUpdater.lua")
source("dataS/scripts/environment/weather/WeatherObject.lua")
source("dataS/scripts/environment/weather/WeatherObjectTwister.lua")
source("dataS/scripts/environment/weather/WeatherObjectHail.lua")
source("dataS/scripts/environment/weather/WeatherInstance.lua")
source("dataS/scripts/environment/weather/WindObject.lua")
source("dataS/scripts/environment/weather/WindUpdater.lua")
source("dataS/scripts/environment/weather/WeatherAddObjectEvent.lua")
source("dataS/scripts/environment/weather/WeatherStateEvent.lua")
source("dataS/scripts/environment/weather/FogSettings.lua")
source("dataS/scripts/environment/weather/FogUpdater.lua")
source("dataS/scripts/environment/weather/FogStateEvent.lua")
source("dataS/scripts/environment/weather/SkyBoxUpdater.lua")
local Weather_mt = Class(Weather)

-- Upvalues: Weather_mt
-- Local values: self
function Weather.new(owner, customMt)
	-- upvalues: (copy) Weather_mt
	local v4_ = customMt or Weather_mt
	local v5_ = setmetatable({}, v4_)
	v5_.owner = owner
	v5_.isRainAllowed = false
	v5_.typeToWeatherObject = {}
	v5_.weatherObjects = {}
	v5_.weightedWeatherObjects = {}
	v5_.forecastItems = {}
	v5_.cloudUpdater = CloudUpdater.new()
	v5_.temperatureUpdater = TemperatureUpdater.new()
	v5_.fogUpdater = FogUpdater.new()
	v5_.rainUpdater = RainUpdater.new()
	if getAtmosphereQuality() == AtmosphereQuality.OFF then
		v5_.skyBoxUpdater = SkyBoxUpdater.new()
	end
	v5_.windUpdater = WindUpdater.new()
	v5_.windUpdater:addWindChangedListener(v5_.cloudUpdater)
	v5_.windUpdater:addWindChangedListener(v5_.rainUpdater)
	v5_.forecast = WeatherForecast.new(v5_)
	v5_.timeSinceLastRain = 9999999
	v5_.snowHeight = 0
	v5_.groundWetness = 0
	v5_.groundWetnessDryDuration = 1800000
	v5_.groundWetnessWetDuration = 300000
	v5_.temperatureDebugGraph = Graph.new(24, 0.58, 0.5, 0.4, 0.4, 0, 40, true, "\194\176", Graph.STYLE_LINES)
	v5_.temperatureDebugGraph:setColor(1, 0, 0, 1)
	v5_.temperatureDebugGraph:setBackgroundColor(0, 0, 0, 0.6)
	v5_.temperatureDebugGraph:setHorizontalLine(5, true, 1, 1, 1, 0.4)
	v5_.temperatureDebugGraph:setVerticalLine(6, true, 1, 1, 1, 0.3)
	v5_.temperatureDebugOverlayCurrent = createImageOverlay("dataS/menu/base/graph_pixel.png")
	setOverlayColor(v5_.temperatureDebugOverlayCurrent, 0, 1, 0, 1)
	addConsoleCommand("gsWeatherDebug", "Toggles weather debug", "consoleCommandWeatherToggleDebug", v5_)
	if not g_currentMission.missionDynamicInfo.isMultiplayer and g_currentMission:getIsServer() then
		addConsoleCommand("gsWeatherReload", "Reloads weather data", "consoleCommandWeatherReloadData", v5_)
		addConsoleCommand("gsWeatherSet", "Sets a weather object by type", "consoleCommandWeatherSet", v5_)
		addConsoleCommand("gsWeatherAdd", "Adds a weather object by type", "consoleCommandWeatherAdd", v5_)
		addConsoleCommand("gsWeatherTwisterSpawn", "Adds a twister at current position in current direction", "consoleCommandWeatherTwisterSpawn", v5_)
		addConsoleCommand("gsWeatherSetDebugWind", "Sets wind data", "consoleCommandWeatherSetDebugWind", v5_)
		addConsoleCommand("gsWeatherSetClouds", "Sets cloud data", "consoleCommandWeatherSetClouds", v5_)
		addConsoleCommand("gsWeatherToggleRandomWindWaving", "Toggles waving of random wind", "consoleCommandWeatherToggleRandomWindWaving", v5_)
	end
	return v5_
end

-- Local values: _, season, envMapCloudPresetIds, cloudPresets, _, cloudPreset, _, preset, _, presetId, cloudSettings, maxObjects, _, seasonKey, numAdded, seasonName, season, fog, twister
function Weather:load(xmlFile, key, baseDirectory)
	self.forecastItems = {}
	self.weatherObjects = {}
	self.weightedWeatherObjects = {}
	for _, v10_ in pairs(Season.getAllOrdered()) do
		self.weatherObjects[v10_] = {}
		self.weightedWeatherObjects[v10_] = {}
		self.typeToWeatherObject[v10_] = {}
		self.seasonToFog = {}
	end
	self.rainUpdater:load(xmlFile, key .. ".weather.rain", baseDirectory)
	self.cloudUpdater:load(xmlFile, key .. ".weather.clouds", baseDirectory)
	local v_u_11_ = {}
	xmlFile:iterate(key .. ".weather.envMap.cloudProbe", function(_, p12_)
		-- upvalues: (copy) xmlFile, (copy) v_u_11_, (copy) self
		local v13_ = xmlFile:getString(p12_ .. "#presetId")
		if v13_ == nil then
			Logging.xmlWarning(xmlFile, "Missing clouds presetId for \'%s\'", p12_)
			return false
		end
		if #v_u_11_ == 3 then
			Logging.xmlWarning(xmlFile, "Only 3 different envmap types are supported for \'%s\'", p12_)
			return false
		end
		if self.cloudUpdater:getPreset(v13_) == nil then
			Logging.xmlWarning(xmlFile, "Clouds presetId \'%s\' is not defined for \'%s\'", v13_, p12_)
			return false
		end
		local v14_ = v_u_11_
		table.insert(v14_, v13_)
		return true
	end)
	local v15_ = self.cloudUpdater:getPresets()
	if #v_u_11_ == 0 then
		Logging.xmlWarning(xmlFile, "No env map cloud probes defined. Adding first cloud preset")
		local _, v16_ = next(v15_)
		local v17_ = v16_.id
		table.insert(v_u_11_, v17_)
	end
	for _, v18_ in pairs(v15_) do
		if v_u_11_[v18_.envMapCloudProbeIndex] == nil then
			Logging.xmlWarning(xmlFile, "Invalid envMapCloudProbeIndex for cloud preset \'%s\'. Using 1 instead", v18_.id)
			v18_.envMapCloudProbeIndex = 1
		end
	end
	self.envMapCloudProbes = {}
	for _, v19_ in ipairs(v_u_11_) do
		local v20_ = self.cloudUpdater:createCloudSettingsFromPreset(v19_)
		local v21_ = v20_ ~= nil
		assert(v21_)
		local v22_ = self.envMapCloudProbes
		table.insert(v22_, v20_)
	end
	local v23_ = 2 ^ Weather.SEND_BITS_OBJECT_INDEX - 1
	for _, v24_ in xmlFile:iterator(key .. ".weather.season") do
		v23_ = v23_ - self:loadWeatherObjects(xmlFile, v24_, v23_)
		local v25_ = xmlFile:getString(v24_ .. "#name")
		local v26_ = Season.getByName(v25_) or Season.SUMMER
		local v27_ = FogSettings.new()
		if xmlFile:hasProperty(v24_ .. ".fog") then
			v27_:loadTemplate(xmlFile, v24_ .. ".fog")
		end
		self.seasonToFog[v26_] = v27_
	end
	self.firstWeatherType = self.firstWeatherType or WeatherType.SUN or (WeatherType.CLOUDY or WeatherType.RAIN)
	if self.skyBoxUpdater ~= nil and not self.skyBoxUpdater:load(xmlFile, key .. ".skyBox") then
		self.skyBoxUpdater:delete()
		self.skyBoxUpdater = nil
	end
	self:randomizeFog(1)
	if g_server ~= nil then
		self:addStartWeather()
		self:fillWeatherForecast()
		self:init()
	end
	self.forecast:load()
	self.temperatureUpdater:setDayLength(self.owner.dayLength)
	g_messageCenter:unsubscribeAll(self)
	g_messageCenter:subscribe(MessageType.DAY_CHANGED, self.onDayChanged, self)
	g_messageCenter:subscribe(MessageType.TIMESCALE_CHANGED, self.onTimeScaleChanged, self)
	g_messageCenter:subscribe(MessageType.PERIOD_LENGTH_CHANGED, self.onPeriodLengthChanged, self)
	g_messageCenter:subscribe(MessageType.GAME_STATE_CHANGED, self.onGameStateChanged, self)
	if Platform.gameplay.supportsTwister then
		local v28_ = Twister.new(g_server ~= nil, g_client ~= nil)
		if v28_:load(xmlFile, key .. ".weather.twister", baseDirectory) then
			v28_:register(true)
			self.twister = v28_
			return
		end
		v28_:delete()
	end
end

-- Local values: seasonName, season, weatherObjects, weightedWeatherObjects, typeToWeatherObject, numAdded, _, objectKey, typeName, weatherType, className, classObject, instance, i
function Weather:loadWeatherObjects(xmlFile, key, maxObjects)
	local v33_ = xmlFile:getString(key .. "#name")
	if v33_ == nil then
		Logging.xmlError(xmlFile, "No season name given in \'%s\'", key)
		return 0
	end
	local v34_ = Season.getByName(v33_)
	if v34_ == nil then
		Logging.xmlError(xmlFile, "Invalid season name \'%s\' given in \'%s\'", v33_, key)
		return 0
	end
	local v35_ = self.weatherObjects[v34_]
	local v36_ = self.weightedWeatherObjects[v34_]
	local v37_ = self.typeToWeatherObject[v34_]
	local v38_ = 0
	for _, v39_ in xmlFile:iterator(key .. ".object") do
		if maxObjects < #v35_ then
			Logging.warning("Weather object limit (%d) reached at \'%s\'", maxObjects, v39_)
			return v38_
		end
		local v40_ = xmlFile:getString(v39_ .. "#typeName")
		local v41_ = WeatherType.getByName(v40_)
		if v41_ == nil then
			Logging.xmlWarning(xmlFile, "Invalid weather type \'%s\' in \'%s\'", v40_, v39_)
		elseif self.isRainAllowed or v41_ ~= WeatherType.RAIN and v41_ ~= WeatherType.SNOW then
			if v37_[v41_] == nil then
				local v42_ = xmlFile:getString(v39_ .. "#class")
				local v43_ = ClassUtil.getClassObject(v42_)
				if v43_ == nil then
					Logging.xmlWarning(xmlFile, "Class \'%s\' not found in \'%s\'", tostring(v42_), v39_)
				elseif v43_:isa(WeatherObject) then
					local v44_ = v43_.new(v41_, self.cloudUpdater, self.temperatureUpdater, self.windUpdater, self.rainUpdater)
					if v44_:load(xmlFile, v39_) then
						if xmlFile:getBool(v39_ .. "#isFirstWeather") then
							self.firstWeatherType = v41_
						end
						table.insert(v35_, v44_)
						v44_.index = #v35_
						v44_.season = v34_
						v37_[v41_] = v44_
						if v44_:getIsAvailable() then
							for _ = 1, v44_.weight do
								local v45_ = v44_.index
								table.insert(v36_, v45_)
							end
						end
						v38_ = v38_ + 1
					end
				else
					Logging.xmlWarning(xmlFile, "Given class \'%s\' is not a WeatherObject in \'%s\'", tostring(v42_), v39_)
				end
			else
				Logging.xmlWarning(xmlFile, "WeatherObject for type \'%s\' already defined in \'%s\'", v40_, v39_)
			end
		end
	end
	return v38_
end

-- Local values: _, seasonWeatherObjects, _, weatherObject
function Weather:delete()
	removeConsoleCommand("gsWeatherSet")
	removeConsoleCommand("gsWeatherAdd")
	removeConsoleCommand("gsWeatherDebug")
	removeConsoleCommand("gsWeatherSetWindState")
	removeConsoleCommand("gsWeatherReload")
	removeConsoleCommand("gsWeatherSetDebugWind")
	removeConsoleCommand("gsWeatherSetClouds")
	removeConsoleCommand("gsWeatherToggleRandomWindWaving")
	removeConsoleCommand("gsWeatherTwisterSpawn")
	delete(self.temperatureDebugOverlayCurrent)
	self.temperatureDebugGraph:delete()
	self.windUpdater:removeWindChangedListener(self.cloudUpdater)
	self.windUpdater:removeWindChangedListener(self.rainUpdater)
	self.rainUpdater:delete()
	for _, v47_ in pairs(self.weatherObjects) do
		for _, v48_ in ipairs(v47_) do
			v48_:delete()
		end
	end
	self.weatherObjects = {}
	if self.skyBoxUpdater ~= nil then
		self.skyBoxUpdater:delete()
	end
	self.forecast:delete()
	g_messageCenter:unsubscribeAll(self)
end

-- Local values: xmlFile, k, instance, instanceKey
function Weather:saveToXMLFile(xmlFileHandle, key)
	local v52_ = XMLFile.wrap(xmlFileHandle)
	for v53_, v54_ in ipairs(self.forecastItems) do
		v54_:saveToXMLFile(v52_, (string.format("%s.forecast.instance(%d)", key, v53_ - 1)))
	end
	self.fogUpdater:saveToXMLFile(v52_, key .. ".fog")
	v52_:setFloat(key .. ".snow#height", self.snowHeight)
	v52_:setFloat(key .. ".ground#wetness", self.groundWetness)
	local v55_ = key .. "#timeSinceLastRain"
	local v56_ = MathUtil.msToMinutes(self.timeSinceLastRain)
	v52_:setInt(v55_, (math.round(v56_)))
	if self.twister ~= nil then
		self.twister:saveToXMLFile(v52_, key .. ".twister")
	end
	v52_:delete()
end

-- Local values: xmlFile, currentInstance, currentWeatherObject, lastStartDay, lastStartDayTime, _, instanceKey, instance, lastInstance, wholeDay, extensionTime, timeBeforeMidnight, oldDuration
function Weather:loadFromXMLFile(xmlFileHandle, key)
	local v60_ = XMLFile.wrap(xmlFileHandle)
	local v61_ = self.forecastItems[1]
	self:getWeatherObjectByIndex(v61_.season, v61_.objectIndex):deactivate(1)
	self.forecastItems = {}
	local v62_ = nil
	local v63_ = nil
	for _, v64_ in v60_:iterator(key .. ".forecast.instance") do
		local v65_ = WeatherInstance.new()
		if not v65_:loadFromXMLFile(v60_, v64_) or v65_.startDay == v62_ and v65_.startDayTime == v63_ then
			break
		end
		self:addWeatherForecast(v65_)
		v62_ = v65_.startDay
		v63_ = v65_.startDayTime
	end
	local v66_ = self.forecastItems[#self.forecastItems]
	if v66_ ~= nil then
		local v67_ = 86400000 - v66_.startDayTime - v66_.duration
		if v67_ > 0 and v67_ < 10800000 then
			local v68_ = v66_.duration
			v66_.duration = 86400000 - v66_.startDayTime
			Logging.info("Found broken weather forecast: Adjusted duration from %d to %d", v68_, v66_.duration)
		end
	end
	self.fogUpdater:loadFromXMLFile(v60_, key .. ".fog")
	self.timeSinceLastRain = MathUtil.minutesToMs(v60_:getInt(key .. "#timeSinceLastRain", 0)) or self.timeSinceLastRain
	self.snowHeight = v60_:getFloat(key .. ".snow#height", self.snowHeight)
	self.groundWetness = v60_:getFloat(key .. ".ground#wetness", self.groundWetness)
	if self.twister ~= nil then
		self.twister:loadFromXMLFile(v60_, key .. ".twister")
	end
	v60_:delete()
	self:fillWeatherForecast()
	self.cloudUpdater:setTimeScale(g_currentMission:getEffectiveTimeScale())
	self:init(true)
end

-- Local values: scaledDt, nextInstance, currentInstance, currentWeatherObject, duration, nextWeatherObject, windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor, rainfallScale, hailfallScale, snowfallScale, updateTime, _, seasonWeatherObjects, _, weatherObject, currentTemperature, timeScale, tempScale, rainFactor, deltaWetness, factor, wetness, dryThreshold, terrainDisplacementWetness
function Weather:update(dt)
	local v71_ = dt * g_currentMission:getEffectiveTimeScale()
	if #self.forecastItems >= 2 then
		local v72_ = self.forecastItems[2]
		local v73_ = self.forecastItems[1]
		local v74_ = self:getWeatherObjectByIndex(v73_.season, v73_.objectIndex)
		if self.owner.currentMonotonicDay > v72_.startDay or self.owner.currentMonotonicDay == v72_.startDay and self.owner.dayTime > v72_.startDayTime then
			local v75_ = Weather.CHANGE_DURATION
			local v76_ = self.cheatedTime and 0 or v75_
			v74_:deactivate(v76_)
			local v77_ = self:getWeatherObjectByIndex(v72_.season, v72_.objectIndex)
			v77_:activate(v72_, v76_)
			if v77_.setWindValues ~= nil then
				local v78_, v79_, v80_, v81_ = self.windUpdater:getCurrentValues()
				v77_:setWindValues(v78_, v79_, v80_, v81_)
			end
			self:onWeatherChanged(v77_)
			table.remove(self.forecastItems, 1)
			if g_server ~= nil then
				self:fillWeatherForecast()
			end
		elseif self.cheatedTime then
			self.cheatedTime = nil
			local v82_ = self:getRainFallScale()
			local v83_ = self:getHailFallScale()
			local v84_ = self:getSnowFallScale()
			if v82_ == 0 and (v83_ == 0 and v84_ == 0) then
				self.groundWetness = 0
			end
		end
		local v85_ = not (self:getIsRaining() or self:getIsHailing())
		if v85_ then
			v85_ = not self:getIsSnowing()
		end
		if v85_ then
			self.timeSinceLastRain = self.timeSinceLastRain + v71_
		else
			self.timeSinceLastRain = 0
		end
	elseif g_server ~= nil then
		self:fillWeatherForecast()
	end
	for _, v86_ in pairs(self.weatherObjects) do
		for _, v87_ in ipairs(v86_) do
			v87_:update(v71_)
		end
	end
	self.cloudUpdater:update(v71_)
	self.temperatureUpdater:update(v71_)
	self.windUpdater:update(v71_)
	self.fogUpdater:update(v71_)
	self.rainUpdater:update(v71_)
	if self.skyBoxUpdater ~= nil then
		self.skyBoxUpdater:update(v71_, self.owner.dayTime, self:getRainFallScale(), self:getTimeUntilRain())
	end
	local v88_ = self.temperatureUpdater:getTemperatureAtTime(self.owner.dayTime)
	local v89_ = g_currentMission:getEffectiveTimeScale()
	if g_currentMission.missionInfo.isSnowEnabled then
		if self:getIsSnowing() and v88_ < 3 then
			local v90_ = 1 - math.max(0, v88_) / 4
			local v91_ = self.snowHeight + 0.0003 * (dt / 1000) * (v89_ / 100) * self:getSnowFallScale() * v90_
			self.snowHeight = math.clamp(v91_, 0, 0.5)
		elseif v88_ >= 5 then
			self.snowHeight = 0
		elseif v88_ > 2 and self.snowHeight > 0 then
			local v92_ = self:getIsRaining() and 3 or 1
			local v93_ = self.snowHeight - v88_ * 0.001 * (dt / 1000) * (v89_ / 100) * v92_
			self.snowHeight = math.clamp(v93_, 0, 0.5)
		end
	else
		self.snowHeight = 0
	end
	local v94_
	if self.timeSinceLastRain == 0 then
		local v95_ = self:getRainFallScale()
		local v96_ = self:getSnowFallScale()
		local v97_ = math.max(v95_, v96_, self:getHailFallScale())
		v94_ = v71_ / self.groundWetnessWetDuration * v97_
	else
		v94_ = -(v71_ / self.groundWetnessDryDuration)
	end
	local v98_ = self.groundWetness + v94_
	self.groundWetness = math.clamp(v98_, 0, 1)
	g_currentMission.snowSystem:setSnowHeight(self.snowHeight)
	local v99_ = self:getGroundWetness()
	local v100_ = v99_ - 0.15
	local v101_ = math.max(0, v100_) / 0.85
	setWetness(v99_)
	setTerrainDisplacementWetness(g_terrainNode, v101_)
end

-- Local values: data, currentMin, currentMax, current, windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor, k, instance, dayDif, weatherObject, rainPreset, text, graph, h, temperature, factor, camera, camX, camY, camZ, camDx, camDy, camDz
function Weather:draw()
	if Weather.DEBUG_ENABLED then
		local v103_ = {}
		local v104_, v105_ = self.temperatureUpdater:getCurrentValues(self.owner.dayTime)
		local v106_ = self.temperatureUpdater:getTemperatureAtTime(self.owner.dayTime)
		table.insert(v103_, {
			["name"] = "TEMPERATURE",
			["value"] = ""
		})
		local v107_ = {
			["name"] = "current",
			["value"] = string.format("%.2f\194\176", v106_)
		}
		table.insert(v103_, v107_)
		local v108_ = {
			["name"] = "currentMin",
			["value"] = string.format("%.2f\194\176", v104_)
		}
		table.insert(v103_, v108_)
		local v109_ = {
			["name"] = "currentMax",
			["value"] = string.format("%.2f\194\176", v105_)
		}
		table.insert(v103_, v109_)
		table.insert(v103_, {
			["name"] = "",
			["value"] = ""
		})
		table.insert(v103_, {
			["name"] = "SNOW",
			["value"] = ""
		})
		local v110_ = {
			["name"] = "height",
			["value"] = string.format("%.5f", self.snowHeight)
		}
		table.insert(v103_, v110_)
		local v111_ = {
			["name"] = "shader",
			["value"] = string.format("%.5f", g_currentMission.snowSystem.snowShaderValue)
		}
		table.insert(v103_, v111_)
		table.insert(v103_, {
			["name"] = "",
			["value"] = ""
		})
		local v112_, v113_, v114_, v115_ = self.windUpdater:getCurrentValues()
		table.insert(v103_, {
			["name"] = "WIND",
			["value"] = ""
		})
		local v116_ = {
			["name"] = "dirX",
			["value"] = string.format("%.3f", v112_)
		}
		table.insert(v103_, v116_)
		local v117_ = {
			["name"] = "dirZ",
			["value"] = string.format("%.3f", v113_)
		}
		table.insert(v103_, v117_)
		local v118_ = {
			["name"] = "velocity",
			["value"] = MathUtil.mpsToKmh(v114_)
		}
		table.insert(v103_, v118_)
		table.insert(v103_, {
			["name"] = "cirrusSpeedFactor",
			["value"] = v115_
		})
		local v119_ = {
			["name"] = "cShared0",
			["value"] = string.format("%.2f", self.windUpdater.sharedShaderParamValueWindSpeed)
		}
		table.insert(v103_, v119_)
		local v120_ = {
			["name"] = "cShared1",
			["value"] = string.format("%.2f", self.windUpdater.sharedShaderParamValueWindDirX)
		}
		table.insert(v103_, v120_)
		local v121_ = {
			["name"] = "cShared2",
			["value"] = string.format("%.2f", self.windUpdater.sharedShaderParamValueWindDirZ)
		}
		table.insert(v103_, v121_)
		table.insert(v103_, {
			["name"] = "",
			["value"] = ""
		})
		table.insert(v103_, {
			["name"] = "RAIN",
			["value"] = ""
		})
		local v122_ = {
			["name"] = "timeSince",
			["value"] = string.format("%.2f", self:getTimeSinceLastRain())
		}
		table.insert(v103_, v122_)
		local v123_ = {
			["name"] = "rainFallScale",
			["value"] = string.format("%.2f", self:getRainFallScale())
		}
		table.insert(v103_, v123_)
		local v124_ = {
			["name"] = "snowFallScale",
			["value"] = string.format("%.2f", self:getSnowFallScale())
		}
		table.insert(v103_, v124_)
		local v125_ = {
			["name"] = "groundWetness",
			["value"] = string.format("%.2f", self:getGroundWetness())
		}
		table.insert(v103_, v125_)
		table.insert(v103_, {
			["name"] = "",
			["value"] = "",
			["columnOffset"] = 0.12
		})
		self.fogUpdater:addDebugValues(v103_)
		table.insert(v103_, {
			["name"] = "",
			["value"] = "",
			["columnOffset"] = 0.12
		})
		self.cloudUpdater:addDebugValues(v103_)
		table.insert(v103_, {
			["name"] = "",
			["value"] = "",
			["columnOffset"] = 0.12
		})
		self.rainUpdater:addDebugValues(v103_)
		table.insert(v103_, {
			["name"] = "",
			["value"] = "",
			["columnOffset"] = 0.12
		})
		if self.skyBoxUpdater ~= nil then
			self.skyBoxUpdater:addDebugValues(v103_)
			table.insert(v103_, {
				["name"] = "",
				["value"] = "",
				["columnOffset"] = 0.12
			})
		end
		for v126_, v127_ in ipairs(self.forecastItems) do
			local v128_ = v127_.startDay - self.owner.currentMonotonicDay
			local v129_ = self:getWeatherObjectByIndex(v127_.season, v127_.objectIndex)
			local v130_ = v129_.variations[v127_.variationIndex].rainPresetId or "nil"
			local v131_ = string.format("Var %d | Active | Duration %d | Season %s | RainPreset %s", v127_.variationIndex, v127_.duration / 3600000, Season.getName(v127_.season), v130_)
			if v126_ > 1 then
				if v128_ == 0 then
					v131_ = string.format("Var %d | In %d minutes | Duration %d | Season %s | RainPreset %s", v127_.variationIndex, (v127_.startDayTime - self.owner.dayTime) / 60000, v127_.duration / 3600000, Season.getName(v127_.season), v130_)
				else
					v131_ = string.format("Var %d | In %d days | Duration %d | Season %s | RainPreset %s", v127_.variationIndex, v128_, v127_.duration / 3600000, Season.getName(v127_.season), v130_)
				end
			end
			local v132_ = {
				["name"] = WeatherType.getName(v129_.weatherType),
				["value"] = v131_
			}
			table.insert(v103_, v132_)
		end
		DebugUtil.renderTable(0.2, 0.46, 0.011, v103_)
		local v133_ = self.temperatureDebugGraph
		for v134_ = 1, 24 do
			v133_:setValue(v134_, (self.temperatureUpdater:getTemperatureAtTime(v134_ * 60 * 60 * 1000)))
		end
		v133_:draw()
		local v135_ = self.owner.dayTime / self.owner.dayLength
		renderOverlay(self.temperatureDebugOverlayCurrent, v133_.left + v135_ * v133_.width, v133_.bottom, g_pixelSizeX, v133_.height)
		local v136_ = g_cameraManager:getActiveCamera()
		local v137_, v138_, v139_ = getWorldTranslation(v136_)
		local v140_, v141_, v142_ = localDirectionToWorld(v136_, 0, 0, -1)
		local v143_ = v137_ + 10 * v140_
		local v144_ = v138_ + 10 * v141_
		local v145_ = v139_ + 10 * v142_
		drawDebugArrow(v143_, v144_ + 2, v145_, v112_ * 3, 0, v113_ * 3, 0.3, 0.3, 0.3, 1, 1, 1, false)
	end
end

function Weather:sendInitialState(connection)
	connection:sendEvent(WeatherStateEvent.new(self.snowHeight, self.timeSinceLastRain))
	connection:sendEvent(WeatherAddObjectEvent.new(self.forecastItems, true, true))
end

function Weather:setInitialState(snowHeight, timeSinceLastRain)
	self.snowHeight = snowHeight
	self.timeSinceLastRain = timeSinceLastRain
	g_currentMission.snowSystem:setSnowHeight(self.snowHeight)
end

function Weather:setIsRainAllowed(isRainAllowed)
	self.isRainAllowed = isRainAllowed
end

-- Local values: currentInstance, weatherObject, windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor
function Weather:init(isSavegameInit)
	local v155_ = self.forecastItems[1]
	local v156_ = self:getWeatherObjectByIndex(v155_.season, v155_.objectIndex)
	v156_:activate(v155_, 0, isSavegameInit)
	if v156_.setWindValues ~= nil then
		local v157_, v158_, v159_, v160_ = self.windUpdater:getCurrentValues()
		v156_:setWindValues(v157_, v158_, v159_, v160_)
	end
	self:onWeatherChanged(v156_)
	g_currentMission.snowSystem:setSnowHeight(self.snowHeight)
end

function Weather:onWeatherChanged(weatherObject)
	g_messageCenter:publish(MessageType.WEATHER_CHANGED, weatherObject)
end

-- Local values: currentWeatherObject
function Weather:rebuild()
	if g_currentMission:getIsServer() then
		local v163_ = self:getWeatherObjectByIndex(self.forecastItems[1].season, self.forecastItems[1].objectIndex)
		v163_:deactivate(1)
		v163_:update(9999999)
		self.forecastItems = {}
		self:addStartWeather()
		self:fillWeatherForecast(true)
	end
end

-- Local values: weatherObject, weatherObjectIndex, weatherObjectVariationIndex
function Weather:getRandomWeatherObjectVariation(season, firstWeather)
	local v167_ = self.typeToWeatherObject[season][self.firstWeatherType]
	if v167_ == nil or not firstWeather then
		local v168_ = self.weightedWeatherObjects[season][math.random(1, #self.weightedWeatherObjects[season])]
		v167_ = self.weatherObjects[season][v168_]
	end
	local v169_ = v167_:getRandomVariationIndex()
	return v167_.index, v169_
end

function Weather:getWeatherObjectByIndex(season, index)
	return self.weatherObjects[season][index]
end

function Weather:getForecastInstanceVariation(instance)
	return self.weatherObjects[instance.season][instance.objectIndex]:getVariationByIndex(instance.variationIndex)
end

-- Local values: season, objects, weatherType, weatherObject, i
function Weather:updateAvailableWeatherObjects()
	for v176_, v177_ in pairs(self.typeToWeatherObject) do
		self.weightedWeatherObjects[v176_] = {}
		for _, v178_ in pairs(v177_) do
			if v178_:getIsAvailable() then
				for _ = 1, v178_.weight do
					local v179_ = self.weightedWeatherObjects[v176_]
					local v180_ = v178_.index
					table.insert(v179_, v180_)
				end
			end
		end
	end
end

-- Local values: startDay, startDayTime, endDay, endDayTime, season, weatherInstance
function Weather:addStartWeather()
	local v182_ = self.owner.currentMonotonicDay
	local v183_ = self.owner.dayTime
	local v184_, v185_ = self.owner:getDayAndDayTime(v183_, v182_)
	local v186_ = self.owner:getVisualSeasonAtDay(v182_)
	self:updateAvailableWeatherObjects()
	self:addWeatherForecast((self:createRandomWeatherInstance(v186_, v184_, v185_, true)))
end

-- Local values: newObjects, lastItem, maxNumOfforecastItemsItems, startDay, startDayTime, endDay, endDayTime, season, weatherInstance
function Weather:fillWeatherForecast(isRebuild)
	self:updateAvailableWeatherObjects()
	local v189_ = self.forecastItems[#self.forecastItems]
	local v190_ = 2 ^ Weather.SEND_BITS_NUM_OBJECTS - 1
	local v191_ = {}
	while (v189_ == nil or v189_.startDay < self.owner.currentMonotonicDay + 9) and #self.forecastItems < v190_ do
		local v192_ = self.owner.currentMonotonicDay
		local v193_ = self.owner.dayTime
		if v189_ ~= nil then
			v192_ = v189_.startDay
			v193_ = v189_.startDayTime + v189_.duration
		end
		local v194_, v195_ = self.owner:getDayAndDayTime(v193_, v192_)
		local v196_ = self:createRandomWeatherInstance(self.owner:getVisualSeasonAtDay(v194_), v194_, v195_, false)
		self:addWeatherForecast(v196_)
		table.insert(v191_, v196_)
		v189_ = self.forecastItems[#self.forecastItems]
	end
	if #v191_ > 0 then
		if isRebuild then
			v191_ = self.forecastItems
		end
		g_server:broadcastEvent(WeatherAddObjectEvent.new(v191_, isRebuild or false), false)
	end
end

-- Local values: weatherObjectIndex, weatherObjectVariationIndex, weatherObject, variation, duration, _, seasonNextDay, isSeasonBoundary, wholeDay, timeBeforeMidnight, extensionTime
function Weather:createRandomWeatherInstance(season, startDay, startDayTime, firstWeather)
	local v202_, v203_ = self:getRandomWeatherObjectVariation(season, firstWeather)
	local v204_ = self:getWeatherObjectByIndex(season, v202_):getVariationByIndex(v203_)
	local v205_ = MathUtil.hoursToMs
	local v206_ = math.random(v204_.minHours, v204_.maxHours)
	local v207_ = v205_((math.max(v206_, 1)))
	local v208_ = season ~= self.owner:getVisualSeasonAtDay(startDay + 1)
	local v209_, _ = math.modf(startDayTime)
	if v208_ then
		if v209_ + v207_ > 86400000 then
			v207_ = 86400000 - v209_
		end
		local v210_ = 86400000 - v209_ - v207_
		if v210_ > 0 and v210_ < 10800000 then
			v207_ = 86400000 - v209_
		end
	end
	return WeatherInstance.createInstance(v202_, v203_, startDay, v209_, v207_, season)
end

function Weather:addWeatherForecast(weatherInstance)
	local v213_ = self.forecastItems
	table.insert(v213_, weatherInstance)
end

function Weather:getIsReady()
	return #self.forecastItems > 0
end

function Weather:onTimeScaleChanged()
	self.cloudUpdater:setTimeScale(g_currentMission:getEffectiveTimeScale())
end

function Weather:getForecast()
	return self.forecast
end

function Weather:getRainFallScale()
	return self.rainUpdater:getRainFallScale()
end

function Weather:getSnowFallScale()
	return self.rainUpdater:getSnowFallScale()
end

function Weather:getHailFallScale()
	return self.rainUpdater:getHailFallScale()
end

function Weather:getIsHailing()
	return self:getHailFallScale() > 0.05
end

function Weather:getIsRaining()
	return self:getRainFallScale() > 0.05
end

function Weather:getIsSnowing()
	return self:getSnowFallScale() > 0.05
end

-- Local values: cloudUpdater, cloudEnvMapIndex1, cloudEnvMapIndex2, alpha
function Weather:getCloudEnvMapInfo()
	local v224_ = self.cloudUpdater
	return v224_.lastClouds.envMapCloudProbeIndex, v224_.targetClouds.envMapCloudProbeIndex, v224_.alpha
end

-- Local values: k, instance, object
function Weather:getTimeUntilRain()
	for v226_ = 1, #self.forecastItems do
		local v227_ = self.forecastItems[v226_]
		local v228_ = self:getWeatherObjectByIndex(v227_.season, v227_.objectIndex)
		if v227_.startDay == self.owner.currentMonotonicDay and (v228_.weatherType == WeatherType.RAIN or v228_.weatherType == WeatherType.SNOW) and self.owner.dayTime < v227_.startDayTime then
			return v227_.startDayTime - self.owner.dayTime
		end
	end
	return math.huge
end

function Weather:getTimeSinceLastRain()
	return MathUtil.msToMinutes(self.timeSinceLastRain)
end

function Weather:getGroundWetness()
	return self.groundWetness
end

-- Local values: instance, _, object, object
function Weather:getWeatherTypeAtTime(day, dayTime)
	if g_client ~= nil and #self.forecastItems == 0 then
		return WeatherType.SUN
	end
	local v234_ = self.forecastItems[1]
	for _, v235_ in ipairs(self.forecastItems) do
		if v235_.startDay >= day and (v235_.startDay ~= day or v235_.startDayTime >= dayTime) then
			break
		end
		v234_ = v235_
	end
	return self:getWeatherObjectByIndex(v234_.season, v234_.objectIndex).weatherType
end

function Weather:getCurrentMinMaxTemperatures()
	return self.temperatureUpdater:getCurrentValues()
end

function Weather:getCurrentTemperature()
	return self.temperatureUpdater:getTemperatureAtTime(self.owner.dayTime)
end

-- Local values: currentVariation, nextVariation, avgCurrent, avgNext, change, trend
function Weather:getCurrentTemperatureTrend()
	local v239_ = self:getForecastInstanceVariation(self.forecastItems[1])
	local v240_ = self:getForecastInstanceVariation(self.forecastItems[2])
	local v241_ = (v239_.minTemperature + v239_.maxTemperature) * 0.5 - (v240_.minTemperature + v240_.maxTemperature) * 0.5
	return math.abs(v241_) <= Weather.TEMPERATURE_STABLE_CHANGE and 0 or math.sign(v241_)
end

-- Local values: instance, object
function Weather:getCurrentWeatherType()
	local v243_ = self.forecastItems[1]
	return self:getWeatherObjectByIndex(v243_.season, v243_.objectIndex).weatherType
end

-- Local values: instance, object
function Weather:getNextWeatherType(beforeDay, beforeTime)
	local v247_ = self.forecastItems[2]
	if beforeDay < v247_.startDay or v247_.startDay == beforeDay and beforeTime < v247_.startDayTime then
		v247_ = self.forecastItems[1]
	end
	return self:getWeatherObjectByIndex(v247_.season, v247_.objectIndex).weatherType
end

-- Local values: types
function Weather:getWeatherObjectBySeasonAndType(season, weatherType)
	local v251_ = self.typeToWeatherObject[season]
	if v251_ == nil then
		return nil
	else
		return v251_[weatherType]
	end
end

-- Local values: fog, newSeasonFog
function Weather:randomizeFog(fadeDuration)
	local v254_ = self.seasonToFog[self.owner.currentSeason]
	local v255_
	if v254_ == nil then
		v255_ = nil
	else
		v255_ = v254_:createFromTemplate()
	end
	self.fogUpdater:setTargetFog(v255_, fadeDuration)
end

function Weather:onDayChanged(day)
	self:randomizeFog(MathUtil.hoursToMs(1))
end

function Weather:onPeriodLengthChanged()
	self:rebuild()
end

-- Local values: isInVehicleShop
function Weather:onGameStateChanged(newGameState, oldGameState)
	local v260_ = newGameState == GameState.MENU_SHOP_CONFIG
	if self.rainUpdater ~= nil then
		self.rainUpdater:setVisible(not v260_)
	end
end

-- Local values: env, currentWeatherInstance, currentWeatherObject, weatherType, weatherObject, variation, duration, index, currentInstance, startDay, startDayTime, instance, x, _, z, rotationY, windDirX, windDirZ
function Weather:consoleCommandWeatherTwisterSpawn()
	local v262_ = g_currentMission.environment
	local v263_ = self.forecastItems[1]
	local v264_
	if v263_ == nil then
		v264_ = nil
	else
		v264_ = self:getWeatherObjectByIndex(v263_.season, v263_.objectIndex)
	end
	self.forecastItems = {}
	local v265_ = WeatherType.getByName("TWISTER")
	if v265_ ~= nil then
		local v266_ = self.typeToWeatherObject[v262_.currentSeason][v265_]
		if v266_ ~= nil then
			local v267_ = v266_:getVariationByIndex(v266_:getRandomVariationIndex())
			local v268_ = MathUtil.hoursToMs(math.random(v267_.minHours, v267_.maxHours))
			local v269_ = self.forecastItems[2]
			local v270_
			if v269_ == nil then
				v269_ = self.forecastItems[1]
				if v269_ == nil then
					v270_ = 1
				else
					v270_ = 2
				end
			else
				v270_ = 3
			end
			local v271_ = self.owner.currentMonotonicDay
			local v272_ = self.owner.dayTime
			if v269_ ~= nil then
				v271_ = v269_.startDay
				v272_ = v269_.startDayTime
			end
			local v273_, v274_ = self.owner:getDayAndDayTime(v272_ + v268_, v271_)
			local v275_ = WeatherInstance.createInstance(v266_.index, v267_.index, v273_, v274_, v268_, v262_.currentSeason)
			local v276_, _, v277_ = g_localPlayer:getPosition()
			v275_.twisterStartPosX = v276_
			v275_.twisterStartPosZ = v277_
			local v278_ = self.forecastItems
			table.insert(v278_, v270_, v275_)
			self:fillWeatherForecast()
			if v264_ ~= nil then
				v264_:deactivate(1)
				v264_:update(9999999)
			end
			self:init()
			local v279_ = g_localPlayer:getYaw()
			local v280_, v281_ = MathUtil.getDirectionFromYRotation(v279_)
			self.windUpdater.targetDirX = v280_
			self.windUpdater.targetDirZ = v281_
			return "Spawned twister"
		end
	end
	return "Failed to spawn twister"
end

-- Local values: env, currentWeatherInstance, currentWeatherObject, weatherType, weatherObject, variation, duration, index, currentInstance, startDay, startDayTime, instance, typeNames, weatherTypeIndex, _
function Weather:consoleCommandWeatherSet(typeName, variationIndex)
	local v285_ = g_currentMission.environment
	local v286_ = tonumber(variationIndex)
	local v287_ = self.forecastItems[1]
	local v288_
	if v287_ == nil then
		v288_ = nil
	else
		v288_ = self:getWeatherObjectByIndex(v287_.season, v287_.objectIndex)
	end
	self.forecastItems = {}
	local v289_ = WeatherType.getByName(typeName)
	if v289_ ~= nil then
		local v290_ = self.typeToWeatherObject[v285_.currentSeason][v289_]
		if v290_ ~= nil then
			local v291_ = v290_:getVariationByIndex(v286_ or v290_:getRandomVariationIndex())
			if v291_ == nil then
				v291_ = v290_:getVariationByIndex(v290_:getRandomVariationIndex())
			end
			local v292_ = MathUtil.hoursToMs(math.random(v291_.minHours, v291_.maxHours))
			local v293_ = self.forecastItems[2]
			local v294_
			if v293_ == nil then
				v293_ = self.forecastItems[1]
				if v293_ == nil then
					v294_ = 1
				else
					v294_ = 2
				end
			else
				v294_ = 3
			end
			local v295_ = self.owner.currentMonotonicDay
			local v296_ = self.owner.dayTime
			if v293_ ~= nil then
				v295_ = v293_.startDay
				v296_ = v293_.startDayTime
			end
			local v297_, v298_ = self.owner:getDayAndDayTime(v296_ + v292_, v295_)
			local v299_ = WeatherInstance.createInstance(v290_.index, v291_.index, v297_, v298_, v292_, v285_.currentSeason)
			local v300_ = self.forecastItems
			table.insert(v300_, v294_, v299_)
			self:fillWeatherForecast()
			if v288_ ~= nil then
				v288_:deactivate(1)
				v288_:update(9999999)
			end
			self:init()
			return string.format("Set weather to \'%s\'", string.upper(typeName))
		end
	end
	local v301_ = {}
	for v302_, _ in pairs(self.typeToWeatherObject[v285_.currentSeason]) do
		local v303_ = WeatherType.getName
		table.insert(v301_, v303_(v302_))
	end
	return string.format("Invalid typeName \'%s\': gsWeatherSet <typeName> <variation> | Available typeNames for current season: %s", typeName, table.concat(v301_, ", "))
end

-- Local values: env, weatherType, weatherObject, variation, duration, index, currentInstance, startDay, startDayTime, instance, timeDif, lastDuration, lastStartDayTime, lastStartDay, i, forecastItem, typeNames, weatherTypeIndex, _
function Weather:consoleCommandWeatherAdd(typeName)
	local v306_ = g_currentMission.environment
	local v307_ = WeatherType.getByName(typeName)
	if v307_ ~= nil then
		local v308_ = self.typeToWeatherObject[v306_.currentSeason][v307_]
		if v308_ ~= nil then
			local v309_ = v308_:getVariationByIndex(v308_:getRandomVariationIndex())
			local v310_ = MathUtil.hoursToMs(math.random(v309_.minHours, v309_.maxHours))
			local v311_ = self.forecastItems[2]
			local v312_
			if v311_ == nil then
				v311_ = self.forecastItems[1]
				if v311_ == nil then
					v312_ = 1
				else
					v312_ = 2
				end
			else
				v312_ = 3
			end
			local v313_ = self.owner.currentMonotonicDay
			local v314_ = self.owner.dayTime
			if v311_ ~= nil then
				v313_ = v311_.startDay
				v314_ = v311_.startDayTime
			end
			local v315_, v316_ = self.owner:getDayAndDayTime(v314_ + v311_.duration, v313_)
			local v317_ = WeatherInstance.createInstance(v308_.index, v309_.index, v315_, v316_, v310_, v306_.currentSeason)
			local v318_ = (v317_.startDayTime - self.owner.dayTime) / 60000 + (v315_ - self.owner.currentMonotonicDay) * 24 * 60
			local v319_ = self.forecastItems
			table.insert(v319_, v312_, v317_)
			for v320_ = v312_ + 1, #self.forecastItems do
				local v321_ = self.forecastItems[v320_]
				local v322_, v323_ = self.owner:getDayAndDayTime(v316_ + v310_, v315_)
				v321_.startDay = v322_
				v321_.startDayTime = v323_
				v310_ = v321_.duration
				v316_ = v321_.startDayTime
				v315_ = v321_.startDay
			end
			return string.format("Added state %s. Starts in %d minutes...", typeName, v318_)
		end
	end
	local v324_ = {}
	for v325_, _ in pairs(self.typeToWeatherObject[v306_.currentSeason]) do
		local v326_ = WeatherType.getName
		table.insert(v324_, v326_(v325_))
	end
	return string.format("Invalid typeName \'%s\': gsWeatherAdd <typeName> | Available typeNames for current season: %s", typeName, table.concat(v324_, ", "))
end

function Weather:consoleCommandWeatherToggleDebug()
	Weather.DEBUG_ENABLED = not Weather.DEBUG_ENABLED
	if Weather.DEBUG_ENABLED then
		g_currentMission:addDrawable(self)
	else
		g_currentMission:removeDrawable(self)
	end
	local v328_ = Weather.DEBUG_ENABLED
	return "Weather Debug Enabled: " .. tostring(v328_)
end

-- Local values: xmlFile, forecastItem, currentWeatherObject, season, objects, _, object
function Weather:consoleCommandWeatherReloadData()
	local v330_ = XMLFile.load("weather", self.owner.xmlFilename)
	local v331_ = self.forecastItems[1]
	if v331_ ~= nil then
		local v332_ = self:getWeatherObjectByIndex(v331_.season, v331_.objectIndex)
		v332_:deactivate(1)
		v332_:update(9999999)
	end
	for _, v333_ in ipairs(self.weatherObjects) do
		for _, v334_ in ipairs(v333_) do
			v334_:delete()
		end
	end
	self.weatherObjects = {}
	self.rainUpdater:reset()
	self:load(v330_, "environment")
	v330_:delete()
	return "Reloaded weather data"
end

function Weather:consoleCommandWeatherSetDebugWind(xDir, zDir, speed, cirrusSpeedFactor, duration)
	if g_client == nil then
		return "Client only command"
	end
	local v341_ = tonumber(speed) or 1
	local v342_ = tonumber(xDir) or 1
	local v343_ = tonumber(zDir) or 1
	local v344_ = tonumber(cirrusSpeedFactor) or 1
	local v345_ = tonumber(duration) or 1
	if v341_ > 0 then
		self.windUpdater:setTargetValues(v342_, v343_, v341_, v344_, v345_)
	end
	return "Set debug wind speed " .. v341_ .. ". Command: gsWeatherSetDebugWind <xDir> <zDir> <speed> <cirrusSpeedFactor> <duration>"
end

-- Local values: currentInstance, currentWeatherObject, varIndex, variation, windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor
function Weather:consoleCommandWeatherSetClouds(typeFrom, typeTo, cloudDensityScale, cirrusCloudDensityScale)
	local v351_ = tonumber(typeFrom)
	local v352_ = tonumber(typeTo)
	local v353_ = tonumber(cloudDensityScale)
	local v354_ = tonumber(cirrusCloudDensityScale)
	if v351_ == nil or v352_ == nil then
		return "Invalid usage. Command: gsWeatherSetClouds <typeFrom> <typeTo> <cloudDensityScale> <cirrusCloudDensityScale>"
	end
	local v355_ = self.forecastItems[1]
	local v356_ = self:getWeatherObjectByIndex(v355_.season, v355_.objectIndex)
	local v357_ = v355_.variationIndex
	local v358_ = v356_.variations[v357_]
	v358_.clouds.cloudTypeFrom = v351_
	v358_.clouds.cloudTypeTo = v352_
	v358_.clouds.cloudCoverage = v353_ or v358_.clouds.cloudCoverage
	v358_.clouds.cirrusCloudDensityScale = v354_ or v358_.clouds.cirrusCloudDensityScale
	v356_:activate(v355_, 0.0001)
	if v356_.setWindValues ~= nil then
		local v359_, v360_, v361_, v362_ = self.windUpdater:getCurrentValues()
		v356_:setWindValues(v359_, v360_, v361_, v362_)
	end
	return "Set cloud settings..."
end

function Weather:consoleCommandWeatherToggleRandomWindWaving()
	self.windUpdater.randomWindWaving = not self.windUpdater.randomWindWaving
	return "Random wind waving is now " .. (self.windUpdater.randomWindWaving and "enabled" or "disabled")
end
