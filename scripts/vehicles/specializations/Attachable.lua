Attachable = {}
source("dataS/scripts/vehicles/specializations/events/AttachableStartDetachEvent.lua")
Attachable.INPUT_ATTACHERJOINT_XML_KEY = "vehicle.attachable.inputAttacherJoints.inputAttacherJoint(?)"
Attachable.INPUT_ATTACHERJOINT_CONFIG_XML_KEY = "vehicle.attachable.inputAttacherJointConfigurations.inputAttacherJointConfiguration(?).inputAttacherJoint(?)"
Attachable.STEERING_AXLE_XML_KEY = "vehicle.attachable.steeringAxleAngleScale"
Attachable.STEERING_ANGLE_NODE_XML_KEY = "vehicle.attachable.steeringAngleNodes.steeringAngleNode(?)"
Attachable.LOWER_LINK_BALL_FILENAME = "data/shared/assets/lowerLinkBalls/lowerLinkBall%02d.i3d"

function Attachable.prerequisitesPresent(self)
	return true
end

function Attachable.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onPreAttach")
	SpecializationUtil.registerEvent(vehicleType, "onPostAttach")
	SpecializationUtil.registerEvent(vehicleType, "onPreDetach")
	SpecializationUtil.registerEvent(vehicleType, "onPostDetach")
	SpecializationUtil.registerEvent(vehicleType, "onSetLowered")
	SpecializationUtil.registerEvent(vehicleType, "onSetLoweredAll")
	SpecializationUtil.registerEvent(vehicleType, "onLeaveRootVehicle")
end

function Attachable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadInputAttacherJoint", Attachable.loadInputAttacherJoint)
	SpecializationUtil.registerFunction(vehicleType, "loadAttacherJointHeightNode", Attachable.loadAttacherJointHeightNode)
	SpecializationUtil.registerFunction(vehicleType, "getIsAttacherJointHeightNodeActive", Attachable.getIsAttacherJointHeightNodeActive)
	SpecializationUtil.registerFunction(vehicleType, "getInputAttacherJointByJointDescIndex", Attachable.getInputAttacherJointByJointDescIndex)
	SpecializationUtil.registerFunction(vehicleType, "getInputAttacherJointIndexByNode", Attachable.getInputAttacherJointIndexByNode)
	SpecializationUtil.registerFunction(vehicleType, "getAttacherVehicle", Attachable.getAttacherVehicle)
	SpecializationUtil.registerFunction(vehicleType, "getShowAttachableMapHotspot", Attachable.getShowAttachableMapHotspot)
	SpecializationUtil.registerFunction(vehicleType, "getInputAttacherJoints", Attachable.getInputAttacherJoints)
	SpecializationUtil.registerFunction(vehicleType, "getIsAttachedTo", Attachable.getIsAttachedTo)
	SpecializationUtil.registerFunction(vehicleType, "getActiveInputAttacherJointDescIndex", Attachable.getActiveInputAttacherJointDescIndex)
	SpecializationUtil.registerFunction(vehicleType, "getActiveInputAttacherJoint", Attachable.getActiveInputAttacherJoint)
	SpecializationUtil.registerFunction(vehicleType, "getAllowsLowering", Attachable.getAllowsLowering)
	SpecializationUtil.registerFunction(vehicleType, "loadSupportAnimationFromXML", Attachable.loadSupportAnimationFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsSupportAnimationAllowed", Attachable.getIsSupportAnimationAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getIsReadyToFinishDetachProcess", Attachable.getIsReadyToFinishDetachProcess)
	SpecializationUtil.registerFunction(vehicleType, "startDetachProcess", Attachable.startDetachProcess)
	SpecializationUtil.registerFunction(vehicleType, "getIsImplementChainLowered", Attachable.getIsImplementChainLowered)
	SpecializationUtil.registerFunction(vehicleType, "getIsInWorkPosition", Attachable.getIsInWorkPosition)
	SpecializationUtil.registerFunction(vehicleType, "getAttachbleAirConsumerUsage", Attachable.getAttachbleAirConsumerUsage)
	SpecializationUtil.registerFunction(vehicleType, "isDetachAllowed", Attachable.isDetachAllowed)
	SpecializationUtil.registerFunction(vehicleType, "isAttachAllowed", Attachable.isAttachAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getIsInputAttacherActive", Attachable.getIsInputAttacherActive)
	SpecializationUtil.registerFunction(vehicleType, "getSteeringAxleBaseVehicle", Attachable.getSteeringAxleBaseVehicle)
	SpecializationUtil.registerFunction(vehicleType, "loadSteeringAxleFromXML", Attachable.loadSteeringAxleFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsSteeringAxleAllowed", Attachable.getIsSteeringAxleAllowed)
	SpecializationUtil.registerFunction(vehicleType, "loadSteeringAngleNodeFromXML", Attachable.loadSteeringAngleNodeFromXML)
	SpecializationUtil.registerFunction(vehicleType, "updateSteeringAngleNode", Attachable.updateSteeringAngleNode)
	SpecializationUtil.registerFunction(vehicleType, "attachableAddToolCameras", Attachable.attachableAddToolCameras)
	SpecializationUtil.registerFunction(vehicleType, "attachableRemoveToolCameras", Attachable.attachableRemoveToolCameras)
	SpecializationUtil.registerFunction(vehicleType, "preAttach", Attachable.preAttach)
	SpecializationUtil.registerFunction(vehicleType, "postAttach", Attachable.postAttach)
	SpecializationUtil.registerFunction(vehicleType, "preDetach", Attachable.preDetach)
	SpecializationUtil.registerFunction(vehicleType, "postDetach", Attachable.postDetach)
	SpecializationUtil.registerFunction(vehicleType, "setLowered", Attachable.setLowered)
	SpecializationUtil.registerFunction(vehicleType, "setLoweredAll", Attachable.setLoweredAll)
	SpecializationUtil.registerFunction(vehicleType, "setToolBottomArmWidthByIndex", Attachable.setToolBottomArmWidthByIndex)
	SpecializationUtil.registerFunction(vehicleType, "updateInputAttacherJointGraphics", Attachable.updateInputAttacherJointGraphics)
	SpecializationUtil.registerFunction(vehicleType, "setIsAdditionalAttachment", Attachable.setIsAdditionalAttachment)
	SpecializationUtil.registerFunction(vehicleType, "getIsAdditionalAttachment", Attachable.getIsAdditionalAttachment)
	SpecializationUtil.registerFunction(vehicleType, "setIsSupportVehicle", Attachable.setIsSupportVehicle)
	SpecializationUtil.registerFunction(vehicleType, "getIsSupportVehicle", Attachable.getIsSupportVehicle)
	SpecializationUtil.registerFunction(vehicleType, "registerLoweringActionEvent", Attachable.registerLoweringActionEvent)
	SpecializationUtil.registerFunction(vehicleType, "getLoweringActionEventState", Attachable.getLoweringActionEventState)
	SpecializationUtil.registerFunction(vehicleType, "getAllowMultipleAttachments", Attachable.getAllowMultipleAttachments)
	SpecializationUtil.registerFunction(vehicleType, "resolveMultipleAttachments", Attachable.resolveMultipleAttachments)
	SpecializationUtil.registerFunction(vehicleType, "getBlockFoliageDestruction", Attachable.getBlockFoliageDestruction)
	SpecializationUtil.registerFunction(vehicleType, "setIsDetachingBlocked", Attachable.setIsDetachingBlocked)
end

function Attachable.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "findRootVehicle", Attachable.findRootVehicle)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsActive", Attachable.getIsActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsOperating", Attachable.getIsOperating)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getBrakeForce", Attachable.getBrakeForce)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", Attachable.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleTurnedOn", Attachable.getCanToggleTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanImplementBeUsedForAI", Attachable.getCanImplementBeUsedForAI)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanAIImplementContinueWork", Attachable.getCanAIImplementContinueWork)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreControlledActionsAllowed", Attachable.getAreControlledActionsAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDeactivateOnLeave", Attachable.getDeactivateOnLeave)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getActiveFarm", Attachable.getActiveFarm)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Attachable.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsLowered", Attachable.getIsLowered)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "mountDynamic", Attachable.mountDynamic)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getOwnerConnection", Attachable.getOwnerConnection)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsInUse", Attachable.getIsInUse)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getUpdatePriority", Attachable.getUpdatePriority)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeReset", Attachable.getCanBeReset)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAdditionalLightAttributesFromXML", Attachable.loadAdditionalLightAttributesFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsLightActive", Attachable.getIsLightActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsPowered", Attachable.getIsPowered)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConnectionHoseConfigIndex", Attachable.getConnectionHoseConfigIndex)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMapHotspotVisible", Attachable.getIsMapHotspotVisible)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getPowerTakeOffConfigIndex", Attachable.getPowerTakeOffConfigIndex)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDashboardGroupFromXML", Attachable.loadDashboardGroupFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDashboardGroupActive", Attachable.getIsDashboardGroupActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setWorldPositionQuaternion", Attachable.setWorldPositionQuaternion)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", Attachable.addToPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", Attachable.removeFromPhysics)
end

function Attachable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onPreInitComponentPlacement", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDelete", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateInterpolation", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onSelect", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onUnselect", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onRootVehicleChanged", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onFoldStateChanged", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterAnimationValueTypes", Attachable)
end
function Attachable.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("inputAttacherJoint", g_i18n:getText("configuration_inputAttacherJoint"), "attachable", VehicleConfigurationItem)
	local v5_ = Vehicle.xmlSchema
	v5_:setXMLSpecializationType("Attachable")
	Attachable.registerInputAttacherJointXMLPaths(v5_, Attachable.INPUT_ATTACHERJOINT_XML_KEY)
	Attachable.registerInputAttacherJointXMLPaths(v5_, Attachable.INPUT_ATTACHERJOINT_CONFIG_XML_KEY)
	ObjectChangeUtil.registerObjectChangeXMLPaths(v5_, Attachable.INPUT_ATTACHERJOINT_XML_KEY)
	ObjectChangeUtil.registerObjectChangeXMLPaths(v5_, Attachable.INPUT_ATTACHERJOINT_CONFIG_XML_KEY)
	Attachable.registerSupportXMLPaths(v5_, "vehicle.attachable.inputAttacherJointConfigurations.inputAttacherJointConfiguration(?).support(?)")
	v5_:register(XMLValueType.INT, "vehicle.attachable#connectionHoseConfigId", "Connection hose configuration index to use")
	v5_:register(XMLValueType.INT, "vehicle.attachable#powerTakeOffConfigId", "Power take off configuration index to use")
	v5_:register(XMLValueType.INT, "vehicle.attachable.inputAttacherJointConfigurations.inputAttacherJointConfiguration(?)#connectionHoseConfigId", "Connection hose configuration index to use")
	v5_:register(XMLValueType.INT, "vehicle.attachable.inputAttacherJointConfigurations.inputAttacherJointConfiguration(?)#powerTakeOffConfigId", "Power take off configuration index to use")
	v5_:register(XMLValueType.FLOAT, "vehicle.attachable.brakeForce#force", "Brake force", 0)
	v5_:register(XMLValueType.FLOAT, "vehicle.attachable.brakeForce#maxForce", "Brake force when vehicle reached mass of #maxForceMass", 0)
	v5_:register(XMLValueType.FLOAT, "vehicle.attachable.brakeForce#maxForceMass", "When this mass is reached the vehicle will brake with #maxForce", 0)
	v5_:register(XMLValueType.BOOL, "vehicle.attachable.brakeForce#includeAttachables", "Defines if the mass of the attached vehicles is included in the calculations", false)
	v5_:register(XMLValueType.FLOAT, "vehicle.attachable.brakeForce#loweredForce", "Brake force while the tool is lowered")
	v5_:register(XMLValueType.FLOAT, "vehicle.attachable.airConsumer#usage", "Air consumption while fully braking", 0)
	v5_:register(XMLValueType.BOOL, "vehicle.attachable#allowFoldingWhileAttached", "Allow folding while attached", true)
	v5_:register(XMLValueType.BOOL, "vehicle.attachable#allowFoldingWhileLowered", "Allow folding while lowered", true)
	v5_:register(XMLValueType.BOOL, "vehicle.attachable#blockFoliageDestruction", "If active the vehicle will block the complete foliage destruction of the vehicle chain", false)
	v5_:register(XMLValueType.BOOL, "vehicle.attachable.power#requiresExternalPower", "Tool requires external power from a vehicle with motor to work", true)
	v5_:register(XMLValueType.L10N_STRING, "vehicle.attachable.power#attachToPowerWarning", "Warning to be displayed if no vehicle with motor is attached", "warning_attachToPower")
	v5_:register(XMLValueType.FLOAT, "vehicle.attachable.steeringAxleAngleScale#startSpeed", "Start speed", 10)
	v5_:register(XMLValueType.FLOAT, "vehicle.attachable.steeringAxleAngleScale#endSpeed", "End speed", 30)
	v5_:register(XMLValueType.BOOL, "vehicle.attachable.steeringAxleAngleScale#backwards", "Is active backwards", false)
	v5_:register(XMLValueType.ANGLE, "vehicle.attachable.steeringAxleAngleScale#speed", "Speed (Degrees per second)", 60)
	v5_:register(XMLValueType.BOOL, "vehicle.attachable.steeringAxleAngleScale#useSuperAttachable", "Use super attachable", false)
	v5_:register(XMLValueType.NODE_INDEX, "vehicle.attachable.steeringAxleAngleScale.targetNode#node", "Target node")
	v5_:register(XMLValueType.ANGLE, "vehicle.attachable.steeringAxleAngleScale.targetNode#refAngle", "Reference angle to transfer from angle between vehicles to defined min. and max. rot for target node")
	v5_:register(XMLValueType.ANGLE, "vehicle.attachable.steeringAxleAngleScale#minRot", "Min Rotation", 0)
	v5_:register(XMLValueType.ANGLE, "vehicle.attachable.steeringAxleAngleScale#maxRot", "Max Rotation", 0)
	v5_:register(XMLValueType.FLOAT, "vehicle.attachable.steeringAxleAngleScale#direction", "Direction", 1)
	v5_:register(XMLValueType.BOOL, "vehicle.attachable.steeringAxleAngleScale#forceUsage", "Force usage of steering axle, even if attacher vehicle does not have steering bar nodes", false)
	v5_:register(XMLValueType.BOOL, "vehicle.attachable.steeringAxleAngleScale#speedDependent", "Steering axle angle is scaled based on speed with #startSpeed and #endSpeed", true)
	v5_:register(XMLValueType.FLOAT, "vehicle.attachable.steeringAxleAngleScale#distanceDelay", "The steering angle is updated delayed after vehicle has been moved this distance", 0)
	v5_:register(XMLValueType.INT, "vehicle.attachable.steeringAxleAngleScale#referenceComponentIndex", "If defined the given component is used for steering angle reference. Y between root component and this component will result in steering angle.")
	v5_:register(XMLValueType.NODE_INDEX, Attachable.STEERING_ANGLE_NODE_XML_KEY .. "#node", "Steering angle node")
	v5_:register(XMLValueType.ANGLE, Attachable.STEERING_ANGLE_NODE_XML_KEY .. "#speed", "Change speed (degree per second)", 25)
	v5_:register(XMLValueType.FLOAT, Attachable.STEERING_ANGLE_NODE_XML_KEY .. "#scale", "Scale of vehicle to vehicle angle that is applied", 1)
	v5_:register(XMLValueType.ANGLE, Attachable.STEERING_ANGLE_NODE_XML_KEY .. "#offset", "Angle offset", 0)
	v5_:register(XMLValueType.FLOAT, Attachable.STEERING_ANGLE_NODE_XML_KEY .. "#minSpeed", "Min. speed of vehicle to update", 0)
	Attachable.registerSupportXMLPaths(v5_, "vehicle.attachable.support(?)")
	v5_:register(XMLValueType.STRING, "vehicle.attachable.lowerAnimation#name", "Animation name")
	v5_:register(XMLValueType.FLOAT, "vehicle.attachable.lowerAnimation#speed", "Animation speed", 1)
	v5_:register(XMLValueType.INT, "vehicle.attachable.lowerAnimation#directionOnDetach", "Direction on detach", 0)
	v5_:register(XMLValueType.BOOL, "vehicle.attachable.lowerAnimation#defaultLowered", "Is default lowered", false)
	VehicleCamera.registerCameraXMLPaths(v5_, "vehicle.attachable.toolCameras.toolCamera(?)")
	SoundManager.registerSampleXMLPaths(v5_, "vehicle.attachable.sounds", "active(?)")
	for v6_ = 1, #Lights.ADDITIONAL_LIGHT_ATTRIBUTES_KEYS do
		local v7_ = Lights.ADDITIONAL_LIGHT_ATTRIBUTES_KEYS[v6_]
		v5_:register(XMLValueType.INT, v7_ .. "#inputAttacherJointIndex", "Index of input attacher joint that needs to be active to activate light")
	end
	v5_:register(XMLValueType.BOOL, Dashboard.GROUP_XML_KEY .. "#isAttached", "Tool is attached")
	v5_:addDelayedRegistrationFunc("AnimatedVehicle:part", function(p8_, p9_)
		p8_:register(XMLValueType.INT, p9_ .. "#inputAttacherJointIndex", "Input Attacher Joint Index [1..n]")
		p8_:register(XMLValueType.VECTOR_3, p9_ .. "#lowerRotLimitScaleStart", "Lower rotation limit start")
		p8_:register(XMLValueType.VECTOR_3, p9_ .. "#lowerRotLimitScaleEnd", "Lower rotation limit end")
		p8_:register(XMLValueType.VECTOR_3, p9_ .. "#upperRotLimitScaleStart", "Upper rotation limit start")
		p8_:register(XMLValueType.VECTOR_3, p9_ .. "#upperRotLimitScaleEnd", "Upper rotation limit end")
		p8_:register(XMLValueType.VECTOR_3, p9_ .. "#lowerTransLimitScaleStart", "Lower translation limit start")
		p8_:register(XMLValueType.VECTOR_3, p9_ .. "#lowerTransLimitScaleEnd", "Lower translation limit end")
		p8_:register(XMLValueType.VECTOR_3, p9_ .. "#upperTransLimitScaleStart", "Upper translation limit start")
		p8_:register(XMLValueType.VECTOR_3, p9_ .. "#upperTransLimitScaleEnd", "Upper translation limit end")
		p8_:register(XMLValueType.ANGLE, p9_ .. "#lowerRotationOffsetStart", "Lower rotation offset start")
		p8_:register(XMLValueType.ANGLE, p9_ .. "#lowerRotationOffsetEnd", "Lower rotation offset end")
		p8_:register(XMLValueType.ANGLE, p9_ .. "#upperRotationOffsetStart", "Upper rotation offset start")
		p8_:register(XMLValueType.ANGLE, p9_ .. "#upperRotationOffsetEnd", "Upper rotation offset end")
		p8_:register(XMLValueType.FLOAT, p9_ .. "#lowerDistanceToGroundStart", "Lower distance to ground start")
		p8_:register(XMLValueType.FLOAT, p9_ .. "#lowerDistanceToGroundEnd", "Lower distance to ground end")
		p8_:register(XMLValueType.FLOAT, p9_ .. "#upperDistanceToGroundStart", "Upper distance to ground start")
		p8_:register(XMLValueType.FLOAT, p9_ .. "#upperDistanceToGroundEnd", "Upper distance to ground end")
	end)
	v5_:setXMLSpecializationType()
	local v10_ = Vehicle.xmlSchemaSavegame
	v10_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).attachable#lowerAnimTime", "Lower animation time")
	v10_:register(XMLValueType.BOOL, "vehicles.vehicle(?).attachable#isDetachingBlocked", "If detaching is blocked")
