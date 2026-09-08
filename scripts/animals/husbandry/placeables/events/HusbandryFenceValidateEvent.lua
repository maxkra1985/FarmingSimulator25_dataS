-- Local values: HusbandryFenceValidateEvent_mt
HusbandryFenceValidateEvent = {}
local HusbandryFenceValidateEvent_mt = Class(HusbandryFenceValidateEvent, Event)
InitStaticEventClass(HusbandryFenceValidateEvent, "HusbandryFenceValidateEvent")
function HusbandryFenceValidateEvent.emptyNew()
	-- upvalues: (copy) HusbandryFenceValidateEvent_mt
	return Event.new(HusbandryFenceValidateEvent_mt)
end

-- Local values: self
function HusbandryFenceValidateEvent.new(placeable)
	local v3_ = HusbandryFenceValidateEvent.emptyNew()
	v3_.placeable = placeable
	return v3_
end

-- Local values: self
function HusbandryFenceValidateEvent.newServerToClient(success)
	local v5_ = HusbandryFenceValidateEvent.emptyNew()
	v5_.success = success
	return v5_
end

function HusbandryFenceValidateEvent:readStream(streamId, connection)
	if connection:getIsServer() then
		self.success = streamReadBool(streamId)
	else
		self.placeable = NetworkUtil.readNodeObject(streamId)
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

-- Local values: success
function HusbandryFenceValidateEvent:run(connection)
	if connection:getIsServer() then
		g_messageCenter:publish(HusbandryFenceValidateEvent, self.success)
	elseif self.placeable ~= nil then
		local v14_ = self.placeable:tryFinalizeFence()
		connection:sendEvent(HusbandryFenceValidateEvent.newServerToClient(v14_))
	end
end
