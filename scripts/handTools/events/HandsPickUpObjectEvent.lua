HandsPickUpObjectEvent = {}
local HandsPickUpObjectEvent_mt = Class(HandsPickUpObjectEvent, Event)
InitStaticEventClass(HandsPickUpObjectEvent, "HandsPickUpObjectEvent")
function HandsPickUpObjectEvent.emptyNew()
	local self = Event.new(HandsPickUpObjectEvent_mt)
	return self
end
function HandsPickUpObjectEvent.new(hands, target)
	local self = HandsPickUpObjectEvent.emptyNew()
	self.hands = hands
	self.target = target
	return self
end
function HandsPickUpObjectEvent:readStream(streamId, connection)
	self.hands = NetworkUtil.readNodeObject(streamId)
	self.target = {}
	self.target.distance = NetworkUtil.readCompressedRange(streamId, 0, HandToolHands.PICKUP_DISTANCE, 10)
	local isSplitShape = streamReadBool(streamId)
	if isSplitShape then
		self.target.node = readSplitShapeIdFromStream(streamId)
		if self.target.node == 0 then
			Logging.error("Picked up split shape is not synced!")
			self.target.node = nil
		end
	else
		local nodeObject = NetworkUtil.readNodeObject(streamId)
		if nodeObject ~= nil then
			self.target.node = nodeObject.rootNode or nodeObject.nodeId
		else
			Logging.error("Could not find picked up node object!")
		end
	end
	self:run(connection)
end
function HandsPickUpObjectEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.hands)
	NetworkUtil.writeCompressedRange(streamId, self.target.distance, 0, HandToolHands.PICKUP_DISTANCE, 10)
	local isSplitShape = false
	if self.target.node ~= nil then
		isSplitShape = false
		if self.target.node ~= 0 then
			isSplitShape = getHasClassId(self.target.node, ClassIds.MESH_SPLIT_SHAPE)
		end
	end
	streamWriteBool(streamId, isSplitShape)
	local nodeObject = g_currentMission:getNodeObject(self.target.node)
	if isSplitShape then
		writeSplitShapeIdToStream(streamId, self.target.node)
	elseif nodeObject ~= nil then
		NetworkUtil.writeNodeObject(streamId, nodeObject)
	else
		Logging.error("Invalid picked up object! Is not a split shape or object! id: %s", tostring(self.target.node))
	end
end
function HandsPickUpObjectEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.hands)
	end
	if self.hands ~= nil and (self.hands:getIsSynchronized() and (not self.hands:pickUpTarget(self.target, true) and not connection:getIsServer())) then
		connection:sendEvent(HandsPickUpFailedEvent.new(self.hands))
	end
end
function HandsPickUpObjectEvent.sendEvent(hands, target, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(HandsPickUpObjectEvent.new(hands, target), nil, nil, hands)
			return
		end
		g_client:getServerConnection():sendEvent(HandsPickUpObjectEvent.new(hands, target))
	end
end