end

function Attachable.registerInputAttacherJointXMLPaths(schema, baseName)
	schema:addDelayedRegistrationPath(baseName, "Attachable:inputAttacherJoint")
	schema:register(XMLValueType.NODE_INDEX, baseName .. "#node", "Joint Node")
	schema:register(XMLValueType.NODE_INDEX, baseName .. ".heightNode(?)#node", "Height Node")
	schema:register(XMLValueType.STRING, baseName .. "#jointType", "Joint type")
	schema:register(XMLValueType.STRING, baseName .. ".subType#name", "If defined this type needs to match with the sub type in the attacher vehicle")
	schema:register(XMLValueType.BOOL, baseName .. ".subType#showWarning", "Show warning if user tries to attach with a different sub type", true)
	schema:register(XMLValueType.BOOL, baseName .. "#needsTrailerJoint", "Needs trailer joint (only if no joint type is given)", false)
	schema:register(XMLValueType.BOOL, baseName .. "#needsLowJoint", "Needs low trailer joint (only if no joint type is given)", false)
	schema:register(XMLValueType.NODE_INDEX, baseName .. "#topReferenceNode", "Top Reference Node")
	schema:register(XMLValueType.NODE_INDEX, baseName .. "#rootNode", "Root node", "Parent component of attacher joint node")
	schema:register(XMLValueType.BOOL, baseName .. "#allowsDetaching", "Allows detaching", true)
	schema:register(XMLValueType.BOOL, baseName .. "#fixedRotation", "Fixed rotation (Rot limit is freezed)", false)
	schema:register(XMLValueType.BOOL, baseName .. "#hardAttach", "Implement is hard attached", false)
	schema:register(XMLValueType.TIME, baseName .. "#smoothAttachTime", "Time until the attachment is fully attached (seconds)", 0.5)
	schema:register(XMLValueType.NODE_INDEX, baseName .. "#nodeVisual", "Visual joint node")
	schema:register(XMLValueType.FLOAT, baseName .. ".distanceToGround#lower", "Lower distance to ground")
	schema:register(XMLValueType.FLOAT, baseName .. ".distanceToGround#upper", "Upper distance to ground")
	schema:register(XMLValueType.STRING, baseName .. ".distanceToGround.vehicle(?)#filename", "Vehicle filename to activate these distances")
	schema:register(XMLValueType.FLOAT, baseName .. ".distanceToGround.vehicle(?)#lower", "Lower distance to ground while attached to this vehicle")
	schema:register(XMLValueType.FLOAT, baseName .. ".distanceToGround.vehicle(?)#upper", "Upper distance to ground while attached to this vehicle")
	schema:register(XMLValueType.ANGLE, baseName .. "#lowerRotationOffset", "Rotation offset if lowered")
	schema:register(XMLValueType.ANGLE, baseName .. "#upperRotationOffset", "Rotation offset if lifted", "8 degrees for implements")
	schema:register(XMLValueType.BOOL, baseName .. "#allowsJointRotLimitMovement", "Rotation limit is changed during lifting/lowering", true)
	schema:register(XMLValueType.BOOL, baseName .. "#allowsJointTransLimitMovement", "Translation limit is changed during lifting/lowering", true)
	schema:register(XMLValueType.BOOL, baseName .. "#needsToolbar", "Needs toolbar", false)
	schema:register(XMLValueType.VECTOR_N, baseName .. ".bottomArm#categories", "Bottom arm categories (0-4). Defines the width of the lower links and the ball size. Can be multiple categories separated by a whitespace if the tool support more than one.")
	schema:register(XMLValueType.VECTOR_N, baseName .. ".bottomArm#widths", "Manual definition of the available lower link widths. Overwrites the category definition. Multiple width values separated by a whitespace.")
	schema:register(XMLValueType.INT, baseName .. ".bottomArm#ballType", "Ball type to load (1: regular ball, 2: ball with guide cone)", 1)
	schema:register(XMLValueType.STRING, baseName .. ".bottomArm#ballFilename", "Path to custom ball i3d file to use")
	schema:register(XMLValueType.BOOL, baseName .. ".bottomArm#ballDefaultVisibility", "Defines if the balls are also visible while the tool is not attached", "\'true\' if no toolbar is used (\'needsToolbar\' attribute)")
	schema:register(XMLValueType.NODE_INDEX, baseName .. "#steeringBarLeftNode", "Left steering bar node (Node of movingPart that should point towards the steeringBar left node of the tractor)")
	schema:register(XMLValueType.NODE_INDEX, baseName .. "#steeringBarRightNode", "Right steering bar node (Node of movingPart that should point towards the steeringBar right node of the tractor)")
	schema:register(XMLValueType.NODE_INDEX, baseName .. "#drawbarNode", "Drawbar node (Node of movingPart that should point towards the attacherJoint node of the tractor)")
	schema:register(XMLValueType.NODE_INDEX, baseName .. "#bottomArmLeftNode", "Left bottom arm node (Node can be used as movingTool target from the tractor)")
	schema:register(XMLValueType.NODE_INDEX, baseName .. "#bottomArmRightNode", "Right bottom arm node (Node can be used as movingTool target from the tractor)")
	schema:register(XMLValueType.VECTOR_3, baseName .. "#upperRotLimitScale", "Upper rot limit scale", "0 0 0")
	schema:register(XMLValueType.VECTOR_3, baseName .. "#lowerRotLimitScale", "Lower rot limit scale", "0 0 0")
	schema:register(XMLValueType.FLOAT, baseName .. "#rotLimitThreshold", "Defines when the transition from upper to lower rot limit starts (0: directly, 0.9: after 90% of lowering)", 0)
	schema:register(XMLValueType.VECTOR_3, baseName .. "#upperTransLimitScale", "Upper trans limit scale", "0 0 0")
	schema:register(XMLValueType.VECTOR_3, baseName .. "#lowerTransLimitScale", "Lower trans limit scale", "0 0 0")
	schema:register(XMLValueType.FLOAT, baseName .. "#transLimitThreshold", "Defines when the transition from upper to lower trans limit starts (0: directly, 0.9: after 90% of lowering)", 0)
	schema:register(XMLValueType.VECTOR_3, baseName .. "#rotLimitSpring", "Rotation limit spring", "0 0 0")
	schema:register(XMLValueType.VECTOR_3, baseName .. "#rotLimitDamping", "Rotation limit damping", "1 1 1")
	schema:register(XMLValueType.VECTOR_3, baseName .. "#rotLimitForceLimit", "Rotation limit force limit", "-1 -1 -1")
	schema:register(XMLValueType.VECTOR_3, baseName .. "#transLimitSpring", "Translation limit spring", "0 0 0")
	schema:register(XMLValueType.VECTOR_3, baseName .. "#transLimitDamping", "Translation limit damping", "1 1 1")
	schema:register(XMLValueType.VECTOR_3, baseName .. "#transLimitForceLimit", "Translation limit force limit", "-1 -1 -1")
	schema:register(XMLValueType.INT, baseName .. "#attachAngleLimitAxis", "Direction axis which is used to calculate angle to enable attach", 1)
	schema:register(XMLValueType.FLOAT, baseName .. "#attacherHeight", "Height of attacher", "0.9 for trailer, 0.55 for trailer low")
	schema:register(XMLValueType.BOOL, baseName .. "#needsLowering", "Needs lowering")
	schema:register(XMLValueType.BOOL, baseName .. "#allowsLowering", "Allows lowering")
	schema:register(XMLValueType.BOOL, baseName .. "#isDefaultLowered", "Is default lowered", false)
	schema:register(XMLValueType.BOOL, baseName .. "#useFoldingLoweredState", "Use folding lowered state", false)
	schema:register(XMLValueType.BOOL, baseName .. "#forceSelectionOnAttach", "Is selected on attach", true)
	schema:register(XMLValueType.BOOL, baseName .. "#forceAllowDetachWhileLifted", "Attacher vehicle can be always detached no matter if we are lifted or not", false)
	schema:register(XMLValueType.INT, baseName .. "#forcedAttachingDirection", "Tool can be only attached in this direction", 0)
	schema:register(XMLValueType.BOOL, baseName .. "#allowFolding", "Folding is allowed while attached to this attacher joint", true)
	schema:register(XMLValueType.BOOL, baseName .. "#allowTurnOn", "Turn on is allowed while attached to this attacher joint", true)
	schema:register(XMLValueType.BOOL, baseName .. "#allowAI", "Toggling of AI is allowed while attached to this attacher joint", true)
	schema:register(XMLValueType.BOOL, baseName .. "#allowDetachWhileParentLifted", "If set to false the parent vehicle needs to be lowered to be able to detach this implement", true)
	schema:register(XMLValueType.BOOL, baseName .. "#useTopLights", "Defines if the tool attached to this attacher activates to automatic switch to the top lights", true)
	schema:register(XMLValueType.INT, baseName .. ".dependentAttacherJoint(?)#attacherJointIndex", "Dependent attacher joint index")
	schema:register(XMLValueType.NODE_INDEX, baseName .. ".additionalObjects.additionalObject(?)#node", "Additional object node")
	schema:register(XMLValueType.STRING, baseName .. ".additionalObjects.additionalObject(?)#attacherVehiclePath", "Path to vehicle for object activation")
	schema:register(XMLValueType.STRING, baseName .. ".additionalAttachment#filename", "Path to additional attachment")
	schema:register(XMLValueType.INT, baseName .. ".additionalAttachment#inputAttacherJointIndex", "Input attacher joint index of additional attachment")
	schema:register(XMLValueType.BOOL, baseName .. ".additionalAttachment#needsLowering", "Additional implements needs lowering")
	schema:register(XMLValueType.STRING, baseName .. ".additionalAttachment#jointType", "Additional implement joint type")
end

function Attachable.registerSupportXMLPaths(schema, key)
	schema:addDelayedRegistrationPath(key, "Attachable:support")
	schema:register(XMLValueType.STRING, key .. "#animationName", "Animation name")
	schema:register(XMLValueType.BOOL, key .. "#delayedOnLoad", "Defines if the animation is played onPostLoad or onPreInitComponentPlacement -> useful if the animation collides e.g. with the folding animation", false)
	schema:register(XMLValueType.BOOL, key .. "#delayedOnAttach", "Defines if the animation is played before or after the attaching process", true)
	schema:register(XMLValueType.BOOL, key .. "#detachAfterAnimation", "Defines if the vehicle is detached after the animation has played", true)
	schema:register(XMLValueType.FLOAT, key .. "#detachAnimationTime", "Defines when in the support animation the vehicle is detached (detachAfterAnimation needs to be true)", 1)
end

