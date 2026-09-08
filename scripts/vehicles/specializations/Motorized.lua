source("dataS/scripts/vehicles/specializations/events/MotorClutchCreakingEvent.lua")
source("dataS/scripts/vehicles/specializations/events/MotorSetTurnedOnEvent.lua")
source("dataS/scripts/vehicles/specializations/events/MotorGearShiftEvent.lua")
source("dataS/scripts/vehicles/specializations/events/MotorStateEvent.lua")
source("dataS/scripts/vehicles/specializations/enums/MotorState.lua")
Motorized = {}
Motorized.DAMAGED_USAGE_INCREASE = 0.3
function Motorized.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("motor", g_i18n:getText("configuration_motorSetup"), "motorized", VehicleConfigurationItemMotor, nil, nil, nil, 1)
	g_storeManager:addSpecType("fuel", "shopListAttributeIconFuel", Motorized.loadSpecValueFuel, Motorized.getSpecValueFuelDiesel, StoreSpecies.VEHICLE)
	g_storeManager:addSpecType("electricCharge", "shopListAttributeIconElectricCharge", Motorized.loadSpecValueFuel, Motorized.getSpecValueFuelElectricCharge, StoreSpecies.VEHICLE)
	g_storeManager:addSpecType("methane", "shopListAttributeIconMethane", Motorized.loadSpecValueFuel, Motorized.getSpecValueFuelMethane, StoreSpecies.VEHICLE)
	g_storeManager:addSpecType("maxSpeed", "shopListAttributeIconMaxSpeed", Motorized.loadSpecValueMaxSpeed, Motorized.getSpecValueMaxSpeed, StoreSpecies.VEHICLE)
	g_storeManager:addSpecType("power", "shopListAttributeIconPower", Motorized.loadSpecValuePower, Motorized.getSpecValuePower, StoreSpecies.VEHICLE)
	g_storeManager:addSpecType("powerConfig", "shopListAttributeIconPower", Motorized.loadSpecValuePowerConfig, Motorized.getSpecValuePowerConfig, StoreSpecies.VEHICLE)
	g_storeManager:addSpecType("transmission", "shopListAttributeIconTransmission", Motorized.loadSpecValueTransmission, Motorized.getSpecValueTransmission, StoreSpecies.VEHICLE)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("Motorized")
	Motorized.registerDifferentialXMLPaths(v1_, "vehicle.motorized.differentialConfigurations.differentialConfiguration(?)")
	Motorized.registerDifferentialXMLPaths(v1_, "vehicle.motorized.differentials")
	Motorized.registerMotorXMLPaths(v1_, "vehicle.motorized.motorConfigurations.motorConfiguration(?)")
	Motorized.registerConsumerXMLPaths(v1_, "vehicle.motorized.consumerConfigurations.consumerConfiguration(?)")
	Motorized.registerConsumerXMLPaths(v1_, "vehicle.motorized.consumers")
	Motorized.registerSoundXMLPaths(v1_, "vehicle.motorized.sounds")
	Motorized.registerSoundXMLPaths(v1_, "vehicle.motorized.motorConfigurations.motorConfiguration(?).sounds")
	v1_:register(XMLValueType.FLOAT, "vehicle.motorized.reverseDriveSound#threshold", "Reverse drive sound turn on speed threshold", 4)
	v1_:register(XMLValueType.FLOAT, "vehicle.motorized.brakeCompressor#capacity", "Brake compressor capacity", 6)
	v1_:register(XMLValueType.FLOAT, "vehicle.motorized.brakeCompressor#refillFillLevel", "Brake compressor refill threshold", "half of capacity")
	v1_:register(XMLValueType.FLOAT, "vehicle.motorized.brakeCompressor#fillSpeed", "Brake compressor fill speed", 0.6)
	ParticleUtil.registerParticleXMLPaths(v1_, "vehicle.motorized.exhaustParticleSystems", "exhaustParticleSystem(?)")
	v1_:register(XMLValueType.FLOAT, "vehicle.motorized.exhaustParticleSystems#minScale", "Min. scale", 0.5)
	v1_:register(XMLValueType.FLOAT, "vehicle.motorized.exhaustParticleSystems#maxScale", "Max. scale", 1)
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.motorized.exhaustFlap(?)#node", "Exhaust Flap Node")
	v1_:register(XMLValueType.ANGLE, "vehicle.motorized.exhaustFlap(?)#maxRot", "Max. rotation", 0)
	v1_:register(XMLValueType.INT, "vehicle.motorized.exhaustFlap(?)#rotationAxis", "Rotation Axis", 1)
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.motorized.exhaustEffects.exhaustEffect(?)#node", "Effect link node")
	v1_:register(XMLValueType.STRING, "vehicle.motorized.exhaustEffects.exhaustEffect(?)#filename", "Effect i3d filename")
	v1_:register(XMLValueType.VECTOR_4, "vehicle.motorized.exhaustEffects.exhaustEffect(?)#minRpmColor", "Min. rpm color", "0 0 0 1")
	v1_:register(XMLValueType.VECTOR_4, "vehicle.motorized.exhaustEffects.exhaustEffect(?)#maxRpmColor", "Max. rpm color", "0.0384 0.0359 0.0627 2.0")
	v1_:register(XMLValueType.FLOAT, "vehicle.motorized.exhaustEffects.exhaustEffect(?)#minRpmScale", "Min. rpm scale", 0.25)
	v1_:register(XMLValueType.FLOAT, "vehicle.motorized.exhaustEffects.exhaustEffect(?)#maxRpmScale", "Max. rpm scale", 0.95)
	v1_:register(XMLValueType.FLOAT, "vehicle.motorized.exhaustEffects.exhaustEffect(?)#upFactor", "Defines how far the effect goes up in the air in meter", 0.75)
	EffectManager.registerEffectXMLPaths(v1_, "vehicle.motorized.effects")
	v1_:register(XMLValueType.FLOAT, "vehicle.motorized.motorStartDuration", "Motor start duration", "Duration motor takes to start. After this time player can start to drive")
	v1_:register(XMLValueType.FLOAT, "vehicle.motorized.brakeForce#force", "Brake force when vehicle is empty", 0)
	v1_:register(XMLValueType.FLOAT, "vehicle.motorized.brakeForce#maxForce", "Brake force when vehicle reached mass of #maxForceMass", 0)
	v1_:register(XMLValueType.FLOAT, "vehicle.motorized.brakeForce#maxForceMass", "When this mass is reached the vehicle will brake with #maxForce", 0)
	v1_:register(XMLValueType.BOOL, "vehicle.motorized.brakeForce#includeAttachables", "Defines if the mass of the attached vehicles is included in the calculations", false)
	v1_:register(XMLValueType.L10N_STRING, "vehicle.motorized#clutchNoEngagedWarning", "Warning to be displayed if try to start the engine but clutch not engaged", "warning_motorClutchNoEngaged")
	v1_:register(XMLValueType.L10N_STRING, "vehicle.motorized#clutchCrackingGearWarning", "Warning to be display if user tries to select a gear without pressing clutch pedal", "action_clutchCrackingGear")
	v1_:register(XMLValueType.L10N_STRING, "vehicle.motorized#clutchCrackingGroupWarning", "Warning to be display if user tries to select a gear without pressing clutch pedal", "action_clutchCrackingGroup")
	v1_:register(XMLValueType.L10N_STRING, "vehicle.motorized#turnOnText", "Motor start text", "action_startMotor")
	v1_:register(XMLValueType.L10N_STRING, "vehicle.motorized#turnOffText", "Motor stop text", "action_stopMotor")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.motorized.gearLevers.gearLever(?)#node", "Gear lever node")
	v1_:register(XMLValueType.INT, "vehicle.motorized.gearLevers.gearLever(?)#centerAxis", "Axis of center bay")
	v1_:register(XMLValueType.TIME, "vehicle.motorized.gearLevers.gearLever(?)#changeTime", "Time to move lever from one state to another", 0.5)
	v1_:register(XMLValueType.TIME, "vehicle.motorized.gearLevers.gearLever(?)#handsOnDelay", "The animation is delayed by this time to have time to put the hand on the lever", 0)
	v1_:register(XMLValueType.INT, "vehicle.motorized.gearLevers.gearLever(?).state(?)#gear", "Gear index")
	v1_:register(XMLValueType.INT, "vehicle.motorized.gearLevers.gearLever(?).state(?)#group", "Group index")
	v1_:register(XMLValueType.ANGLE, "vehicle.motorized.gearLevers.gearLever(?).state(?)#xRot", "X rotation")
	v1_:register(XMLValueType.ANGLE, "vehicle.motorized.gearLevers.gearLever(?).state(?)#yRot", "Y rotation")
	v1_:register(XMLValueType.ANGLE, "vehicle.motorized.gearLevers.gearLever(?).state(?)#zRot", "Z rotation")
	v1_:register(XMLValueType.FLOAT, "vehicle.storeData.specs.power", "Power")
	v1_:register(XMLValueType.FLOAT, "vehicle.storeData.specs.maxSpeed", "Max speed")
	v1_:register(XMLValueType.STRING, "vehicle.motorized#statsType", "Statistic type", "tractor")
	v1_:register(XMLValueType.BOOL, "vehicle.motorized#forceSpeedHudDisplay", "Force usage of vehicle speed display in hud independent of setting", false)
	v1_:register(XMLValueType.BOOL, "vehicle.motorized#forceRpmHudDisplay", "Force usage of motor speed display in hud independent of setting", false)
	Dashboard.registerDashboardXMLPaths(v1_, "vehicle.motorized.dashboards", {
		"rpm",
		"load",
		"speed",
		"speedDir",
		"fuelUsage",
		"motorTemperature",
		"motorTemperatureWarning",
		"clutchPedal",
		"gear",
		"gearGroup",
		"gearIndex",
		"gearGroupIndex",
		"gearShiftUp",
		"gearShiftDown",
		"gearShiftUpDown",
		"movingDirection",
		"directionForward",
		"directionForwardExclusive",
		"directionBackward",
		"directionNeutral",
		"movingDirectionLetter",
		"ignitionState",
		"battery"
	})
	AnimationManager.registerAnimationNodesXMLPaths(v1_, "vehicle.motorized.animationNodes")
	v1_:register(XMLValueType.BOOL, Dashboard.GROUP_XML_KEY .. "#isMotorStarting", "Is motor starting")
	v1_:register(XMLValueType.BOOL, Dashboard.GROUP_XML_KEY .. "#isMotorRunning", "Is motor running")
	v1_:register(XMLValueType.BOOL, Dashboard.GROUP_XML_KEY .. "#electronicsStarting", "Electrical components starting (depending on defined \'electronicsStartingTime\')", false)
	v1_:register(XMLValueType.TIME, Dashboard.GROUP_XML_KEY .. "#electronicsStartingTime", "Starting time of electric components", 2)
	v1_:register(XMLValueType.BOOL, Dashboard.GROUP_XML_KEY .. "#electronicsRunning", "Electrical components are started and running (depending on defined \'electronicsStartingTime\')", false)
	v1_:setXMLSpecializationType()
end

function Motorized.registerMotorXMLPaths(schema, baseKey)
	schema:register(XMLValueType.STRING, baseKey .. ".motor#type", "Motor type", "vehicle")
	schema:register(XMLValueType.STRING, baseKey .. ".motor#startAnimationName", "Motor start animation", "vehicle")
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor#minRpm", "Min. RPM", 1000)
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor#maxRpm", "Max. RPM", 1800)
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor#minSpeed", "Min. driving speed", 1)
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor#maxForwardSpeed", "Max. forward speed")
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor#maxBackwardSpeed", "Max. backward speed")
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor#accelerationLimit", "Acceleration limit", 2)
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor#brakeForce", "Brake force", 10)
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor#lowBrakeForceScale", "Low brake force scale", 0.5)
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor#lowBrakeForceSpeedLimit", "Low brake force speed limit (below this speed the lowBrakeForceScale is activated)", 1)
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor#torqueScale", "Scale factor for torque curve", 1)
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor#ptoMotorRpmRatio", "PTO to motor rpm ratio", 4)
	schema:register(XMLValueType.FLOAT, baseKey .. ".transmission#minForwardGearRatio", "Min. forward gear ratio")
	schema:register(XMLValueType.FLOAT, baseKey .. ".transmission#maxForwardGearRatio", "Max. forward gear ratio")
	schema:register(XMLValueType.FLOAT, baseKey .. ".transmission#minBackwardGearRatio", "Min. backward gear ratio")
	schema:register(XMLValueType.FLOAT, baseKey .. ".transmission#maxBackwardGearRatio", "Max. backward gear ratio")
	schema:register(XMLValueType.TIME, baseKey .. ".transmission#gearChangeTime", "Gear change time")
	schema:register(XMLValueType.TIME, baseKey .. ".transmission#autoGearChangeTime", "Auto gear change time")
	schema:register(XMLValueType.FLOAT, baseKey .. ".transmission#axleRatio", "Axle ratio", 1)
	schema:register(XMLValueType.FLOAT, baseKey .. ".transmission#startGearThreshold", "Adjusts which gear is used as start gear", VehicleMotor.GEAR_START_THRESHOLD)
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor.torque(?)#normRpm", "Norm RPM (0-1)")
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor.torque(?)#rpm", "RPM")
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor.torque(?)#torque", "Torque")
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor#rotInertia", "Rotation inertia", "Peak. motor torque / 600")
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor#dampingRateScale", "Scales motor damping rate", 1)
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor#rpmSpeedLimit", "Motor rotation acceleration limit")
	schema:register(XMLValueType.FLOAT, baseKey .. ".transmission.forwardGear(?)#gearRatio", "Gear ratio")
	schema:register(XMLValueType.FLOAT, baseKey .. ".transmission.forwardGear(?)#maxSpeed", "Gear ratio")
	schema:register(XMLValueType.BOOL, baseKey .. ".transmission.forwardGear(?)#defaultGear", "Gear ratio")
	schema:register(XMLValueType.STRING, baseKey .. ".transmission.forwardGear(?)#name", "Gear name to display")
	schema:register(XMLValueType.STRING, baseKey .. ".transmission.forwardGear(?)#reverseName", "Gear name to display (if reverse direction is active)")
	schema:register(XMLValueType.STRING, baseKey .. ".transmission.forwardGear(?)#dashboardName", "Gear name to display in dashboard")
	schema:register(XMLValueType.STRING, baseKey .. ".transmission.forwardGear(?)#dashboardReverseName", "Gear name to display in dashboard (if reverse direction is active)")
	schema:register(XMLValueType.STRING, baseKey .. ".transmission.forwardGear(?)#actionName", "Input Action to select this gear", "SHIFT_GEAR_SELECT_X")
	schema:register(XMLValueType.FLOAT, baseKey .. ".transmission.backwardGear(?)#gearRatio", "Gear ratio")
	schema:register(XMLValueType.FLOAT, baseKey .. ".transmission.backwardGear(?)#maxSpeed", "Gear ratio")
	schema:register(XMLValueType.BOOL, baseKey .. ".transmission.backwardGear(?)#defaultGear", "Gear ratio")
	schema:register(XMLValueType.STRING, baseKey .. ".transmission.backwardGear(?)#name", "Gear name to display")
	schema:register(XMLValueType.STRING, baseKey .. ".transmission.backwardGear(?)#reverseName", "Gear name to display (if reverse direction is active)")
	schema:register(XMLValueType.STRING, baseKey .. ".transmission.backwardGear(?)#dashboardName", "Gear name to display in dashboard")
	schema:register(XMLValueType.STRING, baseKey .. ".transmission.backwardGear(?)#dashboardReverseName", "Gear name to display in dashboard (if reverse direction is active)")
	schema:register(XMLValueType.STRING, baseKey .. ".transmission.backwardGear(?)#actionName", "Input Action to select this gear", "SHIFT_GEAR_SELECT_X")
	schema:register(XMLValueType.STRING, baseKey .. ".transmission.groups#type", "Type of groups (powershift/default)", "default")
	schema:register(XMLValueType.TIME, baseKey .. ".transmission.groups#changeTime", "Change time if default type", 0.5)
	schema:register(XMLValueType.FLOAT, baseKey .. ".transmission.groups.group(?)#ratio", "Ratio while stage active")
	schema:register(XMLValueType.BOOL, baseKey .. ".transmission.groups.group(?)#isDefault", "Is default stage", false)
	schema:register(XMLValueType.STRING, baseKey .. ".transmission.groups.group(?)#name", "Gear name to display")
	schema:register(XMLValueType.STRING, baseKey .. ".transmission.groups.group(?)#dashboardName", "Gear name to display in dashboard")
	schema:register(XMLValueType.STRING, baseKey .. ".transmission.groups.group(?)#actionName", "Input Action to select this group", "SHIFT_GROUP_SELECT_X")
	schema:register(XMLValueType.BOOL, baseKey .. ".transmission.directionChange#useGroup", "Use group as reverse change", false)
	schema:register(XMLValueType.INT, baseKey .. ".transmission.directionChange#reverseGroupIndex", "Group will be activated while direction is changed", 1)
	schema:register(XMLValueType.BOOL, baseKey .. ".transmission.directionChange#useGear", "Use gear as reverse change", false)
	schema:register(XMLValueType.INT, baseKey .. ".transmission.directionChange#reverseGearIndex", "Gear will be activated while direction is changed", 1)
	schema:register(XMLValueType.TIME, baseKey .. ".transmission.directionChange#changeTime", "Direction change time", 0.5)
	schema:register(XMLValueType.BOOL, baseKey .. ".transmission.manualShift#gears", "Defines if gears can be shifted manually", true)
	schema:register(XMLValueType.BOOL, baseKey .. ".transmission.manualShift#groups", "Defines if groups can be shifted manually", true)
	schema:register(XMLValueType.L10N_STRING, baseKey .. ".transmission#name", "Name of transmission to display in the shop")
	schema:register(XMLValueType.STRING, baseKey .. ".transmission#param", "Parameter to insert in transmission name")
	schema:register(XMLValueType.FLOAT, baseKey .. ".motorStartDuration", "Motor start duration", "Duration motor takes to start. After this time player can start to drive")
end

function Motorized.registerDifferentialXMLPaths(schema, baseKey)
	schema:register(XMLValueType.FLOAT, baseKey .. ".differentials.differential(?)#torqueRatio", "Torque ratio", 0.5)
	schema:register(XMLValueType.FLOAT, baseKey .. ".differentials.differential(?)#maxSpeedRatio", "Max. speed ratio", 1.3)
	schema:register(XMLValueType.INT, baseKey .. ".differentials.differential(?)#wheelIndex1", "Wheel index 1")
	schema:register(XMLValueType.INT, baseKey .. ".differentials.differential(?)#wheelIndex2", "Wheel index 2")
	schema:register(XMLValueType.INT, baseKey .. ".differentials.differential(?)#differentialIndex1", "Differential index 1")
	schema:register(XMLValueType.INT, baseKey .. ".differentials.differential(?)#differentialIndex2", "Differential index 2")
end

function Motorized.registerConsumerXMLPaths(schema, baseKey)
	schema:register(XMLValueType.L10N_STRING, baseKey .. "#consumersEmptyWarning", "Consumers empty warning", "warning_motorFuelEmpty")
	schema:register(XMLValueType.INT, baseKey .. ".consumer(?)#fillUnitIndex", "Fill unit index", 1)
	schema:register(XMLValueType.STRING, baseKey .. ".consumer(?)#fillType", "Fill type name")
	schema:register(XMLValueType.FLOAT, baseKey .. ".consumer(?)#usage", "Usage in l/h", 1)
	schema:register(XMLValueType.BOOL, baseKey .. ".consumer(?)#permanentConsumption", "Do permanent consumption", 1)
	schema:register(XMLValueType.FLOAT, baseKey .. ".consumer(?)#refillLitersPerSecond", "Refill liters per second", 0)
	schema:register(XMLValueType.FLOAT, baseKey .. ".consumer(?)#refillCapacityPercentage", "Refill capacity percentage", 0)
	schema:register(XMLValueType.FLOAT, baseKey .. ".consumer(?)#capacity", "If defined the capacity of the fillUnit fill be overwritten with this value")
end

function Motorized.registerSoundXMLPaths(schema, baseKey)
	SoundManager.registerSampleXMLPaths(schema, baseKey, "motorStart")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "motorStop")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "gearbox(?)")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "clutchCracking")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "gearEngaged")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "gearDisengaged")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "gearLeverStart")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "gearLeverEnd")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "gearGroupLeverStart")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "gearGroupLeverEnd")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "gearRangeChange")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "gearGroupChange")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "blowOffValve")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "retarder")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "motor(?)")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "airCompressorStart")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "airCompressorStop")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "airCompressorRun")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "compressedAir")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "airRelease")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "reverseDrive")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "brake")
end

function Motorized.prerequisitesPresent(specializations)
	local v11_ = SpecializationUtil.hasSpecialization(FillUnit, specializations)
	if v11_ then
		v11_ = SpecializationUtil.hasSpecialization(VehicleSettings, specializations)
	end
	return v11_
end

function Motorized.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onStartMotor")
	SpecializationUtil.registerEvent(vehicleType, "onStopMotor")
	SpecializationUtil.registerEvent(vehicleType, "onGearDirectionChanged")
	SpecializationUtil.registerEvent(vehicleType, "onGearChanged")
	SpecializationUtil.registerEvent(vehicleType, "onGearGroupChanged")
	SpecializationUtil.registerEvent(vehicleType, "onMotorBlowOffValveChanged")
	SpecializationUtil.registerEvent(vehicleType, "onClutchCreaking")
end

