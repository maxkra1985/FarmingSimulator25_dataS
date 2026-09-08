-- Local values: WildlifeInstanceMover_mt
WildlifeInstanceMover = {}
local WildlifeInstanceMover_mt = Class(WildlifeInstanceMover)
WildlifeInstanceMover.DEFAULT_ATTRIBUTES = {
	["canFly"] = false,
	["canSwim"] = false,
	["walkSpeed"] = 1,
	["flySpeed"] = nil,
	["climbSpeed"] = 1,
	["swimSpeed"] = nil,
	["flyHeight"] = nil,
	["canIdleInWater"] = false,
	["wadeDepth"] = 0
}
WildlifeInstanceMover.COLLISION_MASK = CollisionFlag.TERRAIN + CollisionFlag.STATIC_OBJECT + CollisionFlag.WATER
WildlifeInstanceMover.MOVEMENT_HEIGHT_CHECK_INTERVAL = 2500
WildlifeInstanceMover.USE_HEIGHT_VERTICAL_DISTANCE = 2.2
WildlifeInstanceMover.TAKEOFF_LAND_HORIZONTAL_DISTANCE = 3.5
WildlifeInstanceMover.TAKEOFF_LAND_VERTICAL_DISTANCE = 2
WildlifeInstanceMover.MINIMUM_RUBBER_BAND = 0.2
WildlifeInstanceMover.MOVEMENT_SPEED_MULTIPLIER_VARIATION = 0.1
WildlifeInstanceMover.GLIDE_DURATION_RANGE = {
	["minimum"] = 2,
	["maximum"] = 6
}
WildlifeInstanceMover.FLAP_DURATION_RANGE = {
	["minimum"] = 0.5,
	["maximum"] = 1.5
}
WildlifeInstanceMover.MINIMUM_TARGET_DISTANCE = 0.1

function WildlifeInstanceMover.registerXMLPaths(xmlSchema)
	xmlSchema:register(XMLValueType.FLOAT, "species.movement#walkSpeed", "The average movement speed of the species on foot", WildlifeInstanceMover.DEFAULT_ATTRIBUTES.walkSpeed, false)
	xmlSchema:register(XMLValueType.FLOAT, "species.movement#flySpeed", "The average movement speed of the species in the air", WildlifeInstanceMover.DEFAULT_ATTRIBUTES.flySpeed, false)
	xmlSchema:register(XMLValueType.FLOAT, "species.movement#climbSpeed", "The average movement speed of the species flying upwards", WildlifeInstanceMover.DEFAULT_ATTRIBUTES.climbSpeed, false)
	xmlSchema:register(XMLValueType.FLOAT, "species.movement#swimSpeed", "The average movement speed of the species in the water", WildlifeInstanceMover.DEFAULT_ATTRIBUTES.swimSpeed, false)
	xmlSchema:register(XMLValueType.VECTOR_2, "species.movement#flyHeight", "The range of fly heights of the species in the air", WildlifeSpecies.formatRange(WildlifeInstanceMover.DEFAULT_ATTRIBUTES.flyHeight), false)
	xmlSchema:register(XMLValueType.BOOL, "species.movement#canIdleInWater", "Is true if this species can set a movement target in a body of water; otherwise false", WildlifeInstanceMover.DEFAULT_ATTRIBUTES.canIdleInWater, false)
	xmlSchema:register(XMLValueType.FLOAT, "species.movement#wadeDepth", "How far into water the instance can walk", WildlifeInstanceMover.DEFAULT_ATTRIBUTES.wadeDepth, false)
end

