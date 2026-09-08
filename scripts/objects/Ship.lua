-- Local values: Ship_mt
Ship = {}
local Ship_mt = Class(Ship)

function Ship:onCreate(id)
	g_currentMission:addUpdateable(Ship.new(id))
end

-- Upvalues: Ship_mt
-- Local values: instance, length, numShips, i, shipId
function Ship.new(id)
	-- upvalues: (copy) Ship_mt
	local v4_ = {}
	local v5_ = Ship_mt
	setmetatable(v4_, v5_)
	v4_.nurbsId = getChildAt(id, 0)
	v4_.shipIds = {}
	local v6_ = v4_.shipIds
	local v7_ = getChildAt
	table.insert(v6_, v7_(id, 1))
	v4_.times = {}
	local v8_ = v4_.times
	table.insert(v8_, 0)
	local v9_ = getSplineLength(v4_.nurbsId)
	v4_.timeScale = Utils.getNoNil(getUserAttribute(id, "speed"), 10) / 3.6
	local v10_ = Utils.getNoNil(getUserAttribute(id, "numShips"), 1)
	for v11_ = 2, v10_ do
		local v12_ = clone(v4_.shipIds[1], false, true)
		link(id, v12_)
		local v13_ = v4_.shipIds
		table.insert(v13_, v12_)
		local v14_ = v4_.times
		local v15_ = 1 / v10_ * (v11_ - 1)
		table.insert(v14_, v15_)
	end
	if v9_ ~= 0 then
		v4_.timeScale = v4_.timeScale / v9_
	end
	v4_.initCount = 0
	return v4_
end

function Ship:delete() end

-- Local values: i, x, y, z, rx, ry, rz
function Ship:update(dt)
	if self.initCount > 0 then
		for v18_ = 1, #self.shipIds do
			self.times[v18_] = self.times[v18_] - 0.001 * dt * self.timeScale
			if self.times[v18_] < 0 then
				self.times[v18_] = self.times[v18_] + 1
			end
			if self.times[v18_] > 1 then
				self.times[v18_] = self.times[v18_] - 1
			end
			local v19_, v20_, v21_ = getSplinePosition(self.nurbsId, self.times[v18_])
			local v22_, v23_, v24_ = getSplineOrientation(self.nurbsId, self.times[v18_], 0, -1, 0)
			setTranslation(self.shipIds[v18_], v19_, v20_, v21_)
			setRotation(self.shipIds[v18_], v22_, v23_, v24_)
		end
	else
		self.initCount = self.initCount + 1
	end
end
