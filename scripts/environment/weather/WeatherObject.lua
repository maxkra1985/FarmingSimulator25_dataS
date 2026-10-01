WeatherObject = {}
local WeatherObject_mt = Class(WeatherObject)
function WeatherObject.new(weatherType, cloudUpdater, temperatureUpdater, windUpdater, rainUpdater, customMt)
	local self = setmetatable({}, customMt or WeatherObject_mt)
	self.weatherType = weatherType
	self.temperatureUpdater = temperatureUpdater
	self.cloudUpdater = cloudUpdater
	self.windUpdater = windUpdater
	self.rainUpdater = rainUpdater
	self.variations = {}
	self.weightedVariations = {}
	return self
end
function WeatherObject:getIsAvailable()
	return true
end
function WeatherObject:load(xmlFile, key, baseDirectory)
	self.weight = xmlFile:getInt(key .. "#weight", 1)
	local maxVariations = 2 ^ Weather.SEND_BITS_OBJECT_VARIATION_INDEX - 1
	for _, variationKey in xmlFile:iterator(key .. ".variation") do
		if maxVariations < #self.variations then
			Logging.xmlWarning(xmlFile, "Weather object variation limit (%d) readed at '%s'", maxVariations, variationKey)
			break
		end
		local variation = self:loadVariation(xmlFile, variationKey, baseDirectory)
		if variation == nil then
			continue
		end
		table.insert(self.variations, variation)
		variation.index = #self.variations
		for _ = 1, variation.weight do
			table.insert(self.weightedVariations, variation.index)
		end
	end
	return true
end
function WeatherObject:getMinDuration()
	return 1
end
function WeatherObject:loadVariation(xmlFile, key, cloudPresets, baseDirectory)
	local variation = {}
	local minDuration = self:getMinDuration()
	variation.weight = xmlFile:getInt(key .. "#weight", 1)
	variation.minHours = math.clamp(xmlFile:getInt(key .. "#minHours", 5), 1, 2 ^ Weather.SEND_BITS_DURATION - 1)
	if variation.minHours < minDuration then
		Logging.xmlWarning(xmlFile, "MinHours needs to be greater than %.1f hours for variation '%s'!", minDuration, key)
		variation.minHours = minDuration
	end
	variation.maxHours = math.clamp(xmlFile:getInt(key .. "#maxHours", 10), 3, 2 ^ Weather.SEND_BITS_DURATION - 1)
	if variation.maxHours < variation.minHours then
		Logging.xmlWarning(xmlFile, "MaxHours needs to be greater than minHours! for variation '%s'", key)
		variation.maxHours = variation.minHours
	end
	local minTemperature = xmlFile:getInt(key .. "#minTemperature", 15)
	local maxTemperature = xmlFile:getInt(key .. "#maxTemperature", 25)
	local maxSendTemp = 2 ^ Weather.SEND_BITS_TEMPERATURE
	if maxSendTemp < minTemperature then
		minTemperature = maxSendTemp
		Logging.xmlWarning(xmlFile, "Min temperature is too high. Maximum is %d for variation '%s'", maxSendTemp, key)
	elseif maxSendTemp < maxTemperature then
		maxTemperature = maxSendTemp
		Logging.xmlWarning(xmlFile, "Max temperature is too high. Maximum is %d for variation '%s'", maxSendTemp, key)
	end
	if maxTemperature < minTemperature then
		local minCopy = minTemperature
		minTemperature = maxTemperature
		maxTemperature = minCopy
	end
	variation.minTemperature = minTemperature
	variation.maxTemperature = maxTemperature
	local cloudKey = key .. ".clouds#presetId"
	local presetId = xmlFile:getString(cloudKey)
	local cloudSettings = self.cloudUpdater:createCloudSettingsFromPreset(presetId)
	if cloudSettings == nil then
		Logging.xmlWarning(xmlFile, "Clouds presetId '%s' is not defined for '%s'", presetId, cloudKey)
		return nil
	else
		variation.clouds = cloudSettings
		local rainKey = key .. ".rain#presetId"
		local rainPresetId = xmlFile:getString(rainKey)
		if rainPresetId ~= nil then
			local rainSettings = self.rainUpdater:createRainSettingsFromPreset(rainPresetId)
			if rainSettings ~= nil then
				variation.rain = rainSettings
				variation.rainPresetId = rainPresetId
			else
				Logging.xmlWarning(xmlFile, "Rain presetId '%s' is not defined for '%s'", rainPresetId, rainKey)
			end
		end
		variation.wind = WindObject.new()
		variation.wind:load(xmlFile, key .. ".wind")
		return variation
	end
end
function WeatherObject:getRandomVariationIndex()
	return self.weightedVariations[math.random(1, #self.weightedVariations)]
end
function WeatherObject:getVariationByIndex(index)
	if index == nil then
		return nil
	else
		return self.variations[index]
	end
end
function WeatherObject:delete() end
function WeatherObject:update(scaledDt) end
function WeatherObject:activate(weatherInstance, blendDuration, isSavegameInit)
	local variationIndex = weatherInstance.variationIndex
	local variation = self.variations[variationIndex]
	local clouds = variation.clouds
	local wind = variation.wind
	local rain = variation.rain
	self.rainUpdater:setTargetRain(rain, blendDuration)
	self.cloudUpdater:setTargetClouds(clouds, blendDuration)
	self.temperatureUpdater:setTargetValues(variation.minTemperature, variation.maxTemperature, blendDuration == 0)
	self.windUpdater:setTargetValues(wind.windDirectionX, wind.windDirectionZ, wind.windVelocity, wind.cirrusSpeedFactor, blendDuration)
end
function WeatherObject:deactivate(blendDuration) end
