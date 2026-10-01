ConstructionScreen = {}
ConstructionScreen.CELL_NAME_DETAIL = "detailTemplate"
ConstructionScreen.CELL_NAME_FILL_TYPES = "fillTypesTemplate"
ConstructionScreen.INPUT_CONTEXT = "CONSTRUCTION_MENU"
local ConstructionScreen_mt = Class(ConstructionScreen, ScreenElement)
function ConstructionScreen.register()
	local constructionScreen = ConstructionScreen.new()
	g_gui:loadGui("dataS/gui/ConstructionScreen.xml", "ConstructionScreen", constructionScreen)
	if g_addCheatCommands then
		addConsoleCommand("gsConstructionScreenUIToggle", "Toggle construction screen UI", "consoleCommandToggleUI", ConstructionScreen)
	end
	return constructionScreen
end
function ConstructionScreen.new(target, custom_mt)
	local self = ScreenElement.new(target, custom_mt or ConstructionScreen_mt)
	self.isMouseMode = true
	self.camera = GuiTopDownCamera.new()
	self.cursor = GuiTopDownCursor.new()
	self.sound = ConstructionSound.new()
	self.brush = nil
	self.items = {}
	self.menuEvents = {}
	self.brushEvents = {}
	self.configEvents = {}
	self.marqueeBoxes = {}
	self.clonedElements = {}
	self.detailsCache = {}
	self.detailsTemplates = {}
	self.configItemCache = {}
	self.configItemCacheLarge = {}
	return self
end
function ConstructionScreen.createFromExistingGui(gui, guiName)
	local newGui = ConstructionScreen.new()
	g_gui.guis[guiName]:delete()
	g_gui.guis[guiName].target:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, newGui)
	return newGui
end
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
	for k, clone in pairs(self.clonedElements) do
		clone:delete()
		self.clonedElements[k] = nil
	end
	for k, clone in pairs(self.detailsTemplates) do
		clone:delete()
		self.detailsTemplates[k] = nil
	end
	for k, clone in pairs(self.subCategoryDotBox.elements) do
		clone:delete()
		self.subCategoryDotBox.elements[k] = nil
	end
	for k, cell in pairs(self.detailsCache) do
		for l, clone in pairs(cell) do
			clone:delete()
			self.detailsCache[k][l] = nil
		end
		self.detailsCache[k] = nil
	end
	for _, element in ipairs(self.configItemCache) do
		element:delete()
	end
	self.configItemCache = {}
	for _, element in ipairs(self.configItemCacheLarge) do
		element:delete()
	end
	self.configItemCacheLarge = {}
	self.subCategoryDotTemplate:delete()
	self.configurationItemTemplate:delete()
	self.configurationItemTemplateLarge:delete()
	ConstructionScreen:superClass().delete(self)
end
function ConstructionScreen:onOpen()
	ConstructionScreen:superClass().onOpen(self)
	g_currentMission.lastConstructionScreenOpenTime = g_time
	g_inputBinding:setContext(ConstructionScreen.INPUT_CONTEXT)
	local viewPortStartX = self.menuBox.absPosition[1] + self.menuBox.absSize[1]
	self.viewPortStartX = viewPortStartX
	self.camera:setTerrainRootNode(g_terrainNode)
	self.camera:setEdgeScrollingOffset(viewPortStartX, 0, 1, 1)
	self.camera:activate()
	self.cursor:activate()
	self.originalSafeFrameOffsetX = g_safeFrameOffsetX
	g_safeFrameOffsetX = viewPortStartX + g_safeFrameOffsetX
	if self.selectorBrush == nil then
		local class = g_constructionBrushTypeManager:getClassObjectByTypeName("select")
		self.selectorBrush = class.new(nil, self.cursor)
	end
	self:setBrush(self.selectorBrush, true)
	if self.destructBrush == nil then
		local class = g_constructionBrushTypeManager:getClassObjectByTypeName("destruct")
		self.destructBrush = class.new(nil, self.cursor)
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
		self.wasFirstPerson = false
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
	if not self.isMouseMode or not self.isMouseInMenu then
		self.cursor:setCameraRay(self.camera:getPickRay())
	else
		self.cursor:setCameraRay(nil)
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
function ConstructionScreen:setBrush(brush, skipMenuUpdate)
	if brush == self.brush then
		return
	else
		local previousBrush = self.brush
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
		else
			if self.brush ~= nil then
				self:registerMenuActionEvents(false)
			end
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
			if previousBrush ~= nil and self.brush:class() == previousBrush:class() then
				self.brush:copyState(previousBrush)
			end
			self:registerBrushActionEvents()
		end
		if not skipMenuUpdate then
			self:updateMenuState(previousBrush)
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
	if self.configurations ~= nil then
		return
	else
		self.cursor:mouseEvent(posX, posY, isDown, isUp, button)
	end
end
function ConstructionScreen:draw()
	if ConstructionScreen.uiHidden then
		return
	else
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
function ConstructionScreen:registerMenuActionEvents(hasMenuButtons)
	self.menuEvents = {}
	local _ = nil
	local eventId = nil
	_, eventId = g_inputBinding:registerActionEvent(InputAction.MENU_ACCEPT, self, self.onButtonMenuAccept, false, true, false, true)
	g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_VERY_LOW)
	g_inputBinding:setActionEventTextVisibility(eventId, false)
	self.acceptButtonEvent = eventId
	_, eventId = g_inputBinding:registerActionEvent(InputAction.MENU_BACK, self, self.onButtonMenuBack, false, true, false, true)
	g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_VERY_LOW)
	self.backButtonEvent = eventId
	table.insert(self.menuEvents, eventId)
	_, eventId = g_inputBinding:registerActionEvent(InputAction.PAUSE, g_localPlayer.inputComponent, g_localPlayer.inputComponent.onInputPause, false, true, false, true)
	g_inputBinding:setActionEventTextVisibility(eventId, false)
	_, eventId = g_inputBinding:registerActionEvent(InputAction.TOGGLE_HELP_TEXT, g_localPlayer.inputComponent, g_localPlayer.inputComponent.onInputToggleHelpText, false, true, false, true)
	g_inputBinding:setActionEventTextVisibility(eventId, false)
	if hasMenuButtons then
		_, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_UP_DOWN, self, self.onMenuUpDown, false, true, true, true)
		g_inputBinding:setActionEventTextVisibility(eventId, false)
		table.insert(self.menuEvents, eventId)
		_, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_LEFT_RIGHT, self, self.onMenuLeftRight, false, true, true, true)
		g_inputBinding:setActionEventTextVisibility(eventId, false)
		table.insert(self.menuEvents, eventId)
		_, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_UP_DOWN, self, self.onReleaseUpDown, true, false, false, true)
		g_inputBinding:setActionEventTextVisibility(eventId, false)
		table.insert(self.menuEvents, eventId)
		_, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_LEFT_RIGHT, self, self.onReleaseLeftRight, true, false, false, true)
		g_inputBinding:setActionEventTextVisibility(eventId, false)
		table.insert(self.menuEvents, eventId)
		_, eventId = g_inputBinding:registerActionEvent(InputAction.MENU_PAGE_PREV, self, self.onMenuPagePrev, false, true, false, true)
		g_inputBinding:setActionEventTextVisibility(eventId, false)
		table.insert(self.menuEvents, eventId)
		_, eventId = g_inputBinding:registerActionEvent(InputAction.MENU_PAGE_NEXT, self, self.onMenuPageNext, false, true, false, true)
		g_inputBinding:setActionEventTextVisibility(eventId, false)
		table.insert(self.menuEvents, eventId)
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
function ConstructionScreen:removeMenuActionEvents()
	for _, event in ipairs(self.menuEvents) do
		g_inputBinding:removeActionEvent(event)
	end
