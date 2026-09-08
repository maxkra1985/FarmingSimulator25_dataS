source("dataS/scripts/vehicles/specializations/events/ReverseDrivingSetStateEvent.lua")
ReverseDriving = {}

function ReverseDriving.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(Drivable, specializations) and SpecializationUtil.hasSpecialization(Enterable, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
	end
	return v2_
end
function ReverseDriving.initSpecialization()
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("ReverseDriving")
	IKUtil.registerIKChainTargetsXMLPaths(v3_, "vehicle.reverseDriving")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.reverseDriving.steeringWheel#node", "Spawn place node")
	v3_:register(XMLValueType.ANGLE, "vehicle.reverseDriving.steeringWheel#indoorRotation", "Indoor rotation", "vehicle.drivable.steeringWheel#indoorRotation")
	v3_:register(XMLValueType.ANGLE, "vehicle.reverseDriving.steeringWheel#outdoorRotation", "Outdoor rotation", "vehicle.drivable.steeringWheel#outdoorRotation")
	v3_:register(XMLValueType.STRING, "vehicle.reverseDriving#animationName", "Animation name", "reverseDriving")
	v3_:register(XMLValueType.BOOL, "vehicle.reverseDriving#hideCharacterOnChange", "Hide the character while changing the direction", true)
	v3_:register(XMLValueType.BOOL, "vehicle.reverseDriving#inverseTransmission", "Inverse the transmission gear ratio when direction has changed", false)
	v3_:register(XMLValueType.BOOL, "vehicle.reverseDriving#initialInversed", "Vehicle is in reverse driving state directly after loading", false)
	v3_:register(XMLValueType.VECTOR_N, "vehicle.reverseDriving#disablingAttacherJointIndices", "Attacher joint indices which are disabling the reverse driving")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.reverseDriving.ai#steeringNode", "Steering Node while in reverse driving mode")
	AIImplement.registerAICollisionTriggerXMLPaths(v3_, "vehicle.reverseDriving.ai")
	v3_:register(XMLValueType.BOOL, Dashboard.GROUP_XML_KEY .. "#isReverseDriving", "Is Reverse driving")
	for v4_ = 1, #Lights.ADDITIONAL_LIGHT_ATTRIBUTES_KEYS do
		local v5_ = Lights.ADDITIONAL_LIGHT_ATTRIBUTES_KEYS[v4_]
		v3_:register(XMLValueType.INT, v5_ .. "#enableDirection", "Light is enabled when driving into this direction [-1, 1]")
	end
	v3_:setXMLSpecializationType()
	Vehicle.xmlSchemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).reverseDriving#isActive", "Reverse driving is active")
end
function ReverseDriving.postInitSpecialization()
	local v6_ = Vehicle.xmlSchema
	for _, v7_ in pairs(g_vehicleConfigurationManager:getConfigurations()) do
		local v8_ = v7_.configurationKey .. "(?)"
		v6_:setXMLSharedRegistration("configReverseDriving", v8_)
		v6_:register(XMLValueType.BOOL, v8_ .. ".reverseDriving#isAllowed", "Reverse driving is allowed while this configuration is equipped", true)
		v6_:resetXMLSharedRegistration("configReverseDriving", v8_)
	end
end

function ReverseDriving.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onStartReverseDirectionChange")
	SpecializationUtil.registerEvent(vehicleType, "onReverseDirectionChanged")
end

function ReverseDriving.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "reverseDirectionChanged", ReverseDriving.reverseDirectionChanged)
	SpecializationUtil.registerFunction(vehicleType, "setIsReverseDriving", ReverseDriving.setIsReverseDriving)
	SpecializationUtil.registerFunction(vehicleType, "getIsReverseDrivingAllowed", ReverseDriving.getIsReverseDrivingAllowed)
end

function ReverseDriving.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateSteeringWheel", ReverseDriving.updateSteeringWheel)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSteeringDirection", ReverseDriving.getSteeringDirection)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowCharacterVisibilityUpdate", ReverseDriving.getAllowCharacterVisibilityUpdate)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanStartAIVehicle", ReverseDriving.getCanStartAIVehicle)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDashboardGroupFromXML", ReverseDriving.loadDashboardGroupFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDashboardGroupActive", ReverseDriving.getIsDashboardGroupActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", ReverseDriving.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAdditionalLightAttributesFromXML", ReverseDriving.loadAdditionalLightAttributesFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsLightActive", ReverseDriving.getIsLightActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIDirectionNode", ReverseDriving.getAIDirectionNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIRootNode", ReverseDriving.getAIRootNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIImplementCollisionTrigger", ReverseDriving.getAIImplementCollisionTrigger)
end

