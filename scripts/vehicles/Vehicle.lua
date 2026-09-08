-- Local values: Vehicle_mt
Vehicle = {}
local Vehicle_mt = Class(Vehicle, Object)
Vehicle.defaultWidth = 6
Vehicle.defaultLength = 8
Vehicle.defaultHeight = 4
Vehicle.DEFAULT_SIZE = {
	["width"] = Vehicle.defaultWidth,
	["length"] = Vehicle.defaultLength,
	["height"] = Vehicle.defaultHeight,
	["widthOffset"] = 0,
	["lengthOffset"] = 0,
	["heightOffset"] = 0
}
Vehicle.SPRING_SCALE = 10
Vehicle.NUM_INTERACTION_FLAGS = 0
Vehicle.INTERACTION_FLAG_NONE = 0
Vehicle.NUM_STATE_CHANGES = 0
Vehicle.DAMAGED_SPEEDLIMIT_REDUCTION = 0.3
Vehicle.INPUT_CONTEXT_NAME = "VEHICLE"
Vehicle.xmlSchema = nil
Vehicle.xmlSchemaSounds = nil
Vehicle.xmlSchemaSavegame = nil
Vehicle.DEBUG_NETWORK_READ_WRITE = false
Vehicle.DEBUG_NETWORK_READ_WRITE_UPDATE = false
Vehicle.DEBUG_RANDOM_FAIL_LOADING = false
InitStaticObjectClass(Vehicle, "Vehicle")
source("dataS/scripts/vehicles/VehicleDebug.lua")
source("dataS/scripts/vehicles/VehicleStateRecorder.lua")
source("dataS/scripts/vehicles/VehicleSchemaOverlayData.lua")
source("dataS/scripts/vehicles/VehicleBrokenEvent.lua")
source("dataS/scripts/vehicles/VehiclePropertyState.lua")
source("dataS/scripts/vehicles/VehicleStateChange.lua")
source("dataS/scripts/vehicles/VehicleSetIsReconfiguratingEvent.lua")
source("dataS/scripts/vehicles/VehicleTeleportEvent.lua")

-- Local values: key
function Vehicle.registerInteractionFlag(name)
	local v3_ = "INTERACTION_FLAG_" .. string.upper(name)
	if Vehicle[v3_] == nil then
		Vehicle.NUM_INTERACTION_FLAGS = Vehicle.NUM_INTERACTION_FLAGS + 1
		Vehicle[v3_] = Vehicle.NUM_INTERACTION_FLAGS
	end
	return Vehicle[v3_]
end

function Vehicle.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onPreLoad")
	SpecializationUtil.registerEvent(vehicleType, "onLoad")
	SpecializationUtil.registerEvent(vehicleType, "onPostLoad")
	SpecializationUtil.registerEvent(vehicleType, "onPreInitComponentPlacement")
	SpecializationUtil.registerEvent(vehicleType, "onPreLoadFinished")
	SpecializationUtil.registerEvent(vehicleType, "onLoadFinished")
	SpecializationUtil.registerEvent(vehicleType, "onLoadEnd")
	SpecializationUtil.registerEvent(vehicleType, "onRegistered")
	SpecializationUtil.registerEvent(vehicleType, "onDirtyMaskCleared")
	SpecializationUtil.registerEvent(vehicleType, "onPreDelete")
	SpecializationUtil.registerEvent(vehicleType, "onDelete")
	SpecializationUtil.registerEvent(vehicleType, "onSave")
	SpecializationUtil.registerEvent(vehicleType, "onReadStream")
	SpecializationUtil.registerEvent(vehicleType, "onWriteStream")
	SpecializationUtil.registerEvent(vehicleType, "onReadUpdateStream")
	SpecializationUtil.registerEvent(vehicleType, "onWriteUpdateStream")
	SpecializationUtil.registerEvent(vehicleType, "onReadPositionUpdateStream")
	SpecializationUtil.registerEvent(vehicleType, "onWritePositionUpdateStream")
	SpecializationUtil.registerEvent(vehicleType, "onHandToolTaken")
	SpecializationUtil.registerEvent(vehicleType, "onHandToolPlaced")
	SpecializationUtil.registerEvent(vehicleType, "onPreUpdate")
	SpecializationUtil.registerEvent(vehicleType, "onUpdate")
	SpecializationUtil.registerEvent(vehicleType, "onUpdateInterpolation")
	SpecializationUtil.registerEvent(vehicleType, "onUpdateDebug")
	SpecializationUtil.registerEvent(vehicleType, "onPostUpdate")
	SpecializationUtil.registerEvent(vehicleType, "onUpdateTick")
	SpecializationUtil.registerEvent(vehicleType, "onPostUpdateTick")
	SpecializationUtil.registerEvent(vehicleType, "onUpdateEnd")
	SpecializationUtil.registerEvent(vehicleType, "onDraw")
	SpecializationUtil.registerEvent(vehicleType, "onDrawUIInfo")
	SpecializationUtil.registerEvent(vehicleType, "onActivate")
	SpecializationUtil.registerEvent(vehicleType, "onDeactivate")
	SpecializationUtil.registerEvent(vehicleType, "onStateChange")
	SpecializationUtil.registerEvent(vehicleType, "onPreRegisterActionEvents")
	SpecializationUtil.registerEvent(vehicleType, "onRegisterActionEvents")
	SpecializationUtil.registerEvent(vehicleType, "onRootVehicleChanged")
	SpecializationUtil.registerEvent(vehicleType, "onSelect")
	SpecializationUtil.registerEvent(vehicleType, "onUnselect")
	SpecializationUtil.registerEvent(vehicleType, "onSetBroken")
	SpecializationUtil.registerEvent(vehicleType, "onSaleItemSet")
end

