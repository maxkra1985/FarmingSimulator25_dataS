-- Local values: Connection_mt
Connection = {}
source("dataS/scripts/network/DisconnectReason.lua")
local Connection_mt = Class(Connection)
Connection.SYNC_CREATING = 1
Connection.SYNC_CREATING_DELAYED = 2
Connection.SYNC_LOADED = 3
Connection.SYNC_SYNCING = 4
Connection.SYNC_CREATED = 5
Connection.SYNC_REMOVING = 6
Connection.SYNC_MANUALLY_REGISTERED = 7
Connection.SYNC_HIST_CREATE = 0
Connection.SYNC_HIST_SYNC = 1
Connection.SYNC_HIST_UPDATE = 2
Connection.SYNC_HIST_REMOVE = 3
Connection.SEND_INFO_NUM_BITS = 3
Connection.SEND_INFO_DELETE = 0
Connection.SEND_INFO_CREATE = 1
Connection.SEND_INFO_SYNC = 2
Connection.SEND_INFO_UPDATE = 3
Connection.SEND_INFO_REMOVE = 4

-- Upvalues: Connection_mt
-- Local values: self
function Connection.new(id, isServer, reverseConnection)
	-- upvalues: (copy) Connection_mt
	local v5_ = Connection_mt
	local v6_ = setmetatable({}, v5_)
	v6_.streamId = id
	v6_.isServer = isServer
	v6_.isConnected = true
	v6_.isReadyForObjects = false
	v6_.isReadyForEvents = false
	v6_.objectsInfo = {}
	v6_.pendingDeleteObjects = {}
	v6_.pendingDeleteObjectPacketIds = {}
	v6_.compressionRatio = 1
	v6_.sendStatsTime = 0
	v6_.lastSeqSent = 0
	v6_.lastSeqReceived = 0
	v6_.highestAckedSeq = 0
	v6_.ackMask = 0
	v6_.hasPacketsToAck = false
	v6_.ackPingPacketSent = false
	if v6_.streamId == NetworkNode.LOCAL_STREAM_ID then
		v6_:setIsReadyForObjects(true)
		v6_:setIsReadyForEvents(true)
		if reverseConnection ~= nil then
			v6_.localConnection = reverseConnection
			return v6_
		end
		v6_.localConnection = Connection.new(id, not isServer, v6_)
		v6_.localConnection:setIsReadyForObjects(true)
		v6_.localConnection:setIsReadyForEvents(true)
	end
	return v6_
end

function Connection:setIsReadyForObjects(isReadyForObjects)
	self.isReadyForObjects = isReadyForObjects
end

function Connection:setIsReadyForEvents(isReadyForEvents)
	self.isReadyForEvents = isReadyForEvents
end

-- Local values: sendSize, sendSizeCompressed, compressionRatio
function Connection:updateSendStats(tickSum)
	self.sendStatsTime = self.sendStatsTime + tickSum
	if self.sendStatsTime > 100 then
		self.sendStatsTime = 0
		local v13_, v14_ = netGetAndResetConnectionSendStats(self.streamId)
		local v15_
		if v14_ > 0 then
			local v16_ = v13_ / v14_
			v15_ = math.clamp(v16_, 1, 5)
		else
			v15_ = 1
		end
		self.compressionRatio = 0.8 * self.compressionRatio + 0.2 * v15_
	end
end

-- Local values: networkChannel, startOffset, endOffset, dataSent
function Connection:sendEvent(event, deleteEvent, force)
	if self.isConnected then
		if self.streamId == NetworkNode.LOCAL_STREAM_ID then
			event:run(self.localConnection)
		elseif self.isReadyForEvents or force then
			if event.eventId == nil then
				printError("Error: Invalid event id for " .. (ClassUtil.getClassNameByObject(event) or "<unable to retrieve class>"))
			else
				local v21_ = event.networkChannel
				if g_server ~= nil and v21_ == NetworkNode.CHANNEL_MAIN then
					g_server:setCurrentReliableWriteStreamConnection(self)
				end
				streamWriteUIntN(self.streamId, MessageIds.EVENT, MessageIds.SEND_NUM_BITS)
				streamWriteUIntN(self.streamId, event.eventId, EventIds.SEND_NUM_BITS)
				streamWriteBool(self.streamId, g_networkDebug)
				local v22_
				if g_networkDebug then
					v22_ = streamGetWriteOffset(self.streamId)
					streamWriteInt32(self.streamId, 0)
				else
					v22_ = nil
				end
				event:writeStream(self.streamId, self)
				if g_networkDebug then
					local v23_ = streamGetWriteOffset(self.streamId)
					streamSetWriteOffset(self.streamId, v22_)
					streamWriteInt32(self.streamId, v23_ - (v22_ + 32))
					streamSetWriteOffset(self.streamId, v23_)
				end
				local v24_ = streamGetWriteOffset(self.streamId)
				netSendStream(self.streamId, "high", "reliable_ordered", v21_, true)
				if g_server == nil then
					g_client:addPacketSize(self, NetworkNode.PACKET_EVENT, v24_ / 8)
				else
					g_server:setCurrentReliableWriteStreamConnection(nil)
					g_server:addPacketSize(self, NetworkNode.PACKET_EVENT, v24_ / 8)
				end
			end
		end
		if deleteEvent then
			event:delete()
		end
	end
