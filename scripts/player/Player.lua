-- Local values: Player_mt
Player = {}
local Player_mt = Class(Player, Object)
InitStaticObjectClass(Player, "Player")
Player.MAX_HAND_TOOL_CARRY_MASS = 15
Player.HAND_TOOL_COUNT_NUM_BITS = 4
Player.DEBUG_DISPLAY_FLAG = {
	["NONE"] = 0,
	["INITIALISATION"] = 1,
	["HANDTOOLS"] = 2,
	["NETWORK"] = 4,
	["GRAPHICS"] = 8,
	["STATE"] = 16,
	["MOVEMENT"] = 32,
	["INPUT"] = 64,
	["ALL"] = 255
}
Player.START_WITH_SUPERSPEED = StartParams.getIsSet("playerSuperSpeed")
local v2_ = Player.DEBUG_DISPLAY_FLAG
local v3_ = Player.DEBUG_DISPLAY_FLAG.NETWORK
local v4_ = Player.DEBUG_DISPLAY_FLAG.HANDTOOLS
v2_.NETWORK_HANDTOOLS = bit32.bor(v3_, v4_)
local v5_ = Player.DEBUG_DISPLAY_FLAG
local v6_ = Player.DEBUG_DISPLAY_FLAG.NETWORK
local v7_ = Player.DEBUG_DISPLAY_FLAG.GRAPHICS
v5_.NETWORK_GRAPHICS = bit32.bor(v6_, v7_)
local v8_ = Player.DEBUG_DISPLAY_FLAG
local v9_ = Player.DEBUG_DISPLAY_FLAG.NETWORK
local v10_ = Player.DEBUG_DISPLAY_FLAG.MOVEMENT
v8_.NETWORK_MOVEMENT = bit32.bor(v9_, v10_)
local v11_ = Player.DEBUG_DISPLAY_FLAG
local v12_ = Player.DEBUG_DISPLAY_FLAG.NETWORK
local v13_ = Player.DEBUG_DISPLAY_FLAG.INPUT
v11_.NETWORK_INPUT = bit32.bor(v12_, v13_)
Player.currentDebugFlag = Player.DEBUG_DISPLAY_FLAG.NONE
Player.currentDebugVerbosityFlag = Player.DEBUG_DISPLAY_FLAG.NONE

function Player.registerXMLPaths(xmlSchema)
	xmlSchema:register(XMLValueType.STRING, "player.filename", "The file path of the player\'s i3d file", nil, true)
	HumanModel.registerXMLPaths(xmlSchema, "player")
	PlayerStyle.registerXMLPaths(xmlSchema)
	IKUtil.registerIKChainXMLPaths(xmlSchema, "player.ikChains.ikChain(?)")
end

function Player.registerSavegameXMLPaths(savegameXMLSchema, baseKey)
	local v17_ = baseKey .. ".player(?)"
	savegameXMLSchema:register(XMLValueType.STRING, v17_ .. "#uniqueUserId", "The unique user id of the player", nil, true)
	savegameXMLSchema:register(XMLValueType.STRING, v17_ .. "#timeLastConnected", "The date and time that the player last connected", nil, false)
	savegameXMLSchema:register(XMLValueType.VECTOR_3, v17_ .. ".spawn#position", "The player\'s spawn position", nil, false)
	savegameXMLSchema:register(XMLValueType.ANGLE, v17_ .. ".spawn#yaw", "The player\'s spawn yaw (y rotation)", nil, false)
	savegameXMLSchema:register(XMLValueType.STRING, v17_ .. ".spawn#vehicleUniqueId", "The unique id of the vehicle in which to spawn", nil, false)
	savegameXMLSchema:register(XMLValueType.STRING, v17_ .. ".handTools.handTool(?)#uniqueId", "The unique id of the hand tool the player owns", nil, true)
	PlayerStyle.registerSavegameXMLPaths(savegameXMLSchema, v17_ .. ".style")
	PlayerStyle.registerSavegameXMLPaths(savegameXMLSchema, "gameSettings.lastPlayerStyle")
end

-- Local values: i, handToolUniqueId
function Player.saveDataToXMLFile(xmlFile, playerData, baseKey)
	xmlFile:setValue(baseKey .. "#uniqueUserId", playerData.uniqueId)
	xmlFile:setValue(baseKey .. "#timeLastConnected", playerData.lastConnectedDateTime)
	if playerData.spawnPositionX ~= nil then
		xmlFile:setValue(baseKey .. ".spawn#position", playerData.spawnPositionX, playerData.spawnPositionY, playerData.spawnPositionZ)
	end
	if playerData.spawnYaw ~= nil then
		xmlFile:setValue(baseKey .. ".spawn#yaw", playerData.spawnYaw)
	end
	if not string.isNilOrWhitespace(playerData.spawnVehicleUniqueId) then
		xmlFile:setValue(baseKey .. ".spawn#vehicleUniqueId", playerData.spawnVehicleUniqueId)
	end
	if playerData.style:isValid() then
		playerData.style:saveToXMLFile(xmlFile, baseKey .. ".style")
	end
	for v21_, v22_ in ipairs(playerData.handToolUniqueIds) do
		xmlFile:setValue(string.format("%s.handTools.handTool(%d)#uniqueId", baseKey, v21_ - 1), v22_)
	end
end

-- Local values: uniqueId, lastConnectedDateTime, style, spawnPositionX, spawnPositionY, spawnPositionZ, spawnYaw, spawnVehicleUniqueId, handToolUniqueIds, nodeIndex, handToolKey, handToolUniqueId
function Player.loadDataFromXMLFile(xmlFile, baseKey)
	local v25_ = xmlFile:getValue(baseKey .. "#uniqueUserId", nil)
	local v26_ = xmlFile:getValue(baseKey .. "#timeLastConnected", getDate("%Y/%m/%d %H:%M"))
	if not string.isNilOrWhitespace(v25_) then
		local v27_
		if xmlFile:hasProperty(baseKey .. ".style") then
			v27_ = PlayerStyle.new()
			v27_:loadFromXMLFile(xmlFile, baseKey .. ".style")
			if not v27_:isValid() then
				Logging.xmlWarning(xmlFile, "Player with unique id of %s has an invalid style, using default!", v25_)
				v27_ = PlayerStyle.defaultStyle()
			end
		else
			v27_ = PlayerStyle.defaultStyle()
		end
		local v28_, v29_, v30_ = xmlFile:getValue(baseKey .. ".spawn#position", nil)
		local v31_ = xmlFile:getValue(baseKey .. ".spawn#yaw", nil)
		local v32_ = xmlFile:getValue(baseKey .. ".spawn#vehicleUniqueId", nil)
		local v33_ = {}
		for _, v34_ in xmlFile:iterator(baseKey .. ".handTools.handTool") do
			local v35_ = xmlFile:getValue(v34_ .. "#uniqueId", nil)
			if string.isNilOrWhitespace(v35_) then
				Logging.xmlError(xmlFile, "Player\'s hand tool is missing unique id!")
			else
				table.insert(v33_, v35_)
			end
		end
		return {
			["uniqueId"] = v25_,
			["lastConnectedDateTime"] = v26_,
			["spawnPositionX"] = v28_,
			["spawnPositionY"] = v29_,
			["spawnPositionZ"] = v30_,
			["spawnYaw"] = v31_,
			["spawnVehicleUniqueId"] = v32_,
			["handToolUniqueIds"] = v33_,
			["style"] = v27_
		}
	end
	Logging.xmlError(xmlFile, "Player is missing unique id!")
end

-- Local values: self, mission, playerData, style, isDefaultStyle, lastPlayerStyle
function Player.createServerInstance(isClient, isOwner, connection, userId, farmId, userManager)
	local v42_ = Player.new(true, isClient)
	v42_.farmId = farmId
	v42_.userId = userId
	v42_:setUniqueUserId(userManager:getUniqueUserIdByUserId(userId))
	v42_.walkDistance = 0
	v42_.animUpdateTime = 0
	v42_.allowPlayerPickUp = Platform.allowPlayerPickUp
	v42_.debugFlightMode = false
	v42_.debugFlightCoolDown = 0
	v42_.requestedFieldData = false
	v42_:initialise(connection, isOwner)
	local v43_ = g_currentMission.playerSystem:getPlayerDataByUniqueId(v42_.uniqueUserId)
	v42_:load(v43_)
	local v44_ = false
	local v45_
	if v43_ == nil then
		v45_ = nil
	else
		v45_ = v43_.style
	end
	if v45_ == nil then
		local v46_ = g_gameSettings.lastPlayerStyle
		if isOwner and (v46_ ~= nil and v46_:isValid()) then
			v45_ = PlayerStyle.defaultStyle()
			v45_:copyFrom(v46_)
		end
		if v45_ == nil then
			v45_ = PlayerStyle.defaultStyle()
			v44_ = true
		end
	end
	v42_:setStyleAsync(v45_, v44_, nil, true)
	v42_:register(false)
	return v42_
end

