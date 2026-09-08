-- Local values: getAttacherJointCompatibility
AttacherJoints = {}
AttacherJoints.DEFAULT_MAX_UPDATE_DISTANCE = 50
AttacherJoints.MAX_ATTACH_DISTANCE_SQ = 0.48999999999999994
AttacherJoints.MAX_ATTACH_ANGLE = 0.34202
AttacherJoints.SMOOTH_ATTACH_TIME = 500
AttacherJoints.NUM_JOINTTYPES = 0
AttacherJoints.jointTypeNameToInt = {}
AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY = {}
AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[0] = 0.51
AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[1] = 0.718
AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[2] = 0.87
AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[3] = 1.01
AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[4] = 1.222
AttacherJoints.LOWER_LINK_BALL_SIZE_BY_CATEGORY = {}
AttacherJoints.LOWER_LINK_BALL_SIZE_BY_CATEGORY[0] = 0.035
AttacherJoints.LOWER_LINK_BALL_SIZE_BY_CATEGORY[1] = 0.044
AttacherJoints.LOWER_LINK_BALL_SIZE_BY_CATEGORY[2] = 0.056
AttacherJoints.LOWER_LINK_BALL_SIZE_BY_CATEGORY[3] = 0.064
AttacherJoints.LOWER_LINK_BALL_SIZE_BY_CATEGORY[4] = 0.085
source("dataS/scripts/vehicles/specializations/components/AttacherJointTopArm.lua")

-- Local values: minDistance, index, categoryIndex, categoryWidth, distance
function AttacherJoints.getClosestLowerLinkCategoryIndex(width)
	local v2_ = math.huge
	local v3_ = 1
	for v4_, v5_ in pairs(AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY) do
		local v6_ = width - v5_
		local v7_ = math.abs(v6_)
		if v7_ < v2_ then
			v3_ = v4_
			v2_ = v7_
		end
	end
	return v3_
end
function AttacherJoints.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("attacherJoint", g_i18n:getText("configuration_attacherJoint"), "attacherJoints", VehicleConfigurationItem)
	local v8_ = Vehicle.xmlSchema
	v8_:setXMLSpecializationType("AttacherJoints")
	AttacherJoints.registerAttacherJointXMLPaths(v8_, "vehicle.attacherJoints")
	SoundManager.registerSampleXMLPaths(v8_, "vehicle.attacherJoints.sounds", "hydraulic")
	SoundManager.registerSampleXMLPaths(v8_, "vehicle.attacherJoints.sounds", "attach")
	SoundManager.registerSampleXMLPaths(v8_, "vehicle.attacherJoints.sounds", "detach")
	v8_:register(XMLValueType.FLOAT, "vehicle.attacherJoints#comboDuration", "Combo duration", 2)
	v8_:register(XMLValueType.INT, "vehicle.attacherJoints#connectionHoseConfigId", "Connection hose configuration index to use")
	v8_:register(XMLValueType.INT, "vehicle.attacherJoints#powerTakeOffConfigId", "Power take off configuration index to use")
	v8_:register(XMLValueType.INT, "vehicle.attacherJoints.attacherJointConfigurations.attacherJointConfiguration(?)#connectionHoseConfigId", "Connection hose configuration index to use")
	v8_:register(XMLValueType.INT, "vehicle.attacherJoints.attacherJointConfigurations.attacherJointConfiguration(?)#powerTakeOffConfigId", "Power take off configuration index to use")
	v8_:register(XMLValueType.FLOAT, "vehicle.attacherJoints#maxUpdateDistance", "Max. distance to vehicle root to update attacher joint graphics", AttacherJoints.DEFAULT_MAX_UPDATE_DISTANCE)
	v8_:register(XMLValueType.VECTOR_N, Dashboard.GROUP_XML_KEY .. "#attacherJointIndices", "Group is only active if something is attached to those joints (List if indices of the attacher joint in xml)")
	v8_:register(XMLValueType.NODE_INDICES, Dashboard.GROUP_XML_KEY .. "#attacherJointNodes", "Group is only active if something is attached to those joints (List of attacherJoint nodes)")
	v8_:register(XMLValueType.VECTOR_N, Attachable.INPUT_ATTACHERJOINT_XML_KEY .. ".heightNode(?)#disablingAttacherJointIndices", "Attacher joint indices that disable height node if something is attached")
	v8_:register(XMLValueType.VECTOR_N, Attachable.INPUT_ATTACHERJOINT_CONFIG_XML_KEY .. ".heightNode(?)#disablingAttacherJointIndices", "Attacher joint indices that disable height node if something is attached")
	v8_:register(XMLValueType.NODE_INDICES, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?)#disablingAttacherJointNodes", "Attacher joint nodes that disable the tip side if something is attached")
	v8_:register(XMLValueType.NODE_INDICES, FillUnit.FILL_UNIT_XML_KEY .. "#disablingAttacherJointNodes", "Attacher joint nodes that disable the filling if something is attached")
	v8_:addDelayedRegistrationFunc("ConnectionHoses:targetNode", function(p9_, p10_)
		p9_:register(XMLValueType.NODE_INDICES, p10_ .. "#blockedByAttacherJointNodes", "List of attacher joints that block the usage of this hose target node")
	end)
	Dashboard.addDelayedRegistrationFunc(v8_, function(p11_, p12_)
		p11_:register(XMLValueType.NODE_INDEX, p12_ .. "#attacherJointNode", "Node of the attacher joint to use")
		p11_:register(XMLValueType.NODE_INDICES, p12_ .. "#attacherJointNodes", "List of attacher joint indices to use (first active one is used)")
	end)
	Dashboard.registerDashboardXMLPaths(v8_, "vehicle.attacherJoints.dashboards", { "bottomArmPosition", "bottomArmPositionMin", "bottomArmPositionMax" })
	v8_:setXMLSpecializationType()
	local v13_ = Vehicle.xmlSchemaSavegame
	v13_:register(XMLValueType.INT, "vehicles.vehicle(?).attacherJoints#comboDirection", "Current combo direction")
	v13_:register(XMLValueType.INT, "vehicles.vehicle(?).attacherJoints.attachedImplement(?)#jointIndex", "Index of attacherJoint")
	v13_:register(XMLValueType.BOOL, "vehicles.vehicle(?).attacherJoints.attachedImplement(?)#moveDown", "Attacher joint is lowered or not")
	v13_:register(XMLValueType.STRING, "vehicles.vehicle(?).attacherJoints.attachedImplement(?)#attachedVehicleUniqueId", "Unique id of attached vehicle")
	v13_:register(XMLValueType.INT, "vehicles.vehicle(?).attacherJoints.attachedImplement(?)#inputJointIndex", "Index of input attacher joint on the attached vehicle")
	v13_:register(XMLValueType.INT, "vehicles.vehicle(?).attacherJoints.attacherJoint(?)#jointIndex", "Index of attacherJoint")
	v13_:register(XMLValueType.BOOL, "vehicles.vehicle(?).attacherJoints.attacherJoint(?)#isBlocked", "Attacher joint is blocked or not")
	v13_:register(XMLValueType.INT, "vehicles.attachments(?)#rootVehicleId", "Root vehicle id")
	v13_:register(XMLValueType.INT, "vehicles.attachments(?).attachment(?)#attachmentId", "Attachment vehicle id")
	v13_:register(XMLValueType.INT, "vehicles.attachments(?).attachment(?)#inputJointDescIndex", "Index of input attacher joint", 1)
	v13_:register(XMLValueType.INT, "vehicles.attachments(?).attachment(?)#jointIndex", "Index of attacher joint")
	v13_:register(XMLValueType.BOOL, "vehicles.attachments(?).attachment(?)#moveDown", "Attachment lowered or lifted")
end

function AttacherJoints.registerAttacherJointXMLPaths(schema, baseName)
	schema:setXMLSharedRegistration("AttacherJoint", baseName)
	local v16_ = baseName .. ".attacherJoint(?)"
	schema:register(XMLValueType.NODE_INDEX, v16_ .. "#node", "Node")
	schema:register(XMLValueType.NODE_INDEX, v16_ .. "#nodeVisual", "Visual node")
	schema:register(XMLValueType.BOOL, v16_ .. "#supportsHardAttach", "Supports hard attach")
	schema:register(XMLValueType.STRING, v16_ .. "#jointType", "Joint type", "implement")
	schema:register(XMLValueType.STRING, v16_ .. ".subType#name", "If defined this type needs to match with the sub type in the tool")
	schema:register(XMLValueType.STRING, v16_ .. ".subType#brandRestriction", "If defined it\'s only possible to attach tools from these brands (can be multiple separated by \' \')")
	schema:register(XMLValueType.STRING, v16_ .. ".subType#vehicleRestriction", "If defined it\'s only possible to attach tools containing these strings in there xml path (can be multiple separated by \' \')")
	schema:register(XMLValueType.BOOL, v16_ .. ".subType#subTypeShowWarning", "Show warning if sub type does not match", true)
	schema:register(XMLValueType.BOOL, v16_ .. "#allowsJointLimitMovement", "Allows joint limit movement", true)
	schema:register(XMLValueType.BOOL, v16_ .. "#allowsLowering", "Allows lowering", true)
	schema:register(XMLValueType.BOOL, v16_ .. "#isDefaultLowered", "Default lowered state", false)
	schema:register(XMLValueType.BOOL, v16_ .. "#allowDetachingWhileLifted", "Allow detach while lifted", true)
	schema:register(XMLValueType.BOOL, v16_ .. "#allowFoldingWhileAttached", "Allow folding while attached", true)
	schema:register(XMLValueType.BOOL, v16_ .. "#canTurnOnImplement", "Can turn on implement", true)
	schema:register(XMLValueType.NODE_INDEX, v16_ .. ".rotationNode#node", "Rotation node")
	schema:register(XMLValueType.VECTOR_ROT, v16_ .. ".rotationNode#lowerRotation", "Lower rotation", "0 0 0")
	schema:register(XMLValueType.VECTOR_ROT, v16_ .. ".rotationNode#upperRotation", "Upper rotation", "rotation in i3d")
	schema:register(XMLValueType.VECTOR_ROT, v16_ .. ".rotationNode#startRotation", "Start rotation", "rotation in i3d")
	schema:register(XMLValueType.NODE_INDEX, v16_ .. ".rotationNode2#node", "Rotation node")
	schema:register(XMLValueType.VECTOR_ROT, v16_ .. ".rotationNode2#lowerRotation", "Lower rotation", "0 0 0")
	schema:register(XMLValueType.VECTOR_ROT, v16_ .. ".rotationNode2#upperRotation", "Upper rotation", "rotation in i3d")
	schema:register(XMLValueType.NODE_INDEX, v16_ .. ".transNode#node", "Translation node")
	schema:register(XMLValueType.FLOAT, v16_ .. ".transNode#height", "Height of visual translation node", 0.12)
	schema:register(XMLValueType.FLOAT, v16_ .. ".transNode#minY", "Min Y translation")
	schema:register(XMLValueType.FLOAT, v16_ .. ".transNode#maxY", "Max Y translation")
	schema:register(XMLValueType.NODE_INDEX, v16_ .. ".transNode.dependentBottomArm#node", "Dependent bottom arm node")
	schema:register(XMLValueType.FLOAT, v16_ .. ".transNode.dependentBottomArm#threshold", "If the trans node Y translation is below this threshold the rotation will be set", "unlimited, so rotation is always set")
	schema:register(XMLValueType.VECTOR_ROT, v16_ .. ".transNode.dependentBottomArm#rotation", "Rotation to be set when the translation node is below the threshold", "0 0 0")
	schema:register(XMLValueType.FLOAT, v16_ .. ".distanceToGround#lower", "Lower distance to ground", 0.7)
	schema:register(XMLValueType.FLOAT, v16_ .. ".distanceToGround#upper", "Upper distance to ground", 1)
	schema:register(XMLValueType.ANGLE, v16_ .. "#lowerRotationOffset", "Upper rotation offset", 0)
	schema:register(XMLValueType.ANGLE, v16_ .. "#upperRotationOffset", "Lower rotation offset", 0)
	schema:register(XMLValueType.BOOL, v16_ .. "#dynamicLowerRotLimit", "Set the lower rot limit dynamically based on the lowered state (so the attacher can freely rotate between it\'s upper and lower rotation value. E.g. for combines)", false)
	schema:register(XMLValueType.BOOL, v16_ .. "#lockDownRotLimit", "Lock down rotation limit", false)
	schema:register(XMLValueType.BOOL, v16_ .. "#lockUpRotLimit", "Lock up rotation limit", false)
	schema:register(XMLValueType.BOOL, v16_ .. "#lockDownTransLimit", "Lock down translation limit", true)
	schema:register(XMLValueType.BOOL, v16_ .. "#lockUpTransLimit", "Lock up translation limit", false)
	schema:register(XMLValueType.VECTOR_ROT, v16_ .. "#lowerRotLimit", "Lower rotation limit", "(20 20 20) for implement type, otherwise (0 0 0)")
	schema:register(XMLValueType.VECTOR_ROT, v16_ .. "#upperRotLimit", "Upper rotation limit", "Lower rot limit")
	schema:register(XMLValueType.VECTOR_3, v16_ .. "#lowerTransLimit", "Lower translation limit", "(0.5 0.5 0.5) for implement type, otherwise (0 0 0)")
	schema:register(XMLValueType.VECTOR_3, v16_ .. "#upperTransLimit", "Upper translation limit", "Lower trans limit")
	schema:register(XMLValueType.VECTOR_3, v16_ .. "#jointPositionOffset", "Joint position offset", "0 0 0")
	schema:register(XMLValueType.VECTOR_3, v16_ .. "#rotLimitSpring", "Rotation limit spring", "0 0 0")
	schema:register(XMLValueType.VECTOR_3, v16_ .. "#rotLimitDamping", "Rotation limit damping", "1 1 1")
	schema:register(XMLValueType.VECTOR_3, v16_ .. "#rotLimitForceLimit", "Rotation limit force limit", "-1 -1 -1")
	schema:register(XMLValueType.VECTOR_3, v16_ .. "#transLimitSpring", "Translation limit spring", "0 0 0")
	schema:register(XMLValueType.VECTOR_3, v16_ .. "#transLimitDamping", "Translation limit damping", "1 1 1")
	schema:register(XMLValueType.VECTOR_3, v16_ .. "#transLimitForceLimit", "Translation limit force limit", "-1 -1 -1")
	schema:register(XMLValueType.FLOAT, v16_ .. "#moveTime", "Move time", 0.5)
	schema:register(XMLValueType.VECTOR_N, v16_ .. "#disabledByAttacherJoints", "This attacher becomes unavailable after attaching something to these attacher joint indices")
	schema:register(XMLValueType.BOOL, v16_ .. "#enableCollision", "Collision between vehicle is enabled", false)
	AttacherJointTopArm.registerVehicleXMLPaths(schema, v16_ .. ".topArm")
	schema:register(XMLValueType.NODE_INDEX, v16_ .. ".bottomArm#rotationNode", "Rotation node of bottom arm")
	schema:register(XMLValueType.NODE_INDEX, v16_ .. ".bottomArm#translationNode", "Translation node of bottom arm")
	schema:register(XMLValueType.NODE_INDEX, v16_ .. ".bottomArm#referenceNode", "Reference node of bottom arm")
	schema:register(XMLValueType.VECTOR_ROT, v16_ .. ".bottomArm#startRotation", "Start rotation", "values set in i3d")
	schema:register(XMLValueType.INT, v16_ .. ".bottomArm#zScale", "Inverts bottom arm direction", 1)
	schema:register(XMLValueType.BOOL, v16_ .. ".bottomArm#lockDirection", "Lock direction", true)
	schema:register(XMLValueType.ANGLE, v16_ .. ".bottomArm#resetSpeed", "Speed of bottom arm to return to idle position (deg/sec)", 45)
	schema:register(XMLValueType.BOOL, v16_ .. ".bottomArm#updateReferenceDistance", "If \'true\', the reference distance will be updated dynamically. So it\'s possible to adjust the bottom arm length.", false)
	schema:register(XMLValueType.NODE_INDEX, v16_ .. ".bottomArm#jointPositionNode", "Node that will be equalized with the current attacher joint position of the attached implement")
	schema:register(XMLValueType.BOOL, v16_ .. ".bottomArm#toggleVisibility", "Bottom arm will be hidden on detach", false)
	schema:register(XMLValueType.VECTOR_N, v16_ .. ".bottomArm#categoryRange", "Defines the min. and max. category that can be used separated by a whitespace. (if only one value is given it will be used as min. and max. value.)", "1 4")
	schema:register(XMLValueType.VECTOR_N, v16_ .. ".bottomArm#widthRange", "Defines the min. and max. bottom arm width that can be used separated by a whitespace. Overwrites the categoryRange attribute. (if only one value is given it will be used as min. and max. value.)")
	schema:register(XMLValueType.FLOAT, v16_ .. ".bottomArm#defaultWidth", "Defines the default bottom arm width while nothing is attached", "Width inside i3d file")
	schema:register(XMLValueType.INT, v16_ .. ".bottomArm#defaultCategory", "Defines the default width category which is used when nothing is attached", "Width inside i3d file")
	schema:register(XMLValueType.BOOL, v16_ .. ".bottomArm#ballVisibility", "Defines if the balls of the tool are visible while the tool is attached to us", true)
	schema:register(XMLValueType.NODE_INDEX, v16_ .. ".bottomArm.armLeft#node", "Left bottom arm")
	schema:register(XMLValueType.NODE_INDEX, v16_ .. ".bottomArm.armLeft#referenceNode", "Left bottom arm reference node (placed at the attaching point at the end of the bottom arm. If not defined the arm will be translated on the X axis to the target width.)")
	schema:register(XMLValueType.NODE_INDEX, v16_ .. ".bottomArm.armRight#node", "Right bottom arm")
	schema:register(XMLValueType.NODE_INDEX, v16_ .. ".bottomArm.armRight#referenceNode", "Right bottom arm reference node (placed at the attaching point at the end of the bottom arm. If not defined the arm will be translated on the X axis to the target width.)")
	schema:register(XMLValueType.NODE_INDEX, v16_ .. ".bottomArm#leftNode", "Node of moving tool that will be aligned to \'bottomArmLeftNode\', if defined in the tool")
	schema:register(XMLValueType.NODE_INDEX, v16_ .. ".bottomArm#rightNode", "Node of moving tool that will be aligned to \'bottomArmRightNode\', if defined in the tool")
	schema:register(XMLValueType.STRING, v16_ .. ".toolbar#filename", "Filename to toolbars i3d containing 5 meshes for category 0-4", "$data/shared/assets/toolbars/toolbars.i3d")
	SoundManager.registerSampleXMLPaths(schema, v16_, "attachSound")
	SoundManager.registerSampleXMLPaths(schema, v16_, "detachSound")
	schema:register(XMLValueType.NODE_INDEX, v16_ .. ".steeringBars#leftNode", "Steering bar left node")
	schema:register(XMLValueType.NODE_INDEX, v16_ .. ".steeringBars#rightNode", "Steering bar right node")
	schema:register(XMLValueType.BOOL, v16_ .. ".steeringBars#forceUsage", "Forces usage of tools steering axle even if no steering bars are defined", true)
	schema:register(XMLValueType.NODE_INDEX, v16_ .. ".visualAlignNode(?)#node", "Node of movingPart that should point towards the inputAttacherJoint node of the implement")
	schema:register(XMLValueType.BOOL, v16_ .. ".visualAlignNode(?)#delayedOnAttach", "Node is updated after the smooth attach is finished", true)
	schema:register(XMLValueType.NODE_INDICES, v16_ .. ".visuals#nodes", "Visual nodes of attacher joint that will be visible when the joint is active")
	schema:register(XMLValueType.NODE_INDICES, v16_ .. ".visuals#hide", "Visual nodes that will be hidden while attacher joint is active if there attacher is inactive")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, v16_)
	schema:register(XMLValueType.BOOL, v16_ .. "#delayedObjectChanges", "Defines if object change is deactivated after the bottomArm has moved (if available)", true)
	schema:register(XMLValueType.BOOL, v16_ .. "#delayedObjectChangesOnAttach", "Defines if object change is activated on attach or post attach", false)
	schema:register(XMLValueType.INT, v16_ .. "#direction", "Direction of attacher joint (1 = front, -1 = back). Used for additional attachments on mobile and top light control in basegame.")
	schema:register(XMLValueType.BOOL, v16_ .. "#useTopLights", "Defines if the attacher joint enables the top lights if something is attached. Flag needs to be set on the implement as well.", "\'true\' if the attacher joint is on the front")
	schema:register(XMLValueType.NODE_INDEX, v16_ .. "#rootNode", "Root node", "Parent component of attacher joint node")
	schema:register(XMLValueType.FLOAT, v16_ .. "#comboTime", "Combo time")
	schema:register(XMLValueType.VECTOR_2, v16_ .. ".schema#position", "Schema position")
	schema:register(XMLValueType.VECTOR_2, v16_ .. ".schema#liftedOffset", "Offset if lifted", "0 5")
	schema:register(XMLValueType.ANGLE, v16_ .. ".schema#rotation", "Schema rotation", 0)
	schema:register(XMLValueType.BOOL, v16_ .. ".schema#invertX", "Invert X", false)
	schema:addDelayedRegistrationPath(v16_, "AttacherJoint")
	schema:resetXMLSharedRegistration("AttacherJoint", v16_)
end

-- Local values: key
function AttacherJoints.registerJointType(name)
	local v18_ = "JOINTTYPE_" .. string.upper(name)
	if AttacherJoints[v18_] == nil then
		AttacherJoints.NUM_JOINTTYPES = AttacherJoints.NUM_JOINTTYPES + 1
		AttacherJoints[v18_] = AttacherJoints.NUM_JOINTTYPES
		AttacherJoints.jointTypeNameToInt[name] = AttacherJoints.NUM_JOINTTYPES
	end
	return AttacherJoints[v18_]
end
AttacherJoints.JOINTTYPE_IMPLEMENT = AttacherJoints.registerJointType("implement")
AttacherJoints.JOINTTYPE_TRAILER = AttacherJoints.registerJointType("trailer")
AttacherJoints.JOINTTYPE_TRAILERLOW = AttacherJoints.registerJointType("trailerLow")
AttacherJoints.JOINTTYPE_TRAILERSADDLED = AttacherJoints.registerJointType("trailerSaddled")
AttacherJoints.JOINTTYPE_TRAILERCAR = AttacherJoints.registerJointType("trailerCar")
AttacherJoints.JOINTTYPE_TELEHANDLER = AttacherJoints.registerJointType("telehandler")
AttacherJoints.JOINTTYPE_FRONTLOADER = AttacherJoints.registerJointType("frontloader")
AttacherJoints.JOINTTYPE_LOADERFORK = AttacherJoints.registerJointType("loaderFork")
AttacherJoints.JOINTTYPE_SEMITRAILER = AttacherJoints.registerJointType("semitrailer")
AttacherJoints.JOINTTYPE_SEMITRAILERHOOK = AttacherJoints.registerJointType("semitrailerHook")
AttacherJoints.JOINTTYPE_SEMITRAILERCAR = AttacherJoints.registerJointType("semitrailerCar")
AttacherJoints.JOINTTYPE_ATTACHABLEFRONTLOADER = AttacherJoints.registerJointType("attachableFrontloader")
AttacherJoints.JOINTTYPE_WHEELLOADER = AttacherJoints.registerJointType("wheelLoader")
AttacherJoints.JOINTTYPE_MANUREBARREL = AttacherJoints.registerJointType("manureBarrel")
AttacherJoints.JOINTTYPE_CUTTER = AttacherJoints.registerJointType("cutter")
AttacherJoints.JOINTTYPE_CUTTERHARVESTER = AttacherJoints.registerJointType("cutterHarvester")
AttacherJoints.JOINTTYPE_CUTTERTRAILER = AttacherJoints.registerJointType("cutterTrailer")
AttacherJoints.JOINTTYPE_SKIDSTEER = AttacherJoints.registerJointType("skidSteer")
AttacherJoints.JOINTTYPE_CONVEYOR = AttacherJoints.registerJointType("conveyor")
AttacherJoints.JOINTTYPE_HOOKLIFT = AttacherJoints.registerJointType("hookLift")
AttacherJoints.JOINTTYPE_BIGBAG = AttacherJoints.registerJointType("bigBag")
AttacherJoints.JOINTTYPE_TRAIN = AttacherJoints.registerJointType("train")

function AttacherJoints.prerequisitesPresent(self)
	return true
end

function AttacherJoints.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onPreAttachImplement")
	SpecializationUtil.registerEvent(vehicleType, "onPostAttachImplement")
	SpecializationUtil.registerEvent(vehicleType, "onPreDetachImplement")
	SpecializationUtil.registerEvent(vehicleType, "onPostDetachImplement")
	SpecializationUtil.registerEvent(vehicleType, "onRequiresTopLightsChanged")
end

