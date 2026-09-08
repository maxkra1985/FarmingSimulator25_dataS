YarderTower = {}
YarderTower.TREE_RAYCAST_DISTANCE = 40
YarderTower.TERRAIN_RAYCAST_DISTANCE = 20
YarderTower.MAX_CONTROL_DISTANCE = 15
YarderTower.GROUND_COLLISION_MASK = CollisionFlag.TERRAIN + CollisionFlag.TERRAIN_DELTA + CollisionFlag.STATIC_OBJECT
YarderTower.DAMAGED_SPEED_REDUCTION = 0.3
YarderTower.FOLLOW_MODE_NONE = 0
YarderTower.FOLLOW_MODE_ME = 1
YarderTower.FOLLOW_MODE_HOME = 2
YarderTower.FOLLOW_MODE_PICKUP = 3
YarderTower.FAILED_REASON_NONE = 0
YarderTower.FAILED_REASON_TOO_LONG = 1
YarderTower.FAILED_REASON_WRONG_ANGLE = 2
YarderTower.FAILED_REASON_TREE_TOO_SMALL = 3
YarderTower.FAILED_REASON_WAY_BLOCKED = 4
YarderTower.FAILED_REASON_ONLY_UPHILL_YARDING = 5
source("dataS/scripts/vehicles/specializations/activatables/YarderTowerSetupActivatable.lua")
source("dataS/scripts/vehicles/specializations/activatables/YarderTowerControlActivatable.lua")
source("dataS/scripts/vehicles/specializations/events/YarderTowerFollowModeEvent.lua")
source("dataS/scripts/vehicles/specializations/events/YarderTowerSetTargetEvent.lua")
source("dataS/scripts/gui/hud/extensions/YarderTowerHUDExtension.lua")

function YarderTower.prerequisitesPresent(specializations)
	return true
end
function YarderTower.initSpecialization()
	g_storeManager:addSpecType("yarderMaxLength", "shopListAttributeIconWinchMaxLength", YarderTower.loadSpecValueMaxLength, YarderTower.getSpecValueMaxLength, StoreSpecies.VEHICLE)
	g_storeManager:addSpecType("yarderMaxMass", "shopListAttributeIconWinchMaxMass", YarderTower.loadSpecValueMaxMass, YarderTower.getSpecValueMaxMass, StoreSpecies.VEHICLE)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("YarderTower")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.yarderTower#controlTrigger", "Trigger for player to control the tower")
	v1_:register(XMLValueType.BOOL, "vehicle.yarderTower#requiresAttacherVehicle", "Attacher vehicle is not allowed to be detached", false)
	v1_:register(XMLValueType.BOOL, "vehicle.yarderTower#requiresLowering", "Yarder can only be set up while lowered", false)
	v1_:register(XMLValueType.FLOAT, "vehicle.yarderTower#foldMinLimit", "Yarder can only be set up while fold time in between these limits", 0)
	v1_:register(XMLValueType.FLOAT, "vehicle.yarderTower#foldMaxLimit", "Yarder can only be set up while fold time in between these limits", 1)
	v1_:register(XMLValueType.FLOAT, "vehicle.yarderTower.placement#height", "Default height used on the trees", 10)
	v1_:register(XMLValueType.STRING, "vehicle.yarderTower.placement#minHeightOffset", "Min. height offset from main rope start to position on the tree (\'-\' for no limit)", "-1")
	v1_:register(XMLValueType.FLOAT, "vehicle.yarderTower.carriage#maxSpeed", "Max. speed of carriage in kph", 20)
	v1_:register(XMLValueType.FLOAT, "vehicle.yarderTower.carriage#acceleration", "Acceleration speed", 0.01)
	v1_:register(XMLValueType.FLOAT, "vehicle.yarderTower.carriage#deceleration", "Deceleration speed", 0.05)
	v1_:register(XMLValueType.FLOAT, "vehicle.yarderTower.carriage#startOffset", "Min. offset from tower to the carriage in meter", 1)
	v1_:register(XMLValueType.FLOAT, "vehicle.yarderTower.carriage#endOffset", "Min. offset from tree to the carriage in meter", 1)
	v1_:register(XMLValueType.STRING, "vehicle.yarderTower.carriage#filename", "Path to vehicle xml of carriage vehicle")
	v1_:register(XMLValueType.FLOAT, "vehicle.yarderTower.carriage#maxTreeMass", "Max. tree mass that can be attached (used for store spec data)")
	ForestryHook.registerXMLPaths(v1_, "vehicle.yarderTower.hooks.tree")
	ForestryHook.registerXMLPaths(v1_, "vehicle.yarderTower.hooks.ground")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.yarderTower.ropes.setupRope#node", "Setup rope start node")
	v1_:register(XMLValueType.COLOR, "vehicle.yarderTower.ropes.setupRope#colorInvalid", "Emissive color of rope while placement is invalid")
	v1_:register(XMLValueType.COLOR, "vehicle.yarderTower.ropes.setupRope#colorValid", "Emissive color of rope while placement is valid")
	v1_:register(XMLValueType.FLOAT, "vehicle.yarderTower.ropes.setupRope#diameterTree", "Rope diameter while on a tree", 0.015)
	v1_:register(XMLValueType.FLOAT, "vehicle.yarderTower.ropes.setupRope#diameterPlayer", "Rope diameter while in players hand", 0.015)
	YarderTower.registerRopeXMLPaths(v1_, "vehicle.yarderTower.ropes.setupRope")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.yarderTower.ropes.mainRope#node", "Main rope start node")
	v1_:register(XMLValueType.ANGLE, "vehicle.yarderTower.ropes.mainRope#maxAngle", "Max angle to the target", 80)
	v1_:register(XMLValueType.FLOAT, "vehicle.yarderTower.ropes.mainRope#maxLength", "Max distance to the target", 100)
	v1_:register(XMLValueType.FLOAT, "vehicle.yarderTower.ropes.mainRope#clearance", "Min. clearance below the rope", 2)
	v1_:register(XMLValueType.FLOAT, "vehicle.yarderTower.ropes.mainRope#minTreeDiameter", "Min. diameter of target tree", 0.2)
	YarderTower.registerRopeXMLPaths(v1_, "vehicle.yarderTower.ropes.mainRope")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.yarderTower.ropes.pullRope#node", "Pull rope start node")
	YarderTower.registerRopeXMLPaths(v1_, "vehicle.yarderTower.ropes.pullRope")
	v1_:register(XMLValueType.FLOAT, "vehicle.yarderTower.ropes.pushRope#yOffset", "Y Offset from main anchor point", 1.5)
	YarderTower.registerRopeXMLPaths(v1_, "vehicle.yarderTower.ropes.pushRope")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.yarderTower.ropes.supportRopes#centerNode", "Center of search radius")
	v1_:register(XMLValueType.FLOAT, "vehicle.yarderTower.ropes.supportRopes#treeRadius", "Radius to search mounting trees", 25)
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.yarderTower.ropes.supportRopes.supportRope(?)#node", "Support node which is automatically connected")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.yarderTower.ropes.supportRopes.supportRope(?)#raycastNode", "Dedicated node only used for ground detection raycast", "#node")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.yarderTower.ropes.supportRopes.supportRope(?)#angleReferenceNode", "Node used for angle calculations to validate the mounting point")
	v1_:register(XMLValueType.ANGLE, "vehicle.yarderTower.ropes.supportRopes.supportRope(?)#maxAngle", "Max. angle to tree", 15)
	v1_:register(XMLValueType.ANGLE, "vehicle.yarderTower.ropes.supportRopes.supportRope(?)#raycastRotY", "Y rotation of rotNode while searching for ground mounting point via raycast")
	v1_:register(XMLValueType.FLOAT, "vehicle.yarderTower.ropes.supportRopes.supportRope(?)#treeYOffset", "Y translation offset from tree root", 1)
	YarderTower.registerRopeXMLPaths(v1_, "vehicle.yarderTower.ropes.supportRopes.supportRope(?)")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.yarderTower.sounds", "setupRopeIncrease")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.yarderTower.sounds", "setupRopeDecrease")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.yarderTower.sounds", "setupRopeValidTarget")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.yarderTower.sounds", "setupStarted")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.yarderTower.sounds", "setupFinished")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.yarderTower.sounds", "setupCanceled")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.yarderTower.sounds", "ropeLinkTree")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.yarderTower.sounds", "ropeLinkGround")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.yarderTower.sounds", "removeYarder")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.yarderTower.sounds", "carriageMovePos")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.yarderTower.sounds", "carriageMoveNeg")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.yarderTower.sounds", "carriageMovePosLimit")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.yarderTower.sounds", "carriageMoveNegLimit")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.yarderTower.sounds", "carriageDriveMovePos")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.yarderTower.sounds", "carriageDriveMoveNeg")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.yarderTower.sounds", "carriageDriveMovePosLimit")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.yarderTower.sounds", "carriageDriveMoveNegLimit")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.yarderTower.sounds", "motor")
	EffectManager.registerEffectXMLPaths(v1_, "vehicle.yarderTower.motorEffects")
	v1_:setXMLSpecializationType()
	local v2_ = Vehicle.xmlSchemaSavegame
	v2_:register(XMLValueType.BOOL, "vehicles.vehicle(?).yarderTower#isActive", "Main rope is active")
	v2_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).yarderTower#position", "Current carriage position")
	v2_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).yarderTower.target#x", "Target x position")
	v2_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).yarderTower.target#y", "Target y position")
	v2_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).yarderTower.target#z", "Target z position")
	YarderCarriage.registerSavegameXMLPaths(v2_, "vehicles.vehicle(?).yarderTower")
end

function YarderTower.registerRopeXMLPaths(schema, baseKey)
	schema:register(XMLValueType.FLOAT, baseKey .. "#maxOffset", "Max y offset from direct line in the center of the rope", 0.1)
	schema:register(XMLValueType.FLOAT, baseKey .. "#offsetReferenceLength", "Y offset is interpolated up to this distance of rope length", 5)
	schema:register(XMLValueType.STRING, baseKey .. "#filename", "Path to rope i3d file")
	schema:register(XMLValueType.STRING, baseKey .. "#ropeNode", "Index path to rope to load", "0|0")
	schema:register(XMLValueType.FLOAT, baseKey .. "#diameter", "Rope diameter", 0.015)
	schema:register(XMLValueType.NODE_INDEX, baseKey .. "#rotNode", "Rotation node which is aligned in the rope direction")
	schema:register(XMLValueType.BOOL, baseKey .. "#rotNodeAllAxis", "Adjust all axis of the rotation node - otherwise only rotated about the Y axis", false)
	schema:register(XMLValueType.NODE_INDEX, baseKey .. ".ropeLengthNode(?)#node", "Node that is changing depending on the rope length")
	schema:register(XMLValueType.FLOAT, baseKey .. ".ropeLengthNode(?)#minLength", "Min. length for reference", 0)
	schema:register(XMLValueType.FLOAT, baseKey .. ".ropeLengthNode(?)#maxLength", "Max. length for reference", 10)
	schema:register(XMLValueType.VECTOR_ROT, baseKey .. ".ropeLengthNode(?)#minRot", "Rotation to apply at min. length")
	schema:register(XMLValueType.VECTOR_ROT, baseKey .. ".ropeLengthNode(?)#maxRot", "Rotation to apply at max. length")
	schema:register(XMLValueType.VECTOR_TRANS, baseKey .. ".ropeLengthNode(?)#minTrans", "Translation to apply at min. length")
	schema:register(XMLValueType.VECTOR_TRANS, baseKey .. ".ropeLengthNode(?)#maxTrans", "Translation to apply at max. length")
	schema:register(XMLValueType.VECTOR_SCALE, baseKey .. ".ropeLengthNode(?)#minScale", "Scale to apply at min. length")
	schema:register(XMLValueType.VECTOR_SCALE, baseKey .. ".ropeLengthNode(?)#maxScale", "Scale to apply at max. length")
	schema:register(XMLValueType.STRING, baseKey .. ".ropeLengthNode(?)#shaderParameterName", "Shader parameter to adjust")
	schema:register(XMLValueType.VECTOR_4, baseKey .. ".ropeLengthNode(?)#minShaderParameter", "Shader parameter to apply at min. length")
	schema:register(XMLValueType.VECTOR_4, baseKey .. ".ropeLengthNode(?)#maxShaderParameter", "Shader parameter to apply at max. length")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, baseKey)
end

function YarderTower.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onYarderCarriageTreeAttached")
end

