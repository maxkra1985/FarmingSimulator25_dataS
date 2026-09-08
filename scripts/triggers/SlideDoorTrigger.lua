-- Local values: SlideDoorTrigger_mt
SlideDoorTrigger = {}
local SlideDoorTrigger_mt = Class(SlideDoorTrigger)

function SlideDoorTrigger:onCreate(id)
	g_currentMission:addUpdateable(SlideDoorTrigger.new(id))
end

-- Upvalues: SlideDoorTrigger_mt
-- Local values: self, num, i, slideDoor
function SlideDoorTrigger.new(triggerId)
	-- upvalues: (copy) SlideDoorTrigger_mt
	local v4_ = SlideDoorTrigger_mt
	local v5_ = setmetatable({}, v4_)
	v5_.triggerId = triggerId
	addTrigger(triggerId, "triggerCallback", v5_)
	local v6_ = getNumOfChildren(triggerId)
	v5_.slideDoors = {}
	for v7_ = 1, v6_ do
		local v8_ = {
			["node"] = getChildAt(triggerId, v7_ - 1)
		}
		local v9_, v10_, v11_ = getTranslation(v8_.node)
		v8_.startX = v9_
		v8_.startY = v10_
		v8_.startZ = v11_
		local v12_ = v8_.startX
		local v13_ = Utils.getNoNil
		local v14_ = getUserAttribute(v8_.node, "translateX")
		v8_.endX = v12_ + tonumber(v13_(v14_, "0"))
		local v15_ = v8_.startY
		local v16_ = Utils.getNoNil
		local v17_ = getUserAttribute(v8_.node, "translateY")
		v8_.endY = v15_ + tonumber(v16_(v17_, "0"))
		local v18_ = v8_.startZ
		local v19_ = Utils.getNoNil
		local v20_ = getUserAttribute(v8_.node, "translateZ")
		v8_.endZ = v18_ + tonumber(v19_(v20_, "0"))
		local v21_ = v5_.slideDoors
		table.insert(v21_, v8_)
	end
	v5_.opening = false
	v5_.closing = false
	v5_.pausing = false
	v5_.playerLeft = false
	local v22_ = Utils.getNoNil
	local v23_ = getUserAttribute(triggerId, "speed")
	v5_.speed = tonumber(v22_(v23_, "0.001"))
	local v24_ = Utils.getNoNil
	local v25_ = getUserAttribute(triggerId, "pauseDuration")
	v5_.pauseDuration = tonumber(v24_(v25_, "2000"))
	v5_.pauseTime = v5_.pauseDuration
	v5_.doorPos = 0
	v5_.isEnabled = true
	return v5_
end

function SlideDoorTrigger:delete()
	if self.triggerId ~= nil then
		removeTrigger(self.triggerId)
		self.triggerId = nil
	end
end

-- Local values: moving, _, slideDoor, x, y, z
function SlideDoorTrigger:update(dt)
	if self.isEnabled then
		local v29_ = false
		if self.pausing then
			self.pauseTime = self.pauseTime - dt
			if self.pauseTime <= 0 then
				self.pausing = false
				self.closing = true
			end
		end
		if self.opening then
			v29_ = true
			self.doorPos = self.doorPos + self.speed * dt
			if self.doorPos > 1 then
				self.doorPos = 1
				self.opening = false
				if self.playerLeft then
					self.pausing = true
					self.pauseTime = self.pauseDuration
				end
			end
		end
		if self.closing then
			v29_ = true
			self.doorPos = self.doorPos - self.speed * dt
			if self.doorPos < 0 then
				self.doorPos = 0
				self.closing = false
			end
		end
		if v29_ then
			for _, v30_ in pairs(self.slideDoors) do
				local v31_ = (1 - self.doorPos) * v30_.startX + self.doorPos * v30_.endX
				local v32_ = (1 - self.doorPos) * v30_.startY + self.doorPos * v30_.endY
				local v33_ = (1 - self.doorPos) * v30_.startZ + self.doorPos * v30_.endZ
				setTranslation(v30_.node, v31_, v32_, v33_)
			end
		end
	end
end

function SlideDoorTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if self.isEnabled and (onEnter or onLeave) and g_currentMission.players[otherId] ~= nil then
		if onEnter then
			self.playerLeft = false
			if self.pausing then
				self.pausing = false
			end
			self.opening = true
			self.closing = false
			return
		end
		self.playerLeft = true
		if not self.opening then
			self.pausing = true
			self.pauseTime = self.pauseDuration
		end
	end
end
