Winch = {}
Winch.TREE_RAYCAST_DISTANCE = 5
Winch.CONTROL_RANGE = 12.5
source("dataS/scripts/vehicles/specializations/events/TreeAttachEvent.lua")
source("dataS/scripts/vehicles/specializations/events/TreeAttachRequestEvent.lua")
source("dataS/scripts/vehicles/specializations/events/TreeAttachResponseEvent.lua")
source("dataS/scripts/vehicles/specializations/events/TreeDetachEvent.lua")
source("dataS/scripts/vehicles/specializations/activatables/WinchAttachTreeActivatable.lua")
source("dataS/scripts/vehicles/specializations/activatables/WinchControlRopeActivatable.lua")

function Winch.prerequisitesPresent(specializations)
	return true
end
function Winch.initSpecialization()
	if g_iconGenerator == nil then
		g_vehicleConfigurationManager:addConfigurationType("winch", g_i18n:getText("configuration_winch"), "winch", VehicleConfigurationItem)
	end
	g_storeManager:addSpecType("winchMaxMass", "shopListAttributeIconWinchMaxMass", Winch.loadSpecValueMaxMass, Winch.getSpecValueMaxMass, StoreSpecies.VEHICLE)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("Winch")
	Winch.registerXMLPaths(v1_, "vehicle.winch")
	Winch.registerXMLPaths(v1_, "vehicle.winch.winchConfigurations.winchConfiguration(?)")
	ObjectChangeUtil.registerObjectChangeXMLPaths(v1_, "vehicle.winch.winchConfigurations.winchConfiguration(?)")
	v1_:setXMLSpecializationType()
end

-- Local values: schemaSavegame, key
function Winch.registerXMLPaths(schema, baseKey)
	schema:register(XMLValueType.INT, baseKey .. "#controlGroupIndex", "Winch controls are only active while this cylindered control group is used")
	schema:register(XMLValueType.INT, baseKey .. ".rope(?)#maxNumTrees", "Max. number of trees that can be attached", 1)
	schema:register(XMLValueType.FLOAT, baseKey .. ".rope(?)#maxTreeMass", "Max. tree mass that can be attached (to)", 1)
	schema:register(XMLValueType.NODE_INDEX, baseKey .. ".rope(?)#node", "Outgoing node for the rope")
	schema:register(XMLValueType.NODE_INDEX, baseKey .. ".rope(?)#triggerNode", "Trigger node to pickup the rope as player")
	schema:register(XMLValueType.FLOAT, baseKey .. ".rope(?)#minLength", "Minimum length of the rope", 1)
	schema:register(XMLValueType.FLOAT, baseKey .. ".rope(?)#maxLength", "Maximum length of the rope", 30)
	schema:register(XMLValueType.FLOAT, baseKey .. ".rope(?)#maxSubLength", "Maximum length of the rope from tree to tree when attaching multiple trees to one rope", 2)
	schema:register(XMLValueType.FLOAT, baseKey .. ".rope(?)#speed", "Speed when pulling the rope [m/sec]", 1.5)
	schema:register(XMLValueType.FLOAT, baseKey .. ".rope(?)#acceleration", "Acceleration (time in seconds until full speed is reached)", 1.5)
	ForestryPhysicsRope.registerXMLPaths(schema, baseKey .. ".rope(?).mainRope")
	ForestryPhysicsRope.registerXMLPaths(schema, baseKey .. ".rope(?).setupRope")
	schema:register(XMLValueType.INT, baseKey .. ".rope(?).componentJoint(?)#jointIndex", "Index of component joint")
	schema:register(XMLValueType.VECTOR_ROT, baseKey .. ".rope(?).componentJoint(?)#limitActive", "Rotation limit of component joint while tree is attached")
	schema:register(XMLValueType.VECTOR_ROT, baseKey .. ".rope(?).componentJoint(?)#limitInactive", "Rotation limit of component joint while no tree is attached")
	schema:register(XMLValueType.NODE_INDEX, baseKey .. ".rope(?).attach#node", "Outgoing node for tree attach rope (used for dummy rope display)")
	schema:register(XMLValueType.TIME, baseKey .. ".rope(?).attach#time", "Time until the tree is fully attached", 0.5)
	TargetTreeMarker.registerXMLPaths(schema, baseKey .. ".rope(?).attach.marker")
	ForestryHook.registerXMLPaths(schema, baseKey .. ".rope(?).treeHook")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, baseKey .. ".rope(?)")
	SoundManager.registerSampleXMLPaths(schema, baseKey .. ".rope(?).sounds", "pullRope")
	SoundManager.registerSampleXMLPaths(schema, baseKey .. ".rope(?).sounds", "releaseRope")
	SoundManager.registerSampleXMLPaths(schema, baseKey .. ".rope(?).sounds", "attachTree")
	SoundManager.registerSampleXMLPaths(schema, baseKey .. ".rope(?).sounds", "detachTree")
	AnimationManager.registerAnimationNodesXMLPaths(schema, baseKey .. ".rope(?).animationNodes")
	schema:addDelayedRegistrationFunc("Cylindered:movingTool", function(p4_, p5_)
		p4_:register(XMLValueType.VECTOR_N, p5_ .. ".winch#ropeIndices", "List of rope indices which are update while moving part changes")
	end)
	schema:addDelayedRegistrationFunc("Cylindered:movingPart", function(p6_, p7_)
		p6_:register(XMLValueType.VECTOR_N, p7_ .. ".winch#ropeIndices", "List of rope indices which are update while moving part changes")
	end)
	local v8_ = Vehicle.xmlSchemaSavegame
	v8_:register(XMLValueType.INT, "vehicles.vehicle(?).winch.rope(?)#index", "Rope index")
	v8_:register(XMLValueType.VECTOR_TRANS, "vehicles.vehicle(?).winch.rope(?).attachedTree(?)#translation", "Translation of attached tree")
	v8_:register(XMLValueType.INT, "vehicles.vehicle(?).winch.rope(?).attachedTree(?)#splitShapePart1", "Split shape data part 1")
	v8_:register(XMLValueType.INT, "vehicles.vehicle(?).winch.rope(?).attachedTree(?)#splitShapePart2", "Split shape data part 2")
	v8_:register(XMLValueType.INT, "vehicles.vehicle(?).winch.rope(?).attachedTree(?)#splitShapePart3", "Split shape data part 3")
	ForestryPhysicsRope.registerSavegameXMLPaths(v8_, "vehicles.vehicle(?).winch.rope(?).attachedTree(?).physicsRope")
end

