-- Local values: AITaskConveyor_mt
AITaskConveyor = {}
local AITaskConveyor_mt = Class(AITaskConveyor, AITask)

-- Upvalues: AITaskConveyor_mt
-- Local values: self
function AITaskConveyor.new(isServer, job, customMt)
	-- upvalues: (copy) AITaskConveyor_mt
	local v5_ = AITask.new(isServer, job, customMt or AITaskConveyor_mt)
	v5_.vehicle = nil
	return v5_
end

function AITaskConveyor:reset()
	self.vehicle = nil
	AITaskConveyor:superClass().reset(self)
end

function AITaskConveyor:setVehicle(vehicle)
	self.vehicle = vehicle
end

function AITaskConveyor:start()
	if self.vehicle == nil then
		Logging.devError("Could not start AITaskConveyor. No vehicle set")
	else
		self.vehicle:startFieldWorker()
	end
	AITaskConveyor:superClass().start(self)
end

function AITaskConveyor:stop(wasJobStopped)
	AITaskConveyor:superClass().stop(self, wasJobStopped)
	if self.vehicle == nil then
		Logging.devError("Could not stop AITaskConveyor. No vehicle set")
	else
		self.vehicle:stopFieldWorker()
	end
end
