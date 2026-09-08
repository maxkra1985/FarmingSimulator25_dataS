-- Local values: LandscapingSculptEvent_mt
LandscapingSculptEvent = {}
local LandscapingSculptEvent_mt = Class(LandscapingSculptEvent, Event)
InitStaticEventClass(LandscapingSculptEvent, "LandscapingSculptEvent")
function LandscapingSculptEvent.emptyNew()
	-- upvalues: (copy) LandscapingSculptEvent_mt
	return Event.new(LandscapingSculptEvent_mt, NetworkNode.CHANNEL_TERRAIN_DEFORMATION)
end

-- Local values: self
function LandscapingSculptEvent.new(validateOnly, operation, x, y, z, nx, ny, nz, d, minY, maxY, radius, strength, brushShape, smoothingDistance, terrainPaintingLayer, terrainFoliageLayer, terrainFoliageValue)
	local v20_ = LandscapingSculptEvent.emptyNew()
	v20_.runConnection = nil
	v20_.validateOnly = validateOnly
	v20_.operation = operation
	v20_.x = x
	v20_.y = y
	v20_.z = z
	v20_.nx = nx
	v20_.ny = ny
	v20_.nz = nz
	v20_.d = d
	v20_.minY = minY
	v20_.maxY = maxY
	v20_.radius = radius
	v20_.strength = strength
	v20_.smoothingDistance = smoothingDistance
	v20_.brushShape = brushShape
	v20_.terrainPaintingLayer = terrainPaintingLayer
	v20_.terrainFoliageLayer = terrainFoliageLayer
	v20_.terrainFoliageValue = terrainFoliageValue
	return v20_
end

-- Local values: self
function LandscapingSculptEvent.newServerToClient(validateOnly, errorCode, displacedVolumeOrArea)
	local v24_ = LandscapingSculptEvent.emptyNew()
	v24_.validateOnly = validateOnly
	v24_.errorCode = errorCode
	v24_.displacedVolumeOrArea = displacedVolumeOrArea
	return v24_
end

function LandscapingSculptEvent:delete() end

-- Local values: compressedParamsXZ, compressedParamsY, isNoBrush
function LandscapingSculptEvent:writeStream(streamId, connection)
	local v28_ = g_currentMission.vehicleXZPosCompressionParams
	local v29_ = g_currentMission.vehicleYPosCompressionParams
	if connection:getIsServer() then
		NetworkUtil.writeCompressedWorldPosition(streamId, self.x, v28_)
		NetworkUtil.writeCompressedWorldPosition(streamId, self.y, v29_)
		NetworkUtil.writeCompressedWorldPosition(streamId, self.z, v28_)
		NetworkUtil.writeCompressedRange(streamId, self.radius, 0, 64, 14)
		NetworkUtil.writeCompressedRange(streamId, self.strength, 0, 8, 10)
		NetworkUtil.writeCompressedRange(streamId, self.smoothingDistance, 0, 10, 10)
		streamWriteUIntN(streamId, self.operation, Landscaping.OPERATION_NUM_SEND_BITS)
		streamWriteUIntN(streamId, self.brushShape, Landscaping.BRUSH_SHAPE_NUM_SEND_BITS)
		streamWriteBool(streamId, self.validateOnly)
		if self.operation == Landscaping.OPERATION.PAINT then
			local v30_ = self.terrainPaintingLayer == TerrainDeformation.NO_TERRAIN_BRUSH
			if not streamWriteBool(streamId, v30_) then
				streamWriteUIntN(streamId, self.terrainPaintingLayer, TerrainDeformation.LAYER_SEND_NUM_BITS)
			end
		end
		if self.operation == Landscaping.OPERATION.FOLIAGE then
			streamWriteUIntN(streamId, self.terrainFoliageLayer, TerrainDeformation.LAYER_SEND_NUM_BITS)
			streamWriteUIntN(streamId, self.terrainFoliageValue, 5)
		end
		if self.operation == Landscaping.OPERATION.SLOPE then
			NetworkUtil.writeCompressedRange(streamId, self.nx, -1, 1, 16)
			NetworkUtil.writeCompressedRange(streamId, self.ny, -1, 1, 16)
			NetworkUtil.writeCompressedRange(streamId, self.nz, -1, 1, 16)
			streamWriteFloat32(streamId, self.d)
			NetworkUtil.writeCompressedWorldPosition(streamId, self.minY, v29_)
			NetworkUtil.writeCompressedWorldPosition(streamId, self.maxY, v29_)
			return
		end
	else
		streamWriteUIntN(streamId, self.errorCode, TerrainDeformation.STATE_SEND_NUM_BITS)
		streamWriteBool(streamId, self.validateOnly)
		if streamWriteBool(streamId, self.errorCode == TerrainDeformation.STATE_SUCCESS) then
			streamWriteFloat32(streamId, self.displacedVolumeOrArea)
		end
	end
