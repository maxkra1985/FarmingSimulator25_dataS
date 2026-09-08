-- Local values: IntroductionHelpSystem_mt
IntroductionHelpSystem = {}
local IntroductionHelpSystem_mt = Class(IntroductionHelpSystem)
IntroductionHelpSystem.FILENAME = "dataS/introductionHints.xml"

-- Upvalues: IntroductionHelpSystem_mt
-- Local values: self
function IntroductionHelpSystem.new(custom_mt)
	-- upvalues: (copy) IntroductionHelpSystem_mt
	local v3_ = custom_mt or IntroductionHelpSystem_mt
	local v4_ = setmetatable({}, v3_)
	v4_.registeredElements = {}
	v4_.registeredHints = {}
	v4_.shownHints = {}
	v4_.drawHelpQueue = {}
	g_messageCenter:subscribe(MessageType.GUI_BEFORE_OPEN, v4_.onMenuOpen, v4_)
	g_messageCenter:subscribe(MessageType.APP_SUSPENDED, v4_.onAppSuspended, v4_)
	return v4_
end

function IntroductionHelpSystem:delete()
	g_messageCenter:unsubscribeAll(self)
end

-- Local values: helpItem
function IntroductionHelpSystem:registerHelp(name, target, drawFunction, availableFunction, registerCustomInputFunction, unregisterCustomInputFunction)
	if drawFunction == nil then
		Logging.devError("Could not register introduction help. Drawfunction is not defined!")
		printCallstack()
	else
		local v13_ = self.registeredElements[name]
		if v13_ == nil then
			v13_ = {
				["name"] = name,
				["alreadyShown"] = false,
				["waitingForDraw"] = false,
				["canReset"] = true
			}
			self.registeredElements[name] = v13_
		end
		v13_.drawFunction = drawFunction
		v13_.availableFunction = availableFunction
		v13_.registerCustomInputFunction = registerCustomInputFunction
		v13_.unregisterCustomInputFunction = unregisterCustomInputFunction
		v13_.target = target
	end
end

-- Local values: hint
function IntroductionHelpSystem:registerHint(name, text, isInitialActive)
	if self.registeredHints[name] == nil then
		local v18_ = {
			["name"] = name,
			["text"] = text,
			["alreadyShown"] = Utils.getNoNil(isInitialActive, false)
		}
		if isInitialActive then
			local v19_ = self.shownHints
			table.insert(v19_, text)
		end
		self.registeredHints[name] = v18_
	end
end

-- Local values: missionInfo, shownElements, shownElementsStr, _, elementName, shownHints, shownHintsStr, _, hintName
function IntroductionHelpSystem:loadShownElements()
	local v21_ = g_currentMission.missionInfo
	local v22_ = v21_ == nil and "" or v21_.introductionHelpShownElements
	local v23_ = string.split(v22_, " ")
	for _, v24_ in ipairs(v23_) do
		if v24_ ~= "" then
			if self.registeredElements[v24_] == nil then
				self.registeredElements[v24_] = {}
			end
			self.registeredElements[v24_].alreadyShown = true
			self.registeredElements[v24_].canReset = false
		end
	end
	local v25_ = v21_ == nil and "" or v21_.introductionHelpShownHints
	local v26_ = string.split(v25_, " ")
	for _, v27_ in ipairs(v26_) do
		if v27_ ~= "" and self.registeredHints[v27_] == false then
			self.registeredHints[v27_].alreadyShown = true
			local v28_ = self.shownHints
			local v29_ = self.registeredHints[v27_].text
			table.insert(v28_, v29_)
		end
	end
end

-- Local values: xmlFile
function IntroductionHelpSystem:loadHelpElementsFromXML()
	local v_u_31_ = XMLFile.load("introductionHelpElementsXML", IntroductionHelpSystem.FILENAME)
	if v_u_31_ then
		v_u_31_:iterate("hints.hint", function(_, p32_)
			-- upvalues: (copy) v_u_31_, (copy) self
			local v33_ = v_u_31_:getString(p32_ .. "#id")
			local v34_ = v_u_31_:getString(p32_ .. "#text")
			if v33_ ~= nil and v34_ ~= nil then
				self:registerHint(v33_, g_i18n:convertText(v34_), (v_u_31_:getBool(p32_ .. "#initialActive", false)))
			end
		end)
		v_u_31_:delete()
	end
