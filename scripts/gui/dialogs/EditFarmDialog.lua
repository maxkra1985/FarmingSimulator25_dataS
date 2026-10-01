EditFarmDialog = {}
local EditFarmDialog_mt = Class(EditFarmDialog, MessageDialog)
EditFarmDialog.MAX_COLUMNS = 8
function EditFarmDialog.register()
	local editFarmDialog = EditFarmDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/EditFarmDialog.xml", "EditFarmDialog", editFarmDialog)
	EditFarmDialog.INSTANCE = editFarmDialog
end
function EditFarmDialog.show(farmId)
	if EditFarmDialog.INSTANCE ~= nil then
		local dialog = EditFarmDialog.INSTANCE
		g_gui:showDialog("EditFarmDialog")
		dialog:setExistingFarm(farmId)
	end
end
function EditFarmDialog.new(target, custom_mt)
	local self = EditFarmDialog:superClass().new(target, custom_mt or EditFarmDialog_mt)
	self.farmId = nil
	self.isCreatingNewFarm = true
	self.availableColorIndexMap = {}
	self.availableColors = {}
	self.selectedColorIndex = 1
	self.currentColorItemList = {}
	self.colorsToAdd = {}
	self.selectedIndex = 1
	self.colorElements = {}
	return self
end
function EditFarmDialog.createFromExistingGui(gui, guiName)
	EditFarmDialog.register()
	local farmId = gui.farmId
	EditFarmDialog.show(farmId)
end
function EditFarmDialog:delete()
	if self.buttonTemplate ~= nil then
		self.buttonTemplate:delete()
	end
	EditFarmDialog:superClass().delete(self)
end
function EditFarmDialog:onClose()
	EditFarmDialog:superClass().onClose(self)
	self.isCreatingNewFarm = true
end
function EditFarmDialog:setColors(colors, defaultColor, defaultColorMaterial)
	for i = #self.colorElements, 1, -1 do
		self.colorElements[i]:delete()
	end
	if #colors == 0 then
		return
	end
	if type(colors[1].color) ~= "table" then
		local newColors = {}
		for i, color in ipairs(colors) do
			newColors[i] = { color = color }
			if table.equalLists(defaultColor, color) then
				defaultColor = newColors[i]
			end
		end
		colors = newColors
	end
	self.colors = colors
	self.colorElements = {}
	self.colorMapping = {}
	self.buttonMapping = {}
	for _, color in ipairs(colors) do
		if color.uiColor ~= nil then
			if table.equalLists(defaultColor, color.uiColor) then
				if defaultColorMaterial == nil or color.material == defaultColorMaterial then
					self.defaultColor = color
				else
				end
			end
		elseif table.equalLists(defaultColor, color.color) then
			if defaultColorMaterial == nil or color.material == defaultColorMaterial then
				self.defaultColor = color
			else
			end
		end
		local buttonWidth = self.buttonTemplate.size[1] + self.buttonTemplate.margin[1] + self.buttonTemplate.margin[3]
		for i, color in ipairs(colors) do
			if color.isSelectable == false then
				continue
			end
			local newColorButton = self.buttonTemplate:clone(self.colorButtonLayout)
			newColorButton:setVisible(true)
			self.colorMapping[newColorButton] = i
			self.buttonMapping[color] = newColorButton
			table.insert(self.colorElements, newColorButton)
			local uiColor = color.color
			if color.uiColor ~= nil then
				uiColor = color.uiColor
			end
			newColorButton:setMaterial(nil)
			newColorButton:setColor(uiColor[1] or 1, uiColor[2] or 1, uiColor[3] or 1)
		end
		self.colorButtonLayout:invalidateLayout()
		local numCols = math.floor(self.colorButtonLayout.size[1] / buttonWidth)
		self:focusLinkColorButtons(numCols)
		self.defaultColorMaterial = defaultColorMaterial
		return
	end
end
function EditFarmDialog:setCallback(callbackFunction, target, args)
	self.callbackFunction = callbackFunction
	self.target = target
	self.args = args
