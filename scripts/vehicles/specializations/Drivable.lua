source("dataS/scripts/vehicles/specializations/events/SetCruiseControlStateEvent.lua")
source("dataS/scripts/vehicles/specializations/events/SetCruiseControlSpeedEvent.lua")
Drivable = {}
Drivable.CRUISECONTROL_STATE_OFF = 0
Drivable.CRUISECONTROL_STATE_ACTIVE = 1
Drivable.CRUISECONTROL_STATE_FULL = 2
Drivable.CRUISECONTROL_FULL_TOGGLE_TIME = 500
source("dataS/scripts/gui/hud/extensions/CruiseControlHUDExtension.lua")

function Drivable.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(Enterable, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(Motorized, specializations)
	end
	return v2_
end
function Drivable.initSpecialization()
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("Drivable")
	v3_:register(XMLValueType.INT, "vehicle.drivable#reverserDirection", "Default state of reverser direction (when set to -1 the driving direction is inverted)", 1)
	v3_:register(XMLValueType.INT, "vehicle.drivable#steeringDirection", "Default state of steering direction (when set to -1 the steering direction is inverted)", 1)
	v3_:register(XMLValueType.FLOAT, "vehicle.drivable.speedRotScale#scale", "Speed dependent steering speed scale", 80)
	v3_:register(XMLValueType.FLOAT, "vehicle.drivable.speedRotScale#offset", "Speed dependent steering speed offset", 0.7)
	v3_:register(XMLValueType.FLOAT, "vehicle.drivable.cruiseControl#maxSpeed", "Max. cruise control speed", "Max. vehicle speed")
	v3_:register(XMLValueType.FLOAT, "vehicle.drivable.cruiseControl#minSpeed", "Min. cruise control speed", 1)
	v3_:register(XMLValueType.FLOAT, "vehicle.drivable.cruiseControl#maxSpeedReverse", "Max. cruise control speed in reverse", "Max. value reverse speed")
	v3_:register(XMLValueType.BOOL, "vehicle.drivable.cruiseControl#enabled", "Cruise control enabled", true)
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.drivable.steeringWheel#node", "Steering wheel node")
	v3_:register(XMLValueType.ANGLE, "vehicle.drivable.steeringWheel#indoorRotation", "Steering wheel indoor rotation", 0)
	v3_:register(XMLValueType.ANGLE, "vehicle.drivable.steeringWheel#outdoorRotation", "Steering wheel outdoor rotation", 0)
	v3_:register(XMLValueType.BOOL, "vehicle.drivable.idleTurning#allowed", "When vehicle is not moving and steering keys are pressed turns on the same spot", false)
	v3_:register(XMLValueType.BOOL, "vehicle.drivable.idleTurning#updateSteeringWheel", "Update steering wheel", true)
	v3_:register(XMLValueType.BOOL, "vehicle.drivable.idleTurning#lockDirection", "Defines if the direction is locked until player accelerates again", true)
	v3_:register(XMLValueType.INT, "vehicle.drivable.idleTurning#direction", "Driving direction [-1, 1]", 1)
	v3_:register(XMLValueType.FLOAT, "vehicle.drivable.idleTurning#maxSpeed", "Max. speed while turning", 10)
	v3_:register(XMLValueType.FLOAT, "vehicle.drivable.idleTurning#steeringFactor", "Steering speed factor", 100)
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.drivable.idleTurning.wheel(?)#node", "Wheel node to change")
	v3_:register(XMLValueType.ANGLE, "vehicle.drivable.idleTurning.wheel(?)#steeringAngle", "Steering angle while idle turning")
	v3_:register(XMLValueType.BOOL, "vehicle.drivable.idleTurning.wheel(?)#inverted", "Acceleration is inverted", false)
	Dashboard.registerDashboardXMLPaths(v3_, "vehicle.drivable.dashboards", {
		"cruiseControl",
		"cruiseControlReverse",
		"directionForward",
		"directionBackward",
		"movingDirection",
		"cruiseControlActive",
		"accelerationAxis",
		"decelerationAxis",
		"ac_decelerationAxis",
		"steeringAngle",
		"combinedPedalLeft",
		"combinedPedalRight",
		"odometerMilage"
	})
	SoundManager.registerSampleXMLPaths(v3_, "vehicle.drivable.sounds", "waterSplash")
	v3_:setXMLSpecializationType()
	local v4_ = Vehicle.xmlSchemaSavegame
	v4_:register(XMLValueType.INT, "vehicles.vehicle(?).drivable#cruiseControl", "Current cruise control speed")
	v4_:register(XMLValueType.INT, "vehicles.vehicle(?).drivable#cruiseControlReverse", "Current cruise control speed reverse")
	v4_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).drivable#odometerMilage", "Current odometer milage (km)", 0)
end

function Drivable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "updateSteeringWheel", Drivable.updateSteeringWheel)
	SpecializationUtil.registerFunction(vehicleType, "setCruiseControlState", Drivable.setCruiseControlState)
	SpecializationUtil.registerFunction(vehicleType, "setCruiseControlMaxSpeed", Drivable.setCruiseControlMaxSpeed)
	SpecializationUtil.registerFunction(vehicleType, "getCruiseControlState", Drivable.getCruiseControlState)
	SpecializationUtil.registerFunction(vehicleType, "getCruiseControlSpeed", Drivable.getCruiseControlSpeed)
	SpecializationUtil.registerFunction(vehicleType, "getCruiseControlMaxSpeed", Drivable.getCruiseControlMaxSpeed)
	SpecializationUtil.registerFunction(vehicleType, "getCruiseControlDisplayInfo", Drivable.getCruiseControlDisplayInfo)
	SpecializationUtil.registerFunction(vehicleType, "getAxisForward", Drivable.getAxisForward)
	SpecializationUtil.registerFunction(vehicleType, "getAccelerationAxis", Drivable.getAccelerationAxis)
	SpecializationUtil.registerFunction(vehicleType, "getDecelerationAxis", Drivable.getDecelerationAxis)
	SpecializationUtil.registerFunction(vehicleType, "getCruiseControlAxis", Drivable.getCruiseControlAxis)
	SpecializationUtil.registerFunction(vehicleType, "getAcDecelerationAxis", Drivable.getAcDecelerationAxis)
	SpecializationUtil.registerFunction(vehicleType, "getDashboardSteeringAxis", Drivable.getDashboardSteeringAxis)
	SpecializationUtil.registerFunction(vehicleType, "setReverserDirection", Drivable.setReverserDirection)
	SpecializationUtil.registerFunction(vehicleType, "getReverserDirection", Drivable.getReverserDirection)
	SpecializationUtil.registerFunction(vehicleType, "getSteeringDirection", Drivable.getSteeringDirection)
	SpecializationUtil.registerFunction(vehicleType, "getIsDrivingForward", Drivable.getIsDrivingForward)
	SpecializationUtil.registerFunction(vehicleType, "getIsDrivingBackward", Drivable.getIsDrivingBackward)
	SpecializationUtil.registerFunction(vehicleType, "getDrivingDirection", Drivable.getDrivingDirection)
	SpecializationUtil.registerFunction(vehicleType, "getIsVehicleControlledByPlayer", Drivable.getIsVehicleControlledByPlayer)
	SpecializationUtil.registerFunction(vehicleType, "getIsPlayerVehicleControlAllowed", Drivable.getIsPlayerVehicleControlAllowed)
	SpecializationUtil.registerFunction(vehicleType, "registerPlayerVehicleControlAllowedFunction", Drivable.registerPlayerVehicleControlAllowedFunction)
	SpecializationUtil.registerFunction(vehicleType, "updateVehiclePhysics", Drivable.updateVehiclePhysics)
	SpecializationUtil.registerFunction(vehicleType, "setAccelerationPedalInput", Drivable.setAccelerationPedalInput)
	SpecializationUtil.registerFunction(vehicleType, "setBrakePedalInput", Drivable.setBrakePedalInput)
	SpecializationUtil.registerFunction(vehicleType, "setTargetSpeedAndDirection", Drivable.setTargetSpeedAndDirection)
	SpecializationUtil.registerFunction(vehicleType, "setSteeringInput", Drivable.setSteeringInput)
	SpecializationUtil.registerFunction(vehicleType, "brakeToStop", Drivable.brakeToStop)
	SpecializationUtil.registerFunction(vehicleType, "updateSteeringAngle", Drivable.updateSteeringAngle)
