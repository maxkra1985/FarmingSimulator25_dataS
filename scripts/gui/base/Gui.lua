-- Local values: Gui_mt
Gui = {}
local Gui_mt = Class(Gui)
Gui.CONFIGURATION_CLASS_MAPPING = {}
Gui.ELEMENT_PROCESSING_FUNCTIONS = {}
Gui.NAV_AXES = {
	InputAction.MENU_AXIS_LEFT_RIGHT,
	InputAction.MENU_AXIS_UP_DOWN,
	InputAction.MENU_LIST_PAGE_START_GAMEPAD,
	InputAction.MENU_LIST_PAGE_END_GAMEPAD
}
Gui.NAV_ACTIONS = {
	InputAction.MENU_ACCEPT,
	InputAction.MENU_ACTIVATE,
	InputAction.MENU_CANCEL,
	InputAction.MENU_BACK,
	InputAction.MENU,
	InputAction.TOGGLE_STORE,
	InputAction.TOGGLE_MAP,
	InputAction.MENU_PAGE_PREV,
	InputAction.MENU_PAGE_NEXT,
	InputAction.MENU_EXTRA_1,
	InputAction.MENU_EXTRA_2,
	InputAction.MENU_LIST_PAGE_START,
	InputAction.MENU_LIST_PAGE_END,
	InputAction.MENU_LIST_PAGE_PREV,
	InputAction.MENU_LIST_PAGE_NEXT
}
Gui.GUI_PROFILE_BASE = "baseReference"
Gui.GUI_PROFILE_TYPE_NAME = string.upper("GUIProfiles")
Gui.INPUT_CONTEXT_MENU = "MENU"
Gui.INPUT_CONTEXT_DIALOG = "DIALOG"
function Gui.new()
	-- upvalues: (copy) Gui_mt
	local v2_ = Gui_mt
	local v3_ = setmetatable({}, v2_)
	v3_.guiSoundPlayer = GuiSoundPlayer.new(g_soundManager)
	FocusManager:setSoundPlayer(v3_.guiSoundPlayer)
	v3_.screens = {}
	v3_.screenControllers = {}
	v3_.dialogs = {}
	v3_.profiles = {}
	v3_.traits = {}
	v3_.presets = {}
	v3_.focusElements = {}
	v3_.guis = {}
	v3_.nameScreenTypes = {}
	v3_.currentGuiName = ""
	v3_.currentlyReloading = false
	v3_.frames = {}
	v3_.isInputListening = false
	v3_.actionEventIds = {}
	v3_.frameInputTarget = nil
	v3_.frameInputHandled = false
	v3_.changeScreenClosure = v3_:makeChangeScreenClosure()
	v3_.toggleCustomInputContextClosure = v3_:makeToggleCustomInputContextClosure()
	v3_.playSampleClosure = v3_:makePlaySampleClosure()
	g_adsSystem:clearGroupRegion(AdsSystem.OCCLUSION_GROUP.UI)
	g_adsSystem:addGroupRegion(AdsSystem.OCCLUSION_GROUP.UI, 0, 0, 1, 1)
	g_adsSystem:setGroupActive(AdsSystem.OCCLUSION_GROUP.UI, false)
	return v3_
end

-- Local values: name, gui, name, frame
function Gui:delete()
	self.guiSoundPlayer:delete()
	for _, v5_ in pairs(self.guis) do
		v5_:delete()
		v5_.target:delete()
	end
	for _, v6_ in pairs(self.frames) do
		v6_.target:delete()
		v6_:delete()
	end
	self.currentGui = nil
end

-- Local values: presets, i, key, name, value, preset
function Gui:loadPresets(xmlFile, rootKey)
	local v10_ = 0
	local v11_ = {}
	while true do
		local v12_ = string.format("%s.Preset(%d)", rootKey, v10_)
		if not hasXMLProperty(xmlFile, v12_) then
			break
		end
		local v13_ = getXMLString(xmlFile, v12_ .. "#name")
		local v14_ = getXMLString(xmlFile, v12_ .. "#value")
		if v13_ ~= nil and v14_ ~= nil then
			if v14_:startsWith("$preset_") then
				local v15_ = string.gsub(v14_, "$preset_", "")
				if v11_[v15_] == nil then
					Logging.devWarning("Preset \'%s\' is not defined in Preset!", v15_)
				else
					v14_ = v11_[v15_]
				end
			end
			if self.presets[v13_] == nil or self.currentlyReloading then
				v11_[v13_] = v14_
				self.presets[v13_] = v14_
			else
				Logging.xmlDevError(xmlFile, "GUI-Preset name \'%s\' already defined!", v13_)
			end
		end
		v10_ = v10_ + 1
	end
	return v11_
