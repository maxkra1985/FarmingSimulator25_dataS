-- Local values: AIFieldWorkerStateEvent_mt
AIFieldWorkerStateEvent = {}
local AIFieldWorkerStateEvent_mt = Class(AIFieldWorkerStateEvent, Event)
InitStaticEventClass(AIFieldWorkerStateEvent, "AIFieldWorkerStateEvent")
function AIFieldWorkerStateEvent.emptyNew()
	-- upvalues: (copy) AIFieldWorkerStateEvent_mt
	return Event.new(AIFieldWorkerStateEvent_mt)
end

-- Local values: self
function AIFieldWorkerStateEvent.new(vehicle, isActive)
	local v4_ = AIFieldWorkerStateEvent.emptyNew()
	v4_.vehicle = vehicle
	v4_.isActive = isActive
	return v4_
end

function AIFieldWorkerStateEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.isActive = streamReadBool(streamId)
	self:run(connection)
end

function AIFieldWorkerStateEvent:writeStream(streamId, connection)
	local v11_ = not connection:getIsServer()
	assert(v11_, "AIFieldWorkerStateEvent is a server to client event only")
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteBool(streamId, self.isActive)
end

function AIFieldWorkerStateEvent:run(connection)
	if self.vehicle ~= nil and (self.vehicle ~= nil and self.vehicle:getIsSynchronized()) then
		if self.isActive then
			self.vehicle:startFieldWorker()
			return
		end
		self.vehicle:stopFieldWorker()
	end
end
