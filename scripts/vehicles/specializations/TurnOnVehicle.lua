source("dataS/scripts/vehicles/specializations/events/SetTurnedOnEvent.lua")
TurnOnVehicle = {}
TurnOnVehicle.TURNED_ON_ANIMATION_XML_PATH = "vehicle.turnOnVehicle.turnedOnAnimation(?)"

function TurnOnVehicle.prerequisitesPresent(self)
	return true
end
function TurnOnVehicle.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("TurnOnVehicle")
	v1_:register(XMLValueType.STRING, "vehicle.turnOnVehicle#toggleButton", "Input action name", "IMPLEMENT_EXTRA")
	v1_:register(XMLValueType.L10N_STRING, "vehicle.turnOnVehicle#turnOffText", "Turn off text", "action_turnOffOBJECT")
	v1_:register(XMLValueType.L10N_STRING, "vehicle.turnOnVehicle#turnOnText", "Turn on text", "action_turnOnOBJECT")
	v1_:register(XMLValueType.BOOL, "vehicle.turnOnVehicle#isAlwaysTurnedOn", "Always turned on", false)
	v1_:register(XMLValueType.BOOL, "vehicle.turnOnVehicle#turnedOnByAttacherVehicle", "Turned on by attacher vehicle", false)
	v1_:register(XMLValueType.BOOL, "vehicle.turnOnVehicle#turnOffIfNotAllowed", "Turn off if not allowed", true)
	v1_:register(XMLValueType.BOOL, "vehicle.turnOnVehicle#turnOffOnDeactivate", "Turn off if the vehicle is deactivated", true)
	v1_:register(XMLValueType.BOOL, "vehicle.turnOnVehicle#aiRequiresTurnOn", "AI requires turned on vehicle", true)
	v1_:register(XMLValueType.BOOL, "vehicle.turnOnVehicle#requiresTurnOn", "(Mobile only) Vehicle requires turn on", true)
	AnimationManager.registerAnimationNodesXMLPaths(v1_, "vehicle.turnOnVehicle.animationNodes")
	EffectManager.registerEffectXMLPaths(v1_, "vehicle.turnOnVehicle.effects")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.turnOnVehicle.sounds", "start(?)")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.turnOnVehicle.sounds", "stop(?)")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.turnOnVehicle.sounds", "work(?)")
	v1_:register(XMLValueType.STRING, "vehicle.turnOnVehicle.turnedAnimation#name", "Turned animation name (Animation played while activating and deactivating)")
	v1_:register(XMLValueType.FLOAT, "vehicle.turnOnVehicle.turnedAnimation#turnOnSpeedScale", "Turn on speed scale", 1)
	v1_:register(XMLValueType.FLOAT, "vehicle.turnOnVehicle.turnedAnimation#turnOffSpeedScale", "Turn off speed scale", "Inversed turnOnSpeedScale")
	v1_:register(XMLValueType.STRING, TurnOnVehicle.TURNED_ON_ANIMATION_XML_PATH .. "#name", "Turned on animation name (Animation played while turn on)")
	v1_:register(XMLValueType.FLOAT, TurnOnVehicle.TURNED_ON_ANIMATION_XML_PATH .. "#turnOnFadeTime", "Turn on fade time", 1)
	v1_:register(XMLValueType.FLOAT, TurnOnVehicle.TURNED_ON_ANIMATION_XML_PATH .. "#turnOffFadeTime", "Turn off fade time", 1)
	v1_:register(XMLValueType.FLOAT, TurnOnVehicle.TURNED_ON_ANIMATION_XML_PATH .. "#speedScale", "Speed scale", 1)
	v1_:register(XMLValueType.INT, "vehicle.turnOnVehicle.activatableFillUnits.activatableFillUnit(?)#index", "Activateable fill unit index")
	v1_:register(XMLValueType.BOOL, Attachable.INPUT_ATTACHERJOINT_XML_KEY .. "#canBeTurnedOn", "Attacher joint can turn on implement", true)
	v1_:register(XMLValueType.BOOL, Attachable.INPUT_ATTACHERJOINT_CONFIG_XML_KEY .. "#canBeTurnedOn", "Attacher joint can turn on implement", true)
	v1_:register(XMLValueType.BOOL, WorkArea.WORK_AREA_XML_KEY .. "#needsSetIsTurnedOn", "Work area needs turned on vehicle to work", true)
	v1_:register(XMLValueType.BOOL, WorkArea.WORK_AREA_XML_CONFIG_KEY .. "#needsSetIsTurnedOn", "Work area needs turned on vehicle to work", true)
	v1_:register(XMLValueType.BOOL, FillUnit.ALARM_TRIGGER_XML_KEY .. "#needsTurnOn", "Needs turned on vehicle", false)
	v1_:register(XMLValueType.BOOL, FillUnit.ALARM_TRIGGER_XML_KEY .. "#turnOffInTrigger", "Turn vehicle off when triggered", false)
	v1_:register(XMLValueType.BOOL, Shovel.SHOVEL_NODE_XML_KEY .. "#needsActivation", "Needs activation", false)
	v1_:register(XMLValueType.BOOL, Dischargeable.DISCHARGE_NODE_XML_PATH .. "#needsSetIsTurnedOn", "Vehicle needs to be turned on to activate discharge node", false)
	v1_:register(XMLValueType.BOOL, Dischargeable.DISCHARGE_NODE_XML_PATH .. "#turnOnActivateNode", "Discharge node is set active when vehicle is turned on", false)
	v1_:register(XMLValueType.BOOL, Dischargeable.DISCHARGE_NODE_CONFIG_XML_PATH .. "#needsSetIsTurnedOn", "Vehicle needs to be turned on to activate discharge node", false)
	v1_:register(XMLValueType.BOOL, Dischargeable.DISCHARGE_NODE_CONFIG_XML_PATH .. "#turnOnActivateNode", "Discharge node is set active when vehicle is turned on", false)
	v1_:register(XMLValueType.FLOAT, BunkerSiloCompacter.XML_PATH .. "#turnedOnCompactingScale", "Compacting scale which is used while vehicle is turned on", "normal scale")
	v1_:register(XMLValueType.TIME, "vehicle.turnOnVehicle.turnedOnSpeed#fadeInTime", "(Turned on speed simulation - used as sound modifier and for rpm dashboards) Time to reach max. turned on speed", 1)
	v1_:register(XMLValueType.TIME, "vehicle.turnOnVehicle.turnedOnSpeed#fadeOutTime", "(Turned on speed simulation - used as sound modifier and for rpm dashboards) Time to reach the turned off speed again", 1)
	v1_:register(XMLValueType.FLOAT, "vehicle.turnOnVehicle.turnedOnSpeed#variance", "Variation value at max. speed", 0.02)
	v1_:register(XMLValueType.FLOAT, "vehicle.turnOnVehicle.turnedOnSpeed#varianceSpeed", "Speed factor of variance change", 1)
	Dashboard.registerDashboardXMLPaths(v1_, "vehicle.turnOnVehicle.dashboards", { "turnedOn", "rpm" })
	v1_:register(XMLValueType.FLOAT, "vehicle.turnOnVehicle.dashboards.dashboard(?)#minRpm", "Rpm value if vehicle is turned off", 0)
	v1_:register(XMLValueType.FLOAT, "vehicle.turnOnVehicle.dashboards.dashboard(?)#maxRpm", "Rpm value if vehicle is turned on", 1000)
	v1_:setXMLSpecializationType()
