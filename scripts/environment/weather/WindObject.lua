-- Local values: WindObject_mt
WindObject = {}
WindObject.LAST_ANGLE = math.random(-3.141592653589793, 3.141592653589793)
local WindObject_mt = Class(WindObject)

-- Upvalues: WindObject_mt
-- Local values: self
function WindObject.new(customMt)
	-- upvalues: (copy) WindObject_mt
	local v3_ = customMt or WindObject_mt
	local v4_ = setmetatable({}, v3_)
	v4_.windDirectionX = 1
	v4_.windDirectionZ = 1
	v4_.windVelocity = 1
	v4_.cirrusSpeedFactor = 1
	return v4_
end

-- Local values: windAngle, xDir, zDir
function WindObject:load(xmlFile, key)
	local v8_ = xmlFile:getFloat(key .. "#angle")
	if v8_ == nil then
		v8_ = WindObject.LAST_ANGLE + math.random(-15, 15)
	end
	WindObject.LAST_ANGLE = v8_
	local v9_, v10_ = MathUtil.getDirectionFromYRotation((math.rad(v8_)))
	self.windDirectionX = v9_
	self.windDirectionZ = v10_
	self.windAngle = v8_
	self.windVelocity = MathUtil.kmhToMps(xmlFile:getFloat(key .. "#speed") or 30)
	self.cirrusSpeedFactor = xmlFile:getFloat(key .. "#cirrusSpeedFactor") or 1
end

function WindObject:delete() end

function WindObject:getValues()
	return self.windDirectionX, self.windDirectionZ, self.windVelocity, self.cirrusSpeedFactor
end
