-- Local values: AnimalHusbandryNoMorePalletSpaceEvent_mt
AnimalHusbandryNoMorePalletSpaceEvent = {}
local AnimalHusbandryNoMorePalletSpaceEvent_mt = Class(AnimalHusbandryNoMorePalletSpaceEvent, Event)
InitStaticEventClass(AnimalHusbandryNoMorePalletSpaceEvent, "AnimalHusbandryNoMorePalletSpaceEvent")
function AnimalHusbandryNoMorePalletSpaceEvent.emptyNew()
	-- upvalues: (copy) AnimalHusbandryNoMorePalletSpaceEvent_mt
	return Event.new(AnimalHusbandryNoMorePalletSpaceEvent_mt)
end

-- Local values: self
function AnimalHusbandryNoMorePalletSpaceEvent.new(animalHusbandry, fillTypeIndex)
	local v4_ = AnimalHusbandryNoMorePalletSpaceEvent.emptyNew()
	v4_.animalHusbandry = animalHusbandry
	v4_.fillTypeIndex = fillTypeIndex
	return v4_
end

function AnimalHusbandryNoMorePalletSpaceEvent:readStream(streamId, connection)
	self.animalHusbandry = NetworkUtil.readNodeObject(streamId)
	self.fillTypeIndex = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
	self:run(connection)
end

function AnimalHusbandryNoMorePalletSpaceEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.animalHusbandry)
	streamWriteUIntN(streamId, self.fillTypeIndex, FillTypeManager.SEND_NUM_BITS)
end

function AnimalHusbandryNoMorePalletSpaceEvent:run(connection)
	if connection:getIsServer() and self.animalHusbandry ~= nil then
		self.animalHusbandry:showPalletBlockedWarning(self.fillTypeIndex)
	end
end