end

function TurnOnVehicle.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onTurnedOn")
	SpecializationUtil.registerEvent(vehicleType, "onTurnedOff")
end

function TurnOnVehicle.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setIsTurnedOn", TurnOnVehicle.setIsTurnedOn)
	SpecializationUtil.registerFunction(vehicleType, "getIsTurnedOn", TurnOnVehicle.getIsTurnedOn)
	SpecializationUtil.registerFunction(vehicleType, "getCanBeTurnedOn", TurnOnVehicle.getCanBeTurnedOn)
	SpecializationUtil.registerFunction(vehicleType, "getCanBeTurnedOnAll", TurnOnVehicle.getCanBeTurnedOnAll)
	SpecializationUtil.registerFunction(vehicleType, "getCanToggleTurnedOn", TurnOnVehicle.getCanToggleTurnedOn)
	SpecializationUtil.registerFunction(vehicleType, "getTurnedOnNotAllowedWarning", TurnOnVehicle.getTurnedOnNotAllowedWarning)
	SpecializationUtil.registerFunction(vehicleType, "getAIRequiresTurnOn", TurnOnVehicle.getAIRequiresTurnOn)
	SpecializationUtil.registerFunction(vehicleType, "getRequiresTurnOn", TurnOnVehicle.getRequiresTurnOn)
	SpecializationUtil.registerFunction(vehicleType, "getAIRequiresTurnOffOnHeadland", TurnOnVehicle.getAIRequiresTurnOffOnHeadland)
	SpecializationUtil.registerFunction(vehicleType, "loadTurnedOnAnimationFromXML", TurnOnVehicle.loadTurnedOnAnimationFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsTurnedOnAnimationActive", TurnOnVehicle.getIsTurnedOnAnimationActive)
	SpecializationUtil.registerFunction(vehicleType, "getTurnedOnSpeedFactor", TurnOnVehicle.getTurnedOnSpeedFactor)
end

function TurnOnVehicle.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getUseTurnedOnSchema", TurnOnVehicle.getUseTurnedOnSchema)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadInputAttacherJoint", TurnOnVehicle.loadInputAttacherJoint)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", TurnOnVehicle.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", TurnOnVehicle.getIsWorkAreaActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanAIImplementContinueWork", TurnOnVehicle.getCanAIImplementContinueWork)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsOperating", TurnOnVehicle.getIsOperating)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAlarmTriggerIsActive", TurnOnVehicle.getAlarmTriggerIsActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAlarmTrigger", TurnOnVehicle.loadAlarmTrigger)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFillUnitActive", TurnOnVehicle.getIsFillUnitActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadShovelNode", TurnOnVehicle.loadShovelNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getShovelNodeIsActive", TurnOnVehicle.getShovelNodeIsActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSeedChangeAllowed", TurnOnVehicle.getIsSeedChangeAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", TurnOnVehicle.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsPowerTakeOffActive", TurnOnVehicle.getIsPowerTakeOffActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDischargeNode", TurnOnVehicle.loadDischargeNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDischargeNodeActive", TurnOnVehicle.getIsDischargeNodeActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadBunkerSiloCompactorFromXML", TurnOnVehicle.loadBunkerSiloCompactorFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getBunkerSiloCompacterScale", TurnOnVehicle.getBunkerSiloCompacterScale)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkModeChangeAllowed", TurnOnVehicle.getIsWorkModeChangeAllowed)
end