function Motorized.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadDifferentials", Motorized.loadDifferentials)
	SpecializationUtil.registerFunction(vehicleType, "loadMotor", Motorized.loadMotor)
	SpecializationUtil.registerFunction(vehicleType, "loadGears", Motorized.loadGears)
	SpecializationUtil.registerFunction(vehicleType, "loadGearGroups", Motorized.loadGearGroups)
	SpecializationUtil.registerFunction(vehicleType, "loadExhaustEffects", Motorized.loadExhaustEffects)
	SpecializationUtil.registerFunction(vehicleType, "onExhaustEffectI3DLoaded", Motorized.onExhaustEffectI3DLoaded)
	SpecializationUtil.registerFunction(vehicleType, "loadSounds", Motorized.loadSounds)
	SpecializationUtil.registerFunction(vehicleType, "loadConsumerConfiguration", Motorized.loadConsumerConfiguration)
	SpecializationUtil.registerFunction(vehicleType, "setMotorState", Motorized.setMotorState)
	SpecializationUtil.registerFunction(vehicleType, "getMotorState", Motorized.getMotorState)
	SpecializationUtil.registerFunction(vehicleType, "getIsMotorStarted", Motorized.getIsMotorStarted)
	SpecializationUtil.registerFunction(vehicleType, "getIsMotorInNeutral", Motorized.getIsMotorInNeutral)
	SpecializationUtil.registerFunction(vehicleType, "getCanMotorRun", Motorized.getCanMotorRun)
	SpecializationUtil.registerFunction(vehicleType, "getStopMotorOnLeave", Motorized.getStopMotorOnLeave)
	SpecializationUtil.registerFunction(vehicleType, "getMotorNotAllowedWarning", Motorized.getMotorNotAllowedWarning)
	SpecializationUtil.registerFunction(vehicleType, "startMotor", Motorized.startMotor)
	SpecializationUtil.registerFunction(vehicleType, "stopMotor", Motorized.stopMotor)
	SpecializationUtil.registerFunction(vehicleType, "updateMotorProperties", Motorized.updateMotorProperties)
	SpecializationUtil.registerFunction(vehicleType, "controlVehicle", Motorized.controlVehicle)
	SpecializationUtil.registerFunction(vehicleType, "updateConsumers", Motorized.updateConsumers)
	SpecializationUtil.registerFunction(vehicleType, "updateMotorTemperature", Motorized.updateMotorTemperature)
	SpecializationUtil.registerFunction(vehicleType, "getMotor", Motorized.getMotor)
	SpecializationUtil.registerFunction(vehicleType, "getMotorStartTime", Motorized.getMotorStartTime)
	SpecializationUtil.registerFunction(vehicleType, "getMotorType", Motorized.getMotorType)
	SpecializationUtil.registerFunction(vehicleType, "getMotorRpmPercentage", Motorized.getMotorRpmPercentage)
	SpecializationUtil.registerFunction(vehicleType, "getMotorRpmReal", Motorized.getMotorRpmReal)
	SpecializationUtil.registerFunction(vehicleType, "getMotorLoadPercentage", Motorized.getMotorLoadPercentage)
	SpecializationUtil.registerFunction(vehicleType, "getMotorBlowOffValveState", Motorized.getMotorBlowOffValveState)
	SpecializationUtil.registerFunction(vehicleType, "getMotorDifferentialSpeed", Motorized.getMotorDifferentialSpeed)
	SpecializationUtil.registerFunction(vehicleType, "getConsumerFillUnitIndex", Motorized.getConsumerFillUnitIndex)
	SpecializationUtil.registerFunction(vehicleType, "getAirConsumerUsage", Motorized.getAirConsumerUsage)
	SpecializationUtil.registerFunction(vehicleType, "getTraveledDistanceStatsActive", Motorized.getTraveledDistanceStatsActive)
	SpecializationUtil.registerFunction(vehicleType, "setGearLeversState", Motorized.setGearLeversState)
	SpecializationUtil.registerFunction(vehicleType, "generateShiftAnimation", Motorized.generateShiftAnimation)
	SpecializationUtil.registerFunction(vehicleType, "getGearInfoToDisplay", Motorized.getGearInfoToDisplay)
	SpecializationUtil.registerFunction(vehicleType, "setTransmissionDirection", Motorized.setTransmissionDirection)
	SpecializationUtil.registerFunction(vehicleType, "getDirectionChangeMode", Motorized.getDirectionChangeMode)
	SpecializationUtil.registerFunction(vehicleType, "getIsManualDirectionChangeAllowed", Motorized.getIsManualDirectionChangeAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getIsManualDirectionChangeActive", Motorized.getIsManualDirectionChangeActive)
	SpecializationUtil.registerFunction(vehicleType, "getGearShiftMode", Motorized.getGearShiftMode)
	SpecializationUtil.registerFunction(vehicleType, "stopVehicle", Motorized.stopVehicle)
end

function Motorized.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getBrakeForce", Motorized.getBrakeForce)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", Motorized.addToPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", Motorized.removeFromPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsOperating", Motorized.getIsOperating)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDeactivateOnLeave", Motorized.getDeactivateOnLeave)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDeactivateLightsOnLeave", Motorized.getDeactivateLightsOnLeave)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDashboardGroupFromXML", Motorized.loadDashboardGroupFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDashboardGroupActive", Motorized.getIsDashboardGroupActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsActiveForInteriorLights", Motorized.getIsActiveForInteriorLights)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsActiveForWipers", Motorized.getIsActiveForWipers)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getUsageCausesDamage", Motorized.getUsageCausesDamage)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getName", Motorized.getName)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Motorized.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsPowered", Motorized.getIsPowered)
end

function Motorized.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onSetBroken", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onGearDirectionChanged", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onGearChanged", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onGearGroupChanged", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onMotorBlowOffValveChanged", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onClutchCreaking", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onReverseDirectionChanged", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onVehicleSettingChanged", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onAIJobStarted", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onAIJobFinished", Motorized)
end

-- Local values: spec, _, component, configKey, maxDuration, _, sample
function Motorized:onLoad(savegame)
	local v_u_17_ = self.spec_motorized
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnRotationNodes.turnedOnRotationNode#type", "vehicle.motor.animationNodes.animationNode", "motor")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.differentialConfigurations", "vehicle.motorized.differentialConfigurations")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.motorConfigurations", "vehicle.motorized.motorConfigurations")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.maximalAirConsumptionPerFullStop", "vehicle.motorized.consumerConfigurations.consumerConfiguration.consumer(with fill type \'air\')#usage (is now in usage per second at full brake power)")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.indoorHud.rpm", "vehicle.motorized.dashboards.dashboard with valueType \'rpm\'")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.indoorHud.speed", "vehicle.motorized.dashboards.dashboard with valueType \'speed\'")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.indoorHud.fuelUsage", "vehicle.motorized.dashboards.dashboard with valueType \'fuelUsage\'")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.indoorHud.fuel", "fillUnit.dashboard with valueType \'fillLevel\'")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.motor", "vehicle.motorized.motorConfigurations.motorConfiguration(?).motor")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.transmission", "vehicle.motorized.motorConfigurations.motorConfiguration(?).transmission")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.fuelCapacity", "vehicle.motorized.consumerConfigurations.consumerConfiguration.consumer#capacity")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.motorized.motorConfigurations.motorConfiguration(?).fuelCapacity", "vehicle.motorized.consumerConfigurations.consumerConfiguration.consumer#capacity")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle#consumerConfigurationIndex", "vehicle.motorized.motorConfigurations.motorConfiguration(?)#consumerConfigurationIndex\'")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.motorized.exhaustParticleSystems#count")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.motorized.exhaustParticleSystems.exhaustParticleSystem1", "vehicle.motorized.exhaustParticleSystems.exhaustParticleSystem")
	v_u_17_.motorizedNode = nil
	for _, v18_ in pairs(self.components) do
		if v18_.motorized then
			v_u_17_.motorizedNode = v18_.node
			break
		end
	end
	v_u_17_.directionChangeMode = VehicleMotor.DIRECTION_CHANGE_MODE_AUTOMATIC
	v_u_17_.gearShiftMode = VehicleMotor.SHIFT_MODE_AUTOMATIC
	local v19_ = string.format("vehicle.motorized.motorConfigurations.motorConfiguration(%d)", self.configurations.motor - 1)
	self:loadDifferentials(self.xmlFile, self.differentialIndex)
	self:loadMotor(self.xmlFile, self.configurations.motor)
	self:loadSounds(self.xmlFile, "vehicle.motorized.sounds")
	if self.xmlFile:hasProperty(v19_) then
		self:loadSounds(self.xmlFile, v19_ .. ".sounds")
	end
	self:loadConsumerConfiguration(self.xmlFile, v_u_17_.consumerConfigurationIndex)
	if self.isClient then
		self:loadExhaustEffects(self.xmlFile)
	end
	v_u_17_.gearLevers = {}
	v_u_17_.activeGearLeverInterpolators = {}
	self.xmlFile:iterate("vehicle.motorized.gearLevers.gearLever", function(_, p20_)
		-- upvalues: (copy) self, (copy) v_u_17_
		local v_u_21_ = {
			["node"] = self.xmlFile:getValue(p20_ .. "#node", nil, self.components, self.i3dMappings)
		}
		if v_u_21_.node == nil then
			Logging.xmlWarning(self.xmlFile, "Unable to load gear lever. Missing node! \'%s\'", p20_)
		else
			v_u_21_.centerAxis = self.xmlFile:getValue(p20_ .. "#centerAxis")
			v_u_21_.changeTime = self.xmlFile:getValue(p20_ .. "#changeTime", 500)
			v_u_21_.handsOnDelay = self.xmlFile:getValue(p20_ .. "#handsOnDelay", 0)
			v_u_21_.curTarget = { getRotation(v_u_21_.node) }
			v_u_21_.states = {}
			self.xmlFile:iterate(p20_ .. ".state", function(_, p22_)
				-- upvalues: (ref) self, (copy) v_u_21_
				local v23_ = {
					["gear"] = self.xmlFile:getValue(p22_ .. "#gear"),
					["group"] = self.xmlFile:getValue(p22_ .. "#group")
				}
				if v23_.gear == nil and v23_.group == nil then
					Logging.xmlWarning(self.xmlFile, "Unable to load gear lever state. Missing gear or group! \'%s\'", p22_)
				else
					v23_.node = v_u_21_.node
					v23_.gearLever = v_u_21_
					local v24_, v25_, v26_ = getRotation(v_u_21_.node)
					local v27_ = self.xmlFile:getValue(p22_ .. "#xRot", v24_)
					local v28_ = self.xmlFile:getValue(p22_ .. "#yRot", v25_)
					local v29_ = self.xmlFile:getValue(p22_ .. "#zRot", v26_)
					v23_.rotation = { v27_, v28_, v29_ }
					v23_.useRotation = { self.xmlFile:getValue(p22_ .. "#xRot") ~= nil, self.xmlFile:getValue(p22_ .. "#yRot") ~= nil, self.xmlFile:getValue(p22_ .. "#zRot") ~= nil }
					v23_.curRotation = { v27_, v28_, v29_ }
					local v30_ = v_u_21_.states
					table.insert(v30_, v23_)
				end
			end)
			local v31_ = v_u_17_.gearLevers
			table.insert(v31_, v_u_21_)
		end
	end)
	v_u_17_.stopMotorOnLeave = true
	v_u_17_.motorStartDuration = 0
	if v_u_17_.samples ~= nil and v_u_17_.samples.motorStart ~= nil then
		v_u_17_.motorStartDuration = v_u_17_.samples.motorStart.duration
	end
	if v_u_17_.motorSamples ~= nil then
		local v32_ = 0
		for _, v33_ in ipairs(v_u_17_.motorSamples) do
			local v34_ = g_soundManager
			v32_ = math.max(v32_, v34_:getSampleLoopSynthesisStartDuration(v33_))
		end
		if v32_ ~= 0 then
			v_u_17_.motorStartDuration = v32_
		end
	end
	v_u_17_.motorStartDuration = self.xmlFile:getValue("vehicle.motorized.motorStartDuration", v_u_17_.motorStartDuration) or 0
	if self.xmlFile:hasProperty(v19_) then
		v_u_17_.motorStartDuration = self.xmlFile:getValue(v19_ .. ".motorStartDuration", v_u_17_.motorStartDuration)
	end
	v_u_17_.minBrakeForce = self.xmlFile:getValue("vehicle.motorized.brakeForce#force", 0) * 2
	v_u_17_.maxBrakeForce = self.xmlFile:getValue("vehicle.motorized.brakeForce#maxForce", 0) * 2
	v_u_17_.maxBrakeForceMass = self.xmlFile:getValue("vehicle.motorized.brakeForce#maxForceMass", 0) / 1000
	v_u_17_.maxBrakeForceMassIncludeAttachables = self.xmlFile:getValue("vehicle.motorized.brakeForce#includeAttachables", false)
	v_u_17_.clutchNoEngagedWarning = self.xmlFile:getValue("vehicle.motorized#clutchNoEngagedWarning", "warning_motorClutchNoEngaged", self.customEnvironment)
	v_u_17_.clutchCrackingGearWarning = self.xmlFile:getValue("vehicle.motorized#clutchCrackingGearWarning", "action_clutchCrackingGear", self.customEnvironment)
	v_u_17_.clutchCrackingGroupWarning = self.xmlFile:getValue("vehicle.motorized#clutchCrackingGroupWarning", "action_clutchCrackingGroup", self.customEnvironment)
	v_u_17_.turnOnText = self.xmlFile:getValue("vehicle.motorized#turnOnText", "action_startMotor", self.customEnvironment)
	v_u_17_.turnOffText = self.xmlFile:getValue("vehicle.motorized#turnOffText", "action_stopMotor", self.customEnvironment)
	v_u_17_.speedDisplayScale = 1
	v_u_17_.motorStartTime = 0
	v_u_17_.actualLoadPercentage = 0
	v_u_17_.smoothedLoadPercentage = 0
	v_u_17_.maxDecelerationDuringBrake = 0
	v_u_17_.blowOffValveState = 0
	v_u_17_.lastControlParameters = {
		["acceleratorPedal"] = nil,
		["maxSpeed"] = nil,
		["maxAcceleration"] = nil,
		["minMotorRotSpeed"] = nil,
		["maxMotorRotSpeed"] = nil,
		["maxMotorRotAcceleration"] = nil,
		["minGearRatio"] = nil,
		["maxGearRatio"] = nil,
		["maxClutchTorque"] = nil,
		["neededPtoTorque"] = nil
	}
	v_u_17_.clutchCrackingTimeOut = math.huge
	v_u_17_.clutchState = 0
	v_u_17_.clutchStateSent = 0
	v_u_17_.motorState = MotorState.OFF
	v_u_17_.motorStopTimerDuration = g_gameSettings:getValue(GameSettings.SETTING.MOTOR_STOP_TIMER_DURATION)
	v_u_17_.motorStopTimer = v_u_17_.motorStopTimerDuration
	v_u_17_.motorNotRequiredTimer = 0
	v_u_17_.motorStateIgnitionTime = 0
	v_u_17_.motorTemperature = {}
	v_u_17_.motorTemperature.value = 20
	v_u_17_.motorTemperature.valueSend = 20
	v_u_17_.motorTemperature.valueMax = 120
	v_u_17_.motorTemperature.valueMin = 20
	v_u_17_.motorTemperature.heatingPerMS = 0.0015
	v_u_17_.motorTemperature.coolingByWindPerMS = 0.001
	v_u_17_.motorFan = {}
	v_u_17_.motorFan.enabled = false
	v_u_17_.motorFan.enableTemperature = 95
	v_u_17_.motorFan.disableTemperature = 85
	v_u_17_.motorFan.coolingPerMS = 0.003
	v_u_17_.lastFuelUsage = 0
	v_u_17_.lastFuelUsageDisplay = 0
	v_u_17_.lastFuelUsageDisplayTime = 0
	v_u_17_.fuelUsageBuffer = ValueBuffer.new(250)
	v_u_17_.lastDefUsage = 0
	v_u_17_.lastAirUsage = 0
	v_u_17_.lastVehicleDamage = 0
	v_u_17_.forceSpeedHudDisplay = self.xmlFile:getValue("vehicle.motorized#forceSpeedHudDisplay", false)
	v_u_17_.forceRpmHudDisplay = self.xmlFile:getValue("vehicle.motorized#forceRpmHudDisplay", false)
	v_u_17_.statsType = string.lower(self.xmlFile:getValue("vehicle.motorized#statsType", "tractor"))
	if v_u_17_.statsType ~= "tractor" and (v_u_17_.statsType ~= "car" and v_u_17_.statsType ~= "truck") then
		v_u_17_.statsType = "tractor"
	end
	v_u_17_.statsTypeDistance = v_u_17_.statsType .. "Distance"
	v_u_17_.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.motorized.animationNodes", self.components, self, self.i3dMappings)
	v_u_17_.traveledDistanceBuffer = 0
	v_u_17_.dirtyFlag = self:getNextDirtyFlag()
	v_u_17_.inputDirtyFlag = self:getNextDirtyFlag()
	self:registerVehicleSetting(GameSettings.SETTING.DIRECTION_CHANGE_MODE, false)
	self:registerVehicleSetting(GameSettings.SETTING.GEAR_SHIFT_MODE, false)
end

-- Local values: spec, moneyChange, _, consumer, fillLevel, minFillLevel, fillLevelToFill, costs, _, fillType, fillTypeName
function Motorized:onPostLoad(savegame)
	local v37_ = self.spec_motorized
	if self.isServer then
		local v38_ = 0
		for _, v39_ in pairs(v37_.consumersByFillTypeName) do
			local v40_ = self:getFillUnitFillLevel(v39_.fillUnitIndex)
			local v41_ = self:getFillUnitCapacity(v39_.fillUnitIndex) * 0.1
			if v40_ < v41_ then
				local v42_ = v41_ - v40_
				self:addFillUnitFillLevel(self:getOwnerFarmId(), v39_.fillUnitIndex, v42_, v39_.fillType, ToolType.UNDEFINED)
				local v43_ = v42_ * g_currentMission.economyManager:getCostPerLiter(v39_.fillType) * 2
				g_farmManager:updateFarmStats(self:getOwnerFarmId(), "expenses", v43_)
				g_currentMission:addMoney(-v43_, self:getOwnerFarmId(), MoneyType.PURCHASE_FUEL, false, false)
				v38_ = v38_ + v43_
			end
		end
		if v38_ > 0 then
			g_currentMission:addMoneyChange(-v38_, self:getOwnerFarmId(), MoneyType.PURCHASE_FUEL, true)
		end
	end
	v37_.propellantFillUnitIndices = {}
	for _, v44_ in pairs({
		FillType.DIESEL,
		FillType.DEF,
		FillType.ELECTRICCHARGE,
		FillType.METHANE
	}) do
		local v45_ = g_fillTypeManager:getFillTypeNameByIndex(v44_)
		if v37_.consumersByFillTypeName[v45_] ~= nil then
			local v46_ = v37_.propellantFillUnitIndices
			local v47_ = v37_.consumersByFillTypeName[v45_].fillUnitIndex
			table.insert(v46_, v47_)
		end
	end
	if v37_.motor ~= nil then
		v37_.motor:postLoad(savegame)
	end
end

