source("dataS/scripts/vehicles/specializations/events/BalerSetIsUnloadingBaleEvent.lua")
source("dataS/scripts/vehicles/specializations/events/BalerSetBaleTimeEvent.lua")
source("dataS/scripts/vehicles/specializations/events/BalerCreateBaleEvent.lua")
source("dataS/scripts/vehicles/specializations/events/BalerDropFromPlatformEvent.lua")
source("dataS/scripts/vehicles/specializations/events/BalerAutomaticDropEvent.lua")
source("dataS/scripts/vehicles/specializations/events/BalerBaleTypeEvent.lua")
Baler = {}
Baler.CONSUMABLE_TYPE_NAME_ROUND = "BALE_NET"
Baler.CONSUMABLE_TYPE_NAME_SQUARE = "BALE_TWINE"
Baler.UNLOADING_CLOSED = 1
Baler.UNLOADING_OPENING = 2
Baler.UNLOADING_OPEN = 3
Baler.UNLOADING_CLOSING = 4
Baler.CLIENT_DM_UPDATE_RADIUS = 50
function Baler.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("baler", g_i18n:getText("shop_configuration"), "baler", VehicleConfigurationItem)
	AIFieldWorker.registerDriveStrategy(function(p1_)
		return SpecializationUtil.hasSpecialization(Baler, p1_.specializations)
	end, AIDriveStrategyBaler)
	g_workAreaTypeManager:addWorkAreaType("baler", false, false, true)
	g_storeManager:addSpecType("balerBaleSizeRound", "shopListAttributeIconBaleSizeRound", Baler.loadSpecValueBaleSizeRound, Baler.getSpecValueBaleSizeRound, StoreSpecies.VEHICLE)
	g_storeManager:addSpecType("balerBaleSizeSquare", "shopListAttributeIconBaleSizeSquare", Baler.loadSpecValueBaleSizeSquare, Baler.getSpecValueBaleSizeSquare, StoreSpecies.VEHICLE)
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("Baler")
	Baler.registerBalerXMLPaths(v2_, "vehicle.baler")
	Baler.registerBalerXMLPaths(v2_, "vehicle.baler.balerConfigurations.balerConfiguration(?)")
	v2_:register(XMLValueType.BOOL, FillUnit.ALARM_TRIGGER_XML_KEY .. "#needsBaleLoaded", "Alarm triggers only when a full bale is loaded", false)
	v2_:setXMLSpecializationType()
	local v3_ = Vehicle.xmlSchemaSavegame
	v3_:register(XMLValueType.INT, "vehicles.vehicle(?).baler#numBales", "Number of bales")
	v3_:register(XMLValueType.STRING, "vehicles.vehicle(?).baler.bale(?)#filename", "XML Filename of bale")
	v3_:register(XMLValueType.STRING, "vehicles.vehicle(?).baler.bale(?)#variationId", "Variation ID of the bale")
	v3_:register(XMLValueType.INT, "vehicles.vehicle(?).baler.bale(?)#ownerFarmId", "Owner of the bale")
	v3_:register(XMLValueType.STRING, "vehicles.vehicle(?).baler.bale(?)#fillType", "Bale fill type index")
	v3_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).baler.bale(?)#fillLevel", "Bale fill level")
	v3_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).baler.bale(?)#baleTime", "Bale time")
	v3_:register(XMLValueType.BOOL, "vehicles.vehicle(?).baler#platformReadyToDrop", "Platform is ready to drop", false)
	v3_:register(XMLValueType.INT, "vehicles.vehicle(?).baler#baleTypeIndex", "Current bale type index", 1)
	v3_:register(XMLValueType.INT, "vehicles.vehicle(?).baler#preSelectedBaleTypeIndex", "Pre selected bale type index", 1)
	v3_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).baler#fillUnitCapacity", "Current baler capacity depending on bale size")
	v3_:register(XMLValueType.BOOL, "vehicles.vehicle(?).baler#bufferUnloadingStarted", "Baler buffer unloading in progress")
	v3_:register(XMLValueType.STRING, "vehicles.vehicle(?).baler#workAreaMissionUniqueId", "Workarea mission unique id")
end

function Baler.registerBalerXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. "#fillScale", "Fill scale", 1)
	schema:register(XMLValueType.INT, basePath .. "#fillUnitIndex", "Fill unit index", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#consumableUsage", "Usage of bale net or twine per bale", 0.025)
	schema:register(XMLValueType.BOOL, basePath .. "#useDropLandOwnershipForBales", "Defines if the produced bales are always owned by the land owner of the current location while dropping the bale. If not, the owner is either the owner from the last workArea pickup location (if available) or the owner of the bale as default.", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".baleAnimation#spacing", "Spacing between bales", 0)
	schema:register(XMLValueType.BOOL, basePath .. ".baleAnimation#enableCollision", "Enable collision of bales with any other object", true)
	schema:register(XMLValueType.FLOAT, basePath .. ".baleAnimation.key(?)#time", "Key time")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".baleAnimation.key(?)#pos", "Key position")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".baleAnimation.key(?)#rot", "Key rotation")
	schema:register(XMLValueType.STRING, basePath .. ".baleAnimation#closeAnimationName", "Close animation name")
	schema:register(XMLValueType.FLOAT, basePath .. ".baleAnimation#closeAnimationSpeed", "Close animation speed", 1)
	schema:register(XMLValueType.BOOL, basePath .. ".automaticDrop#enabled", "Automatic drop default enabled", "true on mobile")
	schema:register(XMLValueType.BOOL, basePath .. ".automaticDrop#toggleable", "Automatic bale drop can be toggled", "false on mobile")
	schema:register(XMLValueType.L10N_STRING, basePath .. ".baleTypes#changeText", "Change bale size text", "action_changeBaleSize")
	schema:register(XMLValueType.BOOL, basePath .. ".baleTypes.baleType(?)#isRoundBale", "Is round bale", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".baleTypes.baleType(?)#width", "Bale width", 1.2)
	schema:register(XMLValueType.FLOAT, basePath .. ".baleTypes.baleType(?)#height", "Bale height", 0.9)
	schema:register(XMLValueType.FLOAT, basePath .. ".baleTypes.baleType(?)#length", "Bale length", 2.4)
	schema:register(XMLValueType.FLOAT, basePath .. ".baleTypes.baleType(?)#diameter", "Bale diameter", 2.8)
	schema:register(XMLValueType.BOOL, basePath .. ".baleTypes.baleType(?)#isDefault", "Bale type is selected by default", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".baleTypes.baleType(?)#consumableUsage", "Usage of bale net or twine per bale", 0.025)
	schema:register(XMLValueType.STRING, basePath .. ".baleTypes.baleType(?)#chamberBaleVariationId", "Variation identifier of the dummy bale in the chamber", "DEFAULT")
	schema:register(XMLValueType.STRING, basePath .. ".baleTypes.baleType(?)#defaultBaleVariationId", "Variation identifier of the final bale of no consumables are used", "DEFAULT")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".baleTypes.baleType(?).nodes#baleNode", "Bale link node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".baleTypes.baleType(?).nodes#baleRootNode", "Bale root node", "Same as baleNode")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".baleTypes.baleType(?).nodes#scaleNode", "Bale scale node")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".baleTypes.baleType(?).nodes#scaleComponents", "Bale scale component")
	schema:register(XMLValueType.STRING, basePath .. ".baleTypes.baleType(?).animations#fillAnimation", "Fill animation while this bale type is active")
	schema:register(XMLValueType.STRING, basePath .. ".baleTypes.baleType(?).animations#unloadAnimation", "Unload animation while this bale type is active")
	schema:register(XMLValueType.FLOAT, basePath .. ".baleTypes.baleType(?).animations#unloadAnimationSpeed", "Unload animation speed", 1)
	schema:register(XMLValueType.TIME, basePath .. ".baleTypes.baleType(?).animations#dropAnimationTime", "Specific time in #unloadAnimation when to drop the bale", "At the end of the unloading animation")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".baleTypes.baleType(?).detailVisibilityCutNode(?)#node", "Reference node for details visibility cut")
	schema:register(XMLValueType.INT, basePath .. ".baleTypes.baleType(?).detailVisibilityCutNode(?)#axis", "Axis of visibility cut [1, 3]", 3)
	schema:register(XMLValueType.INT, basePath .. ".baleTypes.baleType(?).detailVisibilityCutNode(?)#direction", "Direction of visibility cut [-1, 1]", 1)
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath .. ".baleTypes.baleType(?)")
	schema:register(XMLValueType.FLOAT, basePath .. "#unfinishedBaleThreshold", "Threshold to unload a unfinished bale", 2000)
	schema:register(XMLValueType.BOOL, basePath .. "#canUnloadUnfinishedBale", "Can unload unfinished bale", false)
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "work")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "eject")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "unload")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "door")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "knotCleaning")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "bufferOverloadingStart(?)")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "bufferOverloadingStop(?)")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "bufferOverloadingWork(?)")
	AnimationManager.registerAnimationNodesXMLPaths(schema, basePath .. ".animationNodes")
	AnimationManager.registerAnimationNodesXMLPaths(schema, basePath .. ".unloadAnimationNodes")
	EffectManager.registerEffectXMLPaths(schema, basePath .. ".fillEffect")
	EffectManager.registerEffectXMLPaths(schema, basePath .. ".additiveEffects")
	schema:register(XMLValueType.STRING, basePath .. ".knotingAnimation#name", "Knoting animation name")
	schema:register(XMLValueType.FLOAT, basePath .. ".knotingAnimation#speed", "Knoting animation speed", 1)
	schema:register(XMLValueType.STRING, basePath .. ".compactingAnimation#name", "Compacting animation name")
	schema:register(XMLValueType.FLOAT, basePath .. ".compactingAnimation#interval", "Compacting interval", 60)
	schema:register(XMLValueType.FLOAT, basePath .. ".compactingAnimation#compactTime", "Compacting time", 5)
	schema:register(XMLValueType.FLOAT, basePath .. ".compactingAnimation#speed", "Compacting animation speed", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".compactingAnimation#minFillLevelTime", "Compacting min. fill level animation target time", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".compactingAnimation#maxFillLevelTime", "Compacting max. fill level animation target time", 0.1)
	schema:register(XMLValueType.STRING, basePath .. "#maxPickupLitersPerSecond", "Max pickup liters per second", 500)
	schema:register(XMLValueType.BOOL, basePath .. ".baleUnloading#allowed", "Bale unloading allowed", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".baleUnloading#time", "Bale unloading time", 4)
	schema:register(XMLValueType.FLOAT, basePath .. ".baleUnloading#foldThreshold", "Bale unloading fold threshold", 0.25)
	schema:register(XMLValueType.L10N_STRING, basePath .. ".automaticDrop#textPos", "Positive toggle automatic drop text", "action_toggleAutomaticBaleDropPos")
	schema:register(XMLValueType.L10N_STRING, basePath .. ".automaticDrop#textNeg", "Negative toggle automatic drop text", "action_toggleAutomaticBaleDropNeg")
	schema:register(XMLValueType.STRING, basePath .. ".platform#animationName", "Platform animation")
	schema:register(XMLValueType.FLOAT, basePath .. ".platform#nextBaleTime", "Animation time when directly the next bale is unloaded after dropping from platform", 0)
	schema:register(XMLValueType.BOOL, basePath .. ".platform#automaticDrop", "Bale is automatically dropped from platform", "true on mobile")
	schema:register(XMLValueType.FLOAT, basePath .. ".platform#aiSpeed", "Speed of AI while dropping a bale from platform (km/h)", 3)
	schema:register(XMLValueType.INT, basePath .. ".buffer#fillUnitIndex", "Buffer fill unit index")
	schema:register(XMLValueType.INT, basePath .. ".buffer#unloadInfoIndex", "Fill volume unload info index index", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".buffer#capacityPercentage", "If set, this percentage of the bale capacity is set for the buffer. If not set the defined capacity from the xml is used.")
	schema:register(XMLValueType.TIME, basePath .. ".buffer#overloadingDuration", "Duration of overloading from buffer to baler unit (sec)", 0.5)
	schema:register(XMLValueType.TIME, basePath .. ".buffer#overloadingDelay", "Time until the real overloading is starting (can be used to wait for the effects to be fully fade in) (sec)", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".buffer#overloadingStartFillLevelPct", "Fill level percentage [0-1] of the buffer to start the overloading", 1)
	schema:register(XMLValueType.BOOL, basePath .. ".buffer#fillMainUnitAfterOverload", "After overloading the full buffer to the main unit it will continue filling the main unit until it\'s full", false)
	schema:register(XMLValueType.STRING, basePath .. ".buffer#balerDisplayType", "Forced fill type to display on baler unit")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".buffer.dummyBale#node", "Dummy bale link node")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".buffer.dummyBale#scaleComponents", "Dummy bale link scale components", "1 1 0")
	schema:register(XMLValueType.STRING, basePath .. ".buffer.overloadAnimation#name", "Name of overload animation")
	schema:register(XMLValueType.FLOAT, basePath .. ".buffer.overloadAnimation#speedScale", "Speed of overload animation", 1)
	schema:register(XMLValueType.STRING, basePath .. ".buffer.loadingStateAnimation#name", "Name of loading state animation")
	schema:register(XMLValueType.FLOAT, basePath .. ".buffer.loadingStateAnimation#speedScale", "Speed of loading state animation", 1)
	EffectManager.registerEffectXMLPaths(schema, basePath .. ".buffer.overloadingEffect")
	AnimationManager.registerAnimationNodesXMLPaths(schema, basePath .. ".buffer.overloadingAnimationNodes")
	schema:register(XMLValueType.FLOAT, basePath .. ".variableSpeedLimit#targetLiterPerSecond", "Target liters per second", 200)
	schema:register(XMLValueType.TIME, basePath .. ".variableSpeedLimit#changeInterval", "Interval which adjusts speed limit to conditions", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".variableSpeedLimit#minSpeedLimit", "Min. speed limit", 5)
	schema:register(XMLValueType.FLOAT, basePath .. ".variableSpeedLimit#maxSpeedLimit", "Max. speed limit", 15)
	schema:register(XMLValueType.FLOAT, basePath .. ".variableSpeedLimit#defaultSpeedLimit", "Default speed limit", 10)
	schema:register(XMLValueType.STRING, basePath .. ".variableSpeedLimit.target(?)#fillType", "Name of fill type")
	schema:register(XMLValueType.FLOAT, basePath .. ".variableSpeedLimit.target(?)#targetLiterPerSecond", "Target liters per second with this fill type", 200)
	schema:register(XMLValueType.FLOAT, basePath .. ".variableSpeedLimit.target(?)#defaultSpeedLimit", "Default speed limit with this fill type", 10)
	schema:register(XMLValueType.INT, basePath .. ".additives#fillUnitIndex", "Additives fill unit index")
	schema:register(XMLValueType.FLOAT, basePath .. ".additives#usage", "Usage per picked up liter", 0.0000275)
	schema:register(XMLValueType.STRING, basePath .. ".additives#fillTypes", "Fill types to apply additives", "GRASS_WINDROW")
	schema:register(XMLValueType.BOOL, basePath .. ".additives#appliedByBufferOverloading", "Additives are applied while the buffer unit is overloaded into main unit", false)
end

function Baler.prerequisitesPresent(specializations)
	local v7_ = SpecializationUtil.hasSpecialization(FillUnit, specializations) and SpecializationUtil.hasSpecialization(WorkArea, specializations) and (SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations) and SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations))
	if v7_ then
		v7_ = SpecializationUtil.hasSpecialization(Consumable, specializations)
	end
	return v7_
end

function Baler.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onBalerUnloadingStarted")
	SpecializationUtil.registerEvent(vehicleType, "onBalerUnloadingFinished")
end

