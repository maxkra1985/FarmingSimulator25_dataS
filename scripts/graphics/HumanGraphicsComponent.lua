-- Local values: HumanGraphicsComponent_mt
HumanGraphicsComponent = {}
local HumanGraphicsComponent_mt = Class(HumanGraphicsComponent)
HumanGraphicsComponent.ROTATION_VELOCITY_DAMPENING = 0.025
function HumanGraphicsComponent.new()
	-- upvalues: (copy) HumanGraphicsComponent_mt
	local v2_ = HumanGraphicsComponent_mt
	local v3_ = setmetatable({}, v2_)
	v3_.foliageBendingId = nil
	v3_.foliageBendingNode = nil
	v3_.graphicsRootNode = nil
	v3_.isGraphicsRootNodeVisible = true
	v3_.rightShoulderCameraNode = nil
	v3_.style = PlayerStyle.new()
	v3_.baseStyle = PlayerStyle.new()
	v3_.model = HumanModel.new()
	v3_.model:loadEmpty()
	v3_.nameTagOffsetY = 1.9
	v3_.facialAnimation = nil
	v3_.facialAnimationEnabled = false
	v3_.facialAnimationMinimumDistance = FacialAnimation.MINIMUM_VISIBLE_CAMERA_DISTANCE
	v3_.facialAnimationMaximumDistance = FacialAnimation.MAXIMUM_VISIBLE_CAMERA_DISTANCE
	v3_.postAnimationCallbackHandle = nil
	v3_.sounds = HumanSounds.new()
	v3_.soundsEnabled = true
	local v4_ = ConditionalAnimation.new()
	local v5_ = {
		["absSpeed"] = v4_:registerParameter("absSpeed", ConditionalAnimation.TYPE.FLOAT),
		["relativeVelocityX"] = v4_:registerParameter("relativeVelocityX", ConditionalAnimation.TYPE.FLOAT),
		["relativeVelocityY"] = v4_:registerParameter("relativeVelocityY", ConditionalAnimation.TYPE.FLOAT),
		["relativeVelocityZ"] = v4_:registerParameter("relativeVelocityZ", ConditionalAnimation.TYPE.FLOAT),
		["rotationVelocity"] = v4_:registerParameter("rotationVelocity", ConditionalAnimation.TYPE.FLOAT),
		["movementDirX"] = v4_:registerParameter("movementDirX", ConditionalAnimation.TYPE.FLOAT),
		["movementDirZ"] = v4_:registerParameter("movementDirZ", ConditionalAnimation.TYPE.FLOAT),
		["distanceToGround"] = v4_:registerParameter("distanceToGround", ConditionalAnimation.TYPE.FLOAT),
		["isCloseToGround"] = v4_:registerParameter("isCloseToGround", ConditionalAnimation.TYPE.BOOL),
		["isIdling"] = v4_:registerParameter("isIdling", ConditionalAnimation.TYPE.BOOL),
		["isWalking"] = v4_:registerParameter("isWalking", ConditionalAnimation.TYPE.BOOL),
		["isRunning"] = v4_:registerParameter("isRunning", ConditionalAnimation.TYPE.BOOL),
		["isCrouching"] = v4_:registerParameter("isCrouching", ConditionalAnimation.TYPE.BOOL),
		["isGrounded"] = v4_:registerParameter("isGrounded", ConditionalAnimation.TYPE.BOOL),
		["isInWater"] = v4_:registerParameter("isInWater", ConditionalAnimation.TYPE.BOOL),
		["isSwimming"] = v4_:registerParameter("isSwimming", ConditionalAnimation.TYPE.BOOL),
		["isStrafeWalkMode"] = v4_:registerParameter("isStrafeWalkMode", ConditionalAnimation.TYPE.BOOL),
		["isFirstPerson"] = v4_:registerParameter("isFirstPerson", ConditionalAnimation.TYPE.BOOL),
		["isCutting"] = v4_:registerParameter("isCutting", ConditionalAnimation.TYPE.BOOL),
		["isVerticalCut"] = v4_:registerParameter("isVerticalCut", ConditionalAnimation.TYPE.BOOL),
		["isHoldingChainsaw"] = v4_:registerParameter("isHoldingChainsaw", ConditionalAnimation.TYPE.BOOL),
		["isNPC"] = v4_:registerParameter("isNPC", ConditionalAnimation.TYPE.BOOL)
	}
	v4_:setSpecialParameterIds(v5_.absSpeed, v5_.rotationVelocity)
	v3_.animation = v4_
	v3_.animationParameters = v5_
	v3_.defaultState = HumanGraphicsComponentState.new()
	v3_:defaultAllParameters()
	return v3_
