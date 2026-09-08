-- Local values: BaseMission_mt
source("dataS/scripts/events/VehicleRemoveEvent.lua")
source("dataS/scripts/events/OnCreateLoadedObjectEvent.lua")
BaseMission = {}
local BaseMission_mt = Class(BaseMission)
BaseMission.STATE_INTRO = 0
BaseMission.STATE_READY = 1
BaseMission.STATE_RUNNING = 2
BaseMission.STATE_FINISHED = 3
BaseMission.STATE_FAILED = 5
BaseMission.STATE_CONTINUED = 6
BaseMission.INPUT_CONTEXT_VEHICLE = "VEHICLE"
BaseMission.INPUT_CONTEXT_PAUSE = "PAUSE"
BaseMission.INPUT_CONTEXT_SYNCHRONIZING = "MP_SYNC"

-- Upvalues: BaseMission_mt
-- Local values: self
function BaseMission.new(baseDirectory, customMt)
	-- upvalues: (copy) BaseMission_mt
	local v4_ = customMt or BaseMission_mt
	local v5_ = setmetatable({}, v4_)
	v5_.baseDirectory = baseDirectory
	v5_.server = g_server
	v5_.client = g_client
	v5_.hud = nil
	v5_.playerSystem = PlayerSystem.new()
	v5_.placeableSystem = PlaceableSystem.new(v5_)
	v5_.vehicleSystem = VehicleSystem.new(v5_)
	v5_.itemSystem = ItemSystem.new(v5_)
	v5_.handToolSystem = HandToolSystem.new()
	v5_.onCreateObjectSystem = OnCreateObjectSystem.new(v5_)
	v5_.beehiveSystem = BeehiveSystem.new(v5_)
	if Platform.hasShallowWaterSimulation then
		v5_.shallowWaterSimulation = ShallowWaterSimulation.new()
		v5_.shallowWaterSimulation:load()
	end
	v5_.cancelLoading = false
	v5_.vertexBufferMemoryUsage = 0
	v5_.indexBufferMemoryUsage = 0
	v5_.textureMemoryUsage = 0
	v5_.waitForDLCVerification = false
	v5_.waitForCorruptDlcs = false
	v5_.finishedFirstUpdate = false
	v5_.players = {}
	v5_.connectionsToPlayer = {}
	v5_.updateables = {}
	v5_.sortedUpdateables = {}
	v5_.nonUpdateables = {}
	v5_.drawables = {}
	v5_.triggerMarkers = {}
	v5_.triggerMarkersAreVisible = true
	v5_.helpTriggers = {}
	v5_.helpTriggersAreVisible = true
	v5_.dynamicallyLoadedObjects = {}
	v5_.isPlayerFrozen = false
	v5_.environment = nil
	v5_.state = BaseMission.STATE_INTRO
	v5_.isRunning = false
	v5_.isLoaded = false
	v5_.numLoadingTasks = 0
	v5_.isMissionStarted = false
	v5_.isToggleVehicleAllowed = true
	v5_.ownedItems = {}
	v5_.leasedItems = {}
	v5_.loadSpawnPlaces = {}
	v5_.storeSpawnPlaces = {}
	v5_.restrictedZones = {}
	v5_.usedLoadPlaces = {}
	v5_.usedStorePlaces = {}
	v5_.nodeToObject = {}
	v5_.maps = {}
	v5_.surfaceSounds = {}
	v5_.cuttingSounds = {}
	v5_.preSimulateTime = 4000
	v5_.maxNumHirables = Platform.gameplay.maxNumHirables
	v5_.time = 0
	v5_.activatableObjectsSystem = ActivatableObjectsSystem.new(v5_)
	v5_.pauseListeners = {}
	v5_.paused = false
	v5_.pressStartPaused = false
	v5_.manualPaused = false
	v5_.suspendPaused = false
	v5_.lastNonPauseGameState = GameState.PLAY
	v5_.isLoadingMap = false
	v5_.numLoadingMaps = 0
	v5_.loadingMapBaseDirectory = ""
	v5_.objectsToClassName = {}
	v5_.lastInteractionTime = -1
	v5_.isExitingGame = false
	return v5_
end

function BaseMission:initialize()
	self:subscribeSettingsChangeMessages()
	self:subscribeGuiOpenCloseMessages()
	g_messageCenter:subscribe(MessageType.GAME_STATE_CHANGED, self.onGameStateChange, self)
	self.hud = self:createHUD()
	self.placementManager = PlacementManager.new()
end

-- Local values: hud
function BaseMission:createHUD()
	if Platform.isMobile then
		return MobileHUD.new(g_server ~= nil, g_client ~= nil, GS_IS_CONSOLE_VERSION, g_messageCenter, g_i18n, g_inputBinding, g_inputDisplayManager, g_modManager, g_fillTypeManager, g_fruitTypeManager, g_gui.guiSoundPlayer, self, g_farmManager, g_farmlandManager)
	else
		return HUD.new()
	end
end

