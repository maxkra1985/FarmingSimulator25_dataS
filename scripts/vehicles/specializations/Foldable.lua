source("dataS/scripts/vehicles/specializations/events/FoldableSetFoldDirectionEvent.lua")
Foldable = {}

function Foldable.prerequisitesPresent(specializations)
	return true
end
function Foldable.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("folding", g_i18n:getText("configuration_folding"), "foldable", VehicleConfigurationItem)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("Foldable")
	v1_:register(XMLValueType.FLOAT, "vehicle.foldable.foldingConfigurations.foldingConfiguration(?)#workingWidth", "Working width to display in shop")
	Foldable.registerFoldingXMLPaths(v1_, "vehicle.foldable.foldingConfigurations.foldingConfiguration(?).foldingParts")
	v1_:register(XMLValueType.BOOL, WorkArea.WORK_AREA_XML_KEY .. "#foldLimitedOuterRange", "Fold limit outer range", false)
	v1_:register(XMLValueType.FLOAT, WorkArea.WORK_AREA_XML_KEY .. ".folding#minLimit", "Min. fold limit", 0)
	v1_:register(XMLValueType.FLOAT, WorkArea.WORK_AREA_XML_KEY .. ".folding#maxLimit", "Max. fold limit", 1)
	v1_:register(XMLValueType.BOOL, WorkArea.WORK_AREA_XML_CONFIG_KEY .. "#foldLimitedOuterRange", "Fold limit outer range", false)
	v1_:register(XMLValueType.FLOAT, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".folding#minLimit", "Min. fold limit", 0)
	v1_:register(XMLValueType.FLOAT, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".folding#maxLimit", "Max. fold limit", 1)
	v1_:register(XMLValueType.FLOAT, GroundReference.GROUND_REFERENCE_XML_KEY .. ".folding#minLimit", "Min. fold limit", 0)
	v1_:register(XMLValueType.FLOAT, GroundReference.GROUND_REFERENCE_XML_KEY .. ".folding#maxLimit", "Max. fold limit", 1)
	v1_:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#foldLimitedOuterRange", "Fold limit outer range", false)
	v1_:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#foldMinLimit", "Min. fold limit", 0)
	v1_:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#foldMaxLimit", "Max. fold limit", 1)
	v1_:register(XMLValueType.BOOL, Leveler.LEVELER_NODE_XML_KEY .. "#foldLimitedOuterRange", "Fold limit outer range", false)
	v1_:register(XMLValueType.FLOAT, Leveler.LEVELER_NODE_XML_KEY .. "#foldMinLimit", "Min. fold limit", 0)
	v1_:register(XMLValueType.FLOAT, Leveler.LEVELER_NODE_XML_KEY .. "#foldMaxLimit", "Max. fold limit", 1)
	v1_:addDelayedRegistrationFunc("SlopeCompensation:compensationNode", function(p2_, p3_)
		p2_:register(XMLValueType.FLOAT, p3_ .. "#foldAngleScale", "Fold angle scale")
		p2_:register(XMLValueType.BOOL, p3_ .. "#invertFoldAngleScale", "Invert fold angle scale", false)
	end)
	v1_:addDelayedRegistrationFunc("Cylindered:movingTool", function(p4_, p5_)
		p4_:register(XMLValueType.FLOAT, p5_ .. "#foldMinLimit", "Fold min. time", 0)
		p4_:register(XMLValueType.FLOAT, p5_ .. "#foldMaxLimit", "Fold max. time", 1)
		p4_:register(XMLValueType.INT, p5_ .. "#foldingConfigurationIndex", "Index of folding configuration to activate the moving tool")
		p4_:register(XMLValueType.VECTOR_N, p5_ .. "#foldingConfigurationIndices", "List of folding configuration indices to activate the moving tool")
	end)
	v1_:addDelayedRegistrationFunc("Cylindered:movingPart", function(p6_, p7_)
		p6_:register(XMLValueType.FLOAT, p7_ .. "#foldMinLimit", "Fold min. time", 0)
		p6_:register(XMLValueType.FLOAT, p7_ .. "#foldMaxLimit", "Fold max. time", 1)
	end)
	v1_:addDelayedRegistrationFunc("Attachable:support", function(p8_, p9_)
		p8_:register(XMLValueType.FLOAT, p9_ .. ".folding#minLimit", "Min. fold limit", 0)
		p8_:register(XMLValueType.FLOAT, p9_ .. ".folding#maxLimit", "Max. fold limit", 1)
	end)
	v1_:addDelayedRegistrationFunc("CrabSteering:steeringMode", function(p10_, p11_)
		p10_:register(XMLValueType.FLOAT, p11_ .. ".folding#minLimit", "Min. fold limit", 0)
		p10_:register(XMLValueType.FLOAT, p11_ .. ".folding#maxLimit", "Max. fold limit", 1)
	end)
	v1_:addDelayedRegistrationFunc("WheelChock", function(p12_, p13_)
		p12_:register(XMLValueType.FLOAT, p13_ .. "#foldMinLimit", "Fold min. time", 0)
		p12_:register(XMLValueType.FLOAT, p13_ .. "#foldMaxLimit", "Fold max. time", 1)
	end)
	v1_:addDelayedRegistrationFunc("GroundAdjustedNodes:node", function(p14_, p15_)
		p14_:register(XMLValueType.FLOAT, p15_ .. ".foldable#minLimit", "Fold min. time", 0)
		p14_:register(XMLValueType.FLOAT, p15_ .. ".foldable#maxLimit", "Fold max. time", 1)
	end)
	v1_:addDelayedRegistrationFunc("CraneShovel", function(p16_, p17_)
		p16_:register(XMLValueType.FLOAT, p17_ .. ".foldable#minLimit", "Fold min. time", 0)
		p16_:register(XMLValueType.FLOAT, p17_ .. ".foldable#maxLimit", "Fold max. time", 1)
	end)
	v1_:register(XMLValueType.FLOAT, Sprayer.SPRAY_TYPE_XML_KEY .. "#foldMinLimit", "Fold min. time", 0)
	v1_:register(XMLValueType.FLOAT, Sprayer.SPRAY_TYPE_XML_KEY .. "#foldMaxLimit", "Fold max. time", 1)
	v1_:register(XMLValueType.INT, Sprayer.SPRAY_TYPE_XML_KEY .. "#foldingConfigurationIndex", "Index of folding configuration to activate spray type")
	v1_:register(XMLValueType.VECTOR_N, Sprayer.SPRAY_TYPE_XML_KEY .. "#foldingConfigurationIndices", "List of folding configuration indices to activate spray type")
	v1_:register(XMLValueType.FLOAT, Attachable.INPUT_ATTACHERJOINT_XML_KEY .. "#foldMinLimit", "Fold min. time", 0)
	v1_:register(XMLValueType.FLOAT, Attachable.INPUT_ATTACHERJOINT_XML_KEY .. "#foldMaxLimit", "Fold max. time", 1)
	v1_:register(XMLValueType.FLOAT, Attachable.INPUT_ATTACHERJOINT_CONFIG_XML_KEY .. "#foldMinLimit", "Fold min. time", 0)
	v1_:register(XMLValueType.FLOAT, Attachable.INPUT_ATTACHERJOINT_CONFIG_XML_KEY .. "#foldMaxLimit", "Fold max. time", 1)
	v1_:register(XMLValueType.FLOAT, Attachable.INPUT_ATTACHERJOINT_XML_KEY .. ".heightNode(?)#foldMinLimit", "Fold min. time", 0)
	v1_:register(XMLValueType.FLOAT, Attachable.INPUT_ATTACHERJOINT_XML_KEY .. ".heightNode(?)#foldMaxLimit", "Fold max. time", 1)
	v1_:register(XMLValueType.FLOAT, Attachable.INPUT_ATTACHERJOINT_CONFIG_XML_KEY .. ".heightNode(?)#foldMinLimit", "Fold min. time", 0)
	v1_:register(XMLValueType.FLOAT, Attachable.INPUT_ATTACHERJOINT_CONFIG_XML_KEY .. ".heightNode(?)#foldMaxLimit", "Fold max. time", 1)
	v1_:register(XMLValueType.FLOAT, Enterable.ADDITIONAL_CHARACTER_XML_KEY .. "#foldMinLimit", "Fold min. time", 0)
	v1_:register(XMLValueType.FLOAT, Enterable.ADDITIONAL_CHARACTER_XML_KEY .. "#foldMaxLimit", "Fold max. time", 1)
	v1_:register(XMLValueType.FLOAT, Attachable.STEERING_AXLE_XML_KEY .. ".folding#minLimit", "Min. fold limit", 0)
	v1_:register(XMLValueType.FLOAT, Attachable.STEERING_AXLE_XML_KEY .. ".folding#maxLimit", "Max. fold limit", 1)
	v1_:register(XMLValueType.FLOAT, Wheels.WHEEL_XML_PATH .. "#versatileFoldMinLimit", "Fold min. time for versatility", 0)
	v1_:register(XMLValueType.FLOAT, Wheels.WHEEL_XML_PATH .. "#versatileFoldMaxLimit", "Fold max. time for versatility", 1)
	v1_:register(XMLValueType.FLOAT, FillUnit.FILL_UNIT_XML_KEY .. "#foldMinLimit", "Fold min. time for filling", 0)
	v1_:register(XMLValueType.FLOAT, FillUnit.FILL_UNIT_XML_KEY .. "#foldMaxLimit", "Fold max. time for filling", 1)
	v1_:register(XMLValueType.FLOAT, TurnOnVehicle.TURNED_ON_ANIMATION_XML_PATH .. "#foldMinLimit", "Fold min. time for running turned on animation", 0)
	v1_:register(XMLValueType.FLOAT, TurnOnVehicle.TURNED_ON_ANIMATION_XML_PATH .. "#foldMaxLimit", "Fold max. time for running turned on animation", 1)
	v1_:register(XMLValueType.FLOAT, Pickup.PICKUP_XML_KEY .. "#foldMinLimit", "Fold min. time for pickup lowering", 0)
	v1_:register(XMLValueType.FLOAT, Pickup.PICKUP_XML_KEY .. "#foldMaxLimit", "Fold max. time for pickup lowering", 1)
	v1_:register(XMLValueType.FLOAT, Cutter.CUTTER_TILT_XML_KEY .. "#foldMinLimit", "Fold min. time for cutter automatic tilt", 0)
	v1_:register(XMLValueType.FLOAT, Cutter.CUTTER_TILT_XML_KEY .. "#foldMaxLimit", "Fold max. time for cutter automatic tilt", 1)
	v1_:register(XMLValueType.FLOAT, VinePrepruner.PRUNER_NODE_XML_KEY .. "#foldMinLimit", "Fold min. time for pruner node update", 0)
	v1_:register(XMLValueType.FLOAT, VinePrepruner.PRUNER_NODE_XML_KEY .. "#foldMaxLimit", "Fold max. time for pruner node update", 1)
	v1_:register(XMLValueType.FLOAT, Shovel.SHOVEL_NODE_XML_KEY .. "#foldMinLimit", "Fold min. time for shovel pickup", 0)
	v1_:register(XMLValueType.FLOAT, Shovel.SHOVEL_NODE_XML_KEY .. "#foldMaxLimit", "Fold max. time for shovel pickup", 1)
	v1_:register(XMLValueType.FLOAT, Attachable.STEERING_ANGLE_NODE_XML_KEY .. "#foldMinLimit", "Fold min. time for steering angle nodes to update", 0)
	v1_:register(XMLValueType.FLOAT, Attachable.STEERING_ANGLE_NODE_XML_KEY .. "#foldMaxLimit", "Fold max. time for steering angle nodes to update", 1)
	v1_:register(XMLValueType.FLOAT, WoodHarvester.HEADER_JOINT_TILT_XML_KEY .. "#foldMinLimit", "Fold min. time for header tilt to be allowed", 0)
	v1_:register(XMLValueType.FLOAT, WoodHarvester.HEADER_JOINT_TILT_XML_KEY .. "#foldMaxLimit", "Fold max. time for header tilt to be allowed", 1)
	v1_:register(XMLValueType.FLOAT, Suspensions.SUSPENSION_NODE_XML_KEY .. "#foldMinLimit", "Fold min. time for suspension node to be active", 0)
	v1_:register(XMLValueType.FLOAT, Suspensions.SUSPENSION_NODE_XML_KEY .. "#foldMaxLimit", "Fold max. time for suspension node to be active", 1)
	v1_:setXMLSpecializationType()
	local v18_ = Vehicle.xmlSchemaSavegame
	v18_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).foldable#foldAnimTime", "Fold animation time")
	v18_:register(XMLValueType.BOOL, "vehicles.vehicle(?).foldable#isAllowed", "If folding is allowed")
end

