-- Local values: Football_mt
Football = {}
Football.TYPE_SHOT = 0
Football.TYPE_PASS = 1
Football.TYPE_DRIBBLE = 2
local Football_mt = Class(Football, PhysicsObject)
InitStaticObjectClass(Football, "Football")

function Football.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Football node")
	schema:register(XMLValueType.FLOAT, basePath .. "#radius", "Football radius")
	schema:register(XMLValueType.FLOAT, basePath .. "#rollingThreshold", "Football rolling threshold")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "shot")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "pass")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "dribble")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "rolling")
end

-- Upvalues: Football_mt
-- Local values: self
function Football.new(isServer, isClient, customMt)
	-- upvalues: (copy) Football_mt
	local v7_ = PhysicsObject.new(isServer, isClient, customMt or Football_mt)
	v7_.forcedClipDistance = 200
	registerObjectClassName(v7_, "Football")
	return v7_
end

-- Local values: node, baseDirectory
function Football:load(xmlFile, key, components, i3dMappings)
	local v13_ = xmlFile:getValue(key .. "#node", nil, components, i3dMappings)
	if v13_ == nil then
		return false
	end
	self:setNodeId(v13_)
	self.radius = xmlFile:getValue(key .. "#radius", 0.16)
	self.rollingThreshold = xmlFile:getValue(key .. "#rollingThreshold", 0.05)
	local v14_ = g_currentMission.baseDirectory
	self.samples = {}
	self.samples.shot = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "shot", v14_, components, 1, AudioGroup.ENVIRONMENT, i3dMappings, self)
	self.samples.pass = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "pass", v14_, components, 1, AudioGroup.ENVIRONMENT, i3dMappings, self)
	self.samples.dribble = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "dribble", v14_, components, 1, AudioGroup.ENVIRONMENT, i3dMappings, self)
	self.samples.rolling = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "rolling", v14_, components, 0, AudioGroup.ENVIRONMENT, i3dMappings, self)
	self.lastPosX = 0
	self.lastPosY = 0
	self.lastPosZ = 0
	self.lastSpeed = 0
	return true
end

function Football:delete()
	g_soundManager:deleteSamples(self.samples)
	unregisterObjectClassName(self)
	self:removeChildrenFromNodeObject(self.nodeId)
	PhysicsObject:superClass().delete(self)
end

function Football:resetToWorldPosition(x, y, z, rx, ry, rz)
	if self.isServer then
		removeFromPhysics(self.nodeId)
		setWorldTranslation(self.nodeId, x, y, z)
		setWorldRotation(self.nodeId, rx, ry, rz)
		addToPhysics(self.nodeId)
		self.lastPosX = x
		self.lastPosY = y
		self.lastPosZ = z
	end
end

function Football:getCanBePickedUp()
	return false
end

-- Local values: x, y, z, isRolling, terrainHeight, terrainDelta, distance
function Football:update(dt)
	Football:superClass().update(self, dt)
	local v25_, v26_, v27_ = getWorldTranslation(self.nodeId)
	local v28_ = false
	if not getIsSleeping(self.nodeId) then
		local v29_ = getTerrainHeightAtWorldPos(g_terrainNode, v25_, v26_, v27_)
		local v30_ = v26_ - self.radius - v29_
		if math.abs(v30_) < self.rollingThreshold then
			self.lastSpeed = MathUtil.vector3Length(self.lastPosX - v25_, self.lastPosY - v26_, self.lastPosZ - v27_) / dt
			v28_ = self.lastSpeed > 0.0001 and true or v28_
		end
	end
	if v28_ then
		if not g_soundManager:getIsSamplePlaying(self.samples.rolling) then
			g_soundManager:playSample(self.samples.rolling)
		end
	elseif g_soundManager:getIsSamplePlaying(self.samples.rolling) then
		g_soundManager:stopSample(self.samples.rolling)
	end
	self.lastPosX = v25_
	self.lastPosY = v26_
	self.lastPosZ = v27_
end

function Football:onShot(shotType)
	if shotType == Football.TYPE_SHOT then
		g_soundManager:playSample(self.samples.shot)
		return
	elseif shotType == Football.TYPE_PASS then
		g_soundManager:playSample(self.samples.pass)
	elseif shotType == Football.TYPE_DRIBBLE then
		g_soundManager:playSample(self.samples.dribble)
	end
end

-- Local values: x, y, z, mass, dirY, impulse, impulseX, impulseY, impulseZ
function Football:shoot(dirX, dirZ, angleDeg, velocity, shotType, connection)
	self:onShot(shotType)
	if self.isServer then
		g_server:broadcastEvent(FootballShootEvent.newServerToClient(self, shotType), false, connection)
		self.canShoot = false
		local v40_, v41_, v42_ = getWorldTranslation(self.nodeId)
		local v43_ = getMass(self.nodeId)
		local v44_ = math.deg(angleDeg)
		local v45_ = math.tan(v44_)
		local v46_ = v43_ * velocity
		local v47_ = dirX * v46_
		local v48_ = v45_ * v46_
		local v49_ = dirZ * v46_
		addImpulse(self.nodeId, v47_, v48_, v49_, v40_, v41_, v42_, false)
	else
		g_client:getServerConnection():sendEvent(FootballShootEvent.new(self, dirX, dirZ, angleDeg, velocity, shotType))
	end
end

function Football:getBallSpeed()
	return self.lastSpeed * 3600
end
g_soundManager:registerModifierType("FOOTBALL_SPEED", Football.getBallSpeed)
