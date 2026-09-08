-- Local values: MultiTextOptionElement_mt
MultiTextOptionElement = {}
MultiTextOptionElement.ELEMENT_BG = 1
MultiTextOptionElement.ELEMENT_LEFT = 2
MultiTextOptionElement.ELEMENT_RIGHT = 3
MultiTextOptionElement.ELEMENT_TEXT = 4
MultiTextOptionElement.FIRST_INPUT_DELAY = 400
MultiTextOptionElement.INPUT_DELAY = 200
MultiTextOptionElement.FAST_SCROLL_DELAY = 1800
local MultiTextOptionElement_mt = Class(MultiTextOptionElement, GuiElement)
Gui.registerGuiElement("MultiTextOption", MultiTextOptionElement)
Gui.registerGuiElementProcFunction("MultiTextOption", Gui.assignPlaySampleCallback)

-- Upvalues: MultiTextOptionElement_mt
-- Local values: self
function MultiTextOptionElement.new(target, custom_mt)
	-- upvalues: (copy) MultiTextOptionElement_mt
	local v4_ = GuiElement.new(target, custom_mt or MultiTextOptionElement_mt)
	v4_:include(IndexChangeSubjectMixin)
	v4_:include(PlaySampleMixin)
	v4_.isChecked = false
	v4_.inputEntered = false
	v4_.buttonLRChange = false
	v4_.canChangeState = true
	v4_.state = 1
	v4_.wrap = true
	v4_.hideLeftRightButtons = false
	v4_.hideButtonOnLimitReached = false
	v4_.disableButtonsOnSingleText = false
	v4_.texts = {}
	v4_.registerContinuousInput = true
	v4_.continuousInputStep = nil
	v4_.useDynamicInputSteps = nil
	v4_.dynamicInputStep = nil
	v4_.continuousTriggerTime = 0
	v4_.isLeftButtonPressed = false
	v4_.isRightButtonPressed = false
	v4_.wasContinuousTrigger = false
	v4_.scrollDelayDuration = MultiTextOptionElement.FIRST_INPUT_DELAY
	v4_.baseScrollDelayDuration = MultiTextOptionElement.INPUT_DELAY
	v4_.leftDelayTime = 0
	v4_.rightDelayTime = 0
	v4_.delayTime = 0
	v4_.leftButtonElement = nil
	v4_.rightButtonElement = nil
	v4_.textElement = nil
	v4_.labelElement = nil
	v4_.iconElement = nil
	v4_.bgElement = nil
	v4_.defaultProfileButtonLeft = nil
	v4_.defaultProfileButtonRight = nil
	v4_.defaultProfileText = nil
	v4_.defaultProfileBg = nil
	v4_.defaultProfileBgRound = nil
	v4_.defaultProfileBgThreePart = nil
	v4_.autoAddDefaultElements = false
	v4_.gradientElements = {}
	return v4_
end

-- Local values: xmlFilename, modName, _, text, texts, _, textPart
function MultiTextOptionElement:loadFromXML(xmlFile, key)
	local v8_ = getXMLFilename(xmlFile)
	local v9_, _ = Utils.getModNameAndBaseDirectory(v8_)
	if v9_ ~= nil then
		self.customEnvironment = v9_
	end
	MultiTextOptionElement:superClass().loadFromXML(self, xmlFile, key)
	self:addCallback(xmlFile, key .. "#onClick", "onClickCallback")
	self:addCallback(xmlFile, key .. "#onFocus", "onFocusCallback")
	self:addCallback(xmlFile, key .. "#onLeave", "onLeaveCallback")
	self.wrap = Utils.getNoNil(getXMLBool(xmlFile, key .. "#wrap"), self.wrap)
	self.hideLeftRightButtons = Utils.getNoNil(getXMLBool(xmlFile, key .. "#hideLeftRightButtons"), self.hideLeftRightButtons)
	self.hideButtonOnLimitReached = Utils.getNoNil(getXMLBool(xmlFile, key .. "#hideButtonOnLimitReached"), self.hideButtonOnLimitReached)
	self.disableButtonsOnSingleText = Utils.getNoNil(getXMLBool(xmlFile, key .. "#disableButtonsOnSingleText"), self.disableButtonsOnSingleText)
	self.buttonLRChange = Utils.getNoNil(getXMLBool(xmlFile, key .. "#buttonLRChange"), self.buttonLRChange)
	self.baseScrollDelayDuration = getXMLInt(xmlFile, key .. "#scrollDelayDuration") or self.baseScrollDelayDuration
	self.continuousInputStep = getXMLInt(xmlFile, key .. "#continuousInputStep") or self.continuousInputStep
	self.useDynamicInputSteps = Utils.getNoNil(getXMLBool(xmlFile, key .. "#useDynamicInputSteps"), self.useDynamicInputSteps)
	self.registerContinuousInput = Utils.getNoNil(getXMLBool(xmlFile, key .. "#registerContinuousInput"), self.registerContinuousInput)
	local v10_ = getXMLString(xmlFile, key .. "#texts")
	if v10_ ~= nil then
		local v11_ = v10_:split("|")
		for _, v13_ in pairs(v11_) do
			if v13_:sub(1, 6) == "$l10n_" then
				local v13_ = g_i18n:getText(v13_:sub(7), self.customEnvironment)
			end
			local v14_ = self.texts
			table.insert(v14_, v13_)
		end
	end
	self.xmlFile = xmlFile
	self.xmlKey = key
