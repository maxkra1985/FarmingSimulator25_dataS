-- Local values: PalletFillerBuyPalletEvent_mt
PalletFillerBuyPalletEvent = {}
local PalletFillerBuyPalletEvent_mt = Class(PalletFillerBuyPalletEvent, Event)
InitStaticEventClass(PalletFillerBuyPalletEvent, "PalletFillerBuyPalletEvent")
function PalletFillerBuyPalletEvent.emptyNew()
	-- upvalues: (copy) PalletFillerBuyPalletEvent_mt
	return Event.new(PalletFillerBuyPalletEvent_mt)
end

-- Local values: self
function PalletFillerBuyPalletEvent.new(object)
	local v3_ = PalletFillerBuyPalletEvent.emptyNew()
	v3_.object = object
	return v3_
end

function PalletFillerBuyPalletEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end

function PalletFillerBuyPalletEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
end

-- Local values: vehicleBuyData
function PalletFillerBuyPalletEvent:run(connection)
	if connection:getIsServer() then
		if self.object ~= nil and self.object:getIsSynchronized() then
			self.object:buyPalletFillerPallets(true)
		end
	else
		g_server:broadcastEvent(self, false, connection, self.object)
		if self.object ~= nil and self.object:getIsSynchronized() then
			if g_currentMission.slotSystem:getCanAddLimitedObjects(SlotSystem.LIMITED_OBJECT_PALLET, 1) then
				self.object:buyPalletFillerPallets(true)
			else
				local v11_ = BuyVehicleData.new()
				v11_:setStoreItem(self.object.spec_palletFiller.pallet.storeItem)
				connection:sendEvent(BuyVehicleEvent.newServerToClient(BuyVehicleEvent.STATE_TOO_MANY_PALLETS, v11_))
			end
		end
	end
end
