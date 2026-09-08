-- Local values: allElements_mt
FocusManager = {
	["TOP"] = "top",
	["BOTTOM"] = "bottom",
	["LEFT"] = "left",
	["RIGHT"] = "right",
	["EPSILON"] = 0.00001,
	["INITIAL_DELAY_TIME"] = 350,
	["SCROLL_DELAY_TIME"] = 70
}
FocusManager.guiFocusData = {}
FocusManager.currentFocusData = {}
FocusManager.currentFocusData.focusElement = nil
FocusManager.currentFocusData.highlightElement = nil
FocusManager.currentFocusData.initialFocusElement = nil
FocusManager.isFocusLocked = false
FocusManager.lastInput = {}
FocusManager.lockUntil = {}
FocusManager.autoIDcount = 0
FocusManager.OPPOSING_DIRECTIONS = {
	[FocusManager.TOP] = FocusManager.BOTTOM,
	[FocusManager.BOTTOM] = FocusManager.TOP,
	[FocusManager.LEFT] = FocusManager.RIGHT,
	[FocusManager.RIGHT] = FocusManager.LEFT
}
FocusManager.DIRECTION_VECTORS = {
	[FocusManager.TOP] = { 0, 1 },
	[FocusManager.BOTTOM] = { 0, -1 },
	[FocusManager.LEFT] = { -1, 0 },
	[FocusManager.RIGHT] = { 1, 0 }
}
FocusManager.DEBUG = false
FocusManager.allElements = setmetatable({}, {
	["__mode"] = "k"
})

-- Local values: focusElement, highlightElement, focusElement, oldSound
function FocusManager:setGui(gui)
	if self.currentFocusData then
		local v3_ = self.currentFocusData.focusElement
		if v3_ then
			self:unsetFocus(v3_)
		end
		local v4_ = self.currentFocusData.highlightElement
		if v4_ then
			self:unsetHighlight(v4_)
		end
	end
	self.currentGui = gui
	self.currentFocusData = self.guiFocusData[gui]
	if self.currentFocusData then
		local v5_ = self.currentFocusData.initialFocusElement or self.currentFocusData.focusElement
		if v5_ ~= nil then
			local v6_ = v5_.soundDisabled
			v5_.soundDisabled = true
			self:setFocus(v5_)
			v5_.soundDisabled = v6_
		end
	else
		self.guiFocusData[gui] = {}
		self.guiFocusData[gui].idToElementMapping = {}
		self.currentFocusData = self.guiFocusData[gui]
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
	local v12_ = string.format("focusAuto_%d", FocusManager.autoIDcount)
	FocusManager.autoIDcount = FocusManager.autoIDcount + 1
	return v12_
end

-- Local values: focusId, isAlwaysFocusedOnOpen, focusChangeOverride, old
function FocusManager:loadElementFromXML(xmlFile, xmlBaseNode, element)
	local v17_ = getXMLString(xmlFile, xmlBaseNode .. "#focusId") or FocusManager.serveAutoFocusId()
	element.focusId = v17_
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
	local v18_ = getXMLString(xmlFile, xmlBaseNode .. "#focusInit") == "onOpen"
	element.isAlwaysFocusedOnOpen = v18_
	local v19_ = getXMLString(xmlFile, xmlBaseNode .. "#focusChangeOverride")
	if v19_ then
		if element.target and element.target.focusChangeOverride then
			element.focusChangeOverride = element.target[v19_]
		else
			self.focusChangeOverride = ClassUtil.getFunction(v19_)
		end
	end
	if FocusManager.allElements[element] == nil then
		FocusManager.allElements[element] = {}
	end
	local v20_ = FocusManager.allElements[element]
	local v21_ = self.currentGui
	table.insert(v20_, v21_)
	self.currentFocusData.idToElementMapping[v17_] = element
	if v18_ then
		self.currentFocusData.initialFocusElement = element
		local v22_ = element.soundDisabled
		element.soundDisabled = true
		self:setFocus(element)
		element.soundDisabled = v22_
	elseif not self.currentFocusData.focusElement then
		self.currentFocusData.focusElement = element
	end
end