end

-- Local values: text, texts, _, textPart
function MultiTextOptionElement:loadProfile(profile, applyProfile)
	MultiTextOptionElement:superClass().loadProfile(self, profile, applyProfile)
	self.wrap = profile:getBool("wrap", self.wrap)
	self.hideLeftRightButtons = profile:getBool("hideLeftRightButtons", self.hideLeftRightButtons)
	self.hideButtonOnLimitReached = profile:getBool("hideButtonOnLimitReached", self.hideButtonOnLimitReached)
	self.disableButtonsOnSingleText = profile:getBool("disableButtonsOnSingleText", self.disableButtonsOnSingleText)
	self.buttonLRChange = profile:getBool("buttonLRChange", self.buttonLRChange)
	self.baseScrollDelayDuration = profile:getNumber("scrollDelayDuration", self.baseScrollDelayDuration)
	self.continuousInputStep = profile:getNumber("continuousInputStep", self.continuousInputStep)
	self.useDynamicInputSteps = profile:getBool("useDynamicInputSteps", self.useDynamicInputSteps)
	self.registerContinuousInput = profile:getBool("registerContinuousInput", self.registerContinuousInput)
	self.defaultProfileButtonLeft = profile:getValue("defaultProfileButtonLeft", self.defaultProfileButtonLeft)
	self.defaultProfileButtonRight = profile:getValue("defaultProfileButtonRight", self.defaultProfileButtonRight)
	self.defaultProfileText = profile:getValue("defaultProfileText", self.defaultProfileText)
	self.defaultProfileBg = profile:getValue("defaultProfileBg", self.defaultProfileBg)
	self.defaultProfileBgRound = profile:getValue("defaultProfileBgRound", self.defaultProfileBgRound)
	self.defaultProfileBgThreePart = profile:getValue("defaultProfileBgThreePart", self.defaultProfileBgThreePart)
	self.autoAddDefaultElements = profile:getBool("autoAddDefaultElements", self.autoAddDefaultElements)
	local v18_ = profile:getValue("texts")
	if v18_ ~= nil then
		local v19_ = v18_:split("|")
		for _, v21_ in pairs(v19_) do
			if v21_:sub(1, 6) == "$l10n_" then
				local v21_ = g_i18n:getText(v21_:sub(7))
			end
			local v22_ = self.texts
			table.insert(v22_, v21_)
		end
	end
end

-- Local values: ret
function MultiTextOptionElement:clone(parent, includeId, suppressOnCreate, blockFocusHandlingReload)
	local v28_ = MultiTextOptionElement:superClass().clone(self, parent, includeId, suppressOnCreate, blockFocusHandlingReload)
	v28_:addDefaultElements()
	v28_:setElementsByName()
	return v28_
end

