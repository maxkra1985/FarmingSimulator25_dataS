-- Local values: DensityMapParallelogram_mt
DensityMapParallelogram = {}
local DensityMapParallelogram_mt = Class(DensityMapParallelogram)

-- Upvalues: DensityMapParallelogram_mt
-- Local values: self
function DensityMapParallelogram.new(customMt)
	-- upvalues: (copy) DensityMapParallelogram_mt
	local v3_ = customMt or DensityMapParallelogram_mt
	local v4_ = setmetatable({}, v3_)
	v4_.worldStartX = 0
	v4_.worldStartZ = 0
	v4_.worldWidthX = 0
	v4_.worldWidthZ = 0
	v4_.worldHeightX = 0
	v4_.worldHeightZ = 0
	return v4_
end

function DensityMapParallelogram:saveToXMLFile(xmlFile, key)
	xmlFile:setValue(key .. ".parallelogram#worldStartXZ", self.worldStartX, self.worldStartZ)
	xmlFile:setValue(key .. ".parallelogram#worldWidthXZ", self.worldWidthX, self.worldWidthZ)
	xmlFile:setValue(key .. ".parallelogram#worldWidthXZ", self.worldHeightX, self.worldHeightZ)
end

-- Local values: worldStartX, worldStartZ, worldWidthX, worldWidthZ, worldHeightX, worldHeightZ
function DensityMapParallelogram:loadFromXMLFile(xmlFile, key)
	local v11_, v12_ = xmlFile:getValue(key .. "#worldStartXZ")
	local v13_, v14_ = xmlFile:getValue(key .. "#worldWidthXZ")
	local v15_, v16_ = xmlFile:getValue(key .. "#worldHeightXZ")
	if v13_ == nil or (v14_ == nil or (v15_ == nil or v16_ == nil)) then
		return false
	end
	self.worldStartX = v11_
	self.worldStartZ = v12_
	self.worldWidthX = v13_
	self.worldWidthZ = v14_
	self.worldHeightX = v15_
	self.worldHeightZ = v16_
	return true
end

-- Local values: polygon3DVertices, add, cornerX, cornerZ, x, z, y, x, z, y, x, z, y, x, z, y
function DensityMapParallelogram:getVerticesAs3DCoordinates(worldY, worldYFunc)
	local v20_ = table.create(12)
	local v21_ = self.worldStartX + (self.worldWidthX - self.worldStartX) + (self.worldHeightX - self.worldStartX)
	local v22_ = self.worldStartZ + (self.worldWidthZ - self.worldStartZ) + (self.worldHeightZ - self.worldStartZ)
	local v23_ = self.worldStartX
	local v24_ = self.worldStartZ
	local v25_ = worldYFunc and worldYFunc(v23_, v24_) or (worldY or 0)
	table.insert(v20_, v23_)
	table.insert(v20_, v25_)
	table.insert(v20_, v24_)
	local v26_ = self.worldWidthX
	local v27_ = self.worldWidthZ
	local v28_ = worldYFunc and worldYFunc(v26_, v27_) or (worldY or 0)
	table.insert(v20_, v26_)
	table.insert(v20_, v28_)
	table.insert(v20_, v27_)
	local v29_ = worldYFunc and worldYFunc(v21_, v22_) or (worldY or 0)
	table.insert(v20_, v21_)
	table.insert(v20_, v29_)
	table.insert(v20_, v22_)
	local v30_ = self.worldHeightX
	local v31_ = self.worldHeightZ
	local v32_ = worldYFunc and worldYFunc(v30_, v31_) or (worldY or 0)
	table.insert(v20_, v30_)
	table.insert(v20_, v32_)
	table.insert(v20_, v31_)
	return v20_
end

-- Local values: cornerX, cornerZ, worldX, worldZ
function DensityMapParallelogram:getCenter()
	local v34_ = self.worldStartX + (self.worldWidthX - self.worldStartX) + (self.worldHeightX - self.worldStartX)
	local v35_ = self.worldStartZ + (self.worldWidthZ - self.worldStartZ) + (self.worldHeightZ - self.worldStartZ)
	return (self.worldStartX + self.worldWidthX + v34_ + self.worldHeightX) * 0.25, (self.worldStartZ + self.worldWidthZ + v35_ + self.worldHeightZ) * 0.25
end

-- Local values: debugPlane
function DensityMapParallelogram:visualize(lifetime, groupId, maxCount)
	local v40_ = DebugPlane.newSimple(true, true, nil, true)
	v40_:createWithPositions(self.worldStartX, 0, self.worldStartZ, self.worldWidthX, 0, self.worldWidthZ, self.worldHeightX, 0, self.worldHeightZ)
	v40_:addToManager(groupId, lifetime or 15000, maxCount)
end

-- Local values: cornerX, cornerZ
function DensityMapParallelogram:applyToModifier(modifier)
	modifier:clearPolygonPoints()
	local v43_ = self.worldStartX + (self.worldWidthX - self.worldStartX) + (self.worldHeightX - self.worldStartX)
	local v44_ = self.worldStartZ + (self.worldWidthZ - self.worldStartZ) + (self.worldHeightZ - self.worldStartZ)
	modifier:addPolygonPointWorldCoords(self.worldStartX, self.worldStartZ)
	modifier:addPolygonPointWorldCoords(self.worldWidthX, self.worldWidthZ)
	modifier:addPolygonPointWorldCoords(v43_, v44_)
	modifier:addPolygonPointWorldCoords(self.worldHeightX, self.worldHeightZ)
end

