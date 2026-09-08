Mountable = {}
Mountable.FORCE_LIMIT_UPDATE_TIME = 1000
Mountable.FORCE_LIMIT_RAYCAST_DISTANCE = 20
source("dataS/scripts/vehicles/specializations/events/MountableSetMountTypeEvent.lua")

function Mountable.prerequisitesPresent(self)
	return true
end
function Mountable.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("Mountable")
	v1_:register(XMLValueType.FLOAT, "vehicle.dynamicMount#forceLimitScale", "Force limit scale", 1)
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.dynamicMount#triggerNode", "Trigger node")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.dynamicMount#jointNode", "Joint node")
	v1_:register(XMLValueType.FLOAT, "vehicle.dynamicMount#triggerForceAcceleration", "Trigger force acceleration", 4)
	v1_:register(XMLValueType.BOOL, "vehicle.dynamicMount#singleAxisFreeY", "Single axis free Y")
	v1_:register(XMLValueType.BOOL, "vehicle.dynamicMount#singleAxisFreeX", "Single axis free X")
	v1_:register(XMLValueType.BOOL, "vehicle.dynamicMount#allowFoldingWhileMounted", "Allow folding while vehicle is mounted", false)
	v1_:register(XMLValueType.FLOAT, "vehicle.dynamicMount#jointTransY", "Fixed Y translation of local placed joint", "not defined")
	v1_:register(XMLValueType.BOOL, "vehicle.dynamicMount#jointLimitToRotY", "Local placed joint will only be adjusted on Y axis to the target mounter object. X and Z will be 0.", false)
	v1_:register(XMLValueType.FLOAT, "vehicle.dynamicMount#additionalMountDistance", "Distance from root node to the object laying on top (normally height of object). If defined the mass of this object has influence in mounting.", 0)
	v1_:register(XMLValueType.BOOL, "vehicle.dynamicMount#allowMassReduction", "Defines if mass can be reduced by the mount vehicle", true)
	v1_:register(XMLValueType.STRING, "vehicle.dynamicMount.lockPosition(?)#xmlFilename", "XML filename of vehicle to lock on (needs to match only the end of the filename)")
	v1_:register(XMLValueType.STRING, "vehicle.dynamicMount.lockPosition(?)#jointNode", "Joint node of other vehicle (path or i3dMapping name)", "vehicle root node")
	v1_:register(XMLValueType.VECTOR_TRANS, "vehicle.dynamicMount.lockPosition(?)#transOffset", "Translation offset from joint node", "0 0 0")
	v1_:register(XMLValueType.VECTOR_ROT, "vehicle.dynamicMount.lockPosition(?)#rotOffset", "Rotation offset from joint node", "0 0 0")
	v1_:setXMLSpecializationType()
end

function Mountable.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onDynamicMountTypeChanged")
end

function Mountable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getSupportsMountDynamic", Mountable.getSupportsMountDynamic)
	SpecializationUtil.registerFunction(vehicleType, "getSupportsMountKinematic", Mountable.getSupportsMountKinematic)
	SpecializationUtil.registerFunction(vehicleType, "onDynamicMountJointBreak", Mountable.onDynamicMountJointBreak)
	SpecializationUtil.registerFunction(vehicleType, "mountableTriggerCallback", Mountable.mountableTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "mount", Mountable.mount)
	SpecializationUtil.registerFunction(vehicleType, "unmount", Mountable.unmount)
	SpecializationUtil.registerFunction(vehicleType, "mountKinematic", Mountable.mountKinematic)
	SpecializationUtil.registerFunction(vehicleType, "unmountKinematic", Mountable.unmountKinematic)
	SpecializationUtil.registerFunction(vehicleType, "mountDynamic", Mountable.mountDynamic)
	SpecializationUtil.registerFunction(vehicleType, "unmountDynamic", Mountable.unmountDynamic)
	SpecializationUtil.registerFunction(vehicleType, "getAdditionalMountingDistance", Mountable.getAdditionalMountingDistance)
	SpecializationUtil.registerFunction(vehicleType, "getAdditionalMountingMass", Mountable.getAdditionalMountingMass)
	SpecializationUtil.registerFunction(vehicleType, "updateDynamicMountJointForceLimit", Mountable.updateDynamicMountJointForceLimit)
	SpecializationUtil.registerFunction(vehicleType, "additionalMountingMassRaycastCallback", Mountable.additionalMountingMassRaycastCallback)
	SpecializationUtil.registerFunction(vehicleType, "getMountObject", Mountable.getMountObject)
	SpecializationUtil.registerFunction(vehicleType, "getDynamicMountObject", Mountable.getDynamicMountObject)
	SpecializationUtil.registerFunction(vehicleType, "setReducedComponentMass", Mountable.setReducedComponentMass)
	SpecializationUtil.registerFunction(vehicleType, "getAllowComponentMassReduction", Mountable.getAllowComponentMassReduction)
	SpecializationUtil.registerFunction(vehicleType, "getDefaultAllowComponentMassReduction", Mountable.getDefaultAllowComponentMassReduction)
	SpecializationUtil.registerFunction(vehicleType, "getMountableLockPositions", Mountable.getMountableLockPositions)
	SpecializationUtil.registerFunction(vehicleType, "setDynamicMountType", Mountable.setDynamicMountType)
	SpecializationUtil.registerFunction(vehicleType, "addMountStateChangeListener", Mountable.addMountStateChangeListener)
	SpecializationUtil.registerFunction(vehicleType, "removeMountStateChangeListener", Mountable.removeMountStateChangeListener)