function ReverseDriving.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ReverseDriving)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", ReverseDriving)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", ReverseDriving)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", ReverseDriving)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", ReverseDriving)
	SpecializationUtil.registerEventListener(vehicleType, "onVehicleCharacterChanged", ReverseDriving)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", ReverseDriving)
end

-- Local values: spec, node, _, ry, _, name, id, configDesc, key
function ReverseDriving:onLoad(savegame)
	local v14_ = self.spec_reverseDriving
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.reverseDriving.steering#reversedIndex", "vehicle.reverseDriving.steeringWheel#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.reverseDriving.steering#reversedNode", "vehicle.reverseDriving.steeringWheel#node")
	v14_.reversedCharacterTargets = {}
	IKUtil.loadIKChainTargets(self.xmlFile, "vehicle.reverseDriving", self.components, v14_.reversedCharacterTargets, self.i3dMappings)
	local v15_ = self.xmlFile:getValue("vehicle.reverseDriving.steeringWheel#node", nil, self.components, self.i3dMappings)
	if v15_ ~= nil then
		v14_.steeringWheel = {}
		v14_.steeringWheel.node = v15_
		local _, v16_, _ = getRotation(v14_.steeringWheel.node)
		v14_.steeringWheel.lastRotation = v16_
		v14_.steeringWheel.indoorRotation = self.xmlFile:getValue("vehicle.reverseDriving.steeringWheel#indoorRotation", self.xmlFile:getValue("vehicle.drivable.steeringWheel#indoorRotation", 0))
		v14_.steeringWheel.outdoorRotation = self.xmlFile:getValue("vehicle.reverseDriving.steeringWheel#outdoorRotation", self.xmlFile:getValue("vehicle.drivable.steeringWheel#outdoorRotation", 0))
	end
	v14_.reverseDrivingAnimation = self.xmlFile:getValue("vehicle.reverseDriving#animationName", "reverseDriving")
	v14_.hideCharacterOnChange = self.xmlFile:getValue("vehicle.reverseDriving#hideCharacterOnChange", true)
	v14_.inverseTransmission = self.xmlFile:getValue("vehicle.reverseDriving#inverseTransmission", false)
	v14_.disablingAttacherJointIndices = self.xmlFile:getValue("vehicle.reverseDriving#disablingAttacherJointIndices", nil, true)
	v14_.aiSteeringNode = self.xmlFile:getValue("vehicle.reverseDriving.ai#steeringNode", nil, self.components, self.i3dMappings)
	v14_.supportsAI = v14_.aiSteeringNode ~= nil
	if self.loadAICollisionTriggerFromXML ~= nil then
		v14_.aiCollisionTrigger = self:loadAICollisionTriggerFromXML(self.xmlFile, "vehicle.reverseDriving.ai")
	end
	v14_.hasReverseDriving = self:getAnimationExists(v14_.reverseDrivingAnimation)
	for v17_, v18_ in pairs(self.configurations) do
		local v19_ = g_vehicleConfigurationManager:getConfigurationDescByName(v17_)
		local v20_ = string.format("%s(%d).reverseDriving", v19_.configurationKey, v18_ - 1)
		if not self.xmlFile:getValue(v20_ .. "#isAllowed", true) then
			v14_.hasReverseDriving = false
		end
	end
	v14_.isChangingDirection = false
	v14_.isReverseDriving = self.xmlFile:getValue("vehicle.reverseDriving#initialInversed", false)
	v14_.smoothReverserDirection = 1
	if not v14_.hasReverseDriving then
		SpecializationUtil.removeEventListener(self, "onPostLoad", ReverseDriving)
		SpecializationUtil.removeEventListener(self, "onReadStream", ReverseDriving)
		SpecializationUtil.removeEventListener(self, "onWriteStream", ReverseDriving)
		SpecializationUtil.removeEventListener(self, "onUpdate", ReverseDriving)
		SpecializationUtil.removeEventListener(self, "onVehicleCharacterChanged", ReverseDriving)
		SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", ReverseDriving)
	end
end

-- Local values: spec, character, isReverseDriving
function ReverseDriving:onPostLoad(savegame)
	local v23_ = self.spec_reverseDriving
	local v24_ = self:getVehicleCharacter()
	if v24_ ~= nil then
		v23_.defaultCharacterTargets = v24_:getIKChainTargets()
	end
	local v25_ = v23_.isReverseDriving
	if savegame ~= nil then
		v25_ = savegame.xmlFile:getValue(savegame.key .. ".reverseDriving#isActive", v25_)
	end
	self:setIsReverseDriving(v25_, true, true)
	v23_.updateAnimationOnEnter = v25_
end

