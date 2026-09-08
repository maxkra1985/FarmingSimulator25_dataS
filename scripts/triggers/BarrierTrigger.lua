-- Local values: Barrier_mt
Barrier = {}
local Barrier_mt = Class(Barrier)

function Barrier:onCreate(id)
	g_currentMission:addUpdateable(Barrier.new(id))
end

-- Upvalues: Barrier_mt
-- Local values: self, num, i, childLevel1, barrierId
function Barrier.new(id, customMt)
	-- upvalues: (copy) Barrier_mt
	local v5_ = customMt or Barrier_mt
	local v6_ = setmetatable({}, v5_)
	v6_.triggerId = id
	addTrigger(id, "triggerCallback", v6_)
	v6_.barriers = {}
	for v7_ = 0, getNumOfChildren(id) - 1 do
		local v8_ = getChildAt(id, v7_)
		if v8_ ~= 0 and getNumOfChildren(id) >= 1 then
			local v9_ = getChildAt(v8_, 0)
			if v9_ ~= 0 then
				local v10_ = v6_.barriers
				table.insert(v10_, v9_)
			end
		end
	end
	v6_.isEnabled = true
	v6_.count = 0
	v6_.angle = 90
	v6_.maxAngle = 90
	v6_.minAngle = 0
	return v6_
end

function Barrier:delete()
	removeTrigger(self.triggerId)
end

-- Local values: old, i
function Barrier:update(dt)
	local v14_ = self.angle
	if self.count > 0 then
		if self.angle < self.maxAngle then
			self.angle = self.angle + dt * 0.001 * 60
		end
		if self.angle > self.maxAngle then
			self.angle = self.maxAngle
		end
	else
		if self.angle > self.minAngle then
			self.angle = self.angle - dt * 0.001 * 60
		end
		if self.angle < self.minAngle then
			self.angle = self.minAngle
		end
	end
	if v14_ ~= self.angle then
		for v15_ = 1, #self.barriers do
			setRotation(self.barriers[v15_], 0, 0, MathUtil.degToRad(self.angle))
		end
	end
end

function Barrier:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if onEnter and self.isEnabled then
		self.count = self.count + 1
	elseif onLeave then
		self.count = self.count - 1
	end
end
