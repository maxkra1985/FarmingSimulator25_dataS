-- Local values: FootballFieldResetBallEvent_mt
FootballFieldResetBallEvent = {}
local FootballFieldResetBallEvent_mt = Class(FootballFieldResetBallEvent, Event)
InitStaticEventClass(FootballFieldResetBallEvent, "FootballFieldResetBallEvent")
function FootballFieldResetBallEvent.emptyNew()
	-- upvalues: (copy) FootballFieldResetBallEvent_mt
	return Event.new(FootballFieldResetBallEvent_mt)
end

-- Local values: self
function FootballFieldResetBallEvent.new(footballField)
	local v3_ = FootballFieldResetBallEvent.emptyNew()
	v3_.footballField = footballField
	return v3_
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
