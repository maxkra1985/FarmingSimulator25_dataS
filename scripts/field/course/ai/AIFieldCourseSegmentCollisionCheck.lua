-- Local values: AIFieldCourseSegmentCollisionCheck_mt
AIFieldCourseSegmentCollisionCheck = {}
source("dataS/scripts/field/course/ai/AIFieldCourseSegmentCollisionCheckState.lua")
local AIFieldCourseSegmentCollisionCheck_mt = Class(AIFieldCourseSegmentCollisionCheck)

-- Upvalues: AIFieldCourseSegmentCollisionCheck_mt
-- Local values: self
function AIFieldCourseSegmentCollisionCheck.new(fieldCourseSettings, fieldBoundaryLine, callbackFunc, callbackTarget)
	-- upvalues: (copy) AIFieldCourseSegmentCollisionCheck_mt
	local v4_ = AIFieldCourseSegmentCollisionCheck_mt
	local v5_ = setmetatable({}, v4_)
	v5_.fieldCourseSettings = fieldCourseSettings
	v5_.fieldBoundaryLine = fieldBoundaryLine
	v5_.state = AIFieldCourseSegmentCollisionCheckState.INITIAL
	return v5_
end

-- Local values: segment, direction, safetyOffset, agentLength, frontOffset, backOffset, numPositions, x1, z1, x2, z2, dirX, dirZ, bx, bz, sizeX, sizeY, sizeZ, x1, z1, x2, z2, dirX, dirZ, bx, bz, sizeX, sizeY, sizeZ
function AIFieldCourseSegmentCollisionCheck:next()
	local v7_ = self.segment
	local v8_ = self.direction
	local v9_ = self.fieldCourseSettings.agentFrontOffset + self.fieldCourseSettings.agentBackOffset + 1
	local v10_ = self.fieldCourseSettings.toolFrontOffset
	local v11_ = self.fieldCourseSettings.agentFrontOffset
	local v12_ = math.max(v10_, v11_) + 0.5
	local v13_ = self.fieldCourseSettings.toolBackOffset
	local v14_ = -self.fieldCourseSettings.agentBackOffset
	local v15_ = math.min(v13_, v14_) - 0.5
	local v16_ = #self.segment.positions
	if self.state == AIFieldCourseSegmentCollisionCheckState.START_CHECK or self.state == AIFieldCourseSegmentCollisionCheckState.START_ADJUSTMENT then
		local v17_, v18_, v19_, v20_
		if v8_ > 0 then
			v17_ = v7_.positions[1][1]
			v18_ = v7_.positions[1][2]
			local v21_ = v7_.positions[2][1]
			local v22_ = v7_.positions[2][2]
			v19_, v20_ = MathUtil.vector2Normalize(v21_ - v17_, v22_ - v18_)
		else
			v17_ = v7_.positions[v16_][1]
			v18_ = v7_.positions[v16_][2]
			local v23_ = v7_.positions[v16_ - 1][1]
			local v24_ = v7_.positions[v16_ - 1][2]
			v19_, v20_ = MathUtil.vector2Normalize(v23_ - v17_, v24_ - v18_)
		end
		if self.state == AIFieldCourseSegmentCollisionCheckState.START_ADJUSTMENT then
			self.startAdjustmentDistance = self.startAdjustmentDistance + 1
			if v9_ < self.startAdjustmentDistance or self.startAdjustmentDistance + 2 >= self.segmentLength then
				self.state = AIFieldCourseSegmentCollisionCheckState.END_CHECK
				self:next()
				return
			end
			v15_ = v15_ + self.startAdjustmentDistance
		end
		local v25_ = v17_ + v19_ * (v15_ + v9_ * 0.5)
		local v26_ = v18_ + v20_ * (v15_ + v9_ * 0.5)
		local v27_ = self.fieldCourseSettings.implementWidth + 0.5
		local v28_ = self.fieldCourseSettings.agentHeight + 0.5
		if v7_.sideOffset ~= nil and v7_.sideOffset ~= 0 then
			v25_ = v25_ + v20_ * v7_.sideOffset
			v26_ = v26_ - v19_ * v7_.sideOffset
		end
		self:overlapCheck(v25_, v26_, v19_, v20_, v27_, v28_, v9_, "overlapCallback")
		return
	elseif self.state == AIFieldCourseSegmentCollisionCheckState.END_CHECK or self.state == AIFieldCourseSegmentCollisionCheckState.END_ADJUSTMENT then
		local v29_, v30_, v31_, v32_
		if v8_ > 0 then
			v29_ = v7_.positions[v16_][1]
			v30_ = v7_.positions[v16_][2]
			local v33_ = v7_.positions[v16_ - 1][1]
			local v34_ = v7_.positions[v16_ - 1][2]
			v31_, v32_ = MathUtil.vector2Normalize(v33_ - v29_, v34_ - v30_)
		else
			v29_ = v7_.positions[1][1]
			v30_ = v7_.positions[1][2]
			local v35_ = v7_.positions[2][1]
			local v36_ = v7_.positions[2][2]
			v31_, v32_ = MathUtil.vector2Normalize(v35_ - v29_, v36_ - v30_)
		end
		if self.state == AIFieldCourseSegmentCollisionCheckState.END_ADJUSTMENT then
			self.endAdjustmentDistance = self.endAdjustmentDistance + 1
			if v9_ < self.endAdjustmentDistance or self.endAdjustmentDistance + 2 >= self.segmentLength - self.startAdjustmentDistance then
				self.state = AIFieldCourseSegmentCollisionCheckState.FINISHED
				self:next()
				return
			end
			v12_ = v12_ - self.endAdjustmentDistance
		end
		local v37_ = v29_ - v31_ * (v12_ - v9_ * 0.5)
		local v38_ = v30_ - v32_ * (v12_ - v9_ * 0.5)
		local v39_ = self.fieldCourseSettings.implementWidth + 0.5
		local v40_ = self.fieldCourseSettings.agentHeight + 0.5
		if v7_.sideOffset ~= nil and v7_.sideOffset ~= 0 then
			v37_ = v37_ - v32_ * v7_.sideOffset
			v38_ = v38_ + v31_ * v7_.sideOffset
		end
		self:overlapCheck(v37_, v38_, v31_, v32_, v39_, v40_, v9_, "overlapCallback")
	elseif self.state == AIFieldCourseSegmentCollisionCheckState.FINISHED then
		if self.startAdjustmentDistance ~= 0 then
			FieldCourseUtil.extendSegment(v7_.positions, -v8_, -self.startAdjustmentDistance)
		end
		if self.endAdjustmentDistance ~= 0 then
			FieldCourseUtil.extendSegment(v7_.positions, v8_, -self.endAdjustmentDistance)
		end
		self:doCallback()
	end
