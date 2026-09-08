-- Local values: TransferMoneyEvent_mt
TransferMoneyEvent = {}
local TransferMoneyEvent_mt = Class(TransferMoneyEvent, Event)
InitStaticEventClass(TransferMoneyEvent, "TransferMoneyEvent")
function TransferMoneyEvent.emptyNew()
	-- upvalues: (copy) TransferMoneyEvent_mt
	return Event.new(TransferMoneyEvent_mt)
end

-- Local values: self
function TransferMoneyEvent.new(amount, destinationFarmId)
	local v4_ = TransferMoneyEvent.emptyNew()
	v4_.amount = amount
	v4_.destinationFarmId = destinationFarmId
	return v4_
end

function TransferMoneyEvent:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.amount)
	streamWriteUIntN(streamId, self.destinationFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end

function TransferMoneyEvent:readStream(streamId, connection)
	self.amount = streamReadInt32(streamId)
	self.destinationFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self:run(connection)
end

-- Local values: senderUserId, senderFarm
function TransferMoneyEvent:run(connection)
	if connection:getIsServer() then
		printError("Error: TransferMoneyEvent is a client to server only event")
	else
		local v12_ = g_currentMission.userManager:getUserIdByConnection(connection)
		local v13_ = g_farmManager:getFarmByUserId(v12_)
		if g_currentMission:getHasPlayerPermission("transferMoney", connection, v13_.farmId) then
			local v14_ = v13_.money
			if math.round(v14_) >= self.amount then
				g_currentMission:addMoney(-self.amount, v13_.farmId, MoneyType.TRANSFER, true, true)
				g_currentMission:addMoney(self.amount, self.destinationFarmId, MoneyType.TRANSFER, true, true)
				return
			end
		end
	end
end
