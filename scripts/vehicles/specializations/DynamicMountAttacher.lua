DynamicMountAttacher = {}
DynamicMountAttacher.DYNAMIC_MOUNT_GRAB_XML_PATH = "vehicle.dynamicMountAttacher.grab"

function DynamicMountAttacher.prerequisitesPresent(self)
	return true
end
function DynamicMountAttacher.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("DynamicMountAttacher")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.dynamicMountAttacher#node", "Attacher node")
	v1_:register(XMLValueType.FLOAT, "vehicle.dynamicMountAttacher#forceLimitScale", "Force limit", 1)
	v1_:register(XMLValueType.FLOAT, "vehicle.dynamicMountAttacher#timeToMount", "No movement time until mounting", 1000)
	v1_:register(XMLValueType.BOOL, "vehicle.dynamicMountAttacher#stateChangeMount", "Mount / unmount the object while the allowed state changes (e.g. due to foldable limits)", false)
	v1_:register(XMLValueType.INT, "vehicle.dynamicMountAttacher#numObjectBits", "Number of object bits to sync", 5)
	v1_:register(XMLValueType.BOOL, "vehicle.dynamicMountAttacher#limitToKnownObjects", "Only mount objects that are defined with a lockPosition", false)
	v1_:register(XMLValueType.BOOL, "vehicle.dynamicMountAttacher#collisionBetweenObjects", "Collision between mounted objects is enabled", true)
	v1_:register(XMLValueType.STRING, "vehicle.dynamicMountAttacher.grab#openMountType", "Open mount type", "TYPE_FORK")
	v1_:register(XMLValueType.STRING, "vehicle.dynamicMountAttacher.grab#closedMountType", "Closed mount type", "TYPE_AUTO_ATTACH_XYZ")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.dynamicMountAttacher.fork(?)#node", "Fork collision node (starting from FS25 one combined node for front and back part)")
	v1_:register(XMLValueType.STRING, "vehicle.dynamicMountAttacher.fork(?)#mountType", "Mount type that is used if object is mounted via this fork node", "FORK")
	v1_:register(XMLValueType.FLOAT, "vehicle.dynamicMountAttacher.fork(?)#forceLimitScale", "Force limit that is used if object is mounted via this fork node", 1)
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.dynamicMountAttacher#triggerNode", "Trigger node")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.dynamicMountAttacher#rootNode", "Root node")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.dynamicMountAttacher#jointNode", "Joint node")
	v1_:register(XMLValueType.FLOAT, "vehicle.dynamicMountAttacher#forceAcceleration", "Force acceleration", 30)
	v1_:register(XMLValueType.STRING, "vehicle.dynamicMountAttacher#mountType", "Mount type", "TYPE_AUTO_ATTACH_XZ")
	v1_:register(XMLValueType.BOOL, "vehicle.dynamicMountAttacher#transferMass", "If this is set to \'true\' the mass of the object to mount is transferred to our own component. This improves physics stability", false)
	v1_:addDelayedRegistrationPath("vehicle.dynamicMountAttacher.lockPosition(?)", "DynamicMountAttacher:lockPosition")
	v1_:register(XMLValueType.STRING, "vehicle.dynamicMountAttacher.lockPosition(?)#xmlFilename", "XML filename of vehicle to lock (needs to match only the end of the filename)")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.dynamicMountAttacher.lockPosition(?)#jointNode", "Joint node (Represents the position of the other vehicles root node)")
	v1_:register(XMLValueType.STRING, "vehicle.dynamicMountAttacher.lockPosition(?).configuration(?)#name", "Name of configuration")
	v1_:register(XMLValueType.INT, "vehicle.dynamicMountAttacher.lockPosition(?).configuration(?)#index", "Configuration index that needs to match to use the lock position")
	v1_:register(XMLValueType.FLOAT, "vehicle.dynamicMountAttacher.lockPosition(?)#width", "Width of lock position (if defined, collision to other vehicles is checked during locking)")
	v1_:register(XMLValueType.FLOAT, "vehicle.dynamicMountAttacher.lockPosition(?)#length", "Length of lock position (if defined, collision to other vehicles is checked during locking)")
	v1_:register(XMLValueType.FLOAT, "vehicle.dynamicMountAttacher.lockPosition(?)#height", "Height of lock position (if defined, collision to other vehicles is checked during locking)")
	ObjectChangeUtil.registerObjectChangeXMLPaths(v1_, "vehicle.dynamicMountAttacher.lockPosition(?)")
	v1_:register(XMLValueType.STRING, "vehicle.dynamicMountAttacher.animation#name", "Animation name")
	v1_:register(XMLValueType.FLOAT, "vehicle.dynamicMountAttacher.animation#speed", "Animation speed", 1)
	v1_:addDelayedRegistrationFunc("Cylindered:movingTool", function(p2_, p3_)
		p2_:register(XMLValueType.BOOL, p3_ .. ".dynamicMountAttacher#value", "Update dynamic mount attacher joints")
		p2_:register(XMLValueType.BOOL, p3_ .. ".dynamicMountAttacher#allowedMounted", "Allow moving tool movement while something is mounted", true)
	end)
	v1_:addDelayedRegistrationFunc("Cylindered:movingPart", function(p4_, p5_)
		p4_:register(XMLValueType.BOOL, p5_ .. ".dynamicMountAttacher#value", "Update dynamic mount attacher joints")
	end)
	v1_:register(XMLValueType.BOOL, "vehicle.dynamicMountAttacher#allowFoldingWhileMounted", "Folding is allowed while a object is mounted", true)
	v1_:setXMLSpecializationType()
end

