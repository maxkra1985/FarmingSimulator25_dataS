-- Local values: KickBanNotificationEvent_mt
KickBanNotificationEvent = {}
local KickBanNotificationEvent_mt = Class(KickBanNotificationEvent, Event)
InitStaticEventClass(KickBanNotificationEvent, "KickBanNotificationEvent")
function KickBanNotificationEvent.emptyNew()
	-- upvalues: (copy) KickBanNotificationEvent_mt
	return Event.new(KickBanNotificationEvent_mt, 1)
end

-- Local values: self
function KickBanNotificationEvent.new(doKick)
	local v3_ = KickBanNotificationEvent.emptyNew()
	v3_.doKick = doKick
	return v3_
end

function KickBanNotificationEvent:readStream(streamId, connection)
	local v6_ = connection:getIsServer()
	assert(v6_, "KickBanNotificationEvent is a server to client only event")
	if connection:getIsServer() then
		if streamReadBool(streamId) then
			g_currentMission:setConnectionLostState(FSBaseMission.CONNECTION_LOST_KICKED)
			return
		end
		g_currentMission:setConnectionLostState(FSBaseMission.CONNECTION_LOST_BANNED)
	end
end

function KickBanNotificationEvent:writeStream(streamId, connection)
	if not connection:getIsServer() then
		streamWriteBool(streamId, self.doKick)
	end
end
