LogGrab = {}
LogGrab.GRAB_INDEX_NUM_BITS = 3
source("dataS/scripts/vehicles/specializations/events/LogGrabClawStateEvent.lua")

function LogGrab.prerequisitesPresent(specializations)
	return true
end
function LogGrab.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("logGrab", g_i18n:getText("shop_configuration"), "logGrab", VehicleConfigurationItem)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("LogGrab")
	LogGrab.registerLogGrabXMLPaths(v1_, "vehicle.logGrab.grab(?)")
	LogGrab.registerLogGrabXMLPaths(v1_, "vehicle.logGrab.logGrabConfigurations.logGrabConfiguration(?).grab(?)")
	v1_:setXMLSpecializationType()
	Vehicle.xmlSchemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).logGrab.grab(?)#state", "Grab claw state")
end

function LogGrab.registerLogGrabXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#jointNode", "Joint node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#jointRoot", "Joint root node")
	schema:register(XMLValueType.BOOL, basePath .. "#lockAllAxis", "Lock all axis", false)
	schema:register(XMLValueType.BOOL, basePath .. "#limitYAxis", "Limit joint y axis movement (only allows movement up, but not down)", false)
	schema:register(XMLValueType.ANGLE, basePath .. "#rotLimit", "Defines the rotation limit on all axis", 10)
	schema:register(XMLValueType.BOOL, basePath .. "#unmountOnTreeCut", "Unmount trees while the wood harvester cuts the tree (only if the vehicle is a wood harvester as well)", false)
	schema:register(XMLValueType.FLOAT, basePath .. "#foldMinLimit", "Min. folding time to attach trees", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#foldMaxLimit", "Max. folding time to attach trees", 1)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".trigger#node", "Trigger node")
	schema:register(XMLValueType.INT, basePath .. ".claw(?)#componentJointIndex", "Component joint index")
	schema:register(XMLValueType.FLOAT, basePath .. ".claw(?)#dampingFactor", "Damping factor", 20)
	schema:register(XMLValueType.INT, basePath .. ".claw(?)#axis", "Grab axis", 1)
	schema:register(XMLValueType.ANGLE, basePath .. ".claw(?)#rotationOffsetThreshold", "Rotation offset threshold", 10)
	schema:register(XMLValueType.BOOL, basePath .. ".claw(?)#rotationOffsetInverted", "Invert threshold", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".claw(?)#rotationOffsetTime", "Rotation offset time until mount", 1000)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".claw(?).movingTool(?)#node", "Node of moving tool to block while limit is exceeded")
	schema:register(XMLValueType.FLOAT, basePath .. ".claw(?).movingTool(?)#direction", "Direction to block the moving tool", 1)
	schema:register(XMLValueType.INT, basePath .. ".claw(?).movingTool(?)#closeDirection", "Direction in which the grab is closed (if defined the trees are locked while fully closed)")
	schema:register(XMLValueType.STRING, basePath .. ".clawAnimation#name", "Claw animation name")
	schema:register(XMLValueType.FLOAT, basePath .. ".clawAnimation#speedScale", "Animation speed scale", 1)
	schema:register(XMLValueType.BOOL, basePath .. ".clawAnimation#initialState", "Initial state of the grab (true: closed, false: open)", true)
	schema:register(XMLValueType.FLOAT, basePath .. ".clawAnimation#lockTime", "Animation time when trees are locked", 1)
	schema:register(XMLValueType.STRING, basePath .. ".clawAnimation#inputAction", "Input action to toggle animation", "IMPLEMENT_EXTRA2")
	schema:register(XMLValueType.INT, basePath .. ".clawAnimation#controlGroupIndex", "Control group that needs to be active")
	schema:register(XMLValueType.L10N_STRING, basePath .. ".clawAnimation#textPos", "Input text to open the claw", "action_foldBenchPos")
	schema:register(XMLValueType.L10N_STRING, basePath .. ".clawAnimation#textNeg", "Input text to close the claw", "action_foldBenchNeg")
	schema:register(XMLValueType.FLOAT, basePath .. ".clawAnimation#foldMinLimit", "Min. folding time to control claw", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".clawAnimation#foldMaxLimit", "Max. folding time to control claw", 1)
	schema:register(XMLValueType.BOOL, basePath .. ".clawAnimation#openDuringFolding", "Claw will be opened during folding", false)
	schema:register(XMLValueType.BOOL, basePath .. ".clawAnimation#closeDuringFolding", "Claw will be closed during folding", false)
	schema:register(XMLValueType.STRING, basePath .. ".lockAnimation#name", "Lock animation played while tree joints are created and revered while joints are removed")
	schema:register(XMLValueType.FLOAT, basePath .. ".lockAnimation#speedScale", "Animation speed scale", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".lockAnimation#unlockSpeedScale", "Animation speed scale while trees are unlocked", "negative #speedScale")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".treeDetection#node", "Tree detection node")
	schema:register(XMLValueType.FLOAT, basePath .. ".treeDetection#sizeY", "Tree detection node size y", 2)
	schema:register(XMLValueType.FLOAT, basePath .. ".treeDetection#sizeZ", "Tree detection node size z", 2)
	schema:register(XMLValueType.INT, basePath .. ".componentJointLimit(?)#jointIndex", "Index of component joint to change", 1)
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".componentJointLimit(?)#limitActive", "Limit when tree is mounted")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".componentJointLimit(?)#limitInactive", "Limit when no tree is mounted")
	schema:register(XMLValueType.INT, basePath .. ".componentJointMassSetting(?)#jointIndex", "Index of component joint to change", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".componentJointMassSetting(?)#minMass", "Mass of mounted trees to use min defined value (t)", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".componentJointMassSetting(?)#maxMass", "Mass of mounted trees to use max defined value (t)", 1)
	schema:register(XMLValueType.VECTOR_3, basePath .. ".componentJointMassSetting(?)#minMaxRotDriveForce", "Max. rot drive force applied when the trees weight #minMass")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".componentJointMassSetting(?)#maxMaxRotDriveForce", "Max. rot drive force applied when the trees weight #maxMass")
