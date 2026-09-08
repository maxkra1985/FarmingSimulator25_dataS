-- Local values: BuyObjectEvent_mt
BuyObjectEvent = {}
local BuyObjectEvent_mt = Class(BuyObjectEvent, Event)
BuyObjectEvent.STATE_SUCCESS = 0
BuyObjectEvent.STATE_FAILED_TO_LOAD = 1
BuyObjectEvent.STATE_NO_SPACE = 2
BuyObjectEvent.STATE_LIMIT_REACHED = 3
BuyObjectEvent.STATE_NOT_ENOUGH_MONEY = 4
InitStaticEventClass(BuyObjectEvent, "BuyObjectEvent")
function BuyObjectEvent.emptyNew()
	-- upvalues: (copy) BuyObjectEvent_mt
	return Event.new(BuyObjectEvent_mt)
end

-- Local values: self
function BuyObjectEvent.new(filename, isFreeOfCharge, ownerFarmId)
	local v5_ = BuyObjectEvent.emptyNew()
	v5_.filename = filename
	v5_.isFreeOfCharge = isFreeOfCharge
	v5_.ownerFarmId = ownerFarmId
	return v5_
end

-- Local values: self
function BuyObjectEvent.newServerToClient(errorCode, price)
	local v8_ = BuyObjectEvent.emptyNew()
	v8_.errorCode = errorCode
	v8_.price = price
	return v8_
end

function BuyObjectEvent:readStream(streamId, connection)
	if connection:getIsServer() then
		self.errorCode = streamReadUIntN(streamId, 3)
		self.price = streamReadFloat32(streamId)
	else
		self.filename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
		self.isFreeOfCharge = streamReadBool(streamId)
		self.ownerFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	end
	self:run(connection)
end

function BuyObjectEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.filename))
		streamWriteBool(streamId, self.isFreeOfCharge)
		streamWriteUIntN(streamId, self.ownerFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	else
		streamWriteUIntN(streamId, self.errorCode, 3)
		streamWriteFloat32(streamId, self.price)
	end
end

-- Local values: dataStoreItem, errorCode, price, _, object, hasNoSpace, isLimitReached, financeCategory
function BuyObjectEvent:run(connection)
	if connection:getIsServer() then
		g_messageCenter:publish(BuyObjectEvent, self.errorCode, self.price)
	else
		self.filename = string.lower(self.filename)
		local v17_ = g_storeManager:getItemByXMLFilename(self.filename)
		local v18_ = BuyObjectEvent.STATE_FAILED_TO_LOAD
		local v19_
		if v17_ == nil then
			v19_ = 0
		else
			local v20_
			v19_, v20_ = g_currentMission.economyManager:getBuyPrice(v17_, self.saleItem)
			if v19_ <= g_currentMission:getMoney(self.ownerFarmId) then
				local v21_, v22_, v23_ = g_currentMission:loadObjectAtPlace(v17_.xmlFilename, g_currentMission.storeSpawnPlaces, g_currentMission.usedStorePlaces, MathUtil.degToRad(v17_.rotation), self.ownerFarmId)
				if v21_ == nil then
					if v22_ then
						v18_ = BuyObjectEvent.STATE_NO_SPACE
					elseif v23_ then
						v18_ = BuyObjectEvent.STATE_LIMIT_REACHED
					end
				elseif GS_IS_CONSOLE_VERSION and not fileExists(v17_.xmlFilename) then
					v21_:delete()
				else
					if not self.isFreeOfCharge then
						local v24_ = MoneyType.OTHER
						if v21_.fillType == FillType.TREESAPLINGS or v21_.fillType == FillType.POPLAR then
							v24_ = MoneyType.PURCHASE_SAPLINGS
						elseif v21_.fillType == FillType.FERTILIZER or v21_.fillType == FillType.LIQUIDFERTILIZER then
							v24_ = MoneyType.PURCHASE_FERTILIZER
						elseif v21_.fillType == FillType.SEEDS then
							v24_ = MoneyType.PURCHASE_SEEDS
						end
						g_currentMission:addMoney(-v19_, self.ownerFarmId, v24_)
					end
					v18_ = BuyObjectEvent.STATE_SUCCESS
				end
			else
				v18_ = BuyObjectEvent.STATE_NOT_ENOUGH_MONEY
			end
		end
		connection:sendEvent(BuyObjectEvent.newServerToClient(v18_, v19_))
	end
end