-- Local values: _
function DensityMapParallelogram:updateFromNodes(startNode, widthNode, heightNode)
	local v49_, _, v50_ = getWorldTranslation(startNode)
	self.worldStartX = v49_
	self.worldStartZ = v50_
	local v51_, _, v52_ = getWorldTranslation(widthNode)
	self.worldWidthX = v51_
	self.worldWidthZ = v52_
	local v53_, _, v54_ = getWorldTranslation(heightNode)
	self.worldHeightX = v53_
	self.worldHeightZ = v54_
end

function DensityMapParallelogram:updateFromPositionAndSize(worldX, worldZ, widthX, widthZ, heightX, heightZ)
	self.worldStartX = worldX
	self.worldStartZ = worldZ
	self.worldWidthX = worldX + widthX
	self.worldWidthZ = worldZ + widthZ
	self.worldHeightX = worldX + heightX
	self.worldHeightZ = worldZ + heightZ
end

function DensityMapParallelogram:updateFromWorldPositions(worldStartX, worldStartZ, worldWidthX, worldWidthZ, worldHeightX, worldHeightZ)
	self.worldStartX = worldStartX
	self.worldStartZ = worldStartZ
	self.worldWidthX = worldWidthX
	self.worldWidthZ = worldWidthZ
	self.worldHeightX = worldHeightX
	self.worldHeightZ = worldHeightZ
end

-- Local values: parallelogram
function DensityMapParallelogram.createFromNodes(startNode, widthNode, heightNode)
	local v72_ = DensityMapParallelogram.new()
	v72_:updateFromNodes(startNode, widthNode, heightNode)
	return v72_
end

-- Local values: parallelogram
function DensityMapParallelogram.createFromPositionAndSize(worldX, worldZ, widthX, widthZ, heightX, heightZ)
	local v79_ = DensityMapParallelogram.new()
	v79_:updateFromPositionAndSize(worldX, worldZ, widthX, widthZ, heightX, heightZ)
	return v79_
end

-- Local values: parallelogram
function DensityMapParallelogram.createFromWorldPositions(worldStartX, worldStartZ, worldWidthX, worldWidthZ, worldHeightX, worldHeightZ)
	local v86_ = DensityMapParallelogram.new()
	v86_:updateFromWorldPositions(worldStartX, worldStartZ, worldWidthX, worldWidthZ, worldHeightX, worldHeightZ)
	return v86_
end

-- Local values: worldStartX, worldStartZ, worldWidthX, worldWidthZ, worldHeightX, worldHeightZ, widthX, widthZ, heightX, heightZ
function DensityMapParallelogram.createFromXMLFile(xmlFile, key)
	local v89_, v90_ = xmlFile:getValue(key .. ".parallelogram#worldStartXZ")
	if v89_ == nil and v90_ == nil then
		return nil
	elseif v89_ == nil or v90_ == nil then
		Logging.xmlWarning(xmlFile, "Invalid worldStartXZ for DensityMapParallelogram in \'%s\'", key)
		return nil
	else
		local v91_, v92_ = xmlFile:getValue(key .. ".parallelogram#worldWidthXZ")
		local v93_, v94_ = xmlFile:getValue(key .. ".parallelogram#worldHeightXZ")
		if v91_ == nil or (v92_ == nil or (v93_ == nil or v94_ == nil)) then
			if v91_ == nil and (v92_ == nil and (v93_ == nil and v94_ == nil)) then
				local v95_, v96_ = xmlFile:getValue(key .. ".parallelogram#widthXZ")
				local v97_, v98_ = xmlFile:getValue(key .. ".parallelogram#heightXZ")
				if v95_ == nil or (v96_ == nil or (v97_ == nil or v98_ == nil)) then
					if v95_ == nil and (v96_ == nil and (v97_ == nil and v98_ == nil)) then
						Logging.xmlWarning(xmlFile, "Invalid data for DensityMapParallelogram in \'%s\'", key)
						return nil
					elseif v95_ == nil or v96_ == nil then
						Logging.xmlWarning(xmlFile, "Invalid worldWidthXZ for DensityMapParallelogram in \'%s\'", key)
						return nil
					else
						Logging.xmlWarning(xmlFile, "Invalid worldHeightXZ for DensityMapParallelogram in \'%s\'", key)
						return nil
					end
				else
					return DensityMapParallelogram.createFromPositionAndSize(v89_, v90_, v95_, v96_, v97_, v98_)
				end
			elseif v91_ == nil or v92_ == nil then
				Logging.xmlWarning(xmlFile, "Invalid worldWidthXZ for DensityMapParallelogram in \'%s\'", key)
				return nil
			else
				Logging.xmlWarning(xmlFile, "Invalid worldHeightXZ for DensityMapParallelogram in \'%s\'", key)
				return nil
			end
		else
			return DensityMapParallelogram.createFromWorldPositions(v89_, v90_, v91_, v92_, v93_, v94_)
		end
	end
end

function DensityMapParallelogram.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.VECTOR_2, basePath .. ".parallelogram#worldStartXZ", "Parallelogram world start position (x,z)", nil, false)
	schema:register(XMLValueType.VECTOR_2, basePath .. ".parallelogram#worldWidthXZ", "Parallelogram world width position (x,z)", nil, false)
	schema:register(XMLValueType.VECTOR_2, basePath .. ".parallelogram#worldHeightXZ", "Parallelogram world height position (x,z)", nil, false)
	schema:register(XMLValueType.VECTOR_2, basePath .. ".parallelogram#widthXZ", "Parallelogram world width size (x,z)", nil, false)
	schema:register(XMLValueType.VECTOR_2, basePath .. ".parallelogram#heightXZ", "Parallelogram world height size (x,z)", nil, false)
end
