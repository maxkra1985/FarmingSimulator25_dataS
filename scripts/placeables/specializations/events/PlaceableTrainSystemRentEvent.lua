-- Local values: PlaceableTrainSystemRentEvent_mt
PlaceableTrainSystemRentEvent = {}
local PlaceableTrainSystemRentEvent_mt = Class(PlaceableTrainSystemRentEvent, Event)
InitStaticEventClass(PlaceableTrainSystemRentEvent, "PlaceableTrainSystemRentEvent")
function PlaceableTrainSystemRentEvent.emptyNew()
	-- upvalues: (copy) PlaceableTrainSystemRentEvent_mt
	return Event.new(PlaceableTrainSystemRentEvent_mt)
end

-- Local values: self
function PlaceableTrainSystemRentEvent.new(object, isRented, farmId, splinePosition)
	local v6_ = PlaceableTrainSystemRentEvent.emptyNew()
	v6_.object = object
	v6_.isRented = isRented
	v6_.farmId = farmId
	v6_.splinePosition = splinePosition
	return v6_
end

function PlaceableTrainSystemRentEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.isRented = streamReadBool(streamId)
	if self.isRented then
		self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
		self.splinePosition = streamReadFloat32(streamId)
	end
	self:run(connection)
end

function PlaceableTrainSystemRentEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	if streamWriteBool(streamId, self.isRented) then
		streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
		streamWriteFloat32(streamId, self.splinePosition)
	end
end

-- Local values: farmId, splinePosition
function PlaceableTrainSystemRentEvent:run(connection)
	local v14_, v15_
	if self.isRented then
		v14_ = self.farmId
		v15_ = self.splinePosition
	else
		v14_ = nil
		v15_ = nil
	end
	if self.object ~= nil and self.object:getIsSynchronized() then
		if self.isRented then
			self.object:rentRailroad(v14_, v15_, true)
		else
			self.object:returnRailroad(true)
		end
	end
	if not connection:getIsServer() then
		g_server:broadcastEvent(PlaceableTrainSystemRentEvent.new(self.object, self.isRented, self.farmId, self.splinePosition), nil, connection, self.object)
	end
end

function PlaceableTrainSystemRentEvent.sendEvent(object, isRented, farmId, splinePosition, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(PlaceableTrainSystemRentEvent.new(object, isRented, farmId, splinePosition), nil, nil, object)
			return
		end
		g_client:getServerConnection():sendEvent(PlaceableTrainSystemRentEvent.new(object, isRented, farmId, splinePosition))
	end
end
