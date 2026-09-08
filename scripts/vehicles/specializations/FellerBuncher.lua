FellerBuncher = {}
source("dataS/scripts/vehicles/specializations/events/FellerBuncherCutEvent.lua")
source("dataS/scripts/vehicles/specializations/events/FellerBuncherReleaseEvent.lua")

function FellerBuncher.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(FillUnit, specializations)
end
function FellerBuncher.initSpecialization()
	g_storeManager:addSpecType("fellerBuncherMaxTreeSize", "shopListAttributeIconMaxTreeSize", FellerBuncher.loadSpecValueMaxTreeSize, FellerBuncher.getSpecValueMaxTreeSize, StoreSpecies.VEHICLE)
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("FellerBuncher")
	v2_:register(XMLValueType.INT, "vehicle.fellerBuncher#fillUnitIndex", "Fill unit index")
	v2_:register(XMLValueType.FLOAT, "vehicle.fellerBuncher#maxRadius", "Max. tree radius that can be cut", 1)
	v2_:register(XMLValueType.STRING, "vehicle.fellerBuncher#releaseInputAction", "Name of input action to release the tree(s)", "IMPLEMENT_EXTRA2")
	v2_:register(XMLValueType.STRING, "vehicle.fellerBuncher#cutInputAction", "Name of input action to cut the tree (if not defined the trees are automatically cut after cutNode#duration)")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.fellerBuncher.cutNode#node", "Cut node - Used for tree detection and actual cutting")
	v2_:register(XMLValueType.FLOAT, "vehicle.fellerBuncher.cutNode#sizeY", "Cut node size y", 2)
	v2_:register(XMLValueType.FLOAT, "vehicle.fellerBuncher.cutNode#sizeZ", "Cut node size z", 2)
	v2_:register(XMLValueType.TIME, "vehicle.fellerBuncher.cutNode#duration", "Cut duration", 1)
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.fellerBuncher.cutNode.cutCollision#node", "Cut collision node - Node is moved during cutting process")
	v2_:register(XMLValueType.VECTOR_TRANS, "vehicle.fellerBuncher.cutNode.cutCollision#startTrans", "Start translation")
	v2_:register(XMLValueType.VECTOR_TRANS, "vehicle.fellerBuncher.cutNode.cutCollision#endTrans", "end translation")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.fellerBuncher.mountNode#node", "Mount node - Detects trees and mounts them to the parent component")
	v2_:register(XMLValueType.FLOAT, "vehicle.fellerBuncher.mountNode#sizeY", "Mount node size y", 2)
	v2_:register(XMLValueType.FLOAT, "vehicle.fellerBuncher.mountNode#sizeZ", "Mount node size z", 2)
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.fellerBuncher.treeMoveDirectionNode#node", "Provides direction in which the tree is moved while mounting")
	v2_:register(XMLValueType.FLOAT, "vehicle.fellerBuncher.treeMoveDirectionNode#distance", "How far the tree is moved")
	v2_:register(XMLValueType.FLOAT, "vehicle.fellerBuncher.treeMoveDirectionNode#liftDistance", "How far the tree is lifted")
	v2_:register(XMLValueType.STRING, "vehicle.fellerBuncher.mainGrab#animationName", "Main grab animation name")
	v2_:register(XMLValueType.FLOAT, "vehicle.fellerBuncher.mainGrab#speedScale", "Main grab animation speed", 1)
	v2_:register(XMLValueType.FLOAT, "vehicle.fellerBuncher.mainGrab#releaseSpeedScale", "Main grab animation release speed", 1)
	v2_:register(XMLValueType.VECTOR_N, "vehicle.fellerBuncher.mainGrab#componentJointIndices", "Component joint indices to change the damping rate while main grab is closed")
	v2_:register(XMLValueType.FLOAT, "vehicle.fellerBuncher.mainGrab#dampingFactor", "Damping factor for component joint index", 20)
	v2_:register(XMLValueType.STRING, "vehicle.fellerBuncher.cutAnimation#animationName", "Cut animation name")
	v2_:register(XMLValueType.FLOAT, "vehicle.fellerBuncher.cutAnimation#speedScale", "Cut animation speed scale", 1)
	v2_:register(XMLValueType.TIME, "vehicle.fellerBuncher.unmount#delay", "Delay between unmounting each tree", 0.4)
	v2_:register(XMLValueType.STRING, "vehicle.fellerBuncher.unmount#animationName", "Animation played after the joint releases")
	v2_:register(XMLValueType.FLOAT, "vehicle.fellerBuncher.unmount#speedScale", "Animation speed", 1)
	v2_:register(XMLValueType.STRING, "vehicle.fellerBuncher.treeSlot(?).grab#animationName", "Grab animation name")
	v2_:register(XMLValueType.FLOAT, "vehicle.fellerBuncher.treeSlot(?).grab#speedScale", "Grab animation speed", 1)
	v2_:register(XMLValueType.FLOAT, "vehicle.fellerBuncher.treeSlot(?).grab#releaseSpeedScale", "Grab animation release speed", 1)
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.fellerBuncher.sounds", "cut")
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.fellerBuncher.sounds", "saw")
	AnimationManager.registerAnimationNodesXMLPaths(v2_, "vehicle.fellerBuncher.animationNodes")
	EffectManager.registerEffectXMLPaths(v2_, "vehicle.fellerBuncher.effects")
	v2_:setXMLSpecializationType()
end

