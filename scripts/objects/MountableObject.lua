-- Local values: MountableObject_mt
MountableObject = {}
MountableObject.MOUNT_TYPE_NONE = 0
MountableObject.MOUNT_TYPE_DEFAULT = 1
MountableObject.MOUNT_TYPE_KINEMATIC = 2
MountableObject.MOUNT_TYPE_DYNAMIC = 3
MountableObject.MOUNT_TYPE_SEND_NUM_BITS = 2
MountableObject.FORCE_LIMIT_UPDATE_TIME = 1000
MountableObject.FORCE_LIMIT_RAYCAST_DISTANCE = 20
local MountableObject_mt = Class(MountableObject, PhysicsObject)
InitStaticObjectClass(MountableObject, "MountableObject")

-- Upvalues: MountableObject_mt
-- Local values: self
function MountableObject.new(isServer, isClient, customMt)
	-- upvalues: (copy) MountableObject_mt
	local v5_ = PhysicsObject.new(isServer, isClient, customMt or MountableObject_mt)
	v5_.dynamicMountSingleAxisFreeX = false
	v5_.dynamicMountSingleAxisFreeY = false
	v5_.dynamicMountType = MountableObject.MOUNT_TYPE_NONE
	v5_.dynamicMountObjectId = nil
	v5_.forceLimitUpdate = {}
	v5_.forceLimitUpdate.raycastActive = false
	v5_.forceLimitUpdate.timer = 0
	v5_.forceLimitUpdate.lastDistance = 0
	v5_.forceLimitUpdate.nextMountingDistance = 0
	v5_.forceLimitUpdate.additionalMass = 0
	v5_.forceLimitUpdate.isAllowed = false
	v5_.supportsForkJointOffset = true
	v5_.lastMoveTime = -100000
	v5_.mountStateChangeListeners = {}
	return v5_
end

function MountableObject:delete()
	if self.dynamicMountTriggerId ~= nil then
		removeTrigger(self.dynamicMountTriggerId)
	end
	if self.dynamicMountJointIndex ~= nil then
		removeJointBreakReport(self.dynamicMountJointIndex)
		removeJoint(self.dynamicMountJointIndex)
	end
	if self.dynamicMountObject ~= nil then
		self.dynamicMountObject:removeDynamicMountedObject(self, true)
	end
	if self.mountObject ~= nil then
		if self.mountObject.removeMountedObject ~= nil then
			self.mountObject:removeMountedObject(self, true)
		end
		if self.mountObject.onUnmountObject ~= nil then
			self.mountObject:onUnmountObject(self)
		end
	end
	MountableObject:superClass().delete(self)
end

function MountableObject:getAllowsAutoDelete()
	local v8_
	if self.mountObject == nil then
		v8_ = MountableObject:superClass().getAllowsAutoDelete(self)
	else
		v8_ = false
	end
	return v8_
end

-- Local values: testScope, testScope
function MountableObject:testScope(x, y, z, coeff)
	if self.mountObject ~= nil then
		local v14_ = self.mountObject.testScope
		return v14_ == nil and true or v14_(self.mountObject, x, y, z, coeff)
	end
	if self.dynamicMountObject == nil then
		return MountableObject:superClass().testScope(self, x, y, z, coeff)
	end
	local v15_ = self.dynamicMountObject.testScope
	return v15_ == nil and true or v15_(self.dynamicMountObject, x, y, z, coeff)
end

function MountableObject:getUpdatePriority(skipCount, x, y, z, coeff, connection, isGuiVisible)
	if self.mountObject == nil then
		if self.dynamicMountObject == nil then
			return MountableObject:superClass().getUpdatePriority(self, skipCount, x, y, z, coeff, connection, isGuiVisible)
		else
			return self.dynamicMountObject:getUpdatePriority(skipCount, x, y, z, coeff, connection, isGuiVisible)
		end
	else
		return self.mountObject:getUpdatePriority(skipCount, x, y, z, coeff, connection, isGuiVisible)
	end
end

-- Local values: _, _, zOffset
function MountableObject:updateTick(dt)
	if self.isServer then
		if self:updateMove() then
			self.lastMoveTime = g_currentMission.time
		end
		if self.dynamicMountObjectTriggerCount ~= nil and self.dynamicMountObjectTriggerCount <= 0 then
			if self.dynamicMountJointNodeDynamicRefNode == nil then
				self:unmountDynamic()
				self.dynamicMountObjectTriggerCount = nil
			else
				local _, _, v26_ = localToLocal(self.dynamicMountJointNodeDynamic, self.dynamicMountJointNodeDynamicRefNode, 0, 0, 0)
				if self.dynamicMountJointNodeDynamicMountOffset < v26_ then
					self.dynamicMountJointNodeDynamicMountOffset = nil
					self.dynamicMountJointNodeDynamicRefNode = nil
					self:unmountDynamic()
					self.dynamicMountObjectTriggerCount = nil
				else
					self:raiseActive()
				end
			end
		end
		if self.dynamicMountJointIndex ~= nil and self.forceLimitUpdate.isAllowed then
			self:updateDynamicMountJointForceLimit(dt)
		end
	end
