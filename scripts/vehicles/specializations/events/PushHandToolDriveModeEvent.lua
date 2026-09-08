-- Local values: PushHandToolDriveModeEvent_mt
PushHandToolDriveModeEvent = {}
local PushHandToolDriveModeEvent_mt = Class(PushHandToolDriveModeEvent, Event)
InitStaticEventClass(PushHandToolDriveModeEvent, "PushHandToolDriveModeEvent")
function PushHandToolDriveModeEvent.emptyNew()
	-- upvalues: (copy) PushHandToolDriveModeEvent_mt
	return Event.new(PushHandToolDriveModeEvent_mt)
end

-- Local values: self
function PushHandToolDriveModeEvent.new(object, driveModeState)
	local v4_ = PushHandToolDriveModeEvent.emptyNew()
	v4_.object = object
	v4_.driveModeState = driveModeState
	return v4_
end

function PushHandToolDriveModeEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.driveModeState = streamReadBool(streamId)
	self:run(connection)
end

function PushHandToolDriveModeEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.driveModeState)
end

function PushHandToolDriveModeEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setPushHandToolDriveMode(self.driveModeState, true)
	end
end

function PushHandToolDriveModeEvent.sendEvent(vehicle, driveModeState, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(PushHandToolDriveModeEvent.new(vehicle, driveModeState), nil, nil, vehicle)
			return
		end
		g_client:getServerConnection():sendEvent(PushHandToolDriveModeEvent.new(vehicle, driveModeState))
	end
end
