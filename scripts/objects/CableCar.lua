-- Local values: CableCar_mt
CableCar = {}
local CableCar_mt = Class(CableCar)

function CableCar:onCreate(id)
	g_currentMission:addUpdateable(CableCar.new(id))
end

-- Upvalues: CableCar_mt
-- Local values: self, length, numCableCars, i, cableCarId
function CableCar.new(id)
	-- upvalues: (copy) CableCar_mt
	local v4_ = CableCar_mt
	local v5_ = setmetatable({}, v4_)
	v5_.nurbsId = getChildAt(id, 0)
	v5_.cableCarIds = {}
	local v6_ = v5_.cableCarIds
	local v7_ = getChildAt
	table.insert(v6_, v7_(id, 1))
	v5_.times = {}
	local v8_ = v5_.times
	table.insert(v8_, 0)
	v5_.truckIds = {}
	local v9_ = v5_.truckIds
	local v10_ = getChildAt
	local v11_ = getChildAt(id, 1)
	table.insert(v9_, v10_(v11_, 0))
	local v12_ = getSplineLength(v5_.nurbsId)
	v5_.timeScale = Utils.getNoNil(getUserAttribute(id, "speed"), 10) / 3.6
	local v13_ = Utils.getNoNil(getUserAttribute(id, "numCableCars"), 1)
	for v14_ = 2, v13_ do
		local v15_ = clone(v5_.cableCarIds[1], false, true)
		link(id, v15_)
		local v16_ = v5_.cableCarIds
		table.insert(v16_, v15_)
		local v17_ = v5_.times
		local v18_ = 1 / v13_ * (v14_ - 1)
		table.insert(v17_, v18_)
		local v19_ = v5_.truckIds
		local v20_ = getChildAt
		table.insert(v19_, v20_(v15_, 0))
	end
	if v12_ ~= 0 then
		v5_.timeScale = v5_.timeScale / v12_
	end
	return v5_
end

function CableCar:delete() end

-- Local values: i, x, y, z, dx, dy, dz, _, dy1, dz1
function CableCar:update(dt)
	for v23_ = 1, #self.cableCarIds do
		self.times[v23_] = self.times[v23_] - 0.001 * dt * self.timeScale
		if self.times[v23_] < 0 then
			self.times[v23_] = self.times[v23_] + 1
		end
		if self.times[v23_] > 1 then
			self.times[v23_] = self.times[v23_] - 1
		end
		local v24_, v25_, v26_ = getSplinePosition(self.nurbsId, self.times[v23_])
		local v27_, v28_, v29_ = getSplineDirection(self.nurbsId, self.times[v23_])
		setTranslation(self.cableCarIds[v23_], v24_, v25_, v26_)
		setDirection(self.cableCarIds[v23_], v27_, 0, v29_, 0, 1, 0)
		local _, v30_, v31_ = worldDirectionToLocal(self.cableCarIds[v23_], v27_, v28_, v29_)
		setDirection(self.truckIds[v23_], 0, v30_, v31_, 0, 1, 0)
	end
end
