WildlifeInstanceAlligator = {}
local WildlifeInstanceAlligator_mt = Class(WildlifeInstanceAlligator, WildlifeInstance)
WildlifeInstanceAlligator.IDLE_VARIANT_PARAMETER_NAME = "idleVariant"
WildlifeInstanceAlligator.FORWARD_VELOCITY_PARAMETER_NAME = "forwardVelocity"
WildlifeInstanceAlligator.IN_WATER_PARAMETER_NAME = "inWater"
WildlifeInstanceAlligator.ATLAS_SHADER_PARAMETER_NAME = "atlasInvSizeAndOffsetUV"
WildlifeInstanceAlligator.CONDITIONAL_ANIMATION_XML_KEY = "species.alligator.conditionalAnimation"
WildlifeInstanceAlligator.WATER_RAYCAST_HEIGHT = 20
WildlifeInstanceAlligator.WATER_RAYCAST_DISTANCE = 60
WildlifeInstanceAlligator.WATER_CHECK_INTERVAL = 250
WildlifeInstanceAlligator.POSE_SMOOTHING_TIME = 200
WildlifeInstanceAlligator.VECTOR_EPSILON = 0.01
WildlifeInstanceAlligator.IDLE_SOUND_NAME = "idle"
WildlifeInstanceAlligator.FLEE_SOUND_NAME = "flee"
WildlifeInstanceAlligator.WATER_ENTRY_SOUND_NAME = "waterEntry"
WildlifeInstanceAlligator.IDLE_SOUND_INTERVAL_MIN = 4000
WildlifeInstanceAlligator.IDLE_SOUND_INTERVAL_MAX = 12000
function WildlifeInstanceAlligator.new(species, customMt)
	local self = WildlifeInstanceAlligator:superClass().new(species, customMt or WildlifeInstanceAlligator_mt)
	self.rootNode = createTransformGroup("WildlifeAlligator")
	link(getRootNode(), self.rootNode)
	setVisibility(self.rootNode, false)
	self.sounds = WildlifeInstanceSounds.new(self)
	self.idleSoundTimer = 0
	self.spawnNode = nil
	self.textureVariant = nil
	self.assetNode = nil
	self.skeletonNode = nil
	self.sharedLoadRequestId = nil
	self.isAssetLoadRequested = false
	self.conditionalAnimation = nil
	self.idleVariantParameterId = nil
	self.forwardVelocityParameterId = nil
	self.inWaterParameterId = nil
	self.state = WildlifeAlligatorState.RESTING
	self.facingX = 0
	self.facingZ = 0
	self.forwardVelocity = 0
	self.walkedDistance = 0
	self.swimmedDistance = 0
	self.targetSwimDistance = 0
	self.waterHeight = nil
	self.isInWater = false
	self.isWaterAhead = false
	self.isWaterCheckPending = false
	self.timeOfLastWaterCheck = 0
	self.foliageBendingId = nil
	self.shallowWaterObstacle = nil
	return self
end
function WildlifeInstanceAlligator:delete()
	self.isDeleted = true
	self:destroyFoliageBending()
	self:destroyShallowWaterObstacle()
	self:releaseAsset()
	self.sounds:delete()
	if self.rootNode ~= nil then
		delete(self.rootNode)
		self.rootNode = nil
	end
	WildlifeInstanceAlligator:superClass().delete(self)
end
function WildlifeInstanceAlligator:spawnAt(x, y, z)
	WildlifeInstanceAlligator:superClass().spawnAt(self, x, y, z)
	setWorldTranslation(self.rootNode, x, y, z)
	setVisibility(self.rootNode, true)
	self.state = WildlifeAlligatorState.RESTING
	self.forwardVelocity = 0
	self.walkedDistance = 0
	self.swimmedDistance = 0
	self.targetSwimDistance = MathUtil.randomFloat(self.species.swimDistanceMin, self.species.swimDistanceMax)
	self.waterHeight = nil
	self.isInWater = false
	self.isWaterAhead = false
	self.timeOfLastWaterCheck = 0
	self.hasNoEscapeDirection = nil
	self.hasFinishedFleeing = nil
	self.sounds:onInstanceSpawned(self.species)
	self:resetIdleSoundTimer()
	self:updateFacing()
	self:applyPose(nil)
	if not self.isAssetLoadRequested then
		self.isAssetLoadRequested = true
		self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.species.assetFilename, false, false, self.onAssetLoaded, self)
	end
	self:applyTextureVariant()
	self:updateAnimationParameters()
	self:createFoliageBending()
	self:createShallowWaterObstacle()
