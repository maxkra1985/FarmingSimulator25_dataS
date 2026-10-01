SetSplitShapesEvent = {}
local SetSplitShapesEvent_mt = Class(SetSplitShapesEvent, Event)
InitStaticEventClass(SetSplitShapesEvent, "SetSplitShapesEvent")
SetSplitShapesEvent.PartSizeBits = 160000
function SetSplitShapesEvent.emptyNew()
	local self = Event.new(SetSplitShapesEvent_mt)
	self.streamId = createStream()
	return self
end
function SetSplitShapesEvent.newAck(streamCurrentOffsetAck)
	local self = SetSplitShapesEvent.emptyNew()
	self.streamCurrentOffsetAck = streamCurrentOffsetAck
	return self
end
function SetSplitShapesEvent.newReceiving(streamTotalSize)
	local self = SetSplitShapesEvent.emptyNew()
	self.streamTotalSize = streamTotalSize
	return self
end
function SetSplitShapesEvent.new()
	local self = SetSplitShapesEvent.emptyNew()
	local streamId = self.streamId
	local mapsSplitShapeFileIds = g_currentMission.mapsSplitShapeFileIds
	local numFileIds = #mapsSplitShapeFileIds
	streamWriteInt32(streamId, numFileIds)
	for i = 1, numFileIds do
		streamWriteInt32(streamId, mapsSplitShapeFileIds[i])
	end
	g_treePlantManager:writeToClientStream(streamId)
	writeSplitShapesToStream(streamId)
	self.streamCurrentOffset = 0
	self.streamTotalSize = streamGetWriteOffset(streamId)
	self.percentage = 0
	return self
end
function SetSplitShapesEvent:delete()
	if self.streamId ~= 0 then
		delete(self.streamId)
		self.streamId = 0
	end
end
function SetSplitShapesEvent:readStream(streamId, connection)
	local currentMission = g_currentMission
	if connection:getIsServer() then
		local streamCurrentOffset = streamReadUInt32(streamId)
		Logging.devInfo("SetSplitShapesEvent:readStream-currentOffset: %d", streamCurrentOffset)
		if streamCurrentOffset == 0 then
			local streamTotalSizeInit = streamReadUInt32(streamId)
			currentMission.receivingSplitShapesEvent = SetSplitShapesEvent.newReceiving(streamTotalSizeInit)
			Logging.devInfo("SetSplitShapesEvent:readStream-totalSize: %d", streamTotalSizeInit)
		end
		local event = currentMission.receivingSplitShapesEvent
		local streamTotalSize = event.streamTotalSize
		local sizeToRead = math.min(event.streamTotalSize - streamCurrentOffset, SetSplitShapesEvent.PartSizeBits)
		Logging.devInfo("SetSplitShapesEvent:readStream-readData: %d", sizeToRead)
		streamWriteStream(event.streamId, streamId, sizeToRead, true)
		streamCurrentOffset = streamCurrentOffset + sizeToRead
		event.percentage = math.clamp(streamCurrentOffset / streamTotalSize, 0, 1)
		currentMission:onSplitShapesProgress(connection, event.percentage)
		connection:sendEvent(SetSplitShapesEvent.newAck(streamCurrentOffset), true)
		if streamCurrentOffset == streamTotalSize then
			event:processReadData()
			currentMission.receivingSplitShapesEvent:delete()
			currentMission.receivingSplitShapesEvent = nil
		end
	else
		local streamCurrentOffsetAck = streamReadUInt32(streamId)
		local syncPlayer = currentMission.playersSynchronizing[connection]
		if syncPlayer ~= nil and syncPlayer.splitShapesEvent ~= nil then
			local splitShapesEvent = syncPlayer.splitShapesEvent
			splitShapesEvent.percentage = math.clamp(streamCurrentOffsetAck / splitShapesEvent.streamTotalSize, 0, 1)
			if streamCurrentOffsetAck < splitShapesEvent.streamTotalSize then
				connection:sendEvent(splitShapesEvent, false)
			end
			currentMission:onSplitShapesProgress(connection, splitShapesEvent.percentage)
		end
	end
end
function SetSplitShapesEvent:writeStream(streamId, connection)
	if not connection:getIsServer() then
		local currentMission = g_currentMission
		assert(currentMission.playersSynchronizing[connection].splitShapesEvent == self)
		local streamCurrentOffset = self.streamCurrentOffset
		self.streamCurrentOffset = self.streamCurrentOffset + SetSplitShapesEvent.PartSizeBits
		streamWriteUInt32(streamId, streamCurrentOffset)
		Logging.devInfo("SetSplitShapesEvent:writeStream-currentOffset: %d", streamCurrentOffset)
		if streamCurrentOffset == 0 then
			streamWriteUInt32(streamId, self.streamTotalSize)
			Logging.devInfo("SetSplitShapesEvent:writeStream-totalSize: %d", self.streamTotalSize)
		end
		local readOffset = streamGetReadOffset(self.streamId)
		streamSetReadOffset(self.streamId, streamCurrentOffset)
		local start = streamGetWriteOffset(streamId)
		streamWriteStream(streamId, self.streamId, SetSplitShapesEvent.PartSizeBits, true)
		Logging.devInfo("SetSplitShapesEvent:writeStream-writeData: %d", streamGetWriteOffset(streamId) - start)
		streamSetReadOffset(self.streamId, readOffset)
	else
		streamWriteUInt32(streamId, self.streamCurrentOffsetAck)
	end
end
function SetSplitShapesEvent:processReadData()
	local streamId = self.streamId
	local mapsSplitShapeFileIds = g_currentMission.mapsSplitShapeFileIds
	local numFileIds = streamReadInt32(streamId)
	for i = 1, numFileIds do
		local fileId = streamReadInt32(streamId)
		setSplitShapesFileIdMapping(mapsSplitShapeFileIds[i], fileId)
	end
	g_treePlantManager:readFromServerStream(streamId)
	readSplitShapesFromStream(streamId)
end
function SetSplitShapesEvent:run(connection) end
