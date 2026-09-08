-- Local values: ColorPickerDialog_mt
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
	local v2_ = ColorPickerDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/ColorPickerDialog.xml", "ColorPickerDialog", v2_)
	ColorPickerDialog.INSTANCE = v2_
end

-- Local values: dialog
function ColorPickerDialog.show(callback, target, args, colors, defaultColorIndex, defaultMaterial, customColor, customColorsEnabled, disableOpenSound, materialSelectionDisabled)
	if ColorPickerDialog.INSTANCE ~= nil then
		local v13_ = ColorPickerDialog.INSTANCE
		v13_.dialogColors = colors
		v13_.dialogDefaultColorIndex = defaultColorIndex
		v13_.dialogCustomColor = customColor
		v13_.dialogDefaultMaterial = defaultMaterial
		v13_:setCustomOptionsEnabled(customColorsEnabled, materialSelectionDisabled)
		v13_:setCallback(callback, target, args)
		v13_:setDisableOpenSound(disableOpenSound)
		g_gui:showDialog("ColorPickerDialog")
	end
end

-- Upvalues: ColorPickerDialog_mt
-- Local values: self
function ColorPickerDialog.new(target, custom_mt)
	-- upvalues: (copy) ColorPickerDialog_mt
	local v16_ = ColorPickerDialog:superClass().new(target, custom_mt or ColorPickerDialog_mt)
	v16_.colorElements = {}
	v16_.customColorsDirty = false
	v16_.customColors = {}
	v16_.customRenderColor = {
		1,
		0,
		0,
		1
	}
	v16_.accumHorizontalInput = 0
	v16_.accumVerticalInput = 0
	v16_.lastColorButtonClickTime = 0
	return v16_
end

-- Local values: callback, target, callbackArgs, colors, defaultColor, defaultColorMaterial
function ColorPickerDialog.createFromExistingGui(gui, guiName)
	ColorPickerDialog.register()
	local v18_ = gui.callbackFunction
	local v19_ = gui.target
	local v20_ = gui.args
	local v21_ = gui.colors
	local v22_ = gui.colors[gui.defaultColorIndex] or gui.colors[1]
	local v23_ = gui.defaultColorMaterial
	ColorPickerDialog.show(v18_, v19_, v20_, v21_, v22_, v23_)
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

-- Local values: lineSize, index, button, hueTexts, rgbTexts, i
function ColorPickerDialog:onGuiSetupFinished()
	ColorPickerDialog:superClass().onGuiSetupFinished(self)
	local v28_ = (self.contentContainer.absSize[1] - self.headerText:getTextWidth()) / 2 - 20 * g_pixelSizeScaledX
	self.topLineLeft:setSize(v28_, nil)
	self.topLineRight:setSize(v28_, nil)
	for v_u_29_, v30_ in pairs(self.subCategoryTabs) do
		v30_:getDescendantByName("background").getIsSelected = function()
			-- upvalues: (copy) v_u_29_, (copy) self
			return v_u_29_ == self.pageSelector:getState()
		end
		function v30_.getIsSelected()
			-- upvalues: (copy) v_u_29_, (copy) self
			return v_u_29_ == self.pageSelector:getState()
		end
	end
	local v31_ = {}
	local v32_ = {}
	for v33_ = 0, 360 do
		local v34_ = tostring(v33_)
		table.insert(v31_, v34_)
		if v33_ <= 255 then
			local v35_ = tostring(v33_)
			table.insert(v32_, v35_)
		end
	end
	self.hueSlider:setTexts(v31_)
	self.rgbRed:setTexts(v32_)
	self.rgbGreen:setTexts(v32_)
	self.rgbBlue:setTexts(v32_)
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
	if self.customColorsEnabled and self.dialogCustomColor ~= nil then
		self:setCustomColorRGB(self.dialogCustomColor)
		self:onClickCustom()
	elseif self.colors == nil or self.colors[self.dialogDefaultColorIndex] == nil then
		self:onHueChanged(1)
		self:setCustomColorHSV(0, 1, 1)
		self:onClickList()
	else
		self:setCustomColorRGB(self.colors[self.dialogDefaultColorIndex].color)
		self:onClickList()
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