end

-- Local values: i, trait, key
function Gui:loadTraits(xmlFile, rootKey, presets)
	local v20_ = 0
	while true do
		local v21_ = GuiProfile.new(self.profiles, self.traits)
		local v22_ = rootKey .. ".Trait(" .. v20_ .. ")"
		if not hasXMLProperty(xmlFile, v22_) then
			break
		end
		v21_:loadFromXML(xmlFile, v22_, presets, true)
		if self.traits[v21_.name] == nil or self.currentlyReloading then
			self.traits[v21_.name] = v21_
		else
			Logging.xmlDevError(xmlFile, "GUI-Trait name \'%s\' already defined!", v21_.name)
		end
		v20_ = v20_ + 1
	end
end

-- Local values: i, profile, key, j, k, variantName, variantProfile
function Gui:loadProfileSet(xmlFile, rootKey, presets, categoryName)
	local v28_ = 0
	while true do
		local v29_ = GuiProfile.new(self.profiles, self.traits)
		local v30_ = rootKey .. ".Profile(" .. v28_ .. ")"
		if not hasXMLProperty(xmlFile, v30_) then
			return
		end
		v29_:loadFromXML(xmlFile, v30_, presets, false)
		if self.profiles[v29_.name] == nil or self.currentlyReloading then
			v29_.category = categoryName
			self.profiles[v29_.name] = v29_
			local v31_ = 0
			while true do
				local v32_ = rootKey .. ".Profile(" .. v28_ .. ").Variant(" .. v31_ .. ")"
				if not hasXMLProperty(xmlFile, v32_) then
					break
				end
				local v33_ = getXMLString(xmlFile, v32_ .. "#name")
				if v33_ ~= nil then
					local v34_ = GuiProfile.new(self.profiles, self.traits)
					if not hasXMLProperty(xmlFile, v32_) then
						break
					end
					v34_:loadFromXML(xmlFile, v32_, presets, false, true)
					if v34_.parent == nil then
						v34_.parent = v29_.name
					end
					v34_.category = categoryName
					v34_.name = v33_ .. "_" .. v29_.name
					if self.profiles[v34_.name] == nil or self.currentlyReloading then
						self.profiles[v34_.name] = v34_
					else
						Logging.xmlDevError(xmlFile, "GUI-Profile name \'%s\' already defined!", v34_.name)
					end
				end
				v31_ = v31_ + 1
			end
		else
			Logging.xmlDevError(xmlFile, "GUI-Profile name \'%s\' already defined!", v29_.name)
		end
		v28_ = v28_ + 1
	end
end

-- Local values: xmlFile, i, key, categoryName
function Gui:loadProfiles(xmlFilename)
	local v37_ = loadXMLFile("Temp", xmlFilename)
	if v37_ == nil or v37_ == 0 then
		Logging.error("Could not open guiProfile-config \'%s\'!", xmlFilename)
		return false
	end
	self:loadPresets(v37_, "GuiProfiles.Presets")
	self:loadTraits(v37_, "GuiProfiles.Traits", self.presets)
	self:loadProfileSet(v37_, "GuiProfiles", self.presets)
	local v38_ = 0
	while true do
		local v39_ = string.format("GuiProfiles.Category(%d)", v38_)
		if not hasXMLProperty(v37_, v39_) then
			break
		end
		local v40_ = getXMLString(v37_, v39_ .. "#name")
		self:loadProfileSet(v37_, v39_, self.presets, v40_)
		v38_ = v38_ + 1
	end
	delete(v37_)
	return true
end

-- Local values: xmlFile, gui
function Gui:loadGui(xmlFilename, name, controller, isFrame)
	local v46_ = loadXMLFile("Temp", xmlFilename)
	local v47_ = nil
	if (v46_ == nil or v46_ == 0) and not self.currentlyReloading then
		Logging.error("Could not open gui-config \'%s\'!", xmlFilename)
		controller:delete()
		return v47_
	end
	self:loadProfileSet(v46_, "GUI.GuiProfiles", self.presets)
	FocusManager:setGui(name)
	local v48_ = GuiElement.new(controller)
	v48_.name = name
	v48_.xmlFilename = xmlFilename
	controller.name = name
	controller.xmlFilename = xmlFilename
	v48_:loadFromXML(v46_, "GUI")
	if g_screenWidth ~= g_unsafeScreenWidth or g_screenHeight ~= g_unsafeScreenHeight then
		v48_:setPosition(g_safeFrameScreenOffsetX * g_pixelSizeX, g_safeFrameScreenOffsetY * g_pixelSizeY)
		v48_:setSize(g_screenWidth / g_unsafeScreenWidth, g_screenHeight / g_unsafeScreenHeight, true)
	end
	if isFrame then
		controller.name = v48_.name
		v48_.isFrame = true
	end
	self:loadGuiRec(v46_, "GUI", v48_, controller)
	controller:addElement(v48_)
	if not isFrame then
		controller:updateAbsolutePosition()
	end
	controller:exposeControlsAsFields(name)
	controller:onGuiSetupFinished()
	v48_:raiseCallback("onCreateCallback", v48_, v48_.onCreateArgs)
	if isFrame then
		self:addFrame(controller, v48_)
	else
		self.guis[name] = v48_
		self.nameScreenTypes[name] = controller:class()
		self:addScreen(controller:class(), controller, v48_)
	end
	delete(v46_)
	return v48_
