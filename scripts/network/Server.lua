Server = {}
local Server_mt = Class(Server, NetworkNode)
function Server.new()
	local self = NetworkNode.new(Server_mt)
	self.clients = {}
	self.clientConnections = {}
	self.clientPositions = {}
	self.clientGuiVisibility = {}
	self.clientClipDistCoeffs = {}
	self.objects = {}
	self.tickRate = 30
	self.tickDuration = 1000 / self.tickRate
	self.tickSum = 0
	self.netIsRunning = false
	addConsoleCommand("gsNetworkShowTraffic", "Toggle network traffic visualization", "consoleCommandToggleShowNetworkTraffic", self)
	addConsoleCommand("gsNetworkShowTrafficClients", "Toggle client network traffic visualization", "consoleCommandToggleShowNetworkTrafficClients", self)
	addConsoleCommand("gsNetworkDebug", "Toggle network debugging", "consoleCommandToggleNetworkDebug", self)
	addConsoleCommand("gsNetworkShowObjects", "Toggle network show objects", "consoleCommandToggleNetworkShowObjects", self)
	return self
end
function Server:delete()
	removeConsoleCommand("gsNetworkShowTraffic")
	removeConsoleCommand("gsNetworkShowTrafficClients")
	removeConsoleCommand("gsNetworkDebug")
	removeConsoleCommand("gsNetworkShowObjects")
	Server:superClass().delete(self)
	self:stop()
