DeadwoodMissionWrongTreeEvent = {}
local DeadwoodMissionWrongTreeEvent_mt = Class(DeadwoodMissionWrongTreeEvent, Event)
InitStaticEventClass(DeadwoodMissionWrongTreeEvent, "DeadwoodMissionWrongTreeEvent")
function DeadwoodMissionWrongTreeEvent.emptyNew()
	local self = Event.new(DeadwoodMissionWrongTreeEvent_mt)
	return self
end
function DeadwoodMissionWrongTreeEvent.new()
	local self = DeadwoodMissionWrongTreeEvent.emptyNew()
	return self
end
function DeadwoodMissionWrongTreeEvent:readStream(streamId, connection)
	self:run(connection)
end
function DeadwoodMissionWrongTreeEvent:writeStream(streamId, connection) end
function DeadwoodMissionWrongTreeEvent:run(connection)
	g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, g_i18n:getText("ingameNotification_wrongMissionTreeCutDown"))
end
