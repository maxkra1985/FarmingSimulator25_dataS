-- Local values: PlaceablePalletBuyEvent_mt
PlaceablePalletBuyEvent = {}
local PlaceablePalletBuyEvent_mt = Class(PlaceablePalletBuyEvent, Event)
InitStaticEventClass(PlaceablePalletBuyEvent, "PlaceablePalletBuyEvent")
function PlaceablePalletBuyEvent.emptyNew()
	-- upvalues: (copy) PlaceablePalletBuyEvent_mt
	return Event.new(PlaceablePalletBuyEvent_mt)
end

-- Local values: self
function PlaceablePalletBuyEvent.new(placeable, farmId, fillTypeIndex, quantity, palletPrice)
	local v7_ = PlaceablePalletBuyEvent.emptyNew()
	local v8_ = quantity < 16
	assert(v8_)
	v7_.placeable = placeable
	v7_.farmId = farmId
	v7_.fillTypeIndex = fillTypeIndex
	v7_.quantity = quantity
	v7_.palletPrice = palletPrice
	return v7_
end

-- Local values: self
function PlaceablePalletBuyEvent.newServerToClient(errorCode, numBoughPallets)
	local v11_ = PlaceablePalletBuyEvent.emptyNew()
	v11_.numBoughPallets = numBoughPallets
	v11_.errorCode = errorCode
	return v11_
end

function PlaceablePalletBuyEvent:readStream(streamId, connection)
	if connection:getIsServer() then
		self.errorCode = streamReadUIntN(streamId, 3)
		self.numBoughPallets = streamReadUIntN(streamId, 4)
	else
		self.placeable = NetworkUtil.readNodeObject(streamId)
		self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
		self.fillTypeIndex = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
		self.quantity = streamReadUIntN(streamId, 4)
		self.palletPrice = streamReadUInt16(streamId)
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
	elseif self.placeable ~= nil then
		self.placeable:tryToSpawnPallets(self.farmId, self.fillTypeIndex, self.quantity, function(p20_, p21_)
			-- upvalues: (copy) self, (copy) connection
			if p21_ > 0 then
				local v22_ = self.palletPrice * p21_
				g_currentMission:addMoney(-v22_, self.farmId, MoneyType.PURCHASE_PALLETS, true, true)
			end
			connection:sendEvent(PlaceablePalletBuyEvent.newServerToClient(p20_, p21_))
		end)
	end
end
