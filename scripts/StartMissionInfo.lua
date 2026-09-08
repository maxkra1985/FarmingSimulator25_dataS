-- Local values: StartMissionInfo_mt
StartMissionInfo = {}
local StartMissionInfo_mt = Class(StartMissionInfo)

-- Upvalues: StartMissionInfo_mt
-- Local values: self
function StartMissionInfo.new(subclass_mt)
	-- upvalues: (copy) StartMissionInfo_mt
	local v3_ = subclass_mt or StartMissionInfo_mt
	local v4_ = setmetatable({}, v3_)
	v4_:reset()
	return v4_
end

function StartMissionInfo:reset()
	self.isMultiplayer = false
	self.createGame = false
	self.canStart = false
	self.mapId = "MapUS"
	self.economicDifficulty = EconomicDifficulty.EASY
	self.initialMoney = 100000
	self.initialLoan = 0
	self.hasStartFarm = true
	self.startWithGuidedTour = true
end
