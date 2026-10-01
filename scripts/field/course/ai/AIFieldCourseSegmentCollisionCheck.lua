AIFieldCourseSegmentCollisionCheck = {}
source("dataS/scripts/field/course/ai/AIFieldCourseSegmentCollisionCheckState.lua")
local AIFieldCourseSegmentCollisionCheck_mt = Class(AIFieldCourseSegmentCollisionCheck)
function AIFieldCourseSegmentCollisionCheck.new(fieldCourseSettings, fieldBoundaryLine, callbackFunc, callbackTarget)
	local self = setmetatable({}, AIFieldCourseSegmentCollisionCheck_mt)
	self.fieldCourseSettings = fieldCourseSettings
	self.fieldBoundaryLine = fieldBoundaryLine
	self.state = AIFieldCourseSegmentCollisionCheckState.INITIAL
	return self
end
function AIFieldCourseSegmentCollisionCheck:next()
	local segment = self.segment
	local direction = self.direction
	local safetyOffset = 0.5
	local agentLength = self.fieldCourseSettings.agentFrontOffset + self.fieldCourseSettings.agentBackOffset + 1
	local frontOffset = math.max(self.fieldCourseSettings.toolFrontOffset, self.fieldCourseSettings.agentFrontOffset) + 0.5
	local backOffset = math.min(self.fieldCourseSettings.toolBackOffset, -self.fieldCourseSettings.agentBackOffset) - 0.5
	local numPositions = #self.segment.positions
	if self.state == AIFieldCourseSegmentCollisionCheckState.START_CHECK or self.state == AIFieldCourseSegmentCollisionCheckState.START_ADJUSTMENT then
		local x1 = nil
		local z1 = nil
		local x2 = nil
		local z2 = nil
		local dirX = nil
		local dirZ = nil
		if 0 < direction then
			x1 = segment.positions[1][1]
			z1 = segment.positions[1][2]
			x2 = segment.positions[2][1]
			z2 = segment.positions[2][2]
			dirX, dirZ = MathUtil.vector2Normalize(x2 - x1, z2 - z1)
		else
			x1 = segment.positions[numPositions][1]
			z1 = segment.positions[numPositions][2]
			x2 = segment.positions[numPositions - 1][1]
			z2 = segment.positions[numPositions - 1][2]
			dirX, dirZ = MathUtil.vector2Normalize(x2 - x1, z2 - z1)
		end
		if self.state == AIFieldCourseSegmentCollisionCheckState.START_ADJUSTMENT then
			self.startAdjustmentDistance = self.startAdjustmentDistance + 1
			if agentLength < self.startAdjustmentDistance or self.segmentLength <= self.startAdjustmentDistance + 2 then
				self.state = AIFieldCourseSegmentCollisionCheckState.END_CHECK
				self:next()
				return
			end
			backOffset = backOffset + self.startAdjustmentDistance
		end
		local bx = x1 + dirX * (backOffset + agentLength * 0.5)
		local bz = z1 + dirZ * (backOffset + agentLength * 0.5)
		local sizeX = self.fieldCourseSettings.implementWidth + 0.5
		local sizeY = self.fieldCourseSettings.agentHeight + 0.5
		local sizeZ = agentLength
		if segment.sideOffset ~= nil and segment.sideOffset ~= 0 then
			bx = bx + dirZ * segment.sideOffset
			bz = bz - dirX * segment.sideOffset
		end
		self:overlapCheck(bx, bz, dirX, dirZ, sizeX, sizeY, sizeZ, "overlapCallback")
		return
	end
	if self.state == AIFieldCourseSegmentCollisionCheckState.END_CHECK or self.state == AIFieldCourseSegmentCollisionCheckState.END_ADJUSTMENT then
		local x1 = nil
		local z1 = nil
		local x2 = nil
		local z2 = nil
		local dirX = nil
		local dirZ = nil
		if 0 < direction then
			x1 = segment.positions[numPositions][1]
			z1 = segment.positions[numPositions][2]
			x2 = segment.positions[numPositions - 1][1]
			z2 = segment.positions[numPositions - 1][2]
			dirX, dirZ = MathUtil.vector2Normalize(x2 - x1, z2 - z1)
		else
			x1 = segment.positions[1][1]
			z1 = segment.positions[1][2]
			x2 = segment.positions[2][1]
			z2 = segment.positions[2][2]
			dirX, dirZ = MathUtil.vector2Normalize(x2 - x1, z2 - z1)
		end
		if self.state == AIFieldCourseSegmentCollisionCheckState.END_ADJUSTMENT then
			self.endAdjustmentDistance = self.endAdjustmentDistance + 1
			if agentLength < self.endAdjustmentDistance or self.segmentLength - self.startAdjustmentDistance <= self.endAdjustmentDistance + 2 then
				self.state = AIFieldCourseSegmentCollisionCheckState.FINISHED
				self:next()
				return
			end
			frontOffset = frontOffset - self.endAdjustmentDistance
		end
		local bx = x1 - dirX * (frontOffset - agentLength * 0.5)
		local bz = z1 - dirZ * (frontOffset - agentLength * 0.5)
		local sizeX = self.fieldCourseSettings.implementWidth + 0.5
		local sizeY = self.fieldCourseSettings.agentHeight + 0.5
		local sizeZ = agentLength
		if segment.sideOffset ~= nil and segment.sideOffset ~= 0 then
			bx = bx - dirZ * segment.sideOffset
			bz = bz + dirX * segment.sideOffset
		end
		self:overlapCheck(bx, bz, dirX, dirZ, sizeX, sizeY, sizeZ, "overlapCallback")
		return
	end
	if self.state == AIFieldCourseSegmentCollisionCheckState.FINISHED then
		if self.startAdjustmentDistance ~= 0 then
			FieldCourseUtil.extendSegment(segment.positions, -direction, -self.startAdjustmentDistance)
		end
		if self.endAdjustmentDistance ~= 0 then
			FieldCourseUtil.extendSegment(segment.positions, direction, -self.endAdjustmentDistance)
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
function AIFieldCourseSegmentCollisionCheck:overlapCheck(x, z, dirX, dirZ, sizeX, sizeY, sizeZ, callbackName, debugBoxName)
	local ry = MathUtil.getYRotationFromDirection(dirX, dirZ)
	local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z) + sizeY * 0.5
	sizeX = sizeX * 0.5
	sizeY = sizeY * 0.5
	sizeZ = sizeZ * 0.5
	local p1x = x + dirX * sizeZ + dirZ * sizeX
	local p1z = z + dirZ * sizeZ - dirX * sizeX
	local p2x = x + dirX * sizeZ - dirZ * sizeX
	local p2z = z + dirZ * sizeZ + dirX * sizeX
	if FieldCourseUtil.getIsSegmentInsideBoundary(p1x, p1z, p2x, p2z, self.fieldBoundaryLine) then
		local p3x = x - dirX * sizeZ + dirZ * sizeX
		local p3z = z - dirZ * sizeZ - dirX * sizeX
		local p4x = x - dirX * sizeZ - dirZ * sizeX
		local p4z = z - dirZ * sizeZ + dirX * sizeX
		if FieldCourseUtil.getIsSegmentInsideBoundary(p3x, p3z, p4x, p4z, self.fieldBoundaryLine) and (FieldCourseUtil.getIsSegmentInsideBoundary(p1x, p1z, p3x, p3z, self.fieldBoundaryLine) and FieldCourseUtil.getIsSegmentInsideBoundary(p2x, p2z, p4x, p4z, self.fieldBoundaryLine)) then
			self:overlapCallback(0, -1, true)
			return
		end
	end
	overlapBoxAsync(x, y, z, 0, ry, 0, sizeX, sizeY, sizeZ, callbackName, self, CollisionFlag.AI_BLOCKING, false, false, true, true)