end

function Drivable.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsManualDirectionChangeAllowed", Drivable.getIsManualDirectionChangeAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getMapHotspotRotation", Drivable.getMapHotspotRotation)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setTransmissionDirection", Drivable.setTransmissionDirection)
end

function Drivable.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onVehiclePhysicsUpdate")
	SpecializationUtil.registerEvent(vehicleType, "onCruiseControlSpeedChanged")
end

function Drivable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Drivable)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", Drivable)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Drivable)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Drivable)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Drivable)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Drivable)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Drivable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Drivable)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", Drivable)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Drivable)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", Drivable)
	SpecializationUtil.registerEventListener(vehicleType, "onSetBroken", Drivable)
end

-- Local values: spec, motor, node, _, ry, _, maxSpeed, maxSpeedReverse
function Drivable:onLoad(savegame)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.steering#index", "vehicle.drivable.steeringWheel#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.steering#node", "vehicle.drivable.steeringWheel#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cruiseControl", "vehicle.drivable.cruiseControl")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.indoorHud.cruiseControl", "vehicle.drivable.dashboards.dashboard with valueType \'cruiseControl\'")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.showChangeToolSelectionHelp")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.maxRotatedTimeSpeed#value")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.speedRotScale#scale", "vehicle.drivable.speedRotScale#scale")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.speedRotScale#offset", "vehicle.drivable.speedRotScale#offset")
	local v_u_11_ = self.spec_drivable
	v_u_11_.showToolSelectionHud = true
	v_u_11_.doHandbrake = false
	v_u_11_.doHandbrakeSend = false
	v_u_11_.reverserDirection = self.xmlFile:getValue("vehicle.drivable#reverserDirection", 1)
	v_u_11_.steeringDirection = self.xmlFile:getValue("vehicle.drivable#steeringDirection", 1)
	v_u_11_.lastInputValues = {}
	v_u_11_.lastInputValues.axisAccelerate = 0
	v_u_11_.lastInputValues.axisBrake = 0
	v_u_11_.lastInputValues.axisSteer = 0
	v_u_11_.lastInputValues.axisSteerIsAnalog = false
	v_u_11_.lastInputValues.axisSteerDeviceCategory = InputDevice.CATEGORY.UNKNOWN
	v_u_11_.lastInputValues.cruiseControlValue = 0
	v_u_11_.lastInputValues.cruiseControlState = 0
	v_u_11_.axisForward = 0
	v_u_11_.axisForwardSend = 0
	v_u_11_.axisSide = 0
	v_u_11_.axisSideSend = 0
	v_u_11_.axisSideLast = 0
	v_u_11_.lastIsControlled = false
	v_u_11_.speedRotScale = self.xmlFile:getValue("vehicle.drivable.speedRotScale#scale", 80)
	v_u_11_.speedRotScaleOffset = self.xmlFile:getValue("vehicle.drivable.speedRotScale#offset", 0.7)
	local v12_ = self:getMotor()
	v_u_11_.cruiseControl = {}
	v_u_11_.cruiseControl.maxSpeed = self.xmlFile:getValue("vehicle.drivable.cruiseControl#maxSpeed", MathUtil.round(v12_:getMaximumForwardSpeed() * 3.6))
	local v13_ = v_u_11_.cruiseControl
	local v14_ = self.xmlFile
	local v15_ = v_u_11_.cruiseControl.maxSpeed
	v13_.minSpeed = v14_:getValue("vehicle.drivable.cruiseControl#minSpeed", (math.min(1, v15_)))
	v_u_11_.cruiseControl.speed = v_u_11_.cruiseControl.maxSpeed
	v_u_11_.cruiseControl.maxSpeedReverse = self.xmlFile:getValue("vehicle.drivable.cruiseControl#maxSpeedReverse", MathUtil.round(v12_:getMaximumBackwardSpeed() * 3.6))
	v_u_11_.cruiseControl.speedReverse = v_u_11_.cruiseControl.maxSpeedReverse
	v_u_11_.cruiseControl.isActive = self.xmlFile:getValue("vehicle.drivable.cruiseControl#enabled", true)
	v_u_11_.cruiseControl.state = Drivable.CRUISECONTROL_STATE_OFF
	v_u_11_.cruiseControl.topSpeedTime = 1000
	v_u_11_.cruiseControl.changeDelay = 250
	v_u_11_.cruiseControl.changeCurrentDelay = 0
	v_u_11_.cruiseControl.changeMultiplier = 1
	v_u_11_.cruiseControl.transmissionDirection = 1
	v_u_11_.cruiseControl.speedSent = v_u_11_.cruiseControl.speed
	v_u_11_.cruiseControl.speedReverseSent = v_u_11_.cruiseControl.speedReverse
	local v16_ = self.xmlFile:getValue("vehicle.drivable.steeringWheel#node", nil, self.components, self.i3dMappings)
	if v16_ ~= nil then
		v_u_11_.steeringWheel = {}
		v_u_11_.steeringWheel.node = v16_
		local _, v17_, _ = getRotation(v_u_11_.steeringWheel.node)
		v_u_11_.steeringWheel.lastRotation = v17_
		v_u_11_.steeringWheel.indoorRotation = self.xmlFile:getValue("vehicle.drivable.steeringWheel#indoorRotation", 0)
		v_u_11_.steeringWheel.outdoorRotation = self.xmlFile:getValue("vehicle.drivable.steeringWheel#outdoorRotation", 0)
	end
	v_u_11_.idleTurningAllowed = self.xmlFile:getValue("vehicle.drivable.idleTurning#allowed", false)
	v_u_11_.idleTurningUpdateSteeringWheel = self.xmlFile:getValue("vehicle.drivable.idleTurning#updateSteeringWheel", true)
	v_u_11_.idleTurningLockDirection = self.xmlFile:getValue("vehicle.drivable.idleTurning#lockDirection", true)
	v_u_11_.idleTurningDrivingDirection = self.xmlFile:getValue("vehicle.drivable.idleTurning#direction", 1)
	v_u_11_.idleTurningMaxSpeed = self.xmlFile:getValue("vehicle.drivable.idleTurning#maxSpeed", 10)
	v_u_11_.idleTurningSteeringFactor = self.xmlFile:getValue("vehicle.drivable.idleTurning#steeringFactor", 100)
	v_u_11_.idleTurningWheels = {}
	self.xmlFile:iterate("vehicle.drivable.idleTurning.wheel", function(_, p18_)
		-- upvalues: (copy) self, (copy) v_u_11_
		local v19_ = self.xmlFile:getValue(p18_ .. "#node", nil, self.components, self.i3dMappings)
		if v19_ ~= nil then
			local v20_ = {
				["wheelNode"] = v19_,
				["steeringAngle"] = self.xmlFile:getValue(p18_ .. "#steeringAngle", 0),
				["inverted"] = self.xmlFile:getValue(p18_ .. "#inverted", false)
			}
			local v21_ = v_u_11_.idleTurningWheels
			table.insert(v21_, v20_)
		end
	end)
	v_u_11_.idleTurningActive = false
	v_u_11_.idleTurningActiveSend = false
	v_u_11_.idleTurningDirection = 0
	self.customSteeringAngleFunction = self.customSteeringAngleFunction or #v_u_11_.idleTurningWheels > 0
	v_u_11_.forceFeedback = {}
	v_u_11_.forceFeedback.isActive = false
	v_u_11_.forceFeedback.device = nil
	v_u_11_.forceFeedback.binding = nil
	v_u_11_.forceFeedback.axisIndex = 0
	v_u_11_.forceFeedback.intensity = g_gameSettings:getValue(GameSettings.SETTING.FORCE_FEEDBACK)
	v_u_11_.playerControlAllowedFunctions = {}
	v_u_11_.hasPlayerControlAllowedFunctions = false
	v_u_11_.initialWheelPhysicsUpdate = true
	v_u_11_.odometerMilage = 0
	if self.isClient then
		v_u_11_.samples = {}
		v_u_11_.samples.waterSplash = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.drivable.sounds", "waterSplash", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		if self.isClient and (g_isDevelopmentVersion and (not GS_IS_MOBILE_VERSION and v_u_11_.samples.waterSplash == nil)) then
			Logging.xmlDevWarning(self.xmlFile, "Missing drivable waterSplash sound")
		end
	end
	if savegame ~= nil then
		self:setCruiseControlMaxSpeed(savegame.xmlFile:getValue(savegame.key .. ".drivable#cruiseControl"), (savegame.xmlFile:getValue(savegame.key .. ".drivable#cruiseControlReverse")))
		v_u_11_.odometerMilage = savegame.xmlFile:getValue(savegame.key .. ".drivable#odometerMilage", v_u_11_.odometerMilage)
	end
	v_u_11_.hudExtension = CruiseControlHUDExtension.new(self)
	v_u_11_.dirtyFlag = self:getNextDirtyFlag()