end

function Mountable.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsActive", Mountable.getIsActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getOwnerConnection", Mountable.getOwnerConnection)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "findRootVehicle", Mountable.findRootVehicle)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMapHotspotVisible", Mountable.getIsMapHotspotVisible)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAdditionalComponentMass", Mountable.getAdditionalComponentMass)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setWorldPositionQuaternion", Mountable.setWorldPositionQuaternion)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", Mountable.addToPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", Mountable.removeFromPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", Mountable.getIsFoldAllowed)
end

function Mountable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Mountable)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Mountable)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Mountable)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Mountable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Mountable)
	SpecializationUtil.registerEventListener(vehicleType, "onPreAttach", Mountable)
end

-- Local values: spec
function Mountable:onLoad(savegame)
	local v_u_7_ = self.spec_mountable
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.dynamicMount#triggerIndex", "vehicle.dynamicMount#triggerNode")
	v_u_7_.dynamicMountJointIndex = nil
	v_u_7_.dynamicMountObject = nil
	self.dynamicMountObjectActorId = nil
	v_u_7_.dynamicMountForceLimitScale = self.xmlFile:getValue("vehicle.dynamicMount#forceLimitScale", 1)
	v_u_7_.componentNode = self.rootNode
	v_u_7_.dynamicMountTriggerId = self.xmlFile:getValue("vehicle.dynamicMount#triggerNode", nil, self.components, self.i3dMappings)
	if v_u_7_.dynamicMountTriggerId ~= nil then
		if self.isServer then
			addTrigger(v_u_7_.dynamicMountTriggerId, "mountableTriggerCallback", self)
		end
		v_u_7_.componentNode = self:getParentComponent(v_u_7_.dynamicMountTriggerId)
		if v_u_7_.dynamicMountJointNodeDynamic == nil then
			v_u_7_.dynamicMountJointNodeDynamic = createTransformGroup("dynamicMountJointNodeDynamic")
			link(v_u_7_.componentNode, v_u_7_.dynamicMountJointNodeDynamic)
		end
		v_u_7_.dynamicMountJointTransY = self.xmlFile:getValue("vehicle.dynamicMount#jointTransY")
		v_u_7_.dynamicMountJointLimitToRotY = self.xmlFile:getValue("vehicle.dynamicMount#jointLimitToRotY", false)
	end
	v_u_7_.jointNode = self.xmlFile:getValue("vehicle.dynamicMount#jointNode", nil, self.components, self.i3dMappings)
	v_u_7_.dynamicMountTriggerForceAcceleration = self.xmlFile:getValue("vehicle.dynamicMount#triggerForceAcceleration", 4)
	v_u_7_.dynamicMountSingleAxisFreeY = self.xmlFile:getValue("vehicle.dynamicMount#singleAxisFreeY")
	v_u_7_.dynamicMountSingleAxisFreeX = self.xmlFile:getValue("vehicle.dynamicMount#singleAxisFreeX")
	v_u_7_.dynamicMountAllowFoldingWhileMounted = self.xmlFile:getValue("vehicle.dynamicMount#allowFoldingWhileMounted", false)
	v_u_7_.additionalMountDistance = self.xmlFile:getValue("vehicle.dynamicMount#additionalMountDistance", 0)
	v_u_7_.forceLimitUpdate = {}
	v_u_7_.forceLimitUpdate.raycastActive = false
	v_u_7_.forceLimitUpdate.timer = 0
	v_u_7_.forceLimitUpdate.lastDistance = 0
	v_u_7_.forceLimitUpdate.nextMountingDistance = 0
	v_u_7_.forceLimitUpdate.additionalMass = 0
	v_u_7_.forceLimitUpdate.isAllowed = false
	v_u_7_.allowMassReduction = self.xmlFile:getValue("vehicle.dynamicMount#allowMassReduction", self:getDefaultAllowComponentMassReduction())
	v_u_7_.reducedComponentMass = false
	v_u_7_.lockPositions = {}
	self.xmlFile:iterate("vehicle.dynamicMount.lockPosition", function(_, p8_)
		-- upvalues: (copy) self, (copy) v_u_7_
		local v9_ = {
			["xmlFilename"] = self.xmlFile:getValue(p8_ .. "#xmlFilename"),
			["jointNode"] = self.xmlFile:getValue(p8_ .. "#jointNode", "0>")
		}
		if v9_.xmlFilename == nil or v9_.jointNode == nil then
			Logging.xmlWarning(self.xmlFile, "Invalid lock position \'%s\'. Missing xmlFilename or jointNode!", p8_)
		else
			v9_.xmlFilename = v9_.xmlFilename:gsub("$data", "data")
			v9_.transOffset = self.xmlFile:getValue(p8_ .. "#transOffset", "0 0 0", true)
			v9_.rotOffset = self.xmlFile:getValue(p8_ .. "#rotOffset", "0 0 0", true)
			local v10_ = v_u_7_.lockPositions
			table.insert(v10_, v9_)
		end
	end)
	self.dynamicMountType = MountableObject.MOUNT_TYPE_NONE
	self.dynamicMountObjectId = nil
	v_u_7_.mountStateChangeListeners = {}
