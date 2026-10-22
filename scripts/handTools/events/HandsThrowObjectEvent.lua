HandsThrowObjectEvent = {}
local HandsThrowObjectEvent_mt = Class(HandsThrowObjectEvent, Event)
InitStaticEventClass(HandsThrowObjectEvent, "HandsThrowObjectEvent")
HandsThrowObjectEvent.THROW_DIRECTION_NUM_BITS = 12
HandsThrowObjectEvent.THROW_FORCE_SCALAR_NUM_BITS = 8
function HandsThrowObjectEvent.emptyNew()
	local self = Event.new(HandsThrowObjectEvent_mt)
	return self
end
function HandsThrowObjectEvent.new(hands, dirX, dirY, dirZ, forceScalar)
	local self = HandsThrowObjectEvent.emptyNew()
	self.hands = hands
	self.dirX = dirX
	self.dirY = dirY
	self.dirZ = dirZ
	self.forceScalar = forceScalar
	self.isThrow = dirX ~= 0 or dirY ~= 0 or dirZ ~= 0
	return self
end
function HandsThrowObjectEvent:readStream(streamId, connection)
	self.hands = NetworkUtil.readNodeObject(streamId)
	self.isThrow = streamReadBool(streamId)
	if self.isThrow then
		self.dirX = NetworkUtil.readCompressedRange(streamId, -1, 1, HandsThrowObjectEvent.THROW_DIRECTION_NUM_BITS)
		self.dirY = NetworkUtil.readCompressedRange(streamId, -1, 1, HandsThrowObjectEvent.THROW_DIRECTION_NUM_BITS)
		self.dirZ = NetworkUtil.readCompressedRange(streamId, -1, 1, HandsThrowObjectEvent.THROW_DIRECTION_NUM_BITS)
		self.forceScalar = NetworkUtil.readCompressedRange(streamId, 0, 1, HandsThrowObjectEvent.THROW_FORCE_SCALAR_NUM_BITS)
	end
	self:run(connection)
end
function HandsThrowObjectEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.hands)
	if streamWriteBool(streamId, self.isThrow) then
		NetworkUtil.writeCompressedRange(streamId, self.dirX, -1, 1, HandsThrowObjectEvent.THROW_DIRECTION_NUM_BITS)
		NetworkUtil.writeCompressedRange(streamId, self.dirY, -1, 1, HandsThrowObjectEvent.THROW_DIRECTION_NUM_BITS)
		NetworkUtil.writeCompressedRange(streamId, self.dirZ, -1, 1, HandsThrowObjectEvent.THROW_DIRECTION_NUM_BITS)
		NetworkUtil.writeCompressedRange(streamId, self.forceScalar, 0, 1, HandsThrowObjectEvent.THROW_FORCE_SCALAR_NUM_BITS)
	end
end
function HandsThrowObjectEvent:run(connection)
	if self.hands == nil then
		return
	end
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.hands)
	end
	if not self.isThrow then
		self.hands:dropHeldItem(true)
	else
		self.hands:throwHeldItemWithForceVector(self.dirX, self.dirY, self.dirZ, self.forceScalar, true)
	end
end
function HandsThrowObjectEvent.sendEvent(hands, dirX, dirY, dirZ, forceScalar, noEventSend)
	if noEventSend == true then
		return
	elseif g_server ~= nil then
		g_server:broadcastEvent(HandsThrowObjectEvent.new(hands, dirX, dirY, dirZ, forceScalar), nil, nil, hands)
	else
		g_client:getServerConnection():sendEvent(HandsThrowObjectEvent.new(hands, dirX, dirY, dirZ, forceScalar))
	end
end