end
function ConstructionScreen:onButtonMenuAccept()
	if self.isMouseMode or self.brush == self.selectorBrush and self.selectorBrush.lastPlaceable == nil or self.configurations ~= nil then
		self.dragIsLocked = true
		g_gui:notifyControls("MENU_ACCEPT")
		return
	end
	self:onButtonPrimary()
end
function ConstructionScreen:onButtonMenuBack()
	if self.brush:canCancel() then
		self.brush:cancel()
	elseif self.brush == self.destructBrush then
		self.destructMode = false
		self:setBrush(self.previousBrush)
	elseif self.configurations ~= nil then
		self:onShowConfigs()
	elseif not self.brush.isSelector then
		self:setBrush(self.selectorBrush)
	else
		self:changeScreen(nil)
	end
end
function ConstructionScreen:onCategoryChanged(_, _, isLeftButton)
	local oldCategory = self.currentCategory
	oldCategory = isLeftButton and oldCategory - 1 or oldCategory + 1
	if oldCategory <= 0 then
		oldCategory = #self.categories
	elseif #self.categories < oldCategory then
		oldCategory = 1
	end
	if oldCategory ~= self.currentCategory then
		self:setCurrentCategory(oldCategory)
	end
end
function ConstructionScreen:onSubCategoryChanged(index)
	self:setCurrentTab(index)
end
function ConstructionScreen:registerBrushActionEvents()
	local _ = nil
	local eventId = nil
	local brush = self.brush
	if brush == nil then
		return
	else
		self.brushEvents = {}
		if brush.supportsPrimaryButton then
			if brush.supportsPrimaryDragging then
				_, eventId = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_PRIMARY, self, self.onButtonPrimaryDrag, true, true, true, true)
				table.insert(self.brushEvents, eventId)
				self.primaryBrushEvent = eventId
			else
				_, eventId = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_PRIMARY, self, self.onButtonPrimary, false, true, false, true)
				table.insert(self.brushEvents, eventId)
				self.primaryBrushEvent = eventId
			end
			g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_VERY_HIGH)
		end
		if brush.supportsSecondaryButton then
			if brush.supportsSecondaryDragging then
				_, eventId = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_SECONDARY, self, self.onButtonSecondaryDrag, true, true, true, true)
				table.insert(self.brushEvents, eventId)
				self.secondaryBrushEvent = eventId
			else
				_, eventId = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_SECONDARY, self, self.onButtonSecondary, false, true, false, true)
				table.insert(self.brushEvents, eventId)
				self.secondaryBrushEvent = eventId
			end
			g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_VERY_HIGH)
		end
		if brush.supportsTertiaryButton then
			_, self.tertiaryBrushEvent = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_TERTIARY, self, self.onButtonTertiary, false, true, false, true)
			g_inputBinding:setActionEventTextPriority(self.tertiaryBrushEvent, GS_PRIO_HIGH)
			table.insert(self.brushEvents, self.tertiaryBrushEvent)
		end
		if brush.supportsFourthButton then
			_, self.fourthBrushEvent = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_FOURTH, self, self.onButtonFourth, false, true, false, true)
			g_inputBinding:setActionEventTextPriority(self.fourthBrushEvent, GS_PRIO_HIGH)
			table.insert(self.brushEvents, self.fourthBrushEvent)
		end
		if brush.placeableHasConfigs then
			_, self.showConfigsEvent = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_SHOW_CONFIGS, self, self.onShowConfigs, false, true, false, true)
			g_inputBinding:setActionEventText(self.showConfigsEvent, g_i18n:getText("input_CONSTRUCTION_SHOW_CONFIGS"))
			g_inputBinding:setActionEventTextPriority(self.showConfigsEvent, GS_PRIO_HIGH)
			table.insert(self.brushEvents, self.showConfigsEvent)
		end
		if brush.supportsPrimaryAxis then
			_, self.primaryBrushAxisEvent = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_ACTION_PRIMARY, self, self.onAxisPrimary, false, not brush.primaryAxisIsContinuous, brush.primaryAxisIsContinuous, true)
			g_inputBinding:setActionEventTextPriority(self.primaryBrushAxisEvent, GS_PRIO_HIGH)
			table.insert(self.brushEvents, self.primaryBrushAxisEvent)
		end
		if brush.supportsSecondaryAxis then
			_, self.secondaryBrushAxisEvent = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_ACTION_SECONDARY, self, self.onAxisSecondary, false, not brush.secondaryAxisIsContinuous, brush.secondaryAxisIsContinuous, true)
			g_inputBinding:setActionEventTextPriority(self.secondaryBrushAxisEvent, GS_PRIO_HIGH)
			table.insert(self.brushEvents, self.secondaryBrushAxisEvent)
		end
		if brush.supportsSnapping then
			_, self.snappingBrushEvent = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_SNAPPING, self, self.onButtonSnapping, false, true, false, true)
			g_inputBinding:setActionEventTextPriority(self.snappingBrushEvent, GS_PRIO_HIGH)
			table.insert(self.brushEvents, self.snappingBrushEvent)
		end
	end