end

function LogGrab.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onLogGrabMountedTreesChanged")
end

function LogGrab.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadLogGrabFromXML", LogGrab.loadLogGrabFromXML)
	SpecializationUtil.registerFunction(vehicleType, "updateLogGrabClawState", LogGrab.updateLogGrabClawState)
	SpecializationUtil.registerFunction(vehicleType, "getGrabCanMountSplitShape", LogGrab.getGrabCanMountSplitShape)
	SpecializationUtil.registerFunction(vehicleType, "mountSplitShape", LogGrab.mountSplitShape)
	SpecializationUtil.registerFunction(vehicleType, "unmountSplitShape", LogGrab.unmountSplitShape)
	SpecializationUtil.registerFunction(vehicleType, "getIsLogGrabClawStateChangeAllowed", LogGrab.getIsLogGrabClawStateChangeAllowed)
	SpecializationUtil.registerFunction(vehicleType, "setLogGrabClawState", LogGrab.setLogGrabClawState)
end

function LogGrab.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setComponentJointFrame", LogGrab.setComponentJointFrame)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getMovingToolMoveValue", LogGrab.getMovingToolMoveValue)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "onDelimbTree", LogGrab.onDelimbTree)
end

function LogGrab.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", LogGrab)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", LogGrab)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", LogGrab)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", LogGrab)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", LogGrab)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", LogGrab)
	SpecializationUtil.registerEventListener(vehicleType, "onCutTree", LogGrab)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", LogGrab)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", LogGrab)
	SpecializationUtil.registerEventListener(vehicleType, "onLogGrabMountedTreesChanged", LogGrab)
	SpecializationUtil.registerEventListener(vehicleType, "onFoldStateChanged", LogGrab)
	SpecializationUtil.registerEventListener(vehicleType, "onFoldTimeChanged", LogGrab)
end

-- Local values: spec, configurationId, configKey
function LogGrab:onLoad(savegame)
	local v_u_9_ = self.spec_logGrab
	v_u_9_.grabs = {}
	if self.xmlFile:hasProperty("vehicle.logGrab") then
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.logGrab.trigger#node", "vehicle.logGrab.grab.trigger#node")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.logGrab#jointNode", "vehicle.logGrab.grab#jointNode")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.logGrab#jointRoot", "vehicle.logGrab.grab#jointRoot")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.logGrab#lockAllAxis", "vehicle.logGrab.grab#lockAllAxis")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.logGrab.grab#componentJoint", "vehicle.logGrab.grab.claw#componentJointIndex")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.logGrab.grab#dampingFactor", "vehicle.logGrab.grab.claw#dampingFactor")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.logGrab.grab#axis", "vehicle.logGrab.grab.claw#axis")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.logGrab.grab#rotationOffsetThreshold", "vehicle.logGrab.grab.claw#rotationOffsetThreshold")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.logGrab.grab#rotationOffsetTime", "vehicle.logGrab.grab.claw#rotationOffsetTime")
		local v10_ = self.configurations.logGrab or 1
		local v11_ = string.format("vehicle.logGrab.logGrabConfigurations.logGrabConfiguration(%d)", v10_ - 1)
		self.xmlFile:iterate(v11_ .. ".grab", function(_, p12_)
			-- upvalues: (copy) self, (copy) v_u_9_
			local v13_ = {}
			if self:loadLogGrabFromXML(self.xmlFile, p12_, v13_) then
				local v14_ = v_u_9_.grabs
				table.insert(v14_, v13_)
			end
		end)
		self.xmlFile:iterate("vehicle.logGrab.grab", function(_, p15_)
			-- upvalues: (copy) self, (copy) v_u_9_
			local v16_ = {}
			if self:loadLogGrabFromXML(self.xmlFile, p15_, v16_) then
				local v17_ = v_u_9_.grabs
				table.insert(v17_, v16_)
			end
		end)
	end
	if #v_u_9_.grabs == 0 then
		SpecializationUtil.removeEventListener(self, "onPostLoad", LogGrab)
		SpecializationUtil.removeEventListener(self, "onDelete", LogGrab)
		SpecializationUtil.removeEventListener(self, "onReadStream", LogGrab)
		SpecializationUtil.removeEventListener(self, "onWriteStream", LogGrab)
		SpecializationUtil.removeEventListener(self, "onUpdateTick", LogGrab)
		SpecializationUtil.removeEventListener(self, "onCutTree", LogGrab)
		SpecializationUtil.removeEventListener(self, "onTurnedOn", LogGrab)
		SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", LogGrab)
		SpecializationUtil.removeEventListener(self, "onLogGrabMountedTreesChanged", LogGrab)
		SpecializationUtil.removeEventListener(self, "onFoldStateChanged", LogGrab)
		SpecializationUtil.removeEventListener(self, "onFoldTimeChanged", LogGrab)
	end
end

-- Local values: spec, i, grab, state, grabKey, j, clawData, ti, movingToolData
function LogGrab:onPostLoad(savegame)
	local v20_ = self.spec_logGrab
	for v21_ = 1, #v20_.grabs do
		local v22_ = v20_.grabs[v21_]
		if v22_.clawAnimation.name ~= nil then
			local v23_ = v22_.clawAnimation.initialState
			if savegame ~= nil and not savegame.resetVehicles then
				local v24_ = string.format("%s.logGrab.grab(%d)", savegame.key, v21_ - 1)
				v23_ = savegame.xmlFile:getValue(v24_ .. "#state", v23_)
			end
			if v23_ then
				v22_.clawAnimation.state = true
				self:playAnimation(v22_.clawAnimation.name, 1, 0, true)
				AnimatedVehicle.updateAnimationByName(self, v22_.clawAnimation.name, 9999999, true)
			end
		end
		for v25_ = 1, #v22_.claws do
			local v26_ = v22_.claws[v25_]
			for v27_ = #v26_.movingTools, 1, -1 do
				local v28_ = v26_.movingTools[v27_]
				v28_.movingTool = self:getMovingToolByNode(v28_.node)
				if v28_.movingTool == nil then
					table.remove(v26_.movingTools, v27_)
				end
			end
		end
	end
