-- Local values: GetBansEvent_mt
GetBansEvent = {}
local GetBansEvent_mt = Class(GetBansEvent, Event)
InitStaticEventClass(GetBansEvent, "GetBansEvent")
function GetBansEvent.emptyNew()
	-- upvalues: (copy) GetBansEvent_mt
	return Event.new(GetBansEvent_mt)
end

-- Local values: self
function GetBansEvent.new(bans)
	local v3_ = GetBansEvent.emptyNew()
	v3_.bans = bans or {}
	return v3_
end

-- Local values: num, _, ban
function GetBansEvent:readStream(streamId, connection)
	local v7_ = streamReadUInt16(streamId)
	self.bans = {}
	for _ = 1, v7_ do
		local v8_ = {
			["displayName"] = streamReadString(streamId),
			["uniqueUserId"] = streamReadString(streamId)
		}
		local v9_ = self.bans
		table.insert(v9_, v8_)
	end
	self:run(connection)
end

-- Local values: i, ban
function GetBansEvent:writeStream(streamId, connection)
	streamWriteUInt16(streamId, #self.bans)
	for _, v12_ in ipairs(self.bans) do
		streamWriteString(streamId, v12_.displayName)
		streamWriteString(streamId, v12_.uniqueUserId)
	end
end

-- Local values: bans, i, uniqueUserId, _platformUserId, _platformId, displayName
function GetBansEvent:run(connection)
	if connection:getIsServer() then
		g_messageCenter:publish(GetBansEvent, self.bans)
		return
	elseif g_currentMission.userManager:getIsConnectionMasterUser(connection) then
		local v15_ = {}
		for v16_ = 0, getNumOfBlockedUsers() - 1 do
			local v17_, _, _, v18_ = getBlockedUser(v16_)
			table.insert(v15_, {
				["uniqueUserId"] = v17_,
				["displayName"] = v18_
			})
		end
		connection:sendEvent(GetBansEvent.new(v15_))
	else
		print("Connection is not a master user")
	end
end
