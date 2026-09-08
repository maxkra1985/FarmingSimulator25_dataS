-- Local values: FootballFieldGoalEvent_mt
FootballFieldGoalEvent = {}
local FootballFieldGoalEvent_mt = Class(FootballFieldGoalEvent, Event)
InitStaticEventClass(FootballFieldGoalEvent, "FootballFieldGoalEvent")
function FootballFieldGoalEvent.emptyNew()
	-- upvalues: (copy) FootballFieldGoalEvent_mt
	return Event.new(FootballFieldGoalEvent_mt)
end

-- Local values: self
function FootballFieldGoalEvent.new(footballField, isBlueGoal, scoreBlue, scoreRed)
	local v6_ = FootballFieldGoalEvent.emptyNew()
	local v7_ = scoreBlue > 99 and 0 or scoreBlue
	local v8_ = scoreRed > 99 and 0 or scoreRed
	v6_.footballField = footballField
	v6_.isBlueGoal = isBlueGoal
	v6_.scoreBlue = v7_
	v6_.scoreRed = v8_
	return v6_
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
