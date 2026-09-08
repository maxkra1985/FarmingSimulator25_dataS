-- Local values: MobileHUD_mt
source("dataS/scripts/gui/hud/HUDSliderElement.lua")
source("dataS/scripts/gui/hud/ControlBarDisplay.lua")
source("dataS/scripts/gui/hud/SpeedSliderDisplay.lua")
source("dataS/scripts/gui/hud/SteeringSliderDisplay.lua")
source("dataS/scripts/gui/hud/SwitchVehicleDisplay.lua")
source("dataS/scripts/gui/hud/PlayerControlPadDisplay.lua")
source("dataS/scripts/gui/hud/GameInfoDisplayMobile.lua")
source("dataS/scripts/gui/hud/ingameMap/IngameMapMobile.lua")
source("dataS/scripts/gui/hud/SideNotificationMobile.lua")
source("dataS/scripts/gui/hud/HUDPopupMessageMobile.lua")
source("dataS/scripts/gui/hud/HUDButtonElement.lua")
source("dataS/scripts/gui/hud/IntroductionHelpHUDUtil.lua")
source("dataS/scripts/gui/hud/InputGlyphMobileElement.lua")
source("dataS/scripts/gui/hud/POIInfoDisplay.lua")
MobileHUD = {}
local MobileHUD_mt = Class(MobileHUD, HUD)

-- Upvalues: MobileHUD_mt
-- Local values: self
function MobileHUD.new(isServer, isClient, isConsoleVersion, messageCenter, l10n, inputManager, inputDisplayManager, modManager, fillTypeManager, fruitTypeManager, guiSoundPlayer, currentMission, farmManager, farmlandManager)
	-- upvalues: (copy) MobileHUD_mt
	local v16_ = MobileHUD:superClass().new(isServer, isClient, isConsoleVersion, messageCenter, l10n, inputManager, inputDisplayManager, modManager, fillTypeManager, fruitTypeManager, guiSoundPlayer, currentMission, farmManager, farmlandManager, MobileHUD_mt)
	v16_.lastMouseInput = {
		["posX"] = 0,
		["posY"] = 0,
		["isDown"] = false,
		["isUp"] = false,
		["button"] = 0,
		["touchIsDown"] = false
	}
	v16_.messageCenter:subscribe(MessageType.AI_VEHICLE_STATE_CHANGE, v16_.onAIVehicleStateChanged, v16_)
	return v16_
end

function MobileHUD:delete()
	g_touchHandler:removeAllTouchAreas()
	self.messageCenter:unsubscribeAll(self)
	IntroductionHelpHUDUtil.delete()
	MobileHUD:superClass().delete(self)
end