function Winch.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadWinchRopeFromXML", Winch.loadWinchRopeFromXML)
	SpecializationUtil.registerFunction(vehicleType, "setWinchTreeAttachMode", Winch.setWinchTreeAttachMode)
	SpecializationUtil.registerFunction(vehicleType, "getIsWinchAttachModeActive", Winch.getIsWinchAttachModeActive)
	SpecializationUtil.registerFunction(vehicleType, "getCanAttachWinchTree", Winch.getCanAttachWinchTree)
	SpecializationUtil.registerFunction(vehicleType, "onAttachTreeInputEvent", Winch.onAttachTreeInputEvent)
	SpecializationUtil.registerFunction(vehicleType, "getWinchRopeSpeedFactor", Winch.getWinchRopeSpeedFactor)
	SpecializationUtil.registerFunction(vehicleType, "getIsWinchTreeAttachAllowed", Winch.getIsWinchTreeAttachAllowed)
	SpecializationUtil.registerFunction(vehicleType, "showWinchTreeMountFailedWarning", Winch.showWinchTreeMountFailedWarning)
	SpecializationUtil.registerFunction(vehicleType, "attachTreeToWinch", Winch.attachTreeToWinch)
	SpecializationUtil.registerFunction(vehicleType, "detachTreeFromWinch", Winch.detachTreeFromWinch)
	SpecializationUtil.registerFunction(vehicleType, "setWinchControlInput", Winch.setWinchControlInput)
	SpecializationUtil.registerFunction(vehicleType, "onWinchPlayerTriggerCallback", Winch.onWinchPlayerTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "onWinchTreeRaycastCallback", Winch.onWinchTreeRaycastCallback)
	SpecializationUtil.registerFunction(vehicleType, "onWinchTreeShapeCut", Winch.onWinchTreeShapeCut)
	SpecializationUtil.registerFunction(vehicleType, "onWinchTreeShapeMounted", Winch.onWinchTreeShapeMounted)
	SpecializationUtil.registerFunction(vehicleType, "onPlayerPreTeleport", Winch.onPlayerPreTeleport)
end

function Winch.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadExtraDependentParts", Winch.loadExtraDependentParts)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateExtraDependentParts", Winch.updateExtraDependentParts)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoConsumePtoPower", Winch.getDoConsumePtoPower)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConsumingLoad", Winch.getConsumingLoad)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsPowerTakeOffActive", Winch.getIsPowerTakeOffActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", Winch.addToPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", Winch.removeFromPhysics)
end

function Winch.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Winch)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Winch)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Winch)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Winch)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Winch)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Winch)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Winch)
	SpecializationUtil.registerEventListener(vehicleType, "onPostUpdate", Winch)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Winch)
end

-- Local values: spec, configurationId, configKey, _, ropeKey, rope, _, ropeKey, rope
function Winch:onLoad(savegame)
	local v13_ = self.spec_winch
	v13_.texts = {}
	local v14_ = Utils.getNoNil(self.configurations.winch, 1)
	local v15_ = string.format("vehicle.winch.winchConfigurations.winchConfiguration(%d)", v14_ - 1)
	ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.winch.winchConfigurations.winchConfiguration", v14_, self.components, self)
	v13_.controlGroupIndex = self.xmlFile:getValue("vehicle.winch#controlGroupIndex", self.xmlFile:getValue(v15_ .. "#controlGroupIndex"))
	v13_.ropes = {}
	for _, v16_ in self.xmlFile:iterator("vehicle.winch.rope") do
		local v17_ = {}
		if self:loadWinchRopeFromXML(self.xmlFile, v16_, v17_) then
			local v18_ = v13_.ropes
			table.insert(v18_, v17_)
			v17_.index = #v13_.ropes
		end
	end
	for _, v19_ in self.xmlFile:iterator(v15_ .. ".rope") do
		local v20_ = {}
		if self:loadWinchRopeFromXML(self.xmlFile, v19_, v20_) then
			local v21_ = v13_.ropes
			table.insert(v21_, v20_)
			v20_.index = #v13_.ropes
		end
	end
	if #v13_.ropes > 0 then
		v13_.hasRopes = true
		v13_.texts.startAttachMode = g_i18n:getText("input_WINCH_ATTACH_MODE")
		v13_.texts.stopAttachMode = g_i18n:getText("winch_releaseRope")
		v13_.texts.attachTree = g_i18n:getText("input_WINCH_ATTACH")
		v13_.texts.attachAnotherTree = g_i18n:getText("winch_attachAnotherTree")
		v13_.texts.detachTree = g_i18n:getText("input_WINCH_DETACH")
		v13_.texts.control = g_i18n:getText("winch_control")
		v13_.texts.warningTooHeavy = g_i18n:getText("winch_treeTooHeavy")
		v13_.texts.warningMaxNumTreesReached = g_i18n:getText("winch_maxNumTreesReached")
		v13_.texts.warningMaxLengthReached = g_i18n:getText("winch_ropeMaxLengthReached")
		v13_.treeRaycast = {}
		v13_.treeRaycast.hasStarted = false
		v13_.treeRaycast.startPos = { 0, 0, 0 }
		v13_.treeRaycast.treeTargetPos = { 0, 0, 0 }
		v13_.treeRaycast.treeCenterPos = { 0, 0, 0 }
		v13_.treeRaycast.treeUp = { 0, 1, 0 }
		v13_.treeRaycast.treeRadius = 1
		v13_.treeRaycast.maxDistance = math.huge
		v13_.splitShapesToAttach = {}
		v13_.isAttachable = SpecializationUtil.hasSpecialization(Attachable, self.specializations)
		g_messageCenter:subscribe(MessageType.TREE_SHAPE_CUT, self.onWinchTreeShapeCut, self)
		g_messageCenter:subscribe(MessageType.TREE_SHAPE_MOUNTED, self.onWinchTreeShapeMounted, self)
		g_messageCenter:subscribe(MessageType.PLAYER_PRE_TELEPORT, self.onWinchTreeShapeMounted, self)
		v13_.dirtyFlag = self:getNextDirtyFlag()
		v13_.ropeDirtyFlag = self:getNextDirtyFlag()
	else
		SpecializationUtil.removeEventListener(self, "onLoadFinished", Winch)
		SpecializationUtil.removeEventListener(self, "onDelete", Winch)
		SpecializationUtil.removeEventListener(self, "onReadStream", Winch)
		SpecializationUtil.removeEventListener(self, "onWriteStream", Winch)
		SpecializationUtil.removeEventListener(self, "onReadUpdateStream", Winch)
		SpecializationUtil.removeEventListener(self, "onWriteUpdateStream", Winch)
		SpecializationUtil.removeEventListener(self, "onPostUpdate", Winch)
		SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", Winch)
	end
end

-- Local values: specKey
function Winch:onLoadFinished(savegame)
	if savegame ~= nil and not savegame.resetVehicles then
		local v24_ = savegame.key .. ".winch"
		savegame.xmlFile:iterate(v24_ .. ".rope", function(_, p25_)
			-- upvalues: (copy) savegame, (copy) self
			local v_u_26_ = savegame.xmlFile:getValue(p25_ .. "#index", 1)
			savegame.xmlFile:iterate(p25_ .. ".attachedTree", function(_, p27_)
				-- upvalues: (ref) savegame, (ref) self, (copy) v_u_26_
				local v28_ = savegame.xmlFile:getValue(p27_ .. "#translation", nil, true)
				if v28_ ~= nil then
					local v29_ = savegame.xmlFile:getValue(p27_ .. "#splitShapePart1")
					if v29_ ~= nil then
						local v30_ = savegame.xmlFile:getValue(p27_ .. "#splitShapePart2")
						local v31_ = savegame.xmlFile:getValue(p27_ .. "#splitShapePart3")
						local v32_ = ForestryPhysicsRope.loadPositionDataFromSavegame(savegame.xmlFile, p27_ .. ".physicsRope")
						local v33_ = getShapeFromSaveableSplitShapeId(v29_, v30_, v31_)
						if v33_ ~= nil and v33_ ~= 0 then
							self:attachTreeToWinch(v33_, v28_[1], v28_[2], v28_[3], v_u_26_, v32_, true)
						end
					end
				end
			end)
		end)
	end
