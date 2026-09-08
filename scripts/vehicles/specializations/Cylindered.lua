Cylindered = {}
Cylindered.DIRTY_COLLISION_UPDATE_CHECK = false
Cylindered.MOVING_TOOL_SEND_MIN_RESOLUTION = 0.006981317007977318
Cylindered.MOVING_TOOLS_XML_KEYS = { "vehicle.cylindered.movingTools", "vehicle.cylindered.cylinderedConfigurations.cylinderedConfiguration(?).movingTools" }
Cylindered.MOVING_PART_XML_KEYS = { "vehicle.cylindered.movingParts.movingPart(?)", "vehicle.cylindered.cylinderedConfigurations.cylinderedConfiguration(?).movingParts.movingPart(?)" }
Cylindered.DASHBOARD_XML_KEYS = { "vehicle.cylindered.dashboards", "vehicle.cylindered.cylinderedConfigurations.cylinderedConfiguration(?).dashboards" }
Cylindered.SOUND_TYPE_EVENT = 0
Cylindered.SOUND_TYPE_CONTINUES = 1
Cylindered.SOUND_TYPE_ENDING = 2
Cylindered.SOUND_TYPE_STARTING = 3
Cylindered.SOUND_ACTION_TRANSLATING_END = 0
Cylindered.SOUND_ACTION_TRANSLATING_END_POS = 1
Cylindered.SOUND_ACTION_TRANSLATING_END_NEG = 2
Cylindered.SOUND_ACTION_TRANSLATING_START = 3
Cylindered.SOUND_ACTION_TRANSLATING_START_POS = 4
Cylindered.SOUND_ACTION_TRANSLATING_START_NEG = 5
Cylindered.SOUND_ACTION_TRANSLATING_POS = 6
Cylindered.SOUND_ACTION_TRANSLATING_NEG = 7
Cylindered.SOUND_ACTION_TOOL_MOVE_END = 8
Cylindered.SOUND_ACTION_TOOL_MOVE_END_POS = 9
Cylindered.SOUND_ACTION_TOOL_MOVE_END_NEG = 10
Cylindered.SOUND_ACTION_TOOL_MOVE_END_POS_LIMIT = 11
Cylindered.SOUND_ACTION_TOOL_MOVE_END_NEG_LIMIT = 12
Cylindered.SOUND_ACTION_TOOL_MOVE_START = 13
Cylindered.SOUND_ACTION_TOOL_MOVE_START_POS = 14
Cylindered.SOUND_ACTION_TOOL_MOVE_START_NEG = 15
Cylindered.SOUND_ACTION_TOOL_MOVE_START_POS_LIMIT = 16
Cylindered.SOUND_ACTION_TOOL_MOVE_START_NEG_LIMIT = 17
Cylindered.SOUND_ACTION_TOOL_MOVE_POS = 18
Cylindered.SOUND_ACTION_TOOL_MOVE_NEG = 19

function Cylindered.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(VehicleSettings, specializations)
end
function Cylindered.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("cylindered", g_i18n:getText("shop_configuration"), "cylindered", VehicleConfigurationItem)
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("Cylindered")
	v2_:register(XMLValueType.TIME, "vehicle.cylindered.movingTools#powerConsumingActiveTimeOffset", "Power consumer deactivation delay. After the moving tool has not been moved this long it will no longer consume power.", 5)
	Cylindered.registerSoundXMLPaths(v2_, "vehicle.cylindered.sounds")
	Cylindered.registerSoundXMLPaths(v2_, "vehicle.cylindered.cylinderedConfigurations.cylinderedConfiguration(?).sounds")
	for _, v3_ in ipairs(Cylindered.MOVING_TOOLS_XML_KEYS) do
		Cylindered.registerMovingToolXMLPaths(v2_, v3_ .. ".movingTool(?)")
		Cylindered.registerEasyArmControlXMLPaths(v2_, v3_ .. ".easyArmControl")
		v2_:register(XMLValueType.L10N_STRING, v3_ .. ".controlGroups.controlGroup(?)#name", "Control group name")
	end
	for _, v4_ in ipairs(Cylindered.MOVING_PART_XML_KEYS) do
		Cylindered.registerMovingPartXMLPaths(v2_, v4_)
	end
	v2_:addDelayedRegistrationFunc("Cylindered:movingPart", function(p5_, p6_)
		p5_:register(XMLValueType.INT, p6_ .. "#inputAttacherJointIndex", "Input Attacher Joint Index [1..n]")
	end)
	for _, v7_ in ipairs(Cylindered.DASHBOARD_XML_KEYS) do
		Dashboard.registerDashboardXMLPaths(v2_, v7_, { "movingTool" })
		v2_:register(XMLValueType.STRING, v7_ .. ".dashboard(?)#axis", "Moving tool input action name")
		v2_:register(XMLValueType.INT, v7_ .. ".dashboard(?)#attacherJointIndex", "Index of attacher joint that has to be connected")
		v2_:register(XMLValueType.NODE_INDEX, v7_ .. ".dashboard(?)#attacherJointNode", "Node of attacher joint that has to be connected")
		v2_:register(XMLValueType.NODE_INDICES, v7_ .. ".dashboard(?)#attacherJointNodes", "List of attacher joints nodes that has to be connected (on of them)")
	end
	ObjectChangeUtil.addAdditionalObjectChangeXMLPaths(v2_, function(p8_, p9_)
		p8_:register(XMLValueType.ANGLE, p9_ .. "#movingToolRotMaxActive", "Moving tool max. rotation if object change active")
		p8_:register(XMLValueType.ANGLE, p9_ .. "#movingToolRotMaxInactive", "Moving tool max. rotation if object change inactive")
		p8_:register(XMLValueType.ANGLE, p9_ .. "#movingToolRotMinActive", "Moving tool min. rotation if object change active")
		p8_:register(XMLValueType.ANGLE, p9_ .. "#movingToolRotMinInactive", "Moving tool min. rotation if object change inactive")
		p8_:register(XMLValueType.ANGLE, p9_ .. "#movingToolStartRotActive", "Moving tool start rotation if object change inactive")
		p8_:register(XMLValueType.ANGLE, p9_ .. "#movingToolStartRotInactive", "Moving tool start rotation if object change inactive")
		p8_:register(XMLValueType.FLOAT, p9_ .. "#movingToolTransMaxActive", "Moving tool max. translation if object change active")
		p8_:register(XMLValueType.FLOAT, p9_ .. "#movingToolTransMaxInactive", "Moving tool max. translation if object change inactive")
		p8_:register(XMLValueType.FLOAT, p9_ .. "#movingToolTransMinActive", "Moving tool min. translation if object change active")
		p8_:register(XMLValueType.FLOAT, p9_ .. "#movingToolTransMinInactive", "Moving tool min. translation if object change inactive")
		p8_:register(XMLValueType.FLOAT, p9_ .. "#movingToolStartTransActive", "Moving tool start translation if object change inactive")
		p8_:register(XMLValueType.FLOAT, p9_ .. "#movingToolStartTransInactive", "Moving tool start translation if object change inactive")
		p8_:register(XMLValueType.BOOL, p9_ .. "#movingPartUpdateActive", "moving part active state if object change active")
		p8_:register(XMLValueType.BOOL, p9_ .. "#movingPartUpdateInactive", "moving part active state if object change inactive")
	end)
	v2_:register(XMLValueType.NODE_INDEX, Dischargeable.DISCHARGE_NODE_XML_PATH .. ".movingToolActivation#node", "Moving tool node")
	v2_:register(XMLValueType.BOOL, Dischargeable.DISCHARGE_NODE_XML_PATH .. ".movingToolActivation#isInverted", "Activation is inverted", false)
	v2_:register(XMLValueType.FLOAT, Dischargeable.DISCHARGE_NODE_XML_PATH .. ".movingToolActivation#openFactor", "Open factor", 1)
	v2_:register(XMLValueType.FLOAT, Dischargeable.DISCHARGE_NODE_XML_PATH .. ".movingToolActivation#openOffset", "Open offset", 0)
	v2_:register(XMLValueType.NODE_INDEX, Dischargeable.DISCHARGE_NODE_CONFIG_XML_PATH .. ".movingToolActivation#node", "Moving tool node")
	v2_:register(XMLValueType.BOOL, Dischargeable.DISCHARGE_NODE_CONFIG_XML_PATH .. ".movingToolActivation#isInverted", "Activation is inverted", false)
	v2_:register(XMLValueType.FLOAT, Dischargeable.DISCHARGE_NODE_CONFIG_XML_PATH .. ".movingToolActivation#openFactor", "Open factor", 1)
	v2_:register(XMLValueType.FLOAT, Dischargeable.DISCHARGE_NODE_CONFIG_XML_PATH .. ".movingToolActivation#openOffset", "Open offset", 0)
	v2_:register(XMLValueType.NODE_INDEX, Shovel.SHOVEL_NODE_XML_KEY .. ".movingToolActivation#node", "Moving tool node")
	v2_:register(XMLValueType.BOOL, Shovel.SHOVEL_NODE_XML_KEY .. ".movingToolActivation#isInverted", "Activation is inverted", false)
	v2_:register(XMLValueType.FLOAT, Shovel.SHOVEL_NODE_XML_KEY .. ".movingToolActivation#openFactor", "Open factor", 1)
	v2_:register(XMLValueType.NODE_INDEX, DynamicMountAttacher.DYNAMIC_MOUNT_GRAB_XML_PATH .. ".movingToolActivation#node", "Moving tool node")
	v2_:register(XMLValueType.BOOL, DynamicMountAttacher.DYNAMIC_MOUNT_GRAB_XML_PATH .. ".movingToolActivation#isInverted", "Activation is inverted", false)
	v2_:register(XMLValueType.FLOAT, DynamicMountAttacher.DYNAMIC_MOUNT_GRAB_XML_PATH .. ".movingToolActivation#openFactor", "Open factor", 1)
	v2_:addDelayedRegistrationFunc("AnimatedVehicle:part", function(p10_, p11_)
		p10_:register(XMLValueType.NODE_INDEX, p11_ .. "#startReferencePoint", "Start reference point")
		p10_:register(XMLValueType.NODE_INDEX, p11_ .. "#endReferencePoint", "End reference point")
	end)
	v2_:setXMLSpecializationType()
	local v12_ = Vehicle.xmlSchemaSavegame
	v12_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).cylindered.movingTool(?)#translation", "Current translation value")
	v12_:register(XMLValueType.ANGLE, "vehicles.vehicle(?).cylindered.movingTool(?)#rotation", "Current rotation in rad")
	v12_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).cylindered.movingTool(?)#animationTime", "Current animation time")
end

function Cylindered.registerSoundXMLPaths(schema, baseKey)
	SoundManager.registerSampleXMLPaths(schema, baseKey, "hydraulic")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "actionSound(?)")
	schema:register(XMLValueType.STRING, baseKey .. ".actionSound(?)#actionNames", "Target actions on given nodes")
	schema:register(XMLValueType.STRING, baseKey .. ".actionSound(?)#nodes", "Nodes that can activate this sound on given action events")
	schema:register(XMLValueType.FLOAT, baseKey .. ".actionSound(?).pitch#dropOffFactor", "Factor that is applied to pitch while drop off time is active", 1)
	schema:register(XMLValueType.FLOAT, baseKey .. ".actionSound(?).pitch#dropOffTime", "After this time the sound will be deactivated", 0)
end

function Cylindered.registerEasyArmControlXMLPaths(schema, key)
	schema:register(XMLValueType.NODE_INDEX, key .. "#rootNode", "Root node")
	schema:register(XMLValueType.NODE_INDEX, key .. "#node", "Node")
	schema:register(XMLValueType.NODE_INDEX, key .. "#targetNodeZ", "Z target node")
	schema:register(XMLValueType.NODE_INDEX, key .. "#refNode", "Reference node")
	schema:register(XMLValueType.FLOAT, key .. "#maxTotalDistance", "Max. total distance the arms can move from rootNode", "automatically calculated")
	schema:register(XMLValueType.FLOAT, key .. ".targetMovement#speed", "Target node move speed", 1)
	schema:register(XMLValueType.FLOAT, key .. ".targetMovement#acceleration", "Target node move acceleration", 50)
	schema:register(XMLValueType.FLOAT, key .. ".zTranslationNodes#minMoveRatio", "Min. ratio between translation and rotation movement [0: only rotation, 1: only translation]", 0.2)
	schema:register(XMLValueType.FLOAT, key .. ".zTranslationNodes#maxMoveRatio", "Max. ratio between translation and rotation movement [0: only rotation, 1: only translation]", 0.8)
	schema:register(XMLValueType.FLOAT, key .. ".zTranslationNodes#moveRatioMinDir", "Defines direction value when the translation parts start to move", 0)
	schema:register(XMLValueType.FLOAT, key .. ".zTranslationNodes#moveRatioMaxDir", "Defines direction value when the rotation parts stop to move", 1)
	schema:register(XMLValueType.BOOL, key .. ".zTranslationNodes#allowNegativeTrans", "Allow translation movement if translation parts are pointing towards the root node", false)
	schema:register(XMLValueType.FLOAT, key .. ".zTranslationNodes#minNegativeTrans", "Min. translation percentage when moving the translation parts into negative direction while they are pointing towards the root node", 0)
	schema:register(XMLValueType.NODE_INDEX, key .. ".zTranslationNodes.zTranslationNode(?)#node", "Z translation node")
	schema:register(XMLValueType.NODE_INDEX, key .. ".xRotationNodes.xRotationNode1#node", "X translation node")
	schema:register(XMLValueType.NODE_INDEX, key .. ".xRotationNodes.xRotationNode2#node", "X translation node")
end

function Cylindered.registerMovingToolXMLPaths(schema, toolKey)
	schema:addDelayedRegistrationPath(toolKey, "Cylindered:movingTool")
	schema:register(XMLValueType.NODE_INDEX, toolKey .. "#node", "Node")
	schema:register(XMLValueType.BOOL, toolKey .. "#isEasyControlTarget", "Is easy control target", false)
	schema:register(XMLValueType.ANGLE, toolKey .. ".rotation#rotSpeed", "Rotation speed")
	schema:register(XMLValueType.ANGLE, toolKey .. ".rotation#rotAcceleration", "Rotation acceleration")
	schema:register(XMLValueType.INT, toolKey .. ".rotation#rotationAxis", "Rotation axis", 1)
	schema:register(XMLValueType.ANGLE, toolKey .. ".rotation#rotMax", "Max. rotation")
	schema:register(XMLValueType.ANGLE, toolKey .. ".rotation#rotMin", "Min. rotation")
	schema:register(XMLValueType.ANGLE, toolKey .. ".rotation#startRot", "Start rotation")
	schema:register(XMLValueType.BOOL, toolKey .. ".rotation#syncMaxRotLimits", "Synchronize max. rotation limits", false)
	schema:register(XMLValueType.BOOL, toolKey .. ".rotation#syncMinRotLimits", "Synchronize min. rotation limits", false)
	schema:register(XMLValueType.INT, toolKey .. ".rotation#rotSendNumBits", "Number of bits to synchronize", "automatically calculated by rotation range")
	schema:register(XMLValueType.ANGLE, toolKey .. ".rotation#attachRotMax", "Max. rotation value set during attach")
	schema:register(XMLValueType.ANGLE, toolKey .. ".rotation#attachRotMin", "Min. rotation value set during attach")
	schema:register(XMLValueType.ANGLE, toolKey .. ".rotation#detachingRotMaxLimit", "Max. rotation to detach vehicle")
	schema:register(XMLValueType.ANGLE, toolKey .. ".rotation#detachingRotMinLimit", "Min. rotation to detach vehicle")
	schema:register(XMLValueType.FLOAT, toolKey .. ".translation#transSpeed", "Translation speed")
	schema:register(XMLValueType.FLOAT, toolKey .. ".translation#transAcceleration", "Translation acceleration")
	schema:register(XMLValueType.INT, toolKey .. ".translation#translationAxis", "Translation axis")
	schema:register(XMLValueType.FLOAT, toolKey .. ".translation#transMax", "Max. translation")
	schema:register(XMLValueType.FLOAT, toolKey .. ".translation#transMin", "Min. translation")
	schema:register(XMLValueType.FLOAT, toolKey .. ".translation#startTrans", "Start translation")
	schema:register(XMLValueType.FLOAT, toolKey .. ".translation#attachTransMax", "Max. translation value set during attach")
	schema:register(XMLValueType.FLOAT, toolKey .. ".translation#attachTransMin", "Min. translation value set during attach")
	schema:register(XMLValueType.FLOAT, toolKey .. ".translation#detachingTransMaxLimit", "Max. translation to detach vehicle")
	schema:register(XMLValueType.FLOAT, toolKey .. ".translation#detachingTransMinLimit", "Min. translation to detach vehicle")
	schema:register(XMLValueType.STRING, toolKey .. "#requiredConfigurationName", "Name of configuration that is required to use this moving tool")
	schema:register(XMLValueType.VECTOR_N, toolKey .. "#requiredConfigurationIndices", "List of configuration indices that are required to use this moving tool")
	schema:register(XMLValueType.BOOL, toolKey .. "#playSound", "Play sound", false)
	schema:register(XMLValueType.STRING, toolKey .. ".animation#animName", "Animation name")
	schema:register(XMLValueType.FLOAT, toolKey .. ".animation#animSpeed", "Animation speed")
	schema:register(XMLValueType.FLOAT, toolKey .. ".animation#animAcceleration", "Animation acceleration")
	schema:register(XMLValueType.INT, toolKey .. ".animation#animSendNumBits", "Number of bits to synchronize", 8)
	schema:register(XMLValueType.FLOAT, toolKey .. ".animation#animMaxTime", "Animation max. time", 1)
	schema:register(XMLValueType.FLOAT, toolKey .. ".animation#animMinTime", "Animation min. time", 0)
	schema:register(XMLValueType.FLOAT, toolKey .. ".animation#animStartTime", "Animation start time")
	schema:register(XMLValueType.STRING, toolKey .. ".controls#iconName", "Icon identifier")
	schema:registerAutoCompletionDataSource(toolKey .. ".controls#iconName", "$dataS/axisIcons.xml", "axisIcons.icon#name")
	schema:register(XMLValueType.INT, toolKey .. ".controls#groupIndex", "Control group index", 0)
	schema:register(XMLValueType.STRING, toolKey .. ".controls#axis", "Input action name")
	schema:register(XMLValueType.BOOL, toolKey .. ".controls#invertAxis", "Invert input axis", false)
	schema:register(XMLValueType.FLOAT, toolKey .. ".controls#mouseSpeedFactor", "Mouse speed factor", 1)
	schema:register(XMLValueType.BOOL, toolKey .. "#allowSaving", "Allow saving", true)
	schema:register(XMLValueType.FLOAT, toolKey .. "#aiActivePosition", "Position of the moving tool (trans, rot, anim) while the AI is active [0-1]. Position will then be enforced when the AI starts to work.")
	schema:register(XMLValueType.BOOL, toolKey .. "#isIntitialDirty", "Is initial dirty", true)
	schema:register(XMLValueType.NODE_INDEX, toolKey .. "#delayedNode", "Delayed node")
	schema:register(XMLValueType.INT, toolKey .. "#delayedFrames", "Delayed frames", 3)
	schema:register(XMLValueType.BOOL, toolKey .. "#isConsumingPower", "While tool is moving the power consumer is set active", false)
	schema:register(XMLValueType.NODE_INDEX, toolKey .. ".dependentPart(?)#node", "Dependent part")
	schema:register(XMLValueType.STRING, toolKey .. ".dependentPart(?)#maxUpdateDistance", "Max. distance to vehicle root to update dependent part (\'-\' means unlimited)", "-")
	schema:register(XMLValueType.VECTOR_N, toolKey .. "#wheelIndices", "List of wheel indices to update")
	schema:register(XMLValueType.STRING, toolKey .. "#wheelNodes", "List of wheel nodes to update")
	schema:register(XMLValueType.BOOL, toolKey .. ".inputAttacherJoint#value", "Update input attacher joint")
	schema:register(XMLValueType.VECTOR_N, toolKey .. ".attacherJoint#jointIndices", "List of attacher joints to update")
	schema:register(XMLValueType.BOOL, toolKey .. ".attacherJoint#ignoreWarning", "No warning is printed if the joint index is not available (due to configurations)", false)
	schema:register(XMLValueType.INT, toolKey .. "#fillUnitIndex", "Fill unit index")
	schema:register(XMLValueType.FLOAT, toolKey .. "#minFillLevel", "Min. fill level")
	schema:register(XMLValueType.FLOAT, toolKey .. "#maxFillLevel", "Max. fill level")
	schema:register(XMLValueType.FLOAT, toolKey .. "#foldMinLimit", "Min. fold time", 0)
	schema:register(XMLValueType.FLOAT, toolKey .. "#foldMaxLimit", "Max. fold time", 1)
	Cylindered.registerDependentComponentJointXMLPaths(schema, toolKey)
	Cylindered.registerDependentAnimationXMLPaths(schema, toolKey)
	Cylindered.registerDependentMovingToolXMLPaths(schema, toolKey)
end

function Cylindered.registerMovingPartXMLPaths(schema, partKey)
	schema:addDelayedRegistrationPath(partKey, "Cylindered:movingPart")
	schema:register(XMLValueType.NODE_INDEX, partKey .. "#node", "Node")
	schema:register(XMLValueType.NODE_INDEX, partKey .. "#referenceFrame", "Reference frame")
	schema:register(XMLValueType.NODE_INDEX, partKey .. "#referencePoint", "Reference point")
	schema:register(XMLValueType.NODE_INDICES, partKey .. "#referencePoints", "List of reference points (average position will be used as reference)")
	schema:register(XMLValueType.BOOL, partKey .. "#invertZ", "Invert Z axis", false)
	schema:register(XMLValueType.BOOL, partKey .. "#scaleZ", "Allow Z axis scaling", false)
	schema:register(XMLValueType.INT, partKey .. "#limitedAxis", "Limited axis")
	schema:register(XMLValueType.BOOL, partKey .. "#isActiveDirty", "Part is permanently updated", false)
	schema:register(XMLValueType.BOOL, partKey .. "#playSound", "Play hydraulic sound", false)
	schema:register(XMLValueType.BOOL, partKey .. "#moveToReferenceFrame", "Move to reference frame", false)
	schema:register(XMLValueType.BOOL, partKey .. "#doLineAlignment", "Do line alignment (line as ref point)", false)
	schema:register(XMLValueType.BOOL, partKey .. "#doInversedLineAlignment", "Do inversed line alignment (line inside part and fixed ref point)", false)
	schema:register(XMLValueType.BOOL, partKey .. "#do3DLineAlignment", "Do 3D line alignment (X and Y rotation is aligned to the given line - line is only allowed to have two points!)", false)
	schema:register(XMLValueType.FLOAT, partKey .. ".orientationLine#partLength", "Part length (Distance from part to line)", 0.5)
	schema:register(XMLValueType.NODE_INDEX, partKey .. ".orientationLine#referenceTransNode", "Node that is moved to the current line position and at the same time is used a referencePoint for the directional alignment of the movingPart")
	schema:register(XMLValueType.NODE_INDEX, partKey .. ".orientationLine#partLengthNode", "Node to measure the part length dynamically")
	schema:register(XMLValueType.NODE_INDEX, partKey .. ".orientationLine.lineNode(?)#node", "Line node")
	schema:register(XMLValueType.BOOL, partKey .. "#doDirectionAlignment", "Do direction alignment", true)
	schema:register(XMLValueType.BOOL, partKey .. "#doRotationAlignment", "Do rotation alignment", false)
	schema:register(XMLValueType.FLOAT, partKey .. "#rotMultiplier", "Rotation multiplier for rotation alignment", 0)
	schema:register(XMLValueType.ANGLE, partKey .. "#minRot", "Min. rotation for limited axis")
	schema:register(XMLValueType.ANGLE, partKey .. "#maxRot", "Max. rotation for limited axis")
	schema:register(XMLValueType.BOOL, partKey .. "#alignToWorldY", "Align part to world Y axis", false)
	schema:register(XMLValueType.NODE_INDEX, partKey .. "#localReferencePoint", "Local reference point")
	schema:register(XMLValueType.NODE_INDEX, partKey .. "#referenceDistancePoint", "Z translation will be used as reference distance")
	schema:register(XMLValueType.FLOAT, partKey .. "#referenceDistance", "Reference distance to be used instead of the current distance in the i3d (distance between node and ref point - or local ref point and ref point)")
	schema:register(XMLValueType.FLOAT, partKey .. "#localReferenceDistance", "Predefined reference distance", "calculated automatically")
	schema:register(XMLValueType.BOOL, partKey .. "#updateLocalReferenceDistance", "Update distance to local reference point", false)
	schema:register(XMLValueType.BOOL, partKey .. "#dynamicLocalReferenceDistance", "Local reference distance will be calculated based on the initial distance and the localReferencePoint direction", false)
	schema:register(XMLValueType.BOOL, partKey .. "#localReferenceTranslate", "Translate to local reference node", false)
	schema:register(XMLValueType.FLOAT, partKey .. "#referenceDistanceThreshold", "Distance threshold to update moving part while isActiveDirty", 0.0001)
	schema:register(XMLValueType.BOOL, partKey .. "#useLocalOffset", "Use local offset", false)
	schema:register(XMLValueType.FLOAT, partKey .. "#referencePointOffset", "Offset to the reference point in Y alignment")
	schema:register(XMLValueType.FLOAT, partKey .. "#directionThreshold", "Direction threshold to update part if vehicle is inactive", 0.0001)
	schema:register(XMLValueType.FLOAT, partKey .. "#directionThresholdActive", "Direction threshold to update part if vehicle is inactive", 0.0001)
	schema:register(XMLValueType.STRING, partKey .. "#maxUpdateDistance", "Max. distance to vehicle root while isActiveDirty is set (\'-\' means unlimited)")
	schema:register(XMLValueType.BOOL, partKey .. "#smoothedDirectionScale", "If moving part is deactivated e.g. due to folding limits the direction is slowly interpolated back to the start direction depending on #smoothedDirectionTime", false)
	schema:register(XMLValueType.TIME, partKey .. "#smoothedDirectionTime", "Defines how low it takes until the part is back in original direction (sec.)", 2)
	schema:register(XMLValueType.BOOL, partKey .. "#debug", "Enables debug rendering for this part", false)
	schema:register(XMLValueType.NODE_INDEX, partKey .. ".dependentPart(?)#node", "Dependent part")
	schema:register(XMLValueType.STRING, partKey .. ".dependentPart(?)#maxUpdateDistance", "Max. distance to vehicle root to update dependent part (\'-\' means unlimited)", "-")
	schema:register(XMLValueType.BOOL, partKey .. "#divideTranslatingDistance", "If true all translating parts will move at the same time. If false they start to move in the order from the xml", true)
	schema:register(XMLValueType.NODE_INDEX, partKey .. ".translatingPart(?)#node", "Translating part")
	schema:register(XMLValueType.FLOAT, partKey .. ".translatingPart(?)#referenceDistance", "Reference distance")
	schema:register(XMLValueType.FLOAT, partKey .. ".translatingPart(?)#minZTrans", "Min. Z Translation")
	schema:register(XMLValueType.FLOAT, partKey .. ".translatingPart(?)#maxZTrans", "Max. Z Translation")
	schema:register(XMLValueType.BOOL, partKey .. ".translatingPart(?)#divideTranslatingDistance", "Define individual division per translating part. E.g. one part is extending without division and two other parts extend afterwards at the same speed.", "movingPart#divideTranslatingDistance")
	schema:register(XMLValueType.VECTOR_N, partKey .. "#wheelIndices", "List of wheel indices to update")
	schema:register(XMLValueType.STRING, partKey .. "#wheelNodes", "List of wheel nodes to update")
	schema:register(XMLValueType.BOOL, partKey .. ".inputAttacherJoint#value", "Update input attacher joint")
	schema:register(XMLValueType.VECTOR_N, partKey .. ".attacherJoint#jointIndices", "List of attacher joints to update")
	schema:register(XMLValueType.BOOL, partKey .. ".attacherJoint#ignoreWarning", "No warning is printed if the joint index is not available (due to configurations)", false)
	Cylindered.registerDependentComponentJointXMLPaths(schema, partKey)
	Cylindered.registerCopyLocalDirectionXMLPaths(schema, partKey)
	Cylindered.registerDependentAnimationXMLPaths(schema, partKey)
	Cylindered.registerDependentMovingToolXMLPaths(schema, partKey)
