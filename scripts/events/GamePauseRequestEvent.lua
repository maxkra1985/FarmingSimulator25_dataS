-- Local values: GamePauseRequestEvent_mt
GamePauseRequestEvent = {}
local GamePauseRequestEvent_mt = Class(GamePauseRequestEvent, Event)
InitStaticEventClass(GamePauseRequestEvent, "GamePauseRequestEvent")
function GamePauseRequestEvent.emptyNew()
	-- upvalues: (copy) GamePauseRequestEvent_mt
	return Event.new(GamePauseRequestEvent_mt)
end

-- Local values: self
function GamePauseRequestEvent.new(pause)
	local v3_ = GamePauseRequestEvent.emptyNew()
	v3_.pause = pause
	return v3_
end

function GamePauseRequestEvent:readStream(streamId, connection)
	self.pause = streamReadBool(streamId)
	self:run(connection)
end

function GamePauseRequestEvent:writeStream(streamId, connection)
	streamWriteBool(streamId, self.pause)
end

function GamePauseRequestEvent:run(connection)
	g_currentMission:setManualPause(self.pause)
end