-- Local values: spec, rpm, load, speed, speedDir, fuelUsage, motorTemperature, motorTemperatureWarning, clutchPedal, gear, gearGroup, gearIndex, gearGroupIndex, gearShiftUp, gearShiftDown, gearShiftUpDown, movingDirection, directionForward, directionForwardExclusive, directionBackward, directionNeutral, movingDirectionLetter, ignitionState, battery
function Motorized:onRegisterDashboardValueTypes()
	local v_u_49_ = self.spec_motorized
	local v50_ = DashboardValueType.new("motorized", "rpm")
	v50_:setValue(self, "getMotorRpmReal")
	v50_:setRange(0, v_u_49_.motor:getMaxRpm())
	v50_:setInterpolationSpeed(function(_, _)
		-- upvalues: (copy) v_u_49_
		return v_u_49_.motor:getMaxRpm() * 0.001
	end)
	self:registerDashboardValueType(v50_)
	local v51_ = DashboardValueType.new("motorized", "load")
	v51_:setValue(v_u_49_.motor, "getSmoothLoadPercentage")
	v51_:setRange(0, 100)
	v51_:setInterpolationSpeed(0.1)
	v51_:setValueFactor(100)
	self:registerDashboardValueType(v51_)
	local v52_ = DashboardValueType.new("motorized", "speed")
	v52_:setValue(self, "getLastSpeed")
	v52_:setRange(0, v_u_49_.motor:getMaximumForwardSpeed() * 3.6)
	v52_:setInterpolationSpeed(function(_, _)
		-- upvalues: (copy) self
		return self:getLastSpeed() * 0.001
	end)
	self:registerDashboardValueType(v52_)
	local v53_ = DashboardValueType.new("motorized", "speedDir")
	v53_:setValue(self, function()
		-- upvalues: (copy) self, (copy) v_u_49_
		return self:getLastSpeed() * v_u_49_.motor:getDrivingDirection()
	end)
	v53_:setRange(-v_u_49_.motor:getMaximumBackwardSpeed() * 3.6, v_u_49_.motor:getMaximumForwardSpeed() * 3.6)
	v53_:setInterpolationSpeed(function(_, _)
		-- upvalues: (copy) v_u_49_
		return v_u_49_.motor:getMaximumForwardSpeed() * 3.6 * 0.001
	end)
	v53_:setCenter(0)
	self:registerDashboardValueType(v53_)
	local v54_ = DashboardValueType.new("motorized", "fuelUsage")
	v54_:setValue(v_u_49_, "lastFuelUsageDisplay")
	self:registerDashboardValueType(v54_)
	local v55_ = DashboardValueType.new("motorized", "motorTemperature")
	v55_:setValue(v_u_49_.motorTemperature, "value")
	v55_:setRange("valueMin", "valueMax")
	v55_:setInterpolationSpeed(function(p56_, _)
		return (p56_.valueMax - p56_.valueMin) * 0.001
	end)
	self:registerDashboardValueType(v55_)
	local v57_ = DashboardValueType.new("motorized", "motorTemperatureWarning")
	v57_:setValue(v_u_49_.motorTemperature, function(_, p58_)
		-- upvalues: (copy) v_u_49_
		local v59_ = v_u_49_.motorTemperature.value
		local v60_
		if p58_.warningThresholdMin < v59_ then
			v60_ = v59_ < p58_.warningThresholdMax
		else
			v60_ = false
		end
		return v60_
	end)
	v57_:setAdditionalFunctions(Dashboard.warningAttributes)
	self:registerDashboardValueType(v57_)
	local v61_ = DashboardValueType.new("motorized", "clutchPedal")
	v61_:setValue(v_u_49_.motor, "getSmoothedClutchPedal")
	v61_:setRange(0, 1)
	self:registerDashboardValueType(v61_)
	local v62_ = DashboardValueType.new("motorized", "gear")
	v62_:setValue(v_u_49_.motor, function()
		-- upvalues: (copy) v_u_49_
		return v_u_49_.motor:getGearToDisplay(true)
	end)
	v62_:setRange(0, math.huge)
	v62_:setPollUpdate(v_u_49_.motor.forwardGears == nil)
	self:registerDashboardValueType(v62_)
	local v63_ = DashboardValueType.new("motorized", "gearGroup")
	v63_:setValue(v_u_49_.motor, function()
		-- upvalues: (copy) v_u_49_
		return v_u_49_.motor:getGearGroupToDisplay(true)
	end)
	v63_:setRange(0, math.huge)
	v63_:setPollUpdate(false)
	self:registerDashboardValueType(v63_)
	local v64_ = DashboardValueType.new("motorized", "gearIndex")
	v64_:setValue(v_u_49_.motor, function()
		-- upvalues: (copy) v_u_49_
		return v_u_49_.motor.targetGear
	end)
	v64_:setRange(0, math.huge)
	v64_:setPollUpdate(false)
	self:registerDashboardValueType(v64_)
	local v65_ = DashboardValueType.new("motorized", "gearGroupIndex")
	v65_:setValue(v_u_49_.motor, function()
		-- upvalues: (copy) v_u_49_
		return v_u_49_.motor.activeGearGroupIndex
	end)
	v65_:setRange(0, math.huge)
	v65_:setPollUpdate(false)
	self:registerDashboardValueType(v65_)
	local v66_ = DashboardValueType.new("motorized", "gearShiftUp")
	v66_:setValue(v_u_49_.motor, function(p67_)
		local v68_
		if g_time - p67_.lastGearChangeTime < 200 then
			v68_ = p67_.targetGear > p67_.previousGear
		else
			v68_ = false
		end
		return v68_
	end)
	self:registerDashboardValueType(v66_)
	local v69_ = DashboardValueType.new("motorized", "gearShiftDown")
	v69_:setValue(v_u_49_.motor, function(p70_)
		local v71_
		if g_time - p70_.lastGearChangeTime < 200 then
			v71_ = p70_.targetGear < p70_.previousGear
		else
			v71_ = false
		end
		return v71_
	end)
	self:registerDashboardValueType(v69_)
	local v72_ = DashboardValueType.new("motorized", "gearShiftUpDown")
	v72_:setValue(v_u_49_.motor, function(p73_)
		if g_time - p73_.lastGearChangeTime >= 200 then
			return 0
		end
		local v74_ = p73_.targetGear - p73_.previousGear
		return math.sign(v74_)
	end)
	v72_:setRange(-1, 1)
	self:registerDashboardValueType(v72_)
	local v75_ = DashboardValueType.new("motorized", "movingDirection")
	v75_:setValue(v_u_49_.motor, "getDrivingDirection")
	v75_:setRange(-1, 1)
	self:registerDashboardValueType(v75_)
	local v76_ = DashboardValueType.new("motorized", "directionForward")
	v76_:setValue(v_u_49_.motor, function(p77_)
		return p77_:getDrivingDirection() >= 0
	end)
	self:registerDashboardValueType(v76_)
	local v78_ = DashboardValueType.new("motorized", "directionForwardExclusive")
	v78_:setValue(v_u_49_.motor, function(p79_)
		return p79_:getDrivingDirection() > 0
	end)
	self:registerDashboardValueType(v78_)
	local v80_ = DashboardValueType.new("motorized", "directionBackward")
	v80_:setValue(v_u_49_.motor, function(p81_)
		return p81_:getDrivingDirection() < 0
	end)
	self:registerDashboardValueType(v80_)
	local v82_ = DashboardValueType.new("motorized", "directionNeutral")
	v82_:setValue(v_u_49_.motor, function(p83_)
		return p83_:getDrivingDirection() == 0
	end)
	self:registerDashboardValueType(v82_)
	local v84_ = DashboardValueType.new("motorized", "movingDirectionLetter")
	v84_:setValue(v_u_49_.motor, function(p85_)
		return p85_:getDrivingDirection() == 1 and "F" or (p85_:getDrivingDirection() == -1 and "R" or "N")
	end)
	self:registerDashboardValueType(v84_)
	local v86_ = DashboardValueType.new("motorized", "ignitionState")
	v86_:setValue(self, function()
		-- upvalues: (copy) self
		if not g_ignitionLockManager:getIsAvailable() then
			local v87_ = self:getMotorState()
			return v87_ == MotorState.ON and 2 or (v87_ == MotorState.STARTING and 1 or 0)
		end
		local v88_ = g_ignitionLockManager:getState()
		if v88_ == IgnitionLockState.OFF then
			return 0
		end
		if v88_ == IgnitionLockState.IGNITION then
			return 2
		end
		if v88_ == IgnitionLockState.START then
			return 1
		end
	end)
	v86_:setRange(0, 2)
	self:registerDashboardValueType(v86_)
	local v89_ = DashboardValueType.new("motorized", "battery")
	v89_:setValue(self, 12 + (math.random() * 0.5 - 0.15))
	v89_:setRange(0, 15)
	v89_:setInterpolationSpeed(0.015)
	self:registerDashboardValueType(v89_)
end

-- Local values: spec, _, sharedLoadRequestId
function Motorized:onDelete()
	local v91_ = self.spec_motorized
	if v91_.motor ~= nil then
		v91_.motor:delete()
	end
	if v91_.sharedLoadRequestIds ~= nil then
		for _, v92_ in ipairs(v91_.sharedLoadRequestIds) do
			g_i3DManager:releaseSharedI3DFile(v92_)
		end
		v91_.sharedLoadRequestIds = nil
	end
	ParticleUtil.deleteParticleSystems(v91_.exhaustParticleSystems)
	g_soundManager:deleteSamples(v91_.samples)
	g_soundManager:deleteSamples(v91_.motorSamples)
	g_soundManager:deleteSamples(v91_.gearboxSamples)
	g_animationManager:deleteAnimations(v91_.animationNodes)
	if v91_.effects ~= nil then
		g_effectManager:deleteEffects(v91_.effects)
	end
end

-- Local values: motorState
function Motorized:onReadStream(streamId, connection)
	self:setMotorState(MotorState.readStream(streamId), true)
end

function Motorized:onWriteStream(streamId, connection)
	MotorState.writeStream(streamId, self.spec_motorized.motorState)
end

-- Local values: spec, rpm, rpmRange, loadPercentage, clutchState
function Motorized:onReadUpdateStream(streamId, timestamp, connection)
	local v100_ = self.spec_motorized
	if connection.isServer then
		if streamReadBool(streamId) then
			local v101_ = streamReadUIntN(streamId, 11) / 2047
			local v102_ = v100_.motor:getMaxRpm() - v100_.motor:getMinRpm()
			v100_.motor:setEqualizedMotorRpm(v101_ * v102_ + v100_.motor:getMinRpm())
			local v103_ = streamReadUIntN(streamId, 7)
			v100_.motor.rawLoadPercentage = v103_ / 127
			v100_.brakeCompressor.doFill = streamReadBool(streamId)
			local v104_ = streamReadUIntN(streamId, 5)
			v100_.motor:onManualClutchChanged(v104_ / 31)
		end
		if streamReadBool(streamId) then
			v100_.motor:readGearDataFromStream(streamId)
			return
		end
	elseif streamReadBool(streamId) and streamReadBool(streamId) then
		v100_.clutchState = streamReadUIntN(streamId, 7) / 127
		v100_.motor:onManualClutchChanged(v100_.clutchState)
		if v100_.clutchState > 0 then
			self:raiseActive()
		end
	end
end

-- Local values: spec, motorState, rpmRange, rpm
function Motorized:onWriteUpdateStream(streamId, connection, dirtyMask)
	local v109_ = self.spec_motorized
	if connection.isServer then
		local v110_ = streamWriteBool
		local v111_ = v109_.inputDirtyFlag
		if v110_(streamId, bit32.band(dirtyMask, v111_) ~= 0) and streamWriteBool(streamId, v109_.clutchState ~= v109_.clutchStateSent) then
			streamWriteUIntN(streamId, 127 * v109_.clutchState, 7)
			v109_.clutchStateSent = v109_.clutchState
		end
	else
		local v112_ = self:getMotorState()
		if streamWriteBool(streamId, v112_ == MotorState.STARTING and true or v112_ == MotorState.ON) then
			local v113_ = v109_.motor:getMaxRpm() - v109_.motor:getMinRpm()
			local v114_ = (v109_.motor:getEqualizedMotorRpm() - v109_.motor:getMinRpm()) / v113_
			local v115_ = math.clamp(v114_, 0, 1) * 2047
			local v116_ = math.floor(v115_)
			streamWriteUIntN(streamId, v116_, 11)
			streamWriteUIntN(streamId, 127 * v109_.actualLoadPercentage, 7)
			streamWriteBool(streamId, v109_.brakeCompressor.doFill)
			streamWriteUIntN(streamId, 31 * v109_.motor:getClutchPedal(), 5)
		end
		local v117_ = streamWriteBool
		local v118_ = v109_.dirtyFlag
		if v117_(streamId, bit32.band(dirtyMask, v118_) ~= 0) then
			v109_.motor:writeGearDataToStream(streamId)
			return
		end
	end
end

-- Local values: spec, accInput, motorState, damage, samples, rpm, minRpm, maxRpm, rpmPercentage, loadPercentage, consumer, isBraking, reverserDirection, isReverseDriving, state, gearLeverInterpolator, currentInterpolation, sample, limit, sample, farmId, distance
function Motorized:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v121_ = self.spec_motorized
	local v122_ = self.getAxisForward == nil and 0 or self:getAxisForward()
	local v123_ = self:getMotorState()
	if v123_ == MotorState.STARTING or v123_ == MotorState.ON then
		if self.isServer and (v123_ == MotorState.STARTING and v121_.motorStartTime < g_currentMission.time) then
			self:setMotorState(MotorState.ON)
		end
		v121_.motor:update(dt)
		if self.isServer then
			local v124_ = v121_.motor.rawLoadPercentage
			v121_.actualLoadPercentage = math.clamp(v124_, 0, 1)
		end
		v121_.smoothedLoadPercentage = v121_.motor:getSmoothLoadPercentage()
		local v125_ = self.getCruiseControlState ~= nil and self:getCruiseControlState() ~= Drivable.CRUISECONTROL_STATE_OFF and 1 or v122_
		if self.isServer then
			self:updateConsumers(dt, v125_)
			local v126_ = self:getVehicleDamage() - v121_.lastVehicleDamage
			if math.abs(v126_) > 0.05 then
				self:updateMotorProperties()
				v121_.lastVehicleDamage = self:getVehicleDamage()
			end
		end
		if self.isClient then
			local v127_ = v121_.samples
			local v128_ = self:getMotorRpmReal()
			local v129_ = v121_.motor.minRpm
			local v130_ = v121_.motor.maxRpm
			local v131_ = (v128_ - v129_) / (v130_ - v129_)
			local v132_ = math.min(v131_, 1)
			local v133_ = math.max(v132_, 0)
			local v134_ = self:getMotorLoadPercentage()
			local v135_ = math.min(v134_, 1)
			local v136_ = math.max(v135_, -1)
			g_soundManager:setSamplesLoopSynthesisParameters(v121_.motorSamples, v133_, v136_)
			if g_soundManager:getIsSamplePlaying(v121_.motorSamples[1]) then
				if v127_.airCompressorRun ~= nil and (v121_.consumersByFillTypeName ~= nil and v121_.consumersByFillTypeName.AIR ~= nil) then
					if v121_.consumersByFillTypeName.AIR.doRefill then
						if not g_soundManager:getIsSamplePlaying(v127_.airCompressorRun) then
							if v127_.airCompressorStart == nil then
								g_soundManager:playSample(v127_.airCompressorRun)
							else
								if not g_soundManager:getIsSamplePlaying(v127_.airCompressorStart) and v121_.brakeCompressor.playSampleRunTime == nil then
									g_soundManager:playSample(v127_.airCompressorStart)
									v121_.brakeCompressor.playSampleRunTime = g_currentMission.time + v127_.airCompressorStart.duration
								end
								if not g_soundManager:getIsSamplePlaying(v127_.airCompressorStart) then
									v121_.brakeCompressor.playSampleRunTime = nil
									g_soundManager:stopSample(v127_.airCompressorStart)
									g_soundManager:playSample(v127_.airCompressorRun)
								end
							end
						end
					elseif g_soundManager:getIsSamplePlaying(v127_.airCompressorRun) then
						g_soundManager:stopSample(v127_.airCompressorRun)
						g_soundManager:playSample(v127_.airCompressorStop)
					end
				end
				if v121_.compressionSoundTime <= g_currentMission.time then
					g_soundManager:playSample(v127_.airRelease)
					v121_.compressionSoundTime = g_currentMission.time + math.random(10000, 40000)
				end
				local v137_
				if self:getDecelerationAxis() > 0 then
					v137_ = self:getLastSpeed() > 1
				else
					v137_ = false
				end
				if v127_.compressedAir ~= nil then
					if v137_ then
						v127_.compressedAir.brakeTime = v127_.compressedAir.brakeTime + dt
					elseif v127_.compressedAir.brakeTime > 0 then
						v127_.compressedAir.lastBrakeTime = v127_.compressedAir.brakeTime
						v127_.compressedAir.brakeTime = 0
						g_soundManager:playSample(v127_.compressedAir)
					end
				end
				if v127_.brake ~= nil then
					if v137_ then
						if not v121_.isBrakeSamplePlaying then
							g_soundManager:playSample(v127_.brake)
							v121_.isBrakeSamplePlaying = true
						end
					elseif v121_.isBrakeSamplePlaying then
						g_soundManager:stopSample(v127_.brake)
						v121_.isBrakeSamplePlaying = false
					end
				end
				if v127_.reverseDrive ~= nil then
					local v138_ = self.getReverserDirection == nil and 1 or self:getReverserDirection()
					local v139_
					if self:getLastSpeed() > v121_.reverseDriveThreshold then
						v139_ = self.movingDirection ~= v138_
					else
						v139_ = false
					end
					if g_soundManager:getIsSamplePlaying(v127_.reverseDrive) or not v139_ then
						if not v139_ then
							g_soundManager:stopSample(v127_.reverseDrive)
						end
					else
						g_soundManager:playSample(v127_.reverseDrive)
					end
				end
			end
			for v140_, v141_ in pairs(v121_.activeGearLeverInterpolators) do
				local v142_ = v141_.interpolations[v141_.currentInterpolation]
				if v142_ == nil then
					v121_.activeGearLeverInterpolators[v140_] = nil
				elseif v141_.handsOnDelay > 0 then
					v141_.handsOnDelay = v141_.handsOnDelay - dt
					if v141_.handsOnDelay <= 0 then
						local v143_ = v141_.isGear and v121_.samples.gearLeverStart or v121_.samples.gearGroupLeverStart
						if not g_soundManager:getIsSamplePlaying(v143_) then
							g_soundManager:playSample(v143_)
						end
					end
					if self.setCharacterTargetNodeStateDirty ~= nil then
						self:setCharacterTargetNodeStateDirty(v140_.node, true)
					end
				else
					local v144_ = v140_.curRotation
					local v145_ = v140_.curRotation
					local v146_ = v140_.curRotation
					local v147_, v148_, v149_ = getRotation(v140_.node)
					v144_[1] = v147_
					v145_[2] = v148_
					v146_[3] = v149_
					local v150_ = math.min
					if v142_.speed < 0 then
						v150_ = math.max
					end
					v140_.curRotation[v142_.axis] = v150_(v140_.curRotation[v142_.axis] + v142_.speed * dt, v142_.tar)
					setRotation(v140_.node, v140_.curRotation[1], v140_.curRotation[2], v140_.curRotation[3])
					if v140_.curRotation[v142_.axis] == v142_.tar then
						v141_.currentInterpolation = v141_.currentInterpolation + 1
						if v141_.currentInterpolation > #v141_.interpolations then
							v121_.activeGearLeverInterpolators[v140_] = nil
							if v141_.isResetPosition and self.resetCharacterTargetNodeStateDefaults ~= nil then
								self:resetCharacterTargetNodeStateDefaults(v140_.node)
							end
							local v151_ = v141_.isGear and v121_.samples.gearLeverEnd or v121_.samples.gearGroupLeverEnd
							if not g_soundManager:getIsSamplePlaying(v151_) then
								g_soundManager:playSample(v151_)
							end
						end
					end
					if self.setCharacterTargetNodeStateDirty ~= nil then
						self:setCharacterTargetNodeStateDirty(v140_.node)
					end
				end
			end
		end
		if self.isServer and (not self:getIsAIActive() and (self:getTraveledDistanceStatsActive() and self.lastMovedDistance > 0.001)) then
			v121_.traveledDistanceBuffer = v121_.traveledDistanceBuffer + self.lastMovedDistance
			if v121_.traveledDistanceBuffer > 10 then
				local v152_ = self:getOwnerFarmId()
				local v153_ = v121_.traveledDistanceBuffer * 0.001
				g_farmManager:updateFarmStats(v152_, "traveledDistance", v153_)
				g_farmManager:updateFarmStats(v152_, v121_.statsTypeDistance, v153_)
				v121_.traveledDistanceBuffer = 0
			end
		end
	end
end

