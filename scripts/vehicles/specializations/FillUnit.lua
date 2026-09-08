-- Local values: FillActivatable_mt
source("dataS/scripts/vehicles/specializations/events/SetFillUnitIsFillingEvent.lua")
source("dataS/scripts/vehicles/specializations/events/SetFillUnitCapacityEvent.lua")
source("dataS/scripts/vehicles/specializations/events/FillUnitUnloadEvent.lua")
source("dataS/scripts/vehicles/specializations/events/FillUnitUnloadedEvent.lua")
FillUnit = {}
FillUnit.FILL_UNIT_CONFIG_XML_KEY = "vehicle.fillUnit.fillUnitConfigurations.fillUnitConfiguration(?)"
FillUnit.FILL_UNIT_XML_KEY = FillUnit.FILL_UNIT_CONFIG_XML_KEY .. ".fillUnits.fillUnit(?)"
FillUnit.ALARM_TRIGGER_XML_KEY = FillUnit.FILL_UNIT_XML_KEY .. ".alarmTriggers.alarmTrigger(?)"
FillUnit.CAPACITY_TO_NETWORK_BITS = {}
FillUnit.CAPACITY_TO_NETWORK_BITS[0] = 16
FillUnit.CAPACITY_TO_NETWORK_BITS[1] = 12
FillUnit.CAPACITY_TO_NETWORK_BITS[2048] = 16
FillUnit.UNIT = {}
FillUnit.UNIT.CUBICMETER = {
	["conversionFunc"] = function(p1_)
		return MathUtil.round(p1_ * 0.001, 1)
	end,
	["l10n"] = "unit_cubicShort"
}
FillUnit.UNIT.LITER = {
	["conversionFunc"] = function(p2_)
		return p2_
	end,
	["l10n"] = "unit_literShort"
}
function FillUnit.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("fillUnit", g_i18n:getText("configuration_fillUnit"), "fillUnit", VehicleConfigurationItem)
	g_storeManager:addSpecType("capacity", "shopListAttributeIconCapacity", FillUnit.loadSpecValueCapacity, FillUnit.getSpecValueCapacity, StoreSpecies.VEHICLE, { "fillUnit" })
	g_storeManager:addSpecType("fillTypes", "shopListAttributeIconFillTypes", FillUnit.loadSpecValueFillTypes, FillUnit.getSpecValueFillTypes, StoreSpecies.VEHICLE, { "fillUnit" })
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("FillUnit")
	v3_:register(XMLValueType.STRING, "vehicle.storeData.specs.fillTypes", "Fill types")
	v3_:register(XMLValueType.STRING, "vehicle.storeData.specs.fillTypeCategories", "Fill type categories")
	v3_:register(XMLValueType.STRING, "vehicle.storeData.specs.fruitTypes", "Fruit types")
	v3_:register(XMLValueType.STRING, "vehicle.storeData.specs.fruitTypeCategories", "Fruit type categories")
	v3_:register(XMLValueType.FLOAT, "vehicle.storeData.specs.capacity", "Capacity")
	FillUnit.registerUnitDisplaySchema(v3_, "vehicle.storeData.specs.capacity")
	v3_:register(XMLValueType.BOOL, FillUnit.FILL_UNIT_CONFIG_XML_KEY .. ".fillUnits#removeVehicleIfEmpty", "Remove vehicle if unit empty", false)
	v3_:register(XMLValueType.FLOAT, FillUnit.FILL_UNIT_CONFIG_XML_KEY .. ".fillUnits#removeVehicleThreshold", "Remove vehicle if empty threshold in liters", 0)
	v3_:register(XMLValueType.TIME, FillUnit.FILL_UNIT_CONFIG_XML_KEY .. ".fillUnits#removeVehicleDelay", "Delay for vehicle removal (e.g. can be used while sounds are still playing)", 0)
	v3_:register(XMLValueType.FLOAT, FillUnit.FILL_UNIT_CONFIG_XML_KEY .. ".fillUnits#removeVehicleReward", "Amount of money as reward of removing the pallet", 0)
	v3_:register(XMLValueType.BOOL, FillUnit.FILL_UNIT_CONFIG_XML_KEY .. ".fillUnits#allowFoldingWhileFilled", "Allow folding while filled", true)
	v3_:register(XMLValueType.BOOL, FillUnit.FILL_UNIT_CONFIG_XML_KEY .. ".fillUnits#resetFoldingWhileFilled", "Reset folding while filled", false)
	v3_:register(XMLValueType.FLOAT, FillUnit.FILL_UNIT_CONFIG_XML_KEY .. ".fillUnits#allowFoldingThreshold", "Allow folding threshold", 0.0001)
	v3_:register(XMLValueType.FLOAT, FillUnit.FILL_UNIT_CONFIG_XML_KEY .. ".fillUnits#fillTypeChangeThreshold", "Fill type overwrite threshold", 0.05)
	v3_:register(XMLValueType.FLOAT, FillUnit.FILL_UNIT_CONFIG_XML_KEY .. ".fillUnits.fillTrigger#litersPerSecond", "Fill liters per second", 200)
	v3_:register(XMLValueType.BOOL, FillUnit.FILL_UNIT_CONFIG_XML_KEY .. ".fillUnits.fillTrigger#consumePtoPower", "Consume pto power while filling", false)
	local v4_ = FillUnit.FILL_UNIT_XML_KEY
	v3_:register(XMLValueType.FLOAT, v4_ .. "#capacity", "Capacity", "unlimited")
	v3_:register(XMLValueType.BOOL, v4_ .. "#updateMass", "Update vehicle mass while fill level changes", true)
	v3_:register(XMLValueType.BOOL, v4_ .. "#canBeUnloaded", "Can be unloaded", true)
	v3_:register(XMLValueType.FLOAT, v4_ .. "#allowFoldingThreshold", "Allow folding threshold", "Value of fillUnits#allowFoldingThreshold")
	v3_:register(XMLValueType.STRING, v4_ .. "#allowFoldingFillType", "Defines the fill type for which the folding threshold applies - all others are always allowed")
	FillUnit.registerUnitDisplaySchema(v3_, v4_)
	v3_:register(XMLValueType.BOOL, v4_ .. "#showCapacityInShop", "Show capacity in shop", true)
	v3_:register(XMLValueType.BOOL, v4_ .. "#showInShop", "Show in shop", true)
	v3_:register(XMLValueType.NODE_INDEX, v4_ .. ".exactFillRootNode#node", "Exact fill root node")
	v3_:register(XMLValueType.FLOAT, v4_ .. ".exactFillRootNode#extraEffectDistance", "Exact fill root node extra distance", 0)
	v3_:register(XMLValueType.NODE_INDEX, v4_ .. ".autoAimTargetNode#node", "Auto aim target node")
	v3_:register(XMLValueType.FLOAT, v4_ .. ".autoAimTargetNode#startZ", "Start Z translation")
	v3_:register(XMLValueType.FLOAT, v4_ .. ".autoAimTargetNode#endZ", "End Z translation")
	v3_:register(XMLValueType.FLOAT, v4_ .. ".autoAimTargetNode#startPercentage", "Start move percentage")
	v3_:register(XMLValueType.BOOL, v4_ .. ".autoAimTargetNode#invert", "Invert Z movement")
	v3_:register(XMLValueType.STRING, v4_ .. "#fillTypeCategories", "Supported fill type categories")
	v3_:register(XMLValueType.STRING, v4_ .. "#fillTypes", "Supported fill types")
	v3_:register(XMLValueType.FLOAT, v4_ .. "#startFillLevel", "Start fill level")
	v3_:register(XMLValueType.STRING, v4_ .. "#startFillType", "Start fill type")
	v3_:register(XMLValueType.NODE_INDEX, v4_ .. ".fillRootNode#node", "Fill root node", "first component")
	v3_:register(XMLValueType.NODE_INDEX, v4_ .. ".fillMassNode#node", "Fill root node", "first component")
	v3_:register(XMLValueType.BOOL, v4_ .. "#updateFillLevelMass", "Update fill level mass", true)
	v3_:register(XMLValueType.BOOL, v4_ .. "#ignoreFillLimit", "Ignores limiting of filling if the max mass is reached (if the settings is turned on)", false)
	v3_:register(XMLValueType.BOOL, v4_ .. "#synchronizeFillLevel", "Synchronize fill level", true)
	v3_:register(XMLValueType.BOOL, v4_ .. "#synchronizeFullFillLevel", "Synchronize fill level as 32bit float instead of percentage with max. 16 bits", false)
	v3_:register(XMLValueType.INT, v4_ .. "#synchronizationNumBits", "Synchronization bits")
	v3_:register(XMLValueType.BOOL, v4_ .. "#showOnHud", "Show on HUD", true)
	v3_:register(XMLValueType.BOOL, v4_ .. "#showOnInfoHud", "Show on Info HUD", true)
	v3_:register(XMLValueType.INT, v4_ .. "#uiPrecision", "Precision in UI display", 0)
	v3_:register(XMLValueType.L10N_STRING, v4_ .. "#uiCustomFillTypeName", "Custom fill type name for UI display")
	v3_:register(XMLValueType.L10N_STRING, v4_ .. "#uiExtraInfoText", "Extra text to display behind the fill type name")
	v3_:register(XMLValueType.STRING, v4_ .. "#uiDisplayType", "The style that is used for the display of the fill level in the HUD (\'BAR\' or \'STEP\')", "BAR")
	v3_:register(XMLValueType.BOOL, v4_ .. "#blocksAutomatedTrainTravel", "Block automated train travel if not empty", false)
	v3_:register(XMLValueType.STRING, v4_ .. "#fillAnimation", "Fill animation name")
	v3_:register(XMLValueType.FLOAT, v4_ .. "#fillAnimationLoadTime", "Fill animation load time")
	v3_:register(XMLValueType.FLOAT, v4_ .. "#fillAnimationEmptyTime", "Fill animation empty time")
	v3_:register(XMLValueType.STRING, v4_ .. ".fillLevelAnimation(?)#name", "Fill level animation name (Animation time is set depending on fill level percentage)")
	v3_:register(XMLValueType.BOOL, v4_ .. ".fillLevelAnimation(?)#resetOnEmpty", "Update animation when fill level reaches zero", true)
	v3_:register(XMLValueType.BOOL, v4_ .. ".fillLevelAnimation(?)#updateWhileFilled", "Animation will be updated while filled (If not \'true\', the animation will be set the the max. state)", true)
	v3_:register(XMLValueType.BOOL, v4_ .. ".fillLevelAnimation(?)#useMaxStateIfEmpty", "If the fill unit is empty, the animation will use the max. state", true)
	v3_:register(XMLValueType.FLOAT, v4_ .. ".alarmTriggers.alarmTrigger(?)#minFillLevel", "Fill animation empty time")
	v3_:register(XMLValueType.FLOAT, v4_ .. ".alarmTriggers.alarmTrigger(?)#maxFillLevel", "Fill animation empty time")
	v3_:register(XMLValueType.BOOL, v4_ .. ".alarmTriggers.alarmTrigger(?)#needsTurnOn", "Needs turn on", false)
	v3_:register(XMLValueType.BOOL, v4_ .. ".alarmTriggers.alarmTrigger(?)#turnOffInTrigger", "Turn off in trigger", false)
	v3_:register(XMLValueType.INT, v4_ .. ".alarmTriggers.alarmTrigger(?)#direction", "Direction in which the trigger is active (0: any, 1: filling, -1: discharging)", 0)
	SoundManager.registerSampleXMLPaths(v3_, v4_ .. ".alarmTriggers.alarmTrigger(?)", "alarmSound")
	BeaconLight.registerVehicleXMLPaths(v3_, v4_ .. ".alarmTriggers.alarmTrigger(?).beaconLight(?)")
	v3_:register(XMLValueType.TIME, v4_ .. ".alarmTriggers.alarmTrigger(?).beaconLight(?)#activeDuration", "Duration the beacon light is active (0: as long as the alarm trigger is active)", 0)
	v3_:register(XMLValueType.NODE_INDEX, v4_ .. ".measurementNodes.measurementNode(?)#node", "Measurement node")
	v3_:register(XMLValueType.NODE_INDEX, v4_ .. ".fillPlane.node(?)#node", "Fill plane node")
	v3_:register(XMLValueType.FLOAT, v4_ .. ".fillPlane.node(?).key(?)#time", "Key time")
	v3_:register(XMLValueType.VECTOR_TRANS, v4_ .. ".fillPlane.node(?).key(?)#translation", "Translation")
	v3_:register(XMLValueType.FLOAT, v4_ .. ".fillPlane.node(?).key(?)#y", "Y Translation")
	v3_:register(XMLValueType.VECTOR_ROT, v4_ .. ".fillPlane.node(?).key(?)#rotation", "Rotation")
	v3_:register(XMLValueType.VECTOR_SCALE, v4_ .. ".fillPlane.node(?).key(?)#scale", "Scale")
	v3_:register(XMLValueType.VECTOR_2, v4_ .. ".fillPlane.node(?)#minMaxY", "Min. and max. Y translation")
	v3_:register(XMLValueType.BOOL, v4_ .. ".fillPlane.node(?)#alwaysVisible", "Is always visible", false)
	v3_:register(XMLValueType.STRING, v4_ .. ".fillPlane#defaultFillType", "Default fill type name")
	v3_:register(XMLValueType.STRING, v4_ .. ".fillTypeMaterials.material(?)#fillType", "Fill type name")
	v3_:register(XMLValueType.NODE_INDEX, v4_ .. ".fillTypeMaterials.material(?)#node", "Node which receives material")
	v3_:register(XMLValueType.NODE_INDEX, v4_ .. ".fillTypeMaterials.material(?)#refNode", "Node which provides material")
	v3_:register(XMLValueType.STRING, v4_ .. ".fillTypeMaterials.material(?)#materialSlotName", "Material slot name to apply the defined texture as diffuse map")
	v3_:register(XMLValueType.FILENAME, v4_ .. ".fillTypeMaterials.material(?)#diffuse", "Path to a custom diffuse texture to apply")
	EffectManager.registerEffectXMLPaths(v3_, v4_ .. ".fillEffect")
	AnimationManager.registerAnimationNodesXMLPaths(v3_, v4_ .. ".animationNodes")
	Dashboard.registerDashboardXMLPaths(v3_, v4_, { "fillLevel", "fillLevelPct", "fillLevelWarning" })
	Dashboard.addDelayedRegistrationFunc(v3_, function(p5_, p6_)
		p5_:register(XMLValueType.STRING, p6_ .. "#fillType", "Fill type of fillUnit to be used")
		p5_:register(XMLValueType.INT, p6_ .. "#fillUnitIndex", "Fill unit index to represent")
	end)
	v3_:register(XMLValueType.NODE_INDEX, FillUnit.FILL_UNIT_CONFIG_XML_KEY .. ".fillUnits.unloading(?)#node", "Unloading node")
	v3_:register(XMLValueType.FLOAT, FillUnit.FILL_UNIT_CONFIG_XML_KEY .. ".fillUnits.unloading(?)#width", "Unloading width", 15)
	v3_:register(XMLValueType.VECTOR_TRANS, FillUnit.FILL_UNIT_CONFIG_XML_KEY .. ".fillUnits.unloading(?)#offset", "Unloading offset", "0 0 0")
	EffectManager.registerEffectXMLPaths(v3_, FillUnit.FILL_UNIT_CONFIG_XML_KEY .. ".fillUnits.fillEffect")
	AnimationManager.registerAnimationNodesXMLPaths(v3_, FillUnit.FILL_UNIT_CONFIG_XML_KEY .. ".fillUnits.animationNodes")
	SoundManager.registerSampleXMLPaths(v3_, "vehicle.fillUnit.sounds", "fill")
	v3_:register(XMLValueType.INT, Leveler.LEVELER_NODE_XML_KEY .. "#fillUnitIndex", "Reference fill unit index", 1)
	v3_:register(XMLValueType.FLOAT, Leveler.LEVELER_NODE_XML_KEY .. "#minFillLevel", "Min. fill level to activate leveler node (pct between 0 and 1)", 0)
	v3_:register(XMLValueType.FLOAT, Leveler.LEVELER_NODE_XML_KEY .. "#maxFillLevel", "Max. fill level to activate leveler node (pct between 0 and 1)", 1)
	v3_:addDelayedRegistrationFunc("AttacherJoint", function(p7_, p8_)
		p7_:register(XMLValueType.INT, p8_ .. "#fillUnitIndex", "Reference fill unit index", 1)
		p7_:register(XMLValueType.BOOL, p8_ .. "#fillUnitTopArmOnly", "Block attaching of implements with top arm only", false)
		p7_:register(XMLValueType.FLOAT, p8_ .. "#minFillLevel", "Min. fill level to activate attacher joint (pct between 0 and 1)", 0)
		p7_:register(XMLValueType.FLOAT, p8_ .. "#maxFillLevel", "Max. fill level to activate attacher joint (pct between 0 and 1)", 1)
	end)
	v3_:setXMLSpecializationType()
	local v9_ = Vehicle.xmlSchemaSavegame
	v9_:register(XMLValueType.INT, "vehicles.vehicle(?).fillUnit.unit(?)#index", "Fill Unit index")
	v9_:register(XMLValueType.STRING, "vehicles.vehicle(?).fillUnit.unit(?)#fillType", "Fill type")
	v9_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).fillUnit.unit(?)#fillLevel", "Fill level")
end

function FillUnit.registerUnitDisplaySchema(schema, key)
	schema:register(XMLValueType.STRING, key .. "#shopDisplayUnit", "Unit used for displaying the capacity in shop (converts to given unit from capacity in liters)", "LITER", false, table.toList(FillUnit.UNIT))
	schema:register(XMLValueType.STRING, key .. "#unitTextOverride", "Unit text override, no conversion performed on given capacity")
end

function FillUnit.prerequisitesPresent(self)
	return true
end

function FillUnit.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onFillUnitFillLevelChanged")
	SpecializationUtil.registerEvent(vehicleType, "onChangedFillType")
	SpecializationUtil.registerEvent(vehicleType, "onAlarmTriggerChanged")
	SpecializationUtil.registerEvent(vehicleType, "onAddedFillUnitTrigger")
	SpecializationUtil.registerEvent(vehicleType, "onFillUnitTriggerChanged")
	SpecializationUtil.registerEvent(vehicleType, "onRemovedFillUnitTrigger")
	SpecializationUtil.registerEvent(vehicleType, "onFillUnitIsFillingStateChanged")
	SpecializationUtil.registerEvent(vehicleType, "onFillUnitUnloadPallet")
	SpecializationUtil.registerEvent(vehicleType, "onFillUnitUnloaded")
