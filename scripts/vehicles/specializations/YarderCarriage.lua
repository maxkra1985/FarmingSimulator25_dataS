YarderCarriage = {}
YarderCarriage.TREE_RAYCAST_DISTANCE = 5
YarderCarriage.ROPE_MAX_LIMIT_OFFSET = 2.5
source("dataS/scripts/vehicles/specializations/events/TreeAttachEvent.lua")
source("dataS/scripts/vehicles/specializations/events/TreeAttachRequestEvent.lua")
source("dataS/scripts/vehicles/specializations/events/TreeAttachResponseEvent.lua")
source("dataS/scripts/vehicles/specializations/events/TreeDetachEvent.lua")

function YarderCarriage.prerequisitesPresent(specializations)
	return true
end
function YarderCarriage.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("YarderCarriage")
	v1_:register(XMLValueType.INT, "vehicle.yarderCarriage#maxNumTrees", "Max. number of trees that can be attached", 4)
	v1_:register(XMLValueType.FLOAT, "vehicle.yarderCarriage#maxTreeMass", "Max. total tree mass that can be attached (to)", 1)
	v1_:register(XMLValueType.FLOAT, "vehicle.yarderCarriage#length", "Total length off carriage to calculate the offset to start and end correctly", 2)
	v1_:register(XMLValueType.FLOAT, "vehicle.yarderCarriage#rollSpacing", "Spacing between the rolls to calculate the rotation correctly", 0.75)
	v1_:register(XMLValueType.FLOAT, "vehicle.yarderCarriage#liftSpeed", "Lifting speed [m/sec]", 2)
	v1_:register(XMLValueType.FLOAT, "vehicle.yarderCarriage#liftAcceleration", "Lifting acceleration (time in seconds until full speed is reached)", 0.75)
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.yarderCarriage#pullRopeTargetNode", "Target connection node for pull rope")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.yarderCarriage#pushRopeTargetNode", "Target connection node for push rope")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.yarderCarriage.ropeAlignmentNode(?)#node", "Node is aligned to the rope in x and y axis")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.yarderCarriage.joint#node", "Attach joint node")
	v1_:register(XMLValueType.TIME, "vehicle.yarderCarriage.joint#attachTime", "Time until the tree is fully attached", 0.5)
	v1_:register(XMLValueType.FLOAT, "vehicle.yarderCarriage.joint#minDistance", "Min. distance of the rope", 0.5)
	v1_:register(XMLValueType.FLOAT, "vehicle.yarderCarriage.joint#maxDistance", "Max. distance of the rope", 10)
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.yarderCarriage.rope#originNode", "Rope origin node")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.yarderCarriage.rope#rootHook", "Root hook node")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.yarderCarriage.rope#rootHookReferenceNode", "Root hook reference node placed at the end of the hook")
	v1_:register(XMLValueType.FLOAT, "vehicle.yarderCarriage.rope#treeRopeLength", "Length of the rope from the root hook to the tree", 1)
	ForestryRope.registerXMLPaths(v1_, "vehicle.yarderCarriage.rope.mainRope")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.yarderCarriage.rope.attach#mainNode", "Outgoing node for main tree attach rope (used for dummy rope display)")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.yarderCarriage.rope.attach#additionalNode", "Outgoing node for additional tree attach rope (used for dummy rope display)")
	ForestryRope.registerXMLPaths(v1_, "vehicle.yarderCarriage.rope.attach.mainRope")
	ForestryRope.registerXMLPaths(v1_, "vehicle.yarderCarriage.rope.attach.additionalRope")
	TargetTreeMarker.registerXMLPaths(v1_, "vehicle.yarderCarriage.rope.attach.marker")
	v1_:register(XMLValueType.INT, "vehicle.yarderCarriage.rope.componentJoint#index", "Component joint index")
	v1_:register(XMLValueType.VECTOR_ROT, "vehicle.yarderCarriage.rope.componentJoint#rotLimitInactive", "Component joint rot limit while tree(s) not attached")
	v1_:register(XMLValueType.VECTOR_ROT, "vehicle.yarderCarriage.rope.componentJoint#rotLimitActive", "Component joint rot limit while tree(s) attached")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.yarderCarriage.additionalRopes.additionalRope(?)#referenceNode", "Node at the end of the hook for placement of the rope")
	ForestryRope.registerXMLPaths(v1_, "vehicle.yarderCarriage.additionalRopes.additionalRope(?).rope")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.yarderCarriage.additionalRopes.additionalRope(?).hookNode(?)#node", "Node to align to target point")
	v1_:register(XMLValueType.BOOL, "vehicle.yarderCarriage.additionalRopes.additionalRope(?).hookNode(?)#alignYRot", "Node is only aligned on y axis", false)
	v1_:register(XMLValueType.BOOL, "vehicle.yarderCarriage.additionalRopes.additionalRope(?).hookNode(?)#alignXRot", "Node is only aligned on x axis", false)
	v1_:register(XMLValueType.ANGLE, "vehicle.yarderCarriage.additionalRopes.additionalRope(?).hookNode(?)#minRot", "Min. rotation value for only y or x alignment", -180)
	v1_:register(XMLValueType.ANGLE, "vehicle.yarderCarriage.additionalRopes.additionalRope(?).hookNode(?)#maxRot", "Max. rotation value for only y or x alignment", 180)
	v1_:register(XMLValueType.BOOL, "vehicle.yarderCarriage.additionalRopes.additionalRope(?).hookNode(?)#alignToTarget", "Node is only aligned on all axis", true)
	ObjectChangeUtil.registerObjectChangeXMLPaths(v1_, "vehicle.yarderCarriage.rope")
	v1_:register(XMLValueType.FLOAT, "vehicle.yarderCarriage.treeHook#offset", "Hook offset from tree", 0.01)
	v1_:register(XMLValueType.STRING, "vehicle.yarderCarriage.treeHook#tensionBeltType", "Name of tension belt type used for tree hook", "forestryTreeBelt")
	ForestryHook.registerXMLPaths(v1_, "vehicle.yarderCarriage.treeHook")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.yarderCarriage.sounds", "attachTree")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.yarderCarriage.sounds", "detachTree")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.yarderCarriage.sounds", "lift")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.yarderCarriage.sounds", "lower")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.yarderCarriage.sounds", "liftLimit")
	v1_:setXMLSpecializationType()
end

