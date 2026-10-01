FocusManager = { TOP = "top", BOTTOM = "bottom", LEFT = "left", RIGHT = "right", EPSILON = 0.00001, INITIAL_DELAY_TIME = 350, SCROLL_DELAY_TIME = 70 }
FocusManager.guiFocusData = {}
FocusManager.currentFocusData = {}
FocusManager.currentFocusData.focusElement = nil
FocusManager.currentFocusData.highlightElement = nil
FocusManager.currentFocusData.initialFocusElement = nil
FocusManager.isFocusLocked = false
FocusManager.lastInput = {}
FocusManager.lockUntil = {}
FocusManager.autoIDcount = 0
FocusManager.OPPOSING_DIRECTIONS = { [FocusManager.TOP] = FocusManager.BOTTOM, [FocusManager.BOTTOM] = FocusManager.TOP, [FocusManager.LEFT] = FocusManager.RIGHT, [FocusManager.RIGHT] = FocusManager.LEFT }
FocusManager.DIRECTION_VECTORS = { [FocusManager.TOP] = { 0, 1 }, [FocusManager.BOTTOM] = { 0, -1 }, [FocusManager.LEFT] = { -1, 0 }, [FocusManager.RIGHT] = { 1, 0 } }
FocusManager.DEBUG = false
local allElements_mt = { __mode = "k" }
FocusManager.allElements = setmetatable({}, allElements_mt)
function FocusManager:setGui(gui)
	if self.currentFocusData then
		local focusElement = self.currentFocusData.focusElement
		if focusElement then
			self:unsetFocus(focusElement)
		end
		local highlightElement = self.currentFocusData.highlightElement
		if highlightElement then
			self:unsetHighlight(highlightElement)
		end
	end
	self.currentGui = gui
	self.currentFocusData = self.guiFocusData[gui]
	if not self.currentFocusData then
		self.guiFocusData[gui] = {}
		self.guiFocusData[gui].idToElementMapping = {}
		self.currentFocusData = self.guiFocusData[gui]
	else
		local focusElement = self.currentFocusData.initialFocusElement or self.currentFocusData.focusElement
		if focusElement ~= nil then
			local oldSound = focusElement.soundDisabled
			focusElement.soundDisabled = true
			self:setFocus(focusElement)
			focusElement.soundDisabled = oldSound
		end
	end
	self:resetFocusInputLocks()
end
function FocusManager:setSoundPlayer(guiSoundPlayer)
	self.soundPlayer = guiSoundPlayer
end
function FocusManager:getElementById(id)
	return self.currentFocusData.idToElementMapping[id]
end
function FocusManager:getFocusedElement()
	return self.currentFocusData.focusElement
end
function FocusManager.serveAutoFocusId()
	local focusId = string.format("focusAuto_%d", FocusManager.autoIDcount)
	FocusManager.autoIDcount = FocusManager.autoIDcount + 1
	return focusId
end
function FocusManager:loadElementFromXML(xmlFile, xmlBaseNode, element)
	local focusId = getXMLString(xmlFile, xmlBaseNode .. "#focusId") or FocusManager.serveAutoFocusId()
	element.focusId = focusId
	element.focusChangeData = {}
	if not element.focusChangeData[FocusManager.TOP] then
		element.focusChangeData[FocusManager.TOP] = getXMLString(xmlFile, xmlBaseNode .. "#focusChangeTop")
	end
	if not element.focusChangeData[FocusManager.BOTTOM] then
		element.focusChangeData[FocusManager.BOTTOM] = getXMLString(xmlFile, xmlBaseNode .. "#focusChangeBottom")
	end
	if not element.focusChangeData[FocusManager.LEFT] then
		element.focusChangeData[FocusManager.LEFT] = getXMLString(xmlFile, xmlBaseNode .. "#focusChangeLeft")
	end
	if not element.focusChangeData[FocusManager.RIGHT] then
		element.focusChangeData[FocusManager.RIGHT] = getXMLString(xmlFile, xmlBaseNode .. "#focusChangeRight")
	end
	element.focused = getXMLString(xmlFile, xmlBaseNode .. "#focusInit") ~= nil
	local isAlwaysFocusedOnOpen = getXMLString(xmlFile, xmlBaseNode .. "#focusInit") == "onOpen"
	element.isAlwaysFocusedOnOpen = isAlwaysFocusedOnOpen
	local focusChangeOverride = getXMLString(xmlFile, xmlBaseNode .. "#focusChangeOverride")
	if focusChangeOverride and element.target then
		if element.target.focusChangeOverride then
			element.focusChangeOverride = element.target[focusChangeOverride]
		else
			self.focusChangeOverride = ClassUtil.getFunction(focusChangeOverride)
		end
	end
	if FocusManager.allElements[element] == nil then
		FocusManager.allElements[element] = {}
	end
	table.insert(FocusManager.allElements[element], self.currentGui)
	self.currentFocusData.idToElementMapping[focusId] = element
	if isAlwaysFocusedOnOpen then
		self.currentFocusData.initialFocusElement = element
		local old = element.soundDisabled
		element.soundDisabled = true
		self:setFocus(element)
		element.soundDisabled = old
	else
		if not self.currentFocusData.focusElement then
			self.currentFocusData.focusElement = element
		end
	end