end

function HumanGraphicsComponent:initialize()
	self.graphicsRootNode = createTransformGroup("player_graphicsRootNode")
	link(getRootNode(), self.graphicsRootNode)
	self.rightShoulderCameraNode = createTransformGroup("player_rightShoulderCameraNode")
	link(self.graphicsRootNode, self.rightShoulderCameraNode)
	setTranslation(self.rightShoulderCameraNode, -0.35, 1.675, -0.35)
	self.foliageBendingNode = createTransformGroup("player_foliageBendingNode")
	link(self.graphicsRootNode, self.foliageBendingNode)
end

function HumanGraphicsComponent:show()
	self:setModelVisibility(true)
end

function HumanGraphicsComponent:hide()
	self:setModelVisibility(false)
end

-- Local values: mission
function HumanGraphicsComponent:delete()
	if self:getHasFacialAnimation() then
		self.facialAnimation:delete()
	end
	self.sounds:delete()
	self.animation:delete()
	self.model:delete()
	if self.graphicsRootNode ~= 0 and self.graphicsRootNode ~= nil then
		delete(self.graphicsRootNode)
		self.graphicsRootNode = nil
	end
	local v10_ = g_currentMission
	if v10_ ~= nil and self.foliageBendingId ~= nil then
		v10_.foliageBendingSystem:destroyObject(self.foliageBendingId)
		self.foliageBendingId = nil
	end
end

function HumanGraphicsComponent:getModel()
	return self.model
end

function HumanGraphicsComponent:setModel(model)
	if model.rootNode == nil then
		printCallstack()
		Logging.error("New model is missing root node and cannot be used!")
	else
		if self.model ~= nil and self.model ~= model then
			self.model:delete()
		end
		self.model = model
		link(self.graphicsRootNode, model.rootNode)
		self:loadAnimation()
		self:loadSounds()
		self:setModelVisibility(true)
	end
end

-- Local values: model, skeletonNode, animNode
function HumanGraphicsComponent:loadAnimation()
	self.animation:unload()
	local v15_ = self.model
	local v16_ = v15_:getSkeletonNode()
	if v16_ ~= nil and getNumOfChildren(v16_) > 0 then
		local v17_ = g_animCache:getNode(AnimationCache.CHARACTER)
		self:defaultAllParameters()
		self.animation:load(v16_, v15_.animationFilename, "conditionalAnimation", v17_)
	end
end

function HumanGraphicsComponent:setSoundsEnabled(soundsEnabled)
	self.soundsEnabled = soundsEnabled
end

-- Local values: model
function HumanGraphicsComponent:loadSounds()
	self.sounds:unload()
	if self.soundsEnabled then
		local v21_ = self.model
		if v21_.soundFilename ~= nil then
			self.sounds:load(self.graphicsRootNode, v21_.soundFilename, "humanSounds", v21_.thirdPersonLeftFootNode, v21_.thirdPersonRightFootNode)
		end
	end
end

function HumanGraphicsComponent:getIsFacialAnimationEnabled()
	return self.facialAnimationEnabled
end

function HumanGraphicsComponent:setIsFacialAnimationEnabled(facialAnimationEnabled)
	if self.facialAnimationEnabled == facialAnimationEnabled then
		return
	else
		self.facialAnimationEnabled = facialAnimationEnabled
		if self.facialAnimationEnabled or not self:getHasFacialAnimation() then
			if self.facialAnimationEnabled and not self:getHasFacialAnimation() then
				self.facialAnimation = FacialAnimation.new()
				self.postAnimationCallbackHandle = addPostAnimationCallback(HumanGraphicsComponent.onPostAnimationUpdate, self, nil)
			end
		else
			self.facialAnimation:delete()
			self.facialAnimation = nil
			removePostAnimationCallback(self.postAnimationCallbackHandle)
			self.postAnimationCallbackHandle = nil
		end
	end
