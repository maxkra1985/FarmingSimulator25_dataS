-- Local values: WildlifeInstanceSimple_mt
WildlifeInstanceSimple = {}
local WildlifeInstanceSimple_mt = Class(WildlifeInstanceSimple, WildlifeInstance)

-- Upvalues: WildlifeInstanceSimple_mt
-- Local values: self
function WildlifeInstanceSimple.new(species, customMt)
	-- upvalues: (copy) WildlifeInstanceSimple_mt
	local v4_ = WildlifeInstance.new(species, customMt or WildlifeInstanceSimple_mt)
	v4_.mover = WildlifeInstanceMover.new(v4_)
	v4_.graphics = WildlifeInstanceGraphics.new(v4_)
	v4_.sounds = WildlifeInstanceSounds.new(v4_)
	v4_.stateMachine = WildlifeStateMachine.new(v4_)
	v4_.rootNode = createTransformGroup("WildlifeCreature")
	link(getRootNode(), v4_.rootNode)
	return v4_
end

function WildlifeInstanceSimple:delete()
	self.graphics:delete()
	self.mover:delete()
	self.sounds:delete()
	self.stateMachine:delete()
	delete(self.rootNode)
	WildlifeInstanceSimple:superClass().delete(self)
end

function WildlifeInstanceSimple:getCurrentPosition()
	return getWorldTranslation(self.rootNode)
end

-- Local values: instanceX, _, instanceZ
function WildlifeInstanceSimple:calculateDistanceFrom(positionX, positionZ)
	local v10_, _, v11_ = self:getCurrentPosition()
	return MathUtil.vector2Length(positionX - v10_, positionZ - v11_)
end

function WildlifeInstanceSimple:spawnAt(x, y, z)
	WildlifeInstanceSimple:superClass().spawnAt(self, x, y, z)
	self.mover:recalculateGroundReference(nil, x, y, z)
	setWorldTranslation(self.rootNode, x, y, z)
	self.stateMachine:onInstanceSpawned(x, y, z, self.species)
	self.graphics:onInstanceSpawned(self.species)
	self.sounds:onInstanceSpawned(self.species)
	setVisibility(self.rootNode, true)
end

function WildlifeInstanceSimple:despawn()
	setVisibility(self.rootNode, false)
	self.mover:cancelTarget()
	self.stateMachine:onInstanceDespawned()
	WildlifeInstanceSimple:superClass().despawn(self)
end

-- Local values: fleeAngle, fleeDirectionX, fleeDirectionZ
function WildlifeInstanceSimple:update(dt)
	WildlifeInstanceSimple:superClass().update(self, dt)
	self.stateMachine:update(dt)
	self.mover:update(dt)
	self.graphics:update(dt)
	if self:getCanDespawnNow() then
		local v19_ = MathUtil.randomFloat(-3.141592653589793, 3.141592653589793)
		local v20_, v21_ = MathUtil.getDirectionFromYRotation(v19_)
		self.stateMachine.states.flee:fleeInDirection(v20_, v21_)
		self.stateMachine:changeState(self.stateMachine.states.flee)
	end
end

function WildlifeInstanceSimple:getCanDespawnNow()
	local v23_ = not self.stateMachine.states.flee.fleeingToDespawn
	if v23_ then
		if self.despawnTime == nil then
			v23_ = false
		else
			v23_ = self:getSecondsSinceSpawn() >= self.despawnTime
		end
	end
	return v23_
end
