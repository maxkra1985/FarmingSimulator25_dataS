BaleGrab = {}
BaleGrab.CLOSE_TIMER = 250

function BaleGrab.prerequisitesPresent(specializations)
	return true
end
function BaleGrab.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("BaleGrab")
	v1_:register(XMLValueType.FLOAT, "vehicle.baleGrab#minSizeRound", "Min. size of round bales (for shop display only)")
	v1_:register(XMLValueType.FLOAT, "vehicle.baleGrab#maxSizeRound", "Max. size of round bales (for shop display only)")
	v1_:register(XMLValueType.FLOAT, "vehicle.baleGrab#minSizeSquare", "Min. size of square bales (for shop display only)")
	v1_:register(XMLValueType.FLOAT, "vehicle.baleGrab#maxSizeSquare", "Max. size of square bales (for shop display only)")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.baleGrab#triggerNode", "Trigger node")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.baleGrab#rootNode", "Root node", "Main component")
	v1_:register(XMLValueType.STRING, "vehicle.baleGrab#dynamicMountType", "Dynamic mount type", "TYPE_FIX_ATTACH")
	v1_:register(XMLValueType.FLOAT, "vehicle.baleGrab#forceAcceleration", "Force acceleration", 20)
	v1_:register(XMLValueType.INT, "vehicle.baleGrab.grab(?)#componentJointIndex", "Component joint index of grab")
	v1_:register(XMLValueType.FLOAT, "vehicle.baleGrab.grab(?)#dampingFactor", "Factor that is applied to the component joint rot/trans damping as soon as a bale is mounted", 20)
	v1_:register(XMLValueType.INT, "vehicle.baleGrab.grab(?)#rotationAxis", "Rotation axis of component joint to detect if the grab is rotating out of the limits (only rotation or translation axis can be used)")
	v1_:register(XMLValueType.ANGLE, "vehicle.baleGrab.grab(?)#rotationThreshold", "Threshold to mount the bale if the component is this angle off the component joint rotation", 5)
	v1_:register(XMLValueType.INT, "vehicle.baleGrab.grab(?)#translationAxis", "Translation axis of component joint to detect if the grab is translating out of the limits (only rotation or translation axis can be used)")
	v1_:register(XMLValueType.FLOAT, "vehicle.baleGrab.grab(?)#translationThreshold", "Threshold to mount the bale if the component is this translation off the component joint translation", 0.05)
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.baleGrab.grab(?).movingTool(?)#node", "Node of moving tool to block while limit is exceeded")
	v1_:register(XMLValueType.INT, "vehicle.baleGrab.grab(?).movingTool(?)#closingDirection", "Direction to block the moving tool", 1)
	v1_:setXMLSpecializationType()
	g_storeManager:addSpecType("baleGrabMaxSizeRound", "shopListAttributeIconBaleSizeRound", BaleGrab.loadSpecValueMaxSizeRound, BaleGrab.getSpecValueMaxSizeRound, StoreSpecies.VEHICLE)
	g_storeManager:addSpecType("baleGrabMaxSizeSquare", "shopListAttributeIconBaleSizeSquare", BaleGrab.loadSpecValueMaxSizeSquare, BaleGrab.getSpecValueMaxSizeSquare, StoreSpecies.VEHICLE)
end

function BaleGrab.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "baleGrabTriggerCallback", BaleGrab.baleGrabTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "addDynamicMountedObject", BaleGrab.addDynamicMountedObject)
	SpecializationUtil.registerFunction(vehicleType, "removeDynamicMountedObject", BaleGrab.removeDynamicMountedObject)
	SpecializationUtil.registerFunction(vehicleType, "getIsBaleGrabClosed", BaleGrab.getIsBaleGrabClosed)
	SpecializationUtil.registerFunction(vehicleType, "mountBaleGrabObject", BaleGrab.mountBaleGrabObject)
	SpecializationUtil.registerFunction(vehicleType, "unmountBaleGrabObject", BaleGrab.unmountBaleGrabObject)
end

function BaleGrab.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getMovingToolMoveValue", BaleGrab.getMovingToolMoveValue)
end