-- Local values: blinkTween, fadeOverlay
function MobileHUD:createDisplayComponents(uiScale)
	self.buttons = {}
	self.ingameMap = IngameMapMobile.new(self, g_baseHUDFilename, g_controlHUDFilename, self.inputDisplayManager)
	self.ingameMap:setScale(uiScale)
	local v20_ = self.displayComponents
	local v21_ = self.ingameMap
	table.insert(v20_, v21_)
	self.gamePausedDisplay = GamePausedDisplay.new()
	self.gamePausedDisplay:setScale(uiScale)
	self.gamePausedDisplay:setVisible(false)
	local v22_ = self.displayComponents
	local v23_ = self.gamePausedDisplay
	table.insert(v22_, v23_)
	self.menuBackgroundOverlay = Overlay.new(HUD.MENU_BACKGROUND_PATH, 0.5, 0, 1, g_screenAspectRatio)
	self.menuBackgroundOverlay:setAlignment(Overlay.ALIGN_VERTICAL_BOTTOM, Overlay.ALIGN_HORIZONTAL_CENTER)
	self.blinkingWarning = nil
	self.blinkingWarningDisplay = HUDTextDisplay.new(0.5, 0.5, HUD.TEXT_SIZE.BLINKING_WARNING, RenderText.ALIGN_CENTER, HUD.COLOR.BLINKING_WARNING, true)
	local v24_ = TweenSequence.new(self.blinkingWarningDisplay)
	v24_:addTween(MultiValueTween.new(self.blinkingWarningDisplay.setTextColorChannels, HUD.COLOR.BLINKING_WARNING_1, HUD.COLOR.BLINKING_WARNING_2, HUD.ANIMATION.BLINKING_WARNING_TIME))
	v24_:addTween(MultiValueTween.new(self.blinkingWarningDisplay.setTextColorChannels, HUD.COLOR.BLINKING_WARNING_2, HUD.COLOR.BLINKING_WARNING_1, HUD.ANIMATION.BLINKING_WARNING_TIME))
	v24_:setLooping(true)
	self.blinkingWarningDisplay:setAnimation(v24_)
	self.blinkingWarningDisplay:setVisible(false)
	local v25_ = self.displayComponents
	local v26_ = self.blinkingWarningDisplay
	table.insert(v25_, v26_)
	local v27_ = Overlay.new(g_baseHUDFilename, 0, 0, 1, 1)
	v27_:setUVs(GuiUtils.getUVs(HUD.UV.AREA))
	v27_:setColor(0, 0, 0, 0)
	self.fadeScreenElement = HUDElement.new(v27_)
	local v28_ = self.displayComponents
	local v29_ = self.fadeScreenElement
	table.insert(v28_, v29_)
	self.popupMessage = HUDPopupMessageMobile.new(g_baseHUDFilename, self.ingameMap)
	self.popupMessage:setScale(uiScale)
	self.popupMessage:storeOriginalPosition()
	local v30_ = self.displayComponents
	local v31_ = self.popupMessage
	table.insert(v30_, v31_)
	self.gameInfoDisplay = GameInfoDisplayMobile.new(self, g_baseHUDFilename, g_gameSettings:getValue(GameSettings.SETTING.MONEY_UNIT), g_controlHUDFilename)
	self.gameInfoDisplay:setScale(uiScale)
	self.gameInfoDisplay:setTemperatureVisible(false)
	self.gameInfoDisplay:setVehicle(self.controlledVehicle)
	local v32_ = self.displayComponents
	local v33_ = self.gameInfoDisplay
	table.insert(v32_, v33_)
	self.controlBarDisplay = ControlBarDisplay.new(self, g_baseHUDFilename, g_controlHUDFilename)
	self.controlBarDisplay:setVehicle(self.controlledVehicle)
	self.controlBarDisplay:setScale(uiScale)
	self.controlBarDisplay:storeOriginalPosition()
	self.controlBarDisplay:setVisible(true, false)
	local v34_ = self.displayComponents
	local v35_ = self.controlBarDisplay
	table.insert(v34_, v35_)
	self.switchVehicleDisplay = SwitchVehicleDisplay.new(self, g_baseHUDFilename, g_controlHUDFilename)
	self.switchVehicleDisplay:setVehicle(self.controlledVehicle)
	self.switchVehicleDisplay:setScale(uiScale)
	self.switchVehicleDisplay:storeOriginalPosition()
	self.switchVehicleDisplay:setVisible(true, false)
	local v36_ = self.displayComponents
	local v37_ = self.switchVehicleDisplay
	table.insert(v36_, v37_)
	self.speedSliderDisplay = SpeedSliderDisplay.new(self, g_baseHUDFilename, g_controlHUDFilename)
	self.speedSliderDisplay:setVehicle(self.controlledVehicle)
	self.speedSliderDisplay:setScale(uiScale)
	self.speedSliderDisplay:storeOriginalPosition()
	self.speedSliderDisplay:setVisible(true, false)
	local v38_ = self.displayComponents
	local v39_ = self.speedSliderDisplay
	table.insert(v38_, v39_)
	self.steeringSliderDisplay = SteeringSliderDisplay.new(self, g_baseHUDFilename)
	self.steeringSliderDisplay:setVehicle(self.controlledVehicle)
	self.steeringSliderDisplay:setScale(uiScale)
	self.steeringSliderDisplay:storeOriginalPosition()
	self.steeringSliderDisplay:setVisible(true, false)
	local v40_ = self.displayComponents
	local v41_ = self.steeringSliderDisplay
	table.insert(v40_, v41_)
	self.playerControlPadDisplay = PlayerControlPadDisplay.new(self, g_baseHUDFilename)
	self.playerControlPadDisplay:setScale(uiScale)
	self.playerControlPadDisplay:storeOriginalPosition()
	self.playerControlPadDisplay:setVisible(true, false)
	local v42_ = self.displayComponents
	local v43_ = self.playerControlPadDisplay
	table.insert(v42_, v43_)
	self.achievementMessage = AchievementMessage.new()
	self.achievementMessage:setScale(uiScale)
	self.achievementMessage:setVisible(false, false)
	local v44_ = self.displayComponents
	local v45_ = self.achievementMessage
	table.insert(v44_, v45_)
	self.sideNotifications = SideNotificationMobile.new()
	self.sideNotifications:setScale(uiScale)
	self.sideNotifications:storeOriginalPosition()
	self.sideNotifications:setVisible(true, false)
	local v46_ = self.displayComponents
	local v47_ = self.sideNotifications
	table.insert(v46_, v47_)
	self.topNotification = TopNotification.new()
	self.topNotification:setScale(uiScale)
	self.topNotification:storeOriginalPosition()
	self.topNotification:setVisible(false, false)
	local v48_ = self.displayComponents
	local v49_ = self.topNotification
	table.insert(v48_, v49_)
	self.infoDisplay = InfoDisplay.new()
	self.infoDisplay:setScale(uiScale)
	self.infoDisplay:storeOriginalPosition()
	self.infoDisplay:setVisible(false, false)
	local v50_ = self.displayComponents
	local v51_ = self.infoDisplay
	table.insert(v50_, v51_)
	self.poiInfoDisplay = POIInfoDisplay.new()
	self.poiInfoDisplay:setScale(uiScale)
	local v52_ = self.displayComponents
	local v53_ = self.poiInfoDisplay
	table.insert(v52_, v53_)