function TurnOnVehicle.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterExternalActionEvents", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onRootVehicleChanged", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onAlarmTriggerChanged", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onSetBroken", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", TurnOnVehicle)
end

-- Local values: spec, turnOnButtonStr, allowsAnimations, turnOnAnimation, i, key, fillUnitIndex
function TurnOnVehicle:onLoad(savegame)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnOnSettings#turnOffText", "vehicle.turnOnVehicle#turnOffText")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnOnSettings#turnOnText", "vehicle.turnOnVehicle#turnOnText")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnOnSettings#needsSelection")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnOnSettings#isAlwaysTurnedOn", "vehicle.turnOnVehicle#isAlwaysTurnedOn")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnOnSettings#toggleButton", "vehicle.turnOnVehicle#toggleButton")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnOnSettings#animationName", "vehicle.turnOnVehicle.turnedAnimation#name")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnOnSettings#turnOnSpeedScale", "vehicle.turnOnVehicle.turnedAnimation#turnOnSpeedScale")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnOnSettings#turnOffSpeedScale", "vehicle.turnOnVehicle.turnedAnimation#turnOffSpeedScale")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnRotationNodes.turnedOnRotationNode#type", "vehicle.turnOnVehicle.animationNodes.animationNode", "turnOn")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.foldable.foldingParts#turnOffOnFold", "vehicle.turnOnVehicle#turnOffIfNotAllowed")
	local v_u_7_ = self.spec_turnOnVehicle
	local v8_ = self.xmlFile:getValue("vehicle.turnOnVehicle#toggleButton")
	if v8_ ~= nil then
		v_u_7_.toggleTurnOnInputBinding = InputAction[v8_]
	end
	v_u_7_.toggleTurnOnInputBinding = Utils.getNoNil(v_u_7_.toggleTurnOnInputBinding, InputAction.IMPLEMENT_EXTRA)
	v_u_7_.turnOffText = string.format(self.xmlFile:getValue("vehicle.turnOnVehicle#turnOffText", "action_turnOffOBJECT", self.customEnvironment), self.typeDesc)
	v_u_7_.turnOnText = string.format(self.xmlFile:getValue("vehicle.turnOnVehicle#turnOnText", "action_turnOnOBJECT", self.customEnvironment), self.typeDesc)
	v_u_7_.isTurnedOn = false
	v_u_7_.isAlwaysTurnedOn = self.xmlFile:getValue("vehicle.turnOnVehicle#isAlwaysTurnedOn", false)
	v_u_7_.turnedOnByAttacherVehicle = self.xmlFile:getValue("vehicle.turnOnVehicle#turnedOnByAttacherVehicle", false)
	v_u_7_.turnOffIfNotAllowed = self.xmlFile:getValue("vehicle.turnOnVehicle#turnOffIfNotAllowed", true)
	v_u_7_.turnOffOnDeactivate = self.xmlFile:getValue("vehicle.turnOnVehicle#turnOffOnDeactivate", not GS_IS_MOBILE_VERSION)
	v_u_7_.aiRequiresTurnOn = self.xmlFile:getValue("vehicle.turnOnVehicle#aiRequiresTurnOn", true)
	v_u_7_.requiresTurnOn = self.xmlFile:getValue("vehicle.turnOnVehicle#requiresTurnOn", true)
	if self.isClient then
		v_u_7_.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.turnOnVehicle.animationNodes", self.components, self, self.i3dMappings)
		local v9_ = SpecializationUtil.hasSpecialization(AnimatedVehicle, self.specializations)
		if v9_ then
			local v10_ = self.xmlFile:getValue("vehicle.turnOnVehicle.turnedAnimation#name")
			if v10_ ~= nil then
				v_u_7_.turnOnAnimation = {}
				v_u_7_.turnOnAnimation.name = v10_
				v_u_7_.turnOnAnimation.turnOnSpeedScale = self.xmlFile:getValue("vehicle.turnOnVehicle.turnedAnimation#turnOnSpeedScale", 1)
				v_u_7_.turnOnAnimation.turnOffSpeedScale = self.xmlFile:getValue("vehicle.turnOnVehicle.turnedAnimation#turnOffSpeedScale", -v_u_7_.turnOnAnimation.turnOnSpeedScale)
			end
		end
		v_u_7_.turnedOnAnimations = {}
		if v9_ then
			self.xmlFile:iterate("vehicle.turnOnVehicle.turnedOnAnimation", function(_, p11_)
				-- upvalues: (copy) self, (copy) v_u_7_
				local v12_ = {}
				if self:loadTurnedOnAnimationFromXML(self.xmlFile, p11_, v12_) then
					local v13_ = v_u_7_.turnedOnAnimations
					table.insert(v13_, v12_)
				end
			end)
		end
		v_u_7_.activatableFillUnits = {}
		local v14_ = 0
		while true do
			local v15_ = string.format("vehicle.turnOnVehicle.activatableFillUnits.activatableFillUnit(%d)", v14_)
			if not self.xmlFile:hasProperty(v15_) then
				break
			end
			local v16_ = self.xmlFile:getValue(v15_ .. "#index")
			if v16_ ~= nil then
				v_u_7_.activatableFillUnits[v16_] = true
			end
			v14_ = v14_ + 1
		end
		v_u_7_.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.turnOnVehicle.effects", self.components, self, self.i3dMappings)
		v_u_7_.samples = {}
		v_u_7_.samples.start = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.turnOnVehicle.sounds", "start", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_7_.samples.stop = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.turnOnVehicle.sounds", "stop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_7_.samples.work = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.turnOnVehicle.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_7_.turnedOnSpeed = {}
		v_u_7_.turnedOnSpeed.isActive = self.xmlFile:hasProperty("vehicle.turnOnVehicle.turnedOnSpeed")
		v_u_7_.turnedOnSpeed.alpha = 0
		v_u_7_.turnedOnSpeed.fadeInTime = self.xmlFile:getValue("vehicle.turnOnVehicle.turnedOnSpeed#fadeInTime", 1)
		v_u_7_.turnedOnSpeed.fadeOutTime = self.xmlFile:getValue("vehicle.turnOnVehicle.turnedOnSpeed#fadeOutTime", 1)
		v_u_7_.turnedOnSpeed.variance = self.xmlFile:getValue("vehicle.turnOnVehicle.turnedOnSpeed#variance", 0.02)
		v_u_7_.turnedOnSpeed.varianceSpeed = self.xmlFile:getValue("vehicle.turnOnVehicle.turnedOnSpeed#varianceSpeed", 0.01)
	end
	if not self.isClient then
		SpecializationUtil.removeEventListener(self, "onDelete", TurnOnVehicle)
		SpecializationUtil.removeEventListener(self, "onUpdate", TurnOnVehicle)
	end
