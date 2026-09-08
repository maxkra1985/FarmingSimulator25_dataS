-- Local values: AITaskWaitForFilling_mt
AITaskWaitForFilling = {}
local AITaskWaitForFilling_mt = Class(AITaskWaitForFilling, AITask)

-- Upvalues: AITaskWaitForFilling_mt
-- Local values: self
function AITaskWaitForFilling.new(isServer, job, customMt)
	-- upvalues: (copy) AITaskWaitForFilling_mt
	local v5_ = AITask.new(isServer, job, customMt or AITaskWaitForFilling_mt)
	v5_.fillTypes = {}
	v5_.vehicle = nil
	v5_.fillUnitInfo = {}
	v5_.waitTime = 0
	v5_.waitDuration = 3000
	v5_.isFullyLoaded = false
	return v5_
end

function AITaskWaitForFilling:reset()
	self.vehicle = nil
	self.fillTypes = {}
	self.fillUnitInfo = {}
	self.waitTime = 0
	self.isFullyLoaded = false
	AITaskWaitForFilling:superClass().reset(self)
end

function AITaskWaitForFilling:addAllowedFillType(fillType)
	self.fillTypes[fillType] = true
end

-- Local values: valid, isFullyLoaded, _, fillUnitInfo, vehicle, fillUnitIndex, fillType, fillLevel, freeCapacity
function AITaskWaitForFilling:update(dt)
	if self.isServer then
		if self.isFullyLoaded then
			if g_time > self.waitTime then
				self.isFinished = true
			end
		else
			local v10_ = false
			local v11_ = true
			for _, v12_ in ipairs(self.fillUnitInfo) do
				local v13_ = v12_.vehicle
				local v14_ = v12_.fillUnitIndex
				local v15_ = v13_:getFillUnitFillType(v14_)
				local v16_ = v13_:getFillUnitFillLevel(v14_)
				if v13_:getFillUnitFreeCapacity(v14_) > 0 then
					v11_ = false
				end
				if v16_ > 0 and self.fillTypes[v15_] or v16_ == 0 then
					v10_ = true
				end
			end
			if not v10_ then
				g_currentMission.aiSystem:stopJob(self.job, AIMessageErrorNoValidFillTypeLoaded.new())
				return
			end
			if v11_ then
				self.isFullyLoaded = true
				self.waitTime = g_time + self.waitDuration
				return
			end
		end
	end
end

-- Local values: _, fillUnitInfo
function AITaskWaitForFilling:start()
	AITaskWaitForFilling:superClass().start(self)
	if self.isServer then
		self.isFullyLoaded = false
		for _, v18_ in ipairs(self.fillUnitInfo) do
			v18_.vehicle:aiPrepareLoading(v18_.fillUnitIndex, self)
		end
	end
end

-- Local values: _, fillUnitInfo
function AITaskWaitForFilling:stop(wasJobStopped)
	AITaskWaitForFilling:superClass().stop(self, wasJobStopped)
	if self.isServer then
		for _, v21_ in ipairs(self.fillUnitInfo) do
			v21_.vehicle:aiFinishLoading(v21_.fillUnitIndex, self)
		end
	end
end

function AITaskWaitForFilling:setVehicle(vehicle)
	self.vehicle = vehicle
end

function AITaskWaitForFilling:addFillUnits(vehicle, fillUnitIndex)
	local v27_ = self.fillUnitInfo
	table.insert(v27_, {
		["vehicle"] = vehicle,
		["fillUnitIndex"] = fillUnitIndex
	})
end