end

-- Local values: spec, mountObject
function Mountable:onDelete()
	local v12_ = self.spec_mountable
	local v13_ = self:getDynamicMountObject()
	if v13_ ~= nil and v13_.onUnmountObject ~= nil then
		v13_:onUnmountObject(self)
	end
	if v12_.dynamicMountJointIndex ~= nil then
		removeJointBreakReport(v12_.dynamicMountJointIndex)
		removeJoint(v12_.dynamicMountJointIndex)
	end
	if v12_.dynamicMountObject ~= nil then
		v12_.dynamicMountObject:removeDynamicMountedObject(self, true)
	end
	if v12_.dynamicMountTriggerId ~= nil then
		removeTrigger(v12_.dynamicMountTriggerId)
	end
end

function Mountable:onReadStream(streamId, connection)
	self:setDynamicMountType(streamReadUIntN(streamId, MountableObject.MOUNT_TYPE_SEND_NUM_BITS), nil, true)
end

function Mountable:onWriteStream(streamId, connection)
	streamWriteUIntN(streamId, self.spec_mountable.dynamicMountType, MountableObject.MOUNT_TYPE_SEND_NUM_BITS)
end

-- Local values: spec, _, _, zOffset
function Mountable:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isServer then
		local v20_ = self.spec_mountable
		if v20_.dynamicMountObjectTriggerCount ~= nil and v20_.dynamicMountObjectTriggerCount <= 0 then
			if v20_.dynamicMountJointNodeDynamicRefNode == nil then
				self:unmountDynamic()
				v20_.dynamicMountObjectTriggerCount = nil
			else
				local _, _, v21_ = localToLocal(v20_.dynamicMountJointNodeDynamic, v20_.dynamicMountJointNodeDynamicRefNode, 0, 0, 0)
				if v20_.dynamicMountJointNodeDynamicMountOffset < v21_ then
					v20_.dynamicMountJointNodeDynamicMountOffset = nil
					v20_.dynamicMountJointNodeDynamicRefNode = nil
					self:unmountDynamic()
					v20_.dynamicMountObjectTriggerCount = nil
				else
					self:raiseActive()
				end
			end
		end
		if self.dynamicMountJointIndex ~= nil and v20_.forceLimitUpdate.isAllowed then
			self:updateDynamicMountJointForceLimit(dt)
		end
	end
