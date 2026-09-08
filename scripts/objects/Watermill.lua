-- Local values: Watermill_mt
Watermill = {}
local Watermill_mt = Class(Watermill)

function Watermill:onCreate(id)
	g_currentMission:addUpdateable(Watermill.new(id))
end

-- Upvalues: Watermill_mt
-- Local values: self
function Watermill.new(name)
	-- upvalues: (copy) Watermill_mt
	local v4_ = Watermill_mt
	local v5_ = setmetatable({}, v4_)
	v5_.wheelId = getChildAt(name, 0)
	return v5_
end

function Watermill:delete() end

function Watermill:update(dt)
	rotate(self.wheelId, -0.0005 * dt, 0, 0)
end