function Foldable.registerFoldingXMLPaths(schema, basePath)
	schema:register(XMLValueType.L10N_STRING, basePath .. "#objectText", "override OBJECT text inserted in folding action string", "vehicle typeDesc")
	schema:register(XMLValueType.L10N_STRING, basePath .. "#posDirectionText", "Positive direction text", "$l10n_action_foldOBJECT")
	schema:register(XMLValueType.L10N_STRING, basePath .. "#negDirectionText", "Negative direction text", "$l10n_action_unfoldOBJECT")
	schema:register(XMLValueType.L10N_STRING, basePath .. "#middlePosDirectionText", "Positive middle direction text", "$l10n_action_liftOBJECT")
	schema:register(XMLValueType.L10N_STRING, basePath .. "#middleNegDirectionText", "Negative middle direction text", "$l10n_action_lowerOBJECT")
	schema:register(XMLValueType.FLOAT, basePath .. "#startAnimTime", "Start animation time", "Depending on startMoveDirection")
	schema:register(XMLValueType.INT, basePath .. "#startMoveDirection", "Start move direction", 0)
	schema:register(XMLValueType.INT, basePath .. "#turnOnFoldDirection", "Turn on fold direction")
	schema:register(XMLValueType.BOOL, basePath .. "#allowUnfoldingByAI", "Allow folding by AI", true)
	schema:register(XMLValueType.STRING, basePath .. "#foldInputButton", "Fold Input action", "IMPLEMENT_EXTRA2")
	schema:register(XMLValueType.STRING, basePath .. "#foldMiddleInputButton", "Fold middle Input action", "LOWER_IMPLEMENT")
	schema:register(XMLValueType.FLOAT, basePath .. "#foldMiddleAnimTime", "Fold middle anim time")
	schema:register(XMLValueType.INT, basePath .. "#foldMiddleDirection", "Fold middle direction", 1)
	schema:register(XMLValueType.INT, basePath .. "#foldMiddleAIRaiseDirection", "Fold middle AI raise direction", "same as foldMiddleDirection")
	schema:register(XMLValueType.FLOAT, basePath .. "#turnOnFoldMaxLimit", "Turn on fold max. limit", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#turnOnFoldMinLimit", "Turn on fold min. limit", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#toggleCoverMaxLimit", "Toggle cover fold max. limit", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#toggleCoverMinLimit", "Toggle cover fold min. limit", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#detachingMaxLimit", "Detach fold max. limit", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#detachingMinLimit", "Detach fold min. limit", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#attachingMaxLimit", "Attach fold max. limit", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#attachingMinLimit", "Attach fold min. limit", 0)
	schema:register(XMLValueType.BOOL, basePath .. "#allowDetachingWhileFolding", "Allow detaching while folding", false)
	schema:register(XMLValueType.FLOAT, basePath .. "#loweringMaxLimit", "Lowering fold max. limit", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#loweringMinLimit", "Lowering fold min. limit", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#loadMovingToolStatesMaxLimit", "Load moving tool states fold max. limit", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#loadMovingToolStatesMinLimit", "Load moving tool states fold min. limit", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#dynamicMountMaxLimit", "Dynamic mount fold max. limit", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#dynamicMountMinLimit", "Dynamic mount fold min. limit", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#crabSteeringMinLimit", "Crab steering change fold max. limit", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#crabSteeringMaxLimit", "Crab steering change fold min. limit", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".toggleFolding#minLimit", "Min. fold time to invert the current folding direction when already folding", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".toggleFolding#maxLimit", "Max. fold time to invert the current folding direction when already folding", 1)
	schema:register(XMLValueType.INT, basePath .. ".toggleFolding#blockedDirection", "Direction which is blocked while not in the given range (0 = all directions)", 0)
	schema:register(XMLValueType.L10N_STRING, basePath .. "#unfoldWarning", "Unfold warning (Triggered when not in the right folding state for certain action (due to min/max limits))", "$l10n_warning_firstUnfoldTheTool")
	schema:register(XMLValueType.L10N_STRING, basePath .. "#detachWarning", "Detach warning (Triggered when trying to detach while currently folding)", "$l10n_warning_doNotDetachWhileFolding")
	schema:register(XMLValueType.BOOL, basePath .. "#useParentFoldingState", "The fold state can not be controlled manually. It\'s always a copy of the fold state of the parent vehicle.", false)
	schema:register(XMLValueType.BOOL, basePath .. "#ignoreFoldMiddleWhileFolded", "While the tool is folded pressing the lowering button will only control the attacher joint state, not the fold state. The lowering key has only function if the tool is unfolded. (only if fold middle time defined)", false)
	schema:register(XMLValueType.BOOL, basePath .. "#lowerWhileDetach", "If tool is in fold middle state it gets lowered on detach and lifted while it\'s attached again", false)
	schema:register(XMLValueType.BOOL, basePath .. "#foldWhileDetach", "Fold the tool while it is being detached", false)
	schema:register(XMLValueType.BOOL, basePath .. "#keepFoldingWhileDetached", "If set to \'true\' the tool is still continuing with the folding animation after the tool is detached, otherwise it\'s stopped", "true for mobile platform, otherwise false")
	schema:register(XMLValueType.BOOL, basePath .. "#releaseBrakesWhileFolding", "If set to \'true\' the tool is releasing it\'s brakes while the folding is active", false)
	schema:register(XMLValueType.BOOL, basePath .. "#requiresPower", "Vehicle needs to be powered to change folding state", true)
	schema:register(XMLValueType.BOOL, basePath .. "#allowControlWhileFolding", "Allow controlling of vehicle while folding is in progress", true)
	schema:register(XMLValueType.FLOAT, basePath .. ".foldingPart(?)#speedScale", "Speed scale", 1)
	schema:register(XMLValueType.INT, basePath .. ".foldingPart(?)#componentJointIndex", "Component joint index")
	schema:register(XMLValueType.INT, basePath .. ".foldingPart(?)#anchorActor", "Component joint anchor actor", 0)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".foldingPart(?)#rootNode", "Root node for animation clip")
	schema:register(XMLValueType.STRING, basePath .. ".foldingPart(?)#animationClip", "Animation clip name")
	schema:register(XMLValueType.STRING, basePath .. ".foldingPart(?)#animationName", "Animation name")
	schema:register(XMLValueType.FLOAT, basePath .. ".foldingPart(?)#delayDistance", "Distance to be moved by the vehicle until part is played")
	schema:register(XMLValueType.FLOAT, basePath .. ".foldingPart(?)#previousDuration", "lowering duration if previous part", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".foldingPart(?)#loweringDuration", "lowering duration if folding part", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".foldingPart(?)#maxDelayDuration", "Max. duration of distance delay until movement is forced. Decreases by half when not moving", 7.5)
	schema:register(XMLValueType.BOOL, basePath .. ".foldingPart(?)#aiSkipDelay", "Defines if the AI uses the delayed lowering/lifting or is controls all parts synchronized", false)
	schema:register(XMLValueType.BOOL, basePath .. ".foldingPart(?)#skipDelayOnReverse", "While reversing the delay is completely skipped", true)
end

function Foldable.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onFoldStateChanged")
	SpecializationUtil.registerEvent(vehicleType, "onFoldTimeChanged")
end

function Foldable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadFoldingPartFromXML", Foldable.loadFoldingPartFromXML)
	SpecializationUtil.registerFunction(vehicleType, "setFoldDirection", Foldable.setFoldDirection)
	SpecializationUtil.registerFunction(vehicleType, "setFoldState", Foldable.setFoldState)
	SpecializationUtil.registerFunction(vehicleType, "setFoldMiddleState", Foldable.setFoldMiddleState)
	SpecializationUtil.registerFunction(vehicleType, "getIsUnfolded", Foldable.getIsUnfolded)
	SpecializationUtil.registerFunction(vehicleType, "getFoldAnimTime", Foldable.getFoldAnimTime)
	SpecializationUtil.registerFunction(vehicleType, "setIsFoldActionAllowed", Foldable.setIsFoldActionAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getIsFoldActionAllowed", Foldable.getIsFoldActionAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getIsFoldAllowed", Foldable.getIsFoldAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getIsFoldMiddleAllowed", Foldable.getIsFoldMiddleAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getToggledFoldDirection", Foldable.getToggledFoldDirection)
	SpecializationUtil.registerFunction(vehicleType, "getToggledFoldMiddleDirection", Foldable.getToggledFoldMiddleDirection)
end

function Foldable.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "allowLoadMovingToolStates", Foldable.allowLoadMovingToolStates)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSpeedRotatingPartFromXML", Foldable.loadSpeedRotatingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSpeedRotatingPartActive", Foldable.getIsSpeedRotatingPartActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSlopeCompensationNodeFromXML", Foldable.loadSlopeCompensationNodeFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSlopeCompensationAngleScale", Foldable.getSlopeCompensationAngleScale)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWheelFromXML", Foldable.loadWheelFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsVersatileYRotActive", Foldable.getIsVersatileYRotActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", Foldable.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", Foldable.getIsWorkAreaActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadGroundReferenceNode", Foldable.loadGroundReferenceNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateGroundReferenceNode", Foldable.updateGroundReferenceNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadLevelerNodeFromXML", Foldable.loadLevelerNodeFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsLevelerPickupNodeActive", Foldable.getIsLevelerPickupNodeActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadMovingToolFromXML", Foldable.loadMovingToolFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMovingToolActive", Foldable.getIsMovingToolActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadMovingPartFromXML", Foldable.loadMovingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMovingPartActive", Foldable.getIsMovingPartActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", Foldable.getCanBeTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsNextCoverStateAllowed", Foldable.getIsNextCoverStateAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsNextCoverStateAllowedWarning", Foldable.getIsNextCoverStateAllowedWarning)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsInWorkPosition", Foldable.getIsInWorkPosition)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTurnedOnNotAllowedWarning", Foldable.getTurnedOnNotAllowedWarning)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "isDetachAllowed", Foldable.isDetachAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "isAttachAllowed", Foldable.isAttachAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowsLowering", Foldable.getAllowsLowering)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsLowered", Foldable.getIsLowered)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanAIImplementContinueWork", Foldable.getCanAIImplementContinueWork)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIReadyToDrive", Foldable.getIsAIReadyToDrive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIPreparingToDrive", Foldable.getIsAIPreparingToDrive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "registerLoweringActionEvent", Foldable.registerLoweringActionEvent)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "registerSelfLoweringActionEvent", Foldable.registerSelfLoweringActionEvent)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadGroundAdjustedNodeFromXML", Foldable.loadGroundAdjustedNodeFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsGroundAdjustedNodeActive", Foldable.getIsGroundAdjustedNodeActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSprayTypeFromXML", Foldable.loadSprayTypeFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSprayTypeActive", Foldable.getIsSprayTypeActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Foldable.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadInputAttacherJoint", Foldable.loadInputAttacherJoint)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsInputAttacherActive", Foldable.getIsInputAttacherActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAdditionalCharacterFromXML", Foldable.loadAdditionalCharacterFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAdditionalCharacterActive", Foldable.getIsAdditionalCharacterActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowDynamicMountObjects", Foldable.getAllowDynamicMountObjects)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSupportAnimationFromXML", Foldable.loadSupportAnimationFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSupportAnimationAllowed", Foldable.getIsSupportAnimationAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSteeringAxleFromXML", Foldable.loadSteeringAxleFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSteeringAxleAllowed", Foldable.getIsSteeringAxleAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadFillUnitFromXML", Foldable.loadFillUnitFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitSupportsToolType", Foldable.getFillUnitSupportsToolType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadTurnedOnAnimationFromXML", Foldable.loadTurnedOnAnimationFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsTurnedOnAnimationActive", Foldable.getIsTurnedOnAnimationActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAttacherJointHeightNode", Foldable.loadAttacherJointHeightNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAttacherJointHeightNodeActive", Foldable.getIsAttacherJointHeightNodeActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadPickupFromXML", Foldable.loadPickupFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanChangePickupState", Foldable.getCanChangePickupState)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadCutterTiltFromXML", Foldable.loadCutterTiltFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCutterTiltIsActive", Foldable.getCutterTiltIsActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadPreprunerNodeFromXML", Foldable.loadPreprunerNodeFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsPreprunerNodeActive", Foldable.getIsPreprunerNodeActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadShovelNode", Foldable.loadShovelNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getShovelNodeIsActive", Foldable.getShovelNodeIsActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSteeringAngleNodeFromXML", Foldable.loadSteeringAngleNodeFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateSteeringAngleNode", Foldable.updateSteeringAngleNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWoodHarvesterHeaderTiltFromXML", Foldable.loadWoodHarvesterHeaderTiltFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWoodHarvesterTiltStateAllowed", Foldable.getIsWoodHarvesterTiltStateAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSuspensionNodeFromXML", Foldable.loadSuspensionNodeFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSuspensionNodeActive", Foldable.getIsSuspensionNodeActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadCrabSteeringModeFromXML", Foldable.loadCrabSteeringModeFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCrabSteeringModeAvailable", Foldable.getCrabSteeringModeAvailable)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleCrabSteering", Foldable.getCanToggleCrabSteering)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "onLoadWheelChockFromXML", Foldable.onLoadWheelChockFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWheelChockAllowed", Foldable.getIsWheelChockAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadCraneShovelFromXML", Foldable.loadCraneShovelFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCraneShovelStateChangedAllowed", Foldable.getCraneShovelStateChangedAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getBrakeForce", Foldable.getBrakeForce)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRequiresPower", Foldable.getRequiresPower)
end

function Foldable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onRegistered", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterExternalActionEvents", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onSetLoweredAll", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onRootVehicleChanged", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onPreAttachImplement", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetachImplement", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onDynamicMountTypeChanged", Foldable)
end