end

-- Local values: spec, turnedOn, rpm
function TurnOnVehicle:onRegisterDashboardValueTypes()
	local v18_ = self.spec_turnOnVehicle
	local v19_ = DashboardValueType.new("turnOnVehicle", "turnedOn")
	v19_:setValue(v18_, "isTurnedOn")
	v19_:setPollUpdate(false)
	self:registerDashboardValueType(v19_)
	local v20_ = DashboardValueType.new("turnOnVehicle", "rpm")
	v20_:setValue(self, TurnOnVehicle.dashboardRpmValue)
	v20_:setAdditionalFunctions(TurnOnVehicle.dashboardRpmAttributes, nil)
	self:registerDashboardValueType(v20_)
end

-- Local values: spec
function TurnOnVehicle:onDelete()
	local v22_ = self.spec_turnOnVehicle
	if self.isClient then
		if v22_.samples ~= nil then
			g_soundManager:deleteSamples(v22_.samples.start)
			g_soundManager:deleteSamples(v22_.samples.stop)
			g_soundManager:deleteSamples(v22_.samples.work)
		end
		g_animationManager:deleteAnimations(v22_.animationNodes)
		g_effectManager:deleteEffects(v22_.effects)
	end
end

-- Local values: turnedOn
function TurnOnVehicle:onReadStream(streamId, connection)
	self:setIsTurnedOn(streamReadBool(streamId), true)
end

-- Local values: spec
function TurnOnVehicle:onWriteStream(streamId, connection)
	local v27_ = self.spec_turnOnVehicle
	streamWriteBool(streamId, v27_.isTurnedOn)
end

-- Local values: spec, i, turnedOnAnimation, isTurnedOn, duration, targetAlpha, time, modValue, dir, limitFunc, fadeTime
function TurnOnVehicle:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v30_ = self.spec_turnOnVehicle
	for v31_ = 1, #v30_.turnedOnAnimations do
		local v32_ = v30_.turnedOnAnimations[v31_]
		local v33_ = self:getIsTurnedOnAnimationActive(v32_)
		if v32_.isTurnedOn ~= v33_ then
			if v33_ then
				v32_.speedDirection = 1
				local v34_ = v32_.name
				local v35_ = v32_.currentSpeed * v32_.speedScale
				self:playAnimation(v34_, math.max(v35_, 0.001), self:getAnimationTime(v32_.name), true)
			else
				v32_.speedDirection = -1
			end
			v32_.isTurnedOn = v33_
		end
		if v32_.speedDirection ~= 0 then
			local v36_ = v32_.turnOnFadeTime
			if v32_.speedDirection == -1 then
				v36_ = v32_.turnOffFadeTime
			end
			local v37_ = v32_.currentSpeed + v32_.speedDirection * dt / v36_
			v32_.currentSpeed = math.clamp(v37_, 0, 1)
			self:setAnimationSpeed(v32_.name, v32_.currentSpeed * v32_.speedScale)
			if v32_.speedDirection == -1 and v32_.currentSpeed == 0 then
				self:stopAnimation(v32_.name, true)
			end
			if v32_.currentSpeed == 1 or v32_.currentSpeed == 0 then
				v32_.speedDirection = 0
			end
		end
	end
	if self.isClient and v30_.turnedOnSpeed.isActive then
		local v38_
		if self:getIsTurnedOn() then
			local v39_ = g_time * v30_.turnedOnSpeed.varianceSpeed * 0.05
			local v40_ = math.sin(v39_)
			local v41_ = (v39_ + 2) * 0.3
			local v42_ = v40_ * math.sin(v41_) * 0.8
			local v43_ = v39_ * 5
			v38_ = 1 + (v42_ + math.cos(v43_) * 0.2) * v30_.turnedOnSpeed.variance
		else
			v38_ = 0
		end
		if v38_ ~= v30_.turnedOnSpeed.alpha then
			local v44_ = v38_ - v30_.turnedOnSpeed.alpha
			local v45_ = math.sign(v44_)
			local v46_ = v45_ < 0 and math.max or math.min
			local v47_ = v45_ < 0 and v30_.turnedOnSpeed.fadeOutTime or v30_.turnedOnSpeed.fadeInTime
			v30_.turnedOnSpeed.alpha = v46_(v30_.turnedOnSpeed.alpha + 1 / v47_ * v45_ * dt, v38_)
		end
	end
