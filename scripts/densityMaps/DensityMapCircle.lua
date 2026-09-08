-- Local values: DensityMapCircle_mt
DensityMapCircle = {}
local DensityMapCircle_mt = Class(DensityMapCircle)

-- Upvalues: DensityMapCircle_mt
-- Local values: self
function DensityMapCircle.new(customMt)
	-- upvalues: (copy) DensityMapCircle_mt
	local v3_ = customMt or DensityMapCircle_mt
	local v4_ = setmetatable({}, v3_)
	v4_.worldPosX = 0
	v4_.worldPosZ = 0
	v4_.radius = 0
	v4_.numSegments = 1
	v4_.points = {}
	return v4_
end

function DensityMapCircle:saveToXMLFile(xmlFile, key)
	xmlFile:setValue(key .. ".circle#worldPositionXZ", self.worldPosX, self.worldPosZ)
	xmlFile:setValue(key .. ".circle#radius", self.radius)
	xmlFile:setValue(key .. ".circle#numSegments", self.numSegments)
end

-- Local values: worldPosX, worldPosZ, radius, numSegments
function DensityMapCircle:loadFromXMLFile(xmlFile, key)
	local v11_, v12_ = xmlFile:getValue(key .. ".circle#worldPositionXZ")
	local v13_ = xmlFile:getValue(key .. ".circle#radius")
	local v14_ = xmlFile:getValue(key .. ".circle#numSegments")
	if v11_ == nil or (v12_ == nil or (v13_ == nil or v14_ == nil)) then
		return false
	end
	self.worldPosX = v11_
	self.worldPosZ = v12_
	self.radius = v13_
	self.numSegments = v14_
	return true
end

-- Local values: i, a1, c, s, x, z
function DensityMapCircle:updateFromWorldPosition(worldPosX, worldPosZ, radius, numSegments)
	if numSegments < #self.points then
		table.clear(self.points)
	end
	self.worldPosX = worldPosX
	self.worldPosZ = worldPosZ
	self.radius = radius
	self.numSegments = numSegments
	for v20_ = 1, numSegments do
		local v21_ = (v20_ - 1) / numSegments * 2 * 3.141592653589793
		local v22_ = math.cos(v21_) * radius
		local v23_ = math.sin(v21_) * radius
		local v24_ = worldPosX + v22_
		local v25_ = worldPosZ + v23_
		if self.points[v20_] == nil then
			self.points[v20_] = { v24_, v25_ }
		else
			local v26_ = self.points[v20_]
			local v27_ = self.points[v20_]
			v26_[1] = v24_
			v27_[2] = v25_
		end
	end
end

-- Local values: polygon3DVertices, _, point, x, z, y
function DensityMapCircle:getVerticesAs3DCoordinates(worldY, worldYFunc)
	local v31_ = table.create(#self.points * 3)
	for _, v32_ in ipairs(self.points) do
		local v33_ = v32_[1]
		local v34_ = v32_[2]
		local v35_ = worldYFunc and worldYFunc(v33_, v34_) or (worldY or 0)
		table.insert(v31_, v33_)
		table.insert(v31_, v35_)
		table.insert(v31_, v34_)
	end
	return v31_
end

function DensityMapCircle:getCenter()
	return self.worldPosX, self.worldPosZ
end

-- Local values: _, point
function DensityMapCircle:applyToModifier(modifier)
	modifier:clearPolygonPoints()
	for _, v39_ in ipairs(self.points) do
		modifier:addPolygonPointWorldCoords(v39_[1], v39_[2])
	end
end

-- Local values: debugPolygon, _, point, x, z, color
function DensityMapCircle:visualize(lifetime, groupId, maxCount)
	local v44_ = DebugPolygon.new()
	for _, v45_ in ipairs(self.points) do
		local v46_ = v45_[1]
		local v47_ = v45_[2]
		v44_:addPosition(v46_, getTerrainHeightAtWorldPos(g_terrainNode, v46_, 0, v47_), v47_)
	end
	local v48_ = DebugUtil.getDebugColor():copy()
	v48_.a = 0.3
	v44_:setColor(v48_)
	v44_:setIsSolid(false)
	v44_:setDrawContour(true)
	v44_:addToManager(groupId, lifetime or 15000, maxCount)
end

-- Local values: polygon
function DensityMapCircle.createCircle(worldPosX, worldPosZ, radius, numSegments)
	local v53_ = DensityMapCircle.new()
	v53_:updateFromWorldPosition(worldPosX, worldPosZ, radius, numSegments)
	return v53_
end

-- Local values: worldPosX, worldPosZ, radius, numSegments
function DensityMapCircle.createFromXMLFile(xmlFile, key)
	local v56_, v57_ = xmlFile:getValue(key .. ".circle#worldPositionXZ")
	if v56_ == nil and v57_ == nil then
		return nil
	end
	if v56_ == nil or v57_ == nil then
		Logging.xmlWarning(xmlFile, "Invalid worldStartXZ for DensityMapCircle in \'%s\'", key)
		return nil
	end
	local v58_ = xmlFile:getValue(key .. ".circle#radius", 5)
	local v59_ = xmlFile:getValue(key .. ".circle#numSegments", 5)
	return DensityMapCircle.createCircle(v56_, v57_, v58_, v59_)
end

function DensityMapCircle.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.VECTOR_2, basePath .. ".circle#worldPositionXZ", "Circle center world position (x,z)", nil, false)
	schema:register(XMLValueType.FLOAT, basePath .. ".circle#radius", "Circle radius", 5, false)
	schema:register(XMLValueType.INT, basePath .. ".circle#numSegments", "Number of circle segments", 5, false)
end