end

-- Local values: compressedParamsXZ, compressedParamsY, isNoBrush
function LandscapingSculptEvent:readStream(streamId, connection)
	local v34_ = g_currentMission.vehicleXZPosCompressionParams
	local v35_ = g_currentMission.vehicleYPosCompressionParams
	if connection:getIsServer() then
		self.errorCode = streamReadUIntN(streamId, TerrainDeformation.STATE_SEND_NUM_BITS)
		self.validateOnly = streamReadBool(streamId)
		if streamReadBool(streamId) then
			self.displacedVolumeOrArea = streamReadFloat32(streamId)
		else
			self.displacedVolumeOrArea = 0
		end
	else
		self.x = NetworkUtil.readCompressedWorldPosition(streamId, v34_)
		self.y = NetworkUtil.readCompressedWorldPosition(streamId, v35_)
		self.z = NetworkUtil.readCompressedWorldPosition(streamId, v34_)
		self.radius = NetworkUtil.readCompressedRange(streamId, 0, 64, 14)
		self.strength = NetworkUtil.readCompressedRange(streamId, 0, 8, 10)
		self.smoothingDistance = NetworkUtil.readCompressedRange(streamId, 0, 10, 10)
		self.operation = streamReadUIntN(streamId, Landscaping.OPERATION_NUM_SEND_BITS)
		self.brushShape = streamReadUIntN(streamId, Landscaping.BRUSH_SHAPE_NUM_SEND_BITS)
		self.validateOnly = streamReadBool(streamId)
		if self.operation == Landscaping.OPERATION.PAINT then
			if streamReadBool(streamId) then
				self.terrainPaintingLayer = TerrainDeformation.NO_TERRAIN_BRUSH
			else
				self.terrainPaintingLayer = streamReadUIntN(streamId, TerrainDeformation.LAYER_SEND_NUM_BITS)
			end
		end
		if self.operation == Landscaping.OPERATION.FOLIAGE then
			self.terrainFoliageLayer = streamReadUIntN(streamId, TerrainDeformation.LAYER_SEND_NUM_BITS)
			self.terrainFoliageValue = streamReadUIntN(streamId, 5)
		end
		if self.operation == Landscaping.OPERATION.SLOPE then
			self.nx = NetworkUtil.readCompressedRange(streamId, -1, 1, 16)
			self.ny = NetworkUtil.readCompressedRange(streamId, -1, 1, 16)
			self.nz = NetworkUtil.readCompressedRange(streamId, -1, 1, 16)
			self.d = streamReadFloat32(streamId)
			self.minY = NetworkUtil.readCompressedWorldPosition(streamId, v35_)
			self.maxY = NetworkUtil.readCompressedWorldPosition(streamId, v35_)
		end
	end
	self:run(connection)
end

-- Local values: userId, landscaping
function LandscapingSculptEvent:run(connection)
	if connection:getIsServer() or g_currentMission == nil then
		g_messageCenter:publish(LandscapingSculptEvent, self.validateOnly, self.errorCode, self.displacedVolumeOrArea)
	else
		self.runConnection = connection
		local v38_ = g_currentMission.userManager:getUserIdByConnection(connection)
		Landscaping.new(g_terrainDeformationQueue, g_densityMapHeightManager.placementCollisionMap, v38_, self.validateOnly, self.onSculptingFinished, self):sculpt(self.x, self.y, self.z, self.nx, self.ny, self.nz, self.d, self.minY, self.maxY, self.radius, self.strength, self.brushShape, self.operation, self.smoothingDistance, self.terrainPaintingLayer, self.terrainFoliageLayer, self.terrainFoliageValue)
	end
end

-- Local values: response
function LandscapingSculptEvent:onSculptingFinished(errorCode, displacedVolumeOrArea, _)
	if self.runConnection ~= nil and self.runConnection.isConnected then
		local v42_ = LandscapingSculptEvent.newServerToClient(self.validateOnly, errorCode, displacedVolumeOrArea)
		self.runConnection:sendEvent(v42_)
	end
end