end
function AIFieldCourseSegmentCollisionCheck:overlapCallback(nodeId, subShapeIndex, isLast)
	if g_currentMission == nil then
		return
	else
		if self.state == AIFieldCourseSegmentCollisionCheckState.START_CHECK then
			if nodeId ~= 0 then
				self.state = AIFieldCourseSegmentCollisionCheckState.START_ADJUSTMENT
			else
				self.state = AIFieldCourseSegmentCollisionCheckState.END_CHECK
			end
		elseif self.state == AIFieldCourseSegmentCollisionCheckState.START_ADJUSTMENT then
			if nodeId == 0 then
				self.state = AIFieldCourseSegmentCollisionCheckState.END_CHECK
			end
		elseif self.state == AIFieldCourseSegmentCollisionCheckState.END_CHECK then
			if nodeId ~= 0 then
				self.state = AIFieldCourseSegmentCollisionCheckState.END_ADJUSTMENT
			else
				self.state = AIFieldCourseSegmentCollisionCheckState.FINISHED
			end
		elseif self.state == AIFieldCourseSegmentCollisionCheckState.END_ADJUSTMENT then
			if nodeId == 0 then
				self.state = AIFieldCourseSegmentCollisionCheckState.FINISHED
			end
		end
		self:next()
		return false
	end
end
function AIFieldCourseSegmentCollisionCheck:doCallback()
	if self.callbackTarget ~= nil then
		self.callbackFunc(self.callbackTarget, self.segment)
	else
		self.callbackFunc(self.segment)
	end
end