-- Local values: spec, attacherConfigs, i
function Attachable:onLoad(savegame)
	local v_u_16_ = self.spec_attachable
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.attacherJoint", "vehicle.inputAttacherJoints.inputAttacherJoint")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.needsLowering", "vehicle.inputAttacherJoints.inputAttacherJoint#needsLowering")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.allowsLowering", "vehicle.inputAttacherJoints.inputAttacherJoint#allowsLowering")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.isDefaultLowered", "vehicle.inputAttacherJoints.inputAttacherJoint#isDefaultLowered")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.forceSelectionOnAttach#value", "vehicle.inputAttacherJoints.inputAttacherJoint#forceSelectionOnAttach")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.topReferenceNode#index", "vehicle.attacherJoint#topReferenceNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.attachRootNode#index", "vehicle.attacherJoint#rootNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.inputAttacherJoints", "vehicle.attachable.inputAttacherJoints")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.inputAttacherJointConfigurations", "vehicle.attachable.inputAttacherJointConfigurations")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.brakeForce", "vehicle.attachable.brakeForce#force")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.attachable.brakeForce", "vehicle.attachable.brakeForce#force", nil, true)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.steeringAxleAngleScale", "vehicle.attachable.steeringAxleAngleScale")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.support", "vehicle.attachable.support")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.lowerAnimation", "vehicle.attachable.lowerAnimation")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.toolCameras", "vehicle.attachable.toolCameras")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.attachable.toolCameras#count", "vehicle.attachable.toolCameras")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.attachable.toolCameras.toolCamera1", "vehicle.attachable.toolCamera")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.attachable.toolCameras.toolCamera2", "vehicle.attachable.toolCamera")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.attachable.toolCameras.toolCamera3", "vehicle.attachable.toolCamera")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.foldable.foldingParts#onlyFoldOnDetach", "vehicle.attachable#allowFoldingWhileAttached")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.maximalAirConsumptionPerFullStop", "vehicle.attachable.airConsumer#usage (is now in usage per second at full brake power)")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.attachable.steeringAxleAngleScale#targetNode", "vehicle.attachable.steeringAxleAngleScale.targetNode#node")
	v_u_16_.attacherJoint = nil
	v_u_16_.supportAnimations = {}
	self.xmlFile:iterate("vehicle.attachable.support", function(_, p17_)
		-- upvalues: (copy) self, (copy) v_u_16_
		local v18_ = {}
		if self:loadSupportAnimationFromXML(v18_, self.xmlFile, p17_) then
			local v19_ = v_u_16_.supportAnimations
			table.insert(v19_, v18_)
		end
	end)
	v_u_16_.inputAttacherJoints = {}
	self.xmlFile:iterate("vehicle.attachable.inputAttacherJoints.inputAttacherJoint", function(p20_, p21_)
		-- upvalues: (copy) self, (copy) v_u_16_
		local v22_ = {}
		if self:loadInputAttacherJoint(self.xmlFile, p21_, v22_, p20_ - 1) then
			local v23_ = v_u_16_.inputAttacherJoints
			table.insert(v23_, v22_)
		end
	end)
	if self.configurations.inputAttacherJoint ~= nil then
		local v24_ = string.format("vehicle.attachable.inputAttacherJointConfigurations.inputAttacherJointConfiguration(%d)", self.configurations.inputAttacherJoint - 1)
		self.xmlFile:iterate(v24_ .. ".inputAttacherJoint", function(p25_, p26_)
			-- upvalues: (copy) self, (copy) v_u_16_
			local v27_ = {}
			if self:loadInputAttacherJoint(self.xmlFile, p26_, v27_, p25_ - 1) then
				local v28_ = v_u_16_.inputAttacherJoints
				table.insert(v28_, v27_)
			end
		end)
		self.xmlFile:iterate(v24_ .. ".support", function(_, p29_)
			-- upvalues: (copy) self, (copy) v_u_16_
			local v30_ = {}
			if self:loadSupportAnimationFromXML(v30_, self.xmlFile, p29_) then
				local v31_ = v_u_16_.supportAnimations
				table.insert(v31_, v30_)
			end
		end)
	end
	v_u_16_.brakeForce = self.xmlFile:getValue("vehicle.attachable.brakeForce#force", 0) * 10
	v_u_16_.maxBrakeForce = self.xmlFile:getValue("vehicle.attachable.brakeForce#maxForce", 0) * 10
	v_u_16_.loweredBrakeForce = self.xmlFile:getValue("vehicle.attachable.brakeForce#loweredForce", -1) * 10
	v_u_16_.maxBrakeForceMass = self.xmlFile:getValue("vehicle.attachable.brakeForce#maxForceMass", 0) / 1000
	v_u_16_.maxBrakeForceMassIncludeAttachables = self.xmlFile:getValue("vehicle.attachable.brakeForce#includeAttachables", false)
	if v_u_16_.maxBrakeForce ~= 0 and v_u_16_.maxBrakeForceMass == 0 then
		Logging.xmlWarning(self.xmlFile, "Max. brake force is defined, but no \'maxBrakeForceMass\' is given. The brake force will not be used.")
	end
	v_u_16_.airConsumerUsage = self.xmlFile:getValue("vehicle.attachable.airConsumer#usage", 0)
	v_u_16_.allowFoldingWhileAttached = self.xmlFile:getValue("vehicle.attachable#allowFoldingWhileAttached", true)
	v_u_16_.allowFoldingWhileLowered = self.xmlFile:getValue("vehicle.attachable#allowFoldingWhileLowered", true)
	v_u_16_.blockFoliageDestruction = self.xmlFile:getValue("vehicle.attachable#blockFoliageDestruction", false)
	v_u_16_.requiresExternalPower = self.xmlFile:getValue("vehicle.attachable.power#requiresExternalPower", true)
	v_u_16_.attachToPowerWarning = self.xmlFile:getValue("vehicle.attachable.power#attachToPowerWarning", "warning_attachToPower", self.customEnvironment)
	v_u_16_.updateWheels = true
	v_u_16_.updateSteeringAxleAngle = true
	v_u_16_.isDetachingBlocked = false
	v_u_16_.isSelected = false
	v_u_16_.attachTime = 0
	v_u_16_.steeringAxleAngle = 0
	v_u_16_.steeringAxleTargetAngle = 0
	self:loadSteeringAxleFromXML(v_u_16_, self.xmlFile, "vehicle.attachable.steeringAxleAngleScale")
	if v_u_16_.steeringAxleDistanceDelay > 0 then
		v_u_16_.steeringAxleTargetAngleHistory = {}
		local v32_ = v_u_16_.steeringAxleDistanceDelay / 0.1
		for v33_ = 1, math.floor(v32_) do
			v_u_16_.steeringAxleTargetAngleHistory[v33_] = 0
		end
		v_u_16_.steeringAxleTargetAngleHistoryIndex = 1
		v_u_16_.steeringAxleTargetAngleHistoryMoved = 1
	end
	v_u_16_.steeringAngleNodes = {}
	self.xmlFile:iterate("vehicle.attachable.steeringAngleNodes.steeringAngleNode", function(_, p34_)
		-- upvalues: (copy) self, (copy) v_u_16_
		local v35_ = {}
		if self:loadSteeringAngleNodeFromXML(v35_, self.xmlFile, p34_) then
			local v36_ = v_u_16_.steeringAngleNodes
			table.insert(v36_, v35_)
		end
	end)
	v_u_16_.detachingInProgress = false
	v_u_16_.lowerAnimation = self.xmlFile:getValue("vehicle.attachable.lowerAnimation#name")
	v_u_16_.lowerAnimationSpeed = self.xmlFile:getValue("vehicle.attachable.lowerAnimation#speed", 1)
	v_u_16_.lowerAnimationDirectionOnDetach = self.xmlFile:getValue("vehicle.attachable.lowerAnimation#directionOnDetach", 0)
	v_u_16_.lowerAnimationDefaultLowered = self.xmlFile:getValue("vehicle.attachable.lowerAnimation#defaultLowered", false)
	v_u_16_.toolCameras = {}
	self.xmlFile:iterate("vehicle.attachable.toolCameras.toolCamera", function(_, p37_)
		-- upvalues: (copy) self, (copy) v_u_16_
		local v38_ = VehicleCamera.new(self)
		if v38_:loadFromXML(self.xmlFile, p37_) then
			local v39_ = v_u_16_.toolCameras
			table.insert(v39_, v38_)
		end
	end)
	if self.isClient then
		v_u_16_.samples = {}
		v_u_16_.samples.active = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.attachable.sounds", "active", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_16_.isActiveSamplePlaying = false
	end
	v_u_16_.isHardAttached = false
	v_u_16_.isAdditionalAttachment = false
	v_u_16_.texts = {}
	v_u_16_.texts.liftObject = g_i18n:getText("action_liftOBJECT")
	v_u_16_.texts.lowerObject = g_i18n:getText("action_lowerOBJECT")
	v_u_16_.texts.warningFoldingAttached = g_i18n:getText("warning_foldingNotWhileAttached")
	v_u_16_.texts.warningFoldingLowered = g_i18n:getText("warning_foldingNotWhileLowered")
	v_u_16_.texts.warningFoldingAttacherJoint = g_i18n:getText("warning_foldingNotWhileAttachedToAttacherJoint")
	v_u_16_.texts.lowerImplementFirst = g_i18n:getText("warning_lowerImplementFirst")
end

-- Local values: spec, _, supportAnimation, brakeForce
function Attachable:onPostLoad(savegame)
	local v41_ = self.spec_attachable
	for _, v42_ in ipairs(v41_.supportAnimations) do
		if not v42_.delayedOnLoad and self:getIsSupportAnimationAllowed(v42_) then
			self:playAnimation(v42_.animationName, 1, nil, true, false)
			AnimatedVehicle.updateAnimationByName(self, v42_.animationName, 9999999, true)
		end
	end
	if self.brake ~= nil then
		local v43_ = self:getBrakeForce()
		if v43_ > 0 then
			self:brake(v43_, true)
		end
	end
	local v44_
	if #v41_.steeringAngleNodes > 0 or v41_.steeringAxleTargetNode ~= nil then
		v44_ = true
	elseif self.getWheels == nil then
		v44_ = false
	else
		v44_ = #self:getWheels() > 0
	end
	v41_.updateSteeringAxleAngle = v44_
	if #v41_.inputAttacherJoints == 0 then
		SpecializationUtil.removeEventListener(self, "onUpdateInterpolation", Attachable)
		SpecializationUtil.removeEventListener(self, "onUpdate", Attachable)
	end
end

-- Local values: spec, inputAttacherJointIndex, inputAttacherJoint
function Attachable:onLoadFinished(savegame)
	local v46_ = self.spec_attachable
	for v47_, v48_ in ipairs(v46_.inputAttacherJoints) do
		v48_.jointInfo = g_currentMission.vehicleSystem:registerInputAttacherJoint(self, v47_, v48_)
	end
end

-- Local values: spec, _, supportAnimation, _, inputAttacherJoint, lowerAnimTime, speed
function Attachable:onPreInitComponentPlacement(savegame)
	local v51_ = self.spec_attachable
	for _, v52_ in ipairs(v51_.supportAnimations) do
		if v52_.delayedOnLoad and self:getIsSupportAnimationAllowed(v52_) then
			self:playAnimation(v52_.animationName, 1, nil, true, false)
			AnimatedVehicle.updateAnimationByName(self, v52_.animationName, 9999999, true)
		end
	end
	for _, v53_ in ipairs(v51_.inputAttacherJoints) do
		if v53_.drawbarNode ~= nil then
			self:setMovingPartReferenceNode(v53_.drawbarNode, v53_.node, false)
			self:setMovingPartReferenceNode(v53_.drawbarNode, nil, false)
		end
	end
	if savegame == nil or savegame.resetVehicles then
		if v51_.lowerAnimationDefaultLowered then
			self:playAnimation(v51_.lowerAnimation, 1, nil, true, false)
			AnimatedVehicle.updateAnimationByName(self, v51_.lowerAnimation, 9999999, true)
		end
	else
		if v51_.lowerAnimation ~= nil and self.playAnimation ~= nil then
			local v54_ = savegame.xmlFile:getValue(savegame.key .. ".attachable#lowerAnimTime")
			if v54_ ~= nil then
				local v55_ = v54_ < 0.5 and -1 or 1
				self:playAnimation(v51_.lowerAnimation, v55_, nil, true, false)
				self:setAnimationTime(v51_.lowerAnimation, v54_)
				AnimatedVehicle.updateAnimationByName(self, v51_.lowerAnimation, 9999999, true)
				if self.updateCylinderedInitial ~= nil then
					self:updateCylinderedInitial(false)
				end
			end
		end
		v51_.isDetachingBlocked = savegame.xmlFile:getValue(savegame.key .. ".attachable#isDetachingBlocked", false)
	end
end

-- Local values: spec, i, inputAttacherJoint
function Attachable:onPreDelete()
	local v57_ = self.spec_attachable
	if v57_.attacherVehicle ~= nil then
		v57_.attacherVehicle:detachImplementByObject(self, true)
	end
	if v57_.inputAttacherJoints ~= nil then
		for v58_ = 1, #v57_.inputAttacherJoints do
			local v59_ = v57_.inputAttacherJoints[v58_]
			if v59_.jointInfo ~= nil then
				g_currentMission.vehicleSystem:removeInputAttacherJoint(v59_.jointInfo)
				v59_.jointInfo = nil
			end
		end
	end
end

-- Local values: spec, _, camera, i, inputAttacherJoint
function Attachable:onDelete()
	local v61_ = self.spec_attachable
	if v61_.toolCameras ~= nil then
		for _, v62_ in ipairs(v61_.toolCameras) do
			v62_:delete()
		end
	end
	if v61_.inputAttacherJoints ~= nil then
		for v63_ = 1, #v61_.inputAttacherJoints do
			local v64_ = v61_.inputAttacherJoints[v63_]
			if v64_.bottomArm ~= nil and v64_.bottomArm.sharedLoadRequestIdBalls ~= nil then
				g_i3DManager:releaseSharedI3DFile(v64_.bottomArm.sharedLoadRequestIdBalls)
			end
		end
	end
	if v61_.samples ~= nil then
		g_soundManager:deleteSamples(v61_.samples.active)
	end
end

-- Local values: spec, lowerAnimTime
function Attachable:saveToXMLFile(xmlFile, key, usedModNames)
	local v68_ = self.spec_attachable
	if v68_.lowerAnimation ~= nil and self.playAnimation ~= nil then
		local v69_ = self:getAnimationTime(v68_.lowerAnimation)
		xmlFile:setValue(key .. "#lowerAnimTime", v69_)
	end
	xmlFile:setValue(key .. "#isDetachingBlocked", Utils.getNoNil(v68_.isDetachingBlocked, false))
end

-- Local values: object, inputJointDescIndex, jointDescIndex, moveDown, implementIndex
function Attachable:onReadStream(streamId, connection)
	if streamReadBool(streamId) then
		local v72_ = NetworkUtil.readNodeObject(streamId)
		local v73_ = streamReadInt8(streamId)
		local v74_ = streamReadInt8(streamId)
		local v75_ = streamReadBool(streamId)
		local v76_ = streamReadInt8(streamId)
		if v72_ ~= nil and v72_:getIsSynchronized() then
			v72_:attachImplement(self, v73_, v74_, true, v76_, v75_, true, true)
			v72_:setJointMoveDown(v74_, v75_, true)
		end
	end
end

-- Local values: spec, attacherJointVehicleSpec, implementIndex, implement, inputJointDescIndex, jointDescIndex, jointDesc, moveDown
function Attachable:onWriteStream(streamId, connection)
	local v79_ = self.spec_attachable
	streamWriteBool(streamId, v79_.attacherVehicle ~= nil)
	if v79_.attacherVehicle ~= nil then
		local v80_ = v79_.attacherVehicle.spec_attacherJoints
		local v81_ = v79_.attacherVehicle:getImplementIndexByObject(self)
		local v82_ = v80_.attachedImplements[v81_]
		local v83_ = v79_.inputAttacherJointDescIndex
		local v84_ = v82_.jointDescIndex
		local v85_ = v80_.attacherJoints[v84_].moveDown
		NetworkUtil.writeNodeObject(streamId, v79_.attacherVehicle)
		streamWriteInt8(streamId, v83_)
		streamWriteInt8(streamId, v84_)
		streamWriteBool(streamId, v85_)
		streamWriteInt8(streamId, v81_)
	end