function BaleGrab.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", BaleGrab)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", BaleGrab)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", BaleGrab)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", BaleGrab)
end

-- Local values: spec, dynamicMountTypeString
function BaleGrab:onLoad(savegame)
	local v_u_6_ = self.spec_baleGrab
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleGrab#jointType", "vehicle.baleGrab#dynamicMountType")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleGrab#grabRefComponentJointIndex1", "vehicle.baleGrab.grab#componentJointIndex")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleGrab#grabRefComponentJointIndex2", "vehicle.baleGrab.grab#componentJointIndex")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleGrab#rotDiffThreshold1", "vehicle.baleGrab.grab#rotationThreshold")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleGrab#rotDiffThreshold2", "vehicle.baleGrab.grab#rotationThreshold")
	if self.isServer then
		v_u_6_.rootNode = self.xmlFile:getValue("vehicle.baleGrab#rootNode", self.rootNode, self.components, self.i3dMappings)
		v_u_6_.triggerNode = self.xmlFile:getValue("vehicle.baleGrab#triggerNode", nil, self.components, self.i3dMappings)
		if v_u_6_.triggerNode ~= nil then
			if CollisionFlag.getHasMaskFlagSet(v_u_6_.triggerNode, CollisionFlag.DYNAMIC_OBJECT) then
				addTrigger(v_u_6_.triggerNode, "baleGrabTriggerCallback", self)
			else
				Logging.xmlWarning(self.xmlFile, "BaleGrab trigger has no \'TRIGGER_DYNAMIC_OBJECT\' collision bit set!")
			end
			v_u_6_.jointNode = createTransformGroup("balegrabJointNode")
			link(v_u_6_.rootNode, v_u_6_.jointNode)
			v_u_6_.forceAcceleration = self.xmlFile:getValue("vehicle.baleGrab#forceAcceleration", 20)
			local v7_ = self.xmlFile:getValue("vehicle.baleGrab#dynamicMountType", "TYPE_FIX_ATTACH")
			v_u_6_.dynamicMountType = DynamicMountUtil[v7_] or DynamicMountUtil.TYPE_FIX_ATTACH
			v_u_6_.grabs = {}
			self.xmlFile:iterate("vehicle.baleGrab.grab", function(_, p8_)
				-- upvalues: (copy) self, (copy) v_u_6_
				local v_u_9_ = {
					["componentJointIndex"] = self.xmlFile:getValue(p8_ .. "#componentJointIndex")
				}
				if v_u_9_.componentJointIndex == nil then
					Logging.xmlWarning(self.xmlFile, "Missing component joint in \'%s", p8_)
				else
					v_u_9_.dampingFactor = self.xmlFile:getValue(p8_ .. "#dampingFactor", 20)
					v_u_9_.rotationAxis = self.xmlFile:getValue(p8_ .. "#rotationAxis")
					if v_u_9_.rotationAxis == nil then
						v_u_9_.translationAxis = self.xmlFile:getValue(p8_ .. "#translationAxis")
						if v_u_9_.translationAxis == nil then
							Logging.xmlWarning(self.xmlFile, "Missing rotation or translation axis in \'%s", p8_)
						else
							v_u_9_.translationThreshold = self.xmlFile:getValue(p8_ .. "#translationThreshold", 0.05)
						end
					else
						v_u_9_.rotationThreshold = self.xmlFile:getValue(p8_ .. "#rotationThreshold", 5)
					end
					if v_u_9_.rotationAxis ~= nil or v_u_9_.translationAxis then
						v_u_9_.componentJoint = self.componentJoints[v_u_9_.componentJointIndex]
						if v_u_9_.componentJoint == nil then
							Logging.xmlWarning(self.xmlFile, "Invalid component joint index %s in \'%s", v_u_9_.componentJointIndex, p8_)
						else
							v_u_9_.componentJointActor0 = v_u_9_.componentJoint.jointNode
							v_u_9_.componentJointActor1 = v_u_9_.componentJoint.jointNodeActor1
							if v_u_9_.componentJointActor0 == v_u_9_.componentJointActor1 then
								v_u_9_.componentJointActor1 = createTransformGroup("componentJointActor1")
								if self:getParentComponent(v_u_9_.componentJointActor0) == self.components[v_u_9_.componentJoint.componentIndices[1]].node then
									link(self.components[v_u_9_.componentJoint.componentIndices[2]].node, v_u_9_.componentJointActor1)
								else
									link(self.components[v_u_9_.componentJoint.componentIndices[1]].node, v_u_9_.componentJointActor1)
								end
								setWorldTranslation(v_u_9_.componentJointActor1, getWorldTranslation(v_u_9_.componentJointActor0))
								setWorldRotation(v_u_9_.componentJointActor1, getWorldRotation(v_u_9_.componentJointActor0))
							end
							v_u_9_.movingTools = {}
							self.xmlFile:iterate(p8_ .. ".movingTool", function(_, p10_)
								-- upvalues: (ref) self, (copy) v_u_9_
								local v11_ = {
									["node"] = self.xmlFile:getValue(p10_ .. "#node", nil, self.components, self.i3dMappings)
								}
								if v11_.node ~= nil then
									v11_.closingDirection = self.xmlFile:getValue(p10_ .. "#closingDirection")
									local v12_ = v_u_9_.movingTools
									table.insert(v12_, v11_)
								end
							end)
							v_u_9_.lastValues = { 0, 0, 0 }
							v_u_9_.isClosed = false
							v_u_9_.closeTimer = 0
							v_u_9_.jointChecksum = 0
							local v13_ = v_u_6_.grabs
							table.insert(v13_, v_u_9_)
						end
					end
				end
			end)
		end
		v_u_6_.lastAllGrabsClosed = false
		v_u_6_.dynamicMountedObjects = {}
		v_u_6_.pendingDynamicMountObjects = {}
	end
	if v_u_6_.triggerNode == nil then
		SpecializationUtil.removeEventListener(self, "onPostLoad", BaleGrab)
		SpecializationUtil.removeEventListener(self, "onDelete", BaleGrab)
		SpecializationUtil.removeEventListener(self, "onUpdateTick", BaleGrab)
	end
