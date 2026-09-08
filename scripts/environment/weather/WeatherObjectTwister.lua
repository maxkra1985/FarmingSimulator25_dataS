-- Local values: WeatherObjectTwister_mt
WeatherObjectTwister = {}
local WeatherObjectTwister_mt = Class(WeatherObjectTwister, WeatherObject)

-- Upvalues: WeatherObjectTwister_mt
-- Local values: self
function WeatherObjectTwister.new(weatherType, cloudUpdater, temperatureUpdater, windUpdater, rainUpdater, customMt)
	-- upvalues: (copy) WeatherObjectTwister_mt
	local v8_ = WeatherObject.new(weatherType, cloudUpdater, temperatureUpdater, windUpdater, rainUpdater, customMt or WeatherObjectTwister_mt)
	v8_.twisterStartPosX = nil
	v8_.twisterStartPosZ = nil
	v8_.twisterMeterPerHour = 150
	return v8_
end

-- Local values: mission, environment, weather
function WeatherObjectTwister:getIsAvailable()
	local v9_ = g_currentMission
	if v9_.missionInfo.disasterDestructionState == DisasterDestructionState.DISABLED then
		return false
	else
		return v9_.environment.weather.twister ~= nil
	end
end

function WeatherObjectTwister:getMinDuration()
	return 3
end

-- Local values: variation
function WeatherObjectTwister:loadVariation(xmlFile, key, cloudPresets, baseDirectory)
	local v15_ = WeatherObjectTwister:superClass().loadVariation(self, xmlFile, key, cloudPresets, baseDirectory)
	if v15_ ~= nil then
		v15_.metersPerHour = xmlFile:getInt(key .. ".twister#metersPerHour", 150)
	end
	return v15_
end

function WeatherObjectTwister:update(scaledDt)
	WeatherObjectTwister:superClass().update(self, scaledDt)
	if self.twisterActivationTime ~= nil then
		self.twisterActivationTime = self.twisterActivationTime - scaledDt
		if self.twisterActivationTime <= 0 then
			if g_server ~= nil then
				g_server:broadcastEvent(TwisterStartEvent.new(self.twisterStartPosX, self.twisterStartPosZ, self.twisterMeterPerHour), true)
			end
			self.twisterActivationTime = nil
		end
	end
end

-- Local values: mission, weather
function WeatherObjectTwister:activate(weatherInstance, blendDuration, isSavegameInit)
	WeatherObjectTwister:superClass().activate(self, weatherInstance, blendDuration)
	if g_server == nil then
		return
	else
		local v22_ = g_currentMission
		if v22_.environment.weather.twister == nil then
			Logging.warning("Try to spawn twister but no twister defined for map")
			return
		elseif v22_.missionInfo.disasterDestructionState ~= DisasterDestructionState.DISABLED then
			self.twisterActivationTime = blendDuration
			self.twisterMeterPerHour = weatherInstance.twisterMeterPerHour
			if not isSavegameInit then
				self.twisterStartPosX = weatherInstance.twisterStartPosX
				self.twisterStartPosZ = weatherInstance.twisterStartPosZ
			end
		end
	end
end

-- Local values: mission, weather
function WeatherObjectTwister:deactivate(blendDuration)
	WeatherObjectTwister:superClass().deactivate(self, blendDuration)
	if g_server == nil then
		return
	elseif g_currentMission.environment.weather.twister ~= nil then
		self.twisterActivationTime = nil
		g_server:broadcastEvent(TwisterStopEvent.new(), true)
	end
end

-- Local values: variationIndex, variation, durationMs, durationHours, totalMeters, terrainSizeHalf, minX, maxX, minZ, maxZ, wind, dirX, dirZ
function WeatherObjectTwister.initInstanceData(weatherObject, instance)
	local v27_ = instance.variationIndex
	local v28_ = weatherObject.variations[v27_]
	instance.twisterMeterPerHour = v28_.metersPerHour
	local v29_ = instance.duration
	local v30_ = MathUtil.msToHours(v29_ - 2 * Weather.CHANGE_DURATION)
	local v31_ = v28_.metersPerHour * v30_
	local v32_ = g_currentMission.terrainSize * 0.5
	local v33_ = -v32_
	local v34_ = -v32_
	local v35_ = v28_.wind
	local v36_ = v35_.windDirectionX
	local v37_ = v35_.windDirectionZ
	local v38_
	if math.abs(v36_) > 0.0001 then
		if v36_ < 0 then
			v33_ = v33_ + v31_
			v38_ = v32_
		elseif v36_ > 0 then
			v38_ = v32_ - v31_
		else
			v38_ = v32_
		end
	else
		v38_ = v32_
	end
	if math.abs(v37_) > 0.0001 then
		if v37_ < 0 then
			v34_ = v34_ + v31_
		elseif v37_ > 0 then
			v32_ = v32_ - v31_
		end
	end
	if v38_ >= v33_ then
		local v39_ = v33_
		v33_ = v38_
		v38_ = v39_
	end
	if v32_ >= v34_ then
		local v40_ = v34_
		v34_ = v32_
		v32_ = v40_
	end
	local v41_ = math.random(v38_, v33_)
	instance.twisterStartPosX = math.round(v41_)
	local v42_ = math.random(v32_, v34_)
	instance.twisterStartPosZ = math.round(v42_)
end

function WeatherObjectTwister.saveInstanceDataToXMLFile(xmlFile, key, instance)
	xmlFile:setInt(key .. ".twister#startPosX", instance.twisterStartPosX or 0)
	xmlFile:setInt(key .. ".twister#startPosZ", instance.twisterStartPosZ or 0)
	xmlFile:setInt(key .. ".twister#meterPerHour", instance.twisterMeterPerHour or 0)
end

function WeatherObjectTwister.loadInstanceDataFromXMLFile(xmlFile, key, instance)
	instance.twisterStartPosX = xmlFile:getInt(key .. ".twister#startPosX", 0)
	instance.twisterStartPosZ = xmlFile:getInt(key .. ".twister#startPosZ", 0)
	instance.twisterMeterPerHour = xmlFile:getInt(key .. ".twister#meterPerHour", 0)
	return true
end
