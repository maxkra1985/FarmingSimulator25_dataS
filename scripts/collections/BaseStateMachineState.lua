-- Local values: BaseStateMachineState_mt
BaseStateMachineState = {}
local BaseStateMachineState_mt = Class(BaseStateMachineState)

function BaseStateMachineState.registerXMLPaths(xmlSchema, baseKey)
	xmlSchema:register(XMLValueType.FLOAT, baseKey .. "#debugPositionX", "The x position of the state when debug-drawn, in screen-space", nil, false)
	xmlSchema:register(XMLValueType.FLOAT, baseKey .. "#debugPositionY", "The y position of the state when debug-drawn, in screen-space", nil, false)
	xmlSchema:register(XMLValueType.FLOAT, baseKey .. "#debugWidth", "The width of the state when debug-drawn, in screen-space", nil, false)
	xmlSchema:register(XMLValueType.FLOAT, baseKey .. "#debugHeight", "The height of the state when debug-drawn, in screen-space", nil, false)
end

-- Upvalues: BaseStateMachineState_mt
-- Local values: self
function BaseStateMachineState.new(stateMachine, custom_mt)
	-- upvalues: (copy) BaseStateMachineState_mt
	local v6_ = custom_mt or BaseStateMachineState_mt
	local v7_ = setmetatable({}, v6_)
	v7_.stateMachine = stateMachine
	v7_.transitions = {}
	v7_.debugPositionX = nil
	v7_.debugPositionY = nil
	v7_.debugWidth = nil
	v7_.debugHeight = nil
	return v7_
end

function BaseStateMachineState:loadDebugInfoFromXMLFile(xmlFile, baseKey)
	self.debugPositionX = xmlFile:getValue(baseKey .. "#debugPositionX")
	self.debugPositionY = xmlFile:getValue(baseKey .. "#debugPositionY")
	self.debugWidth = xmlFile:getValue(baseKey .. "#debugWidth")
	self.debugHeight = xmlFile:getValue(baseKey .. "#debugHeight")
end

-- Local values: state, binding
function BaseStateMachineState:trySwitchToValidTransition()
	for v12_, v13_ in pairs(self.transitions) do
		if v13_.conditionFunction(v13_.context) then
			self.stateMachine:changeState(v12_)
			return v12_
		end
	end
	return nil
end

function BaseStateMachineState:createTransitions() end

function BaseStateMachineState:addTransition(conditionFunction, targetState, contextObject)
	self.transitions[targetState] = {
		["context"] = contextObject or targetState,
		["conditionFunction"] = conditionFunction
	}
	return self.transitions[targetState]
end

function BaseStateMachineState:calculateIfShouldBeForced()
	return false
end

function BaseStateMachineState:calculateIfValidEntryState()
	return false
end

function BaseStateMachineState:onStateEntered(previousState) end

function BaseStateMachineState:onStateExited(nextState) end

function BaseStateMachineState:updateAsCurrent(dt)
	if not self.stateMachine:getIsPassive() then
		self:trySwitchToValidTransition()
	end
end

function BaseStateMachineState:updateAsInactive(dt) end

function BaseStateMachineState:caclulateDebugScreenBounds(x, y, width, height)
	if self.debugPositionX == nil or (self.debugPositionY == nil or (self.debugWidth == nil or self.debugHeight == nil)) then
		return nil, nil, nil, nil
	else
		return x + self.debugPositionX * width, y + self.debugPositionY * height, self.debugWidth * width, self.debugHeight * height
	end
end

-- Local values: frameX, frameY, frameWidth, frameHeight
function BaseStateMachineState:debugDraw(x, y, width, height, textSize, color)
	local v30_, v31_, v32_, v33_ = self:caclulateDebugScreenBounds(x, y, width, height)
	if v30_ == nil then
		return nil, nil, nil, nil
	end
	if color == nil then
		color = self.stateMachine.currentState == self and Color.PRESETS.GREEN or Color.PRESETS.GRAY
	end
	drawFilledRect(v30_, v31_, v32_, v33_, color:unpack())
	return v30_, v31_, v32_, v33_
end

-- Local values: frameX, frameY, frameWidth, frameHeight, targetState, condition, targetFrameX, targetFrameY, targetFrameWidth, targetFrameHeight, color, lineStartX, lineStartY, lineEndX, lineEndY, lineLength, lineDirectionX, lineDirectionY, lineAngle, lineCentreX, lineCentreY, arrowDirectionX, arrowDirectionY
function BaseStateMachineState:debugDrawTransitions(x, y, width, height, activatedColor, wouldBeActivatedColor, unactivatedColor)
	local v42_, v43_, v44_, v45_ = self:caclulateDebugScreenBounds(x, y, width, height)
	if v42_ ~= nil then
		for v46_, v47_ in pairs(self.transitions) do
			local v48_, v49_, v50_, v51_ = v46_:caclulateDebugScreenBounds(x, y, width, height)
			if v48_ ~= nil then
				local v52_
				if v47_.conditionFunction(v47_.context) then
					if self.stateMachine.currentState == self then
						v52_ = activatedColor or Color.PRESETS.GREEN
					else
						v52_ = wouldBeActivatedColor or Color.PRESETS.GOLD
					end
				else
					v52_ = unactivatedColor or Color.PRESETS.RED
				end
				local v53_ = v42_ + v44_ / 2
				local v54_ = v43_ + v45_ / 2
				local v55_ = v48_ + v50_ / 2
				local v56_ = v49_ + v51_ / 2
				local v57_ = MathUtil.vector2Length(v53_ - v55_, v54_ - v56_)
				local v58_ = (v55_ - v53_) / v57_
				local v59_ = (v56_ - v54_) / v57_
				local v60_ = math.atan2(v59_, v58_)
				local v61_ = v53_ + v58_ * v57_ * 0.5
				local v62_ = v54_ + v59_ * v57_ * 0.5
				local v63_ = v60_ + 2.0734511513692637
				local v64_ = math.cos(v63_)
				local v65_ = v60_ + 2.0734511513692637
				local v66_ = math.sin(v65_)
				drawLine2D(v61_, v62_, v61_ + v64_ * 0.01, v62_ + v66_ * 0.01, 0.001, v52_:unpack())
				local v67_ = v60_ - 2.0734511513692637
				local v68_ = math.cos(v67_)
				local v69_ = v60_ - 2.0734511513692637
				local v70_ = math.sin(v69_)
				drawLine2D(v61_, v62_, v61_ + v68_ * 0.01, v62_ + v70_ * 0.01, 0.001, v52_:unpack())
				drawLine2D(v53_, v54_, v55_, v56_, 0.001, v52_:unpack())
			end
		end
	end
end
