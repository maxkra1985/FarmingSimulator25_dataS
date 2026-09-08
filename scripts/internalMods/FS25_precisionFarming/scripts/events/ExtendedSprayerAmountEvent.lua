-- Local values: ExtendedSprayerAmountEvent_mt
ExtendedSprayerAmountEvent = {}
local ExtendedSprayerAmountEvent_mt = Class(ExtendedSprayerAmountEvent, Event)
InitEventClass(ExtendedSprayerAmountEvent, "ExtendedSprayerAmountEvent")
function ExtendedSprayerAmountEvent.emptyNew()
	-- upvalues: (copy) ExtendedSprayerAmountEvent_mt
	return Event.new(ExtendedSprayerAmountEvent_mt)
end

-- Local values: self
function ExtendedSprayerAmountEvent.new(object, automaticMode, manualValue)
	local v5_ = ExtendedSprayerAmountEvent.emptyNew()
	v5_.object = object
	v5_.automaticMode = automaticMode
	v5_.manualValue = manualValue
	return v5_
end

function ExtendedSprayerAmountEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.automaticMode = streamReadBool(streamId)
	if not self.automaticMode then
		self.manualValue = streamReadUIntN(streamId, NitrogenMap.NUM_BITS)
	end
	self:run(connection)
end

function ExtendedSprayerAmountEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	if not streamWriteBool(streamId, self.automaticMode) then
		streamWriteUIntN(streamId, self.manualValue, NitrogenMap.NUM_BITS)
	end
end

function ExtendedSprayerAmountEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setSprayAmountAutoMode(self.automaticMode, true)
		if not self.automaticMode then
			self.object:setSprayAmountManualValue(self.manualValue, true)
		end
	end
end

function ExtendedSprayerAmountEvent.sendEvent(object, automaticMode, manualValue, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(ExtendedSprayerAmountEvent.new(object, automaticMode, manualValue), nil, nil, object)
			return
		end
		g_client:getServerConnection():sendEvent(ExtendedSprayerAmountEvent.new(object, automaticMode, manualValue))
	end
end
