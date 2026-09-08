-- Local values: CollectibleTriggerEvent_mt
CollectibleTriggerEvent = {}
local CollectibleTriggerEvent_mt = Class(CollectibleTriggerEvent, Event)
InitStaticEventClass(CollectibleTriggerEvent, "CollectibleTriggerEvent")
function CollectibleTriggerEvent.emptyNew()
	-- upvalues: (copy) CollectibleTriggerEvent_mt
	return Event.new(CollectibleTriggerEvent_mt)
end

-- Local values: self
function CollectibleTriggerEvent.new(player, index)
	local v4_ = CollectibleTriggerEvent.emptyNew()
	v4_.player = player
	v4_.index = index
	return v4_
end

function CollectibleTriggerEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.player)
	streamWriteUInt8(streamId, self.index)
end

function CollectibleTriggerEvent:readStream(streamId, connection)
	self.player = NetworkUtil.readNodeObject(streamId)
	self.index = streamReadUInt8(streamId)
	self:run(connection)
end

function CollectibleTriggerEvent:run(connection)
	g_currentMission.collectiblesSystem:onTriggerEvent(self.index, self.player)
end
