-- Local values: BuyExistingPlaceableEvent_mt
BuyExistingPlaceableEvent = {}
local BuyExistingPlaceableEvent_mt = Class(BuyExistingPlaceableEvent, Event)
BuyExistingPlaceableEvent.STATE_SUCCESS = 0
BuyExistingPlaceableEvent.STATE_NO_PERMISSION = 1
BuyExistingPlaceableEvent.STATE_NOT_ENOUGH_MONEY = 2
BuyExistingPlaceableEvent.STATE_NUM_BITS = 2
local v2_ = BuyExistingPlaceableEvent
local v3_ = {
	[BuyExistingPlaceableEvent.STATE_SUCCESS] = {
		["dialogType"] = DialogElement.TYPE_INFO,
		["text"] = "shop_messageBoughtPlaceable"
	},
	[BuyExistingPlaceableEvent.STATE_NO_PERMISSION] = {
		["dialogType"] = DialogElement.TYPE_WARNING,
		["text"] = "shop_messageNoPermissionGeneral"
	},
	[BuyExistingPlaceableEvent.STATE_NOT_ENOUGH_MONEY] = {
		["dialogType"] = DialogElement.TYPE_WARNING,
		["text"] = "shop_messageNotEnoughMoneyToBuy"
	}
}
v2_.DIALOG_MESSAGES = v3_
InitStaticEventClass(BuyExistingPlaceableEvent, "BuyExistingPlaceableEvent")
function BuyExistingPlaceableEvent.emptyNew()
	-- upvalues: (copy) BuyExistingPlaceableEvent_mt
	return Event.new(BuyExistingPlaceableEvent_mt)
end

-- Local values: self
function BuyExistingPlaceableEvent.new(placeable, ownerFarmId)
	local v6_ = BuyExistingPlaceableEvent.emptyNew()
	v6_.placeable = placeable
	v6_.ownerFarmId = ownerFarmId
	return v6_
end

-- Local values: self
function BuyExistingPlaceableEvent.newServerToClient(statusCode, price)
	local v9_ = BuyExistingPlaceableEvent.emptyNew()
	v9_.statusCode = statusCode
	v9_.price = price
	return v9_
end

function BuyExistingPlaceableEvent:readStream(streamId, connection)
	if connection:getIsServer() then
		self.statusCode = streamReadUIntN(streamId, BuyExistingPlaceableEvent.STATE_NUM_BITS)
		self.price = streamReadInt32(streamId)
	else
		self.placeable = NetworkUtil.readNodeObject(streamId)
		self.ownerFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	end
	self:run(connection)
end

function BuyExistingPlaceableEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.placeable)
		streamWriteUIntN(streamId, self.ownerFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	else
		streamWriteUIntN(streamId, self.statusCode, BuyExistingPlaceableEvent.STATE_NUM_BITS)
		streamWriteInt32(streamId, self.price)
	end
end

-- Local values: statusCode, price, dataStoreItem, farmlandId, farmland
function BuyExistingPlaceableEvent:run(connection)
	if connection:getIsServer() then
		g_messageCenter:publish(BuyExistingPlaceableEvent, self.statusCode, self.price)
	else
		local v18_ = BuyExistingPlaceableEvent.STATE_SUCCESS
		local v19_ = 0
		if g_currentMission:getHasPlayerPermission("buyPlaceable", connection) then
			local v20_ = g_storeManager:getItemByXMLFilename(self.placeable.configFileName)
			if v20_ ~= nil then
				v19_ = g_currentMission.economyManager:getBuyPrice(v20_)
				if self.placeable.buysFarmland then
					local v21_ = self.placeable:getFarmlandId()
					local v22_ = g_farmlandManager:getFarmlandById(v21_)
					if v22_ ~= nil and g_farmlandManager:getFarmlandOwner(v21_) ~= self.ownerFarmId then
						v19_ = v19_ + v22_.price * self.placeable.buysFarmlandPriceScale
					end
				end
				if v19_ <= g_currentMission:getMoney(self.ownerFarmId) then
					g_currentMission:addMoney(-v19_, self.ownerFarmId, MoneyType.SHOP_PROPERTY_BUY, true, true)
					self.placeable:setOwnerFarmId(self.ownerFarmId)
				else
					v18_ = BuyExistingPlaceableEvent.STATE_NOT_ENOUGH_MONEY
				end
			end
		else
			v18_ = BuyExistingPlaceableEvent.STATE_NO_PERMISSION
		end
		connection:sendEvent(BuyExistingPlaceableEvent.newServerToClient(v18_, v19_))
	end
end