function YarderTower.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "onHookI3DLoaded", YarderTower.onHookI3DLoaded)
	SpecializationUtil.registerFunction(vehicleType, "onRopeI3DLoaded", YarderTower.onRopeI3DLoaded)
	SpecializationUtil.registerFunction(vehicleType, "getIsSetupModeChangeAllowed", YarderTower.getIsSetupModeChangeAllowed)
	SpecializationUtil.registerFunction(vehicleType, "setYarderSetupModeState", YarderTower.setYarderSetupModeState)
	SpecializationUtil.registerFunction(vehicleType, "setYarderTargetActive", YarderTower.setYarderTargetActive)
	SpecializationUtil.registerFunction(vehicleType, "setYarderCarriageFollowMode", YarderTower.setYarderCarriageFollowMode)
	SpecializationUtil.registerFunction(vehicleType, "setYarderCarriageMoveInput", YarderTower.setYarderCarriageMoveInput)
	SpecializationUtil.registerFunction(vehicleType, "setYarderCarriageLiftInput", YarderTower.setYarderCarriageLiftInput)
	SpecializationUtil.registerFunction(vehicleType, "onYarderCarriageAttach", YarderTower.onYarderCarriageAttach)
	SpecializationUtil.registerFunction(vehicleType, "onYarderCarriageDetach", YarderTower.onYarderCarriageDetach)
	SpecializationUtil.registerFunction(vehicleType, "setupSupportRopes", YarderTower.setupSupportRopes)
	SpecializationUtil.registerFunction(vehicleType, "onCreateCarriageFinished", YarderTower.onCreateCarriageFinished)
	SpecializationUtil.registerFunction(vehicleType, "onCarriageVehicleDeleted", YarderTower.onCarriageVehicleDeleted)
	SpecializationUtil.registerFunction(vehicleType, "setYarderRopeState", YarderTower.setYarderRopeState)
	SpecializationUtil.registerFunction(vehicleType, "updateYarderRope", YarderTower.updateYarderRope)
	SpecializationUtil.registerFunction(vehicleType, "updateYarderRopeLengthNodes", YarderTower.updateYarderRopeLengthNodes)
	SpecializationUtil.registerFunction(vehicleType, "getTreeAtPosition", YarderTower.getTreeAtPosition)
	SpecializationUtil.registerFunction(vehicleType, "getIsPlayerInYarderRange", YarderTower.getIsPlayerInYarderRange)
	SpecializationUtil.registerFunction(vehicleType, "getIsPlayerInYarderControlRange", YarderTower.getIsPlayerInYarderControlRange)
	SpecializationUtil.registerFunction(vehicleType, "getYarderIsSetUp", YarderTower.getYarderIsSetUp)
	SpecializationUtil.registerFunction(vehicleType, "getYarderStatusInfo", YarderTower.getYarderStatusInfo)
	SpecializationUtil.registerFunction(vehicleType, "getYarderMainRopeLength", YarderTower.getYarderMainRopeLength)
	SpecializationUtil.registerFunction(vehicleType, "getYarderCarriageLastSpeed", YarderTower.getYarderCarriageLastSpeed)
	SpecializationUtil.registerFunction(vehicleType, "getIsTreeShapeUsedForYarderSetup", YarderTower.getIsTreeShapeUsedForYarderSetup)
	SpecializationUtil.registerFunction(vehicleType, "onYarderControlTriggerCallback", YarderTower.onYarderControlTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "onYarderTreeRaycastCallback", YarderTower.onYarderTreeRaycastCallback)
	SpecializationUtil.registerFunction(vehicleType, "doRopePlacementValidation", YarderTower.doRopePlacementValidation)
	SpecializationUtil.registerFunction(vehicleType, "onMainRopePlacementValidated", YarderTower.onMainRopePlacementValidated)
	SpecializationUtil.registerFunction(vehicleType, "onYarderSupportTerrainRaycastCallback", YarderTower.onYarderSupportTerrainRaycastCallback)
	SpecializationUtil.registerFunction(vehicleType, "onSupportRopeTreeOverlapCallback", YarderTower.onSupportRopeTreeOverlapCallback)
	SpecializationUtil.registerFunction(vehicleType, "onYarderTowerPlayerDeleted", YarderTower.onYarderTowerPlayerDeleted)
end

function YarderTower.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "isDetachAllowed", YarderTower.isDetachAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", YarderTower.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowsLowering", YarderTower.getAllowsLowering)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoConsumePtoPower", YarderTower.getDoConsumePtoPower)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConsumingLoad", YarderTower.getConsumingLoad)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsPowerTakeOffActive", YarderTower.getIsPowerTakeOffActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", YarderTower.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", YarderTower.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getUsageCausesDamage", YarderTower.getUsageCausesDamage)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", YarderTower.addToPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", YarderTower.removeFromPhysics)
end

function YarderTower.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", YarderTower)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadEnd", YarderTower)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDelete", YarderTower)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", YarderTower)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", YarderTower)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", YarderTower)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", YarderTower)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", YarderTower)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", YarderTower)
	SpecializationUtil.registerEventListener(vehicleType, "onYarderCarriageTreeAttached", YarderTower)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", YarderTower)
end