-- Local values: _, text
function MultiTextOptionElement:copyAttributes(src)
	MultiTextOptionElement:superClass().copyAttributes(self, src)
	self.isChecked = src.isChecked
	self.buttonLRChange = src.buttonLRChange
	self.state = src.state
	self.wrap = src.wrap
	self.hideLeftRightButtons = src.hideLeftRightButtons
	self.hideButtonOnLimitReached = src.hideButtonOnLimitReached
	self.disableButtonsOnSingleText = src.disableButtonsOnSingleText
	self.baseScrollDelayDuration = src.baseScrollDelayDuration
	self.continuousInputStep = src.continuousInputStep
	self.useDynamicInputSteps = src.useDynamicInputSteps
	self.registerContinuousInput = src.registerContinuousInput
	self.canChangeState = src.canChangeState
	self.defaultProfileButtonLeft = src.defaultProfileButtonLeft
	self.defaultProfileButtonRight = src.defaultProfileButtonRight
	self.defaultProfileText = src.defaultProfileText
	self.defaultProfileBg = src.defaultProfileBg
	self.defaultProfileBgRound = src.defaultProfileBgRound
	self.defaultProfileBgThreePart = src.defaultProfileBgThreePart
	self.autoAddDefaultElements = src.autoAddDefaultElements
	self.onClickCallback = src.onClickCallback
	self.onLeaveCallback = src.onLeaveCallback
	self.onFocusCallback = src.onFocusCallback
	for _, v31_ in pairs(src.texts) do
		self:addText(v31_)
	end
	GuiMixin.cloneMixin(IndexChangeSubjectMixin, src, self)
	GuiMixin.cloneMixin(PlaySampleMixin, src, self)
end

function MultiTextOptionElement:onGuiSetupFinished()
	self:addDefaultElements()
	self:setElementsByName()
	self:updateAbsolutePosition()
	if self.leftButtonElement ~= nil then
		self.leftButtonElement.soundDisabled = true
	end
	if self.rightButtonElement ~= nil then
		self.rightButtonElement.soundDisabled = true
	end
end

-- Local values: _, element
function MultiTextOptionElement:setElementsByName()
	for _, v34_ in pairs(self.elements) do
		if v34_.name == nil then
			Logging.warning("MultiTextOptionElement: Could not find a name for element with profile name \'%s\', using default element", v34_.profile)
			return
		end
		if v34_.name == "left" then
			if self.leftButtonElement ~= nil and self.leftButtonElement ~= v34_ then
				self.leftButtonElement:delete()
			end
			self.leftButtonElement = v34_
			v34_.target = self
			v34_:setHandleFocus(false)
			v34_:setCallback("onClickCallback", "onLeftButtonClicked")
			v34_:setDisabled(self.disabled)
			v34_:setVisible(not self.hideLeftRightButtons)
		elseif v34_.name == "right" then
			if self.rightButtonElement ~= nil and self.rightButtonElement ~= v34_ then
				self.rightButtonElement:delete()
			end
			self.rightButtonElement = v34_
			v34_.target = self
			v34_:setHandleFocus(false)
			v34_:setCallback("onClickCallback", "onRightButtonClicked")
			v34_:setDisabled(self.disabled)
			v34_:setVisible(not self.hideLeftRightButtons)
		elseif v34_.name == "label" then
			self.labelElement = v34_
		elseif v34_.name == "text" then
			if v34_:isa(TextElement) then
				if self.textElement ~= nil and self.textElement ~= v34_ then
					self.textElement:delete()
				end
				self.textElement = v34_
				self:updateContentElement()
			end
		elseif v34_.name == "icon" then
			self.iconElement = v34_
			self:updateContentElement()
		elseif v34_.name == "gradient" then
			if v34_:isa(BitmapElement) then
				local v35_ = self.gradientElements
				table.insert(v35_, v34_)
			end
		elseif v34_.name == "background" then
			if self.bgElement ~= nil and self.bgElement ~= v34_ then
				self.bgElement:delete()
			end
			self.bgElement = v34_
			v34_:setSize(self.size[1])
		end
	end
end