end

function FillUnit.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getDrawFirstFillText", FillUnit.getDrawFirstFillText)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnits", FillUnit.getFillUnits)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitByIndex", FillUnit.getFillUnitByIndex)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitExists", FillUnit.getFillUnitExists)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitCapacity", FillUnit.getFillUnitCapacity)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitFreeCapacity", FillUnit.getFillUnitFreeCapacity)
	SpecializationUtil.registerFunction(vehicleType, "getIsFillAllowedFromFarm", FillUnit.getIsFillAllowedFromFarm)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitFillLevel", FillUnit.getFillUnitFillLevel)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitFillLevelPercentage", FillUnit.getFillUnitFillLevelPercentage)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitFillType", FillUnit.getFillUnitFillType)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitLastValidFillType", FillUnit.getFillUnitLastValidFillType)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitFirstSupportedFillType", FillUnit.getFillUnitFirstSupportedFillType)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitExactFillRootNode", FillUnit.getFillUnitExactFillRootNode)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitRootNode", FillUnit.getFillUnitRootNode)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitAutoAimTargetNode", FillUnit.getFillUnitAutoAimTargetNode)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitSupportsFillType", FillUnit.getFillUnitSupportsFillType)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitSupportsToolType", FillUnit.getFillUnitSupportsToolType)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitSupportsToolTypeAndFillType", FillUnit.getFillUnitSupportsToolTypeAndFillType)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitSupportedFillTypes", FillUnit.getFillUnitSupportedFillTypes)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitSupportedToolTypes", FillUnit.getFillUnitSupportedToolTypes)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitAllowsFillType", FillUnit.getFillUnitAllowsFillType)
	SpecializationUtil.registerFunction(vehicleType, "getFillTypeChangeThreshold", FillUnit.getFillTypeChangeThreshold)
	SpecializationUtil.registerFunction(vehicleType, "getFirstValidFillUnitToFill", FillUnit.getFirstValidFillUnitToFill)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitCanBeFilled", FillUnit.getFillUnitCanBeFilled)
	SpecializationUtil.registerFunction(vehicleType, "setFillUnitFillType", FillUnit.setFillUnitFillType)
	SpecializationUtil.registerFunction(vehicleType, "setFillUnitFillTypeToDisplay", FillUnit.setFillUnitFillTypeToDisplay)
	SpecializationUtil.registerFunction(vehicleType, "setFillUnitFillLevelToDisplay", FillUnit.setFillUnitFillLevelToDisplay)
	SpecializationUtil.registerFunction(vehicleType, "setFillUnitCapacityToDisplay", FillUnit.setFillUnitCapacityToDisplay)
	SpecializationUtil.registerFunction(vehicleType, "setFillUnitCapacity", FillUnit.setFillUnitCapacity)
	SpecializationUtil.registerFunction(vehicleType, "setFillUnitForcedMaterialFillType", FillUnit.setFillUnitForcedMaterialFillType)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitForcedMaterialFillType", FillUnit.getFillUnitForcedMaterialFillType)
	SpecializationUtil.registerFunction(vehicleType, "setFillUnitInTriggerRange", FillUnit.setFillUnitInTriggerRange)
	SpecializationUtil.registerFunction(vehicleType, "updateAlarmTriggers", FillUnit.updateAlarmTriggers)
	SpecializationUtil.registerFunction(vehicleType, "getAlarmTriggerIsActive", FillUnit.getAlarmTriggerIsActive)
	SpecializationUtil.registerFunction(vehicleType, "setAlarmTriggerState", FillUnit.setAlarmTriggerState)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitIndexFromNode", FillUnit.getFillUnitIndexFromNode)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitExtraDistanceFromNode", FillUnit.getFillUnitExtraDistanceFromNode)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitFromNode", FillUnit.getFillUnitFromNode)
	SpecializationUtil.registerFunction(vehicleType, "addFillUnitFillLevel", FillUnit.addFillUnitFillLevel)
	SpecializationUtil.registerFunction(vehicleType, "setFillUnitLastValidFillType", FillUnit.setFillUnitLastValidFillType)
	SpecializationUtil.registerFunction(vehicleType, "loadFillUnitFromXML", FillUnit.loadFillUnitFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadAlarmTrigger", FillUnit.loadAlarmTrigger)
	SpecializationUtil.registerFunction(vehicleType, "loadMeasurementNode", FillUnit.loadMeasurementNode)
	SpecializationUtil.registerFunction(vehicleType, "updateMeasurementNodes", FillUnit.updateMeasurementNodes)
	SpecializationUtil.registerFunction(vehicleType, "loadFillPlane", FillUnit.loadFillPlane)
	SpecializationUtil.registerFunction(vehicleType, "setFillPlaneForcedFillType", FillUnit.setFillPlaneForcedFillType)
	SpecializationUtil.registerFunction(vehicleType, "updateFillUnitFillPlane", FillUnit.updateFillUnitFillPlane)
	SpecializationUtil.registerFunction(vehicleType, "loadFillTypeMaterials", FillUnit.loadFillTypeMaterials)
	SpecializationUtil.registerFunction(vehicleType, "updateFillTypeMaterials", FillUnit.updateFillTypeMaterials)
	SpecializationUtil.registerFunction(vehicleType, "updateFillUnitAutoAimTarget", FillUnit.updateFillUnitAutoAimTarget)
	SpecializationUtil.registerFunction(vehicleType, "addFillUnitTrigger", FillUnit.addFillUnitTrigger)
	SpecializationUtil.registerFunction(vehicleType, "removeFillUnitTrigger", FillUnit.removeFillUnitTrigger)
	SpecializationUtil.registerFunction(vehicleType, "setFillUnitIsFilling", FillUnit.setFillUnitIsFilling)
	SpecializationUtil.registerFunction(vehicleType, "setFillSoundIsPlaying", FillUnit.setFillSoundIsPlaying)
	SpecializationUtil.registerFunction(vehicleType, "getIsFillUnitActive", FillUnit.getIsFillUnitActive)
	SpecializationUtil.registerFunction(vehicleType, "updateFillUnitTriggers", FillUnit.updateFillUnitTriggers)
	SpecializationUtil.registerFunction(vehicleType, "emptyAllFillUnits", FillUnit.emptyAllFillUnits)
	SpecializationUtil.registerFunction(vehicleType, "unloadFillUnits", FillUnit.unloadFillUnits)
	SpecializationUtil.registerFunction(vehicleType, "loadFillUnitUnloadingFromXML", FillUnit.loadFillUnitUnloadingFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitUnloadPalletFilename", FillUnit.getFillUnitUnloadPalletFilename)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitHasMountedPalletsToUnload", FillUnit.getFillUnitHasMountedPalletsToUnload)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitMountedPalletsToUnload", FillUnit.getFillUnitMountedPalletsToUnload)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitUnloadingTasks", FillUnit.getFillUnitUnloadingTasks)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitEmptyOnReset", FillUnit.getFillUnitEmptyOnReset)
	SpecializationUtil.registerFunction(vehicleType, "getAllowLoadTriggerActivation", FillUnit.getAllowLoadTriggerActivation)
	SpecializationUtil.registerFunction(vehicleType, "addExactFillRootAimToUpdate", FillUnit.addExactFillRootAimToUpdate)
	SpecializationUtil.registerFunction(vehicleType, "debugGetSupportedFillTypesPerFillUnit", FillUnit.debugGetSupportedFillTypesPerFillUnit)
end

function FillUnit.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAdditionalComponentMass", FillUnit.getAdditionalComponentMass)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillLevelInformation", FillUnit.getFillLevelInformation)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", FillUnit.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsReadyForAutomatedTrainTravel", FillUnit.getIsReadyForAutomatedTrainTravel)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadMovingToolFromXML", FillUnit.loadMovingToolFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMovingToolActive", FillUnit.getIsMovingToolActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoConsumePtoPower", FillUnit.getDoConsumePtoPower)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsPowerTakeOffActive", FillUnit.getIsPowerTakeOffActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", FillUnit.getCanBeTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "showInfo", FillUnit.showInfo)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadLevelerNodeFromXML", FillUnit.loadLevelerNodeFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsLevelerPickupNodeActive", FillUnit.getIsLevelerPickupNodeActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAttacherJointFromXML", FillUnit.loadAttacherJointFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAttacherJointCompatible", FillUnit.getIsAttacherJointCompatible)
end

function FillUnit.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", FillUnit)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", FillUnit)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", FillUnit)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", FillUnit)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", FillUnit)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", FillUnit)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", FillUnit)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", FillUnit)
	SpecializationUtil.registerEventListener(vehicleType, "onPostUpdate", FillUnit)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", FillUnit)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", FillUnit)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", FillUnit)
	SpecializationUtil.registerEventListener(vehicleType, "onDischargeTargetObjectChanged", FillUnit)
end

-- Local values: spec, fillUnitConfigurationId, baseKey, i, key, entry
function FillUnit:onLoad(savegame)
	local v_u_17_ = self.spec_fillUnit
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.measurementNodes.measurementNode", "vehicle.fillUnit.fillUnitConfigurations.fillUnitConfiguration.fillUnits.fillUnit.measurementNodes.measurementNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.fillPlanes.fillPlane", "vehicle.fillUnit.fillUnitConfigurations.fillUnitConfiguration.fillUnits.fillUnit.fillPlane")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.foldable.foldingParts#onlyFoldOnEmpty", "vehicle.fillUnit#allowFoldingWhileFilled")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.fillAutoAimTargetNode", "vehicle.fillUnit.fillUnitConfigurations.fillUnitConfiguration.fillUnits.fillUnit.autoAimTargetNode")
	local v18_ = Utils.getNoNil(self.configurations.fillUnit, 1)
	local v19_ = string.format("vehicle.fillUnit.fillUnitConfigurations.fillUnitConfiguration(%d).fillUnits", v18_ - 1)
	v_u_17_.removeVehicleIfEmpty = self.xmlFile:getValue(v19_ .. "#removeVehicleIfEmpty", false)
	v_u_17_.removeVehicleThreshold = self.xmlFile:getValue(v19_ .. "#removeVehicleThreshold", 0)
	v_u_17_.removeVehicleDelay = self.xmlFile:getValue(v19_ .. "#removeVehicleDelay", 0)
	v_u_17_.removeVehicleReward = self.xmlFile:getValue(v19_ .. "#removeVehicleReward", 0)
	v_u_17_.allowFoldingWhileFilled = self.xmlFile:getValue(v19_ .. "#allowFoldingWhileFilled", true)
	v_u_17_.resetFoldingWhileFilled = self.xmlFile:getValue(v19_ .. "#resetFoldingWhileFilled", false)
	v_u_17_.allowFoldingThreshold = self.xmlFile:getValue(v19_ .. "#allowFoldingThreshold", 0.0001)
	v_u_17_.fillTypeChangeThreshold = self.xmlFile:getValue(v19_ .. "#fillTypeChangeThreshold", 0.05)
	v_u_17_.fillUnits = {}
	v_u_17_.exactFillRootNodeToFillUnit = {}
	v_u_17_.exactFillRootNodeToExtraDistance = {}
	v_u_17_.exactFillRootNodeAimToUpdate = {}
	v_u_17_.hasExactFillRootNodes = false
	v_u_17_.activeAlarmTriggers = {}
	v_u_17_.fillTrigger = {}
	v_u_17_.fillTrigger.triggers = {}
	v_u_17_.fillTrigger.activatable = FillActivatable.new(self)
	v_u_17_.fillTrigger.isFilling = false
	v_u_17_.fillTrigger.currentTrigger = nil
	v_u_17_.fillTrigger.selectedTrigger = nil
	v_u_17_.fillTrigger.litersPerSecond = self.xmlFile:getValue(v19_ .. ".fillTrigger#litersPerSecond", 200)
	v_u_17_.fillTrigger.consumePtoPower = self.xmlFile:getValue(v19_ .. ".fillTrigger#consumePtoPower", false)
	local v_u_20_ = 0
	while true do
		local v21_ = string.format("%s.fillUnit(%d)", v19_, v_u_20_)
		if not self.xmlFile:hasProperty(v21_) then
			break
		end
		local v22_ = {}
		if not self:loadFillUnitFromXML(self.xmlFile, v21_, v22_, v_u_20_ + 1) then
			Logging.xmlWarning(self.xmlFile, "Could not load fillUnit for \'%s\'", v21_)
			self:setLoadingState(VehicleLoadingState.ERROR)
			break
		end
		local v23_ = v_u_17_.fillUnits
		table.insert(v23_, v22_)
		v_u_20_ = v_u_20_ + 1
	end
	if self.xmlFile:hasProperty(v19_ .. ".unloading") then
		v_u_17_.unloading = {}
		self.xmlFile:iterate(v19_ .. ".unloading", function(_, p24_)
			-- upvalues: (copy) self, (ref) v_u_20_, (copy) v_u_17_
			local v25_ = {}
			if not self:loadFillUnitUnloadingFromXML(self.xmlFile, p24_, v25_, v_u_20_ + 1) then
				Logging.xmlWarning(self.xmlFile, "Could not load unloading node for \'%s\'", p24_)
				return false
			end
			local v26_ = v_u_17_.unloading
			table.insert(v26_, v25_)
		end)
	end
	if self.isClient then
		v_u_17_.samples = {}
		v_u_17_.samples.fill = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.fillUnit.sounds", "fill", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_17_.fillEffects = g_effectManager:loadEffect(self.xmlFile, v19_ .. ".fillEffect", self.components, self, self.i3dMappings)
		v_u_17_.animationNodes = g_animationManager:loadAnimations(self.xmlFile, v19_ .. ".animationNodes", self.components, self, self.i3dMappings)
		v_u_17_.activeFillEffects = {}
		v_u_17_.activeFillAnimations = {}
	end
	v_u_17_.texts = {}
	v_u_17_.texts.warningFoldingFilled = g_i18n:getText("warning_foldingNotWhileFilled")
	v_u_17_.texts.firstFillTheTool = g_i18n:getText("info_firstFillTheTool")
	v_u_17_.texts.unloadNoSpace = g_i18n:getText("fillUnit_unload_nospace")
	v_u_17_.texts.stopRefill = g_i18n:getText("action_stopRefillingOBJECT")
	v_u_17_.texts.startRefill = g_i18n:getText("action_refillOBJECT")
	v_u_17_.isInfoDirty = false
	v_u_17_.fillUnitInfos = {}
	v_u_17_.dirtyFlag = self:getNextDirtyFlag()
end

-- Local values: spec, fillUnitsToLoad, i, fillUnit, i, xmlFile, key, fillUnitIndex, allowLoading, fillTypeName, fillLevel, fillTypeIndex, fillUnit, _, fillLevelAnimation, fillUnitIndex, fillUnit, _, fillLevelAnimation, i, fillUnit
function FillUnit:onPostLoad(savegame)
	local v29_ = self.spec_fillUnit
	if self.isServer then
		local v30_ = {}
		for v31_, v32_ in ipairs(v29_.fillUnits) do
			if v32_.startFillLevel == nil and v32_.startFillTypeIndex == nil then
				v30_[v31_] = v32_
			end
		end
		if savegame == nil or not savegame.xmlFile:hasProperty(savegame.key .. ".fillUnit") then
			if not self.vehicleLoadingData:getCustomParameter("spawnEmpty") then
				for v33_, v34_ in pairs(v29_.fillUnits) do
					if v34_.startFillLevel ~= nil and v34_.startFillTypeIndex ~= nil then
						self:addFillUnitFillLevel(self:getOwnerFarmId(), v33_, v34_.startFillLevel, v34_.startFillTypeIndex, ToolType.UNDEFINED, nil)
						for _, v35_ in ipairs(v34_.fillLevelAnimations) do
							AnimatedVehicle.updateAnimationByName(self, v35_.name, 9999999, true)
						end
					end
				end
			end
		else
			local v36_ = savegame.xmlFile
			local v37_ = 0
			while true do
				local v38_ = string.format("%s.fillUnit.unit(%d)", savegame.key, v37_)
				if not v36_:hasProperty(v38_) then
					break
				end
				local v39_ = v36_:getValue(v38_ .. "#index")
				local v40_
				if v30_[v39_] == nil then
					v40_ = true
				elseif v30_[v39_] == nil then
					v40_ = false
				else
					v40_ = not (savegame.resetVehicles and self:getFillUnitEmptyOnReset())
				end
				if v40_ then
					local v41_ = v36_:getValue(v38_ .. "#fillType")
					local v42_ = v36_:getValue(v38_ .. "#fillLevel")
					local v43_ = g_fillTypeManager:getFillTypeIndexByName(v41_)
					self:addFillUnitFillLevel(self:getOwnerFarmId(), v39_, v42_, v43_, ToolType.UNDEFINED, nil)
					local v44_ = v29_.fillUnits[v39_]
					if v44_ ~= nil then
						for _, v45_ in ipairs(v44_.fillLevelAnimations) do
							AnimatedVehicle.updateAnimationByName(self, v45_.name, 9999999, true)
						end
					end
				end
				v37_ = v37_ + 1
			end
		end
		for _, v46_ in ipairs(v29_.fillUnits) do
			self:updateAlarmTriggers(v46_.alarmTriggers)
		end
	end
	if #v29_.fillUnits == 0 then
		SpecializationUtil.removeEventListener(self, "onReadStream", FillUnit)
		SpecializationUtil.removeEventListener(self, "onWriteStream", FillUnit)
		SpecializationUtil.removeEventListener(self, "onReadUpdateStream", FillUnit)
		SpecializationUtil.removeEventListener(self, "onWriteUpdateStream", FillUnit)
		SpecializationUtil.removeEventListener(self, "onUpdateTick", FillUnit)
		SpecializationUtil.removeEventListener(self, "onPostUpdate", FillUnit)
		SpecializationUtil.removeEventListener(self, "onDraw", FillUnit)
		SpecializationUtil.removeEventListener(self, "onDeactivate", FillUnit)
		SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", FillUnit)
	end
end

