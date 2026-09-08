-- Local values: KickBanEvent_mt
KickBanEvent = {}
local KickBanEvent_mt = Class(KickBanEvent, Event)
InitStaticEventClass(KickBanEvent, "KickBanEvent")
function KickBanEvent.emptyNew()
	-- upvalues: (copy) KickBanEvent_mt
	return Event.new(KickBanEvent_mt)
end

-- Local values: self
function KickBanEvent.new(doKick, userId)
	local v4_ = KickBanEvent.emptyNew()
	v4_.doKick = doKick
	v4_.userId = userId
	return v4_
end

function KickBanEvent:readStream(streamId, connection)
	local v8_ = g_currentMission:getIsServer()
	assert(v8_, "KickBanEvent is a client to server only event")
	self.doKick = streamReadBool(streamId)
	self.userId = User.streamReadUserId(streamId)
	self:run(connection)
end

function KickBanEvent:writeStream(streamId, connection)
	streamWriteBool(streamId, self.doKick)
	User.streamWriteUserId(streamId, self.userId)
end

-- Local values: user
function KickBanEvent:run(connection)
	if connection:getIsServer() then
		printError("Error: KickBanEvent is a client to server only event")
		return
	elseif self.userId == g_currentMission:getServerUserId() then
		print("The server cannot be kicked or banned")
		return
	elseif g_currentMission.userManager:getIsConnectionMasterUser(connection) then
		local v13_ = g_currentMission.userManager:getUserByUserId(self.userId)
		if v13_ == nil then
			local v14_ = print
			local v15_ = self.userId
			v14_("User(" .. tostring(v15_) .. ") not found")
			return
		elseif self.doKick then
			g_currentMission:kickUser(v13_)
		else
			g_currentMission:banUser(v13_)
		end
	else
		print("Connection is not a master user")
		return
	end
end