function YarderCarriage.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getCarriageDimensions", YarderCarriage.getCarriageDimensions)
	SpecializationUtil.registerFunction(vehicleType, "getCarriagePullRopeTargetNode", YarderCarriage.getCarriagePullRopeTargetNode)
	SpecializationUtil.registerFunction(vehicleType, "getCarriagePushRopeTargetNode", YarderCarriage.getCarriagePushRopeTargetNode)
	SpecializationUtil.registerFunction(vehicleType, "setYarderTowerVehicle", YarderCarriage.setYarderTowerVehicle)
	SpecializationUtil.registerFunction(vehicleType, "updateRopeAlignmentNodes", YarderCarriage.updateRopeAlignmentNodes)
	SpecializationUtil.registerFunction(vehicleType, "updateCarriageInRange", YarderCarriage.updateCarriageInRange)
	SpecializationUtil.registerFunction(vehicleType, "onYarderCarriageUpdateEnd", YarderCarriage.onYarderCarriageUpdateEnd)
	SpecializationUtil.registerFunction(vehicleType, "updateTreeAttachRopes", YarderCarriage.updateTreeAttachRopes)
	SpecializationUtil.registerFunction(vehicleType, "onCarriageTreeRaycastCallback", YarderCarriage.onCarriageTreeRaycastCallback)
	SpecializationUtil.registerFunction(vehicleType, "onAttachTreeAction", YarderCarriage.onAttachTreeAction)
	SpecializationUtil.registerFunction(vehicleType, "attachTreeToCarriage", YarderCarriage.attachTreeToCarriage)
	SpecializationUtil.registerFunction(vehicleType, "createJoint", YarderCarriage.createJoint)
	SpecializationUtil.registerFunction(vehicleType, "onDetachTreeAction", YarderCarriage.onDetachTreeAction)
	SpecializationUtil.registerFunction(vehicleType, "detachTreeFromCarriage", YarderCarriage.detachTreeFromCarriage)
	SpecializationUtil.registerFunction(vehicleType, "getNumAttachedTrees", YarderCarriage.getNumAttachedTrees)
	SpecializationUtil.registerFunction(vehicleType, "getMaxNumAttachedTrees", YarderCarriage.getMaxNumAttachedTrees)
	SpecializationUtil.registerFunction(vehicleType, "getAttachedTreeMass", YarderCarriage.getAttachedTreeMass)
	SpecializationUtil.registerFunction(vehicleType, "getIsCarriageTreeAttachAllowed", YarderCarriage.getIsCarriageTreeAttachAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getIsTreeInMountRange", YarderCarriage.getIsTreeInMountRange)
	SpecializationUtil.registerFunction(vehicleType, "showCarriageTreeMountFailedWarning", YarderCarriage.showCarriageTreeMountFailedWarning)
	SpecializationUtil.registerFunction(vehicleType, "setCarriageLiftInput", YarderCarriage.setCarriageLiftInput)
	SpecializationUtil.registerFunction(vehicleType, "saveAttachedTreesToXML", YarderCarriage.saveAttachedTreesToXML)
	SpecializationUtil.registerFunction(vehicleType, "resolveLoadedAttachedTrees", YarderCarriage.resolveLoadedAttachedTrees)
	SpecializationUtil.registerFunction(vehicleType, "onYarderCarriageTreeShapeCut", YarderCarriage.onYarderCarriageTreeShapeCut)
	SpecializationUtil.registerFunction(vehicleType, "onYarderCarriageTreeShapeMounted", YarderCarriage.onYarderCarriageTreeShapeMounted)
end

function YarderCarriage.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", YarderCarriage.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", YarderCarriage.getWearMultiplier)
end

function YarderCarriage.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", YarderCarriage)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", YarderCarriage)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", YarderCarriage)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", YarderCarriage)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", YarderCarriage)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", YarderCarriage)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", YarderCarriage)
	SpecializationUtil.registerEventListener(vehicleType, "onPostUpdate", YarderCarriage)
end

