source("dataS/scripts/vehicles/specializations/events/BaleLoaderStateEvent.lua")
BaleLoader = {}

function BaleLoader.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(FillUnit, specializations)
end
function BaleLoader.initSpecialization()
	g_storeManager:addSpecType("baleLoaderBaleSizeRound", "shopListAttributeIconBaleSizeRound", BaleLoader.loadSpecValueBaleSizeRound, BaleLoader.getSpecValueBaleSizeRound, StoreSpecies.VEHICLE)
	g_storeManager:addSpecType("baleLoaderBaleSizeSquare", "shopListAttributeIconBaleSizeSquare", BaleLoader.loadSpecValueBaleSizeSquare, BaleLoader.getSpecValueBaleSizeSquare, StoreSpecies.VEHICLE)
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("BaleLoader")
	v2_:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#transportPosition", "Transport position text", "action_baleloaderTransportPosition")
	v2_:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#operatingPosition", "Operating position text", "action_baleloaderOperatingPosition")
	v2_:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#unload", "Unload text", "action_baleloaderUnload")
	v2_:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#tilting", "Tilting text", "info_baleloaderTiltingTable")
	v2_:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#lowering", "Lowering text", "info_baleloaderLoweringTable")
	v2_:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#lowerPlattform", "Lower platform text", "action_baleloaderLowerPlatform")
	v2_:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#abortUnloading", "Abort unloading text", "action_baleloaderAbortUnloading")
	v2_:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#unloadHere", "Unload here text", "action_baleloaderUnloadHere")
	v2_:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#baleNotSupported", "Bale not supported warning", "warning_baleNotSupported")
	v2_:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#baleDoNotAllowFillTypeMixing", "Warning to be shown if the fill type is different from loaded fill types", "warning_baleDoNotAllowFillTypeMixing")
	v2_:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#onlyOneBaleTypeWarning", "Warning to be shown if user tries to collect a different bale type as already loaded", "warning_baleLoaderOnlyAllowOnceSize")
	v2_:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#minUnloadingFillLevelWarning", "Warning to be displayed if min fill level is not reached", "warning_baleLoaderNotFullyLoaded")
	BaleLoader.registerAnimationXMLPaths(v2_, "vehicle.baleLoader")
	v2_:register(XMLValueType.BOOL, "vehicle.baleLoader#transportPositionAfterUnloading", "Activate transport mode after unloading", true)
	v2_:register(XMLValueType.BOOL, "vehicle.baleLoader#useFoldingState", "Use folding state for activation and deactivation", false)
	v2_:register(XMLValueType.BOOL, "vehicle.baleLoader#useBalePlaceAsLoadPosition", "Use bale place position as load position", false)
	v2_:register(XMLValueType.FLOAT, "vehicle.baleLoader#balePlaceOffset", "Bale place offset", 0)
	v2_:register(XMLValueType.BOOL, "vehicle.baleLoader#keepBaleRotationDuringLoad", "Keep the same bale rotation while loading bale", false)
	v2_:register(XMLValueType.BOOL, "vehicle.baleLoader#automaticUnloading", "Automatically unload the bale loader if platform lifted", false)
	v2_:register(XMLValueType.BOOL, "vehicle.baleLoader#fullAutomaticUnloading", "Automatically unload the bale loader when getting full", false)
	v2_:register(XMLValueType.INT, "vehicle.baleLoader#minUnloadingFillLevel", "Min. fill level until unloading is allowed", 1)
	v2_:register(XMLValueType.BOOL, "vehicle.baleLoader#allowKinematicMounting", "Kinematic mounting of bale is allow (= bales still have collision while loaded)", true)
	v2_:register(XMLValueType.BOOL, "vehicle.baleLoader#consumePtoPower", "Defines if the bale loader consumes pto power while in work mode", true)
	v2_:register(XMLValueType.BOOL, "vehicle.baleLoader.dynamicMount#enabled", "Bales are dynamically mounted", false)
	v2_:register(XMLValueType.BOOL, "vehicle.baleLoader.dynamicMount#doInterpolation", "Bale position is interpolated from bale origin position to grabber position", false)
	v2_:register(XMLValueType.TIME, "vehicle.baleLoader.dynamicMount#interpolationTimeRot", "Time for bale rotation interpolation", 1)
	v2_:register(XMLValueType.FLOAT, "vehicle.baleLoader.dynamicMount#interpolationSpeedTrans", "Speed of translation interpolation (m/sec)", 0.1)
	v2_:register(XMLValueType.VECTOR_TRANS, "vehicle.baleLoader.dynamicMount#minTransLimits", "Min translation limit")
	v2_:register(XMLValueType.VECTOR_TRANS, "vehicle.baleLoader.dynamicMount#maxTransLimits", "Max translation limit")
	v2_:register(XMLValueType.BOOL, "vehicle.baleLoader.dynamicBaleUnloading#enabled", "Bales are joint together during unloading")
	v2_:register(XMLValueType.VECTOR_N, "vehicle.baleLoader.dynamicBaleUnloading#connectedRows", "Indices of rows that are connected together")
	v2_:register(XMLValueType.STRING, "vehicle.baleLoader.dynamicBaleUnloading#interConnectedRowStarts", "Interconnections at row start between rows (e.g. \'1-2 3-4\')")
	v2_:register(XMLValueType.STRING, "vehicle.baleLoader.dynamicBaleUnloading#interConnectedRowEnds", "Interconnections at row ends between rows (e.g. \'1-2 3-4\')")
	v2_:register(XMLValueType.FLOAT, "vehicle.baleLoader.dynamicBaleUnloading#widthOffset", "Width offset")
	v2_:register(XMLValueType.FLOAT, "vehicle.baleLoader.dynamicBaleUnloading#heightOffset", "Height offset")
	v2_:register(XMLValueType.FLOAT, "vehicle.baleLoader.dynamicBaleUnloading#diameterOffset", "Diameter offset")
	v2_:register(XMLValueType.ANGLE, "vehicle.baleLoader.dynamicBaleUnloading#rowConnectionRotLimit", "Rotation limit for row joints")
	v2_:register(XMLValueType.ANGLE, "vehicle.baleLoader.dynamicBaleUnloading#rowInterConnectionRotLimit", "Rotation limit for inter row joints")
	v2_:register(XMLValueType.STRING, "vehicle.baleLoader.dynamicBaleUnloading.releaseAnimation#name", "Reference animation to remove joints")
	v2_:register(XMLValueType.FLOAT, "vehicle.baleLoader.dynamicBaleUnloading.releaseAnimation#time", "If animation time is higher than this time the joints will be removed", 1)
	v2_:register(XMLValueType.BOOL, "vehicle.baleLoader.dynamicBaleUnloading.releaseAnimation#useUnloadingMoverTrigger", "Bale joints will be removed as soon all bales hast left the unloading mover trigger", false)
	v2_:register(XMLValueType.INT, "vehicle.baleLoader#fillUnitIndex", "Fill unit index", 1)
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.baleLoader.grabber#grabNode", "Grab node")
	v2_:register(XMLValueType.FLOAT, "vehicle.baleLoader.grabber#pickupRange", "Pickup range", 3)
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.baleLoader.grabber#triggerNode", "Trigger node")
	EffectManager.registerEffectXMLPaths(v2_, "vehicle.baleLoader.grabber")
	v2_:register(XMLValueType.TIME, "vehicle.baleLoader.grabber#effectDisableDuration", "Disable duration", 0.6)
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.baleLoader.balePlaces#startBalePlace", "Start bale place node")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.baleLoader.balePlaces.balePlace(?)#node", "Bale place node")
	v2_:register(XMLValueType.STRING, "vehicle.baleLoader.foldingAnimations#baseAnimation", "Base animation name", "baleGrabberTransportToWork")
	v2_:register(XMLValueType.STRING, "vehicle.baleLoader.foldingAnimations.foldingAnimation(?)#name", "Animation name")
	v2_:register(XMLValueType.INT, "vehicle.baleLoader.foldingAnimations.foldingAnimation(?)#baleTypeIndex", "Index of current bale type", "\'0\' - any bale type")
	v2_:register(XMLValueType.FLOAT, "vehicle.baleLoader.foldingAnimations.foldingAnimation(?)#minFillLevel", "Min. fill level to use this animation", "-inf")
	v2_:register(XMLValueType.FLOAT, "vehicle.baleLoader.foldingAnimations.foldingAnimation(?)#maxFillLevel", "Max. fill level to use this animation", "inf")
	v2_:register(XMLValueType.FLOAT, "vehicle.baleLoader.foldingAnimations.foldingAnimation(?)#minBalePlace", "Min. bales on platform to use this animation", "-inf")
	v2_:register(XMLValueType.FLOAT, "vehicle.baleLoader.foldingAnimations.foldingAnimation(?)#maxBalePlace", "Max. bales on platform to use this animation", "inf")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.baleLoader.unloadingMoverNodes#trigger", "As long as bales are in this trigger the mover nodes are active and the player can not lower the platform")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.baleLoader.unloadingMoverNodes.unloadingMoverNode(?)#node", "Node that moves bales")
	v2_:register(XMLValueType.FLOAT, "vehicle.baleLoader.unloadingMoverNodes.unloadingMoverNode(?)#speed", "Defines direction and speed of moving in X direction", -1)
	AnimationManager.registerAnimationNodesXMLPaths(v2_, "vehicle.baleLoader.unloadingMoverNodes.animationNodes")
	v2_:register(XMLValueType.INT, "vehicle.baleLoader.synchronization#numBitsPosition", "Number of bits to synchronize bale positions", 10)
	v2_:register(XMLValueType.FLOAT, "vehicle.baleLoader.synchronization#maxPosition", "Max. position offset of bales from bale place in meter", 3)
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.baleLoader.sounds", "grab")
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.baleLoader.sounds", "emptyRotate")
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.baleLoader.sounds", "work")
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.baleLoader.sounds", "unload")
	v2_:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#diameter", "Bale diameter")
	v2_:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#width", "Bale width")
	v2_:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#height", "Bale height")
	v2_:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#length", "Bale length")
	v2_:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#minDiameter", "Bale min diameter", "diameter value")
	v2_:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#maxDiameter", "Bale max diameter", "diameter value")
	v2_:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#minWidth", "Bale min width", "width value")
	v2_:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#maxWidth", "Bale max width", "width value")
	v2_:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#minHeight", "Bale min height", "height value")
	v2_:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#maxHeight", "Bale max height", "height value")
	v2_:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#minLength", "Bale min length", "length value")
	v2_:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#maxLength", "Bale max length", "length value")
	v2_:register(XMLValueType.INT, "vehicle.baleLoader.baleTypes.baleType(?)#fillUnitIndex", "Fill unit index", "baleLoader#fillUnitIndex")
	v2_:register(XMLValueType.BOOL, "vehicle.baleLoader.baleTypes.baleType(?)#mixedFillTypes", "Allow loading of mixed fill types", true)
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.baleLoader.baleTypes.baleType(?).balePlaces#startBalePlace", "Start bale place node")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.baleLoader.baleTypes.baleType(?).balePlaces.balePlace(?)#node", "Bale place node")
	ObjectChangeUtil.registerObjectChangeXMLPaths(v2_, "vehicle.baleLoader.baleTypes.baleType(?)")
	BaleLoader.registerAnimationXMLPaths(v2_, "vehicle.baleLoader.baleTypes.baleType(?)")
	AnimationManager.registerAnimationNodesXMLPaths(v2_, "vehicle.baleLoader.animationNodes")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.baleLoader.balePacker#node", "Node where to create the packed bale")
	v2_:register(XMLValueType.STRING, "vehicle.baleLoader.balePacker#packedFilename", "Filename to packed bale")
	v2_:addDelayedRegistrationFunc("AnimatedVehicle:part", function(p3_, p4_)
		p3_:register(XMLValueType.BOOL, p4_ .. "#baleLoaderAnimationNodes", "Bale Loader animation nodes turn on/off")
	end)
	v2_:setXMLSpecializationType()
	local v5_ = Vehicle.xmlSchemaSavegame
	v5_:register(XMLValueType.STRING, "vehicles.vehicle(?).baleLoader#lastFoldingAnimation", "Last folding animation name")
	v5_:register(XMLValueType.INT, "vehicles.vehicle(?).baleLoader#baleTypeIndex", "Last bale type index")
	v5_:register(XMLValueType.BOOL, "vehicles.vehicle(?).baleLoader#isInWorkPosition", "Is in working Position")
	v5_:register(XMLValueType.STRING, "vehicles.vehicle(?).baleLoader.bale(?)#filename", "Filename")
	v5_:register(XMLValueType.VECTOR_TRANS, "vehicles.vehicle(?).baleLoader.bale(?)#position", "Position")
	v5_:register(XMLValueType.VECTOR_ROT, "vehicles.vehicle(?).baleLoader.bale(?)#rotation", "Rotation")
	v5_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).baleLoader.bale(?)#fillLevel", "Filllevel")
	v5_:register(XMLValueType.INT, "vehicles.vehicle(?).baleLoader.bale(?)#balePlace", "Bale place index")
	v5_:register(XMLValueType.INT, "vehicles.vehicle(?).baleLoader.bale(?)#helper", "Helper index")
	v5_:register(XMLValueType.INT, "vehicles.vehicle(?).baleLoader.bale(?)#farmId", "Farm index")
	Bale.registerSavegameXMLPaths(v5_, "vehicles.vehicle(?).baleLoader.bale(?)")
end

function BaleLoader.registerAnimationXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".animations.platform#rotate", "Rotate platform animation name", "rotatePlatform")
	schema:register(XMLValueType.STRING, basePath .. ".animations.platform#rotateBack", "Rotate platform back animation name", "rotatePlatform")
	schema:register(XMLValueType.STRING, basePath .. ".animations.platform#rotateEmpty", "Rotate platform empty animation name", "rotatePlatform")
	schema:register(XMLValueType.BOOL, basePath .. ".animations.platform#allowPickupWhileMoving", "Allow pickup of next bale while platform is rotating", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".animations.baleGrabber#dropBaleReverseSpeed", "Speed of grabber in reverse", 5)
	schema:register(XMLValueType.STRING, basePath .. ".animations.baleGrabber#dropToWork", "Custom grabber animation when moving from drop to work")
	schema:register(XMLValueType.STRING, basePath .. ".animations.baleGrabber#workToDrop", "Bale grabber work to drop animation", "baleGrabberWorkToDrop")
	schema:register(XMLValueType.STRING, basePath .. ".animations.baleGrabber#dropBale", "Bale grabber drop bale animation", "baleGrabberDropBale")
	schema:register(XMLValueType.STRING, basePath .. ".animations.baleGrabber#transportToWork", "Transport to work animation", "baleGrabberTransportToWork")
	schema:register(XMLValueType.STRING, basePath .. ".animations.pusher#emptyHide", "Empty hide animation", "emptyHidePusher1")
	schema:register(XMLValueType.STRING, basePath .. ".animations.pusher#moveToEmpty", "Move to empty position", "moveBalePusherToEmpty")
	schema:register(XMLValueType.BOOL, basePath .. ".animations.pusher#hidePusherOnEmpty", "Reverse move to empty animation after execution", true)
	schema:register(XMLValueType.BOOL, basePath .. ".animations.pusher#pushBalesOnEmpty", "Defines if bale are pushed or pulled on empty", false)
	schema:register(XMLValueType.STRING, basePath .. ".animations.releaseFrontPlatform#name", "Release front platform animation name", "releaseFrontplattform")
	schema:register(XMLValueType.BOOL, basePath .. ".animations.releaseFrontPlatform#fillLevelSpeed", "Front platform speed is dependent on fill level", false)
	schema:register(XMLValueType.STRING, basePath .. ".animations.moveBalePlaces#name", "Move bale places animation", "moveBalePlaces")
	schema:register(XMLValueType.STRING, basePath .. ".animations.moveBalePlaces#extrasOnce", "Move bale places extra once animation", "moveBalePlaces")
	schema:register(XMLValueType.STRING, basePath .. ".animations.moveBalePlaces#empty", "Move bale places empty animation", "moveBalePlaces")
	schema:register(XMLValueType.FLOAT, basePath .. ".animations.moveBalePlaces#emptySpeed", "Speed of move bale places to empty", 1.5)
	schema:register(XMLValueType.FLOAT, basePath .. ".animations.moveBalePlaces#emptyReverseSpeed", "Reverse speed of move bale places to empty", -1)
	schema:register(XMLValueType.FLOAT, basePath .. ".animations.moveBalePlaces#pushOffset", "Delay of empty animation to give pusher time to move to the last bale", 0)
	schema:register(XMLValueType.BOOL, basePath .. ".animations.moveBalePlaces#moveAfterRotatePlatform", "Move bale places after rotate platform", false)
	schema:register(XMLValueType.BOOL, basePath .. ".animations.moveBalePlaces#resetOnSink", "Reset move bale places on platform sink", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".animations.moveBalePlaces#maxGrabberTime", "Max. grabber time to move bale places", "inf")
	schema:register(XMLValueType.BOOL, basePath .. ".animations.moveBalePlaces#alwaysMove", "Always move bale places", false)
	schema:register(XMLValueType.STRING, basePath .. ".animations.emptyRotate#name", "Empty rotate", "emptyRotate")
	schema:register(XMLValueType.BOOL, basePath .. ".animations.emptyRotate#reset", "Reset empty rotate animation", true)
	schema:register(XMLValueType.STRING, basePath .. ".animations#frontBalePusher", "Front bale pusher animation", "frontBalePusher")
	schema:register(XMLValueType.STRING, basePath .. ".animations#balesToOtherRow", "Bales to othe row animation", "balesToOtherRow")
	schema:register(XMLValueType.STRING, basePath .. ".animations#closeGrippers", "Close grippers animation", "closeGrippers")
end
BaleLoader.GRAB_MOVE_UP = 1
BaleLoader.GRAB_MOVE_DOWN = 2
BaleLoader.GRAB_DROP_BALE = 3
BaleLoader.EMPTY_NONE = 1
BaleLoader.EMPTY_TO_WORK = 2
BaleLoader.EMPTY_ROTATE_PLATFORM = 3
BaleLoader.EMPTY_ROTATE1 = 4
BaleLoader.EMPTY_CLOSE_GRIPPERS = 5
BaleLoader.EMPTY_HIDE_PUSHER1 = 6
BaleLoader.EMPTY_HIDE_PUSHER2 = 7
BaleLoader.EMPTY_ROTATE2 = 8
BaleLoader.EMPTY_WAIT_TO_DROP = 9
BaleLoader.EMPTY_WAIT_TO_SINK = 10
BaleLoader.EMPTY_SINK = 11
BaleLoader.EMPTY_CANCEL = 12
BaleLoader.EMPTY_WAIT_TO_REDO = 13
BaleLoader.CHANGE_DROP_BALES = 1
BaleLoader.CHANGE_SINK = 2
BaleLoader.CHANGE_EMPTY_REDO = 3
BaleLoader.CHANGE_EMPTY_START = 4
BaleLoader.CHANGE_EMPTY_CANCEL = 5
BaleLoader.CHANGE_MOVE_TO_WORK = 6
BaleLoader.CHANGE_MOVE_TO_TRANSPORT = 7
BaleLoader.CHANGE_GRAB_BALE = 8
BaleLoader.CHANGE_GRAB_MOVE_UP = 9
BaleLoader.CHANGE_GRAB_DROP_BALE = 10
BaleLoader.CHANGE_GRAB_MOVE_DOWN = 11
BaleLoader.CHANGE_FRONT_PUSHER = 12
BaleLoader.CHANGE_ROTATE_PLATFORM = 13
BaleLoader.CHANGE_EMPTY_ROTATE_PLATFORM = 14
BaleLoader.CHANGE_EMPTY_ROTATE1 = 15
BaleLoader.CHANGE_EMPTY_CLOSE_GRIPPERS = 16
BaleLoader.CHANGE_EMPTY_HIDE_PUSHER1 = 17
BaleLoader.CHANGE_EMPTY_HIDE_PUSHER2 = 18
BaleLoader.CHANGE_EMPTY_ROTATE2 = 19
BaleLoader.CHANGE_EMPTY_WAIT_TO_DROP = 20
BaleLoader.CHANGE_EMPTY_STATE_NIL = 21
BaleLoader.CHANGE_EMPTY_WAIT_TO_REDO = 22
BaleLoader.CHANGE_BUTTON_EMPTY = 23
BaleLoader.CHANGE_BUTTON_EMPTY_ABORT = 24
BaleLoader.CHANGE_BUTTON_WORK_TRANSPORT = 25

