-- Local values: TreeMarkerEvent_mt
TreeMarkerEvent = {}
local TreeMarkerEvent_mt = Class(TreeMarkerEvent, Event)
InitStaticEventClass(TreeMarkerEvent, "TreeMarkerEvent")
function TreeMarkerEvent.emptyNew()
	-- upvalues: (copy) TreeMarkerEvent_mt
	return Event.new(TreeMarkerEvent_mt)
end

-- Local values: self
function TreeMarkerEvent.new(treeMarkers)
	local v3_ = TreeMarkerEvent.emptyNew()
	local v4_ = #treeMarkers <= 255
	assert(v4_, "Max num of treemarkers per event is 255")
	v3_.treeMarkers = treeMarkers
	return v3_
end

-- Local values: paramsX, paramsY, numMarkers, i, treeMarker, rot, scale
function TreeMarkerEvent:readStream(streamId, connection)
	local v8_ = g_currentMission.treeMarkerSystem.xTreePosCompressionParams
	local v9_ = g_currentMission.treeMarkerSystem.yTreePosCompressionParams
	self.treeMarkers = {}
	for _ = 1, streamReadUInt8(streamId) do
		local v10_ = {
			["splitShapeId"] = readSplitShapeIdFromStream(streamId),
			["treeMarkerTypeIndex"] = streamReadUInt8(streamId),
			["r"] = streamReadUInt8(streamId) / 255,
			["g"] = streamReadUInt8(streamId) / 255,
			["b"] = streamReadUInt8(streamId) / 255,
			["a"] = streamReadUInt8(streamId) / 255,
			["posX"] = NetworkUtil.readCompressedWorldPosition(streamId, v8_),
			["posY"] = NetworkUtil.readCompressedWorldPosition(streamId, v9_),
			["rotY"] = streamReadUIntN(streamId, 9) / 511 * 3.141592653589793 * 2,
			["scale"] = streamReadUIntN(streamId, 9) / 511
		}
		local v11_ = self.treeMarkers
		table.insert(v11_, v10_)
	end
	self:run(connection)
end

-- Local values: paramsX, paramsY, _, treeMarker, rot, scale
function TreeMarkerEvent:writeStream(streamId, connection)
	local v14_ = g_currentMission.treeMarkerSystem.xTreePosCompressionParams
	local v15_ = g_currentMission.treeMarkerSystem.yTreePosCompressionParams
	streamWriteUInt8(streamId, #self.treeMarkers)
	for _, v16_ in ipairs(self.treeMarkers) do
		writeSplitShapeIdToStream(streamId, v16_.splitShapeId)
		streamWriteUInt8(streamId, v16_.treeMarkerTypeIndex)
		streamWriteUInt8(streamId, v16_.r * 255)
		streamWriteUInt8(streamId, v16_.g * 255)
		streamWriteUInt8(streamId, v16_.b * 255)
		streamWriteUInt8(streamId, v16_.a * 255)
		NetworkUtil.writeCompressedWorldPosition(streamId, v16_.posX, v14_)
		NetworkUtil.writeCompressedWorldPosition(streamId, v16_.posY, v15_)
		local v17_ = v16_.rotY % 6.283185307179586
		local v18_ = streamWriteUIntN
		local v19_ = v17_ / 6.283185307179586 * 511
		local v20_ = math.floor(v19_)
		v18_(streamId, math.clamp(v20_, 0, 511), 9)
		local v21_ = v16_.scale * 511
		local v22_ = math.floor(v21_)
		streamWriteUIntN(streamId, v22_, 9)
	end
end

-- Local values: _, treeMarker, splitShapeId, treeMarkerTypeIndex, r, g, b, a, posX, posY, scale, rotY
function TreeMarkerEvent:run(connection)
	for _, v24_ in ipairs(self.treeMarkers) do
		local v25_ = v24_.splitShapeId
		local v26_ = v24_.treeMarkerTypeIndex
		local v27_ = v24_.r
		local v28_ = v24_.g
		local v29_ = v24_.b
		local v30_ = v24_.a
		local v31_ = v24_.posX
		local v32_ = v24_.posY
		local v33_ = v24_.scale
		local v34_ = v24_.rotY
		g_currentMission.treeMarkerSystem:addTreeMarker(v25_, v26_, v27_, v28_, v29_, v30_, v31_, v32_, v33_, v34_, true)
	end
end
