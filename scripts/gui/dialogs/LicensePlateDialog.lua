LicensePlateDialog = {}
local LicensePlateDialog_mt = Class(LicensePlateDialog, InfoDialog)
function LicensePlateDialog.register()
	local licensePlateDialog = LicensePlateDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/LicensePlateDialog.xml", "LicensePlateDialog", licensePlateDialog)
	LicensePlateDialog.INSTANCE = licensePlateDialog
end
function LicensePlateDialog.show(licensePlateData, callback, target)
	if LicensePlateDialog.INSTANCE ~= nil then
		local dialog = LicensePlateDialog.INSTANCE
		dialog:setLicensePlateData(licensePlateData)
		dialog:setCallback(callback, target)
		g_gui:showDialog("LicensePlateDialog")
	end
end
function LicensePlateDialog.new(target, custom_mt)
	local self = InfoDialog.new(target, custom_mt or LicensePlateDialog_mt)
	self.currentVariation = 1
	self.currentColorIndex = 1
	return self
end
function LicensePlateDialog.createFromExistingGui(gui, guiName)
	LicensePlateDialog.register()
	local licensePlateData = gui.licensePlateData
	local callback = gui.callbackFunc
	local target = gui.target
	LicensePlateDialog.show(licensePlateData, callback, target)
end
function LicensePlateDialog:delete()
	if self.keyboardButtonTemplate ~= nil then
		self.keyboardButtonTemplate:delete()
	end
	if self.licensePlate ~= nil then
		delete(self.licensePlate.node)
		self.self.licensePlate = nil
	end
	LicensePlateDialog:superClass().delete(self)
end
function LicensePlateDialog:onCreate()
	LicensePlateDialog:superClass().onCreate(self)
	self.keyboardButtonTemplate:unlinkElement()
	FocusManager:removeElement(self.keyboardButtonTemplate)
end
function LicensePlateDialog:onGuiSetupFinished()
	LicensePlateDialog:superClass().onGuiSetupFinished(self)
	local lineSize = (self.contentContainer.absSize[1] - self.headerText:getTextWidth()) / 2 - 20 * g_pixelSizeScaledX
	self.topLineLeft:setSize(lineSize, nil)
	self.topLineRight:setSize(lineSize, nil)
end
function LicensePlateDialog:loadMapData(mapXMLFile, missionInfo, baseDirectory)
	self.sceneRender:createScene()
end
function LicensePlateDialog:unloadMapData()
	self.sceneRender:destroyScene()