end

function MountableObject:getIsMounted()
	return self.dynamicMountType ~= MountableObject.MOUNT_TYPE_NONE
end

-- Local values: quatX, quatY, quatZ, quatW
function MountableObject:mount(object, node, x, y, z, rx, ry, rz)
	if self.dynamicMountType == MountableObject.MOUNT_TYPE_DYNAMIC then
		self:unmountDynamic()
	elseif self.dynamicMountType == MountableObject.MOUNT_TYPE_KINEMATIC then
		self:unmountKinematic()
	end
	self:unmountDynamic(true)
	if self.mountObject == nil then
		removeFromPhysics(self.nodeId)
	end
	link(node, self.nodeId)
	local v37_, v38_, v39_, v40_ = mathEulerToQuaternion(rx, ry, rz)
	self:setLocalPositionQuaternion(x, y, z, v37_, v38_, v39_, v40_, true)
	self.mountObject = object
	self:setDynamicMountType(MountableObject.MOUNT_TYPE_DEFAULT, object)
end

-- Local values: x, y, z, quatX, quatY, quatZ, quatW
function MountableObject:unmount()
	self:setDynamicMountType(MountableObject.MOUNT_TYPE_NONE)
	if self.mountObject == nil then
		return false
	end
	self.mountObject = nil
	local v42_, v43_, v44_ = getWorldTranslation(self.nodeId)
	local v45_, v46_, v47_, v48_ = getWorldQuaternion(self.nodeId)
	link(getRootNode(), self.nodeId)
	self:setWorldPositionQuaternion(v42_, v43_, v44_, v45_, v46_, v47_, v48_, true)
	addToPhysics(self.nodeId)
	return true
end

-- Local values: quatX, quatY, quatZ, quatW, i
function MountableObject:mountKinematic(object, node, x, y, z, rx, ry, rz)
	if self.dynamicMountType == MountableObject.MOUNT_TYPE_DEFAULT then
		self:unmount()
	elseif self.dynamicMountType == MountableObject.MOUNT_TYPE_DYNAMIC then
		self:unmountDynamic()
	end
	self:unmountDynamic(true)
	removeFromPhysics(self.nodeId)
	link(node, self.nodeId)
	local v58_, v59_, v60_, v61_ = mathEulerToQuaternion(rx, ry, rz)
	self:setLocalPositionQuaternion(x, y, z, v58_, v59_, v60_, v61_, true)
	addToPhysics(self.nodeId)
	if self.isServer then
		setRigidBodyType(self.nodeId, RigidBodyType.KINEMATIC)
	end
	if object.components ~= nil then
		for v62_ = 1, #object.components do
			if getRigidBodyType(object.components[v62_].node) == RigidBodyType.DYNAMIC then
				setPairCollision(object.components[v62_].node, self.nodeId, false)
			end
		end
	end
	self.mountObject = object
	self.mountJointNode = node
	self:setDynamicMountType(MountableObject.MOUNT_TYPE_KINEMATIC, object)
end

-- Local values: components, x, y, z, quatX, quatY, quatZ, quatW, i
function MountableObject:unmountKinematic()
	self:setDynamicMountType(MountableObject.MOUNT_TYPE_NONE)
	if self.mountObject == nil then
		return false
	end
	local v64_ = self.mountObject.components
	if self.mountObject.onUnmountObject ~= nil then
		self.mountObject:onUnmountObject(self)
	end
	self.mountObject = nil
	self.mountJointNode = nil
	local v65_, v66_, v67_ = getWorldTranslation(self.nodeId)
	local v68_, v69_, v70_, v71_ = getWorldQuaternion(self.nodeId)
	removeFromPhysics(self.nodeId)
	link(getRootNode(), self.nodeId)
	self:setWorldPositionQuaternion(v65_, v66_, v67_, v68_, v69_, v70_, v71_, true)
	addToPhysics(self.nodeId)
	if self.isServer then
		setRigidBodyType(self.nodeId, self:getDefaultRigidBodyType())
	end
	if v64_ ~= nil then
		for v72_ = 1, #v64_ do
			if getRigidBodyType(v64_[v72_].node) == RigidBodyType.DYNAMIC then
				setPairCollision(v64_[v72_].node, self.nodeId, true)
			end
		end
	end
	return true
