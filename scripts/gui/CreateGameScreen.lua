-- Local values: CreateGameScreen_mt
CreateGameScreen = {}
local CreateGameScreen_mt = Class(CreateGameScreen, ScreenElement)
function CreateGameScreen.register()
	local v2_ = CreateGameScreen.new()
	g_gui:loadGui("dataS/gui/CreateGameScreen.xml", "CreateGameScreen", v2_)
	return v2_
end

-- Upvalues: CreateGameScreen_mt
-- Local values: self
function CreateGameScreen.new(target, custom_mt)
	-- upvalues: (copy) CreateGameScreen_mt
	local v5_ = ScreenElement.new(target, custom_mt or CreateGameScreen_mt)
	v5_.capacityTable = { "2" }
	v5_.capacityNumberTable = { 2 }
	v5_.lastCheckedPort = nil
	v5_.isPortTesting = false
	v5_.mappedPortUDP = 0
	v5_.mappedPortTCP = 0
	v5_.connectionsTable = {}
	v5_.connectionsInfos = {}
	if Platform.hasNetworkSettings then
		local v6_ = v5_.connectionsTable
		table.insert(v6_, "DSL 6000 (6/0.5 Mbit/s)")
		local v7_ = v5_.connectionsInfos
		table.insert(v7_, {
			["maxCapacity"] = 4,
			["uploadRate"] = 50
		})
		local v8_ = v5_.connectionsTable
		table.insert(v8_, "DSL 16000 (16/1 Mbit/s)")
		local v9_ = v5_.connectionsInfos
		table.insert(v9_, {
			["maxCapacity"] = 8,
			["uploadRate"] = 80
		})
		local v10_ = v5_.connectionsTable
		table.insert(v10_, "DSL 25 (25/5 Mbit/s)")
		local v11_ = v5_.connectionsInfos
		table.insert(v11_, {
			["maxCapacity"] = 10,
			["uploadRate"] = 150
		})
		local v12_ = v5_.connectionsTable
		table.insert(v12_, "DSL 50 (50/10 Mbit/s)")
		local v13_ = v5_.connectionsInfos
		table.insert(v13_, {
			["maxCapacity"] = 12,
			["uploadRate"] = 250
		})
		local v14_ = v5_.connectionsTable
		table.insert(v14_, "DSL 100 (100/20 Mbit/s)")
		local v15_ = v5_.connectionsInfos
		table.insert(v15_, {
			["maxCapacity"] = 16,
			["uploadRate"] = 500
		})
		local v16_ = v5_.connectionsTable
		table.insert(v16_, "LAN (100/100 Mbit/s)")
		local v17_ = v5_.connectionsInfos
		table.insert(v17_, {
			["maxCapacity"] = 16,
			["uploadRate"] = 1000
		})
		v5_.dedicatedServerConnectionIndex = #v5_.connectionsTable - 1
	else
		local v18_ = v5_.connectionsTable
		table.insert(v18_, "16Mbps/1Mbps")
		local v19_ = v5_.connectionsInfos
		local v20_ = {
			["maxCapacity"] = g_serverMaxCapacity,
			["uploadRate"] = 80
		}
		table.insert(v19_, v20_)
		v5_.dedicatedServerConnectionIndex = 1
	end
	v5_.defaultServerName = ""
	v5_.lastUserName = ""
	v5_.allowOnlyFriends = false
	v5_.allowCrossPlay = false
	v5_.autoAccept = false
	v5_.usePendingInvites = false
	v5_.mpLanguage = g_gameSettings:getValue(GameSettings.SETTING.MP_LANGUAGE)
	v5_.blockTime = 0
	return v5_
end

-- Local values: startMissionInfo, newGui
function CreateGameScreen.createFromExistingGui(gui, guiName)
	local v23_ = gui.startMissionInfo
	local v24_ = CreateGameScreen.new(nil, nil, v23_)
	g_gui.guis[guiName]:delete()
	g_gui.guis[guiName].target:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v24_)
	return v24_
