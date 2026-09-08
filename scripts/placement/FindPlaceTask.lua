-- Local values: FindPlaceTask_mt
FindPlaceTask = {}
FindPlaceTask.SAFE_OFFSET = 0.05
FindPlaceTask.DEFAULT_COLLISION_MASK = CollisionFlag.VEHICLE + CollisionFlag.PLAYER + CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.TREE + CollisionFlag.STATIC_OBJECT + CollisionFlag.BUILDING
local FindPlaceTask_mt = Class(FindPlaceTask)

-- Upvalues: FindPlaceTask_mt
-- Local values: self
function FindPlaceTask.new(places, size, callback, callbackTarget, filterFunction, yOffset, zOffset, useTerrainHeight)
	-- upvalues: (copy) FindPlaceTask_mt
	local v10_ = FindPlaceTask_mt
	local v11_ = setmetatable({}, v10_)
	v11_.places = places
	v11_.size = size
	v11_.halfWidth = size.width / 2
	v11_.halfLength = size.length / 2
	v11_.halfHeight = size.height / 2
	v11_.callback = callback
	v11_.callbackTarget = callbackTarget
	v11_.filterFunction = filterFunction
	v11_.yOffset = yOffset
	v11_.zOffset = zOffset
	v11_.useTerrainHeight = useTerrainHeight
	v11_.curPlaceIndex = 1
	v11_.currentPlace = nil
	v11_.currentPositionOffset = 0
	v11_.spaceIsFree = false
	v11_.noMoreSpaces = false
	return v11_
end

-- Local values: isFinished, pos, x, y, z, xRot, yRot, zRot, xExtend, yExtend, zExtend
function FindPlaceTask:runStep()
	local v13_ = false
	self.spaceIsFree = false
	local v14_ = self:getNextPosition()
	if v14_ then
		local v15_ = v14_.overlapX
		local v16_ = v14_.overlapY
		local v17_ = v14_.overlapZ
		local v18_ = v14_.xRot
		local v19_ = v14_.yRot
		local v20_ = v14_.zRot
		local v21_ = self.halfWidth
		local v22_ = self.halfHeight
		local v23_ = self.halfLength
		self.spaceIsFree = true
		overlapBox(v15_, v16_, v17_, v18_, v19_, v20_, v21_, v22_, v23_, "overlapBoxCallbackFuncFindPlace", self, FindPlaceTask.DEFAULT_COLLISION_MASK, true, true, true, true)
	else
		self.noMoreSpaces = true
	end
	if self.spaceIsFree or self.noMoreSpaces then
		self.callback(self.callbackTarget, v14_)
		v13_ = true
	end
	return v13_
end

function FindPlaceTask:overlapBoxCallbackFuncFindPlace(node)
	if node ~= 0 and (node ~= g_terrainNode and not getHasTrigger(node)) then
		self.spaceIsFree = false
		return false
	end
end

function FindPlaceTask:getPlaceFulfillsSizeRequirements()
	return self.size.width <= self.currentPlace.maxWidth and (self.size.length <= self.currentPlace.maxLength and self.size.height <= self.currentPlace.maxHeight)
end

-- Local values: currentPlace, widthMax, lengthMax, neededOffset, dirX, dirY, dirZ, normX, normY, normZ, upX, upY, upZ, xOffset, yOffset, yOffsetOverlap, zOffset, xRot, yRot, zRot, location
function FindPlaceTask:getNextPosition()
	if self.currentPlace or self:nextPlace() then
		local v28_ = self.currentPlace
		local v29_, v30_ = MathUtil.vector2Rotate(self.halfLength, self.halfWidth, v28_.palletRotationOffset)
		local v31_ = math.max(v29_, v30_) + (self.safeOffset or FindPlaceTask.SAFE_OFFSET)
		if self.currentPositionOffset == 0 then
			self.currentPositionOffset = v31_
		else
			self.currentPositionOffset = self.currentPositionOffset + v31_ * 2
		end
		if self.currentPositionOffset >= v28_.width - v31_ then
			if not self:nextPlace() then
				return
			end
			v28_ = self.currentPlace
			local v32_, v33_ = MathUtil.vector2Rotate(self.halfLength, self.halfWidth, v28_.palletRotationOffset)
			self.currentPositionOffset = math.max(v32_, v33_) + (self.safeOffset or FindPlaceTask.SAFE_OFFSET)
		end
		local v34_ = v28_.dirX
		local v35_ = v28_.dirY
		local v36_ = v28_.dirZ
		local v37_ = v28_.dirPerpX
		local v38_ = v28_.dirPerpY
		local v39_ = v28_.dirPerpZ
		local v40_, v41_, v42_ = MathUtil.crossProduct(v37_, v38_, v39_, v34_, v35_, v36_)
		local v43_ = self.yOffset or 0
		local v44_ = self.halfHeight + v43_
		local v45_ = self.currentPositionOffset
		local v46_, v47_, v48_ = localRotationToWorld(self.currentPlace.startNode, 0, self.currentPlace.palletRotationOffset, 0)
		return {
			["x"] = self.currentPlace.startX + v37_ * 0 + v40_ * v43_ + v34_ * v45_,
			["y"] = self.currentPlace.startY + v38_ * 0 + v41_ * v43_ + v35_ * v45_,
			["z"] = self.currentPlace.startZ + v39_ * 0 + v42_ * v43_ + v36_ * v45_,
			["overlapX"] = self.currentPlace.startX + v37_ * 0 + v40_ * v44_ + v34_ * v45_,
			["overlapY"] = self.currentPlace.startY + v38_ * 0 + v41_ * v44_ + v35_ * v45_,
			["overlapZ"] = self.currentPlace.startZ + v39_ * 0 + v42_ * v44_ + v36_ * v45_,
			["xRot"] = v46_,
			["yRot"] = v47_,
			["zRot"] = v48_
		}
	end
	if PlacementManager ~= nil and PlacementManager.debugEnabled then
		Logging.devWarning("FindPlaceTask: no place available for requested size w=%.2f:, l=%.2f:, h=%.2f:", self.size.width, self.size.length, self.size.height)
	end
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
