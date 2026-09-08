-- Local values: GameplayHintManager_mt
GameplayHintManager = {}
local GameplayHintManager_mt = Class(GameplayHintManager, AbstractManager)

-- Upvalues: GameplayHintManager_mt
-- Local values: self
function GameplayHintManager.new(customMt)
	-- upvalues: (copy) GameplayHintManager_mt
	return AbstractManager.new(customMt or GameplayHintManager_mt)
end

function GameplayHintManager:initDataStructures()
	self.gameplayHints = {}
	self.isLoaded = false
end

-- Local values: filenameStr, filename, customEnvironment, _, gameplayHintXmlFile, i, key, text
function GameplayHintManager:loadMapData(xmlFile, missionInfo)
	GameplayHintManager:superClass().loadMapData(self)
	local v6_ = getXMLString(xmlFile, "map.gameplayHints#filename")
	if v6_ == nil then
		Logging.xmlInfo(xmlFile, "No gameplay hints defined for map")
		return false
	end
	local v7_ = Utils.getFilename(v6_, g_currentMission.baseDirectory)
	if v7_ == nil or (v7_ == "" or not fileExists(v7_)) then
		Logging.xmlError(xmlFile, "Could not load gameplayHint config file \'" .. tostring(v6_) .. "\'!")
		return false
	end
	local v8_, _ = Utils.getModNameAndBaseDirectory(v7_)
	local v9_ = loadXMLFile("gameplayHints", v7_)
	if v9_ ~= 0 then
		local v10_ = 0
		while true do
			local v11_ = string.format("gameplayHints.gameplayHint(%d)", v10_)
			if not hasXMLProperty(v9_, v11_) then
				break
			end
			local v12_ = getXMLString(v9_, v11_)
			if v12_:sub(1, 6) == "$l10n_" then
				v12_ = g_i18n:getText(v12_:sub(7), v8_)
			end
			local v13_ = self.gameplayHints
			table.insert(v13_, v12_)
			v10_ = v10_ + 1
		end
		delete(v9_)
	end
	self.isLoaded = true
	return true
end

-- Local values: hints, addedHints, numHints, hintId
function GameplayHintManager:getRandomGameplayHint(numberOfHints)
	local v16_ = {}
	local v17_ = {}
	if #self.gameplayHints <= numberOfHints then
		return self.gameplayHints
	end
	local v18_ = #self.gameplayHints
	while #v16_ < numberOfHints do
		local v19_ = math.random(1, v18_)
		if v17_[v19_] == nil then
			local v20_ = self.gameplayHints[v19_]
			table.insert(v16_, v20_)
			v17_[v19_] = v19_
		end
	end
	return v16_
end

function GameplayHintManager:getIsLoaded()
	return self.isLoaded
end
g_gameplayHintManager = GameplayHintManager.new()