-- Upvalues: Player_mt
-- Local values: self
function Player.new(isServer, isClient)
	-- upvalues: (copy) Player_mt
	local v49_ = Object.new(isServer, isClient, Player_mt)
	v49_.userId = nil
	v49_.isDefaultStyle = true
	v49_.filename = nil
	v49_.connection = nil
	v49_.networkComponent = nil
	v49_.positionalInterpolator = nil
	v49_.spawnVehicle = nil
	v49_.spawnPositionX = nil
	v49_.spawnPositionY = nil
	v49_.spawnPositionZ = nil
	v49_.spawnYaw = nil
	v49_.dirtyFlag = v49_:getNextDirtyFlag()
	v49_.isOwner = false
	v49_.isControlled = false
	v49_.isLocallyControlled = nil
	v49_.farmId = FarmManager.SPECTATOR_FARM_ID
	v49_.stateEvents = {}
	v49_:registerStateEvents()
	v49_.stateFunctions = {}
	v49_:registerStateFunctions()
	v49_.playerHotspot = PlayerHotspot.new()
	v49_.hands = nil
	v49_.carriedHandTools = {}
	v49_.currentHandTool = nil
	v49_.currentHandToolIndex = 0
	v49_.lastHandToolIndex = 0
	v49_.maximumHandToolCarryMass = Player.MAX_HAND_TOOL_CARRY_MASS
	v49_.inputComponent = nil
	v49_.camera = nil
	v49_.targeter = nil
	v49_.graphicsComponent = HumanGraphicsComponent.new()
	v49_.graphicsState = PlayerGraphicsState.new()
	v49_.capsuleController = PlayerCCT.new()
	v49_.mover = PlayerMover.new(v49_)
	v49_.stateMachine = PlayerStateMachine.new(v49_)
	v49_.stateMachine:createStateIndexNameMapping()
	v49_.hudUpdater = PlayerHUDUpdater.new()
	v49_.debugFunctionId = nil
	v49_.isFirstPerson = true
	v49_.isHoldingChainsaw = false
	v49_.isCutting = false
	v49_.isVerticalCut = true
	v49_.toggleFlightModeCommand = nil
	v49_.toggleSuperSpeedCommand = nil
	v49_.isStrafeWalkMode = false
	v49_.forceHandToolFirstPerson = false
	v49_.isFlashlightActive = false
	return v49_
end

function Player:initialise(connection, isOwner)
	self.connection = connection
	self.isOwner = isOwner == true
	if self.isOwner or self.isClient then
		g_messageCenter:subscribeOneshot(MessageType.CURRENT_MISSION_LOADED, Player.onStartMission, self)
	end
	if self.isServer then
		g_messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, Player.playerFarmChanged, self)
	end
	g_messageCenter:subscribe(ContractingStateEvent, Player.onContractingStateChanged, self)
	self.stateMachine.states.onFoot:setIsPassive(not self.isOwner)
	self.rootNode = createTransformGroup("Player Root")
	link(getRootNode(), self.rootNode)
	self.capsuleController:setMass(self.graphicsComponent.model:getMass())
	self.capsuleController:setRootNode(self.rootNode)
	self.capsuleController:rebuild()
	g_currentMission:addNodeObject(self.rootNode, self)
	if self.isOwner then
		self.inputComponent = PlayerInputComponent.new(self)
		self.camera = PlayerCamera.new(self)
		self.targeter = PlayerTargeter.new(self)
		self.inputComponent:registerActionEvents()
		self.camera:initialise()
		HandToolUtil.addHandToolHolderTarget(self.targeter)
	elseif self.isServer then
		self.positionalInterpolator = PlayerPositionalInterpolator.new(self, PlayerPositionalInterpolator.INTERPOLATION_TARGET_ENUM.GRAPHICAL_NODE)
	else
		self.positionalInterpolator = PlayerPositionalInterpolator.new(self, PlayerPositionalInterpolator.INTERPOLATION_TARGET_ENUM.ROOT_NODE)
	end
	self:addStateEvent(function(...)
		-- upvalues: (copy) self
		for _, v53_ in ipairs(self.carriedHandTools) do
			v53_:setCarryingPlayerEnteredVehicle()
		end
	end, nil, "onEnterVehicle")
	self:addStateEvent(function(...)
		-- upvalues: (copy) self
		for _, v54_ in ipairs(self.carriedHandTools) do
			v54_:setCarryingPlayerExitedVehicle()
		end
	end, nil, "onLeaveVehicle")
	self.graphicsComponent:initialize()
	self.mover:initialise()
	if self.isServer then
		self.networkComponent = PlayerServerNetworkComponent.new(self)
	elseif isOwner then
		self.networkComponent = PlayerLocalNetworkComponent.new(self)
	else
		self.networkComponent = PlayerRemoteNetworkComponent.new(self)
	end
	self.isStrafeWalkMode = not self.isOwner
	self.forceHandToolFirstPerson = self.isOwner
	self.mover:setPosition(0, -200, 0, true)
	if self.isOwner and g_addTestCommands then
		addConsoleCommand("gsTipToTrigger", "Tips a fillType into a trigger", "consoleCommandTipToTrigger", self, "fillTypeName; amount")
		addConsoleCommand("gsPlayerToggleStrafeWalkMode", "Toggles strafe walk mode", "consoleCommandToggleStrafeWalkMode", self)
		addConsoleCommand("gsPlayerToggleForceHandToolFirstPerson", "Toggle the force handtool mode", "consoleCommandToggleForceHandToolFirstPerson", self)
	end
end

-- Local values: mission, _, handToolUniqueId, handData, flashlightData, startHandTools, _, xmlFilename, data
function Player:load(playerData)
	local v57_ = g_currentMission
	self:createConsoleCommands()
	if self.isServer then
		if playerData ~= nil then
			local v58_ = playerData.spawnPositionX
			local v59_ = playerData.spawnPositionY
			local v60_ = playerData.spawnPositionZ
			self.spawnPositionX = v58_
			self.spawnPositionY = v59_
			self.spawnPositionZ = v60_
			self.spawnYaw = playerData.spawnYaw
			self.spawnVehicle = self:resolveSpawnVehicle(playerData.spawnVehicleUniqueId)
			self.pendingHandToolUniqueIds = {}
			for _, v61_ in ipairs(playerData.handToolUniqueIds) do
				local v62_ = self.pendingHandToolUniqueIds
				table.insert(v62_, v61_)
			end
		end
		self.pendingStartHandTools = {}
		local v63_ = HandToolLoadingData.new()
		v63_:setFilename("data/handTools/hands.xml")
		v63_:setOwnerFarmId(self.farmId)
		v63_:setIsSaved(false)
		v63_:setCanBeDropped(false)
		self.pendingStartHandTools[v63_] = true
		v63_.areHands = true
		v63_:load(self.onStartHandToolLoaded, self, v63_)
		local v64_ = HandToolLoadingData.new()
		v64_:setFilename("data/handTools/brandless/flashlight/flashlight.xml")
		v64_:setOwnerFarmId(self.farmId)
		v64_:setIsSaved(false)
		v64_:setCanBeDropped(false)
		v64_:setHolder(self)
		self.pendingStartHandTools[v64_] = true
		v64_:load(self.onStartHandToolLoaded, self, v64_)
		local v65_ = v57_.handToolSystem:getStartingHandTools()
		for _, v66_ in ipairs(v65_) do
			local v67_ = HandToolLoadingData.new()
			v67_:setFilename(v66_)
			v67_:setOwnerFarmId(self.farmId)
			v67_:setHolder(self)
			v67_:setIsSaved(false)
			v67_:setCanBeDropped(false)
			self.pendingStartHandTools[v67_] = true
			v67_:load(self.onStartHandToolLoaded, self, v67_)
		end
		self.mover:teleportToSpawnPoint()
	end
	self.capsuleController:rebuild()
	self.mover:onPlayerLoad()
	if self.isOwner then
		self.inputComponent:onPlayerLoad()
		self.capsuleController:onPlayerLoad(self)
		self.camera:onPlayerLoad()
	else
		self.mover:disablePhysics()
	end
	v57_.playerSystem:addPlayer(self)
	if self.isServer and not self.isOwner then
		self:onStartMission()
	end
end