function Vehicle.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "register", Vehicle.register)
	SpecializationUtil.registerFunction(vehicleType, "setOwnerFarmId", Vehicle.setOwnerFarmId)
	SpecializationUtil.registerFunction(vehicleType, "loadSubSharedI3DFile", Vehicle.loadSubSharedI3DFile)
	SpecializationUtil.registerFunction(vehicleType, "drawUIInfo", Vehicle.drawUIInfo)
	SpecializationUtil.registerFunction(vehicleType, "raiseActive", Vehicle.raiseActive)
	SpecializationUtil.registerFunction(vehicleType, "setLoadingState", Vehicle.setLoadingState)
	SpecializationUtil.registerFunction(vehicleType, "setLoadingStep", Vehicle.setLoadingStep)
	SpecializationUtil.registerFunction(vehicleType, "addToPhysics", Vehicle.addToPhysics)
	SpecializationUtil.registerFunction(vehicleType, "removeFromPhysics", Vehicle.removeFromPhysics)
	SpecializationUtil.registerFunction(vehicleType, "setVisibility", Vehicle.setVisibility)
	SpecializationUtil.registerFunction(vehicleType, "setRelativePosition", Vehicle.setRelativePosition)
	SpecializationUtil.registerFunction(vehicleType, "setAbsolutePosition", Vehicle.setAbsolutePosition)
	SpecializationUtil.registerFunction(vehicleType, "getLimitedVehicleYPosition", Vehicle.getLimitedVehicleYPosition)
	SpecializationUtil.registerFunction(vehicleType, "setWorldPosition", Vehicle.setWorldPosition)
	SpecializationUtil.registerFunction(vehicleType, "setWorldPositionQuaternion", Vehicle.setWorldPositionQuaternion)
	SpecializationUtil.registerFunction(vehicleType, "setDefaultComponentPosition", Vehicle.setDefaultComponentPosition)
	SpecializationUtil.registerFunction(vehicleType, "getIsNodeActive", Vehicle.getIsNodeActive)
	SpecializationUtil.registerFunction(vehicleType, "updateVehicleSpeed", Vehicle.updateVehicleSpeed)
	SpecializationUtil.registerFunction(vehicleType, "getUpdatePriority", Vehicle.getUpdatePriority)
	SpecializationUtil.registerFunction(vehicleType, "getPrice", Vehicle.getPrice)
	SpecializationUtil.registerFunction(vehicleType, "getSellPrice", Vehicle.getSellPrice)
	SpecializationUtil.registerFunction(vehicleType, "getDailyUpkeep", Vehicle.getDailyUpkeep)
	SpecializationUtil.registerFunction(vehicleType, "getIsOnField", Vehicle.getIsOnField)
	SpecializationUtil.registerFunction(vehicleType, "getParentComponent", Vehicle.getParentComponent)
	SpecializationUtil.registerFunction(vehicleType, "getLastSpeed", Vehicle.getLastSpeed)
	SpecializationUtil.registerFunction(vehicleType, "getDeactivateOnLeave", Vehicle.getDeactivateOnLeave)
	SpecializationUtil.registerFunction(vehicleType, "getOwnerConnection", Vehicle.getOwnerConnection)
	SpecializationUtil.registerFunction(vehicleType, "getIsVehicleNode", Vehicle.getIsVehicleNode)
	SpecializationUtil.registerFunction(vehicleType, "getIsOperating", Vehicle.getIsOperating)
	SpecializationUtil.registerFunction(vehicleType, "getIsActive", Vehicle.getIsActive)
	SpecializationUtil.registerFunction(vehicleType, "getIsActiveForInput", Vehicle.getIsActiveForInput)
	SpecializationUtil.registerFunction(vehicleType, "getIsActiveForSound", Vehicle.getIsActiveForSound)
	SpecializationUtil.registerFunction(vehicleType, "getIsLowered", Vehicle.getIsLowered)
	SpecializationUtil.registerFunction(vehicleType, "updateWaterInfo", Vehicle.updateWaterInfo)
	SpecializationUtil.registerFunction(vehicleType, "onWaterRaycastCallback", Vehicle.onWaterRaycastCallback)
	SpecializationUtil.registerFunction(vehicleType, "setBroken", Vehicle.setBroken)
	SpecializationUtil.registerFunction(vehicleType, "getVehicleDamage", Vehicle.getVehicleDamage)
	SpecializationUtil.registerFunction(vehicleType, "getRepairPrice", Vehicle.getRepairPrice)
	SpecializationUtil.registerFunction(vehicleType, "getRepaintPrice", Vehicle.getRepaintPrice)
	SpecializationUtil.registerFunction(vehicleType, "setMassDirty", Vehicle.setMassDirty)
	SpecializationUtil.registerFunction(vehicleType, "updateMass", Vehicle.updateMass)
	SpecializationUtil.registerFunction(vehicleType, "getMaxComponentMassReached", Vehicle.getMaxComponentMassReached)
	SpecializationUtil.registerFunction(vehicleType, "getAdditionalComponentMass", Vehicle.getAdditionalComponentMass)
	SpecializationUtil.registerFunction(vehicleType, "getTotalMass", Vehicle.getTotalMass)
	SpecializationUtil.registerFunction(vehicleType, "getComponentMass", Vehicle.getComponentMass)
	SpecializationUtil.registerFunction(vehicleType, "getDefaultMass", Vehicle.getDefaultMass)
	SpecializationUtil.registerFunction(vehicleType, "getOverallCenterOfMass", Vehicle.getOverallCenterOfMass)
	SpecializationUtil.registerFunction(vehicleType, "getVehicleWorldXRot", Vehicle.getVehicleWorldXRot)
	SpecializationUtil.registerFunction(vehicleType, "getVehicleWorldDirection", Vehicle.getVehicleWorldDirection)
	SpecializationUtil.registerFunction(vehicleType, "getFillLevelInformation", Vehicle.getFillLevelInformation)
	SpecializationUtil.registerFunction(vehicleType, "getHasObjectMounted", Vehicle.getHasObjectMounted)
	SpecializationUtil.registerFunction(vehicleType, "activate", Vehicle.activate)
	SpecializationUtil.registerFunction(vehicleType, "deactivate", Vehicle.deactivate)
	SpecializationUtil.registerFunction(vehicleType, "setComponentJointFrame", Vehicle.setComponentJointFrame)
	SpecializationUtil.registerFunction(vehicleType, "setComponentJointRotLimit", Vehicle.setComponentJointRotLimit)
	SpecializationUtil.registerFunction(vehicleType, "setComponentJointTransLimit", Vehicle.setComponentJointTransLimit)
	SpecializationUtil.registerFunction(vehicleType, "loadComponentFromXML", Vehicle.loadComponentFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadComponentJointFromXML", Vehicle.loadComponentJointFromXML)
	SpecializationUtil.registerFunction(vehicleType, "createComponentJoint", Vehicle.createComponentJoint)
	SpecializationUtil.registerFunction(vehicleType, "loadSchemaOverlay", Vehicle.loadSchemaOverlay)
	SpecializationUtil.registerFunction(vehicleType, "getAdditionalSchemaText", Vehicle.getAdditionalSchemaText)
	SpecializationUtil.registerFunction(vehicleType, "getUseTurnedOnSchema", Vehicle.getUseTurnedOnSchema)
	SpecializationUtil.registerFunction(vehicleType, "dayChanged", Vehicle.dayChanged)
	SpecializationUtil.registerFunction(vehicleType, "periodChanged", Vehicle.periodChanged)
	SpecializationUtil.registerFunction(vehicleType, "raiseStateChange", Vehicle.raiseStateChange)
	SpecializationUtil.registerFunction(vehicleType, "doCheckSpeedLimit", Vehicle.doCheckSpeedLimit)
	SpecializationUtil.registerFunction(vehicleType, "interact", Vehicle.interact)
	SpecializationUtil.registerFunction(vehicleType, "getInteractionHelp", Vehicle.getInteractionHelp)
	SpecializationUtil.registerFunction(vehicleType, "getIsInteractive", Vehicle.getIsInteractive)
	SpecializationUtil.registerFunction(vehicleType, "getDistanceToNode", Vehicle.getDistanceToNode)
	SpecializationUtil.registerFunction(vehicleType, "getIsAIActive", Vehicle.getIsAIActive)
	SpecializationUtil.registerFunction(vehicleType, "getIsPowered", Vehicle.getIsPowered)
	SpecializationUtil.registerFunction(vehicleType, "getRequiresPower", Vehicle.getRequiresPower)
	SpecializationUtil.registerFunction(vehicleType, "getIsInShowroom", Vehicle.getIsInShowroom)
	SpecializationUtil.registerFunction(vehicleType, "addVehicleToAIImplementList", Vehicle.addVehicleToAIImplementList)
	SpecializationUtil.registerFunction(vehicleType, "setOperatingTime", Vehicle.setOperatingTime)
	SpecializationUtil.registerFunction(vehicleType, "requestActionEventUpdate", Vehicle.requestActionEventUpdate)
	SpecializationUtil.registerFunction(vehicleType, "removeActionEvents", Vehicle.removeActionEvents)
	SpecializationUtil.registerFunction(vehicleType, "updateActionEvents", Vehicle.updateActionEvents)
	SpecializationUtil.registerFunction(vehicleType, "registerActionEvents", Vehicle.registerActionEvents)
	SpecializationUtil.registerFunction(vehicleType, "addActionEvent", Vehicle.addActionEvent)
	SpecializationUtil.registerFunction(vehicleType, "updateSelectableObjects", Vehicle.updateSelectableObjects)
	SpecializationUtil.registerFunction(vehicleType, "registerSelectableObjects", Vehicle.registerSelectableObjects)
	SpecializationUtil.registerFunction(vehicleType, "addSubselection", Vehicle.addSubselection)
	SpecializationUtil.registerFunction(vehicleType, "getRootVehicle", Vehicle.getRootVehicle)
	SpecializationUtil.registerFunction(vehicleType, "findRootVehicle", Vehicle.findRootVehicle)
	SpecializationUtil.registerFunction(vehicleType, "getChildVehicles", Vehicle.getChildVehicles)
	SpecializationUtil.registerFunction(vehicleType, "addChildVehicles", Vehicle.addChildVehicles)
	SpecializationUtil.registerFunction(vehicleType, "updateVehicleChain", Vehicle.updateVehicleChain)
	SpecializationUtil.registerFunction(vehicleType, "getCanBeSelected", Vehicle.getCanBeSelected)
	SpecializationUtil.registerFunction(vehicleType, "getBlockSelection", Vehicle.getBlockSelection)
	SpecializationUtil.registerFunction(vehicleType, "getCanToggleSelectable", Vehicle.getCanToggleSelectable)
	SpecializationUtil.registerFunction(vehicleType, "unselectVehicle", Vehicle.unselectVehicle)
	SpecializationUtil.registerFunction(vehicleType, "selectVehicle", Vehicle.selectVehicle)
	SpecializationUtil.registerFunction(vehicleType, "getIsSelected", Vehicle.getIsSelected)
	SpecializationUtil.registerFunction(vehicleType, "getSelectedObject", Vehicle.getSelectedObject)
	SpecializationUtil.registerFunction(vehicleType, "getSelectedVehicle", Vehicle.getSelectedVehicle)
	SpecializationUtil.registerFunction(vehicleType, "setSelectedVehicle", Vehicle.setSelectedVehicle)
	SpecializationUtil.registerFunction(vehicleType, "setSelectedObject", Vehicle.setSelectedObject)
	SpecializationUtil.registerFunction(vehicleType, "getIsReadyForAutomatedTrainTravel", Vehicle.getIsReadyForAutomatedTrainTravel)
	SpecializationUtil.registerFunction(vehicleType, "getIsAutomaticShiftingAllowed", Vehicle.getIsAutomaticShiftingAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getSpeedLimit", Vehicle.getSpeedLimit)
	SpecializationUtil.registerFunction(vehicleType, "getRawSpeedLimit", Vehicle.getRawSpeedLimit)
	SpecializationUtil.registerFunction(vehicleType, "getActiveFarm", Vehicle.getActiveFarm)
	SpecializationUtil.registerFunction(vehicleType, "onVehicleWakeUpCallback", Vehicle.onVehicleWakeUpCallback)
	SpecializationUtil.registerFunction(vehicleType, "getCanBeMounted", Vehicle.getCanBeMounted)
	SpecializationUtil.registerFunction(vehicleType, "getName", Vehicle.getName)
	SpecializationUtil.registerFunction(vehicleType, "getFullName", Vehicle.getFullName)
	SpecializationUtil.registerFunction(vehicleType, "getBrand", Vehicle.getBrand)
	SpecializationUtil.registerFunction(vehicleType, "getImageFilename", Vehicle.getImageFilename)
	SpecializationUtil.registerFunction(vehicleType, "getCanBePickedUp", Vehicle.getCanBePickedUp)
	SpecializationUtil.registerFunction(vehicleType, "getCanBeReset", Vehicle.getCanBeReset)
	SpecializationUtil.registerFunction(vehicleType, "getResetPlaces", Vehicle.getResetPlaces)
	SpecializationUtil.registerFunction(vehicleType, "getCanBeSold", Vehicle.getCanBeSold)
	SpecializationUtil.registerFunction(vehicleType, "getCanBeAddedToSales", Vehicle.getCanBeAddedToSales)
	SpecializationUtil.registerFunction(vehicleType, "getReloadXML", Vehicle.getReloadXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsInUse", Vehicle.getIsInUse)
	SpecializationUtil.registerFunction(vehicleType, "getPropertyState", Vehicle.getPropertyState)
	SpecializationUtil.registerFunction(vehicleType, "getAreControlledActionsAllowed", Vehicle.getAreControlledActionsAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getAreControlledActionsAvailable", Vehicle.getAreControlledActionsAvailable)
	SpecializationUtil.registerFunction(vehicleType, "getAreControlledActionsAccessible", Vehicle.getAreControlledActionsAccessible)
	SpecializationUtil.registerFunction(vehicleType, "getControlledActionIcons", Vehicle.getControlledActionIcons)
	SpecializationUtil.registerFunction(vehicleType, "playControlledActions", Vehicle.playControlledActions)
	SpecializationUtil.registerFunction(vehicleType, "getActionControllerDirection", Vehicle.getActionControllerDirection)
	SpecializationUtil.registerFunction(vehicleType, "createMapHotspot", Vehicle.createMapHotspot)
	SpecializationUtil.registerFunction(vehicleType, "getMapHotspot", Vehicle.getMapHotspot)
	SpecializationUtil.registerFunction(vehicleType, "updateMapHotspot", Vehicle.updateMapHotspot)
	SpecializationUtil.registerFunction(vehicleType, "getIsMapHotspotVisible", Vehicle.getIsMapHotspotVisible)
	SpecializationUtil.registerFunction(vehicleType, "getMapHotspotRotation", Vehicle.getMapHotspotRotation)
	SpecializationUtil.registerFunction(vehicleType, "getMapHotspotPosition", Vehicle.getMapHotspotPosition)
	SpecializationUtil.registerFunction(vehicleType, "getShowInVehiclesOverview", Vehicle.getShowInVehiclesOverview)
	SpecializationUtil.registerFunction(vehicleType, "showInfo", Vehicle.showInfo)
	SpecializationUtil.registerFunction(vehicleType, "loadObjectChangeValuesFromXML", Vehicle.loadObjectChangeValuesFromXML)
	SpecializationUtil.registerFunction(vehicleType, "setObjectChangeValues", Vehicle.setObjectChangeValues)
	SpecializationUtil.registerFunction(vehicleType, "getIsSynchronized", Vehicle.getIsSynchronized)
end
function Vehicle.init()
	g_vehicleConfigurationManager:addConfigurationType("baseColor", g_i18n:getText("configuration_baseColor"), nil, VehicleConfigurationItemColor)
	g_vehicleConfigurationManager:addConfigurationType("vehicleType", g_i18n:getText("configuration_design"), nil, VehicleConfigurationItemVehicleType)
	g_vehicleConfigurationManager:addConfigurationType("component", g_i18n:getText("configuration_design"), "base", VehicleConfigurationItem)
	g_vehicleConfigurationManager:addConfigurationType("design", g_i18n:getText("configuration_design"), nil, VehicleConfigurationItem)
	g_vehicleConfigurationManager:addConfigurationType("designColor", g_i18n:getText("configuration_designColor"), nil, VehicleConfigurationItemColor)
	for v6_ = 2, 16 do
		g_vehicleConfigurationManager:addConfigurationType(string.format("design%d", v6_), g_i18n:getText("configuration_design"), nil, VehicleConfigurationItem)
		g_vehicleConfigurationManager:addConfigurationType(string.format("designColor%d", v6_), g_i18n:getText("configuration_designColor"), nil, VehicleConfigurationItemColor)
	end
	g_storeManager:addSpecType("age", "shopListAttributeIconLifeTime", nil, Vehicle.getSpecValueAge, StoreSpecies.VEHICLE)
	g_storeManager:addSpecType("operatingTime", "shopListAttributeIconOperatingHours", nil, Vehicle.getSpecValueOperatingTime, StoreSpecies.VEHICLE)
	g_storeManager:addSpecType("dailyUpkeep", "shopListAttributeIconMaintenanceCosts", nil, Vehicle.getSpecValueDailyUpkeep, StoreSpecies.VEHICLE)
	g_storeManager:addSpecType("workingWidth", "shopListAttributeIconWorkingWidth", Vehicle.loadSpecValueWorkingWidth, Vehicle.getSpecValueWorkingWidth, StoreSpecies.VEHICLE)
	g_storeManager:addSpecType("workingWidthConfig", "shopListAttributeIconWorkingWidth", Vehicle.loadSpecValueWorkingWidthConfig, Vehicle.getSpecValueWorkingWidthConfig, StoreSpecies.VEHICLE)
	g_storeManager:addSpecType("speedLimit", "shopListAttributeIconWorkSpeed", Vehicle.loadSpecValueSpeedLimit, Vehicle.getSpecValueSpeedLimit, StoreSpecies.VEHICLE)
	g_storeManager:addSpecType("weight", "shopListAttributeIconWeight", Vehicle.loadSpecValueWeight, Vehicle.getSpecValueWeight, StoreSpecies.VEHICLE, nil, Vehicle.getSpecConfigValuesWeight)
	g_storeManager:addSpecType("additionalWeight", "shopListAttributeIconAdditionalWeight", Vehicle.loadSpecValueAdditionalWeight, Vehicle.getSpecValueAdditionalWeight, StoreSpecies.VEHICLE)
	g_storeManager:addSpecType("combinations", nil, Vehicle.loadSpecValueCombinations, Vehicle.getSpecValueCombinations, StoreSpecies.VEHICLE)
	g_storeManager:addSpecType("slots", "shopListAttributeIconSlots", nil, Vehicle.getSpecValueSlots, StoreSpecies.VEHICLE)
	Vehicle.xmlSchema = XMLSchema.new("vehicle")
	g_storeManager:addSpeciesXMLSchema(StoreSpecies.VEHICLE, Vehicle.xmlSchema)
	g_vehicleTypeManager:setXMLSchema(Vehicle.xmlSchema)
	Vehicle.xmlSchemaSounds = XMLSchema.new("vehicle_sounds")
	Vehicle.xmlSchemaSounds:setRootNodeName("sounds")
	Vehicle.xmlSchema:addSubSchema(Vehicle.xmlSchemaSounds, "sounds")
	Vehicle.xmlSchemaSavegame = XMLSchema.new("savegame_vehicles")
	Vehicle.registers()
end
function Vehicle.postInit()
	local v_u_7_ = Vehicle.xmlSchema
	local v_u_8_ = Vehicle.xmlSchemaSavegame
	local v9_ = g_vehicleConfigurationManager:getConfigurations()
	for _, v_u_10_ in pairs(v9_) do
		g_asyncTaskManager:addSubtask(function()
			-- upvalues: (copy) v_u_10_, (copy) v_u_7_, (copy) v_u_8_
			if v_u_10_.itemClass.registerXMLPaths ~= nil then
				v_u_10_.itemClass.registerXMLPaths(v_u_7_, v_u_10_.configurationsKey, v_u_10_.configurationKey .. "(?)")
			end
			v_u_7_:register(XMLValueType.FLOAT, v_u_10_.configurationKey .. "(?)#workingWidth", "Work width to display in shop while config is active")
			v_u_7_:register(XMLValueType.L10N_STRING, v_u_10_.configurationKey .. "(?)#typeDesc", "Type description text to display in shop while config is active")
			if v_u_10_.itemClass.registerSavegameXMLPaths ~= nil then
				v_u_10_.itemClass.registerSavegameXMLPaths(v_u_8_, "vehicles.vehicle(?).configuration(?)")
				v_u_10_.itemClass.registerSavegameXMLPaths(v_u_8_, "vehicles.vehicle(?).boughtConfiguration(?)")
			end
		end)
	end
end
function Vehicle.registers()
	local v11_ = Vehicle.xmlSchema
	local v12_ = Vehicle.xmlSchemaSavegame
	v11_:register(XMLValueType.STRING, "vehicle#type", "Vehicle type")
	v11_:registerAutoCompletionDataSource("vehicle#type", "$dataS/vehicleTypes.xml", "vehicleTypes.type#name")
	v11_:register(XMLValueType.STRING, "vehicle.annotation", "Annotation", nil, true)
	StoreManager.registerStoreDataXMLPaths(v11_, "vehicle")
	v11_:register(XMLValueType.FLOAT, "vehicle.storeData.specs.workingWidth", "Working width to display in shop")
	v11_:register(XMLValueType.FLOAT, "vehicle.storeData.specs.workingWidth#minWidth", "Min. working width to display in shop")
	v11_:register(XMLValueType.STRING, "vehicle.storeData.specs.combination(?)#xmlFilename", "Combination to display in shop")
	v11_:registerAutoCompletionDataSource("vehicle.storeData.specs.combination(?)#xmlFilename", "dataS/storeItems.xml", "storeItems.storeItem#xmlFilename")
	v11_:register(XMLValueType.STRING, "vehicle.storeData.specs.combination(?)#filterCategory", "Filter in this category")
	v11_:registerAutoCompletionDataSource("vehicle.storeData.specs.combination(?)#filterCategory", "$dataS/storeCategories.xml", "categories.category#name")
	v11_:register(XMLValueType.STRING, "vehicle.storeData.specs.combination(?)#filterSpec", "Filter for this spec type")
	v11_:register(XMLValueType.FLOAT, "vehicle.storeData.specs.combination(?)#filterSpecMin", "Filter spec type in this range (min.)")
	v11_:register(XMLValueType.FLOAT, "vehicle.storeData.specs.combination(?)#filterSpecMax", "Filter spec type in this range (max.)")
	v11_:register(XMLValueType.BOOL, "vehicle.storeData.specs.weight#ignore", "Hide vehicle weight in shop", false)
	v11_:register(XMLValueType.FLOAT, "vehicle.storeData.specs.weight#minValue", "Min. weight to display in shop")
	v11_:register(XMLValueType.FLOAT, "vehicle.storeData.specs.weight#maxValue", "Max. weight to display in shop")
	v11_:register(XMLValueType.STRING, "vehicle.storeData.specs.weight.config(?)#name", "Name of configuration")
	v11_:register(XMLValueType.INT, "vehicle.storeData.specs.weight.config(?)#index", "Index of selected configuration")
	v11_:register(XMLValueType.FLOAT, "vehicle.storeData.specs.weight.config(?)#value", "Weight value which can be reached with this configuration")
	v11_:register(XMLValueType.STRING, "vehicle.base.filename", "Path to i3d filename", nil)
	v11_:register(XMLValueType.L10N_STRING, "vehicle.base.typeDesc", "Type description", nil)
	v11_:register(XMLValueType.BOOL, "vehicle.base.synchronizePosition", "Vehicle position synchronized", true)
	v11_:register(XMLValueType.BOOL, "vehicle.base.supportsPickUp", "Vehicle can be picked up by hand", false)
	v11_:register(XMLValueType.BOOL, "vehicle.base.canBeReset", "Vehicle can be reset to shop", true)
	v11_:register(XMLValueType.BOOL, "vehicle.base.showInVehicleMenu", "Vehicle shows in vehicle menu", true)
	v11_:register(XMLValueType.BOOL, "vehicle.base.supportsRadio", "Vehicle supported radio", true)
	v11_:register(XMLValueType.BOOL, "vehicle.base.input#allowed", "Vehicle allows key input", true)
	v11_:register(XMLValueType.BOOL, "vehicle.base.selection#allowed", "Vehicle selection is allowed", true)
	v11_:register(XMLValueType.FLOAT, "vehicle.base.tailwaterDepth#warning", "Tailwater depth warning is shown from this water depth", "25% of vehicle height")
	v11_:register(XMLValueType.FLOAT, "vehicle.base.tailwaterDepth#threshold", "Vehicle is broken after this water depth", "75% of vehicle height")
	v11_:register(XMLValueType.STRING, "vehicle.base.mapHotspot#type", "Map hotspot type", nil, nil, table.toList(VehicleHotspot.TYPE))
	v11_:register(XMLValueType.BOOL, "vehicle.base.mapHotspot#available", "Map hotspot is available", true)
	v11_:register(XMLValueType.FLOAT, "vehicle.base.speedLimit#value", "Speed limit")
	v11_:register(XMLValueType.FLOAT, "vehicle.base.size#width", "Occupied width of the vehicle when loaded", nil, true)
	v11_:register(XMLValueType.FLOAT, "vehicle.base.size#length", "Occupied length of the vehicle when loaded", nil, true)
	v11_:register(XMLValueType.FLOAT, "vehicle.base.size#height", "Occupied height of the vehicle when loaded")
	v11_:register(XMLValueType.FLOAT, "vehicle.base.size#widthOffset", "Width offset")
	v11_:register(XMLValueType.FLOAT, "vehicle.base.size#lengthOffset", "Width offset")
	v11_:register(XMLValueType.FLOAT, "vehicle.base.size#heightOffset", "Height offset")
	v11_:register(XMLValueType.ANGLE, "vehicle.base.size#yRotation", "Y Rotation offset in i3d (Needs to be set to the vehicle\'s rotation in the i3d file and is e.g. used to check ai working direction)", 0)
	v11_:register(XMLValueType.NODE_INDEX, "vehicle.base.steeringAxle#node", "Steering axle node used to calculate the steering angle of attachments")
	v11_:register(XMLValueType.STRING, "vehicle.base.sounds#filename", "Path to external sound files")
	v11_:register(XMLValueType.FLOAT, "vehicle.base.sounds#volumeFactor", "This factor will be applied to all sounds of this vehicle")
	I3DUtil.registerI3dMappingXMLPaths(v11_, "vehicle")
	Vehicle.registerComponentXMLPaths(v11_, "vehicle.base.components")
	Vehicle.registerComponentXMLPaths(v11_, "vehicle.base.componentConfigurations.componentConfiguration(?)")
	ObjectChangeUtil.registerObjectChangesXMLPaths(v11_, "vehicle.base")
	v11_:register(XMLValueType.VECTOR_2, "vehicle.base.schemaOverlay#attacherJointPosition", "Position of attacher joint")
	v11_:register(XMLValueType.VECTOR_2, "vehicle.base.schemaOverlay#basePosition", "Position of vehicle")
	v11_:register(XMLValueType.STRING, "vehicle.base.schemaOverlay#name", "Name of schema overlay")
	v11_:registerAutoCompletionDataSource("vehicle.base.schemaOverlay#name", "$dataS/vehicleSchemaOverlays.xml", "vehicleSchemaOverlays.overlay#name")
	v11_:register(XMLValueType.FLOAT, "vehicle.base.schemaOverlay#invisibleBorderRight", "Size of invisible border on the right")
	v11_:register(XMLValueType.FLOAT, "vehicle.base.schemaOverlay#invisibleBorderLeft", "Size of invisible border on the left")
	v11_:register(XMLValueType.STRING, "vehicle.vehicleTypeConfigurations.vehicleTypeConfiguration(?)#vehicleType", "Vehicle type for configuration")
	v11_:register(XMLValueType.BOOL, "vehicle.designConfigurations#preLoad", "Defines if the design configurations are applied before the execution of load or after. Can help if the configurations manipulate the wheel positions for example.", false)
	StoreItemUtil.registerConfigurationSetXMLPaths(v11_, "vehicle")
	v12_:register(XMLValueType.BOOL, "vehicles#loadAnyFarmInSingleplayer", "Load any farm in singleplayer", false)
	v12_:register(XMLValueType.STRING, "vehicles.vehicle(?)#filename", "XML filename")
	v12_:register(XMLValueType.STRING, "vehicles.vehicle(?)#modName", "Vehicle mod name")
	v12_:register(XMLValueType.BOOL, "vehicles.vehicle(?)#isBroken", "If the vehicle is broken", false)
	v12_:register(XMLValueType.BOOL, "vehicles.vehicle(?)#defaultFarmProperty", "Property of default farm", false)
	v12_:register(XMLValueType.INT, "vehicles.vehicle(?)#id", "Vehicle id")
	v12_:register(XMLValueType.STRING, "vehicles.vehicle(?)#tourId", "Tour id")
	v12_:register(XMLValueType.INT, "vehicles.vehicle(?)#farmId", "Farm id")
	v12_:register(XMLValueType.STRING, "vehicles.vehicle(?)#uniqueId", "Vehicle\'s unique id")
	v12_:register(XMLValueType.FLOAT, "vehicles.vehicle(?)#age", "Age in number of months")
	v12_:register(XMLValueType.FLOAT, "vehicles.vehicle(?)#price", "Price")
	VehiclePropertyState.registerXMLPath(v12_, "vehicles.vehicle(?)#propertyState", "Property state", nil, false)
	v12_:register(XMLValueType.FLOAT, "vehicles.vehicle(?)#operatingTime", "Operating time")
	v12_:register(XMLValueType.INT, "vehicles.vehicle(?)#selectedObjectIndex", "Selected object index")
	v12_:register(XMLValueType.INT, "vehicles.vehicle(?)#subSelectedObjectIndex", "Sub selected object index")
	v12_:register(XMLValueType.INT, "vehicles.vehicle(?).component(?)#index", "Component index")
	v12_:register(XMLValueType.VECTOR_TRANS, "vehicles.vehicle(?).component(?)#position", "Component position")
	v12_:register(XMLValueType.VECTOR_ROT, "vehicles.vehicle(?).component(?)#rotation", "Component rotation")
	VehicleActionController.registerXMLPaths(v12_, "vehicles.vehicle(?).actionController")
	v12_:register(XMLValueType.INT, "vehicles.attachments(?)#rootVehicleId", "Id of root vehicle")
end

function Vehicle.registerComponentXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#numComponents", "Number of components loaded from i3d", "number of components the i3d contains")
	schema:register(XMLValueType.FLOAT, basePath .. "#maxMass", "Max. overall mass the vehicle can have", "unlimited")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#directionReferenceNode", "Direction node to calculate the current driving direction and speed")
	schema:register(XMLValueType.INT, basePath .. ".component(?)#index", "Index of the component node in the i3d hierarchy")
	schema:register(XMLValueType.FLOAT, basePath .. ".component(?)#mass", "Mass of component [kg]", "Mass of component in i3d")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".component(?)#centerOfMass", "Center of mass in local space (x y z)", "Center of mass in i3d")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".component(?)#inertiaScale", "Scales the inertia, defining how the mass is distributed around the object (x y z, x = inertia around the local x axis). Inertia quadratically depends on the object radius. E.g. using an inertiaScale of 4 is equal to having a 2 times larger object along the given axis", "1 1 1")
	schema:register(XMLValueType.INT, basePath .. ".component(?)#solverIterationCount", "Solver iterations count")
	schema:register(XMLValueType.BOOL, basePath .. ".component(?)#motorized", "Is motorized component", "set by motorized specialization")
	schema:register(XMLValueType.BOOL, basePath .. ".component(?)#collideWithAttachables", "Collides with attachables", false)
	schema:register(XMLValueType.INT, basePath .. ".joint(?)#component1", "First component of the joint")
	schema:register(XMLValueType.INT, basePath .. ".joint(?)#component2", "Second component of the joint")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".joint(?)#node", "Joint node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".joint(?)#nodeActor1", "Actor node of second component", "Joint node")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#rotLimit", "Rotation limit", "0 0 0")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#transLimit", "Translation limit", "0 0 0")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#rotMinLimit", "Min rotation limit", "inversed rotation limit")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#transMinLimit", "Min translation limit", "inversed translation limit")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#rotLimitSpring", "Rotation spring limit", "0 0 0")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#rotLimitDamping", "Rotation damping limit", "1 1 1")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#rotLimitForceLimit", "Rotation limit force limit (-1 = infinite)", "-1 -1 -1")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#transLimitForceLimit", "Translation limit force limit (-1 = infinite)", "-1 -1 -1")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#transLimitSpring", "Translation spring limit", "0 0 0")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#transLimitDamping", "Translation damping limit", "1 1 1")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".joint(?)#zRotationNode", "Position of joints z rotation")
	schema:register(XMLValueType.BOOL, basePath .. ".joint(?)#breakable", "Joint is breakable", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".joint(?)#breakForce", "Joint force until it breaks", 10)
	schema:register(XMLValueType.FLOAT, basePath .. ".joint(?)#breakTorque", "Joint torque until it breaks", 10)
	schema:register(XMLValueType.BOOL, basePath .. ".joint(?)#enableCollision", "Enable collision between both components", false)
	schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#maxRotDriveForce", "Max rotational drive force", "0 0 0")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#rotDriveVelocity", "Rotational drive velocity")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#rotDriveRotation", "Rotational drive rotation")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#rotDriveSpring", "Rotational drive spring", "0 0 0")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#rotDriveDamping", "Rotational drive damping", "0 0 0")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#transDriveVelocity", "Translational drive velocity")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#transDrivePosition", "Translational drive position")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#transDriveSpring", "Translational drive spring", "0 0 0")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#transDriveDamping", "Translational drive damping", "1 1 1")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#maxTransDriveForce", "Max translational drive force", "0 0 0")
	schema:register(XMLValueType.BOOL, basePath .. ".joint(?)#initComponentPosition", "Defines if the component is translated and rotated during loading based on joint movement", true)
	schema:register(XMLValueType.BOOL, basePath .. ".collisionPair(?)#enabled", "Collision between components enabled")
	schema:register(XMLValueType.INT, basePath .. ".collisionPair(?)#component1", "Index of first component")
	schema:register(XMLValueType.INT, basePath .. ".collisionPair(?)#component2", "Index of second component")
end

-- Upvalues: Vehicle_mt
-- Local values: self
function Vehicle.new(isServer, isClient, customMt)
	-- upvalues: (copy) Vehicle_mt
	local v18_ = Object.new(isServer, isClient, customMt or Vehicle_mt)
	v18_.finishedLoading = false
	v18_.isDeleted = false
	v18_.updateLoopIndex = -1
	v18_.sharedLoadRequestId = nil
	v18_.loadingState = VehicleLoadingState.OK
	v18_.loadingStep = SpecializationLoadStep.CREATED
	v18_.loadingTasks = {}
	v18_.readyForFinishLoading = false
	v18_.uniqueId = nil
	v18_.actionController = VehicleActionController.new(v18_)
	return v18_
end

function Vehicle:setFilename(filename)
	self.configFileName = filename
	self.configFileNameClean = Utils.getFilenameInfo(filename, true)
	local v21_, v22_ = Utils.getModNameAndBaseDirectory(filename)
	self.customEnvironment = v21_
	self.baseDirectory = v22_
end

-- Local values: configName, _
function Vehicle:setConfigurations(configurations, boughtConfigurations, configurationData)
	self.configurations = configurations
	self.boughtConfigurations = boughtConfigurations
	self.configurationData = configurationData or self.configurationData
	if self.configurationData == nil then
		self.configurationData = {}
	end
	self.sortedConfigurationNames = {}
	for v27_, _ in pairs(self.configurations) do
		local v28_ = self.sortedConfigurationNames
		table.insert(v28_, v27_)
	end
	table.sort(self.sortedConfigurationNames, function(p29_, p30_)
		return p29_ < p30_
	end)
end

-- Local values: configItem, configType
function Vehicle:setType(typeDef)
	assertWithCallstack(self.configFileName ~= nil, "Setting vehicle type without setting a filename previously. Call \'setFilename\' first!")
	if self.configurations ~= nil then
		local v33_ = ConfigurationUtil.getConfigItemByConfigId(self.configFileName, "vehicleType", self.configurations.vehicleType)
		if v33_ ~= nil and v33_.vehicleType ~= nil then
			local v34_ = g_vehicleTypeManager:getTypeByName(v33_.vehicleType, self.customEnvironment)
			if v34_ == nil then
				Logging.warning("Unknown vehicle type \'%s\' in configuration for \'%s\'", v33_.vehicleType, self.configFileName)
			else
				typeDef = v34_
			end
		end
	end
	SpecializationUtil.initSpecializationsIntoTypeClass(g_vehicleTypeManager, typeDef, self)
end

function Vehicle:setLoadCallback(loadCallbackFunction, loadCallbackFunctionTarget, loadCallbackFunctionArguments)
	self.loadCallbackFunction = loadCallbackFunction
	self.loadCallbackFunctionTarget = loadCallbackFunctionTarget
	self.loadCallbackFunctionArguments = loadCallbackFunctionArguments
end

function Vehicle:loadCallback()
	if self.loadCallbackFunction ~= nil then
		self.loadCallbackFunction(self.loadCallbackFunctionTarget, self, self.loadingState, self.loadCallbackFunctionArguments)
		self.loadCallbackFunction = nil
		self.loadCallbackFunctionTarget = nil
		self.loadCallbackFunctionArguments = nil
	end
end

-- Local values: storeItem, item, closestSet, closestSetMatches, configName, index, configName, _, defaultConfigId, configName, value, defaultConfigId, isPathValid, invalidDesc
function Vehicle:load(vehicleLoadingData)
	self.vehicleLoadingData = vehicleLoadingData
	self:setLoadingStep(SpecializationLoadStep.PRE_LOAD)
	self.isVehicleSaved = vehicleLoadingData.isSaved
	if self.type == nil then
		Logging.xmlWarning(self.xmlFile, "Unable to find vehicleType")
		self:setLoadingState(VehicleLoadingState.ERROR)
		return self.loadingState
	end
	self.actionEvents = {}
	self.xmlFile = XMLFile.load("vehicleXML", self.configFileName, Vehicle.xmlSchema)
	self.savegame = vehicleLoadingData.savegameData
	self.isAddedToPhysics = false
	local v42_ = g_storeManager:getItemByXMLFilename(self.configFileName)
	if v42_ ~= nil then
		self.brand = g_brandManager:getBrandByIndex(v42_.brandIndex)
		self.lifetime = v42_.lifetime
	end
	self.externalSoundsFilename = self.xmlFile:getValue("vehicle.base.sounds#filename")
	if self.externalSoundsFilename ~= nil then
		self.externalSoundsFilename = Utils.getFilename(self.externalSoundsFilename, self.baseDirectory)
		self.externalSoundsFile = XMLFile.load("TempExternalSounds", self.externalSoundsFilename, Vehicle.xmlSchemaSounds)
	end
	self.soundVolumeFactor = self.xmlFile:getValue("vehicle.base.sounds#volumeFactor")
	SpecializationUtil.copyTypeFunctionsInto(self.type, self)
	local v43_ = g_storeManager:getItemByXMLFilename(self.configFileName)
	if v43_ ~= nil and v43_.configurations ~= nil then
		if v43_.configurationSets ~= nil and (#v43_.configurationSets > 0 and not ConfigurationUtil.getConfigurationsMatchConfigSets(self.configurations, v43_.configurationSets)) then
			local v44_, v45_ = ConfigurationUtil.getClosestConfigurationSet(self.configurations, v43_.configurationSets)
			if v44_ ~= nil then
				for v46_, v47_ in pairs(v44_.configurations) do
					self.configurations[v46_] = v47_
				end
				Logging.xmlInfo(self.xmlFile, "Savegame configurations do not match the configuration sets! Apply closest configuration set \'%s\' with %d matching configurations.", v44_.name, v45_)
			end
		end
		for v48_, _ in pairs(v43_.configurations) do
			local v49_ = StoreItemUtil.getDefaultConfigId(v43_, v48_)
			if self.configurations[v48_] == nil then
				ConfigurationUtil.setConfiguration(self, v48_, v49_)
			end
			ConfigurationUtil.addBoughtConfiguration(g_vehicleConfigurationManager, self, v48_, v49_)
		end
		for v50_, v51_ in pairs(self.configurations) do
			if v43_.configurations[v50_] == nil then
				Logging.xmlWarning(self.xmlFile, "Configurations are not present anymore. Ignoring this configuration (%s)!", v50_)
				self.configurations[v50_] = nil
				self.boughtConfigurations[v50_] = nil
			else
				local v52_ = StoreItemUtil.getDefaultConfigId(v43_, v50_)
				if #v43_.configurations[v50_] < v51_ then
					Logging.xmlWarning(self.xmlFile, "Configuration with index \'%d\' is not present anymore. Using default configuration instead! (%s)", v51_, v50_)
					if self.boughtConfigurations[v50_] ~= nil then
						self.boughtConfigurations[v50_][v51_] = nil
						if next(self.boughtConfigurations[v50_]) == nil then
							self.boughtConfigurations[v50_] = nil
						end
					end
					ConfigurationUtil.setConfiguration(self, v50_, v52_)
				else
					ConfigurationUtil.addBoughtConfiguration(g_vehicleConfigurationManager, self, v50_, v51_)
				end
			end
		end
	end
	SpecializationUtil.createSpecializationEnvironments(self, function(p53_, p54_)
		-- upvalues: (copy) self
		Logging.xmlError(self.xmlFile, "The vehicle specialization \'%s\' could not be added because variable \'%s\' already exists!", p53_, p54_)
		self:setLoadingState(VehicleLoadingState.ERROR)
	end)
	SpecializationUtil.raiseEvent(self, "onPreLoad", self.savegame)
	if self.loadingState ~= VehicleLoadingState.OK then
		Logging.xmlError(self.xmlFile, "Vehicle pre-loading failed!")
		self.xmlFile:delete()
		return false
	end
	ConfigurationUtil.raiseConfigurationItemEvent(self, "onPreLoad")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.filename", "vehicle.base.filename")
	self.i3dFilename = Utils.getFilename(self.xmlFile:getValue("vehicle.base.filename"), self.baseDirectory)
	if self.i3dFilename ~= nil then
		local v55_, v56_ = Utils.getPathIsValid(self.i3dFilename)
		if not v55_ then
			Logging.xmlWarning(self.xmlFile, "Filename contains %s, which are not allowed! (%s)", v56_, "vehicle.base.filename")
		end
	end
	self:setLoadingStep(SpecializationLoadStep.AWAIT_I3D)
	self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.i3dFilename, true, false, self.i3dFileLoaded, self)
	return nil
end

function Vehicle:i3dFileLoaded(i3dNode, failedReason, arguments, i3dLoadingId)
	if i3dNode == 0 then
		self:setLoadingState(VehicleLoadingState.ERROR)
		Logging.xmlError(self.xmlFile, "Vehicle i3d loading failed!")
		self:loadCallback()
	else
		self.i3dNode = i3dNode
		setVisibility(i3dNode, false)
		g_asyncTaskManager:addTask(function()
			-- upvalues: (copy) self
			self:loadFinished()
		end)
	end
end

-- Local values: realNumComponents, componentsKey, numComponents
function Vehicle:loadFinished()
	local v_u_60_ = nil
	local v_u_61_ = nil
	local v_u_62_ = nil
	self:addAsyncTask(function()
		-- upvalues: (copy) self
		self:setLoadingState(VehicleLoadingState.OK)
		self:setLoadingStep(SpecializationLoadStep.LOAD)
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.forcedMapHotspotType", "vehicle.base.mapHotspot#type")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.base.forcedMapHotspotType", "vehicle.base.mapHotspot#type")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.speedLimit#value", "vehicle.base.speedLimit#value")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.steeringAxleNode#index", "vehicle.base.steeringAxle#node")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.size#width", "vehicle.base.size#width")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.size#length", "vehicle.base.size#length")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.size#widthOffset", "vehicle.base.size#widthOffset")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.size#lengthOffset", "vehicle.base.size#lengthOffset")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.typeDesc", "vehicle.base.typeDesc")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.components", "vehicle.base.components")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.components.component", "vehicle.base.components.component")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.base.components.component1", "vehicle.base.components.component")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.base.mapHotspot#hasDirection")
	end, "Vehicle - Deprecated Check")
	self:addAsyncTask(function()
		-- upvalues: (copy) self, (ref) v_u_60_, (ref) v_u_61_, (ref) v_u_62_
		local v63_ = self.savegame
		if v63_ ~= nil then
			self.tourId = nil
			local v64_ = v63_.xmlFile:getValue(v63_.key .. "#tourId")
			if v64_ ~= nil then
				self.tourId = v64_
				g_guidedTourManager:addVehicle(self, self.tourId)
			end
		end
		self.age = 0
		self.propertyState = self.vehicleLoadingData.propertyState
		self:setOwnerFarmId(self.vehicleLoadingData.ownerFarmId, true)
		if v63_ ~= nil then
			local v65_ = v63_.xmlFile:getValue(v63_.key .. "#uniqueId", nil)
			if v65_ ~= nil then
				self:setUniqueId(v65_)
			end
			if not v63_.ignoreFarmId then
				local v66_ = v63_.xmlFile:getValue(v63_.key .. "#farmId", AccessHandler.EVERYONE)
				if g_farmManager.mergedFarms ~= nil and g_farmManager.mergedFarms[v66_] ~= nil then
					v66_ = g_farmManager.mergedFarms[v66_]
				end
				self:setOwnerFarmId(v66_, true)
			end
		end
		self.price = self.vehicleLoadingData.price
		if self.price == 0 or self.price == nil then
			local v67_ = g_storeManager:getItemByXMLFilename(self.configFileName)
			self.price = StoreItemUtil.getDefaultPrice(v67_, self.configurations)
		end
		self.typeDesc = self.xmlFile:getValue("vehicle.base.typeDesc", "TypeDescription", self.customEnvironment, true)
		for v68_, v69_ in pairs(g_vehicleConfigurationManager:getConfigurations()) do
			local v70_ = string.format("%s(%d)", v69_.configurationKey, (self.configurations[v68_] or 1) - 1)
			local v71_ = self.xmlFile:getValue(v70_ .. "#typeDesc", nil, self.customEnvironment, false)
			if v71_ ~= nil then
				self.typeDesc = v71_
			end
		end
		self.synchronizePosition = self.xmlFile:getValue("vehicle.base.synchronizePosition", true)
		self.highPrecisionPositionSynchronization = false
		self.supportsPickUp = self.xmlFile:getValue("vehicle.base.supportsPickUp", false)
		self.canBeReset = self.xmlFile:getValue("vehicle.base.canBeReset", true)
		self.showInVehicleOverview = self.xmlFile:getValue("vehicle.base.showInVehicleMenu", true)
		self.rootNode = getChildAt(self.i3dNode, 0)
		self.serverMass = 0
		self.precalculatedMass = 0
		self.isMassDirty = false
		self.terrainHeightResetCounter = 0
		self.currentUpdateDistance = 0
		self.lastDistanceToCamera = 0
		self.lodDistanceCoeff = getLODDistanceCoeff()
		self.viewDistanceCoeff = getViewDistanceCoeff()
		self.components = {}
		self.vehicleNodes = {}
		v_u_60_ = getNumOfChildren(self.i3dNode)
		local v72_ = { 0, 0, 0 }
		local v73_ = self.configurations.component or 1
		v_u_61_ = string.format("vehicle.base.componentConfigurations.componentConfiguration(%d)", v73_ - 1)
		if not self.xmlFile:hasProperty(v_u_61_) then
			v_u_61_ = "vehicle.base.components"
		end
		v_u_62_ = self.xmlFile:getValue(v_u_61_ .. "#numComponents", v_u_60_)
		self.maxComponentMass = self.xmlFile:getValue(v_u_61_ .. "#maxMass", math.huge) / 1000
		self.rootLevelNodes = {}
		for v74_ = 1, v_u_60_ do
			local v75_ = {
				["node"] = getChildAt(self.i3dNode, v74_ - 1),
				["isInactive"] = true
			}
			if not getVisibility(v75_.node) then
				Logging.xmlDevWarning(self.xmlFile, "Found hidden component \'%s\' in i3d file. Components are not allowed to be hidden!", getName(v75_.node))
			end
			setVisibility(v75_.node, false)
			local v76_ = self.rootLevelNodes
			table.insert(v76_, v75_)
		end
		for v77_, v78_ in self.xmlFile:iterator(v_u_61_ .. ".component") do
			if v_u_62_ < v77_ then
				Logging.xmlWarning(self.xmlFile, "Invalid components count. I3D file has \'%d\' components, but tried to load component no. \'%d\'!", v_u_62_, v77_ + 1)
				break
			end
			local v79_ = self.xmlFile:getValue(v78_ .. "#index", v77_) - 1
			local v80_ = {
				["node"] = getChildAt(self.i3dNode, v79_)
			}
			if self:loadComponentFromXML(v80_, self.xmlFile, v78_, v72_, v77_) then
				local v81_, v82_, v83_ = getWorldTranslation(v80_.node)
				local v84_, v85_, v86_, v87_ = getWorldQuaternion(v80_.node)
				v80_.networkInterpolators = {}
				v80_.networkInterpolators.position = InterpolatorPosition.new(v81_, v82_, v83_)
				v80_.networkInterpolators.quaternion = InterpolatorQuaternion.new(v84_, v85_, v86_, v87_)
				local v88_ = self.components
				table.insert(v88_, v80_)
			end
		end
		for _, v89_ in ipairs(self.components) do
			link(getRootNode(), v89_.node)
		end
	end, "Vehicle - Components Loading")
	self:addAsyncTask(function()
		-- upvalues: (copy) self, (ref) v_u_62_
		for _, v90_ in ipairs(self.rootLevelNodes) do
			for _, v91_ in ipairs(self.components) do
				if v91_.node == v90_.node then
					v90_.isInactive = false
				end
			end
			if v90_.isInactive then
				local v92_, v93_, v94_ = getWorldTranslation(v90_.node)
				local v95_, v96_, v97_ = getWorldRotation(v90_.node)
				link(self.components[1].node, v90_.node)
				setWorldTranslation(v90_.node, v92_, v93_, v94_)
				setWorldRotation(v90_.node, v95_, v96_, v97_)
				setRigidBodyType(v90_.node, RigidBodyType.NONE)
				I3DUtil.iterateRecursively(v90_.node, function(p98_)
					if getIsCompoundChild(p98_) then
						setIsCompoundChild(p98_, false)
					end
				end)
			end
		end
		delete(self.i3dNode)
		self.i3dNode = nil
		self.numComponents = #self.components
		if v_u_62_ ~= self.numComponents then
			Logging.xmlWarning(self.xmlFile, "I3D file offers \'%d\' objects, but \'%d\' components have been loaded!", v_u_62_, self.numComponents)
		end
		if Vehicle.DEBUG_RANDOM_FAIL_LOADING and math.random() > 0.75 then
			self.numComponents = 0
		end
		if self.numComponents == 0 then
			Logging.xmlWarning(self.xmlFile, "No components defined for vehicle!")
			self:setLoadingState(VehicleLoadingState.ERROR)
			self:loadCallback()
		end
	end, "Vehicle - I3D Delete")
	self:addAsyncTask(function()
		-- upvalues: (copy) self, (ref) v_u_60_
		self.defaultMass = 0
		for v99_ = 1, #self.components do
			self.defaultMass = self.defaultMass + self.components[v99_].defaultMass
		end
		self.i3dMappings = {}
		I3DUtil.loadI3DMapping(self.xmlFile, "vehicle", self.rootLevelNodes, self.i3dMappings, v_u_60_)
	end, "Vehicle - I3D mapping")
	self:addAsyncTask(function()
		-- upvalues: (copy) self
		self.steeringAxleNode = self.xmlFile:getValue("vehicle.base.steeringAxle#node", nil, self.components, self.i3dMappings)
		if self.steeringAxleNode == nil then
			self.steeringAxleNode = self.components[1].node
		end
		self:loadSchemaOverlay(self.xmlFile)
	end, "Vehicle - Schema Overlays")
	self:addAsyncTask(function()
		-- upvalues: (copy) self, (ref) v_u_61_
		self.componentJoints = {}
		for v100_, v101_ in self.xmlFile:iterator(v_u_61_ .. ".joint") do
			local v102_ = self.xmlFile:getValue(v101_ .. "#component1")
			local v103_ = self.xmlFile:getValue(v101_ .. "#component2")
			XMLUtil.checkDeprecatedXMLElements(self.xmlFile, v101_ .. "#index", v101_ .. "#node")
			if v102_ == nil or v103_ == nil then
				Logging.xmlWarning(self.xmlFile, "Missing component index in component joint \'%s\'", v101_)
				return
			end
			local v104_ = self.xmlFile:getValue(v101_ .. "#node", nil, self.components, self.i3dMappings)
			if v104_ ~= nil and v104_ ~= 0 then
				local v105_ = {}
				if self:loadComponentJointFromXML(v105_, self.xmlFile, v101_, v100_ - 1, v104_, v102_, v103_) then
					local v106_ = self.componentJoints
					table.insert(v106_, v105_)
					v105_.index = #self.componentJoints
				end
			end
		end
	end, "Vehicle - Component Joints")
	self:addAsyncTask(function()
		-- upvalues: (copy) self, (ref) v_u_61_
		self.collisionPairs = {}
		for _, v107_ in self.xmlFile:iterator(v_u_61_ .. ".collisionPair") do
			local v108_ = self.xmlFile:getValue(v107_ .. "#enabled")
			local v109_ = self.xmlFile:getValue(v107_ .. "#component1")
			local v110_ = self.xmlFile:getValue(v107_ .. "#component2")
			if v109_ ~= nil and (v110_ ~= nil and v108_ ~= nil) then
				local v111_ = self.components[v109_]
				local v112_ = self.components[v110_]
				if v111_ == nil or v112_ == nil then
					Logging.xmlWarning(self.xmlFile, "Failed to load collision pair \'%s\'. Unknown component indices. Indices start with 1.", v107_)
				elseif not v108_ then
					local v113_ = self.collisionPairs
					table.insert(v113_, {
						["component1"] = v111_,
						["component2"] = v112_,
						["enabled"] = v108_
					})
				end
			end
		end
	end, "Vehicle - Collision Pairs")
	self:addAsyncTask(function()
		-- upvalues: (copy) self
		self.supportsRadio = self.xmlFile:getValue("vehicle.base.supportsRadio", true)
		self.allowsInput = self.xmlFile:getValue("vehicle.base.input#allowed", true)
		self.size = StoreItemUtil.getSizeValuesFromXML(self.configFileName, self.xmlFile, "vehicle", 0, self.configurations)
	end, "Vehicle - Size")
	self:addAsyncTask(function()
		-- upvalues: (copy) self, (ref) v_u_61_
		self.yRotationOffset = self.xmlFile:getValue("vehicle.base.size#yRotation", 0)
		self.showTailwaterDepthWarning = false
		self.thresholdTailwaterDepthWarning = self.xmlFile:getValue("vehicle.base.tailwaterDepth#warning", self.size.height * 0.25)
		self.thresholdTailwaterDepth = self.xmlFile:getValue("vehicle.base.tailwaterDepth#threshold", self.size.height * 0.75)
		self.networkTimeInterpolator = InterpolationTime.new(1.2)
		self.movingDirection = 0
		self.rotatedTime = 0
		self.isBroken = false
		self.forceIsActive = false
		self.finishedFirstUpdate = false
		self.lastPosition = nil
		self.lastSpeed = 0
		self.lastSpeedReal = 0
		self.lastSpeedSmoothed = 0
		self.lastSignedSpeed = 0
		self.lastSignedSpeedReal = 0
		self.lastMovedDistance = 0
		self.lastSpeedAcceleration = 0
		self.lastMoveTime = -10000
		self.operatingTime = 0
		self.allowSelection = self.xmlFile:getValue("vehicle.base.selection#allowed", true)
		self.isInWater = false
		self.isInShallowWater = false
		self.isInMediumWater = false
		self.waterY = -200
		self.tailwaterDepth = -200
		self.waterCheckPosition = { 0, 0, 0 }
		self.currentSelection = {
			["object"] = nil,
			["index"] = 0,
			["subIndex"] = 1
		}
		self.selectionObject = {
			["index"] = 0,
			["isSelected"] = false,
			["vehicle"] = self,
			["subSelections"] = {}
		}
		self.childVehicles = { self }
		self.childVehicleHash = ""
		self.rootVehicle = self
		self.registeredActionEvents = {}
		self.actionEventUpdateRequested = false
		self.vehicleDirtyFlag = self:getNextDirtyFlag()
		if g_currentMission ~= nil and g_currentMission.environment ~= nil then
			g_messageCenter:subscribe(MessageType.DAY_CHANGED, self.dayChanged, self)
			g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.periodChanged, self)
		end
		self.mapHotspotAvailable = self.xmlFile:getValue("vehicle.base.mapHotspot#available", true)
		if self.mapHotspotAvailable then
			local v114_ = self.xmlFile:getValue("vehicle.base.mapHotspot#type", "OTHER")
			self.mapHotspotType = VehicleHotspot.getTypeByName(v114_) or VehicleHotspot.TYPE.OTHER
		end
		self.directionReferenceNode = self.xmlFile:getValue(v_u_61_ .. "#directionReferenceNode", nil, self.components, self.i3dMappings)
		local v115_ = math.huge
		for _, v116_ in ipairs(self.specializations) do
			if v116_.getDefaultSpeedLimit ~= nil then
				local v117_ = v116_.getDefaultSpeedLimit(self)
				v115_ = math.min(v117_, v115_)
			end
		end
		self.checkSpeedLimit = v115_ == math.huge
		self.speedLimit = self.xmlFile:getValue("vehicle.base.speedLimit#value", v115_)
	end, "Vehicle - Various Data")
	self:addAsyncTask(function()
		-- upvalues: (copy) self
		local v118_ = {}
		ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, "vehicle.base.objectChanges", v118_, self.components, self)
		ObjectChangeUtil.setObjectChanges(v118_, true)
	end, "Vehicle - Object Change Loading")
	self:addAsyncTask(function()
		-- upvalues: (copy) self
		ConfigurationUtil.raiseConfigurationItemEvent(self, "onLoad")
	end, "Vehicle - Configurations OnLoad")
	self:addAsyncTask(function()
		-- upvalues: (copy) self
		SpecializationUtil.raiseAsyncEvent(self, "onLoad", self.savegame)
	end)
	self:addAsyncTask(function()
		-- upvalues: (copy) self
		if self.loadingState ~= VehicleLoadingState.OK then
			Logging.xmlError(self.xmlFile, "Vehicle loading failed!")
			self:loadCallback()
		end
	end, nil, true)
	self:addAsyncTask(function()
		-- upvalues: (copy) self
		if Platform.gameplay.automaticVehicleControl and self.actionController ~= nil then
			self.actionController:load(self.savegame)
		end
		SpecializationUtil.raiseEvent(self, "onRootVehicleChanged", self)
		if self.isServer then
			for _, v119_ in pairs(self.componentJoints) do
				if v119_.initComponentPosition then
					local v120_ = self.components[v119_.componentIndices[2]].node
					local v121_ = v119_.jointNode
					if self:getParentComponent(v121_) == v120_ then
						v121_ = v119_.jointNodeActor1
					end
					if self:getParentComponent(v121_) ~= v120_ then
						setTranslation(v120_, localToLocal(v120_, v121_, 0, 0, 0))
						setRotation(v120_, localRotationToLocal(v120_, v121_, 0, 0, 0))
						link(v121_, v120_)
					end
				end
			end
		end
	end)
	self:addAsyncTask(function()
		-- upvalues: (copy) self
		ConfigurationUtil.raiseConfigurationItemEvent(self, "onPrePostLoad")
		self:setLoadingStep(SpecializationLoadStep.POST_LOAD)
	end)
	self:addAsyncTask(function()
		-- upvalues: (copy) self
		SpecializationUtil.raiseAsyncEvent(self, "onPostLoad", self.savegame)
	end)
	self:addAsyncTask(function()
		-- upvalues: (copy) self
		ConfigurationUtil.raiseConfigurationItemEvent(self, "onPostLoad")
	end)
	self:addAsyncTask(function()
		-- upvalues: (copy) self
		if self.loadingState ~= VehicleLoadingState.OK then
			Logging.xmlError(self.xmlFile, "Vehicle post-loading failed!")
			self:loadCallback()
		end
	end, nil, true)
	self:addAsyncTask(function()
		-- upvalues: (copy) self
		SpecializationUtil.raiseAsyncEvent(self, "onPreInitComponentPlacement", self.savegame)
	end)
	self:addAsyncTask(function()
		-- upvalues: (copy) self
		if self.loadingState ~= VehicleLoadingState.OK then
			Logging.xmlError(self.xmlFile, "Vehicle pre init component placement failed!")
			self:loadCallback()
		end
	end, nil, true)
	self:addAsyncTask(function()
		-- upvalues: (copy) self
		if self.isServer then
			for _, v122_ in pairs(self.componentJoints) do
				if v122_.initComponentPosition then
					local v123_ = self.components[v122_.componentIndices[2]]
					local v124_ = v122_.jointNode
					if self:getParentComponent(v124_) == v123_.node then
						v124_ = v122_.jointNodeActor1
					end
					if self:getParentComponent(v124_) ~= v123_.node and getParent(v123_.node) == v124_ then
						local v125_, v126_, v127_
						if v122_.jointNodeActor1 == v122_.jointNode then
							v125_ = 0
							v126_ = 0
							v127_ = 0
						else
							local v128_, v129_, v130_ = localToLocal(v122_.jointNode, v123_.node, 0, 0, 0)
							local v131_, v132_, v133_ = localToLocal(v122_.jointNodeActor1, v123_.node, 0, 0, 0)
							v125_ = v128_ - v131_
							v126_ = v129_ - v132_
							v127_ = v130_ - v133_
						end
						local v134_, v135_, v136_ = localToWorld(v123_.node, v125_, v126_, v127_)
						local v137_, v138_, v139_ = localRotationToWorld(v123_.node, 0, 0, 0)
						link(getRootNode(), v123_.node)
						setWorldTranslation(v123_.node, v134_, v135_, v136_)
						setWorldRotation(v123_.node, v137_, v138_, v139_)
						v123_.originalTranslation = { v134_, v135_, v136_ }
						v123_.originalRotation = { v137_, v138_, v139_ }
						v123_.sentTranslation = { v134_, v135_, v136_ }
						v123_.sentRotation = { v137_, v138_, v139_ }
					end
				end
			end
			for _, v140_ in pairs(self.componentJoints) do
				self:setComponentJointFrame(v140_, 0)
				self:setComponentJointFrame(v140_, 1)
			end
		end
		local v141_ = self.savegame
		if v141_ ~= nil then
			self.age = v141_.xmlFile:getValue(v141_.key .. "#age", 0)
			self.price = v141_.xmlFile:getValue(v141_.key .. "#price", self.price)
			self.propertyState = VehiclePropertyState.loadFromXMLFile(v141_.xmlFile, v141_.key .. "#propertyState") or self.propertyState
			self:setOperatingTime(v141_.xmlFile:getValue(v141_.key .. "#operatingTime", self.operatingTime) * 1000, true)
			local v142_ = v141_.xmlFile:getValue(v141_.key .. "#isBroken", self.isBroken)
			if not v141_.resetVehicles and v142_ then
				self:setBroken()
			end
		end
		if not self.vehicleLoadingData:applyPositionData(self) then
			self:setLoadingState(VehicleLoadingState.NO_SPACE)
			self:loadCallback()
		end
	end, "Vehicle - Components Linking")
	self:addAsyncTask(function()
		-- upvalues: (copy) self
		self:updateSelectableObjects()
		self:setSelectedVehicle(self, nil, true)
		if self.rootVehicle == self then
			local v143_ = self.savegame
			if v143_ ~= nil then
				self.loadedSelectedObjectIndex = v143_.xmlFile:getValue(v143_.key .. "#selectedObjectIndex")
				self.loadedSubSelectedObjectIndex = v143_.xmlFile:getValue(v143_.key .. "#subSelectedObjectIndex")
			end
		end
		SpecializationUtil.raiseEvent(self, "onPreLoadFinished", self.savegame)
		self:setVisibility(false)
		if #self.loadingTasks == 0 then
			self:onFinishedLoading()
		else
			self.readyForFinishLoading = true
			self:setLoadingStep(SpecializationLoadStep.AWAIT_SUB_I3D)
		end
	end, "Vehicle - Finalize Loading")
