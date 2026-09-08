source("dataS/scripts/vehicles/specializations/events/PickupSetStateEvent.lua")
Pickup = {}
Pickup.PICKUP_XML_KEY = "vehicle.pickup"

function Pickup.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
end
function Pickup.initSpecialization()
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("Pickup")
	v2_:register(XMLValueType.STRING, Pickup.PICKUP_XML_KEY .. ".animation#name", "Pickup animation name")
	v2_:register(XMLValueType.FLOAT, Pickup.PICKUP_XML_KEY .. ".animation#lowerSpeed", "Pickup animation lower speed")
	v2_:register(XMLValueType.FLOAT, Pickup.PICKUP_XML_KEY .. ".animation#liftSpeed", "Pickup animation lift speed")
	v2_:register(XMLValueType.BOOL, Pickup.PICKUP_XML_KEY .. ".animation#isDefaultLowered", "Pickup animation is default lowered")
	v2_:setXMLSpecializationType()
end

function Pickup.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "allowPickingUp", Pickup.allowPickingUp)
	SpecializationUtil.registerFunction(vehicleType, "setPickupState", Pickup.setPickupState)
	SpecializationUtil.registerFunction(vehicleType, "loadPickupFromXML", Pickup.loadPickupFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getCanChangePickupState", Pickup.getCanChangePickupState)
end

function Pickup.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsLowered", Pickup.getIsLowered)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Pickup.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Pickup.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "registerLoweringActionEvent", Pickup.registerLoweringActionEvent)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "registerSelfLoweringActionEvent", Pickup.registerSelfLoweringActionEvent)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanDischargeToGround", Pickup.getCanDischargeToGround)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanDischargeToObject", Pickup.getCanDischargeToObject)
end

function Pickup.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Pickup)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Pickup)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Pickup)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Pickup)
	SpecializationUtil.registerEventListener(vehicleType, "onSetLoweredAll", Pickup)
	SpecializationUtil.registerEventListener(vehicleType, "onRootVehicleChanged", Pickup)
	SpecializationUtil.registerEventListener(vehicleType, "onFoldTimeChanged", Pickup)
end

function Pickup:onLoad(savegame)
	self:loadPickupFromXML(self.xmlFile, "vehicle.pickup", self.spec_pickup)
end

-- Local values: spec, dir
function Pickup:onPostLoad(savegame)
	local v8_ = self.spec_pickup
	if v8_.animationName ~= "" then
		local v9_
		if v8_.animationIsDefaultLowered then
			v8_.isLowered = true
			v9_ = 20
		else
			v9_ = -20
		end
		self:playAnimation(v8_.animationName, v9_, nil, true)
		AnimatedVehicle.updateAnimations(self, 99999999, true)
	end
end

-- Local values: isPickupLowered
function Pickup:onReadStream(streamId, connection)
	self:setPickupState(streamReadBool(streamId), true)
end

-- Local values: spec
function Pickup:onWriteStream(streamId, connection)
	local v14_ = self.spec_pickup
	streamWriteBool(streamId, v14_.isLowered)
end

function Pickup:onSetLoweredAll(doLowering, jointDescIndex)
	self:setPickupState(doLowering)
end

-- Local values: spec, actionController
function Pickup:onRootVehicleChanged(rootVehicle)
	local v19_ = self.spec_pickup
	if v19_.animationName ~= "" then
		local v20_ = rootVehicle.actionController
		if v20_ == nil then
			if v19_.controlledAction ~= nil then
				v19_.controlledAction:remove()
			end
		else
			if v19_.controlledAction ~= nil then
				v19_.controlledAction:updateParent(v20_)
				return
			end
			v19_.controlledAction = v20_:registerAction("lowerPickup", InputAction.LOWER_IMPLEMENT, 2)
			v19_.controlledAction:setCallback(self, Pickup.actionControllerLowerPickupEvent)
			v19_.controlledAction:setFinishedFunctions(self, self.getIsLowered, true, false)
			v19_.controlledAction:setIsSaved(true)
			if self:getAINeedsLowering() then
				v19_.controlledAction:addAIEventListener(self, "onAIImplementStartLine", 1)
				v19_.controlledAction:addAIEventListener(self, "onAIImplementEndLine", -1)
				v19_.controlledAction:addAIEventListener(self, "onAIImplementStart", -1)
				return
			end
		end
	end
end

function Pickup:onFoldTimeChanged(foldAnimTime)
	Pickup.updateActionEvents(self)
end

function Pickup:actionControllerLowerPickupEvent(direction)
	self:setPickupState(direction > 0)
	return true
end