end

-- Local values: numElements, index, typeName, currentXmlPath, upperCaseTypeName, newGuiElement, elementClass, processingFunction
function Gui:loadGuiRec(xmlFile, xmlNodePath, parentGuiElement, target)
	for v54_ = 0, getXMLNumOfChildren(xmlFile, xmlNodePath) - 1 do
		local v55_ = getXMLElementName(xmlFile, string.format("%s.*(%i)", xmlNodePath, v54_))
		local v56_ = string.format("%s.*(%i)", xmlNodePath, v54_)
		local v57_ = string.upper(v55_)
		if v57_ ~= Gui.GUI_PROFILE_TYPE_NAME then
			local v58_ = Gui.CONFIGURATION_CLASS_MAPPING[v57_]
			if v58_ then
				local v59_ = v58_.new(target)
				v59_.typeName = v55_
				parentGuiElement:addElement(v59_)
				v59_:loadFromXML(xmlFile, v56_)
				local v60_ = Gui.ELEMENT_PROCESSING_FUNCTIONS[v57_]
				if v60_ then
					v59_ = v60_(self, v59_)
				end
				self:loadGuiRec(xmlFile, v56_, v59_, target)
				v59_:raiseCallback("onCreateCallback", v59_, v59_.onCreateArgs)
			else
				Logging.xmlWarning(xmlFile, string.format("Could not find type name %s in registered GUI element classes", v55_))
			end
		end
	end
end

-- Local values: refName, frame, frameName, frameController, frameParent, controllerClone, cloneRoot, frameId
function Gui:resolveFrameReference(frameRefElement)
	local v63_ = frameRefElement.referencedFrameName or ""
	local v64_ = self.frames[v63_]
	if v64_ == nil then
		return frameRefElement
	end
	local v65_ = frameRefElement.name or v63_
	local v66_ = v64_.parent
	local v67_ = frameRefElement.parent
	local v68_ = v66_:clone(v67_, true, true, true)
	v68_.name = v65_
	FocusManager:setGui(v65_)
	v68_.positionOrigin = v67_.positionOrigin
	v68_.screenAlign = v67_.screenAlign
	local v69_ = v67_.size
	v68_:setSize(unpack(v69_))
	local v70_ = v68_:getRootElement()
	v70_.positionOrigin = v67_.positionOrigin
	v70_.screenAlign = v67_.screenAlign
	local v71_ = v67_.size
	v70_:setSize(unpack(v71_))
	v68_:setTarget(v68_, v66_, true)
	local v72_ = frameRefElement.id
	v68_.id = v72_
	if frameRefElement.target then
		frameRefElement.target[v72_] = v68_
	end
	FocusManager:loadElementFromCustomValues(v68_, nil, nil, false, false)
	frameRefElement:unlinkElement()
	frameRefElement:delete()
	return v68_
end

-- Local values: specialized, defaultProfileName, _, prefix, customProfileName, consoleProfileName, consoleProfileName
function Gui:getProfile(profileName)
	if profileName ~= nil then
		local v75_ = profileName
		local v76_ = false
		for _, v77_ in ipairs(Platform.guiPrefixes) do
			local v78_ = v77_ .. profileName
			if self.profiles[v78_] ~= nil then
				v75_ = v78_
				v76_ = true
			end
		end
		local v79_
		if v76_ or not Platform.isConsole then
			v79_ = v75_
		else
			v79_ = "console_" .. v75_
			if self.profiles[v79_] == nil then
				v79_ = v75_
			else
				v76_ = true
			end
		end
		if v76_ or not Platform.isMobile then
			profileName = v79_
		else
			profileName = "mobile_" .. v79_
			if self.profiles[profileName] == nil then
				profileName = v79_
			end
		end
	end
	if not (profileName and self.profiles[profileName]) then
		if profileName and profileName ~= "" then
			Logging.warning("Could not retrieve GUI profile \'%s\'. Using base reference profile instead.", (tostring(profileName)))
		end
		profileName = Gui.GUI_PROFILE_BASE
	end
	return self.profiles[profileName]
