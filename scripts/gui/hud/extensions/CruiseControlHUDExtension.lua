-- Local values: CruiseControlHUDExtension_mt
CruiseControlHUDExtension = {}
local CruiseControlHUDExtension_mt = Class(CruiseControlHUDExtension)

-- Upvalues: CruiseControlHUDExtension_mt
-- Local values: self, r, g, b, a
function CruiseControlHUDExtension.new(vehicle, customMt)
	-- upvalues: (copy) CruiseControlHUDExtension_mt
	local v4_ = customMt or CruiseControlHUDExtension_mt
	local v5_ = setmetatable({}, v4_)
	v5_.priority = GS_PRIO_VERY_LOW
	local v6_ = HUD.COLOR.BACKGROUND
	local v7_, v8_, v9_, v10_ = unpack(v6_)
	v5_.background = g_overlayManager:createOverlay("gui.shortcutBox2", 0, 0, 0, 0)
	v5_.background:setColor(v7_, v8_, v9_, v10_)
	v5_.separatorHorizontal = g_overlayManager:createOverlay(g_plainColorSliceId, 0, 0, 0, 0)
	v5_.separatorHorizontal:setColor(1, 1, 1, 0.25)
	v5_.changeSpeedText = utf8ToUpper(g_i18n:getText("action_changeSpeed"))
	v5_.vehicle = vehicle
	v5_.toggleElement = nil
	v5_.changeElement = nil
	v5_:storeScaledValues()
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.UI_SCALE], v5_.storeScaledValues, v5_)
	return v5_
end

function CruiseControlHUDExtension:delete()
	self.background:delete()
	self.separatorHorizontal:delete()
	g_messageCenter:unsubscribeAll(self)
end

-- Local values: _, uiScale, width, height
function CruiseControlHUDExtension:storeScaledValues()
	local v13_ = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
	local v14_, v15_ = getNormalizedScreenValues(330 * v13_, 50 * v13_)
	self.background:setDimension(v14_, v15_)
	self.separatorHorizontal:setDimension(v14_, g_pixelSizeY)
	local _, v16_ = getNormalizedScreenValues(0, 25 * v13_)
	self.inputHeight = v16_
end

-- Local values: k, helpElement, actionName
function CruiseControlHUDExtension:setEventHelpElements(inputHelpDisplay, eventHelpElements)
	inputHelpDisplay:addSkipAction(InputAction.TOGGLE_CRUISE_CONTROL)
	inputHelpDisplay:addSkipAction(InputAction.AXIS_CRUISE_CONTROL)
	self.toggleElement = nil
	self.changeElement = nil
	if eventHelpElements ~= nil then
		for _, v20_ in ipairs(eventHelpElements) do
			local v21_ = v20_.actionName
			if v21_ == InputAction.TOGGLE_CRUISE_CONTROL then
				self.toggleElement = v20_
			elseif v21_ == InputAction.AXIS_CRUISE_CONTROL then
				self.changeElement = v20_
			end
		end
	end
end

-- Local values: toggleElement, changeElement, textOffsetX, textOffsetY, textSize, togglePosY, changePosY, startPosX, toggleWidth, changeWidth, toggleText, changeText
function CruiseControlHUDExtension:draw(inputHelpDisplay, posX, posY)
	local v26_ = self.toggleElement
	local v27_ = self.changeElement
	if v26_ == nil or v27_ == nil then
		if v26_ ~= nil then
			return inputHelpDisplay:drawInputHelpElement(posX, posY, v26_, self.comboButtonMapping)
		end
		if v27_ ~= nil then
			posY = inputHelpDisplay:drawInputHelpElement(posX, posY, v27_, self.comboButtonMapping)
		end
		return posY
	end
	local v28_ = posY - self.background.height
	self.background:setPosition(posX, v28_)
	self.background:render()
	local v29_ = inputHelpDisplay.textOffsetX
	local v30_ = inputHelpDisplay.textOffsetY
	local v31_ = inputHelpDisplay.textSize
	local v32_ = v28_ + self.inputHeight
	local v33_ = posX + self.background.width
	local v34_ = inputHelpDisplay:drawInput(v33_, v32_, self.inputHeight, v26_)
	local v35_ = inputHelpDisplay:drawInput(v33_, v28_, self.inputHeight, v27_)
	setTextBold(true)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextColor(1, 1, 1, 1)
	local v36_ = utf8ToUpper(v26_.text)
	local v37_ = Utils.limitTextToWidth(v36_, v31_, self.background.width - v34_ - 2 * v29_, false, "...")
	renderText(posX + v29_, v32_ + v30_, v31_, v37_)
	local v38_ = utf8ToUpper(self.changeSpeedText)
	local v39_ = Utils.limitTextToWidth(v38_, v31_, self.background.width - v35_ - 2 * v29_, false, "...")
	renderText(posX + v29_, v28_ + v30_, v31_, v39_)
	setTextBold(false)
	self.separatorHorizontal:renderCustom(posX, v28_ + self.background.height * 0.5)
	return v28_
end

function CruiseControlHUDExtension:getHeight()
	return (self.toggleElement == nil or self.changeElement == nil) and (self.toggleElement == nil and self.changeElement == nil and 0 or 0) or self.background.height
end
