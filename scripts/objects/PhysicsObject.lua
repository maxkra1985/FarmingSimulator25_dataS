-- Local values: PhysicsObject_mt
PhysicsObject = {}
local PhysicsObject_mt = Class(PhysicsObject, Object)
InitStaticObjectClass(PhysicsObject, "PhysicsObject")

-- Upvalues: PhysicsObject_mt
-- Local values: self
function PhysicsObject.new(isServer, isClient, customMt)
	-- upvalues: (copy) PhysicsObject_mt
	local v5_ = Object.new(isServer, isClient, customMt or PhysicsObject_mt)
	v5_.nodeId = 0
	v5_.networkTimeInterpolator = InterpolationTime.new(1.2)
	v5_.forcedClipDistance = 60
	v5_.physicsObjectDirtyFlag = v5_:getNextDirtyFlag()
	v5_.isDeleted = false
	return v5_
end

function PhysicsObject:delete()
	if self.nodeId ~= 0 then
		self:removeChildrenFromNodeObject(self.nodeId)
		delete(self.nodeId)
	end
	self.nodeId = 0
	self.isDeleted = true
	PhysicsObject:superClass().delete(self)
end

function PhysicsObject:getAllowsAutoDelete()
	return true
end

function PhysicsObject:loadOnCreate(nodeId)
	self:setNodeId(nodeId)
	if not self.isServer then
		self:onGhostRemove()
	end
end

-- Local values: x, y, z, xRot, yRot, zRot, quatX, quatY, quatZ, quatW
function PhysicsObject:setNodeId(nodeId)
	self.nodeId = nodeId
	setRigidBodyType(self.nodeId, self:getDefaultRigidBodyType())
	addToPhysics(self.nodeId)
	local v11_, v12_, v13_ = getTranslation(self.nodeId)
	local v14_, v15_, v16_ = getRotation(self.nodeId)
	self.sendPosX = v11_
	self.sendPosY = v12_
	self.sendPosZ = v13_
	self.sendRotX = v14_
	self.sendRotY = v15_
	self.sendRotZ = v16_
	if not self.isServer then
		local v17_, v18_, v19_, v20_ = mathEulerToQuaternion(v14_, v15_, v16_)
		self.positionInterpolator = InterpolatorPosition.new(v11_, v12_, v13_)
		self.quaternionInterpolator = InterpolatorQuaternion.new(v17_, v18_, v19_, v20_)
	end
	self:addChildenToNodeObject(self.nodeId)
end

-- Local values: paramsXZ, paramsY, x, y, z, xRot, yRot, zRot, quatX, quatY, quatZ, quatW
function PhysicsObject:readStream(streamId, connection, objectId)
	PhysicsObject:superClass().readStream(self, streamId, connection, objectId)
	local v25_ = self.nodeId ~= 0
	assert(v25_)
	if connection:getIsServer() then
		local v26_ = g_currentMission.vehicleXZPosCompressionParams
		local v27_ = g_currentMission.vehicleYPosCompressionParams
		local v28_ = NetworkUtil.readCompressedWorldPosition(streamId, v26_)
		local v29_ = NetworkUtil.readCompressedWorldPosition(streamId, v27_)
		local v30_ = NetworkUtil.readCompressedWorldPosition(streamId, v26_)
		local v31_ = NetworkUtil.readCompressedAngle(streamId)
		local v32_ = NetworkUtil.readCompressedAngle(streamId)
		local v33_ = NetworkUtil.readCompressedAngle(streamId)
		local v34_, v35_, v36_, v37_ = mathEulerToQuaternion(v31_, v32_, v33_)
		self:setWorldPositionQuaternion(v28_, v29_, v30_, v34_, v35_, v36_, v37_, true)
		self.networkTimeInterpolator:reset()
	end
end

-- Local values: x, y, z, xRot, yRot, zRot, paramsXZ, paramsY
function PhysicsObject:writeStream(streamId, connection)
	PhysicsObject:superClass().writeStream(self, streamId, connection)
	if not connection:getIsServer() then
		local v41_, v42_, v43_ = getWorldTranslation(self.nodeId)
		local v44_, v45_, v46_ = getWorldRotation(self.nodeId)
		local v47_ = g_currentMission.vehicleXZPosCompressionParams
		local v48_ = g_currentMission.vehicleYPosCompressionParams
		NetworkUtil.writeCompressedWorldPosition(streamId, v41_, v47_)
		NetworkUtil.writeCompressedWorldPosition(streamId, v42_, v48_)
		NetworkUtil.writeCompressedWorldPosition(streamId, v43_, v47_)
		NetworkUtil.writeCompressedAngle(streamId, v44_)
		NetworkUtil.writeCompressedAngle(streamId, v45_)
		NetworkUtil.writeCompressedAngle(streamId, v46_)
	end