end

function Cylindered.registerDependentComponentJointXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. ".componentJoint(?)#index", "Dependent component joint index")
	schema:register(XMLValueType.BOOL, basePath .. ".componentJoint(?)#ignoreWarning", "Ignore if the index could not be found (due to configurations for example)", false)
	schema:register(XMLValueType.INT, basePath .. ".componentJoint(?)#anchorActor", "Dependent component anchor actor")
end

function Cylindered.registerCopyLocalDirectionXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".copyLocalDirectionPart(?)#node", "Copy local direction part")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".copyLocalDirectionPart(?)#dirScale", "Direction scale")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".copyLocalDirectionPart(?)#upScale", "Up vector scale")
	Cylindered.registerDependentComponentJointXMLPaths(schema, basePath .. ".copyLocalDirectionPart(?)")
end

function Cylindered.registerDependentAnimationXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".dependentAnimation(?)#name", "Dependent animation name")
	schema:register(XMLValueType.INT, basePath .. ".dependentAnimation(?)#translationAxis", "Translation axis")
	schema:register(XMLValueType.INT, basePath .. ".dependentAnimation(?)#rotationAxis", "Rotation axis")
	schema:register(XMLValueType.INT, basePath .. ".dependentAnimation(?)#useTranslatingPartIndex", "Use translation part index")
	schema:register(XMLValueType.FLOAT, basePath .. ".dependentAnimation(?)#minValue", "Min. reference value")
	schema:register(XMLValueType.FLOAT, basePath .. ".dependentAnimation(?)#maxValue", "Max. reference value")
	schema:register(XMLValueType.BOOL, basePath .. ".dependentAnimation(?)#invert", "Invert reference value", false)
end

function Cylindered.registerDependentMovingToolXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".dependentMovingTool(?)#node", "Dependent part")
	schema:register(XMLValueType.INT, basePath .. ".dependentMovingTool(?)#axis", "Rotation axis of the moving part which is used as reference in the rotationBasedLimits", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".dependentMovingTool(?)#speedScale", "Speed scale")
	schema:register(XMLValueType.BOOL, basePath .. ".dependentMovingTool(?)#requiresMovement", "Requires movement", false)
	schema:register(XMLValueType.ANGLE, basePath .. ".dependentMovingTool(?).rotationBasedLimits.limit(?)#rotation", "Rotation")
	schema:register(XMLValueType.ANGLE, basePath .. ".dependentMovingTool(?).rotationBasedLimits.limit(?)#rotMin", "Min. rotation")
	schema:register(XMLValueType.ANGLE, basePath .. ".dependentMovingTool(?).rotationBasedLimits.limit(?)#rotMax", "Max. rotation")
	schema:register(XMLValueType.FLOAT, basePath .. ".dependentMovingTool(?).rotationBasedLimits.limit(?)#transMin", "Min. translation")
	schema:register(XMLValueType.FLOAT, basePath .. ".dependentMovingTool(?).rotationBasedLimits.limit(?)#transMax", "Max. translation")
	schema:register(XMLValueType.VECTOR_2, basePath .. ".dependentMovingTool(?)#minTransLimits", "Min. translation limits")
	schema:register(XMLValueType.VECTOR_2, basePath .. ".dependentMovingTool(?)#maxTransLimits", "Max. translation limits")
	schema:register(XMLValueType.VECTOR_ROT_2, basePath .. ".dependentMovingTool(?)#minRotLimits", "Min. rotation limits")
	schema:register(XMLValueType.VECTOR_ROT_2, basePath .. ".dependentMovingTool(?)#maxRotLimits", "Max. rotation limits")
end

function Cylindered.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onMovingToolChanged")
end

function Cylindered.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadMovingPartsFromXML", Cylindered.loadMovingPartsFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadMovingPartFromXML", Cylindered.loadMovingPartFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadMovingToolsFromXML", Cylindered.loadMovingToolsFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadMovingToolFromXML", Cylindered.loadMovingToolFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadDependentMovingTools", Cylindered.loadDependentMovingTools)
	SpecializationUtil.registerFunction(vehicleType, "loadEasyArmControlFromXML", Cylindered.loadEasyArmControlFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadDependentParts", Cylindered.loadDependentParts)
	SpecializationUtil.registerFunction(vehicleType, "resolveDependentPartData", Cylindered.resolveDependentPartData)
	SpecializationUtil.registerFunction(vehicleType, "loadDependentComponentJoints", Cylindered.loadDependentComponentJoints)
	SpecializationUtil.registerFunction(vehicleType, "loadDependentAttacherJoints", Cylindered.loadDependentAttacherJoints)
	SpecializationUtil.registerFunction(vehicleType, "loadDependentWheels", Cylindered.loadDependentWheels)
	SpecializationUtil.registerFunction(vehicleType, "loadDependentTranslatingParts", Cylindered.loadDependentTranslatingParts)
	SpecializationUtil.registerFunction(vehicleType, "loadExtraDependentParts", Cylindered.loadExtraDependentParts)
	SpecializationUtil.registerFunction(vehicleType, "loadDependentAnimations", Cylindered.loadDependentAnimations)
	SpecializationUtil.registerFunction(vehicleType, "loadCopyLocalDirectionParts", Cylindered.loadCopyLocalDirectionParts)
	SpecializationUtil.registerFunction(vehicleType, "loadRotationBasedLimits", Cylindered.loadRotationBasedLimits)
	SpecializationUtil.registerFunction(vehicleType, "loadActionSoundsFromXML", Cylindered.loadActionSoundsFromXML)
	SpecializationUtil.registerFunction(vehicleType, "checkMovingPartDirtyUpdateNode", Cylindered.checkMovingPartDirtyUpdateNode)
	SpecializationUtil.registerFunction(vehicleType, "updateDirtyMovingParts", Cylindered.updateDirtyMovingParts)
	SpecializationUtil.registerFunction(vehicleType, "setMovingToolDirty", Cylindered.setMovingToolDirty)
	SpecializationUtil.registerFunction(vehicleType, "setMovingPartReferenceNode", Cylindered.setMovingPartReferenceNode)
	SpecializationUtil.registerFunction(vehicleType, "updateMovingPartByNode", Cylindered.updateMovingPartByNode)
	SpecializationUtil.registerFunction(vehicleType, "updateCylinderedInitial", Cylindered.updateCylinderedInitial)
	SpecializationUtil.registerFunction(vehicleType, "allowLoadMovingToolStates", Cylindered.allowLoadMovingToolStates)
	SpecializationUtil.registerFunction(vehicleType, "getMovingToolByNode", Cylindered.getMovingToolByNode)
	SpecializationUtil.registerFunction(vehicleType, "getMovingPartByNode", Cylindered.getMovingPartByNode)
	SpecializationUtil.registerFunction(vehicleType, "getTranslatingPartByNode", Cylindered.getTranslatingPartByNode)
	SpecializationUtil.registerFunction(vehicleType, "getIsMovingToolActive", Cylindered.getIsMovingToolActive)
	SpecializationUtil.registerFunction(vehicleType, "getIsMovingPartActive", Cylindered.getIsMovingPartActive)
	SpecializationUtil.registerFunction(vehicleType, "getMovingToolMoveValue", Cylindered.getMovingToolMoveValue)
	SpecializationUtil.registerFunction(vehicleType, "setDelayedData", Cylindered.setDelayedData)
	SpecializationUtil.registerFunction(vehicleType, "updateDelayedTool", Cylindered.updateDelayedTool)
	SpecializationUtil.registerFunction(vehicleType, "updateEasyControl", Cylindered.updateEasyControl)
	SpecializationUtil.registerFunction(vehicleType, "setIsEasyControlActive", Cylindered.setIsEasyControlActive)
	SpecializationUtil.registerFunction(vehicleType, "setEasyControlForcedTransMove", Cylindered.setEasyControlForcedTransMove)
	SpecializationUtil.registerFunction(vehicleType, "updateExtraDependentParts", Cylindered.updateExtraDependentParts)
	SpecializationUtil.registerFunction(vehicleType, "updateDependentAnimations", Cylindered.updateDependentAnimations)
	SpecializationUtil.registerFunction(vehicleType, "updateDependentToolLimits", Cylindered.updateDependentToolLimits)
	SpecializationUtil.registerFunction(vehicleType, "onMovingPartSoundEvent", Cylindered.onMovingPartSoundEvent)
	SpecializationUtil.registerFunction(vehicleType, "updateMovingToolSoundEvents", Cylindered.updateMovingToolSoundEvents)
	SpecializationUtil.registerFunction(vehicleType, "updateControlGroups", Cylindered.updateControlGroups)
end

function Cylindered.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "isDetachAllowed", Cylindered.isDetachAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadObjectChangeValuesFromXML", Cylindered.loadObjectChangeValuesFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setObjectChangeValues", Cylindered.setObjectChangeValues)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDischargeNode", Cylindered.loadDischargeNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDischargeNodeEmptyFactor", Cylindered.getDischargeNodeEmptyFactor)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadShovelNode", Cylindered.loadShovelNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getShovelNodeIsActive", Cylindered.getShovelNodeIsActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDynamicMountGrabFromXML", Cylindered.loadDynamicMountGrabFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDynamicMountGrabOpened", Cylindered.getIsDynamicMountGrabOpened)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setComponentJointFrame", Cylindered.setComponentJointFrame)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAdditionalSchemaText", Cylindered.getAdditionalSchemaText)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Cylindered.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoConsumePtoPower", Cylindered.getDoConsumePtoPower)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConsumingLoad", Cylindered.getConsumingLoad)
end

function Cylindered.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateEnd", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onPostUpdate", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onPostUpdateTick", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onSelect", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onUnselect", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onAnimationPartChanged", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onAIImplementStart", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onVehicleSettingChanged", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterAnimationValueTypes", Cylindered)
end

