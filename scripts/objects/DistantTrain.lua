-- Local values: DistantTrain_mt
DistantTrain = {}
local DistantTrain_mt = Class(DistantTrain)

function DistantTrain:onCreate(id)
	g_currentMission:addUpdateable(DistantTrain.new(id))
end

-- Upvalues: DistantTrain_mt
-- Local values: self, dx, _, dz
function DistantTrain.new(id)
	-- upvalues: (copy) DistantTrain_mt
	local v4_ = DistantTrain_mt
	local v5_ = setmetatable({}, v4_)
	v5_.nurbsId = getChildAt(id, 0)
	v5_.distantTrainId = getChildAt(id, 1)
	v5_.time = 1
	v5_.timeScale = Utils.getNoNil(getUserAttribute(id, "speed"), 10) / 100
	v5_.delayMin = Utils.getNoNil(getUserAttribute(id, "delayMin"), 10) * 1000
	v5_.delayMax = Utils.getNoNil(getUserAttribute(id, "delayMax"), 30) * 1000
	v5_.currentDelay = math.random(v5_.delayMin, v5_.delayMax)
	local v6_, _, v7_ = getSplineDirection(v5_.nurbsId, 0.5)
	setDirection(v5_.distantTrainId, v6_, 0, v7_, 0, 1, 0)
	return v5_
end

function DistantTrain:delete() end

-- Local values: x, y, z
function DistantTrain:update(dt)
	if self.currentDelay > 0 then
		self.currentDelay = self.currentDelay - dt
	else
		self.time = self.time - 0.001 * dt * self.timeScale
		if self.time < 0 then
			self.time = 1
			self.currentDelay = math.random(self.delayMin, self.delayMax)
		end
		local v10_, v11_, v12_ = getSplinePosition(self.nurbsId, self.time)
		setTranslation(self.distantTrainId, v10_, v11_, v12_)
	end
end