end

-- Local values: spec, i, grab, toolIndex, movingToolData
function BaleGrab:onPostLoad(savegame)
	local v15_ = self.spec_baleGrab
	for v16_ = 1, #v15_.grabs do
		local v17_ = v15_.grabs[v16_]
		for v18_ = #v17_.movingTools, 1, -1 do
			local v19_ = v17_.movingTools[v18_]
			v19_.movingTool = self:getMovingToolByNode(v19_.node)
			if v19_.movingTool == nil then
				table.remove(v17_.movingTools, v18_)
			end
		end
	end
end

-- Local values: spec, object, _, object, _
function BaleGrab:onDelete()
	local v21_ = self.spec_baleGrab
	if v21_.pendingDynamicMountObjects ~= nil then
		for v22_, _ in pairs(v21_.pendingDynamicMountObjects) do
			if v22_.removeDeleteListener ~= nil then
				v22_:removeDeleteListener(self, BaleGrab.onPendingObjectDelete)
			end
			if v22_.removeMountStateChangeListener ~= nil then
				v22_:removeMountStateChangeListener(self, BaleGrab.onPendingObjectMountStateChanged)
			end
		end
		table.clear(v21_.pendingDynamicMountObjects)
	end
	if v21_.dynamicMountedObjects ~= nil then
		for v23_, _ in pairs(v21_.dynamicMountedObjects) do
			self:unmountBaleGrabObject(v23_)
		end
		table.clear(v21_.dynamicMountedObjects)
	end
	if v21_.triggerNode ~= nil then
		removeTrigger(v21_.triggerNode)
		v21_.triggerNode = nil
	end
end

