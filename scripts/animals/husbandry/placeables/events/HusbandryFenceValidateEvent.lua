HusbandryFenceValidateEvent = {}
local HusbandryFenceValidateEvent_mt = Class(HusbandryFenceValidateEvent, Event)
InitStaticEventClass(HusbandryFenceValidateEvent, "HusbandryFenceValidateEvent")
function HusbandryFenceValidateEvent.emptyNew()
	local self = Event.new(HusbandryFenceValidateEvent_mt)
	return self
end
function HusbandryFenceValidateEvent.new(placeable)
	local self = HusbandryFenceValidateEvent.emptyNew()
	self.placeable = placeable
	return self
end
function HusbandryFenceValidateEvent.newServerToClient(success)
	local self = HusbandryFenceValidateEvent.emptyNew()
	self.success = success
	return self
end
function HusbandryFenceValidateEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.placeable = NetworkUtil.readNodeObject(streamId)
	else
		self.success = streamReadBool(streamId)
	end
	self:run(connection)
end
function HusbandryFenceValidateEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.placeable)
	else
		streamWriteBool(streamId, self.success)
	end
end
function HusbandryFenceValidateEvent:run(connection)
	if connection:getIsServer() then
		g_messageCenter:publish(HusbandryFenceValidateEvent, self.success)
	else
		if self.placeable ~= nil then
			local success = self.placeable:tryFinalizeFence()
			connection:sendEvent(HusbandryFenceValidateEvent.newServerToClient(success))
		end
	end
end
