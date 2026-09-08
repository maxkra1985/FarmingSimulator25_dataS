-- Local values: AIFieldCourseTurnCollisionCheck_mt
AIFieldCourseTurnCollisionCheck = {}
local AIFieldCourseTurnCollisionCheck_mt = Class(AIFieldCourseTurnCollisionCheck)

-- Upvalues: AIFieldCourseTurnCollisionCheck_mt
-- Local values: self
function AIFieldCourseTurnCollisionCheck.new(turn, fieldCourseSettings, callbackFunc, callbackTarget)
	-- upvalues: (copy) AIFieldCourseTurnCollisionCheck_mt
	local v6_ = AIFieldCourseTurnCollisionCheck_mt
	local v7_ = setmetatable({}, v6_)
	v7_.turn = turn
	v7_.fieldCourseSettings = fieldCourseSettings
	v7_.callbackFunc = callbackFunc
	v7_.callbackTarget = callbackTarget
	v7_.stepLength = (v7_.fieldCourseSettings.agentFrontOffset + v7_.fieldCourseSettings.agentBackOffset) * 0.5
	v7_.segmentIndex = 1
	v7_.segmentPosition = 0
	v7_.x = 0
	v7_.z = 0
	v7_.phi = 0
	local v8_ = turn.turnData.sx - turn.turnData.sDirX
	local v9_ = turn.turnData.sz - turn.turnData.sDirZ
	v7_.lastWx = v8_
	v7_.lastWz = v9_
	g_fieldCourseManager:addUpdateable(v7_)
	return v7_
end

-- Local values: segment, delta, nextSegment, wx, wz, dirX, dirZ, centerZ, bx, bz, rx, ry, rz, sizeX, sizeY, sizeZ, by
function AIFieldCourseTurnCollisionCheck:update(dt)
	if self.overlapInProgress then
		return
	else
		local v11_ = self.turn.segments[self.segmentIndex]
		if v11_ == nil then
			self:doCallback(true)
		else
			local v12_ = self.stepLength / self.turn.turnData.turnRadius
			self.segmentPosition = self.segmentPosition + v12_
			if self.segmentPosition >= v11_:getLength() then
				self.segmentIndex = self.segmentIndex + 1
				local v13_ = self.turn.segments[self.segmentIndex]
				local v14_ = v11_:getLength() - (self.segmentPosition - v12_)
				local v15_ = math.min(v12_, v14_)
				local v16_, v17_, v18_ = v11_:move(self.x, self.z, self.phi, v15_, self.turn.turnData.turnRadius)
				self.x = v16_
				self.z = v17_
				self.phi = v18_
				if v13_ == nil or v11_.drivingDirection ~= v13_.drivingDirection then
					self.segmentPosition = 0
				else
					local v19_ = self.stepLength / self.turn.turnData.turnRadius - v15_
					local v20_, v21_, v22_ = v13_:move(self.x, self.z, self.phi, v19_, self.turn.turnData.turnRadius)
					self.x = v20_
					self.z = v21_
					self.phi = v22_
					self.segmentPosition = self.segmentPosition - v11_:getLength()
				end
			else
				local v23_, v24_, v25_ = v11_:move(self.x, self.z, self.phi, v12_, self.turn.turnData.turnRadius)
				self.x = v23_
				self.z = v24_
				self.phi = v25_
			end
			local v26_ = self.turn.turnData.sx + self.turn.turnData.sDirX * self.x - self.turn.turnData.sDirZ * self.z
			local v27_ = self.turn.turnData.sz + self.turn.turnData.sDirZ * self.x + self.turn.turnData.sDirX * self.z
			local v28_, v29_ = MathUtil.vector2Normalize(v26_ - self.lastWx, v27_ - self.lastWz)
			local v30_ = (self.fieldCourseSettings.agentFrontOffset - self.fieldCourseSettings.agentBackOffset) * 0.5
			if v11_.drivingDirection < 0 then
				v30_ = -v30_
			end
			local v31_ = self.lastWx + v28_ * v30_
			local v32_ = self.lastWz + v29_ * v30_
			local v33_ = MathUtil.getYRotationFromDirection(v28_, v29_)
			local v34_ = self.fieldCourseSettings.implementWidth + 0.5
			local v35_ = self.fieldCourseSettings.agentHeight + 0.5
			local v36_ = self.fieldCourseSettings.agentFrontOffset + self.fieldCourseSettings.agentBackOffset
			local v37_ = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, v31_, 0, v32_) + v35_ * 0.5
			overlapBoxAsync(v31_, v37_, v32_, 0, v33_, 0, v34_ * 0.5, v35_ * 0.5, v36_ * 0.5, "overlapCallback", self, CollisionFlag.AI_BLOCKING, false, false, true, true)
			self.overlapInProgress = true
			self.lastWx = v26_
			self.lastWz = v27_
		end
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
	if self.callbackTarget == nil then
		self.callbackFunc(success, self.turn)
	else
		self.callbackFunc(self.callbackTarget, success, self.turn)
	end
end