function BaleLoader.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadBaleTypeFromXML", BaleLoader.loadBaleTypeFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadBalePlacesFromXML", BaleLoader.loadBalePlacesFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadBaleLoaderAnimationsFromXML", BaleLoader.loadBaleLoaderAnimationsFromXML)
	SpecializationUtil.registerFunction(vehicleType, "createBaleToBaleJoints", BaleLoader.createBaleToBaleJoints)
	SpecializationUtil.registerFunction(vehicleType, "createBaleToBaleJoint", BaleLoader.createBaleToBaleJoint)
	SpecializationUtil.registerFunction(vehicleType, "doStateChange", BaleLoader.doStateChange)
	SpecializationUtil.registerFunction(vehicleType, "getBaleGrabberDropBaleAnimName", BaleLoader.getBaleGrabberDropBaleAnimName)
	SpecializationUtil.registerFunction(vehicleType, "getIsBaleGrabbingAllowed", BaleLoader.getIsBaleGrabbingAllowed)
	SpecializationUtil.registerFunction(vehicleType, "pickupBale", BaleLoader.pickupBale)
	SpecializationUtil.registerFunction(vehicleType, "setBaleLoaderBaleType", BaleLoader.setBaleLoaderBaleType)
	SpecializationUtil.registerFunction(vehicleType, "getBaleTypeByBale", BaleLoader.getBaleTypeByBale)
	SpecializationUtil.registerFunction(vehicleType, "baleGrabberTriggerCallback", BaleLoader.baleGrabberTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "baleLoaderMoveTriggerCallback", BaleLoader.baleLoaderMoveTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "mountDynamicBale", BaleLoader.mountDynamicBale)
	SpecializationUtil.registerFunction(vehicleType, "unmountDynamicBale", BaleLoader.unmountDynamicBale)
	SpecializationUtil.registerFunction(vehicleType, "mountBale", BaleLoader.mountBale)
	SpecializationUtil.registerFunction(vehicleType, "unmountBale", BaleLoader.unmountBale)
	SpecializationUtil.registerFunction(vehicleType, "setBalePairCollision", BaleLoader.setBalePairCollision)
	SpecializationUtil.registerFunction(vehicleType, "getLoadedBales", BaleLoader.getLoadedBales)
	SpecializationUtil.registerFunction(vehicleType, "startAutomaticBaleUnloading", BaleLoader.startAutomaticBaleUnloading)
	SpecializationUtil.registerFunction(vehicleType, "getIsAutomaticBaleUnloadingInProgress", BaleLoader.getIsAutomaticBaleUnloadingInProgress)
	SpecializationUtil.registerFunction(vehicleType, "getIsAutomaticBaleUnloadingAllowed", BaleLoader.getIsAutomaticBaleUnloadingAllowed)
	SpecializationUtil.registerFunction(vehicleType, "playBaleLoaderFoldingAnimation", BaleLoader.playBaleLoaderFoldingAnimation)
	SpecializationUtil.registerFunction(vehicleType, "getIsBaleLoaderFoldingPlaying", BaleLoader.getIsBaleLoaderFoldingPlaying)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentFoldingAnimation", BaleLoader.getCurrentFoldingAnimation)
	SpecializationUtil.registerFunction(vehicleType, "updateFoldingAnimation", BaleLoader.updateFoldingAnimation)
	SpecializationUtil.registerFunction(vehicleType, "onBaleMoverBaleRemoved", BaleLoader.onBaleMoverBaleRemoved)
	SpecializationUtil.registerFunction(vehicleType, "addBaleUnloadTrigger", BaleLoader.addBaleUnloadTrigger)
	SpecializationUtil.registerFunction(vehicleType, "removeBaleUnloadTrigger", BaleLoader.removeBaleUnloadTrigger)
end

function BaleLoader.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", BaleLoader.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowDynamicMountFillLevelInfo", BaleLoader.getAllowDynamicMountFillLevelInfo)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreControlledActionsAllowed", BaleLoader.getAreControlledActionsAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIReadyToDrive", BaleLoader.getIsAIReadyToDrive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIPreparingToDrive", BaleLoader.getIsAIPreparingToDrive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", BaleLoader.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoConsumePtoPower", BaleLoader.getDoConsumePtoPower)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConsumingLoad", BaleLoader.getConsumingLoad)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsPowerTakeOffActive", BaleLoader.getIsPowerTakeOffActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", BaleLoader.addToPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", BaleLoader.removeFromPhysics)
end

function BaleLoader.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onActivate", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onRootVehicleChanged", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onFoldStateChanged", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onBalerUnloadingStarted", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterAnimationValueTypes", BaleLoader)
end

-- Local values: spec, baseKey, connectedRows, i, getConnectedRows, grabParticleSystem, psName, i, baleTypeKey, entry, animationKey, animation, moverKey, entry
function BaleLoader:onLoad(savegame)
	local v12_ = self.spec_baleLoader
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleloaderTurnedOnScrollers.baleloaderTurnedOnScroller", "vehicle.baleLoader.animationNodes.animationNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleGrabber", "vehicle.baleLoader.grabber")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.balePlaces", "vehicle.baleLoader.balePlaces")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.grabParticleSystem", "vehicle.baleLoader.grabber.grabParticleSystem")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader.grabber.grabParticleSystem", "vehicle.baleLoader.grabber.effectNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#pickupRange", "vehicle.baleLoader.grabber#pickupRange")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleTypes", "vehicle.baleLoader.baleTypes")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#textTransportPosition", "vehicle.baleLoader.texts#transportPosition")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#textOperatingPosition", "vehicle.baleLoader.texts#operatingPosition")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#textUnload", "vehicle.baleLoader.texts#unload")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#textTilting", "vehicle.baleLoader.texts#tilting")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#textLowering", "vehicle.baleLoader.texts#lowering")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#textLowerPlattform", "vehicle.baleLoader.texts#lowerPlattform")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#textAbortUnloading", "vehicle.baleLoader.texts#abortUnloading")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#textUnloadHere", "vehicle.baleLoader.texts#unloadHere")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#rotatePlatformAnimName", "vehicle.baleLoader.animations#rotatePlatform")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#rotatePlatformBackAnimName", "vehicle.baleLoader.animations#rotatePlatformBack")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#rotatePlatformEmptyAnimName", "vehicle.baleLoader.animations#rotatePlatformEmpty")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader.animations#grabberDropBaleReverseSpeed", "vehicle.baleLoader.animations.baleGrabber#dropBaleReverseSpeed")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader.animations#grabberDropToWork", "vehicle.baleLoader.animations.baleGrabber#dropToWork")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader.animations#rotatePlatform", "vehicle.baleLoader.animations.platform#rotate")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader.animations#rotatePlatformBack", "vehicle.baleLoader.animations.platform#rotateBack")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader.animations#rotatePlatformEmpty", "vehicle.baleLoader.animations.platform#rotateEmpty")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#moveBalePlacesAfterRotatePlatform", "vehicle.baleLoader.animations.moveBalePlaces#moveAfterRotatePlatform")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#moveBalePlacesMaxGrabberTime", "vehicle.baleLoader.animations.moveBalePlaces#maxGrabberTime")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#alwaysMoveBalePlaces", "vehicle.baleLoader.animations.moveBalePlaces#alwaysMove")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#resetEmptyRotateAnimation", "vehicle.baleLoader.animations.emptyRotate#reset")
	v12_.balesToLoad = {}
	v12_.balesToMount = {}
	v12_.isInWorkPosition = false
	v12_.grabberIsMoving = false
	v12_.rotatePlatformDirection = 0
	v12_.frontBalePusherDirection = 0
	v12_.emptyState = BaleLoader.EMPTY_NONE
	v12_.texts = {}
	v12_.texts.transportPosition = self.xmlFile:getValue("vehicle.baleLoader.texts#transportPosition", "action_baleloaderTransportPosition", nil, self.customEnvironment)
	v12_.texts.operatingPosition = self.xmlFile:getValue("vehicle.baleLoader.texts#operatingPosition", "action_baleloaderOperatingPosition", nil, self.customEnvironment)
	v12_.texts.unload = self.xmlFile:getValue("vehicle.baleLoader.texts#unload", "action_baleloaderUnload", nil, self.customEnvironment)
	v12_.texts.tilting = self.xmlFile:getValue("vehicle.baleLoader.texts#tilting", "info_baleloaderTiltingTable", nil, self.customEnvironment)
	v12_.texts.lowering = self.xmlFile:getValue("vehicle.baleLoader.texts#lowering", "info_baleloaderLoweringTable", nil, self.customEnvironment)
	v12_.texts.lowerPlattform = self.xmlFile:getValue("vehicle.baleLoader.texts#lowerPlattform", "action_baleloaderLowerPlatform", nil, self.customEnvironment)
	v12_.texts.abortUnloading = self.xmlFile:getValue("vehicle.baleLoader.texts#abortUnloading", "action_baleloaderAbortUnloading", nil, self.customEnvironment)
	v12_.texts.unloadHere = self.xmlFile:getValue("vehicle.baleLoader.texts#unloadHere", "action_baleloaderUnloadHere", nil, self.customEnvironment)
	v12_.texts.baleNotSupported = self.xmlFile:getValue("vehicle.baleLoader.texts#baleNotSupported", "warning_baleNotSupported", nil, self.customEnvironment)
	v12_.texts.baleDoNotAllowFillTypeMixing = self.xmlFile:getValue("vehicle.baleLoader.texts#baleDoNotAllowFillTypeMixing", "warning_baleDoNotAllowFillTypeMixing", nil, self.customEnvironment)
	v12_.texts.onlyOneBaleTypeWarning = self.xmlFile:getValue("vehicle.baleLoader.texts#onlyOneBaleTypeWarning", "warning_baleLoaderOnlyAllowOnceSize", nil, self.customEnvironment)
	v12_.texts.minUnloadingFillLevelWarning = self.xmlFile:getValue("vehicle.baleLoader.texts#minUnloadingFillLevelWarning", "warning_baleLoaderNotFullyLoaded", nil, self.customEnvironment)
	v12_.texts.youDoNotOwnBale = g_i18n:getText("warning_youDontOwnThisItem")
	v12_.transportPositionAfterUnloading = self.xmlFile:getValue("vehicle.baleLoader#transportPositionAfterUnloading", true)
	v12_.useFoldingState = self.xmlFile:getValue("vehicle.baleLoader#useFoldingState", false)
	v12_.useBalePlaceAsLoadPosition = self.xmlFile:getValue("vehicle.baleLoader#useBalePlaceAsLoadPosition", false)
	v12_.balePlaceOffset = self.xmlFile:getValue("vehicle.baleLoader#balePlaceOffset", 0)
	v12_.keepBaleRotationDuringLoad = self.xmlFile:getValue("vehicle.baleLoader#keepBaleRotationDuringLoad", false)
	v12_.fullAutomaticUnloading = self.xmlFile:getValue("vehicle.baleLoader#fullAutomaticUnloading", false)
	v12_.automaticUnloading = self.xmlFile:getValue("vehicle.baleLoader#automaticUnloading", v12_.fullAutomaticUnloading)
	v12_.minUnloadingFillLevel = self.xmlFile:getValue("vehicle.baleLoader#minUnloadingFillLevel", 1)
	v12_.fillUnitIndex = self.xmlFile:getValue("vehicle.baleLoader#fillUnitIndex", 1)
	v12_.allowKinematicMounting = self.xmlFile:getValue("vehicle.baleLoader#allowKinematicMounting", true)
	v12_.consumePtoPower = self.xmlFile:getValue("vehicle.baleLoader#consumePtoPower", true)
	v12_.dynamicMount = {}
	v12_.dynamicMount.enabled = self.xmlFile:getValue("vehicle.baleLoader.dynamicMount#enabled", false)
	v12_.dynamicMount.jointInterpolation = self.xmlFile:getValue("vehicle.baleLoader.dynamicMount#doInterpolation", false)
	v12_.dynamicMount.jointInterpolationTimeRot = self.xmlFile:getValue("vehicle.baleLoader.dynamicMount#interpolationTimeRot", 1)
	v12_.dynamicMount.jointInterpolationSpeedTrans = self.xmlFile:getValue("vehicle.baleLoader.dynamicMount#interpolationSpeedTrans", 0.1) / 1000
	v12_.dynamicMount.baleJointsToUpdate = {}
	v12_.dynamicMount.minTransLimits = self.xmlFile:getValue("vehicle.baleLoader.dynamicMount#minTransLimits", nil, true)
	v12_.dynamicMount.maxTransLimits = self.xmlFile:getValue("vehicle.baleLoader.dynamicMount#maxTransLimits", nil, true)
	v12_.dynamicMount.baleMassDirty = false
	v12_.dynamicBaleUnloading = {}
	v12_.dynamicBaleUnloading.enabled = self.xmlFile:getValue("vehicle.baleLoader.dynamicBaleUnloading#enabled", false)
	v12_.dynamicBaleUnloading.connectedRows = {}
	local v13_ = self.xmlFile:getValue("vehicle.baleLoader.dynamicBaleUnloading#connectedRows", nil, true)
	if v13_ ~= nil then
		for v14_ = 1, #v13_ do
			v12_.dynamicBaleUnloading.connectedRows[v13_[v14_]] = true
		end
	end
	local function v25_(p15_)
		-- upvalues: (copy) self
		local v16_ = {}
		local v17_ = self.xmlFile:getValue(p15_)
		if v17_ ~= nil then
			local v18_ = string.split(v17_, " ")
			for v19_ = 1, #v18_ do
				local v20_ = string.split(v18_[v19_], "-")
				if #v20_ == 2 then
					local v21_ = {}
					local v22_ = v20_[1]
					local v23_ = tonumber(v22_)
					local v24_ = v20_[2]
					__set_list(v21_, 1, {v23_, (tonumber(v24_))})
					table.insert(v16_, v21_)
				else
					Logging.xmlWarning(self.xmlFile, "Unknown row connection \'%s\' in \'%s\' (should look like \'1-2 3-4\')", v18_[v19_], p15_)
				end
			end
		end
		return v16_
	end
	v12_.dynamicBaleUnloading.interConnectedRowStarts = v25_("vehicle.baleLoader.dynamicBaleUnloading#interConnectedRowStarts")
	v12_.dynamicBaleUnloading.interConnectedRowEnds = v25_("vehicle.baleLoader.dynamicBaleUnloading#interConnectedRowEnds")
	v12_.dynamicBaleUnloading.widthOffset = self.xmlFile:getValue("vehicle.baleLoader.dynamicBaleUnloading#widthOffset", 0.05)
	v12_.dynamicBaleUnloading.heightOffset = self.xmlFile:getValue("vehicle.baleLoader.dynamicBaleUnloading#heightOffset", 0.05)
	v12_.dynamicBaleUnloading.diameterOffset = self.xmlFile:getValue("vehicle.baleLoader.dynamicBaleUnloading#diameterOffset", 0.05)
	v12_.dynamicBaleUnloading.rowConnectionRotLimit = self.xmlFile:getValue("vehicle.baleLoader.dynamicBaleUnloading#rowConnectionRotLimit", 4)
	v12_.dynamicBaleUnloading.rowInterConnectionRotLimit = self.xmlFile:getValue("vehicle.baleLoader.dynamicBaleUnloading#rowInterConnectionRotLimit", 1)
	v12_.dynamicBaleUnloading.releaseAnimation = self.xmlFile:getValue("vehicle.baleLoader.dynamicBaleUnloading.releaseAnimation#name")
	v12_.dynamicBaleUnloading.releaseAnimationTime = self.xmlFile:getValue("vehicle.baleLoader.dynamicBaleUnloading.releaseAnimation#time", 1)
	v12_.dynamicBaleUnloading.useUnloadingMoverTrigger = self.xmlFile:getValue("vehicle.baleLoader.dynamicBaleUnloading.releaseAnimation#useUnloadingMoverTrigger", false)
	v12_.baleGrabber = {}
	v12_.baleGrabber.grabNode = self.xmlFile:getValue("vehicle.baleLoader.grabber#grabNode", nil, self.components, self.i3dMappings)
	v12_.baleGrabber.pickupRange = self.xmlFile:getValue("vehicle.baleLoader.grabber#pickupRange", 3)
	v12_.baleGrabber.balesInTrigger = {}
	v12_.baleGrabber.trigger = self.xmlFile:getValue("vehicle.baleLoader.grabber#triggerNode", nil, self.components, self.i3dMappings)
	if v12_.baleGrabber.trigger == nil then
		Logging.xmlError(self.xmlFile, "Bale grabber needs a valid trigger!")
	else
		addTrigger(v12_.baleGrabber.trigger, "baleGrabberTriggerCallback", self)
		g_currentMission:addNodeObject(v12_.baleGrabber.trigger, self)
	end
	if self.isClient then
		local v26_ = {}
		if ParticleUtil.loadParticleSystem(self.xmlFile, v26_, "vehicle.baleLoader.grabber.grabParticleSystem", self.components, false, nil, self.baseDirectory) then
			v12_.grabParticleSystem = v26_
			v12_.grabParticleSystemDisableTime = 0
		end
		v12_.grabberEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.baleLoader.grabber", self.components, self, self.i3dMappings)
		v12_.grabberEffectDisableDuration = self.xmlFile:getValue("vehicle.baleLoader.grabber#effectDisableDuration", 0.6)
		v12_.grabberEffectDisableTime = 0
		v12_.samples = {}
		v12_.samples.grab = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.baleLoader.sounds", "grab", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v12_.samples.emptyRotate = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.baleLoader.sounds", "emptyRotate", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v12_.samples.work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.baleLoader.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v12_.samples.unload = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.baleLoader.sounds", "unload", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
	v12_.defaultAnimations = {}
	self:loadBaleLoaderAnimationsFromXML(self.xmlFile, "vehicle.baleLoader", v12_.defaultAnimations)
	v12_.animations = v12_.defaultAnimations.animations
	v12_.defaultBalePlace = {}
	v12_.useSharedBalePlaces = false
	if self:loadBalePlacesFromXML(self.xmlFile, "vehicle.baleLoader", v12_.defaultBalePlace) then
		v12_.useSharedBalePlaces = true
	end
	v12_.startBalePlace = v12_.defaultBalePlace.startBalePlace
	v12_.balePlaces = v12_.defaultBalePlace.balePlaces
	v12_.baleTypes = {}
	local v27_ = 0
	while true do
		local v28_ = string.format("%s.baleTypes.baleType(%d)", "vehicle.baleLoader", v27_)
		if not self.xmlFile:hasProperty(v28_) then
			break
		end
		local v29_ = {}
		if self:loadBaleTypeFromXML(self.xmlFile, v28_, v29_) then
			v29_.index = v27_ + 1
			local v30_ = v12_.baleTypes
			table.insert(v30_, v29_)
		end
		v27_ = v27_ + 1
	end
	if #v12_.baleTypes == 0 then
		Logging.xmlError(self.xmlFile, "No bale types defined for baleLoader!")
	else
		if v12_.startBalePlace == nil then
			v12_.startBalePlace = v12_.baleTypes[1].startBalePlace
		end
		if v12_.balePlaces == nil then
			v12_.balePlaces = v12_.baleTypes[1].balePlaces
		end
		if v12_.startBalePlace == nil then
			Logging.xmlError(self.xmlFile, "Could not find startBalePlace for baleLoader!")
		end
		if v12_.balePlaces == nil then
			Logging.xmlError(self.xmlFile, "Could not find bale places for baleLoader!")
		end
	end
	self:setBaleLoaderBaleType(1)
	v12_.foldingAnimations = {}
	local v31_ = 0
	while true do
		local v32_ = string.format("%s.foldingAnimations.foldingAnimation(%d)", "vehicle.baleLoader", v31_)
		if not self.xmlFile:hasProperty(v32_) then
			break
		end
		local v33_ = {
			["name"] = self.xmlFile:getValue(v32_ .. "#name"),
			["baleTypeIndex"] = self.xmlFile:getValue(v32_ .. "#baleTypeIndex", 0),
			["minFillLevel"] = self.xmlFile:getValue(v32_ .. "#minFillLevel", -math.huge),
			["maxFillLevel"] = self.xmlFile:getValue(v32_ .. "#maxFillLevel", math.huge),
			["minBalePlace"] = self.xmlFile:getValue(v32_ .. "#minBalePlace", -math.huge),
			["maxBalePlace"] = self.xmlFile:getValue(v32_ .. "#maxBalePlace", math.huge)
		}
		if self:getAnimationExists(v33_.name) then
			local v34_ = v12_.foldingAnimations
			table.insert(v34_, v33_)
		else
			Logging.xmlWarning(self.xmlFile, "Unknown folding animation \'%s\' in \'%s\'", v33_.name, v32_)
		end
		v31_ = v31_ + 1
	end
	v12_.hasMultipleFoldingAnimations = #v12_.foldingAnimations > 0
	v12_.lastFoldingAnimation = v12_.animations.baleGrabberTransportToWork
	self:updateFoldingAnimation()
	v12_.unloadingMover = {}
	v12_.unloadingMover.trigger = self.xmlFile:getValue("vehicle.baleLoader.unloadingMoverNodes#trigger", nil, self.components, self.i3dMappings)
	if v12_.unloadingMover.trigger ~= nil then
		addTrigger(v12_.unloadingMover.trigger, "baleLoaderMoveTriggerCallback", self)
		g_currentMission:addNodeObject(v12_.unloadingMover.trigger, self)
	end
	v12_.unloadingMover.isActive = false
	v12_.unloadingMover.dirtyFlag = self:getNextDirtyFlag()
	v12_.unloadingMover.frameDelay = 0
	v12_.unloadingMover.balesInTrigger = {}
	v12_.unloadingMover.nodes = {}
	v12_.unloadingMover.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.baleLoader.unloadingMoverNodes.animationNodes", self.components, self, self.i3dMappings)
	local v35_ = 0
	while true do
		local v36_ = string.format("%s.unloadingMoverNodes.unloadingMoverNode(%d)", "vehicle.baleLoader", v35_)
		if not self.xmlFile:hasProperty(v36_) then
			break
		end
		local v37_ = {
			["node"] = self.xmlFile:getValue(v36_ .. "#node", nil, self.components, self.i3dMappings),
			["speed"] = self.xmlFile:getValue(v36_ .. "#speed", -1)
		}
		if v37_.node == nil then
			Logging.xmlWarning(self.xmlFile, "Unknown node in \'%s\'", v36_)
		else
			local v38_ = v12_.unloadingMover.nodes
			table.insert(v38_, v37_)
		end
		v35_ = v35_ + 1
	end
	v12_.balePacker = {}
	v12_.balePacker.node = self.xmlFile:getValue("vehicle.baleLoader.balePacker#node", nil, self.components, self.i3dMappings)
	v12_.balePacker.filename = self.xmlFile:getValue("vehicle.baleLoader.balePacker#packedFilename")
	if v12_.balePacker.filename ~= nil then
		v12_.balePacker.filename = Utils.getFilename(v12_.balePacker.filename, self.baseDirectory)
		if v12_.balePacker.filename ~= nil and not fileExists(v12_.balePacker.filename) then
			Logging.xmlError(self.xmlFile, "Unable to find packed bale \'%s\'", v12_.balePacker.filename)
		end
	end
	v12_.synchronizationNumBitsPosition = self.xmlFile:getValue("vehicle.baleLoader.synchronization#numBitsPosition", 10)
	v12_.synchronizationMaxPosition = self.xmlFile:getValue("vehicle.baleLoader.synchronization#maxPosition", 3)
	v12_.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.baleLoader.animationNodes", self.components, self, self.i3dMappings)
	v12_.animationNodesBlocked = false
	v12_.showBaleNotSupportedWarning = false
	v12_.baleNotSupportedWarning = nil
	v12_.automaticUnloadingInProgress = false
	v12_.automaticUnloadingAdditionalBalesToLoad = -1
	v12_.lastPickupAutomatedUnloadingDelayTime = 15000
	v12_.lastPickupTime = -v12_.lastPickupAutomatedUnloadingDelayTime
	v12_.kinematicMountedBales = {}
	v12_.baleUnloadTriggers = {}
	v12_.baleJoints = {}
