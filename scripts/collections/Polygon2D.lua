Polygon2D = {}
local Polygon2D_mt = Class(Polygon2D)
function Polygon2D.new(numVertices, vertexCoordinates, customMt)
	local self = setmetatable({}, customMt or Polygon2D_mt)
	if vertexCoordinates ~= nil then
		self:setVertices(vertexCoordinates)
		return self
	elseif numVertices ~= nil and 4 < numVertices then
		self.vertices = table.create(numVertices * 2)
		return self
	else
		self.vertices = {}
		return self
	end
end
function Polygon2D:addPos(x, z)
	self.vertices[#self.vertices + 1] = x
	self.vertices[#self.vertices + 1] = z
	self.bbMinX = nil
	self.bbMaxX = nil
	self.bbMinZ = nil
	self.bbMaxZ = nil
	self.area = nil
	self.curveOrientation = nil
end
function Polygon2D:addNode(node)
	local x, _y, z = getWorldTranslation(node)
	self.vertices[#self.vertices + 1] = x
	self.vertices[#self.vertices + 1] = z
	self.bbMinX = nil
	self.bbMaxX = nil
	self.bbMinZ = nil
	self.bbMaxZ = nil
	self.area = nil
	self.curveOrientation = nil
end
function Polygon2D:addNodes(nodes)
	for _, node in ipairs(nodes) do
		local x, _y, z = getWorldTranslation(node)
		self.vertices[#self.vertices + 1] = x
		self.vertices[#self.vertices + 1] = z
	end
	self.bbMinX = nil
	self.bbMaxX = nil
	self.bbMinZ = nil
	self.bbMaxZ = nil
	self.area = nil
	self.curveOrientation = nil
end
function Polygon2D:getVertices()
	return self.vertices
end
function Polygon2D:iteratorVertices(startOffset, endIndexOffset)
	local currentIndex = 1 + (startOffset or 0) * 2
	local endIndex = #self.vertices - 2 * (endIndexOffset or 0)
	local iterator = function()
		if endIndex <= currentIndex then
			return nil
		else
			currentIndex = currentIndex + 2
			return (currentIndex - 1) / 2, self.vertices[currentIndex - 2], self.vertices[currentIndex - 1]
		end
	end
	return iterator
end
function Polygon2D:setVertices(vertices)
	self.vertices = vertices
	self.bbMinX = nil
	self.bbMaxX = nil
	self.bbMinZ = nil
	self.bbMaxZ = nil
	self.area = nil
	self.curveOrientation = nil
end
function Polygon2D:setVerticesFromXYZ(verticesXYZ)
	local numVerts2D = math.floor(#verticesXYZ * 0.6666666666666666)
	self.vertices = table.create(numVerts2D)
	for i = 1, #verticesXYZ, 3 do
		table.insert(self.vertices, verticesXYZ[i])
		table.insert(self.vertices, verticesXYZ[i + 2])
	end
	self.bbMinX = nil
	self.bbMaxX = nil
	self.bbMinZ = nil
	self.bbMaxZ = nil
	self.area = nil
	self.curveOrientation = nil
end
function Polygon2D:getNumVertices()
	return #self.vertices / 2
end
function Polygon2D:removeVertex(index)
	index = index * 2 - 1
	table.remove(self.vertices, index)
	table.remove(self.vertices, index)
	self.bbMinX = nil
	self.bbMaxX = nil
	self.bbMinZ = nil
	self.bbMaxZ = nil
	self.area = nil
	self.curveOrientation = nil
end
function Polygon2D:getVertex(index)
	index = index * 2
	return self.vertices[index - 1], self.vertices[index]
end
function Polygon2D:getLastVertex()
	local length = #self.vertices
	if length == 0 then
		return nil
	else
		return self.vertices[#self.vertices - 1], self.vertices[#self.vertices]
	end
end
function Polygon2D:getVerticesAs3DCoordinates(worldY, worldYFunc)
	local polygon3DVertices = table.create(#self.vertices * 1.5)
	for i = 1, #self.vertices, 2 do
		polygon3DVertices[#polygon3DVertices + 1] = self.vertices[i]
		if worldYFunc then
			local _v29 = worldYFunc(self.vertices[i], self.vertices[i + 1], (i + 1) / 2) or worldY or 0
		end
		polygon3DVertices[#polygon3DVertices + 1] = 0
		polygon3DVertices[#polygon3DVertices + 1] = self.vertices[i + 1]
	end
	return polygon3DVertices
end
function Polygon2D:getNumEdges()
	if #self.vertices <= 2 then
		return 0
	elseif #self.vertices == 4 then
		return 1
	else
		return #self.vertices / 2
	end
end
function Polygon2D:getEdge(index)
	index = index * 2 - 1
	if index + 3 <= #self.vertices then
		return self.vertices[index], self.vertices[index + 1], self.vertices[index + 2], self.vertices[index + 3]
	else
		return self.vertices[index], self.vertices[index + 1], self.vertices[1], self.vertices[2]
	end
end
function Polygon2D:iteratorEdges(startOffset, endIndexOffset)
	if #self.vertices < 4 then
		return function()
			return nil
		end
	else
		local currentIndex = 1 + (startOffset or 0) * 2
		local endIndex = #self.vertices - 2 * (endIndexOffset or 0)
		local iterator = function()
			if endIndex <= currentIndex then
				return nil
			end
			currentIndex = currentIndex + 2
			if currentIndex + 1 <= #self.vertices then
				return (currentIndex - 1) / 2, self.vertices[currentIndex - 2], self.vertices[currentIndex - 1], self.vertices[currentIndex], self.vertices[currentIndex + 1]
			elseif #self.vertices >= 6 then
				return (currentIndex - 1) / 2, self.vertices[currentIndex - 2], self.vertices[currentIndex - 1], self.vertices[1], self.vertices[2]
			else
				return nil
			end
		end
		return iterator
	end
end
function Polygon2D:getBoundingBox()
	if self.bbMinX ~= nil then
		return self.bbMinX, self.bbMaxX, self.bbMinZ, self.bbMaxZ
	elseif #self.vertices == 0 then
		return nil, nil, nil, nil
	else
		local minX = math.huge
		local maxX = -math.huge
		local minZ = math.huge
		local maxZ = -math.huge
		for i = 1, #self.vertices, 2 do
			minX = math.min(minX, self.vertices[i])
			maxX = math.max(maxX, self.vertices[i])
			minZ = math.min(minZ, self.vertices[i + 1])
			maxZ = math.max(maxZ, self.vertices[i + 1])
		end
		self.bbMinX = minX
		self.bbMaxX = maxX
		self.bbMinZ = minZ
		self.bbMaxZ = maxZ
		return minX, maxX, minZ, maxZ
	end
end
function Polygon2D:getArea()
	if self.area ~= nil then
		return self.area
	else
		local doubleArea = 0
		local vertices = self.vertices
		local numVertices = #vertices
		for i = 1, #vertices, 2 do
			local x1 = vertices[i]
			local z1 = vertices[i + 1]
			local x2 = vertices[1 + (i + 1) % numVertices]
			local z2 = vertices[1 + (i + 2) % numVertices]
			doubleArea = doubleArea + x1 * z2 - z1 * x2
		end
		self.area = math.abs(doubleArea / 2)
		return self.area
	end
end
function Polygon2D:getConvexHull()
	local vertices = {}
	local hullVertices = {}
	local minX = math.huge
	local minZ = math.huge
	for _, vx, vz in self:iteratorVertices() do
		vertices[#vertices + 1] = { vx, vz }
		if vz < minZ or vz == minZ and vx < minX then
			minX = vx
			minZ = vz
			vertices[1] = vertices[#vertices]
			vertices[#vertices] = vertices[1]
		end
	end
	local getOrientation = function(x1, z1, x2, z2, x3, z3)
		local value = (z2 - z1) * (x3 - x2) - (x2 - x1) * (z3 - z2)
		if 0 < value then
			return 1
		elseif value < 0 then
			return -1
		else
			return 0
		end
	end
	table.sort(vertices, function(a, b)
		local x1 = minX
		local z1 = minZ
		local x2 = a[1]
		local z2 = a[2]
		local x3 = b[1]
		local z3 = b[2]
		local value = (z2 - z1) * (x3 - x2) - (x2 - x1) * (z3 - z2)
		local o = 0 < value and 1 or (value < 0 and -1 or 0)
		if o == 0 then
			if MathUtil.vector2LengthSq(minX - a[1], minZ - a[2]) <= MathUtil.vector2LengthSq(minX - b[1], minZ - b[2]) then
				return false
			else
				return true
			end
		elseif o == -1 then
			return false
		else
			return true
		end
	end)
	for index, vertex in ipairs(vertices) do
		while true do
			local _v3 = #hullVertices
			if 3 >= _v3 then
				break
			end
			local x1 = hullVertices[#hullVertices - 3]
			local z1 = hullVertices[#hullVertices - 2]
			local x2 = hullVertices[#hullVertices - 1]
			local z2 = hullVertices[#hullVertices]
			local x3 = vertex[1]
			local z3 = vertex[2]
			local value = (z2 - z1) * (x3 - x2) - (x2 - x1) * (z3 - z2)
			if _v3 <= 0 then
				table.remove(hullVertices)
				table.remove(hullVertices)
			end
		end
		hullVertices[#hullVertices + 1] = vertex[1]
		hullVertices[#hullVertices + 1] = vertex[2]
	end
	return hullVertices
end
function Polygon2D:getCurveOrientation()
	if self.curveOrientation ~= nil then
		return self.curveOrientation
	else
		local doubleArea = 0
		local vertices = self.vertices
		local numVertices = #vertices
		for i = 1, #vertices, 2 do
			local x1 = vertices[i]
			local z1 = vertices[i + 1]
			local x2 = vertices[1 + (i + 1) % numVertices]
			local z2 = vertices[1 + (i + 2) % numVertices]
			doubleArea = doubleArea + x1 * z2 - z1 * x2
		end
		self.curveOrientation = math.sign(doubleArea)
		return self.curveOrientation
	end
end
function Polygon2D:getIsPosInside(x, z)
	if #self.vertices < 6 then
		return false
	else
		local minX, maxX, minZ, maxZ = self:getBoundingBox()
		if x < minX or maxX < x or z < minZ or maxZ < z then
			return false
		end
		local intersectCount = 0
		for i = 1, #self.vertices, 2 do
			local edgeStartX = self.vertices[i]
			local edgeStartZ = self.vertices[i + 1]
			local edgeEndX = self.vertices[i + 2] or self.vertices[1]
			local edgeEndZ = self.vertices[i + 3] or self.vertices[2]
			local hasIntersection, _ix, _iz = MathUtil.getLineSegmentsIntersection(x, z, 100000, z, edgeStartX, edgeStartZ, edgeEndX, edgeEndZ)
			if hasIntersection then
				intersectCount = intersectCount + 1
			end
		end
		return intersectCount % 2 ~= 0, intersectCount
	end
end
function Polygon2D:getIsLineSegmentIntersecting(lx1, lz1, lx2, lz2)
	for _, x1, z1, x2, z2 in self:iteratorEdges() do
		if MathUtil.getAreLineSegmentsIntersecting(x1, z1, x2, z2, lx1, lz1, lx2, lz2) then
			return true
		end
	end
	if self:getIsPosInside(lx1, lz1) then
		return true
	elseif self:getIsPosInside(lx2, lz2) then
		return true
	else
		return false
	end
end
function Polygon2D:getIsCircleIntersecting(x, z, radius)
	if self:getIsPosInside(x, z) then
		return true
	else
		for _, x1, z1, x2, z2 in self:iteratorEdges() do
			local distance = MathUtil.getDistanceToLineSegment2D(x1, z1, x2, z2, x, z)
			if distance <= radius then
				return true
			end
		end
		return false
	end
end
function Polygon2D:getIsCircleInside(x, z, radius)
	if not self:getIsPosInside(x, z) then
		return false
	else
		for _, x1, z1, x2, z2 in self:iteratorEdges() do
			local distance = MathUtil.getDistanceToLineSegment2D(x1, z1, x2, z2, x, z)
			if distance < radius then
				return false
			end
		end
		return true
	end
end
function Polygon2D:renderEdges(worldY, color, alignToTerrain, showEdgeLength, solid)
	local r, g, b, a = (color or Color.PRESETS.WHITE):unpack()
	local v1y = worldY
	local v2y = worldY
	for edgeIndex, v1x, v1z, v2x, v2z in self:iteratorEdges() do
		if alignToTerrain and g_terrainNode ~= nil then
			v1y = getTerrainHeightAtWorldPos(g_terrainNode, v1x, 0, v1z)
			v2y = getTerrainHeightAtWorldPos(g_terrainNode, v2x, 0, v2z)
		end
		drawDebugLine(v1x, v1y, v1z, r, g, b, v2x, v2y, v2z, r, g, b, solid)
		if showEdgeLength then
			local len = MathUtil.vector2Length(v1x - v2x, v1z - v2z)
			Utils.renderTextAtWorldPosition((v1x + v2x) / 2, (v1y + v2y) / 2, (v1z + v2z) / 2, string.format("#%d %.2f", edgeIndex, len), nil, nil, r, g, b, a)
		end
	end
end
function Polygon2D:getOffsetPolygon(offset)
	if self:getNumEdges() < 3 then
		return nil
	else
		local offsetPolygon = Polygon2D.new()
		local orientation = self:getCurveOrientation()
		for edgeIndex, x1, z1, x2, z2 in self:iteratorEdges() do
			local oldEdge = edgeIndex - 1
			if oldEdge < 1 then
				oldEdge = #self.vertices / 2
			end
			local e1nX = x2 - x1
			local e1nZ = z2 - z1
			if MathUtil.vector2Length(e1nX, e1nZ) < offset then
				return nil
			end
			e1nX, e1nZ = MathUtil.vector2Normalize(e1nX, e1nZ)
			local x0, z0 = self:getEdge(oldEdge)
			local e2nX = x1 - x0
			local e2nZ = z1 - z0
			if MathUtil.vector2Length(e2nX, e2nZ) < offset then
				return nil
			end
			e2nX, e2nZ = MathUtil.vector2Normalize(e2nX, e2nZ)
			local nX = e1nZ + e2nZ
			local nZ = -e1nX - e2nX
			if nX == 0 and nZ == 0 then
				return nil
			end
			local offsetLen = offset * orientation / math.sqrt((1 + e1nZ * e2nZ + -e1nX * -e2nX) / 2)
			nX, nZ = MathUtil.vector2SetLength(nX, nZ, offsetLen)
			offsetPolygon:addPos(x1 + nX, z1 + nZ)
		end
		return offsetPolygon
	end
end
function Polygon2D:renderFace(worldY, color, alignToTerrain)
	if #self.vertices < 6 then
		return
	else
		local r, g, b, a = (color or Color.PRESETS.WHITE):unpack()
		local yHeightFunc = nil
		if alignToTerrain and g_terrainNode ~= nil then
			function yHeightFunc(x, z)
				return getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
			end
		end
		drawDebugPolygon(self:getVerticesAs3DCoordinates(worldY, yHeightFunc), r, g, b, a, false)
	end
end
