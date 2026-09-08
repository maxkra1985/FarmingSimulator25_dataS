-- Local values: HusbandryCancelCreationEvent_mt
HusbandryCancelCreationEvent = {}
local HusbandryCancelCreationEvent_mt = Class(HusbandryCancelCreationEvent, Event)
InitStaticEventClass(HusbandryCancelCreationEvent, "HusbandryCancelCreationEvent")
function HusbandryCancelCreationEvent.emptyNew()
	-- upvalues: (copy) HusbandryCancelCreationEvent_mt
	return Event.new(HusbandryCancelCreationEvent_mt)
end

-- Local values: self
function HusbandryCancelCreationEvent.new(placeableId)
	local v3_ = HusbandryCancelCreationEvent.emptyNew()
	v3_.placeableId = placeableId
	return v3_
end

function HusbandryCancelCreationEvent:readStream(streamId, connection)
	self.placeable = NetworkUtil.readNodeObjectId(streamId)
	self:run(connection)
end

function HusbandryCancelCreationEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObjectId(streamId, self.placeableId)
end

function HusbandryCancelCreationEvent:run(connection)
	local v11_ = not connection:getIsServer()
	assert(v11_, "HusbandryCancelCreationEvent is a client to server event only")
	if self.placeable ~= nil and self.placeable.createMeadow ~= nil then
		self.placeable:createMeadow(false)
	end
end
