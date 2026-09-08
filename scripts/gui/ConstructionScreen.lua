-- Local values: ConstructionScreen_mt
ConstructionScreen = {}
ConstructionScreen.CELL_NAME_DETAIL = "detailTemplate"
ConstructionScreen.CELL_NAME_FILL_TYPES = "fillTypesTemplate"
ConstructionScreen.INPUT_CONTEXT = "CONSTRUCTION_MENU"
local ConstructionScreen_mt = Class(ConstructionScreen, ScreenElement)
function ConstructionScreen.register()
	local v2_ = ConstructionScreen.new()
	g_gui:loadGui("dataS/gui/ConstructionScreen.xml", "ConstructionScreen", v2_)
	if g_addCheatCommands then
		addConsoleCommand("gsConstructionScreenUIToggle", "Toggle construction screen UI", "consoleCommandToggleUI", ConstructionScreen)
	end
	return v2_
end

-- Upvalues: ConstructionScreen_mt
-- Local values: self
function ConstructionScreen.new(target, custom_mt)
	-- upvalues: (copy) ConstructionScreen_mt
	local v5_ = ScreenElement.new(target, custom_mt or ConstructionScreen_mt)
	v5_.isMouseMode = true
	v5_.camera = GuiTopDownCamera.new()
	v5_.cursor = GuiTopDownCursor.new()
	v5_.sound = ConstructionSound.new()
	v5_.brush = nil
	v5_.items = {}
	v5_.menuEvents = {}
	v5_.brushEvents = {}
	v5_.configEvents = {}
	v5_.marqueeBoxes = {}
	v5_.clonedElements = {}
	v5_.detailsCache = {}
	v5_.detailsTemplates = {}
	v5_.configItemCache = {}
	v5_.configItemCacheLarge = {}
	return v5_
end

-- Local values: newGui
function ConstructionScreen.createFromExistingGui(gui, guiName)
	local v8_ = ConstructionScreen.new()
	g_gui.guis[guiName]:delete()
	g_gui.guis[guiName].target:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v8_)
	return v8_
end

-- Local values: k, clone, k, clone, k, clone, k, cell, l, clone, _, element, _, element
function ConstructionScreen:delete()
	self.camera:delete()
	self.cursor:delete()
	self.sound:delete()
	if self.selectorBrush ~= nil then
		self.selectorBrush:delete()
	end
	if self.destructBrush ~= nil then
		self.destructBrush:delete()
	end
	for v10_, v11_ in pairs(self.clonedElements) do
		v11_:delete()
		self.clonedElements[v10_] = nil
	end
	for v12_, v13_ in pairs(self.detailsTemplates) do
		v13_:delete()
		self.detailsTemplates[v12_] = nil
	end
	for v14_, v15_ in pairs(self.subCategoryDotBox.elements) do
		v15_:delete()
		self.subCategoryDotBox.elements[v14_] = nil
	end
	for v16_, v17_ in pairs(self.detailsCache) do
		for v18_, v19_ in pairs(v17_) do
			v19_:delete()
			self.detailsCache[v16_][v18_] = nil
		end
		self.detailsCache[v16_] = nil
	end
	for _, v20_ in ipairs(self.configItemCache) do
		v20_:delete()
	end
	self.configItemCache = {}
	for _, v21_ in ipairs(self.configItemCacheLarge) do
		v21_:delete()
	end
	self.configItemCacheLarge = {}
	self.subCategoryDotTemplate:delete()
	self.configurationItemTemplate:delete()
	self.configurationItemTemplateLarge:delete()
	ConstructionScreen:superClass().delete(self)
end

-- Local values: viewPortStartX, class, class
function ConstructionScreen:onOpen()
	ConstructionScreen:superClass().onOpen(self)
	g_currentMission.lastConstructionScreenOpenTime = g_time
	g_inputBinding:setContext(ConstructionScreen.INPUT_CONTEXT)
	local v23_ = self.menuBox.absPosition[1] + self.menuBox.absSize[1]
	self.viewPortStartX = v23_
	self.camera:setTerrainRootNode(g_terrainNode)
	self.camera:setEdgeScrollingOffset(v23_, 0, 1, 1)
	self.camera:activate()
	self.cursor:activate()
	self.originalSafeFrameOffsetX = g_safeFrameOffsetX
	g_safeFrameOffsetX = v23_ + g_safeFrameOffsetX
	if self.selectorBrush == nil then
		self.selectorBrush = g_constructionBrushTypeManager:getClassObjectByTypeName("select").new(nil, self.cursor)
	end
	self:setBrush(self.selectorBrush, true)
	if self.destructBrush == nil then
		self.destructBrush = g_constructionBrushTypeManager:getClassObjectByTypeName("destruct").new(nil, self.cursor)
	end
	self.destructMode = false
	self.isMouseMode = g_inputBinding.lastInputMode == GS_INPUT_HELP_MODE_KEYBOARD
	g_messageCenter:subscribe(MessageType.INPUT_MODE_CHANGED, self.onInputModeChanged, self)
	self:rebuildData()
	if self.currentCategory == nil then
		self:setCurrentCategory(1, 1)
	end
	self:updateMenuState()
	FocusManager:setFocus(self.itemList)
	self.originalInputHelpVisibility = g_currentMission.hud.inputHelp:getVisible()
	g_currentMission.hud:setInputHelpVisible(true, true)
	g_messageCenter:subscribe(MessageType.SLOT_USAGE_CHANGED, self.onSlotUsageChanged, self)
	if g_isDevelopmentVersion then
		g_messageCenter:subscribe(MessageType.APP_WINDOW_FOCUS_CHANGED, self.onAppWindowFocusChanged, self)
	end
	if g_localPlayer ~= nil then
		local v24_
		if g_localPlayer:getCurrentVehicle() == nil then
			v24_ = g_localPlayer.camera.isFirstPerson
		else
			v24_ = false
		end
		self.wasFirstPerson = v24_
		if self.wasFirstPerson then
			g_localPlayer.graphicsComponent:setModelVisibility(true)
		end
	end
end

function ConstructionScreen:onClose(element)
	if g_localPlayer ~= nil and self.wasFirstPerson then
		g_localPlayer.graphicsComponent:setModelVisibility(false)
		self.wasFirstPerson = nil
	end
	g_messageCenter:unsubscribeAll(self)
	g_currentMission.hud:setInputHelpVisible(self.originalInputHelpVisibility)
	g_currentMission.lastConstructionScreenOpenTime = -1
	self:setBrush(nil, false)
	g_safeFrameOffsetX = self.originalSafeFrameOffsetX
	self.camera:setEdgeScrollingOffset(0, 0, 1, 1)
	self.cursor:deactivate()
	self.camera:deactivate()
	self:removeMenuActionEvents()
	g_inputBinding:revertContext()
	ConstructionScreen:superClass().onClose(self)
end

function ConstructionScreen:onGuiSetupFinished()
	ConstructionScreen:superClass().onGuiSetupFinished(self)
	self.subCategoryDotTemplate:unlinkElement()
	FocusManager:removeElement(self.subCategoryDotTemplate)
	self.configurationItemTemplate:unlinkElement()
	FocusManager:removeElement(self.configurationItemTemplate)
	self.configurationItemTemplateLarge:unlinkElement()
	FocusManager:removeElement(self.configurationItemTemplateLarge)
	self:buildCellDatabase()
end

function ConstructionScreen:update(dt)
	ConstructionScreen:superClass().update(self, dt)
	g_currentMission.hud:updateBlinkingWarning(dt)
	g_currentMission.hud.sideNotifications:update(dt)
	self.camera:setCursorLocked(self.cursor.isCatchingCursor)
	self.camera:update(dt)
	if self.isMouseMode and self.isMouseInMenu then
		self.cursor:setCameraRay(nil)
	else
		self.cursor:setCameraRay(self.camera:getPickRay())
	end
	if self.configurations == nil then
		self.cursor:update(dt)
		self.brush:update(dt)
	end
	if self.brush.inputTextDirty then
		self:updateBrushActionTexts()
		self.brush.inputTextDirty = false
	end
	if self.sound:setActiveSound(self.brush.activeSoundId, self.brush.activeSoundPitchModifier) then
		self.brush.activeSoundId = ConstructionSound.ID.NONE
	end
	self:updateMarqueeAnimation(dt)
end

