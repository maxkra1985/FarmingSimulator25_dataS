-- Local values: SetSplitShapesEvent_mt
SetSplitShapesEvent = {}
local SetSplitShapesEvent_mt = Class(SetSplitShapesEvent, Event)
InitStaticEventClass(SetSplitShapesEvent, "SetSplitShapesEvent")
SetSplitShapesEvent.PartSizeBits = 160000
function SetSplitShapesEvent.emptyNew()
	-- upvalues: (copy) SetSplitShapesEvent_mt
	local v2_ = Event.new(SetSplitShapesEvent_mt)
	v2_.streamId = createStream()
	return v2_
end

-- Local values: self
function SetSplitShapesEvent.newAck(streamCurrentOffsetAck)
	local v4_ = SetSplitShapesEvent.emptyNew()
	v4_.streamCurrentOffsetAck = streamCurrentOffsetAck
	return v4_
end

-- Local values: self
function SetSplitShapesEvent.newReceiving(streamTotalSize)
	local v6_ = SetSplitShapesEvent.emptyNew()
	v6_.streamTotalSize = streamTotalSize
	return v6_
end
function SetSplitShapesEvent.new()
	local v7_ = SetSplitShapesEvent.emptyNew()
	local v8_ = v7_.streamId
	local v9_ = g_currentMission.mapsSplitShapeFileIds
	local v10_ = #v9_
	streamWriteInt32(v8_, v10_)
	for v11_ = 1, v10_ do
		streamWriteInt32(v8_, v9_[v11_])
	end
	g_treePlantManager:writeToClientStream(v8_)
	writeSplitShapesToStream(v8_)
	v7_.streamCurrentOffset = 0
	v7_.streamTotalSize = streamGetWriteOffset(v8_)
	v7_.percentage = 0
	return v7_
end

function SetSplitShapesEvent:delete()
	if self.streamId ~= 0 then
		delete(self.streamId)
		self.streamId = 0
	end
end

-- Local values: currentMission, streamCurrentOffset, streamTotalSizeInit, event, streamTotalSize, sizeToRead, streamCurrentOffsetAck, syncPlayer, splitShapesEvent
function SetSplitShapesEvent:readStream(streamId, connection)
	local v15_ = g_currentMission
	if connection:getIsServer() then
		local v16_ = streamReadUInt32(streamId)
		Logging.devInfo("SetSplitShapesEvent:readStream-currentOffset: %d", v16_)
		if v16_ == 0 then
			local v17_ = streamReadUInt32(streamId)
			v15_.receivingSplitShapesEvent = SetSplitShapesEvent.newReceiving(v17_)
			Logging.devInfo("SetSplitShapesEvent:readStream-totalSize: %d", v17_)
		end
		local v18_ = v15_.receivingSplitShapesEvent
		local v19_ = v18_.streamTotalSize
		local v20_ = v18_.streamTotalSize - v16_
		local v21_ = SetSplitShapesEvent.PartSizeBits
		local v22_ = math.min(v20_, v21_)
		Logging.devInfo("SetSplitShapesEvent:readStream-readData: %d", v22_)
		streamWriteStream(v18_.streamId, streamId, v22_, true)
		local v23_ = v16_ + v22_
		local v24_ = v23_ / v19_
		v18_.percentage = math.clamp(v24_, 0, 1)
		v15_:onSplitShapesProgress(connection, v18_.percentage)
		connection:sendEvent(SetSplitShapesEvent.newAck(v23_), true)
		if v23_ == v19_ then
			v18_:processReadData()
			v15_.receivingSplitShapesEvent:delete()
			v15_.receivingSplitShapesEvent = nil
			return
		end
	else
		local v25_ = streamReadUInt32(streamId)
		local v26_ = v15_.playersSynchronizing[connection]
		if v26_ ~= nil and v26_.splitShapesEvent ~= nil then
			local v27_ = v26_.splitShapesEvent
			local v28_ = v25_ / v27_.streamTotalSize
			v27_.percentage = math.clamp(v28_, 0, 1)
			if v25_ < v27_.streamTotalSize then
				connection:sendEvent(v27_, false)
			end
			v15_:onSplitShapesProgress(connection, v27_.percentage)
		end
	end
end

-- Local values: currentMission, streamCurrentOffset, readOffset, start
function SetSplitShapesEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		streamWriteUInt32(streamId, self.streamCurrentOffsetAck)
	else
		local v32_ = g_currentMission.playersSynchronizing[connection].splitShapesEvent == self
		assert(v32_)
		local v33_ = self.streamCurrentOffset
		self.streamCurrentOffset = self.streamCurrentOffset + SetSplitShapesEvent.PartSizeBits
		streamWriteUInt32(streamId, v33_)
		Logging.devInfo("SetSplitShapesEvent:writeStream-currentOffset: %d", v33_)
		if v33_ == 0 then
			streamWriteUInt32(streamId, self.streamTotalSize)
			Logging.devInfo("SetSplitShapesEvent:writeStream-totalSize: %d", self.streamTotalSize)
		end
		local v34_ = streamGetReadOffset(self.streamId)
		streamSetReadOffset(self.streamId, v33_)
		local v35_ = streamGetWriteOffset(streamId)
		streamWriteStream(streamId, self.streamId, SetSplitShapesEvent.PartSizeBits, true)
		Logging.devInfo("SetSplitShapesEvent:writeStream-writeData: %d", streamGetWriteOffset(streamId) - v35_)
		streamSetReadOffset(self.streamId, v34_)
	end
end

-- Local values: streamId, mapsSplitShapeFileIds, numFileIds, i, fileId
function SetSplitShapesEvent:processReadData()
	local v37_ = self.streamId
	local v38_ = g_currentMission.mapsSplitShapeFileIds
	for v39_ = 1, streamReadInt32(v37_) do
		local v40_ = streamReadInt32(v37_)
		setSplitShapesFileIdMapping(v38_[v39_], v40_)
	end
	g_treePlantManager:readFromServerStream(v37_)
	readSplitShapesFromStream(v37_)
end

function SetSplitShapesEvent:run(connection) end