-- Local values: currentVehicle, seatIndex, mission, loadingData, i, handTool
function Player:delete()
	local v69_ = self:getCurrentVehicle()
	if v69_ ~= nil and not v69_:getIsBeingDeleted() then
		local v70_
		if v69_.getPassengerSeatIndexByPlayer == nil then
			v70_ = nil
		else
			v70_ = v69_:getPassengerSeatIndexByPlayer(self.userId)
		end
		if v70_ == nil then
			v69_:onPlayerLeaveVehicle()
		else
			v69_:leavePassengerSeat(self.isOwner, v70_)
		end
	end
	local v71_ = g_currentMission
	v71_.playerSystem:removePlayer(self)
	if self.pendingStartHandTools ~= nil then
		for v72_ in pairs(self.pendingStartHandTools) do
			v72_:cancelLoading()
		end
	end
	if self.swsObstacle ~= nil then
		v71_.shallowWaterSimulation:removeObstacle(self.swsObstacle)
		self.swsObstacle = nil
	end
	if v71_.aiSystem ~= nil then
		v71_.aiSystem:removeObstacle(self.rootNode)
	end
	g_messageCenter:unsubscribeAll(self)
	if self.hudUpdater ~= nil then
		self.hudUpdater:delete()
		self.hudUpdater = nil
	end
	if self.isOwner then
		self.inputComponent:unregisterActionEvents()
		self.inputComponent:stopListeningForBindingChanges()
		removeConsoleCommand("gsPlayerDebugFlagToggle")
		removeConsoleCommand("gsPlayerDebugFlagVerbosityToggle")
		removeConsoleCommand("gsPlayerFlightToggle")
	end
	if self.playerHotspot ~= nil then
		v71_:removeMapHotspot(self.playerHotspot)
		self.playerHotspot:delete()
		self.playerHotspot = nil
	end
	if self.stateMachine ~= nil then
		self.stateMachine:delete()
		self.stateMachine = nil
	end
	if self.hands ~= nil then
		self.hands:delete()
		self.hands = nil
	end
	for v73_ = #self.carriedHandTools, 1, -1 do
		local v74_ = self.carriedHandTools[v73_]
		if v74_.isPlayerStartHandTool then
			v74_:delete()
		else
			v74_:setHolder(nil, true)
		end
	end
	if self.graphicsComponent ~= nil then
		self.graphicsComponent:delete()
		self.graphicsComponent = nil
	end
	if self.mover ~= nil then
		self.mover:delete()
		self.mover = nil
	end
	if self.capsuleController ~= nil then
		self.capsuleController:delete()
		self.capsuleController = nil
	end
	if self.camera ~= nil then
		self.camera:delete()
		self.camera = nil
	end
	g_currentMission:removeNodeObject(self.rootNode)
	delete(self.rootNode)
	self.isDeleted = true
	Player:superClass().delete(self)
end

-- Local values: isOwner, x, y, z, currentStyle
function Player:writeStream(streamId, connection)
	Player:superClass().writeStream(self, streamId, connection)
	local v78_ = connection == self.connection
	streamWriteBool(streamId, v78_)
	local v79_, v80_, v81_ = self.capsuleController:getPosition()
	streamWriteFloat32(streamId, v79_)
	streamWriteFloat32(streamId, v80_)
	streamWriteFloat32(streamId, v81_)
	streamWriteBool(streamId, self.isControlled)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	User.streamWriteUserId(streamId, self.userId)
	if streamWriteBool(streamId, not self.isDefaultStyle) then
		self.graphicsComponent:getStyle():writeStream(streamId, connection)
	end
	if streamWriteBool(streamId, self.hands ~= nil) then
		NetworkUtil.writeNodeObject(streamId, self.hands)
	end
end

-- Local values: isOwner, x, y, z, isControlled, style
function Player:readStream(streamId, connection, objectId)
	Player:superClass().readStream(self, streamId, connection)
	local v85_ = streamReadBool(streamId)
	local v86_ = streamReadFloat32(streamId)
	local v87_ = streamReadFloat32(streamId)
	local v88_ = streamReadFloat32(streamId)
	local v89_ = streamReadBool(streamId)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self.userId = User.streamReadUserId(streamId)
	self:initialise(connection, v85_)
	local v90_
	if streamReadBool(streamId) then
		v90_ = self.graphicsComponent:getStyle()
		v90_:readStream(streamId, connection)
	else
		v90_ = PlayerStyle.defaultStyle()
	end
	if streamReadBool(streamId) then
		self.pendingHandsId = NetworkUtil.readNodeObjectId(streamId)
	end
	self:load(nil)
	self:setStyleAsync(v90_, false, nil, true)
	self:teleportTo(v86_, v87_, v88_, true, true)
	if v89_ then
		self:show()
	else
		self:hide()
	end
end

function Player:writeUpdateStream(streamId, connection, dirtyMask)
	if self.networkComponent then
		self.networkComponent:writeUpdateStream(streamId, connection, dirtyMask)
	end
end

function Player:readUpdateStream(streamId, timestamp, connection)
	if self.networkComponent then
		self.networkComponent:readUpdateStream(streamId, connection, timestamp)
	end
end

function Player:onStartHandToolLoaded(handTool, loadingState, loadingData)
	if handTool ~= nil then
		if loadingData.areHands then
			self.hands = handTool
			table.removeElement(self.carriedHandTools, handTool)
			local v102_ = self.carriedHandTools
			table.insert(v102_, 1, handTool)
			handTool:setHolder(self, true)
			self:setCurrentHandTool(handTool, true)
		end
		handTool.isPlayerStartHandTool = true
	end
	self.pendingStartHandTools[loadingData] = nil
end

-- Local values: hands, mission, handToolSystem, _, handToolUniqueId, handTool, x, y, z
function Player:update(dt)
	if self.pendingHandsId ~= nil then
		local v105_ = NetworkUtil.getObject(self.pendingHandsId)
		if v105_ ~= nil then
			self.hands = v105_
			self.pendingHandsId = nil
		end
	end
	if self.pendingHandToolUniqueIds ~= nil then
		local v106_ = g_currentMission.handToolSystem
		for _, v107_ in ipairs(self.pendingHandToolUniqueIds) do
			local v108_ = v106_:getHandToolByUniqueId(v107_)
			if v108_ ~= nil and v108_:getHolder() == nil then
				v108_:setHolder(self, false)
			end
		end
		self.pendingHandToolUniqueIds = nil
	end
	if self.isControlled then
		self:raiseActive()
		if self.isOwner and self.hudUpdater ~= nil then
			local v109_, v110_, v111_ = self:getPosition()
			self.hudUpdater:update(dt, v109_, v110_, v111_, self:getYaw())
		end
	end
	self.stateMachine:update(dt)
end

function Player:updateTick(dt)
	if self.stateMachine.currentState.updateTick ~= nil then
		self.stateMachine.currentState:updateTick(dt)
	end
end

-- Local values: currentHandTool
function Player:draw()
	if g_noHudModeEnabled then
		return
	elseif not self:getIsInVehicle() then
		local v115_ = self:getHeldHandTool(true)
		if v115_ ~= nil then
			v115_:draw()
		end
	end
end

-- Local values: x, y, z, x1, y1, z1, diffX, diffY, diffZ, dist
function Player:drawUIInfo()
	if self.isClient and (self.isControlled and (self ~= g_localPlayer and (not g_gui:getIsGuiVisible() and (not g_noHudModeEnabled and (g_gameSettings:getValue(GameSettings.SETTING.SHOW_MULTIPLAYER_NAMES) and self.graphicsComponent.isGraphicsRootNodeVisible))))) then
		local v117_, v118_, v119_ = getTranslation(self.graphicsComponent.graphicsRootNode)
		local v120_, v121_, v122_ = getWorldTranslation(g_cameraManager:getActiveCamera())
		local v123_ = v117_ - v120_
		local v124_ = v118_ - v121_
		local v125_ = v119_ - v122_
		if MathUtil.vector3LengthSq(v123_, v124_, v125_) <= 10000 then
			local v126_ = v118_ + self.graphicsComponent.nameTagOffsetY
			Utils.renderTextAtWorldPosition(v117_, v126_, v119_, self:getNickname(), getCorrectTextSize(0.02), 0)
		end
	end
end

-- Local values: mission, user
function Player:getNickname()
	local v128_ = g_currentMission.userManager:getUserByUserId(self.userId)
	return v128_ == nil and "Unknown" or v128_:getNickname()
end

-- Local values: playerData, _, handTool, mission
function Player:createData()
	local v130_ = {
		["uniqueId"] = self.uniqueUserId,
		["lastConnectedDateTime"] = getDate("%Y/%m/%d %H:%M"),
		["style"] = self.graphicsComponent:getStyle(),
		["handToolUniqueIds"] = {}
	}
	if self:getHasSpawnPosition() then
		local v131_, v132_, v133_ = self:getSpawnPosition()
		v130_.spawnPositionX = v131_
		v130_.spawnPositionY = v132_
		v130_.spawnPositionZ = v133_
	end
	if self:getHasSpawnYaw() then
		v130_.spawnYaw = self:getSpawnYaw()
	end
	for _, v134_ in ipairs(self.carriedHandTools) do
		if v134_:getNeedsSaving() then
			local v135_ = v130_.handToolUniqueIds
			table.insert(v135_, v134_:getUniqueId())
		end
	end
	if not (self:getHasSpawnVehicle() and g_currentMission.accessHandler:canPlayerAccess(self:getSpawnVehicle(), self)) then
		return v130_
	end
	v130_.spawnVehicleUniqueId = self:getSpawnVehicle().uniqueId
	return v130_
end

-- Local values: playerData
function Player:saveToXMLFile(xmlFile, baseKey)
	local v139_ = self:createData()
	Player.saveDataToXMLFile(xmlFile, v139_, baseKey)
end

function Player:applyCustomWorkStyle(presetName)
	self.graphicsComponent:applyCustomWorkStyle(presetName, self.isOwner)
end

-- Local values: finishedStyleCallback
function Player:setStyleAsync(style, isDefaultStyle, callback, noEventSend)
	self.isDefaultStyle = isDefaultStyle
	self.graphicsComponent:setStyleAsync(style, function(p147_, p148_, p149_)
		-- upvalues: (copy) self, (copy) callback
		self:onStyleChanged(p147_, p148_, p149_)
		if callback ~= nil then
			callback(p147_, p148_)
		end
	end, nil, nil, false, nil, self.isOwner)
	PlayerSetStyleEvent.sendEvent(self, style, NetworkUtil.getObjectId(self), noEventSend)
