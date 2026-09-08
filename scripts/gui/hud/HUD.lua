-- Local values: HUD_mt
source("dataS/scripts/gui/hud/mapHotspots/MapHotspot.lua")
source("dataS/scripts/gui/hud/mapHotspots/AIHotspot.lua")
source("dataS/scripts/gui/hud/mapHotspots/AIPlaceableMarkerHotspot.lua")
source("dataS/scripts/gui/hud/mapHotspots/AITargetHotspot.lua")
source("dataS/scripts/gui/hud/mapHotspots/FarmlandHotspot.lua")
source("dataS/scripts/gui/hud/mapHotspots/MissionHotspot.lua")
source("dataS/scripts/gui/hud/mapHotspots/PlaceableHotspot.lua")
source("dataS/scripts/gui/hud/mapHotspots/PlayerHotspot.lua")
source("dataS/scripts/gui/hud/mapHotspots/TourHotspot.lua")
source("dataS/scripts/gui/hud/mapHotspots/VehicleHotspot.lua")
source("dataS/scripts/gui/hud/mapHotspots/CollectibleHotspot.lua")
source("dataS/scripts/gui/hud/mapHotspots/TwisterHotspot.lua")
source("dataS/scripts/gui/hud/mapHotspots/NPCHotspot.lua")
source("dataS/scripts/gui/hud/mapHotspots/FerryHotspot.lua")
source("dataS/scripts/gui/hud/HUDDisplay.lua")
source("dataS/scripts/gui/hud/HUDElement.lua")
source("dataS/scripts/gui/hud/HUDDisplayElement.lua")
source("dataS/scripts/gui/hud/HUDFrameElement.lua")
source("dataS/scripts/gui/hud/HUDTextButtonElement.lua")
source("dataS/scripts/gui/hud/GameInfoDisplay.lua")
source("dataS/scripts/gui/hud/SpeedMeterDisplay.lua")
source("dataS/scripts/gui/hud/FillLevelsDisplay.lua")
source("dataS/scripts/gui/hud/InputGlyphElement.lua")
source("dataS/scripts/gui/hud/ContextActionDisplay.lua")
source("dataS/scripts/gui/hud/AchievementMessage.lua")
source("dataS/scripts/gui/hud/ingameMap/IngameMapState.lua")
source("dataS/scripts/gui/hud/ingameMap/IngameMap.lua")
source("dataS/scripts/gui/hud/ingameMap/IngameMapLayout.lua")
source("dataS/scripts/gui/hud/ingameMap/IngameMapLayoutCircle.lua")
source("dataS/scripts/gui/hud/ingameMap/IngameMapLayoutSquare.lua")
source("dataS/scripts/gui/hud/ingameMap/IngameMapLayoutSquareLarge.lua")
source("dataS/scripts/gui/hud/ingameMap/IngameMapLayoutNone.lua")
source("dataS/scripts/gui/hud/ingameMap/IngameMapLayoutFullscreen.lua")
source("dataS/scripts/gui/hud/ingameMap/IngameMapLayoutPartialscreen.lua")
source("dataS/scripts/gui/hud/InputHelpDisplay.lua")
source("dataS/scripts/gui/hud/IngameMessage.lua")
source("dataS/scripts/gui/hud/SideNotification.lua")
source("dataS/scripts/gui/hud/TopNotification.lua")
source("dataS/scripts/gui/hud/GamePausedDisplay.lua")
source("dataS/scripts/gui/hud/HUDTextDisplay.lua")
source("dataS/scripts/gui/hud/ChatDisplay.lua")
source("dataS/scripts/gui/hud/SpeakerDisplay.lua")
source("dataS/scripts/gui/hud/HUDRoundedBarElement.lua")
source("dataS/scripts/gui/hud/InfoDisplay.lua")
source("dataS/scripts/gui/hud/InfoDisplayBox.lua")
source("dataS/scripts/gui/hud/InfoDisplayKeyValueBox.lua")
source("dataS/scripts/gui/hud/InfoDisplayKeyValueBoxMobile.lua")
source("dataS/scripts/gui/hud/WarningDisplay.lua")
HUD = {}
local HUD_mt = Class(HUD)
HUD.CONTEXT_PRIORITY = {
	["LOW"] = 1,
	["MEDIUM"] = 2,
	["HIGH"] = 3
}
HUD.GAME_INFO_PART = {
	["NONE"] = 0,
	["MONEY"] = 1,
	["TIME"] = 2,
	["TEMPERATURE"] = 4,
	["WEATHER"] = 8,
	["TUTORIAL"] = 16
}
HUD.ACHIEVEMENT_DISPLAY_DURATION = 5000
HUD.FADE_FOLLOW_DELAY = 100

