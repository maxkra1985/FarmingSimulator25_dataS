-- Local values: ScrollingAnimation_mt
ScrollingAnimation = {}
ScrollingAnimation.STATE_OFF = 0
ScrollingAnimation.STATE_ON = 1
ScrollingAnimation.STATE_TURNING_OFF = 2
local ScrollingAnimation_mt = Class(ScrollingAnimation, Animation)

-- Upvalues: ScrollingAnimation_mt
-- Local values: self
function ScrollingAnimation.new(customMt)
	-- upvalues: (copy) ScrollingAnimation_mt
	local v3_ = Animation.new(customMt or ScrollingAnimation_mt)
	v3_.state = ScrollingAnimation.STATE_OFF
	v3_.nodes = {}
	v3_.shaderParameterName = nil
	v3_.scrollPosition = 0
	v3_.scrollSpeed = 0
	v3_.scrollLength = 1
	v3_.shaderParameterComponent = 1
	v3_.currentAlpha = 0
	v3_.currentScroll = 0
	v3_.initialTurnOnFadeTime = 1000
	v3_.turnOnOffVariance = nil
	v3_.turnOnFadeTime = 0
	v3_.turnOffFadeTime = 0
	v3_.owner = nil
	return v3_
end

-- Local values: node, _, nodeKey, speedScale, scrollSpeed, node, _, node, _, prevName, fillTypeStr, speedFuncStr
function ScrollingAnimation:load(xmlFile, key, rootNodes, owner, i3dMapping)
	if not xmlFile:hasProperty(key) then
		return nil
	end
	self.owner = owner
	self.scrollSpeed = xmlFile:getValue(key .. "#scrollSpeed", 1) * 0.001
	local v10_ = xmlFile:getValue(key .. "#node", nil, rootNodes, i3dMapping)
	if v10_ ~= nil then
		self.nodes[v10_] = 1
	end
	for _, v11_ in xmlFile:iterator(key .. ".node") do
		local v12_ = xmlFile:getValue(v11_ .. "#node", nil, rootNodes, i3dMapping)
		if v12_ ~= nil then
			local v13_ = xmlFile:getValue(v11_ .. "#speedScale", 1)
			local v14_ = xmlFile:getValue(v11_ .. "#scrollSpeed")
			if v14_ ~= nil then
				v13_ = v13_ * (v14_ * 0.001) / self.scrollSpeed
			end
			self.nodes[v12_] = v13_
		end
	end
	if table.size(self.nodes) == 0 then
		Logging.xmlWarning(xmlFile, "Missing node(s) for rotation animation \'%s\'!", key)
		return nil
	end
	self.rootNode = next(self.nodes)
	self.shaderParameterName = xmlFile:getValue(key .. "#shaderParameterName", "offsetUV")
	self.shaderParameterPrevName = xmlFile:getValue(key .. "#shaderParameterPrevName")
	for v15_, _ in pairs(self.nodes) do
		if not getHasShaderParameter(v15_, self.shaderParameterName) then
			Logging.xmlWarning(xmlFile, "Node \'%s\' has no shader parameter \'%s\' for animationNode \'%s\'!", getName(v15_), self.shaderParameterName, key)
			return nil
		end
	end
	if self.shaderParameterPrevName == nil then
		local v16_ = string.upper
		local v17_ = self.shaderParameterName
		local v18_ = v16_((string.sub(v17_, 1, 1)))
		local v19_ = self.shaderParameterName
		local v20_ = "prev" .. v18_ .. string.sub(v19_, 2)
		if getHasShaderParameter(self.rootNode, v20_) then
			self.shaderParameterPrevName = v20_
		end
	else
		for v21_, _ in pairs(self.nodes) do
			if not getHasShaderParameter(v21_, self.shaderParameterPrevName) then
				Logging.xmlWarning(xmlFile, "Node \'%s\' has no shader parameter \'%s\' (prev) for animationNode \'%s\'!", getName(v21_), self.shaderParameterPrevName, key)
				return nil
			end
		end
	end
	local v22_ = xmlFile:getValue(key .. "#type")
	if v22_ ~= nil then
		self.fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(v22_)
	end
	self.scrollLength = xmlFile:getValue(key .. "#scrollLength", 1)
	self.shaderParameterComponent = xmlFile:getValue(key .. "#shaderParameterComponent", 1)
	local v23_ = xmlFile:getValue(key .. "#turnOnFadeTime", 2) * 1000
	self.turnOnFadeTime = math.max(v23_, 1)
	local v24_ = xmlFile:getValue(key .. "#turnOffFadeTime", 2) * 1000
	self.turnOffFadeTime = math.max(v24_, 1)
	self.turnOnOffVariance = xmlFile:getValue(key .. "#turnOnOffVariance")
	if self.turnOnOffVariance ~= nil then
		self.initialTurnOnFadeTime = self.turnOnFadeTime
		self.initialTurnOffFadeTime = self.turnOffFadeTime
		self.turnOnOffVariance = self.turnOnOffVariance * 1000
	end
	local v25_ = xmlFile:getValue(key .. "#speedFunc")
	if v25_ ~= nil then
		if owner[v25_] == nil then
			Logging.xmlWarning(xmlFile, "Could not find speed function \'%s\' for scrolling animation \'%s\'!", v25_, key)
		else
			self.speedFunc = owner[v25_]
			self.speedFuncTarget = self.owner
			self.speedFuncParam = xmlFile:getValue(key .. "#speedFuncParam")
		end
	end
	self.minAlphaForTurnOff = xmlFile:getValue(key .. "#minAlphaForTurnOff", 0)
	self.delayedTurnOff = false
	self.turnedOffPosition = xmlFile:getValue(key .. "#turnedOffPosition")
	if self.turnedOffPosition ~= nil then
		self.turnOffFadeTimeOrigin = self.turnOffFadeTime
		self.turnedOffSubDivisions = xmlFile:getValue(key .. "#turnedOffSubDivisions", 1)
	end
	return self
