-- Local values: ExtendedSprayerDefaultFruitTypeEvent_mt
ExtendedSprayerDefaultFruitTypeEvent = {}
local ExtendedSprayerDefaultFruitTypeEvent_mt = Class(ExtendedSprayerDefaultFruitTypeEvent, Event)
InitEventClass(ExtendedSprayerDefaultFruitTypeEvent, "ExtendedSprayerDefaultFruitTypeEvent")
function ExtendedSprayerDefaultFruitTypeEvent.emptyNew()
	-- upvalues: (copy) ExtendedSprayerDefaultFruitTypeEvent_mt
	return Event.new(ExtendedSprayerDefaultFruitTypeEvent_mt)
end

-- Local values: self
function ExtendedSprayerDefaultFruitTypeEvent.new(object, fruitRequirementIndex)
	local v4_ = ExtendedSprayerDefaultFruitTypeEvent.emptyNew()
	v4_.object = object
	v4_.fruitRequirementIndex = fruitRequirementIndex
	return v4_
end

function ExtendedSprayerDefaultFruitTypeEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.fruitRequirementIndex = streamReadUIntN(streamId, FruitTypeManager.SEND_NUM_BITS)
	self:run(connection)
end

function ExtendedSprayerDefaultFruitTypeEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteUIntN(streamId, self.fruitRequirementIndex, FruitTypeManager.SEND_NUM_BITS)
end

function ExtendedSprayerDefaultFruitTypeEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setSprayAmountDefaultFruitRequirementIndex(self.fruitRequirementIndex, true)
	end
end

function ExtendedSprayerDefaultFruitTypeEvent.sendEvent(object, fruitRequirementIndex, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(ExtendedSprayerDefaultFruitTypeEvent.new(object, fruitRequirementIndex), nil, nil, object)
			return
		end
		g_client:getServerConnection():sendEvent(ExtendedSprayerDefaultFruitTypeEvent.new(object, fruitRequirementIndex))
	end
end