-- Upvalues: HUD_mt
-- Local values: self, uiScale, messageCenter
function HUD.new(customMt)
	-- upvalues: (copy) HUD_mt
	local v3_ = customMt or HUD_mt
	local v4_ = setmetatable({}, v3_)
	local v5_ = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
	v4_.ingameMap = nil
	v4_.gameInfoDisplay = nil
	v4_.inputHelp = nil
	v4_.speedMeter = nil
	v4_.fillLevelsDisplay = nil
	v4_.sideNotifications = nil
	v4_.topNotification = nil
	v4_.chatDisplay = nil
	v4_.speakerDisplay = nil
	v4_.warningDisplay = nil
	v4_.ingameMessage = nil
	v4_.achievementMessage = nil
	v4_.contextActionDisplay = nil
	v4_.gamePausedDisplay = nil
	v4_.vehicleNameDisplay = nil
	v4_.fadeScreenElement = nil
	v4_.fadeAnimation = TweenSequence.NO_SEQUENCE
	v4_.fadeFollowDelay = 0
	v4_.showVehicleInfo = true
	v4_.isVisible = true
	v4_.controlledVehicle = nil
	v4_.isControllingPlayer = true
	v4_.displayComponents = {}
	v4_:createDisplayComponents(v5_)
	v4_.moneyChanges = {}
	IntroductionHelpHUDUtil.init()
	IntroductionHelpHUDUtil.setScale(v5_)
	local v6_ = g_messageCenter
	v6_:subscribe(MessageType.ACHIEVEMENT_UNLOCKED, v4_.showAchievementMessage, v4_)
	v6_:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.SHOW_HELP_MENU], v4_.setInputHelpVisible, v4_)
	v6_:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.UI_SCALE], v4_.onUIScaleChanged, v4_)
	addConsoleCommand("gsHudVisibility", "Toggle HUd visibility", "consoleCommandToggleVisibility", v4_)
	if g_isDevelopmentVersion then
		addConsoleCommand("gsHUDToggleUIScale", "toggles ui scale", "consoleCommandToggleUIScale", v4_)
		addConsoleCommand("gsHUDCoordinatesToggle", "toggles coordinates displayed in the bottom left of the screen", "consoleCommandToggleCoordinates", v4_)
	end
	return v4_
end