end
function FocusManager:loadElementFromCustomValues(element, focusId, focusChangeData, focusActive, isAlwaysFocusedOnOpen)
	if focusId and self.currentFocusData.idToElementMapping[focusId] then
		return false
	end
	if not element.focusId then
		focusId = focusId or FocusManager.serveAutoFocusId()
		element.focusId = focusId
	end
	element.focusChangeData = element.focusChangeData or focusChangeData or {}
	element.isAlwaysFocusedOnOpen = isAlwaysFocusedOnOpen
	if FocusManager.allElements[element] == nil then
		FocusManager.allElements[element] = {}
	end
	table.insert(FocusManager.allElements[element], self.currentGui)
	self.currentFocusData.idToElementMapping[element.focusId] = element
	if isAlwaysFocusedOnOpen then
		self.currentFocusData.initialFocusElement = element
	end
	if focusActive then
		self:setFocus(element)
	end
	local success = true
	for _, child in pairs(element.elements) do
		success = success and self:loadElementFromCustomValues(child, child.focusId, child.focusChangeData, child.focusActive, child.isAlwaysFocusedOnOpen)
	end
	return success
end
function FocusManager:removeElement(element)
	if not element.focusId then
		return
	else
		for _, child in pairs(element.elements) do
			self:removeElement(child)
		end
		if element:getIsFocused() then
			element:onFocusLeave()
			FocusManager:unsetFocus(element)
		end
		if FocusManager.allElements[element] ~= nil then
			for _, guiItWasAddedTo in ipairs(FocusManager.allElements[element]) do
				local data = self.guiFocusData[guiItWasAddedTo]
				data.idToElementMapping[element.focusId] = nil
				if data.focusElement == element then
					data.focusElement = nil
				end
			end
			FocusManager.allElements[element] = nil
		end
		self.currentFocusData.idToElementMapping[element.focusId] = nil
		element.focusId = nil
		element.focusChangeData = {}
		if self.currentFocusData.focusElement == element then
			self.currentFocusData.focusElement = nil
		end
	end
end
function FocusManager:linkElements(sourceElement, direction, targetElement)
	if targetElement == nil then
		sourceElement.focusChangeData[direction] = "nil"
	else
		sourceElement.focusChangeData[direction] = targetElement.focusId
	end
end
function FocusManager:inputEvent(action, value, eventUsed)
	local element = self.currentFocusData.focusElement
	local pressedAccept = false
	local direction = nil
	if action == InputAction.MENU_AXIS_UP_DOWN then
		if g_analogStickVTolerance < value then
			direction = FocusManager.TOP
		elseif action == InputAction.MENU_AXIS_UP_DOWN then
			if value < -g_analogStickVTolerance then
				direction = FocusManager.BOTTOM
			elseif action == InputAction.MENU_AXIS_LEFT_RIGHT then
				if value < -g_analogStickHTolerance then
					direction = FocusManager.LEFT
				elseif action == InputAction.MENU_AXIS_LEFT_RIGHT then
					if g_analogStickHTolerance < value then
						direction = FocusManager.RIGHT
					end
				end
			end
		end
	end
	if direction ~= nil then
		self:updateFocus(element, direction, eventUsed)
	end
	if not eventUsed and (element ~= nil and not element.needExternalClick) then
		pressedAccept = action == InputAction.MENU_ACCEPT
		if pressedAccept and (not self:isFocusInputLocked(action) and (element:getIsFocused() and element:getIsVisible())) then
			self.focusSystemMadeChanges = true
			element:onFocusActivate()
			self.focusSystemMadeChanges = false
		end
	end
	return eventUsed
end
function FocusManager.getDirectionForAxisValue(inputAction, value)
	if value == nil then
		return nil
	else
		local direction = nil
		if inputAction == InputAction.MENU_AXIS_UP_DOWN then
			if value < 0 then
				direction = FocusManager.BOTTOM
				return direction
			end
			if 0 < value then
				direction = FocusManager.TOP
				return direction
			end
		elseif inputAction == InputAction.MENU_AXIS_LEFT_RIGHT then
			if value < 0 then
				direction = FocusManager.LEFT
				return direction
			end
			if 0 < value then
				direction = FocusManager.RIGHT
			end
		end
		return direction
	end