function DynamicMountAttacher.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadDynamicLockPositionFromXML", DynamicMountAttacher.loadDynamicLockPositionFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsDynamicLockPositionActive", DynamicMountAttacher.getIsDynamicLockPositionActive)
	SpecializationUtil.registerFunction(vehicleType, "writeDynamicMountObjectsToStream", DynamicMountAttacher.writeDynamicMountObjectsToStream)
	SpecializationUtil.registerFunction(vehicleType, "readDynamicMountObjectsFromStream", DynamicMountAttacher.readDynamicMountObjectsFromStream)
	SpecializationUtil.registerFunction(vehicleType, "getAllowDynamicMountObjects", DynamicMountAttacher.getAllowDynamicMountObjects)
	SpecializationUtil.registerFunction(vehicleType, "dynamicMountTriggerCallback", DynamicMountAttacher.dynamicMountTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "lockDynamicMountedObject", DynamicMountAttacher.lockDynamicMountedObject)
	SpecializationUtil.registerFunction(vehicleType, "addDynamicMountedObject", DynamicMountAttacher.addDynamicMountedObject)
	SpecializationUtil.registerFunction(vehicleType, "removeDynamicMountedObject", DynamicMountAttacher.removeDynamicMountedObject)
	SpecializationUtil.registerFunction(vehicleType, "onUnmountObject", DynamicMountAttacher.onUnmountObject)
	SpecializationUtil.registerFunction(vehicleType, "setDynamicMountAnimationState", DynamicMountAttacher.setDynamicMountAnimationState)
	SpecializationUtil.registerFunction(vehicleType, "getAllowDynamicMountFillLevelInfo", DynamicMountAttacher.getAllowDynamicMountFillLevelInfo)
	SpecializationUtil.registerFunction(vehicleType, "loadDynamicMountGrabFromXML", DynamicMountAttacher.loadDynamicMountGrabFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsDynamicMountGrabOpened", DynamicMountAttacher.getIsDynamicMountGrabOpened)
	SpecializationUtil.registerFunction(vehicleType, "getDynamicMountTimeToMount", DynamicMountAttacher.getDynamicMountTimeToMount)
	SpecializationUtil.registerFunction(vehicleType, "getHasDynamicMountedObjects", DynamicMountAttacher.getHasDynamicMountedObjects)
	SpecializationUtil.registerFunction(vehicleType, "forceDynamicMountPendingObjects", DynamicMountAttacher.forceDynamicMountPendingObjects)
	SpecializationUtil.registerFunction(vehicleType, "forceUnmountDynamicMountedObjects", DynamicMountAttacher.forceUnmountDynamicMountedObjects)
	SpecializationUtil.registerFunction(vehicleType, "getDynamicMountAttacherSettingsByNode", DynamicMountAttacher.getDynamicMountAttacherSettingsByNode)
	SpecializationUtil.registerFunction(vehicleType, "dynamicMountLockPositionOverlapCallback", DynamicMountAttacher.dynamicMountLockPositionOverlapCallback)
end

function DynamicMountAttacher.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillLevelInformation", DynamicMountAttacher.getFillLevelInformation)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadExtraDependentParts", DynamicMountAttacher.loadExtraDependentParts)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateExtraDependentParts", DynamicMountAttacher.updateExtraDependentParts)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAttachedTo", DynamicMountAttacher.getIsAttachedTo)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAdditionalComponentMass", DynamicMountAttacher.getAdditionalComponentMass)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", DynamicMountAttacher.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadMovingToolFromXML", DynamicMountAttacher.loadMovingToolFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMovingToolActive", DynamicMountAttacher.getIsMovingToolActive)
end

function DynamicMountAttacher.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", DynamicMountAttacher)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", DynamicMountAttacher)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", DynamicMountAttacher)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", DynamicMountAttacher)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", DynamicMountAttacher)
	SpecializationUtil.registerEventListener(vehicleType, "onPreAttachImplement", DynamicMountAttacher)
end