end

function Gui:getIsGuiVisible()
	return self.currentGui ~= nil and true or self:getIsDialogVisible()
end

function Gui:getIsMenuVisible()
	return self.currentGui ~= nil
end

function Gui:getIsDialogVisible()
	return #self.dialogs > 0
end

function Gui:getIsOverlayGuiVisible()
	return false
end

function Gui:showGui(guiName)
	local v85_ = guiName == nil and "" or guiName
	return self:changeScreen(self.guis[self.currentGui], self.nameScreenTypes[v85_])
end

-- Local values: gui, list, _, v, oldListener, x, y, width, height
function Gui:showDialog(guiName, closeAllOthers)
	local v89_ = self.guis[guiName]
	self.currentDialogName = guiName
	self.currentDialog = guiName
	if v89_ ~= nil then
		if closeAllOthers then
			local v90_ = self.dialogs
			for _, v91_ in ipairs(v90_) do
				if v91_ ~= v89_ then
					self:closeDialog(v91_)
				end
			end
		end
		local v92_ = self.currentListener
		if self.currentListener == v89_ then
			return v89_
		end
		if self.currentListener ~= nil then
			self.focusElements[self.currentListener] = FocusManager:getFocusedElement()
		end
		if v89_.target.needInput == nil or v89_.target.needInput == true then
			if not self:getIsGuiVisible() then
				self:enterMenuContext()
			end
			self:enterMenuContext(Gui.INPUT_CONTEXT_DIALOG .. "_" .. tostring(guiName))
		end
		FocusManager:setGui(guiName)
		local v93_ = self.dialogs
		table.insert(v93_, v89_)
		v89_:onOpen()
		self.currentListener = v89_
		local v94_ = g_messageCenter
		local v95_ = MessageType.GUI_DIALOG_OPENED
		local v96_
		if v92_ == nil then
			v96_ = false
		else
			v96_ = v92_ ~= v89_
		end
		v94_:publish(v95_, guiName, v96_)
		v89_.blurAreaActive = false
		if v89_.target.getBlurArea ~= nil then
			local v97_, v98_, v99_, v100_ = v89_.target:getBlurArea()
			if v97_ ~= nil then
				v89_.blurAreaActive = true
				g_depthOfFieldManager:pushArea(v97_, v98_, v99_, v100_)
			end
		end
	end
	return v89_
end

-- Local values: gui
function Gui:closeDialogByName(guiName)
	local v103_ = self.guis[guiName]
	if v103_ ~= nil then
		self:closeDialog(v103_)
	end
end

