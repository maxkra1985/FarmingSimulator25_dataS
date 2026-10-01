DogBall = {}
DogBall.RESET_DISTANCE = 100
DogBall.RESET_DISTANCE_SQ = DogBall.RESET_DISTANCE * DogBall.RESET_DISTANCE
local DogBall_mt = Class(DogBall, PhysicsObject)
InitStaticObjectClass(DogBall, "DogBall")
function DogBall.new(isServer, isClient, customMt)
	local self = PhysicsObject.new(isServer, isClient, customMt or DogBall_mt)
	self.forcedClipDistance = 150
	registerObjectClassName(self, "DogBall")
	self.sharedLoadRequestId = nil
	return self
end
function DogBall:delete()
	self.isDeleted = true
	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
	end
	unregisterObjectClassName(self)
	DogBall:superClass().delete(self)
end
function DogBall:readStream(streamId, connection)
	if connection:getIsServer() then
		local i3dFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
		local isNew = self.i3dFilename == nil
		if isNew then
			self:load(i3dFilename, 0, 0, 0, 0, 0, 0)
		end
	end
	DogBall:superClass().readStream(self, streamId, connection)
end
function DogBall:writeStream(streamId, connection)
	if not connection:getIsServer() then
		streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.i3dFilename))
	end
	DogBall:superClass().writeStream(self, streamId, connection)
end
function DogBall:createNode(i3dFilename)
	self.i3dFilename = i3dFilename
	self.customEnvironment, self.baseDirectory = Utils.getModNameAndBaseDirectory(i3dFilename)
	local dogBallRoot, sharedLoadRequestId = g_i3DManager:loadSharedI3DFile(i3dFilename, false, false)
	self.sharedLoadRequestId = sharedLoadRequestId
	local dogBallId = getChildAt(dogBallRoot, 0)
	link(getRootNode(), dogBallId)
	delete(dogBallRoot)
	self:setNodeId(dogBallId)
end
function DogBall:setNodeId(nodeId)
	DogBall:superClass().setNodeId(self, nodeId)
	if getNumOfChildren(nodeId) == 1 then
		self.ballVisualNode = getChildAt(nodeId, 0)
		local _, y, _ = getTranslation(self.ballVisualNode)
		self.ballVisualOffsetY = y
	end
end
function DogBall:getTerrainHeightWithProps(x, z)
	local terrainY = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
	local offset = 1
	local distance = 5
	local collisionMask = CollisionFlag.STATIC_OBJECT + CollisionFlag.ROAD + CollisionFlag.BUILDING
	self.groundY = -1
	raycastClosest(x, terrainY + 1, z, 0, -1, 0, 5, "groundRaycastCallback", self, collisionMask)
	return math.max(terrainY, self.groundY)
end
function DogBall:groundRaycastCallback(hitObjectId, x, y, z, distance)
	if hitObjectId ~= nil then
		local objectType = getRigidBodyType(hitObjectId)
		if objectType ~= RigidBodyType.DYNAMIC and objectType ~= RigidBodyType.KINEMATIC then
			self.groundY = y
			return false
		end
	end
	return true
end
function DogBall:update(dt)
	DogBall:superClass().update(self, dt)
	if self.isClient and self.ballVisualNode ~= nil then
		local x, y, z = getWorldTranslation(self.nodeId)
		y = y + self.ballVisualOffsetY
		setWorldTranslation(self.ballVisualNode, x, y, z)
	end
end
function DogBall:updateTick(dt)
	if self.isServer then
		local x, y, z = getWorldTranslation(self.nodeId)
		if y + 1 < self:getTerrainHeightWithProps(x, z) then
			self:reset()
		end
		local parentNode = getParent(self.nodeId)
		if parentNode ~= 0 then
			if parentNode == getRootNode() or parentNode == g_terrainNode then
				local distSq = MathUtil.vector3LengthSq(x - self.spawnPos[1], y - self.spawnPos[2], z - self.spawnPos[3])
				if DogBall.RESET_DISTANCE_SQ < distSq then
					self:reset()
				end
			else
				local distSq = MathUtil.vector3LengthSq(x - self.throwPos[1], y - self.throwPos[2], z - self.throwPos[3])
				if DogBall.RESET_DISTANCE_SQ < distSq then
					self:reset()
				end
			end
		end
	end
	DogBall:superClass().updateTick(self, dt)
end
function DogBall:load(i3dFilename, x, y, z, rx, ry, rz)
	self:createNode(i3dFilename)
	setTranslation(self.nodeId, x, y, z)
	setRotation(self.nodeId, rx, ry, rz)
	if self.isServer then
		self.spawnPos = { x, y, z }
		self.throwPos = { x, y, z }
		self.startRot = { rx, ry, rz }
	end
	return true
end
function DogBall:reset()
	if self.isServer then
		removeFromPhysics(self.nodeId)
		setTranslation(self.nodeId, unpack(self.spawnPos))
		setRotation(self.nodeId, unpack(self.startRot))
		addToPhysics(self.nodeId)
	end
end
