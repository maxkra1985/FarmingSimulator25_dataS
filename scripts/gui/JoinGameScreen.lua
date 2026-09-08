-- Local values: JoinGameScreen_mt
JoinGameScreen = {}
JoinGameScreen.REFRESH_TIME = 25000
JoinGameScreen.FILTER_CHANGE_REFRESH_TIME = 500
local JoinGameScreen_mt = Class(JoinGameScreen, ScreenElement)
function JoinGameScreen.register()
	local v2_ = JoinGameScreen.new()
	g_gui:loadGui("dataS/gui/JoinGameScreen.xml", "JoinGameScreen", v2_)
	return v2_
end

-- Upvalues: JoinGameScreen_mt
-- Local values: self, i
function JoinGameScreen.new(target, custom_mt)
	-- upvalues: (copy) JoinGameScreen_mt
	local v5_ = ScreenElement.new(target, custom_mt or JoinGameScreen_mt)
	v5_.servers = {}
	v5_.serversBuffer = {}
	v5_.displayServers = {}
	v5_.requestedDetailsServerId = -1
	v5_.serverDetailsPending = false
	v5_.sortKey = "name"
	v5_.sortOrder = TableHeaderElement.SORTING_ASC
	v5_.totalNumServers = 0
	v5_.numServers = 0
	v5_.maxNumPlayersStates = {}
	v5_.maxNumPlayersNumbers = {}
	for v6_ = g_serverMinCapacity, g_joinServerMaxCapacity do
		local v7_ = v5_.maxNumPlayersStates
		local v8_ = tostring(v6_)
		table.insert(v7_, v8_)
		local v9_ = v5_.maxNumPlayersNumbers
		table.insert(v9_, v6_)
	end
	v5_.maxNumPlayersState = #v5_.maxNumPlayersNumbers
	v5_.selectedMaxNumPlayers = v5_.maxNumPlayersNumbers[v5_.maxNumPlayersState]
	v5_.includePasswordProtected = true
	v5_.includeFullGames = true
	v5_.onlyWithAllModsAvailable = false
	v5_.allowCrossPlay = false
	v5_.selectedMap = ""
	v5_.selectedLanguageId = 0
	v5_.serverName = ""
	v5_.lastUserName = ""
	v5_.returnScreenClass = MultiplayerScreen
	v5_.lastSelectedServerName = nil
	v5_.lastSelectedServerMapName = nil
	if g_isDevelopmentVersion then
		JoinGameScreen.REFRESH_TIME = 10000
	end
	return v5_
end

-- Local values: newGui
function JoinGameScreen.createFromExistingGui(gui, guiName)
	local v12_ = JoinGameScreen.new()
	g_gui.guis[guiName]:delete()
	g_gui.guis[guiName].target:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v12_)
	return v12_
end

