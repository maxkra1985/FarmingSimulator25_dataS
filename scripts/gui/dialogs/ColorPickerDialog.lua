ColorPickerDialog = {}
local ColorPickerDialog_mt = Class(ColorPickerDialog, MessageDialog)
ColorPickerDialog.MAX_COLUMNS = 8
ColorPickerDialog.MAX_NUM_CUSTOM_COLORS = 255
ColorPickerDialog.INPUT_THRESHOLD = 0.01
ColorPickerDialog.INPUT_SCALE = 10000
ColorPickerDialog.DOUBLE_CLICK_INTERVAL = 400
ColorPickerDialog.CATEGORY_LIST = 1
ColorPickerDialog.CATEGORY_CUSTOM = 2
ColorPickerDialog.CATEGORY_FAVORITES = 3
function ColorPickerDialog.register()
	local colorPickerDialog = ColorPickerDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/ColorPickerDialog.xml", "ColorPickerDialog", colorPickerDialog)
	ColorPickerDialog.INSTANCE = colorPickerDialog
end
function ColorPickerDialog.show(callback, target, args, colors, defaultColorIndex, defaultMaterial, customColor, customColorsEnabled, disableOpenSound, materialSelectionDisabled)
	if ColorPickerDialog.INSTANCE ~= nil then
		local dialog = ColorPickerDialog.INSTANCE
		dialog.dialogColors = colors
		dialog.dialogDefaultColorIndex = defaultColorIndex
		dialog.dialogCustomColor = customColor
		dialog.dialogDefaultMaterial = defaultMaterial
		dialog:setCustomOptionsEnabled(customColorsEnabled, materialSelectionDisabled)
		dialog:setCallback(callback, target, args)
		dialog:setDisableOpenSound(disableOpenSound)
		g_gui:showDialog("ColorPickerDialog")
	end
end
function ColorPickerDialog.new(target, custom_mt)
	local self = ColorPickerDialog:superClass().new(target, custom_mt or ColorPickerDialog_mt)
	self.colorElements = {}
	self.customColorsDirty = false
	self.customColors = {}
	self.customRenderColor = { 1, 0, 0, 1 }
	self.accumHorizontalInput = 0
	self.accumVerticalInput = 0
	self.lastColorButtonClickTime = 0
	return self
end
function ColorPickerDialog.createFromExistingGui(gui, guiName)
	ColorPickerDialog.register()
	local callback = gui.callbackFunction
	local target = gui.target
	local callbackArgs = gui.args
	local colors = gui.colors
	local defaultColor = gui.colors[gui.defaultColorIndex] or gui.colors[1]
	local defaultColorMaterial = gui.defaultColorMaterial
	ColorPickerDialog.show(callback, target, callbackArgs, colors, defaultColor, defaultColorMaterial)
end
function ColorPickerDialog:delete()
	if self.buttonTemplate ~= nil then
		self.buttonTemplate:delete()
	end
	ColorPickerDialog:superClass().delete(self)
end
function ColorPickerDialog:loadMapData(mapXMLFile, missionInfo, baseDirectory)
	self.colorRender:createScene()
end
function ColorPickerDialog:unloadMapData()
	self.colorRender:destroyScene()
end
function ColorPickerDialog:onGuiSetupFinished()
	ColorPickerDialog:superClass().onGuiSetupFinished(self)
	local lineSize = (self.contentContainer.absSize[1] - self.headerText:getTextWidth()) / 2 - 20 * g_pixelSizeScaledX
	self.topLineLeft:setSize(lineSize, nil)
	self.topLineRight:setSize(lineSize, nil)
	for index, button in pairs(self.subCategoryTabs) do
		button:getDescendantByName("background").getIsSelected = function()
			return index == self.pageSelector:getState()
		end
		function button.getIsSelected()
			return index == self.pageSelector:getState()
		end
	end
	local hueTexts = {}
	local rgbTexts = {}
	for i = 0, 360 do
		table.insert(hueTexts, tostring(i))
		if i <= 255 then
			table.insert(rgbTexts, tostring(i))
		end
	end
	self.hueSlider:setTexts(hueTexts)
	self.rgbRed:setTexts(rgbTexts)
	self.rgbGreen:setTexts(rgbTexts)
	self.rgbBlue:setTexts(rgbTexts)
	self.materialPicker:setTexts({ g_i18n:getText(ColorPickerDialog.MATERIAL_TEXTS[1].text), g_i18n:getText(ColorPickerDialog.MATERIAL_TEXTS[2].text), g_i18n:getText(ColorPickerDialog.MATERIAL_TEXTS[3].text) })
	FocusManager:linkElements(self.rgbRed, FocusManager.BOTTOM, self.rgbGreen)
	FocusManager:linkElements(self.rgbGreen, FocusManager.TOP, self.rgbRed)
	FocusManager:linkElements(self.rgbGreen, FocusManager.BOTTOM, self.rgbBlue)
	FocusManager:linkElements(self.rgbBlue, FocusManager.TOP, self.rgbGreen)
	FocusManager:linkElements(self.rgbBlue, FocusManager.BOTTOM, self.materialPicker)
	FocusManager:linkElements(self.materialPicker, FocusManager.TOP, self.rgbBlue)
