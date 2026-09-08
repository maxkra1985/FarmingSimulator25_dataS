-- Local values: AIJobSkipTaskEvent_mt
AIJobSkipTaskEvent = {}
local AIJobSkipTaskEvent_mt = Class(AIJobSkipTaskEvent, Event)
InitStaticEventClass(AIJobSkipTaskEvent, "AIJobSkipTaskEvent")
function AIJobSkipTaskEvent.emptyNew()
	-- upvalues: (copy) AIJobSkipTaskEvent_mt
	return Event.new(AIJobSkipTaskEvent_mt)
end

-- Local values: self
function AIJobSkipTaskEvent.new(job)
	local v3_ = AIJobSkipTaskEvent.emptyNew()
	v3_.job = job
	return v3_
end

-- Local values: jobId
function AIJobSkipTaskEvent:readStream(streamId, connection)
	local v7_ = streamReadInt32(streamId)
	self.job = g_currentMission.aiSystem:getJobById(v7_)
	self:run(connection)
end

function AIJobSkipTaskEvent:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.job.jobId)
end

function AIJobSkipTaskEvent:run(connection)
	local v12_ = not connection:getIsServer()
	assert(v12_, "AIJobSkipTaskEvent is client to server only")
	g_currentMission.aiSystem:skipCurrentTaskInternal(self.job)
	if Platform.isMobile then
		g_messageCenter:publish(MessageType.AI_TASK_SKIPPED)
	end
end
