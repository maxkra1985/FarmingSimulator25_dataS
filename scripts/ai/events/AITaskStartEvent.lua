-- Local values: AITaskStartEvent_mt
AITaskStartEvent = {}
local AITaskStartEvent_mt = Class(AITaskStartEvent, Event)
InitStaticEventClass(AITaskStartEvent, "AITaskStartEvent")
function AITaskStartEvent.emptyNew()
	-- upvalues: (copy) AITaskStartEvent_mt
	return Event.new(AITaskStartEvent_mt)
end

-- Local values: self
function AITaskStartEvent.new(job, task)
	local v4_ = AITaskStartEvent.emptyNew()
	v4_.job = job
	v4_.task = task
	return v4_
end

-- Local values: jobId, taskId
function AITaskStartEvent:readStream(streamId, connection)
	local v8_ = streamReadInt32(streamId)
	local v9_ = streamReadUInt8(streamId)
	self.job = g_currentMission.aiSystem:getJobById(v8_)
	if self.job ~= nil then
		self.task = self.job:getTaskByIndex(v9_)
	end
	self:run(connection)
end

function AITaskStartEvent:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.job.jobId)
	streamWriteUInt8(streamId, self.task.taskIndex)
end

function AITaskStartEvent:run(connection)
	if self.job == nil then
		Logging.devWarning("AITaskStartEvent: Job not defined")
	else
		self.job:startTask(self.task)
	end
end