end
function ColorPickerDialog:onOpen()
	ColorPickerDialog:superClass().onOpen(self)
	self.colorRender:setVisible(true)
	self.customPickerUpDownEventId = g_inputBinding:registerActionEvent(InputAction.AXIS_PICK_COLOR_UPDOWN, self, self.onVerticalCursorInput, false, false, true, true)
	self.customPickerLeftRightEventId = g_inputBinding:registerActionEvent(InputAction.AXIS_PICK_COLOR_LEFTRIGHT, self, self.onHorizontalCursorInput, false, false, true, true)
	self.customColorsDirty = false
	self.customColors = table.copyIndex(g_gameSettings:getValue(GameSettings.SETTING.CUSTOM_COLORS))
	self:setInitialFocus()
	self.needsRenderColorUpdate = true
	if self.customColorsEnabled then
		if self.dialogCustomColor ~= nil then
			self:setCustomColorRGB(self.dialogCustomColor)
			self:onClickCustom()
		elseif self.colors ~= nil then
			if self.colors[self.dialogDefaultColorIndex] ~= nil then
				self:setCustomColorRGB(self.colors[self.dialogDefaultColorIndex].color)
				self:onClickList()
			else
				self:onHueChanged(1)
				self:setCustomColorHSV(0, 1, 1)
				self:onClickList()
			end
		end
	end
	self.lastInputHelpMode = nil
end
function ColorPickerDialog:onClose()
	self.colorRender:setVisible(false)
	g_inputBinding:removeActionEventsByTarget(self)
	if self.customColorsDirty then
		g_gameSettings:setValue(GameSettings.SETTING.CUSTOM_COLORS, self.customColors, true)
	end
	ColorPickerDialog:superClass().onClose(self)
end
function ColorPickerDialog:setCustomOptionsEnabled(customColorsEnabled, materialSelectionDisabled)
	self.subCategoryTabs[2]:setVisible(customColorsEnabled)
	self.subCategoryTabs[3]:setVisible(customColorsEnabled)
	self.subCategoryBox:invalidateLayout()
	self.pageSelector:setVisible(customColorsEnabled)
	self.categoryGlyphsPrev:setVisible(customColorsEnabled)
	self.categoryGlyphsNext:setVisible(customColorsEnabled)
	if customColorsEnabled then
		self.pageSelector:setTexts({ "1", "2", "3" })
	else
		self.pageSelector:setTexts({ "1" })
	end
	self.materialTitle:setVisible(not materialSelectionDisabled)
	self.materialPicker:setVisible(not materialSelectionDisabled)
	if self.dialogDefaultMaterial ~= nil then
		for index, material in pairs(ColorPickerDialog.MATERIAL_TEXTS) do
			if material.materialName == self.dialogDefaultMaterial then
				self.materialPicker:setState(index, true)
				self.customColorsEnabled = customColorsEnabled
				self.materialSelectionDisabled = materialSelectionDisabled
				return
			end
		end
	else
		self.materialPicker:setState(1, true)
	end
