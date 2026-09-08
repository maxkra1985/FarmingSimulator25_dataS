-- Local values: Daylight_mt
Daylight = {}
local Daylight_mt = Class(Daylight)

-- Upvalues: Daylight_mt
-- Local values: self
function Daylight.new(customMt)
	-- upvalues: (copy) Daylight_mt
	local v3_ = customMt or Daylight_mt
	local v4_ = setmetatable({}, v3_)
	v4_.latitude = 50
	v4_.latitudeInRadians = 50
	v4_.dayStart = 6
	v4_.dayEnd = 20
	v4_.nightEnd = 8
	v4_.nightStart = 18
	v4_.logicalNightStart = 6
	v4_.logicalNightEnd = 18
	v4_.logicalNightStartMinutes = v4_.logicalNightStart * 60
	v4_.logicalNightEndMinutes = v4_.logicalNightEnd * 60
	v4_:setJulianDay(90)
	return v4_
end

function Daylight:delete() end

function Daylight:load(xmlFile, baseKey)
	self.latitude = xmlFile:getFloat(baseKey .. ".latitude", 50)
	local v8_ = self.latitude
	self.latitudeInRadians = math.rad(v8_)
end

function Daylight:saveToXMLFile(xmlFile, key) end

function Daylight:loadFromXMLFile(xmlFile, key) end

function Daylight:setJulianDay(julianDay)
	if self.julianDay ~= julianDay then
		self.julianDay = julianDay
		local v11_, v12_, v13_, v14_ = self:calculateStartEndOfDay()
		self.dayStart = v11_
		self.dayEnd = v12_
		self.nightEnd = v13_
		self.nightStart = v14_
		self.logicalNightStart = MathUtil.lerp(self.dayEnd, self.nightStart, 0.3)
		self.logicalNightEnd = MathUtil.lerp(self.nightEnd, self.dayStart, 0.8)
		self.logicalNightStartMinutes = self.logicalNightStart * 60
		self.logicalNightEndMinutes = self.logicalNightEnd * 60
		g_messageCenter:publishDelayed(MessageType.DAYLIGHT_CHANGED)
	end
end

function Daylight:getDaylightTimes()
	return self.dayStart, self.dayEnd, self.nightEnd, self.nightStart
end

function Daylight:getLogicalNightTime()
	return self.logicalNightStart, self.logicalNightEnd
end

function Daylight:getSunHeightAngle()
	return self.latitudeInRadians - self:calculateSunDeclination() - 1.5707963267948966
end

-- Local values: dayStart, dayEnd, nightEnd, nightStart, sunDeclination
function Daylight:calculateStartEndOfDay()
	local v19_ = self:calculateSunDeclination()
	local v20_ = self:calculateTime(-12, true, v19_)
	local v21_ = self:calculateTime(-5, false, v19_)
	local v22_ = self:calculateTime(14, false, v19_)
	local v23_ = self:calculateTime(5, true, v19_)
	local v24_ = math.max(v23_, 1.01)
	if v20_ == v21_ then
		v21_ = v21_ + 0.01
	end
	local v25_ = math.min(v22_, 22.99)
	local v26_ = v25_ - 0.01
	return v20_, math.min(v21_, v26_), v24_, v25_
end

-- Local values: denom, latitudeInRadians, gamma
function Daylight:calculateTime(position, isDawn, sunDeclination)
	local v31_ = position * 3.141592653589793 / 180
	local v32_ = self.latitudeInRadians
	local v33_ = (math.sin(v31_) + math.sin(v32_) * math.sin(sunDeclination)) / (math.cos(v32_) * math.cos(sunDeclination))
	local v34_ = v33_ < -1 and 0 or (v33_ > 1 and 24 or 24 - 7.639437268410976 * math.acos(v33_))
	if isDawn then
		local v35_ = 12 - v34_ / 2
		return math.max(v35_, 0.01)
	else
		local v36_ = 12 + v34_ / 2
		return math.min(v36_, 23.99)
	end
end

-- Local values: theta
function Daylight:calculateSunDeclination()
	local v38_ = 0.0086 * (self.julianDay - 186)
	local v39_ = 0.967 * math.tan(v38_)
	local v40_ = 0.216 + 2 * math.atan(v39_)
	local v41_ = 0.4 * math.cos(v40_)
	return math.asin(v41_)
end
