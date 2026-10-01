DensityMapPolygon = {}
local DensityMapPolygon_mt = Class(DensityMapPolygon)
function DensityMapPolygon.new(customMt)
	local self = setmetatable({}, customMt or DensityMapPolygon_mt)
	self.originX = 0
	self.originZ = 0
	self.originDirX = 0
	self.originDirZ = 1
	self.scaleX = 1
	self.scaleZ = 1
	self.pointsX = {}
	self.pointsZ = {}
	return self
end
function DensityMapPolygon:saveToXMLFile(xmlFile, key)
	for pointIndex = 1, #self.pointsX do
		xmlFile:setValue(string.format("%s.polygon.point(%d)", key, pointIndex - 1), self.pointsX[pointIndex], self.pointsZ[pointIndex])
	end
end
function DensityMapPolygon:loadFromXMLFile(xmlFile, key)
	for _, pointKey in xmlFile:iterator(key .. ".polygon.point") do
		local worldPosX, worldPosZ = xmlFile:getValue(pointKey)
		self:addPolygonPoint(worldPosX, worldPosZ)
	end
	return 0 < #self.pointsX
end
function DensityMapPolygon:addPolygonPoint(worldX, worldZ)
	table.insert(self.pointsX, worldX)
	table.insert(self.pointsZ, worldZ)
end
function DensityMapPolygon:setPolygonPoint(index, worldX, worldZ)
	self.pointsX[index] = worldX
	self.pointsZ[index] = worldZ
end
function DensityMapPolygon:updateOrigin(originX, originZ, originDirX, originDirZ)
	self.originX = originX
	self.originZ = originZ
	self.originDirX = originDirX
	self.originDirZ = originDirZ
end
function DensityMapPolygon:updateScale(scaleX, scaleZ)
	self.scaleX = scaleX
	self.scaleZ = scaleZ
end
function DensityMapPolygon:updateFromPolygon2D(polygon)
	for _, x, z in polygon:iteratorVertices() do
		self:addPolygonPoint(x, z)
	end
end
function DensityMapPolygon:updateFromNodes(nodes)
	for _, node in ipairs(nodes) do
		local x, _, z = getWorldTranslation(node)
		self:addPolygonPoint(x, z)
	end
end
function DensityMapPolygon:applyToModifier(modifier)
	modifier:clearPolygonPoints()
	for pointIndex = 1, #self.pointsX do
		local x = self.pointsX[pointIndex] * self.scaleX
		local z = self.pointsZ[pointIndex] * self.scaleZ
		local worldX = self.originX + z * self.originDirX + x * self.originDirZ
		local worldZ = self.originZ + z * self.originDirZ - x * self.originDirX
		modifier:addPolygonPointWorldCoords(worldX, worldZ)
	end
end
function DensityMapPolygon:getVerticesList()
	local listVerticesXZ = table.create(#self.pointsX * 2)
	for pointIndex = 1, #self.pointsX do
		local x = self.pointsX[pointIndex] * self.scaleX
		local z = self.pointsZ[pointIndex] * self.scaleZ
		local worldX = self.originX + z * self.originDirX + x * self.originDirZ
		local worldZ = self.originZ + z * self.originDirZ - x * self.originDirX
		table.insert(listVerticesXZ, worldX)
		table.insert(listVerticesXZ, worldZ)
	end
	return listVerticesXZ
end
function DensityMapPolygon:getVerticesAs3DCoordinates(worldY, worldYFunc)
	local polygon3DVertices = table.create(#self.pointsX * 3)
	for pointIndex = 1, #self.pointsX do
		local x = self.pointsX[pointIndex] * self.scaleX
		local z = self.pointsZ[pointIndex] * self.scaleZ
		local worldX = self.originX + z * self.originDirX + x * self.originDirZ
		local worldZ = self.originZ + z * self.originDirZ - x * self.originDirX
		if worldYFunc then
			local y = worldYFunc(worldX, worldZ) or worldY or 0
		end
		local y = 0
		table.insert(polygon3DVertices, worldX)
		table.insert(polygon3DVertices, y)
		table.insert(polygon3DVertices, worldZ)
	end
	return polygon3DVertices
end
function DensityMapPolygon:getCenter()
	local worldX = 0
	local worldZ = 0
	local numPoints = #self.pointsX
	if 0 < numPoints then
		for pointIndex = 1, numPoints do
			local x = self.pointsX[pointIndex] * self.scaleX
			local z = self.pointsZ[pointIndex] * self.scaleZ
			worldX = worldX + self.originX + z * self.originDirX + x * self.originDirZ
			worldZ = worldZ + self.originZ + z * self.originDirZ - x * self.originDirX
		end
		worldX = worldX / numPoints
		worldZ = worldZ / numPoints
	end
	return worldX, worldZ
end
function DensityMapPolygon:visualize(lifetime, groupId, maxCount)
	local debugPolygon = DebugPolygon.new()
	for pointIndex = 1, #self.pointsX do
		local x = self.pointsX[pointIndex] * self.scaleX
		local z = self.pointsZ[pointIndex] * self.scaleZ
		local worldX = self.originX + z * self.originDirX + x * self.originDirZ
		local worldZ = self.originZ + z * self.originDirZ - x * self.originDirX
		debugPolygon:addPosition(worldX, getTerrainHeightAtWorldPos(g_terrainNode, worldX, 0, worldZ), worldZ)
	end
	local color = DebugUtil.getDebugColor():copy()
	color.a = 0.3
	debugPolygon:setColor(color)
	debugPolygon:setIsSolid(false)
	debugPolygon:setDrawContour(true)
	debugPolygon:addToManager(groupId, lifetime or 15000, maxCount)
end
function DensityMapPolygon.createFromNodes(nodes)
	if nodes == nil or #nodes < 3 then
		Logging.warning("Too few polygon nodes given. A polygon needs at least 3 nodes.")
		return nil
	end
	local polygon = DensityMapPolygon.new()
	polygon:updateFromNodes(nodes)
	return polygon
end
function DensityMapPolygon.createFromXMLFile(xmlFile, key)
	if not xmlFile:hasProperty(key .. ".polygon.point") then
		return nil
	end
	local polygon = DensityMapPolygon.new()
	for _, pointKey in xmlFile:iterator(key .. ".polygon.point") do
		local worldX, worldZ = xmlFile:getValue(pointKey)
		if worldX == nil or worldZ == nil then
			Logging.xmlWarning(xmlFile, "Invalid point world positions for DensityMapPolygon in '%s'", pointKey)
			return
		end
		polygon:addPolygonPoint(worldX, worldZ)
	end
	if #polygon.pointsX < 3 then
		Logging.xmlWarning(xmlFile, "Too few polygon points defined. A polygon needs at least 3 points. '%s'", key)
		return nil
	else
		return polygon
	end
end
function DensityMapPolygon.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.VECTOR_2, basePath .. ".polygon.point(?)", "Polygon point world position (x,z)", nil, false)
end
