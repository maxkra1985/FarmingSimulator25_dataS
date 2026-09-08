-- Local values: AIJobStartRequestEvent_mt
AIJobStartRequestEvent = {}
local AIJobStartRequestEvent_mt = Class(AIJobStartRequestEvent, Event)
InitStaticEventClass(AIJobStartRequestEvent, "AIJobStartRequestEvent")
function AIJobStartRequestEvent.emptyNew()
	-- upvalues: (copy) AIJobStartRequestEvent_mt
	return Event.new(AIJobStartRequestEvent_mt)
end

-- Local values: self
function AIJobStartRequestEvent.new(job, startFarmId)
	local v4_ = AIJobStartRequestEvent.emptyNew()
	v4_.job = job
	v4_.startFarmId = startFarmId
	return v4_
end

-- Local values: self
function AIJobStartRequestEvent.newServerToClient(state, jobTypeIndex)
	local v7_ = AIJobStartRequestEvent.emptyNew()
	v7_.state = state
	v7_.jobTypeIndex = jobTypeIndex
	return v7_
end

-- Local values: jobTypeIndex
function AIJobStartRequestEvent:readStream(streamId, connection)
	if connection:getIsServer() then
		self.state = streamReadUInt8(streamId)
		self.jobTypeIndex = streamReadUInt16(streamId)
	else
		self.startFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
		local v11_ = streamReadUInt16(streamId)
		self.job = g_currentMission.aiJobTypeManager:createJob(v11_)
		self.job:readStream(streamId, connection)
	end
	self:run(connection)
end

-- Local values: jobTypeIndex
function AIJobStartRequestEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		streamWriteUIntN(streamId, self.startFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
		local v15_ = g_currentMission.aiJobTypeManager:getJobTypeIndex(self.job)
		streamWriteUInt16(streamId, v15_)
		self.job:writeStream(streamId, connection)
	else
		streamWriteUInt8(streamId, self.state)
		streamWriteUInt16(streamId, self.jobTypeIndex)
	end
end

-- Local values: jobTypeIndex, startable, state
function AIJobStartRequestEvent:run(connection)
	if connection:getIsServer() then
		g_messageCenter:publish(AIJobStartRequestEvent, self.state, self.jobTypeIndex)
		return
	else
		local v18_ = g_currentMission.aiJobTypeManager:getJobTypeIndex(self.job)
		local v19_, v20_ = self.job:getIsStartable(connection)
		if v19_ then
			connection:sendEvent(AIJobStartRequestEvent.newServerToClient(0, v18_))
			g_currentMission.aiSystem:startJob(self.job, self.startFarmId)
		else
			connection:sendEvent(AIJobStartRequestEvent.newServerToClient(v20_, v18_))
		end
	end
end
