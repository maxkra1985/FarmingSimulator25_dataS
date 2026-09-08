-- Local values: AITaskDriveTo_mt
AITaskDriveTo = {}
AITaskDriveTo.STATE_PREPARE_DRIVING = 1
AITaskDriveTo.STATE_DRIVE_TO_OFFSET_POS = 2
AITaskDriveTo.STATE_DRIVE_TO_FINAL_POS = 3
AITaskDriveTo.PREPARE_TIMEOUT = 2000
local AITaskDriveTo_mt = Class(AITaskDriveTo, AITask)

-- Upvalues: AITaskDriveTo_mt
-- Local values: self
function AITaskDriveTo.new(isServer, job, customMt)
	-- upvalues: (copy) AITaskDriveTo_mt
	local v5_ = AITask.new(isServer, job, customMt or AITaskDriveTo_mt)
	v5_.x = nil
	v5_.z = nil
	v5_.dirX = nil
	v5_.dirZ = nil
	v5_.vehicle = nil
	v5_.state = AITaskDriveTo.STATE_DRIVE_TO_OFFSET_POS
	v5_.maxSpeed = 10
	v5_.offset = 0
	v5_.prepareTimeout = 0
	return v5_
end

function AITaskDriveTo:reset()
	self.vehicle = nil
	self.x = nil
	self.z = nil
	self.dirX = nil
	self.dirZ = nil
	self.state = AITaskDriveTo.STATE_DRIVE_TO_OFFSET_POS
	self.maxSpeed = 10
	self.offset = 0
	AITaskDriveTo:superClass().reset(self)
end

function AITaskDriveTo:setVehicle(vehicle)
	self.vehicle = vehicle
end

function AITaskDriveTo:setTargetOffset(offset)
	self.offset = offset
end

function AITaskDriveTo:setTargetPosition(x, z)
	self.x = x
	self.z = z
	local _ = self.isActive
end

function AITaskDriveTo:setTargetDirection(dirX, dirZ)
	self.dirX = dirX
	self.dirZ = dirZ
	local _ = self.isActive
end

-- Local values: isReadyToDrive, blockingVehicle
function AITaskDriveTo:update(dt)
	if self.isServer and self.state == AITaskDriveTo.STATE_PREPARE_DRIVING then
		local v19_, v20_ = self.vehicle:getIsAIReadyToDrive()
		if v19_ then
			self:startDriving()
			return
		end
		if not self.vehicle:getIsAIPreparingToDrive() then
			self.prepareTimeout = self.prepareTimeout + dt
			if self.prepareTimeout > AITaskDriveTo.PREPARE_TIMEOUT then
				self.vehicle:stopCurrentAIJob(AIMessageErrorCouldNotPrepare.new(v20_ or self.vehicle))
			end
		end
	end
end

function AITaskDriveTo:start()
	if self.isServer then
		self.state = AITaskDriveTo.STATE_PREPARE_DRIVING
		self.vehicle:prepareForAIDriving()
		self.isActive = true
	end
	AITaskDriveTo:superClass().start(self)
end

function AITaskDriveTo:stop(wasJobStopped)
	AITaskDriveTo:superClass().stop(self, wasJobStopped)
	if self.isServer then
		self.vehicle:unsetAITarget()
		self.isActive = false
	end
end

-- Local values: y, dirY, x, z
function AITaskDriveTo:startDriving()
	local v25_ = getTerrainHeightAtWorldPos(g_terrainNode, self.x, 0, self.z)
	self.state = AITaskDriveTo.STATE_DRIVE_TO_FINAL_POS
	local v26_ = self.x
	local v27_ = self.z
	if self.offset ~= 0 then
		self.state = AITaskDriveTo.STATE_DRIVE_TO_OFFSET_POS
		v26_ = self.x + self.dirX * -self.offset
		v27_ = self.z + self.dirZ * -self.offset
	end
	self.vehicle:setAITarget(self, v26_, v25_, v27_, self.dirX, 0, self.dirZ)
end

-- Local values: y
function AITaskDriveTo:onTargetReached()
	if self.state == AITaskDriveTo.STATE_DRIVE_TO_OFFSET_POS then
		local v29_ = getTerrainHeightAtWorldPos(g_terrainNode, self.x, 0, self.z)
		self.vehicle:setAITarget(self, self.x, v29_, self.z, self.dirX, 0, self.dirZ, self.maxSpeed, true)
		self.state = AITaskDriveTo.STATE_DRIVE_TO_FINAL_POS
	else
		self.isFinished = true
	end
end

function AITaskDriveTo:onError(errorMessage) end