-- Local values: baseElement, baseElement, baseElement, baseElement, baseElement, baseElement
function MultiTextOptionElement:addDefaultElements()
	if self.autoAddDefaultElements then
		if self:getDescendantByName("background") == nil then
			if self.defaultProfileBgRound == nil or self.defaultProfileBgRound == "" then
				if self.defaultProfileBgThreePart == nil or self.defaultProfileBgThreePart == "" then
					if self.defaultProfileBg ~= nil then
						local v37_ = BitmapElement.new(self)
						v37_.name = "background"
						self:addElement(v37_)
						v37_:applyProfile(self.defaultProfileBg)
					end
				else
					local v38_ = ThreePartBitmapElement.new(self)
					v38_.name = "background"
					self:addElement(v38_)
					v38_:applyProfile(self.defaultProfileBgThreePart)
				end
			else
				local v39_ = RoundCornerElement.new(self)
				v39_.name = "background"
				self:addElement(v39_)
				v39_:applyProfile(self.defaultProfileBgRound)
			end
		end
		if self:getDescendantByName("left") == nil then
			local v40_ = ButtonElement.new(self)
			v40_.name = "left"
			self:addElement(v40_)
			v40_:applyProfile(self.defaultProfileButtonLeft)
		end
		if self:getDescendantByName("right") == nil then
			local v41_ = ButtonElement.new(self)
			v41_.name = "right"
			self:addElement(v41_)
			v41_:applyProfile(self.defaultProfileButtonRight)
		end
		if self:getDescendantByName("text") == nil then
			local v42_ = TextElement.new(self)
			v42_.name = "text"
			self:addElement(v42_)
			v42_:applyProfile(self.defaultProfileText)
		end
	end
end

-- Local values: numTexts
function MultiTextOptionElement:setState(state, forceEvent)
	local v46_ = #self.texts
	local v47_ = math.min(state, v46_)
	self.state = math.max(v47_, 1)
	self:updateContentElement()
	if forceEvent then
		self:raiseClickCallback(true)
	end
	self:notifyIndexChange(self.state, v46_)
end

function MultiTextOptionElement:getState()
	return self.state
end

function MultiTextOptionElement:disableButtonSounds()
	if self.leftButtonElement ~= nil then
		self.leftButtonElement:disablePlaySample()
	end
	if self.rightButtonElement ~= nil then
		self.rightButtonElement:disablePlaySample()
	end
end

function MultiTextOptionElement:addText(text, i)
	if i == nil then
		local v53_ = self.texts
		table.insert(v53_, text)
	else
		local v54_ = self.texts
		table.insert(v54_, i, text)
	end
	self:updateContentElement()
	if self.useDynamicInputSteps ~= false then
		local v55_ = #self.texts / 5
		local v56_ = math.floor(v55_)
		self.dynamicInputStep = math.min(v56_, 10)
	end
	self:notifyIndexChange(self.state, #self.texts)
end

function MultiTextOptionElement:setTexts(texts)
	if texts == nil then
		self.texts = {}
	else
		self.texts = texts
	end
	self.isImageMode = nil
	local v59_ = self.state
	local v60_ = #self.texts
	self.state = math.min(v59_, v60_)
	self:updateContentElement()
	if self.useDynamicInputSteps ~= false then
		local v61_ = #self.texts / 5
		local v62_ = math.floor(v61_)
		self.dynamicInputStep = math.min(v62_, 10)
	end
	self:notifyIndexChange(self.state, #self.texts)
end

function MultiTextOptionElement:setIcons(icons)
	if icons == nil then
		self.texts = {}
	else
		self.texts = icons
	end
	self.isImageMode = true
	local v65_ = self.state
	local v66_ = #self.texts
	self.state = math.min(v65_, v66_)
	self:updateContentElement()
	self:notifyIndexChange(self.state, #self.texts)
end

function MultiTextOptionElement:setLabel(labelString)
	if self.labelElement ~= nil then
		self.labelElement:setText(labelString)
	end
end

-- Local values: isInElement, leftButton, rightButton
function MultiTextOptionElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	if self:getIsActive() then
		eventUsed = (MultiTextOptionElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed or self.wasContinuousTrigger and isUp) or self.wasContinuousTrigger and isUp) and true or eventUsed
		local v76_ = GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2], nil)
		if v76_ and isDown then
			local v77_ = self.leftButtonElement
			local v78_ = not self.hideLeftRightButtons
			if v78_ then
				v78_ = GuiUtils.checkOverlayOverlap(posX, posY, v77_.absPosition[1], v77_.absPosition[2], v77_.size[1], v77_.size[2], v77_.hotspot)
			end
			self.isLeftButtonPressed = v78_
			local v79_ = self.rightButtonElement
			local v80_ = not self.hideLeftRightButtons
			if v80_ then
				v80_ = GuiUtils.checkOverlayOverlap(posX, posY, v79_.absPosition[1], v79_.absPosition[2], v79_.size[1], v79_.size[2], v79_.hotspot)
			end
			self.isRightButtonPressed = v80_
			self.delayTime = g_time
		elseif (self.leftButtonElement == nil or not self.leftButtonElement:getIsPressed()) and (self.rightButtonElement == nil or not self.rightButtonElement:getIsPressed()) then
			self.delayTime = math.huge
			self.isLeftButtonPressed = false
			self.isRightButtonPressed = false
			self:releaseInput()
		end
		if eventUsed or not v76_ then
			if self.inputEntered and not self:getIsFocused() then
				FocusManager:unsetHighlight(self)
				self.inputEntered = false
			end
		elseif not (self.inputEntered or self:getIsFocused()) then
			FocusManager:setHighlight(self)
			self.inputEntered = true
			return eventUsed
		end
	end
	return eventUsed