-- Local values: mpAvailibility, _, i, map, title, text, reloadFilterSettings
function JoinGameScreen:onOpen()
	JoinGameScreen:superClass().onOpen(self)
	local v14_, _ = getCrossPlayAvailability(false)
	self.allowCrossPlayElement.parent:setVisible(v14_ == MultiplayerAvailability.AVAILABLE)
	self.settingsBox:invalidateLayout()
	self.mapTable = {}
	self.mapIds = {}
	local v15_ = self.mapTable
	local v16_ = g_i18n
	table.insert(v15_, v16_:getText("ui_anyMap"))
	local v17_ = self.mapIds
	table.insert(v17_, "")
	for v18_ = 1, g_mapManager:getNumOfMaps() do
		local v19_ = g_mapManager:getMapDataByIndex(v18_)
		local v20_ = v19_.title
		local v21_ = Utils.limitTextToWidth(v20_, 0.025, 0.245, false, "..")
		local v22_ = self.mapTable
		table.insert(v22_, v21_)
		local v23_ = self.mapIds
		local v24_ = v19_.id
		table.insert(v23_, v24_)
	end
	self.mapSelectionElement:setTexts(self.mapTable)
	if self.showingDeepLinkingPassword then
		self.showingPasswordDialog = nil
		self.showingDeepLinkingPassword = nil
		g_deepLinkingInfo = nil
	end
	if g_deepLinkingInfo == nil then
		MessageDialog.hide()
	else
		local v25_ = g_i18n:getText("ui_connectingPleaseWait")
		MessageDialog.show(v25_, nil, nil, DialogElement.TYPE_LOADING)
	end
	self.mainBox:setVisible(g_deepLinkingInfo == nil)
	local v26_ = not self.settingsLoaded
	if GS_IS_CONSOLE_VERSION and self.lastUserName ~= g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME) then
		self.lastUserName = g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME)
		v26_ = true
	end
	if v26_ then
		self:loadFilterSettings()
	end
	self.isRequestPending = false
	self.serverDetailsPending = false
	g_masterServerConnection:setCallbackTarget(self)
	self.startButtonElement:setDisabled(true)
	self.detailButtonElement:setDisabled(true)
	self.numServersText:setText("")
	self.refreshTimer = JoinGameScreen.REFRESH_TIME
	self.servers = {}
	self.isInitialLoad = true
	self.serverList:reloadData()
	if not g_masterServerConnection.isInit then
		g_connectionManager:startupWithWorkingPort(g_gameSettings:getValue(GameSettings.SETTING.DEFAULT_SERVER_PORT))
		g_masterServerConnection:connectToMasterServer(g_masterServerConnection.lastBackServerIndex)
	end
	self.loadingText:setVisible(self.serverList:getItemCount() == 0)
	self.noMatchingGamesText:setVisible(false)
	if g_deepLinkingInfo == nil then
		self:getServers()
	else
		masterServerRequestServerDetailsWithPlatformServerId(g_deepLinkingInfo.platformServerId, v14_ == MultiplayerAvailability.AVAILABLE)
	end
	g_messageCenter:subscribe(MessageType.INPUT_MODE_CHANGED, self.onInputModeChanged, self)
	self:showSortButton(false)
	g_messageCenter:subscribe(MessageType.BLOCK_LIST_CHANGED, self.getServers, self)
	Logging.info("numBlockedUsers: %d", getNumOfBlockedUsers())
end

function JoinGameScreen:onClose()
	JoinGameScreen:superClass().onClose(self)
	self.settingsLoaded = false
	self.servers = {}
	self.serversBuffer = {}
	self.displayServers = {}
	self.mapTable = {}
	self.mapIds = {}
	self.showingPasswordDialog = nil
	self.showingDeepLinkingPassword = nil
	g_messageCenter:unsubscribeAll(self)
end

function JoinGameScreen:triggerRebuildOnFilterChange()
	self:updateDisplayedServers()
end

-- Local values: k, t
function JoinGameScreen:onServerInfoDetails(id, name, language, capacity, numPlayers, mapName, mapId, hasPassword, isLanServer, modTitles, modHashes, allowCrossPlay, platformId, password)
	if g_isDevelopmentVersion then
		log(string.format("JoinGameScreen Id: %d\nname: %s\nlanguage: %d\ncapacity: %d\nnumPlayers: %d\nmapName: %s\nmapId: %s\nhasPassword: %s\nisLanServer: %s\nmodTitles: %s\nmodHashes: %s\nallowCrossPlay: %s\nplatformId: %s\n", id, name, language, capacity, numPlayers, mapName, mapId, tostring(hasPassword), tostring(isLanServer), modTitles, modHashes, allowCrossPlay, getDeviceTypeFromPlatformId(platformId)))
		for v44_, v45_ in ipairs(modTitles) do
			log("    ", v45_, "> Hash:", modHashes[v44_])
		end
	end
	if g_deepLinkingInfo == nil then
		if id == self.requestedDetailsServerId then
			g_serverDetailScreen:setServerInfo(id, name, language, capacity, numPlayers, mapName, mapId, hasPassword, isLanServer, modTitles, modHashes, g_modManager:getAreAllModsAvailable(modHashes), allowCrossPlay, platformId)
			g_gui:showGui("ServerDetailScreen")
		end
	elseif g_deepLinkingInfo.platformServerId ~= "" then
		if hasPassword then
			self.showingPasswordDialog = true
			self.showingDeepLinkingPassword = true
			PasswordDialog.show(self.onPasswordEntered, self, {
				["serverId"] = id,
				["language"] = language
			}, "")
		else
			self:startGame(password, id, language)
		end
	end
	self.serverDetailsPending = false