end

function Vehicle:addAsyncTask(func, name, ignoreErrorChecks)
	g_asyncTaskManager:addSubtask(function()
		-- upvalues: (copy) ignoreErrorChecks, (copy) self, (copy) func
		if ignoreErrorChecks == true or self.loadingState == VehicleLoadingState.OK and not self.markedForDeletion then
			func()
		end
	end, name)
end

-- Local values: loadingTask, targetAsyncCallbackFunction, sharedLoadRequestId
function Vehicle:loadSubSharedI3DFile(filename, callOnCreate, addToPhysics, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	local v_u_155_ = self:createLoadingTask(self)
	local v160_ = asyncCallbackFunction ~= nil and function(p156_, p157_, p158_, p159_)
		-- upvalues: (copy) self, (copy) asyncCallbackFunction, (copy) v_u_155_
		if self.isDeleted or self.isDeleting then
			if p157_ ~= 0 then
				delete(p157_)
			end
			asyncCallbackFunction(p156_, 0, p158_, p159_)
			self:finishLoadingTask(v_u_155_)
		else
			asyncCallbackFunction(p156_, p157_, p158_, p159_)
			self:finishLoadingTask(v_u_155_)
		end
	end or asyncCallbackFunction
	return g_i3DManager:loadSharedI3DFileAsync(filename, callOnCreate, addToPhysics, v160_, asyncCallbackObject, asyncCallbackArguments)
end

function Vehicle:onFinishedLoading()
	if self.isServer then
		self:setVisibility(true)
		self:addToPhysics()
	end
	self:setLoadingStep(SpecializationLoadStep.FINISHED)
	SpecializationUtil.raiseEvent(self, "onLoadFinished", self.savegame)
	ConfigurationUtil.raiseConfigurationItemEvent(self, "onLoadFinished")
	if self.isServer then
		self:setLoadingStep(SpecializationLoadStep.SYNCHRONIZED)
	end
	if g_currentMission ~= nil and (self.propertyState ~= VehiclePropertyState.SHOP_CONFIG and self.mapHotspotAvailable) then
		self:createMapHotspot()
	end
	self.finishedLoading = true
	if g_currentMission.vehicleSystem:addVehicle(self) then
		if self.propertyState == VehiclePropertyState.OWNED then
			g_currentMission:addOwnedItem(self)
		elseif self.propertyState == VehiclePropertyState.LEASED then
			g_currentMission:addLeasedItem(self)
		end
		if self.vehicleLoadingData.isRegistered then
			self:register()
		end
		SpecializationUtil.raiseEvent(self, "onLoadEnd", self.savegame)
		self:loadCallback()
		self.savegame = nil
		self.vehicleLoadingData = nil
	else
		Logging.xmlError(self.xmlFile, "Failed to register vehicle!")
		self:setLoadingState(VehicleLoadingState.ERROR)
		self:loadCallback()
	end
end

function Vehicle:createLoadingTask(target)
	return SpecializationUtil.createLoadingTask(self, target)
end

function Vehicle:finishLoadingTask(task)
	SpecializationUtil.finishLoadingTask(self, task)
end

function Vehicle:getIsBeingDeleted()
	return self.markedForDeletion or (self.isDeleting or self.isDeleted)
end

-- Local values: rootVehicle, _, v, _, component, _, component
function Vehicle:delete(immediate)
	if not self.markedForDeletion then
		self:deleteMapHotspot()
		if self.tourId ~= nil then
			g_guidedTourManager:removeVehicle(self.tourId)
		end
		g_messageCenter:unsubscribeAll(self)
		local v169_ = self.rootVehicle
		if v169_ ~= nil and v169_:getIsAIActive() then
			v169_:stopCurrentAIJob(AIMessageErrorVehicleDeleted.new())
		end
		if self.propertyState == VehiclePropertyState.OWNED then
			g_currentMission:removeOwnedItem(self)
		elseif self.propertyState == VehiclePropertyState.LEASED then
			g_currentMission:removeLeasedItem(self)
		end
	end
	self.markedForDeletion = true
	if g_currentMission.isExitingGame or immediate then
		if self.isDeleted then
			Logging.devError("Trying to delete an already deleted vehicle")
			printCallstack()
		else
			VehicleDebug.delete(self)
			self.isDeleting = true
			g_inputBinding:beginActionEventsModification(Vehicle.INPUT_CONTEXT_NAME)
			self:removeActionEvents()
			g_inputBinding:endActionEventsModification()
			SpecializationUtil.raiseEvent(self, "onPreDelete")
			SpecializationUtil.raiseEvent(self, "onDelete")
			if self.isServer and self.componentJoints ~= nil then
				for _, v170_ in pairs(self.componentJoints) do
					if v170_.jointIndex ~= 0 then
						removeJoint(v170_.jointIndex)
					end
				end
				removeWakeUpReport(self.rootNode)
			end
			if self.components ~= nil then
				for _, v171_ in pairs(self.components) do
					unlink(v171_.node)
				end
				for _, v172_ in pairs(self.components) do
					delete(v172_.node)
					g_currentMission:removeNodeObject(v172_.node)
				end
			end
			if self.i3dNode ~= nil then
				delete(self.i3dNode)
				self.i3dNode = nil
			end
			if self.sharedLoadRequestId ~= nil then
				g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
				self.sharedLoadRequestId = nil
			end
			self.xmlFile:delete()
			if self.externalSoundsFile ~= nil then
				self.externalSoundsFile:delete()
			end
			self.rootNode = nil
			self.isDeleting = false
			self.isDeleted = true
			g_currentMission.vehicleSystem:removeVehicle(self)
			Vehicle:superClass().delete(self)
		end
	else
		g_currentMission.vehicleSystem:markVehicleForDeletion(self)
		return
	end
end

-- Local values: vehicle, uniqueId, vehicleSystem, xmlFile, asyncCallbackFunction
function Vehicle:reset(forceDelete, callback, resetPlayer)
	if not self.isResetInProgress then
		if forceDelete then
			self:delete()
		end
		if resetPlayer and (g_localPlayer ~= nil and g_localPlayer:getCurrentVehicle() == self) then
			g_localPlayer:leaveVehicle(nil, true)
			g_localPlayer.mover:teleportToSpawnPoint()
		end
		local v_u_177_ = self:getUniqueId()
		local v_u_178_ = g_currentMission.vehicleSystem
		self.isResetInProgress = true
		local v_u_179_ = self:getReloadXML()
		local function v_u_181_(_, p180_, _)
			-- upvalues: (copy) self, (copy) forceDelete, (copy) v_u_178_, (copy) v_u_177_, (copy) callback, (copy) v_u_179_
			self.isResetInProgress = false
			if #p180_ > 0 then
				g_messageCenter:publish(MessageType.VEHICLE_RESET, self, p180_[1])
				if not forceDelete then
					self:delete()
				end
			elseif not forceDelete then
				v_u_178_.vehicleByUniqueId[v_u_177_] = self
			end
			if callback ~= nil then
				callback(#p180_ > 0)
			end
			v_u_179_:delete()
		end
		g_asyncTaskManager:addTask(function()
			-- upvalues: (copy) v_u_178_, (copy) v_u_177_, (copy) v_u_179_, (copy) v_u_181_
			v_u_178_.vehicleByUniqueId[v_u_177_] = nil
			v_u_178_:loadFromXMLFile(v_u_179_, v_u_181_, nil, {}, true)
		end)
	end
end

function Vehicle:getNeedsSaving()
	return self.isVehicleSaved
end

-- Local values: k, component, compKey, node, x, y, z, xRot, yRot, zRot, id, spec, name
function Vehicle:saveToXMLFile(xmlFile, key, usedModNames)
	xmlFile:setValue(key .. "#uniqueId", self.uniqueId)
	xmlFile:setValue(key .. "#age", self.age)
	xmlFile:setValue(key .. "#price", self.price)
	xmlFile:setValue(key .. "#farmId", self:getOwnerFarmId())
	VehiclePropertyState.saveToXMLFile(xmlFile, key .. "#propertyState", self.propertyState)
	xmlFile:setValue(key .. "#operatingTime", self.operatingTime / 1000)
	if self.tourId ~= nil then
		xmlFile:setValue(key .. "#tourId", self.tourId)
	end
	if self.rootVehicle == self then
		xmlFile:setValue(key .. "#selectedObjectIndex", self.currentSelection.index)
		if self.currentSelection.subIndex ~= nil then
			xmlFile:setValue(key .. "#subSelectedObjectIndex", self.currentSelection.subIndex)
		end
	end
	if self.isBroken then
		xmlFile:setValue(key .. "#isBroken", self.isBroken)
	end
	for v187_, v188_ in ipairs(self.components) do
		local v189_ = string.format("%s.component(%d)", key, v187_ - 1)
		local v190_ = v188_.node
		local v191_, v192_, v193_ = getWorldTranslation(v190_)
		local v194_, v195_, v196_ = getWorldRotation(v190_)
		xmlFile:setValue(v189_ .. "#index", v187_)
		xmlFile:setValue(v189_ .. "#position", v191_, v192_, v193_)
		xmlFile:setValue(v189_ .. "#rotation", v194_, v195_, v196_)
	end
	ConfigurationUtil.saveConfigurationsToXMLFile(self.configFileName, xmlFile, key .. ".configuration", self.configurations, self.boughtConfigurations, self.configurationData)
	for v197_, v198_ in pairs(self.specializations) do
		local v199_ = self.specializationNames[v197_]
		if v198_.saveToXMLFile ~= nil then
			v198_.saveToXMLFile(self, xmlFile, key .. "." .. v199_, usedModNames)
		end
	end
	if Platform.gameplay.automaticVehicleControl and self.actionController ~= nil then
		self.actionController:saveToXMLFile(xmlFile, key .. ".actionController", usedModNames)
	end
end

-- Local values: isTabbable, name, categoryName, storeItem, x, y, z, id, spec
function Vehicle:saveStatsToXMLFile(xmlFile, key)
	local v203_ = self.getIsTabbable == nil and true or self:getIsTabbable()
	if self.isDeleted or not (self.isVehicleSaved and v203_) then
		return false
	end
	local v204_ = "Unknown"
	local v205_ = g_storeManager:getItemByXMLFilename(self.configFileName)
	local v206_
	if v205_ == nil then
		v206_ = "unknown"
	else
		if v205_.name ~= nil then
			local v207_ = v205_.name
			v204_ = tostring(v207_)
		end
		v206_ = v205_.categoryName
	end
	setXMLString(xmlFile, key .. "#name", HTMLUtil.encodeToHTML(v204_))
	setXMLString(xmlFile, key .. "#category", HTMLUtil.encodeToHTML(v206_))
	local v208_ = setXMLString
	local v209_ = key .. "#type"
	local v210_ = HTMLUtil.encodeToHTML
	local v211_ = self.typeName
	v208_(xmlFile, v209_, v210_((tostring(v211_))))
	if self.components[1] ~= nil and self.components[1].node ~= 0 then
		local v212_, v213_, v214_ = getWorldTranslation(self.components[1].node)
		setXMLFloat(xmlFile, key .. "#x", v212_)
		setXMLFloat(xmlFile, key .. "#y", v213_)
		setXMLFloat(xmlFile, key .. "#z", v214_)
	end
	for _, v215_ in pairs(self.specializations) do
		if v215_.saveStatsToXMLFile ~= nil then
			v215_.saveStatsToXMLFile(self, xmlFile, key)
		end
	end
	return true
end

-- Local values: filename, configurations, boughtConfigurations, configurationData, data, asyncCallbackFunction
function Vehicle:readStream(streamId, connection, objectId)
	Vehicle:superClass().readStream(self, streamId, connection, objectId)
	local v220_ = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
	local v221_, v222_, v223_ = ConfigurationUtil.readConfigurationsFromStream(g_vehicleConfigurationManager, streamId, connection, v220_)
	self.propertyState = VehiclePropertyState.readStream(streamId)
	if self.loadingStep == SpecializationLoadStep.CREATED then
		local v224_ = VehicleLoadingData.new()
		v224_:setFilename(v220_)
		v224_:setPropertyState(self.propertyState)
		v224_:setOwnerFarmId(self.ownerFarmId)
		v224_:setConfigurations(v221_)
		v224_:setBoughtConfigurations(v222_)
		v224_:setConfigurationData(v223_)
		v224_:loadVehicleOnClient(self, function(_, p225_, p226_)
			if p226_ == VehicleLoadingState.OK then
				g_client:onObjectFinishedAsyncLoading(p225_)
			else
				Logging.error("Failed to load vehicle on client")
				printCallstack()
			end
		end, nil)
	else
		Logging.error("Try to intialize loading of a vehicle that is already loading!")
	end
end

-- Local values: paramsXZ, paramsY, i, component, x, y, z, x_rot, y_rot, z_rot, qx, qy, qz, qw, _, spec, className, startBits
function Vehicle:postReadStream(streamId, connection)
	self:removeFromPhysics()
	local v230_ = self.highPrecisionPositionSynchronization and (self.vehicleXZPosHighPrecisionCompressionParams or g_currentMission.vehicleXZPosHighPrecisionCompressionParams) or (self.vehicleXZPosCompressionParams or g_currentMission.vehicleXZPosCompressionParams)
	local v231_ = self.highPrecisionPositionSynchronization and (self.vehicleYPosHighPrecisionCompressionParams or g_currentMission.vehicleYPosHighPrecisionCompressionParams) or (self.vehicleYPosCompressionParams or g_currentMission.vehicleYPosCompressionParams)
	for v232_ = 1, #self.components do
		local v233_ = self.components[v232_]
		local v234_ = NetworkUtil.readCompressedWorldPosition(streamId, v230_)
		local v235_ = NetworkUtil.readCompressedWorldPosition(streamId, v231_)
		local v236_ = NetworkUtil.readCompressedWorldPosition(streamId, v230_)
		local v237_ = NetworkUtil.readCompressedAngle(streamId)
		local v238_ = NetworkUtil.readCompressedAngle(streamId)
		local v239_ = NetworkUtil.readCompressedAngle(streamId)
		local v240_, v241_, v242_, v243_ = mathEulerToQuaternion(v237_, v238_, v239_)
		self:setWorldPositionQuaternion(v234_, v235_, v236_, v240_, v241_, v242_, v243_, v232_, true)
		v233_.networkInterpolators.position:setPosition(v234_, v235_, v236_)
		v233_.networkInterpolators.quaternion:setQuaternion(v240_, v241_, v242_, v243_)
	end
	self.networkTimeInterpolator:reset()
	self:setVisibility(true)
	self:addToPhysics()
	self.serverMass = streamReadFloat32(streamId)
	self.age = streamReadUInt16(streamId)
	self:setOperatingTime(streamReadFloat32(streamId), true)
	self.price = streamReadInt32(streamId)
	self.isBroken = streamReadBool(streamId)
	if Vehicle.DEBUG_NETWORK_READ_WRITE then
		print("-------------------------------------------------------------")
		print(self.configFileName)
		for _, v244_ in ipairs(self.eventListeners.onReadStream) do
			local v245_ = ClassUtil.getClassName(v244_)
			local v246_ = streamGetReadOffset(streamId)
			v244_.onReadStream(self, streamId, connection)
			print("  " .. tostring(v245_) .. " read " .. streamGetReadOffset(streamId) - v246_ .. " bits")
		end
	else
		SpecializationUtil.raiseEvent(self, "onReadStream", streamId, connection)
	end
	self:setLoadingStep(SpecializationLoadStep.SYNCHRONIZED)
end

function Vehicle:writeStream(streamId, connection)
	Vehicle:superClass().writeStream(self, streamId, connection)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.configFileName))
	ConfigurationUtil.writeConfigurationsToStream(g_vehicleConfigurationManager, streamId, connection, self.configFileName, self.configurations, self.boughtConfigurations, self.configurationData)
	VehiclePropertyState.writeStream(streamId, self.propertyState)
