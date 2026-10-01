WeatherForecast = {}
WeatherForecast.DAY_LENGTH = 86400000
WeatherForecast.CURVE_TOP_TIME = 0.64788735773
WeatherForecast.CURVE_BOTTOM_TIME = 0.14788735773
WeatherForecast.CLOUD_THRESHOLD = 0.5
local WeatherForecast_mt = Class(WeatherForecast)
function WeatherForecast.new(owner, customMt)
	local self = setmetatable({}, customMt or WeatherForecast_mt)
	self.owner = owner
	return self
end
function WeatherForecast:load() end
function WeatherForecast:delete()
	self.owner = nil
end
function WeatherForecast:getCurrentWeather()
	local weatherType = self.owner:getWeatherTypeAtTime(self.owner.owner.currentMonotonicDay, self.owner.owner.dayTime)
	local windX, windZ, windSpeed = self.owner.windUpdater:getCurrentValues()
	local windAngle = math.deg(MathUtil.getYRotationFromDirection(windX, windZ))
	windAngle = MathUtil.round(windAngle / 45) * 45
	return { windDirection = windAngle, windSpeed = windSpeed, forecastType = weatherType, temperature = self.owner:getCurrentTemperature() }
end
function WeatherForecast:dataForTime(day, time)
	for _, item in ipairs(self.owner.forecastItems) do
		return self.owner:getForecastInstanceVariation(item), item
	end
	return nil
end
function WeatherForecast:getHourlyForecast(hoursFromNow)
	local time = self.owner.owner.dayTime + hoursFromNow * 60 * 60 * 1000
	local day = self.owner.owner.currentMonotonicDay
	if WeatherForecast.DAY_LENGTH < time then
		time = time - WeatherForecast.DAY_LENGTH
		day = day + 1
	end
	local instance, forecastItem = self:dataForTime(day, time)
	if instance == nil then
		return nil
	else
		local startDayTime = time / WeatherForecast.DAY_LENGTH
		local finishDayTime = (time + 3600000) / WeatherForecast.DAY_LENGTH
		local maxTemp = -math.huge
		if startDayTime <= WeatherForecast.CURVE_BOTTOM_TIME then
			if WeatherForecast.CURVE_BOTTOM_TIME <= finishDayTime then
				maxTemp = math.max(maxTemp, self:getTemperatureAtTimeForCurve(WeatherForecast.CURVE_BOTTOM_TIME, instance.minTemperature, instance.maxTemperature))
			elseif startDayTime <= WeatherForecast.CURVE_TOP_TIME then
				if WeatherForecast.CURVE_TOP_TIME <= finishDayTime then
					maxTemp = math.max(maxTemp, self:getTemperatureAtTimeForCurve(WeatherForecast.CURVE_TOP_TIME, instance.minTemperature, instance.maxTemperature))
				end
			end
		end
		maxTemp = math.max(maxTemp, self:getTemperatureAtTimeForCurve(startDayTime, instance.minTemperature, instance.maxTemperature))
		maxTemp = math.max(maxTemp, self:getTemperatureAtTimeForCurve(finishDayTime, instance.minTemperature, instance.maxTemperature))
		local object = self.owner:getWeatherObjectByIndex(forecastItem.season, forecastItem.objectIndex)
		local forecastType = object.weatherType
		local variation = object:getVariationByIndex(forecastItem.variationIndex)
		local windSpeed = variation.wind.windVelocity
		local windDirection = variation.wind.windAngle
		return { time = time, day = day, temperature = maxTemp, windSpeed = windSpeed, windDirection = windDirection, forecastType = forecastType }
	end
end
function WeatherForecast:getDailyForecast(daysFromToday)
	local day = self.owner.owner.currentMonotonicDay + daysFromToday
	local instances = {}
	local minTemp = math.huge
	local maxTemp = -math.huge
	local forecastType = WeatherType.SUN
	local hasSunInForecast = false
	local windSpeed = 0
	local windDirection = 0
	local uncertaintyFactor = math.pow(1.025, daysFromToday - 1)
	local uncertaintySign = 1
	for _, item in ipairs(self.owner.forecastItems) do
		if item.startDay == day or item.startDay == day - 1 and WeatherForecast.DAY_LENGTH < item.startDayTime + item.duration then
			local instance = self.owner:getForecastInstanceVariation(item)
			table.insert(instances, instance)
			local uFactor = uncertaintyFactor
			if uncertaintySign == -1 then
				uFactor = 1 / uFactor
			end
			local start = nil
			local finish = nil
			start = item.startDay == day and 0 or (WeatherForecast.DAY_LENGTH - item.startDayTime) / item.duration
			local endDayTime = item.startDayTime + item.duration
			if WeatherForecast.DAY_LENGTH < item.startDayTime + item.duration then
				if item.startDay == day - 1 then
					finish = 1
				elseif endDayTime <= WeatherForecast.DAY_LENGTH then
					finish = 1
				else
					finish = 1 - (endDayTime - WeatherForecast.DAY_LENGTH) / item.duration
				end
			end
			local startDayTime = (item.startDayTime + item.duration * start) / WeatherForecast.DAY_LENGTH % 1
			local finishDayTime = (item.startDayTime + item.duration * finish) / WeatherForecast.DAY_LENGTH
			if startDayTime <= WeatherForecast.CURVE_BOTTOM_TIME and WeatherForecast.CURVE_BOTTOM_TIME <= finishDayTime then
				minTemp = math.min(minTemp, self:getTemperatureAtTimeForCurve(WeatherForecast.CURVE_BOTTOM_TIME, instance.minTemperature, instance.maxTemperature) / uFactor)
			end
			if startDayTime <= WeatherForecast.CURVE_TOP_TIME and WeatherForecast.CURVE_TOP_TIME <= finishDayTime then
				maxTemp = math.max(maxTemp, self:getTemperatureAtTimeForCurve(WeatherForecast.CURVE_TOP_TIME, instance.minTemperature, instance.maxTemperature) * uFactor)
			end
			local object = self.owner:getWeatherObjectByIndex(item.season, item.objectIndex)
			local weatherType = object.weatherType
			if weatherType == WeatherType.SUN then
				hasSunInForecast = true
				if forecastType == WeatherType.CLOUDY then
					forecastType = WeatherType.PARTIALLY_CLOUDY
				end
			elseif weatherType == WeatherType.CLOUDY then
				if hasSunInForecast and forecastType == WeatherType.SUN then
					forecastType = WeatherType.PARTIALLY_CLOUDY
				end
			elseif weatherType == WeatherType.RAIN then
				forecastType = WeatherType.RAIN
			elseif weatherType == WeatherType.SNOW then
				forecastType = WeatherType.SNOW
			elseif weatherType == WeatherType.TWISTER then
				forecastType = WeatherType.TWISTER
			end
			local variation = object:getVariationByIndex(item.variationIndex)
			if variation.wind ~= nil then
				windSpeed = math.max(windSpeed, variation.wind.windVelocity * uFactor)
				windDirection = (windDirection * (#instances - 1) + variation.wind.windAngle) / #instances
			end
			uncertaintySign = -1 * uncertaintySign
		end
	end
	windDirection = MathUtil.round(windDirection / 45) * 45
	return { day = day, highTemperature = maxTemp, lowTemperature = minTemp, windSpeed = windSpeed, windDirection = windDirection, forecastType = forecastType }
end
function WeatherForecast:getTemperatureAtTimeForCurve(t, curveMin, curveMax)
	local T = 6.283185307179586 * t
	local d = curveMax - curveMin
	local dh = 0.5 * d
	return dh * math.sin(T - 2.5) + curveMin + dh
end
