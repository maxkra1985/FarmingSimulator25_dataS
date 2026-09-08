-- Local values: WeatherObject_mt
WeatherObject = {}
local WeatherObject_mt = Class(WeatherObject)

-- Upvalues: WeatherObject_mt
-- Local values: self
function WeatherObject.new(weatherType, cloudUpdater, temperatureUpdater, windUpdater, rainUpdater, customMt)
	-- upvalues: (copy) WeatherObject_mt
	local v8_ = customMt or WeatherObject_mt
	local v9_ = setmetatable({}, v8_)
	v9_.weatherType = weatherType
	v9_.temperatureUpdater = temperatureUpdater
	v9_.cloudUpdater = cloudUpdater
	v9_.windUpdater = windUpdater
	v9_.rainUpdater = rainUpdater
	v9_.variations = {}
	v9_.weightedVariations = {}
	return v9_
end

function WeatherObject:getIsAvailable()
	return true
end

-- Local values: maxVariations, _, variationKey, variation, _
function WeatherObject:load(xmlFile, key, baseDirectory)
	self.weight = xmlFile:getInt(key .. "#weight", 1)
	local v14_ = 2 ^ Weather.SEND_BITS_OBJECT_VARIATION_INDEX - 1
	for _, v15_ in xmlFile:iterator(key .. ".variation") do
		if v14_ < #self.variations then
			Logging.xmlWarning(xmlFile, "Weather object variation limit (%d) readed at \'%s\'", v14_, v15_)
			break
		end
		local v16_ = self:loadVariation(xmlFile, v15_, baseDirectory)
		if v16_ ~= nil then
			local v17_ = self.variations
			table.insert(v17_, v16_)
			v16_.index = #self.variations
			for _ = 1, v16_.weight do
				local v18_ = self.weightedVariations
				local v19_ = v16_.index
				table.insert(v18_, v19_)
			end
		end
	end
	return true
end

function WeatherObject:getMinDuration()
	return 1
end

-- Local values: variation, minDuration, minTemperature, maxTemperature, maxSendTemp, minCopy, cloudKey, presetId, cloudSettings, rainKey, rainPresetId, rainSettings
function WeatherObject:loadVariation(xmlFile, key, cloudPresets, baseDirectory)
	local v23_ = {}
	local v24_ = self:getMinDuration()
	v23_.weight = xmlFile:getInt(key .. "#weight", 1)
	local v25_ = xmlFile:getInt(key .. "#minHours", 5)
	local v26_ = 2 ^ Weather.SEND_BITS_DURATION - 1
	v23_.minHours = math.clamp(v25_, 1, v26_)
	if v23_.minHours < v24_ then
		Logging.xmlWarning(xmlFile, "MinHours needs to be greater than %.1f hours for variation \'%s\'!", v24_, key)
		v23_.minHours = v24_
	end
	local v27_ = xmlFile:getInt(key .. "#maxHours", 10)
	local v28_ = 2 ^ Weather.SEND_BITS_DURATION - 1
	v23_.maxHours = math.clamp(v27_, 3, v28_)
	if v23_.maxHours < v23_.minHours then
		Logging.xmlWarning(xmlFile, "MaxHours needs to be greater than minHours! for variation \'%s\'", key)
		v23_.maxHours = v23_.minHours
	end
	local v29_ = xmlFile:getInt(key .. "#minTemperature", 15)
	local v30_ = xmlFile:getInt(key .. "#maxTemperature", 25)
	local v31_ = 2 ^ Weather.SEND_BITS_TEMPERATURE
	if v31_ < v29_ then
		Logging.xmlWarning(xmlFile, "Min temperature is too high. Maximum is %d for variation \'%s\'", v31_, key)
	elseif v31_ < v30_ then
		Logging.xmlWarning(xmlFile, "Max temperature is too high. Maximum is %d for variation \'%s\'", v31_, key)
		v30_ = v31_
		v31_ = v29_
	else
		v31_ = v29_
	end
	if v30_ >= v31_ then
		local v32_ = v31_
		v31_ = v30_
		v30_ = v32_
	end
	v23_.minTemperature = v30_
	v23_.maxTemperature = v31_
	local v33_ = key .. ".clouds#presetId"
	local v34_ = xmlFile:getString(v33_)
	local v35_ = self.cloudUpdater:createCloudSettingsFromPreset(v34_)
	if v35_ == nil then
		Logging.xmlWarning(xmlFile, "Clouds presetId \'%s\' is not defined for \'%s\'", v34_, v33_)
		return nil
	end
	v23_.clouds = v35_
	local v36_ = key .. ".rain#presetId"
	local v37_ = xmlFile:getString(v36_)
	if v37_ ~= nil then
		local v38_ = self.rainUpdater:createRainSettingsFromPreset(v37_)
		if v38_ == nil then
			Logging.xmlWarning(xmlFile, "Rain presetId \'%s\' is not defined for \'%s\'", v37_, v36_)
		else
			v23_.rain = v38_
			v23_.rainPresetId = v37_
		end
	end
	v23_.wind = WindObject.new()
	v23_.wind:load(xmlFile, key .. ".wind")
	return v23_
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

-- Local values: variationIndex, variation, clouds, wind, rain
function WeatherObject:activate(weatherInstance, blendDuration, isSavegameInit)
	local v45_ = weatherInstance.variationIndex
	local v46_ = self.variations[v45_]
	local v47_ = v46_.clouds
	local v48_ = v46_.wind
	local v49_ = v46_.rain
	self.rainUpdater:setTargetRain(v49_, blendDuration)
	self.cloudUpdater:setTargetClouds(v47_, blendDuration)
	self.temperatureUpdater:setTargetValues(v46_.minTemperature, v46_.maxTemperature, blendDuration == 0)
	self.windUpdater:setTargetValues(v48_.windDirectionX, v48_.windDirectionZ, v48_.windVelocity, v48_.cirrusSpeedFactor, blendDuration)
end

function WeatherObject:deactivate(blendDuration) end
