-- Local values: ClientStartMissionEvent_mt
ClientStartMissionEvent = {}
local ClientStartMissionEvent_mt = Class(ClientStartMissionEvent, Event)
InitStaticEventClass(ClientStartMissionEvent, "ClientStartMissionEvent")
function ClientStartMissionEvent.emptyNew()
	-- upvalues: (copy) ClientStartMissionEvent_mt
	return Event.new(ClientStartMissionEvent_mt)
end

-- Local values: self
function ClientStartMissionEvent.new(userId)
	return ClientStartMissionEvent.emptyNew()
end

function ClientStartMissionEvent:writeStream(streamId, connection) end

function ClientStartMissionEvent:readStream(streamId, connection)
	self:run(connection)
end

-- Local values: user
function ClientStartMissionEvent:run(connection)
	local v5_ = not connection:getIsServer()
	assert(v5_, "ClientStartMissionEvent is a client to server event only!")
	local v6_ = g_currentMission.userManager:getUserByConnection(connection)
	v6_:setState(FSBaseMission.USER_STATE_INGAME)
	g_messageCenter:publish(MessageType.ON_CLIENT_START_MISSION, v6_)
end
