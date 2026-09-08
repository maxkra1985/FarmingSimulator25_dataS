-- Local values: AnimalSellEvent_mt
AnimalSellEvent = {}
AnimalSellEvent.SELL_SUCCESS = 0
AnimalSellEvent.SELL_ERROR_NO_PERMISSION = 1
AnimalSellEvent.SELL_ERROR_INVALID_CLUSTER = 2
AnimalSellEvent.SELL_ERROR_NOT_ENOUGH_ANIMALS = 3
AnimalSellEvent.SELL_ERROR_CANNOT_BE_SOLD = 4
AnimalSellEvent.SELL_ERROR_OBJECT_DOES_NOT_EXIST = 5
local AnimalSellEvent_mt = Class(AnimalSellEvent, Event)
InitStaticEventClass(AnimalSellEvent, "AnimalSellEvent")
function AnimalSellEvent.emptyNew()
	-- upvalues: (copy) AnimalSellEvent_mt
	return Event.new(AnimalSellEvent_mt)
end

-- Local values: self
function AnimalSellEvent.new(object, clusterId, numAnimals, sellPrice, feePrice)
	local v7_ = AnimalSellEvent.emptyNew()
	v7_.object = object
	v7_.clusterId = clusterId
	v7_.numAnimals = numAnimals
	v7_.sellPrice = sellPrice
	v7_.feePrice = feePrice
	return v7_
end

-- Local values: self
function AnimalSellEvent.newServerToClient(errorCode)
	local v9_ = AnimalSellEvent.emptyNew()
	v9_.errorCode = errorCode
	return v9_
end

function AnimalSellEvent:readStream(streamId, connection)
	if connection:getIsServer() then
		self.errorCode = streamReadUIntN(streamId, 3)
	else
		self.object = NetworkUtil.readNodeObject(streamId)
		self.clusterId = streamReadInt32(streamId)
		self.numAnimals = streamReadUInt8(streamId)
		self.sellPrice = streamReadInt32(streamId)
		self.feePrice = -streamReadInt32(streamId)
	end
	self:run(connection)
end

function AnimalSellEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.object)
		streamWriteInt32(streamId, self.clusterId)
		streamWriteUInt8(streamId, self.numAnimals)
		local v16_ = streamWriteInt32
		local v17_ = self.sellPrice
		v16_(streamId, (math.abs(v17_)))
		local v18_ = streamWriteInt32
		local v19_ = self.feePrice
		v18_(streamId, (math.abs(v19_)))
	else
		streamWriteUIntN(streamId, self.errorCode, 3)
	end
end

-- Local values: errorCode, cluster, clusterSystem, uniqueUserId, farm, price
function AnimalSellEvent:run(connection)
	if connection:getIsServer() then
		g_messageCenter:publish(AnimalSellEvent, self.errorCode)
		return
	elseif g_currentMission:getHasPlayerPermission("tradeAnimals", connection) then
		local v22_ = AnimalSellEvent.validate(self.object, self.clusterId, self.numAnimals, self.sellPrice, self.feePrice)
		if v22_ == nil then
			local v23_ = self.object:getClusterById(self.clusterId)
			local v24_ = self.object:getClusterSystem()
			v23_:changeNumAnimals(-self.numAnimals)
			v24_:updateNow()
			local v25_ = g_currentMission.userManager:getUniqueUserIdByConnection(connection)
			local v26_ = g_farmManager:getFarmForUniqueUserId(v25_)
			local v27_ = self.sellPrice + self.feePrice
			g_currentMission:addMoney(v27_, v26_.farmId, MoneyType.SOLD_ANIMALS, true, true)
			connection:sendEvent(AnimalSellEvent.newServerToClient(AnimalSellEvent.SELL_SUCCESS))
		else
			connection:sendEvent(AnimalSellEvent.newServerToClient(v22_))
		end
	else
		connection:sendEvent(AnimalSellEvent.newServerToClient(AnimalSellEvent.SELL_ERROR_NO_PERMISSION))
		return
	end
end

-- Local values: cluster
function AnimalSellEvent.validate(object, clusterId, numAnimals, sellPrice, feePrice)
	if object == nil then
		return AnimalSellEvent.SELL_ERROR_OBJECT_DOES_NOT_EXIST
	else
		local v31_ = object:getClusterById(clusterId)
		if v31_ == nil then
			return AnimalSellEvent.SELL_ERROR_INVALID_CLUSTER
		elseif v31_:getNumAnimals() < numAnimals then
			return AnimalSellEvent.SELL_ERROR_NOT_ENOUGH_ANIMALS
		elseif v31_:getCanBeSold() then
			return nil
		else
			return AnimalSellEvent.SELL_ERROR_CANNOT_BE_SOLD
		end
	end
end