-- Local values: spec
function YarderCarriage:onLoad(savegame)
	local v_u_6_ = self.spec_yarderCarriage
	v_u_6_.maxNumTrees = self.xmlFile:getValue("vehicle.yarderCarriage#maxNumTrees", 4)
	local v7_ = v_u_6_.maxNumTrees
	local v8_ = math.sqrt(v7_)
	v_u_6_.maxTreeBits = math.ceil(v8_)
	v_u_6_.maxTreeMass = self.xmlFile:getValue("vehicle.yarderCarriage#maxTreeMass", 1)
	v_u_6_.length = self.xmlFile:getValue("vehicle.yarderCarriage#length", 2)
	v_u_6_.rollSpacing = self.xmlFile:getValue("vehicle.yarderCarriage#rollSpacing", 0.75)
	v_u_6_.liftSpeed = self.xmlFile:getValue("vehicle.yarderCarriage#liftSpeed", 2) * 0.001
	v_u_6_.liftAcceleration = 1 / self.xmlFile:getValue("vehicle.yarderCarriage#liftAcceleration", 0.75) * 0.001
	v_u_6_.curLiftSpeedAlpha = 0
	v_u_6_.curLiftSpeedLastDirection = 0
	v_u_6_.pullRopeTargetNode = self.xmlFile:getValue("vehicle.yarderCarriage#pullRopeTargetNode", nil, self.components, self.i3dMappings)
	v_u_6_.pushRopeTargetNode = self.xmlFile:getValue("vehicle.yarderCarriage#pushRopeTargetNode", nil, self.components, self.i3dMappings)
	v_u_6_.ropeAlignmentNodes = {}
	self.xmlFile:iterate("vehicle.yarderCarriage.ropeAlignmentNode", function(_, p9_)
		-- upvalues: (copy) self, (copy) v_u_6_
		local v10_ = {
			["node"] = self.xmlFile:getValue(p9_ .. "#node", nil, self.components, self.i3dMappings)
		}
		if v10_.node ~= nil then
			local v11_ = v_u_6_.ropeAlignmentNodes
			table.insert(v11_, v10_)
		end
	end)
	v_u_6_.joint = {}
	v_u_6_.joint.node = self.xmlFile:getValue("vehicle.yarderCarriage.joint#node", nil, self.components, self.i3dMappings)
	v_u_6_.joint.attachTime = self.xmlFile:getValue("vehicle.yarderCarriage.joint#attachTime", 0.5)
	v_u_6_.joint.minDistance = self.xmlFile:getValue("vehicle.yarderCarriage.joint#minDistance", 0.5)
	v_u_6_.joint.maxDistance = self.xmlFile:getValue("vehicle.yarderCarriage.joint#maxDistance", 20)
	v_u_6_.joint.component = self:getParentComponent(v_u_6_.joint.node)
	v_u_6_.rope = {}
	v_u_6_.rope.originNode = self.xmlFile:getValue("vehicle.yarderCarriage.rope#originNode", nil, self.components, self.i3dMappings)
	v_u_6_.rope.rootHook = self.xmlFile:getValue("vehicle.yarderCarriage.rope#rootHook", nil, self.components, self.i3dMappings)
	v_u_6_.rope.rootHookReferenceNode = self.xmlFile:getValue("vehicle.yarderCarriage.rope#rootHookReferenceNode", nil, self.components, self.i3dMappings)
	v_u_6_.rope.treeRopeLength = self.xmlFile:getValue("vehicle.yarderCarriage.rope#treeRopeLength", 1)
	v_u_6_.rope.rootHookLength = 1
	if v_u_6_.rope.rootHook ~= nil and v_u_6_.rope.rootHookReferenceNode ~= nil then
		v_u_6_.rope.rootHookLength = calcDistanceFrom(v_u_6_.rope.rootHook, v_u_6_.rope.rootHookReferenceNode)
	end
	v_u_6_.rope.mainRope = ForestryRope.new(self, v_u_6_.rope.rootHook)
	v_u_6_.rope.mainRope:loadFromXML(self.xmlFile, "vehicle.yarderCarriage.rope.mainRope", self.baseDirectory)
	v_u_6_.rope.attachMainNode = self.xmlFile:getValue("vehicle.yarderCarriage.rope.attach#mainNode", nil, self.components, self.i3dMappings)
	v_u_6_.rope.attachMainRope = ForestryRope.new(self, v_u_6_.rope.attachMainNode)
	v_u_6_.rope.attachMainRope:loadFromXML(self.xmlFile, "vehicle.yarderCarriage.rope.attach.mainRope", self.baseDirectory)
	v_u_6_.rope.attachMainRope:setVisibility(false)
	v_u_6_.rope.attachAdditionalNode = self.xmlFile:getValue("vehicle.yarderCarriage.rope.attach#additionalNode", nil, self.components, self.i3dMappings)
	v_u_6_.rope.attachAdditionalRope = ForestryRope.new(self, v_u_6_.rope.attachAdditionalNode)
	v_u_6_.rope.attachAdditionalRope:loadFromXML(self.xmlFile, "vehicle.yarderCarriage.rope.attach.additionalRope", self.baseDirectory)
	v_u_6_.rope.attachAdditionalRope:setVisibility(false)
	v_u_6_.rope.attachMarker = TargetTreeMarker.new(self, self.rootNode)
	v_u_6_.rope.attachMarker:loadFromXML(self.xmlFile, "vehicle.yarderCarriage.rope.attach.marker")
	v_u_6_.rope.componentJointIndex = self.xmlFile:getValue("vehicle.yarderCarriage.rope.componentJoint#index")
	v_u_6_.rope.componentJointLimitInactive = self.xmlFile:getValue("vehicle.yarderCarriage.rope.componentJoint#rotLimitInactive", "0 0 0", true)
	v_u_6_.rope.componentJointLimitActive = self.xmlFile:getValue("vehicle.yarderCarriage.rope.componentJoint#rotLimitActive", nil, true)
	v_u_6_.rope.changeObjects = {}
	ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, "vehicle.yarderCarriage.rope", v_u_6_.rope.changeObjects, self.components, self)
	ObjectChangeUtil.setObjectChanges(v_u_6_.rope.changeObjects, false, self, self.setMovingToolDirty)
	v_u_6_.additionalRopes = {}
	self.xmlFile:iterate("vehicle.yarderCarriage.additionalRopes.additionalRope", function(_, p12_)
		-- upvalues: (copy) self, (copy) v_u_6_
		local v_u_13_ = {
			["referenceNode"] = self.xmlFile:getValue(p12_ .. "#referenceNode", nil, self.components, self.i3dMappings)
		}
		v_u_13_.rope = ForestryRope.new(self, v_u_13_.referenceNode)
		v_u_13_.rope:loadFromXML(self.xmlFile, p12_ .. ".rope", self.baseDirectory)
		v_u_13_.hookNodes = {}
		self.xmlFile:iterate(p12_ .. ".hookNode", function(_, p14_)
			-- upvalues: (ref) self, (copy) v_u_13_
			local v15_ = {
				["node"] = self.xmlFile:getValue(p14_ .. "#node", nil, self.components, self.i3dMappings),
				["alignYRot"] = self.xmlFile:getValue(p14_ .. "#alignYRot", false),
				["alignXRot"] = self.xmlFile:getValue(p14_ .. "#alignXRot", false),
				["minRot"] = self.xmlFile:getValue(p14_ .. "#minRot", -180),
				["maxRot"] = self.xmlFile:getValue(p14_ .. "#maxRot", 180),
				["alignToTarget"] = self.xmlFile:getValue(p14_ .. "#alignToTarget", true),
				["referenceFrame"] = createTransformGroup("hookNodeReferenceFrame")
			}
			link(getParent(v15_.node), v15_.referenceFrame)
			setTranslation(v15_.referenceFrame, getTranslation(v15_.node))
			setRotation(v15_.referenceFrame, getRotation(v15_.node))
			setVisibility(v15_.node, false)
			local v16_ = v_u_13_.hookNodes
			table.insert(v16_, v15_)
		end)
		setVisibility(v_u_13_.referenceNode, false)
		local v17_ = v_u_6_.additionalRopes
		table.insert(v17_, v_u_13_)
	end)
	v_u_6_.treeHook = {}
	v_u_6_.treeHook.offset = self.xmlFile:getValue("vehicle.yarderCarriage.treeHook#offset", 0.01)
	v_u_6_.treeHook.tensionBeltType = self.xmlFile:getValue("vehicle.yarderCarriage.treeHook#tensionBeltType", "forestryTreeBelt")
	v_u_6_.treeHook.beltData = g_tensionBeltManager:getBeltData(v_u_6_.treeHook.tensionBeltType)
	v_u_6_.treeHook.hookData = ForestryHook.new(self, self.rootNode)
	v_u_6_.treeHook.hookData:loadFromXML(self.xmlFile, "vehicle.yarderCarriage.treeHook", self.baseDirectory)
	v_u_6_.treeHook.hookData:setVisibility(false)
	v_u_6_.yarderTowerVehicle = nil
	v_u_6_.treeRaycast = {}
	v_u_6_.treeRaycast.hasStarted = false
	v_u_6_.treeRaycast.foundTree = false
	v_u_6_.treeRaycast.treeTargetPos = { 0, 0, 0 }
	v_u_6_.treeRaycast.treeCenterPos = { 0, 0, 0 }
	v_u_6_.treeRaycast.treeUp = { 0, 1, 0 }
	v_u_6_.treeRaycast.treeRadius = 1
	v_u_6_.attachedTrees = {}
	v_u_6_.splitShapesToAttach = {}
	v_u_6_.lastTransLimitY = 0
	v_u_6_.lastTransLimitYTimeOffset = 0
	v_u_6_.sampleLiftPlayedSent = false
	v_u_6_.sampleLiftLimitPlayedSent = false
	v_u_6_.sampleLowerPlayedSent = false
	v_u_6_.samples = {}
	if self.isClient then
		v_u_6_.samples.attachTree = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderCarriage.sounds", "attachTree", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_6_.samples.detachTree = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderCarriage.sounds", "detachTree", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_6_.samples.lift = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderCarriage.sounds", "lift", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_6_.samples.lower = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderCarriage.sounds", "lower", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_6_.samples.liftLimit = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderCarriage.sounds", "liftLimit", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
	v_u_6_.texts = {}
	v_u_6_.texts.warningTooHeavy = g_i18n:getText("yarder_treeToHeavy")
	self.isVehicleSaved = false
	v_u_6_.dirtyFlag = self:getNextDirtyFlag()
	g_messageCenter:subscribe(MessageType.TREE_SHAPE_CUT, self.onYarderCarriageTreeShapeCut, self)
	g_messageCenter:subscribe(MessageType.TREE_SHAPE_MOUNTED, self.onYarderCarriageTreeShapeMounted, self)
end

-- Local values: spec
function YarderCarriage:onLoadFinished(savegame)
	local v19_ = self.spec_yarderCarriage
	v19_.rope.mainRope:setTargetNode(v19_.rope.originNode)
	v19_.rope.treeRope = v19_.rope.mainRope:clone(v19_.rope.rootHookReferenceNode)
	v19_.rope.treeRope:setLength(v19_.rope.treeRopeLength)
end