end

-- Local values: isInElement, leftButton, rightButton
function MultiTextOptionElement:touchEvent(posX, posY, isDown, isUp, touchId, eventUsed)
	if self:getIsActive() then
		eventUsed = (MultiTextOptionElement:superClass().touchEvent(self, posX, posY, isDown, isUp, touchId, eventUsed or self.wasContinuousTrigger and isUp) or self.wasContinuousTrigger and isUp) and true or eventUsed
		local v88_ = GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2], self.hotspot)
		if v88_ and isDown then
			local v89_ = self.leftButtonElement
			local v90_ = not self.hideLeftRightButtons
			if v90_ then
				v90_ = GuiUtils.checkOverlayOverlap(posX, posY, v89_.absPosition[1], v89_.absPosition[2], v89_.size[1], v89_.size[2], v89_.hotspot)
			end
			self.isLeftButtonPressed = v90_
			local v91_ = self.rightButtonElement
			local v92_ = not self.hideLeftRightButtons
			if v92_ then
				v92_ = GuiUtils.checkOverlayOverlap(posX, posY, v91_.absPosition[1], v91_.absPosition[2], v91_.size[1], v91_.size[2], v91_.hotspot)
			end
			self.isRightButtonPressed = v92_
			self.delayTime = g_time
		elseif (self.leftButtonElement == nil or not self.leftButtonElement:getIsPressed()) and (self.rightButtonElement == nil or not self.rightButtonElement:getIsPressed()) then
			self.delayTime = math.huge
			self.isLeftButtonPressed = false
			self.isRightButtonPressed = false
			self:releaseInput()
		end
		if eventUsed or not v88_ then
			if self.inputEntered and not self:getIsFocused() then
				FocusManager:unsetHighlight(self)
				self.inputEntered = false
			end
		elseif not (self.inputEntered or self:getIsFocused()) then
			FocusManager:setHighlight(self)
			self.inputEntered = true
			return eventUsed
		end
	end
	return eventUsed
end

function MultiTextOptionElement:inputEvent(action, value, eventUsed)
	local v97_ = MultiTextOptionElement:superClass().inputEvent(self, action, value, eventUsed)
	if not v97_ then
		self.registeredInputEventThisFrame = true
		if action == InputAction.MENU_AXIS_LEFT_RIGHT then
			if value < -g_analogStickHTolerance then
				self:inputLeft(false)
				self.leftButtonElement:setPressed(true)
				return true
			end
			if g_analogStickHTolerance < value then
				self:inputRight(false)
				self.rightButtonElement:setPressed(true)
				return true
			end
		else
			if action == InputAction.MENU_PAGE_PREV then
				self:inputLeft(true)
				self.leftButtonElement:setPressed(true)
				return true
			end
			if action == InputAction.MENU_PAGE_NEXT then
				self:inputRight(true)
				self.rightButtonElement:setPressed(true)
				v97_ = true
			end
		end
	end
	return v97_
end

function MultiTextOptionElement:update(dt)
	MultiTextOptionElement:superClass().update(self, dt)
	if self.registerContinuousInput and (self.isLeftButtonPressed or self.isRightButtonPressed) and self.delayTime <= g_time then
		if self.isLeftButtonPressed then
			self:inputLeft(false)
			self.leftButtonElement:setPressed(true)
		else
			self.leftButtonElement:setPressed(false)
		end
		if self.isRightButtonPressed then
			self:inputRight(false)
			self.rightButtonElement:setPressed(true)
		else
			self.rightButtonElement:setPressed(false)
		end
		self.wasContinuousTrigger = true
		self.delayTime = g_time + self.scrollDelayDuration
	end
	if self.registerContinuousInput and self.wasContinuousTrigger then
		self.continuousTriggerTime = self.continuousTriggerTime + dt
	end
	if self.registeredInputEventThisFrame then
		self.registeredInputEventLastFrame = true
		self.registeredInputEventThisFrame = false
	elseif self.registeredInputEventLastFrame then
		self.registeredInputEventLastFrame = false
		self.leftButtonElement:setPressed(false)
		self.rightButtonElement:setPressed(false)
		self:releaseInput()
	end