-- Local values: spec, missionInfo, automaticMotorStartEnabled, motorState, isEntered, isControlled, isPlayerInRange, _, player, distance, _, enterable, distance, motorState, motorState, rpmScale, _, ps, scale, _, exhaustFlap, minRandom, maxRandom, state, angle, _, effect, posX, posY, posZ, vx, vy, vz, ex, ey, ez, lx, ly, lz, distance, xFactor, yFactor, xRot, zRot, scale, r, g, b, a, warning, ignitionState, warning
function Motorized:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v157_ = self.spec_motorized
	local v158_ = g_currentMission.missionInfo.automaticMotorStartEnabled
	if self.isServer then
		if not v158_ then
			local v159_ = self:getMotorState()
			if (v159_ == MotorState.STARTING or v159_ == MotorState.ON) and not self:getIsAIActive() then
				local v160_
				if self.getIsEntered == nil then
					v160_ = false
				else
					v160_ = self:getIsEntered()
				end
				local v161_
				if self.getIsControlled == nil then
					v161_ = false
				else
					v161_ = self:getIsControlled()
				end
				if not (v160_ or v161_) then
					local v162_ = false
					for _, v163_ in pairs(g_currentMission.playerSystem.players) do
						if v163_.isControlled and calcDistanceFrom(self.rootNode, v163_.rootNode) < 250 then
							v162_ = true
							break
						end
					end
					if not v162_ then
						for _, v164_ in pairs(g_currentMission.vehicleSystem.enterables) do
							if v164_:getIsInUse(nil) and calcDistanceFrom(self.rootNode, v164_.rootNode) < 250 then
								v162_ = true
								break
							end
						end
					end
					if v162_ then
						v157_.motorStopTimer = v157_.motorStopTimerDuration
					else
						v157_.motorStopTimer = v157_.motorStopTimer - dt
						if v157_.motorStopTimer <= 0 then
							self:stopMotor()
						end
					end
				end
			end
		end
		local v165_ = self:getMotorState()
		if v165_ == MotorState.STARTING or v165_ == MotorState.ON then
			self:updateMotorTemperature(dt)
		end
		if v158_ then
			if v165_ == MotorState.OFF or v165_ == MotorState.IGNITION then
				if not g_ignitionLockManager:getIsAvailable() then
					if (self.getIsControlled ~= nil and self:getIsControlled() or self.getIsEnteredForInput ~= nil and self:getIsEnteredForInput()) and self:getCanMotorRun() then
						self:startMotor(true)
					end
					if self:getRequiresPower() and self:getCanMotorRun() then
						self:startMotor(true)
					end
				end
			elseif self.getIsControlled ~= nil and (not self:getIsControlled() and (self.getIsEnteredForInput ~= nil and not self:getIsEnteredForInput())) then
				if self:getStopMotorOnLeave() then
					v157_.motorNotRequiredTimer = v157_.motorNotRequiredTimer + dt
					if v157_.motorNotRequiredTimer > 250 then
						self:stopMotor(true)
					end
				end
				self:raiseActive()
			end
		end
	end
	if self.isClient then
		local v166_ = self:getMotorState()
		if v166_ == MotorState.STARTING or v166_ == MotorState.ON then
			local v167_ = self:getMotorRpmReal() / v157_.motor:getMaxRpm()
			if v157_.exhaustParticleSystems ~= nil then
				for _, v168_ in pairs(v157_.exhaustParticleSystems) do
					local v169_ = MathUtil.lerp(v157_.exhaustParticleSystems.minScale, v157_.exhaustParticleSystems.maxScale, v167_)
					ParticleUtil.setEmitCountScale(v157_.exhaustParticleSystems, v169_)
					ParticleUtil.setParticleLifespan(v168_, v168_.originalLifespan * v169_)
				end
			end
			for _, v170_ in ipairs(v157_.exhaustFlaps) do
				local v171_ = MathUtil.lerp(-0.1, 0.1, math.random()) + v167_
				local v172_ = math.clamp(v171_, 0, 1) * v170_.maxRot
				if v170_.rotationAxis == 1 then
					setRotation(v170_.node, v172_, 0, 0)
				elseif v170_.rotationAxis == 2 then
					setRotation(v170_.node, 0, v172_, 0)
				else
					setRotation(v170_.node, 0, 0, v172_)
				end
			end
			if v157_.effects ~= nil then
				g_effectManager:setDensity(v157_.effects, v167_)
			end
			if v157_.exhaustEffects ~= nil then
				for _, v173_ in pairs(v157_.exhaustEffects) do
					local v174_, v175_, v176_ = localToWorld(v173_.effectNode, 0, 0.5, 0)
					if v173_.lastPosition == nil then
						v173_.lastPosition = { v174_, v175_, v176_ }
					end
					local v177_ = (v174_ - v173_.lastPosition[1]) * 10
					local v178_ = (v175_ - v173_.lastPosition[2]) * 10
					local v179_ = (v176_ - v173_.lastPosition[3]) * 10
					local v180_, v181_, v182_ = localToWorld(v173_.effectNode, 0, 1, 0)
					local v183_ = v180_ - v177_
					local v184_ = v181_ - v178_ + v173_.upFactor
					local v185_ = v182_ - v179_
					local v186_, v187_, v188_ = worldToLocal(v173_.effectNode, v183_, v184_, v185_)
					local v189_ = MathUtil.vector2Length(v186_, v188_)
					if v189_ > 0 then
						v186_, v188_ = MathUtil.vector2Normalize(v186_, v188_)
					end
					local v190_ = math.max(v187_, 0.01)
					local v191_ = math.abs(v190_)
					local v192_ = v189_ / v191_
					local v193_ = math.atan(v192_) * (1.2 + 2 * v191_)
					local v194_ = v189_ / v191_
					local v195_ = math.atan(v194_) * (1.2 + 2 * v191_)
					local v196_ = v188_ / v191_
					local v197_ = math.atan(v196_) * v193_
					local v198_ = v186_ / v191_
					local v199_ = -math.atan(v198_) * v195_
					v173_.xRot = v173_.xRot * 0.95 + v197_ * 0.05
					v173_.zRot = v173_.zRot * 0.95 + v199_ * 0.05
					local v200_ = MathUtil.lerp(v173_.minRpmScale, v173_.maxRpmScale, v167_)
					setShaderParameter(v173_.effectNode, "param", v173_.xRot, v173_.zRot, 0, v200_, false)
					local v201_ = MathUtil.lerp(v173_.minRpmColor[1], v173_.maxRpmColor[1], v167_)
					local v202_ = MathUtil.lerp(v173_.minRpmColor[2], v173_.maxRpmColor[2], v167_)
					local v203_ = MathUtil.lerp(v173_.minRpmColor[3], v173_.maxRpmColor[3], v167_)
					local v204_ = MathUtil.lerp(v173_.minRpmColor[4], v173_.maxRpmColor[4], v167_)
					setShaderParameter(v173_.effectNode, "exhaustColor", v201_, v202_, v203_, v204_, false)
					v173_.lastPosition[1] = v174_
					v173_.lastPosition[2] = v175_
					v173_.lastPosition[3] = v176_
				end
			end
			v157_.lastFuelUsageDisplayTime = v157_.lastFuelUsageDisplayTime + dt
			if v157_.lastFuelUsageDisplayTime > 250 then
				v157_.lastFuelUsageDisplayTime = 0
				v157_.lastFuelUsageDisplay = v157_.fuelUsageBuffer:getAverage()
			end
			v157_.fuelUsageBuffer:add(v157_.lastFuelUsage)
		end
		if v157_.clutchCrackingTimeOut < g_time then
			if g_soundManager:getIsSamplePlaying(v157_.samples.clutchCracking) then
				g_soundManager:stopSample(v157_.samples.clutchCracking)
			end
			if v157_.clutchCrackingGearIndex ~= nil then
				self:setGearLeversState(0, nil, 500)
			end
			if v157_.clutchCrackingGroupIndex ~= nil then
				self:setGearLeversState(nil, 0, 500)
			end
			v157_.clutchCrackingTimeOut = math.huge
		end
		if isActiveForInputIgnoreSelection then
			if v158_ and not self:getCanMotorRun() then
				local v205_ = self:getMotorNotAllowedWarning()
				if v205_ ~= nil then
					g_currentMission:showBlinkingWarning(v205_, 2000)
				end
			end
			if g_ignitionLockManager:getIsAvailable() and not self:getIsAIActive() then
				local v206_ = g_ignitionLockManager:getState()
				local v207_ = self:getMotorState()
				if v206_ == IgnitionLockState.OFF then
					if v207_ ~= MotorState.OFF then
						self:setMotorState(MotorState.OFF)
					end
				elseif v206_ == IgnitionLockState.IGNITION then
					if v207_ == MotorState.OFF then
						self:setMotorState(MotorState.IGNITION)
					end
				elseif v206_ == IgnitionLockState.START and (v207_ ~= MotorState.STARTING and v207_ ~= MotorState.ON) then
					if self:getCanMotorRun() then
						self:setMotorState(MotorState.STARTING)
					else
						local v208_ = self:getMotorNotAllowedWarning()
						if v208_ ~= nil then
							g_currentMission:showBlinkingWarning(v208_, 2000)
						end
					end
				end
			end
			Motorized.updateActionEvents(self)
		end
	end
end

-- Local values: key, _, spec
function Motorized:loadDifferentials(xmlFile, configDifferentialIndex)
	local v212_, _ = ConfigurationUtil.getXMLConfigurationKey(xmlFile, configDifferentialIndex, "vehicle.motorized.differentialConfigurations.differentialConfiguration", "vehicle.motorized.differentials", "differentials")
	local v_u_213_ = self.spec_motorized
	v_u_213_.differentials = {}
	if self.isServer and v_u_213_.motorizedNode ~= nil then
		xmlFile:iterate(v212_ .. ".differentials.differential", function(_, p214_)
			-- upvalues: (copy) xmlFile, (copy) self, (copy) v_u_213_
			local v215_ = xmlFile:getValue(p214_ .. "#torqueRatio", 0.5)
			local v216_ = xmlFile:getValue(p214_ .. "#maxSpeedRatio", 1.3)
			local v217_ = { -1, -1 }
			local v218_ = { false, false }
			for v219_ = 1, 2 do
				local v220_ = xmlFile:getValue(p214_ .. string.format("#wheelIndex%d", v219_))
				if v220_ == nil then
					local v221_ = xmlFile:getValue(p214_ .. string.format("#differentialIndex%d", v219_))
					if v221_ ~= nil then
						v217_[v219_] = v221_ - 1
						v218_[v219_] = false
						if v221_ == 0 then
							Logging.xmlWarning(self.xmlFile, "Unable to find differentialIndex \'0\' for differential \'%s\' (Indices start at 1)", p214_)
						end
					end
				elseif self:getWheelFromWheelIndex(v220_) == nil then
					Logging.xmlWarning(self.xmlFile, "Unable to find wheelIndex \'%d\' for differential \'%s\' (Indices start at 1)", v220_, p214_)
				else
					v217_[v219_] = v220_
					v218_[v219_] = true
				end
			end
			if v217_[1] ~= -1 and v217_[2] ~= -1 then
				local v222_ = v_u_213_.differentials
				local v223_ = {
					["torqueRatio"] = v215_,
					["maxSpeedRatio"] = v216_,
					["diffIndex1"] = v217_[1],
					["diffIndex1IsWheel"] = v218_[1],
					["diffIndex2"] = v217_[2],
					["diffIndex2IsWheel"] = v218_[2]
				}
				table.insert(v222_, v223_)
			end
		end)
		if #v_u_213_.differentials == 0 then
			Logging.xmlWarning(self.xmlFile, "No differentials defined")
		end
	end
end

-- Local values: key, spec, fallbackConfigKey, vehicleName, params, motorMinRpm, motorMaxRpm, minSpeed, maxForwardSpeed, maxBackwardSpeed, spec_wheels, accelerationLimit, brakeForce, lowBrakeForceScale, lowBrakeForceSpeedLimit, torqueScale, ptoMotorRpmRatio, transmissionKey, minForwardGearRatio, maxForwardGearRatio, minBackwardGearRatio, maxBackwardGearRatio, gearChangeTime, autoGearChangeTime, axleRatio, startGearThreshold, forwardGears, backwardGears, gearGroups, groupsType, groupChangeTime, directionChangeUseGear, directionChangeGearIndex, directionChangeUseGroup, directionChangeGroupIndex, directionChangeTime, manualShiftGears, manualShiftGroups, torqueCurve, torqueI, torqueBase, torqueKey, normRpm, rpm, torque, rotInertia, dampingRateScale, motorRotationAccelerationLimit
function Motorized:loadMotor(xmlFile, motorId)
	local v227_, _ = ConfigurationUtil.getXMLConfigurationKey(xmlFile, motorId, "vehicle.motorized.motorConfigurations.motorConfiguration", "vehicle.motorized", "motor")
	local v228_ = self.spec_motorized
	local v229_ = xmlFile:getValue(v227_ .. "#name", nil, self.customEnvironment, false)
	local v230_ = xmlFile:getValue(v227_ .. "#params")
	if v229_ ~= nil and v230_ ~= nil then
		v229_ = g_i18n:insertTextParams(v229_, v230_, self.customEnvironment, xmlFile)
	end
	v228_.vehicleName = xmlFile:getValue(v227_ .. "#vehicleName", v229_, self.customEnvironment, false)
	v228_.motorType = ConfigurationUtil.getConfigurationValue(xmlFile, v227_, ".motor", "#type", "vehicle", "vehicle.motorized.motorConfigurations.motorConfiguration(0)")
	v228_.motorStartAnimation = ConfigurationUtil.getConfigurationValue(xmlFile, v227_, ".motor", "#startAnimationName", "vehicle", "vehicle.motorized.motorConfigurations.motorConfiguration(0)")
	v228_.consumerConfigurationIndex = ConfigurationUtil.getConfigurationValue(xmlFile, v227_, "#consumerConfigurationIndex", "", 1, "vehicle.motorized.motorConfigurations.motorConfiguration(0)")
	local v231_ = ConfigurationUtil.getConfigurationValue(xmlFile, v227_, ".motor", "#minRpm", 1000, "vehicle.motorized.motorConfigurations.motorConfiguration(0)")
	local v232_ = ConfigurationUtil.getConfigurationValue(xmlFile, v227_, ".motor", "#maxRpm", 1800, "vehicle.motorized.motorConfigurations.motorConfiguration(0)")
	local v233_ = ConfigurationUtil.getConfigurationValue(xmlFile, v227_, ".motor", "#minSpeed", 1, "vehicle.motorized.motorConfigurations.motorConfiguration(0)")
	local v234_ = ConfigurationUtil.getConfigurationValue(xmlFile, v227_, ".motor", "#maxForwardSpeed", nil, "vehicle.motorized.motorConfigurations.motorConfiguration(0)")
	local v235_ = ConfigurationUtil.getConfigurationValue(xmlFile, v227_, ".motor", "#maxBackwardSpeed", nil, "vehicle.motorized.motorConfigurations.motorConfiguration(0)")
	if v234_ ~= nil then
		v234_ = v234_ / 3.6
	end
	if v235_ ~= nil then
		v235_ = v235_ / 3.6
	end
	local v236_ = self.spec_wheels
	if v236_ ~= nil and (v236_.configItem ~= nil and v236_.configItem.maxForwardSpeed ~= nil) then
		v234_ = v236_.configItem.maxForwardSpeed / 3.6
	end
	local v237_ = ConfigurationUtil.getConfigurationValue(xmlFile, v227_, ".motor", "#accelerationLimit", 2, "vehicle.motorized.motorConfigurations.motorConfiguration(0)")
	local v238_ = ConfigurationUtil.getConfigurationValue(xmlFile, v227_, ".motor", "#brakeForce", 10, "vehicle.motorized.motorConfigurations.motorConfiguration(0)") * 2
	local v239_ = ConfigurationUtil.getConfigurationValue(xmlFile, v227_, ".motor", "#lowBrakeForceScale", 0.5, "vehicle.motorized.motorConfigurations.motorConfiguration(0)")
	local v240_ = ConfigurationUtil.getConfigurationValue(xmlFile, v227_, ".motor", "#lowBrakeForceSpeedLimit", 1, "vehicle.motorized.motorConfigurations.motorConfiguration(0)") / 3600
	local v241_ = ConfigurationUtil.getConfigurationValue(xmlFile, v227_, ".motor", "#torqueScale", 1, "vehicle.motorized.motorConfigurations.motorConfiguration(0)")
	local v242_ = ConfigurationUtil.getConfigurationValue(xmlFile, v227_, ".motor", "#ptoMotorRpmRatio", 4, "vehicle.motorized.motorConfigurations.motorConfiguration(0)")
	local v243_ = v227_ .. ".transmission"
	local v244_ = not xmlFile:hasProperty(v243_) and "vehicle.motorized.motorConfigurations.motorConfiguration(0).transmission" or v243_
	local v245_ = xmlFile:getValue(v244_ .. "#minForwardGearRatio")
	local v246_ = xmlFile:getValue(v244_ .. "#maxForwardGearRatio")
	local v247_ = xmlFile:getValue(v244_ .. "#minBackwardGearRatio")
	local v248_ = xmlFile:getValue(v244_ .. "#maxBackwardGearRatio")
	local v249_ = xmlFile:getValue(v244_ .. "#gearChangeTime")
	local v250_ = xmlFile:getValue(v244_ .. "#autoGearChangeTime")
	local v251_ = xmlFile:getValue(v244_ .. "#axleRatio", 1)
	local v252_ = xmlFile:getValue(v244_ .. "#startGearThreshold", VehicleMotor.GEAR_START_THRESHOLD)
	local v253_, v254_
	if v246_ == nil or v245_ == nil then
		v253_ = nil
		v254_ = nil
	else
		v253_ = v245_ * v251_
		v254_ = v246_ * v251_
	end
	local v255_, v256_
	if v247_ == nil or v248_ == nil then
		v255_ = nil
		v256_ = nil
	else
		v256_ = v247_ * v251_
		v255_ = v248_ * v251_
	end
	local v257_
	if v253_ == nil then
		v257_ = self:loadGears(xmlFile, "forwardGear", v244_, v232_, v251_, 1)
		if v257_ == nil then
			printWarning("Warning: Missing forward gear ratios for motor in \'" .. self.configFileName .. "\'!")
			v257_ = {
				{
					["ratio"] = 1,
					["default"] = false
				}
			}
		end
	else
		v257_ = nil
	end
	local v258_
	if v256_ == nil then
		v258_ = self:loadGears(xmlFile, "backwardGear", v244_, v232_, v251_, -1)
	else
		v258_ = nil
	end
	local v259_ = self:loadGearGroups(xmlFile, v244_ .. ".groups", v232_, v251_)
	local v260_ = xmlFile:getValue(v244_ .. ".groups#type", "default")
	local v261_ = xmlFile:getValue(v244_ .. ".groups#changeTime", 0.5)
	local v262_ = xmlFile:getValue(v244_ .. ".directionChange#useGear", false)
	local v263_ = xmlFile:getValue(v244_ .. ".directionChange#reverseGearIndex", 1)
	local v264_ = xmlFile:getValue(v244_ .. ".directionChange#useGroup", false)
	local v265_ = xmlFile:getValue(v244_ .. ".directionChange#reverseGroupIndex", 1)
	local v266_ = xmlFile:getValue(v244_ .. ".directionChange#changeTime", 0.5)
	local v267_ = xmlFile:getValue(v244_ .. ".manualShift#gears", true)
	local v268_ = xmlFile:getValue(v244_ .. ".manualShift#groups", true)
	local v269_ = AnimCurve.new(linearInterpolator1)
	local v270_ = 0
	local v271_
	if v227_ == nil or not xmlFile:hasProperty(v227_ .. ".motor.torque(0)") then
		v271_ = "vehicle.motorized.motorConfigurations.motorConfiguration(0).motor.torque"
	else
		v271_ = v227_ .. ".motor.torque"
	end
	while true do
		local v272_ = string.format(v271_ .. "(%d)", v270_)
		local v273_ = xmlFile:getValue(v272_ .. "#normRpm")
		local v274_
		if v273_ == nil then
			v274_ = xmlFile:getValue(v272_ .. "#rpm")
		else
			v274_ = v273_ * v232_
		end
		local v275_ = xmlFile:getValue(v272_ .. "#torque")
		if v275_ == nil or v274_ == nil then
			v228_.motor = VehicleMotor.new(self, v231_, v232_, v234_, v235_, v269_, v238_, v257_, v258_, v253_, v254_, v256_, v255_, v242_, v233_)
			v228_.motor:setGearGroups(v259_, v260_, v261_)
			v228_.motor:setDirectionChange(v262_, v263_, v264_, v265_, v266_)
			v228_.motor:setManualShift(v267_, v268_)
			v228_.motor:setStartGearThreshold(v252_)
			local v276_ = ConfigurationUtil.getConfigurationValue(xmlFile, v227_, ".motor", "#rotInertia", v228_.motor:getRotInertia(), "vehicle.motorized.motorConfigurations.motorConfiguration(0)")
			local v277_ = ConfigurationUtil.getConfigurationValue(xmlFile, v227_, ".motor", "#dampingRateScale", 1, "vehicle.motorized.motorConfigurations.motorConfiguration(0)")
			v228_.motor:setRotInertia(v276_)
			v228_.motor:setDampingRateScale(v277_)
			v228_.motor:setLowBrakeForce(v239_, v240_)
			v228_.motor:setAccelerationLimit(v237_)
			local v278_ = ConfigurationUtil.getConfigurationValue(xmlFile, v227_, ".motor", "#rpmSpeedLimit", nil, "vehicle.motorized.motorConfigurations.motorConfiguration(0)")
			if v278_ ~= nil then
				local v279_ = v278_ * 3.141592653589793 / 30
				v228_.motor:setMotorRotationAccelerationLimit(v279_)
			end
			if v249_ ~= nil then
				v228_.motor:setGearChangeTime(v249_)
			end
			if v250_ ~= nil then
				v228_.motor:setAutoGearChangeTime(v250_)
			end
			return
		end
		v269_:addKeyframe({
			v275_ * v241_,
			["time"] = v274_
		})
		v270_ = v270_ + 1
	end
end
function Motorized.sortGears(p280_, p281_)
	if p280_.ratio < 0 and p281_.ratio >= 0 then
		return true
	elseif p280_.ratio >= 0 and p281_.ratio < 0 then
		return false
	else
		return p280_.ratio > p281_.ratio
	end
end

-- Local values: gears, gearI, gearKey, gearRatio, maxSpeed, gearEntry, j, gearEntry
function Motorized:loadGears(xmlFile, gearName, key, motorMaxRpm, axleRatio, direction)
	local v288_ = 0
	local v289_ = {}
	while true do
		local v290_ = string.format(key .. ".%s(%d)", gearName, v288_)
		if not xmlFile:hasProperty(v290_) then
			break
		end
		local v291_ = xmlFile:getValue(v290_ .. "#gearRatio")
		local v292_ = xmlFile:getValue(v290_ .. "#maxSpeed")
		if v292_ ~= nil then
			v291_ = motorMaxRpm * 3.141592653589793 / (v292_ / 3.6 * 30)
		end
		if v291_ ~= nil then
			local v293_ = {
				["ratio"] = v291_ * axleRatio,
				["default"] = xmlFile:getValue(v290_ .. "#defaultGear", false)
			}
			local v294_ = v290_ .. "#name"
			local v295_ = (v288_ + 1) * direction
			v293_.name = xmlFile:getValue(v294_, (tostring(v295_)))
			local v296_ = v290_ .. "#reverseName"
			local v297_ = (v288_ + 1) * direction * -1
			v293_.reverseName = xmlFile:getValue(v296_, (tostring(v297_)))
			v293_.dashboardName = xmlFile:getValue(v290_ .. "#dashboardName")
			v293_.dashboardReverseName = xmlFile:getValue(v290_ .. "#dashboardReverseName")
			v293_.actionName = xmlFile:getValue(v290_ .. "#actionName")
			if (v288_ < 8 or v293_.actionName ~= nil) and v293_.actionName ~= "-" then
				v293_.actionName = v293_.actionName or string.format("SHIFT_GEAR_SELECT_%d", v288_ + 1)
				v293_.inputAction = InputAction[v293_.actionName]
				if v293_.inputAction == nil then
					Logging.xmlWarning(xmlFile, "Invalid actionName \'%s\' found for gear \'%s\'", v293_.actionName, v290_)
					v293_.inputAction = InputAction[string.format("SHIFT_GEAR_SELECT_%d", v288_ + 1)]
				end
			end
			table.insert(v289_, v293_)
		end
		v288_ = v288_ + 1
	end
	if #v289_ <= 0 then
		return nil
	end
	if #v289_ > 8 then
		for v298_, v299_ in pairs(v289_) do
			if v299_.actionName == nil then
				Logging.xmlDevWarning(xmlFile, "More than 8 gears defined, but manual assignment of actionName missing for gear %d. (Use \'-\' to skip a gear)", v298_)
			end
		end
	end
	table.sort(v289_, Motorized.sortGears)
	return v289_