-- Local values: spec, grabKey, _, key, fork, mountTypeStr, dynamicMountTrigger, collisionMask, mountTypeString
function DynamicMountAttacher:onLoad(savegame)
	local v_u_10_ = self.spec_dynamicMountAttacher
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.dynamicMountAttacher#index", "vehicle.dynamicMountAttacher#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.dynamicMountAttacher.mountCollisionMask", "vehicle.dynamicMountAttacher.fork")
	v_u_10_.dynamicMountAttacherNode = self.xmlFile:getValue("vehicle.dynamicMountAttacher#node", nil, self.components, self.i3dMappings)
	v_u_10_.dynamicMountAttacherForceLimitScale = self.xmlFile:getValue("vehicle.dynamicMountAttacher#forceLimitScale", 1)
	v_u_10_.dynamicMountAttacherTimeToMount = self.xmlFile:getValue("vehicle.dynamicMountAttacher#timeToMount", 1000)
	v_u_10_.dynamicMountAttacherStateChangeMount = self.xmlFile:getValue("vehicle.dynamicMountAttacher#stateChangeMount", false)
	v_u_10_.numObjectBits = self.xmlFile:getValue("vehicle.dynamicMountAttacher#numObjectBits", 5)
	v_u_10_.maxNumObjectsToSend = 2 ^ v_u_10_.numObjectBits - 1
	v_u_10_.limitToKnownObjects = self.xmlFile:getValue("vehicle.dynamicMountAttacher#limitToKnownObjects", false)
	v_u_10_.collisionBetweenObjects = self.xmlFile:getValue("vehicle.dynamicMountAttacher#collisionBetweenObjects", true)
	if self.xmlFile:hasProperty("vehicle.dynamicMountAttacher.grab") then
		v_u_10_.dynamicMountAttacherGrab = {}
		self:loadDynamicMountGrabFromXML(self.xmlFile, "vehicle.dynamicMountAttacher.grab", v_u_10_.dynamicMountAttacherGrab)
	end
	v_u_10_.pendingDynamicMountObjects = {}
	v_u_10_.lockPositions = {}
	if self.isServer then
		v_u_10_.forks = {}
		for _, v11_ in self.xmlFile:iterator("vehicle.dynamicMountAttacher.fork") do
			local v12_ = {
				["node"] = self.xmlFile:getValue(v11_ .. "#node", nil, self.components, self.i3dMappings)
			}
			if v12_.node == nil then
				Logging.xmlWarning(self.xmlFile, "Missing node or fork in \'%s\'", v11_)
			elseif getCollisionFilterGroup(v12_.node) == CollisionFlag.VEHICLE_FORK then
				local v13_ = self.xmlFile:getValue(v11_ .. "#mountType", "FORK")
				v12_.mountType = DynamicMountUtil["TYPE_" .. v13_] or DynamicMountUtil.TYPE_FORK
				v12_.forceLimitScale = self.xmlFile:getValue(v11_ .. "#forceLimitScale", v_u_10_.dynamicMountAttacherForceLimitScale)
				local v14_ = v_u_10_.forks
				table.insert(v14_, v12_)
			else
				Logging.xmlWarning(self.xmlFile, "Fork node \'%s\' has invalid collision filter group, should have %s!", getName(v12_.node), CollisionFlag.getBitAndName(CollisionFlag.VEHICLE_FORK))
			end
		end
		local v15_ = {
			["triggerNode"] = self.xmlFile:getValue("vehicle.dynamicMountAttacher#triggerNode", nil, self.components, self.i3dMappings),
			["rootNode"] = self.xmlFile:getValue("vehicle.dynamicMountAttacher#rootNode", nil, self.components, self.i3dMappings),
			["jointNode"] = self.xmlFile:getValue("vehicle.dynamicMountAttacher#jointNode", nil, self.components, self.i3dMappings)
		}
		if v15_.triggerNode ~= nil and (v15_.rootNode ~= nil and v15_.jointNode ~= nil) then
			local v16_ = getCollisionFilterMask(v15_.triggerNode)
			local v17_ = CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE
			if bit32.band(v16_, v17_) > 0 then
				addTrigger(v15_.triggerNode, "dynamicMountTriggerCallback", self)
				v15_.forceAcceleration = self.xmlFile:getValue("vehicle.dynamicMountAttacher#forceAcceleration", 30)
				local v18_ = self.xmlFile:getValue("vehicle.dynamicMountAttacher#mountType", "TYPE_AUTO_ATTACH_XZ")
				v15_.mountType = Utils.getNoNil(DynamicMountUtil[v18_], DynamicMountUtil.TYPE_AUTO_ATTACH_XZ)
				v15_.currentMountType = v15_.mountType
				v15_.component = self:getParentComponent(v15_.triggerNode)
				v_u_10_.dynamicMountAttacherTrigger = v15_
			else
				Logging.xmlWarning(self.xmlFile, "Dynamic Mount trigger has invalid collision filter mask, should have %s or %s!", CollisionFlag.getBitAndName(CollisionFlag.DYNAMIC_OBJECT), CollisionFlag.getBitAndName(CollisionFlag.VEHICLE))
			end
			if string.contains(string.lower(getName(v15_.jointNode)), "cutter") then
				local v19_ = CollisionFlag.VEHICLE
				if bit32.band(v16_, v19_) == 0 then
					Logging.xmlWarning(self.xmlFile, "Dynamic Mount trigger has invalid collision filter mask, should have %s for cutter trailers!", CollisionFlag.getBitAndName(CollisionFlag.VEHICLE))
				end
			end
			g_currentMission:addNodeObject(v15_.triggerNode, self)
		end
		v_u_10_.transferMass = self.xmlFile:getValue("vehicle.dynamicMountAttacher#transferMass", false)
		self.xmlFile:iterate("vehicle.dynamicMountAttacher.lockPosition", function(_, p20_)
			-- upvalues: (copy) self, (copy) v_u_10_
			local v21_ = {}
			if self:loadDynamicLockPositionFromXML(self.xmlFile, p20_, v21_) then
				local v22_ = v_u_10_.lockPositions
				table.insert(v22_, v21_)
			end
		end)
	end
	v_u_10_.animationName = self.xmlFile:getValue("vehicle.dynamicMountAttacher.animation#name")
	v_u_10_.animationSpeed = self.xmlFile:getValue("vehicle.dynamicMountAttacher.animation#speed", 1)
	if v_u_10_.animationName ~= nil then
		self:playAnimation(v_u_10_.animationName, v_u_10_.animationSpeed, self:getAnimationTime(v_u_10_.animationName), true)
	end
	v_u_10_.allowFoldingWhileMounted = self.xmlFile:getValue("vehicle.dynamicMountAttacher#allowFoldingWhileMounted", true)
	v_u_10_.lastMountingIsAllowed = false
	v_u_10_.overlapBoxHasCollision = false
	v_u_10_.overlapBoxIgnoreVehicle = nil
	v_u_10_.dynamicMountedObjects = {}
	v_u_10_.dynamicMountedObjectsDirtyFlag = self:getNextDirtyFlag()
end

-- Local values: spec, object, _
function DynamicMountAttacher:onDelete()
	local v24_ = self.spec_dynamicMountAttacher
	if self.isServer and v24_.dynamicMountedObjects ~= nil then
		for v25_, _ in pairs(v24_.dynamicMountedObjects) do
			v25_:unmountDynamic()
		end
	end
	if v24_.dynamicMountAttacherTrigger ~= nil then
		removeTrigger(v24_.dynamicMountAttacherTrigger.triggerNode)
		g_currentMission:removeNodeObject(v24_.dynamicMountAttacherTrigger.triggerNode)
	end
end

-- Local values: spec, sum
function DynamicMountAttacher:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local v29_ = self.spec_dynamicMountAttacher
		if streamReadBool(streamId) then
			self:setDynamicMountAnimationState(self:readDynamicMountObjectsFromStream(streamId, v29_.dynamicMountedObjects) > 0)
			self:readDynamicMountObjectsFromStream(streamId, v29_.pendingDynamicMountObjects)
		end
	end
end

-- Local values: spec
function DynamicMountAttacher:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v34_ = self.spec_dynamicMountAttacher
		local v35_ = streamWriteBool
		local v36_ = v34_.dynamicMountedObjectsDirtyFlag
		if v35_(streamId, bit32.band(dirtyMask, v36_) ~= 0) then
			self:writeDynamicMountObjectsToStream(streamId, v34_.dynamicMountedObjects)
			self:writeDynamicMountObjectsToStream(streamId, v34_.pendingDynamicMountObjects)
		end
	end
end

