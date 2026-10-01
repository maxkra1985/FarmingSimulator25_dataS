ServerDetailScreen = {}
ServerDetailScreen.COLOR_RED = { 0.8069, 0.0097, 0.0097, 1 }
ServerDetailScreen.COLOR_WHITE = { 0.89627, 0.92158, 0.81485, 1 }
local ServerDetailScreen_mt = Class(ServerDetailScreen, ScreenElement)
function ServerDetailScreen.register()
	local serverDetailScreen = ServerDetailScreen.new()
	g_gui:loadGui("dataS/gui/ServerDetailScreen.xml", "ServerDetailScreen", serverDetailScreen)
	return serverDetailScreen
end
function ServerDetailScreen.new(target, custom_mt)
	local self = ScreenElement.new(target, custom_mt or ServerDetailScreen_mt)
	self:setReturnScreenClass(JoinGameScreen)
	self.sortedMods = {}
	return self
end
function ServerDetailScreen.createFromExistingGui(gui, guiName)
	local newGui = ServerDetailScreen.new()
	g_gui.guis[guiName]:delete()
	g_gui.guis[guiName].target:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, newGui)
	return newGui
end
function ServerDetailScreen:onCreate(element)
	self.modList:removeElement(self.listItemTemplate)
end
function ServerDetailScreen:onCreateList(element)
	self.modList = element
end
function ServerDetailScreen:setServerInfo(id, name, language, capacity, numPlayers, mapName, mapId, hasPassword, isLanServer, modTitles, modHashes, areAllModsAvailable, allowCrossPlay, platformId)
	self.serverId = id
	self.numPlayers = numPlayers
	self.capacity = capacity
	self.areAllModsAvailable = areAllModsAvailable
	self.hasPassword = hasPassword
	self.platformId = platformId
	self.serverName = name
	self.serverNameElement:setText(name)
	self.mapElement:setText(mapName)
	self.languageElement:setText(getLanguageName(language))
	self.platformElement:setPlatformId(platformId)
	local map = g_mapManager:getMapById(mapId)
	if map ~= nil then
		self.mapIconElement:setImageFilename(map.iconFilename)
	else
		self.mapIconElement:setImageFilename("dataS/menu/modHubPreview_default.png")
	end
	self.passwordElement:setLocaKey(hasPassword and "ui_yes" or "ui_no")
	self.crossPlayElement:setLocaKey(allowCrossPlay and "ui_yes" or "ui_no")
	local numPlayersText = string.format("%02d/%02d", numPlayers, capacity)
	self.numPlayersElement:setText(numPlayersText)
	if numPlayers == capacity then
		self.numPlayersElement:setTextColor(unpack(ServerDetailScreen.COLOR_RED))
	else
		self.numPlayersElement:setTextColor(unpack(ServerDetailScreen.COLOR_WHITE))
	end
	self:updateStartButton()
	for index, mod in pairs(modTitles) do
		local modTitle, modVersion, modAuthor, modName = ServerDetailScreen.unpackModInfo(modTitles[index])
		local modHash = modHashes[index]
		local title = nil
		local version = nil
		local hash = nil
		local icon = nil
		local iconIsWeb = nil
		local availability = nil
		local zipFilename = nil
		local author = nil
		local modHubId = nil
		if g_modManager:getIsModAvailable(modHash) then
			local modItem = g_modManager:getModByFileHash(modHash)
			title = modItem.title
			version = modItem.version
			icon = modItem.iconFilename
			zipFilename = ""
			availability = "ui_modAvailable"
		else
			local modId = getModIdByFilename(modName)
			if modId ~= 0 then
				if getModMetaAttributeString(modId, "hash") == modHash then
					local modHubInfo = g_modHubController:getModInfo(modId)
					if not getModMetaAttributeBool(modId, "isDLC") then
						modHubId = modId
					end
					title = modHubInfo:getName()
					version = modHubInfo:getVersionString()
					icon = modHubInfo:getIconFilename()
					iconIsWeb = true
					zipFilename = ""
					availability = "ui_modAvailableModHub"
				else
					title = modTitle
					author = modAuthor
					version = modVersion
					hash = modHash
					zipFilename = modName ~= nil and modName ~= "" and modName .. ".zip" or ""
					availability = "ui_modUnavailable"
				end
			end
		end
		local modInfo = { title = title, modHubId = modHubId, version = version, hash = hash, icon = icon, iconIsWeb = iconIsWeb, availability = availability, zipFilename = zipFilename, author = author }
		table.insert(self.sortedMods, modInfo)
	end
	local availabilities = { ["ui_modUnavailable"] = 1, ["ui_modAvailableModHub"] = 2, ["ui_modAvailable"] = 3 }
	local notDownloadedFirstSortFunc = function(a, b)
		if a.availability ~= b.availability then
			return availabilities[a.availability] < availabilities[b.availability]
		else
			return a.title < b.title
		end
	end
	table.sort(self.sortedMods, notDownloadedFirstSortFunc)
	local hasMods = 0 < #self.sortedMods
	self.noModsDLCsElement:setVisible(not hasMods)
	self.notAllModsOnSystemLabel:setVisible(hasMods and not areAllModsAvailable)
	self.modList:setDataSource(self)
	self.modList:reloadData()
	local _, _, numDownloadable = self:getDownloadableModsInfo()
	self.getModsButton:setDisabled(numDownloadable == 0)
	if Platform.hasNativeProfiles and getPlatformIdsAreCompatible(platformId, getPlatformId()) then
		self.blockOrShowButton:setText(g_i18n:getText("button_showProfile"))
		self.doShowUserProfile = true
		return
	end
	self.blockOrShowButton:setText(g_i18n:getText("button_block"))
	self.doShowUserProfile = false
