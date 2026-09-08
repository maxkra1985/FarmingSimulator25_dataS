-- Local values: BoundaryDetectionTaskInsideOut_mt
BoundaryDetectionTaskInsideOut = {}
local BoundaryDetectionTaskInsideOut_mt = Class(BoundaryDetectionTaskInsideOut)

-- Upvalues: BoundaryDetectionTaskInsideOut_mt
-- Local values: self
function BoundaryDetectionTaskInsideOut.new(x, z)
	-- upvalues: (copy) BoundaryDetectionTaskInsideOut_mt
	local v4_ = BoundaryDetectionTaskInsideOut_mt
	local v5_ = setmetatable({}, v4_)
	v5_.startX = x
	v5_.startZ = z
	v5_.curX = x
	v5_.curZ = z
	v5_.boundaryPositions = {}
	v5_.terrainDetailId = g_currentMission.terrainDetailId
	v5_.terrainDetailResolution = g_currentMission.terrainSize / g_currentMission.terrainDetailMapSize
	if getDensityAtWorldPos(v5_.terrainDetailId, v5_.curX, 0, v5_.curZ) == 0 then
		return v5_
	else
		return nil
	end
end

-- Local values: terrainDetailResolution, startTime, isOnField, numPositions, dirX, dirZ, frontValue, leftValue, rightValue, numPositions, distance, dirX, dirZ, i, pDirX, pDirZ
function BoundaryDetectionTaskInsideOut:update(dt, frameBudget)
	local v8_ = self.terrainDetailResolution
	local v9_ = getTimeSec()
	while getTimeSec() - v9_ < frameBudget do
		if #self.boundaryPositions == 0 then
			if getDensityAtWorldPos(self.terrainDetailId, self.curX, 0, self.curZ) ~= 0 then
				local v10_ = self.curX
				local v11_ = self.curZ - v8_
				self.curX = v10_
				self.curZ = v11_
				local v12_ = self.boundaryPositions
				local v13_ = { self.curX, self.curZ }
				table.insert(v12_, v13_)
			else
				self.curZ = self.curZ + v8_
			end
		else
			local v14_ = #self.boundaryPositions
			local v15_, v16_
			if v14_ >= 2 then
				v15_ = self.boundaryPositions[v14_][1] - self.boundaryPositions[v14_ - 1][1]
				v16_ = self.boundaryPositions[v14_][2] - self.boundaryPositions[v14_ - 1][2]
			elseif getDensityAtWorldPos(self.terrainDetailId, self.curX + v8_, 0, self.curZ) == 0 then
				v15_ = -1
				v16_ = 0
			elseif getDensityAtWorldPos(self.terrainDetailId, self.curX, 0, self.curZ + v8_) == 0 then
				v15_ = 0
				v16_ = -1
			else
				v15_ = 1
				v16_ = 0
			end
			local v17_, v18_ = MathUtil.vector2Normalize(v15_, v16_)
			local v19_ = v17_ * v8_
			local v20_ = v18_ * v8_
			local v21_ = getDensityAtWorldPos(self.terrainDetailId, self.curX + v19_, 0, self.curZ + v20_)
			local v22_ = getDensityAtWorldPos(self.terrainDetailId, self.curX + v20_, 0, self.curZ - v19_)
			local v23_ = getDensityAtWorldPos(self.terrainDetailId, self.curX - v20_, 0, self.curZ + v19_)
			if v22_ == 0 or v21_ ~= 0 then
				if v22_ == 0 then
					local v24_ = self.curX + v20_
					local v25_ = self.curZ - v19_
					self.curX = v24_
					self.curZ = v25_
				elseif v23_ == 0 then
					local v26_ = self.curX - v20_
					local v27_ = self.curZ + v19_
					self.curX = v26_
					self.curZ = v27_
				else
					local v28_ = self.curX - v19_
					local v29_ = self.curZ - v20_
					self.curX = v28_
					self.curZ = v29_
				end
			else
				local v30_ = self.curX + v19_
				local v31_ = self.curZ + v20_
				self.curX = v30_
				self.curZ = v31_
			end
			local v32_ = self.boundaryPositions
			local v33_ = { self.curX, self.curZ }
			table.insert(v32_, v33_)
		end
		local v34_ = #self.boundaryPositions
		if v34_ > 10 and MathUtil.vector2Length(self.boundaryPositions[v34_][1] - self.boundaryPositions[1][1], self.boundaryPositions[v34_][2] - self.boundaryPositions[1][2]) < self.terrainDetailResolution then
			self:finalize()
			return false
		end
		if v34_ > 15000 then
			local v35_, v36_ = MathUtil.vector2Normalize(self.boundaryPositions[v34_][1] - self.boundaryPositions[v34_ - 1][1], self.boundaryPositions[v34_][2] - self.boundaryPositions[v34_ - 1][2])
			for v37_ = v34_ - 1, 2, -1 do
				local v38_ = self.boundaryPositions[v37_][1] - self.curX
				if math.abs(v38_) < 0.001 then
					local v39_ = self.boundaryPositions[v37_][2] - self.curZ
					if math.abs(v39_) < 0.001 then
						local v40_, v41_ = MathUtil.vector2Normalize(self.boundaryPositions[v37_][1] - self.boundaryPositions[v37_ - 1][1], self.boundaryPositions[v37_][2] - self.boundaryPositions[v37_ - 1][2])
						local v42_ = v35_ - v40_
						if math.abs(v42_) < 0.001 then
							local v43_ = v36_ - v41_
							if math.abs(v43_) < 0.001 then
								Logging.devWarning("BoundaryDetectionTaskInsideOut: Unable to detect field boundary - infinite loop detected")
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
function BoundaryDetectionTaskInsideOut:getMaxZ()
	local v45_ = -math.huge
	for _, v46_ in pairs(self.boundaryPositions) do
		local v47_ = v46_[2]
		v45_ = math.max(v45_, v47_)
	end
	return v45_
end

-- Local values: maxValue, maxValueIndex, i, position, value, newBoundaryPositions, i, i
function BoundaryDetectionTaskInsideOut:finalize()
	local v49_ = -math.huge
	local v50_ = 0
	for v51_, v52_ in pairs(self.boundaryPositions) do
		local v53_ = v52_[1] * v52_[2] * 0.1
		if v49_ < v53_ then
			v50_ = v51_
			v49_ = v53_
		end
	end
	local v54_ = {}
	for v55_ = v50_, #self.boundaryPositions do
		local v56_ = self.boundaryPositions[v55_]
		table.insert(v54_, v56_)
	end
	for v57_ = 1, v50_ - 1 do
		local v58_ = self.boundaryPositions[v57_]
		table.insert(v54_, v58_)
	end
	local v59_ = { v54_[1][1], v54_[1][2] }
	table.insert(v54_, v59_)
	self.boundaryPositions = v54_
end
