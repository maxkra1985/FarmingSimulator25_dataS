PlaceablePalletBuyEvent = {}
local PlaceablePalletBuyEvent_mt = Class(PlaceablePalletBuyEvent, Event)
InitStaticEventClass(PlaceablePalletBuyEvent, "PlaceablePalletBuyEvent")
function PlaceablePalletBuyEvent.emptyNew()
	local self = Event.new(PlaceablePalletBuyEvent_mt)
	return self
end
function PlaceablePalletBuyEvent.new(placeable, farmId, fillTypeIndex, quantity, palletPrice)
	local self = PlaceablePalletBuyEvent.emptyNew()
	assert(quantity < 16)
	self.placeable = placeable
	self.farmId = farmId
	self.fillTypeIndex = fillTypeIndex
	self.quantity = quantity
	self.palletPrice = palletPrice
	return self
end
function PlaceablePalletBuyEvent.newServerToClient(errorCode, numBoughPallets)
	local self = PlaceablePalletBuyEvent.emptyNew()
	self.numBoughPallets = numBoughPallets
	self.errorCode = errorCode
	return self
end
function PlaceablePalletBuyEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.placeable = NetworkUtil.readNodeObject(streamId)
		self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
		self.fillTypeIndex = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
		self.quantity = streamReadUIntN(streamId, 4)
		self.palletPrice = streamReadUInt16(streamId)
	else
		self.errorCode = streamReadUIntN(streamId, 3)
		self.numBoughPallets = streamReadUIntN(streamId, 4)
	end
	self:run(connection)
end
function PlaceablePalletBuyEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.placeable)
		streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
		streamWriteUIntN(streamId, self.fillTypeIndex, FillTypeManager.SEND_NUM_BITS)
		streamWriteUIntN(streamId, self.quantity, 4)
		streamWriteUInt16(streamId, self.palletPrice)
	else
		streamWriteUIntN(streamId, self.errorCode, 3)
		streamWriteUIntN(streamId, self.numBoughPallets, 4)
	end
end
function PlaceablePalletBuyEvent:run(connection)
	if connection:getIsServer() then
		g_messageCenter:publish(PlaceablePalletBuyEvent, self.errorCode, self.numBoughPallets)
	else
		if self.placeable ~= nil then
			self.placeable:tryToSpawnPallets(self.farmId, self.fillTypeIndex, self.quantity, function(errorCode, numBoughtPallets)
				if 0 < numBoughtPallets then
					local price = self.palletPrice * numBoughtPallets
					g_currentMission:addMoney(-price, self.farmId, MoneyType.PURCHASE_PALLETS, true, true)
				end
				connection:sendEvent(PlaceablePalletBuyEvent.newServerToClient(errorCode, numBoughtPallets))
			end)
		end
	end
end
