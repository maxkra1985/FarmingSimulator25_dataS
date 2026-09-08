source("dataS/scripts/vehicles/specializations/events/BaleWrapperStateEvent.lua")
source("dataS/scripts/vehicles/specializations/events/BaleWrapperAutomaticDropEvent.lua")
source("dataS/scripts/vehicles/specializations/events/BaleWrapperDropEvent.lua")
BaleWrapper = {}
BaleWrapper.CONSUMABLE_TYPE_NAME = "BALE_WRAP"
BaleWrapper.STATE_NONE = 0
BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER = 1
BaleWrapper.STATE_MOVING_GRABBER_TO_WORK = 2
BaleWrapper.STATE_WRAPPER_WRAPPING_BALE = 3
BaleWrapper.STATE_WRAPPER_FINSIHED = 4
BaleWrapper.STATE_WRAPPER_DROPPING_BALE = 5
BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM = 6
BaleWrapper.STATE_NUM_BITS = 3
BaleWrapper.CHANGE_GRAB_BALE = 1
BaleWrapper.CHANGE_DROP_BALE_AT_GRABBER = 2
BaleWrapper.CHANGE_WRAPPING_START = 3
BaleWrapper.CHANGE_WRAPPING_BALE_FINSIHED = 4
BaleWrapper.CHANGE_WRAPPER_START_DROP_BALE = 5
BaleWrapper.CHANGE_WRAPPER_BALE_DROPPED = 6
BaleWrapper.CHANGE_WRAPPER_PLATFORM_RESET = 7
BaleWrapper.CHANGE_BUTTON_EMPTY = 8
BaleWrapper.ANIMATION_NAMES = {
	"moveToWrapper",
	"wrapBale",
	"dropFromWrapper",
	"resetAfterDrop",
	"resetWrapping"
}
BaleWrapper.DROP_COLLISION_MASK = CollisionFlag.VEHICLE + CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.PLAYER
BaleWrapper.BLOCK_COLLISION_MASK = CollisionFlag.VEHICLE + CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.PLAYER

function BaleWrapper.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(Consumable, specializations)
	end
	return v2_
end
function BaleWrapper.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("wrappingColor", g_i18n:getText("configuration_wrappingColor"), nil, VehicleConfigurationItemColor)
	g_vehicleConfigurationManager:addConfigurationType("wrappingAnimation", g_i18n:getText("configuration_wrappingAnimation"), "baleWrapper", VehicleConfigurationItem)
	g_storeManager:addSpecType("baleWrapperBaleSizeRound", "shopListAttributeIconBaleWrapperBaleSizeRound", BaleWrapper.loadSpecValueBaleSizeRound, BaleWrapper.getSpecValueBaleSizeRound, StoreSpecies.VEHICLE)
	g_storeManager:addSpecType("baleWrapperBaleSizeSquare", "shopListAttributeIconBaleWrapperBaleSizeSquare", BaleWrapper.loadSpecValueBaleSizeSquare, BaleWrapper.getSpecValueBaleSizeSquare, StoreSpecies.VEHICLE)
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("BaleWrapper")
	v3_:register(XMLValueType.FLOAT, "vehicle.baleWrapper#foldMinLimit", "Fold min limit (Allow grabbing if folding is between these values)", 0)
	v3_:register(XMLValueType.FLOAT, "vehicle.baleWrapper#foldMaxLimit", "Fold max limit (Allow grabbing if folding is between these values)", 1)
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.baleWrapper.grabber#node", "Grabber node")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.baleWrapper.grabber#triggerNode", "Grabber trigger node")
	v3_:register(XMLValueType.FLOAT, "vehicle.baleWrapper.grabber#nearestDistance", "Distance to bale to grab it", 3)
	v3_:register(XMLValueType.BOOL, "vehicle.baleWrapper.automaticDrop#enabled", "Automatic drop", "true on mobile")
	v3_:register(XMLValueType.BOOL, "vehicle.baleWrapper.automaticDrop#toggleable", "Automatic bale drop can be toggled", "false on mobile")
	v3_:register(XMLValueType.L10N_STRING, "vehicle.baleWrapper.automaticDrop#textPos", "Positive toggle automatic drop text", "action_toggleAutomaticBaleDropPos")
	v3_:register(XMLValueType.L10N_STRING, "vehicle.baleWrapper.automaticDrop#textNeg", "Negative toggle automatic drop text", "action_toggleAutomaticBaleDropNeg")
	BaleWrapper.registerWrapperXMLPaths(v3_, "vehicle.baleWrapper.roundBaleWrapper")
	BaleWrapper.registerWrapperXMLPaths(v3_, "vehicle.baleWrapper.squareBaleWrapper")
	for v4_ = 1, #BaleWrapper.ANIMATION_NAMES do
		BaleWrapper.registerWrapperAnimationXMLPaths(v3_, "vehicle.baleWrapper.wrappingAnimationConfigurations.wrappingAnimationConfiguration(?).roundBaleWrapper", BaleWrapper.ANIMATION_NAMES[v4_])
		BaleWrapper.registerWrapperAnimationXMLPaths(v3_, "vehicle.baleWrapper.wrappingAnimationConfigurations.wrappingAnimationConfiguration(?).roundBaleWrapper.baleTypes.baleType(?)", BaleWrapper.ANIMATION_NAMES[v4_])
		BaleWrapper.registerWrapperAnimationXMLPaths(v3_, "vehicle.baleWrapper.wrappingAnimationConfigurations.wrappingAnimationConfiguration(?).squareBaleWrapper", BaleWrapper.ANIMATION_NAMES[v4_])
		BaleWrapper.registerWrapperAnimationXMLPaths(v3_, "vehicle.baleWrapper.wrappingAnimationConfigurations.wrappingAnimationConfiguration(?).squareBaleWrapper.baleTypes.baleType(?)", BaleWrapper.ANIMATION_NAMES[v4_])
	end
	v3_:setXMLSpecializationType()
	local v5_ = Vehicle.xmlSchemaSavegame
	v5_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).baleWrapper#wrapperTime", "Bale wrapping time", 0)
	Bale.registerSavegameXMLPaths(v5_, "vehicles.vehicle(?).baleWrapper.bale")
end

-- Local values: i
function BaleWrapper.registerWrapperXMLPaths(schema, basePath)
	for v8_ = 1, #BaleWrapper.ANIMATION_NAMES do
		BaleWrapper.registerWrapperAnimationXMLPaths(schema, basePath, BaleWrapper.ANIMATION_NAMES[v8_])
		BaleWrapper.registerWrapperAnimationXMLPaths(schema, basePath .. ".baleTypes.baleType(?)", BaleWrapper.ANIMATION_NAMES[v8_])
	end
	schema:register(XMLValueType.STRING, basePath .. ".baleTypes.baleType(?)#fillType", "Fill type name")
	schema:register(XMLValueType.FLOAT, basePath .. ".baleTypes.baleType(?)#diameter", "Bale diameter", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".baleTypes.baleType(?)#width", "Bale width", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".baleTypes.baleType(?)#height", "Bale height", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".baleTypes.baleType(?)#length", "Bale length", 0)
	schema:register(XMLValueType.STRING, basePath .. ".baleTypes.baleType(?).textures#diffuse", "Path to wrap diffuse map")
	schema:register(XMLValueType.STRING, basePath .. ".baleTypes.baleType(?).textures#normal", "Path to wrap normal map")
	schema:register(XMLValueType.BOOL, basePath .. ".baleTypes.baleType(?)#skipWrapping", "Bale is picked up, but not wrapped", false)
	schema:register(XMLValueType.BOOL, basePath .. ".baleTypes.baleType(?)#forceWhileFolding", "Force this bale type while wrapper is folded", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".baleTypes.baleType(?)#wrapUsage", "Usage of wrap rolls per bale", 0.1)
	schema:register(XMLValueType.FLOAT, basePath .. ".baleTypes.baleType(?).wrappingState.key(?)#time", "Time of wrapping (0-1)")
	schema:register(XMLValueType.FLOAT, basePath .. ".baleTypes.baleType(?).wrappingState.key(?)#wrappingState", "Wrapping state for shader")
	schema:register(XMLValueType.STRING, basePath .. ".baleTypes.baleType(?).dropAnimations.dropAnimation(?)#name", "Drop animation name")
	schema:register(XMLValueType.FLOAT, basePath .. ".baleTypes.baleType(?).dropAnimations.dropAnimation(?)#animSpeed", "Drop animation speed", 1)
	schema:register(XMLValueType.L10N_STRING, basePath .. ".baleTypes.baleType(?).dropAnimations.dropAnimation(?)#text", "Text to display in the input help")
	schema:register(XMLValueType.STRING, basePath .. ".baleTypes.baleType(?).dropAnimations.dropAnimation(?)#inputAction", "Name of input action")
	schema:register(XMLValueType.BOOL, basePath .. ".baleTypes.baleType(?).dropAnimations.dropAnimation(?)#liftOnDrop", "Lift the tools attacher joint while the bale is dropped", false)
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath .. ".baleTypes.baleType(?)")
	BaleWrapper.registerWrapperFoilAnimationXMLPaths(schema, basePath .. ".baleTypes.baleType(?)")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#baleNode", "Bale Node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#wrapperNode", "Wrapper Node")
	schema:register(XMLValueType.INT, basePath .. "#wrapperRotAxis", "Wrapper rotation axis", 2)
	schema:register(XMLValueType.FLOAT, basePath .. ".wrapperAnimation.key(?)#time", "Key time")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".wrapperAnimation.key(?)#baleRot", "Bale rotation")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".wrapperAnimation.key(?)#wrapperRot", "Wrapper rotation", "0 0 0")
	schema:register(XMLValueType.FLOAT, basePath .. "#wrappingTime", "Wrapping duration", 5)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".wrapAnimNodes.wrapAnimNode(?)#node", "Wrap node")
	schema:register(XMLValueType.BOOL, basePath .. ".wrapAnimNodes.wrapAnimNode(?)#repeatWrapperRot", "Repeat wrapper rotation, so wrapper rotation is always between 0 and 360", false)
	schema:register(XMLValueType.INT, basePath .. ".wrapAnimNodes.wrapAnimNode(?)#normalizeRotationOnBaleDrop", "Normalize rotation on bale drop", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".wrapAnimNodes.wrapAnimNode(?).key(?)#wrapperRot", "Wrapper rotation")
	schema:register(XMLValueType.FLOAT, basePath .. ".wrapAnimNodes.wrapAnimNode(?).key(?)#wrapperTime", "Wrapper time")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".wrapAnimNodes.wrapAnimNode(?).key(?)#trans", "Trans", "0 0 0")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".wrapAnimNodes.wrapAnimNode(?).key(?)#rot", "Rotation", "0 0 0")
	schema:register(XMLValueType.VECTOR_SCALE, basePath .. ".wrapAnimNodes.wrapAnimNode(?).key(?)#scale", "Scale", "1 1 1")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".wrapNodes.wrapNode(?)#node", "Wrap node")
	schema:register(XMLValueType.BOOL, basePath .. ".wrapNodes.wrapNode(?)#wrapVisibility", "Visibility while wrapping", false)
	schema:register(XMLValueType.BOOL, basePath .. ".wrapNodes.wrapNode(?)#emptyVisibility", "Visibility while empty", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".wrapNodes.wrapNode(?)#maxWrapperRot", "Max. wrapper rotation")
	schema:register(XMLValueType.FLOAT, basePath .. ".wrappingState.key(?)#time", "Time of wrapping (0-1)")
	schema:register(XMLValueType.FLOAT, basePath .. ".wrappingState.key(?)#wrappingState", "Wrapping state for shader")
	schema:register(XMLValueType.FLOAT, basePath .. ".wrappingAnimationNodes#maxTime", "Max. time of animation nodes", "Wrapper anim time")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".wrappingAnimationNodes.key(?)#node", "Animation node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".wrappingAnimationNodes.key(?)#rootNode", "Reference node for rotation")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".wrappingAnimationNodes.key(?)#linkNode", "Node will be linked to this node while key is activated")
	schema:register(XMLValueType.FLOAT, basePath .. ".wrappingAnimationNodes.key(?)#time", "Time to activate key")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".wrappingAnimationNodes.key(?)#translation", "Translation of key")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".wrappingAnimationNodes#referenceNode", "Reference node")
	schema:register(XMLValueType.INT, basePath .. ".wrappingAnimationNodes#referenceAxis", "Reference axis", 1)
	schema:register(XMLValueType.ANGLE, basePath .. ".wrappingAnimationNodes#minRot", "Min. rotation", 0)
	schema:register(XMLValueType.ANGLE, basePath .. ".wrappingAnimationNodes#maxRot", "Max. rotation", 0)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".dropArea#node", "Node in the center of the drop area (if defined this area will be checked if something blocks this area)")
	schema:register(XMLValueType.FLOAT, basePath .. ".dropArea#width", "Width of area", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".dropArea#height", "Height of area", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".dropArea#length", "Length of area", 1)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".blockWrapArea#node", "Node in the center of the block area (if defined this area will be checked if it\'s clear to start the wrapping process)")
	schema:register(XMLValueType.FLOAT, basePath .. ".blockWrapArea#width", "Width of area", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".blockWrapArea#height", "Height of area", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".blockWrapArea#length", "Length of area", 1)
	BaleWrapper.registerWrapperFoilAnimationXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".wrappingCollisions.collision(?)#node", "Collision node")
	schema:register(XMLValueType.INT, basePath .. ".wrappingCollisions.collision(?)#activeCollisionMask", "Collision mask active")
	schema:register(XMLValueType.INT, basePath .. ".wrappingCollisions.collision(?)#inActiveCollisionMask", "Collision mask in active")
	schema:register(XMLValueType.L10N_STRING, basePath .. "#unloadBaleText", "Unload bale text", "\'action_unloadRoundBale\' for round bales and \'action_unloadSquareBale\' for square bales")
	schema:register(XMLValueType.BOOL, basePath .. "#skipUnsupportedBales", "Skip unsupported bales (pick them up and drop them instantly)")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "wrap(?)")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "start(?)")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "stop(?)")
	schema:register(XMLValueType.FLOAT, basePath .. ".sounds#wrappingEndTime", "Wrapping time to play end wrapping sound", 1)
