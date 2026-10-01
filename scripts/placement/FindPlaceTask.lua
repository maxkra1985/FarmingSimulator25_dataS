FindPlaceTask = {}
FindPlaceTask.SAFE_OFFSET = 0.05
FindPlaceTask.DEFAULT_COLLISION_MASK = CollisionFlag.VEHICLE + CollisionFlag.PLAYER + CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.TREE + CollisionFlag.STATIC_OBJECT + CollisionFlag.BUILDING
local FindPlaceTask_mt = Class(FindPlaceTask)
function FindPlaceTask.new(places, size, callback, callbackTarget, filterFunction, yOffset, zOffset, useTerrainHeight)
	local self = setmetatable({}, FindPlaceTask_mt)
	self.places = places
	self.size = size
	self.halfWidth = size.width / 2
	self.halfLength = size.length / 2
	self.halfHeight = size.height / 2
	self.callback = callback
	self.callbackTarget = callbackTarget
	self.filterFunction = filterFunction
	self.yOffset = yOffset
	self.zOffset = zOffset
	self.useTerrainHeight = useTerrainHeight
	self.curPlaceIndex = 1
	self.currentPlace = nil
	self.currentPositionOffset = 0
	self.spaceIsFree = false
	self.noMoreSpaces = false
	return self
end
function FindPlaceTask:runStep()
	local isFinished = false
	self.spaceIsFree = false
	local pos = self:getNextPosition()
	if pos then
		local x = pos.overlapX
		local y = pos.overlapY
		local z = pos.overlapZ
		local xRot = pos.xRot
		local yRot = pos.yRot
		local zRot = pos.zRot
		local xExtend = self.halfWidth
		local yExtend = self.halfHeight
		local zExtend = self.halfLength
		self.spaceIsFree = true
		overlapBox(x, y, z, xRot, yRot, zRot, xExtend, yExtend, zExtend, "overlapBoxCallbackFuncFindPlace", self, FindPlaceTask.DEFAULT_COLLISION_MASK, true, true, true, true)
	else
		self.noMoreSpaces = true
	end
	if self.spaceIsFree or self.noMoreSpaces then
		self.callback(self.callbackTarget, pos)
		isFinished = true
	end
	return isFinished
end
function FindPlaceTask:overlapBoxCallbackFuncFindPlace(node)
	if node ~= 0 and (node ~= g_terrainNode and not getHasTrigger(node)) then
		self.spaceIsFree = false
		return false
	end
end
function FindPlaceTask:getPlaceFulfillsSizeRequirements()
	if self.currentPlace.maxWidth < self.size.width or self.currentPlace.maxLength < self.size.length or self.currentPlace.maxHeight < self.size.height then
		return false
	end
	return true
end
function FindPlaceTask:getNextPosition()
	if not self.currentPlace and not self:nextPlace() then
		if PlacementManager ~= nil and PlacementManager.debugEnabled then
			Logging.devWarning("FindPlaceTask: no place available for requested size w=%.2f:, l=%.2f:, h=%.2f:", self.size.width, self.size.length, self.size.height)
		end
		return
	end
	local currentPlace = self.currentPlace
	local widthMax, lengthMax = MathUtil.vector2Rotate(self.halfLength, self.halfWidth, currentPlace.palletRotationOffset)
	local neededOffset = math.max(widthMax, lengthMax) + (self.safeOffset or FindPlaceTask.SAFE_OFFSET)
	if self.currentPositionOffset == 0 then
		self.currentPositionOffset = neededOffset
	else
		self.currentPositionOffset = self.currentPositionOffset + neededOffset * 2
	end
	if currentPlace.width - neededOffset <= self.currentPositionOffset and self:nextPlace() then
		currentPlace = self.currentPlace
		widthMax, lengthMax = MathUtil.vector2Rotate(self.halfLength, self.halfWidth, currentPlace.palletRotationOffset)
		neededOffset = math.max(widthMax, lengthMax) + (self.safeOffset or FindPlaceTask.SAFE_OFFSET)
		self.currentPositionOffset = neededOffset
	end
	local dirX = currentPlace.dirX
	local dirY = currentPlace.dirY
	local dirZ = currentPlace.dirZ
	local normX = currentPlace.dirPerpX
	local normY = currentPlace.dirPerpY
	local normZ = currentPlace.dirPerpZ
	local upX, upY, upZ = MathUtil.crossProduct(normX, normY, normZ, dirX, dirY, dirZ)
	local xOffset = 0
	local yOffset = self.yOffset or 0
	local yOffsetOverlap = self.halfHeight + yOffset
	local zOffset = self.currentPositionOffset
	local xRot, yRot, zRot = localRotationToWorld(self.currentPlace.startNode, 0, self.currentPlace.palletRotationOffset, 0)
	local location = { xRot = xRot, yRot = yRot, zRot = zRot, x = self.currentPlace.startX + normX * 0 + upX * yOffset + dirX * zOffset, y = self.currentPlace.startY + normY * 0 + upY * yOffset + dirY * zOffset, z = self.currentPlace.startZ + normZ * 0 + upZ * yOffset + dirZ * zOffset, overlapX = self.currentPlace.startX + normX * 0 + upX * yOffsetOverlap + dirX * zOffset, overlapY = self.currentPlace.startY + normY * 0 + upY * yOffsetOverlap + dirY * zOffset, overlapZ = self.currentPlace.startZ + normZ * 0 + upZ * yOffsetOverlap + dirZ * zOffset }
	return location
end
function FindPlaceTask:nextPlace()
	self.currentPositionOffset = 0
	while true do
		self.currentPlace = self.places[self.curPlaceIndex]
		if not self.currentPlace then
			break
		end
		if self:getPlaceFulfillsSizeRequirements() then
			self.curPlaceIndex = self.curPlaceIndex + 1
			return true
		end
		self.curPlaceIndex = self.curPlaceIndex + 1
	end
	return false
end