-- Local values: spec, foldingConfigurationId, configKey, startMoveDirection, foldInputButtonStr, foldMiddleInputButtonStr, i, baseKey, foldingPart, foldAnimTime
function Foldable:onLoad(savegame)
	local v27_ = self.spec_foldable
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.foldingParts", "vehicle.foldable.foldingConfigurations.foldingConfiguration.foldingParts")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.foldable.foldingParts", "vehicle.foldable.foldingConfigurations.foldingConfiguration.foldingParts")
	local v28_ = Utils.getNoNil(self.configurations.folding, 1)
	local v29_ = string.format("vehicle.foldable.foldingConfigurations.foldingConfiguration(%d).foldingParts", v28_ - 1)
	v27_.isFoldAllowed = true
	v27_.objectText = self.xmlFile:getValue(v29_ .. "#objectText", self.typeDesc, self.customEnvironment, false)
	v27_.posDirectionText = string.format(self.xmlFile:getValue(v29_ .. "#posDirectionText", "action_foldOBJECT", self.customEnvironment, false), v27_.objectText)
	v27_.negDirectionText = string.format(self.xmlFile:getValue(v29_ .. "#negDirectionText", "action_unfoldOBJECT", self.customEnvironment, false), v27_.objectText)
	v27_.middlePosDirectionText = string.format(self.xmlFile:getValue(v29_ .. "#middlePosDirectionText", "action_liftOBJECT", self.customEnvironment, false), v27_.objectText)
	v27_.middleNegDirectionText = string.format(self.xmlFile:getValue(v29_ .. "#middleNegDirectionText", "action_lowerOBJECT", self.customEnvironment, false), v27_.objectText)
	v27_.startAnimTime = self.xmlFile:getValue(v29_ .. "#startAnimTime")
	v27_.foldMoveDirection = 0
	v27_.moveToMiddle = false
	if v27_.startAnimTime == nil then
		v27_.startAnimTime = 0
		if self.xmlFile:getValue(v29_ .. "#startMoveDirection", 0) > 0.1 then
			v27_.startAnimTime = 1
		end
	end
	v27_.turnOnFoldDirection = 1
	if v27_.startAnimTime > 0.5 then
		v27_.turnOnFoldDirection = -1
	end
	local v30_ = self.xmlFile:getValue(v29_ .. "#turnOnFoldDirection", v27_.turnOnFoldDirection)
	v27_.turnOnFoldDirection = math.sign(v30_)
	if v27_.turnOnFoldDirection == 0 then
		Logging.xmlWarning(self.xmlFile, "Foldable \'turnOnFoldDirection\' not allowed to be 0! Only -1 and 1 are allowed")
		v27_.turnOnFoldDirection = -1
	end
	v27_.allowUnfoldingByAI = self.xmlFile:getValue(v29_ .. "#allowUnfoldingByAI", true)
	local v31_ = self.xmlFile:getValue(v29_ .. "#foldInputButton")
	if v31_ ~= nil then
		v27_.foldInputButton = InputAction[v31_]
	end
	v27_.foldInputButton = Utils.getNoNil(v27_.foldInputButton, InputAction.IMPLEMENT_EXTRA2)
	local v32_ = self.xmlFile:getValue(v29_ .. "#foldMiddleInputButton")
	if v32_ ~= nil then
		v27_.foldMiddleInputButton = InputAction[v32_]
	end
	v27_.foldMiddleInputButton = Utils.getNoNil(v27_.foldMiddleInputButton, InputAction.LOWER_IMPLEMENT)
	v27_.foldMiddleAnimTime = self.xmlFile:getValue(v29_ .. "#foldMiddleAnimTime")
	v27_.foldMiddleDirection = self.xmlFile:getValue(v29_ .. "#foldMiddleDirection", 1)
	v27_.foldMiddleAIRaiseDirection = self.xmlFile:getValue(v29_ .. "#foldMiddleAIRaiseDirection", v27_.foldMiddleDirection)
	v27_.turnOnFoldMaxLimit = self.xmlFile:getValue(v29_ .. "#turnOnFoldMaxLimit", 1)
	v27_.turnOnFoldMinLimit = self.xmlFile:getValue(v29_ .. "#turnOnFoldMinLimit", 0)
	v27_.toggleCoverMaxLimit = self.xmlFile:getValue(v29_ .. "#toggleCoverMaxLimit", 1)
	v27_.toggleCoverMinLimit = self.xmlFile:getValue(v29_ .. "#toggleCoverMinLimit", 0)
	v27_.detachingMaxLimit = self.xmlFile:getValue(v29_ .. "#detachingMaxLimit", 1)
	v27_.detachingMinLimit = self.xmlFile:getValue(v29_ .. "#detachingMinLimit", 0)
	v27_.attachingMaxLimit = self.xmlFile:getValue(v29_ .. "#attachingMaxLimit", 1)
	v27_.attachingMinLimit = self.xmlFile:getValue(v29_ .. "#attachingMinLimit", 0)
	v27_.allowDetachingWhileFolding = self.xmlFile:getValue(v29_ .. "#allowDetachingWhileFolding", false)
	v27_.loweringMaxLimit = self.xmlFile:getValue(v29_ .. "#loweringMaxLimit", 1)
	v27_.loweringMinLimit = self.xmlFile:getValue(v29_ .. "#loweringMinLimit", 0)
	v27_.loadMovingToolStatesMaxLimit = self.xmlFile:getValue(v29_ .. "#loadMovingToolStatesMaxLimit", 1)
	v27_.loadMovingToolStatesMinLimit = self.xmlFile:getValue(v29_ .. "#loadMovingToolStatesMinLimit", 0)
	v27_.dynamicMountMinLimit = self.xmlFile:getValue(v29_ .. "#dynamicMountMinLimit", 0)
	v27_.dynamicMountMaxLimit = self.xmlFile:getValue(v29_ .. "#dynamicMountMaxLimit", 1)
	v27_.crabSteeringMinLimit = self.xmlFile:getValue(v29_ .. "#crabSteeringMinLimit", 0)
	v27_.crabSteeringMaxLimit = self.xmlFile:getValue(v29_ .. "#crabSteeringMaxLimit", 1)
	v27_.toggleFoldingMinLimit = self.xmlFile:getValue(v29_ .. ".toggleFolding#minLimit", 0)
	v27_.toggleFoldingMaxLimit = self.xmlFile:getValue(v29_ .. ".toggleFolding#maxLimit", 1)
	v27_.toggleFoldingBlockedDirection = self.xmlFile:getValue(v29_ .. ".toggleFolding#blockedDirection", 0)
	v27_.unfoldWarning = string.format(self.xmlFile:getValue(v29_ .. "#unfoldWarning", "warning_firstUnfoldTheTool", self.customEnvironment, false), v27_.objectText)
	v27_.detachWarning = string.format(self.xmlFile:getValue(v29_ .. "#detachWarning", "warning_doNotDetachWhileFolding", self.customEnvironment, false), v27_.objectText)
	v27_.useParentFoldingState = self.xmlFile:getValue(v29_ .. "#useParentFoldingState", false)
	v27_.subFoldingStateVehicles = {}
	v27_.ignoreFoldMiddleWhileFolded = self.xmlFile:getValue(v29_ .. "#ignoreFoldMiddleWhileFolded", false)
	v27_.lowerWhileDetach = self.xmlFile:getValue(v29_ .. "#lowerWhileDetach", false)
	v27_.foldWhileDetach = self.xmlFile:getValue(v29_ .. "#foldWhileDetach", false)
	v27_.keepFoldingWhileDetached = self.xmlFile:getValue(v29_ .. "#keepFoldingWhileDetached", Platform.gameplay.keepFoldingWhileDetached)
	v27_.releaseBrakesWhileFolding = self.xmlFile:getValue(v29_ .. "#releaseBrakesWhileFolding", false)
	v27_.requiresPower = self.xmlFile:getValue(v29_ .. "#requiresPower", true)
	v27_.allowControlWhileFolding = self.xmlFile:getValue(v29_ .. "#allowControlWhileFolding", true)
	v27_.foldAnimTime = 0
	v27_.maxFoldAnimDuration = 0.0001
	v27_.foldingParts = {}
	local v33_ = 0
	while true do
		local v34_ = string.format(v29_ .. ".foldingPart(%d)", v33_)
		if not self.xmlFile:hasProperty(v34_) then
			break
		end
		local v35_ = {}
		if self:loadFoldingPartFromXML(self.xmlFile, v34_, v35_) then
			local v36_ = v27_.foldingParts
			table.insert(v36_, v35_)
			local v37_ = v27_.maxFoldAnimDuration
			local v38_ = v35_.animDuration
			v27_.maxFoldAnimDuration = math.max(v37_, v38_)
		end
		v33_ = v33_ + 1
	end
	v27_.hasFoldingParts = #v27_.foldingParts > 0
	v27_.actionEventsLowering = {}
	if v27_.hasFoldingParts and (savegame ~= nil and not savegame.resetVehicles) then
		v27_.loadedFoldAnimTime = savegame.xmlFile:getValue(savegame.key .. ".foldable#foldAnimTime")
		v27_.isFoldAllowed = savegame.xmlFile:getValue(savegame.key .. ".foldable#isAllowed", v27_.isFoldAllowed)
	end
	if v27_.loadedFoldAnimTime == nil then
		v27_.loadedFoldAnimTime = v27_.startAnimTime
	end
	if self.vehicleLoadingData:getCustomParameter("foldableInvertFoldState") then
		v27_.loadedFoldAnimTime = 1 - v27_.loadedFoldAnimTime
	else
		local v39_ = self.vehicleLoadingData:getCustomParameter("foldableFoldingTime")
		if v39_ ~= nil then
			v27_.loadedFoldAnimTime = v39_
		end
	end
end

-- Local values: spec
function Foldable:onPostLoad(savegame)
	local v41_ = self.spec_foldable
	Foldable.setAnimTime(self, v41_.loadedFoldAnimTime, false)
	if #v41_.foldingParts == 0 or v41_.useParentFoldingState then
		SpecializationUtil.removeEventListener(self, "onReadStream", Foldable)
		SpecializationUtil.removeEventListener(self, "onWriteStream", Foldable)
		SpecializationUtil.removeEventListener(self, "onUpdate", Foldable)
		SpecializationUtil.removeEventListener(self, "onUpdateTick", Foldable)
		SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", Foldable)
		SpecializationUtil.removeEventListener(self, "onRegisterExternalActionEvents", Foldable)
		SpecializationUtil.removeEventListener(self, "onDeactivate", Foldable)
		SpecializationUtil.removeEventListener(self, "onSetLoweredAll", Foldable)
		SpecializationUtil.removeEventListener(self, "onPostAttach", Foldable)
		SpecializationUtil.removeEventListener(self, "onPreDetach", Foldable)
		SpecializationUtil.removeEventListener(self, "onDynamicMountTypeChanged", Foldable)
	end
end

-- Local values: spec
function Foldable:onRegistered()
	if not self.spec_foldable.allowControlWhileFolding and self.registerPlayerVehicleControlAllowedFunction ~= nil then
		self:registerPlayerVehicleControlAllowedFunction(self, Foldable.getIsVehicleControlAllowed)
	end
end

-- Local values: spec
function Foldable:saveToXMLFile(xmlFile, key, usedModNames)
	local v46_ = self.spec_foldable
	if v46_.hasFoldingParts then
		xmlFile:setValue(key .. "#foldAnimTime", v46_.foldAnimTime)
		xmlFile:setValue(key .. "#isAllowed", v46_.isFoldAllowed)
	end
end

-- Local values: direction, moveToMiddle, animTime
function Foldable:onReadStream(streamId, connection)
	local v49_ = streamReadUIntN(streamId, 2) - 1
	local v50_ = streamReadBool(streamId)
	local v51_ = streamReadFloat32(streamId)
	Foldable.setAnimTime(self, v51_, false)
	self:setFoldState(v49_, v50_, true)
end

-- Local values: spec, direction
function Foldable:onWriteStream(streamId, connection)
	local v54_ = self.spec_foldable
	local v55_ = v54_.foldMoveDirection
	local v56_ = math.sign(v55_) + 1
	streamWriteUIntN(streamId, v56_, 2)
	streamWriteBool(streamId, v54_.moveToMiddle)
	streamWriteFloat32(streamId, v54_.foldAnimTime)
end

-- Local values: spec, isInvalid, foldAnimTime, _, foldingPart, charSet, animTime, animTime, _, foldingPart, _, vehicle, i, foldingPart, delayedLowering, lowerDistance, prevDistance, distance, force
function Foldable:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v58_ = self.spec_foldable
	local v59_ = v58_.foldMoveDirection
	if math.abs(v59_) > 0.1 then
		local v60_ = v58_.foldMoveDirection < -0.1 and 1 or 0
		local v61_ = false
		for _, v62_ in pairs(v58_.foldingParts) do
			local v63_ = v62_.animCharSet
			if v58_.foldMoveDirection > 0 then
				local v64_
				if v63_ == 0 then
					v64_ = self:getRealAnimationTime(v62_.animationName)
				else
					v64_ = getAnimTrackTime(v63_, 0)
				end
				v61_ = v64_ < v62_.animDuration and true or v61_
				local v65_ = v64_ / v58_.maxFoldAnimDuration
				v60_ = math.max(v60_, v65_)
			elseif v58_.foldMoveDirection < 0 then
				local v66_
				if v63_ == 0 then
					v66_ = self:getRealAnimationTime(v62_.animationName)
				else
					v66_ = getAnimTrackTime(v63_, 0)
				end
				v61_ = v66_ > 0 and true or v61_
				local v67_ = v66_ / v58_.maxFoldAnimDuration
				v60_ = math.min(v60_, v67_)
			end
		end
		local v68_ = math.clamp(v60_, 0, 1)
		if v68_ ~= v58_.foldAnimTime then
			v58_.foldAnimTime = v68_
			SpecializationUtil.raiseEvent(self, "onFoldTimeChanged", v58_.foldAnimTime)
		end
		if v58_.foldMoveDirection > 0 then
			if v58_.moveToMiddle and v58_.foldMiddleAnimTime ~= nil then
				if v58_.foldAnimTime == v58_.foldMiddleAnimTime then
					v58_.foldMoveDirection = 0
				end
			elseif v58_.foldAnimTime == 1 then
				v58_.foldMoveDirection = 0
			end
		elseif v58_.foldMoveDirection < 0 then
			if v58_.moveToMiddle and v58_.foldMiddleAnimTime ~= nil then
				if v58_.foldAnimTime == v58_.foldMiddleAnimTime then
					v58_.foldMoveDirection = 0
				end
			elseif v58_.foldAnimTime == 0 then
				v58_.foldMoveDirection = 0
			end
		end
		if v61_ and self.isServer then
			for _, v69_ in pairs(v58_.foldingParts) do
				if v69_.componentJoint ~= nil then
					self:setComponentJointFrame(v69_.componentJoint, v69_.anchorActor)
				end
			end
		end
		for _, v70_ in pairs(v58_.subFoldingStateVehicles) do
			Foldable.setAnimTime(v70_, v58_.foldAnimTime, false, true)
		end
		if not v58_.allowControlWhileFolding and self.brake ~= nil then
			self:brake(self:getBrakeForce())
		end
	end
	for v71_ = 1, #v58_.foldingParts do
		local v72_ = v58_.foldingParts[v71_]
		local v73_ = v72_.delayedLowering
		if v73_ ~= nil and v73_.currentDistance >= 0 then
			v73_.currentDistance = v73_.currentDistance + self.lastMovedDistance
			if v73_.prevDistance == nil and v73_.startTime + v73_.previousDuration < g_time then
				v73_.prevDistance = v73_.currentDistance
			end
			local v74_ = self.lastSpeedReal * v73_.loweringDuration
			local v75_ = v73_.prevDistance or self.lastSpeedReal * v73_.previousDuration
			local v76_ = v73_.distance + v75_ - v74_
			local v77_ = g_time
			local v78_ = v73_.startTime
			local v79_ = v73_.maxDelayDuration
			local v80_ = v73_.currentDistance / v76_ * 0.5 + 0.5
			local v81_ = v78_ + v79_ * math.clamp(v80_, 0, 1) < v77_
			if v73_.aiSkipDelay then
				v81_ = v81_ or self:getIsAIActive()
			end
			if v73_.skipDelayOnReverse then
				if not v81_ then
					if self:getLastSpeed() > 2.5 then
						v81_ = self.movingDirection < 0
					else
						v81_ = false
					end
				end
			end
			if v76_ <= v73_.currentDistance or v81_ then
				self:playAnimation(v72_.animationName, v73_.speedScale, v73_.animTime, true)
				if v73_.stopAnimTime ~= nil then
					self:setAnimationStopTime(v72_.animationName, v73_.stopAnimTime)
				end
				v73_.currentDistance = -1
			end
		end
	end