-- Local values: success, _, child
function FocusManager:loadElementFromCustomValues(element, focusId, focusChangeData, focusActive, isAlwaysFocusedOnOpen)
	if focusId and self.currentFocusData.idToElementMapping[focusId] then
		return false
	end
	if not element.focusId then
		element.focusId = focusId or FocusManager.serveAutoFocusId()
	end
	element.focusChangeData = element.focusChangeData or (focusChangeData or {})
	element.isAlwaysFocusedOnOpen = isAlwaysFocusedOnOpen
	if FocusManager.allElements[element] == nil then
		FocusManager.allElements[element] = {}
	end
	local v29_ = FocusManager.allElements[element]
	local v30_ = self.currentGui
	table.insert(v29_, v30_)
	self.currentFocusData.idToElementMapping[element.focusId] = element
	if isAlwaysFocusedOnOpen then
		self.currentFocusData.initialFocusElement = element
	end
	if focusActive then
		self:setFocus(element)
	end
	local v31_ = true
	for _, v32_ in pairs(element.elements) do
		if v31_ then
			v31_ = self:loadElementFromCustomValues(v32_, v32_.focusId, v32_.focusChangeData, v32_.focusActive, v32_.isAlwaysFocusedOnOpen)
		end
	end
	return v31_
end

-- Local values: _, child, _, guiItWasAddedTo, data
function FocusManager:removeElement(element)
	if element.focusId then
		for _, v35_ in pairs(element.elements) do
			self:removeElement(v35_)
		end
		if element:getIsFocused() then
			element:onFocusLeave()
			FocusManager:unsetFocus(element)
		end
		if FocusManager.allElements[element] ~= nil then
			for _, v36_ in ipairs(FocusManager.allElements[element]) do
				local v37_ = self.guiFocusData[v36_]
				v37_.idToElementMapping[element.focusId] = nil
				if v37_.focusElement == element then
					v37_.focusElement = nil
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

-- Local values: element, pressedAccept, direction
function FocusManager:inputEvent(action, value, eventUsed)
	local v45_ = self.currentFocusData.focusElement
	local v46_ = false
	local v47_ = nil
	if action == InputAction.MENU_AXIS_UP_DOWN and g_analogStickVTolerance < value then
		v47_ = FocusManager.TOP
	elseif action == InputAction.MENU_AXIS_UP_DOWN and value < -g_analogStickVTolerance then
		v47_ = FocusManager.BOTTOM
	elseif action == InputAction.MENU_AXIS_LEFT_RIGHT and value < -g_analogStickHTolerance then
		v47_ = FocusManager.LEFT
	elseif action == InputAction.MENU_AXIS_LEFT_RIGHT and g_analogStickHTolerance < value then
		v47_ = FocusManager.RIGHT
	end
	if v47_ ~= nil then
		self:updateFocus(v45_, v47_, eventUsed)
	end
	if not eventUsed and (v45_ ~= nil and not v45_.needExternalClick) then
		v46_ = action == InputAction.MENU_ACCEPT
		if v46_ and (not self:isFocusInputLocked(action) and (v45_:getIsFocused() and v45_:getIsVisible())) then
			self.focusSystemMadeChanges = true
			v45_:onFocusActivate()
			self.focusSystemMadeChanges = false
		end
	end
	return eventUsed or (v47_ ~= nil and true or v46_)
end

-- Local values: direction
function FocusManager.getDirectionForAxisValue(inputAction, value)
	if value == nil then
		return nil
	end
	local v50_ = nil
	if inputAction == InputAction.MENU_AXIS_UP_DOWN then
		if value < 0 then
			return FocusManager.BOTTOM
		end
		if value > 0 then
			return FocusManager.TOP
		end
	elseif inputAction == InputAction.MENU_AXIS_LEFT_RIGHT then
		if value < 0 then
			return FocusManager.LEFT
		end
		if value > 0 then
			v50_ = FocusManager.RIGHT
		end
	end
	return v50_
end

-- Local values: key
function FocusManager:isFocusInputLocked(inputAxis, value)
	local v54_ = FocusManager.getDirectionForAxisValue(inputAxis, value)
	if v54_ == nil and inputAxis ~= InputAction.MENU_AXIS_UP_DOWN then
		if inputAxis == InputAction.MENU_AXIS_LEFT_RIGHT then
			inputAxis = v54_
		end
	else
		inputAxis = v54_
	end
	return self.lastInput[inputAxis] and self.lockUntil[inputAxis] > g_time and true or false
end

