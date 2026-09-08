-- Local values: SprayCanEvent_mt
SprayCanEvent = {}
local SprayCanEvent_mt = Class(SprayCanEvent, Event)
InitStaticEventClass(SprayCanEvent, "SprayCanEvent")
function SprayCanEvent.emptyNew()
	-- upvalues: (copy) SprayCanEvent_mt
	return Event.new(SprayCanEvent_mt)
end

-- Local values: self
function SprayCanEvent.new(sprayCan, treeMarkerTypeIndex, splitShapeId, x, y, z, hitX, hitY, hitZ)
	local v11_ = SprayCanEvent.emptyNew()
	v11_.sprayCan = sprayCan
	v11_.treeMarkerTypeIndex = treeMarkerTypeIndex
	v11_.splitShapeId = splitShapeId
	v11_.x = x
	v11_.y = y
	v11_.z = z
	v11_.hitX = hitX
	v11_.hitY = hitY
	v11_.hitZ = hitZ
	return v11_
end

-- Local values: paramsXZ, paramsY
function SprayCanEvent:readStream(streamId, connection)
	self.sprayCan = NetworkUtil.readNodeObject(streamId)
	self.treeMarkerTypeIndex = streamReadUInt8(streamId)
	if streamReadBool(streamId) then
		self.splitShapeId = readSplitShapeIdFromStream(streamId)
		local v15_ = g_currentMission.treeMarkerSystem.xzWorldPosCompressionParams
		local v16_ = g_currentMission.treeMarkerSystem.yWorldPosCompressionParams
		self.x = NetworkUtil.readCompressedWorldPosition(streamId, v15_)
		self.y = NetworkUtil.readCompressedWorldPosition(streamId, v16_)
		self.z = NetworkUtil.readCompressedWorldPosition(streamId, v15_)
		self.hitX = NetworkUtil.readCompressedWorldPosition(streamId, v15_)
		self.hitY = NetworkUtil.readCompressedWorldPosition(streamId, v16_)
		self.hitZ = NetworkUtil.readCompressedWorldPosition(streamId, v15_)
	end
	self:run(connection)
end

-- Local values: paramsXZ, paramsY
function SprayCanEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.sprayCan)
	streamWriteUInt8(streamId, self.treeMarkerTypeIndex)
	if streamWriteBool(streamId, self.splitShapeId ~= nil) then
		writeSplitShapeIdToStream(streamId, self.splitShapeId)
		local v19_ = g_currentMission.treeMarkerSystem.xzWorldPosCompressionParams
		local v20_ = g_currentMission.treeMarkerSystem.yWorldPosCompressionParams
		NetworkUtil.writeCompressedWorldPosition(streamId, self.x, v19_)
		NetworkUtil.writeCompressedWorldPosition(streamId, self.y, v20_)
		NetworkUtil.writeCompressedWorldPosition(streamId, self.z, v19_)
		NetworkUtil.writeCompressedWorldPosition(streamId, self.hitX, v19_)
		NetworkUtil.writeCompressedWorldPosition(streamId, self.hitY, v20_)
		NetworkUtil.writeCompressedWorldPosition(streamId, self.hitZ, v19_)
	end
end

function SprayCanEvent:run(connection)
	if g_currentMission:getIsServer() then
		g_server:broadcastEvent(SprayCanEvent.new(self.sprayCan, self.treeMarkerTypeIndex, self.splitShapeId, self.x, self.y, self.z, self.hitX, self.hitY, self.hitZ), false)
	end
	if self.sprayCan ~= nil and self.sprayCan:getIsSynchronized() then
		self.sprayCan:tryToAddTreeMarker(self.treeMarkerTypeIndex, self.splitShapeId, self.x, self.y, self.z, self.hitX, self.hitY, self.hitZ)
	end
end
