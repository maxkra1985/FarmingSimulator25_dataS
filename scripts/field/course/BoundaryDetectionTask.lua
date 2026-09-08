-- Local values: BoundaryDetectionTask_mt
BoundaryDetectionTask = {}
local BoundaryDetectionTask_mt = Class(BoundaryDetectionTask)

-- Upvalues: BoundaryDetectionTask_mt
-- Local values: self
function BoundaryDetectionTask.new(x, z)
	-- upvalues: (copy) BoundaryDetectionTask_mt
	local v4_ = BoundaryDetectionTask_mt
	local v5_ = setmetatable({}, v4_)
	v5_.startX = x
	v5_.startZ = z
	v5_.curX = x
	v5_.curZ = z
	v5_.boundaryPositions = {}
	v5_.terrainDetailId = g_currentMission.terrainDetailId
	v5_.terrainDetailResolution = g_currentMission.terrainSize / g_currentMission.terrainDetailMapSize
	if getDensityAtWorldPos(v5_.terrainDetailId, v5_.curX, 0, v5_.curZ) == 0 then
		return nil
	else
		return v5_
	end
end

-- Local values: terrainDetailResolution, startTime, isOnField, numPositions, dirX, dirZ, frontValue, leftValue, rightValue, numPositions, distance, dirX, dirZ, i, pDirX, pDirZ
function BoundaryDetectionTask:update(dt, frameBudget)
	local v8_ = self.terrainDetailResolution
	local v9_ = getTimeSec()
	while getTimeSec() - v9_ < frameBudget do
		if #self.boundaryPositions == 0 then
			if getDensityAtWorldPos(self.terrainDetailId, self.curX, 0, self.curZ) ~= 0 then
				self.curZ = self.curZ + v8_
			else
				local v10_ = self.boundaryPositions
				local v11_ = { self.curX, self.curZ }
				table.insert(v10_, v11_)
			end
		else
			local v12_ = #self.boundaryPositions
			local v13_, v14_
			if v12_ >= 2 then
				v13_ = self.boundaryPositions[v12_][1] - self.boundaryPositions[v12_ - 1][1]
				v14_ = self.boundaryPositions[v12_][2] - self.boundaryPositions[v12_ - 1][2]
			elseif getDensityAtWorldPos(self.terrainDetailId, self.curX + v8_, 0, self.curZ) == 0 then
				v13_ = -1
				v14_ = 0
			elseif getDensityAtWorldPos(self.terrainDetailId, self.curX, 0, self.curZ + v8_) == 0 then
				v13_ = 0
				v14_ = -1
			else
				v13_ = 1
				v14_ = 0
			end
			local v15_, v16_ = MathUtil.vector2Normalize(v13_, v14_)
			local v17_ = v15_ * v8_
			local v18_ = v16_ * v8_
			local v19_ = getDensityAtWorldPos(self.terrainDetailId, self.curX + v17_, 0, self.curZ + v18_)
			local v20_ = getDensityAtWorldPos(self.terrainDetailId, self.curX + v18_, 0, self.curZ - v17_)
			local v21_ = getDensityAtWorldPos(self.terrainDetailId, self.curX - v18_, 0, self.curZ + v17_)
			if v21_ == 0 or v19_ ~= 0 then
				if v21_ == 0 then
					local v22_ = self.curX - v18_
					local v23_ = self.curZ + v17_
					self.curX = v22_
					self.curZ = v23_
				elseif v20_ == 0 then
					local v24_ = self.curX + v18_
					local v25_ = self.curZ - v17_
					self.curX = v24_
					self.curZ = v25_
				else
					local v26_ = self.curX - v17_
					local v27_ = self.curZ - v18_
					self.curX = v26_
					self.curZ = v27_
				end
			else
				local v28_ = self.curX + v17_
				local v29_ = self.curZ + v18_
				self.curX = v28_
				self.curZ = v29_
			end
			local v30_ = self.boundaryPositions
			local v31_ = { self.curX, self.curZ }
			table.insert(v30_, v31_)
		end
		local v32_ = #self.boundaryPositions
		if v32_ > 10 and MathUtil.vector2Length(self.boundaryPositions[v32_][1] - self.boundaryPositions[1][1], self.boundaryPositions[v32_][2] - self.boundaryPositions[1][2]) < self.terrainDetailResolution then
			self:finalize()
			return false
		end
		if v32_ > 15000 then
			local v33_, v34_ = MathUtil.vector2Normalize(self.boundaryPositions[v32_][1] - self.boundaryPositions[v32_ - 1][1], self.boundaryPositions[v32_][2] - self.boundaryPositions[v32_ - 1][2])
			for v35_ = v32_ - 1, 2, -1 do
				local v36_ = self.boundaryPositions[v35_][1] - self.curX
				if math.abs(v36_) < 0.001 then
					local v37_ = self.boundaryPositions[v35_][2] - self.curZ
					if math.abs(v37_) < 0.001 then
						local v38_, v39_ = MathUtil.vector2Normalize(self.boundaryPositions[v35_][1] - self.boundaryPositions[v35_ - 1][1], self.boundaryPositions[v35_][2] - self.boundaryPositions[v35_ - 1][2])
						local v40_ = v33_ - v38_
						if math.abs(v40_) < 0.001 then
							local v41_ = v34_ - v39_
							if math.abs(v41_) < 0.001 then
								Logging.devWarning("BoundaryDetectionTask: Unable to detect field boundary - infinite loop detected")
								self:finalize()
								return false
							end
						end
					end
				end
			end
		end
	end
	return true
end

-- Local values: maxZ, _, position
function BoundaryDetectionTask:getMaxZ()
	local v43_ = -math.huge
	for _, v44_ in pairs(self.boundaryPositions) do
		local v45_ = v44_[2]
		v43_ = math.max(v43_, v45_)
	end
	return v43_
end

-- Local values: maxValue, maxValueIndex, i, position, value, newBoundaryPositions, i, i
function BoundaryDetectionTask:finalize()
	local v47_ = -math.huge
	local v48_ = 0
	for v49_, v50_ in pairs(self.boundaryPositions) do
		local v51_ = v50_[1] * v50_[2] * 0.1
		if v47_ < v51_ then
			v48_ = v49_
			v47_ = v51_
		end
	end
	local v52_ = {}
	for v53_ = v48_, #self.boundaryPositions do
		local v54_ = self.boundaryPositions[v53_]
		table.insert(v52_, v54_)
	end
	for v55_ = 1, v48_ - 1 do
		local v56_ = self.boundaryPositions[v55_]
		table.insert(v52_, v56_)
	end
	local v57_ = { v52_[1][1], v52_[1][2] }
	table.insert(v52_, v57_)
	self.boundaryPositions = v52_
end
