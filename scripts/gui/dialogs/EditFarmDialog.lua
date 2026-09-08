-- Local values: EditFarmDialog_mt
EditFarmDialog = {}
local EditFarmDialog_mt = Class(EditFarmDialog, MessageDialog)
EditFarmDialog.MAX_COLUMNS = 8
function EditFarmDialog.register()
	local v2_ = EditFarmDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/EditFarmDialog.xml", "EditFarmDialog", v2_)
	EditFarmDialog.INSTANCE = v2_
end

-- Local values: dialog
function EditFarmDialog.show(farmId)
	if EditFarmDialog.INSTANCE ~= nil then
		local v4_ = EditFarmDialog.INSTANCE
		g_gui:showDialog("EditFarmDialog")
		v4_:setExistingFarm(farmId)
	end
end

-- Upvalues: EditFarmDialog_mt
-- Local values: self
function EditFarmDialog.new(target, custom_mt)
	-- upvalues: (copy) EditFarmDialog_mt
	local v7_ = EditFarmDialog:superClass().new(target, custom_mt or EditFarmDialog_mt)
	v7_.farmId = nil
	v7_.isCreatingNewFarm = true
	v7_.availableColorIndexMap = {}
	v7_.availableColors = {}
	v7_.selectedColorIndex = 1
	v7_.currentColorItemList = {}
	v7_.colorsToAdd = {}
	v7_.selectedIndex = 1
	v7_.colorElements = {}
	return v7_
end

-- Local values: farmId
function EditFarmDialog.createFromExistingGui(gui, guiName)
	EditFarmDialog.register()
	local v9_ = gui.farmId
	EditFarmDialog.show(v9_)
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

-- Local values: i, newColors, i, color, _, color, buttonWidth, i, color, newColorButton, uiColor, numCols
function EditFarmDialog:setColors(colors, defaultColor, defaultColorMaterial)
	for v16_ = #self.colorElements, 1, -1 do
		self.colorElements[v16_]:delete()
	end
	if #colors == 0 then
		return
	end
	local v17_ = colors[1].color
	if type(v17_) ~= "table" then
		colors = {}
		for v18_, v19_ in ipairs(colors) do
			colors[v18_] = {
				["color"] = v19_
			}
			if table.equalLists(defaultColor, v19_) then
				defaultColor = colors[v18_]
			end
		end
	end
	self.colors = colors
	self.colorElements = {}
	self.colorMapping = {}
	self.buttonMapping = {}
	for _, v20_ in ipairs(colors) do
		if v20_.uiColor == nil then
			if table.equalLists(defaultColor, v20_.color) and (defaultColorMaterial == nil or v20_.material == defaultColorMaterial) then
				self.defaultColor = v20_
				break
			end
		elseif table.equalLists(defaultColor, v20_.uiColor) and (defaultColorMaterial == nil or v20_.material == defaultColorMaterial) then
			self.defaultColor = v20_
			break
		end
	end
	local v21_ = self.buttonTemplate.size[1] + self.buttonTemplate.margin[1] + self.buttonTemplate.margin[3]
	for v22_, v23_ in ipairs(colors) do
		if v23_.isSelectable ~= false then
			local v24_ = self.buttonTemplate:clone(self.colorButtonLayout)
			v24_:setVisible(true)
			self.colorMapping[v24_] = v22_
			self.buttonMapping[v23_] = v24_
			local v25_ = self.colorElements
			table.insert(v25_, v24_)
			local v26_ = v23_.color
			if v23_.uiColor ~= nil then
				v26_ = v23_.uiColor
			end
			v24_:setMaterial(nil)
			v24_:setColor(v26_[1] or 1, v26_[2] or 1, v26_[3] or 1)
		end
	end
	self.colorButtonLayout:invalidateLayout()
	local v27_ = self.colorButtonLayout.size[1] / v21_
	self:focusLinkColorButtons((math.floor(v27_)))
	self.defaultColorMaterial = defaultColorMaterial
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
	if self.currentSelectedElement == nil then
		return true
	end
	self:onClickColorButton(self.currentSelectedElement)
	return false
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