function FellerBuncher.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setFellerBuncherGrabState", FellerBuncher.setFellerBuncherGrabState)
	SpecializationUtil.registerFunction(vehicleType, "getIsFellerBuncherReadyForCut", FellerBuncher.getIsFellerBuncherReadyForCut)
	SpecializationUtil.registerFunction(vehicleType, "getFellerBuncherCanCutSplitShape", FellerBuncher.getFellerBuncherCanCutSplitShape)
	SpecializationUtil.registerFunction(vehicleType, "cutTree", FellerBuncher.cutTree)
	SpecializationUtil.registerFunction(vehicleType, "fellerBuncherSplitShapeCallback", FellerBuncher.fellerBuncherSplitShapeCallback)
	SpecializationUtil.registerFunction(vehicleType, "doMountProcess", FellerBuncher.doMountProcess)
	SpecializationUtil.registerFunction(vehicleType, "mountTreeInRange", FellerBuncher.mountTreeInRange)
	SpecializationUtil.registerFunction(vehicleType, "releaseMountedTrees", FellerBuncher.releaseMountedTrees)
	SpecializationUtil.registerFunction(vehicleType, "releaseMainArmTree", FellerBuncher.releaseMainArmTree)
	SpecializationUtil.registerFunction(vehicleType, "releaseNextTreeSlot", FellerBuncher.releaseNextTreeSlot)
	SpecializationUtil.registerFunction(vehicleType, "onFellerBuncherTreesChanged", FellerBuncher.onFellerBuncherTreesChanged)
	SpecializationUtil.registerFunction(vehicleType, "getNumLoadedTrees", FellerBuncher.getNumLoadedTrees)
	SpecializationUtil.registerFunction(vehicleType, "onFellerBuncherTreeShapeCut", FellerBuncher.onFellerBuncherTreeShapeCut)
	SpecializationUtil.registerFunction(vehicleType, "onFellerBuncherTreeShapeMounted", FellerBuncher.onFellerBuncherTreeShapeMounted)
end

function FellerBuncher.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleTurnedOn", FellerBuncher.getCanToggleTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "registerLoweringActionEvent", FellerBuncher.registerLoweringActionEvent)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSupportsAutoTreeAlignment", FellerBuncher.getSupportsAutoTreeAlignment)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAutoAlignHasValidTree", FellerBuncher.getAutoAlignHasValidTree)
end

function FellerBuncher.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", FellerBuncher)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", FellerBuncher)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", FellerBuncher)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", FellerBuncher)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", FellerBuncher)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", FellerBuncher)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", FellerBuncher)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", FellerBuncher)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", FellerBuncher)
	SpecializationUtil.registerEventListener(vehicleType, "onFinishAnimation", FellerBuncher)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", FellerBuncher)
end