end

-- Local values: spec, i, grab
function LogGrab:onDelete()
	local v30_ = self.spec_logGrab
	if v30_.grabs ~= nil then
		for v31_ = 1, #v30_.grabs do
			local v32_ = v30_.grabs[v31_]
			if v32_.callbackId ~= nil then
				removeTrigger(v32_.triggerNode, v32_.callbackId)
			end
		end
	end
end

-- Local values: spec, i, grab, grabKey
function LogGrab:saveToXMLFile(xmlFile, key, usedModNames)
	local v36_ = self.spec_logGrab
	for v37_ = 1, #v36_.grabs do
		local v38_ = v36_.grabs[v37_]
		if v38_.clawAnimation.name ~= nil then
			xmlFile:setValue((key .. string.format(".grab(%d)", v37_ - 1)) .. "#state", v38_.clawAnimation.state)
		end
	end
end

-- Local values: spec, i, grab, state
function LogGrab:onReadStream(streamId, connection)
	local v41_ = self.spec_logGrab
	for v42_ = 1, #v41_.grabs do
		if v41_.grabs[v42_].clawAnimation.name ~= nil then
			self:setLogGrabClawState(v42_, streamReadBool(streamId), true)
		end
	end
end

-- Local values: spec, i, grab
function LogGrab:onWriteStream(streamId, connection)
	local v45_ = self.spec_logGrab
	for v46_ = 1, #v45_.grabs do
		local v47_ = v45_.grabs[v46_]
		if v47_.clawAnimation.name ~= nil then
			streamWriteBool(streamId, v47_.clawAnimation.state)
		end
	end
end

-- Local values: spec, i, grab, isGrabClosed, triggerEmpty, j, claw, clawState, clawsClosed, j, shape, _, shape, _, jointIndex, jointTransform, j, claw, componentJoint, axis, shapeId, shapeData, j, claw, componentJoint, state, clawAnimationRunning, isActive, j, componentJointLimit, alpha, x, y, z
function LogGrab:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isServer then
		local v50_ = self.spec_logGrab
		for v51_ = 1, #v50_.grabs do
			local v52_ = v50_.grabs[v51_]
			local v53_ = true
			if v52_.clawAnimation.name == nil then
				local v54_
				if next(v52_.dynamicMountedShapes) == nil then
					v54_ = next(v52_.pendingDynamicMountShapes) == nil
				else
					v54_ = false
				end
				for v55_ = 1, #v52_.claws do
					local v56_ = v52_.claws[v55_]
					local v57_ = self:updateLogGrabClawState(v56_, dt, nil, v54_)
					if g_time - v52_.lastGrabChangeTime > 2500 then
						v57_ = v56_.lastClawState
					end
					if v52_.unmountOnTreeCut and (self.spec_woodHarvester ~= nil and self.spec_woodHarvester.attachedSplitShape ~= nil) then
						v57_ = false
					end
					if not v57_ then
						v53_ = false
					end
					v56_.lastClawState = v57_
				end
			elseif v52_.clawAnimation.state then
				if self:getIsAnimationPlaying(v52_.clawAnimation.name) then
					local v58_ = true
					for v59_ = 1, #v52_.claws do
						if not self:updateLogGrabClawState(v52_.claws[v59_], dt, true) then
							v58_ = false
						end
					end
					if v58_ then
						self:stopAnimation(v52_.clawAnimation.name)
					end
				end
				if self:getIsAnimationPlaying(v52_.clawAnimation.name) and self:getAnimationTime(v52_.clawAnimation.name) < v52_.clawAnimation.lockTime then
					v53_ = false
				end
			elseif self:getAnimationTime(v52_.clawAnimation.name) < v52_.clawAnimation.lockTime then
				v53_ = false
			end
			for v60_, _ in pairs(v52_.pendingDynamicMountShapes) do
				if not entityExists(v60_) then
					v52_.pendingDynamicMountShapes[v60_] = nil
				end
			end
			if v53_ then
				for v61_, _ in pairs(v52_.pendingDynamicMountShapes) do
					if v52_.dynamicMountedShapes[v61_] == nil and self:getGrabCanMountSplitShape(v52_, v61_) then
						local v62_, v63_ = self:mountSplitShape(v52_, v61_)
						if v62_ ~= nil then
							v52_.dynamicMountedShapes[v61_] = {
								["jointIndex"] = v62_,
								["jointTransform"] = v63_
							}
							v52_.pendingDynamicMountShapes[v61_] = nil
						end
					end
				end
				if not v52_.jointLimitsOpen and next(v52_.dynamicMountedShapes) ~= nil then
					v52_.jointLimitsOpen = true
					for v64_ = 1, #v52_.claws do
						local v65_ = v52_.claws[v64_]
						local v66_ = self.componentJoints[v65_.componentJoint]
						if v66_ ~= nil then
							for v67_ = 1, 3 do
								setJointRotationLimitSpring(v66_.jointIndex, v67_ - 1, v66_.rotLimitSpring[v67_], v66_.rotLimitDamping[v67_] * v65_.dampingFactor)
							end
						end
					end
				end
			else
				for v68_, v69_ in pairs(v52_.dynamicMountedShapes) do
					self:unmountSplitShape(v52_, v68_, v69_.jointIndex, v69_.jointTransform, false)
				end
				if v52_.jointLimitsOpen then
					v52_.jointLimitsOpen = false
					for v70_ = 1, #v52_.claws do
						local v71_ = v52_.claws[v70_]
						local v72_ = self.componentJoints[v71_.componentJoint]
						if v72_ ~= nil then
							setJointRotationLimitSpring(v72_.jointIndex, 0, v72_.rotLimitSpring[1], v72_.rotLimitDamping[1])
							setJointRotationLimitSpring(v72_.jointIndex, 1, v72_.rotLimitSpring[2], v72_.rotLimitDamping[2])
							setJointRotationLimitSpring(v72_.jointIndex, 2, v72_.rotLimitSpring[3], v72_.rotLimitDamping[3])
						end
					end
				end
			end
			if v52_.lockAnimation.name ~= nil then
				if v53_ then
					v53_ = next(v52_.dynamicMountedShapes) ~= nil
				end
				if v53_ ~= v52_.lockAnimation.state then
					v52_.lockAnimation.state = v53_
					if v53_ then
						self:playAnimation(v52_.lockAnimation.name, v52_.lockAnimation.speedScale, self:getAnimationTime(v52_.lockAnimation.name))
					else
						self:playAnimation(v52_.lockAnimation.name, v52_.lockAnimation.unlockSpeedScale, self:getAnimationTime(v52_.lockAnimation.name))
					end
				end
			end
			local v73_
			if v52_.clawAnimation.name == nil then
				v73_ = false
			else
				v73_ = self:getIsAnimationPlaying(v52_.clawAnimation.name)
			end
			if v52_.componentLimitsDirty or v73_ then
				local v74_ = next(v52_.dynamicMountedShapes) ~= nil
				for v75_ = 1, #v52_.componentJointLimits do
					local v76_ = v52_.componentJointLimits[v75_]
					if v76_.isActive ~= v74_ or v73_ then
						v76_.isActive = v74_
						local v77_ = next(v52_.dynamicMountedShapes) == nil and 1 or 0
						if v52_.clawAnimation.name ~= nil and (next(v52_.dynamicMountedShapes) ~= nil or next(v52_.pendingDynamicMountShapes)) then
							v77_ = 1 - self:getAnimationTime(v52_.clawAnimation.name)
						end
						local v78_, v79_, v80_ = MathUtil.vector3Lerp(v76_.limitActive[1], v76_.limitActive[2], v76_.limitActive[3], v76_.limitInactive[1], v76_.limitInactive[2], v76_.limitInactive[3], v77_)
						self:setComponentJointRotLimit(v76_.joint, 0, -v78_, v78_)
						self:setComponentJointRotLimit(v76_.joint, 1, -v79_, v79_)
						self:setComponentJointRotLimit(v76_.joint, 2, -v80_, v80_)
					end
				end
				v52_.componentLimitsDirty = false
			end
		end
	end