-- Local values: spec, isInvalid, placementMinHeightOffset, storeItem, loadSharedRopeAttributes, i, supportRope
function YarderTower:onLoad(savegame)
	local v_u_10_ = self.spec_yarderTower
	local v11_ = false
	v_u_10_.sharedLoadRequestIds = {}
	v_u_10_.controlTriggerNode = self.xmlFile:getValue("vehicle.yarderTower#controlTrigger", nil, self.components, self.i3dMappings)
	if v_u_10_.controlTriggerNode == nil then
		Logging.xmlError(self.xmlFile, "Missing yarder control trigger")
		v11_ = true
	else
		if not CollisionFlag.getHasMaskFlagSet(v_u_10_.controlTriggerNode, CollisionFlag.PLAYER) then
			Logging.xmlError(self.xmlFile, "Yarder control trigger does not have the PLAYER collision flag set!")
			v11_ = true
		end
		addTrigger(v_u_10_.controlTriggerNode, "onYarderControlTriggerCallback", self)
	end
	v_u_10_.requiresAttacherVehicle = self.xmlFile:getValue("vehicle.yarderTower#requiresAttacherVehicle", false)
	v_u_10_.requiresLowering = self.xmlFile:getValue("vehicle.yarderTower#requiresLowering", false)
	v_u_10_.foldMinLimit = self.xmlFile:getValue("vehicle.yarderTower#foldMinLimit", 0)
	v_u_10_.foldMaxLimit = self.xmlFile:getValue("vehicle.yarderTower#foldMaxLimit", 1)
	v_u_10_.requiresPowerTimeOffset = 0
	v_u_10_.placementHeight = self.xmlFile:getValue("vehicle.yarderTower.placement#height", 10)
	local v12_ = self.xmlFile:getValue("vehicle.yarderTower.placement#minHeightOffset", "-1")
	if v12_ == "-" then
		v_u_10_.placementMinHeightOffset = math.huge
	else
		v_u_10_.placementMinHeightOffset = tonumber(v12_)
	end
	v_u_10_.carriage = {}
	v_u_10_.carriage.lastMoveInput = 0
	v_u_10_.carriage.lastMoveInputTime = 0
	v_u_10_.carriage.lastLiftInput = 0
	v_u_10_.carriage.lastLiftInputTime = 0
	v_u_10_.carriage.speed = 0
	v_u_10_.carriage.targetSpeed = 0
	v_u_10_.carriage.position = 0
	v_u_10_.carriage.lastPosition = 0
	v_u_10_.carriage.lastPositionTimeOffset = 0
	v_u_10_.carriage.lastSpeed = 0
	v_u_10_.carriage.followModeState = YarderTower.FOLLOW_MODE_NONE
	v_u_10_.carriage.followModePlayer = nil
	v_u_10_.carriage.followModeLocalPlayer = false
	v_u_10_.carriage.followModePickupPosition = 0
	v_u_10_.carriage.lastPlayerInRange = false
	v_u_10_.carriage.maxSpeed = self.xmlFile:getValue("vehicle.yarderTower.carriage#maxSpeed", 20) / 3600
	v_u_10_.carriage.acceleration = self.xmlFile:getValue("vehicle.yarderTower.carriage#acceleration", 0.01)
	v_u_10_.carriage.deceleration = self.xmlFile:getValue("vehicle.yarderTower.carriage#deceleration", 0.05)
	v_u_10_.carriage.startOffset = self.xmlFile:getValue("vehicle.yarderTower.carriage#startOffset", 1)
	v_u_10_.carriage.endOffset = self.xmlFile:getValue("vehicle.yarderTower.carriage#endOffset", 1)
	v_u_10_.carriage.filename = self.xmlFile:getValue("vehicle.yarderTower.carriage#filename")
	if v_u_10_.carriage.filename == nil then
		Logging.xmlError(self.xmlFile, "No carriage filename given in \'vehicle.yarderTower.carriage#filename\'")
		v11_ = true
	else
		v_u_10_.carriage.filename = Utils.getFilename(v_u_10_.carriage.filename, self.baseDirectory)
		if g_storeManager:getItemByXMLFilename(v_u_10_.carriage.filename) == nil then
			Logging.xmlError(self.xmlFile, "Invalid carriage filename given. (%s)", v_u_10_.carriage.filename)
			v11_ = true
		end
	end
	v_u_10_.hooks = {}
	v_u_10_.hooks.treeData = ForestryHook.new(self, self.rootNode)
	v_u_10_.hooks.treeData:loadFromXML(self.xmlFile, "vehicle.yarderTower.hooks.tree", self.baseDirectory)
	v_u_10_.hooks.treeData:setVisibility(false)
	v_u_10_.hooks.groundData = ForestryHook.new(self, self.rootNode)
	v_u_10_.hooks.groundData:loadFromXML(self.xmlFile, "vehicle.yarderTower.hooks.ground", self.baseDirectory)
	v_u_10_.hooks.groundData:setVisibility(false)
	if not (v_u_10_.hooks.treeData:isValid() and v_u_10_.hooks.groundData:isValid()) then
		Logging.xmlError(self.xmlFile, "Missing ground or tree hook for yarder!")
		v11_ = true
	end
	local function v_u_20_(p_u_13_, p14_)
		-- upvalues: (copy) self, (copy) v_u_10_
		p_u_13_.isActive = false
		p_u_13_.maxOffset = self.xmlFile:getValue(p14_ .. "#maxOffset", 0.4)
		p_u_13_.offsetReferenceLength = self.xmlFile:getValue(p14_ .. "#offsetReferenceLength", 5)
		p_u_13_.diameter = self.xmlFile:getValue(p14_ .. "#diameter", 0.015)
		p_u_13_.filename = self.xmlFile:getValue(p14_ .. "#filename")
		p_u_13_.ropeNodePath = self.xmlFile:getValue(p14_ .. "#ropeNode", "0|0")
		if p_u_13_.filename ~= nil then
			p_u_13_.filename = Utils.getFilename(p_u_13_.filename, self.baseDirectory)
			local v15_ = self:loadSubSharedI3DFile(p_u_13_.filename, false, false, self.onRopeI3DLoaded, self, p_u_13_)
			local v16_ = v_u_10_.sharedLoadRequestIds
			table.insert(v16_, v15_)
		end
		p_u_13_.rotNode = self.xmlFile:getValue(p14_ .. "#rotNode", nil, self.components, self.i3dMappings)
		p_u_13_.rotNodeAllAxis = self.xmlFile:getValue(p14_ .. "#rotNodeAllAxis", false)
		if p_u_13_.rotNode ~= nil then
			p_u_13_.rotNodeInitRot = { getRotation(p_u_13_.rotNode) }
		end
		p_u_13_.ropeLengthNodes = {}
		self.xmlFile:iterate(p14_ .. ".ropeLengthNode", function(_, p17_)
			-- upvalues: (ref) self, (copy) p_u_13_
			local v18_ = {
				["node"] = self.xmlFile:getValue(p17_ .. "#node", nil, self.components, self.i3dMappings)
			}
			if v18_.node ~= nil then
				v18_.minLength = self.xmlFile:getValue(p17_ .. "#minLength", 0)
				v18_.maxLength = self.xmlFile:getValue(p17_ .. "#maxLength", 10)
				v18_.minRot = self.xmlFile:getValue(p17_ .. "#minRot", nil, true)
				v18_.maxRot = self.xmlFile:getValue(p17_ .. "#maxRot", nil, true)
				v18_.minTrans = self.xmlFile:getValue(p17_ .. "#minTrans", nil, true)
				v18_.maxTrans = self.xmlFile:getValue(p17_ .. "#maxTrans", nil, true)
				v18_.minScale = self.xmlFile:getValue(p17_ .. "#minScale", nil, true)
				v18_.maxScale = self.xmlFile:getValue(p17_ .. "#maxScale", nil, true)
				v18_.shaderParameterName = self.xmlFile:getValue(p17_ .. "#shaderParameterName")
				v18_.minShaderParameter = self.xmlFile:getValue(p17_ .. "#minShaderParameter", nil, true)
				v18_.maxShaderParameter = self.xmlFile:getValue(p17_ .. "#maxShaderParameter", nil, true)
				if v18_.shaderParameterName ~= nil and not getHasShaderParameter(v18_.node, v18_.shaderParameterName) then
					Logging.xmlWarning(p17_, "Node does not have the provided shader parameter \'%s\'", v18_.shaderParameterName)
				end
				local v19_ = p_u_13_.ropeLengthNodes
				table.insert(v19_, v18_)
			end
		end)
		p_u_13_.changeObjects = {}
		ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, p14_, p_u_13_.changeObjects, self.components, self)
		ObjectChangeUtil.setObjectChanges(p_u_13_.changeObjects, false, self, self.setMovingToolDirty)
	end
	v_u_10_.setupRope = {}
	v_u_10_.setupRope.node = self.xmlFile:getValue("vehicle.yarderTower.ropes.setupRope#node", nil, self.components, self.i3dMappings)
	if v_u_10_.setupRope.node == nil then
		Logging.xmlWarning(self.xmlFile, "Missing setupRope for yarder tower")
		v11_ = true
	end
	v_u_10_.setupRope.colorInvalid = self.xmlFile:getValue("vehicle.yarderTower.ropes.setupRope#colorInvalid", nil, true)
	v_u_10_.setupRope.colorValid = self.xmlFile:getValue("vehicle.yarderTower.ropes.setupRope#colorValid", nil, true)
	v_u_10_.setupRope.diameterTree = self.xmlFile:getValue("vehicle.yarderTower.ropes.setupRope#diameterTree", 0.015)
	v_u_10_.setupRope.diameterPlayer = self.xmlFile:getValue("vehicle.yarderTower.ropes.setupRope#diameterPlayer", 0.015)
	v_u_20_(v_u_10_.setupRope, "vehicle.yarderTower.ropes.setupRope")
	v_u_10_.mainRope = {}
	v_u_10_.mainRope.node = self.xmlFile:getValue("vehicle.yarderTower.ropes.mainRope#node", nil, self.components, self.i3dMappings)
	if v_u_10_.mainRope.node == nil then
		Logging.xmlWarning(self.xmlFile, "Missing mainRope for yarder tower")
		v11_ = true
	end
	v_u_10_.mainRope.maxAngle = self.xmlFile:getValue("vehicle.yarderTower.ropes.mainRope#maxAngle", 80)
	v_u_10_.mainRope.maxLength = self.xmlFile:getValue("vehicle.yarderTower.ropes.mainRope#maxLength", 100)
	v_u_10_.mainRope.clearance = self.xmlFile:getValue("vehicle.yarderTower.ropes.mainRope#clearance", 2)
	v_u_10_.mainRope.minTreeDiameter = self.xmlFile:getValue("vehicle.yarderTower.ropes.mainRope#minTreeDiameter", 0.2)
	v_u_20_(v_u_10_.mainRope, "vehicle.yarderTower.ropes.mainRope")
	v_u_10_.mainRope.isActive = false
	v_u_10_.mainRope.isValid = false
	v_u_10_.mainRope.lastIsValid = false
	v_u_10_.mainRope.lastLength = 0
	v_u_10_.mainRope.lastLengthOffsetTime = 0
	v_u_10_.mainRope.failedWarning = nil
	v_u_10_.mainRope.target = { 0, 0, 0 }
	v_u_10_.pullRope = {}
	v_u_10_.pullRope.node = self.xmlFile:getValue("vehicle.yarderTower.ropes.pullRope#node", nil, self.components, self.i3dMappings)
	v_u_20_(v_u_10_.pullRope, "vehicle.yarderTower.ropes.pullRope")
	v_u_10_.pushRope = {}
	v_u_10_.pushRope.yOffset = self.xmlFile:getValue("vehicle.yarderTower.ropes.pushRope#yOffset", 1.5)
	v_u_20_(v_u_10_.pushRope, "vehicle.yarderTower.ropes.pushRope")
	v_u_10_.supportRopes = {}
	v_u_10_.supportRopes.centerNode = self.xmlFile:getValue("vehicle.yarderTower.ropes.supportRopes#centerNode", nil, self.components, self.i3dMappings)
	v_u_10_.supportRopes.treeRadius = self.xmlFile:getValue("vehicle.yarderTower.ropes.supportRopes#treeRadius", 25)
	v_u_10_.supportRopes.foundTrees = {}
	v_u_10_.supportRopes.ropes = {}
	self.xmlFile:iterate("vehicle.yarderTower.ropes.supportRopes.supportRope", function(_, p21_)
		-- upvalues: (copy) self, (copy) v_u_20_, (copy) v_u_10_
		local v22_ = {
			["node"] = self.xmlFile:getValue(p21_ .. "#node", nil, self.components, self.i3dMappings)
		}
		if v22_.node ~= nil then
			v22_.angleReferenceNode = self.xmlFile:getValue(p21_ .. "#angleReferenceNode", v22_.node, self.components, self.i3dMappings)
			v22_.maxAngle = self.xmlFile:getValue(p21_ .. "#maxAngle", 22.5)
			v22_.raycastRotY = self.xmlFile:getValue(p21_ .. "#raycastRotY")
			v22_.treeYOffset = self.xmlFile:getValue(p21_ .. "#treeYOffset", 1)
			v22_.raycastNode = self.xmlFile:getValue(p21_ .. "#raycastNode", v22_.node, self.components, self.i3dMappings)
			v22_.target = { 0, 0, 0 }
			v22_.vehicle = self
			v22_.onYarderSupportTerrainRaycastCallback = self.onYarderSupportTerrainRaycastCallback
			v_u_20_(v22_, p21_)
			local v23_ = v_u_10_.supportRopes.ropes
			table.insert(v23_, v22_)
		end
	end)
	v_u_10_.isPlayerInRange = false
	v_u_10_.setupModeState = false
	v_u_10_.updateRopesDirtyTime = 0
	v_u_10_.treeRaycast = {}
	v_u_10_.treeRaycast.hasStarted = false
	v_u_10_.treeRaycast.lastValidTree = nil
	v_u_10_.treeRaycast.lastValidTreeHeight = 0
	v_u_10_.treeRaycast.foundTree = nil
	v_u_10_.treeRaycast.data = {
		["vehicle"] = self,
		["x"] = 0,
		["y"] = 0,
		["z"] = 0,
		["hasStarted"] = false,
		["callback"] = self.onMainRopePlacementValidated
	}
	v_u_10_.lastMotorRpm = 0
	v_u_10_.lastMotorPowerTimeOffset = 0
	v_u_10_.samples = {}
	if self.isClient then
		v_u_10_.samples.setupRopeIncrease = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "setupRopeIncrease", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_10_.samples.setupRopeDecrease = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "setupRopeDecrease", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_10_.samples.setupRopeValidTarget = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "setupRopeValidTarget", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_10_.samples.setupStarted = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "setupStarted", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_10_.samples.setupFinished = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "setupFinished", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_10_.samples.setupCanceled = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "setupCanceled", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_10_.samples.ropeLinkTree = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "ropeLinkTree", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_10_.samples.ropeLinkGround = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "ropeLinkGround", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_10_.samples.removeYarder = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "removeYarder", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_10_.samples.carriageMovePos = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "carriageMovePos", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_10_.samples.carriageMoveNeg = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "carriageMoveNeg", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_10_.samples.carriageMovePosLimit = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "carriageMovePosLimit", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_10_.samples.carriageMoveNegLimit = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "carriageMoveNegLimit", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_10_.samples.carriageDriveMovePos = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "carriageDriveMovePos", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_10_.samples.carriageDriveMoveNeg = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "carriageDriveMoveNeg", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_10_.samples.carriageDriveMovePosLimit = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "carriageDriveMovePosLimit", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_10_.samples.carriageDriveMoveNegLimit = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "carriageDriveMoveNegLimit", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_10_.samples.motor = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "motor", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		for v24_ = 1, #v_u_10_.supportRopes.ropes do
			local v25_ = v_u_10_.supportRopes.ropes[v24_]
			if v_u_10_.samples.ropeLinkTree ~= nil then
				v25_.sampleRopeLinkTree = g_soundManager:cloneSample(v_u_10_.samples.ropeLinkTree, self.rootNode, self)
			end
			if v_u_10_.samples.ropeLinkGround ~= nil then
				v25_.sampleRopeLinkGround = g_soundManager:cloneSample(v_u_10_.samples.ropeLinkGround, self.rootNode, self)
			end
		end
		if v_u_10_.samples.ropeLinkTree ~= nil then
			v_u_10_.mainRope.sampleRopeLinkTree = g_soundManager:cloneSample(v_u_10_.samples.ropeLinkTree, self.rootNode, self)
		end
		v_u_10_.motorEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.yarderTower.motorEffects", self.components, self, self.i3dMappings)
	end
	v_u_10_.texts = {}
	v_u_10_.texts.warningWrongAngle = g_i18n:getText("yarder_wrongAngle")
	v_u_10_.texts.warningRopeTooLong = g_i18n:getText("yarder_ropeTooLong")
	v_u_10_.texts.warningTreeTooSmall = g_i18n:getText("yarder_treeTooSmall")
	v_u_10_.texts.warningWayIsBlocked = g_i18n:getText("yarder_wayIsBlocked")
	v_u_10_.texts.actionStartSetup = g_i18n:getText("yarder_setup")
	v_u_10_.texts.actionCancelSetup = g_i18n:getText("yarder_cancelSetup")
	v_u_10_.texts.actionRemoveYarder = g_i18n:getText("yarder_remove")
	v_u_10_.texts.actionSetTargetTree = g_i18n:getText("yarder_setTargetTree")
	v_u_10_.texts.actionCarriageFollowModeEnable = g_i18n:getText("yarder_carriageFollowModeEnable")
	v_u_10_.texts.actionCarriageFollowModeDisable = g_i18n:getText("yarder_carriageFollowModeDisable")
	v_u_10_.texts.actionCarriageManualControl = g_i18n:getText("yarder_carriageMove")
	v_u_10_.texts.actionCarriageLiftLower = g_i18n:getText("yarder_carriageLiftLower")
	v_u_10_.texts.actionCarriageAttachTree = g_i18n:getText("yarder_carriageAttachTree")
	v_u_10_.texts.actionCarriageDetachTree = g_i18n:getText("yarder_carriageDetachTree")
	v_u_10_.texts.warningDetachNotAllowed = g_i18n:getText("yarder_detachNotAllowed")
	v_u_10_.texts.warningDoNotMoveVehicle = g_i18n:getText("yarder_doNotMoveVehicle")
	v_u_10_.texts.warningLowerFirst = g_i18n:getText("warning_lowerImplementFirst")
	v_u_10_.texts.warningUnfoldFirst = g_i18n:getText("warning_firstUnfoldTheTool")
	v_u_10_.texts.warningOnlyForUphillYarding = g_i18n:getText("yarder_onlyForUphillYarding")
	if v11_ then
		Logging.xmlError(self.xmlFile, "Failed to load yarder")
		if v_u_10_.controlTriggerNode ~= nil then
			removeTrigger(v_u_10_.controlTriggerNode)
			v_u_10_.controlTriggerNode = nil
		end
		SpecializationUtil.removeEventListener(self, "onLoadEnd", YarderTower)
		SpecializationUtil.removeEventListener(self, "onReadStream", YarderTower)
		SpecializationUtil.removeEventListener(self, "onWriteStream", YarderTower)
		SpecializationUtil.removeEventListener(self, "onReadUpdateStream", YarderTower)
		SpecializationUtil.removeEventListener(self, "onWriteUpdateStream", YarderTower)
		SpecializationUtil.removeEventListener(self, "onUpdate", YarderTower)
		SpecializationUtil.removeEventListener(self, "onYarderCarriageTreeAttached", YarderTower)
		SpecializationUtil.removeEventListener(self, "onPostAttach", YarderTower)
	else
		v_u_10_.setupActivatable = YarderTowerSetupActivatable.new(self)
		v_u_10_.controlActivatable = YarderTowerControlActivatable.new(self)
		v_u_10_.hudExtension = YarderTowerHUDExtension.new(self)
	end
	v_u_10_.dirtyFlag = self:getNextDirtyFlag()
end

-- Local values: spec, key
function YarderTower:onLoadEnd(savegame)
	local v28_ = self.spec_yarderTower
	if savegame ~= nil and not savegame.resetVehicles then
		local v29_ = savegame.key .. ".yarderTower"
		v28_.mainRope.isActive = savegame.xmlFile:getValue(v29_ .. "#isActive", false)
		v28_.carriage.position = savegame.xmlFile:getValue(v29_ .. "#position", 0)
		if v28_.mainRope.isActive then
			v28_.mainRope.isValid = true
			v28_.mainRope.target[1] = savegame.xmlFile:getValue(v29_ .. ".target#x", v28_.mainRope.target[1])
			v28_.mainRope.target[2] = savegame.xmlFile:getValue(v29_ .. ".target#y", v28_.mainRope.target[2])
			v28_.mainRope.target[3] = savegame.xmlFile:getValue(v29_ .. ".target#z", v28_.mainRope.target[3])
			self:setYarderTargetActive(true, true)
			v28_.loadedAttachedTreesData = YarderCarriage.loadAttachedTreesFromXML(savegame.xmlFile, v29_)
		end
	end
end

-- Local values: spec
function YarderTower:onPreDelete()
	local v31_ = self.spec_yarderTower
	if v31_.mainRope ~= nil and v31_.mainRope.isActive then
		self:setYarderTargetActive(false, true)
	end
end

-- Local values: spec, _, sharedLoadRequestId, i, supportRope
function YarderTower:onDelete()
	local v33_ = self.spec_yarderTower
	if v33_.hudExtension ~= nil then
		g_currentMission.hud:removeInfoExtension(v33_.hudExtension)
		v33_.hudExtension:delete()
	end
	if v33_.controlTriggerNode ~= nil then
		removeTrigger(v33_.controlTriggerNode)
		v33_.controlTriggerNode = nil
	end
	if v33_.sharedLoadRequestIds ~= nil then
		for _, v34_ in ipairs(v33_.sharedLoadRequestIds) do
			g_i3DManager:releaseSharedI3DFile(v34_)
		end
	end
	if v33_.hooks ~= nil then
		if v33_.hooks.treeData ~= nil then
			v33_.hooks.treeData:delete()
		end
		if v33_.hooks.groundData ~= nil then
			v33_.hooks.groundData:delete()
		end
	end
	if self.isClient then
		g_soundManager:deleteSamples(v33_.samples)
		if v33_.supportRopes ~= nil then
			for v35_ = 1, #v33_.supportRopes.ropes do
				local v36_ = v33_.supportRopes.ropes[v35_]
				g_soundManager:deleteSample(v36_.sampleRopeLinkTree)
				g_soundManager:deleteSample(v36_.sampleRopeLinkGround)
			end
		end
		if v33_.mainRope ~= nil then
			g_soundManager:deleteSample(v33_.mainRope.sampleRopeLinkTree)
		end
		g_effectManager:deleteEffects(v33_.motorEffects)
	end
	g_currentMission.activatableObjectsSystem:removeActivatable(v33_.setupActivatable)
	g_currentMission.activatableObjectsSystem:removeActivatable(v33_.controlActivatable)