-- Local values: spec
function ReverseDriving:saveToXMLFile(xmlFile, key, usedModNames)
	local v29_ = self.spec_reverseDriving
	if v29_.hasReverseDriving then
		xmlFile:setValue(key .. "#isActive", v29_.isReverseDriving)
	end
end

-- Local values: spec
function ReverseDriving:onReadStream(streamId, connection)
	self:setIsReverseDriving(streamReadBool(streamId), true, true)
	local v32_ = self.spec_reverseDriving
	v32_.updateAnimationOnEnter = v32_.isReverseDriving
end

function ReverseDriving:onWriteStream(streamId, connection)
	streamWriteBool(streamId, self.spec_reverseDriving.isReverseDriving)
end

-- Local values: spec, character, direction
function ReverseDriving:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v37_ = self.spec_reverseDriving
	if v37_.isChangingDirection then
		if v37_.hideCharacterOnChange then
			local v38_ = self:getVehicleCharacter()
			if v38_ ~= nil then
				v38_:setCharacterVisibility(false)
			end
		end
		if not self:getIsEntered() and v37_.updateAnimationOnEnter then
			AnimatedVehicle.updateAnimations(self, 99999999, true)
			v37_.updateAnimationOnEnter = false
		end
		if not self:getIsAnimationPlaying(v37_.reverseDrivingAnimation) then
			self:reverseDirectionChanged(v37_.reverserDirection)
		end
		local v39_ = v37_.isReverseDriving and 1 or -1
		local v40_ = v37_.smoothReverserDirection - 0.001 * dt * v39_
		v37_.smoothReverserDirection = math.clamp(v40_, -1, 1)
	end
end

-- Local values: spec, character
function ReverseDriving:reverseDirectionChanged(direction)
	local v43_ = self.spec_reverseDriving
	v43_.isChangingDirection = false
	if v43_.isReverseDriving then
		self:setReverserDirection(-1)
		v43_.smoothReverserDirection = -1
	else
		self:setReverserDirection(1)
		v43_.smoothReverserDirection = 1
	end
	local v44_ = self:getVehicleCharacter()
	if v44_ ~= nil then
		if v43_.isReverseDriving and next(v43_.reversedCharacterTargets) ~= nil then
			v44_:setIKChainTargets(v43_.reversedCharacterTargets)
		else
			v44_:setIKChainTargets(v43_.defaultCharacterTargets)
		end
		if v44_.meshThirdPerson ~= nil and not self:getIsEntered() then
			v44_:updateVisibility()
		end
		v44_:setAllowCharacterUpdate(true)
	end
	if self.setLightsTypesMask ~= nil then
		self:setLightsTypesMask(self.spec_lights.lightsTypesMask, true, true)
	end
	SpecializationUtil.raiseEvent(self, "onReverseDirectionChanged", direction)
end

-- Local values: spec, dir, character
function ReverseDriving:setIsReverseDriving(isReverseDriving, noEventSend, forceUpdate)
	local v49_ = self.spec_reverseDriving
	if isReverseDriving ~= v49_.isReverseDriving or forceUpdate then
		v49_.isChangingDirection = true
		v49_.isReverseDriving = isReverseDriving
		local v50_ = isReverseDriving and 1 or -1
		self:playAnimation(v49_.reverseDrivingAnimation, v50_, self:getAnimationTime(v49_.reverseDrivingAnimation), true)
		local v51_ = self:getVehicleCharacter()
		if v51_ ~= nil then
			v51_:setAllowCharacterUpdate(false)
		end
		if v49_.inverseTransmission and self.setTransmissionDirection ~= nil then
			self:setTransmissionDirection(-v50_)
		end
		self:setReverserDirection(0)
		SpecializationUtil.raiseEvent(self, "onStartReverseDirectionChange")
		ReverseDrivingSetStateEvent.sendEvent(self, isReverseDriving, noEventSend)
		if forceUpdate then
			AnimatedVehicle.updateAnimationByName(self, v49_.reverseDrivingAnimation, 9999999, true)
		end
		self:setAIRootNodeDirty()
	end
end

-- Local values: spec, i
function ReverseDriving:getIsReverseDrivingAllowed(newState)
	local v54_ = self.spec_reverseDriving
	if newState and v54_.disablingAttacherJointIndices ~= nil then
		for v55_ = 1, #v54_.disablingAttacherJointIndices do
			if self:getImplementFromAttacherJointIndex(v54_.disablingAttacherJointIndices[v55_]) ~= nil then
				return false
			end
		end
	end
	return true
end

