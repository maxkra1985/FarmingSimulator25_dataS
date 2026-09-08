-- Local values: FootballFieldResetEvent_mt
FootballFieldResetEvent = {}
local FootballFieldResetEvent_mt = Class(FootballFieldResetEvent, Event)
InitStaticEventClass(FootballFieldResetEvent, "FootballFieldResetEvent")
function FootballFieldResetEvent.emptyNew()
	-- upvalues: (copy) FootballFieldResetEvent_mt
	return Event.new(FootballFieldResetEvent_mt)
end

-- Local values: self
function FootballFieldResetEvent.new(footballField)
	local v3_ = FootballFieldResetEvent.emptyNew()
	v3_.footballField = footballField
	return v3_
end

function FootballFieldResetEvent:readStream(streamId, connection)
	local v6_ = g_currentMission
	assert(v6_:getIsServer())
	self.footballField = NetworkUtil.readNodeObject(streamId)
	self.footballField:reset()
end

function FootballFieldResetEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.footballField)
end

function FootballFieldResetEvent:run(connection)
	Logging.error("FootballFieldResetEvent is a client to server only event")
end