end

-- Local values: spec
function YarderTower:saveToXMLFile(xmlFile, key, usedModNames)
	local v41_ = self.spec_yarderTower
	xmlFile:setValue(key .. "#isActive", v41_.mainRope.isActive)
	xmlFile:setValue(key .. "#position", v41_.carriage.position)
	if v41_.mainRope.isActive then
		xmlFile:setValue(key .. ".target#x", v41_.mainRope.target[1])
		xmlFile:setValue(key .. ".target#y", v41_.mainRope.target[2])
		xmlFile:setValue(key .. ".target#z", v41_.mainRope.target[3])
	end
	if v41_.carriage.vehicle ~= nil then
		v41_.carriage.vehicle:saveAttachedTreesToXML(xmlFile, key, usedModNames)
	end
end

-- Local values: spec, x, y, z
function YarderTower:onReadStream(streamId, connection)
	local v44_ = self.spec_yarderTower
	v44_.carriage.followModeState = streamReadUIntN(streamId, 2)
	if streamReadBool(streamId) then
		local v45_ = streamReadFloat32(streamId)
		local v46_ = streamReadFloat32(streamId)
		local v47_ = streamReadFloat32(streamId)
		v44_.mainRope.isValid = true
		local v48_ = v44_.mainRope.target
		local v49_ = v44_.mainRope.target
		local v50_ = v44_.mainRope.target
		v48_[1] = v45_
		v49_[2] = v46_
		v50_[3] = v47_
		self:setYarderTargetActive(true, true)
	end
end

-- Local values: spec
function YarderTower:onWriteStream(streamId, connection)
	local v53_ = self.spec_yarderTower
	streamWriteUIntN(streamId, v53_.carriage.followModeState, 2)
	if streamWriteBool(streamId, v53_.mainRope.isActive) then
		streamWriteFloat32(streamId, v53_.mainRope.target[1])
		streamWriteFloat32(streamId, v53_.mainRope.target[2])
		streamWriteFloat32(streamId, v53_.mainRope.target[3])
	end
end

function YarderTower:onReadUpdateStream(streamId, timestamp, connection)
	if not connection:getIsServer() and streamReadBool(streamId) then
		self:setYarderCarriageMoveInput(streamReadUIntN(streamId, 2) - 1)
		self:setYarderCarriageLiftInput(streamReadUIntN(streamId, 2) - 1)
	end
end

-- Local values: spec
function YarderTower:onWriteUpdateStream(streamId, connection, dirtyMask)
	local v61_ = self.spec_yarderTower
	if connection:getIsServer() then
		local v62_ = streamWriteBool
		local v63_ = v61_.dirtyFlag
		if v62_(streamId, bit32.band(dirtyMask, v63_) ~= 0) then
			local v64_ = streamWriteUIntN
			local v65_ = v61_.carriage.lastMoveInput
			v64_(streamId, math.sign(v65_) + 1, 2)
			local v66_ = streamWriteUIntN
			local v67_ = v61_.carriage.lastLiftInput
			v66_(streamId, math.sign(v67_) + 1, 2)
		end
	end
end