-- Local values: spec, cutInputActionStr
function FellerBuncher:onLoad(savegame)
	local v_u_7_ = self.spec_fellerBuncher
	v_u_7_.fillUnitIndex = self.xmlFile:getValue("vehicle.fellerBuncher#fillUnitIndex")
	v_u_7_.maxRadius = self.xmlFile:getValue("vehicle.fellerBuncher#maxRadius", 1)
	v_u_7_.releaseInputAction = InputAction[self.xmlFile:getValue("vehicle.fellerBuncher#releaseInputAction", "IMPLEMENT_EXTRA2")] or InputAction.IMPLEMENT_EXTRA2
	local v8_ = self.xmlFile:getValue("vehicle.fellerBuncher#cutInputAction")
	if v8_ ~= nil then
		v_u_7_.cutInputAction = InputAction[v8_]
	end
	v_u_7_.cutNode = self.xmlFile:getValue("vehicle.fellerBuncher.cutNode#node", nil, self.components, self.i3dMappings)
	v_u_7_.cutNodeSizeY = self.xmlFile:getValue("vehicle.fellerBuncher.cutNode#sizeY", 2)
	v_u_7_.cutNodeSizeZ = self.xmlFile:getValue("vehicle.fellerBuncher.cutNode#sizeZ", 2)
	v_u_7_.cutDuration = self.xmlFile:getValue("vehicle.fellerBuncher.cutNode#duration", 1)
	v_u_7_.cutTimer = 0
	v_u_7_.effectState = false
	v_u_7_.lastEffectState = false
	v_u_7_.cutCollisionNode = self.xmlFile:getValue("vehicle.fellerBuncher.cutNode.cutCollision#node", nil, self.components, self.i3dMappings)
	v_u_7_.cutCollisionNodeStartTrans = self.xmlFile:getValue("vehicle.fellerBuncher.cutNode.cutCollision#startTrans", nil, true)
	v_u_7_.cutCollisionNodeEndTrans = self.xmlFile:getValue("vehicle.fellerBuncher.cutNode.cutCollision#endTrans", nil, true)
	v_u_7_.mountNode = self.xmlFile:getValue("vehicle.fellerBuncher.mountNode#node", nil, self.components, self.i3dMappings)
	v_u_7_.mountComponent = self:getParentComponent(v_u_7_.mountNode or self.rootNode)
	v_u_7_.mountNodeSizeY = self.xmlFile:getValue("vehicle.fellerBuncher.mountNode#sizeY", 2)
	v_u_7_.mountNodeSizeZ = self.xmlFile:getValue("vehicle.fellerBuncher.mountNode#sizeZ", 2)
	v_u_7_.treeMoveDirectionNode = self.xmlFile:getValue("vehicle.fellerBuncher.treeMoveDirectionNode#node", nil, self.components, self.i3dMappings)
	v_u_7_.treeMoveDirectionDistance = self.xmlFile:getValue("vehicle.fellerBuncher.treeMoveDirectionNode#distance", 0.05)
	v_u_7_.treeMoveDirectionLiftDistance = self.xmlFile:getValue("vehicle.fellerBuncher.treeMoveDirectionNode#liftDistance", 0.05)
	v_u_7_.mainGrab = {}
	v_u_7_.mainGrab.animationName = self.xmlFile:getValue("vehicle.fellerBuncher.mainGrab#animationName")
	v_u_7_.mainGrab.speedScale = self.xmlFile:getValue("vehicle.fellerBuncher.mainGrab#speedScale", 1)
	v_u_7_.mainGrab.releaseSpeedScale = self.xmlFile:getValue("vehicle.fellerBuncher.mainGrab#releaseSpeedScale", 1)
	v_u_7_.mainGrab.componentJointIndices = self.xmlFile:getValue("vehicle.fellerBuncher.mainGrab#componentJointIndices", nil, true)
	v_u_7_.mainGrab.dampingFactor = self.xmlFile:getValue("vehicle.fellerBuncher.mainGrab#dampingFactor", 20)
	v_u_7_.mainGrab.jointIndex = 0
	v_u_7_.mainGrab.jointNode = nil
	v_u_7_.mainGrab.shapeId = nil
	v_u_7_.mainGrab.isUsed = false
	v_u_7_.cutAnimation = {}
	v_u_7_.cutAnimation.animationName = self.xmlFile:getValue("vehicle.fellerBuncher.cutAnimation#animationName")
	v_u_7_.cutAnimation.speedScale = self.xmlFile:getValue("vehicle.fellerBuncher.cutAnimation#speedScale", 1)
	v_u_7_.foundSplitShape = nil
	v_u_7_.foundSplitShapeIsTree = false
	v_u_7_.mountProcessInProgress = false
	v_u_7_.mountProcessSplitShape = nil
	v_u_7_.mountProcessTreeSlot = nil
	v_u_7_.unmountProcessInProgress = false
	v_u_7_.unmountProcessAnimationPlayed = false
	v_u_7_.unmountProcessTimer = 0
	v_u_7_.unmountProcessDelay = self.xmlFile:getValue("vehicle.fellerBuncher.unmount#delay", 0.4)
	v_u_7_.unmountProcessAnimation = self.xmlFile:getValue("vehicle.fellerBuncher.unmount#animationName")
	v_u_7_.unmountProcessAnimationSpeedScale = self.xmlFile:getValue("vehicle.fellerBuncher.unmount#speedScale", 1)
	v_u_7_.treeSlots = {}
	self.xmlFile:iterate("vehicle.fellerBuncher.treeSlot", function(_, p9_)
		-- upvalues: (copy) self, (copy) v_u_7_
		local v10_ = {
			["animationName"] = self.xmlFile:getValue(p9_ .. ".grab#animationName"),
			["speedScale"] = self.xmlFile:getValue(p9_ .. ".grab#speedScale", 1),
			["releaseSpeedScale"] = self.xmlFile:getValue(p9_ .. ".grab#releaseSpeedScale", 1)
		}
		if v10_.animationName ~= nil then
			v10_.isUsed = false
			v10_.jointIndex = 0
			v10_.jointNode = nil
			v10_.shapeId = nil
			local v11_ = v_u_7_.treeSlots
			table.insert(v11_, v10_)
		end
	end)
	if self.isClient then
		v_u_7_.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.fellerBuncher.animationNodes", self.components, self, self.i3dMappings)
		v_u_7_.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.fellerBuncher.effects", self.components, self, self.i3dMappings)
		v_u_7_.samples = {}
		v_u_7_.samples.cut = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.fellerBuncher.sounds", "cut", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_7_.samples.saw = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.fellerBuncher.sounds", "saw", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
	v_u_7_.texts = {}
	v_u_7_.texts.actionRelease = g_i18n:getText("action_releaseTrees", self.customEnvironment)
	v_u_7_.texts.actionCutTree = g_i18n:getText("action_woodHarvesterCut", self.customEnvironment)
	v_u_7_.texts.warningNoAccess = g_i18n:getText("warning_youAreNotAllowedToCutThisTree", self.customEnvironment)
	v_u_7_.texts.warningNoPermission = g_i18n:getText("shop_messageNoPermissionGeneral", self.customEnvironment)
	v_u_7_.texts.treeTooThick = g_i18n:getText("warning_treeTooThick", self.customEnvironment)
	g_messageCenter:subscribe(MessageType.TREE_SHAPE_CUT, self.onFellerBuncherTreeShapeCut, self)
	g_messageCenter:subscribe(MessageType.TREE_SHAPE_MOUNTED, self.onFellerBuncherTreeShapeMounted, self)
	v_u_7_.dirtyFlag = self:getNextDirtyFlag()
end

-- Local values: spec
function FellerBuncher:onDelete()
	local v13_ = self.spec_fellerBuncher
	if v13_.treeSlots ~= nil then
		self:releaseMainArmTree()
		while self:releaseNextTreeSlot() do

		end
	end
	g_effectManager:deleteEffects(v13_.effects)
	g_soundManager:deleteSamples(v13_.samples)
	g_animationManager:deleteAnimations(v13_.animationNodes)
end

-- Local values: spec, i
function FellerBuncher:onReadStream(streamId, connection)
	local v16_ = self.spec_fellerBuncher
	v16_.effectState = streamReadBool(streamId)
	v16_.mainGrab.isUsed = streamReadBool(streamId)
	for v17_ = 1, #v16_.treeSlots do
		v16_.treeSlots[v17_].isUsed = streamReadBool(streamId)
	end
end

-- Local values: spec, i
function FellerBuncher:onWriteStream(streamId, connection)
	local v20_ = self.spec_fellerBuncher
	streamWriteBool(streamId, v20_.effectState)
	streamWriteBool(streamId, v20_.mainGrab.isUsed)
	for v21_ = 1, #v20_.treeSlots do
		streamWriteBool(streamId, v20_.treeSlots[v21_].isUsed)
	end
end

-- Local values: spec, i
function FellerBuncher:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		local v25_ = self.spec_fellerBuncher
		v25_.effectState = streamReadBool(streamId)
		v25_.mainGrab.isUsed = streamReadBool(streamId)
		for v26_ = 1, #v25_.treeSlots do
			v25_.treeSlots[v26_].isUsed = streamReadBool(streamId)
		end
		FellerBuncher.updateActionEvents(self)
	end
end

