FootballFieldGoalEvent = {}
local FootballFieldGoalEvent_mt = Class(FootballFieldGoalEvent, Event)
InitStaticEventClass(FootballFieldGoalEvent, "FootballFieldGoalEvent")
function FootballFieldGoalEvent.emptyNew()
	local self = Event.new(FootballFieldGoalEvent_mt)
	return self
end
function FootballFieldGoalEvent.new(footballField, isBlueGoal, scoreBlue, scoreRed)
	local self = FootballFieldGoalEvent.emptyNew()
	if 99 < scoreBlue then
		scoreBlue = 0
	end
	if 99 < scoreRed then
		scoreRed = 0
	end
	self.footballField = footballField
	self.isBlueGoal = isBlueGoal
	self.scoreBlue = scoreBlue
	self.scoreRed = scoreRed
	return self
end
function FootballFieldGoalEvent:readStream(streamId, connection)
	self.footballField = NetworkUtil.readNodeObject(streamId)
	self.isBlueGoal = streamReadBool(streamId)
	self.scoreBlue = streamReadUIntN(streamId, 7)
	self.scoreRed = streamReadUIntN(streamId, 7)
	self:run(connection)
end
function FootballFieldGoalEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.footballField)
	streamWriteBool(streamId, self.isBlueGoal)
	streamWriteUIntN(streamId, self.scoreBlue, 7)
	streamWriteUIntN(streamId, self.scoreRed, 7)
end
function FootballFieldGoalEvent:run(connection)
	if self.footballField ~= nil then
		self.footballField:onGoal(self.isBlueGoal, self.scoreBlue, self.scoreRed)
	end
end
