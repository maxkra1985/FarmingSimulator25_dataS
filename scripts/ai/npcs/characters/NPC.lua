NPC = {}
NPC.CONVERSATION_INDEX_SEND_NUM_BITS = 8
NPC.CONVERSATION_ITEM_INDEX_SEND_NUM_BITS = 8
NPC.CONVERSATION_OPTION_INDEX_SEND_NUM_BITS = 8
NPC.VOICEOVER_PLAYBACK_DELAY_MS = 500
NPC.VOICEOVER_DURATION_PER_WORD_MS = 350
local NPC_mt = Class(NPC, Object)
InitStaticObjectClass(NPC, "NPC")
g_xmlManager:addCreateSchemaFunction(function()
	NPC.xmlSchema = XMLSchema.new("npc")
end)
g_xmlManager:addInitSchemaFunction(function()
	local schema = NPC.xmlSchema
	schema:register(XMLValueType.STRING, "npc.class", "NPC controller class name", "NPC", false)
	schema:register(XMLValueType.STRING, "npc.filename", "NPC filename", nil, true)
	schema:register(XMLValueType.STRING, "npc.title", "NPC title", nil, true)
	schema:register(XMLValueType.STRING, "npc.imageFilename", "NPC image", nil, true)
	schema:register(XMLValueType.STRING, "npc.conversations.conversation(?)", "NPC conversation files", nil, true)
	schema:register(XMLValueType.STRING, "npc.conversations.conversation(?)#uniqueId", "NPC conversation unique id", nil, true)
	SoundManager.registerSampleXMLPaths(schema, "npc.sounds", "voice")
	SoundManager.registerSampleXMLPaths(schema, "npc.sounds", "phone")
	schema:register(XMLValueType.NODE_INDEX, "npc.interactionTrigger#node", "NPC interaction trigger node", nil, true)
	PlayerStyle.registerSavegameXMLPaths(schema, "npc.playerStyle")
	I3DUtil.registerI3dMappingXMLPaths(schema, "npc")
	local savegameSchema = NPCManager.xmlSchemaSavegame
	local savegameKey = "npcs.npc(?)"
	savegameSchema:register(XMLValueType.BOOL, "npcs.npc(?)" .. "#isActive", "If the npc is active")
	savegameSchema:register(XMLValueType.STRING, "npcs.npc(?)" .. "#spotUniqueId", "Id of the current npc spot")
	local playerKey = "npcs.npc(?)" .. ".player(?)"
	savegameSchema:register(XMLValueType.STRING, playerKey .. "#uniqueUserId")
	savegameSchema:register(XMLValueType.INT, playerKey .. "#numContacts")
	savegameSchema:register(XMLValueType.STRING, playerKey .. ".conversation(?)#uniqueId")
	NPCConversation.registerSavegameXMLPaths(savegameSchema, playerKey .. ".conversation(?)")
	NPCSpot.registerSavegameXMLPaths(savegameSchema, "npcs.spots.spot(?)")
end)
function NPC.new(isServer, isClient, customMt)
	local self = Object.new(isServer, isClient, customMt or NPC_mt)
	self.name = "Unknown NPC"
	self.title = "Unknown NPC"
	self.filename = nil
	self.imageFilename = nil
	self.finishedMissions = 0
	self.clipDistance = 100
	self.components = {}
	self.i3dMappings = {}
	self.isPlayerInRange = false
	self.spot = nil
	self.isActive = false
	self.x = 0
	self.y = 0
	self.z = 0
	self.rotX = 0
	self.rotY = 0
	self.rotZ = 0
	self.distanceToCamera = 0
	self.conversations = {}
	self.idToConversation = {}
	self.typeToConversations = {}
	self.filenameToConversation = {}
	self.availableConversations = {}
	self.inputData = ConversationInputData.new()
	self.currentConversationPlayerObjectId = nil
	self.isInConversation = false
	self.isInFacialAnimationConversation = false
	self.isPhoneConversation = false
	self.rotationSpeed = 0.006283185307179587
	self.farmData = {}
	self.userData = {}
	self.playerGraphics = HumanGraphicsComponent.new()
	self.playerGraphics.defaultState.isNPC = true
	self.playerGraphics:setIsFacialAnimationEnabled(true)
	self.playerGraphics:setSoundsEnabled(false)
	self.mapHotspot = NPCHotspot.new(self)
	self.dirtyFlag = self:getNextDirtyFlag()
	g_messageCenter:subscribe(MessageType.USER_REMOVED, self.onUserRemoved, self)
	g_messageCenter:subscribe(MessageType.APP_SUSPENDED, self.onForceCancelConversation, self)
	return self