-- Local values: spec, i
function FellerBuncher:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v31_ = self.spec_fellerBuncher
		local v32_ = streamWriteBool
		local v33_ = v31_.dirtyFlag
		if v32_(streamId, bit32.band(dirtyMask, v33_) ~= 0) then
			streamWriteBool(streamId, v31_.effectState)
			streamWriteBool(streamId, v31_.mainGrab.isUsed)
			for v34_ = 1, #v31_.treeSlots do
				streamWriteBool(streamId, v31_.treeSlots[v34_].isUsed)
			end
		end
	end
end

-- Local values: spec, lastFoundSplitShape, isCutting, cx, cy, cz, nx, ny, nz, yx, yy, yz, splitShapeId, minY, maxY, minZ, maxZ, isAllowed, warning, dx, dy, dz, cx, cy, cz, isUnloading, i, isFinished, i, cx, cy, cz, nx, ny, nz, yx, yy, yz, splitShapeId, minY, maxY, minZ, maxZ, isAllowed, warning
function FellerBuncher:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v38_ = self.spec_fellerBuncher
	local v39_ = v38_.foundSplitShape
	v38_.foundSplitShape = nil
	if self.isServer then
		local v40_ = false
		if self:getIsFellerBuncherReadyForCut() then
			if v38_.cutNode ~= nil then
				local v41_, v42_, v43_ = getWorldTranslation(v38_.cutNode)
				local v44_, v45_, v46_ = localDirectionToWorld(v38_.cutNode, 1, 0, 0)
				local v47_, v48_, v49_ = localDirectionToWorld(v38_.cutNode, 0, 1, 0)
				local v50_, v51_, v52_, v53_, v54_ = findSplitShape(v41_, v42_, v43_, v44_, v45_, v46_, v47_, v48_, v49_, v38_.cutNodeSizeY, v38_.cutNodeSizeZ)
				if v50_ ~= 0 then
					local v55_, v56_ = self:getFellerBuncherCanCutSplitShape(v50_, v41_, v42_, v43_, v44_, v45_, v46_, v47_, v48_, v49_, v51_, v52_, v53_, v54_)
					if v55_ then
						v38_.foundSplitShape = v50_
						v38_.foundSplitShapeIsTree = getRigidBodyType(v50_) == RigidBodyType.STATIC
						if v38_.cutInputAction == nil then
							v40_ = true
							v38_.cutTimer = v38_.cutTimer + dt
							if v38_.cutTimer > v38_.cutDuration then
								self:cutTree()
								v38_.cutTimer = 0
							end
							if v38_.cutCollisionNode ~= nil then
								setTranslation(v38_.cutCollisionNode, MathUtil.vector3ArrayLerp(v38_.cutCollisionNodeStartTrans, v38_.cutCollisionNodeEndTrans, v38_.cutTimer / v38_.cutDuration))
							end
						end
					elseif isActiveForInputIgnoreSelection and v56_ ~= nil then
						g_currentMission:showBlinkingWarning(v56_, 100)
					end
				end
			end
			if not v40_ then
				v38_.cutTimer = 0
			end
		elseif v38_.mountProcessInProgress then
			if v38_.mountProcessSplitShape ~= nil then
				local v57_, v58_, v59_ = localDirectionToWorld(v38_.treeMoveDirectionNode, 0, 0, getMass(v38_.mountProcessSplitShape) * 10)
				local v60_, v61_, v62_ = worldToLocal(v38_.mountProcessSplitShape, localToWorld(v38_.treeMoveDirectionNode, 0, 1, 0))
				addForce(v38_.mountProcessSplitShape, v57_, v58_, v59_, v60_, v61_, v62_, true)
			end
		elseif v38_.unmountProcessInProgress then
			local v63_ = v38_.unmountProcessTimer - dt
			v38_.unmountProcessTimer = math.max(v63_, 0)
			if v38_.unmountProcessTimer <= 0 then
				if self:getNumLoadedTrees() > 0 then
					if not self:releaseNextTreeSlot() then
						v38_.unmountProcessInProgress = false
						if not self:getIsTurnedOn() then
							self:setFellerBuncherGrabState(false)
						end
					end
					v38_.unmountProcessTimer = v38_.unmountProcessDelay
				else
					local v64_ = self:getIsAnimationPlaying(v38_.mainGrab.animationName)
					for v65_ = 1, #v38_.treeSlots do
						v64_ = v64_ or self:getIsAnimationPlaying(v38_.treeSlots[v65_].animationName)
					end
					if not (v64_ or v38_.unmountProcessAnimationPlayed) then
						if v38_.unmountProcessAnimation ~= nil and not self:getIsAnimationPlaying(v38_.unmountProcessAnimation) then
							self:playAnimation(v38_.unmountProcessAnimation, v38_.unmountProcessAnimationSpeedScale, 0, true)
						end
						v38_.unmountProcessAnimationPlayed = true
					end
					local v66_ = false
					if not v64_ and v38_.unmountProcessAnimationPlayed then
						if v38_.unmountProcessAnimation == nil then
							v66_ = true
						elseif not self:getIsAnimationPlaying(v38_.unmountProcessAnimation) then
							if self:getAnimationTime(v38_.unmountProcessAnimation) > 0.99 then
								self:playAnimation(v38_.unmountProcessAnimation, -v38_.unmountProcessAnimationSpeedScale, 1, true)
							else
								v66_ = true
							end
						end
					end
					if v66_ then
						v38_.unmountProcessInProgress = false
						if not self:getIsTurnedOn() then
							self:setFellerBuncherGrabState(false)
						end
					end
				end
			end
		else
			v38_.cutTimer = 0
		end
		if v38_.mainGrab.shapeId == nil or entityExists(v38_.mainGrab.shapeId) then
			for v67_ = 1, #v38_.treeSlots do
				if v38_.treeSlots[v67_].shapeId ~= nil and not entityExists(v38_.treeSlots[v67_].shapeId) then
					self:releaseMountedTrees()
					break
				end
			end
		else
			self:releaseMountedTrees()
		end
	elseif isActiveForInputIgnoreSelection and v38_.cutNode ~= nil then
		local v68_, v69_, v70_ = getWorldTranslation(v38_.cutNode)
		local v71_, v72_, v73_ = localDirectionToWorld(v38_.cutNode, 1, 0, 0)
		local v74_, v75_, v76_ = localDirectionToWorld(v38_.cutNode, 0, 1, 0)
		local v77_, v78_, v79_, v80_, v81_ = findSplitShape(v68_, v69_, v70_, v71_, v72_, v73_, v74_, v75_, v76_, v38_.cutNodeSizeY, v38_.cutNodeSizeZ)
		if v77_ ~= 0 then
			local v82_, v83_ = self:getFellerBuncherCanCutSplitShape(v77_, v68_, v69_, v70_, v71_, v72_, v73_, v74_, v75_, v76_, v78_, v79_, v80_, v81_)
			if v82_ then
				v38_.foundSplitShape = v77_
			elseif v83_ ~= nil then
				g_currentMission:showBlinkingWarning(v83_, 100)
			end
		end
	end
	if v39_ ~= v38_.foundSplitShape then
		FellerBuncher.updateActionEvents(self)
	end
	if self.isServer then
		v38_.effectState = v38_.cutTimer > 0
	end
	if v38_.effectState ~= v38_.lastEffectState then
		v38_.lastEffectState = v38_.effectState
		self:raiseDirtyFlags(v38_.dirtyFlag)
		if self.isClient then
			if v38_.effectState then
				g_effectManager:setEffectTypeInfo(v38_.effects, FillType.WOODCHIPS)
				g_effectManager:startEffects(v38_.effects)
				if not g_soundManager:getIsSamplePlaying(v38_.samples.cut) then
					g_soundManager:playSample(v38_.samples.cut)
					return
				end
			else
				g_effectManager:stopEffects(v38_.effects)
				if g_soundManager:getIsSamplePlaying(v38_.samples.cut) then
					g_soundManager:stopSample(v38_.samples.cut)
				end
			end
		end
	end
