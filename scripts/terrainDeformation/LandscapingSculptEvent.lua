LandscapingSculptEvent = {}
local LandscapingSculptEvent_mt = Class(LandscapingSculptEvent, Event)
InitStaticEventClass(LandscapingSculptEvent, "LandscapingSculptEvent")
function LandscapingSculptEvent.emptyNew()
	local self = Event.new(LandscapingSculptEvent_mt, NetworkNode.CHANNEL_TERRAIN_DEFORMATION)
	return self
end
function LandscapingSculptEvent.new(validateOnly, operation, x, y, z, nx, ny, nz, d, minY, maxY, radius, strength, brushShape, smoothingDistance, terrainPaintingLayer, terrainFoliageLayer, terrainFoliageValue)
	local self = LandscapingSculptEvent.emptyNew()
	self.runConnection = nil
	self.validateOnly = validateOnly
	self.operation = operation
	self.x = x
	self.y = y
	self.z = z
	self.nx = nx
	self.ny = ny
	self.nz = nz
	self.d = d
	self.minY = minY
	self.maxY = maxY
	self.radius = radius
	self.strength = strength
	self.smoothingDistance = smoothingDistance
	self.brushShape = brushShape
	self.terrainPaintingLayer = terrainPaintingLayer
	self.terrainFoliageLayer = terrainFoliageLayer
	self.terrainFoliageValue = terrainFoliageValue
	return self
end
function LandscapingSculptEvent.newServerToClient(validateOnly, errorCode, displacedVolumeOrArea)
	local self = LandscapingSculptEvent.emptyNew()
	self.validateOnly = validateOnly
	self.errorCode = errorCode
	self.displacedVolumeOrArea = displacedVolumeOrArea
	return self
end
function LandscapingSculptEvent:delete() end
function LandscapingSculptEvent:writeStream(streamId, connection)
	local compressedParamsXZ = g_currentMission.vehicleXZPosCompressionParams
	local compressedParamsY = g_currentMission.vehicleYPosCompressionParams
	if connection:getIsServer() then
		NetworkUtil.writeCompressedWorldPosition(streamId, self.x, compressedParamsXZ)
		NetworkUtil.writeCompressedWorldPosition(streamId, self.y, compressedParamsY)
		NetworkUtil.writeCompressedWorldPosition(streamId, self.z, compressedParamsXZ)
		NetworkUtil.writeCompressedRange(streamId, self.radius, 0, 64, 14)
		NetworkUtil.writeCompressedRange(streamId, self.strength, 0, 8, 10)
		NetworkUtil.writeCompressedRange(streamId, self.smoothingDistance, 0, 10, 10)
		streamWriteUIntN(streamId, self.operation, Landscaping.OPERATION_NUM_SEND_BITS)
		streamWriteUIntN(streamId, self.brushShape, Landscaping.BRUSH_SHAPE_NUM_SEND_BITS)
		streamWriteBool(streamId, self.validateOnly)
		if self.operation == Landscaping.OPERATION.PAINT then
			local isNoBrush = self.terrainPaintingLayer == TerrainDeformation.NO_TERRAIN_BRUSH
			if not streamWriteBool(streamId, isNoBrush) then
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
			NetworkUtil.writeCompressedWorldPosition(streamId, self.minY, compressedParamsY)
			NetworkUtil.writeCompressedWorldPosition(streamId, self.maxY, compressedParamsY)
		end
	else
		streamWriteUIntN(streamId, self.errorCode, TerrainDeformation.STATE_SEND_NUM_BITS)
		streamWriteBool(streamId, self.validateOnly)
		if streamWriteBool(streamId, self.errorCode == TerrainDeformation.STATE_SUCCESS) then
			streamWriteFloat32(streamId, self.displacedVolumeOrArea)
		end
	end
end
function LandscapingSculptEvent:readStream(streamId, connection)
	local compressedParamsXZ = g_currentMission.vehicleXZPosCompressionParams
	local compressedParamsY = g_currentMission.vehicleYPosCompressionParams
	if not connection:getIsServer() then
		self.x = NetworkUtil.readCompressedWorldPosition(streamId, compressedParamsXZ)
		self.y = NetworkUtil.readCompressedWorldPosition(streamId, compressedParamsY)
		self.z = NetworkUtil.readCompressedWorldPosition(streamId, compressedParamsXZ)
		self.radius = NetworkUtil.readCompressedRange(streamId, 0, 64, 14)
		self.strength = NetworkUtil.readCompressedRange(streamId, 0, 8, 10)
		self.smoothingDistance = NetworkUtil.readCompressedRange(streamId, 0, 10, 10)
		self.operation = streamReadUIntN(streamId, Landscaping.OPERATION_NUM_SEND_BITS)
		self.brushShape = streamReadUIntN(streamId, Landscaping.BRUSH_SHAPE_NUM_SEND_BITS)
		self.validateOnly = streamReadBool(streamId)
		if self.operation == Landscaping.OPERATION.PAINT then
			local isNoBrush = streamReadBool(streamId)
			if isNoBrush then
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
			self.minY = NetworkUtil.readCompressedWorldPosition(streamId, compressedParamsY)
			self.maxY = NetworkUtil.readCompressedWorldPosition(streamId, compressedParamsY)
		end
	else
		self.errorCode = streamReadUIntN(streamId, TerrainDeformation.STATE_SEND_NUM_BITS)
		self.validateOnly = streamReadBool(streamId)
		if streamReadBool(streamId) then
			self.displacedVolumeOrArea = streamReadFloat32(streamId)
		else
			self.displacedVolumeOrArea = 0
		end
	end
	self:run(connection)
end
function LandscapingSculptEvent:run(connection)
	if not connection:getIsServer() and g_currentMission ~= nil then
		self.runConnection = connection
		local userId = g_currentMission.userManager:getUserIdByConnection(connection)
		local landscaping = Landscaping.new(g_terrainDeformationQueue, g_densityMapHeightManager.placementCollisionMap, userId, self.validateOnly, self.onSculptingFinished, self)
		landscaping:sculpt(self.x, self.y, self.z, self.nx, self.ny, self.nz, self.d, self.minY, self.maxY, self.radius, self.strength, self.brushShape, self.operation, self.smoothingDistance, self.terrainPaintingLayer, self.terrainFoliageLayer, self.terrainFoliageValue)
		return
	end
	g_messageCenter:publish(LandscapingSculptEvent, self.validateOnly, self.errorCode, self.displacedVolumeOrArea)
end
function LandscapingSculptEvent:onSculptingFinished(errorCode, displacedVolumeOrArea, _)
	if self.runConnection ~= nil and self.runConnection.isConnected then
		local response = LandscapingSculptEvent.newServerToClient(self.validateOnly, errorCode, displacedVolumeOrArea)
		self.runConnection:sendEvent(response)
	end
end
