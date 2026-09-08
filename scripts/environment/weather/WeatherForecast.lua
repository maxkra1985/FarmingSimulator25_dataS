-- Local values: WeatherForecast_mt
WeatherForecast = {}
WeatherForecast.DAY_LENGTH = 86400000
WeatherForecast.CURVE_TOP_TIME = 0.64788735773
WeatherForecast.CURVE_BOTTOM_TIME = 0.14788735773
WeatherForecast.CLOUD_THRESHOLD = 0.5
local WeatherForecast_mt = Class(WeatherForecast)

-- Upvalues: WeatherForecast_mt
-- Local values: self
function WeatherForecast.new(owner, customMt)
	-- upvalues: (copy) WeatherForecast_mt
	local v4_ = customMt or WeatherForecast_mt
	local v5_ = setmetatable({}, v4_)
	v5_.owner = owner
	return v5_
end

function WeatherForecast:load() end

function WeatherForecast:delete()
	self.owner = nil
end

-- Local values: weatherType, windX, windZ, windSpeed, windAngle
function WeatherForecast:getCurrentWeather()
	local v8_ = self.owner:getWeatherTypeAtTime(self.owner.owner.currentMonotonicDay, self.owner.owner.dayTime)
	local v9_, v10_, v11_ = self.owner.windUpdater:getCurrentValues()
	local v12_ = MathUtil.getYRotationFromDirection(v9_, v10_)
	local v13_ = math.deg(v12_)
	local v14_ = MathUtil.round(v13_ / 45) * 45
	return {
		["temperature"] = self.owner:getCurrentTemperature(),
		["windDirection"] = v14_,
		["windSpeed"] = v11_,
		["forecastType"] = v8_
	}
end

-- Local values: _, item
function WeatherForecast:dataForTime(day, time)
	for _, v18_ in ipairs(self.owner.forecastItems) do
		if v18_.startDay == day and (v18_.startDayTime <= time and time <= v18_.startDayTime + v18_.duration) or v18_.startDay < day and time <= v18_.startDayTime + v18_.duration - WeatherForecast.DAY_LENGTH then
			return self.owner:getForecastInstanceVariation(v18_), v18_
		end
	end
	return nil
end

-- Local values: time, day, instance, forecastItem, startDayTime, finishDayTime, maxTemp, object, forecastType, variation, windSpeed, windDirection
function WeatherForecast:getHourlyForecast(hoursFromNow)
	local v21_ = self.owner.owner.dayTime + hoursFromNow * 60 * 60 * 1000
	local v22_ = self.owner.owner.currentMonotonicDay
	if WeatherForecast.DAY_LENGTH < v21_ then
		v21_ = v21_ - WeatherForecast.DAY_LENGTH
		v22_ = v22_ + 1
	end
	local v23_, v24_ = self:dataForTime(v22_, v21_)
	if v23_ == nil then
		return nil
	end
	local v25_ = v21_ / WeatherForecast.DAY_LENGTH
	local v26_ = (v21_ + 3600000) / WeatherForecast.DAY_LENGTH
	local v27_ = -math.huge
	if v25_ <= WeatherForecast.CURVE_BOTTOM_TIME and WeatherForecast.CURVE_BOTTOM_TIME <= v26_ then
		local v28_ = WeatherForecast.CURVE_BOTTOM_TIME
		local v29_ = v23_.minTemperature
		local v30_ = v23_.maxTemperature
		v27_ = math.max(v27_, self:getTemperatureAtTimeForCurve(v28_, v29_, v30_))
	elseif v25_ <= WeatherForecast.CURVE_TOP_TIME and WeatherForecast.CURVE_TOP_TIME <= v26_ then
		local v31_ = WeatherForecast.CURVE_TOP_TIME
		local v32_ = v23_.minTemperature
		local v33_ = v23_.maxTemperature
		v27_ = math.max(v27_, self:getTemperatureAtTimeForCurve(v31_, v32_, v33_))
	end
	local v34_ = v23_.minTemperature
	local v35_ = v23_.maxTemperature
	local v36_ = math.max(v27_, self:getTemperatureAtTimeForCurve(v25_, v34_, v35_))
	local v37_ = v23_.minTemperature
	local v38_ = v23_.maxTemperature
	local v39_ = math.max(v36_, self:getTemperatureAtTimeForCurve(v26_, v37_, v38_))
	local v40_ = self.owner:getWeatherObjectByIndex(v24_.season, v24_.objectIndex)
	local v41_ = v40_.weatherType
	local v42_ = v40_:getVariationByIndex(v24_.variationIndex)
	return {
		["time"] = v21_,
		["day"] = v22_,
		["temperature"] = v39_,
		["windSpeed"] = v42_.wind.windVelocity,
		["windDirection"] = v42_.wind.windAngle,
		["forecastType"] = v41_
	}