end

function BaleWrapper.registerWrapperAnimationXMLPaths(schema, basePath, name)
	schema:register(XMLValueType.STRING, basePath .. ".animations." .. name .. "#animName", "Animation name", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".animations." .. name .. "#animSpeed", "Animation speed", 1)
	schema:register(XMLValueType.BOOL, basePath .. ".animations." .. name .. "#reverseAfterMove", "Reverse animation after playing", true)
	schema:register(XMLValueType.BOOL, basePath .. ".animations." .. name .. "#resetOnStart", "Reset animation on start", false)
end

function BaleWrapper.registerWrapperFoilAnimationXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".wrappingFoilAnimation#referenceNode", "Time reference node")
	schema:register(XMLValueType.INT, basePath .. ".wrappingFoilAnimation#referenceAxis", "Rotation axis")
	schema:register(XMLValueType.ANGLE, basePath .. ".wrappingFoilAnimation#minRot", "Min. reference rotation")
	schema:register(XMLValueType.ANGLE, basePath .. ".wrappingFoilAnimation#maxRot", "Max. reference rotation")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".wrappingFoilAnimation#clipNode", "Node which has clip assigned")
	schema:register(XMLValueType.STRING, basePath .. ".wrappingFoilAnimation#clipName", "Name of the clip to control")
end

function BaleWrapper.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadWrapperFromXML", BaleWrapper.loadWrapperFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadWrapperAnimationsFromXML", BaleWrapper.loadWrapperAnimationsFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadWrapperAnimCurveFromXML", BaleWrapper.loadWrapperAnimCurveFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadWrapperAnimNodesFromXML", BaleWrapper.loadWrapperAnimNodesFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadWrapperWrapNodesFromXML", BaleWrapper.loadWrapperWrapNodesFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadWrapperStateCurveFromXML", BaleWrapper.loadWrapperStateCurveFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadWrapperAnimationNodesFromXML", BaleWrapper.loadWrapperAnimationNodesFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadWrapperFoilAnimationFromXML", BaleWrapper.loadWrapperFoilAnimationFromXML)
	SpecializationUtil.registerFunction(vehicleType, "baleGrabberTriggerCallback", BaleWrapper.baleGrabberTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "allowsGrabbingBale", BaleWrapper.allowsGrabbingBale)
	SpecializationUtil.registerFunction(vehicleType, "pickupWrapperBale", BaleWrapper.pickupWrapperBale)
	SpecializationUtil.registerFunction(vehicleType, "getIsBaleWrappable", BaleWrapper.getIsBaleWrappable)
	SpecializationUtil.registerFunction(vehicleType, "getIsBaleDropAllowed", BaleWrapper.getIsBaleDropAllowed)
	SpecializationUtil.registerFunction(vehicleType, "onBaleWrapperDropOverlapCallback", BaleWrapper.onBaleWrapperDropOverlapCallback)
	SpecializationUtil.registerFunction(vehicleType, "getIsBaleWrappingAllowed", BaleWrapper.getIsBaleWrappingAllowed)
	SpecializationUtil.registerFunction(vehicleType, "onBaleWrapperBlockOverlapCallback", BaleWrapper.onBaleWrapperBlockOverlapCallback)
	SpecializationUtil.registerFunction(vehicleType, "updateWrappingState", BaleWrapper.updateWrappingState)
	SpecializationUtil.registerFunction(vehicleType, "doStateChange", BaleWrapper.doStateChange)
	SpecializationUtil.registerFunction(vehicleType, "updateWrapNodes", BaleWrapper.updateWrapNodes)
	SpecializationUtil.registerFunction(vehicleType, "playMoveToWrapper", BaleWrapper.playMoveToWrapper)
	SpecializationUtil.registerFunction(vehicleType, "setBaleWrapperType", BaleWrapper.setBaleWrapperType)
	SpecializationUtil.registerFunction(vehicleType, "getMatchingBaleTypeIndex", BaleWrapper.getMatchingBaleTypeIndex)
	SpecializationUtil.registerFunction(vehicleType, "setBaleWrapperAutomaticDrop", BaleWrapper.setBaleWrapperAutomaticDrop)
	SpecializationUtil.registerFunction(vehicleType, "setBaleWrapperDropAnimation", BaleWrapper.setBaleWrapperDropAnimation)
end

function BaleWrapper.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", BaleWrapper.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", BaleWrapper.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getShowConsumableEmptyWarning", BaleWrapper.getShowConsumableEmptyWarning)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRequiresPower", BaleWrapper.getRequiresPower)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getStandaloneMotorTargetRpm", BaleWrapper.getStandaloneMotorTargetRpm)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getStandaloneMotorLoad", BaleWrapper.getStandaloneMotorLoad)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", BaleWrapper.addToPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", BaleWrapper.removeFromPhysics)
end

function BaleWrapper.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", BaleWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", BaleWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", BaleWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", BaleWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", BaleWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", BaleWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", BaleWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", BaleWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", BaleWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", BaleWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterExternalActionEvents", BaleWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", BaleWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onFoldStateChanged", BaleWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onConsumableVariationChanged", BaleWrapper)
end

-- Local values: spec, baseKey
function BaleWrapper:onLoad(savegame)
	local v18_ = self.spec_baleWrapper
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wrapper", "vehicle.baleWrapper")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleGrabber", "vehicle.baleWrapper.grabber")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleWrapper.grabber#index", "vehicle.baleWrapper.grabber#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleWrapper.grabber#index", "vehicle.baleWrapper.grabber#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleWrapper.roundBaleWrapper#baleIndex", "vehicle.baleWrapper.roundBaleWrapper#baleNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleWrapper.roundBaleWrapper#wrapperIndex", "vehicle.baleWrapper.roundBaleWrapper#wrapperNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleWrapper.squareBaleWrapper#baleIndex", "vehicle.baleWrapper.squareBaleWrapper#baleNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleWrapper.squareBaleWrapper#wrapperIndex", "vehicle.baleWrapper.squareBaleWrapper#wrapperNode")
	v18_.roundBaleWrapper = {}
	self:loadWrapperFromXML(v18_.roundBaleWrapper, self.xmlFile, "vehicle.baleWrapper", "roundBaleWrapper")
	v18_.squareBaleWrapper = {}
	self:loadWrapperFromXML(v18_.squareBaleWrapper, self.xmlFile, "vehicle.baleWrapper", "squareBaleWrapper")
	v18_.currentWrapper = {}
	v18_.currentWrapperFoldMinLimit = self.xmlFile:getValue("vehicle.baleWrapper#foldMinLimit", 0)
	v18_.currentWrapperFoldMaxLimit = self.xmlFile:getValue("vehicle.baleWrapper#foldMaxLimit", 1)
	v18_.currentWrapper = v18_.roundBaleWrapper
	self:updateWrapNodes(false, true, 0)
	v18_.currentWrapper = v18_.squareBaleWrapper
	self:updateWrapNodes(false, true, 0)
	v18_.currentBaleTypeIndex = 1
	if v18_.roundBaleWrapper.baleNode == nil then
		if v18_.squareBaleWrapper.baleNode ~= nil then
			self:setBaleWrapperType(false, 1)
		end
	else
		self:setBaleWrapperType(true, 1)
	end
	v18_.baleGrabber = {}
	v18_.baleGrabber.grabNode = self.xmlFile:getValue("vehicle.baleWrapper.grabber#node", nil, self.components, self.i3dMappings)
	v18_.baleGrabber.triggerNode = self.xmlFile:getValue("vehicle.baleWrapper.grabber#triggerNode", nil, self.components, self.i3dMappings)
	if v18_.baleGrabber.triggerNode == nil then
		Logging.xmlWarning(self.xmlFile, "Missing bale grab trigger node \'%s\'. This is required for all bale wrappers.", "vehicle.baleWrapper.grabber#triggerNode")
	else
		addTrigger(v18_.baleGrabber.triggerNode, "baleGrabberTriggerCallback", self)
	end
	v18_.baleGrabber.nearestDistance = self.xmlFile:getValue("vehicle.baleWrapper.grabber#nearestDistance", 3)
	v18_.baleGrabber.balesInTrigger = {}
	v18_.baleToLoad = nil
	v18_.baleToMount = nil
	v18_.baleWrapperState = BaleWrapper.STATE_NONE
	v18_.grabberIsMoving = false
	v18_.hasBaleWrapper = true
	v18_.wrapColor = { 1, 1, 1 }
	v18_.showInvalidBaleWarning = false
	v18_.baleDropBlockedWarning = nil
	v18_.dropAnimationIndex = 1
	v18_.foundDropOverlappingObject = false
	v18_.foundDropOverlappingObjectTime = -math.huge
	v18_.foundBlockOverlappingObject = false
	v18_.automaticDrop = self.xmlFile:getValue("vehicle.baleWrapper.automaticDrop#enabled", Platform.gameplay.automaticBaleDrop)
	v18_.toggleableAutomaticDrop = self.xmlFile:getValue("vehicle.baleWrapper.automaticDrop#toggleable", not Platform.gameplay.automaticBaleDrop)
	v18_.toggleAutomaticDropTextPos = self.xmlFile:getValue("vehicle.baleWrapper.automaticDrop#textPos", "action_toggleAutomaticBaleDropPos", self.customEnvironment)
	v18_.toggleAutomaticDropTextNeg = self.xmlFile:getValue("vehicle.baleWrapper.automaticDrop#textNeg", "action_toggleAutomaticBaleDropNeg", self.customEnvironment)
	v18_.texts = {}
	v18_.texts.warningFoldingWrapping = g_i18n:getText("warning_foldingNotWhileWrapping")
	v18_.texts.warningBaleNotSupported = g_i18n:getText("warning_baleNotSupported")
	v18_.texts.warningDropAreaBlocked = g_i18n:getText("warning_baleWrapperDropAreaBlocked")
end

-- Local values: spec, filename, baleToLoad
function BaleWrapper:onPostLoad(savegame)
	local v21_ = self.spec_baleWrapper
	if savegame ~= nil and not savegame.resetVehicles then
		local v22_ = savegame.xmlFile:getValue(savegame.key .. ".baleWrapper.bale#filename")
		if v22_ ~= nil then
			local v23_ = {
				["filename"] = NetworkUtil.convertFromNetworkFilename(v22_),
				["wrapperTime"] = savegame.xmlFile:getValue(savegame.key .. ".baleWrapper#wrapperTime", 0),
				["translation"] = { 0, 0, 0 },
				["rotation"] = { 0, 0, 0 },
				["attributes"] = {}
			}
			Bale.loadBaleAttributesFromXMLFile(v23_.attributes, savegame.xmlFile, savegame.key .. ".baleWrapper.bale", savegame.resetVehicles)
			v21_.baleToLoad = v23_
		end
	end
end

