TreeTransportMissionTreeCutEvent = {}
local TreeTransportMissionTreeCutEvent_mt = Class(TreeTransportMissionTreeCutEvent, Event)
InitStaticEventClass(TreeTransportMissionTreeCutEvent, "TreeTransportMissionTreeCutEvent")
function TreeTransportMissionTreeCutEvent.emptyNew()
	local self = Event.new(TreeTransportMissionTreeCutEvent_mt)
	return self
end
function TreeTransportMissionTreeCutEvent.new()
	local self = TreeTransportMissionTreeCutEvent.emptyNew()
	return self
end
function TreeTransportMissionTreeCutEvent:readStream(streamId, connection)
	self:run(connection)
end
function TreeTransportMissionTreeCutEvent:writeStream(streamId, connection) end
function TreeTransportMissionTreeCutEvent:run(connection)
	g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, g_i18n:getText("ingameNotification_treeTransportCutWarning"))
end
