-- Local values: NPC_mt
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
	local v2_ = NPC.xmlSchema
	v2_:register(XMLValueType.STRING, "npc.class", "NPC controller class name", "NPC", false)
	v2_:register(XMLValueType.STRING, "npc.filename", "NPC filename", nil, true)
	v2_:register(XMLValueType.STRING, "npc.title", "NPC title", nil, true)
	v2_:register(XMLValueType.STRING, "npc.imageFilename", "NPC image", nil, true)
	v2_:register(XMLValueType.STRING, "npc.conversations.conversation(?)", "NPC conversation files", nil, true)
	v2_:register(XMLValueType.STRING, "npc.conversations.conversation(?)#uniqueId", "NPC conversation unique id", nil, true)
	SoundManager.registerSampleXMLPaths(v2_, "npc.sounds", "voice")
	SoundManager.registerSampleXMLPaths(v2_, "npc.sounds", "phone")
	v2_:register(XMLValueType.NODE_INDEX, "npc.interactionTrigger#node", "NPC interaction trigger node", nil, true)
	PlayerStyle.registerSavegameXMLPaths(v2_, "npc.playerStyle")
	I3DUtil.registerI3dMappingXMLPaths(v2_, "npc")
	local v3_ = NPCManager.xmlSchemaSavegame
	v3_:register(XMLValueType.BOOL, "npcs.npc(?)#isActive", "If the npc is active")
	v3_:register(XMLValueType.STRING, "npcs.npc(?)#spotUniqueId", "Id of the current npc spot")
	local v4_ = "npcs.npc(?).player(?)"
	v3_:register(XMLValueType.STRING, v4_ .. "#uniqueUserId")
	v3_:register(XMLValueType.INT, v4_ .. "#numContacts")
	v3_:register(XMLValueType.STRING, v4_ .. ".conversation(?)#uniqueId")
	NPCConversation.registerSavegameXMLPaths(v3_, v4_ .. ".conversation(?)")
	NPCSpot.registerSavegameXMLPaths(v3_, "npcs.spots.spot(?)")
end)

-- Upvalues: NPC_mt
-- Local values: self
function NPC.new(isServer, isClient, customMt)
	-- upvalues: (copy) NPC_mt
	local v8_ = Object.new(isServer, isClient, customMt or NPC_mt)
	v8_.name = "Unknown NPC"
	v8_.title = "Unknown NPC"
	v8_.filename = nil
	v8_.imageFilename = nil
	v8_.finishedMissions = 0
	v8_.clipDistance = 100
	v8_.components = {}
	v8_.i3dMappings = {}
	v8_.isPlayerInRange = false
	v8_.spot = nil
	v8_.isActive = false
	v8_.x = 0
	v8_.y = 0
	v8_.z = 0
	v8_.rotX = 0
	v8_.rotY = 0
	v8_.rotZ = 0
	v8_.distanceToCamera = 0
	v8_.conversations = {}
	v8_.idToConversation = {}
	v8_.typeToConversations = {}
	v8_.filenameToConversation = {}
	v8_.availableConversations = {}
	v8_.inputData = ConversationInputData.new()
	v8_.currentConversationPlayerObjectId = nil
	v8_.isInConversation = false
	v8_.isInFacialAnimationConversation = false
	v8_.isPhoneConversation = false
	v8_.rotationSpeed = 0.006283185307179587
	v8_.farmData = {}
	v8_.userData = {}
	v8_.playerGraphics = HumanGraphicsComponent.new()
	v8_.playerGraphics.defaultState.isNPC = true
	v8_.playerGraphics:setIsFacialAnimationEnabled(true)
	v8_.playerGraphics:setSoundsEnabled(false)
	v8_.mapHotspot = NPCHotspot.new(v8_)
	v8_.dirtyFlag = v8_:getNextDirtyFlag()
	g_messageCenter:subscribe(MessageType.USER_REMOVED, v8_.onUserRemoved, v8_)
	g_messageCenter:subscribe(MessageType.APP_SUSPENDED, v8_.onForceCancelConversation, v8_)
	return v8_
end