end

-- Local values: spec, cruiseControl, cruiseControlReverse, cruiseControlActive, directionForward, directionBackward, movingDirection, accelerationAxis, decelerationAxis, ac_decelerationAxis, steeringAngle, combinedPedalLeft, combinedPedalRight, odometerMilage
function Drivable:onRegisterDashboardValueTypes()
	local v23_ = self.spec_drivable
	local v24_ = DashboardValueType.new("drivable", "cruiseControl")
	v24_:setValue(v23_.cruiseControl, "speed")
	self:registerDashboardValueType(v24_)
	local v25_ = DashboardValueType.new("drivable", "cruiseControlReverse")
	v25_:setValue(v23_.cruiseControl, "speedReverse")
	self:registerDashboardValueType(v25_)
	local v26_ = DashboardValueType.new("drivable", "cruiseControlActive")
	v26_:setValue(v23_.cruiseControl, "state")
	v26_:setValueCompare(Drivable.CRUISECONTROL_STATE_ACTIVE, Drivable.CRUISECONTROL_STATE_FULL)
	self:registerDashboardValueType(v26_)
	local v27_ = DashboardValueType.new("drivable", "directionForward")
	v27_:setValue(self, "getIsDrivingForward")
	self:registerDashboardValueType(v27_)
	local v28_ = DashboardValueType.new("drivable", "directionBackward")
	v28_:setValue(self, "getIsDrivingBackward")
	self:registerDashboardValueType(v28_)
	local v29_ = DashboardValueType.new("drivable", "movingDirection")
	v29_:setValue(self, "getDrivingDirection")
	v29_:setRange(-1, 1)
	self:registerDashboardValueType(v29_)
	local v30_ = DashboardValueType.new("drivable", "accelerationAxis")
	v30_:setValue(self, "getAccelerationAxis")
	self:registerDashboardValueType(v30_)
	local v31_ = DashboardValueType.new("drivable", "decelerationAxis")
	v31_:setValue(self, "getDecelerationAxis")
	self:registerDashboardValueType(v31_)
	local v32_ = DashboardValueType.new("drivable", "ac_decelerationAxis")
	v32_:setValue(self, "getAcDecelerationAxis")
	self:registerDashboardValueType(v32_)
	local v33_ = DashboardValueType.new("drivable", "steeringAngle")
	v33_:setValue(self, "getDashboardSteeringAxis")
	v33_:setRange(-1, 1)
	self:registerDashboardValueType(v33_)
	local v34_ = DashboardValueType.new("drivable", "combinedPedalLeft")
	v34_:setValue(self, Drivable.getDashboardCombinedPedalLeft)
	v34_:setRange(-1, 1)
	self:registerDashboardValueType(v34_)
	local v35_ = DashboardValueType.new("drivable", "combinedPedalRight")
	v35_:setValue(self, Drivable.getDashboardCombinedPedalRight)
	v35_:setRange(-1, 1)
	self:registerDashboardValueType(v35_)
	local v36_ = DashboardValueType.new("drivable", "odometerMilage")
	v36_:setValue(v23_, "odometerMilage")
	self:registerDashboardValueType(v36_)
end

-- Local values: spec
function Drivable:onDelete()
	local v38_ = self.spec_drivable
	g_soundManager:deleteSamples(v38_.samples)
	if v38_.hudExtension ~= nil then
		v38_.hudExtension:delete()
	end
end

-- Local values: spec
function Drivable:saveToXMLFile(xmlFile, key, usedModNames)
	local v42_ = self.spec_drivable
	xmlFile:setValue(key .. "#cruiseControl", v42_.cruiseControl.speed)
	xmlFile:setValue(key .. "#cruiseControlReverse", v42_.cruiseControl.speedReverse)
	xmlFile:setValue(key .. "#odometerMilage", v42_.odometerMilage)
end

-- Local values: spec, speed, speedReverse
function Drivable:onReadStream(streamId, connection)
	local v45_ = self.spec_drivable
	if v45_.cruiseControl.isActive then
		self:setCruiseControlState(streamReadUIntN(streamId, 2), true)
		local v46_ = streamReadUInt8(streamId)
		local v47_ = streamReadUInt8(streamId)
		self:setCruiseControlMaxSpeed(v46_, v47_)
		v45_.cruiseControl.speedSent = v46_
		v45_.cruiseControl.speedReverseSent = v47_
		v45_.odometerMilage = streamReadFloat32(streamId)
	end
end

-- Local values: spec
function Drivable:onWriteStream(streamId, connection)
	local v50_ = self.spec_drivable
	if v50_.cruiseControl.isActive then
		streamWriteUIntN(streamId, v50_.cruiseControl.state, 2)
		streamWriteUInt8(streamId, v50_.cruiseControl.speed)
		streamWriteUInt8(streamId, v50_.cruiseControl.speedReverse)
		streamWriteFloat32(streamId, v50_.odometerMilage)
	end
end

-- Local values: spec
function Drivable:onReadUpdateStream(streamId, timestamp, connection)
	local v53_ = self.spec_drivable
	if streamReadBool(streamId) then
		v53_.axisForward = streamReadUIntN(streamId, 10) / 1023 * 2 - 1
		local v54_ = v53_.axisForward
		if math.abs(v54_) < 0.00099 then
			v53_.axisForward = 0
		end
		v53_.axisSide = streamReadUIntN(streamId, 10) / 1023 * 2 - 1
		local v55_ = v53_.axisSide
		if math.abs(v55_) < 0.00099 then
			v53_.axisSide = 0
		end
		v53_.doHandbrake = streamReadBool(streamId)
		v53_.idleTurningActive = streamReadBool(streamId)
	end