end

-- Local values: spec
function FellerBuncher:onTurnedOn()
	local v85_ = self.spec_fellerBuncher
	if self:getNumLoadedTrees() == 0 then
		self:setFellerBuncherGrabState(true)
	end
	if self.isClient then
		g_animationManager:startAnimations(v85_.animationNodes)
		g_soundManager:playSample(v85_.samples.saw)
	end
end

-- Local values: spec
function FellerBuncher:onTurnedOff()
	local v87_ = self.spec_fellerBuncher
	if self:getNumLoadedTrees() == 0 then
		self:setFellerBuncherGrabState(false)
	end
	if self.isClient then
		g_animationManager:stopAnimations(v87_.animationNodes)
		g_effectManager:stopEffects(v87_.effects)
		g_soundManager:stopSamples(v87_.samples)
	end
end

-- Local values: spec, i, treeSlot, j, componentJoint, i, treeSlot
function FellerBuncher:onFinishAnimation(name)
	local v90_ = self.spec_fellerBuncher
	if v90_.mountProcessInProgress then
		if name == v90_.mainGrab.animationName then
			for v91_ = 1, #v90_.treeSlots do
				local v92_ = v90_.treeSlots[v91_]
				if not v92_.isUsed then
					self:playAnimation(v92_.animationName, -v92_.speedScale, self:getAnimationTime(v92_.animationName), true)
					v90_.mountProcessTreeSlot = v92_
					break
				end
			end
			if v90_.mountProcessTreeSlot == nil and v90_.mainGrab.jointIndex == 0 then
				local v93_ = v90_.mainGrab
				local v94_ = v90_.mainGrab
				local v95_ = v90_.mainGrab
				local v96_, v97_, v98_ = self:mountTreeInRange()
				v93_.jointIndex = v96_
				v94_.jointNode = v97_
				v95_.shapeId = v98_
				if v90_.mainGrab.jointIndex == 0 then
					self:playAnimation(v90_.mainGrab.animationName, v90_.mainGrab.speedScale, self:getAnimationTime(v90_.mainGrab.animationName), true)
					self:playAnimation(v90_.cutAnimation.animationName, v90_.cutAnimation.speedScale, self:getAnimationTime(v90_.cutAnimation.animationName), true)
				else
					v90_.mainGrab.isUsed = true
					self:onFellerBuncherTreesChanged()
					if self.isServer and v90_.mainGrab.componentJointIndices ~= nil then
						for v99_ = 1, #v90_.mainGrab.componentJointIndices do
							local v100_ = self.componentJoints[v90_.mainGrab.componentJointIndices[v99_]]
							if v100_ ~= nil then
								for v101_ = 1, 3 do
									setJointRotationLimitSpring(v100_.jointIndex, v101_ - 1, v100_.rotLimitSpring[v101_], v100_.rotLimitDamping[v101_] * v90_.mainGrab.dampingFactor)
								end
							end
						end
					end
				end
				v90_.mountProcessInProgress = false
				v90_.mountProcessSplitShape = nil
				return
			end
		elseif v90_.mountProcessTreeSlot ~= nil and name == v90_.mountProcessTreeSlot.animationName then
			self:playAnimation(v90_.mainGrab.animationName, v90_.mainGrab.speedScale, self:getAnimationTime(v90_.mainGrab.animationName), true)
			self:playAnimation(v90_.cutAnimation.animationName, v90_.cutAnimation.speedScale, self:getAnimationTime(v90_.cutAnimation.animationName), true)
			local v102_ = v90_.mountProcessTreeSlot
			local v103_, v104_, v105_ = self:mountTreeInRange()
			v102_.jointIndex = v103_
			v102_.jointNode = v104_
			v102_.shapeId = v105_
			if v102_.jointIndex == 0 then
				self:playAnimation(v102_.animationName, v102_.speedScale, self:getAnimationTime(v102_.animationName), true)
			else
				v102_.isUsed = true
				self:onFellerBuncherTreesChanged()
			end
			v90_.mountProcessInProgress = false
			v90_.mountProcessSplitShape = nil
			v90_.mountProcessTreeSlot = nil
		end
	end
