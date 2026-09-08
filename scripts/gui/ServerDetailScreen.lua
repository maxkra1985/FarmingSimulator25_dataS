-- Local values: ServerDetailScreen_mt
ServerDetailScreen = {}
ServerDetailScreen.COLOR_RED = {
	0.8069,
	0.0097,
	0.0097,
	1
}
ServerDetailScreen.COLOR_WHITE = {
	0.89627,
	0.92158,
	0.81485,
	1
}
local ServerDetailScreen_mt = Class(ServerDetailScreen, ScreenElement)
function ServerDetailScreen.register()
	local v2_ = ServerDetailScreen.new()
	g_gui:loadGui("dataS/gui/ServerDetailScreen.xml", "ServerDetailScreen", v2_)
	return v2_
end

-- Upvalues: ServerDetailScreen_mt
-- Local values: self
function ServerDetailScreen.new(target, custom_mt)
	-- upvalues: (copy) ServerDetailScreen_mt
	local v5_ = ScreenElement.new(target, custom_mt or ServerDetailScreen_mt)
	v5_:setReturnScreenClass(JoinGameScreen)
	v5_.sortedMods = {}
	return v5_
end

-- Local values: newGui
function ServerDetailScreen.createFromExistingGui(gui, guiName)
	local v8_ = ServerDetailScreen.new()
	g_gui.guis[guiName]:delete()
	g_gui.guis[guiName].target:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v8_)
	return v8_
end

function ServerDetailScreen:onCreate(element)
	self.modList:removeElement(self.listItemTemplate)
end

function ServerDetailScreen:onCreateList(element)
	self.modList = element
end

-- Local values: map, numPlayersText, index, mod, modTitle, modVersion, modAuthor, modName, modHash, title, version, hash, icon, iconIsWeb, availability, zipFilename, author, modHubId, modItem, modId, modHubInfo, modInfo, availabilities, notDownloadedFirstSortFunc, hasMods, _, _, numDownloadable
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
	local v26_ = g_mapManager:getMapById(mapId)
	if v26_ == nil then
		self.mapIconElement:setImageFilename("dataS/menu/modHubPreview_default.png")
	else
		self.mapIconElement:setImageFilename(v26_.iconFilename)
	end
	self.passwordElement:setLocaKey(hasPassword and "ui_yes" or "ui_no")
	self.crossPlayElement:setLocaKey(allowCrossPlay and "ui_yes" or "ui_no")
	local v27_ = string.format("%02d/%02d", numPlayers, capacity)
	self.numPlayersElement:setText(v27_)
	if numPlayers == capacity then
		local v28_ = self.numPlayersElement
		local v29_ = ServerDetailScreen.COLOR_RED
		v28_:setTextColor(unpack(v29_))
	else
		local v30_ = self.numPlayersElement
		local v31_ = ServerDetailScreen.COLOR_WHITE
		v30_:setTextColor(unpack(v31_))
	end
	self:updateStartButton()
	for v32_, _ in pairs(modTitles) do
		local v33_, v34_, v35_, v36_ = ServerDetailScreen.unpackModInfo(modTitles[v32_])
		local v37_ = modHashes[v32_]
		local v38_ = nil
		local v39_ = nil
		local v40_ = nil
		local v41_ = nil
		local v42_ = nil
		local v43_, v44_
		if g_modManager:getIsModAvailable(v37_) then
			local v45_ = g_modManager:getModByFileHash(v37_)
			v33_ = v45_.title
			v34_ = v45_.version
			v39_ = v45_.iconFilename
			v43_ = "ui_modAvailable"
			v44_ = ""
		else
			local v46_ = getModIdByFilename(v36_)
			if v46_ == 0 or getModMetaAttributeString(v46_, "hash") ~= v37_ then
				v44_ = v36_ == nil and "" or (v36_ ~= "" and v36_ .. ".zip" or "")
				v38_ = v37_
				v41_ = v35_
				v43_ = "ui_modUnavailable"
			else
				local v47_ = g_modHubController:getModInfo(v46_)
				if getModMetaAttributeBool(v46_, "isDLC") then
					v46_ = v42_
				end
				v33_ = v47_:getName()
				v34_ = v47_:getVersionString()
				v39_ = v47_:getIconFilename()
				v42_ = v46_
				v40_ = true
				v43_ = "ui_modAvailableModHub"
				v44_ = ""
			end
		end
		local v48_ = self.sortedMods
		table.insert(v48_, {
			["title"] = v33_,
			["modHubId"] = v42_,
			["version"] = v34_,
			["hash"] = v38_,
			["icon"] = v39_,
			["iconIsWeb"] = v40_,
			["availability"] = v43_,
			["zipFilename"] = v44_,
			["author"] = v41_
		})
	end
	local v_u_49_ = {
		["ui_modUnavailable"] = 1,
		["ui_modAvailableModHub"] = 2,
		["ui_modAvailable"] = 3
	}
	table.sort(self.sortedMods, function(p50_, p51_)
		-- upvalues: (copy) v_u_49_
		if p50_.availability == p51_.availability then
			return p50_.title < p51_.title
		else
			return v_u_49_[p50_.availability] < v_u_49_[p51_.availability]
		end
	end)
	local v52_ = #self.sortedMods > 0
	self.noModsDLCsElement:setVisible(not v52_)
	local v53_ = self.notAllModsOnSystemLabel
	if v52_ then
		v52_ = not areAllModsAvailable
	end
	v53_:setVisible(v52_)
	self.modList:setDataSource(self)
	self.modList:reloadData()
	local _, _, v54_ = self:getDownloadableModsInfo()
	self.getModsButton:setDisabled(v54_ == 0)
	if Platform.hasNativeProfiles and getPlatformIdsAreCompatible(platformId, getPlatformId()) then
		self.blockOrShowButton:setText(g_i18n:getText("button_showProfile"))
		self.doShowUserProfile = true
	else
		self.blockOrShowButton:setText(g_i18n:getText("button_block"))
		self.doShowUserProfile = false
	end
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