-- Upvalues: WildlifeInstanceMover_mt
-- Local values: self
function WildlifeInstanceMover.new(instance)
	-- upvalues: (copy) WildlifeInstanceMover_mt
	local v4_ = WildlifeInstanceMover_mt
	local v5_ = setmetatable({}, v4_)
	v5_.instance = instance
	v5_.currentAverageSpeed = WildlifeInstanceMover.DEFAULT_ATTRIBUTES.walkSpeed
	v5_.overiddenSpeed = nil
	v5_.isSwimming = false
	v5_.desiredHeight = 0
	v5_.groundReferenceHeight = 0
	v5_.heightCheckPending = nil
	v5_.timeOfLastHeightCheck = 0
	v5_.shouldTakeOff = true
	v5_.isFlapping = false
	v5_.flapGlideTimer = 0
	v5_.startX = nil
	v5_.startY = nil
	v5_.startZ = nil
	v5_.horizontalTotalDistance = nil
	v5_.targetX = nil
	v5_.targetY = nil
	v5_.targetZ = nil
	v5_.isFlyingToTarget = false
	v5_.horizontalMovedDistance = 0
	return v5_
end

function WildlifeInstanceMover:flyOrMoveToTarget(targetX, targetY, targetZ, moveSpeed, shouldTakeOff)
	if self.instance.species.movementAttributes.canFly then
		self:flyToTarget(targetX, targetY, targetZ, moveSpeed, shouldTakeOff)
	else
		self:moveToTarget(targetX, targetY, targetZ, moveSpeed)
	end
end

function WildlifeInstanceMover:flyToTarget(targetX, targetY, targetZ, moveSpeed, shouldTakeOff)
	if not self:checkIfTargetPositionValid(targetX, targetY, targetZ) then
		return false
	end
	self.overiddenSpeed = moveSpeed
	self:randomiseCurrentSpeed()
	self.targetX = targetX
	self.targetY = targetY
	self.targetZ = targetZ
	self.isFlyingToTarget = true
	self.shouldTakeOff = (shouldTakeOff == nil or not shouldTakeOff) and true or shouldTakeOff
	self:initialiseMovement()
	self.instance.sounds:playSound("flyAway")
	return true
end

-- Local values: _, currentY
function WildlifeInstanceMover:moveToTarget(targetX, targetY, targetZ, moveSpeed)
	if not self:checkIfTargetPositionValid(targetX, targetY, targetZ) then
		return false
	end
	local _, v23_ = self.instance:getCurrentPosition()
	local v24_ = targetY - v23_
	if math.abs(v24_) >= WildlifeInstanceMover.USE_HEIGHT_VERTICAL_DISTANCE and self.instance.species.movementAttributes.canFly then
		return self:flyToTarget(targetX, targetY, targetZ, moveSpeed)
	end
	self.overiddenSpeed = moveSpeed
	self:randomiseCurrentSpeed()
	self.targetX = targetX
	self.targetY = targetY
	self.targetZ = targetZ
	self.isFlyingToTarget = false
	self:initialiseMovement()
	return true
end

function WildlifeInstanceMover:initialiseMovement()
	local v26_, v27_, v28_ = self.instance:getCurrentPosition()
	self.startX = v26_
	self.startY = v27_
	self.startZ = v28_
	self.horizontalTotalDistance = MathUtil.vector2Length(self.targetX - self.startX, self.targetZ - self.startZ)
	self.horizontalMovedDistance = 0
	self.isFlapping = false
	self.flapGlideTimer = MathUtil.randomFloat(WildlifeInstanceMover.GLIDE_DURATION_RANGE.minimum, WildlifeInstanceMover.GLIDE_DURATION_RANGE.maximum) * 1000
	self.heightCheckPending = nil
	self:randomiseDesiredHeight()
end

function WildlifeInstanceMover:getIsMoving()
	local v30_
	if self.targetX == nil or self.targetY == nil then
		v30_ = false
	else
		v30_ = self.targetZ ~= nil
	end
	return v30_
end

-- Local values: currentX, _, currentZ, distance
function WildlifeInstanceMover:checkIfTargetPositionValid(targetX, targetY, targetZ)
	local v34_, _, v35_ = self.instance:getCurrentPosition()
	return MathUtil.vector2Length(targetX - v34_, targetZ - v35_) >= WildlifeInstanceMover.MINIMUM_TARGET_DISTANCE
end

function WildlifeInstanceMover:cancelTarget()
	self.startX = nil
	self.startY = nil
	self.startZ = nil
	self.targetX = nil
	self.targetY = nil
	self.targetZ = nil
	self.horizontalTotalDistance = nil
	self.horizontalMovedDistance = 0
	self.shouldTakeOff = true
	self.isFlyingToTarget = false
	self.isFlapping = false
	self.flapGlideTimer = 0
	self.overiddenSpeed = nil
	self.heightCheckPending = nil