-- Local values: colorIndex, color
function EditFarmDialog:onFocusColorButton(element)
	local v39_ = self.colorMapping[element]
	local v40_ = self.colors[v39_]
	self.currentSelectedElement = element
	if self.colorName ~= nil then
		self.colorName:setText(Utils.getNoNil(v40_.name, ""))
	end
end

-- Local values: colorIndex, color
function EditFarmDialog:onLeaveColorButton(element)
	if self.colorName ~= nil then
		if self.currentSelectedElement ~= nil then
			local v42_ = self.colorMapping[self.currentSelectedElement]
			local v43_ = self.colors[v42_]
			self.colorName:setText(Utils.getNoNil(v43_.name, ""))
			return
		end
		self.colorName:setText("")
	end
end

function EditFarmDialog:setButtonTexts(okText, backText)
	self.okButton:setText(Utils.getNoNil(okText, self.defaultOkText))
	self.backButton:setText(Utils.getNoNil(backText, self.defaultBackText))
end

-- Local values: farm, titleTemplate, title
function EditFarmDialog:setExistingFarm(farmId)
	self.farmId = farmId
	self:storeAvailableColors(farmId)
	if farmId == nil or (farmId == FarmManager.INVALID_FARM_ID or farmId == FarmManager.SPECTATOR_FARM_ID) then
		self.titleText:setText(g_i18n:getText(EditFarmDialog.L10N_SYMBOL.TITLE_CREATE_FARM))
		self.farmNameInput:setText(g_i18n:getText(EditFarmDialog.L10N_SYMBOL.DEFAULT_FARM_NAME))
		self.farmPasswordInput:setText("")
		self.selectedColorIndex = self.availableColorIndexMap[1]
		self:setButtonTexts(g_i18n:getText(EditFarmDialog.L10N_SYMBOL.BUTTON_CREATE))
	else
		self.isCreatingNewFarm = false
		local v49_ = g_farmManager:getFarmById(farmId)
		local v50_ = g_i18n:getText(EditFarmDialog.L10N_SYMBOL.TITLE_EDIT_FARM_TEMPLATE)
		local v51_ = string.format(v50_, v49_.name)
		self.titleText:setText(v51_)
		self.farmNameInput:setText(v49_.name)
		self.farmPasswordInput:setText(v49_.password or "")
		self.selectedColorIndex = v49_.color
		self:setButtonTexts(g_i18n:getText(EditFarmDialog.L10N_SYMBOL.BUTTON_CONFIRM))
	end
	self.farmIconPreview:setImageSlice(nil, Farm.ICON_SLICE_IDS[self.selectedColorIndex])
	self:setColors(self.availableColors, self.availableColors[1])
	self.dialogButtonLayout:invalidateLayout()
end

