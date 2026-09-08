HandToolChainsaw = {}
source("dataS/scripts/handTools/events/ChainsawCutEvent.lua")
HandToolChainsaw.WORLD_POSITION_COMPRESSION_PARAMS_XZ = nil
HandToolChainsaw.WORLD_POSITION_COMPRESSION_PARAMS_Y = nil
HandToolChainsaw.CACHED_TARGETED_TREE = {
	["node"] = nil,
	["x"] = 0,
	["y"] = 0,
	["z"] = 0
}
HandToolChainsaw.TARGET_MASK = CollisionFlag.TREE + CollisionFlag.DYNAMIC_OBJECT
HandToolChainsaw.SPLIT_PLANE_OFFSET_Z = -0.2
HandToolChainsaw.ROOTS_HEIGHT_THRESHOLD = 0.01
HandToolChainsaw.GROUND_DISTANCE_THRESHOLD = 0.02
HandToolChainsaw.MINIMUM_CUT_DISTANCE = 0.5
HandToolChainsaw.MAXIMUM_CUT_DISTANCE = 1.5
HandToolChainsaw.ROTATION_SPEED = 0.003
HandToolChainsaw.VALID_CUT_COLOR = Color.new(0.395, 0.925, 0.115, 1)
HandToolChainsaw.INVALID_CUT_COLOR = Color.PRESETS.ORANGERED
source("dataS/scripts/handTools/specializations/ChainsawCutState.lua")

function HandToolChainsaw.registerXMLPaths(xmlSchema)
	xmlSchema:setXMLSpecializationType("HandToolChainsaw")
	xmlSchema:register(XMLValueType.STRING, "handTool.chainsaw.playerWorkStylePreset", "Name of the style preset", nil, false)
	xmlSchema:register(XMLValueType.FLOAT, "handTool.chainsaw#maximumCutDiameter", "The maximum diameter in metres that can be cut", 1, false)
	xmlSchema:register(XMLValueType.FLOAT, "handTool.chainsaw#maximumDelimbDiameter", "The maximum diameter range in metres that is used for delimb", 1, false)
	xmlSchema:register(XMLValueType.FLOAT, "handTool.chainsaw#cutTimePerSquareMeter", "The time in seconds per square metre that the chainsaw takes to cut", 1, false)
	xmlSchema:register(XMLValueType.STRING, "handTool.chainsaw.ringSelector#filename", "The path of the ring selector i3d file", nil, true)
	xmlSchema:register(XMLValueType.FLOAT, "handTool.chainsaw.ringSelector#scaleOffset", "The size in metres added onto the ring indicator\'s scale", 0, false)
	xmlSchema:register(XMLValueType.NODE_INDEX, "handTool.chainsaw.cutNode#node", "The name of the node used to position the chainsaw while cutting", nil, false)
	xmlSchema:register(XMLValueType.NODE_INDEX, "handTool.chainsaw.handNode#cutting", "The name of the node used to position the chainsaw while cutting", nil, false)
	xmlSchema:register(XMLValueType.NODE_INDEX, "handTool.chainsaw.handNode#walking", "The name of the node used to position the chainsaw while walking", nil, false)
	AnimationManager.registerAnimationNodesXMLPaths(xmlSchema, "handTool.chainsaw.chain")
	EffectManager.registerEffectXMLPaths(xmlSchema, "handTool.chainsaw.effects")
	SoundManager.registerSampleXMLPaths(xmlSchema, "handTool.chainsaw.sounds", "cut(?)")
end

function HandToolChainsaw.registerFunctions(handToolType)
	SpecializationUtil.registerFunction(handToolType, "calculateCutPlane", HandToolChainsaw.calculateCutPlane)
	SpecializationUtil.registerFunction(handToolType, "getChainSpeedFactor", HandToolChainsaw.getChainSpeedFactor)
	SpecializationUtil.registerFunction(handToolType, "testIfTooLow", HandToolChainsaw.testIfTooLow)
	SpecializationUtil.registerFunction(handToolType, "testIfCutAllowed", HandToolChainsaw.testIfCutAllowed)
	SpecializationUtil.registerFunction(handToolType, "testIfCutValid", HandToolChainsaw.testIfCutValid)
	SpecializationUtil.registerFunction(handToolType, "beginCutting", HandToolChainsaw.beginCutting)
	SpecializationUtil.registerFunction(handToolType, "stopCutting", HandToolChainsaw.stopCutting)
	SpecializationUtil.registerFunction(handToolType, "beginDelimbing", HandToolChainsaw.beginDelimbing)
	SpecializationUtil.registerFunction(handToolType, "stopDelimbing", HandToolChainsaw.stopDelimbing)
	SpecializationUtil.registerFunction(handToolType, "setCurrentCutState", HandToolChainsaw.setCurrentCutState)
	SpecializationUtil.registerFunction(handToolType, "updateCutting", HandToolChainsaw.updateCutting)
	SpecializationUtil.registerFunction(handToolType, "updateCuttingAnimation", HandToolChainsaw.updateCuttingAnimation)
	SpecializationUtil.registerFunction(handToolType, "updateSplitPlane", HandToolChainsaw.updateSplitPlane)
	SpecializationUtil.registerFunction(handToolType, "updateRingSelector", HandToolChainsaw.updateRingSelector)
end

function HandToolChainsaw.registerEventListeners(handToolType)
	SpecializationUtil.registerEventListener(handToolType, "onDelete", HandToolChainsaw)
	SpecializationUtil.registerEventListener(handToolType, "onLoad", HandToolChainsaw)
	SpecializationUtil.registerEventListener(handToolType, "onPostLoad", HandToolChainsaw)
	SpecializationUtil.registerEventListener(handToolType, "onUpdate", HandToolChainsaw)
	SpecializationUtil.registerEventListener(handToolType, "onDraw", HandToolChainsaw)
	SpecializationUtil.registerEventListener(handToolType, "onWriteUpdateStream", HandToolChainsaw)
	SpecializationUtil.registerEventListener(handToolType, "onReadUpdateStream", HandToolChainsaw)
	SpecializationUtil.registerEventListener(handToolType, "onHeldStart", HandToolChainsaw)
	SpecializationUtil.registerEventListener(handToolType, "onHeldEnd", HandToolChainsaw)
	SpecializationUtil.registerEventListener(handToolType, "onRegisterActionEvents", HandToolChainsaw)
end

function HandToolChainsaw.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(HandToolMotorized, specializations)
end