end

-- Local values: paramsXZ, paramsY, i, component, x, y, z, x_rot, y_rot, z_rot, _, spec, className, startBits
function Vehicle:postWriteStream(streamId, connection)
	local v253_ = self.highPrecisionPositionSynchronization and (self.vehicleXZPosHighPrecisionCompressionParams or g_currentMission.vehicleXZPosHighPrecisionCompressionParams) or (self.vehicleXZPosCompressionParams or g_currentMission.vehicleXZPosCompressionParams)
	local v254_ = self.highPrecisionPositionSynchronization and (self.vehicleYPosHighPrecisionCompressionParams or g_currentMission.vehicleYPosHighPrecisionCompressionParams) or (self.vehicleYPosCompressionParams or g_currentMission.vehicleYPosCompressionParams)
	for v255_ = 1, #self.components do
		local v256_ = self.components[v255_]
		local v257_, v258_, v259_ = getWorldTranslation(v256_.node)
		local v260_, v261_, v262_ = getWorldRotation(v256_.node)
		NetworkUtil.writeCompressedWorldPosition(streamId, v257_, v253_)
		NetworkUtil.writeCompressedWorldPosition(streamId, v258_, v254_)
		NetworkUtil.writeCompressedWorldPosition(streamId, v259_, v253_)
		NetworkUtil.writeCompressedAngle(streamId, v260_)
		NetworkUtil.writeCompressedAngle(streamId, v261_)
		NetworkUtil.writeCompressedAngle(streamId, v262_)
	end
	streamWriteFloat32(streamId, self.serverMass)
	streamWriteUInt16(streamId, self.age)
	streamWriteFloat32(streamId, self.operatingTime)
	streamWriteInt32(streamId, self.price)
	streamWriteBool(streamId, self.isBroken)
	if Vehicle.DEBUG_NETWORK_READ_WRITE then
		print("-------------------------------------------------------------")
		print(self.configFileName)
		for _, v263_ in ipairs(self.eventListeners.onWriteStream) do
			local v264_ = ClassUtil.getClassName(v263_)
			local v265_ = streamGetWriteOffset(streamId)
			v263_.onWriteStream(self, streamId, connection)
			print("  " .. tostring(v264_) .. " Wrote " .. streamGetWriteOffset(streamId) - v265_ .. " bits")
		end
	else
		SpecializationUtil.raiseEvent(self, "onWriteStream", streamId, connection)
	end
end

-- Local values: hasUpdate, paramsXZ, paramsY, i, component, x, y, z, x_rot, y_rot, z_rot, qx, qy, qz, qw, _, spec, className, startBits
function Vehicle:readUpdateStream(streamId, timestamp, connection)
	if connection.isServer and streamReadBool(streamId) then
		self.networkTimeInterpolator:startNewPhaseNetwork()
		local v270_ = self.highPrecisionPositionSynchronization and (self.vehicleXZPosHighPrecisionCompressionParams or g_currentMission.vehicleXZPosHighPrecisionCompressionParams) or (self.vehicleXZPosCompressionParams or g_currentMission.vehicleXZPosCompressionParams)
		local v271_ = self.highPrecisionPositionSynchronization and (self.vehicleYPosHighPrecisionCompressionParams or g_currentMission.vehicleYPosHighPrecisionCompressionParams) or (self.vehicleYPosCompressionParams or g_currentMission.vehicleYPosCompressionParams)
		for v272_ = 1, #self.components do
			local v273_ = self.components[v272_]
			if not v273_.isStatic then
				local v274_ = NetworkUtil.readCompressedWorldPosition(streamId, v270_)
				local v275_ = NetworkUtil.readCompressedWorldPosition(streamId, v271_)
				local v276_ = NetworkUtil.readCompressedWorldPosition(streamId, v270_)
				local v277_ = NetworkUtil.readCompressedAngle(streamId)
				local v278_ = NetworkUtil.readCompressedAngle(streamId)
				local v279_ = NetworkUtil.readCompressedAngle(streamId)
				local v280_, v281_, v282_, v283_ = mathEulerToQuaternion(v277_, v278_, v279_)
				v273_.networkInterpolators.position:setTargetPosition(v274_, v275_, v276_)
				v273_.networkInterpolators.quaternion:setTargetQuaternion(v280_, v281_, v282_, v283_)
			end
		end
		SpecializationUtil.raiseEvent(self, "onReadPositionUpdateStream", streamId, connection)
	end
	if Vehicle.DEBUG_NETWORK_READ_WRITE_UPDATE then
		print("-------------------------------------------------------------")
		print(self.configFileName)
		for _, v284_ in ipairs(self.eventListeners.onReadUpdateStream) do
			local v285_ = ClassUtil.getClassName(v284_)
			local v286_ = streamGetReadOffset(streamId)
			v284_.onReadUpdateStream(self, streamId, timestamp, connection)
			print("  " .. tostring(v285_) .. " read " .. streamGetReadOffset(streamId) - v286_ .. " bits")
		end
	else
		SpecializationUtil.raiseEvent(self, "onReadUpdateStream", streamId, timestamp, connection)
	end
end

-- Local values: paramsXZ, paramsY, i, component, x, y, z, x_rot, y_rot, z_rot, _, spec, className, startBits
function Vehicle:writeUpdateStream(streamId, connection, dirtyMask)
	if not connection.isServer then
		local v291_ = streamWriteBool
		local v292_ = self.vehicleDirtyFlag
		if v291_(streamId, bit32.band(dirtyMask, v292_) ~= 0) then
			local v293_ = self.highPrecisionPositionSynchronization and (self.vehicleXZPosHighPrecisionCompressionParams or g_currentMission.vehicleXZPosHighPrecisionCompressionParams) or (self.vehicleXZPosCompressionParams or g_currentMission.vehicleXZPosCompressionParams)
			local v294_ = self.highPrecisionPositionSynchronization and (self.vehicleYPosHighPrecisionCompressionParams or g_currentMission.vehicleYPosHighPrecisionCompressionParams) or (self.vehicleYPosCompressionParams or g_currentMission.vehicleYPosCompressionParams)
			for v295_ = 1, #self.components do
				local v296_ = self.components[v295_]
				if not v296_.isStatic then
					local v297_, v298_, v299_ = getWorldTranslation(v296_.node)
					local v300_, v301_, v302_ = getWorldRotation(v296_.node)
					NetworkUtil.writeCompressedWorldPosition(streamId, v297_, v293_)
					NetworkUtil.writeCompressedWorldPosition(streamId, v298_, v294_)
					NetworkUtil.writeCompressedWorldPosition(streamId, v299_, v293_)
					NetworkUtil.writeCompressedAngle(streamId, v300_)
					NetworkUtil.writeCompressedAngle(streamId, v301_)
					NetworkUtil.writeCompressedAngle(streamId, v302_)
				end
			end
			SpecializationUtil.raiseEvent(self, "onWritePositionUpdateStream", streamId, connection, dirtyMask)
		end
	end
	if Vehicle.DEBUG_NETWORK_READ_WRITE_UPDATE then
		print("-------------------------------------------------------------")
		print(self.configFileName)
		for _, v303_ in ipairs(self.eventListeners.onWriteUpdateStream) do
			local v304_ = ClassUtil.getClassName(v303_)
			local v305_ = streamGetWriteOffset(streamId)
			v303_.onWriteUpdateStream(self, streamId, connection, dirtyMask)
			print("  " .. tostring(v304_) .. " Wrote " .. streamGetWriteOffset(streamId) - v305_ .. " bits")
		end
	else
		SpecializationUtil.raiseEvent(self, "onWriteUpdateStream", streamId, connection, dirtyMask)
	end
end