end
function EditFarmDialog:onCreate()
	EditFarmDialog:superClass().onCreate(self)
	self.defaultOkText = self.okButton.text
	self.defaultBackText = self.backButton.text
	self.buttonTemplate:unlinkElement()
	self.buttonTemplate:setVisible(false)
end
function EditFarmDialog:onClickOk()
	if self.currentSelectedElement ~= nil then
		self:onClickColorButton(self.currentSelectedElement)
		return false
	else
		return true
	end
end
function EditFarmDialog:onClickBack(forceBack, usedMenuButton)
	self:sendCallback(nil)
	return false
end
function EditFarmDialog:sendCallback(colorIndex)
	self:close()
	if self.callbackFunction ~= nil then
		if self.target ~= nil then
			self.callbackFunction(self.target, colorIndex, self.args)
			return
		end
		self.callbackFunction(colorIndex, self.args)
	end
end
function EditFarmDialog:onFocusColorButton(element)
	local colorIndex = self.colorMapping[element]
	local color = self.colors[colorIndex]
	self.currentSelectedElement = element
	if self.colorName ~= nil then
		self.colorName:setText(Utils.getNoNil(color.name, ""))
	end
end
function EditFarmDialog:onLeaveColorButton(element)
	if self.colorName ~= nil then
		if self.currentSelectedElement ~= nil then
			local colorIndex = self.colorMapping[self.currentSelectedElement]
			local color = self.colors[colorIndex]
			self.colorName:setText(Utils.getNoNil(color.name, ""))
			return
		end
		self.colorName:setText("")
	end
end
function EditFarmDialog:setButtonTexts(okText, backText)
	self.okButton:setText(Utils.getNoNil(okText, self.defaultOkText))
	self.backButton:setText(Utils.getNoNil(backText, self.defaultBackText))
end
function EditFarmDialog:setExistingFarm(farmId)
	self.farmId = farmId
	self:storeAvailableColors(farmId)
	if farmId ~= nil and farmId ~= FarmManager.INVALID_FARM_ID then
		if farmId ~= FarmManager.SPECTATOR_FARM_ID then
			self.isCreatingNewFarm = false
			local farm = g_farmManager:getFarmById(farmId)
			local titleTemplate = g_i18n:getText(EditFarmDialog.L10N_SYMBOL.TITLE_EDIT_FARM_TEMPLATE)
			local title = string.format(titleTemplate, farm.name)
			self.titleText:setText(title)
			self.farmNameInput:setText(farm.name)
			self.farmPasswordInput:setText(farm.password or "")
			self.selectedColorIndex = farm.color
			self:setButtonTexts(g_i18n:getText(EditFarmDialog.L10N_SYMBOL.BUTTON_CONFIRM))
		else
			self.titleText:setText(g_i18n:getText(EditFarmDialog.L10N_SYMBOL.TITLE_CREATE_FARM))
			self.farmNameInput:setText(g_i18n:getText(EditFarmDialog.L10N_SYMBOL.DEFAULT_FARM_NAME))
			self.farmPasswordInput:setText("")
			self.selectedColorIndex = self.availableColorIndexMap[1]
			self:setButtonTexts(g_i18n:getText(EditFarmDialog.L10N_SYMBOL.BUTTON_CREATE))
		end
	end
	self.farmIconPreview:setImageSlice(nil, Farm.ICON_SLICE_IDS[self.selectedColorIndex])
	self:setColors(self.availableColors, self.availableColors[1])
	self.dialogButtonLayout:invalidateLayout()
