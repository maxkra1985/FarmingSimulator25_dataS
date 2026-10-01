BoundaryDetectionTask = {}
local BoundaryDetectionTask_mt = Class(BoundaryDetectionTask)
function BoundaryDetectionTask.new(x, z)
	local self = setmetatable({}, BoundaryDetectionTask_mt)
	self.startX = x
	self.startZ = z
	self.curX = x
	self.curZ = z
	self.boundaryPositions = {}
	self.terrainDetailId = g_currentMission.terrainDetailId
	self.terrainDetailResolution = g_currentMission.terrainSize / g_currentMission.terrainDetailMapSize
	if getDensityAtWorldPos(self.terrainDetailId, self.curX, 0, self.curZ) == 0 then
		return nil
	else
		return self
	end
end
function BoundaryDetectionTask:update(dt, frameBudget)
	local terrainDetailResolution = self.terrainDetailResolution
	local startTime = getTimeSec()
	while getTimeSec() - startTime < frameBudget do
		if #self.boundaryPositions == 0 then
			local isOnField = getDensityAtWorldPos(self.terrainDetailId, self.curX, 0, self.curZ) ~= 0
			if isOnField then
				self.curZ = self.curZ + terrainDetailResolution
			else
				table.insert(self.boundaryPositions, { self.curX, self.curZ })
			end
		else
			local numPositions = #self.boundaryPositions
			local dirX = nil
			local dirZ = nil
			if 2 <= numPositions then
				dirX = self.boundaryPositions[numPositions][1] - self.boundaryPositions[numPositions - 1][1]
				dirZ = self.boundaryPositions[numPositions][2] - self.boundaryPositions[numPositions - 1][2]
			elseif getDensityAtWorldPos(self.terrainDetailId, self.curX + terrainDetailResolution, 0, self.curZ) == 0 then
				dirX = -1
				dirZ = 0
			elseif getDensityAtWorldPos(self.terrainDetailId, self.curX, 0, self.curZ + terrainDetailResolution) == 0 then
				dirX = 0
				dirZ = -1
			else
				dirX = 1
				dirZ = 0
			end
			dirX, dirZ = MathUtil.vector2Normalize(dirX, dirZ)
			dirX = dirX * terrainDetailResolution
			dirZ = dirZ * terrainDetailResolution
			local frontValue = getDensityAtWorldPos(self.terrainDetailId, self.curX + dirX, 0, self.curZ + dirZ)
			local leftValue = getDensityAtWorldPos(self.terrainDetailId, self.curX + dirZ, 0, self.curZ - dirX)
			local rightValue = getDensityAtWorldPos(self.terrainDetailId, self.curX - dirZ, 0, self.curZ + dirX)
			if rightValue ~= 0 then
				if frontValue == 0 then
					self.curX = self.curX + dirX
					self.curZ = self.curZ + dirZ
				elseif rightValue == 0 then
					self.curX = self.curX - dirZ
					self.curZ = self.curZ + dirX
				elseif leftValue == 0 then
					self.curX = self.curX + dirZ
					self.curZ = self.curZ - dirX
				else
					self.curX = self.curX - dirX
					self.curZ = self.curZ - dirZ
				end
			end
			table.insert(self.boundaryPositions, { self.curX, self.curZ })
		end
		local numPositions = #self.boundaryPositions
		if 10 < numPositions then
			local distance = MathUtil.vector2Length(self.boundaryPositions[numPositions][1] - self.boundaryPositions[1][1], self.boundaryPositions[numPositions][2] - self.boundaryPositions[1][2])
			if distance < self.terrainDetailResolution then
				self:finalize()
				return false
			end
		end
		if 15000 < numPositions then
			local dirX, dirZ = MathUtil.vector2Normalize(self.boundaryPositions[numPositions][1] - self.boundaryPositions[numPositions - 1][1], self.boundaryPositions[numPositions][2] - self.boundaryPositions[numPositions - 1][2])
			for i = numPositions - 1, 2, -1 do
				if math.abs(self.boundaryPositions[i][1] - self.curX) < 0.001 and math.abs(self.boundaryPositions[i][2] - self.curZ) < 0.001 then
					local pDirX, pDirZ = MathUtil.vector2Normalize(self.boundaryPositions[i][1] - self.boundaryPositions[i - 1][1], self.boundaryPositions[i][2] - self.boundaryPositions[i - 1][2])
					if math.abs(dirX - pDirX) < 0.001 and math.abs(dirZ - pDirZ) < 0.001 then
						Logging.devWarning("BoundaryDetectionTask: Unable to detect field boundary - infinite loop detected")
						self:finalize()
						return false
					end
				end
			end
		end
	end
	return true
end
function BoundaryDetectionTask:getMaxZ()
	local maxZ = -math.huge
	for _, position in pairs(self.boundaryPositions) do
		maxZ = math.max(maxZ, position[2])
	end
	return maxZ
end
function BoundaryDetectionTask:finalize()
	local maxValue = -math.huge
	local maxValueIndex = 0
	for i, position in pairs(self.boundaryPositions) do
		local value = position[1] * position[2] * 0.1
		if maxValue < value then
			maxValue = value
			maxValueIndex = i
		end
	end
	local newBoundaryPositions = {}
	for i = maxValueIndex, #self.boundaryPositions do
		table.insert(newBoundaryPositions, self.boundaryPositions[i])
	end
	for i = 1, maxValueIndex - 1 do
		table.insert(newBoundaryPositions, self.boundaryPositions[i])
	end
	table.insert(newBoundaryPositions, { newBoundaryPositions[1][1], newBoundaryPositions[1][2] })
	self.boundaryPositions = newBoundaryPositions
end