end

-- Local values: spec, axisForward, axisSide
function Drivable:onWriteUpdateStream(streamId, connection, dirtyMask)
	local v59_ = self.spec_drivable
	local v60_ = streamWriteBool
	local v61_ = v59_.dirtyFlag
	if v60_(streamId, bit32.band(dirtyMask, v61_) ~= 0) then
		local v62_ = v59_.axisForward + 1
		local v63_ = math.clamp(v62_, 0, 2) / 2 * 1023
		streamWriteUIntN(streamId, v63_, 10)
		local v64_ = v59_.axisSide + 1
		local v65_ = math.clamp(v64_, 0, 2) / 2 * 1023
		streamWriteUIntN(streamId, v65_, 10)
		streamWriteBool(streamId, v59_.doHandbrake)
		streamWriteBool(streamId, v59_.idleTurningActive)
	end
end

-- Local values: spec, lastSpeed, axisForward, currentSpeed, targetSpeed, speedDifference, speedFactor, sensitivitySetting, axisSteer, isArticulatedSteering, forceFeedback, angleFactor, speedForceFactor, targetState, force, isSteeringBack, rotateBackSpeedSetting, speed, setting, steeringDuration, rotDelta, inputValue, lastCruiseControlValue, dir, speed, speedReverse, useReverseSpeed, isControlled, cruiseControlSpeed, diff, dir, limit, maxSpeed, _, allowed, inputHelpMode, dx, dy, dz, steeringValue
function Drivable:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v68_ = self.spec_drivable
	if self.isClient and (self.getIsEntered ~= nil and self:getIsEntered()) then
		if self.isActiveForInputIgnoreSelectionIgnoreAI then
			if self:getIsVehicleControlledByPlayer() then
				local v69_ = self:getLastSpeed()
				v68_.doHandbrake = false
				local v70_ = v68_.lastInputValues.axisAccelerate - v68_.lastInputValues.axisBrake
				local v71_ = math.clamp(v70_, -1, 1)
				v68_.axisForward = v71_
				if v68_.brakeToStop then
					v68_.lastInputValues.targetSpeed = 0.51
					v68_.lastInputValues.targetDirection = 1
					if v69_ < 1 then
						v68_.brakeToStop = false
						v68_.lastInputValues.targetSpeed = nil
						v68_.lastInputValues.targetDirection = nil
					end
				end
				if v68_.lastInputValues.targetSpeed ~= nil then
					local v72_ = v69_ * self.movingDirection * self:getReverserDirection()
					local v73_ = v68_.lastInputValues.targetSpeed * v68_.lastInputValues.targetDirection
					local v74_ = v73_ - v72_
					if math.abs(v74_) > 0.1 and math.abs(v73_) > 0.5 then
						local v75_ = math.abs(v74_)
						local v76_ = math.pow(v75_, 1.5) * math.sign(v74_)
						v68_.axisForward = math.clamp(v76_, -1, 1)
					end
				end
				if self:getIsPowered() then
					local v77_ = 1
					local v78_ = g_gameSettings:getValue(GameSettings.SETTING.STEERING_SENSITIVITY)
					local v79_ = v68_.lastInputValues.axisSteer
					local v80_
					if v68_.lastInputValues.axisSteerIsAnalog then
						local v81_
						if self.spec_articulatedAxis == nil then
							v81_ = false
						else
							v81_ = self.spec_articulatedAxis.componentJoint ~= nil
						end
						v80_ = v81_ and 1.5 or 2.5
						if GS_IS_MOBILE_VERSION then
							v80_ = v80_ * 1.5
							if v79_ == 0 then
								v80_ = v80_ * g_gameSettings:getValue(GameSettings.SETTING.STEERING_BACK_SPEED) / 10
							end
							local v82_ = math.abs(v79_)
							local v83_ = 1 / v78_
							v79_ = math.pow(v82_, v83_) * (v79_ >= 0 and 1 or -1)
						elseif v68_.lastInputValues.axisSteerDeviceCategory == InputDevice.CATEGORY.GAMEPAD then
							local v84_ = 1 / (self.lastSpeed * v68_.speedRotScale + v68_.speedRotScaleOffset)
							local v85_ = math.min(v84_, 1)
							v80_ = v85_ * v85_ * v78_ * 1.75
						end
						local v86_ = v68_.forceFeedback
						if v86_.isActive then
							if v86_.intensity > 0 then
								local v87_ = math.abs(v79_)
								local v88_ = (v69_ - 2) / 15
								local v89_ = math.min(v88_, 1)
								local v90_ = math.max(v89_, 0)
								local v91_ = v79_ - 0.2 * v90_ * math.sign(v79_)
								local v92_ = math.abs(v91_) * 0.4
								local v93_ = math.max(v92_, 0.25) * v90_ * v87_ * 2 * v86_.intensity
								v86_.device:setForceFeedback(v86_.axisIndex, v93_, v91_)
							else
								v86_.device:setForceFeedback(v86_.axisIndex, 0, v79_)
							end
						end
					else
						local v94_
						if v68_.lastInputValues.axisSteer == 0 then
							v94_ = false
						else
							local v95_ = v68_.lastInputValues.axisSteer
							local v96_ = math.sign(v95_)
							local v97_ = v68_.axisSide
							v94_ = v96_ ~= math.sign(v97_)
						end
						if v68_.lastInputValues.axisSteer == 0 or v94_ then
							local v98_ = g_gameSettings:getValue(GameSettings.SETTING.STEERING_BACK_SPEED) / 10
							if not v94_ and (v98_ < 1 and self.speedDependentRotateBack) then
								local v99_ = v69_ - 0.5
								local v100_ = math.max(v99_, 0) / 36 * (v98_ / 0.5)
								v77_ = v77_ * math.min(v100_, 1)
							end
							v80_ = v77_ * (self.autoRotateBackSpeed or 1) / 1.5
						else
							local v101_ = 1 / (self.lastSpeed * v68_.speedRotScale + v68_.speedRotScaleOffset)
							v80_ = math.min(v101_, 1) * v78_
						end
					end
					if v68_.idleTurningAllowed then
						if v71_ == 0 and (math.abs(v79_) > 0.05 and (v69_ < 1 and not v68_.idleTurningActive)) then
							v68_.idleTurningActive = true
							v68_.idleTurningDirection = math.sign(v79_) * v68_.idleTurningDrivingDirection
						end
						if v71_ ~= 0 and v68_.idleTurningActive then
							v68_.idleTurningActive = false
							if v79_ > 0 then
								self.rotatedTime = self.minRotTime
								v68_.axisSide = 1
							elseif v79_ < 0 then
								self.rotatedTime = self.maxRotTime
								v68_.axisSide = -1
							end
						end
						if v68_.idleTurningActive and not v68_.idleTurningLockDirection then
							v68_.idleTurningDirection = v68_.idleTurningDrivingDirection
							if v79_ == 0 then
								v68_.idleTurningActive = false
								v68_.axisSide = 0
							end
						end
						if v68_.idleTurningActive then
							v68_.axisForward = v68_.idleTurningDirection * math.sign(v79_)
							v79_ = math.abs(v79_) * v68_.idleTurningDirection
							v80_ = v80_ * v68_.idleTurningSteeringFactor
						end
					end
					local v102_ = dt / ((self.wheelSteeringDuration or 1) * 1000) * v80_
					if v68_.axisSide < v79_ then
						local v103_ = v68_.axisSide + v102_
						v68_.axisSide = math.min(v79_, v103_)
					elseif v79_ < v68_.axisSide then
						local v104_ = v68_.axisSide - v102_
						v68_.axisSide = math.max(v79_, v104_)
					end
				end
			else
				v68_.axisForward = 0
				v68_.idleTurningActive = false
				if self.rotatedTime < 0 then
					v68_.axisSide = self.rotatedTime / -self.maxRotTime / self:getSteeringDirection()
				else
					v68_.axisSide = self.rotatedTime / self.minRotTime / self:getSteeringDirection()
				end
			end
		else
			v68_.doHandbrake = true
			v68_.axisForward = 0
			v68_.idleTurningActive = false
		end
		v68_.lastInputValues.axisAccelerate = 0
		v68_.lastInputValues.axisBrake = 0
		v68_.lastInputValues.axisSteer = 0
		if v68_.axisForward ~= v68_.axisForwardSend or (v68_.axisSide ~= v68_.axisSideSend or (v68_.doHandbrake ~= v68_.doHandbrakeSend or v68_.idleTurningActiveSend ~= v68_.idleTurningActive)) then
			v68_.axisForwardSend = v68_.axisForward
			v68_.axisSideSend = v68_.axisSide
			v68_.doHandbrakeSend = v68_.doHandbrake
			v68_.idleTurningActiveSend = v68_.idleTurningActive
			self:raiseDirtyFlags(v68_.dirtyFlag)
		end
	end
	if self.isClient and (self.getIsEntered ~= nil and self:getIsEntered()) then
		local v105_ = v68_.lastInputValues.cruiseControlState
		v68_.lastInputValues.cruiseControlState = 0
		if v105_ == 1 then
			if v68_.cruiseControl.topSpeedTime == Drivable.CRUISECONTROL_FULL_TOGGLE_TIME then
				if v68_.cruiseControl.state == Drivable.CRUISECONTROL_STATE_OFF then
					self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_ACTIVE)
				else
					self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)
				end
			end
			if v68_.cruiseControl.topSpeedTime > 0 then
				v68_.cruiseControl.topSpeedTime = v68_.cruiseControl.topSpeedTime - dt
				if v68_.cruiseControl.topSpeedTime < 0 then
					self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_FULL)
				end
			end
		else
			v68_.cruiseControl.topSpeedTime = Drivable.CRUISECONTROL_FULL_TOGGLE_TIME
		end
		local v106_ = v68_.lastInputValues.cruiseControlValue
		v68_.lastInputValues.cruiseControlValue = 0
		if v106_ == 0 then
			v68_.cruiseControl.changeCurrentDelay = 0
			v68_.cruiseControl.changeMultiplier = 1
		else
			v68_.cruiseControl.changeCurrentDelay = v68_.cruiseControl.changeCurrentDelay - dt * v68_.cruiseControl.changeMultiplier
			local v107_ = v68_.cruiseControl
			local v108_ = v68_.cruiseControl.changeMultiplier + dt * 0.003
			v107_.changeMultiplier = math.min(v108_, 10)
			if v68_.cruiseControl.changeCurrentDelay < 0 then
				v68_.cruiseControl.changeCurrentDelay = v68_.cruiseControl.changeDelay
				local v109_ = math.sign(v106_)
				local v110_ = v68_.cruiseControl.speed
				local v111_ = v68_.cruiseControl.speedReverse
				local v112_ = self:getDrivingDirection() < 0
				if self:getReverserDirection() < 0 then
					v112_ = not v112_
				end
				if v112_ then
					v111_ = v111_ + v109_
				else
					v110_ = v110_ + v109_
				end
				self:setCruiseControlMaxSpeed(v110_, v111_)
				if v68_.cruiseControl.speed ~= v68_.cruiseControl.speedSent or v68_.cruiseControl.speedReverse ~= v68_.cruiseControl.speedReverseSent then
					if g_server == nil then
						g_client:getServerConnection():sendEvent(SetCruiseControlSpeedEvent.new(self, v68_.cruiseControl.speed, v68_.cruiseControl.speedReverse))
					else
						g_server:broadcastEvent(SetCruiseControlSpeedEvent.new(self, v68_.cruiseControl.speed, v68_.cruiseControl.speedReverse), nil, nil, self)
					end
					v68_.cruiseControl.speedSent = v68_.cruiseControl.speed
					v68_.cruiseControl.speedReverseSent = v68_.cruiseControl.speedReverse
				end
			end
		end
	end
	local v113_
	if self.getIsControlled == nil then
		v113_ = false
	else
		v113_ = self:getIsControlled()
	end
	if self:getIsVehicleControlledByPlayer() and self.isServer then
		if v113_ then
			local v114_
			if v68_.cruiseControl.state == Drivable.CRUISECONTROL_STATE_ACTIVE then
				if self:getReverserDirection() < 0 then
					v114_ = v68_.cruiseControl.speedReverse
				else
					v114_ = v68_.cruiseControl.speed
				end
			else
				v114_ = math.huge
			end
			if self:getDrivingDirection() < 0 then
				if self:getReverserDirection() < 0 then
					local v115_ = v68_.cruiseControl.speed
					v114_ = math.min(v114_, v115_)
				else
					local v116_ = v68_.cruiseControl.speedReverse
					v114_ = math.min(v114_, v116_)
				end
			end
			if v114_ == math.huge then
				v68_.cruiseControl.speedInterpolated = nil
			else
				v68_.cruiseControl.speedInterpolated = v68_.cruiseControl.speedInterpolated or v114_
				if v114_ ~= v68_.cruiseControl.speedInterpolated then
					local v117_ = v114_ - v68_.cruiseControl.speedInterpolated
					local v118_ = math.sign(v117_)
					local v119_ = v118_ == 1 and math.min or math.max
					local v120_ = v68_.cruiseControl
					local v121_ = v68_.cruiseControl.speedInterpolated
					local v122_ = dt * 0.0025
					local v123_ = math.abs(v117_)
					v120_.speedInterpolated = v119_(v121_ + v122_ * math.max(1, v123_) * v118_, v114_)
					v114_ = v68_.cruiseControl.speedInterpolated
				end
			end
			local v124_, _ = self:getSpeedLimit(true)
			local v125_ = math.min(v124_, v114_)
			if v68_.idleTurningAllowed and v68_.idleTurningActive then
				local v126_ = v68_.idleTurningMaxSpeed
				v125_ = math.min(v125_, v126_)
			end
			self:getMotor():setSpeedLimit(v125_)
			self:updateVehiclePhysics(v68_.axisForward, v68_.axisSide, v68_.doHandbrake, dt)
		elseif v68_.lastIsControlled then
			SpecializationUtil.raiseEvent(self, "onVehiclePhysicsUpdate", 0, 0, true, 0)
		end
	end
	if self.isClient and v113_ and (not v68_.idleTurningAllowed or (not v68_.idleTurningActive or v68_.idleTurningUpdateSteeringWheel)) then
		self:updateSteeringWheel(v68_.steeringWheel, dt, 1)
	end
	v68_.lastIsControlled = v113_
	if self:getIsActiveForInput(true) and (g_inputBinding:getInputHelpMode() ~= GS_INPUT_HELP_MODE_GAMEPAD or GS_PLATFORM_SWITCH) and g_gameSettings:getValue(GameSettings.SETTING.GYROSCOPE_STEERING) then
		local v127_, v128_, v129_ = getGravityDirection()
		self:setSteeringInput(MathUtil.getSteeringAngleFromDeviceGravity(v127_, v128_, v129_), true, InputDevice.CATEGORY.WHEEL)
	end
	v68_.odometerMilage = v68_.odometerMilage + self.lastMovedDistance * 0.001