end

function HumanGraphicsComponent:getHasFacialAnimation()
	return self.facialAnimation ~= nil
end

function HumanGraphicsComponent:getFacialAnimation()
	return self.facialAnimation
end

-- Local values: currentModel
function HumanGraphicsComponent:getIsInCameraFrustum(camera, aspectRatio)
	local v30_ = self:getModel()
	if v30_ == nil then
		return false
	else
		return v30_:getIsInCameraFrustum(camera, aspectRatio)
	end
end

-- Local values: directionX, directionY, directionZ
function HumanGraphicsComponent:getModelDirection()
	if self.graphicsRootNode == nil then
		return 0, 0, -1
	end
	local v32_, v33_, v34_ = localDirectionToWorld(self.graphicsRootNode, 0, 0, -1)
	return v32_, v33_, v34_
end

-- Local values: directionX, directionY, directionZ, _, yaw
function HumanGraphicsComponent:getModelYaw()
	if self.graphicsRootNode == nil then
		return 0
	end
	local v36_, v37_, v38_ = localDirectionToWorld(self.graphicsRootNode, 0, 0, 1)
	local _, v39_ = MathUtil.directionToPitchYaw(v36_, v37_, v38_)
	return v39_
end

function HumanGraphicsComponent:setModelYaw(yaw)
	local v42_ = MathUtil.getValidLimit(yaw)
	setWorldRotation(self.graphicsRootNode, 0, v42_, 0)
end

function HumanGraphicsComponent:setModelRotation(rx, ry, rz)
	setWorldRotation(self.graphicsRootNode, rx, ry, rz)
end

function HumanGraphicsComponent:setModelPosition(x, y, z)
	setWorldTranslation(self.graphicsRootNode, x, y, z)
end

function HumanGraphicsComponent:getModelVisibility()
	return self.model:getVisibility()
end

-- Local values: useFoliageBending, mission
function HumanGraphicsComponent:setModelVisibility(visibility, overrideFoliageBending)
	self.model:setVisibility(visibility)
	self:setGraphicsRootNodeVisibility(self.isGraphicsRootNodeVisible)
	local v55_ = Utils.getNoNil(overrideFoliageBending, visibility)
	local v56_ = g_currentMission
	if v55_ then
		if self.foliageBendingNode ~= nil and (self.foliageBendingId == nil and (v56_ ~= nil and v56_.foliageBendingSystem)) then
			self.foliageBendingId = v56_.foliageBendingSystem:createRectangle(-0.5, 0.5, -0.5, 0.5, 0.4, self.foliageBendingNode)
			return
		end
	elseif self.foliageBendingId ~= nil then
		v56_.foliageBendingSystem:destroyObject(self.foliageBendingId)
		self.foliageBendingId = nil
	end
end

function HumanGraphicsComponent:setGraphicsRootNodeVisibility(isVisible)
	self.isGraphicsRootNodeVisible = isVisible
	if self.model ~= nil then
		self.model:setParentVisibility(isVisible)
	end
end

function HumanGraphicsComponent:getIsFacialAnimationVisible()
	local v60_ = self:getHasFacialAnimation()
	if v60_ then
		v60_ = self.facialAnimation:getIsVisible()
	end
	return v60_
end

-- Local values: lookAtWeight
function HumanGraphicsComponent:blendFacialAnimation(blendFactor)
	if self:getHasFacialAnimation() then
		self.facialAnimation:setIsVisible(blendFactor > 0)
		if self.model.faceNode ~= nil then
			setVisibility(self.model.faceNode, blendFactor <= 0)
		end
		local v63_ = math.clamp(blendFactor, 0, 1)
		self.facialAnimation:setLookAtWeight(v63_)
	else
		self.model:showHead()
	end
end

function HumanGraphicsComponent:updateFacialAnimationEmotions()
	if not self:getHasFacialAnimation() then
	end
end

-- Local values: blendFactor
function HumanGraphicsComponent:updateFacialAnimationVisibilityFromCameraDistance(cameraDistance)
	self:blendFacialAnimation((cameraDistance - self.facialAnimationMinimumDistance) / (self.facialAnimationMinimumDistance - self.facialAnimationMaximumDistance))