end
function NPC:load(xmlFilename)
	self.xmlFile = XMLFile.load("NPC", xmlFilename, NPC.xmlSchema)
	if self.xmlFile == nil then
		return false
	end
	self.xmlFilename = xmlFilename
	local customEnv, baseDirectory = Utils.getModNameAndBaseDirectory(self.xmlFile:getFilename())
	self.baseDirectory = baseDirectory
	local title = self.xmlFile:getValue("npc.title")
	if title ~= nil then
		self.title = g_i18n:convertText(title, customEnv)
		local imageFilename = self.xmlFile:getValue("npc.imageFilename")
		if imageFilename ~= nil then
			self.imageFilename = Utils.getFilename(imageFilename, baseDirectory)
			local i3dFilename = self.xmlFile:getValue("npc.filename")
			if i3dFilename ~= nil then
				self.i3dFilename = Utils.getFilename(i3dFilename, baseDirectory)
				self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.i3dFilename, true, true, self.onI3DFileLoaded, self, nil)
				self.playerGraphics:initialize()
				link(getRootNode(), self.playerGraphics.graphicsRootNode)
				local playerStyle = PlayerStyle.new()
				playerStyle:loadFromXMLFile(self.xmlFile, "npc.playerStyle")
				self.playerStyle = playerStyle
				self.playerGraphics:setStyleAsync(playerStyle, self.loadCharacterFinished, self, {})
				for _, conversationKey in self.xmlFile:iterator("npc.conversations.conversation") do
					local uniqueId = self.xmlFile:getValue(conversationKey .. "#uniqueId")
					if uniqueId == nil then
						Logging.xmlWarning(self.xmlFile, "Missing uniqueId for conversation '%s'", conversationKey)
					elseif self.idToConversation[uniqueId] ~= nil then
						Logging.xmlWarning(self.xmlFile, "UniqueId '%s' already used for conversation '%s'", uniqueId, conversationKey)
					else
						local conversationXMLFilename = self.xmlFile:getValue(conversationKey)
						if conversationXMLFilename ~= nil then
							local systemConversationXMLFilename = Utils.getFilename(conversationXMLFilename, baseDirectory)
							local conversation = NPCUtil.createConversationFromXML(self, systemConversationXMLFilename, uniqueId)
							if conversation == nil then
								continue
							end
							table.insert(self.conversations, conversation)
							conversation:setIndex(#self.conversations)
							self.idToConversation[uniqueId] = conversation
							self.filenameToConversation[conversationXMLFilename] = conversation
							local typeId = conversation:getType()
							if self.typeToConversations[typeId] == nil then
								self.typeToConversations[typeId] = {}
							end
							table.insert(self.typeToConversations[typeId], conversation)
						else
							Logging.xmlWarning(self.xmlFile, "No config file found for npc conversation '%s'", conversationKey)
						end
					end
				end
				return true
			else
				Logging.xmlWarning(self.xmlFile, "Missing i3dFilename for npc!")
				self.xmlFile:delete()
				self.xmlFile = nil
				return false
			end
		else
			Logging.xmlWarning(self.xmlFile, "Missing imageFilename for npc!")
			self.xmlFile:delete()
			self.xmlFile = nil
			return false
		end
	else
		Logging.xmlWarning(self.xmlFile, "Missing title for npc!")
		self.xmlFile:delete()
		self.xmlFile = nil
		return false
	end
end
function NPC:writeStream(streamId, connection)
	NPC:superClass().writeStream(self, streamId, connection)
	if streamWriteBool(streamId, self.spot ~= nil) then
		streamWriteFloat32(streamId, self.x)
		streamWriteFloat32(streamId, self.y)
		streamWriteFloat32(streamId, self.z)
		streamWriteFloat32(streamId, self.rotX)
		streamWriteFloat32(streamId, self.rotY)
		streamWriteFloat32(streamId, self.rotZ)
	end
	local currentConversation = self.currentConversation
	if streamWriteBool(streamId, currentConversation ~= nil and self.currentConversationPlayerObjectId ~= nil) then
		NetworkUtil.writeNodeObjectId(streamId, self.currentConversationPlayerObjectId)
		streamWriteUIntN(streamId, currentConversation:getIndex(), NPC.CONVERSATION_INDEX_SEND_NUM_BITS)
		streamWriteBool(streamId, self.isInFacialAnimationConversation)
		streamWriteBool(streamId, self.isPhoneConversation)
	end
end
function NPC:readStream(streamId, connection, objectId)
	NPC:superClass().readStream(self, streamId, connection, objectId)
	if streamReadBool(streamId) then
		self.x = streamReadFloat32(streamId)
		self.y = streamReadFloat32(streamId)
		self.z = streamReadFloat32(streamId)
		self.rotX = streamReadFloat32(streamId)
		self.rotY = streamReadFloat32(streamId)
		self.rotZ = streamReadFloat32(streamId)
		self.isActive = true
	end
	if streamReadBool(streamId) then
		local playerNetworkId = NetworkUtil.readNodeObjectId(streamId)
		local conversationIndex = streamReadUIntN(streamId, NPC.CONVERSATION_INDEX_SEND_NUM_BITS)
		local useFacialAnimation = streamReadBool(streamId)
		local isPhoneConversation = streamReadBool(streamId)
		self:onConversationStarted(playerNetworkId, conversationIndex, useFacialAnimation, isPhoneConversation)
	end
end
function NPC:writeUpdateStream(streamId, connection, dirtyMask)
	NPC:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	if streamWriteBool(streamId, self.spot ~= nil) then
		streamWriteFloat32(streamId, self.x)
		streamWriteFloat32(streamId, self.y)
		streamWriteFloat32(streamId, self.z)
		streamWriteFloat32(streamId, self.rotX)
		streamWriteFloat32(streamId, self.rotY)
		streamWriteFloat32(streamId, self.rotZ)
	end
end
function NPC:readUpdateStream(streamId, timestamp, connection)
	NPC:superClass().readUpdateStream(self, streamId, timestamp, connection)
	self.isActive = streamReadBool(streamId)
	if self.isActive then
		self.x = streamReadFloat32(streamId)
		self.y = streamReadFloat32(streamId)
		self.z = streamReadFloat32(streamId)
		self.rotX = streamReadFloat32(streamId)
		self.rotY = streamReadFloat32(streamId)
		self.rotZ = streamReadFloat32(streamId)
	end
	self:updatePosition()
end
function NPC:loadCharacterFinished(loadingState, arguments)
	if loadingState ~= HumanModelLoadingState.OK then
		if loadingState == HumanModelLoadingState.CANCELED then
			Logging.info("Loading player model canceled")
		else
			Logging.error("Loading player model failed")
		end
		self.playerGraphics:delete()
		self.playerGraphics = nil
	else
		self.playerGraphics:defaultAllParameters()
		self:updatePosition()
	end
end
function NPC:onI3DFileLoaded(node, failedReason, args)
	if failedReason == LoadI3DFailedReason.NONE then
		link(getRootNode(), node)
		self.node = node
		setClipDistance(node, self.clipDistance)
		I3DUtil.loadI3DComponents(node, self.components)
		I3DUtil.loadI3DMapping(self.xmlFile, "npc", self.components, self.i3dMappings)
		local mission = g_currentMission
		if mission:getIsClient() then
			self.samples = {}
			self.samples.voice = g_soundManager:loadSampleFromXML(self.xmlFile, "npc.sounds", "voice", self.baseDirectory, self.components, 1, AudioGroup.CHARACTER, self.i3dMappings, self, false)
			self.samples.phone = g_soundManager:loadSample2DFromXML(self.xmlFile, "npc.sounds", "phone", "", 1, AudioGroup.CHARACTER, false)
		end
		local triggerNode = self.xmlFile:getValue("npc.interactionTrigger#node", nil, self.components, self.i3dMappings)
		self.interactionTriggerNode = triggerNode
		self.interactionTriggerCallbackId = addTrigger(triggerNode, "onInteractionCallback", self, false, self.onInteractionCallback)
		self.activatable = NPCActivatable.new(self)
		self:updatePosition()
	end
	if self.xmlFile ~= nil then
		self.xmlFile:delete()
		self.xmlFile = nil
	end
end
function NPC:saveToSavegameXMLFile(xmlFile, key)
	if self.spot ~= nil then
		xmlFile:setValue(key .. "#spotUniqueId", self.spot:getUniqueId())
	end
	local userIndex = 0
	for uniqueUserId, userData in pairs(self.userData) do
		local userKey = string.format("%s.player(%d)", key, userIndex)
		xmlFile:setValue(userKey .. "#uniqueUserId", uniqueUserId)
		xmlFile:setValue(userKey .. "#numContacts", userData.numContacts or 0)
		local conversationIndex = 0
		for conversationUniqueId, conversationData in pairs(userData.conversations) do
			local conversation = self:getConversationById(conversationUniqueId)
			local conversationKey = string.format("%s.conversation(%d)", userKey, conversationIndex)
			xmlFile:setValue(conversationKey .. "#uniqueId", conversationUniqueId)
			conversation:saveToSavegameXMLFile(xmlFile, conversationKey, conversationData)
			conversationIndex = conversationIndex + 1
		end
		userIndex = userIndex + 1
	end
end
function NPC:loadFromSavegameXMLFile(xmlFile, key)
	local spotUniqueId = xmlFile:getValue(key .. "#spotUniqueId")
	if spotUniqueId ~= nil then
		self.pendingSpotUniqueId = spotUniqueId
	end
	local mission = g_currentMission
	local playerSystem = mission.playerSystem
	for _, userKey in xmlFile:iterator(key .. ".player") do
		local uniqueUserId = xmlFile:getValue(userKey .. "#uniqueUserId")
		local hasUser = playerSystem:getHasPlayerWithUniqueId(uniqueUserId)
		if hasUser == nil then
			continue
		end
		local userData = {}
		userData.numContacts = xmlFile:getValue(userKey .. "#numContacts", 0)
		userData.conversations = {}
		for _, conversationKey in xmlFile:iterator(userKey .. ".conversation") do
			local conversationUniqueId = xmlFile:getValue(conversationKey .. "#uniqueId")
			local conversation = self:getConversationById(conversationUniqueId)
			if conversation == nil then
				continue
			end
			local conversationData = {}
			conversation:loadFromSavegameXMLFile(xmlFile, conversationKey, conversationData)
			if next(conversationData) == nil then
				continue
			end
			userData.conversations[conversationUniqueId] = conversationData
		end
		if next(userData.conversations) == nil then
			continue
		end
		self.userData[uniqueUserId] = userData
	end
	return true
end
function NPC:delete()
	g_messageCenter:unsubscribeAll(self)
	for _, conversation in ipairs(self.conversations) do
		conversation:delete()
	end
	if self.interactionTriggerCallbackId ~= nil then
		removeTrigger(self.interactionTriggerNode, self.interactionTriggerCallbackId)
	end
	if self.samples ~= nil then
		g_soundManager:deleteSamples(self.samples)
	end
	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
		self.sharedLoadRequestId = nil
	end
	if self.node ~= nil then
		delete(self.node)
		self.node = nil
	end
	if self.xmlFile ~= nil then
		self.xmlFile:delete()
		self.xmlFile = nil
	end
	if self.mapHotspot ~= nil then
		self.mapHotspot:delete()
	end
	self.inputData:delete()
	if self.playerGraphics ~= nil then
		self.playerGraphics:delete()
		self.playerGraphics = nil
	end
	if self.playerStyle ~= nil then
		self.playerStyle:delete()
		self.playerStyle = nil
	end
	self.isPlayerInRange = false
	local mission = g_currentMission
	mission.activatableObjectsSystem:removeActivatable(self.activatable)
end
function NPC:update(dt)
	if self.pendingSpotUniqueId ~= nil then
		local spot = g_npcManager:getSpotByUniqueId(self.pendingSpotUniqueId)
		if spot ~= nil then
			self:setSpot(spot)
			self.forceUpdate = true
		end
		self.pendingSpotUniqueId = nil
	end
	if self.needPositionUpdate then
		local playerGraphics = self.playerGraphics
		if playerGraphics ~= nil and (self.forceUpdate or self.clipDistance < self.distanceToCamera or not playerGraphics:getIsInCameraFrustum()) then
			self:updatePosition()
			self.needPositionUpdate = false
			self.forceUpdate = false
		end
		self:raiseActive()
	end
	if self.pendingConversationItemIndex ~= nil then
		self:showConversationItem(self.pendingConversationItemIndex, self.pendingConversationDisabledOptionIndices)
		self.pendingConversationItemIndex = nil
		self.pendingConversationDisabledOptionIndices = nil
	end
	if self.playerGraphics ~= nil then
		self.playerGraphics:defaultAllParameters()
		self.playerGraphics:update(dt)
		local player = self:getInteractingPlayer() or g_localPlayer
		if player ~= nil and self.node ~= nil then
			local px, _, pz = player:getPosition()
			local x, _, z = getWorldTranslation(self.node)
			local length = MathUtil.vector2Length(px - x, pz - z)
			if 0 < length then
				local dirX, dirZ = MathUtil.vector2Normalize(px - x, pz - z)
				local currentRotation = self.playerGraphics:getModelYaw()
				local lastRotation = currentRotation
				local targetRotation = MathUtil.getYRotationFromDirection(dirX, dirZ)
				targetRotation = MathUtil.normalizeRotationForShortestPath(targetRotation, currentRotation)
				if currentRotation < targetRotation then
					currentRotation = math.min(currentRotation + dt * self.rotationSpeed, targetRotation)
				else
					currentRotation = math.max(currentRotation - dt * self.rotationSpeed, targetRotation)
				end
				local difference = MathUtil.getAngleDifference(currentRotation, lastRotation)
				self.playerGraphics.defaultState.rotationVelocity = difference
				self.playerGraphics:setModelYaw(currentRotation)
			end
		end
		if NPCManager.DEBUG_ANIMATIONS then
			self.playerGraphics.animation:debugDraw(0.025, 0.95, 0.014)
		end
	end
	local player = self:getInteractingPlayer()
	if player ~= nil and (player == g_localPlayer and (self:getIsInFacialAnimationConversation() and not self:getIsPhoneConversation())) then
		player:updateWhileInConversation(dt, self)
	end
end
function NPC:getName()
	return self.name
end
function NPC:getImageFilename()
	return self.imageFilename
end
function NPC:getBeVisited()
	return self.spot ~= nil
end
function NPC:getTeleportWorldPosition()
	if self.spot ~= nil then
		local distance = 4
		if self.spot.node ~= nil then
			return localToWorld(self.spot.node, 0, 0, 4)
		else
			local dirX, dirZ = MathUtil.getDirectionFromYRotation(self.rotY)
			local x = self.x + dirX * 4
			local z = self.z + dirZ * 4
			return x, self.y, z
		end
	end
	return nil
end
function NPC:getTeleportWorldRotation()
	if self.spot ~= nil then
		local _ = nil
		local rotY = self.rotY
		if self.spot.node ~= nil then
			_, rotY, _ = getWorldRotation(self.spot.node)
		end
		return rotY + 3.141592653589793
	else
		return nil
	end
end
function NPC:getMapHotspot()
	return self.mapHotspot
end
function NPC:getTitle()
	return self.title
end
function NPC:getConversationByFilename(filename)
	return self.filenameToConversation[filename]
end
function NPC:getConversationById(uniqueId)
	return self.idToConversation[uniqueId]
end
function NPC:updatePosition()
	if self.isActive then
		addToPhysics(self.node)
		if self.node ~= nil then
			setWorldTranslation(self.node, self.x, self.y, self.z)
			setWorldRotation(self.node, self.rotX, self.rotY, self.rotZ)
		end
		if self.playerGraphics ~= nil then
			self.playerGraphics:setModelPosition(self.x, self.y, self.z)
			self.playerGraphics:setModelRotation(self.rotX, self.rotY, self.rotZ)
		end
	elseif self.node ~= nil then
		removeFromPhysics(self.node)
	end
	self:updateVisibility()
	if self.isServer then
		self:raiseDirtyFlags(self.dirtyFlag)
	end
end
function NPC:setSpot(spot)
	local wasChanged = self.spot ~= spot
	self.spot = spot
	self.isActive = spot ~= nil
	if spot ~= nil then
		local x, y, z = spot:getPosition()
		local rotX, rotY, rotZ = spot:getRotation()
		if not wasChanged then
			if 0.01 < math.abs(x - self.x) or 0.01 < math.abs(y - self.y) or 0.01 < math.abs(z - self.z) then
				wasChanged = true
			end
			if not wasChanged and (0.001 < math.abs(rotX - self.rotX) or 0.001 < math.abs(rotY - self.rotY) or 0.001 < math.abs(rotZ - self.rotZ)) then
				wasChanged = true
			end
		end
		self.x = x
		self.y = y
		self.z = z
		self.rotX = rotX
		self.rotY = rotY
		self.rotZ = rotZ
		self:addHotspots()
		self.mapHotspot:setWorldPosition(self.x, self.z)
	else
		self:removeHotspot()
	end
	if wasChanged then
		self:raiseActive()
		self.needPositionUpdate = true
	end
end
function NPC:getSpot()
	return self.spot
end
function NPC:getPosition()
	return self.x, self.y, self.z
end
function NPC:getPositionOffset(offsetX, offsetY, offsetZ)
	if self.node == nil then
		return offsetX, offsetY, offsetZ
	else
		return localToWorld(self.node, offsetX, offsetY, offsetZ)
	end
end
function NPC:getIsActive()
	return self.isActive
end
function NPC:onInteractionCallback(triggerId, otherId, onEnter, onLeave, onStay)
	local player = g_localPlayer
	if self.isActive and (player ~= nil and otherId == player.rootNode) then
		local mission = g_currentMission
		if onEnter then
			self.isPlayerInRange = true
			mission.activatableObjectsSystem:addActivatable(self.activatable)
			return
		end
		if onLeave then
			self.isPlayerInRange = false
			mission.activatableObjectsSystem:removeActivatable(self.activatable)
		end
	end
end
function NPC:getCanInteract()
	if g_guidedTourManager:getIsTourRunning() and self.nextConversation == nil then
		return false
	end
	if self.isRequestPending then
		return false
	elseif self.isInConversation then
		return false
	elseif self.currentConversationPlayerObjectId ~= nil then
		return false
	elseif not self.isActive then
		return false
	else
		return 0 < #self.conversations
	end
end
function NPC:getFacingDirection()
	if self.playerGraphics ~= nil then
		return self.playerGraphics:getModelDirection()
	else
		return 0, 0, 1
	end
end
function NPC:getIsPlayerInRange()
	return self.isPlayerInRange
end
function NPC:getFarmData(farm)
	self.farmData[farm.farmId] = self.farmData[farm.farmId] or {}
	return self.farmData[farm.farmId]
end
function NPC:getInteractingPlayer()
	if self.currentConversationPlayerObjectId == nil then
		return nil
	else
		local player = NetworkUtil.getObject(self.currentConversationPlayerObjectId)
		return player
	end
end
function NPC:getConversationByIndex(index)
	return self.conversations[index]
end
function NPC:getIsInConversation()
	return self.isInConversation
end
function NPC:getIsInFacialAnimationConversation()
	return self.isInFacialAnimationConversation
end
function NPC:getIsPhoneConversation()
	return self.isPhoneConversation
end
function NPC:getCurrentConversation()
	return self.currentConversation
end
function NPC:getIsFirstContact(player)
	if player == nil then
		return false
	end
	local uniqueUserId = player:getUniqueUserId()
	local userData = self.userData[uniqueUserId]
	if userData == nil then
		return true
	else
		local numContacts = userData.numContacts
		return numContacts == 0
	end
end
function NPC:resetConversationNumTriggeredByType(player, typeId)
	if player == nil then
		return
	end
	local userData = self.userData[player:getUniqueUserId()]
	if userData == nil then
		return
	else
		local conversations = self.typeToConversations[typeId]
		for _, conversation in ipairs(conversations) do
			local conversationData = userData.conversations[conversation:getUniqueId()]
			if conversationData == nil then
				continue
			end
			conversationData.numTriggered = 0
		end
	end
end
function NPC:getWasConversationTriggered(player, uniqueId)
	if player == nil then
		return false
	end
	local userData = self.userData[player:getUniqueUserId()]
	if userData == nil then
		return false
	else
		return userData.conversations[uniqueId] ~= nil
	end
end
function NPC:getConversationNumTriggered(player, uniqueId)
	if player == nil then
		return nil
	end
	local userData = self.userData[player:getUniqueUserId()]
	if userData == nil then
		return 0
	end
	local conversationData = userData.conversations[uniqueId]
	if conversationData == nil then
		return 0
	else
		return conversationData.numTriggered
	end
end
function NPC:getRandomConversation(player, typeId, uniqueIds)
	local conversations = self.conversations
	local typeName = nil
	if typeId ~= nil then
		typeName = NPCConversationType.getName(typeId)
		if typeName == nil then
			Logging.devInfo("NPCConversationType not defined for id '%s'", typeId)
			return nil
		end
		conversations = self.typeToConversations[typeId]
		if conversations == nil then
			Logging.devInfo("No conversations defined for type '%s'", NPCConversationType.getName(typeId))
			return nil
		end
	end
	return self:getRandomConversationFromList(player, conversations)
end
function NPC:getRandomConversationFromUniqueIds(player, uniqueIds)
	local conversations = {}
	for _, uniqueId in ipairs(uniqueIds) do
		local conversation = self.idToConversation[uniqueId]
		table.insert(conversations, conversation)
	end
	return self:getRandomConversationFromList(player, conversations)
end
function NPC:getRandomConversationFromList(player, conversations)
	local availableConversations = {}
	local userData = self.userData[player:getUniqueUserId()]
	for _, conversation in ipairs(conversations) do
		conversation:init(player)
		local conversationUserData = nil
		if userData ~= nil then
			conversationUserData = userData.conversations[conversation:getUniqueId()]
		end
		if conversation:getIsAvailable(player, conversationUserData) then
			table.insert(availableConversations, conversation)
		end
	end
	if #availableConversations == 0 then
		Logging.devInfo("No conversations available")
		return nil
	else
		table.sort(availableConversations, function(a, b)
			return a:compare(b)
		end)
		local probabilityBasedConversations = {}
		local lastWeight = availableConversations[1]:getWeight()
		for k, availableConversation in ipairs(availableConversations) do
			local weight = availableConversation:getWeight()
			if lastWeight == weight then
				for i = 1, availableConversation:getProbability() do
					table.insert(probabilityBasedConversations, availableConversation)
				end
			end
		end
		local conversationIndex = math.random(1, #probabilityBasedConversations)
		local conversation = probabilityBasedConversations[conversationIndex]
		return conversation
	end
end
function NPC:setNextConversation(conversation, finishCallback)
	self.nextConversation = conversation
	self.finishCallback = finishCallback
end
function NPC:setFollowUpConversation(conversation)
	assert(g_server ~= nil, "NPC.setFollowUpConversation is a server-only function")
	self.followUpConversation = conversation
end
function NPC:requestConversation(player)
	if player == nil then
		Logging.devInfo("NPC.requestConversation: no player  given")
	elseif not self.isServer then
		if self.isRequestPending then
			Logging.devInfo("NPC.requestConversation: request is already pending")
		else
			self.isRequestPending = true
			g_client:getServerConnection():sendEvent(NPCConversationRequestEvent.new(self, player))
		end
	else
		local playerObjectId = NetworkUtil.getObjectId(player)
		if self.currentConversationPlayerObjectId ~= nil then
			if playerObjectId ~= self.currentConversationPlayerObjectId then
				player.connection:sendEvent(NPCConversationStartFailedEvent.new(self, NPCConversationFailedState.FAILED_REASON_NPC_BUSY))
			end
			return
		end
		self.inputData:reset()
		local conversation = self.nextConversation
		if conversation == nil then
			if self:getIsFirstContact(player) then
				conversation = self:getRandomConversation(player, NPCConversationType.FIRST_CONTACT)
			end
			if conversation == nil then
				conversation = self:getRandomConversation(player, NPCConversationType.INTRO)
			end
			if conversation == nil then
				conversation = self:getRandomConversation(player, NPCConversationType.DEFAULT)
			end
		end
		if conversation == nil then
			player.connection:sendEvent(NPCConversationStartFailedEvent.new(self, NPCConversationFailedState.FAILED_REASON_NO_CONVERSATION_AVAILABLE))
		else
			self:startConversation(player, conversation, true, false)
		end
	end
end
function NPC:startConversation(player, conversation, useFacialAnimation, isPhoneConversation)
	assert(g_server ~= nil, "NPC:startConversation is a server only function")
	if player == nil then
		Logging.devInfo("NPC.startConversation: no player  given")
		return
	end
	useFacialAnimation = Utils.getNoNil(useFacialAnimation, true)
	isPhoneConversation = Utils.getNoNil(isPhoneConversation, false)
	if conversation == self.nextConversation then
		self.nextConversation = nil
	end
	conversation:loadTexts()
	local conversationItem = conversation:getConversationItemByIndex(1)
	if conversationItem == nil then
		player.connection:sendEvent(NPCConversationStartFailedEvent.new(self, NPCConversationFailedState.FAILED_REASON_NO_CONVERSATION_ITEMS))
		Logging.warning("NPC.startConversation: No text items defined for conversation '%s'", conversation.xmlFilename)
		conversation:unloadTexts()
	else
		Logging.devInfo("NPC.startConversation: Talking to NPC '%s'. Start Conversation '%s'", self:getName(), conversation.xmlFilename)
		local conversationId = conversation:getUniqueId()
		local userData = self.userData[player:getUniqueUserId()] or { numContacts = 0, conversations = {} }
		local conversationUserData = userData.conversations[conversationId] or {}
		self.currentConversation = conversation
		self.currentConversationPlayerObjectId = NetworkUtil.getObjectId(player)
		conversation:start(player, conversationUserData)
		conversationItem:activate()
		userData.numContacts = userData.numContacts + 1
		if next(conversationUserData) ~= nil then
			userData.conversations[conversationId] = conversationUserData
			self.userData[player:getUniqueUserId()] = userData
		end
		local conversationIndex = conversation:getIndex()
		local disabledOptionIndices = {}
		if conversationItem.options ~= nil then
			for k, option in ipairs(conversationItem.options) do
				if option.isActive then
					if option.prerequisites == nil then
						continue
					end
					for _, optionPrerequisite in ipairs(option.prerequisites) do
						if optionPrerequisite:getIsValid(player) then
							continue
						end
						table.insert(disabledOptionIndices, k)
					end
				else
					table.insert(disabledOptionIndices, k)
				end
			end
		end
		g_server:broadcastEvent(NPCConversationStartEvent.new(self, player, conversationIndex, 1, disabledOptionIndices, useFacialAnimation, isPhoneConversation), true)
	end
end
function NPC:onConversationStarted(playerNetworkId, conversationIndex, useFacialAnimation, isPhoneConversation)
	self.isRequestPending = false
	local conversation = self:getConversationByIndex(conversationIndex)
	if conversation == nil then
		Logging.devWarning("NPC.onConversationStarted: Unknown conversation with index '%s'", conversationIndex)
	else
		self.currentConversation = conversation
		self.currentConversationPlayerObjectId = playerNetworkId
		if not self.isInConversation then
			self.isInConversation = true
			self:startFacialAnimation(useFacialAnimation, isPhoneConversation)
		end
		Logging.devInfo("NPC.onConversationStarted: Started conversion '%s' with player '%s'", conversationIndex, playerNetworkId)
		conversation:loadTexts()
	end
end
function NPC:onConversationShowItem(conversationItemIndex, disabledOptionIndices)
	self.isRequestPending = false
	if self.currentConversation == nil then
		Logging.devWarning("NPC.onConversationShowItem: No conversation started")
	else
		self.pendingConversationItemIndex = conversationItemIndex
		self.pendingConversationDisabledOptionIndices = disabledOptionIndices
		self:raiseActive()
	end
end
function NPC:processAnswer(connection, conversationItemIndex, optionIndex)
	assert(g_server ~= nil, "NPC.processAnswer is a server-only function")
	local conversation = self.currentConversation
	if conversation == nil then
		self:resetConversation()
		Logging.warning("NPC.processAnswer: No conversation started")
		return
	end
	local player = self:getInteractingPlayer()
	if player.connection ~= connection then
		Logging.devWarning("NPC.processAnswer: Recieved answer from invalid user connection")
		return
	end
	local conversationItem = conversation:getConversationItemByIndex(conversationItemIndex)
	if conversationItem == nil then
		self:resetConversation()
		Logging.devWarning("NPC.processAnswer: Unknown conversation item with index '%s'", conversationItemIndex)
		return
	end
	local nextId = nil
	if optionIndex == nil or optionIndex == 0 then
		local options = conversationItem:getOptions()
		if optionIndex == 0 and (options ~= nil and 0 < #options) then
			Logging.devWarning("NPC.processAnswer: Recieved optionIndex 0 but conversation item has options defined!")
		end
		nextId = conversationItem:getNextId()
		local followUpConversation = self.followUpConversation
		local isPhoneConversation = self:getIsPhoneConversation()
		local isFacialAnimationConversation = self:getIsInFacialAnimationConversation()
		if nextId == nil then
			self:finishConversation(followUpConversation ~= nil)
			if followUpConversation ~= nil then
				self.followUpConversation = nil
				self:startConversation(player, followUpConversation, isFacialAnimationConversation, isPhoneConversation)
			end
			return
		end
		local nextConversationItem = conversation:getConversationItemById(nextId)
		if nextConversationItem == nil then
			self:resetConversation()
			Logging.warning("NPC.processAnswer: Unknown conversation item with id '%s'", nextId)
			return
		else
			nextConversationItem:activate()
			local disabledOptionIndices = {}
			if nextConversationItem.options ~= nil then
				for k, option in ipairs(nextConversationItem.options) do
					if option.isActive then
						if option.prerequisites == nil then
							continue
						end
						for _, optionPrerequisite in ipairs(option.prerequisites) do
							if optionPrerequisite:getIsValid(player) then
								continue
							end
							table.insert(disabledOptionIndices, k)
						end
					else
						table.insert(disabledOptionIndices, k)
					end
				end
			end
			g_server:broadcastEvent(NPCConversationItemShowEvent.new(self, nextConversationItem:getIndex(), disabledOptionIndices), true)
			return
		end
	end
	local option = conversationItem:getOptionByIndex(optionIndex)
	if option == nil then
		self:resetConversation()
		Logging.warning("NPC.processAnswer: Unknown conversation item option with index '%s'", optionIndex)
		return
	end
	conversationItem:activateOption(optionIndex)
	nextId = option.nextId
end
function NPC:onFailedToStartConversation(failedReason)
	self.isRequestPending = false
	Logging.devInfo("Failed to start conversation", failedReason)
end
function NPC:showConversationItem(conversationItemIndex, conversationDisabledOptionIndices)
	local conversation = self.currentConversation
	if conversation == nil then
		self:resetConversation()
		Logging.warning("NPC.showConversationItem: No conversation started")
		return
	end
	local conversationItem = conversation:getConversationItemByIndex(conversationItemIndex)
	if conversationItem == nil then
		self:resetConversation()
		Logging.warning("NPC.showConversationItem: Unknown conversation item with index '%s'", conversationItemIndex)
		return
	end
	local player = self:getInteractingPlayer()
	if player == nil then
		Logging.warning("NPC.showConversationItem: Player not available/synched")
		return
	end
	conversationItem:init()
	local text = conversationItem:getText()
	local plainText = text:getPlainText()
	local optionTexts = {}
	local optionTextMapping = {}
	local options = conversationItem:getOptions()
	if options ~= nil then
		local blockedOptionIndex = {}
		for _, index in ipairs(conversationDisabledOptionIndices) do
			blockedOptionIndex[index] = true
		end
		for k, option in ipairs(options) do
			if blockedOptionIndex[k] == nil then
				table.insert(optionTexts, option.text:getPlainText())
				optionTextMapping[#optionTexts] = k
			end
		end
	end
	local args = {}
	args.conversationItem = conversationItem
	args.conversationIndex = conversation:getIndex()
	args.conversationItemIndex = conversationItemIndex
	args.conversationOptionTextMapping = optionTextMapping
	local dialogDuration = 2000
	if conversationItem:getIsActive() then
		local audioFilename = text:getAudioFilename()
		if audioFilename ~= nil then
			local sample = nil
			if self:getIsPhoneConversation() then
				if self.samples.phone ~= nil then
					g_soundManager:createAudio2d(self.samples.phone, audioFilename)
					g_soundManager:playSample(self.samples.phone, NPC.VOICEOVER_PLAYBACK_DELAY_MS)
					dialogDuration = self.samples.phone.duration + NPC.VOICEOVER_PLAYBACK_DELAY_MS * 2
					sample = self.samples.phone
				end
			elseif self.samples.voice ~= nil then
				g_soundManager:createAudioSource(self.samples.voice, audioFilename)
				g_soundManager:playSample(self.samples.voice, NPC.VOICEOVER_PLAYBACK_DELAY_MS)
				dialogDuration = self.samples.voice.duration + NPC.VOICEOVER_PLAYBACK_DELAY_MS * 2
				sample = self.samples.voice
			end
			if self:getIsInFacialAnimationConversation() and (self.playerGraphics ~= nil and self.playerGraphics.facialAnimation ~= nil) then
				local lookAtNode = nil
				if player ~= nil then
					local currentVehicle = player:getCurrentVehicle()
					if currentVehicle ~= nil then
						local enterable = currentVehicle.spec_enterable
						if enterable ~= nil then
							for _, camera in ipairs(enterable.cameras) do
								if camera.isInside then
									lookAtNode = camera.cameraNode
									self.playerGraphics.facialAnimation:start(text:getEmotionFilename(), sample, plainText, lookAtNode)
									if 0 < #optionTexts then
										dialogDuration = nil
									end
									if player ~= nil and player == g_localPlayer then
										ConversationDialog.show(self.title, plainText, optionTexts, dialogDuration, self.dialogCallback, self, args)
									end
									return
								end
							end
						end
					elseif player.graphicsComponent.model ~= nil then
						lookAtNode = player.graphicsComponent.model.faceFocusNode
					end
				end
			end
		else
			local numWords = Utils.getNumOfWords(plainText)
			dialogDuration = numWords * NPC.VOICEOVER_DURATION_PER_WORD_MS + NPC.VOICEOVER_PLAYBACK_DELAY_MS * 2
		end
	else
		plainText = nil
	end
end
function NPC:dialogCallback(canceled, textOptionIndex, args)
	if self.currentConversation ~= nil and (self.currentConversation:getCanBeCanceled() and canceled) then
		self:cancelConversation()
		return
	end
	local conversationItemIndex = args.conversationItemIndex
	local optionIndex = args.conversationOptionTextMapping[textOptionIndex]
	self.isRequestPending = true
	g_client:getServerConnection():sendEvent(NPCConversationAnswerEvent.new(self, conversationItemIndex, optionIndex))
end
function NPC:onUserRemoved(user)
	if g_server ~= nil and self:getIsInConversation() then
		local player = self:getInteractingPlayer()
		if player ~= nil and player.userId == user:getId() then
			Logging.devInfo("NPC.onUserRemoved conversation user '%s' left the game", user:getNickname())
			self:cancelConversation()
		end
	end
end
function NPC:onForceCancelConversation()
	local player = self:getInteractingPlayer()
	if player ~= nil and player == g_localPlayer then
		self:cancelConversation()
	end
end
function NPC:onCanceledConversation()
	self.isRequestPending = false
	Logging.devInfo("onCanceledConversation")
	if self.isInConversation then
		self.isInConversation = false
		ConversationDialog.hide()
		self:stopFacialAnimation()
	end
	self:resetConversation()
end
function NPC:cancelConversation(connection)
	if g_server == nil then
		g_client:getServerConnection():sendEvent(NPCConversationCancelEvent.new(self))
		return
	end
	local player = self:getInteractingPlayer()
	if player == nil then
		return
	elseif not (connection ~= nil and connection ~= player.connection) then
		g_server:broadcastEvent(NPCConversationCancelEvent.new(self), true)
	else
		Logging.devWarning("NPC.cancelConversation: Cancel event recieved from invalid user")
		return
	end
end
function NPC:onFinishedConversation(hasFollowUpConversation)
	self.isRequestPending = false
	if self.isInConversation and not hasFollowUpConversation then
		self.isInConversation = false
		ConversationDialog.hide()
		self:stopFacialAnimation()
	end
	self:resetConversation()
end
function NPC:finishConversation(hasFollowUpConversation)
	assert(g_server ~= nil, "NPC:finishConversation is a server-only function")
	g_server:broadcastEvent(NPCConversationFinishedEvent.new(self, hasFollowUpConversation), true)
	if self.finishCallback ~= nil then
		self.finishCallback()
	end
end
function NPC:resetConversation()
	Logging.devInfo("NPC.resetConversation")
	if g_soundManager:getIsSamplePlaying(self.samples.voice) then
		g_soundManager:stopSample(self.samples.voice)
	end
	if g_soundManager:getIsSamplePlaying(self.samples.phone) then
		g_soundManager:stopSample(self.samples.phone)
	end
	if self.playerGraphics ~= nil and self.playerGraphics.facialAnimation ~= nil then
		self.playerGraphics.facialAnimation:stop()
		self.playerGraphics.facialAnimation:reset()
	end
	if self.currentConversation ~= nil then
		self.currentConversation:reset()
	end
	self.currentConversation = nil
	self.currentConversationPlayerObjectId = nil
	self.followUpConversation = nil
	self.currentConversationConnection = nil
end
function NPC:setInputData(name, value)
	self.inputData:setData(name, value)
end
function NPC:getInputData(name)
	return self.inputData:getData(name)
end
function NPC:setDistanceToCamera(distance)
	self.distanceToCamera = distance
	local isNear = distance < self.clipDistance
	if isNear then
		self:raiseActive()
	end
	self:updateVisibility()
	if self.playerGraphics ~= nil then
		self.playerGraphics:updateFacialAnimationVisibilityFromCameraDistance(distance)
	end
end
function NPC:updateVisibility()
	local isVisible = self.isActive
	if self.clipDistance < self.distanceToCamera then
		isVisible = false
	end
	if self.playerGraphics ~= nil then
		if isVisible then
			self.playerGraphics:show()
		else
			self.playerGraphics:hide()
		end
	end
	if self.node ~= nil then
		setVisibility(self.node, isVisible)
	end
end
function NPC:addHotspots()
	if self.mapHotspot ~= nil and not self.isHotspotAdded then
		self.isHotspotAdded = true
		local mission = g_currentMission
		mission:addMapHotspot(self.mapHotspot)
	end
end
function NPC:removeHotspot()
	if self.mapHotspot ~= nil and self.isHotspotAdded then
		local mission = g_currentMission
		mission:removeMapHotspot(self.mapHotspot)
		self.isHotspotAdded = false
	end
end
function NPC:validate()
	for _, conversation in ipairs(self.conversations) do
		conversation:validate()
	end
end
function NPC:startFacialAnimation(useFacialAnimation, isPhoneConversation)
	if useFacialAnimation then
		self.isInFacialAnimationConversation = true
		if not isPhoneConversation then
			local currentPlayer = NetworkUtil.getObject(self.currentConversationPlayerObjectId)
			local player = g_localPlayer
			if currentPlayer ~= nil and (currentPlayer == player and (player.isOwner and player.camera ~= nil)) then
				player.camera:setIsInConversation(true)
				player.camera:setTargetOverrideFromNode(player.graphicsComponent.rightShoulderCameraNode, 250)
			end
		end
	end
	if isPhoneConversation then
		self.isPhoneConversation = true
	end
end
function NPC:stopFacialAnimation()
	if self.isInFacialAnimationConversation then
		self.isInFacialAnimationConversation = false
		if not self:getIsPhoneConversation() then
			local currentPlayer = NetworkUtil.getObject(self.currentConversationPlayerObjectId)
			local player = g_localPlayer
			if currentPlayer ~= nil and (currentPlayer == player and (player.isOwner and player.camera ~= nil)) then
				player.camera:setIsInConversation(false)
				player.camera:clearTargetOverride()
			end
		end
	end
	self.isPhoneConversation = false
end
