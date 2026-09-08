-- Local values: PlayerCCT_mt
PlayerCCT = {}
local PlayerCCT_mt = Class(PlayerCCT)
PlayerCCT.DEFAULT_HEIGHT = 1.1
PlayerCCT.DEFAULT_COLLISION_GROUP = CollisionFlag.PLAYER
local v2_ = PlayerCCT
local v3_ = CollisionMask.ALL
local v4_ = CollisionFlag.WATER
local v5_ = CollisionFlag.AI_BLOCKING
local v6_ = CollisionFlag.GROUND_TIP_BLOCKING
local v7_ = CollisionFlag.PLACEMENT_BLOCKING
local v8_ = CollisionFlag.PRECIPITATION_BLOCKING
local v9_ = CollisionFlag.CAMERA_BLOCKING
local v10_ = CollisionFlag.ANIMAL_POSITIONING
local v11_ = CollisionFlag.ANIMAL_NAV_MESH_BLOCKING
local v12_ = CollisionFlag.TRAFFIC_VEHICLE_BLOCKING
local v13_ = CollisionFlag.TERRAIN_DISPLACEMENT
v2_.DEFAULT_COLLISION_MASK = v3_ - bit32.bor(v4_, v5_, v6_, v7_, v8_, v9_, v10_, v11_, v12_, v13_)
PlayerCCT.DEFAULT_MOVEMENT_COLLISION_GROUP = PlayerCCT.DEFAULT_COLLISION_GROUP
PlayerCCT.DEFAULT_MOVEMENT_COLLISION_MASK = Utils.clearFlags(PlayerCCT.DEFAULT_COLLISION_MASK, CollisionFlag.TRIGGER, CollisionFlag.FILLABLE)
function PlayerCCT.new()
	-- upvalues: (copy) PlayerCCT_mt
	local v14_ = PlayerCCT_mt
	local v15_ = setmetatable({}, v14_)
	v15_.capsuleId = nil
	v15_.height = PlayerCCT.DEFAULT_HEIGHT
	v15_.desiredHeight = v15_.height
	v15_.heightChangePhysicsIndex = nil
	v15_.radius = 0.35
	v15_.slopeLimit = 60
	v15_.stepOffset = 0.4
	v15_.mass = 0
	v15_.collisionGroup = PlayerCCT.DEFAULT_COLLISION_GROUP
	v15_.collisionMask = PlayerCCT.DEFAULT_COLLISION_MASK
	v15_.movementCollisionGroup = PlayerCCT.DEFAULT_MOVEMENT_COLLISION_GROUP
	v15_.movementCollisionMask = PlayerCCT.DEFAULT_MOVEMENT_COLLISION_MASK
	return v15_
end

function PlayerCCT:onPlayerLoad(player)
	if player ~= nil and player.toggleNoClipCommand ~= nil then
		player.toggleNoClipCommand.onEnabled:registerListener(function(p18_, p19_)
			-- upvalues: (copy) self
			local v20_ = Utils.stringToBoolean(p18_)
			local v21_ = Utils.stringToBoolean(p19_) and CollisionFlag.DEFAULT or PlayerCCT.DEFAULT_COLLISION_GROUP
			local v22_ = CollisionFlag.TRIGGER
			local v23_ = v20_ and 0 or CollisionFlag.TERRAIN
			local v24_ = bit32.bor(v22_, v23_)
			self:setMovementCollisionFilter(v21_, v24_)
			self:setKinematicCollisionFilter(v21_, v24_)
			self:rebuild()
		end)
		player.toggleNoClipCommand.onDisabled:registerListener(function()
			-- upvalues: (copy) self
			self:setMovementCollisionFilter(PlayerCCT.DEFAULT_MOVEMENT_COLLISION_GROUP, PlayerCCT.DEFAULT_MOVEMENT_COLLISION_MASK)
			self:setKinematicCollisionFilter(PlayerCCT.DEFAULT_COLLISION_GROUP, PlayerCCT.DEFAULT_COLLISION_MASK)
			self:rebuild()
		end)
	end
end

function PlayerCCT:delete()
	if self.capsuleId ~= nil then
		removeCCT(self.capsuleId)
		self.capsuleId = nil
	end
end

function PlayerCCT:getMovementCollisionFilter()
	return self.movementCollisionGroup, self.movementCollisionMask
end

function PlayerCCT:setMovementCollisionFilter(movementCollisionGroup, movementCollisionMask)
	self.movementCollisionGroup = movementCollisionGroup
	self.movementCollisionMask = movementCollisionMask
end

