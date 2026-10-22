FenceRequestDeleteSegmentPartEvent = {}
local FenceRequestDeleteSegmentPartEvent_mt = Class(FenceRequestDeleteSegmentPartEvent, Event)
InitStaticEventClass(FenceRequestDeleteSegmentPartEvent, "FenceRequestDeleteSegmentPartEvent")
function FenceRequestDeleteSegmentPartEvent.emptyNew()
	return Event.new(FenceRequestDeleteSegmentPartEvent_mt, NetworkNode.CHANNEL_MAIN)
end
function FenceRequestDeleteSegmentPartEvent.newClientToServer(fencePlaceable, segmentId, childIndex, hitX, hitY, hitZ, wholeSegment)
	local self = FenceRequestDeleteSegmentPartEvent.emptyNew()
	self.fencePlaceable = fencePlaceable
	self.segmentId = segmentId
	self.childIndex = childIndex
	self.hitX = hitX
	self.hitY = hitY
	self.hitZ = hitZ
	self.wholeSegment = wholeSegment
	return self
end
function FenceRequestDeleteSegmentPartEvent.newServerToClient(success)
	local self = FenceRequestDeleteSegmentPartEvent.emptyNew()
	self.success = success
	return self
end
function FenceRequestDeleteSegmentPartEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		local paramsXZ = g_currentMission.vehicleXZPosCompressionParams
		local paramsY = g_currentMission.vehicleYPosCompressionParams
		local fencePlaceable = NetworkUtil.readNodeObject(streamId)
		self.fencePlaceable = fencePlaceable
		self.segmentId = streamReadUInt16(streamId)
		self.childIndex = streamReadUInt16(streamId)
		self.hitX = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
		self.hitY = NetworkUtil.readCompressedWorldPosition(streamId, paramsY)
		self.hitZ = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
		self.wholeSegment = streamReadBool(streamId)
	else
		self.success = streamReadBool(streamId)
	end
	self:run(connection)
end
function FenceRequestDeleteSegmentPartEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		local paramsXZ = g_currentMission.vehicleXZPosCompressionParams
		local paramsY = g_currentMission.vehicleYPosCompressionParams
		NetworkUtil.writeNodeObject(streamId, self.fencePlaceable)
		streamWriteUInt16(streamId, self.segmentId)
		streamWriteUInt16(streamId, self.childIndex)
		NetworkUtil.writeCompressedWorldPosition(streamId, self.hitX, paramsXZ)
		NetworkUtil.writeCompressedWorldPosition(streamId, self.hitY, paramsY)
		NetworkUtil.writeCompressedWorldPosition(streamId, self.hitZ, paramsXZ)
		streamWriteBool(streamId, self.wholeSegment)
	else
		streamWriteBool(streamId, self.success)
	end
end
function FenceRequestDeleteSegmentPartEvent.findNearestChild(root, x, y, z)
	local closestNode = nil
	local closestDistance = math.huge
	for i = 0, getNumOfChildren(root) - 1 do
		local child = getChildAt(root, i)
		local cx, cy, cz = getWorldTranslation(child)
		local distance = MathUtil.vector3Length(cx - x, cy - y, cz - z)
		if distance < closestDistance then
			closestDistance = distance
			closestNode = child
		end
	end
	return closestNode
end
function FenceRequestDeleteSegmentPartEvent:run(connection)
	if connection:getIsServer() then
		g_messageCenter:publish(FenceRequestDeleteSegmentPartEvent, self.success)
		return
	end
	local reply = function(success)
		if connection:getIsLocal() then
			g_messageCenter:publish(FenceRequestDeleteSegmentPartEvent, success)
		else
			connection:sendEvent(FenceRequestDeleteSegmentPartEvent.newServerToClient(success))
		end
	end
	if self.fencePlaceable == nil or not self.fencePlaceable:getIsSynchronized() then
		if connection:getIsLocal() then
			g_messageCenter:publish(FenceRequestDeleteSegmentPartEvent, false)
			return
		else
			connection:sendEvent(FenceRequestDeleteSegmentPartEvent.newServerToClient(false))
			return
		end
	end
	local fence = self.fencePlaceable:getFence()
	local segment = fence:getSegmentById(self.segmentId)
	if segment == nil then
		if connection:getIsLocal() then
			g_messageCenter:publish(FenceRequestDeleteSegmentPartEvent, false)
		else
			connection:sendEvent(FenceRequestDeleteSegmentPartEvent.newServerToClient(false))
		end
	elseif not fence:getAllowSegmentDeletion() then
		if connection:getIsLocal() then
			g_messageCenter:publish(FenceRequestDeleteSegmentPartEvent, false)
		else
			connection:sendEvent(FenceRequestDeleteSegmentPartEvent.newServerToClient(false))
		end
	else
		local player = g_currentMission:getPlayerByConnection(connection)
		local farmId = player ~= nil and player.farmId or nil
		local canModify = false
		if farmId ~= nil then
			canModify = segment:getCanBeModifiedByFarmId(farmId)
		end
		if not canModify or not segment:getCanBeDeleted() then
			if connection:getIsLocal() then
				g_messageCenter:publish(FenceRequestDeleteSegmentPartEvent, false)
				return
			else
				connection:sendEvent(FenceRequestDeleteSegmentPartEvent.newServerToClient(false))
				return
			end
		end
		local node = getChildAt(segment.root, self.childIndex)
		if node == nil or node == 0 then
			node = FenceRequestDeleteSegmentPartEvent.findNearestChild(segment.root, self.hitX, self.hitY, self.hitZ) or 0
		end
		if node ~= 0 then
			local oldSegmentId = segment.id
			local newSegments = fence:deleteSegmentPart(segment, node, self.wholeSegment)
			if newSegments == nil then
				if connection:getIsLocal() then
					g_messageCenter:publish(FenceRequestDeleteSegmentPartEvent, false)
				else
					connection:sendEvent(FenceRequestDeleteSegmentPartEvent.newServerToClient(false))
				end
			elseif fence:getNumSegments() == 0 then
				self.fencePlaceable:delete()
				if connection:getIsLocal() then
					g_messageCenter:publish(FenceRequestDeleteSegmentPartEvent, true)
				else
					connection:sendEvent(FenceRequestDeleteSegmentPartEvent.newServerToClient(true))
				end
			else
				g_server:broadcastEvent(FenceDeleteSegmentEvent.new(self.fencePlaceable, oldSegmentId), false, nil)
				for _, newSegment in ipairs(newSegments) do
					g_server:broadcastEvent(FenceSegmentEvent.new(self.fencePlaceable, newSegment), false, nil, self.fencePlaceable)
				end
				if connection:getIsLocal() then
					g_messageCenter:publish(FenceRequestDeleteSegmentPartEvent, true)
				else
					connection:sendEvent(FenceRequestDeleteSegmentPartEvent.newServerToClient(true))
				end
			end
		elseif connection:getIsLocal() then
			g_messageCenter:publish(FenceRequestDeleteSegmentPartEvent, false)
		else
			connection:sendEvent(FenceRequestDeleteSegmentPartEvent.newServerToClient(false))
		end
	end
end
