-- Local values: AITaskStopEvent_mt
AITaskStopEvent = {}
local AITaskStopEvent_mt = Class(AITaskStopEvent, Event)
InitStaticEventClass(AITaskStopEvent, "AITaskStopEvent")
function AITaskStopEvent.emptyNew()
	-- upvalues: (copy) AITaskStopEvent_mt
	return Event.new(AITaskStopEvent_mt)
end

-- Local values: self
function AITaskStopEvent.new(job, task, wasJobStopped)
	local v5_ = AITaskStopEvent.emptyNew()
	v5_.job = job
	v5_.wasJobStopped = wasJobStopped
	v5_.task = task
	return v5_
end

-- Local values: jobId, taskId, wasJobStopped
function AITaskStopEvent:readStream(streamId, connection)
	local v9_ = streamReadInt32(streamId)
	local v10_ = streamReadUInt8(streamId)
	local v11_ = streamReadBool(streamId)
	self.job = g_currentMission.aiSystem:getJobById(v9_)
	if self.job ~= nil then
		self.task = self.job:getTaskByIndex(v10_)
	end
	self.wasJobStopped = v11_
	self:run(connection)
end

function AITaskStopEvent:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.job.jobId)
	streamWriteUInt8(streamId, self.task.taskIndex)
	streamWriteBool(streamId, self.wasJobStopped)
end

function AITaskStopEvent:run(connection)
	if self.job == nil then
		Logging.devWarning("AITaskStopEvent: Job not defined")
	else
		self.job:stopTask(self.task, self.wasJobStopped)
	end
end