end

-- Local values: spec, hud
function Drivable:onDraw()
	local v131_ = self.spec_drivable
	if v131_.hudExtension ~= nil and (self.getIsControlled ~= nil and self:getIsControlled()) then
		g_currentMission.hud:addHelpExtension(v131_.hudExtension)
	end
end

-- Local values: spec, ownerConnection, text
function Drivable:setCruiseControlState(state, noEventSend)
	local v135_ = self.spec_drivable
	if v135_.cruiseControl ~= nil and v135_.cruiseControl.state ~= state then
		v135_.cruiseControl.state = state
		if noEventSend == nil or not noEventSend then
			if self.isServer then
				local v136_ = self:getOwnerConnection()
				if v136_ ~= nil then
					v136_:sendEvent(SetCruiseControlStateEvent.new(self, state))
				end
			else
				g_client:getServerConnection():sendEvent(SetCruiseControlStateEvent.new(self, state))
			end
		end
		if v135_.toggleCruiseControlEvent ~= nil then
			local v137_
			if state == Drivable.CRUISECONTROL_STATE_ACTIVE then
				v137_ = g_i18n:getText("action_deactivateCruiseControl")
			else
				v137_ = g_i18n:getText("action_activateCruiseControl")
			end
			g_inputBinding:setActionEventText(v135_.toggleCruiseControlEvent, v137_)
		end
	end
