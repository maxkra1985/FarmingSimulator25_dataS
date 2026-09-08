-- Local values: AIModeHUDExtension_mt
AIModeHUDExtension = {}
local AIModeHUDExtension_mt = Class(AIModeHUDExtension)

-- Upvalues: AIModeHUDExtension_mt
-- Local values: self, r, g, b, a
function AIModeHUDExtension.new(vehicle, customMt)
	-- upvalues: (copy) AIModeHUDExtension_mt
	local v4_ = customMt or AIModeHUDExtension_mt
	local v5_ = setmetatable({}, v4_)
	v5_.priority = GS_PRIO_VERY_HIGH
	local v6_ = HUD.COLOR.BACKGROUND
	local v7_, v8_, v9_, v10_ = unpack(v6_)
	v5_.background = g_overlayManager:createOverlay("gui.shortcutBox2", 0, 0, 0, 0)
	v5_.background:setColor(v7_, v8_, v9_, v10_)
	v5_.separatorHorizontal = g_overlayManager:createOverlay(g_plainColorSliceId, 0, 0, 0, 0)
	v5_.separatorHorizontal:setColor(1, 1, 1, 0.25)
	v5_.aiModeText = g_i18n:getText("action_aiModeSelected")
	v5_.aiModeHoldText = utf8ToUpper(g_i18n:getText("input_holdButton"))
	v5_.vehicle = vehicle
	v5_.spec = vehicle.spec_aiModeSelection
	v5_.specDrivable = vehicle.spec_aiDrivable
	v5_.textWorkerDeactivate = g_i18n:getText("ai_modeWorker_deactivate")
	v5_.textWorkerActivate = g_i18n:getText("ai_modeWorker_activate")
	v5_.textSteeringAssistDeactivate = g_i18n:getText("ai_modeSteeringAssist_deactivate")
	v5_.textSteeringAssistActivate = g_i18n:getText("ai_modeSteeringAssist_activate")
	v5_.textSteeringAssistDisabled = g_i18n:getText("ai_modeSteeringAssist_noLane")
	v5_.textAIState = g_i18n:getText("ai_state")
	v5_.textAIStateDriving = g_i18n:getText("ai_stateDriving")
	v5_.textAIStatePlanning = g_i18n:getText("ai_statePlanning")
	v5_.textAIStateBlocked = g_i18n:getText("ai_stateBlocked")
	v5_.textAIStateTargetReached = g_i18n:getText("ai_stateTargetReached")
	v5_.textAIStateNotReachable = g_i18n:getText("ai_stateNotReachable")
	v5_.aiElement = nil
	v5_:storeScaledValues()
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.UI_SCALE], v5_.storeScaledValues, v5_)
	return v5_
end

function AIModeHUDExtension:delete()
	self.background:delete()
	self.separatorHorizontal:delete()
	g_messageCenter:unsubscribeAll(self)
end

-- Local values: _, uiScale, width, height
function AIModeHUDExtension:storeScaledValues()
	local v13_ = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
	local v14_, v15_ = getNormalizedScreenValues(330 * v13_, 50 * v13_)
	self.background:setDimension(v14_, v15_)
	self.separatorHorizontal:setDimension(v14_, g_pixelSizeY)
	local _, v16_ = getNormalizedScreenValues(0, 25 * v13_)
	self.inputHeight = v16_
	self.holdIconButtonOffset = getNormalizedScreenValues(5 * v13_, 0)
end

-- Local values: k, helpElement, actionName
function AIModeHUDExtension:setEventHelpElements(inputHelpDisplay, eventHelpElements)
	inputHelpDisplay:addSkipAction(InputAction.TOGGLE_AI)
	inputHelpDisplay:addSkipAction(InputAction.TOGGLE_AI_STEERING)
	self.aiElement = nil
	self.aiSteeringElement = nil
	if eventHelpElements ~= nil then
		for _, v20_ in ipairs(eventHelpElements) do
			local v21_ = v20_.actionName
			if v21_ == InputAction.TOGGLE_AI then
				self.aiElement = v20_
			elseif v21_ == InputAction.TOGGLE_AI_STEERING then
				self.aiSteeringElement = v20_
			end
		end
	end
