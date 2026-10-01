FootballFieldResetEvent = {}
local FootballFieldResetEvent_mt = Class(FootballFieldResetEvent, Event)
InitStaticEventClass(FootballFieldResetEvent, "FootballFieldResetEvent")
function FootballFieldResetEvent.emptyNew()
	local self = Event.new(FootballFieldResetEvent_mt)
	return self
end
function FootballFieldResetEvent.new(footballField)
	local self = FootballFieldResetEvent.emptyNew()
	self.footballField = footballField
	return self
end
function FootballFieldResetEvent:readStream(streamId, connection)
	assert(g_currentMission:getIsServer())
	self.footballField = NetworkUtil.readNodeObject(streamId)
	self.footballField:reset()
end
function FootballFieldResetEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.footballField)
end
function FootballFieldResetEvent:run(connection)
	Logging.error("FootballFieldResetEvent is a client to server only event")
end
