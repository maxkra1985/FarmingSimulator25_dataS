CruiseControlHUDExtension = {}
local CruiseControlHUDExtension_mt = Class(CruiseControlHUDExtension)
function CruiseControlHUDExtension.new(vehicle, customMt)
	local self = setmetatable({}, customMt or CruiseControlHUDExtension_mt)
	self.priority = GS_PRIO_VERY_LOW
	local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
	self.background = g_overlayManager:createOverlay("gui.shortcutBox2", 0, 0, 0, 0)
	self.background:setColor(r, g, b, a)
	self.separatorHorizontal = g_overlayManager:createOverlay(g_plainColorSliceId, 0, 0, 0, 0)
	self.separatorHorizontal:setColor(1, 1, 1, 0.25)
	self.changeSpeedText = utf8ToUpper(g_i18n:getText("action_changeSpeed"))
	self.vehicle = vehicle
	self.toggleElement = nil
	self.changeElement = nil
	self:storeScaledValues()
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.UI_SCALE], self.storeScaledValues, self)
	return self
end
function CruiseControlHUDExtension:delete()
	self.background:delete()
	self.separatorHorizontal:delete()
	g_messageCenter:unsubscribeAll(self)
end
function CruiseControlHUDExtension:storeScaledValues()
	local _ = nil
	local uiScale = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
	local width, height = getNormalizedScreenValues(330 * uiScale, 50 * uiScale)
	self.background:setDimension(width, height)
	self.separatorHorizontal:setDimension(width, g_pixelSizeY)
	_, self.inputHeight = getNormalizedScreenValues(0, 25 * uiScale)
end
function CruiseControlHUDExtension:setEventHelpElements(inputHelpDisplay, eventHelpElements)
	inputHelpDisplay:addSkipAction(InputAction.TOGGLE_CRUISE_CONTROL)
	inputHelpDisplay:addSkipAction(InputAction.AXIS_CRUISE_CONTROL)
	self.toggleElement = nil
	self.changeElement = nil
	if eventHelpElements ~= nil then
		for k, helpElement in ipairs(eventHelpElements) do
			local actionName = helpElement.actionName
			if actionName == InputAction.TOGGLE_CRUISE_CONTROL then
				self.toggleElement = helpElement
			elseif actionName == InputAction.AXIS_CRUISE_CONTROL then
				self.changeElement = helpElement
			end
		end
	end
end
function CruiseControlHUDExtension:draw(inputHelpDisplay, posX, posY)
	local toggleElement = self.toggleElement
	local changeElement = self.changeElement
	if toggleElement ~= nil and changeElement ~= nil then
		posY = posY - self.background.height
		self.background:setPosition(posX, posY)
		self.background:render()
		local textOffsetX = inputHelpDisplay.textOffsetX
		local textOffsetY = inputHelpDisplay.textOffsetY
		local textSize = inputHelpDisplay.textSize
		local togglePosY = posY + self.inputHeight
		local changePosY = posY
		local startPosX = posX + self.background.width
		local toggleWidth = inputHelpDisplay:drawInput(startPosX, togglePosY, self.inputHeight, toggleElement)
		local changeWidth = inputHelpDisplay:drawInput(startPosX, changePosY, self.inputHeight, changeElement)
		setTextBold(true)
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextColor(1, 1, 1, 1)
		local toggleText = utf8ToUpper(toggleElement.text)
		toggleText = Utils.limitTextToWidth(toggleText, textSize, self.background.width - toggleWidth - 2 * textOffsetX, false, "...")
		renderText(posX + textOffsetX, togglePosY + textOffsetY, textSize, toggleText)
		local changeText = utf8ToUpper(self.changeSpeedText)
		changeText = Utils.limitTextToWidth(changeText, textSize, self.background.width - changeWidth - 2 * textOffsetX, false, "...")
		renderText(posX + textOffsetX, changePosY + textOffsetY, textSize, changeText)
		setTextBold(false)
		self.separatorHorizontal:renderCustom(posX, posY + self.background.height * 0.5)
		return posY
	end
	if toggleElement ~= nil then
		posY = inputHelpDisplay:drawInputHelpElement(posX, posY, toggleElement, self.comboButtonMapping)
		return posY
	else
		if changeElement ~= nil then
			posY = inputHelpDisplay:drawInputHelpElement(posX, posY, changeElement, self.comboButtonMapping)
		end
		return posY
	end
end
function CruiseControlHUDExtension:getHeight()
	if self.toggleElement ~= nil and self.changeElement ~= nil then
		return self.background.height
	end
	if self.toggleElement ~= nil or self.changeElement ~= nil then
		return 0
	end
	return 0
end