end

-- Local values: attacherVehicle, implement
function Attachable:onUpdateInterpolation(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v88_ = self:getAttacherVehicle()
	if v88_ ~= nil and (self.currentUpdateDistance < v88_.spec_attacherJoints.maxUpdateDistance and self.updateLoopIndex == v88_.updateLoopIndex) then
		local v89_ = v88_:getImplementByObject(self)
		if v89_ ~= nil then
			v88_:updateAttacherJointGraphics(v89_, dt, true)
			self:updateInputAttacherJointGraphics(v89_, dt, true)
		end
	end
end

-- Local values: spec, yRot, steeringAngle, baseVehicle, allowedBackwards, scale, startSpeed, endSpeed, lastIndex, dir, speed, angle, alpha, numSteeringAngleNodes, baseVehicle, i, attacherVehicle
function Attachable:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v92_ = self.spec_attachable
	local v93_ = nil
	if v92_.updateSteeringAxleAngle and (self:getLastSpeed() > 0.25 or not self.finishedFirstUpdate) then
		local v94_ = 0
		local v95_ = self:getSteeringAxleBaseVehicle()
		local v96_ = v92_.steeringAxleUpdateBackwards
		if v96_ then
			v96_ = not self:getIsAIActive()
		end
		if v95_ == nil and v92_.steeringAxleReferenceComponentNode == nil or self.movingDirection < 0 and not v96_ then
			if self:getLastSpeed() > 0.2 then
				v94_ = 0
			end
		else
			v93_ = Utils.getYRotationBetweenNodes(self.steeringAxleNode, v92_.steeringAxleReferenceComponentNode or v95_.steeringAxleNode)
			local v97_
			if v92_.steeringAxleAngleScaleSpeedDependent then
				local v98_ = v92_.steeringAxleAngleScaleStart
				local v99_ = v92_.steeringAxleAngleScaleEnd
				local v100_ = 1 + (self:getLastSpeed() - v98_) * 1 / (v98_ - v99_)
				v97_ = math.clamp(v100_, 0, 1)
			else
				v97_ = 1
			end
			v94_ = v93_ * v97_
		end
		local v101_ = not self:getIsSteeringAxleAllowed() and 0 or v94_
		if v92_.steeringAxleDistanceDelay > 0 then
			v92_.steeringAxleTargetAngleHistoryMoved = v92_.steeringAxleTargetAngleHistoryMoved + self.lastMovedDistance
			if v92_.steeringAxleTargetAngleHistoryMoved > 0.1 then
				v92_.steeringAxleTargetAngleHistory[v92_.steeringAxleTargetAngleHistoryIndex] = v101_
				v92_.steeringAxleTargetAngleHistoryIndex = v92_.steeringAxleTargetAngleHistoryIndex + 1
				if v92_.steeringAxleTargetAngleHistoryIndex > #v92_.steeringAxleTargetAngleHistory then
					v92_.steeringAxleTargetAngleHistoryIndex = 1
				end
			end
			local v102_ = v92_.steeringAxleTargetAngleHistoryIndex + 1
			local v103_ = #v92_.steeringAxleTargetAngleHistory < v102_ and 1 or v102_
			v92_.steeringAxleTargetAngle = v92_.steeringAxleTargetAngleHistory[v103_]
		else
			v92_.steeringAxleTargetAngle = v101_
		end
		local v104_ = v92_.steeringAxleTargetAngle - v92_.steeringAxleAngle
		local v105_ = math.sign(v104_)
		local v106_ = v92_.steeringAxleAngleSpeed
		local v107_ = not self.finishedFirstUpdate and 9999 or v106_
		if v105_ == 1 then
			local v108_ = v92_.steeringAxleAngle + v105_ * dt * v107_
			local v109_ = v92_.steeringAxleTargetAngle
			v92_.steeringAxleAngle = math.min(v108_, v109_)
		else
			local v110_ = v92_.steeringAxleAngle + v105_ * dt * v107_
			local v111_ = v92_.steeringAxleTargetAngle
			v92_.steeringAxleAngle = math.max(v110_, v111_)
		end
		if v92_.steeringAxleTargetNode ~= nil then
			local v112_
			if v92_.steeringAxleTargetNodeRefAngle == nil then
				local v113_ = v92_.steeringAxleAngle
				local v114_ = v92_.steeringAxleAngleMinRot
				local v115_ = v92_.steeringAxleAngleMaxRot
				v112_ = math.clamp(v113_, v114_, v115_)
			else
				local v116_ = v92_.steeringAxleAngle / v92_.steeringAxleTargetNodeRefAngle
				local v117_ = math.clamp(v116_, -1, 1)
				if v117_ >= 0 then
					v112_ = v92_.steeringAxleAngleMaxRot * v117_
				else
					v112_ = v92_.steeringAxleAngleMinRot * -v117_
				end
			end
			setRotation(v92_.steeringAxleTargetNode, 0, v112_ * v92_.steeringAxleDirection, 0)
			self:setMovingToolDirty(v92_.steeringAxleTargetNode)
		end
	end
	local v118_ = #v92_.steeringAngleNodes
	if v118_ > 0 and v93_ == nil then
		local v119_ = self:getSteeringAxleBaseVehicle()
		if v119_ ~= nil then
			v93_ = Utils.getYRotationBetweenNodes(self.steeringAxleNode, v119_.steeringAxleNode)
		end
	end
	if v93_ ~= nil then
		for v120_ = 1, v118_ do
			self:updateSteeringAngleNode(v92_.steeringAngleNodes[v120_], v93_, dt)
		end
	end
	local v121_ = self:getAttacherVehicle()
	if v92_.detachingInProgress and self:getIsReadyToFinishDetachProcess() then
		if v121_ ~= nil then
			v121_:detachImplementByObject(self)
		end
		v92_.detachingInProgress = false
	end
end

-- Local values: spec, i, inputAttacherJoint
function Attachable:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v123_ = self.spec_attachable
	for v124_ = 1, #v123_.inputAttacherJoints do
		local v125_ = v123_.inputAttacherJoints[v124_]
		if v125_.jointInfo ~= nil then
			g_currentMission.vehicleSystem:updateInputAttacherJoint(v125_.jointInfo)
		end
	end
	if self.isClient then
		if self.lastSpeed > 0.00027 then
			if not v123_.isActiveSamplePlaying then
				g_soundManager:playSamples(v123_.samples.active)
				v123_.isActiveSamplePlaying = true
				return
			end
		elseif v123_.isActiveSamplePlaying then
			g_soundManager:stopSamples(v123_.samples.active)
			v123_.isActiveSamplePlaying = false
		end
	end
end

-- Local values: node, jointTypeStr, jointType, needsTrailerJoint, needsLowTrailerJoint, subTypeStr, parentComponent, copy, defaultUpperRotationOffset, categories, i, category, _, category, defaultNeedsLowering, defaultAllowsLowering, k, dependentKey, attacherJointIndex, i, baseKey, entry, filename, additionalJointTypeStr, additionalJointType
function Attachable:loadInputAttacherJoint(xmlFile, key, inputAttacherJoint, index)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#index", key .. "#node")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#indexVisual", key .. "#nodeVisual")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#ptoInputNode", "vehicle.powerTakeOffs.input")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#lowerDistanceToGround", key .. ".distanceToGround#lower")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#upperDistanceToGround", key .. ".distanceToGround#upper")
	local v_u_130_ = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	if v_u_130_ == nil then
		return false
	end
	inputAttacherJoint.node = v_u_130_
	inputAttacherJoint.heightNodes = {}
	xmlFile:iterate(key .. ".heightNode", function(_, p131_)
		-- upvalues: (copy) self, (copy) xmlFile, (copy) v_u_130_, (copy) inputAttacherJoint
		local v132_ = {}
		if self:loadAttacherJointHeightNode(xmlFile, p131_, v132_, v_u_130_) then
			local v133_ = inputAttacherJoint.heightNodes
			table.insert(v133_, v132_)
		end
	end)
	local v134_ = xmlFile:getValue(key .. "#jointType")
	local v135_ = nil
	if v134_ == nil then
		Logging.xmlWarning(self.xmlFile, "Missing jointType for inputAttacherJoint \'%s\'!", key)
	else
		v135_ = AttacherJoints.jointTypeNameToInt[v134_]
		if v135_ == nil then
			Logging.xmlWarning(self.xmlFile, "Invalid jointType \'%s\' for inputAttacherJoint \'%s\'!", tostring(v134_), key)
		end
	end
	if v135_ == nil then
		local v136_ = xmlFile:getValue(key .. "#needsTrailerJoint", false)
		local v137_ = xmlFile:getValue(key .. "#needsLowJoint", false)
		if v136_ then
			if v137_ then
				v135_ = AttacherJoints.JOINTTYPE_TRAILERLOW
			else
				v135_ = AttacherJoints.JOINTTYPE_TRAILER
			end
		else
			v135_ = AttacherJoints.JOINTTYPE_IMPLEMENT
		end
	end
	inputAttacherJoint.jointType = v135_
	local v138_ = xmlFile:getValue(key .. ".subType#name")
	if not string.isNilOrWhitespace(v138_) then
		inputAttacherJoint.subTypes = string.split(v138_, " ")
	end
	inputAttacherJoint.subTypeShowWarning = xmlFile:getValue(key .. ".subType#showWarning", true)
	local v139_ = self:getParentComponent(inputAttacherJoint.node)
	inputAttacherJoint.jointOrigTrans = { getTranslation(inputAttacherJoint.node) }
	inputAttacherJoint.jointOrigOffsetComponent = { localToLocal(v139_, inputAttacherJoint.node, 0, 0, 0) }
	inputAttacherJoint.jointOrigRotOffsetComponent = { localRotationToLocal(v139_, inputAttacherJoint.node, 0, 0, 0) }
	inputAttacherJoint.topReferenceNode = xmlFile:getValue(key .. "#topReferenceNode", nil, self.components, self.i3dMappings)
	inputAttacherJoint.rootNode = xmlFile:getValue(key .. "#rootNode", v139_, self.components, self.i3dMappings)
	inputAttacherJoint.rootNodeBackup = inputAttacherJoint.rootNode
	inputAttacherJoint.allowsDetaching = xmlFile:getValue(key .. "#allowsDetaching", true)
	inputAttacherJoint.fixedRotation = xmlFile:getValue(key .. "#fixedRotation", false)
	inputAttacherJoint.hardAttach = xmlFile:getValue(key .. "#hardAttach", false)
	if inputAttacherJoint.hardAttach and #self.components > 1 then
		Logging.xmlWarning(self.xmlFile, "hardAttach only available for single component vehicles! InputAttacherJoint \'%s\'!", key)
		inputAttacherJoint.hardAttach = false
	end
	inputAttacherJoint.visualNode = xmlFile:getValue(key .. "#nodeVisual", nil, self.components, self.i3dMappings)
	if inputAttacherJoint.hardAttach and inputAttacherJoint.visualNode ~= nil then
		inputAttacherJoint.visualNodeData = {
			["parent"] = getParent(inputAttacherJoint.visualNode),
			["translation"] = { getTranslation(inputAttacherJoint.visualNode) },
			["rotation"] = { getRotation(inputAttacherJoint.visualNode) },
			["index"] = getChildIndex(inputAttacherJoint.visualNode)
		}
	end
	inputAttacherJoint.smoothAttachTime = xmlFile:getValue(key .. "#smoothAttachTime")
	if v135_ == AttacherJoints.JOINTTYPE_IMPLEMENT or (v135_ == AttacherJoints.JOINTTYPE_CUTTER or v135_ == AttacherJoints.JOINTTYPE_CUTTERHARVESTER) then
		if xmlFile:getValue(key .. ".distanceToGround#lower") == nil then
			Logging.xmlWarning(self.xmlFile, "Missing \'.distanceToGround#lower\' for inputAttacherJoint \'%s\'!", key)
		end
		if xmlFile:getValue(key .. ".distanceToGround#upper") == nil then
			Logging.xmlWarning(self.xmlFile, "Missing \'.distanceToGround#upper\' for inputAttacherJoint \'%s\'!", key)
		end
	end
	inputAttacherJoint.lowerDistanceToGround = xmlFile:getValue(key .. ".distanceToGround#lower", 0.7)
	inputAttacherJoint.upperDistanceToGround = xmlFile:getValue(key .. ".distanceToGround#upper", 1)
	if inputAttacherJoint.lowerDistanceToGround > inputAttacherJoint.upperDistanceToGround then
		Logging.xmlWarning(self.xmlFile, "distanceToGround#lower may not be larger than distanceToGround#upper for inputAttacherJoint \'%s\'. Switching values!", key)
		local v140_ = inputAttacherJoint.lowerDistanceToGround
		inputAttacherJoint.lowerDistanceToGround = inputAttacherJoint.upperDistanceToGround
		inputAttacherJoint.upperDistanceToGround = v140_
	end
	inputAttacherJoint.distanceToGroundByVehicle = {}
	xmlFile:iterate(key .. ".distanceToGround.vehicle", function(_, p141_)
		-- upvalues: (copy) xmlFile, (copy) inputAttacherJoint
		local v142_ = {
			["filename"] = xmlFile:getValue(p141_ .. "#filename")
		}
		if v142_.filename ~= nil then
			v142_.filename = string.lower(v142_.filename)
			v142_.lower = xmlFile:getValue(p141_ .. "#lower", inputAttacherJoint.lowerDistanceToGround)
			v142_.upper = xmlFile:getValue(p141_ .. "#upper", inputAttacherJoint.upperDistanceToGround)
			local v143_ = inputAttacherJoint.distanceToGroundByVehicle
			table.insert(v143_, v142_)
		end
	end)
	inputAttacherJoint.lowerDistanceToGroundOriginal = inputAttacherJoint.lowerDistanceToGround
	inputAttacherJoint.upperDistanceToGroundOriginal = inputAttacherJoint.upperDistanceToGround
	inputAttacherJoint.lowerRotationOffset = xmlFile:getValue(key .. "#lowerRotationOffset", 0)
	local v144_ = v135_ == AttacherJoints.JOINTTYPE_IMPLEMENT and 8 or 0
	inputAttacherJoint.upperRotationOffset = xmlFile:getValue(key .. "#upperRotationOffset", v144_)
	inputAttacherJoint.allowsJointRotLimitMovement = xmlFile:getValue(key .. "#allowsJointRotLimitMovement", true)
	inputAttacherJoint.allowsJointTransLimitMovement = xmlFile:getValue(key .. "#allowsJointTransLimitMovement", true)
	inputAttacherJoint.needsToolbar = xmlFile:getValue(key .. "#needsToolbar", false)
	if inputAttacherJoint.needsToolbar and v135_ ~= AttacherJoints.JOINTTYPE_IMPLEMENT then
		Logging.xmlWarning(self.xmlFile, "\'needsToolbar\' requires jointType \'implement\' for inputAttacherJoint \'%s\'!", key)
		inputAttacherJoint.needsToolbar = false
	end
	if v135_ == AttacherJoints.JOINTTYPE_IMPLEMENT and not inputAttacherJoint.needsToolbar then
		inputAttacherJoint.bottomArm = {}
		local v145_ = xmlFile:getValue(key .. ".bottomArm#categories", "", true)
		for _, v146_ in ipairs(v145_) do
			if v146_ < 0 or v146_ > 4 then
				Logging.xmlWarning(xmlFile, "Bottom arm category should be between 0 and 4 in \'%s\'", key)
			end
		end
		inputAttacherJoint.bottomArm.widths = xmlFile:getValue(key .. ".bottomArm#widths", nil, true)
		if inputAttacherJoint.bottomArm.widths == nil or #inputAttacherJoint.bottomArm.widths == 0 then
			inputAttacherJoint.bottomArm.widths = {}
			for _, v147_ in ipairs(v145_) do
				local v148_ = inputAttacherJoint.bottomArm.widths
				local v149_ = AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[v147_]
				table.insert(v148_, v149_)
			end
		end
		inputAttacherJoint.bottomArm.ballType = xmlFile:getValue(key .. ".bottomArm#ballType", 1)
		inputAttacherJoint.bottomArm.ballDefaultVisibility = xmlFile:getValue(key .. ".bottomArm#ballDefaultVisibility", not inputAttacherJoint.needsToolbar)
		inputAttacherJoint.bottomArm.ballFilename = xmlFile:getValue(key .. ".bottomArm#ballFilename")
		if inputAttacherJoint.bottomArm.ballFilename == nil then
			inputAttacherJoint.bottomArm.ballFilename = string.format(Attachable.LOWER_LINK_BALL_FILENAME, inputAttacherJoint.bottomArm.ballType)
		else
			inputAttacherJoint.bottomArm.ballFilename = Utils.getFilename(inputAttacherJoint.bottomArm.ballFilename, self.baseDirectory)
		end
		if #inputAttacherJoint.bottomArm.widths > 0 and inputAttacherJoint.bottomArm.ballFilename ~= nil then
			if fileExists(inputAttacherJoint.bottomArm.ballFilename) then
				inputAttacherJoint.bottomArm.sharedLoadRequestIdBalls = self:loadSubSharedI3DFile(inputAttacherJoint.bottomArm.ballFilename, false, false, Attachable.onBottomArmBallsI3DLoaded, self, inputAttacherJoint)
			else
				Logging.xmlWarning(xmlFile, "Unable to load lower link balls from \'%s\' in \'%s\'", inputAttacherJoint.bottomArm.ballFilename, key)
			end
		end
	end
	if self.setMovingPartReferenceNode ~= nil then
		inputAttacherJoint.steeringBarLeftNode = xmlFile:getValue(key .. "#steeringBarLeftNode", nil, self.components, self.i3dMappings)
		inputAttacherJoint.steeringBarRightNode = xmlFile:getValue(key .. "#steeringBarRightNode", nil, self.components, self.i3dMappings)
		inputAttacherJoint.drawbarNode = xmlFile:getValue(key .. "#drawbarNode", nil, self.components, self.i3dMappings)
	end
	inputAttacherJoint.bottomArmLeftNode = xmlFile:getValue(key .. "#bottomArmLeftNode", nil, self.components, self.i3dMappings)
	inputAttacherJoint.bottomArmRightNode = xmlFile:getValue(key .. "#bottomArmRightNode", nil, self.components, self.i3dMappings)
	inputAttacherJoint.upperRotLimitScale = xmlFile:getValue(key .. "#upperRotLimitScale", "0 0 0", true)
	inputAttacherJoint.lowerRotLimitScale = xmlFile:getValue(key .. "#lowerRotLimitScale", nil, true)
	if inputAttacherJoint.lowerRotLimitScale == nil then
		local v150_ = inputAttacherJoint.lowerDistanceToGround - inputAttacherJoint.upperDistanceToGround
		if math.abs(v150_) > 0.0001 then
			if v135_ == AttacherJoints.JOINTTYPE_IMPLEMENT then
				inputAttacherJoint.lowerRotLimitScale = { 0, 0, 1 }
			else
				inputAttacherJoint.lowerRotLimitScale = { 1, 1, 1 }
			end
		else
			inputAttacherJoint.lowerRotLimitScale = { 0, 0, 0 }
		end
	end
	inputAttacherJoint.rotLimitThreshold = xmlFile:getValue(key .. "#rotLimitThreshold", 0)
	inputAttacherJoint.upperTransLimitScale = xmlFile:getValue(key .. "#upperTransLimitScale", "0 0 0", true)
	inputAttacherJoint.lowerTransLimitScale = xmlFile:getValue(key .. "#lowerTransLimitScale", "0 1 0", true)
	inputAttacherJoint.transLimitThreshold = xmlFile:getValue(key .. "#transLimitThreshold", 0)
	inputAttacherJoint.rotLimitSpring = xmlFile:getValue(key .. "#rotLimitSpring", "0 0 0", true)
	inputAttacherJoint.rotLimitDamping = xmlFile:getValue(key .. "#rotLimitDamping", "1 1 1", true)
	inputAttacherJoint.rotLimitForceLimit = xmlFile:getValue(key .. "#rotLimitForceLimit", "-1 -1 -1", true)
	inputAttacherJoint.transLimitSpring = xmlFile:getValue(key .. "#transLimitSpring", "0 0 0", true)
	inputAttacherJoint.transLimitDamping = xmlFile:getValue(key .. "#transLimitDamping", "1 1 1", true)
	inputAttacherJoint.transLimitForceLimit = xmlFile:getValue(key .. "#transLimitForceLimit", "-1 -1 -1", true)
	inputAttacherJoint.attachAngleLimitAxis = xmlFile:getValue(key .. "#attachAngleLimitAxis", 1)
	inputAttacherJoint.attacherHeight = xmlFile:getValue(key .. "#attacherHeight")
	if inputAttacherJoint.attacherHeight == nil then
		if v135_ == AttacherJoints.JOINTTYPE_TRAILER then
			inputAttacherJoint.attacherHeight = 0.9
		elseif v135_ == AttacherJoints.JOINTTYPE_TRAILERLOW then
			inputAttacherJoint.attacherHeight = 0.55
		elseif v135_ == AttacherJoints.JOINTTYPE_TRAILERCAR then
			inputAttacherJoint.attacherHeight = 0.55
		end
	end
	local v151_ = inputAttacherJoint.jointType ~= AttacherJoints.JOINTTYPE_TRAILER and (inputAttacherJoint.jointType ~= AttacherJoints.JOINTTYPE_TRAILERLOW and inputAttacherJoint.jointType ~= AttacherJoints.JOINTTYPE_TRAILERCAR)
	local v152_ = inputAttacherJoint.jointType ~= AttacherJoints.JOINTTYPE_TRAILER and (inputAttacherJoint.jointType ~= AttacherJoints.JOINTTYPE_TRAILERLOW and inputAttacherJoint.jointType ~= AttacherJoints.JOINTTYPE_TRAILERCAR) and true or false
	inputAttacherJoint.needsLowering = xmlFile:getValue(key .. "#needsLowering", v151_)
	inputAttacherJoint.allowsLowering = xmlFile:getValue(key .. "#allowsLowering", v152_)
	inputAttacherJoint.isDefaultLowered = xmlFile:getValue(key .. "#isDefaultLowered", false)
	inputAttacherJoint.useFoldingLoweredState = xmlFile:getValue(key .. "#useFoldingLoweredState", false)
	inputAttacherJoint.forceSelection = xmlFile:getValue(key .. "#forceSelectionOnAttach", true)
	inputAttacherJoint.forceAllowDetachWhileLifted = xmlFile:getValue(key .. "#forceAllowDetachWhileLifted", false)
	inputAttacherJoint.forcedAttachingDirection = xmlFile:getValue(key .. "#forcedAttachingDirection", 0)
	inputAttacherJoint.allowFolding = xmlFile:getValue(key .. "#allowFolding", true)
	inputAttacherJoint.allowTurnOn = xmlFile:getValue(key .. "#allowTurnOn", true)
	inputAttacherJoint.allowAI = xmlFile:getValue(key .. "#allowAI", true)
	inputAttacherJoint.allowDetachWhileParentLifted = xmlFile:getValue(key .. "#allowDetachWhileParentLifted", true)
	inputAttacherJoint.useTopLights = xmlFile:getValue(key .. "#useTopLights", true)
	inputAttacherJoint.dependentAttacherJoints = {}
	local v153_ = 0
	while true do
		local v154_ = string.format(key .. ".dependentAttacherJoint(%d)", v153_)
		if not xmlFile:hasProperty(v154_) then
			break
		end
		local v155_ = xmlFile:getValue(v154_ .. "#attacherJointIndex")
		if v155_ ~= nil then
			local v156_ = inputAttacherJoint.dependentAttacherJoints
			table.insert(v156_, v155_)
		end
		v153_ = v153_ + 1
	end
	if inputAttacherJoint.hardAttach then
		inputAttacherJoint.needsLowering = false
		inputAttacherJoint.allowsLowering = false
		inputAttacherJoint.isDefaultLowered = false
		inputAttacherJoint.upperRotationOffset = 0
	end
	inputAttacherJoint.changeObjects = {}
	ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key, inputAttacherJoint.changeObjects, self.components, self)
	ObjectChangeUtil.setObjectChanges(inputAttacherJoint.changeObjects, false, self, self.setMovingToolDirty)
	inputAttacherJoint.additionalObjects = {}
	local v157_ = 0
	while true do
		local v158_ = string.format("%s.additionalObjects.additionalObject(%d)", key, v157_)
		if not xmlFile:hasProperty(v158_) then
			break
		end
		local v159_ = {
			["node"] = xmlFile:getValue(v158_ .. "#node", nil, self.components, self.i3dMappings),
			["attacherVehiclePath"] = xmlFile:getValue(v158_ .. "#attacherVehiclePath")
		}
		if v159_.node ~= nil and v159_.attacherVehiclePath ~= nil then
			v159_.attacherVehiclePath = NetworkUtil.convertToNetworkFilename(v159_.attacherVehiclePath)
			local v160_ = inputAttacherJoint.additionalObjects
			table.insert(v160_, v159_)
		end
		v157_ = v157_ + 1
	end
	inputAttacherJoint.additionalAttachment = {}
	local v161_ = xmlFile:getValue(key .. ".additionalAttachment#filename")
	if v161_ ~= nil then
		inputAttacherJoint.additionalAttachment.filename = Utils.getFilename(v161_, self.customEnvironment)
	end
	inputAttacherJoint.additionalAttachment.inputAttacherJointIndex = xmlFile:getValue(key .. ".additionalAttachment#inputAttacherJointIndex", 1)
	inputAttacherJoint.additionalAttachment.needsLowering = xmlFile:getValue(key .. ".additionalAttachment#needsLowering", false)
	local v162_ = xmlFile:getValue(key .. ".additionalAttachment#jointType")
	local v163_
	if v162_ == nil then
		v163_ = nil
	else
		v163_ = AttacherJoints.jointTypeNameToInt[v162_]
		if v163_ == nil then
			Logging.xmlWarning(self.xmlFile, "Invalid jointType \'%s\' for additonal implement \'%s\'!", tostring(v162_), inputAttacherJoint.additionalAttachment.filename)
		end
	end
	inputAttacherJoint.additionalAttachment.jointType = v163_ or AttacherJoints.JOINTTYPE_IMPLEMENT
	return true
