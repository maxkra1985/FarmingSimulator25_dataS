-- Local values: WoodUnloadTriggerEvent_mt
WoodUnloadTriggerEvent = {}
local WoodUnloadTriggerEvent_mt = Class(WoodUnloadTriggerEvent, Event)
InitStaticEventClass(WoodUnloadTriggerEvent, "WoodUnloadTriggerEvent")
function WoodUnloadTriggerEvent.emptyNew()
	-- upvalues: (copy) WoodUnloadTriggerEvent_mt
	return Event.new(WoodUnloadTriggerEvent_mt)
end

-- Local values: self
function WoodUnloadTriggerEvent.new(woodUnloadTrigger, farmId)
	local v4_ = WoodUnloadTriggerEvent.emptyNew()
	local v5_ = g_server == nil
	assert(v5_, "Client->Server event")
	v4_.woodUnloadTrigger = woodUnloadTrigger
	v4_.farmId = farmId
	return v4_
end

function WoodUnloadTriggerEvent:readStream(streamId, connection)
	self.woodUnloadTrigger = NetworkUtil.readNodeObject(streamId)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self:run(connection)
end

function WoodUnloadTriggerEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.woodUnloadTrigger)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end

function WoodUnloadTriggerEvent:run(connection)
	if not connection:getIsServer() then
		self.woodUnloadTrigger:processWood(self.farmId)
	end
end
