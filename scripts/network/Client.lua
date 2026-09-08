-- Local values: Client_mt, clientLocalNetConnect
Client = {}
local Client_mt = Class(Client, NetworkNode)
local clientLocalNetConnect = ""
function InitClientOnce()
	-- upvalues: (ref) clientLocalNetConnect
	if clientLocalNetConnect == "" then
		clientLocalNetConnect = netConnect
	end
end
function Client.new()
	-- upvalues: (copy) Client_mt
	local v3_ = NetworkNode.new(Client_mt)
	v3_.serverConnection = nil
	v3_.tempClientCreatingObjects = {}
	v3_.tempClientManuallyRegisteringObjects = {}
	v3_.tickRate = 30
	v3_.tickDuration = 1000 / v3_.tickRate
	v3_.tickSum = 0
	v3_.netIsRunning = false
	v3_.serverStreamId = 0
	v3_.currentLatency = 80
	v3_.lastNumUpdatesSent = 0
	v3_.finishedAsyncObjects = {}
	if g_server == nil then
		addConsoleCommand("gsNetworkShowTraffic", "Toggle network traffic visualization", "consoleCommandToggleShowNetworkTraffic", v3_)
		addConsoleCommand("gsNetworkShowObjects", "Toggle network show objects", "consoleCommandToggleNetworkShowObjects", v3_)
	end
	return v3_
end

-- Local values: _, object, _, object
function Client:delete()
	if g_server == nil then
		removeConsoleCommand("gsNetworkShowTraffic")
		removeConsoleCommand("gsNetworkShowObjects")
	end
	for _, v5_ in pairs(self.tempClientCreatingObjects) do
		v5_:delete()
	end
	for _, v6_ in pairs(self.tempClientManuallyRegisteringObjects) do
		v6_:delete()
	end
	self.finishedAsyncObjects = {}
	Client:superClass().delete(self)
	self:stop()
end

