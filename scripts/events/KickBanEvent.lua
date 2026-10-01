KickBanEvent = {}
local KickBanEvent_mt = Class(KickBanEvent, Event)
InitStaticEventClass(KickBanEvent, "KickBanEvent")
function KickBanEvent.emptyNew()
	local self = Event.new(KickBanEvent_mt)
	return self
end
function KickBanEvent.new(doKick, userId)
	local self = KickBanEvent.emptyNew()
	self.doKick = doKick
	self.userId = userId
	return self
end
function KickBanEvent:readStream(streamId, connection)
	assert(g_currentMission:getIsServer(), "KickBanEvent is a client to server only event")
	self.doKick = streamReadBool(streamId)
	self.userId = User.streamReadUserId(streamId)
	self:run(connection)
end
function KickBanEvent:writeStream(streamId, connection)
	streamWriteBool(streamId, self.doKick)
	User.streamWriteUserId(streamId, self.userId)
end
function KickBanEvent:run(connection)
	if not connection:getIsServer() then
		if self.userId == g_currentMission:getServerUserId() then
			print("The server cannot be kicked or banned")
			return
		elseif not g_currentMission.userManager:getIsConnectionMasterUser(connection) then
			print("Connection is not a master user")
			return
		else
			local user = g_currentMission.userManager:getUserByUserId(self.userId)
			if user ~= nil then
				if self.doKick then
					g_currentMission:kickUser(user)
					return
				else
					g_currentMission:banUser(user)
					return
				end
			end
			print("User(" .. tostring(self.userId) .. ") not found")
			return
		end
	end
	printError("Error: KickBanEvent is a client to server only event")
end