-- Local values: password
function ServerDetailScreen:onClickOk()
	if self:getCanStartGame() then
		if not self.hasPassword then
			g_joinGameScreen:startGame("", self.serverId)
			return
		end
		local v58_ = Utils.getNoNil(g_gameSettings:getTableValue(GameSettings.SETTING.JOIN_GAME, "password"), "")
		PasswordDialog.show(self.onPasswordEntered, self, nil, v58_)
	end
end

function ServerDetailScreen:update(dt)
	ServerDetailScreen:superClass().update(self, dt)
	self:updateStartButton()
end

-- Local values: canStart, isDisabled
function ServerDetailScreen:updateStartButton()
	local v62_ = not self:getCanStartGame()
	if self.startElement:getIsDisabled() ~= v62_ then
		self.startElement:setDisabled(v62_)
	end
end

-- Local values: canStart, uniqueUserId, platformUserId, platformId, isBlocked
function ServerDetailScreen:getCanStartGame()
	local v64_ = self.areAllModsAvailable
	if v64_ then
		v64_ = self.numPlayers < self.capacity
	end
	if self.serverId ~= nil then
		local v65_, v66_, v67_ = masterServerGetServerUserInfo(self.serverId)
		if getIsUserBlocked(v65_, v66_, v67_) then
			v64_ = false
		end
	end
	return v64_
end

