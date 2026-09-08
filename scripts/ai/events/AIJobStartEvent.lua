-- Local values: AIJobStartEvent_mt
AIJobStartEvent = {}
local AIJobStartEvent_mt = Class(AIJobStartEvent, Event)
InitStaticEventClass(AIJobStartEvent, "AIJobStartEvent")
function AIJobStartEvent.emptyNew()
	-- upvalues: (copy) AIJobStartEvent_mt
	return Event.new(AIJobStartEvent_mt)
end

-- Local values: self
function AIJobStartEvent.new(job, startFarmId)
	local v4_ = AIJobStartEvent.emptyNew()
	v4_.job = job
	v4_.startFarmId = startFarmId
	return v4_
end

-- Local values: jobTypeIndex
function AIJobStartEvent:readStream(streamId, connection)
	local v8_ = connection:getIsServer()
	assert(v8_, "AIJobStartEvent is a server to client only event")
	self.startFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	local v9_ = streamReadInt32(streamId)
	self.job = g_currentMission.aiJobTypeManager:createJob(v9_)
	self.job:readStream(streamId, connection)
	self:run(connection)
end

-- Local values: jobTypeIndex
function AIJobStartEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.startFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	local v13_ = g_currentMission.aiJobTypeManager:getJobTypeIndex(self.job)
	streamWriteInt32(streamId, v13_)
	self.job:writeStream(streamId, connection)
end

function AIJobStartEvent:run(connection)
	g_currentMission.aiSystem:startJobInternal(self.job, self.startFarmId)
end