end

-- Local values: spec
function Mountable:getSupportsMountDynamic()
	return self.spec_mountable.dynamicMountForceLimitScale ~= nil
end

function Mountable:getSupportsMountKinematic()
	return #self.components == 1
end

-- Local values: spec
function Mountable:onDynamicMountJointBreak(jointIndex, breakingImpulse)
	if jointIndex == self.spec_mountable.dynamicMountJointIndex then
		self:unmountDynamic()
	end
	return false
end

-- Local values: spec, vehicle, dynamicMountAttacher
function Mountable:mountableTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	local v30_ = self.spec_mountable
	if onEnter then
		local v31_ = g_currentMission.nodeToObject[otherActorId]
		if v31_ ~= nil and v31_.spec_dynamicMountAttacher ~= nil then
			local v32_ = v31_.spec_dynamicMountAttacher
			if v32_ ~= nil and v32_.dynamicMountAttacherNode ~= nil then
				if self.dynamicMountObjectActorId == nil then
					self:mountDynamic(v31_, otherActorId, v32_.dynamicMountAttacherNode, DynamicMountUtil.TYPE_FORK, v30_.dynamicMountTriggerForceAcceleration * v32_.dynamicMountAttacherForceLimitScale)
					v30_.dynamicMountObjectTriggerCount = 1
					return
				end
				if otherActorId ~= self.dynamicMountObjectActorId and v30_.dynamicMountObjectTriggerCount == nil then
					self:unmountDynamic()
					self:mountDynamic(v31_, otherActorId, v32_.dynamicMountAttacherNode, DynamicMountUtil.TYPE_FORK, v30_.dynamicMountTriggerForceAcceleration * v32_.dynamicMountAttacherForceLimitScale)
					v30_.dynamicMountObjectTriggerCount = 1
					return
				end
				if otherActorId == self.dynamicMountObjectActorId and v30_.dynamicMountObjectTriggerCount ~= nil then
					v30_.dynamicMountObjectTriggerCount = v30_.dynamicMountObjectTriggerCount + 1
					return
				end
			end
		end
	elseif onLeave and (otherActorId == self.dynamicMountObjectActorId and v30_.dynamicMountObjectTriggerCount ~= nil) then
		v30_.dynamicMountObjectTriggerCount = v30_.dynamicMountObjectTriggerCount - 1
		if v30_.dynamicMountJointNodeDynamic == nil and v30_.dynamicMountObjectTriggerCount == 0 then
			self:unmountDynamic()
			v30_.dynamicMountObjectTriggerCount = nil
		end
	end
end

-- Local values: spec, wx, wy, wz, wqx, wqy, wqz, wqw
function Mountable:mount(object, node, x, y, z, rx, ry, rz)
	local v42_ = self.spec_mountable
	self:unmountDynamic(true)
	if self.dynamicMountType == MountableObject.MOUNT_TYPE_NONE then
		removeFromPhysics(v42_.componentNode)
	end
	link(node, v42_.componentNode)
	local v43_, v44_, v45_ = localToWorld(node, x, y, z)
	local v46_, v47_, v48_, v49_ = mathEulerToQuaternion(localRotationToWorld(node, rx, ry, rz))
	self:setWorldPositionQuaternion(v43_, v44_, v45_, v46_, v47_, v48_, v49_, 1, true)
	self:setDynamicMountType(MountableObject.MOUNT_TYPE_DEFAULT, object)
end

