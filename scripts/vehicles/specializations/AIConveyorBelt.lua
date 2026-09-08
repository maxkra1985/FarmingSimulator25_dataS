source("dataS/scripts/vehicles/specializations/events/AIConveyorBeltSetAngleEvent.lua")
AIConveyorBelt = {}

function AIConveyorBelt.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(AIFieldWorker, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(Motorized, specializations)
	end
	return v2_
end
function AIConveyorBelt.initSpecialization()
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("AIConveyorBelt")
	v3_:register(XMLValueType.FLOAT, "vehicle.ai.conveyorBelt#minAngle", "Min angle", 5)
	v3_:register(XMLValueType.FLOAT, "vehicle.ai.conveyorBelt#maxAngle", "Max angle", 45)
	v3_:register(XMLValueType.FLOAT, "vehicle.ai.conveyorBelt#stepSize", "Step size", 5)
	v3_:register(XMLValueType.FLOAT, "vehicle.ai.conveyorBelt#speed", "Speed", 1)
	v3_:register(XMLValueType.INT, "vehicle.ai.conveyorBelt#direction", "Direction", -1)
	v3_:setXMLSpecializationType()
	Vehicle.xmlSchemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).aiConveyorBelt#currentAngle", "Current angle", 45)
end

function AIConveyorBelt.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setAIConveyorBeltAngle", AIConveyorBelt.setAIConveyorBeltAngle)
	SpecializationUtil.registerFunction(vehicleType, "getDirectionAndSpeedToTargetAngle", AIConveyorBelt.getDirectionAndSpeedToTargetAngle)
end

function AIConveyorBelt.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getStartableAIJob", AIConveyorBelt.getStartableAIJob)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getHasStartableAIJob", AIConveyorBelt.getHasStartableAIJob)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanStartFieldWork", AIConveyorBelt.getCanStartFieldWork)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanStartAIVehicle", AIConveyorBelt.getCanStartAIVehicle)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", AIConveyorBelt.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAINeedsTrafficCollisionBox", AIConveyorBelt.getAINeedsTrafficCollisionBox)
end

function AIConveyorBelt.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AIConveyorBelt)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AIConveyorBelt)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", AIConveyorBelt)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", AIConveyorBelt)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AIConveyorBelt)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", AIConveyorBelt)
	SpecializationUtil.registerEventListener(vehicleType, "onAIFieldWorkerStart", AIConveyorBelt)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", AIConveyorBelt)
end

-- Local values: spec
function AIConveyorBelt:onLoad(savegame)
	local v8_ = self.spec_aiConveyorBelt
	v8_.isAllowed = self.xmlFile:hasProperty("vehicle.ai.conveyorBelt")
	v8_.minAngle = self.xmlFile:getValue("vehicle.ai.conveyorBelt#minAngle", 5)
	v8_.maxAngle = self.xmlFile:getValue("vehicle.ai.conveyorBelt#maxAngle", 45)
	v8_.stepSize = self.xmlFile:getValue("vehicle.ai.conveyorBelt#stepSize", 5)
	v8_.currentAngle = v8_.maxAngle
	v8_.minTargetWorldYRot = 0
	v8_.maxTargetWorldYRot = 0
	v8_.currentDirection = 0
	v8_.currentSpeed = 0
	v8_.conveyorJob = g_currentMission.aiJobTypeManager:createJob(AIJobType.CONVEYOR)
	v8_.speed = self.xmlFile:getValue("vehicle.ai.conveyorBelt#speed", 1)
	v8_.direction = self.xmlFile:getValue("vehicle.ai.conveyorBelt#direction", -1)
	if not self.isServer then
		SpecializationUtil.removeEventListener(self, "onUpdate", AIConveyorBelt)
	end
	if not self.isClient then
		SpecializationUtil.removeEventListener(self, "onUpdateTick", AIConveyorBelt)
	end
end

-- Local values: spec
function AIConveyorBelt:onPostLoad(savegame)
	local v11_ = self.spec_aiConveyorBelt
	if savegame ~= nil and not savegame.resetVehicles then
		v11_.currentAngle = savegame.xmlFile:getValue(savegame.key .. ".aiConveyorBelt#currentAngle", v11_.currentAngle)
	end
end

-- Local values: spec
function AIConveyorBelt:saveToXMLFile(xmlFile, key, usedModNames)
	local v15_ = self.spec_aiConveyorBelt
	xmlFile:setValue(key .. "#currentAngle", v15_.currentAngle)
end

function AIConveyorBelt:onReadStream(streamId, connection)
	self:setAIConveyorBeltAngle(streamReadInt8(streamId), true)
end

function AIConveyorBelt:onWriteStream(streamId, connection)
	streamWriteInt8(streamId, self.spec_aiConveyorBelt.currentAngle)
end