function PlayerCCT:getKinematicCollisionFilter()
	return self.collisionGroup, self.collisionMask
end

function PlayerCCT:setKinematicCollisionFilter(kinematicCollisionGroup, kinematicCollisionMask)
	self.collisionGroup = kinematicCollisionGroup
	self.collisionMask = kinematicCollisionMask
end

function PlayerCCT:getTotalHeight()
	return self:getHeight() + self.radius * 2
end

function PlayerCCT:getHeight()
	return self.height
end

function PlayerCCT:setHeight(height)
	if height == self.desiredHeight or height < 0 then
		return
	else
		self.desiredHeight = height
		setCCTHeight(self.capsuleId, self.desiredHeight, self.movementCollisionGroup, self.movementCollisionMask)
		if self.height < height then
			self.heightChangePhysicsIndex = getPhysicsUpdateIndex()
		else
			self.heightChangePhysicsIndex = nil
			self.height = height
		end
	end
end

function PlayerCCT:getRadius()
	return self.radius
end

function PlayerCCT:getSlopeLimit()
	return self.slopeLimit
end

function PlayerCCT:setSlopeLimit(slopeLimit)
	self.slopeLimit = slopeLimit
end

function PlayerCCT:getStepOffset()
	return self.stepOffset
end

function PlayerCCT:setStepOffset(stepOffset)
	self.stepOffset = stepOffset
end

function PlayerCCT:getMass()
	return self.mass
end

function PlayerCCT:setMass(mass)
	self.mass = mass
end

function PlayerCCT:getSkinWidth()
	return self.radius * 0.2
end

function PlayerCCT:getBottomOffsetY()
	return -self.radius
end

function PlayerCCT:setRootNode(rootNode)
	self.rootNode = rootNode
end

function PlayerCCT:rebuild()
	if self.capsuleId ~= nil then
		removeCCT(self.capsuleId)
		self.capsuleId = nil
	end
	self.capsuleId = createCCT(self.rootNode, self.radius, self.desiredHeight, self.stepOffset, self.slopeLimit, self:getSkinWidth(), self.collisionGroup, self.collisionMask, self.mass)
	self.height = self.desiredHeight
	self.heightChangePhysicsIndex = nil
end

function PlayerCCT:move(movementX, movementY, movementZ)
	moveCCT(self.capsuleId, movementX, movementY, movementZ, self.movementCollisionGroup, self.movementCollisionMask)
end

function PlayerCCT:moveExternal(movementX, movementY, movementZ)
	self:move(movementX, movementY, movementZ)
end

-- Local values: node
function PlayerCCT:getTouchingNode()
	local v62_ = self.capsuleId == nil and 0 or getCCTGroundObject(self.capsuleId)
	if v62_ == 0 or not v62_ then
		v62_ = nil
	end
	return v62_
end

-- Local values: x, y, z
function PlayerCCT:getPosition()
	local v64_, v65_, v66_ = getWorldTranslation(self.rootNode)
	return v64_, v65_ + self:getBottomOffsetY(), v66_
end

function PlayerCCT:setPosition(x, y, z, setNodeTranslation)
	if setNodeTranslation then
		setWorldTranslation(self.rootNode, x, y - self:getBottomOffsetY(), z)
	end
	setCCTPosition(self.capsuleId, x, y - self:getBottomOffsetY(), z)
end

-- Local values: _, _, isGrounded
function PlayerCCT:calculateIfBottomTouchesGround()
	local _, _, v73_ = getCCTCollisionFlags(self.capsuleId)
	return v73_
end

-- Local values: cctHeight
function PlayerCCT:update()
	if self.heightChangePhysicsIndex ~= nil and getIsPhysicsUpdateIndexSimulated(self.heightChangePhysicsIndex) then
		self.heightChangePhysicsIndex = nil
		local v75_ = getCCTHeight(self.capsuleId) - self.desiredHeight
		if math.abs(v75_) <= 0.001 then
			self.height = self.desiredHeight
			return
		end
		self.desiredHeight = self.height
	end
end

function PlayerCCT:debugDraw(x, y, textSize)
	local v80_ = DebugUtil.renderTextLine(x, y, textSize * 1.5, "CCT", nil, true)
	local v81_ = DebugUtil.renderTextLine(x, v80_, textSize, string.format("Height: %.2f", self.height))
	local v82_ = DebugUtil.renderTextLine(x, v81_, textSize, string.format("Physics height: %.2f", getCCTHeight(self.capsuleId)))
	return DebugUtil.renderTextLine(x, v82_, textSize, string.format("Desired height: %.2f", self.desiredHeight))
end