end

-- Local values: spec, attacherVehicle
function TurnOnVehicle:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v49_ = self.spec_turnOnVehicle
	if self.isClient and not (v49_.isAlwaysTurnedOn or v49_.turnedOnByAttacherVehicle) then
		TurnOnVehicle.updateActionEvents(self)
	end
	if self.isServer and (v49_.turnOffIfNotAllowed and not self:getCanBeTurnedOn()) then
		if self:getIsTurnedOn() then
			self:setIsTurnedOn(false)
			return
		end
		if self.getAttacherVehicle ~= nil then
			local v50_ = self:getAttacherVehicle()
			if v50_ ~= nil and (v50_.setIsTurnedOn ~= nil and v50_:getIsTurnedOn()) then
				v50_:setIsTurnedOn(false)
			end
		end
	end
end

-- Local values: spec
function TurnOnVehicle:setIsTurnedOn(isTurnedOn, noEventSend)
	local v54_ = self.spec_turnOnVehicle
	if isTurnedOn ~= v54_.isTurnedOn then
		SetTurnedOnEvent.sendEvent(self, isTurnedOn, noEventSend)
		v54_.isTurnedOn = isTurnedOn
		if v54_.isTurnedOn then
			SpecializationUtil.raiseEvent(self, "onTurnedOn")
			self.rootVehicle:raiseStateChange(VehicleStateChange.TURN_ON, self)
		else
			SpecializationUtil.raiseEvent(self, "onTurnedOff")
			self.rootVehicle:raiseStateChange(VehicleStateChange.TURN_OFF, self)
		end
		if self.isClient and self.updateDashboardValueType ~= nil then
			self:updateDashboardValueType("turnOnVehicle.turnedOn")
		end
	end
end

-- Local values: spec, i
function TurnOnVehicle:onTurnedOn()
	local v56_ = self.spec_turnOnVehicle
	if self.isClient then
		if v56_.turnOnAnimation ~= nil then
			self:playAnimation(v56_.turnOnAnimation.name, v56_.turnOnAnimation.turnOnSpeedScale, self:getAnimationTime(v56_.turnOnAnimation.name), true)
		end
		g_soundManager:stopSamples(v56_.samples.start)
		g_soundManager:stopSamples(v56_.samples.work)
		g_soundManager:stopSamples(v56_.samples.stop)
		g_soundManager:playSamples(v56_.samples.start)
		for v57_ = 1, #v56_.samples.work do
			g_soundManager:playSample(v56_.samples.work[v57_], 0, v56_.samples.start[v57_] or v56_.samples.start[1])
		end
		g_animationManager:startAnimations(v56_.animationNodes)
		g_effectManager:startEffects(v56_.effects)
	end
	if v56_.activateableDischargeNode ~= nil and v56_.activateableDischargeNode.index ~= nil then
		v56_.activateableDischargeNodePrev = self:getCurrentDischargeNode()
		self:setCurrentDischargeNodeIndex(v56_.activateableDischargeNode.index)
	end
end

-- Local values: spec
function TurnOnVehicle:onTurnedOff()
	local v59_ = self.spec_turnOnVehicle
	if self.isClient then
		if v59_.turnOnAnimation ~= nil then
			self:playAnimation(v59_.turnOnAnimation.name, v59_.turnOnAnimation.turnOffSpeedScale, self:getAnimationTime(v59_.turnOnAnimation.name), true)
		end
		g_soundManager:stopSamples(v59_.samples.start)
		g_soundManager:stopSamples(v59_.samples.work)
		g_soundManager:stopSamples(v59_.samples.stop)
		g_soundManager:playSamples(v59_.samples.stop)
		g_animationManager:stopAnimations(v59_.animationNodes)
		g_effectManager:stopEffects(v59_.effects)
	end
	if v59_.activateableDischargeNodePrev ~= nil and v59_.activateableDischargeNodePrev.index ~= nil then
		self:setCurrentDischargeNodeIndex(v59_.activateableDischargeNodePrev.index)
		v59_.activateableDischargeNodePrev = nil
	end
end

-- Local values: spec
function TurnOnVehicle:getIsTurnedOn()
	local v61_ = self.spec_turnOnVehicle
	return v61_.isAlwaysTurnedOn or v61_.isTurnedOn
end

-- Local values: spec, inputAttacherJoint
function TurnOnVehicle:getCanBeTurnedOn()
	if self.spec_turnOnVehicle.isAlwaysTurnedOn then
		return false
	end
	if self.getInputAttacherJoint ~= nil then
		local v63_ = self:getInputAttacherJoint()
		if v63_ ~= nil and (v63_.canBeTurnedOn ~= nil and not v63_.canBeTurnedOn) then
			return false
		end
	end
	return self:getIsPowered() and true or false
end

-- Local values: vehicles, i, vehicle
function TurnOnVehicle:getCanBeTurnedOnAll()
	local v65_ = self.rootVehicle:getChildVehicles()
	for v66_ = 1, #v65_ do
		local v67_ = v65_[v66_]
		if v67_.getCanBeTurnedOn ~= nil and not v67_:getCanBeTurnedOn() then
			return false
		end
	end
	return true
