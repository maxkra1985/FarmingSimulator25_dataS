-- Local values: VehicleActionControllerAction_mt
VehicleActionControllerAction = {}
local VehicleActionControllerAction_mt = Class(VehicleActionControllerAction)

-- Upvalues: VehicleActionControllerAction_mt
-- Local values: self
function VehicleActionControllerAction.new(parent, name, inputAction, priority, customMt)
	-- upvalues: (copy) VehicleActionControllerAction_mt
	local v7_ = customMt or VehicleActionControllerAction_mt
	local v8_ = setmetatable({}, v7_)
	v8_.parent = parent
	v8_.name = name
	v8_.inputAction = inputAction
	v8_.priority = priority
	v8_.lastDirection = -1
	v8_.lastValidDirection = 0
	v8_.isSaved = false
	v8_.resetOnDeactivation = true
	v8_.identifier = ""
	v8_.aiEventListener = {}
	return v8_
end

function VehicleActionControllerAction:remove()
	self.parent:removeAction(self)
end

function VehicleActionControllerAction:updateParent(parent)
	if parent ~= self.parent then
		self.parent:removeAction(self)
		parent:addAction(self)
	end
	self.parent = parent
end

function VehicleActionControllerAction:setCallback(callbackTarget, inputCallback, inputCallbackRev)
	self.callbackTarget = callbackTarget
	self.inputCallback = inputCallback
	self.inputCallbackRev = inputCallbackRev
	self.identifier = callbackTarget.configFileName or ""
end

function VehicleActionControllerAction:setFinishedFunctions(finishedFunctionTarget, finishedFunc, finishedResult, finishedResultRev, finishedFuncRev)
	self.finishedFunctionTarget = finishedFunctionTarget
	self.finishedFunc = finishedFunc
	self.finishedFuncRev = finishedFuncRev
	self.finishedResult = finishedResult
	self.finishedResultRev = finishedResultRev
end

function VehicleActionControllerAction:setDeactivateFunction(deactivateFunctionTarget, deactivateFunc, inverseDeactivateFunc)
	self.deactivateFunctionTarget = deactivateFunctionTarget
	self.deactivateFunc = deactivateFunc
	self.inverseDeactivateFunc = Utils.getNoNil(inverseDeactivateFunc, false)
end

function VehicleActionControllerAction:setIsAvailableFunction(availableFunc)
	self.availableFunc = availableFunc
end

function VehicleActionControllerAction:setIsAccessibleFunction(accessibleFunc)
	self.accessibleFunc = accessibleFunc
end

function VehicleActionControllerAction:setActionIcons(iconPos, iconNeg, changeColor)
	self.iconPos = iconPos
	self.iconNeg = iconNeg
	self.iconChangeColor = changeColor
end

function VehicleActionControllerAction:setResetOnDeactivation(resetOnDeactivation)
	self.resetOnDeactivation = resetOnDeactivation
end

function VehicleActionControllerAction:setIsSaved(isSaved)
	self.isSaved = isSaved
end

function VehicleActionControllerAction:getIsSaved()
	return self.isSaved
end

function VehicleActionControllerAction:isAvailable()
	return self.availableFunc == nil and true or self.availableFunc()
end

function VehicleActionControllerAction:isAccessible()
	return self.accessibleFunc == nil and true or self.accessibleFunc()
end

function VehicleActionControllerAction:getControlledActionIcons()
	return self.iconPos, self.iconNeg, self.iconChangeColor
end

function VehicleActionControllerAction:getLastDirection()
	return self.lastDirection
end

function VehicleActionControllerAction:getDoResetOnDeactivation()
	return self.resetOnDeactivation
end

-- Local values: listener
function VehicleActionControllerAction:addAIEventListener(sourceVehicle, eventName, direction, forceUntilFinished)
	self.sourceVehicle = sourceVehicle
	local v49_ = self.aiEventListener
	table.insert(v49_, {
		["eventName"] = eventName,
		["direction"] = direction,
		["forceUntilFinished"] = forceUntilFinished
	})
end

function VehicleActionControllerAction:registerActionEvents(target, vehicle, actionEvents, isActiveForInput, isActiveForInputIgnoreSelection) end

function VehicleActionControllerAction:actionEvent(actionName, inputValue, actionIndex, isAnalog)
	self:doAction()
end

-- Local values: success
function VehicleActionControllerAction:doAction(direction, isAIEvent)
	if direction == nil then
		direction = -self.lastDirection
	end
	self.lastDirection = direction
	local v54_ = self.inputCallback(self.callbackTarget, direction, isAIEvent)
	if v54_ then
		self.lastValidDirection = self.lastDirection
	end
	return v54_
end

function VehicleActionControllerAction:getIsFinished(direction)
	if self.finishedFunc == nil then
		return true
	elseif direction > 0 then
		return self.finishedFunc(self.finishedFunctionTarget) == self.finishedResult
	else
		return self.finishedFunc(self.finishedFunctionTarget) == self.finishedResultRev
	end
end

function VehicleActionControllerAction:getSourceVehicle()
	return self.sourceVehicle
end

-- Local values: _, listener
function VehicleActionControllerAction:onAIEvent(eventName)
	for _, v60_ in ipairs(self.aiEventListener) do
		if v60_.eventName == eventName then
			if self:doAction(v60_.direction, true) or not v60_.forceUntilFinished then
				if self.forceDirectionUntilFinished ~= nil and v60_.direction ~= self.forceDirectionUntilFinished then
					self.forceDirectionUntilFinished = nil
				end
				self.parent:stopActionSequence()
			else
				self.forceDirectionUntilFinished = v60_.direction
			end
		end
	end
end

function VehicleActionControllerAction:update(dt)
	if self.deactivateFunc ~= nil and (self.lastDirection == 1 and (self.deactivateFunc(self.deactivateFunctionTarget) == not self.inverseDeactivateFunc and (self.parent.currentSequenceIndex == nil and self.forceDirectionUntilFinished == nil))) then
		self.parent:startActionSequence()
	end
end

function VehicleActionControllerAction:updateForAI(dt)
	if self.forceDirectionUntilFinished ~= nil and self:doAction(self.forceDirectionUntilFinished) then
		self.forceDirectionUntilFinished = nil
		self.parent:stopActionSequence()
	end
end

-- Local values: finishedResult, vehicleName
function VehicleActionControllerAction:getDebugText()
	local v64_
	if self.finishedFunc == nil then
		v64_ = "?"
	else
		v64_ = self.finishedFunc(self.finishedFunctionTarget)
		if type(v64_) == "number" then
			v64_ = string.format("%.1f", v64_)
		end
	end
	local v65_ = self.callbackTarget == nil and "Unknown Vehicle" or self.callbackTarget:getName()
	return string.format("Prio \'%d\' - Vehicle \'%s\' - Action \'%s\' (%s/%s)", self.priority, v65_, self.name, v64_, self.lastDirection == 1 and self.finishedResult or self.finishedResultRev)
end
