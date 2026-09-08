-- Local values: AIJobVehicleStateEvent_mt
AIJobVehicleStateEvent = {}
local AIJobVehicleStateEvent_mt = Class(AIJobVehicleStateEvent, Event)
InitStaticEventClass(AIJobVehicleStateEvent, "AIJobVehicleStateEvent")
function AIJobVehicleStateEvent.emptyNew()
	-- upvalues: (copy) AIJobVehicleStateEvent_mt
	return Event.new(AIJobVehicleStateEvent_mt)
end

-- Local values: self
function AIJobVehicleStateEvent.new(vehicle, job, helperIndex, startedFarmId)
	local v6_ = AIJobVehicleStateEvent.emptyNew()
	v6_.vehicle = vehicle
	v6_.job = job
	v6_.helperIndex = helperIndex
	v6_.startedFarmId = startedFarmId
	return v6_
end

-- Local values: jobId
function AIJobVehicleStateEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	if streamReadBool(streamId) then
		local v10_ = streamReadInt32(streamId)
		self.job = g_currentMission.aiSystem:getJobById(v10_)
		self.startedFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
		self.helperIndex = streamReadUInt8(streamId)
	end
	self:run(connection)
end

function AIJobVehicleStateEvent:writeStream(streamId, connection)
	local v14_ = not connection:getIsServer()
	assert(v14_, "AIJobVehicleStateEvent is a server to client event only")
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	if streamWriteBool(streamId, self.job ~= nil) then
		streamWriteInt32(streamId, self.job.jobId)
		streamWriteUIntN(streamId, self.startedFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
		streamWriteUInt8(streamId, self.helperIndex)
	end
end

function AIJobVehicleStateEvent:run(connection)
	if self.vehicle ~= nil and (self.vehicle ~= nil and self.vehicle:getIsSynchronized()) then
		if self.job ~= nil then
			self.vehicle:aiJobStarted(self.job, self.helperIndex, self.startedFarmId)
			return
		end
		self.vehicle:aiJobFinished()
	end
end
