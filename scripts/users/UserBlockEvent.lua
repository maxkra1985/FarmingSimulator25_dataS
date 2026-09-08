-- Local values: UserBlockEvent_mt
UserBlockEvent = {}
local UserBlockEvent_mt = Class(UserBlockEvent, Event)
InitStaticEventClass(UserBlockEvent, "UserBlockEvent")
function UserBlockEvent.emptyNew()
	-- upvalues: (copy) UserBlockEvent_mt
	return Event.new(UserBlockEvent_mt)
end

-- Local values: self
function UserBlockEvent.new(userId, isBlocked)
	local v4_ = UserBlockEvent.emptyNew()
	v4_.userId = userId
	v4_.isBlocked = isBlocked
	return v4_
end

function UserBlockEvent:readStream(streamId, connection)
	self.userId = User.streamReadUserId(streamId)
	self.isBlocked = streamReadBool(streamId)
	self:run(connection)
end

function UserBlockEvent:writeStream(streamId, connection)
	User.streamWriteUserId(streamId, self.userId)
	streamWriteBool(streamId, self.isBlocked)
end

-- Local values: fromUser, toUser
function UserBlockEvent:run(connection)
	if not connection:getIsServer() then
		local v12_ = g_currentMission.userManager:getUserByConnection(connection)
		local v13_ = g_currentMission.userManager:getUserByUserId(self.userId)
		if v13_ ~= nil then
			v13_:setIsBlockedBy(v12_, self.isBlocked)
		end
	end
end

function UserBlockEvent.sendEvent(userId, isBlocked, noEventSend)
	if (noEventSend == nil or noEventSend == false) and g_server == nil then
		g_client:getServerConnection():sendEvent(UserBlockEvent.new(userId, isBlocked))
	end
end