-- Local values: spec, i, additionalRope
function YarderCarriage:onDelete()
	local v21_ = self.spec_yarderCarriage
	if v21_.yarderTowerVehicle ~= nil then
		v21_.yarderTowerVehicle.spec_yarderTower.carriage.vehicle = nil
	end
	if #v21_.attachedTrees > 0 then
		self:detachTreeFromCarriage(nil, true)
	end
	if self.isClient then
		g_soundManager:deleteSamples(v21_.samples)
	end
	if v21_.treeHook.hookData ~= nil then
		v21_.treeHook.hookData:delete()
	end
	if v21_.rope.attachMarker ~= nil then
		v21_.rope.attachMarker:delete()
	end
	if v21_.rope.mainRope ~= nil then
		v21_.rope.mainRope:delete()
	end
	if v21_.rope.treeRope ~= nil then
		v21_.rope.treeRope:delete()
	end
	if v21_.rope.attachMainRope ~= nil then
		v21_.rope.attachMainRope:delete()
	end
	if v21_.rope.attachAdditionalRope ~= nil then
		v21_.rope.attachAdditionalRope:delete()
	end
	if v21_.additionalRopes ~= nil then
		for v22_ = 1, #v21_.additionalRopes do
			local v23_ = v21_.additionalRopes[v22_]
			if v23_.rope ~= nil then
				v23_.rope:delete()
			end
		end
	end
end

-- Local values: spec, numTrees, i, x, y, z, splitShapeId, splitShapeId1, splitShapeId2
function YarderCarriage:onReadStream(streamId, connection)
	local v26_ = self.spec_yarderCarriage
	if streamReadBool(streamId) then
		v26_.yarderTowerVehicle = NetworkUtil.readNodeObject(streamId)
		v26_.yarderTowerVehicle.spec_yarderTower.carriage.vehicle = self
	end
	for _ = 1, streamReadUIntN(streamId, v26_.maxTreeBits) do
		local v27_ = streamReadFloat32(streamId)
		local v28_ = streamReadFloat32(streamId)
		local v29_ = streamReadFloat32(streamId)
		local v30_, v31_, v32_ = readSplitShapeIdFromStream(streamId)
		if v30_ == 0 then
			if v31_ ~= 0 then
				local v33_ = v26_.splitShapesToAttach
				table.insert(v33_, {
					["splitShapeId1"] = v31_,
					["splitShapeId2"] = v32_,
					["x"] = v27_,
					["y"] = v28_,
					["z"] = v29_
				})
			end
		else
			local v34_, v35_, v36_ = localToWorld(v30_, v27_, v28_, v29_)
			self:attachTreeToCarriage(v30_, v34_, v35_, v36_, nil, true)
		end
	end
end