end

-- Local values: spec, baleTypeIndex, numBales, i, baleKey, filename, translation, rotation, balePlace, helper, parentNode, bales, attributes
function BaleLoader:onPostLoad(savegame)
	if savegame ~= nil then
		local v41_ = self.spec_baleLoader
		local v42_ = savegame.xmlFile:getValue(savegame.key .. ".baleLoader#baleTypeIndex")
		if v42_ ~= nil then
			self:setBaleLoaderBaleType(v42_, true)
		end
		if v41_.hasMultipleFoldingAnimations and not savegame.resetVehicles then
			v41_.lastFoldingAnimation = savegame.xmlFile:getValue(savegame.key .. ".baleLoader#lastFoldingAnimation", v41_.lastFoldingAnimation)
		end
		if savegame.xmlFile:getValue(savegame.key .. ".baleLoader#isInWorkPosition", false) then
			if not v41_.isInWorkPosition then
				v41_.grabberIsMoving = true
				v41_.isInWorkPosition = true
				BaleLoader.moveToWorkPosition(self, true)
			end
		else
			BaleLoader.moveToTransportPosition(self)
		end
		v41_.startBalePlace.current = 1
		v41_.startBalePlace.count = 0
		if not savegame.resetVehicles then
			local v43_ = 0
			local v44_ = 0
			while true do
				local v45_ = savegame.key .. string.format(".baleLoader.bale(%d)", v43_)
				if not savegame.xmlFile:hasProperty(v45_) then
					break
				end
				local v46_ = savegame.xmlFile:getValue(v45_ .. "#filename")
				if v46_ ~= nil then
					local v47_ = NetworkUtil.convertFromNetworkFilename(v46_)
					local v48_ = savegame.xmlFile:getValue(v45_ .. "#position", nil, true)
					local v49_ = savegame.xmlFile:getValue(v45_ .. "#rotation", nil, true)
					local v50_ = savegame.xmlFile:getValue(v45_ .. "#balePlace")
					local v51_ = savegame.xmlFile:getValue(v45_ .. "#helper")
					if v50_ == nil or v50_ > 0 and (v48_ == nil or v49_ == nil) or v50_ < 1 and v51_ == nil then
						printWarning("Warning: Corrupt savegame, bale " .. v47_ .. " could not be loaded")
					else
						if v50_ <= 0 then
							v48_ = { 0, 0, 0 }
							v49_ = { 0, 0, 0 }
						end
						local v52_ = nil
						local v53_ = nil
						if v50_ < 1 then
							if v41_.startBalePlace.node ~= nil and v51_ <= v41_.startBalePlace.numOfPlaces then
								v52_ = getChildAt(v41_.startBalePlace.node, v51_ - 1)
								if v41_.startBalePlace.bales == nil then
									v41_.startBalePlace.bales = {}
								end
								v53_ = v41_.startBalePlace.bales
								v41_.startBalePlace.count = v41_.startBalePlace.count + 1
							end
						elseif v50_ <= #v41_.balePlaces then
							local v54_ = v41_.startBalePlace
							local v55_ = v41_.startBalePlace.current
							local v56_ = v50_ + 1
							v54_.current = math.max(v55_, v56_)
							v52_ = v41_.balePlaces[v50_].node
							if v41_.balePlaces[v50_].bales == nil then
								v41_.balePlaces[v50_].bales = {}
							end
							v53_ = v41_.balePlaces[v50_].bales
						end
						if v52_ ~= nil then
							local v57_ = {}
							Bale.loadBaleAttributesFromXMLFile(v57_, savegame.xmlFile, v45_, savegame.resetVehicles)
							v44_ = v44_ + 1
							local v58_ = v41_.balesToLoad
							table.insert(v58_, {
								["parentNode"] = v52_,
								["filename"] = v47_,
								["bales"] = v53_,
								["translation"] = v48_,
								["rotation"] = v49_,
								["attributes"] = v57_
							})
						end
					end
				end
				v43_ = v43_ + 1
			end
		end
		self:updateFoldingAnimation()
		BaleLoader.updateBalePlacesAnimations(self)
	end
end

-- Local values: spec, k, v, baleObject, x, y, z, rx, ry, rz
function BaleLoader:onLoadFinished(savegame)
	local v60_ = self.spec_baleLoader
	for v61_, v62_ in pairs(v60_.balesToLoad) do
		local v63_ = Bale.new(self.isServer, self.isClient)
		local v64_ = v62_.translation
		local v65_, v66_, v67_ = unpack(v64_)
		local v68_ = v62_.rotation
		local v69_, v70_, v71_ = unpack(v68_)
		if v63_:loadFromConfigXML(v62_.filename, v65_, v66_, v67_, v69_, v70_, v71_, v62_.attributes.uniqueId) then
			v63_:applyBaleAttributes(v62_.attributes)
			v63_:register()
			if v60_.dynamicMount.enabled then
				self:mountDynamicBale(v63_, v62_.parentNode)
			else
				self:mountBale(v63_, self, v62_.parentNode, v65_, v66_, v67_, v69_, v70_, v71_)
			end
			v63_:setCanBeSold(false)
			local v72_ = v62_.bales
			local v73_ = NetworkUtil.getObjectId
			table.insert(v72_, v73_(v63_))
		end
		v60_.balesToLoad[v61_] = nil
	end
end

-- Local values: spec, _, balePlace, _, baleServerId, bale, _, baleServerId, bale, bale, object, _, unloadTrigger, _
function BaleLoader:onDelete()
	local v75_ = self.spec_baleLoader
	if v75_.balePlaces ~= nil then
		for _, v76_ in pairs(v75_.balePlaces) do
			if v76_.bales ~= nil then
				for _, v77_ in pairs(v76_.bales) do
					local v78_ = NetworkUtil.getObject(v77_)
					if v78_ ~= nil then
						if v75_.dynamicMount.enabled then
							self:unmountDynamicBale(v78_)
						else
							self:unmountBale(v78_)
						end
						v78_:setCanBeSold(true)
						if self.isReconfigurating ~= nil and self.isReconfigurating then
							v78_:delete()
						end
					end
				end
			end
		end
	end
	if v75_.startBalePlace ~= nil then
		for _, v79_ in ipairs(v75_.startBalePlace.bales) do
			local v80_ = NetworkUtil.getObject(v79_)
			if v80_ ~= nil then
				if v75_.dynamicMount.enabled then
					self:unmountDynamicBale(v80_)
				else
					self:unmountBale(v80_)
				end
				v80_:setCanBeSold(true)
				if self.isReconfigurating ~= nil and self.isReconfigurating then
					v80_:delete()
				end
			end
		end
	end
	if v75_.baleGrabber ~= nil then
		if v75_.baleGrabber.currentBale ~= nil then
			local v81_ = NetworkUtil.getObject(v75_.baleGrabber.currentBale)
			if v81_ ~= nil then
				if v75_.dynamicMount.enabled then
					self:unmountDynamicBale(v81_)
				else
					self:unmountBale(v81_)
				end
				v81_:setCanBeSold(true)
			end
		end
		if v75_.baleGrabber.trigger ~= nil then
			removeTrigger(v75_.baleGrabber.trigger)
			g_currentMission:removeNodeObject(v75_.baleGrabber.trigger)
		end
	end
	if v75_.unloadingMover ~= nil then
		if v75_.unloadingMover.trigger ~= nil then
			removeTrigger(v75_.unloadingMover.trigger)
			g_currentMission:removeNodeObject(v75_.unloadingMover.trigger)
		end
		if v75_.unloadingMover.balesInTrigger ~= nil then
			for v82_, _ in pairs(v75_.unloadingMover.balesInTrigger) do
				if v82_.removeDeleteListener ~= nil then
					v82_:removeDeleteListener(self, "onBaleMoverBaleRemoved")
				end
			end
			table.clear(v75_.unloadingMover.balesInTrigger)
		end
		g_animationManager:deleteAnimations(v75_.unloadingMover.animationNodes)
	end
	if v75_.baleUnloadTriggers ~= nil then
		for v83_, _ in pairs(v75_.baleUnloadTriggers) do
			if v83_.removeDeleteListener ~= nil then
				v83_:removeDeleteListener(self, BaleLoader.onBaleUnloadTriggerDeleted)
			end
		end
		table.clear(v75_.baleUnloadTriggers)
	end
	g_effectManager:deleteEffects(v75_.grabberEffects)
	g_soundManager:deleteSamples(v75_.samples)
	g_animationManager:deleteAnimations(v75_.animationNodes)
end

-- Local values: spec, baleIndex, i, balePlace, _, baleServerId, bale, baleKey, startBaleEmpty, loadPlaceEmpty, lastItem, evenCapacity, i, baleServerId, bale, baleKey, bale
function BaleLoader:saveToXMLFile(xmlFile, key, usedModNames)
	local v87_ = self.spec_baleLoader
	xmlFile:setValue(key .. "#isInWorkPosition", v87_.isInWorkPosition)
	if v87_.currentBaleType ~= nil then
		xmlFile:setValue(key .. "#baleTypeIndex", v87_.currentBaleType.index)
	end
	local v88_ = 0
	for v89_, v90_ in pairs(v87_.balePlaces) do
		if v90_.bales ~= nil then
			for _, v91_ in pairs(v90_.bales) do
				local v92_ = NetworkUtil.getObject(v91_)
				if v92_ ~= nil then
					local v93_ = string.format("%s.bale(%d)", key, v88_)
					v92_:saveToXMLFile(xmlFile, v93_)
					local v94_ = #v87_.startBalePlace.bales == 0
					local v95_ = self:getFillUnitFillLevel(v87_.fillUnitIndex) % v87_.startBalePlace.numOfPlaces ~= 0
					local v96_ = self:getFillUnitFillLevel(v87_.fillUnitIndex) / v87_.startBalePlace.numOfPlaces
					if v94_ and (v95_ and (math.floor(v96_) + 1 == v89_ and self:getFillUnitCapacity(v87_.fillUnitIndex) % 2 == 0)) then
						xmlFile:setValue(v93_ .. "#balePlace", 0)
						xmlFile:setValue(v93_ .. "#helper", 1)
					else
						xmlFile:setValue(v93_ .. "#balePlace", v89_)
					end
					v88_ = v88_ + 1
				end
			end
		end
	end
	for v97_, v98_ in ipairs(v87_.startBalePlace.bales) do
		local v99_ = NetworkUtil.getObject(v98_)
		if v99_ ~= nil then
			local v100_ = string.format("%s.bale(%d)", key, v88_)
			v99_:saveToXMLFile(xmlFile, v100_)
			xmlFile:setValue(v100_ .. "#balePlace", 0)
			xmlFile:setValue(v100_ .. "#helper", v97_)
			v88_ = v88_ + 1
		end
	end
	if v87_.hasMultipleFoldingAnimations and v87_.lastFoldingAnimation ~= nil then
		xmlFile:setValue(key .. "#lastFoldingAnimation", v87_.lastFoldingAnimation)
	end
	if v87_.baleGrabber.currentBale ~= nil then
		local v101_ = NetworkUtil.getObject(v87_.baleGrabber.currentBale)
		if v101_ ~= nil then
			self:unmountBale(v101_)
			v87_.baleGrabber.currentBaleIsUnmounted = true
		end
	end
end

-- Local values: spec, currentBaleTypeIndex, emptyState, i, baleServerId, attachNode, i, balePlace, numBales, _, baleServerId, x, y, z, maxValue
function BaleLoader:onReadStream(streamId, connection)
	local v104_ = self.spec_baleLoader
	v104_.isInWorkPosition = streamReadBool(streamId)
	v104_.frontBalePusherDirection = streamReadIntN(streamId, 3)
	v104_.rotatePlatformDirection = streamReadIntN(streamId, 3)
	if streamReadBool(streamId) then
		self:setBaleLoaderBaleType((streamReadIntN(streamId, 6)))
	end
	if v104_.isInWorkPosition then
		BaleLoader.moveToWorkPosition(self)
	end
	local v105_ = streamReadUIntN(streamId, 4)
	v104_.startBalePlace.current = streamReadInt8(streamId)
	if streamReadBool(streamId) then
		v104_.baleGrabber.currentBale = NetworkUtil.readNodeObjectId(streamId)
		v104_.balesToMount[v104_.baleGrabber.currentBale] = {
			["serverId"] = v104_.baleGrabber.currentBale,
			["linkNode"] = v104_.baleGrabber.grabNode,
			["trans"] = { 0, 0, 0 },
			["rot"] = { 0, 0, 0 }
		}
	end
	v104_.startBalePlace.count = streamReadUInt8(streamId)
	for v106_ = 1, v104_.startBalePlace.count do
		local v107_ = NetworkUtil.readNodeObjectId(streamId)
		local v108_ = {
			["serverId"] = v107_,
			["linkNode"] = getChildAt(v104_.startBalePlace.node, v106_ - 1),
			["trans"] = { 0, 0, 0 },
			["rot"] = { 0, 0, 0 }
		}
		v104_.balesToMount[v107_] = v108_
		local v109_ = v104_.startBalePlace.bales
		table.insert(v109_, v107_)
		self:updateFoldingAnimation()
	end
	for v110_ = 1, #v104_.balePlaces do
		local v111_ = v104_.balePlaces[v110_]
		local v112_ = streamReadUInt8(streamId)
		if v112_ > 0 then
			v111_.bales = {}
			for _ = 1, v112_ do
				local v113_ = NetworkUtil.readNodeObjectId(streamId)
				local v114_, v115_, v116_
				if v104_.dynamicMount.enabled then
					v114_ = 0
					v115_ = 0
					v116_ = 0
				else
					local v117_ = 2 ^ v104_.synchronizationNumBitsPosition - 1
					v114_ = streamReadUIntN(streamId, v104_.synchronizationNumBitsPosition) / v117_ * (v104_.synchronizationMaxPosition * 2) - v104_.synchronizationMaxPosition
					v115_ = streamReadUIntN(streamId, v104_.synchronizationNumBitsPosition) / v117_ * (v104_.synchronizationMaxPosition * 2) - v104_.synchronizationMaxPosition
					v116_ = streamReadUIntN(streamId, v104_.synchronizationNumBitsPosition) / v117_ * (v104_.synchronizationMaxPosition * 2) - v104_.synchronizationMaxPosition
				end
				local v118_ = v111_.bales
				table.insert(v118_, v113_)
				v104_.balesToMount[v113_] = {
					["serverId"] = v113_,
					["linkNode"] = v111_.node,
					["trans"] = { v114_, v115_, v116_ },
					["rot"] = { 0, 0, 0 }
				}
			end
		end
	end
	BaleLoader.updateBalePlacesAnimations(self)
	if BaleLoader.EMPTY_TO_WORK <= v105_ then
		self:doStateChange(BaleLoader.CHANGE_EMPTY_START)
		AnimatedVehicle.updateAnimations(self, 99999999, true)
		if BaleLoader.EMPTY_ROTATE_PLATFORM <= v105_ then
			self:doStateChange(BaleLoader.CHANGE_EMPTY_ROTATE_PLATFORM)
			AnimatedVehicle.updateAnimations(self, 99999999, true)
			if BaleLoader.EMPTY_ROTATE1 <= v105_ then
				self:doStateChange(BaleLoader.CHANGE_EMPTY_ROTATE1)
				AnimatedVehicle.updateAnimations(self, 99999999, true)
				if BaleLoader.EMPTY_CLOSE_GRIPPERS <= v105_ then
					self:doStateChange(BaleLoader.CHANGE_EMPTY_CLOSE_GRIPPERS)
					AnimatedVehicle.updateAnimations(self, 99999999, true)
					if BaleLoader.EMPTY_HIDE_PUSHER1 <= v105_ then
						self:doStateChange(BaleLoader.CHANGE_EMPTY_HIDE_PUSHER1)
						AnimatedVehicle.updateAnimations(self, 99999999, true)
						if BaleLoader.EMPTY_HIDE_PUSHER2 <= v105_ then
							self:doStateChange(BaleLoader.CHANGE_EMPTY_HIDE_PUSHER2)
							AnimatedVehicle.updateAnimations(self, 99999999, true)
							if BaleLoader.EMPTY_ROTATE2 <= v105_ then
								self:doStateChange(BaleLoader.CHANGE_EMPTY_ROTATE2)
								AnimatedVehicle.updateAnimations(self, 99999999, true)
								if BaleLoader.EMPTY_WAIT_TO_DROP <= v105_ then
									self:doStateChange(BaleLoader.CHANGE_EMPTY_WAIT_TO_DROP)
									AnimatedVehicle.updateAnimations(self, 99999999, true)
									if v105_ == BaleLoader.EMPTY_CANCEL or v105_ == BaleLoader.EMPTY_WAIT_TO_REDO then
										self:doStateChange(BaleLoader.CHANGE_EMPTY_CANCEL)
										AnimatedVehicle.updateAnimations(self, 99999999, true)
										if v105_ == BaleLoader.EMPTY_WAIT_TO_REDO then
											self:doStateChange(BaleLoader.CHANGE_EMPTY_WAIT_TO_REDO)
											AnimatedVehicle.updateAnimations(self, 99999999, true)
										end
									elseif v105_ == BaleLoader.EMPTY_WAIT_TO_SINK or v105_ == BaleLoader.EMPTY_SINK then
										self:doStateChange(BaleLoader.CHANGE_DROP_BALES)
										AnimatedVehicle.updateAnimations(self, 99999999, true)
										if v105_ == BaleLoader.EMPTY_SINK then
											self:doStateChange(BaleLoader.CHANGE_SINK)
											AnimatedVehicle.updateAnimations(self, 99999999, true)
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
	v104_.emptyState = v105_