end
function EditFarmDialog:storeAvailableColors(editingFarmId)
	self.availableColors = {}
	self.availableColorIndexMap = {}
	local farms = g_farmManager:getFarms()
	for farmColorIndex, color in ipairs(Farm.COLORS) do
		local colorTaken = false
		for _, farm in pairs(farms) do
			if farm.showInFarmScreen then
				if farm.farmId == editingFarmId then
					continue
				end
				if farm.color == farmColorIndex then
					colorTaken = true
					break
				end
			end
		end
		if colorTaken then
			continue
		end
		table.insert(self.availableColors, color)
		self.availableColorIndexMap[#self.availableColors] = farmColorIndex
	end
end
function EditFarmDialog:resizeDialog(heightOffset) end
function EditFarmDialog:focusLinkColorButtons(numCols)
	for i = 1, #self.colorButtonLayout.elements do
		local button = self.colorButtonLayout.elements[i]
		local leftButton = self.colorButtonLayout.elements[i - 1]
		local rightButton = self.colorButtonLayout.elements[i + 1]
		local topButton = self.colorButtonLayout.elements[i - numCols]
		local bottomButton = self.colorButtonLayout.elements[i + numCols]
		if leftButton ~= nil then
			FocusManager:linkElements(button, FocusManager.LEFT, leftButton)
		else
			FocusManager:linkElements(button, FocusManager.LEFT, button)
		end
		if rightButton ~= nil then
			FocusManager:linkElements(button, FocusManager.RIGHT, rightButton)
		else
			FocusManager:linkElements(button, FocusManager.RIGHT, button)
		end
		if topButton ~= nil then
			FocusManager:linkElements(button, FocusManager.TOP, topButton)
		else
			FocusManager:linkElements(button, FocusManager.TOP, button)
		end
		if bottomButton ~= nil then
			FocusManager:linkElements(button, FocusManager.BOTTOM, bottomButton)
		else
			FocusManager:linkElements(button, FocusManager.BOTTOM, button)
		end
	end
	for i = 1, #self.colorButtonLayout.elements do
		local button = self.colorButtonLayout.elements[i]
		FocusManager:linkElements(button, FocusManager.TOP, self.farmPasswordInput)
		FocusManager:linkElements(button, FocusManager.BOTTOM, self.farmNameInput)
	end
	FocusManager:linkElements(self.farmPasswordInput, FocusManager.BOTTOM, self.colorButtonLayout)
end
function EditFarmDialog:onClickColorButton(element)
	local buttonIndex = self.colorMapping[element]
	self.selectedColorIndex = self.availableColorIndexMap[buttonIndex]
	self.farmIconPreview:setImageSlice(nil, Farm.ICON_SLICE_IDS[self.selectedColorIndex])
end
function EditFarmDialog:onClickDone()
	local farmName = self.farmNameInput.text
	local password = self.farmPasswordInput.text
	if password == "" then
		password = nil
	end
	local filteredName = filterText(farmName, true, true)
	if farmName ~= "" then
		if farmName ~= filteredName then
			self.farmNameInput:setText(filteredName)
			Logging.info("Entered farm name contains profanity and has been adjusted.")
		else
			if self.isCreatingNewFarm then
				g_client:getServerConnection():sendEvent(FarmCreateUpdateEvent.new(farmName, self.selectedColorIndex, password, false, nil))
			else
				g_client:getServerConnection():sendEvent(FarmCreateUpdateEvent.new(farmName, self.selectedColorIndex, password, true, self.farmId))
			end
			self:close()
		end
	end
	return false
end
function EditFarmDialog:onClickEdit()
	local focusedElement = FocusManager:getFocusedElement()
	if focusedElement == self.farmNameInput then
		self.farmNameInput:onFocusActivate()
	elseif focusedElement == self.farmPasswordInput then
		self.farmPasswordInput:onFocusActivate()
	else
		for _, button in ipairs(self.colorButtonLayout.elements) do
			if button == focusedElement then
				button:sendAction()
			end
		end
	end
end
EditFarmDialog.L10N_SYMBOL = { TITLE_CREATE_FARM = "ui_createNewFarm", TITLE_EDIT_FARM_TEMPLATE = "ui_editFarm", DEFAULT_FARM_NAME = "ui_defaultFarmName", BUTTON_CREATE = "button_mp_createFarm", BUTTON_CONFIRM = "button_confirm" }