-- Local values: speedReal, movedDistance, movingDirection, signedSpeedReal, interpPos, dx, dy, dz, x, y, z, dx, dy, dz, vx, vy, vz
function Vehicle:updateVehicleSpeed(dt)
	if self.finishedFirstUpdate and not self.components[1].isStatic then
		local v308_ = 0
		local v309_ = 0
		local v310_ = 0
		local v311_ = 0
		if self.isServer and not self.components[1].isKinematic then
			if self.components[1].isDynamic then
				local v312_, v313_, v314_ = getLocalLinearVelocity(self.components[1].node)
				if self.directionReferenceNode ~= nil then
					v312_, v313_, v314_ = localDirectionToLocal(self.components[1].node, self.directionReferenceNode, v312_, v313_, v314_)
				end
				v308_ = MathUtil.vector3Length(v312_, v313_, v314_) * 0.001
				v309_ = v308_ * g_physicsDt
				v311_ = v308_ * (v314_ >= 0 and 1 or -1)
				if v314_ > 0.001 then
					v310_ = 1
				elseif v314_ < -0.001 then
					v310_ = -1
				end
			end
		elseif self.isServer or not self.synchronizePosition then
			local v315_, v316_, v317_ = getWorldTranslation(self.components[1].node)
			if self.lastPosition == nil then
				self.lastPosition = { v315_, v316_, v317_ }
			end
			local v318_, v319_, v320_ = worldDirectionToLocal(self.directionReferenceNode or self.components[1].node, v315_ - self.lastPosition[1], v316_ - self.lastPosition[2], v317_ - self.lastPosition[3])
			local v321_ = self.lastPosition
			local v322_ = self.lastPosition
			local v323_ = self.lastPosition
			v321_[1] = v315_
			v322_[2] = v316_
			v323_[3] = v317_
			v310_ = v320_ > 0.001 and 1 or (v320_ < -0.001 and -1 or v310_)
			v309_ = MathUtil.vector3Length(v318_, v319_, v320_)
			v308_ = v309_ / dt
			v311_ = v308_ * (v320_ >= 0 and 1 or -1)
		else
			local v324_ = self.components[1].networkInterpolators.position
			local v325_, v326_, v327_
			if self.networkTimeInterpolator:isInterpolating() then
				v325_, v326_, v327_ = worldDirectionToLocal(self.directionReferenceNode or self.components[1].node, v324_.targetPositionX - v324_.lastPositionX, v324_.targetPositionY - v324_.lastPositionY, v324_.targetPositionZ - v324_.lastPositionZ)
			else
				v327_ = 0
				v325_ = 0
				v326_ = 0
			end
			v310_ = v327_ > 0.001 and 1 or (v327_ < -0.001 and -1 or v310_)
			v308_ = MathUtil.vector3Length(v325_, v326_, v327_) / self.networkTimeInterpolator.interpolationDuration
			v311_ = v308_ * (v327_ >= 0 and 1 or -1)
			v309_ = v308_ * dt
		end
		if self.isServer then
			if g_physicsDtNonInterpolated > 0 then
				self.lastSpeedAcceleration = (v308_ * v310_ - self.lastSpeedReal * self.movingDirection) / g_physicsDtNonInterpolated
			end
		else
			self.lastSpeedAcceleration = (v308_ * v310_ - self.lastSpeedReal * self.movingDirection) / dt
		end
		if self.isServer then
			self.lastSpeed = self.lastSpeed * 0.5 + v308_ * 0.5
			self.lastSignedSpeed = self.lastSignedSpeed * 0.5 + v311_ * 0.5
		else
			self.lastSpeed = self.lastSpeed * 0.9 + v308_ * 0.1
			self.lastSignedSpeed = self.lastSignedSpeed * 0.9 + v311_ * 0.1
		end
		self.lastSpeedSmoothed = self.lastSpeedSmoothed * 0.9 + v308_ * 0.1
		self.lastSpeedReal = v308_
		self.lastSignedSpeedReal = v311_
		self.movingDirection = v310_
		self.lastMovedDistance = v309_
	end
end

-- Local values: mapBoundingSize, wx, wy, wz, resetThreshold, isActiveForInput, isActiveForInputIgnoreSelection, isSelected, lastDistanceToCamera, rootNode, cameraNode, interpolationAlpha, i, component, posX, posY, posZ, quatX, quatY, quatZ, quatW
function Vehicle:update(dt)
	if self.isServer then
		local v330_ = g_currentMission.terrainSize
		local v331_, v332_, v333_ = getTranslation(self.rootNode)
		if MathUtil.isNan(v331_) then
			if not self.isDeleting or self.isDeleted then
				Logging.error("Invalid vehicle translation detected, resetting to shop (%s)", self.configFileName)
				self:setRelativePosition(0, 0, 0, 0)
				self:reset(true, nil, true)
			end
			return
		end
		if v331_ < -v330_ or (v330_ < v331_ or (v333_ < -v330_ or v330_ < v333_)) then
			if not self.isDeleting or self.isDeleted then
				Logging.error("Vehicle outside of the world detected, resetting to shop (%s)", self.configFileName)
				self:reset(true, nil, true)
			end
			return
		end
		if v332_ < -v330_ then
			if not self.isDeleting or self.isDeleted then
				local v334_ = v330_ * 0.5 - 25
				if v331_ < -v334_ or (v334_ < v331_ or (v333_ < -v334_ or v334_ < v333_)) then
					Logging.error("Vehicle below the world detected, resetting to shop (%s)", self.configFileName)
					self:reset(true, nil, true)
					return
				end
				if self.terrainHeightResetCounter > 5 then
					self.terrainHeightResetCounter = 0
					Logging.error("Vehicle below the world detected multiple times, resetting to shop (%s)", self.configFileName)
					self:reset(true, nil, true)
					return
				end
				Logging.error("Vehicle below the world detected, resetting to terrain level again (%s)", self.configFileName)
				self.rootVehicle:resetPositionToTerrainHeight()
				self.terrainHeightResetCounter = self.terrainHeightResetCounter + 1
			end
			return
		end
	end
	self.isActive = self:getIsActive()
	local v335_ = self:getIsActiveForInput()
	local v336_ = self:getIsActiveForInput(true)
	local v337_ = self:getIsSelected()
	local v338_ = self.rootNode
	local v339_
	if v338_ == nil then
		v339_ = 999999
	else
		local v340_ = g_cameraManager:getActiveCamera()
		v339_ = calcDistanceFrom(v338_, v340_)
	end
	self.lastDistanceToCamera = v339_
	self.currentUpdateDistance = v339_ / self.viewDistanceCoeff
	self.isActiveForInputIgnoreSelectionIgnoreAI = self:getIsActiveForInput(true, true)
	self.isActiveForLocalSound = self.isActiveForInputIgnoreSelectionIgnoreAI
	self.updateLoopIndex = g_updateLoopIndex
	SpecializationUtil.raiseEvent(self, "onPreUpdate", dt, v335_, v336_, v337_)
	if not self.isServer and self.synchronizePosition then
		self.networkTimeInterpolator:update(dt)
		local v341_ = self.networkTimeInterpolator:getAlpha()
		for v342_, v343_ in pairs(self.components) do
			if not v343_.isStatic then
				local v344_, v345_, v346_ = v343_.networkInterpolators.position:getInterpolatedValues(v341_)
				local v347_, v348_, v349_, v350_ = v343_.networkInterpolators.quaternion:getInterpolatedValues(v341_)
				self:setWorldPositionQuaternion(v344_, v345_, v346_, v347_, v348_, v349_, v350_, v342_, false)
			end
		end
		if self.networkTimeInterpolator:isInterpolating() then
			self:raiseActive()
		end
	end
	SpecializationUtil.raiseEvent(self, "onUpdateInterpolation", dt, v335_, v336_, v337_)
	self:updateVehicleSpeed(dt)
	if self.actionEventUpdateRequested then
		self:updateActionEvents()
	end
	if Platform.gameplay.automaticVehicleControl then
		if self.actionController ~= nil then
			self.actionController:update(dt)
			self.actionController:updateForAI(dt)
		end
	elseif self.actionController ~= nil then
		self.actionController:updateForAI(dt)
	end
	SpecializationUtil.raiseEvent(self, "onUpdate", dt, v335_, v336_, v337_)
	if Vehicle.debuggingActive then
		SpecializationUtil.raiseEvent(self, "onUpdateDebug", dt, v335_, v336_, v337_)
	end
	SpecializationUtil.raiseEvent(self, "onPostUpdate", dt, v335_, v336_, v337_)
	if self.finishedFirstUpdate and self.isMassDirty then
		self.isMassDirty = false
		self:updateMass()
	end
	self.finishedFirstUpdate = true
	if self.isServer and not getIsSleeping(self.rootNode) then
		self:raiseActive()
	end
	VehicleDebug.updateDebug(self, dt)
	self:updateMapHotspot()
end

-- Local values: wx, _, _, isActiveForInput, isActiveForInputIgnoreSelection, isSelected, hasOwner, i, component, x, y, z, x_rot, y_rot, z_rot, sentTranslation, sentRotation, rootAttacherVehicle
function Vehicle:updateTick(dt)
	if self.isServer then
		local v353_, _, _ = getWorldTranslation(self.rootNode)
		if MathUtil.isNan(v353_) then
			return
		end
	end
	local v354_ = self:getIsActiveForInput()
	local v355_ = self:getIsActiveForInput(true)
	local v356_ = self:getIsSelected()
	if self.isActive and self.needWaterInfo then
		self:updateWaterInfo()
	end
	self.isOnField = self:getIsOnField()
	if self.isServer and self.synchronizePosition then
		local v357_ = self:getOwnerConnection() ~= nil
		for v358_ = 1, #self.components do
			local v359_ = self.components[v358_]
			if not v359_.isStatic then
				local v360_, v361_, v362_ = getWorldTranslation(v359_.node)
				local v363_, v364_, v365_ = getWorldRotation(v359_.node)
				local v366_ = v359_.sentTranslation
				local v367_ = v359_.sentRotation
				if v357_ then
					::l17::
					self:raiseDirtyFlags(self.vehicleDirtyFlag)
					v366_[1] = v360_
					v366_[2] = v361_
					v366_[3] = v362_
					v367_[1] = v363_
					v367_[2] = v364_
					v367_[3] = v365_
					self.lastMoveTime = g_currentMission.time
				else
					local v368_ = v360_ - v366_[1]
					if math.abs(v368_) > 0.005 then
						goto l17
					end
					local v369_ = v361_ - v366_[2]
					if math.abs(v369_) > 0.005 then
						goto l17
					end
					local v370_ = v362_ - v366_[3]
					if math.abs(v370_) > 0.005 then
						goto l17
					end
					local v371_ = v363_ - v367_[1]
					if math.abs(v371_) > 0.1 then
						goto l17
					end
					local v372_ = v364_ - v367_[2]
					if math.abs(v372_) > 0.1 then
						goto l17
					end
					local v373_ = v365_ - v367_[3]
					if math.abs(v373_) > 0.1 then
						goto l17
					end
				end
			end
		end
	end
	self.showTailwaterDepthWarning = false
	if not self.isBroken and (not g_gui:getIsGuiVisible() and self.tailwaterDepth > self.thresholdTailwaterDepthWarning) then
		self.showTailwaterDepthWarning = true
		if self.tailwaterDepth > self.thresholdTailwaterDepth then
			self:setBroken()
		end
	end
	local v374_ = self.rootVehicle
	if v374_ ~= nil and v374_ ~= self then
		v374_.showTailwaterDepthWarning = v374_.showTailwaterDepthWarning or self.showTailwaterDepthWarning
	end
	if self:getIsOperating() then
		self:setOperatingTime(self.operatingTime + dt)
	end
	SpecializationUtil.raiseEvent(self, "onUpdateTick", dt, v354_, v355_, v356_)
	SpecializationUtil.raiseEvent(self, "onPostUpdateTick", dt, v354_, v355_, v356_)
end

-- Local values: isActiveForInput, isActiveForInputIgnoreSelection, isSelected
function Vehicle:updateEnd(dt)
	local v377_ = self:getIsActiveForInput()
	local v378_ = self:getIsActiveForInput(true)
	local v379_ = self:getIsSelected()
	self.currentUpdateDistance = 0
	SpecializationUtil.raiseEvent(self, "onUpdateEnd", dt, v377_, v378_, v379_)
end

-- Local values: rootVehicle, selectedVehicle, isActiveForInput, isActiveForInputIgnoreSelection
function Vehicle:draw(subDraw)
	if self:getIsSynchronized() then
		local v382_ = self.rootVehicle
		local v383_ = self:getSelectedVehicle()
		if not subDraw then
			if self ~= v382_ and v383_ ~= v382_ then
				v382_:draw(true)
			end
			if v383_ ~= nil and (self ~= v383_ and v383_ ~= v382_) then
				v383_:draw(true)
			end
		end
		if v383_ == self or v382_ == self then
			local v384_ = self:getIsActiveForInput()
			local v385_ = self:getIsActiveForInput(true)
			SpecializationUtil.raiseEvent(self, "onDraw", v384_, v385_, true)
		end
		VehicleDebug.drawDebug(self)
		if self.showTailwaterDepthWarning then
			g_currentMission:showBlinkingWarning(g_i18n:getText("warning_dontDriveIntoWater"), 2000)
		end
	end
end

-- Local values: dist, x, y, z
function Vehicle:drawUIInfo()
	if self:getIsSynchronized() then
		SpecializationUtil.raiseEvent(self, "onDrawUIInfo")
		if g_showVehicleDistance then
			local v387_ = calcDistanceFrom(self.rootNode, g_cameraManager:getActiveCamera())
			if v387_ <= 350 then
				local v388_, v389_, v390_ = getWorldTranslation(self.rootNode)
				Utils.renderTextAtWorldPosition(v388_, v389_ + 1, v390_, string.format("%.0f", v387_), getCorrectTextSize(0.02), 0)
			end
		end
	end
end

function Vehicle:setLoadingState(loadingState)
	if VehicleLoadingState.getName(loadingState) == nil then
		printCallstack()
		Logging.error("Invalid loading state \'%s\'!", loadingState)
	else
		self.loadingState = loadingState
	end
end

function Vehicle:setLoadingStep(loadingStep)
	SpecializationUtil.setLoadingStep(self, loadingStep)
end

-- Local values: lastMotorizedNode, _, component, _, jointDesc, _, collisionPair
function Vehicle:addToPhysics()
	if self.isAddedToPhysics then
		return false
	end
	local v396_ = nil
	for _, v397_ in pairs(self.components) do
		addToPhysics(v397_.node)
		if v397_.motorized then
			if v396_ ~= nil and self.isServer then
				addVehicleLink(v396_, v397_.node)
			end
			v396_ = v397_.node
		end
	end
	self.isAddedToPhysics = true
	if self.isServer then
		for _, v398_ in pairs(self.componentJoints) do
			self:createComponentJoint(self.components[v398_.componentIndices[1]], self.components[v398_.componentIndices[2]], v398_)
		end
		addWakeUpReport(self.rootNode, "onVehicleWakeUpCallback", self)
	end
	for _, v399_ in pairs(self.collisionPairs) do
		setPairCollision(v399_.component1.node, v399_.component2.node, v399_.enabled)
	end
	self:setMassDirty()
	return true
end

-- Local values: _, component, _, jointDesc
function Vehicle:removeFromPhysics()
	for _, v401_ in pairs(self.components) do
		removeFromPhysics(v401_.node)
	end
	if self.isServer then
		for _, v402_ in pairs(self.componentJoints) do
			v402_.jointIndex = 0
		end
		removeWakeUpReport(self.rootNode)
	end
	self.isAddedToPhysics = false
	return true
end

-- Local values: _, component
function Vehicle:setVisibility(state)
	for _, v405_ in pairs(self.components) do
		setVisibility(v405_.node, state)
	end
end

-- Local values: terrainHeight
function Vehicle:setRelativePosition(positionX, offsetY, positionZ, yRot)
	self:setAbsolutePosition(positionX, getTerrainHeightAtWorldPos(g_terrainNode, positionX, 300, positionZ) + offsetY, positionZ, 0, yRot, 0)
end

-- Local values: tempRootNode, i, component, x, y, z, rx, ry, rz
function Vehicle:setAbsolutePosition(positionX, positionY, positionZ, xRot, yRot, zRot, componentPositions)
	local v419_ = createTransformGroup("tempRootNode")
	setTranslation(v419_, positionX, positionY, positionZ)
	setRotation(v419_, xRot, yRot, zRot)
	for v420_, v421_ in pairs(self.components) do
		local v422_ = localToWorld
		local v423_ = v421_.originalTranslation
		local v424_, v425_, v426_ = v422_(v419_, unpack(v423_))
		local v427_ = localRotationToWorld
		local v428_ = v421_.originalRotation
		local v429_, v430_, v431_ = v427_(v419_, unpack(v428_))
		if componentPositions ~= nil and #componentPositions == #self.components then
			local v432_ = componentPositions[v420_][1]
			v424_, v425_, v426_ = unpack(v432_)
			local v433_ = componentPositions[v420_][2]
			v429_, v430_, v431_ = unpack(v433_)
		end
		self:setWorldPosition(v424_, v425_, v426_, v429_, v430_, v431_, v420_, true)
	end
	delete(v419_)
	self.networkTimeInterpolator:reset()
end

-- Local values: terrainHeight
function Vehicle:getLimitedVehicleYPosition(position)
	if position.posY == nil then
		return getTerrainHeightAtWorldPos(g_terrainNode, position.posX, 300, position.posZ) + Utils.getNoNil(position.yOffset, 0)
	else
		return position.posY
	end
end

-- Local values: component, qx, qy, qz, qw
function Vehicle:setWorldPosition(x, y, z, xRot, yRot, zRot, componentIndex, changeInterp)
	local v444_ = self.components[componentIndex]
	if v444_ ~= nil then
		setWorldTranslation(v444_.node, x, y, z)
		setWorldRotation(v444_.node, xRot, yRot, zRot)
		if changeInterp then
			local v445_, v446_, v447_, v448_ = mathEulerToQuaternion(xRot, yRot, zRot)
			v444_.networkInterpolators.quaternion:setQuaternion(v445_, v446_, v447_, v448_)
			v444_.networkInterpolators.position:setPosition(x, y, z)
		end
	end
end

-- Local values: component
function Vehicle:setWorldPositionQuaternion(x, y, z, qx, qy, qz, qw, componentIndex, changeInterp)
	local v459_ = self.components[componentIndex]
	if v459_ ~= nil then
		setWorldTranslation(v459_.node, x, y, z)
		setWorldQuaternion(v459_.node, qx, qy, qz, qw)
		if changeInterp then
			v459_.networkInterpolators.quaternion:setQuaternion(qx, qy, qz, qw)
			v459_.networkInterpolators.position:setPosition(x, y, z)
		end
	end
end

-- Local values: component, x, y, z, rx, ry, rz
function Vehicle:setDefaultComponentPosition(componentIndex)
	if componentIndex ~= 1 then
		local v462_ = self.components[componentIndex]
		if v462_ ~= nil then
			local v463_ = localToWorld
			local v464_ = self.rootNode
			local v465_ = v462_.originalTranslation
			local v466_, v467_, v468_ = v463_(v464_, unpack(v465_))
			local v469_ = localRotationToWorld
			local v470_ = self.rootNode
			local v471_ = v462_.originalRotation
			local v472_, v473_, v474_ = v469_(v470_, unpack(v471_))
			self:setWorldPosition(v466_, v467_, v468_, v472_, v473_, v474_, componentIndex, true)
		end
	end
end

-- Local values: maxOffset, i, component, wx, wy, wz, terrainHeight, i, component, wx, wy, wz, _, childVehicle
function Vehicle:resetPositionToTerrainHeight()
	local v476_ = 0
	for _, v477_ in pairs(self.components) do
		local v478_, v479_, v480_ = getWorldTranslation(v477_.node)
		local v481_ = getTerrainHeightAtWorldPos(g_terrainNode, v478_, v479_, v480_) - v479_
		v476_ = math.max(v476_, v481_)
	end
	self:removeFromPhysics()
	for _, v482_ in pairs(self.components) do
		local v483_, v484_, v485_ = getWorldTranslation(v482_.node)
		setWorldTranslation(v482_.node, v483_, v484_ + v476_ + 10, v485_)
	end
	self:addToPhysics()
	for _, v486_ in ipairs(self.childVehicles) do
		if v486_ ~= self then
			v486_:resetPositionToTerrainHeight()
		end
	end
end

-- Local values: _, rootLevelNode
function Vehicle:getIsNodeActive(node)
	while node ~= 0 do
		for _, v489_ in ipairs(self.rootLevelNodes) do
			if node == v489_.node then
				return not v489_.isInactive
			end
		end
		node = getParent(node)
	end
	return false
end

-- Local values: x1, y1, z1, dist, clipDist
function Vehicle:getUpdatePriority(skipCount, x, y, z, coeff, connection, isGuiVisible)
	if self:getOwnerConnection() == connection then
		return 50
	end
	local v497_, v498_, v499_ = getWorldTranslation(self.components[1].node)
	return (1 - MathUtil.vector3Length(v497_ - x, v498_ - y, v499_ - z) / (getClipDistance(self.components[1].node) * coeff)) * 0.8 + 0.5 * skipCount * 0.2
end

function Vehicle:getPrice()
	return self.price
end

-- Local values: storeItem
function Vehicle:getSellPrice()
	local v502_ = g_storeManager:getItemByXMLFilename(self.configFileName)
	return Vehicle.calculateSellPrice(v502_, self.age, self.operatingTime, self:getPrice(), self:getRepairPrice(), self:getRepaintPrice())
end

-- Local values: operatingTimeHours, maxVehicleAge, ageInYears, motorizedFactor, operatingTimeFactor, ageFactor
function Vehicle.calculateSellPrice(storeItem, age, operatingTime, price, repairPrice, repaintPrice)
	local v509_ = operatingTime / 3600000
	local v510_ = storeItem.lifetime
	local v511_ = age / Environment.PERIODS_IN_YEAR
	StoreItemUtil.loadSpecsFromXML(storeItem)
	local v512_ = 1 - v509_ ^ (storeItem.specs.power == nil and 1.3 or 1) / v510_
	local v513_ = -0.1 * math.log(v511_) + 0.75
	local v514_ = math.min(v513_, 0.85)
	local v515_ = price * v512_ * v514_ - repairPrice - repaintPrice
	local v516_ = price * 0.03
	return math.max(v515_, v516_)
end

-- Local values: _, component, wx, wy, wz, h, isOnField, _
function Vehicle:getIsOnField()
	for _, v518_ in pairs(self.components) do
		local v519_, v520_, v521_ = localToWorld(v518_.node, getCenterOfMass(v518_.node))
		if v520_ < getTerrainHeightAtWorldPos(g_terrainNode, v519_, v520_, v521_) - 1 then
			break
		end
		local v522_, _ = FSDensityMapUtil.getFieldDataAtWorldPosition(v519_, v520_, v521_)
		if v522_ then
			return true
		end
	end
	return false
end

function Vehicle:getParentComponent(node)
	while node ~= 0 do
		if self:getIsVehicleNode(node) then
			return node
		end
		node = getParent(node)
	end
	return 0
end

function Vehicle:getLastSpeed(useAttacherVehicleSpeed)
	if useAttacherVehicleSpeed and self.attacherVehicle ~= nil then
		return self.attacherVehicle:getLastSpeed(true)
	else
		return self.lastSpeed * 3600
	end
end
g_soundManager:registerModifierType("SPEED", Vehicle.getLastSpeed)

function Vehicle:getDeactivateOnLeave()
	return true
end

function Vehicle:getIsSynchronized()
	return self.loadingStep == SpecializationLoadStep.SYNCHRONIZED
end

function Vehicle:getActiveFarm()
	return self:getOwnerFarmId()
end

function Vehicle:getIsVehicleNode(nodeId)
	return self.vehicleNodes[nodeId] ~= nil
end

function Vehicle:getIsOperating()
	return false
end

function Vehicle:getIsActive()
	if self.isBroken then
		return false
	else
		return self.forceIsActive and true or false
	end
end

-- Local values: rootVehicle, selectedObject, rootAttacherVehicle
function Vehicle:getIsActiveForInput(ignoreSelection, activeForAI)
	if not self.allowsInput then
		return false
	end
	if not g_currentMission.isRunning then
		return false
	end
	if (activeForAI == nil or not activeForAI) and self:getIsAIActive() then
		return false
	end
	if not ignoreSelection then
		local v535_ = self.rootVehicle
		if v535_ == nil then
			return false
		end
		if self ~= v535_:getSelectedVehicle() then
			return false
		end
	end
	local v536_ = self.rootVehicle
	if v536_ == self then
		if self.getIsEntered == nil and (self.getAttacherVehicle ~= nil and self:getAttacherVehicle() == nil) then
			return false
		end
	elseif not v536_:getIsActiveForInput(true, activeForAI) then
		return false
	end
	return true
end

function Vehicle:getIsActiveForSound()
	printWarning("Warning: Vehicle:getIsActiveForSound() is deprecated")
	return false
end

function Vehicle:getIsLowered(defaultIsLowered)
	return false
end

-- Local values: x, y, z, raycastDistance
function Vehicle:updateWaterInfo()
	if not self.waterCheckIsPending then
		local v538_, v539_, v540_ = localToWorld(self.rootNode, 0, self.size.height * 0.5, 0)
		self.waterCheckPosition[1] = v538_
		self.waterCheckPosition[2] = v539_
		self.waterCheckPosition[3] = v540_
		self.waterCheckIsPending = true
		raycastClosestAsync(v538_, v539_ + 25, v540_, 0, -1, 0, 50, "onWaterRaycastCallback", self, CollisionFlag.WATER)
	end