end

-- Local values: aiElement, aiSteeringElement, textOffsetX, textOffsetY, textSize, togglePosY, modePosY, textPosX, startPosX, specDrivable, text, drawToggleButton, drawModeSwitch, currentMode, state, toggleWidth, changeWidth, toggleText, modeText, status, stateText, infoText
function AIModeHUDExtension:draw(inputHelpDisplay, posX, posY)
	local v26_ = self.aiElement
	local v27_ = self.aiSteeringElement
	if v26_ ~= nil then
		posY = posY - self.background.height
		self.background:setPosition(posX, posY)
		self.background:render()
		local v28_ = inputHelpDisplay.textOffsetX
		local v29_ = inputHelpDisplay.textOffsetY
		local v30_ = inputHelpDisplay.textSize
		local v31_ = posY + self.inputHeight
		local v32_ = posX + v28_
		local v33_ = posX + self.background.width
		local v34_ = self.specDrivable
		local v35_ = true
		local v36_ = (v34_ == nil or not v34_.isRunning) and true or false
		local v37_ = self.spec.currentMode
		local v38_
		if v37_ == AIModeSelection.MODE.WORKER then
			v38_ = self.vehicle:getIsAIActive() and self.textWorkerDeactivate or self.textWorkerActivate
		else
			local v39_ = self.vehicle:getAIAutomaticSteeringState()
			if v39_ == AIAutomaticSteering.STATE.ACTIVE then
				v38_ = self.textSteeringAssistDeactivate
			elseif v39_ == AIAutomaticSteering.STATE.AVAILABLE then
				v38_ = self.textSteeringAssistActivate
			else
				v38_ = self.textSteeringAssistDisabled
				v35_ = false
			end
		end
		local v40_ = not v35_ and 0 or inputHelpDisplay:drawInput(v33_, v31_, self.inputHeight, v27_ or v26_)
		local v41_ = not v36_ and 0 or inputHelpDisplay:drawInput(v33_, posY, self.inputHeight, v26_, self.holdIconButtonOffset, self.aiModeHoldText)
		setTextBold(true)
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextColor(1, 1, 1, 1)
		local v42_ = utf8ToUpper(v38_)
		local v43_ = Utils.limitTextToWidth(v42_, v30_, self.background.width - v40_ - 2 * v28_, false, "...")
		renderText(v32_, v31_ + v29_, v30_, v43_)
		if v36_ then
			local v44_ = utf8ToUpper(string.format(self.aiModeText, g_i18n:getText(AIModeSelection.MODE_TEXTS[v37_])))
			local v45_ = Utils.limitTextToWidth(v44_, v30_, self.background.width - v41_ - 2 * v28_, false, "...")
			renderText(v32_, posY + v29_, v30_, v45_)
		else
			local v46_ = v34_.lastState
			local v47_ = nil
			if v46_ == AgentState.DRIVING then
				v47_ = self.textAIStateDriving
			elseif v46_ == AgentState.PLANNING then
				v47_ = self.textAIStatePlanning
			elseif v46_ == AgentState.BLOCKED then
				v47_ = self.textAIStateBlocked
			elseif v46_ == AgentState.TARGET_REACHED then
				v47_ = self.textAIStateTargetReached
			elseif v46_ == AgentState.NOT_REACHABLE then
				v47_ = self.textAIStateNotReachable
			end
			if v47_ ~= nil then
				local v48_ = string.namedFormat(self.textAIState, "aiState", v47_)
				renderText(v32_, posY + v29_, v30_, utf8ToUpper(v48_))
			end
		end
		setTextBold(false)
		self.separatorHorizontal:renderCustom(posX, posY + self.background.height * 0.5)
	end
	return posY
end

function AIModeHUDExtension:getHeight()
	return self.aiElement == nil and 0 or self.background.height
end
