FacialAnimation = {}
local FacialAnimation_mt = Class(FacialAnimation)
FacialAnimation.MINIMUM_VISIBLE_CAMERA_DISTANCE = 15
FacialAnimation.MAXIMUM_VISIBLE_CAMERA_DISTANCE = 20
function FacialAnimation.new(customMt)
	local self = setmetatable({}, customMt or FacialAnimation_mt)
	self.visualFilename = nil
	self.expressionFilename = nil
	self.emotionFilename = nil
	self.skeletonRootNodePath = nil
	self.visualNode = nil
	self.spineNode = nil
	self.rootNode = nil
	self.skeletonRootNode = nil
	self.lookAtNode = nil
	self.neckNode = nil
	self.headNode = nil
	self.facialAnimationPlayer = nil
	self.audioSample = nil
	self.isVisible = false
	return self
end
function FacialAnimation:loadFromStyleAsync(playerStyle, model, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	local selectedFace = playerStyle.configs.face:getSelectedItem()
	if selectedFace == nil then
		Logging.warning("Could not load facial animation as the style has no face!")
		return false
	elseif selectedFace.visualFilename == nil then
		return false
	elseif string.isNilOrWhitespace(selectedFace.expressionsFilename) then
		Logging.warning("Could not load facial animation as the face config has no expressions filename! Face name: %q", selectedFace.name)
		return false
	else
		self:cleanup()
		self.visualFilename = Utils.getFilename(selectedFace.visualFilename, model.baseDirectory)
		self.expressionFilename = Utils.getFilename(selectedFace.expressionsFilename, model.baseDirectory)
		self.skeletonRootNodePath = selectedFace.skeletonNodePath
		local asyncCallbackData = { asyncCallbackFunction = asyncCallbackFunction, asyncCallbackObject = asyncCallbackObject, asyncCallbackArguments = asyncCallbackArguments, model = model }
		self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.visualFilename, false, false, self.onVisualsLoaded, self, asyncCallbackData)
		return true
	end
end
function FacialAnimation:onVisualsLoaded(i3dNode, failedReason, args)
	if failedReason ~= LoadI3DFailedReason.NONE then
		Logging.warning("Failed to load facial animations i3d file! %q", I3DManager.getFailedReasonName(failedReason))
		if args.asyncCallbackFunction ~= nil then
			args.asyncCallbackFunction(args.asyncCallbackObject, false, args.asyncCallbackArguments)
		end
		return
	end
	self.skeletonRootNode = I3DUtil.indexToObject(i3dNode, self.skeletonRootNodePath)
	if self.skeletonRootNode == nil then
		Logging.warning("Could not load skeleton node %q for facial animation", tostring(self.skeletonRootNodePath))
		if args.asyncCallbackFunction ~= nil then
			args.asyncCallbackFunction(args.asyncCallbackObject, false, args.asyncCallbackArguments)
		end
	elseif getAnimCharacterSet(self.skeletonRootNode) == 0 then
		Logging.warning("Invalid skeleton node %q for facial animation, missing anim character set", I3DUtil.getNodePath(self.skeletonRootNode))
	else
		self.visualNode = i3dNode
		self.spineNode = getChildAt(self.visualNode, 1)
		self.neckNode = getChildAt(self.spineNode, 0)
		self.headNode = getChildAt(self.neckNode, 0)
		self.headFocusNode = createTransformGroup("npcHeadFocusNode")
		local animPlayer = createFacialAnimPlayer("facialAnimation", self.skeletonRootNode, self.expressionFilename)
		if animPlayer ~= nil then
			if animPlayer ~= 0 then
				self.facialAnimationPlayer = animPlayer
				self:updatePlayer()
				self:setLookAtNode(self.lookAtNode)
			else
				Logging.warning("Could not initialize facial animation")
			end
		end
		self:linkToModel(args.model)
		if args.asyncCallbackFunction ~= nil then
			args.asyncCallbackFunction(args.asyncCallbackObject, true, args.asyncCallbackArguments)
		end
	end