end
function ServerDetailScreen:onOpen()
	ServerDetailScreen:superClass().onOpen(self)
	self.getModsButton:setVisible(Platform.hasModHub)
	self.modList:setSelectedIndex(1, nil, true)
end
function ServerDetailScreen:onClose()
	self.sortedMods = {}
	ServerDetailScreen:superClass().onClose(self)
end
function ServerDetailScreen:onClickOk()
	if self:getCanStartGame() then
		if not self.hasPassword then
			g_joinGameScreen:startGame("", self.serverId)
			return
		end
		local password = Utils.getNoNil(g_gameSettings:getTableValue(GameSettings.SETTING.JOIN_GAME, "password"), "")
		PasswordDialog.show(self.onPasswordEntered, self, nil, password)
	end
end
function ServerDetailScreen:update(dt)
	ServerDetailScreen:superClass().update(self, dt)
	self:updateStartButton()
end
function ServerDetailScreen:updateStartButton()
	local canStart = self:getCanStartGame()
	local isDisabled = not canStart
	if self.startElement:getIsDisabled() ~= isDisabled then
		self.startElement:setDisabled(isDisabled)
	end
end
function ServerDetailScreen:getCanStartGame()
	local canStart = self.areAllModsAvailable and self.numPlayers < self.capacity
	if self.serverId ~= nil then
		local uniqueUserId, platformUserId, platformId = masterServerGetServerUserInfo(self.serverId)
		local isBlocked = getIsUserBlocked(uniqueUserId, platformUserId, platformId)
		if isBlocked then
			canStart = false
		end
	end
	return canStart