end

function Attachable:loadAttacherJointHeightNode(xmlFile, key, heightNode, attacherJointNode)
	heightNode.node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	heightNode.attacherJointNode = attacherJointNode
	return true
end

function Attachable:getIsAttacherJointHeightNodeActive(heightNode)
	return true
end

function Attachable:getInputAttacherJointByJointDescIndex(index)
	return self.spec_attachable.inputAttacherJoints[index]
end

-- Local values: spec, i, inputAttacherJoint
function Attachable:getInputAttacherJointIndexByNode(node)
	local v173_ = self.spec_attachable
	for v174_ = 1, #v173_.inputAttacherJoints do
		if v173_.inputAttacherJoints[v174_].node == node then
			return v174_
		end
	end
	return nil
end

function Attachable:getAttacherVehicle()
	return self.spec_attachable.attacherVehicle
end

function Attachable:getShowAttachableMapHotspot()
	return self.spec_attachable.attacherVehicle == nil
end

function Attachable:getInputAttacherJoints()
	return self.spec_attachable.inputAttacherJoints
end

-- Local values: spec
function Attachable:getIsAttachedTo(vehicle)
	if vehicle == self then
		return true
	end
	local v180_ = self.spec_attachable
	if v180_.attacherVehicle ~= nil then
		if v180_.attacherVehicle == vehicle then
			return true
		end
		if v180_.attacherVehicle.getIsAttachedTo ~= nil then
			return v180_.attacherVehicle:getIsAttachedTo(vehicle)
		end
	end
	return false
end

function Attachable:getActiveInputAttacherJointDescIndex()
	return self.spec_attachable.inputAttacherJointDescIndex
end

function Attachable:getActiveInputAttacherJoint()
	return self.spec_attachable.attacherJoint
end

-- Local values: spec, inputAttacherJoint
function Attachable:getAllowsLowering()
	local v184_ = self.spec_attachable
	if v184_.isAdditionalAttachment and not v184_.additionalAttachmentNeedsLowering then
		return false, nil
	else
		local v185_ = self:getActiveInputAttacherJoint()
		if v185_ == nil or v185_.allowsLowering then
			return true, nil
		else
			return false, nil
		end
	end
end

function Attachable:loadSupportAnimationFromXML(supportAnimation, xmlFile, key)
	supportAnimation.animationName = xmlFile:getValue(key .. "#animationName")
	supportAnimation.delayedOnLoad = xmlFile:getValue(key .. "#delayedOnLoad", false)
	supportAnimation.delayedOnAttach = xmlFile:getValue(key .. "#delayedOnAttach", true)
	supportAnimation.detachAfterAnimation = xmlFile:getValue(key .. "#detachAfterAnimation", true)
	supportAnimation.detachAnimationTime = xmlFile:getValue(key .. "#detachAnimationTime", 1)
	return supportAnimation.animationName ~= nil
end

function Attachable:getIsSupportAnimationAllowed(supportAnimation)
	return self.playAnimation ~= nil
end

-- Local values: spec, readyforDetach, i, animation
function Attachable:getIsReadyToFinishDetachProcess()
	local v191_ = self.spec_attachable
	local v192_ = true
	for v193_ = 1, #v191_.supportAnimations do
		local v194_ = v191_.supportAnimations[v193_]
		if v194_.detachAfterAnimation then
			if v194_.detachAnimationTime >= 1 then
				if self:getIsAnimationPlaying(v194_.animationName) then
					v192_ = false
				end
			elseif self:getAnimationTime(v194_.animationName) < v194_.detachAnimationTime then
				v192_ = false
			end
		end
	end
	return v192_
end

-- Local values: spec, i, attacherVehicle
function Attachable:startDetachProcess(noEventSend)
	AttachableStartDetachEvent.sendEvent(self, noEventSend)
	local v197_ = self.spec_attachable
	for v198_ = 1, #v197_.supportAnimations do
		if v197_.supportAnimations[v198_].detachAfterAnimation and self:getIsSupportAnimationAllowed(v197_.supportAnimations[v198_]) then
			self:playAnimation(v197_.supportAnimations[v198_].animationName, 1, nil, true)
		end
	end
	if not self.isServer then
		return self:getIsReadyToFinishDetachProcess() and true or false
	end
	if not self:getIsReadyToFinishDetachProcess() then
		v197_.detachingInProgress = true
		return false
	end
	v197_.detachingInProgress = false
	local v199_ = self:getAttacherVehicle()
	if v199_ ~= nil then
		v199_:detachImplementByObject(self)
	end
	return true
end

-- Local values: attacherVehicle
function Attachable:getIsImplementChainLowered(defaultIsLowered)
	if not self:getIsLowered(defaultIsLowered) then
		return false
	end
	local v202_ = self:getAttacherVehicle()
	return (v202_ == nil or (v202_.getAllowsLowering == nil or (not v202_:getAllowsLowering() or v202_:getIsImplementChainLowered(defaultIsLowered)))) and true or false