-- Local values: spec, mountObject, x, y, z, qx, qy, qz, qw
function Mountable:unmount(noEventSend)
	local v52_ = self.spec_mountable
	if self.dynamicMountType ~= MountableObject.MOUNT_TYPE_DEFAULT then
		return false
	end
	local v53_ = self:getDynamicMountObject()
	if v53_ ~= nil and v53_.onUnmountObject ~= nil then
		v53_:onUnmountObject(self)
	end
	local v54_, v55_, v56_ = getWorldTranslation(v52_.componentNode)
	local v57_, v58_, v59_, v60_ = getWorldQuaternion(v52_.componentNode)
	link(getRootNode(), v52_.componentNode)
	self:setWorldPositionQuaternion(v54_, v55_, v56_, v57_, v58_, v59_, v60_, 1, true)
	addToPhysics(v52_.componentNode)
	self:setDynamicMountType(MountableObject.MOUNT_TYPE_NONE, nil, noEventSend)
	return true
end

-- Local values: spec, wx, wy, wz, wqx, wqy, wqz, wqw, componentNode
function Mountable:mountKinematic(object, node, x, y, z, rx, ry, rz)
	local v70_ = self.spec_mountable
	self:unmountDynamic(true)
	removeFromPhysics(v70_.componentNode)
	if self.isServer then
		setRigidBodyType(v70_.componentNode, RigidBodyType.KINEMATIC)
		self.components[1].isKinematic = true
		self.components[1].isDynamic = false
	end
	link(node, v70_.componentNode)
	local v71_, v72_, v73_ = localToWorld(node, x, y, z)
	local v74_, v75_, v76_, v77_ = mathEulerToQuaternion(localRotationToWorld(node, rx, ry, rz))
	self:setWorldPositionQuaternion(v71_, v72_, v73_, v74_, v75_, v76_, v77_, 1, true)
	addToPhysics(v70_.componentNode)
	if object.getParentComponent ~= nil then
		local v78_ = object:getParentComponent(node)
		if getRigidBodyType(v78_) == RigidBodyType.DYNAMIC then
			setPairCollision(v78_, v70_.componentNode, false)
		end
	end
	v70_.mountJointNode = node
	self:setDynamicMountType(MountableObject.MOUNT_TYPE_KINEMATIC, object)
end

-- Local values: spec, mountObject, componentNode, x, y, z, qx, qy, qz, qw
function Mountable:unmountKinematic()
	local v80_ = self.spec_mountable
	if self.dynamicMountType ~= MountableObject.MOUNT_TYPE_KINEMATIC then
		return false
	end
	local v81_ = self:getDynamicMountObject()
	if v81_ ~= nil then
		if v81_.getParentComponent ~= nil then
			local v82_ = v81_:getParentComponent(v80_.mountJointNode)
			if getRigidBodyType(v82_) == RigidBodyType.DYNAMIC then
				setPairCollision(v82_, v80_.componentNode, true)
			end
		end
		if v81_.onUnmountObject ~= nil then
			v81_:onUnmountObject(self)
		end
	end
	v80_.mountJointNode = nil
	local v83_, v84_, v85_ = getWorldTranslation(v80_.componentNode)
	local v86_, v87_, v88_, v89_ = getWorldQuaternion(v80_.componentNode)
	removeFromPhysics(v80_.componentNode)
	link(getRootNode(), v80_.componentNode)
	self:setWorldPositionQuaternion(v83_, v84_, v85_, v86_, v87_, v88_, v89_, 1, true)
	addToPhysics(v80_.componentNode)
	if self.isServer then
		setRigidBodyType(v80_.componentNode, RigidBodyType.DYNAMIC)
		self.components[1].isKinematic = false
		self.components[1].isDynamic = true
	end
	self:setDynamicMountType(MountableObject.MOUNT_TYPE_NONE)
	return true
end

