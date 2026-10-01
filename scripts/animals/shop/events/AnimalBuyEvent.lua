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
	local self = Event.new(AnimalBuyEvent_mt)
	return self
end
function AnimalBuyEvent.new(object, subTypeIndex, age, numAnimals, buyPrice, feePrice)
	local self = AnimalBuyEvent.emptyNew()
	self.object = object
	self.subTypeIndex = subTypeIndex
	self.age = age
	self.numAnimals = numAnimals
	self.buyPrice = buyPrice
	self.feePrice = feePrice
	return self
end
function AnimalBuyEvent.newServerToClient(errorCode)
	local self = AnimalBuyEvent.emptyNew()
	self.errorCode = errorCode
	return self
end
function AnimalBuyEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.object = NetworkUtil.readNodeObject(streamId)
		self.subTypeIndex = streamReadUIntN(streamId, AnimalCluster.NUM_BITS_SUB_TYPE)
		self.age = streamReadUIntN(streamId, AnimalCluster.NUM_BITS_AGE)
		self.numAnimals = streamReadUInt8(streamId)
		self.buyPrice = -streamReadInt32(streamId)
		self.feePrice = -streamReadInt32(streamId)
	else
		self.errorCode = streamReadUIntN(streamId, 3)
	end
	self:run(connection)
end
function AnimalBuyEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.object)
		streamWriteUIntN(streamId, self.subTypeIndex, AnimalCluster.NUM_BITS_SUB_TYPE)
		streamWriteUIntN(streamId, self.age, AnimalCluster.NUM_BITS_AGE)
		streamWriteUInt8(streamId, self.numAnimals)
		streamWriteInt32(streamId, math.abs(self.buyPrice))
		streamWriteInt32(streamId, math.abs(self.feePrice))
	else
		streamWriteUIntN(streamId, self.errorCode, 3)
	end
end
function AnimalBuyEvent:run(connection)
	if not connection:getIsServer() then
		if not g_currentMission:getHasPlayerPermission("tradeAnimals", connection) then
			connection:sendEvent(AnimalBuyEvent.newServerToClient(AnimalBuyEvent.BUY_ERROR_NO_PERMISSION))
			return
		end
		local uniqueUserId = g_currentMission.userManager:getUniqueUserIdByConnection(connection)
		local farm = g_farmManager:getFarmForUniqueUserId(uniqueUserId)
		local farmId = farm.farmId
		local errorCode = AnimalBuyEvent.validate(self.object, self.subTypeIndex, self.age, self.numAnimals, self.buyPrice, self.feePrice, farmId)
		if errorCode ~= nil then
			connection:sendEvent(AnimalBuyEvent.newServerToClient(errorCode))
			return
		else
			self.object:addAnimals(self.subTypeIndex, self.numAnimals, self.age)
			local price = self.buyPrice + self.feePrice
			g_currentMission:addMoney(price, farm.farmId, MoneyType.NEW_ANIMALS_COST, true, true)
			connection:sendEvent(AnimalBuyEvent.newServerToClient(AnimalBuyEvent.BUY_SUCCESS))
			return
		end
	end
	g_messageCenter:publish(AnimalBuyEvent, self.errorCode)
end
function AnimalBuyEvent.validate(object, subTypeIndex, age, numAnimals, buyPrice, feePrice, farmId)
	if object == nil then
		return AnimalBuyEvent.BUY_ERROR_OBJECT_DOES_NOT_EXIST
	end
	if not object:getSupportsAnimalSubType(subTypeIndex) then
		return AnimalBuyEvent.BUY_ERROR_ANIMAL_NOT_SUPPORTED
	end
	if object:getNumOfFreeAnimalSlots(subTypeIndex) < numAnimals then
		return AnimalBuyEvent.BUY_ERROR_NOT_ENOUGH_SPACE
	end
	local animalTypeIndex = g_currentMission.animalSystem:getTypeIndexBySubTypeIndex(subTypeIndex)
	local placeables = g_currentMission.husbandrySystem:getPlaceablesByFarm(farmId, animalTypeIndex)
	if #placeables == 0 then
		return AnimalBuyEvent.BUY_ERROR_NO_BARN_AVAILABLE
	end
	if g_currentMission.husbandrySystem:getNumOfFreeAnimalSlots(farmId, subTypeIndex) < numAnimals then
		return AnimalBuyEvent.BUY_ERROR_ANIMAL_GLOBAL_LIMIT_REACHED
	end
	local price = buyPrice + feePrice
	if g_currentMission:getMoney(farmId) + price < 0 then
		return AnimalBuyEvent.BUY_ERROR_NOT_ENOUGH_MONEY
	else
		return nil
	end
end