end

-- Local values: x, y, z, _, _, zOffset, _
function MountableObject:mountDynamic(object, objectActorId, jointNode, mountType, forceAcceleration)
	local v79_ = self.isServer
	assert(v79_)
	if self.dynamicMountType == MountableObject.MOUNT_TYPE_DEFAULT then
		self:unmount()
	elseif self.dynamicMountType == MountableObject.MOUNT_TYPE_KINEMATIC then
		self:unmountKinematic()
	end
	if self:getSupportsMountDynamic() and self.mountObject == nil then
		if object:getOwnerFarmId() == nil or g_currentMission.accessHandler:canFarmAccess(object:getOwnerFarmId(), self) then
			if self.dynamicMountTriggerId ~= nil then
				local v80_, v81_, v82_
				if mountType == DynamicMountUtil.TYPE_FORK and self.supportsForkJointOffset then
					local _, _, v83_ = worldToLocal(jointNode, localToWorld(self.nodeId, getCenterOfMass(self.nodeId)))
					v80_, v81_, v82_ = localToLocal(jointNode, getParent(self.dynamicMountJointNodeDynamic), 0, 0, v83_)
				else
					v80_, v81_, v82_ = localToLocal(jointNode, getParent(self.dynamicMountJointNodeDynamic), 0, 0, 0)
				end
				setTranslation(self.dynamicMountJointNodeDynamic, v80_, v81_, v82_)
				setRotation(self.dynamicMountJointNodeDynamic, localRotationToLocal(jointNode, getParent(self.dynamicMountJointNodeDynamic), 0, 0, 0))
				local _, _, v84_ = localToLocal(self.dynamicMountJointNodeDynamic, jointNode, 0, 0, 0)
				self.dynamicMountJointNodeDynamicMountOffset = v84_
				self.dynamicMountJointNodeDynamicRefNode = jointNode
			end
			self.mountBaseForceAcceleration = forceAcceleration
			self.mountBaseMass = self:getMass()
			self.forceLimitUpdate.isAllowed = mountType == DynamicMountUtil.TYPE_FORK
			if DynamicMountUtil.mountDynamic(self, self.nodeId, object, objectActorId, jointNode, mountType, forceAcceleration * self.dynamicMountForceLimitScale, self.dynamicMountJointNodeDynamic) then
				self:setDynamicMountType(MountableObject.MOUNT_TYPE_DYNAMIC, object)
				return true
			else
				self.dynamicMountJointNodeDynamicRefNode = nil
				return false
			end
		else
			return false
		end
	else
		return false
	end
end

function MountableObject:unmountDynamic(isDelete)
	DynamicMountUtil.unmountDynamic(self, isDelete)
	self:setDynamicMountType(MountableObject.MOUNT_TYPE_NONE)
	if self.isServer then
		self.lastMoveTime = g_currentMission.time
	end
	self.dynamicMountJointNodeDynamicMountOffset = nil
	self.dynamicMountJointNodeDynamicRefNode = nil
end

function MountableObject:getSupportsMountDynamic()
	return true
end

function MountableObject:getAdditionalMountingDistance()
	return 0
end

-- Local values: object, i
function MountableObject:addToPhysics()
	MountableObject:superClass().addToPhysics(self)
	if self.dynamicMountType == MountableObject.MOUNT_TYPE_KINEMATIC then
		local v88_ = self.mountObject
		if v88_ ~= nil and v88_.components ~= nil then
			for v89_ = 1, #v88_.components do
				if getRigidBodyType(v88_.components[v89_].node) == RigidBodyType.DYNAMIC then
					setPairCollision(v88_.components[v89_].node, self.nodeId, false)
				end
			end
		end
	end
end

function MountableObject:removeFromPhysics()
	MountableObject:superClass().removeFromPhysics(self)
end

-- Local values: x, y, z
function MountableObject:updateDynamicMountJointForceLimit(dt)
	if not self.forceLimitUpdate.raycastActive then
		self.forceLimitUpdate.timer = self.forceLimitUpdate.timer - dt
		if self.forceLimitUpdate.timer <= 0 then
			self.forceLimitUpdate.raycastActive = true
			self.forceLimitUpdate.timer = MountableObject.FORCE_LIMIT_UPDATE_TIME
			self.forceLimitUpdate.lastDistance = 0
			self.forceLimitUpdate.lastObject = nil
			self.forceLimitUpdate.nextMountingDistance = self:getAdditionalMountingDistance()
			self.forceLimitUpdate.additionalMass = 0
			local v93_, v94_, v95_ = getWorldTranslation(self.nodeId)
			raycastAllAsync(v93_, v94_, v95_, 0, 1, 0, MountableObject.FORCE_LIMIT_RAYCAST_DISTANCE, "additionalMountingMassRaycastCallback", self, CollisionFlag.DYNAMIC_OBJECT)
		end
	end