-- Local values: index, material
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
	if self.dialogDefaultMaterial == nil then
		self.materialPicker:setState(1, true)
	else
		for v41_, v42_ in pairs(ColorPickerDialog.MATERIAL_TEXTS) do
			if v42_.materialName == self.dialogDefaultMaterial then
				self.materialPicker:setState(v41_, true)
				break
			end
		end
	end
	self.customColorsEnabled = customColorsEnabled
	self.materialSelectionDisabled = materialSelectionDisabled
end

-- Local values: i, defaultColor, newColors, i, color, i, color, index, color, numSelectableColors, buttonWidth, buttonHeight, numCols, numRows, i, color, newColorButton, uiColor, r, g, b, i, newColorButton
function ColorPickerDialog:setColors(colors, defaultColorIndex, defaultColorMaterial)
	for v47_ = #self.colorElements, 1, -1 do
		self.colorElements[v47_]:delete()
	end
	local v48_ = nil
	if #colors > 0 then
		local v49_ = colors[1].color
		if type(v49_) == "table" then
			if defaultColorIndex == nil then
				if self.dialogCustomColor ~= nil then
					for v50_, v51_ in ipairs(colors) do
						if v51_[1] == self.dialogCustomColor[1] and (v51_[2] == self.dialogCustomColor[2] and v51_[3] == self.dialogCustomColor[3]) then
							v48_ = colors[v50_]
						end
					end
					v48_ = v48_ or colors[1]
				end
			else
				self.lastListButtonIndex = defaultColorIndex
			end
		else
			colors = {}
			for v52_, v53_ in ipairs(colors) do
				colors[v52_] = {
					["color"] = v53_
				}
			end
			v48_ = colors[defaultColorIndex or 1]
		end
	end
	self.colors = colors
	self.colorElements = {}
	self.colorMapping = {}
	self.buttonMapping = {}
	self.layoutMapping = {}
	if self.lastListButtonIndex == nil then
		if v48_ == nil then
			self.lastListButtonIndex = 1
		else
			for v54_, v55_ in ipairs(colors) do
				if v55_.uiColor == nil then
					if (table.equalLists(v48_, v55_.color) or table.equalLists(v48_, v55_)) and (defaultColorMaterial == nil or v55_.material == defaultColorMaterial) then
						self.lastListButtonIndex = v54_
						break
					end
				elseif table.equalLists(v48_, v55_.uiColor) and (defaultColorMaterial == nil or v55_.material == defaultColorMaterial) then
					self.lastListButtonIndex = v54_
					break
				end
			end
		end
	end
	local v56_ = self.buttonTemplate.size[1] + self.buttonTemplate.margin[1] + self.buttonTemplate.margin[3]
	local v57_ = self.buttonTemplate.size[2] + self.buttonTemplate.margin[2] + self.buttonTemplate.margin[4]
	local v58_ = self.colorButtonLayout.absSize[1] / v56_
	local v59_ = math.floor(v58_)
	local v60_ = self.colorButtonLayout.absSize[2] / v57_
	local v61_ = math.floor(v60_)
	local v62_ = 0
	for v63_, v64_ in ipairs(colors) do
		if v64_.isSelectable ~= false then
			local v65_ = self.buttonTemplate:clone(self.colorButtonLayout)
			v65_:setVisible(true)
			self.colorMapping[v65_] = v63_
			self.buttonMapping[v64_] = v65_
			v62_ = v62_ + 1
			self.layoutMapping[v65_] = v62_
			local v66_ = self.colorElements
			table.insert(v66_, v65_)
			local v67_ = v64_.color
			if v64_.uiColor ~= nil then
				v67_ = v64_.uiColor
			end
			if v64_.materialName == ColorPickerDialog.MATERIAL_TEXTS[ColorPickerDialog.MATERIAL_MATTE].materialName then
				v65_:setIsMatte(true)
			else
				v65_:setIsMetallic(v64_.materialName == ColorPickerDialog.MATERIAL_TEXTS[ColorPickerDialog.MATERIAL_METALLIC].materialName)
			end
			if v64_.isMat then
				v65_:setIsMatte(true)
			end
			if v64_.isMetallic then
				v65_:setIsMetallic(true)
			end
			local v68_
			if v67_[1] == nil then
				v68_ = 1
			else
				local v69_ = v67_[1]
				v68_ = math.clamp(v69_, 0, 1) or 1
			end
			local v70_
			if v67_[2] == nil then
				v70_ = 1
			else
				local v71_ = v67_[2]
				v70_ = math.clamp(v71_, 0, 1) or 1
			end
			local v72_
			if v67_[3] == nil then
				v72_ = 1
			else
				local v73_ = v67_[3]
				v72_ = math.clamp(v73_, 0, 1) or 1
			end
			v65_:setColor(v68_, v70_, v72_)
			if v63_ == self.lastListButtonIndex then
				self.lastListButtonIndex = #self.colorElements
			end
		end
	end
	for _ = #self.colorButtonLayout.elements + 1, v61_ * v59_ do
		local v74_ = self.buttonTemplate:clone(self.colorButtonLayout)
		v74_:setVisible(true)
		local v75_ = self.colorElements
		table.insert(v75_, v74_)
		v74_:setColor(0, 0, 0, 0.15)
		v74_:setMaterial()
		v74_.handleFocus = false
		v74_:setDisabled(true)
	end
	self.colorButtonLayout:invalidateLayout()
	self:focusLinkColorButtons(v59_)
	self:setInitialFocus()
	self.defaultColorMaterial = defaultColorMaterial