end

-- Local values: day, instances, minTemp, maxTemp, forecastType, hasSunInForecast, windSpeed, windDirection, uncertaintyFactor, uncertaintySign, _, item, instance, uFactor, start, finish, endDayTime, startDayTime, finishDayTime, object, weatherType, variation
function WeatherForecast:getDailyForecast(daysFromToday)
	local v45_ = self.owner.owner.currentMonotonicDay + daysFromToday
	local v46_ = WeatherType.SUN
	local v47_ = daysFromToday - 1
	local v48_ = math.pow(1.025, v47_)
	local v49_ = math.huge
	local v50_ = -math.huge
	local v51_ = {}
	local v52_ = 1
	local v53_ = false
	local v54_ = 0
	local v55_ = 0
	for _, v56_ in ipairs(self.owner.forecastItems) do
		if v56_.startDay == v45_ or v56_.startDay == v45_ - 1 and v56_.startDayTime + v56_.duration > WeatherForecast.DAY_LENGTH then
			local v57_ = self.owner:getForecastInstanceVariation(v56_)
			table.insert(v51_, v57_)
			local v58_
			if v52_ == -1 then
				v58_ = 1 / v48_
			else
				v58_ = v48_
			end
			local v59_ = v56_.startDay == v45_ and 0 or (WeatherForecast.DAY_LENGTH - v56_.startDayTime) / v56_.duration
			local v60_ = v56_.startDayTime + v56_.duration
			local v61_ = (v56_.startDayTime + v56_.duration > WeatherForecast.DAY_LENGTH and v56_.startDay == v45_ - 1 or v60_ <= WeatherForecast.DAY_LENGTH) and 1 or 1 - (v60_ - WeatherForecast.DAY_LENGTH) / v56_.duration
			local v62_ = (v56_.startDayTime + v56_.duration * v59_) / WeatherForecast.DAY_LENGTH % 1
			local v63_ = (v56_.startDayTime + v56_.duration * v61_) / WeatherForecast.DAY_LENGTH
			if v62_ <= WeatherForecast.CURVE_BOTTOM_TIME and WeatherForecast.CURVE_BOTTOM_TIME <= v63_ then
				local v64_ = self:getTemperatureAtTimeForCurve(WeatherForecast.CURVE_BOTTOM_TIME, v57_.minTemperature, v57_.maxTemperature) / v58_
				v49_ = math.min(v49_, v64_)
			end
			if v62_ <= WeatherForecast.CURVE_TOP_TIME and WeatherForecast.CURVE_TOP_TIME <= v63_ then
				local v65_ = self:getTemperatureAtTimeForCurve(WeatherForecast.CURVE_TOP_TIME, v57_.minTemperature, v57_.maxTemperature) * v58_
				v50_ = math.max(v50_, v65_)
			end
			local v66_ = self.owner:getWeatherObjectByIndex(v56_.season, v56_.objectIndex)
			local v67_ = v66_.weatherType
			if v67_ == WeatherType.SUN then
				v53_ = true
				if v46_ == WeatherType.CLOUDY then
					v46_ = WeatherType.PARTIALLY_CLOUDY
				end
			elseif v67_ == WeatherType.CLOUDY then
				if v53_ and v46_ == WeatherType.SUN then
					v46_ = WeatherType.PARTIALLY_CLOUDY
				end
			elseif v67_ == WeatherType.RAIN then
				v46_ = WeatherType.RAIN
			elseif v67_ == WeatherType.SNOW then
				v46_ = WeatherType.SNOW
			elseif v67_ == WeatherType.TWISTER then
				v46_ = WeatherType.TWISTER
			end
			local v68_ = v66_:getVariationByIndex(v56_.variationIndex)
			if v68_.wind ~= nil then
				local v69_ = v68_.wind.windVelocity * v58_
				v54_ = math.max(v54_, v69_)
				v55_ = (v55_ * (#v51_ - 1) + v68_.wind.windAngle) / #v51_
			end
			v52_ = -1 * v52_
		end
	end
	return {
		["day"] = v45_,
		["highTemperature"] = v50_,
		["lowTemperature"] = v49_,
		["windSpeed"] = v54_,
		["windDirection"] = MathUtil.round(v55_ / 45) * 45,
		["forecastType"] = v46_
	}
end

-- Local values: T, d, dh
function WeatherForecast:getTemperatureAtTimeForCurve(t, curveMin, curveMax)
	local v73_ = 6.283185307179586 * t
	local v74_ = 0.5 * (curveMax - curveMin)
	local v75_ = v73_ - 2.5
	return v74_ * math.sin(v75_) + curveMin + v74_
end