-- Local values: spec, isRoundBaleWrapper, wrappingAnimationConfig, configKey, defaultText
function BaleWrapper:loadWrapperFromXML(wrapper, xmlFile, baseKey, wrapperName)
	local v_u_29_ = self.spec_baleWrapper
	local v_u_30_ = wrapper == v_u_29_.roundBaleWrapper
	local v31_ = Utils.getNoNil(self.configurations.wrappingAnimation, 1)
	local v_u_32_ = string.format("vehicle.baleWrapper.wrappingAnimationConfigurations.wrappingAnimationConfiguration(%d)", v31_ - 1)
	self:loadWrapperAnimationsFromXML(wrapper, xmlFile, baseKey, v_u_32_, "." .. wrapperName .. ".animations")
	wrapper.defaultAnimations = wrapper.animations
	local v33_ = baseKey .. "." .. wrapperName
	wrapper.baleNode = xmlFile:getValue(v33_ .. "#baleNode", nil, self.components, self.i3dMappings)
	wrapper.wrapperNode = xmlFile:getValue(v33_ .. "#wrapperNode", nil, self.components, self.i3dMappings)
	wrapper.wrapperRotAxis = xmlFile:getValue(v33_ .. "#wrapperRotAxis", 2)
	wrapper.animTime = xmlFile:getValue(v33_ .. "#wrappingTime", 5) * 1000
	wrapper.currentTime = 0
	wrapper.currentBale = nil
	wrapper.allowedBaleTypes = {}
	xmlFile:iterate(v33_ .. ".baleTypes.baleType", function(p34_, p35_)
		-- upvalues: (copy) self, (copy) xmlFile, (copy) v_u_32_, (copy) wrapperName, (copy) wrapper, (copy) v_u_29_, (copy) v_u_30_
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, p35_ .. "#fillType")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, p35_ .. "#wrapperBaleFilename")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, p35_ .. "#minBaleDiameter", p35_ .. "#diameter")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, p35_ .. "#maxBaleDiameter", p35_ .. "#diameter")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, p35_ .. "#minBaleWidth", p35_ .. "#width")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, p35_ .. "#maxBaleWidth", p35_ .. "#width")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, p35_ .. "#minBaleHeight", p35_ .. "#height")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, p35_ .. "#maxBaleHeight", p35_ .. "#height")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, p35_ .. "#minBaleLength", p35_ .. "#length")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, p35_ .. "#maxBaleLength", p35_ .. "#length")
		local v36_ = {
			["diameter"] = MathUtil.round(xmlFile:getValue(p35_ .. "#diameter", 0), 2),
			["width"] = MathUtil.round(xmlFile:getValue(p35_ .. "#width", 0), 2),
			["height"] = MathUtil.round(xmlFile:getValue(p35_ .. "#height", 0), 2),
			["length"] = MathUtil.round(xmlFile:getValue(p35_ .. "#length", 0), 2),
			["wrapDiffuse"] = xmlFile:getValue(p35_ .. ".textures#diffuse")
		}
		if v36_.wrapDiffuse ~= nil then
			v36_.wrapDiffuse = Utils.getFilename(v36_.wrapDiffuse, self.baseDirectory)
			if v36_.wrapDiffuse ~= nil and not textureFileExists(v36_.wrapDiffuse) then
				Logging.xmlWarning(self.xmlFile, "Bale wrap diffuse map \'%s\' does not exist.", v36_.wrapDiffuse)
				v36_.wrapDiffuse = nil
			end
		end
		v36_.wrapNormal = xmlFile:getValue(p35_ .. ".textures#normal")
		if v36_.wrapNormal ~= nil then
			v36_.wrapNormal = Utils.getFilename(v36_.wrapNormal, self.baseDirectory)
			if v36_.wrapNormal ~= nil and not textureFileExists(v36_.wrapNormal) then
				Logging.xmlWarning(self.xmlFile, "Bale wrap normal map \'%s\' does not exist.", v36_.wrapNormal)
				v36_.wrapNormal = nil
			end
		end
		self:loadWrapperAnimationsFromXML(v36_, xmlFile, p35_, string.format("%s.%s.baleTypes.baleType(%d)", v_u_32_, wrapperName, p34_ - 1), ".animations", wrapper.animations)
		self:loadWrapperFoilAnimationFromXML(v36_, xmlFile, p35_)
		v36_.changeObjects = {}
		ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, p35_, v36_.changeObjects, self.components, self)
		v36_.skipWrapping = xmlFile:getValue(p35_ .. "#skipWrapping", false)
		v36_.forceWhileFolding = xmlFile:getValue(p35_ .. "#forceWhileFolding", false)
		if v36_.forceWhileFolding then
			v_u_29_.foldedBaleType = {
				["isRoundBaleWrapper"] = v_u_30_,
				["baleTypeIndex"] = p34_
			}
		end
		v36_.wrapUsage = xmlFile:getValue(p35_ .. "#wrapUsage", 0.1) / wrapper.animTime
		self:loadWrapperStateCurveFromXML(v36_, xmlFile, p35_)
		v36_.dropAnimations = {}
		for _, v37_ in self.xmlFile:iterator(p35_ .. ".dropAnimations.dropAnimation") do
			local v38_ = {
				["name"] = xmlFile:getValue(v37_ .. "#name"),
				["animSpeed"] = xmlFile:getValue(v37_ .. "#animSpeed", 1),
				["text"] = xmlFile:getValue(v37_ .. "#text", nil, self.customEnvironment, false),
				["inputAction"] = xmlFile:getValue(v37_ .. "#inputAction")
			}
			if v38_.inputAction ~= nil then
				v38_.inputAction = InputAction[v38_.inputAction]
			end
			v38_.liftOnDrop = xmlFile:getValue(v37_ .. "#liftOnDrop", false)
			local v39_ = v36_.dropAnimations
			table.insert(v39_, v38_)
		end
		local v40_ = wrapper.allowedBaleTypes
		table.insert(v40_, v36_)
	end)
	self:loadWrapperAnimCurveFromXML(wrapper, xmlFile, v33_)
	self:loadWrapperAnimNodesFromXML(wrapper, xmlFile, v33_)
	self:loadWrapperWrapNodesFromXML(wrapper, xmlFile, v33_)
	self:loadWrapperStateCurveFromXML(wrapper, xmlFile, v33_)
	self:loadWrapperAnimationNodesFromXML(wrapper, xmlFile, v33_, wrapper.animTime)
	self:loadWrapperFoilAnimationFromXML(wrapper, xmlFile, v33_, true)
	wrapper.wrappingFoilAnimationDefault = wrapper.wrappingFoilAnimation
	wrapper.dropArea = {}
	wrapper.dropArea.node = self.xmlFile:getValue(v33_ .. ".dropArea#node", nil, self.components, self.i3dMappings)
	wrapper.dropArea.width = self.xmlFile:getValue(v33_ .. ".dropArea#width", 1)
	wrapper.dropArea.height = self.xmlFile:getValue(v33_ .. ".dropArea#height", 1)
	wrapper.dropArea.length = self.xmlFile:getValue(v33_ .. ".dropArea#length", 1)
	wrapper.blockWrapArea = {}
	wrapper.blockWrapArea.node = self.xmlFile:getValue(v33_ .. ".blockWrapArea#node", nil, self.components, self.i3dMappings)
	wrapper.blockWrapArea.width = self.xmlFile:getValue(v33_ .. ".blockWrapArea#width", 1)
	wrapper.blockWrapArea.height = self.xmlFile:getValue(v33_ .. ".blockWrapArea#height", 1)
	wrapper.blockWrapArea.length = self.xmlFile:getValue(v33_ .. ".blockWrapArea#length", 1)
	wrapper.unloadBaleText = xmlFile:getValue(v33_ .. "#unloadBaleText", v_u_30_ and "action_unloadRoundBale" or "action_unloadSquareBale", self.customEnvironment)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, v33_ .. "#skipWrappingFillTypes", v33_ .. "#skipUnsupportedBales")
	wrapper.skipUnsupportedBales = self.xmlFile:getValue(v33_ .. "#skipUnsupportedBales", false)
	if self.isClient then
		wrapper.samples = {}
		wrapper.samples.wrap = g_soundManager:loadSamplesFromXML(self.xmlFile, v33_ .. ".sounds", "wrap", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		wrapper.samples.start = g_soundManager:loadSamplesFromXML(self.xmlFile, v33_ .. ".sounds", "start", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		wrapper.samples.stop = g_soundManager:loadSamplesFromXML(self.xmlFile, v33_ .. ".sounds", "stop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		wrapper.wrappingSoundEndTime = xmlFile:getValue(v33_ .. ".sounds#wrappingEndTime", 1)
	end
end

-- Local values: i, animType, key, configTypeKey, anim
function BaleWrapper:loadWrapperAnimationsFromXML(target, xmlFile, baseKey, configKey, animationsKey, parentAnimations)
	target.animations = {}
	if parentAnimations ~= nil then
		local v48_ = target.animations
		setmetatable(v48_, {
			["__index"] = parentAnimations
		})
	end
	for v49_ = 1, #BaleWrapper.ANIMATION_NAMES do
		local v50_ = BaleWrapper.ANIMATION_NAMES[v49_]
		local v51_ = baseKey .. animationsKey .. "." .. v50_
		local v52_ = configKey .. animationsKey .. "." .. v50_
		if not xmlFile:hasProperty(v52_) then
			v52_ = v51_
		end
		local v53_ = {
			["animName"] = xmlFile:getValue(v52_ .. "#animName"),
			["animSpeed"] = xmlFile:getValue(v52_ .. "#animSpeed", 1),
			["reverseAfterMove"] = xmlFile:getValue(v52_ .. "#reverseAfterMove", true)
		}
		if xmlFile:getValue(v52_ .. "#resetOnStart", false) then
			self:playAnimation(v53_.animName, -1, 0.1, true)
			AnimatedVehicle.updateAnimationByName(self, v53_.animName, 9999999, true)
		end
		if parentAnimations == nil or v53_.animName ~= nil then
			target.animations[v50_] = v53_
		end
	end
end

function BaleWrapper:loadWrapperAnimCurveFromXML(target, xmlFile, baseKey)
	target.animCurve = AnimCurve.new(linearInterpolatorN)
	xmlFile:iterate(baseKey .. "wrapperAnimation.key", function(_, p57_)
		-- upvalues: (copy) xmlFile, (copy) target
		local v58_ = xmlFile:getValue(p57_ .. "#time")
		local v59_, v60_, v61_ = xmlFile:getValue(p57_ .. "#baleRot")
		if v59_ == nil or (v60_ == nil or v61_ == nil) then
			return false
		end
		local v62_, v63_, v64_ = xmlFile:getValue(p57_ .. "#wrapperRot", "0 0 0")
		target.animCurve:addKeyframe({
			v59_,
			v60_,
			v61_,
			v62_,
			v63_,
			v64_,
			["time"] = v58_
		})
	end)
end

function BaleWrapper:loadWrapperAnimNodesFromXML(target, xmlFile, baseKey)
	target.wrapAnimNodes = {}
	xmlFile:iterate(baseKey .. ".wrapAnimNodes.wrapAnimNode", function(_, p69_)
		-- upvalues: (copy) self, (copy) xmlFile, (copy) target
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, p69_ .. "#index", p69_ .. "#node")
		local v_u_70_ = {
			["nodeId"] = xmlFile:getValue(p69_ .. "#node", nil, self.components, self.i3dMappings)
		}
		if v_u_70_.nodeId ~= nil then
			v_u_70_.useWrapperRot = false
			v_u_70_.animCurve = AnimCurve.new(linearInterpolatorN)
			local v_u_71_ = 0
			xmlFile:iterate(p69_ .. ".key", function(_, p72_)
				-- upvalues: (ref) xmlFile, (copy) v_u_70_, (ref) v_u_71_
				local v73_ = xmlFile:getValue(p72_ .. "#wrapperRot")
				local v74_ = xmlFile:getValue(p72_ .. "#wrapperTime")
				if v73_ == nil and v74_ == nil then
					return false
				end
				v_u_70_.useWrapperRot = v73_ ~= nil
				local v75_, v76_, v77_ = xmlFile:getValue(p72_ .. "#trans", "0 0 0")
				local v78_, v79_, v80_ = xmlFile:getValue(p72_ .. "#rot", "0 0 0")
				local v81_, v82_, v83_ = xmlFile:getValue(p72_ .. "#scale", "1 1 1")
				if v73_ == nil then
					v_u_70_.animCurve:addKeyframe({
						v75_,
						v76_,
						v77_,
						v78_,
						v79_,
						v80_,
						v81_,
						v82_,
						v83_,
						["time"] = v74_
					})
				else
					v_u_70_.animCurve:addKeyframe({
						v75_,
						v76_,
						v77_,
						v78_,
						v79_,
						v80_,
						v81_,
						v82_,
						v83_,
						["time"] = math.rad(v73_)
					})
				end
				v_u_71_ = v_u_71_ + 1
			end)
			if v_u_71_ > 0 then
				v_u_70_.repeatWrapperRot = xmlFile:getValue(p69_ .. "#repeatWrapperRot", false)
				v_u_70_.normalizeRotationOnBaleDrop = xmlFile:getValue(p69_ .. "#normalizeRotationOnBaleDrop", 0)
				local v84_ = target.wrapAnimNodes
				table.insert(v84_, v_u_70_)
			end
		end
	end)
end

function BaleWrapper:loadWrapperWrapNodesFromXML(target, xmlFile, baseKey)
	target.wrapNodes = {}
	xmlFile:iterate(baseKey .. ".wrapNodes.wrapNode", function(_, p89_)
		-- upvalues: (copy) self, (copy) xmlFile, (copy) target
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, p89_ .. "#index", p89_ .. "#node")
		local v90_ = {
			["nodeId"] = xmlFile:getValue(p89_ .. "#node", nil, self.components, self.i3dMappings),
			["wrapVisibility"] = xmlFile:getValue(p89_ .. "#wrapVisibility", false),
			["emptyVisibility"] = xmlFile:getValue(p89_ .. "#emptyVisibility", false)
		}
		if v90_.nodeId ~= nil and (v90_.wrapVisibility or v90_.emptyVisibility) then
			v90_.maxWrapperRot = xmlFile:getValue(p89_ .. "#maxWrapperRot", math.huge)
			local v91_ = target.wrapNodes
			table.insert(v91_, v90_)
		end
	end)
end

function BaleWrapper:loadWrapperStateCurveFromXML(target, xmlFile, baseKey)
	target.wrappingStateCurve = AnimCurve.new(linearInterpolator1)
	xmlFile:iterate(baseKey .. ".wrappingState.key", function(_, p95_)
		-- upvalues: (copy) xmlFile, (copy) target
		local v96_ = xmlFile:getValue(p95_ .. "#time")
		local v97_ = {
			xmlFile:getValue(p95_ .. "#wrappingState"),
			["time"] = v96_
		}
		target.wrappingStateCurve:addKeyframe(v97_)
	end)
	if #target.wrappingStateCurve.keyframes == 0 then
		target.wrappingStateCurve = nil
	end
end

-- Local values: maxTime, j, wrappingAnimationNode, x, y, z
function BaleWrapper:loadWrapperAnimationNodesFromXML(target, xmlFile, baseKey, animTime)
	local v_u_103_ = xmlFile:getValue(baseKey .. ".wrappingAnimationNodes#maxTime", animTime / 1000)
	target.wrappingAnimationNodes = {}
	target.wrappingAnimationNodes.nodes = {}
	target.wrappingAnimationNodes.nodeToRootNode = {}
	xmlFile:iterate(baseKey .. ".wrappingAnimationNodes.key", function(_, p104_)
		-- upvalues: (copy) xmlFile, (copy) self, (copy) v_u_103_, (copy) target
		local v105_ = xmlFile:getValue(p104_ .. "#time")
		local v106_ = xmlFile:getValue(p104_ .. "#node", nil, self.components, self.i3dMappings)
		local v107_ = xmlFile:getValue(p104_ .. "#rootNode", nil, self.components, self.i3dMappings)
		local v108_ = xmlFile:getValue(p104_ .. "#linkNode", nil, self.components, self.i3dMappings)
		if v105_ ~= nil and v106_ ~= nil then
			local v109_ = {
				["time"] = v105_ / v_u_103_,
				["nodeId"] = v106_,
				["linkNode"] = v108_,
				["parent"] = getParent(v106_),
				["translation"] = xmlFile:getValue(p104_ .. "#translation", nil, true)
			}
			if v109_.translation == nil then
				Logging.xmlWarning(xmlFile, "Missing values for \'%s\'", p104_ .. "#translation")
				return
			end
			if v107_ ~= nil then
				target.wrappingAnimationNodes.nodeToRootNode[v106_] = v107_
			end
			local v110_ = target.wrappingAnimationNodes.nodes
			table.insert(v110_, v109_)
		end
	end)
	for v111_ = 1, #target.wrappingAnimationNodes.nodes do
		local v112_ = target.wrappingAnimationNodes.nodes[v111_]
		if v112_.time == 0 then
			local v113_ = setTranslation
			local v114_ = v112_.nodeId
			local v115_ = v112_.translation
			v113_(v114_, unpack(v115_))
			if v112_.linkNode ~= nil then
				local v116_ = localToWorld
				local v117_ = v112_.parent
				local v118_ = v112_.translation
				local v119_, v120_, v121_ = v116_(v117_, unpack(v118_))
				link(v112_.linkNode, v112_.nodeId)
				setWorldTranslation(v112_.nodeId, v119_, v120_, v121_)
			end
		end
	end
	target.wrappingAnimationNodes.referenceNode = xmlFile:getValue(baseKey .. ".wrappingAnimationNodes#referenceNode", nil, self.components, self.i3dMappings)
	target.wrappingAnimationNodes.referenceAxis = xmlFile:getValue(baseKey .. ".wrappingAnimationNodes#referenceAxis", 2)
	target.wrappingAnimationNodes.referenceMinRot = xmlFile:getValue(baseKey .. ".wrappingAnimationNodes#minRot", 0)
	target.wrappingAnimationNodes.referenceMaxRot = xmlFile:getValue(baseKey .. ".wrappingAnimationNodes#maxRot", 0)
	if target.wrappingAnimationNodes.referenceNode ~= nil then
		target.wrappingAnimationNodes.referenceNodeRotation = { getRotation(target.wrappingAnimationNodes.referenceNode) }
	end
	target.wrappingAnimationNodes.lastTime = -1
	target.wrappingAnimationNodes.currentIndex = 0
end

-- Local values: wrappingFoilAnimation
function BaleWrapper:loadWrapperFoilAnimationFromXML(target, xmlFile, baseKey, isDefault)
	local v127_ = {
		["referenceNode"] = xmlFile:getValue(baseKey .. ".wrappingFoilAnimation#referenceNode", nil, self.components, self.i3dMappings)
	}
	if v127_.referenceNode ~= nil then
		v127_.referenceAxis = xmlFile:getValue(baseKey .. ".wrappingFoilAnimation#referenceAxis", 2)
		v127_.referenceMinRot = xmlFile:getValue(baseKey .. ".wrappingFoilAnimation#minRot", 0)
		v127_.referenceMaxRot = xmlFile:getValue(baseKey .. ".wrappingFoilAnimation#maxRot", 0)
		v127_.referenceNodeRotation = { 0, 0, 0 }
		v127_.clipNode = xmlFile:getValue(baseKey .. ".wrappingFoilAnimation#clipNode", nil, self.components, self.i3dMappings)
		if v127_.clipNode ~= nil then
			v127_.animationClip = xmlFile:getValue(baseKey .. ".wrappingFoilAnimation#clipName")
			if v127_.animationClip == nil then
				Logging.xmlWarning(self.xmlFile, "Missing clipName for foil animation \'%s\'", baseKey .. ".wrappingFoilAnimation")
				return
			else
				v127_.animationCharSet = getAnimCharacterSet(v127_.clipNode)
				if v127_.animationCharSet == 0 then
					Logging.xmlWarning(self.xmlFile, "Unable to find animation clip \'%s\' on node \'%s\' in \'%s\'", v127_.animationClip, getName(v127_.clipNode), baseKey .. ".wrappingFoilAnimation")
					return
				else
					v127_.animationClipIndex = getAnimClipIndex(v127_.animationCharSet, v127_.animationClip)
					if v127_.animationClipIndex >= 0 then
						v127_.animationClipDuration = getAnimClipDuration(v127_.animationCharSet, v127_.animationClipIndex)
						if isDefault then
							clearAnimTrackClip(v127_.animationCharSet, 0)
							assignAnimTrackClip(v127_.animationCharSet, 0, v127_.animationClipIndex)
							enableAnimTrack(v127_.animationCharSet, 0)
							setAnimTrackTime(v127_.animationCharSet, 0, 0, true)
							disableAnimTrack(v127_.animationCharSet, 0)
						end
						v127_.lastTime = 0
						target.wrappingFoilAnimation = v127_
					else
						Logging.xmlWarning(self.xmlFile, "Unable to find animation clip \'%s\' on node \'%s\' in \'%s\'", v127_.animationClip, getName(v127_.clipNode), baseKey .. ".wrappingFoilAnimation")
					end
				end
			end
		end
		Logging.xmlWarning(self.xmlFile, "Missing clipNode for foil animation \'%s\'", baseKey .. ".wrappingFoilAnimation")
	end
end

-- Local values: spec, v, baleObject, x, y, z, rx, ry, rz, wrapperState, wrapAnimation, wrappingTime
function BaleWrapper:onLoadFinished(savegame)
	local v129_ = self.spec_baleWrapper
	if v129_.baleToLoad ~= nil then
		local v130_ = v129_.baleToLoad
		v129_.baleToLoad = nil
		local v131_ = Bale.new(self.isServer, self.isClient)
		local v132_ = v130_.translation
		local v133_, v134_, v135_ = unpack(v132_)
		local v136_ = v130_.rotation
		local v137_, v138_, v139_ = unpack(v136_)
		if v131_:loadFromConfigXML(v130_.filename, v133_, v134_, v135_, v137_, v138_, v139_, v130_.attributes.uniqueId) then
			v131_:applyBaleAttributes(v130_.attributes)
			v131_:register()
			if v131_.nodeId ~= nil and v131_.nodeId ~= 0 then
				self:doStateChange(BaleWrapper.CHANGE_GRAB_BALE, NetworkUtil.getObjectId(v131_))
				self:doStateChange(BaleWrapper.CHANGE_DROP_BALE_AT_GRABBER)
				self:doStateChange(BaleWrapper.CHANGE_WRAPPING_START)
				v129_.currentWrapper.currentTime = v130_.wrapperTime
				local v140_ = v130_.wrapperTime / v129_.currentWrapper.animTime
				v131_:setWrappingState((math.min(v140_, 1)))
				local v141_ = v129_.currentWrapper.animations.wrapBale
				local v142_ = v129_.currentWrapper.currentTime / v129_.currentWrapper.animTime
				self:updateWrappingState(v142_)
				AnimatedVehicle.updateAnimations(self, 99999999, true)
				if v142_ < 1 then
					self:setAnimationTime(v141_.animName, v142_, true)
					self:playAnimation(v141_.animName, v141_.animSpeed, v142_, true)
					return
				end
				self:doStateChange(BaleWrapper.CHANGE_WRAPPING_BALE_FINSIHED)
				self:setAnimationTime(v141_.animName, v142_, true)
				v129_.setWrappingStateFinished = false
			end
		end
	end
end

-- Local values: spec, baleId, bale
function BaleWrapper:onDelete()
	local v144_ = self.spec_baleWrapper
	local v145_
	if v144_.currentWrapper == nil or v144_.currentWrapper.currentBale == nil then
		v145_ = nil
	else
		v145_ = v144_.currentWrapper.currentBale
	end
	if v144_.baleGrabber ~= nil and v144_.baleGrabber.currentBale ~= nil then
		v145_ = v144_.baleGrabber.currentBale
	end
	if v145_ ~= nil then
		local v146_ = NetworkUtil.getObject(v145_)
		if v146_ ~= nil then
			if self.isServer then
				if self.isReconfigurating == nil or not self.isReconfigurating then
					v146_:unmountKinematic()
					v146_:setNeedsSaving(true)
					v146_:setCanBeSold(true)
				else
					v146_:delete()
				end
			else
				v146_:unmountKinematic()
				v146_:setNeedsSaving(true)
				v146_:setCanBeSold(true)
			end
		end
	end
	if v144_.baleGrabber ~= nil and v144_.baleGrabber.triggerNode ~= nil then
		removeTrigger(v144_.baleGrabber.triggerNode)
	end
	if v144_.roundBaleWrapper ~= nil then
		g_soundManager:deleteSamples(v144_.roundBaleWrapper.samples.wrap)
		g_soundManager:deleteSamples(v144_.roundBaleWrapper.samples.start)
		g_soundManager:deleteSamples(v144_.roundBaleWrapper.samples.stop)
	end
	if v144_.squareBaleWrapper ~= nil then
		g_soundManager:deleteSamples(v144_.squareBaleWrapper.samples.wrap)
		g_soundManager:deleteSamples(v144_.squareBaleWrapper.samples.start)
		g_soundManager:deleteSamples(v144_.squareBaleWrapper.samples.stop)
	end
end

-- Local values: spec, baleServerId, bale
function BaleWrapper:saveToXMLFile(xmlFile, key, usedModNames)
	local v150_ = self.spec_baleWrapper
	local v151_ = v150_.baleGrabber.currentBale
	if v151_ == nil then
		v151_ = v150_.currentWrapper.currentBale
	end
	xmlFile:setValue(key .. "#wrapperTime", v150_.currentWrapper.currentTime)
	if v151_ ~= nil then
		local v152_ = NetworkUtil.getObject(v151_)
		if v152_ ~= nil then
			v152_:saveToXMLFile(xmlFile, key .. ".bale")
		end
	end
end

-- Local values: spec, isRoundBaleWrapper, baleTypeIndex, wrapperState, baleServerId, wrapperTime, wrapAnimation, wrappingTime, wrapAnimation
function BaleWrapper:onReadStream(streamId, connection)
	if connection:getIsServer() then
		local v156_ = self.spec_baleWrapper
		self:setBaleWrapperType(streamReadBool(streamId), (streamReadUIntN(streamId, 8)))
		local v157_ = streamReadUIntN(streamId, BaleWrapper.STATE_NUM_BITS)
		if BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER <= v157_ then
			local v158_
			if v157_ == BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM then
				v158_ = nil
			else
				v158_ = NetworkUtil.readNodeObjectId(streamId)
			end
			if v157_ == BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER then
				self:doStateChange(BaleWrapper.CHANGE_GRAB_BALE, v158_)
				AnimatedVehicle.updateAnimations(self, 99999999, true)
				return
			end
			if v157_ == BaleWrapper.STATE_MOVING_GRABBER_TO_WORK then
				self.baleGrabber.currentBale = v158_
				self:doStateChange(BaleWrapper.CHANGE_DROP_BALE_AT_GRABBER)
				AnimatedVehicle.updateAnimations(self, 99999999, true)
				return
			end
			if v157_ == BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM then
				v156_.baleWrapperState = BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM
			else
				self:doStateChange(BaleWrapper.CHANGE_GRAB_BALE, v158_)
				AnimatedVehicle.updateAnimations(self, 99999999, true)
				v156_.currentWrapper.currentBale = v158_
				self:doStateChange(BaleWrapper.CHANGE_DROP_BALE_AT_GRABBER)
				AnimatedVehicle.updateAnimations(self, 99999999, true)
				self:updateWrapNodes(true, false, 0)
				if v157_ == BaleWrapper.STATE_WRAPPER_WRAPPING_BALE then
					self:doStateChange(BaleWrapper.CHANGE_WRAPPING_START)
					local v159_ = streamReadFloat32(streamId)
					v156_.currentWrapper.currentTime = v159_
					local v160_ = v156_.currentWrapper.animations.wrapBale
					local v161_ = v156_.currentWrapper.currentTime / v156_.currentWrapper.animTime
					self:setAnimationStopTime(v160_.animName, v161_)
					AnimatedVehicle.updateAnimationByName(self, v160_.animName, 9999999, true)
					self:updateWrappingState(v161_, true)
					if v161_ < 1 then
						self:playAnimation(v160_.animName, v160_.animSpeed, self:getAnimationTime(v160_.animName), true, false)
						return
					end
				else
					local v162_ = v156_.currentWrapper.animations.wrapBale
					if v162_.animName ~= nil then
						self:playAnimation(v162_.animName, v162_.animSpeed, nil, true)
						AnimatedVehicle.updateAnimationByName(self, v162_.animName, 9999999, true)
					end
					v156_.currentWrapper.currentTime = v156_.currentWrapper.animTime
					self:updateWrappingState(1, true)
					self:doStateChange(BaleWrapper.CHANGE_WRAPPING_BALE_FINSIHED)
					AnimatedVehicle.updateAnimations(self, 99999999, true)
					if BaleWrapper.STATE_WRAPPER_DROPPING_BALE <= v157_ then
						self:doStateChange(BaleWrapper.CHANGE_WRAPPER_START_DROP_BALE)
						AnimatedVehicle.updateAnimations(self, 99999999, true)
						return
					end
				end
			end
		end
	end
end

-- Local values: spec, wrapperState
function BaleWrapper:onWriteStream(streamId, connection)
	if not connection:getIsServer() then
		local v166_ = self.spec_baleWrapper
		streamWriteBool(streamId, v166_.currentWrapper == v166_.roundBaleWrapper)
		streamWriteUIntN(streamId, v166_.currentBaleTypeIndex, 8)
		local v167_ = v166_.baleWrapperState
		streamWriteUIntN(streamId, v167_, BaleWrapper.STATE_NUM_BITS)
		if BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER <= v167_ and v167_ ~= BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM then
			if v167_ == BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER then
				NetworkUtil.writeNodeObjectId(streamId, v166_.baleGrabber.currentBale)
			else
				NetworkUtil.writeNodeObjectId(streamId, v166_.currentWrapper.currentBale)
			end
		end
		if v167_ == BaleWrapper.STATE_WRAPPER_WRAPPING_BALE then
			streamWriteFloat32(streamId, v166_.currentWrapper.currentTime)
		end
	end
end

-- Local values: spec, bale, x, y, z, rx, ry, rz, wrapper, baleType, wrappingTime
function BaleWrapper:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v170_ = self.spec_baleWrapper
	if v170_.baleToMount ~= nil then
		local v171_ = NetworkUtil.getObject(v170_.baleToMount.serverId)
		if v171_ ~= nil then
			local v172_ = v170_.baleToMount.trans
			local v173_, v174_, v175_ = unpack(v172_)
			local v176_ = v170_.baleToMount.rot
			local v177_, v178_, v179_ = unpack(v176_)
			v171_:mountKinematic(self, v170_.baleToMount.linkNode, v173_, v174_, v175_, v177_, v178_, v179_)
			v171_:setCanBeSold(false)
			v171_:setNeedsSaving(false)
			v170_.baleToMount = nil
			if v170_.baleWrapperState == BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER then
				self:playMoveToWrapper(v171_)
			end
		end
	end
	if v170_.baleWrapperState == BaleWrapper.STATE_WRAPPER_WRAPPING_BALE then
		local v180_ = v170_.currentWrapper
		local v181_ = v180_.allowedBaleTypes[v170_.currentBaleTypeIndex]
		self:updateConsumable(BaleWrapper.CONSUMABLE_TYPE_NAME, -v181_.wrapUsage * dt, true)
		local v182_ = v180_.currentTime + dt
		local v183_ = v170_.currentWrapper.animTime
		v180_.currentTime = math.min(v182_, v183_)
		local v184_ = v180_.currentTime / v180_.animTime
		self:updateWrappingState(v184_)
		self:raiseActive()
		if self.isClient then
			if v180_.wrappingSoundEndTime <= v184_ then
				if g_soundManager:getIsSamplePlaying(v180_.samples.wrap[1]) then
					g_soundManager:stopSamples(v180_.samples.wrap)
					g_soundManager:playSamples(v180_.samples.stop)
					return
				end
			elseif not g_soundManager:getIsSamplePlaying(v180_.samples.wrap[1]) then
				g_soundManager:playSamples(v180_.samples.wrap)
			end
		end
	end
end

-- Local values: spec, nearestBaleWrappable, nearestBale, nearestBaleTypeIndex, bale, isPowered, _, dropIsAllowed, warning
function BaleWrapper:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v186_ = self.spec_baleWrapper
	v186_.showInvalidBaleWarning = false
	v186_.baleDropBlockedWarning = nil
	if self:allowsGrabbingBale() and (v186_.baleGrabber.grabNode ~= nil and v186_.baleGrabber.currentBale == nil) then
		local v187_, v188_, v189_ = BaleWrapper.getBaleInRange(self, v186_.baleGrabber.grabNode, v186_.baleGrabber.nearestDistance)
		if v188_ then
			if v187_ == nil and not (v188_.isRoundbale and v186_.roundBaleWrapper.skipUnsupportedBales) and not v186_.squareBaleWrapper.skipUnsupportedBales then
				if self.isClient and (v188_ and v186_.lastDroppedBaleId ~= NetworkUtil.getObjectId(v188_)) then
					v186_.showInvalidBaleWarning = true
				end
			elseif self.isServer then
				self:pickupWrapperBale(v187_ or v188_, v189_)
			end
		end
	end
	if self.isServer and v186_.baleWrapperState ~= BaleWrapper.STATE_NONE then
		if v186_.baleWrapperState == BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER then
			if not self:getIsAnimationPlaying(v186_.currentWrapper.animations.moveToWrapper.animName) then
				g_server:broadcastEvent(BaleWrapperStateEvent.new(self, BaleWrapper.CHANGE_DROP_BALE_AT_GRABBER), true, nil, self)
			end
		elseif v186_.baleWrapperState == BaleWrapper.STATE_MOVING_GRABBER_TO_WORK then
			if not self:getIsAnimationPlaying(v186_.currentWrapper.animations.moveToWrapper.animName) then
				local v190_ = NetworkUtil.getObject(v186_.currentWrapper.currentBale)
				if v190_ == nil or v190_.supportsWrapping then
					if self:getIsBaleWrappingAllowed() then
						g_server:broadcastEvent(BaleWrapperStateEvent.new(self, BaleWrapper.CHANGE_WRAPPING_START), true, nil, self)
					end
				else
					g_server:broadcastEvent(BaleWrapperStateEvent.new(self, BaleWrapper.CHANGE_WRAPPER_START_DROP_BALE), true, nil, self)
				end
			end
		elseif v186_.baleWrapperState == BaleWrapper.STATE_WRAPPER_DROPPING_BALE then
			if not self:getIsAnimationPlaying(v186_.currentWrapper.animations.dropFromWrapper.animName) then
				g_server:broadcastEvent(BaleWrapperStateEvent.new(self, BaleWrapper.CHANGE_WRAPPER_BALE_DROPPED), true, nil, self)
			end
		elseif v186_.baleWrapperState == BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM and not self:getIsAnimationPlaying(v186_.currentWrapper.animations.resetAfterDrop.animName) then
			g_server:broadcastEvent(BaleWrapperStateEvent.new(self, BaleWrapper.CHANGE_WRAPPER_PLATFORM_RESET), true, nil, self)
		end
	end
	if v186_.automaticDrop or self:getIsAIActive() then
		local v191_, _ = self:getIsPowered()
		if v191_ and v186_.baleWrapperState == BaleWrapper.STATE_WRAPPER_FINSIHED then
			local v192_, v193_ = self:getIsBaleDropAllowed()
			if v192_ then
				if self.isServer then
					self:doStateChange(BaleWrapper.CHANGE_BUTTON_EMPTY)
				end
			elseif v193_ ~= nil then
				v186_.baleDropBlockedWarning = v193_
			end
		end
	end
	BaleWrapper.updateActionEvents(self)
	if v186_.setWrappingStateFinished then
		g_server:broadcastEvent(BaleWrapperStateEvent.new(self, BaleWrapper.CHANGE_WRAPPING_BALE_FINSIHED), true, nil, self)
		v186_.setWrappingStateFinished = false
	end
end

-- Local values: spec
function BaleWrapper:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local v195_ = self.spec_baleWrapper
		if v195_.showInvalidBaleWarning then
			g_currentMission:showBlinkingWarning(v195_.texts.warningBaleNotSupported, 500)
			return
		end
		if v195_.baleDropBlockedWarning ~= nil then
			g_currentMission:showBlinkingWarning(v195_.baleDropBlockedWarning, 500)
		end
	end
end

-- Local values: object, spec
function BaleWrapper:baleGrabberTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if otherId ~= 0 and getRigidBodyType(otherId) == RigidBodyType.DYNAMIC then
		local v200_ = g_currentMission:getNodeObject(otherId)
		if v200_ ~= nil and v200_:isa(Bale) then
			local v201_ = self.spec_baleWrapper
			if onEnter then
				v201_.baleGrabber.balesInTrigger[v200_] = Utils.getNoNil(v201_.baleGrabber.balesInTrigger[v200_], 0) + 1
				return
			end
			if onLeave and v201_.baleGrabber.balesInTrigger[v200_] ~= nil then
				local v202_ = v201_.baleGrabber.balesInTrigger
				local v203_ = v201_.baleGrabber.balesInTrigger[v200_] - 1
				v202_[v200_] = math.max(0, v203_)
				if v201_.baleGrabber.balesInTrigger[v200_] == 0 then
					v201_.baleGrabber.balesInTrigger[v200_] = nil
				end
			end
		end
	end
end

-- Local values: spec, specFoldable
function BaleWrapper:allowsGrabbingBale()
	local v205_ = self.spec_baleWrapper
	local v206_ = self.spec_foldable
	if v206_ == nil or (v206_.foldAnimTime == nil or v206_.foldAnimTime <= v205_.currentWrapperFoldMaxLimit and v206_.foldAnimTime >= v205_.currentWrapperFoldMinLimit) then
		if v205_.baleToLoad == nil then
			return v205_.baleWrapperState == BaleWrapper.STATE_NONE
		else
			return false
		end
	else
		return false
	end
end

-- Local values: spec, _, wrapNode, doShow, wrapperRotRepeat, _, wrapAnimNode, x, y, z, rx, ry, rz, sx, sy, sz, rot, _, wrapAnimNode, rot, i
function BaleWrapper:updateWrapNodes(isWrapping, isEmpty, t, wrapperRot)
	local v212_ = self.spec_baleWrapper
	local v213_ = wrapperRot == nil and 0 or wrapperRot
	for _, v214_ in pairs(v212_.currentWrapper.wrapNodes) do
		local v215_ = v214_.maxWrapperRot == nil and true or v213_ < v214_.maxWrapperRot
		local v216_ = setVisibility
		local v217_ = v214_.nodeId
		local v218_ = not v215_ or isWrapping and v214_.wrapVisibility
		if not v218_ then
			if isEmpty then
				v218_ = v214_.emptyVisibility
			else
				v218_ = isEmpty
			end
		end
		v216_(v217_, v218_)
	end
	if isWrapping then
		local v219_ = math.sign(v213_) * (v213_ % 3.141592653589793)
		if v219_ < 0 then
			v219_ = v219_ + 3.141592653589793
		end
		for _, v220_ in pairs(v212_.currentWrapper.wrapAnimNodes) do
			local v221_, v222_, v223_, v224_, v225_, v226_, v227_, v228_, v229_
			if v220_.useWrapperRot then
				local v230_
				if v220_.repeatWrapperRot then
					v230_ = v219_
				else
					v230_ = v213_
				end
				v221_, v222_, v223_, v224_, v225_, v226_, v227_, v228_, v229_ = v220_.animCurve:get(v230_)
			else
				v221_, v222_, v223_, v224_, v225_, v226_, v227_, v228_, v229_ = v220_.animCurve:get(t)
			end
			if v221_ ~= nil then
				setTranslation(v220_.nodeId, v221_, v222_, v223_)
				setRotation(v220_.nodeId, v224_, v225_, v226_)
				setScale(v220_.nodeId, v227_, v228_, v229_)
			end
		end
	elseif not isEmpty then
		for _, v231_ in pairs(v212_.currentWrapper.wrapAnimNodes) do
			if v231_.normalizeRotationOnBaleDrop ~= 0 then
				local v232_ = { getRotation(v231_.nodeId) }
				for v233_ = 1, 3 do
					local v234_ = v231_.normalizeRotationOnBaleDrop
					local v235_ = v232_[v233_]
					v232_[v233_] = v234_ * math.sign(v235_) * (v232_[v233_] % 6.283185307179586)
				end
				setRotation(v231_.nodeId, v232_[1], v232_[2], v232_[3])
			end
		end
	end
end

-- Local values: spec, wrapper, foilTime, wrappingFoilAnimation, rotation, oldClipIndex, nodesTime, rotation, nodes, i, wrappingAnimationNode, x, y, z, animationNode, rootNode, rx, ry, rz, wrappingState, wrapperRot, baleX, baleY, baleZ, wrapX, wrapY, wrapZ, bale, baleType, wrappingStateCurve
function BaleWrapper:updateWrappingState(wrappingTime, noEventSend)
	local v239_ = self.spec_baleWrapper
	local v240_ = v239_.currentWrapper
	local v241_
	if v240_.wrappingFoilAnimation == nil then
		v241_ = 0
	else
		local v242_ = v240_.wrappingFoilAnimation
		local v243_ = v242_.referenceNodeRotation
		local v244_ = v242_.referenceNodeRotation
		local v245_ = v242_.referenceNodeRotation
		local v246_, v247_, v248_ = getRotation(v242_.referenceNode)
		v243_[1] = v246_
		v244_[2] = v247_
		v245_[3] = v248_
		v241_ = (v242_.referenceNodeRotation[v242_.referenceAxis] - v242_.referenceMinRot) / (v242_.referenceMaxRot - v242_.referenceMinRot)
		if v241_ > 0 and (v241_ < 1 and v241_ ~= v242_.lastTime) then
			if getAnimTrackAssignedClip(v242_.animationCharSet, 0) ~= v242_.animationClipIndex then
				clearAnimTrackClip(v242_.animationCharSet, 0)
				assignAnimTrackClip(v242_.animationCharSet, 0, v242_.animationClipIndex)
			end
			enableAnimTrack(v242_.animationCharSet, 0)
			setAnimTrackTime(v242_.animationCharSet, 0, v241_ * v242_.animationClipDuration, true)
			disableAnimTrack(v242_.animationCharSet, 0)
			v242_.lastTime = v241_
		end
	end
	local v249_
	if v240_.wrappingAnimationNodes.referenceNode == nil then
		v249_ = 0
	else
		local v250_ = v240_.wrappingAnimationNodes.referenceNodeRotation
		local v251_ = v240_.wrappingAnimationNodes.referenceNodeRotation
		local v252_ = v240_.wrappingAnimationNodes.referenceNodeRotation
		local v253_, v254_, v255_ = getRotation(v240_.wrappingAnimationNodes.referenceNode)
		v250_[1] = v253_
		v251_[2] = v254_
		v252_[3] = v255_
		local v256_ = (v240_.wrappingAnimationNodes.referenceNodeRotation[v240_.wrappingAnimationNodes.referenceAxis] - v240_.wrappingAnimationNodes.referenceMinRot) / (v240_.wrappingAnimationNodes.referenceMaxRot - v240_.wrappingAnimationNodes.referenceMinRot)
		local v257_ = math.clamp(v256_, 0, 1)
		v249_ = MathUtil.round(v257_, 5)
	end
	if v240_.wrappingAnimationNodes.lastTime < v249_ then
		local v258_ = v240_.wrappingAnimationNodes.nodes
		for v259_ = v240_.wrappingAnimationNodes.currentIndex + 1, #v258_ do
			local v260_ = v258_[v259_]
			if v260_.time > v249_ then
				break
			end
			if v260_.linkNode == nil then
				if getParent(v260_.nodeId) ~= v260_.parent then
					link(v260_.parent, v260_.nodeId)
				end
				local v261_ = setTranslation
				local v262_ = v260_.nodeId
				local v263_ = v260_.translation
				v261_(v262_, unpack(v263_))
			else
				local v264_ = localToWorld
				local v265_ = v260_.parent
				local v266_ = v260_.translation
				local v267_, v268_, v269_ = v264_(v265_, unpack(v266_))
				if getParent(v260_.nodeId) ~= v260_.linkNode then
					link(v260_.linkNode, v260_.nodeId)
				end
				setWorldTranslation(v260_.nodeId, v267_, v268_, v269_)
			end
			v240_.wrappingAnimationNodes.currentIndex = v259_
		end
	elseif v249_ < v240_.wrappingAnimationNodes.lastTime then
		v240_.wrappingAnimationNodes.currentIndex = 0
	end
	v240_.wrappingAnimationNodes.lastTime = v249_
	for v270_, v271_ in pairs(v240_.wrappingAnimationNodes.nodeToRootNode) do
		local v272_, v273_, v274_ = localRotationToLocal(v271_, getParent(v270_), 0, 0, 0)
		setRotation(v270_, v272_, v273_, v274_)
	end
	local v275_ = math.min(wrappingTime, 1)
	local v276_ = 0
	if v240_.animCurve ~= nil then
		local v277_, v278_, v279_, v280_, v281_, v282_ = v240_.animCurve:get(wrappingTime)
		if v277_ == nil then
			if v240_.animations.wrapBale.animName ~= nil then
				wrappingTime = self:getAnimationTime(v240_.animations.wrapBale.animName)
			end
		else
			setRotation(v240_.baleNode, v277_ % 6.283185307179586, v278_ % 6.283185307179586, v279_ % 6.283185307179586)
			setRotation(v240_.wrapperNode, v280_ % 6.283185307179586, v281_ % 6.283185307179586, v282_ % 6.283185307179586)
			v276_ = v[3 + v240_.wrapperRotAxis]
		end
		if v240_.wrappingAnimationNodes.referenceNode == nil then
			v249_ = v275_
		end
		if v240_.wrappingFoilAnimation == nil then
			v241_ = v249_
		end
		if v240_.currentBale ~= nil then
			local v283_ = NetworkUtil.getObject(v240_.currentBale)
			if v283_ ~= nil then
				local v284_ = v239_.currentWrapper.allowedBaleTypes[v239_.currentBaleTypeIndex]
				if v283_:getSupportsWrapping() and (not v284_.skipWrapping and v283_.wrappingState < 1) then
					local v285_ = v284_.wrappingStateCurve or v240_.wrappingStateCurve
					if v285_ ~= nil then
						v241_ = v285_:get(v241_)
					end
					v283_:setWrappingState(v241_, true)
					if v283_.setColor ~= nil then
						v283_:setColor(v239_.wrapColor[1], v239_.wrapColor[2], v239_.wrapColor[3])
					end
				end
			end
		end
	end
	self:updateWrapNodes(wrappingTime > 0, false, wrappingTime, v276_)
	if wrappingTime > 0.99999 and (self.isServer and (v239_.baleWrapperState == BaleWrapper.STATE_WRAPPER_WRAPPING_BALE and not noEventSend)) then
		g_server:broadcastEvent(BaleWrapperStateEvent.new(self, BaleWrapper.CHANGE_WRAPPING_BALE_FINSIHED), true, nil, self)
	end
end

-- Local values: spec, baleTypeIndex
function BaleWrapper:playMoveToWrapper(bale)
	local v288_ = self.spec_baleWrapper
	local v289_ = self:getMatchingBaleTypeIndex(bale.isRoundbale and v288_.roundBaleWrapper.allowedBaleTypes or v288_.squareBaleWrapper.allowedBaleTypes, bale)
	self:setBaleWrapperType(bale.isRoundbale, v289_)
	if v288_.currentWrapper.animations.moveToWrapper.animName ~= nil then
		self:playAnimation(v288_.currentWrapper.animations.moveToWrapper.animName, v288_.currentWrapper.animations.moveToWrapper.animSpeed, nil, true)
	end
end

-- Local values: spec, baleType, wrappingFoilAnimation
function BaleWrapper:setBaleWrapperType(isRoundBaleWrapper, baleTypeIndex)
	local v293_ = self.spec_baleWrapper
	v293_.currentWrapper = isRoundBaleWrapper and v293_.roundBaleWrapper or v293_.squareBaleWrapper
	v293_.currentBaleTypeIndex = baleTypeIndex
	local v294_ = v293_.currentWrapper.allowedBaleTypes[baleTypeIndex]
	if v294_ ~= nil then
		v293_.currentWrapper.animations = v294_.animations
		v293_.currentWrapper.wrappingFoilAnimation = v294_.wrappingFoilAnimation or v293_.currentWrapper.wrappingFoilAnimationDefault
		ObjectChangeUtil.setObjectChanges(v294_.changeObjects, true, self, self.setMovingToolDirty)
		if v293_.currentWrapper.wrappingFoilAnimation ~= nil then
			local v295_ = v293_.currentWrapper.wrappingFoilAnimation
			clearAnimTrackClip(v295_.animationCharSet, 0)
			assignAnimTrackClip(v295_.animationCharSet, 0, v295_.animationClipIndex)
			enableAnimTrack(v295_.animationCharSet, 0)
			setAnimTrackTime(v295_.animationCharSet, 0, 0, true)
			disableAnimTrack(v295_.animationCharSet, 0)
		end
	end
	self:requestActionEventUpdate()
end

-- Local values: i, baleType
function BaleWrapper:getMatchingBaleTypeIndex(baleTypes, bale)
	for v298_, v299_ in ipairs(baleTypes) do
		if bale:getBaleMatchesSize(v299_.diameter, v299_.width, v299_.height, v299_.length) then
			return v298_
		end
	end
	return 1
end

-- Local values: spec, baleType, skipWrapping, bale, bale, x, y, z, attachNode, bale, baleType, skippedWrapping, bale, animation, baleType, dropAnimation, attacherVehicle, bale, baleType, total, _, dropAnimationName
function BaleWrapper:doStateChange(id, nearestBaleServerId)
	local v303_ = self.spec_baleWrapper
	if id == BaleWrapper.CHANGE_WRAPPING_START or v303_.baleWrapperState ~= BaleWrapper.STATE_WRAPPER_FINSIHED and id == BaleWrapper.CHANGE_WRAPPER_START_DROP_BALE then
		local v304_ = v303_.currentWrapper.allowedBaleTypes[v303_.currentBaleTypeIndex].skipWrapping
		local v305_ = NetworkUtil.getObject(v303_.currentWrapper.currentBale)
		if v305_ == nil or v305_:getSupportsWrapping() and v305_.wrappingState ~= 1 then
			if v305_ == nil then
				Logging.devInfo("BaleWrapper:doStateChange (state: %d) - Bale not synced yet objectId %d", id, v303_.currentWrapper.currentBale)
			end
		else
			v304_ = true
		end
		if v304_ then
			if self.isServer then
				v303_.setWrappingStateFinished = true
			end
			return
		end
	end
	if id == BaleWrapper.CHANGE_GRAB_BALE then
		local v306_ = NetworkUtil.getObject(nearestBaleServerId)
		v303_.baleGrabber.currentBale = nearestBaleServerId
		if v306_ == nil then
			v303_.baleToMount = {
				["serverId"] = nearestBaleServerId,
				["linkNode"] = v303_.baleGrabber.grabNode,
				["trans"] = { 0, 0, 0 },
				["rot"] = { 0, 0, 0 }
			}
		else
			local v307_, v308_, v309_ = localToLocal(v306_.nodeId, getParent(v303_.baleGrabber.grabNode), 0, 0, 0)
			setTranslation(v303_.baleGrabber.grabNode, v307_, v308_, v309_)
			v306_:mountKinematic(self, v303_.baleGrabber.grabNode, 0, 0, 0, 0, 0, 0)
			v306_:setCanBeSold(false)
			v306_:setNeedsSaving(false)
			v303_.baleToMount = nil
			self:playMoveToWrapper(v306_)
		end
		v303_.baleWrapperState = BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER
	elseif id == BaleWrapper.CHANGE_DROP_BALE_AT_GRABBER then
		local v310_ = v303_.currentWrapper.baleNode
		local v311_ = NetworkUtil.getObject(v303_.baleGrabber.currentBale)
		if v311_ == nil then
			v303_.baleToMount = {
				["serverId"] = v303_.baleGrabber.currentBale,
				["linkNode"] = v310_,
				["trans"] = { 0, 0, 0 },
				["rot"] = { 0, 0, 0 }
			}
		else
			v311_:mountKinematic(self, v310_, 0, 0, 0, 0, 0, 0)
			v311_:setCanBeSold(false)
			v311_:setNeedsSaving(false)
			v303_.baleToMount = nil
		end
		self:updateWrapNodes(true, false, 0)
		v303_.currentWrapper.currentBale = v303_.baleGrabber.currentBale
		v303_.baleGrabber.currentBale = nil
		if v303_.currentWrapper.animations.moveToWrapper.animName ~= nil and v303_.currentWrapper.animations.moveToWrapper.reverseAfterMove then
			self:playAnimation(v303_.currentWrapper.animations.moveToWrapper.animName, -v303_.currentWrapper.animations.moveToWrapper.animSpeed, nil, true)
		end
		v303_.baleWrapperState = BaleWrapper.STATE_MOVING_GRABBER_TO_WORK
	elseif id == BaleWrapper.CHANGE_WRAPPING_START then
		v303_.baleWrapperState = BaleWrapper.STATE_WRAPPER_WRAPPING_BALE
		if self.isClient then
			g_soundManager:playSamples(v303_.currentWrapper.samples.start)
			g_soundManager:playSamples(v303_.currentWrapper.samples.wrap, 0, v303_.currentWrapper.samples.start[1])
		end
		if v303_.currentWrapper.animations.wrapBale.animName ~= nil then
			self:playAnimation(v303_.currentWrapper.animations.wrapBale.animName, v303_.currentWrapper.animations.wrapBale.animSpeed, nil, true)
		end
	elseif id == BaleWrapper.CHANGE_WRAPPING_BALE_FINSIHED then
		if self.isClient then
			g_soundManager:stopSamples(v303_.currentWrapper.samples.wrap)
			g_soundManager:stopSamples(v303_.currentWrapper.samples.stop)
			if v303_.currentWrapper.wrappingSoundEndTime == 1 then
				g_soundManager:playSamples(v303_.currentWrapper.samples.stop)
			end
			g_soundManager:stopSamples(v303_.currentWrapper.samples.start)
		end
		self:updateWrappingState(1, true)
		v303_.baleWrapperState = BaleWrapper.STATE_WRAPPER_FINSIHED
		local v312_ = v303_.currentWrapper.allowedBaleTypes[v303_.currentBaleTypeIndex].skipWrapping
		local v313_ = NetworkUtil.getObject(v303_.currentWrapper.currentBale)
		local v314_ = v313_ ~= nil and (not v313_:getSupportsWrapping() or v313_.wrappingState == 1) and true or v312_
		if v314_ then
			self:updateWrappingState(0, true)
		end
		if not v314_ then
			local v315_ = v303_.currentWrapper.animations.resetWrapping
			if v315_.animName ~= nil then
				self:playAnimation(v315_.animName, v315_.animSpeed, nil, true)
			end
		end
		self:updateConsumable(BaleWrapper.CONSUMABLE_TYPE_NAME, 0)
	elseif id == BaleWrapper.CHANGE_WRAPPER_START_DROP_BALE then
		self:updateWrapNodes(false, false, 0)
		local v316_ = v303_.currentWrapper.allowedBaleTypes[v303_.currentBaleTypeIndex].dropAnimations[v303_.dropAnimationIndex]
		if v316_ ~= nil then
			v303_.currentWrapper.animations.dropFromWrapper.animName = v316_.name
			v303_.currentWrapper.animations.dropFromWrapper.animSpeed = v316_.animSpeed
			if self.isServer and (v316_.liftOnDrop and self:getIsLowered()) then
				local v317_ = self:getAttacherVehicle()
				if v317_ ~= nil then
					v317_:handleLowerImplementEvent(self)
				end
			end
		end
		if v303_.currentWrapper.animations.dropFromWrapper.animName ~= nil then
			self:playAnimation(v303_.currentWrapper.animations.dropFromWrapper.animName, v303_.currentWrapper.animations.dropFromWrapper.animSpeed, nil, true)
		end
		v303_.dropAnimationIndex = 1
		v303_.baleWrapperState = BaleWrapper.STATE_WRAPPER_DROPPING_BALE
	elseif id == BaleWrapper.CHANGE_WRAPPER_BALE_DROPPED then
		local v318_ = NetworkUtil.getObject(v303_.currentWrapper.currentBale)
		if v318_ ~= nil then
			v318_:unmountKinematic()
			v318_:setNeedsSaving(true)
			v318_:setCanBeSold(true)
			local v319_ = v303_.currentWrapper.allowedBaleTypes[v303_.currentBaleTypeIndex]
			if v318_:getSupportsWrapping() and not v319_.skipWrapping then
				local v320_, _ = g_farmManager:updateFarmStats(self:getOwnerFarmId(), "wrappedBales", 1)
				if v320_ ~= nil then
					g_achievementManager:tryUnlock("WrappedBales", v320_)
				end
				if v318_.wrappingState < 1 then
					v318_:setWrappingState(1)
				end
			end
		end
		v303_.lastDroppedBaleId = NetworkUtil.getObjectId(v318_)
		v303_.currentWrapper.currentBale = nil
		v303_.currentWrapper.currentTime = 0
		if v303_.currentWrapper.animations.resetAfterDrop.animName ~= nil then
			local v321_ = v303_.currentWrapper.animations.dropFromWrapper.animName
			if self:getIsAnimationPlaying(v321_) then
				self:stopAnimation(v321_, true)
				self:setAnimationTime(v321_, 1, true, false)
			end
			self:playAnimation(v303_.currentWrapper.animations.resetAfterDrop.animName, v303_.currentWrapper.animations.resetAfterDrop.animSpeed, nil, true)
		end
		self:setBaleWrapperType(v303_.currentWrapper == v303_.roundBaleWrapper, v303_.currentBaleTypeIndex)
		v303_.baleWrapperState = BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM
	elseif id == BaleWrapper.CHANGE_WRAPPER_PLATFORM_RESET then
		self:updateWrappingState(0)
		self:updateWrapNodes(false, true, 0)
		v303_.baleWrapperState = BaleWrapper.STATE_NONE
	elseif id == BaleWrapper.CHANGE_BUTTON_EMPTY then
		local v322_ = self.isServer
		assert(v322_)
		if v303_.baleWrapperState == BaleWrapper.STATE_WRAPPER_FINSIHED then
			g_server:broadcastEvent(BaleWrapperStateEvent.new(self, BaleWrapper.CHANGE_WRAPPER_START_DROP_BALE), true, nil, self)
		end
	end
	BaleWrapper.updateActionEvents(self)
end

-- Local values: spec, sizeMatch, baleTypes, i, baleType
function BaleWrapper:getIsBaleWrappable(bale)
	local v325_ = self.spec_baleWrapper
	local v326_ = false
	local v327_ = bale.isRoundbale and v325_.roundBaleWrapper.allowedBaleTypes or v325_.squareBaleWrapper.allowedBaleTypes
	if v327_ ~= nil then
		for v328_, v329_ in ipairs(v327_) do
			if bale:getBaleMatchesSize(v329_.diameter, v329_.width, v329_.height, v329_.length) then
				v326_ = true
				if not v329_.skipWrapping and (bale:getSupportsWrapping() and bale.wrappingState < 1) then
					return true, v326_, v328_
				end
			end
		end
	end
	return false, v326_
end

-- Local values: spec, currentWrapper, x, y, z, rx, ry, rz, ex, ey, ez
function BaleWrapper:getIsBaleDropAllowed()
	local v331_ = self.spec_baleWrapper
	local v332_ = v331_.currentWrapper
	if v332_.dropArea.node ~= nil then
		local v333_, v334_, v335_ = getWorldTranslation(v332_.dropArea.node)
		local v336_, v337_, v338_ = getWorldRotation(v332_.dropArea.node)
		local v339_ = v332_.dropArea.width * 0.5
		local v340_ = v332_.dropArea.height * 0.5
		local v341_ = v332_.dropArea.length * 0.5
		v331_.foundDropOverlappingObject = false
		overlapBox(v333_, v334_, v335_, v336_, v337_, v338_, v339_, v340_, v341_, "onBaleWrapperDropOverlapCallback", self, BaleWrapper.DROP_COLLISION_MASK, true, true, false, true)
		if v331_.foundDropOverlappingObject then
			return false, v331_.texts.warningDropAreaBlocked
		end
	end
	return true, nil
end

-- Local values: object, spec, currentWrapper
function BaleWrapper:onBaleWrapperDropOverlapCallback(nodeId)
	local v344_ = g_currentMission:getNodeObject(nodeId)
	if v344_ ~= nil and v344_ ~= self then
		local v345_ = self.spec_baleWrapper
		local v346_ = v345_.currentWrapper
		if v346_.currentBale ~= nil and v344_ == NetworkUtil.getObject(v346_.currentBale) then
			return
		end
		v345_.foundDropOverlappingObject = true
		v345_.foundDropOverlappingObjectTime = g_time
	end
end

-- Local values: spec, currentWrapper, x, y, z, rx, ry, rz, ex, ey, ez
function BaleWrapper:getIsBaleWrappingAllowed()
	local v348_ = self.spec_baleWrapper
	local v349_ = v348_.currentWrapper
	if v349_.blockWrapArea.node ~= nil then
		local v350_, v351_, v352_ = getWorldTranslation(v349_.blockWrapArea.node)
		local v353_, v354_, v355_ = getWorldRotation(v349_.blockWrapArea.node)
		local v356_ = v349_.blockWrapArea.width * 0.5
		local v357_ = v349_.blockWrapArea.height * 0.5
		local v358_ = v349_.blockWrapArea.length * 0.5
		v348_.foundBlockOverlappingObject = false
		overlapBox(v350_, v351_, v352_, v353_, v354_, v355_, v356_, v357_, v358_, "onBaleWrapperBlockOverlapCallback", self, BaleWrapper.BLOCK_COLLISION_MASK, true, true, false, true)
		if v348_.foundBlockOverlappingObject then
			return false
		end
	end
	return self:getConsumableIsAvailable(BaleWrapper.CONSUMABLE_TYPE_NAME)
end

-- Local values: object, spec, currentWrapper
function BaleWrapper:onBaleWrapperBlockOverlapCallback(nodeId)
	local v361_ = g_currentMission:getNodeObject(nodeId)
	if v361_ ~= nil and v361_ ~= self then
		local v362_ = self.spec_baleWrapper
		local v363_ = v362_.currentWrapper
		if v363_.currentBale ~= nil and v361_ == NetworkUtil.getObject(v363_.currentBale) then
			return
		end
		v362_.foundBlockOverlappingObject = true
	end
end

-- Local values: spec, baleTypes, baleType
function BaleWrapper:pickupWrapperBale(bale, baleTypeIndex)
	local v367_ = self.spec_baleWrapper
	if bale:getSupportsWrapping() then
		local v368_ = bale.isRoundbale and v367_.roundBaleWrapper.allowedBaleTypes or v367_.squareBaleWrapper.allowedBaleTypes
		if v368_ ~= nil and baleTypeIndex ~= nil then
			local v369_ = v368_[baleTypeIndex]
			if v369_ ~= nil and (not v369_.skipWrapping and (bale.wrappingState < 1 and (v369_.wrapDiffuse ~= nil or v369_.wrapNormal ~= nil))) then
				bale:setWrapTextures(v369_.wrapDiffuse, v369_.wrapNormal)
			end
		end
	end
	v367_.baleGrabber.balesInTrigger[bale] = nil
	g_server:broadcastEvent(BaleWrapperStateEvent.new(self, BaleWrapper.CHANGE_GRAB_BALE, NetworkUtil.getObjectId(bale)), true, nil, self)
end

-- Local values: nearestBale, nearestBaleWrappable, nearestBaleTypeIndex, nearestDistance, spec, bale, _, isWrappable, sizeMatches, baleTypeIndex
function BaleWrapper:getBaleInRange(refNode, distance)
	local v373_ = self.spec_baleWrapper
	local v374_ = distance
	local v375_ = nil
	local v376_ = nil
	local v377_ = nil
	for v378_, _ in pairs(v373_.baleGrabber.balesInTrigger) do
		if v378_.dynamicMountType == MountableObject.MOUNT_TYPE_NONE and (v378_.nodeId ~= 0 and calcDistanceFrom(refNode, v378_.nodeId) < distance) then
			local v379_, v380_, v381_ = self:getIsBaleWrappable(v378_)
			if v379_ and v380_ then
				v377_ = v381_
				v376_ = v378_
				v375_ = v376_
				distance = v374_
				local v382_ = v376_
				v376_ = v375_
				v382_ = v375_
				v375_ = v376_
			else
				v376_ = v378_
				distance = v374_
			end
		end
	end
	return v375_, v376_, v377_
end

-- Local values: spec
function BaleWrapper:setBaleWrapperAutomaticDrop(state, noEventSend)
	local v386_ = self.spec_baleWrapper
	if state == nil then
		state = not v386_.automaticDrop
	end
	v386_.automaticDrop = state
	self:requestActionEventUpdate()
	BaleWrapperAutomaticDropEvent.sendEvent(self, state, noEventSend)
end

-- Local values: spec
function BaleWrapper:setBaleWrapperDropAnimation(dropAnimationIndex)
	self.spec_baleWrapper.dropAnimationIndex = dropAnimationIndex
end

-- Local values: spec
function BaleWrapper:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	local v393_ = self.spec_baleWrapper
	if v393_.baleWrapperState == BaleWrapper.STATE_NONE then
		return superFunc(self, direction, onAiTurnOn)
	else
		return false, v393_.texts.warningFoldingWrapping
	end
end

function BaleWrapper:getCanBeSelected(superFunc)
	return true
end

function BaleWrapper:getShowConsumableEmptyWarning(superFunc, typeName)
	if typeName ~= BaleWrapper.CONSUMABLE_TYPE_NAME then
		return superFunc(self, typeName)
	end
	local v397_
	if self.spec_baleWrapper.baleWrapperState == BaleWrapper.STATE_NONE then
		v397_ = false
	else
		v397_ = superFunc(self, typeName)
	end
	return v397_
end

-- Local values: spec
function BaleWrapper:getRequiresPower(superFunc)
	return self.spec_baleWrapper.baleWrapperState ~= BaleWrapper.STATE_NONE and true or superFunc(self)
end

-- Local values: rpmFactor, spec
function BaleWrapper:getStandaloneMotorTargetRpm(superFunc)
	local v402_ = 0
	local v403_ = self.spec_baleWrapper
	if v403_.baleWrapperState ~= BaleWrapper.STATE_NONE then
		v402_ = v403_.baleWrapperState == BaleWrapper.STATE_WRAPPER_WRAPPING_BALE and 1 or (v403_.baleWrapperState ~= BaleWrapper.STATE_WRAPPER_FINSIHED and 0.5 or v402_)
	end
	local v404_ = superFunc(self)
	return math.max(v404_, v402_)
end

-- Local values: loadFactorSum, numLoadFactors, loadFactor, spec
function BaleWrapper:getStandaloneMotorLoad(superFunc)
	local v407_, v408_ = superFunc(self)
	local v409_ = 0
	local v410_ = self.spec_baleWrapper
	if v410_.baleWrapperState ~= BaleWrapper.STATE_NONE then
		v409_ = v410_.baleWrapperState == BaleWrapper.STATE_WRAPPER_WRAPPING_BALE and 1 or (v410_.baleWrapperState ~= BaleWrapper.STATE_WRAPPER_FINSIHED and 0.5 or v409_)
	end
	return v407_ + v409_, v408_ + 1
end

-- Local values: spec, object, currentWrapper, object
function BaleWrapper:addToPhysics(superFunc)
	if not superFunc(self) then
		return false
	end
	local v413_ = self.spec_baleWrapper
	local v414_ = NetworkUtil.getObject(v413_.baleGrabber.currentBale)
	if v414_ ~= nil then
		v414_:addToPhysics()
		v414_:mountKinematic(self, v413_.baleGrabber.grabNode, 0, 0, 0, 0, 0, 0)
	end
	local v415_ = v413_.currentWrapper
	if v415_.currentBale ~= nil then
		local v416_ = NetworkUtil.getObject(v415_.currentBale)
		if v416_ ~= nil then
			v416_:addToPhysics()
			v416_:mountKinematic(self, v413_.currentWrapper.baleNode, 0, 0, 0, 0, 0, 0)
		end
	end
	return true
end

-- Local values: spec, currentWrapper, object
function BaleWrapper:removeFromPhysics(superFunc)
	if not superFunc(self) then
		return false
	end
	local v419_ = self.spec_baleWrapper.currentWrapper
	if v419_.currentBale ~= nil then
		local v420_ = NetworkUtil.getObject(v419_.currentBale)
		if v420_ ~= nil then
			v420_:unmountKinematic()
			v420_:removeFromPhysics()
		end
	end
	return true
end

-- Local values: spec, _, actionEventId, baleType, i, dropAnimation, _, actionEventId, _, actionEventId
function BaleWrapper:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v423_ = self.spec_baleWrapper
		self:clearActionEventsTable(v423_.actionEvents)
		if isActiveForInputIgnoreSelection then
			if not v423_.automaticDrop then
				local _, v424_ = self:addPoweredActionEvent(v423_.actionEvents, InputAction.IMPLEMENT_EXTRA3, self, BaleWrapper.actionEventEmpty, false, true, false, true, nil)
				g_inputBinding:setActionEventText(v424_, v423_.currentWrapper.unloadBaleText)
				g_inputBinding:setActionEventTextPriority(v424_, GS_PRIO_HIGH)
				local v425_ = v423_.currentWrapper.allowedBaleTypes[v423_.currentBaleTypeIndex]
				for v426_ = 1, #v425_.dropAnimations do
					local v427_ = v425_.dropAnimations[v426_]
					if v427_.inputAction ~= nil then
						local _, v428_ = self:addPoweredActionEvent(v423_.actionEvents, v427_.inputAction, self, BaleWrapper.actionEventDrop, false, true, false, false, v426_)
						g_inputBinding:setActionEventTextPriority(v428_, GS_PRIO_HIGH)
						g_inputBinding:setActionEventText(v428_, v427_.text)
					end
				end
			end
			if v423_.toggleableAutomaticDrop then
				local _, v429_ = self:addActionEvent(v423_.actionEvents, InputAction.IMPLEMENT_EXTRA4, self, BaleWrapper.actionEventToggleAutomaticDrop, false, true, false, true, nil)
				g_inputBinding:setActionEventText(v429_, v423_.automaticDrop and v423_.toggleAutomaticDropTextNeg or v423_.toggleAutomaticDropTextPos)
				g_inputBinding:setActionEventTextPriority(v429_, GS_PRIO_HIGH)
			end
			BaleWrapper.updateActionEvents(self)
		end
	end
end

-- Local values: spec
function BaleWrapper:onRegisterExternalActionEvents(trigger, name, xmlFile, key)
	local v433_ = self.spec_baleWrapper
	if name == "baleWrapperDrop" then
		self:registerExternalActionEvent(trigger, name, BaleWrapper.externalActionEventUnloadRegister, BaleWrapper.externalActionEventUnloadUpdate)
	elseif name == "baleWrapperAutomaticDrop" then
		if v433_.toggleableAutomaticDrop then
			self:registerExternalActionEvent(trigger, name, BaleWrapper.externalActionEventAutomaticUnloadRegister, BaleWrapper.externalActionEventAutomaticUnloadUpdate)
			return
		end
	elseif name == "baleWrapperWarnings" then
		self:registerExternalActionEvent(trigger, name, BaleWrapper.externalActionEventWarningsRegister, BaleWrapper.externalActionEventWarningsUpdate)
	end
end

-- Local values: spec
function BaleWrapper:onDeactivate()
	local v435_ = self.spec_baleWrapper
	v435_.showInvalidBaleWarning = false
	if self.isClient then
		g_soundManager:stopSamples(v435_.currentWrapper.samples.wrap)
		g_soundManager:stopSamples(v435_.currentWrapper.samples.start)
		g_soundManager:stopSamples(v435_.currentWrapper.samples.stop)
	end
end

-- Local values: spec
function BaleWrapper:onFoldStateChanged(direction, moveToMiddle)
	local v438_ = self.spec_baleWrapper
	if v438_.foldedBaleType ~= nil and self.spec_foldable.turnOnFoldDirection ~= direction then
		self:setBaleWrapperType(v438_.foldedBaleType.isRoundBaleWrapper, v438_.foldedBaleType.baleTypeIndex)
	end
end

-- Local values: spec
function BaleWrapper:onConsumableVariationChanged(variationIndex, metaData)
	if metaData.color ~= nil then
		local v441_ = self.spec_baleWrapper
		v441_.wrapColor[1] = metaData.color[1]
		v441_.wrapColor[2] = metaData.color[2]
		v441_.wrapColor[3] = metaData.color[3]
	end
end

-- Local values: spec, dropIsAllowed, warning
function BaleWrapper:actionEventEmpty(actionName, inputValue, callbackState, isAnalog)
	if self.spec_baleWrapper.baleWrapperState == BaleWrapper.STATE_WRAPPER_FINSIHED then
		local v443_, v444_ = self:getIsBaleDropAllowed()
		if v443_ then
			g_client:getServerConnection():sendEvent(BaleWrapperStateEvent.new(self, BaleWrapper.CHANGE_BUTTON_EMPTY))
			return
		end
		if v444_ ~= nil then
			g_currentMission:showBlinkingWarning(v444_, 2000)
		end
	end
end

function BaleWrapper:actionEventToggleAutomaticDrop(actionName, inputValue, callbackState, isAnalog)
	self:setBaleWrapperAutomaticDrop()
end

-- Local values: spec
function BaleWrapper:actionEventDrop(actionName, inputValue, callbackState, isAnalog)
	if self.spec_baleWrapper.baleWrapperState == BaleWrapper.STATE_WRAPPER_FINSIHED then
		g_client:getServerConnection():sendEvent(BaleWrapperDropEvent.new(self, callbackState))
	end
end

-- Local values: spec, actionEvent, baleType, i, dropAnimation
function BaleWrapper:updateActionEvents()
	local v449_ = self.spec_baleWrapper
	local v450_ = v449_.actionEvents[InputAction.IMPLEMENT_EXTRA3]
	if v450_ ~= nil then
		g_inputBinding:setActionEventActive(v450_.actionEventId, v449_.baleWrapperState == BaleWrapper.STATE_WRAPPER_FINSIHED)
		g_inputBinding:setActionEventText(v450_.actionEventId, v449_.currentWrapper.unloadBaleText)
	end
	if v449_.toggleableAutomaticDrop then
		local v451_ = v449_.actionEvents[InputAction.IMPLEMENT_EXTRA4]
		if v451_ ~= nil then
			g_inputBinding:setActionEventText(v451_.actionEventId, v449_.automaticDrop and v449_.toggleAutomaticDropTextNeg or v449_.toggleAutomaticDropTextPos)
		end
	end
	local v452_ = v449_.currentWrapper.allowedBaleTypes[v449_.currentBaleTypeIndex]
	for v453_ = 1, #v452_.dropAnimations do
		local v454_ = v452_.dropAnimations[v453_]
		if v454_.inputAction ~= nil then
			local v455_ = v449_.actionEvents[v454_.inputAction]
			if v455_ ~= nil then
				g_inputBinding:setActionEventActive(v455_.actionEventId, v449_.baleWrapperState == BaleWrapper.STATE_WRAPPER_FINSIHED)
			end
		end
	end
end

-- Local values: spec, actionEvent, _
function BaleWrapper.externalActionEventUnloadRegister(data, vehicle)
	local v_u_458_ = vehicle.spec_baleWrapper
	local _, v463_ = g_inputBinding:registerActionEvent(InputAction.IMPLEMENT_EXTRA3, data, function(_, p459_, p460_, p461_, p462_)
		-- upvalues: (copy) v_u_458_, (copy) vehicle
		if not v_u_458_.automaticDrop then
			BaleWrapper.actionEventEmpty(vehicle, p459_, p460_, p461_, p462_)
		end
	end, false, true, false, true)
	data.actionEventId = v463_
	g_inputBinding:setActionEventTextPriority(data.actionEventId, GS_PRIO_HIGH)
	g_inputBinding:setActionEventText(data.actionEventId, v_u_458_.currentWrapper.unloadBaleText)
end

-- Local values: spec
function BaleWrapper.externalActionEventUnloadUpdate(data, vehicle)
	local v466_ = vehicle.spec_baleWrapper
	g_inputBinding:setActionEventActive(data.actionEventId, v466_.baleWrapperState == BaleWrapper.STATE_WRAPPER_FINSIHED)
end

-- Local values: actionEvent, _
function BaleWrapper.externalActionEventAutomaticUnloadRegister(data, vehicle)
	local _, v473_ = g_inputBinding:registerActionEvent(InputAction.IMPLEMENT_EXTRA4, data, function(_, p469_, p470_, p471_, p472_)
		-- upvalues: (copy) vehicle
		BaleWrapper.actionEventToggleAutomaticDrop(vehicle, p469_, p470_, p471_, p472_)
	end, false, true, false, true)
	data.actionEventId = v473_
	g_inputBinding:setActionEventTextPriority(data.actionEventId, GS_PRIO_HIGH)
end

-- Local values: spec
function BaleWrapper.externalActionEventAutomaticUnloadUpdate(data, vehicle)
	local v476_ = vehicle.spec_baleWrapper
	g_inputBinding:setActionEventText(data.actionEventId, v476_.automaticDrop and v476_.toggleAutomaticDropTextNeg or v476_.toggleAutomaticDropTextPos)
end

function BaleWrapper.externalActionEventWarningsRegister(data, vehicle) end

-- Local values: spec
function BaleWrapper.externalActionEventWarningsUpdate(data, vehicle)
	local v478_ = vehicle.spec_baleWrapper
	if v478_.automaticDrop then
		if g_time - v478_.foundDropOverlappingObjectTime < 500 then
			g_currentMission:showBlinkingWarning(v478_.texts.warningDropAreaBlocked, 500)
			return
		end
	elseif v478_.showInvalidBaleWarning then
		g_currentMission:showBlinkingWarning(v478_.texts.warningBaleNotSupported, 500)
	end
end

-- Local values: rootName, wrapperName, baleSizeAttributes
function BaleWrapper.loadSpecValueBaleSize(xmlFile, customEnvironment, baseDir, roundBaleWrapper)
	local v_u_481_ = {
		["minDiameter"] = math.huge,
		["maxDiameter"] = -math.huge,
		["minLength"] = math.huge,
		["maxLength"] = -math.huge
	}
	xmlFile:iterate(xmlFile:getRootName() .. ".baleWrapper." .. (roundBaleWrapper and "roundBaleWrapper" or "squareBaleWrapper") .. ".baleTypes.baleType", function(_, p482_)
		-- upvalues: (copy) xmlFile, (copy) v_u_481_
		if not xmlFile:getValue(p482_ .. "#skipWrapping", false) then
			local v483_ = MathUtil.round(xmlFile:getValue(p482_ .. "#diameter", 0), 2)
			local v484_ = v_u_481_
			local v485_ = v_u_481_.minDiameter
			v484_.minDiameter = math.min(v485_, v483_)
			local v486_ = v_u_481_
			local v487_ = v_u_481_.maxDiameter
			v486_.maxDiameter = math.max(v487_, v483_)
			local v488_ = MathUtil.round(xmlFile:getValue(p482_ .. "#length", 0), 2)
			local v489_ = v_u_481_
			local v490_ = v_u_481_.minLength
			v489_.minLength = math.min(v490_, v488_)
			local v491_ = v_u_481_
			local v492_ = v_u_481_.maxLength
			v491_.maxLength = math.max(v492_, v488_)
		end
	end)
	if v_u_481_.minDiameter == math.huge and v_u_481_.minLength == math.huge then
		return nil
	else
		return v_u_481_
	end
end

-- Local values: baleSizeAttributes, minValue, maxValue, unit, size
function BaleWrapper.getSpecValueBaleSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange, roundBaleWrapper)
	local v497_ = roundBaleWrapper and storeItem.specs.baleWrapperBaleSizeRound or storeItem.specs.baleWrapperBaleSizeSquare
	if v497_ == nil then
		if returnValues and returnRange then
			return 0, 0, ""
		elseif returnValues then
			return 0, ""
		else
			return ""
		end
	else
		local v498_ = roundBaleWrapper and v497_.minDiameter or v497_.minLength
		local v499_ = roundBaleWrapper and v497_.maxDiameter or v497_.maxLength
		if returnValues == nil or not returnValues then
			local v500_ = g_i18n:getText("unit_cmShort")
			if v499_ == v498_ then
				return string.format("%d%s", v498_ * 100, v500_)
			else
				return string.format("%d%s-%d%s", v498_ * 100, v500_, v499_ * 100, v500_)
			end
		elseif returnRange == true and v499_ ~= v498_ then
			return v498_ * 100, v499_ * 100, g_i18n:getText("unit_cmShort")
		else
			return v498_ * 100, g_i18n:getText("unit_cmShort")
		end
	end
end

function BaleWrapper.loadSpecValueBaleSizeRound(xmlFile, customEnvironment, baseDir)
	return BaleWrapper.loadSpecValueBaleSize(xmlFile, customEnvironment, baseDir, true)
end

function BaleWrapper.loadSpecValueBaleSizeSquare(xmlFile, customEnvironment, baseDir)
	return BaleWrapper.loadSpecValueBaleSize(xmlFile, customEnvironment, baseDir, false)
end

function BaleWrapper.getSpecValueBaleSizeRound(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	if storeItem.specs.baleWrapperBaleSizeRound == nil then
		return nil
	else
		return BaleWrapper.getSpecValueBaleSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange, true)
	end
end

function BaleWrapper.getSpecValueBaleSizeSquare(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	if storeItem.specs.baleWrapperBaleSizeSquare == nil then
		return nil
	else
		return BaleWrapper.getSpecValueBaleSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange, false)
	end
end