-- Local values: nameFadeTween, fadeOverlay
function HUD:createDisplayComponents(uiScale)
	self.gameInfoDisplay = GameInfoDisplay.new()
	self.gameInfoDisplay:setScale(uiScale)
	self.displayComponents.gameInfoDisplay = self.gameInfoDisplay
	self.speedMeter = SpeedMeterDisplay.new()
	self.speedMeter:setVehicle(self.controlledVehicle)
	self.speedMeter:setScale(uiScale)
	self.speedMeter:setVisible(false)
	self.displayComponents.speedMeter = self.speedMeter
	self.sideNotifications = SideNotification.new()
	self.sideNotifications:setScale(uiScale)
	self.sideNotifications:setVisible(true)
	self.displayComponents.sideNotifications = self.sideNotifications
	self.topNotification = TopNotification.new()
	self.topNotification:setScale(uiScale)
	self.topNotification:setVisible(true)
	self.displayComponents.topNotification = self.topNotification
	self.infoDisplay = InfoDisplay.new()
	self.infoDisplay:setScale(uiScale)
	self.infoDisplay:setVisible(false)
	self.displayComponents.infoDisplay = self.infoDisplay
	self.chatDisplay = ChatDisplay.new()
	self.chatDisplay:setScale(uiScale)
	self.chatDisplay:setVisible(false)
	self.displayComponents.chatDisplay = self.chatDisplay
	self.fillLevelsDisplay = FillLevelsDisplay.new()
	self.fillLevelsDisplay:setVehicle(self.controlledVehicle)
	self.fillLevelsDisplay:setScale(uiScale)
	self.fillLevelsDisplay:setVisible(false)
	self.displayComponents.fillLevelsDisplay = self.fillLevelsDisplay
	self.inputHelp = InputHelpDisplay.new()
	self.inputHelp:loadVehicleSchemaOverlays()
	self.inputHelp:setScale(uiScale)
	self.inputHelp:setVisible(g_gameSettings:getValue(GameSettings.SETTING.SHOW_HELP_MENU))
	self.displayComponents.inputHelp = self.inputHelp
	self.speakerDisplay = SpeakerDisplay.new()
	self.speakerDisplay:setScale(uiScale)
	self.speakerDisplay:setVisible(false)
	self.displayComponents.speakerDisplay = self.speakerDisplay
	self.warningDisplay = WarningDisplay.new()
	self.warningDisplay:setScale(uiScale)
	self.warningDisplay:setVisible(false)
	self.displayComponents.warningDisplay = self.warningDisplay
	self.ingameMap = IngameMap.new()
	self.ingameMap:setScale(uiScale)
	self.displayComponents.ingameMap = self.ingameMap
	self.ingameMessage = IngameMessage.new()
	self.ingameMessage:setScale(uiScale)
	self.ingameMessage:setVisible(false)
	self.displayComponents.ingameMessage = self.ingameMessage
	self.achievementMessage = AchievementMessage.new()
	self.achievementMessage:setScale(uiScale)
	self.achievementMessage:setVisible(false)
	self.displayComponents.achievementMessage = self.achievementMessage
	self.contextActionDisplay = ContextActionDisplay.new()
	self.contextActionDisplay:setScale(uiScale)
	self.contextActionDisplay:setVisible(false)
	self.displayComponents.contextActionDisplay = self.contextActionDisplay
	self.gamePausedDisplay = GamePausedDisplay.new()
	self.gamePausedDisplay:setScale(uiScale)
	self.gamePausedDisplay:setVisible(false)
	self.displayComponents.gamePausedDisplay = self.gamePausedDisplay
	self.vehicleNameDisplay = HUDTextDisplay.new(0.5, g_safeFrameOffsetY, HUD.TEXT_SIZE.VEHICLE_NAME, RenderText.ALIGN_CENTER, HUD.COLOR.VEHICLE_NAME, true)
	self.vehicleNameDisplay:setTextShadow(true, HUD.COLOR.VEHICLE_NAME_SHADOW)
	local v9_ = TweenSequence.new(self.vehicleNameDisplay)
	v9_:addTween(Tween.new(self.vehicleNameDisplay.setAlpha, 0, 1, HUD.ANIMATION.VEHICLE_NAME_FADE))
	v9_:addInterval(HUD.ANIMATION.VEHICLE_NAME_SHOW)
	v9_:addTween(Tween.new(self.vehicleNameDisplay.setAlpha, 1, 0, HUD.ANIMATION.VEHICLE_NAME_FADE))
	self.vehicleNameDisplay:setAnimation(v9_)
	self.vehicleNameDisplay:setVisible(false, false)
	local v10_ = self.displayComponents
	local v11_ = self.vehicleNameDisplay
	table.insert(v10_, v11_)
	local v12_ = g_overlayManager:createOverlay(g_plainColorSliceId, 0, 0, 1, 1)
	v12_:setColor(0, 0, 0, 0)
	self.fadeScreenElement = HUDElement.new(v12_)
	local v13_ = self.displayComponents
	local v14_ = self.fadeScreenElement
	table.insert(v13_, v14_)
end

-- Local values: k, v
function HUD:delete()
	for v16_, v17_ in pairs(self.displayComponents) do
		if v17_ then
			v17_:delete()
			self.displayComponents[v16_] = nil
		end
	end
	IntroductionHelpHUDUtil.delete()
	g_messageCenter:unsubscribeAll(self)
	removeConsoleCommand("gsHudVisibility")
	removeConsoleCommand("gsHUDToggleUIScale")
	removeConsoleCommand("gsHUDCoordinatesToggle")
