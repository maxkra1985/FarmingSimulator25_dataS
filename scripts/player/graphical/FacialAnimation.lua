-- Local values: FacialAnimation_mt
FacialAnimation = {}
local FacialAnimation_mt = Class(FacialAnimation)
FacialAnimation.MINIMUM_VISIBLE_CAMERA_DISTANCE = 15
FacialAnimation.MAXIMUM_VISIBLE_CAMERA_DISTANCE = 20

-- Upvalues: FacialAnimation_mt
-- Local values: self
function FacialAnimation.new(customMt)
	-- upvalues: (copy) FacialAnimation_mt
	local v3_ = customMt or FacialAnimation_mt
	local v4_ = setmetatable({}, v3_)
	v4_.visualFilename = nil
	v4_.expressionFilename = nil
	v4_.emotionFilename = nil
	v4_.skeletonRootNodePath = nil
	v4_.visualNode = nil
	v4_.spineNode = nil
	v4_.rootNode = nil
	v4_.skeletonRootNode = nil
	v4_.lookAtNode = nil
	v4_.neckNode = nil
	v4_.headNode = nil
	v4_.facialAnimationPlayer = nil
	v4_.audioSample = nil
	v4_.isVisible = false
	return v4_
end

-- Local values: selectedFace, asyncCallbackData
function FacialAnimation:loadFromStyleAsync(playerStyle, model, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	local v11_ = playerStyle.configs.face:getSelectedItem()
	if v11_ == nil then
		Logging.warning("Could not load facial animation as the style has no face!")
		return false
	end
	if v11_.visualFilename == nil then
		return false
	end
	if string.isNilOrWhitespace(v11_.expressionsFilename) then
		Logging.warning("Could not load facial animation as the face config has no expressions filename! Face name: %q", v11_.name)
		return false
	end
	self:cleanup()
	self.visualFilename = Utils.getFilename(v11_.visualFilename, model.baseDirectory)
	self.expressionFilename = Utils.getFilename(v11_.expressionsFilename, model.baseDirectory)
	self.skeletonRootNodePath = v11_.skeletonNodePath
	self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.visualFilename, false, false, self.onVisualsLoaded, self, {
		["asyncCallbackFunction"] = asyncCallbackFunction,
		["asyncCallbackObject"] = asyncCallbackObject,
		["asyncCallbackArguments"] = asyncCallbackArguments,
		["model"] = model
	})
	return true
end

-- Local values: animPlayer
function FacialAnimation:onVisualsLoaded(i3dNode, failedReason, args)
	if failedReason == LoadI3DFailedReason.NONE then
		self.skeletonRootNode = I3DUtil.indexToObject(i3dNode, self.skeletonRootNodePath)
		if self.skeletonRootNode == nil then
			local v16_ = Logging.warning
			local v17_ = self.skeletonRootNodePath
			v16_("Could not load skeleton node %q for facial animation", (tostring(v17_)))
			if args.asyncCallbackFunction ~= nil then
				args.asyncCallbackFunction(args.asyncCallbackObject, false, args.asyncCallbackArguments)
			end
			return
		elseif getAnimCharacterSet(self.skeletonRootNode) == 0 then
			Logging.warning("Invalid skeleton node %q for facial animation, missing anim character set", I3DUtil.getNodePath(self.skeletonRootNode))
		else
			self.visualNode = i3dNode
			self.spineNode = getChildAt(self.visualNode, 1)
			self.neckNode = getChildAt(self.spineNode, 0)
			self.headNode = getChildAt(self.neckNode, 0)
			self.headFocusNode = createTransformGroup("npcHeadFocusNode")
			local v18_ = createFacialAnimPlayer("facialAnimation", self.skeletonRootNode, self.expressionFilename)
			if v18_ == nil or v18_ == 0 then
				Logging.warning("Could not initialize facial animation")
			else
				self.facialAnimationPlayer = v18_
				self:updatePlayer()
				self:setLookAtNode(self.lookAtNode)
			end
			self:linkToModel(args.model)
			if args.asyncCallbackFunction ~= nil then
				args.asyncCallbackFunction(args.asyncCallbackObject, true, args.asyncCallbackArguments)
			end
		end
	else
		Logging.warning("Failed to load facial animations i3d file! %q", I3DManager.getFailedReasonName(failedReason))
		if args.asyncCallbackFunction ~= nil then
			args.asyncCallbackFunction(args.asyncCallbackObject, false, args.asyncCallbackArguments)
		end
		return
	end