end
function ConstructionScreen:updateBrushActionTexts()
	if self.primaryBrushEvent ~= nil then
		local text = self.brush:getButtonPrimaryText()
		if text ~= nil then
			g_inputBinding:setActionEventText(self.primaryBrushEvent, g_i18n:convertText(text))
		end
		g_inputBinding:setActionEventTextVisibility(self.primaryBrushEvent, text ~= nil)
	end
	if self.secondaryBrushEvent ~= nil then
		local text = self.brush:getButtonSecondaryText()
		if text ~= nil then
			g_inputBinding:setActionEventText(self.secondaryBrushEvent, g_i18n:convertText(text))
		end
		g_inputBinding:setActionEventTextVisibility(self.secondaryBrushEvent, text ~= nil)
	end
	if self.tertiaryBrushEvent ~= nil then
		local text = self.brush:getButtonTertiaryText()
		if text ~= nil then
			g_inputBinding:setActionEventText(self.tertiaryBrushEvent, g_i18n:convertText(text))
		end
		g_inputBinding:setActionEventTextVisibility(self.tertiaryBrushEvent, text ~= nil)
	end
	if self.fourthBrushEvent ~= nil then
		local text = self.brush:getButtonFourthText()
		if text ~= nil then
			g_inputBinding:setActionEventText(self.fourthBrushEvent, g_i18n:convertText(text))
		end
		g_inputBinding:setActionEventTextVisibility(self.fourthBrushEvent, text ~= nil)
	end
	if self.primaryBrushAxisEvent ~= nil then
		local text = self.brush:getAxisPrimaryText()
		if text ~= nil then
			g_inputBinding:setActionEventText(self.primaryBrushAxisEvent, g_i18n:convertText(text))
		end
		g_inputBinding:setActionEventTextVisibility(self.primaryBrushAxisEvent, text ~= nil)
	end
	if self.secondaryBrushAxisEvent ~= nil then
		local text = self.brush:getAxisSecondaryText()
		if text ~= nil then
			g_inputBinding:setActionEventText(self.secondaryBrushAxisEvent, g_i18n:convertText(text))
		end
		g_inputBinding:setActionEventTextVisibility(self.secondaryBrushAxisEvent, text ~= nil)
	end
	if self.snappingBrushEvent ~= nil then
		local text = self.brush:getButtonSnappingText()
		if text ~= nil then
			g_inputBinding:setActionEventText(self.snappingBrushEvent, g_i18n:convertText(text))
		end
		g_inputBinding:setActionEventTextVisibility(self.snappingBrushEvent, text ~= nil)
	end
end
function ConstructionScreen:removeBrushActionEvents()
	for _, event in ipairs(self.brushEvents) do
		g_inputBinding:removeActionEvent(event)
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
function ConstructionScreen:onButtonPrimaryDrag(_, inputValue, _, isAnalog, isMouse)
	if not self.isMouseInMenu then
		local isDown = inputValue == 1 and self.previousPrimaryDragValue ~= 1
		local isDrag = inputValue == 1 and self.previousPrimaryDragValue == 1
		local isUp = inputValue == 0
		self.previousPrimaryDragValue = inputValue
		if self.dragIsLocked then
			if isUp then
				self.dragIsLocked = false
			end
		else
			self.brush:onButtonPrimary(isDown, isDrag, isUp)
		end
	end
end
function ConstructionScreen:onButtonSecondary(_, inputValue, _, isAnalog, isMouse)
	if not self.isMouseInMenu then
		self.brush:onButtonSecondary()
	end
end
function ConstructionScreen:onButtonSecondaryDrag(_, inputValue, _, isAnalog, isMouse)
	if not self.isMouseInMenu then
		local isDown = inputValue == 1 and self.previousSecondaryDragValue ~= 1
		local isDrag = inputValue == 1 and self.previousSecondaryDragValue == 1
		local isUp = inputValue == 0
		self.previousSecondaryDragValue = inputValue
		self.brush:onButtonSecondary(isDown, isDrag, isUp)
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
function ConstructionScreen:onShowConfigs()
	if self.configsBox:getIsVisible() then
		self.configsBox:setVisible(false)
		self.listBox:setVisible(true)
		self:registerBrushActionEvents()
		self:updateBrushActionTexts()
		self:updateMenuActionTexts()
		for _, event in ipairs(self.configEvents) do
			g_inputBinding:removeActionEvent(event)
		end
		self.cursor:setRotationEnabled(self.cursorRotationEnabled or false)
		self.configurations = nil
		if 0 < self.itemList:getItemCount() then
			FocusManager:setFocus(self.itemList)
		else
			FocusManager:setFocus(self.subCategorySelector)
		end
		self.categorySelector:setDisabled(false)
	else
		self.configsBox:setVisible(true)
		self.listBox:setVisible(false)
		self:removeBrushActionEvents()
		local _, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_UP_DOWN, self, self.onMenuUpDown, false, true, true, true)
		g_inputBinding:setActionEventTextVisibility(eventId, false)
		table.insert(self.configEvents, eventId)
		_, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_LEFT_RIGHT, self, self.onMenuLeftRight, false, true, true, true)
		g_inputBinding:setActionEventTextVisibility(eventId, false)
		table.insert(self.configEvents, eventId)
		_, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_UP_DOWN, self, self.onReleaseUpDown, true, false, false, true)
		g_inputBinding:setActionEventTextVisibility(eventId, false)
		table.insert(self.configEvents, eventId)
		_, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_LEFT_RIGHT, self, self.onReleaseLeftRight, true, false, false, true)
		g_inputBinding:setActionEventTextVisibility(eventId, false)
		table.insert(self.configEvents, eventId)
		self.cursorRotationEnabled = self.cursor.rotationEnabled
		self.cursor:setRotationEnabled(false)
		local storeItem = self.brush.storeItem
		local configurations = {}
		if storeItem.defaultConfigurationIds ~= nil then
			for configName, index in pairs(storeItem.defaultConfigurationIds) do
				configurations[configName] = index
			end
		end
		if self.brush.configurations ~= nil then
			for configName, index in pairs(self.brush.configurations) do
				configurations[configName] = index
			end
		end
		self.needsRefocus = true
		self.configurations = configurations
		self.configurationData = {}
		self:processStoreItemConfigurations(storeItem)
		self:updateConfigOptionsDisplay(storeItem)
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
function ConstructionScreen:updateConfigurationButton()
	local visible = self.focusedButtonElement ~= nil or self.focusedColorElement ~= nil
	self.configButton:setVisible(visible)
	self.buttonsPanel:invalidateLayout()
end
function ConstructionScreen:onClickConfigAction()
	if self.focusedColorElement ~= nil then
		self.focusedColorElement:onFocusActivate()
	else
		if self.focusedButtonElement ~= nil then
			self.focusedButtonElement:onFocusActivate()
		end
	end
end
function ConstructionScreen:getNumberOfItemsInSection(list, section)
	if list == self.categorySelector then
		return #self.categories
	end
	if self.currentCategory == nil or self.currentTab == nil then
		return 0
	end
	local items = self.items[self.currentCategory][self.currentTab]
	if items == nil then
		return 0
	else
		return #items
	end