-- Local values: spec, allGrabsClosed, i, grab, isClosed, x, y, z, rx, ry, rz, jointChecksum, x, y, z, rx, ry, rz, object, _, i, grab, axis, object, _, i, grab, axis
function BaleGrab:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isServer then
		local v26_ = self.spec_baleGrab
		local v27_ = next(v26_.pendingDynamicMountObjects) ~= nil
		for v28_ = 1, #v26_.grabs do
			local v29_ = v26_.grabs[v28_]
			if self:getIsBaleGrabClosed(v29_) then
				local v30_ = v29_.closeTimer - dt
				v29_.closeTimer = math.max(v30_, 0)
			else
				v29_.closeTimer = BaleGrab.CLOSE_TIMER
			end
			if v29_.closeTimer == 0 == v29_.isClosed then
				if v29_.closeTimer == BaleGrab.CLOSE_TIMER then
					local v31_, v32_, v33_ = getTranslation(v29_.componentJointActor0)
					local v34_, v35_, v36_ = getRotation(v29_.componentJointActor0)
					v29_.jointChecksum = v31_ + v32_ + v33_ + v34_ + v35_ + v36_
				end
			else
				local v37_, v38_, v39_ = getTranslation(v29_.componentJointActor0)
				local v40_, v41_, v42_ = getRotation(v29_.componentJointActor0)
				local v43_ = v37_ + v38_ + v39_ + v40_ + v41_ + v42_
				if v29_.jointChecksum == v43_ then
					if next(v26_.pendingDynamicMountObjects) == nil or v29_.closeTimer ~= 0 then
						if next(v26_.pendingDynamicMountObjects) == nil and v29_.closeTimer == BaleGrab.CLOSE_TIMER then
							v29_.isClosed = v29_.closeTimer == 0
						end
					else
						v29_.isClosed = v29_.closeTimer == 0
					end
				else
					v29_.jointChecksum = v43_
					v29_.isClosed = v29_.closeTimer == 0
				end
			end
			if not v29_.isClosed then
				v27_ = false
			end
		end
		if v27_ ~= v26_.lastAllGrabsClosed then
			v26_.lastAllGrabsClosed = v27_
			if v27_ then
				for v44_, _ in pairs(v26_.pendingDynamicMountObjects) do
					if v26_.dynamicMountedObjects[v44_] == nil and v44_.dynamicMountType == MountableObject.MOUNT_TYPE_NONE then
						self:unmountBaleGrabObject(v44_)
						self:mountBaleGrabObject(v44_)
					end
				end
				for v45_ = 1, #v26_.grabs do
					local v46_ = v26_.grabs[v45_]
					for v47_ = 1, 3 do
						if v46_.rotationAxis == nil then
							setJointTranslationLimitSpring(v46_.componentJoint.jointIndex, v47_ - 1, v46_.componentJoint.transLimitSpring[v47_], v46_.componentJoint.transLimitDamping[v47_] * v46_.dampingFactor)
						else
							setJointRotationLimitSpring(v46_.componentJoint.jointIndex, v47_ - 1, v46_.componentJoint.rotLimitSpring[v47_], v46_.componentJoint.rotLimitDamping[v47_] * v46_.dampingFactor)
						end
					end
				end
				return
			end
			for v48_, _ in pairs(v26_.dynamicMountedObjects) do
				self:unmountBaleGrabObject(v48_)
			end
			for v49_ = 1, #v26_.grabs do
				local v50_ = v26_.grabs[v49_]
				for v51_ = 1, 3 do
					if v50_.rotationAxis == nil then
						setJointTranslationLimitSpring(v50_.componentJoint.jointIndex, v51_ - 1, v50_.componentJoint.transLimitSpring[v51_], v50_.componentJoint.transLimitDamping[v51_])
					else
						setJointRotationLimitSpring(v50_.componentJoint.jointIndex, v51_ - 1, v50_.componentJoint.rotLimitSpring[v51_], v50_.componentJoint.rotLimitDamping[v51_])
					end
				end
			end
		end
	end
end

-- Local values: move, spec, i, grab, toolIndex, movingToolData
function BaleGrab:getMovingToolMoveValue(superFunc, movingTool)
	local v55_ = superFunc(self, movingTool)
	local v56_ = self.spec_baleGrab
	for v57_ = 1, #v56_.grabs do
		local v58_ = v56_.grabs[v57_]
		for v59_ = 1, #v58_.movingTools do
			local v60_ = v58_.movingTools[v59_]
			if v60_.movingTool == movingTool then
				v60_.lastMoveValue = v55_
				if v58_.closeTimer < BaleGrab.CLOSE_TIMER and (next(v56_.pendingDynamicMountObjects) ~= nil and math.sign(v55_) == v60_.closingDirection) then
					v55_ = 0
				end
			end
		end
	end
	return v55_