end

function MultiTextOptionElement:releaseInput(action)
	self.leftDelayTime = 0
	self.rightDelayTime = 0
	self.hasWrapped = false
	self.wasContinuousTrigger = false
	self.continuousTriggerTime = 0
	self.scrollDelayDuration = MultiTextOptionElement.FIRST_INPUT_DELAY
end

-- Local values: isReadyForInput, canContinue, usedShoulderButton, isFocusedWithoutButtons, isLeftButtonFocusedOrPressed
function MultiTextOptionElement:inputLeft(isShoulderButton, forceEvent, blockContinuousInput)
	local v105_ = self.leftDelayTime <= g_time
	local v106_ = not self.hasWrapped
	local v107_ = isShoulderButton and self:getIsVisible()
	if v107_ then
		v107_ = self.buttonLRChange
	end
	local v108_ = self.hideLeftRightButtons
	if v108_ then
		v108_ = self:getIsFocused()
	end
	local v109_
	if self.leftButtonElement == nil then
		v109_ = false
	else
		v109_ = self.leftButtonElement:getIsFocused() or self.leftButtonElement:getIsPressed()
	end
	if not (v105_ and (v106_ and (forceEvent or (v107_ or (v108_ or v109_))))) then
		return false
	end
	if self.leftDelayTime > 0 and not blockContinuousInput then
		self.wasContinuousTrigger = true
	end
	self:onLeftButtonClicked()
	self.leftDelayTime = g_time + self.scrollDelayDuration
	self.scrollDelayDuration = self.baseScrollDelayDuration
	self.rightDelayTime = 0
	return true
end

-- Local values: isReadyForInput, canContinue, usedShoulderButton, isFocusedWithoutButtons, isRightButtonFocusedOrPressed
function MultiTextOptionElement:inputRight(isShoulderButton, forceEvent, blockContinuousInput)
	local v114_ = self.rightDelayTime <= g_time
	local v115_ = not self.hasWrapped
	local v116_ = isShoulderButton and self:getIsVisible()
	if v116_ then
		v116_ = self.buttonLRChange
	end
	local v117_ = self.hideLeftRightButtons
	if v117_ then
		v117_ = self:getIsFocused()
	end
	local v118_
	if self.rightButtonElement == nil then
		v118_ = false
	else
		v118_ = self.rightButtonElement:getIsFocused() or self.rightButtonElement:getIsPressed()
	end
	if not (v114_ and (v115_ and (forceEvent or (v116_ or (v117_ or v118_))))) then
		return false
	end
	if self.rightDelayTime > 0 and not blockContinuousInput then
		self.wasContinuousTrigger = true
	end
	self:onRightButtonClicked()
	self.rightDelayTime = g_time + self.scrollDelayDuration
	self.scrollDelayDuration = self.baseScrollDelayDuration
	self.leftDelayTime = 0
	return true
end

function MultiTextOptionElement:raiseClickCallback(isLeftButtonEvent)
	self:raiseCallback("onClickCallback", self.state, self, isLeftButtonEvent)
end

