-- Local values: SprayerDoubledAmountEvent_mt
SprayerDoubledAmountEvent = {}
local SprayerDoubledAmountEvent_mt = Class(SprayerDoubledAmountEvent, Event)
InitStaticEventClass(SprayerDoubledAmountEvent, "SprayerDoubledAmountEvent")
function SprayerDoubledAmountEvent.emptyNew()
	-- upvalues: (copy) SprayerDoubledAmountEvent_mt
	return Event.new(SprayerDoubledAmountEvent_mt)
end

-- Local values: self
function SprayerDoubledAmountEvent.new(object, isActive)
	local v4_ = SprayerDoubledAmountEvent.emptyNew()
	v4_.object = object
	v4_.isActive = isActive
	return v4_
end

function SprayerDoubledAmountEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.isActive = streamReadBool(streamId)
	self:run(connection)
end

function SprayerDoubledAmountEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.isActive)
end

function SprayerDoubledAmountEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setSprayerDoubledAmountActive(self.isActive, true)
	end
	if not connection:getIsServer() then
		g_server:broadcastEvent(SprayerDoubledAmountEvent.new(self.object, self.isActive), nil, connection, self.object)
	end
end

function SprayerDoubledAmountEvent.sendEvent(vehicle, isActive, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(SprayerDoubledAmountEvent.new(vehicle, isActive), nil, nil, vehicle)
			return
		end
		g_client:getServerConnection():sendEvent(SprayerDoubledAmountEvent.new(vehicle, isActive))
	end
end