-- Local values: spec
function ReverseDriving:updateSteeringWheel(superFunc, steeringWheel, dt, direction)
	local v61_ = self.spec_reverseDriving
	if v61_.isReverseDriving then
		if v61_.steeringWheel ~= nil then
			steeringWheel = v61_.steeringWheel
		end
		direction = -direction
	end
	superFunc(self, steeringWheel, dt, direction)
end

-- Local values: spec
function ReverseDriving:getSteeringDirection(superFunc)
	local v64_ = self.spec_reverseDriving
	if v64_.hasReverseDriving then
		return v64_.smoothReverserDirection
	else
		return superFunc(self)
	end
end

-- Local values: spec
function ReverseDriving:getAllowCharacterVisibilityUpdate(superFunc)
	local v67_ = self.spec_reverseDriving
	local v68_ = superFunc(self)
	if v68_ then
		v68_ = not (v67_.hideCharacterOnChange and v67_.isChangingDirection)
	end
	return v68_
end

-- Local values: spec
function ReverseDriving:getCanStartAIVehicle(superFunc, jobClass)
	local v72_ = self.spec_reverseDriving
	if not v72_.supportsAI and v72_.hasReverseDriving then
		if v72_.isReverseDriving then
			return false
		end
		if v72_.isChangingDirection then
			return false
		end
	end
	return superFunc(self, jobClass)
end

function ReverseDriving:loadDashboardGroupFromXML(superFunc, xmlFile, key, group)
	if not superFunc(self, xmlFile, key, group) then
		return false
	end
	group.isReverseDriving = xmlFile:getValue(key .. "#isReverseDriving")
	return true
end

function ReverseDriving:getIsDashboardGroupActive(superFunc, group)
	if group.isReverseDriving == nil or self.spec_reverseDriving.isReverseDriving == group.isReverseDriving then
		return superFunc(self, group)
	else
		return false
	end
end

function ReverseDriving:getCanBeSelected(superFunc)
	return true
end

function ReverseDriving:loadAdditionalLightAttributesFromXML(superFunc, xmlFile, key, light)
	if not superFunc(self, xmlFile, key, light) then
		return false
	end
	light.enableDirection = xmlFile:getValue(key .. "#enableDirection")
	return true
end

function ReverseDriving:getIsLightActive(superFunc, light)
	if light.enableDirection == nil or light.enableDirection == self:getReverserDirection() then
		return superFunc(self, light)
	else
		return false
	end
end

-- Local values: spec
function ReverseDriving:getAIDirectionNode(superFunc)
	local v91_ = self.spec_reverseDriving
	if v91_.isReverseDriving then
		return v91_.aiSteeringNode or superFunc(self)
	else
		return superFunc(self)
	end
end

-- Local values: spec
function ReverseDriving:getAIRootNode(superFunc)
	local v94_ = self.spec_reverseDriving
	if v94_.isReverseDriving then
		return v94_.aiSteeringNode or superFunc(self)
	else
		return superFunc(self)
	end
end

-- Local values: spec
function ReverseDriving:getAIImplementCollisionTrigger(superFunc)
	local v97_ = self.spec_reverseDriving
	if v97_.isReverseDriving then
		return v97_.aiCollisionTrigger or superFunc(self)
	else
		return superFunc(self)
	end
end

-- Local values: spec
function ReverseDriving:onVehicleCharacterChanged(character)
	local v100_ = self.spec_reverseDriving
	if character ~= nil then
		if v100_.updateAnimationOnEnter then
			AnimatedVehicle.updateAnimations(self, 99999999, true)
			v100_.updateAnimationOnEnter = false
		end
		if v100_.isReverseDriving and next(v100_.reversedCharacterTargets) ~= nil then
			character:setIKChainTargets(v100_.reversedCharacterTargets, true)
			return
		end
		character:setIKChainTargets(v100_.defaultCharacterTargets, true)
	end
end

-- Local values: spec, _, actionEventId
function ReverseDriving:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v103_ = self.spec_reverseDriving
		self:clearActionEventsTable(v103_.actionEvents)
		if isActiveForInputIgnoreSelection then
			local _, v104_ = self:addPoweredActionEvent(v103_.actionEvents, InputAction.CHANGE_DRIVING_DIRECTION, self, ReverseDriving.actionEventToggleReverseDriving, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v104_, GS_PRIO_NORMAL)
			g_inputBinding:setActionEventText(v104_, g_i18n:getText("input_CHANGE_DRIVING_DIRECTION"))
		end
	end
end

-- Local values: spec
function ReverseDriving:actionEventToggleReverseDriving(actionName, inputValue, callbackState, isAnalog)
	local v106_ = self.spec_reverseDriving
	if self:getIsReverseDrivingAllowed(not v106_.isReverseDriving) then
		self:setIsReverseDriving(not v106_.isReverseDriving)
	end
end
