-- Local values: AutoSaveManager_mt
AutoSaveManager = {}
AutoSaveManager.DEFAULT_INTERVAL = 15
AutoSaveManager.INTERVAL_OPTIONS = {}
AutoSaveManager.INTERVAL_OPTIONS[1] = 0
AutoSaveManager.INTERVAL_OPTIONS[2] = 5
AutoSaveManager.INTERVAL_OPTIONS[3] = 10
AutoSaveManager.INTERVAL_OPTIONS[4] = 15
local AutoSaveManager_mt = Class(AutoSaveManager, AbstractManager)

-- Upvalues: AutoSaveManager_mt
-- Local values: self
function AutoSaveManager.new(customMt)
	-- upvalues: (copy) AutoSaveManager_mt
	local v3_ = AbstractManager.new(customMt or AutoSaveManager_mt)
	v3_.interval = 60000 * AutoSaveManager.DEFAULT_INTERVAL
	v3_.time = v3_.interval
	v3_.isPending = false
	v3_.isActive = true
	v3_.saveNextFrame = false
	return v3_
end

function AutoSaveManager:loadFinished()
	g_messageCenter:subscribe(MessageType.GUI_INGAME_OPEN, self.onOpenIngameMenu, self)
	g_messageCenter:subscribe(MessageType.SAVEGAME_LOADED, self.onSavegameLoaded, self)
	if g_currentMission:getIsServer() then
		addConsoleCommand("gsAutoSave", "Enables/disables auto save", "consoleCommandAutoSave", self, "[true|false]")
		addConsoleCommand("gsAutoSaveInterval", "Sets the auto save interval", "consoleCommandAutoSaveInterval", self, "[minutes]")
	end
end

function AutoSaveManager:unloadMapData()
	g_messageCenter:unsubscribeAll(self)
	if g_currentMission:getIsServer() then
		removeConsoleCommand("gsAutoSaveInterval")
		removeConsoleCommand("gsAutoSave")
	end
end

function AutoSaveManager:update(dt)
	if self:getIsAutoSaveAllowed() and (g_currentMission:getIsServer() and (g_currentMission.gameStarted and self.time < g_time)) then
		self.isPending = true
		if g_dedicatedServer ~= nil then
			self:runAutoSaveIfPending(true)
		end
	end
	if self.saveNextFrame then
		self:runAutoSaveIfPending()
		self.saveNextFrame = false
	end
end

function AutoSaveManager:runAutoSaveIfPending(hideVisuals)
	if self.isPending then
		self.isPending = false
		g_currentMission:startSaveCurrentGame(hideVisuals)
		self.time = g_time + self.interval
	end
end

function AutoSaveManager:onMissionStarted(isNewSavegame)
	self.time = g_time + self.interval
	self.isPending = false
end

function AutoSaveManager:onOpenIngameMenu()
	self.saveNextFrame = true
end

-- Local values: interval
function AutoSaveManager:onSavegameLoaded()
	if g_dedicatedServer == nil then
		local v12_ = 0
		if g_currentMission ~= nil then
			if g_currentMission.missionInfo ~= nil and g_currentMission.missionInfo.autoSaveInterval ~= nil then
				v12_ = g_currentMission.missionInfo.autoSaveInterval
			end
			g_messageCenter:subscribeOneshot(MessageType.CURRENT_MISSION_START, AutoSaveManager.onMissionStarted, self)
		end
		if not GS_IS_MOBILE_VERSION then
			self:setInterval(v12_)
		end
	end
end

function AutoSaveManager:setInterval(intervalMinutes)
	if intervalMinutes > 0 then
		self.interval = intervalMinutes * 60 * 1000
		self.time = g_time + self.interval
		self:setIsActive(true)
	else
		self:setIsActive(false)
	end
end

function AutoSaveManager:getInterval()
	return not self.isActive and 0 or self.interval / 60 / 1000
end

-- Local values: interval
function AutoSaveManager:getIntervalFromIndex(index)
	local v17_ = AutoSaveManager.INTERVAL_OPTIONS[index]
	return v17_ == nil and 0 or v17_
end

-- Local values: i, v
function AutoSaveManager:getIndexFromInterval(interval)
	for v19_, v20_ in ipairs(AutoSaveManager.INTERVAL_OPTIONS) do
		if v20_ == interval then
			return v19_
		end
	end
	return 1
end

function AutoSaveManager:getIntervalOptions()
	return AutoSaveManager.INTERVAL_OPTIONS
end

function AutoSaveManager:setIsActive(state)
	self.isActive = state
	if state then
		self.time = g_time + self.interval
	end
end

function AutoSaveManager:getIsActive()
	return self.isActive
end

function AutoSaveManager:resetTime()
	self.time = g_time + self.interval
end

function AutoSaveManager:getIsAutoSaveAllowed()
	if g_currentMission == nil or not g_currentMission:getIsAutoSaveSupported() then
		return false
	elseif g_appIsSuspended then
		return false
	elseif Profiler.IS_INITIALIZED then
		return false
	else
		return self.isActive
	end
end

-- Local values: currentInterval
function AutoSaveManager:consoleCommandAutoSaveInterval(intervalMinutes)
	if g_currentMission:getIsServer() then
		local v27_ = tonumber(intervalMinutes)
		if v27_ ~= nil then
			local v28_ = math.max(v27_, 0)
			g_autoSaveManager:setInterval(v28_)
		end
		local v29_ = g_autoSaveManager:getInterval()
		return string.format("AutoSaveInterval = %s\nArguments: intervalInMinutes", v29_ > 0 and string.format("%d minutes", v29_) or "off")
	end
	printError("This is a server-only command")
end

-- Local values: enabled
function AutoSaveManager:consoleCommandAutoSave(enabledStr)
	if g_currentMission:getIsServer() then
		if enabledStr == nil or enabledStr == "" then
			local v31_ = g_autoSaveManager
			return "AutoSave = " .. tostring(v31_:getIsActive()) .. ". Arguments: enabled[true|false]"
		end
		local v32_ = Utils.stringToBoolean(enabledStr)
		g_autoSaveManager:setIsActive(v32_)
		local v33_ = g_autoSaveManager
		return "AutoSave = " .. tostring(v33_:getIsActive())
	end
	printError("This is a server-only command")
end