end

-- Local values: checkY, waterY, checkX, checkZ, terrainHeight, waterDepth
function Vehicle:onWaterRaycastCallback(nodeId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	self.waterCheckIsPending = false
	local v544_ = self.waterCheckPosition[2] - self.size.height * 0.5
	local v545_ = nodeId == 0 and -2500 or y
	self.waterY = v545_
	self.isInWater = v544_ < v545_
	self.isInShallowWater = false
	self.isInMediumWater = false
	if self.isInWater then
		local v546_ = self.waterCheckPosition[1]
		local v547_ = self.waterCheckPosition[3]
		local v548_ = v545_ - getTerrainHeightAtWorldPos(g_terrainNode, v546_, 0, v547_)
		self.isInShallowWater = math.max(0, v548_) <= 0.5
		self.isInMediumWater = not self.isInShallowWater
	end
	local v549_ = v545_ - v544_
	self.tailwaterDepth = math.max(0, v549_)
	return false
end

function Vehicle:setBroken()
	if self.isServer and not self.isBroken then
		g_server:broadcastEvent(VehicleBrokenEvent.new(self), nil, nil, self)
	end
	self.isBroken = true
	SpecializationUtil.raiseEvent(self, "onSetBroken")
	if self.tourId ~= nil and g_guidedTourManager:getIsTourRunning() then
		g_guidedTourManager:abortTour()
	end
end

function Vehicle:getVehicleDamage()
	return 0
end

function Vehicle:getRepairPrice()
	return 0
end

function Vehicle:getRepaintPrice()
	return 0
end

-- Local values: vehicle
function Vehicle:requestActionEventUpdate()
	local v552_ = self.rootVehicle
	if v552_ == self then
		self.actionEventUpdateRequested = true
	else
		v552_:requestActionEventUpdate()
	end
	v552_:removeActionEvents()
end

function Vehicle:removeActionEvents()
	g_inputBinding:removeActionEventsByTarget(self)
end

-- Local values: rootVehicle
function Vehicle:updateActionEvents()
	self.rootVehicle:registerActionEvents()
end

-- Local values: isActiveForInput, isActiveForInputIgnoreSelection, numSelectableObjects, _, object, _, actionEventId
function Vehicle:registerActionEvents(excludedVehicle)
	if not g_gui:getIsGuiVisible() and (not g_currentMission.isPlayerFrozen and excludedVehicle ~= self) then
		self.actionEventUpdateRequested = false
		local v557_ = self:getIsActiveForInput()
		local v558_ = self:getIsActiveForInput(true)
		if v557_ then
			g_inputBinding:resetActiveActionBindings()
		end
		g_inputBinding:beginActionEventsModification(Vehicle.INPUT_CONTEXT_NAME)
		SpecializationUtil.raiseEvent(self, "onPreRegisterActionEvents", v557_, v558_)
		SpecializationUtil.raiseEvent(self, "onRegisterActionEvents", v557_, v558_)
		self:clearActionEventsTable(self.actionEvents)
		if self:getCanToggleSelectable() then
			local v559_ = 0
			for _, v560_ in ipairs(self.selectableObjects) do
				v559_ = v559_ + 1 + #v560_.subSelections
			end
			if v559_ > 1 then
				local _, v561_ = self:addActionEvent(self.actionEvents, InputAction.SWITCH_IMPLEMENT, self, Vehicle.actionEventToggleSelection, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(v561_, GS_PRIO_LOW)
				local _, v562_ = self:addActionEvent(self.actionEvents, InputAction.SWITCH_IMPLEMENT_BACK, self, Vehicle.actionEventToggleSelectionReverse, false, true, false, true, nil)
				g_inputBinding:setActionEventTextVisibility(v562_, false)
			end
		end
		VehicleDebug.registerActionEvents(self)
		if Platform.gameplay.automaticVehicleControl and (self.actionController ~= nil and (self:getIsActiveForInput(true) and self == self.rootVehicle)) then
			self.actionController:registerActionEvents(v557_, v558_)
		end
		g_inputBinding:endActionEventsModification()
	end
end

-- Local values: actionEventName, actionEvent
function Vehicle:clearActionEventsTable(actionEventsTable)
	if actionEventsTable ~= nil then
		for v564_, v565_ in pairs(actionEventsTable) do
			g_inputBinding:removeActionEvent(v565_.actionEventId)
			actionEventsTable[v564_] = nil
		end
	end
end

-- Local values: newCallback
function Vehicle:addPoweredActionEvent(actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, ignoreCollisions, reportAnyDeviceCollision)
	return self:addActionEvent(actionEventsTable, inputAction, target, function(p579_, p580_, p581_, p582_, p583_, p584_, p585_, p586_)
		-- upvalues: (copy) callback
		local v587_, v588_ = p579_:getIsPowered()
		if v587_ then
			callback(p579_, p580_, p581_, p582_, p583_, p584_, p585_, p586_)
		elseif p581_ ~= 0 and v588_ ~= nil then
			g_currentMission:showBlinkingWarning(v588_, 2000)
		end
	end, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, ignoreCollisions, reportAnyDeviceCollision)
end

-- Local values: state, actionEventId, otherEvents, event, clearedVehicleEvent, _, otherEvent, _, otherEvent
function Vehicle:addActionEvent(actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, ignoreCollisions, reportAnyDeviceCollision)
	local v602_, v603_, v604_ = g_inputBinding:registerActionEvent(inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, true, reportAnyDeviceCollision)
	if v602_ then
		actionEventsTable[inputAction] = {
			["actionEventId"] = v603_
		}
		local v605_ = g_inputBinding.events[v603_]
		if v605_ ~= nil then
			v605_.parentEventsTable = actionEventsTable
		end
		if customIconName and customIconName ~= "" then
			g_inputBinding:setActionEventIcon(v603_, customIconName)
		end
	end
	if v604_ ~= nil and (ignoreCollisions == nil or not ignoreCollisions) then
		if self:getIsSelected() then
			local v606_ = false
			for _, v607_ in ipairs(v604_) do
				if v607_.parentEventsTable ~= nil then
					g_inputBinding:removeActionEvent(v607_.id)
					v607_.parentEventsTable[v607_.id] = nil
					v606_ = true
				end
			end
			if v606_ then
				return self:addActionEvent(actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName)
			end
		else
			g_inputBinding:removeActionEvent(v603_)
			for _, v608_ in ipairs(v604_) do
				if v608_.targetObject.getIsSelected ~= nil and (not v608_.targetObject:getIsSelected() and v608_.parentEventsTable ~= nil) then
					g_inputBinding:removeActionEvent(v608_.id)
					v608_.parentEventsTable[v608_.id] = nil
				end
			end
		end
	end
	return v602_, v603_
end

function Vehicle:removeActionEvent(actionEventsTable, inputAction)
	if actionEventsTable[inputAction] ~= nil then
		g_inputBinding:removeActionEvent(actionEventsTable[inputAction].actionEventId)
		actionEventsTable[inputAction] = nil
	end
end

function Vehicle:updateSelectableObjects()
	self.selectableObjects = {}
	if self == self.rootVehicle then
		self:registerSelectableObjects(self.selectableObjects)
	end
end

function Vehicle:registerSelectableObjects(selectableObjects)
	if self:getCanBeSelected() and not self:getBlockSelection() then
		local v614_ = self.selectionObject
		table.insert(selectableObjects, v614_)
		self.selectionObject.index = #selectableObjects
	end
end

function Vehicle:addSubselection(subSelection)
	local v617_ = self.selectionObject.subSelections
	table.insert(v617_, subSelection)
	return #self.selectionObject.subSelections
end

function Vehicle:clearSubselections()
	self.selectionObject.subSelections = {}
end

function Vehicle:getCanBeSelected()
	return VehicleDebug.state ~= 0
end

function Vehicle:getBlockSelection()
	return not self.allowSelection
end

function Vehicle:getCanToggleSelectable()
	return false
end

function Vehicle:getRootVehicle()
	return self.rootVehicle
end

function Vehicle:findRootVehicle()
	return self
end

function Vehicle:getChildVehicles()
	return self.childVehicles
end

function Vehicle:getChildVehicleHash()
	return self.childVehicleHash
end

function Vehicle:addChildVehicles(vehicles, rootVehicle)
	table.insert(vehicles, self)
	local v627_ = rootVehicle.childVehicleHash
	local v628_ = self.id
	rootVehicle.childVehicleHash = v627_ .. ":" .. tostring(v628_)
end

-- Local values: rootVehicle, i, i
function Vehicle:updateVehicleChain(secondCall)
	local v631_ = self:findRootVehicle()
	if v631_ ~= self.rootVehicle then
		self.rootVehicle = v631_
		SpecializationUtil.raiseEvent(self, "onRootVehicleChanged", v631_)
	end
	if v631_ == self or secondCall then
		for v632_ = #self.childVehicles, 1, -1 do
			self.childVehicles[v632_] = nil
		end
		self.childVehicleHash = ""
		self:addChildVehicles(self.childVehicles, self)
		if v631_ == self then
			for v633_ = 1, #self.childVehicles do
				if self.childVehicles[v633_] ~= v631_ then
					self.childVehicles[v633_]:updateVehicleChain(true)
				end
			end
		end
	else
		v631_:updateVehicleChain()
	end
end

function Vehicle:unselectVehicle()
	self.selectionObject.isSelected = false
	SpecializationUtil.raiseEvent(self, "onUnselect")
	self:requestActionEventUpdate()
end

function Vehicle:selectVehicle(subSelectionIndex, ignoreActionEventUpdate)
	self.selectionObject.isSelected = true
	SpecializationUtil.raiseEvent(self, "onSelect", subSelectionIndex)
	if ignoreActionEventUpdate == nil or not ignoreActionEventUpdate then
		self:requestActionEventUpdate()
	end
end

-- Local values: object, _, o
function Vehicle:setSelectedVehicle(vehicle, subSelectionIndex, ignoreActionEventUpdate)
	local v642_ = nil
	if vehicle == nil or (not vehicle:getCanBeSelected() or self:getBlockSelection()) then
		vehicle = nil
		for _, v643_ in ipairs(self.selectableObjects) do
			if v643_.vehicle:getCanBeSelected() and not v643_.vehicle:getBlockSelection() then
				vehicle = v643_.vehicle
				break
			end
		end
	end
	if vehicle ~= nil then
		v642_ = vehicle.selectionObject
	end
	return self:setSelectedObject(v642_, subSelectionIndex, ignoreActionEventUpdate)
end

-- Local values: currentSelection, found, _, o, _, o, _, o
function Vehicle:setSelectedObject(object, subSelectionIndex, ignoreActionEventUpdate)
	local v648_ = self.currentSelection
	if object == nil then
		object = self:getSelectedObject()
	end
	local v649_ = false
	for _, v650_ in ipairs(self.selectableObjects) do
		if v650_ == object then
			v649_ = true
		end
	end
	if v649_ then
		for _, v651_ in ipairs(self.selectableObjects) do
			if v651_ ~= object and v651_.vehicle:getIsSelected() then
				v651_.vehicle:unselectVehicle()
			end
		end
		if object ~= v648_.object or subSelectionIndex ~= v648_.subIndex then
			v648_.object = object
			v648_.index = object.index
			if subSelectionIndex ~= nil then
				v648_.subIndex = subSelectionIndex
			end
			if v648_.subIndex > #object.subSelections then
				v648_.subIndex = 1
			end
			v648_.object.vehicle:selectVehicle(v648_.subIndex, ignoreActionEventUpdate)
			return true
		end
	else
		local v652_ = self:getSelectedObject()
		local v653_ = false
		for _, v654_ in ipairs(self.selectableObjects) do
			if v654_ == v652_ then
				v653_ = true
			end
		end
		if not v653_ then
			v648_.object = nil
			v648_.index = 1
			v648_.subIndex = 1
		end
	end
	return false
end

function Vehicle:getIsSelected()
	if self.selectionObject == nil then
		return false
	else
		return self.selectionObject.isSelected
	end
end

-- Local values: rootVehicle
function Vehicle:getSelectedObject()
	local v657_ = self.rootVehicle
	if v657_ == self then
		return self.currentSelection.object
	else
		return v657_:getSelectedObject()
	end
end

-- Local values: selectedObject
function Vehicle:getSelectedVehicle()
	local v659_ = self:getSelectedObject()
	if v659_ == nil then
		return nil
	else
		return v659_.vehicle
	end
end

function Vehicle:hasInputConflictWithSelection(inputs)
	printCallstack()
	Logging.xmlWarning(self.xmlFile, "Vehicle:hasInputConflictWithSelection() is deprecated!")
	return false
end

function Vehicle:setMassDirty()
	self.isMassDirty = true
end

-- Local values: k, component, mass, realTotalMass, _, component, k, component, maxFactor
function Vehicle:updateMass()
	self.serverMass = 0
	for v663_, v664_ in ipairs(self.components) do
		if v664_.defaultMass == nil then
			if v664_.isDynamic then
				v664_.defaultMass = getMass(v664_.node)
			else
				v664_.defaultMass = 1
			end
			v664_.mass = v664_.defaultMass
		end
		local v665_ = self:getAdditionalComponentMass(v664_)
		if v665_ == math.huge then
			Logging.devError("%s: Additional component \'%d\' mass is inf!", self.configFileName, v663_)
		end
		v664_.mass = v664_.defaultMass + v665_
		if v664_.mass == math.huge then
			Logging.devError("%s: Setting component \'%d\' mass to inf!", self.configFileName, v663_)
		end
		self.serverMass = self.serverMass + v664_.mass
	end
	local v666_ = 0
	for _, v667_ in ipairs(self.components) do
		v666_ = v666_ + self:getComponentMass(v667_)
	end
	self.precalculatedMass = v666_ - self.serverMass
	for v668_, v669_ in ipairs(self.components) do
		local v670_ = self.serverMass / (self.maxComponentMass - self.precalculatedMass)
		if v670_ > 1 then
			v669_.mass = v669_.mass / v670_
			if v669_.mass == math.huge then
				Logging.devError("%s: Scaling component \'%d\' mass to inf! MaxFactor %s | serverMass %s | maxComponentMass %s | precalculatedMass %s", self.configFileName, v668_, v670_, self.serverMass, self.maxComponentMass, self.precalculatedMass)
			end
		end
		if self.isServer and v669_.isDynamic then
			local v671_ = v669_.lastMass - v669_.mass
			if math.abs(v671_) > 0.02 then
				setMass(v669_.node, v669_.mass)
				v669_.lastMass = v669_.mass
			end
		end
	end
	local v672_ = self.serverMass
	local v673_ = self.maxComponentMass - self.precalculatedMass
	self.serverMass = math.min(v672_, v673_)
end

function Vehicle:getMaxComponentMassReached()
	return self.serverMass + 0.001 >= self.maxComponentMass - self.precalculatedMass
end

function Vehicle:getAvailableComponentMass()
	local v676_ = self.maxComponentMass - self.precalculatedMass - self.serverMass
	return math.max(v676_, 0)
end

function Vehicle:getAdditionalComponentMass(component)
	return 0
end

-- Local values: mass, _, component
function Vehicle:getTotalMass(onlyGivenVehicle)
	local v678_ = 0
	for _, v679_ in ipairs(self.components) do
		v678_ = v678_ + self:getComponentMass(v679_)
	end
	return v678_
end

function Vehicle:getComponentMass(component)
	return component == nil and 0 or component.mass
end

-- Local values: mass, _, component
function Vehicle:getDefaultMass()
	local v682_ = 0
	for _, v683_ in ipairs(self.components) do
		v682_ = v682_ + (v683_.defaultMass or 0)
	end
	return v682_
end

-- Local values: cx, cy, cz, totalMass, numComponents, i, component, ccx, ccy, ccz, percentage
function Vehicle:getOverallCenterOfMass()
	local v685_ = self:getTotalMass(true)
	local v686_ = 0
	local v687_ = 0
	local v688_ = 0
	for v689_ = 1, #self.components do
		local v690_ = self.components[v689_]
		local v691_, v692_, v693_ = localToWorld(v690_.node, getCenterOfMass(v690_.node))
		local v694_ = self:getComponentMass(v690_) / v685_
		v686_ = v686_ + v691_ * v694_
		v687_ = v687_ + v692_ * v694_
		v688_ = v688_ + v693_ * v694_
	end
	return v686_, v687_, v688_
end

-- Local values: _, y, _, slopeAngle
function Vehicle:getVehicleWorldXRot()
	local _, v696_, _ = localDirectionToWorld(self.components[1].node, 0, 0, 1)
	local v697_ = 1 / v696_
	local v698_ = 1.5707963267948966 - math.atan(v697_)
	if v698_ > 1.5707963267948966 then
		v698_ = v698_ - 3.141592653589793
	end
	return v698_
end

function Vehicle:getVehicleWorldDirection()
	return localDirectionToWorld(self.components[1].node, 0, 0, 1)
end

function Vehicle:getFillLevelInformation(display) end

function Vehicle:getHasObjectMounted(object)
	return false
end

function Vehicle:activate()
	if self.actionController ~= nil then
		self.actionController:activate()
	end
	SpecializationUtil.raiseEvent(self, "onActivate")
end

function Vehicle:deactivate()
	if self.actionController ~= nil then
		self.actionController:deactivate()
	end
	SpecializationUtil.raiseEvent(self, "onDeactivate")
end

-- Local values: localPoses, localPoses, jointNode
function Vehicle:setComponentJointFrame(jointDesc, anchorActor)
	if anchorActor == 0 then
		local v705_ = jointDesc.jointLocalPoses[1]
		local v706_ = v705_.trans
		local v707_ = v705_.trans
		local v708_ = v705_.trans
		local v709_, v710_, v711_ = localToLocal(jointDesc.jointNode, self.objects[jointDesc.objectIndices[1]].node, 0, 0, 0)
		v706_[1] = v709_
		v707_[2] = v710_
		v708_[3] = v711_
		local v712_ = v705_.rot
		local v713_ = v705_.rot
		local v714_ = v705_.rot
		local v715_, v716_, v717_ = localRotationToLocal(jointDesc.jointNode, self.objects[jointDesc.objectIndices[1]].node, 0, 0, 0)
		v712_[1] = v715_
		v713_[2] = v716_
		v714_[3] = v717_
	else
		local v718_ = jointDesc.jointLocalPoses[2]
		local v719_ = v718_.trans
		local v720_ = v718_.trans
		local v721_ = v718_.trans
		local v722_, v723_, v724_ = localToLocal(jointDesc.jointNodeActor1, self.objects[jointDesc.objectIndices[2]].node, 0, 0, 0)
		v719_[1] = v722_
		v720_[2] = v723_
		v721_[3] = v724_
		local v725_ = v718_.rot
		local v726_ = v718_.rot
		local v727_ = v718_.rot
		local v728_, v729_, v730_ = localRotationToLocal(jointDesc.jointNodeActor1, self.objects[jointDesc.objectIndices[2]].node, 0, 0, 0)
		v725_[1] = v728_
		v726_[2] = v729_
		v727_[3] = v730_
	end
	local v731_ = jointDesc.jointNode
	if anchorActor == 1 then
		v731_ = jointDesc.jointNodeActor1
	end
	if jointDesc.jointIndex ~= 0 then
		setJointFrame(jointDesc.jointIndex, anchorActor, v731_)
	end
end

function Vehicle:setComponentJointRotLimit(componentJoint, axis, minLimit, maxLimit)
	if self.isServer then
		componentJoint.rotLimit[axis] = maxLimit
		componentJoint.rotMinLimit[axis] = minLimit
		if componentJoint.jointIndex ~= 0 then
			if minLimit <= maxLimit then
				setJointRotationLimit(componentJoint.jointIndex, axis - 1, true, minLimit, maxLimit)
				return
			end
			setJointRotationLimit(componentJoint.jointIndex, axis - 1, false, 0, 0)
		end
	end
end

function Vehicle:setComponentJointTransLimit(componentJoint, axis, minLimit, maxLimit)
	if self.isServer then
		componentJoint.transLimit[axis] = maxLimit
		componentJoint.transMinLimit[axis] = minLimit
		if componentJoint.jointIndex ~= 0 then
			if minLimit <= maxLimit then
				setJointTranslationLimit(componentJoint.jointIndex, axis - 1, true, minLimit, maxLimit)
				return
			end
			setJointTranslationLimit(componentJoint.jointIndex, axis - 1, false, 0, 0)
		end
	end
end

-- Local values: x, y, z, rx, ry, rz, mass, comX, comY, comZ, inertiaScaleX, inertiaScaleY, inertiaScaleZ, count, clipDistance, defaultClipdistance, name
function Vehicle:loadComponentFromXML(component, xmlFile, key, rootPosition, i)
	if not self.isServer and getRigidBodyType(component.node) == RigidBodyType.DYNAMIC then
		setRigidBodyType(component.node, RigidBodyType.KINEMATIC)
	end
	if i == 1 then
		local v748_, v749_, v750_ = getTranslation(component.node)
		rootPosition[1] = v748_
		rootPosition[2] = v749_
		rootPosition[3] = v750_
		if rootPosition[2] ~= 0 then
			Logging.xmlWarning(self.xmlFile, "Y-Translation of object 1 (node 0>) has to be 0. Current value is: %.5f", rootPosition[2])
		end
	end
	if getRigidBodyType(component.node) == RigidBodyType.STATIC then
		component.isStatic = true
	elseif getRigidBodyType(component.node) == RigidBodyType.KINEMATIC then
		component.isKinematic = true
	elseif getRigidBodyType(component.node) == RigidBodyType.DYNAMIC then
		component.isDynamic = true
	end
	if not CollisionFlag.getHasGroupFlagSet(component.node, CollisionFlag.VEHICLE) then
		Logging.xmlWarning(self.xmlFile, "Missing collision group mask %s. Please add this bit to object node \'%s\'", CollisionFlag.getBitAndName(CollisionFlag.VEHICLE), getName(component.node))
	end
	if not CollisionFlag.getHasMaskFlagSet(component.node, CollisionFlag.VEHICLE) then
		Logging.xmlWarning(self.xmlFile, "Missing collision filter mask %s. Please add this bit to object node \'%s\'", CollisionFlag.getBitAndName(CollisionFlag.VEHICLE), getName(component.node))
	end
	translate(component.node, -rootPosition[1], -rootPosition[2], -rootPosition[3])
	local v751_, v752_, v753_ = getTranslation(component.node)
	local v754_, v755_, v756_ = getRotation(component.node)
	component.originalTranslation = { v751_, v752_, v753_ }
	component.originalRotation = { v754_, v755_, v756_ }
	component.sentTranslation = { v751_, v752_, v753_ }
	component.sentRotation = { v754_, v755_, v756_ }
	component.defaultMass = nil
	component.mass = nil
	local v757_ = xmlFile:getValue(key .. "#mass")
	if v757_ == nil then
		Logging.xmlWarning(self.xmlFile, "Missing \'mass\' for \'%s\'. Using default mass 500kg instead!", key)
		component.defaultMass = 0.5
		component.mass = 0.5
		component.lastMass = component.mass
	else
		if v757_ < 10 then
			Logging.xmlDevWarning(self.xmlFile, "Mass is lower than 10kg for \'%s\'. Mass unit is kilograms. Is this correct?", key)
		end
		if component.isDynamic then
			setMass(component.node, v757_ / 1000)
		end
		component.defaultMass = v757_ / 1000
		component.mass = component.defaultMass
		component.lastMass = component.mass
	end
	local v758_, v759_, v760_ = xmlFile:getValue(key .. "#centerOfMass")
	if v758_ ~= nil then
		setCenterOfMass(component.node, v758_, v759_, v760_)
	end
	local v761_, v762_, v763_ = xmlFile:getValue(key .. "#inertiaScale")
	if v761_ ~= nil then
		setInertiaScale(component.node, v761_, v762_, v763_)
	end
	local v764_ = xmlFile:getValue(key .. "#solverIterationCount")
	if v764_ ~= nil then
		setSolverIterationCount(component.node, v764_)
		component.solverIterationCount = v764_
	end
	component.motorized = xmlFile:getValue(key .. "#motorized")
	self.vehicleNodes[component.node] = {
		["object"] = component
	}
	if getClipDistance(component.node) >= 1000000 and getVisibility(component.node) then
		Logging.xmlWarning(self.xmlFile, "No clipdistance is set to object node \'%s\' (%s>). Set default clipdistance \'%d\'", getName(component.node), i - 1, 300)
		setClipDistance(component.node, 300)
	end
	component.collideWithAttachables = xmlFile:getValue(key .. "#collideWithAttachables", false)
	if getRigidBodyType(component.node) ~= RigidBodyType.NONE then
		if getLinearDamping(component.node) > 0.01 then
			Logging.xmlDevWarning(self.xmlFile, "Non-zero linear damping (%.4f) for object node \'%s\' (%s>). Is this correct?", getLinearDamping(component.node), getName(component.node), i - 1)
		elseif getAngularDamping(component.node) > 0.05 then
			Logging.xmlDevWarning(self.xmlFile, "Large angular damping (%.4f) for object node \'%s\' (%s>). Is this correct?", getAngularDamping(component.node), getName(component.node), i - 1)
		elseif getAngularDamping(component.node) < 0.0001 then
			Logging.xmlDevWarning(self.xmlFile, "Zero damping for object node \'%s\' (%s>). Is this correct?", getName(component.node), i - 1)
		end
	end
	local v765_ = getName(component.node)
	if not v765_:contains("_object") then
		Logging.xmlDevWarning(self.xmlFile, "Name of object \'%d\' (\'%s\') does not correspond with the object naming convention! (vehicleName_objectName_object%d)", i, v765_, i)
	end
	g_currentMission:addNodeObject(component.node, self)
	return true
end

-- Local values: x, y, z, rotLimits, transLimits, rotMinLimits, transMinLimits, i, trans, rot, rotLimitSpring, rotLimitDamping, rotLimitForceLimit, transLimitForceLimit, transLimitSpring, transLimitDamping, zRotationNode, yOffset, zOffset, maxRotDriveForce, rotDriveVelocity, rotDriveRotation, rotDriveSpring, rotDriveDamping, maxTransDriveForce, transDriveVelocity, transDrivePosition, transDriveSpring, transDriveDamping
function Vehicle:loadComponentJointFromXML(jointDesc, xmlFile, key, componentJointI, jointNode, index1, index2)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#indexActor1", key .. "#nodeActor1")
	jointDesc.objectIndices = { index1, index2 }
	jointDesc.jointNode = jointNode
	jointDesc.jointNodeActor1 = xmlFile:getValue(key .. "#nodeActor1", jointNode, self.objects, self.i3dMappings)
	if self.isServer then
		if self.objects[index1] == nil or self.objects[index2] == nil then
			Logging.xmlWarning(self.xmlFile, "Invalid object indices (object1: %d, object2: %d) for object joint %d. Indices start with 1!", index1, index2, componentJointI)
			return false
		end
		local v774_, v775_, v776_ = xmlFile:getValue(key .. "#rotLimit")
		local v777_ = {}
		local v778_ = Utils.getNoNil(v774_, 0)
		local v779_ = math.rad(v778_)
		local v780_ = Utils.getNoNil(v775_, 0)
		local v781_ = math.rad(v780_)
		local v782_ = Utils.getNoNil(v776_, 0)
		__set_list(v777_, 1, {v779_, v781_, (math.rad(v782_))})
		local v783_, v784_, v785_ = xmlFile:getValue(key .. "#transLimit")
		local v786_ = { Utils.getNoNil(v783_, 0), Utils.getNoNil(v784_, 0), Utils.getNoNil(v785_, 0) }
		jointDesc.rotLimit = v777_
		jointDesc.transLimit = v786_
		local v787_, v788_, v789_ = xmlFile:getValue(key .. "#rotMinLimit")
		local v790_ = { Utils.getNoNilRad(v787_, nil), Utils.getNoNilRad(v788_, nil), Utils.getNoNilRad(v789_, nil) }
		local v791_, v792_, v793_ = xmlFile:getValue(key .. "#transMinLimit")
		local v794_ = { v791_, v792_, v793_ }
		for v795_ = 1, 3 do
			if v790_[v795_] == nil then
				if v777_[v795_] >= 0 then
					v790_[v795_] = -v777_[v795_]
				else
					v790_[v795_] = v777_[v795_] + 1
				end
			end
			if v794_[v795_] == nil then
				if v786_[v795_] >= 0 then
					v794_[v795_] = -v786_[v795_]
				else
					v794_[v795_] = v786_[v795_] + 1
				end
			end
		end
		jointDesc.jointLocalPoses = {}
		local v796_ = {
			["trans"] = { localToLocal(jointDesc.jointNode, self.objects[index1].node, 0, 0, 0) },
			["rot"] = { localRotationToLocal(jointDesc.jointNode, self.objects[index1].node, 0, 0, 0) }
		}
		jointDesc.jointLocalPoses[1] = v796_
		local v797_ = {
			["trans"] = { localToLocal(jointDesc.jointNodeActor1, self.objects[index2].node, 0, 0, 0) },
			["rot"] = { localRotationToLocal(jointDesc.jointNodeActor1, self.objects[index2].node, 0, 0, 0) }
		}
		jointDesc.jointLocalPoses[2] = v797_
		jointDesc.rotMinLimit = v790_
		jointDesc.transMinLimit = v794_
		local v798_, v799_, v800_ = xmlFile:getValue(key .. "#rotLimitSpring")
		local v801_ = { Utils.getNoNil(v798_, 0), Utils.getNoNil(v799_, 0), Utils.getNoNil(v800_, 0) }
		local v802_, v803_, v804_ = xmlFile:getValue(key .. "#rotLimitDamping")
		local v805_ = { Utils.getNoNil(v802_, 1), Utils.getNoNil(v803_, 1), Utils.getNoNil(v804_, 1) }
		jointDesc.rotLimitSpring = v801_
		jointDesc.rotLimitDamping = v805_
		local v806_, v807_, v808_ = xmlFile:getValue(key .. "#rotLimitForceLimit")
		local v809_ = { Utils.getNoNil(v806_, -1), Utils.getNoNil(v807_, -1), Utils.getNoNil(v808_, -1) }
		local v810_, v811_, v812_ = xmlFile:getValue(key .. "#transLimitForceLimit")
		local v813_ = { Utils.getNoNil(v810_, -1), Utils.getNoNil(v811_, -1), Utils.getNoNil(v812_, -1) }
		jointDesc.rotLimitForceLimit = v809_
		jointDesc.transLimitForceLimit = v813_
		local v814_, v815_, v816_ = xmlFile:getValue(key .. "#transLimitSpring")
		local v817_ = { Utils.getNoNil(v814_, 0), Utils.getNoNil(v815_, 0), Utils.getNoNil(v816_, 0) }
		local v818_, v819_, v820_ = xmlFile:getValue(key .. "#transLimitDamping")
		local v821_ = { Utils.getNoNil(v818_, 1), Utils.getNoNil(v819_, 1), Utils.getNoNil(v820_, 1) }
		jointDesc.transLimitSpring = v817_
		jointDesc.transLimitDamping = v821_
		jointDesc.zRotationXOffset = 0
		local v822_ = xmlFile:getValue(key .. "#zRotationNode", nil, self.objects, self.i3dMappings)
		if v822_ ~= nil then
			local v823_, v824_, v825_ = localToLocal(v822_, jointNode, 0, 0, 0)
			jointDesc.zRotationXOffset = v823_
			if math.abs(v824_) > 0.01 or math.abs(v825_) > 0.01 then
				Logging.xmlWarning(self.xmlFile, "ComponentJoint zRotationNode \'%s\' is not correctly aligned with joint node \'%s\'. Offset is: y %.3f, z %.3f. Make sure the zRotationNode has only a translation offset on the X axis.", getName(v822_), getName(jointNode), v824_, v825_)
			end
		end
		jointDesc.isBreakable = xmlFile:getValue(key .. "#breakable", false)
		if jointDesc.isBreakable then
			jointDesc.breakForce = xmlFile:getValue(key .. "#breakForce", 10)
			jointDesc.breakTorque = xmlFile:getValue(key .. "#breakTorque", 10)
		end
		jointDesc.enableCollision = xmlFile:getValue(key .. "#enableCollision", false)
		local v826_, v827_, v828_ = xmlFile:getValue(key .. "#maxRotDriveForce")
		local v829_ = { Utils.getNoNil(v826_, 0), Utils.getNoNil(v827_, 0), Utils.getNoNil(v828_, 0) }
		local v830_, v831_, v832_ = xmlFile:getValue(key .. "#rotDriveVelocity")
		local v833_ = { Utils.getNoNilRad(v830_, nil), Utils.getNoNilRad(v831_, nil), Utils.getNoNilRad(v832_, nil) }
		local v834_, v835_, v836_ = xmlFile:getValue(key .. "#rotDriveRotation")
		local v837_ = { Utils.getNoNilRad(v834_, nil), Utils.getNoNilRad(v835_, nil), Utils.getNoNilRad(v836_, nil) }
		local v838_, v839_, v840_ = xmlFile:getValue(key .. "#rotDriveSpring")
		local v841_ = { Utils.getNoNil(v838_, 0), Utils.getNoNil(v839_, 0), Utils.getNoNil(v840_, 0) }
		local v842_, v843_, v844_ = xmlFile:getValue(key .. "#rotDriveDamping")
		local v845_ = { Utils.getNoNil(v842_, 0), Utils.getNoNil(v843_, 0), Utils.getNoNil(v844_, 0) }
		jointDesc.rotDriveVelocity = v833_
		jointDesc.rotDriveRotation = v837_
		jointDesc.rotDriveSpring = v841_
		jointDesc.rotDriveDamping = v845_
		jointDesc.maxRotDriveForce = v829_
		local v846_, v847_, v848_ = xmlFile:getValue(key .. "#maxTransDriveForce")
		local v849_ = { Utils.getNoNil(v846_, 0), Utils.getNoNil(v847_, 0), Utils.getNoNil(v848_, 0) }
		local v850_, v851_, v852_ = xmlFile:getValue(key .. "#transDriveVelocity")
		local v853_ = { v850_, v851_, v852_ }
		local v854_, v855_, v856_ = xmlFile:getValue(key .. "#transDrivePosition")
		local v857_ = { v854_, v855_, v856_ }
		local v858_, v859_, v860_ = xmlFile:getValue(key .. "#transDriveSpring")
		local v861_ = { Utils.getNoNil(v858_, 0), Utils.getNoNil(v859_, 0), Utils.getNoNil(v860_, 0) }
		local v862_, v863_, v864_ = xmlFile:getValue(key .. "#transDriveDamping")
		local v865_ = { Utils.getNoNil(v862_, 1), Utils.getNoNil(v863_, 1), Utils.getNoNil(v864_, 1) }
		jointDesc.transDriveVelocity = v853_
		jointDesc.transDrivePosition = v857_
		jointDesc.transDriveSpring = v861_
		jointDesc.transDriveDamping = v865_
		jointDesc.maxTransDriveForce = v849_
		jointDesc.initComponentPosition = xmlFile:getValue(key .. "#initComponentPosition", true)
		jointDesc.jointIndex = 0
	end
	return true
end

-- Local values: constr, localPoses1, localPoses2, i, i, pos, vel, pos, vel
function Vehicle:createComponentJoint(component1, component2, jointDesc)
	if component1 == nil or (component2 == nil or jointDesc == nil) then
		Logging.xmlWarning(self.xmlFile, "Could not create object joint. No object1, object2 or jointDesc given!")
		return false
	end
	local v870_ = JointConstructor.new()
	v870_:setActors(component1.node, component2.node)
	local v871_ = jointDesc.jointLocalPoses[1]
	local v872_ = jointDesc.jointLocalPoses[2]
	v870_:setJointLocalPositions(v871_.trans[1], v871_.trans[2], v871_.trans[3], v872_.trans[1], v872_.trans[2], v872_.trans[3])
	v870_:setJointLocalRotations(v871_.rot[1], v871_.rot[2], v871_.rot[3], v872_.rot[1], v872_.rot[2], v872_.rot[3])
	v870_:setRotationLimitSpring(jointDesc.rotLimitSpring[1], jointDesc.rotLimitDamping[1], jointDesc.rotLimitSpring[2], jointDesc.rotLimitDamping[2], jointDesc.rotLimitSpring[3], jointDesc.rotLimitDamping[3])
	v870_:setTranslationLimitSpring(jointDesc.transLimitSpring[1], jointDesc.transLimitDamping[1], jointDesc.transLimitSpring[2], jointDesc.transLimitDamping[2], jointDesc.transLimitSpring[3], jointDesc.transLimitDamping[3])
	v870_:setZRotationXOffset(jointDesc.zRotationXOffset)
	for v873_ = 1, 3 do
		if jointDesc.rotLimit[v873_] >= jointDesc.rotMinLimit[v873_] then
			v870_:setRotationLimit(v873_ - 1, jointDesc.rotMinLimit[v873_], jointDesc.rotLimit[v873_])
		end
		if jointDesc.transLimit[v873_] >= jointDesc.transMinLimit[v873_] then
			v870_:setTranslationLimit(v873_ - 1, true, jointDesc.transMinLimit[v873_], jointDesc.transLimit[v873_])
		else
			v870_:setTranslationLimit(v873_ - 1, false, 0, 0)
		end
	end
	v870_:setRotationLimitForceLimit(jointDesc.rotLimitForceLimit[1], jointDesc.rotLimitForceLimit[2], jointDesc.rotLimitForceLimit[3])
	v870_:setTranslationLimitForceLimit(jointDesc.transLimitForceLimit[1], jointDesc.transLimitForceLimit[2], jointDesc.transLimitForceLimit[3])
	if jointDesc.isBreakable then
		v870_:setBreakable(jointDesc.breakForce, jointDesc.breakTorque)
	end
	v870_:setEnableCollision(jointDesc.enableCollision)
	for v874_ = 1, 3 do
		if jointDesc.maxRotDriveForce[v874_] > 0.0001 and (jointDesc.rotDriveVelocity[v874_] ~= nil or jointDesc.rotDriveRotation[v874_] ~= nil) then
			local v875_ = Utils.getNoNil(jointDesc.rotDriveRotation[v874_], 0)
			local v876_ = Utils.getNoNil(jointDesc.rotDriveVelocity[v874_], 0)
			v870_:setAngularDrive(v874_ - 1, jointDesc.rotDriveRotation[v874_] ~= nil, jointDesc.rotDriveVelocity[v874_] ~= nil, jointDesc.rotDriveSpring[v874_], jointDesc.rotDriveDamping[v874_], jointDesc.maxRotDriveForce[v874_], v875_, v876_)
		end
		if jointDesc.maxTransDriveForce[v874_] > 0.0001 and (jointDesc.transDriveVelocity[v874_] ~= nil or jointDesc.transDrivePosition[v874_] ~= nil) then
			local v877_ = Utils.getNoNil(jointDesc.transDrivePosition[v874_], 0)
			local v878_ = Utils.getNoNil(jointDesc.transDriveVelocity[v874_], 0)
			v870_:setLinearDrive(v874_ - 1, jointDesc.transDrivePosition[v874_] ~= nil, jointDesc.transDriveVelocity[v874_] ~= nil, jointDesc.transDriveSpring[v874_], jointDesc.transDriveDamping[v874_], jointDesc.maxTransDriveForce[v874_], v877_, v878_)
		end
	end
	jointDesc.jointIndex = v870_:finalize()
	return true
end

-- Local values: name
function Vehicle.prefixSchemaOverlayName(baseName, prefix)
	if baseName ~= "" and not VehicleSchemaOverlayData.SCHEMA_OVERLAY[baseName] then
		baseName = prefix .. baseName
	end
	return baseName
end

-- Local values: x, y, baseX, baseY, schemaName, modPrefix
function Vehicle:loadSchemaOverlay(xmlFile)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.schemaOverlay#file")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.schemaOverlay#width")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.schemaOverlay#height")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.schemaOverlay#invisibleBorderRight", "vehicle.base.schemaOverlay#invisibleBorderRight")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.schemaOverlay#invisibleBorderLeft", "vehicle.base.schemaOverlay#invisibleBorderLeft")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.schemaOverlay#attacherJointPosition", "vehicle.base.schemaOverlay#attacherJointPosition")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.schemaOverlay#basePosition", "vehicle.base.schemaOverlay#basePosition")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.schemaOverlay#fileSelected")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.schemaOverlay#fileTurnedOn")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.schemaOverlay#fileSelectedTurnedOn")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.base.schemaOverlay.default#name", "vehicle.base.schemaOverlay#name")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.base.schemaOverlay.turnedOn#name")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.base.schemaOverlay.selected#name")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.base.schemaOverlay.turnedOnSelected#name")
	if xmlFile:hasProperty("vehicle.base.schemaOverlay") then
		XMLUtil.checkDeprecatedXMLElements(xmlFile, "vehicle.schemaOverlay.attacherJoint", "vehicle.attacherJoints.attacherJoint.schema")
		local v883_, v884_ = xmlFile:getValue("vehicle.base.schemaOverlay#attacherJointPosition")
		local v885_, v886_ = xmlFile:getValue("vehicle.base.schemaOverlay#basePosition")
		if v885_ ~= nil then
			v883_ = v885_
		end
		if v886_ ~= nil then
			v884_ = v886_
		end
		local v887_ = xmlFile:getValue("vehicle.base.schemaOverlay#name", "")
		local v888_ = self.customEnvironment or ""
		local v889_ = Vehicle.prefixSchemaOverlayName(v887_, v888_)
		self.schemaOverlay = VehicleSchemaOverlayData.new(v883_, v884_, v889_, xmlFile:getValue("vehicle.base.schemaOverlay#invisibleBorderRight"), xmlFile:getValue("vehicle.base.schemaOverlay#invisibleBorderLeft"))
	end
end

function Vehicle:getAdditionalSchemaText()
	return nil
end

function Vehicle:getUseTurnedOnSchema()
	return false
end

function Vehicle:dayChanged() end

function Vehicle:periodChanged()
	self.age = self.age + 1
end
function Vehicle.raiseStateChange(p891_, p892_, ...)
	SpecializationUtil.raiseEvent(p891_, "onStateChange", p892_, ...)
end

function Vehicle:doCheckSpeedLimit()
	return false
end

function Vehicle:getWorkLoad()
	return 0, 0
end

function Vehicle:interact(player) end

function Vehicle:getInteractionHelp()
	return ""
end

function Vehicle:getIsInteractive()
	return not self.isBroken
end

function Vehicle:getDistanceToNode(node)
	self.interactionFlag = Vehicle.INTERACTION_FLAG_NONE
	return math.huge
end

-- Local values: attacherVehicle
function Vehicle:getIsAIActive()
	if self.getAttacherVehicle ~= nil then
		local v896_ = self:getAttacherVehicle()
		if v896_ ~= nil then
			return v896_:getIsAIActive()
		end
	end
	return false
end

function Vehicle:getIsPowered()
	return true
end

function Vehicle:getRequiresPower()
	return false
end

function Vehicle:getIsInShowroom()
	return self.propertyState == VehiclePropertyState.SHOP_CONFIG
end

function Vehicle:addVehicleToAIImplementList(list) end

function Vehicle:setOperatingTime(operatingTime, isLoading)
	if not isLoading and (self.propertyState == VehiclePropertyState.LEASED and (g_currentMission ~= nil and g_currentMission.economyManager ~= nil)) then
		local v901_ = operatingTime / 3600000
		local v902_ = math.floor(v901_)
		local v903_ = self.operatingTime / 3600000
		if math.floor(v903_) < v902_ then
			g_currentMission.economyManager:vehicleOperatingHourChanged(self)
		end
	end
	self.operatingTime = math.max(operatingTime or 0, 0)
end

function Vehicle:getOperatingTime()
	return self.operatingTime
end

-- Local values: ignoreCheck, hasMask, _, component
function Vehicle:doCollisionMaskCheck(targetCollisionMask, path, node, str)
	local v910_
	if path == nil then
		v910_ = false
	else
		v910_ = self.xmlFile:getValue(path, false)
	end
	if not v910_ then
		local v911_ = false
		if node == nil then
			for _, v912_ in ipairs(self.lists) do
				if not v911_ then
					local v913_ = getCollisionFilterMask(v912_.node)
					v911_ = bit32.band(v913_, targetCollisionMask) == targetCollisionMask
				end
			end
		elseif not v911_ then
			local v914_ = getCollisionFilterMask(node)
			v911_ = bit32.band(v914_, targetCollisionMask) == targetCollisionMask
		end
		if not v911_ then
			printCallstack()
			Logging.xmlWarning(self.xmlFile, "%s has wrong collision mask! Following bit(s) need to be set \'%s\' or use \'%s\'", str or self.typeName, MathUtil.numberToSetBitsStr(targetCollisionMask), path)
			return false
		end
	end
	return true
end

function Vehicle:getIsReadyForAutomatedTrainTravel()
	return true
end

function Vehicle:getIsAutomaticShiftingAllowed()
	return true
end

-- Local values: limit, doCheckSpeedLimit, damage, attachedImplements, _, implement, speed, implementDoCheckSpeedLimit
function Vehicle:getSpeedLimit(onlyIfWorking)
	local v917_ = self:doCheckSpeedLimit()
	local v918_
	if onlyIfWorking == nil or onlyIfWorking and v917_ then
		v918_ = self:getRawSpeedLimit()
		local v919_ = self:getVehicleDamage()
		if v919_ > 0 then
			v918_ = v918_ * (1 - v919_ * Vehicle.DAMAGED_SPEEDLIMIT_REDUCTION)
		end
	else
		v918_ = math.huge
	end
	local v920_
	if self.getAttachedImplements == nil then
		v920_ = nil
	else
		v920_ = self:getAttachedImplements()
	end
	if v920_ ~= nil then
		for _, v921_ in pairs(v920_) do
			if v921_.list ~= nil then
				local v922_, v923_ = v921_.list:getSpeedLimit(onlyIfWorking)
				if onlyIfWorking == nil or onlyIfWorking and v923_ then
					v918_ = math.min(v918_, v922_)
				end
				v917_ = v917_ or v923_
			end
		end
	end
	return v918_, v917_
end

function Vehicle:getRawSpeedLimit()
	return self.speedLimit
end

function Vehicle:onVehicleWakeUpCallback(id)
	self:raiseActive()
end

function Vehicle:getCanBeMounted()
	return entityExists(self.lists[1].node)
end

-- Local values: storeItem
function Vehicle:getDailyUpkeep()
	local v928_ = g_storeManager:getItemByXMLFilename(self.configFileName)
	return Vehicle.calculateDailyUpkeep(v928_, self.age, self.operatingTime, self.configurations)
end

-- Local values: multiplier, ageMultiplier, operatingTimeMultiplier
function Vehicle.calculateDailyUpkeep(storeItem, age, operatingTime, configurations)
	local v933_
	if storeItem.lifetime == nil or storeItem.lifetime == 0 then
		v933_ = 1
	else
		local v934_ = age / storeItem.lifetime
		local v935_ = 0.3 * math.min(v934_, 1)
		local v936_ = operatingTime / 3600000 / (storeItem.lifetime * EconomyManager.LIFETIME_OPERATINGTIME_RATIO)
		local v937_ = 0.7 * math.min(v936_, 1)
		v933_ = 1 + EconomyManager.MAX_DAILYUPKEEP_MULTIPLIER * (v935_ + v937_)
	end
	return StoreItemUtil.getDailyUpkeep(storeItem, configurations) * v933_
end

-- Local values: name
function Vehicle:getUppercaseName()
	local v939_ = self:getFullName()
	return utf8ToUpper(v939_)
end

-- Local values: storeItem, configName, _, configId, config
function Vehicle:getName()
	local v941_ = g_storeManager:getItemByXMLFilename(self.configFileName)
	if v941_ == nil then
		return "Unknown"
	end
	if v941_.configurations ~= nil then
		for v942_, _ in pairs(v941_.configurations) do
			local v943_ = self.configurations[v942_]
			local v944_ = v941_.configurations[v942_][v943_]
			if v944_.vehicleName ~= nil and v944_.vehicleName ~= "" then
				return v944_.vehicleName
			end
		end
	end
	return v941_.name
end

-- Local values: name, storeItem, brand
function Vehicle:getFullName()
	local v946_ = self:getName()
	if g_storeManager:getItemByXMLFilename(self.configFileName) ~= nil then
		local v947_ = g_brandManager:getBrandByIndex(self:getBrand())
		if v947_ ~= nil and v947_.name ~= "NONE" then
			v946_ = v947_.title .. " " .. v946_
		end
	end
	return v946_
end

-- Local values: storeItem, configName, _, configId, config
function Vehicle:getBrand()
	local v949_ = g_storeManager:getItemByXMLFilename(self.configFileName)
	if v949_ == nil then
		return Brand.LIZARD
	end
	if v949_.configurations ~= nil then
		for v950_, _ in pairs(v949_.configurations) do
			local v951_ = self.configurations[v950_]
			local v952_ = v949_.configurations[v950_][v951_]
			if v952_.vehicleBrand ~= nil then
				return v952_.vehicleBrand
			end
		end
	end
	return v949_.brandIndex
end

-- Local values: storeItem, configName, _, configId, config
function Vehicle:getImageFilename()
	local v954_ = g_storeManager:getItemByXMLFilename(self.configFileName)
	if v954_ == nil then
		return ShopController.EMPTY_FILENAME
	end
	if v954_.configurations ~= nil then
		for v955_, _ in pairs(v954_.configurations) do
			local v956_ = self.configurations[v955_]
			local v957_ = v954_.configurations[v955_][v956_]
			if v957_ == nil then
				Logging.xmlWarning(self.xmlFile, "Vehicle has an invalid configuration value %s for %s", v956_, v955_)
			elseif v957_.vehicleIcon ~= nil and v957_.vehicleIcon ~= "" then
				return v957_.vehicleIcon
			end
		end
	end
	return v954_.imageFilename
end

function Vehicle:getCanBePickedUp(byPlayer)
	local v960_ = self.supportsPickUp
	if v960_ then
		v960_ = g_currentMission.accessHandler:canPlayerAccess(self, byPlayer)
	end
	return v960_
end

function Vehicle:getCanBeReset()
	local v962_ = self.canBeReset
	if v962_ then
		v962_ = not g_guidedTourManager:getIsTourRunning()
	end
	return v962_
end

function Vehicle:getResetPlaces()
	return g_currentMission:getResetPlaces(), g_currentMission.usedLoadPlaces
end

-- Local values: storeItem
function Vehicle:getCanBeSold()
	local v964_ = g_storeManager:getItemByXMLFilename(self.configFileName)
	return v964_ == nil and true or v964_.canBeSold
end

function Vehicle:getCanBeAddedToSales()
	return true
end

-- Local values: vehicleXMLFile, key
function Vehicle:getReloadXML()
	local v966_ = XMLFile.create("vehicleXMLFile", "", "vehicles", Vehicle.xmlSchemaSavegame)
	if v966_ == nil then
		return nil
	end
	local v967_ = string.format("vehicles.vehicle(%d)", 0)
	v966_:setValue(v967_ .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.configFileName)))
	self:saveToXMLFile(v966_, v967_, {})
	return v966_