end

-- Local values: shownElements, elementName, element, missionInfo, shownHints, hintName, hint
function IntroductionHelpSystem:saveShownElements()
	local v36_ = ""
	for v37_, v38_ in pairs(self.registeredElements) do
		if v38_.alreadyShown then
			v36_ = v36_ .. v37_ .. " "
		end
	end
	local v39_ = g_currentMission.missionInfo
	if v39_ ~= nil then
		v39_.introductionHelpShownElements = v36_
	end
	local v40_ = ""
	for _, v41_ in pairs(self.registeredHints) do
		if v41_.alreadyShown then
			v40_ = v40_ .. v41_.name .. " "
		end
	end
	if v39_ ~= nil then
		v39_.introductionHelpShownHints = v40_
	end
end

-- Local values: missionInfo
function IntroductionHelpSystem:setIsActive(isActive)
	local v43_ = g_currentMission.missionInfo
	if v43_ ~= nil then
		v43_.introductionHelpActive = isActive
	end
end

function IntroductionHelpSystem:getIsActive()
	local v44_ = not g_guidedTourManager:getIsTourRunning()
	if v44_ then
		v44_ = g_currentMission.missionInfo.introductionHelpActive
	end
	return v44_
end

function IntroductionHelpSystem:getIsHelpVisible()
	return self.currentElement ~= nil
end

-- Local values: element
function IntroductionHelpSystem:showHelp(name, forced, blockInput, customText, callback, callbackTarget)
	local v53_ = self.registeredElements[name]
	if v53_ == nil or v53_.drawFunction == nil or (v53_.alreadyShown or v53_.waitingForDraw) and not forced then
		if callback ~= nil then
			callback(callbackTarget)
		end
	else
		v53_.waitingForDraw = true
		v53_.blockInput = Utils.getNoNil(blockInput, true)
		v53_.customText = customText
		v53_.callback = callback
		v53_.callbackTarget = callbackTarget
		table.addElement(self.drawHelpQueue, v53_)
	end
end

-- Local values: element
function IntroductionHelpSystem:hideHelp(name, forced)
	local v57_ = self.registeredElements[name]
	if v57_ ~= nil and (v57_.canReset or forced) then
		v57_.waitingForDraw = false
		table.removeElement(self.drawHelpQueue, v57_)
		if v57_ == self.currentElement then
			self:revertInputContext()
			if self.currentElement.callback ~= nil then
				self.currentElement.callback(self.currentElement.callbackTarget)
			end
			self.currentElement = nil
		end
	end
end

-- Local values: _, element
function IntroductionHelpSystem:hideAll()
	for _, v59_ in ipairs(self.drawHelpQueue) do
		self.registeredElements[v59_.name].alreadyShown = true
	end
	self:saveShownElements()
	self.drawHelpQueue = {}
	if self.currentElement ~= nil then
		self:onContinueNext()
	end
end

-- Local values: hint
function IntroductionHelpSystem:showHint(name, callback, target)
	local v64_ = self.registeredHints[name]
	if v64_ ~= nil and not v64_.alreadyShown then
		InfoDialog.show(v64_.text, callback, target)
		local v65_ = self.shownHints
		local v66_ = v64_.text
		table.insert(v65_, v66_)
		v64_.alreadyShown = true
		self:saveShownElements()
	end
end

-- Local values: element
function IntroductionHelpSystem:resetElement(elementName, forced)
	local v70_ = self.registeredElements[elementName]
	if v70_ ~= nil and (v70_.canReset or forced) then
		v70_.alreadyShown = false
		v70_.waitingForDraw = false
		table.removeElement(self.drawHelpQueue, v70_)
		if v70_ == self.currentElement then
			self:revertInputContext()
			if self.currentElement.callback ~= nil then
				self.currentElement.callback(self.currentElement.callbackTarget)
			end
			self.currentElement = nil
		end
	end
