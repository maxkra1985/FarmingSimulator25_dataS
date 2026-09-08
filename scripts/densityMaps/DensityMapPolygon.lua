-- Local values: DensityMapPolygon_mt
DensityMapPolygon = {}
local DensityMapPolygon_mt = Class(DensityMapPolygon)

-- Upvalues: DensityMapPolygon_mt
-- Local values: self
function DensityMapPolygon.new(customMt)
	-- upvalues: (copy) DensityMapPolygon_mt
	local v3_ = customMt or DensityMapPolygon_mt
	local v4_ = setmetatable({}, v3_)
	v4_.originX = 0
	v4_.originZ = 0
	v4_.originDirX = 0
	v4_.originDirZ = 1
	v4_.scaleX = 1
	v4_.scaleZ = 1
	v4_.pointsX = {}
	v4_.pointsZ = {}
	return v4_
end

-- Local values: pointIndex
function DensityMapPolygon:saveToXMLFile(xmlFile, key)
	for v8_ = 1, #self.pointsX do
		xmlFile:setValue(string.format("%s.polygon.point(%d)", key, v8_ - 1), self.pointsX[v8_], self.pointsZ[v8_])
	end
end

-- Local values: _, pointKey, worldPosX, worldPosZ
function DensityMapPolygon:loadFromXMLFile(xmlFile, key)
	for _, v12_ in xmlFile:iterator(key .. ".polygon.point") do
		local v13_, v14_ = xmlFile:getValue(v12_)
		self:addPolygonPoint(v13_, v14_)
	end
	return #self.pointsX > 0
end

function DensityMapPolygon:addPolygonPoint(worldX, worldZ)
	local v18_ = self.pointsX
	table.insert(v18_, worldX)
	local v19_ = self.pointsZ
	table.insert(v19_, worldZ)
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

-- Local values: _, x, z
function DensityMapPolygon:updateFromPolygon2D(polygon)
	for _, v34_, v35_ in polygon:iteratorVertices() do
		self:addPolygonPoint(v34_, v35_)
	end
end

-- Local values: _, node, x, _, z
function DensityMapPolygon:updateFromNodes(nodes)
	for _, v38_ in ipairs(nodes) do
		local v39_, _, v40_ = getWorldTranslation(v38_)
		self:addPolygonPoint(v39_, v40_)
	end
end

-- Local values: pointIndex, x, z, worldX, worldZ
function DensityMapPolygon:applyToModifier(modifier)
	modifier:clearPolygonPoints()
	for v43_ = 1, #self.pointsX do
		local v44_ = self.pointsX[v43_] * self.scaleX
		local v45_ = self.pointsZ[v43_] * self.scaleZ
		modifier:addPolygonPointWorldCoords(self.originX + v45_ * self.originDirX + v44_ * self.originDirZ, self.originZ + v45_ * self.originDirZ - v44_ * self.originDirX)
	end
end

-- Local values: listVerticesXZ, pointIndex, x, z, worldX, worldZ
function DensityMapPolygon:getVerticesList()
	local v47_ = table.create(#self.pointsX * 2)
	for v48_ = 1, #self.pointsX do
		local v49_ = self.pointsX[v48_] * self.scaleX
		local v50_ = self.pointsZ[v48_] * self.scaleZ
		local v51_ = self.originX + v50_ * self.originDirX + v49_ * self.originDirZ
		local v52_ = self.originZ + v50_ * self.originDirZ - v49_ * self.originDirX
		table.insert(v47_, v51_)
		table.insert(v47_, v52_)
	end
	return v47_
end

-- Local values: polygon3DVertices, pointIndex, x, z, worldX, worldZ, y
function DensityMapPolygon:getVerticesAs3DCoordinates(worldY, worldYFunc)
	local v56_ = table.create(#self.pointsX * 3)
	for v57_ = 1, #self.pointsX do
		local v58_ = self.pointsX[v57_] * self.scaleX
		local v59_ = self.pointsZ[v57_] * self.scaleZ
		local v60_ = self.originX + v59_ * self.originDirX + v58_ * self.originDirZ
		local v61_ = self.originZ + v59_ * self.originDirZ - v58_ * self.originDirX
		local v62_ = worldYFunc and worldYFunc(v60_, v61_) or (worldY or 0)
		table.insert(v56_, v60_)
		table.insert(v56_, v62_)
		table.insert(v56_, v61_)
	end
	return v56_
end

-- Local values: worldX, worldZ, numPoints, pointIndex, x, z
function DensityMapPolygon:getCenter()
	local v64_ = 0
	local v65_ = 0
	local v66_ = #self.pointsX
	if v66_ > 0 then
		for v67_ = 1, v66_ do
			local v68_ = self.pointsX[v67_] * self.scaleX
			local v69_ = self.pointsZ[v67_] * self.scaleZ
			v64_ = v64_ + self.originX + v69_ * self.originDirX + v68_ * self.originDirZ
			v65_ = v65_ + self.originZ + v69_ * self.originDirZ - v68_ * self.originDirX
		end
		v64_ = v64_ / v66_
		v65_ = v65_ / v66_
	end
	return v64_, v65_
end

-- Local values: debugPolygon, pointIndex, x, z, worldX, worldZ, color
function DensityMapPolygon:visualize(lifetime, groupId, maxCount)
	local v74_ = DebugPolygon.new()
	for v75_ = 1, #self.pointsX do
		local v76_ = self.pointsX[v75_] * self.scaleX
		local v77_ = self.pointsZ[v75_] * self.scaleZ
		local v78_ = self.originX + v77_ * self.originDirX + v76_ * self.originDirZ
		local v79_ = self.originZ + v77_ * self.originDirZ - v76_ * self.originDirX
		v74_:addPosition(v78_, getTerrainHeightAtWorldPos(g_terrainNode, v78_, 0, v79_), v79_)
	end
	local v80_ = DebugUtil.getDebugColor():copy()
	v80_.a = 0.3
	v74_:setColor(v80_)
	v74_:setIsSolid(false)
	v74_:setDrawContour(true)
	v74_:addToManager(groupId, lifetime or 15000, maxCount)
end

-- Local values: polygon
function DensityMapPolygon.createFromNodes(nodes)
	if nodes == nil or #nodes < 3 then
		Logging.warning("Too few polygon nodes given. A polygon needs at least 3 nodes.")
		return nil
	end
	local v82_ = DensityMapPolygon.new()
	v82_:updateFromNodes(nodes)
	return v82_
end

-- Local values: polygon, _, pointKey, worldX, worldZ
function DensityMapPolygon.createFromXMLFile(xmlFile, key)
	if not xmlFile:hasProperty(key .. ".polygon.point") then
		return nil
	end
	local v85_ = DensityMapPolygon.new()
	for _, v86_ in xmlFile:iterator(key .. ".polygon.point") do
		local v87_, v88_ = xmlFile:getValue(v86_)
		if v87_ == nil or v88_ == nil then
			Logging.xmlWarning(xmlFile, "Invalid point world positions for DensityMapPolygon in \'%s\'", v86_)
			return
		end
		v85_:addPolygonPoint(v87_, v88_)
	end
	if #v85_.pointsX >= 3 then
		return v85_
	end
	Logging.xmlWarning(xmlFile, "Too few polygon points defined. A polygon needs at least 3 points. \'%s\'", key)
	return nil
end

function DensityMapPolygon.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.VECTOR_2, basePath .. ".polygon.point(?)", "Polygon point world position (x,z)", nil, false)
end