-- Local values: k, v, _, object, k, updateable, _, listener, _, v, _, surfaceSound, _, cuttingSound
function BaseMission:delete()
	g_messageCenter:unsubscribeAll(self)
	PlatformNodeRemover.reset()
	self.isExitingGame = true
	self.isRunning = false
	g_cameraManager:setDefaultCamera()
	self:setMapTargetHotspot(nil)
	if self:getIsClient() and (g_localPlayer ~= nil and g_localPlayer:getIsInVehicle()) then
		g_localPlayer:leaveVehicle(nil, true)
	end
	for v9_, v10_ in pairs(self.nonUpdateables) do
		v10_:delete()
		self.nonUpdateables[v9_] = nil
	end
	if g_server ~= nil then
		g_server:delete()
		g_server = nil
	end
	if g_client ~= nil then
		g_client:delete()
		g_client = nil
	end
	if self.placementManager ~= nil then
		self.placementManager:delete()
	end
	if g_localPlayer ~= nil then
		g_localPlayer:delete()
	end
	if self.trafficSystem ~= nil then
		self.trafficSystem:setEnabled(false)
		self.trafficSystem:reset()
	end
	if self.pedestrianSystem ~= nil then
		self.pedestrianSystem:delete()
		self.pedestrianSystem = nil
	end
	if self.shallowWaterSimulation ~= nil then
		self.shallowWaterSimulation:delete()
		self.shallowWaterSimulation = nil
	end
	g_terrainDeformationQueue:cancelAllJobs()
	self.leasedItems = {}
	self.ownedItems = {}
	self.placeableSystem:delete()
	self.vehicleSystem:delete()
	self.itemSystem:delete()
	self.onCreateObjectSystem:delete()
	self.handToolSystem:delete()
	self.beehiveSystem:delete()
	for _, v11_ in pairs(self.dynamicallyLoadedObjects) do
		delete(v11_)
	end
	if self.environment ~= nil then
		g_inGameMenu:setEnvironment(nil)
		self.environment:delete()
		self.environment = nil
	end
	for v12_, v13_ in pairs(self.updateables) do
		if v13_.delete ~= nil then
			v13_:delete()
		end
		table.removeElement(self.sortedUpdateables, v13_)
		self.updateables[v12_] = nil
	end
	for _, v14_ in ipairs_reverse(g_modEventListeners) do
		if v14_.deleteMap ~= nil then
			v14_:deleteMap()
		end
	end
	if self.hud ~= nil then
		g_messageCenter:unsubscribeAll(self.hud)
		self.hud:delete()
		self.hud = nil
	end
	g_terrainNode = nil
	g_terrainSize = nil
	g_terrainSizeHalf = nil
	for _, v15_ in pairs(self.maps) do
		delete(v15_)
	end
	for _, v16_ in pairs(self.surfaceSounds) do
		g_soundManager:deleteSample(v16_.sample)
	end
	self.surfaceSounds = {}
	for _, v17_ in pairs(self.cuttingSounds) do
		g_soundManager:deleteSample(v17_)
	end
	self.cuttingSounds = {}
	removeConsoleCommand("gsRender360Screenshot")
	removeConsoleCommand("gsShaderParamsSet")
	g_inputBinding:clearAllContexts()
	g_gui:setCurrentMission(nil)
	g_gui:setClient(nil)
end

function BaseMission:load()
	self:startLoadingTask()
	if self:getIsServer() and g_addTestCommands then
		addConsoleCommand("gsRender360Screenshot", "Renders 360 screenshots from current camera position", "consoleCommandRender360Screenshot", self)
		addConsoleCommand("gsShaderParamsSet", "Sets shader parameters for given nodeName and shader parameter name", "consoleCommandSetShaderParameter", self, "nodeName; shaderParameterName; x; y; z; w; shared")
	end
	self:finishLoadingTask()
end

function BaseMission:startLoadingTask()
	self.numLoadingTasks = self.numLoadingTasks + 1
	if self.numLoadingTasks == 1 then
		setStreamLowPriorityI3DFiles(false)
		if self.missionDynamicInfo.isMultiplayer then
			netSetIsEventProcessingEnabled(false)
		end
	end
end

function BaseMission:finishLoadingTask()
	self.numLoadingTasks = self.numLoadingTasks - 1
	if self.numLoadingTasks <= 0 then
		if not self.isLoaded then
			self:onFinishedLoading()
		end
		setStreamLowPriorityI3DFiles(true)
		if self.missionDynamicInfo.isMultiplayer then
			netSetIsEventProcessingEnabled(true)
		end
	end
end

function BaseMission:onFinishedLoading()
	self.isLoaded = true
	g_gui:setCurrentMission(self)
	g_gui:setClient(g_client)
end

function BaseMission:canStartMission()
	if self.vehicleSystem:canStartMission() then
		if self.placeableSystem:canStartMission() then
			if self.handToolSystem:canStartMission() then
				return self:getIsServer() and true or g_localPlayer ~= nil
			else
				return false
			end
		else
			return false
		end
	else
		return false
	end
end

function BaseMission:onStartMission()
	Logging.info("Entered Gameplay")
	setTextureStreamingPaused(false)
	self:fadeScreen(-1, 1500, nil)
	self.isMissionStarted = true
	self:setShowTriggerMarker(g_gameSettings:getValue(GameSettings.SETTING.SHOW_TRIGGER_MARKER))
	self:setShowHelpTrigger(g_gameSettings:getValue(GameSettings.SETTING.SHOW_HELP_TRIGGER))
	if Profiler.IS_INITIALIZED then
		g_guidedTourManager:abortTour()
	end
end

function BaseMission:onObjectCreated(object)
	if object:isa(Player) then
		self.players[object.rootNode] = object
		if object.isOwner then
			g_inGameMenu:setPlayer(object)
			self.hud:setPlayer(object)
		end
		if self:getIsServer() then
			self.connectionsToPlayer[object.connection] = object
		end
		g_messageCenter:publish(MessageType.PLAYER_CREATED, object)
	elseif object:isa(Farm) then
		g_farmManager:onFarmObjectCreated(object)
	end
end

function BaseMission:onObjectDeleted(object)
	if object:isa(Player) then
		if g_localPlayer == object then
			g_localPlayer = nil
		end
		self.players[object.rootNode] = nil
		if self:getIsServer() then
			self.connectionsToPlayer[object.connection] = nil
			return
		end
	elseif object:isa(Farm) then
		g_farmManager:onFarmObjectDeleted(object)
	end
end