end

-- Local values: spec, i, baleServerId, i, balePlace, numBales, baleI, baleServerId, bale, nodeId, x, y, z, maxValue
function BaleLoader:onWriteStream(streamId, connection)
	local v121_ = self.spec_baleLoader
	streamWriteBool(streamId, v121_.isInWorkPosition)
	streamWriteIntN(streamId, v121_.frontBalePusherDirection, 3)
	streamWriteIntN(streamId, v121_.rotatePlatformDirection, 3)
	if streamWriteBool(streamId, v121_.currentBaleType ~= nil) then
		streamWriteIntN(streamId, v121_.currentBaleType.index or 1, 6)
	end
	streamWriteUIntN(streamId, v121_.emptyState, 4)
	streamWriteInt8(streamId, v121_.startBalePlace.current)
	if streamWriteBool(streamId, v121_.baleGrabber.currentBale ~= nil) then
		NetworkUtil.writeNodeObjectId(streamId, v121_.baleGrabber.currentBale)
	end
	streamWriteUInt8(streamId, v121_.startBalePlace.count)
	for v122_ = 1, v121_.startBalePlace.count do
		local v123_ = v121_.startBalePlace.bales[v122_]
		NetworkUtil.writeNodeObjectId(streamId, v123_)
	end
	for v124_ = 1, #v121_.balePlaces do
		local v125_ = v121_.balePlaces[v124_]
		local v126_ = v125_.bales == nil and 0 or #v125_.bales
		streamWriteUInt8(streamId, v126_)
		if v125_.bales ~= nil then
			for v127_ = 1, v126_ do
				local v128_ = v125_.bales[v127_]
				local v129_ = NetworkUtil.getObject(v128_).nodeId
				local v130_, v131_, v132_ = getTranslation(v129_)
				NetworkUtil.writeNodeObjectId(streamId, v128_)
				if not v121_.dynamicMount.enabled then
					if math.abs(v130_) > v121_.synchronizationMaxPosition or (math.abs(v131_) > v121_.synchronizationMaxPosition or math.abs(v132_) > v121_.synchronizationMaxPosition) then
						Logging.xmlWarning(self.xmlFile, "Position of bale \'%d\' could not be synchronized correctly. Position out of range (%.2f, %.2f, %.2f) > %.2f. Increase \'vehicle.baleLoader.synchronization#maxPosition\'", v127_, v130_, v131_, v132_, v121_.synchronizationMaxPosition)
					end
					local v133_ = 2 ^ v121_.synchronizationNumBitsPosition - 1
					streamWriteUIntN(streamId, (v121_.synchronizationMaxPosition + v130_) / (v121_.synchronizationMaxPosition * 2) * v133_, v121_.synchronizationNumBitsPosition)
					streamWriteUIntN(streamId, (v121_.synchronizationMaxPosition + v131_) / (v121_.synchronizationMaxPosition * 2) * v133_, v121_.synchronizationNumBitsPosition)
					streamWriteUIntN(streamId, (v121_.synchronizationMaxPosition + v132_) / (v121_.synchronizationMaxPosition * 2) * v133_, v121_.synchronizationNumBitsPosition)
				end
			end
		end
	end
end

-- Local values: spec, moverActive
function BaleLoader:onReadUpdateStream(streamId, timestamp, connection)
	local v137_ = self.spec_baleLoader
	if connection:getIsServer() and streamReadBool(streamId) then
		local v138_ = streamReadBool(streamId)
		if v138_ ~= v137_.unloadingMover.isActive then
			if v138_ then
				g_animationManager:startAnimations(v137_.unloadingMover.animationNodes)
				g_soundManager:playSample(v137_.samples.unload)
			else
				g_animationManager:stopAnimations(v137_.unloadingMover.animationNodes)
				g_soundManager:stopSample(v137_.samples.unload)
			end
			v137_.unloadingMover.isActive = v138_
		end
	end
end

-- Local values: spec
function BaleLoader:onWriteUpdateStream(streamId, connection, dirtyMask)
	local v143_ = self.spec_baleLoader
	if not connection:getIsServer() then
		local v144_ = streamWriteBool
		local v145_ = v143_.unloadingMover.dirtyFlag
		if v144_(streamId, bit32.band(dirtyMask, v145_) ~= 0) then
			streamWriteBool(streamId, v143_.unloadingMover.isActive)
		end
	end
end

-- Local values: spec, delta, numBalePlaces
function BaleLoader:updateBalePlacesAnimations()
	local v147_ = self.spec_baleLoader
	if v147_.startBalePlace ~= nil and v147_.startBalePlace.current > v147_.startBalePlace.numOfPlaces or v147_.animations.moveBalePlacesAfterRotatePlatform and v147_.startBalePlace.current > 1 then
		local v148_ = #v147_.balePlaces
		local v149_ = v147_.animations.moveBalePlacesAfterRotatePlatform and not (v147_.animations.moveBalePlacesAlways or v147_.useBalePlaceAsLoadPosition) and 0 or 1
		if v147_.useBalePlaceAsLoadPosition then
			v148_ = v148_ - 1
			v149_ = v149_ + v147_.balePlaceOffset
		end
		self:playAnimation(v147_.animations.moveBalePlaces, 1, 0, true)
		local v150_ = v147_.animations.moveBalePlaces
		local v151_ = (v147_.startBalePlace.current - v149_) / v148_
		self:setAnimationStopTime(v150_, (math.min(v151_, 1)))
		AnimatedVehicle.updateAnimations(self, 99999999, true)
	end
	if v147_.startBalePlace ~= nil and v147_.startBalePlace.count >= 1 then
		self:playAnimation(v147_.animations.balesToOtherRow, 20, nil, true)
		AnimatedVehicle.updateAnimations(self, 99999999, true)
		if v147_.startBalePlace.count >= v147_.startBalePlace.numOfPlaces then
			BaleLoader.rotatePlatform(self)
		end
	end
end

-- Local values: spec, k, baleToMount, bale, x, y, z, rx, ry, rz, baleType, nearestBale, nearestBaleType, warning, name, name, bale
function BaleLoader:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v153_ = self.spec_baleLoader
	if self.finishedFirstUpdate then
		for v154_, v155_ in pairs(v153_.balesToMount) do
			local v156_ = NetworkUtil.getObject(v155_.serverId)
			if v156_ ~= nil then
				local v157_ = v155_.trans
				local v158_, v159_, v160_ = unpack(v157_)
				local v161_ = v155_.rot
				local v162_, v163_, v164_ = unpack(v161_)
				if v153_.dynamicMount.enabled then
					self:mountDynamicBale(v156_, v155_.linkNode)
				else
					self:mountBale(v156_, self, v155_.linkNode, v158_, v159_, v160_, v162_, v163_, v164_)
				end
				local v165_ = self:getBaleTypeByBale(v156_)
				if v165_ ~= nil then
					self:setBaleLoaderBaleType(v165_.index)
				end
				v153_.balesToMount[v154_] = nil
			end
		end
	end
	if self.isClient and (v153_.grabberEffectDisableTime ~= 0 and v153_.grabberEffectDisableTime < g_currentMission.time) then
		g_effectManager:stopEffects(v153_.grabberEffects)
		v153_.grabberEffectDisableTime = 0
	end
	if v153_.grabberIsMoving and not self:getIsBaleLoaderFoldingPlaying() then
		v153_.grabberIsMoving = false
	end
	v153_.showBaleNotSupportedWarning = false
	if self:getIsBaleGrabbingAllowed() and (v153_.baleGrabber.grabNode ~= nil and v153_.baleGrabber.currentBale == nil) then
		local v166_, v167_, v168_ = BaleLoader.getBaleInRange(self, v153_.baleGrabber.grabNode, v153_.baleGrabber.balesInTrigger)
		if v166_ ~= nil then
			if v167_ == nil then
				v153_.showBaleNotSupportedWarning = true
				v153_.baleNotSupportedWarning = v168_
			elseif self.isServer then
				self:pickupBale(v166_, v167_)
			end
		end
	end
	if self.isServer then
		if v153_.grabberMoveState ~= nil then
			if v153_.grabberMoveState == BaleLoader.GRAB_MOVE_UP then
				if not self:getIsAnimationPlaying(v153_.animations.baleGrabberWorkToDrop) then
					g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_GRAB_MOVE_UP), true, nil, self)
				end
			elseif v153_.grabberMoveState == BaleLoader.GRAB_DROP_BALE then
				if not self:getIsAnimationPlaying(v153_.currentBaleGrabberDropBaleAnimName) then
					g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_GRAB_DROP_BALE), true, nil, self)
				end
			elseif v153_.grabberMoveState == BaleLoader.GRAB_MOVE_DOWN and not self:getIsAnimationPlaying(v153_.animations.baleGrabberDropToWork or v153_.animations.baleGrabberWorkToDrop) then
				g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_GRAB_MOVE_DOWN), true, nil, self)
				self:setAnimationTime(v153_.currentBaleGrabberDropBaleAnimName, 0, false)
				self:setAnimationTime(v153_.animations.baleGrabberWorkToDrop, 0, false)
			end
		end
		if v153_.frontBalePusherDirection ~= 0 and not self:getIsAnimationPlaying(v153_.animations.frontBalePusher) then
			g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_FRONT_PUSHER), true, nil, self)
		end
		if v153_.rotatePlatformDirection ~= 0 then
			local v169_ = v153_.animations.rotatePlatform
			if v153_.rotatePlatformDirection < 0 then
				v169_ = v153_.animations.rotatePlatformBack
			end
			if not (self:getIsAnimationPlaying(v169_) or (self:getIsAnimationPlaying(v153_.animations.moveBalePlacesExtrasOnce) or v153_.moveBalePlacesDelayedMovement)) then
				g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_ROTATE_PLATFORM), true, nil, self)
			end
		end
		if v153_.emptyState ~= BaleLoader.EMPTY_NONE then
			if v153_.emptyState == BaleLoader.EMPTY_TO_WORK then
				if not self:getIsBaleLoaderFoldingPlaying() then
					g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_ROTATE_PLATFORM), true, nil, self)
				end
			elseif v153_.emptyState == BaleLoader.EMPTY_ROTATE_PLATFORM then
				if not self:getIsAnimationPlaying(v153_.animations.rotatePlatformEmpty) then
					g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_ROTATE1), true, nil, self)
				end
			elseif v153_.emptyState == BaleLoader.EMPTY_ROTATE1 then
				if not (self:getIsAnimationPlaying(v153_.animations.emptyRotate) or self:getIsAnimationPlaying(v153_.animations.moveBalePlacesToEmpty)) then
					g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_CLOSE_GRIPPERS), true, nil, self)
				end
			elseif v153_.emptyState == BaleLoader.EMPTY_CLOSE_GRIPPERS then
				if not self:getIsAnimationPlaying(v153_.animations.closeGrippers) then
					g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_HIDE_PUSHER1), true, nil, self)
				end
			elseif v153_.emptyState == BaleLoader.EMPTY_HIDE_PUSHER1 then
				if not self:getIsAnimationPlaying(v153_.animations.pusherEmptyHide1) then
					g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_HIDE_PUSHER2), true, nil, self)
				end
			elseif v153_.emptyState == BaleLoader.EMPTY_HIDE_PUSHER2 then
				if self:getAnimationTime(v153_.animations.pusherMoveToEmpty) < 0.7 or not self:getIsAnimationPlaying(v153_.animations.pusherMoveToEmpty) then
					g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_ROTATE2), true, nil, self)
				end
			elseif v153_.emptyState == BaleLoader.EMPTY_ROTATE2 then
				if not self:getIsAnimationPlaying(v153_.animations.emptyRotate) then
					g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_WAIT_TO_DROP), true, nil, self)
				end
			elseif v153_.emptyState == BaleLoader.EMPTY_SINK then
				if not (self:getIsAnimationPlaying(v153_.animations.emptyRotate) or (self:getIsAnimationPlaying(v153_.animations.moveBalePlacesToEmpty) or (self:getIsAnimationPlaying(v153_.animations.pusherEmptyHide1) or self:getIsAnimationPlaying(v153_.animations.rotatePlatformEmpty)))) then
					g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_STATE_NIL), true, nil, self)
				end
			elseif v153_.emptyState == BaleLoader.EMPTY_CANCEL and not self:getIsAnimationPlaying(v153_.animations.emptyRotate) then
				g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_WAIT_TO_REDO), true, nil, self)
			end
		end
	end
	if v153_.baleGrabber.currentBaleIsUnmounted then
		v153_.baleGrabber.currentBaleIsUnmounted = false
		local v170_ = NetworkUtil.getObject(v153_.baleGrabber.currentBale)
		if v170_ ~= nil then
			if v153_.dynamicMount.enabled then
				self:mountDynamicBale(v170_, v153_.baleGrabber.grabNode)
			else
				self:mountBale(v170_, self, v153_.baleGrabber.grabNode, 0, 0, 0, 0, 0, 0)
			end
			v170_:setCanBeSold(false)
		end
	end
end

