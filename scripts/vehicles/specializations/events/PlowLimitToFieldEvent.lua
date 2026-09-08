-- Local values: PlowLimitToFieldEvent_mt
PlowLimitToFieldEvent = {}
local PlowLimitToFieldEvent_mt = Class(PlowLimitToFieldEvent, Event)
InitStaticEventClass(PlowLimitToFieldEvent, "PlowLimitToFieldEvent")
function PlowLimitToFieldEvent.emptyNew()
	-- upvalues: (copy) PlowLimitToFieldEvent_mt
	return Event.new(PlowLimitToFieldEvent_mt)
end

-- Local values: self
function PlowLimitToFieldEvent.new(object, plowLimitToField)
	local v4_ = PlowLimitToFieldEvent.emptyNew()
	v4_.object = object
	v4_.plowLimitToField = plowLimitToField
	return v4_
end

function PlowLimitToFieldEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.plowLimitToField = streamReadBool(streamId)
	self:run(connection)
end

function PlowLimitToFieldEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.plowLimitToField)
end

function PlowLimitToFieldEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setPlowLimitToField(self.plowLimitToField, true)
	end
	if not connection:getIsServer() then
		g_server:broadcastEvent(PlowLimitToFieldEvent.new(self.object, self.plowLimitToField), nil, connection, self.object)
	end
end