end

-- Local values: spec, i, rope
function Winch:onDelete()
	local v35_ = self.spec_winch
	if v35_.ropes ~= nil then
		for v36_ = 1, #v35_.ropes do
			local v37_ = v35_.ropes[v36_]
			self:detachTreeFromWinch(v36_, true)
			removeTrigger(v37_.triggerNode)
			v37_.mainRope:delete()
			v37_.setupRope:delete()
			v37_.attachMarker:delete()
			v37_.hookData:delete()
			if self.isClient then
				g_soundManager:deleteSamples(v37_.samples)
				g_animationManager:deleteAnimations(v37_.animationNodes)
			end
			g_currentMission.activatableObjectsSystem:removeActivatable(v37_.attachTreeActivatable)
			g_currentMission.activatableObjectsSystem:removeActivatable(v37_.controlActivatable)
		end
	end
end

-- Local values: spec, ropeIndex, rope, numTrees, j, x, y, z, splitShapeId, splitShapeId1, splitShapeId2
function Winch:onReadStream(streamId, connection)
	local v40_ = self.spec_winch
	for v41_ = 1, #v40_.ropes do
		local v42_ = v40_.ropes[v41_]
		if streamReadBool(streamId) then
			for _ = 1, streamReadUIntN(streamId, v42_.maxTreeBits) + 1 do
				local v43_ = streamReadFloat32(streamId)
				local v44_ = streamReadFloat32(streamId)
				local v45_ = streamReadFloat32(streamId)
				local v46_, v47_, v48_ = readSplitShapeIdFromStream(streamId)
				if v46_ == 0 then
					if v47_ ~= 0 then
						local v49_ = v40_.splitShapesToAttach
						table.insert(v49_, {
							["splitShapeId1"] = v47_,
							["splitShapeId2"] = v48_,
							["x"] = v43_,
							["y"] = v44_,
							["z"] = v45_,
							["ropeIndex"] = v41_
						})
					end
				else
					local v50_, v51_, v52_ = localToWorld(v46_, v43_, v44_, v45_)
					self:attachTreeToWinch(v46_, v50_, v51_, v52_, v41_, nil, true)
				end
			end
		end
	end
end