function Baler.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "processBalerArea", Baler.processBalerArea)
	SpecializationUtil.registerFunction(vehicleType, "setBaleTypeIndex", Baler.setBaleTypeIndex)
	SpecializationUtil.registerFunction(vehicleType, "isUnloadingAllowed", Baler.isUnloadingAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getTimeFromLevel", Baler.getTimeFromLevel)
	SpecializationUtil.registerFunction(vehicleType, "moveBales", Baler.moveBales)
	SpecializationUtil.registerFunction(vehicleType, "moveBale", Baler.moveBale)
	SpecializationUtil.registerFunction(vehicleType, "setIsUnloadingBale", Baler.setIsUnloadingBale)
	SpecializationUtil.registerFunction(vehicleType, "getIsBaleUnloading", Baler.getIsBaleUnloading)
	SpecializationUtil.registerFunction(vehicleType, "dropBale", Baler.dropBale)
	SpecializationUtil.registerFunction(vehicleType, "finishBale", Baler.finishBale)
	SpecializationUtil.registerFunction(vehicleType, "createBale", Baler.createBale)
	SpecializationUtil.registerFunction(vehicleType, "setBaleTime", Baler.setBaleTime)
	SpecializationUtil.registerFunction(vehicleType, "getCanUnloadUnfinishedBale", Baler.getCanUnloadUnfinishedBale)
	SpecializationUtil.registerFunction(vehicleType, "setBalerAutomaticDrop", Baler.setBalerAutomaticDrop)
	SpecializationUtil.registerFunction(vehicleType, "updateDummyBale", Baler.updateDummyBale)
	SpecializationUtil.registerFunction(vehicleType, "deleteDummyBale", Baler.deleteDummyBale)
	SpecializationUtil.registerFunction(vehicleType, "createDummyBale", Baler.createDummyBale)
	SpecializationUtil.registerFunction(vehicleType, "handleUnloadingBaleEvent", Baler.handleUnloadingBaleEvent)
	SpecializationUtil.registerFunction(vehicleType, "dropBaleFromPlatform", Baler.dropBaleFromPlatform)
	SpecializationUtil.registerFunction(vehicleType, "getBalerBaleOwnerFarmId", Baler.getBalerBaleOwnerFarmId)
	SpecializationUtil.registerFunction(vehicleType, "getIsRoundBaler", Baler.getIsRoundBaler)
end

function Baler.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSpeedRotatingPartFromXML", Baler.loadSpeedRotatingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Baler.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSpeedRotatingPartActive", Baler.getIsSpeedRotatingPartActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", Baler.getCanBeTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", Baler.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", Baler.getIsWorkAreaActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConsumingLoad", Baler.getConsumingLoad)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRequiresPower", Baler.getRequiresPower)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Baler.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAttachedTo", Baler.getIsAttachedTo)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowDynamicMountFillLevelInfo", Baler.getAllowDynamicMountFillLevelInfo)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAlarmTriggerIsActive", Baler.getAlarmTriggerIsActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAlarmTrigger", Baler.loadAlarmTrigger)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getShowConsumableEmptyWarning", Baler.getShowConsumableEmptyWarning)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", Baler.addToPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", Baler.removeFromPhysics)
end

function Baler.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterExternalActionEvents", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onRootVehicleChanged", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onChangedFillType", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onConsumableVariationChanged", Baler)
end

