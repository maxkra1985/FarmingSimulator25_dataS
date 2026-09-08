-- Local values: DogBall_mt
DogBall = {}
DogBall.RESET_DISTANCE = 100
DogBall.RESET_DISTANCE_SQ = DogBall.RESET_DISTANCE * DogBall.RESET_DISTANCE
local DogBall_mt = Class(DogBall, PhysicsObject)
InitStaticObjectClass(DogBall, "DogBall")

-- Upvalues: DogBall_mt
-- Local values: self
function DogBall.new(isServer, isClient, customMt)
	-- upvalues: (copy) DogBall_mt
	local v5_ = PhysicsObject.new(isServer, isClient, customMt or DogBall_mt)
	v5_.forcedClipDistance = 150
	registerObjectClassName(v5_, "DogBall")
	v5_.sharedLoadRequestId = nil
	return v5_
end

function DogBall:delete()
	self.isDeleted = true
	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
	end
	unregisterObjectClassName(self)
	DogBall:superClass().delete(self)
end

-- Local values: i3dFilename, isNew
function DogBall:readStream(streamId, connection)
	if connection:getIsServer() then
		local v10_ = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
		if self.i3dFilename == nil then
			self:load(v10_, 0, 0, 0, 0, 0, 0)
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

-- Local values: dogBallRoot, sharedLoadRequestId, dogBallId
function DogBall:createNode(i3dFilename)
	self.i3dFilename = i3dFilename
	local v16_, v17_ = Utils.getModNameAndBaseDirectory(i3dFilename)
	self.customEnvironment = v16_
	self.baseDirectory = v17_
	local v18_, v19_ = g_i3DManager:loadSharedI3DFile(i3dFilename, false, false)
	self.sharedLoadRequestId = v19_
	local v20_ = getChildAt(v18_, 0)
	link(getRootNode(), v20_)
	delete(v18_)
	self:setNodeId(v20_)
end

-- Local values: _, y, _
function DogBall:setNodeId(nodeId)
	DogBall:superClass().setNodeId(self, nodeId)
	if getNumOfChildren(nodeId) == 1 then
		self.ballVisualNode = getChildAt(nodeId, 0)
		local _, v23_, _ = getTranslation(self.ballVisualNode)
		self.ballVisualOffsetY = v23_
	end
end

-- Local values: terrainY, offset, distance, collisionMask
function DogBall:getTerrainHeightWithProps(x, z)
	local v27_ = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
	local v28_ = CollisionFlag.STATIC_OBJECT + CollisionFlag.ROAD + CollisionFlag.BUILDING
	self.groundY = -1
	raycastClosest(x, v27_ + 1, z, 0, -1, 0, 5, "groundRaycastCallback", self, v28_)
	local v29_ = self.groundY
	return math.max(v27_, v29_)
end

-- Local values: objectType
function DogBall:groundRaycastCallback(hitObjectId, x, y, z, distance)
	if hitObjectId ~= nil then
		local v33_ = getRigidBodyType(hitObjectId)
		if v33_ ~= RigidBodyType.DYNAMIC and v33_ ~= RigidBodyType.KINEMATIC then
			self.groundY = y
			return false
		end
	end
	return true
end

-- Local values: x, y, z
function DogBall:update(dt)
	DogBall:superClass().update(self, dt)
	if self.isClient and self.ballVisualNode ~= nil then
		local v36_, v37_, v38_ = getWorldTranslation(self.nodeId)
		local v39_ = v37_ + self.ballVisualOffsetY
		setWorldTranslation(self.ballVisualNode, v36_, v39_, v38_)
	end
end

-- Local values: x, y, z, parentNode, distSq, distSq
function DogBall:updateTick(dt)
	if self.isServer then
		local v42_, v43_, v44_ = getWorldTranslation(self.nodeId)
		if self:getTerrainHeightWithProps(v42_, v44_) > v43_ + 1 then
			self:reset()
		end
		local v45_ = getParent(self.nodeId)
		if v45_ == 0 or v45_ ~= getRootNode() and v45_ ~= g_terrainNode then
			if MathUtil.vector3LengthSq(v42_ - self.throwPos[1], v43_ - self.throwPos[2], v44_ - self.throwPos[3]) > DogBall.RESET_DISTANCE_SQ then
				self:reset()
			end
		elseif MathUtil.vector3LengthSq(v42_ - self.spawnPos[1], v43_ - self.spawnPos[2], v44_ - self.spawnPos[3]) > DogBall.RESET_DISTANCE_SQ then
			self:reset()
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
		local v55_ = setTranslation
		local v56_ = self.nodeId
		local v57_ = self.spawnPos
		v55_(v56_, unpack(v57_))
		local v58_ = setRotation
		local v59_ = self.nodeId
		local v60_ = self.startRot
		v58_(v59_, unpack(v60_))
		addToPhysics(self.nodeId)
	end
end