function AttacherJoints.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadAttachmentsFinished", AttacherJoints.loadAttachmentsFinished)
	SpecializationUtil.registerFunction(vehicleType, "handleLowerImplementEvent", AttacherJoints.handleLowerImplementEvent)
	SpecializationUtil.registerFunction(vehicleType, "handleLowerImplementByAttacherJointIndex", AttacherJoints.handleLowerImplementByAttacherJointIndex)
	SpecializationUtil.registerFunction(vehicleType, "getAttachedImplements", AttacherJoints.getAttachedImplements)
	SpecializationUtil.registerFunction(vehicleType, "getAttacherJoints", AttacherJoints.getAttacherJoints)
	SpecializationUtil.registerFunction(vehicleType, "getAttacherJointByJointDescIndex", AttacherJoints.getAttacherJointByJointDescIndex)
	SpecializationUtil.registerFunction(vehicleType, "getAttacherJointIndexByNode", AttacherJoints.getAttacherJointIndexByNode)
	SpecializationUtil.registerFunction(vehicleType, "getAttacherJointByNode", AttacherJoints.getAttacherJointByNode)
	SpecializationUtil.registerFunction(vehicleType, "getImplementFromAttacherJointIndex", AttacherJoints.getImplementFromAttacherJointIndex)
	SpecializationUtil.registerFunction(vehicleType, "getAttacherJointIndexFromObject", AttacherJoints.getAttacherJointIndexFromObject)
	SpecializationUtil.registerFunction(vehicleType, "getAttacherJointDescFromObject", AttacherJoints.getAttacherJointDescFromObject)
	SpecializationUtil.registerFunction(vehicleType, "getAttacherJointIndexFromImplementIndex", AttacherJoints.getAttacherJointIndexFromImplementIndex)
	SpecializationUtil.registerFunction(vehicleType, "getObjectFromImplementIndex", AttacherJoints.getObjectFromImplementIndex)
	SpecializationUtil.registerFunction(vehicleType, "updateAttacherJointGraphics", AttacherJoints.updateAttacherJointGraphics)
	SpecializationUtil.registerFunction(vehicleType, "calculateAttacherJointMoveUpperLowerAlpha", AttacherJoints.calculateAttacherJointMoveUpperLowerAlpha)
	SpecializationUtil.registerFunction(vehicleType, "doGroundHeightNodeCheck", AttacherJoints.doGroundHeightNodeCheck)
	SpecializationUtil.registerFunction(vehicleType, "finishGroundHeightNodeCheck", AttacherJoints.finishGroundHeightNodeCheck)
	SpecializationUtil.registerFunction(vehicleType, "groundHeightNodeCheckCallback", AttacherJoints.groundHeightNodeCheckCallback)
	SpecializationUtil.registerFunction(vehicleType, "updateAttacherJointRotation", AttacherJoints.updateAttacherJointRotation)
	SpecializationUtil.registerFunction(vehicleType, "updateAttacherJointRotationNodes", AttacherJoints.updateAttacherJointRotationNodes)
	SpecializationUtil.registerFunction(vehicleType, "updateAttacherJointSettingsByObject", AttacherJoints.updateAttacherJointSettingsByObject)
	SpecializationUtil.registerFunction(vehicleType, "setAttacherJointBottomArmWidth", AttacherJoints.setAttacherJointBottomArmWidth)
	SpecializationUtil.registerFunction(vehicleType, "attachImplementFromInfo", AttacherJoints.attachImplementFromInfo)
	SpecializationUtil.registerFunction(vehicleType, "attachImplement", AttacherJoints.attachImplement)
	SpecializationUtil.registerFunction(vehicleType, "postAttachImplement", AttacherJoints.postAttachImplement)
	SpecializationUtil.registerFunction(vehicleType, "createAttachmentJoint", AttacherJoints.createAttachmentJoint)
	SpecializationUtil.registerFunction(vehicleType, "hardAttachImplement", AttacherJoints.hardAttachImplement)
	SpecializationUtil.registerFunction(vehicleType, "hardDetachImplement", AttacherJoints.hardDetachImplement)
	SpecializationUtil.registerFunction(vehicleType, "detachImplement", AttacherJoints.detachImplement)
	SpecializationUtil.registerFunction(vehicleType, "detachImplementByObject", AttacherJoints.detachImplementByObject)
	SpecializationUtil.registerFunction(vehicleType, "playAttachSound", AttacherJoints.playAttachSound)
	SpecializationUtil.registerFunction(vehicleType, "playDetachSound", AttacherJoints.playDetachSound)
	SpecializationUtil.registerFunction(vehicleType, "detachingIsPossible", AttacherJoints.detachingIsPossible)
	SpecializationUtil.registerFunction(vehicleType, "attachAdditionalAttachment", AttacherJoints.attachAdditionalAttachment)
	SpecializationUtil.registerFunction(vehicleType, "detachAdditionalAttachment", AttacherJoints.detachAdditionalAttachment)
	SpecializationUtil.registerFunction(vehicleType, "getImplementIndexByJointDescIndex", AttacherJoints.getImplementIndexByJointDescIndex)
	SpecializationUtil.registerFunction(vehicleType, "getImplementByJointDescIndex", AttacherJoints.getImplementByJointDescIndex)
	SpecializationUtil.registerFunction(vehicleType, "getImplementIndexByObject", AttacherJoints.getImplementIndexByObject)
	SpecializationUtil.registerFunction(vehicleType, "getImplementByObject", AttacherJoints.getImplementByObject)
	SpecializationUtil.registerFunction(vehicleType, "callFunctionOnAllImplements", AttacherJoints.callFunctionOnAllImplements)
	SpecializationUtil.registerFunction(vehicleType, "activateAttachments", AttacherJoints.activateAttachments)
	SpecializationUtil.registerFunction(vehicleType, "deactivateAttachments", AttacherJoints.deactivateAttachments)
	SpecializationUtil.registerFunction(vehicleType, "deactivateAttachmentsLights", AttacherJoints.deactivateAttachmentsLights)
	SpecializationUtil.registerFunction(vehicleType, "setJointMoveDown", AttacherJoints.setJointMoveDown)
	SpecializationUtil.registerFunction(vehicleType, "getJointMoveDown", AttacherJoints.getJointMoveDown)
	SpecializationUtil.registerFunction(vehicleType, "getIsHardAttachAllowed", AttacherJoints.getIsHardAttachAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getIsSmoothAttachUpdateAllowed", AttacherJoints.getIsSmoothAttachUpdateAllowed)
	SpecializationUtil.registerFunction(vehicleType, "loadAttacherJointFromXML", AttacherJoints.loadAttacherJointFromXML)
	SpecializationUtil.registerFunction(vehicleType, "onBottomArmToolbarI3DLoaded", AttacherJoints.onBottomArmToolbarI3DLoaded)
	SpecializationUtil.registerFunction(vehicleType, "setSelectedImplementByObject", AttacherJoints.setSelectedImplementByObject)
	SpecializationUtil.registerFunction(vehicleType, "getSelectedImplement", AttacherJoints.getSelectedImplement)
	SpecializationUtil.registerFunction(vehicleType, "getCanToggleAttach", AttacherJoints.getCanToggleAttach)
	SpecializationUtil.registerFunction(vehicleType, "getShowAttachControlBarAction", AttacherJoints.getShowAttachControlBarAction)
	SpecializationUtil.registerFunction(vehicleType, "getAttachControlBarActionAccessible", AttacherJoints.getAttachControlBarActionAccessible)
	SpecializationUtil.registerFunction(vehicleType, "detachAttachedImplement", AttacherJoints.detachAttachedImplement)
	SpecializationUtil.registerFunction(vehicleType, "startAttacherJointCombo", AttacherJoints.startAttacherJointCombo)
	SpecializationUtil.registerFunction(vehicleType, "registerSelfLoweringActionEvent", AttacherJoints.registerSelfLoweringActionEvent)
	SpecializationUtil.registerFunction(vehicleType, "getIsAttachingAllowed", AttacherJoints.getIsAttachingAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getIsAttacherJointCompatible", AttacherJoints.getIsAttacherJointCompatible)
	SpecializationUtil.registerFunction(vehicleType, "getCanSteerAttachable", AttacherJoints.getCanSteerAttachable)
	SpecializationUtil.registerFunction(vehicleType, "onAttacherJointsVehicleLoaded", AttacherJoints.onAttacherJointsVehicleLoaded)
	SpecializationUtil.registerFunction(vehicleType, "getAttachableInfo", AttacherJoints.getAttachableInfo)
	SpecializationUtil.registerFunction(vehicleType, "setAttacherJointBlocked", AttacherJoints.setAttacherJointBlocked)
end

function AttacherJoints.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "raiseActive", AttacherJoints.raiseActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "registerActionEvents", AttacherJoints.registerActionEvents)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeActionEvents", AttacherJoints.removeActionEvents)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", AttacherJoints.addToPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", AttacherJoints.removeFromPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTotalMass", AttacherJoints.getTotalMass)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAdditionalComponentMass", AttacherJoints.getAdditionalComponentMass)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addChildVehicles", AttacherJoints.addChildVehicles)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAirConsumerUsage", AttacherJoints.getAirConsumerUsage)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRequiresPower", AttacherJoints.getRequiresPower)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addVehicleToAIImplementList", AttacherJoints.addVehicleToAIImplementList)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "collectAIAgentAttachments", AttacherJoints.collectAIAgentAttachments)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setAIVehicleObstacleStateDirty", AttacherJoints.setAIVehicleObstacleStateDirty)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirectionSnapAngle", AttacherJoints.getDirectionSnapAngle)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillLevelInformation", AttacherJoints.getFillLevelInformation)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getHasObjectMounted", AttacherJoints.getHasObjectMounted)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "attachableAddToolCameras", AttacherJoints.attachableAddToolCameras)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "attachableRemoveToolCameras", AttacherJoints.attachableRemoveToolCameras)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "registerSelectableObjects", AttacherJoints.registerSelectableObjects)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsReadyForAutomatedTrainTravel", AttacherJoints.getIsReadyForAutomatedTrainTravel)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAutomaticShiftingAllowed", AttacherJoints.getIsAutomaticShiftingAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDashboardGroupFromXML", AttacherJoints.loadDashboardGroupFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDashboardGroupActive", AttacherJoints.getIsDashboardGroupActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAttacherJointHeightNode", AttacherJoints.loadAttacherJointHeightNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAttacherJointHeightNodeActive", AttacherJoints.getIsAttacherJointHeightNodeActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadTipSide", AttacherJoints.loadTipSide)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsTipSideAvailable", AttacherJoints.getIsTipSideAvailable)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadFillUnitFromXML", AttacherJoints.loadFillUnitFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitSupportsToolType", AttacherJoints.getFillUnitSupportsToolType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "isDetachAllowed", AttacherJoints.isDetachAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", AttacherJoints.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWheelFoliageDestructionAllowed", AttacherJoints.getIsWheelFoliageDestructionAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreControlledActionsAllowed", AttacherJoints.getAreControlledActionsAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConnectionHoseConfigIndex", AttacherJoints.getConnectionHoseConfigIndex)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getPowerTakeOffConfigIndex", AttacherJoints.getPowerTakeOffConfigIndex)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadHoseTargetNode", AttacherJoints.loadHoseTargetNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsConnectionTargetUsed", AttacherJoints.getIsConnectionTargetUsed)
end

function AttacherJoints.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDelete", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateInterpolation", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateEnd", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onLightsTypesMaskChanged", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnLightStateChanged", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onBrakeLightsVisibilityChanged", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onReverseLightsVisibilityChanged", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onBeaconLightsVisibilityChanged", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onBrake", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onActivate", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onReverseDirectionChanged", AttacherJoints)
end

-- Local values: spec
function AttacherJoints:onPreLoad(savegame)
	local v24_ = self.spec_attacherJoints
	v24_.attachedImplements = {}
	v24_.selectedImplement = nil
	v24_.lastInputAttacherCheckIndex = 0
end

-- Local values: spec, i, baseName, attacherJoint, k, attacherJoint
function AttacherJoints:onLoad(savegame)
	local v26_ = self.spec_attacherJoints
	v26_.attacherJointCombos = {}
	v26_.attacherJointCombos.duration = self.xmlFile:getValue("vehicle.attacherJoints#comboDuration", 2) * 1000
	v26_.attacherJointCombos.currentTime = 0
	v26_.attacherJointCombos.direction = -1
	v26_.attacherJointCombos.isRunning = false
	v26_.attacherJointCombos.joints = {}
	v26_.maxUpdateDistance = self.xmlFile:getValue("vehicle.attacherJoints#maxUpdateDistance", AttacherJoints.DEFAULT_MAX_UPDATE_DISTANCE)
	v26_.visualNodeToAttacherJoints = {}
	v26_.hideVisualNodeToAttacherJoints = {}
	v26_.attacherJoints = {}
	local v27_ = 0
	while true do
		local v28_ = string.format("vehicle.attacherJoints.attacherJoint(%d)", v27_)
		if not self.xmlFile:hasProperty(v28_) then
			break
		end
		local v29_ = {}
		if self:loadAttacherJointFromXML(v29_, self.xmlFile, v28_, v27_) then
			local v30_ = v26_.attacherJoints
			table.insert(v30_, v29_)
			v29_.index = #v26_.attacherJoints
		end
		v27_ = v27_ + 1
	end
	v26_.attachableInfo = {}
	v26_.attachableInfo.attacherVehicle = nil
	v26_.attachableInfo.attacherVehicleJointDescIndex = nil
	v26_.attachableInfo.attachable = nil
	v26_.attachableInfo.attachableJointDescIndex = nil
	v26_.pendingAttachableInfo = {}
	v26_.pendingAttachableInfo.minDistance = math.huge
	v26_.pendingAttachableInfo.minDistanceY = math.huge
	v26_.pendingAttachableInfo.attacherVehicle = nil
	v26_.pendingAttachableInfo.attacherVehicleJointDescIndex = nil
	v26_.pendingAttachableInfo.attachable = nil
	v26_.pendingAttachableInfo.attachableJointDescIndex = nil
	v26_.pendingAttachableInfo.warning = nil
	if self.isClient then
		v26_.samples = {}
		v26_.isHydraulicSamplePlaying = false
		v26_.samples.hydraulic = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.attacherJoints.sounds", "hydraulic", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v26_.samples.attach = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.attacherJoints.sounds", "attach", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v26_.samples.detach = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.attacherJoints.sounds", "detach", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
	if self.isClient and g_isDevelopmentVersion then
		for v31_, v32_ in ipairs(v26_.attacherJoints) do
			if v26_.samples.attach == nil and v32_.sampleAttach == nil then
				Logging.xmlDevWarning(self.xmlFile, "Missing attach sound for attacherjoint \'%d\'", v31_)
			end
			if v32_.rotationNode ~= nil and v26_.samples.hydraulic == nil then
				Logging.xmlDevWarning(self.xmlFile, "Missing hydraulic sound for attacherjoint \'%d\'", v31_)
			end
		end
	end
	v26_.showAttachNotAllowedText = 0
	v26_.wasInAttachRange = false
	v26_.texts = {}
	v26_.texts.warningToolNotCompatible = g_i18n:getText("warning_toolNotCompatible")
	v26_.texts.warningToolBrandNotCompatible = g_i18n:getText("warning_toolBrandNotCompatible")
	v26_.texts.infoAttachNotAllowed = g_i18n:getText("info_attach_not_allowed")
	v26_.texts.lowerImplementFirst = g_i18n:getText("warning_lowerImplementFirst")
	v26_.texts.detachNotAllowed = g_i18n:getText("warning_detachNotAllowed")
	v26_.texts.actionAttach = g_i18n:getText("action_attach")
	v26_.texts.actionDetach = g_i18n:getText("action_detach")
	v26_.texts.warningFoldingAttacherJoint = g_i18n:getText("warning_foldingNotWhileAttachedToAttacherJoint")
	v26_.groundHeightNodeCheckData = {
		["isDirty"] = false,
		["minDistance"] = math.huge,
		["hit"] = false,
		["raycastDistance"] = 1,
		["currentRaycastDistance"] = 1,
		["heightNodes"] = {},
		["jointDesc"] = {},
		["index"] = -1,
		["lowerDistanceToGround"] = 0,
		["upperDistanceToGround"] = 0,
		["currentRaycastWorldPos"] = { 0, 0, 0 },
		["currentRaycastWorldDir"] = { 0, 0, 0 },
		["currentJointTransformPos"] = { 0, 0, 0 },
		["raycastWorldPos"] = { 0, 0, 0 },
		["raycastWorldDir"] = { 0, 0, 0 },
		["jointTransformPos"] = { 0, 0, 0 },
		["upperAlpha"] = 0,
		["lowerAlpha"] = 0
	}
	v26_.dirtyFlag = self:getNextDirtyFlag()
end