end

function AIFieldCourseSegmentCollisionCheck:checkSegment(segment, direction, callbackFunc, callbackTarget)
	self.segment = segment
	self.segmentLength = FieldCourseUtil.getSegmentLength(segment.positions)
	self.direction = direction
	self.callbackFunc = callbackFunc
	self.callbackTarget = callbackTarget
	self.startAdjustmentDistance = 0
	self.endAdjustmentDistance = 0
	self.state = AIFieldCourseSegmentCollisionCheckState.START_CHECK
	self:next()
end

-- Local values: ry, y, p1x, p1z, p2x, p2z, p3x, p3z, p4x, p4z
function AIFieldCourseSegmentCollisionCheck:overlapCheck(x, z, dirX, dirZ, sizeX, sizeY, sizeZ, callbackName, debugBoxName)
	local v55_ = MathUtil.getYRotationFromDirection(dirX, dirZ)
	local v56_ = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z) + sizeY * 0.5
	local v57_ = sizeX * 0.5
	local v58_ = sizeY * 0.5
	local v59_ = sizeZ * 0.5
	local v60_ = x + dirX * v59_ + dirZ * v57_
	local v61_ = z + dirZ * v59_ - dirX * v57_
	local v62_ = x + dirX * v59_ - dirZ * v57_
	local v63_ = z + dirZ * v59_ + dirX * v57_
	if FieldCourseUtil.getIsSegmentInsideBoundary(v60_, v61_, v62_, v63_, self.fieldBoundaryLine) then
		local v64_ = x - dirX * v59_ + dirZ * v57_
		local v65_ = z - dirZ * v59_ - dirX * v57_
		local v66_ = x - dirX * v59_ - dirZ * v57_
		local v67_ = z - dirZ * v59_ + dirX * v57_
		if FieldCourseUtil.getIsSegmentInsideBoundary(v64_, v65_, v66_, v67_, self.fieldBoundaryLine) and (FieldCourseUtil.getIsSegmentInsideBoundary(v60_, v61_, v64_, v65_, self.fieldBoundaryLine) and FieldCourseUtil.getIsSegmentInsideBoundary(v62_, v63_, v66_, v67_, self.fieldBoundaryLine)) then
			self:overlapCallback(0, -1, true)
			return
		end
	end
	overlapBoxAsync(x, v56_, z, 0, v55_, 0, v57_, v58_, v59_, callbackName, self, CollisionFlag.AI_BLOCKING, false, false, true, true)
end

function AIFieldCourseSegmentCollisionCheck:overlapCallback(nodeId, subShapeIndex, isLast)
	if g_currentMission ~= nil then
		if self.state == AIFieldCourseSegmentCollisionCheckState.START_CHECK then
			if nodeId == 0 then
				self.state = AIFieldCourseSegmentCollisionCheckState.END_CHECK
			else
				self.state = AIFieldCourseSegmentCollisionCheckState.START_ADJUSTMENT
			end
		elseif self.state == AIFieldCourseSegmentCollisionCheckState.START_ADJUSTMENT then
			if nodeId == 0 then
				self.state = AIFieldCourseSegmentCollisionCheckState.END_CHECK
			end
		elseif self.state == AIFieldCourseSegmentCollisionCheckState.END_CHECK then
			if nodeId == 0 then
				self.state = AIFieldCourseSegmentCollisionCheckState.FINISHED
			else
				self.state = AIFieldCourseSegmentCollisionCheckState.END_ADJUSTMENT
			end
		elseif self.state == AIFieldCourseSegmentCollisionCheckState.END_ADJUSTMENT and nodeId == 0 then
			self.state = AIFieldCourseSegmentCollisionCheckState.FINISHED
		end
		self:next()
		return false
	end
end

function AIFieldCourseSegmentCollisionCheck:doCallback()
	if self.callbackTarget == nil then
		self.callbackFunc(self.segment)
	else
		self.callbackFunc(self.callbackTarget, self.segment)
	end
end
