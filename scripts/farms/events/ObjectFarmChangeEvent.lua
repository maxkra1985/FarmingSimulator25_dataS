-- Local values: ObjectFarmChangeEvent_mt
ObjectFarmChangeEvent = {}
local ObjectFarmChangeEvent_mt = Class(ObjectFarmChangeEvent, Event)
InitStaticEventClass(ObjectFarmChangeEvent, "ObjectFarmChangeEvent")
function ObjectFarmChangeEvent.emptyNew()
	-- upvalues: (copy) ObjectFarmChangeEvent_mt
	return Event.new(ObjectFarmChangeEvent_mt)
end

-- Local values: self
function ObjectFarmChangeEvent.new(object, farmId)
	local v4_ = ObjectFarmChangeEvent.emptyNew()
	v4_.object = object
	v4_.farmId = farmId
	return v4_
end

function ObjectFarmChangeEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end

function ObjectFarmChangeEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self:run(connection)
end

function ObjectFarmChangeEvent:run(connection)
	if connection:getIsServer() then
		self.object:setOwnerFarmId(self.farmId, true)
	end
end
