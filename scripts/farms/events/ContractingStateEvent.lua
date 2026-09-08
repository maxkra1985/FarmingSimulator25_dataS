-- Local values: ContractingStateEvent_mt
ContractingStateEvent = {}
local ContractingStateEvent_mt = Class(ContractingStateEvent, Event)
InitStaticEventClass(ContractingStateEvent, "ContractingStateEvent")
function ContractingStateEvent.emptyNew()
	-- upvalues: (copy) ContractingStateEvent_mt
	return Event.new(ContractingStateEvent_mt)
end

-- Local values: self
function ContractingStateEvent.new(byFarmId, forFarmId, state)
	local v5_ = ContractingStateEvent.emptyNew()
	v5_.byFarmId = byFarmId
	v5_.forFarmId = forFarmId
	v5_.state = state
	return v5_
end

function ContractingStateEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.byFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	streamWriteUIntN(streamId, self.forFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	streamWriteBool(streamId, self.state)
end

function ContractingStateEvent:readStream(streamId, connection)
	self.byFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self.forFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self.state = streamReadBool(streamId)
	self:run(connection)
end

-- Local values: byFarm
function ContractingStateEvent:run(connection)
	local v13_ = g_farmManager:getFarmById(self.byFarmId)
	if connection:getIsServer() then
		v13_:setIsContractingFor(self.forFarmId, self.state, true)
		g_messageCenter:publish(ContractingStateEvent, v13_.farmId, self.forFarmId, self.state)
	elseif g_currentMission:getHasPlayerPermission("manageContracting", connection, self.forFarmId) then
		v13_:setIsContractingFor(self.forFarmId, self.state, true)
		g_server:broadcastEvent(self)
		return
	end
end
