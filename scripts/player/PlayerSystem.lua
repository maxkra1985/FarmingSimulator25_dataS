-- Local values: PlayerSystem_mt
PlayerSystem = {}
local PlayerSystem_mt = Class(PlayerSystem)
PlayerSystem.MAX_NUM_SAVED_PLAYERS = 250
PlayerSystem.MAX_NUM_DAYS_OFFLINE = 30
PlayerSystem.PLAYER_STYLES_BY_FILENAME = {}
PlayerSystem.PLAYER_STYLES = {}
PlayerSystem.DEBUG_ANIMATIONS = false
PlayerSystem.DEBUG_SOUNDS = false
g_xmlManager:addEarlyCreateSchemaFunction(function()
	PlayerSystem.charactersXMLSchema = XMLSchema.new("playerModels")
	PlayerSystem.registerCharactersXMLPaths(PlayerSystem.charactersXMLSchema)
	PlayerSystem.xmlSchema = XMLSchema.new("player")
	PlayerSystem.registerXMLPaths(PlayerSystem.xmlSchema)
	PlayerSystem.savegameXMLSchema = XMLSchema.new("savegame_players")
	PlayerSystem.registerSavegameXMLPaths(PlayerSystem.savegameXMLSchema)
end)

-- Local values: modelKey
function PlayerSystem.registerCharactersXMLPaths(charactersXMLSchema)
	charactersXMLSchema:register(XMLValueType.STRING, "playerModels.playerModel(?)#filename", "The filename of the player file", nil, true)
	charactersXMLSchema:register(XMLValueType.STRING, "playerModels.playerModel(?)#name", "The name of the player file", nil, true)
	charactersXMLSchema:register(XMLValueType.STRING, "playerModels.playerModel(?)#gender", "The gender of the player file", nil, true)
end

function PlayerSystem.registerXMLPaths(xmlSchema)
	Player.registerXMLPaths(xmlSchema)
end

-- Local values: baseKey
function PlayerSystem.registerSavegameXMLPaths(savegameXMLSchema)
	Player.registerSavegameXMLPaths(savegameXMLSchema, "players")
end
function PlayerSystem.new()
	-- upvalues: (copy) PlayerSystem_mt
	local v5_ = PlayerSystem_mt
	local v6_ = setmetatable({}, v5_)
	v6_.players = {}
	v6_.playersByUniqueId = {}
	v6_.playersByUserId = {}
	v6_.playersByRootNode = {}
	v6_.playersByConnection = {}
	if g_server ~= nil then
		v6_.unloadedPlayerDataCount = 0
		v6_.unloadedPlayerDataByUniqueId = {}
	end
	g_messageCenter:subscribe(MessageType.USER_ADDED, PlayerSystem.onUserAdded, v6_)
	g_playerSystem = v6_
	addConsoleCommand("gsPlayerAnimationReload", "Reloads the animations", "consoleCommandAnimationReload", v6_)
	addConsoleCommand("gsPlayerAnimationDebug", "Toggles animation debug view", "consoleCommandAnimationDebug", v6_)
	addConsoleCommand("gsPlayerSoundsReload", "Reloads the sounds", "consoleCommandSoundReload", v6_)
	addConsoleCommand("gsPlayerSoundsDebug", "Toggles sounds debug view", "consoleCommandSoundDebug", v6_)
	return v6_
end

function PlayerSystem:delete()
	removeConsoleCommand("gsPlayerAnimationReload")
	removeConsoleCommand("gsPlayerAnimationDebug")
	removeConsoleCommand("consoleCommandSoundReload")
	removeConsoleCommand("consoleCommandSoundDebug")
	g_messageCenter:unsubscribeAll(self)
	g_playerSystem = nil
end

-- Local values: rootKey, xmlFile, savedPlayerCount, i, player
function PlayerSystem:saveToXMLFile(xmlFilename)
	local v10_ = XMLFile.create("Players", xmlFilename, "players", PlayerSystem.savegameXMLSchema)
	if v10_ == nil then
		return false
	end
	local v11_ = 0
	for _, v12_ in ipairs(self.players) do
		v12_:saveToXMLFile(v10_, string.format("%s.player(%d)", "players", v11_))
		v11_ = v11_ + 1
	end
	if v11_ + self.unloadedPlayerDataCount >= PlayerSystem.MAX_NUM_SAVED_PLAYERS then
		self:saveHugeUnloadedPlayers(v10_, "players")
	else
		self:saveUnloadedPlayers(v10_, "players")
	end
	v10_:save()
	v10_:delete()
	return true