end
function ConstructionScreen:populateCellForItemInSection(list, section, index, cell)
	if list == self.categorySelector then
		local category = self.categories[index]
		local tabButton = cell:getAttribute("tabButton")
		tabButton:setImageFilename(nil, category.iconFilename)
		tabButton:setImageUVs(nil, category.iconUVs)
		tabButton:setImageSlice(nil, category.iconSliceId)
		function tabButton.onClickCallback()
			self:setCurrentCategory(index)
		end
	else
		local item = self.items[self.currentCategory][self.currentTab][index]
		cell:getAttribute("price"):setValue(g_i18n:formatMoney(item.price, 0, true, true))
		cell:getAttribute("terrainLayer"):setVisible(item.terrainOverlayLayer ~= nil)
		cell:getAttribute("icon"):setVisible(item.imageFilename ~= nil)
		if item.imageFilename ~= nil then
			cell:getAttribute("icon"):setImageFilename(item.imageFilename)
		else
			if item.terrainOverlayLayer ~= nil then
				cell:getAttribute("terrainLayer"):setTerrainLayer(g_terrainNode, item.terrainOverlayLayer)
			end
		end
	end
end
function ConstructionScreen:onListSelectionChanged(list, section, index)
	if g_gui.currentlyReloading then
		return
	else
		if list == self.itemList then
			local selectedBrush = self.items[self.currentCategory][self.currentTab][index]
			if selectedBrush == nil then
				self:assignItemAttributeData(nil)
				return
			end
			self.lastSelectionIndex = index
			self:assignItemAttributeData(selectedBrush)
		end
	end
end
function ConstructionScreen:onListHighlightChanged(list, section, index)
	if g_gui.currentlyReloading then
		return
	else
		if list == self.itemList then
			index = index or self.lastSelectionIndex
			local selectedBrush = self.items[self.currentCategory][self.currentTab][index]
			if selectedBrush == nil then
				self:assignItemAttributeData(nil)
				return
			end
			self:assignItemAttributeData(selectedBrush)
		end
	end
end
function ConstructionScreen:onClickItem()
	local item = self.items[self.currentCategory][self.currentTab][self.itemList.selectedIndex]
	local brush = item.brushClass.new(nil, self.cursor)
	if item.brushParameters ~= nil then
		brush:setStoreItem(item.storeItem)
		brush:setParameters(unpack(item.brushParameters))
		brush.uniqueIndex = item.uniqueIndex
	end
	self.destructMode = false
	self:setBrush(brush, true)
end
function ConstructionScreen:refreshDetails()
	self:onListSelectionChanged(self.itemList, 1, self.itemList.selectedIndex)
end
function ConstructionScreen:assignItemAttributeData(selectedBrush)
	local layoutsToInvalidate = {}
	for k, clone in pairs(self.clonedElements) do
		if layoutsToInvalidate[clone.parent] == nil then
			layoutsToInvalidate[clone.parent] = true
		end
		clone:delete()
		self.clonedElements[k] = nil
	end
	for layout, _ in pairs(layoutsToInvalidate) do
		layout:invalidateLayout()
	end
	for k, _ in pairs(self.marqueeBoxes) do
		self.marqueeBoxes[k] = nil
	end
	local displayItem = nil
	if selectedBrush ~= nil then
		self.itemDetailsName:setText(selectedBrush.name)
		displayItem = selectedBrush.displayItem
	end
	self.itemDetailsName:setVisible(selectedBrush ~= nil)
	self.attributesLayout:setVisible(false)
	if displayItem == nil then
		self.itemDetailsBrandImage:setVisible(false)
		self.itemDetailsModName:setVisible(false)
		self.itemDetailsDescription:setVisible(false)
	else
		for i = #self.attributesLayout.elements, 1, -1 do
			self:queueDetailsCell(self.attributesLayout.elements[i])
		end
		self:assignItemTextData(displayItem)
		self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_FILL_TYPES, displayItem.fillTypeIconFilenames)
		self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_FILL_TYPES, displayItem.foodFillTypeIconFilenames)
		self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_INPUT, displayItem.prodPointInputFillTypeIconFilenames)
		self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_OUTPUT, displayItem.prodPointOutputFillTypeIconFilenames)
		self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_INPUT, displayItem.sellingStationFillTypesIconFilenames)
		self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_OUTPUT, displayItem.buyingStationFillTypesIconFilenames)
		self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_FILL_TYPES, displayItem.objectStorageFillTypesIconFilenames)
		local brand = nil
		local modName = nil
		local description = nil
		if displayItem.storeItem ~= nil then
			brand = g_brandManager:getBrandByIndex(displayItem.storeItem.brandIndex)
			if brand ~= nil then
				self.itemDetailsBrandImage:setImageFilename(brand.image)
			end
			if displayItem.storeItem.isMod then
				if displayItem.storeItem.dlcTitle == nil then
					modName = "Mod"
				elseif displayItem.storeItem.isMod then
					if displayItem.storeItem.dlcTitle ~= nil then
						modName = displayItem.storeItem.dlcTitle .. " (Mod)"
					elseif displayItem.storeItem.dlcTitle ~= nil then
						modName = displayItem.storeItem.dlcTitle
					end
				end
			end
			self.itemDetailsModName:setText(modName or "")
			description = displayItem.functionText
			self.itemDetailsDescription:setText(description)
		end
		self.itemDetailsBrandImage:setVisible(brand ~= nil)
		self.itemDetailsModName:setVisible(false)
		self.itemDetailsDescription:setVisible(false)
		self.descriptionLayout:invalidateLayout()
		self.attributesLayout:invalidateLayout()
	end
end
function ConstructionScreen:assignItemTextData(displayItem)
	local numAttributesUsed = 0
	if displayItem ~= nil and displayItem.attributeValues ~= nil then
		for i, value in pairs(displayItem.attributeValues) do
			local cell = self:dequeueDetailsCell(ConstructionScreen.CELL_NAME_DETAIL)
			local icon = cell:getDescendantByName("icon")
			local text = cell:getDescendantByName("text")
			local profile = displayItem.attributeIconProfiles[i]
			if profile ~= nil and profile ~= "" then
				if type(value) == "string" then
					local slotCount = string.format("(%0d / %0d)", g_currentMission.slotSystem.slotUsage, g_currentMission.slotSystem.slotLimit)
					local value = value:gsub("%$SLOTS%$", slotCount)
				end
				text:setText(value)
				icon:applyProfile(profile)
				numAttributesUsed = numAttributesUsed + 1
			end
			cell:setSize(icon.absSize[1] + icon.margin[1] + text.absSize[1], nil)
		end
	end
