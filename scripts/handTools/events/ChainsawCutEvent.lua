-- Local values: ChainsawCutEvent_mt
ChainsawCutEvent = {}
local ChainsawCutEvent_mt = Class(ChainsawCutEvent, Event)
InitStaticEventClass(ChainsawCutEvent, "ChainsawCutEvent")
function ChainsawCutEvent.emptyNew()
	-- upvalues: (copy) ChainsawCutEvent_mt
	return Event.new(ChainsawCutEvent_mt)
end

-- Local values: self
function ChainsawCutEvent.new(splitShapeId, x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ, farmId)
	local v15_ = ChainsawCutEvent.emptyNew()
	v15_.splitShapeId = splitShapeId
	v15_.x = x
	v15_.y = y
	v15_.z = z
	v15_.nx = nx
	v15_.ny = ny
	v15_.nz = nz
	v15_.yx = yx
	v15_.yy = yy
	v15_.yz = yz
	v15_.cutSizeY = cutSizeY
	v15_.cutSizeZ = cutSizeZ
	v15_.farmId = farmId
	return v15_
end

-- Local values: splitShapeId, x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ, farmId
function ChainsawCutEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		local v18_ = readSplitShapeIdFromStream(streamId)
		local v19_ = streamReadFloat32(streamId)
		local v20_ = streamReadFloat32(streamId)
		local v21_ = streamReadFloat32(streamId)
		local v22_ = streamReadFloat32(streamId)
		local v23_ = streamReadFloat32(streamId)
		local v24_ = streamReadFloat32(streamId)
		local v25_ = streamReadFloat32(streamId)
		local v26_ = streamReadFloat32(streamId)
		local v27_ = streamReadFloat32(streamId)
		local v28_ = streamReadFloat32(streamId)
		local v29_ = streamReadFloat32(streamId)
		local v30_ = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
		if v18_ ~= 0 then
			ChainsawUtil.cutSplitShape(v18_, v19_, v20_, v21_, v22_, v23_, v24_, v25_, v26_, v27_, v28_, v29_, v30_)
		end
	end
end

function ChainsawCutEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		writeSplitShapeIdToStream(streamId, self.splitShapeId)
		streamWriteFloat32(streamId, self.x)
		streamWriteFloat32(streamId, self.y)
		streamWriteFloat32(streamId, self.z)
		streamWriteFloat32(streamId, self.nx)
		streamWriteFloat32(streamId, self.ny)
		streamWriteFloat32(streamId, self.nz)
		streamWriteFloat32(streamId, self.yx)
		streamWriteFloat32(streamId, self.yy)
		streamWriteFloat32(streamId, self.yz)
		streamWriteFloat32(streamId, self.cutSizeY)
		streamWriteFloat32(streamId, self.cutSizeZ)
		streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	end
end

function ChainsawCutEvent:run(connection)
	print("Error: ChainsawCutEvent is not allowed to be executed on a local client")
end