-- Local values: spec, i, rope, j, attachData, x, y, z
function Winch:onWriteStream(streamId, connection)
	local v55_ = self.spec_winch
	for v56_ = 1, #v55_.ropes do
		local v57_ = v55_.ropes[v56_]
		if streamWriteBool(streamId, #v57_.attachedTrees > 0) then
			streamWriteUIntN(streamId, #v57_.attachedTrees - 1, v57_.maxTreeBits)
			for v58_ = 1, #v57_.attachedTrees do
				local v59_ = v57_.attachedTrees[v58_]
				local v60_, v61_, v62_ = worldToLocal(v59_.treeId, getWorldTranslation(v59_.activeHookData.hookId))
				streamWriteFloat32(streamId, v60_)
				streamWriteFloat32(streamId, v61_)
				streamWriteFloat32(streamId, v62_)
				writeSplitShapeIdToStream(streamId, v59_.treeId)
			end
		end
	end
end

-- Local values: spec, i, i, rope, i, rope
function Winch:onReadUpdateStream(streamId, timestamp, connection)
	local v66_ = self.spec_winch
	if connection:getIsServer() then
		if streamReadBool(streamId) then
			for v67_ = 1, #v66_.ropes do
				local v68_ = v66_.ropes[v67_]
				v68_.controlDirection = streamReadUIntN(streamId, 2) - 1
				v68_.lastControlTimer = 500
				if v68_.controlDirection > 0 then
					if not g_soundManager:getIsSamplePlaying(v68_.samples.pullRope) then
						g_soundManager:playSample(v68_.samples.pullRope)
						g_soundManager:stopSample(v68_.samples.releaseRope)
					end
					g_animationManager:startAnimations(v68_.animationNodes)
				elseif v68_.controlDirection < 0 then
					if not g_soundManager:getIsSamplePlaying(v68_.samples.releaseRope) then
						g_soundManager:playSample(v68_.samples.releaseRope)
						g_soundManager:stopSample(v68_.samples.pullRope)
					end
					g_animationManager:startAnimations(v68_.animationNodes)
				end
			end
		end
		if streamReadBool(streamId) then
			for v69_ = 1, #v66_.ropes do
				v66_.ropes[v69_].mainRope:readUpdateStream(streamId)
			end
		end
	elseif streamReadBool(streamId) then
		for v70_ = 1, #v66_.ropes do
			self:setWinchControlInput(v70_, streamReadUIntN(streamId, 2) - 1)
		end
		return
	end
end

-- Local values: spec, i, i, i, rope
function Winch:onWriteUpdateStream(streamId, connection, dirtyMask)
	local v75_ = self.spec_winch
	if connection:getIsServer() then
		local v76_ = streamWriteBool
		local v77_ = v75_.dirtyFlag
		if v76_(streamId, bit32.band(dirtyMask, v77_) ~= 0) then
			for v78_ = 1, #v75_.ropes do
				local v79_ = streamWriteUIntN
				local v80_ = v75_.ropes[v78_].controlInputSent
				v79_(streamId, math.sign(v80_) + 1, 2)
			end
			return
		end
	else
		local v81_ = streamWriteBool
		local v82_ = v75_.dirtyFlag
		if v81_(streamId, bit32.band(dirtyMask, v82_) ~= 0) then
			for v83_ = 1, #v75_.ropes do
				local v84_ = streamWriteUIntN
				local v85_ = v75_.ropes[v83_].controlDirection
				v84_(streamId, math.sign(v85_) + 1, 2)
			end
		end
		local v86_ = streamWriteBool
		local v87_ = v75_.ropeDirtyFlag
		if v86_(streamId, bit32.band(dirtyMask, v87_) ~= 0) then
			for v88_ = 1, #v75_.ropes do
				v75_.ropes[v88_].mainRope:writeUpdateStream(streamId)
			end
		end
	end
end

-- Local values: spec, saveIndex, i, rope, ropeKey, j, attachData, treeKey, splitShapePart1, splitShapePart2, splitShapePart3
function Winch:saveToXMLFile(xmlFile, key, usedModNames)
	local v92_ = self.spec_winch
	local v93_ = 0
	for v94_ = 1, #v92_.ropes do
		local v95_ = v92_.ropes[v94_]
		if #v95_.attachedTrees > 0 then
			local v96_ = string.format("%s.rope(%d)", key, v93_)
			xmlFile:setValue(v96_ .. "#index", v94_)
			for v97_ = 1, #v95_.attachedTrees do
				local v98_ = v95_.attachedTrees[v97_]
				local v99_ = string.format("%s.attachedTree(%d)", v96_, v97_ - 1)
				xmlFile:setValue(v99_ .. "#translation", getWorldTranslation(v98_.activeHookData.hookId))
				local v100_, v101_, v102_ = getSaveableSplitShapeId(v98_.treeId)
				if v100_ ~= 0 and v100_ ~= nil then
					xmlFile:setValue(v99_ .. "#splitShapePart1", v100_)
					xmlFile:setValue(v99_ .. "#splitShapePart2", v101_)
					xmlFile:setValue(v99_ .. "#splitShapePart3", v102_)
				end
				v95_.mainRope:saveToXMLFile(xmlFile, v99_ .. ".physicsRope")
			end
			v93_ = v93_ + 1
		end
	end
end

-- Local values: spec, i, attachData, splitShapeId, x, y, z, i, rope, j, attachData, i, rope, player, cameraNode, x, y, z, dx, dy, dz, sx, sy, sz, rootData, maxRopeLength, lengthExtension, kinematicHelperNode, rootData, lengthPercentage, r, g, b, a
function Winch:onPostUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v105_ = self.spec_winch
	if self.isServer then
		for v106_ = 1, #v105_.ropes do
			local v107_ = v105_.ropes[v106_]
			for v108_ = 1, #v107_.attachedTrees do
				local v109_ = v107_.attachedTrees[v108_]
				if v109_.treeId == nil or not entityExists(v109_.treeId) then
					self:detachTreeFromWinch()
					break
				end
			end
		end
	else
		for v110_ = #v105_.splitShapesToAttach, 1, -1 do
			local v111_ = v105_.splitShapesToAttach[v110_]
			local v112_ = resolveStreamSplitShapeId(v111_.splitShapeId1, v111_.splitShapeId2)
			if v112_ ~= 0 then
				local v113_, v114_, v115_ = localToWorld(v112_, v111_.x, v111_.y, v111_.z)
				self:attachTreeToWinch(v112_, v113_, v114_, v115_, v111_.ropeIndex, nil, true)
				table.remove(v105_.splitShapesToAttach, v110_)
			end
		end
	end
	for v116_ = 1, #v105_.ropes do
		local v117_ = v105_.ropes[v116_]
		if v117_.isAttachModeActive then
			local v118_ = g_localPlayer
			if v118_ ~= nil then
				if v118_:getIsHoldingHandTool() or not v118_.isControlled then
					self:setWinchTreeAttachMode(v117_, false)
					v105_.treeRaycast.lastValidTree = nil
				else
					local v119_ = v118_:getCurrentCameraNode()
					local v120_, v121_, v122_ = localToWorld(v119_, 0, 0, 1)
					local v123_, v124_, v125_ = localDirectionToWorld(v119_, 0, 0, -1)
					local v126_, v127_, v128_
					if #v117_.attachedTrees > 0 then
						v126_, v127_, v128_ = v117_.attachedTrees[1].activeHookData:getRopeTargetPosition()
					else
						v126_, v127_, v128_ = getWorldTranslation(v117_.attachNode)
					end
					local v129_ = #v117_.attachedTrees > 0 and v117_.maxSubLength or v117_.maxLength
					local v130_ = #v117_.attachedTrees > 0 and 2 or 7.5
					if not v105_.treeRaycast.hasStarted then
						v105_.treeRaycast.hasStarted = true
						v105_.treeRaycast.isFirstAttachment = #v117_.attachedTrees == 0
						v105_.treeRaycast.maxDistance = v129_
						local v131_ = v105_.treeRaycast.startPos
						local v132_ = v105_.treeRaycast.startPos
						local v133_ = v105_.treeRaycast.startPos
						v131_[1] = v126_
						v132_[2] = v127_
						v133_[3] = v128_
						raycastClosestAsync(v120_, v121_, v122_, v123_, v124_, v125_, Winch.TREE_RAYCAST_DISTANCE, "onWinchTreeRaycastCallback", self, CollisionFlag.TREE)
					end
					if v117_.setupRope.physicsRopeIndex == nil then
						local v134_ = v118_.hands.spec_hands.kinematicNode
						if #v117_.attachedTrees == 0 then
							v117_.setupRope:setMaxLength(v117_.maxLength + v130_)
							v117_.setupRope:create(v134_, v134_, nil, nil, false)
						else
							local v135_ = v117_.attachedTrees[1]
							local v136_ = v117_.setupRope
							local v137_ = v117_.maxSubLength
							local v138_ = calcDistanceFrom
							local v139_ = v135_.activeHookData
							v136_:setMaxLength(math.max(v137_, v138_(v134_, v139_:getRopeTarget())) + v130_)
							v117_.setupRope:create(v134_, v134_, v135_.treeId, v135_.activeHookData:getRopeTarget(), false)
						end
						v117_.setupRope:setUseDynamicLength(true)
					end
					local v140_ = v117_.setupRope:getRopeDirectLengthPercentage(v117_.setupRope.maxLength - v130_)
					if v140_ > 1 then
						if (v140_ - 1) * v129_ > v130_ * 0.75 then
							self:setWinchTreeAttachMode(v117_, false)
							v105_.treeRaycast.lastValidTree = nil
						else
							g_currentMission:showBlinkingWarning(v105_.texts.warningMaxLengthReached, 1000)
						end
					end
					if v105_.treeRaycast.lastValidTree == nil then
						if v105_.treeRaycast.lastInValidTree == nil then
							local v141_, v142_, v143_, v144_
							if v140_ > 1 then
								v141_ = 1
								v142_ = 0
								v143_ = 0
								v144_ = 1
							else
								v141_ = 0
								v142_ = 1
								v143_ = 0
								v144_ = 1
							end
							v117_.setupRope:setEmissiveColor(v141_, v142_, v143_, v144_)
						else
							v117_.setupRope:setEmissiveColor(1, 0, 0, 1)
						end
					else
						v117_.setupRope:setEmissiveColor(0, 1, 0, 1)
					end
				end
			end
			if v105_.treeRaycast.lastValidTree == nil then
				v117_.attachMarker:setIsActive(false)
			else
				v117_.attachMarker:setIsActive(true)
				v117_.attachMarker:setPosition(v105_.treeRaycast.treeCenterPos[1], v105_.treeRaycast.treeCenterPos[2], v105_.treeRaycast.treeCenterPos[3], v105_.treeRaycast.treeUp[1], v105_.treeRaycast.treeUp[2], v105_.treeRaycast.treeUp[3], v105_.treeRaycast.treeRadius)
			end
			self:raiseActive()
		end
		if v117_.lastControlTimer > 0 then
			v117_.lastControlTimer = v117_.lastControlTimer - dt
			if v117_.lastControlTimer <= 0 then
				v117_.controlDirection = 0
				v117_.curSpeedAlpha = 0
				g_soundManager:stopSample(v117_.samples.pullRope)
				g_soundManager:stopSample(v117_.samples.releaseRope)
				g_animationManager:stopAnimations(v117_.animationNodes)
			end
			self:raiseActive()
		end
	end
end

-- Local values: spec, actionsAllowed, _, actionEventId
function Winch:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v147_ = self.spec_winch
		self:clearActionEventsTable(v147_.actionEvents)
		if isActiveForInputIgnoreSelection and (v147_.controlGroupIndex == nil or v147_.controlGroupIndex == self.spec_cylindered.currentControlGroupIndex) then
			local _, v148_ = self:addPoweredActionEvent(v147_.actionEvents, InputAction.WINCH_CONTROL_VEHICLE, self, Winch.actionEventControl, false, false, true, true, nil)
			g_inputBinding:setActionEventTextPriority(v148_, GS_PRIO_HIGH)
			g_inputBinding:setActionEventText(v148_, v147_.texts.control)
			local _, v149_ = self:addPoweredActionEvent(v147_.actionEvents, InputAction.WINCH_DETACH, self, Winch.actionEventDetach, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v149_, GS_PRIO_HIGH)
			g_inputBinding:setActionEventText(v149_, v147_.texts.detachTree)
			Winch.updateActionEvents(self)
		end
	end
end

-- Local values: spec, i
function Winch:actionEventControl(actionName, inputValue, callbackState, isAnalog)
	for v152_ = 1, #self.spec_winch.ropes do
		self:setWinchControlInput(v152_, inputValue)
	end
end

function Winch:actionEventDetach(actionName, inputValue, callbackState, isAnalog)
	self:detachTreeFromWinch()
end

-- Local values: spec, treesAttached, i, actionEventControl, actionEventDetach
function Winch:updateActionEvents()
	if self.isClient then
		local v155_ = self.spec_winch
		local v156_ = false
		for v157_ = 1, #v155_.ropes do
			if #v155_.ropes[v157_].attachedTrees > 0 then
				v156_ = true
				break
			end
		end
		local v158_ = v155_.actionEvents[InputAction.WINCH_CONTROL_VEHICLE]
		if v158_ ~= nil then
			g_inputBinding:setActionEventActive(v158_.actionEventId, v156_)
		end
		local v159_ = v155_.actionEvents[InputAction.WINCH_DETACH]
		if v159_ ~= nil then
			g_inputBinding:setActionEventActive(v159_.actionEventId, v156_)
		end
	end
end

function Winch:loadWinchRopeFromXML(xmlFile, key, rope)
	rope.ropeNode = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	rope.triggerNode = xmlFile:getValue(key .. "#triggerNode", nil, self.components, self.i3dMappings)
	rope.maxNumTrees = xmlFile:getValue(key .. "#maxNumTrees", 1)
	local v164_ = rope.maxNumTrees
	local v165_ = math.sqrt(v164_)
	rope.maxTreeBits = math.ceil(v165_)
	rope.maxTreeMass = xmlFile:getValue(key .. "#maxTreeMass", 1)
	rope.minLength = xmlFile:getValue(key .. "#minLength", 1)
	rope.maxLength = xmlFile:getValue(key .. "#maxLength", 30)
	rope.maxSubLength = xmlFile:getValue(key .. "#maxSubLength", 2)
	rope.speed = xmlFile:getValue(key .. "#speed", 1.5) * 0.001
	rope.acceleration = 1 / xmlFile:getValue(key .. "#acceleration", 1.5) * 0.001
	rope.curSpeedAlpha = 0
	rope.attachNode = xmlFile:getValue(key .. ".attach#node", nil, self.components, self.i3dMappings)
	if rope.ropeNode == nil or (rope.triggerNode == nil or rope.attachNode == nil) then
		return false
	end
	addTrigger(rope.triggerNode, "onWinchPlayerTriggerCallback", self)
	rope.jointComponent = self:getParentComponent(rope.ropeNode)
	rope.mainRope = ForestryPhysicsRope.new(self, rope.jointComponent, rope.ropeNode, self.isServer)
	rope.mainRope:loadFromXML(xmlFile, key .. ".mainRope", rope.minLength, rope.maxLength)
	rope.setupRope = ForestryPhysicsRope.new(self, rope.jointComponent, rope.ropeNode, true)
	rope.setupRope:loadFromXML(xmlFile, key .. ".setupRope", rope.minLength, rope.maxLength)
	rope.componentJoints = {}
	xmlFile:iterate(key .. ".componentJoint", function(_, p166_)
		-- upvalues: (copy) xmlFile, (copy) self, (copy) rope
		local v167_ = {
			["index"] = xmlFile:getValue(p166_ .. "#jointIndex")
		}
		if v167_.index ~= nil then
			v167_.jointDesc = self.componentJoints[v167_.index]
			v167_.limitActive = xmlFile:getValue(p166_ .. "#limitActive", nil, true)
			v167_.limitInactive = xmlFile:getValue(p166_ .. "#limitInactive", nil, true)
			if v167_.limitActive ~= nil and v167_.limitInactive ~= nil then
				local v168_ = rope.componentJoints
				table.insert(v168_, v167_)
			end
		end
	end)
	rope.attachMarker = TargetTreeMarker.new(self, self.rootNode)
	rope.attachMarker:loadFromXML(xmlFile, key .. ".attach.marker")
	rope.attachTime = xmlFile:getValue(key .. ".attach#time", 0.5)
	rope.hookData = ForestryHook.new(self, self.rootNode)
	rope.hookData:loadFromXML(xmlFile, key .. ".treeHook")
	rope.hookData:setVisibility(false)
	rope.changeObjects = {}
	ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key, rope.changeObjects, self.components, self)
	ObjectChangeUtil.setObjectChanges(rope.changeObjects, false, self, self.setMovingToolDirty)
	rope.isPlayerInRange = false
	rope.isAttachModeActive = false
	rope.attachedTrees = {}
	rope.controlDirection = 0
	rope.lastControlTimer = 0
	rope.controlInputSent = 0
	rope.samples = {}
	if self.isClient then
		rope.samples.pullRope = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "pullRope", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		rope.samples.releaseRope = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "releaseRope", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		rope.samples.attachTree = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "attachTree", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		rope.samples.detachTree = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "detachTree", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		rope.animationNodes = g_animationManager:loadAnimations(xmlFile, key .. ".animationNodes", self.components, self, self.i3dMappings)
	end
	rope.attachTreeActivatable = WinchAttachTreeActivatable.new(self, rope)
	rope.controlActivatable = WinchControlRopeActivatable.new(self, rope)
	return true
end

function Winch:setWinchTreeAttachMode(rope, state)
	if state == nil then
		state = not rope.isAttachModeActive
	end
	if state ~= rope.isAttachModeActive then
		if state then
			g_currentMission.activatableObjectsSystem:removeActivatable(rope.controlActivatable)
			g_currentMission.activatableObjectsSystem:removeActivatable(rope.attachTreeActivatable)
			g_currentMission.activatableObjectsSystem:addActivatable(rope.attachTreeActivatable)
			self:raiseActive()
		else
			rope.attachMarker:setIsActive(false)
			rope.setupRope:destroy()
			if not rope.isPlayerInRange then
				g_currentMission.activatableObjectsSystem:removeActivatable(rope.attachTreeActivatable)
			end
			if #rope.attachedTrees > 0 then
				g_currentMission.activatableObjectsSystem:addActivatable(rope.controlActivatable)
			end
		end
		rope.isAttachModeActive = state
	end
end

function Winch:getIsWinchAttachModeActive(rope)
	return rope.isAttachModeActive
end

-- Local values: spec
function Winch:getCanAttachWinchTree(rope)
	if rope.isAttachModeActive then
		return self.spec_winch.treeRaycast.lastValidTree ~= nil
	else
		return false
	end
end

-- Local values: spec, isAllowed, reason
function Winch:onAttachTreeInputEvent(rope)
	if rope.isAttachModeActive then
		local v177_ = self.spec_winch
		if v177_.treeRaycast.lastValidTree ~= nil then
			if g_server == nil then
				g_client:getServerConnection():sendEvent(TreeAttachRequestEvent.new(self, v177_.treeRaycast.lastValidTree, v177_.treeRaycast.treeTargetPos[1], v177_.treeRaycast.treeTargetPos[2], v177_.treeRaycast.treeTargetPos[3], rope.index, rope.setupRope))
			else
				local v178_, v179_ = self:getIsWinchTreeAttachAllowed(rope.index, v177_.treeRaycast.lastValidTree)
				if v178_ then
					self:attachTreeToWinch(v177_.treeRaycast.lastValidTree, v177_.treeRaycast.treeTargetPos[1], v177_.treeRaycast.treeTargetPos[2], v177_.treeRaycast.treeTargetPos[3], rope.index, nil)
				else
					self:showWinchTreeMountFailedWarning(rope.index, v179_)
				end
			end
			self:setWinchTreeAttachMode(rope, false)
			v177_.treeRaycast.lastValidTree = nil
		end
	end
end

-- Local values: spec, i
function Winch:getWinchRopeSpeedFactor(param)
	local v182_ = self.spec_winch
	for v183_ = 1, #v182_.ropes do
		if tostring(v183_) == param then
			return v182_.ropes[v183_].controlDirection
		end
	end
	return 1
end

-- Local values: spec, rope, mass, i
function Winch:getIsWinchTreeAttachAllowed(ropeIndex, splitShapeId)
	local v187_ = self.spec_winch.ropes[ropeIndex]
	if v187_ ~= nil then
		local v188_ = getMass(splitShapeId)
		for v189_ = 1, #v187_.attachedTrees do
			v188_ = v188_ + getMass(v187_.attachedTrees[v189_].treeId)
		end
		if v187_.maxTreeMass < v188_ then
			return false, TreeAttachResponseEvent.TREE_ATTACH_FAIL_REASON_TOO_HEAVY
		end
		if #v187_.attachedTrees >= v187_.maxNumTrees then
			return false, TreeAttachResponseEvent.TREE_ATTACH_FAIL_REASON_TOO_MANY
		end
	end
	return true, TreeAttachResponseEvent.TREE_ATTACH_FAIL_REASON_DEFAULT
end

-- Local values: spec, rope
function Winch:showWinchTreeMountFailedWarning(ropeIndex, reason)
	local v193_ = self.spec_winch
	local v194_ = v193_.ropes[ropeIndex]
	if v194_ ~= nil then
		if reason == TreeAttachResponseEvent.TREE_ATTACH_FAIL_REASON_TOO_HEAVY then
			g_currentMission:showBlinkingWarning(string.format(v193_.texts.warningTooHeavy, v194_.maxTreeMass), 2500)
			return
		end
		if reason == TreeAttachResponseEvent.TREE_ATTACH_FAIL_REASON_TOO_MANY then
			g_currentMission:showBlinkingWarning(v193_.texts.warningMaxNumTreesReached, 2500)
		end
	end
end

-- Local values: rope, attachData, centerX, _, _, rootData, startActor, startNode, endActor, endNode, additionalRope, j, componentJoint, limit
function Winch:attachTreeToWinch(splitShapeId, x, y, z, ropeIndex, setupRopeData, noEventSend)
	local v203_ = self.spec_winch.ropes[ropeIndex]
	if v203_ ~= nil then
		local v204_ = {
			["activeHookData"] = v203_.hookData:clone()
		}
		local v205_, _, _ = v204_.activeHookData:mountToTree(splitShapeId, x, y, z, 4)
		if v205_ == nil then
			return
		end
		if #v203_.attachedTrees == 0 then
			v204_.activeHookData:setTargetNode(v203_.ropeNode, true)
			if setupRopeData == nil then
				v203_.mainRope:copyNodePositions(v203_.setupRope, true)
			else
				v203_.mainRope:applySavegamePositions(setupRopeData)
			end
			v203_.mainRope:create(splitShapeId, v204_.activeHookData:getRopeTarget(), nil, nil, true, true)
		else
			local v206_ = v203_.attachedTrees[1]
			v204_.activeHookData:setTargetNode(v206_.activeHookData:getRopeTarget(), true)
			local v207_ = v204_.activeHookData:getRopeTarget()
			local v208_ = v206_.treeId
			local v209_ = v206_.activeHookData:getRopeTarget()
			local v210_ = v203_.mainRope:clone(splitShapeId, v207_, calcDistanceFrom(v207_, v209_))
			v210_:create(v208_, v209_)
			v204_.additionalRope = v210_
		end
		v204_.treeId = splitShapeId
		local v211_ = v203_.attachedTrees
		table.insert(v211_, v204_)
		for v212_ = 1, #v203_.componentJoints do
			local v213_ = v203_.componentJoints[v212_]
			local v214_ = v213_.limitActive
			self:setComponentJointRotLimit(v213_.jointDesc, 1, -v214_[1], v214_[1])
			self:setComponentJointRotLimit(v213_.jointDesc, 2, -v214_[2], v214_[2])
			self:setComponentJointRotLimit(v213_.jointDesc, 3, -v214_[3], v214_[3])
		end
		ObjectChangeUtil.setObjectChanges(v203_.changeObjects, true, self, self.setMovingToolDirty)
		if self.isClient and (v203_.samples.attachTree ~= nil and v203_.samples.attachTree.soundNode ~= nil) then
			g_soundManager:playSample(v203_.samples.attachTree)
			setWorldTranslation(v203_.samples.attachTree.soundNode, x, y, z)
		end
		g_currentMission.activatableObjectsSystem:removeActivatable(v203_.controlActivatable)
		g_currentMission.activatableObjectsSystem:addActivatable(v203_.controlActivatable)
		g_messageCenter:publish(MessageType.TREE_SHAPE_MOUNTED, splitShapeId, self)
		Winch.updateActionEvents(self)
		TreeAttachEvent.sendEvent(self, splitShapeId, x, y, z, ropeIndex, noEventSend)
	end
end

-- Local values: spec, i, rope, ti, attachData, x, y, z, j, componentJoint, limit
function Winch:detachTreeFromWinch(ropeIndex, noEventSend)
	local v218_ = self.spec_winch
	for v219_ = 1, #v218_.ropes do
		if ropeIndex == nil or v219_ == ropeIndex then
			local v220_ = v218_.ropes[v219_]
			if v220_.isAttachModeActive then
				self:setWinchTreeAttachMode(v220_, false)
			end
			for v221_ = #v220_.attachedTrees, 1, -1 do
				local v222_ = v220_.attachedTrees[v221_]
				if not self.isDeleting and (v221_ == 1 and self.isClient) then
					local v223_, v224_, v225_ = v222_.activeHookData:getRopeTargetPosition()
					if v220_.samples.detachTree ~= nil and (v220_.samples.detachTree.soundNode ~= nil and not g_soundManager:getIsSamplePlaying(v220_.samples.pullRope)) then
						g_soundManager:playSample(v220_.samples.detachTree)
						setWorldTranslation(v220_.samples.detachTree.soundNode, v223_, v224_, v225_)
					end
				end
				if v222_.additionalRope ~= nil then
					v222_.additionalRope:destroy()
					v222_.additionalRope:delete()
					v222_.additionalRope = nil
				end
				v222_.activeHookData:delete()
				v220_.mainRope:destroy()
				v220_.attachedTrees[v221_] = nil
			end
			if self.isServer then
				for v226_ = 1, #v220_.componentJoints do
					local v227_ = v220_.componentJoints[v226_]
					local v228_ = v227_.limitInactive
					self:setComponentJointRotLimit(v227_.jointDesc, 1, -v228_[1], v228_[1])
					self:setComponentJointRotLimit(v227_.jointDesc, 2, -v228_[2], v228_[2])
					self:setComponentJointRotLimit(v227_.jointDesc, 3, -v228_[3], v228_[3])
				end
			end
			ObjectChangeUtil.setObjectChanges(v220_.changeObjects, false, self, self.setMovingToolDirty)
			g_currentMission.activatableObjectsSystem:removeActivatable(v220_.controlActivatable)
			if v220_.isPlayerInRange then
				g_currentMission.activatableObjectsSystem:addActivatable(v220_.attachTreeActivatable)
			end
		end
	end
	Winch.updateActionEvents(self)
	TreeDetachEvent.sendEvent(self, ropeIndex, noEventSend)
end

-- Local values: spec, rope, controlDirection
function Winch:setWinchControlInput(ropeIndex, direction)
	local v232_ = self.spec_winch
	if not v232_.isAttachable or self:getAttacherVehicle() ~= nil then
		local v233_ = v232_.ropes[ropeIndex]
		if v233_ ~= nil then
			if self.isServer then
				if direction ~= 0 and #v233_.attachedTrees >= 1 then
					if direction ~= 0 then
						local v234_ = v233_.curSpeedAlpha + g_currentDt * v233_.acceleration
						v233_.curSpeedAlpha = math.min(v234_, 1)
					end
					local v235_ = v233_.mainRope:adjustLength(-(v233_.speed * v233_.curSpeedAlpha) * g_currentDt * direction)
					if v235_ ~= 0 then
						v233_.controlDirection = v235_
						v233_.lastControlTimer = 500
					end
					if self.isClient then
						if v233_.controlDirection > 0 then
							if not g_soundManager:getIsSamplePlaying(v233_.samples.pullRope) then
								g_soundManager:playSample(v233_.samples.pullRope)
								g_soundManager:stopSample(v233_.samples.releaseRope)
							end
							g_animationManager:startAnimations(v233_.animationNodes)
						elseif v233_.controlDirection < 0 then
							if not g_soundManager:getIsSamplePlaying(v233_.samples.releaseRope) then
								g_soundManager:playSample(v233_.samples.releaseRope)
								g_soundManager:stopSample(v233_.samples.pullRope)
							end
							g_animationManager:startAnimations(v233_.animationNodes)
						end
					end
					self:raiseDirtyFlags(v232_.dirtyFlag)
					self:raiseDirtyFlags(v232_.ropeDirtyFlag)
					return
				end
			else
				v233_.controlInputSent = direction
				self:raiseDirtyFlags(v232_.dirtyFlag)
			end
		end
	end
end

-- Local values: spec, i, rope
function Winch:onWinchPlayerTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	local v241_ = self.spec_winch
	if (not v241_.isAttachable or self:getAttacherVehicle() ~= nil) and ((onEnter or onLeave) and (g_localPlayer ~= nil and otherId == g_localPlayer.rootNode)) then
		for v242_ = 1, #v241_.ropes do
			local v243_ = v241_.ropes[v242_]
			if v243_.triggerNode == triggerId then
				if onEnter then
					v243_.isPlayerInRange = true
					g_currentMission.activatableObjectsSystem:addActivatable(v243_.attachTreeActivatable)
					return
				end
				v243_.isPlayerInRange = false
				if not v243_.isAttachModeActive then
					g_currentMission.activatableObjectsSystem:removeActivatable(v243_.attachTreeActivatable)
					return
				end
				break
			end
		end
	end
end

-- Local values: spec, i, rope, j, attachData, centerX, centerY, centerZ, upX, upY, upZ, radius, distanceToStart
function Winch:onWinchTreeRaycastCallback(hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	local v251_ = self.spec_winch
	if hitObjectId ~= 0 and (getHasClassId(hitObjectId, ClassIds.SHAPE) and getSplitType(hitObjectId) ~= 0) then
		if isLast then
			v251_.treeRaycast.hasStarted = false
			if getRigidBodyType(shapeId) == RigidBodyType.STATIC and not v251_.treeRaycast.isFirstAttachment then
				v251_.treeRaycast.lastValidTree = nil
				return false
			end
			for v252_ = 1, #v251_.ropes do
				local v253_ = v251_.ropes[v252_]
				for v254_ = 1, #v253_.attachedTrees do
					if v253_.attachedTrees[v254_].treeId == hitObjectId then
						v251_.treeRaycast.lastValidTree = nil
						return false
					end
				end
			end
			local v255_, v256_, v257_, v258_, v259_, v260_, v261_ = SplitShapeUtil.getTreeOffsetPosition(hitObjectId, x, y, z, 4, 0.15)
			if v255_ == nil then
				v251_.treeRaycast.lastValidTree = nil
			else
				if MathUtil.vector3Length(v251_.treeRaycast.startPos[1] - x, v251_.treeRaycast.startPos[2] - y, v251_.treeRaycast.startPos[3] - z) > v251_.treeRaycast.maxDistance then
					v251_.treeRaycast.lastInValidTree = hitObjectId
					v251_.treeRaycast.lastValidTree = nil
				else
					v251_.treeRaycast.lastValidTree = hitObjectId
					v251_.treeRaycast.lastInValidTree = nil
				end
				v251_.treeRaycast.treeTargetPos[1] = x
				v251_.treeRaycast.treeTargetPos[2] = y
				v251_.treeRaycast.treeTargetPos[3] = z
				v251_.treeRaycast.treeCenterPos[1] = v255_
				v251_.treeRaycast.treeCenterPos[2] = v256_
				v251_.treeRaycast.treeCenterPos[3] = v257_
				v251_.treeRaycast.treeUp[1] = v258_
				v251_.treeRaycast.treeUp[2] = v259_
				v251_.treeRaycast.treeUp[3] = v260_
				v251_.treeRaycast.treeRadius = v261_
				self:raiseActive()
			end
		end
		return false
	end
	if isLast then
		v251_.treeRaycast.hasStarted = false
		v251_.treeRaycast.lastValidTree = nil
		v251_.treeRaycast.lastInValidTree = nil
	end
end

-- Local values: spec, i, rope, j, attachData
function Winch:onWinchTreeShapeCut(oldShape, shape)
	if self.isServer then
		local v264_ = self.spec_winch
		for v265_ = 1, #v264_.ropes do
			local v266_ = v264_.ropes[v265_]
			for v267_ = 1, #v266_.attachedTrees do
				if v266_.attachedTrees[v267_].treeId == oldShape then
					self:detachTreeFromWinch()
					break
				end
			end
		end
	end
end

-- Local values: spec, i, rope, j, attachData
function Winch:onWinchTreeShapeMounted(shape, mountVehicle)
	if mountVehicle ~= self and self.isServer then
		local v271_ = self.spec_winch
		for v272_ = 1, #v271_.ropes do
			local v273_ = v271_.ropes[v272_]
			for v274_ = 1, #v273_.attachedTrees do
				if v273_.attachedTrees[v274_].treeId == shape then
					self:detachTreeFromWinch()
					break
				end
			end
		end
	end
end

-- Local values: spec, _, rope
function Winch:onPlayerPreTeleport(player)
	if player == g_localPlayer then
		local v277_ = self.spec_winch
		for _, v278_ in ipairs(v277_.ropes) do
			v278_.setupRope:destroy()
		end
	end
end

function Winch:loadExtraDependentParts(superFunc, xmlFile, baseName, entry)
	if not superFunc(self, xmlFile, baseName, entry) then
		return false
	end
	entry.winchRopeIndices = xmlFile:getValue(baseName .. ".winch#ropeIndices", nil, true)
	return true
end

-- Local values: i, index, rope
function Winch:updateExtraDependentParts(superFunc, part, dt)
	superFunc(self, part, dt)
	if part.winchRopeIndices ~= nil then
		for v288_ = 1, #part.winchRopeIndices do
			local v289_ = part.winchRopeIndices[v288_]
			local v290_ = self.spec_winch.ropes[v289_]
			if v290_ ~= nil and v290_.mainRope ~= nil then
				v290_.mainRope:updateAnchorNodes()
			end
		end
	end
end

-- Local values: spec, i
function Winch:getDoConsumePtoPower(superFunc)
	local v293_ = self.spec_winch
	if v293_.hasRopes then
		for v294_ = 1, #v293_.ropes do
			if #v293_.ropes[v294_].attachedTrees > 0 then
				return true
			end
		end
	end
	return superFunc(self)
end

-- Local values: value, count, loadPercentage, spec, i
function Winch:getConsumingLoad(superFunc)
	local v297_, v298_ = superFunc(self)
	local v299_ = 0
	local v300_ = self.spec_winch
	if v300_.hasRopes then
		for v301_ = 1, #v300_.ropes do
			if v300_.ropes[v301_].lastControlTimer > 0 then
				v299_ = 1
			end
		end
	end
	return v297_ + v299_, v298_ + 1
end

-- Local values: spec, i
function Winch:getIsPowerTakeOffActive(superFunc)
	local v304_ = self.spec_winch
	if v304_.hasRopes then
		for v305_ = 1, #v304_.ropes do
			if #v304_.ropes[v305_].attachedTrees > 0 then
				return true
			end
		end
	end
	return superFunc(self)
end

-- Local values: _, rope, attachData
function Winch:addToPhysics(superFunc)
	if not superFunc(self) then
		return false
	end
	for _, v308_ in ipairs(self.spec_winch.ropes) do
		if #v308_.attachedTrees > 0 then
			local v309_ = v308_.attachedTrees[1]
			v308_.mainRope:create(v309_.treeId, v309_.activeHookData:getRopeTarget(), nil, nil, true, true)
		end
	end
	return true
end

-- Local values: _, rope
function Winch:removeFromPhysics(superFunc)
	for _, v312_ in ipairs(self.spec_winch.ropes) do
		if #v312_.attachedTrees > 0 then
			v312_.mainRope:destroy()
		end
	end
	return superFunc(self)
end

-- Local values: maxTreeMass, massByConfig
function Winch.loadSpecValueMaxMass(xmlFile, customEnvironment, baseDir)
	local v_u_314_ = 0
	xmlFile:iterate("vehicle.winch.rope", function(_, p315_)
		-- upvalues: (ref) v_u_314_, (copy) xmlFile
		local v316_ = xmlFile:getValue(p315_ .. "#maxTreeMass", 0)
		local v317_ = v_u_314_
		v_u_314_ = math.max(v316_, v317_)
	end)
	local v_u_318_ = {}
	xmlFile:iterate("vehicle.winch.winchConfigurations.winchConfiguration", function(p319_, p320_)
		-- upvalues: (copy) xmlFile, (copy) v_u_318_
		local v_u_321_ = 0
		xmlFile:iterate(p320_ .. ".rope", function(_, p322_)
			-- upvalues: (ref) v_u_321_, (ref) xmlFile
			local v323_ = xmlFile:getValue(p322_ .. "#maxTreeMass", 0)
			local v324_ = v_u_321_
			v_u_321_ = math.max(v323_, v324_)
		end)
		v_u_318_[p319_] = v_u_321_
	end)
	return {
		["maxTreeMass"] = v_u_314_,
		["massByConfig"] = v_u_318_
	}
end

-- Local values: maxTreeMass, configId, _, length, str
function Winch.getSpecValueMaxMass(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	if storeItem.specs.winchMaxMass ~= nil then
		local v329_ = storeItem.specs.winchMaxMass.maxTreeMass
		if configurations == nil then
			for _, v330_ in pairs(storeItem.specs.winchMaxMass.massByConfig) do
				v329_ = math.max(v330_, v329_)
			end
		else
			local v331_ = configurations.winch
			v329_ = storeItem.specs.winchMaxMass.massByConfig[v331_] or v329_
		end
		local v332_ = string.format("%.1f%s", v329_, g_i18n:getText("unit_tonsShort"))
		if returnValues and returnRange then
			return v329_, v329_, v332_
		end
		if returnValues then
			return v329_, v332_
		end
		if v329_ ~= 0 then
			return v332_
		end
	end
end
