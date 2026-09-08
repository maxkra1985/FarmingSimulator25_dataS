-- Local values: MoneyChangeEvent_mt
MoneyChangeEvent = {}
local MoneyChangeEvent_mt = Class(MoneyChangeEvent, Event)
InitStaticEventClass(MoneyChangeEvent, "MoneyChangeEvent")
function MoneyChangeEvent.emptyNew()
	-- upvalues: (copy) MoneyChangeEvent_mt
	return Event.new(MoneyChangeEvent_mt)
end

-- Local values: self
function MoneyChangeEvent.new(amount, moneyType, farmId, text)
	local v6_ = MoneyChangeEvent.emptyNew()
	v6_.amount = amount
	v6_.moneyType = moneyType
	v6_.farmId = farmId
	v6_.text = text
	return v6_
end

function MoneyChangeEvent:writeStream(streamId, connection)
	streamWriteFloat32(streamId, self.amount)
	streamWriteUInt16(streamId, self.moneyType.id)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	if self.text == nil then
		streamWriteBool(streamId, false)
	else
		streamWriteBool(streamId, true)
		streamWriteString(streamId, self.text)
	end
end

-- Local values: moneyTypeId
function MoneyChangeEvent:readStream(streamId, connection)
	self.amount = streamReadFloat32(streamId)
	local v12_ = streamReadUInt16(streamId)
	self.moneyType = MoneyType.getMoneyTypeById(v12_)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	if streamReadBool(streamId) then
		self.text = streamReadString(streamId)
	end
	self:run(connection)
end

-- Local values: text
function MoneyChangeEvent:run(connection)
	if g_currentMission:getFarmId() == self.farmId and self.moneyType ~= nil then
		g_currentMission.hud:addMoneyChange(self.moneyType, self.amount)
		local v14_
		if self.text == nil then
			v14_ = nil
		else
			v14_ = g_i18n:getText(self.text)
		end
		g_currentMission.hud:showMoneyChange(self.moneyType, v14_)
	end
end