end
function WildlifeInstanceAlligator:despawn()
	setVisibility(self.rootNode, false)
	self.spawnNode = nil
	self.state = WildlifeAlligatorState.RESTING
	self.sounds:deleteCurrentSample(true)
	self:destroyFoliageBending()
	self:destroyShallowWaterObstacle()
	WildlifeInstanceAlligator:superClass().despawn(self)
end
function WildlifeInstanceAlligator:update(dt)
	WildlifeInstanceAlligator:superClass().update(self, dt)
	local state = self.state
	if state == WildlifeAlligatorState.RESTING then
		self:updateResting(dt)
	elseif state == WildlifeAlligatorState.WALKING then
		self:updateWalking(dt)
	elseif state == WildlifeAlligatorState.SWIMMING then
		self:updateSwimming(dt)
	end
	self:updateAnimationParameters()
	if self.conditionalAnimation ~= nil then
		self.conditionalAnimation:update(dt)
	end
end
function WildlifeInstanceAlligator:updateResting(dt)
	self:updateIdleSound(dt)
	if self:getCanStartFleeing() then
		self:startFleeing()
	end
end
function WildlifeInstanceAlligator:updateWalking(dt)
	local movedDistance = self:moveForward(self.species.walkSpeed, dt)
	self.walkedDistance = self.walkedDistance + movedDistance
	if self.isInWater then
		self:startSwimming()
	else
		if self:getHasCoveredWalkDistance() then
			self:stopFleeing()
		end
	end
end
function WildlifeInstanceAlligator:updateSwimming(dt)
	local movedDistance = self:moveForward(self:getSwimSpeed(), dt)
	self.swimmedDistance = self.swimmedDistance + movedDistance
	if not self.isWaterAhead then
		self:stopFleeing()
	else
		if self.targetSwimDistance <= self.swimmedDistance then
			self:stopFleeing()
		end
	end
end
function WildlifeInstanceAlligator:updateIdleSound(dt)
	self.idleSoundTimer = self.idleSoundTimer - dt
	if 0 < self.idleSoundTimer then
		return
	else
		self:resetIdleSoundTimer()
		self.sounds:playSound(WildlifeInstanceAlligator.IDLE_SOUND_NAME)
	end
end
function WildlifeInstanceAlligator:resetIdleSoundTimer()
	self.idleSoundTimer = MathUtil.randomFloat(WildlifeInstanceAlligator.IDLE_SOUND_INTERVAL_MIN, WildlifeInstanceAlligator.IDLE_SOUND_INTERVAL_MAX)
end
function WildlifeInstanceAlligator:getHasCoveredWalkDistance()
	return self.species.maxWalkDistance <= self.walkedDistance
end
function WildlifeInstanceAlligator:getSwimSpeed()
	local species = self.species
	if self.swimmedDistance < species.fastSwimDistance then
		return species.fastSwimSpeed
	else
		return species.swimSpeed
	end
end
function WildlifeInstanceAlligator:moveForward(speed, dt)
	local movedDistance = speed * dt * 0.001
	self.forwardVelocity = speed
	local x, y, z = getWorldTranslation(self.rootNode)
	local newX = x + self.facingX * movedDistance
	local newZ = z + self.facingZ * movedDistance
	setWorldTranslation(self.rootNode, newX, y, newZ)
	self:applyPose(dt)
	self:updateWaterCheck(newX, newZ)
	return movedDistance
end
function WildlifeInstanceAlligator:applyPose(dt)
	local x, currentY, z = getWorldTranslation(self.rootNode)
	local targetY, targetUpX, targetUpY, targetUpZ = self:getPoseTarget(x, z)
	local y = targetY
	local upX = targetUpX
	local upY = targetUpY
	local upZ = targetUpZ
	if dt ~= nil then
		local alpha = math.min(dt / WildlifeInstanceAlligator.POSE_SMOOTHING_TIME, 1)
		local currentUpX, currentUpY, currentUpZ = localDirectionToWorld(self.rootNode, 0, 1, 0)
		y = MathUtil.lerp(currentY, targetY, alpha)
		upX = MathUtil.lerp(currentUpX, targetUpX, alpha)
		upY = MathUtil.lerp(currentUpY, targetUpY, alpha)
		upZ = MathUtil.lerp(currentUpZ, targetUpZ, alpha)
		upX, upY, upZ = MathUtil.vector3Normalize(upX, upY, upZ)
	end
	local facingDotUp = MathUtil.dotProduct(self.facingX, 0, self.facingZ, upX, upY, upZ)
	local forwardX = self.facingX - upX * facingDotUp
	local forwardY = -upY * facingDotUp
	local forwardZ = self.facingZ - upZ * facingDotUp
	setWorldTranslation(self.rootNode, x, y, z)
	I3DUtil.setWorldDirection(self.rootNode, forwardX, forwardY, forwardZ, upX, upY, upZ)
