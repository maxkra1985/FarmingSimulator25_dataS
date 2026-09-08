-- Local values: DataGrid_mt
DataGrid = {}
local DataGrid_mt = Class(DataGrid)

-- Upvalues: DataGrid_mt
-- Local values: self, _
function DataGrid.new(numRows, numColumns, customMt)
	-- upvalues: (copy) DataGrid_mt
	local v5_ = customMt or DataGrid_mt
	local v6_ = setmetatable({}, v5_)
	v6_.grid = {}
	v6_.numRows = numRows
	v6_.numColumns = numColumns
	for _ = 1, numRows do
		local v7_ = v6_.grid
		table.insert(v7_, {})
	end
	return v6_
end

function DataGrid:delete()
	self.grid = nil
end

function DataGrid:getValue(rowIndex, colIndex)
	if rowIndex < 1 or self.numRows < rowIndex then
		Logging.error("rowIndex out of bounds!")
		printCallstack()
		return nil
	end
	if colIndex >= 1 and self.numColumns >= colIndex then
		return self.grid[rowIndex][colIndex]
	end
	Logging.error("colIndex out of bounds!")
	printCallstack()
	return nil
end

function DataGrid:setValue(rowIndex, colIndex, value)
	if rowIndex < 1 or self.numRows < rowIndex then
		Logging.error("rowIndex out of bounds!")
		printCallstack()
		return false
	end
	if colIndex >= 1 and self.numColumns >= colIndex then
		self.grid[rowIndex][colIndex] = value
		return true
	end
	Logging.error("colIndex out of bounds!")
	printCallstack()
	return false
end

function DataGrid:isRowColumnInRange(rowIndex, colIndex)
	local v19_
	if rowIndex > 0 and (rowIndex <= self.numRows and colIndex > 0) then
		v19_ = colIndex <= self.numColumns
	else
		v19_ = false
	end
	return v19_
end

-- Local values: cellX, cellY
function DataGrid:doForAll(cellFunction)
	for v22_ = 1, self.numColumns do
		for v23_ = 1, self.numRows do
			cellFunction(v22_, v23_, self:getValue(v23_, v22_))
		end
	end
end