-- Local values: previousBrush
function ConstructionScreen:setBrush(brush, skipMenuUpdate)
	if brush ~= self.brush then
		local v32_ = self.brush
		if self.brush ~= nil then
			self.brush:deactivate()
			if self.brush ~= self.selectorBrush and self.brush ~= self.destructBrush then
				self.brush:delete()
			end
		end
		self:removeMenuActionEvents()
		self:removeBrushActionEvents()
		self.camera:removeActionEvents()
		self.cursor:removeActionEvents()
		self.brush = brush
		self.camera:registerActionEvents()
		self.cursor:registerActionEvents()
		if self.brush == nil or self.brush == self.selectorBrush then
			self:registerMenuActionEvents(true)
		elseif self.brush ~= nil then
			self:registerMenuActionEvents(false)
		end
		self.buttonPagePrev:setVisible(self.brush ~= self.destructBrush)
		self.buttonPageNext:setVisible(self.brush ~= self.destructBrush)
		if self.brush == self.destructBrush then
			self.buttonBack:setText(g_i18n:getText("ui_demolitionModeExit"))
		else
			self.buttonBack:setText(g_i18n:getText("button_back"))
		end
		if brush ~= nil then
			self.brush:activate()
			if v32_ ~= nil and self.brush:class() == v32_:class() then
				self.brush:copyState(v32_)
			end
			self:registerBrushActionEvents()
		end
		if not skipMenuUpdate then
			self:updateMenuState(v32_)
		end
		self:updateBrushActionTexts()
		self:updateMenuActionTexts()
		self.camera:setMovementDisabledForGamepad(self.brush == nil)
	end
end

function ConstructionScreen:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	self.isMouseInMenu = GuiUtils.checkOverlayOverlap(posX, posY, self.menuBox.absPosition[1], self.menuBox.absPosition[2], self.menuBox.absSize[1], self.menuBox.absSize[2])
	if not self.isMouseInMenu then
		self.isMouseInMenu = GuiUtils.checkOverlayOverlap(posX, posY, self.categoryContainer.absPosition[1], self.categoryContainer.absPosition[2], self.categoryContainer.absSize[1], self.categoryContainer.absSize[2])
	end
	self.camera.mouseDisabled = self.isMouseInMenu
	self.cursor.mouseDisabled = self.isMouseInMenu
	self.camera:setMouseEdgeScrollingActive(self.brush ~= self.selectorBrush)
	self.camera:mouseEvent(posX, posY, isDown, isUp, button)
	if self.configurations == nil then
		self.cursor:mouseEvent(posX, posY, isDown, isUp, button)
	end
end

function ConstructionScreen:draw()
	if not ConstructionScreen.uiHidden then
		ConstructionScreen:superClass().draw(self)
		g_currentMission.hud:drawInputHelp(self.helpDisplay.position[1], self.helpDisplay.position[2])
		g_currentMission.hud.gameInfoDisplay:draw()
		g_currentMission.hud:drawSideNotification()
		g_currentMission.hud:drawBlinkingWarning()
		if self.configurations == nil then
			self.cursor:draw()
			if self.brush.draw ~= nil then
				self.brush:draw()
			end
		end
	end
end

function ConstructionScreen:onInputModeChanged(inputMode)
	self.isMouseMode = inputMode[1] == GS_INPUT_HELP_MODE_KEYBOARD
	self:updateMenuState()
	self:updateMenuActionTexts()
end

function ConstructionScreen:onAppWindowFocusChanged(hasFocus)
	if self.camera ~= nil then
		self.camera:setMouseEdgeScrollingActive(hasFocus)
	end
end

-- Local values: _, eventId
function ConstructionScreen:registerMenuActionEvents(hasMenuButtons)
	self.menuEvents = {}
	local _, v46_ = g_inputBinding:registerActionEvent(InputAction.MENU_ACCEPT, self, self.onButtonMenuAccept, false, true, false, true)
	g_inputBinding:setActionEventTextPriority(v46_, GS_PRIO_VERY_LOW)
	g_inputBinding:setActionEventTextVisibility(v46_, false)
	self.acceptButtonEvent = v46_
	local _, v47_ = g_inputBinding:registerActionEvent(InputAction.MENU_BACK, self, self.onButtonMenuBack, false, true, false, true)
	g_inputBinding:setActionEventTextPriority(v47_, GS_PRIO_VERY_LOW)
	self.backButtonEvent = v47_
	local v48_ = self.menuEvents
	table.insert(v48_, v47_)
	local _, v49_ = g_inputBinding:registerActionEvent(InputAction.PAUSE, g_localPlayer.inputComponent, g_localPlayer.inputComponent.onInputPause, false, true, false, true)
	g_inputBinding:setActionEventTextVisibility(v49_, false)
	local _, v50_ = g_inputBinding:registerActionEvent(InputAction.TOGGLE_HELP_TEXT, g_localPlayer.inputComponent, g_localPlayer.inputComponent.onInputToggleHelpText, false, true, false, true)
	g_inputBinding:setActionEventTextVisibility(v50_, false)
	if hasMenuButtons then
		local _, v51_ = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_UP_DOWN, self, self.onMenuUpDown, false, true, true, true)
		g_inputBinding:setActionEventTextVisibility(v51_, false)
		local v52_ = self.menuEvents
		table.insert(v52_, v51_)
		local _, v53_ = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_LEFT_RIGHT, self, self.onMenuLeftRight, false, true, true, true)
		g_inputBinding:setActionEventTextVisibility(v53_, false)
		local v54_ = self.menuEvents
		table.insert(v54_, v53_)
		local _, v55_ = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_UP_DOWN, self, self.onReleaseUpDown, true, false, false, true)
		g_inputBinding:setActionEventTextVisibility(v55_, false)
		local v56_ = self.menuEvents
		table.insert(v56_, v55_)
		local _, v57_ = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_LEFT_RIGHT, self, self.onReleaseLeftRight, true, false, false, true)
		g_inputBinding:setActionEventTextVisibility(v57_, false)
		local v58_ = self.menuEvents
		table.insert(v58_, v57_)
		local _, v59_ = g_inputBinding:registerActionEvent(InputAction.MENU_PAGE_PREV, self, self.onMenuPagePrev, false, true, false, true)
		g_inputBinding:setActionEventTextVisibility(v59_, false)
		local v60_ = self.menuEvents
		table.insert(v60_, v59_)
		local _, v61_ = g_inputBinding:registerActionEvent(InputAction.MENU_PAGE_NEXT, self, self.onMenuPageNext, false, true, false, true)
		g_inputBinding:setActionEventTextVisibility(v61_, false)
		local v62_ = self.menuEvents
		table.insert(v62_, v61_)
	end
	self:updateMenuActionTexts()
end

function ConstructionScreen:onMenuUpDown(_, inputValue)
	g_gui:onMenuInput(InputAction.MENU_AXIS_UP_DOWN, inputValue)
end

function ConstructionScreen:onMenuLeftRight(_, inputValue)
	g_gui:onMenuInput(InputAction.MENU_AXIS_LEFT_RIGHT, inputValue)
end

function ConstructionScreen:onReleaseUpDown(action)
	g_gui:onReleaseMovement(InputAction.MENU_AXIS_UP_DOWN)
end

function ConstructionScreen:onReleaseLeftRight(action)
	g_gui:onReleaseMovement(InputAction.MENU_AXIS_LEFT_RIGHT)
end

function ConstructionScreen:onMenuPagePrev()
	self:onCategoryChanged(nil, nil, true)
end

function ConstructionScreen:onMenuPageNext()
	self:onCategoryChanged(nil, nil, false)
end

function ConstructionScreen:updateMenuActionTexts()
	g_inputBinding:setActionEventTextVisibility(self.backButtonEvent, false)
	if self.brush == self.selectorBrush then
		g_inputBinding:setActionEventText(self.backButtonEvent, g_i18n:getText("input_CONSTRUCTION_EXIT"))
	else
		g_inputBinding:setActionEventText(self.backButtonEvent, g_i18n:getText("input_CONSTRUCTION_CANCEL"))
	end
end

-- Local values: _, event
function ConstructionScreen:removeMenuActionEvents()
	for _, v69_ in ipairs(self.menuEvents) do
		g_inputBinding:removeActionEvent(v69_)
	end
end

function ConstructionScreen:onButtonMenuAccept()
	if self.isMouseMode or self.brush == self.selectorBrush and self.selectorBrush.lastPlaceable == nil or self.configurations ~= nil then
		self.dragIsLocked = true
		g_gui:notifyControls("MENU_ACCEPT")
	else
		self:onButtonPrimary()
	end
end

function ConstructionScreen:onButtonMenuBack()
	if self.brush:canCancel() then
		self.brush:cancel()
		return
	elseif self.brush == self.destructBrush then
		self.destructMode = false
		self:setBrush(self.previousBrush)
		return
	elseif self.configurations == nil then
		if self.brush.isSelector then
			self:changeScreen(nil)
		else
			self:setBrush(self.selectorBrush)
		end
	else
		self:onShowConfigs()
		return
	end
end

-- Local values: oldCategory
function ConstructionScreen:onCategoryChanged(_, _, isLeftButton)
	local v74_ = self.currentCategory
	local v75_
	if isLeftButton then
		v75_ = v74_ - 1
	else
		v75_ = v74_ + 1
	end
	local v76_
	if v75_ <= 0 then
		v76_ = #self.categories
	else
		v76_ = #self.categories < v75_ and 1 or v75_
	end
	if v76_ ~= self.currentCategory then
		self:setCurrentCategory(v76_)
	end
end

function ConstructionScreen:onSubCategoryChanged(index)
	self:setCurrentTab(index)
end

