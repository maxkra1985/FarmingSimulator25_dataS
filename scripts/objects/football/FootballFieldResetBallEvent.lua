FootballFieldResetBallEvent = {}
local FootballFieldResetBallEvent_mt = Class(FootballFieldResetBallEvent, Event)
InitStaticEventClass(FootballFieldResetBallEvent, "FootballFieldResetBallEvent")
function FootballFieldResetBallEvent.emptyNew()
	local self = Event.new(FootballFieldResetBallEvent_mt)
	return self
end
function FootballFieldResetBallEvent.new(footballField)
	local self = FootballFieldResetBallEvent.emptyNew()
	self.footballField = footballField
	return self
end
function FootballFieldResetBallEvent:readStream(streamId, connection)
	self.footballField = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end
function FootballFieldResetBallEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.footballField)
end
function FootballFieldResetBallEvent:run(connection)
	if self.footballField ~= nil then
		self.footballField:onResetBall()
	end
end