-- Local values: modMapName, baseDirectory, modName, loaded, args
function BaseMission:loadMap(filename, addPhysics, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	local v34_ = addPhysics == nil and true or addPhysics
	local v35_, v36_ = Utils.getModNameAndBaseDirectory(filename)
	if self.numLoadingMaps == 0 then
		self.loadingMapModName = v35_
		self.loadingMapBaseDirectory = v36_
		self.loadedMapBaseDirectory = v36_
		resetModOnCreateFunctions()
		for v37_, v38_ in pairs(g_modIsLoaded) do
			if v38_ and not g_modManager:isModMap(v37_) then
				_G[v37_].g_onCreateUtil.activateOnCreateFunctions()
			end
		end
		if v35_ ~= nil then
			_G[v35_].g_onCreateUtil.activateOnCreateFunctions()
		end
		self.isLoadingMap = true
	elseif self.loadingMapBaseDirectory ~= v36_ then
		printWarning("Warning: Asynchronous map loading from different mods. onCreate functions will not work correctly")
	end
	self.numLoadingMaps = self.numLoadingMaps + 1
	if asyncCallbackFunction == nil then
		Logging.error("Loading the map in sync is not allowed anymore! Please call loadMap with a async callback.")
		printCallstack()
	else
		g_i3DManager:loadI3DFileAsync(filename, true, v34_, self.loadMapFinished, self, {
			["filename"] = filename,
			["asyncCallbackFunction"] = asyncCallbackFunction,
			["asyncCallbackObject"] = asyncCallbackObject,
			["asyncCallbackArguments"] = asyncCallbackArguments
		})
	end
end

-- Local values: filename, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments, _, v
function BaseMission:loadMapFinished(node, failedReason, arguments, callAsyncCallback)
	g_mpLoadingScreen:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.MAP)
	local v43_ = arguments.filename
	local v44_ = arguments.asyncCallbackFunction
	local v45_ = arguments.asyncCallbackObject
	local v46_ = arguments.asyncCallbackArguments
	if node ~= 0 then
		self:findDynamicObjects(node)
		PlatformNodeRemover.removeNodes()
	end
	if Profiler.IS_INITIALIZED then
		Profiler.setMapRootNode(node)
	end
	self.numLoadingMaps = self.numLoadingMaps - 1
	if self.numLoadingMaps == 0 then
		self.isLoadingMap = false
		resetModOnCreateFunctions()
		self.loadingMapModName = nil
		self.loadingMapBaseDirectory = ""
	end
	if node ~= 0 and not self.cancelLoading then
		local v47_ = self.maps
		table.insert(v47_, node)
		link(getRootNode(), node)
	end
	for _, v48_ in pairs(g_modEventListeners) do
		if v48_.loadMap ~= nil then
			v48_:loadMap(v43_)
		end
	end
	if not self.cancelLoading then
		self:setShowFieldInfo(g_gameSettings:getValue(GameSettings.SETTING.SHOW_FIELD_INFO))
	end
	if (callAsyncCallback == nil or callAsyncCallback) and v44_ ~= nil then
		v44_(v45_, node, v46_)
	end
end

-- Local values: filename, envXmlFile
function BaseMission:loadEnvironment(xmlFile)
	local v51_ = Utils.getFilename(getXMLString(xmlFile, "map.environment#filename"), self.baseDirectory)
	self.environment = Environment.new(self)
	self.environment:load(v51_)
	if self.missionInfo.environmentXMLLoad ~= nil and self:getIsServer() then
		local v52_ = loadXMLFile("environmentXML", self.missionInfo.environmentXMLLoad)
		self.environment:loadFromXMLFile(v52_, "environment")
		delete(v52_)
	end
	g_inGameMenu:setEnvironment(self.environment)
end

-- Local values: i, c, mpCreatePhysicsObject, mpRemoveRigidBody, object
function BaseMission:findDynamicObjects(node)
	for v55_ = 1, getNumOfChildren(node) do
		local v56_ = getChildAt(node, v55_ - 1)
		if RigidBodyType.DYNAMIC == getRigidBodyType(v56_) then
			if (not getHasClassId(v56_, ClassIds.SHAPE) or getSplitType(v56_) == 0) and self.missionDynamicInfo.isMultiplayer then
				local v57_ = Utils.getNoNil(getUserAttribute(v56_, "mpCreatePhysicsObject"), false)
				local v58_ = Utils.getNoNil(getUserAttribute(v56_, "mpRemoveRigidBody"), true)
				if v57_ then
					local v59_ = PhysicsObject.new(self:getIsServer(), self:getIsClient())
					self.onCreateObjectSystem:add(v59_)
					v59_:loadOnCreate(v56_)
					v59_:register(true)
				elseif v58_ then
					setRigidBodyType(v56_, RigidBodyType.NONE)
				end
			end
		else
			self:findDynamicObjects(v56_)
		end
	end
end

-- Local values: xmlFile, i, key, entry, audioGroup, loopCount, j, key, name, sample
function BaseMission:loadMapSounds(xmlFilename, baseDirectory)
	if self:getIsClient() then
		local v63_ = loadXMLFile("mapSoundXML", xmlFilename)
		if v63_ ~= 0 then
			self.surfaceSounds = {}
			local v64_ = 0
			while true do
				local v65_ = string.format("sound.surface.material(%d)", v64_)
				if not hasXMLProperty(v63_, v65_) then
					break
				end
				local v66_ = {}
				local v67_ = AudioGroup.ENVIRONMENT
				v66_.type = Utils.getNoNil(getXMLString(v63_, v65_ .. "#type"), "wheel")
				if string.startsWith(v66_.type, "wheel") then
					v67_ = AudioGroup.VEHICLE
				end
				v66_.materialId = getXMLInt(v63_, v65_ .. "#materialId")
				v66_.name = getXMLString(v63_, v65_ .. "#name")
				local v68_ = getXMLInt(v63_, v65_ .. "#loopCount") or 0
				v66_.sample = g_soundManager:loadSampleFromXML(v63_, "sound.surface", string.format("material(%d)", v64_), baseDirectory, getRootNode(), v68_, v67_, nil, nil)
				if v66_.sample ~= nil then
					local v69_ = self.surfaceSounds
					table.insert(v69_, v66_)
				end
				v64_ = v64_ + 1
			end
			self.cuttingSounds = {}
			local v70_ = 0
			while true do
				local v71_ = string.format("sound.cutting.sample(%d)", v70_)
				if not hasXMLProperty(v63_, v71_) then
					break
				end
				local v72_ = getXMLString(v63_, v71_ .. "#name")
				local v73_ = g_soundManager:loadSampleFromXML(v63_, "sound.cutting", string.format("sample(%d)", v70_), baseDirectory, getRootNode(), 1, AudioGroup.ENVIRONMENT, nil, nil)
				if v72_ == nil then
					printWarning("Warning: a cutting sound does not have a name")
				else
					self.cuttingSounds[v72_] = v73_
				end
				v70_ = v70_ + 1
			end
			delete(v63_)
		end
	else
		return
	end
