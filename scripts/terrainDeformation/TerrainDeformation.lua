TerrainDeformation = {}
local TerrainDeformation_mt = Class(TerrainDeformation)
TerrainDeformation.STATE_SUCCESS = 0
TerrainDeformation.STATE_FAILED_BLOCKED = 1
TerrainDeformation.STATE_FAILED_COLLIDE_WITH_OBJECT = 2
TerrainDeformation.STATE_FAILED_TO_DEFORM = 3
TerrainDeformation.STATE_CANCELLED = 4
TerrainDeformation.STATE_FAILED_NOT_ENOUGH_MONEY = 5
TerrainDeformation.STATE_FAILED_NOT_OWNED = 6
TerrainDeformation.STATE_SEND_NUM_BITS = 3
TerrainDeformation.LAYER_SEND_NUM_BITS = 8
TerrainDeformation.NO_TERRAIN_BRUSH = -1
function TerrainDeformation.new(terrainNode)
	local self = setmetatable({}, TerrainDeformation_mt)
	self.terrainDeformationId = createTerrainDeformation(terrainNode)
	return self
end
function TerrainDeformation:delete()
	if entityExists(self.terrainDeformationId) then
		delete(self.terrainDeformationId)
	end
	self.terrainDeformationId = nil
end
function TerrainDeformation:enableDeformationMode()
	if self.terrainDeformationId == nil then
		return
	else
		enableTerrainDeformationMode(self.terrainDeformationId)
	end
end
function TerrainDeformation:enableAreaBasedDeformationMode()
	if self.terrainDeformationId == nil then
		return
	else
		enableAreaBasedTerrainDeformationMode(self.terrainDeformationId)
	end
end
function TerrainDeformation:enableAdditiveDeformationMode()
	if self.terrainDeformationId == nil then
		return
	else
		enableTerrainDeformationHeightAdditiveMode(self.terrainDeformationId)
	end
end
function TerrainDeformation:setAdditiveHeightChangeAmount(amount)
	if self.terrainDeformationId == nil then
		return
	else
		setTerrainDeformationHeightChangeAmount(self.terrainDeformationId, amount)
	end
end
function TerrainDeformation:setHeightTarget(minY, maxY, nx, ny, nz, d)
	if self.terrainDeformationId == nil then
		return
	else
		setTerrainDeformationHeightSetTarget(self.terrainDeformationId, minY, maxY, nx, ny, nz, d)
	end
end
function TerrainDeformation:enableSetDeformationMode()
	if self.terrainDeformationId == nil then
		return
	else
		enableTerrainDeformationHeightSetMode(self.terrainDeformationId)
	end
end
function TerrainDeformation:enableSmoothingMode()
	if self.terrainDeformationId == nil then
		return
	else
		enableTerrainDeformationHeightSmoothingMode(self.terrainDeformationId)
	end
end
function TerrainDeformation:enablePaintingMode()
	if self.terrainDeformationId == nil then
		return
	else
		enableTerrainDeformationPaintingMode(self.terrainDeformationId)
	end
end
function TerrainDeformation:clearAreas()
	if self.terrainDeformationId == nil then
		return
	else
		clearTerrainDeformationAreas(self.terrainDeformationId)
	end
end
function TerrainDeformation:addSoftSquareBrush(x, z, size, hardness, strength, terrainBrushId)
	if self.terrainDeformationId == nil then
		return
	else
		addTerrainDeformationWorldspaceSoftBrush(self.terrainDeformationId, x, z, BrushType.BRUSH_TYPE_SQUARE, size, hardness, strength, terrainBrushId or TerrainDeformation.NO_TERRAIN_BRUSH)
	end
end
function TerrainDeformation:addSoftCircleBrush(x, z, radius, hardness, strength, terrainBrushId)
	if self.terrainDeformationId == nil then
		return
	else
		addTerrainDeformationWorldspaceSoftBrush(self.terrainDeformationId, x, z, BrushType.BRUSH_TYPE_CIRCLE, radius, hardness, strength, terrainBrushId or TerrainDeformation.NO_TERRAIN_BRUSH)
	end
end
function TerrainDeformation:addArea(x, y, z, side1X, side1Y, side1Z, side2X, side2Y, side2Z, terrainBrushId, writeBlockedAreaMap)
	if self.terrainDeformationId == nil then
		return
	else
		addTerrainDeformationArea(self.terrainDeformationId, x, y, z, side1X, side1Y, side1Z, side2X, side2Y, side2Z, terrainBrushId or TerrainDeformation.NO_TERRAIN_BRUSH, writeBlockedAreaMap)
	end
end
function TerrainDeformation:addPolygonalArea(vertexPositions, terrainBrushId, writeBlockedAreaMap)
	if self.terrainDeformationId == nil then
		return
	else
		addTerrainDeformationPolygonalArea(self.terrainDeformationId, vertexPositions, terrainBrushId or TerrainDeformation.NO_TERRAIN_BRUSH, writeBlockedAreaMap)
	end
end
function TerrainDeformation:setOutsideAreaBrush(brushId)
	if self.terrainDeformationId == nil then
		return
	else
		setTerrainDeformationOutsideAreaBrush(self.terrainDeformationId, brushId or TerrainDeformation.NO_TERRAIN_BRUSH)
	end
end
function TerrainDeformation:setOutsideAreaConstraints(maxSmoothDistance, maxSlope, maxEdgeAngle)
	if self.terrainDeformationId == nil then
		return
	else
		local steepness = maxSlope / 0.7853981633974483
		setTerrainDeformationOutsideAreaConstraints(self.terrainDeformationId, maxSmoothDistance, steepness, maxEdgeAngle)
	end
end
function TerrainDeformation:getBlockedAreaMapSize()
	if self.terrainDeformationId == nil then
		return
	else
		return getTerrainDeformationBlockedAreaMapSize(self.terrainDeformationId)
	end
end
function TerrainDeformation:setDynamicObjectCollisionMask(collisionMask)
	if self.terrainDeformationId == nil then
		return
	else
		setTerrainDeformationDynamicObjectCollisionMask(self.terrainDeformationId, collisionMask)
	end
end
function TerrainDeformation:setDynamicObjectMaxDisplacement(maxDisplacement)
	if self.terrainDeformationId == nil then
		return
	else
		setTerrainDeformationDynamicObjectMaxDisplacement(self.terrainDeformationId, maxDisplacement)
	end
end
function TerrainDeformation:setBlockedAreaMap(bitVectorMapId, channel)
	if bitVectorMapId == nil or bitVectorMapId == 0 then
		return
	end
	if self.terrainDeformationId == nil then
		return
	else
		setTerrainDeformationBlockedAreaMap(self.terrainDeformationId, bitVectorMapId, channel)
	end
end
function TerrainDeformation:setBlockedAreaMaxDisplacement(maxDisplacement)
	if self.terrainDeformationId == nil then
		return
	else
		setTerrainDeformationBlockedAreaMaxDisplacement(self.terrainDeformationId, maxDisplacement)
	end
end
function TerrainDeformation:apply(previewOnly, callbackFunc, callbackObject, callbackArgs)
	if self.terrainDeformationId == nil then
		return
	else
		setTerrainDeformationTyreTrackSystem(self.terrainDeformationId, g_currentMission.tireTrackSystem.tireTrackSystemId)
		applyTerrainDeformation(self.terrainDeformationId, previewOnly, callbackFunc, callbackObject, callbackArgs)
	end
end
function TerrainDeformation:cancel()
	if self.terrainDeformationId == nil then
		return
	else
		cancelTerrainDeformation(self.terrainDeformationId)
	end
end
