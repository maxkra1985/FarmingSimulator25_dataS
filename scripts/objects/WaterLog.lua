-- Local values: WaterLog_mt
WaterLog = {}
WaterLog.STATE_EMERGING = 0
WaterLog.STATE_PAUSING = 1
WaterLog.STATE_MOVING = 2
local WaterLog_mt = Class(WaterLog)

function WaterLog:onCreate(id)
	g_currentMission:addUpdateable(WaterLog.new(id))
end

-- Upvalues: WaterLog_mt
-- Local values: self
function WaterLog.new(id)
	-- upvalues: (copy) WaterLog_mt
	local v4_ = WaterLog_mt
	local v5_ = setmetatable({}, v4_)
	v5_.splineId = getChildAt(id, 0)
	v5_.waterLogId = getChildAt(id, 1)
	v5_.splinePos = 0
	v5_.speed = Utils.getNoNil(getUserAttribute(id, "speed"), 0.001)
	v5_.emergeTime = Utils.getNoNil(getUserAttribute(id, "emergeTime"), 15000)
	v5_.emergeTimer = v5_.emergeTime
	v5_.pauseTime = Utils.getNoNil(getUserAttribute(id, "pauseTime"), 15000)
	v5_.pauseTimer = v5_.pauseTime
	v5_.state = WaterLog.STATE_EMERGING
	return v5_
end

function WaterLog:delete() end

-- Local values: x, y, z, rx, ry, rz, x, y, z, rx, ry, rz
function WaterLog:update(dt)
	if self.state == WaterLog.STATE_EMERGING then
		self.emergeTimer = self.emergeTimer - dt
		if self.emergeTimer < 0 then
			self.emergeTimer = 0
			self.state = WaterLog.STATE_PAUSING
		end
		local v8_, v9_, v10_ = getSplinePosition(self.splineId, 0)
		local v11_, v12_, v13_ = getSplineOrientation(self.splineId, 0, 0, -1, 0)
		setTranslation(self.waterLogId, v8_, v9_ - 3.5 * (self.emergeTimer / self.emergeTime), v10_)
		setRotation(self.waterLogId, v11_, v12_, v13_)
	elseif self.state == WaterLog.STATE_PAUSING then
		self.pauseTimer = self.pauseTimer - dt
		if self.pauseTimer < 0 then
			self.splinePos = 0
			self.state = WaterLog.STATE_MOVING
			return
		end
	elseif self.state == WaterLog.STATE_MOVING then
		self.splinePos = self.splinePos + dt * self.speed * 0.01
		if self.splinePos > 1 then
			self.splinePos = 1
			self.emergeTimer = self.emergeTime
			self.pauseTimer = self.pauseTime
			self.state = WaterLog.STATE_EMERGING
		end
		local v14_, v15_, v16_ = getSplinePosition(self.splineId, self.splinePos)
		local v17_, v18_, v19_ = getSplineOrientation(self.splineId, self.splinePos, 0, -1, 0)
		setTranslation(self.waterLogId, v14_, v15_, v16_)
		setRotation(self.waterLogId, v17_, v18_, v19_)
	end
end