end

function Vehicle:getIsInUse(connection)
	return false
end

function Vehicle:getPropertyState()
	return self.propertyState
end

function Vehicle:getAreControlledActionsAvailable()
	if self:getIsAIActive() then
		return false
	elseif self.actionController == nil then
		return false
	else
		return self.actionController:getAreControlledActionsAvailable()
	end
end

function Vehicle:getAreControlledActionsAccessible()
	if self:getIsAIActive() then
		return false
	elseif self.actionController == nil then
		return false
	else
		return self.actionController:getAreControlledActionsAccessible()
	end
end

-- Local values: iconPos, iconNeg, changeColor
function Vehicle:getControlledActionIcons()
	if self.actionController ~= nil then
		local v972_, v973_, v974_ = self.actionController:getControlledActionIcons()
		if v972_ ~= nil then
			return v972_, v973_, v974_
		end
	end
	return "TURN_ON", "TURN_ON", true
end

function Vehicle:getAreControlledActionsAllowed()
	return not self:getIsAIActive(), ""
end

function Vehicle:playControlledActions()
	if self.actionController ~= nil then
		self.actionController:playControlledActions()
	end
end

function Vehicle:getActionControllerDirection()
	return self.actionController == nil and 1 or self.actionController:getActionControllerDirection()
end