-- Local values: spec, _, trigger, _, fillUnit, _, alarmTrigger, _, beaconLight
function FillUnit:onDelete()
	local v48_ = self.spec_fillUnit
	if v48_.fillTrigger ~= nil then
		g_currentMission.activatableObjectsSystem:removeActivatable(v48_.fillTrigger.activatable)
		for _, v49_ in pairs(v48_.fillTrigger.triggers) do
			v49_:onVehicleDeleted(self)
		end
		v48_.fillTrigger.currentTrigger = nil
		v48_.fillTrigger.selectedTrigger = nil
	end
	if v48_.fillUnits ~= nil then
		for _, v50_ in ipairs(v48_.fillUnits) do
			for _, v51_ in ipairs(v50_.alarmTriggers) do
				g_soundManager:deleteSample(v51_.sample)
				for _, v52_ in ipairs(v51_.beaconLights) do
					v52_:delete()
				end
			end
			g_effectManager:deleteEffects(v50_.fillEffects)
			g_animationManager:deleteAnimations(v50_.animationNodes)
			if v50_.exactFillRootNode ~= nil then
				g_currentMission:removeNodeObject(v50_.exactFillRootNode)
			end
		end
	end
	g_effectManager:deleteEffects(v48_.fillEffects)
	g_animationManager:deleteAnimations(v48_.animationNodes)
	if v48_.samples ~= nil then
		g_soundManager:deleteSamples(v48_.samples)
		table.clear(v48_.samples)
	end
end

-- Local values: spec, i, k, fillUnit, fillUnitKey, fillTypeName
function FillUnit:saveToXMLFile(xmlFile, key, usedModNames)
	local v56_ = self.spec_fillUnit
	local v57_ = 0
	for v58_, v59_ in ipairs(v56_.fillUnits) do
		if v59_.needsSaving then
			local v60_ = string.format("%s.unit(%d)", key, v57_)
			local v61_ = Utils.getNoNil(g_fillTypeManager:getFillTypeNameByIndex(v59_.fillType), "unknown")
			xmlFile:setValue(v60_ .. "#index", v58_)
			xmlFile:setValue(v60_ .. "#fillType", v61_)
			xmlFile:setValue(v60_ .. "#fillLevel", v59_.fillLevel)
			v57_ = v57_ + 1
		end
	end
end

-- Local values: spec, fillTypes, fillLevels, numFillUnits, i, fillUnit, fillTypeName
function FillUnit:saveStatsToXMLFile(xmlFile, key)
	local v65_ = self.spec_fillUnit
	local v66_ = #v65_.fillUnits
	local v67_ = ""
	local v68_ = ""
	for v69_, v70_ in ipairs(v65_.fillUnits) do
		local v71_ = Utils.getNoNil(g_fillTypeManager:getFillTypeNameByIndex(v70_.fillType), "unknown")
		v67_ = v67_ .. HTMLUtil.encodeToHTML((tostring(v71_)))
		v68_ = v68_ .. string.format("%.3f", v70_.fillLevel)
		if v66_ > 1 and v69_ ~= v66_ then
			v67_ = v67_ .. " "
			v68_ = v68_ .. " "
		end
	end
	setXMLString(xmlFile, key .. "#fillTypes", v67_)
	setXMLString(xmlFile, key .. "#fillLevels", v68_)
end

-- Local values: spec, i, fillLevel, fillType, lastValidFillType
function FillUnit:onReadStream(streamId, connection)
	if connection:getIsServer() then
		local v75_ = self.spec_fillUnit
		self:setFillUnitIsFilling(streamReadBool(streamId), true)
		for v76_ = 1, #v75_.fillUnits do
			if v75_.fillUnits[v76_].synchronizeFillLevel then
				local v77_ = streamReadFloat32(streamId)
				local v78_ = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
				self:addFillUnitFillLevel(self:getOwnerFarmId(), v76_, v77_, v78_, ToolType.UNDEFINED, nil)
				self:setFillUnitLastValidFillType(v76_, streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS), true)
			end
		end
	end
end

-- Local values: spec, i, fillUnit
function FillUnit:onWriteStream(streamId, connection)
	if not connection:getIsServer() then
		local v82_ = self.spec_fillUnit
		streamWriteBool(streamId, v82_.fillTrigger.isFilling)
		for v83_ = 1, #v82_.fillUnits do
			if v82_.fillUnits[v83_].synchronizeFillLevel then
				local v84_ = v82_.fillUnits[v83_]
				streamWriteFloat32(streamId, v84_.fillLevel)
				streamWriteUIntN(streamId, v84_.fillType, FillTypeManager.SEND_NUM_BITS)
				streamWriteUIntN(streamId, v84_.lastValidFillType, FillTypeManager.SEND_NUM_BITS)
			end
		end
	end
end

-- Local values: spec, i, fillUnit, fillLevel, maxValue, fillType, oldFillType, lastValidFillType
function FillUnit:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local v88_ = self.spec_fillUnit
		if streamReadBool(streamId) then
			for v89_ = 1, #v88_.fillUnits do
				local v90_ = v88_.fillUnits[v89_]
				if v90_.synchronizeFillLevel then
					local v91_
					if streamReadBool(streamId) then
						v91_ = streamReadFloat32(streamId)
					else
						local v92_ = 2 ^ v90_.synchronizationNumBits - 1
						v91_ = v90_.capacity * streamReadUIntN(streamId, v90_.synchronizationNumBits) / v92_
					end
					local v93_ = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
					if v91_ ~= v90_.fillLevel or v93_ ~= v90_.fillType then
						local v94_ = self:getFillUnitFillType(v89_)
						if v93_ == FillType.UNKNOWN then
							self:addFillUnitFillLevel(self:getOwnerFarmId(), v89_, -math.huge, v94_, ToolType.UNDEFINED, nil)
						else
							if v94_ ~= FillType.UNKNOWN and v93_ ~= v94_ then
								self:setFillUnitFillType(v89_, v93_)
							end
							self:addFillUnitFillLevel(self:getOwnerFarmId(), v89_, v91_ - v90_.fillLevel, v93_, ToolType.UNDEFINED, nil)
						end
					end
					local v95_ = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
					self:setFillUnitLastValidFillType(v89_, v95_, v95_ ~= v90_.lastValidFillType)
				end
			end
		end
	end
end

-- Local values: spec, i, fillUnit, percent, value
function FillUnit:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v100_ = self.spec_fillUnit
		local v101_ = streamWriteBool
		local v102_ = v100_.dirtyFlag
		if v101_(streamId, bit32.band(dirtyMask, v102_) ~= 0) then
			for v103_ = 1, #v100_.fillUnits do
				local v104_ = v100_.fillUnits[v103_]
				if v104_.synchronizeFillLevel then
					if streamWriteBool(streamId, v104_.synchronizeFullFillLevel or v104_.capacity == math.huge) then
						streamWriteFloat32(streamId, v104_.fillLevelSent)
					else
						local v105_
						if v104_.capacity > 0 then
							local v106_ = v104_.fillLevelSent / v104_.capacity
							v105_ = math.clamp(v106_, 0, 1)
						else
							v105_ = 0
						end
						local v107_ = v105_ * (2 ^ v104_.synchronizationNumBits - 1) + 0.5
						local v108_ = math.floor(v107_)
						streamWriteUIntN(streamId, v108_, v104_.synchronizationNumBits)
					end
					streamWriteUIntN(streamId, v104_.fillTypeSent, FillTypeManager.SEND_NUM_BITS)
					streamWriteUIntN(streamId, v104_.lastValidFillTypeSent, FillTypeManager.SEND_NUM_BITS)
				end
			end
		end
	end
end

-- Local values: spec, delta, trigger, _, fillUnit, needsUpdate, effect, time, animationNodes, time
function FillUnit:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v111_ = self.spec_fillUnit
	if self.isServer and v111_.fillTrigger.isFilling then
		local v112_ = v111_.fillTrigger.currentTrigger
		if (v112_ == nil and 0 or v112_:fillVehicle(self, v111_.fillTrigger.litersPerSecond * dt * 0.001, dt)) <= 0 then
			self:setFillUnitIsFilling(false)
		end
	end
	if self.isClient then
		for _, v113_ in pairs(v111_.fillUnits) do
			self:updateMeasurementNodes(v113_, dt, false)
		end
		self:updateAlarmTriggers(v111_.activeAlarmTriggers)
		local v114_ = false
		for v115_, v116_ in pairs(v111_.activeFillEffects) do
			local v117_ = v116_ - dt
			if v117_ < 0 then
				g_effectManager:stopEffects(v115_)
				v111_.activeFillEffects[v115_] = nil
			else
				v111_.activeFillEffects[v115_] = v117_
				v114_ = true
			end
		end
		for v118_, v119_ in pairs(v111_.activeFillAnimations) do
			local v120_ = v119_ - dt
			if v120_ < 0 then
				g_animationManager:stopAnimations(v118_)
				v111_.activeFillAnimations[v118_] = nil
			else
				v111_.activeFillAnimations[v118_] = v120_
				v114_ = true
			end
		end
		if v114_ then
			self:raiseActive()
		end
	end
end

-- Local values: spec, vehicle, func
function FillUnit:onPostUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v123_ = self.spec_fillUnit
	for v124_, v125_ in pairs(v123_.exactFillRootNodeAimToUpdate) do
		if not v124_.isDeleted then
			v125_(v124_, dt)
		end
		v123_.exactFillRootNodeAimToUpdate[v124_] = nil
	end
end

-- Local values: spec
function FillUnit:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self:getDrawFirstFillText() then
		local v127_ = self.spec_fillUnit
		g_currentMission:addExtraPrintText(v127_.texts.firstFillTheTool)
	end
end

-- Local values: spec, _, fillUnit
function FillUnit:onDeactivate()
	local v129_ = self.spec_fillUnit
	if v129_.fillTrigger.isFilling then
		self:setFillUnitIsFilling(false, true)
	end
	for _, v130_ in pairs(v129_.fillUnits) do
		self:updateMeasurementNodes(v130_, 0, false, 0)
	end
end

