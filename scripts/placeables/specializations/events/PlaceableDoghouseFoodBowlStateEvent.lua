-- Local values: PlaceableDoghouseFoodBowlStateEvent_mt
PlaceableDoghouseFoodBowlStateEvent = {}
local PlaceableDoghouseFoodBowlStateEvent_mt = Class(PlaceableDoghouseFoodBowlStateEvent, Event)
InitStaticEventClass(PlaceableDoghouseFoodBowlStateEvent, "PlaceableDoghouseFoodBowlStateEvent")
function PlaceableDoghouseFoodBowlStateEvent.emptyNew()
	-- upvalues: (copy) PlaceableDoghouseFoodBowlStateEvent_mt
	return Event.new(PlaceableDoghouseFoodBowlStateEvent_mt)
end

-- Local values: self
function PlaceableDoghouseFoodBowlStateEvent.new(doghouse, isFilled)
	local v4_ = PlaceableDoghouseFoodBowlStateEvent.emptyNew()
	v4_.doghouse = doghouse
	v4_.isFilled = isFilled
	return v4_
end

function PlaceableDoghouseFoodBowlStateEvent:readStream(streamId, connection)
	self.doghouse = NetworkUtil.readNodeObject(streamId)
	self.isFilled = streamReadBool(streamId)
	self:run(connection)
end

function PlaceableDoghouseFoodBowlStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.doghouse)
	streamWriteBool(streamId, self.isFilled)
end

function PlaceableDoghouseFoodBowlStateEvent:run(connection)
	if self.doghouse ~= nil and self.doghouse:getIsSynchronized() then
		self.doghouse:setFoodBowlState(self.isFilled, true)
	end
	if not connection:getIsServer() then
		g_server:broadcastEvent(PlaceableDoghouseFoodBowlStateEvent.new(self.doghouse, self.isFilled), nil, connection, self.doghouse)
	end
end

function PlaceableDoghouseFoodBowlStateEvent.sendEvent(doghouse, isFilled, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(PlaceableDoghouseFoodBowlStateEvent.new(doghouse, isFilled), nil, nil, doghouse)
			return
		end
		g_client:getServerConnection():sendEvent(PlaceableDoghouseFoodBowlStateEvent.new(doghouse, isFilled))
	end
end