end

function CreateGameScreen:onCreate()
	self.portElementBox:setVisible(Platform.hasNetworkSettings)
	self.bandwidthElementBox:setVisible(Platform.hasNetworkSettings)
	self.allowOnlyFriendsElementBox:setVisible(Platform.hasFriendFilter)
	self.changeButton:setVisible(GS_IS_CONSOLE_VERSION)
	self.buttonBox:invalidateLayout()
	self.settingsBox:invalidateLayout()
end

-- Local values: name, nickname
function CreateGameScreen:getDefaultServerName()
	local v26_ = g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME)
	if g_languageShort == "pl" then
		return v26_ .. " - " .. g_i18n:getText("ui_serverNameGame")
	elseif v26_:endsWith("s") then
		return v26_ .. "\' " .. g_i18n:getText("ui_serverNameGame")
	elseif v26_:endsWith("\'") then
		return v26_ .. "s " .. g_i18n:getText("ui_serverNameGame")
	else
		return v26_ .. "\'s " .. g_i18n:getText("ui_serverNameGame")
	end
end

function CreateGameScreen:onCreateNumPlayer(element)
	self.capacityElement = element
	element:setTexts(self.capacityTable)
	element:setState(#self.capacityTable)
end

function CreateGameScreen:onCreateBandwidth(element)
	self.bandwidthElement = element
	element:setTexts(self.connectionsTable)
end

-- Local values: languageTable, numL, i
function CreateGameScreen:onCreateMultiplayerLanguage(element)
	self.multiplayerLanguageElement = element
	local v33_ = {}
	for v34_ = 0, getNumOfLanguages() - 1 do
		local v35_ = getLanguageName
		table.insert(v33_, v35_(v34_))
	end
	element:setTexts(v33_)
end

-- Local values: mpAvailibility, _, reloadSettings, bandwidth, capacityState, numPlayers, i, map
function CreateGameScreen:onOpen()
	CreateGameScreen:superClass().onOpen(self)
	local v37_, _ = getCrossPlayAvailability(false)
	self.allowCrossPlayElementBox:setVisible(v37_ == MultiplayerAvailability.AVAILABLE)
	local v38_ = not self.settingsLoaded
	if GS_IS_CONSOLE_VERSION then
		if self.lastUserName ~= g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME) then
			self.lastUserName = g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME)
			v38_ = true
		end
		FocusManager:setFocus(self.serverNameElement)
	end
	if v38_ then
		local v39_ = g_gameSettings:getTableValue(GameSettings.SETTING.CREATE_GAME, "bandwidth")
		local v40_ = self.bandwidthElement
		local v41_ = Utils.getNoNil(v39_, 2)
		local v42_ = #self.connectionsTable
		v40_:setState((math.clamp(v41_, 1, v42_)))
	end
	self:fillCapacity()
	local v43_ = #self.capacityNumberTable
	if v38_ then
		self.settingsLoaded = true
		self.defaultServerName = self:getDefaultServerName()
		self.serverNameElement:setText(Utils.getNoNil(g_gameSettings:getTableValue(GameSettings.SETTING.CREATE_GAME, "serverName"), self.defaultServerName))
		self.passwordElement:setText(Utils.getNoNil(g_gameSettings:getTableValue(GameSettings.SETTING.CREATE_GAME, "password"), ""))
		local v44_ = self.portElement
		local v45_ = Utils.getNoNil
		local v46_ = g_gameSettings:getTableValue(GameSettings.SETTING.CREATE_GAME, "port")
		local v47_ = g_gameSettings
		local v48_ = GameSettings.SETTING.DEFAULT_SERVER_PORT
		v44_:setText((tostring(v45_(v46_, v47_:getValue(v48_)))))
		self.autoAccept = Utils.getNoNil(g_gameSettings:getTableValue(GameSettings.SETTING.CREATE_GAME, "autoAccept"), false)
		self.autoAcceptElement:setIsChecked(self.autoAccept, true)
		self.allowOnlyFriends = Utils.getNoNil(g_gameSettings:getTableValue(GameSettings.SETTING.CREATE_GAME, "allowOnlyFriends"), false)
		self.allowOnlyFriendsElement:setIsChecked(self.allowOnlyFriends, true)
		local v49_ = Utils.getNoNil(g_gameSettings:getTableValue(GameSettings.SETTING.CREATE_GAME, "allowCrossPlay"), false)
		if v49_ then
			v49_ = v37_ == MultiplayerAvailability.AVAILABLE
		end
		self.allowCrossPlay = v49_
		self.allowCrossPlayElement:setIsChecked(self.allowCrossPlay, true)
		self.mpLanguage = Utils.getNoNil(g_gameSettings:getValue(GameSettings.SETTING.MP_LANGUAGE), g_language)
		self.multiplayerLanguageElement:setState(self.mpLanguage + 1)
		local v50_ = g_gameSettings:getTableValue(GameSettings.SETTING.CREATE_GAME, "capacity")
		if v50_ ~= nil then
			for v51_ = 1, #self.capacityNumberTable do
				if v50_ == self.capacityNumberTable[v51_] then
					v43_ = v51_
					break
				end
			end
		end
	end
	self.capacityElement:setState(v43_)
	local v52_ = g_mapManager:getMapById(self.missionInfo.mapId)
	if v52_ ~= nil then
		self.mapBackground:setImageFilename(v52_.iconFilename)
	end
	self.mapBackground:setVisible(v52_ ~= nil)
	self.isTyping = false
	self.isPortTesting = false
	self.settingsBox:invalidateLayout()