end

-- Local values: groups, i, groupKey, ratio, groupEntry, j, groupEntry
function Motorized:loadGearGroups(xmlFile, key, motorMaxRpm, axleRatio)
	local v302_ = 0
	local v303_ = {}
	while true do
		local v304_ = string.format(key .. ".group(%d)", v302_)
		if not xmlFile:hasProperty(v304_) then
			break
		end
		local v305_ = xmlFile:getValue(v304_ .. "#ratio")
		if v305_ ~= nil then
			local v306_ = {
				["ratio"] = 1 / v305_,
				["isDefault"] = xmlFile:getValue(v304_ .. "#isDefault", false)
			}
			local v307_ = v304_ .. "#name"
			local v308_ = v302_ + 1
			v306_.name = xmlFile:getValue(v307_, (tostring(v308_)))
			v306_.dashboardName = xmlFile:getValue(v304_ .. "#dashboardName")
			v306_.actionName = xmlFile:getValue(v304_ .. "#actionName")
			if (v302_ < 4 or v306_.actionName ~= nil) and v306_.actionName ~= "-" then
				v306_.actionName = v306_.actionName or string.format("SHIFT_GROUP_SELECT_%d", v302_ + 1)
				v306_.inputAction = InputAction[v306_.actionName]
				if v306_.inputAction == nil then
					Logging.xmlWarning(xmlFile, "Invalid actionName \'%s\' found for gear group \'%s\'", v306_.actionName, v304_)
					v306_.inputAction = InputAction[string.format("SHIFT_GROUP_SELECT_%d", v302_ + 1)]
				end
			end
			table.insert(v303_, v306_)
		end
		v302_ = v302_ + 1
	end
	if #v303_ <= 0 then
		return nil
	end
	if #v303_ > 4 then
		for v309_, v310_ in pairs(v303_) do
			if v310_.actionName == nil then
				Logging.xmlDevWarning(xmlFile, "More than 4 gear groups defined, but manual assignment of actionName missing for gearGroup %d. (Use \'-\' to skip a group)", v309_)
			end
		end
	end
	table.sort(v303_, Motorized.sortGears)
	return v303_
end

-- Local values: spec, minScale, maxScale, i, baseKey, particleSystem, _, key, exhaustFlap
function Motorized:loadExhaustEffects(xmlFile)
	local v_u_313_ = self.spec_motorized
	local v314_ = xmlFile:getValue("vehicle.motorized.exhaustParticleSystems#minScale", 0.5)
	local v315_ = xmlFile:getValue("vehicle.motorized.exhaustParticleSystems#maxScale", 1)
	v_u_313_.exhaustParticleSystems = {}
	local v316_ = 0
	while true do
		local v317_ = string.format("vehicle.motorized.exhaustParticleSystems.exhaustParticleSystem(%d)", v316_)
		if not xmlFile:hasProperty(v317_) then
			break
		end
		local v318_ = {}
		ParticleUtil.loadParticleSystem(xmlFile, v318_, v317_, self.components, false, nil, self.baseDirectory)
		v318_.minScale = v314_
		v318_.maxScale = v315_
		local v319_ = v_u_313_.exhaustParticleSystems
		table.insert(v319_, v318_)
		v316_ = v316_ + 1
	end
	if #v_u_313_.exhaustParticleSystems == 0 then
		v_u_313_.exhaustParticleSystems = nil
	end
	XMLUtil.checkDeprecatedXMLElements(xmlFile, "vehicle.motorized.exhaustFlap#index", "vehicle.motorized.exhaustFlap#node")
	v_u_313_.exhaustFlaps = {}
	for _, v320_ in self.xmlFile:iterator("vehicle.motorized.exhaustFlap") do
		local v321_ = {
			["node"] = xmlFile:getValue(v320_ .. "#node", nil, self.components, self.i3dMappings)
		}
		if v321_.node ~= nil then
			v321_.maxRot = xmlFile:getValue(v320_ .. "#maxRot", 0)
			v321_.rotationAxis = xmlFile:getValue(v320_ .. "#rotationAxis", 1)
			local v322_ = v_u_313_.exhaustFlaps
			table.insert(v322_, v321_)
		end
	end
	v_u_313_.exhaustEffects = {}
	v_u_313_.sharedLoadRequestIds = {}
	xmlFile:iterate("vehicle.motorized.exhaustEffects.exhaustEffect", function(_, p323_)
		-- upvalues: (copy) xmlFile, (copy) self, (copy) v_u_313_
		XMLUtil.checkDeprecatedXMLElements(xmlFile, p323_ .. "#index", p323_ .. "#node")
		local v324_ = xmlFile:getValue(p323_ .. "#node", nil, self.components, self.i3dMappings)
		local v325_ = xmlFile:getValue(p323_ .. "#filename")
		if v325_ ~= nil and v324_ ~= nil then
			local v326_ = Utils.getFilename(v325_, self.baseDirectory)
			local v327_ = {
				["xmlFile"] = xmlFile,
				["key"] = p323_,
				["linkNode"] = v324_,
				["filename"] = v326_
			}
			local v328_ = self:loadSubSharedI3DFile(v326_, false, false, self.onExhaustEffectI3DLoaded, self, v327_)
			local v329_ = v_u_313_.sharedLoadRequestIds
			table.insert(v329_, v328_)
		end
	end)
	v_u_313_.exhaustEffectMaxSteeringSpeed = 0.001
	v_u_313_.effects = g_effectManager:loadEffect(xmlFile, "vehicle.motorized.effects", self.components, self, self.i3dMappings)
	g_effectManager:setEffectTypeInfo(v_u_313_.effects, FillType.UNKNOWN)
end

-- Local values: spec, node, xmlFile, key, effect
function Motorized:onExhaustEffectI3DLoaded(i3dNode, failedReason, args)
	local v333_ = self.spec_motorized
	if i3dNode ~= 0 then
		local v334_ = getChildAt(i3dNode, 0)
		if getHasShaderParameter(v334_, "param") then
			local v335_ = args.xmlFile
			local v336_ = args.key
			local v337_ = {
				["effectNode"] = v334_,
				["node"] = args.linkNode,
				["filename"] = args.filename
			}
			link(v337_.node, v337_.effectNode)
			setVisibility(v337_.effectNode, false)
			delete(i3dNode)
			v337_.minRpmColor = v335_:getValue(v336_ .. "#minRpmColor", "0 0 0 1", true)
			v337_.maxRpmColor = v335_:getValue(v336_ .. "#maxRpmColor", "0.0384 0.0359 0.0627 2.0", true)
			v337_.minRpmScale = v335_:getValue(v336_ .. "#minRpmScale", 0.25)
			v337_.maxRpmScale = v335_:getValue(v336_ .. "#maxRpmScale", 0.95)
			v337_.upFactor = v335_:getValue(v336_ .. "#upFactor", 0.75)
			v337_.lastPosition = nil
			v337_.xRot = 0
			v337_.zRot = 0
			local v338_ = v333_.exhaustEffects
			table.insert(v338_, v337_)
		end
	end
end