-- Local values: defaultSteps, oldState, _
function MultiTextOptionElement:onRightButtonClicked(steps, noFocus)
	if self:getCanChangeState() then
		local v124_ = 1
		if self.continuousTriggerTime >= MultiTextOptionElement.FAST_SCROLL_DELAY then
			v124_ = self.continuousInputStep or (self.dynamicInputStep or v124_)
		end
		local v125_ = steps or v124_
		local v126_ = v125_ ~= nil and type(v125_) ~= "number" and 1 or v125_
		local v127_ = self.state
		for _ = 1, v126_ do
			if self.wrap then
				self.state = self.state + 1
				if self.state > #self.texts then
					if self.wasContinuousTrigger then
						self.hasWrapped = true
						self.state = self.state - 1
					else
						self.state = 1
					end
				end
			else
				local v128_ = self.state + 1
				local v129_ = #self.texts
				self.state = math.min(v128_, v129_)
			end
		end
		if not self.hasWrapped and self.state ~= v127_ then
			self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
		end
		if noFocus == nil or not noFocus then
			self:setSoundSuppressed(true)
			FocusManager:setFocus(self)
			self:setSoundSuppressed(false)
			if self.leftButtonElement ~= nil then
				self.leftButtonElement:onFocusEnter()
			end
			if self.rightButtonElement ~= nil then
				self.rightButtonElement:onFocusEnter()
			end
		end
		self:updateContentElement()
		self:raiseClickCallback(false)
		self:notifyIndexChange(self.state, #self.texts)
	end
end

-- Local values: defaultSteps, oldState, _
function MultiTextOptionElement:onLeftButtonClicked(steps, noFocus)
	if self:getCanChangeState() then
		local v133_ = 1
		if self.continuousTriggerTime >= MultiTextOptionElement.FAST_SCROLL_DELAY then
			v133_ = self.continuousInputStep or (self.dynamicInputStep or v133_)
		end
		local v134_ = steps or v133_
		local v135_ = v134_ ~= nil and type(v134_) ~= "number" and 1 or v134_
		local v136_ = self.state
		for _ = 1, v135_ do
			if self.wrap then
				self.state = self.state - 1
				if self.state < 1 then
					if self.wasContinuousTrigger then
						self.hasWrapped = true
						self.state = self.state + 1
					else
						self.state = #self.texts
					end
				end
			else
				local v137_ = self.state - 1
				self.state = math.max(v137_, 1)
			end
		end
		if not self.hasWrapped and self.state ~= v136_ then
			self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
		end
		if noFocus == nil or not noFocus then
			self:setSoundSuppressed(true)
			FocusManager:setFocus(self)
			self:setSoundSuppressed(false)
			if self.leftButtonElement ~= nil then
				self.leftButtonElement:onFocusEnter()
			end
			if self.rightButtonElement ~= nil then
				self.rightButtonElement:onFocusEnter()
			end
		end
		self:updateContentElement()
		self:raiseClickCallback(true)
		self:notifyIndexChange(self.state, #self.texts)
	end
end

function MultiTextOptionElement:getCanChangeState()
	return self.canChangeState
end

function MultiTextOptionElement:setCanChangeState(canChangeState)
	self.canChangeState = canChangeState
end

function MultiTextOptionElement:canReceiveFocus(element, direction)
	local v142_ = not self.disabled and self:getIsVisible()
	if v142_ then
		v142_ = not (self.handleFocus and self.disableButtonsOnSingleText) or #self.texts > 1
	end
	return v142_
end

function MultiTextOptionElement:onFocusLeave()
	MultiTextOptionElement:superClass().onFocusLeave(self)
	self:raiseCallback("onLeaveCallback", self)
end

function MultiTextOptionElement:onFocusEnter()
	MultiTextOptionElement:superClass().onFocusEnter(self)
	self:raiseCallback("onFocusCallback", self)
end

-- Local values: value, isFilename, useIcon, i, i
function MultiTextOptionElement:updateContentElement()
	local v146_ = self.texts[self.state]
	local v147_
	if self.isImageMode and (v146_ ~= nil and string.find(v146_, ".", nil, true) ~= nil) then
		v147_ = textureFileExists(v146_)
	else
		v147_ = false
	end
	local v148_ = false
	if self.iconElement ~= nil then
		if v146_ ~= nil and v147_ then
			self.iconElement:setImageFilename(v146_)
			self.iconElement:setVisible(true)
			for v149_ = 1, #self.gradientElements do
				self.gradientElements[v149_]:setVisible(false)
			end
			v148_ = true
		end
		if not v148_ then
			self.iconElement:setVisible(false)
			for v150_ = 1, #self.gradientElements do
				self.gradientElements[v150_]:setVisible(true)
			end
		end
	end
	if self.textElement ~= nil then
		if v148_ or (v146_ == nil or v147_) then
			self.textElement:setText("")
		else
			self.textElement:setText(v146_)
		end
	end
	if self.disableButtonsOnSingleText then
		self:setDisabled(#self.texts <= 1)
	end
	if self.hideButtonOnLimitReached and not self.wrap then
		if self.leftButtonElement ~= nil then
			self.leftButtonElement:setVisible(self.state ~= 1)
		end
		if self.rightButtonElement ~= nil then
			self.rightButtonElement:setVisible(self.state ~= #self.texts)
		end
	end
end
