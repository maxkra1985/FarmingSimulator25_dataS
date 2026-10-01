WeatherObjectTwister = {}
local WeatherObjectTwister_mt = Class(WeatherObjectTwister, WeatherObject)
function WeatherObjectTwister.new(weatherType, cloudUpdater, temperatureUpdater, windUpdater, rainUpdater, customMt)
	local self = WeatherObject.new(weatherType, cloudUpdater, temperatureUpdater, windUpdater, rainUpdater, customMt or WeatherObjectTwister_mt)
	self.twisterStartPosX = nil
	self.twisterStartPosZ = nil
	self.twisterMeterPerHour = 150
	return self
end
function WeatherObjectTwister:getIsAvailable()
	local mission = g_currentMission
	if mission.missionInfo.disasterDestructionState == DisasterDestructionState.DISABLED then
		return false
	end
	local environment = mission.environment
	local weather = environment.weather
	if weather.twister == nil then
		return false
	else
		return true
	end
end
function WeatherObjectTwister:getMinDuration()
	return 3
end
function WeatherObjectTwister:loadVariation(xmlFile, key, cloudPresets, baseDirectory)
	local variation = WeatherObjectTwister:superClass().loadVariation(self, xmlFile, key, cloudPresets, baseDirectory)
	if variation ~= nil then
		variation.metersPerHour = xmlFile:getInt(key .. ".twister#metersPerHour", 150)
	end
	return variation
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
function WeatherObjectTwister:activate(weatherInstance, blendDuration, isSavegameInit)
	WeatherObjectTwister:superClass().activate(self, weatherInstance, blendDuration)
	if g_server == nil then
		return
	end
	local mission = g_currentMission
	local weather = mission.environment.weather
	if weather.twister == nil then
		Logging.warning("Try to spawn twister but no twister defined for map")
	elseif mission.missionInfo.disasterDestructionState ~= DisasterDestructionState.DISABLED then
		self.twisterActivationTime = blendDuration
		self.twisterMeterPerHour = weatherInstance.twisterMeterPerHour
		if not isSavegameInit then
			self.twisterStartPosX = weatherInstance.twisterStartPosX
			self.twisterStartPosZ = weatherInstance.twisterStartPosZ
		end
	end
end
function WeatherObjectTwister:deactivate(blendDuration)
	WeatherObjectTwister:superClass().deactivate(self, blendDuration)
	if g_server == nil then
		return
	end
	local mission = g_currentMission
	local weather = mission.environment.weather
	if weather.twister == nil then
		return
	else
		self.twisterActivationTime = nil
		g_server:broadcastEvent(TwisterStopEvent.new(), true)
	end
end
function WeatherObjectTwister.initInstanceData(weatherObject, instance)
	local variationIndex = instance.variationIndex
	local variation = weatherObject.variations[variationIndex]
	instance.twisterMeterPerHour = variation.metersPerHour
	local durationMs = instance.duration
	local durationHours = MathUtil.msToHours(durationMs - 2 * Weather.CHANGE_DURATION)
	local totalMeters = variation.metersPerHour * durationHours
	local terrainSizeHalf = g_currentMission.terrainSize * 0.5
	local minX = -terrainSizeHalf
	local maxX = terrainSizeHalf
	local minZ = -terrainSizeHalf
	local maxZ = terrainSizeHalf
	local wind = variation.wind
	local dirX = wind.windDirectionX
	local dirZ = wind.windDirectionZ
	if 0.0001 < math.abs(dirX) then
		if dirX < 0 then
			minX = minX + totalMeters
		elseif 0 < dirX then
			maxX = maxX - totalMeters
		end
	end
	if 0.0001 < math.abs(dirZ) then
		if dirZ < 0 then
			minZ = minZ + totalMeters
		elseif 0 < dirZ then
			maxZ = maxZ - totalMeters
		end
	end
	if maxX < minX then
		maxX = minX
		minX = maxX
	end
	if maxZ < minZ then
		maxZ = minZ
		minZ = maxZ
	end
	instance.twisterStartPosX = math.round(math.random(minX, maxX))
	instance.twisterStartPosZ = math.round(math.random(minZ, maxZ))
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