end

-- Local values: previousX, previousY, previousZ, interpolatedDesiredYLevel, currentX, currentY, currentZ
function WildlifeInstanceMover:update(dt)
	if self:getIsMoving() then
		local v39_, v40_, v41_ = self.instance:getCurrentPosition()
		self.horizontalMovedDistance = MathUtil.vector2Length(self.startX - v39_, self.startZ - v41_)
		self:tryRecalculateGroundReferenceAsync(v39_, v40_, v41_)
		local v42_, v43_, v44_ = self:calculateCurrentPosition(v39_, v40_, v41_, dt, (self:calculateInterpolatedDesiredYLevel(v39_, v40_, v41_, dt)))
		self:checkIfTargetReached(v42_, v43_, v44_)
		self:updateNodeTransform(v39_, v40_, v41_, v42_, v43_, v44_, dt)
	end
end

-- Local values: speciesFlyHeight, horizontalDistanceRequired, minimumFlyHeight, maximumFlyHeight
function WildlifeInstanceMover:randomiseDesiredHeight()
	if self.isFlyingToTarget then
		local v46_ = self.instance.species.movementAttributes.flyHeight
		local v47_ = v46_.maximum / self.instance.species.movementAttributes.climbSpeed * self.currentAverageSpeed
		local v48_ = v46_.minimum
		local v49_ = v46_.maximum
		if self.horizontalTotalDistance / 3 < v47_ then
			v49_ = self.horizontalTotalDistance / 3 / self.currentAverageSpeed * self.instance.species.movementAttributes.climbSpeed
			v48_ = math.min(v48_, v49_)
		end
		self.desiredHeight = MathUtil.randomFloat(v48_, v49_)
	else
		self.desiredHeight = 0
	end
end

-- Local values: randomMultiplier
function WildlifeInstanceMover:randomiseCurrentSpeed()
	self.currentAverageSpeed = self.overiddenSpeed
	if self.currentAverageSpeed == nil then
		if self.isFlyingToTarget then
			self.currentAverageSpeed = self.instance.species.movementAttributes.flySpeed
		elseif self.isSwimming and self.instance.species.movementAttributes.canSwim then
			self.currentAverageSpeed = self.instance.species.movementAttributes.swimSpeed
		else
			self.currentAverageSpeed = self.instance.species.movementAttributes.walkSpeed
		end
		local v51_ = MathUtil.randomFloat(1 - WildlifeInstanceMover.MOVEMENT_SPEED_MULTIPLIER_VARIATION, 1 + WildlifeInstanceMover.MOVEMENT_SPEED_MULTIPLIER_VARIATION)
		self.currentAverageSpeed = self.currentAverageSpeed * v51_
	end
end

-- Local values: horizontalTargetDistance, timeSinceLastHeightCheck
function WildlifeInstanceMover:tryRecalculateGroundReferenceAsync(previousX, previousY, previousZ)
	local v56_ = self.horizontalTotalDistance - self.horizontalMovedDistance
	if self.isFlyingToTarget or v56_ > 0.1 then
		local v57_ = g_time - self.timeOfLastHeightCheck
		if not self.heightCheckPending and v57_ >= WildlifeInstanceMover.MOVEMENT_HEIGHT_CHECK_INTERVAL then
			self.heightCheckPending = true
			raycastClosestAsync(previousX, previousY + 100, previousZ, 0, -1, 0, 200, "recalculateGroundReference", self, WildlifeInstanceMover.COLLISION_MASK)
		end
	else
		self.groundReferenceHeight = self.targetY
		return
	end
end

