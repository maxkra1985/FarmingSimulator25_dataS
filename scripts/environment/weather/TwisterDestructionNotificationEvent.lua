TwisterDestructionNotificationEvent = {}
local TwisterDestructionNotificationEvent_mt = Class(TwisterDestructionNotificationEvent, Event)
InitStaticEventClass(TwisterDestructionNotificationEvent, "TwisterDestructionNotificationEvent")
function TwisterDestructionNotificationEvent.emptyNew()
	return Event.new(TwisterDestructionNotificationEvent_mt)
end
function TwisterDestructionNotificationEvent.new()
	local self = TwisterDestructionNotificationEvent.emptyNew()
	return self
end
function TwisterDestructionNotificationEvent:readStream(streamId, connection)
	self:run(connection)
end
function TwisterDestructionNotificationEvent:writeStream(streamId, connection) end
function TwisterDestructionNotificationEvent:run(connection)
	local mission = g_currentMission
	mission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, g_i18n:getText("twister_destroyedNotification"))
end