end

-- Local values: collisionMask
function LogGrab:loadLogGrabFromXML(xmlFile, key, logGrab)
	logGrab.claws = {}
	xmlFile:iterate(key .. ".claw", function(_, p85_)
		-- upvalues: (copy) self, (copy) xmlFile, (copy) logGrab
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, p85_ .. "#componentJoint", p85_ .. "#componentJointIndex")
		local v_u_86_ = {
			["componentJoint"] = xmlFile:getValue(p85_ .. "#componentJointIndex")
		}
		if v_u_86_.componentJoint == nil then
			Logging.xmlWarning(xmlFile, "Missing claw componentJoint in xml. \'%s\'", p85_)
		else
			v_u_86_.dampingFactor = xmlFile:getValue(p85_ .. "#dampingFactor", 20)
			v_u_86_.axis = xmlFile:getValue(p85_ .. "#axis", 1)
			v_u_86_.direction = { 0, 0, 0 }
			v_u_86_.direction[v_u_86_.axis] = 1
			local v87_ = self.componentJoints[v_u_86_.componentJoint]
			if v87_ == nil then
				Logging.xmlWarning(xmlFile, "Unable to load claw componentJoint from xml. \'%s\'", p85_)
				return false
			end
			v_u_86_.jointActor0 = v87_.jointNode
			v_u_86_.jointActor1 = v87_.jointNodeActor1
			if v87_.jointNodeActor1 == v87_.jointNode then
				local v88_ = createTransformGroup("jointNodeActor1Reference")
				local v89_ = self.components[v87_.componentIndices[2]]
				link(v89_.node, v88_)
				setWorldTranslation(v88_, getWorldTranslation(v87_.jointNode))
				setWorldRotation(v88_, getWorldRotation(v87_.jointNode))
				v_u_86_.jointActor1 = v88_
			end
			v_u_86_.rotationOffsetThreshold = xmlFile:getValue(p85_ .. "#rotationOffsetThreshold", 10)
			v_u_86_.rotationOffsetInverted = xmlFile:getValue(p85_ .. "#rotationOffsetInverted", false)
			v_u_86_.rotationOffsetTime = xmlFile:getValue(p85_ .. "#rotationOffsetTime", 1000)
			v_u_86_.rotationOffsetTimer = 0
			v_u_86_.rotationChangedTimer = 0
			v_u_86_.currentOffset = 0
			v_u_86_.lastClawState = false
			v_u_86_.movingTools = {}
			xmlFile:iterate(p85_ .. ".movingTool", function(_, p90_)
				-- upvalues: (ref) xmlFile, (ref) self, (copy) v_u_86_
				local v91_ = {
					["node"] = xmlFile:getValue(p90_ .. "#node", nil, self.components, self.i3dMappings)
				}
				if v91_.node == nil then
					Logging.xmlWarning(xmlFile, "Unable to load movingTool from xml. \'%s\'", p90_)
				else
					v91_.direction = xmlFile:getValue(p90_ .. "#direction", 1)
					v91_.closeDirection = xmlFile:getValue(p90_ .. "#closeDirection")
					local v92_ = v_u_86_.movingTools
					table.insert(v92_, v91_)
				end
			end)
			local v93_ = logGrab.claws
			table.insert(v93_, v_u_86_)
		end
	end)
	logGrab.clawAnimation = {}
	logGrab.clawAnimation.state = false
	logGrab.clawAnimation.name = xmlFile:getValue(key .. ".clawAnimation#name")
	logGrab.clawAnimation.speedScale = xmlFile:getValue(key .. ".clawAnimation#speedScale", 1)
	logGrab.clawAnimation.initialState = xmlFile:getValue(key .. ".clawAnimation#initialState", true)
	logGrab.clawAnimation.lockTime = xmlFile:getValue(key .. ".clawAnimation#lockTime", 1)
	logGrab.clawAnimation.inputAction = InputAction[xmlFile:getValue(key .. ".clawAnimation#inputAction", "IMPLEMENT_EXTRA2")] or InputAction.IMPLEMENT_EXTRA2
	logGrab.clawAnimation.controlGroupIndex = xmlFile:getValue(key .. ".clawAnimation#controlGroupIndex")
	logGrab.clawAnimation.textPos = xmlFile:getValue(key .. ".clawAnimation#textPos", "action_foldBenchPos", self.customEnvironment, false)
	logGrab.clawAnimation.textNeg = xmlFile:getValue(key .. ".clawAnimation#textNeg", "action_foldBenchNeg", self.customEnvironment, false)
	logGrab.clawAnimation.foldMinLimit = xmlFile:getValue(key .. ".clawAnimation#foldMinLimit", 0)
	logGrab.clawAnimation.foldMaxLimit = xmlFile:getValue(key .. ".clawAnimation#foldMaxLimit", 0)
	logGrab.clawAnimation.openDuringFolding = xmlFile:getValue(key .. ".clawAnimation#openDuringFolding", false)
	logGrab.clawAnimation.closeDuringFolding = xmlFile:getValue(key .. ".clawAnimation#closeDuringFolding", false)
	logGrab.lockAnimation = {}
	logGrab.lockAnimation.state = false
	logGrab.lockAnimation.name = xmlFile:getValue(key .. ".lockAnimation#name")
	logGrab.lockAnimation.speedScale = xmlFile:getValue(key .. ".lockAnimation#speedScale", 1)
	logGrab.lockAnimation.unlockSpeedScale = xmlFile:getValue(key .. ".lockAnimation#unlockSpeedScale", -logGrab.lockAnimation.speedScale)
	logGrab.jointNode = xmlFile:getValue(key .. "#jointNode", nil, self.components, self.i3dMappings)
	logGrab.jointRoot = xmlFile:getValue(key .. "#jointRoot", nil, self.components, self.i3dMappings)
	logGrab.lockAllAxis = xmlFile:getValue(key .. "#lockAllAxis", false)
	logGrab.limitYAxis = xmlFile:getValue(key .. "#limitYAxis", false)
	logGrab.rotLimit = xmlFile:getValue(key .. "#rotLimit", 10)
	logGrab.unmountOnTreeCut = xmlFile:getValue(key .. "#unmountOnTreeCut", false)
	logGrab.foldMinLimit = xmlFile:getValue(key .. "#foldMinLimit", 0)
	logGrab.foldMaxLimit = xmlFile:getValue(key .. "#foldMaxLimit", 1)
	logGrab.triggerNode = xmlFile:getValue(key .. ".trigger#node", nil, self.components, self.i3dMappings)
	if logGrab.triggerNode == nil then
		Logging.xmlWarning(xmlFile, "Missing grab trigger in \'%s\'", key)
		return false
	end
	if getCollisionFilterMask(logGrab.triggerNode) == CollisionFlag.TREE then
		logGrab.callbackId = addTrigger(logGrab.triggerNode, "logGrabTriggerCallback", self, false, LogGrab.logGrabTriggerCallback)
		logGrab.pendingDynamicMountShapes = {}
		logGrab.dynamicMountedShapes = {}
		logGrab.jointLimitsOpen = false
		logGrab.treeDetectionNode = xmlFile:getValue(key .. ".treeDetection#node", nil, self.components, self.i3dMappings)
		if logGrab.treeDetectionNode == nil then
			Logging.xmlWarning(xmlFile, "Missing tree detection node in \'%s\'", key)
			return false
		end
		logGrab.treeDetectionNodeSizeY = xmlFile:getValue(key .. ".treeDetection#sizeY", 2)
		logGrab.treeDetectionNodeSizeZ = xmlFile:getValue(key .. ".treeDetection#sizeZ", 2)
		logGrab.componentJointLimits = {}
		xmlFile:iterate(key .. ".componentJointLimit", function(_, p94_)
			-- upvalues: (copy) xmlFile, (copy) self, (copy) logGrab
			local v95_ = {
				["jointIndex"] = xmlFile:getValue(p94_ .. "#jointIndex")
			}
			if v95_.jointIndex ~= nil then
				v95_.joint = self.componentJoints[v95_.jointIndex]
				v95_.limitActive = xmlFile:getValue(p94_ .. "#limitActive", nil, true)
				v95_.limitInactive = xmlFile:getValue(p94_ .. "#limitInactive", nil, true)
				if v95_.joint ~= nil and (v95_.limitActive ~= nil and v95_.limitInactive ~= nil) then
					v95_.isActive = false
					local v96_ = logGrab.componentJointLimits
					table.insert(v96_, v95_)
				end
			end
		end)
		logGrab.componentJointMassSettings = {}
		xmlFile:iterate(key .. ".componentJointMassSetting", function(_, p97_)
			-- upvalues: (copy) xmlFile, (copy) self, (copy) logGrab
			local v98_ = {
				["jointIndex"] = xmlFile:getValue(p97_ .. "#jointIndex")
			}
			if v98_.jointIndex ~= nil then
				v98_.joint = self.componentJoints[v98_.jointIndex]
				v98_.minMass = xmlFile:getValue(p97_ .. "#minMass", 0)
				v98_.maxMass = xmlFile:getValue(p97_ .. "#maxMass", 1)
				v98_.minMaxRotDriveForce = xmlFile:getValue(p97_ .. "#minMaxRotDriveForce", nil, true)
				v98_.maxMaxRotDriveForce = xmlFile:getValue(p97_ .. "#maxMaxRotDriveForce", nil, true)
				v98_.maxRotDriveForce = { 0, 0, 0 }
				if v98_.joint ~= nil and (v98_.minMaxRotDriveForce ~= nil and v98_.maxMaxRotDriveForce ~= nil) then
					local v99_ = logGrab.componentJointMassSettings
					table.insert(v99_, v98_)
				end
			end
		end)
		logGrab.componentLimitsDirty = false
		logGrab.lastGrabChangeTime = -math.huge
		return true
	end
	Logging.xmlWarning(xmlFile, "LogGrab trigger \'%s\' has wrong collision mask, only the Tree bit is allowed!", getName(logGrab.triggerNode))
