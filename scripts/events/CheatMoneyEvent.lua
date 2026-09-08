-- Local values: CheatMoneyEvent_mt
CheatMoneyEvent = {}
local CheatMoneyEvent_mt = Class(CheatMoneyEvent, Event)
InitStaticEventClass(CheatMoneyEvent, "CheatMoneyEvent")
function CheatMoneyEvent.emptyNew()
	-- upvalues: (copy) CheatMoneyEvent_mt
	return Event.new(CheatMoneyEvent_mt)
end

-- Local values: self
function CheatMoneyEvent.new(amount, farmId)
	local v4_ = CheatMoneyEvent.emptyNew()
	v4_.amount = amount
	v4_.farmId = farmId
	return v4_
end

function CheatMoneyEvent:readStream(streamId, connection)
	local v8_ = g_currentMission
	assert(v8_:getIsServer())
	self.amount = streamReadInt32(streamId)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	if g_currentMission:getIsServer() and (not connection:getIsServer() and (g_currentMission.userManager:getIsConnectionMasterUser(connection) and self.farmId ~= FarmManager.SPECTATOR_FARM_ID)) then
		g_currentMission:addMoney(self.amount, self.farmId, MoneyType.OTHER)
	end
end

function CheatMoneyEvent:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.amount)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end

function CheatMoneyEvent:run(connection)
	printError("Error: CheatMoneyEvent is a client to server only event")
end
