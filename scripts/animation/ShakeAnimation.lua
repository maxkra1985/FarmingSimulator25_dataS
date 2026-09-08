-- Local values: ShakeAnimation_mt
ShakeAnimation = {}
ShakeAnimation.STATE_OFF = 0
ShakeAnimation.STATE_ON = 1
ShakeAnimation.STATE_TURNING_OFF = 2
local ShakeAnimation_mt = Class(ShakeAnimation, Animation)

-- Upvalues: ShakeAnimation_mt
-- Local values: self
function ShakeAnimation.new(customMt)
	-- upvalues: (copy) ShakeAnimation_mt
	local v3_ = Animation.new(customMt or ShakeAnimation_mt)
	v3_.state = ShakeAnimation.STATE_OFF
	v3_.node = nil
	v3_.turnOnOffVariance = nil
	v3_.turnOnFadeTime = 0
	v3_.turnOffFadeTime = 0
	v3_.initialTurnOnFadeTime = 1000
	v3_.currentAlpha = 0
	v3_.owner = nil
	function v3_.speedFunc()
		return 1
	end
	v3_.speedFuncTarget = v3_
	return v3_
end

function ShakeAnimation:load(xmlFile, key, rootNodes, owner, i3dMapping)
	if not xmlFile:hasProperty(key) then
		return nil
	end
	self.owner = owner
	self.node = xmlFile:getValue(key .. "#node", nil, rootNodes, i3dMapping)
	if self.node == nil then
		Logging.xmlWarning(xmlFile, "Missing node for shake animation \'%s\'!", key)
		return nil
	end
	if not getHasShaderParameter(self.node, "shaking") then
		Logging.xmlWarning(xmlFile, "Node \'%s\' has no shader parameter \'shaking\' for shake animation \'%s\'!", getName(self.node), key)
		return nil
	end
	local v10_ = xmlFile:getValue(key .. "#turnOnFadeTime", 2) * 1000
	self.turnOnFadeTime = math.max(v10_, 1)
	local v11_ = xmlFile:getValue(key .. "#turnOffFadeTime", 2) * 1000
	self.turnOffFadeTime = math.max(v11_, 1)
	self.turnOnOffVariance = xmlFile:getValue(key .. "#turnOnOffVariance")
	if self.turnOnOffVariance ~= nil then
		self.initialTurnOnFadeTime = self.turnOnFadeTime
		self.initialTurnOffFadeTime = self.turnOffFadeTime
		self.turnOnOffVariance = self.turnOnOffVariance * 1000
	end
	self.shaking = xmlFile:getValue(key .. "#shaking", "0 0 0 0", true)
	return self
end

-- Local values: needUpdate, shaking, alpha
function ShakeAnimation:update(dt)
	ShakeAnimation:superClass().update(self, dt)
	local v14_ = false
	if self.state == ShakeAnimation.STATE_ON then
		v14_ = self.currentAlpha < 1
		local v15_ = self.currentAlpha + dt / self.turnOnFadeTime
		self.currentAlpha = math.min(1, v15_)
	elseif self.state == ShakeAnimation.STATE_TURNING_OFF then
		v14_ = self.currentAlpha > 0
		local v16_ = self.currentAlpha - dt / self.turnOffFadeTime
		self.currentAlpha = math.max(0, v16_)
	end
	if v14_ then
		local v17_ = self.shaking
		local v18_ = self.currentAlpha
		g_animationManager:setPrevShaderParameter(self.node, "shaking", v17_[1] * v18_, v17_[2] * v18_, v17_[3] * v18_, v17_[4] * v18_, false, "prevShaking")
	end
	if self.state == ShakeAnimation.STATE_TURNING_OFF and self.currentAlpha == 0 then
		self.state = ShakeAnimation.STATE_OFF
	end
	self:updateDuplicates()
end

function ShakeAnimation:isRunning()
	return self.state ~= ShakeAnimation.STATE_OFF
end

function ShakeAnimation:start()
	if self.state == ShakeAnimation.STATE_ON then
		return false
	end
	if self.state == ShakeAnimation.STATE_OFF and (self.turnOnOffVariance ~= nil and self.currentAlpha == 0) then
		self.turnOnFadeTime = self.initialTurnOnFadeTime + math.random(-self.turnOnOffVariance, self.turnOnOffVariance)
		self.turnOffFadeTime = self.initialTurnOffFadeTime + math.random(-self.turnOnOffVariance, self.turnOnOffVariance)
	end
	self.state = ShakeAnimation.STATE_ON
	self:updateDuplicates()
	return true
end

function ShakeAnimation:stop()
	if self.state == ShakeAnimation.STATE_OFF then
		return false
	end
	self.state = ShakeAnimation.STATE_TURNING_OFF
	self:updateDuplicates()
	return true
end

function ShakeAnimation:reset()
	self.currentAlpha = 0
	self.state = ShakeAnimation.STATE_OFF
	self:updateDuplicates()
end

function ShakeAnimation:isDuplicate(otherAnimation)
	return otherAnimation:isa(ShakeAnimation) and (self.parent == otherAnimation.parent and self.node == otherAnimation.node) and true or false
end

function ShakeAnimation:updateDuplicate(otherAnimation)
	otherAnimation.currentAlpha = self.currentAlpha
	otherAnimation.state = self.state
end

function ShakeAnimation.registerAnimationClassXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Node")
	schema:register(XMLValueType.VECTOR_4, basePath .. "#shaking", "(ShakeAnimation) Shaking scale for shader parameters", "0 0 0 0")
	schema:register(XMLValueType.FLOAT, basePath .. "#turnOnFadeTime", "Turn on fade time", 2)
	schema:register(XMLValueType.FLOAT, basePath .. "#turnOffFadeTime", "Turn off fade time", 2)
	schema:register(XMLValueType.FLOAT, basePath .. "#turnOnOffVariance", "Turn off time variance")
	schema:register(XMLValueType.STRING, basePath .. "#speedFunc", "Lua speed function")
end