-- Local values: spec, actionEvent, showAction, showAction, unloadTrigger, _, bales, unloadingAllowed, i, bale, isPlaying, removeJoints, animation, i, i, jointNodePositionChanged, i, jointNode, qx, qy, qz, qw, qx, qy, qz, qw, x, y, z, move, moveValue, old, limit, old, limit, anyAnimationPlaying, name, _, _, balePlace, _, baleServerId, bale, mass, _, baleServerId, bale, mass, bale, balePlacesTime, duration, startTime, speedFactor, speed
function BaleLoader:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v173_ = self.spec_baleLoader
	if self.isClient then
		local v174_ = v173_.actionEvents[InputAction.IMPLEMENT_EXTRA]
		if v174_ ~= nil then
			local v175_
			if v173_.emptyState == BaleLoader.EMPTY_NONE and v173_.grabberMoveState == nil then
				if v173_.isInWorkPosition then
					g_inputBinding:setActionEventText(v174_.actionEventId, v173_.texts.transportPosition)
					v175_ = true
				else
					g_inputBinding:setActionEventText(v174_.actionEventId, v173_.texts.operatingPosition)
					v175_ = true
				end
			else
				v175_ = false
			end
			g_inputBinding:setActionEventActive(v174_.actionEventId, v175_)
		end
		local v176_ = v173_.actionEvents[InputAction.IMPLEMENT_EXTRA2]
		if v176_ ~= nil then
			g_inputBinding:setActionEventActive(v176_.actionEventId, v173_.emptyState == BaleLoader.EMPTY_WAIT_TO_DROP)
		end
		local v177_ = v173_.actionEvents[InputAction.IMPLEMENT_EXTRA3]
		if v177_ ~= nil then
			local v178_ = false
			if v173_.emptyState == BaleLoader.EMPTY_NONE then
				if BaleLoader.getAllowsStartUnloading(self) then
					g_inputBinding:setActionEventText(v177_.actionEventId, v173_.texts.unload)
					v178_ = true
				end
			elseif v173_.emptyState == BaleLoader.EMPTY_WAIT_TO_DROP then
				g_inputBinding:setActionEventText(v177_.actionEventId, v173_.texts.unloadHere)
				v178_ = true
			elseif v173_.emptyState == BaleLoader.EMPTY_WAIT_TO_SINK then
				if not v173_.unloadingMover.isActive then
					g_inputBinding:setActionEventText(v177_.actionEventId, v173_.texts.lowerPlattform)
					v178_ = true
				end
			elseif v173_.emptyState == BaleLoader.EMPTY_WAIT_TO_REDO then
				g_inputBinding:setActionEventText(v177_.actionEventId, v173_.texts.unload)
				v178_ = true
			end
			g_inputBinding:setActionEventActive(v177_.actionEventId, v178_)
		end
	end
	if self.isServer then
		if Platform.gameplay.automaticBaleDrop then
			local v179_, _ = next(v173_.baleUnloadTriggers)
			if v179_ ~= nil and self:getIsAutomaticBaleUnloadingAllowed() then
				local v180_ = self:getLoadedBales()
				local v181_ = false
				for _, v182_ in ipairs(v180_) do
					if v179_:getIsBaleSupportedByUnloadTrigger(v182_) then
						v181_ = true
						break
					end
				end
				if v181_ and BaleLoader.getAllowsStartUnloading(self) then
					self:startAutomaticBaleUnloading()
				end
			end
		end
		if v173_.fullAutomaticUnloading and (self:getFillUnitFillLevelPercentage(v173_.fillUnitIndex) == 1 or v173_.automaticUnloadingAdditionalBalesToLoad == 0) and BaleLoader.getAllowsStartUnloading(self) then
			self:startAutomaticBaleUnloading()
		end
		if v173_.automaticUnloading or v173_.automaticUnloadingInProgress then
			if v173_.emptyState == BaleLoader.EMPTY_WAIT_TO_DROP then
				self:doStateChange(BaleLoader.CHANGE_BUTTON_EMPTY)
			end
			local v183_ = self:getIsAnimationPlaying(v173_.animations.releaseFrontPlatform)
			if v173_.emptyState == BaleLoader.EMPTY_WAIT_TO_SINK and not (v183_ or v173_.unloadingMover.isActive) then
				self:doStateChange(BaleLoader.CHANGE_SINK)
			end
		end
		if #v173_.baleJoints > 0 then
			local v184_ = v173_.dynamicBaleUnloading.useUnloadingMoverTrigger and (v173_.unloadingMover.frameDelay == 0 and next(v173_.unloadingMover.balesInTrigger) == nil) and true or false
			if v173_.dynamicBaleUnloading.useUnloadingMoverTrigger == nil or v184_ then
				v184_ = false
				if v173_.dynamicBaleUnloading.releaseAnimation ~= nil then
					local v185_ = v173_.dynamicBaleUnloading.releaseAnimation
					v184_ = (self:getAnimationTime(v185_) >= v173_.dynamicBaleUnloading.releaseAnimationTime or not self:getIsAnimationPlaying(v185_)) and true or v184_
				end
			end
			if v184_ then
				for v186_ = #v173_.baleJoints, 1, -1 do
					removeJoint(v173_.baleJoints[v186_])
					v173_.baleJoints[v186_] = nil
				end
			end
		end
		if v173_.unloadingMover.isActive then
			local v187_ = v173_.unloadingMover
			local v188_ = v173_.unloadingMover.frameDelay - 1
			v187_.frameDelay = math.max(v188_, 0)
			if v173_.unloadingMover.frameDelay == 0 and next(v173_.unloadingMover.balesInTrigger) == nil then
				v173_.unloadingMover.isActive = false
				for v189_ = 1, #v173_.unloadingMover.nodes do
					setFrictionVelocity(v173_.unloadingMover.nodes[v189_].node, 0)
				end
				if self.isClient then
					g_animationManager:stopAnimations(v173_.unloadingMover.animationNodes)
					g_soundManager:stopSample(v173_.samples.unload)
				end
				self:raiseDirtyFlags(v173_.unloadingMover.dirtyFlag)
			end
		end
		if v173_.dynamicMount.enabled then
			local v190_ = false
			for v191_, v192_ in ipairs(v173_.dynamicMount.baleJointsToUpdate) do
				if v192_.quaternion == nil then
					local v193_, v194_, v195_, v196_ = getQuaternion(v192_.node)
					v192_.quaternion = {
						v193_,
						v194_,
						v195_,
						v196_
					}
				end
				if v192_.time < v173_.dynamicMount.jointInterpolationTimeRot then
					v192_.time = v192_.time + dt
					local v197_ = 0
					local v198_ = 0
					local v199_ = 0
					local v200_ = 1
					local v201_ = v192_.quaternion[2]
					if math.abs(v201_) > 0.5 then
						v197_, v198_, v199_, v200_ = MathUtil.slerpQuaternionShortestPath(v192_.quaternion[1], v192_.quaternion[2], v192_.quaternion[3], v192_.quaternion[4], 0, 1, 0, 0, v192_.time / v173_.dynamicMount.jointInterpolationTimeRot)
					else
						local v202_ = v192_.quaternion[2]
						if math.abs(v202_) < 0.5 then
							v197_, v198_, v199_, v200_ = MathUtil.slerpQuaternionShortestPath(v192_.quaternion[1], v192_.quaternion[2], v192_.quaternion[3], v192_.quaternion[4], 0, 0, 0, 1, v192_.time / v173_.dynamicMount.jointInterpolationTimeRot)
						end
					end
					setQuaternion(v192_.node, v197_, v198_, v199_, v200_)
					v190_ = true
				end
				local v203_, v204_, v205_ = getTranslation(v192_.node)
				if math.abs(v203_) + math.abs(v204_) + math.abs(v205_) > 0.001 then
					local v_u_206_ = v173_.dynamicMount.jointInterpolationSpeedTrans * dt
					setTranslation(v192_.node, (math.sign(v203_) > 0 and math.max or math.min)(v203_ - math.sign(v203_) * v_u_206_, 0), (math.sign(v204_) > 0 and math.max or math.min)(v204_ - math.sign(v204_) * v_u_206_, 0), (function(p207_)
						-- upvalues: (copy) v_u_206_
						return (math.sign(p207_) > 0 and math.max or math.min)(p207_ - math.sign(p207_) * v_u_206_, 0)
					end)(v205_))
					v190_ = true
				elseif v192_.time > v173_.dynamicMount.jointInterpolationTimeRot then
					table.remove(v173_.dynamicMount.baleJointsToUpdate, v191_)
				end
			end
			local v208_ = false
			for v209_, _ in pairs(self.spec_animatedVehicle.animations) do
				if self:getIsAnimationPlaying(v209_) then
					v208_ = true
				end
			end
			if v208_ or (v190_ or v173_.dynamicMount.baleMassDirty) then
				for _, v210_ in pairs(v173_.balePlaces) do
					if v210_.bales ~= nil then
						for _, v211_ in pairs(v210_.bales) do
							local v212_ = NetworkUtil.getObject(v211_)
							if v212_ ~= nil then
								if v212_.dynamicMountJointIndex ~= nil then
									setJointFrame(v212_.dynamicMountJointIndex, 0, v212_.baleLoaderDynamicJointNode)
								end
								if v212_.backupMass == nil then
									local v213_ = getMass(v212_.nodeId)
									if v213_ ~= 1 then
										v212_.backupMass = v213_
										setMass(v212_.nodeId, 0.1)
										v173_.dynamicMount.baleMassDirty = false
									end
								end
							end
						end
					end
				end
				if v173_.startBalePlace ~= nil then
					for _, v214_ in ipairs(v173_.startBalePlace.bales) do
						local v215_ = NetworkUtil.getObject(v214_)
						if v215_ ~= nil then
							if v215_.dynamicMountJointIndex ~= nil then
								setJointFrame(v215_.dynamicMountJointIndex, 0, v215_.baleLoaderDynamicJointNode)
							end
							if v215_.backupMass == nil then
								local v216_ = getMass(v215_.nodeId)
								if v216_ ~= 1 then
									v215_.backupMass = v216_
									setMass(v215_.nodeId, 0.1)
									v173_.dynamicMount.baleMassDirty = false
								end
							end
						end
					end
				end
				if v173_.baleGrabber.currentBale ~= nil then
					local v217_ = NetworkUtil.getObject(v173_.baleGrabber.currentBale)
					if v217_ ~= nil and v217_.dynamicMountJointIndex ~= nil then
						setJointFrame(v217_.dynamicMountJointIndex, 0, v217_.baleLoaderDynamicJointNode)
					end
				end
			end
		end
	end
	if v173_.moveBalePlacesDelayedMovement and self:getAnimationTime(v173_.animations.baleGrabberWorkToDrop) < v173_.animations.moveBalePlacesMaxGrabberTime then
		v173_.rotatePlatformDirection = -1
		self:playAnimation(v173_.animations.rotatePlatformBack, -1, nil, true)
		if v173_.animations.moveBalePlacesAfterRotatePlatform and (v173_.startBalePlace ~= nil and v173_.startBalePlace.current <= #v173_.balePlaces or v173_.animations.moveBalePlacesAlways) then
			self:playAnimation(v173_.animations.moveBalePlaces, 1, (v173_.startBalePlace.current - 1) / #v173_.balePlaces, true)
			self:setAnimationStopTime(v173_.animations.moveBalePlaces, v173_.startBalePlace.current / #v173_.balePlaces)
			self:playAnimation(v173_.animations.moveBalePlacesExtrasOnce, 1, nil, true)
		end
		v173_.moveBalePlacesDelayedMovement = nil
	end
	if v173_.animations.moveBalePlacesToEmptyPushOffsetTime > 0 then
		v173_.animations.moveBalePlacesToEmptyPushOffsetTime = v173_.animations.moveBalePlacesToEmptyPushOffsetTime - dt
		if v173_.animations.moveBalePlacesToEmptyPushOffsetTime <= 0 then
			local v218_ = self:getRealAnimationTime(v173_.animations.moveBalePlaces)
			local v219_ = self:getAnimationDuration(v173_.animations.moveBalePlacesToEmpty)
			local v220_ = v218_ / v219_
			local v221_ = (v219_ - v218_) / (v219_ - v218_ - v173_.animations.moveBalePlacesToEmptyPushOffsetDelay * v173_.animations.moveBalePlacesToEmptySpeed)
			local v222_ = v173_.animations.moveBalePlacesToEmptySpeed * v221_
			self:playAnimation(v173_.animations.moveBalePlacesToEmpty, v222_, v220_, true)
			v173_.animations.moveBalePlacesToEmptyPushOffsetTime = 0
		end
	end
end

-- Local values: spec
function BaleLoader:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v224_ = self.spec_baleLoader
	if v224_.showBaleNotSupportedWarning and v224_.baleNotSupportedWarning ~= nil then
		g_currentMission:showBlinkingWarning(v224_.baleNotSupportedWarning, 2000)
	end
end

-- Local values: spec, nearestDistance, nearestBale, nearestBaleType, warning, bale, state, isValidBale, otherBale, _, balePlace, _, baleServerId, baleInPlace, _, baleServerId, baleInPlace, distance, foundBaleType, activeFarmId
function BaleLoader:getBaleInRange(refNode, balesInTrigger)
	local v228_ = self.spec_baleLoader
	local v229_ = v228_.baleGrabber.pickupRange
	local v230_ = v228_.texts.baleNotSupported
	local v231_ = nil
	local v232_ = nil
	for v233_, v234_ in pairs(balesInTrigger) do
		if v234_ ~= nil and v234_ > 0 then
			local v235_ = true
			local v236_ = nil
			for _, v237_ in pairs(v228_.balePlaces) do
				if v237_.bales ~= nil then
					for _, v238_ in pairs(v237_.bales) do
						v236_ = NetworkUtil.getObject(v238_)
						if v236_ ~= nil and v236_ == v233_ then
							v235_ = false
						end
					end
				end
			end
			if v228_.startBalePlace ~= nil then
				for _, v239_ in ipairs(v228_.startBalePlace.bales) do
					v236_ = NetworkUtil.getObject(v239_)
					if v236_ ~= nil and v236_ == v233_ then
						v235_ = false
					end
				end
			end
			if v233_ == nil or not entityExists(v233_.nodeId) then
				v235_ = false
			end
			if v235_ then
				local v240_ = calcDistanceFrom(refNode, v233_.nodeId)
				if v240_ < v229_ then
					local v241_ = self:getBaleTypeByBale(v233_)
					if v241_ ~= v228_.currentBaleType and self:getFillUnitFillLevel(v228_.currentBaleType.fillUnitIndex) ~= 0 then
						v230_ = v228_.texts.onlyOneBaleTypeWarning
						v241_ = nil
					end
					if v241_ ~= nil and (not v241_.mixedFillTypes and (v236_ ~= nil and v233_:getFillType() ~= v236_:getFillType())) then
						v230_ = v228_.texts.baleDoNotAllowFillTypeMixing
						v241_ = nil
					end
					if v233_:getIsMounted() or v233_.baleJointIndex ~= nil then
						v241_ = nil
						v230_ = nil
					end
					if not v233_:getBaleSupportsBaleLoader() then
						v241_ = nil
					end
					local v242_ = self:getActiveFarm()
					if v242_ ~= v233_.ownerFarmId and (not g_currentMission.accessHandler:canFarmAccessOtherId(v242_, v233_.ownerFarmId) and self.spec_baler == nil) then
						v230_ = v228_.texts.youDoNotOwnBale
						v241_ = nil
					end
					if v241_ ~= nil or v231_ == nil then
						if v241_ == nil then
							v240_ = v229_
						end
						v232_ = v233_
						v229_ = v240_
						v231_ = v241_
					end
				end
			end
		end
	end
	return v232_, v231_, v230_
end

-- Local values: spec
function BaleLoader:onActivate()
	local v244_ = self.spec_baleLoader
	if v244_.isInWorkPosition and not v244_.animationNodesBlocked then
		g_animationManager:startAnimations(v244_.animationNodes)
		g_soundManager:playSample(v244_.samples.work)
	end
end

-- Local values: spec
function BaleLoader:onDeactivate()
	local v246_ = self.spec_baleLoader
	g_effectManager:stopEffects(v246_.grabberEffects)
	g_animationManager:stopAnimations(v246_.animationNodes)
	g_soundManager:stopSample(v246_.samples.work)
end

-- Local values: spec, actionController, finishedFunc
function BaleLoader:onRootVehicleChanged(rootVehicle)
	local v249_ = self.spec_baleLoader
	local v250_ = rootVehicle.actionController
	if v250_ == nil then
		if v249_.controlledAction ~= nil then
			v249_.controlledAction:remove()
		end
		return
	elseif v249_.controlledAction == nil then
		v249_.controlledAction = v250_:registerAction("baleLoaderWorkstate", nil, 4)
		v249_.controlledAction:setCallback(self, BaleLoader.actionControllerEvent)
		v249_.controlledAction:setFinishedFunctions(self, function(p251_)
			return p251_.spec_baleLoader.isInWorkPosition
		end, true, false)
		v249_.controlledAction:addAIEventListener(self, "onAIImplementPrepareForTransport", -1)
	else
		v249_.controlledAction:updateParent(v250_)
	end
end

-- Local values: spec
function BaleLoader:actionControllerEvent(direction)
	local v254_ = self.spec_baleLoader
	if v254_.grabberIsMoving or v254_.grabberMoveState ~= nil or (direction <= 0 or v254_.isInWorkPosition) and (direction >= 0 or not v254_.isInWorkPosition) then
		return false
	end
	BaleLoader.actionEventWorkTransport(self)
	return true
end

-- Local values: spec
function BaleLoader:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillType, toolType, fillPositionData, appliedDelta)
	if fillUnitIndex == self.spec_baleLoader.fillUnitIndex then
		self:updateFoldingAnimation()
	end
end

function BaleLoader:onFoldStateChanged(direction)
	if self.spec_baleLoader.useFoldingState and self.isServer then
		if direction == self.spec_foldable.turnOnFoldDirection then
			g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_MOVE_TO_WORK), true, nil, self)
			return
		end
		g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_MOVE_TO_TRANSPORT), true, nil, self)
	end
end

-- Local values: spec
function BaleLoader:onBalerUnloadingStarted(balesToUnload)
	local v261_ = self.spec_baleLoader
	if v261_.fullAutomaticUnloading then
		v261_.automaticUnloadingAdditionalBalesToLoad = balesToUnload
	end
end

-- Local values: spec
function BaleLoader:onRegisterAnimationValueTypes()
	local v_u_263_ = self.spec_baleLoader
	self:registerAnimationValueType("baleLoaderAnimationNodes", "baleLoaderAnimationNodes", "", false, AnimationValueBool, function(_, _, _)
		return true
	end, function(_)
		-- upvalues: (copy) v_u_263_
		return not v_u_263_.animationNodesBlocked
	end, function(_, p264_)
		-- upvalues: (copy) v_u_263_
		v_u_263_.animationNodesBlocked = not p264_
		if not v_u_263_.animationNodesBlocked and v_u_263_.isInWorkPosition then
			g_animationManager:startAnimations(v_u_263_.animationNodes)
			g_soundManager:playSample(v_u_263_.samples.work)
		end
		if v_u_263_.animationNodesBlocked and v_u_263_.isInWorkPosition then
			g_animationManager:stopAnimations(v_u_263_.animationNodes)
			g_soundManager:stopSample(v_u_263_.samples.work)
		end
	end)
end

-- Local values: spec, getDimensionValue, dimensions
function BaleLoader:loadBaleTypeFromXML(xmlFile, key, baleType)
	local v269_ = self.spec_baleLoader
	local function v280_(p270_, p271_, p272_, p273_, p274_)
		-- upvalues: (copy) xmlFile
		local v275_ = p270_:getValue(p271_ .. "#" .. p272_)
		local v276_ = p270_:getValue(p271_ .. "#" .. p273_)
		local v277_ = p270_:getValue(p271_ .. "#" .. p274_)
		local v278_ = v276_ or (v277_ or v275_)
		local v279_ = v277_ or v278_
		if v278_ ~= nil and v279_ ~= nil then
			return MathUtil.round(v278_, 2), MathUtil.round(v279_, 2)
		end
		Logging.xmlError(xmlFile, "Unable to load bale dimension. \'%s\' is not available in \'%s\'", p272_, p271_)
		return 0, 0
	end
	baleType.dimensions = {}
	local v281_ = baleType.dimensions
	v281_.isRoundbale = (self.xmlFile:getString(key .. "#diameter") ~= nil or self.xmlFile:getString(key .. "#minDiameter") ~= nil) and true or self.xmlFile:getString(key .. "#maxDiameter") ~= nil
	if v281_.isRoundbale then
		local v282_, v283_ = v280_(self.xmlFile, key, "width", "minWidth", "maxWidth")
		v281_.minWidth = v282_
		v281_.maxWidth = v283_
		local v284_, v285_ = v280_(self.xmlFile, key, "diameter", "minDiameter", "maxDiameter")
		v281_.minDiameter = v284_
		v281_.maxDiameter = v285_
	else
		local v286_, v287_ = v280_(self.xmlFile, key, "width", "minWidth", "maxWidth")
		v281_.minWidth = v286_
		v281_.maxWidth = v287_
		local v288_, v289_ = v280_(self.xmlFile, key, "height", "minHeight", "maxHeight")
		v281_.minHeight = v288_
		v281_.maxHeight = v289_
		local v290_, v291_ = v280_(self.xmlFile, key, "length", "minLength", "maxLength")
		v281_.minLength = v290_
		v281_.maxLength = v291_
	end
	baleType.mixedFillTypes = self.xmlFile:getValue(key .. "#mixedFillTypes", true)
	baleType.fillUnitIndex = self.xmlFile:getValue(key .. "#fillUnitIndex", v269_.fillUnitIndex)
	baleType.changeObjects = {}
	ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, key, baleType.changeObjects, self.components, self)
	self:loadBalePlacesFromXML(xmlFile, key, baleType)
	return self:loadBaleLoaderAnimationsFromXML(xmlFile, key, baleType, v269_.defaultAnimations) and true or false
end

-- Local values: default
function BaleLoader:loadBaleLoaderAnimationsFromXML(xmlFile, key, target, defaultTarget)
	target.animations = {}
	local v296_ = target.animations
	if defaultTarget ~= nil then
		v296_ = defaultTarget.animations or target.animations
	end
	target.animations.rotatePlatform = xmlFile:getValue(key .. ".animations.platform#rotate", v296_.rotatePlatform or "rotatePlatform")
	target.animations.rotatePlatformBack = xmlFile:getValue(key .. ".animations.platform#rotateBack", v296_.rotatePlatformBack or "rotatePlatform")
	target.animations.rotatePlatformEmpty = xmlFile:getValue(key .. ".animations.platform#rotateEmpty", v296_.rotatePlatformEmpty or "rotatePlatform")
	target.animations.rotatePlatformAllowPickup = xmlFile:getValue(key .. ".animations.platform#allowPickupWhileMoving", Utils.getNoNil(v296_.rotatePlatformAllowPickup, false))
	target.animations.baleGrabberDropBaleReverseSpeed = xmlFile:getValue(key .. ".animations.baleGrabber#dropBaleReverseSpeed", v296_.baleGrabberDropBaleReverseSpeed or 5)
	target.animations.baleGrabberDropToWork = xmlFile:getValue(key .. ".animations.baleGrabber#dropToWork", v296_.baleGrabberDropToWork)
	target.animations.baleGrabberWorkToDrop = xmlFile:getValue(key .. ".animations.baleGrabber#workToDrop", v296_.baleGrabberWorkToDrop or "baleGrabberWorkToDrop")
	target.animations.baleGrabberDropBale = xmlFile:getValue(key .. ".animations.baleGrabber#dropBale", v296_.baleGrabberDropBale or "baleGrabberDropBale")
	target.animations.baleGrabberTransportToWork = xmlFile:getValue(key .. ".animations.baleGrabber#transportToWork", v296_.baleGrabberTransportToWork or "baleGrabberTransportToWork")
	target.animations.pusherEmptyHide1 = xmlFile:getValue(key .. ".animations.pusher#emptyHide", v296_.pusherEmptyHide1 or "emptyHidePusher1")
	target.animations.pusherMoveToEmpty = xmlFile:getValue(key .. ".animations.pusher#moveToEmpty", v296_.pusherMoveToEmpty or "moveBalePusherToEmpty")
	target.animations.pusherHideOnEmpty = xmlFile:getValue(key .. ".animations.pusher#hidePusherOnEmpty", Utils.getNoNil(v296_.pusherHideOnEmpty, true))
	target.animations.pusherPushBalesOnEmpty = xmlFile:getValue(key .. ".animations.pusher#pushBalesOnEmpty", Utils.getNoNil(v296_.pusherPushBalesOnEmpty, false))
	target.animations.releaseFrontPlatform = xmlFile:getValue(key .. ".animations.releaseFrontPlatform#name", v296_.releaseFrontPlatform or "releaseFrontplattform")
	target.animations.releaseFrontPlatformFillLevelSpeed = xmlFile:getValue(key .. ".animations.releaseFrontPlatform#fillLevelSpeed", Utils.getNoNil(v296_.releaseFrontPlatformFillLevelSpeed, false))
	target.animations.moveBalePlaces = xmlFile:getValue(key .. ".animations.moveBalePlaces#name", v296_.moveBalePlaces or "moveBalePlaces")
	target.animations.moveBalePlacesExtrasOnce = xmlFile:getValue(key .. ".animations.moveBalePlaces#extrasOnce", v296_.moveBalePlacesExtrasOnce or "moveBalePlacesExtrasOnce")
	target.animations.moveBalePlacesToEmpty = xmlFile:getValue(key .. ".animations.moveBalePlaces#empty", v296_.moveBalePlacesToEmpty or "moveBalePlacesToEmpty")
	target.animations.moveBalePlacesToEmptySpeed = xmlFile:getValue(key .. ".animations.moveBalePlaces#emptySpeed", v296_.moveBalePlacesToEmptySpeed or 1.5)
	target.animations.moveBalePlacesToEmptyReverseSpeed = xmlFile:getValue(key .. ".animations.moveBalePlaces#emptyReverseSpeed", v296_.moveBalePlacesToEmptyReverseSpeed or -1)
	target.animations.moveBalePlacesToEmptyPushOffset = xmlFile:getValue(key .. ".animations.moveBalePlaces#pushOffset", v296_.moveBalePlacesToEmptyPushOffset or 0)
	target.animations.moveBalePlacesToEmptyPushOffsetDelay = 0
	target.animations.moveBalePlacesToEmptyPushOffsetTime = 0
	target.animations.moveBalePlacesAfterRotatePlatform = xmlFile:getValue(key .. ".animations.moveBalePlaces#moveAfterRotatePlatform", Utils.getNoNil(v296_.moveBalePlacesAfterRotatePlatform, false))
	target.animations.moveBalePlacesResetOnSink = xmlFile:getValue(key .. ".animations.moveBalePlaces#resetOnSink", Utils.getNoNil(v296_.moveBalePlacesResetOnSink, false))
	target.animations.moveBalePlacesMaxGrabberTime = xmlFile:getValue(key .. ".animations.moveBalePlaces#maxGrabberTime", v296_.moveBalePlacesMaxGrabberTime or math.huge)
	target.animations.moveBalePlacesAlways = xmlFile:getValue(key .. ".animations.moveBalePlaces#alwaysMove", Utils.getNoNil(v296_.moveBalePlacesAlways, false))
	target.animations.emptyRotate = xmlFile:getValue(key .. ".animations.emptyRotate#name", v296_.emptyRotate or "emptyRotate")
	target.animations.emptyRotateReset = xmlFile:getValue(key .. ".animations.emptyRotate#reset", Utils.getNoNil(v296_.emptyRotateReset, true))
	target.animations.frontBalePusher = xmlFile:getValue(key .. ".animations#frontBalePusher", v296_.frontBalePusher or "frontBalePusher")
	target.animations.balesToOtherRow = xmlFile:getValue(key .. ".animations#balesToOtherRow", v296_.balesToOtherRow or "balesToOtherRow")
	target.animations.closeGrippers = xmlFile:getValue(key .. ".animations#closeGrippers", v296_.closeGrippers or "closeGrippers")
	return true