-- Local values: _, eventId, brush
function ConstructionScreen:registerBrushActionEvents()
	local v80_ = self.brush
	if v80_ ~= nil then
		self.brushEvents = {}
		if v80_.supportsPrimaryButton then
			local v81_
			if v80_.supportsPrimaryDragging then
				local v82_
				v82_, v81_ = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_PRIMARY, self, self.onButtonPrimaryDrag, true, true, true, true)
				local v83_ = self.brushEvents
				table.insert(v83_, v81_)
				self.primaryBrushEvent = v81_
			else
				local v84_
				v84_, v81_ = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_PRIMARY, self, self.onButtonPrimary, false, true, false, true)
				local v85_ = self.brushEvents
				table.insert(v85_, v81_)
				self.primaryBrushEvent = v81_
			end
			g_inputBinding:setActionEventTextPriority(v81_, GS_PRIO_VERY_HIGH)
		end
		if v80_.supportsSecondaryButton then
			local v86_
			if v80_.supportsSecondaryDragging then
				local v87_
				v87_, v86_ = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_SECONDARY, self, self.onButtonSecondaryDrag, true, true, true, true)
				local v88_ = self.brushEvents
				table.insert(v88_, v86_)
				self.secondaryBrushEvent = v86_
			else
				local v89_
				v89_, v86_ = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_SECONDARY, self, self.onButtonSecondary, false, true, false, true)
				local v90_ = self.brushEvents
				table.insert(v90_, v86_)
				self.secondaryBrushEvent = v86_
			end
			g_inputBinding:setActionEventTextPriority(v86_, GS_PRIO_VERY_HIGH)
		end
		if v80_.supportsTertiaryButton then
			local _, v91_ = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_TERTIARY, self, self.onButtonTertiary, false, true, false, true)
			self.tertiaryBrushEvent = v91_
			g_inputBinding:setActionEventTextPriority(self.tertiaryBrushEvent, GS_PRIO_HIGH)
			local v92_ = self.brushEvents
			local v93_ = self.tertiaryBrushEvent
			table.insert(v92_, v93_)
		end
		if v80_.supportsFourthButton then
			local _, v94_ = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_FOURTH, self, self.onButtonFourth, false, true, false, true)
			self.fourthBrushEvent = v94_
			g_inputBinding:setActionEventTextPriority(self.fourthBrushEvent, GS_PRIO_HIGH)
			local v95_ = self.brushEvents
			local v96_ = self.fourthBrushEvent
			table.insert(v95_, v96_)
		end
		if v80_.placeableHasConfigs then
			local _, v97_ = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_SHOW_CONFIGS, self, self.onShowConfigs, false, true, false, true)
			self.showConfigsEvent = v97_
			g_inputBinding:setActionEventText(self.showConfigsEvent, g_i18n:getText("input_CONSTRUCTION_SHOW_CONFIGS"))
			g_inputBinding:setActionEventTextPriority(self.showConfigsEvent, GS_PRIO_HIGH)
			local v98_ = self.brushEvents
			local v99_ = self.showConfigsEvent
			table.insert(v98_, v99_)
		end
		if v80_.supportsPrimaryAxis then
			local _, v100_ = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_ACTION_PRIMARY, self, self.onAxisPrimary, false, not v80_.primaryAxisIsContinuous, v80_.primaryAxisIsContinuous, true)
			self.primaryBrushAxisEvent = v100_
			g_inputBinding:setActionEventTextPriority(self.primaryBrushAxisEvent, GS_PRIO_HIGH)
			local v101_ = self.brushEvents
			local v102_ = self.primaryBrushAxisEvent
			table.insert(v101_, v102_)
		end
		if v80_.supportsSecondaryAxis then
			local _, v103_ = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_ACTION_SECONDARY, self, self.onAxisSecondary, false, not v80_.secondaryAxisIsContinuous, v80_.secondaryAxisIsContinuous, true)
			self.secondaryBrushAxisEvent = v103_
			g_inputBinding:setActionEventTextPriority(self.secondaryBrushAxisEvent, GS_PRIO_HIGH)
			local v104_ = self.brushEvents
			local v105_ = self.secondaryBrushAxisEvent
			table.insert(v104_, v105_)
		end
		if v80_.supportsSnapping then
			local _, v106_ = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_SNAPPING, self, self.onButtonSnapping, false, true, false, true)
			self.snappingBrushEvent = v106_
			g_inputBinding:setActionEventTextPriority(self.snappingBrushEvent, GS_PRIO_HIGH)
			local v107_ = self.brushEvents
			local v108_ = self.snappingBrushEvent
			table.insert(v107_, v108_)
		end
	end
end

-- Local values: text, text, text, text, text, text, text
function ConstructionScreen:updateBrushActionTexts()
	if self.primaryBrushEvent ~= nil then
		local v110_ = self.brush:getButtonPrimaryText()
		if v110_ ~= nil then
			g_inputBinding:setActionEventText(self.primaryBrushEvent, g_i18n:convertText(v110_))
		end
		g_inputBinding:setActionEventTextVisibility(self.primaryBrushEvent, v110_ ~= nil)
	end
	if self.secondaryBrushEvent ~= nil then
		local v111_ = self.brush:getButtonSecondaryText()
		if v111_ ~= nil then
			g_inputBinding:setActionEventText(self.secondaryBrushEvent, g_i18n:convertText(v111_))
		end
		g_inputBinding:setActionEventTextVisibility(self.secondaryBrushEvent, v111_ ~= nil)
	end
	if self.tertiaryBrushEvent ~= nil then
		local v112_ = self.brush:getButtonTertiaryText()
		if v112_ ~= nil then
			g_inputBinding:setActionEventText(self.tertiaryBrushEvent, g_i18n:convertText(v112_))
		end
		g_inputBinding:setActionEventTextVisibility(self.tertiaryBrushEvent, v112_ ~= nil)
	end
	if self.fourthBrushEvent ~= nil then
		local v113_ = self.brush:getButtonFourthText()
		if v113_ ~= nil then
			g_inputBinding:setActionEventText(self.fourthBrushEvent, g_i18n:convertText(v113_))
		end
		g_inputBinding:setActionEventTextVisibility(self.fourthBrushEvent, v113_ ~= nil)
	end
	if self.primaryBrushAxisEvent ~= nil then
		local v114_ = self.brush:getAxisPrimaryText()
		if v114_ ~= nil then
			g_inputBinding:setActionEventText(self.primaryBrushAxisEvent, g_i18n:convertText(v114_))
		end
		g_inputBinding:setActionEventTextVisibility(self.primaryBrushAxisEvent, v114_ ~= nil)
	end
	if self.secondaryBrushAxisEvent ~= nil then
		local v115_ = self.brush:getAxisSecondaryText()
		if v115_ ~= nil then
			g_inputBinding:setActionEventText(self.secondaryBrushAxisEvent, g_i18n:convertText(v115_))
		end
		g_inputBinding:setActionEventTextVisibility(self.secondaryBrushAxisEvent, v115_ ~= nil)
	end
	if self.snappingBrushEvent ~= nil then
		local v116_ = self.brush:getButtonSnappingText()
		if v116_ ~= nil then
			g_inputBinding:setActionEventText(self.snappingBrushEvent, g_i18n:convertText(v116_))
		end
		g_inputBinding:setActionEventTextVisibility(self.snappingBrushEvent, v116_ ~= nil)
	end
end

-- Local values: _, event
function ConstructionScreen:removeBrushActionEvents()
	for _, v118_ in ipairs(self.brushEvents) do
		g_inputBinding:removeActionEvent(v118_)
	end
	self.primaryBrushEvent = nil
	self.secondaryBrushEvent = nil
	self.tertiaryBrushEvent = nil
	self.fourthBrushEvent = nil
	self.primaryBrushAxisEvent = nil
	self.secondaryBrushAxisEvent = nil
	self.snappingBrushEvent = nil
	self.showConfigsEvent = nil
end

function ConstructionScreen:onButtonPrimary(_, inputValue, _, isAnalog, isMouse)
	if not self.isMouseInMenu and self.configurations == nil then
		self.brush:onButtonPrimary()
	end
end

-- Local values: isDown, isDrag, isUp
function ConstructionScreen:onButtonPrimaryDrag(_, inputValue, _, isAnalog, isMouse)
	if not self.isMouseInMenu then
		local v122_
		if inputValue == 1 then
			v122_ = self.previousPrimaryDragValue ~= 1
		else
			v122_ = false
		end
		local v123_
		if inputValue == 1 then
			v123_ = self.previousPrimaryDragValue == 1
		else
			v123_ = false
		end
		local v124_ = inputValue == 0
		self.previousPrimaryDragValue = inputValue
		if self.dragIsLocked then
			if v124_ then
				self.dragIsLocked = false
				return
			end
		else
			self.brush:onButtonPrimary(v122_, v123_, v124_)
		end
	end
end

function ConstructionScreen:onButtonSecondary(_, inputValue, _, isAnalog, isMouse)
	if not self.isMouseInMenu then
		self.brush:onButtonSecondary()
	end
end

