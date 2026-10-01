Watermill = {}
local Watermill_mt = Class(Watermill)
function Watermill:onCreate(id)
	g_currentMission:addUpdateable(Watermill.new(id))
end
function Watermill.new(name)
	local self = setmetatable({}, Watermill_mt)
	self.wheelId = getChildAt(name, 0)
	return self
end
function Watermill:delete() end
function Watermill:update(dt)
	rotate(self.wheelId, -0.0005 * dt, 0, 0)
end