end
function ConstructionScreen:assignItemFillTypesData(baseIconProfile, iconFilenames)
	if iconFilenames ~= nil and 0 < #iconFilenames then
		local totalWidth = 0
		local cell = self:dequeueDetailsCell(ConstructionScreen.CELL_NAME_FILL_TYPES)
		local cellIcon = cell:getDescendantByName("icon")
		local iconsLayout = cell:getDescendantByName("iconsLayout")
		cellIcon:applyProfile(baseIconProfile)
		for _, iconFilename in pairs(iconFilenames) do
			local icon = self.fruitIconTemplate:clone(iconsLayout)
			icon:setVisible(true)
			table.insert(self.clonedElements, icon)
			icon:applyProfile(ShopItemsFrame.PROFILE.ICON_FRUIT_TYPE)
			icon:setImageFilename(iconFilename)
			totalWidth = totalWidth + icon.absSize[1] + icon.margin[1] + icon.margin[3]
		end
		local maxWidth = self.attributesLayout.absSize[1] * 0.91
		local parentSize = math.min(maxWidth, totalWidth)
		local iconsLayoutSize = parentSize + cellIcon.absSize[1] + cellIcon.margin[1]
		iconsLayout:setSize(totalWidth, nil)
		iconsLayout:setPosition(0, nil)
		iconsLayout.parent:setSize(parentSize, nil)
		cell:setSize(iconsLayoutSize, nil)
		iconsLayout:invalidateLayout()
		if iconsLayoutSize < totalWidth then
			self.marqueeBoxes[iconsLayout] = 0
			return
		end
		self.marqueeBoxes[iconsLayout] = nil
	end
end
function ConstructionScreen:updateMarqueeAnimation(dt)
	for box, time in pairs(self.marqueeBoxes) do
		local contentWidth = box.absSize[1]
		local visibleWidth = box.parent.absSize[1]
		local scrollAmount = contentWidth - visibleWidth
		local scrollLengthFactor = contentWidth / visibleWidth
		local scrollDuration = 5000 * scrollLengthFactor
		local time = time + dt
		if scrollDuration <= time then
			time = -scrollDuration
		end
		local alpha = MathUtil.smoothstep(0.1, 0.9, math.abs(time) / scrollDuration)
		local offset = scrollAmount * alpha
		box:setPosition(-offset)
		self.marqueeBoxes[box] = time
	end
end
function ConstructionScreen:onSlotUsageChanged()
	self:refreshDetails()
end
function ConstructionScreen:processStoreItemConfigurations(placeable)
	self.configSelection = { title = g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.CONFIGURATION_LABEL), texts = {}, prices = {}, options = {} }
	self.currentConfigSet = 1
	local configSets = placeable.configurationSets
	if placeable.configurationSets == nil or #placeable.configurationSets == 0 then
		local defaultSet = { name = "", configurations = {}, isDefault = true }
		configSets = { defaultSet }
	end
	if placeable.configurations ~= nil then
		for i, configSet in ipairs(configSets) do
			if configSet.isDefault then
				self.currentConfigSet = i
			end
			if configSet.overwrittenTitle ~= nil then
				self.configSelection.title = configSet.overwrittenTitle
			end
			local price = 0
			for name, index in pairs(configSet.configurations) do
				price = price + placeable.configurations[name][index].price
			end
			table.insert(self.configSelection.prices, price)
			table.insert(self.configSelection.texts, configSet.name)
			local setOptions = self:processStoreItemConfigurationSet(placeable, configSet)
			table.insert(self.configSelection.options, setOptions)
		end
		for name, index in pairs(configSets[self.currentConfigSet].configurations) do
			self.configurations[name] = index
		end
		self.colorPickers = {}
		local colorPickerIndex = 1
		local configurations = g_placeableConfigurationManager:getSortedConfigurationTypes()
		for i = 1, #configurations do
			local configName = configurations[i]
			local configItems = placeable.configurations[configName]
			if placeable.configurations[configName] == nil then
				continue
			end
			local isColor = g_placeableConfigurationManager:getConfigurationSelectorType(configName) == ConfigurationUtil.SELECTOR_COLOR
			if 1 < #configItems and isColor then
				self:processStoreItemColorOption(placeable, configName, configItems, colorPickerIndex)
				colorPickerIndex = colorPickerIndex + 1
			end
		end
		self.displayableColorCount = colorPickerIndex - 1
	else
		table.insert(self.configSelection.options, {})
		self.displayableColorCount = 0
	end
end
function ConstructionScreen:processStoreItemConfigurationSet(storeItem, configSet)
	local options = {}
	local configurationTypes = g_placeableConfigurationManager:getSortedConfigurationTypes()
	for _, configName in ipairs(configurationTypes) do
		if g_placeableConfigurationManager:getConfigurationSelectorType(configName) == ConfigurationUtil.SELECTOR_COLOR then
			continue
		end
		local items = storeItem.configurations[configName]
		if items == nil then
			continue
		end
		if 1 < #items and configSet.configurations[configName] == nil then
			local option = self:processStoreItemConfigurationOption(storeItem, configName, items)
			table.insert(options, option)
		end
	end
	return options
end
function ConstructionScreen:processStoreItemConfigurationOption(storeItem, configName, configItems)
	local configOption = { name = configName }
	configOption.title = g_placeableConfigurationManager:getConfigurationAttribute(configName, "title")
	configOption.texts = {}
	configOption.icons = {}
	configOption.options = {}
	configOption.defaultIndex = 1
	local initialIndex = 1
	local overwrittenTitle = nil
	local hasValidIcons = false
	local index = 1
	for _, item in ipairs(configItems) do
		if item.isDefault then
			initialIndex = index
			configOption.defaultIndex = index
		end
		local isSelectable = item.isSelectable
		for _, otherConfigItems in pairs(storeItem.configurations) do
			for _, configItem in pairs(otherConfigItems) do
				if configItem.dependentConfigurations == nil then
					continue
				end
				for _, dependentConfiguration in pairs(configItem.dependentConfigurations) do
					if dependentConfiguration.name == configName then
						return
					end
				end
			end
		end
		overwrittenTitle = overwrittenTitle or item.overwrittenTitle
		if isSelectable then
			table.insert(configOption.texts, item.name)
			table.insert(configOption.options, item)
			if item.brandIndex ~= nil then
				local iconFilename = g_brandManager:getBrandIconByIndex(item.brandIndex)
				if iconFilename ~= nil then
					table.insert(configOption.icons, iconFilename)
					hasValidIcons = true
				end
			end
			if #configOption.icons ~= #configOption.texts then
				table.insert(configOption.icons, item.name)
			end
			index = index + 1
		end
	end
	configOption.defaultIndex = initialIndex
	configOption.title = overwrittenTitle or configOption.title
	if not hasValidIcons then
		configOption.icons = nil
	end
	if #configOption.options <= 1 then
		return
	else
		return configOption
	end
end
function ConstructionScreen:processStoreItemColorOption(storeItem, configName, colorItems, colorPickerIndex)
	local overwrittenTitle = nil
	for _, item in ipairs(colorItems) do
		overwrittenTitle = overwrittenTitle or item.overwrittenTitle
	end
	table.insert(self.colorPickers, { configName = configName, colorItems = colorItems, title = overwrittenTitle or g_placeableConfigurationManager:getConfigurationAttribute(configName, "title") })
