-- Local values: PlaceableFenceAddSegmentEvent_mt
PlaceableFenceAddSegmentEvent = {}
local PlaceableFenceAddSegmentEvent_mt = Class(PlaceableFenceAddSegmentEvent, Event)
InitStaticEventClass(PlaceableFenceAddSegmentEvent, "PlaceableFenceAddSegmentEvent")
function PlaceableFenceAddSegmentEvent.emptyNew()
	-- upvalues: (copy) PlaceableFenceAddSegmentEvent_mt
	return Event.new(PlaceableFenceAddSegmentEvent_mt)
end

-- Local values: self
function PlaceableFenceAddSegmentEvent.new(fence, x1, z1, x2, z2, renderFirst, renderLast, gateIndex, price)
	local v11_ = PlaceableFenceAddSegmentEvent.emptyNew()
	v11_.fence = fence
	v11_.x1 = x1
	v11_.z1 = z1
	v11_.x2 = x2
	v11_.z2 = z2
	v11_.renderFirst = renderFirst
	v11_.renderLast = renderLast
	v11_.gateIndex = gateIndex
	v11_.price = price
	return v11_
end

function PlaceableFenceAddSegmentEvent:readStream(streamId, connection)
	self.fence = NetworkUtil.readNodeObject(streamId)
	self.x1 = streamReadFloat32(streamId)
	self.z1 = streamReadFloat32(streamId)
	self.x2 = streamReadFloat32(streamId)
	self.z2 = streamReadFloat32(streamId)
	self.renderFirst = streamReadBool(streamId)
	self.renderLast = streamReadBool(streamId)
	self.gateIndex = streamReadUInt8(streamId)
	if self.gateIndex == 0 then
		self.gateIndex = nil
	end
	self.price = streamReadInt32(streamId)
	self:run(connection)
end

function PlaceableFenceAddSegmentEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.fence)
	streamWriteFloat32(streamId, self.x1)
	streamWriteFloat32(streamId, self.z1)
	streamWriteFloat32(streamId, self.x2)
	streamWriteFloat32(streamId, self.z2)
	streamWriteBool(streamId, self.renderFirst)
	streamWriteBool(streamId, self.renderLast)
	streamWriteUInt8(streamId, self.gateIndex or 0)
	streamWriteInt32(streamId, self.price)
end

-- Local values: segment
function PlaceableFenceAddSegmentEvent:run(connection)
	if self.fence ~= nil and self.fence:getIsSynchronized() then
		local v19_ = self.fence:createSegment(self.x1, self.z1, self.x2, self.z2, self.renderFirst, self.gateIndex)
		v19_.renderLast = self.renderLast
		local v20_ = self.fence
		local v21_
		if self.gateIndex == nil then
			v21_ = false
		else
			v21_ = connection:getIsServer()
		end
		v20_:addSegment(v19_, v21_)
		g_messageCenter:publish(PlaceableFenceAddSegmentEvent, self.fence, v19_)
		if not connection:getIsServer() then
			g_currentMission:addMoney(-self.price, self.fence:getOwnerFarmId(), MoneyType.SHOP_PROPERTY_BUY, true)
			g_server:broadcastEvent(self, false, nil, self.fence)
		end
	end
end
