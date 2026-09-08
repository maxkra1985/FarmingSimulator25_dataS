-- Local values: AnimationManager_mt
AnimationManager = {}
local AnimationManager_mt = Class(AnimationManager, AbstractManager)

-- Upvalues: AnimationManager_mt
-- Local values: self
function AnimationManager.new(customMt)
	-- upvalues: (copy) AnimationManager_mt
	return AbstractManager.new(customMt or AnimationManager_mt)
end

function AnimationManager:initDataStructures()
	self.runningAnimations = {}
	self.registeredAnimations = {}
	self.registeredAnimationClasses = {}
	self.prevShaderParametersToSet = {}
end

function AnimationManager:registerAnimationClass(className, animationClass)
	if ClassUtil.getIsValidClassName(className) then
		self.registeredAnimationClasses[className] = animationClass
	else
		printError("Error: Invalid animation class name: " .. className)
	end
end

function AnimationManager:getAnimationClass(className)
	return self.registeredAnimationClasses[className]
end

-- Local values: animations, i, key, animationClassName, animationClass, animation, anim, j, otherAnim
function AnimationManager:loadAnimations(xmlFile, baseName, rootNode, parent, i3dMapping, maxUpdateDistance)
	local v16_ = 0
	local v17_ = {}
	while true do
		local v18_ = string.format(baseName .. ".animationNode(%d)", v16_)
		if not xmlFile:hasProperty(v18_) then
			break
		end
		local v19_ = xmlFile:getValue(v18_ .. "#class") or "RotationAnimation"
		local v20_ = self:getAnimationClass(v19_)
		if v20_ == nil then
			if parent.customEnvironment ~= nil and parent.customEnvironment ~= "" then
				v20_ = self:getAnimationClass(parent.customEnvironment .. "." .. v19_)
			end
			if v20_ == nil then
				v20_ = ClassUtil.getClassObject(v19_)
			end
		end
		if v20_ == nil then
			printWarning("Warning: Unknown animation \'" .. v19_ .. "\' in \'" .. Utils.getNoNil(parent.configFileName, parent.xmlFilename) .. "\'")
		else
			local v21_ = v20_.new()
			if v21_ ~= nil then
				local v22_ = v21_:load(xmlFile, v18_, rootNode, parent, i3dMapping)
				if v22_ ~= nil then
					for v23_ = 1, #self.registeredAnimations do
						local v24_ = self.registeredAnimations[v23_]
						if v22_:isDuplicate(v24_) then
							v22_:addDuplicate(v24_)
							v24_:addDuplicate(v22_)
						end
					end
					v22_:setUpdateDistance(maxUpdateDistance or Animation.DEFAULT_UPDATE_DISTANCE)
					table.insert(v17_, v22_)
					local v25_ = self.registeredAnimations
					table.insert(v25_, v22_)
				end
			end
		end
		v16_ = v16_ + 1
	end
	return v17_
end

-- Local values: i, animation
function AnimationManager:deleteAnimations(animations)
	if animations ~= nil then
		for v28_ = #animations, 1, -1 do
			local v29_ = animations[v28_]
			self.runningAnimations[v29_] = nil
			v29_:delete()
			table.remove(animations, v28_)
			table.removeElement(self.registeredAnimations, v29_)
		end
	end
end

-- Local values: index, animation, allowUpdate, effectDt, i, prevShaderParameterData
function AnimationManager:update(dt)
	for v32_, v33_ in pairs(self.runningAnimations) do
		if v33_.maxUpdateDistance == nil then
			v33_:update(dt)
		else
			local v34_ = v33_:getAllowUpdate()
			if v34_ then
				local v35_
				if v33_.allowUpdate then
					v35_ = dt
				else
					v35_ = g_currentMission.time - v33_.lastUpdateTime
				end
				v33_:update(v35_)
				v33_.lastUpdateTime = g_currentMission.time
			end
			v33_.allowUpdate = v34_
		end
		if not v33_:isRunning() then
			self.runningAnimations[v32_] = nil
		end
	end
	for v36_ = 1, #self.prevShaderParametersToSet do
		local v37_ = self.prevShaderParametersToSet[v36_]
		if v37_.isValid and v37_.loopIndex < g_updateLoopIndex then
			if entityExists(v37_.node) then
				setShaderParameter(v37_.node, v37_.parameterNamePrev, v37_.x, v37_.y, v37_.z, v37_.w, v37_.shared)
			end
			v37_.isValid = false
		end
	end
