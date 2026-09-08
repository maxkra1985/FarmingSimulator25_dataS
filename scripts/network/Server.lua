-- Local values: Server_mt
Server = {}
local Server_mt = Class(Server, NetworkNode)
function Server.new()
	-- upvalues: (copy) Server_mt
	local v2_ = NetworkNode.new(Server_mt)
	v2_.clients = {}
	v2_.clientConnections = {}
	v2_.clientPositions = {}
	v2_.clientGuiVisibility = {}
	v2_.clientClipDistCoeffs = {}
	v2_.objects = {}
	v2_.tickRate = 30
	v2_.tickDuration = 1000 / v2_.tickRate
	v2_.tickSum = 0
	v2_.netIsRunning = false
	addConsoleCommand("gsNetworkShowTraffic", "Toggle network traffic visualization", "consoleCommandToggleShowNetworkTraffic", v2_)
	addConsoleCommand("gsNetworkShowTrafficClients", "Toggle client network traffic visualization", "consoleCommandToggleShowNetworkTrafficClients", v2_)
	addConsoleCommand("gsNetworkDebug", "Toggle network debugging", "consoleCommandToggleNetworkDebug", v2_)
	addConsoleCommand("gsNetworkShowObjects", "Toggle network show objects", "consoleCommandToggleNetworkShowObjects", v2_)
	return v2_
end

function Server:delete()
	removeConsoleCommand("gsNetworkShowTraffic")
	removeConsoleCommand("gsNetworkShowTrafficClients")
	removeConsoleCommand("gsNetworkDebug")
	removeConsoleCommand("gsNetworkShowObjects")
	Server:superClass().delete(self)
	self:stop()
end