-- Local values: key
function FocusManager:lockFocusInput(axisAction, delay, value)
	local v59_ = FocusManager.getDirectionForAxisValue(axisAction, value)
	if v59_ or axisAction == InputAction.MENU_AXIS_UP_DOWN then
		axisAction = v59_
	elseif axisAction == InputAction.MENU_AXIS_LEFT_RIGHT then
		axisAction = v59_
	end
	self.lastInput[axisAction] = g_time
	self.lockUntil[axisAction] = g_time + delay
end

function FocusManager:releaseMovementFocusInput(action)
	if action == InputAction.MENU_AXIS_LEFT_RIGHT then
		self.lastInput[FocusManager.LEFT] = nil
		self.lockUntil[FocusManager.LEFT] = nil
		self.lastInput[FocusManager.RIGHT] = nil
		self.lockUntil[FocusManager.RIGHT] = nil
	elseif action == InputAction.MENU_AXIS_UP_DOWN then
		self.lastInput[FocusManager.TOP] = nil
		self.lockUntil[FocusManager.TOP] = nil
		self.lastInput[FocusManager.BOTTOM] = nil
		self.lockUntil[FocusManager.BOTTOM] = nil
	end
end

-- Local values: k, _, k, _
function FocusManager:resetFocusInputLocks()
	for v63_, _ in pairs(self.lastInput) do
		self.lastInput[v63_] = nil
	end
	for v64_, _ in pairs(self.lockUntil) do
		self.lockUntil[v64_] = 0
	end
end

-- Local values: px, py
function FocusManager.getClosestPointOnBoundingBox(x, y, boxMinX, boxMinY, boxMaxX, boxMaxY)
	if x < boxMinX then
		boxMaxX = boxMinX
	elseif boxMaxX >= x then
		boxMaxX = x
	end
	if y < boxMinY then
		return boxMaxX, boxMinY
	end
	if boxMaxY >= y then
		boxMaxY = y
	end
	return boxMaxX, boxMaxY
end

-- Local values: ePointX, ePointY, oPointX, oPointY, elementDirX, elementDirY
function FocusManager.getShortestBoundingBoxVector(minX, minY, maxX, maxY, otherBoxMinX, otherBoxMinY, otherBoxMaxX, otherBoxMaxY, otherCenterX, otherCenterY)
	local v81_, v82_ = FocusManager.getClosestPointOnBoundingBox(otherCenterX, otherCenterY, minX, minY, maxX, maxY)
	local v83_, v84_ = FocusManager.getClosestPointOnBoundingBox(v81_, v82_, otherBoxMinX, otherBoxMinY, otherBoxMaxX, otherBoxMaxY)
	return v83_ - v81_, v84_ - v82_
end

-- Local values: retOther, retDistSq, minX, minY, maxX, maxY, centerX, centerY, otherBoxMinX, otherBoxMinY, otherBoxMaxX, otherBoxMaxY, otherCenterX, otherCenterY, elementDirX, elementDirY, boxDistanceSq, dot, useOther, closestBoxMinX, closestBoxMinY, closestBoxMaxX, closestBoxMaxY, closestCenterX, closestCenterY, toClosestX, toClosestY, closestDot
function FocusManager.checkElementDistance(curElement, other, dirX, dirY, curElementOffsetY, closestOther, closestDistanceSq)
	local v92_, v93_, v94_, v95_ = curElement:getBorders()
	local v96_ = v93_ + curElementOffsetY
	local v97_ = v95_ + curElementOffsetY
	local v98_, v99_ = curElement:getCenter()
	local v100_ = v99_ + curElementOffsetY
	local v101_
	if other == curElement or (other.disabled or (not other:getIsVisible() or (not other:canReceiveFocus() or (other:isChildOf(curElement) or curElement:isChildOf(other))))) then
		v101_ = closestDistanceSq
		other = closestOther
	else
		local v102_, v103_, v104_, v105_ = other:getBorders()
		local v106_, v107_ = other:getCenter()
		local v108_, v109_ = FocusManager.getShortestBoundingBoxVector(v92_, v96_, v94_, v97_, v102_, v103_, v104_, v105_, v106_, v107_)
		v101_ = MathUtil.vector2LengthSq(v108_, v109_)
		local v110_ = MathUtil.dotProduct(v108_, v109_, 0, dirX, dirY, 0)
		if v101_ < FocusManager.EPSILON then
			v110_ = MathUtil.dotProduct(v106_ - v98_, v107_ - v100_, 0, dirX, dirY, 0)
		end
		if v110_ > 0 then
			local v111_ = false
			if closestOther then
				local v112_ = closestDistanceSq - v101_
				if math.abs(v112_) < FocusManager.EPSILON then
					local v113_, v114_, v115_, v116_ = closestOther:getBorders()
					local v117_, v118_ = closestOther:getCenter()
					local v119_, v120_ = FocusManager.getShortestBoundingBoxVector(v92_, v96_, v94_, v97_, v113_, v114_, v115_, v116_, v117_, v118_)
					local v121_ = MathUtil.dotProduct(v119_, v120_, 0, dirX, dirY, 0)
					local v122_ = v121_ - v110_
					if math.abs(v122_) < FocusManager.EPSILON then
						if dirY > 0 then
							v111_ = other.absPosition[1] > closestOther.absPosition[1]
						elseif dirY < 0 then
							v111_ = other.absPosition[1] < closestOther.absPosition[1]
						elseif dirX > 0 then
							v111_ = other.absPosition[2] > closestOther.absPosition[2]
						elseif dirX < 0 then
							v111_ = other.absPosition[2] < closestOther.absPosition[2]
						end
					else
						v111_ = v121_ < v110_ and true or v111_
					end
					::l21::
					if not v111_ then
						v101_ = closestDistanceSq
						other = closestOther
					end
					goto l2
				end
			end
			v111_ = v101_ < closestDistanceSq and true or v111_
			goto l21
		end
		v101_ = closestDistanceSq
		other = closestOther
	end
	::l2::
	return other, v101_
