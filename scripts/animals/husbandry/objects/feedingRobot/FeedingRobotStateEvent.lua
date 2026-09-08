-- Local values: FeedingRobotStateEvent_mt
FeedingRobotStateEvent = {}
local FeedingRobotStateEvent_mt = Class(FeedingRobotStateEvent, Event)
InitStaticEventClass(FeedingRobotStateEvent, "FeedingRobotStateEvent")
function FeedingRobotStateEvent.emptyNew()
	-- upvalues: (copy) FeedingRobotStateEvent_mt
	return Event.new(FeedingRobotStateEvent_mt)
end

-- Local values: self
function FeedingRobotStateEvent.new(feedingRobot, state)
	local v4_ = FeedingRobotStateEvent.emptyNew()
	v4_.feedingRobot = feedingRobot
	v4_.state = state
	return v4_
end

function FeedingRobotStateEvent:readStream(streamId, connection)
	self.feedingRobot = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadUInt8(streamId)
	self:run(connection)
end

function FeedingRobotStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.feedingRobot)
	streamWriteUInt8(streamId, self.state)
end

function FeedingRobotStateEvent:run(connection)
	if self.feedingRobot ~= nil then
		self.feedingRobot:setState(self.state)
	end
end
