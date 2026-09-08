-- Local values: MissionInfo_mt
MissionInfo = {}
local MissionInfo_mt = Class(MissionInfo)

-- Upvalues: MissionInfo_mt
-- Local values: self
function MissionInfo.new(baseDirectory, customEnvironment, customMt)
	-- upvalues: (copy) MissionInfo_mt
	local v5_ = customMt or MissionInfo_mt
	local v6_ = setmetatable({}, v5_)
	v6_.baseDirectory = baseDirectory
	v6_.customEnvironment = customEnvironment
	v6_.savegameDirectory = nil
	v6_.mapId = nil
	v6_.mapTitle = nil
	v6_.mapXMLFilename = nil
	v6_.isValid = nil
	v6_.hasInitiallyOwnedFarmlands = nil
	v6_.initialMoney = nil
	v6_.initialLoan = nil
	v6_.isSnowEnabled = nil
	v6_.disasterDestructionState = nil
	v6_.growthMode = nil
	v6_.weedsEnabled = nil
	v6_.stonesEnabled = nil
	v6_.timeScale = nil
	v6_.dirtInterval = nil
	v6_.fruitDestruction = nil
	v6_.helperBuySeeds = nil
	v6_.helperBuyFertilizer = nil
	v6_.helperSlurrySource = nil
	v6_.helperManureSource = nil
	v6_.stopAndGoBraking = nil
	v6_.trailerFillLimit = nil
	v6_.automaticMotorStartEnabled = nil
	v6_.introductionHelpActive = nil
	v6_.autoSaveInterval = nil
	v6_.foundHelpIcons = nil
	v6_.economicDifficulty = nil
	v6_.trafficEnabled = nil
	return v6_
end

function MissionInfo:loadDefaults()
	self.id = "invalid"
	self.scriptFilename = ""
	self.scriptClass = ""
end

function MissionInfo:isValidMissionId(id)
	if id == nil or id:len() == 0 then
		return false
	else
		return id:find("[^%w_]") == nil
	end
end