-- Local values: spec, dynamicMountSpec, _, mountedObject, x, y, z, _, _, zOffset, dx, dy, dz, rx, ry, rz, _, upY, _, rx, ry, rz, _
function Mountable:mountDynamic(object, objectActorId, jointNode, mountType, forceAcceleration)
	local v96_ = self.spec_mountable
	if not self:getSupportsMountDynamic() or (self:getDynamicMountObject() ~= nil or self.dynamicMountType ~= MountableObject.MOUNT_TYPE_NONE) then
		return false
	end
	local v97_ = self.spec_dynamicMountAttacher
	if v97_ ~= nil then
		for _, v98_ in pairs(v97_.dynamicMountedObjects) do
			if v98_:isa(Vehicle) and v98_.rootVehicle == object.rootVehicle then
				return false
			end
		end
	end
	if object.rootVehicle == self.rootVehicle then
		return false
	end
	local v99_ = v96_.jointNode or jointNode
	if v96_.dynamicMountTriggerId ~= nil then
		local v100_, v101_, v102_
		if mountType == DynamicMountUtil.TYPE_FORK then
			local _, _, v103_ = worldToLocal(v99_, localToWorld(v96_.componentNode, getCenterOfMass(v96_.componentNode)))
			v100_, v101_, v102_ = localToLocal(v99_, getParent(v96_.dynamicMountJointNodeDynamic), 0, 0, v103_)
		else
			v100_, v101_, v102_ = localToLocal(v99_, getParent(v96_.dynamicMountJointNodeDynamic), 0, 0, 0)
		end
		local v104_ = v96_.dynamicMountJointTransY or v101_
		setTranslation(v96_.dynamicMountJointNodeDynamic, v100_, v104_, v102_)
		if v96_.dynamicMountJointLimitToRotY then
			local v105_, v106_, v107_ = localDirectionToLocal(v99_, getParent(v96_.dynamicMountJointNodeDynamic), 0, 0, 1)
			if math.abs(v106_) > 0.2 then
				return false
			end
			local v108_, v109_ = MathUtil.vector2Normalize(v105_, v107_)
			local v110_ = MathUtil.getYRotationFromDirection(v108_, v109_)
			setRotation(v96_.dynamicMountJointNodeDynamic, 0, v110_, 0)
			local _, v111_, _ = localDirectionToLocal(v99_, getParent(v96_.dynamicMountJointNodeDynamic), 0, 1, 0)
			if v111_ < 0 then
				rotateAboutLocalAxis(v96_.dynamicMountJointNodeDynamic, 3.141592653589793, 0, 0, 1)
			end
		else
			local v112_, v113_, v114_ = localRotationToLocal(v99_, getParent(v96_.dynamicMountJointNodeDynamic), 0, 0, 0)
			setRotation(v96_.dynamicMountJointNodeDynamic, v112_, v113_, v114_)
		end
		local _, _, v115_ = localToLocal(v96_.dynamicMountJointNodeDynamic, v99_, 0, 0, 0)
		v96_.dynamicMountJointNodeDynamicMountOffset = v115_
		v96_.dynamicMountJointNodeDynamicRefNode = v99_
	end
	v96_.mountBaseForceAcceleration = forceAcceleration
	v96_.mountBaseMass = self:getTotalMass()
	v96_.forceLimitUpdate.isAllowed = mountType == DynamicMountUtil.TYPE_FORK
	if not DynamicMountUtil.mountDynamic(self, v96_.componentNode, object, objectActorId, v99_, mountType, forceAcceleration * v96_.dynamicMountForceLimitScale, v96_.dynamicMountJointNodeDynamic) then
		return false
	end
	self:setDynamicMountType(MountableObject.MOUNT_TYPE_DYNAMIC, object)
	return true
end

-- Local values: mountObject
function Mountable:unmountDynamic(isDelete)
	self:setDynamicMountType(MountableObject.MOUNT_TYPE_NONE)
	local v118_ = self:getDynamicMountObject()
	if v118_ ~= nil and v118_.onUnmountObject ~= nil then
		v118_:onUnmountObject(self)
	end
	self:setDynamicMountType(MountableObject.MOUNT_TYPE_NONE)
	DynamicMountUtil.unmountDynamic(self, isDelete)
end

-- Local values: spec, object, componentNode
function Mountable:addToPhysics(superFunc)
	if not superFunc(self) then
		return false
	end
	local v121_ = self.spec_mountable
	if self.dynamicMountType == MountableObject.MOUNT_TYPE_KINEMATIC then
		local v122_ = self:getDynamicMountObject()
		if v122_ ~= nil and v122_.getParentComponent ~= nil then
			local v123_ = v122_:getParentComponent(v121_.mountJointNode)
			if getRigidBodyType(v123_) == RigidBodyType.DYNAMIC then
				setPairCollision(v123_, v121_.componentNode, false)
			end
		end
	end
	return true
end

function Mountable:removeFromPhysics(superFunc)
	return superFunc(self)
end