end

-- Local values: savedPlayerCount, currentPlayerDataCount, _, playerData
function PlayerSystem:saveUnloadedPlayers(xmlFile, baseKey)
	local v16_ = self:getPlayerCount()
	for _, v17_ in pairs(self.unloadedPlayerDataByUniqueId) do
		Player.saveDataToXMLFile(xmlFile, v17_, string.format("%s.player(%d)", baseKey, v16_))
		v16_ = v16_ + 1
	end
end

-- Local values: savedPlayerCount, sortedPlayerDataByLastPlayTime, _, playerData, currentYear, currentMonth, currentDay, currentHour, currentMinute, maxSecondsSinceLastConnection, i, playerData, year, month, day, hour, minute
function PlayerSystem:saveHugeUnloadedPlayers(xmlFile, baseKey)
	local v21_ = self:getPlayerCount()
	local v22_ = table.create(self.unloadedPlayerDataCount)
	for _, v23_ in pairs(self.unloadedPlayerDataByUniqueId) do
		table.insert(v22_, v23_)
	end
	table.sort(v22_, function(p24_, p25_)
		return p24_.lastConnectedDateTime > p25_.lastConnectedDateTime
	end)
	local v26_, v27_, v28_, v29_, v30_ = string.match(getDate("%Y/%m/%d %H:%M"), "(%d+)/(%d+)/(%d+) (%d+):(%d+)")
	local v31_ = tonumber(v26_)
	local v32_ = tonumber(v27_)
	local v33_ = tonumber(v28_)
	local v34_ = tonumber(v29_)
	local v35_ = tonumber(v30_)
	local v36_ = PlayerSystem.MAX_NUM_DAYS_OFFLINE * 24 * 60 * 60
	for v37_, v38_ in ipairs(v22_) do
		if v37_ + v21_ > PlayerSystem.MAX_NUM_SAVED_PLAYERS then
			local v39_, v40_, v41_, v42_, v43_ = string.match(v38_.lastConnectedDateTime, "(%d+)/(%d+)/(%d+) (%d+):(%d+)")
			local v44_ = tonumber(v39_)
			local v45_ = tonumber(v40_)
			local v46_ = tonumber(v41_)
			local v47_ = tonumber(v42_)
			local v48_ = tonumber(v43_)
			if v44_ ~= nil then
				local v49_ = getDateDiffSeconds(v44_, v45_, v46_, v47_, v48_, 0, v31_, v32_, v33_, v34_, v35_, 0)
				if v36_ < math.abs(v49_) then
					Logging.xmlInfo(xmlFile, "Excluded %d players from player save: Limit reached and affected players did not join the server for more than %d days", v21_ + self.unloadedPlayerDataCount - (v37_ - 1), PlayerSystem.MAX_NUM_DAYS_OFFLINE)
					return
				end
			end
		end
		Player.saveDataToXMLFile(xmlFile, v38_, string.format("%s.player(%d)", baseKey, v37_ + v21_ - 1))
	end
end