-- Local values: adjustedHeight, requiresSwimming
function WildlifeInstanceMover:recalculateGroundReference(nodeId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	if self.heightCheckPending == nil then
		return
	else
		self.heightCheckPending = nil
		local v63_, v64_ = WildlifeInstanceMover.adjustRayHitForWater(nodeId, x, y, z, self.instance.species.movementAttributes, false)
		self.isSwimming = v64_
		if v63_ ~= nil then
			self.groundReferenceHeight = v63_
			self:randomiseCurrentSpeed()
			self.timeOfLastHeightCheck = g_time
		end
	end
end

-- Local values: transformCollisionMask, isWater, terrainY, waterDepth, tooDeepToWade
function WildlifeInstanceMover.adjustRayHitForWater(transformId, hitX, hitY, hitZ, movementAttributes, willIdle)
	if transformId == nil or transformId == 0 then
		return nil, false
	else
		local v71_ = getCollisionFilterMask(transformId)
		local v72_ = CollisionFlag.WATER
		if bit32.band(v71_, v72_) ~= 0 then
			local v73_ = getTerrainHeightAtWorldPos(g_terrainNode, hitX, 0, hitZ)
			local v74_ = hitY - v73_
			local v75_ = math.max(v74_, 0) > movementAttributes.wadeDepth
			if v75_ and not movementAttributes.canSwim then
				return nil, true
			elseif v75_ then
				if willIdle and not movementAttributes.canIdleInWater then
					return nil, true
				else
					return hitY, true
				end
			else
				return v73_, false
			end
		else
			return hitY, false
		end
	end
end

-- Local values: horizontalDistanceRequired, takeoffScalar, landingScalar, newHeight
function WildlifeInstanceMover:calculateInterpolatedDesiredYLevel(previousX, previousY, previousZ)
	if self.isFlyingToTarget or self.isSwimming then
		local v77_ = self.desiredHeight / self.instance.species.movementAttributes.climbSpeed * self.currentAverageSpeed
		local v78_ = self.horizontalTotalDistance / 2
		local v79_ = math.min(v77_, v78_)
		if self.shouldTakeOff and self.horizontalMovedDistance <= v79_ then
			local v80_ = 1 - (1 - MathUtil.inverseLerp(0, v79_, self.horizontalMovedDistance)) ^ 4
			return self.targetY + self.desiredHeight * v80_
		elseif self.horizontalTotalDistance - self.horizontalMovedDistance < v79_ then
			local v81_ = (1 - MathUtil.inverseLerp(self.horizontalTotalDistance - v79_, self.horizontalTotalDistance, self.horizontalMovedDistance)) ^ 4
			local v82_ = self.desiredHeight * v81_
			local v83_ = self.groundReferenceHeight + v82_ - self.targetY
			if math.abs(v83_) <= 0.1 then
				return self.targetY
			else
				return self.targetY + v82_
			end
		else
			return self.groundReferenceHeight + self.desiredHeight
		end
	else
		return self.groundReferenceHeight
	end
end

-- Local values: horizontalMoveDelta, verticalMoveDelta, horizontalTargetDistance, verticalDesiredHeightDistance, horizontalRubberBand, verticalRubberBand, currentX, currentY, currentZ, directionX, directionZ
function WildlifeInstanceMover:calculateCurrentPosition(previousX, previousY, previousZ, dt, desiredYLevel)
	local v90_ = self.currentAverageSpeed * dt * 0.001
	local v91_ = self.instance.species.movementAttributes.climbSpeed * dt * 0.001
	local v92_ = self.horizontalTotalDistance - self.horizontalMovedDistance
	if self.isFlyingToTarget then
		local v93_ = desiredYLevel - previousY
		local v94_ = math.abs(v93_)
		local v95_ = v92_ / WildlifeInstanceMover.TAKEOFF_LAND_HORIZONTAL_DISTANCE
		local v96_ = WildlifeInstanceMover.MINIMUM_RUBBER_BAND
		local v97_ = math.clamp(v95_, v96_, 1)
		local v98_ = v94_ / WildlifeInstanceMover.TAKEOFF_LAND_VERTICAL_DISTANCE
		local v99_ = WildlifeInstanceMover.MINIMUM_RUBBER_BAND
		local v100_ = math.clamp(v98_, v99_, 1)
		v90_ = v90_ * v97_
		v91_ = v91_ * v100_
	end
	local v101_, v102_
	if v92_ <= v90_ then
		v101_ = self.targetX
		v102_ = self.targetZ
	else
		local v103_, v104_ = MathUtil.vector2Normalize(self.targetX - previousX, self.targetZ - previousZ)
		v101_ = previousX + v90_ * v103_
		v102_ = previousZ + v90_ * v104_
	end
	if v101_ == self.targetX and v102_ == self.targetZ then
		local v105_ = self.targetY - previousY
		if math.abs(v105_) >= 0.3 then
			v91_ = v91_ * MathUtil.randomFloat(1.5, 2.5)
		end
	end
	if not self.isFlyingToTarget then
		return v101_, desiredYLevel, v102_
	end
	local v106_ = desiredYLevel - previousY
	if math.abs(v106_) <= v91_ then
		return v101_, desiredYLevel, v102_
	end
	local v107_ = desiredYLevel - previousY
	return v101_, previousY + math.sign(v107_) * v91_, v102_
end

-- Local values: reachedTarget
function WildlifeInstanceMover:checkIfTargetReached(currentX, currentY, currentZ)
	local v112_
	if currentX == self.targetX and currentY == self.targetY then
		v112_ = currentZ == self.targetZ
	else
		v112_ = false
	end
	if v112_ then
		self:cancelTarget()
		self.instance.stateMachine:onMovementTargetReached()
	end
	return v112_
end

-- Local values: horizontalMovedDelta, verticalMovedDelta, movementDirectionX, movementDirectionZ
function WildlifeInstanceMover:updateNodeTransform(previousX, previousY, previousZ, currentX, currentY, currentZ, dt)
	setTranslation(self.instance.rootNode, currentX, currentY, currentZ)
	local v121_ = MathUtil.vector2Length(currentX - previousX, currentZ - previousZ)
	local v122_ = currentY - previousY
	if v121_ > 0.001 then
		local v123_ = (currentX - previousX) / v121_
		local v124_ = (currentZ - previousZ) / v121_
		setDirection(self.instance.rootNode, v123_, 0, v124_, 0, 1, 0)
	end
	self:updateAnimations(v121_, v122_, currentX, currentY, currentZ, dt)
end

-- Local values: minimumVerticalMoveDelta
function WildlifeInstanceMover:updateAnimations(horizontalMovedDelta, verticalMovedDelta, currentX, currentY, currentZ, dt)
	if self.isFlyingToTarget then
		if self.instance.species.movementAttributes.climbSpeed * WildlifeInstanceMover.MINIMUM_RUBBER_BAND * 0.7 * dt * 0.001 <= math.abs(verticalMovedDelta) then
			self:updateVerticalAnimations(verticalMovedDelta, currentX, currentY, currentZ, dt)
			return
		elseif self:checkFlapDuration(dt) then
			self.instance.graphics:transitionToAnimation("fly")
		else
			self.instance.graphics:transitionToAnimation("flyGlide")
		end
	elseif self.isSwimming and self.instance.graphics:getHasStateAnimation("swim") then
		self.instance.graphics:transitionToAnimation("swim")
	else
		self.instance.graphics:transitionToAnimation("idleWalk")
	end
end

-- Local values: horizontalTargetDistance, targetYDistance, isTakingOff, isLanding
function WildlifeInstanceMover:updateVerticalAnimations(verticalMovedDelta, currentX, currentY, currentZ, dt)
	local v137_ = self.horizontalTotalDistance - self.horizontalMovedDistance
	local v138_ = currentY - self.targetY
	local v139_ = math.abs(v138_)
	local v140_
	if self.horizontalMovedDistance <= WildlifeInstanceMover.TAKEOFF_LAND_HORIZONTAL_DISTANCE then
		v140_ = verticalMovedDelta > 0
	else
		v140_ = false
	end
	if v140_ then
		self.instance.graphics:transitionToAnimation("takeOff")
		return
	else
		local v141_
		if v137_ <= WildlifeInstanceMover.TAKEOFF_LAND_HORIZONTAL_DISTANCE and v139_ <= WildlifeInstanceMover.TAKEOFF_LAND_VERTICAL_DISTANCE then
			v141_ = verticalMovedDelta < 0
		else
			v141_ = false
		end
		if v141_ then
			self.instance.graphics:transitionToAnimation("land")
			return
		elseif verticalMovedDelta < 0 then
			if self:checkFlapDuration(dt) or currentX == self.targetX and currentZ == self.targetZ then
				self.instance.graphics:transitionToAnimation("flyDownFlapping")
			else
				self.instance.graphics:transitionToAnimation("flyDown")
			end
		else
			self.instance.graphics:transitionToAnimation("flyUp")
			return
		end
	end
end

function WildlifeInstanceMover:checkFlapDuration(dt)
	self.flapGlideTimer = self.flapGlideTimer - dt
	if self.flapGlideTimer > 0 then
		return self.isFlapping
	end
	self.isFlapping = not self.isFlapping
	if self.isFlapping then
		self.flapGlideTimer = MathUtil.randomFloat(WildlifeInstanceMover.FLAP_DURATION_RANGE.minimum, WildlifeInstanceMover.FLAP_DURATION_RANGE.maximum) * 1000
	else
		self.flapGlideTimer = MathUtil.randomFloat(WildlifeInstanceMover.GLIDE_DURATION_RANGE.minimum, WildlifeInstanceMover.GLIDE_DURATION_RANGE.maximum) * 1000
	end
	return self.isFlapping
end

-- Local values: previousX, previousY, previousZ, interpolatedYLevel
function WildlifeInstanceMover:debugDraw()
	if self:getIsMoving() then
		DebugGizmo.renderAtPosition(self.targetX, self.targetY, self.targetZ, 0, 0, 1, 0, 1, 0, "Target", false, 1, nil, Color.PRESETS.RED)
		if self.isFlyingToTarget then
			local v145_, v146_, v147_ = self.instance:getCurrentPosition()
			local v148_ = self:calculateInterpolatedDesiredYLevel(v145_, v146_, v147_)
			DebugGizmo.renderAtPosition(self.targetX, self.groundReferenceHeight + self.desiredHeight, self.targetZ, 0, 0, 1, 0, 1, 0, "Fly height", false, 1, nil, Color.PRESETS.GREEN)
			DebugGizmo.renderAtPosition(self.targetX, v148_, self.targetZ, 0, 0, 1, 0, 1, 0, "Desired height", false, 1, nil, Color.PRESETS.BLUE)
		end
	end
end

-- Local values: attributes, flyHeight
function WildlifeInstanceMover.loadAttributesTable(xmlFile)
	local v150_ = {
		["walkSpeed"] = xmlFile:getValue("species.movement#walkSpeed", WildlifeInstanceMover.DEFAULT_ATTRIBUTES.walkSpeed),
		["flySpeed"] = xmlFile:getValue("species.movement#flySpeed", WildlifeInstanceMover.DEFAULT_ATTRIBUTES.flySpeed),
		["climbSpeed"] = xmlFile:getValue("species.movement#climbSpeed", WildlifeInstanceMover.DEFAULT_ATTRIBUTES.climbSpeed),
		["swimSpeed"] = xmlFile:getValue("species.movement#swimSpeed", WildlifeInstanceMover.DEFAULT_ATTRIBUTES.swimSpeed)
	}
	v150_.canFly = v150_.flySpeed ~= nil
	v150_.canSwim = v150_.swimSpeed ~= nil
	local v151_ = xmlFile:getValue("species.movement#flyHeight", nil, true)
	if v150_.canFly and v151_ ~= nil then
		v150_.flyHeight = {
			["minimum"] = v151_[1],
			["maximum"] = v151_[2]
		}
	end
	local v152_ = v150_.canSwim
	if v152_ then
		v152_ = xmlFile:getValue("species.movement#canIdleInWater", WildlifeInstanceMover.DEFAULT_ATTRIBUTES.canIdleInWater)
	end
	v150_.canIdleInWater = v152_
	v150_.wadeDepth = xmlFile:getValue("species.movement#wadeDepth", WildlifeInstanceMover.DEFAULT_ATTRIBUTES.wadeDepth)
	return v150_
end