end

-- Local values: objectInfo, isInQueueState
function Connection:queueSendEvent(event, force, ghostObject)
	if self.isConnected then
		if self.isReadyForEvents or force then
			local v29_ = self.objectsInfo[ghostObject.id]
			if v29_ ~= nil and (v29_.sync == Connection.SYNC_CREATING or (v29_.sync == Connection.SYNC_CREATING_DELAYED or (v29_.sync == Connection.SYNC_LOADED or v29_.sync == Connection.SYNC_SYNCING)) or v29_.sync == Connection.SYNC_MANUALLY_REGISTERED) then
				event.queueCount = event.queueCount + 1
				if v29_.eventQueue == nil then
					v29_.eventQueue = {}
				end
				local v30_ = v29_.eventQueue
				table.insert(v30_, event)
				return
			end
		end
	end
end

function Connection:getIsClient()
	return not self.isServer
end

function Connection:getIsServer()
	return self.isServer
end

function Connection:getIsLocal()
	return self.streamId == NetworkNode.LOCAL_STREAM_ID
end

function Connection:writeUpdateAck(streamId)
	self.lastSeqSent = self.lastSeqSent + 1
	streamWriteUInt8(streamId, self.lastSeqSent % 256)
	streamWriteUInt8(streamId, self.lastSeqReceived % 256)
	streamWriteUInt32(streamId, self.ackMask)
	self.hasPacketsToAck = false
end

-- Local values: seq, highestAck, ackMask, i, isTransmitted
function Connection:readUpdateAck(streamId)
	local v38_ = streamReadUInt8(streamId)
	local v39_ = streamReadUInt8(streamId)
	local v40_ = streamReadUInt32(streamId)
	local v41_ = self.lastSeqReceived
	local v42_ = v38_ + bit32.band(v41_, 4294967040)
	if v42_ < self.lastSeqReceived then
		v42_ = v42_ + 256
	end
	if self.lastSeqReceived + 31 < v42_ then
		return false
	end
	local v43_ = self.highestAckedSeq
	local v44_ = v39_ + bit32.band(v43_, 4294967040)
	if v44_ < self.highestAckedSeq then
		v44_ = v44_ + 256
	end
	if self.lastSeqSent < v44_ then
		return false
	end
	local v45_ = self.ackMask
	local v46_ = v42_ - self.lastSeqReceived
	self.ackMask = bit32.lshift(v45_, v46_)
	self.ackMask = self.ackMask + 1
	self.hasPacketsToAck = true
	for v47_ = self.highestAckedSeq + 1, v44_ do
		local v48_ = v44_ - v47_
		local v49_ = bit32.lshift(1, v48_)
		if bit32.band(v40_, v49_) ~= 0 then
			self:onPacketSent(v47_)
		else
			self:onPacketLost(v47_)
		end
	end
	self.highestAckedSeq = v44_
	self.lastSeqReceived = v42_
	return true
end

function Connection:getIsWindowFull()
	return self.lastSeqSent - self.highestAckedSeq >= 29
end

-- Local values: objectInfo
function Connection:getObjectSyncState(objectId)
	local v53_ = self.objectsInfo[objectId]
	if v53_ == nil then
		return nil
	else
		return v53_.sync
	end
end