end

-- Local values: spec
function BaleGrab:addDynamicMountedObject(object)
	self.spec_baleGrab.dynamicMountedObjects[object] = object
end

-- Local values: spec
function BaleGrab:removeDynamicMountedObject(object, isDeleting)
	local v66_ = self.spec_baleGrab
	if object.dynamicMountType == MountableObject.MOUNT_TYPE_DYNAMIC then
		object:unmountDynamic()
	end
	v66_.dynamicMountedObjects[object] = nil
	if isDeleting then
		v66_.pendingDynamicMountObjects[object] = nil
	end
end

-- Local values: spec
function BaleGrab:onPendingObjectDelete(object)
	local v69_ = self.spec_baleGrab
	if v69_.pendingDynamicMountObjects[object] ~= nil or v69_.dynamicMountedObjects[object] ~= nil then
		self:removeDynamicMountedObject(object, true)
	end
end

-- Local values: spec
function BaleGrab:onPendingObjectMountStateChanged(object, mountState, mountObject)
	if mountState ~= MountableObject.MOUNT_TYPE_NONE and mountObject ~= self then
		local v74_ = self.spec_baleGrab
		if v74_.pendingDynamicMountObjects[object] ~= nil or v74_.dynamicMountedObjects[object] ~= nil then
			self:removeDynamicMountedObject(object, true)
		end
	end
end

-- Local values: spec, object, object
function BaleGrab:baleGrabTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	local v79_ = self.spec_baleGrab
	if onEnter then
		local v80_ = g_currentMission:getNodeObject(otherActorId)
		if v80_ ~= nil and (v80_ ~= self and (v80_.getSupportsMountDynamic ~= nil and (v80_:getSupportsMountDynamic() and (v80_.addMountStateChangeListener ~= nil and (v80_.nodeId ~= nil or v80_.rootNode ~= 0))))) then
			v79_.pendingDynamicMountObjects[v80_] = (v79_.pendingDynamicMountObjects[v80_] or 0) + 1
			if v79_.pendingDynamicMountObjects[v80_] == 1 then
				v80_:addDeleteListener(self, BaleGrab.onPendingObjectDelete)
				v80_:addMountStateChangeListener(self, BaleGrab.onPendingObjectMountStateChanged)
				return
			end
		end
	elseif onLeave then
		local v81_ = g_currentMission:getNodeObject(otherActorId)
		if v81_ ~= nil and v79_.pendingDynamicMountObjects[v81_] ~= nil then
			v79_.pendingDynamicMountObjects[v81_] = v79_.pendingDynamicMountObjects[v81_] - 1
			if v79_.pendingDynamicMountObjects[v81_] <= 0 then
				self:removeDynamicMountedObject(v81_, true)
				v81_:removeDeleteListener(self, BaleGrab.onPendingObjectDelete)
				v81_:removeMountStateChangeListener(self, BaleGrab.onPendingObjectMountStateChanged)
			end
		end
	end
end

-- Local values: toolIndex, movingToolData, state
function BaleGrab:getIsBaleGrabClosed(grab)
	for v84_ = 1, #grab.movingTools do
		local v85_ = grab.movingTools[v84_]
		local v86_ = Cylindered.getMovingToolState(self, v85_.movingTool)
		if v85_.closingDirection > 0 then
			if v86_ < 0.01 then
				return false
			end
		elseif v86_ > 0.99 then
			return false
		end
	end
	if grab.rotationAxis == nil then
		if grab.translationAxis ~= nil then
			local v87_ = grab.lastValues
			local v88_ = grab.lastValues
			local v89_ = grab.lastValues
			local v90_, v91_, v92_ = localToLocal(grab.componentJointActor1, grab.componentJointActor0, 0, 0, 0)
			v87_[1] = v90_
			v88_[2] = v91_
			v89_[3] = v92_
			if grab.translationThreshold > 0 then
				if grab.lastValues[grab.translationAxis] > grab.translationThreshold then
					return true
				end
			elseif grab.lastValues[grab.translationAxis] < grab.translationThreshold then
				return true
			end
		end
	else
		local v93_ = grab.lastValues
		local v94_ = grab.lastValues
		local v95_ = grab.lastValues
		local v96_, v97_, v98_ = localRotationToLocal(grab.componentJointActor1, grab.componentJointActor0, 0, 0, 0)
		v93_[1] = v96_
		v94_[2] = v97_
		v95_[3] = v98_
		if grab.rotationThreshold > 0 then
			if grab.lastValues[grab.rotationAxis] > grab.rotationThreshold then
				return true
			end
		elseif grab.lastValues[grab.rotationAxis] < grab.rotationThreshold then
			return true
		end
	end
	return false