-- Local values: isDown, isDrag, isUp
function ConstructionScreen:onButtonSecondaryDrag(_, inputValue, _, isAnalog, isMouse)
	if not self.isMouseInMenu then
		local v128_
		if inputValue == 1 then
			v128_ = self.previousSecondaryDragValue ~= 1
		else
			v128_ = false
		end
		local v129_
		if inputValue == 1 then
			v129_ = self.previousSecondaryDragValue == 1
		else
			v129_ = false
		end
		local v130_ = inputValue == 0
		self.previousSecondaryDragValue = inputValue
		self.brush:onButtonSecondary(v128_, v129_, v130_)
	end
end

function ConstructionScreen:onButtonTertiary(_, inputValue, _, isAnalog, isMouse)
	self.brush:onButtonTertiary(self)
end

function ConstructionScreen:onButtonFourth(_, inputValue, _, isAnalog, isMouse)
	self.brush:onButtonFourth()
end

function ConstructionScreen:onButtonSnapping(_, inputValue, _, isAnalog, isMouse)
	self.brush:onButtonSnapping()
end

function ConstructionScreen:onAxisPrimary(_, inputValue, _, isAnalog, isMouse)
	self.brush:onAxisPrimary(inputValue)
end

function ConstructionScreen:onAxisSecondary(_, inputValue, _, isAnalog, isMouse)
	self.brush:onAxisSecondary(inputValue)
end

-- Local values: _, event, _, eventId, storeItem, configurations, configName, index, configName, index
function ConstructionScreen:onShowConfigs()
	if self.configsBox:getIsVisible() then
		self.configsBox:setVisible(false)
		self.listBox:setVisible(true)
		self:registerBrushActionEvents()
		self:updateBrushActionTexts()
		self:updateMenuActionTexts()
		for _, v139_ in ipairs(self.configEvents) do
			g_inputBinding:removeActionEvent(v139_)
		end
		self.cursor:setRotationEnabled(self.cursorRotationEnabled or false)
		self.configurations = nil
		if self.itemList:getItemCount() > 0 then
			FocusManager:setFocus(self.itemList)
		else
			FocusManager:setFocus(self.subCategorySelector)
		end
		self.categorySelector:setDisabled(false)
	else
		self.configsBox:setVisible(true)
		self.listBox:setVisible(false)
		self:removeBrushActionEvents()
		local _, v140_ = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_UP_DOWN, self, self.onMenuUpDown, false, true, true, true)
		g_inputBinding:setActionEventTextVisibility(v140_, false)
		local v141_ = self.configEvents
		table.insert(v141_, v140_)
		local _, v142_ = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_LEFT_RIGHT, self, self.onMenuLeftRight, false, true, true, true)
		g_inputBinding:setActionEventTextVisibility(v142_, false)
		local v143_ = self.configEvents
		table.insert(v143_, v142_)
		local _, v144_ = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_UP_DOWN, self, self.onReleaseUpDown, true, false, false, true)
		g_inputBinding:setActionEventTextVisibility(v144_, false)
		local v145_ = self.configEvents
		table.insert(v145_, v144_)
		local _, v146_ = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_LEFT_RIGHT, self, self.onReleaseLeftRight, true, false, false, true)
		g_inputBinding:setActionEventTextVisibility(v146_, false)
		local v147_ = self.configEvents
		table.insert(v147_, v146_)
		self.cursorRotationEnabled = self.cursor.rotationEnabled
		self.cursor:setRotationEnabled(false)
		local v148_ = self.brush.storeItem
		local v149_ = {}
		if v148_.defaultConfigurationIds ~= nil then
			for v150_, v151_ in pairs(v148_.defaultConfigurationIds) do
				v149_[v150_] = v151_
			end
		end
		if self.brush.configurations ~= nil then
			for v152_, v153_ in pairs(self.brush.configurations) do
				v149_[v152_] = v153_
			end
		end
		self.needsRefocus = true
		self.configurations = v149_
		self.configurationData = {}
		self:processStoreItemConfigurations(v148_)
		self:updateConfigOptionsDisplay(v148_)
		self.categorySelector:setDisabled(true)
	end
end

function ConstructionScreen:onClickDestruct()
	if self.destructMode then
		self.destructMode = false
		self:setBrush(self.previousBrush)
	else
		self.destructMode = true
		self.previousBrush = self.brush
		self:setBrush(self.destructBrush)
	end
end

function ConstructionScreen:onFocusConfigurationOption(element)
	self.focusedColorElement = nil
	self.focusedButtonElement = nil
	self.focusedOptionElement = nil
	if element.name == "button" then
		self.focusedButtonElement = element
	elseif element.name == "color" then
		self.focusedColorElement = element
	elseif element.name == "option" then
		self.focusedOptionElement = element
	elseif element.name == "yesNoOption" then
		self.focusedOptionElement = element
	end
	self:updateConfigurationButton()
end

function ConstructionScreen:onLeaveConfigurationOption(element)
	self.focusedColorElement = nil
	self.focusedButtonElement = nil
	self.focusedOptionElement = nil
	self:updateConfigurationButton()
end

-- Local values: visible
function ConstructionScreen:updateConfigurationButton()
	local v159_ = self.focusedButtonElement ~= nil and true or self.focusedColorElement ~= nil
	self.configButton:setVisible(v159_)
	self.buttonsPanel:invalidateLayout()
end

function ConstructionScreen:onClickConfigAction()
	if self.focusedColorElement == nil then
		if self.focusedButtonElement ~= nil then
			self.focusedButtonElement:onFocusActivate()
		end
	else
		self.focusedColorElement:onFocusActivate()
	end
end

-- Local values: items
function ConstructionScreen:getNumberOfItemsInSection(list, section)
	if list == self.categorySelector then
		return #self.categories
	end
	if self.currentCategory == nil or self.currentTab == nil then
		return 0
	end
	local v163_ = self.items[self.currentCategory][self.currentTab]
	return v163_ == nil and 0 or #v163_
end

-- Local values: category, tabButton, item
function ConstructionScreen:populateCellForItemInSection(list, section, index, cell)
	if list == self.categorySelector then
		local v168_ = self.categories[index]
		local v169_ = cell:getAttribute("tabButton")
		v169_:setImageFilename(nil, v168_.iconFilename)
		v169_:setImageUVs(nil, v168_.iconUVs)
		v169_:setImageSlice(nil, v168_.iconSliceId)
		function v169_.onClickCallback()
			-- upvalues: (copy) self, (copy) index
			self:setCurrentCategory(index)
		end
		return
	else
		local v170_ = self.items[self.currentCategory][self.currentTab][index]
		cell:getAttribute("price"):setValue(g_i18n:formatMoney(v170_.price, 0, true, true))
		cell:getAttribute("terrainLayer"):setVisible(v170_.terrainOverlayLayer ~= nil)
		cell:getAttribute("icon"):setVisible(v170_.imageFilename ~= nil)
		if v170_.imageFilename == nil then
			if v170_.terrainOverlayLayer ~= nil then
				cell:getAttribute("terrainLayer"):setTerrainLayer(g_terrainNode, v170_.terrainOverlayLayer)
			end
		else
			cell:getAttribute("icon"):setImageFilename(v170_.imageFilename)
		end
	end
end

-- Local values: selectedBrush
function ConstructionScreen:onListSelectionChanged(list, section, index)
	if not g_gui.currentlyReloading then
		if list == self.itemList then
			local v174_ = self.items[self.currentCategory][self.currentTab][index]
			if v174_ == nil then
				self:assignItemAttributeData(nil)
				return
			end
			self.lastSelectionIndex = index
			self:assignItemAttributeData(v174_)
		end
	end
end

-- Local values: selectedBrush
function ConstructionScreen:onListHighlightChanged(list, section, index)
	if not g_gui.currentlyReloading then
		if list == self.itemList then
			local v178_ = index or self.lastSelectionIndex
			local v179_ = self.items[self.currentCategory][self.currentTab][v178_]
			if v179_ == nil then
				self:assignItemAttributeData(nil)
				return
			end
			self:assignItemAttributeData(v179_)
		end
	end
end

-- Local values: item, brush
function ConstructionScreen:onClickItem()
	local v181_ = self.items[self.currentCategory][self.currentTab][self.itemList.selectedIndex]
	local v182_ = v181_.brushClass.new(nil, self.cursor)
	if v181_.brushParameters ~= nil then
		v182_:setStoreItem(v181_.storeItem)
		local v183_ = v181_.brushParameters
		v182_:setParameters(unpack(v183_))
		v182_.uniqueIndex = v181_.uniqueIndex
	end
	self.destructMode = false
	self:setBrush(v182_, true)
end

function ConstructionScreen:refreshDetails()
	self:onListSelectionChanged(self.itemList, 1, self.itemList.selectedIndex)
end