-- Local values: spec, baseKey, configurationId, configKey, baleAnimCurve, keyframes, lastX, lastY, lastZ, totalLength, i, keyframe, t, defaultBaleTypeIndex, defaultBaleType, closeAnimation, fillTypeName, fillTypeIndex, additivesFillTypeNames, baleTypeIndex, preSelectedBaleTypeIndex, fillUnitCapacity
function Baler:onLoad(savegame)
	local v_u_14_ = self.spec_baler
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.fillScale#value", "vehicle.baler#fillScale")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnRotationNodes.turnedOnRotationNode#type", "vehicle.baler.animationNodes.animationNode", "baler")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.balingAnimation#name", "vehicle.turnOnVehicle.turnedOnAnimation#name")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.fillParticleSystems", "vehicle.baler.fillEffect with effectClass \'ParticleEffect\'")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.uvScrollParts.uvScrollPart", "vehicle.baler.animationNodes.animationNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.balerAlarm", "vehicle.fillUnit.fillUnitConfigurations.fillUnitConfiguration.fillUnits.fillUnit.alarmTriggers.alarmTrigger.alarmSound")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.baleAnimation#node", "vehicle.baler.baleTypes.baleType#baleNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.baleAnimation#baleNode", "vehicle.baler.baleTypes.baleType#baleNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.baleAnimation#scaleNode", "vehicle.baler.baleTypes.baleType#scaleNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.baleAnimation#baleScaleComponent", "vehicle.baler.baleTypes.baleType#scaleComponents")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.baleAnimation#unloadAnimationName", "vehicle.baler.baleTypes.baleType#unloadAnimation")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.baleAnimation#unloadAnimationSpeed", "vehicle.baler.baleTypes.baleType#unloadAnimationSpeed")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.baleAnimation#baleDropAnimTime", "vehicle.baler.baleTypes.baleType#dropAnimationTime")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler#toggleAutomaticDropTextPos", "vehicle.baler.automaticDrop#textPos")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler#toggleAutomaticDropTextNeg", "vehicle.baler.automaticDrop#textNeg")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.baleAnimation#firstBaleMarker", "Please adjust bale nodes to match the default balers")
	local v15_ = self.configurations.baler or 1
	local v16_ = string.format("vehicle.baler.balerConfigurations.balerConfiguration(%d)", v15_ - 1)
	local v17_ = not self.xmlFile:hasProperty(v16_) and "vehicle.baler" or v16_
	v_u_14_.fillScale = self.xmlFile:getValue(v17_ .. "#fillScale", 1)
	v_u_14_.fillUnitIndex = self.xmlFile:getValue(v17_ .. "#fillUnitIndex", 1)
	v_u_14_.consumableUsage = self.xmlFile:getValue(v17_ .. "#consumableUsage", 0.025)
	v_u_14_.useDropLandOwnershipForBales = self.xmlFile:getValue(v17_ .. "#useDropLandOwnershipForBales", false)
	if self.xmlFile:hasProperty(v17_ .. ".baleAnimation") then
		local v18_ = AnimCurve.new(linearInterpolatorN)
		local v_u_19_ = {}
		local v_u_20_ = nil
		local v_u_21_ = nil
		local v_u_22_ = nil
		local v_u_23_ = 0
		self.xmlFile:iterate(v17_ .. ".baleAnimation.key", function(_, p24_)
			-- upvalues: (copy) self, (ref) v_u_20_, (ref) v_u_21_, (ref) v_u_22_, (ref) v_u_23_, (copy) v_u_19_
			XMLUtil.checkDeprecatedXMLElements(self.xmlFile, p24_ .. "#time")
			local v25_ = {}
			local v26_, v27_, v28_ = self.xmlFile:getValue(p24_ .. "#pos")
			v25_.x = v26_
			v25_.y = v27_
			v25_.z = v28_
			if v25_.x == nil then
				Logging.xmlWarning(self.xmlFile, "Missing values for \'%s\'", p24_ .. "#pos")
			else
				local v29_, v30_, v31_ = self.xmlFile:getValue(p24_ .. "#rot", "0 0 0")
				v25_.rx = v29_
				v25_.ry = v30_
				v25_.rz = v31_
				if v_u_20_ ~= nil then
					v25_.length = MathUtil.vector3Length(v_u_20_ - v25_.x, v_u_21_ - v25_.y, v_u_22_ - v25_.z)
					v_u_23_ = v_u_23_ + v25_.length
					v25_.pos = v_u_23_
				end
				local v32_ = v_u_19_
				table.insert(v32_, v25_)
				local v33_ = v25_.x
				local v34_ = v25_.y
				local v35_ = v25_.z
				v_u_20_ = v33_
				v_u_21_ = v34_
				v_u_22_ = v35_
			end
		end)
		local v36_ = v_u_23_
		for v37_ = 1, #v_u_19_ do
			local v38_ = v_u_19_[v37_]
			local v39_ = v38_.pos == nil and 0 or v38_.pos / v36_
			v18_:addKeyframe({
				v38_.x,
				v38_.y,
				v38_.z,
				v38_.rx,
				v38_.ry,
				v38_.rz,
				["time"] = v39_
			})
		end
		if #v_u_19_ > 0 then
			v_u_14_.baleAnimCurve = v18_
			v_u_14_.baleAnimLength = v36_
			v_u_14_.baleAnimSpacing = self.xmlFile:getValue(v17_ .. ".baleAnimation#spacing", 0)
			v_u_14_.baleAnimEnableCollision = self.xmlFile:getValue(v17_ .. ".baleAnimation#enableCollision", true)
		end
	end
	v_u_14_.hasUnloadingAnimation = true
	v_u_14_.isRoundBaler = false
	v_u_14_.lastBaleVariationId = nil
	local v_u_40_ = 1
	v_u_14_.baleTypes = {}
	self.xmlFile:iterate(v17_ .. ".baleTypes.baleType", function(p41_, p42_)
		-- upvalues: (copy) v_u_14_, (copy) self, (ref) v_u_40_
		if #v_u_14_.baleTypes >= BalerBaleTypeEvent.MAX_NUM_BALE_TYPES then
			Logging.xmlError(self.xmlFile, "Too many bale types defined. Max. amount is \'%d\'! \'%s\'", BalerBaleTypeEvent.MAX_NUM_BALE_TYPES, p42_)
			return false
		else
			local v_u_43_ = {
				["index"] = p41_,
				["isRoundBale"] = self.xmlFile:getValue(p42_ .. "#isRoundBale", false),
				["width"] = MathUtil.round(self.xmlFile:getValue(p42_ .. "#width", 1.2), 2),
				["height"] = MathUtil.round(self.xmlFile:getValue(p42_ .. "#height", 0.9), 2),
				["length"] = MathUtil.round(self.xmlFile:getValue(p42_ .. "#length", 2.4), 2),
				["diameter"] = MathUtil.round(self.xmlFile:getValue(p42_ .. "#diameter", 1.8), 2)
			}
			if v_u_43_.isRoundBale then
				v_u_14_.isRoundBaler = true
			end
			v_u_43_.isDefault = self.xmlFile:getValue(p42_ .. "#isDefault", false)
			if v_u_43_.isDefault then
				v_u_40_ = p41_
			end
			v_u_43_.consumableUsage = self.xmlFile:getValue(p42_ .. "#consumableUsage", v_u_14_.consumableUsage)
			v_u_43_.chamberBaleVariationId = self.xmlFile:getValue(p42_ .. "#chamberBaleVariationId", "DEFAULT")
			v_u_43_.defaultBaleVariationId = self.xmlFile:getValue(p42_ .. "#defaultBaleVariationId", "DEFAULT")
			v_u_43_.baleNode = self.xmlFile:getValue(p42_ .. ".nodes#baleNode", nil, self.components, self.i3dMappings)
			local v44_, v45_ = self.xmlFile:getValue(p42_ .. ".nodes#baleRootNode", v_u_43_.baleNode, self.components, self.i3dMappings)
			v_u_43_.baleRootNode = v44_
			v_u_43_.baleNodeComponent = v45_
			if v_u_43_.baleRootNode ~= nil and v_u_43_.baleNodeComponent == nil then
				v_u_43_.baleNodeComponent = self:getParentComponent(v_u_43_.baleRootNode)
			end
			if v_u_43_.baleNode == nil then
				Logging.xmlError(self.xmlFile, "Missing baleNode for bale type. \'%s\'", p42_)
			else
				v_u_43_.scaleNode = self.xmlFile:getValue(p42_ .. ".nodes#scaleNode", nil, self.components, self.i3dMappings)
				v_u_43_.scaleComponents = self.xmlFile:getValue(p42_ .. ".nodes#scaleComponents", nil, true)
				v_u_43_.animations = {}
				v_u_43_.animations.fill = self.xmlFile:getValue(p42_ .. ".animations#fillAnimation")
				v_u_43_.animations.unloading = self.xmlFile:getValue(p42_ .. ".animations#unloadAnimation")
				v_u_43_.animations.unloadingSpeed = self.xmlFile:getValue(p42_ .. ".animations#unloadAnimationSpeed", 1)
				v_u_43_.animations.dropAnimationTime = self.xmlFile:getValue(p42_ .. ".animations#dropAnimationTime", self:getAnimationDuration(v_u_43_.animations.unloading) / 1000)
				v_u_43_.detailVisibilityCutNodes = {}
				self.xmlFile:iterate(p42_ .. ".detailVisibilityCutNode", function(_, p46_)
					-- upvalues: (ref) self, (copy) v_u_43_
					local v47_ = {
						["node"] = self.xmlFile:getValue(p46_ .. "#node", nil, self.components, self.i3dMappings)
					}
					if v47_.node ~= nil then
						v47_.axis = self.xmlFile:getValue(p46_ .. "#axis", 3)
						v47_.direction = self.xmlFile:getValue(p46_ .. "#direction", 1)
						local v48_ = v_u_43_.detailVisibilityCutNodes
						table.insert(v48_, v47_)
					end
				end)
				v_u_43_.changeObjects = {}
				ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, p42_, v_u_43_.changeObjects, self.components, self)
				local v49_ = v_u_14_.baleTypes
				table.insert(v49_, v_u_43_)
				local v50_ = v_u_14_
				local v51_ = v_u_14_.hasUnloadingAnimation
				if v51_ then
					v51_ = v_u_43_.animations.unloading ~= nil
				end
				v50_.hasUnloadingAnimation = v51_
			end
		end
	end)
	local v52_ = v_u_14_.baleTypes[v_u_40_]
	if v52_ ~= nil then
		ObjectChangeUtil.setObjectChanges(v52_.changeObjects, true, self, self.setMovingToolDirty)
	end
	v_u_14_.changeBaleTypeText = self.xmlFile:getValue(v17_ .. ".baleTypes#changeText", "action_changeBaleSize", self.customEnvironment)
	v_u_14_.preSelectedBaleTypeIndex = v_u_40_
	v_u_14_.currentBaleTypeIndex = v_u_40_
	v_u_14_.currentBaleXMLFilename = nil
	v_u_14_.currentBaleTypeDefinition = nil
	if #v_u_14_.baleTypes == 0 then
		Logging.xmlError(self.xmlFile, "No baleTypes definded for baler.")
	end
	if v_u_14_.hasUnloadingAnimation then
		v_u_14_.automaticDrop = self.xmlFile:getValue(v17_ .. ".automaticDrop#enabled", Platform.gameplay.automaticBaleDrop)
		v_u_14_.toggleableAutomaticDrop = self.xmlFile:getValue(v17_ .. ".automaticDrop#toggleable", not Platform.gameplay.automaticBaleDrop)
		v_u_14_.toggleAutomaticDropTextPos = self.xmlFile:getValue(v17_ .. ".automaticDrop#textPos", "action_toggleAutomaticBaleDropPos", self.customEnvironment)
		v_u_14_.toggleAutomaticDropTextNeg = self.xmlFile:getValue(v17_ .. ".automaticDrop#textNeg", "action_toggleAutomaticBaleDropNeg", self.customEnvironment)
		v_u_14_.baleCloseAnimationName = self.xmlFile:getValue(v17_ .. ".baleAnimation#closeAnimationName")
		v_u_14_.baleCloseAnimationSpeed = self.xmlFile:getValue(v17_ .. ".baleAnimation#closeAnimationSpeed", 1)
		local v53_ = self:getAnimationByName(v_u_14_.baleCloseAnimationName)
		if v_u_14_.baleCloseAnimationName == nil or v53_ == nil then
			Logging.xmlError(self.xmlFile, "Failed to find baler close animation. (%s)", v17_ .. ".baleAnimation#closeAnimationName")
		else
			v53_.resetOnStart = false
		end
	end
	v_u_14_.unfinishedBaleThreshold = self.xmlFile:getValue(v17_ .. "#unfinishedBaleThreshold", 2000)
	v_u_14_.canUnloadUnfinishedBale = self.xmlFile:getValue(v17_ .. "#canUnloadUnfinishedBale", false)
	v_u_14_.lastBaleFillLevel = nil
	if self.isClient then
		v_u_14_.samples = {}
		v_u_14_.samples.work = g_soundManager:loadSampleFromXML(self.xmlFile, v17_ .. ".sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_14_.samples.eject = g_soundManager:loadSampleFromXML(self.xmlFile, v17_ .. ".sounds", "eject", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_14_.samples.unload = g_soundManager:loadSampleFromXML(self.xmlFile, v17_ .. ".sounds", "unload", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_14_.samples.door = g_soundManager:loadSampleFromXML(self.xmlFile, v17_ .. ".sounds", "door", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_14_.samples.knotCleaning = g_soundManager:loadSampleFromXML(self.xmlFile, v17_ .. ".sounds", "knotCleaning", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_14_.knotCleaningTimer = 10000
		v_u_14_.knotCleaningTime = 120000
		v_u_14_.animationNodes = g_animationManager:loadAnimations(self.xmlFile, v17_ .. ".animationNodes", self.components, self, self.i3dMappings)
		v_u_14_.unloadAnimationNodes = g_animationManager:loadAnimations(self.xmlFile, v17_ .. ".unloadAnimationNodes", self.components, self, self.i3dMappings)
		v_u_14_.fillEffects = g_effectManager:loadEffect(self.xmlFile, v17_ .. ".fillEffect", self.components, self, self.i3dMappings)
		v_u_14_.fillEffectType = FillType.UNKNOWN
		v_u_14_.additiveEffects = g_effectManager:loadEffect(self.xmlFile, v17_ .. ".additiveEffects", self.components, self, self.i3dMappings)
		v_u_14_.knotingAnimation = self.xmlFile:getValue(v17_ .. ".knotingAnimation#name")
		v_u_14_.knotingAnimationSpeed = self.xmlFile:getValue(v17_ .. ".knotingAnimation#speed", 1)
		v_u_14_.compactingAnimation = self.xmlFile:getValue(v17_ .. ".compactingAnimation#name")
		v_u_14_.compactingAnimationInterval = self.xmlFile:getValue(v17_ .. ".compactingAnimation#interval", 60) * 1000
		v_u_14_.compactingAnimationCompactTime = self.xmlFile:getValue(v17_ .. ".compactingAnimation#compactTime", 5) * 1000
		v_u_14_.compactingAnimationCompactTimer = v_u_14_.compactingAnimationCompactTime
		v_u_14_.compactingAnimationTime = v_u_14_.compactingAnimationInterval
		v_u_14_.compactingAnimationSpeed = self.xmlFile:getValue(v17_ .. ".compactingAnimation#speed", 1)
		v_u_14_.compactingAnimationMinTime = self.xmlFile:getValue(v17_ .. ".compactingAnimation#minFillLevelTime", 1)
		v_u_14_.compactingAnimationMaxTime = self.xmlFile:getValue(v17_ .. ".compactingAnimation#maxFillLevelTime", 0.1)
	end
	v_u_14_.lastAreaBiggerZero = false
	v_u_14_.lastAreaBiggerZeroSent = false
	v_u_14_.lastAreaBiggerZeroTime = 0
	v_u_14_.workAreaParameters = {}
	v_u_14_.workAreaParameters.lastPickedUpLiters = 0
	v_u_14_.fillUnitOverflowFillLevel = 0
	v_u_14_.maxPickupLitersPerSecond = self.xmlFile:getValue(v17_ .. "#maxPickupLitersPerSecond", 500)
	v_u_14_.pickUpLitersBuffer = ValueBuffer.new(750)
	v_u_14_.unloadingState = Baler.UNLOADING_CLOSED
	v_u_14_.pickupFillTypes = {}
	v_u_14_.bales = {}
	v_u_14_.dummyBale = {}
	v_u_14_.dummyBale.currentBaleFillType = FillType.UNKNOWN
	v_u_14_.dummyBale.currentBale = nil
	v_u_14_.dummyBale.currentBaleLength = 0
	v_u_14_.allowsBaleUnloading = self.xmlFile:getValue(v17_ .. ".baleUnloading#allowed", false)
	v_u_14_.baleUnloadingTime = self.xmlFile:getValue(v17_ .. ".baleUnloading#time", 4) * 1000
	v_u_14_.baleFoldThreshold = self.xmlFile:getValue(v17_ .. ".baleUnloading#foldThreshold", 0.25) * self:getFillUnitCapacity(v_u_14_.fillUnitIndex)
	v_u_14_.platformAnimation = self.xmlFile:getValue(v17_ .. ".platform#animationName")
	v_u_14_.platformAnimationNextBaleTime = self.xmlFile:getValue(v17_ .. ".platform#nextBaleTime", 0)
	v_u_14_.platformAutomaticDrop = self.xmlFile:getValue(v17_ .. ".platform#automaticDrop", Platform.gameplay.automaticBaleDrop)
	v_u_14_.platformAIDropSpeed = self.xmlFile:getValue(v17_ .. ".platform#aiSpeed", 3)
	v_u_14_.hasPlatform = v_u_14_.platformAnimation ~= nil
	v_u_14_.hasDynamicMountPlatform = SpecializationUtil.hasSpecialization(DynamicMountAttacher, self.specializations)
	if v_u_14_.hasPlatform then
		v_u_14_.automaticDrop = true
	end
	v_u_14_.platformReadyToDrop = false
	v_u_14_.platformDropInProgress = false
	v_u_14_.platformDelayedDropping = false
	v_u_14_.platformMountDelay = -1
	v_u_14_.buffer = {}
	v_u_14_.buffer.fillUnitIndex = self.xmlFile:getValue(v17_ .. ".buffer#fillUnitIndex")
	v_u_14_.buffer.unloadInfoIndex = self.xmlFile:getValue(v17_ .. ".buffer#unloadInfoIndex", 1)
	v_u_14_.buffer.capacityPercentage = self.xmlFile:getValue(v17_ .. ".buffer#capacityPercentage")
	v_u_14_.buffer.overloadingDuration = self.xmlFile:getValue(v17_ .. ".buffer#overloadingDuration", 1)
	v_u_14_.buffer.overloadingDelay = self.xmlFile:getValue(v17_ .. ".buffer#overloadingDelay", 0)
	v_u_14_.buffer.overloadingTimer = 0
	v_u_14_.buffer.overloadingStartFillLevelPct = MathUtil.round(self.xmlFile:getValue(v17_ .. ".buffer#overloadingStartFillLevelPct", 1), 2)
	v_u_14_.buffer.fillMainUnitAfterOverload = self.xmlFile:getValue(v17_ .. ".buffer#fillMainUnitAfterOverload", false)
	v_u_14_.buffer.unloadingStarted = false
	v_u_14_.buffer.fillLevelToEmpty = 0
	v_u_14_.buffer.dummyBale = {}
	v_u_14_.buffer.dummyBale.available = self.xmlFile:hasProperty(v17_ .. ".buffer.dummyBale")
	v_u_14_.buffer.dummyBale.linkNode = self.xmlFile:getValue(v17_ .. ".buffer.dummyBale#node", nil, self.components, self.i3dMappings)
	v_u_14_.buffer.dummyBale.scaleComponents = self.xmlFile:getValue(v17_ .. ".buffer.dummyBale#scaleComponents", "1 1 0", true)
	v_u_14_.buffer.overloadAnimation = self.xmlFile:getValue(v17_ .. ".buffer.overloadAnimation#name")
	v_u_14_.buffer.overloadAnimationSpeed = self.xmlFile:getValue(v17_ .. ".buffer.overloadAnimation#speedScale", 1)
	v_u_14_.buffer.loadingStateAnimation = self.xmlFile:getValue(v17_ .. ".buffer.loadingStateAnimation#name")
	v_u_14_.buffer.loadingStateAnimationSpeed = self.xmlFile:getValue(v17_ .. ".buffer.loadingStateAnimation#speedScale", 1)
	if self.isClient then
		v_u_14_.buffer.overloadingEffects = g_effectManager:loadEffect(self.xmlFile, v17_ .. ".buffer.overloadingEffect", self.components, self, self.i3dMappings)
		v_u_14_.buffer.overloadingAnimationNodes = g_animationManager:loadAnimations(self.xmlFile, v17_ .. ".buffer.overloadingAnimationNodes", self.components, self, self.i3dMappings)
		v_u_14_.buffer.samplesOverloadingStart = g_soundManager:loadSamplesFromXML(self.xmlFile, v17_ .. ".sounds", "bufferOverloadingStart", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_14_.buffer.samplesOverloadingStop = g_soundManager:loadSamplesFromXML(self.xmlFile, v17_ .. ".sounds", "bufferOverloadingStop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_14_.buffer.samplesOverloadingWork = g_soundManager:loadSamplesFromXML(self.xmlFile, v17_ .. ".sounds", "bufferOverloadingWork", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
	v_u_14_.nonStopBaling = v_u_14_.buffer.fillUnitIndex ~= nil
	if v_u_14_.nonStopBaling ~= nil then
		local v54_ = self.xmlFile:getValue(v17_ .. ".buffer#balerDisplayType")
		local v55_ = g_fillTypeManager:getFillTypeIndexByName(v54_)
		if v55_ ~= nil then
			self:setFillUnitFillTypeToDisplay(v_u_14_.fillUnitIndex, v55_, true)
		end
	end
	v_u_14_.variableSpeedLimit = {}
	v_u_14_.variableSpeedLimit.enabled = self.xmlFile:hasProperty(v17_ .. ".variableSpeedLimit")
	v_u_14_.variableSpeedLimit.pickupPerSecond = 0
	v_u_14_.variableSpeedLimit.pickupPerSecondTimer = 0
	v_u_14_.variableSpeedLimit.targetLiterPerSecond = self.xmlFile:getValue(v17_ .. ".variableSpeedLimit#targetLiterPerSecond", 200)
	v_u_14_.variableSpeedLimit.changeInterval = self.xmlFile:getValue(v17_ .. ".variableSpeedLimit#changeInterval", 1)
	v_u_14_.variableSpeedLimit.minSpeedLimit = self.xmlFile:getValue(v17_ .. ".variableSpeedLimit#minSpeedLimit", 5)
	v_u_14_.variableSpeedLimit.maxSpeedLimit = self.xmlFile:getValue(v17_ .. ".variableSpeedLimit#maxSpeedLimit", 15)
	v_u_14_.variableSpeedLimit.defaultSpeedLimit = self.xmlFile:getValue(v17_ .. ".variableSpeedLimit#defaultSpeedLimit", 10)
	v_u_14_.variableSpeedLimit.backupSpeedLimit = self.speedLimit
	v_u_14_.variableSpeedLimit.usedBackupSpeedLimit = false
	v_u_14_.variableSpeedLimit.lastAdjustedSpeedLimit = nil
	v_u_14_.variableSpeedLimit.lastAdjustedSpeedLimitType = nil
	v_u_14_.variableSpeedLimit.fillTypeToTargetLiterPerSecond = {}
	self.xmlFile:iterate(v17_ .. ".variableSpeedLimit.target", function(_, p56_)
		-- upvalues: (copy) self, (copy) v_u_14_
		local v57_ = g_fillTypeManager:getFillTypeIndexByName(self.xmlFile:getValue(p56_ .. "#fillType"))
		if v57_ ~= nil then
			local v58_ = {
				["targetLiterPerSecond"] = self.xmlFile:getValue(p56_ .. "#targetLiterPerSecond", 200),
				["defaultSpeedLimit"] = self.xmlFile:getValue(p56_ .. "#defaultSpeedLimit", 10)
			}
			v_u_14_.variableSpeedLimit.fillTypeToTargetLiterPerSecond[v57_] = v58_
		end
	end)
	v_u_14_.additives = {}
	v_u_14_.additives.fillUnitIndex = self.xmlFile:getValue(v17_ .. ".additives#fillUnitIndex")
	v_u_14_.additives.available = self:getFillUnitByIndex(v_u_14_.additives.fillUnitIndex) ~= nil
	v_u_14_.additives.usage = self.xmlFile:getValue(v17_ .. ".additives#usage", 0.0000275)
	local v59_ = self.xmlFile:getValue(v17_ .. ".additives#fillTypes", "GRASS_WINDROW")
	v_u_14_.additives.fillTypes = g_fillTypeManager:getFillTypesByNames(v59_, "Warning: \'" .. self.xmlFile:getFilename() .. "\' has invalid fillType \'%s\'.")
	v_u_14_.additives.appliedByBufferOverloading = self.xmlFile:getValue(v17_ .. ".additives#appliedByBufferOverloading", false)
	v_u_14_.additives.isActiveTimer = 0
	v_u_14_.additives.isActive = false
	v_u_14_.isBaleUnloading = false
	v_u_14_.balesToUnload = 0
	v_u_14_.texts = {}
	v_u_14_.texts.warningFoldingBaleLoaded = g_i18n:getText("warning_foldingNotWhileBaleLoaded")
	v_u_14_.texts.warningFoldingTurnedOn = g_i18n:getText("warning_foldingNotWhileTurnedOn")
	v_u_14_.texts.warningTooManyBales = g_i18n:getText("warning_tooManyBales")
	v_u_14_.texts.unloadUnfinishedBale = g_i18n:getText("action_unloadUnfinishedBale")
	v_u_14_.texts.unloadBaler = g_i18n:getText("action_unloadBaler")
	v_u_14_.texts.closeBack = g_i18n:getText("action_closeBack")
	v_u_14_.showBaleLimitWarning = false
	v_u_14_.dirtyFlag = self:getNextDirtyFlag()
	if savegame ~= nil and not savegame.resetVehicles then
		self:setBaleTypeIndex(savegame.xmlFile:getValue(savegame.key .. ".baler#baleTypeIndex", v_u_14_.currentBaleTypeIndex), true, true)
		self:setBaleTypeIndex(savegame.xmlFile:getValue(savegame.key .. ".baler#preSelectedBaleTypeIndex", v_u_14_.preSelectedBaleTypeIndex), nil, true)
		local v60_ = savegame.xmlFile:getValue(savegame.key .. ".baler#fillUnitCapacity")
		if v60_ ~= nil then
			local v61_ = v60_ == 0 and math.huge or v60_
			self:setFillUnitCapacity(v_u_14_.fillUnitIndex, v61_)
			if v_u_14_.buffer.capacityPercentage ~= nil then
				self:setFillUnitCapacity(v_u_14_.fillUnitIndex, v61_ * v_u_14_.buffer.capacityPercentage, false)
			end
		end
		v_u_14_.workAreaParameters.lastMissionUniqueId = savegame.xmlFile:getValue(savegame.key .. ".baler#workAreaMissionUniqueId")
		if v_u_14_.nonStopBaling then
			v_u_14_.buffer.unloadingStarted = savegame.xmlFile:getValue(savegame.key .. ".baler#bufferUnloadingStarted", v_u_14_.buffer.unloadingStarted)
		end
	end
end

-- Local values: spec, fillTypeIndex, enabled, numBales, i, baleKey, bale, filename, fillTypeStr, fillType
function Baler:onPostLoad(savegame)
	local v64_ = self.spec_baler
	for v65_, v66_ in pairs(self:getFillUnitSupportedFillTypes(v64_.fillUnitIndex)) do
		if v66_ and v65_ ~= FillType.UNKNOWN then
			v64_.pickupFillTypes[v65_] = 0
		end
	end
	if savegame ~= nil and not savegame.resetVehicles then
		local v67_ = savegame.xmlFile:getValue(savegame.key .. ".baler#numBales")
		if v67_ ~= nil then
			v64_.balesToLoad = {}
			for v68_ = 1, v67_ do
				local v69_ = string.format("%s.baler.bale(%d)", savegame.key, v68_ - 1)
				local v70_ = {}
				local v71_ = savegame.xmlFile:getValue(v69_ .. "#filename")
				local v72_ = savegame.xmlFile:getValue(v69_ .. "#fillType")
				local v73_ = g_fillTypeManager:getFillTypeByName(v72_)
				if v71_ ~= nil and v73_ ~= nil then
					v70_.filename = v71_
					v70_.fillType = v73_.index
					v70_.fillLevel = savegame.xmlFile:getValue(v69_ .. "#fillLevel")
					v70_.baleTime = savegame.xmlFile:getValue(v69_ .. "#baleTime")
					v70_.variationId = savegame.xmlFile:getValue(v69_ .. "#variationId")
					v70_.ownerFarmId = savegame.xmlFile:getValue(v69_ .. "#ownerFarmId")
					local v74_ = v64_.balesToLoad
					table.insert(v74_, v70_)
				end
			end
		end
		if v64_.hasPlatform then
			v64_.platformReadyToDrop = savegame.xmlFile:getValue(savegame.key .. ".baler#platformReadyToDrop", v64_.platformReadyToDrop)
			if v64_.platformReadyToDrop then
				self:setAnimationTime(v64_.platformAnimation, 1, true)
				self:setAnimationTime(v64_.platformAnimation, 0, true)
				v64_.platformMountDelay = 1
			end
		end
	end
end

-- Local values: spec, _, v
function Baler:onLoadFinished(savegame)
	local v76_ = self.spec_baler
	if self.isServer and (v76_.createBaleNextFrame ~= nil and v76_.createBaleNextFrame) then
		self:finishBale()
		v76_.createBaleNextFrame = nil
	end
	if v76_.balesToLoad ~= nil then
		for _, v77_ in ipairs(v76_.balesToLoad) do
			if self:createBale(v77_.fillType, v77_.fillLevel, nil, v77_.baleTime, v77_.filename, v77_.ownerFarmId, v77_.variationId, true) then
				self:setBaleTime(#v76_.bales, v77_.baleTime, true)
			end
		end
		v76_.balesToLoad = nil
	end
end

-- Local values: spec, dropBales, k, _, _, bale
function Baler:onDelete()
	local v79_ = self.spec_baler
	if v79_.bales ~= nil then
		if (v79_.dropBalesOnDelete or v79_.dropBalesOnDelete == nil) and (self.isReconfigurating == nil or not self.isReconfigurating) then
			for v80_, _ in pairs(v79_.bales) do
				self:dropBale(v80_)
			end
		else
			for _, v81_ in pairs(v79_.bales) do
				if v81_.baleObject ~= nil then
					v81_.baleObject:delete()
				end
			end
		end
	end
	self:deleteDummyBale(v79_.dummyBale)
	if v79_.buffer ~= nil then
		if v79_.buffer.dummyBale.available then
			self:deleteDummyBale(v79_.buffer.dummyBale)
		end
		g_soundManager:deleteSamples(v79_.buffer.samplesOverloadingStart)
		g_soundManager:deleteSamples(v79_.buffer.samplesOverloadingWork)
		g_soundManager:deleteSamples(v79_.buffer.samplesOverloadingStop)
		g_effectManager:deleteEffects(v79_.buffer.overloadingEffects)
		g_animationManager:deleteAnimations(v79_.buffer.overloadingAnimationNodes)
	end
	g_soundManager:deleteSamples(v79_.samples)
	g_effectManager:deleteEffects(v79_.fillEffects)
	g_effectManager:deleteEffects(v79_.additiveEffects)
	g_animationManager:deleteAnimations(v79_.animationNodes)
	g_animationManager:deleteAnimations(v79_.unloadAnimationNodes)
end

-- Local values: spec, k, bale, baleKey, fillTypeStr, mission
function Baler:saveToXMLFile(xmlFile, key, usedModNames)
	local v85_ = self.spec_baler
	if not v85_.hasUnloadingAnimation or self:getFillUnitFreeCapacity(v85_.fillUnitIndex) > 0 then
		xmlFile:setValue(key .. "#numBales", #v85_.bales)
		for v86_, v87_ in ipairs(v85_.bales) do
			local v88_ = string.format("%s.bale(%d)", key, v86_ - 1)
			xmlFile:setValue(v88_ .. "#filename", v87_.filename)
			xmlFile:setValue(v88_ .. "#variationId", v87_.baleObject:getVariationId())
			xmlFile:setValue(v88_ .. "#ownerFarmId", v87_.baleObject:getOwnerFarmId())
			local v89_ = v87_.fillType == FillType.UNKNOWN and "UNKNOWN" or g_fillTypeManager:getFillTypeNameByIndex(v87_.fillType)
			xmlFile:setValue(v88_ .. "#fillType", v89_)
			xmlFile:setValue(v88_ .. "#fillLevel", v87_.fillLevel)
			if v85_.baleAnimCurve ~= nil then
				xmlFile:setValue(v88_ .. "#baleTime", v87_.time)
			end
		end
	end
	if v85_.hasPlatform then
		xmlFile:setValue(key .. "#platformReadyToDrop", v85_.platformReadyToDrop)
	end
	xmlFile:setValue(key .. "#baleTypeIndex", v85_.currentBaleTypeIndex)
	xmlFile:setValue(key .. "#preSelectedBaleTypeIndex", v85_.preSelectedBaleTypeIndex)
	xmlFile:setValue(key .. "#fillUnitCapacity", self:getFillUnitCapacity(v85_.fillUnitIndex))
	local v90_ = g_missionManager:getMissionByUniqueId(v85_.workAreaParameters.lastMissionUniqueId)
	if v90_ ~= nil and v90_:getIsRunning() then
		xmlFile:setValue(key .. "#workAreaMissionUniqueId", v90_:getUniqueId())
	end
	if v85_.nonStopBaling then
		xmlFile:setValue(key .. "#bufferUnloadingStarted", v85_.buffer.unloadingStarted)
	end
end

-- Local values: spec, state, animTime, numBales, i, fillType, fillLevel, baleTime, capacity, fillLevel, fillUnit
function Baler:onReadStream(streamId, connection)
	local v93_ = self.spec_baler
	if v93_.hasUnloadingAnimation then
		local v94_ = streamReadUIntN(streamId, 7)
		local v95_ = streamReadFloat32(streamId)
		if v94_ == Baler.UNLOADING_CLOSED or v94_ == Baler.UNLOADING_CLOSING then
			self:setIsUnloadingBale(false, true)
			self:setRealAnimationTime(v93_.baleCloseAnimationName, v95_)
		elseif v94_ == Baler.UNLOADING_OPEN or v94_ == Baler.UNLOADING_OPENING then
			self:setIsUnloadingBale(true, true)
			self:setRealAnimationTime(v93_.baleUnloadAnimationName, v95_)
		end
	end
	for v96_ = 1, streamReadUInt8(streamId) do
		self:createBale(streamReadIntN(streamId, FillTypeManager.SEND_NUM_BITS), (streamReadFloat32(streamId)))
		if v93_.baleAnimCurve ~= nil then
			self:setBaleTime(v96_, (streamReadFloat32(streamId)))
		end
	end
	v93_.lastAreaBiggerZero = streamReadBool(streamId)
	if v93_.hasPlatform then
		v93_.platformReadyToDrop = streamReadBool(streamId)
		if v93_.platformReadyToDrop then
			self:setAnimationTime(v93_.platformAnimation, 1, true)
			self:setAnimationTime(v93_.platformAnimation, 0, true)
		end
	end
	v93_.currentBaleTypeIndex = streamReadUIntN(streamId, BalerBaleTypeEvent.BALE_TYPE_SEND_NUM_BITS)
	v93_.preSelectedBaleTypeIndex = streamReadUIntN(streamId, BalerBaleTypeEvent.BALE_TYPE_SEND_NUM_BITS)
	local v97_ = streamReadFloat32(streamId)
	self:setFillUnitCapacity(v93_.fillUnitIndex, v97_)
	local v98_ = streamReadFloat32(streamId)
	local v99_ = self:getFillUnitByIndex(v93_.fillUnitIndex)
	if v99_ ~= nil then
		v99_.fillLevel = v98_
	end
end

-- Local values: spec, animTime, i, bale
function Baler:onWriteStream(streamId, connection)
	local v102_ = self.spec_baler
	if v102_.hasUnloadingAnimation then
		streamWriteUIntN(streamId, v102_.unloadingState, 7)
		local v103_ = 0
		if v102_.unloadingState == Baler.UNLOADING_CLOSED or v102_.unloadingState == Baler.UNLOADING_CLOSING then
			v103_ = self:getRealAnimationTime(v102_.baleCloseAnimationName)
		elseif v102_.unloadingState == Baler.UNLOADING_OPEN or v102_.unloadingState == Baler.UNLOADING_OPENING then
			v103_ = self:getRealAnimationTime(v102_.baleUnloadAnimationName)
		end
		streamWriteFloat32(streamId, v103_)
	end
	streamWriteUInt8(streamId, #v102_.bales)
	for v104_ = 1, #v102_.bales do
		local v105_ = v102_.bales[v104_]
		streamWriteIntN(streamId, v105_.fillType, FillTypeManager.SEND_NUM_BITS)
		streamWriteFloat32(streamId, v105_.fillLevel)
		if v102_.baleAnimCurve ~= nil then
			streamWriteFloat32(streamId, v105_.time)
		end
	end
	streamWriteBool(streamId, v102_.lastAreaBiggerZero)
	if v102_.hasPlatform then
		streamWriteBool(streamId, v102_.platformReadyToDrop)
	end
	streamWriteUIntN(streamId, v102_.currentBaleTypeIndex, BalerBaleTypeEvent.BALE_TYPE_SEND_NUM_BITS)
	streamWriteUIntN(streamId, v102_.preSelectedBaleTypeIndex, BalerBaleTypeEvent.BALE_TYPE_SEND_NUM_BITS)
	streamWriteFloat32(streamId, self:getFillUnitCapacity(v102_.fillUnitIndex))
	streamWriteFloat32(streamId, self:getFillUnitFillLevel(v102_.fillUnitIndex))
end

-- Local values: spec, fillType
function Baler:onReadUpdateStream(streamId, timestamp, connection)
	local v109_ = self.spec_baler
	if connection:getIsServer() and streamReadBool(streamId) then
		v109_.lastAreaBiggerZero = streamReadBool(streamId)
		v109_.fillEffectType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
		v109_.showBaleLimitWarning = streamReadBool(streamId)
		if v109_.nonStopBaling then
			v109_.buffer.unloadingStarted = streamReadBool(streamId)
			if v109_.buffer.unloadingStarted then
				local v110_ = self:getFillUnitFillType(v109_.buffer.fillUnitIndex)
				if v110_ == FillType.UNKNOWN then
					v110_ = self:getFillUnitFillType(v109_.fillUnitIndex)
				end
				g_effectManager:setEffectTypeInfo(v109_.buffer.overloadingEffects, v110_)
				g_effectManager:startEffects(v109_.buffer.overloadingEffects)
				g_soundManager:playSamples(v109_.buffer.samplesOverloadingStart)
				g_soundManager:playSamples(v109_.buffer.samplesOverloadingWork, 0, v109_.buffer.samplesOverloadingStart[0])
				g_animationManager:startAnimations(v109_.buffer.overloadingAnimationNodes)
			else
				g_effectManager:stopEffects(v109_.buffer.overloadingEffects)
				g_soundManager:stopSamples(v109_.buffer.samplesOverloadingStart)
				if g_soundManager:getIsSamplePlaying(v109_.buffer.samplesOverloadingWork[0]) then
					g_soundManager:stopSamples(v109_.buffer.samplesOverloadingWork)
					g_soundManager:playSamples(v109_.buffer.samplesOverloadingStop)
				end
				g_animationManager:stopAnimations(v109_.buffer.overloadingAnimationNodes)
			end
		end
		v109_.additives.isActive = streamReadBool(streamId)
		if v109_.additives.isActive then
			g_effectManager:setEffectTypeInfo(v109_.additiveEffects, FillType.LIQUIDFERTILIZER)
			g_effectManager:startEffects(v109_.additiveEffects)
			return
		end
		g_effectManager:stopEffects(v109_.additiveEffects)
	end
end

-- Local values: spec
function Baler:onWriteUpdateStream(streamId, connection, dirtyMask)
	local v115_ = self.spec_baler
	if not connection:getIsServer() then
		local v116_ = streamWriteBool
		local v117_ = v115_.dirtyFlag
		if v116_(streamId, bit32.band(dirtyMask, v117_) ~= 0) then
			streamWriteBool(streamId, v115_.lastAreaBiggerZero)
			streamWriteUIntN(streamId, v115_.fillEffectTypeSent, FillTypeManager.SEND_NUM_BITS)
			streamWriteBool(streamId, v115_.showBaleLimitWarning)
			if v115_.nonStopBaling then
				streamWriteBool(streamId, v115_.buffer.unloadingStarted)
			end
			streamWriteBool(streamId, v115_.additives.isActive)
		end
	end
end

-- Local values: spec, baleObject, baleTypeDef, i, bale, j, detailVisibilityCutNode, j, detailVisibilityCutNode, defaultSpeedLimit, targetLiterPerSecond, fillTypeIndex, target, litersPerSecond, threshold, changeAmount
function Baler:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v120_ = self.spec_baler
	if self.isClient then
		if v120_.baleToMount ~= nil then
			local v121_ = NetworkUtil.getObject(v120_.baleToMount.baleServerId)
			if v121_ ~= nil then
				v121_:mountKinematic(self, v120_.baleToMount.jointNode, 0, 0, 0, 0, 0, 0)
				v120_.baleToMount.baleInfo.baleObject = v121_
				v120_.baleToMount.baleInfo.baleServerId = v120_.baleToMount.baleServerId
				v120_.baleToMount = nil
			end
		end
		local v122_ = v120_.baleTypes[v120_.currentBaleTypeIndex]
		if v122_ ~= nil and #v122_.detailVisibilityCutNodes > 0 then
			for v123_ = 1, #v120_.bales do
				local v124_ = v120_.bales[v123_]
				if v124_.baleObject ~= nil then
					v124_.baleObject:resetDetailVisibilityCut()
					if v124_.time < 1 then
						for v125_ = 1, #v122_.detailVisibilityCutNodes do
							local v126_ = v122_.detailVisibilityCutNodes[v125_]
							v124_.baleObject:setDetailVisibilityCutNode(v126_.node, v126_.axis, v126_.direction)
						end
					end
				end
			end
			if v120_.dummyBale.currentBale ~= nil then
				for v127_ = 1, #v122_.detailVisibilityCutNodes do
					local v128_ = v122_.detailVisibilityCutNodes[v127_]
					Bale.setBaleMeshVisibilityCut(v120_.dummyBale.currentBale, v128_.node, v128_.axis, v128_.direction, true)
				end
			end
		end
	end
	if self.isServer then
		if self.isAddedToPhysics and (v120_.createBaleNextFrame ~= nil and v120_.createBaleNextFrame) then
			self:finishBale()
			v120_.createBaleNextFrame = nil
		end
		if v120_.variableSpeedLimit.enabled then
			v120_.variableSpeedLimit.pickupPerSecondTimer = v120_.variableSpeedLimit.pickupPerSecondTimer + dt
			if v120_.variableSpeedLimit.pickupPerSecondTimer > v120_.variableSpeedLimit.changeInterval then
				local v129_ = v120_.variableSpeedLimit.defaultSpeedLimit
				local v130_ = v120_.variableSpeedLimit.targetLiterPerSecond
				local v131_ = self:getFillUnitFillType(v120_.fillUnitIndex)
				if v131_ == FillType.UNKNOWN and v120_.nonStopBaling then
					v131_ = self:getFillUnitFillType(v120_.buffer.fillUnitIndex)
				end
				if v131_ ~= nil and v120_.variableSpeedLimit.fillTypeToTargetLiterPerSecond[v131_] ~= nil then
					local v132_ = v120_.variableSpeedLimit.fillTypeToTargetLiterPerSecond[v131_]
					v129_ = v132_.defaultSpeedLimit
					v130_ = v132_.targetLiterPerSecond
				end
				local v133_ = v120_.variableSpeedLimit.pickupPerSecond / (v120_.variableSpeedLimit.changeInterval / 1000)
				if v133_ > 0 then
					if v120_.variableSpeedLimit.usedBackupSpeedLimit then
						v120_.variableSpeedLimit.usedBackupSpeedLimit = false
						self.speedLimit = v120_.variableSpeedLimit.lastAdjustedSpeedLimit or v129_
						if (v120_.variableSpeedLimit.lastAdjustedSpeedLimitType or v131_) ~= v131_ then
							self.speedLimit = v129_
						end
					end
					local v134_ = v130_ * 0.15
					local v135_ = v133_ * 2 / v130_
					local v136_ = math.floor(v135_)
					local v137_ = math.max(v136_, 1)
					if v130_ + v134_ < v133_ then
						local v138_ = self.speedLimit - v137_
						local v139_ = v120_.variableSpeedLimit.minSpeedLimit
						self.speedLimit = math.max(v138_, v139_)
					elseif v133_ < v130_ - v134_ then
						local v140_ = self.speedLimit + v137_
						local v141_ = v120_.variableSpeedLimit.maxSpeedLimit
						self.speedLimit = math.min(v140_, v141_)
					end
					v120_.variableSpeedLimit.lastAdjustedSpeedLimit = self.speedLimit
					v120_.variableSpeedLimit.lastAdjustedSpeedLimitType = v131_
				else
					v120_.variableSpeedLimit.usedBackupSpeedLimit = true
					self.speedLimit = v120_.variableSpeedLimit.backupSpeedLimit
				end
				v120_.variableSpeedLimit.pickupPerSecondTimer = 0
				v120_.variableSpeedLimit.pickupPerSecond = 0
			end
		end
	end
end

-- Local values: spec, showBaleLimitWarning, isTurnedOn, loadPercentage, fillLevel, stopTime, deltaTime, baleTypeDef, baleTypeDef, isPlaying, animTime, fillType, _, lastUnloadingStarted, bufferLevel, capacity, delta, sourceFillType, unloadInfo, realDelta, targetFillType, overloadedLiters, fillTypeSupported, i, additivesFillLevel, usage, availableUsage, fillType
function Baler:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v144_ = self.spec_baler
	local v145_ = false
	local v146_ = self:getIsTurnedOn()
	if v146_ then
		v145_ = not g_currentMission.slotSystem:getCanAddLimitedObjects(SlotSystem.LIMITED_OBJECT_BALE, 1) and true or v145_
		if self.isClient then
			if v144_.lastAreaBiggerZero and v144_.fillEffectType ~= FillType.UNKNOWN then
				v144_.lastAreaBiggerZeroTime = 500
			elseif v144_.lastAreaBiggerZeroTime > 0 then
				local v147_ = v144_.lastAreaBiggerZeroTime - dt
				v144_.lastAreaBiggerZeroTime = math.max(v147_, 0)
			end
			if v144_.lastAreaBiggerZeroTime > 0 then
				if v144_.fillEffectType ~= FillType.UNKNOWN then
					g_effectManager:setEffectTypeInfo(v144_.fillEffects, v144_.fillEffectType)
				end
				g_effectManager:startEffects(v144_.fillEffects)
				local v148_ = v144_.pickUpLitersBuffer:get(1000) / v144_.maxPickupLitersPerSecond
				g_effectManager:setDensity(v144_.fillEffects, (math.max(v148_, 0.4)))
			else
				g_effectManager:stopEffects(v144_.fillEffects)
			end
			if v144_.knotCleaningTimer <= g_currentMission.time then
				g_soundManager:playSample(v144_.samples.knotCleaning)
				v144_.knotCleaningTimer = g_currentMission.time + v144_.knotCleaningTime
			end
			if v144_.compactingAnimation ~= nil and v144_.unloadingState == Baler.UNLOADING_CLOSED then
				if v144_.compactingAnimationTime <= g_currentMission.time then
					local v149_ = self:getFillUnitFillLevelPercentage(v144_.fillUnitIndex)
					local v150_ = MathUtil.lerp(v144_.compactingAnimationMinTime, v144_.compactingAnimationMaxTime, v149_)
					if v150_ > 0 then
						self:setAnimationStopTime(v144_.compactingAnimation, (math.clamp(v150_, 0, 1)))
						self:playAnimation(v144_.compactingAnimation, v144_.compactingAnimationSpeed, self:getAnimationTime(v144_.compactingAnimation), false)
						v144_.compactingAnimationTime = math.huge
					end
				end
				if v144_.compactingAnimationTime == math.huge and not self:getIsAnimationPlaying(v144_.compactingAnimation) then
					v144_.compactingAnimationCompactTimer = v144_.compactingAnimationCompactTimer - dt
					if v144_.compactingAnimationCompactTimer < 0 then
						self:playAnimation(v144_.compactingAnimation, -v144_.compactingAnimationSpeed, self:getAnimationTime(v144_.compactingAnimation), false)
						v144_.compactingAnimationCompactTimer = v144_.compactingAnimationCompactTime
					end
					if self:getAnimationTime(v144_.compactingAnimation) == 0 then
						v144_.compactingAnimationTime = g_currentMission.time + v144_.compactingAnimationInterval
					end
				end
			end
		end
	elseif v144_.isBaleUnloading and self.isServer then
		self:moveBales(dt / v144_.baleUnloadingTime)
	end
	if self.isClient and v144_.unloadingState == Baler.UNLOADING_OPEN then
		local v151_ = v144_.baleTypes[v144_.currentBaleTypeIndex]
		if getNumOfChildren(v151_.baleNode) > 0 then
			delete(getChildAt(v151_.baleNode, 0))
		end
	end
	if v144_.unloadingState == Baler.UNLOADING_OPENING then
		local v152_ = v144_.baleTypes[v144_.currentBaleTypeIndex]
		local v153_ = self:getIsAnimationPlaying(v152_.animations.unloading)
		if v153_ and self:getRealAnimationTime(v152_.animations.unloading) < v152_.animations.dropAnimationTime then
			g_animationManager:startAnimations(v144_.unloadAnimationNodes)
		else
			if #v144_.bales > 0 then
				self:dropBale(1)
				if self.isServer then
					self:addFillUnitFillLevel(self:getOwnerFarmId(), v144_.fillUnitIndex, -math.huge, self:getFillUnitFillType(v144_.fillUnitIndex), ToolType.UNDEFINED)
					v144_.buffer.unloadingStarted = false
					for v154_, _ in pairs(v144_.pickupFillTypes) do
						v144_.pickupFillTypes[v154_] = 0
					end
					if self:getFillUnitFillLevel(v144_.fillUnitIndex) == 0 and v144_.preSelectedBaleTypeIndex ~= v144_.currentBaleTypeIndex then
						self:setBaleTypeIndex(v144_.preSelectedBaleTypeIndex, true)
					end
				end
			end
			if not v153_ then
				v144_.unloadingState = Baler.UNLOADING_OPEN
				if self.isClient then
					g_soundManager:stopSample(v144_.samples.eject)
					g_soundManager:stopSample(v144_.samples.door)
					g_animationManager:stopAnimations(v144_.unloadAnimationNodes)
				end
			end
		end
	elseif v144_.unloadingState == Baler.UNLOADING_CLOSING and not self:getIsAnimationPlaying(v144_.baleCloseAnimationName) then
		v144_.unloadingState = Baler.UNLOADING_CLOSED
		if self.isClient then
			g_soundManager:stopSample(v144_.samples.door)
		end
	end
	if (v144_.unloadingState == Baler.UNLOADING_OPEN or v144_.unloadingState == Baler.UNLOADING_CLOSING) and (not self.isServer and #v144_.bales > 0) then
		self:dropBale(1)
	end
	Baler.updateActionEvents(self)
	if self.isServer then
		if v144_.automaticDrop ~= nil and v144_.automaticDrop or self:getIsAIActive() then
			if self:isUnloadingAllowed() and (v144_.hasUnloadingAnimation or v144_.allowsBaleUnloading) and (v144_.unloadingState == Baler.UNLOADING_CLOSED and #v144_.bales > 0) then
				self:setIsUnloadingBale(true)
			end
			if v144_.hasUnloadingAnimation and v144_.unloadingState == Baler.UNLOADING_OPEN then
				self:setIsUnloadingBale(false)
			end
		end
		v144_.pickUpLitersBuffer:add(v144_.workAreaParameters.lastPickedUpLiters)
		if v144_.additives.isActiveTimer > 0 then
			v144_.additives.isActiveTimer = v144_.additives.isActiveTimer - dt
			if v144_.additives.isActiveTimer < 0 then
				v144_.additives.isActiveTimer = 0
				v144_.additives.isActive = false
				if self.isClient then
					g_effectManager:stopEffects(v144_.additiveEffects)
				end
				self:raiseDirtyFlags(v144_.dirtyFlag)
			end
		end
		if v144_.platformAutomaticDrop and v144_.platformReadyToDrop then
			self:dropBaleFromPlatform(true)
		end
		if v144_.hasPlatform then
			if #v144_.bales > 0 and v144_.platformReadyToDrop then
				self:dropBaleFromPlatform(true)
			end
			if v144_.hasDynamicMountPlatform then
				if v144_.platformMountDelay > 0 then
					v144_.platformMountDelay = v144_.platformMountDelay - 1
					if v144_.platformMountDelay == 0 then
						self:forceDynamicMountPendingObjects(true)
					end
				elseif v144_.platformReadyToDrop and not self:getHasDynamicMountedObjects() then
					self:dropBaleFromPlatform(false)
				end
			end
		end
		if v144_.nonStopBaling then
			local v155_ = v144_.buffer.unloadingStarted
			local v156_ = self:getFillUnitFillLevel(v144_.buffer.fillUnitIndex)
			if v156_ > 0 then
				local v157_ = self:getFillUnitCapacity(v144_.buffer.fillUnitIndex)
				if v146_ and MathUtil.round(v156_ / v157_, 2) >= v144_.buffer.overloadingStartFillLevelPct then
					local v158_ = self:getFillUnitCapacity(v144_.fillUnitIndex)
					if (v158_ == 0 or (v158_ == math.huge or self:getFillUnitFreeCapacity(v144_.fillUnitIndex) > 0)) and (not v144_.buffer.unloadingStarted and v144_.unloadingState == Baler.UNLOADING_CLOSED) then
						v144_.buffer.unloadingStarted = true
						v144_.buffer.overloadingTimer = 0
						if v144_.buffer.overloadAnimation ~= nil then
							self:playAnimation(v144_.buffer.overloadAnimation, v144_.buffer.overloadAnimationSpeed)
						end
					end
				end
				if v144_.buffer.unloadingStarted then
					v144_.buffer.overloadingTimer = v144_.buffer.overloadingTimer + dt
					if v144_.buffer.overloadingTimer >= v144_.buffer.overloadingDelay and self:getFillUnitFreeCapacity(v144_.fillUnitIndex) > 0 then
						local v159_ = self:getFillUnitCapacity(v144_.buffer.fillUnitIndex) / v144_.buffer.overloadingDuration * dt
						local v160_ = math.min(v159_, v156_)
						local v161_ = self:getFillUnitFillType(v144_.buffer.fillUnitIndex)
						local v162_ = self:getFillVolumeUnloadInfo(v144_.buffer.unloadInfoIndex)
						local v163_ = self:addFillUnitFillLevel(self:getOwnerFarmId(), v144_.buffer.fillUnitIndex, -v160_, v161_, ToolType.UNDEFINED, v162_)
						local v164_ = self:getFillUnitFillType(v144_.fillUnitIndex)
						if v164_ ~= FillType.UNKNOWN then
							v161_ = v164_
						end
						local v165_ = -v163_
						if v144_.additives.available and v144_.additives.appliedByBufferOverloading then
							local v166_ = false
							for v167_ = 1, #v144_.additives.fillTypes do
								if v161_ == v144_.additives.fillTypes[v167_] then
									v166_ = true
									break
								end
							end
							if v166_ then
								local v168_ = self:getFillUnitFillLevel(v144_.additives.fillUnitIndex)
								if v168_ > 0 then
									local v169_ = v144_.additives.usage * v165_
									if v169_ > 0 then
										local v170_ = v168_ / v169_
										v165_ = v165_ * (1 + 0.05 * math.min(v170_, 1))
										self:addFillUnitFillLevel(self:getOwnerFarmId(), v144_.additives.fillUnitIndex, -v169_, self:getFillUnitFillType(v144_.additives.fillUnitIndex), ToolType.UNDEFINED)
										v144_.additives.isActiveTimer = 250
										v144_.additives.isActive = true
										self:raiseDirtyFlags(v144_.dirtyFlag)
										if self.isClient then
											g_effectManager:setEffectTypeInfo(v144_.additiveEffects, FillType.LIQUIDFERTILIZER)
											g_effectManager:startEffects(v144_.additiveEffects)
										end
									end
								end
							end
						end
						self:addFillUnitFillLevel(self:getOwnerFarmId(), v144_.fillUnitIndex, v165_, v161_, ToolType.UNDEFINED, nil)
						if v144_.buffer.fillLevelToEmpty > 0 then
							local v171_ = v144_.buffer
							local v172_ = v144_.buffer.fillLevelToEmpty - v160_
							v171_.fillLevelToEmpty = math.max(v172_, 0)
							if v144_.buffer.fillLevelToEmpty == 0 then
								v144_.platformDelayedDropping = true
								v144_.buffer.unloadingStarted = false
							end
						end
					end
					if self:getFillUnitFillLevelPercentage(v144_.fillUnitIndex) == 1 or not v146_ then
						v144_.buffer.unloadingStarted = false
					end
				end
			elseif not v144_.buffer.fillMainUnitAfterOverload then
				v144_.buffer.unloadingStarted = false
			end
			if v155_ ~= v144_.buffer.unloadingStarted then
				if self.isClient then
					if v144_.buffer.unloadingStarted then
						local v173_ = self:getFillUnitFillType(v144_.buffer.fillUnitIndex)
						g_effectManager:setEffectTypeInfo(v144_.buffer.overloadingEffects, v173_)
						g_effectManager:startEffects(v144_.buffer.overloadingEffects)
						g_animationManager:startAnimations(v144_.buffer.overloadingAnimationNodes)
						g_soundManager:playSamples(v144_.buffer.samplesOverloadingStart)
						g_soundManager:playSamples(v144_.buffer.samplesOverloadingWork, 0, v144_.buffer.samplesOverloadingStart[1])
					else
						g_effectManager:stopEffects(v144_.buffer.overloadingEffects)
						g_animationManager:stopAnimations(v144_.buffer.overloadingAnimationNodes)
						g_soundManager:stopSamples(v144_.buffer.samplesOverloadingStart)
						if g_soundManager:getIsSamplePlaying(v144_.buffer.samplesOverloadingWork[1]) then
							g_soundManager:stopSamples(v144_.buffer.samplesOverloadingWork)
							g_soundManager:playSamples(v144_.buffer.samplesOverloadingStop)
						end
					end
				end
				self:raiseDirtyFlags(v144_.dirtyFlag)
			end
			if v144_.buffer.overloadAnimation ~= nil and (not self:getIsAnimationPlaying(v144_.buffer.overloadAnimation) and self:getAnimationTime(v144_.buffer.overloadAnimation) > 0.5) then
				self:playAnimation(v144_.buffer.overloadAnimation, -v144_.buffer.overloadAnimationSpeed)
			end
			if v146_ then
				self:raiseActive()
			end
		end
	end
	if self.isServer and v144_.showBaleLimitWarning ~= v145_ then
		v144_.showBaleLimitWarning = v145_
		self:raiseDirtyFlags(v144_.dirtyFlag)
	end
	if v144_.hasPlatform then
		if v144_.platformDelayedDropping and not v144_.platformDropInProgress then
			Baler.actionEventUnloading(self)
			v144_.platformDelayedDropping = false
		end
		if v144_.platformDropInProgress and not self:getIsAnimationPlaying(v144_.platformAnimation) then
			v144_.platformDropInProgress = false
		end
	end
end

-- Local values: spec
function Baler:onDraw()
	local v175_ = self.spec_baler
	if v175_.showBaleLimitWarning then
		g_currentMission:showBlinkingWarning(v175_.texts.warningTooManyBales, 100)
	end
end

-- Local values: spec
function Baler:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	local v180_ = self.spec_baler
	if #v180_.bales > 0 and self:getFillUnitFillLevel(v180_.fillUnitIndex) > v180_.baleFoldThreshold then
		return false, v180_.texts.warningFoldingBaleLoaded
	elseif #v180_.bales > 1 then
		return false, v180_.texts.warningFoldingBaleLoaded
	elseif self:getIsTurnedOn() then
		return false, v180_.texts.warningFoldingTurnedOn
	elseif v180_.hasPlatform and (v180_.platformReadyToDrop or v180_.platformDropInProgress) then
		return false, v180_.texts.warningFoldingBaleLoaded
	else
		return superFunc(self, direction, onAiTurnOn)
	end
end

-- Local values: spec, mainFillTypeIndex, baleTypeDef, baleCapacity
function Baler:onChangedFillType(fillUnitIndex, fillTypeIndex, oldFillTypeIndex)
	local v184_ = self.spec_baler
	if fillUnitIndex == v184_.fillUnitIndex or fillUnitIndex == v184_.buffer.fillUnitIndex then
		local v185_ = self:getFillUnitFillType(v184_.fillUnitIndex)
		if v185_ == FillType.UNKNOWN then
			v185_ = fillTypeIndex
		end
		if v185_ ~= FillType.UNKNOWN then
			local v186_ = v184_.baleTypes[v184_.currentBaleTypeIndex]
			v184_.currentBaleTypeDefinition = v186_
			local v187_, v188_ = g_baleManager:getBaleXMLFilename(v185_, v186_.isRoundBale, v186_.width, v186_.height, v186_.length, v186_.diameter, self.customEnvironment)
			v184_.currentBaleXMLFilename = v187_
			v184_.currentBaleIndex = v188_
			local v189_ = g_baleManager:getBaleCapacityByBaleIndex(v184_.currentBaleIndex, v185_)
			if fillUnitIndex == v184_.fillUnitIndex then
				self:setFillUnitCapacity(fillUnitIndex, v189_, false)
			elseif v184_.buffer.capacityPercentage ~= nil then
				self:setFillUnitCapacity(fillUnitIndex, v189_ * v184_.buffer.capacityPercentage, false)
			end
			ObjectChangeUtil.setObjectChanges(v186_.changeObjects, true, self, self.setMovingToolDirty)
			if v184_.currentBaleXMLFilename == nil then
				Logging.warning("Could not find bale for given bale type definition \'%s\'", v186_.index)
			end
		end
	end
end

-- Local values: spec, baleTypeDef, fillLevel, capacity, i, overflow, fillLevel, capacity
function Baler:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData, appliedDelta)
	local v196_ = self.spec_baler
	if fillUnitIndex == v196_.fillUnitIndex then
		local v197_ = v196_.baleTypes[v196_.currentBaleTypeIndex]
		local v198_ = self:getFillUnitFillLevel(v196_.fillUnitIndex)
		local v199_ = self:getFillUnitCapacity(v196_.fillUnitIndex)
		if self:updateDummyBale(v196_.dummyBale, fillTypeIndex, v198_, v199_) then
			for v200_ = 1, #v196_.baleTypes do
				self:setAnimationTime(v196_.baleTypes[v200_].animations.fill, 0)
			end
		end
		if v198_ > 0 then
			self:setAnimationTime(v197_.animations.fill, v198_ / v199_)
		end
		if self.isServer and fillLevelDelta > 0 then
			if self:getFillUnitFreeCapacity(v196_.fillUnitIndex) <= 0 then
				if self.isAddedToPhysics then
					self:finishBale()
				else
					v196_.createBaleNextFrame = true
				end
				v196_.fillUnitOverflowFillLevel = fillLevelDelta - appliedDelta
				return
			end
			if v196_.fillUnitOverflowFillLevel > 0 and fillLevelDelta > 0 then
				local v201_ = v196_.fillUnitOverflowFillLevel
				v196_.fillUnitOverflowFillLevel = 0
				v196_.fillUnitOverflowFillLevel = v201_ - self:addFillUnitFillLevel(self:getOwnerFarmId(), v196_.fillUnitIndex, v201_, fillTypeIndex, toolType)
				return
			end
		end
	elseif v196_.nonStopBaling and (fillUnitIndex == v196_.buffer.fillUnitIndex and v196_.buffer.dummyBale.available) then
		local v202_ = self:getFillUnitFillLevel(v196_.buffer.fillUnitIndex)
		local v203_ = self:getFillUnitCapacity(v196_.buffer.fillUnitIndex)
		if v196_.buffer.overloadAnimation ~= nil and (self:getAnimationTime(v196_.buffer.overloadAnimation) > 0 and v202_ > 0) then
			return
		end
		self:updateDummyBale(v196_.buffer.dummyBale, fillTypeIndex, v202_, v203_)
	end
end

-- Local values: spec
function Baler:onConsumableVariationChanged(variationIndex, metaData)
	if metaData.bale_variation ~= nil then
		self.spec_baler.lastBaleVariationId = metaData.bale_variation
	end
end

-- Local values: spec
function Baler:onTurnedOn()
	if self.setFoldState ~= nil and #self.spec_foldable.foldingParts > 0 then
		self:setFoldState(self.spec_foldable.turnOnFoldDirection, false, true)
	end
	if self.isClient then
		local v207_ = self.spec_baler
		g_animationManager:startAnimations(v207_.animationNodes)
		g_soundManager:playSample(v207_.samples.work)
	end
	self:raiseActive()
end

-- Local values: spec
function Baler:onTurnedOff()
	if self.isClient then
		local v209_ = self.spec_baler
		g_effectManager:stopEffects(v209_.fillEffects)
		g_effectManager:stopEffects(v209_.additiveEffects)
		g_effectManager:stopEffects(v209_.buffer.overloadingEffects)
		g_animationManager:stopAnimations(v209_.animationNodes)
		g_soundManager:stopSample(v209_.samples.work)
		g_soundManager:stopSample(v209_.samples.eject)
		g_soundManager:stopSample(v209_.samples.unload)
		g_soundManager:stopSample(v209_.samples.door)
		g_soundManager:stopSample(v209_.samples.knotCleaning)
		g_soundManager:stopSamples(v209_.buffer.samplesOverloadingStart)
		if g_soundManager:getIsSamplePlaying(v209_.buffer.samplesOverloadingWork[1]) then
			g_soundManager:stopSamples(v209_.buffer.samplesOverloadingWork)
			g_soundManager:playSamples(v209_.buffer.samplesOverloadingStop)
		end
	end
end

-- Local values: spec, actionController
function Baler:onRootVehicleChanged(rootVehicle)
	local v212_ = self.spec_baler
	local v213_ = rootVehicle.actionController
	if v213_ == nil then
		if v212_.controlledAction ~= nil then
			v212_.controlledAction:remove()
			v212_.controlledAction = nil
		end
		return
	elseif v212_.controlledAction == nil then
		v212_.controlledAction = v213_:registerAction("baleUnload", nil, 1)
		v212_.controlledAction:setCallback(self, Baler.actionControllerBaleUnloadEvent)
		v212_.controlledAction:setFinishedFunctions(self, Baler.getIsBaleUnloading, false, false)
	else
		v212_.controlledAction:updateParent(v213_)
	end
end

-- Local values: spec
function Baler:actionControllerBaleUnloadEvent(direction)
	if direction < 0 then
		local v216_ = self.spec_baler
		if self:isUnloadingAllowed() and (v216_.allowsBaleUnloading and (v216_.unloadingState == Baler.UNLOADING_CLOSED and #v216_.bales > 0)) then
			self:setIsUnloadingBale(true)
		end
	end
	return true
end

function Baler:doCheckSpeedLimit(superFunc)
	local v219_ = not superFunc(self) and self:getIsTurnedOn()
	if v219_ then
		v219_ = self:getIsLowered()
	end
	return v219_
end

-- Local values: spec
function Baler:setBaleTypeIndex(baleTypeIndex, force, noEventSend)
	local v224_ = self.spec_baler
	v224_.preSelectedBaleTypeIndex = baleTypeIndex
	if self:getFillUnitFillLevel(v224_.fillUnitIndex) == 0 or force then
		v224_.currentBaleTypeIndex = baleTypeIndex
	end
	Baler.updateActionEvents(self)
	BalerBaleTypeEvent.sendEvent(self, baleTypeIndex, force, noEventSend)
end

-- Local values: spec
function Baler:isUnloadingAllowed()
	local v226_ = self.spec_baler
	if (v226_.platformReadyToDrop or v226_.platformDropInProgress) and v226_.unloadingState ~= Baler.UNLOADING_OPEN then
		return false
	end
	if self.spec_baleWrapper ~= nil then
		return self:allowsGrabbingBale()
	end
	local v227_ = (v226_.allowsBaleUnloading and true or false) and (v226_.allowsBaleUnloading and not self:getIsTurnedOn())
	if v227_ then
		v227_ = not v226_.isBaleUnloading
	end
	return v227_
end

-- Local values: spec
function Baler:handleUnloadingBaleEvent()
	local v229_ = self.spec_baler
	if self:isUnloadingAllowed() and (v229_.hasUnloadingAnimation or v229_.allowsBaleUnloading) then
		if v229_.unloadingState == Baler.UNLOADING_CLOSED then
			if #v229_.bales > 0 or self:getCanUnloadUnfinishedBale() then
				self:setIsUnloadingBale(true)
				return
			end
		elseif v229_.unloadingState == Baler.UNLOADING_OPEN and v229_.hasUnloadingAnimation then
			self:setIsUnloadingBale(false)
		end
	end
end

-- Local values: spec
function Baler:dropBaleFromPlatform(waitForNextBale, noEventSend)
	local v233_ = self.spec_baler
	if v233_.platformReadyToDrop then
		self:setAnimationTime(v233_.platformAnimation, 0, false)
		self:playAnimation(v233_.platformAnimation, 1, self:getAnimationTime(v233_.platformAnimation), true)
		if waitForNextBale == true then
			self:setAnimationStopTime(v233_.platformAnimation, v233_.platformAnimationNextBaleTime)
		end
		v233_.platformReadyToDrop = false
		v233_.platformDropInProgress = true
		if self.isServer and v233_.hasDynamicMountPlatform then
			self:forceUnmountDynamicMountedObjects()
		end
	end
	BalerDropFromPlatformEvent.sendEvent(self, waitForNextBale, noEventSend)
end

-- Local values: spec, ownerFarmId, farmlandId
function Baler:getBalerBaleOwnerFarmId(x, z)
	local v237_
	if self.spec_baler.useDropLandOwnershipForBales then
		local v238_ = g_farmlandManager:getFarmlandIdAtWorldPosition(x, z)
		v237_ = g_farmlandManager:getFarmlandOwner(v238_)
	else
		v237_ = self:getLastTouchedFarmlandFarmId()
	end
	if v237_ == FarmManager.SPECTATOR_FARM_ID then
		v237_ = self:getOwnerFarmId()
	end
	return v237_
end

-- Local values: spec
function Baler:getIsRoundBaler()
	return self.spec_baler.isRoundBaler
end

-- Local values: spec, fillTypeIndex, fillLevel, delta, mainFillLevel, baleTypeDef
function Baler:setIsUnloadingBale(isUnloadingBale, noEventSend)
	local v243_ = self.spec_baler
	if v243_.hasUnloadingAnimation then
		if isUnloadingBale then
			if v243_.unloadingState ~= Baler.UNLOADING_OPENING then
				if #v243_.bales == 0 and v243_.canUnloadUnfinishedBale then
					local v244_ = self:getFillUnitFillType(v243_.fillUnitIndex)
					local v245_ = self:getFillUnitFillLevel(v243_.fillUnitIndex)
					if v243_.buffer.fillUnitIndex ~= nil then
						v245_ = v245_ + self:getFillUnitFillLevel(v243_.buffer.fillUnitIndex)
						if v244_ == FillType.UNKNOWN then
							v244_ = self:getFillUnitFillType(v243_.buffer.fillUnitIndex)
						end
					end
					if v243_.unfinishedBaleThreshold < v245_ then
						local v246_ = self:getFillUnitFreeCapacity(v243_.fillUnitIndex)
						local v247_ = v243_.fillUnitIndex
						local v248_ = math.min(v245_, self:getFillUnitCapacity(v247_))
						if v243_.buffer.fillUnitIndex ~= nil then
							local v249_ = self:getFillUnitFillLevel(v243_.fillUnitIndex)
							local v250_ = self:getOwnerFarmId()
							local v251_ = v243_.buffer.fillUnitIndex
							local v252_ = v248_ - v249_
							self:addFillUnitFillLevel(v250_, v251_, -math.max(v252_, 0), self:getFillUnitFillType(v243_.buffer.fillUnitIndex), ToolType.UNDEFINED)
						end
						v243_.lastBaleFillLevel = v248_
						self:setFillUnitFillLevelToDisplay(v243_.fillUnitIndex, v248_)
						self:addFillUnitFillLevel(self:getOwnerFarmId(), v243_.fillUnitIndex, v246_, v244_, ToolType.UNDEFINED)
						v243_.buffer.unloadingStarted = false
					end
				end
				BalerSetIsUnloadingBaleEvent.sendEvent(self, isUnloadingBale, noEventSend)
				v243_.unloadingState = Baler.UNLOADING_OPENING
				if self.isClient then
					g_soundManager:playSample(v243_.samples.eject)
					g_soundManager:playSample(v243_.samples.door)
				end
				local v253_ = v243_.baleTypes[v243_.currentBaleTypeIndex]
				self:playAnimation(v253_.animations.unloading, v253_.animations.unloadingSpeed, nil, true)
				return
			end
		elseif v243_.unloadingState ~= Baler.UNLOADING_CLOSING and v243_.unloadingState ~= Baler.UNLOADING_CLOSED then
			BalerSetIsUnloadingBaleEvent.sendEvent(self, isUnloadingBale, noEventSend)
			v243_.unloadingState = Baler.UNLOADING_CLOSING
			if self.isClient then
				g_soundManager:playSample(v243_.samples.door)
			end
			self:playAnimation(v243_.baleCloseAnimationName, v243_.baleCloseAnimationSpeed, nil, true)
			return
		end
	elseif v243_.allowsBaleUnloading and isUnloadingBale then
		BalerSetIsUnloadingBaleEvent.sendEvent(self, isUnloadingBale, noEventSend)
		v243_.isBaleUnloading = true
		v243_.balesToUnload = #v243_.bales
		if self.isClient then
			g_soundManager:playSample(v243_.samples.unload)
		end
		SpecializationUtil.raiseEvent(self, "onBalerUnloadingStarted", v243_.balesToUnload)
	end
end

function Baler:getIsBaleUnloading()
	return self.spec_baler.isBaleUnloading
end

-- Local values: spec, baleLength
function Baler:getTimeFromLevel(level)
	local v257_ = self.spec_baler
	if v257_.currentBaleTypeDefinition == nil then
		return 0
	end
	local v258_ = v257_.currentBaleTypeDefinition.length + v257_.baleAnimSpacing
	return level / self:getFillUnitCapacity(v257_.fillUnitIndex) * (v258_ / v257_.baleAnimLength)
end

-- Local values: spec, i
function Baler:moveBales(dt)
	for v261_ = #self.spec_baler.bales, 1, -1 do
		self:moveBale(v261_, dt)
	end
end

-- Local values: spec, bale
function Baler:moveBale(i, dt, noEventSend)
	self:setBaleTime(i, self.spec_baler.bales[i].time + dt, noEventSend)
end

-- Local values: spec, bale, x, y, z, rx, ry, rz
function Baler:setBaleTime(i, baleTime, noEventSend)
	local v270_ = self.spec_baler
	if v270_.baleAnimCurve ~= nil then
		local v271_ = v270_.bales[i]
		if v271_ ~= nil then
			v271_.time = baleTime
			if self.isServer then
				local v272_, v273_, v274_, v275_, v276_, v277_ = v270_.baleAnimCurve:get(v271_.time)
				setTranslation(v271_.baleJointNode, v272_, v273_, v274_)
				setRotation(v271_.baleJointNode, v275_, v276_, v277_)
				if v271_.baleJointIndex ~= 0 then
					setJointFrame(v271_.baleJointIndex, 0, v271_.baleJointNode)
				end
			end
			if v271_.time >= 1 then
				self:dropBale(i)
			end
			if #v270_.bales == 0 then
				v270_.isBaleUnloading = false
				if self.isClient then
					g_soundManager:stopSample(v270_.samples.unload)
				end
				SpecializationUtil.raiseEvent(self, "onBalerUnloadingFinished", v270_.balesToUnload)
			end
			if self.isServer and (noEventSend == nil or not noEventSend) then
				g_server:broadcastEvent(BalerSetBaleTimeEvent.new(self, i, v271_.time), nil, nil, self)
			end
		end
	end
end

-- Local values: spec, fillTypeIndex, fillType, _, bale, bale
function Baler:finishBale()
	local v279_ = self.spec_baler
	if v279_.baleTypes ~= nil then
		local v280_ = self:getFillUnitFillType(v279_.fillUnitIndex)
		if v279_.hasUnloadingAnimation then
			if self:createBale(v280_, self:getFillUnitCapacity(v279_.fillUnitIndex)) then
				local v281_ = v279_.bales[#v279_.bales]
				g_server:broadcastEvent(BalerCreateBaleEvent.new(self, v280_, 0, NetworkUtil.getObjectId(v281_.baleObject)), nil, nil, self)
				return
			end
			Logging.error("Failed to create bale!")
		else
			self:addFillUnitFillLevel(self:getOwnerFarmId(), v279_.fillUnitIndex, -math.huge, v280_, ToolType.UNDEFINED)
			v279_.buffer.unloadingStarted = false
			for v282_, _ in pairs(v279_.pickupFillTypes) do
				v279_.pickupFillTypes[v282_] = 0
			end
			if not self:createBale(v280_, self:getFillUnitCapacity(v279_.fillUnitIndex)) then
				Logging.error("Failed to create bale!")
				return
			end
			local v283_ = v279_.bales[#v279_.bales]
			g_server:broadcastEvent(BalerCreateBaleEvent.new(self, v280_, v283_.time), nil, nil, self)
			if self:getFillUnitFillLevel(v279_.fillUnitIndex) == 0 and v279_.preSelectedBaleTypeIndex ~= v279_.currentBaleTypeIndex then
				self:setBaleTypeIndex(v279_.preSelectedBaleTypeIndex, true)
				return
			end
		end
	end
end

-- Local values: spec, isValid, baleTypeDef, bale, baleObject, x, y, z, rx, ry, rz, baleObject, x, y, z, rx, ry, rz, baleJointNode, baleObject, constr, i, baleJointIndex, i, otherBale
function Baler:createBale(baleFillType, fillLevel, baleServerId, baleTime, xmlFilename, ownerFarmId, variationId, loadFromSavegame)
	local v293_ = self.spec_baler
	if v293_.knotingAnimation ~= nil and not loadFromSavegame then
		self:playAnimation(v293_.knotingAnimation, v293_.knotingAnimationSpeed, nil, true)
	end
	local v294_ = false
	local v295_ = v293_.baleTypes[v293_.currentBaleTypeIndex]
	if baleTime == nil then
		self:deleteDummyBale(v293_.dummyBale)
	end
	local v296_ = {
		["filename"] = xmlFilename or v293_.currentBaleXMLFilename,
		["time"] = baleTime
	}
	if v296_.time == nil and v293_.baleAnimLength ~= nil then
		v296_.time = v295_.length * 0.5 / v293_.baleAnimLength
	end
	v296_.fillType = baleFillType
	v296_.fillLevel = fillLevel
	if v293_.hasUnloadingAnimation then
		if not loadFromSavegame then
			self:updateConsumable(Baler.CONSUMABLE_TYPE_NAME_ROUND, -v295_.consumableUsage)
		end
		if self.isServer then
			local v297_ = Bale.new(self.isServer, self.isClient)
			local v298_, v299_, v300_ = getWorldTranslation(v295_.baleRootNode)
			local v301_, v302_, v303_ = getWorldRotation(v295_.baleRootNode)
			if v297_:loadFromConfigXML(v296_.filename, v298_, v299_, v300_, v301_, v302_, v303_) then
				v297_:setFillType(baleFillType)
				v297_:setFillLevel(fillLevel)
				v297_:setVariationId(variationId or (v293_.lastBaleVariationId or v295_.defaultBaleVariationId))
				if ownerFarmId == nil then
					v297_:setOwnerFarmId(self:getBalerBaleOwnerFarmId(v298_, v300_), true)
				else
					v297_:setOwnerFarmId(ownerFarmId, true)
				end
				v297_:register()
				v297_:mountKinematic(self, v295_.baleRootNode, 0, 0, 0, 0, 0, 0)
				v296_.baleObject = v297_
				v294_ = true
			end
		elseif baleServerId ~= nil then
			local v304_ = NetworkUtil.getObject(baleServerId)
			if v304_ == nil then
				v293_.baleToMount = {
					["baleServerId"] = baleServerId,
					["jointNode"] = v295_.baleRootNode,
					["baleInfo"] = v296_
				}
				v294_ = true
			else
				v296_.baleServerId = baleServerId
				v304_:mountKinematic(self, v295_.baleRootNode, 0, 0, 0, 0, 0, 0)
				v294_ = true
			end
		end
	elseif not loadFromSavegame then
		self:updateConsumable(Baler.CONSUMABLE_TYPE_NAME_SQUARE, -v295_.consumableUsage)
	end
	if self.isServer and not v293_.hasUnloadingAnimation then
		local v305_, v306_, v307_ = getWorldTranslation(v295_.baleRootNode)
		local v308_, v309_, v310_ = getWorldRotation(v295_.baleRootNode)
		local v311_ = createTransformGroup("BaleJointTG")
		link(v295_.baleRootNode, v311_)
		if v296_.time == nil then
			setTranslation(v311_, 0, 0, 0)
			setRotation(v311_, 0, 0, 0)
		else
			local v312_, v313_, v314_, v315_, v316_, v317_ = v293_.baleAnimCurve:get(v296_.time)
			setTranslation(v311_, v312_, v313_, v314_)
			setRotation(v311_, v315_, v316_, v317_)
			v305_, v306_, v307_ = getWorldTranslation(v311_)
			v308_, v309_, v310_ = getWorldRotation(v311_)
		end
		local v318_ = Bale.new(self.isServer, self.isClient)
		if v318_:loadFromConfigXML(v296_.filename, v305_, v306_, v307_, v308_, v309_, v310_) then
			v318_:setFillType(baleFillType)
			v318_:setFillLevel(fillLevel)
			v318_:setVariationId(variationId or (v293_.lastBaleVariationId or v295_.defaultBaleVariationId))
			if ownerFarmId == nil then
				v318_:setOwnerFarmId(self:getBalerBaleOwnerFarmId(v305_, v307_), true)
			else
				v318_:setOwnerFarmId(ownerFarmId, true)
			end
			v318_:register()
			v318_:setCanBeSold(false)
			v318_:setNeedsSaving(false)
			local v319_ = JointConstructor.new()
			v319_:setActors(v295_.baleNodeComponent, v318_.nodeId)
			v319_:setJointTransforms(v311_, v318_.nodeId)
			for v320_ = 1, 3 do
				v319_:setRotationLimit(v320_ - 1, 0, 0)
				v319_:setTranslationLimit(v320_ - 1, true, 0, 0)
			end
			v319_:setEnableCollision(false)
			local v321_ = v319_:finalize()
			v296_.baleJointNode = v311_
			v296_.baleJointIndex = v321_
			v296_.baleObject = v318_
			v318_.baleJointIndex = v321_
			for v322_ = 1, #v293_.bales do
				local v323_ = v293_.bales[v322_]
				setPairCollision(v323_.baleObject.nodeId, v318_.nodeId, false)
			end
			if v293_.baleAnimEnableCollision then
				v294_ = true
			else
				setCollisionFilterMask(v318_.nodeId, 0)
				v294_ = true
			end
		end
	elseif not (self.isServer or v293_.hasUnloadingAnimation) then
		v294_ = true
	end
	if v294_ then
		local v324_ = v293_.bales
		table.insert(v324_, v296_)
	end
	return v294_
end

-- Local values: spec, bale, mission, baleObject, i, otherBale, baleTypeDef, x, y, z, vx, vy, vz, baleObject
function Baler:dropBale(baleIndex)
	local v327_ = self.spec_baler
	local v328_ = v327_.bales[baleIndex]
	if v328_.baleObject ~= nil then
		local v329_ = g_missionManager:getMissionByUniqueId(v327_.workAreaParameters.lastMissionUniqueId)
		if v329_ ~= nil and v329_.addBale ~= nil then
			v329_:addBale(v328_.baleObject)
		end
	end
	if self.isServer then
		local v330_ = v328_.baleObject
		if v328_.baleJointIndex == nil then
			v330_:unmountKinematic()
		else
			removeJoint(v328_.baleJointIndex)
			delete(v328_.baleJointNode)
		end
		if not v327_.baleAnimEnableCollision then
			setCollisionFilterMask(v330_.nodeId, CollisionPreset.BALE.mask)
		end
		for v331_ = 1, #v327_.bales do
			if v331_ ~= baleIndex then
				local v332_ = v327_.bales[v331_]
				setPairCollision(v332_.baleObject.nodeId, v330_.nodeId, true)
			end
		end
		if v327_.lastBaleFillLevel ~= nil and #v327_.bales == 1 then
			v330_:setFillLevel(v327_.lastBaleFillLevel)
			v327_.lastBaleFillLevel = nil
		end
		v330_.baleJointIndex = nil
		v330_:setCanBeSold(true)
		v330_:setNeedsSaving(true)
		if v330_.nodeId ~= nil and v330_.nodeId ~= 0 then
			local v333_ = v327_.baleTypes[v327_.currentBaleTypeIndex]
			local v334_, v335_, v336_ = getWorldTranslation(v330_.nodeId)
			local v337_, v338_, v339_ = getVelocityAtWorldPos(v333_.baleNodeComponent or self.components[1].node, v334_, v335_, v336_)
			setLinearVelocity(v330_.nodeId, v337_, v338_, v339_)
			g_farmManager:updateFarmStats(self:getBalerBaleOwnerFarmId(v334_, v336_), "baleCount", 1)
		end
	elseif v327_.hasUnloadingAnimation then
		local v340_ = NetworkUtil.getObject(v328_.baleServerId)
		if v340_ ~= nil then
			v340_:unmountKinematic()
		end
	end
	table.remove(v327_.bales, baleIndex)
	if v327_.hasPlatform then
		if not v327_.platformReadyToDrop then
			v327_.platformReadyToDrop = true
		end
		if v327_.hasDynamicMountPlatform then
			v327_.platformMountDelay = 5
		end
	end
end

-- Local values: spec, baleTypeDef, generatedBale, baleNode, scaleNode, percentage, x, y, z, scaleComponents, axis, value
function Baler:updateDummyBale(dummyBaleData, fillTypeIndex, fillLevel, capacity)
	local v346_ = self.spec_baler
	local v347_ = dummyBaleData.baleTypeDef or v346_.baleTypes[v346_.currentBaleTypeIndex]
	local v348_
	if (dummyBaleData.linkNode or v347_.baleNode) == nil or (fillLevel <= 0 or (fillLevel >= capacity or dummyBaleData.currentBale ~= nil and dummyBaleData.currentBaleFillType == fillTypeIndex)) then
		v348_ = false
	else
		if dummyBaleData.currentBale ~= nil then
			self:deleteDummyBale(dummyBaleData)
		end
		self:createDummyBale(dummyBaleData, fillTypeIndex)
		v348_ = true
	end
	if dummyBaleData.currentBale ~= nil then
		local v349_ = dummyBaleData.linkNode or v347_.scaleNode
		if v349_ ~= nil and capacity > 0 then
			local v350_ = fillLevel / capacity
			local v351_ = v347_.isRoundBale and v350_ and v350_ or 1
			local v352_ = dummyBaleData.scaleComponents or v347_.scaleComponents
			local v353_, v354_
			if v352_ == nil then
				v353_ = v350_
				v354_ = 1
			else
				v354_ = 1
				v351_ = 1
				v353_ = 1
				for v355_, v356_ in ipairs(v352_) do
					if v356_ > 0 then
						if v355_ == 1 then
							v354_ = v350_ * v356_
						elseif v355_ == 2 then
							v351_ = v350_ * v356_
						else
							v353_ = v350_ * v356_
						end
					end
				end
			end
			setScale(v349_, v354_, v351_, v353_)
		end
	end
	return v348_
end

function Baler:deleteDummyBale(dummyBaleData)
	if dummyBaleData ~= nil then
		if dummyBaleData.currentBale ~= nil then
			delete(dummyBaleData.currentBale)
			dummyBaleData.currentBale = nil
		end
		if dummyBaleData.sharedLoadRequestId ~= nil then
			g_i3DManager:releaseSharedI3DFile(dummyBaleData.sharedLoadRequestId)
			dummyBaleData.sharedLoadRequestId = nil
		end
	end
end

-- Local values: spec, baleTypeDef, baleId, sharedLoadRequestId, linkNode
function Baler:createDummyBale(dummyBaleData, fillTypeIndex)
	local v361_ = self.spec_baler
	if v361_.currentBaleXMLFilename ~= nil then
		local v362_ = v361_.baleTypes[v361_.currentBaleTypeIndex]
		local v363_, v364_ = Bale.createDummyBale(v361_.currentBaleXMLFilename, fillTypeIndex, v362_.chamberBaleVariationId)
		local v365_ = dummyBaleData.linkNode or v362_.baleNode
		link(v365_, v363_)
		dummyBaleData.currentBale = v363_
		dummyBaleData.baleTypeDef = v362_
		dummyBaleData.currentBaleFillType = fillTypeIndex
		dummyBaleData.sharedLoadRequestId = v364_
	end
end

-- Local values: spec, fillLevel
function Baler:getCanUnloadUnfinishedBale()
	local v367_ = self.spec_baler
	local v368_ = self:getFillUnitFillLevel(v367_.fillUnitIndex)
	if v367_.buffer.fillUnitIndex ~= nil then
		v368_ = v368_ + self:getFillUnitFillLevel(v367_.buffer.fillUnitIndex)
	end
	local v369_ = v367_.canUnloadUnfinishedBale
	if v369_ then
		v369_ = v367_.unfinishedBaleThreshold < v368_
	end
	return v369_
end

-- Local values: spec
function Baler:setBalerAutomaticDrop(state, noEventSend)
	local v373_ = self.spec_baler
	if state == nil then
		if v373_.hasPlatform then
			state = not v373_.platformAutomaticDrop
		else
			state = not v373_.automaticDrop
		end
	end
	if v373_.hasPlatform then
		v373_.platformAutomaticDrop = state
	else
		v373_.automaticDrop = state
	end
	self:requestActionEventUpdate()
	BalerAutomaticDropEvent.sendEvent(self, state, noEventSend)
end

-- Local values: spec
function Baler:getCanBeTurnedOn(superFunc)
	if self.spec_baler.isBaleUnloading then
		return false
	else
		return superFunc(self)
	end
end

function Baler:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)
	speedRotatingPart.rotateOnlyIfFillLevelIncreased = xmlFile:getValue(key .. "#rotateOnlyIfFillLevelIncreased", false)
	return superFunc(self, speedRotatingPart, xmlFile, key)
end

-- Local values: spec
function Baler:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
	local v384_ = self.spec_baler
	if speedRotatingPart.rotateOnlyIfFillLevelIncreased == nil or (not speedRotatingPart.rotateOnlyIfFillLevelIncreased or v384_.lastAreaBiggerZeroTime ~= 0) then
		return superFunc(self, speedRotatingPart)
	else
		return false
	end
end
function Baler.getDefaultSpeedLimit()
	return 25
end

-- Local values: spec
function Baler:getIsWorkAreaActive(superFunc, workArea)
	local v388_ = self.spec_baler
	if g_currentMission.slotSystem:getCanAddLimitedObjects(SlotSystem.LIMITED_OBJECT_BALE, 1) or not self:getIsTurnedOn() then
		if self:getFillUnitFreeCapacity(v388_.buffer.fillUnitIndex or v388_.fillUnitIndex) == 0 then
			return false
		elseif self.allowPickingUp == nil or self:allowPickingUp() then
			if self:getConsumableIsAvailable(Baler.CONSUMABLE_TYPE_NAME_ROUND) and self:getConsumableIsAvailable(Baler.CONSUMABLE_TYPE_NAME_SQUARE) then
				if v388_.hasUnloadingAnimation and (not v388_.nonStopBaling and (#v388_.bales > 0 or v388_.unloadingState ~= Baler.UNLOADING_CLOSED)) then
					return false
				else
					return superFunc(self, workArea)
				end
			else
				return false
			end
		else
			return false
		end
	else
		return false
	end
end

-- Local values: value, count, spec, loadPercentage
function Baler:getConsumingLoad(superFunc)
	local v391_, v392_ = superFunc(self)
	local v393_ = self.spec_baler
	return v391_ + v393_.pickUpLitersBuffer:get(1000) / v393_.maxPickupLitersPerSecond, v392_ + 1
end

-- Local values: spec, bufferFillLevelPercentage
function Baler:getRequiresPower(superFunc)
	local v396_ = self.spec_baler
	if v396_.nonStopBaling then
		if self:getFillUnitFillLevelPercentage(v396_.buffer.fillUnitIndex) > v396_.buffer.overloadingStartFillLevelPct then
			return true
		end
		if v396_.buffer.unloadingStarted then
			return true
		end
	end
	return v396_.unloadingState ~= Baler.UNLOADING_CLOSED and true or (self:getIsTurnedOn() and true or superFunc(self))
end

function Baler:getCanBeSelected(superFunc)
	return true
end

-- Local values: spec, i
function Baler:getIsAttachedTo(superFunc, vehicle)
	if superFunc(self, vehicle) then
		return true
	end
	local v400_ = self.spec_baler
	for v401_ = 1, #v400_.bales do
		if v400_.bales[v401_].baleObject == vehicle then
			return true
		end
	end
	return false
end

function Baler:getAllowDynamicMountFillLevelInfo(superFunc)
	return false
end

-- Local values: ret
function Baler:getAlarmTriggerIsActive(superFunc, alarmTrigger)
	local v405_ = superFunc(self, alarmTrigger)
	if alarmTrigger.needsBaleLoaded and (self.spec_baler ~= nil and #self.spec_baler.bales == 0) then
		return false
	else
		return v405_
	end
end

-- Local values: ret
function Baler:loadAlarmTrigger(superFunc, xmlFile, key, alarmTrigger, fillUnit)
	local v412_ = superFunc(self, xmlFile, key, alarmTrigger, fillUnit)
	alarmTrigger.needsBaleLoaded = xmlFile:getValue(key .. "#needsBaleLoaded", false)
	return v412_
end

function Baler:getShowConsumableEmptyWarning(superFunc, typeName)
	if typeName ~= Baler.CONSUMABLE_TYPE_NAME_ROUND and typeName ~= Baler.CONSUMABLE_TYPE_NAME_SQUARE then
		return superFunc(self, typeName)
	end
	local v416_ = self:getIsTurnedOn()
	if v416_ then
		v416_ = superFunc(self, typeName)
	end
	return v416_
end

-- Local values: spec, baleTypeDef, baleIndex, bale, baleObject, constr, i, baleJointIndex, otherBaleIndex, otherBale
function Baler:addToPhysics(superFunc)
	if not superFunc(self) then
		return false
	end
	local v419_ = self.spec_baler
	local v420_ = v419_.baleTypes[v419_.currentBaleTypeIndex]
	for v421_, v422_ in pairs(v419_.bales) do
		local v423_ = v422_.baleObject
		if v423_ ~= nil then
			v422_.baleObject:addToPhysics()
			if not v419_.hasUnloadingAnimation then
				local v424_ = JointConstructor.new()
				v424_:setActors(v420_.baleNodeComponent, v423_.nodeId)
				v424_:setJointTransforms(v422_.baleJointNode, v423_.nodeId)
				for v425_ = 1, 3 do
					v424_:setRotationLimit(v425_ - 1, 0, 0)
					v424_:setTranslationLimit(v425_ - 1, true, 0, 0)
				end
				v424_:setEnableCollision(false)
				v422_.baleJointIndex = v424_:finalize()
				v422_.baleObject = v423_
				for v426_, v427_ in pairs(v419_.bales) do
					if v426_ ~= v421_ then
						setPairCollision(v427_.baleObject.nodeId, v423_.nodeId, false)
					end
				end
			end
		end
	end
	return true
end

-- Local values: spec, baleIndex, bale
function Baler:removeFromPhysics(superFunc)
	if not superFunc(self) then
		return false
	end
	local v430_ = self.spec_baler
	for _, v431_ in pairs(v430_.bales) do
		if v431_.baleObject ~= nil then
			v431_.baleObject:removeFromPhysics()
			if not v430_.hasUnloadingAnimation and v431_.baleJointIndex ~= nil then
				removeJoint(v431_.baleJointIndex)
				v431_.baleJointIndex = nil
			end
		end
	end
	return true
end

-- Local values: spec, lsx, lsy, lsz, lex, ley, lez, lineRadius, mission, fillTypeIndex, _, pickedUpLiters, fillTypeSupported, i, additivesFillLevel, usage, availableUsage
function Baler:processBalerArea(workArea, dt)
	local v434_ = self.spec_baler
	if not self.isServer and self.currentUpdateDistance > Baler.CLIENT_DM_UPDATE_RADIUS then
		return 0, 0
	end
	local v435_, v436_, v437_, v438_, v439_, v440_, v441_ = DensityMapHeightUtil.getLineByArea(workArea.start, workArea.width, workArea.height)
	if self.isServer then
		v434_.fillEffectType = FillType.UNKNOWN
	end
	local v442_ = self:getMissionByWorkArea(workArea)
	for v443_, _ in pairs(v434_.pickupFillTypes) do
		local v444_ = -DensityMapHeightUtil.tipToGroundAroundLine(self, -math.huge, v443_, v435_, v436_, v437_, v438_, v439_, v440_, v441_, nil, nil, false, nil)
		if v444_ > 0 then
			if self.isServer then
				v434_.fillEffectType = v443_
				if v434_.additives.available and not v434_.additives.appliedByBufferOverloading then
					local v445_ = false
					for v446_ = 1, #v434_.additives.fillTypes do
						if v443_ == v434_.additives.fillTypes[v446_] then
							v445_ = true
							break
						end
					end
					if v445_ then
						local v447_ = self:getFillUnitFillLevel(v434_.additives.fillUnitIndex)
						if v447_ > 0 then
							local v448_ = v434_.additives.usage * v444_
							if v448_ > 0 then
								local v449_ = v447_ / v448_
								v444_ = v444_ * (1 + 0.05 * math.min(v449_, 1))
								self:addFillUnitFillLevel(self:getOwnerFarmId(), v434_.additives.fillUnitIndex, -v448_, self:getFillUnitFillType(v434_.additives.fillUnitIndex), ToolType.UNDEFINED)
								v434_.additives.isActiveTimer = 250
								v434_.additives.isActive = true
								self:raiseDirtyFlags(v434_.dirtyFlag)
								if self.isClient then
									g_effectManager:setEffectTypeInfo(v434_.additiveEffects, FillType.LIQUIDFERTILIZER)
									g_effectManager:startEffects(v434_.additiveEffects)
								end
							end
						end
					end
				end
			end
			v434_.pickupFillTypes[v443_] = v434_.pickupFillTypes[v443_] + v444_
			local v450_ = v434_.workAreaParameters
			local v451_
			if v442_ == nil then
				v451_ = nil
			else
				v451_ = v442_:getUniqueId() or nil
			end
			v450_.lastMissionUniqueId = v451_
			v434_.workAreaParameters.lastPickedUpLiters = v434_.workAreaParameters.lastPickedUpLiters + v444_
			return v444_, v444_
		end
	end
	return 0, 0
end

-- Local values: spec, _, actionEventId, _, actionEventId, _, actionEventId, automaticDropState
function Baler:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v454_ = self.spec_baler
		self:clearActionEventsTable(v454_.actionEvents)
		if isActiveForInputIgnoreSelection then
			if not (v454_.automaticDrop and v454_.platformAutomaticDrop) then
				local _, v455_ = self:addPoweredActionEvent(v454_.actionEvents, InputAction.IMPLEMENT_EXTRA3, self, Baler.actionEventUnloading, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(v455_, GS_PRIO_HIGH)
			end
			if #v454_.baleTypes > 1 then
				local _, v456_ = self:addPoweredActionEvent(v454_.actionEvents, InputAction.TOGGLE_BALE_TYPES, self, Baler.actionEventToggleSize, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(v456_, GS_PRIO_HIGH)
			end
			if v454_.toggleableAutomaticDrop then
				local _, v457_ = self:addPoweredActionEvent(v454_.actionEvents, InputAction.IMPLEMENT_EXTRA4, self, Baler.actionEventToggleAutomaticDrop, false, true, false, true, nil)
				local v458_ = v454_.automaticDrop
				if v454_.hasPlatform then
					v458_ = v454_.platformAutomaticDrop
				end
				g_inputBinding:setActionEventText(v457_, v458_ and v454_.toggleAutomaticDropTextNeg or v454_.toggleAutomaticDropTextPos)
				g_inputBinding:setActionEventTextPriority(v457_, GS_PRIO_HIGH)
			end
			Baler.updateActionEvents(self)
		end
	end
end

-- Local values: spec
function Baler:onRegisterExternalActionEvents(trigger, name, xmlFile, key)
	local v462_ = self.spec_baler
	if name == "balerDrop" then
		self:registerExternalActionEvent(trigger, name, Baler.externalActionEventUnloadRegister, Baler.externalActionEventUnloadUpdate)
	elseif name == "balerAutomaticDrop" then
		if v462_.toggleableAutomaticDrop then
			self:registerExternalActionEvent(trigger, name, Baler.externalActionEventAutomaticUnloadRegister, Baler.externalActionEventAutomaticUnloadUpdate)
			return
		end
	elseif name == "balerBaleSize" and #v462_.baleTypes > 1 then
		self:registerExternalActionEvent(trigger, name, Baler.externalActionEventBaleTypeRegister, Baler.externalActionEventBaleTypeUpdate)
	end
end

-- Local values: spec
function Baler:onStartWorkAreaProcessing(dt)
	local v464_ = self.spec_baler
	if self.isServer then
		v464_.lastAreaBiggerZero = false
		v464_.workAreaParameters.lastPickedUpLiters = 0
	end
end

-- Local values: spec, maxFillType, maxFillTypeFillLevel, fillTypeIndex, fillLevel, pickedUpLiters, deltaLevel, deltaTime, fillUnitIndex, animTime
function Baler:onEndWorkAreaProcessing(dt, hasProcessed)
	local v466_ = self.spec_baler
	if self.isServer then
		local v467_ = FillType.UNKNOWN
		local v468_ = 0
		for v469_, v470_ in pairs(v466_.pickupFillTypes) do
			if v468_ < v470_ then
				v467_ = v469_
				v468_ = v470_
			end
		end
		local v471_ = v466_.workAreaParameters.lastPickedUpLiters
		if v471_ > 0 then
			v466_.lastAreaBiggerZero = true
			local v472_ = v471_ * v466_.fillScale
			v466_.variableSpeedLimit.pickupPerSecond = v466_.variableSpeedLimit.pickupPerSecond + v472_
			if not v466_.hasUnloadingAnimation then
				self:moveBales((self:getTimeFromLevel(v472_)))
			end
			local v473_ = v466_.fillUnitIndex
			if v466_.nonStopBaling then
				if v466_.buffer.fillMainUnitAfterOverload and v466_.buffer.unloadingStarted then
					if self:getFillUnitFreeCapacity(v466_.fillUnitIndex) <= 0 then
						v473_ = v466_.buffer.fillUnitIndex
					end
				else
					v473_ = v466_.buffer.fillUnitIndex
				end
			end
			if v466_.buffer.loadingStateAnimation ~= nil then
				local v474_ = self:getAnimationTime(v466_.buffer.loadingStateAnimation)
				if v473_ == v466_.fillUnitIndex then
					if v474_ >= 0.99 then
						self:playAnimation(v466_.buffer.loadingStateAnimation, -v466_.buffer.loadingStateAnimationSpeed)
					end
				elseif v474_ <= 0.01 then
					self:playAnimation(v466_.buffer.loadingStateAnimation, v466_.buffer.loadingStateAnimationSpeed)
				end
			end
			self:setFillUnitFillType(v473_, v467_)
			self:addFillUnitFillLevel(self:getOwnerFarmId(), v473_, v472_, v467_, ToolType.UNDEFINED)
		end
		if v466_.lastAreaBiggerZero ~= v466_.lastAreaBiggerZeroSent then
			self:raiseDirtyFlags(v466_.dirtyFlag)
			v466_.lastAreaBiggerZeroSent = v466_.lastAreaBiggerZero
		end
		if v466_.fillEffectType ~= v466_.fillEffectTypeSent then
			v466_.fillEffectTypeSent = v466_.fillEffectType
			self:raiseDirtyFlags(v466_.dirtyFlag)
		end
	end
end

-- Local values: spec
function Baler:actionEventUnloading(actionName, inputValue, callbackState, isAnalog)
	local v476_ = self.spec_baler
	if v476_.hasPlatform then
		if self:getCanUnloadUnfinishedBale() and not v476_.platformReadyToDrop then
			self:handleUnloadingBaleEvent()
		else
			self:dropBaleFromPlatform(false)
		end
	else
		self:handleUnloadingBaleEvent()
		return
	end
end

-- Local values: spec, newIndex
function Baler:actionEventToggleSize(actionName, inputValue, callbackState, isAnalog)
	local v478_ = self.spec_baler
	local v479_ = v478_.preSelectedBaleTypeIndex + 1
	self:setBaleTypeIndex(#v478_.baleTypes < v479_ and 1 or v479_)
end

function Baler:actionEventToggleAutomaticDrop(actionName, inputValue, callbackState, isAnalog)
	self:setBalerAutomaticDrop()
end

-- Local values: spec, actionEvent, showAction, automaticDropState, baleTypeDef, baleSize
function Baler:updateActionEvents()
	local v482_ = self.spec_baler
	local v483_ = v482_.actionEvents[InputAction.IMPLEMENT_EXTRA3]
	if v483_ ~= nil then
		local v484_ = false
		if not v482_.automaticDrop and (self:isUnloadingAllowed() and (v482_.hasUnloadingAnimation or v482_.allowsBaleUnloading)) then
			if v482_.unloadingState == Baler.UNLOADING_CLOSED then
				if self:getCanUnloadUnfinishedBale() then
					g_inputBinding:setActionEventText(v483_.actionEventId, v482_.texts.unloadUnfinishedBale)
					v484_ = true
				end
				if #v482_.bales > 0 then
					g_inputBinding:setActionEventText(v483_.actionEventId, v482_.texts.unloadBaler)
					v484_ = true
				end
			elseif v482_.unloadingState == Baler.UNLOADING_OPEN and v482_.hasUnloadingAnimation then
				g_inputBinding:setActionEventText(v483_.actionEventId, v482_.texts.closeBack)
				v484_ = true
			end
		end
		if v482_.platformReadyToDrop then
			g_inputBinding:setActionEventText(v483_.actionEventId, v482_.texts.unloadBaler)
			v484_ = true
		elseif v482_.hasPlatform and (v482_.automaticDrop and (self:isUnloadingAllowed() and (v482_.hasUnloadingAnimation or v482_.allowsBaleUnloading))) and (v482_.unloadingState == Baler.UNLOADING_CLOSED and self:getCanUnloadUnfinishedBale()) then
			g_inputBinding:setActionEventText(v483_.actionEventId, v482_.texts.unloadUnfinishedBale)
			v484_ = true
		end
		g_inputBinding:setActionEventActive(v483_.actionEventId, v484_)
	end
	if v482_.toggleableAutomaticDrop then
		local v485_ = v482_.actionEvents[InputAction.IMPLEMENT_EXTRA4]
		if v485_ ~= nil then
			local v486_ = v482_.automaticDrop
			if v482_.hasPlatform then
				v486_ = v482_.platformAutomaticDrop
			end
			g_inputBinding:setActionEventText(v485_.actionEventId, v486_ and v482_.toggleAutomaticDropTextNeg or v482_.toggleAutomaticDropTextPos)
		end
	end
	if #v482_.baleTypes > 1 then
		local v487_ = v482_.actionEvents[InputAction.TOGGLE_BALE_TYPES]
		if v487_ ~= nil then
			local v488_ = v482_.baleTypes[v482_.preSelectedBaleTypeIndex]
			local v489_
			if v482_.hasUnloadingAnimation then
				v489_ = v488_.diameter
			else
				v489_ = v488_.length
			end
			g_inputBinding:setActionEventText(v487_.actionEventId, v482_.changeBaleTypeText:format(v489_ * 100))
		end
	end
end

-- Local values: actionEvent, _
function Baler.externalActionEventUnloadRegister(data, vehicle)
	local _, v496_ = g_inputBinding:registerActionEvent(InputAction.IMPLEMENT_EXTRA3, data, function(_, p492_, p493_, p494_, p495_)
		-- upvalues: (copy) vehicle
		if not vehicle.spec_baler.automaticDrop then
			Baler.actionEventUnloading(vehicle, p492_, p493_, p494_, p495_)
		end
	end, false, true, false, true)
	data.actionEventId = v496_
	g_inputBinding:setActionEventTextPriority(data.actionEventId, GS_PRIO_HIGH)
end

-- Local values: spec, showAction
function Baler.externalActionEventUnloadUpdate(data, vehicle)
	local v499_ = vehicle.spec_baler
	local v500_ = false
	if vehicle:isUnloadingAllowed() and (v499_.hasUnloadingAnimation or v499_.allowsBaleUnloading) then
		if v499_.unloadingState == Baler.UNLOADING_CLOSED then
			if vehicle:getCanUnloadUnfinishedBale() then
				g_inputBinding:setActionEventText(data.actionEventId, v499_.texts.unloadUnfinishedBale)
				v500_ = true
			end
			if #v499_.bales > 0 then
				g_inputBinding:setActionEventText(data.actionEventId, v499_.texts.unloadBaler)
				v500_ = true
			end
		elseif v499_.unloadingState == Baler.UNLOADING_OPEN and v499_.hasUnloadingAnimation then
			g_inputBinding:setActionEventText(data.actionEventId, v499_.texts.closeBack)
			v500_ = true
		end
	end
	if v499_.platformReadyToDrop then
		g_inputBinding:setActionEventText(data.actionEventId, v499_.texts.unloadBaler)
		v500_ = true
	end
	g_inputBinding:setActionEventActive(data.actionEventId, v500_)
end

-- Local values: actionEvent, _
function Baler.externalActionEventAutomaticUnloadRegister(data, vehicle)
	local _, v507_ = g_inputBinding:registerActionEvent(InputAction.IMPLEMENT_EXTRA4, data, function(_, p503_, p504_, p505_, p506_)
		-- upvalues: (copy) vehicle
		Baler.actionEventToggleAutomaticDrop(vehicle, p503_, p504_, p505_, p506_)
	end, false, true, false, true)
	data.actionEventId = v507_
	g_inputBinding:setActionEventTextPriority(data.actionEventId, GS_PRIO_HIGH)
end

-- Local values: spec, automaticDropState
function Baler.externalActionEventAutomaticUnloadUpdate(data, vehicle)
	local v510_ = vehicle.spec_baler
	local v511_ = v510_.automaticDrop
	if v510_.hasPlatform then
		v511_ = v510_.platformAutomaticDrop
	end
	g_inputBinding:setActionEventText(data.actionEventId, v511_ and v510_.toggleAutomaticDropTextNeg or v510_.toggleAutomaticDropTextPos)
end

-- Local values: actionEvent, _
function Baler.externalActionEventBaleTypeRegister(data, vehicle)
	local _, v518_ = g_inputBinding:registerActionEvent(InputAction.TOGGLE_BALE_TYPES, data, function(_, p514_, p515_, p516_, p517_)
		-- upvalues: (copy) vehicle
		Baler.actionEventToggleSize(vehicle, p514_, p515_, p516_, p517_)
	end, false, true, false, true)
	data.actionEventId = v518_
	g_inputBinding:setActionEventTextPriority(data.actionEventId, GS_PRIO_HIGH)
end

-- Local values: spec, baleTypeDef, baleSize
function Baler.externalActionEventBaleTypeUpdate(data, vehicle)
	local v521_ = vehicle.spec_baler
	local v522_ = v521_.baleTypes[v521_.preSelectedBaleTypeIndex]
	local v523_
	if v521_.hasUnloadingAnimation then
		v523_ = v522_.diameter
	else
		v523_ = v522_.length
	end
	g_inputBinding:setActionEventText(data.actionEventId, v521_.changeBaleTypeText:format(v523_ * 100))
end

-- Local values: rootName, baleSizeAttributes
function Baler.loadSpecValueBaleSize(xmlFile, customEnvironment, baseDir)
	local v_u_525_ = {
		["isRoundBaler"] = false,
		["minDiameter"] = math.huge,
		["maxDiameter"] = -math.huge,
		["minLength"] = math.huge,
		["maxLength"] = -math.huge
	}
	xmlFile:iterate(xmlFile:getRootName() .. ".baler.baleTypes.baleType", function(_, p526_)
		-- upvalues: (copy) v_u_525_, (copy) xmlFile
		v_u_525_.isRoundBaler = xmlFile:getValue(p526_ .. "#isRoundBale", v_u_525_.isRoundBaler)
		local v527_ = MathUtil.round(xmlFile:getValue(p526_ .. "#diameter", 0), 2)
		local v528_ = v_u_525_
		local v529_ = v_u_525_.minDiameter
		v528_.minDiameter = math.min(v529_, v527_)
		local v530_ = v_u_525_
		local v531_ = v_u_525_.maxDiameter
		v530_.maxDiameter = math.max(v531_, v527_)
		local v532_ = MathUtil.round(xmlFile:getValue(p526_ .. "#length", 0), 2)
		local v533_ = v_u_525_
		local v534_ = v_u_525_.minLength
		v533_.minLength = math.min(v534_, v532_)
		local v535_ = v_u_525_
		local v536_ = v_u_525_.maxLength
		v535_.maxLength = math.max(v536_, v532_)
	end)
	if v_u_525_.minDiameter == math.huge and v_u_525_.minLength == math.huge then
		return nil
	else
		return v_u_525_
	end
end

-- Local values: baleSizeAttributes, minValue, maxValue, unit, size
function Baler.getSpecValueBaleSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange, roundBale)
	local v541_ = roundBale and storeItem.specs.balerBaleSizeRound or storeItem.specs.balerBaleSizeSquare
	if v541_ == nil then
		if returnValues and returnRange then
			return 0, 0, ""
		elseif returnValues then
			return 0, ""
		else
			return ""
		end
	else
		local v542_ = v541_.isRoundBaler and v541_.minDiameter or v541_.minLength
		local v543_ = v541_.isRoundBaler and v541_.maxDiameter or v541_.maxLength
		if returnValues == nil or not returnValues then
			local v544_ = g_i18n:getText("unit_cmShort")
			if v543_ == v542_ then
				return string.format("%d%s", v542_ * 100, v544_)
			else
				return string.format("%d%s-%d%s", v542_ * 100, v544_, v543_ * 100, v544_)
			end
		elseif returnRange == true and v543_ ~= v542_ then
			return v542_ * 100, v543_ * 100, g_i18n:getText("unit_cmShort")
		else
			return v542_ * 100, g_i18n:getText("unit_cmShort")
		end
	end
end

-- Local values: baleSizeAttributes
function Baler.loadSpecValueBaleSizeRound(xmlFile, customEnvironment, baseDir)
	local v548_ = Baler.loadSpecValueBaleSize(xmlFile, customEnvironment, baseDir)
	if v548_ == nil or not v548_.isRoundBaler then
		return nil
	else
		return v548_
	end
end

-- Local values: baleSizeAttributes
function Baler.loadSpecValueBaleSizeSquare(xmlFile, customEnvironment, baseDir)
	local v552_ = Baler.loadSpecValueBaleSize(xmlFile, customEnvironment, baseDir)
	if v552_ == nil or v552_.isRoundBaler then
		return nil
	else
		return v552_
	end
end

function Baler.getSpecValueBaleSizeRound(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	if storeItem.specs.balerBaleSizeRound == nil or not storeItem.specs.balerBaleSizeRound.isRoundBaler then
		return nil
	else
		return Baler.getSpecValueBaleSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange, true)
	end
end

function Baler.getSpecValueBaleSizeSquare(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	if storeItem.specs.balerBaleSizeSquare == nil or storeItem.specs.balerBaleSizeSquare.isRoundBaler then
		return nil
	else
		return Baler.getSpecValueBaleSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange, false)
	end
end
