-- Local values: InputEvent_mt
InputEvent = {}
local InputEvent_mt = Class(InputEvent)

-- Upvalues: InputEvent_mt
-- Local values: self
function InputEvent.new(actionName, targetObject, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, orderValue)
	-- upvalues: (copy) InputEvent_mt
	local v11_ = InputEvent_mt
	local v12_ = setmetatable({}, v11_)
	v12_.actionName = actionName
	v12_.targetObject = targetObject
	v12_.callback = callback
	v12_.triggerDown = triggerDown
	v12_.triggerUp = triggerUp
	v12_.triggerAlways = triggerAlways
	v12_.callbackState = callbackState
	v12_.orderValue = orderValue
	v12_.id = v12_:makeId()
	v12_.ignoreComboMask = false
	v12_.isActive = startActive
	v12_.contextDisplayText = nil
	v12_.contextDisplayIconName = nil
	v12_.displayIsVisible = true
	v12_.displayPriority = GS_PRIO_VERY_LOW
	v12_.hasFrameTriggered = false
	return v12_
end

function InputEvent:setIgnoreComboMask(ignoreComboMask)
	self.ignoreComboMask = ignoreComboMask
end

function InputEvent:getIgnoreComboMask()
	return self.ignoreComboMask
end

-- Local values: triggerUp, triggerDown, triggerPressed, triggerContinuous
function InputEvent:notifyInput(binding, isReset)
	local v19_ = self.triggerUp and binding.isUpFlank
	if v19_ then
		v19_ = binding.recievedDownFlankInCurrentContext
	end
	local v20_ = self.triggerDown and (binding.isDownFlank and not self.triggerAlways)
	if v20_ then
		v20_ = not binding.enteredNewContextThisFrame
	end
	local v21_ = self.triggerDown and (self.triggerAlways and binding.isPressed)
	if v21_ then
		v21_ = binding.recievedDownFlankInCurrentContext
	end
	local v22_ = not self.triggerDown
	if v22_ then
		v22_ = self.triggerAlways
	end
	if not self.hasFrameTriggered and (v19_ or (v20_ or (v21_ or v22_))) then
		self.hasFrameTriggered = true
		binding:setFrameTriggered(not v22_)
		self.callback(self.targetObject, self.actionName, binding.inputValue, self.callbackState, binding.isAnalog, binding.isMouse, binding.deviceCategory, binding, isReset)
	end
end

function InputEvent:frameReset()
	self.hasFrameTriggered = false
end

function InputEvent:makeId()
	local v25_ = string.format
	local v26_ = self.actionName
	local v27_ = tostring(v26_)
	local v28_ = self.targetObject
	return v25_("%s|%s|%d", v27_, tostring(v28_), self:getTriggerCode())
end

-- Local values: downFlag, upFlag, alwaysFlag
function InputEvent:getTriggerCode()
	local v30_ = self.triggerDown and 1 or 0
	local v31_ = self.triggerUp and 2 or 0
	local v32_ = self.triggerAlways and 4 or 0
	return v30_ + v31_ + v32_
end

function InputEvent:initializeDisplayText(inputAction)
	self.contextDisplayText = inputAction.displayNamePositive
end

function InputEvent:toString()
	return string.format("[%s: target=%s, triggerUp=%s, triggerDown=%s, triggerAlways=%s, isActive=%s, isVisible=%s, hasFrameTriggered=%s]", self.actionName, self.targetObject, self.triggerUp, self.triggerDown, self.triggerAlways, self.isActive, self.displayIsVisible, self.hasFrameTriggered)
end
InputEvent_mt.__tostring = InputEvent.toString
InputEvent.NO_EVENT = InputEvent.new("", {}, function() end, false, false, false, false, 0, 0)
