RestartManager = {}
RestartManager.START_SCREEN_MAIN = 1
RestartManager.START_SCREEN_JOIN_GAME = 2
RestartManager.START_SCREEN_MULTIPLAYER = 3
RestartManager.START_SCREEN_SETTINGS = 5
RestartManager.START_SCREEN_SETTINGS_ADVANCED = 6
RestartManager.START_SCREEN_GAMEPAD_SIGNIN = 7

function RestartManager:init(args)
	self.restarting = string.find(args, "-restart") ~= nil
end

-- Local values: startScreen
function RestartManager:handleRestart()
	local v4_ = getStartMode()
	if v4_ == RestartManager.START_SCREEN_MAIN then
		g_gui:showGui("MainScreen")
	elseif v4_ == RestartManager.START_SCREEN_JOIN_GAME then
		g_multiplayerScreen:onJoinGameClick()
	elseif v4_ == RestartManager.START_SCREEN_MULTIPLAYER then
		g_gui:showGui("MainScreen")
		g_mainScreen:onMultiplayerClickPerform()
	elseif v4_ == RestartManager.START_SCREEN_SETTINGS then
		g_gui:showGui("SettingsScreen")
		g_settingsScreen:showGeneralSettings()
	elseif v4_ == RestartManager.START_SCREEN_SETTINGS_ADVANCED then
		g_gui:showGui("SettingsScreen")
		g_settingsScreen:showDisplaySettings()
	elseif v4_ == RestartManager.START_SCREEN_GAMEPAD_SIGNIN then
		g_gui:showGui("GamepadSigninScreen")
	end
	if not Platform.isConsole and promptUserConfirmScreenMode() then
		self.restartDisplayTime = 15000
		local v5_ = YesNoDialog.show
		local v6_ = self.restartDisplayOk
		local v7_ = g_i18n:getText("dialog_keepDisplayProperties")
		local v8_ = self.restartDisplayTime / 1000
		self.dialog = v5_(v6_, self, v7_ .. "\n" .. tostring(v8_))
		self.restartDisplayTimerId = addTimer(1000, "restartDisplayTimeUpdate", self)
	end
end

function RestartManager:setStartScreen(screen)
	setStartMode(screen)
end

function RestartManager:restartDisplayTimeUpdate()
	self.restartDisplayTime = self.restartDisplayTime - 1000
	if self.restartDisplayTime <= 0 then
		self.restartDisplayTime = nil
		self.restartDisplayTimerId = nil
		self:restartDisplayNotOk()
		return false
	end
	local v11_ = self.dialog
	local v12_ = g_i18n:getText("dialog_keepDisplayProperties")
	local v13_ = self.restartDisplayTime / 1000
	v11_:setText(v12_ .. "\n" .. tostring(v13_))
	setTimerTime(self.restartDisplayTimerId, 1000)
	return true
end

function RestartManager:restartDisplayOk(yes)
	removeTimer(self.restartDisplayTimerId)
	self.restartDisplayTime = nil
	self.restartDisplayTimerId = nil
	if yes then
		setUserConfirmScreenMode(true)
	else
		self:restartDisplayNotOk()
	end
end

function RestartManager:restartDisplayNotOk()
	setUserConfirmScreenMode(false)
	doRestart(true, "")
end
