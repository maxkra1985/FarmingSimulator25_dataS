AIFieldCourseTurnCollisionCheck = {}
local AIFieldCourseTurnCollisionCheck_mt = Class(AIFieldCourseTurnCollisionCheck)
function AIFieldCourseTurnCollisionCheck.new(turn, fieldCourseSettings, callbackFunc, callbackTarget)
	local self = setmetatable({}, AIFieldCourseTurnCollisionCheck_mt)
	self.turn = turn
	self.fieldCourseSettings = fieldCourseSettings
	self.callbackFunc = callbackFunc
	self.callbackTarget = callbackTarget
	self.stepLength = (self.fieldCourseSettings.agentFrontOffset + self.fieldCourseSettings.agentBackOffset) * 0.5
	self.segmentIndex = 1
	self.segmentPosition = 0
	self.x = 0
	self.z = 0
	self.phi = 0
	self.lastWx = turn.turnData.sx - turn.turnData.sDirX
	self.lastWz = turn.turnData.sz - turn.turnData.sDirZ
	g_fieldCourseManager:addUpdateable(self)
	return self
end
function AIFieldCourseTurnCollisionCheck:update(dt)
	if self.overlapInProgress then
		return
	end
	local segment = self.turn.segments[self.segmentIndex]
	if segment == nil then
		self:doCallback(true)
	else
		local delta = self.stepLength / self.turn.turnData.turnRadius
		self.segmentPosition = self.segmentPosition + delta
		if segment:getLength() <= self.segmentPosition then
			self.segmentIndex = self.segmentIndex + 1
			local nextSegment = self.turn.segments[self.segmentIndex]
			delta = math.min(delta, segment:getLength() - (self.segmentPosition - delta))
			self.x, self.z, self.phi = segment:move(self.x, self.z, self.phi, delta, self.turn.turnData.turnRadius)
			if nextSegment ~= nil then
				if segment.drivingDirection == nextSegment.drivingDirection then
					delta = self.stepLength / self.turn.turnData.turnRadius - delta
					self.x, self.z, self.phi = nextSegment:move(self.x, self.z, self.phi, delta, self.turn.turnData.turnRadius)
					self.segmentPosition = self.segmentPosition - segment:getLength()
				else
					self.segmentPosition = 0
				end
			end
		else
			self.x, self.z, self.phi = segment:move(self.x, self.z, self.phi, delta, self.turn.turnData.turnRadius)
		end
		local wx = self.turn.turnData.sx + self.turn.turnData.sDirX * self.x - self.turn.turnData.sDirZ * self.z
		local wz = self.turn.turnData.sz + self.turn.turnData.sDirZ * self.x + self.turn.turnData.sDirX * self.z
		local dirX, dirZ = MathUtil.vector2Normalize(wx - self.lastWx, wz - self.lastWz)
		local centerZ = (self.fieldCourseSettings.agentFrontOffset - self.fieldCourseSettings.agentBackOffset) * 0.5
		if segment.drivingDirection < 0 then
			centerZ = -centerZ
		end
		local bx = self.lastWx + dirX * centerZ
		local bz = self.lastWz + dirZ * centerZ
		local rx = 0
		local ry = MathUtil.getYRotationFromDirection(dirX, dirZ)
		local rz = 0
		local sizeX = self.fieldCourseSettings.implementWidth + 0.5
		local sizeY = self.fieldCourseSettings.agentHeight + 0.5
		local sizeZ = self.fieldCourseSettings.agentFrontOffset + self.fieldCourseSettings.agentBackOffset
		local by = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, bx, 0, bz) + sizeY * 0.5
		overlapBoxAsync(bx, by, bz, 0, ry, 0, sizeX * 0.5, sizeY * 0.5, sizeZ * 0.5, "overlapCallback", self, CollisionFlag.AI_BLOCKING, false, false, true, true)
		self.overlapInProgress = true
		self.lastWx = wx
		self.lastWz = wz
	end
end
function AIFieldCourseTurnCollisionCheck:overlapCallback(nodeId, subShapeIndex)
	if nodeId ~= 0 then
		self:doCallback(false)
	end
	self.overlapInProgress = false
	return false
end
function AIFieldCourseTurnCollisionCheck:doCallback(success)
	g_fieldCourseManager:removeUpdateable(self)
	if self.callbackTarget ~= nil then
		self.callbackFunc(self.callbackTarget, success, self.turn)
	else
		self.callbackFunc(success, self.turn)
	end
end
