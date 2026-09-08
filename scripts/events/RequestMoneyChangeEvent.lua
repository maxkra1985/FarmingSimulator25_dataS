-- Local values: RequestMoneyChangeEvent_mt
RequestMoneyChangeEvent = {}
local RequestMoneyChangeEvent_mt = Class(RequestMoneyChangeEvent, Event)
InitStaticEventClass(RequestMoneyChangeEvent, "RequestMoneyChangeEvent")
function RequestMoneyChangeEvent.emptyNew()
	-- upvalues: (copy) RequestMoneyChangeEvent_mt
	return Event.new(RequestMoneyChangeEvent_mt)
end

-- Local values: self
function RequestMoneyChangeEvent.new(moneyType)
	local v3_ = RequestMoneyChangeEvent.emptyNew()
	v3_.moneyTypeId = moneyType.id
	return v3_
end

function RequestMoneyChangeEvent:writeStream(streamId, connection)
	streamWriteUInt8(streamId, self.moneyTypeId)
end

function RequestMoneyChangeEvent:readStream(streamId, connection)
	self.moneyTypeId = streamReadUInt8(streamId)
	self:run(connection)
end

-- Local values: farmId, moneyType, player
function RequestMoneyChangeEvent:run(connection)
	local v11_ = nil
	local v12_ = MoneyType.getMoneyTypeById(self.moneyTypeId)
	if v12_ == nil then
		local v13_ = Logging.devError
		local v14_ = self.moneyTypeId
		v13_("RequestMoneyChangeEvent - MoneyType with id \'%s\' not found!", (tostring(v14_)))
	end
	local v15_ = g_currentMission:getPlayerByConnection(connection)
	if v15_ ~= nil then
		v11_ = v15_.farmId
	end
	if v11_ == nil then
		Logging.devError("RequestMoneyChangeEvent - Missing farmId for player!")
	end
	if v12_ ~= nil and v11_ ~= nil then
		g_currentMission:broadcastNotifications(v12_, v11_)
	end
end
