DynamicDataGrid = {}
local DynamicDataGrid_mt = Class(DynamicDataGrid)
function DynamicDataGrid.new(size, tileSize, startX, startZ, cellConstructor, customMt)
	local self = setmetatable({}, customMt or DynamicDataGrid_mt)
	self.tileSize = tileSize or 1
	self.size = size or 20
	self.rowColumnCount = math.ceil(self.size / self.tileSize)
	self.centreIndex = math.floor(self.rowColumnCount * 0.5) + 1
	self.localStartIndex = 1 - self.centreIndex
	self.localEndIndex = self.localStartIndex + self.rowColumnCount - 1
	self.lastPosition = { x = 0, z = 0 }
	if startX and startZ then
		self.lastPosition.x = startX
		self.lastPosition.z = startZ
	end
	self.movedCells = {}
	self.grid = {}
	for columnIndex = self.localStartIndex, self.localEndIndex do
		local column = {}
		for rowIndex = self.localStartIndex, self.localEndIndex do
			local cell = nil
			if cellConstructor then
				local cellWorldX, cellWorldZ = self:getWorldPositionByLocalIndices(columnIndex, rowIndex)
				cell = cellConstructor(cellWorldX, cellWorldZ)
			else
				cell = {}
			end
			table.insert(column, cell)
		end
		table.insert(self.grid, column)
	end
	self.yOffset = 0.05
	return self
end
function DynamicDataGrid:delete()
	for columnIndex = self.localStartIndex, self.localEndIndex do
		for rowIndex = self.localStartIndex, self.localEndIndex do
			local cell = self:getCellFromLocalIndices(columnIndex, rowIndex)
			if cell and cell.delete then
				cell:delete()
			end
		end
	end
	self.grid = nil
end
function DynamicDataGrid:drawDebug(areaColorFunction, cellFunction)
	local xIndexLast = math.floor(self.lastPosition.x / self.tileSize) * self.tileSize
	local zIndexLast = math.floor(self.lastPosition.z / self.tileSize) * self.tileSize
	local startX = xIndexLast - math.floor(self.rowColumnCount * 0.5) * self.tileSize
	local startZ = zIndexLast - math.floor(self.rowColumnCount * 0.5) * self.tileSize
	local terrainNode = g_terrainNode
	for xIndex, column in ipairs(self.grid) do
		local posZ = startZ
		for zIndex, cell in ipairs(column) do
			local x = startX
			local z = posZ
			if areaColorFunction ~= nil then
				local x1 = startX + self.tileSize
				local z1 = posZ
				local x2 = startX
				local z2 = posZ + self.tileSize
				local r, g, b, a = areaColorFunction(cell)
				local y = getTerrainHeightAtWorldPos(terrainNode, x, 0, z) + self.yOffset
				local y1 = getTerrainHeightAtWorldPos(terrainNode, x1, 0, z1) + self.yOffset
				local y2 = getTerrainHeightAtWorldPos(terrainNode, x2, 0, z2) + self.yOffset
				local y3 = getTerrainHeightAtWorldPos(terrainNode, x1, 0, z2) + self.yOffset
				drawDebugTriangle(x, y, z, x2, y2, z2, x1, y1, z1, r, g, b, a, false)
				drawDebugTriangle(x1, y1, z1, x2, y2, z2, x1, y3, z2, r, g, b, a, false)
			end
			if cellFunction ~= nil then
				local cx = x + self.tileSize * 0.5
				local cz = z + self.tileSize * 0.5
				cellFunction(cell, cx, cz)
			end
			posZ = posZ + self.tileSize
		end
		startX = startX + self.tileSize
	end
end
function DynamicDataGrid:getCellFromLocalIndices(localIndexX, localIndexZ)
	localIndexX = localIndexX or 0
	localIndexZ = localIndexZ or 0
	local column = self.grid[self.centreIndex + localIndexX]
	if column == nil then
		return nil
	else
		local cell = column[self.centreIndex + localIndexZ]
		return cell
	end
end
function DynamicDataGrid:getCellFromWorldPosition(worldX, worldZ, clamp)
	local xIndex, zIndex = self:getLocalIndicesByWorldPosition(worldX, worldZ)
	if clamp then
		xIndex = math.clamp(xIndex, self.localStartIndex, self.localEndIndex)
		zIndex = math.clamp(zIndex, self.localStartIndex, self.localEndIndex)
	end
	local xrows = self.grid[self.centreIndex + xIndex]
	if xrows ~= nil then
		return xrows[self.centreIndex + zIndex]
	else
		return nil
	end