end

-- Local values: i, button, leftButton, rightButton, topButton, bottomButton
function ColorPickerDialog:focusLinkColorButtons(numCols)
	for v78_ = 1, #self.colorButtonLayout.elements do
		local v79_ = self.colorButtonLayout.elements[v78_]
		local v80_ = self.colorButtonLayout.elements[v78_ - 1]
		local v81_ = self.colorButtonLayout.elements[v78_ + 1]
		local v82_ = self.colorButtonLayout.elements[v78_ - numCols]
		local v83_ = self.colorButtonLayout.elements[v78_ + numCols]
		if v80_ == nil then
			FocusManager:linkElements(v79_, FocusManager.LEFT, nil)
		else
			FocusManager:linkElements(v79_, FocusManager.LEFT, v80_)
		end
		if v81_ == nil then
			FocusManager:linkElements(v79_, FocusManager.RIGHT, v79_)
		else
			FocusManager:linkElements(v79_, FocusManager.RIGHT, v81_)
		end
		if v82_ == nil then
			FocusManager:linkElements(v79_, FocusManager.TOP, nil)
		else
			FocusManager:linkElements(v79_, FocusManager.TOP, v82_)
		end
		if v83_ == nil then
			FocusManager:linkElements(v79_, FocusManager.BOTTOM, nil)
		else
			FocusManager:linkElements(v79_, FocusManager.BOTTOM, v83_)
		end
	end
end