-- Local values: spec, mountingIsAllowed, object, _, doAttach, objectRoot, trigger, objectJoint, couldMount, object, _, object, _, usedMountType, x, y, z
function DynamicMountAttacher:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isServer then
		local v38_ = self.spec_dynamicMountAttacher
		local v39_ = self:getAllowDynamicMountObjects()
		if v39_ ~= v38_.lastMountingIsAllowed or not v38_.dynamicMountAttacherStateChangeMount then
			v38_.lastMountingIsAllowed = v39_
			if v39_ then
				for v40_, _ in pairs(v38_.pendingDynamicMountObjects) do
					self:raiseActive()
					if v38_.dynamicMountedObjects[v40_] == nil then
						if v40_.lastMoveTime + self:getDynamicMountTimeToMount() < g_currentMission.time then
							local v41_ = false
							local v42_
							if v40_.components == nil then
								v42_ = nil
							else
								if v40_.getCanBeMounted == nil then
									v41_ = entityExists(v40_.components[1].node) and true or v41_
								else
									v41_ = v40_:getCanBeMounted()
								end
								v42_ = v40_.components[1].node
							end
							if v40_.nodeId ~= nil then
								if v40_.getCanBeMounted == nil then
									v41_ = entityExists(v40_.nodeId) and true or v41_
								else
									v41_ = v40_:getCanBeMounted()
								end
								v42_ = v40_.nodeId
							end
							if v41_ then
								local v43_ = v38_.dynamicMountAttacherTrigger
								local v44_ = createTransformGroup("dynamicMountObjectJoint")
								link(v43_.jointNode, v44_)
								setWorldTranslation(v44_, getWorldTranslation(v42_))
								if v40_:mountDynamic(self, v43_.rootNode, v44_, v43_.mountType, v43_.forceAcceleration) then
									v40_.additionalDynamicMountJointNode = v44_
									self:addDynamicMountedObject(v40_)
								else
									delete(v44_)
								end
							else
								v38_.pendingDynamicMountObjects[v40_] = nil
								self:raiseDirtyFlags(v38_.dynamicMountedObjectsDirtyFlag)
							end
						end
					else
						v38_.pendingDynamicMountObjects[v40_] = nil
					end
				end
			else
				for v45_, _ in pairs(v38_.dynamicMountedObjects) do
					self:removeDynamicMountedObject(v45_, false)
					v45_:unmountDynamic()
					if v45_.additionalDynamicMountJointNode ~= nil then
						delete(v45_.additionalDynamicMountJointNode)
						v45_.additionalDynamicMountJointNode = nil
					end
				end
			end
		end
		if v38_.dynamicMountAttacherGrab ~= nil then
			for v46_, _ in pairs(v38_.dynamicMountedObjects) do
				local v47_ = v38_.dynamicMountAttacherGrab.closedMountType
				if self:getIsDynamicMountGrabOpened(v38_.dynamicMountAttacherGrab) then
					v47_ = v38_.dynamicMountAttacherGrab.openMountType
				end
				if v38_.dynamicMountAttacherGrab.currentMountType ~= v47_ then
					v38_.dynamicMountAttacherGrab.currentMountType = v47_
					local v48_, v49_, v50_ = getWorldTranslation(v38_.dynamicMountAttacherNode)
					setJointPosition(v46_.dynamicMountJointIndex, 1, v48_, v49_, v50_)
					if v47_ == DynamicMountUtil.TYPE_FORK then
						setJointRotationLimit(v46_.dynamicMountJointIndex, 0, true, 0, 0)
						setJointRotationLimit(v46_.dynamicMountJointIndex, 1, true, 0, 0)
						setJointRotationLimit(v46_.dynamicMountJointIndex, 2, true, 0, 0)
						if v46_.dynamicMountSingleAxisFreeX then
							setJointTranslationLimit(v46_.dynamicMountJointIndex, 0, false, 0, 0)
						else
							setJointTranslationLimit(v46_.dynamicMountJointIndex, 0, true, -0.01, 0.01)
						end
						if v46_.dynamicMountSingleAxisFreeY then
							setJointTranslationLimit(v46_.dynamicMountJointIndex, 1, false, 0, 0)
						else
							setJointTranslationLimit(v46_.dynamicMountJointIndex, 1, true, -0.01, 0.01)
						end
						setJointTranslationLimit(v46_.dynamicMountJointIndex, 2, false, 0, 0)
					else
						setJointRotationLimit(v46_.dynamicMountJointIndex, 0, true, 0, 0)
						setJointRotationLimit(v46_.dynamicMountJointIndex, 1, true, 0, 0)
						setJointRotationLimit(v46_.dynamicMountJointIndex, 2, true, 0, 0)
						if v47_ == DynamicMountUtil.TYPE_AUTO_ATTACH_XYZ or v47_ == DynamicMountUtil.TYPE_FIX_ATTACH then
							setJointTranslationLimit(v46_.dynamicMountJointIndex, 0, true, -0.01, 0.01)
							setJointTranslationLimit(v46_.dynamicMountJointIndex, 1, true, -0.01, 0.01)
							setJointTranslationLimit(v46_.dynamicMountJointIndex, 2, true, -0.01, 0.01)
						elseif v47_ == DynamicMountUtil.TYPE_AUTO_ATTACH_XZ then
							setJointTranslationLimit(v46_.dynamicMountJointIndex, 0, true, -0.01, 0.01)
							setJointTranslationLimit(v46_.dynamicMountJointIndex, 1, false, 0, 0)
							setJointTranslationLimit(v46_.dynamicMountJointIndex, 2, true, -0.01, 0.01)
						elseif v47_ == DynamicMountUtil.TYPE_AUTO_ATTACH_Y then
							setJointTranslationLimit(v46_.dynamicMountJointIndex, 0, false, 0, 0)
							setJointTranslationLimit(v46_.dynamicMountJointIndex, 1, true, -0.01, 0.01)
							setJointTranslationLimit(v46_.dynamicMountJointIndex, 2, false, 0, 0)
						end
					end
				end
			end
		end
	end
end