end

-- Local values: size, isLimitReached, x, y, z, place, width, _, object, yRot, xmlFile, className, filename, class
function BaseMission:loadObjectAtPlace(xmlFilename, places, usedPlaces, rotationOffset, ownerFarmId)
	local v80_ = StoreItemUtil.getSizeValues(xmlFilename, "object", rotationOffset)
	local v81_, v82_, v83_, v84_, v85_, _ = PlacementUtil.getPlace(places, v80_, usedPlaces, true, true, false, true)
	if v81_ == nil then
		return nil, true, false
	end
	local v86_ = nil
	local v87_ = MathUtil.getYRotationFromDirection(v84_.dirPerpX, v84_.dirPerpZ) + rotationOffset
	local v88_ = loadXMLFile("tempObjectXML", xmlFilename)
	local v89_ = Utils.getNoNil(getXMLString(v88_, "object.className"), "")
	local v90_ = getXMLString(v88_, "object.filename")
	local v91_ = ClassUtil.getClassObject(v89_)
	if v91_ == nil then
		printWarning("Warning: Class \'" .. tostring(v89_) .. "\' not found!")
	elseif v90_ == nil then
		printWarning("Warning: File \'" .. tostring(v90_) .. "\' not found!")
	else
		v86_ = v91_.new(self:getIsServer(), self:getIsClient())
		v86_:setOwnerFarmId(ownerFarmId, true)
		if v86_:load(Utils.getFilename(v90_, self.baseDirectory), v81_, v82_, v83_, 0, v87_, 0, xmlFilename) then
			v86_:register()
			v86_:setFillLevel(v86_.capacity, false)
		else
			v86_:delete()
			v86_ = nil
		end
	end
	delete(v88_)
	if v86_ == nil then
		return nil, false, false
	end
	PlacementUtil.markPlaceUsed(usedPlaces, v84_, v85_)
	return v86_, false, false
end

function BaseMission:addOwnedItem(item)
	BaseMission.addItemToList(self.ownedItems, item)
end

function BaseMission:removeOwnedItem(item)
	BaseMission.removeItemFromList(self.ownedItems, item)
end

function BaseMission:getNumOwnedItems(storeItem, farmId)
	return BaseMission.getNumListItems(self.ownedItems, storeItem, farmId)
end

function BaseMission:addLeasedItem(item)
	BaseMission.addItemToList(self.leasedItems, item)
end

function BaseMission:removeLeasedItem(item)
	BaseMission.removeItemFromList(self.leasedItems, item)
end

function BaseMission:getNumLeasedItems(storeItem, farmId)
	return BaseMission.getNumListItems(self.leasedItems, storeItem, farmId)
end

-- Local values: numItems, _, item, maxNumOfItems, _, bundleItem
function BaseMission.getNumListItems(list, storeItem, farmId)
	local v109_ = 0
	if storeItem.bundleInfo == nil then
		if list[storeItem] ~= nil then
			if farmId == nil then
				return list[storeItem].numItems
			end
			local v110_ = 0
			for _, v111_ in pairs(list[storeItem].items) do
				if v111_:getOwnerFarmId() == farmId then
					v110_ = v110_ + 1
				end
			end
			return v110_
		end
	else
		v109_ = math.huge
		for _, v112_ in pairs(storeItem.bundleInfo.bundleItems) do
			local v113_ = BaseMission.getNumListItems
			local v114_ = v112_.item
			v109_ = math.min(v109_, v113_(list, v114_, farmId))
		end
	end
	return v109_
end

-- Local values: storeItem
function BaseMission.addItemToList(list, item)
	if list ~= nil and item ~= nil then
		local v117_ = g_storeManager:getItemByXMLFilename(item.configFileName)
		if v117_ ~= nil then
			if list[v117_] == nil then
				list[v117_] = {
					["storeItem"] = v117_,
					["numItems"] = 0,
					["items"] = {}
				}
			end
			if list[v117_].items[item] == nil then
				list[v117_].numItems = list[v117_].numItems + 1
				list[v117_].items[item] = item
			end
		end
	end
end

-- Local values: storeItem
function BaseMission.removeItemFromList(list, item)
	if list ~= nil and item ~= nil then
		local v120_ = g_storeManager:getItemByXMLFilename(item.configFileName)
		if v120_ ~= nil and (list[v120_] ~= nil and list[v120_].items[item] ~= nil) then
			list[v120_].numItems = list[v120_].numItems - 1
			list[v120_].items[item] = nil
			if list[v120_].numItems == 0 then
				list[v120_] = nil
			end
		end
	end
end

-- Local values: oldUpdateable
function BaseMission:addUpdateable(updateable, key)
	local v124_ = updateable.isa == nil and true or not updateable:isa(Object)
	assert(v124_, "No network objects allowed in addUpdateable")
	if updateable.update == nil then
		Logging.error("Given updateable has no update function")
		printCallstack()
	else
		local v125_ = self.updateables[key or updateable]
		if v125_ ~= nil then
			table.removeElement(self.sortedUpdateables, v125_)
		end
		self.updateables[key or updateable] = updateable
		table.addElement(self.sortedUpdateables, updateable)
	end
end

function BaseMission:removeUpdateable(updateableOrKey)
	if self.updateables[updateableOrKey] ~= nil then
		table.removeElement(self.sortedUpdateables, self.updateables[updateableOrKey])
	end
	self.updateables[updateableOrKey] = nil
end

function BaseMission:getHasUpdateable(updateable)
	return self.updateables[updateable] ~= nil
end

function BaseMission:getHasDrawable(drawable)
	return self.drawables[drawable] ~= nil
end

function BaseMission:addDrawable(drawable, key)
	self.drawables[key or drawable] = drawable