-- Local values: k, v
function Gui:closeDialog(gui)
	for v106_, v107_ in ipairs(self.dialogs) do
		if v107_ == gui then
			v107_:onClose()
			table.remove(self.dialogs, v106_)
			if gui.blurAreaActive then
				g_depthOfFieldManager:popArea()
				gui.blurAreaActive = false
			end
			if self.currentListener == gui then
				if #self.dialogs > 0 then
					self.currentListener = self.dialogs[#self.dialogs]
				elseif self.currentGui == gui then
					self.currentListener = nil
					self.currentGui = nil
				else
					self.currentListener = self.currentGui
				end
				if self.currentListener ~= nil then
					FocusManager:setGui(self.currentListener.name)
					if self.focusElements[self.currentListener] ~= nil then
						FocusManager:setFocus(self.focusElements[self.currentListener])
						self.focusElements[self.currentListener] = nil
					end
				end
			end
			if gui.target.needInput == nil or gui.target.needInput == true then
				g_inputBinding:revertContext(false)
			end
			break
		end
	end
	if not self:getIsGuiVisible() then
		self:changeScreen(nil)
	end
end

-- Local values: _, v
function Gui:closeAllDialogs()
	for _, v109_ in ipairs(self.dialogs) do
		self:closeDialog(v109_)
	end
end

-- Local values: _, actionName, _, eventId, _, actionName, _, eventId
function Gui:registerMenuInput()
	self.actionEventIds = {}
	for _, v111_ in ipairs(Gui.NAV_ACTIONS) do
		local _, v112_ = g_inputBinding:registerActionEvent(v111_, self, self.onMenuInput, false, true, false, true)
		g_inputBinding:setActionEventTextVisibility(v112_, false)
		if self.actionEventIds[v111_] == nil then
			self.actionEventIds[v111_] = {}
		end
		table.addElement(self.actionEventIds[v111_], v112_)
		if v111_ == InputAction.MENU_PAGE_PREV or v111_ == InputAction.MENU_PAGE_NEXT then
			local _, v113_ = g_inputBinding:registerActionEvent(v111_, self, self.onReleaseInput, true, false, false, true)
			g_inputBinding:setActionEventTextVisibility(v113_, false)
			table.addElement(self.actionEventIds[v111_], v113_)
		end
	end
	for _, v114_ in pairs(Gui.NAV_AXES) do
		local _, v115_ = g_inputBinding:registerActionEvent(v114_, self, self.onMenuInput, false, true, true, true)
		g_inputBinding:setActionEventTextVisibility(v115_, false)
		if self.actionEventIds[v114_] == nil then
			self.actionEventIds[v114_] = {}
		end
		table.addElement(self.actionEventIds[v114_], v115_)
		local _, v116_ = g_inputBinding:registerActionEvent(v114_, self, self.onReleaseMovement, true, false, false, true)
		g_inputBinding:setActionEventTextVisibility(v116_, false)
		table.addElement(self.actionEventIds[v114_], v116_)
	end
	self.isInputListening = true
end

-- Local values: eventUsed
function Gui:mouseEvent(posX, posY, isDown, isUp, button)
	local v123_
	if self.currentListener == nil then
		v123_ = false
	else
		v123_ = self.currentListener:mouseEvent(posX, posY, isDown, isUp, button)
	end
	if not v123_ and (self.currentListener ~= nil and (self.currentListener.target ~= nil and self.currentListener.target.mouseEvent ~= nil)) then
		self.currentListener.target:mouseEvent(posX, posY, isDown, isUp, button)
	end
end

-- Local values: eventUsed
function Gui:touchEvent(posX, posY, isDown, isUp, touchId)
	local v130_
	if self.currentListener == nil or self.currentListener.touchEvent == nil then
		v130_ = false
	else
		v130_ = self.currentListener:touchEvent(posX, posY, isDown, isUp, touchId)
	end
	if not v130_ and (self.currentListener ~= nil and (self.currentListener.target ~= nil and self.currentListener.target.touchEvent ~= nil)) then
		self.currentListener.target:touchEvent(posX, posY, isDown, isUp, touchId)
	end
end

-- Local values: eventUsed
function Gui:keyEvent(unicode, sym, modifier, isDown)
	local v136_
	if self.currentListener == nil then
		v136_ = false
	else
		v136_ = self.currentListener:keyEvent(unicode, sym, modifier, isDown)
	end
	if self.currentListener ~= nil and (self.currentListener.target ~= nil and (not v136_ and self.currentListener.target.keyEvent ~= nil)) then
		self.currentListener.target:keyEvent(unicode, sym, modifier, isDown, v136_)
	end
end

-- Local values: _, v, currentGui
function Gui:update(dt)
	for _, v139_ in pairs(self.dialogs) do
		if v139_.target ~= nil then
			v139_.target:update(dt)
		end
	end
	local v140_ = self.currentGui
	if v140_ ~= nil then
		if v140_.target ~= nil and v140_.target.preUpdate ~= nil then
			v140_.target:preUpdate(dt)
		end
		if v140_ == self.currentGui and (v140_ == self.currentGui and (v140_.target ~= nil and v140_.target.update ~= nil)) then
			v140_.target:update(dt)
		end
	end
	self.frameInputTarget = nil
	self.frameInputHandled = false
end

-- Local values: _, v, item, getGuiElementName, e, e, _, e, _, e, _, e, _, xPixel, yPixel
function Gui:draw()
	if self.currentGui ~= nil and (self.currentGui.target ~= nil and self.currentGui.target.draw ~= nil) then
		self.currentGui.target:draw()
	end
	for _, v142_ in pairs(self.dialogs) do
		if v142_.target ~= nil then
			v142_.target:draw()
		end
	end
	if g_uiDebugEnabled then
		local v143_ = FocusManager.currentFocusData.focusElement
		setTextAlignment(RenderText.ALIGN_CENTER)
		renderText(0.5, 0.94, 0.02, "Focused element: " .. (v143_ == nil or v143_.id or (v143_.profile or v143_.name)))
		if v143_ ~= nil then
			local v144_ = renderText
			local v145_, _ = FocusManager:getNextFocusElement(v143_, FocusManager.TOP)
			v144_(0.5, 0.92, 0.02, "Top element: " .. (v145_ == nil or v145_.id or (v145_.profile or v145_.name)))
			local v146_ = renderText
			local v147_, _ = FocusManager:getNextFocusElement(v143_, FocusManager.BOTTOM)
			v146_(0.5, 0.9, 0.02, "Bottom element: " .. (v147_ == nil or v147_.id or (v147_.profile or v147_.name)))
			local v148_ = renderText
			local v149_, _ = FocusManager:getNextFocusElement(v143_, FocusManager.LEFT)
			v148_(0.5, 0.88, 0.02, "Left element: " .. (v149_ == nil or v149_.id or (v149_.profile or v149_.name)))
			local v150_ = renderText
			local v151_, _ = FocusManager:getNextFocusElement(v143_, FocusManager.RIGHT)
			v150_(0.5, 0.86, 0.02, "Right element: " .. (v151_ == nil or v151_.id or (v151_.profile or v151_.name)))
			local v152_ = 3 * g_pixelSizeX
			local v153_ = 3 * g_pixelSizeY
			drawFilledRect(v143_.absPosition[1] - v152_, v143_.absPosition[2] - v153_, v143_.absSize[1] + 2 * v152_, v153_, 1, 0.5, 0, 1)
			drawFilledRect(v143_.absPosition[1] - v152_, v143_.absPosition[2] + v143_.absSize[2], v143_.absSize[1] + 2 * v152_, v153_, 1, 0.5, 0, 1)
			drawFilledRect(v143_.absPosition[1] - v152_, v143_.absPosition[2], v152_, v143_.absSize[2], 1, 0.5, 0, 1)
			drawFilledRect(v143_.absPosition[1] + v143_.absSize[1], v143_.absPosition[2], v152_, v143_.absSize[2], 1, 0.5, 0, 1)
		end
		setTextAlignment(RenderText.ALIGN_LEFT)
	end
end

-- Local values: eventUsed, locked, focusedElement
function Gui:notifyControls(action, value)
	local v157_ = false
	if self.frameInputTarget == nil then
		self.frameInputTarget = self.currentListener
	end
	if not FocusManager:isFocusInputLocked(action, value) then
		if not v157_ and self.frameInputTarget ~= nil then
			v157_ = self.frameInputTarget:inputEvent(action, value)
		end
		if not v157_ and (self.frameInputTarget ~= nil and self.frameInputTarget.target ~= nil) then
			v157_ = self.frameInputTarget.target:inputEvent(action, value)
		end
		local v158_ = FocusManager:getFocusedElement()
		if not v157_ and (v158_ ~= nil and v158_:getIsActive()) then
			v157_ = v158_:inputEvent(action, value)
		end
		v157_ = v157_ or FocusManager:inputEvent(action, value, v157_)
	end
	self.frameInputHandled = v157_
end

function Gui:onMenuInput(actionName, inputValue)
	if not self.frameInputHandled and self.isInputListening then
		self:notifyControls(actionName, inputValue)
	end
end

function Gui:onReleaseMovement(action)
	self:onReleaseInput(action)
	FocusManager:releaseMovementFocusInput(action)
end

-- Local values: locked, focusedElement
function Gui:onReleaseInput(action)
	if not self.frameInputHandled and (self.isInputListening and not FocusManager:isFocusInputLocked(action)) then
		if self.frameInputTarget ~= nil then
			self.frameInputTarget:inputReleaseEvent(action)
		end
		if self.frameInputTarget ~= nil and self.frameInputTarget.target ~= nil then
			self.frameInputTarget.target:inputReleaseEvent(action)
		end
		local v166_ = FocusManager:getFocusedElement()
		if v166_ ~= nil and v166_:getIsActive() then
			v166_:inputReleaseEvent(action)
		end
	end
end

function Gui:hasElementInputFocus(element)
	local v169_
	if self.currentListener == nil then
		v169_ = false
	else
		v169_ = self.currentListener.target == element
	end
	return v169_
end

function Gui:getScreenInstanceByClass(screenClass)
	return self.screenControllers[screenClass]
end

-- Local values: screenController, isMenuOpening, screenElement, screenName
function Gui:changeScreen(sourceScreen, screenClass, returnScreenClass)
	local v176_ = self.screenControllers[screenClass]
	if screenClass ~= nil and v176_ == nil then
		Logging.devWarning("UI \'%s\' not found", ClassUtil.getClassName(screenClass))
		return nil
	end
	self:closeAllDialogs()
	local v177_ = not self:getIsGuiVisible()
	local v178_ = self.screens[screenClass]
	if sourceScreen == nil then
		if self.currentGui ~= nil then
			self.currentGui:onClose()
		end
	else
		sourceScreen:onClose()
	end
	local v179_ = v178_ and (v178_.name or "") or ""
	self.currentGui = v178_
	self.currentGuiName = v179_
	self.currentListener = v178_
	if v178_ ~= nil and v177_ then
		g_messageCenter:publish(MessageType.GUI_BEFORE_OPEN)
		self:enterMenuContext()
	end
	FocusManager:setGui(v179_)
	if v178_ ~= nil and v176_ ~= nil then
		v176_:setReturnScreenClass(returnScreenClass or v176_.returnScreenClass)
		v178_:onOpen()
		if v177_ then
			g_messageCenter:publish(MessageType.GUI_AFTER_OPEN)
		end
	end
	if not self:getIsGuiVisible() then
		g_messageCenter:publish(MessageType.GUI_BEFORE_CLOSE)
		self:leaveMenuContext()
		g_messageCenter:publish(MessageType.GUI_AFTER_CLOSE)
	end
	g_adsSystem:setGroupActive(AdsSystem.OCCLUSION_GROUP.UI, self.currentGui ~= nil)
	return v178_
end

function Gui:makeChangeScreenClosure()
	return function(p181_, p182_, p183_)
		-- upvalues: (copy) self
		self:changeScreen(p181_, p182_, p183_)
	end
end

function Gui:toggleCustomInputContext(isActive, contextName)
	if isActive then
		self:enterMenuContext(contextName)
	else
		self:leaveMenuContext()
	end
end

function Gui:makeToggleCustomInputContextClosure()
	return function(p188_, p189_)
		-- upvalues: (copy) self
		self:toggleCustomInputContext(p188_, p189_)
	end
end

function Gui:makePlaySampleClosure()
	return function(p191_)
		-- upvalues: (copy) self
		self.guiSoundPlayer:playSample(p191_)
	end
end

function Gui:assignPlaySampleCallback(guiElement)
	if guiElement:hasIncluded(PlaySampleMixin) then
		guiElement:setPlaySampleCallback(self.playSampleClosure)
	end
	return guiElement
end

function Gui:enterMenuContext(contextName)
	g_inputBinding:setContext(contextName or Gui.INPUT_CONTEXT_MENU, true, false)
	self:registerMenuInput()
	self.isInputListening = true
end

function Gui:leaveMenuContext()
	if self.isInputListening then
		g_inputBinding:revertContext(false)
		self.isInputListening = self:getIsGuiVisible()
	end
end

function Gui:addFrame(frameController, frameRootElement)
	self.frames[frameController.name] = frameRootElement
	frameController:setChangeScreenCallback(self.changeScreenClosure)
	frameController:setInputContextCallback(self.toggleCustomInputContextClosure)
	frameController:setPlaySampleCallback(self.playSampleClosure)
end

function Gui:addScreen(screenClass, screenInstance, screenRootElement)
	self.screens[screenClass] = screenRootElement
	self.screenControllers[screenClass] = screenInstance
	screenInstance:setChangeScreenCallback(self.changeScreenClosure)
	screenInstance:setInputContextCallback(self.toggleCustomInputContextClosure)
	screenInstance:setPlaySampleCallback(self.playSampleClosure)
end

-- Local values: _, controller
function Gui:setCurrentMission(currentMission)
	for _, v206_ in pairs(self.screenControllers) do
		if v206_.setCurrentMission ~= nil then
			v206_:setCurrentMission(currentMission)
		end
	end
end

function Gui:loadMapData(mapXmlFile, missionInfo, baseDirectory)
	if not Platform.isMobile then
		self.screenControllers[ShopConfigScreen]:loadMapData(mapXmlFile, missionInfo, baseDirectory)
		self.screenControllers[LicensePlateDialog]:loadMapData(mapXmlFile, missionInfo, baseDirectory)
		self.screenControllers[ColorPickerDialog]:loadMapData(mapXmlFile, missionInfo, baseDirectory)
	end
	if Platform.hasWardrobe then
		self.screenControllers[WardrobeScreen]:loadMapData(mapXmlFile, missionInfo, baseDirectory)
	end
end

function Gui:unloadMapData()
	self.screenControllers[InGameMenu]:unloadMapData()
	self.screenControllers[ShopConfigScreen]:unloadMapData()
	self.screenControllers[LicensePlateDialog]:unloadMapData()
	self.screenControllers[ColorPickerDialog]:unloadMapData()
	if Platform.hasWardrobe then
		self.screenControllers[WardrobeScreen]:unloadMapData()
	end
end

-- Local values: _, controller
function Gui:setClient(client)
	for _, v214_ in pairs(self.screenControllers) do
		if v214_.setClient ~= nil then
			v214_:setClient(client)
		end
	end
end

-- Local values: _, controller
function Gui:setServer(server)
	for _, v217_ in pairs(self.screenControllers) do
		if v217_.setServer ~= nil then
			v217_:setServer(server)
		end
	end
end

-- Local values: notifyScreenClasses, _, class, controller
function Gui:setIsMultiplayer(isMultiplayer)
	local v220_ = { CareerScreen }
	for _, v221_ in pairs(v220_) do
		local v222_ = self.screenControllers[v221_]
		if v222_ ~= nil then
			v222_:setIsMultiplayer(isMultiplayer)
		end
	end
end

function Gui.initGuiLibrary(baseDir)
	source(baseDir .. "/base/GuiProfile.lua")
	source(baseDir .. "/base/GuiUtils.lua")
	source(baseDir .. "/base/GuiOverlay.lua")
	source(baseDir .. "/base/GuiDataSource.lua")
	source(baseDir .. "/base/GuiMixin.lua")
	source(baseDir .. "/base/IndexChangeSubjectMixin.lua")
	source(baseDir .. "/base/PlaySampleMixin.lua")
	source(baseDir .. "/base/Tween.lua")
	source(baseDir .. "/base/MultiValueTween.lua")
	source(baseDir .. "/base/TweenSequence.lua")
	source(baseDir .. "/elements/GuiElement.lua")
	source(baseDir .. "/elements/FrameElement.lua")
	source(baseDir .. "/elements/ScreenElement.lua")
	source(baseDir .. "/elements/DialogElement.lua")
	source(baseDir .. "/elements/BitmapElement.lua")
	source(baseDir .. "/elements/ClearElement.lua")
	source(baseDir .. "/elements/TextElement.lua")
	source(baseDir .. "/elements/ButtonElement.lua")
	source(baseDir .. "/elements/ToggleButtonElement.lua")
	source(baseDir .. "/elements/ColorPickButtonElement.lua")
	source(baseDir .. "/elements/VideoElement.lua")
	source(baseDir .. "/elements/SliderElement.lua")
	source(baseDir .. "/elements/TextInputElement.lua")
	source(baseDir .. "/elements/MultiTextOptionElement.lua")
	source(baseDir .. "/elements/OptionSliderElement.lua")
	source(baseDir .. "/elements/CheckedOptionElement.lua")
	source(baseDir .. "/elements/BinaryOptionElement.lua")
	source(baseDir .. "/elements/ListItemElement.lua")
	source(baseDir .. "/elements/AnimationElement.lua")
	source(baseDir .. "/elements/TimerElement.lua")
	source(baseDir .. "/elements/BoxLayoutElement.lua")
	source(baseDir .. "/elements/PagingElement.lua")
	source(baseDir .. "/elements/TableHeaderElement.lua")
	source(baseDir .. "/elements/IngameMapElement.lua")
	source(baseDir .. "/elements/IngameMapPreviewElement.lua")
	source(baseDir .. "/elements/IndexStateElement.lua")
	source(baseDir .. "/elements/FrameReferenceElement.lua")
	source(baseDir .. "/elements/RenderElement.lua")
	source(baseDir .. "/elements/BreadcrumbsElement.lua")
	source(baseDir .. "/elements/ThreePartBitmapElement.lua")
	source(baseDir .. "/elements/PictureElement.lua")
	source(baseDir .. "/elements/ScrollingLayoutElement.lua")
	source(baseDir .. "/elements/MultiOptionElement.lua")
	source(baseDir .. "/elements/TextBackdropElement.lua")
	source(baseDir .. "/elements/InputGlyphElementUI.lua")
	source(baseDir .. "/elements/TerrainLayerElement.lua")
	source(baseDir .. "/elements/SmoothListElement.lua")
	source(baseDir .. "/elements/DynamicFadedBitmapElement.lua")
	source(baseDir .. "/elements/PlatformIconElement.lua")
	source(baseDir .. "/elements/OptionToggleElement.lua")
	source(baseDir .. "/elements/RoundCornerElement.lua")
	source(baseDir .. "/elements/SafeFrameElement.lua")
end

function Gui.registerGuiElement(name, class)
	local v226_ = string.upper(name)
	Gui.CONFIGURATION_CLASS_MAPPING[v226_] = class
end

function Gui.registerGuiElementProcFunction(name, procFunction)
	local v229_ = string.upper(name)
	Gui.ELEMENT_PROCESSING_FUNCTIONS[v229_] = procFunction
end