end

function MobileHUD:drawControlledEntityHUD()
	if self.isVisible then
		if self.controlledVehicle == nil then
			if self.controlPlayer and self.player ~= nil then
				self.player:draw()
				self.playerControlPadDisplay:draw()
				self.infoDisplay:draw()
			end
		elseif self.showVehicleInfo then
			self.controlledVehicle:draw()
		end
		self.controlBarDisplay:draw()
		self.switchVehicleDisplay:draw()
		self.speedSliderDisplay:draw()
		self.steeringSliderDisplay:draw()
		self.poiInfoDisplay:draw()
		self.poiInfoDisplay:setText("")
	end
end

function MobileHUD:setPOIInfoText(text)
	self.poiInfoDisplay:setText(text)
end

function MobileHUD:drawInputHelp() end

function MobileHUD:drawVehicleName() end

function MobileHUD:drawInGameMessageAndIcon() end

function MobileHUD:addExtraPrintText(text) end

function MobileHUD:showVehicleName(vehicleName) end
function MobileHUD.showAttachConvehicleName(self, isVisible) end
function MobileHUD.showTipConvehicleName(self, isVisible) end
function MobileHUD.showFuelConvehicleName(self, isVisible) end
function MobileHUD.showFillDogBowlConvehicleName(self) end

function MobileHUD:onMenuVisibilityChange(isMenuVisible, isOverlayMenu)
	self.achievementMessage:onMenuVisibilityChange(isMenuVisible)
end

function MobileHUD.setInputHelpVisible(self, isVisible) end

-- Local values: aiActive
function MobileHUD:setControlledVehicle(vehicle)
	self.controlledVehicle = vehicle
	self.controlBarDisplay:setVehicle(vehicle)
	self.switchVehicleDisplay:setVehicle(vehicle)
	self.speedSliderDisplay:setVehicle(vehicle)
	self.steeringSliderDisplay:setVehicle(vehicle)
	if vehicle ~= nil then
		local v61_ = vehicle:getIsAIActive()
		self.controlBarDisplay:onAIVehicleStateChanged(v61_, vehicle)
		self.speedSliderDisplay:onAIVehicleStateChanged(v61_, vehicle)
		self.steeringSliderDisplay:onAIVehicleStateChanged(v61_, vehicle)
	end
	self.controlBarDisplay:onInputHelpModeChange(self.lastInputHelpMode)
	self.switchVehicleDisplay:onInputHelpModeChange(self.lastInputHelpMode)
	self.speedSliderDisplay:onInputHelpModeChange(self.lastInputHelpMode)
	self.steeringSliderDisplay:onInputHelpModeChange(self.lastInputHelpMode)
	self.gameInfoDisplay:setVehicle(vehicle)
end

-- Local values: player
function MobileHUD:setIsControllingPlayer(isControllingPlayer)
	MobileHUD:superClass().setIsControllingPlayer(self, isControllingPlayer)
	local v64_
	if isControllingPlayer then
		v64_ = self.player
	else
		v64_ = nil
	end
	self.isControllingPlayer = isControllingPlayer
	self.controlBarDisplay:setPlayer(v64_)
	self.switchVehicleDisplay:setPlayer(v64_)
	self.speedSliderDisplay:setPlayer(v64_)
	self.steeringSliderDisplay:setPlayer(v64_)
	self.playerControlPadDisplay:setPlayer(v64_)
	self.ingameMap:setPlayer(v64_)