-- Local values: spec, configurationId, configKey, collectDependentParts, subCollisionErrorFunction, j, movingPart, j, part, _, part, addMovingPart, newParts, _, part, _, toolKey, _, groupKey, name, sort, _, groupIndex, subSelectionIndex, _, part, j, dependentTool, tool, _, part, j, dependentTool, tool, easyArmControlKey, easyArmControl, movingTool
function Cylindered:onLoad(savegame)
	local v_u_34_ = self.spec_cylindered
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.movingParts", "vehicle.cylindered.movingParts")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.movingTools", "vehicle.cylindered.movingTools")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cylinderedHydraulicSound", "vehicle.cylindered.sounds.hydraulic")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cylindered.movingParts#isActiveDirtyTimeOffset")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cylindered.movingParts.sounds", "vehicle.cylindered.sounds")
	local v35_ = self.configurations.cylindered or 1
	local v36_ = string.format("vehicle.cylindered.cylinderedConfigurations.cylinderedConfiguration(%d)", v35_ - 1)
	v_u_34_.activeDirtyMovingParts = {}
	v_u_34_.referenceNodes = {}
	v_u_34_.nodesToMovingParts = {}
	v_u_34_.movingParts = {}
	self.anyMovingPartsDirty = false
	v_u_34_.detachLockNodes = nil
	self:loadMovingPartsFromXML(self.xmlFile, "vehicle.cylindered.movingParts.movingPart")
	self:loadMovingPartsFromXML(self.xmlFile, v36_ .. ".movingParts.movingPart")
	if Cylindered.DIRTY_COLLISION_UPDATE_CHECK then
		local function v_u_41_(p37_, p38_)
			-- upvalues: (copy) v_u_34_, (copy) v_u_41_
			table.insert(p38_, p37_)
			if p37_.dependentPartNodes ~= nil then
				for v39_ = 1, #p37_.dependentPartNodes do
					local v40_ = v_u_34_.nodesToMovingParts[p37_.dependentPartNodes[v39_]]
					if v40_ ~= nil then
						table.insert(p38_, v40_)
						v_u_41_(v40_, p38_)
					end
				end
			end
		end
		v_u_34_.realActiveDirtyParts = {}
		local function v45_(p42_, p43_, p44_)
			if getHasClassId(p42_, ClassIds.SHAPE) then
				Logging.xmlError(p43_, "Found collision \'%s\' as child of isActiveDirty movingPart \'%s\'. This can cause the vehicle to never sleep!", getName(p42_), p44_)
			end
		end
		for v46_ = 1, #v_u_34_.movingParts do
			local v47_ = v_u_34_.movingParts[v46_]
			if v47_.isActiveDirty and v47_.directionThreshold == 0.0001 then
				v_u_41_(v47_, v_u_34_.realActiveDirtyParts)
			end
		end
		for v48_ = 1, #v_u_34_.realActiveDirtyParts do
			local v49_ = v_u_34_.realActiveDirtyParts[v48_]
			I3DUtil.checkForChildCollisions(v49_.node, v45_, self.xmlFile, getName(v49_.node))
		end
	end
	v_u_34_.powerConsumingActiveTimeOffset = self.xmlFile:getValue("vehicle.cylindered.movingTools#powerConsumingActiveTimeOffset", 5)
	v_u_34_.powerConsumingTimer = -1
	for _, v50_ in pairs(v_u_34_.movingParts) do
		self:resolveDependentPartData(v50_.dependentPartData, v_u_34_.referenceNodes)
	end
	local function v_u_56_(p51_, p52_, p53_)
		-- upvalues: (copy) v_u_56_
		for _, v54_ in ipairs(p52_) do
			if v54_ == p51_ then
				return
			end
		end
		if p51_.isDependentPart ~= true or p53_ == true then
			table.insert(p52_, p51_)
			for _, v55_ in pairs(p51_.dependentPartData) do
				v_u_56_(v55_.part, p52_, true)
			end
		end
	end
	local v57_ = {}
	for _, v58_ in ipairs(v_u_34_.movingParts) do
		v_u_56_(v58_, v57_)
	end
	v_u_34_.movingParts = v57_
	v_u_34_.controlGroups = {}
	v_u_34_.controlGroupMapping = {}
	v_u_34_.currentControlGroupIndex = 1
	v_u_34_.controlGroupNames = {}
	for _, v59_ in ipairs(Cylindered.MOVING_TOOLS_XML_KEYS) do
		for _, v60_ in self.xmlFile:iterator(v59_ .. ".controlGroups.controlGroup") do
			local v61_ = self.xmlFile:getValue(v60_ .. "#name", "", self.customEnvironment, false)
			if v61_ ~= nil then
				local v62_ = v_u_34_.controlGroupNames
				table.insert(v62_, v61_)
			end
		end
	end
	v_u_34_.nodesToMovingTools = {}
	v_u_34_.movingTools = {}
	self:loadMovingToolsFromXML(self.xmlFile, "vehicle.cylindered.movingTools.movingTool")
	self:loadMovingToolsFromXML(self.xmlFile, v36_ .. ".movingTools.movingTool")
	table.sort(v_u_34_.controlGroups, function(p63_, p64_)
		return p63_ < p64_
	end)
	for _, v65_ in ipairs(v_u_34_.controlGroups) do
		local v66_ = self:addSubselection(v65_)
		v_u_34_.controlGroupMapping[v66_] = v65_
	end
	for _, v67_ in pairs(v_u_34_.movingTools) do
		self:resolveDependentPartData(v67_.dependentPartData, v_u_34_.referenceNodes)
		for v68_ = #v67_.dependentMovingTools, 1, -1 do
			local v69_ = v67_.dependentMovingTools[v68_]
			local v70_ = v_u_34_.nodesToMovingTools[v69_.node]
			if v70_ == nil then
				Logging.xmlWarning(self.xmlFile, "Dependent moving tool \'%s\' not defined. Ignoring it!", getName(v69_.node))
				table.remove(v67_.dependentMovingTools, v68_)
			else
				v69_.movingTool = v70_
			end
		end
	end
	for _, v71_ in pairs(v_u_34_.movingParts) do
		for v72_ = #v71_.dependentMovingTools, 1, -1 do
			local v73_ = v71_.dependentMovingTools[v72_]
			local v74_ = v_u_34_.nodesToMovingTools[v73_.node]
			if v74_ == nil then
				Logging.xmlWarning(self.xmlFile, "Dependent moving tool \'%s\' not defined. Ignoring it!", getName(v73_.node))
				table.remove(v71_.dependentMovingTools, v72_)
			else
				v73_.movingTool = v74_
			end
		end
	end
	v_u_34_.referenceNodes = nil
	local v75_ = v36_ .. ".movingTools.easyArmControl"
	local v76_ = not self.xmlFile:hasProperty(v75_) and "vehicle.cylindered.movingTools.easyArmControl" or v75_
	if self.xmlFile:hasProperty(v76_) then
		local v77_ = {}
		if self:loadEasyArmControlFromXML(self.xmlFile, v76_, v77_) then
			v_u_34_.easyArmControl = v77_
		end
	end
	if self.xmlFile:hasProperty(v36_) then
		local v78_ = DashboardValueType.new("cylindered", "movingTool")
		v78_:setXMLKey(v36_ .. ".dashboards")
		v78_:setValue(self, Cylindered.getMovingToolDashboardState)
		v78_:setRange(0, 1)
		v78_:setAdditionalFunctions(Cylindered.movingToolDashboardAttributes, nil)
		v78_:setIdleValue(0.5)
		self:registerDashboardValueType(v78_)
	end
	v_u_34_.samples = {}
	v_u_34_.actionSamples = {}
	if self.isClient then
		v_u_34_.samples.hydraulic = g_soundManager:loadSampleFromXML(self.xmlFile, v36_ .. ".sounds", "hydraulic", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		if v_u_34_.samples.hydraulic == nil then
			v_u_34_.samples.hydraulic = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.cylindered.sounds", "hydraulic", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		end
		v_u_34_.isHydraulicSamplePlaying = false
		v_u_34_.nodesToSamples = {}
		v_u_34_.activeSamples = {}
		v_u_34_.endingSamples = {}
		v_u_34_.endingSamplesBySample = {}
		v_u_34_.startingSamples = {}
		v_u_34_.startingSamplesBySample = {}
		self:loadActionSoundsFromXML(self.xmlFile, "vehicle.cylindered.sounds")
		self:loadActionSoundsFromXML(self.xmlFile, v36_ .. ".sounds")
	end
	v_u_34_.cylinderedDirtyFlag = self:getNextDirtyFlag()
	v_u_34_.cylinderedInputDirtyFlag = self:getNextDirtyFlag()
	self:registerVehicleSetting(GameSettings.SETTING.EASY_ARM_CONTROL, true)
	v_u_34_.isLoading = true
end

-- Local values: spec, _, tool, _, part, _, tool, i, _, tool, toolKey, changed, newTrans, newRot, animTime, _, dependentTool, hasTools, hasParts, checkPart, j, movingPart
function Cylindered:onPostLoad(savegame)
	local v81_ = self.spec_cylindered
	for _, v82_ in pairs(v81_.movingTools) do
		if self:getIsMovingToolActive(v82_) then
			if v82_.startRot ~= nil then
				v82_.curRot[v82_.rotationAxis] = v82_.startRot
				local v83_ = setRotation
				local v84_ = v82_.node
				local v85_ = v82_.curRot
				v83_(v84_, unpack(v85_))
				SpecializationUtil.raiseEvent(self, "onMovingToolChanged", v82_, 0, 0)
			end
			if v82_.startTrans ~= nil then
				v82_.curTrans[v82_.translationAxis] = v82_.startTrans
				local v86_ = setTranslation
				local v87_ = v82_.node
				local v88_ = v82_.curTrans
				v86_(v87_, unpack(v88_))
				SpecializationUtil.raiseEvent(self, "onMovingToolChanged", v82_, 0, 0)
			end
			if v82_.animStartTime ~= nil then
				self:setAnimationTime(v82_.animName, v82_.animStartTime, nil, false)
				SpecializationUtil.raiseEvent(self, "onMovingToolChanged", v82_, 0, 0)
			end
			if v82_.delayedNode ~= nil then
				self:setDelayedData(v82_, true)
			end
			if v82_.isIntitialDirty then
				Cylindered.setDirty(self, v82_)
			end
		end
	end
	for _, v89_ in pairs(v81_.movingParts) do
		self:loadDependentAttacherJoints(self.xmlFile, v89_.key, v89_)
		self:loadDependentWheels(self.xmlFile, v89_.key, v89_)
	end
	for _, v90_ in pairs(v81_.movingTools) do
		self:loadDependentAttacherJoints(self.xmlFile, v90_.key, v90_)
		self:loadDependentWheels(self.xmlFile, v90_.key, v90_)
	end
	if self:allowLoadMovingToolStates() and (savegame ~= nil and not savegame.resetVehicles) then
		local v91_ = 0
		for _, v92_ in ipairs(v81_.movingTools) do
			if v92_.saving then
				if self:getIsMovingToolActive(v92_) then
					local v93_ = string.format("%s.cylindered.movingTool(%d)", savegame.key, v91_)
					local v94_ = false
					if v92_.transSpeed ~= nil then
						local v95_ = savegame.xmlFile:getValue(v93_ .. "#translation")
						if v95_ ~= nil then
							if v92_.transMax ~= nil then
								local v96_ = v92_.transMax
								v95_ = math.min(v95_, v96_)
							end
							if v92_.transMin ~= nil then
								local v97_ = v92_.transMin
								v95_ = math.max(v95_, v97_)
							end
						end
						if v95_ ~= nil then
							local v98_ = v95_ - v92_.curTrans[v92_.translationAxis]
							if math.abs(v98_) > 0.0001 then
								v92_.curTrans = { getTranslation(v92_.node) }
								v92_.curTrans[v92_.translationAxis] = v95_
								local v99_ = setTranslation
								local v100_ = v92_.node
								local v101_ = v92_.curTrans
								v99_(v100_, unpack(v101_))
								v94_ = true
							end
						end
					end
					if v92_.rotSpeed ~= nil then
						local v102_ = savegame.xmlFile:getValue(v93_ .. "#rotation")
						if v102_ ~= nil then
							if v92_.rotMax ~= nil then
								local v103_ = v92_.rotMax
								v102_ = math.min(v102_, v103_)
							end
							if v92_.rotMin ~= nil then
								local v104_ = v92_.rotMin
								v102_ = math.max(v102_, v104_)
							end
						end
						if v102_ ~= nil then
							local v105_ = v102_ - v92_.curRot[v92_.rotationAxis]
							if math.abs(v105_) > 0.0001 then
								v92_.curRot = { getRotation(v92_.node) }
								v92_.curRot[v92_.rotationAxis] = v102_
								local v106_ = setRotation
								local v107_ = v92_.node
								local v108_ = v92_.curRot
								v106_(v107_, unpack(v108_))
								v94_ = true
							end
						end
					end
					if v92_.animSpeed ~= nil then
						local v109_ = savegame.xmlFile:getValue(v93_ .. "#animationTime")
						if v109_ ~= nil then
							if v92_.animMinTime ~= nil then
								local v110_ = v92_.animMinTime
								v109_ = math.max(v109_, v110_)
							end
							if v92_.animMaxTime ~= nil then
								local v111_ = v92_.animMaxTime
								v109_ = math.min(v109_, v111_)
							end
							v92_.curAnimTime = v109_
							self:setAnimationTime(v92_.animName, v109_, true, false)
						end
					end
					if v94_ then
						Cylindered.setDirty(self, v92_)
						SpecializationUtil.raiseEvent(self, "onMovingToolChanged", v92_, 0, 0)
					end
					if v92_.delayedNode ~= nil then
						self:setDelayedData(v92_, true)
					end
				end
				v91_ = v91_ + 1
			end
			for _, v112_ in pairs(v92_.dependentMovingTools) do
				Cylindered.updateRotationBasedLimits(self, v92_, v112_)
			end
		end
	end
	self:updateEasyControl(9999, true)
	self:updateCylinderedInitial(false)
	local v113_ = #v81_.movingTools > 0
	local v114_ = #v81_.movingParts > 0
	if not v113_ then
		SpecializationUtil.removeEventListener(self, "onReadStream", Cylindered)
		SpecializationUtil.removeEventListener(self, "onWriteStream", Cylindered)
		SpecializationUtil.removeEventListener(self, "onReadUpdateStream", Cylindered)
		SpecializationUtil.removeEventListener(self, "onWriteUpdateStream", Cylindered)
		SpecializationUtil.removeEventListener(self, "onUpdate", Cylindered)
		if not v114_ then
			SpecializationUtil.removeEventListener(self, "onUpdateTick", Cylindered)
			SpecializationUtil.removeEventListener(self, "onPostUpdate", Cylindered)
			SpecializationUtil.removeEventListener(self, "onPostUpdateTick", Cylindered)
		end
	end
	if not (self.isClient and v113_) then
		SpecializationUtil.removeEventListener(self, "onDraw", Cylindered)
		SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", Cylindered)
	end
	if g_isDevelopmentVersion then
		local function v_u_118_(p_u_115_)
			-- upvalues: (copy) self, (copy) v_u_118_
			I3DUtil.iterateRecursively(p_u_115_.node, function(p116_, _)
				-- upvalues: (ref) self, (copy) p_u_115_
				self:checkMovingPartDirtyUpdateNode(p116_, p_u_115_)
			end)
			if p_u_115_.dependentPartData ~= nil then
				for _, v117_ in pairs(p_u_115_.dependentPartData) do
					if v117_.part ~= nil then
						v_u_118_(v117_.part)
					end
				end
			end
		end
		for v119_ = 1, #v81_.movingParts do
			local v120_ = v81_.movingParts[v119_]
			if v120_.isActiveDirty and v120_.maxUpdateDistance ~= math.huge then
				v_u_118_(v120_)
			end
		end
	end
end

-- Local values: spec, i, tool
function Cylindered:onLoadFinished(savegame)
	local v122_ = self.spec_cylindered
	v122_.isLoading = false
	for v123_ = 1, #v122_.movingTools do
		local v124_ = v122_.movingTools[v123_]
		if v124_.delayedHistoryIndex ~= nil and v124_.delayedHistoryIndex > 0 then
			self:updateDelayedTool(v124_, true)
		end
	end
end

-- Local values: movingTool
function Cylindered:onRegisterDashboardValueTypes()
	local v126_ = DashboardValueType.new("cylindered", "movingTool")
	v126_:setValue(self, Cylindered.getMovingToolDashboardState)
	v126_:setRange(0, 1)
	v126_:setAdditionalFunctions(Cylindered.movingToolDashboardAttributes, nil)
	v126_:setIdleValue(0.5)
	self:registerDashboardValueType(v126_)
end

-- Local values: spec, _, movingTool
function Cylindered:onDelete()
	local v128_ = self.spec_cylindered
	g_soundManager:deleteSamples(v128_.samples)
	g_soundManager:deleteSamples(v128_.actionSamples)
	if v128_.movingTools ~= nil then
		for _, v129_ in pairs(v128_.movingTools) do
			if v129_.icon ~= nil then
				v129_.icon:delete()
				v129_.icon = nil
			end
		end
	end
end

-- Local values: spec, index, _, tool, toolKey
function Cylindered:saveToXMLFile(xmlFile, key, usedModNames)
	local v133_ = self.spec_cylindered
	local v134_ = 0
	for _, v135_ in ipairs(v133_.movingTools) do
		if v135_.saving then
			local v136_ = string.format("%s.movingTool(%d)", key, v134_)
			if v135_.transSpeed ~= nil then
				xmlFile:setValue(v136_ .. "#translation", v135_.curTrans[v135_.translationAxis])
			end
			if v135_.rotSpeed ~= nil then
				xmlFile:setValue(v136_ .. "#rotation", v135_.curRot[v135_.rotationAxis])
			end
			if v135_.animSpeed ~= nil then
				xmlFile:setValue(v136_ .. "#animationTime", v135_.curAnimTime)
			end
			v134_ = v134_ + 1
		end
	end
end

-- Local values: spec, i, tool, newTrans, newRot, newAnimTime
function Cylindered:onReadStream(streamId, connection)
	local v140_ = self.spec_cylindered
	if connection:getIsServer() and streamReadBool(streamId) then
		for v141_ = 1, #v140_.movingTools do
			local v142_ = v140_.movingTools[v141_]
			if v142_.dirtyFlag ~= nil then
				v142_.networkTimeInterpolator:reset()
				if v142_.transSpeed ~= nil then
					local v143_ = streamReadFloat32(streamId)
					v142_.curTrans[v142_.translationAxis] = v143_
					local v144_ = setTranslation
					local v145_ = v142_.node
					local v146_ = v142_.curTrans
					v144_(v145_, unpack(v146_))
					v142_.networkInterpolators.translation:setValue(v142_.curTrans[v142_.translationAxis])
				end
				if v142_.rotSpeed ~= nil then
					local v147_ = streamReadFloat32(streamId)
					v142_.curRot[v142_.rotationAxis] = v147_
					local v148_ = setRotation
					local v149_ = v142_.node
					local v150_ = v142_.curRot
					v148_(v149_, unpack(v150_))
					v142_.networkInterpolators.rotation:setAngle(v147_)
				end
				if v142_.animSpeed ~= nil then
					local v151_ = streamReadFloat32(streamId)
					v142_.curAnimTime = v151_
					self:setAnimationTime(v142_.animName, v142_.curAnimTime, nil, false)
					v142_.networkInterpolators.animation:setValue(v151_)
				end
				if v142_.delayedNode ~= nil then
					self:setDelayedData(v142_, true)
				end
				Cylindered.setDirty(self, v142_)
				SpecializationUtil.raiseEvent(self, "onMovingToolChanged", v142_, 0, 0)
			end
		end
	end
end

-- Local values: spec, i, tool
function Cylindered:onWriteStream(streamId, connection)
	local v155_ = self.spec_cylindered
	if not connection:getIsServer() and streamWriteBool(streamId, self:allowLoadMovingToolStates()) then
		for v156_ = 1, #v155_.movingTools do
			local v157_ = v155_.movingTools[v156_]
			if v157_.dirtyFlag ~= nil then
				if v157_.transSpeed ~= nil then
					streamWriteFloat32(streamId, v157_.curTrans[v157_.translationAxis])
				end
				if v157_.rotSpeed ~= nil then
					streamWriteFloat32(streamId, v157_.curRot[v157_.rotationAxis])
				end
				if v157_.animSpeed ~= nil then
					v157_.curAnimTime = self:getAnimationTime(v157_.animName)
					streamWriteFloat32(streamId, v157_.curAnimTime)
				end
			end
		end
	end
end

-- Local values: spec, _, tool, _, tool, newTrans, newRot, resetAnimInterpolation, newAnimTime
function Cylindered:onReadUpdateStream(streamId, timestamp, connection)
	local v161_ = self.spec_cylindered
	if connection:getIsServer() then
		if streamReadBool(streamId) then
			for _, v162_ in ipairs(v161_.movingTools) do
				if v162_.dirtyFlag ~= nil and streamReadBool(streamId) then
					v162_.networkTimeInterpolator:startNewPhaseNetwork()
					if v162_.transSpeed ~= nil then
						local v163_ = streamReadFloat32(streamId)
						local v164_ = v163_ - v162_.curTrans[v162_.translationAxis]
						if math.abs(v164_) > 0.0001 then
							v162_.networkInterpolators.translation:setTargetValue(v163_)
						end
					end
					if v162_.rotSpeed ~= nil then
						local v165_
						if v162_.rotMin == nil or v162_.rotMax == nil then
							v165_ = NetworkUtil.readCompressedAngle(streamId)
						else
							if v162_.syncMinRotLimits then
								v162_.rotMin = streamReadFloat32(streamId)
							end
							if v162_.syncMaxRotLimits then
								v162_.rotMax = streamReadFloat32(streamId)
							end
							v162_.networkInterpolators.rotation:setMinMax(v162_.rotMin, v162_.rotMax)
							v165_ = NetworkUtil.readCompressedRange(streamId, v162_.rotMin, v162_.rotMax, v162_.rotSendNumBits)
						end
						local v166_ = v165_ - v162_.curRot[v162_.rotationAxis]
						if math.abs(v166_) > 0.0001 then
							v162_.networkInterpolators.rotation:setTargetAngle(v165_)
						end
					end
					if v162_.animSpeed ~= nil then
						local v167_ = streamReadBool(streamId)
						local v168_ = NetworkUtil.readCompressedRange(streamId, v162_.animMinTime, v162_.animMaxTime, v162_.animSendNumBits)
						local v169_ = v168_ - v162_.curAnimTime
						if math.abs(v169_) > 0.0001 then
							v162_.networkInterpolators.animation:setTargetValue(v168_)
							if v167_ then
								v162_.networkInterpolators.animation:setValue(v168_)
							end
						end
					end
				end
			end
		end
	elseif streamReadBool(streamId) then
		for _, v170_ in ipairs(v161_.movingTools) do
			if v170_.axisActionIndex ~= nil then
				v170_.move = (streamReadUIntN(streamId, 12) / 4095 * 2 - 1) * 5
				local v171_ = v170_.move
				if math.abs(v171_) < 0.01 then
					v170_.move = 0
				end
			end
		end
		return
	end
end

-- Local values: spec, _, tool, value, _, tool, rot, curAnimTime, hasChanged
function Cylindered:onWriteUpdateStream(streamId, connection, dirtyMask)
	local v176_ = self.spec_cylindered
	if connection:getIsServer() then
		local v177_ = streamWriteBool
		local v178_ = v176_.cylinderedInputDirtyFlag
		if v177_(streamId, bit32.band(dirtyMask, v178_) ~= 0) then
			for _, v179_ in ipairs(v176_.movingTools) do
				if v179_.axisActionIndex ~= nil then
					local v180_ = v179_.moveToSend / 5
					local v181_ = (math.clamp(v180_, -1, 1) + 1) / 2 * 4095
					streamWriteUIntN(streamId, v181_, 12)
				end
			end
			return
		end
	else
		local v182_ = streamWriteBool
		local v183_ = v176_.cylinderedDirtyFlag
		if v182_(streamId, bit32.band(dirtyMask, v183_) ~= 0) then
			for _, v184_ in ipairs(v176_.movingTools) do
				if v184_.dirtyFlag ~= nil then
					local v185_ = streamWriteBool
					local v186_ = v184_.dirtyFlag
					local v187_
					if bit32.band(dirtyMask, v186_) == 0 then
						v187_ = false
					else
						v187_ = self:getIsMovingToolActive(v184_)
					end
					if v185_(streamId, v187_) then
						if v184_.transSpeed ~= nil then
							streamWriteFloat32(streamId, v184_.curTrans[v184_.translationAxis])
						end
						if v184_.rotSpeed ~= nil then
							local v188_ = v184_.curRot[v184_.rotationAxis]
							if v184_.rotMin == nil or v184_.rotMax == nil then
								NetworkUtil.writeCompressedAngle(streamId, v188_)
							else
								if v184_.syncMinRotLimits then
									streamWriteFloat32(streamId, v184_.rotMin)
								end
								if v184_.syncMaxRotLimits then
									streamWriteFloat32(streamId, v184_.rotMax)
								end
								NetworkUtil.writeCompressedRange(streamId, v188_, v184_.rotMin, v184_.rotMax, v184_.rotSendNumBits)
							end
						end
						if v184_.animSpeed ~= nil then
							local v189_ = self:getAnimationTime(v184_.animName)
							local v190_ = v189_ - v184_.curAnimTime
							local v191_ = math.abs(v190_) > 0.001
							streamWriteBool(streamId, v191_ or v184_.networkInterpolators.resetAnimInterpolation)
							v184_.networkInterpolators.resetAnimInterpolation = false
							v184_.curAnimTime = v189_
							NetworkUtil.writeCompressedRange(streamId, v184_.curAnimTime, v184_.animMinTime, v184_.animMaxTime, v184_.animSendNumBits)
						end
					end
				end
			end
		end
	end
end

-- Local values: spec, i, tool, rotSpeed, transSpeed, animSpeed, move, delta, changed, _, dependentTool, isAllowed, i, tool, interpolationAlpha, changed, newRot, newTrans, newAnimTime, _, dependentTool, i, tool
function Cylindered:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v194_ = self.spec_cylindered
	v194_.movingToolNeedsSound = false
	v194_.movingPartNeedsSound = false
	self:updateEasyControl(dt)
	if self.isServer then
		for v195_ = 1, #v194_.movingTools do
			local v196_ = v194_.movingTools[v195_]
			local v197_ = 0
			local v198_ = 0
			local v199_ = 0
			local v200_ = self:getMovingToolMoveValue(v196_)
			v196_.externalMove = 0
			if v196_.curTargetPosition ~= nil then
				local v201_ = Cylindered.getMovingToolState(self, v196_) - v196_.curTargetPosition
				if math.abs(v201_) < 0.001 then
					v196_.curTargetPosition = nil
					v196_.curTargetDirection = nil
				else
					v200_ = v196_.curTargetDirection
				end
			end
			if math.abs(v200_) > 0 then
				if v196_.rotSpeed ~= nil then
					v197_ = v200_ * v196_.rotSpeed
					if v196_.rotAcceleration ~= nil then
						local v202_ = v197_ - v196_.lastRotSpeed
						if math.abs(v202_) >= v196_.rotAcceleration * dt then
							if v196_.lastRotSpeed < v197_ then
								v197_ = v196_.lastRotSpeed + v196_.rotAcceleration * dt
							else
								v197_ = v196_.lastRotSpeed - v196_.rotAcceleration * dt
							end
						end
					end
				end
				if v196_.transSpeed ~= nil then
					v198_ = v200_ * v196_.transSpeed
					if v196_.transAcceleration ~= nil then
						local v203_ = v198_ - v196_.lastTransSpeed
						if math.abs(v203_) >= v196_.transAcceleration * dt then
							if v196_.lastTransSpeed < v198_ then
								v198_ = v196_.lastTransSpeed + v196_.transAcceleration * dt
							else
								v198_ = v196_.lastTransSpeed - v196_.transAcceleration * dt
							end
						end
					end
				end
				if v196_.animSpeed ~= nil then
					v199_ = v200_ * v196_.animSpeed
					if v196_.animAcceleration ~= nil then
						local v204_ = v199_ - v196_.lastAnimSpeed
						if math.abs(v204_) >= v196_.animAcceleration * dt then
							if v196_.lastAnimSpeed < v199_ then
								v199_ = v196_.lastAnimSpeed + v196_.animAcceleration * dt
							else
								v199_ = v196_.lastAnimSpeed - v196_.animAcceleration * dt
							end
						end
					end
				end
			else
				if v196_.rotAcceleration ~= nil then
					if v196_.lastRotSpeed < 0 then
						local v205_ = v196_.lastRotSpeed + v196_.rotAcceleration * dt
						v197_ = math.min(v205_, 0)
					else
						local v206_ = v196_.lastRotSpeed - v196_.rotAcceleration * dt
						v197_ = math.max(v206_, 0)
					end
				end
				if v196_.transAcceleration ~= nil then
					if v196_.lastTransSpeed < 0 then
						local v207_ = v196_.lastTransSpeed + v196_.transAcceleration * dt
						v198_ = math.min(v207_, 0)
					else
						local v208_ = v196_.lastTransSpeed - v196_.transAcceleration * dt
						v198_ = math.max(v208_, 0)
					end
				end
				if v196_.animAcceleration ~= nil then
					if v196_.lastAnimSpeed < 0 then
						local v209_ = v196_.lastAnimSpeed + v196_.animAcceleration * dt
						v199_ = math.min(v209_, 0)
					else
						local v210_ = v196_.lastAnimSpeed - v196_.animAcceleration * dt
						v199_ = math.max(v210_, 0)
					end
				end
			end
			local v211_ = false
			if v197_ == nil or v197_ == 0 then
				v196_.lastRotSpeed = 0
			else
				v211_ = v211_ or Cylindered.setToolRotation(self, v196_, v197_, dt)
			end
			if v198_ == nil or v198_ == 0 then
				v196_.lastTransSpeed = 0
			else
				v211_ = v211_ or Cylindered.setToolTranslation(self, v196_, v198_, dt)
			end
			if v199_ == nil or v199_ == 0 then
				v196_.lastAnimSpeed = 0
			else
				v211_ = v211_ or Cylindered.setToolAnimation(self, v196_, v199_, dt)
			end
			for _, v212_ in pairs(v196_.dependentMovingTools) do
				if v212_.speedScale ~= nil and (not v212_.requiresMovement or v211_) then
					v212_.movingTool.externalMove = v212_.movingTool.externalMove + v212_.speedScale * v196_.move
				end
				Cylindered.updateRotationBasedLimits(self, v196_, v212_)
				self:updateDependentToolLimits(v196_, v212_)
			end
			if v211_ then
				if v196_.playSound then
					v194_.movingToolNeedsSound = true
				end
				Cylindered.setDirty(self, v196_)
				v196_.networkPositionIsDirty = true
				self:raiseDirtyFlags(v196_.dirtyFlag)
				self:raiseDirtyFlags(v194_.cylinderedDirtyFlag)
				v196_.networkDirtyNextFrame = true
				if v196_.isConsumingPower then
					v194_.powerConsumingTimer = v194_.powerConsumingActiveTimeOffset
				end
			elseif v196_.networkDirtyNextFrame then
				self:raiseDirtyFlags(v196_.dirtyFlag)
				self:raiseDirtyFlags(v194_.cylinderedDirtyFlag)
				v196_.networkDirtyNextFrame = nil
			end
		end
	else
		for v213_ = 1, #v194_.movingTools do
			local v214_ = v194_.movingTools[v213_]
			v214_.networkTimeInterpolator:update(dt)
			local v215_ = v214_.networkTimeInterpolator:getAlpha()
			local v216_ = false
			if self:getIsMovingToolActive(v214_) then
				if v214_.rotSpeed ~= nil then
					local v217_ = v214_.networkInterpolators.rotation:getInterpolatedValue(v215_)
					local v218_ = v217_ - v214_.curRot[v214_.rotationAxis]
					if math.abs(v218_) > 0.0001 then
						v214_.curRot[v214_.rotationAxis] = v217_
						setRotation(v214_.node, v214_.curRot[1], v214_.curRot[2], v214_.curRot[3])
						v216_ = true
					end
				end
				if v214_.transSpeed ~= nil then
					local v219_ = v214_.networkInterpolators.translation:getInterpolatedValue(v215_)
					local v220_ = v219_ - v214_.curTrans[v214_.translationAxis]
					if math.abs(v220_) > 0.0001 then
						v214_.curTrans[v214_.translationAxis] = v219_
						setTranslation(v214_.node, v214_.curTrans[1], v214_.curTrans[2], v214_.curTrans[3])
						v216_ = true
					end
				end
				if v214_.animSpeed ~= nil then
					local v221_ = v214_.networkInterpolators.animation:getInterpolatedValue(v215_)
					local v222_ = v221_ - v214_.curAnimTime
					if math.abs(v222_) > 0.0001 then
						v214_.curAnimTime = v221_
						self:setAnimationTime(v214_.animName, v221_, nil, true)
						v216_ = true
					end
				end
				if v216_ then
					Cylindered.setDirty(self, v214_)
					SpecializationUtil.raiseEvent(self, "onMovingToolChanged", v214_, 0, dt)
				end
			end
			for _, v223_ in pairs(v214_.dependentMovingTools) do
				if not (v223_.movingTool.syncMinRotLimits and v223_.movingTool.syncMaxRotLimits) then
					Cylindered.updateRotationBasedLimits(self, v214_, v223_)
					self:updateDependentToolLimits(v214_, v223_)
				end
			end
			if v214_.networkTimeInterpolator:isInterpolating() then
				self:raiseActive()
			end
		end
	end
	for v224_ = 1, #v194_.movingTools do
		local v225_ = v194_.movingTools[v224_]
		if v225_.delayedHistoryIndex ~= nil and v225_.delayedHistoryIndex > 0 then
			self:updateDelayedTool(v225_)
		end
		if v225_.smoothedMove ~= 0 and v225_.lastInputTime + 50 < g_time then
			v225_.smoothedMove = 0
		end
	end
	if v194_.powerConsumingTimer > 0 then
		v194_.powerConsumingTimer = v194_.powerConsumingTimer - dt
	end
	if next(v194_.activeSamples) ~= nil then
		self:raiseActive()
	end
end

-- Local values: x, y, z, rx, ry, rz, i
function Cylindered:setDelayedData(tool, immediate)
	local v228_, v229_, v230_ = getTranslation(tool.node)
	local v231_, v232_, v233_ = getRotation(tool.node)
	tool.delayedHistroyData[tool.delayedFrames] = {
		["rot"] = { v231_, v232_, v233_ },
		["trans"] = { v228_, v229_, v230_ }
	}
	if immediate then
		for v234_ = 1, tool.delayedFrames - 1 do
			tool.delayedHistroyData[v234_] = tool.delayedHistroyData[tool.delayedFrames]
		end
	end
	tool.delayedHistoryIndex = tool.delayedFrames
end

-- Local values: spec, i, currentData, i, movingPart, movingTool
function Cylindered:updateDelayedTool(tool, forceLastPosition)
	local v238_ = self.spec_cylindered
	if forceLastPosition ~= nil and forceLastPosition then
		for v239_ = 1, tool.delayedFrames - 1 do
			tool.delayedHistroyData[v239_] = tool.delayedHistroyData[tool.delayedFrames]
		end
	end
	local v240_ = tool.delayedHistroyData[1]
	for v241_ = 1, tool.delayedFrames - 1 do
		tool.delayedHistroyData[v241_] = tool.delayedHistroyData[v241_ + 1]
	end
	local v242_ = setRotation
	local v243_ = tool.delayedNode
	local v244_ = v240_.rot
	v242_(v243_, unpack(v244_))
	local v245_ = setTranslation
	local v246_ = tool.delayedNode
	local v247_ = v240_.trans
	v245_(v246_, unpack(v247_))
	tool.delayedHistoryIndex = tool.delayedHistoryIndex - 1
	local v248_ = v238_.nodesToMovingParts[tool.delayedNode]
	local v249_ = v238_.nodesToMovingTools[tool.delayedNode]
	if v248_ ~= nil then
		Cylindered.setDirty(self, v248_)
	end
	if v238_.nodesToMovingTools[tool.delayedNode] ~= nil then
		Cylindered.setDirty(self, v249_)
	end
end

-- Local values: targetYTool, targetZTool, maxTrans, _, translationNode, i, xRotKey, node, movingTool, xOffset, yOffset, _, xOffset, yOffset, _, rootOffset, i, xRotationNode, curRot, i, zTranslationNode, curTrans, i, xRotationNode, i, zTranslationNode
function Cylindered:loadEasyArmControlFromXML(xmlFile, key, easyArmControl)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. ".xRotationNodes#maxDistance")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. ".xRotationNodes#transRotRatio")
	easyArmControl.rootNode = xmlFile:getValue(key .. "#rootNode", nil, self.components, self.i3dMappings)
	easyArmControl.targetNodeY = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	easyArmControl.targetNodeZ = xmlFile:getValue(key .. "#targetNodeZ", easyArmControl.targetNodeY, self.components, self.i3dMappings)
	easyArmControl.state = false
	if easyArmControl.targetNodeZ == nil or easyArmControl.targetNodeY == nil then
		Logging.xmlError(xmlFile, "Missing easy control targets!")
		return false
	end
	local v254_ = self:getMovingToolByNode(easyArmControl.targetNodeY)
	local v255_ = self:getMovingToolByNode(easyArmControl.targetNodeZ)
	if v254_ == nil or v255_ == nil then
		Logging.xmlError(xmlFile, "Missing moving tools for easy control targets!")
		return false
	end
	easyArmControl.targetNode = easyArmControl.targetNodeZ
	if getParent(easyArmControl.targetNodeY) == easyArmControl.targetNodeZ then
		easyArmControl.targetNode = easyArmControl.targetNodeY
	end
	easyArmControl.targetRefNode = xmlFile:getValue(key .. "#refNode", nil, self.components, self.i3dMappings)
	easyArmControl.lastValidPositionY = { getTranslation(easyArmControl.targetNodeY) }
	easyArmControl.lastValidPositionZ = { getTranslation(easyArmControl.targetNodeZ) }
	easyArmControl.moveSpeed = xmlFile:getValue(key .. ".targetMovement#speed", 1) / 1000
	easyArmControl.moveAcceleration = xmlFile:getValue(key .. ".targetMovement#acceleration", 50) / 1000000
	easyArmControl.lastSpeedY = 0
	easyArmControl.lastSpeedZ = 0
	easyArmControl.minTransMoveRatio = xmlFile:getValue(key .. ".zTranslationNodes#minMoveRatio", 0.2)
	easyArmControl.maxTransMoveRatio = xmlFile:getValue(key .. ".zTranslationNodes#maxMoveRatio", 0.8)
	easyArmControl.transMoveRatioMinDir = xmlFile:getValue(key .. ".zTranslationNodes#moveRatioMinDir", 0)
	easyArmControl.transMoveRatioMaxDir = xmlFile:getValue(key .. ".zTranslationNodes#moveRatioMaxDir", 1)
	easyArmControl.allowNegativeTrans = xmlFile:getValue(key .. ".zTranslationNodes#allowNegativeTrans", false)
	easyArmControl.minNegativeTrans = xmlFile:getValue(key .. ".zTranslationNodes#minNegativeTrans", 0)
	easyArmControl.forcedTransMove = nil
	easyArmControl.zTranslationNodes = {}
	local v_u_256_ = 0
	xmlFile:iterate(key .. ".zTranslationNodes.zTranslationNode", function(_, p257_)
		-- upvalues: (copy) xmlFile, (copy) self, (ref) v_u_256_, (copy) easyArmControl
		local v258_ = xmlFile:getValue(p257_ .. "#node", nil, self.components, self.i3dMappings)
		if v258_ ~= nil then
			local v259_ = self:getMovingToolByNode(v258_)
			if v259_ ~= nil then
				local v260_ = v259_.transMin - v259_.transMax
				local v261_ = math.abs(v260_)
				v_u_256_ = v_u_256_ + v261_
				v259_.easyArmControlActive = false
				local v262_ = easyArmControl.zTranslationNodes
				local v263_ = {
					["node"] = v258_,
					["movingTool"] = v259_,
					["maxDistance"] = v261_,
					["transFactor"] = 0,
					["startTranslation"] = { getTranslation(v258_) }
				}
				table.insert(v262_, v263_)
			end
		end
	end)
	local v264_ = v_u_256_
	for _, v265_ in ipairs(easyArmControl.zTranslationNodes) do
		v265_.transFactor = v265_.maxDistance / v264_
	end
	easyArmControl.xRotationNodes = {}
	for v266_ = 1, 2 do
		local v267_ = string.format("%s.xRotationNodes.xRotationNode%d", key, v266_)
		if not xmlFile:hasProperty(v267_) then
			Logging.xmlWarning(xmlFile, "Missing second xRotation node for easy control!")
			return false
		end
		XMLUtil.checkDeprecatedXMLElements(xmlFile, v267_ .. "#refNode")
		local v268_ = xmlFile:getValue(v267_ .. "#node", nil, self.components, self.i3dMappings)
		if v268_ ~= nil then
			local v269_ = self:getMovingToolByNode(v268_)
			if v269_ ~= nil then
				v269_.easyArmControlActive = false
				local v270_ = easyArmControl.xRotationNodes
				local v271_ = {
					["node"] = v268_,
					["movingTool"] = v269_,
					["startRotation"] = { getRotation(v268_) }
				}
				table.insert(v270_, v271_)
			end
		end
	end
	if #easyArmControl.xRotationNodes ~= 2 then
		Logging.xmlWarning(xmlFile, "Easy arm control requires two x rotation nodes! Only %d given. (%s)", #easyArmControl.xRotationNodes, key)
		return false
	end
	if easyArmControl.targetRefNode ~= nil then
		local v272_, v273_, _ = localToLocal(easyArmControl.targetRefNode, easyArmControl.xRotationNodes[2].node, 0, 0, 0)
		if math.abs(v272_) > 0.0001 or math.abs(v273_) > 0.0001 then
			Logging.xmlWarning(xmlFile, "Invalid position of \'%s\'. Offset to second xRotation node is not 0 on X or Y axis (x: %f y: %f)", key .. "#refNode", v272_, v273_)
			return false
		end
	end
	local v274_, v275_, _ = localToLocal(easyArmControl.xRotationNodes[2].node, easyArmControl.xRotationNodes[1].node, 0, 0, 0)
	if math.abs(v274_) > 0.0001 or math.abs(v275_) > 0.0001 then
		Logging.xmlWarning(xmlFile, "Invalid position of xRotationNode2. Offset to second xRotationNode1 is not 0 on X or Y axis (x: %f y: %f)", v274_, v275_)
		return false
	end
	local v276_ = calcDistanceFrom(easyArmControl.rootNode, easyArmControl.xRotationNodes[1].node)
	if v276_ > 0.05 then
		Logging.xmlWarning(xmlFile, "Distance between easyArmControl rootNode and xRotationNode1 is to big (%.2f). They should be at the same position.", v276_)
		return false
	end
	easyArmControl.maxTotalDistance = xmlFile:getValue(key .. "#maxTotalDistance")
	if easyArmControl.maxTotalDistance == nil then
		for v277_ = 1, #easyArmControl.xRotationNodes do
			local v278_ = easyArmControl.xRotationNodes[v277_]
			local v279_ = {
				getRotation(v278_.node),
				[v278_.movingTool.rotationAxis] = v278_.movingTool.rotMin
			}
			setRotation(v278_.node, v279_[1], v279_[2], v279_[3])
		end
		for v280_ = 1, #easyArmControl.zTranslationNodes do
			local v281_ = easyArmControl.zTranslationNodes[v280_]
			local v282_ = {
				getTranslation(v281_.node),
				[v281_.movingTool.translationAxis] = v281_.movingTool.transMax
			}
			setTranslation(v281_.node, v282_[1], v282_[2], v282_[3])
		end
		easyArmControl.maxTotalDistance = calcDistanceFrom(easyArmControl.rootNode, easyArmControl.targetRefNode)
		easyArmControl.maxTransDistance = calcDistanceFrom(easyArmControl.xRotationNodes[#easyArmControl.xRotationNodes].node, easyArmControl.targetRefNode)
		for v283_ = 1, #easyArmControl.xRotationNodes do
			local v284_ = easyArmControl.xRotationNodes[v283_]
			setRotation(v284_.node, v284_.startRotation[1], v284_.startRotation[2], v284_.startRotation[3])
		end
		for v285_ = 1, #easyArmControl.zTranslationNodes do
			local v286_ = easyArmControl.zTranslationNodes[v285_]
			setTranslation(v286_.node, v286_.startTranslation[1], v286_.startTranslation[2], v286_.startTranslation[3])
		end
	end
	return true
end

-- Local values: spec, easyArmControl, targetYTool, targetZTool, moveInputY, moveInputZ, hasChanged, transSpeedY, transSpeedZ, moveY, moveZ, worldTargetDirX, worldTargetDirY, worldTargetDirZ, worldTargetX, worldTargetY, worldTargetZ, locTargetX, locTargetY, locTargetZ, distanceToTarget, targetExceedFactor, circleDistance1, _, _, circleDistance2, circle1X, circle1Y, circle1Z, circle2X, circle2Y, circle2Z, numZTranslationNodes, inputDirY, inputDirZ, transDirX, transDirY, transDirZ, difference, rotTransRatio, _, _, targetZOffset, zDifference, minTransPct, transMove, i, zTranslationNode, movingTool, delta, currentTrans, transMin, newTrans, newDelta, ix, iy, i2x, i2y, node1Tool, node2Tool, node1Rotation, node1RotationClamped, node1Overrun, node2Rotation, node2RotationClamped, node2Overrun
function Cylindered:updateEasyControl(dt, updateDelayedNodes)
	local v290_ = self.spec_cylindered
	local v291_ = v290_.easyArmControl
	if v291_ ~= nil then
		local v292_ = self:getMovingToolByNode(v291_.targetNodeY)
		local v293_ = self:getMovingToolByNode(v291_.targetNodeZ)
		local v294_ = self:getMovingToolMoveValue(v292_)
		local v295_ = self:getMovingToolMoveValue(v293_)
		local v296_
		if v294_ == 0 and v295_ == 0 then
			v296_ = false
		else
			v296_ = true
			if v294_ ~= 0 and v292_.isConsumingPower or v295_ ~= 0 and v293_.isConsumingPower then
				v290_.powerConsumingTimer = v290_.powerConsumingActiveTimeOffset
			end
		end
		if self.isServer and (v291_.state and v296_) then
			local v297_ = v294_ * v291_.moveSpeed
			if v291_.moveAcceleration ~= nil then
				local v298_ = v297_ - v291_.lastSpeedY
				if math.abs(v298_) >= v291_.moveAcceleration * dt then
					if v291_.lastSpeedY < v297_ then
						v297_ = v291_.lastSpeedY + v291_.moveAcceleration * dt
					else
						v297_ = v291_.lastSpeedY - v291_.moveAcceleration * dt
					end
				end
			end
			local v299_ = v295_ * v291_.moveSpeed
			if v291_.moveAcceleration ~= nil then
				local v300_ = v299_ - v291_.lastSpeedZ
				if math.abs(v300_) >= v291_.moveAcceleration * dt then
					if v291_.lastSpeedZ < v299_ then
						v299_ = v291_.lastSpeedZ + v291_.moveAcceleration * dt
					else
						v299_ = v291_.lastSpeedZ - v291_.moveAcceleration * dt
					end
				end
			end
			v291_.lastSpeedY = v297_
			local v301_ = v297_ * dt
			v291_.lastSpeedZ = v299_
			local v302_ = v299_ * dt
			local v303_, v304_, v305_ = localDirectionToWorld(v291_.rootNode, 0, v301_, v302_)
			local v306_, v307_, v308_ = getWorldTranslation(v291_.targetRefNode)
			local v309_ = v306_ + v303_
			local v310_ = v307_ + v304_
			local v311_ = v308_ + v305_
			local v312_, v313_, v314_ = worldToLocal(v291_.rootNode, v309_, v310_, v311_)
			local v315_ = MathUtil.vector3Length(v312_, v313_, v314_)
			local v316_ = v291_.maxTotalDistance / v315_
			if v316_ < 1 then
				local v317_ = v312_ * v316_
				local v318_ = v313_ * v316_
				local v319_ = v314_ * v316_
				v309_, v310_, v311_ = localToWorld(v291_.rootNode, v317_, v318_, v319_)
				v315_ = v291_.maxTotalDistance
			end
			local v320_ = MathUtil.vector3Length(localToLocal(v291_.xRotationNodes[2].node, v291_.xRotationNodes[1].node, 0, 0, 0))
			local _, _, v321_ = localToLocal(v291_.targetRefNode, v291_.xRotationNodes[2].node, 0, 0, 0)
			local _, v322_, v323_ = localToLocal(v291_.xRotationNodes[1].node, v291_.rootNode, 0, 0, 0)
			local _, v324_, v325_ = worldToLocal(v291_.rootNode, v309_, v310_, v311_)
			local v326_ = #v291_.zTranslationNodes
			if v326_ > 0 then
				local v327_, v328_ = MathUtil.vector2Normalize(math.abs(v301_), (math.abs(v302_)))
				if v301_ == 0 and v302_ == 0 then
					v327_ = 0
					v328_ = 0
				end
				local v329_, v330_, v331_ = localDirectionToWorld(v291_.zTranslationNodes[1].node, 0, 0, 1)
				local _, v332_, v333_ = worldDirectionToLocal(v291_.rootNode, v329_, v330_, v331_)
				local v334_ = MathUtil.dotProduct(0, v327_, v328_, 0, v332_, v333_)
				local v335_ = math.acos(v334_)
				if v335_ > 1.5707963267948966 then
					v335_ = -v335_ + 3.141592653589793
				end
				local v336_ = (1 - v335_ / 1.5707963267948966 - v291_.transMoveRatioMinDir) / (v291_.transMoveRatioMaxDir - v291_.transMoveRatioMinDir)
				local v337_ = v291_.minTransMoveRatio
				local v338_ = v291_.maxTransMoveRatio
				local v339_ = math.clamp(v336_, v337_, v338_)
				local _, _, v340_ = worldToLocal(v291_.xRotationNodes[2].node, v309_, v310_, v311_)
				local v341_ = v340_ - v321_
				local v342_
				if v291_.allowNegativeTrans or v333_ >= 0 then
					v342_ = 0
				else
					v339_ = v341_ > 0 and -2 or v339_
					v342_ = v291_.minNegativeTrans * -v333_
				end
				local v343_ = v341_ * v339_
				for v344_ = 1, v326_ do
					local v345_ = v291_.zTranslationNodes[v344_].movingTool
					local v346_ = v343_ / v326_
					if v291_.forcedTransMove ~= nil then
						v346_ = v291_.forcedTransMove * v345_.transSpeed * dt
						v291_.forcedTransMove = nil
					end
					local v347_ = v345_.curTrans[v345_.translationAxis]
					local v348_ = (v345_.transMax - v345_.transMin) * v342_ + v345_.transMin
					local v349_ = v347_ + v346_
					local v350_ = v345_.transMax
					local v351_ = math.clamp(v349_, v348_, v350_) - v347_
					Cylindered.setAbsoluteToolTranslation(self, v345_, v347_ + v351_)
				end
				v321_ = MathUtil.vector3Length(worldToLocal(v291_.xRotationNodes[2].node, getWorldTranslation(v291_.targetRefNode)))
			end
			local v352_, v353_, _, _ = MathUtil.getCircleCircleIntersection(v323_, v322_, v320_, v325_, v324_, v321_)
			if v352_ ~= nil and v353_ ~= nil then
				local v354_ = v291_.xRotationNodes[1].movingTool
				local v355_ = v291_.xRotationNodes[2].movingTool
				local v356_ = -math.atan2(v353_, v352_)
				local v357_ = v354_.rotMin
				local v358_ = v354_.rotMax
				local v359_ = math.clamp(v356_, v357_, v358_)
				Cylindered.setAbsoluteToolRotation(self, v291_.xRotationNodes[1].movingTool, v359_, updateDelayedNodes)
				local v360_ = (v320_ * v320_ + v321_ * v321_ - v315_ * v315_) / (2 * v320_ * v321_)
				local v361_ = 3.141592653589793 - math.acos(v360_)
				local v362_ = v361_ + 0
				local v363_ = v355_.rotMin
				local v364_ = v355_.rotMax
				local v365_ = math.clamp(v362_, v363_, v364_)
				local v366_ = v361_ - v365_
				Cylindered.setAbsoluteToolRotation(self, v291_.xRotationNodes[2].movingTool, v365_, updateDelayedNodes)
				local v367_ = v359_ + v366_ * 0.5
				local v368_ = v354_.rotMin
				local v369_ = v354_.rotMax
				local v370_ = math.clamp(v367_, v368_, v369_)
				Cylindered.setAbsoluteToolRotation(self, v291_.xRotationNodes[1].movingTool, v370_, updateDelayedNodes)
			end
		end
	end
end

-- Local values: spec, easyArmControl, targetYTool, targetZTool, origin, _, y, _, _, oldY, _, z, _, _, oldZ
function Cylindered:setIsEasyControlActive(state)
	local v373_ = self.spec_cylindered
	local v374_ = v373_.easyArmControl
	if v374_ ~= nil then
		if self.isServer then
			if v374_ ~= nil then
				local v375_ = self:getMovingToolByNode(v374_.targetNodeY)
				local v376_ = self:getMovingToolByNode(v374_.targetNodeZ)
				if state then
					local v377_ = getParent(v374_.targetNodeY)
					if v377_ == v374_.targetNodeZ then
						v377_ = getParent(v374_.targetNodeZ)
					end
					local _, v378_, _ = localToLocal(v374_.targetRefNode, v377_, 0, 0, 0)
					local _, v379_, _ = getTranslation(v374_.targetNodeY)
					if Cylindered.setToolTranslation(self, v375_, nil, 0, v378_ - v379_) then
						Cylindered.setDirty(self, v375_)
					end
					local _, _, v380_ = localToLocal(v374_.targetRefNode, v377_, 0, 0, 0)
					local _, _, v381_ = getTranslation(v374_.targetNodeZ)
					if Cylindered.setToolTranslation(self, v376_, nil, 0, v380_ - v381_) then
						Cylindered.setDirty(self, v376_)
					end
					local v382_ = v374_.lastValidPositionY
					local v383_ = v374_.lastValidPositionY
					local v384_ = v374_.lastValidPositionY
					local v385_, v386_, v387_ = getTranslation(v374_.targetNodeY)
					v382_[1] = v385_
					v383_[2] = v386_
					v384_[3] = v387_
					local v388_ = v374_.lastValidPositionZ
					local v389_ = v374_.lastValidPositionZ
					local v390_ = v374_.lastValidPositionZ
					local v391_, v392_, v393_ = getTranslation(v374_.targetNodeZ)
					v388_[1] = v391_
					v389_[2] = v392_
					v390_[3] = v393_
					self:raiseDirtyFlags(v373_.cylinderedDirtyFlag)
				end
				v374_.state = state
			end
		else
			v374_.state = state
		end
	end
	self:requestActionEventUpdate()
end

-- Local values: spec, easyArmControl
function Cylindered:setEasyControlForcedTransMove(value)
	local v396_ = self.spec_cylindered.easyArmControl
	if v396_ ~= nil then
		v396_.forcedTransMove = value
	end
end

function Cylindered:updateExtraDependentParts(part, dt) end

-- Local values: _, dependentAnimation, pos, translationAxisValue, rotationAxisValue
function Cylindered:updateDependentAnimations(part, dt)
	if #part.dependentAnimations > 0 then
		for _, v399_ in ipairs(part.dependentAnimations) do
			local v400_ = v399_.translationAxis == nil and 0 or (select(v399_.translationAxis, getTranslation(v399_.node)) - v399_.minValue) / (v399_.maxValue - v399_.minValue)
			if v399_.rotationAxis ~= nil then
				v400_ = (select(v399_.rotationAxis, getRotation(v399_.node)) - v399_.minValue) / (v399_.maxValue - v399_.minValue)
			end
			local v401_ = math.clamp(v400_, 0, 1)
			if v399_.invert then
				v401_ = 1 - v401_
			end
			v399_.lastPos = v401_
			self:setAnimationTime(v399_.name, v401_, true, true)
		end
	end
end

-- Local values: state, transLimitChanged, state, rotLimitChanged
function Cylindered:updateDependentToolLimits(tool, dependentTool)
	if dependentTool.minTransLimits ~= nil or dependentTool.maxTransLimits ~= nil then
		local v405_ = Cylindered.getMovingToolState(self, tool)
		if dependentTool.minTransLimits ~= nil then
			dependentTool.movingTool.transMin = MathUtil.lerp(dependentTool.minTransLimits[1], dependentTool.minTransLimits[2], 1 - v405_)
		end
		if dependentTool.maxTransLimits ~= nil then
			dependentTool.movingTool.transMax = MathUtil.lerp(dependentTool.maxTransLimits[1], dependentTool.maxTransLimits[2], 1 - v405_)
		end
		if Cylindered.setToolTranslation(self, dependentTool.movingTool, 0, 0) then
			Cylindered.setDirty(self, dependentTool.movingTool)
		end
	end
	if dependentTool.minRotLimits ~= nil or dependentTool.maxRotLimits ~= nil then
		local v406_ = Cylindered.getMovingToolState(self, tool)
		if dependentTool.minRotLimits ~= nil then
			dependentTool.movingTool.rotMin = MathUtil.lerp(dependentTool.minRotLimits[1], dependentTool.minRotLimits[2], 1 - v406_)
		end
		if dependentTool.maxRotLimits ~= nil then
			dependentTool.movingTool.rotMax = MathUtil.lerp(dependentTool.maxRotLimits[1], dependentTool.maxRotLimits[2], 1 - v406_)
		end
		dependentTool.movingTool.networkInterpolators.rotation:setMinMax(dependentTool.movingTool.rotMin, dependentTool.movingTool.rotMax)
		if Cylindered.setToolRotation(self, dependentTool.movingTool, 0, 0) then
			Cylindered.setDirty(self, dependentTool.movingTool)
		end
	end
end

-- Local values: samples, i, sample, spec, spec, spec
function Cylindered:onMovingPartSoundEvent(part, action, type)
	if part.samplesByAction ~= nil then
		local v411_ = part.samplesByAction[action]
		if v411_ ~= nil then
			for v412_ = 1, #v411_ do
				local v413_ = v411_[v412_]
				if type == Cylindered.SOUND_TYPE_EVENT then
					if v413_.loops == 0 then
						v413_.loops = 1
					end
					g_soundManager:playSample(v413_)
				elseif type == Cylindered.SOUND_TYPE_CONTINUES then
					if g_soundManager:getIsSamplePlaying(v413_) then
						if v413_.lastActivationPart == part then
							v413_.lastActivationTime = g_time
						end
					else
						g_soundManager:playSample(v413_)
						v413_.lastActivationTime = g_time
						v413_.lastActivationPart = part
						local v414_ = self.spec_cylindered.activeSamples
						table.insert(v414_, v413_)
					end
				elseif type == Cylindered.SOUND_TYPE_ENDING then
					local v415_ = self.spec_cylindered
					if v415_.endingSamplesBySample[v413_] == nil then
						v413_.lastActivationTime = g_time
						local v416_ = v415_.endingSamples
						table.insert(v416_, v413_)
						v415_.endingSamplesBySample[v413_] = v413_
					else
						v413_.lastActivationTime = g_time
					end
				elseif type == Cylindered.SOUND_TYPE_STARTING then
					local v417_ = self.spec_cylindered
					if v417_.startingSamplesBySample[v413_] == nil then
						if v413_.loops == 0 then
							v413_.loops = 1
						end
						g_soundManager:playSample(v413_)
						v413_.lastActivationTime = g_time
						local v418_ = v417_.startingSamples
						table.insert(v418_, v413_)
						v417_.startingSamplesBySample[v413_] = v413_
					else
						v413_.lastActivationTime = g_time
					end
				end
			end
		end
	end
end

function Cylindered:updateMovingToolSoundEvents(tool, direction, hitLimit, wasAtLimit)
	if tool.samplesByAction ~= nil then
		self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_END, Cylindered.SOUND_TYPE_ENDING)
		self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_START, Cylindered.SOUND_TYPE_STARTING)
		if direction then
			self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_POS, Cylindered.SOUND_TYPE_CONTINUES)
			self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_END_POS, Cylindered.SOUND_TYPE_ENDING)
			self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_START_POS, Cylindered.SOUND_TYPE_STARTING)
			if hitLimit then
				self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_END_POS_LIMIT, Cylindered.SOUND_TYPE_ENDING)
			end
			if wasAtLimit then
				self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_START_POS_LIMIT, Cylindered.SOUND_TYPE_STARTING)
				return
			end
		else
			self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_NEG, Cylindered.SOUND_TYPE_CONTINUES)
			self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_END_NEG, Cylindered.SOUND_TYPE_ENDING)
			self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_START_NEG, Cylindered.SOUND_TYPE_STARTING)
			if hitLimit then
				self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_END_NEG_LIMIT, Cylindered.SOUND_TYPE_ENDING)
			end
			if wasAtLimit then
				self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_START_NEG_LIMIT, Cylindered.SOUND_TYPE_STARTING)
			end
		end
	end
