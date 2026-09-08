DynamicMountUtil = {}
DynamicMountUtil.TYPE_FORK = 1
DynamicMountUtil.TYPE_AUTO_ATTACH_XZ = 2
DynamicMountUtil.TYPE_AUTO_ATTACH_XYZ = 3
DynamicMountUtil.TYPE_AUTO_ATTACH_Y = 4
DynamicMountUtil.TYPE_FIX_ATTACH = 5

-- Local values: constr, isBreakable, forceLimit, limit, limit, x, y, z, spring, damping
function DynamicMountUtil.mountDynamic(mountable, nodeId, object, objectActorId, jointNode, mountType, forceAcceleration, jointNode2)
	if mountable.dynamicMountObject ~= nil or (nodeId == nil or nodeId == 0) then
		return false
	end
	local v9_ = JointConstructor.new()
	v9_:setActors(objectActorId, nodeId)
	v9_:setJointTransforms(jointNode, jointNode2 or jointNode)
	local v10_ = false
	local v11_
	if mountable.getTotalMass == nil then
		v11_ = forceAcceleration * getMass(nodeId)
	else
		v11_ = forceAcceleration * mountable:getTotalMass()
	end
	if mountType == DynamicMountUtil.TYPE_FORK then
		v9_:setRotationLimit(0, 0, 0)
		v9_:setRotationLimit(1, 0, 0)
		v9_:setRotationLimit(2, 0, 0)
		if mountable.dynamicMountSingleAxisFreeX then
			v9_:setTranslationLimit(0, false, 0, 0)
		else
			local v12_ = mountable.dynamicMountForkXLimit or 0.01
			v9_:setTranslationLimit(0, true, -v12_, v12_)
		end
		if mountable.dynamicMountSingleAxisFreeY then
			v9_:setTranslationLimit(1, false, 0, 0)
		else
			local v13_ = mountable.dynamicMountForkYLimit or 0.01
			v9_:setTranslationLimit(1, true, -v13_, v13_)
		end
		v9_:setTranslationLimit(2, false, 0, 0)
		v9_:setLinearDrive(2, false, true, 0, 0, v11_, 0, 0)
		v9_:setEnableCollision(true)
	elseif mountType == DynamicMountUtil.TYPE_AUTO_ATTACH_XZ or (mountType == DynamicMountUtil.TYPE_AUTO_ATTACH_XYZ or mountType == DynamicMountUtil.TYPE_AUTO_ATTACH_Y) then
		local v14_, v15_, v16_ = getWorldTranslation(nodeId)
		v9_:setJointWorldPositions(v14_, v15_, v16_, v14_, v15_, v16_)
		v9_:setBreakable(v11_, v11_)
		v10_ = true
		if mountType == DynamicMountUtil.TYPE_AUTO_ATTACH_XZ then
			v9_:setTranslationLimit(1, false, 0, 0)
			v9_:setRotationLimit(0, 0, 0)
			v9_:setRotationLimit(1, 0, 0)
			v9_:setRotationLimit(2, 0, 0)
		elseif mountType == DynamicMountUtil.TYPE_AUTO_ATTACH_Y then
			v9_:setTranslationLimit(0, false, 0, 0)
			v9_:setTranslationLimit(2, false, 0, 0)
		else
			v9_:setRotationLimit(0, 0, 0)
			v9_:setRotationLimit(1, 0, 0)
			v9_:setRotationLimit(2, 0, 0)
			v9_:setRotationLimitSpring(1000, 10, 1000, 10, 1000, 10)
			v9_:setTranslationLimitSpring(1000, 10, 1000, 10, 1000, 10)
		end
		v9_:setEnableCollision(true)
	else
		if mountType ~= DynamicMountUtil.TYPE_FIX_ATTACH then
			printWarning("Warning: DynamicMountUtil.mountDynamic invalid mountType \'" .. tostring(mountType) .. "\'")
			printCallstack()
			return false
		end
		v9_:setRotationLimit(0, 0, 0)
		v9_:setRotationLimit(1, 0, 0)
		v9_:setRotationLimit(2, 0, 0)
	end
	mountable.dynamicMountJointIndex = v9_:finalize()
	if v10_ then
		local v17_ = mountable.onDynamicMountJointBreak ~= nil
		assert(v17_)
		addJointBreakReport(mountable.dynamicMountJointIndex, "onDynamicMountJointBreak", mountable)
	end
	mountable.dynamicMountObjectActorId = objectActorId
	mountable.dynamicMountObject = object
	mountable.dynamicMountJointNode = jointNode2 or jointNode
	mountable.dynamicMountObject:addDynamicMountedObject(mountable)
	return true
end

function DynamicMountUtil.unmountDynamic(mountable, remove)
	if mountable.dynamicMountJointIndex ~= nil then
		removeJoint(mountable.dynamicMountJointIndex)
		mountable.dynamicMountJointIndex = nil
		mountable.dynamicMountObjectActorId = nil
		if remove == nil or remove then
			mountable.dynamicMountObject:removeDynamicMountedObject(mountable, false)
		end
		mountable.dynamicMountObject = nil
	end
end