function Mountable:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	if self.dynamicMountType == MountableObject.MOUNT_TYPE_NONE or self.spec_mountable.dynamicMountAllowFoldingWhileMounted then
		return superFunc(self, direction, onAiTurnOn)
	else
		return false, g_i18n:getText("warning_foldingNotWhileAttached")
	end
end

function Mountable:getAdditionalMountingDistance()
	return self.spec_mountable.additionalMountDistance
end

function Mountable.getAdditionalMountingMass(self)
	return 0
end

-- Local values: spec, x, y, z
function Mountable:updateDynamicMountJointForceLimit(dt)
	local v133_ = self.spec_mountable
	if not v133_.forceLimitUpdate.raycastActive then
		v133_.forceLimitUpdate.timer = v133_.forceLimitUpdate.timer - dt
		if v133_.forceLimitUpdate.timer <= 0 then
			v133_.forceLimitUpdate.raycastActive = true
			v133_.forceLimitUpdate.timer = Mountable.FORCE_LIMIT_UPDATE_TIME
			v133_.forceLimitUpdate.lastDistance = 0
			v133_.forceLimitUpdate.lastObject = nil
			v133_.forceLimitUpdate.nextMountingDistance = self:getAdditionalMountingDistance()
			v133_.forceLimitUpdate.additionalMass = 0
			local v134_, v135_, v136_ = getWorldTranslation(self.rootNode)
			raycastAllAsync(v134_, v135_, v136_, 0, 1, 0, Mountable.FORCE_LIMIT_RAYCAST_DISTANCE, "additionalMountingMassRaycastCallback", self, CollisionFlag.DYNAMIC_OBJECT)
		end
	end
end