end

-- Local values: _, element
function HUD:setScale(scale)
	for _, v20_ in pairs(self.displayComponents) do
		if v20_.setScale ~= nil then
			v20_:setScale(scale, scale)
		end
	end
	IntroductionHelpHUDUtil.setScale(scale)
end

function HUD:drawControlledEntityHUD()
	if self.isVisible then
		if self.controlledVehicle == nil then
			if self.isControllingPlayer and self.player ~= nil then
				self.player:draw()
				self.infoDisplay:draw()
			end
		elseif self.showVehicleInfo then
			self.controlledVehicle:draw()
		end
		self.fillLevelsDisplay:draw()
		self.speedMeter:draw()
		self.contextActionDisplay:draw()
	end
end

function HUD:drawInputHelp(offsetX, offsetY)
	if self.isVisible and (not self.ingameMessage:getVisible() and self.fadeFollowDelay <= 0) then
		self.inputHelp:draw(offsetX, offsetY)
	end
end

function HUD:drawTopNotification()
	self.topNotification:draw()
end

function HUD:drawBlinkingWarning()
	if self.warningDisplay ~= nil then
		self.warningDisplay:draw()
	end
end

function HUD:drawPOIInfo() end

function HUD:drawFading()
	if self.fadeScreenElement:getVisible() and not g_gui:getIsMenuVisible() then
		self.fadeScreenElement:draw()
	end
end

function HUD:drawOverlayAtPositionWithDimensions(overlay, screenX, screenY, screenWidth, screenHeight)
	overlay:setDimension(screenWidth, screenHeight)
	overlay:setPosition(screenX, screenY)
	overlay:render()
end

function HUD:drawOverlayAtPosition(overlay, screenX, screenY)
	overlay:setPosition(screenX, screenY)
	overlay:render()
end

function HUD:drawSideNotification()
	self.sideNotifications:draw()
end

-- Local values: x, y, z
function HUD:drawBaseHUD()
	self.ingameMap:draw()
	self.gameInfoDisplay:draw()
	self:drawSideNotification()
	self.achievementMessage:draw()
	if g_isDevelopmentVersion and (g_localPlayer ~= nil and not self.hideCoordinates) then
		local v38_, v39_, v40_ = g_localPlayer:getPosition()
		setTextBold(false)
		setTextAlignment(RenderText.ALIGN_LEFT)
		renderText(0.003, 0.003, 0.012, string.format("<%.02f %0.2f %0.2f>", v38_, v39_, v40_))
	end
end

function HUD:drawCommunicationDisplay()
	if self.isVisible and not self:getIsFading() then
		self.chatDisplay:draw()
		self.speakerDisplay:draw()
	end
end

function HUD:drawGamePaused(beforeMissionStart)
	self.gamePausedDisplay:draw(beforeMissionStart)
end

-- Local values: hasVehicle, isObstructed
function HUD:drawVehicleName()
	local v45_ = self.currentVehicleName ~= nil
	local v46_ = self.ingameMessage:getVisible() or self.contextActionDisplay:getVisible()
	if not g_gui:getIsMenuVisible() and (v45_ and not v46_) then
		self.vehicleNameDisplay:draw()
	end
end

function HUD:drawInGameMessageAndIcon()
	self.ingameMessage:draw()
end

function HUD:showInGameMessage(title, message, duration, controlGlyphs, callback, callbackTarget)
	self.ingameMessage:showMessage(title, message, duration, controlGlyphs, callback, callbackTarget)
end

function HUD:isInGameMessageVisible()
	return self.ingameMessage:getVisible()
end

function HUD:showBlinkingWarning(text, durationMs, customIdentifier)
	if text ~= nil then
		self.warningDisplay:addWarning(text, durationMs or 2000, customIdentifier)
	end
end

function HUD:addMoneyChange(moneyType, amount)
	if self.moneyChanges[moneyType.id] == nil then
		self.moneyChanges[moneyType.id] = 0
	end
	self.moneyChanges[moneyType.id] = self.moneyChanges[moneyType.id] + amount
end

