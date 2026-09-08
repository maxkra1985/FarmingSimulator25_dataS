-- Local values: OilPump_mt
OilPump = {}
local OilPump_mt = Class(OilPump)

function OilPump:onCreate(id)
	g_currentMission:addUpdateable(OilPump.new(id))
end

-- Upvalues: OilPump_mt
-- Local values: self
function OilPump.new(name)
	-- upvalues: (copy) OilPump_mt
	local v4_ = OilPump_mt
	local v5_ = setmetatable({}, v4_)
	v5_.axisTable = { 0, 0, 0 }
	v5_.me = name
	v5_.head = getChildAt(v5_.me, 1)
	v5_.cylinders = getChildAt(v5_.me, 2)
	v5_.innerCylinders = getChildAt(v5_.cylinders, 0)
	v5_.speed = 0.0012
	v5_.zRotationMin = 0
	v5_.zRotationMax = MathUtil.degToRad(40)
	v5_.timer = math.random() * 2 * 3.141592653589793
	return v5_
end

function OilPump:delete() end

-- Local values: sinValue, zRotation, fakeValue, xRotation, yScale
function OilPump:update(dt)
	self.timer = self.timer + dt * 0.001
	if self.timer >= 6.283185307179586 then
		self.timer = 0
	end
	local v8_ = self.timer
	local v9_ = (math.sin(v8_) + 1) / 2
	local v10_ = self.zRotationMax * v9_
	local v11_ = v10_ - self.zRotationMax / 2
	local v12_ = 2.105 - 1.977 / math.cos(v11_)
	local v13_ = MathUtil.degToRad(-v12_ * 15)
	local v14_ = 1 + 0.5 * v9_
	setRotation(self.head, 0, 0, v10_)
	setRotation(self.cylinders, 0, 0, v13_)
	setScale(self.innerCylinders, 1, v14_, 1)
end