end

-- Local values: spec, rootNode, x, y, z, i
function BaleGrab:mountBaleGrabObject(object)
	local v101_ = self.spec_baleGrab
	local v102_ = object.nodeId or object.rootNode
	local v103_, v104_, v105_ = localToWorld(v102_, getCenterOfMass(v102_))
	setWorldTranslation(v101_.jointNode, v103_, v104_, v105_)
	if not object:mountDynamic(self, v101_.rootNode, v101_.jointNode, v101_.dynamicMountType, v101_.forceAcceleration) then
		return false
	end
	for v106_ = 1, 3 do
		setJointRotationLimitSpring(object.dynamicMountJointIndex, v106_ - 1, 10000, 10)
		setJointTranslationLimitSpring(object.dynamicMountJointIndex, v106_ - 1, 10000, 10)
	end
	self:addDynamicMountedObject(object)
	return true
end

function BaleGrab:unmountBaleGrabObject(object)
	self:removeDynamicMountedObject(object, false)
	return true
end

-- Local values: spec, i, grab, isClosed, isClosed, toolIndex, movingToolData, lastMovingDirection, directionStr, blockStr, object, numShapes, rootNode, state
function BaleGrab:updateDebugValues(values)
	if self.isServer then
		local v111_ = self.spec_baleGrab
		for v112_ = 1, #v111_.grabs do
			local v113_ = v111_.grabs[v112_]
			if v113_.rotationAxis == nil then
				if v113_.translationAxis ~= nil then
					local v114_ = false
					local v115_ = v113_.lastValues
					local v116_ = v113_.lastValues
					local v117_ = v113_.lastValues
					local v118_, v119_, v120_ = localToLocal(v113_.componentJointActor1, v113_.componentJointActor0, 0, 0, 0)
					v115_[1] = v118_
					v116_[2] = v119_
					v117_[3] = v120_
					local v121_
					if v113_.translationThreshold > 0 then
						v121_ = v113_.lastValues[v113_.translationAxis] > v113_.translationThreshold and true or v114_
					else
						v121_ = v113_.lastValues[v113_.translationAxis] < v113_.translationThreshold and true or v114_
					end
					local v122_ = {
						["name"] = string.format("grab (trans - %s):", getName(v113_.componentJointActor0)),
						["value"] = string.format("offset: %.3f / %.3f | state: %s (t %d)", v113_.lastValues[v113_.translationAxis], v113_.translationThreshold, v121_ and "closed" or "open", v113_.closeTimer)
					}
					table.insert(values, v122_)
				end
			else
				local v123_ = false
				local v124_ = v113_.lastValues
				local v125_ = v113_.lastValues
				local v126_ = v113_.lastValues
				local v127_, v128_, v129_ = localRotationToLocal(v113_.componentJointActor1, v113_.componentJointActor0, 0, 0, 0)
				v124_[1] = v127_
				v125_[2] = v128_
				v126_[3] = v129_
				local v130_
				if v113_.rotationThreshold > 0 then
					v130_ = v113_.lastValues[v113_.rotationAxis] > v113_.rotationThreshold and true or v123_
				else
					v130_ = v113_.lastValues[v113_.rotationAxis] < v113_.rotationThreshold and true or v123_
				end
				local v131_ = {
					["name"] = string.format("grab (rot - %s):", getName(v113_.componentJointActor0))
				}
				local v132_ = string.format
				local v133_ = v113_.lastValues[v113_.rotationAxis]
				local v134_ = math.deg(v133_)
				local v135_ = v113_.rotationThreshold
				v131_.value = v132_("offset: %.1fdeg / %.1fdeg | state: %s (t %d)", v134_, math.deg(v135_), v130_ and "closed" or "open", v113_.closeTimer)
				table.insert(values, v131_)
			end
			for v136_ = 1, #v113_.movingTools do
				local v137_ = v113_.movingTools[v136_]
				local v138_ = v137_.lastMoveValue
				local v139_ = math.sign(v138_)
				local v140_ = v139_ == v137_.closingDirection and "closing" or (v139_ == 0 and "none" or "opening")
				local v141_ = v139_ == v137_.closingDirection and (v113_.closeTimer < BaleGrab.CLOSE_TIMER and next(v111_.pendingDynamicMountObjects) ~= nil) and " BLOCKED" or ""
				local v142_ = {
					["name"] = "movingTool:",
					["value"] = string.format("%s | direction: %s%s", getName(v137_.movingTool.node), v140_, v141_)
				}
				table.insert(values, v142_)
			end
		end
		table.insert(values, {
			["name"] = "--",
			["value"] = "--"
		})
		for v143_, v144_ in pairs(v111_.pendingDynamicMountObjects) do
			local v145_ = v143_.nodeId or v143_.rootNode
			local v146_ = {
				["name"] = v111_.dynamicMountedObjects[v143_] == nil and "<> Pending    " or ">< Mounted    ",
				["value"] = string.format("%s (id %d, numShapes %d)", getName(v145_), v145_, v144_)
			}
			table.insert(values, v146_)
		end
	end
