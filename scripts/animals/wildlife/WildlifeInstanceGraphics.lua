-- Local values: WildlifeInstanceGraphics_mt
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

-- Upvalues: WildlifeInstanceGraphics_mt
-- Local values: self
function WildlifeInstanceGraphics.new(attributes, custom_mt)
	-- upvalues: (copy) WildlifeInstanceGraphics_mt
	local v6_ = custom_mt or WildlifeInstanceGraphics_mt
	local v7_ = setmetatable({}, v6_)
	v7_.attributes = attributes
	v7_.rootNode = nil
	v7_.node = nil
	v7_.shaderNode = nil
	v7_.sharedLoadRequestId = nil
	v7_.currentAnimation = nil
	v7_.nextAnimation = nil
	v7_.timeOfLastTransition = 0
	v7_.pendingAnimation = nil
	v7_.pendingAnimationOffset = nil
	return v7_
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

-- Local values: timeSinceTransitionStart, transitionAlpha
function WildlifeInstanceGraphics:update(dt)
	if self.shaderNode == nil then
		return
	elseif self.nextStateAnimation == nil then
		return
	else
		local v15_ = g_time - self.timeOfLastTransition
		if self.timeSinceTransitionStart < self.nextStateAnimation.transitionTime then
			local v16_ = v15_ / self.nextStateAnimation.transitionTime
			local v17_ = math.clamp(v16_, 0, 1)
			setShaderParameter(self.shaderNode, WildlifeInstanceGraphics.SHADER_OPCODE_NAME, self.currentAnimation.opcode, self.nextStateAnimation.opcode, v17_, 0, false)
		else
			self:setAnimation(self.nextStateAnimation.stateName)
		end
	end
end

function WildlifeInstanceGraphics:setAnimationOffset(offset)
	if self.shaderNode == nil then
		self.pendingAnimationOffset = offset
	else
		setShaderParameter(self.shaderNode, WildlifeInstanceGraphics.SHADER_OFFSET_NAME, offset, nil, nil, nil, false)
	end
end

-- Local values: animation
function WildlifeInstanceGraphics:setAnimation(animationName, alsoSetTime)
	if self.shaderNode == nil then
		self.pendingAnimation = animationName
		return
	else
		local v23_ = self.attributes.animations[animationName]
		if v23_ ~= nil and v23_ ~= self.currentAnimation then
			if alsoSetTime then
				self.timeOfLastTransition = g_time - v23_.transitionTime
			end
			self.currentAnimation = v23_
			self.nextStateAnimation = nil
			setShaderParameter(self.shaderNode, WildlifeInstanceGraphics.SHADER_OPCODE_NAME, v23_.opcode, 0, 0, 0, false)
			setShaderParameter(self.shaderNode, WildlifeInstanceGraphics.SHADER_SPEED_NAME, v23_.speed, 0, 0, 0, false)
		end
	end
end

-- Local values: nextAnimation
function WildlifeInstanceGraphics:transitionToAnimation(animationName)
	if self.shaderNode == nil then
		self.pendingAnimation = animationName
		return
	else
		local v26_ = self.attributes.animations[animationName]
		if v26_ ~= nil and (v26_ ~= self.currentAnimation and v26_ ~= self.nextStateAnimation) then
			self.nextStateAnimation = v26_
			self.timeOfLastTransition = g_time
			setShaderParameter(self.shaderNode, WildlifeInstanceGraphics.SHADER_OPCODE_NAME, self.currentAnimation.opcode, v26_.opcode, 1, 0, false)
			setShaderParameter(self.shaderNode, WildlifeInstanceGraphics.SHADER_SPEED_NAME, self.currentAnimation.speed, v26_.speed, 0, 0, false)
		end
	end
end

-- Local values: animation
function WildlifeInstanceGraphics:getHasAnimation(animationName)
	return self.attributes.animations[animationName] ~= nil
end

-- Local values: attributes, i, key, animation
function WildlifeInstanceGraphics.loadAttributesTable(xmlFile, key)
	local v31_ = {
		["filename"] = xmlFile:getValue(key .. ".asset#filename"),
		["nodeIndex"] = xmlFile:getValue(key .. ".asset#node"),
		["shaderNodeIndex"] = xmlFile:getValue(key .. ".asset.animations#shaderNode"),
		["animations"] = {}
	}
	for _, v32_ in xmlFile:iterator(key .. ".asset.animations.animation") do
		local v33_ = {
			["name"] = xmlFile:getValue(v32_ .. "#name"),
			["opcode"] = xmlFile:getValue(v32_ .. "#opcode"),
			["speed"] = xmlFile:getValue(v32_ .. "#speed"),
			["transitionTime"] = xmlFile:getValue(v32_ .. "#transitionTime") * 1000
		}
		v31_.animations[v33_.name] = v33_
	end
	return v31_
end
