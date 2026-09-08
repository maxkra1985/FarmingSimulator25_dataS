-- Local values: ConnectionRequestEvent_mt
ConnectionRequestEvent = {}
local ConnectionRequestEvent_mt = Class(ConnectionRequestEvent, Event)
InitStaticEventClass(ConnectionRequestEvent, "ConnectionRequestEvent")
function ConnectionRequestEvent.emptyNew()
	-- upvalues: (copy) ConnectionRequestEvent_mt
	return Event.new(ConnectionRequestEvent_mt)
end

-- Local values: self
function ConnectionRequestEvent.new(language, password, uniqueUserId, platformUserId, platformId, playerName, platformSessionId)
	local v9_ = ConnectionRequestEvent.emptyNew()
	v9_.language = language
	v9_.password = password
	v9_.uniqueUserId = uniqueUserId
	v9_.platformUserId = platformUserId
	v9_.platformId = platformId
	v9_.playerName = playerName
	v9_.platformSessionId = platformSessionId
	return v9_
end

function ConnectionRequestEvent:readStream(streamId, connection)
	self.language = streamReadUInt8(streamId)
	self.password = streamReadString(streamId)
	self.uniqueUserId = streamReadString(streamId)
	self.platformUserId = streamReadString(streamId)
	self.platformId = streamReadUInt8(streamId)
	self.playerName = streamReadString(streamId)
	self.platformSessionId = streamReadString(streamId)
	self:run(connection)
end

function ConnectionRequestEvent:writeStream(streamId, connection)
	streamWriteUInt8(streamId, self.language)
	streamWriteString(streamId, self.password)
	streamWriteString(streamId, self.uniqueUserId)
	streamWriteString(streamId, self.platformUserId)
	streamWriteUInt8(streamId, self.platformId)
	streamWriteString(streamId, self.playerName)
	streamWriteString(streamId, self.platformSessionId)
end

function ConnectionRequestEvent:run(connection)
	g_currentMission:onConnectionRequest(connection, self.language, self.password, self.uniqueUserId, self.platformUserId, self.platformId, self.playerName, self.platformSessionId)
end