-- Local values: spec, mission, ringI3DFilename, i, animation
function HandToolChainsaw:onLoad(xmlFile, baseDirectory)
	local v8_ = self.spec_chainsaw
	if HandToolChainsaw.WORLD_POSITION_COMPRESSION_PARAMS_XZ == nil then
		local v9_ = g_currentMission
		HandToolChainsaw.WORLD_POSITION_COMPRESSION_PARAMS_XZ = NetworkUtil.createWorldPositionCompressionParams(v9_.terrainSize + 10, 0.5 * (v9_.terrainSize + 10), 0.01)
		HandToolChainsaw.WORLD_POSITION_COMPRESSION_PARAMS_Y = NetworkUtil.createWorldPositionCompressionParams(1500, 0, 0.01)
	end
	v8_.dirtyFlag = self:getNextDirtyFlag()
	v8_.revText = g_i18n:getText("action_revHandToolMotor")
	v8_.cutText = g_i18n:getText("action_startCuttingChainsaw")
	v8_.rollText = g_i18n:getText("action_rollChainsaw")
	v8_.currentCutState = ChainsawCutState.IDLE
	v8_.currentCutStateSent = v8_.currentCutState
	v8_.isVerticalCut = true
	v8_.removedAttachmentsSent = false
	v8_.targetedTree = nil
	v8_.cuttingTreeNode = nil
	v8_.currentCutRoll = 0
	v8_.rollInput = 0
	v8_.isCutting = false
	v8_.cutMinimumY = nil
	v8_.cutMaximumY = nil
	v8_.cutMinimumZ = nil
	v8_.cutMaximumZ = nil
	v8_.cutStartPositionX = 0
	v8_.cutStartPositionY = 0
	v8_.cutStartPositionZ = 0
	v8_.cutEndPositionX = 0
	v8_.cutEndPositionY = 0
	v8_.cutEndPositionZ = 0
	v8_.smoothingCurve = BezierCurve.new(0.11, 0.54, 0.91, 0.5)
	v8_.playerWorkStylePreset = xmlFile:getValue("handTool.chainsaw.playerWorkStylePreset")
	v8_.maximumDelimbDiameter = xmlFile:getValue("handTool.chainsaw#maximumDelimbDiameter", 1)
	v8_.maximumCutDiameter = xmlFile:getValue("handTool.chainsaw#maximumCutDiameter", 1)
	v8_.cutTimePerSquareMeter = xmlFile:getValue("handTool.chainsaw#cutTimePerSquareMeter", 1) * 1000
	v8_.currentCutTime = 0
	v8_.currentTargetCutTime = 0
	v8_.currentTargetStartupTime = 0
	v8_.startupTime = 1000
	v8_.cutNode = xmlFile:getValue("handTool.chainsaw.cutNode#node", nil, self.components, self.i3dMappings)
	if v8_.cutNode == nil then
		Logging.xmlWarning(xmlFile, "Chainsaw is missing cut node, root node will be used instead!")
		v8_.cutNode = self.rootNode
	end
	v8_.handNodeCutting = xmlFile:getValue("handTool.chainsaw.handNode#cutting", nil, self.components, self.i3dMappings)
	v8_.handNodeWalking = xmlFile:getValue("handTool.chainsaw.handNode#walking", nil, self.components, self.i3dMappings)
	local v10_ = xmlFile:getValue("handTool.chainsaw.ringSelector#filename", nil)
	if v10_ ~= nil then
		local v11_ = Utils.getFilename(v10_, self.baseDirectory)
		v8_.ringSharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(v11_, true, false, HandToolChainsaw.onRingLoadFinished, self, nil)
		v8_.ringLoadingTask = self:createLoadingTask(v8_)
		v8_.ringScaleOffset = xmlFile:getValue("handTool.chainsaw.ringSelector#scaleOffset", 0)
	end
	v8_.cutGuideNode = createTransformGroup("chainsawCutGuideNode")
	link(getRootNode(), v8_.cutGuideNode)
	v8_.cameraRotationNode = createTransformGroup("chainsawCameraRotationNode")
	link(getRootNode(), v8_.cameraRotationNode)
	v8_.splitPlaneNode = createTransformGroup("chainsawSplitPlaneNode")
	link(v8_.cameraRotationNode, v8_.splitPlaneNode)
	setRotation(v8_.splitPlaneNode, 0, 0, -1.5707963267948966)
	setTranslation(v8_.splitPlaneNode, -0.1, v8_.maximumCutDiameter / 2, HandToolChainsaw.SPLIT_PLANE_OFFSET_Z)
	if self.isClient then
		v8_.effectEndTime = 0
		v8_.isPlayingEffects = false
		v8_.effects = g_effectManager:loadEffect(xmlFile, "handTool.chainsaw.effects", self.components, self, self.i3dMappings)
		g_effectManager:setEffectTypeInfo(v8_.effects, FillType.WOOD)
		v8_.isPlayingChainAnimation = false
		v8_.chainsAnimation = g_animationManager:loadAnimations(xmlFile, "handTool.chainsaw.chain", self.components, v8_, self.i3dMappings)
		for _, v12_ in ipairs(v8_.chainsAnimation) do
			local v13_ = v8_.startupTime
			local v14_ = v12_.turnOnFadeTime
			v8_.startupTime = math.max(v13_, v14_)
		end
		v8_.cutSamples = g_soundManager:loadSamplesFromXML(xmlFile, "handTool.chainsaw.sounds", "cut", baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
	v8_.delimbEffectDuration = 100
	v8_.lastDelimbPosX = 0
	v8_.lastDelimbPosY = 0
	v8_.lastDelimbPosZ = 0
	v8_.lastDelimbNormalX = 1
	v8_.lastDelimbNormalY = 0
	v8_.lastDelimbNormalZ = 0
	v8_.lastDelimbUpX = 0
	v8_.lastDelimbUpY = 1
	v8_.lastDelimbUpZ = 0
	if self.isClient then
		v8_.crosshair = self:createCrosshairOverlay("gui.crosshairDefault")
	end
	self.walkMultiplier = 0.5
end

-- Local values: spec, motorizedSpec
function HandToolChainsaw:onPostLoad(savegame)
	local v16_ = self.spec_chainsaw
	local v17_ = self.spec_motorized
	self:setRPMGainPerSecond((v17_.maxRPM - v17_.minRPM) / (v16_.startupTime * 0.001))
	self:setRPMLossPerSecond((v17_.maxRPM - v17_.minRPM) / (v16_.startupTime * 0.001) * 1.2)
end

-- Local values: spec
function HandToolChainsaw:onRingLoadFinished(ringNode, failedReason)
	local v20_ = self.spec_chainsaw
	self:finishLoadingTask(v20_.ringLoadingTask)
	v20_.ringLoadingTask = nil
	if ringNode == nil or ringNode == 0 then
		Logging.error("Chainsaw could not load ring indicator i3d!")
	else
		v20_.ringNode = getChildAt(ringNode, 0)
		setVisibility(v20_.ringNode, false)
		link(v20_.cameraRotationNode, v20_.ringNode)
		delete(ringNode)
	end
end

-- Local values: spec
function HandToolChainsaw:onDelete()
	local v22_ = self.spec_chainsaw
	if v22_.ringSharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(v22_.ringSharedLoadRequestId)
		v22_.ringSharedLoadRequestId = nil
	end
	if v22_.chainsAnimation ~= nil then
		g_animationManager:deleteAnimations(v22_.chainsAnimation)
	end
	g_effectManager:deleteEffects(v22_.effects)
	g_soundManager:deleteSamples(v22_.cutSamples)
	if v22_.cutGuideNode ~= nil then
		delete(v22_.cutGuideNode)
		v22_.cutGuideNode = nil
	end
	if v22_.cameraRotationNode ~= nil then
		delete(v22_.cameraRotationNode)
		v22_.cameraRotationNode = nil
		v22_.splitPlaneNode = nil
		v22_.ringNode = nil
	end
	if self:getCarryingPlayer() ~= nil then
		self:getCarryingPlayer().targeter:removeTargetType(HandToolChainsaw)
	end
	if v22_.crosshair ~= nil then
		v22_.crosshair:delete()
		v22_.crosshair = nil
	end
end

-- Local values: spec
function HandToolChainsaw:onWriteUpdateStream(streamId, connection, dirtyMask)
	local v27_ = self.spec_chainsaw
	local v28_ = streamWriteBool
	local v29_ = v27_.dirtyFlag
	if v28_(streamId, bit32.band(dirtyMask, v29_) ~= 0) then
		ChainsawCutState.writeStream(streamId, v27_.currentCutStateSent)
		if v27_.currentCutStateSent == ChainsawCutState.CUTTING then
			streamWriteBool(streamId, v27_.isVerticalCut)
		end
		if connection:getIsServer() then
			if v27_.currentCutStateSent == ChainsawCutState.DELIMBING then
				NetworkUtil.writeCompressedWorldPosition(streamId, v27_.lastDelimbPosX, HandToolChainsaw.WORLD_POSITION_COMPRESSION_PARAMS_XZ)
				NetworkUtil.writeCompressedWorldPosition(streamId, v27_.lastDelimbPosY, HandToolChainsaw.WORLD_POSITION_COMPRESSION_PARAMS_Y)
				NetworkUtil.writeCompressedWorldPosition(streamId, v27_.lastDelimbPosZ, HandToolChainsaw.WORLD_POSITION_COMPRESSION_PARAMS_XZ)
				NetworkUtil.writeCompressedRange(streamId, v27_.lastDelimbNormalX, -1, 1, 12)
				NetworkUtil.writeCompressedRange(streamId, v27_.lastDelimbNormalY, -1, 1, 12)
				NetworkUtil.writeCompressedRange(streamId, v27_.lastDelimbNormalZ, -1, 1, 12)
				NetworkUtil.writeCompressedRange(streamId, v27_.lastDelimbUpX, -1, 1, 12)
				NetworkUtil.writeCompressedRange(streamId, v27_.lastDelimbUpY, -1, 1, 12)
				NetworkUtil.writeCompressedRange(streamId, v27_.lastDelimbUpZ, -1, 1, 12)
				return
			end
		else
			streamWriteBool(streamId, v27_.removedAttachmentsSent)
		end
	end
end

-- Local values: spec, carryingPlayer, receivedState, isVerticalCut, removedAttachment
function HandToolChainsaw:onReadUpdateStream(streamId, timestamp, connection)
	local v33_ = self.spec_chainsaw
	local v34_ = self:getCarryingPlayer()
	if streamReadBool(streamId) then
		local v35_ = ChainsawCutState.readStream(streamId)
		local v36_ = v35_ ~= ChainsawCutState.CUTTING and true or streamReadBool(streamId)
		if v34_ == nil or not v34_.isOwner then
			self:setCurrentCutState(v35_, v36_)
		end
		if connection:getIsServer() then
			if streamReadBool(streamId) and (v34_ ~= nil and v34_.isOwner) then
				v33_.effectEndTime = g_time + v33_.delimbEffectDuration
			end
		elseif v35_ == ChainsawCutState.DELIMBING then
			v33_.lastDelimbPosX = NetworkUtil.readCompressedWorldPosition(streamId, HandToolChainsaw.WORLD_POSITION_COMPRESSION_PARAMS_XZ)
			v33_.lastDelimbPosY = NetworkUtil.readCompressedWorldPosition(streamId, HandToolChainsaw.WORLD_POSITION_COMPRESSION_PARAMS_Y)
			v33_.lastDelimbPosZ = NetworkUtil.readCompressedWorldPosition(streamId, HandToolChainsaw.WORLD_POSITION_COMPRESSION_PARAMS_XZ)
			v33_.lastDelimbNormalX = NetworkUtil.readCompressedRange(streamId, -1, 1, 12)
			v33_.lastDelimbNormalY = NetworkUtil.readCompressedRange(streamId, -1, 1, 12)
			v33_.lastDelimbNormalZ = NetworkUtil.readCompressedRange(streamId, -1, 1, 12)
			v33_.lastDelimbUpX = NetworkUtil.readCompressedRange(streamId, -1, 1, 12)
			v33_.lastDelimbUpY = NetworkUtil.readCompressedRange(streamId, -1, 1, 12)
			v33_.lastDelimbUpZ = NetworkUtil.readCompressedRange(streamId, -1, 1, 12)
			return
		end
	end
end

-- Local values: spec, carryingPlayer, upX, upY, upZ, cameraNode, dirX, dirY, dirZ, isCutPossible, treeNode, cutX, _, cutZ, x, y, z, normalX, normalY, normalZ, upX, upY, upZ, x, y, z, normalX, normalY, normalZ, upX, upY, upZ, planeWidth, planeDepth, removedAttachment
function HandToolChainsaw:onUpdate(dt)
	local v39_ = self.spec_chainsaw
	local v40_ = self:getCarryingPlayer()
	if v40_ ~= nil then
		if v40_.isOwner and self:getIsHeld() then
			v39_.targetedTree = self:getCarryingPlayer().targeter.closestTargetsByKey[HandToolChainsaw]
			v39_.possibleTreeNode = nil
			self:updateSplitPlane()
			if v39_.currentCutState ~= ChainsawCutState.CUTTING then
				if v39_.rollInput ~= 0 then
					local v41_ = v39_.currentCutRoll + HandToolChainsaw.ROTATION_SPEED * v39_.rollInput * dt
					v39_.currentCutRoll = math.clamp(v41_, -1.5707963267948966, 1.5707963267948966)
					v39_.rollInput = 0
				end
				if self.graphicalNode ~= nil then
					local v42_, v43_, v44_ = localDirectionToLocal(v39_.cameraRotationNode, getParent(self.graphicalNode), 0, 1, 0)
					local v45_ = g_cameraManager:getActiveCamera()
					local v46_, v47_, v48_ = localDirectionToLocal(v45_, getParent(self.graphicalNode), 0, 0, -1)
					setDirection(self.graphicalNode, v46_, v47_, v48_, v42_, v43_, v44_)
				end
			end
			local v49_ = false
			if v39_.currentCutState == ChainsawCutState.IDLE or v39_.currentCutState == ChainsawCutState.CUTTING then
				local v50_ = v39_.cuttingTreeNode
				if v50_ == nil and v39_.targetedTree ~= nil then
					v50_ = v39_.targetedTree.node
				end
				if v50_ ~= nil then
					local v51_, _, v52_ = getWorldTranslation(v39_.cameraRotationNode)
					if self:testIfCutValid(v50_, v51_, v52_, v39_.cutMinimumY, v39_.cutMaximumY, v39_.cutMinimumZ, v39_.cutMaximumZ) then
						if v39_.cuttingTreeNode == nil then
							v39_.possibleTreeNode = v50_
							v49_ = true
						else
							v49_ = true
						end
					elseif v39_.cuttingTreeNode ~= nil then
						self:stopCutting(false)
					end
				end
			end
			if v39_.currentCutState == ChainsawCutState.IDLE then
				if v49_ then
					g_inputBinding:setActionEventText(v39_.activateActionId, v39_.cutText)
				else
					g_inputBinding:setActionEventText(v39_.activateActionId, string.format(v39_.revText, self.typeDesc))
				end
				g_inputBinding:setActionEventTextVisibility(v39_.activateActionId, true)
				self:updateRingSelector(v39_.targetedTree, v49_, v39_.cutMinimumY, v39_.cutMaximumY, v39_.cutMinimumZ, v39_.cutMaximumZ)
			elseif v39_.currentCutState == ChainsawCutState.CUTTING then
				g_inputBinding:setActionEventTextVisibility(v39_.activateActionId, false)
				self:updateCutting(dt)
			end
		end
		if v39_.currentCutState == ChainsawCutState.DELIMBING then
			if v40_.isOwner then
				local v53_, v54_, v55_, v56_, v57_, v58_, v59_, v60_, v61_ = self:calculateCutPlane()
				v39_.lastDelimbPosX = v53_
				v39_.lastDelimbPosY = v54_
				v39_.lastDelimbPosZ = v55_
				v39_.lastDelimbNormalX = v56_
				v39_.lastDelimbNormalY = v57_
				v39_.lastDelimbNormalZ = v58_
				v39_.lastDelimbUpX = v59_
				v39_.lastDelimbUpY = v60_
				v39_.lastDelimbUpZ = v61_
				self:raiseDirtyFlags(v39_.dirtyFlag)
			end
			if self.isServer then
				local v62_ = v39_.lastDelimbPosX
				local v63_ = v39_.lastDelimbPosY
				local v64_ = v39_.lastDelimbPosZ
				local v65_ = v39_.lastDelimbNormalX
				local v66_ = v39_.lastDelimbNormalY
				local v67_ = v39_.lastDelimbNormalZ
				local v68_ = v39_.lastDelimbUpX
				local v69_ = v39_.lastDelimbUpY
				local v70_ = v39_.lastDelimbUpZ
				local v71_ = v39_.maximumDelimbDiameter
				local v72_ = v39_.maximumDelimbDiameter + HandToolChainsaw.SPLIT_PLANE_OFFSET_Z
				local v73_ = findAndRemoveSplitShapeAttachments(v62_, v63_, v64_, v65_, v66_, v67_, v68_, v69_, v70_, 0.7, v71_, v72_)
				if v39_.removedAttachmentsSent ~= v73_ then
					v39_.removedAttachmentsSent = v73_
					self:raiseDirtyFlags(v39_.dirtyFlag)
				end
				if v73_ then
					v39_.effectEndTime = g_time + v39_.delimbEffectDuration
				end
			end
		end
		if self.isClient then
			if v39_.effectEndTime > g_time then
				if not v39_.isPlayingEffects then
					g_effectManager:startEffects(v39_.effects)
					g_soundManager:playSamples(v39_.cutSamples)
					v39_.isPlayingEffects = true
				end
			elseif v39_.isPlayingEffects then
				g_effectManager:stopEffects(v39_.effects)
				g_soundManager:stopSamples(v39_.cutSamples)
				v39_.isPlayingEffects = false
			end
			if self:getCurrentRPM() > self:getMinRPM() then
				if not v39_.isPlayingChainAnimation then
					g_animationManager:startAnimations(v39_.chainsAnimation)
					v39_.isPlayingChainAnimation = true
					return
				end
			elseif v39_.isPlayingChainAnimation then
				g_animationManager:stopAnimations(v39_.chainsAnimation)
				v39_.isPlayingChainAnimation = false
			end
		end
	end
end

-- Local values: spec
function HandToolChainsaw:onDraw()
	local v75_ = self.spec_chainsaw
	if v75_.crosshair ~= nil and v75_.currentCutState == ChainsawCutState.IDLE then
		v75_.crosshair:render()
	end
end

-- Local values: carryingPlayer, targeter, spec
function HandToolChainsaw:onHeldStart()
	local v77_ = self:getCarryingPlayer()
	if v77_ ~= nil then
		if v77_.isOwner then
			local v78_ = v77_.targeter
			v78_:addTargetType(HandToolChainsaw, HandToolChainsaw.TARGET_MASK, HandToolChainsaw.MINIMUM_CUT_DISTANCE, HandToolChainsaw.MAXIMUM_CUT_DISTANCE)
			v78_:addFilterToTargetType(HandToolChainsaw, function(p79_, _, _, _)
				local v80_
				if p79_ == nil or p79_ == 0 then
					v80_ = false
				else
					v80_ = getHasClassId(p79_, ClassIds.MESH_SPLIT_SHAPE)
				end
				return v80_
			end)
		else
			setTranslation(self.graphicalNode, 0, 0, 0)
			setRotation(self.graphicalNode, 0, 0, 0)
		end
		local v81_ = self.spec_chainsaw
		if v81_.playerWorkStylePreset ~= nil then
			v77_:applyCustomWorkStyle(v81_.playerWorkStylePreset)
			v77_:setIsHoldingChainsaw(true)
		end
	end
end

-- Local values: spec, carryingPlayer
function HandToolChainsaw:onHeldEnd()
	local v83_ = self.spec_chainsaw
	local v84_ = self:getCarryingPlayer()
	if v84_ ~= nil then
		if v84_.isOwner then
			v84_.targeter:removeTargetType(HandToolChainsaw)
		end
		if v83_.playerWorkStylePreset ~= nil then
			v84_:applyCustomWorkStyle(nil)
			v84_:setIsHoldingChainsaw(false)
		end
	end
	if v83_.currentCutState == ChainsawCutState.DELIMBING then
		self:stopDelimbing()
	elseif v83_.currentCutState == ChainsawCutState.CUTTING then
		self:stopCutting(false)
	end
	g_animationManager:stopAnimations(v83_.chainsAnimation)
	v83_.isPlayingChainAnimation = false
	if v83_.ringNode ~= nil then
		setVisibility(v83_.ringNode, false)
	end
	v83_.rollInput = 0
end

-- Local values: spec, _, actionEventId
function HandToolChainsaw:onRegisterActionEvents()
	local v86_ = self.spec_chainsaw
	if self:getIsActiveForInput(true) then
		local _, v87_ = self:addActionEvent(InputAction.AXIS_ROTATE_HANDTOOL, self, HandToolChainsaw.onRollAction, false, false, true, true, nil)
		g_inputBinding:setActionEventTextPriority(v87_, GS_PRIO_VERY_HIGH)
		g_inputBinding:setActionEventText(v87_, string.format(v86_.rollText, self.typeDesc))
		local _, v88_ = self:addActionEvent(InputAction.ACTIVATE_HANDTOOL, self, HandToolChainsaw.onCutAction, true, true, false, true, nil)
		v86_.activateActionId = v88_
		g_inputBinding:setActionEventTextPriority(v88_, GS_PRIO_VERY_HIGH)
		g_inputBinding:setActionEventText(v88_, string.format(v86_.revText, self.typeDesc))
	end
end

-- Local values: spec
function HandToolChainsaw:onRollAction(_, inputDelta)
	local v91_ = self.spec_chainsaw
	v91_.rollInput = v91_.rollInput + inputDelta
end

-- Local values: isInputDown, spec
function HandToolChainsaw:onCutAction(_, inputValue)
	local v94_ = inputValue > 0
	local v95_ = self.spec_chainsaw
	v95_.isCutting = v94_
	if v94_ then
		if v95_.targetedTree == nil then
			self:beginDelimbing()
		else
			self:beginCutting()
			if v95_.currentCutState ~= ChainsawCutState.CUTTING then
				self:beginDelimbing()
			end
		end
	elseif v95_.currentCutState == ChainsawCutState.CUTTING then
		self:stopCutting(false)
		return
	elseif v95_.currentCutState == ChainsawCutState.DELIMBING then
		self:stopDelimbing()
	else
		v95_.currentCutState = ChainsawCutState.IDLE
	end
end

-- Local values: spec, carryingPlayer
function HandToolChainsaw:setCurrentCutState(cutState, isVerticalCut)
	local v99_ = self.spec_chainsaw
	v99_.currentCutState = cutState
	v99_.isVerticalCut = isVerticalCut
	local v100_ = self:getCarryingPlayer()
	if self.isServer or v100_ ~= nil and v100_.isOwner then
		v99_.currentCutStateSent = v99_.currentCutState
		self:raiseDirtyFlags(v99_.dirtyFlag)
	end
	if v100_ ~= nil then
		v100_:setChainsawState(cutState == ChainsawCutState.CUTTING, isVerticalCut)
	end
end

-- Local values: carryingPlayer, mission
function HandToolChainsaw:testIfCutAllowed(treeNode, cutX, cutZ)
	local v105_ = self:getCarryingPlayer()
	if v105_ == nil then
		return false
	elseif g_currentMission:getHasPlayerPermission(Farm.PERMISSION.CUT_TREES) then
		return g_splitShapeManager:getIsShapeCutAllowed(cutX, cutZ, treeNode, v105_:getFarmId()) and true or false
	else
		return false
	end
end

-- Local values: spec
function HandToolChainsaw:testIfCutValid(treeNode, cutX, cutZ, minY, maxY, minZ, maxZ)
	local v112_ = self.spec_chainsaw
	if self:testIfTooLow(treeNode, minY, maxY, minZ, maxZ) then
		return maxY - minY < v112_.maximumCutDiameter and maxZ - minZ < v112_.maximumCutDiameter
	else
		return false
	end
end

-- Local values: spec, x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4, _, distanceFromRootsY1, _, distanceFromRootsY2, _, distanceFromRootsY3, _, distanceFromRootsY4, rootDistanceValid1, rootDistanceValid2, rootDistanceValid3, rootDistanceValid4, distanceFromTerrainY1, distanceFromTerrainY2, distanceFromTerrainY3, distanceFromTerrainY4, terrainDistanceValid1, terrainDistanceValid2, terrainDistanceValid3, terrainDistanceValid4
function HandToolChainsaw:testIfTooLow(treeNode, minY, maxY, minZ, maxZ)
	if treeNode == nil or (treeNode == 0 or not entityExists(treeNode)) then
		return false
	end
	if minY == nil or (maxY == nil or (minZ == nil or maxZ == nil)) then
		return false
	end
	if getRigidBodyType(treeNode) ~= RigidBodyType.STATIC then
		return true
	end
	local v119_ = self.spec_chainsaw
	local v120_, v121_, v122_ = localToWorld(v119_.splitPlaneNode, minY, 0, minZ)
	local v123_, v124_, v125_ = localToWorld(v119_.splitPlaneNode, minY, 0, maxZ)
	local v126_, v127_, v128_ = localToWorld(v119_.splitPlaneNode, maxY, 0, minZ)
	local v129_, v130_, v131_ = localToWorld(v119_.splitPlaneNode, maxY, 0, maxZ)
	local _, v132_ = worldToLocal(treeNode, v120_, v121_, v122_)
	local _, v133_ = worldToLocal(treeNode, v123_, v124_, v125_)
	local _, v134_ = worldToLocal(treeNode, v126_, v127_, v128_)
	local _, v135_ = worldToLocal(treeNode, v129_, v130_, v131_)
	local v136_ = HandToolChainsaw.ROOTS_HEIGHT_THRESHOLD <= v132_
	local v137_ = HandToolChainsaw.ROOTS_HEIGHT_THRESHOLD <= v133_
	local v138_ = HandToolChainsaw.ROOTS_HEIGHT_THRESHOLD <= v134_
	local v139_ = HandToolChainsaw.ROOTS_HEIGHT_THRESHOLD <= v135_
	local v140_ = v121_ - getTerrainHeightAtWorldPos(g_terrainNode, v120_, v121_, v122_)
	local v141_ = v124_ - getTerrainHeightAtWorldPos(g_terrainNode, v123_, v124_, v125_)
	local v142_ = v127_ - getTerrainHeightAtWorldPos(g_terrainNode, v126_, v127_, v128_)
	local v143_ = v130_ - getTerrainHeightAtWorldPos(g_terrainNode, v129_, v130_, v131_)
	local v144_ = HandToolChainsaw.GROUND_DISTANCE_THRESHOLD <= v140_
	local v145_ = HandToolChainsaw.GROUND_DISTANCE_THRESHOLD <= v141_
	local v146_ = HandToolChainsaw.GROUND_DISTANCE_THRESHOLD <= v142_
	local v147_ = HandToolChainsaw.GROUND_DISTANCE_THRESHOLD <= v143_
	local v148_ = Player.DEBUG_DISPLAY_FLAG.HANDTOOLS
	local v149_ = Player.currentDebugFlag
	if bit32.band(v148_, v149_) ~= 0 then
		drawDebugPoint(v120_, v121_, v122_, v136_ and 0 or 1, v136_ and 1 or 0, 0, 1, true)
		drawDebugPoint(v123_, v124_, v125_, v137_ and 0 or 1, v137_ and 1 or 0, 0, 1, true)
		drawDebugPoint(v126_, v127_, v128_, v138_ and 0 or 1, v138_ and 1 or 0, 0, 1, true)
		drawDebugPoint(v129_, v130_, v131_, v139_ and 0 or 1, v139_ and 1 or 0, 0, 1, true)
		drawDebugLine(v120_, v121_, v122_, v136_ and 0 or 1, v136_ and 1 or 0, 0, v120_, v121_ - (v132_ + HandToolChainsaw.ROOTS_HEIGHT_THRESHOLD), v122_, 1, 0, 0, true)
		drawDebugLine(v123_, v124_, v125_, v137_ and 0 or 1, v137_ and 1 or 0, 0, v123_, v124_ - (v133_ + HandToolChainsaw.ROOTS_HEIGHT_THRESHOLD), v125_, 1, 0, 0, true)
		drawDebugLine(v126_, v127_, v128_, v138_ and 0 or 1, v138_ and 1 or 0, 0, v126_, v127_ - (v134_ + HandToolChainsaw.ROOTS_HEIGHT_THRESHOLD), v128_, 1, 0, 0, true)
		drawDebugLine(v129_, v130_, v131_, v139_ and 0 or 1, v139_ and 1 or 0, 0, v129_, v130_ - (v135_ + HandToolChainsaw.ROOTS_HEIGHT_THRESHOLD), v131_, 1, 0, 0, true)
		drawDebugLine(v120_, v121_, v122_, v144_ and 0 or 1, v144_ and 1 or 0, 0, v120_, v121_ - (v140_ + HandToolChainsaw.GROUND_DISTANCE_THRESHOLD), v122_, 1, 0, 0, true)
		drawDebugLine(v123_, v124_, v125_, v145_ and 0 or 1, v145_ and 1 or 0, 0, v123_, v124_ - (v141_ + HandToolChainsaw.GROUND_DISTANCE_THRESHOLD), v125_, 1, 0, 0, true)
		drawDebugLine(v126_, v127_, v128_, v146_ and 0 or 1, v146_ and 1 or 0, 0, v126_, v127_ - (v142_ + HandToolChainsaw.GROUND_DISTANCE_THRESHOLD), v128_, 1, 0, 0, true)
		drawDebugLine(v129_, v130_, v131_, v147_ and 0 or 1, v147_ and 1 or 0, 0, v129_, v130_ - (v143_ + HandToolChainsaw.GROUND_DISTANCE_THRESHOLD), v131_, 1, 0, 0, true)
	end
	if v136_ then
		if v137_ then
			if v138_ then
				if v139_ then
					if v144_ then
						if v145_ then
							if not v146_ then
								v147_ = v146_
							end
						else
							v147_ = v145_
						end
					else
						v147_ = v144_
					end
				else
					v147_ = v139_
				end
			else
				v147_ = v138_
			end
		else
			v147_ = v137_
		end
	else
		v147_ = v136_
	end
	return v147_
end

-- Local values: motorizedSpec
function HandToolChainsaw:getChainSpeedFactor()
	local v151_ = self.spec_motorized
	return MathUtil.inverseLerp(0.3, 1, MathUtil.lerp(v151_.minRPM, v151_.maxRPM, v151_.currentRPM))
end

-- Local values: spec, player
function HandToolChainsaw:beginDelimbing()
	local v153_ = self.spec_chainsaw
	local v154_ = self:getCarryingPlayer()
	if v154_ ~= nil and v154_.isOwner then
		self:setCurrentCutState(ChainsawCutState.DELIMBING, true)
		self:setCurrentLoad(0)
		self:setTargetRPMToMax()
		g_inputBinding:setActionEventTextVisibility(v153_.activateActionId, false)
	end
end

-- Local values: spec
function HandToolChainsaw:stopDelimbing()
	local v156_ = self.spec_chainsaw
	self:setCurrentCutState(ChainsawCutState.IDLE, true)
	v156_.effectEndTime = 0
	self:setCurrentLoad(0)
	self:setTargetRPMToIdle()
end

-- Local values: spec, player, cutX, _, cutZ, mission, _, _, rotZ, cutArea
function HandToolChainsaw:beginCutting()
	local v158_ = self.spec_chainsaw
	if v158_.ringNode ~= nil then
		setVisibility(v158_.ringNode, false)
	end
	local v159_ = self:getCarryingPlayer()
	if v159_ == nil or not v159_.isOwner then
		return
	elseif v158_.possibleTreeNode == nil then
		return
	else
		local v160_, _, v161_ = getWorldTranslation(v158_.cameraRotationNode)
		if self:testIfCutAllowed(v158_.possibleTreeNode, v160_, v161_) then
			local _, _, v162_ = getRotation(v158_.cameraRotationNode)
			self:setCurrentCutState(ChainsawCutState.CUTTING, v162_ < 0.7)
			v158_.cuttingTreeNode = v158_.possibleTreeNode
			self:setCurrentLoad(0)
			v158_.currentCutTime = 0
			local v163_ = self:getTimeToReachRPM(self:getMaxRPM()) * 1000
			local v164_ = math.floor(v163_)
			v158_.currentTargetStartupTime = math.max(v164_, 0.00001)
			v158_.currentTargetCutTime = (v158_.cutMaximumZ - v158_.cutMinimumZ) * (v158_.cutMaximumY - v158_.cutMinimumY) * 3.141592653589793 * v158_.cutTimePerSquareMeter + v158_.currentTargetStartupTime
			local v165_, v166_, v167_ = localToWorld(v158_.splitPlaneNode, v158_.cutMinimumY - 0.05, 0, v158_.cutMinimumZ)
			v158_.cutRevPositionX = v165_
			v158_.cutRevPositionY = v166_
			v158_.cutRevPositionZ = v167_
			local v168_, v169_, v170_ = localToWorld(v158_.splitPlaneNode, v158_.cutMinimumY, 0, v158_.cutMinimumZ)
			v158_.cutStartPositionX = v168_
			v158_.cutStartPositionY = v169_
			v158_.cutStartPositionZ = v170_
			local v171_, v172_, v173_ = localToWorld(v158_.splitPlaneNode, v158_.cutMaximumY, 0, v158_.cutMinimumZ)
			v158_.cutEndPositionX = v171_
			v158_.cutEndPositionY = v172_
			v158_.cutEndPositionZ = v173_
			HandToolUtil.linkAndTransformRelativeToParent(self.graphicalNode, v158_.cutNode, v158_.cutGuideNode)
			if v159_.inputComponent ~= nil then
				v159_.inputComponent:lock()
			end
		else
			g_currentMission:showBlinkingWarning(g_i18n:getText("warning_youAreNotAllowedToCutThisTree"), 2000)
		end
	end
end

-- Local values: spec, player, cuttingTreeNode, x, y, z, downX, downY, downZ, leftX, leftY, leftZ, planeWidth, planeDepth
function HandToolChainsaw:stopCutting(sliceTree)
	local v176_ = self.spec_chainsaw
	local v177_ = self:getCarryingPlayer()
	if v177_ ~= nil and v177_.isOwner then
		local v178_ = v176_.cuttingTreeNode
		v176_.cuttingTreeNode = nil
		self:setCurrentCutState(ChainsawCutState.IDLE, true)
		v176_.currentCutTime = 0
		self:setCurrentLoad(0)
		self:setTargetRPMToIdle()
		if v177_.isOwner then
			link(self.graphicalNodeParent, self.graphicalNode)
			setTranslation(self.graphicalNode, 0, 0, 0)
			v177_.inputComponent:unlock()
		end
		v176_.effectEndTime = 0
		if sliceTree and v178_ ~= nil then
			local v179_, v180_, v181_, v182_, v183_, v184_, v185_, v186_, v187_, v188_, v189_ = self:calculateCutPlane()
			if self.isServer then
				ChainsawUtil.cutSplitShape(v178_, v179_, v180_, v181_, v182_, v183_, v184_, v185_, v186_, v187_, v188_, v189_, self:getOwnerFarmId())
				return
			end
			g_client:getServerConnection():sendEvent(ChainsawCutEvent.new(v178_, v179_, v180_, v181_, v182_, v183_, v184_, v185_, v186_, v187_, v188_, v189_, self:getOwnerFarmId()))
		end
	end
end

-- Local values: spec, cutPositionX, cutPositionY, cutPositionZ, player, playerTargeter, playerLookX, playerLookY, playerLookZ, cutDistanceFromPlayer
function HandToolChainsaw:updateCutting(dt)
	local v192_ = self.spec_chainsaw
	local v193_, v194_, v195_ = getWorldTranslation(v192_.cameraRotationNode)
	local v196_ = self:getCarryingPlayer().targeter
	local v197_ = v196_.lastRayX
	local v198_ = v196_.lastRayY
	local v199_ = v196_.lastRayZ
	self:updateCuttingAnimation(dt)
	self:setTargetRPMToMax()
	v192_.currentCutTime = v192_.currentCutTime + dt
	if MathUtil.vector3Length(v197_ - v193_, v198_ - v194_, v199_ - v195_) >= HandToolChainsaw.MAXIMUM_CUT_DISTANCE then
		self:stopCutting(false)
	elseif v192_.currentCutTime >= v192_.currentTargetCutTime then
		self:stopCutting(true)
	end
end

-- Local values: spec, cutCurrentPositionX, cutCurrentPositionY, cutCurrentPositionZ, cutCurrentProgress, cutCurrentProgress, cutLastProgress, linearSpeed, currentCutSpeed
function HandToolChainsaw:updateCuttingAnimation(dt)
	local v202_ = self.spec_chainsaw
	local v203_, v204_, v205_
	if v202_.currentCutTime <= v202_.currentTargetStartupTime then
		local v206_ = v202_.currentCutTime / v202_.currentTargetStartupTime
		local v207_ = math.clamp(v206_, 0, 1)
		v203_, v204_, v205_ = MathUtil.vector3Lerp(v202_.cutRevPositionX, v202_.cutRevPositionY, v202_.cutRevPositionZ, v202_.cutStartPositionX, v202_.cutStartPositionY, v202_.cutStartPositionZ, v207_)
		self:setCurrentLoad(0)
	else
		v202_.effectEndTime = g_time + 200
		local v208_ = (v202_.currentCutTime - v202_.currentTargetStartupTime) / (v202_.currentTargetCutTime - v202_.currentTargetStartupTime)
		local v209_ = math.clamp(v208_, 0, 1)
		local v210_ = v202_.smoothingCurve:solve(v209_)
		local v211_ = (v202_.currentCutTime - v202_.currentTargetStartupTime - dt) / (v202_.currentTargetCutTime - v202_.currentTargetStartupTime)
		local v212_ = math.clamp(v211_, 0, 1)
		local v213_ = v202_.smoothingCurve:solve(v212_)
		local v214_ = dt / (v202_.currentTargetCutTime - v202_.currentTargetStartupTime)
		local v215_ = v210_ - v213_
		local v216_ = v214_ / math.max(v215_, 0.00001)
		self:setCurrentLoad((math.clamp(v216_, 0, 1)))
		v203_, v204_, v205_ = MathUtil.vector3Lerp(v202_.cutStartPositionX, v202_.cutStartPositionY, v202_.cutStartPositionZ, v202_.cutEndPositionX, v202_.cutEndPositionY, v202_.cutEndPositionZ, v210_)
	end
	setWorldTranslation(v202_.cutGuideNode, v203_, v204_, v205_)
	setWorldQuaternion(v202_.cutGuideNode, getWorldQuaternion(v202_.splitPlaneNode))
end

-- Local values: spec, x, y, z, cameraNode, upX, upY, upZ, dirX, dirY, dirZ, _, playerYaw, x, y, z, downX, downY, downZ, leftX, leftY, leftZ, planeWidth, planeDepth, x, y, z, downX, downY, downZ, leftX, leftY, leftZ, planeWidth, planeDepth
function HandToolChainsaw:updateSplitPlane()
	local v218_ = self.spec_chainsaw
	if v218_.currentCutState == ChainsawCutState.DELIMBING then
		local v219_, v220_, v221_ = localToWorld(self.graphicalNode, 0, -v218_.maximumDelimbDiameter * 0.5, 0)
		setWorldTranslation(v218_.cameraRotationNode, v219_, v220_, v221_)
		local v222_ = g_cameraManager:getActiveCamera()
		local v223_, v224_, v225_ = localDirectionToWorld(v222_, 0, 1, 0)
		local v226_, v227_, v228_ = localDirectionToWorld(v222_, 0, 0, -1)
		setDirection(v218_.cameraRotationNode, v226_, v227_, v228_, v223_, v224_, v225_)
	else
		local _, v229_ = self:getCarryingPlayer().camera:getRotation()
		setWorldRotation(v218_.cameraRotationNode, 0, v229_, 0)
	end
	rotateAboutLocalAxis(v218_.cameraRotationNode, v218_.currentCutRoll, 0, 0, 1)
	v218_.cutMinimumY = nil
	v218_.cutMaximumY = nil
	v218_.cutMinimumZ = nil
	v218_.cutMaximumZ = nil
	if v218_.currentCutState == ChainsawCutState.CUTTING then
		if v218_.cuttingTreeNode ~= nil and entityExists(v218_.cuttingTreeNode) then
			local v230_, v231_, v232_, v233_, v234_, v235_, v236_, v237_, v238_, v239_, v240_ = self:calculateCutPlane()
			local v241_, v242_, v243_, v244_ = testSplitShape(v218_.cuttingTreeNode, v230_, v231_, v232_, v233_, v234_, v235_, v236_, v237_, v238_, v239_, v240_)
			v218_.cutMinimumY = v241_
			v218_.cutMaximumY = v242_
			v218_.cutMinimumZ = v243_
			v218_.cutMaximumZ = v244_
		end
	else
		if v218_.currentCutState == ChainsawCutState.IDLE then
			if v218_.targetedTree == nil or not entityExists(v218_.targetedTree.node) then
				return
			end
			setWorldTranslation(v218_.cameraRotationNode, v218_.targetedTree.x, v218_.targetedTree.y, v218_.targetedTree.z)
			local v245_, v246_, v247_, v248_, v249_, v250_, v251_, v252_, v253_, v254_, v255_ = self:calculateCutPlane()
			local v256_, v257_, v258_, v259_ = testSplitShape(v218_.targetedTree.node, v245_, v246_, v247_, v248_, v249_, v250_, v251_, v252_, v253_, v254_, v255_)
			v218_.cutMinimumY = v256_
			v218_.cutMaximumY = v257_
			v218_.cutMinimumZ = v258_
			v218_.cutMaximumZ = v259_
		end
		return
	end
end

-- Local values: spec, ringScale, worldTreeCentreX, worldTreeCentreY, worldTreeCentreZ, localTreeCentreX, localTreeCentreY, localTreeCentreZ
function HandToolChainsaw:updateRingSelector(targetedTree, isCutPossible, cutMinimumY, cutMaximumY, cutMinimumZ, cutMaximumZ)
	local v267_ = self.spec_chainsaw
	if v267_.ringNode == nil then
		return
	else
		setVisibility(v267_.ringNode, targetedTree ~= nil)
		if targetedTree == nil then
			return
		else
			if isCutPossible then
				setShaderParameter(v267_.ringNode, "colorScale", HandToolChainsaw.VALID_CUT_COLOR.r, HandToolChainsaw.VALID_CUT_COLOR.g, HandToolChainsaw.VALID_CUT_COLOR.b, 1, false)
			else
				setShaderParameter(v267_.ringNode, "colorScale", HandToolChainsaw.INVALID_CUT_COLOR.r, HandToolChainsaw.INVALID_CUT_COLOR.g, HandToolChainsaw.INVALID_CUT_COLOR.b, 1, false)
			end
			if cutMinimumY ~= nil then
				local v268_ = cutMaximumZ - cutMinimumZ
				local v269_ = cutMaximumY - cutMinimumY
				local v270_ = math.max(v268_, v269_) + v267_.ringScaleOffset
				setScale(v267_.ringNode, 1, v270_, v270_)
				local v271_, v272_, v273_ = localToWorld(v267_.splitPlaneNode, (cutMinimumY + cutMaximumY) * 0.5, 0, (cutMinimumZ + cutMaximumZ) * 0.5)
				local v274_, v275_, v276_ = worldToLocal(getParent(v267_.ringNode), v271_, v272_, v273_)
				setTranslation(v267_.ringNode, v274_, v275_, v276_)
			end
		end
	end
end

-- Local values: spec, x, y, z, downX, downY, downZ, leftX, leftY, leftZ, planeWidth, planeDepth
function HandToolChainsaw:calculateCutPlane()
	local v278_ = self.spec_chainsaw
	local v279_, v280_, v281_ = getWorldTranslation(v278_.splitPlaneNode)
	local v282_, v283_, v284_ = localDirectionToWorld(v278_.splitPlaneNode, 0, -1, 0)
	local v285_, v286_, v287_ = localDirectionToWorld(v278_.splitPlaneNode, 1, 0, 0)
	return v279_, v280_, v281_, v282_, v283_, v284_, v285_, v286_, v287_, v278_.maximumCutDiameter, v278_.maximumCutDiameter + HandToolChainsaw.SPLIT_PLANE_OFFSET_Z
end
