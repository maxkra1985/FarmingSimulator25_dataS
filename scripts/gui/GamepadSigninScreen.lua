-- Local values: GamepadSigninScreen_mt
GamepadSigninScreen = {}
local GamepadSigninScreen_mt = Class(GamepadSigninScreen, ScreenElement)
function GamepadSigninScreen.register()
	local v2_ = GamepadSigninScreen.new()
	g_gui:loadGui("dataS/gui/GamepadSigninScreen.xml", "GamepadSigninScreen", v2_)
	return v2_
end

-- Upvalues: GamepadSigninScreen_mt
-- Local values: self
function GamepadSigninScreen.new(target, custom_mt)
	-- upvalues: (copy) GamepadSigninScreen_mt
	local v5_ = GamepadSigninScreen:superClass().new(target, custom_mt or GamepadSigninScreen_mt)
	v5_.textSpeed = 600
	v5_.textTime = 0
	v5_.textDir = 1
	v5_.textColor1 = {
		1,
		1,
		1,
		1
	}
	v5_.textColor2 = {
		1,
		1,
		1,
		0
	}
	v5_.textColor = {
		1,
		1,
		0.25,
		1
	}
	v5_.forceShowSigninGui = false
	v5_.requestCounter = -1
	return v5_
end

-- Local values: newGui
function GamepadSigninScreen.createFromExistingGui(gui, guiName)
	local v8_ = GamepadSigninScreen.new()
	g_gui.guis[guiName]:delete()
	g_gui.guis[guiName].target:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v8_)
	return v8_
end

function GamepadSigninScreen:onCreate() end

function GamepadSigninScreen:onOpen()
	g_isSignedIn = false
	startMenuMusic()
	if g_currentMission ~= nil and g_currentMission.missionDynamicInfo.isMultiplayer then
		g_currentMission:cancelPlayersSynchronizing()
	end
	if g_modNameToDirectory[g_uniqueDlcNamePrefix .. "highlandsFishingPack"] == nil then
		self.backgroundImage:setImageFilename("shared/splash.png")
	else
		self.backgroundImage:setImageFilename("shared/splash_highlandsFishing.png")
	end
	self.requestCounter = 2
end

function GamepadSigninScreen:onClose() end

-- Local values: colorAlpha, i
function GamepadSigninScreen:update(dt)
	GamepadSigninScreen:superClass().update(self, dt)
	if isGamepadSigninPending() then
		self.startText:setText("...")
	else
		self.startText:setText(g_i18n:getText("ui_consolePressStart"))
	end
	self.textTime = self.textTime + self.textDir * dt
	if self.textTime > self.textSpeed then
		self.textTime = self.textSpeed
		self.textDir = -self.textDir
	end
	if self.textTime < 0 then
		self.textTime = 0
		self.textDir = -self.textDir
	end
	local v12_ = self.textTime / self.textSpeed
	for v13_ = 1, 4 do
		self.textColor[v13_] = (1 - v12_) * self.textColor1[v13_] + self.textColor2[v13_] * v12_
	end
	if self.requestCounter >= 0 then
		self.requestCounter = self.requestCounter - 1
		if self.requestCounter < 0 then
			requestGamepadSignin(Input.BUTTON_2, self.forceShowSigninGui, true)
		end
	end
	local v14_ = self.startText
	local v15_ = self.textColor
	v14_:setTextColor(unpack(v15_))
	self.startText:setText2Color(self.startText.text2Color[1], self.startText.text2Color[2], self.startText.text2Color[3], self.startText.textColor[4])
end

function GamepadSigninScreen:onYesNoSigninAccept(yes)
	if yes then
		self.forceShowSigninGui = true
		self:changeScreen(GamepadSigninScreen)
	else
		g_tempDeepLinkingInfo = nil
		self:changeScreen(MainScreen)
	end
end

function GamepadSigninScreen:inputEvent(action, value, eventUsed)
	if action == InputAction.MENU_ACCEPT and self.requestCounter < 0 then
		self:signIn()
		eventUsed = true
	end
	return eventUsed
end

-- Local values: resumeGame, newUserName, requestUserName, info
function GamepadSigninScreen:signIn()
	g_achievementManager:resetAchievementsState()
	self.forceShowSigninGui = false
	g_isSignedIn = true
	local v22_ = g_currentMission ~= nil
	if GS_PLATFORM_XBOX then
		local v23_ = g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME)
		if v23_ ~= g_currentPlayingUserName then
			v22_ = false
		end
		g_currentPlayingUserName = v23_
	end
	if g_tempDeepLinkingInfo == nil then
		if v22_ then
			if g_currentMission.missionDynamicInfo.isMultiplayer then
				g_currentMission:cancelPlayersSynchronizing()
				self:changeScreen(InGameMenu)
				g_inGameMenu:setMasterServerConnectionFailed(MasterServerConnection.FAILED_CONNECTION_LOST)
			else
				g_currentMission.userSigninPaused = false
				g_currentMission:tryUnpauseGame()
				self:changeScreen(nil)
			end
		end
		if g_currentMission ~= nil then
			OnInGameMenuMenu()
		end
		self:changeScreen(MainScreen)
	else
		local v24_ = g_tempDeepLinkingInfo.requestUserName
		if GS_PLATFORM_XBOX and (v24_ ~= "" and g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME) ~= v24_) then
			YesNoDialog.show(self.onYesNoSigninAccept, self, string.format(g_i18n:getText("ui_signinWithUserToAcceptInviteRetry"), v24_))
			return
		end
		local v25_ = g_tempDeepLinkingInfo
		g_tempDeepLinkingInfo = nil
		if PlatformPrivilegeUtil.checkMultiplayer(acceptedGameInvitePerformConnect, nil, v25_.platformServerId, 30000) then
			acceptedGameInvitePerformConnect(v25_.platformServerId)
			return
		end
	end
end
