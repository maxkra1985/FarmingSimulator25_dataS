-- Local values: InlineWrapperPushOffEvent_mt
InlineWrapperPushOffEvent = {}
local InlineWrapperPushOffEvent_mt = Class(InlineWrapperPushOffEvent, Event)
InitStaticEventClass(InlineWrapperPushOffEvent, "InlineWrapperPushOffEvent")
function InlineWrapperPushOffEvent.emptyNew()
	-- upvalues: (copy) InlineWrapperPushOffEvent_mt
	return Event.new(InlineWrapperPushOffEvent_mt)
end

-- Local values: self
function InlineWrapperPushOffEvent.new(inlineWrapper)
	local v3_ = InlineWrapperPushOffEvent.emptyNew()
	v3_.inlineWrapper = inlineWrapper
	return v3_
end

function InlineWrapperPushOffEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.inlineWrapper = NetworkUtil.readNodeObject(streamId)
	end
	self:run(connection)
end

function InlineWrapperPushOffEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.inlineWrapper)
	end
end

function InlineWrapperPushOffEvent:run(connection)
	if not connection:getIsServer() and (self.inlineWrapper ~= nil and self.inlineWrapper:getIsSynchronized()) then
		self.inlineWrapper:pushOffInlineBale()
	end
end
