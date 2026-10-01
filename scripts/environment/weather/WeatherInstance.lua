WeatherInstance = {}
local WeatherInstance_mt = Class(WeatherInstance)
WeatherInstance.HOURTIME = 3600000
WeatherInstance.MINUTETIME = 60000
function WeatherInstance.new(customMt)
	local self = setmetatable({}, customMt or WeatherInstance_mt)
	self.objectIndex = nil
	self.variationIndex = nil
	self.startDay = 0
	self.startDayTime = 0
	self.duration = 0
	self.season = Season.SPRING
	return self
end
function WeatherInstance:saveToXMLFile(xmlFile, key, nextInstance)
	local weather = g_currentMission.environment.weather
	local weatherObject = weather:getWeatherObjectByIndex(self.season, self.objectIndex)
	xmlFile:setString(key .. "#typeName", WeatherType.getName(weatherObject.weatherType))
	xmlFile:setString(key .. "#season", Season.getName(self.season))
	xmlFile:setInt(key .. "#variationIndex", self.variationIndex)
	xmlFile:setInt(key .. "#startDay", self.startDay)
	xmlFile:setInt(key .. "#startDayTime", self.startDayTime)
	xmlFile:setInt(key .. "#duration", self.duration)
	if nextInstance ~= nil then
		local currentDay = weather.owner.currentMonotonicDay
		local currentDayTime = weather.owner.dayTime
		local durationLeft = 0
		if currentDay < nextInstance.startDay then
			currentDay = currentDay + 1
			durationLeft = 86400000 - currentDayTime
			durationLeft = durationLeft + math.max(0, nextInstance.startDay - currentDay - 1) * 24 * 60 * 60 * 1000
			durationLeft = durationLeft + nextInstance.startDayTime
		else
			durationLeft = nextInstance.startDayTime - currentDayTime
		end
		xmlFile:setInt(key .. "#durationLeft", durationLeft)
	end
	if weatherObject.saveInstanceDataToXMLFile ~= nil then
		weatherObject.saveInstanceDataToXMLFile(xmlFile, key, self)
	end
end
function WeatherInstance:loadFromXMLFile(xmlFile, key)
	local weather = g_currentMission.environment.weather
	local seasonName = xmlFile:getString(key .. "#season")
	local weatherTypeName = xmlFile:getString(key .. "#typeName")
	local season = Season.getByName(seasonName) or Season.SUMMER
	local weatherType = WeatherType.getByName(weatherTypeName)
	local weatherObject = weather:getWeatherObjectBySeasonAndType(season, weatherType)
	if weatherObject == nil then
		Logging.xmlWarning(xmlFile, "Failed to load forecast weather instance. WeatherObject '%s' not defined for '%s'!", weatherTypeName, key)
		return false
	end
	local variationIndex = xmlFile:getInt(key .. "#variationIndex")
	local variation = weatherObject:getVariationByIndex(variationIndex)
	if variation == nil then
		Logging.xmlWarning(xmlFile, "Failed to load forecast weather instance. WeatherObject variationIndex '%s' not defined for weather object '%s' for '%s'!", weatherTypeName, variationIndex, key)
		return false
	end
	local duration = xmlFile:getInt(key .. "#duration")
	if duration == nil then
		Logging.xmlWarning(xmlFile, "Failed to load forecast weather instance. Missing duration for '%s'!", key)
		return false
	end
	if duration < 60000 then
		Logging.xmlWarning(xmlFile, "Failed to load forecast weather instance. Duration '%s' too low for '%s'!", duration, key)
		return false
	end
	local startDay = xmlFile:getInt(key .. "#startDay")
	if startDay == nil then
		Logging.xmlWarning(xmlFile, "Failed to load forecast weather instance. Missing startDay for '%s'!", key)
		return false
	end
	local startDayTime = xmlFile:getInt(key .. "#startDayTime")
	if startDayTime == nil then
		Logging.xmlWarning(xmlFile, "Failed to load forecast weather instance. Missing startDayTime for '%s'!", key)
		return false
	else
		local durationLeft = xmlFile:getInt(key .. "#durationLeft")
		if durationLeft ~= nil then
			startDayTime = startDayTime - (duration - durationLeft)
			if startDayTime < 0 then
				startDay = startDay - 1
				startDayTime = startDayTime + 86400000
			end
		end
		self.objectIndex = weatherObject.index
		self.variationIndex = variationIndex
		self.startDay = startDay
		self.startDayTime = startDayTime
		self.duration = duration
		self.season = season
		if weatherObject.loadInstanceDataFromXMLFile ~= nil and not weatherObject.loadInstanceDataFromXMLFile(xmlFile, key, self) then
			return false
		end
		return true
	end
end
function WeatherInstance:readStream(streamId, connection)
	self.objectIndex = streamReadUIntN(streamId, Weather.SEND_BITS_OBJECT_INDEX) + 1
	self.variationIndex = streamReadUIntN(streamId, Weather.SEND_BITS_OBJECT_VARIATION_INDEX) + 1
	self.startDay = streamReadInt32(streamId)
	self.startDayTime = streamReadUIntN(streamId, Weather.SEND_BITS_STARTTIME) * 60 * 1000
	self.duration = (streamReadUIntN(streamId, Weather.SEND_BITS_DURATION) + 1) * 60 * 60 * 1000
	self.season = Season.readStream(streamId)
end
function WeatherInstance:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.objectIndex - 1, Weather.SEND_BITS_OBJECT_INDEX)
	streamWriteUIntN(streamId, self.variationIndex - 1, Weather.SEND_BITS_OBJECT_VARIATION_INDEX)
	streamWriteInt32(streamId, self.startDay)
	streamWriteUIntN(streamId, self.startDayTime / 60000, Weather.SEND_BITS_STARTTIME)
	streamWriteUIntN(streamId, self.duration / 3600000 - 1, Weather.SEND_BITS_DURATION)
	Season.writeStream(streamId, self.season)
end
function WeatherInstance.createInstance(objectIndex, variationIndex, startDay, startDayTime, duration, season)
	local weather = g_currentMission.environment.weather
	local weatherObject = weather:getWeatherObjectByIndex(season, objectIndex)
	local _ = nil
	local weatherInstance = WeatherInstance.new()
	weatherInstance.objectIndex = objectIndex
	weatherInstance.variationIndex = variationIndex
	weatherInstance.startDay = startDay
	weatherInstance.startDayTime = startDayTime
	weatherInstance.duration = duration
	weatherInstance.season = season
	if weatherObject.initInstanceData ~= nil then
		weatherObject.initInstanceData(weatherObject, weatherInstance)
	end
	return weatherInstance
end