-- Local values: spec, _, actionEventId, _, actionEventId
function FillUnit:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v133_ = self.spec_fillUnit
		self:clearActionEventsTable(v133_.actionEvents)
		if isActiveForInputIgnoreSelection then
			if self.isServer and (GS_IS_CONSOLE_VERSION and g_isDevelopmentVersion) then
				local _, v134_ = self:addActionEvent(v133_.actionEvents, InputAction.CONSOLE_DEBUG_FILLUNIT_NEXT, self, FillUnit.actionEventConsoleFillUnitNext, false, true, false, true, nil)
				g_inputBinding:setActionEventTextVisibility(v134_, false)
				g_inputBinding:setActionEventTextPriority(v134_, GS_PRIO_VERY_LOW)
				local _, v135_ = self:addActionEvent(v133_.actionEvents, InputAction.CONSOLE_DEBUG_FILLUNIT_INC, self, FillUnit.actionEventConsoleFillUnitInc, false, true, false, true, nil)
				g_inputBinding:setActionEventTextVisibility(v135_, false)
				g_inputBinding:setActionEventTextPriority(v135_, GS_PRIO_VERY_LOW)
				local _, v136_ = self:addActionEvent(v133_.actionEvents, InputAction.CONSOLE_DEBUG_FILLUNIT_DEC, self, FillUnit.actionEventConsoleFillUnitDec, false, true, false, true, nil)
				g_inputBinding:setActionEventTextVisibility(v136_, false)
				g_inputBinding:setActionEventTextPriority(v136_, GS_PRIO_VERY_LOW)
			end
			if v133_.unloading ~= nil then
				local _, v137_ = self:addActionEvent(v133_.actionEvents, InputAction.UNLOAD, self, FillUnit.actionEventUnload, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(v137_, GS_PRIO_NORMAL)
				v133_.unloadActionEventId = v137_
				FillUnit.updateUnloadActionDisplay(self)
			end
		end
	end
end

function FillUnit:onDischargeTargetObjectChanged(dischargeObject)
	FillUnit.updateUnloadActionDisplay(self)
end

function FillUnit.getDrawFirstFillText(self)
	return false
end

-- Local values: spec
function FillUnit:getFillUnits()
	return self.spec_fillUnit.fillUnits
end

-- Local values: spec
function FillUnit:getFillUnitByIndex(fillUnitIndex)
	local v142_ = self.spec_fillUnit
	if self:getFillUnitExists(fillUnitIndex) then
		return v142_.fillUnits[fillUnitIndex]
	else
		return nil
	end
end

-- Local values: spec
function FillUnit:getFillUnitExists(fillUnitIndex)
	local v145_ = self.spec_fillUnit
	local v146_
	if fillUnitIndex == nil then
		v146_ = false
	else
		v146_ = v145_.fillUnits[fillUnitIndex] ~= nil
	end
	return v146_
end

-- Local values: spec
function FillUnit:getFillUnitCapacity(fillUnitIndex)
	local v149_ = self.spec_fillUnit
	if v149_.fillUnits[fillUnitIndex] == nil then
		return nil
	else
		return v149_.fillUnits[fillUnitIndex].capacity
	end
end

-- Local values: spec, fillUnit, freeCapacity
function FillUnit:getFillUnitFreeCapacity(fillUnitIndex, fillTypeIndex, farmId)
	local v152_ = self.spec_fillUnit.fillUnits[fillUnitIndex]
	if v152_ == nil then
		return nil
	end
	local v153_ = v152_.capacity - v152_.fillLevel
	return not v152_.ignoreFillLimit and (g_currentMission.missionInfo.trailerFillLimit and self:getMaxComponentMassReached()) and 0 or v153_
end

function FillUnit:getIsFillAllowedFromFarm(farmId)
	return true
end

-- Local values: spec
function FillUnit:getFillUnitFillLevel(fillUnitIndex)
	local v156_ = self.spec_fillUnit
	if v156_.fillUnits[fillUnitIndex] == nil then
		return nil
	else
		return v156_.fillUnits[fillUnitIndex].fillLevel
	end
end

-- Local values: spec, fillUnit
function FillUnit:getFillUnitFillLevelPercentage(fillUnitIndex)
	local v159_ = self.spec_fillUnit.fillUnits[fillUnitIndex]
	if v159_ == nil then
		return nil
	else
		return v159_.capacity <= 0 and 0 or v159_.fillLevel / v159_.capacity
	end
end

-- Local values: spec
function FillUnit:getFillUnitFillType(fillUnitIndex)
	local v162_ = self.spec_fillUnit
	if v162_.fillUnits[fillUnitIndex] == nil then
		return nil
	else
		return v162_.fillUnits[fillUnitIndex].fillType
	end
end

-- Local values: spec
function FillUnit:getFillUnitLastValidFillType(fillUnitIndex)
	local v165_ = self.spec_fillUnit
	if v165_.fillUnits[fillUnitIndex] == nil then
		return nil
	else
		return v165_.fillUnits[fillUnitIndex].lastValidFillType
	end
end

-- Local values: spec
function FillUnit:getFillUnitFirstSupportedFillType(fillUnitIndex)
	local v168_ = self.spec_fillUnit
	if v168_.fillUnits[fillUnitIndex] == nil then
		return nil
	else
		return next(v168_.fillUnits[fillUnitIndex].supportedFillTypes)
	end
end

-- Local values: spec
function FillUnit:getFillUnitExactFillRootNode(fillUnitIndex)
	local v171_ = self.spec_fillUnit
	if v171_.fillUnits[fillUnitIndex] == nil then
		return nil
	else
		return v171_.fillUnits[fillUnitIndex].exactFillRootNode
	end
end

-- Local values: spec
function FillUnit:getFillUnitRootNode(fillUnitIndex)
	local v174_ = self.spec_fillUnit
	if v174_.fillUnits[fillUnitIndex] == nil then
		return nil
	else
		return v174_.fillUnits[fillUnitIndex].fillRootNode
	end
end

-- Local values: spec
function FillUnit:getFillUnitAutoAimTargetNode(fillUnitIndex)
	local v177_ = self.spec_fillUnit
	if v177_.fillUnits[fillUnitIndex] == nil then
		return nil
	else
		return v177_.fillUnits[fillUnitIndex].autoAimTarget.node
	end
end

-- Local values: spec
function FillUnit:getFillUnitSupportsFillType(fillUnitIndex, fillType)
	local v181_ = self.spec_fillUnit
	if v181_.fillUnits[fillUnitIndex] == nil then
		return false
	else
		return v181_.fillUnits[fillUnitIndex].supportedFillTypes[fillType]
	end
end

-- Local values: spec
function FillUnit:getFillUnitSupportsToolType(fillUnitIndex, toolType)
	local v185_ = self.spec_fillUnit
	if v185_.fillUnits[fillUnitIndex] == nil then
		return false
	else
		return v185_.fillUnits[fillUnitIndex].supportedToolTypes[toolType]
	end
end

function FillUnit:getFillUnitSupportsToolTypeAndFillType(fillUnitIndex, toolType, fillType)
	local v190_ = self:getFillUnitSupportsToolType(fillUnitIndex, toolType)
	if v190_ then
		v190_ = self:getFillUnitSupportsFillType(fillUnitIndex, fillType)
	end
	return v190_
end

-- Local values: spec
function FillUnit:getFillUnitSupportedFillTypes(fillUnitIndex)
	local v193_ = self.spec_fillUnit
	if v193_.fillUnits[fillUnitIndex] == nil then
		return nil
	else
		return v193_.fillUnits[fillUnitIndex].supportedFillTypes
	end
end

-- Local values: spec
function FillUnit:getFillUnitSupportedToolTypes(fillUnitIndex)
	local v196_ = self.spec_fillUnit
	if v196_.fillUnits[fillUnitIndex] == nil then
		return nil
	else
		return v196_.fillUnits[fillUnitIndex].supportedToolTypes
	end
end

-- Local values: spec
function FillUnit:getFillUnitAllowsFillType(fillUnitIndex, fillType)
	local v200_ = self.spec_fillUnit
	if v200_.fillUnits[fillUnitIndex] == nil or not self:getFillUnitSupportsFillType(fillUnitIndex, fillType) then
		return false
	end
	if fillType == v200_.fillUnits[fillUnitIndex].fillType then
		return true
	end
	local v201_ = v200_.fillUnits[fillUnitIndex].fillLevel
	local v202_ = v200_.fillUnits[fillUnitIndex].capacity
	return v201_ / math.max(v202_, 0.0001) <= self:getFillTypeChangeThreshold()
end

-- Local values: capacity
function FillUnit:getFillTypeChangeThreshold(fillUnitIndex)
	if fillUnitIndex == nil then
		return self.spec_fillUnit.fillTypeChangeThreshold
	else
		return (self:getFillUnitCapacity(fillUnitIndex) or 1) * self.spec_fillUnit.fillTypeChangeThreshold
	end
end

-- Local values: spec, fillUnitIndex, _
function FillUnit:getFirstValidFillUnitToFill(fillType, ignoreCapacity)
	local v208_ = self.spec_fillUnit
	for v209_, _ in ipairs(v208_.fillUnits) do
		if self:getFillUnitAllowsFillType(v209_, fillType) and (self:getFillUnitFreeCapacity(v209_) > 0 or ignoreCapacity ~= nil and ignoreCapacity) then
			return v209_
		end
	end
	return nil
end

function FillUnit:getFillUnitCanBeFilled(fillUnitIndex, fillType, ignoreCapacity)
	return self:getFillUnitAllowsFillType(fillUnitIndex, fillType) and (self:getFillUnitFreeCapacity(fillUnitIndex) > 0 or ignoreCapacity ~= nil and ignoreCapacity) and true or false
end

-- Local values: spec, oldFillTypeIndex
function FillUnit:setFillUnitFillType(fillUnitIndex, fillTypeIndex)
	local v217_ = self.spec_fillUnit
	local v218_ = v217_.fillUnits[fillUnitIndex].fillType
	if v218_ ~= fillTypeIndex then
		v217_.fillUnits[fillUnitIndex].fillType = fillTypeIndex
		SpecializationUtil.raiseEvent(self, "onChangedFillType", fillUnitIndex, fillTypeIndex, v218_)
	end
end

-- Local values: spec
function FillUnit:setFillUnitFillTypeToDisplay(fillUnitIndex, fillTypeIndex, isPersistent)
	local v223_ = self.spec_fillUnit
	if v223_.fillUnits[fillUnitIndex] ~= nil then
		v223_.fillUnits[fillUnitIndex].fillTypeToDisplay = fillTypeIndex
		local v224_ = v223_.fillUnits[fillUnitIndex]
		if isPersistent == nil then
			isPersistent = false
		end
		v224_.fillTypeToDisplayIsPersistent = isPersistent
	end
end

-- Local values: spec
function FillUnit:setFillUnitFillLevelToDisplay(fillUnitIndex, fillLevel, isPersistent)
	local v229_ = self.spec_fillUnit
	if v229_.fillUnits[fillUnitIndex] ~= nil then
		v229_.fillUnits[fillUnitIndex].fillLevelToDisplay = fillLevel
		local v230_ = v229_.fillUnits[fillUnitIndex]
		if isPersistent == nil then
			isPersistent = false
		end
		v230_.fillLevelToDisplayIsPersistent = isPersistent
	end
end

-- Local values: spec
function FillUnit:setFillUnitCapacityToDisplay(fillUnitIndex, capacity)
	local v234_ = self.spec_fillUnit
	if v234_.fillUnits[fillUnitIndex] ~= nil then
		v234_.fillUnits[fillUnitIndex].capacityToDisplay = capacity
	end
end

-- Local values: spec
function FillUnit:setFillUnitCapacity(fillUnitIndex, capacity, noEventSend)
	local v239_ = self.spec_fillUnit
	if v239_.fillUnits[fillUnitIndex] ~= nil and capacity ~= v239_.fillUnits[fillUnitIndex].capacity then
		v239_.fillUnits[fillUnitIndex].capacity = capacity
		SetFillUnitCapacityEvent.sendEvent(self, fillUnitIndex, capacity, noEventSend)
	end
end

-- Local values: spec
function FillUnit:setFillUnitForcedMaterialFillType(fillUnitIndex, forcedMaterialFillType)
	local v243_ = self.spec_fillUnit
	if v243_.fillUnits[fillUnitIndex] ~= nil then
		v243_.fillUnits[fillUnitIndex].forcedMaterialFillType = forcedMaterialFillType
	end
	self:setFillPlaneForcedFillType(fillUnitIndex, forcedMaterialFillType)
	if self.setFillVolumeForcedFillTypeByFillUnitIndex ~= nil then
		self:setFillVolumeForcedFillTypeByFillUnitIndex(fillUnitIndex, forcedMaterialFillType)
	end
end

-- Local values: spec
function FillUnit:getFillUnitForcedMaterialFillType(fillUnitIndex)
	local v246_ = self.spec_fillUnit
	if v246_.fillUnits[fillUnitIndex] == nil then
		return FillType.UNKNOWN
	else
		return v246_.fillUnits[fillUnitIndex].forcedMaterialFillType
	end
end

function FillUnit:setFillUnitInTriggerRange(fillUnitIndex, isInRange) end

-- Local values: _, alarmTrigger, isActive
function FillUnit:updateAlarmTriggers(alarmTriggers, fillLevelDelta)
	for _, v250_ in pairs(alarmTriggers) do
		local v251_ = self:getAlarmTriggerIsActive(v250_)
		if v250_.direction ~= 0 then
			fillLevelDelta = fillLevelDelta or v250_.lastDeltaFillLevel
			if fillLevelDelta == nil then
				v251_ = false
			else
				if math.sign(fillLevelDelta) ~= v250_.direction then
					v251_ = false
				end
				v250_.lastDeltaFillLevel = fillLevelDelta
			end
		end
		self:setAlarmTriggerState(v250_, v251_)
	end
end

-- Local values: ret, fillLevelPct
function FillUnit:getAlarmTriggerIsActive(alarmTrigger)
	local v253_ = alarmTrigger.fillUnit.fillLevel / alarmTrigger.fillUnit.capacity
	return alarmTrigger.minFillLevel <= v253_ and v253_ <= alarmTrigger.maxFillLevel
end

-- Local values: spec, _, beaconLight, _, beaconLight
function FillUnit:setAlarmTriggerState(alarmTrigger, state)
	local v257_ = self.spec_fillUnit
	if state ~= alarmTrigger.isActive then
		if state then
			if alarmTrigger.sample ~= nil then
				g_soundManager:playSample(alarmTrigger.sample)
			end
			for _, v_u_258_ in ipairs(alarmTrigger.beaconLights) do
				v_u_258_:setIsActive(true)
				if v_u_258_.activeDuration ~= 0 then
					Timer.createOneshot(v_u_258_.activeDuration, function()
						-- upvalues: (copy) v_u_258_
						v_u_258_:setIsActive(false)
					end)
				end
			end
			v257_.activeAlarmTriggers[alarmTrigger] = alarmTrigger
		else
			if alarmTrigger.sample ~= nil then
				g_soundManager:stopSample(alarmTrigger.sample)
			end
			for _, v259_ in ipairs(alarmTrigger.beaconLights) do
				v259_:setIsActive(false)
			end
			v257_.activeAlarmTriggers[alarmTrigger] = nil
		end
		alarmTrigger.isActive = state
		SpecializationUtil.raiseEvent(self, "onAlarmTriggerChanged", alarmTrigger, state)
	end
end

-- Local values: spec, fillUnit
function FillUnit:getFillUnitIndexFromNode(node)
	local v262_ = self.spec_fillUnit.exactFillRootNodeToFillUnit[node]
	if v262_ == nil then
		return nil
	else
		return v262_.fillUnitIndex
	end
end

-- Local values: spec
function FillUnit:getFillUnitExtraDistanceFromNode(node)
	return self.spec_fillUnit.exactFillRootNodeToExtraDistance[node] or 0
end

-- Local values: spec
function FillUnit:getFillUnitFromNode(node)
	return self.spec_fillUnit.exactFillRootNodeToFillUnit[node]
end

-- Local values: spec, oldRemoveOnEmpty, k, _, fillTypeIndex
function FillUnit:emptyAllFillUnits(ignoreDeleteOnEmptyFlag)
	local v269_ = self.spec_fillUnit
	local v270_ = v269_.removeVehicleIfEmpty
	if ignoreDeleteOnEmptyFlag then
		v269_.removeVehicleIfEmpty = false
	end
	for v271_, _ in ipairs(self:getFillUnits()) do
		local v272_ = self:getFillUnitFillType(v271_)
		self:addFillUnitFillLevel(self:getOwnerFarmId(), v271_, -math.huge, v272_, ToolType.UNDEFINED, nil)
	end
	v269_.removeVehicleIfEmpty = v270_
end

function FillUnit:loadFillUnitUnloadingFromXML(xmlFile, key, entry, index)
	entry.node = xmlFile:getValue(key .. "#node", self.rootNode, self.components, self.i3dMappings)
	entry.width = xmlFile:getValue(key .. "#width", 15)
	entry.offset = xmlFile:getValue(key .. "#offset", "0 0 0", true)
	return true
end

-- Local values: fillTypeIndex, fillType
function FillUnit:getFillUnitUnloadPalletFilename(fillUnitIndex)
	local v279_ = self:getFillUnitFillType(fillUnitIndex)
	if v279_ == FillType.UNKNOWN then
		return nil
	else
		return g_fillTypeManager:getFillTypeByIndex(v279_).palletFilename
	end
end

function FillUnit:getFillUnitHasMountedPalletsToUnload()
	return false
end

function FillUnit:getFillUnitMountedPalletsToUnload()
	return nil
end

-- Local values: unloadingTasks, fillUnitIndex, fillUnit, fillLevel, palletFilename, fillTypeIndex
function FillUnit:getFillUnitUnloadingTasks()
	local v281_ = {}
	for v282_, v283_ in ipairs(self:getFillUnits()) do
		local v284_ = self:getFillUnitFillLevel(v282_)
		if v283_.canBeUnloaded and self:getFillUnitFillLevel(v282_) > 0 then
			local v285_ = self:getFillUnitUnloadPalletFilename(v282_)
			if v285_ ~= nil then
				local v286_ = {
					["fillUnitIndex"] = v282_,
					["fillTypeIndex"] = self:getFillUnitFillType(v282_),
					["fillLevel"] = v284_,
					["filename"] = v285_
				}
				table.insert(v281_, v286_)
			end
		end
	end
	return v281_
end

function FillUnit:getFillUnitEmptyOnReset()
	return true
end

function FillUnit:getAllowLoadTriggerActivation(rootVehicle)
	return self.rootVehicle == g_localPlayer:getCurrentVehicle()
end

-- Local values: spec
function FillUnit:addExactFillRootAimToUpdate(vehicle, func)
	self.spec_fillUnit.exactFillRootNodeAimToUpdate[vehicle] = func
end

-- Local values: spec, unloadingPlaces, places, _, unloading, node, ox, oy, oz, x, y, z, place, usedPlaces, availablePallets, unloadingTasks, pallets, i, pallet, x, y, z, place, width, _, rotY, unloadNext
function FillUnit:unloadFillUnits(ignoreWarning)
	if self.isServer then
		local v_u_293_ = self.spec_fillUnit
		if not v_u_293_.unloadingFillUnitsRunning then
			v_u_293_.unloadingFillUnitsRunning = true
			local v294_ = v_u_293_.unloading
			local v_u_295_ = {}
			for _, v296_ in ipairs(v294_) do
				local v297_ = v296_.node
				local v298_ = v296_.offset
				local v299_, v300_, v301_ = unpack(v298_)
				local v302_, v303_, v304_ = localToWorld(v297_, v299_ - v296_.width * 0.5, v300_, v301_)
				local v305_ = {
					["startX"] = v302_,
					["startY"] = v303_,
					["startZ"] = v304_
				}
				local v306_, v307_, v308_ = getWorldRotation(v297_)
				v305_.rotX = v306_
				v305_.rotY = v307_
				v305_.rotZ = v308_
				local v309_, v310_, v311_ = localDirectionToWorld(v297_, 1, 0, 0)
				v305_.dirX = v309_
				v305_.dirY = v310_
				v305_.dirZ = v311_
				local v312_, v313_, v314_ = localDirectionToWorld(v297_, 0, 0, 1)
				v305_.dirPerpX = v312_
				v305_.dirPerpY = v313_
				v305_.dirPerpZ = v314_
				v305_.yOffset = 1
				v305_.maxWidth = math.huge
				v305_.maxLength = math.huge
				v305_.maxHeight = math.huge
				v305_.width = v296_.width
				table.insert(v_u_295_, v305_)
			end
			local v_u_315_ = {}
			local v_u_316_ = {}
			local v_u_317_ = self:getFillUnitUnloadingTasks()
			if self:getFillUnitHasMountedPalletsToUnload() then
				local v318_ = self:getFillUnitMountedPalletsToUnload()
				if v318_ ~= nil and #v318_ > 0 then
					for _, v319_ in ipairs(v318_) do
						local v320_, v321_, v322_, v323_, v324_, _ = PlacementUtil.getPlace(v_u_295_, v319_.size, v_u_315_, true, true, false, true)
						if v320_ == nil then
							if ignoreWarning == nil or not ignoreWarning then
								g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, v_u_293_.texts.unloadNoSpace)
							end
							g_server:broadcastEvent(FillUnitUnloadedEvent.new(self, nil, true), false, nil, self)
						else
							if v319_.unmount ~= nil then
								v319_:unmount(true)
							end
							PlacementUtil.markPlaceUsed(v_u_315_, v323_, v324_)
							v319_:setAbsolutePosition(v320_, v321_, v322_, 0, MathUtil.getYRotationFromDirection(v323_.dirPerpX, v323_.dirPerpZ), 0)
							SpecializationUtil.raiseEvent(self, "onFillUnitUnloadPallet", v319_)
							g_server:broadcastEvent(FillUnitUnloadedEvent.new(self, v319_), false, nil, self)
						end
					end
				end
			end
			local function v_u_334_()
				-- upvalues: (copy) v_u_317_, (copy) v_u_316_, (copy) self, (copy) v_u_334_, (copy) ignoreWarning, (copy) v_u_293_, (copy) v_u_295_, (copy) v_u_315_
				local v325_ = v_u_317_[1]
				if v325_ == nil then
					SpecializationUtil.raiseEvent(self, "onFillUnitUnloaded", true)
					g_server:broadcastEvent(FillUnitUnloadedEvent.new(self, nil, false, true), false, nil, self)
					v_u_293_.unloadingFillUnitsRunning = false
					return
				else
					for v326_, _ in pairs(v_u_316_) do
						local v327_ = v326_:getFirstValidFillUnitToFill(v325_.fillTypeIndex)
						if v327_ ~= nil then
							local v328_ = v326_:addFillUnitFillLevel(self:getOwnerFarmId(), v327_, v325_.fillLevel, v325_.fillTypeIndex, ToolType.UNDEFINED, nil)
							self:addFillUnitFillLevel(self:getOwnerFarmId(), v325_.fillUnitIndex, -v328_, v325_.fillTypeIndex, ToolType.UNDEFINED, nil)
							v325_.fillLevel = v325_.fillLevel - v328_
							if v326_:getFillUnitFreeCapacity(v327_) <= 0 then
								v_u_316_[v326_] = nil
							end
						end
					end
					if v325_.fillLevel > 0.01 then
						local function v332_(_, p329_, p330_, _)
							-- upvalues: (ref) v_u_316_, (ref) self, (ref) v_u_334_, (ref) ignoreWarning, (ref) v_u_293_
							if p330_ == VehicleLoadingState.OK then
								for _, v331_ in ipairs(p329_) do
									v331_:emptyAllFillUnits(true)
									v_u_316_[v331_] = true
									SpecializationUtil.raiseEvent(self, "onFillUnitUnloadPallet", v331_)
								end
								v_u_334_()
							elseif p330_ == VehicleLoadingState.NO_SPACE then
								if ignoreWarning == nil or not ignoreWarning then
									g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, v_u_293_.texts.unloadNoSpace)
								end
								SpecializationUtil.raiseEvent(self, "onFillUnitUnloaded", false)
								g_server:broadcastEvent(FillUnitUnloadedEvent.new(self, nil, true, false), false, nil, self)
								v_u_293_.unloadingFillUnitsRunning = false
							end
						end
						local v333_ = VehicleLoadingData.new()
						v333_:setFilename(v325_.filename)
						v333_:setLoadingPlace(v_u_295_, v_u_315_, 0.5, true)
						v333_:setPropertyState(VehiclePropertyState.OWNED)
						v333_:setOwnerFarmId(self:getOwnerFarmId())
						v333_:load(v332_)
					else
						table.remove(v_u_317_, 1)
						v_u_334_()
					end
				end
			end
			v_u_334_()
		end
	else
		g_client:getServerConnection():sendEvent(FillUnitUnloadEvent.new(self))
		return
	end
end