end
function FocusManager:isFocusInputLocked(inputAxis, value)
	local key = FocusManager.getDirectionForAxisValue(inputAxis, value)
	if key == nil and (inputAxis ~= InputAction.MENU_AXIS_UP_DOWN and inputAxis ~= InputAction.MENU_AXIS_LEFT_RIGHT) then
		key = inputAxis
	end
	if self.lastInput[key] and g_time < self.lockUntil[key] then
		return true
	end
	return false
end
function FocusManager:lockFocusInput(axisAction, delay, value)
	local key = FocusManager.getDirectionForAxisValue(axisAction, value)
	if not key and (axisAction ~= InputAction.MENU_AXIS_UP_DOWN and axisAction ~= InputAction.MENU_AXIS_LEFT_RIGHT) then
		key = axisAction
	end
	self.lastInput[key] = g_time
	self.lockUntil[key] = g_time + delay
end
function FocusManager:releaseMovementFocusInput(action)
	if action == InputAction.MENU_AXIS_LEFT_RIGHT then
		self.lastInput[FocusManager.LEFT] = nil
		self.lockUntil[FocusManager.LEFT] = nil
		self.lastInput[FocusManager.RIGHT] = nil
		self.lockUntil[FocusManager.RIGHT] = nil
	else
		if action == InputAction.MENU_AXIS_UP_DOWN then
			self.lastInput[FocusManager.TOP] = nil
			self.lockUntil[FocusManager.TOP] = nil
			self.lastInput[FocusManager.BOTTOM] = nil
			self.lockUntil[FocusManager.BOTTOM] = nil
		end
	end
end
function FocusManager:resetFocusInputLocks()
	for k, _ in pairs(self.lastInput) do
		self.lastInput[k] = nil
	end
	for k, _ in pairs(self.lockUntil) do
		self.lockUntil[k] = 0
	end
end
function FocusManager.getClosestPointOnBoundingBox(x, y, boxMinX, boxMinY, boxMaxX, boxMaxY)
	local px = x
	local py = y
	if x < boxMinX then
		px = boxMinX
	elseif boxMaxX < x then
		px = boxMaxX
	end
	if y < boxMinY then
		py = boxMinY
		return px, py
	else
		if boxMaxY < y then
			py = boxMaxY
		end
		return px, py
	end
end
function FocusManager.getShortestBoundingBoxVector(minX, minY, maxX, maxY, otherBoxMinX, otherBoxMinY, otherBoxMaxX, otherBoxMaxY, otherCenterX, otherCenterY)
	local ePointX, ePointY = FocusManager.getClosestPointOnBoundingBox(otherCenterX, otherCenterY, minX, minY, maxX, maxY)
	local oPointX, oPointY = FocusManager.getClosestPointOnBoundingBox(ePointX, ePointY, otherBoxMinX, otherBoxMinY, otherBoxMaxX, otherBoxMaxY)
	local elementDirX = oPointX - ePointX
	local elementDirY = oPointY - ePointY
	return elementDirX, elementDirY