-- Local values: spec, trigger, couldMount
function DynamicMountAttacher:lockDynamicMountedObject(object, x, y, z, rx, ry, rz)
	local v59_ = self.spec_dynamicMountAttacher
	DynamicMountUtil.unmountDynamic(object, false)
	object:removeFromPhysics()
	v59_.pendingDynamicMountObjects[object] = nil
	object:setAbsolutePosition(x, y, z, rx, ry, rz, nil)
	object:addToPhysics()
	local v60_ = v59_.dynamicMountAttacherTrigger
	if object:mountDynamic(self, v60_.rootNode, v60_.jointNode, v60_.mountType, v60_.forceAcceleration) then
		return true
	end
	self:removeDynamicMountedObject(object, false)
	return false
end

-- Local values: spec, lockedToPosition, lockPositions, i, position, jointNode, x, y, z, rx, ry, rz, minDistancePosition, minDistance, _, lockPosition, foundVehicle, configName, configIndex, distance, x, y, z, rx, ry, rz, x, y, z, rx, ry, rz, otherObject, _, node1, node2
function DynamicMountAttacher:addDynamicMountedObject(object)
	local v63_ = self.spec_dynamicMountAttacher
	if v63_.dynamicMountedObjects[object] == nil then
		v63_.dynamicMountedObjects[object] = object
		local v64_ = false
		if object.getMountableLockPositions ~= nil then
			local v65_ = object:getMountableLockPositions()
			for v66_ = 1, #v65_ do
				local v67_ = v65_[v66_]
				if string.endsWith(self.configFileName, v67_.xmlFilename) then
					local v68_ = I3DUtil.indexToObject(self.components, v67_.jointNode, self.i3dMappings)
					if v68_ ~= nil then
						local v69_, v70_, v71_ = localToWorld(v68_, v67_.transOffset[1], v67_.transOffset[2], v67_.transOffset[3])
						local v72_, v73_, v74_ = localRotationToWorld(v68_, v67_.rotOffset[1], v67_.rotOffset[2], v67_.rotOffset[3])
						if self:lockDynamicMountedObject(object, v69_, v70_, v71_, v72_, v73_, v74_) then
							v64_ = true
							break
						end
					end
				end
			end
		end
		if not v64_ and object:isa(Vehicle) then
			local v75_ = math.huge
			local v76_ = nil
			for _, v77_ in ipairs(v63_.lockPositions) do
				if self:getIsDynamicLockPositionActive(v77_) and (object.configFileName ~= nil and string.endsWith(object.configFileName, v77_.xmlFilename)) then
					local v78_ = true
					if next(v77_.configurations) ~= nil then
						for v79_, v80_ in pairs(v77_.configurations) do
							if v78_ then
								v78_ = object.configurations == nil and true or object.configurations[v79_] == v80_
							end
						end
					end
					if v78_ then
						local v81_ = calcDistanceFrom(v77_.jointNode, object.rootNode)
						if v81_ < v75_ then
							v76_ = v77_
							v75_ = v81_
						end
					end
				end
			end
			if v76_ ~= nil and (v76_.width ~= nil and (v76_.length ~= nil and v76_.height ~= nil)) then
				local v82_, v83_, v84_ = localToWorld(v76_.jointNode, 0, v76_.height * 0.5, 0)
				local v85_, v86_, v87_ = getWorldRotation(v76_.jointNode)
				v63_.overlapBoxHasCollision = false
				v63_.overlapBoxIgnoreVehicle = object
				overlapBox(v82_, v83_, v84_, v85_, v86_, v87_, v76_.width * 0.5, v76_.height * 0.5, v76_.length * 0.5, "dynamicMountLockPositionOverlapCallback", self, CollisionFlag.VEHICLE, true, false, false, true)
				if v63_.overlapBoxHasCollision then
					v76_ = nil
				end
				v63_.overlapBoxIgnoreVehicle = nil
			end
			if v76_ ~= nil then
				local v88_, v89_, v90_ = getWorldTranslation(v76_.jointNode)
				local v91_, v92_, v93_ = getWorldRotation(v76_.jointNode)
				if self:lockDynamicMountedObject(object, v88_, v89_, v90_, v91_, v92_, v93_) then
					ObjectChangeUtil.setObjectChanges(v76_.objectChanges, true, self, self.setMovingToolDirty)
					v76_.state = true
					v76_.object = object
				end
			end
		end
		if v63_.transferMass and (object.setReducedComponentMass ~= nil and object:getAllowComponentMassReduction()) then
			object:setReducedComponentMass(true)
			self:setMassDirty()
		end
		if not v63_.collisionBetweenObjects then
			for v94_, _ in pairs(v63_.dynamicMountedObjects) do
				if v94_ ~= object then
					local v95_ = object.nodeId or object.rootNode
					local v96_ = v94_.nodeId or v94_.rootNode
					if v95_ ~= nil and v96_ ~= nil then
						setPairCollision(v95_, v96_, false)
					end
				end
			end
		end
		self:setDynamicMountAnimationState(true)
		self:raiseDirtyFlags(v63_.dynamicMountedObjectsDirtyFlag)
	end
end

-- Local values: spec, i, position, otherObject, _, node1, node2
function DynamicMountAttacher:removeDynamicMountedObject(object, isDeleting)
	local v100_ = self.spec_dynamicMountAttacher
	v100_.dynamicMountedObjects[object] = nil
	if isDeleting then
		v100_.pendingDynamicMountObjects[object] = nil
	end
	for v101_ = 1, #v100_.lockPositions do
		local v102_ = v100_.lockPositions[v101_]
		if v102_.state and v102_.object == object then
			ObjectChangeUtil.setObjectChanges(v100_.lockPositions[v101_].objectChanges, false, self, self.setMovingToolDirty)
			v102_.state = false
			v102_.object = nil
		end
	end
	if v100_.transferMass then
		self:setMassDirty()
	end
	if not v100_.collisionBetweenObjects then
		for v103_, _ in pairs(v100_.dynamicMountedObjects) do
			if v103_ ~= object then
				local v104_ = object.nodeId or object.rootNode
				local v105_ = v103_.nodeId or v103_.rootNode
				if v104_ ~= nil and v105_ ~= nil then
					setPairCollision(v104_, v105_, true)
				end
			end
		end
	end
	self:setDynamicMountAnimationState(false)
	self:raiseDirtyFlags(v100_.dynamicMountedObjectsDirtyFlag)
