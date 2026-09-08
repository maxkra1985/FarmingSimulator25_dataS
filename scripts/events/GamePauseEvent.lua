-- Local values: GamePauseEvent_mt
GamePauseEvent = {}
local GamePauseEvent_mt = Class(GamePauseEvent, Event)
InitStaticEventClass(GamePauseEvent, "GamePauseEvent")
function GamePauseEvent.emptyNew()
	-- upvalues: (copy) GamePauseEvent_mt
	return Event.new(GamePauseEvent_mt)
end

-- Local values: self
function GamePauseEvent.new(pause, manualPaused, isSynchronizing)
	local v5_ = GamePauseEvent.emptyNew()
	v5_.pause = pause
	v5_.manualPaused = manualPaused
	v5_.isSynchronizing = isSynchronizing
	return v5_
end

function GamePauseEvent:readStream(streamId, connection)
	self.pause = streamReadBool(streamId)
	self.manualPaused = streamReadBool(streamId)
	self.isSynchronizing = streamReadBool(streamId)
	self:run(connection)
end

function GamePauseEvent:writeStream(streamId, connection)
	streamWriteBool(streamId, self.pause)
	streamWriteBool(streamId, self.manualPaused)
	streamWriteBool(streamId, self.isSynchronizing)
end

function GamePauseEvent:run(connection)
	g_currentMission.manualPaused = self.manualPaused
	g_currentMission.isSynchronizingWithPlayers = self.isSynchronizing
	if self.pause then
		g_currentMission:pauseGame()
	else
		g_currentMission:doUnpauseGame()
	end
end
function GamePauseEvent.sendEvent()
	if g_currentMission:getIsServer() then
		g_server:broadcastEvent(GamePauseEvent.new(g_currentMission.paused, g_currentMission.manualPaused, g_currentMission.isSynchronizingWithPlayers), false)
	end
end