end

-- Local values: spec, i, treeSlot, i, treeSlot
function FellerBuncher:setFellerBuncherGrabState(state)
	local v108_ = self.spec_fellerBuncher
	if state then
		self:playAnimation(v108_.mainGrab.animationName, v108_.mainGrab.speedScale, self:getAnimationTime(v108_.mainGrab.animationName), true)
		for v109_ = 1, #v108_.treeSlots do
			local v110_ = v108_.treeSlots[v109_]
			self:playAnimation(v110_.animationName, v110_.speedScale, self:getAnimationTime(v110_.animationName), true)
		end
		self:playAnimation(v108_.cutAnimation.animationName, v108_.cutAnimation.speedScale, self:getAnimationTime(v108_.cutAnimation.animationName), true)
	else
		self:playAnimation(v108_.mainGrab.animationName, -v108_.mainGrab.speedScale, self:getAnimationTime(v108_.mainGrab.animationName), true)
		for v111_ = 1, #v108_.treeSlots do
			local v112_ = v108_.treeSlots[v111_]
			self:playAnimation(v112_.animationName, -v112_.speedScale, self:getAnimationTime(v112_.animationName), true)
		end
		self:playAnimation(v108_.cutAnimation.animationName, -v108_.cutAnimation.speedScale, self:getAnimationTime(v108_.cutAnimation.animationName), true)
	end
end

-- Local values: spec
function FellerBuncher:getIsFellerBuncherReadyForCut()
	local v114_ = self.spec_fellerBuncher
	if v114_.mountProcessInProgress then
		return false
	elseif v114_.unmountProcessInProgress then
		return false
	elseif self:getIsAnimationPlaying(v114_.mainGrab.animationName) then
		return false
	elseif self:getIsTurnedOn() then
		return self:getNumLoadedTrees() < #v114_.treeSlots + 1
	else
		return false
	end
end

-- Local values: spec, radius, i, lenBelow, lenAbove
function FellerBuncher:getFellerBuncherCanCutSplitShape(splitShapeId, cx, cy, cz, nx, ny, nz, yx, yy, yz, minY, maxY, minZ, maxZ)
	local v127_ = self.spec_fellerBuncher
	if WoodHarvester.getCanSplitShapeBeAccessed(self, cx, cz, splitShapeId) then
		local v128_ = maxY - minY
		local v129_ = maxZ - minZ
		if math.max(v128_, v129_) * 0.5 > v127_.maxRadius then
			return false, v127_.texts.treeTooThick
		end
		if splitShapeId == v127_.mainGrab.shapeId then
			return false
		end
		for v130_ = 1, #v127_.treeSlots do
			if splitShapeId == v127_.treeSlots[v130_].shapeId then
				return false
			end
		end
		local v131_, v132_ = getSplitShapePlaneExtents(splitShapeId, cx, cy, cz, nx, ny, nz)
		return v131_ ~= nil and (v131_ > 0.15 and v132_ > 0.15)
	elseif g_currentMission:getHasPlayerPermission("cutTrees", self:getOwnerConnection()) then
		return false, v127_.texts.warningNoAccess
	else
		return false, v127_.texts.warningNoPermission
	end
end

-- Local values: spec, stats, cutTreeCount, splitType, cx, cy, cz, nx, ny, nz, yx, yy, yz
function FellerBuncher:cutTree(noEventSend)
	local v135_ = self.spec_fellerBuncher
	if v135_.foundSplitShape ~= nil then
		if self.isServer then
			local v136_ = g_currentMission:farmStats(self:getActiveFarm())
			local v137_ = v136_:updateStats("cutTreeCount", 1)
			g_achievementManager:tryUnlock("CutTreeFirst", v137_)
			g_achievementManager:tryUnlock("CutTree", v137_)
			local v138_ = g_splitShapeManager:getSplitTypeByIndex(getSplitType(v135_.foundSplitShape))
			if v138_ ~= nil then
				v136_:updateTreeTypesCut(v138_.name)
			end
			local v139_, v140_, v141_ = getWorldTranslation(v135_.cutNode)
			local v142_, v143_, v144_ = localDirectionToWorld(v135_.cutNode, 1, 0, 0)
			local v145_, v146_, v147_ = localDirectionToWorld(v135_.cutNode, 0, 1, 0)
			splitShape(v135_.foundSplitShape, v139_, v140_, v141_, v142_, v143_, v144_, v145_, v146_, v147_, v135_.cutNodeSizeY, v135_.cutNodeSizeZ, "fellerBuncherSplitShapeCallback", self)
		end
		v135_.foundSplitShape = nil
	end
	self:playAnimation(v135_.cutAnimation.animationName, -v135_.cutAnimation.speedScale, self:getAnimationTime(v135_.cutAnimation.animationName), true)
	if v135_.cutInputAction ~= nil and self.isClient then
		g_soundManager:playSample(v135_.samples.cut)
	end
	FellerBuncherCutEvent.sendEvent(self, noEventSend)
end

-- Local values: spec
function FellerBuncher:fellerBuncherSplitShapeCallback(shape, isBelow, isAbove, minY, maxY, minZ, maxZ)
	local v151_ = self.spec_fellerBuncher
	g_currentMission:addKnownSplitShape(shape)
	g_treePlantManager:addingSplitShape(shape, v151_.foundSplitShape, v151_.foundSplitShapeIsTree)
	if isAbove then
		self:doMountProcess(shape)
	end
end