end

-- Local values: spec
function DynamicMountAttacher:onUnmountObject(object)
	if self.spec_dynamicMountAttacher.dynamicMountedObjects[object] ~= nil then
		self:removeDynamicMountedObject(object, false)
	end
end

-- Local values: spec
function DynamicMountAttacher:setDynamicMountAnimationState(state)
	local v110_ = self.spec_dynamicMountAttacher
	if state then
		self:playAnimation(v110_.animationName, v110_.animationSpeed, self:getAnimationTime(v110_.animationName), true)
	else
		self:playAnimation(v110_.animationName, -v110_.animationSpeed, self:getAnimationTime(v110_.animationName), true)
	end
end

function DynamicMountAttacher:loadDynamicLockPositionFromXML(xmlFile, key, lockPosition)
	lockPosition.xmlFilename = xmlFile:getValue(key .. "#xmlFilename")
	if lockPosition.xmlFilename == nil then
		Logging.xmlWarning(xmlFile, "Missing xmlFilename for lock position \'%s\'", key)
		return false
	end
	lockPosition.xmlFilename = lockPosition.xmlFilename:gsub("$data", "data")
	lockPosition.jointNode = xmlFile:getValue(key .. "#jointNode", nil, self.components, self.i3dMappings)
	if lockPosition.jointNode == nil then
		Logging.xmlWarning(xmlFile, "Missing jointNode for lock position \'%s\'", key)
		return false
	end
	lockPosition.configurations = {}
	xmlFile:iterate(key .. ".configuration", function(_, p115_)
		-- upvalues: (copy) self, (copy) lockPosition
		local v116_ = self.xmlFile:getValue(p115_ .. "#name")
		local v117_ = self.xmlFile:getValue(p115_ .. "#index")
		if v116_ ~= nil and v117_ ~= nil then
			lockPosition.configurations[v116_] = v117_
		end
	end)
	lockPosition.width = xmlFile:getValue(key .. "#width")
	lockPosition.length = xmlFile:getValue(key .. "#length")
	lockPosition.height = xmlFile:getValue(key .. "#height")
	lockPosition.objectChanges = {}
	ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key, lockPosition.objectChanges, self.components, self)
	lockPosition.state = false
	return true
end

function DynamicMountAttacher:getIsDynamicLockPositionActive(lockPosition)
	return not lockPosition.state
end

-- Local values: spec, num, objectIndex, object, _
function DynamicMountAttacher:writeDynamicMountObjectsToStream(streamId, objects)
	local v122_ = self.spec_dynamicMountAttacher
	local v123_ = table.size(objects)
	local v124_ = v122_.maxNumObjectsToSend
	local v125_ = math.min(v123_, v124_)
	streamWriteUIntN(streamId, v125_, v122_.numObjectBits)
	local v126_ = 0
	for v127_, _ in pairs(objects) do
		v126_ = v126_ + 1
		if v126_ <= v125_ then
			NetworkUtil.writeNodeObject(streamId, v127_)
		else
			Logging.xmlWarning(self.xmlFile, "Not enough bits to send all mounted objects. Please increase \'%s\'", "vehicle.dynamicMountAttacher#numObjectBits")
		end
	end
end

-- Local values: spec, sum, k, _, _, object
function DynamicMountAttacher:readDynamicMountObjectsFromStream(streamId, objects)
	local v131_ = self.spec_dynamicMountAttacher
	local v132_ = streamReadUIntN(streamId, v131_.numObjectBits)
	for v133_, _ in pairs(objects) do
		objects[v133_] = nil
	end
	for _ = 1, v132_ do
		local v134_ = NetworkUtil.readNodeObject(streamId)
		if v134_ ~= nil then
			objects[v134_] = v134_
		end
	end
	return v132_
end

function DynamicMountAttacher.getAllowDynamicMountObjects(self)
	return true
end

-- Local values: spec, object, foundVehicle, i, position, configName, configIndex, object, isObject, isVehicle, object, count
function DynamicMountAttacher:dynamicMountTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	local v139_ = self.spec_dynamicMountAttacher
	if v139_.limitToKnownObjects then
		local v140_ = g_currentMission:getNodeObject(otherActorId)
		if v140_ ~= nil then
			local v141_ = false
			for v142_ = 1, #v139_.lockPositions do
				local v143_ = v139_.lockPositions[v142_]
				if not v143_.state and (v140_.configFileName ~= nil and string.endsWith(v140_.configFileName, v143_.xmlFilename)) then
					v141_ = true
					if next(v143_.configurations) ~= nil then
						for v144_, v145_ in pairs(v143_.configurations) do
							if v141_ then
								v141_ = v140_.configurations == nil and true or v140_.configurations[v144_] == v145_
							end
						end
					end
					if v141_ then
						break
					end
				end
			end
			if not v141_ then
				return
			end
		end
	end
	if getRigidBodyType(otherActorId) == RigidBodyType.DYNAMIC and not getHasTrigger(otherActorId) then
		if onEnter then
			local v146_ = g_currentMission:getNodeObject(otherActorId)
			if v146_ == nil then
				v146_ = g_currentMission.nodeToObject[otherActorId]
			end
			if v146_ == self.rootVehicle or self.spec_attachable ~= nil and self.spec_attachable.attacherVehicle == v146_ then
				v146_ = nil
			end
			if v146_ ~= nil and v146_ ~= self then
				local v147_ = v146_.getSupportsMountDynamic ~= nil and v146_:getSupportsMountDynamic()
				if v147_ then
					v147_ = v146_.lastMoveTime ~= nil
				end
				local v148_ = v146_.getSupportsTensionBelts ~= nil and v146_:getSupportsTensionBelts()
				if v148_ then
					v148_ = v146_.lastMoveTime ~= nil
				end
				if v147_ or v148_ then
					v139_.pendingDynamicMountObjects[v146_] = Utils.getNoNil(v139_.pendingDynamicMountObjects[v146_], 0) + 1
					if v139_.pendingDynamicMountObjects[v146_] == 1 then
						self:raiseDirtyFlags(v139_.dynamicMountedObjectsDirtyFlag)
						return
					end
				end
			end
		elseif onLeave then
			local v149_ = g_currentMission:getNodeObject(otherActorId)
			if v149_ == nil then
				v149_ = g_currentMission.nodeToObject[otherActorId]
			end
			if v149_ ~= nil and v139_.pendingDynamicMountObjects[v149_] ~= nil then
				local v150_ = v139_.pendingDynamicMountObjects[v149_] - 1
				if v150_ == 0 then
					v139_.pendingDynamicMountObjects[v149_] = nil
					if v139_.dynamicMountedObjects[v149_] ~= nil then
						self:removeDynamicMountedObject(v149_, false)
						v149_:unmountDynamic()
						if v149_.additionalDynamicMountJointNode ~= nil then
							delete(v149_.additionalDynamicMountJointNode)
							v149_.additionalDynamicMountJointNode = nil
						end
					end
					self:raiseDirtyFlags(v139_.dynamicMountedObjectsDirtyFlag)
					return
				end
				v139_.pendingDynamicMountObjects[v149_] = v150_
			end
		end
	end
