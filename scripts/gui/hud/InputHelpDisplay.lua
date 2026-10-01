local data = nil
if InputHelpDisplay ~= nil then
	local old = g_currentMission.hud.inputHelp
	data = {}
	data.uiScale = old.uiScale
	data.isVisible = old:getVisible()
	data.vehicle = old.vehicle
	old:delete()
end
InputHelpDisplay = {}
InputHelpDisplay.MAX_NUM_ELEMENTS = 6
InputHelpDisplay.MAX_NUM_ELEMENTS_HIGH_PRIORITY = 16
InputHelpDisplay.MAX_SCHEMA_COLLECTION_DEPTH = 5
InputHelpDisplay.SCHEMA_OVERLAY_DEFINITIONS_PATH = "dataS/vehicleSchemaOverlays.xml"
local InputHelpDisplay_mt = Class(InputHelpDisplay, HUDDisplay)
function InputHelpDisplay.new()
	local self = InputHelpDisplay:superClass().new(InputHelpDisplay_mt)
	self.vehicle = nil
	self.extraHelpTexts = {}
	self.helpExtensions = {}
	self.infoExtensions = {}
	self.skipActions = {}
	local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
	self.lineBg = g_overlayManager:createOverlay("gui.shortcutBox1", 0, 0, 0, 0)
	self.lineBg:setColor(r, g, b, a)
	self.lineBgLeft = g_overlayManager:createOverlay("gui.shortcutBox1_left", 0, 0, 0, 0)
	self.lineBgLeft:setColor(r, g, b, a)
	self.lineBgScale = g_overlayManager:createOverlay("gui.shortcutBox1_middle", 0, 0, 0, 0)
	self.lineBgScale:setColor(r, g, b, a)
	self.lineBgRight = g_overlayManager:createOverlay("gui.shortcutBox1_right", 0, 0, 0, 0)
	self.lineBgRight:setColor(r, g, b, a)
	self.comboBg = g_overlayManager:createOverlay("gui.shortcutBox2", 0, 0, 0, 0)
	self.comboBg:setColor(r, g, b, a)
	self.comboText = utf8ToUpper(g_i18n:getText("ui_controlsAdvanced"))
	self.controlGroupText = utf8ToUpper(g_i18n:getText("ui_controlsControlGroup"))
	self.glyphButtonOverlay = GlyphButtonOverlay.new()
	self.glyphButtonOverlay:setColor(nil, nil, nil, nil, 0, 0, 0, 0.8)
	self.keyButtonOverlay = ButtonOverlay.new()
	self.keyButtonOverlay:setColor(nil, nil, nil, nil, 0, 0, 0, 0.8)
	self.separatorHorizontal = g_overlayManager:createOverlay(g_plainColorSliceId, 0, 0, 0, 0)
	self.separatorHorizontal:setColor(1, 1, 1, 0.25)
	self.separatorVertical = g_overlayManager:createOverlay(g_plainColorSliceId, 0, 0, 0, 0)
	self.separatorVertical:setColor(1, 1, 1, 0.25)
	local inputDisplayManager = g_inputDisplayManager
	self.mouseComboOverlays = {}
	for _, combo in ipairs(InputBinding.ORDERED_MOUSE_COMBOS) do
		local actionName = combo.controls
		local helpElement = inputDisplayManager:getControllerSymbolOverlays(actionName, "", "", false)
		local overlays = {}
		for _, button in ipairs(helpElement.buttons) do
			table.insert(overlays, button)
		end
		table.insert(self.mouseComboOverlays, { actionName = actionName, overlays = overlays, mask = combo.mask })
	end
	self:updateGamepadComboButtons()
	self.vehicle = nil
	self.vehicleSchemaOverlays = {}
	self.iconSizeX = 0
	self.iconSizeY = 0
	self.maxSchemaWidth = 0
	g_messageCenter:subscribe(MessageType.INPUT_DEVICES_CHANGED, self.updateGamepadComboButtons, self)
	return self
