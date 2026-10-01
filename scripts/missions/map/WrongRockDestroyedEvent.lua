WrongRockDestroyedEvent = {}
local WrongRockDestroyedEvent_mt = Class(WrongRockDestroyedEvent, Event)
InitStaticEventClass(WrongRockDestroyedEvent, "WrongRockDestroyedEvent")
function WrongRockDestroyedEvent.emptyNew()
	local self = Event.new(WrongRockDestroyedEvent_mt)
	return self
end
function WrongRockDestroyedEvent.new()
	local self = WrongRockDestroyedEvent.emptyNew()
	return self
end
function WrongRockDestroyedEvent:readStream(streamId, connection)
	self:run(connection)
end
function WrongRockDestroyedEvent:writeStream(streamId, connection) end
function WrongRockDestroyedEvent:run(connection)
	g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, g_i18n:getText("ingameNotification_wrongMissionRockDestroyed"))
end