end
function LogGrab.updateLogGrabClawState()
	-- failed to decompile
end

-- Local values: spec, i
function LogGrab:onCutTree(radius, isNewTree)
	if self.isServer and (radius > 0 and isNewTree) then
		for v103_ = 1, #self.spec_logGrab.grabs do
			if self:getIsLogGrabClawStateChangeAllowed(v103_) then
				self:setLogGrabClawState(v103_, true)
			end
		end
	end
end

-- Local values: spec, i
function LogGrab:onTurnedOn()
	if self.isServer then
		for v105_ = 1, #self.spec_logGrab.grabs do
			if self:getIsLogGrabClawStateChangeAllowed(v105_) then
				self:setLogGrabClawState(v105_, false)
			end
		end
	end
end

-- Local values: spec, i
function LogGrab:onTurnedOff()
	if self.isServer then
		for v107_ = 1, #self.spec_logGrab.grabs do
			if self:getIsLogGrabClawStateChangeAllowed(v107_) then
				self:setLogGrabClawState(v107_, true)
			end
		end
	end
end

-- Local values: spec, i, grab, _, actionEventId
function LogGrab:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v110_ = self.spec_logGrab
		self:clearActionEventsTable(v110_.actionEvents)
		if isActiveForInputIgnoreSelection then
			for v111_ = 1, #v110_.grabs do
				local v112_ = v110_.grabs[v111_]
				if v112_.clawAnimation.name ~= nil and (v112_.clawAnimation.controlGroupIndex == nil or (self.spec_cylindered == nil or self.spec_cylindered.currentControlGroupIndex == v112_.clawAnimation.controlGroupIndex)) then
					local _, v113_ = self:addPoweredActionEvent(v110_.actionEvents, v112_.clawAnimation.inputAction, self, LogGrab.actionEventClawAnimation, false, true, false, true, v111_)
					g_inputBinding:setActionEventTextPriority(v113_, GS_PRIO_HIGH)
					LogGrab.updateActionEvents(self)
				end
			end
		end
	end