end

-- Local values: preset, tempStyle
function HumanGraphicsComponent:applyCustomWorkStyle(presetName, isOwner)
	local v70_
	if string.isNilOrWhitespace(presetName) then
		v70_ = nil
	else
		v70_ = self.style:getPresetByName(presetName)
	end
	if v70_ == nil then
		self:setStyleAsync(self.baseStyle, nil, nil, nil, false, nil, isOwner)
	else
		local v71_ = PlayerStyle.new()
		v71_:copyConfigurationFrom(self.baseStyle)
		v70_:applyToStyle(v71_)
		self:setStyleAsync(v71_, nil, nil, nil, true, nil, isOwner)
	end
end

function HumanGraphicsComponent:getStyle(currentStyle)
	if currentStyle then
		return self.style
	else
		return self.baseStyle or self.style
	end
end

function HumanGraphicsComponent:setStyle(style, isTempStyle)
	self.style:copyFrom(style)
	if not isTempStyle then
		self.baseStyle:copyFrom(style)
	end
end

-- Local values: onFinishedFacialAnimationCallback, onStyleLoadedCallback, onModelLoadedCallback
function HumanGraphicsComponent:setStyleAsync(style, callback, callbackObject, callbackArgs, isTempStyle, xmlFile, isOwner)
	local function v_u_88_(_, p85_, p86_)
		-- upvalues: (copy) self, (copy) callback, (copy) callbackObject, (copy) callbackArgs
		if not p85_ and self.facialAnimation ~= nil then
			self.facialAnimation:delete()
			self.facialAnimation = nil
		end
		local v87_ = p86_.loadingState
		if v87_ == HumanModelLoadingState.OK and self.graphicsRootNode ~= nil then
			self:setGraphicsRootNodeVisibility(self.isGraphicsRootNodeVisible)
		end
		if callback ~= nil then
			callback(callbackObject, v87_, p86_.loadedNewPlayerModel, callbackArgs)
		end
	end
	local function v_u_93_(p89_, p90_, p91_)
		-- upvalues: (copy) self, (copy) style, (copy) v_u_88_
		p91_.loadingState = p90_
		local v92_
		if self:getIsFacialAnimationEnabled() then
			v92_ = self.facialAnimation:loadFromStyleAsync(style, self.model, v_u_88_, p89_, p91_)
		else
			v92_ = false
		end
		if not v92_ then
			if self.facialAnimation ~= nil then
				self.facialAnimation:delete()
				self.facialAnimation = nil
			end
			v_u_88_(p89_, true, p91_)
		end
	end
	if self.graphicsRootNode ~= nil then
		self:setGraphicsRootNodeVisibility(self.isGraphicsRootNodeVisible)
	end
	if self.model.xmlFilename == style.xmlFilename then
		self:setStyle(style, isTempStyle)
		self.model:loadFromStyleAsync(self.style, v_u_93_, nil, {
			["loadedNewPlayerModel"] = false
		})
		return
	else
		self:setStyle(style, isTempStyle)
		local function v95_(_, p94_, _)
			-- upvalues: (copy) style, (copy) self, (copy) v_u_93_
			if p94_ == HumanModelLoadingState.OK then
				self:setModel(self.model)
				self.model:loadFromStyleAsync(self.style, v_u_93_, nil, {
					["loadedNewPlayerModel"] = true
				})
			else
				Logging.warning("Player model could not be loaded from " .. style.xmlFilename)
			end
		end
		if xmlFile == nil then
			self.model:load(style.xmlFilename, true, isOwner, true, v95_)
		else
			self.model:loadFromXMLFileAsync(xmlFile, true, isOwner, true, v95_)
		end
	end
end

-- Local values: targetPositionX, targetPositionY, targetPositionZ, shoulderCameraPositionX, shoulderCameraPositionY, shoulderCameraPositionZ, targetShoulderDirectionX, targetShoulderDirectionY, targetShoulderDirectionZ
function HumanGraphicsComponent:pointRightShoulderCameraNodeAt(node)
	local v98_, v99_, v100_ = getWorldTranslation(node)
	local v101_, v102_, v103_ = getWorldTranslation(self.rightShoulderCameraNode)
	local v104_, v105_, v106_ = MathUtil.vector3Normalize(v101_ - v98_, v102_ - v99_, v103_ - v100_)
	setWorldDirection(self.rightShoulderCameraNode, v104_, v105_, v106_, 0, 1, 0)