end

-- Local values: spec, k, _, _, groupIndex, isActive, _, movingTool, subSelectionIndex, vehicle
function Cylindered:updateControlGroups()
	local v425_ = self.spec_cylindered
	self:clearSubselections()
	for v426_, _ in pairs(v425_.controlGroupMapping) do
		v425_.controlGroupMapping[v426_] = nil
	end
	for _, v427_ in ipairs(v425_.controlGroups) do
		local v428_ = false
		for _, v429_ in pairs(v425_.movingTools) do
			if v429_.axisActionIndex ~= nil and (v429_.controlGroupIndex == v427_ and v429_.lastIsActiveState) then
				v428_ = true
				break
			end
		end
		if v428_ then
			local v430_ = self:addSubselection(v427_)
			v425_.controlGroupMapping[v430_] = v427_
		end
	end
	self.rootVehicle:updateSelectableObjects()
	if self.rootVehicle:getSelectedVehicle() == self then
		self.rootVehicle:setSelectedVehicle(self, 99999, false)
	end
end

-- Local values: spec, movingToolStateChanged, _, movingTool, isActive, actionEvent, i, sample, i, sample, i, sample
function Cylindered:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local v433_ = self.spec_cylindered
		local v434_ = false
		for _, v435_ in pairs(v433_.movingTools) do
			if v435_.axisActionIndex ~= nil then
				local v436_ = self:getIsMovingToolActive(v435_)
				if v436_ ~= v435_.lastIsActiveState then
					v435_.lastIsActiveState = v436_
					v434_ = true
				end
				if v433_.currentControlGroupIndex == v435_.controlGroupIndex then
					local v437_ = v433_.actionEvents[v435_.axisActionIndex]
					if v437_ ~= nil then
						g_inputBinding:setActionEventActive(v437_.actionEventId, v436_)
						if not v436_ then
							v435_.move = 0
							if v435_.move ~= v435_.moveToSend then
								v435_.moveToSend = v435_.move
								self:raiseDirtyFlags(v433_.cylinderedInputDirtyFlag)
							end
						end
					end
				end
			end
		end
		if v434_ then
			self:updateControlGroups()
		end
		for v438_ = #v433_.activeSamples, 1, -1 do
			local v439_ = v433_.activeSamples[v438_]
			if v439_.lastActivationTime + dt * 3 < g_time then
				if v439_.lastActivationTime + dt * 3 + v439_.dropOffTime >= g_time then
					if not v439_.dropOffActive then
						v439_.dropOffActive = true
						g_soundManager:setSamplePitchOffset(v439_, g_soundManager:getCurrentSamplePitch(v439_) * (v439_.dropOffFactor - 1))
					end
				else
					v439_.dropOffActive = false
					g_soundManager:setSamplePitchOffset(v439_, 0)
					g_soundManager:stopSample(v439_)
					table.remove(v433_.activeSamples, v438_)
				end
			end
		end
		for v440_ = #v433_.endingSamples, 1, -1 do
			local v441_ = v433_.endingSamples[v440_]
			if v441_.lastActivationTime + dt < g_time then
				if v441_.loops == 0 then
					v441_.loops = 1
				end
				g_soundManager:playSample(v441_)
				table.remove(v433_.endingSamples, v440_)
				v433_.endingSamplesBySample[v441_] = nil
			end
		end
		for v442_ = #v433_.startingSamples, 1, -1 do
			local v443_ = v433_.startingSamples[v442_]
			if v443_.lastActivationTime + dt < g_time then
				table.remove(v433_.startingSamples, v442_)
				v433_.startingSamplesBySample[v443_] = nil
			end
		end
	end
end

