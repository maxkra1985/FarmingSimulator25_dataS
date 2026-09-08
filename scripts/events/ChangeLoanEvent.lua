-- Local values: ChangeLoanEvent_mt
ChangeLoanEvent = {}
local ChangeLoanEvent_mt = Class(ChangeLoanEvent, Event)
InitStaticEventClass(ChangeLoanEvent, "ChangeLoanEvent")
function ChangeLoanEvent.emptyNew()
	-- upvalues: (copy) ChangeLoanEvent_mt
	return Event.new(ChangeLoanEvent_mt)
end

-- Local values: self
function ChangeLoanEvent.new(loanValue, farmId)
	local v4_ = ChangeLoanEvent.emptyNew()
	v4_.loanValue = loanValue
	v4_.farmId = farmId
	return v4_
end

function ChangeLoanEvent:readStream(streamId, connection)
	self.loanValue = streamReadFloat32(streamId)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self:run(connection)
end

function ChangeLoanEvent:writeStream(streamId, connection)
	streamWriteFloat32(streamId, self.loanValue)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end

-- Local values: farm, curLoan, minLoan, maxLoan, delta, farm
function ChangeLoanEvent:run(connection)
	if connection:getIsServer() then
		local v12_ = g_farmManager:getFarmById(self.farmId)
		if v12_ ~= nil then
			v12_.loan = self.loanValue
		end
		g_messageCenter:publish(ChangeLoanEvent)
	elseif self.farmId ~= 0 and g_currentMission:getHasPlayerPermission("farmManager", connection, self.farmId) then
		local v13_ = g_farmManager:getFarmById(self.farmId)
		local v14_ = v13_.loan
		local v15_ = v13_.loanMax
		local v16_ = math.max(v15_, v14_)
		local v17_ = v14_ + self.loanValue
		v13_.loan = math.clamp(v17_, 0, v16_)
		v13_:changeBalance(v13_.loan - v14_)
		g_server:broadcastEvent(ChangeLoanEvent.new(v13_.loan, v13_.farmId), false, nil)
		g_messageCenter:publish(ChangeLoanEvent)
		return
	end
end