end

-- Local values: nextFocusId, dirX, dirY, closestOther, closestDistance, _, other, validWrapElements, wrapOffsetY, _, other
function FocusManager:getNextFocusElement(element, direction)
	local v126_ = element.focusChangeData[direction]
	if v126_ then
		return self.currentFocusData.idToElementMapping[v126_], direction
	end
	local v127_ = FocusManager.DIRECTION_VECTORS[direction]
	local v128_, v129_ = unpack(v127_)
	local v130_ = nil
	local v131_ = math.huge
	for _, v132_ in pairs(self.currentFocusData.idToElementMapping) do
		v130_, v131_ = FocusManager.checkElementDistance(element, v132_, v128_, v129_, 0, v130_, v131_)
	end
	if v130_ == nil then
		if direction == FocusManager.LEFT then
			v130_, direction = self:getNextFocusElement(element, FocusManager.TOP)
		elseif direction == FocusManager.RIGHT then
			v130_, direction = self:getNextFocusElement(element, FocusManager.BOTTOM)
		else
			local v133_ = self.currentFocusData.idToElementMapping
			if element.parent and element.parent.wrapAround then
				v133_ = element.parent.elements
			end
			local v134_ = 0
			if direction == FocusManager.TOP then
				v134_ = -1.2 - element.size[2]
			elseif direction == FocusManager.BOTTOM then
				v134_ = 1.2 + element.size[2]
			end
			for _, v135_ in pairs(v133_) do
				v130_, v131_ = FocusManager.checkElementDistance(element, v135_, v128_, v129_, v134_, v130_, v131_)
			end
		end
	end
	return v130_, direction
end

-- Local values: target, prevTarget
function FocusManager.getNestedFocusTarget(element, direction)
	local v138_ = nil
	while element and v138_ ~= element do
		local v139_ = element:getFocusTarget(FocusManager.OPPOSING_DIRECTIONS[direction], direction)
		v138_ = element
		element = v139_
	end
	return element
end

-- Local values: nextElement, nextElementIsSet, actualDirection, focusElement, maxSteps
function FocusManager:updateFocus(element, direction, updateOnly)
	if element == nil then
		return
	end
	if self.lastInput[direction] then
		if self.lockUntil[direction] > g_time then
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
	end
	if element:shouldFocusChange(direction) then
		local v144_, v145_
		if element.focusChangeOverride then
			if element.target then
				v144_, v145_ = element.focusChangeOverride(element.target, direction)
			else
				v144_, v145_ = element:focusChangeOverride(direction)
			end
		else
			v144_ = nil
			v145_ = nil
		end
		local v146_
		if v144_ then
			v146_ = direction
		else
			v145_, v146_ = self:getNextFocusElement(element, direction)
		end
		if v145_ and v145_:canReceiveFocus() then
			self:setFocus(v145_, v146_)
			return
		end
		if not (element.focusChangeOverride and element:focusChangeOverride(direction)) then
			local v147_ = element
			local v148_ = 30
			while true do
				if v148_ <= 0 or element == nil then
					element = v147_
					break
				end
				element, v146_ = self:getNextFocusElement(element, direction)
				if element ~= nil and element:canReceiveFocus() then
					break
				end
				v148_ = v148_ - 1
			end
		end
		self:setFocus(element, v146_)
	end