-- Local values: xmlFile, i, playerConfigKey, filename, name, gender, playerStyle, playerStyleConfig
function PlayerSystem.loadStyleConfigurationsXML(xmlFilename)
	local v51_ = XMLFile.loadIfExists("PlayerModels", xmlFilename, PlayerSystem.charactersXMLSchema)
	if v51_ == nil then
		Logging.fatal("Missing models file at %s, cannot load without player data!", xmlFilename)
	end
	for _, v52_ in v51_:iterator("playerModels.playerModel") do
		local v53_ = v51_:getValue(v52_ .. "#filename", nil)
		local v54_ = v51_:getValue(v52_ .. "#name", nil)
		local v55_ = v51_:getValue(v52_ .. "#gender", "male")
		if string.isNilOrWhitespace(v53_) then
			Logging.xmlError(v51_, "Player model at %s has invalid filename!", v52_)
		else
			local v56_ = PlayerStyle.new()
			v56_:loadConfigurationXML(v53_)
			local v57_ = {
				["filename"] = v56_.xmlFilename,
				["name"] = v54_,
				["gender"] = v55_,
				["style"] = v56_
			}
			PlayerSystem.PLAYER_STYLES_BY_FILENAME[v56_.xmlFilename] = v57_
			PlayerSystem.PLAYER_STYLES[#PlayerSystem.PLAYER_STYLES + 1] = v57_
		end
	end
	v51_:delete()
end

-- Local values: xmlFile, playerIndex, playerKey, playerData
function PlayerSystem:loadFromSavegameXML(xmlFilename)
	local v60_ = XMLFile.loadIfExists("Players", xmlFilename, PlayerSystem.savegameXMLSchema)
	if v60_ == nil then
		if self.logDebug then
			Logging.devInfo("No players saved under %s, skipping", xmlFilename)
		end
	else
		self.unloadedPlayerDataCount = 0
		for _, v61_ in v60_:iterator("players.player") do
			local v62_ = Player.loadDataFromXMLFile(v60_, v61_)
			self.unloadedPlayerDataByUniqueId[v62_.uniqueId] = v62_
			self.unloadedPlayerDataCount = self.unloadedPlayerDataCount + 1
		end
		v60_:delete()
	end
end

-- Local values: _, player, startPosX, lineOffsetY, posX, posY, textSize, numPlayer, _, player, name, startPosX, lineOffsetY, posX, posY, textSize, numPlayer, _, player, name
function PlayerSystem:draw()
	for _, v64_ in pairs(self.players) do
		if not v64_.isDeleted then
			v64_:drawUIInfo()
		end
	end
	if PlayerSystem.DEBUG_ANIMATIONS then
		local v65_ = getCorrectTextSize(0.012)
		local v66_ = 0.07
		local v67_ = 0.9
		local v68_ = 1
		for _, v69_ in pairs(self.players) do
			local v70_ = v69_:getNickname()
			setTextBold(true)
			renderText(v66_, v67_ + 0.02, v65_, v70_)
			setTextBold(false)
			v69_:drawDebug(v66_, v67_, v65_)
			v66_ = v66_ + 0.1
			v68_ = v68_ + 1
			if v68_ > 9 then
				v67_ = v67_ - 0.4
				v66_ = 0.07
				v68_ = 1
			end
		end
	end
	if PlayerSystem.DEBUG_SOUNDS then
		local v71_ = getCorrectTextSize(0.012)
		local v72_ = 0.07
		local v73_ = 0.9
		local v74_ = 1
		for _, v75_ in pairs(self.players) do
			local v76_ = v75_:getNickname()
			setTextBold(true)
			renderText(v72_, v73_ + 0.02, v71_, v76_)
			setTextBold(false)
			v75_.graphicsComponent.sounds:drawDebug(v72_, v73_, v71_)
			v72_ = v72_ + 0.1
			v74_ = v74_ + 1
			if v74_ > 9 then
				v73_ = v73_ - 0.4
				v72_ = 0.07
				v74_ = 1
			end
		end
	end
end

function PlayerSystem:getLocalPlayer()
	return g_localPlayer
end

function PlayerSystem:setLocalPlayer(localPlayer)
	g_localPlayer = localPlayer
end

function PlayerSystem:getHasPlayerWithUniqueId(uniqueId)
	if g_server == nil then
		local v80_
		if uniqueId == nil then
			v80_ = false
		else
			v80_ = self.playersByUniqueId[uniqueId] ~= nil
		end
		return v80_
	else
		local v81_
		if uniqueId == nil then
			v81_ = false
		else
			v81_ = self.playersByUniqueId[uniqueId] ~= nil and true or self.unloadedPlayerDataByUniqueId[uniqueId] ~= nil
		end
		return v81_
	end
end

function PlayerSystem:getIsPlayerAdded(player)
	local v84_
	if player == nil or player.uniqueUserId == nil then
		v84_ = false
	else
		v84_ = self:getPlayerByUniqueId(player.uniqueUserId) ~= nil
	end
	return v84_
end

function PlayerSystem:getPlayerCount()
	return #self.players
end

function PlayerSystem:getPlayerByIndex(index)
	return self.players[index]
end

function PlayerSystem:getPlayerByUniqueId(uniqueId)
	return self.playersByUniqueId[uniqueId]
end

function PlayerSystem:getPlayerByUserId(userId)
	return self.playersByUserId[userId]
end

function PlayerSystem:getPlayerByRootNode(rootNode)
	return self.playersByRootNode[rootNode]
end

function PlayerSystem:getPlayerByConnection(connection)
	return self.playersByConnection[connection]
end

function PlayerSystem:getPlayerDataByUniqueId(uniqueId)
	if g_server == nil then
		return nil
	else
		return self.unloadedPlayerDataByUniqueId[uniqueId]
	end
end

-- Local values: player, uniqueUserId
function PlayerSystem:onUserAdded(user)
	local v100_ = self:getPlayerByUserId(user:getId())
	if v100_ == nil then
		return
	else
		local v101_ = user:getUniqueUserId()
		if self:getPlayerByUniqueId(v101_) == nil then
			v100_:setUniqueUserId(v101_)
			self.playersByUniqueId[v101_] = v100_
			if g_server ~= nil and self.unloadedPlayerDataByUniqueId[v101_] ~= nil then
				self.unloadedPlayerDataByUniqueId[v101_] = nil
				self.unloadedPlayerDataCount = self.unloadedPlayerDataCount - 1
			end
		end
	end
end

-- Local values: existingPlayer
function PlayerSystem:addPlayer(player)
	local v104_ = self:getPlayerByUserId(player.userId)
	if v104_ ~= nil then
		if v104_ ~= player then
			Logging.error("Player with user id %d exists in the system with table address of %s, but a player with the same user id tried to be added with a table address of %s!", player.userId, tostring(v104_), (tostring(player)))
		end
		return false
	end
	local v105_ = self.players
	table.insert(v105_, player)
	self.playersByUserId[player.userId] = player
	self.playersByRootNode[player.rootNode] = player
	self.playersByConnection[player.connection] = player
	if not string.isNilOrWhitespace(player.uniqueUserId) then
		self.playersByUniqueId[player.uniqueUserId] = player
		if g_server ~= nil and self.unloadedPlayerDataByUniqueId[player.uniqueUserId] ~= nil then
			self.unloadedPlayerDataByUniqueId[player.uniqueUserId] = nil
			self.unloadedPlayerDataCount = self.unloadedPlayerDataCount - 1
		end
	end
	if player.isOwner then
		self:setLocalPlayer(player)
	end
	return true
end

-- Local values: playerData
function PlayerSystem:removePlayer(player)
	if g_server ~= nil then
		local v108_ = player:createData()
		self.unloadedPlayerDataByUniqueId[v108_.uniqueId] = v108_
		self.unloadedPlayerDataCount = self.unloadedPlayerDataCount + 1
	end
	table.removeElement(self.players, player)
	self.playersByUserId[player.userId] = nil
	self.playersByRootNode[player.rootNode] = nil
	self.playersByConnection[player.connection] = nil
	if not string.isNilOrWhitespace(player.uniqueUserId) then
		self.playersByUniqueId[player.uniqueUserId] = nil
	end
end

-- Local values: _, player
function PlayerSystem:consoleCommandAnimationReload()
	for _, v110_ in ipairs(self.players) do
		if v110_.graphicsComponent ~= nil then
			v110_.graphicsComponent:loadAnimation()
		end
	end
	return "Reloaded animation"
end

function PlayerSystem:consoleCommandAnimationDebug()
	PlayerSystem.DEBUG_ANIMATIONS = not PlayerSystem.DEBUG_ANIMATIONS
	return string.format("Animation debug: %s", PlayerSystem.DEBUG_ANIMATIONS)
end

function PlayerSystem:consoleCommandSoundDebug()
	PlayerSystem.DEBUG_SOUNDS = not PlayerSystem.DEBUG_SOUNDS
	return string.format("Sound debug: %s", PlayerSystem.DEBUG_SOUNDS)
end

-- Local values: _, player
function PlayerSystem:consoleCommandSoundReload()
	for _, v112_ in ipairs(self.players) do
		if v112_.graphicsComponent ~= nil then
			v112_.graphicsComponent:loadSounds()
		end
	end
	return "Reloaded animation"
end

-- Local values: i, player
function PlayerSystem:debugDrawAllPlayers(x, y, textSize)
	for _, v117_ in ipairs(self.players) do
		v117_:debugDraw(x, y, textSize)
		x = x + 0.2
	end
end