-- Local values: customEnv, baseDirectory, title, imageFilename, i3dFilename, playerStyle, _, conversationKey, uniqueId, conversationXMLFilename, systemConversationXMLFilename, conversation, typeId
function NPC:load(xmlFilename)
	self.xmlFile = XMLFile.load("NPC", xmlFilename, NPC.xmlSchema)
	if self.xmlFile == nil then
		return false
	end
	self.xmlFilename = xmlFilename
	local v11_, v12_ = Utils.getModNameAndBaseDirectory(self.xmlFile:getFilename())
	self.baseDirectory = v12_
	local v13_ = self.xmlFile:getValue("npc.title")
	if v13_ == nil then
		Logging.xmlWarning(self.xmlFile, "Missing title for npc!")
		self.xmlFile:delete()
		self.xmlFile = nil
		return false
	end
	self.title = g_i18n:convertText(v13_, v11_)
	local v14_ = self.xmlFile:getValue("npc.imageFilename")
	if v14_ == nil then
		Logging.xmlWarning(self.xmlFile, "Missing imageFilename for npc!")
		self.xmlFile:delete()
		self.xmlFile = nil
		return false
	end
	self.imageFilename = Utils.getFilename(v14_, v12_)
	local v15_ = self.xmlFile:getValue("npc.filename")
	if v15_ == nil then
		Logging.xmlWarning(self.xmlFile, "Missing i3dFilename for npc!")
		self.xmlFile:delete()
		self.xmlFile = nil
		return false
	end
	self.i3dFilename = Utils.getFilename(v15_, v12_)
	self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.i3dFilename, true, true, self.onI3DFileLoaded, self, nil)
	self.playerGraphics:initialize()
	link(getRootNode(), self.playerGraphics.graphicsRootNode)
	local v16_ = PlayerStyle.new()
	v16_:loadFromXMLFile(self.xmlFile, "npc.playerStyle")
	self.playerStyle = v16_
	self.playerGraphics:setStyleAsync(v16_, self.loadCharacterFinished, self, {})
	for _, v17_ in self.xmlFile:iterator("npc.conversations.conversation") do
		local v18_ = self.xmlFile:getValue(v17_ .. "#uniqueId")
		if v18_ == nil then
			Logging.xmlWarning(self.xmlFile, "Missing uniqueId for conversation \'%s\'", v17_)
		elseif self.idToConversation[v18_] == nil then
			local v19_ = self.xmlFile:getValue(v17_)
			if v19_ == nil then
				Logging.xmlWarning(self.xmlFile, "No config file found for npc conversation \'%s\'", v17_)
			else
				local v20_ = Utils.getFilename(v19_, v12_)
				local v21_ = NPCUtil.createConversationFromXML(self, v20_, v18_)
				if v21_ ~= nil then
					local v22_ = self.conversations
					table.insert(v22_, v21_)
					v21_:setIndex(#self.conversations)
					self.idToConversation[v18_] = v21_
					self.filenameToConversation[v19_] = v21_
					local v23_ = v21_:getType()
					if self.typeToConversations[v23_] == nil then
						self.typeToConversations[v23_] = {}
					end
					local v24_ = self.typeToConversations[v23_]
					table.insert(v24_, v21_)
				end
			end
		else
			Logging.xmlWarning(self.xmlFile, "UniqueId \'%s\' already used for conversation \'%s\'", v18_, v17_)
		end
	end
	return true
end

-- Local values: currentConversation
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
	local v28_ = self.currentConversation
	local v29_ = streamWriteBool
	local v30_
	if v28_ == nil then
		v30_ = false
	else
		v30_ = self.currentConversationPlayerObjectId ~= nil
	end
	if v29_(streamId, v30_) then
		NetworkUtil.writeNodeObjectId(streamId, self.currentConversationPlayerObjectId)
		streamWriteUIntN(streamId, v28_:getIndex(), NPC.CONVERSATION_INDEX_SEND_NUM_BITS)
		streamWriteBool(streamId, self.isInFacialAnimationConversation)
		streamWriteBool(streamId, self.isPhoneConversation)
	end
end

-- Local values: playerNetworkId, conversationIndex, useFacialAnimation, isPhoneConversation
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
		self:onConversationStarted(NetworkUtil.readNodeObjectId(streamId), streamReadUIntN(streamId, NPC.CONVERSATION_INDEX_SEND_NUM_BITS), streamReadBool(streamId), (streamReadBool(streamId)))
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
	if loadingState == HumanModelLoadingState.OK then
		self.playerGraphics:defaultAllParameters()
		self:updatePosition()
	else
		if loadingState == HumanModelLoadingState.CANCELED then
			Logging.info("Loading player model canceled")
		else
			Logging.error("Loading player model failed")
		end
		self.playerGraphics:delete()
		self.playerGraphics = nil
	end
end

-- Local values: mission, triggerNode
function NPC:onI3DFileLoaded(node, failedReason, args)
	if failedReason == LoadI3DFailedReason.NONE then
		link(getRootNode(), node)
		self.node = node
		setClipDistance(node, self.clipDistance)
		I3DUtil.loadI3DComponents(node, self.components)
		I3DUtil.loadI3DMapping(self.xmlFile, "npc", self.components, self.i3dMappings)
		if g_currentMission:getIsClient() then
			self.samples = {}
			self.samples.voice = g_soundManager:loadSampleFromXML(self.xmlFile, "npc.sounds", "voice", self.baseDirectory, self.components, 1, AudioGroup.CHARACTER, self.i3dMappings, self, false)
			self.samples.phone = g_soundManager:loadSample2DFromXML(self.xmlFile, "npc.sounds", "phone", "", 1, AudioGroup.CHARACTER, false)
		end
		local v48_ = self.xmlFile:getValue("npc.interactionTrigger#node", nil, self.components, self.i3dMappings)
		self.interactionTriggerNode = v48_
		self.interactionTriggerCallbackId = addTrigger(v48_, "onInteractionCallback", self, false, self.onInteractionCallback)
		self.activatable = NPCActivatable.new(self)
		self:updatePosition()
	end
	if self.xmlFile ~= nil then
		self.xmlFile:delete()
		self.xmlFile = nil
	end
end

-- Local values: userIndex, uniqueUserId, userData, userKey, conversationIndex, conversationUniqueId, conversationData, conversation, conversationKey
function NPC:saveToSavegameXMLFile(xmlFile, key)
	if self.spot ~= nil then
		xmlFile:setValue(key .. "#spotUniqueId", self.spot:getUniqueId())
	end
	local v52_ = 0
	for v53_, v54_ in pairs(self.userData) do
		local v55_ = string.format("%s.player(%d)", key, v52_)
		xmlFile:setValue(v55_ .. "#uniqueUserId", v53_)
		xmlFile:setValue(v55_ .. "#numContacts", v54_.numContacts or 0)
		local v56_ = 0
		for v57_, v58_ in pairs(v54_.conversations) do
			local v59_ = self:getConversationById(v57_)
			local v60_ = string.format("%s.conversation(%d)", v55_, v56_)
			xmlFile:setValue(v60_ .. "#uniqueId", v57_)
			v59_:saveToSavegameXMLFile(xmlFile, v60_, v58_)
			v56_ = v56_ + 1
		end
		v52_ = v52_ + 1
	end
end

-- Local values: spotUniqueId, mission, playerSystem, _, userKey, uniqueUserId, hasUser, userData, _, conversationKey, conversationUniqueId, conversation, conversationData
function NPC:loadFromSavegameXMLFile(xmlFile, key)
	local v64_ = xmlFile:getValue(key .. "#spotUniqueId")
	if v64_ ~= nil then
		self.pendingSpotUniqueId = v64_
	end
	local v65_ = g_currentMission.playerSystem
	for _, v66_ in xmlFile:iterator(key .. ".player") do
		local v67_ = xmlFile:getValue(v66_ .. "#uniqueUserId")
		if v65_:getHasPlayerWithUniqueId(v67_) ~= nil then
			local v68_ = {
				["numContacts"] = xmlFile:getValue(v66_ .. "#numContacts", 0),
				["conversations"] = {}
			}
			for _, v69_ in xmlFile:iterator(v66_ .. ".conversation") do
				local v70_ = xmlFile:getValue(v69_ .. "#uniqueId")
				local v71_ = self:getConversationById(v70_)
				if v71_ ~= nil then
					local v72_ = {}
					v71_:loadFromSavegameXMLFile(xmlFile, v69_, v72_)
					if next(v72_) ~= nil then
						v68_.conversations[v70_] = v72_
					end
				end
			end
			if next(v68_.conversations) ~= nil then
				self.userData[v67_] = v68_
			end
		end
	end
	return true
end

-- Local values: _, conversation, mission
function NPC:delete()
	g_messageCenter:unsubscribeAll(self)
	for _, v74_ in ipairs(self.conversations) do
		v74_:delete()
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
	g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
end

-- Local values: spot, playerGraphics, player, px, _, pz, x, _, z, length, dirX, dirZ, currentRotation, lastRotation, targetRotation, difference, rotationVelocity, player
function NPC:update(dt)
	if self.pendingSpotUniqueId ~= nil then
		local v77_ = g_npcManager:getSpotByUniqueId(self.pendingSpotUniqueId)
		if v77_ ~= nil then
			self:setSpot(v77_)
			self.forceUpdate = true
		end
		self.pendingSpotUniqueId = nil
	end
	if self.needPositionUpdate then
		local v78_ = self.playerGraphics
		if v78_ ~= nil and (self.forceUpdate or (self.distanceToCamera > self.clipDistance or not v78_:getIsInCameraFrustum())) then
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
		local v79_ = self:getInteractingPlayer() or g_localPlayer
		if v79_ ~= nil and self.node ~= nil then
			local v80_, _, v81_ = v79_:getPosition()
			local v82_, _, v83_ = getWorldTranslation(self.node)
			if MathUtil.vector2Length(v80_ - v82_, v81_ - v83_) > 0 then
				local v84_, v85_ = MathUtil.vector2Normalize(v80_ - v82_, v81_ - v83_)
				local v86_ = self.playerGraphics:getModelYaw()
				local v87_ = MathUtil.getYRotationFromDirection(v84_, v85_)
				local v88_ = MathUtil.normalizeRotationForShortestPath(v87_, v86_)
				local v89_
				if v86_ < v88_ then
					local v90_ = v86_ + dt * self.rotationSpeed
					v89_ = math.min(v90_, v88_)
				else
					local v91_ = v86_ - dt * self.rotationSpeed
					v89_ = math.max(v91_, v88_)
				end
				local v92_ = MathUtil.getAngleDifference(v89_, v86_)
				self.playerGraphics.defaultState.rotationVelocity = v92_
				self.playerGraphics:setModelYaw(v89_)
			end
		end
		if NPCManager.DEBUG_ANIMATIONS then
			self.playerGraphics.animation:debugDraw(0.025, 0.95, 0.014)
		end
	end
	local v93_ = self:getInteractingPlayer()
	if v93_ ~= nil and (v93_ == g_localPlayer and (self:getIsInFacialAnimationConversation() and not self:getIsPhoneConversation())) then
		v93_:updateWhileInConversation(dt, self)
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

-- Local values: distance, dirX, dirZ, x, z
function NPC:getTeleportWorldPosition()
	if self.spot == nil then
		return nil
	end
	if self.spot.node ~= nil then
		return localToWorld(self.spot.node, 0, 0, 4)
	end
	local v98_, v99_ = MathUtil.getDirectionFromYRotation(self.rotY)
	local v100_ = self.x + v98_ * 4
	local v101_ = self.z + v99_ * 4
	return v100_, self.y, v101_
end

-- Local values: _, rotY
function NPC:getTeleportWorldRotation()
	if self.spot == nil then
		return nil
	end
	local v103_ = self.rotY
	if self.spot.node ~= nil then
		local v104_, v105_
		v104_, v103_, v105_ = getWorldRotation(self.spot.node)
	end
	return v103_ + 3.141592653589793
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

-- Local values: wasChanged, x, y, z, rotX, rotY, rotZ
function NPC:setSpot(spot)
	local v115_ = self.spot ~= spot
	self.spot = spot
	self.isActive = spot ~= nil
	if spot == nil then
		self:removeHotspot()
	else
		local v116_, v117_, v118_ = spot:getPosition()
		local v119_, v120_, v121_ = spot:getRotation()
		if not v115_ then
			local v122_ = v116_ - self.x
			if math.abs(v122_) > 0.01 then
				v115_ = true
			else
				local v123_ = v117_ - self.y
				if math.abs(v123_) > 0.01 then
					v115_ = true
				else
					local v124_ = v118_ - self.z
					v115_ = math.abs(v124_) > 0.01 and true or v115_
				end
			end
			if not v115_ then
				local v125_ = v119_ - self.rotX
				if math.abs(v125_) > 0.001 then
					v115_ = true
				else
					local v126_ = v120_ - self.rotY
					if math.abs(v126_) > 0.001 then
						v115_ = true
					else
						local v127_ = v121_ - self.rotZ
						v115_ = math.abs(v127_) > 0.001 and true or v115_
					end
				end
			end
		end
		self.x = v116_
		self.y = v117_
		self.z = v118_
		self.rotX = v119_
		self.rotY = v120_
		self.rotZ = v121_
		self:addHotspots()
		self.mapHotspot:setWorldPosition(self.x, self.z)
	end
	if v115_ then
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

-- Local values: player, mission
function NPC:onInteractionCallback(triggerId, otherId, onEnter, onLeave, onStay)
	local v139_ = g_localPlayer
	if self.isActive and (v139_ ~= nil and otherId == v139_.rootNode) then
		local v140_ = g_currentMission
		if onEnter then
			self.isPlayerInRange = true
			v140_.activatableObjectsSystem:addActivatable(self.activatable)
			return
		end
		if onLeave then
			self.isPlayerInRange = false
			v140_.activatableObjectsSystem:removeActivatable(self.activatable)
		end
	end
end

function NPC:getCanInteract()
	if g_guidedTourManager:getIsTourRunning() and self.nextConversation == nil then
		return false
	elseif self.isRequestPending then
		return false
	elseif self.isInConversation then
		return false
	elseif self.currentConversationPlayerObjectId == nil then
		if self.isActive then
			return #self.conversations > 0
		else
			return false
		end
	else
		return false
	end
end

function NPC:getFacingDirection()
	if self.playerGraphics == nil then
		return 0, 0, 1
	else
		return self.playerGraphics:getModelDirection()
	end
end

function NPC:getIsPlayerInRange()
	return self.isPlayerInRange
end

function NPC:getFarmData(farm)
	self.farmData[farm.farmId] = self.farmData[farm.farmId] or {}
	return self.farmData[farm.farmId]
end

-- Local values: player
function NPC:getInteractingPlayer()
	if self.currentConversationPlayerObjectId == nil then
		return nil
	else
		return NetworkUtil.getObject(self.currentConversationPlayerObjectId)
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

-- Local values: uniqueUserId, userData, numContacts
function NPC:getIsFirstContact(player)
	if player == nil then
		return false
	end
	local v155_ = player:getUniqueUserId()
	local v156_ = self.userData[v155_]
	return v156_ == nil and true or v156_.numContacts == 0
end

-- Local values: userData, conversations, _, conversation, conversationData
function NPC:resetConversationNumTriggeredByType(player, typeId)
	if player == nil then
		return
	else
		local v160_ = self.userData[player:getUniqueUserId()]
		if v160_ ~= nil then
			local v161_ = self.typeToConversations[typeId]
			for _, v162_ in ipairs(v161_) do
				local v163_ = v160_.conversations[v162_:getUniqueId()]
				if v163_ ~= nil then
					v163_.numTriggered = 0
				end
			end
		end
	end
end

-- Local values: userData
function NPC:getWasConversationTriggered(player, uniqueId)
	if player == nil then
		return false
	else
		local v167_ = self.userData[player:getUniqueUserId()]
		if v167_ == nil then
			return false
		else
			return v167_.conversations[uniqueId] ~= nil
		end
	end
end

-- Local values: userData, conversationData
function NPC:getConversationNumTriggered(player, uniqueId)
	if player == nil then
		return nil
	end
	local v171_ = self.userData[player:getUniqueUserId()]
	if v171_ == nil then
		return 0
	end
	local v172_ = v171_.conversations[uniqueId]
	return v172_ == nil and 0 or v172_.numTriggered
end

-- Local values: conversations, typeName
function NPC:getRandomConversation(player, typeId, uniqueIds)
	local v176_ = self.conversations
	if typeId ~= nil then
		if NPCConversationType.getName(typeId) == nil then
			Logging.devInfo("NPCConversationType not defined for id \'%s\'", typeId)
			return nil
		end
		v176_ = self.typeToConversations[typeId]
		if v176_ == nil then
			Logging.devInfo("No conversations defined for type \'%s\'", NPCConversationType.getName(typeId))
			return nil
		end
	end
	return self:getRandomConversationFromList(player, v176_)
end

-- Local values: conversations, _, uniqueId, conversation
function NPC:getRandomConversationFromUniqueIds(player, uniqueIds)
	local v180_ = {}
	for _, v181_ in ipairs(uniqueIds) do
		local v182_ = self.idToConversation[v181_]
		table.insert(v180_, v182_)
	end
	return self:getRandomConversationFromList(player, v180_)
end

-- Local values: availableConversations, userData, _, conversation, conversationUserData, probabilityBasedConversations, lastWeight, k, availableConversation, weight, i, conversationIndex, conversation
function NPC:getRandomConversationFromList(player, conversations)
	local v186_ = self.userData[player:getUniqueUserId()]
	local v187_ = {}
	for _, v188_ in ipairs(conversations) do
		v188_:init(player)
		local v189_
		if v186_ == nil then
			v189_ = nil
		else
			v189_ = v186_.conversations[v188_:getUniqueId()]
		end
		if v188_:getIsAvailable(player, v189_) then
			table.insert(v187_, v188_)
		end
	end
	if #v187_ == 0 then
		Logging.devInfo("No conversations available")
		return nil
	end
	table.sort(v187_, function(p190_, p191_)
		return p190_:compare(p191_)
	end)
	local v192_ = v187_[1]:getWeight()
	local v193_ = {}
	for _, v194_ in ipairs(v187_) do
		if v192_ ~= v194_:getWeight() then
			break
		end
		for _ = 1, v194_:getProbability() do
			table.insert(v193_, v194_)
		end
	end
	return v193_[math.random(1, #v193_)]
end

function NPC:setNextConversation(conversation, finishCallback)
	self.nextConversation = conversation
	self.finishCallback = finishCallback
end

function NPC:setFollowUpConversation(conversation)
	local v200_ = g_server ~= nil
	assert(v200_, "NPC.setFollowUpConversation is a server-only function")
	self.followUpConversation = conversation
end

-- Local values: playerObjectId, conversation
function NPC:requestConversation(player)
	if player == nil then
		Logging.devInfo("NPC.requestConversation: no player  given")
		return
	elseif self.isServer then
		local v203_ = NetworkUtil.getObjectId(player)
		if self.currentConversationPlayerObjectId == nil then
			self.inputData:reset()
			local v204_ = self.nextConversation
			if v204_ == nil then
				if self:getIsFirstContact(player) then
					v204_ = self:getRandomConversation(player, NPCConversationType.FIRST_CONTACT)
				end
				if v204_ == nil then
					v204_ = self:getRandomConversation(player, NPCConversationType.INTRO)
				end
				if v204_ == nil then
					v204_ = self:getRandomConversation(player, NPCConversationType.DEFAULT)
				end
			end
			if v204_ == nil then
				player.connection:sendEvent(NPCConversationStartFailedEvent.new(self, NPCConversationFailedState.FAILED_REASON_NO_CONVERSATION_AVAILABLE))
			else
				self:startConversation(player, v204_, true, false)
			end
		else
			if v203_ ~= self.currentConversationPlayerObjectId then
				player.connection:sendEvent(NPCConversationStartFailedEvent.new(self, NPCConversationFailedState.FAILED_REASON_NPC_BUSY))
			end
			return
		end
	elseif self.isRequestPending then
		Logging.devInfo("NPC.requestConversation: request is already pending")
	else
		self.isRequestPending = true
		g_client:getServerConnection():sendEvent(NPCConversationRequestEvent.new(self, player))
	end
end

-- Local values: conversationItem, conversationId, userData, conversationUserData, conversationIndex, disabledOptionIndices, k, option, _, optionPrerequisite
function NPC:startConversation(player, conversation, useFacialAnimation, isPhoneConversation)
	local v210_ = g_server ~= nil
	assert(v210_, "NPC:startConversation is a server only function")
	if player == nil then
		Logging.devInfo("NPC.startConversation: no player  given")
		return
	end
	local v211_ = Utils.getNoNil(useFacialAnimation, true)
	local v212_ = Utils.getNoNil(isPhoneConversation, false)
	if conversation == self.nextConversation then
		self.nextConversation = nil
	end
	conversation:loadTexts()
	local v213_ = conversation:getConversationItemByIndex(1)
	if v213_ == nil then
		player.connection:sendEvent(NPCConversationStartFailedEvent.new(self, NPCConversationFailedState.FAILED_REASON_NO_CONVERSATION_ITEMS))
		Logging.warning("NPC.startConversation: No text items defined for conversation \'%s\'", conversation.xmlFilename)
		conversation:unloadTexts()
		return
	end
	Logging.devInfo("NPC.startConversation: Talking to NPC \'%s\'. Start Conversation \'%s\'", self:getName(), conversation.xmlFilename)
	local v214_ = conversation:getUniqueId()
	local v215_ = self.userData[player:getUniqueUserId()] or {
		["numContacts"] = 0,
		["conversations"] = {}
	}
	local v216_ = v215_.conversations[v214_] or {}
	self.currentConversation = conversation
	self.currentConversationPlayerObjectId = NetworkUtil.getObjectId(player)
	conversation:start(player, v216_)
	v213_:activate()
	v215_.numContacts = v215_.numContacts + 1
	if next(v216_) ~= nil then
		v215_.conversations[v214_] = v216_
		self.userData[player:getUniqueUserId()] = v215_
	end
	local v217_ = conversation:getIndex()
	local v218_ = {}
	if v213_.options ~= nil then
		for v219_, v220_ in ipairs(v213_.options) do
			if v220_.isActive then
				if v220_.prerequisites ~= nil then
					for _, v221_ in ipairs(v220_.prerequisites) do
						if not v221_:getIsValid(player) then
							table.insert(v218_, v219_)
							break
						end
					end
				end
			else
				table.insert(v218_, v219_)
			end
		end
	end
	g_server:broadcastEvent(NPCConversationStartEvent.new(self, player, v217_, 1, v218_, v211_, v212_), true)
end

-- Local values: conversation
function NPC:onConversationStarted(playerNetworkId, conversationIndex, useFacialAnimation, isPhoneConversation)
	self.isRequestPending = false
	local v227_ = self:getConversationByIndex(conversationIndex)
	if v227_ == nil then
		Logging.devWarning("NPC.onConversationStarted: Unknown conversation with index \'%s\'", conversationIndex)
	else
		self.currentConversation = v227_
		self.currentConversationPlayerObjectId = playerNetworkId
		if not self.isInConversation then
			self.isInConversation = true
			self:startFacialAnimation(useFacialAnimation, isPhoneConversation)
		end
		Logging.devInfo("NPC.onConversationStarted: Started conversion \'%s\' with player \'%s\'", conversationIndex, playerNetworkId)
		v227_:loadTexts()
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

-- Local values: conversation, player, conversationItem, nextId, options, option, followUpConversation, isPhoneConversation, isFacialAnimationConversation, nextConversationItem, disabledOptionIndices, k, option, _, optionPrerequisite
function NPC:processAnswer(connection, conversationItemIndex, optionIndex)
	local v235_ = g_server ~= nil
	assert(v235_, "NPC.processAnswer is a server-only function")
	local v236_ = self.currentConversation
	if v236_ == nil then
		self:resetConversation()
		Logging.warning("NPC.processAnswer: No conversation started")
		return
	else
		local v237_ = self:getInteractingPlayer()
		if v237_.connection == connection then
			local v238_ = v236_:getConversationItemByIndex(conversationItemIndex)
			if v238_ == nil then
				self:resetConversation()
				Logging.devWarning("NPC.processAnswer: Unknown conversation item with index \'%s\'", conversationItemIndex)
				return
			else
				local v239_
				if optionIndex == nil or optionIndex == 0 then
					local v240_ = v238_:getOptions()
					if optionIndex == 0 and (v240_ ~= nil and #v240_ > 0) then
						Logging.devWarning("NPC.processAnswer: Recieved optionIndex 0 but conversation item has options defined!")
					end
					v239_ = v238_:getNextId()
				else
					local v241_ = v238_:getOptionByIndex(optionIndex)
					if v241_ == nil then
						self:resetConversation()
						Logging.warning("NPC.processAnswer: Unknown conversation item option with index \'%s\'", optionIndex)
						return
					end
					v238_:activateOption(optionIndex)
					v239_ = v241_.nextId
				end
				local v242_ = self.followUpConversation
				local v243_ = self:getIsPhoneConversation()
				local v244_ = self:getIsInFacialAnimationConversation()
				if v239_ == nil then
					self:finishConversation(v242_ ~= nil)
					if v242_ ~= nil then
						self.followUpConversation = nil
						self:startConversation(v237_, v242_, v244_, v243_)
					end
					return
				else
					local v245_ = v236_:getConversationItemById(v239_)
					if v245_ == nil then
						self:resetConversation()
						Logging.warning("NPC.processAnswer: Unknown conversation item with id \'%s\'", v239_)
					else
						v245_:activate()
						local v246_ = {}
						if v245_.options ~= nil then
							for v247_, v248_ in ipairs(v245_.options) do
								if v248_.isActive then
									if v248_.prerequisites ~= nil then
										for _, v249_ in ipairs(v248_.prerequisites) do
											if not v249_:getIsValid(v237_) then
												table.insert(v246_, v247_)
											end
										end
									end
								else
									table.insert(v246_, v247_)
								end
							end
						end
						g_server:broadcastEvent(NPCConversationItemShowEvent.new(self, v245_:getIndex(), v246_), true)
					end
				end
			end
		else
			Logging.devWarning("NPC.processAnswer: Recieved answer from invalid user connection")
			return
		end
	end
end

function NPC:onFailedToStartConversation(failedReason)
	self.isRequestPending = false
	Logging.devInfo("Failed to start conversation", failedReason)
end

-- Local values: conversation, conversationItem, player, text, plainText, optionTexts, optionTextMapping, options, blockedOptionIndex, _, index, k, option, args, dialogDuration, audioFilename, sample, lookAtNode, currentVehicle, enterable, _, camera, numWords
function NPC:showConversationItem(conversationItemIndex, conversationDisabledOptionIndices)
	local v255_ = self.currentConversation
	if v255_ == nil then
		self:resetConversation()
		Logging.warning("NPC.showConversationItem: No conversation started")
		return
	end
	local v256_ = v255_:getConversationItemByIndex(conversationItemIndex)
	if v256_ == nil then
		self:resetConversation()
		Logging.warning("NPC.showConversationItem: Unknown conversation item with index \'%s\'", conversationItemIndex)
		return
	end
	local v257_ = self:getInteractingPlayer()
	if v257_ == nil then
		Logging.warning("NPC.showConversationItem: Player not available/synched")
		return
	end
	v256_:init()
	local v258_ = v256_:getText()
	local v259_ = v258_:getPlainText()
	local v260_ = {}
	local v261_ = {}
	local v262_ = v256_:getOptions()
	if v262_ ~= nil then
		local v263_ = {}
		for _, v264_ in ipairs(conversationDisabledOptionIndices) do
			v263_[v264_] = true
		end
		for v265_, v266_ in ipairs(v262_) do
			if v263_[v265_] == nil then
				local v267_ = v266_.text
				table.insert(v260_, v267_:getPlainText())
				v261_[#v260_] = v265_
			end
		end
	end
	local v268_ = {
		["conversationItem"] = v256_,
		["conversationIndex"] = v255_:getIndex(),
		["conversationItemIndex"] = conversationItemIndex,
		["conversationOptionTextMapping"] = v261_
	}
	local v269_ = 2000
	if v256_:getIsActive() then
		local v270_ = v258_:getAudioFilename()
		if v270_ == nil then
			v269_ = Utils.getNumOfWords(v259_) * NPC.VOICEOVER_DURATION_PER_WORD_MS + NPC.VOICEOVER_PLAYBACK_DELAY_MS * 2
		else
			local v271_ = nil
			if self:getIsPhoneConversation() then
				if self.samples.phone ~= nil then
					g_soundManager:createAudio2d(self.samples.phone, v270_)
					g_soundManager:playSample(self.samples.phone, NPC.VOICEOVER_PLAYBACK_DELAY_MS)
					v269_ = self.samples.phone.duration + NPC.VOICEOVER_PLAYBACK_DELAY_MS * 2
					v271_ = self.samples.phone
				end
			elseif self.samples.voice ~= nil then
				g_soundManager:createAudioSource(self.samples.voice, v270_)
				g_soundManager:playSample(self.samples.voice, NPC.VOICEOVER_PLAYBACK_DELAY_MS)
				v269_ = self.samples.voice.duration + NPC.VOICEOVER_PLAYBACK_DELAY_MS * 2
				v271_ = self.samples.voice
			end
			if self:getIsInFacialAnimationConversation() and (self.playerGraphics ~= nil and self.playerGraphics.facialAnimation ~= nil) then
				local v272_ = nil
				if v257_ ~= nil then
					local v273_ = v257_:getCurrentVehicle()
					if v273_ == nil then
						if v257_.graphicsComponent.model ~= nil then
							v272_ = v257_.graphicsComponent.model.faceFocusNode
						end
					else
						local v274_ = v273_.spec_enterable
						if v274_ ~= nil then
							for _, v275_ in ipairs(v274_.cameras) do
								if v275_.isInside then
									v272_ = v275_.cameraNode
									break
								end
							end
						end
					end
				end
				self.playerGraphics.facialAnimation:start(v258_:getEmotionFilename(), v271_, v259_, v272_)
			end
		end
	else
		v259_ = nil
	end
	if #v260_ > 0 then
		v269_ = nil
	end
	if v257_ ~= nil and v257_ == g_localPlayer then
		ConversationDialog.show(self.title, v259_, v260_, v269_, self.dialogCallback, self, v268_)
	end
end

-- Local values: conversationItemIndex, optionIndex
function NPC:dialogCallback(canceled, textOptionIndex, args)
	if self.currentConversation == nil or not (self.currentConversation:getCanBeCanceled() and canceled) then
		local v280_ = args.conversationItemIndex
		local v281_ = args.conversationOptionTextMapping[textOptionIndex]
		self.isRequestPending = true
		g_client:getServerConnection():sendEvent(NPCConversationAnswerEvent.new(self, v280_, v281_))
	else
		self:cancelConversation()
	end
end

-- Local values: player
function NPC:onUserRemoved(user)
	if g_server ~= nil and self:getIsInConversation() then
		local v284_ = self:getInteractingPlayer()
		if v284_ ~= nil and v284_.userId == user:getId() then
			Logging.devInfo("NPC.onUserRemoved conversation user \'%s\' left the game", user:getNickname())
			self:cancelConversation()
		end
	end
end

-- Local values: player
function NPC:onForceCancelConversation()
	local v286_ = self:getInteractingPlayer()
	if v286_ ~= nil and v286_ == g_localPlayer then
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

-- Local values: player
function NPC:cancelConversation(connection)
	if g_server == nil then
		g_client:getServerConnection():sendEvent(NPCConversationCancelEvent.new(self))
		return
	else
		local v290_ = self:getInteractingPlayer()
		if v290_ == nil then
			return
		elseif connection == nil or connection == v290_.connection then
			g_server:broadcastEvent(NPCConversationCancelEvent.new(self), true)
		else
			Logging.devWarning("NPC.cancelConversation: Cancel event recieved from invalid user")
		end
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
	local v295_ = g_server ~= nil
	assert(v295_, "NPC:finishConversation is a server-only function")
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

-- Local values: isNear
function NPC:setDistanceToCamera(distance)
	self.distanceToCamera = distance
	if distance < self.clipDistance then
		self:raiseActive()
	end
	self:updateVisibility()
	if self.playerGraphics ~= nil then
		self.playerGraphics:updateFacialAnimationVisibilityFromCameraDistance(distance)
	end
end

-- Local values: isVisible
function NPC:updateVisibility()
	local v305_ = self.isActive
	if self.distanceToCamera > self.clipDistance then
		v305_ = false
	end
	if self.playerGraphics ~= nil then
		if v305_ then
			self.playerGraphics:show()
		else
			self.playerGraphics:hide()
		end
	end
	if self.node ~= nil then
		setVisibility(self.node, v305_)
	end
end

-- Local values: mission
function NPC:addHotspots()
	if self.mapHotspot ~= nil and not self.isHotspotAdded then
		self.isHotspotAdded = true
		g_currentMission:addMapHotspot(self.mapHotspot)
	end
end

-- Local values: mission
function NPC:removeHotspot()
	if self.mapHotspot ~= nil and self.isHotspotAdded then
		g_currentMission:removeMapHotspot(self.mapHotspot)
		self.isHotspotAdded = false
	end
end

-- Local values: _, conversation
function NPC:validate()
	for _, v309_ in ipairs(self.conversations) do
		v309_:validate()
	end
end

-- Local values: currentPlayer, player
function NPC:startFacialAnimation(useFacialAnimation, isPhoneConversation)
	if useFacialAnimation then
		self.isInFacialAnimationConversation = true
		if not isPhoneConversation then
			local v313_ = NetworkUtil.getObject(self.currentConversationPlayerObjectId)
			local v314_ = g_localPlayer
			if v313_ ~= nil and (v313_ == v314_ and (v314_.isOwner and v314_.camera ~= nil)) then
				v314_.camera:setIsInConversation(true)
				v314_.camera:setTargetOverrideFromNode(v314_.graphicsComponent.rightShoulderCameraNode, 250)
			end
		end
	end
	if isPhoneConversation then
		self.isPhoneConversation = true
	end
end

-- Local values: currentPlayer, player
function NPC:stopFacialAnimation()
	if self.isInFacialAnimationConversation then
		self.isInFacialAnimationConversation = false
		if not self:getIsPhoneConversation() then
			local v316_ = NetworkUtil.getObject(self.currentConversationPlayerObjectId)
			local v317_ = g_localPlayer
			if v316_ ~= nil and (v316_ == v317_ and (v317_.isOwner and v317_.camera ~= nil)) then
				v317_.camera:setIsInConversation(false)
				v317_.camera:clearTargetOverride()
			end
		end
	end
	self.isPhoneConversation = false
end