-- Local values: mapHotspot
function Vehicle:createMapHotspot()
	local v979_ = VehicleHotspot.new()
	v979_:setVehicle(self)
	v979_:setVehicleType(self.mapHotspotType)
	v979_:setOwnerFarmId(self:getOwnerFarmId())
	self.mapHotspot = v979_
	g_currentMission:addMapHotspot(v979_)
end

function Vehicle:deleteMapHotspot()
	if self.mapHotspot ~= nil then
		g_currentMission:removeMapHotspot(self.mapHotspot)
		self.mapHotspot:delete()
		self.mapHotspot = nil
	end
end

function Vehicle:getMapHotspot()
	return self.mapHotspot
end

function Vehicle:updateMapHotspot()
	if self.mapHotspot ~= nil then
		self.mapHotspot:setVisible(self:getIsMapHotspotVisible())
	end
end

function Vehicle:getIsMapHotspotVisible()
	return true
end

-- Local values: dx, _, dz
function Vehicle:getMapHotspotRotation(isPlayerHotspot)
	local v984_, _, v985_ = localDirectionToWorld(self.directionReferenceNode or self.rootNode, 0, 0, 1)
	return MathUtil.getYRotationFromDirection(v984_, v985_) + 3.141592653589793
end

function Vehicle:getMapHotspotPosition()
	return getWorldTranslation(self.rootNode)
end

function Vehicle:getShowInVehiclesOverview()
	local v988_ = self.showInVehicleOverview
	if v988_ then
		v988_ = self.propertyState == VehiclePropertyState.OWNED and true or self.propertyState == VehiclePropertyState.LEASED
	end
	return v988_
end

function Vehicle:showInfo(box)
	if self.isBroken then
		box:addLine(g_i18n:getText("infohud_vehicleBrokenNeedToReset"), nil, true)
	end
end

function Vehicle:loadObjectChangeValuesFromXML(xmlFile, key, node, object) end

function Vehicle:setObjectChangeValues(object, isActive) end

function Vehicle:wakeUp()
	I3DUtil.wakeUpObject(self.connections[1].node)
end

function Vehicle:register(alreadySent)
	Vehicle:superClass().register(self, alreadySent)
	SpecializationUtil.raiseEvent(self, "onRegistered", alreadySent)
end

function Vehicle:clearDirtyMask()
	self.dirtyMask = 0
	SpecializationUtil.raiseEvent(self, "onDirtyMaskCleared")
end

function Vehicle:setOwnerFarmId(farmId, noEventSend)
	Vehicle:superClass().setOwnerFarmId(self, farmId, noEventSend)
	if self.mapHotspot ~= nil then
		self.mapHotspot:setOwnerFarmId(farmId)
	end
end

function Vehicle:getUniqueId()
	return self.uniqueId
end

function Vehicle:setUniqueId(uniqueId)
	self.uniqueId = uniqueId
end

-- Local values: currentSelection, currentObject, currentObjectIndex, currentSubObjectIndex, numSubSelections, newSelectedSubObjectIndex, newSelectedObjectIndex, newSelectedObject
function Vehicle:actionEventToggleSelection(actionName, inputValue, callbackState, isAnalog)
	local v1002_ = self.currentSelection
	local v1003_ = v1002_.connection
	local v1004_ = v1002_.index
	local v1005_ = v1002_.subIndex
	local v1006_ = v1003_ == nil and 0 or #v1003_.subSelections
	local v1007_ = v1005_ + 1
	local v1008_, v1009_
	if v1006_ < v1007_ then
		local v1010_ = v1004_ + 1
		v1008_ = #self.selectableObjects < v1010_ and 1 or v1010_
		v1009_ = self.selectableObjects[v1008_]
		v1007_ = 1
	else
		v1008_ = v1004_
		v1009_ = v1003_
	end
	if v1003_ ~= v1009_ or (v1004_ ~= v1008_ or v1005_ ~= v1007_) then
		self:setSelectedObject(v1009_, v1007_)
	end
end

-- Local values: currentSelection, currentObject, currentObjectIndex, currentSubObjectIndex, newSelectedSubObjectIndex, newSelectedObjectIndex, newSelectedObject
function Vehicle:actionEventToggleSelectionReverse(actionName, inputValue, callbackState, isAnalog)
	local v1012_ = self.currentSelection
	local v1013_ = v1012_.connection
	local v1014_ = v1012_.index
	local v1015_ = v1012_.subIndex
	local v1016_ = v1015_ - 1
	local v1017_, v1018_
	if v1016_ < 1 then
		local v1019_ = v1014_ - 1
		v1017_ = v1019_ < 1 and #self.selectableObjects or v1019_
		v1018_ = self.selectableObjects[v1017_]
		if v1018_ == nil then
			v1016_ = 1
		else
			v1016_ = #v1018_.subSelections
		end
	else
		v1017_ = v1014_
		v1018_ = v1013_
	end
	if v1013_ ~= v1018_ or (v1014_ ~= v1017_ or v1015_ ~= v1016_) then
		self:setSelectedObject(v1018_, v1016_)
	end
end

function Vehicle.getSpecValueAge(storeItem, realItem, _, saleItem)
	if realItem == nil or realItem.age == nil then
		if saleItem == nil or saleItem.age == nil then
			return nil
		else
			return g_i18n:formatNumMonth(saleItem.age)
		end
	else
		return g_i18n:formatNumMonth(realItem.age)
	end
end

-- Local values: dailyUpkeep
function Vehicle.getSpecValueDailyUpkeep(storeItem, realItem, _, saleItem)
	local v1025_ = storeItem.dailyUpkeep
	local v1026_
	if realItem == nil or realItem.getDailyUpkeep == nil then
		v1026_ = saleItem ~= nil and 0 or v1025_
	else
		v1026_ = realItem:getDailyUpkeep()
	end
	if v1026_ == 0 then
		return nil
	else
		return string.format(g_i18n:getText("shop_maintenanceValue"), g_i18n:formatMoney(v1026_, 2))
	end
end

-- Local values: operatingTime, minutes, hours
function Vehicle.getSpecValueOperatingTime(storeItem, realItem, _, saleItem)
	local v1029_
	if realItem == nil or realItem.operatingTime == nil then
		if saleItem == nil then
			return nil
		end
		v1029_ = saleItem.operatingTime
	else
		v1029_ = realItem.operatingTime
	end
	local v1030_ = v1029_ / 60000
	local v1031_ = v1030_ / 60
	local v1032_ = math.floor(v1031_)
	local v1033_ = (v1030_ - v1032_ * 60) / 6
	local v1034_ = math.floor(v1033_)
	return string.format(g_i18n:getText("shop_operatingTime"), v1032_, v1034_)
end

-- Local values: width, minWidth
function Vehicle.loadSpecValueWorkingWidth(xmlFile, customEnvironment, baseDir)
	local v1036_ = xmlFile:getValue("vehicle.storeData.specs.workingWidth")
	return v1036_ ~= nil and {
		["width"] = v1036_,
		["minWidth"] = xmlFile:getValue("vehicle.storeData.specs.workingWidth#minWidth", v1036_)
	} or nil
end

-- Local values: workingWidth
function Vehicle.getSpecValueWorkingWidth(storeItem, realItem)
	if storeItem.specs.workingWidth == nil then
		return nil
	else
		local v1038_ = storeItem.specs.workingWidth
		if v1038_.minWidth == v1038_.width then
			return string.format(g_i18n:getText("shop_workingWidthValue"), g_i18n:formatNumber(v1038_.width, 1, true))
		else
			return string.format(g_i18n:getText("shop_workingWidthValue"), string.format("%s-%s", g_i18n:formatNumber(v1038_.minWidth, 1, true), g_i18n:formatNumber(v1038_.width, 1, true)))
		end
	end
end

-- Local values: workingWidths, name, configDesc, configurationIndex, configurationKey, workingWidth
function Vehicle.loadSpecValueWorkingWidthConfig(xmlFile, customEnvironment, baseDir)
	local v1040_ = nil
	for v1041_, v1042_ in pairs(g_vehicleConfigurationManager:getConfigurations()) do
		for v1043_, v1044_ in xmlFile:iterator(v1042_.configurationKey) do
			local v1045_ = xmlFile:getValue(v1044_ .. "#workingWidth")
			if v1045_ ~= nil then
				v1040_ = v1040_ or {}
				v1040_[v1041_] = v1040_[v1041_] or {}
				v1040_[v1041_][v1043_] = {
					["width"] = v1045_,
					["isSelectable"] = xmlFile:getValue(v1044_ .. "#isSelectable", true)
				}
			end
		end
	end
	return v1040_
end

-- Local values: minWorkingWidth, workingWidth, configName, config, configData, minWidth, maxWidth, configName, configs, _, configData
function Vehicle.getSpecValueWorkingWidthConfig(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	if storeItem.specs.workingWidthConfig == nil then
		return nil
	else
		local v1051_ = 0
		local v1052_ = 0
		if configurations == nil or realItem == nil and saleItem == nil then
			v1051_ = math.huge
			v1052_ = 0
			for _, v1053_ in pairs(storeItem.specs.workingWidthConfig) do
				for _, v1054_ in pairs(v1053_) do
					if v1054_.isSelectable then
						local v1055_ = v1054_.width
						v1051_ = math.min(v1051_, v1055_)
						local v1056_ = v1054_.width
						v1052_ = math.max(v1052_, v1056_)
					end
				end
			end
		else
			for v1057_, v1058_ in pairs(configurations) do
				if storeItem.specs.workingWidthConfig[v1057_] ~= nil then
					local v1059_ = storeItem.specs.workingWidthConfig[v1057_][v1058_]
					if v1059_ ~= nil then
						v1052_ = v1059_.width
					end
				end
			end
		end
		if returnValues then
			return v1052_
		elseif v1051_ == 0 or (v1051_ == math.huge or v1051_ == v1052_) then
			return string.format(g_i18n:getText("shop_workingWidthValue"), g_i18n:formatNumber(v1052_, 1, true))
		else
			return string.format(g_i18n:getText("shop_workingWidthValue"), string.format("%s-%s", g_i18n:formatNumber(v1051_, 1, true), g_i18n:formatNumber(v1052_, 1, true)))
		end
	end
end

function Vehicle.loadSpecValueSpeedLimit(xmlFile, customEnvironment, baseDir)
	return xmlFile:getValue("vehicle.base.speedLimit#value")
end

function Vehicle.getSpecValueSpeedLimit(storeItem, realItem)
	if storeItem.specs.speedLimit == nil then
		return nil
	else
		return string.format(g_i18n:getText("shop_maxSpeed"), string.format("%1d", g_i18n:getSpeed(storeItem.specs.speedLimit)), g_i18n:getSpeedMeasuringUnit())
	end
end

-- Local values: massData, _, key, mass, hasConfigMass, configIndex, configKey, configMass, _, componentKey, mass, configMin, configMax, _, key, config
function Vehicle.loadSpecValueWeight(xmlFile, customEnvironment, baseDir)
	local v1065_ = {
		["connectionMass"] = 0
	}
	for _, v1066_ in xmlFile:iterator("vehicle.base.connections.connection") do
		local v1067_ = xmlFile:getValue(v1066_ .. "#mass", 0) / 1000
		v1065_.connectionMass = v1065_.connectionMass + v1067_
	end
	v1065_.configurations = {}
	local v1068_ = false
	for v1069_, v1070_ in xmlFile:iterator("vehicle.base.connectionConfigurations.connectionConfiguration") do
		local v1071_ = 0
		for _, v1072_ in xmlFile:iterator(v1070_ .. ".connection") do
			v1071_ = v1071_ + xmlFile:getValue(v1072_ .. "#mass", 0) / 1000
			v1068_ = true
		end
		v1065_.configurations[v1069_] = v1071_
	end
	v1065_.fillUnitMassData = FillUnit.loadSpecValueFillUnitMassData(xmlFile, customEnvironment, baseDir)
	v1065_.wheelMassDefaultConfig = Wheels.loadSpecValueWheelWeight(xmlFile, customEnvironment, baseDir)
	v1065_.storeDataConfigs = {}
	local v1073_ = nil
	local v1074_ = nil
	for _, v1075_ in xmlFile:iterator("vehicle.storeData.specs.weight.config") do
		local v1076_ = {
			["name"] = xmlFile:getValue(v1075_ .. "#name")
		}
		if v1076_.name ~= nil then
			v1076_.index = xmlFile:getValue(v1075_ .. "#index", 1)
			v1076_.value = xmlFile:getValue(v1075_ .. "#value", 0) / 1000
			local v1077_ = v1076_.value * 1000
			v1073_ = math.min(v1073_ or math.huge, v1077_)
			local v1078_ = v1076_.value * 1000
			v1074_ = math.max(v1074_ or -math.huge, v1078_)
			local v1079_ = v1065_.storeDataConfigs
			table.insert(v1079_, v1076_)
		end
	end
	if #v1065_.storeDataConfigs == 0 then
		v1065_.storeDataConfigs = nil
	end
	if not xmlFile:getValue("vehicle.storeData.specs.weight#ignore", false) then
		v1065_.storeDataMin = xmlFile:getValue("vehicle.storeData.specs.weight#minValue", v1073_)
		v1065_.storeDataMax = xmlFile:getValue("vehicle.storeData.specs.weight#maxValue", v1074_)
		if v1065_.connectionMass > 0 or (v1068_ or v1065_.storeDataMin ~= nil) then
			return v1065_
		end
	end
	return nil
end

function Vehicle.getSpecConfigValuesWeight(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	if storeItem.specs.weight == nil or storeItem.specs.weight.storeDataConfigs == nil then
		return nil
	else
		return storeItem.specs.weight.storeDataConfigs
	end
end

-- Local values: vehicleMass, vehicleMassMax
function Vehicle.getSpecValueWeight(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	if storeItem.specs.weight ~= nil then
		local v1086_ = nil
		local v1087_ = nil
		if realItem == nil then
			if storeItem.specs.weight.storeDataMin == nil then
				if storeItem.specs.weight.connectionMass ~= nil then
					if configurations ~= nil and configurations.connection ~= nil then
						v1086_ = storeItem.specs.weight.configurations[configurations.connection]
					end
					if v1086_ == nil then
						v1086_ = storeItem.specs.weight.connectionMass
					end
					v1086_ = v1086_ + (storeItem.specs.weight.wheelMassDefaultConfig or 0) + FillUnit.getSpecValueStartFillUnitMassByMassData(storeItem.specs.weight.fillUnitMassData)
				end
			else
				v1086_ = (storeItem.specs.weight.storeDataMin or 0) / 1000
				v1087_ = (storeItem.specs.weight.storeDataMax or 0) / 1000
			end
		else
			realItem:updateMass()
			v1086_ = realItem:getTotalMass(true)
		end
		if v1086_ ~= nil and v1086_ ~= 0 then
			if returnValues then
				if returnRange then
					return v1086_, v1087_
				else
					return v1086_
				end
			elseif v1087_ == nil or v1087_ == 0 then
				return g_i18n:formatMass(v1086_)
			else
				return g_i18n:formatMass(v1086_, v1087_)
			end
		end
	end
	return nil
end

-- Local values: maxWeight
function Vehicle.loadSpecValueAdditionalWeight(xmlFile, customEnvironment, baseDir)
	local v1089_ = xmlFile:getValue("vehicle.base.connections#maxMass")
	if v1089_ == nil then
		return nil
	else
		return v1089_ / 1000
	end
end

-- Local values: baseWeight, additionalWeight
function Vehicle.getSpecValueAdditionalWeight(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	if not g_currentMission.missionInfo.trailerFillLimit then
		return nil
	end
	if storeItem.specs.additionalWeight ~= nil then
		local v1095_ = Vehicle.getSpecValueWeight(storeItem, realItem, configurations, saleItem, true)
		if v1095_ ~= nil then
			local v1096_ = storeItem.specs.additionalWeight - v1095_
			if returnValues then
				return v1096_
			else
				return g_i18n:formatMass(v1096_)
			end
		end
	end
	return nil
end

-- Local values: combinations
function Vehicle.loadSpecValueCombinations(xmlFile, customEnvironment, baseDirectory)
	local v_u_1099_ = {}
	xmlFile:iterate("vehicle.storeData.specs.combination", function(_, p1100_)
		-- upvalues: (copy) xmlFile, (copy) baseDirectory, (copy) v_u_1099_
		local v1101_ = {}
		local v1102_ = xmlFile:getValue(p1100_ .. "#xmlFilename")
		if v1102_ ~= nil then
			v1101_.xmlFilename = Utils.getFilename(v1102_)
			v1101_.customXMLFilename = Utils.getFilename(v1102_, baseDirectory)
			local v1103_ = g_storeManager:getItemByXMLFilename(v1101_.customXMLFilename)
			if v1103_ == nil then
				v1103_ = g_storeManager:getItemByXMLFilename(v1101_.xmlFilename)
			end
			if v1103_ == nil then
				Logging.xmlWarning(xmlFile, "Could not find combination vehicle \'%s\'", v1101_.xmlFilename)
			end
		end
		local v1104_ = xmlFile:getValue(p1100_ .. "#filterCategory")
		if v1104_ ~= nil then
			v1101_.filterCategories = v1104_:split(" ")
		end
		v1101_.filterSpec = xmlFile:getValue(p1100_ .. "#filterSpec")
		v1101_.filterSpecMin = xmlFile:getValue(p1100_ .. "#filterSpecMin", 0)
		v1101_.filterSpecMax = xmlFile:getValue(p1100_ .. "#filterSpecMax", 1)
		if v1101_.xmlFilename ~= nil or (v1101_.filterCategories ~= nil or v1101_.filterSpec) then
			local v1105_ = v_u_1099_
			table.insert(v1105_, v1101_)
		end
	end)
	return v_u_1099_
end

function Vehicle.getSpecValueCombinations(storeItem, realItem)
	return storeItem.specs.combinations
end

-- Local values: numOwned, valueText, sellSlotUsage, buySlotUsage, i, bundleInfo, numBundleItemOwned, usage
function Vehicle.getSpecValueSlots(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	local v1109_ = g_currentMission:getNumOfItems(storeItem)
	local v1110_ = ""
	if realItem == nil then
		local v1111_ = g_currentMission.slotSystem:getStoreItemSlotUsage(storeItem, v1109_ == 0)
		if storeItem.bundleInfo ~= nil then
			v1111_ = 0
			for v1112_ = 1, #storeItem.bundleInfo.bundleItems do
				local v1113_ = storeItem.bundleInfo.bundleItems[v1112_]
				local v1114_ = g_currentMission:getNumOfItems(v1113_.item)
				v1111_ = v1111_ + g_currentMission.slotSystem:getStoreItemSlotUsage(v1113_.item, v1114_ == 0)
			end
		end
		if v1111_ ~= 0 then
			v1110_ = "+" .. v1111_
		end
	else
		local v1115_ = g_currentMission.slotSystem:getStoreItemSlotUsage(storeItem, v1109_ == 1)
		if v1115_ ~= 0 then
			v1110_ = "-" .. v1115_
		end
	end
	if v1110_ == "" then
		return nil
	else
		return v1110_
	end
end