end

-- Local values: style, i, handTool, isFirstPerson, isVisible
function Player:onStyleChanged(loadingState, loadedNewPlayerModel, args)
	local v151_ = self.graphicsComponent:getStyle()
	if self.isOwner then
		g_gameSettings:setValue(GameSettings.SETTING.LAST_PLAYER_STYLE_MALE, v151_:getIsMale())
	end
	self.capsuleController:rebuild()
	g_messageCenter:publish(MessageType.PLAYER_STYLE_CHANGED, v151_, self.userId)
	for _, v152_ in ipairs(self.carriedHandTools) do
		v152_:setCarryingPlayerStyleChanged()
	end
	local v153_
	if self.camera == nil then
		v153_ = false
	else
		v153_ = self.camera.isFirstPerson
	end
	local v154_ = self.isControlled
	if v154_ then
		v154_ = not v153_
	end
	self.graphicsComponent:setModelVisibility(v154_, true)
end

function Player:getUniqueUserId()
	return self.uniqueUserId
end

function Player:getUniqueId()
	return self.uniqueUserId
end

function Player:setUniqueUserId(uniqueUserId)
	if string.isNilOrWhitespace(self.uniqueUserId) or uniqueUserId == self.uniqueUserId then
		self.uniqueUserId = uniqueUserId
	else
		Logging.error("Cannot change a player\'s unique id after it has been set!")
	end
end

function Player:getFarmId()
	return self.farmId
end

function Player:setFarmId(farmId)
	if self.isServer then
		self.farmId = farmId
		PlayerSetFarmEvent.sendEvent(self, farmId)
	else
		Logging.devError("setFarm only allowed on Server")
	end
end

function Player:toggleFlashlight()
	self:setFlashlightIsActive(not self.isFlashlightActive)
end

-- Local values: flashlight, currentHandTool, i, handTool, handTool
function Player:setFlashlightIsActive(isActive, noEventSend)
	local v166_ = nil
	local v167_ = self.currentHandTool
	if v167_ == nil then
		v167_ = v166_
	elseif not v167_.isFlashlight then
		v167_ = v166_
	end
	for v168_ = #self.carriedHandTools, 1, -1 do
		local v169_ = self.carriedHandTools[v168_]
		if v169_.isFlashlight then
			if v167_ == nil then
				v167_ = v169_
			end
			if v169_ ~= v167_ then
				v169_:setFlashlightIsActive(false, noEventSend)
			end
		end
	end
	self.isFlashlightActive = isActive
	if isActive and self:getHeldHandTool(false) == nil then
		self:setCurrentHandTool(v167_, noEventSend)
	end
	if v167_ ~= nil then
		v167_:setFlashlightIsActive(isActive, noEventSend)
	end
end

function Player:onPickupHandTool(handTool)
	if handTool == nil then
		return false
	end
	table.addElement(self.carriedHandTools, handTool)
	handTool:setCarryingPlayer(self)
	return true
end

-- Local values: success
function Player:onDropHandTool(handTool)
	Logging.devInfo("Player.onDropHandTool: try dropping hand tool %q (%s) from player", handTool.configFileName, handTool.uniqueId)
	if handTool == nil then
		return
	else
		if self.currentHandTool == handTool then
			self:setCurrentHandTool(nil, true)
		end
		self:setFlashlightIsActive(self.isFlashlightActive, true)
		if table.removeElement(self.carriedHandTools, handTool) then
			handTool:setCarryingPlayer(nil)
		else
			Logging.error("Player.onDropHandTool: Could not remove hand tool %q (%s) from player, as it was not carried by the player!", handTool.configFileName, handTool.uniqueId)
			printCallstack()
		end
	end
end

-- Local values: mission
function Player:getCanPickupHandTool(handTool)
	if handTool == nil then
		return false
	elseif g_currentMission.accessHandler:canPlayerAccess(handTool, self, true) then
		return not self:getReachedHandToolLimit(handTool)
	else
		return false
	end
end

function Player:getReachedHandToolLimit(handTool)
	return self:getCarriedHandToolMass() + handTool.mass > self.maximumHandToolCarryMass
end

function Player:getCanPickupHandToolFromMenu(handTool)
	return false
end

function Player:getHolderName()
	return string.format(g_i18n:getText("ui_handToolHolderPlayer"), self:getNickname())
end

-- Local values: numHandTools, newIndex, lowerLimit
function Player:cycleHandTool(direction)
	local v181_ = #self.carriedHandTools
	local v182_ = self.currentHandToolIndex + math.sign(direction)
	local v183_ = self.hands == nil and 0 or 1
	if v181_ < v182_ then
		v181_ = v183_
	elseif v182_ >= v183_ then
		v181_ = v182_
	end
	self:switchToHandToolIndex(v181_)
end

-- Local values: index, numHandTools
function Player:toggleHandTool()
	local v185_ = self.lastHandToolIndex
	if self.currentHandToolIndex > 1 then
		v185_ = 1
	elseif self.lastHandToolIndex == 1 then
		v185_ = self.lastHandToolIndex
	end
	local v186_ = v185_ == 0 and self.hands ~= nil and 1 or v185_
	local v187_ = #self.carriedHandTools
	if v187_ < v186_ then
		v186_ = v187_
	end
	self:switchToHandToolIndex(v186_)
end