-- Local values: currentFPS, numClients, maxUploadSize, i, streamId, connection, maxPacketSize, objectsInfo, pendingDeleteObjects, pendingDeleteObjectPacketIds, sendInfos, x, y, z, coeff, isGuiVisible, numObjects, _, object, objectInfo, testScope, updatePriority, testScope, updatePriority, testScope, updatePriority, updatePriority, objectId, clampedFPS, numInfosOffset, numInfosSent, j, oldPacketSize, sendInfo, startOffset, object, infoId, syncState, objectInfo, objectInfo, dirtyMask, objectInfo, endOffset, packetSize, extraInfo, endOffset, _, object
function Server:update(dt, isRunning)
	Server:superClass().update(self, dt)
	if not isRunning then
		return
	end
	self:updateActiveObjects(dt)
	self.tickSum = self.tickSum + dt
	local v7_ = MathUtil.round(1000 / dt, 0)
	local v8_ = self.serverFPS
	self.serverFPS = math.min(v8_, v7_)
	if self.tickSum >= self.tickDuration - 3 then
		local v9_ = #self.clients
		local v10_ = g_maxUploadRatePerClient
		local v11_ = v9_ ~= 0 and g_maxUploadRate / v9_ or g_maxUploadRate
		local v12_ = math.min(v10_, v11_) * 8 * self.tickSum
		if self.networkListener ~= nil then
			self.networkListener:onConnectionsUpdateTick(self.tickSum)
		end
		self:updateActiveObjectsTick(self.tickSum)
		for v13_ = 1, #self.clients do
			local v14_ = self.clients[v13_]
			local v15_ = self.clientConnections[v14_]
			if v15_.isReadyForObjects then
				if v15_:getIsWindowFull() then
					if not v15_.ackPingPacketSent then
						v15_.ackPingPacketSent = true
						streamWriteUIntN(v14_, MessageIds.OBJECT_PING, MessageIds.SEND_NUM_BITS)
						v15_:writeUpdateAck(v14_)
						netSendStream(v14_, "high", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
					end
				else
					v15_:updateSendStats(self.tickSum)
					v15_.ackPingPacketSent = false
					local v16_ = v12_ * v15_.compressionRatio
					self.currentWriteStreamConnection = v15_
					local v17_ = v15_.objectsInfo
					local v18_ = v15_.pendingDeleteObjects
					local v19_ = v15_.pendingDeleteObjectPacketIds
					local v20_ = table.create(30)
					local v21_, v22_, v23_ = self:getClientPosition(v14_)
					local v24_ = self:getClientClipDistCoeff(v14_)
					local v25_ = self:getClientGuiVisibility(v14_)
					local v26_ = 0
					for _, v27_ in pairs(self.objects) do
						local v28_ = v17_[v27_.id]
						if v28_ ~= nil then
							local v29_ = v28_.dirtyMask
							local v30_ = v27_.dirtyMask
							v28_.dirtyMask = bit32.bor(v29_, v30_)
						end
						if v28_ == nil then
							local v31_ = v27_.testScope
							if v31_ == nil or v31_(v27_, v21_, v22_, v23_, v24_, v25_) then
								local v32_ = v27_:getUpdatePriority(2, v21_, v22_, v23_, v24_, v15_, v25_)
								local v33_ = {
									["id"] = Connection.SEND_INFO_CREATE,
									["object"] = v27_,
									["prio"] = v32_
								}
								table.insert(v20_, v33_)
							end
						elseif v28_.sync == Connection.SYNC_LOADED then
							local v34_ = v27_.testScope
							if v34_ == nil or v34_(v27_, v21_, v22_, v23_, v24_, v25_) then
								local v35_ = v27_:getUpdatePriority(2, v21_, v22_, v23_, v24_, v15_)
								local v36_ = {
									["id"] = Connection.SEND_INFO_SYNC,
									["object"] = v27_,
									["prio"] = v35_
								}
								table.insert(v20_, v36_)
							end
						elseif v28_.sync == Connection.SYNC_CREATED then
							local v37_ = v27_.testScope
							if v37_ == nil or v37_(v27_, v21_, v22_, v23_, v24_, v25_) then
								if v28_.dirtyMask == 0 then
									v28_.skipCount = 0
								else
									v28_.skipCount = v28_.skipCount + 1
									local v38_ = v27_:getUpdatePriority(v28_.skipCount, v21_, v22_, v23_, v24_, v15_, v25_)
									local v39_ = {
										["id"] = Connection.SEND_INFO_UPDATE,
										["object"] = v27_,
										["prio"] = v38_
									}
									table.insert(v20_, v39_)
								end
							else
								v28_.skipCount = v28_.skipCount + 1
								local v40_ = v27_:getUpdatePriority(v28_.skipCount, v21_, v22_, v23_, v24_, v15_, v25_)
								local v41_ = {
									["id"] = Connection.SEND_INFO_REMOVE,
									["object"] = v27_,
									["prio"] = v40_
								}
								table.insert(v20_, v41_)
							end
						end
						v26_ = v26_ + 1
					end
					for v42_ in pairs(v18_) do
						local v43_ = {
							["id"] = Connection.SEND_INFO_DELETE,
							["objectId"] = v42_,
							["prio"] = 100
						}
						table.insert(v20_, v43_)
					end
					table.sort(v20_, Server.prioCmp)
					streamWriteTimestamp(v14_)
					streamWriteUIntN(v14_, MessageIds.OBJECT_UPDATE, MessageIds.SEND_NUM_BITS)
					streamWriteInt32(v14_, g_physicsNetworkTime)
					v15_:writeUpdateAck(v14_)
					local v44_ = self.serverFPS
					local v45_ = math.clamp(v44_, 1, 60)
					streamWriteUIntN(v14_, v45_, 6)
					streamWriteBool(v14_, g_networkDebug)
					if self.networkListener ~= nil then
						self.networkListener:onConnectionWriteUpdateStream(v15_, v16_, g_networkDebug)
					end
					local v46_ = streamGetWriteOffset(v14_)
					streamWriteUInt8(v14_, 0)
					local v47_ = #v20_
					local v48_ = math.min(v47_, 255)
					for v49_ = 1, v48_ do
						local v50_ = streamGetWriteOffset(v14_)
						local v51_ = v20_[v49_]
						local v52_
						if g_networkDebug then
							v52_ = streamGetWriteOffset(v14_)
							streamWriteInt32(v14_, 0)
						else
							v52_ = nil
						end
						local v53_ = v51_.object
						local v54_ = v51_.id
						streamWriteUIntN(v14_, v54_, Connection.SEND_INFO_NUM_BITS)
						if v54_ == Connection.SEND_INFO_DELETE then
							NetworkUtil.writeNodeObjectId(v14_, v51_.objectId)
							v18_[v51_.objectId] = nil
							v19_[v51_.objectId] = v15_.lastSeqSent
						elseif v54_ == Connection.SEND_INFO_CREATE then
							streamWriteUIntN(v14_, v53_.classId, ObjectIds.SEND_NUM_BITS)
							NetworkUtil.writeNodeObjectId(v14_, v53_.id)
							v53_:writeStream(v14_, v15_)
							local v55_ = Connection.SYNC_CREATING
							if v53_:getIsDelayedLoaded() then
								v55_ = Connection.SYNC_CREATING_DELAYED
							end
							v17_[v53_.id] = {
								["skipCount"] = 0,
								["dirtyMask"] = 0,
								["sync"] = v55_,
								["history"] = {}
							}
							v17_[v53_.id].history[v15_.lastSeqSent] = {
								["mask"] = 0,
								["sync"] = Connection.SYNC_HIST_CREATE
							}
						elseif v54_ == Connection.SEND_INFO_SYNC then
							local v56_ = v17_[v53_.id]
							NetworkUtil.writeNodeObjectId(v14_, v53_.id)
							v53_:postWriteStream(v14_, v15_)
							v17_[v53_.id].sync = Connection.SYNC_SYNCING
							v56_.history[v15_.lastSeqSent] = {
								["mask"] = 0,
								["sync"] = Connection.SYNC_HIST_SYNC
							}
						elseif v54_ == Connection.SEND_INFO_UPDATE then
							local v57_ = v17_[v53_.id]
							local v58_ = v57_.dirtyMask
							NetworkUtil.writeNodeObjectId(v14_, v53_.id)
							v53_:writeUpdateStream(v14_, v15_, v58_)
							v57_.history[v15_.lastSeqSent] = {
								["mask"] = v58_,
								["sync"] = Connection.SYNC_HIST_UPDATE
							}
							v57_.skipCount = 0
							v57_.dirtyMask = 0
						else
							local v59_ = v17_[v53_.id]
							NetworkUtil.writeNodeObjectId(v14_, v53_.id)
							v59_.sync = Connection.SYNC_REMOVING
							v59_.history[v15_.lastSeqSent] = {
								["mask"] = 0,
								["sync"] = Connection.SYNC_HIST_REMOVE
							}
						end
						if g_networkDebug then
							local v60_ = streamGetWriteOffset(v14_)
							streamSetWriteOffset(v14_, v52_)
							streamWriteInt32(v14_, v60_ - (v52_ + 32))
							streamSetWriteOffset(v14_, v60_)
						end
						local v61_ = streamGetWriteOffset(v14_)
						self:addPacketSize(v15_, self:getObjectPacketType(v53_), (v61_ - v50_) / 8)
						if g_networkDebugPrints and v54_ == Connection.SEND_INFO_UPDATE then
							local v62_ = v53_.configFileName == nil and "" or "(" .. v53_.configFileName .. ")"
							print("  send object " .. v62_ .. ", size " .. (v61_ - v50_) / 8 .. " bytes")
						end
						if v16_ < v61_ then
							v48_ = v49_
							break
						end
					end
					local v63_ = streamGetWriteOffset(v14_)
					streamSetWriteOffset(v14_, v46_)
					streamWriteUInt8(v14_, v48_)
					streamSetWriteOffset(v14_, v63_)
					netSendStream(v14_, "medium", "unreliable_sequenced", NetworkNode.CHANNEL_MAIN, true)
					self.currentWriteStreamConnection = nil
				end
			end
		end
		if self.networkListener ~= nil then
			self.networkListener:onFinishedClientsWriteUpdateStream()
		end
		for _, v64_ in pairs(self.objects) do
			if v64_.dirtyMask ~= 0 then
				v64_:clearDirtyMask()
			end
		end
		self:updatePacketStats(self.tickSum)
		self.tickSum = 0
		self.serverFPS = v7_
	end
end

function Server:startLocal()
	if g_client ~= nil then
		self.clientConnections[NetworkNode.LOCAL_STREAM_ID] = Connection.new(NetworkNode.LOCAL_STREAM_ID, false)
		self.clientConnections[NetworkNode.LOCAL_STREAM_ID]:setIsReadyForObjects(true)
		self.clientConnections[NetworkNode.LOCAL_STREAM_ID]:setIsReadyForEvents(true)
	end
end

function Server:start(serverPort, serverAddress, maxConnections)
	if not self.netIsRunning then
		self.netIsRunning = true
		print("Started network game (" .. serverPort .. ")")
		if not g_connectionManager:startup(serverPort, serverAddress, maxConnections) then
			printError("Error: Failed to startup network. Probably the select port is already in use")
		end
		g_connectionManager:setDefaultListener(Server.packetReceived, self)
		if g_client ~= nil then
			self.clientConnections[NetworkNode.LOCAL_STREAM_ID] = Connection.new(NetworkNode.LOCAL_STREAM_ID, false)
		end
		if g_isDevelopmentVersion then
			CaptionUtil.addText("- Server")
		end
	end
end

function Server:init()
	EventIds.assignEventIds()
	ObjectIds.assignObjectClassIds()
end

-- Local values: streamId, _, connection
function Server:stop()
	if self.netIsRunning then
		for v71_ in ipairs(self.clients) do
			if entityExists(v71_) then
				netCloseConnection(v71_, true, 1)
			end
		end
		self.clients = {}
		for _, v72_ in pairs(self.clientConnections) do
			v72_.isConnected = false
			v72_:setIsReadyForObjects(false)
			v72_:setIsReadyForEvents(false)
		end
		self.clientConnections = {}
		g_connectionManager:shutdown()
		g_connectionManager:setDefaultListener(nil, nil)
		self.netIsRunning = false
	end
end

function Server:closeConnection(connection, disconnectReason)
	if connection.isConnected then
		self:removeStreamFromClients(connection.streamId)
		if self.networkListener ~= nil then
			self.networkListener:onConnectionClosed(connection, disconnectReason)
		end
		if connection.streamId ~= 0 and entityExists(connection.streamId) then
			netCloseConnection(connection.streamId, true, 1)
		end
		connection.streamId = 0
	end
end

-- Local values: messageId, connection, objectsInfo, objectClassId, clientObjectId, objectClass, tempObject, connection, serverObjectId, objectInfo, connection, numObjects, i, serverObjectId, objectInfo, connection, serverObjectId, object, _, connectionI, connection, numObjects, isGuiActive, x, y, z, i, objectId, object, connection, connection, eventId, eventClass, networkDebug, numBits, startOffset, tempEvent, endOffset, readNumBits, className, coeff, _, object, connection, connection, disconnectReason
function Server:packetReceived(packetType, timestamp, streamId)
	Server:superClass().packetReceived(self, packetType, timestamp, streamId)
	if packetType == Network.TYPE_APPLICATION then
		local v80_ = streamReadUIntN(streamId, MessageIds.SEND_NUM_BITS)
		if v80_ == MessageIds.OBJECT_CREATED then
			local v81_ = self.clientConnections[streamId]
			if v81_ ~= nil then
				local v82_ = v81_.objectsInfo
				local v83_ = streamReadUIntN(streamId, ObjectIds.SEND_NUM_BITS)
				local v84_ = NetworkUtil.readNodeObjectId(streamId)
				local v85_ = ObjectIds.getObjectClassById(v83_)
				if v85_ ~= nil then
					local v86_ = v85_.new(true, g_client ~= nil)
					v86_:readStream(streamId, v81_)
					v86_.isManuallyReplicated = false
					v86_.isRegistered = true
					self:addObject(v86_, v86_.id)
					v82_[v86_.id] = {
						["skipCount"] = 0,
						["dirtyMask"] = 0,
						["sync"] = Connection.SYNC_CREATING,
						["history"] = {}
					}
					streamWriteUIntN(streamId, MessageIds.OBJECT_SERVER_ID, MessageIds.SEND_NUM_BITS)
					NetworkUtil.writeNodeObjectId(streamId, v86_.id)
					NetworkUtil.writeNodeObjectId(streamId, v84_)
					netSendStream(streamId, "high", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
					return
				end
			end
		elseif v80_ == MessageIds.OBJECT_SERVER_ID_ACK then
			local v87_ = self.clientConnections[streamId]
			if v87_ ~= nil then
				local v88_ = NetworkUtil.readNodeObjectId(streamId)
				local v89_ = v87_.objectsInfo[v88_]
				if v89_ ~= nil and v89_.sync == Connection.SYNC_CREATING then
					v89_.sync = Connection.SYNC_CREATED
					v87_:sendObjectEventQueue(v89_)
					return
				end
			end
		elseif v80_ == MessageIds.OBJECT_LOADED then
			local v90_ = self.clientConnections[streamId]
			if v90_ ~= nil then
				for _ = 1, streamReadUInt8(streamId) do
					local v91_ = NetworkUtil.readNodeObjectId(streamId)
					local v92_ = v90_.objectsInfo[v91_]
					if v92_ ~= nil and v92_.sync == Connection.SYNC_CREATING_DELAYED then
						v92_.sync = Connection.SYNC_LOADED
					end
				end
				return
			end
		elseif v80_ == MessageIds.OBJECT_DELETED then
			local v93_ = self.clientConnections[streamId]
			if v93_ ~= nil then
				local v94_ = NetworkUtil.readNodeObjectId(streamId)
				local v95_ = self:getObject(v94_)
				if v95_ ~= nil then
					for _, v96_ in pairs(self.clientConnections) do
						v96_:notifyObjectDeleted(v94_, v96_ == v93_)
					end
					self:unregisterObject(v95_, true)
					v95_:delete()
					return
				end
			end
		elseif v80_ == MessageIds.OBJECT_UPDATE then
			local v97_ = self.clientConnections[streamId]
			if v97_ ~= nil then
				v97_:readUpdateAck(streamId)
				local v98_ = streamReadUInt8(streamId)
				local v99_ = streamReadBool(streamId)
				self:setClientPosition(streamId, streamReadFloat32(streamId), streamReadFloat32(streamId), (streamReadFloat32(streamId)))
				self:setClientGuiVisibility(streamId, v99_)
				for v100_ = 1, v98_ do
					local v101_ = NetworkUtil.readNodeObjectId(streamId)
					if v101_ == nil then
						Logging.devError("Server: Unable to retrieve object id for object index %d of %d", v100_, v98_)
						return
					end
					local v102_ = self:getObject(v101_)
					if v102_ == nil then
						Logging.devError("Server: Trying to readUpdateStream from not registered object with id \'%d\'", v101_)
						return
					end
					v102_:readUpdateStream(streamId, timestamp, v97_)
					v102_:raiseActive()
				end
				voiceChatReadClientUpdateFromStream(v97_.streamId, g_clientInterpDelay, v97_.streamId, v97_.lastSeqSent)
				return
			end
		elseif v80_ == MessageIds.OBJECT_PING then
			local v103_ = self.clientConnections[streamId]
			if v103_ ~= nil then
				v103_:readUpdateAck(streamId)
				streamWriteUIntN(streamId, MessageIds.OBJECT_ACK, MessageIds.SEND_NUM_BITS)
				v103_:writeUpdateAck(streamId)
				netSendStream(streamId, "medium", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
				return
			end
		elseif v80_ == MessageIds.OBJECT_ACK then
			local v104_ = self.clientConnections[streamId]
			if v104_ ~= nil then
				v104_:readUpdateAck(streamId)
				return
			end
		else
			if v80_ ~= MessageIds.EVENT then
				if v80_ == MessageIds.CLIP_COEFF then
					local v105_ = streamReadFloat32(streamId)
					self:setClientClipDistCoeff(self.clientConnections[streamId], v105_)
				else
					printError(string.format("Error: Invalid message id \'%s", v80_))
				end
			end
			local v106_ = streamReadUIntN(streamId, EventIds.SEND_NUM_BITS)
			local v107_ = EventIds.getEventClassById(v106_)
			if v107_ == nil then
				Logging.devError("Could not resolve id \'%s\' to an event class", v106_)
				return
			end
			local v108_ = streamReadBool(streamId)
			local v109_, v110_
			if v108_ then
				v109_ = streamGetReadOffset(streamId)
				v110_ = streamReadInt32(streamId)
			else
				v109_ = 0
				v110_ = nil
			end
			local v111_ = v107_.emptyNew()
			v111_:readStream(streamId, self.clientConnections[streamId])
			v111_:delete()
			if v108_ then
				if not entityExists(streamId) then
					Logging.devError("Could not validate read bits because stream was already closed by event \'%s\'", ClassUtil.getClassName(v107_))
					return
				end
				local v112_ = streamGetReadOffset(streamId) - (v109_ + 32)
				if v112_ ~= v110_ then
					local v113_ = ClassUtil.getClassNameByObject(v107_)
					printError("Error: Not all bits read in event (" .. v112_ .. " vs " .. v110_ .. "), Class: " .. tostring(v113_))
					return
				end
			end
		end
	elseif packetType == Network.TYPE_NEW_INCOMING_CONNECTION then
		if self.clientConnections[streamId] == nil then
			local v114_ = self.clients
			table.insert(v114_, streamId)
			self.clientConnections[streamId] = Connection.new(streamId, false)
			for _, v115_ in pairs(self.objects) do
				if v115_.isManuallyReplicated then
					self.clientConnections[streamId].objectsInfo[v115_.id] = {
						["skipCount"] = 0,
						["dirtyMask"] = 0,
						["sync"] = Connection.SYNC_MANUALLY_REGISTERED,
						["manuallyReplicated"] = true,
						["history"] = {}
					}
				end
			end
			if self.networkListener ~= nil then
				self.networkListener:onConnectionOpened(self.clientConnections[streamId])
				return
			end
		end
	elseif packetType == Network.TYPE_DISCONNECTION_NOTIFICATION then
		local v116_ = self.clientConnections[streamId]
		self:removeStreamFromClients(streamId)
		if v116_ ~= nil and self.networkListener ~= nil then
			self.networkListener:onConnectionClosed(v116_, DisconnectReason.PLAYER_LEFT)
			return
		end
	elseif packetType == Network.TYPE_CONNECTION_ATTEMPT_FAILED or (packetType == Network.TYPE_CONNECTION_LOST or (packetType == Network.TYPE_CONNECTION_BANNED or packetType == Network.TYPE_INVALID_PASSWORD)) then
		local v117_ = self.clientConnections[streamId]
		self:removeStreamFromClients(streamId)
		if v117_ ~= nil and self.networkListener ~= nil then
			local v118_ = nil
			if packetType == Network.TYPE_CONNECTION_LOST then
				v118_ = DisconnectReason.PLAYER_LOST_CONNECTION
			elseif packetType == Network.TYPE_CONNECTION_BANNED then
				v118_ = DisconnectReason.BANNED
			end
			self.networkListener:onConnectionClosed(v117_, v118_)
		end
	end
end

-- Local values: i
function Server:removeStreamFromClients(streamId)
	for v121_ = 1, #self.clients do
		if self.clients[v121_] == streamId then
			table.remove(self.clients, v121_)
			break
		end
	end
	if self.clientConnections[streamId] ~= nil then
		self.clientConnections[streamId].isConnected = false
		self.clientConnections[streamId]:setIsReadyForEvents(false)
		self.clientConnections[streamId]:setIsReadyForObjects(false)
		self.clientConnections[streamId] = nil
	end
end

-- Local values: streamId, connection
function Server:registerObject(object, alreadySent)
	if object.isRegistered then
		Logging.warning("Server:registerObject() object %s %d %s already registered", object, object.id, ClassUtil.getClassNameByObject(object))
	else
		object.isRegistered = true
		self:addObject(object, object.id)
		object.isManuallyReplicated = alreadySent
		if alreadySent then
			for v125_, v126_ in pairs(self.clientConnections) do
				if v125_ ~= NetworkNode.LOCAL_STREAM_ID then
					v126_.objectsInfo[object.id] = {
						["skipCount"] = 0,
						["dirtyMask"] = 0,
						["sync"] = Connection.SYNC_MANUALLY_REGISTERED,
						["manuallyReplicated"] = true,
						["history"] = {}
					}
				end
			end
			return
		end
	end
end

-- Local values: objectId, _, connection
function Server:unregisterObject(object, alreadySent)
	if object.isRegistered then
		local v130_ = object.id
		if self.objects[v130_] ~= nil then
			self:removeObject(object, object.id)
			for _, v131_ in pairs(self.clientConnections) do
				v131_:notifyObjectDeleted(v130_, alreadySent)
			end
		end
		object.isRegistered = false
	end
end

-- Local values: connections, streamId, connection
function Server:broadcastEvent(event, sendLocal, ignoreConnection, ghostObject, force, connectionList, allowQueuing)
	local v140_ = connectionList or self.clientConnections
	for v141_, v142_ in pairs(v140_) do
		if (v141_ ~= NetworkNode.LOCAL_STREAM_ID or sendLocal) and (ignoreConnection == nil or v142_ ~= ignoreConnection) then
			if ghostObject == nil or self:hasGhostObject(v142_, ghostObject) then
				self.currentSendEventConnection = v142_
				v142_:sendEvent(event, false, force)
				self.currentSendEventConnection = nil
			elseif ghostObject ~= nil and allowQueuing then
				v142_:queueSendEvent(event, force, ghostObject)
			end
		end
	end
	if event.queueCount == 0 then
		event:delete()
	end
end

-- Local values: streamId, numIds, _, _, className, classObject
function Server:sendEventIds(connection)
	local v144_ = connection.streamId
	streamWriteUIntN(v144_, MessageIds.EVENT_IDS, MessageIds.SEND_NUM_BITS)
	local v145_ = 0
	for _, _ in pairs(EventIds.eventClasses) do
		v145_ = v145_ + 1
	end
	streamWriteInt32(v144_, v145_)
	for v146_, v147_ in pairs(EventIds.eventClasses) do
		streamWriteUIntN(v144_, v147_.eventId, EventIds.SEND_NUM_BITS)
		streamWriteString(v144_, v146_)
	end
	netSendStream(v144_, "high", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
end

-- Local values: streamId, numIds, _, _, className, classObject
function Server:sendObjectClassIds(connection)
	local v149_ = connection.streamId
	streamWriteUIntN(v149_, MessageIds.OBJECT_CLASS_IDS, MessageIds.SEND_NUM_BITS)
	local v150_ = 0
	for _, _ in pairs(ObjectIds.objectClasses) do
		v150_ = v150_ + 1
	end
	streamWriteInt32(v149_, v150_)
	for v151_, v152_ in pairs(ObjectIds.objectClasses) do
		streamWriteUIntN(v149_, v152_.classId, ObjectIds.SEND_NUM_BITS)
		streamWriteString(v149_, v151_)
	end
	netSendStream(v149_, "high", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
end

-- Local values: streamId, objectsInfo, numToSendOffset, numToSend, _, object, testScope, startOffset, syncState, endOffset, endOffset
function Server:sendObjects(connection, x, y, z, viewDistanceCoeff)
	connection:setIsReadyForObjects(false)
	self:setCurrentReliableWriteStreamConnection(connection)
	local v159_ = connection.streamId
	local v160_ = connection.objectsInfo
	streamWriteUIntN(v159_, MessageIds.OBJECT_INITIAL_ARRAY, MessageIds.SEND_NUM_BITS)
	streamWriteBool(v159_, g_networkDebug)
	local v161_ = streamGetWriteOffset(v159_)
	streamWriteInt32(v159_, 0)
	local v162_ = 0
	for _, v163_ in pairs(self.objects) do
		if v160_[v163_.id] == nil and not v163_.isManuallyReplicated then
			local v164_ = v163_.testScope
			if v164_ == nil or v164_(v163_, x, y, z, viewDistanceCoeff, true) then
				v162_ = v162_ + 1
				local v165_
				if g_networkDebug then
					v165_ = streamGetWriteOffset(v159_)
					streamWriteInt32(v159_, 0)
				else
					v165_ = 0
				end
				streamWriteUIntN(v159_, v163_.classId, ObjectIds.SEND_NUM_BITS)
				NetworkUtil.writeNodeObjectId(v159_, v163_.id)
				v163_:writeStream(v159_, connection)
				local v166_ = Connection.SYNC_CREATED
				if v163_:getIsDelayedLoaded() then
					v166_ = Connection.SYNC_CREATING_DELAYED
				end
				v160_[v163_.id] = {
					["skipCount"] = 0,
					["dirtyMask"] = 0,
					["sync"] = v166_,
					["history"] = {}
				}
				if g_networkDebug then
					local v167_ = streamGetWriteOffset(v159_)
					streamSetWriteOffset(v159_, v165_)
					streamWriteInt32(v159_, v167_ - (v165_ + 32))
					streamSetWriteOffset(v159_, v167_)
				end
			end
		end
	end
	local v168_ = streamGetWriteOffset(v159_)
	streamSetWriteOffset(v159_, v161_)
	streamWriteInt32(v159_, v162_)
	streamSetWriteOffset(v159_, v168_)
	netSendStream(v159_, "high", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
	self:setCurrentReliableWriteStreamConnection(nil)
end

function Server:setClientPosition(client, x, y, z)
	if self.clientPositions[client] == nil then
		self.clientPositions[client] = { x, y, z }
	end
	self.clientPositions[client][1] = x
	self.clientPositions[client][2] = y
	self.clientPositions[client][3] = z
end

-- Local values: pos
function Server:getClientPosition(client)
	local v176_ = self.clientPositions[client]
	if v176_ == nil then
		return 0, 0, 0
	else
		return unpack(v176_)
	end
end

function Server:setClientGuiVisibility(client, isGuiVisible)
	if client ~= nil then
		self.clientGuiVisibility[client] = isGuiVisible
	end
end

function Server:getClientGuiVisibility(client)
	if self.clientGuiVisibility[client] == nil then
		return false
	else
		return self.clientGuiVisibility[client]
	end
end

function Server:setClientClipDistCoeff(client, coeff)
	if client ~= nil then
		self.clientClipDistCoeffs[client] = coeff
	end
end

-- Local values: ret
function Server:getClientClipDistCoeff(client)
	local v187_ = self.clientClipDistCoeffs[client]
	return v187_ == nil and 1 or v187_
end

-- Local values: objectInfo
function Server:hasGhostObject(connection, ghostObject)
	if connection:getIsLocal() then
		return true
	end
	local v190_ = connection.objectsInfo[ghostObject.id]
	local v191_
	if v190_ == nil then
		v191_ = false
	else
		v191_ = v190_.sync == Connection.SYNC_CREATED
	end
	return v191_
end

-- Local values: objectInfo
function Server:finishRegisterObject(connection, object)
	local v194_ = connection.objectsInfo[object.id]
	if v194_ ~= nil and v194_.sync == Connection.SYNC_MANUALLY_REGISTERED then
		v194_.sync = Connection.SYNC_CREATED
		connection:sendObjectEventQueue(v194_)
	end
end

function Server:setCurrentReliableWriteStreamConnection(connection)
	self.currentReliableWriteStreamConnection = connection
end

-- Local values: objectInfo
function Server:registerObjectInStream(connection, object)
	if self.currentReliableWriteStreamConnection == connection or self.currentWriteStreamConnection == connection then
		if object:getIsDelayedLoaded() and not object.finishedLoading then
			printError("Error: Server:registerObjectInStream is only allowed for finished delayed loaded objects")
			printCallstack()
		else
			local v200_ = connection.objectsInfo[object.id]
			if v200_ ~= nil and v200_.sync == Connection.SYNC_MANUALLY_REGISTERED then
				if self.currentReliableWriteStreamConnection == connection then
					v200_.sync = Connection.SYNC_CREATED
				else
					v200_.sync = Connection.SYNC_CREATING
					v200_.history[connection.lastSeqSent] = {
						["mask"] = 0,
						["sync"] = Connection.SYNC_HIST_CREATE
					}
				end
				v200_.dirtyMask = 0
				v200_.skipCount = 0
			end
		end
	else
		printError("Error: Server:registerObjectInStream is only allowed in writeStream calls or reliable events on the main channel")
		printCallstack()
		return
	end
end

function Server.prioCmp(w1, w2)
	return w1.prio > w2.prio
end

function Server:consoleCommandToggleNetworkDebug()
	g_networkDebug = not g_networkDebug
	local v203_ = g_networkDebug
	return "NetworkDebug = " .. tostring(v203_)
end