end

function MountableObject:getAdditionalMountingMass()
	return 0
end

-- Local values: object, offset, massFactor, forceAcceleration, forceLimit
function MountableObject:additionalMountingMassRaycastCallback(hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	if g_currentMission ~= nil then
		self.forceLimitUpdate.raycastActive = false
		local v100_ = g_currentMission.nodeToObject[hitObjectId]
		if v100_ ~= self and (v100_ ~= nil and (v100_:isa(MountableObject) and (self.getAdditionalMountingDistance ~= nil and v100_ ~= self.forceLimitUpdate.lastObject))) then
			local v101_ = distance - self.forceLimitUpdate.lastDistance - self.forceLimitUpdate.nextMountingDistance
			if math.abs(v101_) < 0.25 then
				self.forceLimitUpdate.lastDistance = distance
				self.forceLimitUpdate.nextMountingDistance = self:getAdditionalMountingDistance() * 2
				self.forceLimitUpdate.additionalMass = self.forceLimitUpdate.additionalMass + v100_:getMass()
				self.forceLimitUpdate.lastObject = v100_
			end
		end
		if isLast and self.dynamicMountJointIndex ~= nil then
			local v102_ = (self.forceLimitUpdate.additionalMass + self.mountBaseMass) / self.mountBaseMass
			local v103_ = self.mountBaseForceAcceleration * v102_
			local v104_ = self.mountBaseMass * v103_
			setJointLinearDrive(self.dynamicMountJointIndex, 2, false, true, 0, 0, v104_, 0, 0)
		end
		return true
	end
end

-- Local values: triggerId, forceAcceleration, forceLimitScale, axisFreeY, axisFreeX
function MountableObject:setNodeId(nodeId)
	MountableObject:superClass().setNodeId(self, nodeId)
	if self.isServer then
		local v107_ = I3DUtil.indexToObject(nodeId, getUserAttribute(nodeId, "dynamicMountTriggerIndex"))
		if v107_ ~= nil then
			local v108_ = getUserAttribute
			local v109_ = tonumber(v108_(nodeId, "dynamicMountTriggerForceAcceleration"))
			local v110_ = getUserAttribute
			self:setMountableObjectAttributes(v107_, v109_, tonumber(v110_(nodeId, "dynamicMountForceLimitScale")), getUserAttribute(nodeId, "dynamicMountSingleAxisFreeY") == true, getUserAttribute(nodeId, "dynamicMountSingleAxisFreeX") == true)
		end
		if self.dynamicMountJointNodeDynamic == nil then
			self.dynamicMountJointNodeDynamic = createTransformGroup("dynamicMountJointNodeDynamic")
			link(self.nodeId, self.dynamicMountJointNodeDynamic)
		end
	end
end

function MountableObject:setWorldPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
	if self.isServer then
		MountableObject:superClass().setWorldPositionQuaternion(self, x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
	elseif self.dynamicMountType ~= MountableObject.MOUNT_TYPE_KINEMATIC and self.dynamicMountType ~= MountableObject.MOUNT_TYPE_DEFAULT then
		MountableObject:superClass().setWorldPositionQuaternion(self, x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
		return
	end
end

function MountableObject:setMountableObjectAttributes(triggerId, forceAcceleration, forceLimitScale, axisFreeY, axisFreeX)
	if self.isServer then
		if self.dynamicMountTriggerId == nil then
			self.dynamicMountTriggerId = triggerId
			if self.dynamicMountTriggerId ~= nil then
				addTrigger(self.dynamicMountTriggerId, "dynamicMountTriggerCallback", self)
			end
		end
		self.dynamicMountTriggerForceAcceleration = forceAcceleration or 4
		self.dynamicMountForceLimitScale = forceLimitScale or 1
		self.dynamicMountSingleAxisFreeY = axisFreeY
		self.dynamicMountSingleAxisFreeX = axisFreeX
	end
end

-- Local values: vehicle, dynamicMountAttacherNode, componentNode, dynamicMountAttacher, dynamicMountType, forceLimit
function MountableObject:dynamicMountTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	local v131_ = g_currentMission.nodeToObject[otherActorId]
	if v131_ ~= nil and v131_:isa(Vehicle) then
		local v132_ = v131_.components[1].node
		if v131_.spec_dynamicMountAttacher == nil then
			otherActorId = v132_
		else
			local v133_ = v131_.spec_dynamicMountAttacher.dynamicMountAttacherNode
			if v133_ == nil then
				otherActorId = v132_
			else
				otherActorId = v131_:getParentComponent(v133_)
				if otherActorId == 0 then
					otherActorId = v132_
				end
			end
		end
	end
	if onEnter then
		if self.mountObject == nil then
			local v134_ = DynamicMountUtil.TYPE_FORK
			local v135_, v136_
			if v131_ == nil or v131_.spec_dynamicMountAttacher == nil then
				v135_ = nil
				v136_ = 1
			else
				v135_ = v131_.spec_dynamicMountAttacher
				v134_, v136_ = v131_:getDynamicMountAttacherSettingsByNode(otherShapeId)
			end
			if v135_ ~= nil then
				if self.dynamicMountObjectActorId == nil then
					self:mountDynamic(v131_, otherActorId, v135_.dynamicMountAttacherNode, v134_, self.dynamicMountTriggerForceAcceleration * v136_)
					self.dynamicMountObjectTriggerCount = 1
					return
				end
				if otherActorId ~= self.dynamicMountObjectActorId and self.dynamicMountObjectTriggerCount == nil then
					self:unmountDynamic()
					self:mountDynamic(v131_, otherActorId, v135_.dynamicMountAttacherNode, v134_, self.dynamicMountTriggerForceAcceleration * v136_)
					self.dynamicMountObjectTriggerCount = 1
					return
				end
				if otherActorId == self.dynamicMountObjectActorId and self.dynamicMountObjectTriggerCount ~= nil then
					self.dynamicMountObjectTriggerCount = self.dynamicMountObjectTriggerCount + 1
					return
				end
			end
		end
	elseif onLeave and (otherActorId == self.dynamicMountObjectActorId and self.dynamicMountObjectTriggerCount ~= nil) then
		self.dynamicMountObjectTriggerCount = self.dynamicMountObjectTriggerCount - 1
		if self.dynamicMountObjectTriggerCount <= 0 then
			if self.dynamicMountTriggerId == nil then
				self:unmountDynamic()
				self.dynamicMountObjectTriggerCount = nil
				return
			end
			self:raiseActive()
		end
	end
end

function MountableObject:onDynamicMountJointBreak(jointIndex, breakingImpulse)
	if jointIndex == self.dynamicMountJointIndex then
		self:unmountDynamic()
	end
	return false
end

function MountableObject:getMeshNodes()
	return nil
end

-- Local values: _, listener
function MountableObject:setDynamicMountType(mountState, mountObject)
	if mountState ~= self.dynamicMountType then
		self.dynamicMountType = mountState
		if mountObject == nil then
			self.dynamicMountObjectId = nil
		else
			self.dynamicMountObjectId = NetworkUtil.getObjectId(mountObject)
		end
		for _, v142_ in ipairs(self.mountStateChangeListeners) do
			local v143_ = v142_.callbackFunc
			if type(v143_) == "string" then
				v142_.object[v142_.callbackFunc](v142_.object, self, mountState, mountObject)
			else
				local v144_ = v142_.callbackFunc
				if type(v144_) == "function" then
					v142_.callbackFunc(v142_.object, self, mountState, mountObject)
				end
			end
		end
	end
end

function MountableObject:getDynamicMountObject()
	if self.dynamicMountObjectId ~= nil then
		return NetworkUtil.getObject(self.dynamicMountObjectId)
	end
end

-- Local values: _, listener
function MountableObject:addMountStateChangeListener(object, callbackFunc)
	local v149_ = callbackFunc == nil and "onObjectMountStateChanged" or callbackFunc
	for _, v150_ in ipairs(self.mountStateChangeListeners) do
		if v150_.object == object and v150_.callbackFunc == v149_ then
			return
		end
	end
	local v151_ = self.mountStateChangeListeners
	table.insert(v151_, {
		["object"] = object,
		["callbackFunc"] = v149_
	})
end

-- Local values: indexToRemove, i, listener
function MountableObject:removeMountStateChangeListener(object, callbackFunc)
	local v155_ = callbackFunc == nil and "onObjectMountStateChanged" or callbackFunc
	local v156_ = -1
	for v157_, v158_ in ipairs(self.mountStateChangeListeners) do
		if v158_.object == object and v158_.callbackFunc == v155_ then
			v156_ = v157_
		end
	end
	if v156_ > 0 then
		table.remove(self.mountStateChangeListeners, v156_)
	end
end