end

-- Local values: spec
function TurnOnVehicle:getCanToggleTurnedOn()
	local v69_ = self.spec_turnOnVehicle
	if v69_.isAlwaysTurnedOn then
		return false
	else
		return not v69_.turnedOnByAttacherVehicle
	end
end

function TurnOnVehicle:getTurnedOnNotAllowedWarning()
	if self:getIsPowered() then
		return nil
	else
		return g_i18n:getText("warning_attachToPower")
	end
end

function TurnOnVehicle:getAIRequiresTurnOn()
	return self.spec_turnOnVehicle.aiRequiresTurnOn
end

function TurnOnVehicle:getRequiresTurnOn()
	return self.spec_turnOnVehicle.requiresTurnOn
end

function TurnOnVehicle.getAIRequiresTurnOffOnHeadland(self)
	return false
end

-- Local values: name
function TurnOnVehicle:loadTurnedOnAnimationFromXML(xmlFile, key, turnedOnAnimation)
	local v77_ = self.xmlFile:getValue(key .. "#name")
	if v77_ == nil then
		Logging.xmlWarning(xmlFile, "Missing animation name in \'%s\'", key)
		return false
	end
	turnedOnAnimation.name = v77_
	turnedOnAnimation.turnOnFadeTime = self.xmlFile:getValue(key .. "#turnOnFadeTime", 1) * 1000
	turnedOnAnimation.turnOffFadeTime = self.xmlFile:getValue(key .. "#turnOffFadeTime", 1) * 1000
	turnedOnAnimation.speedScale = self.xmlFile:getValue(key .. "#speedScale", 1)
	turnedOnAnimation.speedDirection = 0
	turnedOnAnimation.currentSpeed = 0
	turnedOnAnimation.isTurnedOn = false
	return true
end

function TurnOnVehicle:getIsTurnedOnAnimationActive(turnedOnAnimation)
	return self:getIsTurnedOn() and true or false
end

function TurnOnVehicle:getUseTurnedOnSchema(superFunc)
	return superFunc(self) or self:getIsTurnedOn()
end

function TurnOnVehicle:loadInputAttacherJoint(superFunc, xmlFile, key, inputAttacherJoint, i)
	if not superFunc(self, xmlFile, key, inputAttacherJoint, i) then
		return false
	end
	inputAttacherJoint.canBeTurnedOn = xmlFile:getValue(key .. "#canBeTurnedOn", true)
	return true
end

-- Local values: retValue
function TurnOnVehicle:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	local v92_ = superFunc(self, workArea, xmlFile, key)
	workArea.needsSetIsTurnedOn = xmlFile:getValue(key .. "#needsSetIsTurnedOn", true)
	return v92_
end

function TurnOnVehicle:getIsWorkAreaActive(superFunc, workArea)
	if self:getIsTurnedOn() or not workArea.needsSetIsTurnedOn then
		return superFunc(self, workArea)
	else
		return false
	end
end

-- Local values: canContinue, stopAI, stopReason
function TurnOnVehicle:getCanAIImplementContinueWork(superFunc, isTurning)
	local v99_, v100_, v101_ = superFunc(self, isTurning)
	if v99_ then
		return not self:getAIRequiresTurnOn() and true or (not self:getIsAIImplementInLine() and true or ((not self:getCanBeTurnedOn() or self:getIsTurnedOn()) and true or false))
	else
		return false, v100_, v101_
	end
end

function TurnOnVehicle:getIsOperating(superFunc)
	return self:getIsTurnedOn() and true or superFunc(self)
end

-- Local values: ret
function TurnOnVehicle:getAlarmTriggerIsActive(superFunc, alarmTrigger)
	local v107_ = superFunc(self, alarmTrigger)
	if alarmTrigger.needsTurnOn and not self:getIsTurnedOn() then
		v107_ = false
	end
	return v107_
end

-- Local values: ret
function TurnOnVehicle:loadAlarmTrigger(superFunc, xmlFile, key, alarmTrigger, fillUnit)
	local v114_ = superFunc(self, xmlFile, key, alarmTrigger, fillUnit)
	alarmTrigger.needsTurnOn = xmlFile:getValue(key .. "#needsTurnOn", false)
	alarmTrigger.turnOffInTrigger = xmlFile:getValue(key .. "#turnOffInTrigger", false)
	return v114_
end

-- Local values: spec
function TurnOnVehicle:getIsFillUnitActive(superFunc, fillUnitIndex)
	if self.spec_turnOnVehicle.activatableFillUnits[fillUnitIndex] == true and not self:getIsTurnedOn() then
		return false
	else
		return superFunc(self, fillUnitIndex)
	end
end

function TurnOnVehicle:loadShovelNode(superFunc, xmlFile, key, shovelNode)
	superFunc(self, xmlFile, key, shovelNode)
	shovelNode.needsActiveVehicle = xmlFile:getValue(key .. "#needsActivation", false)
	return true
end

function TurnOnVehicle:getShovelNodeIsActive(superFunc, shovelNode)
	if shovelNode.needsActiveVehicle and not self:getIsTurnedOn() then
		return false
	else
		return superFunc(self, shovelNode)
	end
end

function TurnOnVehicle:getIsSeedChangeAllowed(superFunc)
	local v128_ = superFunc(self)
	if v128_ then
		v128_ = not self:getIsTurnedOn()
	end
	return v128_
end

