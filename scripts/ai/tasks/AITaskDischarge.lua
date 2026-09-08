-- Local values: AITaskDischarge_mt
AITaskDischarge = {}
AITaskDischarge.STATE_DRIVING = 0
AITaskDischarge.STATE_DISCHARGE = 1
local AITaskDischarge_mt = Class(AITaskDischarge, AITask)

-- Upvalues: AITaskDischarge_mt
-- Local values: self
function AITaskDischarge.new(isServer, job, customMt)
	-- upvalues: (copy) AITaskDischarge_mt
	local v5_ = AITask.new(isServer, job, customMt or AITaskDischarge_mt)
	v5_.vehicle = nil
	v5_.unloadTrigger = nil
	v5_.dischargeVehicle = nil
	v5_.dischargeNode = nil
	v5_.offsetZ = 0
	v5_.maxSpeed = 5
	v5_.state = AITaskDischarge.STATE_DRIVING
	return v5_
end

function AITaskDischarge:reset()
	self.vehicle = nil
	self.unloadTrigger = nil
	self.dischargeVehicle = nil
	self.dischargeNode = nil
	self.offsetZ = 0
	self.state = AITaskDischarge.STATE_DRIVING
	AITaskDischarge:superClass().reset(self)
end

function AITaskDischarge:setVehicle(vehicle)
	self.vehicle = vehicle
end

function AITaskDischarge:setUnloadTrigger(unloadTrigger)
	self.unloadTrigger = unloadTrigger
end

function AITaskDischarge:setDischargeNode(vehicle, dischargeNode, offsetZ)
	if vehicle ~= nil then
		self.offsetZ = offsetZ
		vehicle:setCurrentDischargeNodeIndex(dischargeNode.index)
	end
	self.dischargeNode = dischargeNode
	self.dischargeVehicle = vehicle
end

-- Local values: x, z, xDir, zDir, y
function AITaskDischarge:start()
	if self.isServer then
		local v16_, v17_, v18_, v19_ = self.unloadTrigger:getAITargetPositionAndDirection()
		local v20_ = v16_ + v18_ * -self.offsetZ
		local v21_ = v17_ + v19_ * -self.offsetZ
		local v22_ = getTerrainHeightAtWorldPos(g_terrainNode, v20_, 0, v21_)
		self.vehicle:setAITarget(self, v20_, v22_, v21_, v18_, 0, v19_, self.maxSpeed, true)
		self.state = AITaskDischarge.STATE_DRIVING
	end
	AITaskDischarge:superClass().start(self)
end

function AITaskDischarge:onTargetReached()
	self.vehicle:unsetAITarget()
	if self.dischargeVehicle:getAICanStartDischarge(self.dischargeNode) then
		self.state = AITaskDischarge.STATE_DISCHARGE
		self.dischargeVehicle:startAIDischarge(self.dischargeNode, self)
	else
		g_currentMission.aiSystem:stopJob(self.job, AIMessageErrorUnloadingStationFull.new())
	end
end

function AITaskDischarge:onError(errorMessage) end

function AITaskDischarge:finishedDischarge()
	self.isFinished = true
end
