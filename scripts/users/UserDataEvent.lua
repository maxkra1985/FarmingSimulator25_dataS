-- Local values: UserDataEvent_mt
UserDataEvent = {}
UserDataEvent.SEND_NUM_BITS = 5
local UserDataEvent_mt = Class(UserDataEvent, Event)
InitStaticEventClass(UserDataEvent, "UserDataEvent")
function UserDataEvent.emptyNew()
	-- upvalues: (copy) UserDataEvent_mt
	return Event.new(UserDataEvent_mt)
end

-- Local values: self
function UserDataEvent.new(changedUsers)
	local v3_ = UserDataEvent.emptyNew()
	v3_.changedUsers = changedUsers
	return v3_
end

-- Local values: numUsers, _, userId, user
function UserDataEvent:readStream(streamId, connection)
	self.changedUsers = {}
	for _ = 1, streamReadUIntN(streamId, UserDataEvent.SEND_NUM_BITS) do
		local v7_ = User.streamReadUserId(streamId)
		local v8_ = g_currentMission.userManager:getUserByUserId(v7_)
		if v8_ == nil then
			Logging.error("UserDataEvent: Could not resolve user id \'%s\'", v7_)
			return
		end
		v8_:readStream(streamId, connection)
		if v8_:getIsMasterUser() then
			g_currentMission.userManager:addMasterUser(v8_)
		end
	end
end

-- Local values: numUsers, _, user
function UserDataEvent:writeStream(streamId, connection)
	local v12_ = #self.changedUsers
	streamWriteUIntN(streamId, v12_, UserDataEvent.SEND_NUM_BITS)
	for _, v13_ in ipairs(self.changedUsers) do
		User.streamWriteUserId(streamId, v13_:getId())
		v13_:writeStream(streamId, connection)
	end
end
