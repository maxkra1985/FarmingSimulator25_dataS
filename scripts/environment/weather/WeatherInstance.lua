-- Local values: WeatherInstance_mt
WeatherInstance = {}
local WeatherInstance_mt = Class(WeatherInstance)
WeatherInstance.HOURTIME = 3600000
WeatherInstance.MINUTETIME = 60000

-- Upvalues: WeatherInstance_mt
-- Local values: self
function WeatherInstance.new(customMt)
	-- upvalues: (copy) WeatherInstance_mt
	local v3_ = customMt or WeatherInstance_mt
	local v4_ = setmetatable({}, v3_)
	v4_.objectIndex = nil
	v4_.variationIndex = nil
	v4_.startDay = 0
	v4_.startDayTime = 0
	v4_.duration = 0
	v4_.season = Season.SPRING
	return v4_
end

-- Local values: weather, weatherObject, currentDay, currentDayTime, durationLeft
function WeatherInstance:saveToXMLFile(xmlFile, key, nextInstance)
	local v9_ = g_currentMission.environment.weather
	local v10_ = v9_:getWeatherObjectByIndex(self.season, self.objectIndex)
	xmlFile:setString(key .. "#typeName", WeatherType.getName(v10_.weatherType))
	xmlFile:setString(key .. "#season", Season.getName(self.season))
	xmlFile:setInt(key .. "#variationIndex", self.variationIndex)
	xmlFile:setInt(key .. "#startDay", self.startDay)
	xmlFile:setInt(key .. "#startDayTime", self.startDayTime)
	xmlFile:setInt(key .. "#duration", self.duration)
	if nextInstance ~= nil then
		local v11_ = v9_.owner.currentMonotonicDay
		local v12_ = v9_.owner.dayTime
		local v13_
		if v11_ < nextInstance.startDay then
			local v14_ = v11_ + 1
			local v15_ = 86400000 - v12_
			local v16_ = nextInstance.startDay - v14_ - 1
			v13_ = v15_ + math.max(0, v16_) * 24 * 60 * 60 * 1000 + nextInstance.startDayTime
		else
			v13_ = nextInstance.startDayTime - v12_
		end
		xmlFile:setInt(key .. "#durationLeft", v13_)
	end
	if v10_.saveInstanceDataToXMLFile ~= nil then
		v10_.saveInstanceDataToXMLFile(xmlFile, key, self)
	end
end

-- Local values: weather, seasonName, weatherTypeName, season, weatherType, weatherObject, variationIndex, variation, duration, startDay, startDayTime, durationLeft
function WeatherInstance:loadFromXMLFile(xmlFile, key)
	local v20_ = g_currentMission.environment.weather
	local v21_ = xmlFile:getString(key .. "#season")
	local v22_ = xmlFile:getString(key .. "#typeName")
	local v23_ = Season.getByName(v21_) or Season.SUMMER
	local v24_ = v20_:getWeatherObjectBySeasonAndType(v23_, (WeatherType.getByName(v22_)))
	if v24_ == nil then
		Logging.xmlWarning(xmlFile, "Failed to load forecast weather instance. WeatherObject \'%s\' not defined for \'%s\'!", v22_, key)
		return false
	end
	local v25_ = xmlFile:getInt(key .. "#variationIndex")
	if v24_:getVariationByIndex(v25_) == nil then
		Logging.xmlWarning(xmlFile, "Failed to load forecast weather instance. WeatherObject variationIndex \'%s\' not defined for weather object \'%s\' for \'%s\'!", v22_, v25_, key)
		return false
	end
	local v26_ = xmlFile:getInt(key .. "#duration")
	if v26_ == nil then
		Logging.xmlWarning(xmlFile, "Failed to load forecast weather instance. Missing duration for \'%s\'!", key)
		return false
	end
	if v26_ < 60000 then
		Logging.xmlWarning(xmlFile, "Failed to load forecast weather instance. Duration \'%s\' too low for \'%s\'!", v26_, key)
		return false
	end
	local v27_ = xmlFile:getInt(key .. "#startDay")
	if v27_ == nil then
		Logging.xmlWarning(xmlFile, "Failed to load forecast weather instance. Missing startDay for \'%s\'!", key)
		return false
	end
	local v28_ = xmlFile:getInt(key .. "#startDayTime")
	if v28_ == nil then
		Logging.xmlWarning(xmlFile, "Failed to load forecast weather instance. Missing startDayTime for \'%s\'!", key)
		return false
	end
	local v29_ = xmlFile:getInt(key .. "#durationLeft")
	if v29_ ~= nil then
		v28_ = v28_ - (v26_ - v29_)
		if v28_ < 0 then
			v27_ = v27_ - 1
			v28_ = v28_ + 86400000
		end
	end
	self.objectIndex = v24_.index
	self.variationIndex = v25_
	self.startDay = v27_
	self.startDayTime = v28_
	self.duration = v26_
	self.season = v23_
	return (v24_.loadInstanceDataFromXMLFile == nil or v24_.loadInstanceDataFromXMLFile(xmlFile, key, self)) and true or false
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

-- Local values: weather, weatherObject, _, weatherInstance
function WeatherInstance.createInstance(objectIndex, variationIndex, startDay, startDayTime, duration, season)
	local v40_ = g_currentMission.environment.weather:getWeatherObjectByIndex(season, objectIndex)
	local v41_ = WeatherInstance.new()
	v41_.objectIndex = objectIndex
	v41_.variationIndex = variationIndex
	v41_.startDay = startDay
	v41_.startDayTime = startDayTime
	v41_.duration = duration
	v41_.season = season
	if v40_.initInstanceData ~= nil then
		v40_.initInstanceData(v40_, v41_)
	end
	return v41_
end