end

-- Local values: inputHelpMode, gyroscopeSteeringActive, show
function MobileHUD:update(dt)
	if not self.fadeAnimation:getFinished() then
		self.fadeAnimation:update(dt)
	end
	self.fadeFollowDelay = self.fadeFollowDelay - dt
	self.infoDisplay:update(dt)
	self.controlBarDisplay:update(dt)
	self.switchVehicleDisplay:update(dt)
	self.speedSliderDisplay:update(dt)
	self.steeringSliderDisplay:update(dt)
	self.playerControlPadDisplay:update(dt)
	self.gameInfoDisplay:update(dt)
	self.achievementMessage:update(dt)
	self.sideNotifications:update(dt)
	self.topNotification:update(dt)
	local v67_ = g_inputBinding:getInputHelpMode()
	if v67_ ~= self.lastInputHelpMode then
		self.controlBarDisplay:onInputHelpModeChange(v67_)
		self.switchVehicleDisplay:onInputHelpModeChange(v67_)
		self.speedSliderDisplay:onInputHelpModeChange(v67_)
		self.steeringSliderDisplay:onInputHelpModeChange(v67_)
		self.playerControlPadDisplay:onInputHelpModeChange(v67_)
		self.lastInputHelpMode = v67_
	end
	local v68_ = g_gameSettings:getValue(GameSettings.SETTING.GYROSCOPE_STEERING)
	if self.lastGyroSteeringState ~= v68_ then
		self.controlBarDisplay:onGyroscopeSteeringChanged(v68_)
		self.switchVehicleDisplay:onGyroscopeSteeringChanged(v68_)
		self.steeringSliderDisplay:onGyroscopeSteeringChanged(v68_)
	end
	if self.lastMouseInput.touchIsDown then
		self:mouseEvent(self.lastMouseInput.posX, self.lastMouseInput.posY, true, false, self.lastMouseInput.button)
	end
	if not g_gui:getIsGuiVisible() then
		local v69_ = Input.isKeyPressed(Input.KEY_lctrl) and true or false
		if self.debugMouseCursorActive ~= v69_ then
			g_inputBinding:setShowMouseCursor(v69_, false)
			self.debugMouseCursorActive = v69_
		end
	end
end

function MobileHUD:addTouchButton(overlay, areaOffsetX, areaOffsetY, callback, callbackTarget, triggerType, extraArguments)
	return g_touchHandler:registerTouchAreaOverlay(overlay, areaOffsetX, areaOffsetY, triggerType, callback, callbackTarget, extraArguments)
end

function MobileHUD:removeTouchButton(area)
	g_touchHandler:removeTouchArea(area)
end

function MobileHUD:hideTouchButton(area)
	g_touchHandler:setTouchAreaVisibility(area, false)
end

function MobileHUD:showTouchButton(area)
	g_touchHandler:setTouchAreaVisibility(area, true)
end

function MobileHUD:onAIVehicleStateChanged(state, vehicle)
	self.controlBarDisplay:onAIVehicleStateChanged(state, vehicle)
	self.speedSliderDisplay:onAIVehicleStateChanged(state, vehicle)
	self.steeringSliderDisplay:onAIVehicleStateChanged(state, vehicle)
end

function MobileHUD:setMissionInfo(missionInfo)
	self.missionInfo = missionInfo
	self.gameInfoDisplay:setMissionInfo(missionInfo)
end

function MobileHUD:scrollChatMessages(delta, numMessages) end

function MobileHUD:setChatDisplayVisible(isVisible, animate) end

function MobileHUD:setChatMessagesReference(chatMessages) end

function MobileHUD:addChatMessage(msg, sender, farmId) end

function MobileHUD.setConnectedUsers(self, isVisible) end

function MobileHUD:setInfoVisible(isVisible) end

function MobileHUD:updateMap(dt)
	self.ingameMap:update(dt)
end

function MobileHUD:registerInput()
	self.ingameMap:registerInput()
end

function MobileHUD:showInGameMessage(title, message, duration, controlGlyphs, callback, callbackTarget)
	TourDialog.show(title, message, controlGlyphs, callback, callbackTarget)
end