end

-- Local values: useSharedBalePlaces, i, node, i, balePlaceKey, node, entry
function BaleLoader:loadBalePlacesFromXML(xmlFile, key, target)
	local v300_ = true
	target.startBalePlace = {}
	target.startBalePlace.bales = {}
	target.startBalePlace.node = self.xmlFile:getValue(key .. ".balePlaces#startBalePlace", nil, self.components, self.i3dMappings)
	if target.startBalePlace.node == nil then
		target.startBalePlace.numOfPlaces = 0
		v300_ = false
	else
		target.startBalePlace.numOfPlaces = getNumOfChildren(target.startBalePlace.node)
		if target.startBalePlace.numOfPlaces == 0 then
			target.startBalePlace.node = nil
		else
			target.startBalePlace.origRot = {}
			target.startBalePlace.origTrans = {}
			for v301_ = 1, target.startBalePlace.numOfPlaces do
				local v302_ = getChildAt(target.startBalePlace.node, v301_ - 1)
				target.startBalePlace.origRot[v301_] = { getRotation(v302_) }
				target.startBalePlace.origTrans[v301_] = { getTranslation(v302_) }
			end
		end
	end
	target.startBalePlace.count = 0
	target.startBalePlace.current = 1
	target.balePlaces = {}
	local v303_ = 0
	while true do
		local v304_ = string.format("%s.balePlaces.balePlace(%d)", key, v303_)
		if not self.xmlFile:hasProperty(v304_) then
			break
		end
		local v305_ = self.xmlFile:getValue(v304_ .. "#node", nil, self.components, self.i3dMappings)
		if v305_ ~= nil then
			local v306_ = target.balePlaces
			table.insert(v306_, {
				["node"] = v305_
			})
		end
		v303_ = v303_ + 1
	end
	if #target.balePlaces == 0 then
		v300_ = false
	end
	return v300_
end

-- Local values: dynamicBaleUnloading, lineRotLimit, sideRotLimit, lineIndex, bales, isRoundbale, i, _, connection, bales2, _, connection, bales2
function BaleLoader:createBaleToBaleJoints(baleLines)
	if #baleLines > 1 then
		local v309_ = self.spec_baleLoader.dynamicBaleUnloading
		local v310_ = v309_.rowConnectionRotLimit
		local v311_ = v309_.rowInterConnectionRotLimit
		for v312_, v313_ in ipairs(baleLines) do
			local v314_ = v313_[1].isRoundbale
			if v309_.connectedRows[v312_] then
				for v315_ = 1, #v313_ - 1 do
					if v314_ then
						self:createBaleToBaleJoint(v313_[v315_], v313_[v315_ + 1], 0, v309_.heightOffset, v313_[v315_].width + v309_.widthOffset, v310_, 0, 0, v315_)
					else
						self:createBaleToBaleJoint(v313_[v315_], v313_[v315_ + 1], v313_[v315_].width + v309_.widthOffset, v309_.heightOffset, 0, 0, 0, v310_ * 5, v315_)
					end
				end
			end
			for _, v316_ in ipairs(v309_.interConnectedRowStarts) do
				if v316_[1] == v312_ then
					local v317_ = baleLines[v316_[2]]
					if v317_ ~= nil then
						if v314_ then
							self:createBaleToBaleJoint(v313_[1], v317_[1], v313_[1].diameter + v309_.diameterOffset, v309_.heightOffset, 0, v311_, v311_, v311_, 1)
						else
							self:createBaleToBaleJoint(v313_[1], v317_[1], 0, v313_[1].height + 0.05, 0, v310_, 0, 0, 1)
						end
					end
				end
			end
			for _, v318_ in ipairs(v309_.interConnectedRowEnds) do
				if v318_[1] == v312_ then
					local v319_ = baleLines[v318_[2]]
					if v319_ ~= nil and #v313_ == #v319_ then
						if v314_ then
							self:createBaleToBaleJoint(v313_[#v313_], v319_[#v319_], v313_[#v313_].diameter + v309_.diameterOffset, v309_.heightOffset, 0, v311_, v311_, v311_, #v313_)
						else
							self:createBaleToBaleJoint(v313_[#v313_], v319_[#v319_], 0, v313_[#v313_].height + 0.05, 0, v310_, 0, 0, #v313_)
						end
					end
				end
			end
		end
	end
end

-- Local values: spec, balePlaceRot, constr, jointTransform1, jointTransform2, jointIndex
function BaleLoader:createBaleToBaleJoint(bale1, bale2, x, y, z, rx, ry, rz, balePlaceIndex)
	local v330_ = self.spec_baleLoader
	local v331_ = v330_.balePlaces[balePlaceIndex].node
	local v332_ = JointConstructor.new()
	v332_:setActors(bale1.nodeId, bale2.nodeId)
	local v333_ = createTransformGroup("jointTransform1")
	link(bale1.nodeId, v333_)
	setRotation(v333_, localRotationToLocal(v331_, bale1.nodeId, 0, 0, 0))
	local v334_ = createTransformGroup("jointTransform2")
	link(bale2.nodeId, v334_)
	setRotation(v334_, localRotationToLocal(v331_, bale2.nodeId, 0, 0, 0))
	v332_:setJointTransforms(v333_, v334_)
	v332_:setEnableCollision(true)
	v332_:setRotationLimit(0, -rx, rx)
	v332_:setRotationLimit(1, -ry, ry)
	v332_:setRotationLimit(2, -rz, rz)
	v332_:setTranslationLimit(0, true, -x, x)
	v332_:setTranslationLimit(1, true, -y, y)
	v332_:setTranslationLimit(2, true, -z, z)
	local v335_ = v332_:finalize()
	local v336_ = v330_.baleJoints
	table.insert(v336_, v335_)
end

-- Local values: spec, baleLines, packBales, packedFarmId, packedFillType, packedFillLevel, _, balePlace, i, baleServerId, bale, baleObject, x, y, z, rx, ry, rz, speed, fillLevel, capacity, fillRatio, i, unloadingMoverNode, bale, baleType, attachNode, bale, rx, ry, rz, balePlace, i, node, x, y, z, rx, ry, rz, baleServerId, bale, i, node, balePlacesTime, pusherAnimSpeed, usedPlaces, animDuration, placeTargetTime, pusherTargetTime, targetTime, animDuration, allowOffset, lastPlace, targetTime, animDuration
function BaleLoader:doStateChange(id, nearestBaleServerId)
	local v340_ = self.spec_baleLoader
	if id == BaleLoader.CHANGE_DROP_BALES then
		local v341_ = {}
		if v340_.startBalePlace ~= nil then
			v340_.startBalePlace.current = 1
		end
		local v342_
		if v340_.balePacker.node == nil then
			v342_ = false
		else
			v342_ = v340_.balePacker.filename ~= nil
		end
		local v343_ = FarmManager.SPECTATOR_FARM_ID
		local v344_ = FillType.UNKNOWN
		local v345_ = 0
		for _, v346_ in pairs(v340_.balePlaces) do
			if v346_.bales ~= nil then
				for v347_, v348_ in pairs(v346_.bales) do
					local v349_ = NetworkUtil.getObject(v348_)
					if v349_ ~= nil then
						if v340_.dynamicMount.enabled then
							self:unmountDynamicBale(v349_)
						else
							self:unmountBale(v349_)
						end
						v349_:setCanBeSold(true)
						if v340_.baleGrabber.balesInTrigger[v349_] ~= nil then
							v340_.baleGrabber.balesInTrigger[v349_] = nil
						end
						if v340_.dynamicBaleUnloading.enabled then
							if v341_[v347_] == nil then
								table.insert(v341_, { v349_ })
							else
								local v350_ = v341_[v347_]
								table.insert(v350_, v349_)
							end
						end
						if v342_ then
							v343_ = v349_.ownerFarmId
							v344_ = v349_.fillType
							v345_ = v345_ + v349_.fillLevel
							v349_:delete()
						end
					end
					v340_.balesToMount[v348_] = nil
				end
				v346_.bales = nil
			end
		end
		if self.isServer and v342_ then
			local v351_ = PackedBale.new(self.isServer, self.isClient)
			local v352_, v353_, v354_ = getWorldTranslation(v340_.balePacker.node)
			local v355_, v356_, v357_ = getWorldRotation(v340_.balePacker.node)
			if v351_:loadFromConfigXML(v340_.balePacker.filename, v352_, v353_, v354_, v355_, v356_, v357_) then
				v351_:setFillType(v344_)
				v351_:setFillLevel(v345_)
				v351_:setOwnerFarmId(v343_, true)
				v351_:register()
				removeFromPhysics(v351_.nodeId)
				addToPhysics(v351_.nodeId)
			end
		end
		if v340_.dynamicBaleUnloading.enabled then
			self:createBaleToBaleJoints(v341_)
		end
		local v358_ = 1
		if v340_.animations.releaseFrontPlatformFillLevelSpeed then
			local v359_ = self:getFillUnitFillLevel(v340_.fillUnitIndex) / self:getFillUnitCapacity(v340_.fillUnitIndex)
			if v359_ > 0 then
				v358_ = 1 / v359_
			end
		end
		self:addFillUnitFillLevel(self:getOwnerFarmId(), v340_.fillUnitIndex, -math.huge, self:getFillUnitFirstSupportedFillType(v340_.fillUnitIndex), ToolType.UNDEFINED, nil)
		if self.isServer and v340_.unloadingMover.trigger ~= nil then
			v340_.unloadingMover.isActive = true
			v340_.unloadingMover.frameDelay = 3
			for v360_ = 1, #v340_.unloadingMover.nodes do
				local v361_ = v340_.unloadingMover.nodes[v360_]
				setFrictionVelocity(v361_.node, v361_.speed)
			end
			if self.isClient then
				g_animationManager:startAnimations(v340_.unloadingMover.animationNodes)
				g_soundManager:playSample(v340_.samples.unload)
			end
			self:raiseDirtyFlags(v340_.unloadingMover.dirtyFlag)
		end
		self:playAnimation(v340_.animations.releaseFrontPlatform, v358_, nil, true)
		self:playAnimation(v340_.animations.closeGrippers, -1, nil, true)
		v340_.emptyState = BaleLoader.EMPTY_WAIT_TO_SINK
		return
	elseif id == BaleLoader.CHANGE_SINK then
		if v340_.animations.emptyRotateReset then
			self:playAnimation(v340_.animations.emptyRotate, -1, nil, true)
		end
		self:playAnimation(v340_.animations.moveBalePlacesToEmpty, v340_.animations.moveBalePlacesToEmptyReverseSpeed, nil, true)
		if v340_.animations.moveBalePlacesResetOnSink then
			self:playAnimation(v340_.animations.moveBalePlaces, -999999, nil, true)
		end
		self:playAnimation(v340_.animations.pusherEmptyHide1, -1, nil, true)
		self:playAnimation(v340_.animations.rotatePlatformEmpty, -1, nil, true)
		if not v340_.isInWorkPosition then
			self:playAnimation(v340_.animations.closeGrippers, 1, self:getAnimationTime(v340_.animations.closeGrippers), true)
		end
		v340_.emptyState = BaleLoader.EMPTY_SINK
		return
	elseif id == BaleLoader.CHANGE_EMPTY_REDO then
		self:playAnimation(v340_.animations.emptyRotate, 1, nil, true)
		v340_.emptyState = BaleLoader.EMPTY_ROTATE2
		return
	elseif id == BaleLoader.CHANGE_EMPTY_START then
		if GS_IS_MOBILE_VERSION then
			if self.rootVehicle:getActionControllerDirection() > 0 then
				v340_.controlledAction.parent:startActionSequence()
			end
			v340_.emptyState = BaleLoader.EMPTY_TO_WORK
		else
			BaleLoader.moveToWorkPosition(self)
			v340_.emptyState = BaleLoader.EMPTY_TO_WORK
		end
	elseif id == BaleLoader.CHANGE_EMPTY_CANCEL then
		self:playAnimation(v340_.animations.emptyRotate, -1, nil, true)
		v340_.emptyState = BaleLoader.EMPTY_CANCEL
	elseif id == BaleLoader.CHANGE_MOVE_TO_TRANSPORT then
		if v340_.isInWorkPosition then
			v340_.grabberIsMoving = true
			v340_.isInWorkPosition = false
			g_animationManager:stopAnimations(v340_.animationNodes)
			g_soundManager:stopSample(v340_.samples.work)
			BaleLoader.moveToTransportPosition(self)
			return
		end
	elseif id == BaleLoader.CHANGE_MOVE_TO_WORK then
		if not v340_.isInWorkPosition then
			v340_.grabberIsMoving = true
			v340_.isInWorkPosition = true
			if not v340_.animationNodesBlocked then
				g_animationManager:startAnimations(v340_.animationNodes)
				g_soundManager:playSample(v340_.samples.work)
			end
			BaleLoader.moveToWorkPosition(self)
			return
		end
	elseif id == BaleLoader.CHANGE_GRAB_BALE then
		local v362_ = NetworkUtil.getObject(nearestBaleServerId)
		v340_.baleGrabber.currentBale = nearestBaleServerId
		if v362_ == nil then
			v340_.balesToMount[nearestBaleServerId] = {
				["serverId"] = nearestBaleServerId,
				["linkNode"] = v340_.baleGrabber.grabNode,
				["trans"] = { 0, 0, 0 },
				["rot"] = { 0, 0, 0 }
			}
		else
			if v340_.dynamicMount.enabled then
				self:mountDynamicBale(v362_, v340_.baleGrabber.grabNode)
			else
				self:mountBale(v362_, self, v340_.baleGrabber.grabNode, 0, 0, 0, 0, 0, 0, true)
			end
			v362_:setCanBeSold(false)
			local v363_ = self:getBaleTypeByBale(v362_)
			if v363_ ~= nil then
				self:setBaleLoaderBaleType(v363_.index)
			end
			v340_.balesToMount[nearestBaleServerId] = nil
		end
		v340_.grabberMoveState = BaleLoader.GRAB_MOVE_UP
		self:playAnimation(v340_.animations.baleGrabberWorkToDrop, 1, nil, true)
		self:addFillUnitFillLevel(self:getOwnerFarmId(), v340_.fillUnitIndex, 1, self:getFillUnitFirstSupportedFillType(v340_.fillUnitIndex), ToolType.UNDEFINED, nil)
		if self.isClient then
			g_soundManager:playSample(v340_.samples.grab)
			if v362_ ~= nil then
				g_effectManager:setEffectTypeInfo(v340_.grabberEffects, v362_:getFillType())
				g_effectManager:startEffects(v340_.grabberEffects)
				v340_.grabberEffectDisableTime = g_currentMission.time + v340_.grabberEffectDisableDuration
				return
			end
		end
	else
		if id == BaleLoader.CHANGE_GRAB_MOVE_UP then
			v340_.currentBaleGrabberDropBaleAnimName = self:getBaleGrabberDropBaleAnimName()
			self:playAnimation(v340_.currentBaleGrabberDropBaleAnimName, 1, nil, true)
			v340_.grabberMoveState = BaleLoader.GRAB_DROP_BALE
			return
		end
		if id == BaleLoader.CHANGE_GRAB_DROP_BALE then
			if v340_.startBalePlace ~= nil and (v340_.startBalePlace.count < v340_.startBalePlace.numOfPlaces and v340_.startBalePlace.node ~= nil) then
				local v364_ = getChildAt(v340_.startBalePlace.node, v340_.startBalePlace.count)
				local v365_ = NetworkUtil.getObject(v340_.baleGrabber.currentBale)
				if v365_ == nil then
					v340_.balesToMount[v340_.baleGrabber.currentBale] = {
						["serverId"] = v340_.baleGrabber.currentBale,
						["linkNode"] = v364_,
						["trans"] = { 0, 0, 0 },
						["rot"] = { 0, 0, 0 }
					}
				else
					if v340_.dynamicMount.enabled then
						self:mountDynamicBale(v365_, v364_)
					else
						local v366_, v367_, v368_
						if v340_.keepBaleRotationDuringLoad then
							v366_, v367_, v368_ = localRotationToLocal(v365_.nodeId, v364_, 0, 0, 0)
						else
							v366_ = 0
							v367_ = 0
							v368_ = 0
						end
						self:mountBale(v365_, self, v364_, 0, 0, 0, v366_, v367_, v368_)
					end
					v340_.balesToMount[v340_.baleGrabber.currentBale] = nil
				end
				v340_.startBalePlace.count = v340_.startBalePlace.count + 1
				local v369_ = v340_.startBalePlace.bales
				local v370_ = v340_.baleGrabber.currentBale
				table.insert(v369_, v370_)
				v340_.baleGrabber.currentBale = nil
				self:updateFoldingAnimation()
				if v340_.startBalePlace.count < v340_.startBalePlace.numOfPlaces then
					v340_.frontBalePusherDirection = 1
					self:playAnimation(v340_.animations.balesToOtherRow, 1, nil, true)
					self:playAnimation(v340_.animations.frontBalePusher, 1, nil, true)
				elseif v340_.startBalePlace.count == v340_.startBalePlace.numOfPlaces then
					BaleLoader.rotatePlatform(self)
				end
				if v340_.animations.baleGrabberDropToWork == nil then
					self:playAnimation(v340_.currentBaleGrabberDropBaleAnimName, -v340_.animations.baleGrabberDropBaleReverseSpeed, nil, true)
					self:playAnimation(v340_.animations.baleGrabberWorkToDrop, -1, nil, true)
				else
					self:playAnimation(v340_.animations.baleGrabberDropToWork, 1, 0, true)
				end
				v340_.grabberMoveState = BaleLoader.GRAB_MOVE_DOWN
				return
			end
		else
			if id == BaleLoader.CHANGE_GRAB_MOVE_DOWN then
				v340_.grabberMoveState = nil
				v340_.automaticUnloadingAdditionalBalesToLoad = v340_.automaticUnloadingAdditionalBalesToLoad - 1
				return
			end
			if id == BaleLoader.CHANGE_FRONT_PUSHER then
				if v340_.frontBalePusherDirection > 0 then
					self:playAnimation(v340_.animations.frontBalePusher, -1, nil, true)
					v340_.frontBalePusherDirection = -1
				else
					v340_.frontBalePusherDirection = 0
				end
			end
			if id == BaleLoader.CHANGE_ROTATE_PLATFORM then
				if v340_.startBalePlace == nil or v340_.rotatePlatformDirection <= 0 then
					v340_.rotatePlatformDirection = 0
					return
				end
				local v371_ = v340_.balePlaces[v340_.startBalePlace.current]
				v340_.startBalePlace.current = v340_.startBalePlace.current + 1
				for v372_ = 1, #v340_.startBalePlace.bales do
					local v373_ = getChildAt(v340_.startBalePlace.node, v372_ - 1)
					local v374_, v375_, v376_ = getTranslation(v373_)
					local v377_, v378_, v379_ = getRotation(v373_)
					local v380_ = v340_.startBalePlace.bales[v372_]
					local v381_ = NetworkUtil.getObject(v380_)
					if v381_ == nil then
						v340_.balesToMount[v380_] = {
							["serverId"] = v380_,
							["linkNode"] = v371_.node,
							["trans"] = { v374_, v375_, v376_ },
							["rot"] = { v377_, v378_, v379_ }
						}
					else
						if v340_.keepBaleRotationDuringLoad then
							v374_, v375_, v376_ = localToLocal(v381_.nodeId, v371_.node, 0, 0, 0)
							v377_, v378_, v379_ = localRotationToLocal(v381_.nodeId, v371_.node, 0, 0, 0)
						end
						if v340_.dynamicMount.enabled then
							self:mountDynamicBale(v381_, v371_.node)
						else
							self:mountBale(v381_, self, v371_.node, v374_, v375_, v376_, v377_, v378_, v379_)
						end
						v340_.balesToMount[v380_] = nil
					end
				end
				v371_.bales = v340_.startBalePlace.bales
				v340_.startBalePlace.bales = {}
				v340_.startBalePlace.count = 0
				self:updateFoldingAnimation()
				for v382_ = 1, v340_.startBalePlace.numOfPlaces do
					local v383_ = getChildAt(v340_.startBalePlace.node, v382_ - 1)
					local v384_ = setRotation
					local v385_ = v340_.startBalePlace.origRot[v382_]
					v384_(v383_, unpack(v385_))
					local v386_ = setTranslation
					local v387_ = v340_.startBalePlace.origTrans[v382_]
					v386_(v383_, unpack(v387_))
				end
				if v340_.emptyState ~= BaleLoader.EMPTY_NONE then
					v340_.rotatePlatformDirection = 0
					return
				end
				if self:getAnimationTime(v340_.animations.baleGrabberWorkToDrop) >= v340_.animations.moveBalePlacesMaxGrabberTime and v340_.animations.moveBalePlacesMaxGrabberTime ~= math.huge then
					v340_.rotatePlatformDirection = -1
					v340_.moveBalePlacesDelayedMovement = true
					return
				end
				v340_.rotatePlatformDirection = -1
				self:playAnimation(v340_.animations.rotatePlatformBack, -1, nil, true)
				if v340_.animations.moveBalePlacesAfterRotatePlatform and (v340_.startBalePlace.current <= #v340_.balePlaces or v340_.animations.moveBalePlacesAlways) then
					self:playAnimation(v340_.animations.moveBalePlaces, 1, (v340_.startBalePlace.current - 1) / #v340_.balePlaces, true)
					self:setAnimationStopTime(v340_.animations.moveBalePlaces, v340_.startBalePlace.current / #v340_.balePlaces)
					self:playAnimation(v340_.animations.moveBalePlacesExtrasOnce, 1, nil, true)
					return
				end
			else
				if id == BaleLoader.CHANGE_EMPTY_ROTATE_PLATFORM then
					v340_.emptyState = BaleLoader.EMPTY_ROTATE_PLATFORM
					if v340_.startBalePlace == nil or v340_.startBalePlace.count ~= 0 then
						BaleLoader.rotatePlatform(self)
					else
						self:playAnimation(v340_.animations.rotatePlatformEmpty, 1, nil, true)
					end
				end
				if id == BaleLoader.CHANGE_EMPTY_ROTATE1 then
					self:playAnimation(v340_.animations.emptyRotate, 1, nil, true)
					self:setAnimationStopTime(v340_.animations.emptyRotate, 0.2)
					local v388_ = self:getRealAnimationTime(v340_.animations.moveBalePlaces)
					local v389_ = v340_.animations.moveBalePlacesToEmptySpeed
					if v340_.animations.pusherPushBalesOnEmpty and v340_.startBalePlace ~= nil then
						local v390_ = v340_.startBalePlace.current
						if #v340_.startBalePlace.bales == 0 then
							v390_ = v390_ - 1
						end
						local v391_ = self:getAnimationDuration(v340_.animations.moveBalePlacesToEmpty)
						local v392_ = v391_ <= 0 and 1 or 1 - v388_ / v391_
						local v393_ = 1 - v390_ / #v340_.balePlaces
						v389_ = v340_.animations.moveBalePlacesToEmptySpeed * (v393_ / math.max(v392_, 0.0001))
						if v389_ > 0 then
							self:playAnimation(v340_.animations.pusherMoveToEmpty, v389_, 0, true)
							self:setAnimationStopTime(v340_.animations.pusherMoveToEmpty, v393_)
						end
					else
						local v394_ = self:getAnimationDuration(v340_.animations.pusherMoveToEmpty)
						local v395_ = v394_ <= 0 and 0 or v388_ / v394_
						self:playAnimation(v340_.animations.pusherMoveToEmpty, v340_.animations.moveBalePlacesToEmptySpeed, v395_, true)
					end
					local v396_ = v340_.balePlaces[v340_.startBalePlace.current - 1]
					local v397_ = v396_ == nil or #v396_.bales >= v340_.startBalePlace.numOfPlaces
					if v340_.animations.moveBalePlacesToEmptyPushOffset > 0 and v397_ then
						if v389_ > 0 then
							v340_.animations.moveBalePlacesToEmptyPushOffsetDelay = v340_.animations.moveBalePlacesToEmptyPushOffset * self:getAnimationDuration(v340_.animations.pusherMoveToEmpty) / v389_
							v340_.animations.moveBalePlacesToEmptyPushOffsetTime = v340_.animations.moveBalePlacesToEmptyPushOffsetDelay
						end
					else
						local v398_ = self:getAnimationDuration(v340_.animations.moveBalePlacesToEmpty)
						local v399_ = v398_ <= 0 and 0 or v388_ / v398_
						self:playAnimation(v340_.animations.moveBalePlacesToEmpty, v340_.animations.moveBalePlacesToEmptySpeed, v399_, true)
					end
					v340_.emptyState = BaleLoader.EMPTY_ROTATE1
					if self.isClient then
						g_soundManager:playSample(v340_.samples.emptyRotate)
						return
					end
				else
					if id == BaleLoader.CHANGE_EMPTY_CLOSE_GRIPPERS then
						self:playAnimation(v340_.animations.closeGrippers, 1, nil, true)
						v340_.emptyState = BaleLoader.EMPTY_CLOSE_GRIPPERS
						return
					end
					if id == BaleLoader.CHANGE_EMPTY_HIDE_PUSHER1 then
						self:playAnimation(v340_.animations.pusherEmptyHide1, 1, nil, true)
						v340_.emptyState = BaleLoader.EMPTY_HIDE_PUSHER1
						return
					end
					if id == BaleLoader.CHANGE_EMPTY_HIDE_PUSHER2 then
						if v340_.animations.pusherHideOnEmpty then
							self:playAnimation(v340_.animations.pusherMoveToEmpty, -2, nil, true)
							v340_.emptyState = BaleLoader.EMPTY_HIDE_PUSHER2
							return
						end
						if self.isServer then
							g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_ROTATE2), true, nil, self)
							return
						end
					else
						if id == BaleLoader.CHANGE_EMPTY_ROTATE2 then
							self:playAnimation(v340_.animations.emptyRotate, 1, self:getAnimationTime(v340_.animations.emptyRotate), true)
							v340_.emptyState = BaleLoader.EMPTY_ROTATE2
							return
						end
						if id == BaleLoader.CHANGE_EMPTY_WAIT_TO_DROP then
							v340_.emptyState = BaleLoader.EMPTY_WAIT_TO_DROP
							return
						end
						if id == BaleLoader.CHANGE_EMPTY_STATE_NIL then
							v340_.emptyState = BaleLoader.EMPTY_NONE
							if GS_IS_MOBILE_VERSION then
								if self.rootVehicle:getActionControllerDirection() < 0 then
									v340_.controlledAction.parent:startActionSequence()
								end
							elseif v340_.transportPositionAfterUnloading then
								BaleLoader.moveToTransportPosition(self)
								if self.isServer then
									g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_MOVE_TO_TRANSPORT), true, nil, self)
								end
							end
							v340_.automaticUnloadingInProgress = false
							return
						end
						if id == BaleLoader.CHANGE_EMPTY_WAIT_TO_REDO then
							v340_.emptyState = BaleLoader.EMPTY_WAIT_TO_REDO
							return
						end
						if id == BaleLoader.CHANGE_BUTTON_EMPTY then
							local v400_ = self.isServer
							assert(v400_)
							if v340_.emptyState == BaleLoader.EMPTY_NONE then
								if BaleLoader.getAllowsStartUnloading(self) then
									g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_START), true, nil, self)
									return
								end
							else
								if v340_.emptyState == BaleLoader.EMPTY_WAIT_TO_DROP then
									g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_DROP_BALES), true, nil, self)
									return
								end
								if v340_.emptyState == BaleLoader.EMPTY_WAIT_TO_SINK then
									if not v340_.unloadingMover.isActive then
										g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_SINK), true, nil, self)
										return
									end
								elseif v340_.emptyState == BaleLoader.EMPTY_WAIT_TO_REDO then
									g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_REDO), true, nil, self)
									return
								end
							end
						elseif id == BaleLoader.CHANGE_BUTTON_EMPTY_ABORT then
							local v401_ = self.isServer
							assert(v401_)
							if v340_.emptyState ~= BaleLoader.EMPTY_NONE and v340_.emptyState == BaleLoader.EMPTY_WAIT_TO_DROP then
								g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_CANCEL), true, nil, self)
								return
							end
						elseif id == BaleLoader.CHANGE_BUTTON_WORK_TRANSPORT then
							local v402_ = self.isServer
							assert(v402_)
							if v340_.emptyState == BaleLoader.EMPTY_NONE and v340_.grabberMoveState == nil then
								if v340_.isInWorkPosition then
									g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_MOVE_TO_TRANSPORT), true, nil, self)
									return
								end
								g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_MOVE_TO_WORK), true, nil, self)
							end
						end
					end
				end
			end
		end
	end