-- Local values: spec, x, y, z, dx, dy, dz
function FellerBuncher:doMountProcess(shape, noEventSend)
	local v154_ = self.spec_fellerBuncher
	self:playAnimation(v154_.mainGrab.animationName, -v154_.mainGrab.speedScale, self:getAnimationTime(v154_.mainGrab.animationName), true)
	v154_.mountProcessInProgress = true
	v154_.mountProcessSplitShape = shape
	local v155_, v156_, v157_ = getTranslation(shape)
	local v158_, v159_, v160_ = localDirectionToWorld(v154_.treeMoveDirectionNode, 0, 0, 1)
	setTranslation(shape, v155_ + v158_ * v154_.treeMoveDirectionDistance, v156_ + v159_ * v154_.treeMoveDirectionDistance + v154_.treeMoveDirectionLiftDistance, v157_ + v160_ * v154_.treeMoveDirectionDistance)
end

-- Local values: spec, cx, cy, cz, nx, ny, nz, yx, yy, yz, minY, maxY, minZ, maxZ, jointNode, constr, springForce, springDamping
function FellerBuncher:mountTreeInRange()
	local v162_ = self.spec_fellerBuncher
	if v162_.mountNode ~= nil then
		local v163_, v164_, v165_ = getWorldTranslation(v162_.mountNode)
		local v166_, v167_, v168_ = localDirectionToWorld(v162_.mountNode, 1, 0, 0)
		local v169_, v170_, v171_ = localDirectionToWorld(v162_.mountNode, 0, 1, 0)
		local v172_, v173_, v174_, v175_ = testSplitShape(v162_.mountProcessSplitShape, v163_, v164_, v165_, v166_, v167_, v168_, v169_, v170_, v171_, v162_.mountNodeSizeY, v162_.mountNodeSizeZ)
		if v172_ ~= nil then
			local v176_ = createTransformGroup("jointNode")
			link(v162_.mountNode, v176_)
			setTranslation(v176_, 0, (v172_ + v173_) * 0.5, (v174_ + v175_) * 0.5)
			local v177_ = JointConstructor.new()
			v177_:setActors(v162_.mountComponent, v162_.mountProcessSplitShape)
			v177_:setJointTransforms(v176_, v176_)
			v177_:setRotationLimit(0, 0, 0)
			v177_:setRotationLimit(1, 0, 0)
			v177_:setRotationLimit(2, 0, 0)
			v177_:setEnableCollision(true)
			v177_:setRotationLimitSpring(7500, 1500, 7500, 1500, 7500, 1500)
			v177_:setTranslationLimitSpring(7500, 1500, 7500, 1500, 7500, 1500)
			g_messageCenter:publish(MessageType.TREE_SHAPE_MOUNTED, v162_.mountProcessSplitShape, self)
			return v177_:finalize(), v176_, v162_.mountProcessSplitShape
		end
	end
	return 0, nil
end

-- Local values: spec
function FellerBuncher:releaseMountedTrees(noEventSend)
	local v180_ = self.spec_fellerBuncher
	if self.isServer then
		v180_.unmountProcessInProgress = true
		v180_.unmountProcessAnimationPlayed = false
		v180_.unmountProcessTimer = v180_.unmountProcessDelay
		if not self:releaseMainArmTree() then
			self:releaseNextTreeSlot()
		end
	end
	FellerBuncherReleaseEvent.sendEvent(self, noEventSend)
end

-- Local values: spec, wasUsed, j, componentJoint
function FellerBuncher:releaseMainArmTree()
	local v182_ = self.spec_fellerBuncher
	local v183_ = v182_.mainGrab.isUsed
	self:playAnimation(v182_.mainGrab.animationName, v182_.mainGrab.releaseSpeedScale, self:getAnimationTime(v182_.mainGrab.animationName), true)
	self:playAnimation(v182_.cutAnimation.animationName, v182_.cutAnimation.speedScale, self:getAnimationTime(v182_.cutAnimation.animationName), true)
	if v182_.mainGrab.jointIndex ~= 0 then
		removeJoint(v182_.mainGrab.jointIndex)
		v182_.mainGrab.jointIndex = 0
	end
	if v182_.mainGrab.jointNode ~= nil then
		delete(v182_.mainGrab.jointNode)
		v182_.mainGrab.jointNode = nil
	end
	v182_.mainGrab.shapeId = nil
	v182_.mainGrab.isUsed = false
	if self.isServer and (self.isServer and v182_.mainGrab.componentJointIndices ~= nil) then
		for v184_ = 1, #v182_.mainGrab.componentJointIndices do
			local v185_ = self.componentJoints[v182_.mainGrab.componentJointIndices[v184_]]
			if v185_ ~= nil then
				setJointRotationLimitSpring(v185_.jointIndex, 0, v185_.rotLimitSpring[1], v185_.rotLimitDamping[1])
				setJointRotationLimitSpring(v185_.jointIndex, 1, v185_.rotLimitSpring[2], v185_.rotLimitDamping[2])
				setJointRotationLimitSpring(v185_.jointIndex, 2, v185_.rotLimitSpring[3], v185_.rotLimitDamping[3])
			end
		end
	end
	self:onFellerBuncherTreesChanged()
	return v183_
end

-- Local values: spec, i, treeSlot
function FellerBuncher:releaseNextTreeSlot()
	local v187_ = self.spec_fellerBuncher
	for v188_ = 1, #v187_.treeSlots do
		local v189_ = v187_.treeSlots[v188_]
		if v189_.isUsed then
			self:playAnimation(v189_.animationName, v189_.releaseSpeedScale, self:getAnimationTime(v189_.animationName), true)
			if v189_.jointIndex ~= 0 then
				removeJoint(v189_.jointIndex)
				v189_.jointIndex = 0
			end
			if v189_.jointNode ~= nil then
				delete(v189_.jointNode)
				v189_.jointNode = nil
			end
			v189_.shapeId = nil
			v189_.isUsed = false
			self:onFellerBuncherTreesChanged()
			return true
		end
	end
	return false
end