end

function LogGrab:actionEventClawAnimation(actionName, inputValue, callbackState, isAnalog)
	if self:getIsLogGrabClawStateChangeAllowed(callbackState) then
		self:setLogGrabClawState(callbackState, nil)
	end
end

-- Local values: spec, i, grab, actionEvent
function LogGrab:updateActionEvents()
	local v117_ = self.spec_logGrab
	for v118_ = 1, #v117_.grabs do
		local v119_ = v117_.grabs[v118_]
		local v120_ = v117_.actionEvents[v119_.clawAnimation.inputAction]
		if v120_ ~= nil then
			g_inputBinding:setActionEventText(v120_.actionEventId, v119_.clawAnimation.state and v119_.clawAnimation.textNeg or v119_.clawAnimation.textPos)
			g_inputBinding:setActionEventActive(v120_.actionEventId, self:getIsLogGrabClawStateChangeAllowed(v118_))
		end
	end
end

-- Local values: spec, i, grab, j, claw, componentJoint
function LogGrab:setComponentJointFrame(superFunc, jointDesc, anchorActor)
	superFunc(self, jointDesc, anchorActor)
	local v125_ = self.spec_logGrab
	for v126_ = 1, #v125_.grabs do
		local v127_ = v125_.grabs[v126_]
		for v128_ = 1, #v127_.claws do
			local v129_ = v127_.claws[v128_]
			if jointDesc == self.componentJoints[v129_.componentJoint] then
				v127_.lastGrabChangeTime = g_time
			end
		end
	end
end

-- Local values: move, spec, i, grab, j, claw, ti, movingToolData
function LogGrab:getMovingToolMoveValue(superFunc, movingTool)
	local v133_ = superFunc(self, movingTool)
	local v134_ = self.spec_logGrab
	for v135_ = 1, #v134_.grabs do
		local v136_ = v134_.grabs[v135_]
		for v137_ = 1, #v136_.claws do
			local v138_ = v136_.claws[v137_]
			for v139_ = 1, #v138_.movingTools do
				local v140_ = v138_.movingTools[v139_]
				if v140_.movingTool == movingTool then
					v140_.lastMoveValue = v133_
					if v138_.currentOffset > v138_.rotationOffsetThreshold and math.sign(v133_) == v140_.direction then
						v133_ = 0
					end
				end
			end
		end
	end
	return v133_
