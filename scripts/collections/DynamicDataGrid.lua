-- Local values: DynamicDataGrid_mt
DynamicDataGrid = {}
local DynamicDataGrid_mt = Class(DynamicDataGrid)

-- Upvalues: DynamicDataGrid_mt
-- Local values: self, columnIndex, column, rowIndex, cell, cellWorldX, cellWorldZ
function DynamicDataGrid.new(size, tileSize, startX, startZ, cellConstructor, customMt)
	-- upvalues: (copy) DynamicDataGrid_mt
	local v8_ = customMt or DynamicDataGrid_mt
	local v9_ = setmetatable({}, v8_)
	v9_.tileSize = tileSize or 1
	v9_.size = size or 20
	local v10_ = v9_.size / v9_.tileSize
	v9_.rowColumnCount = math.ceil(v10_)
	local v11_ = v9_.rowColumnCount * 0.5
	v9_.centreIndex = math.floor(v11_) + 1
	v9_.localStartIndex = 1 - v9_.centreIndex
	v9_.localEndIndex = v9_.localStartIndex + v9_.rowColumnCount - 1
	v9_.lastPosition = {
		["x"] = 0,
		["z"] = 0
	}
	if startX and startZ then
		v9_.lastPosition.x = startX
		v9_.lastPosition.z = startZ
	end
	v9_.movedCells = {}
	v9_.grid = {}
	for v12_ = v9_.localStartIndex, v9_.localEndIndex do
		local v13_ = {}
		for v14_ = v9_.localStartIndex, v9_.localEndIndex do
			local v15_
			if cellConstructor then
				local v16_, v17_ = v9_:getWorldPositionByLocalIndices(v12_, v14_)
				v15_ = cellConstructor(v16_, v17_)
			else
				v15_ = {}
			end
			table.insert(v13_, v15_)
		end
		local v18_ = v9_.grid
		table.insert(v18_, v13_)
	end
	v9_.yOffset = 0.05
	return v9_
end

-- Local values: columnIndex, rowIndex, cell
function DynamicDataGrid:delete()
	for v20_ = self.localStartIndex, self.localEndIndex do
		for v21_ = self.localStartIndex, self.localEndIndex do
			local v22_ = self:getCellFromLocalIndices(v20_, v21_)
			if v22_ and v22_.delete then
				v22_:delete()
			end
		end
	end
	self.grid = nil
end

-- Local values: xIndexLast, zIndexLast, startX, startZ, terrainNode, xIndex, column, posZ, zIndex, cell, x, z, x1, z1, x2, z2, x3, z3, r, g, b, a, y, y1, y2, y3, cx, cz
function DynamicDataGrid:drawDebug(areaColorFunction, cellFunction)
	local v26_ = self.lastPosition.x / self.tileSize
	local v27_ = math.floor(v26_) * self.tileSize
	local v28_ = self.lastPosition.z / self.tileSize
	local v29_ = math.floor(v28_) * self.tileSize
	local v30_ = self.rowColumnCount * 0.5
	local v31_ = v27_ - math.floor(v30_) * self.tileSize
	local v32_ = self.rowColumnCount * 0.5
	local v33_ = v29_ - math.floor(v32_) * self.tileSize
	local v34_ = g_terrainNode
	for _, v35_ in ipairs(self.grid) do
		local v36_ = v33_
		for _, v37_ in ipairs(v35_) do
			if areaColorFunction ~= nil then
				local v38_ = v31_ + self.tileSize
				local v39_ = v33_ + self.tileSize
				local v40_, v41_, v42_, v43_ = areaColorFunction(v37_)
				local v44_ = getTerrainHeightAtWorldPos(v34_, v31_, 0, v33_) + self.yOffset
				local v45_ = getTerrainHeightAtWorldPos(v34_, v38_, 0, v33_) + self.yOffset
				local v46_ = getTerrainHeightAtWorldPos(v34_, v31_, 0, v39_) + self.yOffset
				local v47_ = getTerrainHeightAtWorldPos(v34_, v38_, 0, v39_) + self.yOffset
				drawDebugTriangle(v31_, v44_, v33_, v31_, v46_, v39_, v38_, v45_, v33_, v40_, v41_, v42_, v43_, false)
				drawDebugTriangle(v38_, v45_, v33_, v31_, v46_, v39_, v38_, v47_, v39_, v40_, v41_, v42_, v43_, false)
			end
			if cellFunction ~= nil then
				cellFunction(v37_, v31_ + self.tileSize * 0.5, v33_ + self.tileSize * 0.5)
			end
			v33_ = v33_ + self.tileSize
		end
		v31_ = v31_ + self.tileSize
		v33_ = v36_
	end
end

-- Local values: column, cell
function DynamicDataGrid:getCellFromLocalIndices(localIndexX, localIndexZ)
	local v51_ = localIndexZ or 0
	local v52_ = self.grid[self.centreIndex + (localIndexX or 0)]
	if v52_ == nil then
		return nil
	else
		return v52_[self.centreIndex + v51_]
	end
end