end

-- Local values: spec, attacherVehicle, jointDesc
function Foldable:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v83_ = self.spec_foldable
	if self.isClient then
		Foldable.updateActionEventFold(self)
		if v83_.foldMiddleAnimTime ~= nil then
			Foldable.updateActionEventFoldMiddle(self)
		end
	end
	if self.isServer and (v83_.ignoreFoldMiddleWhileFolded and self.getAttacherVehicle ~= nil) then
		local v84_ = v83_.foldAnimTime - v83_.foldMiddleAnimTime
		if math.abs(v84_) < 0.001 and v83_.foldMoveDirection == 1 == (v83_.turnOnFoldDirection == 1) then
			local v85_ = self:getAttacherVehicle()
			if v85_ ~= nil then
				local v86_ = v85_:getAttacherJointDescFromObject(self)
				if (v86_.allowsLowering or v86_.isDefaultLowered) and v86_.moveDown then
					self:setFoldState(-1, false)
				end
			end
		end
	end
end

-- Local values: isValid, componentJointIndex, componentJoint, rootNode, animCharSet, clip, animationName, animation, distance, node
function Foldable:loadFoldingPartFromXML(xmlFile, baseKey, foldingPart)
	local v91_ = false
	foldingPart.speedScale = xmlFile:getValue(baseKey .. "#speedScale", 1)
	if foldingPart.speedScale <= 0 then
		Logging.xmlWarning(xmlFile, "Negative speed scale for folding part \'%s\' not allowed!", baseKey)
		return false
	end
	local v92_ = xmlFile:getValue(baseKey .. "#componentJointIndex")
	local v93_
	if v92_ == nil then
		v93_ = nil
	else
		if v92_ == 0 then
			Logging.xmlWarning(xmlFile, "Invalid componentJointIndex for folding part \'%s\'. Indexing starts with 1!", baseKey)
			return false
		end
		v93_ = self.componentJoints[v92_]
		foldingPart.componentJoint = v93_
	end
	foldingPart.anchorActor = xmlFile:getValue(baseKey .. "#anchorActor", 0)
	foldingPart.animCharSet = 0
	local v94_ = xmlFile:getValue(baseKey .. "#rootNode", nil, self.components, self.i3dMappings)
	if v94_ ~= nil then
		local v95_ = getAnimCharacterSet(v94_)
		if v95_ ~= 0 then
			local v96_ = getAnimClipIndex(v95_, xmlFile:getValue(baseKey .. "#animationClip"))
			if v96_ >= 0 then
				foldingPart.animCharSet = v95_
				assignAnimTrackClip(foldingPart.animCharSet, 0, v96_)
				setAnimTrackLoopState(foldingPart.animCharSet, 0, false)
				foldingPart.animDuration = getAnimClipDuration(foldingPart.animCharSet, v96_)
				v91_ = true
			end
		end
	end
	if not v91_ then
		if SpecializationUtil.hasSpecialization(AnimatedVehicle, self.specializations) then
			local v97_ = xmlFile:getValue(baseKey .. "#animationName")
			if v97_ ~= nil and self:getAnimationExists(v97_) then
				foldingPart.animDuration = self:getAnimationDuration(v97_)
				if foldingPart.animDuration > 0 then
					foldingPart.animationName = v97_
					self:getAnimationByName(v97_).resetOnStart = true
					v91_ = true
				else
					Logging.xmlWarning(xmlFile, "Empty animation in folding part \'%s\'", baseKey)
				end
			end
		elseif xmlFile:getValue(baseKey .. "#animationName") ~= nil then
			Logging.xmlWarning(xmlFile, "Found animationName in folding part \'%s\', but vehicle has no animations!", baseKey)
			return false
		end
	end
	if not v91_ then
		Logging.xmlWarning(xmlFile, "Invalid folding part \'%s\'. Either a animationClip or animationName needs to be defined!", baseKey)
		return false
	end
	local v98_ = xmlFile:getValue(baseKey .. "#delayDistance")
	if v98_ ~= nil then
		foldingPart.delayedLowering = {}
		foldingPart.delayedLowering.distance = v98_
		foldingPart.delayedLowering.previousDuration = xmlFile:getValue(baseKey .. "#previousDuration", 1) * 1000
		foldingPart.delayedLowering.loweringDuration = xmlFile:getValue(baseKey .. "#loweringDuration", 1) * 1000
		foldingPart.delayedLowering.maxDelayDuration = xmlFile:getValue(baseKey .. "#maxDelayDuration", 7.5) * 1000
		foldingPart.delayedLowering.aiSkipDelay = xmlFile:getValue(baseKey .. "#aiSkipDelay", false)
		foldingPart.delayedLowering.skipDelayOnReverse = xmlFile:getValue(baseKey .. "#skipDelayOnReverse", true)
		foldingPart.delayedLowering.currentDistance = -1
		foldingPart.delayedLowering.startTime = math.huge
		foldingPart.delayedLowering.speedScale = 0
		foldingPart.delayedLowering.animTime = 0
		foldingPart.delayedLowering.stopAnimTime = 0
		foldingPart.delayedLowering.prevDistance = nil
	end
	if v93_ ~= nil then
		local v99_ = self.components[v93_.componentIndices[(foldingPart.anchorActor + 1) % 2 + 1]].node
		local v100_, v101_, v102_ = worldToLocal(v93_.jointNode, getWorldTranslation(v99_))
		foldingPart.x = v100_
		foldingPart.y = v101_
		foldingPart.z = v102_
		local v103_, v104_, v105_ = worldDirectionToLocal(v93_.jointNode, localDirectionToWorld(v99_, 0, 1, 0))
		foldingPart.upX = v103_
		foldingPart.upY = v104_
		foldingPart.upZ = v105_
		local v106_, v107_, v108_ = worldDirectionToLocal(v93_.jointNode, localDirectionToWorld(v99_, 0, 0, 1))
		foldingPart.dirX = v106_
		foldingPart.dirY = v107_
		foldingPart.dirZ = v108_
	end
	return true
end

function Foldable:setFoldDirection(direction, noEventSend)
	self:setFoldState(direction, false, noEventSend)
end

-- Local values: spec, _, foldingPart, speedScale, charSet, animTime, alreadyPlaying, stopAnimTime, isFolding, delayedLowering
function Foldable:setFoldState(direction, moveToMiddle, noEventSend)
	local v116_ = self.spec_foldable
	if v116_.foldMiddleAnimTime == nil then
		moveToMiddle = false
	end
	if v116_.foldMoveDirection ~= direction or v116_.moveToMiddle ~= moveToMiddle then
		if noEventSend == nil or noEventSend == false then
			if g_server == nil then
				g_client:getServerConnection():sendEvent(FoldableSetFoldDirectionEvent.new(self, direction, moveToMiddle))
			else
				g_server:broadcastEvent(FoldableSetFoldDirectionEvent.new(self, direction, moveToMiddle), nil, nil, self)
			end
		end
		v116_.foldMoveDirection = direction
		v116_.moveToMiddle = moveToMiddle
		for _, v117_ in pairs(v116_.foldingParts) do
			local v118_ = nil
			if v116_.foldMoveDirection > 0.1 then
				if not v116_.moveToMiddle or v116_.foldAnimTime < v116_.foldMiddleAnimTime then
					v118_ = v117_.speedScale
				end
			elseif v116_.foldMoveDirection < -0.1 and (not v116_.moveToMiddle or v116_.foldAnimTime > v116_.foldMiddleAnimTime) then
				v118_ = -v117_.speedScale
			end
			local v119_ = v117_.animCharSet
			if v119_ == 0 then
				local v120_
				if self:getIsAnimationPlaying(v117_.animationName) then
					v120_ = self:getAnimationTime(v117_.animationName)
				else
					v120_ = v116_.foldAnimTime * v116_.maxFoldAnimDuration / self:getAnimationDuration(v117_.animationName)
				end
				local v121_ = self:getIsAnimationPlaying(v117_.animationName)
				self:stopAnimation(v117_.animationName, true)
				if v118_ ~= nil then
					local v122_
					if moveToMiddle then
						v122_ = v116_.foldMiddleAnimTime * v116_.maxFoldAnimDuration / self:getAnimationDuration(v117_.animationName)
					else
						v122_ = nil
					end
					local v123_ = direction ~= v116_.turnOnFoldDirection == not moveToMiddle
					if v117_.delayedLowering == nil or (v123_ or v121_) then
						self:playAnimation(v117_.animationName, v118_, v120_, true)
						if moveToMiddle then
							self:setAnimationStopTime(v117_.animationName, v122_)
						end
						if v117_.delayedLowering ~= nil then
							v117_.delayedLowering.currentDistance = -1
						end
					else
						local v124_ = v117_.delayedLowering
						v124_.currentDistance = 0
						v124_.speedScale = v118_
						v124_.animTime = v120_
						v124_.stopAnimTime = v122_
						v124_.startTime = g_time
						v124_.prevDistance = nil
					end
				end
			elseif v118_ == nil then
				disableAnimTrack(v119_, 0)
			else
				if v118_ > 0 then
					if getAnimTrackTime(v119_, 0) < 0 then
						setAnimTrackTime(v119_, 0, 0)
					end
				elseif getAnimTrackTime(v119_, 0) > v117_.animDuration then
					setAnimTrackTime(v119_, 0, v117_.animDuration)
				end
				setAnimTrackSpeedScale(v119_, 0, v118_)
				enableAnimTrack(v119_, 0)
			end
		end
		if v116_.foldMoveDirection > 0.1 then
			local v125_ = v116_.foldAnimTime + 0.0001
			local v126_ = v116_.foldAnimTime
			local v127_ = math.max(v126_, 1)
			v116_.foldAnimTime = math.min(v125_, v127_)
		elseif v116_.foldMoveDirection < -0.1 then
			local v128_ = v116_.foldAnimTime - 0.0001
			local v129_ = v116_.foldAnimTime
			local v130_ = math.min(v129_, 0)
			v116_.foldAnimTime = math.max(v128_, v130_)
		end
		if not v116_.allowControlWhileFolding and self.setCruiseControlState ~= nil then
			self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)
		end
		SpecializationUtil.raiseEvent(self, "onFoldStateChanged", direction, moveToMiddle)
	end
end

-- Local values: spec
function Foldable:setFoldMiddleState(doLowering)
	local v133_ = self.spec_foldable
	if v133_.foldMiddleAnimTime ~= nil and self:getIsFoldMiddleAllowed() then
		if doLowering then
			self:setFoldState(-v133_.foldMiddleAIRaiseDirection, false)
			return
		end
		self:setFoldState(v133_.foldMiddleAIRaiseDirection, true)
	end
end

-- Local values: spec
function Foldable:getIsUnfolded()
	local v135_ = self.spec_foldable
	if v135_.hasFoldingParts then
		if v135_.foldMiddleAnimTime == nil then
			return v135_.turnOnFoldDirection == -1 and v135_.foldAnimTime == 0 or v135_.turnOnFoldDirection == 1 and v135_.foldAnimTime == 1
		else
			return v135_.turnOnFoldDirection == -1 and v135_.foldAnimTime < v135_.foldMiddleAnimTime + 0.01 or v135_.turnOnFoldDirection == 1 and v135_.foldAnimTime > v135_.foldMiddleAnimTime - 0.01
		end
	else
		return true
	end
end

-- Local values: spec
function Foldable:getFoldAnimTime()
	local v137_ = self.spec_foldable
	return v137_.loadedFoldAnimTime or v137_.foldAnimTime
end

function Foldable:setIsFoldActionAllowed(isAllowed)
	self.spec_foldable.isFoldAllowed = isAllowed
end

function Foldable:getIsFoldActionAllowed()
	return self.spec_foldable.isFoldAllowed
end

-- Local values: spec, inputAttacherJoint, foldAnimTime
function Foldable:getIsFoldAllowed(direction, onAiTurnOn)
	local v142_ = self.spec_foldable
	if v142_.isFoldAllowed then
		if self.getAttacherVehicle ~= nil and self:getAttacherVehicle() ~= nil then
			local v143_ = self:getActiveInputAttacherJoint()
			if v143_.foldMinLimit ~= nil and v143_.foldMaxLimit ~= nil then
				local v144_ = self:getFoldAnimTime()
				if v144_ < v143_.foldMinLimit or v143_.foldMaxLimit < v144_ then
					return false, nil
				end
			end
		end
		if (v142_.toggleFoldingBlockedDirection == 0 and v142_.foldMoveDirection ~= 0 or v142_.toggleFoldingBlockedDirection ~= 0 and v142_.foldMoveDirection == -v142_.toggleFoldingBlockedDirection) and (v142_.foldAnimTime > v142_.toggleFoldingMaxLimit or v142_.foldAnimTime < v142_.toggleFoldingMinLimit) then
			return false, nil
		else
			return true, nil
		end
	else
		return false, nil
	end
end

-- Local values: spec
function Foldable:getIsFoldMiddleAllowed()
	local v146_ = self.spec_foldable
	if v146_.isFoldAllowed then
		return v146_.foldMiddleAnimTime ~= nil
	else
		return false
	end
end