end
function Server:update(dt, isRunning)
	Server:superClass().update(self, dt)
	if not isRunning then
		return
	else
		self:updateActiveObjects(dt)
		self.tickSum = self.tickSum + dt
		local currentFPS = MathUtil.round(1000 / dt, 0)
		self.serverFPS = math.min(self.serverFPS, currentFPS)
		if self.tickDuration - 3 <= self.tickSum then
			local numClients = #self.clients
			local maxUploadSize = math.min(g_maxUploadRatePerClient, numClients ~= 0 and g_maxUploadRate / numClients or g_maxUploadRate) * 8 * self.tickSum
			if self.networkListener ~= nil then
				self.networkListener:onConnectionsUpdateTick(self.tickSum)
			end
			self:updateActiveObjectsTick(self.tickSum)
			for i = 1, #self.clients do
				local streamId = self.clients[i]
				local connection = self.clientConnections[streamId]
				if connection.isReadyForObjects then
					if connection:getIsWindowFull() then
						if connection.ackPingPacketSent then
							continue
						end
						connection.ackPingPacketSent = true
						streamWriteUIntN(streamId, MessageIds.OBJECT_PING, MessageIds.SEND_NUM_BITS)
						connection:writeUpdateAck(streamId)
						netSendStream(streamId, "high", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
					else
						connection:updateSendStats(self.tickSum)
						connection.ackPingPacketSent = false
						local maxPacketSize = maxUploadSize * connection.compressionRatio
						self.currentWriteStreamConnection = connection
						local objectsInfo = connection.objectsInfo
						local pendingDeleteObjects = connection.pendingDeleteObjects
						local pendingDeleteObjectPacketIds = connection.pendingDeleteObjectPacketIds
						local sendInfos = table.create(30)
						local x, y, z = self:getClientPosition(streamId)
						local coeff = self:getClientClipDistCoeff(streamId)
						local isGuiVisible = self:getClientGuiVisibility(streamId)
						local numObjects = 0
						for _, object in pairs(self.objects) do
							local objectInfo = objectsInfo[object.id]
							if objectInfo ~= nil then
								objectInfo.dirtyMask = bit32.bor(objectInfo.dirtyMask, object.dirtyMask)
							end
							if objectInfo == nil then
								local testScope = object.testScope
								if testScope == nil or testScope(object, x, y, z, coeff, isGuiVisible) then
									local updatePriority = object:getUpdatePriority(2, x, y, z, coeff, connection, isGuiVisible)
									table.insert(sendInfos, { object = object, prio = updatePriority, id = Connection.SEND_INFO_CREATE })
								end
							elseif objectInfo.sync == Connection.SYNC_LOADED then
								local testScope = object.testScope
								if testScope == nil or testScope(object, x, y, z, coeff, isGuiVisible) then
									local updatePriority = object:getUpdatePriority(2, x, y, z, coeff, connection)
									table.insert(sendInfos, { object = object, prio = updatePriority, id = Connection.SEND_INFO_SYNC })
								end
							elseif objectInfo.sync == Connection.SYNC_CREATED then
								local testScope = object.testScope
								if testScope == nil or testScope(object, x, y, z, coeff, isGuiVisible) then
									if objectInfo.dirtyMask ~= 0 then
										objectInfo.skipCount = objectInfo.skipCount + 1
										local updatePriority = object:getUpdatePriority(objectInfo.skipCount, x, y, z, coeff, connection, isGuiVisible)
										table.insert(sendInfos, { object = object, prio = updatePriority, id = Connection.SEND_INFO_UPDATE })
									else
										objectInfo.skipCount = 0
									end
								else
									objectInfo.skipCount = objectInfo.skipCount + 1
									local updatePriority = object:getUpdatePriority(objectInfo.skipCount, x, y, z, coeff, connection, isGuiVisible)
									table.insert(sendInfos, { object = object, prio = updatePriority, id = Connection.SEND_INFO_REMOVE })
								end
							end
							numObjects = numObjects + 1
						end
						for objectId in pairs(pendingDeleteObjects) do
							table.insert(sendInfos, { objectId = objectId, id = Connection.SEND_INFO_DELETE, prio = 100 })
						end
						table.sort(sendInfos, Server.prioCmp)
						streamWriteTimestamp(streamId)
						streamWriteUIntN(streamId, MessageIds.OBJECT_UPDATE, MessageIds.SEND_NUM_BITS)
						streamWriteInt32(streamId, g_physicsNetworkTime)
						connection:writeUpdateAck(streamId)
						local clampedFPS = math.clamp(self.serverFPS, 1, 60)
						streamWriteUIntN(streamId, clampedFPS, 6)
						streamWriteBool(streamId, g_networkDebug)
						if self.networkListener ~= nil then
							self.networkListener:onConnectionWriteUpdateStream(connection, maxPacketSize, g_networkDebug)
						end
						local numInfosOffset = streamGetWriteOffset(streamId)
						streamWriteUInt8(streamId, 0)
						local numInfosSent = math.min(#sendInfos, 255)
						for j = 1, numInfosSent do
							local oldPacketSize = streamGetWriteOffset(streamId)
							local sendInfo = sendInfos[j]
							local startOffset = nil
							if g_networkDebug then
								startOffset = streamGetWriteOffset(streamId)
								streamWriteInt32(streamId, 0)
							end
							local object = sendInfo.object
							local infoId = sendInfo.id
							streamWriteUIntN(streamId, infoId, Connection.SEND_INFO_NUM_BITS)
							if infoId == Connection.SEND_INFO_DELETE then
								NetworkUtil.writeNodeObjectId(streamId, sendInfo.objectId)
								pendingDeleteObjects[sendInfo.objectId] = nil
								pendingDeleteObjectPacketIds[sendInfo.objectId] = connection.lastSeqSent
							elseif infoId == Connection.SEND_INFO_CREATE then
								streamWriteUIntN(streamId, object.classId, ObjectIds.SEND_NUM_BITS)
								NetworkUtil.writeNodeObjectId(streamId, object.id)
								object:writeStream(streamId, connection)
								local syncState = Connection.SYNC_CREATING
								if object:getIsDelayedLoaded() then
									syncState = Connection.SYNC_CREATING_DELAYED
								end
								objectsInfo[object.id] = { skipCount = 0, dirtyMask = 0, sync = syncState, history = {} }
								objectsInfo[object.id].history[connection.lastSeqSent] = { mask = 0, sync = Connection.SYNC_HIST_CREATE }
							elseif infoId == Connection.SEND_INFO_SYNC then
								local objectInfo = objectsInfo[object.id]
								NetworkUtil.writeNodeObjectId(streamId, object.id)
								object:postWriteStream(streamId, connection)
								objectsInfo[object.id].sync = Connection.SYNC_SYNCING
								objectInfo.history[connection.lastSeqSent] = { mask = 0, sync = Connection.SYNC_HIST_SYNC }
							elseif infoId == Connection.SEND_INFO_UPDATE then
								local objectInfo = objectsInfo[object.id]
								local dirtyMask = objectInfo.dirtyMask
								NetworkUtil.writeNodeObjectId(streamId, object.id)
								object:writeUpdateStream(streamId, connection, dirtyMask)
								objectInfo.history[connection.lastSeqSent] = { mask = dirtyMask, sync = Connection.SYNC_HIST_UPDATE }
								objectInfo.skipCount = 0
								objectInfo.dirtyMask = 0
							else
								local objectInfo = objectsInfo[object.id]
								NetworkUtil.writeNodeObjectId(streamId, object.id)
								objectInfo.sync = Connection.SYNC_REMOVING
								objectInfo.history[connection.lastSeqSent] = { mask = 0, sync = Connection.SYNC_HIST_REMOVE }
							end
							if g_networkDebug then
								local endOffset = streamGetWriteOffset(streamId)
								streamSetWriteOffset(streamId, startOffset)
								streamWriteInt32(streamId, endOffset - (startOffset + 32))
								streamSetWriteOffset(streamId, endOffset)
							end
							local packetSize = streamGetWriteOffset(streamId)
							self:addPacketSize(connection, self:getObjectPacketType(object), (packetSize - oldPacketSize) / 8)
							if g_networkDebugPrints and infoId == Connection.SEND_INFO_UPDATE then
								local extraInfo = ""
								if object.configFileName ~= nil then
									extraInfo = "(" .. object.configFileName .. ")"
								end
								print("  send object " .. extraInfo .. ", size " .. (packetSize - oldPacketSize) / 8 .. " bytes")
							end
							if maxPacketSize < packetSize then
								numInfosSent = j
								break
							end
						end
						local endOffset = streamGetWriteOffset(streamId)
						streamSetWriteOffset(streamId, numInfosOffset)
						streamWriteUInt8(streamId, numInfosSent)
						streamSetWriteOffset(streamId, endOffset)
						netSendStream(streamId, "medium", "unreliable_sequenced", NetworkNode.CHANNEL_MAIN, true)
						self.currentWriteStreamConnection = nil
					end
				end
			end
			if self.networkListener ~= nil then
				self.networkListener:onFinishedClientsWriteUpdateStream()
			end
			for _, object in pairs(self.objects) do
				if object.dirtyMask == 0 then
					continue
				end
				object:clearDirtyMask()
			end
			self:updatePacketStats(self.tickSum)
			self.tickSum = 0
			self.serverFPS = currentFPS
		end
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
function Server:stop()
	if self.netIsRunning then
		for streamId in ipairs(self.clients) do
			if entityExists(streamId) then
				netCloseConnection(streamId, true, 1)
			end
		end
		self.clients = {}
		for _, connection in pairs(self.clientConnections) do
			connection.isConnected = false
			connection:setIsReadyForObjects(false)
			connection:setIsReadyForEvents(false)
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
function Server:packetReceived(packetType, timestamp, streamId)
	Server:superClass().packetReceived(self, packetType, timestamp, streamId)
	if packetType == Network.TYPE_APPLICATION then
		local messageId = streamReadUIntN(streamId, MessageIds.SEND_NUM_BITS)
		if messageId == MessageIds.OBJECT_CREATED then
			local connection = self.clientConnections[streamId]
			if connection ~= nil then
				local objectsInfo = connection.objectsInfo
				local objectClassId = streamReadUIntN(streamId, ObjectIds.SEND_NUM_BITS)
				local clientObjectId = NetworkUtil.readNodeObjectId(streamId)
				local objectClass = ObjectIds.getObjectClassById(objectClassId)
				if objectClass ~= nil then
					local tempObject = objectClass.new(true, g_client ~= nil)
					tempObject:readStream(streamId, connection)
					tempObject.isManuallyReplicated = false
					tempObject.isRegistered = true
					self:addObject(tempObject, tempObject.id)
					objectsInfo[tempObject.id] = { skipCount = 0, dirtyMask = 0, sync = Connection.SYNC_CREATING, history = {} }
					streamWriteUIntN(streamId, MessageIds.OBJECT_SERVER_ID, MessageIds.SEND_NUM_BITS)
					NetworkUtil.writeNodeObjectId(streamId, tempObject.id)
					NetworkUtil.writeNodeObjectId(streamId, clientObjectId)
					netSendStream(streamId, "high", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
				end
			end
		elseif messageId == MessageIds.OBJECT_SERVER_ID_ACK then
			local connection = self.clientConnections[streamId]
			if connection ~= nil then
				local serverObjectId = NetworkUtil.readNodeObjectId(streamId)
				local objectInfo = connection.objectsInfo[serverObjectId]
				if objectInfo ~= nil and objectInfo.sync == Connection.SYNC_CREATING then
					objectInfo.sync = Connection.SYNC_CREATED
					connection:sendObjectEventQueue(objectInfo)
				end
			end
		elseif messageId == MessageIds.OBJECT_LOADED then
			local connection = self.clientConnections[streamId]
			if connection ~= nil then
				local numObjects = streamReadUInt8(streamId)
				for i = 1, numObjects do
					local serverObjectId = NetworkUtil.readNodeObjectId(streamId)
					local objectInfo = connection.objectsInfo[serverObjectId]
					if objectInfo == nil then
						continue
					end
					if objectInfo.sync == Connection.SYNC_CREATING_DELAYED then
						objectInfo.sync = Connection.SYNC_LOADED
					end
				end
			end
		elseif messageId == MessageIds.OBJECT_DELETED then
			local connection = self.clientConnections[streamId]
			if connection ~= nil then
				local serverObjectId = NetworkUtil.readNodeObjectId(streamId)
				local object = self:getObject(serverObjectId)
				if object ~= nil then
					for _, connectionI in pairs(self.clientConnections) do
						connectionI:notifyObjectDeleted(serverObjectId, connectionI == connection)
					end
					self:unregisterObject(object, true)
					object:delete()
				end
			end
		elseif messageId == MessageIds.OBJECT_UPDATE then
			local connection = self.clientConnections[streamId]
			if connection ~= nil then
				connection:readUpdateAck(streamId)
				local numObjects = streamReadUInt8(streamId)
				local isGuiActive = streamReadBool(streamId)
				local x = streamReadFloat32(streamId)
				local y = streamReadFloat32(streamId)
				local z = streamReadFloat32(streamId)
				self:setClientPosition(streamId, x, y, z)
				self:setClientGuiVisibility(streamId, isGuiActive)
				for i = 1, numObjects do
					local objectId = NetworkUtil.readNodeObjectId(streamId)
					if objectId == nil then
						Logging.devError("Server: Unable to retrieve object id for object index %d of %d", i, numObjects)
						return
					end
					local object = self:getObject(objectId)
					if object == nil then
						Logging.devError("Server: Trying to readUpdateStream from not registered object with id '%d'", objectId)
						return
					end
					object:readUpdateStream(streamId, timestamp, connection)
					object:raiseActive()
				end
				voiceChatReadClientUpdateFromStream(connection.streamId, g_clientInterpDelay, connection.streamId, connection.lastSeqSent)
			end
		elseif messageId == MessageIds.OBJECT_PING then
			local connection = self.clientConnections[streamId]
			if connection ~= nil then
				connection:readUpdateAck(streamId)
				streamWriteUIntN(streamId, MessageIds.OBJECT_ACK, MessageIds.SEND_NUM_BITS)
				connection:writeUpdateAck(streamId)
				netSendStream(streamId, "medium", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
			end
		elseif messageId == MessageIds.OBJECT_ACK then
			local connection = self.clientConnections[streamId]
			if connection ~= nil then
				connection:readUpdateAck(streamId)
			end
		elseif messageId == MessageIds.EVENT then
			local eventId = streamReadUIntN(streamId, EventIds.SEND_NUM_BITS)
			local eventClass = EventIds.getEventClassById(eventId)
			if eventClass ~= nil then
				local networkDebug = streamReadBool(streamId)
				local numBits = nil
				local startOffset = 0
				if networkDebug then
					startOffset = streamGetReadOffset(streamId)
					numBits = streamReadInt32(streamId)
				end
				local tempEvent = eventClass.emptyNew()
				tempEvent:readStream(streamId, self.clientConnections[streamId])
				tempEvent:delete()
				if networkDebug then
					if entityExists(streamId) then
						local endOffset = streamGetReadOffset(streamId)
						local readNumBits = endOffset - (startOffset + 32)
						if readNumBits ~= numBits then
							local className = ClassUtil.getClassNameByObject(eventClass)
							printError("Error: Not all bits read in event (" .. readNumBits .. " vs " .. numBits .. "), Class: " .. tostring(className))
						end
					else
						Logging.devError("Could not validate read bits because stream was already closed by event '%s'", ClassUtil.getClassName(eventClass))
					end
				end
			else
				Logging.devError("Could not resolve id '%s' to an event class", eventId)
			end
		else
			if messageId == MessageIds.CLIP_COEFF then
				local coeff = streamReadFloat32(streamId)
				self:setClientClipDistCoeff(self.clientConnections[streamId], coeff)
			else
				printError(string.format("Error: Invalid message id '%s", messageId))
			end
		end
	elseif packetType == Network.TYPE_NEW_INCOMING_CONNECTION then
		if self.clientConnections[streamId] == nil then
			table.insert(self.clients, streamId)
			self.clientConnections[streamId] = Connection.new(streamId, false)
			for _, object in pairs(self.objects) do
				if object.isManuallyReplicated then
					self.clientConnections[streamId].objectsInfo[object.id] = { skipCount = 0, dirtyMask = 0, sync = Connection.SYNC_MANUALLY_REGISTERED, manuallyReplicated = true, history = {} }
				end
			end
			if self.networkListener ~= nil then
				self.networkListener:onConnectionOpened(self.clientConnections[streamId])
			end
		end
	elseif packetType == Network.TYPE_DISCONNECTION_NOTIFICATION then
		local connection = self.clientConnections[streamId]
		self:removeStreamFromClients(streamId)
		if connection ~= nil and self.networkListener ~= nil then
			self.networkListener:onConnectionClosed(connection, DisconnectReason.PLAYER_LEFT)
		end
	elseif packetType == Network.TYPE_CONNECTION_ATTEMPT_FAILED or packetType == Network.TYPE_CONNECTION_LOST or packetType == Network.TYPE_CONNECTION_BANNED or packetType == Network.TYPE_INVALID_PASSWORD then
		local connection = self.clientConnections[streamId]
		self:removeStreamFromClients(streamId)
		if connection ~= nil and self.networkListener ~= nil then
			local disconnectReason = nil
			if packetType == Network.TYPE_CONNECTION_LOST then
				disconnectReason = DisconnectReason.PLAYER_LOST_CONNECTION
			elseif packetType == Network.TYPE_CONNECTION_BANNED then
				disconnectReason = DisconnectReason.BANNED
			end
			self.networkListener:onConnectionClosed(connection, disconnectReason)
		end
	end
end
function Server:removeStreamFromClients(streamId)
	for i = 1, #self.clients do
		if self.clients[i] == streamId then
			table.remove(self.clients, i)
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
function Server:registerObject(object, alreadySent)
	if not object.isRegistered then
		object.isRegistered = true
		self:addObject(object, object.id)
		object.isManuallyReplicated = alreadySent
		if alreadySent then
			for streamId, connection in pairs(self.clientConnections) do
				if streamId == NetworkNode.LOCAL_STREAM_ID then
					continue
				end
				connection.objectsInfo[object.id] = { skipCount = 0, dirtyMask = 0, sync = Connection.SYNC_MANUALLY_REGISTERED, manuallyReplicated = true, history = {} }
			end
		end
	else
		Logging.warning("Server:registerObject() object %s %d %s already registered", object, object.id, ClassUtil.getClassNameByObject(object))
	end
end
function Server:unregisterObject(object, alreadySent)
	if object.isRegistered then
		local objectId = object.id
		if self.objects[objectId] ~= nil then
			self:removeObject(object, object.id)
			for _, connection in pairs(self.clientConnections) do
				connection:notifyObjectDeleted(objectId, alreadySent)
			end
		end
		object.isRegistered = false
	end
end
function Server:broadcastEvent(event, sendLocal, ignoreConnection, ghostObject, force, connectionList, allowQueuing)
	local connections = connectionList or self.clientConnections
	for streamId, connection in pairs(connections) do
		if (streamId ~= NetworkNode.LOCAL_STREAM_ID or sendLocal) and (ignoreConnection == nil or connection ~= ignoreConnection) then
			if ghostObject == nil or self:hasGhostObject(connection, ghostObject) then
				self.currentSendEventConnection = connection
				connection:sendEvent(event, false, force)
				self.currentSendEventConnection = nil
			else
				if ghostObject == nil then
					continue
				end
				if allowQueuing then
					connection:queueSendEvent(event, force, ghostObject)
				end
			end
		end
	end
	if event.queueCount == 0 then
		event:delete()
	end
end
function Server:sendEventIds(connection)
	local streamId = connection.streamId
	streamWriteUIntN(streamId, MessageIds.EVENT_IDS, MessageIds.SEND_NUM_BITS)
	local numIds = 0
	for _, _ in pairs(EventIds.eventClasses) do
		numIds = numIds + 1
	end
	streamWriteInt32(streamId, numIds)
	for className, classObject in pairs(EventIds.eventClasses) do
		streamWriteUIntN(streamId, classObject.eventId, EventIds.SEND_NUM_BITS)
		streamWriteString(streamId, className)
	end
	netSendStream(streamId, "high", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
end
function Server:sendObjectClassIds(connection)
	local streamId = connection.streamId
	streamWriteUIntN(streamId, MessageIds.OBJECT_CLASS_IDS, MessageIds.SEND_NUM_BITS)
	local numIds = 0
	for _, _ in pairs(ObjectIds.objectClasses) do
		numIds = numIds + 1
	end
	streamWriteInt32(streamId, numIds)
	for className, classObject in pairs(ObjectIds.objectClasses) do
		streamWriteUIntN(streamId, classObject.classId, ObjectIds.SEND_NUM_BITS)
		streamWriteString(streamId, className)
	end
	netSendStream(streamId, "high", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
end
function Server:sendObjects(connection, x, y, z, viewDistanceCoeff)
	connection:setIsReadyForObjects(false)
	self:setCurrentReliableWriteStreamConnection(connection)
	local streamId = connection.streamId
	local objectsInfo = connection.objectsInfo
	streamWriteUIntN(streamId, MessageIds.OBJECT_INITIAL_ARRAY, MessageIds.SEND_NUM_BITS)
	streamWriteBool(streamId, g_networkDebug)
	local numToSendOffset = streamGetWriteOffset(streamId)
	streamWriteInt32(streamId, 0)
	local numToSend = 0
	for _, object in pairs(self.objects) do
		if objectsInfo[object.id] == nil then
			if object.isManuallyReplicated then
				continue
			end
			local testScope = object.testScope
			if testScope == nil or testScope(object, x, y, z, viewDistanceCoeff, true) then
				numToSend = numToSend + 1
				local startOffset = 0
				if g_networkDebug then
					startOffset = streamGetWriteOffset(streamId)
					streamWriteInt32(streamId, 0)
				end
				streamWriteUIntN(streamId, object.classId, ObjectIds.SEND_NUM_BITS)
				NetworkUtil.writeNodeObjectId(streamId, object.id)
				object:writeStream(streamId, connection)
				local syncState = Connection.SYNC_CREATED
				if object:getIsDelayedLoaded() then
					syncState = Connection.SYNC_CREATING_DELAYED
				end
				objectsInfo[object.id] = { skipCount = 0, dirtyMask = 0, sync = syncState, history = {} }
				if g_networkDebug then
					local endOffset = streamGetWriteOffset(streamId)
					streamSetWriteOffset(streamId, startOffset)
					streamWriteInt32(streamId, endOffset - (startOffset + 32))
					streamSetWriteOffset(streamId, endOffset)
				end
			end
		end
	end
	local endOffset = streamGetWriteOffset(streamId)
	streamSetWriteOffset(streamId, numToSendOffset)
	streamWriteInt32(streamId, numToSend)
	streamSetWriteOffset(streamId, endOffset)
	netSendStream(streamId, "high", "reliable_ordered", NetworkNode.CHANNEL_MAIN, true)
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
function Server:getClientPosition(client)
	local pos = self.clientPositions[client]
	if pos ~= nil then
		return unpack(pos)
	else
		return 0, 0, 0
	end
end
function Server:setClientGuiVisibility(client, isGuiVisible)
	if client ~= nil then
		self.clientGuiVisibility[client] = isGuiVisible
	end
end
function Server:getClientGuiVisibility(client)
	if self.clientGuiVisibility[client] ~= nil then
		return self.clientGuiVisibility[client]
	else
		return false
	end
end
function Server:setClientClipDistCoeff(client, coeff)
	if client ~= nil then
		self.clientClipDistCoeffs[client] = coeff
	end
end
function Server:getClientClipDistCoeff(client)
	local ret = self.clientClipDistCoeffs[client]
	if ret == nil then
		ret = 1
	end
	return ret
end
function Server:hasGhostObject(connection, ghostObject)
	if connection:getIsLocal() then
		return true
	else
		local objectInfo = connection.objectsInfo[ghostObject.id]
		return objectInfo ~= nil and objectInfo.sync == Connection.SYNC_CREATED
	end
end
function Server:finishRegisterObject(connection, object)
	local objectInfo = connection.objectsInfo[object.id]
	if objectInfo ~= nil and objectInfo.sync == Connection.SYNC_MANUALLY_REGISTERED then
		objectInfo.sync = Connection.SYNC_CREATED
		connection:sendObjectEventQueue(objectInfo)
	end
end
function Server:setCurrentReliableWriteStreamConnection(connection)
	self.currentReliableWriteStreamConnection = connection
end
function Server:registerObjectInStream(connection, object)
	if self.currentReliableWriteStreamConnection ~= connection and self.currentWriteStreamConnection ~= connection then
		printError("Error: Server:registerObjectInStream is only allowed in writeStream calls or reliable events on the main channel")
		printCallstack()
		return
	end
	if object:getIsDelayedLoaded() and not object.finishedLoading then
		printError("Error: Server:registerObjectInStream is only allowed for finished delayed loaded objects")
		printCallstack()
		return
	end
	local objectInfo = connection.objectsInfo[object.id]
	if objectInfo ~= nil and objectInfo.sync == Connection.SYNC_MANUALLY_REGISTERED then
		if self.currentReliableWriteStreamConnection == connection then
			objectInfo.sync = Connection.SYNC_CREATED
		else
			objectInfo.sync = Connection.SYNC_CREATING
			objectInfo.history[connection.lastSeqSent] = { mask = 0, sync = Connection.SYNC_HIST_CREATE }
		end
		objectInfo.dirtyMask = 0
		objectInfo.skipCount = 0
	end
end
function Server.prioCmp(w1, w2)
	if w2.prio < w1.prio then
		return true
	else
		return false
	end
end
function Server:consoleCommandToggleNetworkDebug()
	g_networkDebug = not g_networkDebug
	return "NetworkDebug = " .. tostring(g_networkDebug)
end