-- Local values: numObjects, i, object, serverObjectId, objectInfo, dirtyObjects, numDirtyObjects, numDirtyObjectsSent, numDirtyObjectsOffset, x, y, z, isGuiActive, oldPacketSize, maxUploadSize, j, object, objectId, packetSize, endOffset
function Client:update(dt, isRunning)
	if g_server == nil then
		Client:superClass().update(self, dt)
		if self.serverStreamId == 0 then
			return
		end
		if not isRunning then
			return
		end
		if #self.finishedAsyncObjects > 0 then
			local v10_ = #self.finishedAsyncObjects
			local v11_ = math.min(v10_, 255)
			streamWriteUIntN(self.serverStreamId, MessageIds.OBJECT_LOADED, MessageIds.SEND_NUM_BITS)
			streamWriteUInt8(self.serverStreamId, v11_)
			for _ = 1, v11_ do
				local v12_ = table.remove(self.finishedAsyncObjects, 1)
				local v13_ = NetworkUtil.getObjectId(v12_)
				local v14_ = self.serverConnection.objectsInfo[v13_]
				if v14_ ~= nil then
					v14_.sync = Connection.SYNC_LOADED
					NetworkUtil.writeNodeObjectId(self.serverStreamId, v13_)
				end
			end
			netSendStream(self.serverStreamId, "high", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
		end
		self:updateActiveObjects(dt)
		self.tickSum = self.tickSum + dt
		if self.tickSum >= self.tickDuration - 3 then
			local v15_ = self:updateActiveObjectsTick(self.tickSum)
			if self.serverConnection:getIsWindowFull() then
				if not self.serverConnection.ackPingPacketSent then
					self.serverConnection.ackPingPacketSent = true
					streamWriteUIntN(self.serverStreamId, MessageIds.OBJECT_PING, MessageIds.SEND_NUM_BITS)
					self.serverConnection:writeUpdateAck(self.serverStreamId)
					netSendStream(self.serverStreamId, "medium", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
				end
			else
				self.serverConnection.ackPingPacketSent = false
				local v16_ = #v15_
				local v17_ = math.min(v16_, 255)
				if v17_ > 0 then
					streamWriteTimestamp(self.serverStreamId)
				end
				streamWriteUIntN(self.serverStreamId, MessageIds.OBJECT_UPDATE, MessageIds.SEND_NUM_BITS)
				self.serverConnection:writeUpdateAck(self.serverStreamId)
				local v18_ = streamGetWriteOffset(self.serverStreamId)
				streamWriteUInt8(self.serverStreamId, 0)
				local v19_, v20_, v21_, v22_
				if self.networkListener == nil then
					v19_ = false
					v20_ = 0
					v21_ = 0
					v22_ = 0
				else
					v20_, v21_, v22_ = self.networkListener:getClientPosition()
					v19_ = self.networkListener:getClientGuiVisibility()
				end
				streamWriteBool(self.serverStreamId, v19_)
				streamWriteFloat32(self.serverStreamId, v20_)
				streamWriteFloat32(self.serverStreamId, v21_)
				streamWriteFloat32(self.serverStreamId, v22_)
				local v23_ = g_maxUploadRate * 8 * self.tickDuration
				local v24_ = 0
				for v25_ = 1, v17_ do
					local v26_ = v15_[v25_]
					local v27_ = v15_[v25_].lastServerId
					NetworkUtil.writeNodeObjectId(self.serverStreamId, v27_)
					v26_:writeUpdateStream(self.serverStreamId, self.serverConnection, v26_.dirtyMask)
					v26_:clearDirtyMask()
					local v28_ = streamGetWriteOffset(self.serverStreamId)
					self:addPacketSize(self.serverConnection, self:getObjectPacketType(v26_), (v28_ - v24_) / 8)
					if v23_ < v28_ then
						v17_ = v25_
						break
					end
					v24_ = v28_
				end
				local v29_ = streamGetWriteOffset(self.serverStreamId)
				streamSetWriteOffset(self.serverStreamId, v18_)
				streamWriteUInt8(self.serverStreamId, v17_)
				streamSetWriteOffset(self.serverStreamId, v29_)
				local v30_ = streamGetWriteOffset(self.serverStreamId)
				voiceChatWriteClientUpdateToStream(self.serverStreamId, self.serverStreamId)
				self:addPacketSize(self.serverConnection, NetworkNode.PACKET_VOICE_CHAT, (streamGetWriteOffset(self.serverStreamId) - v30_) / 8)
				netSendStream(self.serverStreamId, "medium", "unreliable_sequenced", NetworkNode.CHANNEL_MAIN, true)
			end
			self:updatePacketStats(self.tickSum)
			self.tickSum = 0
		end
	end
end

function Client:drawDebug()
	if g_server == nil then
		Client:superClass().drawDebug(self)
		local _ = self.showNetworkTraffic
	end
end

function Client:onObjectFinishedAsyncLoading(object)
	local v34_ = self.finishedAsyncObjects
	table.insert(v34_, object)
end

function Client:startLocal()
	self.serverConnection = g_server.clientConnections[NetworkNode.LOCAL_STREAM_ID].localConnection
	self:connectionRequestAccepted()
end
local function v40_(p36_, p37_, p38_, p39_)
	-- upvalues: (ref) clientLocalNetConnect
	if not p36_.netIsRunning then
		p36_.netIsRunning = true
		g_connectionManager:startupWithWorkingPort(g_gameSettings:getValue(GameSettings.SETTING.DEFAULT_SERVER_PORT))
		g_connectionManager:setDefaultListener(Client.packetReceived, p36_)
		p36_.serverStreamId = clientLocalNetConnect(p37_, p38_, "", p39_ == nil and "" or p39_)
		p36_.serverConnection = Connection.new(p36_.serverStreamId, true)
		if p36_.serverStreamId == 0 then
			printError("Error: Failed to call connect")
			p36_.serverConnection.isConnected = false
			p36_.serverConnection:setIsReadyForObjects(false)
			p36_.serverConnection:setIsReadyForEvents(false)
			if p36_.networkListener ~= nil then
				p36_.networkListener:onConnectionClosed(p36_.serverConnection)
			end
		else
			p36_.serverConnection:setIsReadyForObjects(true)
			p36_.serverConnection:setIsReadyForEvents(true)
		end
		if g_isDevelopmentVersion then
			CaptionUtil.addText("- Client")
		end
	end
end
Client.start = v40_

function Client:stop()
	if self.netIsRunning then
		if self.serverStreamId ~= 0 then
			netCloseConnection(self.serverStreamId, true, 1)
			self.serverStreamId = 0
		end
		self.serverConnection.isConnected = false
		self.serverConnection:setIsReadyForObjects(false)
		self.serverConnection:setIsReadyForEvents(false)
		g_connectionManager:shutdown()
		g_connectionManager:setDefaultListener(nil, nil)
		self.netIsRunning = false
	end
end

-- Local values: messageId, tickDelay, interpBuffer, targetDelay, adjust, networkDebug, numInfos, i, numBits, startOffset, infoId, objectId, object, objectClassId, objectId, object, needsCreation, objectClass, syncState, objectId, object, objectId, object, objectId, object, networkDebug, numObjects, i, numBits, startOffset, objectClassId, objectId, objectClass, object, syncState, endOffset, readNumBits, extraInfo, serverObjectId, clientObjectId, object, eventId, eventClass, networkDebug, numBits, startOffset, tempEvent, endOffset, readNumBits, className, numIds, i, eventId, className, numIds, i, eventId, className
function Client:packetReceived(packetType, timestamp, streamId)
	if streamId == self.serverStreamId then
		Client:superClass().packetReceived(self, packetType, timestamp, streamId)
		if packetType == Network.TYPE_APPLICATION then
			local v46_ = streamReadUIntN(streamId, MessageIds.SEND_NUM_BITS)
			if v46_ == MessageIds.OBJECT_UPDATE then
				g_packetPhysicsNetworkTime = streamReadInt32(streamId)
				g_networkTime = netGetTime()
				local v47_ = self.currentLatency * 0.9
				local v48_ = g_networkTime - timestamp
				self.currentLatency = v47_ + math.max(v48_, 0.5) * 0.1
				local v49_ = self.lastReceivedNetworkTime == nil and 60 or g_networkTime - self.lastReceivedNetworkTime
				self.lastReceivedNetworkTime = g_networkTime
				local v50_ = g_clientInterpDelayBufferOffset + v49_ * g_clientInterpDelayBufferScale
				local v51_ = g_clientInterpDelayBufferMin
				local v52_ = g_clientInterpDelayBufferMax
				local v53_ = v49_ + math.clamp(v50_, v51_, v52_)
				local v54_ = g_clientInterpDelayAdjustDown
				if g_clientInterpDelay < v53_ then
					v54_ = g_clientInterpDelayAdjustUp
				end
				g_clientInterpDelay = g_clientInterpDelay * (1 - v54_) + v53_ * v54_
				local v55_ = g_clientInterpDelay
				local v56_ = g_clientInterpDelayMin
				local v57_ = g_clientInterpDelayMax
				g_clientInterpDelay = math.clamp(v55_, v56_, v57_)
				self.serverConnection:readUpdateAck(streamId)
				self.serverFPS = streamReadUIntN(streamId, 6)
				local v58_ = streamReadBool(streamId)
				if self.networkListener ~= nil then
					self.networkListener:onConnectionReadUpdateStream(self.serverConnection, v58_)
				end
				for _ = 1, streamReadUInt8(streamId) do
					local v59_, v60_
					if v58_ then
						v59_ = streamGetReadOffset(streamId)
						v60_ = streamReadInt32(streamId)
					else
						v60_ = nil
						v59_ = 0
					end
					local v61_ = streamReadUIntN(streamId, Connection.SEND_INFO_NUM_BITS)
					if v61_ == Connection.SEND_INFO_DELETE then
						local v62_ = self:getObject((NetworkUtil.readNodeObjectId(streamId)))
						if v62_ ~= nil then
							self:unregisterObject(v62_, true)
							v62_:delete()
						end
						if v58_ then
							self:checkObjectUpdateDebugReadSize(streamId, v60_, v59_, "object", v62_)
						end
					elseif v61_ == Connection.SEND_INFO_CREATE then
						if g_server ~= nil then
							printError("Error: Unexpected packet object created")
							return
						end
						local v63_ = streamReadUIntN(streamId, ObjectIds.SEND_NUM_BITS)
						local v64_ = NetworkUtil.readNodeObjectId(streamId)
						local v65_ = self:getObject(v64_)
						local v66_ = v65_ == nil
						if v66_ then
							local v67_ = ObjectIds.getObjectClassById(v63_)
							if v67_ ~= nil then
								v65_ = v67_.new(false, true)
								v65_.isManuallyReplicated = false
								v65_.isRegistered = true
							end
						end
						if v65_ == nil then
							return
						end
						v65_:readStream(streamId, self.serverConnection, v64_)
						local v68_ = Connection.SYNC_CREATED
						if v66_ then
							if v65_:getIsDelayedLoaded() then
								v68_ = Connection.SYNC_CREATING_DELAYED
							else
								v65_.recieveUpdates = true
							end
							self:addObject(v65_, v64_)
						else
							v65_:onGhostAdd()
						end
						self.serverConnection.objectsInfo[v64_] = {
							["dirtyMask"] = 0,
							["sync"] = v68_,
							["history"] = {}
						}
						if v58_ then
							self:checkObjectUpdateDebugReadSize(streamId, v60_, v59_, "creation", v65_)
						end
					elseif v61_ == Connection.SEND_INFO_SYNC then
						local v69_ = NetworkUtil.readNodeObjectId(streamId)
						local v70_ = self:getObject(v69_)
						if v70_ == nil then
							return
						end
						v70_:postReadStream(streamId, self.serverConnection)
						self.serverConnection.objectsInfo[v69_].sync = Connection.SYNC_CREATED
						v70_.recieveUpdates = true
						if v58_ then
							self:checkObjectUpdateDebugReadSize(streamId, v60_, v59_, "sync", v70_)
						end
					elseif v61_ == Connection.SEND_INFO_UPDATE then
						local v71_ = self:getObject((NetworkUtil.readNodeObjectId(streamId)))
						if v71_ == nil then
							return
						end
						v71_:readUpdateStream(streamId, timestamp, self.serverConnection)
						v71_:raiseActive()
						if v58_ then
							self:checkObjectUpdateDebugReadSize(streamId, v60_, v59_, "update", v71_)
						end
					else
						local v72_ = self:getObject((NetworkUtil.readNodeObjectId(streamId)))
						if v72_ ~= nil then
							v72_:onGhostRemove()
						end
						if v58_ then
							self:checkObjectUpdateDebugReadSize(streamId, v60_, v59_, "removal", v72_)
						end
					end
				end
				return
			end
			if v46_ == MessageIds.OBJECT_PING then
				self.serverConnection:readUpdateAck(streamId)
				streamWriteUIntN(streamId, MessageIds.OBJECT_ACK, MessageIds.SEND_NUM_BITS)
				self.serverConnection:writeUpdateAck(streamId)
				netSendStream(streamId, "high", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
				return
			end
			if v46_ == MessageIds.OBJECT_ACK then
				self.serverConnection:readUpdateAck(streamId)
				return
			end
			if v46_ == MessageIds.OBJECT_INITIAL_ARRAY then
				self.waitingForObjects = false
				if g_server == nil then
					local v73_ = streamReadBool(streamId)
					local v74_ = streamReadInt32(streamId)
					print("Joined network game (" .. v74_ .. ")")
					for _ = 1, v74_ do
						local v75_, v76_
						if v73_ then
							v75_ = streamGetReadOffset(streamId)
							v76_ = streamReadInt32(streamId)
						else
							v75_ = 0
							v76_ = 0
						end
						local v77_ = streamReadUIntN(streamId, ObjectIds.SEND_NUM_BITS)
						local v78_ = NetworkUtil.readNodeObjectId(streamId)
						local v79_ = ObjectIds.getObjectClassById(v77_)
						local v80_
						if v79_ == nil then
							v80_ = nil
						else
							v80_ = v79_.new(false, true)
							v80_.isManuallyReplicated = false
							v80_.isRegistered = true
						end
						if v80_ == nil then
							printError("Error: Failed to create new object with class id " .. v77_ .. " in initial object array")
							return
						end
						v80_:readStream(streamId, self.serverConnection, v78_)
						self:addObject(v80_, v78_)
						local v81_ = Connection.SYNC_CREATED
						if v80_:getIsDelayedLoaded() then
							v81_ = Connection.SYNC_CREATING_DELAYED
						else
							v80_.recieveUpdates = true
						end
						self.serverConnection.objectsInfo[v78_] = {
							["dirtyMask"] = 0,
							["sync"] = v81_,
							["history"] = {}
						}
						if v73_ then
							local v82_ = streamGetReadOffset(streamId) - (v75_ + 32)
							if v82_ ~= v76_ then
								local v83_ = v80_.configFileName == nil and "" or " (" .. v80_.configFileName .. ")"
								printError("Error: Not all bits read in object create array (" .. v82_ .. " vs " .. v76_ .. "), Class: " .. v79_.className .. v83_)
							end
						end
					end
					g_messageCenter:publish(MessageType.ENQUEUED_ALL_LOADINGS)
				else
					printError("Error: Unexpected packet object created array")
				end
			end
			if v46_ == MessageIds.OBJECT_SERVER_ID then
				local v84_ = NetworkUtil.readNodeObjectId(streamId)
				local v85_ = NetworkUtil.readNodeObjectId(streamId)
				local v86_ = self.tempClientCreatingObjects[v85_]
				streamWriteUIntN(streamId, MessageIds.OBJECT_SERVER_ID_ACK, MessageIds.SEND_NUM_BITS)
				NetworkUtil.writeNodeObjectId(streamId, v84_)
				netSendStream(streamId, "high", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
				if v86_ == nil then
					streamWriteUIntN(self.serverStreamId, MessageIds.OBJECT_DELETED, MessageIds.SEND_NUM_BITS)
					NetworkUtil.writeNodeObjectId(self.serverStreamId, v84_)
					netSendStream(self.serverStreamId, "high", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
				else
					self:finishRegisterObject(v86_, v84_)
					self.tempClientCreatingObjects[v85_] = nil
				end
			end
			if v46_ ~= MessageIds.EVENT then
				if v46_ == MessageIds.EVENT_IDS then
					for _ = 1, streamReadInt32(streamId) do
						local v87_ = streamReadUIntN(streamId, EventIds.SEND_NUM_BITS)
						local v88_ = streamReadString(streamId)
						EventIds.assignEventId(v88_, v87_)
					end
					return
				elseif v46_ == MessageIds.OBJECT_CLASS_IDS then
					for _ = 1, streamReadInt32(streamId) do
						local v89_ = streamReadUIntN(streamId, ObjectIds.SEND_NUM_BITS)
						local v90_ = streamReadString(streamId)
						ObjectIds.assignObjectClassId(v90_, v89_)
					end
				else
					printError("Error: Invalid message id " .. v46_)
				end
			end
			local v91_ = streamReadUIntN(streamId, EventIds.SEND_NUM_BITS)
			local v92_ = EventIds.getEventClassById(v91_)
			if v92_ ~= nil then
				local v93_ = streamReadBool(streamId)
				local v94_, v95_
				if v93_ then
					v94_ = streamGetReadOffset(streamId)
					v95_ = streamReadInt32(streamId)
				else
					v94_ = 0
					v95_ = nil
				end
				local v96_ = v92_.emptyNew()
				v96_:readStream(streamId, self.serverConnection)
				v96_:delete()
				if v93_ then
					local v97_ = streamGetReadOffset(streamId) - (v94_ + 32)
					if v97_ ~= v95_ then
						local v98_ = ClassUtil.getClassNameByObject(v92_)
						printError("Error: Not all bits read in event (" .. v97_ .. " vs " .. v95_ .. "), Class: " .. tostring(v98_))
						return
					end
				end
			end
		else
			if packetType == Network.TYPE_CONNECTION_REQUEST_ACCEPTED then
				streamWriteUIntN(self.serverStreamId, MessageIds.CLIP_COEFF, MessageIds.SEND_NUM_BITS)
				streamWriteFloat32(self.serverStreamId, getViewDistanceCoeff())
				netSendStream(self.serverStreamId, "high", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
				self:connectionRequestAccepted()
				return
			end
			if packetType == Network.TYPE_DISCONNECTION_NOTIFICATION then
				if streamId == self.serverStreamId then
					self.serverStreamId = 0
					self.serverConnection.isConnected = false
					self.serverConnection:setIsReadyForObjects(false)
					self.serverConnection:setIsReadyForEvents(false)
					if self.networkListener ~= nil then
						self.networkListener:onConnectionClosed(self.serverConnection)
						return
					end
				end
			elseif (packetType == Network.TYPE_CONNECTION_ATTEMPT_FAILED or (packetType == Network.TYPE_CONNECTION_LOST or (packetType == Network.TYPE_CONNECTION_BANNED or packetType == Network.TYPE_INVALID_PASSWORD))) and streamId == self.serverStreamId then
				self.serverStreamId = 0
				self.serverConnection.isConnected = false
				self.serverConnection:setIsReadyForObjects(false)
				self.serverConnection:setIsReadyForEvents(false)
				if self.networkListener ~= nil then
					self.networkListener:onConnectionClosed(self.serverConnection)
				end
			end
		end
	end
end

function Client:connectionRequestAccepted()
	if self.networkListener ~= nil then
		self.networkListener:onConnectionAccepted(self.serverConnection)
	end
end

function Client:registerObject(object, alreadySent)
	if not object.isRegistered then
		object.isManuallyReplicated = alreadySent
		object.isRegistered = true
		if alreadySent then
			self.tempClientManuallyRegisteringObjects[object.id] = object
			return
		end
		if g_server ~= nil then
			printError("Error: Client:registerObject not expected")
			printCallstack()
		end
		self.tempClientCreatingObjects[object.id] = object
		streamWriteUIntN(self.serverStreamId, MessageIds.OBJECT_CREATED, MessageIds.SEND_NUM_BITS)
		streamWriteUIntN(self.serverStreamId, object.classId, ObjectIds.SEND_NUM_BITS)
		NetworkUtil.writeNodeObjectId(self.serverStreamId, object.id)
		object:writeStream(self.serverStreamId, self.serverConnection)
		netSendStream(self.serverStreamId, "high", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
	end
end

-- Local values: serverId
function Client:unregisterObject(object, alreadySent)
	if object.isRegistered then
		local v106_ = self:getObjectId(object)
		if v106_ == nil then
			self.tempClientManuallyRegisteringObjects[object.id] = nil
			self.tempClientCreatingObjects[object.id] = nil
		else
			if (alreadySent == nil or not alreadySent) and self.serverStreamId ~= 0 then
				streamWriteUIntN(self.serverStreamId, MessageIds.OBJECT_DELETED, MessageIds.SEND_NUM_BITS)
				NetworkUtil.writeNodeObjectId(self.serverStreamId, v106_)
				netSendStream(self.serverStreamId, "high", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
			end
			self:removeObject(object, v106_)
		end
		object.isRegistered = false
	end
end

function Client:finishRegisterObject(object, serverId)
	self:addObject(object, serverId)
	self.serverConnection.objectsInfo[serverId] = {
		["dirtyMask"] = 0,
		["sync"] = Connection.SYNC_CREATED,
		["history"] = {}
	}
	object.recieveUpdates = true
	self.tempClientManuallyRegisteringObjects[object.id] = nil
	self.tempClientCreatingObjects[object.id] = nil
end

function Client:getServerConnection()
	return self.serverConnection
end