-- Local values: spec, animTime
function Pickup:setPickupState(isPickupLowered, noEventSend)
	local v27_ = self.spec_pickup
	if isPickupLowered ~= v27_.isLowered then
		PickupSetStateEvent.sendEvent(self, isPickupLowered, noEventSend)
		v27_.isLowered = isPickupLowered
		if v27_.animationName ~= "" then
			local v28_
			if self:getIsAnimationPlaying(v27_.animationName) then
				v28_ = self:getAnimationTime(v27_.animationName)
			else
				v28_ = nil
			end
			if isPickupLowered then
				self:playAnimation(v27_.animationName, v27_.animationLowerSpeed, v28_, true)
			else
				self:playAnimation(v27_.animationName, v27_.animationLiftSpeed, v28_, true)
			end
		end
		Pickup.updateActionEvents(self)
	end
end

-- Local values: spec
function Pickup:allowPickingUp()
	return self.spec_pickup.isLowered
end

-- Local values: spec
function Pickup:getIsLowered(superFunc, default)
	return self.spec_pickup.isLowered
end

function Pickup:loadPickupFromXML(xmlFile, key, spec)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, "vehicle.pickupAnimation", key .. ".animation")
	spec.isLowered = false
	spec.animationName = xmlFile:getValue(key .. ".animation#name", "")
	if not self:getAnimationExists(spec.animationName) then
		spec.animationName = ""
		spec.isLowered = true
	end
	spec.animationLowerSpeed = xmlFile:getValue(key .. ".animation#lowerSpeed", 1)
	spec.animationLiftSpeed = xmlFile:getValue(key .. ".animation#liftSpeed", -spec.animationLowerSpeed)
	spec.animationIsDefaultLowered = xmlFile:getValue(key .. ".animation#isDefaultLowered", false)
	return true
end

function Pickup:getCanChangePickupState(spec, newState)
	return true
end

-- Local values: spec
function Pickup:getDirtMultiplier(superFunc)
	if self.spec_pickup.isLowered and (self.getIsTurnedOn == nil or self:getIsTurnedOn()) then
		return superFunc(self) + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
	else
		return superFunc(self)
	end
end

-- Local values: spec
function Pickup:getWearMultiplier(superFunc)
	if self.spec_pickup.isLowered and (self.getIsTurnedOn == nil or self:getIsTurnedOn()) then
		return superFunc(self) + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit
	else
		return superFunc(self)
	end
end

-- Local values: spec, _, actionEventId
function Pickup:registerLoweringActionEvent(superFunc, actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName)
	local v51_ = self.spec_pickup
	if v51_.animationName ~= "" then
		local _, v52_ = self:addPoweredActionEvent(v51_.actionEvents, InputAction.LOWER_IMPLEMENT, self, Pickup.actionEventTogglePickup, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName)
		g_inputBinding:setActionEventTextPriority(v52_, GS_PRIO_HIGH)
		Pickup.updateActionEvents(self)
		if inputAction == InputAction.LOWER_IMPLEMENT then
			return
		end
	end
	superFunc(self, actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName)
end

function Pickup:registerSelfLoweringActionEvent(superFunc, actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, ignoreCollisions)
	return Pickup.registerLoweringActionEvent(self, superFunc, actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, ignoreCollisions)
end

function Pickup:getCanDischargeToGround(superFunc, dischargeNode)
	if self.spec_pickup.allowWhileTipping or not self.spec_pickup.isLowered then
		return superFunc(self, dischargeNode)
	else
		return false
	end
end

function Pickup:getCanDischargeToObject(superFunc, dischargeNode)
	if self.spec_pickup.allowWhileTipping or not self.spec_pickup.isLowered then
		return superFunc(self, dischargeNode)
	else
		return false
	end
end

-- Local values: spec, actionEvent
function Pickup:updateActionEvents()
	local v73_ = self.spec_pickup
	if v73_.animationName ~= "" then
		local v74_ = v73_.actionEvents[InputAction.LOWER_IMPLEMENT]
		if v74_ ~= nil then
			if v73_.isLowered then
				g_inputBinding:setActionEventText(v74_.actionEventId, string.format(g_i18n:getText("action_liftOBJECT"), g_i18n:getText("typeDesc_pickup")))
			else
				g_inputBinding:setActionEventText(v74_.actionEventId, string.format(g_i18n:getText("action_lowerOBJECT"), g_i18n:getText("typeDesc_pickup")))
			end
			g_inputBinding:setActionEventActive(v74_.actionEventId, self:getCanChangePickupState(v73_, not v73_.isLowered))
		end
	end
end

-- Local values: spec
function Pickup:actionEventTogglePickup(actionName, inputValue, callbackState, isAnalog)
	local v76_ = self.spec_pickup
	if self:getCanChangePickupState(v76_, not v76_.isLowered) then
		self:setPickupState(not v76_.isLowered)
	end
end