end

function BaseMission:removeDrawable(drawable)
	self.drawables[drawable] = nil
end

function BaseMission:addNonUpdateable(nonUpdateable)
	local v139_ = nonUpdateable.isa == nil and true or not nonUpdateable:isa(Object)
	assert(v139_, "No network objects allowed in addNonUpdateable")
	self.nonUpdateables[nonUpdateable] = nonUpdateable
end

function BaseMission:removeNonUpdateable(nonUpdateable)
	self.nonUpdateables[nonUpdateable] = nil
end

function BaseMission:addNodeObject(node, object)
	if self.nodeToObject[node] == nil then
		self.nodeToObject[node] = object
	else
		Logging.error("Node \'%s\' already has a node-object mapping \'%s\'", getName(node), (tostring(object)))
		printCallstack()
	end
end

function BaseMission:removeNodeObject(node)
	self.nodeToObject[node] = nil
end

function BaseMission:getNodeObject(node)
	return self.nodeToObject[node]
end

function BaseMission:pauseGame()
	if not self.paused then
		self:doPauseGame()
		if self:getIsServer() then
			GamePauseEvent.sendEvent()
		end
	end
end

function BaseMission:tryUnpauseGame()
	if not self:canUnpauseGame() then
		return false
	end
	self:doUnpauseGame()
	if self:getIsServer() then
		GamePauseEvent.sendEvent()
	end
	return true
end

function BaseMission:canUnpauseGame()
	local v152_ = self.paused and not (self.manualPaused or self.suspendPaused)
	if v152_ then
		v152_ = not self.pressStartPaused
	end
	return v152_
end

function BaseMission:setManualPause(doPause)
	if (self:getIsServer() or self.isMasterUser) and doPause ~= self.manualPaused then
		self.manualPaused = doPause
		if self:getIsServer() then
			if doPause then
				self:pauseGame()
			else
				self:tryUnpauseGame()
			end
		end
		g_client:getServerConnection():sendEvent(GamePauseRequestEvent.new(doPause))
	end
end

-- Local values: target, callbackFunc
function BaseMission:doPauseGame()
	self.paused = true
	self.isRunning = false
	simulatePhysics(false)
	simulateParticleSystems(false)
	self:resetGameState()
	if self.hud ~= nil and not g_gameSettings:getValue(GameSettings.SETTING.SHOW_HELP_MENU) then
		self.hud:setInputHelpVisible(true)
	end
	for v156_, v157_ in pairs(self.pauseListeners) do
		v157_(v156_, self.paused)
	end
	g_messageCenter:publish(MessageType.PAUSE, true)
	if self.trafficSystem ~= nil then
		self.trafficSystem:setEnabled(false)
	end
	if self.pedestrianSystem ~= nil then
		self.pedestrianSystem:setEnabled(false)
	end
end

-- Local values: lastNonPauseGameState, target, callbackFunc
function BaseMission:doUnpauseGame()
	self.paused = false
	self.isRunning = true
	simulatePhysics(true)
	simulateParticleSystems(true)
	if self.hud ~= nil and not g_gameSettings:getValue(GameSettings.SETTING.SHOW_HELP_MENU) then
		self.hud:setInputHelpVisible(g_gameSettings:getValue(GameSettings.SETTING.SHOW_HELP_MENU))
	end
	local v159_ = self.lastNonPauseGameState
	if v159_ == GameState.MENU_INGAME and g_gui.currentGuiName ~= "InGameMenu" then
		v159_ = GameState.PLAY
	end
	g_gameStateManager:setGameState(v159_)
	for v160_, v161_ in pairs(self.pauseListeners) do
		v161_(v160_, self.paused)
	end
	g_messageCenter:publish(MessageType.PAUSE, false)
	if self.trafficSystem ~= nil then
		self.trafficSystem:setEnabled(self.missionInfo.trafficEnabled)
	end
	if self.pedestrianSystem ~= nil then
		self.pedestrianSystem:setEnabled(true)
	end
end

function BaseMission:addPauseListeners(target, callbackFunc)
	self.pauseListeners[target] = callbackFunc
end

function BaseMission:removePauseListeners(target)
	self.pauseListeners[target] = nil
end

function BaseMission:resetGameState()
	if self.pressStartPaused then
		g_gameStateManager:setGameState(GameState.LOADING)
		return
	elseif self.paused then
		g_gameStateManager:setGameState(GameState.PAUSED)
	else
		g_gameStateManager:setGameState(GameState.PLAY)
	end
end

-- Local values: vehicle
function BaseMission:toggleVehicle(delta)
	if self.isToggleVehicleAllowed then
		local v170_ = self.vehicleSystem:getNextEnterableVehicle(g_localPlayer:getCurrentVehicle(), delta)
		if v170_ ~= nil then
			g_localPlayer:requestToEnterVehicle(v170_)
		end
	end
end

function BaseMission:getIsClient()
	return g_client ~= nil
end

function BaseMission:getIsServer()
	return g_server ~= nil
end

-- Local values: _, v
function BaseMission:mouseEvent(posX, posY, isDown, isUp, button)
	for _, v176_ in pairs(g_modEventListeners) do
		if v176_.mouseEvent ~= nil then
			v176_:mouseEvent(posX, posY, isDown, isUp, button)
		end
	end
end

-- Local values: _, v
function BaseMission:keyEvent(unicode, sym, modifier, isDown)
	for _, v181_ in pairs(g_modEventListeners) do
		if v181_.keyEvent ~= nil then
			v181_:keyEvent(unicode, sym, modifier, isDown)
		end
	end
end