-- Local values: spec, _, part
function Cylindered:onUpdateEnd(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v446_ = self.spec_cylindered
	for _, v447_ in pairs(v446_.activeDirtyMovingParts) do
		Cylindered.setDirty(self, v447_)
	end
	self:updateDirtyMovingParts(dt, true)
end

-- Local values: spec, _, part
function Cylindered:onPostUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v450_ = self.spec_cylindered
	for _, v451_ in pairs(v450_.activeDirtyMovingParts) do
		if self.currentUpdateDistance < v451_.maxUpdateDistance then
			Cylindered.setDirty(self, v451_)
		end
	end
	self:updateDirtyMovingParts(dt, true)
end

function Cylindered:onPostUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	self:updateDirtyMovingParts(dt, false)
end

-- Local values: spec, i, tool, i, part, isActive
function Cylindered:updateDirtyMovingParts(dt, updateSound)
	local v457_ = self.spec_cylindered
	for v458_ = 1, #v457_.movingTools do
		local v459_ = v457_.movingTools[v458_]
		if v459_.isDirty then
			if v459_.playSound then
				v457_.movingToolNeedsSound = true
			end
			Cylindered.updateWheels(self, v459_)
			if self.isServer then
				Cylindered.updateComponentJoints(self, v459_, false)
			end
			self:updateExtraDependentParts(v459_, dt)
			self:updateDependentAnimations(v459_, dt)
			v459_.isDirty = false
		end
	end
	if self.anyMovingPartsDirty then
		for v460_ = 1, #v457_.movingParts do
			local v461_ = v457_.movingParts[v460_]
			if v461_.isDirty then
				local v462_ = self:getIsMovingPartActive(v461_)
				if v462_ or v461_.smoothedDirectionScale and v461_.smoothedDirectionScaleAlpha ~= 0 then
					Cylindered.updateMovingPart(self, v461_, false, nil, v462_)
					self:updateExtraDependentParts(v461_, dt)
					self:updateDependentAnimations(v461_, dt)
					if v461_.playSound then
						v457_.cylinderedHydraulicSoundPartNumber = v460_
						v457_.movingPartNeedsSound = true
					end
				end
			elseif v457_.isClient and v457_.cylinderedHydraulicSoundPartNumber == v460_ then
				v457_.movingPartNeedsSound = false
			end
		end
		self.anyMovingPartsDirty = false
	end
	if updateSound and self.isClient then
		if v457_.movingToolNeedsSound or v457_.movingPartNeedsSound then
			if not v457_.isHydraulicSamplePlaying then
				g_soundManager:playSample(v457_.samples.hydraulic)
				v457_.isHydraulicSamplePlaying = true
			end
			self:raiseActive()
			return
		end
		if v457_.isHydraulicSamplePlaying then
			g_soundManager:stopSample(v457_.samples.hydraulic)
			v457_.isHydraulicSamplePlaying = false
		end
	end
end

-- Local values: spec
function Cylindered:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v465_ = self.spec_cylindered
	if #v465_.controlGroupNames > 1 and (isActiveForInputIgnoreSelection and v465_.currentControlGroupIndex ~= 0) then
		g_currentMission:addExtraPrintText(string.format(g_i18n:getText("action_selectedControlGroup"), v465_.controlGroupNames[v465_.currentControlGroupIndex], v465_.currentControlGroupIndex))
	end
end

-- Local values: spec, _, partKey, entry
function Cylindered:loadMovingPartsFromXML(xmlFile, key)
	local v469_ = self.spec_cylindered
	for _, v470_ in xmlFile:iterator(key) do
		local v471_ = {}
		if self:loadMovingPartFromXML(xmlFile, v470_, v471_) then
			if v469_.referenceNodes[v471_.node] == nil then
				v469_.referenceNodes[v471_.node] = {}
			end
			if v469_.nodesToMovingParts[v471_.node] == nil then
				local v472_ = v469_.referenceNodes[v471_.node]
				table.insert(v472_, v471_)
				self:loadDependentParts(xmlFile, v470_, v471_)
				self:loadDependentComponentJoints(xmlFile, v470_, v471_)
				self:loadCopyLocalDirectionParts(xmlFile, v470_, v471_)
				self:loadExtraDependentParts(xmlFile, v470_, v471_)
				self:loadDependentAnimations(xmlFile, v470_, v471_)
				v471_.key = v470_
				local v473_ = v469_.movingParts
				table.insert(v473_, v471_)
				if v471_.isActiveDirty then
					local v474_ = v469_.activeDirtyMovingParts
					table.insert(v474_, v471_)
				end
				v469_.nodesToMovingParts[v471_.node] = v471_
			else
				Logging.xmlWarning(xmlFile, "Moving part with node \'%s\' already exists!", getName(v471_.node))
			end
		end
	end
end

-- Local values: node, referenceFrame, x, y, z, _, pointKey, lineNode, _, _, zOffset, minRot, maxRot, localReferencePoint, refX, refY, refZ, i, referencePoint, x, y, z, _, x, y, z, side
function Cylindered:loadMovingPartFromXML(xmlFile, key, entry)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#index", key .. "#node")
	local v479_ = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	local v480_ = xmlFile:getValue(key .. "#referenceFrame", nil, self.components, self.i3dMappings)
	if v479_ == nil or v480_ == nil then
		return false
	end
	entry.referencePoint = xmlFile:getValue(key .. "#referencePoint", nil, self.components, self.i3dMappings)
	entry.referencePoints = xmlFile:getValue(key .. "#referencePoints", nil, self.components, self.i3dMappings, true)
	entry.numReferencePoints = #entry.referencePoints
	entry.hasReferencePoints = entry.numReferencePoints > 0 and true or entry.referencePoint ~= nil
	entry.node = v479_
	entry.parent = getParent(v479_)
	entry.referenceFrame = v480_
	entry.invertZ = xmlFile:getValue(key .. "#invertZ", false)
	entry.scaleZ = xmlFile:getValue(key .. "#scaleZ", false)
	entry.limitedAxis = xmlFile:getValue(key .. "#limitedAxis")
	entry.isActiveDirty = xmlFile:getValue(key .. "#isActiveDirty", false)
	entry.playSound = xmlFile:getValue(key .. "#playSound", false)
	entry.moveToReferenceFrame = xmlFile:getValue(key .. "#moveToReferenceFrame", false)
	if entry.moveToReferenceFrame then
		local v481_, v482_, v483_ = worldToLocal(v480_, getWorldTranslation(v479_))
		entry.referenceFrameOffset = { v481_, v482_, v483_ }
	end
	if entry.referenceFrame == entry.node then
		Logging.xmlWarning(xmlFile, "Reference frame equals moving part node. This can lead to bad behaviours! Node \'%s\' in \'%s\'.", getName(entry.node), key)
	end
	entry.doLineAlignment = xmlFile:getValue(key .. "#doLineAlignment", false)
	entry.doInversedLineAlignment = xmlFile:getValue(key .. "#doInversedLineAlignment", false)
	entry.do3DLineAlignment = xmlFile:getValue(key .. "#do3DLineAlignment", false)
	entry.partLength = xmlFile:getValue(key .. ".orientationLine#partLength", 0.5)
	entry.partLengthNode = xmlFile:getValue(key .. ".orientationLine#partLengthNode", nil, self.components, self.i3dMappings)
	entry.orientationLineNodes = {}
	for _, v484_ in self.xmlFile:iterator(key .. ".orientationLine.lineNode") do
		local v485_ = xmlFile:getValue(v484_ .. "#node", nil, self.components, self.i3dMappings)
		if v485_ ~= nil then
			if entry.doInversedLineAlignment then
				local _, _, v486_ = localToLocal(v485_, entry.node, 0, 0, 0)
				if v486_ >= 0 then
					goto l16
				end
				Logging.xmlWarning(xmlFile, "Local orientation line node \'%s\' is in negative Z direction to the movingPart node. This is not allowed! (%s)", getName(v485_), v484_)
			else
				::l16::
				local v487_ = entry.orientationLineNodes
				table.insert(v487_, v485_)
			end
		end
	end
	if entry.do3DLineAlignment then
		if #entry.orientationLineNodes == 2 then
			entry.orientationLineTransNode = xmlFile:getValue(key .. ".orientationLine#referenceTransNode", nil, self.components, self.i3dMappings)
			if entry.orientationLineTransNode == nil then
				Logging.xmlWarning(xmlFile, "Failed to load 3D line alignment from xml. Missing referenceTransNode! (movingPart \'%s\')", getName(v479_))
				entry.do3DLineAlignment = false
			end
		else
			Logging.xmlWarning(xmlFile, "Failed to load 3D line alignment from xml. Requires exactly two line nodes! (movingPart \'%s\')", getName(v479_))
			entry.do3DLineAlignment = false
		end
	end
	entry.doDirectionAlignment = xmlFile:getValue(key .. "#doDirectionAlignment", true)
	entry.doRotationAlignment = xmlFile:getValue(key .. "#doRotationAlignment", false)
	entry.rotMultiplier = xmlFile:getValue(key .. "#rotMultiplier", 0)
	if entry.doDirectionAlignment and entry.doRotationAlignment then
		Logging.xmlWarning(xmlFile, "Direction alignment and rotation alignment used at the same time for movingPart \'%s\' in \'%s\'", getName(v479_), key)
		return false
	end
	if entry.doDirectionAlignment and (entry.doLineAlignment or (entry.doInversedLineAlignment or entry.do3DLineAlignment)) then
		Logging.xmlWarning(xmlFile, "Direction alignment and line alignment used at the same time for movingPart \'%s\' in \'%s\'", getName(v479_), key)
		return false
	end
	local v488_ = xmlFile:getValue(key .. "#minRot")
	local v489_ = xmlFile:getValue(key .. "#maxRot")
	if v488_ ~= nil and v489_ ~= nil then
		if entry.limitedAxis == nil then
			Logging.xmlWarning(xmlFile, "minRot/maxRot requires the use of limitedAxis in for movingPart \'%s\' in \'%s\'", getName(v479_), key)
		else
			entry.minRot = MathUtil.getValidLimit(v488_)
			entry.maxRot = MathUtil.getValidLimit(v489_)
		end
	end
	entry.alignToWorldY = xmlFile:getValue(key .. "#alignToWorldY", false)
	if entry.hasReferencePoints then
		local v490_ = xmlFile:getValue(key .. "#localReferencePoint", nil, self.components, self.i3dMappings)
		local v491_, v492_, v493_
		if entry.referencePoint == nil then
			local v494_ = 0
			local v495_ = 0
			local v496_ = 0
			for _, v497_ in ipairs(entry.referencePoints) do
				local v498_, v499_, v500_ = worldToLocal(v479_, getWorldTranslation(v497_))
				v494_ = v494_ + v498_
				v495_ = v495_ + v499_
				v496_ = v496_ + v500_
			end
			v491_ = v494_ / entry.numReferencePoints
			v492_ = v495_ / entry.numReferencePoints
			v493_ = v496_ / entry.numReferencePoints
		else
			v491_, v492_, v493_ = worldToLocal(v479_, getWorldTranslation(entry.referencePoint))
		end
		local _, _, v501_ = worldToLocal(entry.node, v491_, v492_, v493_)
		entry.smoothedDirectionScaleZOffset = v501_
		if v490_ == nil then
			entry.referenceDistance = 0
			entry.localReferencePoint = { v491_, v492_, v493_ }
		else
			local v502_, v503_, v504_ = worldToLocal(v479_, getWorldTranslation(v490_))
			entry.referenceDistance = MathUtil.vector3Length(v491_ - v502_, v492_ - v503_, v493_ - v504_)
			entry.lastReferenceDistance = entry.referenceDistance
			entry.localReferencePoint = { v502_, v503_, v504_ }
			entry.localReferenceAngleSide = v503_ * (v493_ - v504_) - v504_ * (v492_ - v503_)
			entry.localReferencePointNode = v490_
			entry.updateLocalReferenceDistance = xmlFile:getValue(key .. "#updateLocalReferenceDistance", false)
			entry.localReferenceTranslate = xmlFile:getValue(key .. "#localReferenceTranslate", false)
			if entry.localReferenceTranslate then
				entry.localReferenceTranslation = { getTranslation(entry.node) }
			end
			entry.dynamicLocalReferenceDistance = xmlFile:getValue(key .. "#dynamicLocalReferenceDistance", false)
		end
		entry.referenceDistanceThreshold = xmlFile:getValue(key .. "#referenceDistanceThreshold", 0.0001)
		entry.useLocalOffset = xmlFile:getValue(key .. "#useLocalOffset", false)
		entry.referencePointOffset = xmlFile:getValue(key .. "#referencePointOffset")
		entry.referenceDistance = xmlFile:getValue(key .. "#referenceDistance", entry.referenceDistance)
		entry.referenceDistancePoint = xmlFile:getValue(key .. "#referenceDistancePoint", nil, self.components, self.i3dMappings)
		entry.localReferenceDistance = xmlFile:getValue(key .. "#localReferenceDistance", MathUtil.vector2Length(entry.localReferencePoint[2], entry.localReferencePoint[3]))
		self:loadDependentTranslatingParts(xmlFile, key, entry)
	end
	self:loadDependentMovingTools(xmlFile, key, entry)
	entry.directionThreshold = xmlFile:getValue(key .. "#directionThreshold", 0.0001)
	entry.directionThresholdActive = xmlFile:getValue(key .. "#directionThresholdActive", 0.00001)
	if entry.doDirectionAlignment and not entry.hasReferencePoints then
		entry.directionThreshold = 0
		entry.directionThresholdActive = 0
	end
	entry.maxUpdateDistance = xmlFile:getValue(key .. "#maxUpdateDistance", "-")
	if entry.maxUpdateDistance == "-" then
		entry.maxUpdateDistance = math.huge
	else
		local v505_ = entry.maxUpdateDistance
		entry.maxUpdateDistance = tonumber(v505_)
	end
	if entry.isActiveDirty and (xmlFile:getString(key .. "#maxUpdateDistance") == nil or entry.maxUpdateDistance == nil) then
		Logging.xmlWarning(xmlFile, "No max. update distance set for isActiveDirty moving part \'%s\'! Use #maxUpdateDistance attribute.", getName(v479_))
	end
	entry.smoothedDirectionScale = xmlFile:getValue(key .. "#smoothedDirectionScale", false)
	entry.smoothedDirectionTime = 1 / xmlFile:getValue(key .. "#smoothedDirectionTime", 2)
	entry.smoothedDirectionScaleAlpha = nil
	if entry.smoothedDirectionScale then
		entry.initialDirection = { localDirectionToLocal(entry.node, getParent(entry.node), 0, 0, 1) }
	end
	entry.debug = xmlFile:getValue(key .. "#debug", false)
	if entry.debug then
		Logging.xmlWarning(xmlFile, "MovingPart debug enabled for moving part \'%s\'", getName(v479_))
	end
	entry.lastDirection = { 0, 0, 0 }
	entry.lastUpVector = { 0, 0, 0 }
	entry.isDirty = false
	entry.isPart = true
	entry.isActive = true
	return true
end

-- Local values: spec, _, toolKey, entry
function Cylindered:loadMovingToolsFromXML(xmlFile, key)
	local v509_ = self.spec_cylindered
	for _, v510_ in xmlFile:iterator(key) do
		local v511_ = {}
		if self:loadMovingToolFromXML(xmlFile, v510_, v511_) then
			if v509_.referenceNodes[v511_.node] == nil then
				v509_.referenceNodes[v511_.node] = {}
			end
			if v509_.nodesToMovingTools[v511_.node] == nil then
				local v512_ = v509_.referenceNodes[v511_.node]
				table.insert(v512_, v511_)
				self:loadDependentMovingTools(xmlFile, v510_, v511_)
				self:loadDependentParts(xmlFile, v510_, v511_)
				self:loadDependentComponentJoints(xmlFile, v510_, v511_)
				self:loadExtraDependentParts(xmlFile, v510_, v511_)
				self:loadDependentAnimations(xmlFile, v510_, v511_)
				v511_.isActive = true
				v511_.key = v510_
				local v513_ = v509_.movingTools
				table.insert(v513_, v511_)
				v509_.nodesToMovingTools[v511_.node] = v511_
			else
				Logging.xmlWarning(xmlFile, "Moving tool with node \'%s\' already exists!", getName(v511_.node))
			end
		end
	end
end

-- Local values: spec, node, rotSpeed, rotAcceleration, range, requiredMinValues, bitsToUse, availableValues, availableValues, availableValues, availableValues, availableValues, availableValues, availableValues, availableValues, availableValues, availableValues, availableValues, transSpeed, transAcceleration, animSpeed, animAcceleration, iconName, detachingRotMaxLimit, detachingRotMinLimit, detachingTransMaxLimit, detachingTransMinLimit, detachLock, requiredConfigurationName, requiredConfigurationIndices, i, rx, ry, rz, x, y, z, i
function Cylindered:loadMovingToolFromXML(xmlFile, key, entry)
	local v518_ = self.spec_cylindered
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#index", key .. "#node")
	local v519_ = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	if v519_ == nil then
		return false
	end
	entry.node = v519_
	entry.externalMove = 0
	entry.easyArmControlActive = true
	entry.isEasyControlTarget = xmlFile:getValue(key .. "#isEasyControlTarget", false)
	entry.networkInterpolators = {}
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#rotSpeed", key .. ".rotation#rotSpeed")
	local v520_ = xmlFile:getValue(key .. ".rotation#rotSpeed")
	if v520_ ~= nil then
		entry.rotSpeed = v520_ / 1000
	end
	local v521_ = xmlFile:getValue(key .. ".rotation#rotAcceleration")
	if v521_ ~= nil then
		entry.rotAcceleration = v521_ / 1000000
	end
	entry.lastRotSpeed = 0
	entry.rotMax = xmlFile:getValue(key .. ".rotation#rotMax")
	entry.rotMin = xmlFile:getValue(key .. ".rotation#rotMin")
	entry.syncMaxRotLimits = xmlFile:getValue(key .. ".rotation#syncMaxRotLimits", false)
	entry.syncMinRotLimits = xmlFile:getValue(key .. ".rotation#syncMinRotLimits", false)
	entry.rotSendNumBits = xmlFile:getValue(key .. ".rotation#rotSendNumBits")
	entry.attachRotMax = xmlFile:getValue(key .. ".rotation#attachRotMax")
	entry.attachRotMin = xmlFile:getValue(key .. ".rotation#attachRotMin")
	if entry.rotSendNumBits == nil then
		if entry.rotMin == nil or entry.rotMax == nil then
			entry.rotSendNumBits = 11
		else
			local v522_ = (entry.rotMax - entry.rotMin) / Cylindered.MOVING_TOOL_SEND_MIN_RESOLUTION
			local v523_ = math.ceil(v522_)
			local _ = v523_ <= 2047
			local v524_ = 11
			local v525_ = v523_ <= 1023 and 10 or v524_
			local v526_ = v523_ <= 511 and 9 or v525_
			local v527_ = v523_ <= 255 and 8 or v526_
			local v528_ = v523_ <= 127 and 7 or v527_
			local v529_ = v523_ <= 63 and 6 or v528_
			local v530_ = v523_ <= 31 and 5 or v529_
			local v531_ = v523_ <= 15 and 4 or v530_
			local v532_ = v523_ <= 7 and 3 or v531_
			local v533_ = v523_ <= 3 and 2 or v532_
			entry.rotSendNumBits = v523_ <= 1 and 1 or v533_
		end
	end
	if entry.rotMin ~= nil and (entry.rotMax ~= nil and entry.rotMin >= entry.rotMax) then
		Logging.xmlWarning(xmlFile, "Rotation min value is greater or equal to max value for movingTool \'%s\' in \'%s\'", getName(v519_), key)
		return false
	end
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#transSpeed", key .. ".rotation#transSpeed")
	local v534_ = xmlFile:getValue(key .. ".translation#transSpeed")
	if v534_ ~= nil then
		entry.transSpeed = v534_ / 1000
	end
	local v535_ = xmlFile:getValue(key .. ".translation#transAcceleration")
	if v535_ ~= nil then
		entry.transAcceleration = v535_ / 1000000
	end
	entry.lastTransSpeed = 0
	entry.transMax = xmlFile:getValue(key .. ".translation#transMax")
	entry.transMin = xmlFile:getValue(key .. ".translation#transMin")
	entry.attachTransMax = xmlFile:getValue(key .. ".translation#attachTransMax")
	entry.attachTransMin = xmlFile:getValue(key .. ".translation#attachTransMin")
	entry.playSound = xmlFile:getValue(key .. "#playSound", false)
	if entry.transMin ~= nil and (entry.transMax ~= nil and entry.transMin >= entry.transMax) then
		Logging.xmlWarning(xmlFile, "Translation min value is greater or equal to max value for movingTool \'%s\' in \'%s\'", getName(v519_), key)
		return false
	end
	entry.isConsumingPower = xmlFile:getValue(key .. "#isConsumingPower", false)
	if SpecializationUtil.hasSpecialization(AnimatedVehicle, self.specializations) then
		local v536_ = xmlFile:getValue(key .. ".animation#animSpeed")
		if v536_ ~= nil then
			entry.animSpeed = v536_ / 1000
		end
		local v537_ = xmlFile:getValue(key .. ".animation#animAcceleration")
		if v537_ ~= nil then
			entry.animAcceleration = v537_ / 1000000
		end
		entry.curAnimTime = 0
		entry.lastAnimSpeed = 0
		entry.animName = xmlFile:getValue(key .. ".animation#animName")
		entry.animSendNumBits = xmlFile:getValue(key .. ".animation#animSendNumBits", 8)
		local v538_ = xmlFile:getValue(key .. ".animation#animMaxTime", 1)
		entry.animMaxTime = math.min(v538_, 1)
		local v539_ = xmlFile:getValue(key .. ".animation#animMinTime", 0)
		entry.animMinTime = math.max(v539_, 0)
		if entry.animMinTime >= entry.animMaxTime then
			Logging.xmlWarning(xmlFile, "Animation min value is greater or equal to max value for movingTool \'%s\' in \'%s\'", getName(v519_), key)
			return false
		end
		entry.animStartTime = xmlFile:getValue(key .. ".animation#animStartTime")
		if entry.animStartTime ~= nil then
			entry.curAnimTime = entry.animStartTime
		end
		entry.networkInterpolators.animation = InterpolatorValue.new(entry.curAnimTime)
		entry.networkInterpolators.animation:setMinMax(0, 1)
		entry.networkInterpolators.resetAnimInterpolation = false
	end
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. ".controls#iconFilename", key .. ".controls#iconName")
	local v540_ = xmlFile:getValue(key .. ".controls#iconName")
	if v540_ ~= nil then
		if InputHelpElement.AXIS_ICON[v540_] == nil then
			v540_ = (self.customEnvironment or "") .. v540_
		end
		entry.axisActionIcon = v540_
	end
	entry.controlGroupIndex = xmlFile:getValue(key .. ".controls#groupIndex", 0)
	if entry.controlGroupIndex ~= 0 then
		if v518_.controlGroupNames[entry.controlGroupIndex] == nil then
			Logging.xmlWarning(xmlFile, "ControlGroup \'%d\' not defined for \'%s\'!", entry.controlGroupIndex, key)
		else
			table.addElement(v518_.controlGroups, entry.controlGroupIndex)
		end
	end
	entry.axis = xmlFile:getValue(key .. ".controls#axis")
	if entry.axis ~= nil then
		entry.axisActionIndex = InputAction[entry.axis]
	end
	entry.invertAxis = xmlFile:getValue(key .. ".controls#invertAxis", false)
	entry.mouseSpeedFactor = xmlFile:getValue(key .. ".controls#mouseSpeedFactor", 1)
	if entry.rotSpeed ~= nil or (entry.transSpeed ~= nil or entry.animSpeed ~= nil) then
		entry.dirtyFlag = self:getNextDirtyFlag()
		entry.saving = xmlFile:getValue(key .. "#allowSaving", true)
	end
	entry.aiActivePosition = xmlFile:getValue(key .. "#aiActivePosition")
	entry.isDirty = false
	entry.isIntitialDirty = xmlFile:getValue(key .. "#isIntitialDirty", true)
	entry.rotationAxis = xmlFile:getValue(key .. ".rotation#rotationAxis", 1)
	entry.translationAxis = xmlFile:getValue(key .. ".translation#translationAxis", 3)
	local v541_ = xmlFile:getValue(key .. ".rotation#detachingRotMaxLimit")
	local v542_ = xmlFile:getValue(key .. ".rotation#detachingRotMinLimit")
	local v543_ = xmlFile:getValue(key .. ".translation#detachingTransMaxLimit")
	local v544_ = xmlFile:getValue(key .. ".translation#detachingTransMinLimit")
	if v541_ ~= nil or (v542_ ~= nil or (v543_ ~= nil or v544_ ~= nil)) then
		if v518_.detachLockNodes == nil then
			v518_.detachLockNodes = {}
		end
		v518_.detachLockNodes[entry] = {
			["detachingRotMaxLimit"] = v541_,
			["detachingRotMinLimit"] = v542_,
			["detachingTransMinLimit"] = v544_,
			["detachingTransMaxLimit"] = v543_
		}
	end
	entry.hasRequiredConfigurations = true
	local v545_ = xmlFile:getValue(key .. "#requiredConfigurationName")
	if v545_ ~= nil then
		local v546_ = xmlFile:getValue(key .. "#requiredConfigurationIndices", nil, true)
		if v546_ ~= nil then
			entry.hasRequiredConfigurations = false
			for v547_ = 1, #v546_ do
				if self.configurations[v545_] == v546_[v547_] then
					entry.hasRequiredConfigurations = true
					break
				end
			end
		end
	end
	local v548_, v549_, v550_ = getRotation(v519_)
	entry.curRot = { v548_, v549_, v550_ }
	local v551_, v552_, v553_ = getTranslation(v519_)
	entry.curTrans = { v551_, v552_, v553_ }
	entry.startRot = xmlFile:getValue(key .. ".rotation#startRot")
	entry.startTrans = xmlFile:getValue(key .. ".translation#startTrans")
	entry.move = 0
	entry.moveToSend = 0
	entry.smoothedMove = 0
	entry.lastInputTime = 0
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#delayedIndex", key .. "#delayedNode")
	entry.delayedNode = xmlFile:getValue(key .. "#delayedNode", nil, self.components, self.i3dMappings)
	if entry.delayedNode ~= nil then
		entry.delayedFrames = xmlFile:getValue(key .. "#delayedFrames", 3)
		entry.currentDelayedData = {
			["rot"] = { v548_, v549_, v550_ },
			["trans"] = { v551_, v552_, v553_ }
		}
		entry.delayedHistroyData = {}
		for v554_ = 1, entry.delayedFrames do
			entry.delayedHistroyData[v554_] = {
				["rot"] = { v548_, v549_, v550_ },
				["trans"] = { v551_, v552_, v553_ }
			}
		end
		entry.delayedHistoryIndex = 0
	end
	entry.networkInterpolators.translation = InterpolatorValue.new(entry.curTrans[entry.translationAxis])
	entry.networkInterpolators.translation:setMinMax(entry.transMin, entry.transMax)
	entry.networkInterpolators.rotation = InterpolatorAngle.new(entry.curRot[entry.rotationAxis])
	entry.networkInterpolators.rotation:setMinMax(entry.rotMin, entry.rotMax)
	entry.networkTimeInterpolator = InterpolationTime.new(1.2)
	entry.isTool = true
	return true
end

-- Local values: j, refBaseName, node, speedScale, requiresMovement, axis, rotationBasedLimits, found, i, key, keyFrame, minTransLimits, maxTransLimits, minRotLimits, maxRotLimits, dependentTool
function Cylindered:loadDependentMovingTools(xmlFile, baseName, entry)
	entry.dependentMovingTools = {}
	local v559_ = 0
	while true do
		local v560_ = baseName .. string.format(".dependentMovingTool(%d)", v559_)
		if not xmlFile:hasProperty(v560_) then
			break
		end
		XMLUtil.checkDeprecatedXMLElements(xmlFile, v560_ .. "#index", v560_ .. "#index")
		local v561_ = xmlFile:getValue(v560_ .. "#node", nil, self.components, self.i3dMappings)
		local v562_ = xmlFile:getValue(v560_ .. "#speedScale")
		local v563_ = xmlFile:getValue(v560_ .. "#requiresMovement", false)
		local v564_ = xmlFile:getValue(v560_ .. "#axis", 1)
		local v565_ = AnimCurve.new(Cylindered.limitInterpolator)
		local v566_ = 0
		local v567_ = false
		while true do
			local v568_ = string.format("%s.limit(%d)", v560_ .. ".rotationBasedLimits", v566_)
			if not xmlFile:hasProperty(v568_) then
				break
			end
			local v569_ = self:loadRotationBasedLimits(xmlFile, v568_, entry)
			if v569_ ~= nil then
				v565_:addKeyframe(v569_)
				v567_ = true
			end
			v566_ = v566_ + 1
		end
		if not v567_ then
			v565_ = nil
		end
		local v570_ = xmlFile:getValue(v560_ .. "#minTransLimits", nil, true)
		local v571_ = xmlFile:getValue(v560_ .. "#maxTransLimits", nil, true)
		local v572_ = xmlFile:getValue(v560_ .. "#minRotLimits", nil, true)
		local v573_ = xmlFile:getValue(v560_ .. "#maxRotLimits", nil, true)
		if v561_ ~= nil and (v565_ ~= nil or (v562_ ~= nil or (v570_ ~= nil or (v571_ ~= nil or (v572_ ~= nil or v573_ ~= nil))))) then
			local v574_ = entry.dependentMovingTools
			table.insert(v574_, {
				["node"] = v561_,
				["axis"] = v564_,
				["rotation"] = { 0, 0, 0 },
				["rotationBasedLimits"] = v565_,
				["speedScale"] = v562_,
				["requiresMovement"] = v563_,
				["minTransLimits"] = v570_,
				["maxTransLimits"] = v571_,
				["minRotLimits"] = v572_,
				["maxRotLimits"] = v573_
			})
		end
		v559_ = v559_ + 1
	end
end

function Cylindered:loadDependentParts(xmlFile, baseName, entry)
	entry.dependentPartData = {}
	xmlFile:iterate(baseName .. ".dependentPart", function(_, p579_)
		-- upvalues: (copy) xmlFile, (copy) self, (copy) entry
		XMLUtil.checkDeprecatedXMLElements(xmlFile, p579_ .. "#index", p579_ .. "#node")
		local v580_ = {
			["node"] = xmlFile:getValue(p579_ .. "#node", nil, self.components, self.i3dMappings)
		}
		if v580_.node ~= nil then
			v580_.maxUpdateDistance = xmlFile:getValue(p579_ .. "#maxUpdateDistance", "-")
			if v580_.maxUpdateDistance == "-" then
				v580_.maxUpdateDistance = math.huge
			else
				local v581_ = v580_.maxUpdateDistance
				v580_.maxUpdateDistance = tonumber(v581_)
			end
			v580_.part = nil
			local v582_ = entry.dependentPartData
			table.insert(v582_, v580_)
		end
	end)
end

-- Local values: _, dependentPart, j, depPart, j, data
function Cylindered:resolveDependentPartData(dependentPartData, referenceNodes)
	for _, v585_ in pairs(dependentPartData) do
		if v585_.part == nil and referenceNodes[v585_.node] ~= nil then
			for v586_ = 1, #referenceNodes[v585_.node] do
				local v587_ = referenceNodes[v585_.node][v586_]
				if v586_ == 1 then
					v585_.part = v587_
					v587_.isDependentPart = true
				else
					local v588_ = {
						["node"] = v585_.node,
						["maxUpdateDistance"] = v585_.maxUpdateDistance,
						["part"] = v587_
					}
					table.insert(dependentPartData, v588_)
					v587_.isDependentPart = true
				end
			end
		end
	end
	for v589_ = #dependentPartData, 1, -1 do
		if dependentPartData[v589_].part == nil then
			table.remove(dependentPartData, v589_)
		end
	end
end

-- Local values: i, key, index, anchorActor, componentJoint, jointEntry, jointNode, node
function Cylindered:loadDependentComponentJoints(xmlFile, baseName, entry)
	if self.isServer then
		entry.componentJoints = {}
		XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#componentJointIndex", baseName .. ".componentJoint#index")
		XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#anchorActor", baseName .. ".componentJoint#anchorActor")
		local v594_ = 0
		while true do
			local v595_ = baseName .. string.format(".componentJoint(%d)", v594_)
			if not xmlFile:hasProperty(v595_) then
				break
			end
			local v596_ = xmlFile:getValue(v595_ .. "#index")
			if v596_ == nil or self.componentJoints[v596_] == nil then
				if not xmlFile:getValue(v595_ .. "#ignoreWarning") then
					Logging.xmlWarning(xmlFile, "Invalid index for \'%s\'", v595_)
				end
			else
				local v597_ = xmlFile:getValue(v595_ .. "#anchorActor", 0)
				local v598_ = self.componentJoints[v596_]
				local v599_ = {
					["componentJoint"] = v598_,
					["anchorActor"] = v597_,
					["index"] = v596_
				}
				local v600_ = v598_.jointNode
				if v599_.anchorActor == 1 then
					v600_ = v598_.jointNodeActor1
				end
				local v601_ = self.components[v598_.componentIndices[2]].node
				local v602_, v603_, v604_ = localToLocal(v601_, v600_, 0, 0, 0)
				v599_.x = v602_
				v599_.y = v603_
				v599_.z = v604_
				local v605_, v606_, v607_ = localDirectionToLocal(v601_, v600_, 0, 1, 0)
				v599_.upX = v605_
				v599_.upY = v606_
				v599_.upZ = v607_
				local v608_, v609_, v610_ = localDirectionToLocal(v601_, v600_, 0, 0, 1)
				v599_.dirX = v608_
				v599_.dirY = v609_
				v599_.dirZ = v610_
				local v611_ = entry.componentJoints
				table.insert(v611_, v599_)
			end
			v594_ = v594_ + 1
		end
	end
end

-- Local values: indices, ignoreWarning, availableAttacherJoints, i
function Cylindered:loadDependentAttacherJoints(xmlFile, baseName, entry)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#jointIndices", baseName .. ".attacherJoint#jointIndices")
	local v616_ = xmlFile:getValue(baseName .. ".attacherJoint#jointIndices", nil, true)
	if v616_ ~= nil then
		local v617_ = xmlFile:getValue(baseName .. ".attacherJoint#ignoreWarning", false)
		entry.attacherJoints = {}
		local v618_
		if self.getAttacherJoints == nil then
			v618_ = nil
		else
			v618_ = self:getAttacherJoints()
		end
		if v618_ ~= nil then
			for v619_ = 1, #v616_ do
				if v618_[v616_[v619_]] == nil then
					if not v617_ then
						Logging.xmlWarning(xmlFile, "Invalid attacher joint index \'%s\' for \'%s\'!", v616_[v619_], baseName)
					end
				else
					local v620_ = entry.attacherJoints
					local v621_ = v618_[v616_[v619_]]
					table.insert(v620_, v621_)
				end
			end
		end
	end
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#inputAttacherJoint", baseName .. ".inputAttacherJoint#value")
	entry.inputAttacherJoint = xmlFile:getValue(baseName .. ".inputAttacherJoint#value", false)
end

-- Local values: indices, _, wheelIndex, wheel, wheelNodesStr, wheelNodes, i, wheel
function Cylindered:loadDependentWheels(xmlFile, baseName, entry)
	if SpecializationUtil.hasSpecialization(Wheels, self.specializations) then
		local v626_ = xmlFile:getValue(baseName .. "#wheelIndices", nil, true)
		if v626_ ~= nil then
			entry.wheels = {}
			for _, v627_ in pairs(v626_) do
				local v628_ = self:getWheelFromWheelIndex(v627_)
				if v628_ == nil then
					Logging.xmlWarning(xmlFile, "Invalid wheelIndex \'%s\' for \'%s\'!", v627_, baseName)
				else
					local v629_ = entry.wheels
					table.insert(v629_, v628_)
				end
			end
		end
		local v630_ = xmlFile:getValue(baseName .. "#wheelNodes")
		if v630_ ~= nil and v630_ ~= "" then
			entry.wheels = entry.wheels or {}
			local v631_ = string.split(v630_, " ")
			for v632_ = 1, #v631_ do
				local v633_ = self:getWheelByWheelNode(v631_[v632_])
				if v633_ == nil then
					Logging.xmlWarning(xmlFile, "Invalid wheelNode \'%s\' for \'%s\'!", v631_[v632_], baseName)
				else
					local v634_ = entry.wheels
					table.insert(v634_, v633_)
				end
			end
		end
	end
end