-- Local values: change, sound
function HUD:showMoneyChange(moneyType, text)
	if self.moneyChanges[moneyType.id] ~= nil and self.moneyChanges[moneyType.id] ~= 0 then
		local v66_ = self.moneyChanges[moneyType.id]
		if text == nil then
			text = g_i18n:getText(moneyType.title, moneyType.customEnv)
		end
		local v67_ = (text == nil or text == "") and "" or " (" .. text .. ")"
		if v66_ > 0 then
			local v68_ = GuiSoundPlayer.SOUND_SAMPLES.TRANSACTION
			if moneyType == MoneyType.COLLECTIBLE then
				v68_ = GuiSoundPlayer.SOUND_SAMPLES.COLLECTIBLE
			end
			self:addSideNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format("+ %s%s", g_i18n:formatMoney(v66_, 0, true), v67_), nil, v68_)
		elseif v66_ <= -1 then
			self:addSideNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format("- %s%s", g_i18n:formatMoney(math.abs(v66_), 0, true), v67_), nil, GuiSoundPlayer.SOUND_SAMPLES.TRANSACTION)
		end
		self.moneyChanges[moneyType.id] = 0
	end
end

function HUD:addExtraPrintText(text)
	self.inputHelp:addHelpText(text)
end

function HUD:addHelpExtension(extension)
	self.inputHelp:addHelpExtension(extension)
end

function HUD:addInfoExtension(extension)
	self.inputHelp:addInfoExtension(extension)
end

function HUD:removeInfoExtension(extension)
	self.inputHelp:removeInfoExtension(extension)
end

function HUD:showVehicleName(vehicleName)
	self.vehicleNameDisplay:setVisible(false, true)
	self.currentVehicleName = vehicleName
	self.vehicleNameDisplay:setText(vehicleName)
	self.vehicleNameDisplay:setVisible(true, true)
	self.vehicleNameTextTime = HUD.ANIMATION.VEHICLE_NAME_SHOW + HUD.ANIMATION.VEHICLE_NAME_FADE * 2
end

function HUD:addSideNotification(color, text, duration, sound)
	self.sideNotifications:addNotification(text, color, duration or 12000)
	if sound ~= nil then
		g_gui.guiSoundPlayer:playSample(sound)
	end
end

function HUD:addSideNotificationProgressBar(title, text, progress)
	return self.sideNotifications:addProgressBar(title, text, progress)
end

function HUD:removeSideNotificationProgressBar(progressBar)
	self.sideNotifications:removeProgressBar(progressBar)
end

function HUD:markSideNotificationProgressBarForDrawing(progressBar)
	self.sideNotifications:markProgressBarForDrawing(progressBar)
end

function HUD:setIsSaving(isSaving)
	self.sideNotifications:setIsSaving(isSaving)
end

function HUD:addTopNotification(title, text, info, iconFilename, duration)
	self.topNotification:setNotification(title, text, info, iconFilename, duration)
end

function HUD:hideTopNotification()
	self.topNotification:hide()
end

function HUD:getIsFading()
	return not self.fadeAnimation:getFinished() or self.fadeScreenElement:getAlpha() > 0
end

function HUD:onPauseGameChange(isPaused, pauseText)
	if isPaused ~= nil then
		self.ingameMessage:setPaused(isPaused)
		self.gamePausedDisplay:setVisible(isPaused)
	end
	self.gamePausedDisplay:setPauseText(pauseText)
end

function HUD:setIsVisible(isVisible)
	self.isVisible = isVisible
end

function HUD:setInputHelpVisible(isVisible, skipAnimation)
	self.inputHelp:setVisible(isVisible)
end

function HUD:onUIScaleChanged(uiScale)
	self:setScale(uiScale)
end

function HUD:setInfoVisible(isVisible)
	self.infoDisplay:setEnabled(isVisible)
end

function HUD:getIsVisible()
	return self.isVisible
end

function HUD:setControlledVehicle(vehicle)
	self.controlledVehicle = vehicle
	self.inputHelp:setVehicle(vehicle)
	self.speedMeter:setVehicle(vehicle)
	local v116_ = self.speedMeter
	local v117_
	if vehicle == nil then
		v117_ = false
	else
		v117_ = vehicle.spec_motorized ~= nil
	end
	v116_:setVisible(v117_, true)
	self.fillLevelsDisplay:setVehicle(vehicle)
	self.fillLevelsDisplay:setVisible(vehicle ~= nil)