-- Local values: spec, player, cameraNode, x1, y1, z1, kinematicHelperNode, x2, y2, z2, length, x, y, z, dx, dy, dz, shapeId, x3, y3, z3, terrainHeight, emissiveColor, x1, y1, z1, x2, y2, z2, length, rollSpacing, totalRopeLength, maxSpeed, damage, targetPosition, player, x, y, z, _, direction, speed, attacherVehicle, motor, maxMotorRotAcceleration, minMotorRpm, maxMotorRpm, neededPtoTorque, _, direction, acceleration, func, alphaOffset, startAlphaOffset, endAlphaOffset, alpha, cx, cy, cz, yOffset, rollSpacingAlpha, rsx1, rsy1, rsz1, rsx2, rsy2, rsz2, cDirX, cDirY, cDirZ, rx, ry, rz, pullRopeTargetNode, px, py, pz, maxOffset, length, _, totalRopeLength, alphaOffset, startAlphaOffset, endAlphaOffset, cx, cy, cz, _, _, z, position, pushRopeTargetNode, px, py, pz, isInRange, _, i, supportRope, targetRpm, minLoad, loadFactor
function YarderTower:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v70_ = self.spec_yarderTower
	if v70_.setupModeState then
		if v70_.mainRope.node == nil or (g_localPlayer == nil or not g_localPlayer.isControlled) then
			self:setYarderSetupModeState(false, true)
			v70_.mainRope.isValid = false
			v70_.mainRope.lastIsValid = false
		else
			local v71_ = g_localPlayer
			local v72_ = v71_:getCurrentCameraNode()
			local v73_, v74_, v75_ = getWorldTranslation(v70_.mainRope.node)
			local v76_ = v71_.hands.spec_hands.kinematicNode
			local v77_, v78_, v79_ = getWorldTranslation(v76_)
			local v80_ = MathUtil.vector3Length(v77_ - v73_, v78_ - v74_, v79_ - v75_)
			if not v70_.treeRaycast.hasStarted then
				v70_.treeRaycast.hasStarted = true
				v70_.treeRaycast.foundTree = nil
				local v81_, v82_, v83_ = localToWorld(v72_, 0, 0, 1)
				local v84_, v85_, v86_ = localDirectionToWorld(v72_, 0, 0, -1)
				raycastClosestAsync(v81_, v82_, v83_, v84_, v85_, v86_, YarderTower.TREE_RAYCAST_DISTANCE, "onYarderTreeRaycastCallback", self, CollisionFlag.TREE)
			end
			if v70_.treeRaycast.lastValidTree == nil then
				v70_.mainRope.isValid = false
				local v87_ = v70_.mainRope.target
				local v88_ = v70_.mainRope.target
				local v89_ = v70_.mainRope.target
				v87_[1] = v77_
				v88_[2] = v78_
				v89_[3] = v79_
				v70_.setupRope.diameter = v70_.setupRope.diameterPlayer
			else
				local v90_ = v70_.treeRaycast.lastValidTree
				local v91_, v92_, v93_ = getWorldTranslation(v90_)
				local v94_ = v92_ + v70_.placementHeight
				local v95_ = v70_.treeRaycast.lastValidTreeHeight
				local v96_ = math.max(v94_, v95_)
				local v97_ = v74_ + v70_.placementMinHeightOffset
				local v98_ = math.min(v96_, v97_)
				local v99_ = getTerrainHeightAtWorldPos(g_terrainNode, v91_, 0, v93_) + 0.2
				local v100_ = math.max(v98_, v99_)
				self:doRopePlacementValidation(v70_.mainRope.node, v90_, v91_, v100_, v93_, v70_.mainRope.maxAngle, v70_.mainRope.maxLength, v70_.mainRope.clearance, v70_.mainRope.minTreeDiameter, v70_.treeRaycast.data)
				v77_ = v70_.mainRope.target[1]
				v78_ = v70_.mainRope.target[2]
				v79_ = v70_.mainRope.target[3]
				v80_ = MathUtil.vector3Length(v77_ - v73_, v78_ - v74_, v79_ - v75_)
			end
			if v70_.mainRope.isValid ~= v70_.mainRope.lastIsValid then
				v70_.mainRope.lastIsValid = v70_.mainRope.isValid
				if v70_.mainRope.isValid then
					g_soundManager:playSample(v70_.samples.setupRopeValidTarget)
				end
			end
			if v80_ ~= v70_.mainRope.lastLength then
				if v70_.mainRope.lastLength < v80_ then
					if not g_soundManager:getIsSamplePlaying(v70_.samples.setupRopeIncrease) then
						g_soundManager:playSample(v70_.samples.setupRopeIncrease)
						g_soundManager:stopSample(v70_.samples.setupRopeDecrease)
					end
				elseif not g_soundManager:getIsSamplePlaying(v70_.samples.setupRopeDecrease) then
					g_soundManager:playSample(v70_.samples.setupRopeDecrease)
					g_soundManager:stopSample(v70_.samples.setupRopeIncrease)
				end
				v70_.mainRope.lastLength = v80_
				v70_.mainRope.lastLengthOffsetTime = 250
			end
			if v70_.mainRope.lastLengthOffsetTime > 0 then
				v70_.mainRope.lastLengthOffsetTime = v70_.mainRope.lastLengthOffsetTime - dt
				if v70_.mainRope.lastLengthOffsetTime <= 0 then
					g_soundManager:stopSample(v70_.samples.setupRopeIncrease)
					g_soundManager:stopSample(v70_.samples.setupRopeDecrease)
				end
			end
			local v101_ = v70_.mainRope.isValid and v70_.setupRope.colorValid or v70_.setupRope.colorInvalid
			setShaderParameter(v70_.setupRope.ropeNode, "ropeEmissiveColor", v101_[1], v101_[2], v101_[3], 1, false)
			self:updateYarderRope(v70_.setupRope, v77_, v78_, v79_, dt)
		end
		v70_.setupActivatable:updateActionEventTexts()
		self:raiseActive()
	end
	if v70_.mainRope.isActive then
		if v70_.loadedAttachedTreesData ~= nil and (v70_.carriage.vehicle ~= nil and (v70_.carriage.vehicle.isAddedToPhysics and v70_.carriage.vehicle:resolveLoadedAttachedTrees(v70_.loadedAttachedTreesData))) then
			v70_.loadedAttachedTreesData = nil
		end
		local v102_, v103_, v104_ = getWorldTranslation(v70_.mainRope.node)
		local v105_ = v70_.mainRope.target[1]
		local v106_ = v70_.mainRope.target[2]
		local v107_ = v70_.mainRope.target[3]
		if self.isServer and (v70_.carriage.vehicle ~= nil and v70_.carriage.vehicle.getCarriageDimensions ~= nil) then
			local v108_, v109_ = v70_.carriage.vehicle:getCarriageDimensions()
			local v110_ = MathUtil.vector3Length(v105_ - v102_, v106_ - v103_, v107_ - v104_)
			local v111_ = v70_.carriage.maxSpeed
			local v112_ = self:getVehicleDamage()
			if v112_ > 0 then
				v111_ = v111_ * (1 - v112_ * YarderTower.DAMAGED_SPEED_REDUCTION)
			end
			if v70_.carriage.followModeState == YarderTower.FOLLOW_MODE_NONE then
				if v70_.carriage.lastMoveInput == 0 then
					v70_.carriage.targetSpeed = 0
				else
					v70_.carriage.targetSpeed = v111_ / v110_ * dt * v70_.carriage.lastMoveInput
					if g_time - v70_.carriage.lastMoveInputTime > 250 then
						v70_.carriage.lastMoveInput = 0
					end
				end
			else
				local v113_ = 0
				if v70_.carriage.followModeState == YarderTower.FOLLOW_MODE_ME then
					local v114_ = v70_.carriage.followModePlayer
					if v114_ ~= nil then
						local v115_, v116_, v117_ = getWorldTranslation(v114_.rootNode)
						local v118_, v119_, v120_
						v118_, v119_, v120_, v113_ = MathUtil.getClosestPointOnLineSegment(v102_, 0, v104_, v105_, 0, v107_, v115_, v116_, v117_)
					end
				end
				if v70_.carriage.followModeState == YarderTower.FOLLOW_MODE_PICKUP then
					v113_ = v70_.carriage.followModePickupPosition
				end
				local v121_ = v113_ - v70_.carriage.position
				local v122_ = math.sign(v121_)
				local v123_ = v111_ / v110_ * dt
				local v124_ = v113_ - v70_.carriage.position
				local v125_ = math.abs(v124_) * v110_ / 2
				local v126_ = v123_ * math.min(v125_, 1)
				v70_.carriage.targetSpeed = v122_ * v126_
				if v70_.carriage.followModeState ~= YarderTower.FOLLOW_MODE_ME then
					local v127_ = v113_ - v70_.carriage.position
					if math.abs(v127_) * v110_ < 0.1 then
						self:setYarderCarriageFollowMode(YarderTower.FOLLOW_MODE_NONE)
					end
				end
			end
			if v70_.carriage.lastLiftInput ~= 0 then
				if g_time - v70_.carriage.lastLiftInputTime > 250 then
					v70_.carriage.lastLiftInput = 0
				end
				v70_.carriage.vehicle:setCarriageLiftInput(v70_.carriage.lastLiftInput)
			end
			if v70_.requiresAttacherVehicle then
				if v70_.carriage.followModeState ~= YarderTower.FOLLOW_MODE_NONE or (v70_.carriage.lastLiftInput ~= 0 or v70_.carriage.lastMoveInput ~= 0) then
					v70_.requiresPowerTimeOffset = 10000
				end
				local v128_ = self:getAttacherVehicle()
				if v128_ ~= nil and v128_.startMotor ~= nil then
					if v70_.requiresPowerTimeOffset > 0 then
						v70_.requiresPowerTimeOffset = v70_.requiresPowerTimeOffset - dt
						if v128_:getIsMotorStarted() then
							local v129_ = v128_:getMotor()
							local v130_ = v129_:getMotorRotationAccelerationLimit()
							local v131_, v132_ = v129_:getRequiredMotorRpmRange()
							local v133_, _ = PowerConsumer.getTotalConsumedPtoTorque(v128_)
							local v134_ = v133_ / v129_:getPtoMotorRpmRatio()
							v128_:controlVehicle(0, 0, 0, v131_ * 3.141592653589793 / 30, v132_ * 3.141592653589793 / 30, v130_, 0, 0, v129_:getMaxClutchTorque(), v134_)
							v128_:raiseActive()
						elseif v128_:getCanMotorRun() then
							v128_:startMotor()
						end
					elseif (v128_.getIsControlled == nil or not v128_:getIsControlled()) and v128_:getIsMotorStarted() then
						v128_:stopMotor()
					end
				end
			end
			local v135_ = v70_.carriage
			local v136_ = v70_.carriage.position + v70_.carriage.speed
			v135_.position = math.clamp(v136_, 0, 1)
			local v137_ = v70_.carriage.targetSpeed - v70_.carriage.speed
			local v138_ = math.sign(v137_)
			local v139_ = v70_.carriage.speed
			local v140_ = v138_ * math.sign(v139_)
			local v141_ = v138_ == 1 and math.min or math.max
			v70_.carriage.speed = v141_(v70_.carriage.speed + v70_.carriage.maxSpeed / v110_ * dt * (v140_ == 1 and v70_.carriage.acceleration or v70_.carriage.deceleration) * v138_, v70_.carriage.targetSpeed)
			local v142_ = v108_ / v110_
			local v143_ = v70_.carriage.startOffset / v110_ + v142_ * 0.5
			local v144_ = v70_.carriage.endOffset / v110_ + v142_ * 0.5
			local v145_ = v143_ + v70_.carriage.position * (1 - (v143_ + v144_))
			local v146_, v147_, v148_ = MathUtil.vector3Lerp(v102_, v103_, v104_, v105_, v106_, v107_, v145_)
			local v149_ = v145_ * 3.141592653589793
			local v150_ = math.sin(v149_) * v70_.mainRope.maxOffset
			local v151_ = v109_ / v110_ * 0.5
			local v152_, v153_, v154_ = MathUtil.vector3Lerp(v102_, v103_, v104_, v105_, v106_, v107_, v145_ - v151_)
			local v155_ = (v145_ - v151_) * 3.141592653589793
			local v156_ = v153_ - math.sin(v155_) * v70_.mainRope.maxOffset
			local v157_, v158_, v159_ = MathUtil.vector3Lerp(v102_, v103_, v104_, v105_, v106_, v107_, v145_ + v151_)
			local v160_ = (v145_ + v151_) * 3.141592653589793
			local v161_ = v158_ - math.sin(v160_) * v70_.mainRope.maxOffset
			local v162_, v163_, v164_ = MathUtil.vector3Normalize(v157_ - v152_, v161_ - v156_, v159_ - v154_)
			setDirection(v70_.carriage.vehicle.rootNode, v162_, v163_, v164_, 0, 1, 0)
			local v165_, v166_, v167_ = getWorldRotation(v70_.carriage.vehicle.rootNode)
			if v70_.carriage.vehicle.isAddedToPhysics then
				v70_.carriage.vehicle:setWorldPosition(v146_, v147_ - v150_, v148_, v165_, v166_, v167_, 1, false)
			else
				v70_.carriage.vehicle:setAbsolutePosition(v146_, v147_ - v150_, v148_, v165_, v166_, v167_)
				v70_.carriage.vehicle:addToPhysics()
				v70_.carriage.vehicle:addWearAmount(self:getWearTotalAmount(), true)
				v70_.carriage.vehicle:setDamageAmount(self:getDamageAmount(), true)
				v70_.carriage.vehicle:addDirtAmount(self:getDirtAmount(), true)
			end
			v70_.carriage.vehicle:raiseActive()
		end
		if v70_.carriage.vehicle ~= nil and v70_.carriage.vehicle.getCarriagePullRopeTargetNode ~= nil then
			local v168_ = v70_.carriage.vehicle:getCarriagePullRopeTargetNode()
			if v168_ ~= nil then
				local v169_, v170_, v171_ = getWorldTranslation(v168_)
				local v172_ = self:updateYarderRope(v70_.pullRope, v169_, v170_, v171_, dt)
				v70_.carriage.vehicle:updateRopeAlignmentNodes(v70_.pullRope.ropeNode, v169_, v170_, v171_, v172_)
				local v173_, _ = v70_.carriage.vehicle:getCarriageDimensions()
				local v174_ = MathUtil.vector3Length(v105_ - v102_, v106_ - v103_, v107_ - v104_)
				local v175_ = (v173_ + 0.025) / v174_ * 0.5
				local v176_ = v70_.carriage.startOffset / v174_ + v175_
				local v177_ = v70_.carriage.endOffset / v174_ + v175_
				local v178_, v179_, v180_ = getWorldTranslation(v70_.carriage.vehicle.rootNode)
				local _, _, v181_ = worldToLocal(v70_.mainRope.ropeNode, v178_, v179_, v180_)
				local v182_ = (v181_ / v174_ - v176_) / (1 - (v176_ + v177_))
				local v183_ = math.clamp(v182_, 0, 1)
				local v184_ = v70_.carriage
				local v185_ = (v70_.carriage.lastPosition - v183_) / dt * v174_
				v184_.lastSpeed = math.abs(v185_) / v70_.carriage.maxSpeed
				local v186_ = v183_ - v70_.carriage.lastPosition
				if math.abs(v186_) * v174_ > 0.005 then
					if v70_.carriage.lastPosition < v183_ then
						if not g_soundManager:getIsSamplePlaying(v70_.samples.carriageMovePos) then
							g_soundManager:playSample(v70_.samples.carriageMovePos)
							g_soundManager:playSample(v70_.samples.carriageDriveMovePos)
							g_soundManager:stopSample(v70_.samples.carriageMoveNeg)
							g_soundManager:stopSample(v70_.samples.carriageDriveMoveNeg)
						end
					elseif not g_soundManager:getIsSamplePlaying(v70_.samples.carriageMoveNeg) then
						g_soundManager:playSample(v70_.samples.carriageMoveNeg)
						g_soundManager:playSample(v70_.samples.carriageDriveMoveNeg)
						g_soundManager:stopSample(v70_.samples.carriageMovePos)
						g_soundManager:stopSample(v70_.samples.carriageDriveMovePos)
					end
					if v183_ == 1 then
						g_soundManager:playSample(v70_.samples.carriageMovePosLimit)
						g_soundManager:playSample(v70_.samples.carriageDriveMovePosLimit)
					elseif v183_ == 0 then
						g_soundManager:playSample(v70_.samples.carriageMoveNegLimit)
						g_soundManager:playSample(v70_.samples.carriageDriveMoveNegLimit)
					end
					v70_.carriage.lastPosition = v183_
					v70_.carriage.lastPositionTimeOffset = 250
					if v70_.samples.carriageMovePos ~= nil and v70_.samples.carriageMovePos.soundNode ~= nil then
						setWorldTranslation(v70_.samples.carriageMovePos.soundNode, v178_, v179_, v180_)
					end
					if v70_.samples.carriageMoveNeg ~= nil and v70_.samples.carriageMoveNeg.soundNode ~= nil then
						setWorldTranslation(v70_.samples.carriageMoveNeg.soundNode, v178_, v179_, v180_)
					end
					if v70_.samples.carriageMovePosLimit ~= nil and v70_.samples.carriageMovePosLimit.soundNode ~= nil then
						setWorldTranslation(v70_.samples.carriageMovePosLimit.soundNode, v178_, v179_, v180_)
					end
					if v70_.samples.carriageMoveNegLimit ~= nil and v70_.samples.carriageMoveNegLimit.soundNode ~= nil then
						setWorldTranslation(v70_.samples.carriageMoveNegLimit.soundNode, v178_, v179_, v180_)
					end
					v70_.controlActivatable:updateActionEventTexts()
				elseif v70_.carriage.lastPositionTimeOffset > 0 then
					v70_.carriage.lastPositionTimeOffset = v70_.carriage.lastPositionTimeOffset - dt
					if v70_.carriage.lastPositionTimeOffset <= 0 then
						g_soundManager:stopSample(v70_.samples.carriageMovePos)
						g_soundManager:stopSample(v70_.samples.carriageDriveMovePos)
						g_soundManager:stopSample(v70_.samples.carriageMoveNeg)
						g_soundManager:stopSample(v70_.samples.carriageDriveMoveNeg)
					end
				end
			end
			if v70_.pushRope.isActive ~= nil then
				local v187_ = v70_.carriage.vehicle:getCarriagePushRopeTargetNode()
				if v187_ ~= nil then
					v70_.pushRope.hookData:setTargetNode(v187_, false)
					setWorldTranslation(v70_.pushRope.ropeNode, v70_.pushRope.hookData:getRopeTargetPosition())
					local v188_, v189_, v190_ = getWorldTranslation(v187_)
					self:updateYarderRope(v70_.pushRope, v188_, v189_, v190_, dt)
				end
			end
			local v191_, _ = self:getIsPlayerInYarderControlRange()
			if v191_ then
				v70_.carriage.vehicle:updateCarriageInRange(dt)
				if v70_.hudExtension ~= nil then
					g_currentMission.hud:addInfoExtension(v70_.hudExtension)
				end
			elseif v70_.carriage.lastPlayerInRange then
				v70_.carriage.vehicle:onYarderCarriageUpdateEnd()
			end
			v70_.carriage.lastPlayerInRange = v191_
		end
		local _ = v70_.updateRopesDirtyTime > 0
		v70_.updateRopesDirtyTime = v70_.updateRopesDirtyTime - dt
		self:updateYarderRope(v70_.mainRope, v105_, v106_, v107_, dt)
		for v192_ = 1, #v70_.supportRopes.ropes do
			local v193_ = v70_.supportRopes.ropes[v192_]
			if v193_.isActive then
				self:updateYarderRope(v193_, v193_.target[1], v193_.target[2], v193_.target[3], dt)
			end
		end
		if v70_.carriage.vehicle ~= nil then
			if not g_soundManager:getIsSamplePlaying(v70_.samples.motor) then
				g_soundManager:playSample(v70_.samples.motor)
				v70_.lastMotorRpm = 0
				g_effectManager:startEffects(v70_.motorEffects)
			end
			if v70_.carriage.lastPositionTimeOffset > 0 then
				v70_.lastMotorPowerTimeOffset = 10000
			else
				local v194_ = v70_.lastMotorPowerTimeOffset - dt
				v70_.lastMotorPowerTimeOffset = math.max(v194_, 0)
			end
			local v195_ = 0.33 * v70_.carriage.lastSpeed
			local v196_ = v70_.lastMotorPowerTimeOffset <= 0 and 0 or 0.5 + v70_.carriage.lastSpeed * 0.5
			v70_.lastMotorRpm = v70_.lastMotorRpm * 0.975 + v196_ * 0.025
			local v197_ = v195_ + v70_.carriage.vehicle:getNumAttachedTrees() / v70_.carriage.vehicle:getMaxNumAttachedTrees() * v70_.carriage.lastSpeed * (1 - v195_)
			g_soundManager:setSampleLoopSynthesisParameters(v70_.samples.motor, v70_.lastMotorRpm, v197_)
			g_effectManager:setDensity(v70_.motorEffects, v70_.lastMotorRpm)
		end
		self:raiseActive()
	end
end

-- Local values: spec
function YarderTower:onYarderCarriageTreeAttached(treeId)
	local v199_ = self.spec_yarderTower
	v199_.carriage.followModePickupPosition = v199_.carriage.lastPosition
	v199_.controlActivatable:updateActionEventTexts()
end

-- Local values: rootVehicle
function YarderTower:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex, loadFromSavegame)
	local v201_ = self.rootVehicle
	if v201_.registerPlayerVehicleControlAllowedFunction ~= nil then
		v201_:registerPlayerVehicleControlAllowedFunction(self, YarderTower.getIsVehicleControlAllowed)
	end
end

-- Local values: hookNode
function YarderTower:onHookI3DLoaded(i3dNode, failedReason, hookData)
	if i3dNode ~= 0 then
		local v204_ = getChildAt(i3dNode, 0)
		link(getRootNode(), v204_)
		setVisibility(v204_, false)
		hookData.hookNode = v204_
		delete(i3dNode)
	end
end

-- Local values: ropeNode
function YarderTower:onRopeI3DLoaded(i3dNode, failedReason, ropeData)
	if i3dNode ~= 0 then
		local v208_ = I3DUtil.indexToObject(i3dNode, ropeData.ropeNodePath)
		if v208_ ~= nil then
			link(ropeData.node or self.rootNode, v208_)
			setVisibility(v208_, false)
			ropeData.ropeNode = v208_
		end
		delete(i3dNode)
	end
