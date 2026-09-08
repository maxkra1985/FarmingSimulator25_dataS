-- Local values: BaleWrapperStateEvent_mt
BaleWrapperStateEvent = {}
local BaleWrapperStateEvent_mt = Class(BaleWrapperStateEvent, Event)
InitStaticEventClass(BaleWrapperStateEvent, "BaleWrapperStateEvent")
function BaleWrapperStateEvent.emptyNew()
	-- upvalues: (copy) BaleWrapperStateEvent_mt
	return Event.new(BaleWrapperStateEvent_mt)
end

-- Local values: self
function BaleWrapperStateEvent.new(object, stateId, nearestBaleServerId)
	local v5_ = BaleWrapperStateEvent.emptyNew()
	v5_.object = object
	v5_.stateId = stateId
	local v6_ = nearestBaleServerId ~= nil and true or v5_.stateId ~= BaleWrapper.CHANGE_GRAB_BALE
	assert(v6_)
	v5_.nearestBaleServerId = nearestBaleServerId
	return v5_
end

function BaleWrapperStateEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.stateId = streamReadInt8(streamId)
	if self.stateId == BaleWrapper.CHANGE_GRAB_BALE then
		self.nearestBaleServerId = NetworkUtil.readNodeObjectId(streamId)
	end
	self:run(connection)
end

function BaleWrapperStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteInt8(streamId, self.stateId)
	if self.stateId == BaleWrapper.CHANGE_GRAB_BALE then
		NetworkUtil.writeNodeObjectId(streamId, self.nearestBaleServerId)
	end
end

function BaleWrapperStateEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:doStateChange(self.stateId, self.nearestBaleServerId)
	end
end