end

-- Local values: oldDeepLinkingInfo, _, didDialogShow
function JoinGameScreen:onServerInfoDetailsFailed(reason)
	if g_deepLinkingInfo == nil then
		self.requestedDetailsServerId = -1
	else
		local v48_ = g_deepLinkingInfo
		g_deepLinkingInfo = nil
		if reason == MasterServerServerDetailsFailedReason.NO_CROSS_PLAY then
			local _, v49_ = getCrossPlayAvailability(true)
			if v49_ then
				self.serverDetailsPending = false
				self.crossPlayDialogPendingInfo = v48_
				return
			end
			ConnectionFailedDialog.show(g_i18n:getText("ui_failedToConnectToGameCrossPlay"), g_connectionFailedDialog.onOkCallback, g_connectionFailedDialog, { "JoinGameScreen" })
		else
			ConnectionFailedDialog.show(g_i18n:getText("ui_failedToConnectToGame"), g_connectionFailedDialog.onOkCallback, g_connectionFailedDialog, { "JoinGameScreen" })
		end
	end
	self.serverDetailsPending = false
	self:getServers()
end

function JoinGameScreen:onMasterServerConnectionReady()
	self:getServers()
end

function JoinGameScreen:onMasterServerConnectionFailed(reason)
	g_masterServerConnection:disconnectFromMasterServer()
	g_connectionManager:shutdownAll()
	ConnectionFailedDialog.showMasterServerConnectionFailedReason(reason, "MultiplayerScreen")
end

function JoinGameScreen:onServerInfoStart(numServers, totalNumServers)
	self.totalNumServers = totalNumServers
	self.numServers = numServers
	self.serversBufferNextIndex = 1
end

-- Local values: server
function JoinGameScreen:onServerInfo(id, name, language, capacity, numPlayers, mapName, mapId, hasPassword, allModsAvailable, isLanServer, isFriendServer, allowCrossPlay, platformId)
	local v69_ = self.serversBuffer[self.serversBufferNextIndex] or {}
	v69_.id = id
	v69_.name = name
	v69_.hasPassword = hasPassword
	v69_.language = language
	v69_.capacity = capacity
	v69_.numPlayers = numPlayers
	v69_.mapName = mapName
	v69_.mapId = mapId
	v69_.allModsAvailable = allModsAvailable
	v69_.isLanServer = isLanServer
	v69_.isFriendServer = isFriendServer
	v69_.allowCrossPlay = allowCrossPlay
	v69_.platformId = platformId
	v69_.fullness = numPlayers / capacity
	self.serversBuffer[self.serversBufferNextIndex] = v69_
	self.serversBufferNextIndex = self.serversBufferNextIndex + 1
end

-- Local values: i
function JoinGameScreen:onServerInfoEnd()
	for v71_ = #self.serversBuffer, self.serversBufferNextIndex, -1 do
		self.serversBuffer[v71_] = nil
	end
	self.servers = self.serversBuffer
	self.isRequestPending = false
	self:updateDisplayedServers()
end

-- Local values: _, mod
function JoinGameScreen:getServers()
	if self.isRequestPending or (self.serverDetailsPending or self.showingPasswordDialog) then
		Logging.devInfo("getServers cancel; isRequestPending=%s serverDetailsPending=%s showingPasswordDialog=%s", self.isRequestPending, self.serverDetailsPending, self.showingPasswordDialog)
	else
		masterServerAddAvailableModStart()
		for _, v73_ in ipairs(g_modManager:getMultiplayerMods()) do
			masterServerAddAvailableMod(v73_.fileHash)
		end
		masterServerAddAvailableModEnd()
		self.isRequestPending = true
		masterServerRequestFilteredServers(self.selectedLanguageId, self.allowCrossPlay)
	end
