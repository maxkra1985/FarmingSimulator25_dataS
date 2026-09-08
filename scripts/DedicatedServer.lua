-- Local values: DedicatedServer_mt
DedicatedServer = {}
DedicatedServer.PAUSE_MODE_NO = 1
DedicatedServer.PAUSE_MODE_INSTANT = 2
DedicatedServer.MIN_FRAME_LIMIT = 5
DedicatedServer.MAX_FRAME_LIMIT = 60
local DedicatedServer_mt = Class(DedicatedServer)

-- Upvalues: DedicatedServer_mt
-- Local values: self
function DedicatedServer.new(customMt)
	-- upvalues: (copy) DedicatedServer_mt
	local v3_ = customMt or DedicatedServer_mt
	local v4_ = setmetatable({}, v3_)
	v4_.filename = ""
	v4_.name = "Farming Simulator Dedicated Game"
	v4_.password = ""
	v4_.savegame = 1
	v4_.maxPlayer = g_serverMaxCapacity
	v4_.ip = ""
	v4_.port = 10823
	v4_.crossplayAllowed = true
	v4_.mapName = ""
	v4_.mapFileName = ""
	v4_.adminPassword = ""
	v4_.pauseGameIfEmpty = true
	v4_.mpLanguageCode = "en"
	v4_.autoSaveInterval = 0
	v4_.gameStatsInterval = 60000
	v4_.mods = {}
	v4_.economicDifficulty = 1
	v4_.initialMoney = 100000
	v4_.initialLoan = 0
	v4_.hasStartFarm = false
	return v4_
end

-- Local values: xmlFile, xmlKey, _, modKey, modFilename, modIsDLC, numL, languageIndex
function DedicatedServer:load(filename, gameStatsFilename)
	local v8_ = XMLFile.load("DedicatedServerConfig", filename)
	if v8_ ~= nil then
		self.filename = filename
		self.name = v8_:getString("gameserver.settings.game_name", self.name)
		self.password = v8_:getString("gameserver.settings.game_password", self.password)
		local v9_ = v8_:getInt("gameserver.settings.savegame_index", self.savegame)
		local v10_ = SavegameController.NUM_SAVEGAMES
		self.savegame = math.clamp(v9_, 1, v10_)
		local v11_ = v8_:getInt("gameserver.settings.max_player", self.maxPlayer)
		local v12_ = g_serverMinCapacity
		local v13_ = g_serverMaxCapacity
		self.maxPlayer = math.clamp(v11_, v12_, v13_)
		self.ip = v8_:getString("gameserver.settings.ip", self.ip)
		self.port = v8_:getInt("gameserver.settings.port", self.port)
		self.crossplayAllowed = v8_:getBool("gameserver.settings.crossplay_allowed", self.crossplayAllowed)
		local v14_ = v8_:getInt("gameserver.settings.economicDifficulty", self.economicDifficulty)
		self.economicDifficulty = math.clamp(v14_, 1, 3)
		self.initialMoney = v8_:getInt("gameserver.settings.initialMoney", self.initialMoney)
		self.initialLoan = v8_:getInt("gameserver.settings.initialLoan", self.initialLoan)
		self.mapName = v8_:getString("gameserver.settings.mapID", self.mapName)
		self.mapFileName = v8_:getString("gameserver.settings.mapFilename", self.mapFileName)
		self.adminPassword = v8_:getString("gameserver.settings.admin_password", self.adminPassword)
		if self.adminPassword == "" then
			Logging.info("Starting dedicated server without an admin password!")
		end
		self.mpLanguageCode = v8_:getString("gameserver.settings.language", self.mpLanguageCode)
		self.pauseGameIfEmpty = v8_:getInt("gameserver.settings.pause_game_if_empty", DedicatedServer.PAUSE_MODE_INSTANT) == DedicatedServer.PAUSE_MODE_INSTANT
		local v15_ = v8_:getInt("gameserver.settings.auto_save_interval", self.autoSaveInterval)
		self.autoSaveInterval = math.clamp(v15_, 0, 360)
		local v16_ = v8_:getInt("gameserver.settings.stats_interval", self.gameStatsInterval)
		self.gameStatsInterval = math.max(v16_, 10) * 1000
		for _, v17_ in v8_:iterator("gameserver.mods.mod") do
			local v18_ = v8_:getString(v17_ .. "#filename")
			if v8_:getBool(v17_ .. "#isDlc") and g_dlcModNameHasPrefix[v18_] then
				v18_ = g_uniqueDlcNamePrefix .. v18_
			end
			local v19_ = self.mods
			table.insert(v19_, v18_)
		end
		v8_:delete()
	end
	CaptionUtil.addText(string.format(" - ServerName: \'%s\'", self.name))
	if string.endsWith(self.mapFileName, ".dlc") and not string.startsWith(self.mapFileName, "pdlc_") then
		self.mapFileName = "pdlc_" .. self.mapFileName
	end
	for v20_ = 0, getNumOfLanguages() - 1 do
		if getLanguageCode(v20_) == self.mpLanguageCode then
			g_gameSettings:setValue(GameSettings.SETTING.MP_LANGUAGE, v20_)
			break
		end
	end
	self.gameStats = GameStats.new(gameStatsFilename, self.gameStatsInterval)
end

function DedicatedServer:delete()
	if self.gameStats ~= nil then
		self.gameStats:delete()
		self.gameStats = nil
	end
end

function DedicatedServer:update(dt)
	if self.gameStats ~= nil then
		self.gameStats:update(dt)
	end
end

function DedicatedServer:onStartMission(mission)
	if self.gameStats ~= nil then
		self.gameStats:init(mission)
	end
end

-- Local values: frameRateLimit
function DedicatedServer:lowerFramerate()
	local v26_ = DedicatedServer.MIN_FRAME_LIMIT
	Logging.devInfo("DedicatedServer:raiseFramerate: set framerate to %d", v26_)
	setFramerateLimiter(true, v26_)
end

-- Local values: frameRateLimit, param
function DedicatedServer:raiseFramerate()
	local v27_ = DedicatedServer.MAX_FRAME_LIMIT
	local v28_
	if g_isDevelopmentVersion then
		local v29_ = StartParams.getValue
		v28_ = tonumber(v29_("serverFrameRateLimit"))
		if v28_ == nil then
			v28_ = v27_
		end
	else
		v28_ = v27_
	end
	Logging.devInfo("DedicatedServer:raiseFramerate: set framerate to %d", v28_)
	setFramerateLimiter(true, v28_)
end

-- Local values: xmlFile, xmlKey
function DedicatedServer:updateServerInfo(serverName, password, capacity)
	if self.filename ~= nil then
		local v34_ = XMLFile.load("DedicatedServerConfig", self.filename)
		v34_:setString("gameserver.settings.game_name", serverName)
		v34_:setString("gameserver.settings.game_password", password)
		v34_:setInt("gameserver.settings.max_player", capacity)
		v34_:save()
		v34_:delete()
	end
end

function DedicatedServer:start()
	g_gui:setIsMultiplayer(true)
	g_gui:showGui("CareerScreen")
	g_gameSettings:setValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME, "Server")
end