end
function LogGrab.onDelimbTree(p141_, p142_, p143_, ...)
	local v144_ = p141_.spec_logGrab
	for v145_ = 1, #v144_.grabs do
		if v144_.grabs[v145_].clawAnimation.state then
			p141_:setLogGrabClawState(v145_, false, true)
		end
	end
	return p142_(p141_, p143_, ...)
end

-- Local values: t
function LogGrab:getGrabCanMountSplitShape(grab, shapeId)
	if self.getFoldAnimTime ~= nil then
		local v148_ = self:getFoldAnimTime()
		if v148_ < grab.foldMinLimit or grab.foldMaxLimit < v148_ then
			return false
		end
	end
	return true
end

-- Local values: constr, jointTransform, cx, cy, cz, nx, ny, nz, yx, yy, yz, minY, maxY, minZ, maxZ, x, y, z, springForce, springDamping
function LogGrab:mountSplitShape(grab, shapeId)
	local v152_ = JointConstructor.new()
	v152_:setActors(grab.jointRoot, shapeId)
	local v153_ = createTransformGroup("dynamicMountJoint")
	local v154_, v155_, v156_ = getWorldTranslation(grab.treeDetectionNode)
	local v157_, v158_, v159_ = localDirectionToWorld(grab.treeDetectionNode, 1, 0, 0)
	local v160_, v161_, v162_ = localDirectionToWorld(grab.treeDetectionNode, 0, 1, 0)
	local v163_, v164_, v165_, v166_ = testSplitShape(shapeId, v154_, v155_, v156_, v157_, v158_, v159_, v160_, v161_, v162_, grab.treeDetectionNodeSizeY, grab.treeDetectionNodeSizeZ)
	if v163_ == nil then
		link(grab.jointNode, v153_)
		setTranslation(v153_, 0, 0, 0)
		v152_:setRotationLimit(0, 0, 0)
		v152_:setRotationLimit(1, 0, 0)
		v152_:setRotationLimit(2, 0, 0)
	else
		link(grab.jointNode, v153_)
		local v167_, v168_, v169_ = localToWorld(grab.treeDetectionNode, 0, (v163_ + v164_) * 0.5, (v165_ + v166_) * 0.5)
		setWorldTranslation(v153_, v167_, v168_, v169_)
		v152_:setRotationLimit(0, -grab.rotLimit, grab.rotLimit)
		v152_:setRotationLimit(1, -grab.rotLimit, grab.rotLimit)
		v152_:setRotationLimit(2, -grab.rotLimit, grab.rotLimit)
	end
	v152_:setJointTransforms(v153_, v153_)
	if not grab.lockAllAxis then
		if grab.limitYAxis then
			v152_:setTranslationLimit(1, true, -0.1, 2)
			v152_:setTranslationLimit(2, false, 0, 0)
		else
			v152_:setTranslationLimit(1, false, 0, 0)
			v152_:setTranslationLimit(2, false, 0, 0)
		end
		v152_:setEnableCollision(true)
	end
	v152_:setRotationLimitSpring(7500, 1500, 7500, 1500, 7500, 1500)
	v152_:setTranslationLimitSpring(7500, 1500, 7500, 1500, 7500, 1500)
	grab.componentLimitsDirty = true
	g_messageCenter:publish(MessageType.TREE_SHAPE_MOUNTED, shapeId, self)
	SpecializationUtil.raiseEvent(self, "onLogGrabMountedTreesChanged", grab)
	return v152_:finalize(), v153_
end

function LogGrab:unmountSplitShape(grab, shapeId, jointIndex, jointTransform, isDeleting)
	removeJoint(jointIndex)
	delete(jointTransform)
	grab.dynamicMountedShapes[shapeId] = nil
	if isDeleting == nil or not isDeleting then
		grab.pendingDynamicMountShapes[shapeId] = true
	else
		grab.pendingDynamicMountShapes[shapeId] = nil
	end
	grab.componentLimitsDirty = true
	SpecializationUtil.raiseEvent(self, "onLogGrabMountedTreesChanged", grab)
end

-- Local values: mass, shapeId, _, i, setting, alpha, jointDesc, axis, pos, vel
function LogGrab:onLogGrabMountedTreesChanged(grab)
	if self.isServer then
		local v178_ = 0
		for v179_, _ in pairs(grab.dynamicMountedShapes) do
			if entityExists(v179_) then
				v178_ = v178_ + getMass(v179_)
			end
		end
		for v180_ = 1, #grab.componentJointMassSettings do
			local v181_ = grab.componentJointMassSettings[v180_]
			local v182_ = MathUtil.inverseLerp(v181_.minMass, v181_.maxMass, v178_)
			local v183_ = v181_.maxRotDriveForce
			local v184_ = v181_.maxRotDriveForce
			local v185_ = v181_.maxRotDriveForce
			local v186_, v187_, v188_ = MathUtil.vector3ArrayLerp(v181_.minMaxRotDriveForce, v181_.maxMaxRotDriveForce, v182_)
			v183_[1] = v186_
			v184_[1] = v187_
			v185_[3] = v188_
			local v189_ = v181_.joint
			for v190_ = 1, 3 do
				local v191_ = v189_.rotDriveRotation[v190_] or 0
				local v192_ = v189_.rotDriveVelocity[v190_] or 0
				setJointAngularDrive(v189_.jointIndex, v190_ - 1, v189_.rotDriveRotation[v190_] ~= nil, v189_.rotDriveVelocity[v190_] ~= nil, v189_.rotDriveSpring[v190_], v189_.rotDriveDamping[v190_], v181_.maxRotDriveForce[v190_], v191_, v192_)
			end
		end
	end
end