end

function DynamicMountAttacher:getAllowDynamicMountFillLevelInfo()
	return true
end

-- Local values: openMountType, closedMountType
function DynamicMountAttacher:loadDynamicMountGrabFromXML(xmlFile, key, entry)
	local v154_ = self.xmlFile:getValue(key .. "#openMountType")
	entry.openMountType = Utils.getNoNil(DynamicMountUtil[v154_], DynamicMountUtil.TYPE_FORK)
	local v155_ = self.xmlFile:getValue(key .. "#closedMountType")
	entry.closedMountType = Utils.getNoNil(DynamicMountUtil[v155_], DynamicMountUtil.TYPE_AUTO_ATTACH_XYZ)
	entry.currentMountType = entry.openMountType
	return true
end

function DynamicMountAttacher:getIsDynamicMountGrabOpened(grab)
	return true
end

function DynamicMountAttacher:getDynamicMountTimeToMount()
	return self.spec_dynamicMountAttacher.dynamicMountAttacherTimeToMount
end

function DynamicMountAttacher:getHasDynamicMountedObjects()
	return next(self.spec_dynamicMountAttacher.dynamicMountedObjects) ~= nil
end

-- Local values: spec, object, _, trigger, couldMount
function DynamicMountAttacher:forceDynamicMountPendingObjects(onlyBales)
	if self:getAllowDynamicMountObjects() then
		local v160_ = self.spec_dynamicMountAttacher
		for v161_, _ in pairs(v160_.pendingDynamicMountObjects) do
			if v160_.dynamicMountedObjects[v161_] == nil and (not onlyBales or v161_:isa(Bale)) then
				local v162_ = v160_.dynamicMountAttacherTrigger
				if v161_:mountDynamic(self, v162_.rootNode, v162_.jointNode, v162_.mountType, v162_.forceAcceleration) then
					self:addDynamicMountedObject(v161_)
				end
			end
		end
	end
end

-- Local values: spec, object, _
function DynamicMountAttacher:forceUnmountDynamicMountedObjects()
	local v164_ = self.spec_dynamicMountAttacher
	for v165_, _ in pairs(v164_.dynamicMountedObjects) do
		self:removeDynamicMountedObject(v165_, false)
		v165_:unmountDynamic()
		if v165_.additionalDynamicMountJointNode ~= nil then
			delete(v165_.additionalDynamicMountJointNode)
			v165_.additionalDynamicMountJointNode = nil
		end
	end
end

-- Local values: spec, _, fork
function DynamicMountAttacher:getDynamicMountAttacherSettingsByNode(node)
	local v168_ = self.spec_dynamicMountAttacher
	for _, v169_ in pairs(v168_.forks) do
		if v169_.node == node then
			return v169_.mountType, v169_.forceLimitScale
		end
	end
	return DynamicMountUtil.TYPE_FORK, 1
end

-- Local values: spec
function DynamicMountAttacher:dynamicMountLockPositionOverlapCallback(transformId)
	if g_currentMission.nodeToObject[transformId] ~= nil or g_currentMission.players[transformId] ~= nil then
		local v172_ = self.spec_dynamicMountAttacher
		if g_currentMission.nodeToObject[transformId] ~= self and g_currentMission.nodeToObject[transformId] ~= v172_.overlapBoxIgnoreVehicle then
			v172_.overlapBoxHasCollision = true
		end
	end
end

-- Local values: spec, object, _, fillType, fillLevel, capacity
function DynamicMountAttacher:getFillLevelInformation(superFunc, display)
	superFunc(self, display)
	if self:getAllowDynamicMountFillLevelInfo() then
		local v176_ = self.spec_dynamicMountAttacher
		for v177_, _ in pairs(v176_.dynamicMountedObjects) do
			if v177_.getFillLevelInformation == nil then
				if v177_.getFillLevel ~= nil and v177_.getFillType ~= nil then
					local v178_ = v177_:getFillType()
					local v179_ = v177_:getFillLevel()
					local v180_
					if v177_.getCapacity == nil then
						v180_ = v179_
					else
						v180_ = v177_:getCapacity()
					end
					display:addFillLevel(v178_, v179_, v180_)
				end
			else
				v177_:getFillLevelInformation(display)
			end
		end
	end
end

-- Local values: spec, dynamicMountedObject, _
function DynamicMountAttacher:getHasObjectMounted(superFunc, object)
	if superFunc(self, object) then
		return true
	end
	local v184_ = self.spec_dynamicMountAttacher
	for v185_, _ in pairs(v184_.dynamicMountedObjects) do
		if v185_ == object then
			return true
		end
		if v185_.getHasObjectMounted ~= nil and v185_:getHasObjectMounted(object) then
			return true
		end
	end
	return false
end

function DynamicMountAttacher:loadExtraDependentParts(superFunc, xmlFile, baseName, entry)
	if not superFunc(self, xmlFile, baseName, entry) then
		return false
	end
	entry.updateDynamicMountAttacher = xmlFile:getValue(baseName .. ".dynamicMountAttacher#value")
	return true