-- Local values: xIndex, zIndex, xrows
function DynamicDataGrid:getCellFromWorldPosition(worldX, worldZ, clamp)
	local v57_, v58_ = self:getLocalIndicesByWorldPosition(worldX, worldZ)
	if clamp then
		local v59_ = self.localStartIndex
		local v60_ = self.localEndIndex
		v57_ = math.clamp(v57_, v59_, v60_)
		local v61_ = self.localStartIndex
		local v62_ = self.localEndIndex
		v58_ = math.clamp(v58_, v61_, v62_)
	end
	local v63_ = self.grid[self.centreIndex + v57_]
	if v63_ == nil then
		return nil
	else
		return v63_[self.centreIndex + v58_]
	end
end

-- Local values: currentIndexX, currentIndexZ
function DynamicDataGrid:getWorldPositionByLocalIndices(localIndexX, localIndexZ)
	local v67_, v68_ = self:getWorldIndicesByWorldPosition(self.lastPosition.x, self.lastPosition.z)
	return self:getGridSnappedPositionByLocalIndices(v67_ + localIndexX, v68_ + localIndexZ)
end

-- Local values: currentIndexX, currentIndexZ, worldIndexX, worldIndexZ, localIndexX, localIndexZ
function DynamicDataGrid:getLocalIndicesByWorldPosition(worldX, worldZ)
	local v72_, v73_ = self:getWorldIndicesByWorldPosition(self.lastPosition.x, self.lastPosition.z)
	local v74_, v75_ = self:getWorldIndicesByWorldPosition(worldX, worldZ)
	return v74_ - v72_, v75_ - v73_
end

function DynamicDataGrid:getGridSnappedPositionByLocalIndices(localIndexX, localIndexZ)
	return self:getGridSnappedPosition(localIndexX * self.tileSize, localIndexZ * self.tileSize)
end

-- Local values: snappedX, snappedZ
function DynamicDataGrid:getGridSnappedPosition(x, z)
	local v82_ = x / self.tileSize
	local v83_ = math.floor(v82_) * self.tileSize
	local v84_ = z / self.tileSize
	local v85_ = math.floor(v84_) * self.tileSize
	return v83_ + self.tileSize / 2, v85_ + self.tileSize / 2
end

-- Local values: worldIndexX, worldIndexZ, currentIndexX, currentIndexZ
function DynamicDataGrid:getGridIndicesByWorldPosition(worldX, worldZ)
	local v89_, v90_ = self:getWorldIndicesByWorldPosition(worldX, worldZ)
	local v91_, v92_ = self:getWorldIndicesByWorldPosition(self.lastPosition.x, self.lastPosition.z)
	return v89_ - v91_ + self.centreIndex, v90_ - v92_ + self.centreIndex
end

function DynamicDataGrid:getWorldIndicesByWorldPosition(worldX, worldZ)
	local v96_ = worldX / self.tileSize
	local v97_ = math.floor(v96_)
	local v98_ = worldZ / self.tileSize
	return v97_, math.floor(v98_)
end

-- Local values: xIndex, zIndex, lastXIndex, lastZIndex, xChange, zChange, direction, i, movingLeft, insertIndex, removeIndex, column, rowIndex, cell, direction, i, j, movingBackwards, insertIndex, removeIndex, column, cell, columnIndex, rowIndex, cell, worldX, worldZ
function DynamicDataGrid:setWorldPosition(x, z)
	local v102_, v103_ = self:getWorldIndicesByWorldPosition(x, z)
	local v104_, v105_ = self:getWorldIndicesByWorldPosition(self.lastPosition.x, self.lastPosition.z)
	self.lastPosition.x = x
	self.lastPosition.z = z
	local v106_ = v102_ - v104_
	local v107_ = v103_ - v105_
	if v106_ ~= 0 then
		local v108_ = math.sign(v106_)
		local v109_ = math.abs(v106_)
		local v110_ = self.rowColumnCount
		for _ = 1, math.min(v109_, v110_) do
			local v111_ = v108_ < 0
			local v112_ = v111_ and (self.rowColumnCount or 1) or 1
			local v113_ = table.remove(self.grid, v112_)
			local v114_ = v111_ and 1 or nil
			for _, v115_ in ipairs(v113_) do
				self.movedCells[v115_] = v115_
			end
			if v114_ == nil then
				local v116_ = self.grid
				table.insert(v116_, v113_)
			else
				local v117_ = self.grid
				table.insert(v117_, v114_, v113_)
			end
		end
	end
	if v107_ ~= 0 then
		local v118_ = math.sign(v107_)
		local v119_ = math.abs(v107_)
		local v120_ = self.rowColumnCount
		for _ = 1, math.min(v119_, v120_) do
			for v121_ = 1, self.rowColumnCount do
				local v122_ = v118_ < 0
				local v123_ = v122_ and 1 or nil
				local v124_ = v122_ and (self.rowColumnCount or 1) or 1
				local v125_ = self.grid[v121_]
				local v126_ = table.remove(v125_, v124_)
				self.movedCells[v126_] = v126_
				if v123_ == nil then
					table.insert(v125_, v126_)
				else
					table.insert(v125_, v123_, v126_)
				end
			end
		end
	end
	for v127_ = self.localStartIndex, self.localEndIndex do
		for v128_ = self.localStartIndex, self.localEndIndex do
			local v129_ = self:getCellFromLocalIndices(v127_, v128_)
			if self.movedCells[v129_] then
				if v129_.onCellMoved then
					local v130_, v131_ = self:getWorldPositionByLocalIndices(v127_, v128_)
					v129_:onCellMoved(v130_, v131_)
				else
					table.clear(v129_)
				end
			end
		end
	end
	table.clear(self.movedCells)
end