-- Local values: spec, foldMidTime, targetDirection
function Foldable:getToggledFoldDirection()
	local v148_ = self.spec_foldable
	local v149_
	if v148_.foldMiddleAnimTime == nil then
		v149_ = 0.5
	elseif v148_.foldMiddleDirection > 0 then
		v149_ = (1 + v148_.foldMiddleAnimTime) * 0.5
	else
		v149_ = v148_.foldMiddleAnimTime * 0.5
	end
	local v150_
	if v148_.moveToMiddle then
		v150_ = v148_.foldMiddleDirection
	elseif v148_.foldMoveDirection == 0 then
		v150_ = v148_.foldAnimTime < v149_ and 1 or -1
	else
		v150_ = -v148_.foldMoveDirection
	end
	if v148_.foldMiddleAnimTime ~= nil then
		if v148_.foldMiddleDirection > 0 then
			if v148_.foldAnimTime < v148_.foldMiddleAnimTime - 0.01 then
				return 1
			end
		else
			v150_ = v148_.foldAnimTime > v148_.foldMiddleAnimTime + 0.01 and -1 or v150_
		end
	end
	return v150_
end

-- Local values: spec, ret
function Foldable:getToggledFoldMiddleDirection()
	local v152_ = self.spec_foldable
	local v153_
	if v152_.foldMiddleAnimTime == nil then
		v153_ = 0
	else
		v153_ = v152_.foldMoveDirection > 0.1 and -1 or 1
		if v152_.foldMiddleDirection > 0 then
			if v152_.foldAnimTime >= v152_.foldMiddleAnimTime - 0.01 then
				return -1
			end
		else
			if v152_.foldAnimTime <= v152_.foldMiddleAnimTime + 0.01 then
				return 1
			end
			v153_ = -1
		end
	end
	return v153_
end

-- Local values: spec
function Foldable:getIsVehicleControlAllowed()
	if self.spec_foldable.foldMoveDirection == 0 then
		return true, nil
	else
		return false, nil
	end
end

-- Local values: spec
function Foldable:allowLoadMovingToolStates(superFunc)
	local v157_ = self.spec_foldable
	if v157_.foldAnimTime > v157_.loadMovingToolStatesMaxLimit or v157_.foldAnimTime < v157_.loadMovingToolStatesMinLimit then
		return false
	else
		return superFunc(self)
	end
end

-- Local values: minFoldLimit, maxFoldLimit
function Foldable:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)
	if not superFunc(self, speedRotatingPart, xmlFile, key) then
		return false
	end
	speedRotatingPart.foldLimitedOuterRange = xmlFile:getValue(key .. "#foldLimitedOuterRange", false)
	local v163_, v164_
	if speedRotatingPart.foldLimitedOuterRange then
		v163_ = 0.5
		v164_ = 0.5
	else
		v163_ = 0
		v164_ = 1
	end
	speedRotatingPart.foldMinLimit = xmlFile:getValue(key .. "#foldMinLimit", v163_)
	speedRotatingPart.foldMaxLimit = xmlFile:getValue(key .. "#foldMaxLimit", v164_)
	return true
end

-- Local values: spec
function Foldable:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
	local v168_ = self.spec_foldable
	if speedRotatingPart.foldLimitedOuterRange then
		if v168_.foldAnimTime <= speedRotatingPart.foldMaxLimit and v168_.foldAnimTime > speedRotatingPart.foldMinLimit then
			return false
		end
	elseif v168_.foldAnimTime > speedRotatingPart.foldMaxLimit or v168_.foldAnimTime < speedRotatingPart.foldMinLimit then
		return false
	end
	return superFunc(self, speedRotatingPart)
end

function Foldable:loadSlopeCompensationNodeFromXML(superFunc, compensationNode, xmlFile, key)
	compensationNode.foldAngleScale = xmlFile:getValue(key .. "#foldAngleScale")
	compensationNode.invertFoldAngleScale = xmlFile:getValue(key .. "#invertFoldAngleScale", false)
	return superFunc(self, compensationNode, xmlFile, key)
end

-- Local values: scale, spec, animTime
function Foldable:getSlopeCompensationAngleScale(superFunc, compensationNode)
	local v177_ = superFunc(self, compensationNode)
	if compensationNode.foldAngleScale ~= nil then
		local v178_ = self.spec_foldable
		local v179_ = 1 - v178_.foldAnimTime
		if compensationNode.invertFoldAngleScale then
			v179_ = 1 - v179_
		end
		if v178_.foldMiddleAnimTime ~= nil then
			return v177_ * MathUtil.lerp(compensationNode.foldAngleScale, 1, v179_ / (1 - v178_.foldMiddleAnimTime))
		end
		v177_ = v177_ * MathUtil.lerp(compensationNode.foldAngleScale, 1, v179_)
	end
	return v177_
end

function Foldable:loadWheelFromXML(superFunc, wheel)
	wheel.versatileFoldMinLimit = wheel.xmlObject:getValue("#versatileFoldMinLimit", 0)
	wheel.versatileFoldMaxLimit = wheel.xmlObject:getValue("#versatileFoldMaxLimit", 1)
	return superFunc(self, wheel)
end

-- Local values: spec
function Foldable:getIsVersatileYRotActive(superFunc, wheel)
	local v186_ = self.spec_foldable
	if v186_.foldAnimTime > wheel.versatileFoldMaxLimit or v186_.foldAnimTime < wheel.versatileFoldMinLimit then
		return false
	else
		return superFunc(self, wheel)
	end
end

-- Local values: minFoldLimit, maxFoldLimit
function Foldable:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	workArea.foldLimitedOuterRange = xmlFile:getValue(key .. "#foldLimitedOuterRange", false)
	local v192_, v193_
	if workArea.foldLimitedOuterRange then
		v192_ = 0.5
		v193_ = 0.5
	else
		v192_ = 0
		v193_ = 1
	end
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#foldMinLimit", key .. ".folding#minLimit")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#foldMaxLimit", key .. ".folding#maxLimit")
	workArea.foldMinLimit = xmlFile:getValue(key .. ".folding#minLimit", v192_)
	workArea.foldMaxLimit = xmlFile:getValue(key .. ".folding#maxLimit", v193_)
	return superFunc(self, workArea, xmlFile, key)
end

-- Local values: spec
function Foldable:getIsWorkAreaActive(superFunc, workArea)
	local v197_ = self.spec_foldable
	if workArea.foldLimitedOuterRange then
		if v197_.foldAnimTime <= workArea.foldMaxLimit and v197_.foldAnimTime > workArea.foldMinLimit then
			return false
		end
	elseif v197_.foldAnimTime > workArea.foldMaxLimit or v197_.foldAnimTime < workArea.foldMinLimit then
		return false
	end
	return superFunc(self, workArea)
end

-- Local values: returnValue
function Foldable:loadGroundReferenceNode(superFunc, xmlFile, key, groundReferenceNode)
	local v203_ = superFunc(self, xmlFile, key, groundReferenceNode)
	if v203_ then
		groundReferenceNode.foldMinLimit = xmlFile:getValue(key .. ".folding#minLimit", 0)
		groundReferenceNode.foldMaxLimit = xmlFile:getValue(key .. ".folding#maxLimit", 1)
	end
	return v203_
end

-- Local values: foldAnimTime
function Foldable:updateGroundReferenceNode(superFunc, groundReferenceNode)
	superFunc(self, groundReferenceNode)
	local v207_ = self:getFoldAnimTime()
	if groundReferenceNode.foldMaxLimit < v207_ or v207_ < groundReferenceNode.foldMinLimit then
		groundReferenceNode.isActive = false
	end
end

-- Local values: minFoldLimit, maxFoldLimit
function Foldable:loadLevelerNodeFromXML(superFunc, levelerNode, xmlFile, key)
	levelerNode.foldLimitedOuterRange = xmlFile:getValue(key .. "#foldLimitedOuterRange", false)
	local v213_, v214_
	if levelerNode.foldLimitedOuterRange then
		v213_ = 0.5
		v214_ = 0.5
	else
		v213_ = 0
		v214_ = 1
	end
	levelerNode.foldMinLimit = xmlFile:getValue(key .. "#foldMinLimit", v213_)
	levelerNode.foldMaxLimit = xmlFile:getValue(key .. "#foldMaxLimit", v214_)
	return superFunc(self, levelerNode, xmlFile, key)
end

-- Local values: spec
function Foldable:getIsLevelerPickupNodeActive(superFunc, levelerNode)
	local v218_ = self.spec_foldable
	if levelerNode.foldLimitedOuterRange then
		if v218_.foldAnimTime <= levelerNode.foldMaxLimit and v218_.foldAnimTime > levelerNode.foldMinLimit then
			return false
		end
	elseif v218_.foldAnimTime > levelerNode.foldMaxLimit or v218_.foldAnimTime < levelerNode.foldMinLimit then
		return false
	end
	return superFunc(self, levelerNode)
end

-- Local values: foldingConfigurationIndex, foldingConfigurationIndices, i
function Foldable:loadMovingToolFromXML(superFunc, xmlFile, key, entry)
	if not superFunc(self, xmlFile, key, entry) then
		return false
	end
	entry.foldMinLimit = xmlFile:getValue(key .. "#foldMinLimit", 0)
	entry.foldMaxLimit = xmlFile:getValue(key .. "#foldMaxLimit", 1)
	entry.hasRequiredFoldingConfiguration = true
	if self.configurations.folding ~= nil then
		local v224_ = xmlFile:getValue(key .. "#foldingConfigurationIndex")
		if v224_ ~= nil and self.configurations.folding ~= v224_ then
			entry.hasRequiredFoldingConfiguration = false
		end
		local v225_ = xmlFile:getValue(key .. "#foldingConfigurationIndices", nil, true)
		if v225_ ~= nil and #v225_ > 0 then
			entry.hasRequiredFoldingConfiguration = false
			for v226_ = 1, #v225_ do
				if self.configurations.folding == v225_[v226_] then
					entry.hasRequiredFoldingConfiguration = true
					break
				end
			end
		end
	end
	return true
end

-- Local values: foldAnimTime
function Foldable:getIsMovingToolActive(superFunc, movingTool)
	if movingTool.hasRequiredFoldingConfiguration then
		local v230_ = self:getFoldAnimTime()
		if movingTool.foldMaxLimit < v230_ or v230_ < movingTool.foldMinLimit then
			return false
		else
			return superFunc(self, movingTool)
		end
	else
		return false
	end
end

function Foldable:loadMovingPartFromXML(superFunc, xmlFile, key, entry)
	if not superFunc(self, xmlFile, key, entry) then
		return false
	end
	entry.foldMinLimit = xmlFile:getValue(key .. "#foldMinLimit", 0)
	entry.foldMaxLimit = xmlFile:getValue(key .. "#foldMaxLimit", 1)
	return true
end

-- Local values: foldAnimTime
function Foldable:getIsMovingPartActive(superFunc, movingPart)
	if movingPart.foldMaxLimit ~= 1 or movingPart.foldMinLimit ~= 0 then
		local v239_ = self:getFoldAnimTime()
		if movingPart.foldMaxLimit < v239_ or v239_ < movingPart.foldMinLimit then
			return false
		end
	end
	return superFunc(self, movingPart)
end

-- Local values: spec
function Foldable:getCanBeTurnedOn(superFunc)
	local v242_ = self.spec_foldable
	if v242_.foldAnimTime > v242_.turnOnFoldMaxLimit or v242_.foldAnimTime < v242_.turnOnFoldMinLimit then
		return false
	else
		return superFunc(self)
	end
end

-- Local values: spec
function Foldable:getIsNextCoverStateAllowed(superFunc, nextState)
	if not superFunc(self, nextState) then
		return false
	end
	local v246_ = self.spec_foldable
	return v246_.foldAnimTime <= v246_.toggleCoverMaxLimit and v246_.foldAnimTime >= v246_.toggleCoverMinLimit
end

-- Local values: spec
function Foldable:getIsNextCoverStateAllowedWarning(superFunc, nextState)
	local v250_ = self.spec_foldable
	if v250_.foldAnimTime > v250_.toggleCoverMaxLimit or v250_.foldAnimTime < v250_.toggleCoverMinLimit then
		return v250_.unfoldWarning
	else
		return superFunc(self, nextState)
	end
end