-- Local values: spec, mounter, fillUnit, maxMassToApply, fillTypeDesc, oldFillLevel, capacity, fillTypeChanged, allowFillType, oldFillTypeIndex, oldRemoveOnEmpty, appliedDelta, hasChanged, maxValue, levelPerBit, changedLevel, animTime, direction, _, fillLevelAnimation, currentTime, targetTime, speedScale, animTime, direction
function FillUnit:addFillUnitFillLevel(farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
	local v_u_342_ = self.spec_fillUnit
	v_u_342_.isInfoDirty = true
	if fillLevelDelta < 0 and not (g_currentMission.accessHandler:canFarmAccess(farmId, self, true) or g_guidedTourManager:getIsTourRunning()) then
		return 0
	end
	if self.getDynamicMountObject ~= nil then
		local v343_ = self:getDynamicMountObject()
		if v343_ ~= nil and not g_currentMission.accessHandler:canFarmAccess(v343_:getActiveFarm(), self, true) then
			return 0
		end
	end
	local v344_ = v_u_342_.fillUnits[fillUnitIndex]
	if v344_ == nil then
		return 0
	end
	if fillLevelDelta > 0 and (not v344_.ignoreFillLimit and (g_currentMission.missionInfo.trailerFillLimit and self:getMaxComponentMassReached())) then
		return 0
	end
	if not self:getFillUnitSupportsToolTypeAndFillType(fillUnitIndex, toolType, fillTypeIndex) then
		return 0
	end
	if self.isServer and (fillLevelDelta > 0 and (not v344_.ignoreFillLimit and g_currentMission.missionInfo.trailerFillLimit)) then
		local v345_ = self:getAvailableComponentMass()
		local v346_ = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
		if v346_ ~= nil and v346_.massPerLiter ~= 0 then
			local v347_ = v345_ / v346_.massPerLiter
			fillLevelDelta = math.min(fillLevelDelta, v347_)
		end
	end
	local v348_ = v344_.fillLevel
	local v349_ = v344_.capacity
	local v350_ = v349_ == 0 and math.huge or v349_
	local v351_ = false
	if v344_.fillType == fillTypeIndex then
		local v352_ = v348_ + fillLevelDelta
		local v353_ = math.min(v350_, v352_)
		v344_.fillLevel = math.max(0, v353_)
	elseif fillLevelDelta > 0 then
		if not self:getFillUnitAllowsFillType(fillUnitIndex, fillTypeIndex) then
			return 0
		end
		local v354_ = v344_.fillType
		if v348_ > 0 then
			local v355_ = v_u_342_.removeVehicleIfEmpty
			v_u_342_.removeVehicleIfEmpty = false
			self:addFillUnitFillLevel(farmId, fillUnitIndex, -math.huge, v344_.fillType, toolType, fillPositionData)
			v_u_342_.removeVehicleIfEmpty = v355_
		end
		local v356_ = math.min(v350_, fillLevelDelta)
		v344_.fillLevel = math.max(0, v356_)
		v344_.fillType = fillTypeIndex
		self.rootVehicle:raiseStateChange(VehicleStateChange.FILLTYPE_CHANGE)
		SpecializationUtil.raiseEvent(self, "onChangedFillType", fillUnitIndex, fillTypeIndex, v354_)
		v348_ = 0
		v351_ = true
	end
	if v344_.fillLevel < 0.00001 then
		v344_.fillLevel = 0
	end
	if v344_.fillLevel > 0 then
		v344_.lastValidFillType = v344_.fillType
	else
		SpecializationUtil.raiseEvent(self, "onChangedFillType", fillUnitIndex, FillType.UNKNOWN, v344_.fillType)
		v344_.fillType = FillType.UNKNOWN
		if not v344_.fillTypeToDisplayIsPersistent then
			v344_.fillTypeToDisplay = FillType.UNKNOWN
		end
		if not v344_.fillLevelToDisplayIsPersistent then
			v344_.fillLevelToDisplay = nil
		end
	end
	local v357_ = v344_.fillLevel - v348_
	if self.isServer and v344_.synchronizeFillLevel then
		local v358_ = false
		if v344_.fillLevel ~= v344_.fillLevelSent then
			local v359_ = 2 ^ v344_.synchronizationNumBits - 1
			local v360_ = v344_.capacity / v359_
			local v361_ = v344_.fillLevel - v344_.fillLevelSent
			if v360_ < math.abs(v361_) then
				v344_.fillLevelSent = v344_.fillLevel
				v358_ = true
			end
		end
		if v344_.fillType ~= v344_.fillTypeSent then
			v344_.fillTypeSent = v344_.fillType
			v358_ = true
		end
		if v344_.lastValidFillType ~= v344_.lastValidFillTypeSent then
			v344_.lastValidFillTypeSent = v344_.lastValidFillType
			v358_ = true
		end
		if v358_ then
			self:raiseDirtyFlags(v_u_342_.dirtyFlag)
		end
	end
	if v344_.updateMass then
		self:setMassDirty()
	end
	self:updateFillUnitAutoAimTarget(v344_)
	if self.isClient then
		self:updateAlarmTriggers(v344_.alarmTriggers, fillLevelDelta)
		self:updateFillUnitFillPlane(v344_)
		self:updateMeasurementNodes(v344_, 0, true)
		if v351_ then
			self:updateFillTypeMaterials(v344_.fillTypeMaterials, v344_.fillType)
		end
	end
	SpecializationUtil.raiseEvent(self, "onFillUnitFillLevelChanged", fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData, v357_)
	if self.isServer and (v_u_342_.removeVehicleIfEmpty and (v344_.fillLevel <= v_u_342_.removeVehicleThreshold and fillLevelDelta ~= 0)) then
		if v_u_342_.removeVehicleDelay == 0 then
			self:delete()
			if v_u_342_.removeVehicleReward > 0 then
				g_currentMission:addMoney(v_u_342_.removeVehicleReward, self:getOwnerFarmId(), MoneyType.SOLD_PRODUCTS, true, true)
			end
		else
			Timer.createOneshot(v_u_342_.removeVehicleDelay, function()
				-- upvalues: (copy) self, (copy) v_u_342_
				if not self.isDeleted then
					self:delete()
				end
				if v_u_342_.removeVehicleReward > 0 then
					g_currentMission:addMoney(v_u_342_.removeVehicleReward, self:getOwnerFarmId(), MoneyType.SOLD_PRODUCTS, true, true)
				end
			end)
		end
	end
	if v357_ > 0 then
		if #v_u_342_.fillEffects > 0 then
			g_effectManager:setEffectTypeInfo(v_u_342_.fillEffects, v344_.fillType)
			g_effectManager:startEffects(v_u_342_.fillEffects)
			v_u_342_.activeFillEffects[v_u_342_.fillEffects] = 500
		end
		if #v344_.fillEffects > 0 then
			g_effectManager:setEffectTypeInfo(v344_.fillEffects, v344_.fillType)
			g_effectManager:startEffects(v344_.fillEffects)
			v_u_342_.activeFillEffects[v344_.fillEffects] = 500
		end
		if #v_u_342_.animationNodes > 0 then
			g_animationManager:startAnimations(v_u_342_.animationNodes)
			v_u_342_.activeFillAnimations[v_u_342_.animationNodes] = 500
		end
		if #v344_.animationNodes > 0 then
			g_animationManager:startAnimations(v344_.animationNodes)
			v_u_342_.activeFillAnimations[v344_.animationNodes] = 500
		end
		if v344_.fillAnimation ~= nil and v344_.fillAnimationLoadTime ~= nil then
			local v362_ = self:getAnimationTime(v344_.fillAnimation)
			local v363_ = v344_.fillAnimationLoadTime - v362_
			local v364_ = math.sign(v363_)
			if v364_ ~= 0 then
				self:playAnimation(v344_.fillAnimation, v364_, v362_)
				self:setAnimationStopTime(v344_.fillAnimation, v344_.fillAnimationLoadTime)
			end
		end
	end
	if v357_ ~= 0 then
		for _, v365_ in ipairs(v344_.fillLevelAnimations) do
			if v344_.fillLevel > 0 or v365_.resetOnEmpty then
				local v366_ = self:getAnimationTime(v365_.name)
				local v367_ = v344_.fillLevel / v344_.capacity
				local v368_ = v365_.useMaxStateIfEmpty and v344_.fillLevel == 0 and 1 or v367_
				local v369_ = not v365_.updateWhileFilled and fillLevelDelta > 0 and 1 or v368_
				self:setAnimationStopTime(v365_.name, v369_)
				local v370_ = v369_ - v366_
				local v371_ = math.sign(v370_)
				self:playAnimation(v365_.name, v371_, v366_, true)
			end
		end
		if v344_.hasDashboards and self.updateDashboardValueType ~= nil then
			self:updateDashboardValueType("fillUnit.fillLevel")
			self:updateDashboardValueType("fillUnit.fillLevelPct")
			self:updateDashboardValueType("fillUnit.fillLevelWarning")
		end
		FillUnit.updateUnloadActionDisplay(self)
	end
	if v344_.fillLevel < 0.0001 and (v344_.fillAnimation ~= nil and v344_.fillAnimationEmptyTime ~= nil) then
		local v372_ = self:getAnimationTime(v344_.fillAnimation)
		local v373_ = v344_.fillAnimationEmptyTime - v372_
		local v374_ = math.sign(v373_)
		self:playAnimation(v344_.fillAnimation, v374_, v372_)
		self:setAnimationStopTime(v344_.fillAnimation, v344_.fillAnimationEmptyTime)
	end
	if self.isServer and (not v_u_342_.allowFoldingWhileFilled and v_u_342_.resetFoldingWhileFilled) and (v344_.fillLevel > (v344_.allowFoldingThreshold or v_u_342_.allowFoldingThreshold) and (v344_.allowFoldingFillType == nil or v344_.allowFoldingFillType == v344_.fillType) and self:getIsUnfolded()) then
		self:setFoldState(-self.spec_foldable.turnOnFoldDirection, false)
	end
	return v357_
end

-- Local values: spec, fillUnit
function FillUnit:setFillUnitLastValidFillType(fillUnitIndex, fillType, force)
	local v378_ = self.spec_fillUnit
	local v379_ = v378_.fillUnits[fillUnitIndex]
	if v379_ ~= nil and v379_.lastValidFillType ~= fillType then
		v379_.lastValidFillType = fillType
		v379_.lastValidFillTypeSent = fillType
		self:raiseDirtyFlags(v378_.dirtyFlag)
	end
end

-- Local values: spec, allowFoldingFillTypeName, allowFoldingFillTypeIndex, startZ, fillTypes, fillTypeCategories, fillTypeNames, _, fillType, i, startFillLevel, startFillTypeStr, startFillTypeIndex, updateFillLevelMass, defaultBits, startCapacity, bits, unitText, _, key, fillLevelAnimation, i, nodeKey, alarmTrigger, nodeKey, measurementNode, fillUnitLoadFunc, fillUnitLoadFuncWarning, fillLevel, fillLevelPct, fillLevelWarning
function FillUnit:loadFillUnitFromXML(xmlFile, key, entry, index)
	local v_u_385_ = self.spec_fillUnit
	entry.fillUnitIndex = index
	entry.capacity = xmlFile:getValue(key .. "#capacity", math.huge)
	entry.defaultCapacity = entry.capacity
	entry.updateMass = xmlFile:getValue(key .. "#updateMass", true)
	entry.canBeUnloaded = xmlFile:getValue(key .. "#canBeUnloaded", true)
	entry.allowFoldingThreshold = xmlFile:getValue(key .. "#allowFoldingThreshold")
	local v386_ = xmlFile:getValue(key .. "#allowFoldingFillType")
	if v386_ ~= nil then
		local v387_ = g_fillTypeManager:getFillTypeIndexByName(v386_)
		if v387_ == nil then
			Logging.xmlWarning(self.xmlFile, "Invalid fill type for fill unit in \'%s\'", v386_, key .. "#allowFoldingFillType")
		else
			entry.allowFoldingFillType = v387_
		end
	end
	entry.needsSaving = true
	entry.fillLevel = 0
	entry.fillLevelSent = 0
	entry.fillType = FillType.UNKNOWN
	entry.fillTypeSent = FillType.UNKNOWN
	entry.fillTypeToDisplay = FillType.UNKNOWN
	entry.fillLevelToDisplay = nil
	entry.capacityToDisplay = nil
	entry.lastValidFillType = FillType.UNKNOWN
	entry.lastValidFillTypeSent = FillType.UNKNOWN
	if xmlFile:hasProperty(key .. ".exactFillRootNode") then
		XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. ".exactFillRootNode#index", key .. ".exactFillRootNode#node")
		entry.exactFillRootNode = xmlFile:getValue(key .. ".exactFillRootNode#node", nil, self.components, self.i3dMappings)
		if entry.exactFillRootNode == nil then
			Logging.xmlWarning(self.xmlFile, "ExactFillRootNode not found for fillUnit \'%s\'!", key)
		elseif CollisionFlag.getHasGroupFlagSet(entry.exactFillRootNode, CollisionFlag.FILLABLE) then
			v_u_385_.exactFillRootNodeToFillUnit[entry.exactFillRootNode] = entry
			v_u_385_.exactFillRootNodeToExtraDistance[entry.exactFillRootNode] = xmlFile:getValue(key .. ".exactFillRootNode#extraEffectDistance", 0)
			v_u_385_.hasExactFillRootNodes = true
			g_currentMission:addNodeObject(entry.exactFillRootNode, self)
		else
			Logging.xmlWarning(self.xmlFile, "Missing collision group %s. Please add this bit to exact fill root node \'%s\' collision filter group in \'%s\'", CollisionFlag.getBitAndName(CollisionFlag.FILLABLE), getName(entry.exactFillRootNode), key)
		end
	end
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. ".autoAimTargetNode#index", key .. ".autoAimTargetNode#node")
	entry.autoAimTarget = {}
	entry.autoAimTarget.node = xmlFile:getValue(key .. ".autoAimTargetNode#node", nil, self.components, self.i3dMappings)
	if entry.autoAimTarget.node ~= nil then
		entry.autoAimTarget.baseTrans = { getTranslation(entry.autoAimTarget.node) }
		entry.autoAimTarget.startZ = xmlFile:getValue(key .. ".autoAimTargetNode#startZ")
		entry.autoAimTarget.endZ = xmlFile:getValue(key .. ".autoAimTargetNode#endZ")
		entry.autoAimTarget.startPercentage = xmlFile:getValue(key .. ".autoAimTargetNode#startPercentage", 25) / 100
		entry.autoAimTarget.invert = xmlFile:getValue(key .. ".autoAimTargetNode#invert", false)
		if entry.autoAimTarget.startZ ~= nil and entry.autoAimTarget.endZ ~= nil then
			local v388_ = entry.autoAimTarget.startZ
			if entry.autoAimTarget.invert then
				v388_ = entry.autoAimTarget.endZ
			end
			setTranslation(entry.autoAimTarget.node, entry.autoAimTarget.baseTrans[1], entry.autoAimTarget.baseTrans[2], v388_)
		end
	end
	entry.supportedFillTypes = {}
	local v389_ = xmlFile:getValue(key .. "#fillTypeCategories")
	local v390_ = xmlFile:getValue(key .. "#fillTypes")
	local v391_
	if v389_ == nil or v390_ ~= nil then
		if v389_ ~= nil or v390_ == nil then
			Logging.xmlWarning(self.xmlFile, "Missing \'fillTypeCategories\' or \'fillTypes\' for fillUnit \'%s\'", key)
			return false
		end
		v391_ = g_fillTypeManager:getFillTypesByNames(v390_, "Warning: \'" .. self.configFileName .. "\' has invalid fillType \'%s\'.")
	else
		v391_ = g_fillTypeManager:getFillTypesByCategoryNames(v389_, "Warning: \'" .. self.configFileName .. "\' has invalid fillTypeCategory \'%s\'.")
	end
	if v391_ ~= nil then
		for _, v392_ in pairs(v391_) do
			entry.supportedFillTypes[v392_] = true
		end
	end
	entry.supportedToolTypes = {}
	for v393_ = 1, g_toolTypeManager:getNumberOfToolTypes() do
		entry.supportedToolTypes[v393_] = true
	end
	local v394_ = xmlFile:getValue(key .. "#startFillLevel")
	local v395_ = xmlFile:getValue(key .. "#startFillType")
	if v395_ ~= nil then
		local v396_ = g_fillTypeManager:getFillTypeIndexByName(v395_)
		if v396_ ~= nil then
			entry.startFillLevel = v394_
			entry.startFillTypeIndex = v396_
		end
	end
	entry.fillRootNode = xmlFile:getValue(key .. ".fillRootNode#node", nil, self.components, self.i3dMappings)
	if entry.fillRootNode == nil then
		entry.fillRootNode = self.components[1].node
	end
	entry.fillMassNode = xmlFile:getValue(key .. ".fillMassNode#node", nil, self.components, self.i3dMappings)
	local v397_ = xmlFile:getValue(key .. "#updateFillLevelMass", true)
	if entry.fillMassNode == nil and v397_ then
		entry.fillMassNode = self.components[1].node
	end
	entry.ignoreFillLimit = xmlFile:getValue(key .. "#ignoreFillLimit", false)
	entry.synchronizeFillLevel = xmlFile:getValue(key .. "#synchronizeFillLevel", true)
	entry.synchronizeFullFillLevel = xmlFile:getValue(key .. "#synchronizeFullFillLevel", false)
	local v398_ = 16
	for v399_, v400_ in pairs(FillUnit.CAPACITY_TO_NETWORK_BITS) do
		if v399_ <= entry.capacity then
			v398_ = v400_
		end
	end
	entry.synchronizationNumBits = xmlFile:getValue(key .. "#synchronizationNumBits", v398_)
	entry.showOnHud = xmlFile:getValue(key .. "#showOnHud", true)
	entry.showOnInfoHud = xmlFile:getValue(key .. "#showOnInfoHud", true)
	entry.uiPrecision = xmlFile:getValue(key .. "#uiPrecision", 0)
	entry.uiCustomFillTypeName = xmlFile:getValue(key .. "#uiCustomFillTypeName", nil, self.customEnvironment, false)
	entry.uiExtraInfoText = xmlFile:getValue(key .. "#uiExtraInfoText", nil, self.customEnvironment, false)
	entry.uiDisplayTypeId = FillLevelsDisplay["TYPE_" .. xmlFile:getValue(key .. "#uiDisplayType", "BAR")] or FillLevelsDisplay.TYPE_BAR
	local v401_ = xmlFile:getValue(key .. "#unitTextOverride")
	if v401_ ~= nil then
		entry.unitText = g_i18n:convertText(v401_)
	end
	entry.parentUnitOnHud = nil
	entry.childUnitOnHud = nil
	entry.blocksAutomatedTrainTravel = xmlFile:getValue(key .. "#blocksAutomatedTrainTravel", false)
	entry.fillAnimation = xmlFile:getValue(key .. "#fillAnimation")
	entry.fillAnimationLoadTime = xmlFile:getValue(key .. "#fillAnimationLoadTime")
	entry.fillAnimationEmptyTime = xmlFile:getValue(key .. "#fillAnimationEmptyTime")
	entry.fillLevelAnimations = {}
	for _, v402_ in xmlFile:iterator(key .. ".fillLevelAnimation") do
		local v403_ = {
			["name"] = xmlFile:getValue(v402_ .. "#name")
		}
		if v403_.name == nil then
			Logging.xmlWarning(xmlFile, "Missing \'name\' for fillLevelAnimation \'%s\'", v402_)
		else
			v403_.resetOnEmpty = xmlFile:getValue(v402_ .. "#resetOnEmpty", true)
			v403_.updateWhileFilled = xmlFile:getValue(v402_ .. "#updateWhileFilled", true)
			v403_.useMaxStateIfEmpty = xmlFile:getValue(v402_ .. "#useMaxStateIfEmpty", false)
			local v404_ = entry.fillLevelAnimations
			table.insert(v404_, v403_)
		end
	end
	if self.isClient then
		entry.alarmTriggers = {}
		local v405_ = 0
		while true do
			local v406_ = key .. string.format(".alarmTriggers.alarmTrigger(%d)", v405_)
			if not xmlFile:hasProperty(v406_) then
				break
			end
			local v407_ = {}
			if self:loadAlarmTrigger(xmlFile, v406_, v407_, entry) then
				local v408_ = entry.alarmTriggers
				table.insert(v408_, v407_)
			end
			v405_ = v405_ + 1
		end
		entry.measurementNodes = {}
		local v409_ = 0
		while true do
			local v410_ = key .. string.format(".measurementNodes.measurementNode(%d)", v409_)
			if not xmlFile:hasProperty(v410_) then
				break
			end
			local v411_ = {}
			if self:loadMeasurementNode(xmlFile, v410_, v411_) then
				local v412_ = entry.measurementNodes
				table.insert(v412_, v411_)
			end
			v409_ = v409_ + 1
		end
		entry.fillPlane = {}
		entry.lastFillPlaneType = nil
		if not self:loadFillPlane(xmlFile, key .. ".fillPlane", entry.fillPlane, entry) then
			entry.fillPlane = nil
		end
		entry.fillTypeMaterials = self:loadFillTypeMaterials(xmlFile, key)
		entry.fillEffects = g_effectManager:loadEffect(xmlFile, key .. ".fillEffect", self.components, self, self.i3dMappings)
		entry.animationNodes = g_animationManager:loadAnimations(xmlFile, key .. ".animationNodes", self.components, self, self.i3dMappings)
		XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. ".fillLevelHud", key .. ".dashboard")
		entry.hasDashboards = false
		if self.registerDashboardValueType ~= nil then
			local function v_u_420_(_, p413_, p414_, p415_, _)
				-- upvalues: (copy) v_u_385_, (copy) entry
				local v416_ = p413_:getValue(p414_ .. "#fillType")
				if v416_ ~= nil then
					local v417_ = g_fillTypeManager:getFillTypeIndexByName(v416_)
					if v417_ ~= nil then
						for _, v418_ in ipairs(v_u_385_.fillUnits) do
							if v418_.supportedFillTypes[v417_] then
								p415_.fillUnit = v418_
							end
						end
					end
				end
				local v419_ = p413_:getValue(p414_ .. "#fillUnitIndex")
				if v419_ ~= nil then
					p415_.fillUnit = v_u_385_.fillUnits[v419_]
				end
				if p415_.fillUnit == nil then
					entry.hasDashboards = true
				else
					p415_.fillUnit.hasDashboards = true
				end
				return true
			end
			local v421_ = DashboardValueType.new("fillUnit", "fillLevel")
			v421_:setXMLKey(key)
			v421_:setValue(entry, function(p422_, p423_)
				return (p423_.fillUnit or p422_).fillLevel
			end)
			v421_:setRange(0, function(p424_, p425_)
				return (p425_.fillUnit or p424_).capacity
			end)
			v421_:setInterpolationSpeed(function(p426_, p427_)
				return (p427_.fillUnit or p426_).capacity * 0.001
			end)
			v421_:setAdditionalFunctions(v_u_420_, nil)
			v421_:setPollUpdate(false)
			self:registerDashboardValueType(v421_)
			local v428_ = DashboardValueType.new("fillUnit", "fillLevelPct")
			v428_:setXMLKey(key)
			v428_:setValue(entry, function(p429_, p430_)
				local v431_ = p430_.fillUnit or p429_
				local v432_ = v431_.fillLevel / v431_.capacity
				return math.clamp(v432_, 0, 1) * 100
			end)
			v428_:setRange(0, 100)
			v428_:setInterpolationSpeed(0.1)
			v428_:setAdditionalFunctions(v_u_420_, nil)
			v428_:setPollUpdate(false)
			self:registerDashboardValueType(v428_)
			local v433_ = DashboardValueType.new("fillUnit", "fillLevelWarning")
			v433_:setXMLKey(key)
			v433_:setValue(entry, function(p434_, p435_)
				local v436_ = (p435_.fillUnit or p434_).fillLevel
				local v437_
				if p435_.warningThresholdMin < v436_ then
					v437_ = v436_ < p435_.warningThresholdMax
				else
					v437_ = false
				end
				return v437_
			end)
			v433_:setAdditionalFunctions(function(p438_, p439_, p440_, p441_, p442_)
				-- upvalues: (copy) v_u_420_
				v_u_420_(p438_, p439_, p440_, p441_, p442_)
				return Dashboard.warningAttributes(p438_, p439_, p440_, p441_, p442_)
			end)
			v433_:setPollUpdate(false)
			self:registerDashboardValueType(v433_)
		end
	end
	return true