-- Local values: spec
function Motorized:loadSounds(xmlFile, baseString)
	if self.isClient then
		local v342_ = self.spec_motorized
		v342_.samples = v342_.samples or {}
		v342_.samples.motorStart = g_soundManager:loadSampleFromXML(xmlFile, baseString, "motorStart", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or v342_.samples.motorStart
		v342_.samples.motorStop = g_soundManager:loadSampleFromXML(xmlFile, baseString, "motorStop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or v342_.samples.motorStop
		v342_.samples.clutchCracking = g_soundManager:loadSampleFromXML(xmlFile, baseString, "clutchCracking", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self) or v342_.samples.clutchCracking
		v342_.samples.gearEngaged = g_soundManager:loadSampleFromXML(xmlFile, baseString, "gearEngaged", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or v342_.samples.gearEngaged
		v342_.samples.gearDisengaged = g_soundManager:loadSampleFromXML(xmlFile, baseString, "gearDisengaged", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or v342_.samples.gearDisengaged
		v342_.samples.gearGroupChange = g_soundManager:loadSampleFromXML(xmlFile, baseString, "gearGroupChange", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or v342_.samples.gearGroupChange
		v342_.samples.gearLeverStart = g_soundManager:loadSampleFromXML(xmlFile, baseString, "gearLeverStart", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or v342_.samples.gearLeverStart
		v342_.samples.gearLeverEnd = g_soundManager:loadSampleFromXML(xmlFile, baseString, "gearLeverEnd", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or v342_.samples.gearLeverEnd
		v342_.samples.gearGroupLeverStart = g_soundManager:loadSampleFromXML(xmlFile, baseString, "gearGroupLeverStart", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or v342_.samples.gearGroupLeverStart
		v342_.samples.gearGroupLeverEnd = g_soundManager:loadSampleFromXML(xmlFile, baseString, "gearGroupLeverEnd", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or v342_.samples.gearGroupLeverEnd
		v342_.samples.gearRangeChange = g_soundManager:loadSampleFromXML(xmlFile, baseString, "gearRangeChange", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or v342_.samples.gearRangeChange
		v342_.samples.blowOffValve = g_soundManager:loadSampleFromXML(xmlFile, baseString, "blowOffValve", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or v342_.samples.blowOffValve
		v342_.samples.retarder = g_soundManager:loadSampleFromXML(xmlFile, baseString, "retarder", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self) or v342_.samples.retarder
		v342_.gearboxSamples = g_soundManager:loadSamplesFromXML(xmlFile, baseString, "gearbox", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self, v342_.gearboxSamples)
		v342_.motorSamples = g_soundManager:loadSamplesFromXML(xmlFile, baseString, "motor", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self, v342_.motorSamples)
		v342_.samples.airCompressorStart = g_soundManager:loadSampleFromXML(xmlFile, baseString, "airCompressorStart", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or v342_.samples.airCompressorStart
		v342_.samples.airCompressorStop = g_soundManager:loadSampleFromXML(xmlFile, baseString, "airCompressorStop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or v342_.samples.airCompressorStop
		v342_.samples.airCompressorRun = g_soundManager:loadSampleFromXML(xmlFile, baseString, "airCompressorRun", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self) or v342_.samples.airCompressorRun
		v342_.samples.compressedAir = g_soundManager:loadSampleFromXML(xmlFile, baseString, "compressedAir", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or v342_.samples.compressedAir
		if v342_.samples.compressedAir ~= nil then
			v342_.samples.compressedAir.brakeTime = 0
			v342_.samples.compressedAir.lastBrakeTime = 0
		end
		v342_.samples.airRelease = g_soundManager:loadSampleFromXML(xmlFile, baseString, "airRelease", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or v342_.samples.airRelease
		v342_.samples.reverseDrive = g_soundManager:loadSampleFromXML(xmlFile, baseString, "reverseDrive", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self) or v342_.samples.reverseDrive
		v342_.reverseDriveThreshold = xmlFile:getValue("vehicle.motorized.reverseDriveSound#threshold", 4)
		v342_.brakeCompressor = {}
		v342_.brakeCompressor.capacity = xmlFile:getValue("vehicle.motorized.brakeCompressor#capacity", 6)
		local v343_ = v342_.brakeCompressor
		local v344_ = v342_.brakeCompressor.capacity
		local v345_ = v342_.brakeCompressor.capacity / 2
		v343_.refillFilllevel = math.min(v344_, xmlFile:getValue("vehicle.motorized.brakeCompressor#refillFillLevel", v345_))
		v342_.brakeCompressor.fillSpeed = xmlFile:getValue("vehicle.motorized.brakeCompressor#fillSpeed", 0.6) / 1000
		v342_.brakeCompressor.fillLevel = 0
		v342_.brakeCompressor.doFill = true
		v342_.isBrakeSamplePlaying = false
		v342_.samples.brake = g_soundManager:loadSampleFromXML(xmlFile, baseString, "brake", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self) or v342_.samples.brake
		v342_.compressionSoundTime = 0
	end
end

-- Local values: key, spec, fallbackConfigKey, i, consumerKey, consumer, fillTypeName, fillUnit, usage
function Motorized:loadConsumerConfiguration(xmlFile, consumerIndex)
	local v349_ = string.format("vehicle.motorized.consumerConfigurations.consumerConfiguration(%d)", consumerIndex - 1)
	local v350_ = self.spec_motorized
	v350_.consumersEmptyWarning = self.xmlFile:getValue(v349_ .. "#consumersEmptyWarning", "warning_motorFuelEmpty", self.customEnvironment)
	v350_.consumers = {}
	v350_.consumersByFillTypeName = {}
	v350_.consumersByFillType = {}
	if xmlFile:hasProperty(v349_) then
		local v351_ = 0
		while true do
			local v352_ = string.format(".consumer(%d)", v351_)
			if not xmlFile:hasProperty(v349_ .. v352_) then
				break
			end
			local v353_ = {
				["fillUnitIndex"] = ConfigurationUtil.getConfigurationValue(xmlFile, v349_, v352_, "#fillUnitIndex", 1, "vehicle.motorized.consumers")
			}
			local v354_ = ConfigurationUtil.getConfigurationValue(xmlFile, v349_, v352_, "#fillType", "consumer", "vehicle.motorized.consumers")
			v353_.fillType = g_fillTypeManager:getFillTypeIndexByName(v354_)
			v353_.capacity = ConfigurationUtil.getConfigurationValue(xmlFile, v349_, v352_, "#capacity", nil, "vehicle.motorized.consumers")
			local v355_ = self:getFillUnitByIndex(v353_.fillUnitIndex)
			if v355_ == nil then
				Logging.xmlWarning(self.xmlFile, "Unknown fillUnit \'%d\' for consumer \'%s\'", v353_.fillUnitIndex, v349_ .. v352_)
			else
				if v355_.supportedFillTypes[v353_.fillType] == nil then
					v355_.supportedFillTypes = {}
					v355_.supportedFillTypes[v353_.fillType] = true
				end
				v355_.capacity = v353_.capacity or v355_.capacity
				if (v353_.fillType == FillType.DIESEL or (v353_.fillType == FillType.ELECTRICCHARGE or v353_.fillType == FillType.METHANE)) and v355_.exactFillRootNode == nil then
					Logging.xmlWarning(self.xmlFile, "Missing exactFillRootNode for fuel fill unit (%d).", v353_.fillUnitIndex)
				end
				v355_.startFillLevel = v355_.capacity
				v355_.startFillTypeIndex = v353_.fillType
				v355_.ignoreFillLimit = true
				local v356_ = ConfigurationUtil.getConfigurationValue(xmlFile, v349_, v352_, "#usage", 1, "vehicle.motorized.consumers")
				v353_.permanentConsumption = ConfigurationUtil.getConfigurationValue(xmlFile, v349_, v352_, "#permanentConsumption", true, "vehicle.motorized.consumers")
				if v353_.permanentConsumption then
					v353_.usage = v356_ / 3600000
				else
					v353_.usage = v356_
				end
				v353_.refillLitersPerSecond = ConfigurationUtil.getConfigurationValue(xmlFile, v349_, v352_, "#refillLitersPerSecond", 0, "vehicle.motorized.consumers")
				v353_.refillCapacityPercentage = ConfigurationUtil.getConfigurationValue(xmlFile, v349_, v352_, "#refillCapacityPercentage", 0, "vehicle.motorized.consumers")
				v353_.fillLevelToChange = 0
				local v357_ = v350_.consumers
				table.insert(v357_, v353_)
				v350_.consumersByFillTypeName[string.upper(v354_)] = v353_
				v350_.consumersByFillType[v353_.fillType] = v353_
			end
			v351_ = v351_ + 1
		end
	end
end

function Motorized:getIsMotorStarted()
	return self.spec_motorized.motorState == MotorState.ON
end

function Motorized:getIsMotorInNeutral()
	return self.spec_motorized.motor:getIsInNeutral()
end

function Motorized:getMotorState()
	return self.spec_motorized.motorState
end

-- Local values: spec, _, fillUnitIndex
function Motorized:getCanMotorRun()
	local v362_ = self.spec_motorized
	for _, v363_ in ipairs(v362_.propellantFillUnitIndices) do
		if self:getFillUnitFillLevel(v363_) == 0 then
			return false
		end
	end
	return v362_.motor:getCanMotorRun() and true or false
end

function Motorized:getStopMotorOnLeave()
	local v365_ = self.spec_motorized.stopMotorOnLeave
	if v365_ then
		v365_ = not self:getRequiresPower()
	end
	return v365_
end

-- Local values: spec, _, fillUnit, canMotorRun, reason
function Motorized:getMotorNotAllowedWarning()
	local v367_ = self.spec_motorized
	for _, v368_ in pairs(v367_.propellantFillUnitIndices) do
		if self:getFillUnitFillLevel(v368_) == 0 then
			return v367_.consumersEmptyWarning
		end
	end
	local v369_, v370_ = v367_.motor:getCanMotorRun()
	if v369_ or v370_ ~= VehicleMotor.REASON_CLUTCH_NOT_ENGAGED then
		return nil
	else
		return v367_.clutchNoEngagedWarning
	end
end

-- Local values: spec, lastMotorState, startMotor, stopMotor, _, ps, _, effect, color, _, ps, _, effect, _, exhaustFlap
function Motorized:setMotorState(motorState, noEventSend)
	local v374_ = self.spec_motorized
	if v374_.motorState ~= motorState then
		MotorStateEvent.sendEvent(self, motorState, noEventSend)
		local v375_ = v374_.motorState
		v374_.motorState = motorState
		local v376_ = false
		local v377_ = false
		if v375_ == MotorState.OFF or v375_ == MotorState.IGNITION then
			if motorState == MotorState.STARTING or motorState == MotorState.ON then
				v376_ = true
			end
		elseif v375_ == MotorState.STARTING or v375_ == MotorState.ON then
			if motorState == MotorState.OFF or motorState == MotorState.IGNITION then
				v377_ = true
			end
		end
		if g_ignitionLockManager:getIsAvailable() then
			if motorState == MotorState.IGNITION then
				v374_.motorStateIgnitionTime = g_currentMission.time
			elseif motorState == MotorState.OFF then
				v374_.motorStateIgnitionTime = 0
			elseif (motorState == MotorState.STARTING or motorState == MotorState.ON) and v374_.motorStateIgnitionTime == 0 then
				v374_.motorStateIgnitionTime = g_currentMission.time
			end
		elseif (motorState == MotorState.STARTING or motorState == MotorState.ON) and v374_.motorStateIgnitionTime == 0 then
			v374_.motorStateIgnitionTime = g_currentMission.time
		elseif motorState == MotorState.OFF then
			v374_.motorStateIgnitionTime = 0
		end
		if v376_ then
			if self.isClient then
				if v374_.exhaustParticleSystems ~= nil then
					for _, v378_ in pairs(v374_.exhaustParticleSystems) do
						ParticleUtil.setEmittingState(v378_, true)
					end
				end
				if v374_.exhaustEffects ~= nil then
					for _, v379_ in pairs(v374_.exhaustEffects) do
						setVisibility(v379_.effectNode, true)
						setShaderParameter(v379_.effectNode, "param", v379_.xRot, v379_.zRot, 0, 0, false)
						local v380_ = v379_.minRpmColor
						setShaderParameter(v379_.effectNode, "exhaustColor", v380_[1], v380_[2], v380_[3], v380_[4], false)
					end
				end
				if v374_.samples == nil then
					Logging.error("Motor samples not found (%s, %d)", self.configFileName, self.loadingState)
					printCallstack()
				end
				g_soundManager:stopSample(v374_.samples.motorStop)
				g_soundManager:playSample(v374_.samples.motorStart)
				g_soundManager:playSamples(v374_.motorSamples, 0, v374_.samples.motorStart)
				g_soundManager:playSamples(v374_.gearboxSamples, 0, v374_.samples.motorStart)
				g_soundManager:playSample(v374_.samples.retarder, 0, v374_.samples.motorStart)
				g_animationManager:startAnimations(v374_.animationNodes)
				if v374_.motorStartAnimation ~= nil then
					self:playAnimation(v374_.motorStartAnimation, 1, nil, true)
				end
				g_effectManager:startEffects(v374_.effects)
			end
			v374_.motorStartTime = g_currentMission.time + v374_.motorStartDuration
			v374_.motorNotRequiredTimer = 0
			v374_.compressionSoundTime = g_currentMission.time + math.random(5000, 20000)
			v374_.motor.lastMotorRpm = 0
			SpecializationUtil.raiseEvent(self, "onStartMotor")
			self.rootVehicle:raiseStateChange(VehicleStateChange.MOTOR_TURN_ON)
		elseif v377_ then
			if self.isClient then
				if v374_.exhaustParticleSystems ~= nil then
					for _, v381_ in pairs(v374_.exhaustParticleSystems) do
						ParticleUtil.setEmittingState(v381_, false)
					end
				end
				if v374_.exhaustEffects ~= nil then
					for _, v382_ in pairs(v374_.exhaustEffects) do
						setVisibility(v382_.effectNode, false)
					end
				end
				for _, v383_ in ipairs(v374_.exhaustFlaps) do
					setRotation(v383_.node, 0, 0, 0)
				end
				g_soundManager:stopSamples(v374_.samples)
				g_soundManager:playSample(v374_.samples.motorStop)
				g_soundManager:stopSamples(v374_.motorSamples)
				g_soundManager:stopSamples(v374_.gearboxSamples)
				v374_.isBrakeSamplePlaying = false
				g_animationManager:stopAnimations(v374_.animationNodes)
				if v374_.motorStartAnimation ~= nil then
					self:playAnimation(v374_.motorStartAnimation, -1, nil, true)
				end
				g_effectManager:stopEffects(v374_.effects)
			end
			SpecializationUtil.raiseEvent(self, "onStopMotor")
			self.rootVehicle:raiseStateChange(VehicleStateChange.MOTOR_TURN_OFF)
		end
	end
	if motorState == MotorState.ON or motorState == MotorState.STARTING then
		if self.isServer then
			self:wakeUp()
		end
	else
		v374_.motor.lastMotorRpm = 0
	end
	if self.setDashboardsDirty ~= nil then
		self:setDashboardsDirty()
	end
end

-- Local values: motorState
function Motorized:startMotor(noEventSend)
	local v386_ = self:getMotorState()
	if v386_ == MotorState.OFF or v386_ == MotorState.IGNITION then
		MotorSetTurnedOnEvent.sendEvent(self, true, noEventSend)
		self:setMotorState(MotorState.STARTING, true)
	end
end

-- Local values: motorState
function Motorized:stopMotor(noEventSend)
	local v389_ = self:getMotorState()
	if v389_ == MotorState.ON or v389_ == MotorState.STARTING then
		MotorSetTurnedOnEvent.sendEvent(self, false, noEventSend)
		self:setMotorState(MotorState.OFF, true)
	end
end

-- Local values: spec, idleFactor, rpmPercentage, rpmFactor, loadFactor, motorFactor, missionInfo, fuelUsage, usageFactor, damage, _, consumer, used, fillType, price, consumer, fillType, usage, direction, forwardBrake, backwardBrake, brakeIsPressed, delta, fillLevelPercentage, delta
function Motorized:updateConsumers(dt, accInput)
	local v393_ = self.spec_motorized
	local v394_ = (v393_.motor.lastMotorRpm - v393_.motor.minRpm) / (v393_.motor.maxRpm - v393_.motor.minRpm)
	local v395_ = 0.5 + v394_ * 0.5
	local v396_ = v393_.smoothedLoadPercentage * v394_
	local v397_ = math.max(v396_, 0)
	local v398_ = 0.5 * (0.2 * v395_ + 1.8 * v397_)
	local v399_ = g_currentMission.missionInfo
	local v400_ = v399_.fuelUsage
	local v401_ = v400_ == 1 and 1 or (v400_ == 3 and 2.5 or 1.5)
	local v402_ = self:getVehicleDamage()
	if v402_ > 0 then
		v401_ = v401_ * (1 + v402_ * Motorized.DAMAGED_USAGE_INCREASE)
	end
	for _, v403_ in pairs(v393_.consumers) do
		if v403_.permanentConsumption and v403_.usage > 0 then
			local v404_ = v401_ * v398_ * v403_.usage * dt
			if v404_ ~= 0 then
				v403_.fillLevelToChange = v403_.fillLevelToChange + v404_
				local v405_ = v403_.fillLevelToChange
				if math.abs(v405_) > 1 then
					v404_ = v403_.fillLevelToChange
					v403_.fillLevelToChange = 0
					local v406_ = self:getFillUnitLastValidFillType(v403_.fillUnitIndex)
					g_farmManager:updateFarmStats(self:getOwnerFarmId(), "fuelUsage", v404_)
					if self:getIsAIActive() and (v406_ == FillType.DIESEL or v406_ == FillType.DEF) and v399_.helperBuyFuel then
						if v406_ == FillType.DIESEL then
							local v407_ = v404_ * g_currentMission.economyManager:getCostPerLiter(v406_) * 1.5
							g_farmManager:updateFarmStats(self:getOwnerFarmId(), "expenses", v407_)
							g_currentMission:addMoney(-v407_, self:getOwnerFarmId(), MoneyType.PURCHASE_FUEL, true)
							v404_ = 0
						else
							v404_ = 0
						end
					end
					if v406_ == v403_.fillType then
						self:addFillUnitFillLevel(self:getOwnerFarmId(), v403_.fillUnitIndex, -v404_, v406_, ToolType.UNDEFINED)
					end
				end
				if v403_.fillType == FillType.DIESEL or (v403_.fillType == FillType.ELECTRICCHARGE or v403_.fillType == FillType.METHANE) then
					v393_.lastFuelUsage = v404_ / dt * 1000 * 60 * 60
				elseif v403_.fillType == FillType.DEF then
					v393_.lastDefUsage = v404_ / dt * 1000 * 60 * 60
				end
			end
		end
	end
	if v393_.consumersByFillTypeName.AIR ~= nil then
		local v408_ = v393_.consumersByFillTypeName.AIR
		if self:getFillUnitLastValidFillType(v408_.fillUnitIndex) == v408_.fillType then
			local v409_ = 0
			local v410_ = self.movingDirection * self:getReverserDirection()
			local v411_
			if v410_ > 0 then
				v411_ = accInput < 0
			else
				v411_ = false
			end
			local v412_
			if v410_ < 0 then
				v412_ = accInput > 0
			else
				v412_ = false
			end
			local v413_
			if self:getLastSpeed() > 1 then
				v413_ = v411_ or v412_
			else
				v413_ = false
			end
			if v413_ then
				local v414_ = math.abs(accInput) * dt * self:getAirConsumerUsage() / 1000
				self:addFillUnitFillLevel(self:getOwnerFarmId(), v408_.fillUnitIndex, -v414_, v408_.fillType, ToolType.UNDEFINED)
				v409_ = v414_ / dt * 1000
			end
			local v415_ = self:getFillUnitFillLevelPercentage(v408_.fillUnitIndex)
			if v415_ < v408_.refillCapacityPercentage then
				v408_.doRefill = true
			elseif v415_ == 1 then
				v408_.doRefill = false
			end
			if v408_.doRefill then
				local v416_ = v408_.refillLitersPerSecond / 1000 * dt
				self:addFillUnitFillLevel(self:getOwnerFarmId(), v408_.fillUnitIndex, v416_, v408_.fillType, ToolType.UNDEFINED)
				v409_ = -v416_ / dt * 1000
			end
			v393_.lastAirUsage = v409_
		end
	end
end

-- Local values: spec, delta, factor, speedFactor
function Motorized:updateMotorTemperature(dt)
	local v419_ = self.spec_motorized
	local v420_ = v419_.motorTemperature.heatingPerMS * dt * ((1 + 4 * v419_.actualLoadPercentage) / 5 + self:getMotorRpmPercentage())
	local v421_ = v419_.motorTemperature
	local v422_ = v419_.motorTemperature.valueMax
	local v423_ = v419_.motorTemperature.value + v420_
	v421_.value = math.min(v422_, v423_)
	local v424_ = v419_.motorTemperature.coolingByWindPerMS * dt
	local v425_ = self:getLastSpeed() / 30
	local v426_ = math.min(1, v425_)
	local v427_ = math.pow(v426_, 2)
	local v428_ = v419_.motorTemperature
	local v429_ = v419_.motorTemperature.valueMin
	local v430_ = v419_.motorTemperature.value - v427_ * v424_
	v428_.value = math.max(v429_, v430_)
	if v419_.motorTemperature.value > v419_.motorFan.enableTemperature then
		v419_.motorFan.enabled = true
	end
	if v419_.motorFan.enabled and v419_.motorTemperature.value < v419_.motorFan.disableTemperature then
		v419_.motorFan.enabled = false
	end
	if v419_.motorFan.enabled then
		local v431_ = v419_.motorFan.coolingPerMS * dt
		local v432_ = v419_.motorTemperature
		local v433_ = v419_.motorTemperature.valueMin
		local v434_ = v419_.motorTemperature.value - v431_
		v432_.value = math.max(v433_, v434_)
	end
end

function Motorized:onGearDirectionChanged(direction)
	if self.isServer then
		self:raiseDirtyFlags(self.spec_motorized.dirtyFlag)
	end
	if self.isClient and self.updateDashboardValueType ~= nil then
		self:updateDashboardValueType("motorized.gear")
		self:updateDashboardValueType("motorized.gearIndex")
	end
end

-- Local values: spec, numGears, lowRangeMax
function Motorized:onGearChanged(gear, targetGear, changeTime, previousGear)
	self:setGearLeversState(targetGear, nil, changeTime)
	local v441_ = self.spec_motorized
	if self.isClient then
		if gear == 0 then
			if not g_soundManager:getIsSamplePlaying(v441_.samples.gearDisengaged) then
				g_soundManager:playSample(v441_.samples.gearDisengaged)
			end
		else
			if not g_soundManager:getIsSamplePlaying(v441_.samples.gearEngaged) then
				g_soundManager:playSample(v441_.samples.gearEngaged)
			end
			if previousGear ~= 0 and v441_.motor.currentGears ~= nil then
				local v442_ = #v441_.motor.currentGears * 0.5
				local v443_ = math.ceil(v442_)
				if (previousGear <= v443_ and v443_ < gear or gear <= v443_ and v443_ < previousGear) and not g_soundManager:getIsSamplePlaying(v441_.samples.gearRangeChange) then
					g_soundManager:playSample(v441_.samples.gearRangeChange)
				end
			end
		end
	end
	if self.isServer then
		self:raiseDirtyFlags(v441_.dirtyFlag)
	end
	if self.isClient and self.updateDashboardValueType ~= nil then
		self:updateDashboardValueType("motorized.gear")
		self:updateDashboardValueType("motorized.gearIndex")
	end
end

-- Local values: spec
function Motorized:onGearGroupChanged(targetGroup, changeTime)
	self:setGearLeversState(nil, targetGroup, changeTime)
	local v447_ = self.spec_motorized
	if self.isClient and not g_soundManager:getIsSamplePlaying(v447_.samples.gearGroupChange) then
		g_soundManager:playSample(v447_.samples.gearGroupChange)
	end
	if self.isServer then
		self:raiseDirtyFlags(v447_.dirtyFlag)
	end
	if self.isClient and self.updateDashboardValueType ~= nil then
		self:updateDashboardValueType("motorized.gearGroup")
		self:updateDashboardValueType("motorized.gearGroupIndex")
	end
end

-- Local values: spec
function Motorized:onMotorBlowOffValveChanged(blowOffValveState)
	local v450_ = self.spec_motorized
	if blowOffValveState > 0 then
		v450_.blowOffValveState = blowOffValveState
		if not g_soundManager:getIsSamplePlaying(v450_.samples.blowOffValve) then
			g_soundManager:playSample(v450_.samples.blowOffValve)
			return
		end
	elseif g_soundManager:getIsSamplePlaying(v450_.samples.blowOffValve) then
		g_soundManager:stopSample(v450_.samples.blowOffValve)
	end
end

-- Local values: spec
function Motorized:onClutchCreaking(isEvent, groupTransmission, gearIndex, groupIndex)
	local v456_ = self.spec_motorized
	if self:getIsActiveForInput(true) then
		if groupTransmission then
			g_currentMission:showBlinkingWarning(v456_.clutchCrackingGroupWarning, 2000)
		else
			g_currentMission:showBlinkingWarning(v456_.clutchCrackingGearWarning, 2000)
		end
	end
	if not g_soundManager:getIsSamplePlaying(v456_.samples.clutchCracking) then
		g_soundManager:playSample(v456_.samples.clutchCracking)
	end
	if gearIndex ~= nil then
		self:setGearLeversState(gearIndex, nil, 500, false)
		v456_.clutchCrackingGearIndex = gearIndex
	end
	if groupIndex ~= nil then
		self:setGearLeversState(nil, groupIndex, 500, false)
		v456_.clutchCrackingGroupIndex = groupIndex
	end
	v456_.clutchCrackingTimeOut = g_time + (isEvent and 750 or 100)
	if g_server ~= nil then
		g_server:broadcastEvent(MotorClutchCreakingEvent.new(self, isEvent, groupTransmission, gearIndex, groupIndex), nil, nil, self)
	end
end

function Motorized:onReverseDirectionChanged()
	if self:getDirectionChangeMode() == VehicleMotor.DIRECTION_CHANGE_MODE_MANUAL then
		MotorGearShiftEvent.sendToServer(self, MotorGearShiftEvent.TYPE_DIRECTION_CHANGE)
	end
end

-- Local values: spec, motor
function Motorized:onVehicleSettingChanged(gameSettingId, state)
	local v461_ = self.spec_motorized
	local v462_ = v461_.motor
	if gameSettingId == GameSettings.SETTING.DIRECTION_CHANGE_MODE then
		v461_.directionChangeMode = state
		if v462_ ~= nil then
			v462_:setDirectionChangeMode(state)
			self:requestActionEventUpdate()
		end
	end
	if gameSettingId == GameSettings.SETTING.GEAR_SHIFT_MODE then
		v461_.gearShiftMode = state
		if not self:getIsAIActive() and v462_ ~= nil then
			v462_:setGearShiftMode(state)
			self:requestActionEventUpdate()
		end
	end
end

-- Local values: spec
function Motorized:onAIJobStarted(job)
	local v464_ = self.spec_motorized
	self:startMotor(true)
	if v464_.motor ~= nil then
		v464_.motor:setGearShiftMode(VehicleMotor.SHIFT_MODE_AUTOMATIC)
	end
end

-- Local values: spec
function Motorized:onAIJobFinished(job)
	if self.getIsControlled == nil or not self:getIsControlled() then
		self:stopMotor(true)
	end
	local v466_ = self.spec_motorized
	if v466_.motor ~= nil then
		v466_.motor:setGearShiftMode(v466_.gearShiftMode)
	end
end

function Motorized:getMotor()
	return self.spec_motorized.motor
end

function Motorized:getMotorStartTime()
	return self.spec_motorized.motorStartTime
end

function Motorized:getMotorType()
	return self.spec_motorized.motorType
end

-- Local values: motor
function Motorized:getMotorRpmPercentage()
	local v471_ = self.spec_motorized.motor
	return (v471_:getLastModulatedMotorRpm() - v471_:getMinRpm()) / (v471_:getMaxRpm() - v471_:getMinRpm())
end
g_soundManager:registerModifierType("MOTOR_RPM", Motorized.getMotorRpmPercentage)

function Motorized:getMotorRpmReal()
	return self.spec_motorized.motor:getLastModulatedMotorRpm()
end
g_soundManager:registerModifierType("MOTOR_RPM_REAL", Motorized.getMotorRpmReal)

function Motorized:getMotorLoadPercentage()
	return self.spec_motorized.smoothedLoadPercentage
end
g_soundManager:registerModifierType("MOTOR_LOAD", Motorized.getMotorLoadPercentage)

-- Local values: sample
function Motorized:getMotorBrakeTime()
	local v475_ = self.spec_motorized.samples.compressedAir
	return v475_ == nil and 0 or v475_.lastBrakeTime / 1000
end
g_soundManager:registerModifierType("BRAKE_TIME", Motorized.getMotorBrakeTime)

function Motorized:getMotorBlowOffValveState()
	return self.spec_motorized.blowOffValveState
end
g_soundManager:registerModifierType("BLOW_OFF_VALVE_STATE", Motorized.getMotorBlowOffValveState)

function Motorized:getMotorDifferentialSpeed()
	if self.spec_motorized == nil then
		Logging.error("Sound modifier \'DIFFERENTIAL_SPEED\' used on non motorized vehicle \'%s\'", self.configFileName)
		return 0
	else
		local v478_ = self.spec_motorized.motor.differentialRotSpeed * 3.6
		return math.abs(v478_)
	end
end
g_soundManager:registerModifierType("DIFFERENTIAL_SPEED", Motorized.getMotorDifferentialSpeed)

-- Local values: spec, consumer
function Motorized:getConsumerFillUnitIndex(fillTypeIndex)
	local v481_ = self.spec_motorized.consumersByFillType[fillTypeIndex]
	if v481_ == nil then
		return nil
	else
		return v481_.fillUnitIndex
	end
end

-- Local values: spec, consumer
function Motorized:getAirConsumerUsage()
	local v483_ = self.spec_motorized.consumersByFillTypeName.AIR
	return v483_ and v483_.usage or 0
end

-- Local values: brakeForce, motorBrakeForce, spec, mass, percentage
function Motorized:getBrakeForce(superFunc)
	local v486_ = superFunc(self)
	local v487_ = self.spec_motorized
	local v488_
	if v487_.maxBrakeForceMass > 0 then
		local v489_ = (self:getTotalMass(not v487_.maxBrakeForceMassIncludeAttachables) - self.defaultMass) / (v487_.maxBrakeForceMass - self.defaultMass)
		local v490_ = math.max(v489_, 0)
		local v491_ = math.min(v490_, 1)
		local v492_ = MathUtil.lerp(v487_.minBrakeForce, v487_.maxBrakeForce, v491_)
		v488_ = math.max(v492_, v486_)
	else
		v488_ = self.spec_motorized.motor:getBrakeForce()
	end
	return math.max(v486_, v488_)
end

function Motorized:loadDashboardGroupFromXML(superFunc, xmlFile, key, group)
	if not superFunc(self, xmlFile, key, group) then
		return false
	end
	group.isMotorStarting = xmlFile:getValue(key .. "#isMotorStarting")
	group.isMotorRunning = xmlFile:getValue(key .. "#isMotorRunning")
	group.electronicsStarting = xmlFile:getValue(key .. "#electronicsStarting", false)
	group.electronicsStartingTime = xmlFile:getValue(key .. "#electronicsStartingTime", 2)
	group.electronicsRunning = xmlFile:getValue(key .. "#electronicsRunning", false)
	return true
end

-- Local values: motorState, spec, spec
function Motorized:getIsDashboardGroupActive(superFunc, group)
	local v501_ = self:getMotorState()
	if group.isMotorRunning and (group.isMotorStarting and (v501_ ~= MotorState.STARTING and v501_ ~= MotorState.ON)) then
		return false
	end
	if group.isMotorStarting and (not group.isMotorRunning and v501_ ~= MotorState.STARTING) then
		return false
	end
	if group.isMotorRunning and (not group.isMotorStarting and v501_ ~= MotorState.ON) then
		return false
	end
	if group.electronicsStarting and group.electronicsRunning then
		if self.spec_motorized.motorStateIgnitionTime == 0 then
			return false
		end
	elseif group.electronicsStarting then
		local v502_ = self.spec_motorized
		if v502_.motorStateIgnitionTime == 0 or g_currentMission.time - v502_.motorStateIgnitionTime > group.electronicsStartingTime then
			return false
		end
	elseif group.electronicsRunning then
		local v503_ = self.spec_motorized
		if v503_.motorStateIgnitionTime == 0 or g_currentMission.time - v503_.motorStateIgnitionTime < group.electronicsStartingTime then
			return false
		end
	end
	return superFunc(self, group)
end

-- Local values: state
function Motorized:getIsActiveForInteriorLights(superFunc)
	local v506_ = self:getMotorState()
	return (v506_ == MotorState.IGNITION or (v506_ == MotorState.STARTING or v506_ == MotorState.ON)) and true or superFunc(self)
end

-- Local values: state
function Motorized:getIsActiveForWipers(superFunc)
	if self:getMotorState() == MotorState.OFF then
		return false
	else
		return superFunc(self)
	end
end

-- Local values: motorState
function Motorized:getUsageCausesDamage(superFunc)
	local v511_ = self:getMotorState()
	if v511_ == MotorState.STARTING or v511_ == MotorState.ON then
		return superFunc(self)
	else
		return false
	end
end

-- Local values: spec, _, differential, diffIndex1, diffIndex2
function Motorized:addToPhysics(superFunc)
	if not superFunc(self) then
		return false
	end
	if self.isServer then
		local v514_ = self.spec_motorized
		if v514_.motorizedNode ~= nil and next(v514_.differentials) ~= nil then
			for _, v515_ in pairs(v514_.differentials) do
				local v516_ = v515_.diffIndex1
				local v517_ = v515_.diffIndex2
				if v515_.diffIndex1IsWheel then
					v516_ = self:getWheelFromWheelIndex(v516_).physics.wheelShape
				end
				if v515_.diffIndex2IsWheel then
					v517_ = self:getWheelFromWheelIndex(v517_).physics.wheelShape
				end
				addDifferential(v514_.motorizedNode, v516_, v515_.diffIndex1IsWheel, v517_, v515_.diffIndex2IsWheel, v515_.torqueRatio, v515_.maxSpeedRatio)
			end
			self:updateMotorProperties()
			self:controlVehicle(0, 0, 0, 0, math.huge, 0, 0, 0, 0, 0)
		end
	end
	return true
end

-- Local values: spec
function Motorized:removeFromPhysics(superFunc)
	if self.isServer then
		local v520_ = self.spec_motorized
		if v520_.motorizedNode ~= nil and next(v520_.differentials) ~= nil then
			removeAllDifferentials(v520_.motorizedNode)
		end
	end
	return superFunc(self) and true or false
end

-- Local values: spec, motor, torques, rotationSpeeds
function Motorized:updateMotorProperties()
	local v522_ = self.spec_motorized
	local v523_ = v522_.motor
	local v524_, v525_ = v523_:getTorqueAndSpeedValues()
	setMotorProperties(v522_.motorizedNode, v523_:getMinRpm() * 3.141592653589793 / 30, v523_:getMaxRpm() * 3.141592653589793 / 30, v523_:getRotInertia(), v523_:getDampingRateFullThrottle(), v523_:getDampingRateZeroThrottleClutchEngaged(), v523_:getDampingRateZeroThrottleClutchDisengaged(), v525_, v524_)
end

-- Local values: spec, lastParameters
function Motorized:controlVehicle(acceleratorPedal, maxSpeed, maxAcceleration, minMotorRotSpeed, maxMotorRotSpeed, maxMotorRotAcceleration, minGearRatio, maxGearRatio, maxClutchTorque, neededPtoTorque)
	local v537_ = self.spec_motorized
	controlVehicle(v537_.motorizedNode, acceleratorPedal, maxSpeed, maxAcceleration, minMotorRotSpeed, maxMotorRotSpeed, maxMotorRotAcceleration, minGearRatio, maxGearRatio, maxClutchTorque, neededPtoTorque)
	local v538_ = v537_.lastControlParameters
	if getIsSleeping(v537_.motorizedNode) and (acceleratorPedal ~= v538_.acceleratorPedal or (maxSpeed ~= v538_.maxSpeed or (maxAcceleration ~= v538_.maxAcceleration or (minMotorRotSpeed ~= v538_.minMotorRotSpeed or (maxMotorRotSpeed ~= v538_.maxMotorRotSpeed or (maxMotorRotAcceleration ~= v538_.maxMotorRotAcceleration or (minGearRatio ~= v538_.minGearRatio or (maxGearRatio ~= v538_.maxGearRatio or (maxClutchTorque ~= v538_.maxClutchTorque or neededPtoTorque ~= v538_.neededPtoTorque))))))))) then
		I3DUtil.wakeUpObject(v537_.motorizedNode)
	end
	v538_.acceleratorPedal = acceleratorPedal
	v538_.maxSpeed = maxSpeed
	v538_.maxAcceleration = maxAcceleration
	v538_.minMotorRotSpeed = minMotorRotSpeed
	v538_.maxMotorRotSpeed = maxMotorRotSpeed
	v538_.maxMotorRotAcceleration = maxMotorRotAcceleration
	v538_.minGearRatio = minGearRatio
	v538_.maxGearRatio = maxGearRatio
	v538_.maxClutchTorque = maxClutchTorque
	v538_.neededPtoTorque = neededPtoTorque
end

-- Local values: motorState
function Motorized:getIsOperating(superFunc)
	local v541_ = self:getMotorState()
	return superFunc(self) or v541_ == MotorState.ON
end

-- Local values: missionInfo
function Motorized:getDeactivateOnLeave(superFunc)
	local v544_ = g_currentMission.missionInfo
	local v545_ = superFunc(self)
	if v545_ then
		v545_ = v544_.automaticMotorStartEnabled
	end
	return v545_
end

-- Local values: missionInfo
function Motorized:getDeactivateLightsOnLeave(superFunc)
	local v548_ = g_currentMission.missionInfo
	local v549_ = superFunc(self) and v548_.automaticMotorStartEnabled
	if v549_ then
		v549_ = not self:getRequiresPower()
	end
	return v549_
end

-- Local values: spec, _, actionEventId
function Motorized:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v552_ = self.spec_motorized
		self:clearActionEventsTable(v552_.actionEvents)
		if isActiveForInputIgnoreSelection then
			local _, v553_ = self:addActionEvent(v552_.actionEvents, InputAction.TOGGLE_MOTOR_STATE, self, Motorized.actionEventToggleMotorState, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v553_, GS_PRIO_VERY_HIGH)
			g_inputBinding:setActionEventText(v553_, v552_.turnOnText)
			local _, v554_ = self:addActionEvent(v552_.actionEvents, InputAction.MOTOR_STATE_IGNITION, self, Motorized.actionEventSetMotorStateIgnition, false, true, false, true, nil)
			g_inputBinding:setActionEventTextVisibility(v554_, false)
			local _, v555_ = self:addActionEvent(v552_.actionEvents, InputAction.MOTOR_STATE_ON, self, Motorized.actionEventSetMotorStateOn, false, true, false, true, nil)
			g_inputBinding:setActionEventTextVisibility(v555_, false)
			local _, v556_ = self:addActionEvent(v552_.actionEvents, InputAction.MOTOR_STATE_OFF, self, Motorized.actionEventSetMotorStateOff, false, true, false, true, nil)
			g_inputBinding:setActionEventTextVisibility(v556_, false)
			if (v552_.motor.minForwardGearRatio == nil or v552_.motor.minBackwardGearRatio == nil) and (self:getGearShiftMode() ~= VehicleMotor.SHIFT_MODE_AUTOMATIC or not GS_IS_CONSOLE_VERSION) then
				if v552_.motor.manualShiftGears then
					local _, v557_ = self:addActionEvent(v552_.actionEvents, InputAction.SHIFT_GEAR_UP, self, Motorized.actionEventShiftGear, false, true, false, true, nil)
					g_inputBinding:setActionEventTextVisibility(v557_, false)
					local _, v558_ = self:addActionEvent(v552_.actionEvents, InputAction.SHIFT_GEAR_DOWN, self, Motorized.actionEventShiftGear, false, true, false, true, nil)
					g_inputBinding:setActionEventTextVisibility(v558_, false)
					local _, v559_ = self:addActionEvent(v552_.actionEvents, InputAction.SHIFT_GEAR_SELECT_1, self, Motorized.actionEventSelectGear, true, true, false, true, 1)
					g_inputBinding:setActionEventTextVisibility(v559_, false)
					local _, v560_ = self:addActionEvent(v552_.actionEvents, InputAction.SHIFT_GEAR_SELECT_2, self, Motorized.actionEventSelectGear, true, true, false, true, 2)
					g_inputBinding:setActionEventTextVisibility(v560_, false)
					local _, v561_ = self:addActionEvent(v552_.actionEvents, InputAction.SHIFT_GEAR_SELECT_3, self, Motorized.actionEventSelectGear, true, true, false, true, 3)
					g_inputBinding:setActionEventTextVisibility(v561_, false)
					local _, v562_ = self:addActionEvent(v552_.actionEvents, InputAction.SHIFT_GEAR_SELECT_4, self, Motorized.actionEventSelectGear, true, true, false, true, 4)
					g_inputBinding:setActionEventTextVisibility(v562_, false)
					local _, v563_ = self:addActionEvent(v552_.actionEvents, InputAction.SHIFT_GEAR_SELECT_5, self, Motorized.actionEventSelectGear, true, true, false, true, 5)
					g_inputBinding:setActionEventTextVisibility(v563_, false)
					local _, v564_ = self:addActionEvent(v552_.actionEvents, InputAction.SHIFT_GEAR_SELECT_6, self, Motorized.actionEventSelectGear, true, true, false, true, 6)
					g_inputBinding:setActionEventTextVisibility(v564_, false)
					local _, v565_ = self:addActionEvent(v552_.actionEvents, InputAction.SHIFT_GEAR_SELECT_7, self, Motorized.actionEventSelectGear, true, true, false, true, 7)
					g_inputBinding:setActionEventTextVisibility(v565_, false)
					local _, v566_ = self:addActionEvent(v552_.actionEvents, InputAction.SHIFT_GEAR_SELECT_8, self, Motorized.actionEventSelectGear, true, true, false, true, 8)
					g_inputBinding:setActionEventTextVisibility(v566_, false)
				end
				if v552_.motor.manualShiftGroups and v552_.motor.gearGroups ~= nil then
					local _, v567_ = self:addActionEvent(v552_.actionEvents, InputAction.SHIFT_GROUP_UP, self, Motorized.actionEventShiftGroup, false, true, false, true, nil)
					g_inputBinding:setActionEventTextVisibility(v567_, false)
					local _, v568_ = self:addActionEvent(v552_.actionEvents, InputAction.SHIFT_GROUP_DOWN, self, Motorized.actionEventShiftGroup, false, true, false, true, nil)
					g_inputBinding:setActionEventTextVisibility(v568_, false)
					local _, v569_ = self:addActionEvent(v552_.actionEvents, InputAction.SHIFT_GROUP_SELECT_1, self, Motorized.actionEventSelectGroup, true, true, false, true, 1)
					g_inputBinding:setActionEventTextVisibility(v569_, false)
					local _, v570_ = self:addActionEvent(v552_.actionEvents, InputAction.SHIFT_GROUP_SELECT_2, self, Motorized.actionEventSelectGroup, true, true, false, true, 2)
					g_inputBinding:setActionEventTextVisibility(v570_, false)
					local _, v571_ = self:addActionEvent(v552_.actionEvents, InputAction.SHIFT_GROUP_SELECT_3, self, Motorized.actionEventSelectGroup, true, true, false, true, 3)
					g_inputBinding:setActionEventTextVisibility(v571_, false)
					local _, v572_ = self:addActionEvent(v552_.actionEvents, InputAction.SHIFT_GROUP_SELECT_4, self, Motorized.actionEventSelectGroup, true, true, false, true, 4)
					g_inputBinding:setActionEventTextVisibility(v572_, false)
				end
				local _, v573_ = self:addActionEvent(v552_.actionEvents, InputAction.AXIS_CLUTCH_VEHICLE, self, Motorized.actionEventClutch, false, false, true, true, nil)
				g_inputBinding:setActionEventTextVisibility(v573_, false)
			end
			if self:getDirectionChangeMode() == VehicleMotor.DIRECTION_CHANGE_MODE_MANUAL or self:getGearShiftMode() ~= VehicleMotor.SHIFT_MODE_AUTOMATIC then
				local _, v574_ = self:addActionEvent(v552_.actionEvents, InputAction.DIRECTION_CHANGE, self, Motorized.actionEventDirectionChange, false, true, false, true, nil, nil, true)
				g_inputBinding:setActionEventTextVisibility(v574_, false)
				local _, v575_ = self:addActionEvent(v552_.actionEvents, InputAction.DIRECTION_CHANGE_POS, self, Motorized.actionEventDirectionChange, false, true, false, true, nil, nil, true)
				g_inputBinding:setActionEventTextVisibility(v575_, false)
				local _, v576_ = self:addActionEvent(v552_.actionEvents, InputAction.DIRECTION_CHANGE_NEG, self, Motorized.actionEventDirectionChange, false, true, false, true, nil, nil, true)
				g_inputBinding:setActionEventTextVisibility(v576_, false)
			end
			Motorized.updateActionEvents(self)
		end
	end
end

function Motorized:actionEventShiftGear(actionName, inputValue, callbackState, isAnalog)
	if actionName == InputAction.SHIFT_GEAR_UP then
		MotorGearShiftEvent.sendToServer(self, MotorGearShiftEvent.TYPE_SHIFT_UP)
	else
		MotorGearShiftEvent.sendToServer(self, MotorGearShiftEvent.TYPE_SHIFT_DOWN)
	end
end

-- Local values: spec, gears, i, gear
function Motorized:actionEventSelectGear(actionName, inputValue, callbackState, isAnalog)
	local v583_ = self.spec_motorized.motor.currentGears
	if v583_ ~= nil then
		for v584_ = 1, #v583_ do
			if v583_[v584_].inputAction == InputAction[actionName] then
				MotorGearShiftEvent.sendToServer(self, MotorGearShiftEvent.TYPE_SELECT_GEAR, inputValue == 1 and v584_ and v584_ or 0)
				return
			end
		end
	end
	return MotorGearShiftEvent.sendToServer(self, MotorGearShiftEvent.TYPE_SELECT_GEAR, inputValue == 1 and callbackState and callbackState or 0)
end

function Motorized:actionEventShiftGroup(actionName, inputValue, callbackState, isAnalog)
	if actionName == InputAction.SHIFT_GROUP_UP then
		MotorGearShiftEvent.sendToServer(self, MotorGearShiftEvent.TYPE_SHIFT_GROUP_UP)
	else
		MotorGearShiftEvent.sendToServer(self, MotorGearShiftEvent.TYPE_SHIFT_GROUP_DOWN)
	end
end

-- Local values: spec, groups, i, group
function Motorized:actionEventSelectGroup(actionName, inputValue, callbackState, isAnalog)
	local v591_ = self.spec_motorized.motor.gearGroups
	if v591_ ~= nil then
		for v592_ = 1, #v591_ do
			if v591_[v592_].inputAction == InputAction[actionName] then
				MotorGearShiftEvent.sendToServer(self, MotorGearShiftEvent.TYPE_SELECT_GROUP, inputValue == 1 and v592_ and v592_ or 0)
				return
			end
		end
	end
	return MotorGearShiftEvent.sendToServer(self, MotorGearShiftEvent.TYPE_SELECT_GROUP, inputValue == 1 and callbackState and callbackState or 0)
end

function Motorized:actionEventDirectionChange(actionName, inputValue, callbackState, isAnalog)
	if actionName == InputAction.DIRECTION_CHANGE_POS then
		MotorGearShiftEvent.sendToServer(self, MotorGearShiftEvent.TYPE_DIRECTION_CHANGE_POS)
		return
	elseif actionName == InputAction.DIRECTION_CHANGE_NEG then
		MotorGearShiftEvent.sendToServer(self, MotorGearShiftEvent.TYPE_DIRECTION_CHANGE_NEG)
	else
		MotorGearShiftEvent.sendToServer(self, MotorGearShiftEvent.TYPE_DIRECTION_CHANGE)
	end
end

-- Local values: spec
function Motorized:actionEventClutch(actionName, inputValue, callbackState, isAnalog)
	local v597_ = self.spec_motorized
	v597_.clutchState = inputValue
	if self.isServer then
		v597_.motor:onManualClutchChanged(v597_.clutchState)
		if inputValue > 0 then
			self:raiseActive()
			return
		end
	else
		self:raiseDirtyFlags(v597_.inputDirtyFlag)
	end
end

-- Local values: missionInfo, automaticMotorStartEnabled, spec, actionEvent, text, motorState
function Motorized:updateActionEvents()
	local v599_ = g_currentMission.missionInfo.automaticMotorStartEnabled
	local v600_ = self.spec_motorized
	local v601_ = v600_.actionEvents[InputAction.TOGGLE_MOTOR_STATE]
	if v601_ ~= nil then
		if v599_ then
			g_inputBinding:setActionEventActive(v601_.actionEventId, false)
		else
			g_inputBinding:setActionEventActive(v601_.actionEventId, true)
			local v602_ = self:getMotorState()
			local v603_
			if v602_ == MotorState.STARTING or v602_ == MotorState.ON then
				g_inputBinding:setActionEventTextPriority(v601_.actionEventId, GS_PRIO_VERY_LOW)
				v603_ = v600_.turnOffText
			else
				g_inputBinding:setActionEventTextPriority(v601_.actionEventId, GS_PRIO_VERY_HIGH)
				v603_ = v600_.turnOnText
			end
			g_inputBinding:setActionEventText(v601_.actionEventId, v603_)
		end
	end
	local v604_ = v600_.actionEvents[InputAction.MOTOR_STATE_IGNITION]
	if v604_ ~= nil then
		g_inputBinding:setActionEventActive(v604_.actionEventId, not v599_)
	end
	local v605_ = v600_.actionEvents[InputAction.MOTOR_STATE_ON]
	if v605_ ~= nil then
		g_inputBinding:setActionEventActive(v605_.actionEventId, not v599_)
	end
	local v606_ = v600_.actionEvents[InputAction.MOTOR_STATE_OFF]
	if v606_ ~= nil then
		g_inputBinding:setActionEventActive(v606_.actionEventId, not v599_)
	end
end

function Motorized:getTraveledDistanceStatsActive()
	return true
end

-- Local values: spec, i, gearLever, j, state
function Motorized:setGearLeversState(gear, group, time, isResetPosition)
	local v612_ = self.spec_motorized
	for v613_ = 1, #v612_.gearLevers do
		local v614_ = v612_.gearLevers[v613_]
		for v615_ = 1, #v614_.states do
			local v616_ = v614_.states[v615_]
			if v616_.gear ~= nil and v616_.gear == gear or v616_.group ~= nil and v616_.group == group then
				self:generateShiftAnimation(v614_, v616_, time, isResetPosition)
			end
		end
	end
end

-- Local values: gearLeverInterpolator, requiresChange, axis, alreadyMovingToTarget, axis, requiresMoveToCenter, curCenter, tarCenter, axis, cur, tar, allowed, goToCenter, curCenter, tarCenter, axis, cur, tar, allowed, intState, _, numInterpolations, timePerInterpolation, ii, interpolation
function Motorized:generateShiftAnimation(gearLever, state, time, isResetPosition)
	local v621_ = state.curRotation
	local v622_ = state.curRotation
	local v623_ = state.curRotation
	local v624_, v625_, v626_ = getRotation(gearLever.node)
	v621_[1] = v624_
	v622_[2] = v625_
	v623_[3] = v626_
	local v627_ = false
	local v628_ = {
		["interpolations"] = {}
	}
	for v629_ = 1, 3 do
		local v630_ = state.curRotation[v629_] - state.rotation[v629_]
		if math.abs(v630_) > 0.00001 then
			v627_ = true
			break
		end
	end
	local v631_ = true
	for v632_ = 1, 3 do
		local v633_ = gearLever.curTarget[v632_] - state.rotation[v632_]
		if math.abs(v633_) > 0.00001 then
			v631_ = false
			break
		end
	end
	if not v627_ or v631_ then
		return false
	end
	local v634_ = gearLever.curTarget
	local v635_ = gearLever.curTarget
	local v636_ = gearLever.curTarget
	local v637_ = state.curRotation[1]
	local v638_ = state.curRotation[2]
	local v639_ = state.curRotation[3]
	v634_[1] = v637_
	v635_[2] = v638_
	v636_[3] = v639_
	local v640_
	if gearLever.centerAxis == nil then
		v640_ = false
	else
		local v641_ = state.curRotation[gearLever.centerAxis] - state.rotation[gearLever.centerAxis]
		v640_ = math.abs(v641_) > 0.00001
	end
	if v640_ then
		for v642_ = 1, 3 do
			if v642_ ~= gearLever.centerAxis then
				local v643_ = state.curRotation[v642_]
				local v644_ = state.rotation[v642_]
				local v645_ = gearLever.centerAxis ~= nil and 0 or v644_
				local v646_ = v643_ - v645_
				local v647_ = math.abs(v646_) > 0.00001
				local v648_
				if gearLever.centerAxis == nil or v647_ then
					v648_ = false
				else
					v647_ = state.useRotation[v642_]
					if v647_ then
						local v649_ = state.curRotation[gearLever.centerAxis] - state.rotation[gearLever.centerAxis]
						v647_ = math.abs(v649_) > 0.00001
					end
					v648_ = v647_
				end
				if v647_ then
					local v650_ = v628_.interpolations
					table.insert(v650_, {
						["axis"] = v642_,
						["cur"] = v643_,
						["tar"] = v648_ and 0 or v645_
					})
					gearLever.curTarget[v642_] = v645_
				end
			end
		end
	end
	if gearLever.centerAxis ~= nil then
		if v640_ then
			local v651_ = state.curRotation[gearLever.centerAxis]
			local v652_ = state.rotation[gearLever.centerAxis]
			local v653_ = v628_.interpolations
			local v654_ = {
				["axis"] = gearLever.centerAxis,
				["cur"] = v651_,
				["tar"] = v652_
			}
			table.insert(v653_, v654_)
			gearLever.curTarget[gearLever.centerAxis] = v652_
		end
		for v655_ = 1, 3 do
			if v655_ ~= gearLever.centerAxis then
				local v656_ = state.curRotation[v655_]
				local v657_ = state.rotation[v655_]
				local v658_ = v656_ - v657_
				local v659_ = math.abs(v658_) > 0.00001
				if gearLever.centerAxis ~= nil and not v659_ then
					v659_ = state.useRotation[v655_]
					if v659_ then
						local v660_ = state.curRotation[gearLever.centerAxis] - state.rotation[gearLever.centerAxis]
						v659_ = math.abs(v660_) > 0.00001
					end
				end
				if v659_ then
					local v661_ = v628_.interpolations
					table.insert(v661_, {
						["axis"] = v655_,
						["cur"] = v640_ and 0 or v656_,
						["tar"] = v657_
					})
					gearLever.curTarget[v655_] = v657_
				end
			end
		end
	end
	for v662_, _ in pairs(self.spec_motorized.activeGearLeverInterpolators) do
		if v662_.gearLever == state.gearLever then
			self.spec_motorized.activeGearLeverInterpolators[v662_] = nil
		end
	end
	if self.spec_motorized.activeGearLeverInterpolators[state] == nil then
		local v663_ = #v628_.interpolations
		if v663_ > 0 then
			local v664_ = gearLever.changeTime
			local v665_ = math.max(v664_, 0.001) / v663_
			for v666_ = 1, v663_ do
				local v667_ = v628_.interpolations[v666_]
				v667_.speed = (v667_.tar - v667_.cur) / v665_
			end
			v628_.currentInterpolation = 1
			v628_.isResetPosition = isResetPosition == nil and true or isResetPosition == true
			v628_.handsOnDelay = gearLever.handsOnDelay
			v628_.isGear = state.gear ~= nil
			self.spec_motorized.activeGearLeverInterpolators[state] = v628_
		end
	end
	return true
end

-- Local values: gear, gearGroup, gearsAvailable, groupsAvailable, isAutomatic, prevGearName, nextGearName, prevPrevGearName, nextNextGearName, isGearChanging, showNeutralWarning, motor
function Motorized:getGearInfoToDisplay()
	local v669_ = false
	local v670_ = self.spec_motorized.motor
	local v671_, v672_, v673_, v674_, v675_, v676_, v677_, v678_, v679_
	if v670_ == nil then
		v671_ = nil
		v672_ = nil
		v673_ = nil
		v674_ = nil
		v675_ = nil
		v676_ = nil
		v677_ = nil
		v678_ = nil
		v679_ = nil
	else
		v672_, v674_, v675_, v676_, v677_, v678_, v679_, v671_ = v670_:getGearInfoToDisplay()
		local v680_
		v673_, v680_ = v670_:getGearGroupToDisplay()
		if not v680_ then
			v673_ = nil
		end
		if self.getAcDecelerationAxis ~= nil then
			local v681_ = self:getAcDecelerationAxis()
			if math.abs(v681_) > 0 then
				v669_ = self:getIsMotorInNeutral()
			end
		end
	end
	return v672_, v673_, v674_, v675_, v676_, v677_, v678_, v679_, v671_, v669_
end

-- Local values: motor
function Motorized:setTransmissionDirection(direction)
	local v684_ = self.spec_motorized.motor
	if v684_ ~= nil then
		v684_:setTransmissionDirection(direction)
	end
end

function Motorized:getDirectionChangeMode()
	return self.spec_motorized.directionChangeMode
end

function Motorized:getIsManualDirectionChangeAllowed()
	return not self:getIsAIActive()
end

-- Local values: motor, isManualTransmission, useManualDirectionChange
function Motorized:getIsManualDirectionChangeActive()
	local v688_ = self.spec_motorized.motor
	local v689_ = (v688_.backwardGears ~= nil and true or v688_.forwardGears ~= nil) and v688_.gearShiftMode ~= VehicleMotor.SHIFT_MODE_AUTOMATIC and true or v688_.directionChangeMode == VehicleMotor.DIRECTION_CHANGE_MODE_MANUAL
	if v689_ then
		v689_ = self:getIsManualDirectionChangeAllowed()
	end
	return v689_
end

function Motorized:getGearShiftMode()
	return self.spec_motorized.gearShiftMode
end

-- Local values: missionInfo
function Motorized:onStateChange(state, vehicle, isControlling)
	local v693_ = g_currentMission.missionInfo
	if state == VehicleStateChange.ENTER_VEHICLE then
		if v693_.automaticMotorStartEnabled and (not g_ignitionLockManager:getIsAvailable() and self:getCanMotorRun()) then
			self:startMotor(true)
			return
		end
	elseif state == VehicleStateChange.LEAVE_VEHICLE then
		if self:getStopMotorOnLeave() and v693_.automaticMotorStartEnabled then
			self:stopMotor(true)
		end
		self:stopVehicle()
	end
end

-- Local values: spec
function Motorized:stopVehicle()
	if self.isServer and self.spec_motorized.motorizedNode ~= nil then
		self:controlVehicle(0, 0, 0, 0, math.huge, 0, 0, 0, 0, 0)
	end
end

-- Local values: factor, defFillUnitIndex, delta
function Motorized:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillType, toolType, fillPositionData, appliedDelta)
	if fillLevelDelta > 0 and fillType == FillType.DIESEL then
		local v699_ = self:getFillUnitFillLevel(fillUnitIndex) / self:getFillUnitCapacity(fillUnitIndex)
		local v700_ = self:getConsumerFillUnitIndex(FillType.DEF)
		if v700_ ~= nil then
			local v701_ = self:getFillUnitCapacity(v700_) * v699_ - self:getFillUnitFillLevel(v700_)
			self:addFillUnitFillLevel(self:getOwnerFarmId(), v700_, v701_, FillType.DEF, ToolType.UNDEFINED, nil)
		end
	end
end

function Motorized:onSetBroken()
	self:stopMotor(true)
end

function Motorized:getName(superFunc)
	if self.spec_motorized.vehicleName == nil then
		return superFunc(self)
	else
		return self.spec_motorized.vehicleName
	end
end

-- Local values: missionInfo, vehicles, _, vehicle
function Motorized:getCanBeSelected(superFunc)
	if not g_currentMission.missionInfo.automaticMotorStartEnabled then
		local v707_ = self.rootVehicle:getChildVehicles()
		for _, v708_ in pairs(v707_) do
			if v708_.spec_motorized ~= nil then
				return true
			end
		end
	end
	return superFunc(self)
end

-- Local values: ret, motorState, vehicles, _, vehicle, vehicleMotorState
function Motorized:getIsPowered(superFunc)
	local v711_ = superFunc(self)
	if v711_ then
		local v712_ = self:getMotorState()
		if v712_ ~= MotorState.STARTING and v712_ ~= MotorState.ON then
			local v713_ = self.rootVehicle:getChildVehicles()
			for _, v714_ in pairs(v713_) do
				if v714_ ~= self and v714_.getMotorState ~= nil then
					local v715_ = v714_:getMotorState()
					if v715_ == MotorState.STARTING or v715_ == MotorState.ON then
						return true
					end
				end
			end
			if self:getCanMotorRun() then
				return false, g_i18n:getText("warning_motorNotStarted")
			else
				return false, self:getMotorNotAllowedWarning()
			end
		end
	end
	return v711_
end

-- Local values: i, otherVehicle
function Motorized.tryStartMotor(vehicle)
	for v717_ = 1, #vehicle.rootVehicle.childVehicles do
		local v718_ = vehicle.rootVehicle.childVehicles[v717_]
		if v718_.getCanMotorRun ~= nil and v718_:getCanMotorRun() then
			v718_:startMotor()
		end
	end
end

-- Local values: motorState, warning
function Motorized:actionEventToggleMotorState(actionName, inputValue, callbackState, isAnalog)
	if not self:getIsAIActive() then
		local v720_ = self:getMotorState()
		if v720_ == MotorState.STARTING or v720_ == MotorState.ON then
			self:stopMotor()
			return
		end
		if self:getCanMotorRun() then
			self:startMotor()
			return
		end
		local v721_ = self:getMotorNotAllowedWarning()
		if v721_ ~= nil then
			g_currentMission:showBlinkingWarning(v721_, 2000)
		end
	end
end

-- Local values: motorState
function Motorized:actionEventSetMotorStateIgnition(actionName, inputValue, callbackState, isAnalog)
	if not self:getIsAIActive() and self:getMotorState() == MotorState.OFF then
		self:setMotorState(MotorState.IGNITION)
	end
end

-- Local values: motorState, warning
function Motorized:actionEventSetMotorStateOn(actionName, inputValue, callbackState, isAnalog)
	if not self:getIsAIActive() then
		local v724_ = self:getMotorState()
		if v724_ == MotorState.OFF or v724_ == MotorState.IGNITION then
			if self:getCanMotorRun() then
				self:startMotor()
				return
			end
			local v725_ = self:getMotorNotAllowedWarning()
			if v725_ ~= nil then
				g_currentMission:showBlinkingWarning(v725_, 2000)
			end
		end
	end
end

-- Local values: motorState
function Motorized:actionEventSetMotorStateOff(actionName, inputValue, callbackState, isAnalog)
	if not self:getIsAIActive() and self:getMotorState() ~= MotorState.OFF then
		self:stopMotor()
	end
end

-- Local values: rootName, fillUnits, i, configKey, configFillUnits, j, fillUnitKey, fillTypes, capacity, consumers, key, consumer, j, consumerKey, fillType, fillUnitIndex, capacity
function Motorized.loadSpecValueFuel(xmlFile, customEnvironment, baseDir)
	local v728_ = xmlFile:getRootName()
	local v729_ = 0
	local v730_ = {}
	while true do
		local v731_ = string.format(v728_ .. ".fillUnit.fillUnitConfigurations.fillUnitConfiguration(%d)", v729_)
		if not xmlFile:hasProperty(v731_) then
			break
		end
		local v732_ = 0
		local v733_ = {}
		while true do
			local v734_ = string.format(v731_ .. ".fillUnits.fillUnit(%d)", v732_)
			if not xmlFile:hasProperty(v734_) then
				break
			end
			local v735_ = {
				["fillTypes"] = xmlFile:getValue(v734_ .. "#fillTypes"),
				["capacity"] = xmlFile:getValue(v734_ .. "#capacity")
			}
			table.insert(v733_, v735_)
			v732_ = v732_ + 1
		end
		table.insert(v730_, v733_)
		v729_ = v729_ + 1
	end
	local v736_ = 0
	local v737_ = {}
	while true do
		local v738_ = string.format(v728_ .. ".motorized.consumerConfigurations.consumerConfiguration(%d)", v736_)
		if not xmlFile:hasProperty(v738_) then
			break
		end
		local v739_ = 0
		local v740_ = {}
		while true do
			local v741_ = string.format(v738_ .. ".consumer(%d)", v739_)
			if not xmlFile:hasProperty(v741_) then
				break
			end
			local v742_ = {
				["fillType"] = xmlFile:getValue(v741_ .. "#fillType"),
				["fillUnitIndex"] = xmlFile:getValue(v741_ .. "#fillUnitIndex"),
				["capacity"] = xmlFile:getValue(v741_ .. "#capacity")
			}
			table.insert(v740_, v742_)
			v739_ = v739_ + 1
		end
		table.insert(v737_, v740_)
		v736_ = v736_ + 1
	end
	return {
		["fillUnits"] = v730_,
		["consumers"] = v737_
	}
end

function Motorized.getSpecValueFuelDiesel(storeItem, realItem, configurations)
	return Motorized.getSpecValueFuel(storeItem, realItem, configurations, FillType.DIESEL)
end

function Motorized.getSpecValueFuelElectricCharge(storeItem, realItem, configurations)
	return Motorized.getSpecValueFuel(storeItem, realItem, configurations, FillType.ELECTRICCHARGE)
end

function Motorized.getSpecValueFuelMethane(storeItem, realItem, configurations)
	return Motorized.getSpecValueFuel(storeItem, realItem, configurations, FillType.METHANE)
end

-- Local values: consumerIndex, motorConfigId, motorConfigId, fuel, def, electricCharge, methane, fuelFillUnitIndex, defFillUnitIndex, electricFillUnitIndex, methaneFillUnitIndex, consumerConfiguration, _, unitConsumers, fillType, fuelConfigIndex, fuelFillUnit, defFillUnit, electricFillUnit, methaneFillUnit
function Motorized.getSpecValueFuel(storeItem, realItem, configurations, fillTypeFilter, returnValue)
	local v757_ = 1
	if realItem == nil or (storeItem.configurations == nil or (realItem.configurations.motor == nil or storeItem.configurations.motor == nil)) then
		if configurations ~= nil then
			local v758_ = configurations.motor
			if v758_ ~= nil then
				v757_ = Utils.getNoNil(storeItem.configurations.motor[v758_].consumerConfigurationIndex, v757_)
			end
		end
	else
		local v759_ = realItem.configurations.motor
		v757_ = Utils.getNoNil(storeItem.configurations.motor[v759_].consumerConfigurationIndex, v757_)
	end
	local v760_ = nil
	local v761_ = nil
	local v762_ = nil
	local v763_ = nil
	local v764_ = 0
	local v765_ = 0
	local v766_ = 0
	local v767_ = 0
	local v768_ = storeItem.specs.fuel
	if v768_ then
		v768_ = storeItem.specs.fuel.consumers[v757_]
	end
	if v768_ ~= nil then
		for _, v769_ in ipairs(v768_) do
			local v770_ = g_fillTypeManager:getFillTypeIndexByName(v769_.fillType)
			if fillTypeFilter == nil or v770_ == fillTypeFilter then
				if v770_ == FillType.DIESEL then
					v764_ = v769_.fillUnitIndex
					v760_ = v769_.capacity
					if v770_ == FillType.DEF then
						v765_ = v769_.fillUnitIndex
						v761_ = v769_.capacity
					end
				elseif v770_ == FillType.DEF then
					v765_ = v769_.fillUnitIndex
					v761_ = v769_.capacity
				elseif v770_ == FillType.ELECTRICCHARGE then
					v766_ = v769_.fillUnitIndex
					v762_ = v769_.capacity
				elseif v770_ == FillType.METHANE then
					v767_ = v769_.fillUnitIndex
					v763_ = v769_.capacity
				end
			end
		end
	end
	local v771_ = (realItem == nil or (storeItem.configurations == nil or (realItem.configurations.fillUnit == nil or storeItem.configurations.fillUnit == nil))) and 1 or realItem.configurations.fillUnit
	if storeItem.specs.fuel and storeItem.specs.fuel.fillUnits[v771_] ~= nil then
		if realItem == nil or realItem.getFillUnitCapacity == nil then
			local v772_ = storeItem.specs.fuel.fillUnits[v771_][v764_]
			if v772_ ~= nil and v760_ == nil then
				local v773_ = v772_.capacity
				v760_ = math.max(v773_, v760_ or 0)
			end
			local v774_ = storeItem.specs.fuel.fillUnits[v771_][v765_]
			if v774_ ~= nil and v761_ == nil then
				local v775_ = v774_.capacity
				v761_ = math.max(v775_, v761_ or 0)
			end
			local v776_ = storeItem.specs.fuel.fillUnits[v771_][v766_]
			if v776_ ~= nil and v762_ == nil then
				local v777_ = v776_.capacity
				v762_ = math.max(v777_, v762_ or 0)
			end
			local v778_ = storeItem.specs.fuel.fillUnits[v771_][v767_]
			if v778_ ~= nil and v763_ == nil then
				local v779_ = v778_.capacity
				v763_ = math.max(v779_, v763_ or 0)
			end
		else
			if v764_ ~= 0 then
				v760_ = realItem:getFillUnitCapacity(v764_)
			end
			if v765_ ~= 0 then
				v761_ = realItem:getFillUnitCapacity(v765_)
			end
			if v766_ ~= 0 then
				v762_ = realItem:getFillUnitCapacity(v766_)
			end
			if v767_ ~= 0 then
				v763_ = realItem:getFillUnitCapacity(v767_)
			end
		end
	end
	if returnValue then
		if fillTypeFilter == FillType.DIESEL or fillTypeFilter == nil then
			return v760_
		elseif fillTypeFilter == FillType.DEF then
			return v761_
		elseif fillTypeFilter == FillType.ELECTRICCHARGE then
			return v762_
		else
			return fillTypeFilter ~= FillType.METHANE and 0 or v763_
		end
	elseif v760_ == nil then
		if v762_ == nil then
			if v763_ == nil then
				return nil
			else
				return string.format(g_i18n:getText("shop_fuelValue"), v763_, g_i18n:getText("unit_kg"))
			end
		else
			return string.format(g_i18n:getText("shop_fuelValue"), v762_, g_i18n:getText("unit_kw"))
		end
	elseif v761_ == nil or v761_ <= 0 then
		return string.format(g_i18n:getText("shop_fuelValue"), v760_, g_i18n:getText("unit_literShort"))
	else
		return string.format(g_i18n:getText("shop_fuelDefValue"), v760_, g_i18n:getText("unit_literShort"), v761_, g_i18n:getText("unit_literShort"), g_i18n:getText("fillType_def_short"))
	end
end

-- Local values: motorKey, maxRpm, minForwardGearRatio, axleRatio, forwardGears, calculatedMaxSpeed, storeDataMaxSpeed, maxSpeed, maxForwardSpeed
function Motorized.loadSpecValueMaxSpeed(xmlFile, customEnvironment, baseDir)
	local v781_ = xmlFile:hasProperty("vehicle.motorized.motorConfigurations.motorConfiguration(0)") and "vehicle.motorized.motorConfigurations.motorConfiguration(0)" or (xmlFile:hasProperty("vehicle.motor") and "vehicle" or nil)
	if v781_ == nil then
		return nil
	else
		local v782_ = xmlFile:getValue(v781_ .. ".motor#maxRpm", 1800)
		local v783_ = xmlFile:getValue(v781_ .. ".transmission#minForwardGearRatio", nil)
		local v784_ = xmlFile:getValue(v781_ .. ".transmission#axleRatio", 1)
		local v785_ = Motorized.loadGears(nil, xmlFile, "forwardGear", v781_ .. ".transmission", v782_, v784_, 1)
		if v783_ == nil and v785_ == nil then
			Logging.xmlWarning(xmlFile, "No gear ratios defined for transmission")
		end
		local v786_ = VehicleMotor.calculatePhysicalMaximumSpeed(v783_, v785_, v782_) * 3.6
		local v787_ = math.ceil(v786_)
		local v788_ = xmlFile:getValue("vehicle.storeData.specs.maxSpeed")
		local v789_ = xmlFile:getValue("vehicle.motorized.motorConfigurations.motorConfiguration(0)#maxSpeed")
		local v790_ = xmlFile:getValue(v781_ .. ".motor#maxForwardSpeed")
		if v788_ == nil then
			if v789_ == nil then
				if v790_ == nil then
					return v787_
				else
					return math.min(v790_, v787_)
				end
			else
				return v789_
			end
		else
			return v788_
		end
	end
end

-- Local values: maxSpeed, configId, configId
function Motorized.getSpecValueMaxSpeed(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	local v794_ = nil
	if realItem ~= nil and storeItem.configurations ~= nil then
		if realItem.configurations.motor ~= nil and storeItem.configurations.motor ~= nil then
			local v795_ = realItem.configurations.motor
			v794_ = Utils.getNoNil(storeItem.configurations.motor[v795_].maxSpeed, v794_)
		end
		if realItem.configurations.wheel ~= nil and storeItem.configurations.wheel ~= nil then
			local v796_ = realItem.configurations.wheel
			v794_ = Utils.getNoNil(storeItem.configurations.wheel[v796_].maxForwardSpeedShop, v794_)
		end
	end
	if v794_ == nil then
		v794_ = storeItem.specs.maxSpeed
	end
	if v794_ == nil then
		return nil
	elseif returnValues then
		return MathUtil.round(v794_)
	else
		return string.format(g_i18n:getText("shop_maxSpeed"), string.format("%1d", g_i18n:getSpeed(v794_)), g_i18n:getSpeedMeasuringUnit())
	end
end

function Motorized.loadSpecValuePower(xmlFile, customEnvironment, baseDir)
	return xmlFile:getValue("vehicle.storeData.specs.power")
end

-- Local values: minPower, maxPower, configId, _, configItem
function Motorized.getSpecValuePower(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	local v801_ = nil
	local v802_ = nil
	if realItem == nil or (storeItem.configurations == nil or (realItem.configurations.motor == nil or storeItem.configurations.motor == nil)) then
		if realItem == nil and (storeItem.configurations ~= nil and storeItem.configurations.motor ~= nil) then
			for _, v803_ in ipairs(storeItem.configurations.motor) do
				if v803_.isSelectable and v803_.power ~= nil then
					local v804_ = v803_.power
					v801_ = math.min(v801_ or math.huge, v804_)
					local v805_ = v803_.power
					v802_ = math.max(v802_ or 0, v805_)
				end
			end
		end
	else
		local v806_ = realItem.configurations.motor
		v801_ = storeItem.configurations.motor[v806_].power
		v802_ = v801_
	end
	if v801_ == nil then
		v801_ = storeItem.specs.power
		v802_ = v801_
	end
	if v801_ == nil then
		return nil
	elseif returnValues == nil or returnValues == false then
		if v801_ == v802_ then
			return string.format(g_i18n:getText("shop_maxPowerValueSingle"), MathUtil.round(v801_))
		else
			return string.format(g_i18n:getText("shop_maxPowerValueRange"), MathUtil.round(v801_), MathUtil.round(v802_))
		end
	else
		return MathUtil.round(v801_), MathUtil.round(v802_)
	end
end

-- Local values: powerValues, name, configDesc, index, baseKey, configValue
function Motorized.loadSpecValuePowerConfig(xmlFile, customEnvironment, baseDir)
	local v808_ = nil
	for v809_, v810_ in pairs(g_vehicleConfigurationManager:getConfigurations()) do
		for v811_, v812_ in xmlFile:iterator(v810_.configurationKey) do
			if xmlFile:getValue(v812_ .. "#isSelectable", true) then
				local v813_ = xmlFile:getFloat(v812_ .. "#hp")
				if v813_ ~= nil then
					v808_ = v808_ or {}
					v808_[v809_] = v808_[v809_] or {}
					v808_[v809_][v811_] = MathUtil.round(v813_)
				end
			end
		end
	end
	return v808_
end

-- Local values: minPower, maxPower, configName, config, configPower, numConfigs, _, configs, _, configPower
function Motorized.getSpecValuePowerConfig(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	if storeItem.specs.powerConfig ~= nil then
		local v817_ = nil
		local v818_ = nil
		if configurations == nil then
			v817_ = math.huge
			v818_ = 0
			local v819_ = 0
			for _, v820_ in pairs(storeItem.specs.powerConfig) do
				for _, v821_ in pairs(v820_) do
					v817_ = math.min(v817_, v821_)
					v818_ = math.max(v818_, v821_)
					v819_ = v819_ + 1
				end
			end
		else
			for v822_, v823_ in pairs(configurations) do
				local v824_ = storeItem.specs.powerConfig[v822_][v823_]
				if v824_ ~= nil then
					v818_ = v824_
					v817_ = v818_
					local v825_ = v818_
					v818_ = v817_
					v825_ = v817_
				end
			end
		end
		if v817_ ~= nil then
			if returnValues then
				return MathUtil.round(v817_), MathUtil.round(v818_)
			elseif v817_ == v818_ then
				return string.format(g_i18n:getText("shop_maxPowerValueSingle"), MathUtil.round(v817_))
			else
				return string.format(g_i18n:getText("shop_maxPowerValueRange"), MathUtil.round(v817_), MathUtil.round(v818_))
			end
		end
	end
	return nil
end

-- Local values: nameByConfigIndex
function Motorized.loadSpecValueTransmission(xmlFile, customEnvironment, baseDir)
	local v_u_828_ = {}
	xmlFile:iterate("vehicle.motorized.motorConfigurations.motorConfiguration", function(p829_, p830_)
		-- upvalues: (copy) v_u_828_, (copy) xmlFile, (copy) customEnvironment
		v_u_828_[p829_] = xmlFile:getValue(p830_ .. ".transmission#name", nil, customEnvironment, false)
		local v831_ = xmlFile:getValue(p830_ .. ".transmission#param")
		if v831_ ~= nil then
			local v832_ = g_i18n:convertText(v831_, customEnvironment)
			v_u_828_[p829_] = string.format(v_u_828_[p829_], v832_)
		end
	end)
	return v_u_828_
end

-- Local values: name
function Motorized.getSpecValueTransmission(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	local v835_
	if realItem == nil or (storeItem.configurations == nil or (realItem.configurations.motor == nil or storeItem.configurations.motor == nil)) then
		v835_ = storeItem.specs.transmission[1]
	else
		v835_ = storeItem.specs.transmission[realItem.configurations.motor]
		if v835_ == nil then
			return storeItem.specs.transmission[1]
		end
	end
	return v835_
end