-- Local values: j, refBaseName, node, transEntry, x, y, z, _, refZ, i, referencePoint
function Cylindered:loadDependentTranslatingParts(xmlFile, baseName, entry)
	entry.translatingParts = {}
	if entry.hasReferencePoints then
		entry.divideTranslatingDistance = xmlFile:getValue(baseName .. "#divideTranslatingDistance", true)
		entry.translatingPartsDivider = 0
		local v639_ = 0
		while true do
			local v640_ = baseName .. string.format(".translatingPart(%d)", v639_)
			if not xmlFile:hasProperty(v640_) then
				break
			end
			XMLUtil.checkDeprecatedXMLElements(xmlFile, v640_ .. "#index", v640_ .. "#node")
			local v641_ = xmlFile:getValue(v640_ .. "#node", nil, self.components, self.i3dMappings)
			if v641_ ~= nil then
				local v642_ = {
					["node"] = v641_
				}
				local v643_, v644_, v645_ = getTranslation(v641_)
				v642_.startPos = { v643_, v644_, v645_ }
				v642_.lastZ = v645_
				local v646_
				if entry.referencePoint == nil then
					local v647_ = 0
					for _, v648_ in ipairs(entry.referencePoints) do
						local _, _, v649_ = worldToLocal(v641_, getWorldTranslation(v648_))
						v647_ = v647_ + v649_
					end
					v646_ = v647_ / entry.numReferencePoints
				else
					local v650_, v651_
					v650_, v651_, v646_ = worldToLocal(v641_, getWorldTranslation(entry.referencePoint))
				end
				v642_.referenceDistance = xmlFile:getValue(v640_ .. "#referenceDistance", v646_)
				v642_.minZTrans = xmlFile:getValue(v640_ .. "#minZTrans")
				v642_.maxZTrans = xmlFile:getValue(v640_ .. "#maxZTrans")
				v642_.divideTranslatingDistance = xmlFile:getValue(v640_ .. "#divideTranslatingDistance", entry.divideTranslatingDistance)
				if v642_.divideTranslatingDistance then
					entry.translatingPartsDivider = entry.translatingPartsDivider + 1
				end
				local v652_ = entry.translatingParts
				table.insert(v652_, v642_)
			end
			v639_ = v639_ + 1
		end
		local v653_ = entry.translatingPartsDivider
		entry.translatingPartsDivider = math.max(v653_, 1)
		entry.numTranslatingParts = #entry.translatingParts
	end
end

function Cylindered:loadExtraDependentParts(xmlFile, baseName, entry)
	return true
end

-- Local values: i, baseKey, animationName, dependentAnimation, useTranslatingPartIndex
function Cylindered:loadDependentAnimations(xmlFile, baseName, entry)
	entry.dependentAnimations = {}
	local v657_ = 0
	while true do
		local v658_ = string.format("%s.dependentAnimation(%d)", baseName, v657_)
		if not xmlFile:hasProperty(v658_) then
			break
		end
		local v659_ = xmlFile:getValue(v658_ .. "#name")
		if v659_ ~= nil then
			local v660_ = {
				["name"] = v659_,
				["lastPos"] = 0,
				["translationAxis"] = xmlFile:getValue(v658_ .. "#translationAxis"),
				["rotationAxis"] = xmlFile:getValue(v658_ .. "#rotationAxis"),
				["node"] = entry.node
			}
			local v661_ = xmlFile:getValue(v658_ .. "#useTranslatingPartIndex")
			if v661_ ~= nil and entry.translatingParts[v661_] ~= nil then
				v660_.node = entry.translatingParts[v661_].node
			end
			v660_.minValue = xmlFile:getValue(v658_ .. "#minValue")
			v660_.maxValue = xmlFile:getValue(v658_ .. "#maxValue")
			if v660_.rotationAxis ~= nil then
				v660_.minValue = MathUtil.degToRad(v660_.minValue)
				v660_.maxValue = MathUtil.degToRad(v660_.maxValue)
			end
			v660_.invert = xmlFile:getValue(v658_ .. "#invert", false)
			local v662_ = entry.dependentAnimations
			table.insert(v662_, v660_)
		end
		v657_ = v657_ + 1
	end
end

-- Local values: _, copyLocalDirectionPartKey, node, copyLocalDirectionPart
function Cylindered:loadCopyLocalDirectionParts(xmlFile, baseName, entry)
	entry.copyLocalDirectionParts = {}
	for _, v667_ in xmlFile:iterator(baseName .. ".copyLocalDirectionPart") do
		XMLUtil.checkDeprecatedXMLElements(xmlFile, v667_ .. "#index", v667_ .. "#node")
		local v668_ = xmlFile:getValue(v667_ .. "#node", nil, self.components, self.i3dMappings)
		if v668_ ~= nil then
			local v669_ = {
				["node"] = v668_,
				["dirScale"] = xmlFile:getValue(v667_ .. "#dirScale", nil, true),
				["upScale"] = xmlFile:getValue(v667_ .. "#upScale", nil, true)
			}
			if v669_.dirScale == nil then
				Logging.xmlWarning(xmlFile, "Missing values for \'%s\'", v667_ .. "#dirScale")
			elseif v669_.upScale == nil then
				Logging.xmlWarning(xmlFile, "Missing values for \'%s\'", v667_ .. "#upScale")
			else
				self:loadDependentComponentJoints(xmlFile, v667_, v669_)
				local v670_ = entry.copyLocalDirectionParts
				table.insert(v670_, v669_)
			end
		end
	end
end

-- Local values: rotation, rotMin, rotMax, transMin, transMax, time
function Cylindered:loadRotationBasedLimits(xmlFile, key, tool)
	local v674_ = xmlFile:getValue(key .. "#rotation")
	local v675_ = xmlFile:getValue(key .. "#rotMin")
	local v676_ = xmlFile:getValue(key .. "#rotMax")
	local v677_ = xmlFile:getValue(key .. "#transMin")
	local v678_ = xmlFile:getValue(key .. "#transMax")
	if v674_ == nil or v675_ == nil and (v676_ == nil and (v677_ == nil and v678_ == nil)) then
		return nil
	end
	if tool.rotMin ~= nil and tool.rotMax ~= nil then
		v674_ = (v674_ - tool.rotMin) / (tool.rotMax - tool.rotMin)
	end
	return {
		["rotMin"] = v675_,
		["rotMax"] = v676_,
		["transMin"] = v677_,
		["transMax"] = v678_,
		["time"] = v674_
	}
end

-- Local values: spec, i, actionKey, baseKey, sample, actionNamesStr, actionNames, nodesStr, nodes, l, j, actionName, action, l, node, part
function Cylindered:loadActionSoundsFromXML(xmlFile, key)
	local v682_ = self.spec_cylindered
	local v683_ = 0
	while true do
		local v684_ = string.format("actionSound(%d)", v683_)
		local v685_ = key .. "." .. v684_
		if not xmlFile:hasProperty(v685_) then
			break
		end
		local v686_ = g_soundManager:loadSampleFromXML(xmlFile, key, v684_, self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		if v686_ ~= nil then
			local v687_ = xmlFile:getValue(v685_ .. "#actionNames")
			local v688_ = string.split(v687_:trim(), " ")
			local v689_ = xmlFile:getValue(v685_ .. "#nodes")
			local v690_ = string.split(v689_, " ")
			for v691_ = 1, #v690_ do
				v690_[v691_] = I3DUtil.indexToObject(self.components, v690_[v691_], self.i3dMappings)
			end
			for v692_ = 1, #v688_ do
				local v693_ = v688_[v692_]
				local v694_ = "SOUND_ACTION_" .. string.upper(v693_)
				local v695_ = Cylindered[v694_]
				if v695_ == nil then
					Logging.xmlWarning(xmlFile, "Unable to find sound action \'%s\' for sound \'%s\'", v694_, v685_)
				else
					for v696_ = 1, #v690_ do
						local v697_ = v690_[v696_]
						if v697_ ~= nil then
							if v682_.nodesToSamples[v697_] == nil then
								v682_.nodesToSamples[v697_] = {}
							end
							if v682_.nodesToSamples[v697_][v695_] == nil then
								v682_.nodesToSamples[v697_][v695_] = {}
							end
							local v698_ = self:getMovingPartByNode(v697_) or (self:getTranslatingPartByNode(v697_) or self:getMovingToolByNode(v697_))
							if v698_ == nil then
								Logging.xmlWarning(xmlFile, "Unable to find movingPart or translatingPart for node \'%s\' in %s", getName(v697_), v685_)
							else
								v698_.samplesByAction = v682_.nodesToSamples[v697_]
							end
							local v699_ = v682_.nodesToSamples[v697_][v695_]
							table.insert(v699_, v686_)
						end
					end
				end
			end
			v686_.dropOffFactor = xmlFile:getValue(v685_ .. ".pitch#dropOffFactor", 1)
			v686_.dropOffTime = xmlFile:getValue(v685_ .. ".pitch#dropOffTime", 0) * 1000
			v686_.actionNames = v688_
			v686_.nodes = v690_
			local v700_ = v682_.actionSamples
			table.insert(v700_, v686_)
		end
		v683_ = v683_ + 1
	end
end

function Cylindered:checkMovingPartDirtyUpdateNode(node, movingPart) end

-- Local values: spec, tool, oldTrans, newTrans, diff, oldRot, newRot, diff
function Cylindered:setMovingToolDirty(node, forceUpdate, dt)
	local v705_ = self.spec_cylindered.nodesToMovingTools[node]
	if v705_ ~= nil then
		if v705_.transSpeed ~= nil then
			local v706_ = v705_.curTrans[v705_.translationAxis]
			local v707_ = v705_.curTrans
			local v708_ = v705_.curTrans
			local v709_ = v705_.curTrans
			local v710_, v711_, v712_ = getTranslation(v705_.node)
			v707_[1] = v710_
			v708_[2] = v711_
			v709_[3] = v712_
			local v713_ = v705_.curTrans[v705_.translationAxis]
			local v714_ = v713_ - v706_
			if math.abs(v714_) > 0.0001 then
				local v715_ = v714_ > 0
				local v716_ = v713_ - (v705_.transMax or math.huge)
				local v717_
				if math.abs(v716_) < 0.0001 then
					v717_ = true
				else
					local v718_ = v713_ - (v705_.transMin or math.huge)
					v717_ = math.abs(v718_) < 0.0001
				end
				local v719_ = v706_ - (v705_.transMax or math.huge)
				local v720_
				if math.abs(v719_) < 0.0001 then
					v720_ = true
				else
					local v721_ = v706_ - (v705_.transMin or math.huge)
					v720_ = math.abs(v721_) < 0.0001
				end
				self:updateMovingToolSoundEvents(v705_, v715_, v717_, v720_)
			end
		end
		if v705_.rotSpeed ~= nil then
			local v722_ = v705_.curRot[v705_.rotationAxis]
			local v723_ = v705_.curRot
			local v724_ = v705_.curRot
			local v725_ = v705_.curRot
			local v726_, v727_, v728_ = getRotation(v705_.node)
			v723_[1] = v726_
			v724_[2] = v727_
			v725_[3] = v728_
			local v729_ = v705_.curRot[v705_.rotationAxis]
			local v730_ = v729_ - v722_
			if math.abs(v730_) > 0.0001 then
				local v731_ = v730_ > 0
				local v732_ = v729_ - (v705_.rotMax or math.huge)
				local v733_
				if math.abs(v732_) < 0.0001 then
					v733_ = true
				else
					local v734_ = v729_ - (v705_.rotMin or math.huge)
					v733_ = math.abs(v734_) < 0.0001
				end
				local v735_ = v722_ - (v705_.rotMax or math.huge)
				local v736_
				if math.abs(v735_) < 0.0001 then
					v736_ = true
				else
					local v737_ = v722_ - (v705_.rotMin or math.huge)
					v736_ = math.abs(v737_) < 0.0001
				end
				self:updateMovingToolSoundEvents(v705_, v731_, v733_, v736_)
			end
		end
		Cylindered.setDirty(self, v705_)
		if not self.isServer and self.isClient then
			v705_.networkInterpolators.translation:setValue(v705_.curTrans[v705_.translationAxis])
			v705_.networkInterpolators.rotation:setAngle(v705_.curRot[v705_.rotationAxis])
		end
		if forceUpdate or self.finishedFirstUpdate and not self.isActive then
			self:updateDirtyMovingParts(dt or g_currentDt, true)
		end
	end
end

-- Local values: spec, movingPart, dx, dy, dz, refX, refY, refZ, _, _, data
function Cylindered:setMovingPartReferenceNode(movingPartNode, referenceNode, isActiveDirty)
	local v742_ = self.spec_cylindered
	local v743_ = self:getMovingPartByNode(movingPartNode)
	if v743_ ~= nil then
		if v743_.referencePointOrig == nil then
			v743_.referencePointOrig = v743_.referencePoint
		end
		if referenceNode ~= v743_.referencePoint and v743_.smoothedDirectionScale then
			v743_.smoothedDirectionScaleAlpha = 0
			local v744_, v745_, v746_ = localDirectionToLocal(v743_.node, getParent(v743_.node), 0, 0, 1)
			local v747_ = v743_.initialDirection
			local v748_ = v743_.initialDirection
			local v749_ = v743_.initialDirection
			v747_[1] = v744_
			v748_[2] = v745_
			v749_[3] = v746_
			if v743_.hasReferencePoints and v743_.numTranslatingParts > 0 then
				local v750_, v751_, v752_ = getWorldTranslation(v743_.referencePoint)
				local _, _, v753_ = worldToLocal(v743_.node, v750_, v751_, v752_)
				v743_.smoothedDirectionScaleZOffset = v753_
			end
			if not v743_.isActiveDirty then
				table.addElement(v742_.activeDirtyMovingParts, v743_)
				v743_.smoothedDirectionScaleTempDirty = true
			end
		end
		if referenceNode == nil then
			v743_.referencePoint = v743_.referencePointOrig
		else
			v743_.referencePoint = referenceNode
		end
		if isActiveDirty ~= nil and not v743_.smoothedDirectionScaleTempDirty then
			if isActiveDirty then
				table.addElement(v742_.activeDirtyMovingParts, v743_)
			elseif not v743_.isActiveDirty then
				table.removeElement(v742_.activeDirtyMovingParts, v743_)
			end
		end
		Cylindered.updateMovingPart(self, v743_, false, true, true)
		self:updateExtraDependentParts(v743_, 99999)
		self:updateDependentAnimations(v743_, 99999)
		for _, v754_ in pairs(v743_.dependentPartData) do
			if (v754_.node.referencePointOrig or v754_.node.referencePoint) == v743_.referencePointOrig then
				self:setMovingPartReferenceNode(v754_.node.node, referenceNode, isActiveDirty)
			end
		end
	end
end

-- Local values: movingPart
function Cylindered:updateMovingPartByNode(movingPartNode, dt)
	local v758_ = self.spec_cylindered.nodesToMovingParts[movingPartNode]
	if v758_ ~= nil then
		Cylindered.updateMovingPart(self, v758_, false, true, true)
		self:updateExtraDependentParts(v758_, dt)
		self:updateDependentAnimations(v758_, dt)
	end
end

-- Local values: spec, _, part, _, tool, _, part, isActive
function Cylindered:updateCylinderedInitial(placeComponents, keepDirty)
	local v762_ = placeComponents == nil and true or placeComponents
	if keepDirty == nil then
		keepDirty = false
	end
	local v763_ = self.spec_cylindered
	for _, v764_ in pairs(v763_.activeDirtyMovingParts) do
		Cylindered.setDirty(self, v764_)
	end
	for _, v765_ in ipairs(v763_.movingTools) do
		if v765_.isDirty then
			Cylindered.updateWheels(self, v765_)
			if self.isServer then
				Cylindered.updateComponentJoints(self, v765_, v762_)
			end
			v765_.isDirty = keepDirty
		end
		self:updateExtraDependentParts(v765_, 9999)
		self:updateDependentAnimations(v765_, 9999)
	end
	for _, v766_ in ipairs(v763_.movingParts) do
		local v767_ = self:getIsMovingPartActive(v766_)
		if v767_ or v766_.smoothedDirectionScale and v766_.smoothedDirectionScaleAlpha ~= 0 then
			if v766_.isDirty then
				Cylindered.updateMovingPart(self, v766_, v762_, nil, v767_, false)
				Cylindered.updateWheels(self, v766_)
				v766_.isDirty = keepDirty
			end
			self:updateExtraDependentParts(v766_, 9999)
			self:updateDependentAnimations(v766_, 9999)
		end
	end
end

function Cylindered:allowLoadMovingToolStates(superFunc)
	return true
end

function Cylindered:getMovingToolByNode(node)
	return self.spec_cylindered.nodesToMovingTools[node]
end

function Cylindered:getMovingPartByNode(node)
	return self.spec_cylindered.nodesToMovingParts[node]
end

-- Local values: spec, i, part, j
function Cylindered:getTranslatingPartByNode(node)
	local v774_ = self.spec_cylindered
	for v775_ = 1, #v774_.movingParts do
		local v776_ = v774_.movingParts[v775_]
		if v776_.translatingParts ~= nil then
			for v777_ = 1, v776_.numTranslatingParts do
				if v776_.translatingParts[v777_].node == node then
					return v776_.translatingParts[v777_]
				end
			end
		end
	end
	return nil
end

function Cylindered:getIsMovingToolActive(movingTool)
	local v779_ = movingTool.isActive
	if v779_ then
		v779_ = movingTool.hasRequiredConfigurations
	end
	return v779_
end

function Cylindered:getIsMovingPartActive(movingPart)
	return movingPart.isActive
end

function Cylindered:getMovingToolMoveValue(movingTool)
	return movingTool.move + movingTool.externalMove
end

-- Local values: spec, entry, data, node, rot, trans
function Cylindered:isDetachAllowed(superFunc)
	local v784_ = self.spec_cylindered
	if v784_.detachLockNodes ~= nil then
		for v785_, v786_ in pairs(v784_.detachLockNodes) do
			local v787_ = v785_.node
			local v788_ = select(v785_.rotationAxis, getRotation(v787_))
			if v786_.detachingRotMinLimit ~= nil and v788_ < v786_.detachingRotMinLimit then
				return false, nil
			end
			if v786_.detachingRotMaxLimit ~= nil and v786_.detachingRotMaxLimit < v788_ then
				return false, nil
			end
			local v789_ = select(v785_.translationAxis, getTranslation(v787_))
			if v786_.detachingTransMinLimit ~= nil and v789_ < v786_.detachingTransMinLimit then
				return false, nil
			end
			if v786_.detachingTransMaxLimit ~= nil and v786_.detachingTransMaxLimit < v789_ then
				return false, nil
			end
		end
	end
	return superFunc(self)
end

-- Local values: spec, movingTool
function Cylindered:loadObjectChangeValuesFromXML(superFunc, xmlFile, key, node, object)
	superFunc(self, xmlFile, key, node, object)
	local v796_ = self.spec_cylindered
	if v796_.nodesToMovingTools ~= nil and v796_.nodesToMovingTools[node] ~= nil then
		local v797_ = v796_.nodesToMovingTools[node]
		local v798_ = key .. "#movingToolRotMaxActive"
		local v799_ = v797_.rotMax or 0
		object.movingToolRotMaxActive = xmlFile:getValue(v798_, (math.deg(v799_)))
		local v800_ = key .. "#movingToolRotMaxInactive"
		local v801_ = v797_.rotMax or 0
		object.movingToolRotMaxInactive = xmlFile:getValue(v800_, (math.deg(v801_)))
		local v802_ = key .. "#movingToolRotMinActive"
		local v803_ = v797_.rotMin or 0
		object.movingToolRotMinActive = xmlFile:getValue(v802_, (math.deg(v803_)))
		local v804_ = key .. "#movingToolRotMinInactive"
		local v805_ = v797_.rotMin or 0
		object.movingToolRotMinInactive = xmlFile:getValue(v804_, (math.deg(v805_)))
		object.movingToolStartRotActive = xmlFile:getValue(key .. "#movingToolStartRotActive")
		object.movingToolStartRotInactive = xmlFile:getValue(key .. "#movingToolStartRotInactive")
		object.movingToolTransMaxActive = xmlFile:getValue(key .. "#movingToolTransMaxActive", v797_.transMax)
		object.movingToolTransMaxInactive = xmlFile:getValue(key .. "#movingToolTransMaxInactive", v797_.transMax)
		object.movingToolTransMinActive = xmlFile:getValue(key .. "#movingToolTransMinActive", v797_.transMin)
		object.movingToolTransMinInactive = xmlFile:getValue(key .. "#movingToolTransMinInactive", v797_.transMin)
		object.movingToolStartTransActive = xmlFile:getValue(key .. "#movingToolStartTransActive")
		object.movingToolStartTransInactive = xmlFile:getValue(key .. "#movingToolStartTransInactive")
	end
	ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "movingPartUpdate", nil, function(p806_)
		-- upvalues: (copy) self, (copy) node
		if self.getMovingPartByNode ~= nil then
			local v807_ = self:getMovingPartByNode(node)
			if v807_ ~= nil then
				v807_.isActive = p806_
			end
		end
	end, false)
end

-- Local values: spec, movingTool
function Cylindered:setObjectChangeValues(superFunc, object, isActive)
	superFunc(self, object, isActive)
	local v812_ = self.spec_cylindered
	if v812_.nodesToMovingTools ~= nil and v812_.nodesToMovingTools[object.node] ~= nil then
		local v813_ = v812_.nodesToMovingTools[object.node]
		if isActive then
			v813_.rotMax = object.movingToolRotMaxActive
			v813_.rotMin = object.movingToolRotMinActive
			v813_.transMax = object.movingToolTransMaxActive
			v813_.transMin = object.movingToolTransMinActive
			v813_.startRot = object.movingToolStartRotActive or v813_.startRot
			v813_.startTrans = object.movingToolStartTransActive or v813_.startTrans
			return
		end
		v813_.rotMax = object.movingToolRotMaxInactive
		v813_.rotMin = object.movingToolRotMinInactive
		v813_.transMax = object.movingToolTransMaxInactive
		v813_.transMin = object.movingToolTransMinInactive
		v813_.startRot = object.movingToolStartRotInactive or v813_.startRot
		v813_.startTrans = object.movingToolStartTransInactive or v813_.startTrans
	end
end

-- Local values: baseKey
function Cylindered:loadDischargeNode(superFunc, xmlFile, key, entry)
	if not superFunc(self, xmlFile, key, entry) then
		return false
	end
	local v819_ = key .. ".movingToolActivation"
	if xmlFile:hasProperty(v819_) then
		entry.movingToolActivation = {}
		entry.movingToolActivation.node = xmlFile:getValue(v819_ .. "#node", nil, self.components, self.i3dMappings)
		entry.movingToolActivation.isInverted = xmlFile:getValue(v819_ .. "#isInverted", false)
		entry.movingToolActivation.openFactor = xmlFile:getValue(v819_ .. "#openFactor", 1)
		entry.movingToolActivation.openOffset = xmlFile:getValue(v819_ .. "#openOffset", 0)
		entry.movingToolActivation.openOffsetInv = 1 - entry.movingToolActivation.openOffset
	end
	return true
end

-- Local values: spec, movingToolActivation, currentSpeed, movingTool, state, speedFactor
function Cylindered:getDischargeNodeEmptyFactor(superFunc, dischargeNode)
	if dischargeNode.movingToolActivation == nil then
		return superFunc(self, dischargeNode)
	end
	local v823_ = self.spec_cylindered
	local v824_ = dischargeNode.movingToolActivation
	local v825_ = superFunc(self, dischargeNode)
	local v826_ = v823_.nodesToMovingTools[v824_.node]
	local v827_ = Cylindered.getMovingToolState(self, v826_)
	local v828_ = math.clamp(v827_, 0, 1)
	if v824_.isInverted then
		local v829_ = v828_ - 1
		v828_ = math.abs(v829_)
	end
	local v830_ = v828_ - v824_.openOffset
	local v831_ = math.max(v830_, 0) / v824_.openOffsetInv / v824_.openFactor
	return v825_ * math.clamp(v831_, 0, 1)
end

-- Local values: baseKey
function Cylindered:loadShovelNode(superFunc, xmlFile, key, entry)
	if not superFunc(self, xmlFile, key, entry) then
		return false
	end
	local v837_ = key .. ".movingToolActivation"
	if not xmlFile:hasProperty(v837_) then
		return true
	end
	entry.movingToolActivation = {}
	entry.movingToolActivation.node = xmlFile:getValue(v837_ .. "#node", nil, self.components, self.i3dMappings)
	entry.movingToolActivation.isInverted = xmlFile:getValue(v837_ .. "#isInverted", false)
	entry.movingToolActivation.openFactor = xmlFile:getValue(v837_ .. "#openFactor", 1)
	return true
end

-- Local values: isActive, spec, movingToolActivation, movingTool, state
function Cylindered:getShovelNodeIsActive(superFunc, shovelNode)
	local v841_ = superFunc(self, shovelNode)
	if not v841_ or shovelNode.movingToolActivation == nil then
		return v841_
	end
	local v842_ = self.spec_cylindered
	local v843_ = shovelNode.movingToolActivation
	local v844_ = v842_.nodesToMovingTools[v843_.node]
	local v845_ = Cylindered.getMovingToolState(self, v844_)
	if v843_.isInverted then
		local v846_ = v845_ - 1
		v845_ = math.abs(v846_)
	end
	return v843_.openFactor < v845_
end

-- Local values: baseKey
function Cylindered:loadDynamicMountGrabFromXML(superFunc, xmlFile, key, entry)
	if not superFunc(self, xmlFile, key, entry) then
		return false
	end
	local v852_ = key .. ".movingToolActivation"
	if not xmlFile:hasProperty(v852_) then
		return true
	end
	entry.movingToolActivation = {}
	entry.movingToolActivation.node = xmlFile:getValue(v852_ .. "#node", nil, self.components, self.i3dMappings)
	entry.movingToolActivation.isInverted = xmlFile:getValue(v852_ .. "#isInverted", false)
	entry.movingToolActivation.openFactor = xmlFile:getValue(v852_ .. "#openFactor", 1)
	return true
end

-- Local values: isActive, spec, movingToolActivation, movingTool, state
function Cylindered:getIsDynamicMountGrabOpened(superFunc, grab)
	local v856_ = superFunc(self, grab)
	if not v856_ or grab.movingToolActivation == nil then
		return v856_
	end
	local v857_ = self.spec_cylindered
	local v858_ = grab.movingToolActivation
	local v859_ = v857_.nodesToMovingTools[v858_.node]
	local v860_ = Cylindered.getMovingToolState(self, v859_)
	if v858_.isInverted then
		local v861_ = v860_ - 1
		v860_ = math.abs(v861_)
	end
	return v858_.openFactor < v860_
end

-- Local values: spec, _, movingTool, _, componentJoint, componentJointDesc, jointNode, node
function Cylindered:setComponentJointFrame(superFunc, jointDesc, anchorActor)
	superFunc(self, jointDesc, anchorActor)
	local v866_ = self.spec_cylindered
	for _, v867_ in ipairs(v866_.movingTools) do
		for _, v868_ in ipairs(v867_.componentJoints) do
			local v869_ = self.componentJoints[v868_.index]
			local v870_ = v869_.jointNode
			if v868_.anchorActor == 1 then
				v870_ = v869_.jointNodeActor1
			end
			local v871_ = self.components[v869_.componentIndices[2]].node
			local v872_, v873_, v874_ = localToLocal(v871_, v870_, 0, 0, 0)
			v868_.x = v872_
			v868_.y = v873_
			v868_.z = v874_
			local v875_, v876_, v877_ = localDirectionToLocal(v871_, v870_, 0, 1, 0)
			v868_.upX = v875_
			v868_.upY = v876_
			v868_.upZ = v877_
			local v878_, v879_, v880_ = localDirectionToLocal(v871_, v870_, 0, 0, 1)
			v868_.dirX = v878_
			v868_.dirY = v879_
			v868_.dirZ = v880_
		end
	end
end

-- Local values: t, spec
function Cylindered:getAdditionalSchemaText(superFunc)
	local v883_ = superFunc(self)
	if self.isClient and self:getIsActiveForInput(true) then
		local v884_ = self.spec_cylindered
		if #v884_.controlGroupNames > 1 and v884_.currentControlGroupIndex ~= 0 then
			local v885_ = v884_.currentControlGroupIndex
			v883_ = tostring(v885_)
		end
	end
	return v883_
end

-- Local values: spec, multiplier
function Cylindered:getWearMultiplier(superFunc)
	local v888_ = self.spec_cylindered
	local v889_ = superFunc(self)
	if v888_.isHydraulicSamplePlaying then
		v889_ = v889_ + self:getWorkWearMultiplier()
	end
	return v889_
end

function Cylindered:getDoConsumePtoPower(superFunc)
	return superFunc(self) or self.spec_cylindered.powerConsumingTimer > 0
end