end
function WildlifeInstanceAlligator:getPoseTarget(x, z)
	local groundY, upX, upY, upZ = self:getTerrainPlane(x, z)
	if self.isInWater and self.waterHeight ~= nil then
		local floatY = self.waterHeight + self.species.inWaterYOffset
		if groundY < floatY then
			return floatY, 0, 1, 0
		end
	end
	return groundY, upX, upY, upZ
end
function WildlifeInstanceAlligator:getTerrainPlane(x, z)
	local species = self.species
	local lateralX = self.facingZ
	local lateralZ = -self.facingX
	local frontX = x + self.facingX * species.frontOffset
	local frontZ = z + self.facingZ * species.frontOffset
	local rearX = x + self.facingX * species.backOffset
	local rearZ = z + self.facingZ * species.backOffset
	local rearLeftX = rearX - lateralX * species.sideOffset
	local rearLeftZ = rearZ - lateralZ * species.sideOffset
	local rearRightX = rearX + lateralX * species.sideOffset
	local rearRightZ = rearZ + lateralZ * species.sideOffset
	local frontY = getTerrainHeightAtWorldPos(g_terrainNode, frontX, 0, frontZ)
	local rearLeftY = getTerrainHeightAtWorldPos(g_terrainNode, rearLeftX, 0, rearLeftZ)
	local rearRightY = getTerrainHeightAtWorldPos(g_terrainNode, rearRightX, 0, rearRightZ)
	local longitudinalX = frontX - rearX
	local longitudinalY = frontY - (rearLeftY + rearRightY) * 0.5
	local longitudinalZ = frontZ - rearZ
	local lateralWidthX = rearRightX - rearLeftX
	local lateralWidthY = rearRightY - rearLeftY
	local lateralWidthZ = rearRightZ - rearLeftZ
	local upX, upY, upZ = MathUtil.crossProduct(longitudinalX, longitudinalY, longitudinalZ, lateralWidthX, lateralWidthY, lateralWidthZ)
	local upLength = MathUtil.vector3Length(upX, upY, upZ)
	if upLength < WildlifeInstanceAlligator.VECTOR_EPSILON then
		local terrainY = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
		return terrainY + species.groundYOffset, 0, 1, 0
	else
		upX, upY, upZ = MathUtil.vector3Normalize(upX, upY, upZ)
		if upY < 0 then
			upX = -upX
			upY = -upY
			upZ = -upZ
		end
		local planeY = frontY - (upX * (x - frontX) + upZ * (z - frontZ)) / math.max(upY, WildlifeInstanceAlligator.VECTOR_EPSILON)
		return planeY + species.groundYOffset, upX, upY, upZ
	end
end
function WildlifeInstanceAlligator:getWaterProbeDistance()
	local species = self.species
	if self.state == WildlifeAlligatorState.SWIMMING then
		return species.frontOffset + species.bankClearance
	else
		return species.frontOffset
	end
end
function WildlifeInstanceAlligator:updateWaterCheck(x, z)
	if self.isWaterCheckPending then
		return
	end
	local timeSinceLastWaterCheck = g_time - self.timeOfLastWaterCheck
	if timeSinceLastWaterCheck < WildlifeInstanceAlligator.WATER_CHECK_INTERVAL then
		return
	else
		self.isWaterCheckPending = true
		self.timeOfLastWaterCheck = g_time
		local probeDistance = self:getWaterProbeDistance()
		local sampleX = x + self.facingX * probeDistance
		local sampleZ = z + self.facingZ * probeDistance
		local startY = getTerrainHeightAtWorldPos(g_terrainNode, sampleX, 0, sampleZ) + WildlifeInstanceAlligator.WATER_RAYCAST_HEIGHT
		raycastClosestAsync(sampleX, startY, sampleZ, 0, -1, 0, WildlifeInstanceAlligator.WATER_RAYCAST_DISTANCE, "onWaterRaycastCallback", self, CollisionFlag.WATER)
	end