end

-- Local values: spec, speedLimit, _, speedLimit, _
function Drivable:setCruiseControlMaxSpeed(speed, speedReverse)
	local v141_ = self.spec_drivable
	if speed ~= nil then
		local v142_ = v141_.cruiseControl.minSpeed
		local v143_ = v141_.cruiseControl.maxSpeed
		local v144_ = math.clamp(speed, v142_, v143_)
		if v141_.cruiseControl.speed ~= v144_ then
			v141_.cruiseControl.speed = v144_
			if v141_.cruiseControl.state == Drivable.CRUISECONTROL_STATE_FULL then
				v141_.cruiseControl.state = Drivable.CRUISECONTROL_STATE_ACTIVE
			end
		end
		if speedReverse ~= nil then
			local v145_ = v141_.cruiseControl.minSpeed
			local v146_ = v141_.cruiseControl.maxSpeedReverse
			speedReverse = math.clamp(speedReverse, v145_, v146_)
			v141_.cruiseControl.speedReverse = speedReverse
		end
		if v141_.cruiseControl.state ~= Drivable.CRUISECONTROL_STATE_OFF then
			if v141_.cruiseControl.state == Drivable.CRUISECONTROL_STATE_ACTIVE then
				local v147_, _ = self:getSpeedLimit(true)
				local v148_ = v141_.cruiseControl.speed
				local v149_ = math.min(v147_, v148_)
				self:getMotor():setSpeedLimit(v149_)
			else
				self:getMotor():setSpeedLimit(math.huge)
			end
		end
		if self:getDrivingDirection() < 0 then
			local v150_, _ = self:getSpeedLimit(true)
			local v151_ = v141_.cruiseControl.speedReverse
			local v152_ = math.min(v150_, v151_)
			self:getMotor():setSpeedLimit(v152_)
		end
		SpecializationUtil.raiseEvent(self, "onCruiseControlSpeedChanged", v144_, speedReverse)
	end
end

-- Local values: maxRotation, activeCamera, rotation, vehicleCharacter
function Drivable:updateSteeringWheel(steeringWheel, dt, direction)
	if steeringWheel ~= nil then
		local v156_ = steeringWheel.outdoorRotation
		if g_localPlayer:getCurrentVehicle() == self and self.getActiveCamera ~= nil then
			local v157_ = self:getActiveCamera()
			if v157_ ~= nil and (v157_.isInside and not v157_.isPassengerCamera) then
				v156_ = steeringWheel.indoorRotation
			end
		end
		local v158_ = self.rotatedTime * v156_
		if steeringWheel.lastRotation ~= v158_ then
			steeringWheel.lastRotation = v158_
			setRotation(steeringWheel.node, 0, v158_ * direction, 0)
			if self.getVehicleCharacter ~= nil then
				local v159_ = self:getVehicleCharacter()
				if v159_ ~= nil and v159_:getAllowCharacterUpdate() then
					v159_:setDirty(true)
				end
			end
		end
	end
end

function Drivable:getCruiseControlState()
	return self.spec_drivable.cruiseControl.state
end

-- Local values: spec
function Drivable:getCruiseControlSpeed()
	local v162_ = self.spec_drivable
	if v162_.cruiseControl.state == Drivable.CRUISECONTROL_STATE_FULL then
		return v162_.cruiseControl.maxSpeed
	else
		return v162_.cruiseControl.speed
	end
end

function Drivable:getCruiseControlMaxSpeed()
	return self.spec_drivable.cruiseControl.maxSpeed
end

-- Local values: cruiseControlSpeed, isActive, cruiseControl
function Drivable:getCruiseControlDisplayInfo()
	local v165_ = true
	local v166_ = self.spec_drivable.cruiseControl
	local v167_
	if self:getReverserDirection() < 0 then
		v167_ = v166_.speedReverse
	else
		v167_ = v166_.speed
	end
	if v166_.state == Drivable.CRUISECONTROL_STATE_FULL then
		v167_ = v166_.maxSpeed
	elseif v166_.state == Drivable.CRUISECONTROL_STATE_OFF then
		v165_ = false
	end
	if self:getDrivingDirection() < 0 then
		if self:getReverserDirection() < 0 then
			return v166_.speed, v165_
		end
		v167_ = v166_.speedReverse
	end
	return v167_, v165_
end

function Drivable:getAxisForward()
	return self.spec_drivable.axisForward
end

-- Local values: dir
function Drivable:getAccelerationAxis()
	local v170_ = self.movingDirection > -1 and 1 or -1
	local v171_ = self.spec_drivable.axisForward * v170_ * self:getReverserDirection()
	return math.max(v171_, 0)
end
g_soundManager:registerModifierType("ACCELERATE", Drivable.getAccelerationAxis)

function Drivable:getDecelerationAxis()
	if self.lastSpeedReal > 0.0001 then
		local v173_ = self.movingDirection
		local v174_ = self.spec_drivable.axisForward
		if v173_ == math.sign(v174_) or self.lastSpeedReal > 0.002 then
			local v175_ = self.spec_drivable.axisForward * self.movingDirection * self:getReverserDirection()
			local v176_ = math.min(v175_, 0)
			return math.abs(v176_)
		end
	end
	return 0
end
g_soundManager:registerModifierType("DECELERATE", Drivable.getDecelerationAxis)

function Drivable:getCruiseControlAxis()
	return self.spec_drivable.cruiseControl.state == Drivable.CRUISECONTROL_STATE_OFF and 0 or 1
end
g_soundManager:registerModifierType("CRUISECONTROL", Drivable.getCruiseControlAxis)

function Drivable:getAcDecelerationAxis()
	return self.spec_drivable.axisForward * self:getReverserDirection()
end

-- Local values: spec
function Drivable:getDashboardSteeringAxis()
	local v180_ = self.spec_drivable
	if v180_.idleTurningAllowed and v180_.idleTurningActive then
		return not v180_.idleTurningUpdateSteeringWheel and 0 or self.rotatedTime / self.maxRotTime * self:getReverserDirection() * v180_.idleTurningDirection * v180_.axisForward
	else
		return self.rotatedTime / self.maxRotTime * self:getReverserDirection()
	end
end