end
function FocusManager.checkElementDistance(curElement, other, dirX, dirY, curElementOffsetY, closestOther, closestDistanceSq)
	local retOther = closestOther
	local retDistSq = closestDistanceSq
	local minX, minY, maxX, maxY = curElement:getBorders()
	minY = minY + curElementOffsetY
	maxY = maxY + curElementOffsetY
	local centerX, centerY = curElement:getCenter()
	centerY = centerY + curElementOffsetY
	if other ~= curElement and (not other.disabled and (other:getIsVisible() and (other:canReceiveFocus() and (not other:isChildOf(curElement) and not curElement:isChildOf(other))))) then
		local otherBoxMinX, otherBoxMinY, otherBoxMaxX, otherBoxMaxY = other:getBorders()
		local otherCenterX, otherCenterY = other:getCenter()
		local elementDirX, elementDirY = FocusManager.getShortestBoundingBoxVector(minX, minY, maxX, maxY, otherBoxMinX, otherBoxMinY, otherBoxMaxX, otherBoxMaxY, otherCenterX, otherCenterY)
		local boxDistanceSq = MathUtil.vector2LengthSq(elementDirX, elementDirY)
		local dot = MathUtil.dotProduct(elementDirX, elementDirY, 0, dirX, dirY, 0)
		if boxDistanceSq < FocusManager.EPSILON then
			dot = MathUtil.dotProduct(otherCenterX - centerX, otherCenterY - centerY, 0, dirX, dirY, 0)
		end
		if 0 < dot then
			local useOther = false
			if closestOther then
				if math.abs(closestDistanceSq - boxDistanceSq) < FocusManager.EPSILON then
					local closestBoxMinX, closestBoxMinY, closestBoxMaxX, closestBoxMaxY = closestOther:getBorders()
					local closestCenterX, closestCenterY = closestOther:getCenter()
					local toClosestX, toClosestY = FocusManager.getShortestBoundingBoxVector(minX, minY, maxX, maxY, closestBoxMinX, closestBoxMinY, closestBoxMaxX, closestBoxMaxY, closestCenterX, closestCenterY)
					local closestDot = MathUtil.dotProduct(toClosestX, toClosestY, 0, dirX, dirY, 0)
					if math.abs(closestDot - dot) < FocusManager.EPSILON then
						if 0 < dirY then
							useOther = closestOther.absPosition[1] < other.absPosition[1]
						elseif dirY < 0 then
							useOther = other.absPosition[1] < closestOther.absPosition[1]
						elseif 0 < dirX then
							useOther = closestOther.absPosition[2] < other.absPosition[2]
						elseif dirX < 0 then
							useOther = other.absPosition[2] < closestOther.absPosition[2]
						end
					elseif closestDot < dot then
						useOther = true
					end
				elseif boxDistanceSq < closestDistanceSq then
					useOther = true
				end
			end
			if useOther then
				retOther = other
				retDistSq = boxDistanceSq
			end
		end
	end
	return retOther, retDistSq
end
function FocusManager:getNextFocusElement(element, direction)
	local nextFocusId = element.focusChangeData[direction]
	if nextFocusId then
		return self.currentFocusData.idToElementMapping[nextFocusId], direction
	else
		local dirX, dirY = unpack(FocusManager.DIRECTION_VECTORS[direction])
		local closestOther = nil
		local closestDistance = math.huge
		for _, other in pairs(self.currentFocusData.idToElementMapping) do
			closestOther, closestDistance = FocusManager.checkElementDistance(element, other, dirX, dirY, 0, closestOther, closestDistance)
		end
		if closestOther == nil then
			if direction == FocusManager.LEFT then
				closestOther, direction = self:getNextFocusElement(element, FocusManager.TOP)
			elseif direction == FocusManager.RIGHT then
				closestOther, direction = self:getNextFocusElement(element, FocusManager.BOTTOM)
			else
				local validWrapElements = self.currentFocusData.idToElementMapping
				if element.parent and element.parent.wrapAround then
					validWrapElements = element.parent.elements
				end
				local wrapOffsetY = 0
				if direction == FocusManager.TOP then
					wrapOffsetY = -1.2 - element.size[2]
				elseif direction == FocusManager.BOTTOM then
					wrapOffsetY = 1.2 + element.size[2]
				end
				for _, other in pairs(validWrapElements) do
					closestOther, closestDistance = FocusManager.checkElementDistance(element, other, dirX, dirY, wrapOffsetY, closestOther, closestDistance)
				end
			end
		end
		return closestOther, direction
	end
end
function FocusManager.getNestedFocusTarget(element, direction)
	local target = element
	local prevTarget = nil
	while target do
		if prevTarget == target then
			break
		end
		prevTarget = target
		target = target:getFocusTarget(FocusManager.OPPOSING_DIRECTIONS[direction], direction)
	end
	return target
end
function FocusManager:updateFocus(element, direction, updateOnly)
	if element == nil then
		return
	end
	if self.lastInput[direction] then
		if g_time < self.lockUntil[direction] then
			return
		end
		self.lockUntil[direction] = g_time + self.SCROLL_DELAY_TIME
	else
		self.lockUntil[direction] = g_time + self.INITIAL_DELAY_TIME
	end
	if updateOnly then
		return
	end
	self.lastInput[direction] = g_time
	if self.currentFocusData.focusElement ~= element then
		return
	else
		if element:shouldFocusChange(direction) then
			local nextElement = nil
			local nextElementIsSet = nil
			if element.focusChangeOverride then
				if element.target then
					nextElementIsSet, nextElement = element.focusChangeOverride(element.target, direction)
				else
					nextElementIsSet, nextElement = element:focusChangeOverride(direction)
				end
			end
			local actualDirection = direction
			if not nextElementIsSet then
				nextElement, actualDirection = self:getNextFocusElement(element, direction)
			end
			if nextElement and nextElement:canReceiveFocus() then
				self:setFocus(nextElement, actualDirection)
				return
			end
			local focusElement = element
			nextElement = element
			if not element.focusChangeOverride or not element:focusChangeOverride(direction) then
				local maxSteps = 30
				while 0 < maxSteps do
					if nextElement == nil then
						break
					end
					nextElement, actualDirection = self:getNextFocusElement(nextElement, direction)
					if nextElement ~= nil and nextElement:canReceiveFocus() then
						focusElement = nextElement
						break
					end
					maxSteps = maxSteps - 1
				end
			end
			self:setFocus(focusElement, actualDirection)
		end
	end
