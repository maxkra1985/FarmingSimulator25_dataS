-- Local values: Butterfly_mt
Butterfly = {}
local Butterfly_mt = Class(Butterfly)

function Butterfly:onCreate(id)
	g_currentMission:addUpdateable(Butterfly.new(id))
end

-- Upvalues: Butterfly_mt
-- Local values: self, i, butterflyId, splineId, meshId, speed, butterfly
function Butterfly.new(id)
	-- upvalues: (copy) Butterfly_mt
	local v4_ = Butterfly_mt
	local v5_ = setmetatable({}, v4_)
	v5_.id = id
	v5_.butterflies = {}
	for v6_ = 1, getNumOfChildren(id) do
		local v7_ = getChildAt(id, v6_ - 1)
		local v8_ = {
			["butterflyId"] = v7_,
			["splineId"] = getChildAt(v7_, 0),
			["meshId"] = getChildAt(v7_, 1),
			["speed"] = Utils.getNoNil(getUserAttribute(v7_, "speed"), 0.005),
			["splinePos"] = 0
		}
		local v9_ = v5_.butterflies
		table.insert(v9_, v8_)
	end
	v5_.time = 0
	v5_.animTimer = 0
	v5_.animDelay = 100
	v5_.flip = true
	v5_.checkClosestButterflyTimer = 0
	v5_.checkClosestButterflyInterval = 2000
	v5_.activeButterfly = nil
	v5_.isSunOn = true
	return v5_
end

function Butterfly:delete() end

-- Local values: closestDistance, closestButterfly, playerPositionX, playerPositionY, playerPositionZ, butterflyPositionX, butterflyPositionY, butterflyPositionZ, _, butterfly, distance, _, butterfly, _, butterfly, offset1, offset2, x, y, z, rx, ry, rz
function Butterfly:update(dt)
	if g_currentMission.environment.isSunOn ~= self.isSunOn then
		self.isSunOn = g_currentMission.environment.isSunOn
		if self.isSunOn then
			setVisibility(self.id, true)
		else
			setVisibility(self.id, false)
		end
	end
	if self.isSunOn then
		self.checkClosestButterflyTimer = self.checkClosestButterflyTimer - dt
		if self.checkClosestButterflyTimer <= 0 then
			local v12_, v13_, v14_ = g_localPlayer:getPosition()
			local v15_ = 100000000
			local v16_ = nil
			for _, v17_ in pairs(self.butterflies) do
				local v18_, v19_, v20_ = getWorldTranslation(v17_.splineId)
				local v21_ = MathUtil.vector3Length(v12_ - v18_, v13_ - v19_, v14_ - v20_)
				if v21_ < v15_ then
					v16_ = v17_
					v15_ = v21_
				end
			end
			if v15_ < 150 then
				for _, v22_ in pairs(self.butterflies) do
					if v22_.butterflyId == v16_.butterflyId then
						setVisibility(v22_.butterflyId, true)
					else
						setVisibility(v22_.butterflyId, false)
					end
				end
				self.activeButterfly = v16_
			else
				for _, v23_ in pairs(self.butterflies) do
					setVisibility(v23_.butterflyId, false)
				end
				self.activeButterfly = nil
			end
			self.checkClosestButterflyTimer = self.checkClosestButterflyInterval
		end
		if self.activeButterfly ~= nil then
			self.animTimer = self.animTimer - dt
			if self.animTimer <= 0 then
				self.flip = not self.flip
				setVisibility(getChildAt(self.activeButterfly.meshId, 0), self.flip)
				setVisibility(getChildAt(self.activeButterfly.meshId, 1), not self.flip)
				self.animTimer = self.animDelay
			end
			self.time = self.time + dt * math.random() * 1
			self.activeButterfly.splinePos = self.activeButterfly.splinePos + dt * math.random() * 1 * self.activeButterfly.speed * 0.01
			local v24_ = self.time * 0.005
			local v25_ = math.sin(v24_)
			local v26_ = self.time * 0.025
			local v27_ = v25_ * math.cos(v26_) * 0.05
			local v28_ = self.time * 0.0175
			local v29_ = math.sin(v28_)
			local v30_ = self.time * 0.0125
			local v31_ = v29_ * math.cos(v30_) * 0.05
			if self.activeButterfly.splinePos > 1 then
				self.activeButterfly.splinePos = self.activeButterfly.splinePos - 1
			end
			local v32_, v33_, v34_ = getSplinePosition(self.activeButterfly.splineId, self.activeButterfly.splinePos)
			local v35_, v36_, v37_ = getSplineOrientation(self.activeButterfly.splineId, self.activeButterfly.splinePos, 0, -1, 0)
			setTranslation(self.activeButterfly.meshId, v32_ + v27_, v33_ + v31_, v34_ + v27_)
			setRotation(self.activeButterfly.meshId, v35_, v36_, v37_)
		end
	end
end