end
function LicensePlateDialog:onOpen()
	LicensePlateDialog:superClass().onOpen(self)
	self.needsFirstFocusUpdate = true
	local colors, _ = g_licensePlateManager:getAvailableColors()
	self.changeColorButton.parent:setVisible(1 < #colors)
	self.currentCursorPosition = 1
	self.cursorPositions = {}
	self.sceneRender:setVisible(true)
	self:createKeyboards()
	self:updateLicensePlate()
end
function LicensePlateDialog:onClose()
	LicensePlateDialog:superClass().onClose(self)
	self.sceneRender:setVisible(false)
	if self.licensePlate ~= nil then
		self.licensePlate:delete()
		self.licensePlate = nil
	end
end
function LicensePlateDialog:setLicensePlateData(licensePlateData)
	self.currentVariation = licensePlateData.variation or self.currentVariation
	self.currentCharacters = table.clone(licensePlateData.characters, 5)
	local _, defaultColorIndex = g_licensePlateManager:getAvailableColors()
	self.currentColorIndex = licensePlateData.colorIndex or defaultColorIndex or self.currentColorIndex
	self:updateColorButton()
	self.currentPlacementIndex = licensePlateData.placementIndex or licensePlateData.defaultPlacementIndex or g_licensePlateManager:getDefaultPlacementIndex()
	if licensePlateData.hasFrontPlate ~= false then
		self:updatePlacementOptions()
	else
		self:updatePlacementOptions(LicensePlateManager.PLACEMENT_OPTION.BOTH)
		if self.currentPlacementIndex == LicensePlateManager.PLACEMENT_OPTION.BOTH then
			self.currentPlacementIndex = LicensePlateManager.PLACEMENT_OPTION.BACK_ONLY
		end
	end
	for i = 1, #self.textToPlacementIndex do
		if self.textToPlacementIndex[i] == self.currentPlacementIndex then
			self.placementOption:setState(i)
		end
	end
	self.licensePlateData = licensePlateData
end
function LicensePlateDialog:setCallback(callbackFunction, target, args)
	self.callbackFunction = callbackFunction
	self.target = target
	self.args = args
end
function LicensePlateDialog:sendCallback(variation, characters, colorIndex, placementIndex)
	local licensePlateData = nil
	if variation ~= nil and (characters ~= nil and (colorIndex ~= nil and placementIndex ~= nil)) then
		licensePlateData = { variation = variation, characters = characters, colorIndex = colorIndex, placementIndex = placementIndex }
	end
	if self.callbackFunction ~= nil then
		if self.target ~= nil then
			self.callbackFunction(self.target, licensePlateData, self.args)
			return
		end
		self.callbackFunction(licensePlateData, self.args)
	end
end
function LicensePlateDialog:createKeyboards()
	local font = g_licensePlateManager:getFont()
	local updateButtons = function(characterType, list)
		for i = #list.elements, 1, -1 do
			list.elements[i]:delete()
		end
		local characters = font.charactersByType[characterType]
		for i = 1, #characters do
			local button = self.keyboardButtonTemplate:clone(list)
			local character = characters[i]
			button.keyboardValue = character.value
			button:setText(character.value)
		end
		list:invalidateLayout()
	end
	updateButtons(MaterialManager.FONT_CHARACTER_TYPE.ALPHABETICAL, self.keyboardAlpha)
	updateButtons(MaterialManager.FONT_CHARACTER_TYPE.NUMERICAL, self.keyboardNumeric)
	updateButtons(MaterialManager.FONT_CHARACTER_TYPE.SPECIAL, self.keyboardSpecial)
	self:updateFocusLinking(false, false, false)
end
function LicensePlateDialog:updateFocusLinking(alphabetical, numerical, special)
	local firstAvailableButton = nil
	local lastAvailableButton = nil
	FocusManager:linkElements(self.buttonCursorLeft, FocusManager.RIGHT, self.buttonCursorRight)
	FocusManager:linkElements(self.buttonCursorLeft, FocusManager.LEFT, self.buttonCursorLeft)
	FocusManager:linkElements(self.buttonCursorRight, FocusManager.RIGHT, self.buttonCursorRight)
	FocusManager:linkElements(self.buttonCursorRight, FocusManager.LEFT, self.buttonCursorLeft)
	local numCols = 10
	if alphabetical then
		firstAvailableButton = firstAvailableButton or self.keyboardAlpha.elements[1]
		lastAvailableButton = self.keyboardAlpha.elements[math.floor((#self.keyboardAlpha.elements - 1) / 10) * 10 + 1]
		local above = nil
		for i = 1, #self.keyboardAlpha.elements do
			local button = self.keyboardAlpha.elements[i]
			local leftButton = self.keyboardAlpha.elements[i - 1]
			local rightButton = self.keyboardAlpha.elements[i + 1]
			local topButton = self.keyboardAlpha.elements[i - 10]
			local bottomButton = self.keyboardAlpha.elements[i + 10]
			FocusManager:linkElements(button, FocusManager.LEFT, leftButton or button)
			FocusManager:linkElements(button, FocusManager.RIGHT, rightButton or button)
			if topButton ~= nil then
				FocusManager:linkElements(button, FocusManager.TOP, topButton)
			elseif i <= 5 then
				FocusManager:linkElements(button, FocusManager.TOP, self.buttonCursorLeft)
			else
				FocusManager:linkElements(button, FocusManager.TOP, self.buttonCursorRight)
			end
			if bottomButton ~= nil then
				FocusManager:linkElements(button, FocusManager.BOTTOM, bottomButton)
			else
				local below = self.typeOption
				if numerical then
					below = self.keyboardNumeric.elements[(i - 1) % 10 + 1]
				elseif special then
					below = self.keyboardSpecial.elements[(i - 1) % 10 + 1]
				end
				FocusManager:linkElements(button, FocusManager.BOTTOM, below)
			end
		end
	end
	if numerical then
		firstAvailableButton = firstAvailableButton or self.keyboardNumeric.elements[1]
		lastAvailableButton = self.keyboardNumeric.elements[1]
		for i = 1, #self.keyboardNumeric.elements do
			local button = self.keyboardNumeric.elements[i]
			local leftButton = self.keyboardNumeric.elements[i - 1]
			local rightButton = self.keyboardNumeric.elements[i + 1]
			local topButton = nil
			if alphabetical then
				local index = math.floor((#self.keyboardAlpha.elements - 1) / 10) * 10 + i
				index = math.min(index, #self.keyboardAlpha.elements)
				topButton = self.keyboardAlpha.elements[index]
			end
			local bottomButton = self.typeOption
			if special then
				bottomButton = self.keyboardSpecial.elements[i]
			end
			FocusManager:linkElements(button, FocusManager.LEFT, leftButton or button)
			FocusManager:linkElements(button, FocusManager.RIGHT, rightButton or button)
			if topButton ~= nil then
				FocusManager:linkElements(button, FocusManager.TOP, topButton)
			elseif i <= 5 then
				FocusManager:linkElements(button, FocusManager.TOP, self.buttonCursorLeft)
			else
				FocusManager:linkElements(button, FocusManager.TOP, self.buttonCursorRight)
			end
			if bottomButton == nil then
				continue
			end
			FocusManager:linkElements(button, FocusManager.BOTTOM, bottomButton)
		end
	end
	if special then
		firstAvailableButton = firstAvailableButton or self.keyboardSpecial.elements[1]
		lastAvailableButton = self.keyboardSpecial.elements[1]
		for i = 1, #self.keyboardSpecial.elements do
			local button = self.keyboardSpecial.elements[i]
			local leftButton = self.keyboardSpecial.elements[i - 1]
			local rightButton = self.keyboardSpecial.elements[i + 1]
			local topButton = nil
			if numerical then
				topButton = self.keyboardNumeric.elements[i]
			elseif alphabetical then
				local index = math.floor((#self.keyboardAlpha.elements - 1) / 10) * 10 + i
				index = math.min(index, #self.keyboardAlpha.elements)
				topButton = self.keyboardAlpha.elements[index]
			end
			FocusManager:linkElements(button, FocusManager.LEFT, leftButton or button)
			FocusManager:linkElements(button, FocusManager.RIGHT, rightButton or button)
			if topButton ~= nil then
				FocusManager:linkElements(button, FocusManager.TOP, topButton)
			elseif i <= 5 then
				FocusManager:linkElements(button, FocusManager.TOP, self.buttonCursorLeft)
			else
				FocusManager:linkElements(button, FocusManager.TOP, self.buttonCursorRight)
			end
			FocusManager:linkElements(button, FocusManager.BOTTOM, self.typeOption)
		end
	end
	if firstAvailableButton ~= nil then
		FocusManager:linkElements(self.typeOption, FocusManager.TOP, lastAvailableButton)
		FocusManager:linkElements(self.buttonCursorLeft, FocusManager.BOTTOM, firstAvailableButton)
		FocusManager:linkElements(self.buttonCursorRight, FocusManager.BOTTOM, firstAvailableButton)
		if self.needsFirstFocusUpdate or FocusManager:getFocusedElement() ~= nil and FocusManager:getFocusedElement():getIsDisabled() then
			FocusManager:setFocus(firstAvailableButton)
			self.needsFirstFocusUpdate = false
		end
	end
end
function LicensePlateDialog:updateCursor()
	local positionInfo = self.cursorPositions[self.currentCursorPosition]
	self.cursorElement:setSize(positionInfo.width, positionInfo.height)
	self.cursorElement:setAbsolutePosition(positionInfo.x, positionInfo.y)
	local values = self.licensePlate.variations[self.currentVariation].values
	local value = values[1]
	local realIndex = 1
	for i = 1, #values do
		if values[i].isStatic or values[i].locked then
			continue
		end
		if realIndex == self.currentCursorPosition then
			value = values[i]
			break
		end
		realIndex = realIndex + 1
	end
	for _, element in ipairs(self.keyboardAlpha.elements) do
		local shouldBeDisabled = not value.alphabetical
		if element:getIsDisabled() == shouldBeDisabled then
			continue
		end
		element:setDisabled(shouldBeDisabled)
	end
	for _, element in ipairs(self.keyboardNumeric.elements) do
		local shouldBeDisabled = not value.numerical
		if element:getIsDisabled() == shouldBeDisabled then
			continue
		end
		element:setDisabled(shouldBeDisabled)
	end
	for _, element in ipairs(self.keyboardSpecial.elements) do
		local shouldBeDisabled = not value.special
		if element:getIsDisabled() == shouldBeDisabled then
			continue
		end
		element:setDisabled(shouldBeDisabled)
	end
	self:updateFocusLinking(value.alphabetical, value.numerical, value.special)
end
function LicensePlateDialog:updateVariations()
	local texts = {}
	local typeText = g_i18n:getText("ui_licensePlateTypeItem")
	for i = 1, #self.licensePlate.variations do
		table.insert(texts, string.format(typeText, i))
	end
	self.typeOption:setTexts(texts)
	self.typeOption:setState(self.currentVariation)
end
function LicensePlateDialog:updateColorButton()
	if self.licensePlate ~= nil then
		local r, g, b = unpack(self.licensePlate:getColor(self.currentColorIndex))
		self.changeColorButtonImage:setImageColor(nil, math.clamp(r, 0, 1), math.clamp(g, 0, 1), math.clamp(b, 0, 1), 1)
	end
end
function LicensePlateDialog:updateLicensePlateGraphics()
	self.licensePlate:updateData(self.currentVariation, LicensePlateManager.PLATE_POSITION.BACK, table.concat(self.currentCharacters, ""))
	self.licensePlate:setColorIndex(self.currentColorIndex)
	self:updateColorButton()
	self.sceneRender:setRenderDirty()
	self.sceneRender:setVisible(true)
	local values = g_licensePlateManager:getLicensePlateValues(self.licensePlate, self.currentVariation)
	self.cursorPositions = {}
	local camera = I3DUtil.indexToObject(self.sceneRender.scene, self.sceneRender.cameraPath)
	local offsetX = 2 * g_pixelSizeX
	local offsetY = 8 * g_pixelSizeY
	local lx, ly, lz = localToWorld(self.licensePlate.node, self.licensePlate.width * 0.5, self.licensePlate.height * 0.5, 0)
	local plateEdgeX, plateEdgeY, _ = projectToCamera(camera, 3, lx, ly, lz)
	local _, fontHeight = self.licensePlate:getFontSize()
	local fontHeightScreen = (plateEdgeY - 0.5) * 2 * (fontHeight / self.licensePlate.height) * self.sceneRender.size[2] + offsetY
	if values ~= nil then
		for _, value in ipairs(values) do
			if value.isStatic or value.locked then
				continue
			end
			local valueWidth = (plateEdgeX - 0.5) * 2 * (value.maxWidthRatio * fontHeight / self.licensePlate.width) * self.sceneRender.size[1] + offsetX
			local node, _ = I3DUtil.indexToObject(self.licensePlate.node, value.nodePath)
			local x, y, z = getWorldTranslation(node)
			local cursorX, cursorY, _ = projectToCamera(camera, 3, x, y, z)
			cursorX = cursorX * self.sceneRender.size[1] + self.sceneRender.absPosition[1] - valueWidth * 0.5
			cursorY = cursorY * self.sceneRender.size[2] + self.sceneRender.absPosition[2] - fontHeightScreen * 0.5
			table.insert(self.cursorPositions, { x = cursorX, y = cursorY, width = valueWidth, height = fontHeightScreen, valueIndex = value.index })
		end
	end
	self.currentCursorPosition = math.min(self.currentCursorPosition, #self.cursorPositions)
	self:updateCursor()
end
function LicensePlateDialog:onCreatePlacementOption(element)
	self.placementOption = element
	self:updatePlacementOptions()
end
function LicensePlateDialog:updatePlacementOptions(excluded)
	self.textToPlacementIndex = {}
	local texts = {}
	for index, text in pairs(LicensePlateManager.PLACEMENT_OPTION_TEXT) do
		if index == excluded then
			continue
		end
		table.insert(texts, g_i18n:getText(text))
		self.textToPlacementIndex[#texts] = index
	end
	self.placementOption:setTexts(texts)
	self.placementOption:setState(1)
end
function LicensePlateDialog:onClickBack()
	self:sendCallback(nil)
	LicensePlateDialog:superClass().onClickBack(self)
end
function LicensePlateDialog:onClickChangeColor()
	local colors, defaultColorIndex = g_licensePlateManager:getAvailableColors()
	colors = table.clone(colors, math.huge)
	if 1 < #colors then
		ColorPickerDialog.show(self.onPickedColor, self, nil, colors, defaultColorIndex, nil, nil, nil, true)
	end
	return true
end
function LicensePlateDialog:onPickedColor(colorIndex, args, customColor)
	if colorIndex ~= nil then
		self.currentColorIndex = colorIndex
		self:updateLicensePlateGraphics()
	end
end
function LicensePlateDialog:onClickOk()
	self.currentCharacters = self.licensePlate:validateLicensePlateCharacters(self.currentCharacters)
	self:sendCallback(self.currentVariation, self.currentCharacters, self.currentColorIndex, self.currentPlacementIndex)
	LicensePlateDialog:superClass().onClickOk(self)
end
function LicensePlateDialog:onRenderLoad(scene, overlay)
	setTranslation(scene, 0, -1, 0)
	setName(scene, "LicensePlateDialog_" .. getName(scene))
	self.licensePlaceLinkNode = I3DUtil.indexToObject(scene, "0|0")
end
function LicensePlateDialog:updateLicensePlate()
	if self.licensePlaceLinkNode ~= nil then
		local licensePlate = g_licensePlateManager:getLicensePlate(LicensePlateManager.PLATE_TYPE.ELONGATED)
		if licensePlate ~= nil then
			link(self.licensePlaceLinkNode, licensePlate.node)
			setTranslation(licensePlate.node, 0, 0, 0)
			setRotation(licensePlate.node, 0, 0, 0)
			self.licensePlate = licensePlate
			if self.currentCharacters == nil then
				self.currentCharacters = self.licensePlate:getRandomCharacters(self.currentVariation)
			end
			local cameraNode = I3DUtil.indexToObject(self.sceneRender.scene, self.sceneRender.cameraPath)
			if cameraNode ~= nil then
				local fovY = getFovY(cameraNode)
				local tolerance = 0.005
				local distanceWidth = (self.licensePlate.width / 2 + 0.005) / math.tan(fovY / 2) / (self.sceneRender.size[1] / self.sceneRender.size[2] * g_screenAspectRatio)
				local distanceHeight = (self.licensePlate.height / 2 + 0.005) / math.tan(fovY / 2)
				local distance = math.max(distanceWidth, distanceHeight)
				setTranslation(cameraNode, 0, 0, distance)
			end
			self:updateLicensePlateGraphics()
			self:updateVariations()
		end
	end
end
function LicensePlateDialog:onClickKeyboardButton(element)
	self.currentCharacters[self.cursorPositions[self.currentCursorPosition].valueIndex] = element.keyboardValue
	self:updateLicensePlateGraphics()
	self:onClickCursorRight()
end
function LicensePlateDialog:onClickCursorLeft()
	self.currentCursorPosition = self.currentCursorPosition - 1
	if self.currentCursorPosition < 1 then
		self.currentCursorPosition = #self.cursorPositions
	end
	self:updateCursor()
end
function LicensePlateDialog:onClickCursorRight()
	self.currentCursorPosition = self.currentCursorPosition + 1
	if #self.cursorPositions < self.currentCursorPosition then
		self.currentCursorPosition = 1
	end
	self:updateCursor()
end
function LicensePlateDialog:onClickPlacementOptionChanged(selection)
	self.currentPlacementIndex = self.textToPlacementIndex[selection]
end
function LicensePlateDialog:onClickTypeOptionChanged(selection)
	self.currentVariation = selection
	self.currentCharacters = self.licensePlate:getRandomCharacters(self.currentVariation)
	self:updateLicensePlateGraphics()
end
function LicensePlateDialog:setButtonTexts(okText) end
function LicensePlateDialog:setButtonAction(buttonAction) end
function LicensePlateDialog:keyEvent(unicode, sym, modifier, isDown, eventUsed)
	if LicensePlateDialog:superClass().keyEvent(self, unicode, sym, modifier, isDown, eventUsed) then
		return true
	else
		if isDown then
			if sym == Input.KEY_backspace then
				if 1 < self.currentCursorPosition then
					self:onClickCursorLeft()
					return true
				end
			else
				local value = self.licensePlate.variations[self.currentVariation].values[self.cursorPositions[self.currentCursorPosition].valueIndex]
				local charValue = self:getUnicodeToKeyboardValue(unicode, value)
				if charValue ~= nil then
					self.currentCharacters[self.cursorPositions[self.currentCursorPosition].valueIndex] = charValue
					self:updateLicensePlateGraphics()
					self:onClickCursorRight()
				end
				return true
			end
		end
		return false
	end
end
function LicensePlateDialog:getUnicodeToKeyboardValue(unicode, value)
	local text = utf8ToUpper(unicodeToUtf8(unicode))
	local font = g_licensePlateManager:getFont()
	local check = function(characterType)
		local characters = font.charactersByType[characterType]
		for i = 1, #characters do
			if text == utf8ToUpper(characters[i].value) then
				return characters[i].value
			end
		end
		return nil
	end
	if value.alphabetical then
		local result = check(MaterialManager.FONT_CHARACTER_TYPE.ALPHABETICAL)
		if result ~= nil then
			return result
		end
	end
	if value.numerical then
		local result = check(MaterialManager.FONT_CHARACTER_TYPE.NUMERICAL)
		if result ~= nil then
			return result
		end
	end
	if value.special then
		local result = check(MaterialManager.FONT_CHARACTER_TYPE.SPECIAL)
		if result ~= nil then
			return result
		end
	end
	return nil
end