-- Local values: layoutsToInvalidate, k, clone, layout, _, k, _, displayItem, i, brand, modName, description
function ConstructionScreen:assignItemAttributeData(selectedBrush)
	local v187_ = {}
	for v188_, v189_ in pairs(self.clonedElements) do
		if v187_[v189_.parent] == nil then
			v187_[v189_.parent] = true
		end
		v189_:delete()
		self.clonedElements[v188_] = nil
	end
	for v190_, _ in pairs(v187_) do
		v190_:invalidateLayout()
	end
	for v191_, _ in pairs(self.marqueeBoxes) do
		self.marqueeBoxes[v191_] = nil
	end
	local v192_
	if selectedBrush == nil then
		v192_ = nil
	else
		self.itemDetailsName:setText(selectedBrush.name)
		v192_ = selectedBrush.displayItem
	end
	self.itemDetailsName:setVisible(selectedBrush ~= nil)
	self.attributesLayout:setVisible(v192_ ~= nil)
	if v192_ == nil then
		self.itemDetailsBrandImage:setVisible(false)
		self.itemDetailsModName:setVisible(false)
		self.itemDetailsDescription:setVisible(false)
	else
		for v193_ = #self.attributesLayout.elements, 1, -1 do
			self:queueDetailsCell(self.attributesLayout.elements[v193_])
		end
		self:assignItemTextData(v192_)
		self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_FILL_TYPES, v192_.fillTypeIconFilenames)
		self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_FILL_TYPES, v192_.foodFillTypeIconFilenames)
		self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_INPUT, v192_.prodPointInputFillTypeIconFilenames)
		self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_OUTPUT, v192_.prodPointOutputFillTypeIconFilenames)
		self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_INPUT, v192_.sellingStationFillTypesIconFilenames)
		self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_OUTPUT, v192_.buyingStationFillTypesIconFilenames)
		self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_FILL_TYPES, v192_.objectStorageFillTypesIconFilenames)
		local v194_ = nil
		local v195_, v196_
		if v192_.storeItem == nil then
			v195_ = nil
			v196_ = nil
		else
			v195_ = g_brandManager:getBrandByIndex(v192_.storeItem.brandIndex)
			if v195_ ~= nil then
				self.itemDetailsBrandImage:setImageFilename(v195_.image)
			end
			if v192_.storeItem.isMod and v192_.storeItem.dlcTitle == nil then
				v194_ = "Mod"
			elseif v192_.storeItem.isMod and v192_.storeItem.dlcTitle ~= nil then
				v194_ = v192_.storeItem.dlcTitle .. " (Mod)"
			elseif v192_.storeItem.dlcTitle ~= nil then
				v194_ = v192_.storeItem.dlcTitle
			end
			self.itemDetailsModName:setText(v194_ or "")
			v196_ = v192_.functionText
			self.itemDetailsDescription:setText(v196_)
		end
		self.itemDetailsBrandImage:setVisible(v195_ ~= nil)
		self.itemDetailsModName:setVisible(v194_ ~= nil)
		self.itemDetailsDescription:setVisible(v196_ ~= nil)
		self.descriptionLayout:invalidateLayout()
		self.attributesLayout:invalidateLayout()
	end
end

-- Local values: numAttributesUsed, i, value, cell, icon, text, profile, slotCount
function ConstructionScreen:assignItemTextData(displayItem)
	local v199_ = 0
	if displayItem ~= nil and displayItem.attributeValues ~= nil then
		for v200_, v206_ in pairs(displayItem.attributeValues) do
			local v202_ = self:dequeueDetailsCell(ConstructionScreen.CELL_NAME_DETAIL)
			local v203_ = v202_:getDescendantByName("icon")
			local v204_ = v202_:getDescendantByName("text")
			local v205_ = displayItem.attributeIconProfiles[v200_]
			if v205_ ~= nil and v205_ ~= "" then
				if type(v206_) == "string" then
					local v206_ = v206_:gsub("%$SLOTS%$", (string.format("(%0d / %0d)", g_currentMission.slotSystem.slotUsage, g_currentMission.slotSystem.slotLimit)))
				end
				v204_:setText(v206_)
				v203_:applyProfile(v205_)
				v199_ = v199_ + 1
			end
			v202_:setSize(v203_.absSize[1] + v203_.margin[1] + v204_.absSize[1], nil)
		end
	end
end

-- Local values: totalWidth, cell, cellIcon, iconsLayout, _, iconFilename, icon, maxWidth, parentSize, iconsLayoutSize
function ConstructionScreen:assignItemFillTypesData(baseIconProfile, iconFilenames)
	if iconFilenames ~= nil and #iconFilenames > 0 then
		local v210_ = self:dequeueDetailsCell(ConstructionScreen.CELL_NAME_FILL_TYPES)
		local v211_ = v210_:getDescendantByName("icon")
		local v212_ = v210_:getDescendantByName("iconsLayout")
		v211_:applyProfile(baseIconProfile)
		local v213_ = 0
		for _, v214_ in pairs(iconFilenames) do
			local v215_ = self.fruitIconTemplate:clone(v212_)
			v215_:setVisible(true)
			local v216_ = self.clonedElements
			table.insert(v216_, v215_)
			v215_:applyProfile(ShopItemsFrame.PROFILE.ICON_FRUIT_TYPE)
			v215_:setImageFilename(v214_)
			v213_ = v213_ + v215_.absSize[1] + v215_.margin[1] + v215_.margin[3]
		end
		local v217_ = self.attributesLayout.absSize[1] * 0.91
		local v218_ = math.min(v217_, v213_)
		local v219_ = v218_ + v211_.absSize[1] + v211_.margin[1]
		v212_:setSize(v213_, nil)
		v212_:setPosition(0, nil)
		v212_.parent:setSize(v218_, nil)
		v210_:setSize(v219_, nil)
		v212_:invalidateLayout()
		if v219_ < v213_ then
			self.marqueeBoxes[v212_] = 0
			return
		end
		self.marqueeBoxes[v212_] = nil
	end
end

-- Local values: box, time, contentWidth, visibleWidth, scrollAmount, scrollLengthFactor, scrollDuration, alpha, offset
function ConstructionScreen:updateMarqueeAnimation(dt)
	for v222_, v223_ in pairs(self.marqueeBoxes) do
		local v224_ = v222_.absSize[1]
		local v225_ = v222_.parent.absSize[1]
		local v226_ = v224_ - v225_
		local v227_ = 5000 * (v224_ / v225_)
		local v228_ = v223_ + dt
		if v227_ <= v228_ then
			v228_ = -v227_
		end
		v222_:setPosition(-(v226_ * MathUtil.smoothstep(0.1, 0.9, math.abs(v228_) / v227_)))
		self.marqueeBoxes[v222_] = v228_
	end
end

function ConstructionScreen:onSlotUsageChanged()
	self:refreshDetails()
end

-- Local values: configSets, defaultSet, i, configSet, price, name, index, setOptions, name, index, colorPickerIndex, configurations, i, configName, configItems, isColor
function ConstructionScreen:processStoreItemConfigurations(placeable)
	self.configSelection = {
		["title"] = g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.CONFIGURATION_LABEL),
		["texts"] = {},
		["prices"] = {},
		["options"] = {}
	}
	self.currentConfigSet = 1
	local v232_ = placeable.configurationSets
	local v233_ = (placeable.configurationSets == nil or #placeable.configurationSets == 0) and {
		{
			["name"] = "",
			["configurations"] = {},
			["isDefault"] = true
		}
	} or v232_
	if placeable.configurations == nil then
		local v234_ = self.configSelection.options
		table.insert(v234_, {})
		self.displayableColorCount = 0
	else
		for v235_, v236_ in ipairs(v233_) do
			if v236_.isDefault then
				self.currentConfigSet = v235_
			end
			if v236_.overwrittenTitle ~= nil then
				self.configSelection.title = v236_.overwrittenTitle
			end
			local v237_ = 0
			for v238_, v239_ in pairs(v236_.configurations) do
				v237_ = v237_ + placeable.configurations[v238_][v239_].price
			end
			local v240_ = self.configSelection.prices
			table.insert(v240_, v237_)
			local v241_ = self.configSelection.texts
			local v242_ = v236_.name
			table.insert(v241_, v242_)
			local v243_ = self:processStoreItemConfigurationSet(placeable, v236_)
			local v244_ = self.configSelection.options
			table.insert(v244_, v243_)
		end
		for v245_, v246_ in pairs(v233_[self.currentConfigSet].configurations) do
			self.configurations[v245_] = v246_
		end
		self.colorPickers = {}
		local v247_ = g_placeableConfigurationManager:getSortedConfigurationTypes()
		local v248_ = 1
		for v249_ = 1, #v247_ do
			local v250_ = v247_[v249_]
			local v251_ = placeable.configurations[v250_]
			if placeable.configurations[v250_] ~= nil then
				local v252_ = g_placeableConfigurationManager:getConfigurationSelectorType(v250_) == ConfigurationUtil.SELECTOR_COLOR
				if #v251_ > 1 and v252_ then
					self:processStoreItemColorOption(placeable, v250_, v251_, v248_)
					v248_ = v248_ + 1
				end
			end
		end
		self.displayableColorCount = v248_ - 1
	end
end