end
function ColorPickerDialog:setColors(colors, defaultColorIndex, defaultColorMaterial)
	for i = #self.colorElements, 1, -1 do
		self.colorElements[i]:delete()
	end
	local defaultColor = nil
	if 0 < #colors then
		if type(colors[1].color) ~= "table" then
			local newColors = {}
			for i, color in ipairs(colors) do
				newColors[i] = { color = color }
			end
			colors = newColors
			defaultColor = colors[defaultColorIndex or 1]
		elseif defaultColorIndex ~= nil then
			self.lastListButtonIndex = defaultColorIndex
		elseif self.dialogCustomColor ~= nil then
			for i, color in ipairs(colors) do
				if color[1] == self.dialogCustomColor[1] and (color[2] == self.dialogCustomColor[2] and color[3] == self.dialogCustomColor[3]) then
					defaultColor = colors[i]
				end
			end
			defaultColor = defaultColor or colors[1]
		end
	end
	self.colors = colors
	self.colorElements = {}
	self.colorMapping = {}
	self.buttonMapping = {}
	self.layoutMapping = {}
	if self.lastListButtonIndex == nil then
		if defaultColor == nil then
			self.lastListButtonIndex = 1
		else
			for index, color in ipairs(colors) do
				if color.uiColor ~= nil then
					if table.equalLists(defaultColor, color.uiColor) then
						if defaultColorMaterial == nil or color.material == defaultColorMaterial then
							self.lastListButtonIndex = index
						else
						end
					end
				else
					if defaultColorMaterial == nil or color.material == defaultColorMaterial then
						self.lastListButtonIndex = index
					else
					end
				end
				local numSelectableColors = 0
				local buttonWidth = self.buttonTemplate.size[1] + self.buttonTemplate.margin[1] + self.buttonTemplate.margin[3]
				local buttonHeight = self.buttonTemplate.size[2] + self.buttonTemplate.margin[2] + self.buttonTemplate.margin[4]
				local numCols = math.floor(self.colorButtonLayout.absSize[1] / buttonWidth)
				local numRows = math.floor(self.colorButtonLayout.absSize[2] / buttonHeight)
				for i, color in ipairs(colors) do
					if color.isSelectable == false then
						continue
					end
					local newColorButton = self.buttonTemplate:clone(self.colorButtonLayout)
					newColorButton:setVisible(true)
					self.colorMapping[newColorButton] = i
					self.buttonMapping[color] = newColorButton
					numSelectableColors = numSelectableColors + 1
					self.layoutMapping[newColorButton] = numSelectableColors
					table.insert(self.colorElements, newColorButton)
					local uiColor = color.color
					if color.uiColor ~= nil then
						uiColor = color.uiColor
					end
					if color.materialName == ColorPickerDialog.MATERIAL_TEXTS[ColorPickerDialog.MATERIAL_MATTE].materialName then
						newColorButton:setIsMatte(true)
					else
						newColorButton:setIsMetallic(color.materialName == ColorPickerDialog.MATERIAL_TEXTS[ColorPickerDialog.MATERIAL_METALLIC].materialName)
					end
					if color.isMat then
						newColorButton:setIsMatte(true)
					end
					if color.isMetallic then
						newColorButton:setIsMetallic(true)
					end
					local r = uiColor[1] ~= nil and math.clamp(uiColor[1], 0, 1) or 1
					local g = uiColor[2] ~= nil and math.clamp(uiColor[2], 0, 1) or 1
					local b = uiColor[3] ~= nil and math.clamp(uiColor[3], 0, 1) or 1
					newColorButton:setColor(r, g, b)
					if i == self.lastListButtonIndex then
						self.lastListButtonIndex = #self.colorElements
					end
				end
				for i = #self.colorButtonLayout.elements + 1, numRows * numCols do
					local newColorButton = self.buttonTemplate:clone(self.colorButtonLayout)
					newColorButton:setVisible(true)
					table.insert(self.colorElements, newColorButton)
					newColorButton:setColor(0, 0, 0, 0.15)
					newColorButton:setMaterial()
					newColorButton.handleFocus = false
					newColorButton:setDisabled(true)
				end
				self.colorButtonLayout:invalidateLayout()
				self:focusLinkColorButtons(numCols)
				self:setInitialFocus()
				self.defaultColorMaterial = defaultColorMaterial
				return
			end
		end
	end