end

-- Local values: prevScroll, speedFactor, frame, scroll, scroll, scroll, x, y, z, w, prev_x, prev_y, prev_z, prev_w, node, _
function ScrollingAnimation:update(dt)
	ScrollingAnimation:superClass().update(self, dt)
	local v28_ = self.currentScroll
	local v29_ = self.speedFunc == nil and 1 or self.speedFunc(self.speedFuncTarget, self.speedFuncParam)
	local v30_ = 16.66667
	if self.state == ScrollingAnimation.STATE_ON then
		if self.currentAlpha < 1 then
			while dt > 0 do
				local v31_ = self.currentAlpha + math.min(v30_, dt) / self.turnOnFadeTime
				self.currentAlpha = math.min(1, v31_)
				local v32_ = self.currentAlpha * math.min(v30_, dt) * self.scrollSpeed * v29_
				self.currentScroll = (self.currentScroll + v32_) % self.scrollLength
				dt = dt - 16.66667
				if self.currentAlpha == 1 then
					break
				end
			end
		else
			local v33_ = self.currentAlpha * dt * self.scrollSpeed * v29_
			self.currentScroll = (self.currentScroll + v33_) % self.scrollLength
		end
	elseif self.state == ScrollingAnimation.STATE_TURNING_OFF then
		while dt > 0 do
			local v34_ = self.currentAlpha - math.min(v30_, dt) / self.turnOffFadeTime
			self.currentAlpha = math.max(0, v34_)
			local v35_ = self.currentAlpha * math.min(v30_, dt) * self.scrollSpeed * v29_
			self.currentScroll = (self.currentScroll + v35_) % self.scrollLength
			dt = dt - 16.66667
			if self.currentAlpha == 0 then
				break
			end
		end
	end
	if self.currentScroll ~= v28_ then
		local v36_ = nil
		local v37_ = nil
		local v38_ = nil
		local v39_ = nil
		local v40_ = nil
		local v41_ = nil
		local v42_ = nil
		local v43_ = nil
		if self.shaderParameterComponent == 1 then
			v36_ = self.currentScroll
			v40_ = v28_
			v28_ = v43_
		elseif self.shaderParameterComponent == 2 then
			v37_ = self.currentScroll
			v41_ = v28_
			v28_ = v43_
		elseif self.shaderParameterComponent == 3 then
			v38_ = self.currentScroll
			v42_ = v28_
			v28_ = v43_
		else
			v39_ = self.currentScroll
		end
		for v44_, _ in pairs(self.nodes) do
			if self.shaderParameterPrevName == nil then
				setShaderParameter(v44_, self.shaderParameterName, v36_, v37_, v38_, v39_, false)
			else
				setShaderParameter(v44_, self.shaderParameterPrevName, v40_, v41_, v42_, v28_, false)
				setShaderParameter(v44_, self.shaderParameterName, v36_, v37_, v38_, v39_, false)
			end
			if self.owner ~= nil and self.owner.setMovingToolDirty ~= nil then
				self.owner:setMovingToolDirty(v44_)
			end
		end
	end
	if self.currentAlpha == 0 then
		self.state = ScrollingAnimation.STATE_OFF
	end
	if self.delayedTurnOff and self.currentAlpha >= self.minAlphaForTurnOff then
		self.delayedTurnOff = false
		self:stop()
	end
	self:updateDuplicates()
end

function ScrollingAnimation:isRunning()
	return self.state ~= ScrollingAnimation.STATE_OFF
