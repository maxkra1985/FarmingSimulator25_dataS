-- Local values: AIJobStopEvent_mt
AIJobStopEvent = {}
local AIJobStopEvent_mt = Class(AIJobStopEvent, Event)
InitStaticEventClass(AIJobStopEvent, "AIJobStopEvent")
function AIJobStopEvent.emptyNew()
	-- upvalues: (copy) AIJobStopEvent_mt
	return Event.new(AIJobStopEvent_mt)
end

-- Local values: self
function AIJobStopEvent.new(job, aiMessage)
	local v4_ = AIJobStopEvent.emptyNew()
	v4_.aiMessage = aiMessage
	v4_.job = job
	return v4_
end

-- Local values: jobId, messageIndex
function AIJobStopEvent:readStream(streamId, connection)
	local v8_ = streamReadInt32(streamId)
	self.job = g_currentMission.aiSystem:getJobById(v8_)
	if streamReadBool(streamId) then
		local v9_ = streamReadInt32(streamId)
		self.aiMessage = g_currentMission.aiMessageManager:createMessage(v9_)
		self.aiMessage:readStream(streamId, connection)
	end
	self:run(connection)
end

-- Local values: messageIndex
function AIJobStopEvent:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.job.jobId)
	if streamWriteBool(streamId, self.aiMessage ~= nil) then
		local v13_ = g_currentMission.aiMessageManager:getMessageIndex(self.aiMessage)
		streamWriteInt32(streamId, v13_)
		self.aiMessage:writeStream(streamId, connection)
	end
end

function AIJobStopEvent:run(connection)
	if self.job ~= nil then
		if connection:getIsServer() then
			g_currentMission.aiSystem:stopJobInternal(self.job, self.aiMessage)
			return
		end
		g_currentMission.aiSystem:stopJob(self.job, self.aiMessage)
	end
end
