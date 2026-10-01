ClientStartMissionEvent = {}
local ClientStartMissionEvent_mt = Class(ClientStartMissionEvent, Event)
InitStaticEventClass(ClientStartMissionEvent, "ClientStartMissionEvent")
function ClientStartMissionEvent.emptyNew()
	local self = Event.new(ClientStartMissionEvent_mt)
	return self
end
function ClientStartMissionEvent.new(userId)
	local self = ClientStartMissionEvent.emptyNew()
	return self
end
function ClientStartMissionEvent:writeStream(streamId, connection) end
function ClientStartMissionEvent:readStream(streamId, connection)
	self:run(connection)
end
function ClientStartMissionEvent:run(connection)
	assert(not connection:getIsServer(), "ClientStartMissionEvent is a client to server event only!")
	local user = g_currentMission.userManager:getUserByConnection(connection)
	user:setState(FSBaseMission.USER_STATE_INGAME)
	g_messageCenter:publish(MessageType.ON_CLIENT_START_MISSION, user)
end