-- Local values: elem, lastIndex, subCategoryIndex
function ColorPickerDialog:setInitialFocus()
	local v85_
	if #self.colorElements > 0 then
		local v86_ = nil
		local v87_ = self.pageSelector:getState()
		if v87_ == ColorPickerDialog.CATEGORY_LIST then
			local v88_ = self.lastListButtonIndex or 1
			local v89_ = #self.colors
			v86_ = math.clamp(v88_, 1, v89_)
		elseif v87_ == ColorPickerDialog.CATEGORY_FAVORITES and (self.customColors ~= nil and #self.customColors > 0) then
			local v90_ = self.lastFavoritesButtonIndex or 1
			local v91_ = #self.customColors
			v86_ = math.clamp(v90_, 1, v91_)
		end
		v85_ = self.colorElements[v86_]
	else
		v85_ = nil
	end
	if v85_ ~= nil then
		self.currentSelectedElement = v85_
		self.blockFocusDelegate = true
		FocusManager:setFocus(v85_)
		self.blockFocusDelegate = false
	end
end

function ColorPickerDialog:setCallback(callbackFunction, target, args)
	self.callbackFunction = callbackFunction
	self.target = target
	self.args = args
end

-- Local values: r, g, b
function ColorPickerDialog:setCustomColorHSV(hue, saturation, value)
	if saturation ~= nil and value ~= nil then
		self.cursor:setAbsolutePosition(self.customPicker.absPosition[1] + self.customPicker.absSize[1] * saturation - self.cursor.absSize[1] * 0.5, self.customPicker.absPosition[2] + self.customPicker.absSize[2] * value - self.cursor.absSize[2] * 0.5)
	end
	if not saturation then
		local v100_ = (self.cursor.absPosition[1] + self.cursor.absSize[1] * 0.5 - self.customPicker.absPosition[1]) / self.customPicker.absSize[1]
		saturation = math.clamp(v100_, 0, 1)
	end
	if not value then
		local v101_ = (self.cursor.absPosition[2] + self.cursor.absSize[2] * 0.5 - self.customPicker.absPosition[2]) / self.customPicker.absSize[2]
		value = math.clamp(v101_, 0, 1)
	end
	local v102_, v103_, v104_ = GuiUtils.hsvToRGB(hue / 360, saturation, value)
	if not self.blockStateUpdate then
		local v105_ = self.rgbRed
		local v106_ = v102_ * 255
		v105_:setState(math.round(v106_) + 1)
		local v107_ = self.rgbGreen
		local v108_ = v103_ * 255
		v107_:setState(math.round(v108_) + 1)
		local v109_ = self.rgbBlue
		local v110_ = v104_ * 255
		v109_:setState(math.round(v110_) + 1)
	end
	self.customRenderColor = { math.pow(v102_, 2.2), math.pow(v103_, 2.2), (math.pow(v104_, 2.2)) }
	self.needsRenderColorUpdate = true
end

-- Local values: r, g, b, hue, saturation, value, r2, g2, b2
function ColorPickerDialog:setCustomColorRGB(color)
	local v113_, v114_, v115_ = unpack(color)
	local v116_ = math.pow(v113_, 0.45454545454545453)
	local v117_ = math.pow(v114_, 0.45454545454545453)
	local v118_ = math.pow(v115_, 0.45454545454545453)
	local v119_, v120_, v121_ = GuiUtils.rgbToHSV(v116_, v117_, v118_)
	local v122_, v123_, v124_ = GuiUtils.hsvToRGB(v119_)
	local v125_ = math.pow(v122_, 2.2)
	local v126_ = math.pow(v123_, 2.2)
	local v127_ = math.pow(v124_, 2.2)
	self.customPicker:setImageColor(nil, v125_, v126_, v127_, 1)
	local v128_ = v119_ * 360
	local v129_ = math.round(v128_)
	self.hueSlider:setState(v129_ + 1)
	self.cursor:setAbsolutePosition(self.customPicker.absPosition[1] + self.customPicker.absSize[1] * v120_ - self.cursor.absSize[1] * 0.5, self.customPicker.absPosition[2] + self.customPicker.absSize[2] * v121_ - self.cursor.absSize[2] * 0.5)
	if not self.blockStateUpdate then
		local v130_ = self.rgbRed
		local v131_ = v116_ * 255
		v130_:setState(math.round(v131_) + 1)
		local v132_ = self.rgbGreen
		local v133_ = v117_ * 255
		v132_:setState(math.round(v133_) + 1)
		local v134_ = self.rgbBlue
		local v135_ = v118_ * 255
		v134_:setState(math.round(v135_) + 1)
	end
	self.customRenderColor = { math.pow(v116_, 2.2), math.pow(v117_, 2.2), (math.pow(v118_, 2.2)) }
	self.needsRenderColorUpdate = true
end

function ColorPickerDialog:onCreate()
	ColorPickerDialog:superClass().onCreate(self)
	self.defaultOkText = self.okButton.text
	self.defaultBackText = self.backButton.text
	self.buttonTemplate:unlinkElement()
	FocusManager:removeElement(self.buttonTemplate)
end

-- Local values: inputHelpMode, moveActions, cursor, customPicker, offsetX, offsetY, cursorX, cursorY, material, templateName, sphereNodeId
function ColorPickerDialog:update(dt)
	ColorPickerDialog:superClass().update(self, dt)
	local v139_ = g_inputBinding:getInputHelpMode()
	if v139_ ~= self.lastInputHelpMode then
		self.cursorGlyphBox:setVisible(g_inputBinding:getInputHelpMode() == GS_INPUT_HELP_MODE_GAMEPAD)
		self.customPickerLayout:invalidateLayout()
		local v140_ = { InputAction.AXIS_PICK_COLOR_UPDOWN, InputAction.AXIS_PICK_COLOR_LEFTRIGHT }
		self.cursorGlyph:setActions(v140_, nil, nil, true)
		self.lastInputHelpMode = v139_
	end
	if self.accumVerticalInput ~= 0 or self.accumHorizontalInput ~= 0 then
		local v141_ = self.cursor
		local v142_ = self.customPicker
		ColorPickerDialog.INPUT_SCALE = 20000
		local v143_ = self.accumHorizontalInput * dt / ColorPickerDialog.INPUT_SCALE
		local v144_ = -self.accumVerticalInput * dt / (ColorPickerDialog.INPUT_SCALE / g_screenAspectRatio)
		local v145_ = v141_.absPosition[1] + v143_
		local v146_ = v142_.absPosition[1] - v141_.absSize[1] * 0.5
		local v147_ = v142_.absPosition[1] + v142_.absSize[1] - v141_.absSize[1] * 0.5
		local v148_ = math.clamp(v145_, v146_, v147_)
		local v149_ = v141_.absPosition[2] + v144_
		local v150_ = v142_.absPosition[2] - v141_.absSize[2] * 0.5
		local v151_ = v142_.absPosition[2] + v142_.absSize[2] - v141_.absSize[2] * 0.5
		v141_:setAbsolutePosition(v148_, (math.clamp(v149_, v150_, v151_)))
		self:setCustomColorHSV(self.hueSlider:getState() - 1)
		self.accumVerticalInput = self.accumVerticalInput * 0.5
		self.accumHorizontalInput = self.accumHorizontalInput * 0.5
		local v152_ = self.accumVerticalInput
		if math.abs(v152_) <= ColorPickerDialog.INPUT_THRESHOLD then
			self.accumVerticalInput = 0
		end
		local v153_ = self.accumHorizontalInput
		if math.abs(v153_) <= ColorPickerDialog.INPUT_THRESHOLD then
			self.accumHorizontalInput = 0
		end
	end
	if self.needsRenderColorUpdate and not self.colorRender.isLoading then
		local v154_ = VehicleMaterial.new()
		v154_:setTemplateName(ColorPickerDialog.MATERIAL_TEXTS[self.materialPicker:getState()].materialName)
		v154_:setColor(self.customRenderColor)
		v154_:apply((getChildAt(getChildAt(self.colorRender.scene, 0), 0)))
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
	local v160_ = self.addToFavoritesButton
	local v161_
	if subCategoryIndex == ColorPickerDialog.CATEGORY_CUSTOM then
		v161_ = #self.customColors < ColorPickerDialog.MAX_NUM_CUSTOM_COLORS
	else
		v161_ = false
	end
	v160_:setVisible(v161_)
	self.okButton:setVisible(subCategoryIndex ~= ColorPickerDialog.CATEGORY_FAVORITES and true or #self.colors > 0)
	local v162_ = self.deleteButton
	local v163_
	if subCategoryIndex == ColorPickerDialog.CATEGORY_FAVORITES then
		v163_ = #self.colors > 0
	else
		v163_ = false
	end
	v162_:setVisible(v163_)
	local v164_ = self.renameButton
	local v165_
	if subCategoryIndex == ColorPickerDialog.CATEGORY_FAVORITES then
		v165_ = #self.colors > 0
	else
		v165_ = false
	end
	v164_:setVisible(v165_)
	self.buttonsBox:invalidateLayout()
end

-- Local values: hue, r, g, b
function ColorPickerDialog:onHueChanged(hueState)
	local v168_ = hueState - 1
	local v169_, v170_, v171_ = GuiUtils.hsvToRGB(v168_ / 360)
	local v172_ = math.pow(v169_, 2.2)
	local v173_ = math.pow(v170_, 2.2)
	local v174_ = math.pow(v171_, 2.2)
	self.customPicker:setImageColor(nil, v172_, v173_, v174_, 1)
	self:setCustomColorHSV(v168_)
end

-- Local values: r, g, b, hue, saturation, value
function ColorPickerDialog:onRGBChanged()
	local v176_ = (self.rgbRed:getState() - 1) / 255
	local v177_ = (self.rgbGreen:getState() - 1) / 255
	local v178_ = (self.rgbBlue:getState() - 1) / 255
	local v179_, v180_, v181_ = GuiUtils.rgbToHSV(v176_, v177_, v178_)
	local v182_ = v179_ * 360
	local v183_ = math.round(v182_)
	if v183_ + 1 ~= self.hueSlider:getState() then
		self.blockStateUpdate = true
		self.hueSlider:setState(v183_ + 1, true)
		self.blockStateUpdate = false
	end
	self.cursor:setAbsolutePosition(self.customPicker.absPosition[1] + self.customPicker.absSize[1] * v180_ - self.cursor.absSize[1] * 0.5, self.customPicker.absPosition[2] + self.customPicker.absSize[2] * v181_ - self.cursor.absSize[2] * 0.5)
	self.blockStateUpdate = true
	self:setCustomColorHSV(v183_, v180_, v181_)
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

-- Local values: r, g, b
function ColorPickerDialog:onCustomColorNameEntered(name)
	local v189_ = MathUtil.round((self.rgbRed:getState() - 1) / 255, 5)
	local v190_ = math.pow(v189_, 2.2)
	local v191_ = MathUtil.round((self.rgbGreen:getState() - 1) / 255, 5)
	local v192_ = math.pow(v191_, 2.2)
	local v193_ = MathUtil.round((self.rgbBlue:getState() - 1) / 255, 5)
	local v194_ = math.pow(v193_, 2.2)
	local v195_ = self.customColors
	local v196_ = {
		["name"] = name,
		["color"] = { v190_, v192_, v194_ },
		["materialName"] = ColorPickerDialog.MATERIAL_TEXTS[self.materialPicker:getState()].materialName
	}
	table.insert(v195_, v196_)
	if #self.customColors >= ColorPickerDialog.MAX_NUM_CUSTOM_COLORS then
		self.addToFavoritesButton:setVisible(false)
		self.buttonsBox:invalidateLayout()
	end
	self.customColorsDirty = true
end

-- Local values: colorIndex
function ColorPickerDialog:onYesNoDeleteFromFavorites(yes)
	if yes then
		local v199_ = self.colorMapping[self.currentSelectedElement]
		table.remove(self.customColors, v199_)
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

-- Local values: colorIndex
function ColorPickerDialog:onCustomColorRenamed(name)
	local v203_ = self.colorMapping[self.currentSelectedElement]
	self.customColors[v203_].name = name
	self:setColors(self.customColors)
	self.customColorsDirty = true
end

-- Local values: r, g, b, customColor, colorIndex, customColor, colorIndex, colorIndex
function ColorPickerDialog:onClickOk()
	if self.customColorsEnabled then
		if self.pageSelector:getState() == ColorPickerDialog.CATEGORY_CUSTOM then
			self:setColors(self.dialogColors, self.dialogDefaultColorIndex, self.dialogDefaultMaterial)
			local v205_ = (self.rgbRed:getState() - 1) / 255
			local v206_ = math.pow(v205_, 2.2)
			local v207_ = (self.rgbGreen:getState() - 1) / 255
			local v208_ = math.pow(v207_, 2.2)
			local v209_ = (self.rgbBlue:getState() - 1) / 255
			self:sendCallback(nil, {
				["customColor"] = { v206_, v208_, (math.pow(v209_, 2.2)) },
				["templateName"] = ColorPickerDialog.MATERIAL_TEXTS[self.materialPicker:getState()].materialName
			})
			return
		elseif self.pageSelector:getState() == ColorPickerDialog.CATEGORY_FAVORITES then
			local v210_ = self.colorMapping[self.currentSelectedElement]
			self:sendCallback(nil, {
				["customColor"] = table.clone(self.customColors[v210_].color),
				["templateName"] = self.customColors[v210_].materialName or ColorPickerDialog.MATERIAL_TEXTS[ColorPickerDialog.MATERIAL_GLOSSY].materialName
			})
		else
			self:sendCallback(self.colorMapping[self.currentSelectedElement])
		end
	else
		self:sendCallback(self.colorMapping[self.currentSelectedElement])
		return
	end
end

function ColorPickerDialog:onClickColorButton(element)
	if self.lastColorButtonClickTime + ColorPickerDialog.DOUBLE_CLICK_INTERVAL >= g_time then
		self:onClickOk()
	else
		self:onActivateColorButton(element)
		self.lastColorButtonClickTime = g_time
	end
end

-- Local values: colorIndex, layoutIndex, color, materialName, subCategoryIndex, r, g, b, index, material
function ColorPickerDialog:onActivateColorButton(element)
	local v215_ = self.colorMapping[element]
	local v216_ = self.layoutMapping[element]
	local v217_ = self.colors[v215_].color
	local v218_ = self.colors[v215_].materialName
	local v219_ = self.pageSelector:getState()
	if v219_ == ColorPickerDialog.CATEGORY_LIST then
		self.lastListButtonIndex = v216_
		self.lastFavoritesButtonIndex = nil
	elseif v219_ == ColorPickerDialog.CATEGORY_FAVORITES then
		self.lastListButtonIndex = nil
		self.lastFavoritesButtonIndex = v216_
	end
	if self.customColorsEnabled then
		local v220_ = v217_[1]
		local v221_ = math.pow(v220_, 0.45454545454545453) * 255
		local v222_ = math.round(v221_) + 1
		local v223_ = v217_[2]
		local v224_ = math.pow(v223_, 0.45454545454545453) * 255
		local v225_ = math.round(v224_) + 1
		local v226_ = v217_[3]
		local v227_ = math.pow(v226_, 0.45454545454545453) * 255
		local v228_ = math.round(v227_) + 1
		self.rgbRed:setState(v222_)
		self.rgbGreen:setState(v225_)
		self.rgbBlue:setState(v228_, true)
		if v218_ ~= nil then
			for v229_, v230_ in pairs(ColorPickerDialog.MATERIAL_TEXTS) do
				if v230_.materialName == v218_ then
					self.materialPicker:setState(v229_)
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

-- Local values: colorIndex, color
function ColorPickerDialog:onFocusColorButton(element)
	if not self.blockFocusDelegate then
		self:onActivateColorButton(element)
	end
	local v237_ = self.colorMapping[element]
	local v238_ = self.colors[v237_]
	self.currentSelectedElement = element
	if self.colorName ~= nil then
		self.colorName:setText(Utils.getNoNil(v238_.name, ""))
		self.colorNameBox:invalidateLayout()
	end
end

-- Local values: colorIndex, color
function ColorPickerDialog:onHighlightColorButton(element)
	local v241_ = self.colorMapping[element]
	local v242_ = self.colors[v241_]
	if self.colorName ~= nil then
		self.colorName:setText(Utils.getNoNil(v242_.name, ""))
		self.colorNameBox:invalidateLayout()
	end
end

-- Local values: colorIndex, color
function ColorPickerDialog:onLeaveColorButton(element)
	if self.colorName ~= nil then
		if self.currentSelectedElement == nil then
			self.colorName:setText("")
			self.colorNameBox:invalidateLayout()
		else
			local v244_ = self.colorMapping[self.currentSelectedElement]
			local v245_ = self.colors[v244_]
			if v245_ ~= nil then
				self.colorName:setText(Utils.getNoNil(v245_.name, ""))
				self.colorNameBox:invalidateLayout()
				return
			end
		end
	end
end

function ColorPickerDialog:setButtonTexts(okText, backText)
	self.okButton:setText(Utils.getNoNil(okText, self.defaultOkText))
	self.backButton:setText(Utils.getNoNil(backText, self.defaultBackText))
end

-- Local values: offsetX, offsetY, isInPicker, cursorX, cursorY
function ColorPickerDialog:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	local v254_ = 20 * g_pixelSizeX
	local v255_ = 20 * g_pixelSizeY
	if GuiUtils.checkOverlayOverlap(posX, posY, self.customPicker.absPosition[1] - v254_, self.customPicker.absPosition[2] - v255_, self.customPicker.absSize[1] + v254_ * 2, self.customPicker.absSize[2] + v255_ * 2) and self.customPicker:getIsVisible() then
		if isDown then
			self.inputDown = true
		end
		if self.inputDown then
			local v256_ = self.customPicker.absPosition[1]
			local v257_ = self.customPicker.absPosition[1] + self.customPicker.absSize[1]
			local v258_ = math.clamp(posX, v256_, v257_)
			local v259_ = self.customPicker.absPosition[2]
			local v260_ = self.customPicker.absPosition[2] + self.customPicker.absSize[2]
			local v261_ = math.clamp(posY, v259_, v260_)
			self.cursor:setAbsolutePosition(v258_ - self.cursor.absSize[1] * 0.5, v261_ - self.cursor.absSize[2] * 0.5)
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
local v266_ = {
	{
		["text"] = "material_glossy",
		["materialName"] = "calibratedGlossPaint"
	},
	{
		["text"] = "material_metallic",
		["materialName"] = "calibratedMetallicPaint"
	},
	{
		["text"] = "material_matte",
		["materialName"] = "calibratedMatPaint"
	}
}
ColorPickerDialog.MATERIAL_TEXTS = v266_