end

function FocusManager:setHighlight(element)
	if (not self.currentFocusData.highlightElement or self.currentFocusData.highlightElement ~= element) and element.handleFocus then
		self:unsetHighlight(self.currentFocusData.highlightElement)
		if not element.disallowFocusedHighlight or (not self.currentFocusData.focusElement or self.currentFocusData.focusElement ~= element) then
			self.currentFocusData.highlightElement = element
			element:onHighlight()
			if not element:getSoundSuppressed() and (element:getIsVisible() and (element.playHoverSoundOnFocus ~= false and not element.soundDisabled)) then
				self.soundPlayer:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
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
function FocusManager.setFocus(p153_, p154_, p155_, ...)
	if FocusManager.isFocusLocked or (p154_ == nil or not p154_:canReceiveFocus()) then
		return false
	end
	local v156_ = FocusManager.getNestedFocusTarget(p154_, p155_)
	if v156_.target == nil or v156_.target.name ~= p153_.currentGui then
		return false
	end
	if p153_.currentFocusData.focusElement and (p153_.currentFocusData.focusElement == v156_ and p153_.currentFocusData.focusElement:getIsFocused()) then
		return false
	end
	if p153_.currentFocusData.focusElement ~= nil then
		p153_:unsetFocus(p153_.currentFocusData.focusElement)
		p153_:unsetHighlight(p153_.currentFocusData.highlightElement)
	end
	v156_:setFocused(true)
	p153_.currentFocusData.focusElement = v156_
	v156_:onFocusEnter(...)
	if FocusManager.DEBUG then
		log("focus changed to element", v156_, "; ID:", v156_.id, "; profile:", v156_.profile, "; type:", v156_.typeName)
	end
	if not p154_:getSoundSuppressed() and (p154_:getIsVisible() and (p154_.playHoverSoundOnFocus ~= false or v156_.customFocusSample ~= nil)) and not p154_.soundDisabled then
		p153_.soundPlayer:playSample(v156_.customFocusSample or GuiSoundPlayer.SOUND_SAMPLES.HOVER)
	end
	return true
end
function FocusManager.unsetFocus(p157_, p158_, ...)
	local v159_ = p157_.currentFocusData.focusElement
	if v159_ == p158_ and v159_ ~= nil then
		if p158_:getIsFocused() then
			v159_:onFocusLeave(...)
		end
	else
		return
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
	local v164_
	if self.currentFocusData.focusElement == element then
		v164_ = element:getIsFocused()
	else
		v164_ = false
	end
	return v164_
end

-- Local values: f
function FocusManager:getFocusOverrideFunction(forDirections, substitute, useSubstituteForFocus)
	return (forDirections == nil or #forDirections < 1) and function(_, _)
		return false, nil
	end or function(_, p169_)
		-- upvalues: (copy) forDirections, (copy) useSubstituteForFocus, (copy) self, (copy) substitute
		for _, v170_ in pairs(forDirections) do
			if p169_ == v170_ then
				if not useSubstituteForFocus then
					return true, substitute
				end
				local v171_ = self:getNextFocusElement(substitute, p169_)
				if v171_ then
					return true, v171_
				end
			end
		end
		return false, nil
	end
end

function FocusManager:deleteGuiFocusData(guiName)
	self.guiFocusData[guiName] = nil
end

-- Local values: element
function FocusManager:drawDebug()
	if self.currentFocusData.focusElement ~= nil then
		local v175_ = self.currentFocusData.focusElement
		if v175_:getIsFocused() then
			drawFilledRect(v175_.absPosition[1], v175_.absPosition[2], v175_.size[1], v175_.size[2], 1, 0, 0, 0.5, nil, nil, nil, nil)
		end
	end
end