end
function ConstructionScreen:updateConfigOptionsData(storeItem)
	local displayableOptionCount = 0
	local count = 0
	for i = #self.configurationLayout.elements, 1, -1 do
		local item = self.configurationLayout.elements[i]
		item:setVisible(false)
		FocusManager:removeElement(item)
		item:unlinkElement()
		if item.isLargeConfigItem then
			table.insert(self.configItemCacheLarge, item)
		else
			table.insert(self.configItemCache, item)
		end
	end
	self.focusableElementForScroll = nil
	if 1 < #self.configSelection.options then
		displayableOptionCount = displayableOptionCount + 1
		count = 1
		self:updateConfigSetOptionElement(1, storeItem)
	end
	local optionData = self.configSelection.options[self.currentConfigSet]
	for _, option in ipairs(optionData) do
		displayableOptionCount = displayableOptionCount + 1
		count = count + 1
		self:updateConfigOptionElement(count, option, storeItem)
	end
	self.colorElements = {}
	if 0 < self.displayableColorCount then
		for i, option in ipairs(self.colorPickers) do
			local itemsToDisplay = 0
			local hasCustomColorSupport = false
			for j = 1, #option.colorItems do
				if option.colorItems[j].isSelectable ~= false then
					itemsToDisplay = itemsToDisplay + 1
				end
				if option.colorItems[j].isCustomColor then
					hasCustomColorSupport = true
				end
			end
			if 1 < itemsToDisplay then
				local listElement = self:getOrCreateConfigItem("color")
				local colorElement = listElement:getDescendantByName("color")
				self.colorElements[i] = colorElement
				local colorItems = option.colorItems
				function colorElement.onClickCallback(sourceElement)
					local configIndex = self.configurations[option.configName]
					local colorItem = colorItems[configIndex]
					local color = colorItem.color
					local materialTemplateName = colorItem.materialTemplateName
					local data = self.configurationData[option.configName]
					if data ~= nil and data[configIndex] ~= nil then
						color = data[configIndex].color or color
						materialTemplateName = data[configIndex].materialTemplateName or materialTemplateName
					end
					g_inputBinding:setShowMouseCursor(true)
					ColorPickerDialog.show(self.onPickColor, self, { configName = option.configName, colorOptionIndex = i }, colorItems, nil, materialTemplateName, color, hasCustomColorSupport, true, true)
				end
				local defaultColorIndex = self.configurations[option.configName] or self:getDefaultConfigurationColorIndex(option.configName, colorItems)
				self:onPickColor(defaultColorIndex, { colorOptionIndex = i, configName = option.configName }, nil, true)
				listElement:getDescendantByName("title"):setText(option.title)
				count = count + 1
			end
		end
	end
	self.displayableOptionCount = displayableOptionCount
	return count
end
function ConstructionScreen:updateConfigOptionsDisplay(storeItem)
	local current = FocusManager.currentGui
	FocusManager:setGui("ConstructionScreen")
	local num = self:updateConfigOptionsData(storeItem)
	self.startClipper:setVisible(0 < num)
	self.configSlider.parent:setVisible(0 < num)
	self.configurationLayout:invalidateLayout()
	FocusManager:setGui(current)
	if self.needsRefocus then
		self:selectFirstConfig()
		self.needsRefocus = false
	end
end
function ConstructionScreen:updateConfigSetOptionElement(configElementIndex, storeItem)
	local isYesNoOption = false
	if 1 < #storeItem.configurationSets then
		isYesNoOption = storeItem.configurationSets[1].isYesNoOption
	end
	local listElement = self:getOrCreateConfigItem(isYesNoOption and "yesNoOption" or "option")
	local optionElement = nil
	if isYesNoOption then
		optionElement = listElement:getDescendantByName("yesNoOption")
		optionElement:setIsChecked(self.currentConfigSet ~= 1, true)
	else
		optionElement = listElement:getDescendantByName("option")
		optionElement:setState(self.currentConfigSet)
	end
	optionElement:setTexts(self.configSelection.texts)
	optionElement:setDisabled(false)
	function optionElement.onClickCallback(_, configSetIndex)
		for name, _ in pairs(storeItem.configurationSets[self.currentConfigSet].configurations) do
			self.configurations[name] = ConfigurationUtil.getDefaultConfigIdFromItems(storeItem.configurations[name])
		end
		for name, index in pairs(storeItem.configurationSets[configSetIndex].configurations) do
			self.configurations[name] = index
		end
		self.currentConfigSet = configSetIndex
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CONFIG_WRENCH)
		self:selectFirstConfig()
	end
	listElement:getDescendantByName("title"):setText(self.configSelection.title)
	local price = self.configSelection.prices[self.currentConfigSet]
	listElement:getDescendantByName("price"):setText("+" .. g_i18n:formatMoney(price))
end
function ConstructionScreen:updateConfigOptionElement(configElementIndex, option, storeItem)
	local hasIcons = option.icons ~= nil
	local hasText = not hasIcons
	local isYesNoOption = false
	if 1 < #option.options then
		isYesNoOption = option.options[1].isYesNoOption
		if isYesNoOption then
			hasIcons = false
			hasText = false
		end
	end
	local listElement = nil
	if hasIcons then
		listElement = self:getOrCreateLargeConfigItem("option")
	elseif hasText then
		listElement = self:getOrCreateConfigItem("option")
	elseif isYesNoOption then
		listElement = self:getOrCreateConfigItem("yesNoOption")
	end
	local optionElement = listElement:getDescendantByName(isYesNoOption and "yesNoOption" or "option")
	optionElement:setVisible(true)
	optionElement:setDisabled(true)
	if hasIcons then
		optionElement:setIcons(option.icons)
	elseif hasText then
		optionElement:setTexts(option.texts)
	elseif isYesNoOption then
		optionElement:setTexts(option.texts)
	end
	local priceElement = listElement:getDescendantByName("price")
	local configName = option.name
	local configIndex = 0
	for i, item in pairs(option.options) do
		if item.index == self.configurations[configName] then
			configIndex = i
			break
		end
	end
	if configIndex == 0 or option.options[configIndex] == nil then
		configIndex = option.defaultIndex
	end
	if isYesNoOption then
		optionElement:setIsChecked(configIndex ~= 1, true)
	else
		optionElement:setState(configIndex)
	end
	function optionElement.onClickCallback(_, optionIndex)
		if self.brush.placeable == nil then
			return
		else
			local selectedConfigIndex = option.options[optionIndex].index
			self:setConfigPrice(configName, selectedConfigIndex, priceElement)
			self.configurations[configName] = selectedConfigIndex
			self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CONFIG_WRENCH)
			self:loadCurrentConfiguration(storeItem)
		end
	end
	self.configurations[configName] = option.options[configIndex].index
	listElement:getDescendantByName("title"):setText(option.title)
	self:setConfigPrice(configName, option.options[configIndex].index, priceElement)
