-- Local values: UserEvent_mt
UserEvent = {}
UserEvent.SEND_NUM_BITS = 5
local UserEvent_mt = Class(UserEvent, Event)
InitStaticEventClass(UserEvent, "UserEvent")
function UserEvent.emptyNew()
	-- upvalues: (copy) UserEvent_mt
	return Event.new(UserEvent_mt)
end

-- Local values: self
function UserEvent.new(addedUsers, removedUsers, capacity, disconnectReason)
	local v6_ = UserEvent.emptyNew()
	v6_.addedUsers = addedUsers
	v6_.removedUsers = removedUsers
	v6_.capacity = capacity
	v6_.disconnectReason = disconnectReason or 1
	return v6_
end

-- Local values: userId, numUsers, _, user, _, removedUserId
function UserEvent:readStream(streamId, connection)
	local v10_ = User.streamReadUserId(streamId)
	g_currentMission.playerUserId = v10_
	self.capacity = streamReadInt8(streamId)
	self.addedUsers = {}
	for _ = 1, streamReadUIntN(streamId, UserEvent.SEND_NUM_BITS) do
		local v11_ = User.new()
		v11_:readStream(streamId, connection)
		local v12_ = self.addedUsers
		table.insert(v12_, v11_)
	end
	self.removedUsers = {}
	local v13_ = streamReadUIntN(streamId, UserEvent.SEND_NUM_BITS)
	for _ = 1, v13_ do
		local v14_ = User.streamReadUserId(streamId)
		local v15_ = self.removedUsers
		table.insert(v15_, v14_)
	end
	if v13_ > 0 then
		self.disconnectReason = DisconnectReason.readStream(streamId)
	end
	self:run(connection)
end

-- Local values: userId, numUsers, _, user, _, user
function UserEvent:writeStream(streamId, connection)
	local v19_ = g_currentMission.userManager:getUserIdByConnection(connection)
	User.streamWriteUserId(streamId, v19_)
	streamWriteInt8(streamId, self.capacity)
	local v20_ = #self.addedUsers
	streamWriteUIntN(streamId, v20_, UserEvent.SEND_NUM_BITS)
	for _, v21_ in ipairs(self.addedUsers) do
		v21_:writeStream(streamId, connection)
	end
	local v22_ = #self.removedUsers
	streamWriteUIntN(streamId, v22_, UserEvent.SEND_NUM_BITS)
	for _, v23_ in ipairs(self.removedUsers) do
		User.streamWriteUserId(streamId, v23_:getId())
	end
	if v22_ > 0 then
		DisconnectReason.writeStream(streamId, self.disconnectReason)
	end
end

-- Local values: _, user, _, userId
function UserEvent:run(connection)
	g_currentMission.missionDynamicInfo.capacity = self.capacity
	for _, v25_ in ipairs(self.addedUsers) do
		if g_currentMission.userManager:getUserByUniqueId(v25_:getUniqueUserId()) == nil then
			g_currentMission.userManager:addUser(v25_)
		end
	end
	for _, v26_ in ipairs(self.removedUsers) do
		g_currentMission.userManager:removeUserById(v26_, self.disconnectReason)
	end
end