end

function HUD:setIsControllingPlayer(isControllingPlayer)
	self.isControllingPlayer = isControllingPlayer
end

function HUD:setMoneyUnit(unit) end

function HUD:showAchievementMessage(achievementName, achievementDescription, iconFilename, iconUVs)
	self.achievementMessage:showMessage(achievementName, achievementDescription, iconFilename, iconUVs, HUD.ACHIEVEMENT_DISPLAY_DURATION)
end

-- Local values: actionText
function HUD:showAttachContext(attachVehicleName)
	local v127_ = g_i18n:getText("input_ATTACH")
	self.contextActionDisplay:setContext(InputAction.ATTACH, ContextActionDisplay.CONTEXT_ICON.ATTACH, attachVehicleName, HUD.CONTEXT_PRIORITY.LOW, v127_)
end

-- Local values: actionText
function HUD:showTipContext(fillTypeName)
	local v130_ = g_i18n:getText("input_TOGGLE_TIPSTATE")
	self.contextActionDisplay:setContext(InputAction.TOGGLE_TIPSTATE, ContextActionDisplay.CONTEXT_ICON.TIP, fillTypeName, HUD.CONTEXT_PRIORITY.MEDIUM, v130_)
end

-- Local values: actionText
function HUD:showFuelContext(fuelingVehicleName)
	local v133_ = g_i18n:getText("action_refuel")
	self.contextActionDisplay:setContext(InputAction.ACTIVATE_OBJECT, ContextActionDisplay.CONTEXT_ICON.FUEL, fuelingVehicleName, HUD.CONTEXT_PRIORITY.HIGH, v133_)
end

-- Local values: actionText, targetText
function HUD:showFillDogBowlContext(dogName)
	local v136_ = g_i18n:getText("action_doghouseFillbowl")
	self.contextActionDisplay:setContext(InputAction.ACTIVATE_OBJECT, ContextActionDisplay.CONTEXT_ICON.FILL_BOWL, dogName or "", HUD.CONTEXT_PRIORITY.LOW, v136_)
end

function HUD:setPlayer(player)
	self.player = player
end

function HUD:updateMessage(dt)
	self.ingameMessage:update(dt)
end

function HUD:update(dt)
	if not self.fadeAnimation:getFinished() then
		self.fadeAnimation:update(dt)
	end
	self.fadeFollowDelay = self.fadeFollowDelay - dt
	self.speedMeter:update(dt)
	self.fillLevelsDisplay:update(dt)
	self.contextActionDisplay:update(dt)
	self.achievementMessage:update(dt)
	self.sideNotifications:update(dt)
	self.topNotification:update(dt)
	if g_currentMission.missionDynamicInfo.isMultiplayer then
		self.chatDisplay:update(dt)
		self.speakerDisplay:update(dt)
		self.ingameMap:setHasUnreadMessages(self.chatDisplay:getHasNewMessages())
	end
end

function HUD:updateBlinkingWarning(dt)
	if self.warningDisplay ~= nil then
		self.warningDisplay:update(dt)
	end
end

function HUD:updateMap(dt)
	self.ingameMap:update(dt)
end

function HUD:postUpdateMap(dt)
	self.ingameMap:postUpdate(dt)
end

function HUD:updateVehicleName(dt)
	if self.currentVehicleName ~= nil then
		self.vehicleNameTextTime = self.vehicleNameTextTime - dt
		self.vehicleNameDisplay:update(dt)
		if self.vehicleNameTextTime < 0 then
			self.currentVehicleName = nil
			self.vehicleNameDisplay:setVisible(false, false)
		end
	end
end