function TurnOnVehicle:getCanBeSelected(superFunc)
	return true
end

function TurnOnVehicle:getIsPowerTakeOffActive(superFunc)
	return self:getIsTurnedOn() or superFunc(self)
end

-- Local values: spec
function TurnOnVehicle:loadDischargeNode(superFunc, xmlFile, key, entry)
	if not superFunc(self, xmlFile, key, entry) then
		return false
	end
	entry.needsSetIsTurnedOn = xmlFile:getValue(key .. "#needsSetIsTurnedOn", false)
	entry.turnOnActivateNode = xmlFile:getValue(key .. "#turnOnActivateNode", false)
	if entry.turnOnActivateNode then
		self.spec_turnOnVehicle.activateableDischargeNode = entry
	end
	return true
end

function TurnOnVehicle:getIsDischargeNodeActive(superFunc, dischargeNode)
	if dischargeNode.needsSetIsTurnedOn and not self:getIsTurnedOn() then
		return false
	else
		return superFunc(self, dischargeNode)
	end
end

-- Local values: spec
function TurnOnVehicle:loadBunkerSiloCompactorFromXML(superFunc, xmlFile, key)
	superFunc(self, xmlFile, key)
	self.spec_bunkerSiloCompacter.turnedOnCompactingScale = xmlFile:getValue(key .. "#turnedOnCompactingScale")
end

-- Local values: spec
function TurnOnVehicle:getBunkerSiloCompacterScale(superFunc)
	local v145_ = self.spec_bunkerSiloCompacter
	if v145_.turnedOnCompactingScale == nil or not self:getIsTurnedOn() then
		return superFunc(self)
	else
		return v145_.turnedOnCompactingScale
	end
end

-- Local values: spec
function TurnOnVehicle:getIsWorkModeChangeAllowed(superFunc)
	if self.spec_workMode.allowChangeWhileTurnedOn == false and self:getIsTurnedOn() then
		return false
	else
		return superFunc(self)
	end
end

-- Local values: spec, _, actionEventId
function TurnOnVehicle:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v150_ = self.spec_turnOnVehicle
		self:clearActionEventsTable(v150_.actionEvents)
		if isActiveForInputIgnoreSelection and self:getCanToggleTurnedOn() then
			local _, v151_ = self:addPoweredActionEvent(v150_.actionEvents, v150_.toggleTurnOnInputBinding, self, TurnOnVehicle.actionEventTurnOn, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v151_, GS_PRIO_HIGH)
			TurnOnVehicle.updateActionEvents(self)
			local _, v152_ = self:addPoweredActionEvent(v150_.actionEvents, InputAction.TURN_ON_ALL_IMPLEMENTS, self, TurnOnVehicle.actionEventTurnOnAll, false, true, false, true, nil)
			g_inputBinding:setActionEventTextVisibility(v152_, false)
		end
	end
end

function TurnOnVehicle:onRegisterExternalActionEvents(trigger, name, xmlFile, key)
	if name == "turnOn" then
		self:registerExternalActionEvent(trigger, name, TurnOnVehicle.externalActionEventRegister, TurnOnVehicle.externalActionEventUpdate)
	end
end

function TurnOnVehicle:onAlarmTriggerChanged(alarmTrigger, state)
	if state and alarmTrigger.turnOffInTrigger then
		self:setIsTurnedOn(false, true)
	end
end

function TurnOnVehicle:onSetBroken()
	self:setIsTurnedOn(false, true)
end

function TurnOnVehicle:onStateChange(state, data)
	if state == VehicleStateChange.MOTOR_TURN_OFF and not self:getCanBeTurnedOn() then
		self:setIsTurnedOn(false, true)
	end
end

-- Local values: spec
function TurnOnVehicle:onDeactivate()
	if self.spec_turnOnVehicle.turnOffOnDeactivate then
		self:setIsTurnedOn(false, true)
	end
end

-- Local values: spec
function TurnOnVehicle:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	if self.spec_turnOnVehicle.turnedOnByAttacherVehicle and attacherVehicle.getIsTurnedOn ~= nil then
		self:setIsTurnedOn(attacherVehicle:getIsTurnedOn(), true)
	end
end

function TurnOnVehicle:onPreDetach(attacherVehicle, implement)
	self:setIsTurnedOn(false, true)
end

-- Local values: spec, actionController
function TurnOnVehicle:onRootVehicleChanged(rootVehicle)
	local v168_ = self.spec_turnOnVehicle
	local v169_ = rootVehicle.actionController
	if v169_ == nil or not self:getCanToggleTurnedOn() then
		if v168_.controlledAction ~= nil then
			v168_.controlledAction:remove()
		end
	else
		if v168_.controlledAction ~= nil then
			v168_.controlledAction:updateParent(v169_)
			return
		end
		v168_.controlledAction = v169_:registerAction("turnOn", v168_.toggleTurnOnInputBinding, 1)
		v168_.controlledAction:setCallback(self, TurnOnVehicle.actionControllerTurnOnEvent)
		v168_.controlledAction:setFinishedFunctions(self, self.getIsTurnedOn, true, false)
		v168_.controlledAction:setIsSaved(true)
		v168_.controlledAction:setIsAccessibleFunction(function()
			return true
		end)
		if self:getAIRequiresTurnOn() then
			if not self:getAIRequiresTurnOffOnHeadland() then
				v168_.controlledAction:addAIEventListener(self, "onAIFieldWorkerPrepareForWork", 1, true)
				v168_.controlledAction:addAIEventListener(self, "onAIImplementPrepareForWork", 1, true)
			end
			v168_.controlledAction:addAIEventListener(self, "onAIImplementStartLine", 1, true)
			v168_.controlledAction:addAIEventListener(self, "onAIImplementContinue", 1)
			v168_.controlledAction:addAIEventListener(self, "onAIImplementEnd", -1)
			v168_.controlledAction:addAIEventListener(self, "onAIImplementStart", -1)
			v168_.controlledAction:addAIEventListener(self, "onAIFieldWorkerEnd", -1)
			if self:getAIRequiresTurnOffOnHeadland() then
				v168_.controlledAction:addAIEventListener(self, "onAIImplementEndLine", -1)
			end
			v168_.controlledAction:addAIEventListener(self, "onAIImplementBlock", -1)
			v168_.controlledAction:addAIEventListener(self, "onAIImplementPrepareForTransport", -1)
			return
		end
	end
