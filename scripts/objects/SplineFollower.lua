-- Local values: SplineFollower_mt
SplineFollower = {}
local SplineFollower_mt = Class(SplineFollower)

function SplineFollower:onCreate(node)
	SplineFollower.new(node)
end

-- Upvalues: SplineFollower_mt
-- Local values: self, length
function SplineFollower.new(node)
	-- upvalues: (copy) SplineFollower_mt
	local v4_ = SplineFollower_mt
	local v5_ = setmetatable({}, v4_)
	v5_.spline = node
	v5_.follower = getChildAt(node, 0)
	local v6_ = getSplineLength(v5_.spline)
	v5_.speed = Utils.getNoNil(getUserAttribute(node, "speed"), 1)
	if v6_ ~= 0 then
		v5_.speed = v5_.speed / v6_
	end
	v5_.speed = v5_.speed / 1000
	v5_.splinePos = 0
	g_currentMission:addUpdateable(v5_)
	return v5_
end

function SplineFollower:delete() end

-- Local values: x, y, z
function SplineFollower:update(dt)
	self.splinePos = self.splinePos + dt * self.speed
	if self.splinePos > 1 then
		self.splinePos = self.splinePos - 1
	end
	local v9_, v10_, v11_ = getSplinePosition(self.spline, self.splinePos)
	setWorldTranslation(self.follower, v9_, v10_, v11_)
end