end

-- Local values: prefixName, modelGeoNode, modelHeadNode, modelNeckNode, modelSpine2Node
function FacialAnimation:linkToModel(model)
	if self.visualNode == nil or model == nil then
		return
	else
		I3DUtil.iterateRecursively(self.visualNode, function(p21_)
			setName(p21_, "facialAnimation_" .. getName(p21_))
		end, true)
		if model.i3dMappings.geo == nil then
			Logging.error("Human model is missing geo node i3d mapping!")
			return
		elseif model.i3dMappings.head == nil then
			Logging.error("Human model is missing head node i3d mapping!")
		else
			local v22_ = model.i3dMappings.geo.nodeId
			local v23_ = model.i3dMappings.head.nodeId
			local v24_ = getParent(v23_)
			local v25_ = getParent(v24_)
			link(v25_, self.spineNode)
			setTranslation(self.spineNode, 0, 0, 0)
			setRotation(self.spineNode, 0, 0, 0)
			link(v24_, self.neckNode)
			setTranslation(self.neckNode, 0, 0, 0)
			setRotation(self.neckNode, 0, 0, 0)
			link(v24_, self.headNode)
			setTranslation(self.headNode, getTranslation(v23_))
			setRotation(self.headNode, getRotation(v23_))
			link(v22_, self.visualNode)
			link(v22_, self.headFocusNode)
			setTranslation(self.headFocusNode, 0, 1.75, 0)
			setVisibility(self.visualNode, self.isVisible)
		end
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

-- Local values: playTime
function FacialAnimation:update(dt)
	if self.isVisible and self.facialAnimationPlayer ~= nil then
		local v29_ = (not self.isRunning or self.audioSample == nil) and 0 or g_soundManager:getSamplePlayOffset(self.audioSample)
		setFacialAnimTime(self.facialAnimationPlayer, v29_)
	end
end

function FacialAnimation:getIsVisible()
	return self.isVisible
end

function FacialAnimation:setIsVisible(isVisible)
	if self.isVisible ~= isVisible then
		self.isVisible = isVisible
		if self.visualNode ~= nil then
			setVisibility(self.visualNode, isVisible)
		end
		if self.spineNode ~= nil then
			setVisibility(self.spineNode, isVisible)
		end
	end
end

-- Local values: facialAnimationPlayer, emotionFilename, success
function FacialAnimation:updatePlayer()
	local v34_ = self.facialAnimationPlayer
	if v34_ ~= nil then
		if self.isRunning then
			local v35_ = self.emotionFilename
			if v35_ ~= nil and not setFacialAnimSchedule(v34_, v35_) then
				Logging.warning("FacialAnimation: Could not load emotions \'%s\'", v35_)
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
	Logging.devInfo("FacialAnimation:start - Emotions: \'%s\' - AudioSample: \'%s\'", emotionFilename, audioSample and audioSample.soundSample or "nil")
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

-- Local values: emotion1, emotion2, emotion3, emotion4
function FacialAnimation:getIsEmotionActive(emotion)
	local v47_, v48_, v49_, v50_
	if self.facialAnimationPlayer == nil then
		v47_ = nil
		v48_ = nil
		v49_ = nil
		v50_ = nil
	else
		v47_, v48_, v49_, v50_ = getFacialAnimCurrentEmotions(self.facialAnimationPlayer)
	end
	return (v47_ == emotion or (v48_ == emotion or v49_ == emotion)) and true or v50_ == emotion
end

-- Local values: isSilent, _, _
function FacialAnimation:getIsTalking()
	if self.facialAnimationPlayer == nil then
		return false
	end
	local v52_, _, _ = isFacialAnimSilent(self.facialAnimationPlayer)
	return not v52_
end

function FacialAnimation:setLookAtWeight(weight)
	if self.facialAnimationPlayer ~= nil then
		setFacialAnimLookAtWeight(self.facialAnimationPlayer, weight)
	end
end
