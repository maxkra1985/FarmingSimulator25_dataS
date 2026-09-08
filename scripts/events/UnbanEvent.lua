-- Local values: UnbanEvent_mt
UnbanEvent = {}
local UnbanEvent_mt = Class(UnbanEvent, Event)
InitStaticEventClass(UnbanEvent, "UnbanEvent")
function UnbanEvent.emptyNew()
	-- upvalues: (copy) UnbanEvent_mt
	return Event.new(UnbanEvent_mt)
end

-- Local values: self
function UnbanEvent.new(uniqueUserId)
	local v3_ = UnbanEvent.emptyNew()
	v3_.uniqueUserId = uniqueUserId
	return v3_
end

function UnbanEvent:readStream(streamId, connection)
	local v7_ = g_currentMission:getIsServer()
	assert(v7_, "UnbanEvent is a client to server only event")
	self.uniqueUserId = streamReadString(streamId)
	self:run(connection)
end

function UnbanEvent:writeStream(streamId, connection)
	streamWriteString(streamId, self.uniqueUserId)
end

-- Local values: i, uniqueUserId, platformUserId, platformId, _
function UnbanEvent:run(connection)
	if connection:getIsServer() then
		printError("Error: UnbanEvent is a client to server only event")
		return
	elseif g_currentMission.userManager:getIsConnectionMasterUser(connection) then
		for v12_ = 0, getNumOfBlockedUsers() - 1 do
			local v13_, v14_, v15_, _ = getBlockedUser(v12_)
			if v13_ == self.uniqueUserId then
				setIsUserBlocked(v13_, v14_, v15_, false, "")
				g_messageCenter:publish(MessageType.BLOCK_LIST_CHANGED)
				return
			end
		end
	else
		print("Connection is not a master user")
	end
end