end

function HumanGraphicsComponent:update(dt)
	self.animation:update(dt)
	self.sounds:update(dt)
	if self:getHasFacialAnimation() then
		self.facialAnimation:update(dt)
		self:updateFacialAnimationEmotions()
	end
end

-- Local values: animation, parameters
function HumanGraphicsComponent:applyState(state)
	local v111_ = self.animation
	local v112_ = self.animationParameters
	v111_:setParameter(v112_.absSpeed, state.absSpeed)
	v111_:setParameter(v112_.relativeVelocityX, state.relativeVelocityX)
	v111_:setParameter(v112_.relativeVelocityY, state.relativeVelocityY)
	v111_:setParameter(v112_.relativeVelocityZ, state.relativeVelocityZ)
	v111_:setParameter(v112_.rotationVelocity, state.rotationVelocity)
	v111_:setParameter(v112_.movementDirX, state.movementDirX)
	v111_:setParameter(v112_.movementDirZ, state.movementDirZ)
	v111_:setParameter(v112_.distanceToGround, state.distanceToGround)
	v111_:setParameter(v112_.isCloseToGround, state.isCloseToGround)
	v111_:setParameter(v112_.isIdling, state.isIdling)
	v111_:setParameter(v112_.isWalking, state.isWalking)
	v111_:setParameter(v112_.isRunning, state.isRunning)
	v111_:setParameter(v112_.isCrouching, state.isCrouching)
	v111_:setParameter(v112_.isGrounded, state.isGrounded)
	v111_:setParameter(v112_.isInWater, state.isInWater)
	v111_:setParameter(v112_.isSwimming, state.isSwimming)
	v111_:setParameter(v112_.isStrafeWalkMode, state.isStrafeWalkMode)
	v111_:setParameter(v112_.isFirstPerson, state.isFirstPerson)
	v111_:setParameter(v112_.isCutting, state.isCutting)
	v111_:setParameter(v112_.isVerticalCut, state.isVerticalCut)
	v111_:setParameter(v112_.isHoldingChainsaw, state.isHoldingChainsaw)
	v111_:setParameter(v112_.isNPC, state.isNPC)
	self.sounds:applyState(state)
end

function HumanGraphicsComponent:onPostAnimationUpdate(dt)
	if self:getHasFacialAnimation() then
		if self.facialAnimation.headNode ~= nil and self.model.thirdPersonHeadNode ~= nil then
			setTranslation(self.model.thirdPersonHeadNode, getTranslation(self.facialAnimation.headNode))
			setRotation(self.model.thirdPersonHeadNode, getRotation(self.facialAnimation.headNode))
			setTranslation(self.facialAnimation.neckNode, 0, 0, 0)
		end
	else
		return
	end
end

function HumanGraphicsComponent:defaultAllParameters()
	self:applyState(self.defaultState)
end

-- Local values: directionX, directionY, directionZ, _, yaw
function HumanGraphicsComponent:debugDraw(x, y, textSize, debugDrawModel)
	if (debugDrawModel or debugDrawModel == nil) and self.model ~= nil then
		self.model:debugDraw(x, y, textSize)
	end
	DebugUtil.drawDebugNode(self.graphicsRootNode, "Graphics", false, 0)
	DebugUtil.drawDebugNode(self.rightShoulderCameraNode, "ShoulderCam", false, 0)
	local v120_ = DebugUtil.renderTextLine(x, y, textSize * 1.5, "HumanGraphicsComponent", nil, true)
	local v121_, v122_, v123_ = localDirectionToWorld(self.graphicsRootNode, 0, 0, 1)
	local _, v124_ = MathUtil.directionToPitchYaw(v121_, v122_, v123_)
	local v125_ = DebugUtil.renderTextLine(x, v120_, textSize, string.format("Rotation: %.4f", v124_), nil, true)
	return self.style:debugDraw(x, v125_, textSize)
end

function HumanGraphicsComponent:debugDrawAnimator(x, y, textSize)
	self.animation:debugDraw(x, y, textSize)
end
