-- Local values: AITaskLoading_mt
AITaskLoading = {}
AITaskLoading.STATE_DRIVING = 0
AITaskLoading.STATE_LOADING = 1
local AITaskLoading_mt = Class(AITaskLoading, AITask)

-- Upvalues: AITaskLoading_mt
-- Local values: self
function AITaskLoading.new(isServer, job, customMt)
	-- upvalues: (copy) AITaskLoading_mt
	local v5_ = AITask.new(isServer, job, customMt or AITaskLoading_mt)
	v5_.vehicle = nil
	v5_.loadTrigger = nil
	v5_.fillType = nil
	v5_.loadVehicle = nil
	v5_.fillUnitIndex = nil
	v5_.offsetZ = 0
	v5_.maxSpeed = 5
	return v5_
end

function AITaskLoading:reset()
	self.vehicle = nil
	self.loadTrigger = nil
	self.loadVehicle = nil
	self.fillType = nil
	AITaskLoading:superClass().reset(self)
end

function AITaskLoading:setVehicle(vehicle)
	self.vehicle = vehicle
end

function AITaskLoading:setLoadTrigger(loadTrigger)
	self.loadTrigger = loadTrigger
end

function AITaskLoading:setFillType(fillType)
	self.fillType = fillType
end

function AITaskLoading:setFillUnit(vehicle, fillUnitIndex, offsetZ)
	self.offsetZ = offsetZ
	self.loadVehicle = vehicle
	self.fillUnitIndex = fillUnitIndex
end

-- Local values: x, z, xDir, zDir, y
function AITaskLoading:start()
	if self.isServer then
		local v18_, v19_, v20_, v21_ = self.loadTrigger:getAITargetPositionAndDirection()
		local v22_ = v18_ + v20_ * -self.offsetZ
		local v23_ = v19_ + v21_ * -self.offsetZ
		local v24_ = getTerrainHeightAtWorldPos(g_terrainNode, v22_, 0, v23_)
		self.vehicle:setAITarget(self, v22_, v24_, v23_, v20_, 0, v21_, self.maxSpeed, true)
		self.state = AITaskLoading.STATE_DRIVING
	end
	AITaskLoading:superClass().start(self)
end

function AITaskLoading:stop(wasJobStopped)
	if wasJobStopped and (not self.isFinished and self.state == AITaskLoading.STATE_LOADING) then
		self.loadVehicle:aiCancelLoadingFromTrigger(self.loadTrigger, self.fillUnitIndex, self.fillType, self)
	end
	AITaskLoading:superClass().start(self, wasJobStopped)
end

function AITaskLoading:finishedLoading()
	if self.loadVehicle ~= nil then
		self.loadVehicle:aiFinishLoading(self.fillUnitIndex, self)
	end
	self.isFinished = true
end

function AITaskLoading:onTargetReached()
	self.vehicle:unsetAITarget()
	self.state = AITaskLoading.STATE_LOADING
	self.loadVehicle:aiPrepareLoading(self.fillUnitIndex, self)
	self.loadVehicle:aiStartLoadingFromTrigger(self.loadTrigger, self.fillUnitIndex, self.fillType, self)
end

function AITaskLoading:onError(errorMessage) end
