OrchardBuildFinishedEvent = {}
local OrchardBuildFinishedEvent_mt = Class(OrchardBuildFinishedEvent, Event)
InitStaticEventClass(OrchardBuildFinishedEvent, "OrchardBuildFinishedEvent")
OrchardBuildFinishedEvent.STATUS = { SUCCESS = 0, CANCELLED = 1, NO_PERMISSION = 2, NOT_ENOUGH_MONEY = 3, LAND_UNOWNED = 4, INVALID_REQUEST = 5, EXTRA_CONTENT_FAILED = 6, BUSY = 7, BUILD_RESTRICTED = 8, OVERLAP = 9 }
OrchardBuildFinishedEvent.STATUS_NUM_BITS = 4
function OrchardBuildFinishedEvent.emptyNew()
	local self = Event.new(OrchardBuildFinishedEvent_mt, NetworkNode.CHANNEL_MAIN)
	return self
end
function OrchardBuildFinishedEvent.new(requestId, statusCode, builtSteps)
	local self = OrchardBuildFinishedEvent.emptyNew()
	self.requestId = requestId
	self.statusCode = statusCode
	self.builtSteps = builtSteps
	return self
end
function OrchardBuildFinishedEvent:readStream(streamId, connection)
	self.requestId = streamReadUInt8(streamId)
	self.statusCode = streamReadUIntN(streamId, OrchardBuildFinishedEvent.STATUS_NUM_BITS)
	self.builtSteps = streamReadUInt16(streamId)
	self:run(connection)
end
function OrchardBuildFinishedEvent:writeStream(streamId, connection)
	streamWriteUInt8(streamId, self.requestId)
	streamWriteUIntN(streamId, self.statusCode, OrchardBuildFinishedEvent.STATUS_NUM_BITS)
	streamWriteUInt16(streamId, self.builtSteps)
end
function OrchardBuildFinishedEvent:run(connection)
	g_messageCenter:publish(OrchardBuildFinishedEvent, self.requestId, self.statusCode, self.builtSteps)
end
