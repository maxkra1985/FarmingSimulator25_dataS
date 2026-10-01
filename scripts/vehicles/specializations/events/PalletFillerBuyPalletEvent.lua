PalletFillerBuyPalletEvent = {}
local PalletFillerBuyPalletEvent_mt = Class(PalletFillerBuyPalletEvent, Event)
InitStaticEventClass(PalletFillerBuyPalletEvent, "PalletFillerBuyPalletEvent")
function PalletFillerBuyPalletEvent.emptyNew()
	local self = Event.new(PalletFillerBuyPalletEvent_mt)
	return self
end
function PalletFillerBuyPalletEvent.new(object)
	local self = PalletFillerBuyPalletEvent.emptyNew()
	self.object = object
	return self
end
function PalletFillerBuyPalletEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end
function PalletFillerBuyPalletEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
end
function PalletFillerBuyPalletEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
		if self.object ~= nil and self.object:getIsSynchronized() then
			if g_currentMission.slotSystem:getCanAddLimitedObjects(SlotSystem.LIMITED_OBJECT_PALLET, 1) then
				self.object:buyPalletFillerPallets(true)
			else
				local vehicleBuyData = BuyVehicleData.new()
				vehicleBuyData:setStoreItem(self.object.spec_palletFiller.pallet.storeItem)
				connection:sendEvent(BuyVehicleEvent.newServerToClient(BuyVehicleEvent.STATE_TOO_MANY_PALLETS, vehicleBuyData))
			end
		end
	elseif self.object ~= nil then
		if self.object:getIsSynchronized() then
			self.object:buyPalletFillerPallets(true)
		end
	end
end