end
function ColorPickerDialog:focusLinkColorButtons(numCols)
	for i = 1, #self.colorButtonLayout.elements do
		local button = self.colorButtonLayout.elements[i]
		local leftButton = self.colorButtonLayout.elements[i - 1]
		local rightButton = self.colorButtonLayout.elements[i + 1]
		local topButton = self.colorButtonLayout.elements[i - numCols]
		local bottomButton = self.colorButtonLayout.elements[i + numCols]
		if leftButton ~= nil then
			FocusManager:linkElements(button, FocusManager.LEFT, leftButton)
		else
			FocusManager:linkElements(button, FocusManager.LEFT, nil)
		end
		if rightButton ~= nil then
			FocusManager:linkElements(button, FocusManager.RIGHT, rightButton)
		else
			FocusManager:linkElements(button, FocusManager.RIGHT, button)
		end
		if topButton ~= nil then
			FocusManager:linkElements(button, FocusManager.TOP, topButton)
		else
			FocusManager:linkElements(button, FocusManager.TOP, nil)
		end
		if bottomButton ~= nil then
			FocusManager:linkElements(button, FocusManager.BOTTOM, bottomButton)
		else
			FocusManager:linkElements(button, FocusManager.BOTTOM, nil)
		end
	end
end
function ColorPickerDialog:setInitialFocus()
	local elem = nil
	if 0 < #self.colorElements then
		local lastIndex = nil
		local subCategoryIndex = self.pageSelector:getState()
		if subCategoryIndex == ColorPickerDialog.CATEGORY_LIST then
			lastIndex = math.clamp(self.lastListButtonIndex or 1, 1, #self.colors)
		elseif subCategoryIndex == ColorPickerDialog.CATEGORY_FAVORITES then
			if self.customColors ~= nil and 0 < #self.customColors then
				lastIndex = math.clamp(self.lastFavoritesButtonIndex or 1, 1, #self.customColors)
			end
		end
		elem = self.colorElements[lastIndex]
	end
	if elem ~= nil then
		self.currentSelectedElement = elem
		self.blockFocusDelegate = true
		FocusManager:setFocus(elem)
		self.blockFocusDelegate = false
	end
end
function ColorPickerDialog:setCallback(callbackFunction, target, args)
	self.callbackFunction = callbackFunction
	self.target = target
	self.args = args
end
function ColorPickerDialog:setCustomColorHSV(hue, saturation, value)
	if saturation ~= nil and value ~= nil then
		self.cursor:setAbsolutePosition(self.customPicker.absPosition[1] + self.customPicker.absSize[1] * saturation - self.cursor.absSize[1] * 0.5, self.customPicker.absPosition[2] + self.customPicker.absSize[2] * value - self.cursor.absSize[2] * 0.5)
	end
	saturation = saturation or math.clamp((self.cursor.absPosition[1] + self.cursor.absSize[1] * 0.5 - self.customPicker.absPosition[1]) / self.customPicker.absSize[1], 0, 1)
	value = value or math.clamp((self.cursor.absPosition[2] + self.cursor.absSize[2] * 0.5 - self.customPicker.absPosition[2]) / self.customPicker.absSize[2], 0, 1)
	local r, g, b = GuiUtils.hsvToRGB(hue / 360, saturation, value)
	if not self.blockStateUpdate then
		self.rgbRed:setState(math.round(r * 255) + 1)
		self.rgbGreen:setState(math.round(g * 255) + 1)
		self.rgbBlue:setState(math.round(b * 255) + 1)
	end
	r = math.pow(r, 2.2)
	g = math.pow(g, 2.2)
	b = math.pow(b, 2.2)
	self.customRenderColor = { r, g, b }
	self.needsRenderColorUpdate = true
end
function ColorPickerDialog:setCustomColorRGB(color)
	local r, g, b = unpack(color)
	r = math.pow(r, 0.45454545454545453)
	g = math.pow(g, 0.45454545454545453)
	b = math.pow(b, 0.45454545454545453)
	local hue, saturation, value = GuiUtils.rgbToHSV(r, g, b)
	local r2, g2, b2 = GuiUtils.hsvToRGB(hue)
	r2 = math.pow(r2, 2.2)
	g2 = math.pow(g2, 2.2)
	b2 = math.pow(b2, 2.2)
	self.customPicker:setImageColor(nil, r2, g2, b2, 1)
	hue = math.round(hue * 360)
	self.hueSlider:setState(hue + 1)
	self.cursor:setAbsolutePosition(self.customPicker.absPosition[1] + self.customPicker.absSize[1] * saturation - self.cursor.absSize[1] * 0.5, self.customPicker.absPosition[2] + self.customPicker.absSize[2] * value - self.cursor.absSize[2] * 0.5)
	if not self.blockStateUpdate then
		self.rgbRed:setState(math.round(r * 255) + 1)
		self.rgbGreen:setState(math.round(g * 255) + 1)
		self.rgbBlue:setState(math.round(b * 255) + 1)
	end
	r = math.pow(r, 2.2)
	g = math.pow(g, 2.2)
	b = math.pow(b, 2.2)
	self.customRenderColor = { r, g, b }
	self.needsRenderColorUpdate = true
end
function ColorPickerDialog:onCreate()
	ColorPickerDialog:superClass().onCreate(self)
	self.defaultOkText = self.okButton.text
	self.defaultBackText = self.backButton.text
	self.buttonTemplate:unlinkElement()
	FocusManager:removeElement(self.buttonTemplate)
end
function ColorPickerDialog:update(dt)
	ColorPickerDialog:superClass().update(self, dt)
	local inputHelpMode = g_inputBinding:getInputHelpMode()
	if inputHelpMode ~= self.lastInputHelpMode then
		self.cursorGlyphBox:setVisible(g_inputBinding:getInputHelpMode() == GS_INPUT_HELP_MODE_GAMEPAD)
		self.customPickerLayout:invalidateLayout()
		local moveActions = { InputAction.AXIS_PICK_COLOR_UPDOWN, InputAction.AXIS_PICK_COLOR_LEFTRIGHT }
		self.cursorGlyph:setActions(moveActions, nil, nil, true)
		self.lastInputHelpMode = inputHelpMode
	end
	if self.accumVerticalInput ~= 0 or self.accumHorizontalInput ~= 0 then
		local cursor = self.cursor
		local customPicker = self.customPicker
		ColorPickerDialog.INPUT_SCALE = 20000
		local offsetX = self.accumHorizontalInput * dt / ColorPickerDialog.INPUT_SCALE
		local offsetY = -self.accumVerticalInput * dt / (ColorPickerDialog.INPUT_SCALE / g_screenAspectRatio)
		local cursorX = math.clamp(cursor.absPosition[1] + offsetX, customPicker.absPosition[1] - cursor.absSize[1] * 0.5, customPicker.absPosition[1] + customPicker.absSize[1] - cursor.absSize[1] * 0.5)
		local cursorY = math.clamp(cursor.absPosition[2] + offsetY, customPicker.absPosition[2] - cursor.absSize[2] * 0.5, customPicker.absPosition[2] + customPicker.absSize[2] - cursor.absSize[2] * 0.5)
		cursor:setAbsolutePosition(cursorX, cursorY)
		self:setCustomColorHSV(self.hueSlider:getState() - 1)
		self.accumVerticalInput = self.accumVerticalInput * 0.5
		self.accumHorizontalInput = self.accumHorizontalInput * 0.5
		if math.abs(self.accumVerticalInput) <= ColorPickerDialog.INPUT_THRESHOLD then
			self.accumVerticalInput = 0
		end
		if math.abs(self.accumHorizontalInput) <= ColorPickerDialog.INPUT_THRESHOLD then
			self.accumHorizontalInput = 0
		end
	end
	if self.needsRenderColorUpdate and not self.colorRender.isLoading then
		local material = VehicleMaterial.new()
		local templateName = ColorPickerDialog.MATERIAL_TEXTS[self.materialPicker:getState()].materialName
		material:setTemplateName(templateName)
		material:setColor(self.customRenderColor)
		local sphereNodeId = getChildAt(getChildAt(self.colorRender.scene, 0), 0)
		material:apply(sphereNodeId)
		self.colorRender:setRenderDirty()
		self.needsRenderColorUpdate = false
	end
end
function ColorPickerDialog:onClickList()
	self.pageSelector:setState(ColorPickerDialog.CATEGORY_LIST, true)
end
function ColorPickerDialog:onClickCustom()
	self.pageSelector:setState(ColorPickerDialog.CATEGORY_CUSTOM, true)
end
function ColorPickerDialog:onClickFavorites()
	self.pageSelector:setState(ColorPickerDialog.CATEGORY_FAVORITES, true)
end
function ColorPickerDialog:updateSubCategoryPages(subCategoryIndex)
	g_inputBinding:setActionEventActive(self.customPickerUpDownEventId, subCategoryIndex == ColorPickerDialog.CATEGORY_CUSTOM)
	g_inputBinding:setActionEventActive(self.customPickerLeftRightEventId, subCategoryIndex == ColorPickerDialog.CATEGORY_CUSTOM)
	self.pageColorList:setVisible(subCategoryIndex ~= ColorPickerDialog.CATEGORY_CUSTOM)
	self.pageColorPicker:setVisible(subCategoryIndex == ColorPickerDialog.CATEGORY_CUSTOM)
	self.colorName:setText("")
	self.colorNameBox:invalidateLayout()
	self.materialLegend:setVisible(subCategoryIndex ~= ColorPickerDialog.CATEGORY_CUSTOM)
	if subCategoryIndex == ColorPickerDialog.CATEGORY_LIST then
		self:setColors(self.dialogColors, self.dialogDefaultColorIndex or self.lastListButtonIndex, self.dialogDefaultMaterial)
	elseif subCategoryIndex == ColorPickerDialog.CATEGORY_CUSTOM then
		FocusManager:setFocus(self.hueSlider)
	elseif subCategoryIndex == ColorPickerDialog.CATEGORY_FAVORITES then
		self:setColors(self.customColors, self.lastFavoritesButtonIndex)
	end
	self.addToFavoritesButton:setVisible(subCategoryIndex == ColorPickerDialog.CATEGORY_CUSTOM and #self.customColors < ColorPickerDialog.MAX_NUM_CUSTOM_COLORS)
	self.okButton:setVisible(subCategoryIndex ~= ColorPickerDialog.CATEGORY_FAVORITES or 0 < #self.colors)
	self.deleteButton:setVisible(subCategoryIndex == ColorPickerDialog.CATEGORY_FAVORITES and 0 < #self.colors)
	self.renameButton:setVisible(subCategoryIndex == ColorPickerDialog.CATEGORY_FAVORITES and 0 < #self.colors)
	self.buttonsBox:invalidateLayout()
end
function ColorPickerDialog:onHueChanged(hueState)
	local hue = hueState - 1
	local r, g, b = GuiUtils.hsvToRGB(hue / 360)
	r = math.pow(r, 2.2)
	g = math.pow(g, 2.2)
	b = math.pow(b, 2.2)
	self.customPicker:setImageColor(nil, r, g, b, 1)
	self:setCustomColorHSV(hue)
end
function ColorPickerDialog:onRGBChanged()
	local r = (self.rgbRed:getState() - 1) / 255
	local g = (self.rgbGreen:getState() - 1) / 255
	local b = (self.rgbBlue:getState() - 1) / 255
	local hue, saturation, value = GuiUtils.rgbToHSV(r, g, b)
	hue = math.round(hue * 360)
	if hue + 1 ~= self.hueSlider:getState() then
		self.blockStateUpdate = true
		self.hueSlider:setState(hue + 1, true)
		self.blockStateUpdate = false
	end
	self.cursor:setAbsolutePosition(self.customPicker.absPosition[1] + self.customPicker.absSize[1] * saturation - self.cursor.absSize[1] * 0.5, self.customPicker.absPosition[2] + self.customPicker.absSize[2] * value - self.cursor.absSize[2] * 0.5)
	self.blockStateUpdate = true
	self:setCustomColorHSV(hue, saturation, value)
	self.blockStateUpdate = false
end
function ColorPickerDialog:onMaterialChanged()
	self.needsRenderColorUpdate = true
end
function ColorPickerDialog:onClickAddToFavorites()
	TextInputDialog.show(self.onCustomColorNameEntered, self, nil, g_i18n:getText("ui_colorPicker_enterColorName"), nil, 30, g_i18n:getText("button_confirm"))
end
function ColorPickerDialog:onClickDelete()
	YesNoDialog.show(self.onYesNoDeleteFromFavorites, self, g_i18n:getText("ui_deleteColor"), g_i18n:getText("button_delete"))
end
function ColorPickerDialog:onCustomColorNameEntered(name)
	local r = math.pow(MathUtil.round((self.rgbRed:getState() - 1) / 255, 5), 2.2)
	local g = math.pow(MathUtil.round((self.rgbGreen:getState() - 1) / 255, 5), 2.2)
	local b = math.pow(MathUtil.round((self.rgbBlue:getState() - 1) / 255, 5), 2.2)
	table.insert(self.customColors, { name = name, color = { r, g, b }, materialName = ColorPickerDialog.MATERIAL_TEXTS[self.materialPicker:getState()].materialName })
	if ColorPickerDialog.MAX_NUM_CUSTOM_COLORS <= #self.customColors then
		self.addToFavoritesButton:setVisible(false)
		self.buttonsBox:invalidateLayout()
	end
	self.customColorsDirty = true
end
function ColorPickerDialog:onYesNoDeleteFromFavorites(yes)
	if yes then
		local colorIndex = self.colorMapping[self.currentSelectedElement]
		table.remove(self.customColors, colorIndex)
		self.colorName:setText("")
		self.colorNameBox:invalidateLayout()
		self:setColors(self.customColors)
		self:setInitialFocus()
		self.customColorsDirty = true
	end
end
function ColorPickerDialog:onClickRename()
	TextInputDialog.show(self.onCustomColorRenamed, self, nil, g_i18n:getText("ui_colorPicker_enterColorName"), g_i18n:getText("button_rename"), 30, g_i18n:getText("button_confirm"))
end
function ColorPickerDialog:onCustomColorRenamed(name)
	local colorIndex = self.colorMapping[self.currentSelectedElement]
	self.customColors[colorIndex].name = name
	self:setColors(self.customColors)
	self.customColorsDirty = true
end
function ColorPickerDialog:onClickOk()
	if self.customColorsEnabled then
		if self.pageSelector:getState() == ColorPickerDialog.CATEGORY_CUSTOM then
			self:setColors(self.dialogColors, self.dialogDefaultColorIndex, self.dialogDefaultMaterial)
			local r = math.pow((self.rgbRed:getState() - 1) / 255, 2.2)
			local g = math.pow((self.rgbGreen:getState() - 1) / 255, 2.2)
			local b = math.pow((self.rgbBlue:getState() - 1) / 255, 2.2)
			local customColor = {}
			customColor.customColor = { r, g, b }
			customColor.templateName = ColorPickerDialog.MATERIAL_TEXTS[self.materialPicker:getState()].materialName
			self:sendCallback(nil, customColor)
			return
		elseif self.pageSelector:getState() == ColorPickerDialog.CATEGORY_FAVORITES then
			local colorIndex = self.colorMapping[self.currentSelectedElement]
			local customColor = {}
			customColor.customColor = table.clone(self.customColors[colorIndex].color)
			customColor.templateName = self.customColors[colorIndex].materialName or ColorPickerDialog.MATERIAL_TEXTS[ColorPickerDialog.MATERIAL_GLOSSY].materialName
			self:sendCallback(nil, customColor)
			return
		else
			local colorIndex = self.colorMapping[self.currentSelectedElement]
			self:sendCallback(colorIndex)
			return
		end
	end
	local colorIndex = self.colorMapping[self.currentSelectedElement]
	self:sendCallback(colorIndex)
end
function ColorPickerDialog:onClickColorButton(element)
	if g_time <= self.lastColorButtonClickTime + ColorPickerDialog.DOUBLE_CLICK_INTERVAL then
		self:onClickOk()
	else
		self:onActivateColorButton(element)
		self.lastColorButtonClickTime = g_time
	end
end
function ColorPickerDialog:onActivateColorButton(element)
	local colorIndex = self.colorMapping[element]
	local layoutIndex = self.layoutMapping[element]
	local color = self.colors[colorIndex].color
	local materialName = self.colors[colorIndex].materialName
	local subCategoryIndex = self.pageSelector:getState()
	if subCategoryIndex == ColorPickerDialog.CATEGORY_LIST then
		self.lastListButtonIndex = layoutIndex
		self.lastFavoritesButtonIndex = nil
	elseif subCategoryIndex == ColorPickerDialog.CATEGORY_FAVORITES then
		self.lastListButtonIndex = nil
		self.lastFavoritesButtonIndex = layoutIndex
	end
	if self.customColorsEnabled then
		local r = math.round(math.pow(color[1], 0.45454545454545453) * 255) + 1
		local g = math.round(math.pow(color[2], 0.45454545454545453) * 255) + 1
		local b = math.round(math.pow(color[3], 0.45454545454545453) * 255) + 1
		self.rgbRed:setState(r)
		self.rgbGreen:setState(g)
		self.rgbBlue:setState(b, true)
		if materialName ~= nil then
			for index, material in pairs(ColorPickerDialog.MATERIAL_TEXTS) do
				if material.materialName == materialName then
					self.materialPicker:setState(index)
					return
				end
			end
			return
		end
		self.materialPicker:setState(1)
	end
end
function ColorPickerDialog:onClickBack(forceBack, usedMenuButton)
	self:sendCallback(nil)
	return false
end
function ColorPickerDialog:sendCallback(colorIndex, customColor)
	self:close()
	if self.callbackFunction ~= nil then
		if self.target ~= nil then
			self.callbackFunction(self.target, colorIndex, self.args, customColor)
			return
		end
		self.callbackFunction(colorIndex, self.args, customColor)
	end
end
function ColorPickerDialog:onFocusColorButton(element)
	if not self.blockFocusDelegate then
		self:onActivateColorButton(element)
	end
	local colorIndex = self.colorMapping[element]
	local color = self.colors[colorIndex]
	self.currentSelectedElement = element
	if self.colorName ~= nil then
		self.colorName:setText(Utils.getNoNil(color.name, ""))
		self.colorNameBox:invalidateLayout()
	end
end
function ColorPickerDialog:onHighlightColorButton(element)
	local colorIndex = self.colorMapping[element]
	local color = self.colors[colorIndex]
	if self.colorName ~= nil then
		self.colorName:setText(Utils.getNoNil(color.name, ""))
		self.colorNameBox:invalidateLayout()
	end
end
function ColorPickerDialog:onLeaveColorButton(element)
	if self.colorName ~= nil then
		if self.currentSelectedElement ~= nil then
			local colorIndex = self.colorMapping[self.currentSelectedElement]
			local color = self.colors[colorIndex]
			if color ~= nil then
				self.colorName:setText(Utils.getNoNil(color.name, ""))
				self.colorNameBox:invalidateLayout()
			end
		else
			self.colorName:setText("")
			self.colorNameBox:invalidateLayout()
		end
	end
end
function ColorPickerDialog:setButtonTexts(okText, backText)
	self.okButton:setText(Utils.getNoNil(okText, self.defaultOkText))
	self.backButton:setText(Utils.getNoNil(backText, self.defaultBackText))
end
function ColorPickerDialog:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	local offsetX = 20 * g_pixelSizeX
	local offsetY = 20 * g_pixelSizeY
	local isInPicker = GuiUtils.checkOverlayOverlap(posX, posY, self.customPicker.absPosition[1] - offsetX, self.customPicker.absPosition[2] - offsetY, self.customPicker.absSize[1] + offsetX * 2, self.customPicker.absSize[2] + offsetY * 2)
	if isInPicker and self.customPicker:getIsVisible() then
		if isDown then
			self.inputDown = true
		end
		if self.inputDown then
			local cursorX = math.clamp(posX, self.customPicker.absPosition[1], self.customPicker.absPosition[1] + self.customPicker.absSize[1])
			local cursorY = math.clamp(posY, self.customPicker.absPosition[2], self.customPicker.absPosition[2] + self.customPicker.absSize[2])
			self.cursor:setAbsolutePosition(cursorX - self.cursor.absSize[1] * 0.5, cursorY - self.cursor.absSize[2] * 0.5)
			self:setCustomColorHSV(self.hueSlider:getState() - 1)
		end
	end
	if isUp then
		self.inputDown = false
	end
end
function ColorPickerDialog:onHorizontalCursorInput(_, inputValue)
	self.accumHorizontalInput = self.accumHorizontalInput + inputValue
end
function ColorPickerDialog:onVerticalCursorInput(_, inputValue)
	self.accumVerticalInput = self.accumVerticalInput + inputValue
end
ColorPickerDialog.MATERIAL_GLOSSY = 1
ColorPickerDialog.MATERIAL_METALLIC = 2
ColorPickerDialog.MATERIAL_MATTE = 3
ColorPickerDialog.MATERIAL_TEXTS = { { text = "material_glossy", materialName = "calibratedGlossPaint" }, { text = "material_metallic", materialName = "calibratedMetallicPaint" }, { text = "material_matte", materialName = "calibratedMatPaint" } }