end
function FacialAnimation:linkToModel(model)
	if self.visualNode == nil or model == nil then
		return
	end
	local prefixName = function(node)
		setName(node, "facialAnimation_" .. getName(node))
	end
	I3DUtil.iterateRecursively(self.visualNode, prefixName, true)
	if model.i3dMappings.geo == nil then
		Logging.error("Human model is missing geo node i3d mapping!")
	elseif model.i3dMappings.head == nil then
		Logging.error("Human model is missing head node i3d mapping!")
	else
		local modelGeoNode = model.i3dMappings.geo.nodeId
		local modelHeadNode = model.i3dMappings.head.nodeId
		local modelNeckNode = getParent(modelHeadNode)
		local modelSpine2Node = getParent(modelNeckNode)
		link(modelSpine2Node, self.spineNode)
		setTranslation(self.spineNode, 0, 0, 0)
		setRotation(self.spineNode, 0, 0, 0)
		link(modelNeckNode, self.neckNode)
		setTranslation(self.neckNode, 0, 0, 0)
		setRotation(self.neckNode, 0, 0, 0)
		link(modelNeckNode, self.headNode)
		setTranslation(self.headNode, getTranslation(modelHeadNode))
		setRotation(self.headNode, getRotation(modelHeadNode))
		link(modelGeoNode, self.visualNode)
		link(modelGeoNode, self.headFocusNode)
		setTranslation(self.headFocusNode, 0, 1.75, 0)
		setVisibility(self.visualNode, self.isVisible)
	end
end
function FacialAnimation:delete()
	self:cleanup()
end
function FacialAnimation:cleanup()
	if self.facialAnimationPlayer ~= nil then
		delete(self.facialAnimationPlayer)
		self.facialAnimationPlayer = nil
	end
	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
		self.sharedLoadRequestId = nil
	end
	if self.visualNode ~= nil then
		delete(self.visualNode)
		self.visualNode = nil
	end
	if self.spineNode ~= nil then
		delete(self.spineNode)
		self.spineNode = nil
		self.neckNode = nil
		self.headNode = nil
	end
end
function FacialAnimation:update(dt)
	if not self.isVisible or self.facialAnimationPlayer == nil then
		return
	end
	local playTime = 0
	if self.isRunning and self.audioSample ~= nil then
		playTime = g_soundManager:getSamplePlayOffset(self.audioSample)
	end
	setFacialAnimTime(self.facialAnimationPlayer, playTime)
end
function FacialAnimation:getIsVisible()
	return self.isVisible
end
function FacialAnimation:setIsVisible(isVisible)
	if self.isVisible == isVisible then
		return
	else
		self.isVisible = isVisible
		if self.visualNode ~= nil then
			setVisibility(self.visualNode, isVisible)
		end
		if self.spineNode ~= nil then
			setVisibility(self.spineNode, isVisible)
		end
	end
end
function FacialAnimation:updatePlayer()
	local facialAnimationPlayer = self.facialAnimationPlayer
	if facialAnimationPlayer == nil then
		return
	else
		if self.isRunning then
			local emotionFilename = self.emotionFilename
			if emotionFilename ~= nil then
				local success = setFacialAnimSchedule(facialAnimationPlayer, emotionFilename)
				if not success then
					Logging.warning("FacialAnimation: Could not load emotions '%s'", emotionFilename)
				end
			end
		end
	end
end
function FacialAnimation:setLookAtNode(node)
	self.lookAtNode = node
	if self.facialAnimationPlayer ~= nil then
		setFacialAnimLookAt(self.facialAnimationPlayer, node or 0)
	end
end
function FacialAnimation:reset()
	if self.facialAnimationPlayer ~= nil then
		resetFacialAnim(self.facialAnimationPlayer)
		self:setLookAtNode(nil)
	end
end
function FacialAnimation:start(emotionFilename, audioSample, plainText, focusNode)
	self.audioSample = audioSample
	self.emotionFilename = emotionFilename
	self.plainText = plainText
	Logging.devInfo("FacialAnimation:start - Emotions: '%s' - AudioSample: '%s'", emotionFilename, audioSample and audioSample.soundSample or "nil")
	if self.emotionFilename ~= nil then
		self.isRunning = true
	end
	self:setLookAtNode(focusNode or g_cameraManager:getActiveCamera())
	self:updatePlayer()
end
function FacialAnimation:stop()
	self.emotionFilename = nil
	self.audioSample = nil
	self.isRunning = false
	self:updatePlayer()
end
function FacialAnimation:getIsEmotionActive(emotion)
	local emotion1 = nil
	local emotion2 = nil
	local emotion3 = nil
	local emotion4 = nil
	if self.facialAnimationPlayer ~= nil then
		emotion1, emotion2, emotion3, emotion4 = getFacialAnimCurrentEmotions(self.facialAnimationPlayer)
	end
	return emotion1 == emotion or emotion2 == emotion or emotion3 == emotion or emotion4 == emotion
end
function FacialAnimation:getIsTalking()
	if self.facialAnimationPlayer ~= nil then
		local isSilent, _, _ = isFacialAnimSilent(self.facialAnimationPlayer)
		return not isSilent
	else
		return false
	end
end
function FacialAnimation:setLookAtWeight(weight)
	if self.facialAnimationPlayer ~= nil then
		setFacialAnimLookAtWeight(self.facialAnimationPlayer, weight)
	end
end