-- Local values: options, configurationTypes, _, configName, items, option
function ConstructionScreen:processStoreItemConfigurationSet(storeItem, configSet)
	local v256_ = g_placeableConfigurationManager:getSortedConfigurationTypes()
	local v257_ = {}
	for _, v258_ in ipairs(v256_) do
		if g_placeableConfigurationManager:getConfigurationSelectorType(v258_) ~= ConfigurationUtil.SELECTOR_COLOR then
			local v259_ = storeItem.configurations[v258_]
			if v259_ ~= nil and (#v259_ > 1 and configSet.configurations[v258_] == nil) then
				local v260_ = self:processStoreItemConfigurationOption(storeItem, v258_, v259_)
				table.insert(v257_, v260_)
			end
		end
	end
	return v257_
end

-- Local values: configOption, initialIndex, overwrittenTitle, hasValidIcons, index, _, item, isSelectable, _, otherConfigItems, _, configItem, _, dependentConfiguration, iconFilename
function ConstructionScreen:processStoreItemConfigurationOption(storeItem, configName, configItems)
	local v264_ = {
		["name"] = configName,
		["title"] = g_placeableConfigurationManager:getConfigurationAttribute(configName, "title"),
		["texts"] = {},
		["icons"] = {},
		["options"] = {},
		["defaultIndex"] = 1
	}
	local v265_ = 1
	local v266_ = nil
	local v267_ = 1
	local v268_ = false
	for _, v269_ in ipairs(configItems) do
		if v269_.isDefault then
			v264_.defaultIndex = v265_
			v267_ = v265_
		end
		local v270_ = v269_.isSelectable
		for _, v271_ in pairs(storeItem.configurations) do
			for _, v272_ in pairs(v271_) do
				if v272_.dependentConfigurations ~= nil then
					for _, v273_ in pairs(v272_.dependentConfigurations) do
						if v273_.name == configName then
							return
						end
					end
				end
			end
		end
		v266_ = v266_ or v269_.overwrittenTitle
		if v270_ then
			local v274_ = v264_.texts
			local v275_ = v269_.name
			table.insert(v274_, v275_)
			local v276_ = v264_.options
			table.insert(v276_, v269_)
			if v269_.brandIndex ~= nil then
				local v277_ = g_brandManager:getBrandIconByIndex(v269_.brandIndex)
				if v277_ ~= nil then
					local v278_ = v264_.icons
					table.insert(v278_, v277_)
					v268_ = true
				end
			end
			if #v264_.icons ~= #v264_.texts then
				local v279_ = v264_.icons
				local v280_ = v269_.name
				table.insert(v279_, v280_)
			end
			v265_ = v265_ + 1
		end
	end
	v264_.defaultIndex = v267_
	v264_.title = v266_ or v264_.title
	if not v268_ then
		v264_.icons = nil
	end
	if #v264_.options > 1 then
		return v264_
	end
end

-- Local values: overwrittenTitle, _, item
function ConstructionScreen:processStoreItemColorOption(storeItem, configName, colorItems, colorPickerIndex)
	local v284_ = nil
	for _, v285_ in ipairs(colorItems) do
		v284_ = v284_ or v285_.overwrittenTitle
	end
	local v286_ = self.colorPickers
	local v287_ = {
		["title"] = v284_ or g_placeableConfigurationManager:getConfigurationAttribute(configName, "title"),
		["configName"] = configName,
		["colorItems"] = colorItems
	}
	table.insert(v286_, v287_)
end

-- Local values: displayableOptionCount, count, i, item, optionData, _, option, i, option, itemsToDisplay, hasCustomColorSupport, j, listElement, colorElement, colorItems, defaultColorIndex
function ConstructionScreen:updateConfigOptionsData(storeItem)
	local v290_ = 0
	local v291_ = 0
	for v292_ = #self.configurationLayout.elements, 1, -1 do
		local v293_ = self.configurationLayout.elements[v292_]
		v293_:setVisible(false)
		FocusManager:removeElement(v293_)
		v293_:unlinkElement()
		if v293_.isLargeConfigItem then
			local v294_ = self.configItemCacheLarge
			table.insert(v294_, v293_)
		else
			local v295_ = self.configItemCache
			table.insert(v295_, v293_)
		end
	end
	self.focusableElementForScroll = nil
	if #self.configSelection.options > 1 then
		v290_ = v290_ + 1
		self:updateConfigSetOptionElement(1, storeItem)
		v291_ = 1
	end
	local v296_ = self.configSelection.options[self.currentConfigSet]
	for _, v297_ in ipairs(v296_) do
		v290_ = v290_ + 1
		v291_ = v291_ + 1
		self:updateConfigOptionElement(v291_, v297_, storeItem)
	end
	self.colorElements = {}
	if self.displayableColorCount > 0 then
		for v_u_298_, v_u_299_ in ipairs(self.colorPickers) do
			local v300_ = 0
			local v_u_301_ = false
			for v302_ = 1, #v_u_299_.colorItems do
				if v_u_299_.colorItems[v302_].isSelectable ~= false then
					v300_ = v300_ + 1
				end
				if v_u_299_.colorItems[v302_].isCustomColor then
					v_u_301_ = true
				end
			end
			if v300_ > 1 then
				local v303_ = self:getOrCreateConfigItem("color")
				local v304_ = v303_:getDescendantByName("color")
				self.colorElements[v_u_298_] = v304_
				local v_u_305_ = v_u_299_.colorItems
				function v304_.onClickCallback(_)
					-- upvalues: (copy) self, (copy) v_u_299_, (copy) v_u_305_, (copy) v_u_298_, (ref) v_u_301_
					local v306_ = self.configurations[v_u_299_.configName]
					local v307_ = v_u_305_[v306_]
					local v308_ = v307_.color
					local v309_ = v307_.materialTemplateName
					local v310_ = self.configurationData[v_u_299_.configName]
					if v310_ ~= nil and v310_[v306_] ~= nil then
						v308_ = v310_[v306_].color or v308_
						v309_ = v310_[v306_].materialTemplateName or v309_
					end
					g_inputBinding:setShowMouseCursor(true)
					ColorPickerDialog.show(self.onPickColor, self, {
						["configName"] = v_u_299_.configName,
						["colorOptionIndex"] = v_u_298_
					}, v_u_305_, nil, v309_, v308_, v_u_301_, true, true)
				end
				self:onPickColor(self.configurations[v_u_299_.configName] or self:getDefaultConfigurationColorIndex(v_u_299_.configName, v_u_305_), {
					["configName"] = v_u_299_.configName,
					["colorOptionIndex"] = v_u_298_
				}, nil, true)
				v303_:getDescendantByName("title"):setText(v_u_299_.title)
				v291_ = v291_ + 1
			end
		end
	end
	self.displayableOptionCount = v290_
	return v291_
end

-- Local values: current, num
function ConstructionScreen:updateConfigOptionsDisplay(storeItem)
	local v313_ = FocusManager.currentGui
	FocusManager:setGui("ConstructionScreen")
	local v314_ = self:updateConfigOptionsData(storeItem)
	self.startClipper:setVisible(v314_ > 0)
	self.configSlider.parent:setVisible(v314_ > 0)
	self.configurationLayout:invalidateLayout()
	FocusManager:setGui(v313_)
	if self.needsRefocus then
		self:selectFirstConfig()
		self.needsRefocus = false
	end
end

-- Local values: isYesNoOption, listElement, optionElement, price
function ConstructionScreen:updateConfigSetOptionElement(configElementIndex, storeItem)
	local v317_
	if #storeItem.configurationSets > 1 then
		v317_ = storeItem.configurationSets[1].isYesNoOption
	else
		v317_ = false
	end
	local v318_ = self:getOrCreateConfigItem(v317_ and "yesNoOption" or "option")
	local v319_
	if v317_ then
		v319_ = v318_:getDescendantByName("yesNoOption")
		v319_:setIsChecked(self.currentConfigSet ~= 1, true)
	else
		v319_ = v318_:getDescendantByName("option")
		v319_:setState(self.currentConfigSet)
	end
	v319_:setTexts(self.configSelection.texts)
	v319_:setDisabled(false)
	function v319_.onClickCallback(_, p320_)
		-- upvalues: (copy) storeItem, (copy) self
		for v321_, _ in pairs(storeItem.configurationSets[self.currentConfigSet].configurations) do
			self.configurations[v321_] = ConfigurationUtil.getDefaultConfigIdFromItems(storeItem.configurations[v321_])
		end
		for v322_, v323_ in pairs(storeItem.configurationSets[p320_].configurations) do
			self.configurations[v322_] = v323_
		end
		self.currentConfigSet = p320_
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CONFIG_WRENCH)
		self:selectFirstConfig()
	end
	v318_:getDescendantByName("title"):setText(self.configSelection.title)
	local v324_ = self.configSelection.prices[self.currentConfigSet]
	v318_:getDescendantByName("price"):setText("+" .. g_i18n:formatMoney(v324_))
end