-- Local values: spec
function FellerBuncher:onFellerBuncherTreesChanged()
	local v191_ = self.spec_fellerBuncher
	if v191_.fillUnitIndex ~= nil then
		self:addFillUnitFillLevel(self:getOwnerFarmId(), v191_.fillUnitIndex, -math.huge, self:getFillUnitFirstSupportedFillType(v191_.fillUnitIndex), ToolType.UNDEFINED, nil)
		self:addFillUnitFillLevel(self:getOwnerFarmId(), v191_.fillUnitIndex, self:getNumLoadedTrees(), self:getFillUnitFirstSupportedFillType(v191_.fillUnitIndex), ToolType.UNDEFINED, nil)
	end
	FellerBuncher.updateActionEvents(self)
	self:raiseDirtyFlags(v191_.dirtyFlag)
end

-- Local values: spec, numTrees, i
function FellerBuncher:getNumLoadedTrees()
	local v193_ = self.spec_fellerBuncher
	local v194_ = 0
	if v193_.mainGrab.isUsed then
		v194_ = v194_ + 1
	end
	for v195_ = 1, #v193_.treeSlots do
		if v193_.treeSlots[v195_].isUsed then
			v194_ = v194_ + 1
		end
	end
	return v194_
end

-- Local values: spec, i
function FellerBuncher:onFellerBuncherTreeShapeCut(oldShape, shape)
	if self.isServer then
		local v198_ = self.spec_fellerBuncher
		if oldShape == v198_.mainGrab.shapeId then
			self:releaseMountedTrees()
			return
		end
		for v199_ = 1, #v198_.treeSlots do
			if oldShape == v198_.treeSlots[v199_].shapeId then
				self:releaseMountedTrees()
				return
			end
		end
	end
end

-- Local values: spec, i
function FellerBuncher:onFellerBuncherTreeShapeMounted(shape, mountVehicle)
	if mountVehicle ~= self and self.isServer then
		local v203_ = self.spec_fellerBuncher
		if shape == v203_.mainGrab.shapeId then
			self:releaseMountedTrees()
			return
		end
		for v204_ = 1, #v203_.treeSlots do
			if shape == v203_.treeSlots[v204_].shapeId then
				self:releaseMountedTrees()
				return
			end
		end
	end
end

-- Local values: spec
function FellerBuncher:getCanToggleTurnedOn(superFunc)
	local v207_ = self.spec_fellerBuncher
	if v207_.mountProcessInProgress then
		return false
	elseif self:getIsAnimationPlaying(v207_.mainGrab.animationName) then
		return false
	elseif v207_.unmountProcessInProgress then
		return false
	else
		return superFunc(self)
	end
end

function FellerBuncher:registerLoweringActionEvent(superFunc, actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, ignoreCollisions) end

function FellerBuncher:getSupportsAutoTreeAlignment(superFunc)
	return true
end

-- Local values: spec
function FellerBuncher:getAutoAlignHasValidTree(superFunc, radius)
	local v210_ = self.spec_fellerBuncher
	return v210_.foundSplitShape ~= nil, radius <= v210_.maxRadius
end

-- Local values: spec, _, actionEventId
function FellerBuncher:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v213_ = self.spec_fellerBuncher
		self:clearActionEventsTable(v213_.actionEvents)
		if isActiveForInputIgnoreSelection then
			local _, v214_ = self:addPoweredActionEvent(v213_.actionEvents, v213_.releaseInputAction, self, FellerBuncher.actionEventReleaseTrees, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v214_, GS_PRIO_HIGH)
			g_inputBinding:setActionEventText(v214_, v213_.texts.actionRelease)
			if v213_.cutInputAction ~= nil then
				local _, v215_ = self:addPoweredActionEvent(v213_.actionEvents, v213_.cutInputAction, self, FellerBuncher.actionEventCutTree, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(v215_, GS_PRIO_HIGH)
				g_inputBinding:setActionEventText(v215_, v213_.texts.actionCutTree)
			end
			FellerBuncher.updateActionEvents(self)
		end
	end
end

function FellerBuncher:actionEventReleaseTrees(actionName, inputValue, callbackState, isAnalog)
	self:releaseMountedTrees()
end

function FellerBuncher:actionEventCutTree(actionName, inputValue, callbackState, isAnalog)
	self:cutTree()
end

-- Local values: spec, actionEvent, treesMounted, i
function FellerBuncher:updateActionEvents()
	if self.isClient then
		local v219_ = self.spec_fellerBuncher
		local v220_ = v219_.actionEvents[v219_.releaseInputAction]
		if v220_ ~= nil then
			local v221_ = v219_.mainGrab.isUsed
			if not v221_ then
				for v222_ = 1, #v219_.treeSlots do
					if v219_.treeSlots[v222_].isUsed then
						v221_ = true
						break
					end
				end
			end
			g_inputBinding:setActionEventActive(v220_.actionEventId, v221_)
		end
		local v223_ = v219_.actionEvents[v219_.cutInputAction]
		if v223_ ~= nil then
			g_inputBinding:setActionEventActive(v223_.actionEventId, v219_.foundSplitShape ~= nil)
		end
	end
end

function FellerBuncher.loadSpecValueMaxTreeSize(xmlFile, customEnvironment, baseDir)
	return xmlFile:getValue("vehicle.fellerBuncher#maxRadius")
end

-- Local values: value, str
function FellerBuncher.getSpecValueMaxTreeSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	if storeItem.specs.fellerBuncherMaxTreeSize == nil then
		return
	else
		local v228_ = storeItem.specs.fellerBuncherMaxTreeSize * 2 * 100
		local v229_ = string.format("%d%s", MathUtil.round(v228_), g_i18n:getText("unit_cmShort"))
		if returnValues and returnRange then
			return v228_, v228_, v229_
		elseif returnValues then
			return v228_, v229_
		else
			return v229_
		end
	end
end