end
function InputHelpDisplay:delete()
	self.lineBg:delete()
	self.lineBgLeft:delete()
	self.lineBgScale:delete()
	self.lineBgRight:delete()
	self.comboBg:delete()
	self.glyphButtonOverlay:delete()
	self.keyButtonOverlay:delete()
	self.separatorHorizontal:delete()
	self.separatorVertical:delete()
	for k, v in pairs(self.vehicleSchemaOverlays) do
		v:delete()
		self.vehicleSchemaOverlays[k] = nil
	end
	g_messageCenter:unsubscribe(MessageType.INPUT_DEVICES_CHANGED, self)
	InputHelpDisplay:superClass().delete(self)
end
function InputHelpDisplay:storeScaledValues()
	self:setPosition(g_hudAnchorLeft, g_hudAnchorTop)
	local lineWidth, lineHeight = self:scalePixelValuesToScreenVector(330, 25)
	self.lineBg:setDimension(lineWidth, lineHeight)
	self.helpAnchorOffsetX, self.helpAnchorOffsetY = self:scalePixelValuesToScreenVector(340, -25)
	local partWidth = self:scalePixelToScreenWidth(6)
	self.lineBgLeft:setDimension(partWidth, lineHeight)
	self.lineBgScale:setDimension(0, lineHeight)
	self.lineBgRight:setDimension(partWidth, lineHeight)
	local comboWidth, comboHeight = self:scalePixelValuesToScreenVector(330, 50)
	self.comboBg:setDimension(comboWidth, comboHeight)
	self.lineOffsetY = self:scalePixelToScreenHeight(5)
	self.textSize = self:scalePixelToScreenHeight(12)
	self.textOffsetX, self.textOffsetY = self:scalePixelValuesToScreenVector(14, 8)
	self.comboTextOffsetX, self.comboTextOffsetY = self:scalePixelValuesToScreenVector(14, 32)
	self.comboSeparatorOffsetX, self.comboSeparatorOffsetY = self:scalePixelValuesToScreenVector(0, 24)
	self.comboIconWidth, self.comboIconHeight = self:scalePixelValuesToScreenVector(24, 24)
	self.separatorHorizontal:setDimension(lineWidth, g_pixelSizeY)
	local verticalSeparatorHeight = self:scalePixelToScreenHeight(24)
	self.separatorVertical:setDimension(g_pixelSizeX, verticalSeparatorHeight)
	self.keyButtonOverlay:setMinWidth(self:scalePixelToScreenWidth(35))
	self.glyphButtonOverlay:setMinWidth(self:scalePixelToScreenWidth(35))
	self.schemaOffsetX, self.schemaOffsetY = self:scalePixelValuesToScreenVector(14, 2)
	self.iconSizeX, self.iconSizeY = self:scalePixelValuesToScreenVector(26, 26)
	self.maxSchemaWidth = self:scalePixelToScreenWidth(180)
	for _, overlay in pairs(self.vehicleSchemaOverlays) do
		overlay:resetDimensions()
		local pixelSize = { overlay.defaultWidth, overlay.defaultHeight }
		local width, height = self:scalePixelToScreenVector(pixelSize)
		overlay:setDimension(width, height)
	end