end

function ScrollingAnimation:start()
	if self.state == ScrollingAnimation.STATE_ON then
		return false
	end
	if self.state == ScrollingAnimation.STATE_OFF and (self.turnOnOffVariance ~= nil and self.currentAlpha == 0) then
		self.turnOnFadeTime = self.initialTurnOnFadeTime + math.random(-self.turnOnOffVariance, self.turnOnOffVariance)
		self.turnOffFadeTime = self.initialTurnOffFadeTime + math.random(-self.turnOnOffVariance, self.turnOnOffVariance)
	end
	self.state = ScrollingAnimation.STATE_ON
	self:updateDuplicates()
	return true
end

-- Local values: speedFactor
function ScrollingAnimation:stop()
	if self.state == ScrollingAnimation.STATE_OFF then
		return false
	end
	if self.minAlphaForTurnOff > 0 and self.currentAlpha < self.minAlphaForTurnOff then
		self.delayedTurnOff = true
		self.state = ScrollingAnimation.STATE_ON
		return true
	end
	self.state = ScrollingAnimation.STATE_TURNING_OFF
	self:updateDuplicates()
	if self.turnedOffPosition ~= nil then
		local v48_ = self.speedFunc == nil and 1 or self.speedFunc(self.speedFuncTarget, self.speedFuncParam)
		local v49_ = Animation.calculateTurnOffFadeTime
		local v50_ = self.currentAlpha
		local v51_ = self.scrollSpeed * v48_
		local v52_ = self.scrollSpeed
		self.turnOffFadeTime = v49_(v50_, v51_, math.sign(v52_), self.currentScroll, self.turnedOffPosition, self.turnOffFadeTimeOrigin, self.scrollLength, self.turnedOffSubDivisions)
	end
	return true
end

function ScrollingAnimation:reset()
	self.currentAlpha = 0
	self.state = ScrollingAnimation.STATE_OFF
	self:updateDuplicates()
end

-- Local values: node, _
function ScrollingAnimation:setFillType(fillTypeIndex)
	if self.fillTypeIndex ~= nil then
		for v56_, _ in pairs(self.nodes) do
			setVisibility(v56_, self.fillTypeIndex == fillTypeIndex)
		end
	end
end

-- Local values: node, _
function ScrollingAnimation:isDuplicate(otherAnimation)
	if not otherAnimation:isa(ScrollingAnimation) or (self.parent ~= otherAnimation.parent or table.size(self.nodes) ~= table.size(otherAnimation.nodes)) then
		return false
	end
	for v59_, _ in pairs(self.nodes) do
		if otherAnimation.nodes[v59_] == nil then
			return false
		end
	end
	return true
end

function ScrollingAnimation:updateDuplicate(otherAnimation)
	otherAnimation.currentAlpha = self.currentAlpha
	otherAnimation.currentScroll = self.currentScroll
	otherAnimation.state = self.state
end

function ScrollingAnimation.registerAnimationClassXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".node(?)#node", "Node")
	schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#speedScale", "Speed scale", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#scrollSpeed", "(ScrollingAnimation) Scroll speed", "Default scroll speed")
	schema:register(XMLValueType.STRING, basePath .. "#shaderParameterName", "Shader parameter name")
	schema:register(XMLValueType.STRING, basePath .. "#shaderParameterPrevName", "Prev Shader parameter name", "automatically calculated from #shaderParameterName")
	schema:register(XMLValueType.STRING, basePath .. "#type", "(ScrollingAnimation) Fill type name")
	schema:register(XMLValueType.FLOAT, basePath .. "#scrollSpeed", "(ScrollingAnimation) Scroll speed", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#scrollLength", "(ScrollingAnimation) Scroll length", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#shaderParameterComponent", "(ScrollingAnimation) Shader parameter component", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#turnOnFadeTime", "Turn on fade time", 2)
	schema:register(XMLValueType.FLOAT, basePath .. "#turnOffFadeTime", "Turn off fade time", 2)
	schema:register(XMLValueType.FLOAT, basePath .. "#turnOnOffVariance", "Turn off time variance")
	schema:register(XMLValueType.FLOAT, basePath .. "#turnedOffPosition", "(ScrollingAnimation) Target position while turned off")
	schema:register(XMLValueType.FLOAT, basePath .. "#turnedOffSubDivisions", "Amount of sub divisions which have the same state", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#minAlphaForTurnOff", "Min. alpha for turn off (speed [0-1])", 0)
	schema:register(XMLValueType.STRING, basePath .. "#speedFunc", "Lua speed function")
	schema:register(XMLValueType.STRING, basePath .. "#speedFuncParam", "Additional string parameter that is passed to the speedFunc")
end