-- Local values: spec
function Foldable:getIsInWorkPosition(superFunc)
	local v253_ = self.spec_foldable
	if v253_.turnOnFoldDirection == 0 or (#v253_.foldingParts == 0 or v253_.turnOnFoldDirection == -1 and v253_.foldAnimTime == 0) or v253_.turnOnFoldDirection == 1 and v253_.foldAnimTime == 1 then
		return superFunc(self)
	else
		return false
	end
end

-- Local values: spec
function Foldable:getTurnedOnNotAllowedWarning(superFunc)
	local v256_ = self.spec_foldable
	if v256_.foldAnimTime > v256_.turnOnFoldMaxLimit or v256_.foldAnimTime < v256_.turnOnFoldMinLimit then
		return v256_.unfoldWarning
	else
		return superFunc(self)
	end
end

-- Local values: spec
function Foldable:isDetachAllowed(superFunc)
	local v259_ = self.spec_foldable
	if v259_.foldAnimTime > v259_.detachingMaxLimit or v259_.foldAnimTime < v259_.detachingMinLimit then
		return false, v259_.unfoldWarning
	end
	if not v259_.allowDetachingWhileFolding then
		if v259_.foldMiddleAnimTime == nil then
			::l7::
			if v259_.foldAnimTime > 0 and v259_.foldAnimTime < 1 then
				return false, v259_.detachWarning
			end
			goto l5
		end
		local v260_ = v259_.foldAnimTime - v259_.foldMiddleAnimTime
		if math.abs(v260_) > 0.001 then
			goto l7
		end
	end
	::l5::
	return superFunc(self)
end

-- Local values: spec
function Foldable:isAttachAllowed(superFunc, farmId, attacherVehicle)
	local v265_ = self.spec_foldable
	if v265_.foldAnimTime > v265_.attachingMaxLimit or v265_.foldAnimTime < v265_.attachingMinLimit then
		return false, v265_.unfoldWarning
	else
		return superFunc(self, farmId, attacherVehicle)
	end
end

-- Local values: spec
function Foldable:getAllowsLowering(superFunc)
	local v268_ = self.spec_foldable
	if v268_.foldAnimTime > v268_.loweringMaxLimit or v268_.foldAnimTime < v268_.loweringMinLimit then
		return false, v268_.unfoldWarning
	else
		return superFunc(self)
	end
end

-- Local values: spec, ignoreFoldMiddle
function Foldable:getIsLowered(superFunc, default)
	local v272_ = self.spec_foldable
	if not self:getIsFoldMiddleAllowed() or (v272_.foldMiddleAnimTime == nil or v272_.foldMiddleInputButton == nil) then
		return superFunc(self, default)
	end
	if v272_.ignoreFoldMiddleWhileFolded and self:getFoldAnimTime() > v272_.foldMiddleAnimTime and true or false then
		return superFunc(self, default)
	end
	if v272_.foldMoveDirection == 0 then
		if v272_.foldMiddleDirection > 0 and v272_.foldAnimTime < 0.01 then
			return true
		end
		if v272_.foldMiddleDirection < 0 then
			local v273_ = 1 - v272_.foldAnimTime
			if math.abs(v273_) < 0.01 then
				return true
			end
		end
	elseif v272_.foldMiddleDirection > 0 then
		if v272_.foldAnimTime < v272_.foldMiddleAnimTime + 0.01 then
			local v274_
			if v272_.foldMoveDirection < 0 then
				v274_ = v272_.moveToMiddle ~= true
			else
				v274_ = false
			end
			return v274_
		end
	elseif v272_.foldAnimTime > v272_.foldMiddleAnimTime - 0.01 then
		local v275_
		if v272_.foldMoveDirection > 0 then
			v275_ = v272_.moveToMiddle ~= true
		else
			v275_ = false
		end
		return v275_
	end
	return false
end

-- Local values: spec, state, actionEventId
function Foldable:registerLoweringActionEvent(superFunc, actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, ignoreCollisions)
	local v289_ = self.spec_foldable
	if v289_.hasFoldingParts and v289_.foldMiddleAnimTime ~= nil then
		self:clearActionEventsTable(v289_.actionEventsLowering)
		local v290_, v291_
		if v289_.requiresPower then
			v290_, v291_ = self:addPoweredActionEvent(v289_.actionEventsLowering, v289_.foldMiddleInputButton, self, Foldable.actionEventFoldMiddle, false, true, false, true, nil, nil, ignoreCollisions)
		else
			v290_, v291_ = self:addActionEvent(v289_.actionEventsLowering, v289_.foldMiddleInputButton, self, Foldable.actionEventFoldMiddle, false, true, false, true, nil, nil, ignoreCollisions)
		end
		g_inputBinding:setActionEventTextPriority(v291_, GS_PRIO_HIGH)
		Foldable.updateActionEventFoldMiddle(self)
		if v289_.foldMiddleInputButton == inputAction then
			return v290_, v291_
		end
	end
	return superFunc(self, actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName)
end

function Foldable:registerSelfLoweringActionEvent(superFunc, actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, ignoreCollisions)
	return Foldable.registerLoweringActionEvent(self, superFunc, actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, ignoreCollisions)
end

function Foldable:loadGroundAdjustedNodeFromXML(superFunc, xmlFile, key, adjustedNode)
	if not superFunc(self, xmlFile, key, adjustedNode) then
		return false
	end
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#foldMinLimit", key .. ".foldable#minLimit")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#foldMaxLimit", key .. ".foldable#maxLimit")
	adjustedNode.foldMinLimit = xmlFile:getValue(key .. ".foldable#minLimit", 0)
	adjustedNode.foldMaxLimit = xmlFile:getValue(key .. ".foldable#maxLimit", 1)
	return true
end

-- Local values: spec, foldAnimTime
function Foldable:getIsGroundAdjustedNodeActive(superFunc, adjustedNode, ignoreAttachState)
	local v314_ = self.spec_foldable.foldAnimTime
	if v314_ == nil or adjustedNode.foldMaxLimit >= v314_ and v314_ >= adjustedNode.foldMinLimit then
		return superFunc(self, adjustedNode, ignoreAttachState)
	else
		return false
	end
end

-- Local values: foldingConfigurationIndex, foldingConfigurationIndices, i
function Foldable:loadSprayTypeFromXML(superFunc, xmlFile, key, sprayType)
	sprayType.foldMinLimit = xmlFile:getValue(key .. "#foldMinLimit")
	sprayType.foldMaxLimit = xmlFile:getValue(key .. "#foldMaxLimit")
	sprayType.hasRequiredFoldingConfiguration = true
	if self.configurations.folding ~= nil then
		local v320_ = xmlFile:getValue(key .. "#foldingConfigurationIndex")
		if v320_ ~= nil and self.configurations.folding ~= v320_ then
			sprayType.hasRequiredFoldingConfiguration = false
		end
		local v321_ = xmlFile:getValue(key .. "#foldingConfigurationIndices", nil, true)
		if v321_ ~= nil and #v321_ > 0 then
			sprayType.hasRequiredFoldingConfiguration = false
			for v322_ = 1, #v321_ do
				if self.configurations.folding == v321_[v322_] then
					sprayType.hasRequiredFoldingConfiguration = true
					break
				end
			end
		end
	end
	return superFunc(self, xmlFile, key, sprayType)
end

-- Local values: spec, foldAnimTime
function Foldable:getIsSprayTypeActive(superFunc, sprayType)
	local v326_ = self.spec_foldable
	if sprayType.foldMinLimit ~= nil and sprayType.foldMaxLimit ~= nil then
		local v327_ = v326_.foldAnimTime
		if v327_ ~= nil and (sprayType.foldMaxLimit < v327_ or v327_ < sprayType.foldMinLimit) then
			return false
		end
	end
	if sprayType.hasRequiredFoldingConfiguration then
		return superFunc(self, sprayType)
	else
		return false
	end
end

function Foldable:getCanBeSelected(superFunc)
	return true
end

function Foldable:loadInputAttacherJoint(superFunc, xmlFile, key, inputAttacherJoint, index)
	inputAttacherJoint.foldMinLimit = xmlFile:getValue(key .. "#foldMinLimit")
	inputAttacherJoint.foldMaxLimit = xmlFile:getValue(key .. "#foldMaxLimit")
	return superFunc(self, xmlFile, key, inputAttacherJoint, index)
end

-- Local values: foldAnimTime
function Foldable:getIsInputAttacherActive(superFunc, inputAttacherJoint)
	if inputAttacherJoint.foldMinLimit ~= nil and inputAttacherJoint.foldMaxLimit ~= nil then
		local v337_ = self:getFoldAnimTime()
		if v337_ < inputAttacherJoint.foldMinLimit or inputAttacherJoint.foldMaxLimit < v337_ then
			return false
		end
	end
	return superFunc(self, inputAttacherJoint)
end

-- Local values: spec
function Foldable:loadAdditionalCharacterFromXML(superFunc, xmlFile)
	local v341_ = self.spec_enterable
	v341_.additionalCharacterFoldMinLimit = xmlFile:getValue("vehicle.enterable.additionalCharacter#foldMinLimit")
	v341_.additionalCharacterFoldMaxLimit = xmlFile:getValue("vehicle.enterable.additionalCharacter#foldMaxLimit")
	return superFunc(self, xmlFile)
end

-- Local values: spec, foldAnimTime
function Foldable:getIsAdditionalCharacterActive(superFunc)
	local v344_ = self.spec_enterable
	if v344_.additionalCharacterFoldMinLimit ~= nil and v344_.additionalCharacterFoldMaxLimit ~= nil then
		local v345_ = self:getFoldAnimTime()
		if v344_.additionalCharacterFoldMinLimit <= v345_ and v345_ <= v344_.additionalCharacterFoldMaxLimit then
			return true
		end
	end
	return superFunc(self)
end

-- Local values: spec, foldAnimTime
function Foldable:getAllowDynamicMountObjects(superFunc)
	local v348_ = self.spec_foldable
	local v349_ = self:getFoldAnimTime()
	if v349_ < v348_.dynamicMountMinLimit or v348_.dynamicMountMaxLimit < v349_ then
		return false
	else
		return superFunc(self)
	end
end

function Foldable:loadSupportAnimationFromXML(superFunc, supportAnimation, xmlFile, key)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#foldMinLimit", key .. ".folding#minLimit")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#foldMaxLimit", key .. ".folding#maxLimit")
	supportAnimation.foldMinLimit = xmlFile:getValue(key .. ".folding#minLimit", 0)
	supportAnimation.foldMaxLimit = xmlFile:getValue(key .. ".folding#maxLimit", 1)
	return superFunc(self, supportAnimation, xmlFile, key)
end

-- Local values: foldAnimTime
function Foldable:getIsSupportAnimationAllowed(superFunc, supportAnimation)
	local v358_ = self:getFoldAnimTime()
	if v358_ < supportAnimation.foldMinLimit or supportAnimation.foldMaxLimit < v358_ then
		return false
	else
		return superFunc(self, supportAnimation)
	end
end

function Foldable:loadSteeringAxleFromXML(superFunc, spec, xmlFile, key)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#foldMinLimit", key .. ".folding#minLimit")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#foldMaxLimit", key .. ".folding#maxLimit")
	spec.foldMinLimit = xmlFile:getValue(key .. ".folding#minLimit", 0)
	spec.foldMaxLimit = xmlFile:getValue(key .. ".folding#maxLimit", 1)
	return superFunc(self, spec, xmlFile, key)
end

-- Local values: spec, foldAnimTime
function Foldable:getIsSteeringAxleAllowed(superFunc)
	local v366_ = self.spec_attachable
	local v367_ = self:getFoldAnimTime()
	if v367_ < v366_.foldMinLimit or v366_.foldMaxLimit < v367_ then
		return false
	else
		return superFunc(self)
	end
end

function Foldable:loadFillUnitFromXML(superFunc, xmlFile, key, entry, index)
	entry.foldMinLimit = xmlFile:getValue(key .. "#foldMinLimit", 0)
	entry.foldMaxLimit = xmlFile:getValue(key .. "#foldMaxLimit", 1)
	return superFunc(self, xmlFile, key, entry, index)
end

-- Local values: fillUnit, foldAnimTime
function Foldable:getFillUnitSupportsToolType(superFunc, fillUnitIndex, toolType)
	if toolType ~= ToolType.UNDEFINED then
		local v378_ = self.spec_fillUnit.fillUnits[fillUnitIndex]
		if v378_ ~= nil and (v378_.foldMinLimit ~= nil and v378_.foldMaxLimit ~= nil) then
			local v379_ = self:getFoldAnimTime()
			if v379_ < v378_.foldMinLimit or v378_.foldMaxLimit < v379_ then
				return false
			end
		end
	end
	return superFunc(self, fillUnitIndex, toolType)
end

function Foldable:loadTurnedOnAnimationFromXML(superFunc, xmlFile, key, turnedOnAnimation)
	turnedOnAnimation.foldMinLimit = xmlFile:getValue(key .. "#foldMinLimit", 0)
	turnedOnAnimation.foldMaxLimit = xmlFile:getValue(key .. "#foldMaxLimit", 1)
	return superFunc(self, xmlFile, key, turnedOnAnimation)
end

-- Local values: foldAnimTime
function Foldable:getIsTurnedOnAnimationActive(superFunc, turnedOnAnimation)
	local v388_ = self:getFoldAnimTime()
	if v388_ < turnedOnAnimation.foldMinLimit or turnedOnAnimation.foldMaxLimit < v388_ then
		return false
	else
		return superFunc(self, turnedOnAnimation)
	end
end

function Foldable:loadAttacherJointHeightNode(superFunc, xmlFile, key, heightNode, attacherJointNode)
	heightNode.foldMinLimit = xmlFile:getValue(key .. "#foldMinLimit", 0)
	heightNode.foldMaxLimit = xmlFile:getValue(key .. "#foldMaxLimit", 1)
	return superFunc(self, xmlFile, key, heightNode, attacherJointNode)
end

-- Local values: foldAnimTime
function Foldable:getIsAttacherJointHeightNodeActive(superFunc, heightNode)
	local v398_ = self:getFoldAnimTime()
	if v398_ < heightNode.foldMinLimit or heightNode.foldMaxLimit < v398_ then
		return false
	else
		return superFunc(self, heightNode)
	end
end

function Foldable:loadPickupFromXML(superFunc, xmlFile, key, spec)
	spec.foldMinLimit = xmlFile:getValue(key .. "#foldMinLimit", 0)
	spec.foldMaxLimit = xmlFile:getValue(key .. "#foldMaxLimit", 1)
	return superFunc(self, xmlFile, key, spec)
end

-- Local values: foldAnimTime
function Foldable:getCanChangePickupState(superFunc, spec, newState)
	local v408_ = self:getFoldAnimTime()
	if v408_ < spec.foldMinLimit or spec.foldMaxLimit < v408_ then
		return false
	else
		return superFunc(self, spec, newState)
	end
end

function Foldable:loadCutterTiltFromXML(superFunc, xmlFile, key, target)
	if not superFunc(self, xmlFile, key, target) then
		return false
	end
	target.foldMinLimit = xmlFile:getValue(key .. "#foldMinLimit", 0)
	target.foldMaxLimit = xmlFile:getValue(key .. "#foldMaxLimit", 1)
	return true
end

-- Local values: isActive, doReset, foldAnimTime
function Foldable:getCutterTiltIsActive(superFunc, automaticTilt)
	local v417_, v418_ = superFunc(self, automaticTilt)
	if v417_ then
		local v419_ = self:getFoldAnimTime()
		if v419_ < automaticTilt.foldMinLimit or automaticTilt.foldMaxLimit < v419_ then
			return false, true
		else
			return true, false
		end
	else
		return v417_, v418_
	end
end

function Foldable:loadPreprunerNodeFromXML(superFunc, xmlFile, key, prunerNode)
	if not superFunc(self, xmlFile, key, prunerNode) then
		return false
	end
	prunerNode.foldMinLimit = xmlFile:getValue(key .. "#foldMinLimit", 0)
	prunerNode.foldMaxLimit = xmlFile:getValue(key .. "#foldMaxLimit", 1)
	return true
end

-- Local values: foldAnimTime
function Foldable:getIsPreprunerNodeActive(superFunc, prunerNode)
	local v428_ = self:getFoldAnimTime()
	if v428_ < prunerNode.foldMinLimit or prunerNode.foldMaxLimit < v428_ then
		return false
	else
		return superFunc(self, prunerNode)
	end
end

function Foldable:loadShovelNode(superFunc, xmlFile, key, shovelNode)
	superFunc(self, xmlFile, key, shovelNode)
	shovelNode.foldMinLimit = xmlFile:getValue(key .. "#foldMinLimit", 0)
	shovelNode.foldMaxLimit = xmlFile:getValue(key .. "#foldMaxLimit", 1)
	return true
end

-- Local values: foldAnimTime
function Foldable:getShovelNodeIsActive(superFunc, shovelNode)
	local v437_ = self:getFoldAnimTime()
	if v437_ < shovelNode.foldMinLimit or shovelNode.foldMaxLimit < v437_ then
		return false
	else
		return superFunc(self, shovelNode)
	end
end

function Foldable:loadSteeringAngleNodeFromXML(superFunc, entry, xmlFile, key)
	if not superFunc(self, entry, xmlFile, key) then
		return false
	end
	entry.foldMinLimit = xmlFile:getValue(key .. "#foldMinLimit", 0)
	entry.foldMaxLimit = xmlFile:getValue(key .. "#foldMaxLimit", 1)
	return true
end

-- Local values: foldAnimTime
function Foldable:updateSteeringAngleNode(superFunc, steeringAngleNode, angle, dt)
	local v448_ = self:getFoldAnimTime()
	if v448_ >= steeringAngleNode.foldMinLimit and steeringAngleNode.foldMaxLimit >= v448_ then
		return superFunc(self, steeringAngleNode, angle, dt)
	end
end

function Foldable:loadWoodHarvesterHeaderTiltFromXML(superFunc, headerTilt, xmlFile, key)
	if not superFunc(self, headerTilt, xmlFile, key) then
		return false
	end
	headerTilt.foldMinLimit = xmlFile:getValue(key .. "#foldMinLimit", 0)
	headerTilt.foldMaxLimit = xmlFile:getValue(key .. "#foldMaxLimit", 1)
	return true
end

-- Local values: foldAnimTime
function Foldable:getIsWoodHarvesterTiltStateAllowed(superFunc, headerTilt)
	local v457_ = self:getFoldAnimTime()
	if v457_ < headerTilt.foldMinLimit or headerTilt.foldMaxLimit < v457_ then
		return false
	else
		return superFunc(self, headerTilt)
	end
end

function Foldable:loadSuspensionNodeFromXML(superFunc, xmlFile, key, suspensionNode)
	if not superFunc(self, xmlFile, key, suspensionNode) then
		return false
	end
	suspensionNode.foldMinLimit = xmlFile:getValue(key .. "#foldMinLimit", 0)
	suspensionNode.foldMaxLimit = xmlFile:getValue(key .. "#foldMaxLimit", 1)
	return true
end

-- Local values: foldAnimTime
function Foldable:getIsSuspensionNodeActive(superFunc, suspensionNode)
	local v466_ = self:getFoldAnimTime()
	if v466_ < suspensionNode.foldMinLimit or suspensionNode.foldMaxLimit < v466_ then
		return false
	else
		return superFunc(self, suspensionNode)
	end
end

function Foldable:loadCrabSteeringModeFromXML(superFunc, xmlFile, key, mode)
	if not superFunc(self, xmlFile, key, mode) then
		return false
	end
	mode.foldMinLimit = xmlFile:getValue(key .. ".folding#minLimit", 0)
	mode.foldMaxLimit = xmlFile:getValue(key .. ".folding#maxLimit", 1)
	return true
end

-- Local values: foldAnimTime
function Foldable:getCrabSteeringModeAvailable(superFunc, mode)
	local v475_ = self:getFoldAnimTime()
	if v475_ < mode.foldMinLimit or mode.foldMaxLimit < v475_ then
		return false
	else
		return superFunc(self, mode)
	end
end

-- Local values: spec, foldAnimTime
function Foldable:getCanToggleCrabSteering(superFunc)
	local v478_ = self.spec_foldable
	local v479_ = self:getFoldAnimTime()
	if v479_ < v478_.crabSteeringMinLimit or v478_.crabSteeringMaxLimit < v479_ then
		return false, v478_.unfoldWarning
	else
		return superFunc(self)
	end
end

function Foldable:onLoadWheelChockFromXML(superFunc, wheelChock, xmlObject, key)
	superFunc(self)
	wheelChock.foldMinLimit = xmlObject:getValue(key .. "#foldMinLimit", 0)
	wheelChock.foldMaxLimit = xmlObject:getValue(key .. "#foldMaxLimit", 1)
end

-- Local values: foldAnimTime
function Foldable:getIsWheelChockAllowed(superFunc, wheelChock)
	local v488_ = self:getFoldAnimTime()
	if v488_ == nil or v488_ >= wheelChock.foldMinLimit and wheelChock.foldMaxLimit >= v488_ then
		return superFunc(self)
	else
		return false
	end
end

function Foldable:loadCraneShovelFromXML(superFunc, spec, xmlFile, key)
	if not superFunc(self, spec, xmlFile, key) then
		return false
	end
	spec.foldableMinLimit = xmlFile:getValue(key .. ".foldable#minLimit", 0)
	spec.foldableMaxLimit = xmlFile:getValue(key .. ".foldable#maxLimit", 1)
	return true
end

-- Local values: foldAnimTime
function Foldable:getCraneShovelStateChangedAllowed(superFunc, spec)
	local v497_ = self:getFoldAnimTime()
	if v497_ == nil or v497_ >= spec.foldableMinLimit and spec.foldableMaxLimit >= v497_ then
		return superFunc(self, spec)
	else
		return false, self.spec_foldable.unfoldWarning
	end
end

-- Local values: spec
function Foldable:getBrakeForce(superFunc)
	local v500_ = self.spec_foldable
	return v500_.releaseBrakesWhileFolding and v500_.foldMoveDirection ~= 0 and 0 or superFunc(self)
end

function Foldable:getRequiresPower(superFunc)
	return self.spec_foldable.foldMoveDirection ~= 0 and true or superFunc(self)
end

-- Local values: spec, isOnlyLowering, _, actionEventId
function Foldable:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v505_ = self.spec_foldable
		self:clearActionEventsTable(v505_.actionEvents)
		if isActiveForInputIgnoreSelection then
			local v506_
			if v505_.foldMiddleAnimTime == nil then
				v506_ = false
			else
				v506_ = v505_.foldMiddleAnimTime == 1
			end
			if not v506_ then
				local v507_
				if v505_.requiresPower then
					local v508_
					v508_, v507_ = self:addPoweredActionEvent(v505_.actionEvents, v505_.foldInputButton, self, Foldable.actionEventFold, false, true, false, true, nil)
				else
					local v509_
					v509_, v507_ = self:addActionEvent(v505_.actionEvents, v505_.foldInputButton, self, Foldable.actionEventFold, false, true, false, true, nil)
				end
				g_inputBinding:setActionEventTextPriority(v507_, GS_PRIO_HIGH)
				Foldable.updateActionEventFold(self)
				local _, v510_ = self:addPoweredActionEvent(v505_.actionEvents, InputAction.FOLD_ALL_IMPLEMENTS, self, Foldable.actionEventFoldAll, false, true, false, true, nil)
				g_inputBinding:setActionEventTextVisibility(v510_, false)
			end
		end
	end
end

-- Local values: spec
function Foldable:onRegisterExternalActionEvents(trigger, name, xmlFile, key)
	if name == "folding" and self.spec_foldable.hasFoldingParts then
		self:registerExternalActionEvent(trigger, name, Foldable.externalActionEventRegister, Foldable.externalActionEventUpdate)
	end
end

-- Local values: canContinue, stopAI, stopReason, spec
function Foldable:getCanAIImplementContinueWork(superFunc, isTurning)
	local v517_, v518_, v519_ = superFunc(self, isTurning)
	if not v517_ then
		return false, v518_, v519_
	end
	local v520_ = self.spec_foldable
	if v520_.hasFoldingParts and v520_.allowUnfoldingByAI then
		if v520_.foldMiddleAnimTime == nil then
			if v520_.foldAnimTime ~= 0 and v520_.foldAnimTime ~= 1 then
				return false
			end
		else
			local v521_ = v520_.foldAnimTime - v520_.foldMiddleAnimTime
			if math.abs(v521_) > 0.001 and (v520_.foldAnimTime ~= 0 and v520_.foldAnimTime ~= 1) then
				return v520_.foldAnimTime > 0 and (v520_.foldAnimTime < v520_.foldMiddleAnimTime and v520_.foldMoveDirection > 0)
			end
		end
	end
	return v517_
end

-- Local values: spec
function Foldable:getIsAIReadyToDrive(superFunc)
	local v524_ = self.spec_foldable
	if v524_.hasFoldingParts and v524_.allowUnfoldingByAI then
		if v524_.turnOnFoldDirection > 0 then
			if v524_.foldAnimTime > 0 then
				return false
			end
		elseif v524_.foldAnimTime < 1 then
			return false
		end
	end
	return superFunc(self)
end

-- Local values: spec
function Foldable:getIsAIPreparingToDrive(superFunc)
	local v527_ = self.spec_foldable
	return v527_.hasFoldingParts and (v527_.allowUnfoldingByAI and (v527_.foldAnimTime ~= v527_.foldMiddleAnimTime and (v527_.foldAnimTime ~= 0 and v527_.foldAnimTime ~= 1))) and true or superFunc(self)
end

-- Local values: spec
function Foldable:onDeactivate()
	local v529_ = self.spec_foldable
	if not (v529_.keepFoldingWhileDetached or (v529_.lowerWhileDetach or v529_.foldWhileDetach)) then
		self:setFoldDirection(0, true)
	end
end

function Foldable:onSetLoweredAll(doLowering, jointDescIndex)
	self:setFoldMiddleState(doLowering)
end

-- Local values: spec, jointDesc
function Foldable:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	if self.spec_foldable.lowerWhileDetach and (attacherVehicle ~= nil and (not attacherVehicle:getAttacherJointByJointDescIndex(jointDescIndex).moveDown and self:getFoldAnimTime() < 0.001)) then
		self:setFoldState(1, true, true)
	end
end

-- Local values: spec, actionController
function Foldable:onRootVehicleChanged(rootVehicle)
	local v_u_537_ = self.spec_foldable
	if v_u_537_.hasFoldingParts then
		local v538_ = rootVehicle.actionController
		if v538_ == nil then
			if v_u_537_.controlledActionFold ~= nil then
				v_u_537_.controlledActionFold:remove()
			end
			if v_u_537_.controlledActionLower ~= nil then
				v_u_537_.controlledActionLower:remove()
			end
			if v_u_537_.controlledActionLowerAIStart ~= nil then
				v_u_537_.controlledActionLowerAIStart:remove()
			end
		else
			if v_u_537_.controlledActionFold ~= nil then
				v_u_537_.controlledActionFold:updateParent(v538_)
				if v_u_537_.controlledActionLower ~= nil then
					v_u_537_.controlledActionLower:updateParent(v538_)
				end
				if v_u_537_.controlledActionLowerAIStart ~= nil then
					v_u_537_.controlledActionLowerAIStart:updateParent(v538_)
				end
				return
			end
			v_u_537_.controlledActionFold = v538_:registerAction("fold", v_u_537_.toggleTurnOnInputBinding, 4)
			v_u_537_.controlledActionFold:setCallback(self, Foldable.actionControllerFoldEvent)
			v_u_537_.controlledActionFold:setFinishedFunctions(self, function(p539_)
				-- upvalues: (copy) v_u_537_
				if v_u_537_.turnOnFoldDirection < 0 then
					local v540_ = p539_:getFoldAnimTime()
					return v540_ == 1 and true or v540_ <= (v_u_537_.foldMiddleAnimTime or 0)
				else
					local v541_ = p539_:getFoldAnimTime()
					return v541_ == 0 and true or (v_u_537_.foldMiddleAnimTime or 1) <= v541_
				end
			end, true, true)
			if v_u_537_.allowUnfoldingByAI then
				v_u_537_.controlledActionFold:addAIEventListener(self, "onAIFieldWorkerPrepareForWork", 1)
				v_u_537_.controlledActionFold:addAIEventListener(self, "onAIImplementPrepareForWork", 1)
				v_u_537_.controlledActionFold:addAIEventListener(self, "onAIImplementPrepareForTransport", -1, true)
				if Platform.gameplay.foldAfterAIFinished then
					v_u_537_.controlledActionFold:addAIEventListener(self, "onAIImplementEnd", -1, true)
					v_u_537_.controlledActionFold:addAIEventListener(self, "onAIFieldWorkerEnd", -1)
				end
			end
			if self:getIsFoldMiddleAllowed() then
				v_u_537_.controlledActionLower = v538_:registerAction("lowerFoldable", v_u_537_.toggleTurnOnInputBinding, 3)
				v_u_537_.controlledActionLower:setCallback(self, Foldable.actionControllerLowerEvent)
				v_u_537_.controlledActionLower:setFinishedFunctions(self, self.getFoldAnimTime, v_u_537_.turnOnFoldDirection < 0 and 0 or 1, v_u_537_.foldMiddleAnimTime)
				v_u_537_.controlledActionLower:setResetOnDeactivation(false)
				if v_u_537_.allowUnfoldingByAI then
					v_u_537_.controlledActionLower:addAIEventListener(self, "onAIImplementStartLine", 1)
					v_u_537_.controlledActionLower:addAIEventListener(self, "onAIImplementEndLine", -1)
				end
				v_u_537_.controlledActionLowerAIStart = v538_:registerAction("lowerFoldableAIStart", v_u_537_.toggleTurnOnInputBinding, 3)
				v_u_537_.controlledActionLowerAIStart:setCallback(self, Foldable.actionControllerLowerEventAIStart)
				v_u_537_.controlledActionLowerAIStart:setFinishedFunctions(self, self.getFoldAnimTime, v_u_537_.turnOnFoldDirection < 0 and 0 or 1, v_u_537_.foldMiddleAnimTime)
				v_u_537_.controlledActionLowerAIStart:setResetOnDeactivation(false)
				if v_u_537_.allowUnfoldingByAI then
					v_u_537_.controlledActionLowerAIStart:addAIEventListener(self, "onAIImplementStart", -1)
					return
				end
			end
		end
	end
end

-- Local values: spec
function Foldable:actionControllerFoldEvent(direction)
	local v544_ = self.spec_foldable
	if v544_.hasFoldingParts then
		if self:getIsFoldMiddleAllowed() and (v544_.foldAnimTime > 0 and v544_.foldAnimTime < v544_.foldMiddleAnimTime) then
			return false
		end
		local v545_ = v544_.turnOnFoldDirection * direction
		if self:getIsFoldAllowed(v545_, false) then
			if v545_ == v544_.turnOnFoldDirection then
				if v545_ < 0 and v544_.foldAnimTime > 0 or v545_ > 0 and v544_.foldAnimTime < 1 then
					self:setFoldState(v545_, true)
				end
			elseif v545_ < 0 and v544_.foldAnimTime > 0 or v545_ > 0 and v544_.foldAnimTime < 1 then
				self:setFoldState(v545_, false)
			end
			return true
		end
	end
	return false
end

-- Local values: spec
function Foldable:actionControllerLowerEvent(direction)
	local v548_ = self.spec_foldable
	if v548_.hasFoldingParts then
		local v549_ = v548_.turnOnFoldDirection * direction
		if self:getIsFoldMiddleAllowed() then
			if v549_ == v548_.turnOnFoldDirection then
				self:setFoldState(v549_, false)
			elseif v548_.foldMiddleDirection > 0 then
				if v548_.foldAnimTime > v548_.foldMiddleAnimTime then
					self:setFoldState(-v549_, true)
				else
					self:setFoldState(v549_, true)
				end
			elseif v548_.foldAnimTime < v548_.foldMiddleAnimTime then
				self:setFoldState(-v549_, true)
			else
				self:setFoldState(v549_, true)
			end
			return true
		end
	end
	return false
end

-- Local values: spec
function Foldable:actionControllerLowerEventAIStart(direction)
	local v552_ = self.spec_foldable
	if v552_.hasFoldingParts then
		local v553_ = v552_.turnOnFoldDirection * direction
		if self:getIsFoldMiddleAllowed() then
			if v552_.foldAnimTime >= v552_.foldMiddleAnimTime then
				return true
			end
			if v552_.foldMiddleDirection > 0 then
				if v552_.foldAnimTime > v552_.foldMiddleAnimTime then
					self:setFoldState(-v553_, true)
				else
					self:setFoldState(v553_, true)
				end
			elseif v552_.foldAnimTime < v552_.foldMiddleAnimTime then
				self:setFoldState(-v553_, true)
			else
				self:setFoldState(v553_, true)
			end
		end
	end
	return true
end

-- Local values: spec, foldAnimTime
function Foldable:onPreDetach(attacherVehicle, implement)
	local v555_ = self.spec_foldable
	if v555_.lowerWhileDetach and v555_.foldMiddleAnimTime ~= nil then
		local v556_ = self:getFoldAnimTime() - v555_.foldMiddleAnimTime
		if math.abs(v556_) < 0.001 then
			self:setFoldState(-1, false, true)
			return
		end
	elseif v555_.foldWhileDetach then
		self:setFoldState(-v555_.turnOnFoldDirection, false, true)
	end
end

-- Local values: subSpec
function Foldable:onPreAttachImplement(object, inputJointDescIndex, jointDescIndex, loadFromSavegame)
	local v559_ = object.spec_foldable
	if v559_ ~= nil and v559_.useParentFoldingState then
		self.spec_foldable.subFoldingStateVehicles[object] = object
		Foldable.setAnimTime(object, self.spec_foldable.foldAnimTime, false)
	end
end

-- Local values: subSpec
function Foldable:onPreDetachImplement(implement)
	local v562_ = implement.object.spec_foldable
	if v562_ ~= nil and v562_.useParentFoldingState then
		self.spec_foldable.subFoldingStateVehicles[implement.object] = nil
	end
end

function Foldable:onDynamicMountTypeChanged(dynamicMountType, mountObject)
	if dynamicMountType ~= MountableObject.MOUNT_TYPE_NONE then
		self:setFoldDirection(0, true)
	end
end

-- Local values: spec, _, foldingPart, _, foldingPart, componentJoint, jointNode, node, x, y, z, upX, upY, upZ, dirX, dirY, dirZ, _, vehicle
function Foldable:setAnimTime(animTime, placeComponents, playSounds)
	local v569_ = self.spec_foldable
	v569_.foldAnimTime = animTime
	v569_.loadedFoldAnimTime = nil
	for _, v570_ in pairs(v569_.foldingParts) do
		if v570_.animCharSet == 0 then
			animTime = v569_.foldAnimTime * v569_.maxFoldAnimDuration / self:getAnimationDuration(v570_.animationName)
			self:setAnimationTime(v570_.animationName, animTime, true, playSounds)
		else
			enableAnimTrack(v570_.animCharSet, 0)
			setAnimTrackTime(v570_.animCharSet, 0, v569_.foldAnimTime * v570_.animDuration, true)
			disableAnimTrack(v570_.animCharSet, 0)
		end
	end
	local v571_ = placeComponents == nil and true or placeComponents
	if self.updateCylinderedInitial ~= nil then
		self:updateCylinderedInitial(v571_)
	end
	if v571_ and self.isServer then
		for _, v572_ in pairs(v569_.foldingParts) do
			if v572_.componentJoint ~= nil then
				local v573_ = v572_.componentJoint
				local v574_ = v573_.jointNode
				if v572_.anchorActor == 1 then
					v574_ = v573_.jointNodeActor1
				end
				local v575_ = self.components[v573_.componentIndices[(v572_.anchorActor + 1) % 2 + 1]].node
				local v576_, v577_, v578_ = localToWorld(v574_, v572_.x, v572_.y, v572_.z)
				local v579_, v580_, v581_ = localDirectionToWorld(v574_, v572_.upX, v572_.upY, v572_.upZ)
				local v582_, v583_, v584_ = localDirectionToWorld(v574_, v572_.dirX, v572_.dirY, v572_.dirZ)
				setWorldTranslation(v575_, v576_, v577_, v578_)
				I3DUtil.setWorldDirection(v575_, v582_, v583_, v584_, v579_, v580_, v581_)
				self:setComponentJointFrame(v573_, v572_.anchorActor)
			end
		end
	end
	for _, v585_ in pairs(v569_.subFoldingStateVehicles) do
		Foldable.setAnimTime(v585_, animTime, v571_, playSounds)
	end
	SpecializationUtil.raiseEvent(self, "onFoldTimeChanged", v569_.foldAnimTime)
end

-- Local values: spec, actionEvent, direction, text
function Foldable:updateActionEventFold()
	local v587_ = self.spec_foldable
	local v588_ = v587_.actionEvents[v587_.foldInputButton]
	if v588_ ~= nil then
		local v589_
		if self:getToggledFoldDirection() == v587_.turnOnFoldDirection then
			v589_ = v587_.negDirectionText
		else
			v589_ = v587_.posDirectionText
		end
		g_inputBinding:setActionEventText(v588_.actionEventId, v589_)
		g_inputBinding:setActionEventActive(v588_.actionEventId, self:getIsFoldActionAllowed())
	end
end

-- Local values: spec, actionEvent, state, direction, text
function Foldable:updateActionEventFoldMiddle()
	local v591_ = self.spec_foldable
	local v592_ = v591_.actionEventsLowering[v591_.foldMiddleInputButton]
	if v592_ ~= nil then
		local v593_ = self:getIsFoldMiddleAllowed()
		g_inputBinding:setActionEventActive(v592_.actionEventId, v593_)
		if v593_ then
			local v594_ = self:getToggledFoldMiddleDirection() == v591_.foldMiddleDirection
			if v591_.ignoreFoldMiddleWhileFolded and self:getFoldAnimTime() > v591_.foldMiddleAnimTime then
				v594_ = self:getIsLowered(true)
			end
			local v595_
			if v594_ then
				v595_ = v591_.middlePosDirectionText
			else
				v595_ = v591_.middleNegDirectionText
			end
			g_inputBinding:setActionEventText(v592_.actionEventId, v595_)
		end
	end
end

-- Local values: spec, toggleDirection, allowed, warning, attacherVehicle, attacherJointIndex, moveDown, targetMoveDown
function Foldable:actionEventFold(actionName, inputValue, callbackState, isAnalog)
	local v597_ = self.spec_foldable
	if v597_.hasFoldingParts then
		local v598_ = self:getToggledFoldDirection()
		local v599_, v600_ = self:getIsFoldAllowed(v598_, false)
		if v599_ then
			if v598_ == v597_.turnOnFoldDirection then
				self:setFoldState(v598_, true)
				return
			end
			self:setFoldState(v598_, false)
			if self:getIsFoldMiddleAllowed() and self.getAttacherVehicle ~= nil then
				local v601_ = self:getAttacherVehicle()
				local v602_ = v601_:getAttacherJointIndexFromObject(self)
				if v602_ ~= nil then
					local v603_ = v601_:getJointMoveDown(v602_)
					local v604_ = v598_ == v597_.turnOnFoldDirection
					if v604_ ~= v603_ then
						v601_:setJointMoveDown(v602_, v604_)
						return
					end
				end
			end
		elseif v600_ ~= nil then
			g_currentMission:showBlinkingWarning(v600_, 2000)
		end
	end
end

-- Local values: spec, ignoreFoldMiddle, direction, attacherVehicle, attacherJointIndex, moveDown, targetMoveDown, attacherVehicle
function Foldable:actionEventFoldMiddle(actionName, inputValue, callbackState, isAnalog)
	local v606_ = self.spec_foldable
	if v606_.hasFoldingParts and self:getIsFoldMiddleAllowed() then
		if v606_.ignoreFoldMiddleWhileFolded and self:getFoldAnimTime() > v606_.foldMiddleAnimTime and true or false then
			if self.getAttacherVehicle ~= nil then
				local v607_ = self:getAttacherVehicle()
				if v607_ ~= nil then
					v607_:handleLowerImplementEvent(self)
				end
			end
		else
			local v608_ = self:getToggledFoldMiddleDirection()
			if v608_ ~= 0 then
				if v608_ == v606_.turnOnFoldDirection then
					self:setFoldState(v608_, false)
				else
					self:setFoldState(v608_, true)
				end
				if self.getAttacherVehicle ~= nil then
					local v609_ = self:getAttacherVehicle()
					local v610_ = v609_:getAttacherJointIndexFromObject(self)
					if v610_ ~= nil then
						local v611_ = v609_:getJointMoveDown(v610_)
						local v612_ = v608_ == v606_.turnOnFoldDirection
						if v612_ ~= v611_ then
							v609_:setJointMoveDown(v610_, v612_)
							return
						end
					end
				end
			end
		end
	end
end

-- Local values: spec, displayWarning, warningToDisplay, toggleDirection, allowed, warning, vehicles, i, vehicle, spec2, toggleDirection2, allowed2, warning2
function Foldable:actionEventFoldAll(actionName, inputValue, callbackState, isAnalog)
	local v614_ = self.spec_foldable
	if v614_.hasFoldingParts then
		local v615_ = true
		local v616_ = nil
		local v617_ = self:getToggledFoldDirection()
		local v618_, v619_ = self:getIsFoldAllowed(v617_, false)
		if v618_ then
			if v617_ == v614_.turnOnFoldDirection then
				self:setFoldState(v617_, true)
				v615_ = false
			else
				self:setFoldState(v617_, false)
				v615_ = false
			end
		elseif v619_ ~= nil then
			v616_ = v619_
		end
		local v620_ = self.rootVehicle:getChildVehicles()
		for v621_ = 1, #v620_ do
			local v622_ = v620_[v621_]
			if v622_.setFoldState ~= nil then
				local v623_ = v622_.spec_foldable
				if #v623_.foldingParts > 0 then
					local v624_ = v622_:getToggledFoldDirection()
					local v625_, v626_ = v622_:getIsFoldAllowed(v617_, false)
					if v625_ then
						if v617_ == v614_.turnOnFoldDirection == (v624_ == v623_.turnOnFoldDirection) then
							if v624_ == v623_.turnOnFoldDirection then
								v622_:setFoldState(v624_, true)
							else
								v622_:setFoldState(v624_, false)
							end
							v615_ = false
						end
					elseif v626_ ~= nil then
						v616_ = v626_
					end
				end
			end
		end
		if v615_ and v616_ ~= nil then
			g_currentMission:showBlinkingWarning(v616_, 2000)
		end
	end
end

-- Local values: spec, actionEvent, _
function Foldable.externalActionEventRegister(data, vehicle)
	local v_u_629_ = vehicle.spec_foldable
	local _, v636_ = g_inputBinding:registerActionEvent(v_u_629_.foldInputButton, data, function(_, p630_, p631_, p632_, p633_)
		-- upvalues: (copy) vehicle, (copy) v_u_629_
		Motorized.tryStartMotor(vehicle)
		if v_u_629_.requiresPower then
			local v634_, v635_ = vehicle:getIsPowered()
			if v634_ then
				Foldable.actionEventFold(vehicle, p630_, p631_, p632_, p633_)
				return
			end
			if p631_ ~= 0 and v635_ ~= nil then
				g_currentMission:showBlinkingWarning(v635_, 2000)
				return
			end
		else
			Foldable.actionEventFold(vehicle, p630_, p631_, p632_, p633_)
		end
	end, false, true, false, true)
	data.actionEventId = v636_
	g_inputBinding:setActionEventTextPriority(data.actionEventId, GS_PRIO_HIGH)
end

-- Local values: spec, text
function Foldable.externalActionEventUpdate(data, vehicle)
	local v639_ = vehicle.spec_foldable
	if data.actionEventId ~= nil then
		local v640_
		if vehicle:getToggledFoldDirection() == v639_.turnOnFoldDirection then
			v640_ = v639_.negDirectionText
		else
			v640_ = v639_.posDirectionText
		end
		g_inputBinding:setActionEventText(data.actionEventId, v640_)
	end
end