-- Local values: spec, vehicle, offset, massFactor, forceAcceleration, forceLimit
function Mountable:additionalMountingMassRaycastCallback(hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	if g_currentMission ~= nil and not (self.isDeleted or self.isDeleting) then
		local v141_ = self.spec_mountable
		v141_.forceLimitUpdate.raycastActive = false
		local v142_ = g_currentMission.nodeToObject[hitObjectId]
		if v142_ ~= self and (v142_ ~= nil and (v142_:isa(Vehicle) and (self.getAdditionalMountingDistance ~= nil and v142_ ~= v141_.forceLimitUpdate.lastObject))) then
			local v143_ = distance - v141_.forceLimitUpdate.lastDistance - v141_.forceLimitUpdate.nextMountingDistance
			if math.abs(v143_) < 0.25 then
				v141_.forceLimitUpdate.lastDistance = distance
				v141_.forceLimitUpdate.nextMountingDistance = self:getAdditionalMountingDistance()
				v141_.forceLimitUpdate.additionalMass = v141_.forceLimitUpdate.additionalMass + v142_:getTotalMass()
				v141_.forceLimitUpdate.lastObject = v142_
			end
		end
		if isLast and self.dynamicMountJointIndex ~= nil then
			local v144_ = (v141_.forceLimitUpdate.additionalMass + v141_.mountBaseMass) / v141_.mountBaseMass
			local v145_ = v141_.mountBaseForceAcceleration * v144_
			local v146_ = v141_.mountBaseMass * v145_
			setJointLinearDrive(self.dynamicMountJointIndex, 2, false, true, 0, 0, v146_, 0, 0)
		end
		return true
	end
end

-- Local values: isActive, dynamicMountObject
function Mountable:getIsActive(superFunc)
	local v149_ = self:getDynamicMountObject()
	local v150_
	if v149_ == nil or v149_.getIsActive == nil then
		v150_ = false
	else
		v150_ = v149_:getIsActive()
	end
	return superFunc(self) or v150_
end

function Mountable:getMountObject()
	if self.dynamicMountType == MountableObject.MOUNT_TYPE_DYNAMIC then
		return nil
	else
		return self:getDynamicMountObject()
	end
end

function Mountable:getDynamicMountObject()
	if self.dynamicMountObjectId == nil then
		return nil
	else
		return NetworkUtil.getObject(self.dynamicMountObjectId)
	end
end

-- Local values: spec
function Mountable:setReducedComponentMass(state)
	local v155_ = self.spec_mountable
	if not self:getAllowComponentMassReduction() then
		return false
	end
	if v155_.reducedComponentMass ~= state then
		v155_.reducedComponentMass = state
		self:setMassDirty()
	end
	return true
end

function Mountable:getAllowComponentMassReduction()
	return self.spec_mountable.allowMassReduction
end

function Mountable:getDefaultAllowComponentMassReduction()
	return false
end

function Mountable:getMountableLockPositions()
	return self.spec_mountable.lockPositions
end

-- Local values: spec, _, listener
function Mountable:setDynamicMountType(mountType, mountObject, noEventSend)
	local v162_ = self.spec_mountable
	if mountType ~= self.dynamicMountType then
		self.dynamicMountType = mountType
		if mountObject == nil then
			self.dynamicMountObjectId = nil
		else
			self.dynamicMountObjectId = NetworkUtil.getObjectId(mountObject)
		end
		if mountType == MountableObject.MOUNT_TYPE_NONE then
			self:setReducedComponentMass(false)
		end
		for _, v163_ in ipairs(v162_.mountStateChangeListeners) do
			local v164_ = v163_.callbackFunc
			if type(v164_) == "string" then
				v163_.object[v163_.callbackFunc](v163_.object, self, mountType, mountObject)
			else
				local v165_ = v163_.callbackFunc
				if type(v165_) == "function" then
					v163_.callbackFunc(v163_.object, self, mountType, mountObject)
				end
			end
		end
		SpecializationUtil.raiseEvent(self, "onDynamicMountTypeChanged", self.dynamicMountType, mountObject)
		MountableSetMountTypeEvent.sendEvent(self, self.dynamicMountType, mountObject, noEventSend)
	end
end

-- Local values: spec, _, listener
function Mountable:addMountStateChangeListener(object, callbackFunc)
	local v169_ = self.spec_mountable
	local v170_ = callbackFunc == nil and "onObjectMountStateChanged" or callbackFunc
	for _, v171_ in ipairs(v169_.mountStateChangeListeners) do
		if v171_.object == object and v171_.callbackFunc == v170_ then
			return
		end
	end
	local v172_ = v169_.mountStateChangeListeners
	table.insert(v172_, {
		["object"] = object,
		["callbackFunc"] = v170_
	})
end

-- Local values: spec, indexToRemove, i, listener
function Mountable:removeMountStateChangeListener(object, callbackFunc)
	local v176_ = self.spec_mountable
	local v177_ = callbackFunc == nil and "onObjectMountStateChanged" or callbackFunc
	local v178_ = -1
	for v179_, v180_ in ipairs(v176_.mountStateChangeListeners) do
		if v180_.object == object and v180_.callbackFunc == v177_ then
			v178_ = v179_
		end
	end
	if v178_ > 0 then
		table.remove(v176_.mountStateChangeListeners, v178_)
	end
end

-- Local values: spec, dynamicMountObject
function Mountable:getOwnerConnection(superFunc)
	local _ = self.spec_mountable
	local v183_ = self:getMountObject()
	if v183_ == nil or v183_.getOwnerConnection == nil then
		return superFunc(self)
	else
		return v183_:getOwnerConnection()
	end
end

-- Local values: spec, rootAttacherVehicle, dynamicMountObject
function Mountable:findRootVehicle(superFunc)
	local _ = self.spec_mountable
	local v186_ = superFunc(self)
	if v186_ == nil or v186_ == self then
		local v187_ = self:getMountObject()
		if v187_ ~= nil and v187_.findRootVehicle ~= nil then
			v186_ = v187_:findRootVehicle()
		end
	end
	if v186_ ~= nil then
		self = v186_
	end
	return self
end

function Mountable:getIsMapHotspotVisible(superFunc)
	if superFunc(self) then
		return self:getDynamicMountObject() == nil
	else
		return false
	end
end

-- Local values: additionalMass, spec
function Mountable:getAdditionalComponentMass(superFunc, component)
	local v193_ = superFunc(self, component)
	if self.spec_mountable.reducedComponentMass then
		v193_ = -component.defaultMass + 0.1
	end
	return v193_
end

function Mountable:setWorldPositionQuaternion(superFunc, x, y, z, qx, qy, qz, qw, i, changeInterp)
	if self.isServer or self:getMountObject() == nil then
		return superFunc(self, x, y, z, qx, qy, qz, qw, i, changeInterp)
	end
end

function Mountable:onPreAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	self:unmountDynamic()
end