end

function JoinGameScreen:buildSortFunc()
	return function(p75_, p76_)
		-- upvalues: (copy) self
		if p75_.isLanServer == p76_.isLanServer then
			if p75_.isFriendServer == p76_.isFriendServer then
				if self.sortOrder == TableHeaderElement.SORTING_ASC then
					return p75_[self.sortKey] < p76_[self.sortKey]
				else
					return p75_[self.sortKey] > p76_[self.sortKey]
				end
			else
				local v77_ = not p76_.isFriendServer
				if v77_ then
					v77_ = p75_.isFriendServer
				end
				return v77_
			end
		else
			local v78_ = not p76_.isLanServer
			if v78_ then
				v78_ = p75_.isLanServer
			end
			return v78_
		end
	end
end

-- Local values: lastServerName, lastServerMapName, _, server, index, i, server, k, server
function JoinGameScreen:updateDisplayedServers()
	local v80_ = self.lastSelectedServerName
	local v81_ = self.lastSelectedServerMapName
	self.displayServers = {}
	for _, v82_ in ipairs(self.servers) do
		if self:filterServer(v82_) then
			local v83_ = self.displayServers
			table.insert(v83_, v82_)
		end
	end
	table.sort(self.displayServers, self:buildSortFunc())
	self.numServersText:setText(string.format("%d / %d", #self.displayServers, self.totalNumServers))
	self.numServersBox:invalidateLayout()
	self.numServersBoxBg:setSize(self.numServersBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
	self.serverList:reloadData()
	self.loadingText:setVisible(false)
	self.noMatchingGamesText:setVisible(self.serverList:getItemCount() == 0)
	if self.isInitialLoad then
		if #self.displayServers > 0 then
			FocusManager:setFocus(self.serverList)
		else
			FocusManager:setFocus(self.mapSelectionElement)
		end
	end
	self.isInitialLoad = false
	self:updateButtons()
	if v80_ ~= nil then
		local v84_ = 1
		for v85_, v86_ in ipairs(self.displayServers) do
			if v86_.name == v80_ and v86_.mapName == v81_ then
				v84_ = v85_
				break
			end
		end
		self.serverList:setSelectedIndex(v84_)
	end
	if g_autoDevMP ~= nil then
		for v87_, v88_ in ipairs(self.displayServers) do
			if v88_.name == g_autoDevMP.serverName then
				self.serverList:setSelectedIndex(v87_)
				self:onClickOk(true)
				return
			end
		end
		self.refreshTimer = 2500
	end
end

-- Local values: pwOk, capacityOk, mapOk, modsOk, languageOk, capOk, serverNameOk
function JoinGameScreen:filterServer(server)
	local v91_ = self.includePasswordProtected or not server.hasPassword
	local v92_ = self.includeFullGames or server.numPlayers < server.capacity
	local v93_ = self.selectedMap == "" and true or server.mapId == self.selectedMap
	local v94_ = not self.onlyWithAllModsAvailable or server.allModsAvailable
	local v95_ = server.language == self.selectedLanguageId
	local v96_ = server.capacity <= self.selectedMaxNumPlayers
	local v97_ = self.serverName and server.name
	if v97_ then
		v97_ = self.serverName == "" and true or string.find(utf8ToLower(server.name), utf8ToLower(self.serverName), 1, true) ~= nil
	end
	if v91_ then
		if v92_ then
			if v93_ then
				if v94_ then
					if v95_ then
						if not v96_ then
							v97_ = v96_
						end
					else
						v97_ = v95_
					end
				else
					v97_ = v94_
				end
			else
				v97_ = v93_
			end
		else
			v97_ = v92_
		end
	else
		v97_ = v91_
	end
	return v97_
end

-- Local values: sortingOrder
function JoinGameScreen:onClickHeader(element)
	local v100_ = element:toggleSorting()
	if v100_ == TableHeaderElement.SORTING_OFF then
		self.sortKey = "name"
		self.sortOrder = TableHeaderElement.SORTING_ASC
	else
		self.sortKey = element.columnName
		self.sortOrder = v100_
	end
	self:updateDisplayedServers()
end

function JoinGameScreen:onFocusHeader(headerElement)
	self.focusedHeaderElement = headerElement
	self:showSortButton(true)
end

function JoinGameScreen:onLeaveHeader(self)
	self.focusedHeaderElement = nil
	self:showSortButton(false)
end

-- Local values: languageTable, numL, i
function JoinGameScreen:onCreateLanguage(element)
	local v105_ = {}
	for v106_ = 1, getNumOfLanguages() do
		local v107_ = getLanguageName
		local v108_ = v106_ - 1
		table.insert(v105_, v107_(v108_))
	end
	element:setTexts(v105_)
end

function JoinGameScreen:onCreateMaxNumPlayers(element)
	element:setTexts(self.maxNumPlayersStates)
end

function JoinGameScreen:onFocusGameName(element)
	self.selectedInputElement = element
	self.startButtonElement:setText(g_i18n:getText("button_change"))
	self.startButtonElement:setDisabled(false)
end

function JoinGameScreen:onLeaveGameName(element)
	self.selectedInputElement = nil
	self.startButtonElement:setText(g_i18n:getText("button_start"))
	self:updateButtons()
end

function JoinGameScreen:onClickLanguage(state)
	self.selectedLanguageId = state - 1
	self.refreshTimer = JoinGameScreen.FILTER_CHANGE_REFRESH_TIME
end

function JoinGameScreen:onClickMaxNumPlayers(state)
	self.selectedMaxNumPlayers = self.maxNumPlayersNumbers[state]
	self:triggerRebuildOnFilterChange()
end

function JoinGameScreen:onClickMap(state)
	self.selectedMap = self.mapIds[self.mapSelectionElement.state]
	self:triggerRebuildOnFilterChange()
end

function JoinGameScreen:onClickPassword(element)
	self.includePasswordProtected = self.passwordElement:getIsChecked()
	self:triggerRebuildOnFilterChange()
end

function JoinGameScreen:onClickCapacity(element)
	self.includeFullGames = self.capacityElement:getIsChecked()
	self:triggerRebuildOnFilterChange()
end

function JoinGameScreen:onClickModsDlcs(element)
	self.onlyWithAllModsAvailable = self.modDlcElement:getIsChecked()
	self:triggerRebuildOnFilterChange()
end

function JoinGameScreen:onClickAllowCrossPlay(element)
	self.allowCrossPlay = self.allowCrossPlayElement:getIsChecked()
	self.refreshTimer = JoinGameScreen.FILTER_CHANGE_REFRESH_TIME
end

function JoinGameScreen:onServerNameChanged(element, text)
	self.serverName = text
	self:triggerRebuildOnFilterChange()
end

-- Local values: server, password
function JoinGameScreen:onClickOk(isMouseClick)
	if self.selectedInputElement == nil then
		self:saveFilterSettings()
		JoinGameScreen:superClass().onClickOk(self)
		if self.serverList.selectedIndex > 0 then
			if self:isSelectedServerValid() then
				local v127_ = self:getSelectedServer()
				if v127_ ~= nil and v127_.allModsAvailable then
					if v127_.hasPassword then
						local v128_ = Utils.getNoNil(g_gameSettings:getTableValue(GameSettings.SETTING.JOIN_GAME, "password"), "")
						self.showingPasswordDialog = true
						PasswordDialog.show(self.onPasswordEntered, self, {
							["serverId"] = v127_.id
						}, v128_)
					else
						self:startGame("", v127_.id, v127_.language)
					end
				end
			end
			if isMouseClick then
				self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
			end
		end
	else
		self.serverNameElement:onFocusActivate()
	end
end

-- Local values: server
function JoinGameScreen:onClickActivate()
	JoinGameScreen:superClass().onClickActivate(self)
	self:saveFilterSettings()
	local v130_ = self:getSelectedServer()
	if v130_ ~= nil and not self.serverDetailsPending then
		self.requestedDetailsServerId = v130_.id
		self.serverDetailsPending = true
		masterServerRequestServerDetails(v130_.id)
	end
end

function JoinGameScreen:onClickBack()
	g_startMissionInfo.canStart = false
	g_masterServerConnection:disconnectFromMasterServer()
	g_connectionManager:shutdownAll()
	self:saveFilterSettings()
	return JoinGameScreen:superClass().onClickBack(self)
end

function JoinGameScreen:onDoubleClick()
	self:onClickOk(true)
end

-- Local values: eventUnused
function JoinGameScreen:onClickSort()
	local v134_ = JoinGameScreen:superClass().onClickMenuExtra1(self)
	if v134_ then
		if self.focusedHeaderElement == nil then
			v134_ = false
		else
			self:onClickHeader(self.focusedHeaderElement)
			v134_ = false
		end
	end
	return v134_
end

function JoinGameScreen:onClickOpenBlocklist()
	UnBanDialog.show(nil, nil, true)
end

function JoinGameScreen:onInputModeChanged(inputMode)
	self:showSortButton(self.focusedHeaderElement ~= nil)
end

function JoinGameScreen:getNumberOfItemsInSection(list, section)
	return #self.displayServers
end

-- Local values: server, numPlayers, isFull, languageCode
function JoinGameScreen:populateCellForItemInSection(list, section, index, cell)
	local v140_ = self.displayServers[index]
	cell:getAttribute("iconModsMissing"):setVisible(not v140_.allModsAvailable)
	cell:getAttribute("iconServerPassword"):setVisible(v140_.hasPassword)
	local v141_ = cell:getAttribute("iconServerInternet")
	local v142_ = not v140_.isFriendServer
	if v142_ then
		v142_ = not v140_.isLanServer
	end
	v141_:setVisible(v142_)
	local v143_ = cell:getAttribute("iconServerLan")
	local v144_ = not v140_.isFriendServer
	if v144_ then
		v144_ = v140_.isLanServer
	end
	v143_:setVisible(v144_)
	cell:getAttribute("iconFriends"):setVisible(v140_.isFriendServer)
	cell:getAttribute("iconPlatform"):setPlatformId(v140_.platformId)
	cell:getAttribute("gameName"):setText(v140_.name)
	cell:getAttribute("mapName"):setText(v140_.mapName)
	local v145_ = string.format("%02d/%02d", v140_.numPlayers, v140_.capacity)
	cell:getAttribute("players"):setText(v145_)
	local v146_ = v140_.numPlayers == v140_.capacity
	cell:getAttribute("iconSlotsFull"):setVisible(v146_)
	cell:getAttribute("iconSlotsAvailable"):setVisible(not v146_)
	local v147_ = string.upper(getLanguageCode(v140_.language) or "")
	cell:getAttribute("language"):setText(v147_)
end

-- Local values: server
function JoinGameScreen:onListSelectionChanged(list, section, index)
	local v150_ = self.displayServers[index]
	if v150_ ~= nil then
		self.lastSelectedServerName = v150_.name
		self.lastSelectedServerMapName = v150_.mapName
	end
	self:updateButtons()
end

-- Local values: mpAvailibility, _, selectedMapState, mapId, i, m, capacity, i, c, selectedLanguageId, languageIndex
function JoinGameScreen:loadFilterSettings()
	self.settingsLoaded = true
	local v152_, _ = getCrossPlayAvailability(false)
	local v153_ = 1
	self.includePasswordProtected = Utils.getNoNil(g_gameSettings:getTableValue(GameSettings.SETTING.JOIN_GAME, "includePasswordProtected"), true)
	self.includeFullGames = Utils.getNoNil(g_gameSettings:getTableValue(GameSettings.SETTING.JOIN_GAME, "includeFullGames"), true)
	self.onlyWithAllModsAvailable = Utils.getNoNil(g_gameSettings:getTableValue(GameSettings.SETTING.JOIN_GAME, "onlyWithAllModsAvailable"), false)
	local v154_ = Utils.getNoNil(g_gameSettings:getTableValue(GameSettings.SETTING.JOIN_GAME, "allowCrossPlay"), true)
	if v154_ then
		v154_ = v152_ == MultiplayerAvailability.AVAILABLE
	end
	self.allowCrossPlay = v154_
	self.serverName = Utils.getNoNil(g_gameSettings:getTableValue(GameSettings.SETTING.JOIN_GAME, "serverName"), "")
	if g_autoDevMP ~= nil then
		self.serverName = g_autoDevMP.serverName
	end
	self.maxNumPlayersState = #self.maxNumPlayersNumbers
	self.selectedLanguageId = g_gameSettings:getValue(GameSettings.SETTING.MP_LANGUAGE)
	local v155_ = self.selectedLanguageId
	local v156_ = math.max(v155_, 0)
	local v157_ = getNumOfLanguages() - 1
	self.selectedLanguageId = math.min(v156_, v157_)
	local v158_ = g_gameSettings:getTableValue(GameSettings.SETTING.JOIN_GAME, "mapId")
	if v158_ ~= nil then
		for v159_, v160_ in ipairs(self.mapIds) do
			if v160_ == v158_ then
				v153_ = v159_
				break
			end
		end
	end
	local v161_ = g_gameSettings:getTableValue(GameSettings.SETTING.JOIN_GAME, "capacity")
	if v161_ ~= nil then
		for v162_, v163_ in ipairs(self.maxNumPlayersNumbers) do
			if v163_ == v161_ then
				self.maxNumPlayersState = v162_
				break
			end
		end
	end
	local v164_ = g_gameSettings:getTableValue(GameSettings.SETTING.JOIN_GAME, "language")
	if v164_ ~= nil and (v164_ >= 0 and v164_ < getNumOfLanguages()) then
		self.selectedLanguageId = v164_
	end
	self.mapSelectionElement:setState(v153_)
	self.selectedMap = self.mapIds[self.mapSelectionElement.state]
	self.passwordElement:setIsChecked(self.includePasswordProtected, true)
	self.capacityElement:setIsChecked(self.includeFullGames, true)
	self.modDlcElement:setIsChecked(self.onlyWithAllModsAvailable, true)
	self.allowCrossPlayElement:setIsChecked(self.allowCrossPlay, true)
	self.serverNameElement:setText(self.serverName)
	self.maxNumPlayersElement:setState(self.maxNumPlayersState)
	self.selectedMaxNumPlayers = self.maxNumPlayersNumbers[self.maxNumPlayersElement.state]
	local v165_ = self.selectedLanguageId + 1
	self.languageElement:setState(v165_)
end

function JoinGameScreen:saveFilterSettings()
	g_gameSettings:setTableValue(GameSettings.SETTING.JOIN_GAME, "includePasswordProtected", self.passwordElement:getIsChecked())
	g_gameSettings:setTableValue(GameSettings.SETTING.JOIN_GAME, "includeFullGames", self.capacityElement:getIsChecked())
	g_gameSettings:setTableValue(GameSettings.SETTING.JOIN_GAME, "onlyWithAllModsAvailable", self.modDlcElement:getIsChecked())
	g_gameSettings:setTableValue(GameSettings.SETTING.JOIN_GAME, "allowCrossPlay", self.allowCrossPlayElement:getIsChecked())
	g_gameSettings:setTableValue(GameSettings.SETTING.JOIN_GAME, "serverName", self.serverName)
	g_gameSettings:setTableValue(GameSettings.SETTING.JOIN_GAME, "language", self.selectedLanguageId)
	g_gameSettings:setTableValue(GameSettings.SETTING.JOIN_GAME, "capacity", self.maxNumPlayersNumbers[self.maxNumPlayersElement.state])
	g_gameSettings:setTableValue(GameSettings.SETTING.JOIN_GAME, "mapId", self.mapIds[self.mapSelectionElement.state])
	g_gameSettings:save()
end

function JoinGameScreen:showSortButton(show)
	self.sortButton:setVisible(show)
	self.buttonBox:invalidateLayout()
end

function JoinGameScreen:getSelectedServer()
	return self.displayServers[self.serverList.selectedIndex]
end

-- Local values: isValid
function JoinGameScreen:updateButtons()
	if self.startButtonElement ~= nil then
		local v171_ = self:isSelectedServerValid()
		self.startButtonElement:setDisabled(not v171_)
	end
	self.detailButtonElement:setDisabled(self:getSelectedServer() == nil)
end

-- Local values: selectedServer
function JoinGameScreen:isSelectedServerValid()
	local v173_ = self:getSelectedServer()
	local v174_ = v173_ and v173_.allModsAvailable
	if v174_ then
		v174_ = v173_.numPlayers < v173_.capacity
	end
	return v174_
end

-- Local values: serverId, serverIdRequested, _, server, text
function JoinGameScreen:onPasswordEntered(password, clickOk, args)
	self.showingPasswordDialog = nil
	self.showingDeepLinkingPassword = nil
	if clickOk then
		if g_deepLinkingInfo == nil then
			g_gameSettings:setTableValue(GameSettings.SETTING.JOIN_GAME, "password", password)
			g_gameSettings:save()
		end
		local v179_ = args.serverId
		local v180_ = nil
		for _, v181_ in ipairs(self.displayServers) do
			if v181_.id == v179_ then
				v180_ = v179_
				break
			end
		end
		if v180_ == nil then
			local v182_ = string.format("%s\n%s", g_i18n:getText("ui_connectionFailed"), g_i18n:getText("ui_serverWasShutdown"))
			InfoDialog.show(v182_, nil, nil, DialogElement.TYPE_WARNING)
			return
		end
		self:startGame(password, v180_, args.language)
	end
end

-- Local values: missionInfo, missionDynamicInfo
function JoinGameScreen:startGame(password, serverId, languageId)
	g_maxUploadRate = 30.72
	local v187_ = FSCareerMissionInfo.new("", nil, 0)
	v187_:loadDefaults()
	g_mpLoadingScreen:setMissionInfo(v187_, {
		["serverId"] = serverId,
		["isMultiplayer"] = true,
		["isClient"] = true,
		["password"] = password,
		["languageId"] = languageId,
		["allowOnlyFriends"] = false
	})
	g_gui:changeScreen(nil, MPLoadingScreen, self.returnScreenClass or MultiplayerScreen)
	g_mpLoadingScreen:startClient()
end

-- Local values: mpAvailibility, _
function JoinGameScreen:update(dt)
	JoinGameScreen:superClass().update(self, dt)
	Platform.verifyMultiplayerAvailabilityInMenu()
	if self.crossPlayDialogPendingInfo ~= nil then
		local v190_, _ = getCrossPlayAvailability(true)
		if v190_ == MultiplayerAvailability.AVAILABILITY_UNKNOWN then
			return
		end
		if v190_ == MultiplayerAvailability.AVAILABLE then
			g_deepLinkingInfo = self.crossPlayDialogPendingInfo
			masterServerRequestServerDetailsWithPlatformServerId(g_deepLinkingInfo.platformServerId, true)
		else
			MessageDialog.hide()
			self.mainBox:setVisible(g_deepLinkingInfo == nil)
			FocusManager:setFocus(self.mapSelectionElement)
			self:getServers()
		end
		self.crossPlayDialogPendingInfo = nil
	end
	if not (self.requestPending or (self.serverDetailsPending or self.showingPasswordDialog)) then
		self.refreshTimer = self.refreshTimer - dt
		if self.refreshTimer <= 0 then
			self.refreshTimer = JoinGameScreen.REFRESH_TIME
			self:getServers()
		end
	end
end