end

function TurnOnVehicle:actionControllerTurnOnEvent(direction)
	if direction <= 0 then
		self:setIsTurnedOn(false)
		return not self:getIsTurnedOn()
	end
	if not self:getCanBeTurnedOn() then
		return false
	end
	self:setIsTurnedOn(true)
	return true
end

-- Local values: warning
function TurnOnVehicle:actionEventTurnOn(actionName, inputValue, callbackState, isAnalog)
	if self:getCanToggleTurnedOn() and self:getCanBeTurnedOn() then
		self:setIsTurnedOn(not self:getIsTurnedOn())
	elseif not self:getIsTurnedOn() then
		local v173_ = self:getTurnedOnNotAllowedWarning()
		if v173_ ~= nil then
			g_currentMission:showBlinkingWarning(v173_, 2000)
		end
	end
end

-- Local values: canBeTurnedOn, warning, vehicles, i, vehicle
function TurnOnVehicle:actionEventTurnOnAll(actionName, inputValue, callbackState, isAnalog)
	if self:getCanToggleTurnedOn() then
		local v175_, v176_ = self:getCanBeTurnedOnAll()
		if v175_ then
			local v177_ = self.rootVehicle:getChildVehicles()
			for v178_ = 1, #v177_ do
				local v179_ = v177_[v178_]
				if v179_.setIsTurnedOn ~= nil then
					v179_:setIsTurnedOn(not v179_:getIsTurnedOn())
				end
			end
			return
		end
		if not self:getIsTurnedOn() and v176_ ~= nil then
			g_currentMission:showBlinkingWarning(v176_, 2000)
		end
	end
end

-- Local values: spec, actionEvent, state, text
function TurnOnVehicle:updateActionEvents()
	local v181_ = self.spec_turnOnVehicle
	local v182_ = v181_.actionEvents[v181_.toggleTurnOnInputBinding]
	if v182_ ~= nil then
		local v183_ = self:getCanToggleTurnedOn()
		if v183_ then
			local v184_
			if self:getIsTurnedOn() then
				v184_ = v181_.turnOffText
			else
				v184_ = v181_.turnOnText
			end
			g_inputBinding:setActionEventText(v182_.actionEventId, v184_)
		end
		g_inputBinding:setActionEventActive(v182_.actionEventId, v183_)
	end
end

-- Local values: actionEvent, spec, _
function TurnOnVehicle.externalActionEventRegister(data, vehicle)
	local v187_ = vehicle.spec_turnOnVehicle
	local _, v192_ = g_inputBinding:registerActionEvent(v187_.toggleTurnOnInputBinding, data, function(_, p188_, p189_, p190_, p191_)
		-- upvalues: (copy) vehicle
		Motorized.tryStartMotor(vehicle)
		TurnOnVehicle.actionEventTurnOn(vehicle, p188_, p189_, p190_, p191_)
	end, false, true, false, true)
	data.actionEventId = v192_
	g_inputBinding:setActionEventTextPriority(data.actionEventId, GS_PRIO_HIGH)
end

-- Local values: state, text
function TurnOnVehicle.externalActionEventUpdate(data, vehicle)
	if data.actionEventId ~= nil then
		local v195_ = vehicle:getCanToggleTurnedOn()
		if v195_ then
			local v196_
			if vehicle:getIsTurnedOn() then
				v196_ = vehicle.spec_turnOnVehicle.turnOffText
			else
				v196_ = vehicle.spec_turnOnVehicle.turnOnText
			end
			g_inputBinding:setActionEventText(data.actionEventId, v196_)
		end
		g_inputBinding:setActionEventActive(data.actionEventId, v195_)
	end
end

function TurnOnVehicle:getTurnedOnSpeedFactor()
	return self.spec_turnOnVehicle.turnedOnSpeed.alpha
end
g_soundManager:registerModifierType("TURNED_ON_SPEED", TurnOnVehicle.getTurnedOnSpeedFactor)

function TurnOnVehicle:dashboardRpmAttributes(xmlFile, key, dashboard, isActive)
	dashboard.minRpm = xmlFile:getValue(key .. "#minRpm", 0)
	dashboard.maxRpm = xmlFile:getValue(key .. "#maxRpm", 1000)
	return true
end

function TurnOnVehicle:dashboardRpmValue(dashboard)
	return dashboard.minRpm + (dashboard.maxRpm - dashboard.minRpm) * self.spec_turnOnVehicle.turnedOnSpeed.alpha
end
