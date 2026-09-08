-- Local values: HandsPickUpObjectEvent_mt
HandsPickUpObjectEvent = {}
local HandsPickUpObjectEvent_mt = Class(HandsPickUpObjectEvent, Event)
InitStaticEventClass(HandsPickUpObjectEvent, "HandsPickUpObjectEvent")
function HandsPickUpObjectEvent.emptyNew()
	-- upvalues: (copy) HandsPickUpObjectEvent_mt
	return Event.new(HandsPickUpObjectEvent_mt)
end

-- Local values: self
function HandsPickUpObjectEvent.new(hands, target)
	local v4_ = HandsPickUpObjectEvent.emptyNew()
	v4_.hands = hands
	v4_.target = target
	return v4_
end

-- Local values: isSplitShape, nodeObject
function HandsPickUpObjectEvent:readStream(streamId, connection)
	self.hands = NetworkUtil.readNodeObject(streamId)
	self.target = {}
	self.target.distance = NetworkUtil.readCompressedRange(streamId, 0, HandToolHands.PICKUP_DISTANCE, 10)
	if streamReadBool(streamId) then
		self.target.node = readSplitShapeIdFromStream(streamId)
		if self.target.node == 0 then
			Logging.error("Picked up split shape is not synced!")
			self.target.node = nil
		end
	else
		local v8_ = NetworkUtil.readNodeObject(streamId)
		if v8_ == nil then
			Logging.error("Could not find picked up node object!")
		else
			self.target.node = v8_.rootNode or v8_.nodeId
		end
	end
	self:run(connection)
end

-- Local values: isSplitShape, nodeObject
function HandsPickUpObjectEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.hands)
	NetworkUtil.writeCompressedRange(streamId, self.target.distance, 0, HandToolHands.PICKUP_DISTANCE, 10)
	local v11_
	if self.target.node == nil or self.target.node == 0 then
		v11_ = false
	else
		v11_ = getHasClassId(self.target.node, ClassIds.MESH_SPLIT_SHAPE)
	end
	streamWriteBool(streamId, v11_)
	local v12_ = g_currentMission:getNodeObject(self.target.node)
	if v11_ then
		writeSplitShapeIdToStream(streamId, self.target.node)
		return
	elseif v12_ == nil then
		local v13_ = Logging.error
		local v14_ = self.target.node
		v13_("Invalid picked up object! Is not a split shape or object! id: %s", (tostring(v14_)))
	else
		NetworkUtil.writeNodeObject(streamId, v12_)
	end
end

function HandsPickUpObjectEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.hands)
	end
	if self.hands ~= nil and (self.hands:getIsSynchronized() and not (self.hands:pickUpTarget(self.target, true) or connection:getIsServer())) then
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