end

function Attachable.getIsInWorkPosition(self)
	return true
end

function Attachable:getAttachbleAirConsumerUsage()
	return self.spec_attachable.airConsumerUsage
end

-- Local values: spec, attacherVehicle, attacherVehicle, implement
function Attachable:isDetachAllowed()
	local v205_ = self.spec_attachable
	if v205_.isDetachingBlocked then
		return false
	end
	if v205_.attacherJoint ~= nil then
		if v205_.attacherJoint.allowsDetaching == false then
			return false, nil, false
		end
		if v205_.attacherJoint.allowDetachWhileParentLifted == false then
			local v206_ = self:getAttacherVehicle()
			if v206_ ~= nil and (v206_.getIsLowered ~= nil and not v206_:getIsLowered(true)) then
				return false, string.format(v205_.texts.lowerImplementFirst, v206_.typeDesc), true
			end
		end
	end
	if v205_.isAdditionalAttachment then
		return false
	end
	local v207_ = self:getAttacherVehicle()
	if v207_ ~= nil then
		local v208_ = v207_:getImplementByObject(self)
		if v208_ ~= nil and v208_.attachingIsInProgress then
			return false
		end
	end
	return true, nil
end

function Attachable:isAttachAllowed(farmId, attacherVehicle)
	if g_currentMission.accessHandler:canFarmAccess(farmId, self) then
		if self.spec_attachable.detachingInProgress then
			return false, nil
		else
			return true, nil
		end
	else
		return false, nil
	end
end

function Attachable:getIsInputAttacherActive(inputAttacherJoint)
	return true
end

-- Local values: spec
function Attachable:getSteeringAxleBaseVehicle()
	local v212_ = self.spec_attachable
	if v212_.steeringAxleUseSuperAttachable and (v212_.attacherVehicle ~= nil and v212_.attacherVehicle.getAttacherVehicle ~= nil) then
		return v212_.attacherVehicle:getAttacherVehicle()
	elseif v212_.attacherVehicle == nil or not (v212_.steeringAxleForceUsage or v212_.attacherVehicle:getCanSteerAttachable(self)) then
		return nil
	else
		return v212_.attacherVehicle
	end
end

-- Local values: referenceComponentIndex, component
function Attachable:loadSteeringAxleFromXML(spec, xmlFile, key)
	spec.steeringAxleAngleScaleStart = xmlFile:getValue(key .. "#startSpeed", 10)
	spec.steeringAxleAngleScaleEnd = xmlFile:getValue(key .. "#endSpeed", 30)
	spec.steeringAxleAngleScaleSpeedDependent = xmlFile:getValue(key .. "#speedDependent", true)
	spec.steeringAxleUpdateBackwards = xmlFile:getValue(key .. "#backwards", false)
	spec.steeringAxleAngleSpeed = xmlFile:getValue(key .. "#speed", 60) * 0.001
	spec.steeringAxleUseSuperAttachable = xmlFile:getValue(key .. "#useSuperAttachable", false)
	spec.steeringAxleTargetNode = xmlFile:getValue(key .. ".targetNode#node", nil, self.components, self.i3dMappings)
	spec.steeringAxleTargetNodeRefAngle = xmlFile:getValue(key .. ".targetNode#refAngle")
	spec.steeringAxleAngleMinRot = xmlFile:getValue(key .. "#minRot", 0)
	spec.steeringAxleAngleMaxRot = xmlFile:getValue(key .. "#maxRot", 0)
	spec.steeringAxleDirection = xmlFile:getValue(key .. "#direction", 1)
	spec.steeringAxleForceUsage = xmlFile:getValue(key .. "#forceUsage", spec.steeringAxleTargetNode ~= nil)
	spec.steeringAxleDistanceDelay = xmlFile:getValue(key .. "#distanceDelay", 0)
	local v217_ = xmlFile:getValue(key .. "#referenceComponentIndex")
	if v217_ ~= nil then
		local v218_ = self.components[v217_]
		if v218_ ~= nil then
			spec.steeringAxleReferenceComponentNode = v218_.node
		end
	end
end

function Attachable:getIsSteeringAxleAllowed()
	return true
end

function Attachable:loadSteeringAngleNodeFromXML(entry, xmlFile, key)
	entry.node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	entry.speed = xmlFile:getValue(key .. "#speed", 25) / 1000
	entry.scale = xmlFile:getValue(key .. "#scale", 1)
	entry.offset = xmlFile:getValue(key .. "#offset", 0)
	entry.minSpeed = xmlFile:getValue(key .. "#minSpeed", 0)
	entry.currentAngle = 0
	return true
end

-- Local values: direction, limit, newAngle
function Attachable:updateSteeringAngleNode(steeringAngleNode, angle, dt)
	if self.lastSpeed * 3600 > steeringAngleNode.minSpeed then
		local v227_ = angle - steeringAngleNode.currentAngle
		local v228_ = math.sign(v227_)
		local v229_ = (v228_ < 0 and math.max or math.min)(steeringAngleNode.currentAngle + steeringAngleNode.speed * dt * v228_, angle)
		if v229_ ~= steeringAngleNode.currentAngle then
			steeringAngleNode.currentAngle = v229_
			setRotation(steeringAngleNode.node, 0, steeringAngleNode.offset + steeringAngleNode.currentAngle * steeringAngleNode.scale, 0)
			if self.setMovingToolDirty ~= nil then
				self:setMovingToolDirty(steeringAngleNode.node)
			end
		end
	end
end

-- Local values: spec, rootAttacherVehicle
function Attachable:attachableAddToolCameras()
	local v231_ = self.spec_attachable
	if #v231_.toolCameras > 0 then
		local v232_ = self.rootVehicle
		if v232_ ~= nil and v232_.addToolCameras ~= nil then
			v232_:addToolCameras(v231_.toolCameras)
		end
	end
end

-- Local values: spec, rootAttacherVehicle
function Attachable:attachableRemoveToolCameras()
	local v234_ = self.spec_attachable
	if #v234_.toolCameras > 0 then
		local v235_ = self.rootVehicle
		if v235_ ~= nil and v235_.removeToolCameras ~= nil then
			v235_:removeToolCameras(v234_.toolCameras)
		end
	end
end

-- Local values: spec, attacherVehicleJointDesc, distanceToGroundByVehicle, useDefault, i, vehicleData, _, additionalObject, isAllowed, _, supportAnimation, skipAnimation
function Attachable:preAttach(attacherVehicle, inputJointDescIndex, jointDescIndex, loadFromSavegame)
	local v241_ = self.spec_attachable
	v241_.attacherVehicle = attacherVehicle
	v241_.attacherJoint = v241_.inputAttacherJoints[inputJointDescIndex]
	v241_.inputAttacherJointDescIndex = inputJointDescIndex
	local v242_ = attacherVehicle:getAttacherJointByJointDescIndex(jointDescIndex)
	local v243_ = v241_.attacherJoint.distanceToGroundByVehicle
	if #v241_.attacherJoint.distanceToGroundByVehicle > 0 then
		local v244_ = true
		for v245_ = 1, #v243_ do
			local v246_ = v243_[v245_]
			if string.lower(attacherVehicle.configFileName):endsWith(v246_.filename) then
				v241_.attacherJoint.lowerDistanceToGround = v246_.lower
				v241_.attacherJoint.upperDistanceToGround = v246_.upper
				v244_ = false
			end
		end
		if v244_ then
			v241_.attacherJoint.lowerDistanceToGround = v241_.attacherJoint.lowerDistanceToGroundOriginal
			v241_.attacherJoint.upperDistanceToGround = v241_.attacherJoint.upperDistanceToGroundOriginal
		end
	end
	for _, v247_ in ipairs(v241_.attacherJoint.additionalObjects) do
		setVisibility(v247_.node, v247_.attacherVehiclePath == NetworkUtil.convertToNetworkFilename(attacherVehicle.configFileName))
	end
	if v241_.attacherJoint.bottomArm ~= nil and v241_.attacherJoint.bottomArm.ballsNode ~= nil then
		local v248_ = v242_.bottomArm == nil and true or v242_.bottomArm.ballVisibility
		setVisibility(v241_.attacherJoint.bottomArm.ballsNode, v248_)
	end
	for _, v249_ in ipairs(v241_.supportAnimations) do
		if self:getIsSupportAnimationAllowed(v249_) and not v249_.delayedOnAttach then
			local v250_ = self.propertyState == VehiclePropertyState.SHOP_CONFIG and true or loadFromSavegame
			self:playAnimation(v249_.animationName, -1, nil, true, not v250_)
			if v250_ then
				AnimatedVehicle.updateAnimationByName(self, v249_.animationName, 9999999, true)
			end
		end
	end
	SpecializationUtil.raiseEvent(self, "onPreAttach", attacherVehicle, inputJointDescIndex, jointDescIndex)
end

-- Local values: spec, rootVehicle, lightsSpecAttacherVehicle, _, supportAnimation, skipAnimation, jointDesc, actionController, inputJointDesc
function Attachable:postAttach(attacherVehicle, inputJointDescIndex, jointDescIndex, loadFromSavegame)
	local v256_ = self.spec_attachable
	local v257_ = self.rootVehicle
	if v257_ ~= nil and (v257_.getIsControlled ~= nil and v257_:getIsControlled()) then
		self:activate()
	end
	if self.setLightsTypesMask ~= nil then
		local v258_ = attacherVehicle.spec_lights
		if v258_ ~= nil then
			self:setLightsTypesMask(v258_.lightsTypesMask, true, true)
			self:setBeaconLightsVisibility(v258_.beaconLightsActive, true, true)
			self:setTurnLightState(v258_.turnLightState, true, true)
		end
	end
	v256_.attachTime = g_currentMission.time
	for _, v259_ in ipairs(v256_.supportAnimations) do
		if self:getIsSupportAnimationAllowed(v259_) and v259_.delayedOnAttach then
			local v260_ = self.propertyState == VehiclePropertyState.SHOP_CONFIG and true or loadFromSavegame
			self:playAnimation(v259_.animationName, -1, nil, true, not v260_)
			if v260_ then
				AnimatedVehicle.updateAnimationByName(self, v259_.animationName, 9999999, true)
			end
		end
	end
	self:attachableAddToolCameras()
	ObjectChangeUtil.setObjectChanges(v256_.attacherJoint.changeObjects, true, self, self.setMovingToolDirty)
	local v_u_261_ = attacherVehicle:getAttacherJointByJointDescIndex(jointDescIndex)
	if v256_.attacherJoint.steeringBarLeftNode ~= nil and v_u_261_.steeringBarLeftNode ~= nil then
		self:setMovingPartReferenceNode(v256_.attacherJoint.steeringBarLeftNode, v_u_261_.steeringBarLeftNode, false)
	end
	if v256_.attacherJoint.steeringBarRightNode ~= nil and v_u_261_.steeringBarRightNode ~= nil then
		self:setMovingPartReferenceNode(v256_.attacherJoint.steeringBarRightNode, v_u_261_.steeringBarRightNode, false)
	end
	if v256_.attacherJoint.drawbarNode ~= nil then
		self:setMovingPartReferenceNode(v256_.attacherJoint.drawbarNode, v_u_261_.jointTransform, false)
	end
	local v262_ = self.rootVehicle.actionController
	if v262_ ~= nil then
		local v263_ = self:getActiveInputAttacherJoint()
		if v263_ ~= nil and (v263_.needsLowering and (v263_.allowsLowering and (v_u_261_.allowsLowering and (v263_.lowerDistanceToGround ~= v263_.upperDistanceToGround or v256_.lowerAnimation ~= nil)))) then
			v256_.controlledAction = v262_:registerAction("lower", InputAction.LOWER_IMPLEMENT, 2)
			v256_.controlledAction:setCallback(self, Attachable.actionControllerLowerImplementEvent)
			v256_.controlledAction:setFinishedFunctions(self, function()
				-- upvalues: (copy) v_u_261_
				return v_u_261_.moveDown
			end, true, false)
			v256_.controlledAction:setIsSaved(true)
			v256_.controlledAction:setIsAvailableFunction(function()
				return true
			end)
			v256_.controlledAction:setIsAccessibleFunction(function()
				return true
			end)
			if self:getAINeedsLowering() then
				v256_.controlledAction:addAIEventListener(self, "onAIImplementStartLine", 1, true)
				v256_.controlledAction:addAIEventListener(self, "onAIImplementEndLine", -1)
				v256_.controlledAction:addAIEventListener(self, "onAIImplementStart", -1)
				v256_.controlledAction:addAIEventListener(self, "onAIImplementPrepareForTransport", -1)
			end
		end
	end
	SpecializationUtil.raiseEvent(self, "onPostAttach", attacherVehicle, inputJointDescIndex, jointDescIndex, loadFromSavegame)
end

-- Local values: spec
function Attachable:preDetach(attacherVehicle, implement)
	local v267_ = self.spec_attachable
	if v267_.controlledAction ~= nil then
		v267_.controlledAction:remove()
		v267_.controlledAction = nil
	end
	SpecializationUtil.raiseEvent(self, "onPreDetach", attacherVehicle, implement)
end

-- Local values: spec, _, supportAnimation, _, additionalObject
function Attachable:postDetach(implementIndex)
	local v269_ = self.spec_attachable
	self:deactivate()
	ObjectChangeUtil.setObjectChanges(v269_.attacherJoint.changeObjects, false, self, self.setMovingToolDirty)
	if v269_.attacherJoint.steeringBarLeftNode ~= nil then
		self:setMovingPartReferenceNode(v269_.attacherJoint.steeringBarLeftNode, nil, false)
	end
	if v269_.attacherJoint.steeringBarRightNode ~= nil then
		self:setMovingPartReferenceNode(v269_.attacherJoint.steeringBarRightNode, nil, false)
	end
	if v269_.attacherJoint.drawbarNode ~= nil then
		self:setMovingPartReferenceNode(v269_.attacherJoint.drawbarNode, nil, false)
	end
	if self.playAnimation ~= nil then
		for _, v270_ in ipairs(v269_.supportAnimations) do
			if self:getIsSupportAnimationAllowed(v270_) then
				if v270_.detachAfterAnimation then
					if self:getAnimationTime(v270_.animationName) < 1 then
						self:playAnimation(v270_.animationName, 1, nil, true)
					end
				else
					self:playAnimation(v270_.animationName, 1, nil, true)
				end
			end
		end
		if v269_.lowerAnimation ~= nil and v269_.lowerAnimationDirectionOnDetach ~= 0 then
			self:playAnimation(v269_.lowerAnimation, v269_.lowerAnimationDirectionOnDetach, nil, true)
		end
	end
	self:attachableRemoveToolCameras()
	for _, v271_ in ipairs(v269_.attacherJoint.additionalObjects) do
		setVisibility(v271_.node, false)
	end
	if v269_.attacherJoint.bottomArm ~= nil and v269_.attacherJoint.bottomArm.ballsNode ~= nil then
		setVisibility(v269_.attacherJoint.bottomArm.ballsNode, v269_.attacherJoint.bottomArm.ballDefaultVisibility)
	end
	v269_.attacherVehicle = nil
	v269_.attacherJoint = nil
	v269_.attacherJointIndex = nil
	v269_.inputAttacherJointDescIndex = nil
	SpecializationUtil.raiseEvent(self, "onPostDetach")
end