-- Local values: spec, i, treeData, x, y, z
function YarderCarriage:onWriteStream(streamId, connection)
	local v39_ = self.spec_yarderCarriage
	streamWriteBool(streamId, v39_.yarderTowerVehicle ~= nil)
	if v39_.yarderTowerVehicle ~= nil then
		NetworkUtil.writeNodeObject(streamId, v39_.yarderTowerVehicle)
	end
	streamWriteUIntN(streamId, #v39_.attachedTrees, v39_.maxTreeBits)
	for v40_ = 1, #v39_.attachedTrees do
		local v41_ = v39_.attachedTrees[v40_]
		local v42_, v43_, v44_ = worldToLocal(v41_.treeId, getWorldTranslation(v41_.hookData.hookId))
		streamWriteFloat32(streamId, v42_)
		streamWriteFloat32(streamId, v43_)
		streamWriteFloat32(streamId, v44_)
		writeSplitShapeIdToStream(streamId, v41_.treeId)
	end
end

-- Local values: spec
function YarderCarriage:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		local v48_ = self.spec_yarderCarriage
		if streamReadBool(streamId) and not g_soundManager:getIsSamplePlaying(v48_.samples.lift) then
			g_soundManager:playSample(v48_.samples.lift)
			g_soundManager:stopSample(v48_.samples.lower)
			v48_.lastTransLimitYTimeOffset = 250
		end
		if streamReadBool(streamId) then
			g_soundManager:playSample(v48_.samples.liftLimit)
		end
		if streamReadBool(streamId) and not g_soundManager:getIsSamplePlaying(v48_.samples.lower) then
			g_soundManager:playSample(v48_.samples.lower)
			g_soundManager:stopSample(v48_.samples.lift)
			v48_.lastTransLimitYTimeOffset = 250
		end
	end
end

-- Local values: spec
function YarderCarriage:onWriteUpdateStream(streamId, connection, dirtyMask)
	local v53_ = self.spec_yarderCarriage
	if not connection:getIsServer() then
		local v54_ = streamWriteBool
		local v55_ = v53_.dirtyFlag
		if v54_(streamId, bit32.band(dirtyMask, v55_) ~= 0) then
			streamWriteBool(streamId, v53_.sampleLiftPlayedSent)
			streamWriteBool(streamId, v53_.sampleLiftLimitPlayedSent)
			streamWriteBool(streamId, v53_.sampleLowerPlayedSent)
			v53_.sampleLiftPlayedSent = false
			v53_.sampleLiftLimitPlayedSent = false
			v53_.sampleLowerPlayedSent = false
		end
	end
end

-- Local values: spec, i, treeData, distance, i, attachData, splitShapeId, x, y, z, attachRope
function YarderCarriage:onPostUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v58_ = self.spec_yarderCarriage
	if self.isServer then
		for v59_ = 1, #v58_.attachedTrees do
			local v60_ = v58_.attachedTrees[v59_]
			if v60_.limitDirty then
				local v61_ = v60_.limitValue - v60_.speedScale * g_currentDt
				v60_.limitValue = math.max(v61_, 0)
				setJointTranslationLimit(v60_.jointIndex, 0, true, -v60_.limitValue, v60_.limitValue)
				setJointTranslationLimit(v60_.jointIndex, 1, true, -v60_.transLimitY, v60_.limitValue)
				setJointTranslationLimit(v60_.jointIndex, 2, true, -v60_.limitValue, v60_.limitValue)
				if v60_.limitValue == 0 then
					v60_.limitDirty = false
				end
			else
				if v60_.treeId == nil or not entityExists(v60_.treeId) then
					self:detachTreeFromCarriage()
					break
				end
				if calcDistanceFrom(v58_.joint.node, v60_.hookData.hookId) > v60_.transLimitY + YarderCarriage.ROPE_MAX_LIMIT_OFFSET then
					self:detachTreeFromCarriage()
					break
				end
			end
		end
	else
		for v62_ = #v58_.splitShapesToAttach, 1, -1 do
			local v63_ = v58_.splitShapesToAttach[v62_]
			local v64_ = resolveStreamSplitShapeId(v63_.splitShapeId1, v63_.splitShapeId2)
			if v64_ ~= 0 then
				local v65_, v66_, v67_ = localToWorld(v64_, v63_.x, v63_.y, v63_.z)
				self:attachTreeToCarriage(v64_, v65_, v66_, v67_, nil, true)
				table.remove(v58_.splitShapesToAttach, v62_)
			end
		end
	end
	self:updateTreeAttachRopes(dt)
	if v58_.treeRaycast.validTree ~= nil and not entityExists(v58_.treeRaycast.validTree) then
		v58_.treeRaycast.validTree = nil
	end
	if v58_.treeRaycast.validTree ~= v58_.treeRaycast.lastValidTree then
		v58_.rope.attachMarker:setIsActive(v58_.treeRaycast.validTree ~= nil)
		local v68_ = v58_.rope.attachMainRope
		local v69_
		if v58_.treeRaycast.validTree == nil then
			v69_ = false
		else
			v69_ = #v58_.attachedTrees == 0
		end
		v68_:setVisibility(v69_)
		local v70_ = v58_.rope.attachAdditionalRope
		local v71_
		if v58_.treeRaycast.validTree == nil then
			v71_ = false
		else
			v71_ = #v58_.attachedTrees > 0
		end
		v70_:setVisibility(v71_)
		v58_.treeRaycast.lastValidTree = v58_.treeRaycast.validTree
	end
	local v72_ = #v58_.attachedTrees == 0 and v58_.rope.attachMainRope or v58_.rope.attachAdditionalRope
	if v58_.treeRaycast.validTree ~= nil and v72_ ~= nil then
		v72_:setTargetPosition(v58_.treeRaycast.treeTargetPos[1], v58_.treeRaycast.treeTargetPos[2], v58_.treeRaycast.treeTargetPos[3])
		v58_.rope.attachMarker:setIsActive(true)
		v58_.rope.attachMarker:setPosition(v58_.treeRaycast.treeCenterPos[1], v58_.treeRaycast.treeCenterPos[2], v58_.treeRaycast.treeCenterPos[3], v58_.treeRaycast.treeUp[1], v58_.treeRaycast.treeUp[2], v58_.treeRaycast.treeUp[3], v58_.treeRaycast.treeRadius)
	end
	if v58_.lastTransLimitYTimeOffset > 0 then
		v58_.lastTransLimitYTimeOffset = v58_.lastTransLimitYTimeOffset - dt
		if v58_.lastTransLimitYTimeOffset <= 0 then
			v58_.curLiftSpeedAlpha = 0
			v58_.curLiftSpeedLastDirection = 0
			g_soundManager:stopSample(v58_.samples.lower)
			g_soundManager:stopSample(v58_.samples.lift)
		end
	end
	if #v58_.attachedTrees > 0 or v58_.treeRaycast.validTree ~= nil then
		self:raiseActive()
	end
end

-- Local values: spec
function YarderCarriage:getCarriageDimensions()
	local v74_ = self.spec_yarderCarriage
	return v74_.length, v74_.rollSpacing
end

function YarderCarriage:getCarriagePullRopeTargetNode()
	return self.spec_yarderCarriage.pullRopeTargetNode
end

function YarderCarriage:getCarriagePushRopeTargetNode()
	return self.spec_yarderCarriage.pushRopeTargetNode
end

function YarderCarriage:setYarderTowerVehicle(vehicle)
	self.spec_yarderCarriage.yarderTowerVehicle = vehicle
end

-- Local values: _, _, z1, spec, i, nodeData, _, _, z2, alpha, offset, x, y, z, _
function YarderCarriage:updateRopeAlignmentNodes(ropeNode, tx, ty, tz, maxOffset)
	local _, _, v85_ = worldToLocal(ropeNode, tx, ty, tz)
	local v86_ = self.spec_yarderCarriage
	for v87_ = 1, #v86_.ropeAlignmentNodes do
		local v88_ = v86_.ropeAlignmentNodes[v87_]
		local _, _, v89_ = worldToLocal(ropeNode, getWorldTranslation(v88_.node))
		local v90_ = v89_ / v85_
		local v91_ = math.clamp(v90_, 0, 1) * 3.141592653589793
		local v92_ = math.sin(v91_) * maxOffset
		local v93_, v94_, v95_ = localToWorld(ropeNode, 0, -v92_, v89_)
		local v96_, v97_, _ = worldToLocal(v88_.node, v93_, v94_, v95_)
		translate(v88_.node, v96_, v97_, 0)
	end
end

-- Local values: spec, player, x1, _, z1, x2, _, z2, distance, cameraNode, x, y, z, dx, dy, dz
function YarderCarriage:updateCarriageInRange()
	if g_localPlayer ~= nil then
		local v99_ = self.spec_yarderCarriage
		local v100_ = g_localPlayer
		local v101_, _, v102_ = getWorldTranslation(v100_.rootNode)
		local v103_, _, v104_ = getWorldTranslation(v99_.rope.originNode)
		if MathUtil.vector2Length(v101_ - v103_, v102_ - v104_) < v99_.joint.maxDistance then
			if v100_:getIsHoldingHandTool() then
				v99_.treeRaycast.validTree = nil
				return
			end
			if #v99_.attachedTrees >= v99_.maxNumTrees then
				v99_.treeRaycast.validTree = nil
				return
			end
			if not v99_.treeRaycast.hasStarted then
				v99_.treeRaycast.hasStarted = true
				v99_.treeRaycast.foundTree = nil
				local v105_ = v100_:getCurrentCameraNode()
				local v106_, v107_, v108_ = localToWorld(v105_, 0, 0, 1)
				local v109_, v110_, v111_ = localDirectionToWorld(v105_, 0, 0, -1)
				raycastClosestAsync(v106_, v107_, v108_, v109_, v110_, v111_, YarderCarriage.TREE_RAYCAST_DISTANCE, "onCarriageTreeRaycastCallback", self, CollisionFlag.TREE)
				return
			end
		else
			v99_.treeRaycast.validTree = nil
		end
	end
end

-- Local values: spec
function YarderCarriage:onYarderCarriageUpdateEnd()
	local v113_ = self.spec_yarderCarriage
	v113_.treeRaycast.validTree = nil
	v113_.treeRaycast.hasStarted = false
	self:raiseActive()
end

-- Local values: spec, rootTreeData, x1, y1, z1, x2, y2, z2, distance, dx, dy, dz, upX, upY, upZ, rootHookPosition, i, additionalRope, treeData, x2, y2, z2, j, hookNode, x, _, z, angle, _, y, z, angle, x, y, z
function YarderCarriage:updateTreeAttachRopes(dt)
	local v115_ = self.spec_yarderCarriage
	local v116_ = v115_.attachedTrees[1]
	if v116_ ~= nil and entityExists(v116_.treeId) then
		local v117_, v118_, v119_ = getWorldTranslation(v115_.rope.originNode)
		local v120_, v121_, v122_ = v116_.hookData:getRopeTargetPosition()
		local v123_ = MathUtil.vector3Length(v120_ - v117_, v121_ - v118_, v122_ - v119_)
		local v124_, v125_, v126_ = MathUtil.vector3Normalize(v120_ - v117_, v121_ - v118_, v122_ - v119_)
		local v127_, v128_, v129_ = localDirectionToWorld(getParent(v115_.rope.originNode), 0, 1, 0)
		I3DUtil.setWorldDirection(v115_.rope.originNode, v124_, v125_, v126_, v127_, v128_, v129_)
		local v130_ = v123_ - v115_.rope.treeRopeLength - v115_.rope.rootHookLength
		setTranslation(v115_.rope.rootHook, 0, 0, v130_)
		v115_.rope.mainRope:setLength(v130_)
	end
	for v131_ = 1, #v115_.additionalRopes do
		local v132_ = v115_.additionalRopes[v131_]
		local v133_ = v115_.attachedTrees[v131_ + 1]
		if v133_ ~= nil and entityExists(v133_.treeId) then
			local v134_, v135_, v136_ = v133_.hookData:getRopeTargetPosition()
			for v137_ = 1, #v132_.hookNodes do
				local v138_ = v132_.hookNodes[v137_]
				if v138_.alignYRot then
					local v139_, _, v140_ = worldToLocal(v138_.referenceFrame, v134_, v135_, v136_)
					local v141_, v142_ = MathUtil.vector2Normalize(v139_, v140_)
					local v143_ = math.atan2(v141_, v142_)
					local v144_ = v138_.minRot
					local v145_ = v138_.maxRot
					local v146_ = math.clamp(v143_, v144_, v145_)
					setRotation(v138_.node, 0, v146_, 0)
				elseif v138_.alignXRot then
					local _, v147_, v148_ = worldToLocal(v138_.referenceFrame, v134_, v135_, v136_)
					local v149_, v150_ = MathUtil.vector2Normalize(v147_, v148_)
					local v151_ = -math.atan2(v149_, v150_)
					local v152_ = v138_.minRot
					local v153_ = v138_.maxRot
					local v154_ = math.clamp(v151_, v152_, v153_)
					setRotation(v138_.node, v154_, 0, 0)
				elseif v138_.alignToTarget then
					local v155_, v156_, v157_ = worldToLocal(v138_.referenceFrame, v134_, v135_, v136_)
					local v158_, v159_, v160_ = MathUtil.vector3Normalize(v155_, v156_, v157_)
					setDirection(v138_.node, v158_, v159_, v160_, 0, 1, 0)
				end
			end
			v132_.rope:setTargetNode(v133_.hookData:getRopeTarget(), false)
		end
	end
end

-- Local values: spec, x2, y2, z2, distanceToJoint, i, rootTreeData, distanceToRoot, centerX, centerY, centerZ, upX, upY, upZ, radius
function YarderCarriage:onCarriageTreeRaycastCallback(hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	if not (self.isDeleted or self.isDeleting) then
		local v167_ = self.spec_yarderCarriage
		if not v167_.treeRaycast.hasStarted then
			v167_.treeRaycast.validTree = nil
			return false
		end
		if hitObjectId ~= 0 and (getHasClassId(hitObjectId, ClassIds.SHAPE) and (getSplitType(hitObjectId) ~= 0 and getIsSplitShapeSplit(hitObjectId))) then
			if isLast then
				v167_.treeRaycast.hasStarted = false
				local v168_, _, v169_ = getWorldTranslation(v167_.rope.originNode)
				if MathUtil.vector2Length(x - v168_, z - v169_) > v167_.joint.maxDistance then
					v167_.treeRaycast.validTree = nil
					return false
				end
				if #v167_.attachedTrees > 0 then
					for v170_ = 1, #v167_.attachedTrees do
						if hitObjectId == v167_.attachedTrees[v170_].treeId then
							v167_.treeRaycast.validTree = nil
							return false
						end
					end
					local v171_ = v167_.attachedTrees[1]
					local v172_, v173_, v174_ = getWorldTranslation(v171_.hookData.hookId)
					if MathUtil.vector3Length(x - v172_, y - v173_, z - v174_) > 2 then
						v167_.treeRaycast.validTree = nil
						return false
					end
				end
				local v175_, v176_, v177_, v178_, v179_, v180_, v181_ = SplitShapeUtil.getTreeOffsetPosition(hitObjectId, x, y, z, 4, 0.15)
				if v175_ == nil then
					v167_.treeRaycast.validTree = nil
				else
					v167_.treeRaycast.validTree = hitObjectId
					v167_.treeRaycast.treeTargetPos[1] = x
					v167_.treeRaycast.treeTargetPos[2] = y
					v167_.treeRaycast.treeTargetPos[3] = z
					v167_.treeRaycast.treeCenterPos[1] = v175_
					v167_.treeRaycast.treeCenterPos[2] = v176_
					v167_.treeRaycast.treeCenterPos[3] = v177_
					v167_.treeRaycast.treeUp[1] = v178_
					v167_.treeRaycast.treeUp[2] = v179_
					v167_.treeRaycast.treeUp[3] = v180_
					v167_.treeRaycast.treeRadius = v181_
					self:raiseActive()
				end
			end
			return false
		end
		if isLast then
			v167_.treeRaycast.hasStarted = false
			v167_.treeRaycast.validTree = nil
		end
	end
end

-- Local values: spec, isAllowed, reason
function YarderCarriage:onAttachTreeAction()
	local v183_ = self.spec_yarderCarriage
	if v183_.treeRaycast.validTree ~= nil then
		if g_server == nil then
			g_client:getServerConnection():sendEvent(TreeAttachRequestEvent.new(self, v183_.treeRaycast.validTree, v183_.treeRaycast.treeTargetPos[1], v183_.treeRaycast.treeTargetPos[2], v183_.treeRaycast.treeTargetPos[3]))
		else
			local v184_, v185_ = self:getIsCarriageTreeAttachAllowed(v183_.treeRaycast.validTree)
			if v184_ then
				self:attachTreeToCarriage(v183_.treeRaycast.validTree, v183_.treeRaycast.treeTargetPos[1], v183_.treeRaycast.treeTargetPos[2], v183_.treeRaycast.treeTargetPos[3])
			else
				self:showCarriageTreeMountFailedWarning(nil, v185_)
			end
		end
		v183_.treeRaycast.validTree = nil
	end
end

-- Local values: spec, treeData, centerX, _, _, newIndex, additionalRope, j, hookNode, componentJoint, limit
function YarderCarriage:attachTreeToCarriage(splitShapeId, x, y, z, ropeIndex, noEventSend)
	local v192_ = self.spec_yarderCarriage
	v192_.rope.attachMainRope:setVisibility(false)
	v192_.rope.attachAdditionalRope:setVisibility(false)
	local v193_ = {
		["treeId"] = splitShapeId,
		["hookData"] = v192_.treeHook.hookData:clone()
	}
	local v194_, _, _ = v193_.hookData:mountToTree(splitShapeId, x, y, z, 4)
	if v194_ == nil then
		v193_.hookData:delete()
	else
		v193_.hookData:setTargetNode(v192_.rope.originNode, true)
		if self.isServer then
			local v195_, v196_ = self:createJoint(v193_.treeId, v193_.hookData.hookId)
			v193_.jointIndex = v195_
			v193_.transLimitY = v196_
			v193_.limitValue = v193_.transLimitY
			v193_.speedScale = v193_.transLimitY * (1 / v192_.joint.attachTime)
			v193_.limitDirty = true
			if #v192_.attachedTrees == 0 then
				v192_.lastTransLimitY = v193_.transLimitY
			end
		end
		local v197_ = v192_.attachedTrees
		table.insert(v197_, v193_)
		ObjectChangeUtil.setObjectChanges(v192_.rope.changeObjects, true, self, self.setMovingToolDirty)
		local v198_ = #v192_.attachedTrees
		if v198_ > 1 and v192_.additionalRopes[v198_ - 1] ~= nil then
			local v199_ = v192_.additionalRopes[v198_ - 1]
			setVisibility(v199_.referenceNode, true)
			for v200_ = 1, #v199_.hookNodes do
				local v201_ = v199_.hookNodes[v200_]
				setVisibility(v201_.node, true)
			end
			v193_.hookData:setTargetNode(v199_.referenceNode, true)
		end
		self:updateTreeAttachRopes(9999)
		if v192_.samples.attachTree ~= nil and v192_.samples.attachTree.soundNode ~= nil then
			setWorldTranslation(v192_.samples.attachTree.soundNode, x, y, z)
			g_soundManager:playSample(v192_.samples.attachTree)
		end
		if v198_ == 1 and v192_.rope.componentJointIndex ~= nil then
			local v202_ = self.componentJoints[v192_.rope.componentJointIndex]
			local v203_ = v192_.rope.componentJointLimitActive
			self:setComponentJointRotLimit(v202_, 1, -v203_[1], v203_[1])
			self:setComponentJointRotLimit(v202_, 2, -v203_[2], v203_[2])
			self:setComponentJointRotLimit(v202_, 3, -v203_[3], v203_[3])
		end
		if v192_.yarderTowerVehicle ~= nil then
			SpecializationUtil.raiseEvent(v192_.yarderTowerVehicle, "onYarderCarriageTreeAttached", splitShapeId)
		end
		g_messageCenter:publish(MessageType.TREE_SHAPE_MOUNTED, splitShapeId, self)
		self:raiseActive()
		TreeAttachEvent.sendEvent(self, splitShapeId, x, y, z, nil, noEventSend)
	end
end

-- Local values: spec, constr, springForce, springDamping, distance
function YarderCarriage:createJoint(shapeId, shapeJointId)
	local v207_ = self.spec_yarderCarriage
	local v208_ = JointConstructor.new()
	v208_:setActors(v207_.joint.component, shapeId)
	v208_:setJointTransforms(v207_.joint.node, shapeJointId)
	v208_:setRotationLimit(0, -3.141592653589793, 3.141592653589793)
	v208_:setRotationLimit(1, -3.141592653589793, 3.141592653589793)
	v208_:setRotationLimit(2, -3.141592653589793, 3.141592653589793)
	v208_:setEnableCollision(true)
	v208_:setRotationLimitSpring(7500, 1500, 7500, 1500, 7500, 1500)
	v208_:setTranslationLimitSpring(7500, 1500, 7500, 1500, 7500, 1500)
	local v209_ = calcDistanceFrom(v207_.joint.node, shapeJointId)
	v208_:setTranslationLimit(0, true, -v209_, v209_)
	v208_:setTranslationLimit(1, true, -v209_, v209_)
	v208_:setTranslationLimit(2, true, -v209_, v209_)
	return v208_:finalize(), v209_
end

function YarderCarriage:onDetachTreeAction()
	self:detachTreeFromCarriage()
end

-- Local values: spec, i, treeData, i, additionalRope, j, hookNode, componentJoint, limit
function YarderCarriage:detachTreeFromCarriage(ropeIndex, noEventSend)
	local v213_ = self.spec_yarderCarriage
	if v213_.samples.detachTree ~= nil and (v213_.samples.detachTree.soundNode ~= nil and (v213_.attachedTrees[1] ~= nil and entityExists(v213_.attachedTrees[1].hookData.hookId))) then
		setWorldTranslation(v213_.samples.detachTree.soundNode, getWorldTranslation(v213_.attachedTrees[1].hookData.hookId))
		g_soundManager:playSample(v213_.samples.detachTree)
	end
	for v214_ = #v213_.attachedTrees, 1, -1 do
		local v215_ = v213_.attachedTrees[v214_]
		if self.isServer then
			removeJoint(v215_.jointIndex)
		end
		v215_.hookData:delete()
		table.remove(v213_.attachedTrees, v214_)
	end
	for v216_ = 1, #v213_.additionalRopes do
		local v217_ = v213_.additionalRopes[v216_]
		setVisibility(v217_.referenceNode, false)
		for v218_ = 1, #v217_.hookNodes do
			local v219_ = v217_.hookNodes[v218_]
			setVisibility(v219_.node, false)
		end
	end
	ObjectChangeUtil.setObjectChanges(v213_.rope.changeObjects, false, self, self.setMovingToolDirty)
	if v213_.rope.componentJointIndex ~= nil then
		local v220_ = self.componentJoints[v213_.rope.componentJointIndex]
		local v221_ = v213_.rope.componentJointLimitInactive
		self:setComponentJointRotLimit(v220_, 1, -v221_[1], v221_[1])
		self:setComponentJointRotLimit(v220_, 2, -v221_[2], v221_[2])
		self:setComponentJointRotLimit(v220_, 3, -v221_[3], v221_[3])
	end
	TreeDetachEvent.sendEvent(self, nil, noEventSend)
end

function YarderCarriage:getNumAttachedTrees()
	return #self.spec_yarderCarriage.attachedTrees
end

function YarderCarriage:getMaxNumAttachedTrees()
	return self.spec_yarderCarriage.maxNumTrees
end

-- Local values: spec, totalMass, i
function YarderCarriage:getAttachedTreeMass()
	local v225_ = self.spec_yarderCarriage
	local v226_ = 0
	for v227_ = 1, #v225_.attachedTrees do
		v226_ = v226_ + getMass(v225_.attachedTrees[v227_].treeId)
	end
	return v226_
end

-- Local values: spec
function YarderCarriage:getIsCarriageTreeAttachAllowed(splitShapeId)
	local v230_ = self.spec_yarderCarriage
	if splitShapeId == nil or not entityExists(splitShapeId) then
		return false, TreeAttachResponseEvent.TREE_ATTACH_FAIL_REASON_DEFAULT
	elseif #v230_.attachedTrees >= v230_.maxNumTrees then
		return false, TreeAttachResponseEvent.TREE_ATTACH_FAIL_REASON_DEFAULT
	elseif getMass(splitShapeId) + self:getAttachedTreeMass() > v230_.maxTreeMass then
		return false, TreeAttachResponseEvent.TREE_ATTACH_FAIL_REASON_TOO_HEAVY
	elseif getUserAttribute(splitShapeId, "isTensionBeltMounted") == true then
		return false, TreeAttachResponseEvent.TREE_ATTACH_FAIL_REASON_DEFAULT
	else
		return true, TreeAttachResponseEvent.TREE_ATTACH_FAIL_REASON_DEFAULT
	end
end

-- Local values: spec
function YarderCarriage:getIsTreeInMountRange()
	local v232_ = self.spec_yarderCarriage
	if v232_.treeRaycast.validTree == nil then
		return false
	elseif entityExists(v232_.treeRaycast.validTree) then
		return #v232_.attachedTrees < v232_.maxNumTrees
	else
		return false
	end
end

-- Local values: spec
function YarderCarriage:showCarriageTreeMountFailedWarning(ropeIndex, reason)
	local v235_ = self.spec_yarderCarriage
	if reason == TreeAttachResponseEvent.TREE_ATTACH_FAIL_REASON_TOO_HEAVY then
		g_currentMission:showBlinkingWarning(string.format(v235_.texts.warningTooHeavy, v235_.maxTreeMass), 2500)
	end
end

-- Local values: spec, i, treeData, minDistance, distance, move
function YarderCarriage:setCarriageLiftInput(direction)
	if self.isServer then
		local v238_ = self.spec_yarderCarriage
		for v239_ = 1, #v238_.attachedTrees do
			local v240_ = v238_.attachedTrees[v239_]
			local v241_ = v238_.joint.minDistance
			if v239_ > 1 then
				local v242_ = v238_.attachedTrees[1].transLimitY
				v241_ = math.max(v242_, v241_)
			end
			if entityExists(v240_.treeId) then
				local v243_ = calcDistanceFrom(v238_.joint.node, v240_.hookData.hookId)
				if direction ~= v238_.curLiftSpeedLastDirection then
					v238_.curLiftSpeedAlpha = 0
					v238_.curLiftSpeedLastDirection = direction
				end
				local v244_ = v238_.curLiftSpeedAlpha + g_currentDt * v238_.liftAcceleration
				v238_.curLiftSpeedAlpha = math.min(v244_, 1)
				local v245_ = -(v238_.liftSpeed * v238_.curLiftSpeedAlpha) * g_currentDt * direction
				local v246_ = v240_.transLimitY + v245_
				local v247_ = v243_ + 0.3
				local v248_ = math.max(v241_, v247_)
				v240_.transLimitY = math.clamp(v246_, v241_, v248_)
				setJointTranslationLimit(v240_.jointIndex, 1, true, -v240_.transLimitY, 0)
				if v239_ == 1 and v240_.transLimitY ~= v238_.lastTransLimitY then
					if v245_ < 0 then
						if not g_soundManager:getIsSamplePlaying(v238_.samples.lift) then
							g_soundManager:playSample(v238_.samples.lift)
							g_soundManager:stopSample(v238_.samples.lower)
							v238_.sampleLiftPlayedSent = true
							v238_.sampleLowerPlayedSent = false
						end
					elseif not g_soundManager:getIsSamplePlaying(v238_.samples.lower) then
						g_soundManager:playSample(v238_.samples.lower)
						g_soundManager:stopSample(v238_.samples.lift)
						v238_.sampleLowerPlayedSent = true
						v238_.sampleLiftPlayedSent = false
					end
					if v240_.transLimitY == v238_.joint.minDistance then
						g_soundManager:playSample(v238_.samples.liftLimit)
						v238_.sampleLiftLimitPlayedSent = true
					end
					v238_.lastTransLimitY = v240_.transLimitY
					v238_.lastTransLimitYTimeOffset = 250
					self:raiseDirtyFlags(v238_.dirtyFlag)
				end
			end
		end
	end
end

function YarderCarriage.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".attachedTree(?)#translation", "Main rope is active")
	schema:register(XMLValueType.INT, basePath .. ".attachedTree(?)#splitShapePart1", "Split shape data part 1")
	schema:register(XMLValueType.INT, basePath .. ".attachedTree(?)#splitShapePart2", "Split shape data part 2")
	schema:register(XMLValueType.INT, basePath .. ".attachedTree(?)#splitShapePart3", "Split shape data part 3")
end

-- Local values: spec, i, treeData, treeKey, splitShapePart1, splitShapePart2, splitShapePart3
function YarderCarriage:saveAttachedTreesToXML(xmlFile, key, usedModNames)
	local v254_ = self.spec_yarderCarriage
	for v255_ = 1, #v254_.attachedTrees do
		local v256_ = v254_.attachedTrees[v255_]
		local v257_ = string.format("%s.attachedTree(%d)", key, v255_ - 1)
		xmlFile:setValue(v257_ .. "#translation", getWorldTranslation(v256_.hookData.hookId))
		local v258_, v259_, v260_ = getSaveableSplitShapeId(v256_.treeId)
		if v258_ ~= 0 and v258_ ~= nil then
			xmlFile:setValue(v257_ .. "#splitShapePart1", v258_)
			xmlFile:setValue(v257_ .. "#splitShapePart2", v259_)
			xmlFile:setValue(v257_ .. "#splitShapePart3", v260_)
		end
	end
end

-- Local values: data
function YarderCarriage.loadAttachedTreesFromXML(xmlFile, key)
	local v_u_263_ = {}
	xmlFile:iterate(key .. ".attachedTree", function(_, p264_)
		-- upvalues: (copy) xmlFile, (copy) v_u_263_
		local v265_ = xmlFile:getValue(p264_ .. "#translation", nil, true)
		if v265_ ~= nil then
			local v266_ = xmlFile:getValue(p264_ .. "#splitShapePart1")
			if v266_ ~= nil then
				local v267_ = v_u_263_
				local v268_ = {
					["translation"] = v265_,
					["splitShapePart1"] = v266_,
					["splitShapePart2"] = xmlFile:getValue(p264_ .. "#splitShapePart2"),
					["splitShapePart3"] = xmlFile:getValue(p264_ .. "#splitShapePart3")
				}
				table.insert(v267_, v268_)
			end
		end
	end)
	return v_u_263_
end

-- Local values: i, treeData, shapeId, i, treeData, shapeId
function YarderCarriage:resolveLoadedAttachedTrees(data)
	for v271_ = 1, #data do
		local v272_ = data[v271_]
		local v273_ = getShapeFromSaveableSplitShapeId(v272_.splitShapePart1, v272_.splitShapePart2, v272_.splitShapePart3)
		if v273_ == nil or v273_ == 0 then
			return false
		end
	end
	for v274_ = 1, #data do
		local v275_ = data[v274_]
		self:attachTreeToCarriage(getShapeFromSaveableSplitShapeId(v275_.splitShapePart1, v275_.splitShapePart2, v275_.splitShapePart3), v275_.translation[1], v275_.translation[2], v275_.translation[3], nil, true)
	end
	return true
end

-- Local values: spec, i
function YarderCarriage:onYarderCarriageTreeShapeCut(oldShape, shape)
	if self.isServer then
		local v278_ = self.spec_yarderCarriage
		for v279_ = 1, #v278_.attachedTrees do
			if v278_.attachedTrees[v279_].treeId == oldShape then
				self:detachTreeFromCarriage()
				return
			end
		end
	end
end

-- Local values: spec, i
function YarderCarriage:onYarderCarriageTreeShapeMounted(shape, mountVehicle)
	if mountVehicle ~= self and self.isServer then
		local v283_ = self.spec_yarderCarriage
		for v284_ = 1, #v283_.attachedTrees do
			if v283_.attachedTrees[v284_].treeId == shape then
				self:detachTreeFromCarriage()
				return
			end
		end
	end
end

-- Local values: multiplier, spec
function YarderCarriage:getDirtMultiplier(superFunc)
	local v287_ = superFunc(self)
	local v288_ = self.spec_yarderCarriage
	if v288_.yarderTowerVehicle == nil then
		return v287_
	else
		return v288_.yarderTowerVehicle:getDirtMultiplier()
	end
end

-- Local values: multiplier, spec
function YarderCarriage:getWearMultiplier(superFunc)
	local v291_ = superFunc(self)
	local v292_ = self.spec_yarderCarriage
	if v292_.yarderTowerVehicle == nil then
		return v291_
	else
		return v292_.yarderTowerVehicle:getDirtMultiplier()
	end
end