-- Local values: value, count, spec, loadPercentage
function Cylindered:getConsumingLoad(superFunc)
	local v894_, v895_ = superFunc(self)
	local v896_ = self.spec_cylindered
	local v897_ = v896_.powerConsumingTimer / v896_.powerConsumingActiveTimeOffset
	return v894_ + math.max(v897_, 0), v895_ + 1
end

-- Local values: spec, i, movingTool, isSelectedGroup, easyArmControlActive, canBeControlled, _, actionEventId
function Cylindered:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v900_ = self.spec_cylindered
		self:clearActionEventsTable(v900_.actionEvents)
		if isActiveForInputIgnoreSelection then
			for v901_ = 1, #v900_.movingTools do
				local v902_ = v900_.movingTools[v901_]
				local v903_ = v902_.controlGroupIndex == 0 and true or v902_.controlGroupIndex == v900_.currentControlGroupIndex
				local v904_ = g_gameSettings:getValue(GameSettings.SETTING.EASY_ARM_CONTROL)
				local v905_ = not (v904_ and v902_.easyArmControlActive or v904_)
				if v905_ then
					v905_ = not v902_.isEasyControlTarget
				end
				if v902_.axisActionIndex ~= nil and (v903_ and v905_) then
					local _, v906_ = self:addPoweredActionEvent(v900_.actionEvents, v902_.axisActionIndex, self, Cylindered.actionEventInput, true, false, true, true, v901_, v902_.axisActionIcon)
					g_inputBinding:setActionEventTextPriority(v906_, GS_PRIO_NORMAL)
				end
			end
		end
	end
end

-- Local values: spec, _, tool, changed, trans, changedTrans, rot, changedRot
function Cylindered:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	local v908_ = self.spec_cylindered
	for _, v909_ in ipairs(v908_.movingTools) do
		local v910_ = false
		if v909_.transSpeed ~= nil then
			local v911_ = v909_.curTrans[v909_.translationAxis]
			local v912_ = false
			if v909_.attachTransMax == nil or v909_.attachTransMax >= v911_ then
				if v909_.attachTransMin ~= nil and v911_ < v909_.attachTransMin then
					v911_ = v909_.attachTransMin
					v912_ = true
				end
			else
				v911_ = v909_.attachTransMax
				v912_ = true
			end
			if v912_ then
				v909_.curTrans[v909_.translationAxis] = v911_
				local v913_ = setTranslation
				local v914_ = v909_.node
				local v915_ = v909_.curTrans
				v913_(v914_, unpack(v915_))
				v910_ = true
			end
		end
		if v909_.rotSpeed ~= nil then
			local v916_ = v909_.curRot[v909_.rotationAxis]
			local v917_ = false
			if v909_.attachRotMax == nil or v909_.attachRotMax >= v916_ then
				if v909_.attachRotMin ~= nil and v916_ < v909_.attachRotMin then
					v916_ = v909_.attachRotMin
					v917_ = true
				end
			else
				v916_ = v909_.attachRotMax
				v917_ = true
			end
			if v917_ then
				v909_.curRot[v909_.rotationAxis] = v916_
				local v918_ = setRotation
				local v919_ = v909_.node
				local v920_ = v909_.curRot
				v918_(v919_, unpack(v920_))
				v910_ = true
			end
		end
		if v910_ then
			Cylindered.setDirty(self, v909_)
		end
	end
end

-- Local values: spec, controlGroupIndex
function Cylindered:onSelect(subSelectionIndex)
	local v923_ = self.spec_cylindered
	local v924_ = v923_.controlGroupMapping[subSelectionIndex]
	if v924_ == nil then
		v923_.currentControlGroupIndex = 0
	else
		v923_.currentControlGroupIndex = v924_
	end
end

-- Local values: spec
function Cylindered:onUnselect()
	self.spec_cylindered.currentControlGroupIndex = 0
end

-- Local values: spec, _, movingTool
function Cylindered:onDeactivate()
	if self.isClient then
		local v927_ = self.spec_cylindered
		g_soundManager:stopSample(v927_.samples.hydraulic)
		v927_.isHydraulicSamplePlaying = false
		for _, v928_ in ipairs(v927_.movingTools) do
			v928_.move = 0
			v928_.externalMove = 0
		end
	end
end

function Cylindered:onAnimationPartChanged(node)
	self:setMovingToolDirty(node)
end

-- Local values: spec, _, movingTool
function Cylindered:onAIImplementStart()
	local v932_ = self.spec_cylindered
	for _, v933_ in ipairs(v932_.movingTools) do
		if v933_.aiActivePosition ~= nil then
			v933_.curTargetPosition = v933_.aiActivePosition
			v933_.curTargetDirection = v933_.curTargetPosition - Cylindered.getMovingToolState(self, v933_)
		end
	end
end

function Cylindered:onVehicleSettingChanged(gameSettingId, state)
	if gameSettingId == GameSettings.SETTING.EASY_ARM_CONTROL then
		self:setIsEasyControlActive(state)
	end
end

function Cylindered:onRegisterAnimationValueTypes()
	self:registerAnimationValueType("movingPartReferencePoint", "", "", false, AnimationValueFloat, function(p938_, p939_, p940_)
		p938_.node = p939_:getValue(p940_ .. "#node", nil, p938_.node.components, p938_.node.i3dMappings)
		p938_.startReferencePoint = p939_:getValue(p940_ .. "#startReferencePoint", nil, p938_.node.components, p938_.node.i3dMappings)
		p938_.endReferencePoint = p939_:getValue(p940_ .. "#endReferencePoint", nil, p938_.node.components, p938_.node.i3dMappings)
		if p938_.node == nil or (p938_.startReferencePoint == nil or p938_.endReferencePoint == nil) then
			return false
		end
		p938_:setWarningInformation("node: " .. getName(p938_.node))
		p938_:addCompareParameters("node")
		p938_.animatedReferencePoint = createTransformGroup("animatedReferencePoint_" .. getName(p938_.node))
		link(getParent(p938_.node), p938_.animatedReferencePoint)
		setWorldTranslation(p938_.animatedReferencePoint, getWorldTranslation(p938_.startReferencePoint))
		p938_.startValue = { 0 }
		p938_.endValue = { 1 }
		return true
	end, function(p941_)
		local v942_ = p941_.startValue or p941_.endValue
		if p941_.animation.currentSpeed < 0 then
			v942_ = p941_.endValue or p941_.startValue
		end
		return v942_[1]
	end, function(p943_, p944_)
		-- upvalues: (copy) self
		if p943_.movingPart == nil then
			p943_.movingPart = self:getMovingPartByNode(p943_.node)
		end
		local v945_, v946_, v947_ = localToLocal(p943_.startReferencePoint, getParent(p943_.node), 0, 0, 0)
		local v948_, v949_, v950_ = localToLocal(p943_.endReferencePoint, getParent(p943_.node), 0, 0, 0)
		local v951_, v952_, v953_ = MathUtil.vector3Lerp(v945_, v946_, v947_, v948_, v949_, v950_, p944_)
		setTranslation(p943_.animatedReferencePoint, v951_, v952_, v953_)
		if p943_.movingPart ~= nil then
			if p944_ == 1 then
				self:setMovingPartReferenceNode(p943_.movingPart, p943_.endReferencePoint)
				return
			end
			if p944_ == 0 then
				self:setMovingPartReferenceNode(p943_.movingPart, p943_.startReferencePoint)
				return
			end
			self:setMovingPartReferenceNode(p943_.movingPart, p943_.animatedReferencePoint)
		end
	end)
end

-- Local values: newTrans, oldTrans, diff
function Cylindered:setToolTranslation(tool, transSpeed, dt, delta)
	local v959_ = tool.curTrans
	local v960_ = tool.curTrans
	local v961_ = tool.curTrans
	local v962_, v963_, v964_ = getTranslation(tool.node)
	v959_[1] = v962_
	v960_[2] = v963_
	v961_[3] = v964_
	local v965_ = tool.curTrans[tool.translationAxis]
	local v966_
	if transSpeed == nil then
		v966_ = v965_ + delta
	else
		v966_ = v965_ + transSpeed * dt
	end
	if tool.transMax ~= nil then
		local v967_ = tool.transMax
		v966_ = math.min(v966_, v967_)
	end
	if tool.transMin ~= nil then
		local v968_ = tool.transMin
		v966_ = math.max(v966_, v968_)
	end
	local v969_ = v966_ - v965_
	if dt ~= 0 then
		tool.lastTransSpeed = v969_ / dt
	end
	if math.abs(v969_) <= 0.0001 then
		return false
	end
	tool.curTrans[tool.translationAxis] = v966_
	setTranslation(tool.node, tool.curTrans[1], tool.curTrans[2], tool.curTrans[3])
	self:updateMovingToolSoundEvents(tool, v969_ > 0, v966_ == tool.transMax and true or v966_ == tool.transMin, v965_ == tool.transMax and true or v965_ == tool.transMin)
	SpecializationUtil.raiseEvent(self, "onMovingToolChanged", tool, transSpeed, dt)
	return true
end

-- Local values: oldTrans
function Cylindered:setAbsoluteToolTranslation(tool, translation)
	local v973_ = tool.curTrans
	local v974_ = tool.curTrans
	local v975_ = tool.curTrans
	local v976_, v977_, v978_ = getTranslation(tool.node)
	v973_[1] = v976_
	v974_[2] = v977_
	v975_[3] = v978_
	local v979_ = tool.curTrans[tool.translationAxis]
	if Cylindered.setToolTranslation(self, tool, nil, 0, translation - v979_) then
		Cylindered.setDirty(self, tool)
		self:raiseDirtyFlags(tool.dirtyFlag)
		self:raiseDirtyFlags(self.spec_cylindered.cylinderedDirtyFlag)
	end
end

-- Local values: newRot, oldRot, diff
function Cylindered:setToolRotation(tool, rotSpeed, dt, delta)
	local v985_ = tool.curRot
	local v986_ = tool.curRot
	local v987_ = tool.curRot
	local v988_, v989_, v990_ = getRotation(tool.node)
	v985_[1] = v988_
	v986_[2] = v989_
	v987_[3] = v990_
	local v991_ = tool.curRot[tool.rotationAxis]
	local v992_
	if rotSpeed == nil then
		v992_ = v991_ + delta
	else
		v992_ = v991_ + rotSpeed * dt
	end
	if tool.rotMax ~= nil then
		local v993_ = tool.rotMax
		v992_ = math.min(v992_, v993_)
	end
	if tool.rotMin ~= nil then
		local v994_ = tool.rotMin
		v992_ = math.max(v992_, v994_)
	end
	local v995_ = v992_ - tool.curRot[tool.rotationAxis]
	if rotSpeed ~= nil and dt ~= 0 then
		tool.lastRotSpeed = v995_ / dt
	end
	if math.abs(v995_) <= 0.0001 then
		return false
	end
	if tool.rotMin == nil and tool.rotMax == nil then
		if v992_ > 6.283185307179586 then
			v992_ = v992_ - 6.283185307179586
		end
		if v992_ < 0 then
			v992_ = v992_ + 6.283185307179586
		end
	end
	tool.curRot[tool.rotationAxis] = v992_
	setRotation(tool.node, tool.curRot[1], tool.curRot[2], tool.curRot[3])
	self:updateMovingToolSoundEvents(tool, v995_ > 0, v992_ == tool.rotMax and true or v992_ == tool.rotMin, v991_ == tool.rotMax and true or v991_ == tool.rotMin)
	SpecializationUtil.raiseEvent(self, "onMovingToolChanged", tool, rotSpeed, dt)
	return true
end

-- Local values: oldRot
function Cylindered:setAbsoluteToolRotation(tool, rotation, updateDelayedNodes)
	local v1000_ = tool.curRot
	local v1001_ = tool.curRot
	local v1002_ = tool.curRot
	local v1003_, v1004_, v1005_ = getRotation(tool.node)
	v1000_[1] = v1003_
	v1001_[2] = v1004_
	v1002_[3] = v1005_
	local v1006_ = tool.curRot[tool.rotationAxis]
	if Cylindered.setToolRotation(self, tool, nil, 0, rotation - v1006_) then
		Cylindered.setDirty(self, tool)
		if updateDelayedNodes ~= nil and updateDelayedNodes then
			self:updateDelayedTool(tool)
		end
		self:raiseDirtyFlags(tool.dirtyFlag)
		self:raiseDirtyFlags(self.spec_cylindered.cylinderedDirtyFlag)
	end
end

-- Local values: curAnimTime, newAnimTime, oldAnimTime, diff
function Cylindered:setToolAnimation(tool, animSpeed, dt)
	local v1011_ = self:getAnimationTime(tool.animName)
	local v1012_ = v1011_ - tool.curAnimTime
	if math.abs(v1012_) > 0.001 then
		tool.networkInterpolators.resetAnimInterpolation = true
	end
	tool.curAnimTime = v1011_
	local v1013_ = tool.curAnimTime + animSpeed * dt
	local v1014_ = tool.curAnimTime
	if tool.animMaxTime ~= nil then
		local v1015_ = tool.animMaxTime
		v1013_ = math.min(v1013_, v1015_)
	end
	if tool.animMinTime ~= nil then
		local v1016_ = tool.animMinTime
		v1013_ = math.max(v1013_, v1016_)
	end
	local v1017_ = v1013_ - tool.curAnimTime
	if dt ~= 0 then
		tool.lastAnimSpeed = v1017_ / dt
	end
	if math.abs(v1017_) <= 0.0001 then
		return false
	end
	tool.curAnimTime = v1013_
	self:setAnimationTime(tool.animName, v1013_, nil, true)
	self:updateMovingToolSoundEvents(tool, v1017_ > 0, (v1013_ == tool.animMaxTime or (v1013_ == tool.animMinTime or v1013_ == 0)) and true or v1013_ == 1, (v1014_ == tool.animMaxTime or (v1014_ == tool.animMinTime or v1014_ == 0)) and true or v1014_ == 1)
	SpecializationUtil.raiseEvent(self, "onMovingToolChanged", tool, animSpeed, dt)
	return true
end

-- Local values: state
function Cylindered:getMovingToolState(tool)
	local v1020_ = 0
	if tool.rotMax == nil or tool.rotMin == nil then
		if tool.rotSpeed == nil then
			if tool.transMax == nil or tool.transMin == nil then
				if tool.transSpeed == nil then
					if tool.animName == nil then
						return v1020_
					else
						return self:getAnimationTime(tool.animName)
					end
				else
					return tool.curTrans[tool.translationAxis]
				end
			else
				return (tool.curTrans[tool.translationAxis] - tool.transMin) / (tool.transMax - tool.transMin)
			end
		else
			return tool.curRot[tool.rotationAxis]
		end
	else
		return (tool.curRot[tool.rotationAxis] - tool.rotMin) / (tool.rotMax - tool.rotMin)
	end
end

-- Local values: _, data
function Cylindered:setDirty(part)
	if not part.isDirty or self.spec_cylindered.isLoading then
		part.isDirty = true
		self.anyMovingPartsDirty = true
		if part.delayedNode ~= nil then
			self:setDelayedData(part)
		end
		if part.isTool then
			Cylindered.updateAttacherJoints(self, part)
			Cylindered.updateWheels(self, part)
		end
		for _, v1023_ in pairs(part.dependentPartData) do
			if self.currentUpdateDistance < v1023_.maxUpdateDistance then
				Cylindered.setDirty(self, v1023_.node)
			end
		end
	end
end

-- Local values: _, wheel, _, wheelChock
function Cylindered:updateWheels(part)
	if part.wheels ~= nil then
		for _, v1025_ in pairs(part.wheels) do
			v1025_.physics:updateShapePosition()
			for _, v1026_ in ipairs(v1025_.wheelChocks) do
				v1026_:update()
			end
		end
	end
end