-- Local values: value, spec
function Drivable:getDashboardCombinedPedalLeft()
	local v182_ = self:getAcDecelerationAxis()
	local v183_ = self.spec_drivable
	if v183_.idleTurningAllowed and v183_.idleTurningActive then
		return v182_ * v183_.idleTurningDirection
	end
	local v184_ = v182_ - self:getDashboardSteeringAxis()
	return math.clamp(v184_, -1, 1)
end

-- Local values: value, spec
function Drivable:getDashboardCombinedPedalRight()
	local v186_ = self:getAcDecelerationAxis()
	local v187_ = self.spec_drivable
	if v187_.idleTurningAllowed and v187_.idleTurningActive then
		return -v186_ * v187_.idleTurningDirection
	end
	local v188_ = v186_ + self:getDashboardSteeringAxis()
	return math.clamp(v188_, -1, 1)
end

function Drivable:setReverserDirection(reverserDirection)
	self.spec_drivable.reverserDirection = reverserDirection
end

function Drivable:getReverserDirection()
	return self.spec_drivable.reverserDirection
end

function Drivable:getSteeringDirection()
	return self.spec_drivable.steeringDirection
end

function Drivable:getIsDrivingForward()
	return self:getDrivingDirection() >= 0
end

function Drivable:getIsDrivingBackward()
	return self:getDrivingDirection() < 0
end

-- Local values: lastSpeed
function Drivable:getDrivingDirection()
	local v196_ = self:getLastSpeed()
	return v196_ < 0.2 and 0 or (v196_ < 1.5 and self.spec_drivable.axisForward == 0 and 0 or self.movingDirection * self:getReverserDirection())
end
g_soundManager:registerModifierType("DRIVING_DIRECTION", Drivable.getDrivingDirection)

function Drivable:getIsVehicleControlledByPlayer()
	return true
end

-- Local values: spec, objectId, func, vehicle, isAllowed, warning
function Drivable:getIsPlayerVehicleControlAllowed()
	local v198_ = self.spec_drivable
	if v198_.hasPlayerControlAllowedFunctions then
		for v199_, v200_ in pairs(v198_.playerControlAllowedFunctions) do
			local v201_ = NetworkUtil.getObject(v199_)
			if v201_ == nil or v201_.rootVehicle ~= self then
				v198_.playerControlAllowedFunctions[v199_] = nil
				v198_.hasPlayerControlAllowedFunctions = table.size(v198_.playerControlAllowedFunctions) > 0
			else
				local v202_, v203_ = v200_(v201_)
				if not v202_ then
					return v202_, v203_
				end
			end
		end
	end
	return true, nil
end

-- Local values: objectId, spec
function Drivable:registerPlayerVehicleControlAllowedFunction(vehicle, func)
	local v207_ = NetworkUtil.getObjectId(vehicle)
	if v207_ ~= nil and func ~= nil then
		local v208_ = self.spec_drivable
		v208_.playerControlAllowedFunctions[v207_] = func
		v208_.hasPlayerControlAllowedFunctions = table.size(v208_.playerControlAllowedFunctions) > 0
	end
end

function Drivable:stopMotor(noEventSend)
	self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF, true)
end

-- Local values: spec, entered, _, actionEventId
function Drivable:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v211_ = self.spec_drivable
		v211_.toggleCruiseControlEvent = nil
		self:clearActionEventsTable(v211_.actionEvents)
		local v212_ = self.getIsEntered == nil and true or self:getIsEntered()
		if self:getIsActiveForInput(true, true) and v212_ then
			if not self:getIsAIActive() then
				local _, v213_ = self:addActionEvent(v211_.actionEvents, InputAction.AXIS_ACCELERATE_VEHICLE, self, Drivable.actionEventAccelerate, false, false, true, true, nil)
				g_inputBinding:setActionEventTextPriority(v213_, GS_PRIO_VERY_LOW)
				g_inputBinding:setActionEventTextVisibility(v213_, false)
				local _, v214_ = self:addActionEvent(v211_.actionEvents, InputAction.AXIS_BRAKE_VEHICLE, self, Drivable.actionEventBrake, false, false, true, true, nil)
				g_inputBinding:setActionEventTextPriority(v214_, GS_PRIO_VERY_LOW)
				g_inputBinding:setActionEventTextVisibility(v214_, false)
				local _, v215_ = self:addPoweredActionEvent(v211_.actionEvents, InputAction.AXIS_MOVE_SIDE_VEHICLE, self, Drivable.actionEventSteer, false, false, true, true, nil)
				g_inputBinding:setActionEventTextPriority(v215_, GS_PRIO_VERY_LOW)
				g_inputBinding:setActionEventTextVisibility(v215_, false)
				g_inputBinding:setActionEventText(v215_, g_i18n:getText("action_steer"))
				local _, v216_ = self:addActionEvent(v211_.actionEvents, InputAction.TOGGLE_CRUISE_CONTROL, self, Drivable.actionEventCruiseControlState, false, true, true, true, nil)
				g_inputBinding:setActionEventTextPriority(v216_, GS_PRIO_LOW)
				v211_.toggleCruiseControlEvent = v216_
			end
			local _, v217_ = self:addActionEvent(v211_.actionEvents, InputAction.AXIS_CRUISE_CONTROL, self, Drivable.actionEventCruiseControlValue, false, true, true, true, nil)
			g_inputBinding:setActionEventText(v217_, g_i18n:getText("action_changeCruiseControlLevel"))
			g_inputBinding:setActionEventTextPriority(v217_, GS_PRIO_LOW)
		end
	end
end

-- Local values: spec, forceFeedback
function Drivable:onLeaveVehicle(wasEntered)
	self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF, true)
	if self.brake ~= nil then
		self:brake(1)
	end
	if wasEntered then
		local v220_ = self.spec_drivable.forceFeedback
		if v220_.isActive then
			v220_.device:setForceFeedback(v220_.axisIndex, 0, 0)
			v220_.isActive = false
			v220_.device = nil
		end
	end
end

-- Local values: spec
function Drivable:onSetBroken()
	if self.isClient then
		local v222_ = self.spec_drivable
		g_soundManager:playSample(v222_.samples.waterSplash)
	end
end