end

-- Local values: paramsXZ, paramsY, x, y, z, xRot, yRot, zRot, quatX, quatY, quatZ, quatW
function PhysicsObject:readUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		local v52_ = g_currentMission.vehicleXZPosCompressionParams
		local v53_ = g_currentMission.vehicleYPosCompressionParams
		local v54_ = NetworkUtil.readCompressedWorldPosition(streamId, v52_)
		local v55_ = NetworkUtil.readCompressedWorldPosition(streamId, v53_)
		local v56_ = NetworkUtil.readCompressedWorldPosition(streamId, v52_)
		local v57_ = NetworkUtil.readCompressedAngle(streamId)
		local v58_ = NetworkUtil.readCompressedAngle(streamId)
		local v59_ = NetworkUtil.readCompressedAngle(streamId)
		local v60_, v61_, v62_, v63_ = mathEulerToQuaternion(v57_, v58_, v59_)
		self.positionInterpolator:setTargetPosition(v54_, v55_, v56_)
		self.quaternionInterpolator:setTargetQuaternion(v60_, v61_, v62_, v63_)
		self.networkTimeInterpolator:startNewPhaseNetwork()
	end
end

-- Local values: paramsXZ, paramsY
function PhysicsObject:writeUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v68_ = streamWriteBool
		local v69_ = self.physicsObjectDirtyFlag
		if v68_(streamId, bit32.band(dirtyMask, v69_) ~= 0) then
			local v70_ = g_currentMission.vehicleXZPosCompressionParams
			local v71_ = g_currentMission.vehicleYPosCompressionParams
			NetworkUtil.writeCompressedWorldPosition(streamId, self.sendPosX, v70_)
			NetworkUtil.writeCompressedWorldPosition(streamId, self.sendPosY, v71_)
			NetworkUtil.writeCompressedWorldPosition(streamId, self.sendPosZ, v70_)
			NetworkUtil.writeCompressedAngle(streamId, self.sendRotX)
			NetworkUtil.writeCompressedAngle(streamId, self.sendRotY)
			NetworkUtil.writeCompressedAngle(streamId, self.sendRotZ)
		end
	end
end

-- Local values: interpolationAlpha, posX, posY, posZ, quatX, quatY, quatZ, quatW
function PhysicsObject:update(dt)
	if not self.isDeleted then
		if self.isServer then
			if not getIsSleeping(self.nodeId) then
				self:raiseActive()
			end
		else
			self.networkTimeInterpolator:update(dt)
			local v74_ = self.networkTimeInterpolator:getAlpha()
			local v75_, v76_, v77_ = self.positionInterpolator:getInterpolatedValues(v74_)
			local v78_, v79_, v80_, v81_ = self.quaternionInterpolator:getInterpolatedValues(v74_)
			self:setWorldPositionQuaternion(v75_, v76_, v77_, v78_, v79_, v80_, v81_, false)
			if self.networkTimeInterpolator:isInterpolating() then
				self:raiseActive()
				return
			end
		end
	end
end

-- Local values: x, y, z, xRot, yRot, zRot, hasMoved
function PhysicsObject:updateMove()
	local v83_, v84_, v85_ = getWorldTranslation(self.nodeId)
	local v86_, v87_, v88_ = getWorldRotation(self.nodeId)
	local v89_ = self.sendPosX - v83_
	local v90_
	if math.abs(v89_) > 0.005 then
		v90_ = true
	else
		local v91_ = self.sendPosY - v84_
		if math.abs(v91_) > 0.005 then
			v90_ = true
		else
			local v92_ = self.sendPosZ - v85_
			if math.abs(v92_) > 0.005 then
				v90_ = true
			else
				local v93_ = self.sendRotX - v86_
				if math.abs(v93_) > 0.02 then
					v90_ = true
				else
					local v94_ = self.sendRotY - v87_
					if math.abs(v94_) > 0.02 then
						v90_ = true
					else
						local v95_ = self.sendRotZ - v88_
						v90_ = math.abs(v95_) > 0.02
					end
				end
			end
		end
	end
	if v90_ then
		self:raiseDirtyFlags(self.physicsObjectDirtyFlag)
		self.sendPosX = v83_
		self.sendPosY = v84_
		self.sendPosZ = v85_
		self.sendRotX = v86_
		self.sendRotY = v87_
		self.sendRotZ = v88_
	end
	return v90_
end

function PhysicsObject:updateTick(dt)
	if self.isServer then
		self:updateMove()
	end
end