-- Local values: spec, animationTime, _, dependentAttacherJointIndex, attacherJoints
function Attachable:setLowered(lowered)
	local v274_ = self.spec_attachable
	if v274_.lowerAnimation ~= nil and self.playAnimation ~= nil then
		local v275_ = self:getAnimationTime(v274_.lowerAnimation)
		if lowered and v275_ < 1 then
			self:playAnimation(v274_.lowerAnimation, v274_.lowerAnimationSpeed, v275_, true)
		elseif not lowered and v275_ > 0 then
			self:playAnimation(v274_.lowerAnimation, -v274_.lowerAnimationSpeed, v275_, true)
		end
	end
	if v274_.attacherJoint ~= nil then
		for _, v276_ in pairs(v274_.attacherJoint.dependentAttacherJoints) do
			if self.getAttacherJoints == nil then
				Logging.xmlWarning(self.xmlFile, "Failed to lower dependent attacher joint index \'%d\', AttacherJoint specialization is missing!", v276_)
			elseif self:getAttacherJoints()[v276_] == nil then
				Logging.xmlWarning(self.xmlFile, "Failed to lower dependent attacher joint index \'%d\', No attacher joint defined!", v276_)
			else
				self:setJointMoveDown(v276_, lowered, true)
			end
		end
	end
	SpecializationUtil.raiseEvent(self, "onSetLowered", lowered)
end

function Attachable:setLoweredAll(doLowering, jointDescIndex)
	self:getAttacherVehicle():handleLowerImplementByAttacherJointIndex(jointDescIndex, doLowering)
	SpecializationUtil.raiseEvent(self, "onSetLoweredAll", doLowering, jointDescIndex)
end

-- Local values: inputAttacherJoint, width, nearestCategory, ballSize
function Attachable:setToolBottomArmWidthByIndex(inputAttacherJointIndex, widthIndex)
	local v283_ = self:getInputAttacherJointByJointDescIndex(inputAttacherJointIndex)
	if v283_ ~= nil and (v283_.bottomArm ~= nil and v283_.bottomArm.ballsNodeLeft ~= nil) then
		local v284_ = v283_.bottomArm.widths[widthIndex] or 0.5
		setTranslation(v283_.bottomArm.ballsNodeLeft, v284_ * 0.5, 0, 0)
		setTranslation(v283_.bottomArm.ballsNodeRight, -v284_ * 0.5, 0, 0)
		local v285_ = AttacherJoints.getClosestLowerLinkCategoryIndex(v284_)
		local _ = AttacherJoints.LOWER_LINK_BALL_SIZE_BY_CATEGORY[v285_] or 0.056
	end
end

-- Local values: attacherJoint, inputAttacherJoint
function Attachable:updateInputAttacherJointGraphics(implement, dt)
	if not implement.attachingIsInProgress then
		local v289_ = self:getAttacherVehicle():getAttacherJointByJointDescIndex(implement.jointDescIndex)
		local v290_ = self:getInputAttacherJointByJointDescIndex(implement.inputJointDescIndex)
		if v290_ ~= nil then
			if v290_.steeringBarLeftNode ~= nil and v289_.steeringBarLeftNode ~= nil then
				self:updateMovingPartByNode(v290_.steeringBarLeftNode, dt)
			end
			if v290_.steeringBarRightNode ~= nil and v289_.steeringBarRightNode ~= nil then
				self:updateMovingPartByNode(v290_.steeringBarRightNode, dt)
			end
			if v290_.drawbarNode ~= nil then
				self:updateMovingPartByNode(v290_.drawbarNode, dt)
			end
		end
	end
end

-- Local values: spec
function Attachable:setIsAdditionalAttachment(needsLowering, vehicleLoaded)
	local v294_ = self.spec_attachable
	v294_.isAdditionalAttachment = true
	v294_.additionalAttachmentNeedsLowering = needsLowering
	if vehicleLoaded then
		self:requestActionEventUpdate()
		if not needsLowering and v294_.controlledAction ~= nil then
			v294_.controlledAction:remove()
		end
	end
end

function Attachable:getIsAdditionalAttachment()
	return self.spec_attachable.isAdditionalAttachment
end

-- Local values: spec
function Attachable:setIsSupportVehicle(state)
	self.spec_attachable.isSupportVehicle = state == nil and true or state
end

function Attachable:getIsSupportVehicle()
	return self.spec_attachable.isSupportVehicle
end

function Attachable:registerLoweringActionEvent(actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName)
	return self:addPoweredActionEvent(actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName)
end

-- Local values: showLower, attacherVehicle, jointDesc, inputJointDesc, spec, text
function Attachable:getLoweringActionEventState()
	local v311_ = self:getAttacherVehicle()
	local v312_
	if v311_ == nil then
		v312_ = false
	else
		local v313_ = v311_:getAttacherJointDescFromObject(self)
		local v314_ = self:getActiveInputAttacherJoint()
		v312_ = v313_.allowsLowering
		if v312_ then
			v312_ = v314_.allowsLowering
		end
	end
	local v315_ = self.spec_attachable
	local v316_
	if self:getIsLowered() then
		v316_ = string.format(v315_.texts.liftObject, self.typeDesc)
	else
		v316_ = string.format(v315_.texts.lowerObject, self.typeDesc)
	end
	return v312_, v316_
end

function Attachable:getAllowMultipleAttachments()
	return false
end

function Attachable:resolveMultipleAttachments() end

function Attachable:getBlockFoliageDestruction()
	return self.spec_attachable.blockFoliageDestruction
end

function Attachable:setIsDetachingBlocked(isBlocked)
	self.spec_attachable.isDetachingBlocked = isBlocked
end

-- Local values: brakeForce, spec
function Attachable:onDeactivate()
	if self.brake ~= nil then
		local v321_ = self:getBrakeForce()
		if v321_ > 0 then
			self:brake(v321_, true)
		end
	end
	if self.isClient then
		local v322_ = self.spec_attachable
		if v322_.isActiveSamplePlaying then
			g_soundManager:stopSamples(v322_.samples.active)
			v322_.isActiveSamplePlaying = false
		end
	end
end

-- Local values: attacherVehicle
function Attachable:onSelect(subSelectionIndex)
	local v324_ = self:getAttacherVehicle()
	if v324_ ~= nil then
		v324_:setSelectedImplementByObject(self)
	end
end

-- Local values: attacherVehicle
function Attachable:onUnselect()
	local v326_ = self:getAttacherVehicle()
	if v326_ ~= nil then
		v326_:setSelectedImplementByObject(nil)
	end
end

-- Local values: spec
function Attachable:findRootVehicle(superFunc)
	local v329_ = self.spec_attachable
	if v329_.attacherVehicle == nil then
		return superFunc(self)
	else
		return v329_.attacherVehicle:findRootVehicle()
	end
end

-- Local values: spec
function Attachable:getIsActive(superFunc)
	if superFunc(self) then
		return true
	else
		local v332_ = self.spec_attachable
		if v332_.attacherVehicle == nil then
			return false
		else
			return v332_.attacherVehicle:getIsActive()
		end
	end
end

-- Local values: spec, isOperating
function Attachable:getIsOperating(superFunc)
	local v335_ = self.spec_attachable
	local v336_ = superFunc(self)
	if not v336_ and v335_.attacherVehicle ~= nil then
		v336_ = v335_.attacherVehicle:getIsOperating()
	end
	return v336_
end

-- Local values: superBrakeForce, spec, brakeForce, mass, percentage
function Attachable:getBrakeForce(superFunc)
	local v339_ = superFunc(self)
	local v340_ = self.spec_attachable
	local v341_ = v340_.brakeForce
	if v340_.maxBrakeForceMass > 0 then
		local v342_ = (self:getTotalMass(not v340_.maxBrakeForceMassIncludeAttachables) - self.defaultMass) / (v340_.maxBrakeForceMass - self.defaultMass)
		local v343_ = math.max(v342_, 0)
		local v344_ = math.min(v343_, 1)
		v341_ = MathUtil.lerp(v340_.brakeForce, v340_.maxBrakeForce, v344_)
	end
	if v340_.loweredBrakeForce >= 0 and self:getIsLowered(false) then
		v341_ = v340_.loweredBrakeForce
	end
	return math.max(v339_, v341_)
end

-- Local values: spec
function Attachable:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	local v349_ = self.spec_attachable
	if v349_.allowFoldingWhileAttached or self:getAttacherVehicle() == nil then
		if v349_.allowFoldingWhileLowered or not self:getIsLowered() then
			if v349_.attacherJoint == nil or v349_.attacherJoint.allowFolding then
				return superFunc(self, direction, onAiTurnOn)
			else
				return false, v349_.texts.warningFoldingAttacherJoint
			end
		else
			return false, v349_.texts.warningFoldingLowered
		end
	else
		return false, v349_.texts.warningFoldingAttached
	end
end

-- Local values: attacherVehicle, jointDesc, spec
function Attachable:getCanToggleTurnedOn(superFunc)
	local v352_ = self:getAttacherVehicle()
	if v352_ ~= nil then
		local v353_ = v352_:getAttacherJointDescFromObject(self)
		if v353_ ~= nil and not v353_.canTurnOnImplement then
			return false
		end
	end
	local v354_ = self.spec_attachable
	if v354_.attacherJoint == nil or v354_.attacherJoint.allowTurnOn then
		return superFunc(self)
	else
		return false
	end
end

-- Local values: spec
function Attachable:getCanImplementBeUsedForAI(superFunc)
	local v357_ = self.spec_attachable
	if v357_.attacherJoint == nil or v357_.attacherJoint.allowAI then
		if v357_.detachingInProgress then
			return false
		else
			return superFunc(self)
		end
	else
		return false
	end
end

-- Local values: attacherVehicle
function Attachable:getDeactivateOnLeave(superFunc)
	local v360_ = self:getAttacherVehicle()
	if v360_ == nil or v360_:getDeactivateOnLeave() then
		return superFunc(self)
	else
		return false
	end
end

-- Local values: canContinue, stopAI, stopReason, spec, isReady, time, jointDesc
function Attachable:getCanAIImplementContinueWork(superFunc, isTurning)
	local v364_, v365_, v366_ = superFunc(self, isTurning)
	if not v364_ then
		return false, v365_, v366_
	end
	local v367_ = self.spec_attachable
	local v368_
	if v367_.lowerAnimation == nil then
		v368_ = true
	else
		local v369_ = self:getAnimationTime(v367_.lowerAnimation)
		v368_ = v369_ ~= 1 and v369_ ~= 0 and self:getIsAnimationPlaying(v367_.lowerAnimation)
		if v368_ then
			v368_ = self:getAnimationSpeed(v367_.lowerAnimation) < 0
		end
	end
	if v367_.attacherVehicle ~= nil then
		local v370_ = v367_.attacherVehicle:getAttacherJointDescFromObject(self)
		if v370_.allowsLowering and (self:getAINeedsLowering() and v370_.moveDown) then
			if v370_.moveAlpha ~= v370_.lowerAlpha and v370_.moveAlpha ~= v370_.upperAlpha then
				v368_ = false
			end
		end
	end
	return v368_
end

-- Local values: spec, i
function Attachable:getAreControlledActionsAllowed(superFunc)
	local v373_ = self.spec_attachable
	for v374_ = 1, #v373_.supportAnimations do
		if self:getIsAnimationPlaying(v373_.supportAnimations[v374_].animationName) then
			return false
		end
	end
	return superFunc(self)
end

-- Local values: spec
function Attachable:getActiveFarm(superFunc)
	local v377_ = self.spec_attachable
	if self.spec_enterable == nil or self.spec_enterable.controllerFarmId == 0 then
		if v377_.attacherVehicle == nil then
			return superFunc(self)
		else
			return v377_.attacherVehicle:getActiveFarm()
		end
	else
		return superFunc(self)
	end
end

function Attachable:getCanBeSelected(superFunc)
	return true
end

-- Local values: attacherVehicle, jointDesc
function Attachable:getIsLowered(superFunc, defaultIsLowered)
	local v381_ = self:getAttacherVehicle()
	if v381_ ~= nil then
		local v382_ = v381_:getAttacherJointDescFromObject(self)
		if v382_ ~= nil then
			if v382_.allowsLowering or v382_.isDefaultLowered then
				return v382_.moveDown
			else
				return defaultIsLowered
			end
		end
	end
	return superFunc(self, defaultIsLowered)
end

-- Local values: spec
function Attachable:mountDynamic(superFunc, object, objectActorId, jointNode, mountType, forceAcceleration)
	if self.spec_attachable.attacherVehicle == nil then
		return superFunc(self, object, objectActorId, jointNode, mountType, forceAcceleration)
	else
		return false
	end
end

-- Local values: spec
function Attachable:getOwnerConnection(superFunc)
	local v392_ = self.spec_attachable
	if v392_.attacherVehicle == nil then
		return superFunc(self)
	else
		return v392_.attacherVehicle:getOwnerConnection()
	end
end

-- Local values: attacherVehicle
function Attachable:getIsInUse(superFunc, connection)
	local v396_ = self:getAttacherVehicle()
	if v396_ == nil then
		return superFunc(self, connection)
	else
		return v396_:getIsInUse(connection)
	end
end

-- Local values: attacherVehicle
function Attachable:getUpdatePriority(superFunc, skipCount, x, y, z, coeff, connection, isGuiVisible)
	local v406_ = self:getAttacherVehicle()
	if v406_ == nil then
		return superFunc(self, skipCount, x, y, z, coeff, connection)
	else
		return v406_:getUpdatePriority(skipCount, x, y, z, coeff, connection, isGuiVisible)
	end
end

function Attachable:getCanBeReset(superFunc)
	if self:getIsAdditionalAttachment() then
		return false
	elseif self:getIsSupportVehicle() then
		return false
	else
		return superFunc(self)
	end
end

function Attachable:loadAdditionalLightAttributesFromXML(superFunc, xmlFile, key, light)
	if not superFunc(self, xmlFile, key, light) then
		return false
	end
	light.superFuncIndex = xmlFile:getValue(key .. "#superFuncIndex")
	return true
end

function Attachable:getIsLightActive(superFunc, light)
	if light.superFuncIndex == nil or light.superFuncIndex == self:getActiveInputAttacherJointDescIndex() then
		return superFunc(self, light)
	else
		return false
	end
end

-- Local values: attacherVehicle, isPowered, warning, spec
function Attachable:getIsPowered(superFunc)
	local v419_ = self:getAttacherVehicle()
	if v419_ == nil then
		local v420_ = self.spec_attachable
		if v420_.requiresExternalPower and not SpecializationUtil.hasSpecialization(Motorized, self.self) then
			return false, v420_.attachToPowerWarning
		end
	else
		local v421_, v422_ = v419_:getIsPowered()
		if not v421_ then
			return v421_, v422_
		end
	end
	return superFunc(self)
end

-- Local values: index, configKey
function Attachable:getConnectionHoseConfigIndex(superFunc)
	local v425_ = superFunc(self)
	local v426_ = self.xmlFile:getValue("vehicle.attachable#connectionHoseConfigId", v425_)
	if self.configurations.superFunc ~= nil then
		local v427_ = string.format("vehicle.attachable.superFuncConfigurations.superFuncConfiguration(%d)", self.configurations.superFunc - 1)
		v426_ = self.xmlFile:getValue(v427_ .. "#connectionHoseConfigId", v426_)
	end
	return v426_
end

function Attachable:getIsMapHotspotVisible(superFunc)
	if superFunc(self) then
		if self:getIsAdditionalAttachment() then
			return false
		elseif self:getIsSupportVehicle() then
			return false
		else
			return self:getShowAttachableMapHotspot()
		end
	else
		return false
	end
end