end

-- Local values: spec, time
function YarderTower:getIsSetupModeChangeAllowed()
	local v210_ = self.spec_yarderTower
	if v210_.setupModeState then
		return true
	end
	if v210_.requiresLowering and not self:getIsLowered() then
		return false, string.format(v210_.texts.warningLowerFirst, self:getName())
	end
	if self.getFoldAnimTime ~= nil then
		local v211_ = self:getFoldAnimTime()
		if v211_ < v210_.foldMinLimit or v210_.foldMaxLimit < v211_ then
			return false, string.format(v210_.texts.warningUnfoldFirst, self:getName())
		end
	end
	return true
end

-- Local values: spec
function YarderTower:setYarderSetupModeState(state, canceled)
	local v215_ = self.spec_yarderTower
	if state == nil then
		state = not v215_.setupModeState
	end
	v215_.setupModeState = state
	if state then
		g_soundManager:playSample(v215_.samples.setupStarted)
		self:setYarderTargetActive(false)
		self:setYarderRopeState(v215_.setupRope, true)
		self:raiseActive()
	else
		self:setYarderRopeState(v215_.setupRope, false)
		if not self.spec_yarderTower.isPlayerInRange then
			g_currentMission.activatableObjectsSystem:removeActivatable(v215_.setupActivatable)
		end
		if canceled then
			g_soundManager:playSample(v215_.samples.setupCanceled)
		end
	end
end

-- Local values: spec, x, y, z, shapeId, sx, sy, sz, centerX, centerY, centerZ, yRot, data, i, component, i, supportRope, i, component
function YarderTower:setYarderTargetActive(state, noEventSend)
	local v219_ = self.spec_yarderTower
	if state then
		if v219_.mainRope.isValid then
			local v220_ = v219_.mainRope.target[1]
			local v221_ = v219_.mainRope.target[2]
			local v222_ = v219_.mainRope.target[3]
			local v223_ = self:getTreeAtPosition(v220_, v221_, v222_, 3)
			if v223_ ~= nil and v223_ ~= 0 then
				local v224_, v225_, v226_ = getWorldTranslation(v219_.mainRope.node)
				v219_.mainRope.hookData = v219_.hooks.treeData:clone()
				local v227_, v228_, v229_ = v219_.mainRope.hookData:mountToTree(v223_, v220_, v221_, v222_, 4, v224_, v225_, v226_)
				if v227_ == nil then
					return
				end
				v219_.mainRope.hookData:setTargetNode(v219_.mainRope.node, false)
				local v230_ = v219_.mainRope.target
				local v231_ = v219_.mainRope.target
				local v232_ = v219_.mainRope.target
				local v233_, v234_, v235_ = v219_.mainRope.hookData:getRopeTargetPosition()
				v230_[1] = v233_
				v231_[2] = v234_
				v232_[3] = v235_
				if v219_.mainRope.sampleRopeLinkTree ~= nil and v219_.mainRope.sampleRopeLinkTree.soundNode ~= nil then
					setWorldTranslation(v219_.mainRope.sampleRopeLinkTree.soundNode, v227_, v228_, v229_)
					g_soundManager:playSample(v219_.mainRope.sampleRopeLinkTree)
				end
				v219_.mainRope.isActive = true
				v219_.mainRope.treeId = v223_
				if v219_.pushRope.ropeNode ~= nil then
					v219_.pushRope.hookData = v219_.hooks.treeData:clone()
					v219_.pushRope.hookData:mountToTree(v223_, v220_, v221_ - v219_.pushRope.yOffset, v222_, 4, v224_, v225_ - v219_.pushRope.yOffset, v226_)
					self:setYarderRopeState(v219_.pushRope, true)
				end
				g_splitShapeManager:addActiveYarder(self)
				g_soundManager:playSample(v219_.samples.setupFinished)
				self:raiseActive()
				self:setYarderSetupModeState(false, false)
				self:setupSupportRopes()
				if self.isServer then
					if v219_.carriage.filename == nil then
						Logging.error("Carriage vehicle could not be loaded")
					else
						local v236_ = MathUtil.getYRotationFromDirection(MathUtil.vector2Normalize(v220_ - v224_, v222_ - v226_))
						local v237_ = VehicleLoadingData.new()
						v237_:setFilename(v219_.carriage.filename)
						v237_:setPosition(v219_.mainRope.target[1], v219_.mainRope.target[2], v219_.mainRope.target[3])
						v237_:setRotation(0, v236_, 0)
						v237_:setPropertyState(VehiclePropertyState.OWNED)
						v237_:setOwnerFarmId(self:getOwnerFarmId())
						v237_:load(self.onCreateCarriageFinished, self)
					end
					for v238_ = 1, #self.components do
						local v239_ = self.components[v238_]
						setRigidBodyType(v239_.node, RigidBodyType.KINEMATIC)
						v239_.isDynamic = false
						v239_.isKinematic = true
					end
				end
				v219_.updateRopesDirtyTime = 500
				g_currentMission.activatableObjectsSystem:addActivatable(v219_.controlActivatable)
				YarderTowerSetTargetEvent.sendEvent(self, true, v227_, v228_, v229_, noEventSend)
			end
		end
		v219_.treeRaycast.hasStarted = false
		v219_.treeRaycast.lastValidTree = nil
	else
		if self.isClient and v219_.mainRope.isActive then
			g_soundManager:playSample(v219_.samples.removeYarder)
			if g_soundManager:getIsSamplePlaying(v219_.samples.motor) then
				g_soundManager:stopSample(v219_.samples.motor)
				g_effectManager:stopEffects(v219_.motorEffects)
			end
		end
		v219_.mainRope.isValid = false
		v219_.mainRope.isActive = false
		v219_.mainRope.treeId = nil
		if not g_currentMission.isExitingGame then
			g_splitShapeManager:removeActiveYarder(self)
		end
		for v240_ = 1, #v219_.supportRopes.ropes do
			local v241_ = v219_.supportRopes.ropes[v240_]
			self:setYarderRopeState(v241_, false)
			v241_.treeId = nil
		end
		self:setYarderRopeState(v219_.pushRope, false)
		if v219_.carriage.vehicle ~= nil then
			if self.isServer then
				v219_.carriage.vehicle:setYarderTowerVehicle(nil)
				v219_.carriage.vehicle:delete()
			end
			v219_.carriage.vehicle = nil
			v219_.carriage.lastPlayerInRange = false
		end
		v219_.carriage.position = 0
		g_currentMission.activatableObjectsSystem:removeActivatable(v219_.controlActivatable)
		if self.isServer then
			for v242_ = 1, #self.components do
				local v243_ = self.components[v242_]
				setRigidBodyType(v243_.node, RigidBodyType.DYNAMIC)
				v243_.isDynamic = true
				v243_.isKinematic = false
			end
		end
		YarderTowerSetTargetEvent.sendEvent(self, false, 0, 0, 0, noEventSend)
	end
	self:setYarderRopeState(v219_.mainRope, v219_.mainRope.isActive)
	self:setYarderRopeState(v219_.pullRope, v219_.mainRope.isActive)
end

-- Local values: spec, _, player
function YarderTower:setYarderCarriageFollowMode(state, connection, noEventSend)
	local v248_ = self.spec_yarderTower
	if state == nil then
		state = YarderTower.FOLLOW_MODE_NONE
	end
	v248_.carriage.followModeState = state
	if state == YarderTower.FOLLOW_MODE_ME then
		if self.isServer then
			if connection == nil then
				v248_.carriage.followModePlayer = g_localPlayer
				v248_.carriage.followModePlayer:addDeleteListener(self, "onYarderTowerPlayerDeleted")
			else
				for _, v249_ in pairs(g_currentMission.playerSystem.players) do
					if v249_.connection == connection then
						v248_.carriage.followModePlayer = v249_
						v248_.carriage.followModePlayer:addDeleteListener(self, "onYarderTowerPlayerDeleted")
					end
				end
			end
		end
		if connection == nil then
			v248_.carriage.followModeLocalPlayer = true
		end
	else
		if v248_.carriage.followModePlayer ~= nil then
			v248_.carriage.followModePlayer:removeDeleteListener(self, "onYarderTowerPlayerDeleted")
		end
		v248_.carriage.followModePlayer = nil
		v248_.carriage.followModeLocalPlayer = false
	end
	YarderTowerFollowModeEvent.sendEvent(self, state, noEventSend)
	v248_.controlActivatable:updateActionEventTexts()
end

-- Local values: spec
function YarderTower:setYarderCarriageMoveInput(direction)
	local v252_ = self.spec_yarderTower
	if direction ~= 0 and v252_.carriage.followModeState ~= YarderTower.FOLLOW_MODE_NONE then
		self:setYarderCarriageFollowMode(YarderTower.FOLLOW_MODE_NONE)
	end
	v252_.carriage.lastMoveInput = direction or 0
	v252_.carriage.lastMoveInputTime = g_time
	if v252_.carriage.lastMoveInput ~= 0 then
		self:raiseDirtyFlags(v252_.dirtyFlag)
	end
end

-- Local values: spec
function YarderTower:setYarderCarriageLiftInput(direction)
	local v255_ = self.spec_yarderTower
	v255_.carriage.lastLiftInput = direction or 0
	v255_.carriage.lastLiftInputTime = g_time
	if v255_.carriage.lastLiftInput ~= 0 then
		self:raiseDirtyFlags(v255_.dirtyFlag)
	end
end

function YarderTower:onYarderCarriageAttach()
	self.spec_yarderTower.carriage.vehicle:onAttachTreeAction()
end

function YarderTower:onYarderCarriageDetach()
	self.spec_yarderTower.carriage.vehicle:onDetachTreeAction()
end

-- Local values: spec, x, y, z, j, i, getBestTreeIndex, mountToTree, treesToAttach, i, supportRope, treeId, angle, usedTrees, i, treeData, i, treeData, treeId, _, i, supportRope, rx, _, rz, sx, sy, sz, ex, ey, ez, dx, dy, dz, distance
function YarderTower:setupSupportRopes()
	local v_u_259_ = self.spec_yarderTower
	local v260_, v261_, v262_ = getWorldTranslation(v_u_259_.supportRopes.centerNode)
	for v263_ = 1, #v_u_259_.supportRopes.ropes do
		self:setYarderRopeState(v_u_259_.supportRopes.ropes[v263_], false)
	end
	for v264_ = #v_u_259_.supportRopes.foundTrees, 1, -1 do
		v_u_259_.supportRopes.foundTrees[v264_] = nil
	end
	overlapSphere(v260_, v261_, v262_, v_u_259_.supportRopes.treeRadius, "onSupportRopeTreeOverlapCallback", self, CollisionFlag.TREE, false, false, true, false)
	local function v280_(p265_, p266_)
		-- upvalues: (copy) v_u_259_
		local v267_ = math.huge
		local v268_ = nil
		for v269_ = 1, #v_u_259_.supportRopes.foundTrees do
			local v270_ = v_u_259_.supportRopes.foundTrees[v269_]
			local v271_, v272_, v273_ = getWorldTranslation(v270_)
			local v274_, _, v275_ = MathUtil.vector3Normalize(worldToLocal(p265_, v271_, v272_, v273_))
			local v276_, v277_ = MathUtil.vector2Normalize(v274_, v275_)
			local v278_ = MathUtil.getYRotationFromDirection(v276_, v277_)
			local v279_ = math.abs(v278_)
			if v279_ < p266_ and v279_ < v267_ then
				v268_ = v270_
				v267_ = v279_
			end
		end
		return v268_, v267_
	end
	local v281_ = {}
	local function v304_(p282_, p283_)
		-- upvalues: (copy) v_u_259_, (copy) self
		for v284_ = 1, #v_u_259_.supportRopes.foundTrees do
			local v285_ = v_u_259_.supportRopes.foundTrees[v284_]
			if v285_ == p283_ then
				local v286_, v287_, v288_ = getWorldTranslation(v285_)
				local v289_ = getTerrainHeightAtWorldPos
				local v290_ = g_terrainNode
				local v291_ = math.max(v287_, v289_(v290_, v286_, 0, v288_))
				local v292_, v293_, v294_, _, _, _, _ = SplitShapeUtil.getTreeOffsetPosition(v285_, v286_, v291_ + p282_.treeYOffset, v288_, 3)
				if v292_ ~= nil then
					self:setYarderRopeState(p282_, true)
					local v295_, v296_, v297_ = getWorldTranslation(p282_.node)
					p282_.hookData = v_u_259_.hooks.treeData:clone()
					p282_.hookData:mountToTree(v285_, v292_, v293_, v294_, 4, v295_, v296_, v297_)
					p282_.hookData:setTargetNode(v_u_259_.mainRope.node, false)
					p282_.treeId = v285_
					local v298_ = p282_.target
					local v299_ = p282_.target
					local v300_ = p282_.target
					local v301_, v302_, v303_ = p282_.hookData:getRopeTargetPosition()
					v298_[1] = v301_
					v299_[2] = v302_
					v300_[3] = v303_
					if p282_.sampleRopeLinkTree ~= nil and p282_.sampleRopeLinkTree.soundNode ~= nil then
						setWorldTranslation(p282_.sampleRopeLinkTree.soundNode, v292_, v293_, v294_)
						g_soundManager:playSample(p282_.sampleRopeLinkTree)
					end
					table.remove(v_u_259_.supportRopes.foundTrees, v284_)
					return true
				end
			end
		end
		return false
	end
	for v305_ = 1, #v_u_259_.supportRopes.ropes do
		local v306_ = v_u_259_.supportRopes.ropes[v305_]
		local v307_, v308_ = v280_(v306_.angleReferenceNode, v306_.maxAngle)
		if v307_ ~= nil then
			table.insert(v281_, {
				["supportRope"] = v306_,
				["treeId"] = v307_,
				["angle"] = v308_
			})
		end
	end
	table.sort(v281_, function(p309_, p310_)
		return p309_.angle > p310_.angle
	end)
	local v311_ = {}
	for v312_ = #v281_, 1, -1 do
		local v313_ = v281_[v312_]
		if v311_[v313_.treeId] == nil and v304_(v313_.supportRope, v313_.treeId) then
			v311_[v313_.treeId] = true
			table.remove(v281_, v312_)
		end
	end
	for v314_ = 1, #v281_ do
		local v315_ = v281_[v314_]
		local v316_, _ = v280_(v315_.supportRope.angleReferenceNode, v315_.supportRope.maxAngle)
		if v316_ ~= nil then
			v304_(v315_.supportRope, v316_)
		end
	end
	for v317_ = 1, #v_u_259_.supportRopes.ropes do
		local v318_ = v_u_259_.supportRopes.ropes[v317_]
		if not v318_.isActive then
			if v318_.rotNode ~= nil and v318_.raycastRotY ~= nil then
				local v319_, _, v320_ = getRotation(v318_.rotNode)
				setRotation(v318_.rotNode, v319_, v318_.raycastRotY, v320_)
				if self.setMovingToolDirty ~= nil then
					self:setMovingToolDirty(v318_.rotNode)
				end
			end
			local v321_, v322_, v323_ = getWorldTranslation(v318_.raycastNode)
			local v324_, v325_, v326_ = localToWorld(v318_.raycastNode, 0, 0, YarderTower.TERRAIN_RAYCAST_DISTANCE)
			local v327_ = getTerrainHeightAtWorldPos(g_terrainNode, v324_, 0, v326_) - 0.25
			local v328_ = math.min(v325_, v327_)
			local v329_ = v324_ - v321_
			local v330_ = v328_ - v322_
			local v331_ = v326_ - v323_
			local v332_ = MathUtil.vector3Length(v329_, v330_, v331_)
			local v333_, v334_, v335_ = MathUtil.vector3Normalize(v329_, v330_, v331_)
			raycastClosestAsync(v321_, v322_, v323_, v333_, v334_, v335_, v332_, "onYarderSupportTerrainRaycastCallback", v318_, YarderTower.GROUND_COLLISION_MASK)
		end
	end