end
function ServerDetailScreen:getDownloadableModsInfo()
	local downloadable = {}
	local totalSize = 0
	local totalCount = 0
	for _, modInfo in ipairs(self.sortedMods) do
		local modHash = modInfo.hash
		if g_modManager:getIsModAvailable(modHash) then
			continue
		end
		local modId = modInfo.modHubId
		if modId == nil then
			continue
		end
		downloadable[#downloadable + 1] = modId
		totalCount = totalCount + 1
		totalSize = totalSize + getModMetaAttributeInt(modId, "filesize")
	end
	return downloadable, totalSize, totalCount
end
function ServerDetailScreen:onClickDownload()
	if not PlatformPrivilegeUtil.checkModDownload(self.onClickDownload, self) then
		return
	end
	local downloadable, totalSize, totalCount = self:getDownloadableModsInfo()
	local freeSpaceKb = g_modHubController:getFreeModSpaceKb()
	totalSize = math.floor((totalSize + 1023) / 1024)
	if freeSpaceKb < totalSize then
		InfoDialog.show(string.format(g_i18n:getText("modHub_installNoFreeSpace"), totalSize, freeSpaceKb))
	else
		local callback = function(yes)
			if yes then
				local finishCallback = function(numFailed)
					g_masterServerConnection:disconnectFromMasterServer()
					g_connectionManager:shutdownAll()
					g_modHubScreen:openDownloads()
					if 0 < numFailed then
						InfoDialog.show(g_i18n:getText("modHub_installFailed"))
					end
				end
				g_modHubController:installOrUpdateMods(downloadable, finishCallback)
			end
		end
		local text = string.namedFormat(g_i18n:getText("ui_downloadingServerMods"), "numMods", totalCount, "filesize", string.format("%.02f", totalSize / 1024))
		YesNoDialog.show(callback, nil, text, g_i18n:getText("ui_downloadingServerModsTitle"))
	end
end
function ServerDetailScreen:onClickBlockOrShowInfo()
	if self.doShowUserProfile then
		local _, platformUserId, _ = masterServerGetServerUserInfo(self.serverId)
		showUserProfile(platformUserId)
	else
		local callback = function(yes)
			if yes then
				local uniqueUserId, platformUserId, platformId = masterServerGetServerUserInfo(self.serverId)
				setIsUserBlocked(uniqueUserId, platformUserId, platformId, true, self.serverName)
				g_messageCenter:publish(MessageType.BLOCK_LIST_CHANGED)
				self:onClickBack()
			end
		end
		YesNoDialog.show(callback, nil, g_i18n:getText("ui_doYouWantToBlockThisServer"), g_i18n:getText("ui_doYouWantToBlockThisServer_title"))
	end
end
function ServerDetailScreen:onPasswordEntered(password, clickOk)
	if clickOk then
		g_gameSettings:setTableValue(GameSettings.SETTING.JOIN_GAME, "password", password)
		g_gameSettings:save()
		g_joinGameScreen:startGame(password, self.serverId)
	end
end
function ServerDetailScreen.packModInfo(modTitle, version, author, modName)
	modTitle = string.gsub(modTitle, ";", " ")
	version = string.gsub(version, ";", " ")
	author = string.gsub(author, ";", " ")
	modName = string.gsub(modName, ";", " ")
	return modTitle .. ";" .. version .. ";" .. author .. ";" .. modName
end
function ServerDetailScreen.unpackModInfo(str)
	local parts = str:split(";")
	local modTitle = parts[1]
	local version = parts[2]
	local author = parts[3]
	local modName = parts[4]
	if modTitle == nil or modTitle == "" then
		modTitle = "Unknown Title"
	end
	if version == nil or version == "" then
		version = "0.0.0.1"
	end
	if author == nil then
		author = ""
	end
	if modName == nil then
		modName = ""
	end
	return modTitle, version, author, modName
end
function ServerDetailScreen:getNumberOfItemsInSection(list, section)
	return #self.sortedMods
end
function ServerDetailScreen:populateCellForItemInSection(list, section, index, cell)
	local modInfo = self.sortedMods[index]
	local hash = modInfo.hash
	local iconElement = cell:getAttribute("icon")
	iconElement:setVisible(modInfo.icon ~= nil)
	if modInfo.icon ~= nil then
		iconElement:setIsWebOverlay(modInfo.iconIsWeb == true)
		iconElement:setImageFilename(modInfo.icon)
	end
	cell:getAttribute("title"):setText(modInfo.title)
	cell:getAttribute("version"):setText(g_i18n:getText("ui_modVersion") .. " " .. modInfo.version)
	cell:getAttribute("zipFilename"):setText(modInfo.zipFilename)
	cell:getAttribute("missingIcon"):setVisible(modInfo.availability ~= "ui_modAvailable")
	cell:getAttribute("missingIconBg"):setVisible(modInfo.availability == "ui_modUnavailable")
	if modInfo.hash ~= nil then
		local hash1 = modInfo.hash:sub(1, hash:len() / 2)
		local hash2 = hash:sub(hash:len() / 2 + 1)
		cell:getAttribute("hash"):setText(hash1 .. "\n" .. hash2)
		cell:getAttribute("hash"):setVisible(true)
		cell:getAttribute("author"):setText(modInfo.author)
		cell:getAttribute("author"):setVisible(true)
	else
		cell:getAttribute("hash"):setVisible(false)
		cell:getAttribute("author"):setVisible(false)
	end
end