-- Local values: index, configKey
function Attachable:getPowerTakeOffConfigIndex(superFunc)
	local v432_ = superFunc(self)
	local v433_ = self.xmlFile:getValue("vehicle.attachable#powerTakeOffConfigId", v432_)
	if self.configurations.superFunc ~= nil then
		local v434_ = string.format("vehicle.attachable.superFuncConfigurations.superFuncConfiguration(%d)", self.configurations.superFunc - 1)
		v433_ = self.xmlFile:getValue(v434_ .. "#powerTakeOffConfigId", v433_)
	end
	return v433_
end

function Attachable:loadDashboardGroupFromXML(superFunc, xmlFile, key, group)
	if not superFunc(self, xmlFile, key, group) then
		return false
	end
	group.isAttached = xmlFile:getValue(key .. "#isAttached")
	return true
end

function Attachable:getIsDashboardGroupActive(superFunc, group)
	if group.isAttached == nil or group.isAttached == (self:getAttacherVehicle() ~= nil) then
		return superFunc(self, group)
	else
		return false
	end
end

function Attachable:setWorldPositionQuaternion(superFunc, x, y, z, qx, qy, qz, qw, i, changeInterp)
	if self.isServer then
		return superFunc(self, x, y, z, qx, qy, qz, qw, i, changeInterp)
	end
	if not self.spec_attachable.isHardAttached then
		return superFunc(self, x, y, z, qx, qy, qz, qw, i, changeInterp)
	end
end

-- Local values: spec, attacherVehicle, implement
function Attachable:addToPhysics(superFunc)
	if not superFunc(self) then
		return false
	end
	local v456_ = self.spec_attachable
	local v457_ = self:getAttacherVehicle()
	if v457_ ~= nil then
		if v457_.isAddedToPhysics then
			local v458_ = v457_:getImplementByObject(self)
			if v458_ ~= nil and not v456_.isHardAttached then
				v457_:createAttachmentJoint(v458_, true)
			end
		elseif v456_.isHardAttached then
			self.isAddedToPhysics = false
			if self.isServer then
				removeWakeUpReport(self.rootNode)
			end
		end
	end
	return true
end

-- Local values: spec, attacherVehicle, implement, jointDesc
function Attachable:removeFromPhysics(superFunc)
	local v461_ = self.spec_attachable
	local v462_ = self:getAttacherVehicle()
	if v462_ ~= nil and v462_.isAddedToPhysics then
		local v463_ = v462_:getImplementByObject(self)
		if v463_ ~= nil and not v461_.isHardAttached then
			local v464_ = v462_.spec_attacherJoints.attacherJoints[v463_.jointDescIndex]
			if v464_.jointIndex ~= 0 then
				v464_.jointIndex = 0
			end
		end
	end
	return superFunc(self)
end

-- Local values: spec, moveDown, jointDescIndex
function Attachable:actionControllerLowerImplementEvent(direction)
	local v467_ = self.spec_attachable
	if not self:getAllowsLowering() then
		return false
	end
	local v468_ = direction >= 0
	local v469_ = v467_.attacherVehicle:getAttacherJointIndexFromObject(self)
	if v467_.attacherVehicle:getJointMoveDown(v469_) ~= v468_ then
		v467_.attacherVehicle:setJointMoveDown(v469_, v468_, false)
	end
	return true
end

function Attachable:onStateChange(state, data)
	if self.getAILowerIfAnyIsLowered ~= nil and self:getAILowerIfAnyIsLowered() then
		if state == VehicleStateChange.AI_START_LINE then
			Attachable.actionControllerLowerImplementEvent(self, 1)
			return
		end
		if state == VehicleStateChange.AI_END_LINE then
			Attachable.actionControllerLowerImplementEvent(self, -1)
		end
	end
end

-- Local values: spec, actionController
function Attachable:onRootVehicleChanged(rootVehicle)
	local v474_ = self.spec_attachable
	local v475_ = rootVehicle.actionController
	if v475_ ~= nil and v474_.controlledAction ~= nil then
		v474_.controlledAction:updateParent(v475_)
	end
end

-- Local values: spec
function Attachable:onFoldStateChanged(direction, moveToMiddle)
	local v479_ = self.spec_foldable
	if v479_.foldMiddleAnimTime ~= nil then
		if not moveToMiddle and direction == v479_.turnOnFoldDirection then
			SpecializationUtil.raiseEvent(self, "onSetLowered", true)
			return
		end
		SpecializationUtil.raiseEvent(self, "onSetLowered", false)
	end
end

-- Local values: loadInputAttacherJoint, resolveAttacherJoint, updateJointSettings
function Attachable:onRegisterAnimationValueTypes()
	local function v484_(p481_, p482_, p483_)
		p481_.superFuncIndex = p482_:getValue(p483_ .. "#superFuncIndex")
		if p481_.superFuncIndex == nil then
			return false
		end
		p481_:setWarningInformation("superFuncIndex: " .. p481_.superFuncIndex)
		p481_:addCompareParameters("superFuncIndex")
		return true
	end
	local function v_u_486_(...)
		-- upvalues: (copy) self
		if self.isServer then
			local v485_ = self:getAttacherVehicle()
			if v485_ ~= nil then
				v485_:updateAttacherJointSettingsByObject(self, ...)
			end
		end
	end
	self:registerAnimationValueType("lowerRotLimitScale", "lowerRotLimitScaleStart", "lowerRotLimitScaleEnd", false, AnimationValueFloat, v484_, function(p487_)
		-- upvalues: (copy) self
		if p487_.superFuncIndex ~= nil and p487_.superFunc == nil then
			p487_.superFunc = self:getInputAttacherJointByJointDescIndex(p487_.superFuncIndex)
			if p487_.superFunc == nil then
				Logging.xmlWarning(self.xmlFile, "Unknown superFuncIndex \'%s\' for animation part.", p487_.superFuncIndex)
				p487_.superFuncIndex = nil
			end
		end
		if p487_.superFunc == nil then
			return 0, 0, 0
		end
		local v488_ = p487_.superFunc.lowerRotLimitScale
		return unpack(v488_)
	end, function(p489_, p490_, p491_, p492_)
		-- upvalues: (copy) v_u_486_
		if p489_.superFunc ~= nil then
			p489_.superFunc.lowerRotLimitScale[1] = p490_
			p489_.superFunc.lowerRotLimitScale[2] = p491_
			p489_.superFunc.lowerRotLimitScale[3] = p492_
			v_u_486_(true)
		end
	end)
	self:registerAnimationValueType("upperRotLimitScale", "upperRotLimitScaleStart", "upperRotLimitScaleEnd", false, AnimationValueFloat, v484_, function(p493_)
		-- upvalues: (copy) self
		if p493_.superFuncIndex ~= nil and p493_.superFunc == nil then
			p493_.superFunc = self:getInputAttacherJointByJointDescIndex(p493_.superFuncIndex)
			if p493_.superFunc == nil then
				Logging.xmlWarning(self.xmlFile, "Unknown superFuncIndex \'%s\' for animation part.", p493_.superFuncIndex)
				p493_.superFuncIndex = nil
			end
		end
		if p493_.superFunc == nil then
			return 0, 0, 0
		end
		local v494_ = p493_.superFunc.upperRotLimitScale
		return unpack(v494_)
	end, function(p495_, p496_, p497_, p498_)
		-- upvalues: (copy) v_u_486_
		if p495_.superFunc ~= nil then
			p495_.superFunc.upperRotLimitScale[1] = p496_
			p495_.superFunc.upperRotLimitScale[2] = p497_
			p495_.superFunc.upperRotLimitScale[3] = p498_
			v_u_486_(true)
		end
	end)
	self:registerAnimationValueType("lowerTransLimitScale", "lowerTransLimitScaleStart", "lowerTransLimitScaleEnd", false, AnimationValueFloat, v484_, function(p499_)
		-- upvalues: (copy) self
		if p499_.superFuncIndex ~= nil and p499_.superFunc == nil then
			p499_.superFunc = self:getInputAttacherJointByJointDescIndex(p499_.superFuncIndex)
			if p499_.superFunc == nil then
				Logging.xmlWarning(self.xmlFile, "Unknown superFuncIndex \'%s\' for animation part.", p499_.superFuncIndex)
				p499_.superFuncIndex = nil
			end
		end
		if p499_.superFunc == nil then
			return 0, 0, 0
		end
		local v500_ = p499_.superFunc.lowerTransLimitScale
		return unpack(v500_)
	end, function(p501_, p502_, p503_, p504_)
		-- upvalues: (copy) v_u_486_
		if p501_.superFunc ~= nil then
			p501_.superFunc.lowerTransLimitScale[1] = p502_
			p501_.superFunc.lowerTransLimitScale[2] = p503_
			p501_.superFunc.lowerTransLimitScale[3] = p504_
			v_u_486_(true)
		end
	end)
	self:registerAnimationValueType("upperTransLimitScale", "upperTransLimitScaleStart", "upperTransLimitScaleEnd", false, AnimationValueFloat, v484_, function(p505_)
		-- upvalues: (copy) self
		if p505_.superFuncIndex ~= nil and p505_.superFunc == nil then
			p505_.superFunc = self:getInputAttacherJointByJointDescIndex(p505_.superFuncIndex)
			if p505_.superFunc == nil then
				Logging.xmlWarning(self.xmlFile, "Unknown superFuncIndex \'%s\' for animation part.", p505_.superFuncIndex)
				p505_.superFuncIndex = nil
			end
		end
		if p505_.superFunc == nil then
			return 0, 0, 0
		end
		local v506_ = p505_.superFunc.upperTransLimitScale
		return unpack(v506_)
	end, function(p507_, p508_, p509_, p510_)
		-- upvalues: (copy) v_u_486_
		if p507_.superFunc ~= nil then
			p507_.superFunc.upperTransLimitScale[1] = p508_
			p507_.superFunc.upperTransLimitScale[2] = p509_
			p507_.superFunc.upperTransLimitScale[3] = p510_
			v_u_486_(true)
		end
	end)
	self:registerAnimationValueType("lowerRotationOffset", "lowerRotationOffsetStart", "lowerRotationOffsetEnd", false, AnimationValueFloat, v484_, function(p511_)
		-- upvalues: (copy) self
		if p511_.superFuncIndex ~= nil and p511_.superFunc == nil then
			p511_.superFunc = self:getInputAttacherJointByJointDescIndex(p511_.superFuncIndex)
			if p511_.superFunc == nil then
				Logging.xmlWarning(self.xmlFile, "Unknown superFuncIndex \'%s\' for animation part.", p511_.superFuncIndex)
				p511_.superFuncIndex = nil
			end
		end
		return p511_.superFunc == nil and 0 or p511_.superFunc.lowerRotationOffset
	end, function(p512_, p513_)
		-- upvalues: (copy) v_u_486_
		if p512_.superFunc ~= nil then
			p512_.superFunc.lowerRotationOffset = p513_
			v_u_486_(false, true)
		end
	end)
	self:registerAnimationValueType("upperRotationOffset", "upperRotationOffsetStart", "upperRotationOffsetEnd", false, AnimationValueFloat, v484_, function(p514_)
		-- upvalues: (copy) self
		if p514_.superFuncIndex ~= nil and p514_.superFunc == nil then
			p514_.superFunc = self:getInputAttacherJointByJointDescIndex(p514_.superFuncIndex)
			if p514_.superFunc == nil then
				Logging.xmlWarning(self.xmlFile, "Unknown superFuncIndex \'%s\' for animation part.", p514_.superFuncIndex)
				p514_.superFuncIndex = nil
			end
		end
		return p514_.superFunc == nil and 0 or p514_.superFunc.upperRotationOffset
	end, function(p515_, p516_)
		-- upvalues: (copy) v_u_486_
		if p515_.superFunc ~= nil then
			p515_.superFunc.upperRotationOffset = p516_
			v_u_486_(false, true)
		end
	end)
	self:registerAnimationValueType("lowerDistanceToGround", "lowerDistanceToGroundStart", "lowerDistanceToGroundEnd", false, AnimationValueFloat, v484_, function(p517_)
		-- upvalues: (copy) self
		if p517_.superFuncIndex ~= nil and p517_.superFunc == nil then
			p517_.superFunc = self:getInputAttacherJointByJointDescIndex(p517_.superFuncIndex)
			if p517_.superFunc == nil then
				Logging.xmlWarning(self.xmlFile, "Unknown superFuncIndex \'%s\' for animation part.", p517_.superFuncIndex)
				p517_.superFuncIndex = nil
			end
		end
		return p517_.superFunc == nil and 0 or p517_.superFunc.lowerDistanceToGround
	end, function(p518_, p519_)
		-- upvalues: (copy) v_u_486_
		if p518_.superFunc ~= nil then
			p518_.superFunc.lowerDistanceToGround = p519_
			v_u_486_(false, false, true)
		end
	end)
	self:registerAnimationValueType("upperDistanceToGround", "upperDistanceToGroundStart", "upperDistanceToGroundEnd", false, AnimationValueFloat, v484_, function(p520_)
		-- upvalues: (copy) self
		if p520_.superFuncIndex ~= nil and p520_.superFunc == nil then
			p520_.superFunc = self:getInputAttacherJointByJointDescIndex(p520_.superFuncIndex)
			if p520_.superFunc == nil then
				Logging.xmlWarning(self.xmlFile, "Unknown superFuncIndex \'%s\' for animation part.", p520_.superFuncIndex)
				p520_.superFuncIndex = nil
			end
		end
		return p520_.superFunc == nil and 0 or p520_.superFunc.upperDistanceToGround
	end, function(p521_, p522_)
		-- upvalues: (copy) v_u_486_
		if p521_.superFunc ~= nil then
			p521_.superFunc.upperDistanceToGround = p522_
			v_u_486_(false, false, true)
		end
	end)
end

-- Local values: rootNode, width
function Attachable:onBottomArmBallsI3DLoaded(i3dNode, failedReason, inputAttacherJoint)
	if i3dNode ~= 0 then
		local v525_ = getChildAt(i3dNode, 0)
		if getNumOfChildren(v525_) == 3 then
			link(inputAttacherJoint.node, v525_)
			setTranslation(v525_, 0, 0, 0)
			setRotation(v525_, 0, 1.5707963267948966, 0)
			inputAttacherJoint.bottomArm.ballsNode = v525_
			inputAttacherJoint.bottomArm.ballsNodeLeft = getChildAt(v525_, 0)
			inputAttacherJoint.bottomArm.ballsNodeRight = getChildAt(v525_, 1)
			inputAttacherJoint.bottomArm.ballsNodeTop = getChildAt(v525_, 2)
			local v526_ = inputAttacherJoint.bottomArm.widths[#inputAttacherJoint.bottomArm.widths]
			setTranslation(inputAttacherJoint.bottomArm.ballsNodeLeft, v526_ * 0.5, 0, 0)
			setTranslation(inputAttacherJoint.bottomArm.ballsNodeRight, -v526_ * 0.5, 0, 0)
			setVisibility(inputAttacherJoint.bottomArm.ballsNode, inputAttacherJoint.bottomArm.ballDefaultVisibility)
			setVisibility(inputAttacherJoint.bottomArm.ballsNodeTop, inputAttacherJoint.topReferenceNode ~= nil)
			if inputAttacherJoint.topReferenceNode ~= nil then
				link(inputAttacherJoint.topReferenceNode, inputAttacherJoint.bottomArm.ballsNodeTop)
			end
		else
			Logging.warning("Loaded balls i3d node has wrong amount of nodes. One root node with 3 (left, right, top) ball nodes is required! (%s)", inputAttacherJoint.bottomArm.ballFilename)
		end
		delete(i3dNode)
	end
end
