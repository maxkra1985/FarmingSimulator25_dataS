-- Local values: CrabSteeringHUDExtension_mt
CrabSteeringHUDExtension = {}
local CrabSteeringHUDExtension_mt = Class(CrabSteeringHUDExtension)

-- Upvalues: CrabSteeringHUDExtension_mt
-- Local values: self, r, g, b, a
function CrabSteeringHUDExtension.new(vehicle, customMt)
	-- upvalues: (copy) CrabSteeringHUDExtension_mt
	local v4_ = customMt or CrabSteeringHUDExtension_mt
	local v5_ = setmetatable({}, v4_)
	v5_.priority = GS_PRIO_HIGH
	local v6_ = HUD.COLOR.BACKGROUND
	local v7_, v8_, v9_, v10_ = unpack(v6_)
	v5_.background = g_overlayManager:createOverlay("gui.shortcutBox2", 0, 0, 0, 0)
	v5_.background:setColor(v7_, v8_, v9_, v10_)
	v5_.separatorHorizontal = g_overlayManager:createOverlay(g_plainColorSliceId, 0, 0, 0, 0)
	v5_.separatorHorizontal:setColor(1, 1, 1, 0.25)
	v5_.crabSteeringModeText = g_i18n:getText("action_crabSteeringModeSelected")
	v5_.vehicle = vehicle
	v5_:storeScaledValues()
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.UI_SCALE], v5_.storeScaledValues, v5_)
	return v5_
end

function CrabSteeringHUDExtension:delete()
	self.background:delete()
	self.separatorHorizontal:delete()
	g_messageCenter:unsubscribeAll(self)
end

-- Local values: _, uiScale, width, height
function CrabSteeringHUDExtension:storeScaledValues()
	local v13_ = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
	local v14_, v15_ = getNormalizedScreenValues(330 * v13_, 50 * v13_)
	self.background:setDimension(v14_, v15_)
	self.separatorHorizontal:setDimension(v14_, g_pixelSizeY)
	local _, v16_ = getNormalizedScreenValues(0, 25 * v13_)
	self.inputHeight = v16_
end

-- Local values: k, helpElement, actionName
function CrabSteeringHUDExtension:setEventHelpElements(inputHelpDisplay, eventHelpElements)
	inputHelpDisplay:addSkipAction(InputAction.TOGGLE_CRABSTEERING)
	self.toggleElement = nil
	if eventHelpElements ~= nil then
		for _, v20_ in ipairs(eventHelpElements) do
			if v20_.actionName == InputAction.TOGGLE_CRABSTEERING then
				self.toggleElement = v20_
			end
		end
	end
end

-- Local values: toggleElement, textOffsetX, textOffsetY, textSize, togglePosY, modePosY, textPosX, startPosX, crabSteeringMode, toggleWidth, text, toggleText, modeText
function CrabSteeringHUDExtension:draw(inputHelpDisplay, posX, posY)
	local v25_ = self.toggleElement
	if v25_ == nil then
		return posY
	end
	if self.vehicle:getNumCrabSteeringModesAvailable() <= 1 then
		return posY
	end
	local v26_ = posY - self.background.height
	self.background:setPosition(posX, v26_)
	self.background:render()
	local v27_ = inputHelpDisplay.textOffsetX
	local v28_ = inputHelpDisplay.textOffsetY
	local v29_ = inputHelpDisplay.textSize
	local v30_ = v26_ + self.inputHeight
	local v31_ = posX + v27_
	local v32_ = posX + self.background.width
	local v33_ = self.vehicle:getCrabSteeringMode()
	local v34_ = inputHelpDisplay:drawInput(v32_, v30_, self.inputHeight, v25_)
	setTextBold(true)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextColor(1, 1, 1, 1)
	local v35_ = v25_.text
	local v36_ = utf8ToUpper(v35_)
	local v37_ = Utils.limitTextToWidth(v36_, v29_, self.background.width - v34_ - 2 * v27_, false, "...")
	renderText(v31_, v30_ + v28_, v29_, v37_)
	local v38_ = utf8ToUpper(string.format(self.crabSteeringModeText, v33_.name))
	local v39_ = Utils.limitTextToWidth(v38_, v29_, self.background.width - 2 * v27_, false, "...")
	renderText(v31_, v26_ + v28_, v29_, v39_)
	setTextBold(false)
	self.separatorHorizontal:renderCustom(posX, v26_ + self.background.height * 0.5)
	return v26_
end

-- Local values: toggleElement
function CrabSteeringHUDExtension:getHeight()
	return self.toggleElement == nil and 0 or (self.vehicle:getNumCrabSteeringModesAvailable() <= 1 and 0 or self.background.height)
end
