HookLiftContainer = {}

function HookLiftContainer.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(Attachable, specializations)
	end
	return v2_
end
function HookLiftContainer.initSpecialization()
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("HookLiftContainer")
	v3_:register(XMLValueType.BOOL, "vehicle.hookLiftContainer#tiltContainerOnDischarge", "Tilt container on discharge", true)
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.hookLiftContainer.visualRollReference#startNode", "Reference nodes that represent the bottom of the container")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.hookLiftContainer.visualRollReference#endNode", "Reference nodes that represent the bottom of the container")
	ObjectChangeUtil.registerObjectChangeXMLPaths(v3_, "vehicle.hookLiftContainer.containerLock")
	v3_:setXMLSpecializationType()
end

function HookLiftContainer.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "onHookLiftContainerLockChanged", HookLiftContainer.onHookLiftContainerLockChanged)
end

function HookLiftContainer.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanDischargeToObject", HookLiftContainer.getCanDischargeToObject)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanDischargeToGround", HookLiftContainer.getCanDischargeToGround)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "isDetachAllowed", HookLiftContainer.isDetachAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", HookLiftContainer.addToPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", HookLiftContainer.removeFromPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getBrakeForce", HookLiftContainer.getBrakeForce)
end

function HookLiftContainer.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", HookLiftContainer)
	SpecializationUtil.registerEventListener(vehicleType, "onStartTipping", HookLiftContainer)
	SpecializationUtil.registerEventListener(vehicleType, "onStopTipping", HookLiftContainer)
end

-- Local values: spec
function HookLiftContainer:onLoad(savegame)
	local v8_ = self.spec_hookLiftContainer
	v8_.tiltContainerOnDischarge = self.xmlFile:getValue("vehicle.hookLiftContainer#tiltContainerOnDischarge", true)
	v8_.visualReferenceNodeStart = self.xmlFile:getValue("vehicle.hookLiftContainer.visualRollReference#startNode", nil, self.components, self.i3dMappings)
	v8_.visualReferenceNodeEnd = self.xmlFile:getValue("vehicle.hookLiftContainer.visualRollReference#endNode", nil, self.components, self.i3dMappings)
	v8_.containerLockChangeObjects = {}
	ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, "vehicle.hookLiftContainer.containerLock", v8_.containerLockChangeObjects, self.components, self)
	ObjectChangeUtil.setObjectChanges(v8_.containerLockChangeObjects, false, self, self.setMovingToolDirty)
	if self.setConnectionHosesActive ~= nil then
		self:setConnectionHosesActive(false)
	end
end

-- Local values: attacherVehicle
function HookLiftContainer:getCanDischargeToObject(superFunc, dischargeNode)
	local v12_ = self:getAttacherVehicle()
	if v12_ == nil or (v12_.getIsTippingAllowed == nil or v12_:getIsTippingAllowed()) then
		return superFunc(self, dischargeNode)
	else
		return false
	end
end

-- Local values: attacherVehicle
function HookLiftContainer:getCanDischargeToGround(superFunc, dischargeNode)
	local v16_ = self:getAttacherVehicle()
	if v16_ == nil or (v16_.getIsTippingAllowed == nil or v16_:getIsTippingAllowed()) then
		return superFunc(self, dischargeNode)
	else
		return false
	end
end

-- Local values: attacherVehicle
function HookLiftContainer:isDetachAllowed(superFunc)
	local v19_ = self:getAttacherVehicle()
	if v19_ == nil or (v19_.getCanDetachContainer == nil or v19_:getCanDetachContainer()) then
		return superFunc(self)
	else
		return false, nil
	end
end

-- Local values: spec, attacherVehicle
function HookLiftContainer:onStartTipping(tipSideIndex)
	local v21_ = self.spec_hookLiftContainer
	local v22_ = self:getAttacherVehicle()
	if v22_ ~= nil and (v22_.startTipping ~= nil and v21_.tiltContainerOnDischarge) then
		v22_:startTipping()
	end
end

-- Local values: spec, attacherVehicle
function HookLiftContainer:onStopTipping()
	local v24_ = self.spec_hookLiftContainer
	local v25_ = self:getAttacherVehicle()
	if v25_ ~= nil and (v25_.stopTipping ~= nil and v24_.tiltContainerOnDischarge) then
		v25_:stopTipping()
	end
end

-- Local values: spec, attacherVehicle, implement
function HookLiftContainer:onHookLiftContainerLockChanged(state)
	local v28_ = self.spec_hookLiftContainer
	if self.setConnectionHosesActive ~= nil and self:getAttacherVehicle():getImplementByObject(self) ~= nil then
		self:setConnectionHosesActive(state)
	end
	ObjectChangeUtil.setObjectChanges(v28_.containerLockChangeObjects, state, self, self.setMovingToolDirty)
end

-- Local values: attacherVehicle
function HookLiftContainer:addToPhysics(superFunc)
	if not superFunc(self) then
		return false
	end
	local v31_ = self:getAttacherVehicle()
	if v31_ ~= nil and v31_.setHookLiftContainerPhysicsState ~= nil then
		v31_:setHookLiftContainerPhysicsState(self, true)
	end
	return true
end

-- Local values: attacherVehicle
function HookLiftContainer:removeFromPhysics(superFunc)
	local v34_ = self:getAttacherVehicle()
	if v34_ ~= nil and v34_.setHookLiftContainerPhysicsState ~= nil then
		v34_:setHookLiftContainerPhysicsState(self, false)
	end
	return superFunc(self) and true or false
end

function HookLiftContainer:getBrakeForce(superFunc)
	return self:getAttacherVehicle() ~= nil and 0 or superFunc(self)
end