-- Local values: infoDialog, infoDialog
function BaseMission:preUpdate(dt)
	if not self.waitForCorruptDlcs then
		if self.waitForDLCVerification and (verifyDlcs() and (g_gui:getIsGuiVisible() and g_gui.currentGuiName == "InfoDialog")) then
			g_gui:showGui("")
			self.waitForDLCVerification = false
		end
		if storeAreDlcsCorrupted() then
			self.waitForCorruptDlcs = true
			local v183_ = g_gui:showGui("InfoDialog")
			v183_.target:setText(g_i18n:getText("dialog_dlcsCorruptQuit"))
			v183_.target:setButtonText(g_i18n:getText("button_quit"))
			v183_.target:setCallbacks(self.dlcProblemOnQuitOk, self, true)
			return
		end
		if not self.waitForDLCVerification and storeHaveDlcsChanged() then
			g_forceNeedsDlcsAndModsReload = true
			if not verifyDlcs() then
				self.waitForDLCVerification = true
				local v184_ = g_gui:showGui("InfoDialog")
				v184_.target:setText(g_i18n:getText("dialog_reinsertDlcMedia"))
				v184_.target:setButtonText(g_i18n:getText("button_quit"))
				v184_.target:setCallbacks(self.dlcProblemOnQuitOk, self, true)
				return
			end
			if checkForNewDlcs() then
				self.hud:showInGameMessage(g_i18n:getText("message_newDlcsRestartTitle"), g_i18n:getText("message_newDlcsRestartText"), -1)
			end
		end
	end
end

function BaseMission:dlcProblemOnQuitOk()
	OnInGameMenuMenu()
end

-- Local values: k, k, x, _, z, hotspotX, hotspotZ, distance, i, updateable, _, v
function BaseMission:update(dt)
	if self.waitForDLCVerification or self.waitForCorruptDlcs then
		return
	else
		if self:getIsServer() then
			g_server:update(dt, self.isRunning)
		end
		if self:getIsClient() then
			g_client:update(dt, self.isRunning)
		end
		if self.gameStarted and g_appIsSuspended ~= self.suspendPaused then
			self.suspendPaused = g_appIsSuspended
			if g_appIsSuspended then
				self:pauseGame()
			else
				self:tryUnpauseGame()
			end
		end
		self.activatableObjectsSystem:update(dt)
		g_achievementManager:update(dt)
		self.hud:update(dt)
		if self.isRunning then
			for v187_ in pairs(self.usedStorePlaces) do
				self.usedStorePlaces[v187_] = nil
			end
			for v188_ in pairs(self.usedLoadPlaces) do
				self.usedLoadPlaces[v188_] = nil
			end
			self.time = self.time + dt
			if self:getIsClient() then
				if not g_gui:getIsGuiVisible() then
					self.hud:updateBlinkingWarning(dt)
					if self.currentMapTargetHotspot ~= nil then
						local v189_, _, v190_ = getWorldTranslation(g_cameraManager:getActiveCamera())
						local v191_, v192_ = self.currentMapTargetHotspot:getWorldPosition()
						if MathUtil.vector2Length(v189_ - v191_, v190_ - v192_) < 10 then
							self:setMapTargetHotspot(nil)
						end
					end
				end
				self.interactiveVehicleInRange = self:getInteractiveVehicleInRange()
			end
			if self.environment ~= nil then
				self.environment:update(dt)
			end
			for v193_ = #self.sortedUpdateables, 1, -1 do
				local v194_ = self.sortedUpdateables[v193_]
				if v194_ ~= nil then
					v194_:update(dt)
				end
			end
			self.vehicleSystem:update(dt)
			for _, v195_ in pairs(g_modEventListeners) do
				if v195_.update ~= nil then
					v195_:update(dt)
				end
			end
			g_terrainDeformationQueue:update(dt)
			g_sleepManager:update(dt)
			g_baleManager:update(dt)
			g_fieldCourseManager:update(dt)
			self.beehiveSystem:update(dt)
			self.finishedFirstUpdate = true
			if g_touchHandler ~= nil then
				g_touchHandler:update(dt)
			end
			if g_inAppPurchaseController ~= nil and g_inAppPurchaseController:getIsAvailable() then
				g_inAppPurchaseController:update(dt)
			end
			self.vehicleSystem:deleteMarkedVehicles()
			self.placeableSystem:deleteMarkedPlaceables()
			self.handToolSystem:deleteMarkedHandTools()
			if self.shallowWaterSimulation ~= nil then
				self.shallowWaterSimulation:update(dt)
			end
		end
	end
end

function BaseMission:postUpdate(dt) end

-- Local values: isNotFading, drawHud, isUIHidden, _, v, _, v
function BaseMission:draw()
	local v197_ = not self.hud:getIsFading()
	g_sleepManager:draw()
	local v198_ = not g_gui:getIsMenuVisible()
	if v198_ and (g_gui:getIsDialogVisible() and not Platform.ui.drawHudOnDialog) then
		v198_ = false
	end
	if self:getIsClient() and (self.isRunning and (v198_ and v197_)) then
		self.hud:drawControlledEntityHUD()
		self.vehicleSystem:draw()
		self.playerSystem:draw()
		g_soundManager:draw()
	end
	if not g_gui:getIsGuiVisible() and v197_ then
		new2DLayer()
		if self.isRunning or self.paused then
			self.hud:drawInputHelp()
		end
		if self.isRunning then
			for _, v199_ in pairs(g_modEventListeners) do
				if v199_.draw ~= nil then
					v199_:draw()
				end
			end
			for _, v200_ in pairs(self.drawables) do
				v200_:draw()
			end
			self.hud:drawTopNotification()
			self.hud:drawBlinkingWarning()
		end
	end
	if self.paused and not (self.isMissionStarted or g_gui:getIsGuiVisible()) then
		self.hud:drawGamePaused(true)
	end
	self.hud:drawFading()
	if g_touchHandler ~= nil then
		g_touchHandler:draw()
	end
end

function BaseMission:setTrafficSystem(trafficSystem)
	if trafficSystem == nil or self.trafficSystem == nil then
		self.trafficSystem = trafficSystem
		return true
	else
		Logging.error("BaseMission: Traffic system already set")
		return false
	end
end

function BaseMission:getTrafficSystem()
	return self.trafficSystem
end

function BaseMission:setPedestrianSystem(pedestrianSystem)
	if pedestrianSystem == nil or self.pedestrianSystem == nil then
		self.pedestrianSystem = pedestrianSystem
		return true
	else
		Logging.error("BaseMission: Pedestrian system already set")
		return false
	end
