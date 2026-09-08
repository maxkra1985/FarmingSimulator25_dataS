-- Local values: Rotator_mt
Rotator = {}
local Rotator_mt = Class(Rotator)

function Rotator:onCreate(id)
	g_currentMission:addUpdateable(Rotator.new(id))
end

-- Upvalues: Rotator_mt
-- Local values: self, rpm, axis
function Rotator.new(node)
	-- upvalues: (copy) Rotator_mt
	local v4_ = Rotator_mt
	local v5_ = setmetatable({}, v4_)
	v5_.axisTable = { 0, 0, 0 }
	v5_.rotationNode = node
	local v6_ = getUserAttribute
	local v7_ = tonumber(v6_(node, "rpm"))
	if v7_ == nil then
		local v8_ = Utils.getNoNil
		local v9_ = getUserAttribute
		v5_.speed = v8_(tonumber(v9_(node, "speed")), 0.0012)
	else
		v5_.speed = v7_ * 2 * 3.141592653589793 / 60 / 1000
	end
	local v10_ = Utils.getNoNil(getUserAttribute(node, "axis"), 3)
	v5_.axisTable[v10_] = 1
	return v5_
end

function Rotator:delete() end

function Rotator:update(dt)
	rotate(self.rotationNode, self.axisTable[1] * self.speed * dt, self.axisTable[2] * self.speed * dt, self.axisTable[3] * self.speed * dt)
end