end

function CreateGameScreen:onClickAutoAccept(element)
	self.autoAccept = self.autoAcceptElement:getIsChecked()
end

function CreateGameScreen:onClickAllowOnlyFriends(element)
	self.allowOnlyFriends = self.allowOnlyFriendsElement:getIsChecked()
end

function CreateGameScreen:onClickAllowCrossPlay(element)
	self.allowCrossPlay = self.allowCrossPlayElement:getIsChecked()
end

function CreateGameScreen:onClickNumPlayer(state)
	self.capacity = state
end

function CreateGameScreen:onClickMultiplayerLanguage(state)
	self.mpLanguage = state - 1
	local v60_ = self.mpLanguage
	local v61_ = getNumOfLanguages() - 1
	self.mpLanguage = math.clamp(v60_, 0, v61_)
end

function CreateGameScreen:onClickBandwidth(state)
	self:fillCapacity()
end

function CreateGameScreen:onFocus(element)
	self.currentInputElement = element
	self:showChangeButton(true)
end

function CreateGameScreen:onLeave(element)
	self.currentInputElement = nil
	self:showChangeButton(false)
end

function CreateGameScreen:onEscPressed(element)
	FocusManager:setFocus(element)
	self.isTyping = false
	self.blockTime = self.time + 250
	FocusManager:unsetFocus(element)
	FocusManager:setFocus(element)
end

function CreateGameScreen:onEnterPressed(element)
	self.blockTime = self.time + 250
	self.isTyping = false
	FocusManager:unsetFocus(element)
	FocusManager:setFocus(element)
end

function CreateGameScreen:onEnter(element)
	self.isTyping = true
end

function CreateGameScreen:onClickActivate()
	if self.currentInputElement ~= nil then
		self.currentInputElement:onFocusActivate()
	end
end

function CreateGameScreen:onClickBack()
	if not self.isTyping and self.blockTime <= self.time then
		g_startMissionInfo.canStart = false
		CreateGameScreen:superClass().onClickBack(self)
	end
end