-- Local values: hasIcons, hasText, isYesNoOption, listElement, optionElement, priceElement, configName, configIndex, i, item
function ConstructionScreen:updateConfigOptionElement(configElementIndex, option, storeItem)
	local v328_ = option.icons ~= nil
	local v329_ = not v328_
	local v330_
	if #option.options > 1 then
		v330_ = option.options[1].isYesNoOption
		if v330_ then
			v328_ = false
			v329_ = false
		end
	else
		v330_ = false
	end
	local v331_ = nil
	if v328_ then
		v331_ = self:getOrCreateLargeConfigItem("option")
	elseif v329_ then
		v331_ = self:getOrCreateConfigItem("option")
	elseif v330_ then
		v331_ = self:getOrCreateConfigItem("yesNoOption")
	end
	local v332_ = v331_:getDescendantByName(v330_ and "yesNoOption" or "option")
	v332_:setVisible(true)
	v332_:setDisabled(#option.options <= 1 and true or option.isDisabled)
	if v328_ then
		v332_:setIcons(option.icons)
	elseif v329_ then
		v332_:setTexts(option.texts)
	elseif v330_ then
		v332_:setTexts(option.texts)
	end
	local v_u_333_ = v331_:getDescendantByName("price")
	local v_u_334_ = option.name
	local v335_ = 0
	for v336_, v337_ in pairs(option.options) do
		if v337_.index == self.configurations[v_u_334_] then
			v335_ = v336_
			break
		end
	end
	if v335_ == 0 or option.options[v335_] == nil then
		v335_ = option.defaultIndex
	end
	if v330_ then
		v332_:setIsChecked(v335_ ~= 1, true)
	else
		v332_:setState(v335_)
	end
	function v332_.onClickCallback(_, p338_)
		-- upvalues: (copy) self, (copy) option, (copy) v_u_334_, (copy) v_u_333_, (copy) storeItem
		if self.brush.placeable ~= nil then
			local v339_ = option.options[p338_].index
			self:setConfigPrice(v_u_334_, v339_, v_u_333_)
			self.configurations[v_u_334_] = v339_
			self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CONFIG_WRENCH)
			self:loadCurrentConfiguration(storeItem)
		end
	end
	self.configurations[v_u_334_] = option.options[v335_].index
	v331_:getDescendantByName("title"):setText(option.title)
	self:setConfigPrice(v_u_334_, option.options[v335_].index, v_u_333_)
end