-- Local values: refX, refY, refZ, dirX, dirY, dirZ, changed, applyDirection, x, y, z, i, referencePoint, x, y, z, lx, ly, lz, offset, direction, x, y, z, _, y1, z1, _, y2, z2, a, b, rotOffset, rot, tDirY, tDirZ, ty, tz, x, y, z, _, y, z, _, _, z, _, ly, lz, dz, z1, z2, parentNode, tx, ty, tz, _, _, coz, ox, oy, oz, r1, r2, _, y1, z1, _, y2, z2, _, ly, lz, ix, iy, i2x, i2y, allowUpdate, lRefX, lRefY, lRefZ, currentDistance, side, i, startNode, endNode, _, sy, sz, _, ey, ez, minLength, maxLength, rootX, rootY, rootZ, targetLength, alpha, ty, tz, upX, upY, upZ, x, y, z, lDX, lDY, lDZ, x, y, z, foundPoint, i, startNode, endNode, _, sy, sz, _, ey, ez, _, cy, cz, partLength, hasIntersection, i1y, i1z, i2y, i2z, targetY, targetZ, partLength, startNode, endNode, x, y, z, sx, sy, sz, ex, ey, ez, startDistance, endDistance, alpha, rx, ry, rz, zReferenceOffset, dt, inDirX, inDirY, inDirZ, _, upX, upY, upZ, directionThreshold, lDirX, lDirY, lDirZ, lastDirection, lastUpVector, x, y, z, length, _, nDirX, nDirY, nDirZ, len, x, y, z, ox, oy, oz, _, i, translatingPart, newZ, _, copyLocalDirectionPart, dx, dy, dz, ux, uy, uz, _, dependentTool, _, data, dependentPart, dependentIsActive
function Cylindered:updateMovingPart(part, placeComponents, updateDependentParts, isActive, updateSounds)
	local v1033_ = nil
	local v1034_ = nil
	local v1035_ = nil
	local v1036_ = 0
	local v1037_ = 0
	local v1038_ = 0
	local v1039_ = false
	local v1040_ = false
	if part.hasReferencePoints then
		if part.moveToReferenceFrame then
			local v1041_, v1042_, v1043_ = localToLocal(part.referenceFrame, getParent(part.node), part.referenceFrameOffset[1], part.referenceFrameOffset[2], part.referenceFrameOffset[3])
			setTranslation(part.node, v1041_, v1042_, v1043_)
			v1039_ = true
		end
		if part.referencePoint == nil then
			local v1044_ = 0
			local v1045_ = 0
			local v1046_ = 0
			for _, v1047_ in ipairs(part.referencePoints) do
				local v1048_, v1049_, v1050_ = getWorldTranslation(v1047_)
				v1044_ = v1044_ + v1048_
				v1045_ = v1045_ + v1049_
				v1046_ = v1046_ + v1050_
			end
			v1033_ = v1044_ / part.numReferencePoints
			v1034_ = v1045_ / part.numReferencePoints
			v1035_ = v1046_ / part.numReferencePoints
		else
			v1033_, v1034_, v1035_ = getWorldTranslation(part.referencePoint)
		end
		if part.referenceDistance == 0 then
			if part.useLocalOffset then
				local v1051_, v1052_, v1053_ = worldToLocal(part.node, v1033_, v1034_, v1035_)
				v1036_, v1037_, v1038_ = localDirectionToWorld(part.node, v1051_ - part.localReferencePoint[1], v1052_ - part.localReferencePoint[2], v1053_)
			elseif part.referencePointOffset == nil then
				local v1054_, v1055_, v1056_ = getWorldTranslation(part.node)
				v1036_ = v1033_ - v1054_
				v1037_ = v1034_ - v1055_
				v1038_ = v1035_ - v1056_
			else
				local v1057_ = part.referencePointOffset
				local v1058_ = math.abs(v1057_)
				local v1059_ = part.referencePointOffset
				local v1060_ = math.sign(v1059_)
				local v1061_, v1062_, v1063_ = getWorldTranslation(part.node)
				local _, v1064_, v1065_ = localToLocal(part.node, part.referenceFrame, 0, 0, 0)
				local _, v1066_, v1067_ = localToLocal(part.referencePoint, part.referenceFrame, 0, 0, 0)
				local v1068_ = MathUtil.vector2Length(v1066_ - v1064_, v1067_ - v1065_)
				if v1058_ < v1068_ then
					local v1069_ = v1068_ ^ 2 - v1058_ ^ 2
					local v1070_ = math.sqrt(v1069_)
					local v1071_ = v1058_ / v1070_
					local v1072_ = math.atan(v1071_)
					local v1073_ = MathUtil.getYRotationFromDirection(v1066_ - v1064_, v1067_ - v1065_)
					local v1074_, v1075_ = MathUtil.getDirectionFromYRotation(v1073_ + v1072_ * v1060_)
					local v1076_ = v1064_ + v1074_ * v1070_
					local v1077_ = v1065_ + v1075_ * v1070_
					v1033_, v1034_, v1035_ = localToWorld(part.referenceFrame, 0, v1076_, v1077_)
					v1036_ = v1033_ - v1061_
					v1037_ = v1034_ - v1062_
					v1038_ = v1035_ - v1063_
				end
			end
		else
			if part.updateLocalReferenceDistance then
				local _, v1078_, v1079_ = worldToLocal(part.node, getWorldTranslation(part.localReferencePointNode))
				part.localReferenceDistance = MathUtil.vector2Length(v1078_, v1079_)
			end
			if part.referenceDistancePoint ~= nil then
				local _, _, v1080_ = worldToLocal(part.node, getWorldTranslation(part.referenceDistancePoint))
				part.referenceDistance = v1080_
			end
			if part.localReferenceTranslate then
				local _, v1081_, v1082_ = worldToLocal(part.node, v1033_, v1034_, v1035_)
				if math.abs(v1081_) < part.referenceDistance then
					local v1083_ = part.referenceDistance * part.referenceDistance - v1081_ * v1081_
					local v1084_ = math.sqrt(v1083_)
					local v1085_ = v1082_ - v1084_ - part.localReferenceDistance
					local v1086_ = v1082_ + v1084_ - part.localReferenceDistance
					if math.abs(v1086_) >= math.abs(v1085_) then
						v1086_ = v1085_
					end
					local v1087_ = getParent(part.node)
					local v1088_ = part.localReferenceTranslation
					local v1089_, v1090_, v1091_ = unpack(v1088_)
					local _, _, v1092_ = localToLocal(v1087_, part.node, v1089_, v1090_, v1091_)
					local v1093_, v1094_, v1095_ = localDirectionToLocal(part.node, v1087_, 0, 0, v1086_ - v1092_)
					setTranslation(part.node, v1089_ + v1093_, v1090_ + v1094_, v1091_ + v1095_)
					v1039_ = true
				end
			else
				local v1096_ = part.localReferenceDistance
				local v1097_ = part.referenceDistance
				if part.dynamicLocalReferenceDistance then
					local _, v1098_, v1099_ = worldToLocal(part.node, getWorldTranslation(part.localReferencePointNode))
					local _, v1100_, v1101_ = worldToLocal(part.node, localToWorld(part.localReferencePointNode, 0, 0, part.referenceDistance))
					v1097_ = MathUtil.vector2Length(v1098_ - v1100_, v1099_ - v1101_)
				end
				local _, v1102_, v1103_ = worldToLocal(part.node, v1033_, v1034_, v1035_)
				local v1106_, v1107_, v1106_, v1107_ = MathUtil.getCircleCircleIntersection(0, 0, v1096_, v1102_, v1103_, v1097_)
				local v1108_ = true
				if part.referenceDistanceThreshold > 0 then
					local v1109_, v1110_, v1111_ = getWorldTranslation(part.localReferencePointNode)
					local v1112_ = MathUtil.vector3Length(v1033_ - v1109_, v1034_ - v1110_, v1035_ - v1111_) - part.referenceDistance
					if math.abs(v1112_) < part.referenceDistanceThreshold then
						v1108_ = false
					end
				end
				if v1108_ and v1106_ ~= nil then
					if v1106_ ~= nil then
						local _ = v1106_ * (v1103_ - v1107_) - v1107_ * (v1102_ - v1106_) < 0 == (part.localReferenceAngleSide < 0)
					end
					v1036_, v1037_, v1038_ = localDirectionToWorld(part.node, 0, v1106_, v1107_)
					v1039_ = true
				end
			end
		end
		if part.doInversedLineAlignment then
			if part.doInversedLineAlignmentRoot == nil then
				part.doInversedLineAlignmentRoot = createTransformGroup("inversedLineAlignmentRoot")
				link(getParent(part.node), part.doInversedLineAlignmentRoot, getChildIndex(part.node))
				setTranslation(part.doInversedLineAlignmentRoot, getTranslation(part.node))
				setRotation(part.doInversedLineAlignmentRoot, getRotation(part.node))
				link(part.doInversedLineAlignmentRoot, part.node)
				setTranslation(part.node, 0, 0, 0)
				setRotation(part.node, 0, 0, 0)
			end
			for v1113_ = 1, #part.orientationLineNodes - 1 do
				local v1114_ = part.orientationLineNodes[v1113_]
				local v1115_ = part.orientationLineNodes[v1113_ + 1]
				local _, v1116_, v1117_ = localToLocal(v1114_, part.node, 0, 0, 0)
				local _, v1118_, v1119_ = localToLocal(v1115_, part.node, 0, 0, 0)
				local v1120_ = MathUtil.vector2Length(v1116_, v1117_)
				local v1121_ = MathUtil.vector2Length(v1118_, v1119_)
				local v1122_, v1123_, v1124_ = getWorldTranslation(part.doInversedLineAlignmentRoot)
				local v1125_ = MathUtil.vector3Length(v1033_ - v1122_, v1034_ - v1123_, v1035_ - v1124_)
				if not MathUtil.getIsOutOfBounds(v1125_, v1120_, v1121_) then
					local v1126_ = (v1125_ - v1120_) / (v1121_ - v1120_)
					local v1127_ = MathUtil.lerp(v1116_, v1118_, v1126_)
					local v1128_ = MathUtil.lerp(v1117_, v1119_, v1126_)
					local v1129_, v1130_, v1131_ = localDirectionToWorld(part.referenceFrame, 0, 1, 0)
					local v1132_, v1133_, v1134_ = localDirectionToWorld(part.doInversedLineAlignmentRoot, 0, -v1127_, v1128_)
					I3DUtil.setWorldDirection(part.node, v1132_, v1133_, v1134_, v1129_, v1130_, v1131_, part.limitedAxis, part.minRot, part.maxRot)
					local v1135_, v1136_, v1137_ = getWorldTranslation(part.doInversedLineAlignmentRoot)
					v1036_ = v1033_ - v1135_
					v1037_ = v1034_ - v1136_
					v1038_ = v1035_ - v1137_
					I3DUtil.setWorldDirection(part.doInversedLineAlignmentRoot, v1036_, v1037_, v1038_, v1129_, v1130_, v1131_, part.limitedAxis, part.minRot, part.maxRot)
					v1039_ = true
					break
				end
			end
		end
	else
		if part.alignToWorldY then
			local v1138_, v1139_, v1140_ = localDirectionToWorld(getRootNode(), 0, 1, 0)
			local v1141_, v1142_, v1143_ = worldDirectionToLocal(part.referenceFrame, v1138_, v1139_, v1140_)
			if v1143_ < 0 then
				v1143_ = -v1143_
			end
			v1036_, v1037_, v1038_ = localDirectionToWorld(part.referenceFrame, v1141_, v1142_, v1143_)
			v1039_ = true
		elseif part.doDirectionAlignment then
			v1036_, v1037_, v1038_ = localDirectionToWorld(part.referenceFrame, 0, 0, 1)
			v1039_ = true
		end
		if part.moveToReferenceFrame then
			local v1144_, v1145_, v1146_ = localToLocal(part.referenceFrame, getParent(part.node), part.referenceFrameOffset[1], part.referenceFrameOffset[2], part.referenceFrameOffset[3])
			setTranslation(part.node, v1144_, v1145_, v1146_)
			v1039_ = true
		end
		if part.doLineAlignment then
			local v1147_ = false
			for v1148_ = 1, #part.orientationLineNodes - 1 do
				local v1149_ = part.orientationLineNodes[v1148_]
				local v1150_ = part.orientationLineNodes[v1148_ + 1]
				local _, v1151_, v1152_ = localToLocal(v1149_, part.referenceFrame, 0, 0, 0)
				local _, v1153_, v1154_ = localToLocal(v1150_, part.referenceFrame, 0, 0, 0)
				local _, v1155_, v1156_ = localToLocal(part.node, part.referenceFrame, 0, 0, 0)
				local v1157_ = part.nodeLength
				if part.nodeLengthNode ~= nil then
					v1157_ = calcDistanceFrom(part.node, part.nodeLengthNode)
				end
				local v1158_, v1161_, v1162_, v1161_, v1162_ = MathUtil.getCircleLineIntersection(v1155_, v1156_, v1157_, v1151_, v1152_, v1153_, v1154_)
				if v1158_ then
					local v1163_ = nil
					local v1164_ = nil
					if v1161_ == nil or v1162_ == nil then
						if v1161_ == nil or v1162_ == nil then
							v1161_ = v1163_
							v1162_ = v1164_
						else
							v1147_ = true
						end
					else
						v1147_ = true
					end
					if v1147_ and not (MathUtil.isNan(v1161_) or MathUtil.isNan(v1162_)) then
						v1036_, v1037_, v1038_ = localDirectionToWorld(part.referenceFrame, 0, v1161_, v1162_)
						v1039_ = true
						v1040_ = true
						break
					end
				end
			end
		end
		if part.do3DLineAlignment then
			local v1165_ = part.nodeLength
			if part.nodeLengthNode ~= nil then
				v1165_ = calcDistanceFrom(part.node, part.nodeLengthNode)
			end
			local v1166_ = part.orientationLineNodes[1]
			local v1167_ = part.orientationLineNodes[2]
			local v1168_, v1169_, v1170_ = getWorldTranslation(part.node)
			local v1171_, v1172_, v1173_ = getWorldTranslation(v1166_)
			local v1174_, v1175_, v1176_ = getWorldTranslation(v1167_)
			local v1177_ = MathUtil.vector3Length(v1171_ - v1168_, v1172_ - v1169_, v1173_ - v1170_)
			local v1178_ = MathUtil.vector3Length(v1174_ - v1168_, v1175_ - v1169_, v1176_ - v1170_)
			local v1179_ = MathUtil.inverseLerp(v1177_, v1178_, v1165_)
			local v1180_ = math.clamp(v1179_, 0, 1)
			local v1181_, v1182_, v1183_ = MathUtil.vector3Lerp(v1171_, v1172_, v1173_, v1174_, v1175_, v1176_, v1180_)
			v1036_, v1037_, v1038_ = MathUtil.vector3Normalize(v1181_ - v1168_, v1182_ - v1169_, v1183_ - v1170_)
			setWorldTranslation(part.orientationLineTransNode, v1181_, v1182_, v1183_)
			v1040_ = true
		end
	end
	local v1184_ = nil
	if part.smoothedDirectionScale then
		if part.smoothedDirectionScaleAlpha == nil then
			part.smoothedDirectionScaleAlpha = isActive and 1 or 0
		end
		local v1185_ = g_currentDt or 9999
		if isActive then
			local v1186_ = part.smoothedDirectionScaleAlpha + v1185_ * part.smoothedDirectionTime
			part.smoothedDirectionScaleAlpha = math.min(v1186_, 1)
		else
			local v1187_ = part.smoothedDirectionScaleAlpha - v1185_ * part.smoothedDirectionTime
			part.smoothedDirectionScaleAlpha = math.max(v1187_, 0)
		end
		local v1188_ = localDirectionToWorld
		local v1189_ = getParent(part.node)
		local v1190_ = part.initialDirection
		local v1191_, v1192_, v1193_ = v1188_(v1189_, unpack(v1190_))
		v1036_, v1037_, v1038_ = MathUtil.vector3Lerp(v1191_, v1192_, v1193_, v1036_, v1037_, v1038_, part.smoothedDirectionScaleAlpha)
		if part.hasReferencePoints and part.numTranslatingParts > 0 then
			local _, _, v1194_ = worldToLocal(part.node, v1033_, v1034_, v1035_)
			v1184_ = MathUtil.lerp(part.smoothedDirectionScaleZOffset, v1194_, part.smoothedDirectionScaleAlpha)
		end
		if part.smoothedDirectionScaleTempDirty and (part.smoothedDirectionScaleAlpha == 0 or part.smoothedDirectionScaleAlpha == 1) then
			table.removeElement(self.spec_cylindered.activeDirtyMovingParts, part)
			part.smoothedDirectionScaleTempDirty = false
		end
	end
	if (part.doDirectionAlignment or v1040_) and (v1036_ ~= 0 or (v1037_ ~= 0 or v1038_ ~= 0)) then
		local v1195_, v1196_, v1197_ = localDirectionToWorld(part.referenceFrame, 0, 1, 0)
		if part.invertZ then
			v1036_ = -v1036_
			v1037_ = -v1037_
			v1038_ = -v1038_
		end
		local v1198_ = part.directionThresholdActive
		if not self.isActive and (part.directionThreshold ~= nil and part.directionThreshold > 0) then
			v1198_ = part.directionThreshold
		end
		local v1199_, v1200_, v1201_ = worldDirectionToLocal(part.parent, v1036_, v1037_, v1038_)
		local v1202_ = part.lastDirection
		local v1203_ = part.lastUpVector
		local v1204_ = v1202_[1] - v1199_
		if v1198_ >= math.abs(v1204_) then
			local v1205_ = v1202_[2] - v1200_
			if v1198_ >= math.abs(v1205_) then
				local v1206_ = v1202_[3] - v1201_
				if v1198_ >= math.abs(v1206_) then
					local v1207_ = v1203_[1] - v1195_
					if v1198_ >= math.abs(v1207_) then
						local v1208_ = v1203_[2] - v1196_
						if v1198_ < math.abs(v1208_) then
							goto l108
						end
						local v1209_ = v1203_[3] - v1197_
						if v1198_ < math.abs(v1209_) then
							goto l108
						end
						v1039_ = false
						::l119::
						if part.scaleZ and (part.localReferenceDistance ~= nil and part.localReferenceDistance ~= 0) then
							local v1210_ = MathUtil.vector3Length(v1036_, v1037_, v1038_)
							setScale(part.node, 1, 1, v1210_ / part.localReferenceDistance)
							if part.debug then
								DebugGizmo.renderAtNode(part.node, string.format("scale:%.2f", v1210_ / part.localReferenceDistance))
							end
						end
						goto l97
					end
				end
			end
		end
		::l108::
		I3DUtil.setWorldDirection(part.node, v1036_, v1037_, v1038_, v1195_, v1196_, v1197_, part.limitedAxis, part.minRot, part.maxRot)
		if part.debug then
			local v1211_, v1212_, v1213_ = getWorldTranslation(part.node)
			drawDebugPoint(v1211_, v1212_, v1213_, 1, 0, 0, 1, false)
			local v1214_
			if part.hasReferencePoints then
				local v1215_, v1216_
				v1215_, v1216_, v1214_ = worldToLocal(part.node, v1033_, v1034_, v1035_)
			else
				v1214_ = 1
			end
			local v1217_, v1218_, v1219_ = MathUtil.vector3Normalize(v1036_, v1037_, v1038_)
			drawDebugLine(v1211_, v1212_, v1213_, 1, 0, 0, v1211_ + v1217_ * v1214_, v1212_ + v1218_ * v1214_, v1213_ + v1219_ * v1214_, 0, 1, 0, true)
			if part.referencePoint ~= nil then
				local v1220_, v1221_, v1222_ = getWorldTranslation(part.referencePoint)
				drawDebugPoint(v1220_, v1221_, v1222_, 0, 1, 0, 1, false)
				drawDebugPoint(v1033_, v1034_, v1035_, 0, 0, 1, 1, false)
			end
		end
		v1202_[1] = v1199_
		v1202_[2] = v1200_
		v1202_[3] = v1201_
		v1203_[1] = v1195_
		v1203_[2] = v1196_
		v1203_[3] = v1197_
		v1039_ = true
		goto l119
	else
		::l97::
		if part.doRotationAlignment then
			local v1223_, v1224_, v1225_ = getRotation(part.referenceFrame)
			local v1226_ = v1223_ * part.rotMultiplier
			local v1227_ = v1224_ * part.rotMultiplier
			local v1228_ = v1225_ * part.rotMultiplier
			local v1229_, v1230_, v1231_ = getRotation(part.node)
			local v1232_ = v1226_ - v1229_
			if math.abs(v1232_) > 0.0001 then
				::l127::
				setRotation(part.node, v1226_, v1227_, v1228_)
				v1039_ = true
				goto l125
			end
			local v1233_ = v1227_ - v1230_
			if math.abs(v1233_) > 0.0001 then
				goto l127
			end
			local v1234_ = v1228_ - v1231_
			if math.abs(v1234_) > 0.0001 then
				goto l127
			end
		end
		::l125::
		if part.hasReferencePoints and part.numTranslatingParts > 0 then
			if v1184_ == nil then
				local v1235_, v1236_
				v1235_, v1236_, v1184_ = worldToLocal(part.node, v1033_, v1034_, v1035_)
			end
			for v1237_ = 1, part.numTranslatingParts do
				local v1238_ = part.translatingParts[v1237_]
				local v1239_ = v1184_ - v1238_.referenceDistance
				if part.translatingPartsDivider ~= 1 and v1238_.divideTranslatingDistance then
					v1239_ = v1239_ / part.translatingPartsDivider
				end
				if v1238_.minZTrans ~= nil then
					local v1240_ = v1238_.minZTrans
					v1239_ = math.max(v1240_, v1239_)
				end
				if v1238_.maxZTrans ~= nil then
					local v1241_ = v1238_.maxZTrans
					v1239_ = math.min(v1241_, v1239_)
				end
				if not v1238_.divideTranslatingDistance then
					v1184_ = v1184_ - (v1239_ - v1238_.startPos[3])
				end
				if part.referenceDistanceThreshold == 0 then
					::l145::
					if updateSounds ~= false and (part.samplesByAction ~= nil or v1238_.samplesByAction ~= nil) and v1239_ ~= v1238_.lastZ then
						local v1242_ = v1238_.lastZ - v1239_
						if math.abs(v1242_) > 0.0001 then
							self:onMovingPartSoundEvent(part, Cylindered.SOUND_ACTION_TRANSLATING_END, Cylindered.SOUND_TYPE_ENDING)
							self:onMovingPartSoundEvent(v1238_, Cylindered.SOUND_ACTION_TRANSLATING_END, Cylindered.SOUND_TYPE_ENDING)
							self:onMovingPartSoundEvent(part, Cylindered.SOUND_ACTION_TRANSLATING_START, Cylindered.SOUND_TYPE_STARTING)
							self:onMovingPartSoundEvent(v1238_, Cylindered.SOUND_ACTION_TRANSLATING_START, Cylindered.SOUND_TYPE_STARTING)
							if v1238_.lastZ + 0.0001 < v1239_ then
								self:onMovingPartSoundEvent(part, Cylindered.SOUND_ACTION_TRANSLATING_POS, Cylindered.SOUND_TYPE_CONTINUES)
								self:onMovingPartSoundEvent(v1238_, Cylindered.SOUND_ACTION_TRANSLATING_POS, Cylindered.SOUND_TYPE_CONTINUES)
								self:onMovingPartSoundEvent(part, Cylindered.SOUND_ACTION_TRANSLATING_END_POS, Cylindered.SOUND_TYPE_ENDING)
								self:onMovingPartSoundEvent(v1238_, Cylindered.SOUND_ACTION_TRANSLATING_END_POS, Cylindered.SOUND_TYPE_ENDING)
								self:onMovingPartSoundEvent(part, Cylindered.SOUND_ACTION_TRANSLATING_START_POS, Cylindered.SOUND_TYPE_STARTING)
								self:onMovingPartSoundEvent(v1238_, Cylindered.SOUND_ACTION_TRANSLATING_START_POS, Cylindered.SOUND_TYPE_STARTING)
							elseif v1239_ < v1238_.lastZ - 0.0001 then
								self:onMovingPartSoundEvent(part, Cylindered.SOUND_ACTION_TRANSLATING_NEG, Cylindered.SOUND_TYPE_CONTINUES)
								self:onMovingPartSoundEvent(v1238_, Cylindered.SOUND_ACTION_TRANSLATING_NEG, Cylindered.SOUND_TYPE_CONTINUES)
								self:onMovingPartSoundEvent(part, Cylindered.SOUND_ACTION_TRANSLATING_END_NEG, Cylindered.SOUND_TYPE_ENDING)
								self:onMovingPartSoundEvent(v1238_, Cylindered.SOUND_ACTION_TRANSLATING_END_NEG, Cylindered.SOUND_TYPE_ENDING)
								self:onMovingPartSoundEvent(part, Cylindered.SOUND_ACTION_TRANSLATING_START_NEG, Cylindered.SOUND_TYPE_STARTING)
								self:onMovingPartSoundEvent(v1238_, Cylindered.SOUND_ACTION_TRANSLATING_START_NEG, Cylindered.SOUND_TYPE_STARTING)
							end
						end
					end
					v1238_.lastZ = v1239_
					setTranslation(v1238_.node, v1238_.startPos[1], v1238_.startPos[2], v1239_)
					v1039_ = true
				else
					local v1243_ = v1238_.lastZ - v1239_
					if math.abs(v1243_) > part.referenceDistanceThreshold then
						goto l145
					end
				end
			end
		end
		if v1039_ then
			if part.copyLocalDirectionParts ~= nil then
				for _, v1244_ in pairs(part.copyLocalDirectionParts) do
					local v1245_, v1246_, v1247_ = localDirectionToWorld(part.node, 0, 0, 1)
					local v1248_, v1249_, v1250_ = worldDirectionToLocal(getParent(part.node), v1245_, v1246_, v1247_)
					local v1251_ = v1248_ * v1244_.dirScale[1]
					local v1252_ = v1249_ * v1244_.dirScale[2]
					local v1253_ = v1250_ * v1244_.dirScale[3]
					local v1254_, v1255_, v1256_ = localDirectionToWorld(part.node, 0, 1, 0)
					local v1257_, v1258_, v1259_ = worldDirectionToLocal(getParent(part.node), v1254_, v1255_, v1256_)
					local v1260_ = v1257_ * v1244_.upScale[1]
					local v1261_ = v1258_ * v1244_.upScale[2]
					local v1262_ = v1259_ * v1244_.upScale[3]
					setDirection(v1244_.node, v1251_, v1252_, v1253_, v1260_, v1261_, v1262_)
					if self.isServer then
						Cylindered.updateComponentJoints(self, v1244_, placeComponents)
					end
				end
			end
			if self.isServer then
				Cylindered.updateComponentJoints(self, part, placeComponents)
				Cylindered.updateAttacherJoints(self, part)
				Cylindered.updateWheels(self, part)
			end
			Cylindered.updateWheels(self, part)
			for _, v1263_ in pairs(part.dependentMovingTools) do
				Cylindered.updateRotationBasedLimits(self, part, v1263_)
			end
		end
		if updateDependentParts then
			for _, v1264_ in pairs(part.dependentPartData) do
				if self.currentUpdateDistance < v1264_.maxUpdateDistance then
					local v1265_ = v1264_.node
					local v1266_ = self:getIsMovingPartActive(v1265_)
					if v1266_ or v1265_.smoothedDirectionScale and v1265_.smoothedDirectionScaleAlpha ~= 0 then
						Cylindered.updateMovingPart(self, v1265_, placeComponents, updateDependentParts, v1266_)
					end
				end
			end
		end
		part.isDirty = false
		return
	end
end

-- Local values: _, joint, componentJoint, jointNode, node, x, y, z, upX, upY, upZ, dirX, dirY, dirZ
function Cylindered:updateComponentJoints(entry, placeComponents)
	if self.isServer and entry.componentJoints ~= nil then
		for _, v1270_ in ipairs(entry.componentJoints) do
			local v1271_ = v1270_.componentJoint
			local v1272_ = v1271_.jointNode
			if v1270_.anchorActor == 1 then
				v1272_ = v1271_.jointNodeActor1
			end
			if placeComponents then
				local v1273_ = self.components[v1271_.componentIndices[2]].node
				local v1274_, v1275_, v1276_ = localToWorld(v1272_, v1270_.x, v1270_.y, v1270_.z)
				local v1277_, v1278_, v1279_ = localDirectionToWorld(v1272_, v1270_.upX, v1270_.upY, v1270_.upZ)
				local v1280_, v1281_, v1282_ = localDirectionToWorld(v1272_, v1270_.dirX, v1270_.dirY, v1270_.dirZ)
				setWorldTranslation(v1273_, v1274_, v1275_, v1276_)
				I3DUtil.setWorldDirection(v1273_, v1280_, v1281_, v1282_, v1277_, v1278_, v1279_)
			end
			self:setComponentJointFrame(v1271_, v1270_.anchorActor)
		end
	end
end

-- Local values: _, joint, attacherVehicle, attacherJoints, jointDescIndex, jointDesc, inputAttacherJoint, xNew, yNew, zNew, ox, oy, oz, x, y, z, x1, y1, z1, x2, y2, z2
function Cylindered:updateAttacherJoints(entry)
	if self.isServer then
		if entry.attacherJoints ~= nil then
			for _, v1285_ in ipairs(entry.attacherJoints) do
				if v1285_.jointIndex ~= 0 then
					setJointFrame(v1285_.jointIndex, 0, v1285_.jointTransform)
				end
			end
		end
		if entry.inputAttacherJoint and self.getAttacherVehicle ~= nil then
			local v1286_ = self:getAttacherVehicle()
			if v1286_ ~= nil then
				local v1287_ = v1286_:getAttacherJoints()
				if v1287_ ~= nil then
					local v1288_ = v1286_:getAttacherJointIndexFromObject(self)
					if v1288_ ~= nil then
						local v1289_ = v1287_[v1288_]
						local v1290_ = self:getActiveInputAttacherJoint()
						if v1290_ ~= nil then
							local v1291_ = v1289_.jointOrigTrans[1] + v1289_.jointPositionOffset[1]
							local v1292_ = v1289_.jointOrigTrans[2] + v1289_.jointPositionOffset[2]
							local v1293_ = v1289_.jointOrigTrans[3] + v1289_.jointPositionOffset[3]
							local v1294_, v1295_, v1296_ = getTranslation(v1289_.jointTransform)
							local v1297_ = setTranslation
							local v1298_ = v1289_.jointTransform
							local v1299_ = v1289_.jointOrigTrans
							v1297_(v1298_, unpack(v1299_))
							local v1300_, v1301_, v1302_ = localToWorld(getParent(v1289_.jointTransform), v1291_, v1292_, v1293_)
							local v1303_, v1304_, v1305_ = worldToLocal(v1289_.jointTransform, v1300_, v1301_, v1302_)
							setTranslation(v1289_.jointTransform, v1294_, v1295_, v1296_)
							local v1306_, v1307_, v1308_ = localToWorld(v1290_.node, v1303_, v1304_, v1305_)
							local v1309_, v1310_, v1311_ = worldToLocal(getParent(v1290_.node), v1306_, v1307_, v1308_)
							setTranslation(v1290_.node, v1309_, v1310_, v1311_)
							setJointFrame(v1289_.jointIndex, 1, v1290_.node)
							local v1312_ = setTranslation
							local v1313_ = v1290_.node
							local v1314_ = v1290_.jointOrigTrans
							v1312_(v1313_, unpack(v1314_))
						end
					end
				end
			end
		end
	end
end

-- Local values: oneMinusAlpha, rotMin, rotMax, transMin, transMax
function Cylindered.limitInterpolator(first, second, alpha)
	local v1318_ = 1 - alpha
	local v1319_ = nil
	local v1320_ = nil
	local v1321_ = nil
	local v1322_
	if first.rotMin == nil or second.rotMin == nil then
		v1322_ = nil
	else
		v1322_ = first.rotMin * alpha + second.rotMin * v1318_
	end
	if first.rotMax ~= nil and second.rotMax ~= nil then
		v1319_ = first.rotMax * alpha + second.rotMax * v1318_
	end
	if first.transMin ~= nil and second.transMin ~= nil then
		v1320_ = first.minTrans * alpha + second.transMin * v1318_
	end
	if first.transMax ~= nil and second.transMax ~= nil then
		v1321_ = first.transMax * alpha + second.transMax * v1318_
	end
	return v1322_, v1319_, v1320_, v1321_
end

-- Local values: state, minRot, maxRot, minTrans, maxTrans, isDirty
function Cylindered:updateRotationBasedLimits(tool, dependentTool)
	if dependentTool.rotationBasedLimits ~= nil then
		local v1326_
		if tool.isTool then
			v1326_ = Cylindered.getMovingToolState(self, tool)
		else
			local v1327_ = dependentTool.rotation
			local v1328_ = dependentTool.rotation
			local v1329_ = dependentTool.rotation
			local v1330_, v1331_, v1332_ = getRotation(tool.node)
			v1327_[1] = v1330_
			v1328_[2] = v1331_
			v1329_[3] = v1332_
			v1326_ = dependentTool.rotation[dependentTool.axis]
		end
		local v1333_, v1334_, v1335_, v1336_ = dependentTool.rotationBasedLimits:get(v1326_)
		if v1333_ ~= nil then
			dependentTool.movingTool.rotMin = v1333_
		end
		if v1334_ ~= nil then
			dependentTool.movingTool.rotMax = v1334_
		end
		if v1335_ ~= nil then
			dependentTool.movingTool.transMin = v1335_
		end
		if v1336_ ~= nil then
			dependentTool.movingTool.transMax = v1336_
		end
		if self.isServer then
			local v1337_ = false
			if v1333_ ~= nil or v1334_ ~= nil then
				v1337_ = v1337_ or Cylindered.setToolRotation(self, dependentTool.movingTool, 0, 0)
			end
			if v1335_ ~= nil or v1336_ ~= nil then
				v1337_ = v1337_ or Cylindered.setToolTranslation(self, dependentTool.movingTool, 0, 0)
			end
			if v1337_ then
				Cylindered.setDirty(self, dependentTool.movingTool)
				self:raiseDirtyFlags(dependentTool.movingTool.dirtyFlag)
				self:raiseDirtyFlags(self.spec_cylindered.cylinderedDirtyFlag)
				return
			end
		elseif v1333_ ~= nil or v1334_ ~= nil then
			dependentTool.movingTool.networkInterpolators.rotation:setMinMax(dependentTool.movingTool.rotMin, dependentTool.movingTool.rotMax)
		end
	end
end

-- Local values: spec, tool, move, checkOtherTools, _, implement, vehicle
function Cylindered:actionEventInput(actionName, inputValue, callbackState, isAnalog, isMouse)
	local v1342_ = self.spec_cylindered
	local v_u_1343_ = v1342_.movingTools[callbackState]
	if v_u_1343_ ~= nil then
		v_u_1343_.lastInputTime = g_time
		local v1344_
		if v_u_1343_.invertAxis then
			v1344_ = -inputValue
		else
			v1344_ = inputValue
		end
		local v_u_1345_ = v1344_ * g_gameSettings:getValue(GameSettings.SETTING.VEHICLE_ARM_SENSITIVITY)
		if isMouse then
			v_u_1345_ = v_u_1345_ * 16.666 / g_currentDt * v_u_1343_.mouseSpeedFactor
			if v_u_1343_.moveLocked then
				if math.abs(inputValue) < 0.75 then
					local v1346_ = math.abs(v_u_1345_)
					local v1347_ = v_u_1343_.lockTool.move
					if math.abs(v1347_) * 2 < v1346_ then
						v_u_1343_.moveLocked = false
					else
						v_u_1345_ = 0
					end
				else
					v_u_1343_.moveLocked = false
				end
			else
				local function v1354_(p1348_)
					-- upvalues: (copy) callbackState, (ref) v_u_1345_, (copy) v_u_1343_
					for v1349_, v1350_ in ipairs(p1348_) do
						if v1349_ ~= callbackState and (v1350_.move ~= nil and v1350_.move ~= 0) then
							local v1351_ = v_u_1345_
							local v1352_ = math.abs(v1351_)
							local v1353_ = v1350_.move
							if math.abs(v1353_) < v1352_ then
								v1350_.move = 0
								v1350_.moveToSend = 0
								v1350_.moveLocked = true
								v1350_.lockTool = v_u_1343_
							else
								v_u_1345_ = 0
								v_u_1343_.moveLocked = true
								v_u_1343_.lockTool = v1350_
							end
						end
					end
				end
				v1354_(v1342_.movingTools)
				if self.getAttachedImplements ~= nil then
					for _, v1355_ in pairs(self:getAttachedImplements()) do
						local v1356_ = v1355_.object
						if v1356_.spec_cylindered ~= nil then
							v1354_(v1356_.spec_cylindered.movingTools)
						end
					end
				end
			end
		end
		if v_u_1345_ ~= v_u_1343_.move then
			v_u_1343_.move = v_u_1345_
		end
		if v_u_1343_.move ~= v_u_1343_.moveToSend then
			v_u_1343_.moveToSend = v_u_1343_.move
			self:raiseDirtyFlags(v1342_.cylinderedInputDirtyFlag)
		end
		v_u_1343_.smoothedMove = v_u_1343_.smoothedMove * 0.9 + v_u_1345_ * 0.1
	end
end

-- Local values: vehicle, _, node, index, _, index, implement, spec, _, movingTool, isSelectedGroup, easyArmControlActive, canBeControlled
function Cylindered:getMovingToolDashboardState(dashboard)
	local v1359_
	if dashboard.attacherJointNodes == nil then
		v1359_ = self
	else
		if dashboard.attacherJointIndices == nil then
			dashboard.attacherJointIndices = {}
		end
		v1359_ = self
		for _, v1360_ in ipairs(dashboard.attacherJointNodes) do
			local v1361_ = self:getAttacherJointIndexByNode(v1360_)
			if v1361_ ~= nil then
				local v1362_ = dashboard.attacherJointIndices
				table.insert(v1362_, v1361_)
			end
		end
		dashboard.attacherJointNodes = nil
		if #dashboard.attacherJointIndices == 0 then
			dashboard.attacherJointIndices = nil
		end
	end
	if dashboard.attacherJointIndices ~= nil then
		v1359_ = nil
		for _, v1363_ in ipairs(dashboard.attacherJointIndices) do
			local v1364_ = self:getImplementFromAttacherJointIndex(v1363_)
			if v1364_ ~= nil then
				v1359_ = v1364_.object
				break
			end
		end
	end
	if v1359_ ~= nil then
		local v1365_ = v1359_.spec_cylindered
		if v1365_ ~= nil then
			for _, v1366_ in ipairs(v1365_.movingTools) do
				if v1366_.axis == dashboard.axis then
					local v1367_ = v1366_.controlGroupIndex == 0 and true or v1366_.controlGroupIndex == v1365_.currentControlGroupIndex
					local v1368_
					if v1365_.easyArmControl == nil then
						v1368_ = false
					else
						v1368_ = v1365_.easyArmControl.state
					end
					local v1369_ = not (v1368_ and v1366_.easyArmControlActive or v1368_)
					if v1369_ then
						v1369_ = not v1366_.isEasyControlTarget
					end
					if v1367_ and v1369_ then
						return (v1366_.smoothedMove + 1) / 2
					end
				end
			end
		end
	end
	return 0.5
end

-- Local values: attacherJointIndex
function Cylindered:movingToolDashboardAttributes(xmlFile, key, dashboard, components, i3dMappings)
	dashboard.axis = xmlFile:getValue(key .. "#axis")
	if dashboard.axis == nil then
		Logging.xmlWarning(xmlFile, "Misssing axis attribute for dashboard \'%s\'", key)
		return false
	end
	local v1374_ = xmlFile:getValue(key .. "#attacherJointIndex")
	if v1374_ ~= nil then
		dashboard.attacherJointIndices = {}
		local v1375_ = dashboard.attacherJointIndices
		table.insert(v1375_, v1374_)
	end
	dashboard.attacherJointNode = xmlFile:getValue(key .. "#attacherJointNode", nil, self.components, self.i3dMappings)
	dashboard.attacherJointNodes = xmlFile:getValue(key .. "#attacherJointNodes", nil, self.components, self.i3dMappings, true)
	local v1376_ = dashboard.attacherJointNodes
	local v1377_ = dashboard.attacherJointNode
	table.insert(v1376_, v1377_)
	if #dashboard.attacherJointNodes == 0 then
		dashboard.attacherJointNodes = nil
	end
	return true
end
