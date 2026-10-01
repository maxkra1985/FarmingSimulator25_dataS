WildlifeInstanceGraphics = {}
local WildlifeInstanceGraphics_mt = Class(WildlifeInstanceGraphics)
WildlifeInstanceGraphics.SHADER_OPCODE_NAME = "indicesAndBlend"
WildlifeInstanceGraphics.SHADER_SPEED_NAME = "speeds"
WildlifeInstanceGraphics.SHADER_OFFSET_NAME = "animOffset"
function WildlifeInstanceGraphics.registerXMLPaths(xmlSchema, basePath)
	xmlSchema:register(XMLValueType.STRING, basePath .. ".asset#node", "The filename of the i3d file", nil, true)
	xmlSchema:register(XMLValueType.STRING, basePath .. ".asset#filename", "The filename of the i3d file", nil, true)
	xmlSchema:register(XMLValueType.STRING, basePath .. ".asset.animations#shaderNode", "The index of the shader node within the file", nil, true)
	xmlSchema:register(XMLValueType.INT, basePath .. ".asset.animations.animation(?)#opcode", "The op code for the animation", nil, true)
	xmlSchema:register(XMLValueType.FLOAT, basePath .. ".asset.animations.animation(?)#speed", "The speed for the animation", nil, true)
	xmlSchema:register(XMLValueType.FLOAT, basePath .. ".asset.animations.animation(?)#transitionTime", "The transition time for the animation", nil, true)
	xmlSchema:register(XMLValueType.STRING, basePath .. ".asset.animations.animation(?)#name", "The name of the state required for the animation", nil, true)
end
function WildlifeInstanceGraphics.new(attributes, custom_mt)
	local self = setmetatable({}, custom_mt or WildlifeInstanceGraphics_mt)
	self.attributes = attributes
	self.rootNode = nil
	self.node = nil
	self.shaderNode = nil
	self.sharedLoadRequestId = nil
	self.currentAnimation = nil
	self.nextAnimation = nil
	self.timeOfLastTransition = 0
	self.pendingAnimation = nil
	self.pendingAnimationOffset = nil
	return self
end
function WildlifeInstanceGraphics:load(node)
	self.rootNode = node
	self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.attributes.filename, false, true, self.onI3DLoadingFinished, self)
end
function WildlifeInstanceGraphics:onI3DLoadingFinished(node, failedReason, args)
	if failedReason == LoadI3DFailedReason.NONE then
		self.node = I3DUtil.indexToObject(node, self.attributes.nodeIndex)
		self.shaderNode = I3DUtil.indexToObject(node, self.attributes.shaderNodeIndex)
		link(self.rootNode, self.node)
		delete(node)
		if self.shaderNode ~= nil then
			if self.pendingAnimation ~= nil then
				self:setAnimation(self.pendingAnimation)
				self.pendingAnimation = nil
			end
			if self.pendingAnimationOffset ~= nil then
				self:setAnimationOffset(self.pendingAnimationOffset)
				self.pendingAnimationOffset = nil
			end
		end
	end
end
function WildlifeInstanceGraphics:delete()
	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
		self.sharedLoadRequestId = nil
	end
	if self.node ~= nil then
		delete(self.node)
		self.node = nil
		self.shaderNode = nil
	end
end
function WildlifeInstanceGraphics:update(dt)
	if self.shaderNode == nil then
		return
	end
	if self.nextStateAnimation == nil then
		return
	end
	local timeSinceTransitionStart = g_time - self.timeOfLastTransition
	if self.timeSinceTransitionStart < self.nextStateAnimation.transitionTime then
		local transitionAlpha = math.clamp(timeSinceTransitionStart / self.nextStateAnimation.transitionTime, 0, 1)
		setShaderParameter(self.shaderNode, WildlifeInstanceGraphics.SHADER_OPCODE_NAME, self.currentAnimation.opcode, self.nextStateAnimation.opcode, transitionAlpha, 0, false)
	else
		self:setAnimation(self.nextStateAnimation.stateName)
	end
end
function WildlifeInstanceGraphics:setAnimationOffset(offset)
	if self.shaderNode == nil then
		self.pendingAnimationOffset = offset
	else
		setShaderParameter(self.shaderNode, WildlifeInstanceGraphics.SHADER_OFFSET_NAME, offset, nil, nil, nil, false)
	end
end
function WildlifeInstanceGraphics:setAnimation(animationName, alsoSetTime)
	if self.shaderNode == nil then
		self.pendingAnimation = animationName
	else
		local animation = self.attributes.animations[animationName]
		if animation == nil or animation == self.currentAnimation then
			return
		end
		if alsoSetTime then
			self.timeOfLastTransition = g_time - animation.transitionTime
		end
		self.currentAnimation = animation
		self.nextStateAnimation = nil
		setShaderParameter(self.shaderNode, WildlifeInstanceGraphics.SHADER_OPCODE_NAME, animation.opcode, 0, 0, 0, false)
		setShaderParameter(self.shaderNode, WildlifeInstanceGraphics.SHADER_SPEED_NAME, animation.speed, 0, 0, 0, false)
	end
end
function WildlifeInstanceGraphics:transitionToAnimation(animationName)
	if self.shaderNode == nil then
		self.pendingAnimation = animationName
	else
		local nextAnimation = self.attributes.animations[animationName]
		if nextAnimation == nil or nextAnimation == self.currentAnimation or nextAnimation == self.nextStateAnimation then
			return
		end
		self.nextStateAnimation = nextAnimation
		self.timeOfLastTransition = g_time
		setShaderParameter(self.shaderNode, WildlifeInstanceGraphics.SHADER_OPCODE_NAME, self.currentAnimation.opcode, nextAnimation.opcode, 1, 0, false)
		setShaderParameter(self.shaderNode, WildlifeInstanceGraphics.SHADER_SPEED_NAME, self.currentAnimation.speed, nextAnimation.speed, 0, 0, false)
	end
end
function WildlifeInstanceGraphics:getHasAnimation(animationName)
	local animation = self.attributes.animations[animationName]
	return animation ~= nil
end
function WildlifeInstanceGraphics.loadAttributesTable(xmlFile, key)
	local attributes = {}
	attributes.filename = xmlFile:getValue(key .. ".asset#filename")
	attributes.nodeIndex = xmlFile:getValue(key .. ".asset#node")
	attributes.shaderNodeIndex = xmlFile:getValue(key .. ".asset.animations#shaderNode")
	attributes.animations = {}
	for i, key in xmlFile:iterator(key .. ".asset.animations.animation") do
		local animation = {}
		animation.name = xmlFile:getValue(key .. "#name")
		animation.opcode = xmlFile:getValue(key .. "#opcode")
		animation.speed = xmlFile:getValue(key .. "#speed")
		animation.transitionTime = xmlFile:getValue(key .. "#transitionTime") * 1000
		attributes.animations[animation.name] = animation
	end
	return attributes
end