-- Local values: item, option, color, yesNoOption, price, focusableElement
function ConstructionScreen:getOrCreateConfigItem(type)
	local v342_
	if #self.configItemCache == 0 then
		v342_ = self.configurationItemTemplate:clone(self.configurationLayout)
	else
		v342_ = self.configItemCache[#self.configItemCache]
		self.configItemCache[#self.configItemCache] = nil
		self.configurationLayout:addElement(v342_)
	end
	v342_.isLargeConfigItem = false
	v342_:setVisible(true)
	v342_.focusId = nil
	local v343_ = false
	local v344_ = false
	local v345_ = false
	local v_u_346_ = nil
	if type == "option" then
		v_u_346_ = v342_:getDescendantByName("option")
		v343_ = true
	elseif type == "color" then
		v_u_346_ = v342_:getDescendantByName("color")
		v344_ = true
	elseif type == "yesNoOption" then
		v_u_346_ = v342_:getDescendantByName("yesNoOption")
		v345_ = true
	end
	v342_:getDescendantByName("option"):setVisible(v343_)
	v342_:getDescendantByName("color"):setVisible(v344_)
	v342_:getDescendantByName("yesNoOption"):setVisible(v345_)
	v342_:getDescendantByName("price"):setVisible(true)
	if v_u_346_ ~= nil then
		v_u_346_.forceFocusScrollToTop = self.focusableElementForScroll == nil
		self.focusableElementForScroll = v_u_346_
		v342_:getDescendantByName("title").getIsSelected = function()
			-- upvalues: (ref) v_u_346_
			return v_u_346_:getIsFocused()
		end
	end
	return v342_
end

-- Local values: item, focusableElement
function ConstructionScreen:getOrCreateLargeConfigItem(type)
	local v348_
	if #self.configItemCacheLarge == 0 then
		v348_ = self.configurationItemTemplateLarge:clone(self.configurationLayout)
	else
		v348_ = self.configItemCacheLarge[#self.configItemCacheLarge]
		self.configItemCacheLarge[#self.configItemCacheLarge] = nil
		self.configurationLayout:addElement(v348_)
	end
	v348_.isLargeConfigItem = true
	v348_:setVisible(true)
	v348_.focusId = nil
	local v_u_349_ = v348_:getDescendantByName("option")
	v_u_349_.forceFocusScrollToTop = self.focusableElementForScroll == nil
	self.focusableElementForScroll = v_u_349_
	v348_:getDescendantByName("title").getIsSelected = function()
		-- upvalues: (copy) v_u_349_
		return v_u_349_:getIsFocused()
	end
	return v348_
end

-- Local values: configItems, price
function ConstructionScreen:setConfigPrice(configName, configIndex, priceTextElement)
	local v354_ = self.brush.storeItem.configurations[configName][configIndex].price
	local v355_ = self.brush.placeable ~= nil and ConfigurationUtil.hasBoughtConfiguration(self.brush.placeable, configName, configIndex) and 0 or v354_
	priceTextElement:setText("+" .. g_i18n:formatMoney(v355_) .. "")
	priceTextElement:setVisible(true)
end

-- Local values: configName, isValid, configItems, index, configItem, colorOptionIndex, element, config, color, materialTemplateName, data, isMetallic, isMat, r, g, b, priceElement
function ConstructionScreen:onPickColor(colorIndex, args, customColor, noUpdate)
	local v361_ = args.configName
	if customColor ~= nil then
		local v362_ = self.brush.storeItem.configurations[v361_]
		local v363_ = true
		for v364_, v365_ in pairs(v362_) do
			if v365_.isCustomColor then
				colorIndex = v364_
				v363_ = true
				break
			end
		end
		if v363_ then
			if self.configurationData[v361_] == nil then
				self.configurationData[v361_] = {}
			end
			self.configurationData[v361_][colorIndex] = {}
			self.configurationData[v361_][colorIndex].color = { customColor.customColor[1], customColor.customColor[2], customColor.customColor[3] }
			self.configurationData[v361_][colorIndex].materialTemplateName = customColor.templateName
		end
	end
	if colorIndex ~= nil then
		local v366_ = args.colorOptionIndex
		local v367_ = self.colorElements[v366_]
		self.configurations[v361_] = colorIndex
		local v368_ = self.brush.storeItem.configurations[v361_][colorIndex]
		local v369_ = v368_.color
		local v370_ = v368_.materialTemplateName
		if self.configurationData[v361_] ~= nil then
			local v371_ = self.configurationData[v361_][colorIndex]
			if v371_ ~= nil then
				v369_ = v371_.color or v369_
				local _ = v371_.materialTemplateName or v370_
			end
		end
		local v372_ = v368_.isMetallic
		local v373_ = v368_.isMat
		v367_:getDescendantByName("colorImageGlossy"):setVisible(not (v372_ or v373_))
		v367_:getDescendantByName("colorImageMetallic"):setVisible(v372_)
		v367_:getDescendantByName("colorImageMatte"):setVisible(v373_)
		if MathUtil.getBrightnessFromColor(unpack(v369_)) >= ColorPickButtonElement.BRIGHTNESS_THRESHOLD then
			v367_:getDescendantByName("colorImageGlossy"):setImageColor(nil, 0, 0, 0)
			v367_:getDescendantByName("colorImageMetallic"):setImageColor(nil, 0, 0, 0)
			v367_:getDescendantByName("colorImageMatte"):setImageColor(nil, 0, 0, 0)
		else
			v367_:getDescendantByName("colorImageGlossy"):setImageColor(nil, 1, 1, 1)
			v367_:getDescendantByName("colorImageMetallic"):setImageColor(nil, 1, 1, 1)
			v367_:getDescendantByName("colorImageMatte"):setImageColor(nil, 1, 1, 1)
		end
		local v374_, v375_, v376_ = unpack(v369_)
		v367_:getDescendantByName("colorImage"):setImageColor(nil, math.clamp(v374_, 0, 1), math.clamp(v375_, 0, 1), (math.clamp(v376_, 0, 1)))
		self:setConfigPrice(v361_, colorIndex, v367_.parent:getDescendantByName("price"), self.vehicle)
		if not noUpdate then
			self:loadCurrentConfiguration(self.brush.storeItem)
			self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CONFIG_SPRAY)
		end
	end
end

-- Local values: firstElement, focusElement
function ConstructionScreen:selectFirstConfig()
	local v378_ = self.configurationLayout.elements[1]
	if v378_ == nil then
		FocusManager:unsetFocus(FocusManager:getFocusedElement())
		FocusManager.currentFocusData.focusElement = nil
	else
		local v379_ = v378_:getDescendantByName("option")
		if not v379_:getIsVisible() then
			v379_ = v378_:getDescendantByName("color")
		end
		if not v379_:getIsVisible() then
			v379_ = v378_:getDescendantByName("yesNoOption")
		end
		FocusManager:unsetFocus(v379_)
		FocusManager:setFocus(v379_)
	end
end

-- Local values: data
function ConstructionScreen:loadCurrentConfiguration(storeItem)
	local v382_ = PlaceableLoadingData.new()
	v382_:setConfigurations(self.configurations)
	v382_:setConfigurationData(self.configurationData)
	v382_:setPosition(self.brush.placeable:getPosition())
	self.brush:unloadPlaceable(true)
	self.brush:setStoreItem(storeItem, self.configurations, self.configurationData)
	self.brush:loadPlaceable(v382_)
end

-- Local values: numItems, maxTabs, c, category, t, _, storeItem, brushClass, parameters, brand, brandImage, modDlc
function ConstructionScreen:rebuildData()
	self.categories = g_storeManager:getConstructionCategories()
	self.items = {}
	local v384_ = 0
	local v385_ = 0
	for v386_, v387_ in ipairs(self.categories) do
		self.items[v386_] = {}
		for v388_ = 1, #v387_.tabs do
			self.items[v386_][v388_] = {}
		end
		local v389_ = #v387_.tabs
		v384_ = math.max(v384_, v389_)
	end
	for _, v390_ in ipairs(g_storeManager:getItems()) do
		if v390_.brush ~= nil then
			local v391_ = g_constructionBrushTypeManager:getClassObjectByTypeName(v390_.brush.type)
			local v392_ = v390_.brush.parameters
			local v393_ = (v392_ == nil or #v392_ == 0) and { v390_.xmlFilename } or v392_
			if v391_ ~= nil then
				local v394_ = g_brandManager:getBrandByIndex(v390_.brandIndex)
				local v395_
				if v394_ == nil or v394_.name == "NONE" then
					v395_ = nil
				else
					v395_ = v394_.image
				end
				local v396_ = ""
				if v390_.isMod and v390_.dlcTitle == nil then
					v396_ = "Mod"
				elseif v390_.isMod and v390_.dlcTitle ~= nil then
					v396_ = v390_.dlcTitle .. " (Mod)"
				elseif v390_.dlcTitle ~= nil then
					v396_ = v390_.dlcTitle
				end
				local v397_ = self.items[v390_.brush.category.index][v390_.brush.tab.index]
				local v398_ = {
					["name"] = v390_.name,
					["brushClass"] = v391_,
					["brushParameters"] = v393_,
					["price"] = v390_.price,
					["imageFilename"] = v390_.imageFilename,
					["brandFilename"] = v395_,
					["modDlc"] = v396_,
					["storeItem"] = v390_,
					["displayItem"] = g_shopController:makeDisplayItem(v390_),
					["uniqueIndex"] = v385_ + 1
				}
				table.insert(v397_, v398_)
				v385_ = v385_ + 1
			end
		end
	end
	self:buildTerrainSculptBrushes((self:buildTerrainPaintBrushes(v385_)))
	self.categorySelector:reloadData()
end

-- Local values: landscapingIndex, paintingIndex, paintsTab, groundTypes, typeName, layerName, knownLayers, _, typeName, layer, title
function ConstructionScreen:buildTerrainPaintBrushes(numItems)
	local v401_ = g_storeManager:getConstructionCategoryByName("landscaping").index
	local v402_ = g_storeManager:getConstructionTabByName("painting", "landscaping").index
	local v403_ = self.items[v401_][v402_]
	local v404_ = {}
	for v405_, _ in pairs(g_groundTypeManager.groundTypeMappings) do
		table.insert(v404_, v405_)
	end
	table.sort(v404_)
	local v406_ = {}
	for _, v407_ in ipairs(v404_) do
		local v408_ = g_groundTypeManager:getTerrainLayerByType(v407_)
		local v409_ = g_groundTypeManager:getTerrainTitleByType(v407_)
		if not v406_[v408_] then
			local v410_ = {
				["name"] = g_i18n:convertText(v409_),
				["brushClass"] = ConstructionBrushPaint,
				["brushParameters"] = { v407_ },
				["price"] = 2,
				["imageFilename"] = nil,
				["brandFilename"] = nil,
				["modDlc"] = "",
				["terrainOverlayLayer"] = v408_,
				["uniqueIndex"] = numItems + 1
			}
			table.insert(v403_, v410_)
			numItems = numItems + 1
			v406_[v408_] = true
		end
	end
	return numItems
end

-- Local values: landscapingIndex, sculptingIndex, sculptTab
function ConstructionScreen:buildTerrainSculptBrushes(numItems)
	local v413_ = g_storeManager:getConstructionCategoryByName("landscaping").index
	local v414_ = g_storeManager:getConstructionTabByName("sculpting", "landscaping").index
	local v415_ = self.items[v413_][v414_]
	local v416_ = {
		["name"] = g_i18n:getText("construction_item_shift"),
		["brushClass"] = ConstructionBrushSculpt,
		["brushParameters"] = { ConstructionBrushSculpt.MODE.SHIFT },
		["price"] = 10,
		["imageFilename"] = "dataS/menu/construction/icon_shift.png",
		["uniqueIndex"] = numItems + 1
	}
	table.insert(v415_, v416_)
	local v417_ = {
		["name"] = g_i18n:getText("construction_item_level"),
		["brushClass"] = ConstructionBrushSculpt,
		["brushParameters"] = { ConstructionBrushSculpt.MODE.LEVEL },
		["price"] = 10,
		["imageFilename"] = "dataS/menu/construction/icon_level.png",
		["uniqueIndex"] = numItems + 2
	}
	table.insert(v415_, v417_)
	local v418_ = {
		["name"] = g_i18n:getText("construction_item_soften"),
		["brushClass"] = ConstructionBrushSculpt,
		["brushParameters"] = { ConstructionBrushSculpt.MODE.SOFTEN },
		["price"] = 10,
		["imageFilename"] = "dataS/menu/construction/icon_soften.png",
		["uniqueIndex"] = numItems + 3
	}
	table.insert(v415_, v418_)
	local v419_ = {
		["name"] = g_i18n:getText("construction_item_slope"),
		["brushClass"] = ConstructionBrushSculpt,
		["brushParameters"] = { ConstructionBrushSculpt.MODE.SLOPE },
		["price"] = 10,
		["imageFilename"] = "dataS/menu/construction/icon_slope.png",
		["uniqueIndex"] = numItems + 4
	}
	table.insert(v415_, v419_)
	return numItems + 4
end

-- Local values: i, dot, subCategoryTexts, index, subCategory, dot
function ConstructionScreen:setCurrentCategory(index, tabIndex)
	if self.currentCategory ~= index then
		self.categorySelector:setSelectedIndex(index)
		self.currentCategory = index
		self.subCategorySelector:setState(tabIndex or 1, true)
		for v423_, v424_ in pairs(self.subCategoryDotBox.elements) do
			v424_:delete()
			self.subCategoryDotBox.elements[v423_] = nil
		end
		local v425_ = {}
		for v_u_426_, v427_ in pairs(self.categories[index].tabs) do
			self.subCategoryDotTemplate:clone(self.subCategoryDotBox).getIsSelected = function()
				-- upvalues: (copy) self, (copy) v_u_426_
				return self.currentTab == v_u_426_
			end
			local v428_ = v427_.title
			table.insert(v425_, v428_)
		end
		self.subCategorySelector:setTexts(v425_)
		self.subCategoryDotBox:invalidateLayout()
		self:setBrush(self.selectorBrush, true)
		self:updateMenuState()
	end
end

function ConstructionScreen:setCurrentTab(index)
	self.currentTab = index == nil and 1 or index
	if #self.items[self.currentCategory][self.currentTab] == 0 then
		self:assignItemAttributeData(nil)
	else
		self.itemList:setSelectedIndex(1)
	end
	self:setBrush(self.selectorBrush, true)
	self:updateMenuState()
end

function ConstructionScreen:updateMenuState(brushChangedFrom)
	self.itemList:reloadData()
	self:updateMenuActionTexts()
end

-- Local values: i, element, name
function ConstructionScreen:buildCellDatabase()
	self.detailsTemplates = {}
	for v433_ = #self.attributesLayout.elements, 1, -1 do
		local v434_ = self.attributesLayout.elements[v433_]
		local v435_ = v434_.name
		self.detailsTemplates[v435_] = v434_:clone()
		self.detailsCache[v435_] = {}
	end
end

-- Local values: cell, cache
function ConstructionScreen:dequeueDetailsCell(name)
	if self.detailsTemplates[name] == nil then
		return nil
	end
	local v438_ = self.detailsCache[name]
	local v439_
	if #v438_ > 0 then
		v439_ = v438_[#v438_]
		v438_[#v438_] = nil
	else
		v439_ = self.detailsTemplates[name]:clone(self)
	end
	self.attributesLayout:addElement(v439_)
	return v439_
end

-- Local values: cache
function ConstructionScreen:queueDetailsCell(cell)
	local v442_ = self.detailsCache[cell.name]
	v442_[#v442_ + 1] = cell
	self.attributesLayout:removeElement(cell)
	cell:unlinkElement()
end
function ConstructionScreen.consoleCommandToggleUI()
	ConstructionScreen.uiHidden = not ConstructionScreen.uiHidden
end