end

-- Local values: _, animation
function AnimationManager:areAnimationsRunning(animations)
	if animations ~= nil then
		for _, v39_ in ipairs(animations) do
			if v39_:isRunning() then
				return true
			end
		end
	end
	return false
end

-- Local values: _, animation
function AnimationManager:startAnimations(animations)
	if animations ~= nil then
		for _, v42_ in ipairs(animations) do
			self:startAnimation(v42_)
		end
	end
end

function AnimationManager:startAnimation(animation)
	if animation ~= nil and animation:start() then
		self.runningAnimations[animation] = animation
	end
end

-- Local values: _, animation
function AnimationManager:stopAnimations(animations)
	if animations ~= nil then
		for _, v47_ in ipairs(animations) do
			self:stopAnimation(v47_)
		end
	end
end

function AnimationManager:stopAnimation(animation)
	if animation.stop == nil then
		printCallstack()
	end
	if animation ~= nil and animation:stop() then
		self.runningAnimations[animation] = animation
	end
end

-- Local values: _, animation
function AnimationManager:resetAnimations(animations)
	if animations ~= nil then
		for _, v52_ in ipairs(animations) do
			self:resetAnimation(v52_)
		end
	end
end

function AnimationManager:resetAnimation(animation)
	if animation ~= nil then
		self.runningAnimations[animation] = nil
		animation:reset()
	end
end

-- Local values: _, animation
function AnimationManager:setFillType(animations, fillType)
	if animations ~= nil then
		for _, v57_ in ipairs(animations) do
			if v57_.setFillType ~= nil then
				v57_:setFillType(fillType)
			end
		end
	end
end

-- Local values: slot, i, prevShaderParameterData
function AnimationManager:setPrevShaderParameter(node, parameterName, x, y, z, w, shared, parameterNamePrev)
	setShaderParameter(node, parameterName, x, y, z, w, shared)
	if x == nil or (y == nil or (z == nil or w == nil)) then
		x, y, z, w = getShaderParameter(node, parameterName)
	end
	local v67_ = nil
	for v68_ = 1, #self.prevShaderParametersToSet do
		local v69_ = self.prevShaderParametersToSet[v68_]
		if v69_.isValid then
			if v69_.loopIndex == g_updateLoopIndex and (v69_.node == node and v69_.parameterNamePrev == parameterNamePrev) then
				v69_.x = x
				v69_.y = y
				v69_.z = z
				v69_.w = w
				return
			end
		else
			v67_ = v69_
		end
	end
	if v67_ == nil then
		v67_ = {}
		local v70_ = self.prevShaderParametersToSet
		table.insert(v70_, v67_)
	end
	v67_.node = node
	v67_.parameterNamePrev = parameterNamePrev
	v67_.x = x
	v67_.y = y
	v67_.z = z
	v67_.w = w
	v67_.shared = shared
	v67_.isValid = true
	v67_.loopIndex = g_updateLoopIndex
end

function AnimationManager.registerAnimationNodesXMLPaths(schema, basePath)
	schema:setXMLSharedRegistration("AnimationNode", basePath)
	schema:register(XMLValueType.STRING, basePath .. ".animationNode(?)#class", "Animation class (RotationAnimation | RotationAnimationSpikes | RotationAnimationSpikesGravity | ScrollingAnimation | ShakeAnimation)", "RotationAnimation")
	RotationAnimation.registerAnimationClassXMLPaths(schema, basePath .. ".animationNode(?)")
	RotationAnimationSpikes.registerAnimationClassXMLPaths(schema, basePath .. ".animationNode(?)")
	RotationAnimationSpikesGravity.registerAnimationClassXMLPaths(schema, basePath .. ".animationNode(?)")
	ScrollingAnimation.registerAnimationClassXMLPaths(schema, basePath .. ".animationNode(?)")
	ShakeAnimation.registerAnimationClassXMLPaths(schema, basePath .. ".animationNode(?)")
	schema:resetXMLSharedRegistration("AnimationNode", basePath)
end
g_animationManager = AnimationManager.new()
