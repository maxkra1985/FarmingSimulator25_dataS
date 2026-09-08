-- Local values: AIVehicleIsBlockedEvent_mt
AIVehicleIsBlockedEvent = {}
local AIVehicleIsBlockedEvent_mt = Class(AIVehicleIsBlockedEvent, Event)
InitStaticEventClass(AIVehicleIsBlockedEvent, "AIVehicleIsBlockedEvent")
function AIVehicleIsBlockedEvent.emptyNew()
	-- upvalues: (copy) AIVehicleIsBlockedEvent_mt
	return Event.new(AIVehicleIsBlockedEvent_mt)
end

-- Local values: self
function AIVehicleIsBlockedEvent.new(object, isBlocked)
	local v4_ = AIVehicleIsBlockedEvent.emptyNew()
	v4_.object = object
	v4_.isBlocked = isBlocked
	return v4_
end

function AIVehicleIsBlockedEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.isBlocked = streamReadBool(streamId)
	self:run(connection)
end

function AIVehicleIsBlockedEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.isBlocked)
end

function AIVehicleIsBlockedEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		if self.isBlocked then
			self.object:aiBlock()
			return
		end
		self.object:aiContinue()
	end
end