-- Local values: newHandTool
function Player:switchToHandToolIndex(index)
	if self.currentHandToolIndex == index then
		return
	elseif index < 0 or #self.carriedHandTools < index then
		return
	else
		local v190_ = self.carriedHandTools[index]
		if index > 0 and v190_ == nil then
			Logging.error("Cannot switch to hand tool with index of %d! Hand tool count: %d", index, #self.carriedHandTools)
			return
		elseif self.currentHandTool == v190_ then
			self.lastHandToolIndex = self.currentHandToolIndex
			self.currentHandToolIndex = table.find(self.carriedHandTools, self.currentHandTool) or 0
		elseif not self:setCurrentHandTool(v190_) then
			Logging.error("Could not switch to hand tool with given index %d despite it existing!", index)
		end
	end
end

-- Local values: lastHandTool, handToolId
function Player:setCurrentHandTool(handTool, noEventSend)
	if self.currentHandTool == handTool then
		return false
	end
	if handTool ~= nil and not self:getIsCarryingHandTool(handTool) then
		return false
	end
	local v194_ = handTool or self.hands
	local v195_ = self.currentHandTool
	self.currentHandTool = v194_
	self.lastHandToolIndex = self.currentHandToolIndex
	self.currentHandToolIndex = table.find(self.carriedHandTools, self.currentHandTool) or 0
	if v195_ ~= nil and v195_ ~= v194_ then
		v195_:stopHolding()
	end
	local v196_
	if v194_ == nil then
		v196_ = nil
	else
		if v195_ ~= v194_ then
			v194_:startHolding()
		end
		v196_ = NetworkUtil.getObjectId(v194_)
	end
	if self.isFlashlightActive and v194_ == self.hands then
		self:setFlashlightIsActive(false, true)
	end
	PlayerHoldHandToolEvent.sendEvent(self, v196_, noEventSend)
	return true
end

function Player:getForceHandToolFirstPerson()
	local v198_ = self.isOwner
	if v198_ then
		v198_ = self.forceHandToolFirstPerson
	end
	return v198_
end

-- Local values: handTool
function Player:getIsHoldingHandTool()
	return self:getHeldHandTool() ~= nil
end

-- Local values: currentHandTool
function Player:getHeldHandTool(includeHands)
	local v202_ = self.currentHandTool
	if v202_ == nil then
		return nil
	elseif v202_ == self.hands and not includeHands then
		return nil
	else
		return v202_
	end
end

function Player:getIsCarryingHandTool(handTool)
	local v205_
	if handTool == nil then
		v205_ = false
	else
		v205_ = table.find(self.carriedHandTools, handTool) ~= nil
	end
	return v205_
end

-- Local values: summedWeight, _, handTool
function Player:getCarriedHandToolMass()
	local v207_ = 0
	for _, v208_ in ipairs(self.carriedHandTools) do
		v207_ = v207_ + v208_.mass
	end
	return v207_
end

-- Local values: currentCameraNode, cameraDirectionX, _, cameraDirectionZ, cameraYaw, x, _, z
function Player:getMapPositionAndLookYaw()
	local v210_ = self:getCurrentCameraNode()
	local v211_, _, v212_ = localDirectionToWorld(v210_, 0, 0, -1)
	local v213_ = MathUtil.getYRotationFromDirection(v211_, v212_)
	local v214_, _, v215_ = self:getPosition()
	return v214_, v215_, v213_
end

-- Local values: runMultiplier, handTool
function Player:getRunMultiplier()
	local v217_ = 1
	local v218_ = self:getHeldHandTool(true)
	if v218_ ~= nil then
		v217_ = v218_.runMultiplier or v217_
	end
	return v217_
end

-- Local values: walkMultiplier, handTool
function Player:getWalkMultiplier()
	local v220_ = 1
	local v221_ = self:getHeldHandTool(true)
	if v221_ ~= nil then
		v220_ = v221_.walkMultiplier or v220_
	end
	return v220_
end

-- Local values: jumpMultiplier, handTool
function Player:getJumpMultiplier()
	local v223_ = 1
	local v224_ = self:getHeldHandTool(true)
	if v224_ ~= nil then
		v223_ = v224_.jumpMultiplier or v223_
	end
	return v223_
end

-- Local values: playerStyle, mission
function Player:requestToEnterVehicle(vehicle, force)
	if self.isDeleted then
		return
	else
		local v228_ = self.graphicsComponent:getStyle()
		if g_currentMission.accessHandler:canPlayerAccess(vehicle, self) and v228_ ~= nil then
			g_client:getServerConnection():sendEvent(VehicleEnterRequestEvent.new(vehicle, v228_, self.farmId, force))
		end
	end
end

-- Local values: mission
function Player:requestToEnterVehicleAsPassenger(vehicle, seatIndex)
	if self.isDeleted then
		return
	elseif g_currentMission.accessHandler:canPlayerAccess(vehicle) then
		g_client:getServerConnection():sendEvent(EnterablePassengerEnterRequestEvent.new(vehicle, seatIndex))
	end
end

-- Local values: currentVehicle, seatIndex
function Player:leaveVehicle(vehicle, noEventSend)
	if self.isDeleted then
		return
	else
		local v235_ = vehicle or self:getCurrentVehicle()
		if v235_ == nil then
			Logging.devWarning("Player \'%s\' tries to leave vehicle, but is not in a vehicle anymore", self:getNickname())
			return
		else
			local v236_
			if v235_.getPassengerSeatIndexByPlayer == nil then
				v236_ = nil
			else
				v236_ = v235_:getPassengerSeatIndexByPlayer(self.userId)
			end
			if v236_ == nil then
				VehicleLeaveEvent.sendEvent(v235_, self.userId, noEventSend)
				v235_:onPlayerLeaveVehicle()
				self:onLeaveVehicle(v235_)
			else
				EnterablePassengerLeaveEvent.sendEvent(v235_, self.userId, noEventSend)
				v235_:leavePassengerSeat(self.isOwner, v236_)
				self:onLeaveVehicleAsPassenger(v235_)
			end
		end
	end
end

-- Local values: mission, vehicle
function Player:cycleCurrentVehicle(direction)
	local v239_ = g_currentMission
	if v239_.isPlayerFrozen or not (v239_.isRunning and v239_.isToggleVehicleAllowed) then
		return
	else
		local v240_ = v239_.vehicleSystem:getNextEnterableVehicle(self:getCurrentVehicle(), direction)
		if v240_ ~= nil then
			self:requestToEnterVehicle(v240_)
		end
	end
end

-- Local values: mission, vehicle
function Player:resolveSpawnVehicle(spawnVehicleUniqueId)
	if string.isNilOrWhitespace(spawnVehicleUniqueId) then
		return nil
	else
		local v243_ = g_currentMission
		local v244_ = v243_.vehicleSystem:getVehicleByUniqueId(spawnVehicleUniqueId)
		if v244_ == nil then
			return nil
		elseif v243_.accessHandler:canPlayerAccess(v244_, self) then
			return v244_
		else
			return nil
		end
	end
end

-- Local values: noClipOutputFunction
function Player:createConsoleCommands()
	if self.isOwner then
		addConsoleCommand("gsPlayerDebugFlagToggle", "Toggles the debug display flag with the given name for the player", "consoleCommandToggleDebugFlag", self)
		addConsoleCommand("gsPlayerDebugFlagVerbosityToggle", "Toggles the debug display verbosity flag with the given name for the player", "consoleCommandToggleVerboseDebugFlag", self)
		self:handleDebugBindings()
		self.toggleFlightModeCommand = ConsoleValueToggle.new("gsPlayerFlightToggle", "Enables flight to be toggled (key J). Use keys Q and E to change altitude", nil, function(_, p246_)
			return "Player flight " .. p246_
		end)
		self.toggleSuperSpeedCommand = ConsoleValueToggle.new("gsPlayerSuperSpeedToggle", "Massively increases the movement speed of the player", g_isDevelopmentVersion or Player.START_WITH_SUPERSPEED, function(_, p247_)
			return "Player super speed " .. p247_
		end)
		self.toggleNoClipCommand = ConsoleValueToggle.new("gsPlayerNoClipToggle", "Toggles player collision. First argument is a boolean to determine if collision with the terrain should also be disabled. Second argument to determine if player should interact with triggers", nil, function(p248_, _, p249_)
			return p248_ and (Utils.stringToBoolean(p249_) and "Player noclip enabled, including terrain" or "Player noclip enabled, excluding terrain. To include terrain, use \"true\" as the first parameter in the command") or "Player noclip disabled"
		end, "[disableTerrainCollision=false]; [ignorePlayerInTriggers=false]")
	end
end

-- Local values: mission
function Player:onStartMission()
	local v251_ = g_currentMission
	if g_dedicatedServer == nil or self.userId ~= v251_:getServerUserId() then
		self.stateMachine.states.onFoot:onStateEntered()
		if self:getHasSpawnVehicle() then
			self:requestToEnterVehicle(self.spawnVehicle)
		elseif self.isServer and not self.isOwner then
			self.graphicsComponent:setGraphicsRootNodeVisibility(false)
			g_messageCenter:subscribe(MessageType.ON_CLIENT_START_MISSION, self.onClientStartMission, self)
		end
	else
		self:hide()
		return
	end
end

function Player:moveCCTExternal(moveX, moveY, moveZ)
	if self.capsuleController ~= nil then
		self.capsuleController:moveExternal(moveX, moveY, moveZ)
	end
end

function Player:getTouchingNode()
	if self.capsuleController == nil then
		return nil
	else
		return self.capsuleController:getTouchingNode()
	end
end

function Player:onClientStartMission(user)
	if user ~= nil and self.userId == user:getId() then
		self.graphicsComponent:setGraphicsRootNodeVisibility(true)
	end
end

-- Local values: i, handTool
function Player:playerFarmChanged(player)
	if player == self then
		for v261_ = #self.carriedHandTools, 1, -1 do
			local v262_ = self.carriedHandTools[v261_]
			if v262_:getCanBeDropped() then
				v262_:setHolder(nil)
			else
				v262_:setOwnerFarmId(self.farmId, true)
			end
		end
	end
end

-- Local values: i, handTool
function Player:onContractingStateChanged(farmId, contractingFarmId, isContracting)
	if self.farmId == farmId then
		if not isContracting then
			for v267_ = #self.carriedHandTools, 1, -1 do
				local v268_ = self.carriedHandTools[v267_]
				if v268_:getOwnerFarmId() == contractingFarmId and v268_:getCanBeDropped() then
					v268_:setHolder(nil)
				end
			end
		end
	end
end

function Player:registerStateEvents()
	self:registerStateEventList("onEnterVehicle")
	self:registerStateEventList("onLeaveVehicle")
	self:registerStateEventList("onEnterVehicleAsPassenger")
	self:registerStateEventList("onLeaveVehicleAsPassenger")
	self:registerStateEventList("onEnterRollercoaster")
	self:registerStateEventList("onLeaveRollercoaster")
	self:registerStateEventList("onPerspectiveSwitched")
end

-- Local values: listenerList, existingMemberType
function Player:registerStateEventList(eventName)
	if self.stateEvents[eventName] == nil then
		local v272_ = nil
		local v273_ = self[eventName]
		local v274_ = type(v273_)
		if v274_ == "function" then
			v272_ = ListenerList.new(true)
			v272_:registerListener(self[eventName], self)
		elseif v274_ == "nil" then
			v272_ = ListenerList.new(true)
		elseif v274_ ~= "table" or not self[eventName]:isa(ListenerList) then
			Logging.warning("Cannot overwrite player member %s with an event function, as it is a %s", eventName, v274_)
			return
		end
		self[eventName] = v272_
		self.stateEvents[eventName] = eventName
	else
		Logging.warning("State event with name %s has already been registered!", eventName)
	end
end

function Player:addStateEvent(eventFunction, eventTarget, eventName)
	if self.stateEvents[eventName] == nil then
		Logging.warning("State event with name %q has not been registered!", eventName)
	else
		self[eventName]:registerListener(eventFunction, eventTarget)
	end
end

function Player:registerStateFunctions()
	self:registerStateFunction("getCurrentRootNode")
	self:registerStateFunction("getSpeed")
	self:registerStateFunction("getPosition")
	self:registerStateFunction("getYaw")
	self:registerStateFunction("getCurrentFacingDirection")
	self:registerStateFunction("getCurrentCameraNode")
	self:registerStateFunction("updateWhileInConversation")
	self:registerStateFunction("getIsInVehicle")
	self:registerStateFunction("getCurrentVehicle")
end

function Player:registerStateFunction(functionName)
	if self[functionName] == nil then
		if self.stateFunctions[functionName] == nil then
			self.stateFunctions[functionName] = functionName
			self[functionName] = function(_, ...)
				-- upvalues: (copy) self, (copy) functionName
				return self:fireStateFunction(functionName, ...)
			end
		else
			Logging.warning("State function with name %q has already been registered!", functionName)
		end
	else
		Logging.warning("Cannot register state function with name %q as the Player class already defines a member with the same name!", functionName)
		return
	end
end
function Player.fireStateFunction(p282_, p283_, ...)
	if p282_.stateFunctions[p283_] == nil then
		Logging.warning("State function with name %q has not been registered!", p283_)
	else
		local v284_ = p282_.stateMachine.currentState
		local v285_ = v284_[p283_]
		if type(v285_) == "function" then
			return v285_(v284_, ...)
		end
	end
end

-- Local values: kinematicNode, kinematicRotationNode
function Player:getHandsKinematicNode()
	if self.hands == nil then
		return false
	end
	local v287_, v288_ = self.hands:getKinematicNode()
	return v287_, v288_
end

function Player:getAreHandsHoldingObject()
	if self.hands == nil then
		return false
	else
		return self.hands:getIsHoldingItem()
	end
end

-- Local values: x, y, z, directionX, directionY, directionZ
function Player:getLookRay()
	if not self.isOwner then
		return nil, nil, nil, nil, nil, nil
	end
	local v291_, v292_, v293_ = localDirectionToWorld(self.camera.cameraRootNode, 0, 0, -1)
	if self.camera.isFirstPerson then
		local v294_, v295_, v296_ = self.camera:getCameraPosition()
		return v294_, v295_, v296_, v291_, v292_, v293_
	end
	if self.graphicsComponent == nil or (self.graphicsComponent.model == nil or self.graphicsComponent.model.thirdPersonHeadNode == nil) then
		return nil, nil, nil, nil, nil, nil
	end
	local v297_, v298_, v299_ = getWorldTranslation(self.graphicsComponent.model.thirdPersonHeadNode)
	return v297_, v298_, v299_, v291_, v292_, v293_
end

function Player:updateControlledState(isControlled, skipModel, skipMover)
	if isControlled == self.isControlled then
		return
	elseif isControlled then
		self:show(skipModel, skipMover)
	else
		self:hide(skipModel, skipMover)
	end
end

function Player:getIsControlled(ignoreLocal)
	if ignoreLocal or self.isLocallyControlled == nil then
		return self.isControlled
	else
		return self.isLocallyControlled
	end
end

-- Local values: spawnYaw, y, spawnPoint, mission, startPositionX, startPositionY, startPositionZ, dx, _, dz
function Player:findSpawnPositionAndYaw()
	local v307_ = self:getHasSpawnYaw() and (self:getSpawnYaw() or 0) or 0
	if self:getHasSpawnPosition() then
		return self.spawnPositionX, self.spawnPositionY, self.spawnPositionZ, v307_
	end
	if AutoLoadParams.enable == true and (AutoLoadParams.x ~= nil and AutoLoadParams.z ~= nil) then
		local v308_ = getTerrainHeightAtWorldPos(g_terrainNode, AutoLoadParams.x, 0, AutoLoadParams.z) + 0.2
		return AutoLoadParams.x, v308_, AutoLoadParams.z, v307_
	end
	local v309_ = g_farmManager:getSpawnPoint(self.farmId)
	local v310_ = g_currentMission
	if v309_ == nil or v310_ ~= nil and (v310_:getIsServer() and not v310_.missionInfo.isValid) then
		v309_ = g_mission00StartPoint
	end
	if v309_ == nil then
		Logging.error("Player could not find any valid spawn position!")
		return 0, 0, 0, v307_
	end
	local v311_, v312_, v313_ = getWorldTranslation(v309_)
	local v314_, _, v315_ = localDirectionToWorld(v309_, 0, 0, 1)
	return v311_, v312_, v313_, MathUtil.getYRotationFromDirection(v314_, v315_)
end

function Player:findEmptyAreaAroundPosition(x, y, z)
	return x, y, z
end

function Player:getHasSpawnVehicle()
	return self.spawnVehicle ~= nil
end

function Player:getSpawnVehicle()
	return self.spawnVehicle
end

-- Local values: mission
function Player:setSpawnVehicle(vehicle)
	local v323_ = g_currentMission
	if vehicle == nil or v323_.accessHandler:canPlayerAccess(vehicle, self) then
		self.spawnVehicle = vehicle
	end
end

function Player:getHasSpawnPosition()
	local v325_
	if self.spawnPositionX == nil or self.spawnPositionY == nil then
		v325_ = false
	else
		v325_ = self.spawnPositionZ ~= nil
	end
	return v325_
end

function Player:getSpawnPosition()
	return self.spawnPositionX, self.spawnPositionY, self.spawnPositionZ
end

function Player:setSpawnPosition(x, y, z)
	self.spawnPositionX = x
	self.spawnPositionY = y
	self.spawnPositionZ = z
end

function Player:getHasSpawnYaw()
	return self.spawnYaw ~= nil
end

function Player:getSpawnYaw()
	return self.spawnYaw
end

function Player:setSpawnYaw(spawnYaw)
	self.spawnYaw = spawnYaw
end

function Player:teleportTo(x, y, z, setNodeTranslation, noEventSend)
	self.mover:teleportTo(x, y, z, setNodeTranslation, noEventSend)
end

function Player:teleportToSpawnPoint(noEventSend)
	self.mover:teleportToSpawnPoint(noEventSend)
end

function Player:teleportToNPC(npc, noEventSend)
	self.mover:teleportToNPC(npc)
end

function Player:teleportToExitPoint(vehicle, noEventSend)
	self.mover:teleportToExitPoint(vehicle, noEventSend)
end

function Player:getMovementYaw()
	return self.mover:getMovementYaw()
end

function Player:setMovementYaw(yaw)
	self.mover:setMovementYaw(yaw)
end

function Player:getGraphicalSpeed()
	if self.isOwner then
		return self.mover:getSpeed()
	else
		return self.positionalInterpolator:getInterpolatedSpeed()
	end
end

function Player:getGraphicalVelocity()
	if self.isOwner then
		return self.mover:getVelocity()
	else
		return self.positionalInterpolator:getInterpolatedVelocity()
	end
end

function Player:getGraphicalPosition()
	if self.isOwner then
		return self.mover:getPosition()
	end
	if self.positionalInterpolator.targetNodeType == PlayerPositionalInterpolator.INTERPOLATION_TARGET_ENUM.GRAPHICAL_NODE then
		return self.positionalInterpolator:getInterpolatedPosition()
	end
	if self.positionalInterpolator.targetNodeType == PlayerPositionalInterpolator.INTERPOLATION_TARGET_ENUM.ROOT_NODE then
		return self.mover:getPosition()
	end
	Logging.error("Invalid state for player to get graphical position! Perhaps a missing case for INTERPOLATION_TARGET_ENUM?")
	return 0, 0, 0
end

function Player:getGraphicalYaw()
	if self.isOwner then
		return self:getMovementYaw()
	end
	if self.positionalInterpolator.targetNodeType == PlayerPositionalInterpolator.INTERPOLATION_TARGET_ENUM.GRAPHICAL_NODE then
		return self.positionalInterpolator:getInterpolatedYaw()
	end
	if self.positionalInterpolator.targetNodeType == PlayerPositionalInterpolator.INTERPOLATION_TARGET_ENUM.ROOT_NODE then
		return self:getMovementYaw()
	end
	Logging.error("Invalid state for player to get graphical yaw! Perhaps a missing case for INTERPOLATION_TARGET_ENUM?")
	return 0
end

function Player:setIsHoldingChainsaw(isHoldingChainsaw)
	self.isHoldingChainsaw = isHoldingChainsaw
end

function Player:setChainsawState(isCutting, isVerticalCut)
	self.isCutting = isCutting
	self.isVerticalCut = isVerticalCut
end

-- Local values: isControlled
function Player:showLocally()
	local v361_ = self.isControlled
	self:show()
	self.isLocallyControlled = true
	self.isControlled = v361_
end

-- Local values: isControlled
function Player:hideLocally()
	local v363_ = self.isControlled
	self:hide()
	self.isLocallyControlled = false
	self.isControlled = v363_
end

function Player:clearLocalHideState()
	self.isLocallyControlled = nil
	if self.isControlled then
		self:show()
	else
		self:hide()
	end
end

function Player:raiseDefaultDirtyFlag()
	if self.isServer or self.isOwner then
		self:raiseDirtyFlags(self.dirtyFlag)
	end
end

-- Local values: mission, isFirstPerson, isVisible, getXZVelocityAndRotYFunc, width, yOffset, i, handTool
function Player:show(skipShowingModel, skipEnablingMover, ignoreLocalCheck)
	if self.isDeleted then
		return
	elseif ignoreLocalCheck or self.isLocallyControlled == nil then
		local v370_ = g_currentMission
		self:raiseActive()
		if self.isServer then
			self.networkComponent:setShowHideParameters(skipShowingModel, skipEnablingMover)
			self:setOwnerConnection(self.connection)
			self:raiseDefaultDirtyFlag()
		end
		self.isControlled = true
		g_messageCenter:publish(MessageType.OWN_PLAYER_ENTERED)
		if self.isOwner then
			if v370_ ~= nil then
				v370_.environmentAreaSystem:setReferenceNode(self.camera.cameraRootNode)
			end
			self.camera:makeCurrent()
			self.inputComponent:listenForBindingChanges()
			self.inputComponent:addPauseListeners()
			if not skipShowingModel then
				local v371_
				if self.camera == nil then
					v371_ = false
				else
					v371_ = self.camera.isFirstPerson
				end
				self.graphicsComponent:setModelVisibility(not v371_, true)
			end
		elseif not skipShowingModel then
			self.graphicsComponent:setModelVisibility(true)
		end
		if v370_ ~= nil then
			if v370_.shallowWaterSimulation ~= nil and self.swsObstacle == nil then
				local v372_ = self.capsuleController:getRadius() * 1.5
				local v373_ = {
					[2] = self.capsuleController:getHeight() / 2
				}
				self.swsObstacle = v370_.shallowWaterSimulation:addObstacle(self.rootNode, v372_, self.capsuleController:getTotalHeight(), v372_, function()
					-- upvalues: (copy) self
					local v374_, _, v375_ = self.mover:getVelocity()
					if v374_ == 0 and (v375_ == 0 and self.stateMachine.currentState == self.stateMachine.states.onFoot) then
						local v376_ = self.stateMachine.currentState.currentState
						if v376_ == self.stateMachine.currentState.states.falling or v376_ == self.stateMachine.currentState.states.jumping then
							return math.random(5), math.random(5), 0
						end
					end
					return v374_, v375_, self.mover:getMovementYaw()
				end, nil, v373_)
			end
			if v370_.aiSystem ~= nil then
				v370_.aiSystem:addObstacle(self.rootNode, nil, nil, nil, 0.8, 2, 0.8, nil, false)
			end
		end
		if self.playerHotspot ~= nil then
			self.playerHotspot:setPlayer(self)
			self.playerHotspot:setOwnerFarmId(self.farmId)
			if v370_ ~= nil then
				v370_:addMapHotspot(self.playerHotspot)
			end
		end
		if self.isServer and (v370_ ~= nil and (v370_.trafficSystem ~= nil and v370_.trafficSystem.trafficSystemId ~= 0)) then
			addTrafficSystemPlayer(v370_.trafficSystem.trafficSystemId, self.graphicsComponent.graphicsRootNode)
		end
		self:setCurrentHandTool(nil, true)
		for _, v377_ in ipairs(self.carriedHandTools) do
			v377_:setCarryingPlayerShown()
		end
		if self.isOwner and not skipEnablingMover then
			self.mover:enablePhysics()
		end
	end
end

-- Local values: i, handTool, mission
function Player:hide(skipHidingModel, skipDisablingMover, ignoreLocalCheck)
	if self.isDeleted then
		return
	elseif ignoreLocalCheck or self.isLocallyControlled == nil then
		if self.isServer then
			self.networkComponent:setShowHideParameters(skipHidingModel, skipDisablingMover)
		end
		if self.isControlled and self.isOwner then
			g_messageCenter:publish(MessageType.OWN_PLAYER_LEFT)
			self.inputComponent:stopListeningForBindingChanges()
		end
		if self:getIsHoldingHandTool() then
			self:setCurrentHandTool(nil, true)
		end
		for _, v382_ in ipairs(self.carriedHandTools) do
			v382_:setCarryingPlayerHidden()
		end
		self:setFlashlightIsActive(false, true)
		self.isControlled = false
		local v383_ = g_currentMission
		if self.swsObstacle ~= nil then
			v383_.shallowWaterSimulation:removeObstacle(self.swsObstacle)
			self.swsObstacle = nil
		end
		if v383_.aiSystem ~= nil then
			v383_.aiSystem:removeObstacle(self.rootNode)
		end
		if not skipHidingModel then
			self.graphicsComponent:hide()
		end
		if not skipDisablingMover then
			self.mover:disablePhysics()
			self:teleportTo(0, -200, 0, true, true)
		end
	end
end

-- Local values: isVisible
function Player:onPerspectiveSwitched(isFirstPerson)
	if self.graphicsComponent ~= nil then
		local v386_ = self.isControlled
		if v386_ then
			v386_ = not isFirstPerson
		end
		self.graphicsComponent:setModelVisibility(v386_, true)
	end
	if self:getIsHoldingHandTool() then
		self.currentHandTool:setCarryingPlayerPerspectiveChanged(isFirstPerson)
	end
end

-- Local values: node, x, y, z, sx, sy, sz
function Player:drawDebug(posX, posY, textSize)
	setTextAlignment(RenderText.ALIGN_RIGHT)
	renderText(posX, posY, textSize, "State : ")
	setTextAlignment(RenderText.ALIGN_LEFT)
	renderText(posX, posY, textSize, self.stateMachine:getCurrentStateName())
	local v391_ = posY - textSize - 5 * g_pixelSizeY
	self.graphicsState:drawDebug(posX, v391_, textSize)
	local v392_ = self.rootNode
	if self.graphicsComponent ~= nil then
		v392_ = self.graphicsComponent.graphicsRootNode
	end
	local v393_, v394_, v395_ = localToWorld(v392_, 2, 2, 0)
	local v396_, v397_, v398_ = project(v393_, v394_, v395_)
	DebugUtil.drawDebugNode(v392_, "Root", false, 0)
	if v396_ > -1 and (v396_ < 2 and (v397_ > -1 and (v397_ < 2 and v398_ <= 1))) then
		local _ = self.graphicsComponent == nil
	end
end

-- Local values: flag, possibleValues, flagName, flagValue
function Player:consoleCommandToggleDebugFlag(flagName)
	local v401_
	if flagName == nil then
		v401_ = nil
	else
		v401_ = Player.DEBUG_DISPLAY_FLAG[string.upper(flagName)] or nil
	end
	if string.isNilOrWhitespace(flagName) or v401_ == nil then
		local v402_ = "Flag name must be one of the following: "
		for v403_, _ in pairs(Player.DEBUG_DISPLAY_FLAG) do
			v402_ = v402_ .. v403_ .. ", "
		end
		return v402_
	else
		if v401_ == Player.DEBUG_DISPLAY_FLAG.NONE then
			Player.currentDebugFlag = Player.DEBUG_DISPLAY_FLAG.NONE
		else
			local v404_ = Player
			local v405_ = Player.currentDebugFlag
			v404_.currentDebugFlag = bit32.bxor(v405_, v401_)
		end
		self:handleDebugBindings()
		local v406_ = Player.currentDebugFlag
		if bit32.band(v401_, v406_) == 0 then
			return string.format("Debug flag %q is now disabled", flagName)
		else
			return string.format("Debug flag %q is now enabled", flagName)
		end
	end
end

-- Local values: flag, possibleValues, flagName, flagValue
function Player:consoleCommandToggleVerboseDebugFlag(flagName)
	local v409_
	if flagName == nil then
		v409_ = nil
	else
		v409_ = Player.DEBUG_DISPLAY_FLAG[flagName] or nil
	end
	if string.isNilOrWhitespace(flagName) or v409_ == nil then
		local v410_ = "Flag name must be one of the following: "
		for v411_, _ in pairs(Player.DEBUG_DISPLAY_FLAG) do
			v410_ = v410_ .. v411_ .. ", "
		end
		return v410_
	else
		local v412_ = Player
		local v413_ = Player.currentDebugVerbosityFlag
		v412_.currentDebugVerbosityFlag = bit32.bxor(v413_, v409_)
		self:handleDebugBindings()
		local v414_ = Player.currentDebugVerbosityFlag
		if bit32.band(v409_, v414_) == 0 then
			return string.format("Debug verbosity flag %q is now disabled", flagName)
		else
			return string.format("Debug verbosity flag %q is now enabled", flagName)
		end
	end
end

function Player:consoleCommandToggleStrafeWalkMode()
	self.isStrafeWalkMode = not self.isStrafeWalkMode
	return string.format("StrafeWalkMode: %s", self.isStrafeWalkMode and "Active" or "Inactive")
end

function Player:consoleCommandToggleForceHandToolFirstPerson()
	self.forceHandToolFirstPerson = not self.forceHandToolFirstPerson
	return string.format("ForceHandToolFirstPerson: %s", self.forceHandToolFirstPerson and "Active" or "Inactive")
end

-- Local values: usage, fillTypeIndex, amount, tipTargetObject, notSupported, missingSpace, tipFillType, amountToTip, raycastCallbackTarget, x, y, z, tippedAmount
function Player:consoleCommandTipToTrigger(fillTypeName, amountStr)
	local v420_ = "gsTipToTrigger fillTypeName amount"
	if self.isControlled then
		if fillTypeName == nil then
			Logging.error("No fillType given")
			return v420_
		else
			local v_u_421_ = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
			if v_u_421_ == nil then
				Logging.error("Unknown fillType %q", fillTypeName)
				return v420_
			elseif amountStr == nil then
				Logging.error("No amount given")
				return v420_
			else
				local v422_ = tonumber(amountStr)
				if v422_ == nil then
					Logging.error("Given amount %q is not a number", amountStr)
					return v420_
				else
					local v_u_423_ = nil
					local v_u_424_ = nil
					local v_u_425_ = nil
					local v_u_426_ = v422_
					local v436_ = {
						["callbackFunc"] = function(_, p427_, _, _, _, _, _, _, _, _, p428_)
							-- upvalues: (ref) v_u_424_, (ref) v_u_425_, (copy) self, (ref) v_u_423_, (copy) v_u_421_, (ref) v_u_426_
							local v429_ = g_currentMission.nodeToObject[p427_]
							v_u_424_ = false
							v_u_425_ = false
							if v429_ ~= nil and (v429_ ~= self and v429_.getFillUnitIndexFromNode ~= nil) then
								v_u_423_ = v429_
								local v430_ = v429_:getFillUnitIndexFromNode(p428_)
								if v430_ ~= nil then
									local v431_ = v_u_421_
									if not v429_:getFillUnitSupportsFillType(v430_, v431_) then
										Logging.error("Failed to tip. Target does not support this fillType")
										local v432_
										if v429_.getFillUnitSupportedFillTypes == nil then
											v432_ = v429_.fillTypes
										else
											v432_ = v429_:getFillUnitSupportedFillTypes(v430_)
										end
										if v432_ ~= nil then
											local v433_ = g_fillTypeManager:getFillTypeNamesByIndices(v432_)
											if #v433_ > 0 then
												printf("Supported fillTypes: %s", table.concat(v433_, " "))
											end
										end
										v_u_424_ = true
										return
									end
									local v434_ = v429_:getFillUnitAllowsFillType(v430_, v431_)
									local v435_ = self.farmId
									if v429_:getFillUnitFreeCapacity(v430_, v431_, v435_) <= 0 then
										v_u_425_ = true
										Logging.error("Failed to tip. Target has no more space for this fillType")
										return
									end
									if v434_ then
										v_u_426_ = v_u_426_ - v429_:addFillUnitFillLevel(v435_, v430_, v_u_426_, v431_, ToolType.UNDEFINED, nil)
										if v_u_426_ <= 0 then
											return false
										end
									end
								end
							end
							return true
						end
					}
					local v437_, v438_, v439_ = getWorldTranslation(g_localPlayer.rootNode)
					raycastAll(v437_, v438_ + 5, v439_, 0, -1, 0, 10, "callbackFunc", v436_, CollisionFlag.FILLABLE)
					if v_u_423_ == nil then
						Logging.error("Failed to tip. No target found below current player position")
						return
					elseif not (v_u_424_ or v_u_425_) then
						local v440_ = v422_ - v_u_426_
						if v440_ ~= 0 then
							return "Tipped " .. v440_ .. "l of " .. fillTypeName
						end
						Logging.error("Failed to tip %q. Missing access or no space at target", fillTypeName)
					end
				end
			end
		end
	else
		Logging.error("Not available within a vehicle, needs to be on foot")
		return
	end
end

function Player:handleDebugBindings()
	if self.debugFunctionId == nil and Player.currentDebugFlag ~= Player.DEBUG_DISPLAY_FLAG.NONE then
		self.debugFunctionId = g_debugManager:addElement(DebugFunction.new(nil, function()
			g_currentMission.playerSystem:debugDrawAllPlayers(0.025, 0.95, 0.014)
		end))
	end
	if self.debugFunctionId ~= nil and Player.currentDebugFlag == Player.DEBUG_DISPLAY_FLAG.NONE then
		g_debugManager:removeElementById(self.debugFunctionId)
		self.debugFunctionId = nil
	end
end
function Player.debugLogVerbose(p442_, p443_, p444_, ...)
	if type(p443_) == "number" then
		local v445_ = Player.currentDebugVerbosityFlag
		if bit32.band(p443_, v445_) ~= 0 then
			Player.debugLog(p442_, p443_, p444_, ...)
			return
		end
	end
end
function Player.debugLog(p446_, p447_, p448_, ...)
	if type(p447_) == "number" then
		local v449_ = Player.currentDebugFlag
		if bit32.band(p447_, v449_) ~= 0 then
			local v450_ = nil
			for v451_, v452_ in pairs(Player.DEBUG_DISPLAY_FLAG) do
				if v452_ == p447_ then
					v450_ = v451_
					break
				end
			end
			if v450_ == nil then
				v450_ = string.format("0x%X", p447_)
			end
			if p446_ == nil then
				Logging.info("Player %s: " .. p448_, v450_, ...)
			else
				Logging.info("Player %d %s: " .. p448_, p446_.userId or -1, v450_, ...)
			end
		end
	end
end

-- Local values: flagTextY, flagName, flagValue, functionName, i, handTool
function Player:debugDraw(x, y, textSize)
	if self.isOwner then
		local v457_ = textSize * (table.size(Player.DEBUG_DISPLAY_FLAG) + 1)
		local v458_ = DebugUtil.renderTextLine(0.9, v457_, textSize, "Enabled debug views:", nil, true)
		for v459_, v460_ in pairs(Player.DEBUG_DISPLAY_FLAG) do
			if v460_ ~= 0 then
				local v461_ = Player.currentDebugFlag
				if bit32.band(v460_, v461_) == v460_ then
					v458_ = DebugUtil.renderTextLine(0.9, v458_, textSize, v459_, nil, true)
				end
			end
		end
	end
	if self.userId ~= nil then
		DebugUtil.drawDebugNode(self.rootNode, "Root", false, 0)
		local v462_ = DebugUtil.renderTextLine(x, y, textSize * 2, string.format("Player %d (farm: %d)", self.userId, self.farmId), nil, true, self.isOwner and Color.PRESETS.DARKGREEN or Color.PRESETS.WHITE)
		local v463_ = DebugUtil.renderTextLine
		local v464_ = string.format
		local v465_ = self.isControlled
		local v466_ = tostring(v465_)
		local v467_ = self.isLocallyControlled
		local v468_ = v463_(x, v462_, textSize, v464_("Controlled (server, local): %s, %s", v466_, (tostring(v467_))), nil, true)
		local v469_ = Player.DEBUG_DISPLAY_FLAG.STATE
		local v470_ = Player.currentDebugFlag
		if bit32.band(v469_, v470_) ~= 0 then
			local v471_ = DebugUtil.renderTextLine(x, v468_, textSize * 2, self.stateMachine.states.onFoot:getCurrentStateName(), nil, true)
			local v472_ = DebugUtil.renderTextLine(x, v471_, textSize * 1.5, "State functions", nil, true)
			for v473_ in pairs(self.stateFunctions) do
				v472_ = DebugUtil.renderTextLine(x, v472_, textSize, v473_, nil, true)
			end
			v468_ = DebugUtil.renderNewLine(v472_, textSize)
		end
		if self.stateMachine.currentState == self.stateMachine.states.onFoot then
			local v474_ = Player.DEBUG_DISPLAY_FLAG.MOVEMENT
			local v475_ = Player.currentDebugFlag
			if bit32.band(v474_, v475_) ~= 0 then
				local v476_ = self.mover:debugDraw(x, v468_, textSize)
				local v477_ = self.capsuleController:debugDraw(x, v476_, textSize)
				v468_ = DebugUtil.renderNewLine(v477_, textSize)
			end
			if self.inputComponent ~= nil then
				local v478_ = Player.DEBUG_DISPLAY_FLAG.INPUT
				local v479_ = Player.currentDebugFlag
				if bit32.band(v478_, v479_) ~= 0 then
					v468_ = self.inputComponent:debugDraw(x, v468_, textSize)
				end
			end
			local v480_ = Player.DEBUG_DISPLAY_FLAG.GRAPHICS
			local v481_ = Player.currentDebugFlag
			if bit32.band(v480_, v481_) ~= 0 then
				if self.isOwner then
					self.graphicsComponent:debugDrawAnimator(0.75, 0.5, 0.25, 0.3, 0.01)
					if self.camera ~= nil then
						v468_ = self.camera:debugDraw(x, v468_, textSize)
					end
				end
				local v482_ = self.graphicsComponent:debugDraw(x, v468_, textSize, self.camera == nil and true or not self.camera.isFirstPerson)
				v468_ = DebugUtil.renderNewLine(v482_, textSize)
			end
			local v483_ = Player.DEBUG_DISPLAY_FLAG.HANDTOOLS
			local v484_ = Player.currentDebugFlag
			if bit32.band(v483_, v484_) ~= 0 then
				if self.targeter ~= nil then
					local v485_ = self.targeter:debugDraw(x, v468_, textSize)
					v468_ = DebugUtil.renderNewLine(v485_, textSize)
				end
				local v486_ = DebugUtil.renderTextLine(x, v468_, textSize * 1.5, "Tools", nil, true)
				for v487_, v488_ in ipairs(self.carriedHandTools) do
					if v488_ == self.currentHandTool then
						v486_ = DebugUtil.renderTextLine(x, v486_, textSize, string.format("%d: %s", v487_, v488_.typeName), nil, true)
					else
						v486_ = DebugUtil.renderTextLine(x, v486_, textSize, string.format("%d: %s", v487_, v488_.typeName))
					end
				end
				if self:getIsHoldingHandTool() then
					v486_ = self.currentHandTool:debugDraw(x, v486_, textSize)
				end
				v468_ = DebugUtil.renderNewLine(v486_, textSize)
			end
			if self.networkComponent ~= nil then
				local v489_ = Player.DEBUG_DISPLAY_FLAG.NETWORK
				local v490_ = Player.currentDebugFlag
				if bit32.band(v489_, v490_) ~= 0 then
					local v491_ = self.networkComponent:debugDraw(x, v468_, textSize)
					v468_ = DebugUtil.renderNewLine(v491_, textSize)
				end
			end
			return v468_
		end
	end
end