end
function ConstructionScreen:getOrCreateConfigItem(type)
	local item = nil
	if #self.configItemCache == 0 then
		item = self.configurationItemTemplate:clone(self.configurationLayout)
	else
		item = self.configItemCache[#self.configItemCache]
		self.configItemCache[#self.configItemCache] = nil
		self.configurationLayout:addElement(item)
	end
	item.isLargeConfigItem = false
	item:setVisible(true)
	item.focusId = nil
	local option = false
	local color = false
	local yesNoOption = false
	local price = true
	local focusableElement = nil
	if type == "option" then
		option = true
		focusableElement = item:getDescendantByName("option")
	elseif type == "color" then
		color = true
		focusableElement = item:getDescendantByName("color")
	elseif type == "yesNoOption" then
		yesNoOption = true
		focusableElement = item:getDescendantByName("yesNoOption")
	end
	item:getDescendantByName("option"):setVisible(option)
	item:getDescendantByName("color"):setVisible(color)
	item:getDescendantByName("yesNoOption"):setVisible(yesNoOption)
	item:getDescendantByName("price"):setVisible(true)
	if focusableElement ~= nil then
		focusableElement.forceFocusScrollToTop = self.focusableElementForScroll == nil
		self.focusableElementForScroll = focusableElement
		item:getDescendantByName("title").getIsSelected = function()
			return focusableElement:getIsFocused()
		end
	end
	return item
end
function ConstructionScreen:getOrCreateLargeConfigItem(type)
	local item = nil
	if #self.configItemCacheLarge == 0 then
		item = self.configurationItemTemplateLarge:clone(self.configurationLayout)
	else
		item = self.configItemCacheLarge[#self.configItemCacheLarge]
		self.configItemCacheLarge[#self.configItemCacheLarge] = nil
		self.configurationLayout:addElement(item)
	end
	item.isLargeConfigItem = true
	item:setVisible(true)
	item.focusId = nil
	local focusableElement = item:getDescendantByName("option")
	focusableElement.forceFocusScrollToTop = self.focusableElementForScroll == nil
	self.focusableElementForScroll = focusableElement
	item:getDescendantByName("title").getIsSelected = function()
		return focusableElement:getIsFocused()
	end
	return item
end
function ConstructionScreen:setConfigPrice(configName, configIndex, priceTextElement)
	local configItems = self.brush.storeItem.configurations[configName]
	local price = configItems[configIndex].price
	if self.brush.placeable ~= nil and ConfigurationUtil.hasBoughtConfiguration(self.brush.placeable, configName, configIndex) then
		price = 0
	end
	priceTextElement:setText("+" .. g_i18n:formatMoney(price) .. "")
	priceTextElement:setVisible(true)
end
function ConstructionScreen:onPickColor(colorIndex, args, customColor, noUpdate)
	local configName = args.configName
	if customColor ~= nil then
		local isValid = true
		local configItems = self.brush.storeItem.configurations[configName]
		for index, configItem in pairs(configItems) do
			if configItem.isCustomColor then
				colorIndex = index
				isValid = true
				break
			end
		end
		if isValid then
			if self.configurationData[configName] == nil then
				self.configurationData[configName] = {}
			end
			self.configurationData[configName][colorIndex] = {}
			self.configurationData[configName][colorIndex].color = { customColor.customColor[1], customColor.customColor[2], customColor.customColor[3] }
			self.configurationData[configName][colorIndex].materialTemplateName = customColor.templateName
		end
	end
	if colorIndex ~= nil then
		local colorOptionIndex = args.colorOptionIndex
		local element = self.colorElements[colorOptionIndex]
		self.configurations[configName] = colorIndex
		local config = self.brush.storeItem.configurations[configName][colorIndex]
		local color = config.color
		local materialTemplateName = config.materialTemplateName
		if self.configurationData[configName] ~= nil then
			local data = self.configurationData[configName][colorIndex]
			if data ~= nil then
				color = data.color or color
				materialTemplateName = data.materialTemplateName or materialTemplateName
			end
		end
		local isMetallic = config.isMetallic
		local isMat = config.isMat
		element:getDescendantByName("colorImageGlossy"):setVisible(not (isMetallic or isMat))
		element:getDescendantByName("colorImageMetallic"):setVisible(isMetallic)
		element:getDescendantByName("colorImageMatte"):setVisible(isMat)
		if ColorPickButtonElement.BRIGHTNESS_THRESHOLD <= MathUtil.getBrightnessFromColor(unpack(color)) then
			element:getDescendantByName("colorImageGlossy"):setImageColor(nil, 0, 0, 0)
			element:getDescendantByName("colorImageMetallic"):setImageColor(nil, 0, 0, 0)
			element:getDescendantByName("colorImageMatte"):setImageColor(nil, 0, 0, 0)
		else
			element:getDescendantByName("colorImageGlossy"):setImageColor(nil, 1, 1, 1)
			element:getDescendantByName("colorImageMetallic"):setImageColor(nil, 1, 1, 1)
			element:getDescendantByName("colorImageMatte"):setImageColor(nil, 1, 1, 1)
		end
		local r, g, b = unpack(color)
		element:getDescendantByName("colorImage"):setImageColor(nil, math.clamp(r, 0, 1), math.clamp(g, 0, 1), math.clamp(b, 0, 1))
		local priceElement = element.parent:getDescendantByName("price")
		self:setConfigPrice(configName, colorIndex, priceElement, self.vehicle)
		if not noUpdate then
			self:loadCurrentConfiguration(self.brush.storeItem)
			self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CONFIG_SPRAY)
		end
	end
end
function ConstructionScreen:selectFirstConfig()
	local firstElement = self.configurationLayout.elements[1]
	if firstElement ~= nil then
		local focusElement = firstElement:getDescendantByName("option")
		if not focusElement:getIsVisible() then
			focusElement = firstElement:getDescendantByName("color")
		end
		if not focusElement:getIsVisible() then
			focusElement = firstElement:getDescendantByName("yesNoOption")
		end
		FocusManager:unsetFocus(focusElement)
		FocusManager:setFocus(focusElement)
	else
		FocusManager:unsetFocus(FocusManager:getFocusedElement())
		FocusManager.currentFocusData.focusElement = nil
	end
end
function ConstructionScreen:loadCurrentConfiguration(storeItem)
	local data = PlaceableLoadingData.new()
	data:setConfigurations(self.configurations)
	data:setConfigurationData(self.configurationData)
	data:setPosition(self.brush.placeable:getPosition())
	self.brush:unloadPlaceable(true)
	self.brush:setStoreItem(storeItem, self.configurations, self.configurationData)
	self.brush:loadPlaceable(data)
end
function ConstructionScreen:rebuildData()
	self.categories = g_storeManager:getConstructionCategories()
	self.items = {}
	local numItems = 0
	local maxTabs = 0
	for c, category in ipairs(self.categories) do
		self.items[c] = {}
		for t = 1, #category.tabs do
			self.items[c][t] = {}
		end
		maxTabs = math.max(maxTabs, #category.tabs)
	end
	for _, storeItem in ipairs(g_storeManager:getItems()) do
		if storeItem.brush == nil then
			continue
		end
		local brushClass = g_constructionBrushTypeManager:getClassObjectByTypeName(storeItem.brush.type)
		local parameters = storeItem.brush.parameters
		if parameters == nil or #parameters == 0 then
			parameters = { storeItem.xmlFilename }
		end
		if brushClass == nil then
			continue
		end
		local brand = g_brandManager:getBrandByIndex(storeItem.brandIndex)
		local brandImage = nil
		if brand ~= nil and brand.name ~= "NONE" then
			brandImage = brand.image
		end
		local modDlc = ""
		if storeItem.isMod then
			if storeItem.dlcTitle == nil then
				modDlc = "Mod"
			elseif storeItem.isMod then
				if storeItem.dlcTitle ~= nil then
					modDlc = storeItem.dlcTitle .. " (Mod)"
				elseif storeItem.dlcTitle ~= nil then
					modDlc = storeItem.dlcTitle
				end
			end
		end
		table.insert(self.items[storeItem.brush.category.index][storeItem.brush.tab.index], { brushClass = brushClass, brushParameters = parameters, brandFilename = brandImage, modDlc = modDlc, storeItem = storeItem, name = storeItem.name, price = storeItem.price, imageFilename = storeItem.imageFilename, displayItem = g_shopController:makeDisplayItem(storeItem), uniqueIndex = numItems + 1 })
		numItems = numItems + 1
	end
	numItems = self:buildTerrainPaintBrushes(numItems)
	numItems = self:buildTerrainSculptBrushes(numItems)
	self.categorySelector:reloadData()
end
function ConstructionScreen:buildTerrainPaintBrushes(numItems)
	local landscapingIndex = g_storeManager:getConstructionCategoryByName("landscaping").index
	local paintingIndex = g_storeManager:getConstructionTabByName("painting", "landscaping").index
	local paintsTab = self.items[landscapingIndex][paintingIndex]
	local groundTypes = {}
	for typeName, layerName in pairs(g_groundTypeManager.groundTypeMappings) do
		table.insert(groundTypes, typeName)
	end
	table.sort(groundTypes)
	local knownLayers = {}
	for _, typeName in ipairs(groundTypes) do
		local layer = g_groundTypeManager:getTerrainLayerByType(typeName)
		local title = g_groundTypeManager:getTerrainTitleByType(typeName)
		if knownLayers[layer] then
			continue
		end
		table.insert(paintsTab, { terrainOverlayLayer = layer, name = g_i18n:convertText(title), brushClass = ConstructionBrushPaint, brushParameters = { typeName }, price = 2, imageFilename = nil, brandFilename = nil, modDlc = "", uniqueIndex = numItems + 1 })
		numItems = numItems + 1
		knownLayers[layer] = true
	end
	return numItems
end
function ConstructionScreen:buildTerrainSculptBrushes(numItems)
	local landscapingIndex = g_storeManager:getConstructionCategoryByName("landscaping").index
	local sculptingIndex = g_storeManager:getConstructionTabByName("sculpting", "landscaping").index
	local sculptTab = self.items[landscapingIndex][sculptingIndex]
	table.insert(sculptTab, { name = g_i18n:getText("construction_item_shift"), brushClass = ConstructionBrushSculpt, brushParameters = { ConstructionBrushSculpt.MODE.SHIFT }, price = 10, imageFilename = "dataS/menu/construction/icon_shift.png", uniqueIndex = numItems + 1 })
	table.insert(sculptTab, { name = g_i18n:getText("construction_item_level"), brushClass = ConstructionBrushSculpt, brushParameters = { ConstructionBrushSculpt.MODE.LEVEL }, price = 10, imageFilename = "dataS/menu/construction/icon_level.png", uniqueIndex = numItems + 2 })
	table.insert(sculptTab, { name = g_i18n:getText("construction_item_soften"), brushClass = ConstructionBrushSculpt, brushParameters = { ConstructionBrushSculpt.MODE.SOFTEN }, price = 10, imageFilename = "dataS/menu/construction/icon_soften.png", uniqueIndex = numItems + 3 })
	table.insert(sculptTab, { name = g_i18n:getText("construction_item_slope"), brushClass = ConstructionBrushSculpt, brushParameters = { ConstructionBrushSculpt.MODE.SLOPE }, price = 10, imageFilename = "dataS/menu/construction/icon_slope.png", uniqueIndex = numItems + 4 })
	return numItems + 4
end
function ConstructionScreen:setCurrentCategory(index, tabIndex)
	if self.currentCategory == index then
		return
	else
		self.categorySelector:setSelectedIndex(index)
		self.currentCategory = index
		self.subCategorySelector:setState(tabIndex or 1, true)
		for i, dot in pairs(self.subCategoryDotBox.elements) do
			dot:delete()
			self.subCategoryDotBox.elements[i] = nil
		end
		local subCategoryTexts = {}
		for index, subCategory in pairs(self.categories[index].tabs) do
			local dot = self.subCategoryDotTemplate:clone(self.subCategoryDotBox)
			function dot.getIsSelected()
				return self.currentTab == index
			end
			table.insert(subCategoryTexts, subCategory.title)
		end
		self.subCategorySelector:setTexts(subCategoryTexts)
		self.subCategoryDotBox:invalidateLayout()
		self:setBrush(self.selectorBrush, true)
		self:updateMenuState()
	end
end
function ConstructionScreen:setCurrentTab(index)
	if index == nil then
		index = 1
	end
	self.currentTab = index
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
function ConstructionScreen:buildCellDatabase()
	self.detailsTemplates = {}
	for i = #self.attributesLayout.elements, 1, -1 do
		local element = self.attributesLayout.elements[i]
		local name = element.name
		self.detailsTemplates[name] = element:clone()
		self.detailsCache[name] = {}
	end
end
function ConstructionScreen:dequeueDetailsCell(name)
	if self.detailsTemplates[name] == nil then
		return nil
	else
		local cell = nil
		local cache = self.detailsCache[name]
		if 0 < #cache then
			cell = cache[#cache]
			cache[#cache] = nil
		else
			cell = self.detailsTemplates[name]:clone(self)
		end
		self.attributesLayout:addElement(cell)
		return cell
	end
end
function ConstructionScreen:queueDetailsCell(cell)
	local cache = self.detailsCache[cell.name]
	cache[#cache + 1] = cell
	self.attributesLayout:removeElement(cell)
	cell:unlinkElement()
end
function ConstructionScreen.consoleCommandToggleUI()
	ConstructionScreen.uiHidden = not ConstructionScreen.uiHidden
end