end
function WildlifeInstanceAlligator:onWaterRaycastCallback(hitObjectId, x, y, z, distance)
	self.isWaterCheckPending = false
	if hitObjectId == nil or hitObjectId == 0 then
		self:setIsWaterAhead(false, nil)
		return false
	end
	local terrainHeight = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
	local waterDepth = math.max(y - terrainHeight, 0)
	self:setIsWaterAhead(self.species.wadeDepth < waterDepth, y)
	return false
end
function WildlifeInstanceAlligator:setIsWaterAhead(isWaterAhead, waterY)
	self.isWaterAhead = isWaterAhead
	if self.isInWater then
		return
	else
		self.isInWater = isWaterAhead
		self.waterHeight = waterY
	end
end
function WildlifeInstanceAlligator:drawDebug()
	if self.spawnNode == nil then
		return
	else
		local stateName = WildlifeAlligatorState.getName(self.state)
		local text = string.format("%s\nnode:%s\nstate:%s speed:%.2f water:%s ahead:%s", self.species.name, getName(self.spawnNode), stateName, self.forwardVelocity, tostring(self.isInWater), tostring(self.isWaterAhead))
		DebugText.renderAtNode(self.rootNode, text, DebugUtil.getDebugColor(self.spawnNode), 0.015)
	end
end
function WildlifeInstanceAlligator:calculateDistanceFrom(positionX, positionZ)
	if self.spawnNode == nil then
		return math.huge
	else
		local instanceX, _, instanceZ = getWorldTranslation(self.rootNode)
		return MathUtil.vector2Length(positionX - instanceX, positionZ - instanceZ)
	end
end
function WildlifeInstanceAlligator:setSpawnNode(spawnNode)
	self.spawnNode = spawnNode
end
function WildlifeInstanceAlligator:getCanStartFleeing()
	local fleeDistance = self.species.fleeDistance
	if g_localPlayer == nil or fleeDistance == nil or self.hasNoEscapeDirection then
		return false
	end
	if self.hasFinishedFleeing then
		return false
	else
		local playerX, playerZ = g_localPlayer:getMapPositionAndLookYaw()
		return self:calculateDistanceFrom(playerX, playerZ) <= fleeDistance
	end
end
function WildlifeInstanceAlligator:updateFacing()
	if self.spawnNode == nil then
		return
	end
	local directionX, _, directionZ = localDirectionToWorld(self.spawnNode, 0, 0, 1)
	local directionLength = MathUtil.vector2Length(directionX, directionZ)
	if directionLength < WildlifeInstanceAlligator.VECTOR_EPSILON then
		Logging.warning("Wildlife spawn position '%s' has no usable facing direction", getName(self.spawnNode))
		self.hasNoEscapeDirection = true
		self.facingX = 0
		self.facingZ = 1
	else
		self.facingX = directionX / directionLength
		self.facingZ = directionZ / directionLength
	end
end
function WildlifeInstanceAlligator:startFleeing()
	self.state = WildlifeAlligatorState.WALKING
	self.sounds:playSound(WildlifeInstanceAlligator.FLEE_SOUND_NAME)
end
function WildlifeInstanceAlligator:startSwimming()
	self.state = WildlifeAlligatorState.SWIMMING
	self.sounds:playSound(WildlifeInstanceAlligator.WATER_ENTRY_SOUND_NAME)
end
function WildlifeInstanceAlligator:stopFleeing()
	self.state = WildlifeAlligatorState.RESTING
	self.forwardVelocity = 0
	self.hasFinishedFleeing = true
	self:applyPose(nil)
end
function WildlifeInstanceAlligator:updateAnimationParameters()
	if self.conditionalAnimation == nil then
		return
	else
		self.conditionalAnimation:setParameter(self.forwardVelocityParameterId, self.forwardVelocity)
		self.conditionalAnimation:setParameter(self.inWaterParameterId, self.isInWater)
	end
end
function WildlifeInstanceAlligator:setTextureVariant(textureVariant)
	self.textureVariant = textureVariant
end
function WildlifeInstanceAlligator:createFoliageBending()
	local bendingArea = self.species.foliageBendingArea
	if bendingArea == nil or self.foliageBendingId ~= nil then
		return
	end
	local mission = g_currentMission
	if mission ~= nil and mission.foliageBendingSystem ~= nil then
		self.foliageBendingId = mission.foliageBendingSystem:createRectangle(bendingArea.minX, bendingArea.maxX, bendingArea.minZ, bendingArea.maxZ, bendingArea.yOffset, self.rootNode)
	end
