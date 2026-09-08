-- Local values: FollowerSound_mt
FollowerSound = {}
local FollowerSound_mt = Class(FollowerSound)

function FollowerSound:onCreate(id)
	g_currentMission:addUpdateable(FollowerSound.new(id))
end

-- Upvalues: FollowerSound_mt
-- Local values: self, i, splineCV
function FollowerSound.new(id)
	-- upvalues: (copy) FollowerSound_mt
	local v4_ = FollowerSound_mt
	local v5_ = setmetatable({}, v4_)
	v5_.splineId = getChildAt(id, 0)
	v5_.soundId = getChildAt(id, 1)
	v5_.currentDelay = 200
	v5_.splineCVs = {}
	v5_.followAxis = Utils.getNoNil(getUserAttribute(id, "followAxis"), 1)
	v5_.splineCVCount = getSplineNumOfCV(v5_.splineId)
	v5_.backwards = false
	for v6_ = 1, v5_.splineCVCount do
		local v7_ = {}
		local v8_, v9_, v10_ = getSplineCV(v5_.splineId, v6_ - 1)
		v7_[1] = v8_
		v7_[2] = v9_
		v7_[3] = v10_
		local v11_ = v5_.splineCVs
		table.insert(v11_, v7_)
	end
	if v5_.splineCVs[2][v5_.followAxis] < v5_.splineCVs[1][v5_.followAxis] then
		v5_.backwards = true
	end
	return v5_
end

function FollowerSound:delete() end

-- Local values: localPlayer, playerPosition, i, normalizedPos, newPos, j, normalizedPos, newPos, j
function FollowerSound:update(dt)
	if self.currentDelay > 0 then
		self.currentDelay = self.currentDelay - dt
	else
		self.currentDelay = 200
		local v14_ = { g_localPlayer:getPosition() }
		for v15_ = 1, self.splineCVCount - 1 do
			if v14_[self.followAxis] >= self.splineCVs[v15_][self.followAxis] and v14_[self.followAxis] <= self.splineCVs[v15_ + 1][self.followAxis] then
				local v16_ = (v14_[self.followAxis] - self.splineCVs[v15_][self.followAxis]) / (self.splineCVs[v15_ + 1][self.followAxis] - self.splineCVs[v15_][self.followAxis])
				local v17_ = {}
				for v18_ = 1, 3 do
					v17_[v18_] = (1 - v16_) * self.splineCVs[v15_][v18_] + v16_ * self.splineCVs[v15_ + 1][v18_]
				end
				setTranslation(self.soundId, v17_[1], v17_[2], v17_[3])
			elseif v14_[self.followAxis] <= self.splineCVs[v15_][self.followAxis] and v14_[self.followAxis] >= self.splineCVs[v15_ + 1][self.followAxis] then
				local v19_ = (v14_[self.followAxis] - self.splineCVs[v15_ + 1][self.followAxis]) / (self.splineCVs[v15_][self.followAxis] - self.splineCVs[v15_ + 1][self.followAxis])
				local v20_ = {}
				for v21_ = 1, 3 do
					v20_[v21_] = (1 - v19_) * self.splineCVs[v15_ + 1][v21_] + v19_ * self.splineCVs[v15_][v21_]
				end
				setTranslation(self.soundId, v20_[1], v20_[2], v20_[3])
			end
		end
		if self.backwards then
			if v14_[self.followAxis] < self.splineCVs[self.splineCVCount][self.followAxis] then
				setTranslation(self.soundId, self.splineCVs[self.splineCVCount][1], self.splineCVs[self.splineCVCount][2], self.splineCVs[self.splineCVCount][3])
				return
			end
			if v14_[self.followAxis] > self.splineCVs[1][self.followAxis] then
				setTranslation(self.soundId, self.splineCVs[1][1], self.splineCVs[1][2], self.splineCVs[1][3])
				return
			end
		else
			if v14_[self.followAxis] < self.splineCVs[1][self.followAxis] then
				setTranslation(self.soundId, self.splineCVs[1][1], self.splineCVs[1][2], self.splineCVs[1][3])
				return
			end
			if v14_[self.followAxis] > self.splineCVs[self.splineCVCount][self.followAxis] then
				setTranslation(self.soundId, self.splineCVs[self.splineCVCount][1], self.splineCVs[self.splineCVCount][2], self.splineCVs[self.splineCVCount][3])
			end
		end
	end
end