end

-- Local values: spec, vehicle
function YarderTower:onCreateCarriageFinished(vehicles, vehicleLoadState, arguments)
	local v339_ = self.spec_yarderTower
	if #vehicles == 1 and vehicleLoadState == VehicleLoadingState.OK then
		local v340_ = vehicles[1]
		v339_.carriage.vehicle = v340_
		v340_:addDeleteListener(self, "onCarriageVehicleDeleted")
		v340_:setYarderTowerVehicle(self)
		v340_:removeFromPhysics()
	else
		Logging.error("Failed to load yarder carriage \'%s\'", v339_.carriage.filename)
	end
end

-- Local values: spec
function YarderTower:onCarriageVehicleDeleted(rope, state)
	local v342_ = self.spec_yarderTower
	v342_.carriage.vehicle = nil
	v342_.carriage.lastPlayerInRange = nil
end

function YarderTower:setYarderRopeState(rope, state)
	rope.isActive = state
	if rope.ropeNode ~= nil then
		setVisibility(rope.ropeNode, state)
	end
	if rope.rotNode ~= nil and not state then
		local v346_ = setRotation
		local v347_ = rope.rotNode
		local v348_ = rope.rotNodeInitRot
		v346_(v347_, unpack(v348_))
		if self.setMovingToolDirty ~= nil then
			self:setMovingToolDirty(rope.rotNode)
		end
	end
	if not state then
		if rope.hookData ~= nil then
			rope.hookData:delete()
			rope.hookData = nil
		end
		self:updateYarderRopeLengthNodes(rope, 0)
	end
	ObjectChangeUtil.setObjectChanges(rope.changeObjects, state, self, self.setMovingToolDirty)
end

-- Local values: x1, y1, z1, totalRopeLength, maxOffset, dirX, dirY, dirZ, lDirX, lDirY, lDirZ, lDirX, lDirY, lDirZ, boundingRadius
function YarderTower:updateYarderRope(rope, tx, ty, tz, dt, isSupportRope, emissiveColor)
	local v354_, v355_, v356_ = getWorldTranslation(rope.node or rope.ropeNode)
	local v357_ = MathUtil.vector3Length(tx - v354_, ty - v355_, tz - v356_)
	local v358_ = rope.maxOffset or 0
	local v359_ = v357_ / (rope.offsetReferenceLength or 0)
	local v360_ = v358_ * math.min(v359_, 1)
	if v357_ ~= rope.lastTotalRopeLength then
		local v361_, v362_, v363_ = MathUtil.vector3Normalize(tx - v354_, ty - v355_, tz - v356_)
		if rope.rotNode ~= nil then
			local v364_, v365_, v366_ = worldDirectionToLocal(getParent(rope.rotNode), v361_, v362_, v363_)
			if rope.rotNodeAllAxis then
				local v367_, v368_, v369_ = MathUtil.vector3Normalize(v364_, v365_, v366_)
				setDirection(rope.rotNode, v367_, v368_, v369_, 0, 1, 0)
			else
				local v370_, v371_ = MathUtil.vector2Normalize(v364_, v366_)
				setDirection(rope.rotNode, v370_, 0, v371_, 0, 1, 0)
			end
			if self.setMovingToolDirty ~= nil then
				self:setMovingToolDirty(rope.rotNode)
			end
		end
		if rope.ropeNode ~= nil then
			local v372_, v373_, v374_ = worldDirectionToLocal(getParent(rope.ropeNode), v361_, v362_, v363_)
			setDirection(rope.ropeNode, v372_, v373_, v374_, 0, 1, 0)
			g_animationManager:setPrevShaderParameter(rope.ropeNode, "ropeLengthBendSizeUv", v357_, -v360_, rope.diameter, 4, false, "prevRopeLengthBendSizeUv")
			local v375_ = math.ceil(v357_)
			local v376_ = math.max(v375_, 1) * 0.5
			if math.ceil(v376_) ~= rope.boundingRadius then
				setShapeBoundingSphere(rope.ropeNode, 0, 0, v376_, v376_)
				rope.boundingRadius = v376_
			end
		end
		self:updateYarderRopeLengthNodes(rope, v357_)
		rope.lastTotalRopeLength = v357_
	end
	return v360_
end

-- Local values: i, ropeLengthNode, alpha, x, y, z, x, y, z, x, y, z
function YarderTower:updateYarderRopeLengthNodes(rope, length)
	if rope.ropeLengthNodes ~= nil then
		for v379_ = 1, #rope.ropeLengthNodes do
			local v380_ = rope.ropeLengthNodes[v379_]
			local v381_ = MathUtil.inverseLerp(v380_.minLength, v380_.maxLength, length)
			if v380_.minRot ~= nil and v380_.maxRot ~= nil then
				local v382_, v383_, v384_ = MathUtil.vector3ArrayLerp(v380_.minRot, v380_.maxRot, v381_)
				setRotation(v380_.node, v382_, v383_, v384_)
			end
			if v380_.minTrans ~= nil and v380_.maxTrans ~= nil then
				local v385_, v386_, v387_ = MathUtil.vector3ArrayLerp(v380_.minTrans, v380_.maxTrans, v381_)
				setTranslation(v380_.node, v385_, v386_, v387_)
			end
			if v380_.minScale ~= nil and v380_.maxScale ~= nil then
				local v388_, v389_, v390_ = MathUtil.vector3ArrayLerp(v380_.minScale, v380_.maxScale, v381_)
				setScale(v380_.node, v388_, v389_, v390_)
			end
			if v380_.shaderParameterName ~= nil and (v380_.minShaderParameter ~= nil and v380_.maxShaderParameter ~= nil) then
				setShaderParameter(v380_.node, v380_.shaderParameterName, MathUtil.lerp(v380_.minShaderParameter[1], v380_.maxShaderParameter[1], v381_), MathUtil.lerp(v380_.minShaderParameter[2], v380_.maxShaderParameter[2], v381_), MathUtil.lerp(v380_.minShaderParameter[3], v380_.maxShaderParameter[3], v381_), MathUtil.lerp(v380_.minShaderParameter[4], v380_.maxShaderParameter[4], v381_), false)
			end
		end
	end
end

-- Local values: cx, cy, cz, nx, ny, nz, yx, yy, yz, shapeId, _, _, _, _
function YarderTower:getTreeAtPosition(x, y, z, maxRadius)
	local v395_ = x - maxRadius * 0.5
	local v396_ = z - maxRadius * 0.5
	local v397_, _, _, _, _ = findSplitShape(v395_, y, v396_, 0, 1, 0, 0, 0, 1, maxRadius, maxRadius)
	return v397_
end

-- Local values: spec
function YarderTower:getIsPlayerInYarderRange()
	local v399_ = self.spec_yarderTower
	if self:getOwnerFarmId() == g_currentMission:getFarmId() then
		return v399_.isPlayerInRange or v399_.setupModeState
	else
		return false
	end
end

-- Local values: spec, x1, _, z1, x2, z2, tx, _, tz, distance
function YarderTower:getIsPlayerInYarderControlRange(x, y, z)
	local v404_ = self.spec_yarderTower
	if v404_.isPlayerInRange then
		return false, math.huge
	end
	if x == nil then
		if g_localPlayer == nil then
			return false
		end
		x, y, z = getWorldTranslation(g_localPlayer.rootNode)
	end
	if self:getOwnerFarmId() ~= g_currentMission:getFarmId() then
		return false
	end
	local v405_, _, v406_ = getWorldTranslation(v404_.mainRope.node)
	local v407_ = v404_.mainRope.target[1]
	local v408_ = v404_.mainRope.target[3]
	local v409_, _, v410_ = MathUtil.getClosestPointOnLineSegment(v405_, 0, v406_, v407_, 0, v408_, x, y, z)
	local v411_ = MathUtil.vector2Length(x - v409_, z - v410_)
	return v411_ < YarderTower.MAX_CONTROL_DISTANCE, v411_
end

function YarderTower:getYarderIsSetUp()
	return self.spec_yarderTower.carriage.vehicle ~= nil
end

-- Local values: spec, isLoaded, targetPosition, x, y, z, x1, _, z1, x2, z2, _, _, _, playerPosition
function YarderTower:getYarderStatusInfo()
	local v414_ = self.spec_yarderTower
	local v415_
	if v414_.carriage.vehicle == nil then
		v415_ = false
	else
		v415_ = #v414_.carriage.vehicle.spec_yarderCarriage.attachedTrees > 0
	end
	local v416_ = nil
	if v414_.carriage.followModeState == YarderTower.FOLLOW_MODE_HOME then
		v416_ = 0
	elseif v414_.carriage.followModeState == YarderTower.FOLLOW_MODE_PICKUP then
		v416_ = v414_.carriage.followModePickupPosition
	end
	if g_localPlayer == nil or not g_localPlayer.isControlled then
		return false, v415_, 0, v414_.carriage.lastPosition, v414_.carriage.followModeState, v414_.carriage.followModeLocalPlayer, v416_
	end
	local v417_, v418_, v419_ = getWorldTranslation(g_localPlayer.rootNode)
	local v420_, _, v421_ = getWorldTranslation(v414_.mainRope.node)
	local v422_ = v414_.mainRope.target[1]
	local v423_ = v414_.mainRope.target[3]
	local _, _, _, v424_ = MathUtil.getClosestPointOnLineSegment(v420_, 0, v421_, v422_, 0, v423_, v417_, v418_, v419_)
	return true, v415_, v424_, v414_.carriage.lastPosition, v414_.carriage.followModeState, v414_.carriage.followModeLocalPlayer, v416_
end

-- Local values: spec, x1, y1, z1, x2, y2, z2
function YarderTower:getYarderMainRopeLength()
	local v426_ = self.spec_yarderTower
	if not v426_.mainRope.isValid then
		return 0
	end
	local v427_, v428_, v429_ = getWorldTranslation(v426_.mainRope.node)
	local v430_ = v426_.mainRope.target[1]
	local v431_ = v426_.mainRope.target[2]
	local v432_ = v426_.mainRope.target[3]
	return MathUtil.vector3Length(v430_ - v427_, v431_ - v428_, v432_ - v429_)
end

function YarderTower:getYarderCarriageLastSpeed()
	return self.spec_yarderTower.carriage.lastSpeed
end
g_soundManager:registerModifierType("CARRIAGE_SPEED", YarderTower.getYarderCarriageLastSpeed)

-- Local values: spec, j, supportRope
function YarderTower:getIsTreeShapeUsedForYarderSetup(shape)
	local v436_ = self.spec_yarderTower
	if shape == v436_.mainRope.treeId then
		return true
	end
	for v437_ = 1, #v436_.supportRopes.ropes do
		if v436_.supportRopes.ropes[v437_].treeId == shape then
			return true
		end
	end
	return false
