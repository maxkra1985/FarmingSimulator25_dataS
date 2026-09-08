-- Local values: GetAdminEvent_mt
GetAdminEvent = {}
local GetAdminEvent_mt = Class(GetAdminEvent, Event)
InitStaticEventClass(GetAdminEvent, "GetAdminEvent")
function GetAdminEvent.emptyNew()
	-- upvalues: (copy) GetAdminEvent_mt
	return Event.new(GetAdminEvent_mt)
end

-- Local values: self
function GetAdminEvent.new(password)
	local v3_ = GetAdminEvent.emptyNew()
	v3_.password = password
	return v3_
end

-- Local values: state
function GetAdminEvent:readStream(streamId, connection)
	local v7_ = g_currentMission
	assert(v7_:getIsServer())
	self.password = streamReadString(streamId)
	if g_currentMission:getIsServer() and not connection:getIsServer() then
		local v8_ = GetAdminAnswerEvent.NOT_SUPPORTED
		if g_dedicatedServer ~= nil then
			if g_dedicatedServer.adminPassword == self.password then
				v8_ = GetAdminAnswerEvent.ACCESS_GRANTED
				g_currentMission.userManager:addMasterUserByConnection(connection)
			else
				v8_ = GetAdminAnswerEvent.ACCESS_DENIED
			end
		end
		connection:sendEvent(GetAdminAnswerEvent.new(v8_))
	end
end

function GetAdminEvent:writeStream(streamId, connection)
	streamWriteString(streamId, self.password)
end

function GetAdminEvent:run(connection)
	printError("Error: GetAdminEvent is a client to server only event")
end
