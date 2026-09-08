-- Local values: BaleLoaderStateEvent_mt
BaleLoaderStateEvent = {}
local BaleLoaderStateEvent_mt = Class(BaleLoaderStateEvent, Event)
InitStaticEventClass(BaleLoaderStateEvent, "BaleLoaderStateEvent")
function BaleLoaderStateEvent.emptyNew()
	-- upvalues: (copy) BaleLoaderStateEvent_mt
	return Event.new(BaleLoaderStateEvent_mt)
end

-- Local values: self
function BaleLoaderStateEvent.new(object, stateId, nearestBaleServerId)
	local v5_ = BaleLoaderStateEvent.emptyNew()
	v5_.object = object
	v5_.stateId = stateId
	local v6_ = nearestBaleServerId ~= nil and true or v5_.stateId ~= BaleLoader.CHANGE_GRAB_BALE
	assert(v6_)
	v5_.nearestBaleServerId = nearestBaleServerId
	return v5_
end

function BaleLoaderStateEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.stateId = streamReadInt8(streamId)
	if self.stateId == BaleLoader.CHANGE_GRAB_BALE then
		self.nearestBaleServerId = NetworkUtil.readNodeObjectId(streamId)
	end
	self:run(connection)
end

function BaleLoaderStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteInt8(streamId, self.stateId)
	if self.stateId == BaleLoader.CHANGE_GRAB_BALE then
		NetworkUtil.writeNodeObjectId(streamId, self.nearestBaleServerId)
	end
end

function BaleLoaderStateEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:doStateChange(self.stateId, self.nearestBaleServerId)
	end
end