end

function BaseMission:getPedestrianSystem()
	return self.pedestrianSystem
end

function BaseMission:getTrailerInTipRange(vehicle, minDistance)
	Logging.warning("BaseMission.getTrailerInTipRange() is deprecated")
	return false
end

function BaseMission:getIsTrailerInTipRange()
	Logging.warning("BaseMission.getIsTrailerInTipRange() is deprecated")
	return false
end

-- Local values: nearestVehicle, nearestDistance, _, vehicle, vehicleDistance
function BaseMission:getInteractiveVehicleInRange()
	if g_localPlayer == nil or g_localPlayer:getAreHandsHoldingObject() then
		return nil
	end
	local v208_ = math.huge
	local v209_ = nil
	for _, v210_ in pairs(self.vehicleSystem.interactiveVehicles) do
		if v210_.getIsInteractive ~= nil and v210_:getIsInteractive() then
			local v211_ = v210_:getDistanceToNode(g_localPlayer.rootNode)
			if v211_ < v208_ then
				v209_ = v210_
				v208_ = v211_
			end
		end
	end
	return v209_
end

function BaseMission:setMissionInfo(missionInfo, missionDynamicInfo)
	self.missionInfo = missionInfo
	self.missionDynamicInfo = missionDynamicInfo
	self:setMoneyUnit(g_gameSettings:getValue(GameSettings.SETTING.MONEY_UNIT))
	self:setUseMiles(g_gameSettings:getValue(GameSettings.SETTING.USE_MILES))
	self:setUseFahrenheit(g_gameSettings:getValue(GameSettings.SETTING.USE_FAHRENHEIT))
	self:setUseAcre(g_gameSettings:getValue(GameSettings.SETTING.USE_ACRE))
	self.hud:setMissionInfo(missionInfo)
	g_inGameMenu:setMissionInfo(missionInfo, missionDynamicInfo, self.baseDirectory)
end

function BaseMission:onCreateTriggerMarker(id)
	g_currentMission:addTriggerMarker(id)
end

function BaseMission:addTriggerMarker(id)
	setVisibility(id, self.triggerMarkersAreVisible)
	table.addElement(self.triggerMarkers, id)
end

function BaseMission:removeTriggerMarker(id)
	table.removeElement(self.triggerMarkers, id)
	setVisibility(id, false)
end

-- Local values: _, node
function BaseMission:setShowTriggerMarker(areVisible)
	self.triggerMarkersAreVisible = areVisible
	for _, v222_ in ipairs(self.triggerMarkers) do
		setVisibility(v222_, areVisible)
	end
end

function BaseMission:addHelpTrigger(id)
	setVisibility(id, self.helpTriggersAreVisible)
	table.addElement(self.helpTriggers, id)
end

function BaseMission:removeHelpTrigger(id)
	table.removeElement(self.helpTriggers, id)
end

function BaseMission:setShowHelpTrigger(areVisible)
	self.helpTriggersAreVisible = areVisible
	self:updateHelpTriggerVisibility()
end

-- Local values: visible, _, node
function BaseMission:updateHelpTriggerVisibility()
	local v230_ = self:getCanShowHelpTriggers()
	for _, v231_ in ipairs(self.helpTriggers) do
		setVisibility(v231_, v230_)
		if v230_ then
			addToPhysics(v231_)
		else
			removeFromPhysics(v231_)
		end
	end
end

function BaseMission:getCanShowHelpTriggers()
	return self.helpTriggersAreVisible
end

function BaseMission:setShowFieldInfo(isVisible)
	self.hud:setInfoVisible(isVisible)
end

function BaseMission:addHelpButtonText()
	Logging.error("BaseMission:addHelpButtonText() is deprecated, use InputBinding:setActionEventText() instead")
	printCallstack()
end

function BaseMission:addHelpAxis()
	Logging.error("BaseMission:addHelpAxis() is deprecated")
	printCallstack()
end

function BaseMission:addExtraPrintText(text)
	self.hud:addExtraPrintText(text)
end

function BaseMission:addGameNotification(title, text, info, iconFilename, duration)
	return self.hud:addTopNotification(title, text, info, iconFilename, duration)
end

function BaseMission:showBlinkingWarning(text, durationMs, identifier)
	self.hud:showBlinkingWarning(text, durationMs, identifier)
end

function BaseMission:setMoneyUnit(unit) end

function BaseMission:setUseMiles(useMiles) end

function BaseMission:setUseAcre(useAcrea) end

function BaseMission:setUseFahrenheit(useFahrenheit) end

function BaseMission:fadeScreen(direction, duration, callbackFunc, callbackTarget, arguments)
	self.hud:fadeScreen(direction, duration, callbackFunc, callbackTarget, arguments)
end

-- Local values: numItems, _, item, _, item
function BaseMission:getNumOfItems(storeItem, farmId)
	local v256_ = 0
	if self.ownedItems[storeItem] ~= nil then
		if farmId == nil then
			v256_ = v256_ + self.ownedItems[storeItem].numItems
		elseif self.ownedItems[storeItem].numItems > 0 then
			for _, v257_ in pairs(self.ownedItems[storeItem].items) do
				if v257_:getOwnerFarmId() == farmId then
					v256_ = v256_ + 1
				end
			end
		end
	end
	if self.leasedItems[storeItem] ~= nil then
		if farmId == nil then
			return v256_ + self.leasedItems[storeItem].numItems
		end
		if self.leasedItems[storeItem].numItems > 0 then
			for _, v258_ in pairs(self.leasedItems[storeItem].items) do
				if v258_:getOwnerFarmId() == farmId then
					v256_ = v256_ + 1
				end
			end
		end
	end
	return v256_
end

function BaseMission:spawnCollisionTestCallback(transformId)
	if self.nodeToObject[transformId] ~= nil then
		self.spawnCollisionsFound = true
	end
end

