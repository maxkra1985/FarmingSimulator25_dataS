-- Local values: UserManager_mt
UserManager = {}
local UserManager_mt = Class(UserManager)

-- Upvalues: UserManager_mt
-- Local values: self
function UserManager.new(isServer, customMt)
	-- upvalues: (copy) UserManager_mt
	local v4_ = customMt or UserManager_mt
	local v5_ = setmetatable({}, v4_)
	v5_.isServer = isServer
	v5_.users = {}
	v5_.masterUsers = {}
	v5_.masterUserIdToConnection = {}
	v5_.idCounter = 0
	v5_.blockedUserUpdateTimer = 0
	return v5_
end

function UserManager:delete() end

function UserManager:getNextUserId()
	self.idCounter = self.idCounter + 1
	return self.idCounter
end

function UserManager:addUser(user)
	local v9_ = self.users
	table.insert(v9_, user)
	g_messageCenter:publish(MessageType.USER_ADDED, user)
end

-- Local values: k, user
function UserManager:removeUserByConnection(connection, disconnectReason)
	for v13_, v14_ in ipairs(self.users) do
		if v14_:getConnection() == connection then
			self:removeMasterUser(v14_)
			table.remove(self.users, v13_)
			g_messageCenter:publish(MessageType.USER_REMOVED, v14_, disconnectReason)
			return
		end
	end
end

-- Local values: k, u
function UserManager:removeUser(user, disconnectReason)
	for v18_, v19_ in ipairs(self.users) do
		if user == v19_ then
			self:removeMasterUser(user)
			table.remove(self.users, v18_)
			g_messageCenter:publish(MessageType.USER_REMOVED, user, disconnectReason)
			return
		end
	end
end

-- Local values: k, user
function UserManager:removeUserById(userId, disconnectReason)
	for v23_, v24_ in ipairs(self.users) do
		if userId == v24_:getId() then
			self:removeMasterUser(v24_)
			table.remove(self.users, v23_)
			g_messageCenter:publish(MessageType.USER_REMOVED, v24_, disconnectReason)
			return
		end
	end
end

function UserManager:getUsers()
	return self.users
end

function UserManager:getNumberOfUsers()
	return #self.users
end

-- Local values: _, user, userNickname
function UserManager:getUserByNickname(nickname, useLowercase)
	if useLowercase then
		nickname = string.lower(nickname)
	end
	for _, v30_ in ipairs(self.users) do
		local v31_ = v30_:getNickname()
		if useLowercase then
			v31_ = string.lower(v31_)
		end
		if v31_ == nickname then
			return v30_
		end
	end
	return nil
end

-- Local values: _, user
function UserManager:getUserByConnection(connection)
	for _, v34_ in ipairs(self.users) do
		if v34_:getConnection() == connection then
			return v34_
		end
	end
	return nil
end

-- Local values: _, user
function UserManager:getUserByUniqueId(uniqueUserId)
	for _, v37_ in ipairs(self.users) do
		if v37_:getUniqueUserId() == uniqueUserId then
			return v37_
		end
	end
	return nil
end

-- Local values: user
function UserManager:getUserIdByConnection(connection)
	local v40_ = self:getUserByConnection(connection)
	return v40_ == nil and -1 or v40_:getId()
end

-- Local values: user
function UserManager:getUserNameByConnection(connection)
	local v43_ = self:getUserByConnection(connection)
	return v43_ == nil and "<unknownUserForConnection>" or v43_:getNickname()
end

-- Local values: _, user
function UserManager:getUserByUserId(userId)
	if userId == nil then
		return nil
	end
	for _, v46_ in ipairs(self.users) do
		if v46_:getId() == userId then
			return v46_
		end
	end
	return nil
end

-- Local values: _, user
function UserManager:getUniqueUserIdByUserId(userId)
	if userId == nil then
		return nil
	end
	for _, v49_ in ipairs(self.users) do
		if v49_:getId() == userId then
			return v49_:getUniqueUserId()
		end
	end
	return nil
end

-- Local values: user
function UserManager:getUniqueUserIdByConnection(connection)
	if connection == nil then
		return nil
	else
		local v52_ = self:getUserByConnection(connection)
		if v52_ == nil then
			return nil
		else
			return v52_:getUniqueUserId()
		end
	end
end

function UserManager:getNumberOfMasterUsers()
	return #self.masterUsers
end

-- Local values: user
function UserManager:addMasterUserByConnection(connection)
	local v56_ = self.isServer
	assert(v56_, "UserManager:addMasterUserByConnection call is only allowed on Server")
	local v57_ = self:getUserByConnection(connection)
	if v57_ ~= nil then
		self:addMasterUser(v57_)
	end
end

function UserManager:addMasterUser(user)
	table.addElement(self.masterUsers, user)
	if self.isServer then
		self.masterUserIdToConnection[user:getId()] = user:getConnection()
		g_currentMission:broadcastMissionDynamicInfo()
	end
	user:setIsMasterUser(true)
	g_messageCenter:publish(MessageType.MASTERUSER_ADDED, user)
end

function UserManager:removeMasterUser(user)
	user:setIsMasterUser(false)
	table.removeElement(self.masterUsers, user)
	if self.isServer then
		self.masterUserIdToConnection[user:getId()] = nil
	end
end

function UserManager:getMasterUsers()
	return self.masterUsers
end

function UserManager:getIsUserIdMasterUser(userId)
	local v65_ = self.isServer
	assert(v65_, "UserManager:getIsUserIdMasterUser call is only allowed on Server")
	return self.masterUserIdToConnection[userId] ~= nil
end

-- Local values: user
function UserManager:getIsConnectionMasterUser(connection)
	local v68_ = self.isServer
	assert(v68_, "UserManager:getIsUserIdMasterUser call is only allowed on Server")
	local v69_ = self:getUserByConnection(connection)
	local v70_
	if v69_ == nil then
		v70_ = false
	else
		v70_ = v69_:getIsMasterUser()
	end
	return v70_
end

-- Local values: list, _, user, platformSessionId
function UserManager:getAllPlatformSessionIds()
	local v72_ = self.isServer
	assert(v72_, "UserManager:getAllPlatformSessionIds() call is only allowed on Server")
	local v73_ = {}
	for _, v74_ in ipairs(self.users) do
		local v75_ = v74_:getPlatformSessionId()
		if v75_ ~= "" then
			table.insert(v73_, v75_)
		end
	end
	return v73_
end

function UserManager:setUserBlockDataDirty()
	self.blockedUserUpdateTimer = 0
end

-- Local values: _, user, blockState, connection
function UserManager:update(dt)
	self.blockedUserUpdateTimer = self.blockedUserUpdateTimer - dt
	if self.blockedUserUpdateTimer <= 0 then
		for _, v79_ in ipairs(self.users) do
			if not self.isServer then
				v79_:updateSentUserBlockedState()
			end
			local v80_ = v79_:getIsBlocked()
			if v79_.lastKnownBlockState ~= v80_ then
				v79_.lastKnownBlockState = v80_
				if self.isServer and v80_ then
					local v81_ = v79_:getConnection()
					v81_:sendEvent(KickBanNotificationEvent.new(false))
					g_server:closeConnection(v81_, DisconnectReason.BANNED)
				end
			end
		end
		self.blockedUserUpdateTimer = 5000
	end
end