-- Local values: spec
function AIConveyorBelt:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self:getIsAIActive() then
		local v22_ = self.spec_aiConveyorBelt
		local v23_, v24_ = self:getDirectionAndSpeedToTargetAngle(v22_.currentDirection, v22_.minTargetWorldYRot, v22_.maxTargetWorldYRot)
		v22_.currentDirection = v23_
		v22_.currentSpeed = v24_
		local v25_ = self:getMotor()
		local v26_ = v22_.currentSpeed * v22_.speed
		v25_:setSpeedLimit((math.abs(v26_)))
		WheelsUtil.updateWheelsPhysics(self, dt, v22_.currentSpeed * v22_.speed * v22_.direction, v22_.currentDirection * v22_.direction, false, true)
	end
end

-- Local values: spec, actionEvent
function AIConveyorBelt:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v29_ = self.spec_aiConveyorBelt
	local v30_ = v29_.actionEvents[InputAction.IMPLEMENT_EXTRA3]
	if v30_ ~= nil then
		g_inputBinding:setActionEventActive(v30_.actionEventId, isActiveForInputIgnoreSelection)
		if isActiveForInputIgnoreSelection then
			g_inputBinding:setActionEventText(v30_.actionEventId, string.format(g_i18n:getText("action_conveyorBeltChangeAngle"), string.format("%.0f", v29_.currentAngle)))
		end
	end
end

function AIConveyorBelt:setAIConveyorBeltAngle(angle, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server == nil then
			g_client:getServerConnection():sendEvent(AIConveyorBeltSetAngleEvent.new(self, angle))
		else
			g_server:broadcastEvent(AIConveyorBeltSetAngleEvent.new(self, angle), nil, nil, self)
		end
	end
	self.spec_aiConveyorBelt.currentAngle = angle
end

-- Local values: dx, _, dz, yRot, angleDifference, speed
function AIConveyorBelt:getDirectionAndSpeedToTargetAngle(direction, minAngle, maxAngle)
	local v38_, _, v39_ = localDirectionToWorld(self.components[1].node, 0, 0, 1)
	local v40_ = MathUtil.getYRotationFromDirection(v38_, v39_)
	local v41_
	if direction > 0 then
		if maxAngle < v40_ then
			return -1, 0
		end
		v41_ = maxAngle - v40_
	elseif direction < 0 then
		if v40_ < minAngle then
			return 1, 0
		end
		v41_ = v40_ - minAngle
	else
		v41_ = 0
	end
	local v42_ = math.deg(v41_) / 2.5
	return direction, math.clamp(v42_, 0.1, 1) * direction
end

function AIConveyorBelt:getCanStartAIVehicle(superFunc)
	if superFunc(self) then
		return self.spec_aiConveyorBelt.isAllowed
	else
		return false
	end
end

function AIConveyorBelt:getCanStartFieldWork()
	return self:getCanStartAIVehicle()
end

-- Local values: spec, conveyorJob, success
function AIConveyorBelt:getStartableAIJob(superFunc)
	if self:getCanStartFieldWork() then
		local v47_ = self.spec_aiConveyorBelt.conveyorJob
		v47_:applyCurrentState(self, g_currentMission, g_localPlayer.farmId, false)
		v47_:setValues()
		if v47_:validate(false) then
			return v47_
		end
	end
	return nil
end

function AIConveyorBelt:getHasStartableAIJob(superFunc)
	return true
end

function AIConveyorBelt:getCanBeSelected(superFunc)
	return true
end

function AIConveyorBelt:getAINeedsTrafficCollisionBox(superFunc)
	return false
end

-- Local values: spec, dx, _, dz, yRot
function AIConveyorBelt:onAIFieldWorkerStart()
	local v49_ = self.spec_aiConveyorBelt
	local v50_, _, v51_ = localDirectionToWorld(self.components[1].node, 0, 0, 1)
	local v52_ = MathUtil.getYRotationFromDirection(v50_, v51_)
	local v53_ = v49_.currentAngle
	v49_.minTargetWorldYRot = v52_ - math.rad(v53_) / 2
	local v54_ = v49_.currentAngle
	v49_.maxTargetWorldYRot = v52_ + math.rad(v54_) / 2
	v49_.currentDirection = 1
end

-- Local values: spec, _, actionEventId
function AIConveyorBelt:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v57_ = self.spec_aiConveyorBelt
		self:clearActionEventsTable(v57_.actionEvents)
		if isActiveForInputIgnoreSelection and v57_.isAllowed then
			local _, v58_ = self:addActionEvent(v57_.actionEvents, InputAction.IMPLEMENT_EXTRA3, self, AIConveyorBelt.actionEventChangeAngle, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v58_, GS_PRIO_NORMAL)
		end
	end
end

-- Local values: spec, newAngle
function AIConveyorBelt:actionEventChangeAngle(actionName, inputValue, callbackState, isAnalog)
	local v60_ = self.spec_aiConveyorBelt
	local v61_ = v60_.currentAngle + v60_.stepSize
	if v60_.maxAngle < v61_ then
		v61_ = v60_.minAngle
	end
	self:setAIConveyorBeltAngle(v61_)
end