end
function FocusManager:setHighlight(element)
	if not self.currentFocusData.highlightElement or self.currentFocusData.highlightElement ~= element then
		if not element.handleFocus then
		else
			self:unsetHighlight(self.currentFocusData.highlightElement)
			if not element.disallowFocusedHighlight or not self.currentFocusData.focusElement or self.currentFocusData.focusElement ~= element then
				self.currentFocusData.highlightElement = element
				element:onHighlight()
				if not element:getSoundSuppressed() and (element:getIsVisible() and (element.playHoverSoundOnFocus ~= false and not element.soundDisabled)) then
					self.soundPlayer:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
				end
			end
		end
	end
end
function FocusManager:unsetHighlight(element)
	if self.currentFocusData.highlightElement and self.currentFocusData.highlightElement == element then
		self.currentFocusData.highlightElement = nil
		element:onHighlightRemove()
	end
end
function FocusManager:setFocus(element, direction, ...)
	if FocusManager.isFocusLocked or element == nil or not element:canReceiveFocus() then
		return false
	end
	local targetElement = FocusManager.getNestedFocusTarget(element, direction)
	if targetElement.target == nil or targetElement.target.name ~= self.currentGui then
		return false
	end
	if self.currentFocusData.focusElement and (self.currentFocusData.focusElement == targetElement and self.currentFocusData.focusElement:getIsFocused()) then
		return false
	end
	if self.currentFocusData.focusElement ~= nil then
		self:unsetFocus(self.currentFocusData.focusElement)
		self:unsetHighlight(self.currentFocusData.highlightElement)
	end
	targetElement:setFocused(true)
	self.currentFocusData.focusElement = targetElement
	targetElement:onFocusEnter(...)
	if FocusManager.DEBUG then
		log("focus changed to element", targetElement, "; ID:", targetElement.id, "; profile:", targetElement.profile, "; type:", targetElement.typeName)
	end
	if not element:getSoundSuppressed() and (element:getIsVisible() and ((element.playHoverSoundOnFocus ~= false or targetElement.customFocusSample ~= nil) and not element.soundDisabled)) then
		self.soundPlayer:playSample(targetElement.customFocusSample or GuiSoundPlayer.SOUND_SAMPLES.HOVER)
	end
	return true
end
function FocusManager:unsetFocus(element, ...)
	local prevFocusElement = self.currentFocusData.focusElement
	if prevFocusElement ~= element or prevFocusElement == nil then
		return
	end
	if not element:getIsFocused() then
		return
	else
		prevFocusElement:onFocusLeave(...)
	end
end
function FocusManager:requireLock()
	FocusManager.isFocusLocked = true
end
function FocusManager:releaseLock()
	FocusManager.isFocusLocked = false
end
function FocusManager:isLocked()
	return FocusManager.isFocusLocked
end
function FocusManager:isDirectionLocked(direction)
	return self.lastInput[direction] ~= nil
end
function FocusManager:hasFocus(element)
	local _v4 = false
	if self.currentFocusData.focusElement == element then
		_v4 = element:getIsFocused()
	end
	return _v4
end
function FocusManager:getFocusOverrideFunction(forDirections, substitute, useSubstituteForFocus)
	if forDirections == nil or #forDirections < 1 then
		return function(elementSelf, dir)
			return false, nil
		end
	end
	local f = function(elementSelf, dir)
		for _, overrideDirection in pairs(forDirections) do
			if dir == overrideDirection then
				if useSubstituteForFocus then
					local next = self:getNextFocusElement(substitute, dir)
					if next then
						return true, next
					end
				else
					return true, substitute
				end
			end
		end
		return false, nil
	end
	return f
end
function FocusManager:deleteGuiFocusData(guiName)
	self.guiFocusData[guiName] = nil
end
function FocusManager:drawDebug()
	if self.currentFocusData.focusElement ~= nil then
		local element = self.currentFocusData.focusElement
		if element:getIsFocused() then
			drawFilledRect(element.absPosition[1], element.absPosition[2], element.size[1], element.size[2], 1, 0, 0, 0.5, nil, nil, nil, nil)
		end
	end
end
