-- Local values: User_mt
User = {}
local User_mt = Class(User)

function User.streamReadUserId(streamId)
	return streamReadUIntN(streamId, 12)
end

function User.streamWriteUserId(streamId, userId)
	if userId > 4095 then
		Logging.error("Trying to sync invalid user id \'%d\'", userId)
	end
	streamWriteUIntN(streamId, userId, 12)
end

-- Upvalues: User_mt
-- Local values: self
function User.new(customMt)
	-- upvalues: (copy) User_mt
	local v6_ = customMt or User_mt
	local v7_ = setmetatable({}, v6_)
	v7_.id = -1
	v7_.connection = nil
	v7_.state = FSBaseMission.USER_STATE_LOADING
	v7_.nickname = ""
	v7_.languageIndex = 1
	v7_.isMasterUser = false
	v7_.connectedTime = 0
	v7_.uniqueUserId = ""
	v7_.platformUserId = 0
	v7_.platformId = 0
	v7_.platformSessionId = ""
	v7_.financesVersionCounter = -1
	v7_.financeUpdateSendTime = 0
	v7_.unmutedVoiceVolume = 1
	v7_.blockStates = {}
	v7_.sentUserBlocked = nil
	return v7_
end

-- Local values: playtime
function User:readStream(streamId, connection)
	self.id = User.streamReadUserId(streamId)
	self.nickname = streamReadString(streamId)
	self.languageIndex = streamReadUInt8(streamId)
	self.isMasterUser = streamReadBool(streamId)
	local v10_ = streamReadInt32(streamId)
	self.connectedTime = g_currentMission.time - v10_
	self.uniqueUserId = streamReadString(streamId)
	self.platformUserId = streamReadString(streamId)
	self.platformId = streamReadUInt8(streamId)
	self.platformSessionId = streamReadString(streamId)
end

function User:writeStream(streamId, connection)
	User.streamWriteUserId(streamId, self.id)
	streamWriteString(streamId, self.nickname)
	streamWriteUInt8(streamId, self.languageIndex)
	streamWriteBool(streamId, self.isMasterUser)
	streamWriteInt32(streamId, g_currentMission.time - self.connectedTime)
	streamWriteString(streamId, self.uniqueUserId)
	streamWriteString(streamId, self.platformUserId)
	streamWriteUInt8(streamId, self.platformId)
	streamWriteString(streamId, self.platformSessionId)
end

function User:setId(id)
	self.id = id
end

function User:getId()
	return self.id
end

function User:setState(state)
	self.state = state
end

function User:getState()
	return self.state
end

function User:setConnection(connection)
	self.connection = connection
end

function User:getConnection()
	return self.connection
end

function User:setNickname(name)
	self.nickname = name
end

function User:getNickname()
	if self:getIsBlocked() and not getPlatformIdsAreCompatible(self.platformId, getPlatformId()) then
		return string.format("Player %d", self.id)
	else
		return self.nickname
	end
end

function User:setLanguageIndex(index)
	self.languageIndex = index
end

function User:getLanguageIndex()
	return self.languageIndex
end

function User:setIsMasterUser(isMasterUser)
	self.isMasterUser = isMasterUser
end

function User:getIsMasterUser()
	return self.isMasterUser
end

function User:setConnectedTime(connectedTime)
	self.connectedTime = connectedTime
end

function User:getConnectedTime()
	return self.connectedTime
end

function User:setUniqueUserId(uniqueUserId)
	self.uniqueUserId = uniqueUserId
end

function User:getUniqueUserId()
	return self.uniqueUserId
end

function User:setPlatformUserId(platformUserId)
	self.platformUserId = platformUserId
end

function User:getPlatformUserId()
	return self.platformUserId
end

function User:setPlatformId(platformId)
	self.platformId = platformId
end

function User:getPlatformId()
	return self.platformId
end

function User:setPlatformSessionId(platformSessionId)
	self.platformSessionId = platformSessionId
end

function User:getPlatformSessionId()
	return self.platformSessionId
end

function User:setFinancesVersionCounter(financesVersionCounter)
	self.financesVersionCounter = financesVersionCounter
end

function User:getFinancesVersionCounter()
	return self.financesVersionCounter
end

function User:setFinanceUpdateSendTime(financeUpdateSendTime)
	self.financeUpdateSendTime = financeUpdateSendTime
end

function User:getFinanceUpdateSendTime()
	return self.financeUpdateSendTime
end

function User:getIsBlocked()
	return getIsUserBlocked(self.uniqueUserId, self.platformUserId, self.platformId)
end

function User:getAllowVoiceCommunication()
	return getAllowVoiceCommunicationWithUser(self.uniqueUserId, self.platformUserId, self.platformId) == AsyncResult.YES
end

function User:getAllowTextCommunication()
	return getAllowTextCommunicationWithUser(self.uniqueUserId, self.platformUserId, self.platformId) == AsyncResult.YES
end

function User:block()
	setIsUserBlocked(self.uniqueUserId, self.platformUserId, self.platformId, true, self.nickname)
	g_messageCenter:publish(MessageType.BLOCK_LIST_CHANGED)
	self:updateSentUserBlockedState()
end

function User:unblock()
	setIsUserBlocked(self.uniqueUserId, self.platformUserId, self.platformId, false, "")
	g_messageCenter:publish(MessageType.BLOCK_LIST_CHANGED)
	self:updateSentUserBlockedState()
end

function User:report(reason)
	reportUser(self.uniqueUserId, self.platformUserId, self.platformId, reason)
end

function User:getVoiceVolume()
	return VoiceChatUtil.getUserVolume(self.uniqueUserId)
end

function User:setVoiceVolume(volume)
	VoiceChatUtil.setUserVolume(self.uniqueUserId, volume)
end

function User:getVoiceMuted()
	if self.id == g_currentMission.playerUserId then
		return voiceChatGetRecordingMode() == VoiceChatRecordingMode.MUTED
	else
		return self.isMuted
	end
end

function User:setVoiceMuted(isMuted)
	if self.id == g_currentMission.playerUserId then
		if voiceChatGetRecordingMode() == VoiceChatRecordingMode.MUTED then
			voiceChatSetRecordingMode(g_gameSettings:getValue(SettingsModel.SETTING.VOICE_MODE))
		else
			voiceChatSetRecordingMode(VoiceChatRecordingMode.MUTED)
		end
	else
		if self.isMuted ~= isMuted then
			self.isMuted = isMuted
			if isMuted then
				self.unmutedVoiceVolume = VoiceChatUtil.getUserVolume(self.uniqueUserId)
				VoiceChatUtil.setUserVolume(self.uniqueUserId, 0)
				return
			end
			VoiceChatUtil.setUserVolume(self.uniqueUserId, self.unmutedVoiceVolume)
		end
		return
	end
end

-- Local values: isBlocked
function User:updateSentUserBlockedState()
	local v66_ = self:getIsBlocked()
	if v66_ ~= self.sentUserBlocked then
		self.sentUserBlocked = v66_
		UserBlockEvent.sendEvent(self:getId(), v66_)
	end
end

function User:setIsBlockedBy(user, isBlocked)
	self.blockStates[user:getUniqueUserId()] = isBlocked
	voiceChatSetUserPairBlocked(self:getUniqueUserId(), user:getUniqueUserId(), isBlocked)
end

function User:getIsBlockedBy(user)
	return self.blockStates[user:getUniqueUserId()] ~= false
end