-- Local values: spec, i, grab
function LogGrab:onFoldStateChanged(direction, moveToMiddle)
	local v195_ = self.spec_logGrab
	for v196_ = 1, #v195_.grabs do
		local v197_ = v195_.grabs[v196_]
		if v197_.clawAnimation.openDuringFolding then
			if direction ~= self.spec_foldable.turnOnFoldDirection then
				self:setLogGrabClawState(v196_, false, true)
			end
		elseif v197_.clawAnimation.closeDuringFolding and direction ~= self.spec_foldable.turnOnFoldDirection then
			self:setLogGrabClawState(v196_, true, true)
		end
	end
end

function LogGrab:onFoldTimeChanged(time)
	LogGrab.updateActionEvents(self)
end

-- Local values: spec, grab, t
function LogGrab:getIsLogGrabClawStateChangeAllowed(grabIndex)
	local v201_ = self.spec_logGrab.grabs[grabIndex]
	if v201_ ~= nil and self.getFoldAnimTime ~= nil then
		local v202_ = self:getFoldAnimTime()
		if v202_ < v201_.clawAnimation.foldMinLimit or v201_.clawAnimation.foldMaxLimit < v202_ then
			return false
		end
	end
	return true
end

-- Local values: spec, grab
function LogGrab:setLogGrabClawState(grabIndex, state, noEventSend)
	local v207_ = self.spec_logGrab.grabs[grabIndex]
	if v207_ ~= nil then
		if state == nil then
			state = not v207_.clawAnimation.state
		end
		v207_.clawAnimation.state = state
		self:playAnimation(v207_.clawAnimation.name, v207_.clawAnimation.state and v207_.clawAnimation.speedScale or -v207_.clawAnimation.speedScale, self:getAnimationTime(v207_.clawAnimation.name), true)
	end
	LogGrab.updateActionEvents(self)
	LogGrabClawStateEvent.sendEvent(self, state, grabIndex, noEventSend)
end

-- Local values: spec, i, grab, rigidBodyType
function LogGrab:logGrabTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	local v213_ = self.spec_logGrab
	for v214_ = 1, #v213_.grabs do
		local v215_ = v213_.grabs[v214_]
		if v215_.triggerNode == triggerId then
			if onEnter then
				if getSplitType(otherActorId) ~= 0 then
					local v216_ = getRigidBodyType(otherActorId)
					if (v216_ == RigidBodyType.DYNAMIC or v216_ == RigidBodyType.KINEMATIC) and v215_.pendingDynamicMountShapes[otherActorId] == nil then
						v215_.pendingDynamicMountShapes[otherActorId] = true
					end
				end
			elseif onLeave and getSplitType(otherActorId) ~= 0 then
				if v215_.pendingDynamicMountShapes[otherActorId] == nil then
					if v215_.dynamicMountedShapes[otherActorId] ~= nil then
						self:unmountSplitShape(v215_, otherActorId, v215_.dynamicMountedShapes[otherActorId].jointIndex, v215_.dynamicMountedShapes[otherActorId].jointTransform, true)
					end
				else
					v215_.pendingDynamicMountShapes[otherActorId] = nil
				end
			end
		end
	end
end

-- Local values: spec, i, grab
function LogGrab:addNodeObjectMapping(superFunc, list)
	superFunc(self, list)
	local v220_ = self.spec_logGrab
	for v221_ = 1, #v220_.grabs do
		local v222_ = v220_.grabs[v221_]
		if v222_.triggerNode ~= nil then
			list[v222_.triggerNode] = self
		end
	end
end

-- Local values: spec, i, grab
function LogGrab:removeNodeObjectMapping(superFunc, list)
	superFunc(self, list)
	local v226_ = self.spec_logGrab
	for v227_ = 1, #v226_.grabs do
		local v228_ = v226_.grabs[v227_]
		if v228_.triggerNode ~= nil then
			list[v228_.triggerNode] = nil
		end
	end
end

-- Local values: spec, i, grab, j, claw, lastMove, direction, ti, movingToolStr, closing, shapeId, _, shapeId, _
function LogGrab:updateDebugValues(values)
	if self.isServer then
		local v231_ = self.spec_logGrab
		for v232_ = 1, #v231_.grabs do
			local v233_ = v231_.grabs[v232_]
			for v234_, v235_ in ipairs(v233_.claws) do
				local v236_ = nil
				local v237_ = nil
				for v238_ = 1, #v235_.movingTools do
					v236_ = v235_.movingTools[v238_].lastMoveValue
					v237_ = v235_.movingTools[v238_].direction
				end
				local v239_
				if v236_ == nil or v237_ == nil then
					v239_ = ""
				else
					local v240_ = math.sign(v236_) == v237_
					v239_ = string.format(" | isClosing: %s (%.2f/%d)", v240_, v236_, v237_)
				end
				local v241_ = {
					["name"] = string.format("grab (%d) claw (%d):", v232_, v234_)
				}
				local v242_ = string.format
				local v243_ = v235_.currentOffset
				local v244_ = math.deg(v243_)
				local v245_ = v235_.rotationOffsetThreshold
				v241_.value = v242_("current: %.2fdeg / threshold: %.2fdeg  (timer: %d)%s", v244_, math.deg(v245_), v235_.rotationOffsetTimer, v239_)
				table.insert(values, v241_)
			end
			for v246_, _ in pairs(v233_.dynamicMountedShapes) do
				if entityExists(v246_) then
					local v247_ = {
						["name"] = string.format("grab (%d) mounted:", v232_),
						["value"] = string.format("%s - %d", getName(v246_), v246_)
					}
					table.insert(values, v247_)
				end
			end
			for v248_, _ in pairs(v233_.pendingDynamicMountShapes) do
				if entityExists(v248_) then
					local v249_ = {
						["name"] = string.format("grab (%d) pending:", v232_),
						["value"] = string.format("%s - %d", getName(v248_), v248_)
					}
					table.insert(values, v249_)
				end
			end
		end
	end
end