end

-- Local values: spec
function BaleLoader:getAllowsStartUnloading()
	local v404_ = self.spec_baleLoader
	if self:getFillUnitFillLevel(v404_.fillUnitIndex) == 0 then
		return false
	elseif v404_.rotatePlatformDirection == 0 then
		if v404_.frontBalePusherDirection == 0 then
			if v404_.grabberIsMoving or v404_.grabberMoveState ~= nil then
				return false
			else
				return v404_.emptyState == BaleLoader.EMPTY_NONE
			end
		else
			return false
		end
	else
		return false
	end
end

-- Local values: spec
function BaleLoader:rotatePlatform()
	local v406_ = self.spec_baleLoader
	v406_.rotatePlatformDirection = 1
	self:playAnimation(v406_.animations.rotatePlatform, 1, nil, true)
	if v406_.startBalePlace.current > 1 and not v406_.animations.moveBalePlacesAfterRotatePlatform or v406_.animations.moveBalePlacesAlways then
		self:playAnimation(v406_.animations.moveBalePlaces, 1, (v406_.startBalePlace.current - 1) / #v406_.balePlaces, true)
		self:setAnimationStopTime(v406_.animations.moveBalePlaces, v406_.startBalePlace.current / #v406_.balePlaces)
		self:playAnimation(v406_.animations.moveBalePlacesExtrasOnce, 1, nil, true)
	end
end

-- Local values: spec, speed, animTime
function BaleLoader:moveToWorkPosition(onLoad)
	local v409_ = self.spec_baleLoader
	self:playBaleLoaderFoldingAnimation(onLoad and 9999 or 1)
	local v410_
	if self:getAnimationTime(v409_.animations.closeGrippers) == 0 then
		v410_ = nil
	else
		v410_ = self:getAnimationTime(v409_.animations.closeGrippers)
	end
	self:playAnimation(v409_.animations.closeGrippers, -1, v410_, true)
end

-- Local values: spec
function BaleLoader:moveToTransportPosition()
	self:playBaleLoaderFoldingAnimation(-1)
	local v412_ = self.spec_baleLoader
	local v413_ = v412_.animations.closeGrippers
	local v414_ = self:getAnimationTime(v412_.animations.closeGrippers)
	self:playAnimation(v413_, 1, math.clamp(v414_, 0, 1), true)
end

-- Local values: spec, name
function BaleLoader:getBaleGrabberDropBaleAnimName()
	local v416_ = self.spec_baleLoader
	local v417_ = string.format("%s%d", v416_.animations.baleGrabberDropBale, v416_.startBalePlace.count)
	if self:getAnimationExists(v417_) then
		return v417_
	else
		return v416_.animations.baleGrabberDropBale
	end
end

-- Local values: spec
function BaleLoader:getIsBaleGrabbingAllowed()
	local v419_ = self.spec_baleLoader
	if v419_.isInWorkPosition then
		if v419_.grabberIsMoving or v419_.grabberMoveState ~= nil then
			return false
		elseif v419_.startBalePlace.count >= v419_.startBalePlace.numOfPlaces then
			return false
		elseif v419_.frontBalePusherDirection == 0 then
			if v419_.animations.rotatePlatformAllowPickup or v419_.rotatePlatformDirection == 0 then
				if v419_.animations.moveBalePlacesAlways and self:getIsAnimationPlaying(v419_.animations.moveBalePlaces) then
					return false
				elseif v419_.emptyState == BaleLoader.EMPTY_NONE then
					return self:getFillUnitFreeCapacity(v419_.fillUnitIndex) ~= 0
				else
					return false
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

-- Local values: spec
function BaleLoader:pickupBale(nearestBale, nearestBaleType)
	self.spec_baleLoader.lastPickupTime = g_time
	self:setBaleLoaderBaleType(nearestBaleType.index)
	g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_GRAB_BALE, NetworkUtil.getObjectId(nearestBale)), true, nil, self)
end

-- Local values: spec, newBaleType, i, baleType, fillUnit
function BaleLoader:setBaleLoaderBaleType(baleTypeIndex, forceUpdate)
	local v426_ = self.spec_baleLoader
	local v427_ = v426_.baleTypes[baleTypeIndex] or v426_.baleTypes[1]
	if v427_ ~= v426_.currentBaleType then
		v426_.currentBaleType = v427_
		v426_.animations = v427_.animations
		if not v426_.useSharedBalePlaces then
			if v427_.startBalePlace.node == nil then
				v426_.startBalePlace = v426_.defaultBalePlace.startBalePlace
			else
				v426_.startBalePlace = v427_.startBalePlace
			end
			if #v427_.balePlaces > 0 then
				v426_.balePlaces = v427_.balePlaces
			else
				v426_.balePlaces = v426_.defaultBalePlace.balePlaces
			end
		end
		v426_.fillUnitIndex = v427_.fillUnitIndex
		for v428_ = 1, #v426_.baleTypes do
			local v429_ = v426_.baleTypes[v428_]
			local v430_ = self:getFillUnitByIndex(v429_.fillUnitIndex)
			if v430_.showOnHudOrig == nil then
				v430_.showOnHudOrig = v430_.showOnHud
			end
			if v430_.showOnHudOrig then
				v430_.showOnHud = v429_.fillUnitIndex == v426_.fillUnitIndex
			end
		end
		ObjectChangeUtil.setObjectChanges(v427_.changeObjects, true, self, self.setMovingToolDirty, forceUpdate)
	end
end

-- Local values: spec, foundBaleType, _, baleType, dimensions
function BaleLoader:getBaleTypeByBale(bale)
	local v433_ = self.spec_baleLoader
	local v434_ = nil
	for _, v435_ in pairs(v433_.baleTypes) do
		local v436_ = v435_.dimensions
		if v436_.isRoundbale then
			if v436_.isRoundbale and (bale.width >= v436_.minWidth and (bale.width <= v436_.maxWidth and (bale.diameter >= v436_.minDiameter and bale.diameter <= v436_.maxDiameter))) then
				return v435_
			end
		elseif not v436_.isRoundbale and (bale.width >= v436_.minWidth and (bale.width <= v436_.maxWidth and (bale.height >= v436_.minHeight and (bale.height <= v436_.maxHeight and (bale.length >= v436_.minLength and bale.length <= v436_.maxLength))))) then
			return v435_
		end
	end
	return v434_
end

-- Local values: rigidBodyType, object, spec
function BaleLoader:baleGrabberTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if otherId ~= 0 then
		local v441_ = getRigidBodyType(otherId)
		if self.isServer and v441_ == RigidBodyType.DYNAMIC or not self.isServer and v441_ == RigidBodyType.KINEMATIC then
			local v442_ = g_currentMission:getNodeObject(otherId)
			if v442_ ~= nil and v442_:isa(Bale) then
				local v443_ = self.spec_baleLoader
				if onEnter then
					v443_.baleGrabber.balesInTrigger[v442_] = Utils.getNoNil(v443_.baleGrabber.balesInTrigger[v442_], 0) + 1
					return
				end
				if onLeave and v443_.baleGrabber.balesInTrigger[v442_] ~= nil then
					local v444_ = v443_.baleGrabber.balesInTrigger
					local v445_ = v443_.baleGrabber.balesInTrigger[v442_] - 1
					v444_[v442_] = math.max(0, v445_)
					if v443_.baleGrabber.balesInTrigger[v442_] == 0 then
						v443_.baleGrabber.balesInTrigger[v442_] = nil
					end
				end
			end
		end
	end
end

-- Local values: object, spec
function BaleLoader:baleLoaderMoveTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if otherId ~= 0 and getRigidBodyType(otherId) == RigidBodyType.DYNAMIC then
		local v450_ = g_currentMission:getNodeObject(otherId)
		if v450_ ~= nil and v450_:isa(Bale) then
			local v451_ = self.spec_baleLoader
			if onEnter then
				v451_.unloadingMover.balesInTrigger[v450_] = Utils.getNoNil(v451_.unloadingMover.balesInTrigger[v450_], 0) + 1
				if v451_.unloadingMover.balesInTrigger[v450_] == 1 then
					v450_:addDeleteListener(self, "onBaleMoverBaleRemoved")
					return
				end
			elseif onLeave and v451_.unloadingMover.balesInTrigger[v450_] ~= nil then
				local v452_ = v451_.unloadingMover.balesInTrigger
				local v453_ = v451_.unloadingMover.balesInTrigger[v450_] - 1
				v452_[v450_] = math.max(0, v453_)
				if v451_.unloadingMover.balesInTrigger[v450_] == 0 then
					v451_.unloadingMover.balesInTrigger[v450_] = nil
					v450_:removeDeleteListener(self, "onBaleMoverBaleRemoved")
				end
			end
		end
	end
end

-- Local values: spec, x, y, z, rx, ry, rz, jointNode, x, y, z, quatX, quatY, quatZ, quatW, jointComponent, i, active
function BaleLoader:mountDynamicBale(bale, node)
	local v457_ = self.spec_baleLoader
	if self.isServer then
		if bale.dynamicMountJointIndex == nil or bale.baleLoaderDynamicJointNode == nil then
			local v458_ = createTransformGroup("baleJoint")
			link(node, v458_)
			bale.baleLoaderDynamicJointNode = v458_
			if v457_.dynamicMount.jointInterpolation then
				setWorldTranslation(v458_, getWorldTranslation(bale.nodeId))
				setWorldRotation(v458_, getWorldRotation(bale.nodeId))
			else
				local v459_, v460_, v461_ = getWorldTranslation(v458_)
				local v462_, v463_, v464_, v465_ = getWorldQuaternion(v458_)
				removeFromPhysics(bale.nodeId)
				bale:setWorldPositionQuaternion(v459_, v460_, v461_, v462_, v463_, v464_, v465_, true)
				addToPhysics(bale.nodeId)
				link(v458_, bale.meshNode)
			end
			bale:mountDynamic(self, self:getParentComponent(node), v458_, DynamicMountUtil.TYPE_FIX_ATTACH, 0, false)
			bale:setNeedsSaving(false)
			if v457_.dynamicMount.minTransLimits ~= nil and v457_.dynamicMount.maxTransLimits ~= nil then
				for v466_ = 1, 3 do
					local v467_ = v457_.dynamicMount.minTransLimits[v466_] ~= 0 and true or v457_.dynamicMount.maxTransLimits[v466_] ~= 0
					if v467_ then
						setJointTranslationLimit(bale.dynamicMountJointIndex, v466_ - 1, v467_, v457_.dynamicMount.minTransLimits[v466_], v457_.dynamicMount.maxTransLimits[v466_])
					end
				end
			end
			if v457_.dynamicMount.jointInterpolation then
				local v468_ = v457_.dynamicMount.baleJointsToUpdate
				local v469_ = {
					["node"] = bale.baleLoaderDynamicJointNode,
					["time"] = 0
				}
				table.insert(v468_, v469_)
			end
			v457_.dynamicMount.baleMassDirty = true
		else
			local v470_, v471_, v472_ = getWorldTranslation(bale.baleLoaderDynamicJointNode)
			local v473_, v474_, v475_ = getWorldRotation(bale.baleLoaderDynamicJointNode)
			link(node, bale.baleLoaderDynamicJointNode)
			setWorldTranslation(bale.baleLoaderDynamicJointNode, v470_, v471_, v472_)
			setWorldRotation(bale.baleLoaderDynamicJointNode, v473_, v474_, v475_)
			setJointFrame(bale.dynamicMountJointIndex, 0, bale.baleLoaderDynamicJointNode)
			if v457_.dynamicMount.jointInterpolation then
				local v476_ = v457_.dynamicMount.baleJointsToUpdate
				local v477_ = {
					["node"] = bale.baleLoaderDynamicJointNode,
					["time"] = 0
				}
				table.insert(v476_, v477_)
				return
			end
		end
	end