end

function IntroductionHelpSystem:getCanShowHelp()
	if g_gui:getIsGuiVisible() then
		return false
	else
		return not g_appIsSuspended
	end
end

-- Local values: element, isAvailable, _, eventId, isAvailable
function IntroductionHelpSystem:update(dt)
	if self.currentElement == nil and self:getCanShowHelp() then
		while #self.drawHelpQueue > 0 do
			local v72_ = table.remove(self.drawHelpQueue, 1)
			self.registeredElements[v72_.name].alreadyShown = true
			self:saveShownElements()
			if v72_.availableFunction ~= nil and not v72_.availableFunction(v72_.target) then
				v72_ = nil
			end
			if v72_ ~= nil then
				if v72_.blockInput then
					if v72_.registerCustomInputFunction == nil then
						g_inputBinding:setContext(v72_.name)
						local _, v73_ = g_inputBinding:registerActionEvent(InputAction.INTRODUCTION_HELP_SKIP, self, self.onContinueNext, false, true, false, true)
						g_inputBinding:setActionEventText(v73_, g_i18n:getText("button_continue"))
						if g_touchHandler ~= nil then
							g_touchHandler:setCustomContext(v72_.name, true)
							self.currentTouchArea = g_touchHandler:registerTouchArea(0, 0, 1, 1, 0, 0, TouchHandler.TRIGGER_UP, self.onContinueNextTouch, self)
						end
					else
						v72_.registerCustomInputFunction(v72_.target)
					end
				end
				self.currentElement = v72_
				break
			end
		end
	end
	if self.currentElement ~= nil and (self.currentElement.availableFunction ~= nil and not self.currentElement.availableFunction(self.currentElement.target)) then
		self:onContinueNext()
	end
end

function IntroductionHelpSystem:draw()
	if self.currentElement ~= nil then
		new2DLayer()
		self.currentElement.drawFunction(self.currentElement.target, self.currentElement.customText)
	end
end

function IntroductionHelpSystem:onMenuOpen()
	local _ = self.currentElement == nil
end

function IntroductionHelpSystem:onAppSuspended()
	local _ = self.currentElement == nil
end

-- Local values: element
function IntroductionHelpSystem:revertInputContext()
	local v78_ = self.currentElement
	if v78_ ~= nil and v78_.blockInput then
		if v78_.unregisterCustomInputFunction == nil then
			if g_touchHandler ~= nil then
				g_touchHandler:revertCustomContext()
				if self.currentTouchArea ~= nil then
					g_touchHandler:removeTouchArea(self.currentTouchArea)
					self.currentTouchArea = nil
				end
			end
			g_inputBinding:removeActionEventsByTarget(self)
			g_inputBinding:revertContext()
			return
		end
		v78_.unregisterCustomInputFunction(v78_.target)
	end
end

function IntroductionHelpSystem:onContinueNextTouch()
	if not g_gui:getIsGuiVisible() then
		self:onContinueNext()
	end
end

function IntroductionHelpSystem:onContinueNext()
	if self.currentElement ~= nil then
		self.currentElement.canReset = false
		self:revertInputContext()
		if self.currentElement.callback ~= nil then
			self.currentElement.callback(self.currentElement.callbackTarget)
		end
		self.currentElement = nil
	end
end

function IntroductionHelpSystem:getShownHints()
	return self.shownHints
end

-- Local values: _, element
function IntroductionHelpSystem:resetHelpSystem()
	for _, v83_ in pairs(self.registeredElements) do
		v83_.alreadyShown = false
		if v83_.waitingForDraw ~= nil then
			v83_.waitingForDraw = false
		end
	end
end

-- Local values: _, element
function IntroductionHelpSystem:resetHelpSystemWithDraw()
	for _, v85_ in pairs(self.registeredElements) do
		if v85_.alreadyShown == true then
			v85_.waitingForDraw = true
			v85_.alreadyShown = false
			local v86_ = self.drawHelpQueue
			table.insert(v86_, v85_)
		end
	end
end