end

-- Local values: success
function FillUnit:loadAlarmTrigger(xmlFile, key, alarmTrigger, fillUnit)
	alarmTrigger.fillUnit = fillUnit
	alarmTrigger.isActive = false
	alarmTrigger.minFillLevel = xmlFile:getValue(key .. "#minFillLevel")
	local v448_
	if alarmTrigger.minFillLevel == nil then
		Logging.xmlWarning(self.xmlFile, "Missing \'minFillLevel\' for alarmTrigger \'%s\'", key)
		v448_ = false
	else
		v448_ = true
	end
	alarmTrigger.maxFillLevel = xmlFile:getValue(key .. "#maxFillLevel")
	if alarmTrigger.maxFillLevel == nil then
		Logging.xmlWarning(self.xmlFile, "Missing \'maxFillLevel\' for alarmTrigger \'%s\'", key)
		v448_ = false
	end
	alarmTrigger.sample = g_soundManager:loadSampleFromXML(xmlFile, key, "alarmSound", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	alarmTrigger.beaconLights = {}
	xmlFile:iterate(key .. ".beaconLight", function(_, p449_)
		-- upvalues: (copy) alarmTrigger, (copy) xmlFile, (copy) self
		local v450_ = BeaconLight.loadFromVehicleXML(alarmTrigger.beaconLights, xmlFile, p449_, self)
		if v450_ ~= nil then
			v450_.activeDuration = xmlFile:getValue(p449_ .. "#activeDuration", 0)
		end
	end)
	alarmTrigger.direction = xmlFile:getValue(key .. "#direction", 0)
	return v448_
end

-- Local values: node
function FillUnit:loadMeasurementNode(xmlFile, key, entry)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#index", key .. "#node")
	local v455_ = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	if v455_ == nil then
		Logging.xmlWarning(self.xmlFile, "Missing \'node\' for measurementNode \'%s\'", key)
		return false
	end
	entry.node = v455_
	entry.measurementTime = 0
	entry.intensity = 0
	return true
end

-- Local values: _, measurementNode, intensity
function FillUnit:updateMeasurementNodes(fillUnit, dt, setActive, forcedIntensity)
	if fillUnit.measurementNodes ~= nil then
		for _, v461_ in pairs(fillUnit.measurementNodes) do
			if setActive ~= nil and setActive then
				v461_.measurementTime = 5000
			end
			if v461_.measurementTime > 0 then
				local v462_ = v461_.measurementTime - dt
				v461_.measurementTime = math.max(v462_, 0)
			end
			local v463_ = v461_.measurementTime / 5000
			local v464_ = math.min(v463_, 1)
			local v465_ = self.lastSpeed * 3600 / 10
			local v466_ = math.min(v465_, 1)
			local v467_ = forcedIntensity or math.max(v464_, v466_)
			if v467_ ~= v461_.intensity then
				setShaderParameter(v461_.node, "fillLevel", fillUnit.fillLevel / fillUnit.capacity, v467_, 0, 0, false)
				setShaderParameter(v461_.node, "prevFillLevel", fillUnit.fillLevel / fillUnit.capacity, v461_.intensity, 0, 0, false)
				v461_.intensity = v467_
			end
		end
	end
end

-- Local values: i, nodeKey, node, defaultX, defaultY, defaultZ, defaultRX, defaultRY, defaultRZ, animCurve, j, animKey, keyTime, x, y, z, rx, ry, rz, sx, sy, sz, minY, maxY, alwaysVisible, fillPlaneMaterial, defaultFillTypeStr, defaultFillTypeIndex
function FillUnit:loadFillPlane(xmlFile, key, fillPlane, fillUnit)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#fillType", "Material is dynamically assigned to the nodes")
	if not xmlFile:hasProperty(key) then
		return false
	end
	fillPlane.nodes = {}
	local v473_ = 0
	while true do
		local v474_ = string.format("%s.node(%d)", key, v473_)
		if not xmlFile:hasProperty(v474_) then
			fillPlane.forcedFillType = nil
			local v475_ = xmlFile:getValue(key .. "#defaultFillType")
			if v475_ == nil then
				fillPlane.defaultFillType = next(fillUnit.supportedFillTypes)
			else
				local v476_ = g_fillTypeManager:getFillTypeIndexByName(v475_)
				if v476_ == nil then
					Logging.xmlWarning(self.xmlFile, "Invalid defaultFillType \'%s\' for \'%s\'!", tostring(v475_), key)
					return false
				end
				fillPlane.defaultFillType = v476_
			end
			return true
		end
		XMLUtil.checkDeprecatedXMLElements(xmlFile, v474_ .. "#index", v474_ .. "#node")
		local v477_ = xmlFile:getValue(v474_ .. "#node", nil, self.components, self.i3dMappings)
		if v477_ ~= nil then
			local v478_, v479_, v480_ = getTranslation(v477_)
			local v481_, v482_, v483_ = getRotation(v477_)
			local v484_ = AnimCurve.new(linearInterpolatorTransRotScale)
			local v485_ = 0
			while true do
				local v486_ = string.format("%s.key(%d)", v474_, v485_)
				if not xmlFile:hasProperty(v486_) then
					break
				end
				local v487_ = xmlFile:getValue(v486_ .. "#time")
				if v487_ == nil then
					break
				end
				local v488_, v489_, v490_ = xmlFile:getValue(v486_ .. "#translation")
				if v489_ == nil then
					v489_ = xmlFile:getValue(v486_ .. "#y")
				end
				local v491_, v492_, v493_ = xmlFile:getValue(v486_ .. "#rotation")
				local v494_, v495_, v496_ = xmlFile:getValue(v486_ .. "#scale")
				v484_:addKeyframe({
					["x"] = v488_ or v478_,
					["y"] = v489_ or v479_,
					["z"] = v490_ or v480_,
					["rx"] = v491_ or v481_,
					["ry"] = v492_ or v482_,
					["rz"] = v493_ or v483_,
					["sx"] = v494_ or 1,
					["sy"] = v495_ or 1,
					["sz"] = v496_ or 1,
					["time"] = v487_
				})
				v485_ = v485_ + 1
			end
			if v485_ == 0 then
				local v497_, v498_ = xmlFile:getValue(v474_ .. "#minMaxY")
				v484_:addKeyframe({
					v478_,
					v497_ or v479_,
					v480_,
					v481_,
					v482_,
					v483_,
					1,
					1,
					1,
					["time"] = 0
				})
				v484_:addKeyframe({
					v478_,
					v498_ or v479_,
					v480_,
					v481_,
					v482_,
					v483_,
					1,
					1,
					1,
					["time"] = 1
				})
			end
			local v499_ = xmlFile:getValue(v474_ .. "#alwaysVisible", false)
			setVisibility(v477_, v499_)
			local v500_ = fillPlane.nodes
			table.insert(v500_, {
				["node"] = v477_,
				["animCurve"] = v484_,
				["alwaysVisible"] = v499_
			})
			local v501_ = g_materialManager:getBaseMaterialByName("fillPlane")
			if v501_ == nil then
				Logging.error("Failed to assign material to fill plane. Base Material \'fillPlane\' not found!")
			else
				setMaterial(v477_, v501_, 0)
				g_fillTypeManager:assignFillTypeTextureArraysFromTerrain(v477_, g_terrainNode, true, true, true)
				setShaderParameter(v477_, "isCustomShape", 1, 0, 0, 0, false)
			end
		end
		v473_ = v473_ + 1
	end
end

-- Local values: spec
function FillUnit:setFillPlaneForcedFillType(fillUnitIndex, forcedFillType)
	local v505_ = self.spec_fillUnit
	if v505_.fillUnits[fillUnitIndex] ~= nil and v505_.fillUnits[fillUnitIndex].fillPlane ~= nil then
		v505_.fillUnits[fillUnitIndex].fillPlane.forcedFillType = forcedFillType
	end
end

-- Local values: fillPlane, t, _, node, x, y, z, rx, ry, rz, sx, sy, sz, textureArrayIndex, _, node
function FillUnit:updateFillUnitFillPlane(fillUnit)
	local v508_ = fillUnit.fillPlane
	if v508_ ~= nil then
		local v509_ = self:getFillUnitFillLevelPercentage(fillUnit.fillUnitIndex)
		for _, v510_ in ipairs(v508_.nodes) do
			local v511_, v512_, v513_, v514_, v515_, v516_, v517_, v518_, v519_ = v510_.animCurve:get(v509_)
			setTranslation(v510_.node, v511_, v512_, v513_)
			setRotation(v510_.node, v514_, v515_, v516_)
			setScale(v510_.node, v517_, v518_, v519_)
			setVisibility(v510_.node, fillUnit.fillLevel > 0 and true or v510_.alwaysVisible)
		end
		if fillUnit.fillType ~= fillUnit.lastFillPlaneType then
			local v520_ = g_fillTypeManager:getTextureArrayIndexByFillTypeIndex(fillUnit.fillType)
			if v520_ ~= nil then
				for _, v521_ in ipairs(v508_.nodes) do
					setShaderParameter(v521_.node, "fillTypeId", v520_ - 1, 0, 0, 0, false)
				end
			end
		end
	end
end

-- Local values: fillTypeMaterials
function FillUnit:loadFillTypeMaterials(xmlFile, key)
	local v_u_525_ = {}
	xmlFile:iterate(key .. ".fillTypeMaterials.material", function(_, p526_)
		-- upvalues: (copy) xmlFile, (copy) self, (copy) v_u_525_
		local v527_ = xmlFile:getValue(p526_ .. "#fillType")
		if v527_ == nil then
			Logging.xmlWarning(xmlFile, "Missing fill type in \'%s\'", p526_)
			return
		else
			local v528_ = g_fillTypeManager:getFillTypeIndexByName(v527_)
			if v528_ == nil then
				Logging.xmlWarning(xmlFile, "Unknown fill type \'%s\' in \'%s\'", v527_, p526_)
				return
			else
				local v529_ = xmlFile:getValue(p526_ .. "#node", nil, self.components, self.i3dMappings)
				local v530_ = xmlFile:getValue(p526_ .. "#refNode", nil, self.components, self.i3dMappings)
				local v531_ = xmlFile:getValue(p526_ .. "#materialSlotName")
				if v529_ == nil or v530_ == nil then
					if v531_ == nil then
						Logging.xmlWarning(xmlFile, "Missing node or ref node or materialSlotName in \'%s\'", p526_)
						return
					else
						local v532_ = MaterialUtil.getMaterialBySlotName(self.rootNode, v531_)
						if v532_ == nil then
							Logging.xmlWarning(xmlFile, "Material for slot name \'%s\' not found in \'%s\'", v531_, p526_)
							return
						else
							local v533_ = xmlFile:getValue(p526_ .. "#diffuse", nil, self.baseDirectory)
							if v533_ == nil then
								Logging.xmlWarning(xmlFile, "Missing diffuse texture for fill type \'%s\' in \'%s\'", v527_, p526_)
								return
							elseif textureFileExists(v533_) then
								local v534_ = v_u_525_
								table.insert(v534_, {
									["fillTypeIndex"] = v528_,
									["materialId"] = v532_,
									["diffuse"] = v533_
								})
							else
								Logging.xmlWarning(xmlFile, "Diffuse texture \'%s\' not found in \'%s\'", v533_, p526_)
							end
						end
					end
				else
					local v535_ = v_u_525_
					table.insert(v535_, {
						["fillTypeIndex"] = v528_,
						["node"] = v529_,
						["refNode"] = v530_
					})
					return
				end
			end
		end
	end)
	return v_u_525_
end

-- Local values: i, fillTypeMaterial, materialId, newMaterialId
function FillUnit:updateFillTypeMaterials(fillTypeMaterials, fillTypeIndex)
	for v539_ = 1, #fillTypeMaterials do
		local v540_ = fillTypeMaterials[v539_]
		if v540_.fillTypeIndex == fillTypeIndex then
			if v540_.refNode == nil then
				if v540_.materialId ~= nil then
					local v541_ = setMaterialDiffuseMapFromFile(v540_.materialId, v540_.diffuse, true, true, false)
					MaterialUtil.replaceMaterialRec(self.rootNode, v540_.materialId, v541_)
					v540_.materialId = v541_
				end
			else
				local v542_ = getMaterial(v540_.refNode, 0)
				setMaterial(v540_.node, v542_, 0)
			end
		end
	end
end

-- Local values: autoAimTarget, startFillLevel, percent, newZ
function FillUnit:updateFillUnitAutoAimTarget(fillUnit)
	local v544_ = fillUnit.autoAimTarget
	if v544_.node ~= nil and (v544_.startZ ~= nil and v544_.endZ ~= nil) then
		local v545_ = fillUnit.capacity * v544_.startPercentage
		local v546_ = (fillUnit.fillLevel - v545_) / (fillUnit.capacity - v545_)
		local v547_ = math.clamp(v546_, 0, 1)
		if v544_.invert then
			v547_ = 1 - v547_
		end
		local v548_ = (v544_.endZ - v544_.startZ) * v547_ + v544_.startZ
		setTranslation(v544_.node, v544_.baseTrans[1], v544_.baseTrans[2], v548_)
	end
end

-- Local values: spec
function FillUnit:addFillUnitTrigger(trigger, fillTypeIndex, fillUnitIndex)
	local v553_ = self.spec_fillUnit
	if #v553_.fillTrigger.triggers == 0 then
		g_currentMission.activatableObjectsSystem:addActivatable(v553_.fillTrigger.activatable)
		v553_.fillTrigger.activatable:setFillType(fillTypeIndex)
		if self.isServer and Platform.gameplay.automaticFilling then
			self:setFillUnitIsFilling(true)
		end
	end
	table.addElement(v553_.fillTrigger.triggers, trigger)
	SpecializationUtil.raiseEvent(self, "onAddedFillUnitTrigger", fillTypeIndex, fillUnitIndex, #v553_.fillTrigger.triggers)
	self:updateFillUnitTriggers()
end

-- Local values: spec
function FillUnit:removeFillUnitTrigger(trigger)
	local v556_ = self.spec_fillUnit
	table.removeElement(v556_.fillTrigger.triggers, trigger)
	if self.isServer and trigger == v556_.fillTrigger.currentTrigger then
		self:setFillUnitIsFilling(false)
	end
	if #v556_.fillTrigger.triggers == 0 then
		g_currentMission.activatableObjectsSystem:removeActivatable(v556_.fillTrigger.activatable)
		if self.isServer and Platform.gameplay.automaticFilling then
			self:setFillUnitIsFilling(false)
		end
	end
	SpecializationUtil.raiseEvent(self, "onRemovedFillUnitTrigger", #v556_.fillTrigger.triggers)
	self:updateFillUnitTriggers()
end

-- Local values: spec, fillTypeIndex
function FillUnit:updateFillUnitTriggers()
	local v558_ = self.spec_fillUnit
	table.sort(v558_.fillTrigger.triggers, function(p559_, p560_)
		-- upvalues: (copy) self
		local v561_ = p559_:getCurrentFillType()
		local v562_ = p560_:getCurrentFillType()
		local v563_ = self:getFirstValidFillUnitToFill(v561_)
		local v564_ = self:getFirstValidFillUnitToFill(v562_)
		if v563_ == nil or v564_ == nil then
			return v563_ ~= nil
		else
			return self:getFillUnitFillLevel(v563_) > self:getFillUnitFillLevel(v564_)
		end
	end)
	if #v558_.fillTrigger.triggers > 0 then
		local v565_ = v558_.fillTrigger.triggers[1]:getCurrentFillType()
		v558_.fillTrigger.activatable:setFillType(v565_)
		if v558_.fillTrigger.selectedTrigger ~= v558_.fillTrigger.triggers[1] then
			SpecializationUtil.raiseEvent(self, "onFillUnitTriggerChanged", v558_.fillTrigger.triggers[1], v565_, self:getFirstValidFillUnitToFill(v565_), #v558_.fillTrigger.triggers)
			v558_.fillTrigger.selectedTrigger = v558_.fillTrigger.triggers[1]
			return
		end
	else
		v558_.fillTrigger.selectedTrigger = nil
	end
end

-- Local values: spec, _, trigger
function FillUnit:setFillUnitIsFilling(isFilling, noEventSend)
	local v569_ = self.spec_fillUnit
	if isFilling ~= v569_.fillTrigger.isFilling then
		if noEventSend == nil or noEventSend == false then
			if g_server == nil then
				g_client:getServerConnection():sendEvent(SetFillUnitIsFillingEvent.new(self, isFilling))
			else
				g_server:broadcastEvent(SetFillUnitIsFillingEvent.new(self, isFilling), nil, nil, self)
			end
		end
		v569_.fillTrigger.isFilling = isFilling
		if isFilling then
			v569_.fillTrigger.currentTrigger = nil
			for _, v570_ in ipairs(v569_.fillTrigger.triggers) do
				if v570_:getIsActivatable(self) then
					v569_.fillTrigger.currentTrigger = v570_
					v570_:setFillSoundIsPlaying(isFilling)
					break
				end
			end
		elseif v569_.fillTrigger.currentTrigger ~= nil then
			v569_.fillTrigger.currentTrigger:setFillSoundIsPlaying(isFilling)
			v569_.fillTrigger.currentTrigger = nil
		end
		if self.isClient then
			self:setFillSoundIsPlaying(isFilling)
		end
		SpecializationUtil.raiseEvent(self, "onFillUnitIsFillingStateChanged", isFilling)
		if not isFilling then
			self:updateFillUnitTriggers()
		end
	end
end

-- Local values: spec
function FillUnit:setFillSoundIsPlaying(isPlaying)
	local v573_ = self.spec_fillUnit
	if isPlaying then
		if not g_soundManager:getIsSamplePlaying(v573_.samples.fill) then
			g_soundManager:playSample(v573_.samples.fill)
			return
		end
	elseif g_soundManager:getIsSamplePlaying(v573_.samples.fill) then
		g_soundManager:stopSample(v573_.samples.fill)
	end
end

function FillUnit:getIsFillUnitActive(fillUnitIndex)
	return true
end

-- Local values: additionalMass, spec, _, fillUnit, desc, mass
function FillUnit:getAdditionalComponentMass(superFunc, component)
	local v577_ = superFunc(self, component)
	local v578_ = self.spec_fillUnit
	for _, v579_ in ipairs(v578_.fillUnits) do
		if v579_.updateMass and (v579_.fillMassNode == component.node and (v579_.fillType ~= nil and v579_.fillType ~= FillType.UNKNOWN)) then
			local v580_ = g_fillTypeManager:getFillTypeByIndex(v579_.fillType)
			v577_ = v577_ + v579_.fillLevel * v580_.massPerLiter
		end
	end
	return v577_
end

-- Local values: spec, i, fillUnit, fillType, fillLevel, capacity, maxReached
function FillUnit:getFillLevelInformation(superFunc, display)
	superFunc(self, display)
	local v584_ = self.spec_fillUnit
	for v585_ = 1, #v584_.fillUnits do
		local v586_ = v584_.fillUnits[v585_]
		if v586_.capacity > 0 and v586_.showOnHud then
			local v587_ = v586_.fillType
			if v587_ == FillType.UNKNOWN and table.size(v586_.supportedFillTypes) == 1 then
				v587_ = next(v586_.supportedFillTypes)
			end
			if v586_.fillTypeToDisplay ~= FillType.UNKNOWN then
				v587_ = v586_.fillTypeToDisplay
			end
			local v588_ = v586_.fillLevel
			if v586_.fillLevelToDisplay ~= nil then
				v588_ = v586_.fillLevelToDisplay
			end
			local v589_ = v586_.capacity
			if v586_.capacityToDisplay ~= nil then
				v589_ = v586_.capacityToDisplay
			end
			if v586_.parentUnitOnHud == nil then
				if v586_.childUnitOnHud ~= nil and v587_ == FillType.UNKNOWN then
					v587_ = v584_.fillUnits[v586_.childUnitOnHud].fillType
				end
			else
				if v587_ == FillType.UNKNOWN then
					v587_ = v584_.fillUnits[v586_.parentUnitOnHud].fillType
				end
				v589_ = 0
			end
			local v590_ = not v586_.ignoreFillLimit and g_currentMission.missionInfo.trailerFillLimit
			if v590_ then
				v590_ = self:getMaxComponentMassReached()
			end
			display:addFillLevel(v587_, v588_, v589_, v588_ > 0 and (v586_.uiPrecision or 0) or 0, v590_, v586_.uiDisplayTypeId, v586_.uiCustomFillTypeName, v586_.uiExtraInfoText)
		end
	end
end

-- Local values: spec, fillUnitIndex, fillUnit
function FillUnit:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	local v595_ = self.spec_fillUnit
	if not v595_.allowFoldingWhileFilled then
		for v596_, v597_ in ipairs(v595_.fillUnits) do
			if self:getFillUnitFillLevel(v596_) > (v597_.allowFoldingThreshold or v595_.allowFoldingThreshold) and (v597_.allowFoldingFillType == nil or v597_.allowFoldingFillType == v597_.fillType) then
				return false, v595_.texts.warningFoldingFilled
			end
		end
	end
	return superFunc(self, direction, onAiTurnOn)
end

-- Local values: spec, _, fillUnit
function FillUnit:getIsReadyForAutomatedTrainTravel(superFunc)
	local v600_ = self.spec_fillUnit
	for _, v601_ in ipairs(v600_.fillUnits) do
		if v601_.blocksAutomatedTrainTravel and v601_.fillLevel > 0 then
			return false
		end
	end
	return superFunc(self)
end

function FillUnit:loadMovingToolFromXML(superFunc, xmlFile, key, entry)
	if not superFunc(self, xmlFile, key, entry) then
		return false
	end
	entry.fillUnitIndex = xmlFile:getValue(key .. "#fillUnitIndex")
	entry.minFillLevel = xmlFile:getValue(key .. "#minFillLevel")
	entry.maxFillLevel = xmlFile:getValue(key .. "#maxFillLevel")
	return true
end

-- Local values: fillLevelPct
function FillUnit:getIsMovingToolActive(superFunc, movingTool)
	if movingTool.fillUnitIndex ~= nil then
		local v610_ = self:getFillUnitFillLevelPercentage(movingTool.fillUnitIndex)
		if movingTool.minFillLevel < v610_ or v610_ < movingTool.maxFillLevel then
			return false
		end
	end
	return superFunc(self, movingTool)
end

-- Local values: fillTrigger
function FillUnit:getDoConsumePtoPower(superFunc)
	local v613_ = self.spec_fillUnit.fillTrigger
	local v614_ = not superFunc(self) and v613_.isFilling
	if v614_ then
		v614_ = v613_.consumePtoPower
	end
	return v614_
end

-- Local values: fillTrigger
function FillUnit:getIsPowerTakeOffActive(superFunc)
	local v617_ = self.spec_fillUnit.fillTrigger
	local v618_ = not superFunc(self) and v617_.isFilling
	if v618_ then
		v618_ = v617_.consumePtoPower
	end
	return v618_
end

-- Local values: spec, _, alarmTrigger
function FillUnit:getCanBeTurnedOn(superFunc)
	local v621_ = self.spec_fillUnit
	for _, v622_ in pairs(v621_.activeAlarmTriggers) do
		if v622_.turnOffInTrigger then
			return false
		end
	end
	return superFunc(self)
end

-- Local values: spec, fillTypeToInfo, _, fillUnit, info, fillType, _, info, formattedNumber, rounded
function FillUnit:showInfo(superFunc, box)
	local v626_ = self.spec_fillUnit
	if v626_.isInfoDirty then
		v626_.fillUnitInfos = {}
		local v627_ = {}
		for _, v628_ in ipairs(v626_.fillUnits) do
			if v628_.showOnInfoHud and v628_.fillLevel > 0 then
				local v629_ = v627_[v628_.fillType]
				if v629_ == nil then
					v629_ = {
						["title"] = g_fillTypeManager:getFillTypeByIndex(v628_.fillType).title,
						["fillLevel"] = 0,
						["unit"] = v628_.unitText,
						["precision"] = 0
					}
					local v630_ = v626_.fillUnitInfos
					table.insert(v630_, v629_)
					v627_[v628_.fillType] = v629_
				end
				v629_.fillLevel = v629_.fillLevel + v628_.fillLevel
				if v629_.precision == 0 and v628_.fillLevel > 0 then
					v629_.precision = v628_.uiPrecision or 0
				end
			end
		end
		v626_.isInfoDirty = false
	end
	for _, v631_ in ipairs(v626_.fillUnitInfos) do
		local v632_
		if v631_.precision > 0 then
			local v633_ = MathUtil.round(v631_.fillLevel, v631_.precision)
			v632_ = string.format("%d%s%0" .. v631_.precision .. "d", math.floor(v633_), g_i18n.decimalSeparator, (v633_ - math.floor(v633_)) * 10 ^ v631_.precision)
		else
			v632_ = string.format("%d", MathUtil.round(v631_.fillLevel))
		end
		local v634_ = v632_ .. " " .. (v631_.unit or g_i18n:getVolumeUnit())
		box:addLine(v631_.title, v634_)
	end
	superFunc(self, box)
end

function FillUnit:loadLevelerNodeFromXML(superFunc, levelerNode, xmlFile, key)
	levelerNode.limitFillUnitIndex = xmlFile:getValue(key .. "#fillUnitIndex", 1)
	levelerNode.minFillLevel = xmlFile:getValue(key .. "#minFillLevel", 0)
	levelerNode.maxFillLevel = xmlFile:getValue(key .. "#maxFillLevel", 1)
	return superFunc(self, levelerNode, xmlFile, key)
end

-- Local values: fillLevelPct
function FillUnit:getIsLevelerPickupNodeActive(superFunc, levelerNode)
	local v643_ = self:getFillUnitFillLevelPercentage(levelerNode.limitFillUnitIndex)
	if v643_ == nil or v643_ >= levelerNode.minFillLevel and levelerNode.maxFillLevel >= v643_ then
		return superFunc(self, levelerNode)
	else
		return false
	end
end

function FillUnit:loadAttacherJointFromXML(superFunc, attacherJoint, xmlFile, baseName, index)
	attacherJoint.limitFillUnitIndex = xmlFile:getValue(baseName .. "#fillUnitIndex")
	if attacherJoint.limitFillUnitIndex ~= nil then
		attacherJoint.fillUnitTopArmOnly = xmlFile:getValue(baseName .. "#fillUnitTopArmOnly", false)
		attacherJoint.minFillLevel = xmlFile:getValue(baseName .. "#minFillLevel", 0)
		attacherJoint.maxFillLevel = xmlFile:getValue(baseName .. "#maxFillLevel", 1)
	end
	return superFunc(self, attacherJoint, xmlFile, baseName, index)
end

-- Local values: fillLevelPct
function FillUnit:getIsAttacherJointCompatible(superFunc, vehicle, attacherJoint, inputAttacherVehicle, inputAttacherJoint)
	if attacherJoint.limitFillUnitIndex ~= nil then
		local v656_ = self:getFillUnitFillLevelPercentage(attacherJoint.limitFillUnitIndex)
		if v656_ ~= nil and (v656_ < attacherJoint.minFillLevel or attacherJoint.maxFillLevel < v656_) and (not attacherJoint.fillUnitTopArmOnly or inputAttacherJoint.topReferenceNode ~= nil) then
			return false, g_i18n:getText("warning_fillUnitAttachNotAllowed")
		end
	end
	return superFunc(self, vehicle, attacherJoint, inputAttacherVehicle, inputAttacherJoint)
end

-- Local values: fillUnitToFillTypes, _, fillUnit
function FillUnit:debugGetSupportedFillTypesPerFillUnit()
	local v658_ = {}
	for _, v659_ in ipairs(self:getFillUnits()) do
		v658_[v659_.fillUnitIndex] = v659_.supportedFillTypes
	end
	return v658_
end

-- Local values: curVehicle, fillUnitIndex2, fillUnit2, _, fillType, attachedImplements, _, implement
function FillUnit.addFillTypeSources(sources, currentVehicle, excludeVehicle, fillTypes)
	if currentVehicle ~= excludeVehicle then
		local v664_ = currentVehicle.spec_fillUnit
		if v664_ ~= nil then
			for v665_, v666_ in pairs(v664_.fillUnits) do
				for _, v667_ in pairs(fillTypes) do
					if v666_.supportedFillTypes[v667_] then
						if sources[v667_] == nil then
							sources[v667_] = {}
						end
						local v668_ = sources[v667_]
						table.insert(v668_, {
							["vehicle"] = currentVehicle,
							["fillUnitIndex"] = v665_
						})
					end
				end
			end
		end
	end
	if currentVehicle.getAttachedImplements ~= nil then
		local v669_ = currentVehicle:getAttachedImplements()
		for _, v670_ in pairs(v669_) do
			if v670_.object ~= nil then
				FillUnit.addFillTypeSources(sources, v670_.object, excludeVehicle, fillTypes)
			end
		end
	end
end

-- Local values: getUnitCapacityAndText, rootName, fillUnitConfigurations, overwrittenCapacity, overwrittenUnitText, conversionFunc
function FillUnit.loadSpecValueCapacity(xmlFile, customEnvironment, baseDir)
	local function v_u_678_(p672_, p673_)
		-- upvalues: (copy) xmlFile
		local v674_ = xmlFile:getValue(p672_ .. "#unitTextOverride")
		if v674_ ~= nil then
			return p673_, v674_
		end
		local v675_ = xmlFile:getValue(p672_ .. "#shopDisplayUnit")
		local v676_ = FillUnit.UNIT[v675_]
		if v675_ ~= nil and v676_ == nil then
			Logging.xmlWarning(xmlFile, "Unit \'%s\' is not defined in fillUnit \'%s\'. Available units: %s. Using LITER as default", v675_, p672_, table.concatKeys(FillUnit.UNIT, " "))
		end
		local v677_ = v676_ or FillUnit.UNIT.LITER
		return v677_.conversionFunc(p673_), v677_.l10n, v677_.conversionFunc
	end
	local v679_ = xmlFile:getRootName()
	local v_u_680_ = {}
	XMLUtil.checkDeprecatedXMLElements(xmlFile, v679_ .. ".storeData.specs.capacity#unit", v679_ .. ".storeData.specs.capacity#unitTextOverride")
	local v681_ = xmlFile:getValue(v679_ .. ".storeData.specs.capacity")
	local v_u_682_, v683_
	if v681_ == nil then
		v_u_682_ = nil
		v683_ = nil
	else
		v681_, v683_, v_u_682_ = v_u_678_(v679_ .. ".storeData.specs.capacity", v681_)
	end
	if v681_ == nil or v683_ == nil then
		xmlFile:iterate(v679_ .. ".fillUnit.fillUnitConfigurations.fillUnitConfiguration", function(_, p684_)
			-- upvalues: (copy) xmlFile, (ref) v_u_682_, (copy) v_u_678_, (copy) v_u_680_
			local v_u_685_ = {
				["isSelectable"] = xmlFile:getValue(p684_ .. "#isSelectable", true),
				["fillUnits"] = {}
			}
			xmlFile:iterate(p684_ .. ".fillUnits.fillUnit", function(p686_, p687_)
				-- upvalues: (ref) xmlFile, (ref) v_u_682_, (ref) v_u_678_, (copy) v_u_685_
				XMLUtil.checkDeprecatedXMLElements(xmlFile, p687_ .. "#unit", p687_ .. "#unitTextOverride")
				if xmlFile:getValue(p687_ .. "#showCapacityInShop") ~= false and xmlFile:getValue(p687_ .. "#showInShop") ~= false then
					local v688_, v689_, v690_ = v_u_678_(p687_, xmlFile:getValue(p687_ .. "#capacity") or 0)
					v_u_682_ = v690_
					local v691_ = v_u_685_.fillUnits
					local v692_ = {
						["capacity"] = v688_,
						["unit"] = v689_,
						["conversionFunc"] = v_u_682_,
						["fillUnitIndex"] = p686_
					}
					table.insert(v691_, v692_)
				end
			end)
			local v693_ = v_u_680_
			table.insert(v693_, v_u_685_)
		end)
		if #v_u_680_ > 0 then
			return v_u_680_
		else
			return nil
		end
	else
		local v694_ = {
			["isSelectable"] = true,
			["fillUnits"] = {
				{
					["capacity"] = v681_,
					["unit"] = v683_,
					["conversionFunc"] = v_u_682_
				}
			}
		}
		table.insert(v_u_680_, v694_)
		return v_u_680_
	end
end

-- Local values: configurationIndex, minCapacity, capacity, unit, fillUnitConfigurations, _, fillUnit, unitCapacity, _, configuration, configCapacity, _, fillUnit
function FillUnit.getSpecValueCapacity(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	local v701_ = 1
	if realItem == nil or (storeItem.configurations == nil or (realItem.configurations.fillUnit == nil or storeItem.configurations.fillUnit == nil)) then
		if configurations ~= nil and (storeItem.configurations ~= nil and (configurations.fillUnit ~= nil and storeItem.configurations.fillUnit ~= nil)) then
			v701_ = configurations.fillUnit
		end
	else
		v701_ = realItem.configurations.fillUnit
	end
	local v702_ = 0
	local v703_ = 0
	local v704_ = ""
	local v705_ = storeItem.specs.capacity
	if v705_ ~= nil then
		if realItem == nil and (configurations == nil or saleItem == nil) then
			v702_ = math.huge
			v703_ = 0
			for _, v706_ in ipairs(v705_) do
				if v706_.isSelectable then
					local v707_ = 0
					for _, v708_ in ipairs(v706_.fillUnits) do
						v707_ = v707_ + v708_.capacity
						v704_ = v708_.unit
					end
					if v707_ ~= 0 then
						v702_ = math.min(v702_, v707_)
						v703_ = math.max(v703_, v707_)
					end
				end
			end
			if v702_ == v703_ then
				v703_ = v702_
			elseif v702_ ~= math.huge and (v703_ ~= 0 and (returnValues == nil or not returnValues)) then
				v703_ = string.format("%s-%s", v702_, v703_)
			end
		elseif v705_[v701_] ~= nil then
			for _, v709_ in ipairs(v705_[v701_].fillUnits) do
				if realItem == nil or (realItem.getFillUnitCapacity == nil or v709_.fillUnitIndex == nil) then
					v703_ = v703_ + v709_.capacity
				else
					local v710_ = realItem:getFillUnitCapacity(v709_.fillUnitIndex)
					if v710_ ~= 0 and v710_ ~= math.huge then
						if v709_.conversionFunc ~= nil then
							v710_ = v709_.conversionFunc(v710_)
						end
						v703_ = v703_ + v710_
					end
				end
				v704_ = v709_.unit
			end
			v702_ = v703_
		end
	end
	if type(v703_) == "number" and (v703_ == 0 and (returnValues == nil or not returnValues)) then
		return nil
	else
		if v704_ ~= "" and v704_:sub(1, 6) == "$l10n_" then
			v704_ = v704_:sub(7)
		end
		if returnValues == nil or not returnValues then
			return string.format(g_i18n:getText("shop_capacityValue"), v703_, g_i18n:getText(v704_ or "unit_literShort"))
		elseif returnRange == true and v703_ ~= v702_ then
			return v702_, v703_, v704_
		else
			return v702_, v704_
		end
	end
end

-- Local values: rootName, maxCapacity
function FillUnit.getCapacityFromXml(xmlFile)
	local v712_ = xmlFile:getRootName()
	local v_u_713_ = 0
	xmlFile:iterate(v712_ .. ".fillUnit.fillUnitConfigurations.fillUnitConfiguration", function(_, p714_)
		-- upvalues: (copy) xmlFile, (ref) v_u_713_
		xmlFile:iterate(p714_ .. ".fillUnits.fillUnit", function(_, p715_)
			-- upvalues: (ref) v_u_713_, (ref) xmlFile
			local v716_ = v_u_713_
			local v717_ = xmlFile:getValue(p715_ .. "#capacity") or 0
			v_u_713_ = math.max(v716_, v717_)
		end)
	end)
	return v_u_713_
end

-- Local values: fillTypeNames, fillTypeCategoryNames, fillTypes, fruitTypeNames, fillTypesByConfiguration, rootName, i, key, j, unitKey, showInShop, capacity, currentFillTypes, currentFillTypeCategories, overwrittenFillTypeNames, fruitTypeCategoryNames, windrowFillTypes, fillTypeConverterName, fillTypeConverter, sourceFillTypeIndex, _
function FillUnit.loadSpecValueFillTypes(xmlFile, customEnvironment, baseDir)
	local v719_ = xmlFile:getRootName()
	XMLUtil.checkDeprecatedXMLElements(xmlFile, v719_ .. ".fillTypes", v719_ .. ".cutter#fruitTypes")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, v719_ .. ".fruitTypes", v719_ .. ".storeData.specs.fillTypes")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, v719_ .. ".fillTypeCategories", v719_ .. ".storeData.specs.fillTypeCategories")
	local v720_ = 0
	local v721_ = nil
	local v722_ = nil
	local v723_ = {}
	while true do
		local v724_ = string.format(v719_ .. ".fillUnit.fillUnitConfigurations.fillUnitConfiguration(%d)", v720_)
		if not xmlFile:hasProperty(v724_) then
			break
		end
		local v725_ = 0
		while true do
			local v726_ = string.format(v724_ .. ".fillUnits.fillUnit(%d)", v725_)
			if not xmlFile:hasProperty(v726_) then
				break
			end
			local v727_ = xmlFile:getValue(v726_ .. "#showInShop")
			local v728_ = xmlFile:getValue(v726_ .. "#capacity")
			if (v727_ == nil or v727_) and (v728_ == nil or v728_ > 0) then
				local v729_ = xmlFile:getValue(v726_ .. "#fillTypes")
				if v729_ ~= nil then
					if v721_ == nil then
						v721_ = v729_
					else
						v721_ = v721_ .. " " .. v729_
					end
				end
				local v730_ = xmlFile:getValue(v726_ .. "#fillTypeCategories")
				if v730_ ~= nil then
					if v722_ == nil then
						v722_ = v730_
					else
						v722_ = v722_ .. " " .. v730_
					end
				end
				v723_[v720_ + 1] = {
					["fillTypeNames"] = v729_,
					["categoryNames"] = v730_
				}
			end
			v725_ = v725_ + 1
		end
		v720_ = v720_ + 1
	end
	local v731_ = xmlFile:getValue(v719_ .. ".storeData.specs.fillTypes")
	if v731_ == nil then
		v731_ = v721_
	else
		v722_ = nil
	end
	local v732_ = xmlFile:getValue(v719_ .. ".storeData.specs.fruitTypes")
	if v732_ == nil then
		v732_ = xmlFile:getValue(v719_ .. ".cutter#fruitTypes")
	end
	local v733_ = xmlFile:getValue(v719_ .. ".storeData.specs.fruitTypeCategories")
	if v733_ == nil then
		v733_ = xmlFile:getValue(v719_ .. ".cutter#fruitTypeCategories")
	end
	local v734_ = nil
	local v735_ = xmlFile:getValue(v719_ .. ".cutter#fillTypeConverter")
	if v735_ ~= nil then
		local v736_ = g_fillTypeManager:getConverterDataByName(v735_)
		if v736_ ~= nil then
			v734_ = {}
			for v737_, _ in pairs(v736_) do
				table.insert(v734_, v737_)
			end
			table.sort(v734_)
		end
	end
	return {
		["categoryNames"] = xmlFile:getValue(v719_ .. ".storeData.specs.fillTypeCategories", v722_),
		["fillTypeNames"] = v731_,
		["fruitTypeNames"] = v732_,
		["fruitTypeCategoryNames"] = v733_,
		["windrowFillTypes"] = v734_,
		["fillTypesByConfiguration"] = v723_
	}
end

-- Local values: fillTypeNames, fillTypeCategoryNames, rootName
function FillUnit.getFillTypeNamesFromXML(xmlFile)
	local v_u_739_ = nil
	local v_u_740_ = nil
	xmlFile:iterate(xmlFile:getRootName() .. ".fillUnit.fillUnitConfigurations.fillUnitConfiguration", function(_, p741_)
		-- upvalues: (copy) xmlFile, (ref) v_u_739_, (ref) v_u_740_
		xmlFile:iterate(p741_ .. ".fillUnits.fillUnit", function(_, p742_)
			-- upvalues: (ref) xmlFile, (ref) v_u_739_, (ref) v_u_740_
			local v743_ = xmlFile:getValue(p742_ .. "#capacity")
			if v743_ == nil or v743_ > 0 then
				local v744_ = xmlFile:getValue(p742_ .. "#fillTypes")
				if v744_ ~= nil then
					if v_u_739_ == nil then
						v_u_739_ = v744_
					else
						v_u_739_ = v_u_739_ .. " " .. v744_
					end
				end
				local v745_ = xmlFile:getValue(p742_ .. "#fillTypeCategories")
				if v745_ ~= nil then
					if v_u_740_ == nil then
						v_u_740_ = v745_
						return
					end
					v_u_740_ = v_u_740_ .. " " .. v745_
				end
			end
		end)
	end)
	return {
		["fillTypeNames"] = v_u_739_,
		["fillTypeCategoryNames"] = v_u_740_
	}
end

-- Local values: specs, configuration, configId, categoryNames, fillTypeNames, fillTypes
function FillUnit.getSpecValueFillTypes(storeItem, realItem, configurations)
	local v748_ = storeItem.specs.fillTypes
	if v748_ ~= nil then
		local v749_
		if configurations == nil then
			v749_ = nil
		else
			local v750_ = configurations.fillUnit
			v749_ = v748_.fillTypesByConfiguration[v750_]
		end
		local v751_ = v748_.categoryNames
		if v749_ ~= nil then
			v751_ = v749_.categoryNames or v751_
		end
		local v752_ = v748_.fillTypeNames
		if v749_ ~= nil then
			v752_ = v749_.fillTypeNames or v752_
		end
		if v751_ ~= nil or v752_ ~= nil then
			local v753_ = {}
			if v751_ ~= nil then
				g_fillTypeManager:getFillTypesByCategoryNames(v751_, nil, v753_)
			end
			if v752_ ~= nil then
				g_fillTypeManager:getFillTypesByNames(v752_, nil, v753_)
			end
			return v753_
		end
		if v748_.fruitTypeNames ~= nil then
			return g_fruitTypeManager:getFillTypeIndicesByFruitTypeNames(v748_.fruitTypeNames, nil)
		end
		if v748_.fruitTypeCategoryNames ~= nil then
			return g_fruitTypeManager:getFillTypeIndicesByFruitTypeCategoryName(v748_.fruitTypeCategoryNames, nil)
		end
		if v748_.windrowFillTypes ~= nil then
			return v748_.windrowFillTypes
		end
	end
	return nil
end

-- Local values: fillUnitMassData
function FillUnit.loadSpecValueFillUnitMassData(xmlFile, customEnvironment, baseDir)
	local v_u_755_ = {}
	xmlFile:iterate("vehicle.motorized.consumerConfigurations.consumerConfiguration(0).consumer", function(_, p756_)
		-- upvalues: (copy) xmlFile, (copy) v_u_755_
		local v757_ = xmlFile:getValue(p756_ .. "#fillUnitIndex", 0)
		if v757_ ~= 0 then
			local v758_ = xmlFile:getValue(p756_ .. "#capacity")
			local v759_ = string.format("vehicle.fillUnit.fillUnitConfigurations.fillUnitConfiguration(0).fillUnits.fillUnit(%d)", v757_ - 1)
			local v760_ = xmlFile:getValue(v759_ .. "#fillTypeCategories")
			local v761_ = xmlFile:getValue(v759_ .. "#fillTypes")
			if v758_ == nil then
				v758_ = xmlFile:getValue(v759_ .. "#capacity", 0)
			end
			if v758_ > 0 then
				local v762_ = v_u_755_
				table.insert(v762_, {
					["fillTypeCategories"] = v760_,
					["fillTypes"] = v761_,
					["capacity"] = v758_
				})
			end
		end
	end)
	xmlFile:iterate("vehicle.fillUnit.fillUnitConfigurations.fillUnitConfiguration(0).fillUnits.fillUnit", function(_, p763_)
		-- upvalues: (copy) xmlFile, (copy) v_u_755_
		local v764_ = xmlFile:getValue(p763_ .. "#startFillLevel", 0)
		if v764_ > 0 then
			local v765_ = v_u_755_
			local v766_ = {
				["fillType"] = xmlFile:getValue(p763_ .. "#startFillType"),
				["capacity"] = v764_
			}
			table.insert(v765_, v766_)
		end
	end)
	return v_u_755_
end

-- Local values: mass, _, massData, fillType, fillTypes, fillTypes, fillTypeDesc
function FillUnit.getSpecValueStartFillUnitMassByMassData(fillUnitMassData)
	local v768_ = 0
	for _, v769_ in pairs(fillUnitMassData) do
		local v770_ = nil
		if v769_.fillTypeCategories == nil then
			if v769_.fillTypes == nil then
				if v769_.fillType ~= nil then
					v770_ = g_fillTypeManager:getFillTypeIndexByName(v769_.fillType)
				end
			else
				v770_ = g_fillTypeManager:getFillTypesByNames(v769_.fillTypes)[1]
			end
		else
			v770_ = g_fillTypeManager:getFillTypesByCategoryNames(v769_.fillTypeCategories)[1]
		end
		if v770_ ~= nil then
			local v771_ = g_fillTypeManager:getFillTypeByIndex(v770_)
			v768_ = v768_ + v769_.capacity * v771_.massPerLiter
		end
	end
	return v768_
end

-- Local values: fillType, fillUnit, found, nextFillType, supportedFillType, _
function FillUnit:actionEventConsoleFillUnitNext(actionName, inputValue, callbackState, isAnalog)
	if self:getIsSelected() then
		local v773_ = self:getFillUnitFillType(1)
		local v774_ = self:getFillUnitByIndex(1)
		local v775_ = false
		local v776_ = nil
		for v777_, _ in pairs(v774_.supportedFillTypes) do
			if v775_ then
				v776_ = v777_
				break
			end
			if v777_ == v773_ then
				v775_ = true
			end
		end
		if v776_ == nil then
			v776_ = next(v774_.supportedFillTypes)
		end
		self:addFillUnitFillLevel(self:getOwnerFarmId(), 1, -math.huge, v773_, ToolType.UNDEFINED, nil)
		self:addFillUnitFillLevel(self:getOwnerFarmId(), 1, 100, v776_, ToolType.UNDEFINED, nil)
	end
end

-- Local values: fillType, fillUnit
function FillUnit:actionEventConsoleFillUnitInc(actionName, inputValue, callbackState, isAnalog)
	if self:getIsSelected() then
		local v779_ = self:getFillUnitFillType(1)
		if v779_ == FillType.UNKNOWN then
			local v780_ = self:getFillUnitByIndex(1)
			v779_ = next(v780_.supportedFillTypes)
		end
		self:addFillUnitFillLevel(self:getOwnerFarmId(), 1, 1000, v779_, ToolType.UNDEFINED, nil)
	end
end

-- Local values: fillType
function FillUnit:actionEventConsoleFillUnitDec(actionName, inputValue, callbackState, isAnalog)
	if self:getIsSelected() then
		local v782_ = self:getFillUnitFillType(1)
		self:addFillUnitFillLevel(self:getOwnerFarmId(), 1, -1000, v782_, ToolType.UNDEFINED, nil)
	end
end

function FillUnit:actionEventUnload(actionName, inputValue, callbackState, isAnalog)
	self:unloadFillUnits()
end

-- Local values: spec, isActive, fillUnitIndex, fillUnit, dischargeNode, dischargeObject, _
function FillUnit:updateUnloadActionDisplay()
	local v785_ = self.spec_fillUnit
	if v785_ ~= nil and v785_.unloading ~= nil then
		local v786_ = false
		for v787_, v788_ in ipairs(self:getFillUnits()) do
			if v788_.canBeUnloaded and (self:getFillUnitFillLevel(v787_) > 0 and self:getFillUnitUnloadPalletFilename(v787_) ~= nil) then
				v786_ = true
				break
			end
		end
		local v789_ = self:getFillUnitHasMountedPalletsToUnload() and true or v786_
		if self.getCurrentDischargeNode ~= nil then
			local v790_ = self:getCurrentDischargeNode()
			if v790_ ~= nil then
				local v791_, _ = self:getDischargeTargetObject(v790_)
				if v791_ ~= nil then
					v789_ = false
				end
			end
		end
		g_inputBinding:setActionEventActive(v785_.unloadActionEventId, v789_)
	end
end
FillActivatable = {}
local v_u_792_ = Class(FillActivatable)

-- Upvalues: FillActivatable_mt
-- Local values: self
function FillActivatable.new(vehicle)
	-- upvalues: (copy) v_u_792_
	local v794_ = v_u_792_
	local v795_ = setmetatable({}, v794_)
	v795_.vehicle = vehicle
	v795_.fillTypeIndex = FillType.UNKNOWN
	v795_.activateText = "<FillActivatable>"
	return v795_
end

-- Local values: fillUnitIndex, enoughSpace, allowsFilling, allowsToolType, spec, _, trigger
function FillActivatable:getIsActivatable()
	if self.vehicle:getIsActiveForInput(true) then
		local v797_ = self.vehicle:getFirstValidFillUnitToFill(self.fillTypeIndex)
		if v797_ ~= nil and (self.vehicle:getFillUnitFillLevel(v797_) < self.vehicle:getFillUnitCapacity(v797_) - 1 and (self.vehicle:getFillUnitAllowsFillType(v797_, self.fillTypeIndex) and self.vehicle:getFillUnitSupportsToolType(v797_, ToolType.TRIGGER))) then
			local v798_ = self.vehicle.spec_fillUnit
			for _, v799_ in ipairs(v798_.fillTrigger.triggers) do
				if v799_:getIsActivatable(self.vehicle) then
					self:updateActivateText(v798_.fillTrigger.isFilling)
					return true
				end
			end
		end
	end
	return false
end

-- Local values: spec
function FillActivatable:run()
	local v801_ = self.vehicle.spec_fillUnit
	self.vehicle:setFillUnitIsFilling(not v801_.fillTrigger.isFilling)
	self:updateActivateText(v801_.fillTrigger.isFilling)
end

function FillActivatable:activate()
	g_currentMission:addDrawable(self)
end

function FillActivatable:deactivate()
	g_currentMission:removeDrawable(self)
end

function FillActivatable:draw()
	if self.fillTypeIndex == FillType.FUEL then
		g_currentMission:showFuelContext(self.vehicle)
	end
end

-- Local values: spec
function FillActivatable:updateActivateText(isFilling)
	local v807_ = self.vehicle.spec_fillUnit
	if isFilling then
		self.activateText = string.format(v807_.texts.stopRefill, self.vehicle.typeDesc)
	else
		self.activateText = string.format(v807_.texts.startRefill, self.vehicle.typeDesc)
	end
end

function FillActivatable:setFillType(fillTypeIndex)
	self.fillTypeIndex = fillTypeIndex
end