-- Local values: startAlpha, endAlpha, callbackClosure, seq, tween
function HUD:fadeScreen(direction, duration, callbackFunc, callbackTarget, arguments)
	local v157_, v158_
	if direction <= 0 then
		v157_ = 1
		v158_ = 0
	else
		v157_ = 0
		v158_ = 1
	end
	local v159_ = TweenSequence.new(self.fadeScreenElement)
	local v160_ = Tween.new(self.fadeScreenElement.setAlpha, v157_, v158_, duration)
	v160_:setCurve(Tween.CURVE.EASE_IN)
	v159_:addTween(v160_)
	v159_:addCallback(function()
		-- upvalues: (copy) callbackFunc, (copy) callbackTarget, (copy) arguments, (copy) self
		if callbackFunc ~= nil then
			callbackFunc(callbackTarget, arguments)
		end
		self.fadeFollowDelay = HUD.FADE_FOLLOW_DELAY
	end)
	v159_:start()
	self.fadeAnimation = v159_
end

function HUD:loadIngameMap(ingameMapFilename, ingameMapWidth, ingameMapHeight, fieldColor, grassFieldColor)
	self.ingameMap:loadMap(ingameMapFilename, ingameMapWidth, ingameMapHeight, fieldColor, grassFieldColor)
end

function HUD:setIngameMapSize(sizeIndex)
	if Platform.isMobile then
		sizeIndex = sizeIndex ~= IngameMapState.OFF
	end
	self.ingameMap:toggleSize(sizeIndex)
end

function HUD:getIngameMap()
	return self.ingameMap
end

function HUD:mouseEvent(posX, posY, isDown, isUp, button) end

function HUD:setMissionInfo(missionInfo)
	self.missionInfo = missionInfo
	self.fillLevelsDisplay:resetFillTypes()
end

function HUD:scrollChatMessages(delta)
	self.chatDisplay:scrollChatMessages(delta)
end

function HUD:setChatDisplayVisible(isVisible)
	self.chatDisplay:setVisible(isVisible)
end

function HUD:setChatMessagesReference(chatMessages)
	self.chatDisplay:setChatMessages(chatMessages)
end

function HUD:addChatMessage(msg, sender, farmId)
	self.chatDisplay:addMessage(msg, sender, farmId)
	self.chatDisplay:setVisible(true)
end

function HUD:registerInput()
	self.ingameMap:registerInput()
end

function HUD:addMapHotspot(hotspot)
	return self.ingameMap:addMapHotspot(hotspot)
end

function HUD:removeMapHotspot(hotspot)
	self.ingameMap:removeMapHotspot(hotspot)
end

-- Local values: uiScale, newUIScale
function HUD:consoleCommandToggleUIScale()
	local v187_ = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE) + 0.05
	local v188_ = v187_ > 1.04 and 0.5 or v187_
	g_gameSettings:setValue(SettingsModel.SETTING.UI_SCALE, v188_, false)
	return string.format("New UI Scale: %d%%", v188_ * 100)
end

function HUD:consoleCommandToggleVisibility()
	self:setIsVisible(not self:getIsVisible())
	if self:getIsVisible() then
		g_noHudModeEnabled = false
		return "HUD is now visible"
	else
		g_noHudModeEnabled = true
		return "Warning: HUD is now disabled. Use \'gsHudVisibility\' to enable again"
	end
end

function HUD:consoleCommandToggleCoordinates()
	self.hideCoordinates = not self.hideCoordinates
end
HUD.COLOR = {
	["BACKGROUND"] = {
		0.00439,
		0.00478,
		0.00368,
		0.65
	},
	["BACKGROUND_DARK"] = {
		0.00439,
		0.00478,
		0.00368,
		0.9
	},
	["ACTIVE"] = {
		0.2384,
		0.4621,
		0.0015,
		1
	},
	["AVAILABLE"] = {
		1,
		0.4287,
		0.0006,
		1
	},
	["INACTIVE"] = {
		1,
		1,
		1,
		0.3
	},
	["DEFAULT"] = {
		1,
		1,
		1,
		1
	},
	["FRAME_BACKGROUND"] = {
		0.01,
		0.01,
		0.01,
		0.6
	},
	["VEHICLE_NAME"] = {
		1,
		1,
		1,
		1
	},
	["VEHICLE_NAME_SHADOW"] = {
		0,
		0,
		0,
		1
	}
}
HUD.TEXT_SIZE = {
	["VEHICLE_NAME"] = 36
}
HUD.ANIMATION = {
	["VEHICLE_NAME_FADE"] = 1000,
	["VEHICLE_NAME_SHOW"] = 3000
}