-- Local values: port, capacity, uploadRate, ok, _, up, measured
function CreateGameScreen:onClickOk()
	if self.isTyping or self.blockTime > self.time then
		if self.currentInputElement ~= nil then
			self.currentInputElement:setForcePressed(false)
		end
		return true
	end
	CreateGameScreen:superClass().onClickOk(self)
	if not self:verifyServerName() then
		return true
	end
	g_gameSettings:setValue(GameSettings.SETTING.MP_LANGUAGE, self.mpLanguage)
	local v74_ = self:getPort()
	local v75_ = self.capacityNumberTable[self.capacityElement.state]
	g_gameSettings:setTableValue(GameSettings.SETTING.CREATE_GAME, "password", self.passwordElement.text)
	g_gameSettings:setTableValue(GameSettings.SETTING.CREATE_GAME, "serverName", self.serverNameElement.text)
	g_gameSettings:setTableValue(GameSettings.SETTING.CREATE_GAME, "port", v74_)
	g_gameSettings:setTableValue(GameSettings.SETTING.CREATE_GAME, "bandwidth", self.bandwidthElement.state)
	g_gameSettings:setTableValue(GameSettings.SETTING.CREATE_GAME, "capacity", v75_)
	g_gameSettings:setTableValue(GameSettings.SETTING.CREATE_GAME, "allowOnlyFriends", self.allowOnlyFriends)
	g_gameSettings:setTableValue(GameSettings.SETTING.CREATE_GAME, "allowCrossPlay", self.allowCrossPlay)
	g_gameSettings:setTableValue(GameSettings.SETTING.CREATE_GAME, "autoAccept", self.autoAccept)
	g_gameSettings:save()
	self.settingsLoaded = false
	if GS_IS_CONSOLE_VERSION then
		self.missionDynamicInfo.serverPort = g_gameSettings:getValue(GameSettings.SETTING.DEFAULT_SERVER_PORT)
	else
		self.missionDynamicInfo.serverPort = v74_
	end
	self.missionDynamicInfo.isMultiplayer = true
	self.missionDynamicInfo.isClient = false
	self.missionDynamicInfo.password = self.passwordElement.text
	self.missionDynamicInfo.languageId = self.mpLanguage
	self.missionDynamicInfo.allowOnlyFriends = self.allowOnlyFriends
	self.missionDynamicInfo.allowCrossPlay = self.allowCrossPlay
	self.missionDynamicInfo.serverName = self.serverNameElement.text
	self.missionDynamicInfo.capacity = v75_
	self.missionDynamicInfo.autoAccept = self.autoAccept or g_dedicatedServer ~= nil
	g_maxUploadRate = self.connectionsInfos[self.bandwidthElement.state].uploadRate * 1024 / 1000
	if GS_IS_CONSOLE_VERSION and v75_ < 5 then
		g_maxUploadRate = g_maxUploadRate * 0.9
	end
	if GS_PLATFORM_PLAYSTATION then
		local v76_, _, v77_, v78_ = netGetBandwidthEstimate()
		if v76_ and v78_ then
			g_maxUploadRate = v77_ / 8 * 0.8 / 1000
			local v79_ = g_maxUploadRate
			g_maxUploadRate = math.clamp(v79_, 20, 200)
		end
	end
	g_mpLoadingScreen:setMissionInfo(self.missionInfo, self.missionDynamicInfo)
	g_mpLoadingScreen:showPortTesting()
	g_mpLoadingScreen:loadSavegameAndStart()
	return false
end

-- Local values: serverName, filteredServerName
function CreateGameScreen:verifyServerName()
	local v81_ = self.serverNameElement.text:trim()
	local v82_ = filterText(v81_, false, true)
	if v81_ ~= "" and v81_ == v82_ then
		return true
	end
	if v81_ == "" then
		self.serverNameElement:setText(self.defaultServerName)
	else
		self.serverNameElement:setText(v82_)
		printWarning("Warning: Gamename not allowed. Profanity text filter. Gamename adjusted")
	end
	return false
