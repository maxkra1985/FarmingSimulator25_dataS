-- Local values: MapDataGrid_mt
MapDataGrid = {}
local MapDataGrid_mt = Class(MapDataGrid, DataGrid)

-- Upvalues: MapDataGrid_mt
-- Local values: self
function MapDataGrid.new(mapSize, blocksPerRowColumn, customMt)
	-- upvalues: (copy) MapDataGrid_mt
	local v5_ = DataGrid.new(blocksPerRowColumn, blocksPerRowColumn, customMt or MapDataGrid_mt)
	v5_.blocksPerRowColumn = blocksPerRowColumn
	v5_.mapSize = mapSize
	v5_.blockSize = v5_.mapSize / v5_.blocksPerRowColumn
	return v5_
end

-- Local values: blocksPerRowColumn
function MapDataGrid.createFromBlockSize(mapSize, blockSize, customMt)
	local v9_ = mapSize / blockSize
	local v10_ = math.ceil(v9_)
	return MapDataGrid.new(mapSize, v10_, customMt)
end

-- Local values: rowIndex, colIndex
function MapDataGrid:getValueAtWorldPos(worldX, worldZ)
	local v14_, v15_ = self:getRowColumnFromWorldPos(worldX, worldZ)
	return self:getValue(v14_, v15_), v14_, v15_
end

-- Local values: rowIndex, colIndex
function MapDataGrid:setValueAtWorldPos(worldX, worldZ, value)
	local v20_, v21_ = self:getRowColumnFromWorldPos(worldX, worldZ)
	self:setValue(v20_, v21_, value)
end

-- Local values: mapSize, blocksPerRowColumn, x, z, row, column
function MapDataGrid:getRowColumnFromWorldPos(worldX, worldZ)
	local v25_ = self.mapSize
	local v26_ = self.blocksPerRowColumn
	local v27_ = (worldX + v25_ * 0.5) / v25_
	local v28_ = v26_ * ((worldZ + v25_ * 0.5) / v25_)
	local v29_ = math.ceil(v28_)
	local v30_ = math.clamp(v29_, 1, v26_)
	local v31_ = v26_ * v27_
	local v32_ = math.ceil(v31_)
	return v30_, math.clamp(v32_, 1, v26_)
end

function MapDataGrid:isWorldPositionInRange(worldX, worldZ)
	local v36_
	if self.mapSize * -0.5 < worldX and (worldX <= self.mapSize * 0.5 and self.mapSize * -0.5 < worldZ) then
		v36_ = worldZ <= self.mapSize * 0.5
	else
		v36_ = false
	end
	return v36_
end

-- Local values: minX, maxX, minZ, maxZ
function MapDataGrid:getBoundaries(row, column)
	return (column - 1) * self.blockSize - self.mapSize * 0.5, column * self.blockSize - self.mapSize * 0.5, (row - 1) * self.blockSize - self.mapSize * 0.5, row * self.blockSize - self.mapSize * 0.5
end