end

-- Local values: sizeData
function BaleGrab.loadSpecValueMaxSize(xmlFile, minKey, maxKey)
	local v150_ = {
		["minSize"] = MathUtil.round(xmlFile:getValue(minKey) or 0, 2),
		["maxSize"] = MathUtil.round(xmlFile:getValue(maxKey) or 0, 2)
	}
	if v150_.minSize ~= 0 or v150_.maxSize ~= 0 then
		return v150_
	end
end

function BaleGrab.loadSpecValueMaxSizeRound(xmlFile, customEnvironment, baseDir)
	return BaleGrab.loadSpecValueMaxSize(xmlFile, "vehicle.baleGrab#minSizeRound", "vehicle.baleGrab#maxSizeRound")
end

function BaleGrab.loadSpecValueMaxSizeSquare(xmlFile, customEnvironment, baseDir)
	return BaleGrab.loadSpecValueMaxSize(xmlFile, "vehicle.baleGrab#minSizeSquare", "vehicle.baleGrab#maxSizeSquare")
end

-- Local values: spec, minValue, maxValue, unit, size
function BaleGrab.getSpecValueMaxSize(specName, storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	local v157_ = storeItem.specs[specName]
	if v157_ == nil then
		return
	else
		local v158_ = v157_.minSize or v157_.maxSize
		local v159_ = v157_.maxSize or v157_.minSize
		if returnValues == nil or not returnValues then
			local v160_ = g_i18n:getText("unit_cmShort")
			if v159_ == v158_ or (v158_ == 0 or v159_ == 0) then
				return string.format("%d%s", math.max(v158_, v159_) * 100, v160_)
			else
				return string.format("%d%s-%d%s", v158_ * 100, v160_, v159_ * 100, v160_)
			end
		elseif returnRange == true and (v159_ ~= v158_ and (v158_ ~= 0 and v159_ ~= 0)) then
			return v158_ * 100, v159_ * 100, g_i18n:getText("unit_cmShort")
		else
			return math.max(v158_, v159_) * 100, g_i18n:getText("unit_cmShort")
		end
	end
end

function BaleGrab.getSpecValueMaxSizeRound(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	return BaleGrab.getSpecValueMaxSize("baleGrabMaxSizeRound", storeItem, realItem, configurations, saleItem, returnValues, returnRange)
end

function BaleGrab.getSpecValueMaxSizeSquare(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	return BaleGrab.getSpecValueMaxSize("baleGrabMaxSizeSquare", storeItem, realItem, configurations, saleItem, returnValues, returnRange)
end
