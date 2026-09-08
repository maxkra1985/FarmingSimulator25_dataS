-- Local values: MultiplayerScreen_mt
MultiplayerScreen = {}
MultiplayerScreen.NUM_HINTS = 7
MultiplayerScreen.HINTS_KEY = "ui_joinMultiplayerHint"
local MultiplayerScreen_mt = Class(MultiplayerScreen, ScreenElement)
function MultiplayerScreen.register()
	local v2_ = MultiplayerScreen.new()
	g_gui:loadGui("dataS/gui/MultiplayerScreen.xml", "MultiplayerScreen", v2_)
	return v2_
end

-- Upvalues: MultiplayerScreen_mt
-- Local values: self
function MultiplayerScreen.new(target, custom_mt)
	-- upvalues: (copy) MultiplayerScreen_mt
	local v5_ = ScreenElement.new(target, custom_mt or MultiplayerScreen_mt)
	v5_.returnScreenClass = MainScreen
	v5_.gameplayHintsInitialized = false
	v5_.gameplayHintDuration = 6500
	v5_.gameplayHintTime = v5_.gameplayHintDuration
	return v5_
end

-- Local values: newGui
function MultiplayerScreen.createFromExistingGui(gui, guiName)
	local v8_ = MultiplayerScreen.new()
	g_gui.guis[guiName]:delete()
	g_gui.guis[guiName].target:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v8_)
	return v8_
end

-- Local values: hints, i
function MultiplayerScreen:onOpen()
	MultiplayerScreen:superClass().onOpen(self)
	self:initJoinGameScreen()
	g_startMissionInfo.createGame = false
	g_startMissionInfo.isMultiplayer = true
	if g_startMissionInfo.canStart then
		g_startMissionInfo.canStart = false
		self:changeScreen(ConnectToMasterServerScreen)
		g_connectToMasterServerScreen:connectToFront()
	end
	self:updateOnlinePresenceName()
	self.listCoop:reloadData()
	FocusManager:linkElements(self.listCoop, FocusManager.RIGHT, nil)
	FocusManager:linkElements(self.listCoop, FocusManager.TOP, nil)
	FocusManager:setFocus(self.listCoop)
	local v10_ = {}
	for v11_ = 1, MultiplayerScreen.NUM_HINTS do
		local v12_ = g_i18n
		local v13_ = MultiplayerScreen.HINTS_KEY .. tostring(v11_)
		table.insert(v10_, v12_:getText(v13_))
	end
	self.gameplayHintsInitialized = true
	self.gameplayHintSelector:setTexts(v10_)
	self.hintStateBox:setPageCount(MultiplayerScreen.NUM_HINTS)
	self.gameplayHintTime = self.gameplayHintDuration
end

function MultiplayerScreen:updateOnlinePresenceName()
	self.onlineNameText:setText(g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME))
	if self.onlineNameBox ~= nil then
		self.onlineNameBox:invalidateLayout()
		self.onlineNameBoxBg:setSize(self.onlineNameBox.flowSizes[1] + 65 * g_pixelSizeScaledX)
	end
	if Platform.canChangeGamerTag then
		self.changeNameButton:setVisible(true)
	else
		self.changeNameButton:setVisible(false)
	end
	self.changeNameButton.parent:invalidateLayout()
end

function MultiplayerScreen:initJoinGameScreen()
	g_connectionManager:startupWithWorkingPort(g_gameSettings:getValue(GameSettings.SETTING.DEFAULT_SERVER_PORT))
	g_connectToMasterServerScreen:setNextScreenClass(JoinGameScreen)
	g_connectToMasterServerScreen:setPrevScreenClass(MultiplayerScreen)
end

-- Local values: index
function MultiplayerScreen:onContinue()
	if FocusManager:getFocusedElement() == self.listCoop then
		local v16_ = self.listCoop.selectedIndex
		if v16_ == 1 then
			g_startMissionInfo.canStart = false
			self:changeScreen(ConnectToMasterServerScreen)
			g_connectToMasterServerScreen:connectToFront()
			return
		end
		if v16_ == 2 then
			g_startMissionInfo.canStart = false
			g_createGameScreen.usePendingInvites = false
			self:changeScreen(CareerScreen)
			return
		end
		if v16_ == 3 then
			openWebFile(Platform.urlDedicatedServer, "")
		end
	end
end

function MultiplayerScreen:onClickCreateGame()
	self.listCoop:setSelectedIndex(2)
	self:onContinue()
end

function MultiplayerScreen:onClickJoinGame()
	self.listCoop:setSelectedIndex(1)
	self:onContinue()
end

function MultiplayerScreen:update(dt)
	MultiplayerScreen:superClass().update(self, dt)
	Platform.verifyMultiplayerAvailabilityInMenu()
	self.natWarning:setVisible(getNATType() == NATType.NAT_STRICT)
	self.gameplayHintTime = self.gameplayHintTime - dt
	if self.gameplayHintTime <= 0 then
		self.gameplayHintTime = self.gameplayHintDuration
		self.gameplayHintSelector.soundDisabled = true
		self.gameplayHintSelector:onRightButtonClicked(nil, true)
		self.gameplayHintSelector.soundDisabled = false
	end
end

-- Local values: text, callback, defaultText, confirmText
function MultiplayerScreen:onClickChangeName()
	local v22_ = g_i18n:getText("ui_enterName")
	local v23_ = g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME)
	local v24_ = g_i18n:getText("button_change")
	TextInputDialog.show(function(p25_)
		-- upvalues: (copy) self
		if p25_ ~= g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME) then
			g_gameSettings:setValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME, p25_, true)
			self:updateOnlinePresenceName()
		end
	end, nil, v23_, nil, nil, nil, v24_, nil, v22_)
end

function MultiplayerScreen:onClickOpenBlocklist()
	UnBanDialog.show(nil, nil, true)
end

function MultiplayerScreen:getNumberOfItemsInSection(list, section)
	return Platform.showRentServerWebButton and list == self.listCoop and 3 or 2
end

function MultiplayerScreen:populateCellForItemInSection(list, section, index, cell)
	if list == self.listCoop then
		if index == 1 then
			cell:getAttribute("title"):setLocaKey("button_joinGame")
			cell:getAttribute("text"):setLocaKey("ui_coop_join_short")
			cell:getAttribute("icon"):setImageSlice(nil, "gui.icon_multiplayer_joinServer")
			return
		end
		if index == 2 then
			cell:getAttribute("title"):setLocaKey("button_createGame")
			cell:getAttribute("text"):setLocaKey("ui_coop_create_short")
			cell:getAttribute("icon"):setImageSlice(nil, "gui.icon_multiplayer_createServer")
			return
		end
		if index == 3 then
			cell:getAttribute("title"):setLocaKey("button_rentAServer")
			cell:getAttribute("text"):setLocaKey("ui_coop_dedicated_short")
			cell:getAttribute("icon"):setImageSlice(nil, "gui.icon_multiplayer_rentDedi")
		end
	end
end