-- Local values: downloadable, totalSize, totalCount, _, modInfo, modHash, modId
function ServerDetailScreen:getDownloadableModsInfo()
	local v69_ = {}
	local v70_ = 0
	local v71_ = 0
	for _, v72_ in ipairs(self.sortedMods) do
		local v73_ = v72_.hash
		if not g_modManager:getIsModAvailable(v73_) then
			local v74_ = v72_.modHubId
			if v74_ ~= nil then
				v69_[#v69_ + 1] = v74_
				v70_ = v70_ + 1
				v71_ = v71_ + getModMetaAttributeInt(v74_, "filesize")
			end
		end
	end
	return v69_, v71_, v70_
end

-- Local values: downloadable, totalSize, totalCount, freeSpaceKb, callback, text
function ServerDetailScreen:onClickDownload()
	if PlatformPrivilegeUtil.checkModDownload(self.onClickDownload, self) then
		local v_u_76_, v77_, v78_ = self:getDownloadableModsInfo()
		local v79_ = g_modHubController:getFreeModSpaceKb()
		local v80_ = (v77_ + 1023) / 1024
		local v81_ = math.floor(v80_)
		if v79_ < v81_ then
			InfoDialog.show(string.format(g_i18n:getText("modHub_installNoFreeSpace"), v81_, v79_))
		else
			local v82_ = string.namedFormat(g_i18n:getText("ui_downloadingServerMods"), "numMods", v78_, "filesize", string.format("%.02f", v81_ / 1024))
			YesNoDialog.show(function(p83_)
				-- upvalues: (copy) v_u_76_
				if p83_ then
					g_modHubController:installOrUpdateMods(v_u_76_, function(p84_)
						g_masterServerConnection:disconnectFromMasterServer()
						g_connectionManager:shutdownAll()
						g_modHubScreen:openDownloads()
						if p84_ > 0 then
							InfoDialog.show(g_i18n:getText("modHub_installFailed"))
						end
					end)
				end
			end, nil, v82_, g_i18n:getText("ui_downloadingServerModsTitle"))
		end
	else
		return
	end
end

-- Local values: _, platformUserId, _, callback
function ServerDetailScreen:onClickBlockOrShowInfo()
	if self.doShowUserProfile then
		local _, v86_, _ = masterServerGetServerUserInfo(self.serverId)
		showUserProfile(v86_)
	else
		YesNoDialog.show(function(p87_)
			-- upvalues: (copy) self
			if p87_ then
				local v88_, v89_, v90_ = masterServerGetServerUserInfo(self.serverId)
				setIsUserBlocked(v88_, v89_, v90_, true, self.serverName)
				g_messageCenter:publish(MessageType.BLOCK_LIST_CHANGED)
				self:onClickBack()
			end
		end, nil, g_i18n:getText("ui_doYouWantToBlockThisServer"), g_i18n:getText("ui_doYouWantToBlockThisServer_title"))
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
	return string.gsub(modTitle, ";", " ") .. ";" .. string.gsub(version, ";", " ") .. ";" .. string.gsub(author, ";", " ") .. ";" .. string.gsub(modName, ";", " ")
end

-- Local values: parts, modTitle, version, author, modName
function ServerDetailScreen.unpackModInfo(str)
	local v99_ = str:split(";")
	local v100_ = v99_[1]
	local v101_ = v99_[2]
	local v102_ = v99_[3]
	local v103_ = v99_[4]
	return (v100_ == nil or v100_ == "") and "Unknown Title" or v100_, (v101_ == nil or v101_ == "") and "0.0.0.1" or v101_, v102_ == nil and "" or v102_, v103_ == nil and "" or v103_
end

function ServerDetailScreen:getNumberOfItemsInSection(list, section)
	return #self.sortedMods
end

-- Local values: modInfo, hash, iconElement, hash1, hash2
function ServerDetailScreen:populateCellForItemInSection(list, section, index, cell)
	local v108_ = self.sortedMods[index]
	local v109_ = v108_.hash
	local v110_ = cell:getAttribute("icon")
	v110_:setVisible(v108_.icon ~= nil)
	if v108_.icon ~= nil then
		v110_:setIsWebOverlay(v108_.iconIsWeb == true)
		v110_:setImageFilename(v108_.icon)
	end
	cell:getAttribute("title"):setText(v108_.title)
	cell:getAttribute("version"):setText(g_i18n:getText("ui_modVersion") .. " " .. v108_.version)
	cell:getAttribute("zipFilename"):setText(v108_.zipFilename)
	cell:getAttribute("missingIcon"):setVisible(v108_.availability ~= "ui_modAvailable")
	cell:getAttribute("missingIconBg"):setVisible(v108_.availability == "ui_modUnavailable")
	if v108_.hash == nil then
		cell:getAttribute("hash"):setVisible(false)
		cell:getAttribute("author"):setVisible(false)
	else
		local v111_ = v108_.hash:sub(1, v109_:len() / 2)
		local v112_ = v109_:sub(v109_:len() / 2 + 1)
		cell:getAttribute("hash"):setText(v111_ .. "\n" .. v112_)
		cell:getAttribute("hash"):setVisible(true)
		cell:getAttribute("author"):setText(v108_.author)
		cell:getAttribute("author"):setVisible(true)
	end
end
