-- Local values: Polygon2D_mt
Polygon2D = {}
local Polygon2D_mt = Class(Polygon2D)

-- Upvalues: Polygon2D_mt
-- Local values: self
function Polygon2D.new(numVertices, vertexCoordinates, customMt)
	-- upvalues: (copy) Polygon2D_mt
	local v5_ = customMt or Polygon2D_mt
	local v6_ = setmetatable({}, v5_)
	if vertexCoordinates == nil then
		if numVertices == nil or numVertices <= 4 then
			v6_.vertices = {}
			return v6_
		else
			v6_.vertices = table.create(numVertices * 2)
			return v6_
		end
	else
		v6_:setVertices(vertexCoordinates)
		return v6_
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

-- Local values: x, _y, z
function Polygon2D:addNode(node)
	local v12_, _, v13_ = getWorldTranslation(node)
	self.vertices[#self.vertices + 1] = v12_
	self.vertices[#self.vertices + 1] = v13_
	self.bbMinX = nil
	self.bbMaxX = nil
	self.bbMinZ = nil
	self.bbMaxZ = nil
	self.area = nil
	self.curveOrientation = nil
end

-- Local values: _, node, x, _y, z
function Polygon2D:addNodes(nodes)
	for _, v16_ in ipairs(nodes) do
		local v17_, _, v18_ = getWorldTranslation(v16_)
		self.vertices[#self.vertices + 1] = v17_
		self.vertices[#self.vertices + 1] = v18_
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

-- Local values: currentIndex, endIndex, iterator
function Polygon2D:iteratorVertices(startOffset, endIndexOffset)
	local v_u_23_ = 1 + (startOffset or 0) * 2
	local v_u_24_ = #self.vertices - 2 * (endIndexOffset or 0)
	return function()
		-- upvalues: (ref) v_u_23_, (copy) v_u_24_, (copy) self
		if v_u_24_ <= v_u_23_ then
			return nil
		end
		v_u_23_ = v_u_23_ + 2
		return (v_u_23_ - 1) / 2, self.vertices[v_u_23_ - 2], self.vertices[v_u_23_ - 1]
	end
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

-- Local values: numVerts2D, i
function Polygon2D:setVerticesFromXYZ(verticesXYZ)
	local v29_ = #verticesXYZ * 0.6666666666666666
	local v30_ = math.floor(v29_)
	self.vertices = table.create(v30_)
	for v31_ = 1, #verticesXYZ, 3 do
		local v32_ = self.vertices
		local v33_ = verticesXYZ[v31_]
		table.insert(v32_, v33_)
		local v34_ = self.vertices
		local v35_ = verticesXYZ[v31_ + 2]
		table.insert(v34_, v35_)
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
	local v39_ = index * 2 - 1
	table.remove(self.vertices, v39_)
	table.remove(self.vertices, v39_)
	self.bbMinX = nil
	self.bbMaxX = nil
	self.bbMinZ = nil
	self.bbMaxZ = nil
	self.area = nil
	self.curveOrientation = nil
end

function Polygon2D:getVertex(index)
	local v42_ = index * 2
	return self.vertices[v42_ - 1], self.vertices[v42_]
end

-- Local values: length
function Polygon2D:getLastVertex()
	if #self.vertices == 0 then
		return nil
	else
		return self.vertices[#self.vertices - 1], self.vertices[#self.vertices]
	end
end

-- Local values: polygon3DVertices, i
function Polygon2D:getVerticesAs3DCoordinates(worldY, worldYFunc)
	local v47_ = table.create(#self.vertices * 1.5)
	for v48_ = 1, #self.vertices, 2 do
		v47_[#v47_ + 1] = self.vertices[v48_]
		v47_[#v47_ + 1] = worldYFunc and worldYFunc(self.vertices[v48_], self.vertices[v48_ + 1], (v48_ + 1) / 2) or (worldY or 0)
		v47_[#v47_ + 1] = self.vertices[v48_ + 1]
	end
	return v47_
end

function Polygon2D:getNumEdges()
	return #self.vertices <= 2 and 0 or (#self.vertices == 4 and 1 or #self.vertices / 2)
end

function Polygon2D:getEdge(index)
	local v52_ = index * 2 - 1
	if v52_ + 3 <= #self.vertices then
		return self.vertices[v52_], self.vertices[v52_ + 1], self.vertices[v52_ + 2], self.vertices[v52_ + 3]
	else
		return self.vertices[v52_], self.vertices[v52_ + 1], self.vertices[1], self.vertices[2]
	end
end

-- Local values: currentIndex, endIndex, iterator
function Polygon2D:iteratorEdges(startOffset, endIndexOffset)
	if #self.vertices < 4 then
		return function()
			return nil
		end
	end
	local v_u_56_ = 1 + (startOffset or 0) * 2
	local v_u_57_ = #self.vertices - 2 * (endIndexOffset or 0)
	return function()
		-- upvalues: (ref) v_u_56_, (copy) v_u_57_, (copy) self
		if v_u_57_ <= v_u_56_ then
			return nil
		else
			v_u_56_ = v_u_56_ + 2
			if v_u_56_ + 1 <= #self.vertices then
				return (v_u_56_ - 1) / 2, self.vertices[v_u_56_ - 2], self.vertices[v_u_56_ - 1], self.vertices[v_u_56_], self.vertices[v_u_56_ + 1]
			elseif #self.vertices < 6 then
				return nil
			else
				return (v_u_56_ - 1) / 2, self.vertices[v_u_56_ - 2], self.vertices[v_u_56_ - 1], self.vertices[1], self.vertices[2]
			end
		end
	end
end

-- Local values: minX, maxX, minZ, maxZ, i
function Polygon2D:getBoundingBox()
	if self.bbMinX ~= nil then
		return self.bbMinX, self.bbMaxX, self.bbMinZ, self.bbMaxZ
	end
	if #self.vertices == 0 then
		return nil, nil, nil, nil
	end
	local v59_ = math.huge
	local v60_ = -math.huge
	local v61_ = math.huge
	local v62_ = -math.huge
	for v63_ = 1, #self.vertices, 2 do
		local v64_ = self.vertices[v63_]
		v59_ = math.min(v59_, v64_)
		local v65_ = self.vertices[v63_]
		v60_ = math.max(v60_, v65_)
		local v66_ = self.vertices[v63_ + 1]
		v61_ = math.min(v61_, v66_)
		local v67_ = self.vertices[v63_ + 1]
		v62_ = math.max(v62_, v67_)
	end
	self.bbMinX = v59_
	self.bbMaxX = v60_
	self.bbMinZ = v61_
	self.bbMaxZ = v62_
	return v59_, v60_, v61_, v62_
end

-- Local values: doubleArea, vertices, numVertices, i, x1, z1, x2, z2
function Polygon2D:getArea()
	if self.area ~= nil then
		return self.area
	end
	local v69_ = self.vertices
	local v70_ = #v69_
	local v71_ = 0
	for v72_ = 1, #v69_, 2 do
		local v73_ = v69_[v72_]
		local v74_ = v69_[v72_ + 1]
		local v75_ = v69_[1 + (v72_ + 1) % v70_]
		v71_ = v71_ + v73_ * v69_[1 + (v72_ + 2) % v70_] - v74_ * v75_
	end
	local v76_ = v71_ / 2
	self.area = math.abs(v76_)
	return self.area
end

-- Local values: vertices, hullVertices, minX, minZ, _, vx, vz, getOrientation, index, vertex, x1, z1, x2, z2, x3, z3, value
function Polygon2D:getConvexHull()
	local v78_ = {}
	local v_u_79_ = math.huge
	local v_u_80_ = math.huge
	local v81_ = {}
	for _, v82_, v83_ in self:iteratorVertices() do
		v78_[#v78_ + 1] = { v82_, v83_ }
		if v83_ < v_u_79_ or v83_ == v_u_79_ and v82_ < v_u_80_ then
			local v84_ = #v78_
			local v85_ = v78_[#v78_]
			local v86_ = v78_[1]
			v78_[1] = v85_
			v78_[v84_] = v86_
			v_u_80_ = v82_
			v_u_79_ = v83_
		end
	end
	table.sort(v78_, function(p87_, p88_)
		-- upvalues: (ref) v_u_80_, (ref) v_u_79_
		local v89_ = v_u_80_
		local v90_ = v_u_79_
		local v91_ = p87_[1]
		local v92_ = p87_[2]
		local v93_ = p88_[1]
		local v94_ = p88_[2]
		local v95_ = (v92_ - v90_) * (v93_ - v91_) - (v91_ - v89_) * (v94_ - v92_)
		local v96_ = v95_ > 0 and 1 or (v95_ < 0 and -1 or 0)
		if v96_ == 0 then
			return MathUtil.vector2LengthSq(v_u_80_ - p88_[1], v_u_79_ - p88_[2]) < MathUtil.vector2LengthSq(v_u_80_ - p87_[1], v_u_79_ - p87_[2])
		else
			return v96_ ~= -1
		end
	end)
	for _, v97_ in ipairs(v78_) do
		if #v81_ > 3 then
			local v98_ = v81_[#v81_ - 3]
			local v99_ = v81_[#v81_ - 2]
			local v100_ = v81_[#v81_ - 1]
			local v101_ = v81_[#v81_]
			local v102_ = v97_[1]
			local v103_ = v97_[2]
			local v104_ = (v101_ - v99_) * (v102_ - v100_) - (v100_ - v98_) * (v103_ - v101_)
			if (v104_ > 0 and 1 or (v104_ < 0 and -1 or 0)) > 0 then
				break
			end
			table.remove(v81_)
			table.remove(v81_)
			continue
		end
		v81_[#v81_ + 1] = v97_[1]
		v81_[#v81_ + 1] = v97_[2]
	end
	return v81_
end

-- Local values: doubleArea, vertices, numVertices, i, x1, z1, x2, z2
function Polygon2D:getCurveOrientation()
	if self.curveOrientation ~= nil then
		return self.curveOrientation
	end
	local v106_ = self.vertices
	local v107_ = #v106_
	local v108_ = 0
	for v109_ = 1, #v106_, 2 do
		local v110_ = v106_[v109_]
		local v111_ = v106_[v109_ + 1]
		local v112_ = v106_[1 + (v109_ + 1) % v107_]
		v108_ = v108_ + v110_ * v106_[1 + (v109_ + 2) % v107_] - v111_ * v112_
	end
	self.curveOrientation = math.sign(v108_)
	return self.curveOrientation
end

-- Local values: minX, maxX, minZ, maxZ, intersectCount, i, edgeStartX, edgeStartZ, edgeEndX, edgeEndZ, hasIntersection, _ix, _iz
function Polygon2D:getIsPosInside(x, z)
	if #self.vertices < 6 then
		return false
	end
	local v116_, v117_, v118_, v119_ = self:getBoundingBox()
	if x < v116_ or (v117_ < x or (z < v118_ or v119_ < z)) then
		return false
	end
	local v120_ = 0
	for v121_ = 1, #self.vertices, 2 do
		local v122_ = self.vertices[v121_]
		local v123_ = self.vertices[v121_ + 1]
		local v124_ = self.vertices[v121_ + 2] or self.vertices[1]
		local v125_ = self.vertices[v121_ + 3] or self.vertices[2]
		local v126_, _, _ = MathUtil.getLineSegmentsIntersection(x, z, 100000, z, v122_, v123_, v124_, v125_)
		if v126_ then
			v120_ = v120_ + 1
		end
	end
	return v120_ % 2 ~= 0, v120_
end

-- Local values: _, x1, z1, x2, z2
function Polygon2D:getIsLineSegmentIntersecting(lx1, lz1, lx2, lz2)
	for _, v132_, v133_, v134_, v135_ in self:iteratorEdges() do
		if MathUtil.getAreLineSegmentsIntersecting(v132_, v133_, v134_, v135_, lx1, lz1, lx2, lz2) then
			return true
		end
	end
	return self:getIsPosInside(lx1, lz1) and true or (self:getIsPosInside(lx2, lz2) and true or false)
end

-- Local values: _, x1, z1, x2, z2, distance
function Polygon2D:getIsCircleIntersecting(x, z, radius)
	if self:getIsPosInside(x, z) then
		return true
	end
	for _, v140_, v141_, v142_, v143_ in self:iteratorEdges() do
		if MathUtil.getDistanceToLineSegment2D(v140_, v141_, v142_, v143_, x, z) <= radius then
			return true
		end
	end
	return false
end

-- Local values: _, x1, z1, x2, z2, distance
function Polygon2D:getIsCircleInside(x, z, radius)
	if not self:getIsPosInside(x, z) then
		return false
	end
	for _, v148_, v149_, v150_, v151_ in self:iteratorEdges() do
		if MathUtil.getDistanceToLineSegment2D(v148_, v149_, v150_, v151_, x, z) < radius then
			return false
		end
	end
	return true
end

-- Local values: r, g, b, a, v1y, v2y, edgeIndex, v1x, v1z, v2x, v2z, len
function Polygon2D:renderEdges(worldY, color, alignToTerrain, showEdgeLength, solid)
	local v158_, v159_, v160_, v161_ = (color or Color.PRESETS.WHITE):unpack()
	local v162_ = worldY
	for v163_, v164_, v165_, v166_, v167_ in self:iteratorEdges() do
		if alignToTerrain and g_terrainNode ~= nil then
			worldY = getTerrainHeightAtWorldPos(g_terrainNode, v164_, 0, v165_)
			v162_ = getTerrainHeightAtWorldPos(g_terrainNode, v166_, 0, v167_)
		end
		drawDebugLine(v164_, worldY, v165_, v158_, v159_, v160_, v166_, v162_, v167_, v158_, v159_, v160_, solid)
		if showEdgeLength then
			local v168_ = MathUtil.vector2Length(v164_ - v166_, v165_ - v167_)
			Utils.renderTextAtWorldPosition((v164_ + v166_) / 2, (worldY + v162_) / 2, (v165_ + v167_) / 2, string.format("#%d %.2f", v163_, v168_), nil, nil, v158_, v159_, v160_, v161_)
		end
	end
end

-- Local values: offsetPolygon, orientation, edgeIndex, x1, z1, x2, z2, oldEdge, e1nX, e1nZ, x0, z0, e2nX, e2nZ, nX, nZ, offsetLen
function Polygon2D:getOffsetPolygon(offset)
	if self:getNumEdges() < 3 then
		return nil
	end
	local v171_ = Polygon2D.new()
	local v172_ = self:getCurveOrientation()
	for v173_, v174_, v175_, v176_, v177_ in self:iteratorEdges() do
		local v178_ = v173_ - 1
		if v178_ < 1 then
			v178_ = #self.vertices / 2
		end
		local v179_ = v176_ - v174_
		local v180_ = v177_ - v175_
		if MathUtil.vector2Length(v179_, v180_) < offset then
			return nil
		end
		local v181_, v182_ = MathUtil.vector2Normalize(v179_, v180_)
		local v183_, v184_ = self:getEdge(v178_)
		local v185_ = v174_ - v183_
		local v186_ = v175_ - v184_
		if MathUtil.vector2Length(v185_, v186_) < offset then
			return nil
		end
		local v187_, v188_ = MathUtil.vector2Normalize(v185_, v186_)
		local v189_ = v182_ + v188_
		local v190_ = -v181_ - v187_
		if v189_ == 0 and v190_ == 0 then
			return nil
		end
		local v191_ = offset * v172_
		local v192_ = (1 + v182_ * v188_ + -v181_ * -v187_) / 2
		local v193_ = v191_ / math.sqrt(v192_)
		local v194_, v195_ = MathUtil.vector2SetLength(v189_, v190_, v193_)
		v171_:addPos(v174_ + v194_, v175_ + v195_)
	end
	return v171_
end

-- Local values: r, g, b, a, yHeightFunc
function Polygon2D:renderFace(worldY, color, alignToTerrain)
	if #self.vertices >= 6 then
		local v200_, v201_, v202_, v203_ = (color or Color.PRESETS.WHITE):unpack()
		local v206_ = alignToTerrain and g_terrainNode ~= nil and function(p204_, p205_)
			return getTerrainHeightAtWorldPos(g_terrainNode, p204_, 0, p205_)
		end or nil
		drawDebugPolygon(self:getVerticesAs3DCoordinates(worldY, v206_), v200_, v201_, v202_, v203_, false)
	end
end