end
function InputHelpDisplay:draw(offsetX, offsetY)
	local isVisible = self:getVisible()
	local posX, posY = self:getPosition()
	local vehicleControlPosY = nil
	posX = posX + (offsetX or 0)
	posY = posY + (offsetY or 0)
	posY, vehicleControlPosY = self:drawVehicleSchema(posX, posY, not isVisible)
	if not isVisible then
		return
	end
	local inputBinding = g_inputBinding
	local inputDisplayManager = g_inputDisplayManager
	local pressedComboMaskGamepad, pressedComboMaskMouse = inputBinding:getComboCommandPressedMask()
	local currentPressedMask = (GS_IS_CONSOLE_VERSION or inputBinding:getInputHelpMode() == GS_INPUT_HELP_MODE_GAMEPAD) and pressedComboMaskGamepad or pressedComboMaskMouse
	local isCombo = currentPressedMask ~= 0
	local comboActionStatus = inputDisplayManager:getComboHelpElements(useGamepadButtons)
	local hasComboCommands = next(comboActionStatus) ~= nil
	local eventHelpElements = inputDisplayManager:getEventHelpElements(currentPressedMask, useGamepadButtons)
	if (eventHelpElements == nil or #eventHelpElements == 0) and (not hasComboCommands and isCombo) then
		eventHelpElements = inputDisplayManager:getEventHelpElements(0, useGamepadButtons)
	end
	table.sort(self.helpExtensions, function(a, b)
		return a.priority < b.priority
	end)
	table.sort(self.infoExtensions, function(a, b)
		if a.priority ~= b.priority then
			return a.priority < b.priority
		elseif a.vehicle ~= nil and (b.vehicle ~= nil and (a.vehicle.lastDistanceToCamera ~= nil and b.vehicle.lastDistanceToCamera ~= nil)) then
			return a.vehicle.lastDistanceToCamera < b.vehicle.lastDistanceToCamera
		else
			return true
		end
	end)
	local helpExtensionTotalHeight = 0
	for i = #self.helpExtensions, 1, -1 do
		local helpExtension = self.helpExtensions[i]
		if helpExtension.setEventHelpElements ~= nil then
			helpExtension:setEventHelpElements(self, eventHelpElements)
		end
		local height = helpExtension:getHeight()
		if 0 < height then
			helpExtensionTotalHeight = helpExtensionTotalHeight + height + self.lineOffsetY
		else
			table.remove(self.helpExtensions, i)
		end
	end
	local infoExtensionTotalHeight = 0
	for i = #self.infoExtensions, 1, -1 do
		local infoExtension = self.infoExtensions[i]
		if infoExtension.setEventHelpElements ~= nil then
			infoExtension:setEventHelpElements(self, eventHelpElements)
		end
		local height = infoExtension:getHeight()
		if 0 < height then
			infoExtensionTotalHeight = infoExtensionTotalHeight + height + self.lineOffsetY
		else
			table.remove(self.infoExtensions, i)
		end
	end
	local ignoreComboButtons = false
	if hasComboCommands then
		ignoreComboButtons = true
		posY = posY - self.comboBg.height
		self.comboBg:renderCustom(posX, posY)
		setTextBold(true)
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextColor(1, 1, 1, 1)
		renderText(posX + self.comboTextOffsetX, posY + self.comboTextOffsetY, self.textSize, self.comboText)
		self.separatorHorizontal:renderCustom(posX + self.comboSeparatorOffsetX, posY + self.comboSeparatorOffsetY)
		local combos = self.mouseComboOverlays
		local pressedComboMask = pressedComboMaskMouse
		if useGamepadButtons then
			combos = self.gamepadComboOverlays
			pressedComboMask = pressedComboMaskGamepad
		end
		local numCombos = #combos
		local widthPerCombo = self.comboBg.width / numCombos
		local activeColor = HUD.COLOR.ACTIVE
		local iconPosX = posX
		for k, comboInfo in ipairs(combos) do
			if comboActionStatus[comboInfo.actionName] then
				local isPressed = bit32.band(pressedComboMask, comboInfo.mask) ~= 0
				local r = 1
				local g = 1
				local b = 1
				local a = 1
				if isPressed then
					r = activeColor[1]
					g = activeColor[2]
					b = activeColor[3]
					a = activeColor[4]
				end
				local numOverlays = #comboInfo.overlays
				local spaceX = widthPerCombo - self.comboIconWidth * numOverlays
				local spacingX = spaceX / (numOverlays + 3)
				local overlayPosX = iconPosX + 2 * spacingX
				for _, overlay in ipairs(comboInfo.overlays) do
					overlay:renderCustom(overlayPosX, posY, self.comboIconWidth, self.comboIconHeight, r, g, b, a)
					overlayPosX = overlayPosX + spacingX + self.comboIconWidth
				end
			end
			if k < numCombos then
				iconPosX = iconPosX + widthPerCombo
				self.separatorVertical:renderCustom(iconPosX, posY)
			end
		end
		posY = posY - self.lineOffsetY
	end
	local numElements = 0
	for k, extension in pairs(self.helpExtensions) do
		if extension.priority <= GS_PRIO_LOW then
			numElements = numElements + 1
		end
	end
	if eventHelpElements ~= nil then
		for k, helpElement in ipairs(eventHelpElements) do
			if self.skipActions[helpElement.actionName] == nil then
				if helpElement.actionName == InputAction.SWITCH_IMPLEMENT then
					if vehicleControlPosY ~= nil then
						local buttons = helpElement.buttons
						local isComboButtonMapping = helpElement.isComboButtonMapping
						local keys = helpElement.keys
						local lineBg = self.lineBg
						local lineHeight = lineBg.height
						vehicleControlPosY = vehicleControlPosY - lineHeight
						if 0 < #buttons then
							local totalWidth = self.glyphButtonOverlay:getButtonWidth(buttons, isComboButtonMapping, true, lineHeight)
							local startPosX = posX + lineBg.width - totalWidth
							self.glyphButtonOverlay:renderButton(buttons, isComboButtonMapping, true, startPosX, vehicleControlPosY, lineHeight)
						elseif 0 < #keys then
							local startPosX = posX + lineBg.width
							for i = #keys, 1, -1 do
								local key = keys[i]
								local keyWidth = self.keyButtonOverlay:getButtonWidth(key, lineHeight)
								local width = keyWidth + g_pixelSizeX
								startPosX = startPosX - width
								self.keyButtonOverlay:renderButton(key, startPosX, vehicleControlPosY, lineHeight, true)
							end
						end
					else
						posY = self:drawInputHelpElement(posX, posY, helpElement, ignoreComboButtons)
						posY = posY - self.lineOffsetY
					end
				end
				numElements = numElements + 1
				local maxNumElements = helpElement.priority <= GS_PRIO_HIGH and InputHelpDisplay.MAX_NUM_ELEMENTS_HIGH_PRIORITY or InputHelpDisplay.MAX_NUM_ELEMENTS
				if not (maxNumElements < numElements) then
					continue
				end
				for k, extension in pairs(self.helpExtensions) do
					local maxNumElements = extension.priority <= GS_PRIO_LOW and InputHelpDisplay.MAX_NUM_ELEMENTS_HIGH_PRIORITY or InputHelpDisplay.MAX_NUM_ELEMENTS
					if numElements < maxNumElements then
						posY = extension:draw(self, posX, posY)
						posY = posY - self.lineOffsetY
						numElements = numElements + 1
					end
					self.helpExtensions[k] = nil
				end
				for k, extension in pairs(self.infoExtensions) do
					local newPosY = extension:draw(self, posX, posY)
					if newPosY ~= posY then
						posY = newPosY - self.lineOffsetY
					end
					self.infoExtensions[k] = nil
				end
				for k, text in pairs(self.extraHelpTexts) do
					posY = self:drawExtraText(posX, posY, text)
					posY = posY - self.lineOffsetY
					self.extraHelpTexts[k] = nil
				end
				return
			else
				self.skipActions[helpElement.actionName] = nil
			end
		end
	end
end
function InputHelpDisplay:drawInputHelpElement(posX, posYTop, helpElement, ignoreComboButtons)
	local lineBg = self.lineBg
	local lineHeight = lineBg.height
	local posY = posYTop - lineHeight
	lineBg:renderCustom(posX, posY)
	local buttons = helpElement.buttons
	local isComboButtonMapping = helpElement.isComboButtonMapping
	local keys = helpElement.keys
	local maxWidth = lineBg.width
	if 0 < #buttons then
		local totalWidth = self.glyphButtonOverlay:getButtonWidth(buttons, isComboButtonMapping, ignoreComboButtons, lineHeight)
		local startPosX = posX + lineBg.width - totalWidth
		self.glyphButtonOverlay:renderButton(buttons, isComboButtonMapping, ignoreComboButtons, startPosX, posY, lineHeight)
		maxWidth = maxWidth - totalWidth
	elseif 0 < #keys then
		local startPosX = posX + lineBg.width
		for i = #keys, 1, -1 do
			local key = keys[i]
			local keyWidth = self.keyButtonOverlay:getButtonWidth(key, lineHeight)
			local width = keyWidth + g_pixelSizeX
			startPosX = startPosX - width
			maxWidth = maxWidth - width
			self.keyButtonOverlay:renderButton(key, startPosX, posY, lineHeight, true)
		end
	end
	local iconOverlay = helpElement.iconOverlay
	if iconOverlay ~= nil then
		local iconWidth = lineHeight / g_screenAspectRatio
		iconOverlay:renderCustom(posX + self.textOffsetX, posY, iconWidth, lineHeight, 1, 1, 1, 1)
		return posY
	else
		local textOffsetX = self.textOffsetX
		local textOffsetY = self.textOffsetY
		setTextBold(true)
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextColor(1, 1, 1, 1)
		local text = utf8ToUpper(helpElement.text)
		text = Utils.limitTextToWidth(text, self.textSize, maxWidth - 2 * textOffsetX, false, "...")
		renderText(posX + textOffsetX, posY + textOffsetY, self.textSize, text)
		return posY
	end
end
function InputHelpDisplay:drawInput(posX, posY, height, helpElement, lastButtonCustomOffsetLeft, customButtonInputText)
	local buttons = helpElement.buttons
	local isComboButtonMapping = helpElement.isComboButtonMapping
	local keys = helpElement.keys
	local width = 0
	if 0 < #buttons then
		width = self.glyphButtonOverlay:getButtonWidth(buttons, isComboButtonMapping, true, height, lastButtonCustomOffsetLeft, customButtonInputText)
		local startPosX = posX - width
		self.glyphButtonOverlay:renderButton(buttons, isComboButtonMapping, true, startPosX, posY, height, false, nil, nil, nil, nil, lastButtonCustomOffsetLeft, customButtonInputText)
		return width
	else
		if 0 < #keys then
			local startPosX = posX
			for i = #keys, 1, -1 do
				local key = keys[i]
				local offset = i == #keys and lastButtonCustomOffsetLeft or 0
				local keyWidth = self.keyButtonOverlay:getButtonWidth(key, height, offset, customButtonInputText)
				startPosX = startPosX - keyWidth
				width = width + keyWidth + g_pixelSizeX
				self.keyButtonOverlay:renderButton(key, startPosX, posY, height, true, nil, nil, nil, nil, offset, customButtonInputText)
				startPosX = startPosX - g_pixelSizeX
			end
		end
		return width
	end
end
function InputHelpDisplay:drawExtraText(posX, posYTop, text)
	local lineBg = self.lineBg
	local posY = posYTop - lineBg.height
	lineBg:renderCustom(posX, posY)
	local textOffsetX = self.textOffsetX
	local textOffsetY = self.textOffsetY
	local maxWidth = lineBg.width - 2 * textOffsetX
	setTextBold(true)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextColor(1, 1, 1, 1)
	text = utf8ToUpper(text)
	text = Utils.limitTextToWidth(text, self.textSize, maxWidth, false, "...")
	renderText(posX + textOffsetX, posY + textOffsetY, self.textSize, text)
	return posY
end
function InputHelpDisplay:drawVehicleSchema(posX, posY, isShortVersion)
	local vehicle = self.vehicle
	if vehicle == nil or vehicle.schemaOverlay == nil then
		return posY, nil
	end
	local minX = nil
	local maxX = nil
	local vehicleControlPosY = posY
	vehicle = vehicle.rootVehicle
	self:getVehicleSchemaOverlays(vehicle)
	minX, maxX = self:getSchemaDelimiters()
	if isShortVersion then
		local lineBg = self.lineBg
		local lineHeight = lineBg.height
		posY = posY - lineHeight
		local scale = maxX - minX + 2 * self.schemaOffsetX - 2 * self.lineBgLeft.width
		self.lineBgScale:setDimension(scale, nil)
		self.lineBgLeft:setPosition(posX, posY)
		self.lineBgScale:setPosition(self.lineBgLeft.x + self.lineBgLeft.width, posY)
		self.lineBgRight:setPosition(self.lineBgScale.x + self.lineBgScale.width, posY)
		self.lineBgLeft:render()
		self.lineBgScale:render()
		self.lineBgRight:render()
	else
		posY = posY - self.comboBg.height
		self.comboBg:renderCustom(posX, posY)
		setTextBold(true)
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextColor(1, 1, 1, 1)
		renderText(posX + self.comboTextOffsetX, posY + self.comboTextOffsetY, self.textSize, self.controlGroupText)
		self.separatorHorizontal:renderCustom(posX + self.comboSeparatorOffsetX, posY + self.comboSeparatorOffsetY)
	end
	local scale = 1
	local sizeX = maxX - minX
	if self.maxSchemaWidth < sizeX then
		scale = self.maxSchemaWidth / sizeX
	end
	posX = posX - minX + self.schemaOffsetX
	posY = posY + self.schemaOffsetY
	for _, overlayDesc in ipairs(self.schemaOverlayEntryCache) do
		if overlayDesc.isUsed then
			local overlay = overlayDesc.overlay
			local width = overlay.width
			local height = overlay.height
			overlay:setInvertX(overlayDesc.invertX)
			overlay:setPosition(posX + overlayDesc.x, posY + overlayDesc.y)
			overlay:setRotation(overlayDesc.rotation, 0, 0)
			overlay:setDimension(width * scale, height * scale)
			local color = overlayDesc.turnedOn and HUD.COLOR.ACTIVE or HUD.COLOR.DEFAULT
			overlay:setColor(color[1], color[2], color[3], overlayDesc.selected and 1 or 0.5)
			overlay:render()
			if overlayDesc.additionalText ~= nil then
				local textPosX = posX + overlayDesc.x + width * scale * 0.5
				local textPosY = posY + overlayDesc.y + height * scale * 0.85
				setTextBold(false)
				setTextColor(1, 1, 1, 1)
				setTextAlignment(RenderText.ALIGN_CENTER)
				renderText(textPosX, textPosY, getCorrectTextSize(0.008), overlayDesc.additionalText)
				setTextAlignment(RenderText.ALIGN_LEFT)
				setTextColor(1, 1, 1, 1)
			end
			overlay:setDimension(width, height)
		end
		overlayDesc.isUsed = false
	end
	self.schemaOverlayEntryCacheIndex = 0
	posY = posY - self.lineOffsetY
	return posY, vehicleControlPosY
end
function InputHelpDisplay:addSkipAction(actionName)
	self.skipActions[actionName] = true
end
function InputHelpDisplay:addHelpText(text)
	if not self:getVisible() then
		return
	else
		table.insert(self.extraHelpTexts, text)
	end
end
function InputHelpDisplay:addHelpExtension(extension)
	if not self:getVisible() then
		return
	else
		table.addElement(self.helpExtensions, extension)
	end
end
function InputHelpDisplay:addInfoExtension(extension)
	if not self:getVisible() then
		return
	else
		table.addElement(self.infoExtensions, extension)
	end
end
function InputHelpDisplay:removeInfoExtension(extension)
	table.removeElement(self.infoExtensions, extension)
end
function InputHelpDisplay:setVehicle(vehicle)
	self.vehicle = vehicle
end
function InputHelpDisplay:updateGamepadComboButtons()
	local inputDisplayManager = g_inputDisplayManager
	self.gamepadComboOverlays = {}
	for _, combo in ipairs(InputBinding.ORDERED_GAMEPAD_COMBOS) do
		local actionName = combo.controls
		local helpElement = inputDisplayManager:getControllerSymbolOverlays(actionName, "", "", false)
		local overlays = {}
		for _, button in ipairs(helpElement.buttons) do
			table.insert(overlays, button)
		end
		table.insert(self.gamepadComboOverlays, { actionName = actionName, overlays = overlays, mask = combo.mask })
	end
end
function InputHelpDisplay:getSchemaOverlayForState(schemaOverlayData, isImplement, iconOverride)
	local schemaName = nil
	schemaName = schemaOverlayData.schemaName
	if schemaName == "DEFAULT_IMPLEMENT" then
		schemaName = "IMPLEMENT"
	elseif schemaName == "DEFAULT_VEHICLE" then
		schemaName = "VEHICLE"
	end
	if not schemaName or schemaName == "" or self.vehicleSchemaOverlays[schemaName] == nil then
		schemaName = isImplement and VehicleSchemaOverlayData.SCHEMA_OVERLAY.IMPLEMENT or VehicleSchemaOverlayData.SCHEMA_OVERLAY.VEHICLE
	end
	return self.vehicleSchemaOverlays[schemaName]
end
function InputHelpDisplay:getSchemaDelimiters()
	local minX = math.huge
	local maxX = -math.huge
	for _, overlayDesc in ipairs(self.schemaOverlayEntryCache) do
		if overlayDesc.isUsed then
			local overlay = overlayDesc.overlay
			local cosRot = math.cos(overlayDesc.rotation)
			local sinRot = math.sin(overlayDesc.rotation)
			local offX = overlayDesc.invisibleBorderLeft * overlay.width
			local dx = overlay.width + (overlayDesc.invisibleBorderRight + overlayDesc.invisibleBorderLeft) * overlay.width
			local dy = overlay.height
			local x = overlayDesc.x + offX * cosRot
			local dx2 = dx * cosRot
			local dx3 = -dy * sinRot
			local dx4 = dx2 + dx3
			maxX = math.max(maxX, x, x + dx2, x + dx3, x + dx4)
			minX = math.min(minX, x, x + dx2, x + dx3, x + dx4)
		end
	end
	return minX, maxX
end
function InputHelpDisplay:getVehicleSchemaOverlays(vehicle)
	local overlay = self:getSchemaOverlayForState(vehicle.schemaOverlay, false)
	local entry = self:getOrCreateEntry()
	entry.isUsed = true
	entry.overlay = overlay
	entry.additionalText = vehicle:getAdditionalSchemaText()
	entry.x = 0
	entry.y = 0
	entry.rotation = 0
	entry.invertX = false
	entry.invisibleBorderRight = vehicle.schemaOverlay.invisibleBorderRight
	entry.invisibleBorderLeft = vehicle.schemaOverlay.invisibleBorderLeft
	entry.turnedOn = vehicle:getUseTurnedOnSchema()
	entry.selected = vehicle:getIsSelected()
	self:collectVehicleSchemaDisplayOverlays(1, vehicle, vehicle, overlay, 0, 0, 0, false)
	return overlay.height
end
function InputHelpDisplay:collectVehicleSchemaDisplayOverlays(depth, vehicle, rootVehicle, parentOverlay, x, y, rotation, invertingX)
	if vehicle.getAttachedImplements == nil then
		return
	else
		local attachedImplements = vehicle:getAttachedImplements()
		for _, implement in pairs(attachedImplements) do
			local object = implement.object
			if object == nil or object.schemaOverlay == nil then
				continue
			end
			local selected = object:getIsSelected()
			local turnedOn = object:getUseTurnedOnSchema()
			local jointDesc = vehicle.schemaOverlay.attacherJoints[implement.jointDescIndex]
			if jointDesc == nil then
				continue
			end
			local invertX = invertingX ~= jointDesc.invertX
			local overlay = self:getSchemaOverlayForState(object.schemaOverlay, true)
			local baseY = y + jointDesc.y * parentOverlay.height
			local baseX = nil
			baseX = invertX and x + jointDesc.x * parentOverlay.width or x - overlay.width + (1 - jointDesc.x) * parentOverlay.width
			local rot = rotation + jointDesc.rotation
			local offsetX = nil
			local offsetY = nil
			offsetX = invertX and -object.schemaOverlay.offsetX * overlay.width or object.schemaOverlay.offsetX * overlay.width
			offsetY = object.schemaOverlay.offsetY * overlay.height
			local rotatedX = offsetX * math.cos(rot) - offsetY * math.sin(rot)
			local rotatedY = offsetX * math.sin(rot) + offsetY * math.cos(rot)
			baseX = baseX - rotatedX
			baseY = baseY - rotatedY
			local isLowered = false
			if object.getIsLowered ~= nil then
				isLowered = object:getIsLowered(true)
			end
			if not isLowered then
				local widthOffset, heightOffset = getNormalizedScreenValues(jointDesc.liftedOffsetX, jointDesc.liftedOffsetY)
				baseX = baseX + widthOffset
				baseY = baseY + heightOffset * 0.5
			end
			local additionalText = object:getAdditionalSchemaText()
			local entry = self:getOrCreateEntry()
			entry.isUsed = true
			entry.overlay = overlay
			entry.additionalText = additionalText
			entry.x = baseX
			entry.y = baseY
			entry.rotation = rot
			entry.invertX = not invertX
			entry.invisibleBorderRight = object.schemaOverlay.invisibleBorderRight
			entry.invisibleBorderLeft = object.schemaOverlay.invisibleBorderLeft
			entry.turnedOn = turnedOn
			entry.selected = selected
			if depth <= InputHelpDisplay.MAX_SCHEMA_COLLECTION_DEPTH then
				self:collectVehicleSchemaDisplayOverlays(depth + 1, object, rootVehicle, overlay, baseX, baseY, rot, invertX)
			end
		end
	end
end
function InputHelpDisplay:getOrCreateEntry()
	if self.schemaOverlayEntryCache == nil then
		self.schemaOverlayEntryCache = table.create(10)
		self.schemaOverlayEntryCacheIndex = 0
	end
	self.schemaOverlayEntryCacheIndex = self.schemaOverlayEntryCacheIndex + 1
	local entry = self.schemaOverlayEntryCache[self.schemaOverlayEntryCacheIndex]
	if entry == nil then
		entry = { isUsed = false, overlay = nil, additionalText = nil, x = 0, y = 0, rotation = 0, invertX = false, invisibleBorderRight = 0, invisibleBorderLeft = 0, turnedOn = false, selected = false }
		table.insert(self.schemaOverlayEntryCache, entry)
	end
	return entry
end
function InputHelpDisplay:loadVehicleSchemaOverlays()
	local xmlFile = loadXMLFile("VehicleSchemaDisplayOverlays", InputHelpDisplay.SCHEMA_OVERLAY_DEFINITIONS_PATH)
	self:loadVehicleSchemaOverlaysFromXML(xmlFile)
	delete(xmlFile)
	for _, modDesc in ipairs(g_modManager:getActiveMods()) do
		xmlFile = loadXMLFile("InputHelpDisplay ModFile", modDesc.modFile)
		if xmlFile == 0 then
			continue
		end
		self:loadVehicleSchemaOverlaysFromXML(xmlFile, modDesc.modFile)
		delete(xmlFile)
	end
end
function InputHelpDisplay:loadVehicleSchemaOverlaysFromXML(xmlFile, modPath)
	local rootPath = "vehicleSchemaOverlays"
	local baseDirectory = ""
	local prefix = ""
	if modPath then
		rootPath = "modDesc.vehicleSchemaOverlays"
		local modName, dir = Utils.getModNameAndBaseDirectory(modPath)
		baseDirectory = dir
		prefix = modName
	end
	local atlasPath = getXMLString(xmlFile, rootPath .. "#filename")
	local imageSize = string.getVector(getXMLString(xmlFile, rootPath .. "#imageSize"), 2) or { 1024, 1024 }
	local i = 0
	while true do
		local baseName = string.format("%s.overlay(%d)", rootPath, i)
		if not hasXMLProperty(xmlFile, baseName) then
			break
		end
		local baseOverlayName = getXMLString(xmlFile, baseName .. "#name")
		local uvString = getXMLString(xmlFile, baseName .. "#uvs") or string.format("0px 0px %ipx %ipx", imageSize[1], imageSize[2])
		local uvs = GuiUtils.getUVs(uvString, imageSize)
		local sizeString = getXMLString(xmlFile, baseName .. "#size") or "26px 26px"
		local size = GuiUtils.getNormalizedValues(sizeString, { 1, 1 })
		if baseOverlayName then
			local overlayName = prefix .. baseOverlayName
			local atlasFileName = Utils.getFilename(atlasPath, baseDirectory)
			local schemaOverlay = Overlay.new(atlasFileName, 0, 0, size[1], size[2])
			schemaOverlay:setUVs(uvs)
			self.vehicleSchemaOverlays[overlayName] = schemaOverlay
		end
		i = i + 1
	end
end
function InputHelpDisplay:getHelpAnchorPosition(typeId)
	local posX, posY = self:getPosition()
	posX = posX + self.helpAnchorOffsetX
	posY = posY + self.helpAnchorOffsetY
	return posX, posY
end
if data ~= nil then
	local inputHelp = InputHelpDisplay.new()
	inputHelp:loadVehicleSchemaOverlays()
	inputHelp:setScale(data.uiScale)
	inputHelp:setVisible(data.isVisible)
	inputHelp:setVehicle(data.vehicle)
	g_currentMission.hud.inputHelp = inputHelp
	g_currentMission.hud.displayComponents.inputHelp = inputHelp
	Logging.info("Reloaded InputHelpDisplay")
end