-- Local values: objectId, objectInfo, historyEntry, k, _, objectId, packetId
function Connection:onPacketSent(i)
	for v56_, v57_ in pairs(self.objectsInfo) do
		local v58_ = v57_.history[i]
		if v58_ ~= nil then
			if g_networkDebug then
				for v59_, _ in pairs(v57_.history) do
					local v60_ = i <= v59_
					assert(v60_)
				end
			end
			v57_.history[i] = nil
			if v58_.sync == Connection.SYNC_HIST_CREATE then
				if v57_.sync == Connection.SYNC_CREATING then
					v57_.sync = Connection.SYNC_CREATED
					self:sendObjectEventQueue(v57_)
				end
			elseif v58_.sync == Connection.SYNC_HIST_SYNC then
				if v57_.sync == Connection.SYNC_SYNCING then
					v57_.sync = Connection.SYNC_CREATED
					self:sendObjectEventQueue(v57_)
				end
			elseif v58_.sync == Connection.SYNC_HIST_REMOVE and v57_.sync == Connection.SYNC_REMOVING then
				self.objectsInfo[v56_] = nil
			end
		end
	end
	for v61_, v62_ in pairs(self.pendingDeleteObjectPacketIds) do
		if v62_ == i then
			self.pendingDeleteObjectPacketIds[v61_] = nil
		end
	end
	g_currentMission:onConnectionPacketSent(self, i)
end

-- Local values: objectId, objectInfo, historyEntry, k, _, laterUpdatedMask, _, h, notLaterUpdatedMask, objectId, packetId
function Connection:onPacketLost(i)
	for v65_, v66_ in pairs(self.objectsInfo) do
		local v67_ = v66_.history[i]
		if v67_ ~= nil then
			if g_networkDebug then
				for v68_, _ in pairs(v66_.history) do
					local v69_ = i <= v68_
					assert(v69_)
				end
			end
			v66_.history[i] = nil
			if v67_.sync == Connection.SYNC_HIST_CREATE then
				if v66_.sync == Connection.SYNC_CREATING or v66_.sync == Connection.SYNC_CREATING_DELAYED then
					if v66_.manuallyReplicated then
						v66_.sync = Connection.SYNC_MANUALLY_REGISTERED
					else
						self.objectsInfo[v65_] = nil
					end
				end
			elseif v67_.sync == Connection.SYNC_HIST_SYNC then
				if v66_.sync == Connection.SYNC_SYNCING then
					v66_.sync = Connection.SYNC_LOADED
				end
			elseif v67_.sync == Connection.SYNC_HIST_REMOVE then
				if v66_.sync == Connection.SYNC_REMOVING then
					v66_.sync = Connection.SYNC_CREATED
				end
			else
				local v70_ = 0
				for _, v71_ in pairs(v66_.history) do
					local v72_ = v71_.mask
					v70_ = bit32.bor(v70_, v72_)
				end
				local v73_ = v67_.mask
				local v74_ = bit32.bnot(v70_)
				local v75_ = bit32.band(v73_, v74_)
				if v75_ ~= 0 then
					local v76_ = v66_.dirtyMask
					v66_.dirtyMask = bit32.bor(v76_, v75_)
				end
			end
		end
	end
	for v77_, v78_ in pairs(self.pendingDeleteObjectPacketIds) do
		if v78_ == i then
			self.pendingDeleteObjectPacketIds[v77_] = nil
			self.pendingDeleteObjects[v77_] = v77_
		end
	end
	g_currentMission:onConnectionPacketLost(self, i)
end

-- Local values: _, event
function Connection:sendObjectEventQueue(objectInfo)
	if objectInfo.eventQueue ~= nil then
		for _, v81_ in ipairs(objectInfo.eventQueue) do
			self:sendEvent(v81_, false, true)
			v81_.queueCount = v81_.queueCount - 1
			if v81_.queueCount == 0 then
				v81_:delete()
			end
		end
		objectInfo.eventQueue = nil
	end
end

-- Local values: _, event
function Connection:dropObjectEventQueue(objectInfo)
	if objectInfo.eventQueue ~= nil then
		for _, v83_ in ipairs(objectInfo.eventQueue) do
			v83_.queueCount = v83_.queueCount - 1
			if v83_.queueCount == 0 then
				v83_:delete()
			end
		end
		objectInfo.eventQueue = nil
	end
end

-- Local values: objectInfo
function Connection:notifyObjectDeleted(objectId, alreadySent)
	local v87_ = not self.isServer
	assert(v87_)
	local v88_ = self.objectsInfo[objectId]
	if v88_ ~= nil then
		self:dropObjectEventQueue(v88_)
		self.objectsInfo[objectId] = nil
	end
	if not alreadySent and (self.streamId ~= NetworkNode.LOCAL_STREAM_ID and self.pendingDeleteObjectPacketIds[objectId] == nil) then
		self.pendingDeleteObjects[objectId] = objectId
	end
end

function Connection:getLatency()
	return 20
end