-- Local values: spec, attacherJointIndex, attacherJoint, _, _, attacherJoint2, _, visualAlignNode, _, inputAttacherJoint, xDir, yDir, zDir, xUp, yUp, zUp, xNorm, yNorm, zNorm, xOffset, yOffset, zOffset, aiRootNode, xDir, yDir, zDir, xUp, yUp, zUp, xNorm, yNorm, zNorm, xOffset, yOffset, zOffset, comboData, comboDirection
function AttacherJoints:onPostLoad(savegame)
	local v35_ = self.spec_attacherJoints
	for v36_, v37_ in pairs(v35_.attacherJoints) do
		v37_.jointOrigRot = { getRotation(v37_.jointTransform) }
		v37_.jointOrigTrans = { getTranslation(v37_.jointTransform) }
		if v37_.transNode ~= nil then
			v37_.transNodeMinY = Utils.getNoNil(v37_.transNodeMinY, v37_.jointOrigTrans[2])
			v37_.transNodeMaxY = Utils.getNoNil(v37_.transNodeMaxY, v37_.jointOrigTrans[2])
			local _, v38_, _ = localToLocal(v37_.jointTransform, v37_.transNode, 0, 0, 0)
			v37_.transNodeOffsetY = v38_
			local _, v39_, _ = localToLocal(getParent(v37_.transNode), v37_.rootNode, 0, v37_.transNodeMinY, 0)
			v37_.transNodeMinY = v39_
			local _, v40_, _ = localToLocal(getParent(v37_.transNode), v37_.rootNode, 0, v37_.transNodeMaxY, 0)
			v37_.transNodeMaxY = v40_
		end
		if v37_.transNodeDependentBottomArm ~= nil then
			for _, v41_ in pairs(v35_.attacherJoints) do
				if v41_.bottomArm ~= nil and v41_.bottomArm.rotationNode == v37_.transNodeDependentBottomArm then
					v37_.transNodeDependentBottomArmAttacherJoint = v41_
				end
			end
			if v37_.transNodeDependentBottomArmAttacherJoint == nil then
				Logging.xmlWarning(self.xmlFile, "Unable to find dependent bottom arm \'%s\' in any attacher joint.", getName(v37_.transNodeDependentBottomArm))
				v37_.transNodeDependentBottomArm = nil
			end
		end
		if v37_.bottomArm ~= nil then
			setRotation(v37_.bottomArm.rotationNode, v37_.bottomArm.rotX, v37_.bottomArm.rotY, v37_.bottomArm.rotZ)
			if self.setMovingToolDirty ~= nil then
				self:setMovingToolDirty(v37_.bottomArm.rotationNode)
			end
		end
		if v37_.rotationNode ~= nil then
			setRotation(v37_.rotationNode, v37_.rotX, v37_.rotY, v37_.rotZ)
		end
		if v37_.visualAlignNodes ~= nil then
			for _, v42_ in ipairs(v37_.visualAlignNodes) do
				self:setMovingPartReferenceNode(v42_.node, v37_.jointTransform, false)
			end
		end
		if self.getInputAttacherJoints ~= nil then
			v37_.inputAttacherJointOffsets = {}
			for _, v43_ in ipairs(self:getInputAttacherJoints()) do
				local v44_, v45_, v46_ = localDirectionToLocal(v37_.jointTransform, v43_.node, 0, 0, 1)
				local v47_, v48_, v49_ = localDirectionToLocal(v37_.jointTransform, v43_.node, 0, 1, 0)
				local v50_, v51_, v52_ = localDirectionToLocal(v37_.jointTransform, v43_.node, 1, 0, 0)
				local v53_, v54_, v55_ = localToLocal(v37_.jointTransform, v43_.node, 0, 0, 0)
				local v56_ = v37_.inputAttacherJointOffsets
				table.insert(v56_, {
					v53_,
					v54_,
					v55_,
					v44_,
					v45_,
					v46_,
					v47_,
					v48_,
					v49_,
					v50_,
					v51_,
					v52_
				})
			end
		end
		if self.getAIRootNode ~= nil then
			local v57_ = self:getAIRootNode()
			local v58_, v59_, v60_ = localDirectionToLocal(v37_.jointTransform, v57_, 0, 0, 1)
			local v61_, v62_, v63_ = localDirectionToLocal(v37_.jointTransform, v57_, 0, 1, 0)
			local v64_, v65_, v66_ = localDirectionToLocal(v37_.jointTransform, v57_, 1, 0, 0)
			local v67_, v68_, v69_ = localToLocal(v37_.jointTransform, v57_, 0, 0, 0)
			v37_.aiRootNodeOffset = {
				v67_,
				v68_,
				v69_,
				v58_,
				v59_,
				v60_,
				v61_,
				v62_,
				v63_,
				v64_,
				v65_,
				v66_
			}
		end
		if v37_.comboTime ~= nil then
			local v70_ = {
				["jointIndex"] = v36_
			}
			local v71_ = v37_.comboTime
			v70_.time = math.clamp(v71_, 0, 1) * v35_.attacherJointCombos.duration
			v70_.initialTime = v70_.time
			local v72_ = v35_.attacherJointCombos.joints
			table.insert(v72_, v70_)
		end
		self:setAttacherJointBottomArmWidth(v36_, nil)
	end
	if savegame ~= nil and (not savegame.resetVehicles and v35_.attacherJointCombos ~= nil) then
		local v73_ = savegame.xmlFile:getValue(savegame.key .. ".attacherJoints#comboDirection")
		if v73_ ~= nil then
			v35_.attacherJointCombos.direction = v73_
			if v73_ == 1 then
				v35_.attacherJointCombos.currentTime = v35_.attacherJointCombos.duration
			end
		end
	end
	if #v35_.attacherJoints == 0 then
		SpecializationUtil.removeEventListener(self, "onReadStream", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onWriteStream", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onUpdateInterpolation", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onUpdate", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onUpdateEnd", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onStateChange", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onLightsTypesMaskChanged", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onTurnLightStateChanged", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onBrakeLightsVisibilityChanged", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onReverseLightsVisibilityChanged", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onBeaconLightsVisibilityChanged", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onBrake", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onTurnedOn", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onTurnedOff", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onLeaveVehicle", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onActivate", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onDeactivate", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onReverseDirectionChanged", AttacherJoints)
	end
end

-- Local values: spec, xmlFile, index, attachedImplementKey, jointIndex, attachmentData, vehicle, index, attacherJointKey, jointIndex, isBlocked, attacherJoint
function AttacherJoints:onLoadFinished(savegame)
	local v76_ = self.spec_attacherJoints
	if savegame ~= nil and (not savegame.resetVehicles or savegame.keepPosition) then
		v76_.attachmentDataToLoad = {}
		local v77_ = savegame.xmlFile
		for _, v78_ in v77_:iterator(savegame.key .. ".attacherJoints.attachedImplement") do
			local v79_ = {
				["jointIndex"] = v77_:getValue(v78_ .. "#jointIndex"),
				["attachedVehicleUniqueId"] = v77_:getValue(v78_ .. "#attachedVehicleUniqueId"),
				["inputIndex"] = v77_:getValue(v78_ .. "#inputJointIndex"),
				["moveDown"] = v77_:getValue(v78_ .. "#moveDown", false)
			}
			if v79_.jointIndex ~= nil and (v79_.attachedVehicleUniqueId ~= nil and v79_.inputIndex ~= nil) then
				local v80_ = g_currentMission.vehicleSystem:getVehicleByUniqueId(v79_.attachedVehicleUniqueId)
				if v80_ == nil then
					local v81_ = v76_.attachmentDataToLoad
					table.insert(v81_, v79_)
				else
					self:attachImplement(v80_, v79_.inputIndex, v79_.jointIndex, true, nil, v79_.moveDown, true, true)
					self:setJointMoveDown(v79_.jointIndex, v79_.moveDown, true)
				end
			end
		end
		for _, v82_ in v77_:iterator(savegame.key .. ".attacherJoints.attacherJoint") do
			local v83_ = v77_:getValue(v82_ .. "#jointIndex")
			local v84_ = v77_:getValue(v82_ .. "#isBlocked")
			if v84_ then
				v76_.attacherJoints[v83_].isBlocked = v84_
			end
		end
		if #v76_.attachmentDataToLoad > 0 then
			g_messageCenter:subscribe(MessageType.VEHICLE_LOADED, self.onAttacherJointsVehicleLoaded, self)
		end
	end
end

-- Local values: spec, loadAttacherJointNodeFunc, setAttacherJointFromNodes, bottomArmPosition, bottomArmPositionMin, bottomArmPositionMax
function AttacherJoints:onRegisterDashboardValueTypes()
	local v86_ = self.spec_attacherJoints
	local function v90_(_, p87_, p88_, p89_, _)
		-- upvalues: (copy) self
		p89_.attacherJointNode = p87_:getValue(p88_ .. "#attacherJointNode", nil, self.components, self.i3dMappings)
		if p89_.attacherJointNode ~= nil then
			return true
		end
		p89_.attacherJointNodes = p87_:getValue(p88_ .. "#attacherJointNodes", nil, self.components, self.i3dMappings, true)
		return #p89_.attacherJointNodes ~= 0
	end
	local function v_u_95_(p91_)
		-- upvalues: (copy) self
		if p91_.attacherJointNode ~= nil then
			local v92_ = self:getAttacherJointByNode(p91_.attacherJointNode)
			if v92_ == nil or v92_.bottomArm == nil then
				p91_.attacherJointNode = nil
			else
				p91_.attacherJoint = v92_
			end
		end
		if p91_.attacherJointNodes ~= nil then
			for _, v93_ in ipairs(p91_.attacherJointNodes) do
				local v94_ = self:getAttacherJointByNode(v93_)
				if v94_ ~= nil and v94_.bottomArm ~= nil then
					p91_.attacherJoint = v94_
					break
				end
			end
			if p91_.attacherJoint == nil then
				p91_.attacherJointNodes = nil
			end
		end
	end
	local v96_ = DashboardValueType.new("attacherJoints", "bottomArmPosition")
	v96_:setValue(v86_, function(_, p97_)
		-- upvalues: (copy) v_u_95_
		if p97_.attacherJoint == nil then
			v_u_95_(p97_)
			if p97_.attacherJoint == nil then
				return 0
			end
		end
		return 1 - (p97_.attacherJoint.moveAlpha or 0)
	end)
	v96_:setAdditionalFunctions(v90_)
	v96_:setValueFactor(100)
	v96_:setRange(0, 100)
	v96_:setPollUpdate(false)
	self:registerDashboardValueType(v96_)
	local v98_ = DashboardValueType.new("attacherJoints", "bottomArmPositionMin")
	v98_:setValue(v86_, function(_, p99_)
		-- upvalues: (copy) v_u_95_
		if p99_.attacherJoint == nil then
			v_u_95_(p99_)
			if p99_.attacherJoint == nil then
				return 0
			end
		end
		return 1 - (p99_.attacherJoint.lowerAlpha or 1)
	end)
	v98_:setAdditionalFunctions(v90_)
	v98_:setValueFactor(100)
	v98_:setRange(0, 100)
	v98_:setPollUpdate(false)
	self:registerDashboardValueType(v98_)
	local v100_ = DashboardValueType.new("attacherJoints", "bottomArmPositionMax")
	v100_:setValue(v86_, function(_, p101_)
		-- upvalues: (copy) v_u_95_
		if p101_.attacherJoint == nil then
			v_u_95_(p101_)
			if p101_.attacherJoint == nil then
				return 0
			end
		end
		return 1 - (p101_.attacherJoint.upperAlpha or 0)
	end)
	v100_:setAdditionalFunctions(v90_)
	v100_:setValueFactor(100)
	v100_:setRange(0, 100)
	v100_:setPollUpdate(false)
	self:registerDashboardValueType(v100_)
end

-- Local values: spec, i, implement
function AttacherJoints:onPreDelete()
	local v103_ = self.spec_attacherJoints
	if v103_.attachedImplements ~= nil then
		for v104_ = #v103_.attachedImplements, 1, -1 do
			local v105_ = v103_.attachedImplements[v104_]
			if not v105_.object:getIsAdditionalAttachment() then
				self:detachImplementByObject(v105_.object, true)
			end
		end
	end
end

-- Local values: spec, _, jointDesc, bottomArm
function AttacherJoints:onDelete()
	local v107_ = self.spec_attacherJoints
	if v107_.attacherJoints ~= nil then
		for _, v108_ in pairs(v107_.attacherJoints) do
			g_soundManager:deleteSample(v108_.sampleAttach)
			g_soundManager:deleteSample(v108_.sampleDetach)
			if v108_.topArm ~= nil then
				v108_.topArm:delete()
				v108_.topArm = nil
			end
			local v109_ = v108_.bottomArm
			if v109_ ~= nil and v109_.sharedLoadRequestIdToolbar ~= nil then
				g_i3DManager:releaseSharedI3DFile(v109_.sharedLoadRequestIdToolbar)
				v109_.sharedLoadRequestIdToolbar = nil
			end
		end
		g_soundManager:deleteSamples(v107_.samples)
	end
end

-- Local values: spec, index, implement, attacherJointKey, jointDesc, index, jointIndex, jointDesc, attacherJointKey
function AttacherJoints:saveToXMLFile(xmlFile, key, usedModNames)
	local v113_ = self.spec_attacherJoints
	if v113_.attacherJointCombos ~= nil then
		xmlFile:setValue(key .. "#comboDirection", v113_.attacherJointCombos.direction)
	end
	if v113_.attacherJoints ~= nil then
		for v114_, v115_ in ipairs(v113_.attachedImplements) do
			if v115_.object ~= nil then
				local v116_ = string.format("%s.attachedImplement(%d)", key, v114_ - 1)
				local v117_ = self:getAttacherJointByJointDescIndex(v115_.jointDescIndex)
				xmlFile:setValue(v116_ .. "#jointIndex", v115_.jointDescIndex)
				xmlFile:setValue(v116_ .. "#moveDown", v117_.moveDown)
				xmlFile:setValue(v116_ .. "#attachedVehicleUniqueId", v115_.object:getUniqueId())
				xmlFile:setValue(v116_ .. "#inputJointIndex", v115_.inputJointDescIndex)
			end
		end
		local v118_ = 0
		for v119_, v120_ in pairs(v113_.attacherJoints) do
			if v120_.isBlocked then
				local v121_ = string.format("%s.attacherJoint(%d)", key, v118_)
				xmlFile:setValue(v121_ .. "#jointIndex", v119_)
				xmlFile:setValue(v121_ .. "#isBlocked", v120_.isBlocked)
				v118_ = v118_ + 1
			end
		end
	end
end

-- Local values: numImplements, i, object, inputJointDescIndex, jointDescIndex, moveDown
function AttacherJoints:onReadStream(streamId, connection)
	for v124_ = 1, streamReadInt8(streamId) do
		local v125_ = NetworkUtil.readNodeObject(streamId)
		local v126_ = streamReadInt8(streamId)
		local v127_ = streamReadInt8(streamId)
		local v128_ = streamReadBool(streamId)
		if v125_ ~= nil and v125_:getIsSynchronized() then
			self:attachImplement(v125_, v126_, v127_, true, v124_, v128_, true, true)
			self:setJointMoveDown(v127_, v128_, true)
		end
	end
end

-- Local values: spec, i, implement, inputJointDescIndex, jointDescIndex, jointDesc, moveDown
function AttacherJoints:onWriteStream(streamId, connection)
	local v131_ = self.spec_attacherJoints
	streamWriteInt8(streamId, #v131_.attachedImplements)
	for v132_ = 1, #v131_.attachedImplements do
		local v133_ = v131_.attachedImplements[v132_]
		local v134_ = v133_.object.spec_attachable.inputAttacherJointDescIndex
		local v135_ = v133_.jointDescIndex
		local v136_ = v131_.attacherJoints[v135_].moveDown
		NetworkUtil.writeNodeObject(streamId, v133_.object)
		streamWriteInt8(streamId, v134_)
		streamWriteInt8(streamId, v135_)
		streamWriteBool(streamId, v136_)
	end
end

-- Local values: spec, _, implement, _, implement
function AttacherJoints:onUpdateInterpolation(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v142_ = self.spec_attacherJoints
	if self.currentUpdateDistance < v142_.maxUpdateDistance then
		for _, v143_ in pairs(v142_.attachedImplements) do
			if v143_.object ~= nil and self.updateLoopIndex == v143_.object.updateLoopIndex then
				self:updateAttacherJointGraphics(v143_, dt, true)
				v143_.object:updateInputAttacherJointGraphics(v143_, dt)
			end
		end
	end
	for _, v144_ in pairs(v142_.attachedImplements) do
		if v144_.object ~= nil and v144_.object.spec_attachable.isHardAttached then
			SpecializationUtil.raiseEvent(v144_.object, "onUpdateInterpolation", dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
		end
	end
end

-- Local values: spec, info
function AttacherJoints:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v147_ = self.spec_attacherJoints
	if self.isClient then
		local v148_ = v147_.showAttachNotAllowedText - dt
		v147_.showAttachNotAllowedText = math.max(v148_, 0)
		if v147_.showAttachNotAllowedText > 0 then
			g_currentMission:addExtraPrintText(v147_.texts.infoAttachNotAllowed)
		end
	end
	local v149_ = v147_.attachableInfo
	if Platform.gameplay.automaticAttach and self.isServer or self.isClient and (v147_.actionEvents ~= nil and v147_.actionEvents[InputAction.ATTACH] ~= nil) then
		if self:getCanToggleAttach() then
			AttacherJoints.updateVehiclesInAttachRange(self, AttacherJoints.MAX_ATTACH_DISTANCE_SQ, AttacherJoints.MAX_ATTACH_ANGLE, true)
			return
		end
		v149_.attacherVehicle = nil
		v149_.attacherVehicleJointDescIndex = nil
		v149_.attachable = nil
		v149_.attachableJointDescIndex = nil
	end
end

-- Local values: spec, _, implement
function AttacherJoints:onUpdateEnd(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v152_ = self.spec_attacherJoints
	for _, v153_ in pairs(v152_.attachedImplements) do
		if v153_.object ~= nil and self.updateLoopIndex == v153_.object.updateLoopIndex then
			self:updateAttacherJointGraphics(v153_, dt, true)
		end
	end
end

-- Local values: spec, playHydraulicSound, _, implement, jointDesc, done, i, lastRotLimit, lastTransLimit, jointFrameInvalid, upperAlpha, lowerAlpha, moveAlpha, force, alpha, i, alpha, i, i, jointDesc, combos, _, joint, doLowering, implement, info, attachAllowed, warning
function AttacherJoints:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v156_ = self.spec_attacherJoints
	local v157_ = false
	for _, v158_ in pairs(v156_.attachedImplements) do
		if v158_.object ~= nil then
			local v159_ = v156_.attacherJoints[v158_.jointDescIndex]
			if not v158_.object.spec_attachable.isHardAttached then
				if self.isServer and (v158_.attachingIsInProgress and self:getIsSmoothAttachUpdateAllowed(v158_)) then
					local v160_ = true
					for v161_ = 1, 3 do
						local v162_ = v158_.attachingRotLimit[v161_]
						local v163_ = v158_.attachingTransLimit[v161_]
						local v164_ = v158_.attachingRotLimit
						local v165_ = v158_.attachingRotLimit[v161_] - v158_.attachingRotLimitSpeed[v161_] * dt
						v164_[v161_] = math.max(0, v165_)
						local v166_ = v158_.attachingTransLimit
						local v167_ = v158_.attachingTransLimit[v161_] - v158_.attachingTransLimitSpeed[v161_] * dt
						v166_[v161_] = math.max(0, v167_)
						if v158_.attachingRotLimit[v161_] > 0 or (v158_.attachingTransLimit[v161_] > 0 or (v162_ > 0 or v163_ > 0)) then
							v160_ = false
						end
					end
					v158_.attachingIsInProgress = not v160_
					if v160_ then
						if v158_.object.spec_attachable.attacherJoint.hardAttach and self:getIsHardAttachAllowed(v158_.jointDescIndex) then
							self:hardAttachImplement(v158_)
						end
						self:postAttachImplement(v158_)
					end
				end
				if not v158_.attachingIsInProgress then
					local v168_ = false
					if v159_.allowsLowering and self:getIsActive() then
						local v169_ = v159_.upperAlpha
						local v170_ = v159_.lowerAlpha
						if v159_.moveDown then
							v169_, v170_ = self:calculateAttacherJointMoveUpperLowerAlpha(v159_, v158_.object)
							local v171_ = v159_.moveDefaultTime
							local v172_ = v169_ - v170_
							v159_.moveTime = v171_ * math.abs(v172_)
						end
						local v173_ = Utils.getMovedLimitedValue(v159_.moveAlpha, v170_, v169_, v159_.moveTime, dt, not v159_.moveDown)
						if v173_ ~= v159_.moveAlpha or (v169_ ~= v159_.upperAlpha or v170_ ~= v159_.lowerAlpha) then
							v159_.upperAlpha = v169_
							v159_.lowerAlpha = v170_
							if v159_.moveDown then
								local v174_ = v159_.moveAlpha - v159_.lowerAlpha
								if math.abs(v174_) < 0.05 then
									v159_.isMoving = false
								end
							else
								local v175_ = v159_.moveAlpha - v159_.upperAlpha
								if math.abs(v175_) < 0.05 then
									v159_.isMoving = false
								end
							end
							v157_ = v159_.isMoving
							v159_.moveAlpha = v173_
							if v159_.upperAlpha - v159_.lowerAlpha == 0 then
								v159_.moveLimitAlpha = 1
							else
								v159_.moveLimitAlpha = 1 - (v173_ - v159_.lowerAlpha) / (v159_.upperAlpha - v159_.lowerAlpha)
							end
							v168_ = true
							self:updateAttacherJointRotationNodes(v159_, v159_.moveAlpha)
							self:updateAttacherJointRotation(v159_, v158_.object)
							if self.isClient and self.updateDashboardValueType ~= nil then
								self:updateDashboardValueType("attacherJoints.bottomArmPosition")
							end
						end
					end
					if v168_ or v159_.jointFrameInvalid then
						v159_.jointFrameInvalid = false
						if self.isServer then
							setJointFrame(v159_.jointIndex, 0, v159_.jointTransform)
						end
					end
				end
				if self.isServer then
					local v176_ = v158_.attachingIsInProgress
					if (v176_ or v159_.allowsLowering and v159_.allowsJointLimitMovement) and (v159_.jointIndex ~= nil and v159_.jointIndex ~= 0) then
						if v176_ or v158_.object.spec_attachable.attacherJoint.allowsJointRotLimitMovement then
							local v177_ = v159_.moveLimitAlpha - v158_.rotLimitThreshold
							local v178_ = math.max(v177_, 0) / (1 - v158_.rotLimitThreshold)
							for v179_ = 1, 3 do
								AttacherJoints.updateAttacherJointRotationLimit(v158_, v159_, v179_, v176_, v178_)
							end
						end
						if v176_ or v158_.object.spec_attachable.attacherJoint.allowsJointTransLimitMovement then
							local v180_ = v159_.moveLimitAlpha - v158_.transLimitThreshold
							local v181_ = math.max(v180_, 0) / (1 - v158_.transLimitThreshold)
							for v182_ = 1, 3 do
								AttacherJoints.updateAttacherJointTranslationLimit(v158_, v159_, v182_, v176_, v181_)
							end
						end
					end
				end
			end
		end
	end
	if self.isClient and v156_.samples.hydraulic ~= nil then
		for v183_ = 1, #v156_.attacherJoints do
			local v184_ = v156_.attacherJoints[v183_]
			if v184_.bottomArm ~= nil and v184_.bottomArm.bottomArmInterpolating then
				v157_ = true
			end
		end
		if v157_ then
			if not v156_.isHydraulicSamplePlaying then
				g_soundManager:playSample(v156_.samples.hydraulic)
				v156_.isHydraulicSamplePlaying = true
			end
		elseif v156_.isHydraulicSamplePlaying then
			g_soundManager:stopSample(v156_.samples.hydraulic)
			v156_.isHydraulicSamplePlaying = false
		end
	end
	local v185_ = v156_.attacherJointCombos
	if v185_ ~= nil and v185_.isRunning then
		for _, v186_ in pairs(v185_.joints) do
			local v187_ = nil
			if v185_.direction == 1 and v185_.currentTime >= v186_.time then
				v187_ = true
			elseif v185_.direction == -1 and v185_.currentTime <= v185_.duration - v186_.time then
				v187_ = false
			end
			if v187_ ~= nil then
				local v188_ = self:getImplementFromAttacherJointIndex(v186_.jointIndex)
				if v188_ ~= nil and v188_.object.setLoweredAll ~= nil then
					v188_.object:setLoweredAll(v187_, v186_.jointIndex)
				end
			end
		end
		if v185_.direction == -1 and v185_.currentTime == 0 or v185_.direction == 1 and v185_.currentTime == v185_.duration then
			v185_.isRunning = false
		end
		local v189_ = v185_.currentTime + dt * v185_.direction
		local v190_ = v185_.duration
		v185_.currentTime = math.clamp(v189_, 0, v190_)
	end
	AttacherJoints.updateActionEvents(self)
	if Platform.gameplay.automaticAttach and (self.isServer and self:getCanToggleAttach()) then
		local v191_ = v156_.attachableInfo
		if v191_.attachable == nil or (v156_.wasInAttachRange or v191_.attacherVehicle ~= self) then
			if v191_.attachable == nil and v156_.wasInAttachRange then
				v156_.wasInAttachRange = false
			end
		elseif not (self.isReconfigurating or v191_.attachable.isReconfigurating) then
			local v192_, v193_ = v191_.attachable:isAttachAllowed(self:getActiveFarm(), v191_.attacherVehicle)
			if v192_ then
				if v156_.wasInAttachRange == nil then
					v156_.wasInAttachRange = true
				else
					self:attachImplementFromInfo(v191_)
				end
			end
			if v193_ ~= nil then
				g_currentMission:showBlinkingWarning(v193_, 2000)
				return
			end
		end
	end
end

-- Local values: object
function AttacherJoints:loadAttachmentsFinished()
	if self.rootVehicle == self and self.loadedSelectedObjectIndex ~= nil then
		local v195_ = self.selectableObjects[self.loadedSelectedObjectIndex]
		if v195_ ~= nil then
			self:setSelectedObject(v195_, self.loadedSubSelectedObjectIndex or 1)
		end
		self.loadedSelectedObjectIndex = nil
		self.loadedSubSelectedObjectIndex = nil
	end
end

-- Local values: selectedVehicle, spec, implement, object, attacherVehicle, attacherJointIndex
function AttacherJoints:handleLowerImplementEvent(vehicle, direction)
	local v199_ = self:getSelectedVehicle()
	if vehicle == nil and v199_ == self then
		local v200_ = self.spec_attacherJoints
		if #v200_.attachedImplements == 1 then
			vehicle = v200_.attachedImplements[1].object
		end
	end
	local v201_ = self:getImplementByObject(vehicle or v199_)
	if v201_ ~= nil then
		local v202_ = v201_.object
		if v202_ ~= nil and v202_.getAttacherVehicle ~= nil then
			local v203_ = v202_:getAttacherVehicle()
			if v203_ ~= nil then
				v203_:handleLowerImplementByAttacherJointIndex(v203_:getAttacherJointIndexFromObject(v202_), direction)
			end
		end
	end
end

-- Local values: implement, object, attacherJoints, attacherJoint, allowsLowering, warning
function AttacherJoints:handleLowerImplementByAttacherJointIndex(attacherJointIndex, direction)
	if attacherJointIndex ~= nil then
		local v207_ = self:getImplementByJointDescIndex(attacherJointIndex)
		if v207_ ~= nil then
			local v208_ = v207_.object
			local v209_ = self:getAttacherJoints()[attacherJointIndex]
			local v210_, v211_ = v208_:getAllowsLowering()
			if v210_ and v209_.allowsLowering then
				if direction == nil then
					direction = not v209_.moveDown
				end
				self:setJointMoveDown(v207_.jointDescIndex, direction, false)
				return
			end
			if not v210_ and v211_ ~= nil then
				g_currentMission:showBlinkingWarning(v211_, 2000)
			end
		end
	end
end

function AttacherJoints:getAttachedImplements()
	return self.spec_attacherJoints.attachedImplements
end

function AttacherJoints:getAttacherJoints()
	return self.spec_attacherJoints.attacherJoints
end

function AttacherJoints:getAttacherJointByJointDescIndex(jointDescIndex)
	return self.spec_attacherJoints.attacherJoints[jointDescIndex]
end

-- Local values: spec, i, attacherJoint
function AttacherJoints:getAttacherJointIndexByNode(node)
	local v218_ = self.spec_attacherJoints
	for v219_ = 1, #v218_.attacherJoints do
		if v218_.attacherJoints[v219_].jointTransform == node then
			return v219_
		end
	end
	return nil
end

-- Local values: spec, i, attacherJoint
function AttacherJoints:getAttacherJointByNode(node)
	local v222_ = self.spec_attacherJoints
	for v223_ = 1, #v222_.attacherJoints do
		local v224_ = v222_.attacherJoints[v223_]
		if v224_.jointTransform == node then
			return v224_
		end
	end
	return nil
end

-- Local values: spec, _, attachedImplement
function AttacherJoints:getImplementFromAttacherJointIndex(attacherJointIndex)
	local v227_ = self.spec_attacherJoints
	for _, v228_ in pairs(v227_.attachedImplements) do
		if v228_.jointDescIndex == attacherJointIndex then
			return v228_
		end
	end
	return nil
end

-- Local values: spec, _, attachedImplement
function AttacherJoints:getAttacherJointIndexFromObject(object)
	local v231_ = self.spec_attacherJoints
	for _, v232_ in pairs(v231_.attachedImplements) do
		if v232_.object == object then
			return v232_.jointDescIndex
		end
	end
	return nil
end

-- Local values: spec, _, attachedImplement
function AttacherJoints:getAttacherJointDescFromObject(object)
	local v235_ = self.spec_attacherJoints
	for _, v236_ in pairs(v235_.attachedImplements) do
		if v236_.object == object then
			return v235_.attacherJoints[v236_.jointDescIndex]
		end
	end
	return nil
end

-- Local values: spec, attachedImplement
function AttacherJoints:getAttacherJointIndexFromImplementIndex(implementIndex)
	local v239_ = self.spec_attacherJoints.attachedImplements[implementIndex]
	if v239_ == nil then
		return nil
	else
		return v239_.jointDescIndex
	end
end

-- Local values: spec, attachedImplement
function AttacherJoints:getObjectFromImplementIndex(implementIndex)
	local v242_ = self.spec_attacherJoints.attachedImplements[implementIndex]
	if v242_ == nil then
		return nil
	else
		return v242_.object
	end
end

-- Local values: spec, jointDesc, attacherJoint, ax, ay, az, bx, by, bz, x, y, z, distance, upX, upY, upZ, dirX, dirY, dirZ, changed, interpolator, rx, ry, rz, target, parent, xDir, yDir, zDir, xUp, yUp, zUp, _, visualAlignNode
function AttacherJoints:updateAttacherJointGraphics(implement, dt, forceUpdate)
	local v247_ = self.spec_attacherJoints
	if implement.object == nil then
		::l2::
		return
	end
	local v248_ = v247_.attacherJoints[implement.jointDescIndex]
	local v249_ = implement.object:getInputAttacherJointByJointDescIndex(implement.inputJointDescIndex)
	if v248_.bottomArm == nil then
		::l4::
		if v248_.topArm ~= nil and (not implement.attachingIsInProgress and v249_.topReferenceNode ~= nil) then
			v248_.topArm:update(dt, v249_.topReferenceNode)
		end
		if v248_.visualAlignNodes ~= nil then
			for _, v250_ in ipairs(v248_.visualAlignNodes) do
				self:updateMovingPartByNode(v250_.node, dt)
			end
		end
		goto l2
	end
	local v251_, v252_, v253_ = getWorldTranslation(v248_.bottomArm.rotationNode)
	local v254_, v255_, v256_ = getWorldTranslation(v249_.node)
	local v257_, v258_, v259_ = worldDirectionToLocal(getParent(v248_.bottomArm.rotationNode), v254_ - v251_, v255_ - v252_, v256_ - v253_)
	local v260_ = MathUtil.vector3Length(v257_, v258_, v259_)
	local v261_, v262_
	if math.abs(v258_) > 0.99 * v260_ then
		v261_ = 0
		if v258_ > 0 then
			v262_ = 1
		else
			v262_ = -1
		end
	else
		v261_ = 1
		v262_ = 0
	end
	local v263_ = v258_ * v248_.bottomArm.zScale
	local v264_ = v259_ * v248_.bottomArm.zScale
	local v265_ = v248_.bottomArm.lockDirection and 0 or v257_ * v248_.bottomArm.zScale
	local v266_ = false
	local v267_ = v248_.bottomArm.lastDirection[1] - v265_
	if math.abs(v267_) <= 0.001 then
		local v268_ = v248_.bottomArm.lastDirection[2] - v263_
		if math.abs(v268_) <= 0.001 then
			local v269_ = v248_.bottomArm.lastDirection[3] - v264_
			if math.abs(v269_) <= 0.001 then
				::l14::
				if implement.attachingIsInProgress then
					if v266_ then
						if implement.bottomArmInterpolating then
							local v270_, v271_, v272_ = getRotation(v248_.bottomArm.rotationNodeDir)
							local v273_ = implement.bottomArmInterpolator:getTarget()
							v273_[1] = v270_
							v273_[2] = v271_
							v273_[3] = v272_
							implement.bottomArmInterpolator:updateSpeed()
						else
							local v274_ = ValueInterpolator.new(v248_.bottomArm.interpolatorKey, v248_.bottomArm.interpolatorGet, v248_.bottomArm.interpolatorSet, { getRotation(v248_.bottomArm.rotationNodeDir) }, AttacherJoints.SMOOTH_ATTACH_TIME)
							if v274_ ~= nil then
								v274_:setDeleteListenerObject(self)
								v274_:setFinishedFunc(v248_.bottomArm.interpolatorFinished, v248_.bottomArm)
								v248_.bottomArm.bottomArmInterpolating = true
								implement.bottomArmInterpolating = true
								implement.bottomArmInterpolator = v274_
							end
						end
					end
				elseif implement.bottomArmInterpolator ~= nil then
					ValueInterpolator.removeInterpolator(v248_.bottomArm.interpolatorKey)
					v248_.bottomArm.bottomArmInterpolating = false
					implement.bottomArmInterpolating = false
					implement.bottomArmInterpolator = nil
				end
				if v248_.bottomArm.translationNode ~= nil and not implement.attachingIsInProgress then
					if v248_.bottomArm.updateReferenceDistance then
						v248_.bottomArm.referenceDistance = calcDistanceFrom(v248_.bottomArm.referenceNode, v248_.bottomArm.translationNode)
					end
					setTranslation(v248_.bottomArm.translationNode, 0, 0, (v260_ - v248_.bottomArm.referenceDistance) * v248_.bottomArm.zScale)
				end
				if v248_.bottomArm.jointPositionNode ~= nil and not implement.attachingIsInProgress then
					setWorldTranslation(v248_.bottomArm.jointPositionNode, v254_, v255_, v256_)
					if self.setMovingToolDirty ~= nil then
						self:setMovingToolDirty(v248_.bottomArm.jointPositionNode, forceUpdate, dt)
					end
				end
				if self.setMovingToolDirty ~= nil then
					self:setMovingToolDirty(v248_.bottomArm.rotationNode, forceUpdate, dt)
				end
				if v249_.needsToolbar and v248_.bottomArm.toolbarNode ~= nil then
					local v275_ = getParent(v248_.bottomArm.toolbarNode)
					local _, v276_, v277_ = localDirectionToLocal(v249_.node, v248_.rootNode, 1, 0, 0)
					local v278_, v279_, v280_ = localDirectionToLocal(v248_.rootNode, v275_, 0, v276_, v277_)
					local _, v281_, v282_ = localDirectionToLocal(v249_.node, v248_.rootNode, 0, 1, 0)
					local v283_, v284_, v285_ = localDirectionToLocal(v248_.rootNode, v275_, 0, v281_, v282_)
					setDirection(v248_.bottomArm.toolbarNode, v278_, v279_, v280_, v283_, v284_, v285_)
				end
				if self.updateMovingPartByNode ~= nil then
					if v248_.bottomArm.leftNode ~= nil then
						self:updateMovingPartByNode(v248_.bottomArm.leftNode, forceUpdate, dt)
					end
					if v248_.bottomArm.rightNode ~= nil then
						self:updateMovingPartByNode(v248_.bottomArm.rightNode, forceUpdate, dt)
					end
				end
				goto l4
			end
		end
	end
	if implement.attachingIsInProgress then
		setDirection(v248_.bottomArm.rotationNodeDir, v265_, v263_, v264_, 0, v261_, v262_)
	else
		setDirection(v248_.bottomArm.rotationNode, v265_, v263_, v264_, 0, v261_, v262_)
	end
	v248_.bottomArm.lastDirection[1] = v265_
	v248_.bottomArm.lastDirection[2] = v263_
	v248_.bottomArm.lastDirection[3] = v264_
	v266_ = true
	goto l14
end

-- Local values: objectAttacherJoint, lowerDistanceToGround, upperDistanceToGround, upperAlpha, lowerAlpha, checkData, i, heightNode, offX, offY, offZ, _, y, _, delta, _, hy, _, checkData
function AttacherJoints:calculateAttacherJointMoveUpperLowerAlpha(jointDesc, object, initial)
	local v290_ = object.spec_attachable.attacherJoint
	if jointDesc.allowsLowering then
		local v291_ = jointDesc.lowerDistanceToGround
		local v292_ = jointDesc.upperDistanceToGround
		local v293_ = nil
		local v294_ = nil
		if #v290_.heightNodes > 0 and jointDesc.rotationNode ~= nil then
			local v295_ = self.spec_attacherJoints.groundHeightNodeCheckData
			if initial then
				v295_.heightNodes = v290_.heightNodes
				v295_.jointDesc = jointDesc
				v295_.objectAttacherJoint = v290_
				v295_.object = object
				v295_.index = -1
				v291_ = jointDesc.lowerDistanceToGround
				v292_ = jointDesc.upperDistanceToGround
				for v296_ = 1, #v290_.heightNodes do
					local v297_ = v290_.heightNodes[v296_]
					local v298_, v299_, v300_ = localToLocal(v297_.node, v297_.attacherJointNode, 0, 0, 0)
					self:updateAttacherJointRotationNodes(jointDesc, 1)
					local v301_ = setRotation
					local v302_ = jointDesc.jointTransform
					local v303_ = jointDesc.jointOrigRot
					v301_(v302_, unpack(v303_))
					local _, v304_, _ = localToLocal(jointDesc.jointTransform, jointDesc.rootNode, 0, 0, 0)
					local v305_ = jointDesc.lowerDistanceToGround - v304_
					local _, v306_, _ = localToLocal(jointDesc.jointTransform, jointDesc.rootNode, v298_, v299_, v300_)
					v291_ = v306_ + v305_
					self:updateAttacherJointRotationNodes(jointDesc, 0)
					local _, v307_, _ = localToLocal(jointDesc.jointTransform, jointDesc.rootNode, 0, 0, 0)
					local v308_ = jointDesc.upperDistanceToGround - v307_
					local _, v309_, _ = localToLocal(jointDesc.jointTransform, jointDesc.rootNode, v298_, v299_, v300_)
					v292_ = v309_ + v308_
				end
			elseif (jointDesc.moveAlpha or 0) > 0 then
				if v295_.index == -1 then
					v295_.index = 1
					v295_.minDistance = math.huge
					v295_.hit = false
					self:doGroundHeightNodeCheck()
				end
				if v295_.isDirty then
					v295_.isDirty = false
					self:doGroundHeightNodeCheck()
				end
				if jointDesc.upperAlpha == nil or v295_.upperAlpha == nil then
					v293_ = v295_.upperAlpha
					v294_ = v295_.lowerAlpha
				else
					v293_ = jointDesc.upperAlpha * 0.9 + v295_.upperAlpha * 0.1
					v294_ = jointDesc.lowerAlpha * 0.9 + v295_.lowerAlpha * 0.1
				end
			else
				v293_ = jointDesc.upperAlpha
				v294_ = jointDesc.lowerAlpha
			end
		end
		if v292_ == v291_ then
			v293_ = v293_ or 1
			v294_ = v294_ or 1
		else
			if not v293_ then
				local v310_ = (v290_.upperDistanceToGround - v292_) / (v291_ - v292_)
				v293_ = math.clamp(v310_, 0, 1)
			end
			if not v294_ then
				local v311_ = (v290_.lowerDistanceToGround - v292_) / (v291_ - v292_)
				v294_ = math.clamp(v311_, 0, 1)
			end
		end
		if initial then
			local v312_ = self.spec_attacherJoints.groundHeightNodeCheckData
			v312_.upperAlpha = v293_
			v312_.lowerAlpha = v294_
		end
		if v290_.allowsLowering and jointDesc.allowsLowering then
			return v293_, v294_
		elseif v290_.isDefaultLowered then
			return v294_, v294_
		else
			return v293_, v293_
		end
	elseif v290_.isDefaultLowered then
		return 1, 1
	else
		return 0, 0
	end
end

-- Local values: checkData, heightNode, offX, offY, offZ, lWx, lWy, lWz, uWx, uWy, uWz, dirX, dirY, dirZ, distance
function AttacherJoints:doGroundHeightNodeCheck()
	local v314_ = self.spec_attacherJoints.groundHeightNodeCheckData
	local v315_ = v314_.heightNodes[v314_.index]
	if v315_ == nil or not v314_.object:getIsAttacherJointHeightNodeActive(v315_) then
		v314_.index = v314_.index + 1
		if v314_.index > #v314_.heightNodes then
			self:finishGroundHeightNodeCheck()
		else
			v314_.isDirty = true
		end
	else
		local v316_, v317_, v318_ = localToLocal(v315_.node, v315_.attacherJointNode, 0, 0, 0)
		self:updateAttacherJointRotationNodes(v314_.jointDesc, 1)
		local v319_, v320_, v321_ = localToWorld(v314_.jointDesc.jointTransformOrig, v316_, v317_, v318_)
		self:updateAttacherJointRotationNodes(v314_.jointDesc, 0)
		local v322_, v323_, v324_ = localToWorld(v314_.jointDesc.jointTransformOrig, v316_, v317_, v318_)
		local v325_ = v319_ - v322_
		local v326_ = v320_ - v323_
		local v327_ = v321_ - v324_
		local v328_ = MathUtil.vector3Length(v325_, v326_, v327_)
		local v329_, v330_, v331_ = MathUtil.vector3Normalize(v325_, v326_, v327_)
		v314_.currentRaycastDistance = v328_
		v314_.currentRaycastWorldPos[1] = v322_
		v314_.currentRaycastWorldPos[2] = v323_
		v314_.currentRaycastWorldPos[3] = v324_
		v314_.currentRaycastWorldDir[1] = v329_
		v314_.currentRaycastWorldDir[2] = v330_
		v314_.currentRaycastWorldDir[3] = v331_
		local v332_ = v314_.currentJointTransformPos
		local v333_ = v314_.currentJointTransformPos
		local v334_ = v314_.currentJointTransformPos
		local v335_, v336_, v337_ = getWorldTranslation(v314_.jointDesc.jointTransform)
		v332_[1] = v335_
		v333_[2] = v336_
		v334_[3] = v337_
		local v338_ = v328_ + v314_.objectAttacherJoint.lowerDistanceToGround
		local v339_ = v314_.minDistance
		v314_.minDistance = math.min(v339_, v338_)
		raycastAllAsync(v322_, v323_, v324_, v329_, v330_, v331_, v338_, "groundHeightNodeCheckCallback", self, CollisionFlag.TERRAIN)
		self:updateAttacherJointRotationNodes(v314_.jointDesc, v314_.jointDesc.moveAlpha or 0)
		return
	end
end

-- Local values: checkData, upperAlpha, lowerAlpha, uWx, uWy, uWz, dirX, dirY, dirZ, x1, y1, z1, x3, y3, z3, straightToCenter, circleToCenter, straightOffset, _, h1, h2, angle, offset
function AttacherJoints:finishGroundHeightNodeCheck()
	local v341_ = self.spec_attacherJoints.groundHeightNodeCheckData
	if v341_.minDistance ~= math.huge then
		if not v341_.hit then
			v341_.raycastDistance = v341_.currentRaycastDistance
			v341_.raycastWorldPos[1] = v341_.currentRaycastWorldPos[1]
			v341_.raycastWorldPos[2] = v341_.currentRaycastWorldPos[2]
			v341_.raycastWorldPos[3] = v341_.currentRaycastWorldPos[3]
			v341_.raycastWorldDir[1] = v341_.currentRaycastWorldDir[1]
			v341_.raycastWorldDir[2] = v341_.currentRaycastWorldDir[2]
			v341_.raycastWorldDir[3] = v341_.currentRaycastWorldDir[3]
			v341_.jointTransformPos[1] = v341_.currentJointTransformPos[1]
			v341_.jointTransformPos[2] = v341_.currentJointTransformPos[2]
			v341_.jointTransformPos[3] = v341_.currentJointTransformPos[3]
		end
		local v342_ = (v341_.minDistance - v341_.objectAttacherJoint.upperDistanceToGround) / v341_.raycastDistance
		local v343_ = (v341_.minDistance - v341_.objectAttacherJoint.lowerDistanceToGround) / v341_.raycastDistance
		local v344_ = v341_.raycastWorldPos[1]
		local v345_ = v341_.raycastWorldPos[2]
		local v346_ = v341_.raycastWorldPos[3]
		local v347_ = v341_.raycastWorldDir[1]
		local v348_ = v341_.raycastWorldDir[2]
		local v349_ = v341_.raycastWorldDir[3]
		local v350_ = v344_ + v347_ * v341_.raycastDistance * v343_
		local v351_ = v345_ + v348_ * v341_.raycastDistance * v343_
		local v352_ = v346_ + v349_ * v341_.raycastDistance * v343_
		local v353_ = v341_.jointTransformPos[1]
		local v354_ = v341_.jointTransformPos[2]
		local v355_ = v341_.jointTransformPos[3]
		local v356_ = MathUtil.vector3Length(v350_ - v353_, v351_ - v354_, v352_ - v355_)
		local v357_ = MathUtil.vector3Length(v344_ - v353_, v345_ - v354_, v346_ - v355_) - v356_
		local _, v358_, _ = worldToLocal(self.rootNode, v350_, v351_, v352_)
		local _, v359_, _ = worldToLocal(self.rootNode, v344_, v345_, v346_)
		local v360_ = v357_ / (v359_ - v358_)
		local v361_ = math.atan(v360_)
		local v362_ = v357_ * math.sin(v361_)
		local v363_ = (v341_.minDistance - v341_.objectAttacherJoint.lowerDistanceToGround - v362_) / v341_.raycastDistance
		v341_.lowerAlpha = math.clamp(v363_, 0, 1)
		v341_.upperAlpha = math.clamp(v342_, 0, 1)
	end
	v341_.index = -1
end

-- Local values: checkData
function AttacherJoints:groundHeightNodeCheckCallback(hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	if not self.isDeleted then
		local v368_ = self.spec_attacherJoints.groundHeightNodeCheckData
		if hitObjectId ~= 0 then
			if getRigidBodyType(hitObjectId) == RigidBodyType.STATIC then
				if distance < v368_.minDistance then
					v368_.raycastDistance = v368_.currentRaycastDistance
					v368_.minDistance = distance
					v368_.hit = true
					v368_.raycastWorldPos[1] = v368_.currentRaycastWorldPos[1]
					v368_.raycastWorldPos[2] = v368_.currentRaycastWorldPos[2]
					v368_.raycastWorldPos[3] = v368_.currentRaycastWorldPos[3]
					v368_.raycastWorldDir[1] = v368_.currentRaycastWorldDir[1]
					v368_.raycastWorldDir[2] = v368_.currentRaycastWorldDir[2]
					v368_.raycastWorldDir[3] = v368_.currentRaycastWorldDir[3]
					v368_.jointTransformPos[1] = v368_.currentJointTransformPos[1]
					v368_.jointTransformPos[2] = v368_.currentJointTransformPos[2]
					v368_.jointTransformPos[3] = v368_.currentJointTransformPos[3]
				end
			elseif not isLast then
				return true
			end
		end
		v368_.index = v368_.index + 1
		if v368_.index > #v368_.heightNodes then
			self:finishGroundHeightNodeCheck()
		else
			v368_.isDirty = true
		end
		return false
	end
end

-- Local values: objectAttacherJoint, targetRot, curRot, rotDiff
function AttacherJoints:updateAttacherJointRotation(jointDesc, object)
	local v371_ = object.spec_attachable.attacherJoint
	local v372_ = MathUtil.lerp(v371_.upperRotationOffset, v371_.lowerRotationOffset, jointDesc.moveAlpha) - MathUtil.lerp(jointDesc.upperRotationOffset, jointDesc.lowerRotationOffset, jointDesc.moveAlpha)
	local v373_ = setRotation
	local v374_ = jointDesc.jointTransform
	local v375_ = jointDesc.jointOrigRot
	v373_(v374_, unpack(v375_))
	rotateAboutLocalAxis(jointDesc.jointTransform, v372_, 0, 0, 1)
end

function AttacherJoints:updateAttacherJointRotationNodes(jointDesc, alpha)
	if jointDesc.rotationNode ~= nil then
		setRotation(jointDesc.rotationNode, MathUtil.vector3ArrayLerp(jointDesc.upperRotation, jointDesc.lowerRotation, alpha))
	end
	if jointDesc.rotationNode2 ~= nil then
		setRotation(jointDesc.rotationNode2, MathUtil.vector3ArrayLerp(jointDesc.upperRotation2, jointDesc.lowerRotation2, alpha))
	end
end

-- Local values: jointDesc, implement, objectAttacherJoint, i, upperAlpha, lowerAlpha
function AttacherJoints:updateAttacherJointSettingsByObject(vehicle, updateLimit, updateRotationOffset, updateDistanceToGround)
	local v383_ = self:getAttacherJointDescFromObject(vehicle)
	local v384_ = self:getImplementByObject(vehicle)
	local v385_ = vehicle:getActiveInputAttacherJoint()
	if v383_ ~= nil and v384_ ~= nil then
		if updateLimit then
			for v386_ = 1, 3 do
				AttacherJoints.updateAttacherJointLimits(v384_, v383_, v385_, v386_)
				AttacherJoints.updateAttacherJointRotationLimit(v384_, v383_, v386_, false, v383_.moveLimitAlpha)
				AttacherJoints.updateAttacherJointTranslationLimit(v384_, v383_, v386_, false, v383_.moveLimitAlpha)
			end
		end
		if updateRotationOffset then
			self:updateAttacherJointRotation(v383_, vehicle)
			if self.isServer then
				setJointFrame(v383_.jointIndex, 0, v383_.jointTransform)
			end
		end
		if updateDistanceToGround then
			local v387_, v388_ = self:calculateAttacherJointMoveUpperLowerAlpha(v383_, vehicle)
			local v389_ = v383_.moveDefaultTime
			local v390_ = v387_ - v388_
			v383_.moveTime = v389_ * math.abs(v390_)
			v383_.upperAlpha = v387_
			v383_.lowerAlpha = v388_
			if self.isClient and self.updateDashboardValueType ~= nil then
				self:updateDashboardValueType("attacherJoints.bottomArmPositionMin")
				self:updateDashboardValueType("attacherJoints.bottomArmPositionMax")
			end
		end
	end
end

-- Local values: spec, jointDesc, bottomArm, upX, upY, upZ, wx, wy, wz, ax, ay, az, dx, dy, dz, _, _, zOffsetLeft, _, _, zOffsetRight, _, y, z, activeIndex, index, node
function AttacherJoints:setAttacherJointBottomArmWidth(jointDescIndex, width)
	local v394_ = self.spec_attacherJoints.attacherJoints[jointDescIndex]
	local v395_ = v394_.bottomArm
	if v395_ ~= nil and v395_.variableWidthAvailable ~= nil then
		width = width or v395_.defaultWidth
		if v395_.armLeftReferenceNode == nil or v395_.armRightReferenceNode == nil then
			local _, v396_, v397_ = getTranslation(v395_.armLeft)
			setTranslation(v395_.armLeft, width * 0.5, v396_, v397_)
			local _, v398_, v399_ = getTranslation(v395_.armRight)
			setTranslation(v395_.armRight, -width * 0.5, v398_, v399_)
		else
			local v400_, v401_, v402_ = localDirectionToWorld(v395_.rotationNode, 0, 1, 0)
			local v403_, v404_, v405_ = localToWorld(v395_.referenceNode, width * 0.5, 0, 0)
			local v406_, v407_, v408_ = getWorldTranslation(v395_.armLeft)
			local v409_, v410_, v411_ = MathUtil.vector3Normalize(v403_ - v406_, v404_ - v407_, v405_ - v408_)
			I3DUtil.setWorldDirection(v395_.armLeft, v409_, v410_, v411_, v400_, v401_, v402_, nil, nil, nil)
			local v412_, v413_, v414_ = localToWorld(v395_.referenceNode, -width * 0.5, 0, 0)
			local v415_, v416_, v417_ = getWorldTranslation(v395_.armRight)
			local v418_, v419_, v420_ = MathUtil.vector3Normalize(v412_ - v415_, v413_ - v416_, v414_ - v417_)
			I3DUtil.setWorldDirection(v395_.armRight, v418_, v419_, v420_, v400_, v401_, v402_, nil, nil, nil)
			local _, _, v421_ = localToLocal(v395_.armLeftReferenceNode, v395_.rotationNode, 0, 0, 0)
			local _, _, v422_ = localToLocal(v395_.armRightReferenceNode, v395_.rotationNode, 0, 0, 0)
			v395_.referenceDistance = (math.abs(v421_) + math.abs(v422_)) * 0.5
			setTranslation(v395_.referenceNode, 0, 0, -v395_.referenceDistance)
		end
		if self.setMovingToolDirty ~= nil then
			self:setMovingToolDirty(v395_.rotationNode)
		end
	end
	if v395_ ~= nil and v395_.toolbars ~= nil then
		local v423_ = AttacherJoints.getClosestLowerLinkCategoryIndex(width or v395_.defaultWidth)
		for v424_, v425_ in ipairs(v394_.bottomArm.toolbars) do
			setVisibility(v425_, v423_ == v424_ - 1)
		end
	end
end

-- Local values: attacherJoints, attacherJointDirection, attachedImplements, i, jointDesc
function AttacherJoints:attachImplementFromInfo(info)
	if info.attachable ~= nil then
		local v427_ = info.attacherVehicle.spec_attacherJoints.attacherJoints
		if v427_[info.attacherVehicleJointDescIndex].jointIndex == 0 then
			if info.attachable:getActiveInputAttacherJointDescIndex() ~= nil then
				if not info.attachable:getAllowMultipleAttachments() then
					return false
				end
				info.attachable:resolveMultipleAttachments()
			end
			if GS_IS_MOBILE_VERSION then
				local v428_ = v427_[info.attacherVehicleJointDescIndex].attacherJointDirection
				if v428_ ~= nil then
					local v429_ = info.attacherVehicle:getAttachedImplements()
					for v430_ = 1, #v429_ do
						if v428_ == v427_[v429_[v430_].jointDescIndex].attacherJointDirection then
							return false
						end
					end
				end
			end
			info.attacherVehicle:attachImplement(info.attachable, info.attachableJointDescIndex, info.attacherVehicleJointDescIndex)
			return true
		end
	end
	return false
end

-- Local values: spec, objectAttacherJoint, jointDesc, attacherJointIndex, _, visualAlignNode, i, node, i, node, allowedToHide, attacherJoints, j, widthIndexToUse, widthToUse, i, width, i, width, upperAlpha, lowerAlpha, distanceSqUpper, distanceSqLower, minYHeight, maxYHeight, lowerDistanceToGround, upperDistanceToGround, attacherHeight, ptoOutputs, ptoOutput, ptoInput, _, y, _, ptoYFactor, ptoRealHeight, ptoSize, max, min, totalDistance, factor, y, x, _, z, bottomArmJointDesc, rx, ry, rz, interpolator, isTrailerAttacher, implement, moveDown, inputAttacherJoint, selectedVehicle
function AttacherJoints:attachImplement(object, inputJointDescIndex, jointDescIndex, noEventSend, index, startLowered, noSmoothAttach, loadFromSavegame)
	local v440_ = self.spec_attacherJoints
	local v441_ = object.spec_attachable.inputAttacherJoints[inputJointDescIndex]
	local v442_ = v440_.attacherJoints[jointDescIndex]
	if v442_ == nil or v441_ == nil then
		Logging.warning("Cannot attach object \'%s\' to vehicle \'%s\'. Attacher joint \'%s\' or input attachher joint \'%s\' not found", object.configFileName, self.configFileName, jointDescIndex, inputJointDescIndex)
		return false
	end
	if self:getAttacherJointIndexFromObject(object) ~= nil then
		Logging.warning("Cannot attach object \'%s\' to vehicle \'%s\' between joints \'%d\' and \'%d\'. Joint already in use!", object.configFileName, self.configFileName, jointDescIndex, inputJointDescIndex)
		return
	end
	SpecializationUtil.raiseEvent(self, "onPreAttachImplement", object, inputJointDescIndex, jointDescIndex, loadFromSavegame)
	object:preAttach(self, inputJointDescIndex, jointDescIndex, loadFromSavegame)
	if v442_.visualAlignNodes ~= nil then
		for _, v443_ in ipairs(v442_.visualAlignNodes) do
			if not v443_.delayedOnAttach then
				self:setMovingPartReferenceNode(v443_.node, v441_.node, false)
			end
		end
	end
	if not v442_.delayedObjectChangesOnAttach then
		ObjectChangeUtil.setObjectChanges(v442_.changeObjects, true, self, self.setMovingToolDirty)
	end
	for v444_ = 1, #v442_.visualNodes do
		local v445_ = v442_.visualNodes[v444_]
		setVisibility(v445_, true)
	end
	for v446_ = 1, #v442_.hideVisuals do
		local v447_ = v442_.hideVisuals[v446_]
		local v448_ = true
		local v449_ = v440_.visualNodeToAttacherJoints[v447_]
		if v449_ ~= nil then
			for v450_ = 1, #v449_ do
				if v449_[v450_].jointIndex ~= 0 then
					v448_ = false
				end
			end
		end
		if v448_ then
			setVisibility(v447_, false)
		end
	end
	if v441_.bottomArm ~= nil and (v442_.bottomArm ~= nil and v442_.bottomArm.variableWidthAvailable) then
		local v451_ = nil
		local v452_ = nil
		for v453_ = #v441_.bottomArm.widths, 1, -1 do
			local v454_ = v441_.bottomArm.widths[v453_]
			if v442_.bottomArm.minWidth <= v454_ and v454_ <= v442_.bottomArm.maxWidth then
				v452_ = v453_
				v451_ = v454_
				break
			end
		end
		if v451_ == nil then
			for v455_ = 1, #v441_.bottomArm.widths do
				local v456_ = v441_.bottomArm.widths[v455_]
				if v456_ < v442_.bottomArm.minWidth then
					v451_ = v442_.bottomArm.minWidth
				elseif v442_.bottomArm.maxWidth < v456_ then
					v451_ = v442_.bottomArm.maxWidth
				end
			end
			v451_ = v451_ or v442_.bottomArm.maxWidth
		end
		if v452_ ~= nil then
			object:setToolBottomArmWidthByIndex(inputJointDescIndex, v452_)
		end
		self:setAttacherJointBottomArmWidth(jointDescIndex, v451_)
	end
	local v457_, v458_ = self:calculateAttacherJointMoveUpperLowerAlpha(v442_, object, true)
	local v459_ = v442_.moveDefaultTime
	local v460_ = v457_ - v458_
	v442_.moveTime = v459_ * math.abs(v460_)
	if startLowered == nil then
		startLowered = true
		if v441_.allowsLowering and v442_.allowsLowering then
			self:updateAttacherJointRotationNodes(v442_, v457_)
			local v461_ = calcDistanceSquaredFrom(v442_.jointTransform, v441_.node)
			self:updateAttacherJointRotationNodes(v442_, v458_)
			if v461_ < calcDistanceSquaredFrom(v442_.jointTransform, v441_.node) * 1.1 then
				startLowered = false
			end
			if v441_.useFoldingLoweredState then
				startLowered = object:getIsLowered()
			end
		elseif not v441_.isDefaultLowered then
			startLowered = false
		end
	end
	if noEventSend == nil or noEventSend == false then
		if g_server == nil then
			g_client:getServerConnection():sendEvent(VehicleAttachEvent.new(self, object, inputJointDescIndex, jointDescIndex, startLowered))
		else
			g_server:broadcastEvent(VehicleAttachEvent.new(self, object, inputJointDescIndex, jointDescIndex, startLowered), nil, nil, self)
		end
	end
	if v442_.transNode == nil or v441_.attacherHeight == nil then
		if v442_.transNode == nil then
			local v462_ = (v442_.jointType == AttacherJoints.JOINTTYPE_TRAILER or v442_.jointType == AttacherJoints.JOINTTYPE_TRAILERLOW) and true or v442_.jointType == AttacherJoints.JOINTTYPE_TRAILERCAR
			if self.checkPowerTakeOffCollision ~= nil then
				self:checkPowerTakeOffCollision(v442_.jointTransform, jointDescIndex, v462_)
			end
		end
	else
		local v463_ = v442_.transNodeMinY
		local v464_ = v442_.transNodeMaxY
		local v465_ = v442_.lowerDistanceToGround
		local v466_ = v442_.upperDistanceToGround
		local v467_ = v441_.attacherHeight
		if self.getOutputPowerTakeOffsByJointDescIndex ~= nil and v463_ ~= v464_ then
			local v468_ = self:getOutputPowerTakeOffsByJointDescIndex(jointDescIndex)
			if v468_ ~= nil and #v468_ > 0 then
				local v469_ = v468_[1]
				local v470_ = v469_.connectedInput
				if v470_ ~= nil then
					local _, v471_, _ = localToLocal(v469_.outputNode, v442_.rootNode, 0, 0, 0)
					local v472_ = (v471_ - v463_) / (v464_ - v463_)
					local v473_ = MathUtil.lerp(v465_, v466_, v472_)
					local v474_ = (v470_.size + v442_.transNodeHeight) * 0.5
					if v470_.aboveAttacher then
						local v475_ = v473_ - v474_
						local v476_ = math.min(v465_, v475_)
						v467_ = math.clamp(v467_, v476_, v475_)
					else
						local v477_ = v473_ + v474_
						local v478_ = math.max(v466_, v477_)
						v467_ = math.clamp(v467_, v477_, v478_)
					end
				end
			end
		end
		local v479_ = v467_ - v442_.transNodeOffsetY
		local v480_ = math.clamp(v479_, v465_, v466_)
		local v481_ = v466_ - v465_
		local v482_
		if v481_ > 0 then
			local v483_ = (v480_ - v465_) / v481_
			v482_ = math.clamp(v483_, 0, 1)
		else
			v482_ = 0
		end
		local v484_ = MathUtil.lerp(v463_, v464_, v482_)
		local v485_, _, v486_ = getTranslation(v442_.transNode)
		local _, v487_, _ = localToLocal(v442_.rootNode, getParent(v442_.transNode), 0, v484_, 0)
		setTranslation(v442_.transNode, v485_, v487_, v486_)
		if v442_.transNodeDependentBottomArm ~= nil and v487_ <= v442_.transNodeDependentBottomArmThreshold then
			local v488_ = v442_.transNodeDependentBottomArmAttacherJoint
			local v489_ = v442_.transNodeDependentBottomArmRotation[1]
			local v490_ = v442_.transNodeDependentBottomArmRotation[2]
			local v491_ = v442_.transNodeDependentBottomArmRotation[3]
			if loadFromSavegame then
				setRotation(v488_.bottomArm.rotationNode, v489_, v490_, v491_)
				if self.setMovingToolDirty ~= nil then
					self:setMovingToolDirty(v488_.bottomArm.rotationNode)
				end
			else
				local v492_ = ValueInterpolator.new(v488_.bottomArm.interpolatorKey, v488_.bottomArm.interpolatorGet, v488_.bottomArm.interpolatorSet, { v489_, v490_, v491_ }, AttacherJoints.SMOOTH_ATTACH_TIME * 2)
				if v492_ ~= nil then
					v492_:setDeleteListenerObject(self)
					v492_:setFinishedFunc(v488_.bottomArm.interpolatorFinished, v488_.bottomArm)
					v488_.bottomArm.bottomArmInterpolating = true
				end
			end
		end
	end
	local v493_ = {
		["object"] = object,
		["jointDescIndex"] = jointDescIndex,
		["inputJointDescIndex"] = inputJointDescIndex,
		["loadFromSavegame"] = loadFromSavegame,
		["isDetaching"] = false
	}
	v442_.upperAlpha = v457_
	v442_.lowerAlpha = v458_
	v442_.moveAlpha = v457_
	v442_.moveLimitAlpha = 0
	if startLowered then
		v442_.moveAlpha = v458_
		v442_.moveLimitAlpha = 1
	end
	self:updateAttacherJointRotationNodes(v442_, v442_.moveAlpha)
	self:updateAttacherJointRotation(v442_, object)
	self:createAttachmentJoint(v493_, noSmoothAttach)
	local v494_ = v441_.isDefaultLowered or v442_.isDefaultLowered
	if v441_.useFoldingLoweredState or loadFromSavegame then
		v494_ = startLowered
	end
	v442_.moveDown = v494_
	v442_.isMoving = true
	object:setLowered(v442_.moveDown)
	if index == nil then
		local v495_ = v440_.attachedImplements
		table.insert(v495_, v493_)
	else
		v440_.attachedImplements[index] = v493_
	end
	self:updateAttacherJointGraphics(v493_, 0)
	self:attachAdditionalAttachment(v442_, v441_, object)
	self.rootVehicle:updateSelectableObjects()
	self:updateVehicleChain()
	local v496_
	if v493_.object:getActiveInputAttacherJoint().forceSelection then
		v496_ = v493_.object
	else
		v496_ = nil
	end
	self.rootVehicle:setSelectedVehicle(v496_)
	if not v493_.attachingIsInProgress then
		if v493_.object.spec_attachable.attacherJoint.hardAttach and self:getIsHardAttachAllowed(v493_.jointDescIndex) then
			self:hardAttachImplement(v493_)
		end
		self:postAttachImplement(v493_)
	end
	AttacherJoints.updateRequiredTopLightsState(self)
	if self.setTipSideUpdateDirty ~= nil then
		self:setTipSideUpdateDirty()
	end
	if self.isClient and self.updateDashboardValueType ~= nil then
		self:updateDashboardValueType("attacherJoints.bottomArmPositionMin")
		self:updateDashboardValueType("attacherJoints.bottomArmPositionMax")
	end
	return true
end

-- Local values: spec, object, inputJointDescIndex, jointDescIndex, objectAttacherJoint, jointDesc, _, visualAlignNode, data, rootVehicle
function AttacherJoints:postAttachImplement(implement)
	local v499_ = self.spec_attacherJoints
	local v500_ = implement.object
	local v501_ = implement.inputJointDescIndex
	local v502_ = implement.jointDescIndex
	local v503_ = v500_.spec_attachable.inputAttacherJoints[v501_]
	local v504_ = v499_.attacherJoints[v502_]
	if v503_.topReferenceNode ~= nil and v504_.topArm ~= nil then
		v504_.topArm:setIsActive(true)
	end
	if v504_.bottomArm ~= nil then
		if v504_.bottomArm.toggleVisibility then
			setVisibility(v504_.bottomArm.rotationNode, true)
		end
		if v503_.needsToolbar and v504_.bottomArm.toolbarNode ~= nil then
			setVisibility(v504_.bottomArm.toolbarNode, true)
		end
		if v504_.bottomArm.leftNode ~= nil and v503_.bottomArmLeftNode ~= nil then
			self:setMovingPartReferenceNode(v504_.bottomArm.leftNode, v503_.bottomArmLeftNode, false)
		end
		if v504_.bottomArm.rightNode ~= nil and v503_.bottomArmRightNode ~= nil then
			self:setMovingPartReferenceNode(v504_.bottomArm.rightNode, v503_.bottomArmRightNode, false)
		end
	end
	if v504_.visualAlignNodes ~= nil then
		for _, v505_ in ipairs(v504_.visualAlignNodes) do
			if v505_.delayedOnAttach then
				self:setMovingPartReferenceNode(v505_.node, v503_.node, false)
			end
		end
	end
	if v504_.delayedObjectChangesOnAttach then
		ObjectChangeUtil.setObjectChanges(v504_.changeObjects, true, self, self.setMovingToolDirty)
	end
	if not implement.loadFromSavegame then
		self:playAttachSound(v504_)
	end
	self:updateAttacherJointGraphics(implement, 0)
	SpecializationUtil.raiseEvent(self, "onPostAttachImplement", v500_, v501_, v502_, implement.loadFromSavegame)
	v500_:postAttach(self, v501_, v502_, implement.loadFromSavegame)
	local v506_ = {
		["attacherVehicle"] = self,
		["attachedVehicle"] = implement.object,
		["loadFromSavegame"] = implement.loadFromSavegame
	}
	self.rootVehicle:raiseStateChange(VehicleStateChange.ATTACH, v506_)
end

-- Local values: spec, jointDesc, objectAttacherJoint, rootVehicle, xNew, yNew, zNew, rx, ry, rz, x, y, z, x1, y1, z1, x2, y2, z2, constr, _, dx, dy, dz, dirX, dirY, dirZ, rX, rY, rZ, smoothAttachTime, i, i, rotLimit, transLimit, limitRot, limitTrans, rotLimitDown, rotLimitUp, transLimitDown, transLimitUp, _, component, springX, springY, springZ, dampingX, dampingY, dampingZ, forceLimitX, forceLimitY, forceLimitZ
function AttacherJoints:createAttachmentJoint(implement, noSmoothAttach)
	local v510_ = self.spec_attacherJoints.attacherJoints[implement.jointDescIndex]
	local v511_ = implement.object.spec_attachable.inputAttacherJoints[implement.inputJointDescIndex]
	if self.isServer and v511_ ~= nil then
		if (getRigidBodyType(v510_.rootNode) == RigidBodyType.DYNAMIC or getRigidBodyType(v510_.rootNode) == RigidBodyType.KINEMATIC) and (getRigidBodyType(v511_.rootNode) == RigidBodyType.DYNAMIC or getRigidBodyType(v511_.rootNode) == RigidBodyType.KINEMATIC) then
			if (g_currentMission:getNodeObject(v510_.rootNode) or self).isAddedToPhysics and implement.object.isAddedToPhysics then
				local v512_ = v510_.jointOrigTrans[1] + v510_.jointPositionOffset[1]
				local v513_ = v510_.jointOrigTrans[2] + v510_.jointPositionOffset[2]
				local v514_ = v510_.jointOrigTrans[3] + v510_.jointPositionOffset[3]
				local v515_, v516_, v517_ = getRotation(v510_.jointTransform)
				setTranslation(v510_.jointTransform, v510_.jointOrigTrans[1], v510_.jointOrigTrans[2], v510_.jointOrigTrans[3])
				setRotation(v510_.jointTransform, v510_.jointOrigRot[1], v510_.jointOrigRot[2], v510_.jointOrigRot[3])
				local v518_, v519_, v520_ = localToWorld(getParent(v510_.jointTransform), v512_, v513_, v514_)
				local v521_, v522_, v523_ = worldToLocal(v510_.jointTransform, v518_, v519_, v520_)
				setTranslation(v510_.jointTransform, v512_, v513_, v514_)
				setRotation(v510_.jointTransform, v515_, v516_, v517_)
				local v524_, v525_, v526_ = localToWorld(v511_.node, v521_, v522_, v523_)
				local v527_, v528_, v529_ = worldToLocal(getParent(v511_.node), v524_, v525_, v526_)
				setTranslation(v511_.node, v527_, v528_, v529_)
				local v530_ = JointConstructor.new()
				v530_:setActors(v510_.rootNode, v511_.rootNode)
				v530_:setJointTransforms(v510_.jointTransform, v511_.node)
				implement.jointRotLimit = {}
				implement.jointTransLimit = {}
				implement.lowerRotLimit = {}
				implement.lowerTransLimit = {}
				implement.upperRotLimit = {}
				implement.upperTransLimit = {}
				if noSmoothAttach == nil or not noSmoothAttach then
					local v531_, v532_, v533_ = localToLocal(v511_.node, v510_.jointTransform, 0, 0, 0)
					local _, v534_, v535_ = localDirectionToLocal(v511_.node, v510_.jointTransform, 0, 1, 0)
					local v536_ = math.atan2(v535_, v534_)
					local v537_, _, v538_ = localDirectionToLocal(v511_.node, v510_.jointTransform, 0, 0, 1)
					local v539_ = math.atan2(v537_, v538_)
					local v540_, v541_, _ = localDirectionToLocal(v511_.node, v510_.jointTransform, 1, 0, 0)
					local v542_ = math.atan2(v541_, v540_)
					local v543_ = v511_.smoothAttachTime or AttacherJoints.SMOOTH_ATTACH_TIME
					implement.attachingTransLimit = { math.abs(v531_), math.abs(v532_), (math.abs(v533_)) }
					implement.attachingRotLimit = { math.abs(v536_), math.abs(v539_), (math.abs(v542_)) }
					implement.attachingTransLimitSpeed = {}
					implement.attachingRotLimitSpeed = {}
					for v544_ = 1, 3 do
						implement.attachingTransLimitSpeed[v544_] = implement.attachingTransLimit[v544_] / v543_
						implement.attachingRotLimitSpeed[v544_] = implement.attachingRotLimit[v544_] / v543_
					end
					implement.attachingIsInProgress = true
				else
					implement.attachingTransLimit = { 0, 0, 0 }
					implement.attachingRotLimit = { 0, 0, 0 }
				end
				implement.rotLimitThreshold = v511_.rotLimitThreshold or 0
				implement.transLimitThreshold = v511_.transLimitThreshold or 0
				for v545_ = 1, 3 do
					local v546_, v547_ = AttacherJoints.updateAttacherJointLimits(implement, v510_, v511_, v545_)
					if noSmoothAttach == nil or not noSmoothAttach then
						local v548_ = implement.attachingRotLimit[v545_]
						v546_ = math.max(v546_, v548_)
						local v549_ = implement.attachingTransLimit[v545_]
						v547_ = math.max(v547_, v549_)
					end
					local v550_ = -v546_
					local v551_
					if v545_ == 3 then
						if v510_.lockDownRotLimit then
							local v552_ = -implement.attachingRotLimit[v545_]
							v550_ = math.min(v552_, 0)
						end
						if v510_.lockUpRotLimit then
							local v553_ = implement.attachingRotLimit[v545_]
							v551_ = math.max(v553_, 0)
						else
							v551_ = v546_
						end
					else
						v551_ = v546_
					end
					v530_:setRotationLimit(v545_ - 1, v550_, v551_)
					implement.jointRotLimit[v545_] = v546_
					local v554_ = -v547_
					local v555_
					if v545_ == 2 then
						if v510_.lockDownTransLimit then
							local v556_ = -implement.attachingTransLimit[v545_]
							v554_ = math.min(v556_, 0)
						end
						if v510_.lockUpTransLimit then
							local v557_ = implement.attachingTransLimit[v545_]
							v555_ = math.max(v557_, 0)
						else
							v555_ = v547_
						end
					else
						v555_ = v547_
					end
					v530_:setTranslationLimit(v545_ - 1, true, v554_, v555_)
					implement.jointTransLimit[v545_] = v547_
				end
				if v510_.enableCollision then
					v530_:setEnableCollision(true)
				else
					for _, v558_ in pairs(self.components) do
						if v558_.node ~= v510_.rootNodeBackup and not v558_.collideWithAttachables then
							setPairCollision(v558_.node, v511_.rootNode, false)
						end
					end
				end
				local v559_ = v510_.rotLimitSpring[1]
				local v560_ = v511_.rotLimitSpring[1]
				local v561_ = math.max(v559_, v560_)
				local v562_ = v510_.rotLimitSpring[2]
				local v563_ = v511_.rotLimitSpring[2]
				local v564_ = math.max(v562_, v563_)
				local v565_ = v510_.rotLimitSpring[3]
				local v566_ = v511_.rotLimitSpring[3]
				local v567_ = math.max(v565_, v566_)
				local v568_ = v510_.rotLimitDamping[1]
				local v569_ = v511_.rotLimitDamping[1]
				local v570_ = math.max(v568_, v569_)
				local v571_ = v510_.rotLimitDamping[2]
				local v572_ = v511_.rotLimitDamping[2]
				local v573_ = math.max(v571_, v572_)
				local v574_ = v510_.rotLimitDamping[3]
				local v575_ = v511_.rotLimitDamping[3]
				local v576_ = math.max(v574_, v575_)
				local v577_ = Utils.getMaxJointForceLimit(v510_.rotLimitForceLimit[1], v511_.rotLimitForceLimit[1])
				local v578_ = Utils.getMaxJointForceLimit(v510_.rotLimitForceLimit[2], v511_.rotLimitForceLimit[2])
				local v579_ = Utils.getMaxJointForceLimit(v510_.rotLimitForceLimit[3], v511_.rotLimitForceLimit[3])
				v530_:setRotationLimitSpring(v561_, v570_, v564_, v573_, v567_, v576_)
				v530_:setRotationLimitForceLimit(v577_, v578_, v579_)
				local v580_ = v510_.transLimitSpring[1]
				local v581_ = v511_.transLimitSpring[1]
				local v582_ = math.max(v580_, v581_)
				local v583_ = v510_.transLimitSpring[2]
				local v584_ = v511_.transLimitSpring[2]
				local v585_ = math.max(v583_, v584_)
				local v586_ = v510_.transLimitSpring[3]
				local v587_ = v511_.transLimitSpring[3]
				local v588_ = math.max(v586_, v587_)
				local v589_ = v510_.transLimitDamping[1]
				local v590_ = v511_.transLimitDamping[1]
				local v591_ = math.max(v589_, v590_)
				local v592_ = v510_.transLimitDamping[2]
				local v593_ = v511_.transLimitDamping[2]
				local v594_ = math.max(v592_, v593_)
				local v595_ = v510_.transLimitDamping[3]
				local v596_ = v511_.transLimitDamping[3]
				local v597_ = math.max(v595_, v596_)
				local v598_ = Utils.getMaxJointForceLimit(v510_.transLimitForceLimit[1], v511_.transLimitForceLimit[1])
				local v599_ = Utils.getMaxJointForceLimit(v510_.transLimitForceLimit[2], v511_.transLimitForceLimit[2])
				local v600_ = Utils.getMaxJointForceLimit(v510_.transLimitForceLimit[3], v511_.transLimitForceLimit[3])
				v530_:setTranslationLimitSpring(v582_, v591_, v585_, v594_, v588_, v597_)
				v530_:setTranslationLimitForceLimit(v598_, v599_, v600_)
				v510_.jointIndex = v530_:finalize()
				local v601_ = setTranslation
				local v602_ = v511_.node
				local v603_ = v511_.jointOrigTrans
				v601_(v602_, unpack(v603_))
			end
		else
			return
		end
	else
		v510_.jointIndex = 1
		return
	end
end

-- Local values: spec, implements, attachedImplements, i, impl, object, jointDescIndex, jointDesc, inputJointDescIndex, moveDown, i, attacherJoint, implementJoint, baseVehicleComponentNode, attachedVehicleComponentNode, wasAddedToPhysics, currentVehicle, dirX, dirY, dirZ, upX, upY, upZ, x, y, z, currentVehicle, _, attacherJointToUpdate, _, impl
function AttacherJoints:hardAttachImplement(implement)
	local v606_ = self.spec_attacherJoints
	local v607_ = {}
	local v608_
	if implement.object.getAttachedImplements == nil then
		v608_ = nil
	else
		v608_ = implement.object:getAttachedImplements()
	end
	if v608_ ~= nil then
		for v609_ = 1, #v608_ do
			local v610_ = v608_[v609_]
			local v611_ = v610_.object
			local v612_ = v610_.jointDescIndex
			local v613_ = implement.object.spec_attacherJoints.attacherJoints[v612_]
			local v614_ = {
				["object"] = v611_,
				["implementIndex"] = v609_,
				["jointDescIndex"] = v612_,
				["inputJointDescIndex"] = v611_.spec_attachable.inputAttacherJointDescIndex,
				["moveDown"] = v613_.moveDown
			}
			table.insert(v607_, v614_)
		end
		for _ = 1, #v608_ do
			implement.object:detachImplement(1, true)
		end
	end
	local v615_ = v606_.attacherJoints[implement.jointDescIndex]
	local v616_ = implement.object.spec_attachable.attacherJoint
	local v617_ = self:getParentComponent(v615_.jointTransform)
	local v618_ = implement.object:getParentComponent(implement.object.spec_attachable.attacherJoint.node)
	local v619_ = self.isAddedToPhysics
	if v619_ then
		local v620_ = self
		while self ~= nil do
			self:removeFromPhysics()
			self = self.attacherVehicle
		end
		implement.object:removeFromPhysics()
		self = v620_
	end
	if v606_.attacherVehicle == nil then
		setIsCompound(v617_, true)
	end
	setIsCompoundChild(v618_, true)
	local v621_, v622_, v623_ = localDirectionToLocal(v618_, v616_.node, 0, 0, 1)
	local v624_, v625_, v626_ = localDirectionToLocal(v618_, v616_.node, 0, 1, 0)
	setDirection(v618_, v621_, v622_, v623_, v624_, v625_, v626_)
	local v627_, v628_, v629_ = localToLocal(v618_, v616_.node, 0, 0, 0)
	setTranslation(v618_, v627_, v628_, v629_)
	link(v615_.jointTransform, v618_)
	if v616_.visualNode ~= nil and v615_.jointTransformVisual ~= nil then
		local v630_, v631_, v632_ = localDirectionToLocal(v616_.visualNode, v616_.node, 0, 0, 1)
		local v633_, v634_, v635_ = localDirectionToLocal(v616_.visualNode, v616_.node, 0, 1, 0)
		setDirection(v616_.visualNode, v630_, v631_, v632_, v633_, v634_, v635_)
		local v636_, v637_, v638_ = localToLocal(v616_.visualNode, v616_.node, 0, 0, 0)
		setTranslation(v616_.visualNode, v636_, v637_, v638_)
		link(v615_.jointTransformVisual, v616_.visualNode)
	end
	implement.object.spec_attachable.isHardAttached = true
	if v619_ then
		local v639_ = self
		while self ~= nil do
			self:addToPhysics()
			self = self.attacherVehicle
		end
		self = v639_
	end
	for _, v640_ in pairs(implement.object.spec_attacherJoints.attacherJoints) do
		v640_.rootNode = v617_
	end
	for _, v641_ in pairs(v607_) do
		implement.object:attachImplement(v641_.object, v641_.inputJointDescIndex, v641_.jointDescIndex, true, v641_.implementIndex, v641_.moveDown, true)
	end
	if self.isServer then
		self:setMassDirty()
		self:raiseDirtyFlags(self.vehicleDirtyFlag)
	end
	return true
end

-- Local values: _, attacherJoint, implementJoint, attachedVehicleComponentNode, wasAddedToPhysics, currentVehicle, x, y, z, dirX, dirY, dirZ, upX, upY, upZ, currentVehicle
function AttacherJoints:hardDetachImplement(implement)
	for _, v644_ in pairs(implement.object.spec_attacherJoints.attacherJoints) do
		v644_.rootNode = v644_.rootNodeBackup
	end
	local v645_ = implement.object.spec_attachable.attacherJoint
	local v646_ = implement.object:getParentComponent(v645_.node)
	local v647_ = self.isAddedToPhysics
	if v647_ then
		local v648_ = self
		while self ~= nil do
			self:removeFromPhysics()
			self = self.attacherVehicle
		end
		self = v648_
	end
	setIsCompound(v646_, true)
	local v649_, v650_, v651_ = getWorldTranslation(v646_)
	setTranslation(v646_, v649_, v650_, v651_)
	local v652_, v653_, v654_ = localDirectionToWorld(implement.object.rootNode, 0, 0, 1)
	local v655_, v656_, v657_ = localDirectionToWorld(implement.object.rootNode, 0, 1, 0)
	setDirection(v646_, v652_, v653_, v654_, v655_, v656_, v657_)
	link(getRootNode(), v646_)
	if v645_.visualNode ~= nil and getParent(v645_.visualNode) ~= v645_.visualNodeData.parent then
		link(v645_.visualNodeData.parent, v645_.visualNode, v645_.visualNodeData.index)
		setRotation(v645_.visualNode, v645_.visualNodeData.rotation[1], v645_.visualNodeData.rotation[2], v645_.visualNodeData.rotation[3])
		setTranslation(v645_.visualNode, v645_.visualNodeData.translation[1], v645_.visualNodeData.translation[2], v645_.visualNodeData.translation[3])
	end
	if v647_ then
		local v658_ = self
		while self ~= nil do
			self:addToPhysics()
			self = self.attacherVehicle
		end
		implement.object:addToPhysics()
		self = v658_
	end
	implement.object.spec_attachable.isHardAttached = false
	if self.isServer then
		self:setMassDirty()
		self:raiseDirtyFlags(self.vehicleDirtyFlag)
	end
	return true
end

-- Local values: spec, implement, implement, jointDesc, bottomArmJointDesc, interpolator, _, component, attacherJoint, i, node, allowedToShow, attacherJoints, j, i, node, hideNode, attacherJoints, j, object, interpolator, attacherJoint, _, visualAlignNode, data, rootVehicle, nextImplement
function AttacherJoints:detachImplement(implementIndex, noEventSend)
	local v662_ = self.spec_attacherJoints
	if noEventSend == nil or noEventSend == false then
		if g_server == nil then
			local v663_ = v662_.attachedImplements[implementIndex]
			if v663_.object ~= nil then
				g_client:getServerConnection():sendEvent(VehicleDetachEvent.new(self, v663_.object))
			end
			return
		end
		g_server:broadcastEvent(VehicleDetachEvent.new(self, v662_.attachedImplements[implementIndex].object), nil, nil, self)
	end
	local v664_ = v662_.attachedImplements[implementIndex]
	v664_.isDetaching = true
	SpecializationUtil.raiseEvent(self, "onPreDetachImplement", v664_)
	v664_.object:preDetach(self, v664_)
	local v_u_665_
	if v664_.object == nil then
		v_u_665_ = nil
	else
		v_u_665_ = v662_.attacherJoints[v664_.jointDescIndex]
		if v_u_665_.transNode ~= nil then
			local v666_ = setTranslation
			local v667_ = v_u_665_.transNode
			local v668_ = v_u_665_.transNodeOrgTrans
			v666_(v667_, unpack(v668_))
			if v_u_665_.transNodeDependentBottomArm ~= nil then
				local v669_ = v_u_665_.transNodeDependentBottomArmAttacherJoint
				local v670_ = ValueInterpolator.new(v669_.bottomArm.interpolatorKey, v669_.bottomArm.interpolatorGet, v669_.bottomArm.interpolatorSet, { v669_.bottomArm.rotX, v669_.bottomArm.rotY, v669_.bottomArm.rotZ }, AttacherJoints.SMOOTH_ATTACH_TIME * 2)
				if v670_ ~= nil then
					v670_:setDeleteListenerObject(self)
					v670_:setFinishedFunc(v669_.bottomArm.interpolatorFinished, v669_.bottomArm)
					v669_.bottomArm.bottomArmInterpolating = true
				end
			end
		end
		if not v664_.object.spec_attachable.isHardAttached and self.isServer then
			if v_u_665_.jointIndex ~= 0 then
				removeJoint(v_u_665_.jointIndex)
			end
			if not v_u_665_.enableCollision then
				for _, v671_ in pairs(self.components) do
					if v671_.node ~= v_u_665_.rootNodeBackup and not v671_.collideWithAttachables then
						local v672_ = v664_.object:getActiveInputAttacherJoint()
						setPairCollision(v671_.node, v672_.rootNode, true)
					end
				end
			end
		end
		v_u_665_.jointIndex = 0
		self:setAttacherJointBottomArmWidth(v664_.jointDescIndex, nil)
	end
	if not v_u_665_.delayedObjectChanges or v_u_665_.bottomArm == nil then
		ObjectChangeUtil.setObjectChanges(v_u_665_.changeObjects, false, self, self.setMovingToolDirty)
	end
	for v673_ = 1, #v_u_665_.hideVisuals do
		local v674_ = v_u_665_.hideVisuals[v673_]
		local v675_ = true
		local v676_ = v662_.hideVisualNodeToAttacherJoints[v674_]
		if v676_ ~= nil then
			for v677_ = 1, #v676_ do
				if v676_[v677_].jointIndex ~= 0 then
					v675_ = false
				end
			end
		end
		if v675_ then
			setVisibility(v674_, true)
		end
	end
	for v678_ = 1, #v_u_665_.visualNodes do
		local v679_ = v_u_665_.visualNodes[v678_]
		local v680_ = false
		local v681_ = v662_.hideVisualNodeToAttacherJoints[v679_]
		if v681_ ~= nil then
			for v682_ = 1, #v681_ do
				if v681_[v682_].jointIndex ~= 0 then
					v680_ = true
				end
			end
		end
		if v680_ then
			setVisibility(v679_, false)
		end
	end
	if v664_.object ~= nil then
		local v683_ = v664_.object
		if v683_.spec_attachable.isHardAttached then
			self:hardDetachImplement(v664_)
		end
		if self.isClient then
			if v_u_665_.topArm ~= nil then
				v_u_665_.topArm:setIsActive(false)
			end
			if v_u_665_.bottomArm ~= nil then
				local v684_ = ValueInterpolator.new(v_u_665_.bottomArm.interpolatorKey, v_u_665_.bottomArm.interpolatorGet, v_u_665_.bottomArm.interpolatorSet, { v_u_665_.bottomArm.rotX, v_u_665_.bottomArm.rotY, v_u_665_.bottomArm.rotZ }, nil, v_u_665_.bottomArm.resetSpeed)
				if v684_ ~= nil then
					v684_:setDeleteListenerObject(self)
					v684_:setFinishedFunc(v_u_665_.bottomArm.interpolatorFinished, v_u_665_.bottomArm)
					v_u_665_.bottomArm.bottomArmInterpolating = true
					if v_u_665_.delayedObjectChanges then
						v684_:setFinishedFunc(function()
							-- upvalues: (ref) v_u_665_, (copy) self
							v_u_665_.bottomArm.interpolatorFinished(v_u_665_.bottomArm)
							if v_u_665_.jointIndex == 0 then
								ObjectChangeUtil.setObjectChanges(v_u_665_.changeObjects, false, self, self.setMovingToolDirty)
							end
						end)
					end
				end
				local v685_ = v_u_665_.bottomArm.lastDirection
				local v686_ = v_u_665_.bottomArm.lastDirection
				local v687_ = v_u_665_.bottomArm.lastDirection
				v685_[1] = 0
				v686_[2] = 0
				v687_[3] = 0
				if v_u_665_.bottomArm.translationNode ~= nil then
					setTranslation(v_u_665_.bottomArm.translationNode, 0, 0, 0)
				end
				if v_u_665_.bottomArm.toolbarNode ~= nil then
					setVisibility(v_u_665_.bottomArm.toolbarNode, false)
				end
				if v_u_665_.bottomArm.toggleVisibility then
					setVisibility(v_u_665_.bottomArm.rotationNode, false)
				end
				if v_u_665_.bottomArm.leftNode ~= nil then
					self:setMovingPartReferenceNode(v_u_665_.bottomArm.leftNode, nil, false)
				end
				if v_u_665_.bottomArm.rightNode ~= nil then
					self:setMovingPartReferenceNode(v_u_665_.bottomArm.rightNode, nil, false)
				end
			end
		end
		local v688_ = setTranslation
		local v689_ = v_u_665_.jointTransform
		local v690_ = v_u_665_.jointOrigTrans
		v688_(v689_, unpack(v690_))
		local v691_ = v683_:getActiveInputAttacherJoint()
		local v692_ = setTranslation
		local v693_ = v691_.node
		local v694_ = v691_.jointOrigTrans
		v692_(v693_, unpack(v694_))
		if v_u_665_.rotationNode ~= nil then
			setRotation(v_u_665_.rotationNode, v_u_665_.rotX, v_u_665_.rotY, v_u_665_.rotZ)
		end
		if v_u_665_.rotationNode2 ~= nil then
			setRotation(v_u_665_.rotationNode2, -v_u_665_.rotX, -v_u_665_.rotY, -v_u_665_.rotZ)
		end
		if v_u_665_.visualAlignNodes ~= nil then
			for _, v695_ in ipairs(v_u_665_.visualAlignNodes) do
				self:setMovingPartReferenceNode(v695_.node, v_u_665_.jointTransform, false)
			end
		end
		SpecializationUtil.raiseEvent(self, "onPostDetachImplement", implementIndex)
		v683_:postDetach(implementIndex)
		self:detachAdditionalAttachment(v_u_665_, v691_)
	end
	table.remove(v662_.attachedImplements, implementIndex)
	self:playDetachSound(v_u_665_)
	v662_.wasInAttachRange = nil
	self:updateVehicleChain()
	v664_.object:updateVehicleChain()
	local v696_ = {
		["attacherVehicle"] = self,
		["attachedVehicle"] = v664_.object
	}
	v664_.object:raiseStateChange(VehicleStateChange.DETACH, v696_)
	self.rootVehicle:raiseStateChange(VehicleStateChange.DETACH, v696_)
	self.rootVehicle:updateSelectableObjects()
	if GS_IS_MOBILE_VERSION then
		local v697_ = next(v662_.attachedImplements)
		if v662_.attachedImplements[v697_] == nil then
			self.rootVehicle:setSelectedVehicle(self, nil, true)
		else
			self.rootVehicle:setSelectedVehicle(v662_.attachedImplements[v697_].object, nil, true)
		end
	else
		self.rootVehicle:setSelectedVehicle(self, nil, true)
	end
	self.rootVehicle:requestActionEventUpdate()
	v664_.object:updateSelectableObjects()
	v664_.object:setSelectedVehicle(v664_.object, nil, true)
	v664_.object:requestActionEventUpdate()
	AttacherJoints.updateRequiredTopLightsState(self)
	return true
end

-- Local values: spec, i, implement
function AttacherJoints:detachImplementByObject(object, noEventSend)
	local v701_ = self.spec_attacherJoints
	for v702_, v703_ in ipairs(v701_.attachedImplements) do
		if v703_.object == object then
			self:detachImplement(v702_, noEventSend)
			break
		end
	end
	return true
end

function AttacherJoints:setSelectedImplementByObject(object)
	self.spec_attacherJoints.selectedImplement = self:getImplementByObject(object)
end

-- Local values: spec
function AttacherJoints:getSelectedImplement()
	local v707_ = self.spec_attacherJoints
	if v707_.selectedImplement == nil or v707_.selectedImplement.object:getAttacherVehicle() == self then
		return v707_.selectedImplement
	else
		return nil
	end
end

function AttacherJoints.getCanToggleAttach(self)
	return true
end

function AttacherJoints:getAttachControlBarActionAccessible()
	return true
end

-- Local values: spec, info, selectedVehicle
function AttacherJoints:getShowAttachControlBarAction()
	if self:getIsAIActive() then
		return false
	end
	local v709_ = self.spec_attacherJoints.attachableInfo
	local v710_ = self:getSelectedVehicle()
	if v709_.attacherVehicle == nil then
		if v710_ ~= nil and (not v710_.isDeleted and (v710_.getAttacherVehicle ~= nil and v710_:getAttacherVehicle() ~= nil)) then
			return true
		end
	elseif v710_ == nil then
		return true
	end
	return v709_.attachable ~= nil and v709_.attacherVehicle == self
end

function AttacherJoints:detachAttachedImplement()
	if self:getCanToggleAttach() then
		AttacherJoints.actionEventAttach(self)
	end
end

-- Local values: spec
function AttacherJoints:startAttacherJointCombo(force)
	local v714_ = self.spec_attacherJoints
	if not v714_.attacherJointCombos.isRunning or force then
		v714_.attacherJointCombos.direction = -v714_.attacherJointCombos.direction
		v714_.attacherJointCombos.isRunning = true
	end
end

-- Local values: spec, attacherJoint
function AttacherJoints:setAttacherJointBlocked(attacherJointIndex, isBlocked)
	local v718_ = self.spec_attacherJoints.attacherJoints[attacherJointIndex]
	if v718_ ~= nil then
		v718_.isBlocked = isBlocked
	end
end

-- Local values: i, jointIndex
function AttacherJoints:getIsAttachingAllowed(attacherJoint)
	if attacherJoint.jointIndex ~= 0 then
		return false
	end
	if attacherJoint.isBlocked then
		return false
	end
	if attacherJoint.disabledByAttacherJoints ~= nil and #attacherJoint.disabledByAttacherJoints > 0 then
		for v721_ = 1, #attacherJoint.disabledByAttacherJoints do
			if self:getImplementByJointDescIndex(attacherJoint.disabledByAttacherJoints[v721_]) ~= nil then
				return false
			end
		end
	end
	return true
end

function AttacherJoints:getIsAttacherJointCompatible(vehicle, attacherJoint, inputAttacherVehicle, inputAttacherJoint)
	return true
end

-- Local values: jointDesc
function AttacherJoints:getCanSteerAttachable(attachable)
	local v724_ = self:getAttacherJointDescFromObject(attachable)
	return v724_ ~= nil and (v724_.steeringBarLeftNode ~= nil or (v724_.steeringBarRightNode ~= nil or v724_.steeringBarForceUsage)) and true or false
end

-- Local values: spec, i, attachmentData
function AttacherJoints:onAttacherJointsVehicleLoaded(vehicle)
	local v727_ = self.spec_attacherJoints
	if v727_.attachmentDataToLoad == nil then
		g_messageCenter:unsubscribe(MessageType.VEHICLE_LOADED, self)
	else
		for v728_ = #v727_.attachmentDataToLoad, 1, -1 do
			local v729_ = v727_.attachmentDataToLoad[v728_]
			if v729_.attachedVehicleUniqueId == vehicle:getUniqueId() then
				self:attachImplement(vehicle, v729_.inputIndex, v729_.jointIndex, true, nil, v729_.moveDown, true, true)
				self:setJointMoveDown(v729_.jointIndex, v729_.moveDown, true)
				table.remove(v727_.attachmentDataToLoad, v728_)
			end
		end
		if #v727_.attachmentDataToLoad == 0 then
			self:loadAttachmentsFinished()
			v727_.attachmentDataToLoad = nil
			g_messageCenter:unsubscribe(MessageType.VEHICLE_LOADED, self)
			return
		end
	end
end

function AttacherJoints:registerSelfLoweringActionEvent(actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, ignoreCollisions) end

-- Local values: spec
function AttacherJoints:playAttachSound(jointDesc)
	local v732_ = self.spec_attacherJoints
	if self.isClient then
		if jointDesc == nil or jointDesc.sampleAttach == nil then
			g_soundManager:playSample(v732_.samples.attach)
		else
			g_soundManager:playSample(jointDesc.sampleAttach)
		end
	end
	return true
end

-- Local values: spec
function AttacherJoints:playDetachSound(jointDesc)
	local v735_ = self.spec_attacherJoints
	if self.isClient then
		if jointDesc == nil or jointDesc.sampleDetach == nil then
			if v735_.samples.detach == nil then
				if jointDesc == nil or jointDesc.sampleAttach == nil then
					g_soundManager:playSample(v735_.samples.attach)
				else
					g_soundManager:playSample(jointDesc.sampleAttach)
				end
			else
				g_soundManager:playSample(v735_.samples.detach)
			end
		else
			g_soundManager:playSample(jointDesc.sampleDetach)
		end
	end
	return true
end

-- Local values: implement, object, implementIndex
function AttacherJoints:detachingIsPossible()
	local v737_ = self:getImplementByObject(self:getSelectedVehicle())
	if v737_ ~= nil then
		local v738_ = v737_.object
		if v738_ ~= nil and (v738_.attacherVehicle ~= nil and (v738_:isDetachAllowed() and v738_.attacherVehicle:getImplementIndexByObject(v738_) ~= nil)) then
			return true
		end
	end
	return false
end

-- Local values: storeItem, targetDirection, attacherJoint, attacherJointIndex, index, attacherJointToCheck, x, y, z, dirX, _, dirZ, yRot, asyncCallbackArguments, data
function AttacherJoints:attachAdditionalAttachment(jointDesc, inputJointDesc, object)
	if jointDesc.attacherJointDirection ~= nil and inputJointDesc.additionalAttachment.filename ~= nil then
		local v743_ = g_storeManager:getItemByXMLFilename(inputJointDesc.additionalAttachment.filename)
		if v743_ ~= nil then
			local v744_ = -jointDesc.attacherJointDirection
			local v745_ = nil
			local v746_ = nil
			for v747_, v748_ in ipairs(self:getAttacherJoints()) do
				if v748_.attacherJointDirection == v744_ then
					if v748_.jointIndex ~= 0 then
						v746_ = nil
						break
					end
					if v748_.jointType == inputJointDesc.additionalAttachment.jointType then
						v746_ = v748_
						v745_ = v747_
					end
				end
			end
			if v746_ ~= nil then
				local v749_, v750_, v751_ = localToWorld(v746_.jointTransform, 0, 0, 0)
				local v752_, _, v753_ = localDirectionToWorld(v746_.jointTransform, 1, 0, 0)
				local v754_ = MathUtil.getYRotationFromDirection(v752_, v753_)
				jointDesc.additionalAttachment.currentAttacherJointIndex = v745_
				local v755_ = {
					v745_,
					inputJointDesc.additionalAttachment.inputAttacherJointIndex,
					v746_.jointTransform,
					inputJointDesc.additionalAttachment.needsLowering,
					object,
					v743_.xmlFilename
				}
				local v756_ = VehicleLoadingData.new()
				v756_:setStoreItem(v743_)
				v756_:setPosition(v749_, v750_, v751_)
				v756_:setRotation(0, v754_, 0)
				v756_:setPropertyState(VehiclePropertyState.NONE)
				v756_:setOwnerFarmId(self:getActiveFarm())
				v756_:load(AttacherJoints.additionalAttachmentLoaded, self, v755_)
			end
		end
	end
end

-- Local values: implement
function AttacherJoints:detachAdditionalAttachment(jointDesc, inputJointDesc)
	if jointDesc.additionalAttachment.currentAttacherJointIndex ~= nil and inputJointDesc.additionalAttachment.filename ~= nil then
		local v760_ = self:getImplementByJointDescIndex(jointDesc.additionalAttachment.currentAttacherJointIndex)
		if v760_ ~= nil and v760_.object:getIsAdditionalAttachment() then
			self:detachImplementByObject(v760_.object)
			if not g_currentMission.isExitingGame then
				v760_.object:delete()
			end
		end
	end
end

-- Local values: vehicle, offset, inputAttacherJoints, x, y, z, dirX, _, dirZ, yRot, terrainY
function AttacherJoints:additionalAttachmentLoaded(vehicles, vehicleLoadState, asyncCallbackArguments)
	if vehicleLoadState == VehicleLoadingState.OK then
		local v765_ = vehicles[1]
		if v765_ == nil or v765_.setIsAdditionalAttachment == nil then
			Logging.warning("Invalid additional attachment \'%s\'.", asyncCallbackArguments[6].xmlFilename)
		else
			local v766_ = { 0, 0, 0 }
			if v765_.getInputAttacherJoints ~= nil then
				local v767_ = v765_:getInputAttacherJoints()
				if v767_[asyncCallbackArguments[2]] ~= nil then
					v766_ = v767_[asyncCallbackArguments[2]].jointOrigOffsetComponent
				end
			end
			local v768_, v769_, v770_ = localToWorld(asyncCallbackArguments[3], unpack(v766_))
			local v771_, _, v772_ = localDirectionToWorld(asyncCallbackArguments[3], 1, 0, 0)
			local v773_ = MathUtil.getYRotationFromDirection(v771_, v772_)
			local v774_ = getTerrainHeightAtWorldPos(g_terrainNode, v768_, 0, v770_) + 0.05
			v765_:setAbsolutePosition(v768_, math.max(v769_, v774_), v770_, 0, v773_, 0)
			self:attachImplement(v765_, asyncCallbackArguments[2], asyncCallbackArguments[1], true, nil, nil, true, true)
			v765_:setIsAdditionalAttachment(asyncCallbackArguments[4], true)
			if v765_.addDirtAmount ~= nil and (asyncCallbackArguments[5] ~= nil and asyncCallbackArguments[5].getDirtAmount ~= nil) then
				v765_:addDirtAmount(asyncCallbackArguments[5]:getDirtAmount())
			end
			self.rootVehicle:updateSelectableObjects()
			self.rootVehicle:setSelectedVehicle(asyncCallbackArguments[5] or self)
		end
	else
		Logging.warning("Failed to load additional attachment \'%s\'.", asyncCallbackArguments[6].xmlFilename)
		return
	end
end

-- Local values: spec, i, implement
function AttacherJoints:getImplementIndexByJointDescIndex(jointDescIndex)
	local v777_ = self.spec_attacherJoints
	for v778_, v779_ in pairs(v777_.attachedImplements) do
		if v779_.jointDescIndex == jointDescIndex then
			return v778_
		end
	end
	return nil
end

-- Local values: spec, i, implement
function AttacherJoints:getImplementByJointDescIndex(jointDescIndex)
	local v782_ = self.spec_attacherJoints
	for _, v783_ in pairs(v782_.attachedImplements) do
		if v783_.jointDescIndex == jointDescIndex then
			return v783_
		end
	end
	return nil
end

-- Local values: spec, i, implement
function AttacherJoints:getImplementIndexByObject(object)
	local v786_ = self.spec_attacherJoints
	for v787_, v788_ in pairs(v786_.attachedImplements) do
		if v788_.object == object then
			return v787_
		end
	end
	return nil
end

-- Local values: spec, i, implement
function AttacherJoints:getImplementByObject(object)
	local v791_ = self.spec_attacherJoints
	for _, v792_ in pairs(v791_.attachedImplements) do
		if v792_.object == object then
			return v792_
		end
	end
	return nil
end
function AttacherJoints.callFunctionOnAllImplements(p793_, p794_, ...)
	for _, v795_ in pairs(p793_:getAttachedImplements()) do
		local v796_ = v795_.object
		if v796_ ~= nil and v796_[p794_] ~= nil then
			v796_[p794_](v796_, ...)
		end
	end
end

-- Local values: spec, _, v
function AttacherJoints:activateAttachments()
	local v798_ = self.spec_attacherJoints
	for _, v799_ in pairs(v798_.attachedImplements) do
		if v799_.object ~= nil then
			v799_.object:activate()
		end
	end
end

-- Local values: spec, _, v
function AttacherJoints:deactivateAttachments()
	local v801_ = self.spec_attacherJoints
	for _, v802_ in pairs(v801_.attachedImplements) do
		if v802_.object ~= nil then
			v802_.object:deactivate()
		end
	end
end

-- Local values: spec, _, v
function AttacherJoints:deactivateAttachmentsLights()
	local v804_ = self.spec_attacherJoints
	for _, v805_ in pairs(v804_.attachedImplements) do
		if v805_.object ~= nil and v805_.object.deactivateLights ~= nil then
			v805_.object:deactivateLights()
		end
	end
end

-- Local values: spec, jointDesc, implementIndex, implement
function AttacherJoints:setJointMoveDown(jointDescIndex, moveDown, noEventSend)
	local v810_ = self.spec_attacherJoints
	local v811_ = v810_.attacherJoints[jointDescIndex]
	if v811_ ~= nil and moveDown ~= v811_.moveDown then
		if v811_.allowsLowering then
			v811_.moveDown = moveDown
			v811_.isMoving = true
			local v812_ = self:getImplementIndexByJointDescIndex(jointDescIndex)
			if v812_ ~= nil then
				local v813_ = v810_.attachedImplements[v812_]
				if v813_.object ~= nil then
					v813_.object:setLowered(moveDown)
				end
			end
		end
		VehicleLowerImplementEvent.sendEvent(self, jointDescIndex, moveDown, noEventSend)
	end
	return true
end

-- Local values: jointDesc
function AttacherJoints:getJointMoveDown(jointDescIndex)
	local v816_ = self.spec_attacherJoints.attacherJoints[jointDescIndex]
	if v816_.allowsLowering then
		return v816_.moveDown
	else
		return false
	end
end

-- Local values: spec
function AttacherJoints:getIsHardAttachAllowed(jointDescIndex)
	return self.spec_attacherJoints.attacherJoints[jointDescIndex].supportsHardAttach
end

function AttacherJoints:getIsSmoothAttachUpdateAllowed(implement)
	return true
end

-- Local values: spec, node, jointTypeStr, jointType, subTypeStr, brandRestrictionStr, i, brand, vehicleRestrictionStr, rotationNode, lowerValues, upperValues, l, u, l, u, l, u, rotationNode2, copy, lowerRotLimitStr, lx, ly, lz, ux, uy, uz, lowerTransLimitStr, bottomArmRotationNode, translationNode, referenceNode, bottomArm, x, y, z, toolbarI3dFilename, arguments, categoryRange, widthRange, defaultWidth, defaultCategory, xOffset, _, _, _, key, node, visualAlignNode, i, visualNode, i, hideNode, _, _, zOffset, schemaKey, x, y, liftedOffsetX, liftedOffsetY
function AttacherJoints:loadAttacherJointFromXML(attacherJoint, xmlFile, baseName, index)
	local v823_ = self.spec_attacherJoints
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#index", baseName .. "#node")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#indexVisual", baseName .. "#nodeVisual")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#ptoOutputNode", "vehicle.powerTakeOffs.output")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#lowerDistanceToGround", baseName .. ".distanceToGround#lower")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#upperDistanceToGround", baseName .. ".distanceToGround#upper")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#rotationNode", baseName .. ".rotationNode#node")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#upperRotation", baseName .. ".rotationNode#upperRotation")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#lowerRotation", baseName .. ".rotationNode#lowerRotation")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#startRotation", baseName .. ".rotationNode#startRotation")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#rotationNode2", baseName .. ".rotationNode2#node")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#upperRotation2", baseName .. ".rotationNode2#upperRotation")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#lowerRotation2", baseName .. ".rotationNode2#lowerRotation")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#transNode", baseName .. ".transNode#node")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#transNodeMinY", baseName .. ".transNode#minY")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#transNodeMaxY", baseName .. ".transNode#maxY")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#transNodeHeight", baseName .. ".transNode#height")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. ".additionalAttachment#attacherJointDirection", baseName .. "#direction")
	local v824_ = xmlFile:getValue(baseName .. "#node", nil, self.components, self.i3dMappings)
	if v824_ == nil then
		Logging.xmlWarning(self.xmlFile, "Missing node for attacherJoint \'%s\'", baseName)
		return false
	end
	attacherJoint.jointTransform = v824_
	attacherJoint.jointComponent = self:getParentComponent(attacherJoint.jointTransform)
	attacherJoint.jointTransformVisual = xmlFile:getValue(baseName .. "#nodeVisual", nil, self.components, self.i3dMappings)
	attacherJoint.supportsHardAttach = xmlFile:getValue(baseName .. "#supportsHardAttach", true)
	attacherJoint.jointOrigOffsetComponent = { localToLocal(attacherJoint.jointComponent, attacherJoint.jointTransform, 0, 0, 0) }
	attacherJoint.jointOrigRotOffsetComponent = { localRotationToLocal(attacherJoint.jointComponent, attacherJoint.jointTransform, 0, 0, 0) }
	attacherJoint.jointTransformOrig = createTransformGroup(getName(v824_) .. "_jointTransformOrig")
	link(getParent(v824_), attacherJoint.jointTransformOrig)
	setTranslation(attacherJoint.jointTransformOrig, getTranslation(v824_))
	setRotation(attacherJoint.jointTransformOrig, getRotation(v824_))
	local v825_ = xmlFile:getValue(baseName .. "#jointType")
	local v826_
	if v825_ == nil then
		v826_ = nil
	else
		v826_ = AttacherJoints.jointTypeNameToInt[v825_]
		if v826_ == nil then
			Logging.xmlWarning(self.xmlFile, "Invalid jointType \'%s\' for attacherJoint \'%s\'!", tostring(v825_), baseName)
		end
	end
	if v826_ == nil then
		v826_ = AttacherJoints.JOINTTYPE_IMPLEMENT
	end
	attacherJoint.jointType = v826_
	local v827_ = xmlFile:getValue(baseName .. ".subType#name")
	if not string.isNilOrWhitespace(v827_) then
		attacherJoint.subTypes = string.split(v827_, " ")
	end
	local v828_ = xmlFile:getValue(baseName .. ".subType#brandRestriction")
	if v828_ ~= nil and string.trim(v828_) ~= "" then
		attacherJoint.brandRestrictions = string.split(v828_, " ")
		for v829_ = 1, #attacherJoint.brandRestrictions do
			local v830_ = g_brandManager:getBrandByName(attacherJoint.brandRestrictions[v829_])
			if v830_ == nil then
				Logging.xmlError(xmlFile, "Unknown brand \'%s\' in \'%s\'", attacherJoint.brandRestrictions[v829_], baseName .. ".subType#brandRestriction")
				attacherJoint.brandRestrictions = nil
				break
			end
			attacherJoint.brandRestrictions[v829_] = v830_
		end
	end
	local v831_ = xmlFile:getValue(baseName .. ".subType#vehicleRestriction")
	if v831_ ~= nil and string.trim(v831_) ~= "" then
		attacherJoint.vehicleRestrictions = string.split(v831_, " ")
	end
	attacherJoint.subTypeShowWarning = xmlFile:getValue(baseName .. ".subType#subTypeShowWarning", true)
	attacherJoint.allowsJointLimitMovement = xmlFile:getValue(baseName .. "#allowsJointLimitMovement", true)
	attacherJoint.allowsLowering = xmlFile:getValue(baseName .. "#allowsLowering", true)
	attacherJoint.isDefaultLowered = xmlFile:getValue(baseName .. "#isDefaultLowered", false)
	attacherJoint.allowDetachingWhileLifted = xmlFile:getValue(baseName .. "#allowDetachingWhileLifted", true)
	attacherJoint.allowFoldingWhileAttached = xmlFile:getValue(baseName .. "#allowFoldingWhileAttached", true)
	if v826_ == AttacherJoints.JOINTTYPE_TRAILER or (v826_ == AttacherJoints.JOINTTYPE_TRAILERLOW or v826_ == AttacherJoints.JOINTTYPE_TRAILERCAR) then
		attacherJoint.allowsLowering = false
	end
	attacherJoint.canTurnOnImplement = xmlFile:getValue(baseName .. "#canTurnOnImplement", true)
	local v832_ = xmlFile:getValue(baseName .. ".rotationNode#node", nil, self.components, self.i3dMappings)
	if v832_ ~= nil then
		attacherJoint.rotationNode = v832_
		attacherJoint.lowerRotation = xmlFile:getValue(baseName .. ".rotationNode#lowerRotation", "0 0 0", true)
		attacherJoint.upperRotation = xmlFile:getValue(baseName .. ".rotationNode#upperRotation", nil, true) or { getRotation(v832_) }
		local v833_, v834_, v835_ = xmlFile:getValue(baseName .. ".rotationNode#startRotation", nil)
		attacherJoint.rotX = v833_
		attacherJoint.rotY = v834_
		attacherJoint.rotZ = v835_
		if attacherJoint.rotX == nil then
			local v836_, v837_, v838_ = getRotation(v832_)
			attacherJoint.rotX = v836_
			attacherJoint.rotY = v837_
			attacherJoint.rotZ = v838_
		end
		local v839_ = { attacherJoint.lowerRotation[1], attacherJoint.lowerRotation[2], attacherJoint.lowerRotation[3] }
		local v840_ = { attacherJoint.upperRotation[1], attacherJoint.upperRotation[2], attacherJoint.upperRotation[3] }
		local v841_ = v839_[1]
		local v842_ = v840_[1]
		if v842_ < v841_ then
			v840_[1] = v841_
			v839_[1] = v842_
		end
		local v843_ = v839_[2]
		local v844_ = v840_[2]
		if v844_ < v843_ then
			v840_[2] = v843_
			v839_[2] = v844_
		end
		local v845_ = v839_[3]
		local v846_ = v840_[3]
		if v846_ < v845_ then
			v840_[3] = v845_
			v839_[3] = v846_
		end
		local v847_ = attacherJoint.rotX
		local v848_ = v839_[1]
		local v849_ = v840_[1]
		attacherJoint.rotX = math.clamp(v847_, v848_, v849_)
		local v850_ = attacherJoint.rotY
		local v851_ = v839_[2]
		local v852_ = v840_[2]
		attacherJoint.rotY = math.clamp(v850_, v851_, v852_)
		local v853_ = attacherJoint.rotZ
		local v854_ = v839_[3]
		local v855_ = v840_[3]
		attacherJoint.rotZ = math.clamp(v853_, v854_, v855_)
	end
	local v856_ = xmlFile:getValue(baseName .. ".rotationNode2#node", nil, self.components, self.i3dMappings)
	if v856_ ~= nil then
		attacherJoint.rotationNode2 = v856_
		attacherJoint.lowerRotation2 = xmlFile:getValue(baseName .. ".rotationNode2#lowerRotation", nil, true) or { -attacherJoint.lowerRotation[1], -attacherJoint.lowerRotation[2], -attacherJoint.lowerRotation[3] }
		attacherJoint.upperRotation2 = xmlFile:getValue(baseName .. ".rotationNode2#upperRotation", nil, true) or { -attacherJoint.upperRotation[1], -attacherJoint.upperRotation[2], -attacherJoint.upperRotation[3] }
	end
	attacherJoint.transNode = xmlFile:getValue(baseName .. ".transNode#node", nil, self.components, self.i3dMappings)
	if attacherJoint.transNode ~= nil then
		attacherJoint.transNodeOrgTrans = { getTranslation(attacherJoint.transNode) }
		attacherJoint.transNodeHeight = xmlFile:getValue(baseName .. ".transNode#height", 0.12)
		attacherJoint.transNodeMinY = xmlFile:getValue(baseName .. ".transNode#minY")
		attacherJoint.transNodeMaxY = xmlFile:getValue(baseName .. ".transNode#maxY")
		attacherJoint.transNodeDependentBottomArm = xmlFile:getValue(baseName .. ".transNode.dependentBottomArm#node", nil, self.components, self.i3dMappings)
		attacherJoint.transNodeDependentBottomArmThreshold = xmlFile:getValue(baseName .. ".transNode.dependentBottomArm#threshold", math.huge)
		attacherJoint.transNodeDependentBottomArmRotation = xmlFile:getValue(baseName .. ".transNode.dependentBottomArm#rotation", "0 0 0", true)
	end
	if (attacherJoint.rotationNode ~= nil or attacherJoint.transNode ~= nil) and xmlFile:getValue(baseName .. ".distanceToGround#lower") == nil then
		Logging.xmlWarning(self.xmlFile, "Missing \'.distanceToGround#lower\' for attacherJoint \'%s\'. Use console command \'gsVehicleAnalyze\' to get correct values!", baseName)
	end
	attacherJoint.lowerDistanceToGround = xmlFile:getValue(baseName .. ".distanceToGround#lower", 0.7)
	if (attacherJoint.rotationNode ~= nil or attacherJoint.transNode ~= nil) and xmlFile:getValue(baseName .. ".distanceToGround#upper") == nil then
		Logging.xmlWarning(self.xmlFile, "Missing \'.distanceToGround#upper\' for attacherJoint \'%s\'. Use console command \'gsVehicleAnalyze\' to get correct values!", baseName)
	end
	attacherJoint.upperDistanceToGround = xmlFile:getValue(baseName .. ".distanceToGround#upper", 1)
	if attacherJoint.lowerDistanceToGround > attacherJoint.upperDistanceToGround then
		Logging.xmlWarning(self.xmlFile, "distanceToGround#lower may not be larger than distanceToGround#upper for attacherJoint \'%s\'. Switching values!", baseName)
		local v857_ = attacherJoint.lowerDistanceToGround
		attacherJoint.lowerDistanceToGround = attacherJoint.upperDistanceToGround
		attacherJoint.upperDistanceToGround = v857_
	end
	attacherJoint.lowerRotationOffset = xmlFile:getValue(baseName .. "#lowerRotationOffset", 0)
	attacherJoint.upperRotationOffset = xmlFile:getValue(baseName .. "#upperRotationOffset", 0)
	attacherJoint.dynamicLowerRotLimit = xmlFile:getValue(baseName .. "#dynamicLowerRotLimit", false)
	attacherJoint.lockDownRotLimit = xmlFile:getValue(baseName .. "#lockDownRotLimit", false)
	attacherJoint.lockUpRotLimit = xmlFile:getValue(baseName .. "#lockUpRotLimit", false)
	attacherJoint.lockDownTransLimit = xmlFile:getValue(baseName .. "#lockDownTransLimit", true)
	attacherJoint.lockUpTransLimit = xmlFile:getValue(baseName .. "#lockUpTransLimit", false)
	local v858_ = v826_ == AttacherJoints.JOINTTYPE_IMPLEMENT and "20 20 20" or "0 0 0"
	local v859_, v860_, v861_ = xmlFile:getValue(baseName .. "#lowerRotLimit", v858_)
	attacherJoint.lowerRotLimit = { math.abs(v859_ or 20), math.abs(v860_ or 20), (math.abs(v861_ or 20)) }
	local v862_, v863_, v864_ = xmlFile:getValue(baseName .. "#upperRotLimit")
	attacherJoint.upperRotLimit = { math.abs(v862_ or (v859_ or 20)), math.abs(v863_ or (v860_ or 20)), (math.abs(v864_ or (v861_ or 20))) }
	local v865_ = v826_ == AttacherJoints.JOINTTYPE_IMPLEMENT and "0.5 0.5 0.5" or "0 0 0"
	local v866_, v867_, v868_ = xmlFile:getValue(baseName .. "#lowerTransLimit", v865_)
	attacherJoint.lowerTransLimit = { math.abs(v866_ or 0), math.abs(v867_ or 0), (math.abs(v868_ or 0)) }
	local v869_, v870_, v871_ = xmlFile:getValue(baseName .. "#upperTransLimit")
	attacherJoint.upperTransLimit = { math.abs(v869_ or (v866_ or 0)), math.abs(v870_ or (v867_ or 0)), (math.abs(v871_ or (v868_ or 0))) }
	attacherJoint.jointPositionOffset = xmlFile:getValue(baseName .. "#jointPositionOffset", "0 0 0", true)
	attacherJoint.rotLimitSpring = xmlFile:getValue(baseName .. "#rotLimitSpring", "0 0 0", true)
	attacherJoint.rotLimitDamping = xmlFile:getValue(baseName .. "#rotLimitDamping", "1 1 1", true)
	attacherJoint.rotLimitForceLimit = xmlFile:getValue(baseName .. "#rotLimitForceLimit", "-1 -1 -1", true)
	attacherJoint.transLimitSpring = xmlFile:getValue(baseName .. "#transLimitSpring", "0 0 0", true)
	attacherJoint.transLimitDamping = xmlFile:getValue(baseName .. "#transLimitDamping", "1 1 1", true)
	attacherJoint.transLimitForceLimit = xmlFile:getValue(baseName .. "#transLimitForceLimit", "-1 -1 -1", true)
	attacherJoint.moveDefaultTime = xmlFile:getValue(baseName .. "#moveTime", 0.5) * 1000
	attacherJoint.moveTime = attacherJoint.moveDefaultTime
	attacherJoint.disabledByAttacherJoints = xmlFile:getValue(baseName .. "#disabledByAttacherJoints", nil, true)
	attacherJoint.enableCollision = xmlFile:getValue(baseName .. "#enableCollision", false)
	attacherJoint.topArm = AttacherJointTopArm.loadFromVehicleXML(self, baseName .. ".topArm")
	local v872_ = xmlFile:getValue(baseName .. ".bottomArm#rotationNode", nil, self.components, self.i3dMappings)
	local v873_ = xmlFile:getValue(baseName .. ".bottomArm#translationNode", nil, self.components, self.i3dMappings)
	local v874_ = xmlFile:getValue(baseName .. ".bottomArm#referenceNode", nil, self.components, self.i3dMappings)
	if v872_ ~= nil then
		local v_u_875_ = {
			["rotationNode"] = v872_,
			["rotationNodeDir"] = createTransformGroup("rotationNodeDirTemp")
		}
		link(getParent(v872_), v_u_875_.rotationNodeDir)
		setTranslation(v_u_875_.rotationNodeDir, getTranslation(v872_))
		setRotation(v_u_875_.rotationNodeDir, getRotation(v872_))
		v_u_875_.lastDirection = { 0, 0, 0 }
		local v876_, v877_, v878_ = xmlFile:getValue(baseName .. ".bottomArm#startRotation", nil)
		v_u_875_.rotX = v876_
		v_u_875_.rotY = v877_
		v_u_875_.rotZ = v878_
		if v_u_875_.rotX == nil then
			local v879_, v880_, v881_ = getRotation(v872_)
			v_u_875_.rotX = v879_
			v_u_875_.rotY = v880_
			v_u_875_.rotZ = v881_
		end
		function v_u_875_.interpolatorGet()
			-- upvalues: (copy) v_u_875_
			return getRotation(v_u_875_.rotationNode)
		end
		function v_u_875_.interpolatorSet(p882_, p883_, p884_)
			-- upvalues: (copy) v_u_875_, (copy) self
			setRotation(v_u_875_.rotationNode, p882_, p883_, p884_)
			if self.setMovingToolDirty ~= nil then
				self:setMovingToolDirty(v_u_875_.rotationNode)
			end
		end
		function v_u_875_.interpolatorFinished(self)
			-- upvalues: (copy) v_u_875_
			v_u_875_.bottomArmInterpolating = false
		end
		v_u_875_.interpolatorKey = v872_ .. "rotation"
		v_u_875_.bottomArmInterpolating = false
		if v873_ ~= nil and v874_ ~= nil then
			v_u_875_.translationNode = v873_
			v_u_875_.referenceNode = v874_
			local v885_, v886_, v887_ = getTranslation(v873_)
			if math.abs(v885_) >= 0.0001 or (math.abs(v886_) >= 0.0001 or math.abs(v887_) >= 0.0001) then
				Logging.xmlWarning(self.xmlFile, "BottomArm translation of attacherJoint \'%s\' is not 0/0/0!", baseName)
			end
			v_u_875_.referenceDistance = calcDistanceFrom(v874_, v873_)
		end
		local v888_ = xmlFile:getValue(baseName .. ".bottomArm#zScale", 1)
		v_u_875_.zScale = math.sign(v888_)
		v_u_875_.lockDirection = xmlFile:getValue(baseName .. ".bottomArm#lockDirection", true)
		v_u_875_.resetSpeed = xmlFile:getValue(baseName .. ".bottomArm#resetSpeed", 45)
		v_u_875_.updateReferenceDistance = xmlFile:getValue(baseName .. ".bottomArm#updateReferenceDistance", false)
		v_u_875_.jointPositionNode = xmlFile:getValue(baseName .. ".bottomArm#jointPositionNode", nil, self.components, self.i3dMappings)
		v_u_875_.toggleVisibility = xmlFile:getValue(baseName .. ".bottomArm#toggleVisibility", false)
		if v_u_875_.toggleVisibility then
			setVisibility(v_u_875_.rotationNode, false)
		end
		if v826_ == AttacherJoints.JOINTTYPE_IMPLEMENT then
			v_u_875_.sharedLoadRequestIdToolbar = self:loadSubSharedI3DFile(Utils.getFilename(xmlFile:getValue(baseName .. ".toolbar#filename", "$data/shared/assets/toolbars/toolbars.i3d"), self.baseDirectory), false, false, self.onBottomArmToolbarI3DLoaded, self, {
				["bottomArm"] = v_u_875_,
				["referenceNode"] = v874_
			})
		end
		local v889_ = AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[2]
		local v890_ = AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[2]
		v_u_875_.minWidth = v889_
		v_u_875_.maxWidth = v890_
		local v891_ = xmlFile:getValue(baseName .. ".bottomArm#categoryRange", "1 4", true)
		if v891_ ~= nil and #v891_ >= 1 then
			v_u_875_.minWidth = AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[v891_[1]] or v_u_875_.minWidth
			v_u_875_.maxWidth = AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[v891_[2] or v891_[1]] or v_u_875_.maxWidth
		end
		local v892_ = xmlFile:getValue(baseName .. ".bottomArm#widthRange", nil, true)
		if v892_ ~= nil and #v892_ >= 1 then
			v_u_875_.minWidth = v892_[1] or v_u_875_.minWidth
			v_u_875_.maxWidth = v892_[2] or (v892_[1] or v_u_875_.maxWidth)
		end
		if v826_ == AttacherJoints.JOINTTYPE_IMPLEMENT and not (xmlFile:hasProperty(baseName .. ".bottomArm#categoryRange") or xmlFile:hasProperty(baseName .. ".bottomArm#widthRange")) then
			Logging.xmlWarning(xmlFile, "Missing categoryRange or widthRange attribute for bottom arm in \'%s\'", baseName)
		end
		v_u_875_.armLeft = xmlFile:getValue(baseName .. ".bottomArm.armLeft#node", nil, self.components, self.i3dMappings)
		v_u_875_.armLeftReferenceNode = xmlFile:getValue(baseName .. ".bottomArm.armLeft#referenceNode", nil, self.components, self.i3dMappings)
		if v_u_875_.armLeft ~= nil and v_u_875_.armLeftReferenceNode ~= nil then
			v_u_875_.armLeftLength = calcDistanceFrom(v_u_875_.armLeft, v_u_875_.armLeftReferenceNode)
		end
		v_u_875_.armRight = xmlFile:getValue(baseName .. ".bottomArm.armRight#node", nil, self.components, self.i3dMappings)
		v_u_875_.armRightReferenceNode = xmlFile:getValue(baseName .. ".bottomArm.armRight#referenceNode", nil, self.components, self.i3dMappings)
		if v_u_875_.armRight ~= nil and v_u_875_.armRightReferenceNode ~= nil then
			v_u_875_.armRightLength = calcDistanceFrom(v_u_875_.armRight, v_u_875_.armRightReferenceNode)
		end
		v_u_875_.ballVisibility = xmlFile:getValue(baseName .. ".bottomArm#ballVisibility", true)
		if v_u_875_.armLeft == nil or (v_u_875_.armRight == nil or v_u_875_.referenceNode == nil) then
			v_u_875_.defaultWidth = (v_u_875_.minWidth + v_u_875_.maxWidth) * 0.5
		else
			v_u_875_.variableWidthAvailable = true
			local v893_ = xmlFile:getValue(baseName .. ".bottomArm#defaultCategory")
			local v894_
			if v893_ == nil or (v893_ < 0 or v893_ > 4) then
				v894_ = nil
			else
				v894_ = AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[v893_]
			end
			if v894_ == nil then
				v894_ = xmlFile:getValue(baseName .. ".bottomArm#defaultWidth")
			end
			if v894_ == nil then
				local v895_, _, _ = localToLocal(v_u_875_.armLeftReferenceNode or v_u_875_.armLeft, v_u_875_.referenceNode, 0, 0, 0)
				v894_ = math.abs(v895_) * 2
			end
			v_u_875_.defaultWidth = v894_
		end
		if self.setMovingPartReferenceNode ~= nil then
			v_u_875_.leftNode = xmlFile:getValue(baseName .. ".bottomArm#leftNode", nil, self.components, self.i3dMappings)
			v_u_875_.rightNode = xmlFile:getValue(baseName .. ".bottomArm#rightNode", nil, self.components, self.i3dMappings)
		end
		attacherJoint.bottomArm = v_u_875_
	end
	if self.isClient then
		attacherJoint.sampleAttach = g_soundManager:loadSampleFromXML(xmlFile, baseName, "attachSound", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		attacherJoint.sampleDetach = g_soundManager:loadSampleFromXML(xmlFile, baseName, "detachSound", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
	attacherJoint.steeringBarLeftNode = xmlFile:getValue(baseName .. ".steeringBars#leftNode", nil, self.components, self.i3dMappings)
	attacherJoint.steeringBarRightNode = xmlFile:getValue(baseName .. ".steeringBars#rightNode", nil, self.components, self.i3dMappings)
	attacherJoint.steeringBarForceUsage = xmlFile:getValue(baseName .. ".steeringBars#forceUsage", true)
	if self.setMovingPartReferenceNode ~= nil then
		for _, v896_ in self.xmlFile:iterator(baseName .. ".visualAlignNode") do
			local v897_ = xmlFile:getValue(v896_ .. "#node", nil, self.components, self.i3dMappings)
			if v897_ ~= nil then
				if attacherJoint.visualAlignNodes == nil then
					attacherJoint.visualAlignNodes = {}
				end
				local v898_ = {
					["node"] = v897_,
					["delayedOnAttach"] = xmlFile:getValue(v896_ .. "#delayedOnAttach", true)
				}
				local v899_ = attacherJoint.visualAlignNodes
				table.insert(v899_, v898_)
			end
		end
	end
	attacherJoint.visualNodes = xmlFile:getValue(baseName .. ".visuals#nodes", nil, self.components, self.i3dMappings, true)
	for v900_ = 1, #attacherJoint.visualNodes do
		local v901_ = attacherJoint.visualNodes[v900_]
		if v823_.visualNodeToAttacherJoints[v901_] == nil then
			v823_.visualNodeToAttacherJoints[v901_] = {}
		end
		local v902_ = v823_.visualNodeToAttacherJoints[v901_]
		table.insert(v902_, attacherJoint)
	end
	attacherJoint.hideVisuals = xmlFile:getValue(baseName .. ".visuals#hide", nil, self.components, self.i3dMappings, true)
	for v903_ = 1, #attacherJoint.hideVisuals do
		local v904_ = attacherJoint.hideVisuals[v903_]
		if v823_.hideVisualNodeToAttacherJoints[v904_] == nil then
			v823_.hideVisualNodeToAttacherJoints[v904_] = {}
		end
		local v905_ = v823_.hideVisualNodeToAttacherJoints[v904_]
		table.insert(v905_, attacherJoint)
	end
	attacherJoint.changeObjects = {}
	ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, baseName, attacherJoint.changeObjects, self.components, self)
	ObjectChangeUtil.setObjectChanges(attacherJoint.changeObjects, false, self, self.setMovingToolDirty, true)
	attacherJoint.delayedObjectChanges = xmlFile:getValue(baseName .. "#delayedObjectChanges", true)
	attacherJoint.delayedObjectChangesOnAttach = xmlFile:getValue(baseName .. "#delayedObjectChangesOnAttach", false)
	attacherJoint.additionalAttachment = {}
	local _, _, v906_ = localToLocal(attacherJoint.jointTransform, self.rootNode, 0, 0, 0)
	attacherJoint.attacherJointDirection = xmlFile:getValue(baseName .. "#direction", (math.sign(v906_)))
	attacherJoint.useTopLights = xmlFile:getValue(baseName .. "#useTopLights", attacherJoint.attacherJointDirection == 1)
	attacherJoint.rootNode = xmlFile:getValue(baseName .. "#rootNode", self:getParentComponent(attacherJoint.jointTransform), self.components, self.i3dMappings)
	attacherJoint.rootNodeBackup = attacherJoint.rootNode
	attacherJoint.jointIndex = 0
	attacherJoint.isBlocked = false
	attacherJoint.comboTime = xmlFile:getValue(baseName .. "#comboTime")
	local v907_ = baseName .. ".schema"
	if xmlFile:hasProperty(v907_) then
		local v908_, v909_ = xmlFile:getValue(v907_ .. "#position")
		if v908_ == nil then
			Logging.xmlWarning(self.xmlFile, "Missing values for \'%s\'", v907_ .. "#position")
		else
			local v910_, v911_ = xmlFile:getValue(v907_ .. "#liftedOffset", "0 5")
			self.schemaOverlay:addAttacherJoint(v908_, v909_, xmlFile:getValue(v907_ .. "#rotation", 0), xmlFile:getValue(v907_ .. "#invertX", false), v910_, v911_)
		end
	else
		Logging.xmlWarning(self.xmlFile, "Missing schema overlay attacherJoint \'%s\'!", baseName)
	end
	return true
end

-- Local values: bottomArm, referenceNode, rootNode, activeIndex, index, toolbar
function AttacherJoints:onBottomArmToolbarI3DLoaded(i3dNode, failedReason, args)
	local v914_ = args.bottomArm
	local v915_ = args.referenceNode
	if i3dNode ~= 0 then
		local v916_ = getChildAt(i3dNode, 0)
		link(v915_, v916_)
		setTranslation(v916_, 0, 0, 0)
		setVisibility(v916_, false)
		local v917_ = AttacherJoints.getClosestLowerLinkCategoryIndex(v914_.defaultWidth or AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[2])
		v914_.toolbarNode = v916_
		v914_.toolbars = {}
		for v918_ = 1, getNumOfChildren(v916_) do
			local v919_ = getChildAt(v916_, v918_ - 1)
			setTranslation(v919_, 0, 0, 0)
			setVisibility(v919_, v917_ == v918_ - 1)
			local v920_ = v914_.toolbars
			table.insert(v920_, v919_)
		end
		delete(i3dNode)
	end
end

-- Local values: spec, _, implement
function AttacherJoints:raiseActive(superFunc)
	local v923_ = self.spec_attacherJoints
	superFunc(self)
	for _, v924_ in pairs(v923_.attachedImplements) do
		if v924_.object ~= nil then
			v924_.object:raiseActive()
		end
	end
end

-- Local values: spec, selectedObject, _, implement
function AttacherJoints:registerActionEvents(superFunc, excludedVehicle)
	local v928_ = self.spec_attacherJoints
	superFunc(self, excludedVehicle)
	if self ~= excludedVehicle then
		local v929_ = self:getSelectedObject()
		if v929_ ~= nil and (self ~= v929_.vehicle and excludedVehicle ~= v929_.vehicle) then
			v929_.vehicle:registerActionEvents()
		end
		for _, v930_ in pairs(v928_.attachedImplements) do
			if v930_.object ~= nil then
				if v929_ == nil then
					printCallstack()
				end
				v930_.object:registerActionEvents(v929_.vehicle)
			end
		end
	end
end

-- Local values: spec, _, implement
function AttacherJoints:removeActionEvents(superFunc)
	local v933_ = self.spec_attacherJoints
	superFunc(self)
	for _, v934_ in pairs(v933_.attachedImplements) do
		if v934_.object ~= nil then
			v934_.object:removeActionEvents()
		end
	end
end

-- Local values: spec, _, implement
function AttacherJoints:addToPhysics(superFunc)
	if not superFunc(self) then
		return false
	end
	local v937_ = self.spec_attacherJoints
	for _, v938_ in pairs(v937_.attachedImplements) do
		if v938_.object.spec_attachable.isHardAttached then
			v938_.object:addToPhysics()
		else
			self:createAttachmentJoint(v938_, true)
		end
	end
	return true
end

-- Local values: spec, _, implement, jointDesc
function AttacherJoints:removeFromPhysics(superFunc)
	local v941_ = self.spec_attacherJoints
	for _, v942_ in pairs(v941_.attachedImplements) do
		if v942_.object.spec_attachable.isHardAttached then
			v942_.object:removeFromPhysics()
		else
			local v943_ = v941_.attacherJoints[v942_.jointDescIndex]
			if v943_.jointIndex ~= 0 then
				v943_.jointIndex = 0
			end
		end
	end
	return superFunc(self) and true or false
end

-- Local values: spec, mass, _, implement, object
function AttacherJoints:getTotalMass(superFunc, onlyGivenVehicle)
	local v947_ = self.spec_attacherJoints
	local v948_ = superFunc(self)
	if onlyGivenVehicle == nil or not onlyGivenVehicle then
		for _, v949_ in pairs(v947_.attachedImplements) do
			local v950_ = v949_.object
			if v950_ ~= nil then
				v948_ = v948_ + v950_:getTotalMass(onlyGivenVehicle)
			end
		end
	end
	return v948_
end

-- Local values: additionalMass, spec, _, implement, object
function AttacherJoints:getAdditionalComponentMass(superFunc, component)
	local v954_ = superFunc(self, component)
	if component.node == self.rootNode then
		local v955_ = self.spec_attacherJoints
		for _, v956_ in pairs(v955_.attachedImplements) do
			local v957_ = v956_.object
			if v957_ ~= nil and v957_.spec_attachable.isHardAttached then
				v954_ = v954_ + v957_:getTotalMass(true)
			end
		end
	end
	return v954_
end

-- Local values: spec, _, implement, object
function AttacherJoints:addChildVehicles(superFunc, vehicles, rootVehicle)
	local v962_ = self.spec_attacherJoints
	for _, v963_ in pairs(v962_.attachedImplements) do
		local v964_ = v963_.object
		if v964_ ~= nil and v964_.addChildVehicles ~= nil then
			v964_:addChildVehicles(vehicles, rootVehicle)
		end
	end
	return superFunc(self, vehicles, rootVehicle)
end

-- Local values: spec, usage, _, implement, object
function AttacherJoints:getAirConsumerUsage(superFunc)
	local v967_ = self.spec_attacherJoints
	local v968_ = superFunc(self)
	for _, v969_ in pairs(v967_.attachedImplements) do
		local v970_ = v969_.object
		if v970_ ~= nil and v970_.getAttachbleAirConsumerUsage ~= nil then
			v968_ = v968_ + v970_:getAttachbleAirConsumerUsage()
		end
	end
	return v968_
end

-- Local values: spec, _, implement
function AttacherJoints:getRequiresPower(superFunc)
	local v973_ = self.spec_attacherJoints
	for _, v974_ in pairs(v973_.attachedImplements) do
		if v974_.object ~= nil and v974_.object:getRequiresPower() then
			return true
		end
	end
	return superFunc(self)
end

-- Local values: _, implement, object
function AttacherJoints:addVehicleToAIImplementList(superFunc, list)
	superFunc(self, list)
	for _, v978_ in pairs(self:getAttachedImplements()) do
		local v979_ = v978_.object
		if v979_ ~= nil and v979_.addVehicleToAIImplementList ~= nil then
			v979_:addVehicleToAIImplementList(list)
		end
	end
end

-- Local values: _, implement, object
function AttacherJoints:collectAIAgentAttachments(superFunc, aiDrivableVehicle)
	superFunc(self, aiDrivableVehicle)
	for _, v983_ in pairs(self:getAttachedImplements()) do
		local v984_ = v983_.object
		if v984_ ~= nil and v984_.collectAIAgentAttachments ~= nil then
			v984_:collectAIAgentAttachments(aiDrivableVehicle)
			aiDrivableVehicle:startNewAIAgentAttachmentChain()
		end
	end
end

-- Local values: _, implement, object
function AttacherJoints:setAIVehicleObstacleStateDirty(superFunc)
	superFunc(self)
	for _, v987_ in pairs(self:getAttachedImplements()) do
		local v988_ = v987_.object
		if v988_ ~= nil and v988_.setAIVehicleObstacleStateDirty ~= nil then
			v988_:setAIVehicleObstacleStateDirty()
		end
	end
end

-- Local values: spec, maxAngle, _, implement, object
function AttacherJoints:getDirectionSnapAngle(superFunc)
	local v991_ = self.spec_attacherJoints
	local v992_ = superFunc(self)
	for _, v993_ in pairs(v991_.attachedImplements) do
		local v994_ = v993_.object
		if v994_ ~= nil and v994_.getDirectionSnapAngle ~= nil then
			local v995_ = v992_ + v994_:getDirectionSnapAngle()
			v992_ = math.max(v995_)
		end
	end
	return v992_
end

-- Local values: spec, _, implement, object
function AttacherJoints:getFillLevelInformation(superFunc, display)
	local v999_ = self.spec_attacherJoints
	superFunc(self, display)
	for _, v1000_ in pairs(v999_.attachedImplements) do
		local v1001_ = v1000_.object
		if v1001_ ~= nil and v1001_.getFillLevelInformation ~= nil then
			v1001_:getFillLevelInformation(display)
		end
	end
end

-- Local values: spec, _, implement
function AttacherJoints:getHasObjectMounted(superFunc, object)
	if superFunc(self, object) then
		return true
	end
	local v1005_ = self.spec_attacherJoints
	for _, v1006_ in pairs(v1005_.attachedImplements) do
		if v1006_.object ~= nil and v1006_.object:getHasObjectMounted(object) then
			return true
		end
	end
	return false
end

-- Local values: spec, _, implement, object
function AttacherJoints:attachableAddToolCameras(superFunc)
	local v1009_ = self.spec_attacherJoints
	superFunc(self)
	for _, v1010_ in pairs(v1009_.attachedImplements) do
		local v1011_ = v1010_.object
		if v1011_ ~= nil and v1011_.attachableAddToolCameras ~= nil then
			v1011_:attachableAddToolCameras()
		end
	end
end

-- Local values: spec, _, implement, object
function AttacherJoints:attachableRemoveToolCameras(superFunc)
	local v1014_ = self.spec_attacherJoints
	superFunc(self)
	for _, v1015_ in pairs(v1014_.attachedImplements) do
		local v1016_ = v1015_.object
		if v1016_ ~= nil and v1016_.attachableRemoveToolCameras ~= nil then
			v1016_:attachableRemoveToolCameras()
		end
	end
end

-- Local values: spec, _, implement, object
function AttacherJoints:registerSelectableObjects(superFunc, selectableObjects)
	superFunc(self, selectableObjects)
	local v1020_ = self.spec_attacherJoints
	for _, v1021_ in pairs(v1020_.attachedImplements) do
		local v1022_ = v1021_.object
		if v1022_ ~= nil and v1022_.registerSelectableObjects ~= nil then
			v1022_:registerSelectableObjects(selectableObjects)
		end
	end
end

-- Local values: spec, _, implement, object
function AttacherJoints:getIsReadyForAutomatedTrainTravel(superFunc)
	local v1025_ = self.spec_attacherJoints
	for _, v1026_ in pairs(v1025_.attachedImplements) do
		local v1027_ = v1026_.object
		if v1027_ ~= nil and (v1027_.getIsReadyForAutomatedTrainTravel ~= nil and not v1027_:getIsReadyForAutomatedTrainTravel()) then
			return false
		end
	end
	return superFunc(self)
end

-- Local values: spec, lastSpeed, _, implement, jointDescIndex, jointDesc, object
function AttacherJoints:getIsAutomaticShiftingAllowed(superFunc)
	local v1030_ = self.spec_attacherJoints
	local v1031_ = self:getLastSpeed()
	for _, v1032_ in pairs(v1030_.attachedImplements) do
		if v1031_ < 2 then
			if v1032_.attachingIsInProgress then
				return false
			end
			local v1033_ = v1032_.jointDescIndex
			if v1030_.attacherJoints[v1033_].isMoving then
				return false
			end
		end
		local v1034_ = v1032_.object
		if v1034_ ~= nil and (v1034_.getIsAutomaticShiftingAllowed ~= nil and not v1034_:getIsAutomaticShiftingAllowed()) then
			return false
		end
	end
	return superFunc(self)
end

-- Local values: attacherJointIndices, _, attacherJointIndex
function AttacherJoints:loadDashboardGroupFromXML(superFunc, xmlFile, key, group)
	if not superFunc(self, xmlFile, key, group) then
		return false
	end
	group.attacherJointIndices = {}
	local v1040_ = xmlFile:getValue(key .. "#attacherJointIndices", nil, true)
	if v1040_ ~= nil then
		for _, v1041_ in ipairs(v1040_) do
			local v1042_ = group.attacherJointIndices
			table.insert(v1042_, v1041_)
		end
	end
	if #group.attacherJointIndices == 0 then
		group.attacherJointIndices = nil
	end
	group.attacherJointNodes = xmlFile:getValue(key .. "#attacherJointNodes", nil, self.components, self.i3dMappings, true)
	if #group.attacherJointNodes == 0 then
		group.attacherJointNodes = nil
	end
	return true
end

-- Local values: _, node, attacherJointIndex, hasAttachment, _, jointIndex
function AttacherJoints:getIsDashboardGroupActive(superFunc, group)
	if group.attacherJointNodes ~= nil and self.finishedLoading then
		if group.attacherJointIndices == nil then
			group.attacherJointIndices = {}
		end
		for _, v1046_ in ipairs(group.attacherJointNodes) do
			local v1047_ = self:getAttacherJointIndexByNode(v1046_)
			if v1047_ ~= nil then
				local v1048_ = group.attacherJointIndices
				table.insert(v1048_, v1047_)
			end
		end
		if #group.attacherJointIndices == 0 then
			group.attacherJointIndices = nil
		end
		group.attacherJointNodes = nil
	end
	if group.attacherJointIndices ~= nil then
		local v1049_ = false
		for _, v1050_ in ipairs(group.attacherJointIndices) do
			if self:getImplementFromAttacherJointIndex(v1050_) ~= nil then
				v1049_ = true
			end
		end
		if not v1049_ then
			return false
		end
	end
	return superFunc(self, group)
end

function AttacherJoints:loadAttacherJointHeightNode(superFunc, xmlFile, key, heightNode, attacherJointNode)
	heightNode.disablingAttacherJointIndices = xmlFile:getValue(key .. "#disablingAttacherJointIndices", "", true)
	return superFunc(self, xmlFile, key, heightNode, attacherJointNode)
end

-- Local values: _, jointIndex
function AttacherJoints:getIsAttacherJointHeightNodeActive(superFunc, heightNode)
	for _, v1060_ in ipairs(heightNode.disablingAttacherJointIndices) do
		if self:getImplementFromAttacherJointIndex(v1060_) ~= nil then
			return false
		end
	end
	return superFunc(self, heightNode)
end

-- Local values: disablingAttacherJointNodes
function AttacherJoints:loadTipSide(superFunc, xmlFile, key, entry)
	if not superFunc(self, xmlFile, key, entry) then
		return false
	end
	local v1066_ = xmlFile:getValue(key .. "#disablingAttacherJointNodes", nil, self.components, self.i3dMappings, true)
	if #v1066_ > 0 then
		entry.disablingAttacherJointNodes = v1066_
	end
	return true
end

-- Local values: spec, tipSide, _, jointNode, jointIndex, _, jointIndex
function AttacherJoints:getIsTipSideAvailable(superFunc, sideIndex)
	if not superFunc(self, sideIndex) then
		return false
	end
	local v1070_ = self.spec_trailer.tipSides[sideIndex]
	if v1070_ ~= nil then
		if v1070_.disablingAttacherJointNodes ~= nil then
			v1070_.disablingAttacherJointIndices = {}
			for _, v1071_ in ipairs(v1070_.disablingAttacherJointNodes) do
				local v1072_ = self:getAttacherJointIndexByNode(v1071_)
				if v1072_ ~= nil then
					local v1073_ = v1070_.disablingAttacherJointIndices
					table.insert(v1073_, v1072_)
				end
			end
			if #v1070_.disablingAttacherJointIndices == 0 then
				v1070_.disablingAttacherJointIndices = nil
			end
		end
		if v1070_.disablingAttacherJointIndices ~= nil then
			for _, v1074_ in ipairs(v1070_.disablingAttacherJointIndices) do
				if self:getImplementFromAttacherJointIndex(v1074_) ~= nil then
					return false
				end
			end
		end
	end
	return true
end

-- Local values: disablingAttacherJointNodes
function AttacherJoints:loadFillUnitFromXML(superFunc, xmlFile, key, entry, index)
	if not superFunc(self, xmlFile, key, entry, index) then
		return false
	end
	local v1081_ = xmlFile:getValue(key .. "#disablingAttacherJointNodes", nil, self.components, self.i3dMappings, true)
	if #v1081_ > 0 then
		entry.disablingAttacherJointNodes = v1081_
	end
	return true
end

-- Local values: spec, fillUnit, _, jointNode, jointIndex, _, jointIndex
function AttacherJoints:getFillUnitSupportsToolType(superFunc, fillUnitIndex, toolType)
	if not superFunc(self, fillUnitIndex, toolType) then
		return false
	end
	local v1086_ = self.spec_fillUnit.fillUnits[fillUnitIndex]
	if v1086_ ~= nil then
		if v1086_.disablingAttacherJointNodes ~= nil then
			v1086_.disablingAttacherJointIndices = {}
			for _, v1087_ in ipairs(v1086_.disablingAttacherJointNodes) do
				local v1088_ = self:getAttacherJointIndexByNode(v1087_)
				if v1088_ ~= nil then
					local v1089_ = v1086_.disablingAttacherJointIndices
					table.insert(v1089_, v1088_)
				end
			end
			if #v1086_.disablingAttacherJointIndices == 0 then
				v1086_.disablingAttacherJointIndices = nil
			end
		end
		if v1086_.disablingAttacherJointIndices ~= nil then
			for _, v1090_ in ipairs(v1086_.disablingAttacherJointIndices) do
				if self:getImplementFromAttacherJointIndex(v1090_) ~= nil then
					return false
				end
			end
		end
	end
	return true
end

-- Local values: detachAllowed, warning, showWarning, spec, attacherJointIndex, attacherJoint, implement, inputAttacherJoint
function AttacherJoints:isDetachAllowed(superFunc)
	local v1093_, v1094_, v1095_ = superFunc(self)
	if not v1093_ then
		return v1093_, v1094_, v1095_
	end
	local v1096_ = self.spec_attacherJoints
	for v1097_, v1098_ in ipairs(v1096_.attacherJoints) do
		if not (v1098_.allowDetachingWhileLifted or v1098_.moveDown) then
			local v1099_ = self:getImplementByJointDescIndex(v1097_)
			if v1099_ ~= nil then
				local v1100_ = v1099_.object:getInputAttacherJointByJointDescIndex(v1099_.inputJointDescIndex)
				if v1100_ ~= nil and not v1100_.forceAllowDetachWhileLifted then
					return false, string.format(v1096_.texts.lowerImplementFirst, v1099_.object.typeDesc)
				end
			end
		end
	end
	return true
end

-- Local values: spec, attacherJointIndex, attacherJoint
function AttacherJoints:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	local v1105_ = self.spec_attacherJoints
	for _, v1106_ in ipairs(v1105_.attacherJoints) do
		if not v1106_.allowFoldingWhileAttached and v1106_.jointIndex ~= 0 then
			return false, v1105_.texts.warningFoldingAttacherJoint
		end
	end
	return superFunc(self, direction, onAiTurnOn)
end

-- Local values: spec, _, implement, object
function AttacherJoints:getIsWheelFoliageDestructionAllowed(superFunc, wheel)
	if not superFunc(self, wheel) then
		return false
	end
	local v1110_ = self.spec_attacherJoints
	for _, v1111_ in pairs(v1110_.attachedImplements) do
		local v1112_ = v1111_.object
		if v1112_ ~= nil and (v1112_.getBlockFoliageDestruction ~= nil and v1112_:getBlockFoliageDestruction()) then
			return false
		end
	end
	return true
end

-- Local values: allowed, warning, spec, _, implement, object
function AttacherJoints:getAreControlledActionsAllowed(superFunc)
	local v1115_, v1116_ = superFunc(self)
	if not v1115_ then
		return false, v1116_
	end
	local v1117_ = self.spec_attacherJoints
	for _, v1118_ in pairs(v1117_.attachedImplements) do
		local v1119_ = v1118_.object
		if v1119_ ~= nil and v1119_.getAreControlledActionsAllowed ~= nil then
			local v1120_
			v1120_, v1116_ = v1119_:getAreControlledActionsAllowed()
			if not v1120_ then
				return false, v1116_
			end
		end
		if v1118_.attachingIsInProgress then
			return false
		end
	end
	return true, v1116_
end

-- Local values: index, configKey
function AttacherJoints:getConnectionHoseConfigIndex(superFunc)
	local v1123_ = superFunc(self)
	local v1124_ = self.xmlFile:getValue("vehicle.attacherJoints#connectionHoseConfigId", v1123_)
	if self.configurations.attacherJoint ~= nil then
		local v1125_ = string.format("vehicle.attacherJoints.attacherJointConfigurations.attacherJointConfiguration(%d)", self.configurations.attacherJoint - 1)
		v1124_ = self.xmlFile:getValue(v1125_ .. "#connectionHoseConfigId", v1124_)
	end
	return v1124_
end

-- Local values: index, configKey
function AttacherJoints:getPowerTakeOffConfigIndex(superFunc)
	local v1128_ = superFunc(self)
	local v1129_ = self.xmlFile:getValue("vehicle.attacherJoints#powerTakeOffConfigId", v1128_)
	if self.configurations.attacherJoint ~= nil then
		local v1130_ = string.format("vehicle.attacherJoints.attacherJointConfigurations.attacherJointConfiguration(%d)", self.configurations.attacherJoint - 1)
		v1129_ = self.xmlFile:getValue(v1130_ .. "#powerTakeOffConfigId", v1129_)
	end
	return v1129_
end

-- Local values: attacherJointNodes
function AttacherJoints:loadHoseTargetNode(superFunc, xmlFile, targetKey, entry)
	if not superFunc(self, xmlFile, targetKey, entry) then
		return false
	end
	local v1136_ = xmlFile:getValue(targetKey .. "#blockedByAttacherJointNodes", nil, self.components, self.i3dMappings, true)
	if v1136_ ~= nil then
		entry.blockedByAttacherJointIndices = v1136_
	end
	return true
end

-- Local values: _, jointNode, jointIndex, implement
function AttacherJoints:getIsConnectionTargetUsed(superFunc, desc)
	if superFunc(self, desc) then
		return true
	end
	if desc.blockedByAttacherJointIndices ~= nil then
		for _, v1140_ in ipairs(desc.blockedByAttacherJointIndices) do
			local v1141_ = self:getAttacherJointIndexByNode(v1140_)
			if v1141_ ~= nil and self:getImplementFromAttacherJointIndex(v1141_) ~= nil then
				return true
			end
		end
	end
	return false
end

-- Local values: spec, selectedImplement, _, attachedImplement, _, actionEventId, state, _, firstImplement, _, actionEventId
function AttacherJoints:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v1144_ = self.spec_attacherJoints
		self:clearActionEventsTable(v1144_.actionEvents)
		if isActiveForInputIgnoreSelection then
			if #v1144_.attacherJoints > 0 then
				local v1145_ = self:getSelectedImplement()
				if v1145_ ~= nil and v1145_.object ~= self then
					for _, v1146_ in pairs(v1144_.attachedImplements) do
						if v1146_ == v1145_ then
							v1145_.object:registerLoweringActionEvent(v1144_.actionEvents, InputAction.LOWER_IMPLEMENT, v1145_.object, AttacherJoints.actionEventLowerImplement, false, true, false, true, nil, nil, true)
						end
					end
				end
				local _, v1147_ = self:addPoweredActionEvent(v1144_.actionEvents, InputAction.LOWER_ALL_IMPLEMENTS, self, AttacherJoints.actionEventLowerAllImplements, false, true, false, true, nil, nil, true)
				g_inputBinding:setActionEventTextVisibility(v1147_, false)
			end
			if self:getSelectedVehicle() == self then
				local v1148_, _ = self:registerSelfLoweringActionEvent(v1144_.actionEvents, InputAction.LOWER_IMPLEMENT, self, AttacherJoints.actionEventLowerImplement, false, true, false, true, nil, nil, true)
				if (v1148_ == nil or not v1148_) and #v1144_.attachedImplements == 1 then
					local v1149_ = v1144_.attachedImplements[1]
					if v1149_ ~= nil then
						v1149_.object:registerLoweringActionEvent(v1144_.actionEvents, InputAction.LOWER_IMPLEMENT, v1149_.object, AttacherJoints.actionEventLowerImplement, false, true, false, true, nil, nil, true)
					end
				end
			end
			local _, v1150_ = self:addActionEvent(v1144_.actionEvents, InputAction.ATTACH, self, AttacherJoints.actionEventAttach, false, true, false, true, nil, nil, true)
			g_inputBinding:setActionEventTextPriority(v1150_, GS_PRIO_VERY_HIGH)
			local _, v1151_ = self:addActionEvent(v1144_.actionEvents, InputAction.DETACH, self, AttacherJoints.actionEventDetach, false, true, false, true, nil, nil, true)
			g_inputBinding:setActionEventTextVisibility(v1151_, false)
			AttacherJoints.updateActionEvents(self)
		end
	end
end

function AttacherJoints:onActivate()
	self:activateAttachments()
end

-- Local values: spec
function AttacherJoints:onDeactivate()
	self:deactivateAttachments()
	if self.isClient then
		local v1154_ = self.spec_attacherJoints
		g_soundManager:stopSample(v1154_.samples.hydraulic)
		v1154_.isHydraulicSamplePlaying = false
	end
end

-- Local values: spec, reverserDirection, _, joint
function AttacherJoints:onReverseDirectionChanged(direction)
	local v1156_ = self.spec_attacherJoints
	local v1157_ = self:getReverserDirection()
	if v1156_.attacherJointCombos ~= nil then
		for _, v1158_ in pairs(v1156_.attacherJointCombos.joints) do
			if v1157_ < 0 then
				local v1159_ = v1158_.initialTime - v1156_.attacherJointCombos.duration
				v1158_.time = math.abs(v1159_)
			else
				v1158_.time = v1158_.initialTime
			end
		end
	end
end

-- Local values: spec, _, implement
function AttacherJoints:onStateChange(state, data)
	local v1163_ = self.spec_attacherJoints
	for _, v1164_ in pairs(v1163_.attachedImplements) do
		if v1164_.object ~= nil then
			v1164_.object:raiseStateChange(state, data)
		end
	end
	if state == VehicleStateChange.LOWER_ALL_IMPLEMENTS and #v1163_.attacherJoints > 0 then
		self:startAttacherJointCombo()
	end
end

-- Local values: spec, _, implement, vehicle
function AttacherJoints:onLightsTypesMaskChanged(lightsTypesMask)
	if self.isServer then
		local v1167_ = self.spec_attacherJoints
		for _, v1168_ in pairs(v1167_.attachedImplements) do
			local v1169_ = v1168_.object
			if v1169_ ~= nil and v1169_.setLightsTypesMask ~= nil then
				v1169_:setLightsTypesMask(lightsTypesMask, true)
			end
		end
	end
end

-- Local values: spec, _, implement, vehicle
function AttacherJoints:onTurnLightStateChanged(state)
	local v1172_ = self.spec_attacherJoints
	for _, v1173_ in pairs(v1172_.attachedImplements) do
		local v1174_ = v1173_.object
		if v1174_ ~= nil and v1174_.setTurnLightState ~= nil then
			v1174_:setTurnLightState(state, true, true)
		end
	end
end

-- Local values: spec, _, implement, vehicle
function AttacherJoints:onBrakeLightsVisibilityChanged(visibility)
	local v1177_ = self.spec_attacherJoints
	for _, v1178_ in pairs(v1177_.attachedImplements) do
		local v1179_ = v1178_.object
		if v1179_ ~= nil and v1179_.setBrakeLightsVisibility ~= nil then
			v1179_:setBrakeLightsVisibility(visibility)
		end
	end
end

-- Local values: spec, _, implement, vehicle
function AttacherJoints:onReverseLightsVisibilityChanged(visibility)
	local v1182_ = self.spec_attacherJoints
	for _, v1183_ in pairs(v1182_.attachedImplements) do
		local v1184_ = v1183_.object
		if v1184_ ~= nil and v1184_.setReverseLightsVisibility ~= nil then
			v1184_:setReverseLightsVisibility(visibility)
		end
	end
end

-- Local values: spec, _, implement, vehicle
function AttacherJoints:onBeaconLightsVisibilityChanged(visibility)
	local v1187_ = self.spec_attacherJoints
	for _, v1188_ in pairs(v1187_.attachedImplements) do
		local v1189_ = v1188_.object
		if v1189_ ~= nil and v1189_.setBeaconLightsVisibility ~= nil then
			v1189_:setBeaconLightsVisibility(visibility, true, true)
		end
	end
end

-- Local values: spec, _, implement, vehicle
function AttacherJoints:onBrake(brakePedal)
	local v1192_ = self.spec_attacherJoints
	for _, v1193_ in pairs(v1192_.attachedImplements) do
		local v1194_ = v1193_.object
		if v1194_ ~= nil and v1194_.brake ~= nil then
			v1194_:brake(brakePedal)
		end
	end
end

-- Local values: spec, _, implement, vehicle, turnedOnVehicleSpec
function AttacherJoints:onTurnedOn()
	local v1196_ = self.spec_attacherJoints
	for _, v1197_ in pairs(v1196_.attachedImplements) do
		local v1198_ = v1197_.object
		if v1198_ ~= nil then
			local v1199_ = v1198_.spec_turnOnVehicle
			if v1199_ and v1199_.turnedOnByAttacherVehicle then
				v1198_:setIsTurnedOn(true, true)
			end
		end
	end
end

-- Local values: spec, _, implement, vehicle, turnedOnVehicleSpec
function AttacherJoints:onTurnedOff()
	local v1201_ = self.spec_attacherJoints
	for _, v1202_ in pairs(v1201_.attachedImplements) do
		local v1203_ = v1202_.object
		if v1203_ ~= nil then
			local v1204_ = v1203_.spec_turnOnVehicle
			if v1204_ and v1204_.turnedOnByAttacherVehicle then
				v1203_:setIsTurnedOn(false, true)
			end
		end
	end
end

-- Local values: spec, _, implement, vehicle
function AttacherJoints:onLeaveVehicle()
	local v1206_ = self.spec_attacherJoints
	for _, v1207_ in pairs(v1206_.attachedImplements) do
		local v1208_ = v1207_.object
		if v1208_ ~= nil then
			SpecializationUtil.raiseEvent(v1208_, "onLeaveRootVehicle")
		end
	end
end

-- Local values: spec, info
function AttacherJoints:getAttachableInfo()
	local v1210_ = self.spec_attacherJoints.attachableInfo
	return v1210_.attacherVehicle, v1210_.attacherVehicleJointDescIndex, v1210_.attachable, v1210_.attachableJointDescIndex
end

-- Local values: found, i, j, found, i, brandString, i, found, i, compatibility, warning
function AttacherJoints.getAttacherJointCompatibility(vehicle, attacherJoint, inputAttacherVehicle, inputAttacherJoint)
	if inputAttacherJoint.forcedAttachingDirection ~= 0 and (attacherJoint.attacherJointDirection ~= nil and inputAttacherJoint.forcedAttachingDirection ~= attacherJoint.attacherJointDirection) then
		return false
	end
	if attacherJoint.isBlocked then
		return false
	end
	if attacherJoint.subTypes == nil then
		if inputAttacherJoint.subTypes ~= nil then
			if inputAttacherJoint.subTypeShowWarning and attacherJoint.subTypeShowWarning then
				return false, vehicle.spec_attacherJoints.texts.warningToolNotCompatible
			else
				return false
			end
		end
	else
		if inputAttacherJoint.subTypes == nil then
			if attacherJoint.subTypeShowWarning and inputAttacherJoint.subTypeShowWarning then
				return false, vehicle.spec_attacherJoints.texts.warningToolNotCompatible
			else
				return false
			end
		end
		local v1215_ = false
		for v1216_ = 1, #attacherJoint.subTypes do
			for v1217_ = 1, #inputAttacherJoint.subTypes do
				if attacherJoint.subTypes[v1216_] == inputAttacherJoint.subTypes[v1217_] then
					v1215_ = true
					break
				end
			end
		end
		if not v1215_ then
			if attacherJoint.subTypeShowWarning and inputAttacherJoint.subTypeShowWarning then
				return false, vehicle.spec_attacherJoints.texts.warningToolNotCompatible
			else
				return false
			end
		end
	end
	if attacherJoint.brandRestrictions ~= nil then
		local v1218_ = false
		for v1219_ = 1, #attacherJoint.brandRestrictions do
			if inputAttacherVehicle.brand ~= nil and inputAttacherVehicle.brand == attacherJoint.brandRestrictions[v1219_] then
				v1218_ = true
				break
			end
		end
		if not v1218_ then
			local v1220_ = ""
			for v1221_ = 1, #attacherJoint.brandRestrictions do
				if v1221_ > 1 then
					v1220_ = v1220_ .. ", "
				end
				v1220_ = v1220_ .. attacherJoint.brandRestrictions[v1221_].title
			end
			return false, string.format(vehicle.spec_attacherJoints.texts.warningToolBrandNotCompatible, v1220_)
		end
	end
	if attacherJoint.vehicleRestrictions ~= nil then
		local v1222_ = false
		for v1223_ = 1, #attacherJoint.vehicleRestrictions do
			if inputAttacherVehicle.configFileName:find(attacherJoint.vehicleRestrictions[v1223_]) ~= nil then
				v1222_ = true
				break
			end
		end
		if not v1222_ then
			return false, vehicle.spec_attacherJoints.texts.warningToolNotCompatible
		end
	end
	local v1224_, v1225_ = vehicle:getIsAttacherJointCompatible(vehicle, attacherJoint, inputAttacherVehicle, inputAttacherJoint)
	if v1224_ then
		return true
	else
		return false, v1225_
	end
end
local v_u_1226_ = AttacherJoints.getAttacherJointCompatibility
function AttacherJoints.findVehicleInAttachRange()
	log("function \'AttacherJoints.findVehicleInAttachRange\' is deprecated. Use \'AttacherJoints.updateVehiclesInAttachRange\' instead. Valid output of this function is now up to 5 frames delayed, if parameter 4 is not \'true\'.")
end

-- Upvalues: getAttacherJointCompatibility
-- Local values: spec, attachableInfo, pendingInfo, implements, _, implement, attacherVehicle, attacherVehicleJointDescIndex, attachable, attachableJointDescIndex, warning, numJoints, minUpdateJoints, firstJoint, lastJoint, attacherJointIndex, attacherJoint, x, y, z, i, jointInfo, distSq, distY, distSqY, compatibility, notAllowedWarning, angleInRange, attachAngleLimitAxis, dx, _, _, _, dy, _, _, _, dz
function AttacherJoints.updateVehiclesInAttachRange(vehicle, maxDistanceSq, maxAngle, fullUpdate)
	-- upvalues: (copy) v_u_1226_
	local v1231_ = vehicle.spec_attacherJoints
	if v1231_ == nil then
		return nil, nil, nil, nil
	end
	local v1232_ = v1231_.attachableInfo
	local v1233_ = v1231_.pendingAttachableInfo
	if vehicle.getAttachedImplements ~= nil then
		local v1234_ = vehicle:getAttachedImplements()
		for _, v1235_ in pairs(v1234_) do
			if v1235_.object ~= nil then
				local v1236_, v1237_, v1238_, v1239_, v1240_ = AttacherJoints.updateVehiclesInAttachRange(v1235_.object, maxDistanceSq, maxAngle, fullUpdate)
				if v1236_ ~= nil then
					v1232_.attacherVehicle = v1236_
					v1232_.attacherVehicleJointDescIndex = v1237_
					v1232_.attachable = v1238_
					v1232_.attachableJointDescIndex = v1239_
					v1232_.warning = v1240_
					return v1236_, v1237_, v1238_, v1239_, v1240_
				end
			end
		end
	end
	local v1241_ = #g_currentMission.vehicleSystem.inputAttacherJoints
	local v1242_ = v1241_ / 5
	local v1243_ = math.floor(v1242_)
	local v1244_ = math.max(v1243_, 1)
	local v1245_ = v1231_.lastInputAttacherCheckIndex % v1241_ + 1
	local v1246_ = v1245_ + v1244_
	local v1247_ = math.min(v1246_, v1241_)
	if fullUpdate then
		v1247_ = v1241_
		v1245_ = 1
	end
	v1231_.lastInputAttacherCheckIndex = v1247_ % v1241_
	for v1248_ = 1, #v1231_.attacherJoints do
		local v1249_ = v1231_.attacherJoints[v1248_]
		if v1249_.jointIndex == 0 and vehicle:getIsAttachingAllowed(v1249_) then
			local v1250_, v1251_, v1252_ = getWorldTranslation(v1249_.jointTransform)
			for v1253_ = v1245_, v1247_ do
				local v1254_ = g_currentMission.vehicleSystem.inputAttacherJoints[v1253_]
				if v1254_.jointType == v1249_.jointType and v1254_.vehicle:getIsInputAttacherActive(v1254_.inputAttacherJoint) then
					local v1255_ = MathUtil.vector2LengthSq(v1250_ - v1254_.translation[1], v1252_ - v1254_.translation[3])
					if v1255_ < maxDistanceSq and v1255_ < v1233_.minDistance then
						local v1256_ = v1251_ - v1254_.translation[2]
						local v1257_ = v1256_ * v1256_
						if v1257_ < maxDistanceSq * 4 and (v1257_ < v1233_.minDistanceY and (v1254_.vehicle:getActiveInputAttacherJointDescIndex() == nil or v1254_.vehicle:getAllowMultipleAttachments())) then
							local v1258_, v1259_ = v_u_1226_(vehicle, v1249_, v1254_.vehicle, v1254_.inputAttacherJoint)
							if v1258_ then
								local v1260_ = v1254_.inputAttacherJoint.attachAngleLimitAxis
								local v1261_
								if v1260_ == 1 then
									local v1262_, _, _ = localDirectionToLocal(v1254_.node, v1249_.jointTransform, 1, 0, 0)
									v1261_ = maxAngle < v1262_
								elseif v1260_ == 2 then
									local _, v1263_, _ = localDirectionToLocal(v1254_.node, v1249_.jointTransform, 0, 1, 0)
									v1261_ = maxAngle < v1263_
								else
									local _, _, v1264_ = localDirectionToLocal(v1254_.node, v1249_.jointTransform, 0, 0, 1)
									v1261_ = maxAngle < v1264_
								end
								if v1261_ then
									v1233_.minDistance = v1255_
									v1233_.minDistanceY = v1257_
									v1233_.attacherVehicle = vehicle
									v1233_.attacherVehicleJointDescIndex = v1248_
									v1233_.attachable = v1254_.vehicle
									v1233_.attachableJointDescIndex = v1254_.jointIndex
								end
							else
								v1233_.warning = v1233_.warning or v1259_
							end
						end
					end
				end
			end
		end
	end
	if v1231_.lastInputAttacherCheckIndex == 0 or v1241_ == 0 then
		v1232_.attacherVehicle = v1233_.attacherVehicle
		v1232_.attacherVehicleJointDescIndex = v1233_.attacherVehicleJointDescIndex
		v1232_.attachable = v1233_.attachable
		v1232_.attachableJointDescIndex = v1233_.attachableJointDescIndex
		v1232_.warning = v1233_.warning
		v1233_.minDistance = math.huge
		v1233_.minDistanceY = math.huge
		v1233_.attacherVehicle = nil
		v1233_.attacherVehicleJointDescIndex = nil
		v1233_.attachable = nil
		v1233_.attachableJointDescIndex = nil
		v1233_.warning = nil
	end
	return v1232_.attacherVehicle, v1232_.attacherVehicleJointDescIndex, v1232_.attachable, v1232_.attachableJointDescIndex, v1232_.warning
end

-- Local values: info, attachAllowed, warning, object, detachAllowed, warning, showWarning
function AttacherJoints:actionEventAttach(actionName, inputValue, callbackState, isAnalog)
	local v1266_ = self.spec_attacherJoints.attachableInfo
	if v1266_.attachable == nil then
		local v1267_ = self:getSelectedVehicle()
		if v1267_ ~= nil and (v1267_ ~= self and v1267_.isDetachAllowed ~= nil) then
			local v1268_, v1269_, v1270_ = v1267_:isDetachAllowed()
			if v1268_ then
				v1267_:startDetachProcess()
				return
			end
			if v1270_ == nil or v1270_ then
				g_currentMission:showBlinkingWarning(v1269_ or self.spec_attacherJoints.texts.detachNotAllowed, 2000)
			end
		end
	else
		local v1271_, v1272_ = v1266_.attachable:isAttachAllowed(self:getActiveFarm(), v1266_.attacherVehicle)
		if v1271_ then
			if self.isServer then
				self:attachImplementFromInfo(v1266_)
			else
				g_client:getServerConnection():sendEvent(VehicleAttachRequestEvent.new(v1266_))
			end
		end
		if v1272_ ~= nil then
			g_currentMission:showBlinkingWarning(v1272_, 2000)
			return
		end
	end
end

-- Local values: object, detachAllowed, warning, showWarning
function AttacherJoints:actionEventDetach(actionName, inputValue, callbackState, isAnalog)
	local v1274_ = self:getSelectedVehicle()
	if v1274_ ~= nil and (v1274_ ~= self and v1274_.isDetachAllowed ~= nil) then
		local v1275_, v1276_, v1277_ = v1274_:isDetachAllowed()
		if v1275_ then
			v1274_:startDetachProcess()
			return
		end
		if v1277_ == nil or v1277_ then
			g_currentMission:showBlinkingWarning(v1276_ or self.spec_attacherJoints.texts.detachNotAllowed, 2000)
		end
	end
end

function AttacherJoints:actionEventLowerImplement(actionName, inputValue, callbackState, isAnalog)
	if self.getAttacherVehicle ~= nil then
		self:getAttacherVehicle():handleLowerImplementEvent()
	end
end

function AttacherJoints:actionEventLowerAllImplements(actionName, inputValue, callbackState, isAnalog)
	self:startAttacherJointCombo(true)
	self.rootVehicle:raiseStateChange(VehicleStateChange.LOWER_ALL_IMPLEMENTS)
end

-- Local values: spec, info, attachActionEvent, visible, text, prio, selectedVehicle, lowerActionEvent, showLower, text, selectedImplement, _, attachedImplement, attachedImplement
function AttacherJoints:updateActionEvents()
	local v1281_ = self.spec_attacherJoints
	local v1282_ = v1281_.attachableInfo
	if self.isClient and v1281_.actionEvents ~= nil then
		local v1283_ = v1281_.actionEvents[InputAction.ATTACH]
		if v1283_ ~= nil then
			local v1284_ = false
			if self:getCanToggleAttach() then
				if v1282_.warning ~= nil then
					g_currentMission:showBlinkingWarning(v1282_.warning, 500)
				end
				local v1285_ = GS_PRIO_VERY_LOW
				local v1286_ = self:getSelectedVehicle()
				local v1287_
				if v1286_ == nil or (v1286_.isDeleted or (v1286_.isDetachAllowed == nil or (not v1286_:isDetachAllowed() or v1286_:getAttacherVehicle() == nil))) then
					v1287_ = ""
				else
					v1287_ = v1281_.texts.actionDetach
					v1284_ = true
				end
				if v1282_.attacherVehicle ~= nil then
					if g_currentMission.accessHandler:canFarmAccess(self:getActiveFarm(), v1282_.attachable) then
						v1287_ = v1281_.texts.actionAttach
						g_currentMission:showAttachContext(v1282_.attachable)
						v1285_ = GS_PRIO_VERY_HIGH
						v1284_ = true
					else
						v1281_.showAttachNotAllowedText = 100
					end
				end
				g_inputBinding:setActionEventText(v1283_.actionEventId, v1287_)
				g_inputBinding:setActionEventTextPriority(v1283_.actionEventId, v1285_)
			end
			g_inputBinding:setActionEventTextVisibility(v1283_.actionEventId, v1284_)
		end
		local v1288_ = v1281_.actionEvents[InputAction.LOWER_IMPLEMENT]
		if v1288_ ~= nil then
			local v1289_ = false
			local v1290_ = ""
			local v1291_ = self:getSelectedImplement()
			if v1291_ == nil then
				if #v1281_.attachedImplements == 1 then
					v1289_, v1290_ = v1281_.attachedImplements[1].object:getLoweringActionEventState()
				end
			else
				for _, v1292_ in pairs(v1281_.attachedImplements) do
					if v1292_ == v1291_ then
						v1289_, v1290_ = v1292_.object:getLoweringActionEventState()
						break
					end
				end
			end
			g_inputBinding:setActionEventActive(v1288_.actionEventId, v1289_)
			g_inputBinding:setActionEventText(v1288_.actionEventId, v1290_)
			g_inputBinding:setActionEventTextPriority(v1288_.actionEventId, GS_PRIO_NORMAL)
		end
	end
end

-- Local values: lowerRotLimit, upperRotLimit, upperTransLimit, lowerTransLimit, rotLimit, transLimit
function AttacherJoints.updateAttacherJointLimits(implement, attacherJointDesc, inputAttacherJointDesc, axis)
	local v1297_ = attacherJointDesc.lowerRotLimit[axis] * inputAttacherJointDesc.lowerRotLimitScale[axis]
	local v1298_ = attacherJointDesc.upperRotLimit[axis] * inputAttacherJointDesc.upperRotLimitScale[axis]
	if inputAttacherJointDesc.fixedRotation then
		v1297_ = 0
		v1298_ = 0
	end
	local v1299_ = attacherJointDesc.lowerTransLimit[axis] * inputAttacherJointDesc.lowerTransLimitScale[axis]
	local v1300_ = attacherJointDesc.upperTransLimit[axis] * inputAttacherJointDesc.upperTransLimitScale[axis]
	implement.lowerRotLimit[axis] = v1297_
	implement.upperRotLimit[axis] = v1298_
	implement.lowerTransLimit[axis] = v1299_
	implement.upperTransLimit[axis] = v1300_
	if not attacherJointDesc.allowsLowering then
		implement.upperRotLimit[axis] = v1297_
		implement.upperTransLimit[axis] = v1299_
	end
	if attacherJointDesc.allowsLowering and attacherJointDesc.allowsJointLimitMovement then
		if inputAttacherJointDesc.allowsJointRotLimitMovement then
			v1297_ = MathUtil.lerp(v1298_, v1297_, attacherJointDesc.moveAlpha)
		end
		if inputAttacherJointDesc.allowsJointTransLimitMovement then
			v1299_ = MathUtil.lerp(v1300_, v1299_, attacherJointDesc.moveAlpha)
		end
	end
	return v1297_, v1299_
end

-- Local values: newRotLimit, rotLimitDown, rotLimitUp, rotLimit
function AttacherJoints.updateAttacherJointRotationLimit(implement, attacherJointDesc, axis, force, alpha)
	local v1306_ = MathUtil.lerp
	local v1307_ = implement.attachingRotLimit[axis]
	local v1308_ = implement.upperRotLimit[axis]
	local v1309_ = math.max(v1307_, v1308_)
	local v1310_ = implement.attachingRotLimit[axis]
	local v1311_ = implement.lowerRotLimit[axis]
	local v1312_ = v1306_(v1309_, math.max(v1310_, v1311_), alpha)
	if not force then
		local v1313_ = v1312_ - implement.jointRotLimit[axis]
		if math.abs(v1313_) <= 0.0005 then
			::l3::
			return
		end
	end
	local v1314_ = -v1312_
	local v1315_
	if axis == 3 then
		if attacherJointDesc.lockDownRotLimit then
			local v1316_ = -implement.attachingRotLimit[axis]
			v1314_ = math.min(v1316_, 0)
		end
		if attacherJointDesc.lockUpRotLimit then
			local v1317_ = implement.attachingRotLimit[axis]
			v1315_ = math.max(v1317_, 0)
		else
			v1315_ = v1312_
		end
		if attacherJointDesc.dynamicLowerRotLimit and attacherJointDesc.rotationNode ~= nil then
			local v1318_ = attacherJointDesc.upperRotation[1] - attacherJointDesc.lowerRotation[1]
			v1315_ = math.abs(v1318_) * alpha
			v1314_ = 0
		end
	else
		v1315_ = v1312_
	end
	setJointRotationLimit(attacherJointDesc.jointIndex, axis - 1, true, v1314_, v1315_)
	implement.jointRotLimit[axis] = v1312_
	goto l3
end

-- Local values: newTransLimit, transLimitDown, transLimitUp
function AttacherJoints.updateAttacherJointTranslationLimit(implement, attacherJointDesc, axis, force, alpha)
	local v1324_ = MathUtil.lerp
	local v1325_ = implement.attachingTransLimit[axis]
	local v1326_ = implement.upperTransLimit[axis]
	local v1327_ = math.max(v1325_, v1326_)
	local v1328_ = implement.attachingTransLimit[axis]
	local v1329_ = implement.lowerTransLimit[axis]
	local v1330_ = v1324_(v1327_, math.max(v1328_, v1329_), alpha)
	if force then
		::l2::
		local v1331_ = -v1330_
		local v1332_
		if axis == 2 then
			if attacherJointDesc.lockDownTransLimit then
				local v1333_ = -implement.attachingTransLimit[axis]
				v1331_ = math.min(v1333_, 0)
			end
			if attacherJointDesc.lockUpTransLimit then
				local v1334_ = implement.attachingTransLimit[axis]
				v1332_ = math.max(v1334_, 0)
			else
				v1332_ = v1330_
			end
		else
			v1332_ = v1330_
		end
		setJointTranslationLimit(attacherJointDesc.jointIndex, axis - 1, true, v1331_, v1332_)
		implement.jointTransLimit[axis] = v1330_
	else
		local v1335_ = v1330_ - implement.jointTransLimit[axis]
		if math.abs(v1335_) > 0.0005 then
			goto l2
		end
	end
end

-- Local values: spec, requiresTopLights, i, implement, attacherJoint, implementJoint
function AttacherJoints:updateRequiredTopLightsState()
	local v1337_ = self.spec_attacherJoints
	local v1338_ = false
	for _, v1339_ in ipairs(v1337_.attachedImplements) do
		local v1340_ = v1337_.attacherJoints[v1339_.jointDescIndex]
		local v1341_ = v1339_.object:getActiveInputAttacherJoint()
		if v1340_.useTopLights and v1341_.useTopLights then
			v1338_ = true
			break
		end
	end
	SpecializationUtil.raiseEvent(self, "onRequiresTopLightsChanged", v1338_)
end

-- Local values: i, vehicle, spec, jointDescIndex, _
function AttacherJoints.consoleCommandBottomArmWidth(_, category, width)
	local v1344_
	if width == nil then
		v1344_ = AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[tonumber(category) or 2]
	else
		v1344_ = tonumber(width) or AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[2]
	end
	Logging.info("Set bottom arm width to %.3f m. (Category %d)", v1344_, AttacherJoints.getClosestLowerLinkCategoryIndex(v1344_))
	if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
		for _, v1345_ in ipairs(g_localPlayer:getCurrentVehicle().childVehicles) do
			local v1346_ = v1345_.spec_attacherJoints
			if v1346_ ~= nil then
				for v1347_, _ in ipairs(v1346_.attacherJoints) do
					v1345_:setAttacherJointBottomArmWidth(v1347_, v1344_)
				end
			end
		end
	end
end
addConsoleCommand("gsVehicleBottomArmSetWidth", "Sets the width of the bottom arm to a certain category width", "consoleCommandBottomArmWidth", AttacherJoints)