end

-- Local values: spec
function BaleLoader:unmountDynamicBale(bale)
	if self.isServer then
		local v480_ = self.spec_baleLoader
		bale:unmountDynamic()
		bale:setNeedsSaving(true)
		if bale.baleLoaderDynamicJointNode ~= nil then
			delete(bale.baleLoaderDynamicJointNode)
			bale.baleLoaderDynamicJointNode = nil
		end
		v480_.dynamicMount.baleJointsToUpdate = {}
		if bale.backupMass ~= nil then
			setMass(bale.nodeId, bale.backupMass)
			bale.backupMass = nil
		end
	end
end

-- Local values: spec
function BaleLoader:mountBale(bale, object, node, x, y, z, rx, ry, rz, noKinematicMounting)
	local v492_ = self.spec_baleLoader
	if v492_.unloadingMover.balesInTrigger[bale] ~= nil then
		v492_.unloadingMover.balesInTrigger[bale] = nil
	end
	if noKinematicMounting == true or not v492_.allowKinematicMounting then
		bale:mount(object, node, x, y, z, rx, ry, rz)
		bale:setNeedsSaving(false)
	else
		bale:mountKinematic(object, node, x, y, z, rx, ry, rz)
		bale:setNeedsSaving(false)
		if not table.hasElement(v492_.kinematicMountedBales, bale) then
			self:setBalePairCollision(bale, false)
			table.addElement(v492_.kinematicMountedBales, bale)
		end
	end
end

-- Local values: spec
function BaleLoader:unmountBale(bale)
	local v495_ = self.spec_baleLoader
	if bale.dynamicMountType == MountableObject.MOUNT_TYPE_DEFAULT then
		bale:unmount()
		bale:setNeedsSaving(true)
	elseif bale.dynamicMountType == MountableObject.MOUNT_TYPE_KINEMATIC then
		bale:unmountKinematic()
		bale:setNeedsSaving(true)
		table.removeElement(v495_.kinematicMountedBales, bale)
		self:setBalePairCollision(bale, true)
	end
end

-- Local values: spec, i, i, bale2
function BaleLoader:setBalePairCollision(bale, state)
	local v499_ = self.spec_baleLoader
	for v500_ = 1, #self.components do
		setPairCollision(self.components[v500_].node, bale.nodeId, state)
	end
	for v501_ = 1, #v499_.kinematicMountedBales do
		local v502_ = v499_.kinematicMountedBales[v501_]
		setPairCollision(v502_.nodeId, bale.nodeId, state)
	end
end

-- Local values: bales, spec, _, balePlace, _, baleServerId, bale, _, baleServerId, bale
function BaleLoader:getLoadedBales()
	local v504_ = self.spec_baleLoader
	local v505_ = {}
	for _, v506_ in pairs(v504_.balePlaces) do
		if v506_.bales ~= nil then
			for _, v507_ in pairs(v506_.bales) do
				local v508_ = NetworkUtil.getObject(v507_)
				if v508_ ~= nil then
					table.insert(v505_, v508_)
				end
			end
		end
	end
	for _, v509_ in ipairs(v504_.startBalePlace.bales) do
		local v510_ = NetworkUtil.getObject(v509_)
		if v510_ ~= nil then
			table.insert(v505_, v510_)
		end
	end
	return v505_
end

-- Local values: spec
function BaleLoader:startAutomaticBaleUnloading()
	local v512_ = self.spec_baleLoader
	v512_.automaticUnloadingInProgress = true
	if v512_.automaticUnloadingAdditionalBalesToLoad == 0 then
		v512_.automaticUnloadingAdditionalBalesToLoad = -1
	end
	g_client:getServerConnection():sendEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_BUTTON_EMPTY))
end

function BaleLoader:getIsAutomaticBaleUnloadingInProgress()
	return self.spec_baleLoader.automaticUnloadingInProgress
end

function BaleLoader:getIsAutomaticBaleUnloadingAllowed()
	if self:getIsAutomaticBaleUnloadingInProgress() then
		return false
	elseif self.spec_baleLoader.lastPickupTime + self.spec_baleLoader.lastPickupAutomatedUnloadingDelayTime > g_time then
		return false
	else
		return BaleLoader.getAllowsStartUnloading(self) and true or false
	end
end

-- Local values: animationName
function BaleLoader:playBaleLoaderFoldingAnimation(speed)
	local v517_ = self:getCurrentFoldingAnimation()
	local v518_ = self:getAnimationTime(v517_)
	self:playAnimation(v517_, speed, math.clamp(v518_, 0, 1), true)
end

function BaleLoader:getIsBaleLoaderFoldingPlaying()
	return self:getIsAnimationPlaying(self:getCurrentFoldingAnimation())
end

-- Local values: spec
function BaleLoader:getCurrentFoldingAnimation()
	local v521_ = self.spec_baleLoader
	if v521_.hasMultipleFoldingAnimations then
		return v521_.lastFoldingAnimation
	else
		return v521_.animations.baleGrabberTransportToWork
	end
end

-- Local values: spec, name, fillLevel, balePlace, baleTypeIndex, _, foldingAnimation, animTime
function BaleLoader:updateFoldingAnimation()
	local v523_ = self.spec_baleLoader
	local v524_ = v523_.animations.baleGrabberTransportToWork
	local v525_ = MathUtil.round(self:getFillUnitFillLevel(v523_.fillUnitIndex))
	local v526_ = #v523_.startBalePlace.bales
	local v527_ = v523_.currentBaleType == nil and 1 or v523_.currentBaleType.index
	for _, v528_ in ipairs(v523_.foldingAnimations) do
		if (v528_.baleTypeIndex == 0 or v528_.baleTypeIndex == v527_) and (v528_.minFillLevel <= v525_ and (v525_ <= v528_.maxFillLevel and (v528_.minBalePlace <= v526_ and v526_ <= v528_.maxBalePlace))) then
			v524_ = v528_.name
			break
		end
	end
	if v524_ ~= v523_.lastFoldingAnimation then
		if v523_.lastFoldingAnimation ~= nil then
			self:setAnimationTime(v524_, self:getAnimationTime(v523_.lastFoldingAnimation), false)
		end
		v523_.lastFoldingAnimation = v524_
	end
end

-- Local values: spec
function BaleLoader:onBaleMoverBaleRemoved(bale)
	self.spec_baleLoader.unloadingMover.balesInTrigger[bale] = nil
end

-- Local values: spec
function BaleLoader:onBaleUnloadTriggerDeleted(unloadTrigger)
	local v533_ = self.spec_baleLoader
	if v533_.baleUnloadTriggers[unloadTrigger] ~= nil then
		v533_.baleUnloadTriggers[unloadTrigger] = nil
	end
end

-- Local values: spec
function BaleLoader:addBaleUnloadTrigger(unloadTrigger)
	local v536_ = self.spec_baleLoader
	v536_.baleUnloadTriggers[unloadTrigger] = (v536_.baleUnloadTriggers[unloadTrigger] or 0) + 1
	unloadTrigger:addDeleteListener(self, BaleLoader.onBaleUnloadTriggerDeleted)
	self:raiseActive()
end

-- Local values: spec
function BaleLoader:removeBaleUnloadTrigger(unloadTrigger)
	local v539_ = self.spec_baleLoader
	v539_.baleUnloadTriggers[unloadTrigger] = (v539_.baleUnloadTriggers[unloadTrigger] or 0) - 1
	if v539_.baleUnloadTriggers[unloadTrigger] <= 0 then
		v539_.baleUnloadTriggers[unloadTrigger] = nil
		unloadTrigger:removeDeleteListener(self, BaleLoader.onBaleUnloadTriggerDeleted)
	end
end

function BaleLoader:getCanBeSelected(superFunc)
	return true
end

-- Local values: spec
function BaleLoader:getAllowDynamicMountFillLevelInfo(superFunc)
	if self.spec_baleLoader.dynamicMount.enabled then
		return false
	else
		return superFunc(self)
	end
end

function BaleLoader:getAreControlledActionsAllowed(superFunc)
	if self:getIsAutomaticBaleUnloadingInProgress() then
		return false
	else
		return superFunc(self)
	end
end

-- Local values: spec
function BaleLoader:getIsAIReadyToDrive(superFunc)
	local v546_ = self.spec_baleLoader
	if v546_.isInWorkPosition or v546_.grabberIsMoving then
		return false
	else
		return superFunc(self)
	end
end

-- Local values: spec
function BaleLoader:getIsAIPreparingToDrive(superFunc)
	return self.spec_baleLoader.grabberIsMoving and true or superFunc(self)
end

-- Local values: spec
function BaleLoader:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	if self:getFillUnitFillLevel(self.spec_baleLoader.fillUnitIndex) > 0 then
		return false
	else
		return superFunc(self, direction, onAiTurnOn)
	end
end

-- Local values: spec
function BaleLoader:getDoConsumePtoPower(superFunc)
	local v555_ = self.spec_baleLoader
	return v555_.consumePtoPower and (v555_.isInWorkPosition or v555_.grabberIsMoving) and true or superFunc(self)
end

-- Local values: value, count, spec, loadPercentage
function BaleLoader:getConsumingLoad(superFunc)
	local v558_, v559_ = superFunc(self)
	local v560_ = self.spec_baleLoader
	return v558_ + (v560_.consumePtoPower and (v560_.isInWorkPosition or v560_.grabberIsMoving) and 1 or 0), v559_ + 1
end

-- Local values: spec
function BaleLoader:getIsPowerTakeOffActive(superFunc)
	local v563_ = self.spec_baleLoader
	return v563_.consumePtoPower and (v563_.isInWorkPosition or v563_.grabberIsMoving) and true or superFunc(self)
end

-- Local values: spec, _, balePlace, _, baleServerId, bale, x, y, z, rx, ry, rz, _, baleServerId, bale, attachNode, x, y, z, rx, ry, rz
function BaleLoader:addToPhysics(superFunc)
	if not superFunc(self) then
		return false
	end
	local v566_ = self.spec_baleLoader
	for _, v567_ in pairs(v566_.balePlaces) do
		if v567_.bales ~= nil then
			for _, v568_ in pairs(v567_.bales) do
				local v569_ = NetworkUtil.getObject(v568_)
				if v569_ ~= nil then
					v569_:addToPhysics()
					if v566_.dynamicMount.enabled then
						self:mountDynamicBale(v569_, v567_.node)
					else
						local v570_, v571_, v572_ = localToLocal(v569_.nodeId, v567_.node, 0, 0, 0)
						local v573_, v574_, v575_ = localRotationToLocal(v569_.nodeId, v567_.node, 0, 0, 0)
						self:mountBale(v569_, self, v567_.node, v570_, v571_, v572_, v573_, v574_, v575_)
					end
				end
			end
		end
	end
	for _, v576_ in ipairs(v566_.startBalePlace.bales) do
		local v577_ = NetworkUtil.getObject(v576_)
		if v577_ ~= nil then
			v577_:addToPhysics()
			local v578_ = getChildAt(v566_.startBalePlace.node, v566_.startBalePlace.count)
			if v566_.dynamicMount.enabled then
				self:mountDynamicBale(v577_, v578_)
			else
				local v579_, v580_, v581_ = localToLocal(v577_.nodeId, v578_, 0, 0, 0)
				local v582_, v583_, v584_ = localRotationToLocal(v577_.nodeId, v578_, 0, 0, 0)
				self:mountBale(v577_, self, v578_, v579_, v580_, v581_, v582_, v583_, v584_)
			end
		end
	end
	return true
end

-- Local values: spec, _, balePlace, _, baleServerId, bale, _, baleServerId, bale
function BaleLoader:removeFromPhysics(superFunc)
	if not superFunc(self) then
		return false
	end
	local v587_ = self.spec_baleLoader
	for _, v588_ in pairs(v587_.balePlaces) do
		if v588_.bales ~= nil then
			for _, v589_ in pairs(v588_.bales) do
				local v590_ = NetworkUtil.getObject(v589_)
				if v590_ ~= nil then
					if v587_.dynamicMount.enabled then
						self:unmountDynamicBale(v590_)
					else
						self:unmountBale(v590_)
					end
					v590_:removeFromPhysics()
				end
			end
		end
	end
	for _, v591_ in ipairs(v587_.startBalePlace.bales) do
		local v592_ = NetworkUtil.getObject(v591_)
		if v592_ ~= nil then
			if v587_.dynamicMount.enabled then
				self:unmountDynamicBale(v592_)
			else
				self:unmountBale(v592_)
			end
			v592_:removeFromPhysics()
		end
	end
	return true
end

-- Local values: spec, _, actionEventId, _, actionEventId
function BaleLoader:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v595_ = self.spec_baleLoader
		self:clearActionEventsTable(v595_.actionEvents)
		if isActiveForInputIgnoreSelection then
			if not v595_.useFoldingState then
				local _, v596_ = self:addPoweredActionEvent(v595_.actionEvents, InputAction.IMPLEMENT_EXTRA, self, BaleLoader.actionEventWorkTransport, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(v596_, GS_PRIO_NORMAL)
			end
			if not v595_.fullAutomaticUnloading then
				local _, v597_ = self:addPoweredActionEvent(v595_.actionEvents, InputAction.IMPLEMENT_EXTRA3, self, BaleLoader.actionEventEmpty, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(v597_, GS_PRIO_NORMAL)
				local _, v598_ = self:addPoweredActionEvent(v595_.actionEvents, InputAction.IMPLEMENT_EXTRA2, self, BaleLoader.actionEventAbortEmpty, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(v598_, GS_PRIO_NORMAL)
				g_inputBinding:setActionEventText(v598_, v595_.texts.abortUnloading)
			end
		end
	end
end

-- Local values: spec
function BaleLoader:actionEventEmpty(actionName, inputValue, callbackState, isAnalog)
	local v600_ = self.spec_baleLoader
	if self:getFillUnitFillLevel(v600_.fillUnitIndex) >= v600_.minUnloadingFillLevel or v600_.emptyState ~= BaleLoader.EMPTY_NONE then
		g_client:getServerConnection():sendEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_BUTTON_EMPTY))
	else
		g_currentMission:showBlinkingWarning(v600_.texts.minUnloadingFillLevelWarning, 2500)
	end
end

function BaleLoader:actionEventAbortEmpty(actionName, inputValue, callbackState, isAnalog)
	g_client:getServerConnection():sendEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_BUTTON_EMPTY_ABORT))
end

function BaleLoader:actionEventWorkTransport(actionName, inputValue, callbackState, isAnalog)
	g_client:getServerConnection():sendEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_BUTTON_WORK_TRANSPORT))
end

-- Local values: rootName, baleSizeAttributes
function BaleLoader.loadSpecValueBaleSize(xmlFile, customEnvironment, baseDir, roundBaleLoader)
	local v_u_605_ = {
		["minDiameter"] = math.huge,
		["maxDiameter"] = -math.huge,
		["minLength"] = math.huge,
		["maxLength"] = -math.huge
	}
	xmlFile:iterate(xmlFile:getRootName() .. ".baleLoader.baleTypes.baleType", function(_, p606_)
		-- upvalues: (copy) xmlFile, (copy) roundBaleLoader, (copy) v_u_605_
		if ((xmlFile:getValue(p606_ .. "#diameter") ~= nil or xmlFile:getValue(p606_ .. "#minDiameter") ~= nil) and true or xmlFile:getValue(p606_ .. "#maxDiameter") ~= nil) == roundBaleLoader then
			local v607_ = MathUtil.round(xmlFile:getValue(p606_ .. "#diameter"), 2)
			local v608_ = MathUtil.round(xmlFile:getValue(p606_ .. "#minDiameter"), 2)
			local v609_ = MathUtil.round(xmlFile:getValue(p606_ .. "#maxDiameter"), 2)
			local v610_ = v_u_605_
			local v611_ = v_u_605_.minDiameter
			local v612_ = v607_ or v_u_605_.minDiameter
			local v613_ = v608_ or v_u_605_.minDiameter
			local v614_ = v609_ or v_u_605_.minDiameter
			v610_.minDiameter = math.min(v611_, v612_, v613_, v614_)
			local v615_ = v_u_605_
			local v616_ = v_u_605_.maxDiameter
			local v617_ = v607_ or v_u_605_.maxDiameter
			local v618_ = v608_ or v_u_605_.maxDiameter
			local v619_ = v609_ or v_u_605_.maxDiameter
			v615_.maxDiameter = math.max(v616_, v617_, v618_, v619_)
			local v620_ = MathUtil.round(xmlFile:getValue(p606_ .. "#length"), 2)
			local v621_ = MathUtil.round(xmlFile:getValue(p606_ .. "#minLength"), 2)
			local v622_ = MathUtil.round(xmlFile:getValue(p606_ .. "#maxLength"), 2)
			local v623_ = v_u_605_
			local v624_ = v_u_605_.minLength
			local v625_ = v620_ or v_u_605_.minLength
			local v626_ = v621_ or v_u_605_.minLength
			local v627_ = v622_ or v_u_605_.minLength
			v623_.minLength = math.min(v624_, v625_, v626_, v627_)
			local v628_ = v_u_605_
			local v629_ = v_u_605_.maxLength
			local v630_ = v620_ or v_u_605_.maxLength
			local v631_ = v621_ or v_u_605_.maxLength
			local v632_ = v622_ or v_u_605_.maxLength
			v628_.maxLength = math.max(v629_, v630_, v631_, v632_)
		end
	end)
	if v_u_605_.minDiameter == math.huge and v_u_605_.minLength == math.huge then
		return nil
	else
		return v_u_605_
	end
end

-- Local values: baleSizeAttributes, minValue, maxValue, unit, size
function BaleLoader.getSpecValueBaleSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange, roundBaleLoader)
	local v637_ = roundBaleLoader and storeItem.specs.baleLoaderBaleSizeRound or storeItem.specs.baleLoaderBaleSizeSquare
	if v637_ == nil then
		if returnValues and returnRange then
			return 0, 0, ""
		elseif returnValues then
			return 0, ""
		else
			return ""
		end
	else
		local v638_ = roundBaleLoader and v637_.minDiameter or v637_.minLength
		local v639_ = roundBaleLoader and v637_.maxDiameter or v637_.maxLength
		if returnValues == nil or not returnValues then
			local v640_ = g_i18n:getText("unit_cmShort")
			if v639_ == v638_ then
				return string.format("%d%s", v638_ * 100, v640_)
			else
				return string.format("%d%s-%d%s", v638_ * 100, v640_, v639_ * 100, v640_)
			end
		elseif returnRange == true and v639_ ~= v638_ then
			return v638_ * 100, v639_ * 100, g_i18n:getText("unit_cmShort")
		else
			return v638_ * 100, g_i18n:getText("unit_cmShort")
		end
	end
end

function BaleLoader.loadSpecValueBaleSizeRound(xmlFile, customEnvironment, baseDir)
	return BaleLoader.loadSpecValueBaleSize(xmlFile, customEnvironment, baseDir, true)
end

function BaleLoader.loadSpecValueBaleSizeSquare(xmlFile, customEnvironment, baseDir)
	return BaleLoader.loadSpecValueBaleSize(xmlFile, customEnvironment, baseDir, false)
end

function BaleLoader.getSpecValueBaleSizeRound(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	if storeItem.specs.baleLoaderBaleSizeRound == nil then
		return nil
	else
		return BaleLoader.getSpecValueBaleSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange, true)
	end
end

function BaleLoader.getSpecValueBaleSizeSquare(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	if storeItem.specs.baleLoaderBaleSizeSquare == nil then
		return nil
	else
		return BaleLoader.getSpecValueBaleSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange, false)
	end
end
