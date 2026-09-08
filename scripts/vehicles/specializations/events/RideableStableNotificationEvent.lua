-- Local values: RideableStableNotificationEvent_mt
RideableStableNotificationEvent = {}
local RideableStableNotificationEvent_mt = Class(RideableStableNotificationEvent, Event)
InitStaticEventClass(RideableStableNotificationEvent, "RideableStableNotificationEvent")
function RideableStableNotificationEvent.emptyNew()
	-- upvalues: (copy) RideableStableNotificationEvent_mt
	return Event.new(RideableStableNotificationEvent_mt)
end

-- Local values: self
function RideableStableNotificationEvent.new(isInStable, name)
	local v4_ = RideableStableNotificationEvent.emptyNew()
	v4_.isInStable = isInStable
	v4_.name = name
	return v4_
end

function RideableStableNotificationEvent:readStream(streamId, connection)
	self.isInStable = streamReadBool(streamId)
	self.name = streamReadString(streamId)
	self:run(connection)
end

function RideableStableNotificationEvent:writeStream(streamId, connection)
	streamWriteBool(streamId, self.isInStable)
	streamWriteString(streamId, self.name)
end

function RideableStableNotificationEvent:run(connection)
	if self.isInStable then
		g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format(g_i18n:getText("ingameNotification_horseInStable"), self.name))
	else
		g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("ingameNotification_horseNotInStable"), self.name))
	end
end
