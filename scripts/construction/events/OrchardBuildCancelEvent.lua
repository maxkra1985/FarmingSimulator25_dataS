OrchardBuildCancelEvent = {}
local OrchardBuildCancelEvent_mt = Class(OrchardBuildCancelEvent, Event)
InitStaticEventClass(OrchardBuildCancelEvent, "OrchardBuildCancelEvent")
function OrchardBuildCancelEvent.emptyNew()
	local self = Event.new(OrchardBuildCancelEvent_mt, NetworkNode.CHANNEL_MAIN)
	return self
end
function OrchardBuildCancelEvent.new(requestId)
	local self = OrchardBuildCancelEvent.emptyNew()
	self.requestId = requestId
	return self
end
function OrchardBuildCancelEvent:readStream(streamId, connection)
	self.requestId = streamReadUInt8(streamId)
	self:run(connection)
end
function OrchardBuildCancelEvent:writeStream(streamId, connection)
	streamWriteUInt8(streamId, self.requestId)
end
function OrchardBuildCancelEvent:run(connection)
	if connection:getIsServer() then
		return
	end
	local manager = g_currentMission.orchardBuildManager
	if manager == nil then
		return
	else
		manager:cancelRequest(connection, self.requestId)
	end
end