function BaseMission:setMapTargetHotspot(mapHotspot)
	if self.currentMapTargetHotspot ~= nil then
		self.currentMapTargetHotspot:setBlinking(false)
		self.currentMapTargetHotspot:setPersistent(false)
		g_currentMission.economyManager:updateGreatDemandsPDASpots()
	end
	if mapHotspot ~= nil then
		mapHotspot:setBlinking(true)
		mapHotspot:setPersistent(Platform.ingameMap.taggedHotspotsArePersistent)
	end
	self.currentMapTargetHotspot = mapHotspot
end

-- Local values: place
function BaseMission:onCreateLoadSpawnPlace(node)
	local v264_ = PlacementUtil.loadPlaceFromNode(node)
	local v265_ = g_currentMission.loadSpawnPlaces
	table.insert(v265_, v264_)
end

-- Local values: place
function BaseMission:onCreateStoreSpawnPlace(node)
	local v267_ = PlacementUtil.loadPlaceFromNode(node)
	local v268_ = g_currentMission.storeSpawnPlaces
	table.insert(v268_, v267_)
end

-- Local values: restrictedZone
function BaseMission:onCreateRestrictedZone(node)
	local v270_ = PlacementUtil.createRestrictedZone(node)
	local v271_ = g_currentMission.restrictedZones
	table.insert(v271_, v270_)
end

function BaseMission:getResetPlaces()
	if #self.loadSpawnPlaces > 0 then
		return self.loadSpawnPlaces
	else
		return self.storeSpawnPlaces
	end
end

-- Local values: screenShotFolder, baseFilename, numMSAA, clearColorR, clearColorG, clearColorB, clearColorA, bloomQuality, useDOF, ssaoQuality
function BaseMission:consoleCommandRender360Screenshot(resolution, subDir)
	local v275_ = g_screenshotsDirectory
	local v276_
	if subDir == nil then
		v276_ = v275_ .. "fsScreen_" .. getDate("%Y_%m_%d_%H_%M_%S") .. "/"
	else
		v276_ = v275_ .. subDir .. "/"
	end
	createFolder(v276_)
	local v277_ = v276_ .. "fsScreen360"
	local v278_ = tonumber(resolution) or 512
	render360Screenshot(v277_, v278_, "hdr_raw", 1, 0, 0, 0, 0, 5, true, 5)
end

-- Local values: usage, nodeNameUpper, numTarversedNodes, numAffectedNodes, checkNode
function BaseMission:consoleCommandSetShaderParameter(nodeName, shaderParameterName, x, y, z, w, shared)
	if nodeName == nil then
		return "Error: no nodeName given\nUsage: gsShaderParamsSet nodeName shaderParameterName [x] [y] [z] [w] [shared]\nNodeName is case insensitive"
	end
	if shaderParameterName == nil then
		return "Error: no shaderParameterName given\nUsage: gsShaderParamsSet nodeName shaderParameterName [x] [y] [z] [w] [shared]\nNodeName is case insensitive"
	end
	local v_u_286_ = tonumber(x)
	local v_u_287_ = tonumber(y)
	local v_u_288_ = tonumber(z)
	local v_u_289_ = tonumber(w)
	local v_u_290_ = Utils.stringToBoolean(shared)
	local v_u_291_ = string.upper(nodeName)
	local v_u_292_ = 0
	local v_u_293_ = 0
	local function v299_(p294_)
		-- upvalues: (ref) v_u_292_, (copy) v_u_291_, (copy) shaderParameterName, (ref) v_u_286_, (ref) v_u_287_, (ref) v_u_288_, (ref) v_u_289_, (ref) v_u_290_, (ref) v_u_293_
		v_u_292_ = v_u_292_ + 1
		if string.upper(getName(p294_)) == v_u_291_ and getHasClassId(p294_, ClassIds.SHAPE) then
			if not getHasShaderParameter(p294_, shaderParameterName) then
				return true
			end
			local v295_, v296_, v297_, v298_ = getShaderParameter(p294_, shaderParameterName)
			setShaderParameter(p294_, shaderParameterName, v_u_286_ or v295_, v_u_287_ or v296_, v_u_288_ or v297_, v_u_289_ or v298_, v_u_290_)
			Logging.info("set shader parameter \'%s\' for node \'%s\' to x=%.3f y=%.3f z=%.3f w=%.3f shared=%s", shaderParameterName, I3DUtil.getNodePath(p294_), v_u_286_ or v295_, v_u_287_ or v296_, v_u_288_ or v297_, v_u_289_ or v298_, v_u_290_)
			v_u_293_ = v_u_293_ + 1
		end
	end
	I3DUtil.iterateRecursively(getRootNode(), v299_)
	return string.format("Finished traversal of %d nodes, %d nodes affected", v_u_292_, v_u_293_)
end

function BaseMission:setLastInteractionTime(timeDelta)
	self.lastInteractionTime = g_time
end

-- Local values: messageCenter
function BaseMission:subscribeSettingsChangeMessages()
	local v302_ = g_messageCenter
	v302_:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.MONEY_UNIT], self.setMoneyUnit, self)
	v302_:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_MILES], self.setUseMiles, self)
	v302_:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_ACRE], self.setUseAcre, self)
	v302_:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_FAHRENHEIT], self.setUseFahrenheit, self)
	v302_:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.SHOW_TRIGGER_MARKER], self.setShowTriggerMarker, self)
	v302_:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.SHOW_HELP_TRIGGER], self.setShowHelpTrigger, self)
	v302_:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.SHOW_FIELD_INFO], self.setShowFieldInfo, self)
end

function BaseMission:subscribeGuiOpenCloseMessages()
	g_messageCenter:subscribe(MessageType.GUI_BEFORE_OPEN, self.onBeforeMenuOpen, self)
	g_messageCenter:subscribe(MessageType.GUI_AFTER_CLOSE, self.onAfterMenuClose, self)
end

function BaseMission:onBeforeMenuOpen() end

function BaseMission:onAfterMenuClose() end

function BaseMission:onGameStateChange(newGameState, oldGameState)
	if newGameState ~= GameState.PAUSED then
		self.lastNonPauseGameState = newGameState
	end
end