end
function WildlifeInstanceAlligator:destroyFoliageBending()
	if self.foliageBendingId == nil then
		return
	else
		local mission = g_currentMission
		if mission ~= nil and mission.foliageBendingSystem ~= nil then
			mission.foliageBendingSystem:destroyObject(self.foliageBendingId)
		end
		self.foliageBendingId = nil
	end
end
function WildlifeInstanceAlligator:createShallowWaterObstacle()
	local obstacleSize = self.species.shallowWaterObstacleSize
	if obstacleSize == nil or self.shallowWaterObstacle ~= nil then
		return
	end
	local mission = g_currentMission
	if mission ~= nil and mission.shallowWaterSimulation ~= nil then
		self.shallowWaterObstacle = mission.shallowWaterSimulation:addObstacle(self.rootNode, obstacleSize[1], obstacleSize[2], obstacleSize[3], WildlifeInstanceAlligator.getShallowWaterParameters, self, self.species.shallowWaterObstacleOffset, nil, ObstacleType.ELLIPSE)
	end
end
function WildlifeInstanceAlligator:destroyShallowWaterObstacle()
	if self.shallowWaterObstacle == nil then
		return
	else
		local mission = g_currentMission
		if mission ~= nil and mission.shallowWaterSimulation ~= nil then
			mission.shallowWaterSimulation:removeObstacle(self.shallowWaterObstacle)
		end
		self.shallowWaterObstacle = nil
	end
end
function WildlifeInstanceAlligator:getShallowWaterParameters()
	local velocityX = self.facingX * self.forwardVelocity
	local velocityZ = self.facingZ * self.forwardVelocity
	local rotY = MathUtil.getYRotationFromDirection(self.facingX, self.facingZ)
	return velocityX, velocityZ, rotY
end
function WildlifeInstanceAlligator:applyTextureVariant()
	local variant = self.textureVariant
	if self.assetNode ~= nil and variant ~= nil then
		I3DUtil.setShaderParameterRec(self.assetNode, WildlifeInstanceAlligator.ATLAS_SHADER_PARAMETER_NAME, variant.invSizeU, variant.invSizeV, variant.offsetU, variant.offsetV)
	end
end
function WildlifeInstanceAlligator:onAssetLoaded(node, failedReason, args)
	if self.isDeleted then
		if node ~= nil and node ~= 0 then
			delete(node)
		end
		return
	end
	if failedReason ~= LoadI3DFailedReason.NONE then
		Logging.error("Could not load wildlife asset '%s'", tostring(self.species.assetFilename))
		return
	end
	self.assetNode = node
	link(self.rootNode, node)
	self:applyTextureVariant()
	self.skeletonNode = I3DUtil.indexToObject(node, self.species.skeletonIndex)
	if self.skeletonNode == nil then
		Logging.error("Skeleton index '%s' not found in wildlife asset '%s'", self.species.skeletonIndex, tostring(self.species.assetFilename))
	else
		self:loadConditionalAnimation()
	end
end
function WildlifeInstanceAlligator:loadConditionalAnimation()
	local conditionalAnimation = ConditionalAnimation.new()
	self.idleVariantParameterId = conditionalAnimation:registerParameter(WildlifeInstanceAlligator.IDLE_VARIANT_PARAMETER_NAME, ConditionalAnimation.TYPE.FLOAT)
	self.forwardVelocityParameterId = conditionalAnimation:registerParameter(WildlifeInstanceAlligator.FORWARD_VELOCITY_PARAMETER_NAME, ConditionalAnimation.TYPE.FLOAT)
	self.inWaterParameterId = conditionalAnimation:registerParameter(WildlifeInstanceAlligator.IN_WATER_PARAMETER_NAME, ConditionalAnimation.TYPE.BOOL)
	conditionalAnimation:setSpecialParameterIds(self.forwardVelocityParameterId, 0)
	conditionalAnimation:load(self.skeletonNode, self.species.configFilename, WildlifeInstanceAlligator.CONDITIONAL_ANIMATION_XML_KEY, nil)
	self.conditionalAnimation = conditionalAnimation
	self:initIdleVariant()
end
function WildlifeInstanceAlligator:initIdleVariant()
	self.conditionalAnimation:setParameter(self.idleVariantParameterId, math.random())
end
function WildlifeInstanceAlligator:releaseAsset()
	if self.conditionalAnimation ~= nil then
		self.conditionalAnimation:delete()
		self.conditionalAnimation = nil
	end
	if self.assetNode ~= nil then
		delete(self.assetNode)
		self.assetNode = nil
	end
	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
		self.sharedLoadRequestId = nil
	end
	self.skeletonNode = nil
	self.idleVariantParameterId = nil
end