end

-- Local values: spec, object, _
function DynamicMountAttacher:updateExtraDependentParts(superFunc, part, dt)
	superFunc(self, part, dt)
	if self.isServer and (part.updateDynamicMountAttacher ~= nil and part.updateDynamicMountAttacher) then
		local v195_ = self.spec_dynamicMountAttacher
		for v196_, _ in pairs(v195_.dynamicMountedObjects) do
			setJointFrame(v196_.dynamicMountJointIndex, 0, v196_.dynamicMountJointNode)
		end
	end
end

-- Local values: spec, object, _, object, _
function DynamicMountAttacher:getIsAttachedTo(superFunc, vehicle)
	if superFunc(self, vehicle) then
		return true
	end
	local v200_ = self.spec_dynamicMountAttacher
	for v201_, _ in pairs(v200_.dynamicMountedObjects) do
		if v201_ == vehicle then
			return true
		end
	end
	for v202_, _ in pairs(v200_.pendingDynamicMountObjects) do
		if v202_ == vehicle then
			return true
		end
	end
	return false
end

-- Local values: additionalMass, spec, object, _
function DynamicMountAttacher:getAdditionalComponentMass(superFunc, component)
	local v206_ = superFunc(self, component)
	local v207_ = self.spec_dynamicMountAttacher
	if v207_.dynamicMountAttacherTrigger ~= nil and (v207_.transferMass and v207_.dynamicMountAttacherTrigger.component == component.node) then
		for v208_, _ in pairs(v207_.dynamicMountedObjects) do
			if v208_.getAllowComponentMassReduction ~= nil and v208_:getAllowComponentMassReduction() then
				v206_ = v206_ + (v208_:getDefaultMass() - 0.1)
			end
		end
	end
	return v206_
end

-- Local values: spec
function DynamicMountAttacher:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	if self.spec_dynamicMountAttacher.allowFoldingWhileMounted or not self:getHasDynamicMountedObjects() then
		return superFunc(self, direction, onAiTurnOn)
	else
		return false, g_i18n:getText("warning_toolIsFull")
	end
end

function DynamicMountAttacher:loadMovingToolFromXML(superFunc, xmlFile, key, entry)
	if not superFunc(self, xmlFile, key, entry) then
		return false
	end
	entry.dynamicMountAttacherAllowedMounted = xmlFile:getValue(key .. ".dynamicMountAttacher#allowedMounted", true)
	return true
end

function DynamicMountAttacher:getIsMovingToolActive(superFunc, movingTool)
	if movingTool.dynamicMountAttacherAllowedMounted or next(self.spec_dynamicMountAttacher.dynamicMountedObjects) == nil then
		return superFunc(self, movingTool)
	else
		return false
	end
end

-- Local values: objSpec
function DynamicMountAttacher:onPreAttachImplement(object, inputJointDescIndex, jointDescIndex, loadFromSavegame)
	local v223_ = object.spec_dynamicMountAttacher
	if v223_ ~= nil and self.isServer then
		v223_.pendingDynamicMountObjects[self] = nil
		if v223_.dynamicMountedObjects[self] ~= nil then
			object:removeDynamicMountedObject(self, false)
			self:unmountDynamic()
			if object.additionalDynamicMountJointNode ~= nil then
				delete(object.additionalDynamicMountJointNode)
				object.additionalDynamicMountJointNode = nil
			end
		end
	end
end

-- Local values: spec, timeToMount, object, _, object, _, objectName, objectColor, objectNode, x, y, z
function DynamicMountAttacher:updateDebugValues(values)
	local v226_ = self.spec_dynamicMountAttacher
	if self.isServer then
		local v227_ = self.lastMoveTime + v226_.dynamicMountAttacherTimeToMount - g_currentMission.time
		local v228_ = {
			["name"] = "timeToMount:",
			["value"] = string.format("%d", v227_)
		}
		table.insert(values, v228_)
		for v229_, _ in pairs(v226_.pendingDynamicMountObjects) do
			local v230_ = {
				["name"] = "pendingDynamicMountObject:"
			}
			local v231_ = string.format
			local v232_ = v229_.configFileNameClean or v229_
			local v233_ = v229_.lastMoveTime + v226_.dynamicMountAttacherTimeToMount - g_currentMission.time
			v230_.value = v231_("%s timeToMount: %d", v232_, (math.max(v233_, 0)))
			table.insert(values, v230_)
		end
		for v234_, _ in pairs(v226_.dynamicMountedObjects) do
			local v235_ = v234_.configFileNameClean
			if not v235_ then
				if v234_.xmlFilename then
					v235_ = Utils.getFilenameFromPath(v234_.xmlFilename) or v234_
				else
					v235_ = v234_
				end
			end
			local v236_ = DebugUtil.tableToColor(v234_)
			local v237_ = {
				["name"] = "dynamicMountedObjects:",
				["value"] = string.format("%s jointIndex:%s mountOffset:%.3f triggerCount:%s", v235_, v234_.dynamicMountJointIndex, v234_.dynamicMountJointNodeDynamicMountOffset or -1, v234_.dynamicMountObjectTriggerCount),
				["color"] = v236_
			}
			table.insert(values, v237_)
			local v238_ = v234_.nodeId or v234_.rootNode
			if v238_ ~= nil then
				local v239_, v240_, v241_ = getWorldTranslation(v238_)
				drawDebugPoint(v239_, v240_, v241_, v236_[1], v236_[2], v236_[3], v236_[4], false)
			end
		end
	end
	local v242_ = {
		["name"] = "allowMountObjects:",
		["value"] = string.format("%s", self:getAllowDynamicMountObjects())
	}
	table.insert(values, v242_)
	if v226_.dynamicMountAttacherGrab ~= nil then
		local v243_ = {
			["name"] = "grabOpened:",
			["value"] = string.format("%s", self:getIsDynamicMountGrabOpened(v226_.dynamicMountAttacherGrab))
		}
		table.insert(values, v243_)
	end
end