end

-- Local values: port
function CreateGameScreen:getPort()
	if GS_IS_CONSOLE_VERSION then
		return g_gameSettings:getValue(GameSettings.SETTING.DEFAULT_SERVER_PORT)
	end
	local v84_ = self.portElement.text
	local v85_ = tonumber(v84_)
	if v85_ == nil then
		v85_ = g_gameSettings:getValue(GameSettings.SETTING.DEFAULT_SERVER_PORT)
	end
	self.portElement:setText((tostring(v85_)))
	return v85_
end

function CreateGameScreen:onMasterServerConnectionFailed(reason)
	if self.isPortTesting then
		self.isPortTesting = false
		netShutdown(500, 0)
		ConnectionFailedDialog.showMasterServerConnectionFailedReason(reason, "CreateGameScreen")
	end
end

-- Local values: bandwidth, info, i, state
function CreateGameScreen:fillCapacity()
	local v89_ = self.bandwidthElement.state
	if g_dedicatedServer ~= nil then
		v89_ = self.dedicatedServerConnectionIndex
	end
	local v90_ = self.connectionsInfos[v89_]
	self.capacityTable = {}
	self.capacityNumberTable = {}
	for v91_ = 2, v90_.maxCapacity do
		local v92_ = self.capacityTable
		local v93_ = tostring(v91_)
		table.insert(v92_, v93_)
		local v94_ = self.capacityNumberTable
		table.insert(v94_, v91_)
	end
	local v95_ = self.capacityElement.state
	self.capacityElement:setTexts(self.capacityTable)
	local v96_ = self.capacityElement
	local v97_ = #self.capacityTable
	v96_:setState((math.min(v95_, v97_)))
end

function CreateGameScreen:setMissionInfo(missionInfo, missionDynamicInfo)
	self.missionInfo = missionInfo
	self.missionDynamicInfo = missionDynamicInfo
end

function CreateGameScreen:onIsUnicodeAllowed(unicode)
	local v102_
	if unicode >= 48 then
		v102_ = unicode <= 57
	else
		v102_ = false
	end
	return v102_
end

function CreateGameScreen:showChangeButton(show)
	if show ~= self.changeButton:getIsVisible() then
		self.changeButton:setVisible(show)
		self.buttonBox:invalidateLayout()
	end
end

-- Local values: dediData, capacityState, hasError
function CreateGameScreen:update(dt)
	CreateGameScreen:superClass().update(self, dt)
	if g_dedicatedServer == nil then
		self:showChangeButton(self.currentInputElement ~= nil)
		if GS_PLATFORM_PLAYSTATION then
			if getMultiplayerAvailability() == MultiplayerAvailability.NOT_AVAILABLE then
				g_masterServerConnection:disconnectFromMasterServer()
				g_gui:showGui("MainScreen")
			end
			if getNetworkError() then
				g_masterServerConnection:disconnectFromMasterServer()
				ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
			end
		end
	else
		local v107_ = g_dedicatedServer
		local v108_ = self.serverNameElement
		local v109_ = v107_.name
		v108_:setText((tostring(v109_)))
		local v110_ = self.passwordElement
		local v111_ = v107_.password
		v110_:setText((tostring(v111_)))
		local v112_ = self.portElement
		local v113_ = v107_.port
		v112_:setText((tostring(v113_)))
		self.allowCrossPlayElement:setIsChecked(v107_.crossplayAllowed)
		self.missionDynamicInfo.serverAddress = v107_.ip
		self.bandwidthElement:setState(self.dedicatedServerConnectionIndex)
		local v114_ = v107_.maxPlayer - g_serverMinCapacity + 1
		self.capacityElement:setState(v114_)
		self.allowCrossPlay = v107_.crossplayAllowed
		if self:onClickOk() then
			self:onClickOk()
		end
	end
end