end
function DynamicDataGrid:getWorldPositionByLocalIndices(localIndexX, localIndexZ)
	local currentIndexX, currentIndexZ = self:getWorldIndicesByWorldPosition(self.lastPosition.x, self.lastPosition.z)
	return self:getGridSnappedPositionByLocalIndices(currentIndexX + localIndexX, currentIndexZ + localIndexZ)
end
function DynamicDataGrid:getLocalIndicesByWorldPosition(worldX, worldZ)
	local currentIndexX, currentIndexZ = self:getWorldIndicesByWorldPosition(self.lastPosition.x, self.lastPosition.z)
	local worldIndexX, worldIndexZ = self:getWorldIndicesByWorldPosition(worldX, worldZ)
	local localIndexX = worldIndexX - currentIndexX
	local localIndexZ = worldIndexZ - currentIndexZ
	return localIndexX, localIndexZ
end
function DynamicDataGrid:getGridSnappedPositionByLocalIndices(localIndexX, localIndexZ)
	return self:getGridSnappedPosition(localIndexX * self.tileSize, localIndexZ * self.tileSize)
end
function DynamicDataGrid:getGridSnappedPosition(x, z)
	local snappedX = math.floor(x / self.tileSize) * self.tileSize
	local snappedZ = math.floor(z / self.tileSize) * self.tileSize
	snappedX = snappedX + self.tileSize / 2
	snappedZ = snappedZ + self.tileSize / 2
	return snappedX, snappedZ
end
function DynamicDataGrid:getGridIndicesByWorldPosition(worldX, worldZ)
	local worldIndexX, worldIndexZ = self:getWorldIndicesByWorldPosition(worldX, worldZ)
	local currentIndexX, currentIndexZ = self:getWorldIndicesByWorldPosition(self.lastPosition.x, self.lastPosition.z)
	worldIndexX = worldIndexX - currentIndexX + self.centreIndex
	worldIndexZ = worldIndexZ - currentIndexZ + self.centreIndex
	return worldIndexX, worldIndexZ
end
function DynamicDataGrid:getWorldIndicesByWorldPosition(worldX, worldZ)
	return math.floor(worldX / self.tileSize), math.floor(worldZ / self.tileSize)
end
function DynamicDataGrid:setWorldPosition(x, z)
	local xIndex, zIndex = self:getWorldIndicesByWorldPosition(x, z)
	local lastXIndex, lastZIndex = self:getWorldIndicesByWorldPosition(self.lastPosition.x, self.lastPosition.z)
	self.lastPosition.x = x
	self.lastPosition.z = z
	local xChange = xIndex - lastXIndex
	local zChange = zIndex - lastZIndex
	if xChange ~= 0 then
		local direction = math.sign(xChange)
		for i = 1, math.min(math.abs(xChange), self.rowColumnCount) do
			local insertIndex = direction < 0 and 1
			local removeIndex = movingLeft and self.rowColumnCount or 1
			local column = table.remove(self.grid, removeIndex)
			for rowIndex, cell in ipairs(column) do
				self.movedCells[cell] = cell
			end
			if insertIndex == nil then
				table.insert(self.grid, column)
			else
				table.insert(self.grid, insertIndex, column)
			end
		end
	end
	if zChange ~= 0 then
		local direction = math.sign(zChange)
		for i = 1, math.min(math.abs(zChange), self.rowColumnCount) do
			for j = 1, self.rowColumnCount do
				local insertIndex = direction < 0 and 1
				local removeIndex = movingBackwards and self.rowColumnCount or 1
				local column = self.grid[j]
				local cell = table.remove(column, removeIndex)
				self.movedCells[cell] = cell
				if insertIndex == nil then
					table.insert(column, cell)
				else
					table.insert(column, insertIndex, cell)
				end
			end
		end
	end
	for columnIndex = self.localStartIndex, self.localEndIndex do
		for rowIndex = self.localStartIndex, self.localEndIndex do
			local cell = self:getCellFromLocalIndices(columnIndex, rowIndex)
			if self.movedCells[cell] then
				if cell.onCellMoved then
					local worldX, worldZ = self:getWorldPositionByLocalIndices(columnIndex, rowIndex)
					cell:onCellMoved(worldX, worldZ)
				else
					table.clear(cell)
				end
			end
		end
	end
	table.clear(self.movedCells)
end