end

-- Local values: spec
function YarderTower:onYarderControlTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if (onEnter or onLeave) and (g_localPlayer ~= nil and otherId == g_localPlayer.rootNode) then
		local v442_ = self.spec_yarderTower
		if onEnter then
			self.spec_yarderTower.isPlayerInRange = true
			g_currentMission.activatableObjectsSystem:addActivatable(v442_.setupActivatable)
			return
		end
		self.spec_yarderTower.isPlayerInRange = false
		if not v442_.setupModeState then
			g_currentMission.activatableObjectsSystem:removeActivatable(v442_.setupActivatable)
		end
	end
end

-- Local values: spec
function YarderTower:onYarderTreeRaycastCallback(hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	local v447_ = self.spec_yarderTower
	if hitObjectId ~= 0 and (getHasClassId(hitObjectId, ClassIds.SHAPE) and (getSplitType(hitObjectId) ~= 0 and not getIsSplitShapeSplit(hitObjectId))) then
		if isLast then
			v447_.treeRaycast.hasStarted = false
			v447_.treeRaycast.lastValidTree = hitObjectId
			v447_.treeRaycast.lastValidTreeHeight = y
		end
		return false
	end
	if isLast then
		v447_.treeRaycast.hasStarted = false
		v447_.treeRaycast.lastValidTree = nil
	end
end

-- Local values: sx, sy, sz, dx, dz, ldx, _, ldz, angle, centerX, centerY, centerZ, _, _, _, radius, length, wdx, wdy, wdz
function YarderTower:doRopePlacementValidation(ropeNode, treeId, ex, ey, ez, maxAngle, maxLength, clearance, minTreeDiameter, callbackData)
	if not callbackData.hasStarted then
		local v458_, v459_, v460_ = getWorldTranslation(ropeNode)
		if v459_ + self.spec_yarderTower.placementMinHeightOffset < ey then
			return callbackData.callback(callbackData.vehicle, false, ex, ey, ez, YarderTower.FAILED_REASON_ONLY_UPHILL_YARDING)
		end
		local v461_, v462_ = MathUtil.vector2Normalize(v458_ - ex, v460_ - ez)
		local v463_, _, v464_ = worldDirectionToLocal(ropeNode, v461_, 0, v462_)
		local v465_ = MathUtil.getYRotationFromDirection(v463_, v464_)
		local v466_ = 3.141592653589793 - math.abs(v465_)
		local v467_, v468_, v469_, _, _, _, v470_ = SplitShapeUtil.getTreeOffsetPosition(treeId, ex, ey, ez, 3)
		if v467_ ~= nil and minTreeDiameter <= v470_ * 2 then
			local v471_, v472_ = MathUtil.vector2Normalize(v458_ - v467_, v460_ - v469_)
			local v473_ = v467_ + v471_ * v470_
			local v474_ = v469_ + v472_ * v470_
			if v466_ < maxAngle then
				local v475_ = MathUtil.vector3Length(v473_ - v458_, v468_ - v459_, v474_ - v460_)
				if v475_ < maxLength then
					local v476_, v477_, v478_ = MathUtil.vector3Normalize(v473_ - v458_, v468_ - v459_, v474_ - v460_)
					callbackData.x = v473_
					callbackData.y = v468_
					callbackData.z = v474_
					callbackData.hasStarted = true
					callbackData.onYarderMainTreeRaycastCallback = YarderTower.onYarderMainTreeRaycastCallback
					raycastClosestAsync(v458_, v459_ - 2, v460_, v476_, v477_, v478_, v475_ - 0.5, "onYarderMainTreeRaycastCallback", callbackData, YarderTower.GROUND_COLLISION_MASK)
				else
					callbackData.callback(callbackData.vehicle, false, v473_, v468_, v474_, YarderTower.FAILED_REASON_TOO_LONG)
				end
			else
				callbackData.callback(callbackData.vehicle, false, v473_, v468_, v474_, YarderTower.FAILED_REASON_WRONG_ANGLE)
				return
			end
		end
		callbackData.callback(callbackData.vehicle, false, ex, ey, ez, YarderTower.FAILED_REASON_TREE_TOO_SMALL)
	end
end

function YarderTower.onYarderMainTreeRaycastCallback(callbackData, hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	callbackData.hasStarted = false
	if hitObjectId ~= 0 then
		return callbackData.callback(callbackData.vehicle, false, callbackData.x, callbackData.y, callbackData.z, YarderTower.FAILED_REASON_WAY_BLOCKED)
	end
	if hitObjectId == 0 and isLast then
		return callbackData.callback(callbackData.vehicle, true, callbackData.x, callbackData.y, callbackData.z, YarderTower.FAILED_REASON_NONE)
	end
end

-- Local values: spec
function YarderTower:onMainRopePlacementValidated(isValid, x, y, z, reason)
	local v488_ = self.spec_yarderTower
	if v488_.setupModeState then
		v488_.mainRope.isValid = isValid
		v488_.mainRope.target[1] = x
		v488_.mainRope.target[2] = y
		v488_.mainRope.target[3] = z
	end
	if not isValid then
		if reason == YarderTower.FAILED_REASON_TOO_LONG then
			g_currentMission:showBlinkingWarning(v488_.texts.warningRopeTooLong, 1000)
		elseif reason == YarderTower.FAILED_REASON_WRONG_ANGLE then
			g_currentMission:showBlinkingWarning(v488_.texts.warningWrongAngle, 1000)
		elseif reason == YarderTower.FAILED_REASON_TREE_TOO_SMALL then
			g_currentMission:showBlinkingWarning(v488_.texts.warningTreeTooSmall, 1000)
		elseif reason == YarderTower.FAILED_REASON_WAY_BLOCKED then
			g_currentMission:showBlinkingWarning(v488_.texts.warningWayIsBlocked, 1000)
		elseif reason == YarderTower.FAILED_REASON_ONLY_UPHILL_YARDING then
			g_currentMission:showBlinkingWarning(v488_.texts.warningOnlyForUphillYarding, 1000)
		end
	end
	v488_.setupRope.diameter = v488_.setupRope.diameterTree
end

-- Local values: sx, _, sz, spec
function YarderTower.onYarderSupportTerrainRaycastCallback(supportRope, hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	if hitObjectId ~= 0 and getHasClassId(hitObjectId, ClassIds.TERRAIN_TRANSFORM_GROUP) then
		supportRope.vehicle:setYarderRopeState(supportRope, true)
		local v495_, _, v496_ = getWorldTranslation(supportRope.node)
		supportRope.hookData = supportRope.vehicle.spec_yarderTower.hooks.groundData:clone()
		supportRope.hookData:setPositionAndDirection(x, y, z, MathUtil.vector2Normalize(v495_ - x, v496_ - z))
		supportRope.hookData:setTargetNode(supportRope.node, false)
		local v497_ = supportRope.target
		local v498_ = supportRope.target
		local v499_ = supportRope.target
		local v500_, v501_, v502_ = supportRope.hookData:getRopeTargetPosition()
		v497_[1] = v500_
		v498_[2] = v501_
		v499_[3] = v502_
		if supportRope.sampleRopeLinkGround ~= nil and supportRope.sampleRopeLinkGround.soundNode ~= nil then
			setWorldTranslation(supportRope.sampleRopeLinkGround.soundNode, x, y, z)
			g_soundManager:playSample(supportRope.sampleRopeLinkGround)
		end
		return false
	end
	if isLast and not supportRope.isActive then
		supportRope.vehicle:setYarderRopeState(supportRope, false)
	end
end
function YarderTower.onSupportRopeTreeOverlapCallback(p503_, p504_, ...)
	local v505_ = p503_.spec_yarderTower
	if p504_ ~= v505_.mainRope.treeId then
		local v506_ = v505_.supportRopes.foundTrees
		table.insert(v506_, p504_)
	end
end

function YarderTower:onYarderTowerPlayerDeleted()
	self:setYarderCarriageFollowMode(YarderTower.FOLLOW_MODE_NONE)
end

-- Local values: detachAllowed, warning, showWarning, spec
function YarderTower:isDetachAllowed(superFunc)
	local v510_, v511_, v512_ = superFunc(self)
	if v510_ then
		local v513_ = self.spec_yarderTower
		if v513_.requiresAttacherVehicle and v513_.mainRope.isActive then
			return false, v513_.texts.warningDetachNotAllowed
		else
			return true
		end
	else
		return v510_, v511_, v512_
	end
end

-- Local values: spec
function YarderTower:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	if self.spec_yarderTower.mainRope.isActive then
		return false
	else
		return superFunc(self, direction, onAiTurnOn)
	end
end

-- Local values: spec
function YarderTower:getAllowsLowering(superFunc)
	if self.spec_yarderTower.mainRope.isActive then
		return false
	else
		return superFunc(self)
	end
end

-- Local values: spec
function YarderTower:getDoConsumePtoPower(superFunc)
	return self.spec_yarderTower.mainRope.isActive and true or superFunc(self)
end

-- Local values: value, count, spec, loadPercentage
function YarderTower:getConsumingLoad(superFunc)
	local v524_, v525_ = superFunc(self)
	local v526_ = self.spec_yarderTower
	return v524_ + (not v526_.mainRope.isActive and 0 or 0.05 + v526_.carriage.lastSpeed * 0.95), v525_ + 1
end

-- Local values: spec, attacherVehicle
function YarderTower:getIsPowerTakeOffActive(superFunc)
	if self.spec_yarderTower.mainRope.isActive then
		local v529_ = self:getAttacherVehicle()
		if v529_ ~= nil and (v529_.getIsMotorStarted ~= nil and v529_:getIsMotorStarted()) then
			return true
		end
	end
	return superFunc(self)
end

-- Local values: multiplier, spec
function YarderTower:getDirtMultiplier(superFunc)
	local v532_ = superFunc(self)
	local v533_ = self.spec_yarderTower
	if v533_.mainRope.isActive then
		v532_ = v532_ + v533_.carriage.lastSpeed * self:getWorkDirtMultiplier()
	end
	return v532_
end

-- Local values: multiplier, spec
function YarderTower:getWearMultiplier(superFunc)
	local v536_ = superFunc(self)
	local v537_ = self.spec_yarderTower
	if v537_.mainRope.isActive then
		v536_ = v536_ + v537_.carriage.lastSpeed * self:getWorkWearMultiplier()
	end
	return v536_
end

-- Local values: spec
function YarderTower:getUsageCausesDamage(superFunc)
	local v540_ = self.spec_yarderTower
	if not v540_.mainRope.isActive then
		return superFunc(self)
	end
	local v541_
	if v540_.carriage.lastPositionTimeOffset > 0 then
		v541_ = self.propertyState ~= VehiclePropertyState.MISSION
	else
		v541_ = false
	end
	return v541_
end

-- Local values: spec, i, component
function YarderTower:addToPhysics(superFunc)
	if not superFunc(self) then
		return false
	end
	if self.spec_yarderTower.mainRope.isActive then
		for v544_ = 1, #self.components do
			local v545_ = self.components[v544_]
			setRigidBodyType(v545_.node, RigidBodyType.KINEMATIC)
			v545_.isDynamic = false
			v545_.isKinematic = true
		end
	end
	return true
end

-- Local values: spec, i, component
function YarderTower:removeFromPhysics(superFunc)
	if self.spec_yarderTower.mainRope.isActive then
		for v548_ = 1, #self.components do
			local v549_ = self.components[v548_]
			setRigidBodyType(v549_.node, RigidBodyType.DYNAMIC)
			v549_.isDynamic = true
			v549_.isKinematic = false
		end
	end
	return superFunc(self) and true or false
end

-- Local values: spec
function YarderTower:getIsVehicleControlAllowed()
	local v551_ = self.spec_yarderTower
	if v551_.mainRope.isActive then
		return false, v551_.texts.warningDoNotMoveVehicle
	else
		return true, nil
	end
end

function YarderTower.loadSpecValueMaxLength(xmlFile, customEnvironment, baseDir)
	return xmlFile:getValue("vehicle.yarderTower.ropes.mainRope#maxLength")
end

-- Local values: maxLength, str
function YarderTower.getSpecValueMaxLength(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	if storeItem.specs.yarderMaxLength ~= nil then
		local v556_ = storeItem.specs.yarderMaxLength
		local v557_ = string.format("%d%s", v556_, g_i18n:getText("unit_mShort"))
		if returnValues and returnRange then
			return v556_, v556_, v557_
		end
		if returnValues then
			return v556_, v557_
		end
		if v556_ ~= 0 then
			return v557_
		end
	end
end

function YarderTower.loadSpecValueMaxMass(xmlFile, customEnvironment, baseDir)
	return xmlFile:getValue("vehicle.yarderTower.carriage#maxTreeMass")
end

-- Local values: maxTreeMass, str
function YarderTower.getSpecValueMaxMass(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	if storeItem.specs.yarderMaxMass ~= nil then
		local v562_ = storeItem.specs.yarderMaxMass
		local v563_ = string.format("%.1f%s", v562_, g_i18n:getText("unit_tonsShort"))
		if returnValues and returnRange then
			return v562_, v562_, v563_
		end
		if returnValues then
			return v562_, v563_
		end
		if v562_ ~= 0 then
			return v563_
		end
	end
end