-- Local values: x1, y1, z1, dist, clipDist
function PhysicsObject:testScope(x, y, z, coeff)
	local v102_, v103_, v104_ = getWorldTranslation(self.nodeId)
	local v105_ = (v102_ - x) * (v102_ - x) + (v103_ - y) * (v103_ - y) + (v104_ - z) * (v104_ - z)
	local v106_ = getClipDistance(self.nodeId) * coeff
	local v107_ = self.forcedClipDistance
	local v108_ = math.min(v106_, v107_)
	return v105_ < v108_ * v108_
end

-- Local values: x1, y1, z1, dist, clipDist
function PhysicsObject:getUpdatePriority(skipCount, x, y, z, coeff, connection, isGuiVisible)
	local v115_, v116_, v117_ = getWorldTranslation(self.nodeId)
	local v118_ = (v115_ - x) * (v115_ - x) + (v116_ - y) * (v116_ - y) + (v117_ - z) * (v117_ - z)
	local v119_ = math.sqrt(v118_)
	local v120_ = getClipDistance(self.nodeId) * coeff
	local v121_ = self.forcedClipDistance
	return (1 - v119_ / math.min(v120_, v121_)) * 0.8 + 0.5 * skipCount * 0.2
end

function PhysicsObject:onGhostRemove()
	setVisibility(self.nodeId, false)
	removeFromPhysics(self.nodeId)
end

function PhysicsObject:onGhostAdd()
	setVisibility(self.nodeId, true)
	addToPhysics(self.nodeId)
end

function PhysicsObject:wakeUp()
	I3DUtil.wakeUpObject(self.nodeId)
end

function PhysicsObject:addToPhysics()
	addToPhysics(self.nodeId)
end

function PhysicsObject:removeFromPhysics()
	removeFromPhysics(self.nodeId)
end

function PhysicsObject:setWorldPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
	setWorldTranslation(self.nodeId, x, y, z)
	setWorldQuaternion(self.nodeId, quatX, quatY, quatZ, quatW)
	if changeInterp then
		if not self.isServer then
			self.positionInterpolator:setPosition(x, y, z)
			self.quaternionInterpolator:setQuaternion(quatX, quatY, quatZ, quatW)
			return
		end
		self:raiseDirtyFlags(self.physicsObjectDirtyFlag)
		self.sendPosX = x
		self.sendPosY = y
		self.sendPosZ = z
		local v136_, v137_, v138_ = getWorldRotation(self.nodeId)
		self.sendRotX = v136_
		self.sendRotY = v137_
		self.sendRotZ = v138_
	end
end

function PhysicsObject:setLocalPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
	setTranslation(self.nodeId, x, y, z)
	setQuaternion(self.nodeId, quatX, quatY, quatZ, quatW)
	if changeInterp then
		if not self.isServer then
			self.positionInterpolator:setPosition(getWorldTranslation(self.nodeId))
			self.quaternionInterpolator:setQuaternion(getWorldQuaternion(self.nodeId))
			return
		end
		self:raiseDirtyFlags(self.physicsObjectDirtyFlag)
		local v148_, v149_, v150_ = getWorldTranslation(self.nodeId)
		self.sendPosX = v148_
		self.sendPosY = v149_
		self.sendPosZ = v150_
		local v151_, v152_, v153_ = getWorldRotation(self.nodeId)
		self.sendRotX = v151_
		self.sendRotY = v152_
		self.sendRotZ = v153_
	end
end

function PhysicsObject:getDefaultRigidBodyType()
	if self.isServer then
		return RigidBodyType.DYNAMIC
	else
		return RigidBodyType.KINEMATIC
	end
end

-- Local values: i, rigidBodyType
function PhysicsObject:removeChildrenFromNodeObject(nodeId)
	for v157_ = 0, getNumOfChildren(nodeId) - 1 do
		self:removeChildrenFromNodeObject(getChildAt(nodeId, v157_))
	end
	if getRigidBodyType(nodeId) ~= RigidBodyType.NONE then
		g_currentMission:removeNodeObject(nodeId)
		if self.isServer then
			removeWakeUpReport(nodeId)
		end
	end
end

-- Local values: i, rigidBodyType
function PhysicsObject:addChildenToNodeObject(nodeId)
	for v160_ = 0, getNumOfChildren(nodeId) - 1 do
		self:addChildenToNodeObject(getChildAt(nodeId, v160_))
	end
	if getRigidBodyType(nodeId) ~= RigidBodyType.NONE then
		g_currentMission:addNodeObject(nodeId, self)
		if self.isServer then
			addWakeUpReport(nodeId, "onPhysicObjectWakeUpCallback", self)
		end
	end
end

function PhysicsObject:onPhysicObjectWakeUpCallback(id)
	self:raiseActive()
end
