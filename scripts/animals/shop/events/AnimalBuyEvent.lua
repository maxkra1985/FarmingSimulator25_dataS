-- Local values: AnimalBuyEvent_mt
AnimalBuyEvent = {}
AnimalBuyEvent.BUY_SUCCESS = 0
AnimalBuyEvent.BUY_ERROR_NO_PERMISSION = 1
AnimalBuyEvent.BUY_ERROR_NOT_ENOUGH_MONEY = 2
AnimalBuyEvent.BUY_ERROR_NOT_ENOUGH_SPACE = 3
AnimalBuyEvent.BUY_ERROR_ANIMAL_NOT_SUPPORTED = 4
AnimalBuyEvent.BUY_ERROR_ANIMAL_GLOBAL_LIMIT_REACHED = 5
AnimalBuyEvent.BUY_ERROR_OBJECT_DOES_NOT_EXIST = 6
AnimalBuyEvent.BUY_ERROR_NO_BARN_AVAILABLE = 7
local AnimalBuyEvent_mt = Class(AnimalBuyEvent, Event)
InitStaticEventClass(AnimalBuyEvent, "AnimalBuyEvent")
function AnimalBuyEvent.emptyNew()
	-- upvalues: (copy) AnimalBuyEvent_mt
	return Event.new(AnimalBuyEvent_mt)
end

-- Local values: self
function AnimalBuyEvent.new(object, subTypeIndex, age, numAnimals, buyPrice, feePrice)
	local v8_ = AnimalBuyEvent.emptyNew()
	v8_.object = object
	v8_.subTypeIndex = subTypeIndex
	v8_.age = age
	v8_.numAnimals = numAnimals
	v8_.buyPrice = buyPrice
	v8_.feePrice = feePrice
	return v8_
end

-- Local values: self
function AnimalBuyEvent.newServerToClient(errorCode)
	local v10_ = AnimalBuyEvent.emptyNew()
	v10_.errorCode = errorCode
	return v10_
end

function AnimalBuyEvent:readStream(streamId, connection)
	if connection:getIsServer() then
		self.errorCode = streamReadUIntN(streamId, 3)
	else
		self.object = NetworkUtil.readNodeObject(streamId)
		self.subTypeIndex = streamReadUIntN(streamId, AnimalCluster.NUM_BITS_SUB_TYPE)
		self.age = streamReadUIntN(streamId, AnimalCluster.NUM_BITS_AGE)
		self.numAnimals = streamReadUInt8(streamId)
		self.buyPrice = -streamReadInt32(streamId)
		self.feePrice = -streamReadInt32(streamId)
	end
	self:run(connection)
end

function AnimalBuyEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.object)
		streamWriteUIntN(streamId, self.subTypeIndex, AnimalCluster.NUM_BITS_SUB_TYPE)
		streamWriteUIntN(streamId, self.age, AnimalCluster.NUM_BITS_AGE)
		streamWriteUInt8(streamId, self.numAnimals)
		local v17_ = streamWriteInt32
		local v18_ = self.buyPrice
		v17_(streamId, (math.abs(v18_)))
		local v19_ = streamWriteInt32
		local v20_ = self.feePrice
		v19_(streamId, (math.abs(v20_)))
	else
		streamWriteUIntN(streamId, self.errorCode, 3)
	end
end

-- Local values: uniqueUserId, farm, farmId, errorCode, price
function AnimalBuyEvent:run(connection)
	if connection:getIsServer() then
		g_messageCenter:publish(AnimalBuyEvent, self.errorCode)
		return
	elseif g_currentMission:getHasPlayerPermission("tradeAnimals", connection) then
		local v23_ = g_currentMission.userManager:getUniqueUserIdByConnection(connection)
		local v24_ = g_farmManager:getFarmForUniqueUserId(v23_)
		local v25_ = v24_.farmId
		local v26_ = AnimalBuyEvent.validate(self.object, self.subTypeIndex, self.age, self.numAnimals, self.buyPrice, self.feePrice, v25_)
		if v26_ == nil then
			self.object:addAnimals(self.subTypeIndex, self.numAnimals, self.age)
			local v27_ = self.buyPrice + self.feePrice
			g_currentMission:addMoney(v27_, v24_.farmId, MoneyType.NEW_ANIMALS_COST, true, true)
			connection:sendEvent(AnimalBuyEvent.newServerToClient(AnimalBuyEvent.BUY_SUCCESS))
		else
			connection:sendEvent(AnimalBuyEvent.newServerToClient(v26_))
		end
	else
		connection:sendEvent(AnimalBuyEvent.newServerToClient(AnimalBuyEvent.BUY_ERROR_NO_PERMISSION))
		return
	end
end

-- Local values: animalTypeIndex, placeables, price
function AnimalBuyEvent.validate(object, subTypeIndex, age, numAnimals, buyPrice, feePrice, farmId)
	if object == nil then
		return AnimalBuyEvent.BUY_ERROR_OBJECT_DOES_NOT_EXIST
	elseif object:getSupportsAnimalSubType(subTypeIndex) then
		if object:getNumOfFreeAnimalSlots(subTypeIndex) < numAnimals then
			return AnimalBuyEvent.BUY_ERROR_NOT_ENOUGH_SPACE
		else
			local v34_ = g_currentMission.animalSystem:getTypeIndexBySubTypeIndex(subTypeIndex)
			if #g_currentMission.husbandrySystem:getPlaceablesByFarm(farmId, v34_) == 0 then
				return AnimalBuyEvent.BUY_ERROR_NO_BARN_AVAILABLE
			elseif g_currentMission.husbandrySystem:getNumOfFreeAnimalSlots(farmId, subTypeIndex) < numAnimals then
				return AnimalBuyEvent.BUY_ERROR_ANIMAL_GLOBAL_LIMIT_REACHED
			else
				local v35_ = buyPrice + feePrice
				if g_currentMission:getMoney(farmId) + v35_ < 0 then
					return AnimalBuyEvent.BUY_ERROR_NOT_ENOUGH_MONEY
				else
					return nil
				end
			end
		end
	else
		return AnimalBuyEvent.BUY_ERROR_ANIMAL_NOT_SUPPORTED
	end
end