-- Local values: spec, acceleration, targetRotatedTime, updateDt
function Drivable:updateVehiclePhysics(axisForward, axisSide, doHandbrake, dt)
	local v228_ = self.spec_drivable
	local v229_ = self:getSteeringDirection() * axisSide
	local v230_ = 0
	if self:getIsMotorStarted() then
		if math.abs(axisForward) > 0 then
			self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)
		end
		axisForward = v228_.cruiseControl.state ~= Drivable.CRUISECONTROL_STATE_OFF and 1 or axisForward
	elseif self:getIsManualDirectionChangeActive() then
		if axisForward >= 0 then
			axisForward = v230_
		end
	elseif self.movingDirection == 0 then
		axisForward = v230_
	elseif math.sign(axisForward) == self.movingDirection then
		axisForward = v230_
	end
	if not self:getCanMotorRun() then
		axisForward = math.min(axisForward, 0)
		if self:getIsMotorStarted() then
			self:stopMotor()
		end
	end
	if self.getIsControlled ~= nil and self:getIsControlled() then
		local v231_
		if self.maxRotTime == nil or self.minRotTime == nil then
			v231_ = 0
		elseif v229_ < 0 then
			local v232_ = -self.maxRotTime * v229_
			local v233_ = self.maxRotTime
			v231_ = math.min(v232_, v233_)
		else
			local v234_ = self.minRotTime * v229_
			local v235_ = self.minRotTime
			v231_ = math.max(v234_, v235_)
		end
		self.rotatedTime = v231_
	end
	if self.finishedFirstUpdate and (self.spec_wheels ~= nil and #self.spec_wheels.wheels > 0) then
		if v228_.initialWheelPhysicsUpdate then
			v228_.initialWheelPhysicsUpdate = false
			dt = 99999
		end
		WheelsUtil.updateWheelsPhysics(self, dt, self.lastSpeedReal * self.movingDirection, axisForward, doHandbrake, g_currentMission.missionInfo.stopAndGoBraking)
	end
	return axisForward
end

-- Local values: spec
function Drivable:setAccelerationPedalInput(inputValue)
	local v238_ = self.spec_drivable
	v238_.lastInputValues.axisAccelerate = math.clamp(inputValue, 0, 1)
	if v238_.lastInputValues.targetSpeed ~= nil then
		v238_.lastInputValues.targetSpeed = nil
		v238_.lastInputValues.targetDirection = nil
	end
end

-- Local values: spec
function Drivable:setBrakePedalInput(inputValue)
	local v241_ = self.spec_drivable
	v241_.lastInputValues.axisBrake = math.clamp(inputValue, 0, 1)
	if v241_.lastInputValues.targetSpeed ~= nil then
		v241_.lastInputValues.targetSpeed = nil
		v241_.lastInputValues.targetDirection = nil
	end
end

-- Local values: spec
function Drivable:setTargetSpeedAndDirection(speed, direction)
	local v245_ = self.spec_drivable
	if direction > 0 then
		speed = speed * self:getMotor():getMaximumForwardSpeed() * 3.6
	elseif direction < 0 then
		speed = speed * self:getMotor():getMaximumBackwardSpeed() * 3.6
	end
	v245_.lastInputValues.targetSpeed = speed
	v245_.lastInputValues.targetDirection = direction
end

-- Local values: spec
function Drivable:setSteeringInput(inputValue, isAnalog, deviceCategory)
	local v250_ = self.spec_drivable
	v250_.lastInputValues.axisSteer = inputValue
	if inputValue ~= 0 then
		v250_.lastInputValues.axisSteerIsAnalog = isAnalog
		v250_.lastInputValues.axisSteerDeviceCategory = deviceCategory
	end
end

-- Local values: spec
function Drivable:brakeToStop()
	self.spec_drivable.brakeToStop = true
end

-- Local values: spec, i, wheelData, idleTurnAngle
function Drivable:updateSteeringAngle(wheel, dt, steeringAngle)
	local v255_ = self.spec_drivable
	if v255_.idleTurningAllowed then
		for v256_ = 1, #v255_.idleTurningWheels do
			local v257_ = v255_.idleTurningWheels[v256_]
			if wheel.repr == v257_.wheelNode or wheel.driveNode == v257_.wheelNode then
				local v258_ = v257_.steeringAngle
				if v257_.inverted then
					v258_ = v257_.steeringAngle + 3.141592653589793
				end
				if v255_.idleTurningActive then
					steeringAngle = v258_ or steeringAngle
				end
				return steeringAngle
			end
		end
	end
	return steeringAngle
end

-- Local values: spec
function Drivable:getIsManualDirectionChangeAllowed(superFunc)
	local v261_ = self.spec_drivable
	if v261_.idleTurningAllowed and v261_.idleTurningActive then
		return false
	else
		return superFunc(self)
	end
end

function Drivable:getMapHotspotRotation(superFunc, isPlayerHotspot)
	if self:getReverserDirection() < 0 then
		return superFunc(self, isPlayerHotspot) + 3.141592653589793
	else
		return superFunc(self, isPlayerHotspot)
	end
end

-- Local values: spec
function Drivable:setTransmissionDirection(superFunc, direction)
	superFunc(self, direction)
	local v268_ = self.spec_drivable
	if direction ~= v268_.cruiseControl.transmissionDirection then
		local v269_ = v268_.cruiseControl
		local v270_ = v268_.cruiseControl
		local v271_ = v268_.cruiseControl.maxSpeedReverse
		local v272_ = v268_.cruiseControl.maxSpeed
		v269_.maxSpeed = v271_
		v270_.maxSpeedReverse = v272_
		self:setCruiseControlMaxSpeed(v268_.cruiseControl.speedReverse, v268_.cruiseControl.speed)
		v268_.cruiseControl.transmissionDirection = direction
	end
end

-- Local values: isPowered, isPoweredWarning, isAllowed, warning
function Drivable:actionEventAccelerate(actionName, inputValue, callbackState, isAnalog)
	if inputValue ~= 0 then
		local v275_, v276_ = self:getIsPowered()
		if not v275_ and v276_ ~= nil then
			g_currentMission:showBlinkingWarning(v276_, 2000)
		end
		local v277_, v278_ = self:getIsPlayerVehicleControlAllowed()
		if v277_ then
			self:setAccelerationPedalInput(inputValue)
			return
		end
		if v278_ ~= nil then
			g_currentMission:showBlinkingWarning(v278_, 2000)
		end
	end
end

-- Local values: isPowered, isPoweredWarning, isAllowed, warning
function Drivable:actionEventBrake(actionName, inputValue, callbackState, isAnalog)
	if inputValue ~= 0 then
		local v281_, v282_ = self:getIsPowered()
		if not v281_ and v282_ ~= nil then
			g_currentMission:showBlinkingWarning(v282_, 2000)
		end
		local v283_, v284_ = self:getIsPlayerVehicleControlAllowed()
		if v283_ then
			self:setBrakePedalInput(inputValue)
			return
		end
		if v284_ ~= nil then
			g_currentMission:showBlinkingWarning(v284_, 2000)
		end
	end
end

-- Local values: spec, isSupported, device, axisIndex, isSupported, _, _, isAllowed, warning
function Drivable:actionEventSteer(actionName, inputValue, callbackState, isAnalog, isMouse, deviceCategory, binding)
	local v290_ = self.spec_drivable
	if v290_.forceFeedback.isActive then
		if binding ~= v290_.forceFeedback.binding then
			local v291_, _, _ = g_inputBinding:getBindingForceFeedbackInfo(binding)
			if not v291_ then
				v290_.forceFeedback.isActive = false
				v290_.forceFeedback.device = nil
				v290_.forceFeedback.binding = nil
				v290_.forceFeedback.axisIndex = 0
			end
		end
	else
		local v292_, v293_, v294_ = g_inputBinding:getBindingForceFeedbackInfo(binding)
		v290_.forceFeedback.isActive = v292_
		v290_.forceFeedback.device = v293_
		v290_.forceFeedback.binding = binding
		v290_.forceFeedback.axisIndex = v294_
		if v292_ then
			v293_:setForceFeedback(v294_, 0, inputValue)
		end
	end
	if inputValue ~= 0 then
		local v295_, v296_ = self:getIsPlayerVehicleControlAllowed()
		if v295_ then
			self:setSteeringInput(inputValue, isAnalog, deviceCategory)
			return
		end
		if v296_ ~= nil then
			g_currentMission:showBlinkingWarning(v296_, 2000)
		end
	end
end

-- Local values: spec, isAllowed, warning
function Drivable:actionEventCruiseControlState(actionName, inputValue, callbackState, isAnalog)
	local v298_ = self.spec_drivable
	local v299_, v300_ = self:getIsPlayerVehicleControlAllowed()
	if v299_ then
		v298_.lastInputValues.cruiseControlState = 1
	elseif v300_ ~= nil then
		g_currentMission:showBlinkingWarning(v300_, 2000)
	end
end

-- Local values: spec
function Drivable:actionEventCruiseControlValue(actionName, inputValue, callbackState, isAnalog)
	self.spec_drivable.lastInputValues.cruiseControlValue = inputValue
end