-- Local values: farms, farmColorIndex, color, colorTaken, _, farm
function EditFarmDialog:storeAvailableColors(editingFarmId)
	self.availableColors = {}
	self.availableColorIndexMap = {}
	local v54_ = g_farmManager:getFarms()
	for v55_, v56_ in ipairs(Farm.COLORS) do
		local v57_ = false
		for _, v58_ in pairs(v54_) do
			if v58_.showInFarmScreen and (v58_.farmId ~= editingFarmId and v58_.color == v55_) then
				v57_ = true
				break
			end
		end
		if not v57_ then
			local v59_ = self.availableColors
			table.insert(v59_, v56_)
			self.availableColorIndexMap[#self.availableColors] = v55_
		end
	end
end

function EditFarmDialog:resizeDialog(heightOffset) end

-- Local values: i, button, leftButton, rightButton, topButton, bottomButton, i, button
function EditFarmDialog:focusLinkColorButtons(numCols)
	for v62_ = 1, #self.colorButtonLayout.elements do
		local v63_ = self.colorButtonLayout.elements[v62_]
		local v64_ = self.colorButtonLayout.elements[v62_ - 1]
		local v65_ = self.colorButtonLayout.elements[v62_ + 1]
		local v66_ = self.colorButtonLayout.elements[v62_ - numCols]
		local v67_ = self.colorButtonLayout.elements[v62_ + numCols]
		if v64_ == nil then
			FocusManager:linkElements(v63_, FocusManager.LEFT, v63_)
		else
			FocusManager:linkElements(v63_, FocusManager.LEFT, v64_)
		end
		if v65_ == nil then
			FocusManager:linkElements(v63_, FocusManager.RIGHT, v63_)
		else
			FocusManager:linkElements(v63_, FocusManager.RIGHT, v65_)
		end
		if v66_ == nil then
			FocusManager:linkElements(v63_, FocusManager.TOP, v63_)
		else
			FocusManager:linkElements(v63_, FocusManager.TOP, v66_)
		end
		if v67_ == nil then
			FocusManager:linkElements(v63_, FocusManager.BOTTOM, v63_)
		else
			FocusManager:linkElements(v63_, FocusManager.BOTTOM, v67_)
		end
	end
	for v68_ = 1, #self.colorButtonLayout.elements do
		local v69_ = self.colorButtonLayout.elements[v68_]
		FocusManager:linkElements(v69_, FocusManager.TOP, self.farmPasswordInput)
		FocusManager:linkElements(v69_, FocusManager.BOTTOM, self.farmNameInput)
	end
	FocusManager:linkElements(self.farmPasswordInput, FocusManager.BOTTOM, self.colorButtonLayout)
end

-- Local values: buttonIndex
function EditFarmDialog:onClickColorButton(element)
	local v72_ = self.colorMapping[element]
	self.selectedColorIndex = self.availableColorIndexMap[v72_]
	self.farmIconPreview:setImageSlice(nil, Farm.ICON_SLICE_IDS[self.selectedColorIndex])
end

-- Local values: farmName, password, filteredName
function EditFarmDialog:onClickDone()
	local v74_ = self.farmNameInput.text
	local v75_ = self.farmPasswordInput.text
	if v75_ == "" then
		v75_ = nil
	end
	local v76_ = filterText(v74_, true, true)
	if v74_ ~= "" then
		if v74_ == v76_ then
			if self.isCreatingNewFarm then
				g_client:getServerConnection():sendEvent(FarmCreateUpdateEvent.new(v74_, self.selectedColorIndex, v75_, false, nil))
			else
				g_client:getServerConnection():sendEvent(FarmCreateUpdateEvent.new(v74_, self.selectedColorIndex, v75_, true, self.farmId))
			end
			self:close()
		else
			self.farmNameInput:setText(v76_)
			Logging.info("Entered farm name contains profanity and has been adjusted.")
		end
	end
	return false
end

-- Local values: focusedElement, _, button
function EditFarmDialog:onClickEdit()
	local v78_ = FocusManager:getFocusedElement()
	if v78_ == self.farmNameInput then
		self.farmNameInput:onFocusActivate()
		return
	elseif v78_ == self.farmPasswordInput then
		self.farmPasswordInput:onFocusActivate()
	else
		for _, v79_ in ipairs(self.colorButtonLayout.elements) do
			if v79_ == v78_ then
				v79_:sendAction()
			end
		end
	end
end
EditFarmDialog.L10N_SYMBOL = {
	["TITLE_CREATE_FARM"] = "ui_createNewFarm",
	["TITLE_EDIT_FARM_TEMPLATE"] = "ui_editFarm",
	["DEFAULT_FARM_NAME"] = "ui_defaultFarmName",
	["BUTTON_CREATE"] = "button_mp_createFarm",
	["BUTTON_CONFIRM"] = "button_confirm"
}
