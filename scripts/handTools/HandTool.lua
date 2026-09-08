-- Local values: HandTool_mt
HandTool = {}
local HandTool_mt = Class(HandTool, Object)
InitStaticObjectClass(HandTool, "HandTool")
HandTool.DEFAULT_CROSSHAIR_COLOR = Color.new(1, 1, 1, 0.3)
HandTool.DEFAULT_CROSSHAIR_SIZE_PIXELS = 48
function HandTool.init()
	for _, v2_ in pairs(g_handToolSpecializationManager:getSpecializations()) do
		local v3_ = ClassUtil.getClassObject(v2_.className)
		if v3_ ~= nil and rawget(v3_, "init") ~= nil then
			v3_.init()
		end
	end
end
function HandTool.postInit() end
function HandTool.registerXMLPaths()
	local v4_ = XMLSchema.new("handTool")
	HandTool.xmlSchema = v4_
	g_storeManager:addSpeciesXMLSchema(StoreSpecies.HANDTOOL, HandTool.xmlSchema)
	g_handToolTypeManager:setXMLSchema(HandTool.xmlSchema)
	HandTool.xmlSchemaSounds = XMLSchema.new("handTool_sounds")
	HandTool.xmlSchemaSounds:setRootNodeName("sounds")
	HandTool.xmlSchema:addSubSchema(HandTool.xmlSchemaSounds, "sounds")
	StoreManager.registerStoreDataXMLPaths(v4_, "handTool")
	I3DUtil.registerI3dMappingXMLPaths(v4_, "handTool")
	v4_:register(XMLValueType.STRING, "handTool.annotation", "Annotation", nil, true)
	v4_:register(XMLValueType.BOOL, "handTool.base#canCrouch", "If the player can crouch while holding this tool", true, false)
	v4_:register(XMLValueType.BOOL, "handTool.base#mustBeHeld", "True if this tool must be held, and cannot be put away; false otherwise", false, false)
	v4_:register(XMLValueType.BOOL, "handTool.base#canBeSaved", "True if this tool can be saved; false otherwise", "Defaults to true, so that the tool will be saved", false)
	v4_:register(XMLValueType.BOOL, "handTool.base#canBeDropped", "True if this tool can be dropped to inventory", "Defaults to true, so that the tool will be dropped", false)
	v4_:register(XMLValueType.FLOAT, "handTool.base#runMultiplier", "The amount of run speed the player gains while running with this tool", true, false)
	v4_:register(XMLValueType.FLOAT, "handTool.base#walkMultiplier", "The amount of walk speed the player gains while walking with this tool", true, false)
	v4_:register(XMLValueType.FLOAT, "handTool.base#jumpMultiplier", "The amount of jump strength the player gains while walking with this tool", true, false)
	v4_:register(XMLValueType.L10N_STRING, "handTool.base.actions#activate", "The text displayed for activating the tool", nil, false)
	v4_:register(XMLValueType.STRING, "handTool.base.filename", "Hand tool i3d file", nil, false)
	v4_:register(XMLValueType.L10N_STRING, "handTool.base.typeDesc", "Hand tool name localization string", nil, false)
	v4_:register(XMLValueType.STRING, "handTool.base.sounds#filename", "The filename of the xml file defining the sounds of the tool", nil, false)
	v4_:register(XMLValueType.NODE_INDEX, "handTool.base.graphics#node", "The node containing all the graphical nodes of the tool", nil, false)
	v4_:register(XMLValueType.BOOL, "handTool.base.graphics#lockFirstPerson", "True if first person mode should be forced, false for third person. A lack of this attribute does not lock the perspective at all", nil, false)
	v4_:register(XMLValueType.NODE_INDEX, "handTool.base.handNode#node", "The node used to position the hand tool when held in third person", nil, false)
	v4_:register(XMLValueType.BOOL, "handTool.base.handNode#useLeftHand", "If the handtool should be attached to player left hand", nil, false)
	v4_:register(XMLValueType.NODE_INDEX, "handTool.base.firstPersonNode#node", "The node used to position the hand tool when held in first person", nil, false)
	v4_:register(XMLValueType.NODE_INDEX, "handTool.base.carried#targetNode", "The node of the player character that the tool is attached to when not held", nil, false)
	v4_:register(XMLValueType.NODE_INDEX, "handTool.base.carried#node", "The node used to position the hand tool when not held", nil, false)
	v4_:register(XMLValueType.FLOAT, "handTool.base#mass", "Mass in kilograms", nil, false)
	v4_:register(XMLValueType.STRING, "handTool#type", "The specialisation type of the hand tool", nil, true)
	v4_:registerAutoCompletionDataSource("handTool#type", "$dataS/handToolTypes.xml", "handToolTypes.type#name")
	for _, v5_ in pairs(g_handToolSpecializationManager:getSpecializations()) do
		local v6_ = ClassUtil.getClassObject(v5_.className)
		if v6_ ~= nil and v6_.registerXMLPaths then
			v6_.registerXMLPaths(v4_)
			v4_:setXMLSpecializationType()
		end
	end
end

-- Local values: handToolBaseKey, _, specialisation, specialisationClass
function HandTool.registerSavegameXMLPaths(savegameXMLSchema)
	savegameXMLSchema:register(XMLValueType.STRING, "handTools.handTool(?)#filename", "The filename of the tool xml file", nil, true)
	savegameXMLSchema:register(XMLValueType.STRING, "handTools.handTool(?)#modName", "Name of mod")
	savegameXMLSchema:register(XMLValueType.STRING, "handTools.handTool(?)#uniqueId", "The unique id of the hand tool within the savegame", nil, true)
	savegameXMLSchema:register(XMLValueType.INT, "handTools.handTool(?)#farmId", "The id of the farm owning the tool", nil, true)
	savegameXMLSchema:register(XMLValueType.FLOAT, "handTools.handTool(?)#age", "The age of the hand tool", nil, true)
	savegameXMLSchema:register(XMLValueType.FLOAT, "handTools.handTool(?)#price", "The price of the hand tool", nil, true)
	savegameXMLSchema:register(XMLValueType.STRING, "handTools.handTool(?).holder#uniqueId", "Last holder", nil, true)
	for _, v8_ in pairs(g_handToolSpecializationManager:getSpecializations()) do
		local v9_ = ClassUtil.getClassObject(v8_.className)
		if v9_ ~= nil and v9_.registerSavegameXMLPaths then
			v9_.registerSavegameXMLPaths(savegameXMLSchema, "handTools.handTool(?)")
		end
	end
end

function HandTool.registerFunctions(handToolType)
	SpecializationUtil.registerFunction(handToolType, "register", HandTool.register)
	SpecializationUtil.registerFunction(handToolType, "getShowInHandToolsOverview", HandTool.getShowInHandToolsOverview)
	SpecializationUtil.registerFunction(handToolType, "getNeedsSaving", HandTool.getNeedsSaving)
	SpecializationUtil.registerFunction(handToolType, "getCanBeDropped", HandTool.getCanBeDropped)
	SpecializationUtil.registerFunction(handToolType, "getHolder", HandTool.getHolder)
	SpecializationUtil.registerFunction(handToolType, "setHolder", HandTool.setHolder)
	SpecializationUtil.registerFunction(handToolType, "getIsCarried", HandTool.getIsCarried)
	SpecializationUtil.registerFunction(handToolType, "setCarryingPlayer", HandTool.setCarryingPlayer)
	SpecializationUtil.registerFunction(handToolType, "getCarryingPlayer", HandTool.getCarryingPlayer)
	SpecializationUtil.registerFunction(handToolType, "getPrice", HandTool.getPrice)
	SpecializationUtil.registerFunction(handToolType, "getSellPrice", HandTool.getSellPrice)
	SpecializationUtil.registerFunction(handToolType, "getIsActiveForInput", HandTool.getIsActiveForInput)
	SpecializationUtil.registerFunction(handToolType, "getIsHeld", HandTool.getIsHeld)
	SpecializationUtil.registerFunction(handToolType, "setCarryingPlayerShown", HandTool.setCarryingPlayerShown)
	SpecializationUtil.registerFunction(handToolType, "setCarryingPlayerHidden", HandTool.setCarryingPlayerHidden)
	SpecializationUtil.registerFunction(handToolType, "setCarryingPlayerStyleChanged", HandTool.setCarryingPlayerStyleChanged)
	SpecializationUtil.registerFunction(handToolType, "setCarryingPlayerExitedVehicle", HandTool.setCarryingPlayerExitedVehicle)
	SpecializationUtil.registerFunction(handToolType, "setCarryingPlayerEnteredVehicle", HandTool.setCarryingPlayerEnteredVehicle)
	SpecializationUtil.registerFunction(handToolType, "setCarryingPlayerPerspectiveChanged", HandTool.setCarryingPlayerPerspectiveChanged)
	SpecializationUtil.registerFunction(handToolType, "getName", HandTool.getName)
	SpecializationUtil.registerFunction(handToolType, "attachTool", HandTool.attachTool)
	SpecializationUtil.registerFunction(handToolType, "detachTool", HandTool.detachTool)
	SpecializationUtil.registerFunction(handToolType, "attachToolToHand", HandTool.attachToolToHand)
	SpecializationUtil.registerFunction(handToolType, "attachToolToCamera", HandTool.attachToolToCamera)
	SpecializationUtil.registerFunction(handToolType, "attachToolToCharacter", HandTool.attachToolToCharacter)
end

function HandTool.registerEvents(handToolType)
	SpecializationUtil.registerEvent(handToolType, "onPreLoad")
	SpecializationUtil.registerEvent(handToolType, "onLoad")
	SpecializationUtil.registerEvent(handToolType, "onPostLoad")
	SpecializationUtil.registerEvent(handToolType, "onLoadFinished")
	SpecializationUtil.registerEvent(handToolType, "onDelete")
	SpecializationUtil.registerEvent(handToolType, "onSave")
	SpecializationUtil.registerEvent(handToolType, "onRegistered")
	SpecializationUtil.registerEvent(handToolType, "onWriteStream")
	SpecializationUtil.registerEvent(handToolType, "onReadStream")
	SpecializationUtil.registerEvent(handToolType, "onWriteUpdateStream")
	SpecializationUtil.registerEvent(handToolType, "onReadUpdateStream")
	SpecializationUtil.registerEvent(handToolType, "onPreUpdate")
	SpecializationUtil.registerEvent(handToolType, "onUpdate")
	SpecializationUtil.registerEvent(handToolType, "onPostUpdate")
	SpecializationUtil.registerEvent(handToolType, "onUpdateTick")
	SpecializationUtil.registerEvent(handToolType, "onDraw")
	SpecializationUtil.registerEvent(handToolType, "onRegisterActionEvents")
	SpecializationUtil.registerEvent(handToolType, "onHandToolHolderChanged")
	SpecializationUtil.registerEvent(handToolType, "onHeldStart")
	SpecializationUtil.registerEvent(handToolType, "onHeldEnd")
	SpecializationUtil.registerEvent(handToolType, "onCarryingPlayerStyleChanged")
	SpecializationUtil.registerEvent(handToolType, "onCarryingPlayerShown")
	SpecializationUtil.registerEvent(handToolType, "onCarryingPlayerHidden")
	SpecializationUtil.registerEvent(handToolType, "onCarryingPlayerEnteredVehicle")
	SpecializationUtil.registerEvent(handToolType, "onCarryingPlayerExitedVehicle")
	SpecializationUtil.registerEvent(handToolType, "onCarryingPlayerChanged")
	SpecializationUtil.registerEvent(handToolType, "onCarryingPlayerPerspectiveSwitched")
	SpecializationUtil.registerEvent(handToolType, "onDebugDraw")
end

-- Upvalues: HandTool_mt
-- Local values: self
function HandTool.new(isServer, isClient, customMt)
	-- upvalues: (copy) HandTool_mt
	local v15_ = Object.new(isServer, isClient, customMt or HandTool_mt)
	v15_.finishedLoading = false
	v15_.isDeleted = false
	v15_.updateLoopIndex = -1
	v15_.sharedLoadRequestId = nil
	v15_.loadingState = HandToolLoadingState.OK
	v15_.loadingStep = SpecializationLoadStep.CREATED
	v15_.loadingTasks = {}
	v15_.readyForFinishLoading = false
	v15_.uniqueId = nil
	v15_.rootNode = nil
	v15_.graphicalNode = nil
	v15_.handNode = nil
	v15_.useLeftHand = false
	v15_.firstPersonNode = nil
	v15_.mass = 0
	v15_.actionEvents = {}
	v15_.carryingPlayer = nil
	v15_.isHeld = false
	v15_.holder = nil
	return v15_
end

function HandTool:setFilename(filename)
	self.configFileName = filename
	self.configFileNameClean = Utils.getFilenameInfo(filename, true)
	local v18_, v19_ = Utils.getModNameAndBaseDirectory(filename)
	self.customEnvironment = v18_
	self.baseDirectory = v19_
end

function HandTool:setType(typeDef)
	SpecializationUtil.initSpecializationsIntoTypeClass(g_handToolTypeManager, typeDef, self)
end

function HandTool:setLoadCallback(loadCallbackFunction, loadCallbackFunctionTarget, loadCallbackFunctionArguments)
	self.loadCallbackFunction = loadCallbackFunction
	self.loadCallbackFunctionTarget = loadCallbackFunctionTarget
	self.loadCallbackFunctionArguments = loadCallbackFunctionArguments
end

-- Local values: mission, handToolSystem
function HandTool:loadCallback()
	g_currentMission.handToolSystem:removePendingHandToolLoad(self)
	if self.loadCallbackFunction ~= nil then
		self.loadCallbackFunction(self.loadCallbackFunctionTarget, self, self.loadingState, self.loadCallbackFunctionArguments)
		self.loadCallbackFunctionTarget = nil
		self.loadCallbackFunctionArguments = nil
	end
end

-- Local values: mission, handToolSystem, storeItem, isPathValid, invalidDesc
function HandTool:load(handToolLoadingData)
	local v29_ = g_currentMission.handToolSystem
	self.handToolLoadingData = handToolLoadingData
	if not self.handToolLoadingData.canBeDropped then
		self.canBeDropped = false
	end
	v29_:addPendingHandToolLoad(self)
	self:setLoadingStep(SpecializationLoadStep.PRE_LOAD)
	if self.type == nil then
		Logging.xmlWarning(self.xmlFile, "Unable to find handtoolType")
		self:setLoadingState(HandToolLoadingState.ERROR)
		return self.loadingState
	else
		self.xmlFile = XMLFile.load("handToolXML", self.configFileName, HandTool.xmlSchema)
		self.savegame = handToolLoadingData.savegameData
		local v30_ = g_storeManager:getItemByXMLFilename(self.configFileName)
		if v30_ ~= nil then
			self.brand = g_brandManager:getBrandByIndex(v30_.brandIndex)
			self.lifetime = v30_.lifetime
		end
		SpecializationUtil.copyTypeFunctionsInto(self.type, self)
		SpecializationUtil.createSpecializationEnvironments(self, function(p31_, p32_)
			-- upvalues: (copy) self
			Logging.xmlError(self.xmlFile, "The handTool specialization \'%s\' could not be added because variable \'%s\' already exists!", p31_, p32_)
			self:setLoadingState(HandToolLoadingState.ERROR)
		end)
		SpecializationUtil.raiseEvent(self, "onPreLoad", self.savegame)
		if self.loadingState == HandToolLoadingState.OK then
			self.i3dFilename = Utils.getFilename(self.xmlFile:getValue("handTool.base.filename"), self.baseDirectory)
			if self.i3dFilename == nil then
				self:loadFinished()
			else
				local v33_, v34_ = Utils.getPathIsValid(self.i3dFilename)
				if not v33_ then
					Logging.xmlWarning(self.xmlFile, "Filename contains %s, which are not allowed! (%s)", v34_, "handTool.base.filename")
				end
				self:setLoadingStep(SpecializationLoadStep.AWAIT_I3D)
				self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.i3dFilename, true, false, self.i3dFileLoaded, self)
			end
			return nil
		else
			Logging.xmlError(self.xmlFile, "Handtool pre-loading failed!")
			self.xmlFile:delete()
			return false
		end
	end
end

function HandTool:i3dFileLoaded(i3dNode, failedReason, arguments, i3dLoadingId)
	if i3dNode == 0 then
		self:setLoadingState(HandToolLoadingState.ERROR)
		Logging.xmlError(self.xmlFile, "Handtool i3d loading failed!")
		self:loadCallback()
	else
		self.i3dNode = i3dNode
		setVisibility(i3dNode, false)
		self:loadFinished()
	end
end

-- Local values: savegame, uniqueId, farmId, storeItem, _, component, soundsXMLFilename, mission
function HandTool:loadFinished()
	self:setLoadingState(HandToolLoadingState.OK)
	self:setLoadingStep(SpecializationLoadStep.LOAD)
	self.age = 0
	self:setOwnerFarmId(self.handToolLoadingData.ownerFarmId, true)
	self.mass = self.xmlFile:getValue("handTool.base#mass", 0)
	local v38_ = self.savegame
	if v38_ ~= nil then
		local v39_ = v38_.xmlFile:getValue(v38_.key .. "#uniqueId", nil)
		if v39_ ~= nil then
			self:setUniqueId(v39_)
		end
		local v40_ = v38_.xmlFile:getValue(v38_.key .. "#farmId", AccessHandler.EVERYONE)
		if g_farmManager.mergedFarms ~= nil and g_farmManager.mergedFarms[v40_] ~= nil then
			v40_ = g_farmManager.mergedFarms[v40_]
		end
		self:setOwnerFarmId(v40_, true)
	end
	self.price = self.handToolLoadingData.price
	if self.price == 0 or self.price == nil then
		local v41_ = g_storeManager:getItemByXMLFilename(self.configFileName)
		self.price = StoreItemUtil.getDefaultPrice(v41_, self.configurations)
	end
	self.typeDesc = self.xmlFile:getValue("handTool.base.typeDesc", "TypeDescription", self.customEnvironment, true)
	self.activateText = self.xmlFile:getValue("handTool.base.actions#activate", "Activate", self.customEnvironment, true)
	if self.i3dNode ~= nil then
		self.rootNode = getChildAt(self.i3dNode, 0)
		self.components = {}
		I3DUtil.loadI3DComponents(self.i3dNode, self.components)
		self.i3dMappings = {}
		I3DUtil.loadI3DMapping(self.xmlFile, "handTool", self.rootLevelNodes, self.i3dMappings)
		for _, v42_ in ipairs(self.components) do
			link(getRootNode(), v42_.node)
			setVisibility(v42_.node, false)
		end
		delete(self.i3dNode)
		self.i3dNode = nil
		self.graphicalNode = self.xmlFile:getValue("handTool.base.graphics#node", nil, self.components, self.i3dMappings)
		if self.graphicalNode == nil then
			Logging.xmlError(self.xmlFile, "Handtool is missing graphical node! Graphics will not work as intended!")
			self:setLoadingState(HandToolLoadingState.ERROR)
			self:loadCallback()
			return
		end
		self.graphicalNodeParent = getParent(self.graphicalNode)
		self.handNode = self.xmlFile:getValue("handTool.base.handNode#node", nil, self.components, self.i3dMappings)
		self.useLeftHand = self.xmlFile:getValue("handTool.base.handNode#useLeftHand", self.useLeftHand)
		self.firstPersonNode = self.xmlFile:getValue("handTool.base.firstPersonNode#node", nil, self.components, self.i3dMappings)
	end
	self.shouldLockFirstPerson = self.xmlFile:getValue("handTool.base.graphics#lockFirstPerson", nil)
	self.runMultiplier = self.xmlFile:getValue("handTool.base#runMultiplier", 1)
	self.walkMultiplier = self.xmlFile:getValue("handTool.base#walkMultiplier", 1)
	local v43_ = self.xmlFile:getValue("handTool.base#jumpMultiplier", 1)
	self.jumpMultiplier = math.clamp(v43_, 0, 1.2)
	self.canCrouch = self.xmlFile:getValue("handTool.base#canCrouch", true)
	self.mustBeHeld = self.xmlFile:getValue("handTool.base#mustBeHeld", false)
	self.canBeSaved = self.xmlFile:getValue("handTool.base#canBeSaved", true)
	if not self.handToolLoadingData.isSaved then
		self.canBeSaved = false
	end
	self.canBeDropped = self.xmlFile:getValue("handTool.base#canBeDropped", true)
	if not self.handToolLoadingData.canBeDropped then
		self.canBeDropped = false
	end
	local v44_ = self.xmlFile:getValue("handTool.base.sounds#filename", nil)
	local v45_ = Utils.getFilename(v44_, self.baseDirectory)
	self.externalSoundsFile = XMLFile.loadIfExists("TempExternalSounds", v45_, HandTool.xmlSchemaSounds)
	SpecializationUtil.raiseEvent(self, "onLoad", self.xmlFile, self.baseDirectory)
	if self.loadingState == HandToolLoadingState.OK then
		self:setLoadingStep(SpecializationLoadStep.POST_LOAD)
		SpecializationUtil.raiseEvent(self, "onPostLoad", self.savegame)
		if self.loadingState == HandToolLoadingState.OK then
			if v38_ ~= nil then
				self.age = v38_.xmlFile:getValue(v38_.key .. "#age", 0)
				self.price = v38_.xmlFile:getValue(v38_.key .. "#price", self.price)
			end
			local v46_ = g_currentMission
			if v46_ ~= nil and v46_.environment ~= nil then
				g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.periodChanged, self)
			end
			if #self.loadingTasks == 0 then
				self:onFinishedLoading()
			else
				self.readyForFinishLoading = true
				self:setLoadingStep(SpecializationLoadStep.AWAIT_SUB_I3D)
			end
		else
			Logging.xmlError(self.xmlFile, "HandTool post-loading failed!")
			self:loadCallback()
			return
		end
	else
		Logging.xmlError(self.xmlFile, "HandTool loading failed!")
		self:loadCallback()
		return
	end
end

-- Local values: mission, handToolSystem, holder, savegame
function HandTool:onFinishedLoading()
	self:setLoadingStep(SpecializationLoadStep.FINISHED)
	SpecializationUtil.raiseEvent(self, "onLoadFinished", self.savegame)
	if self.isServer then
		self:setLoadingStep(SpecializationLoadStep.SYNCHRONIZED)
	end
	self.finishedLoading = true
	if g_currentMission.handToolSystem:addHandTool(self) then
		if self.handToolLoadingData.isRegistered then
			self:register()
		end
		local v48_ = self.handToolLoadingData.holder
		if v48_ == nil then
			local v49_ = self.savegame
			if v49_ ~= nil then
				self.pendingHolderUniqueId = v49_.xmlFile:getValue(v49_.key .. ".holder#uniqueId", nil)
			end
		elseif v48_:getCanPickupHandTool(self) then
			self.pendingHolder = v48_
		end
		g_currentMission:addOwnedItem(self)
		self.savegame = nil
		self.handToolLoadingData = nil
		self.xmlFile:delete()
		self.xmlFile = nil
		if self.externalSoundsFile ~= nil then
			self.externalSoundsFile:delete()
			self.externalSoundsFile = nil
		end
		self:loadCallback()
	else
		Logging.xmlError(self.xmlFile, "Failed to register handTool!")
		self:setLoadingState(HandToolLoadingState.ERROR)
		self:loadCallback()
	end
end

function HandTool:createLoadingTask(target)
	return SpecializationUtil.createLoadingTask(self, target)
end

function HandTool:finishLoadingTask(task)
	SpecializationUtil.finishLoadingTask(self, task)
end

function HandTool:setLoadingState(loadingState)
	if HandToolLoadingState.getName(loadingState) == nil then
		printCallstack()
		Logging.error("Invalid loading state \'%s\'!", loadingState)
	else
		self.loadingState = loadingState
	end
end

function HandTool:setLoadingStep(loadingStep)
	SpecializationUtil.setLoadingStep(self, loadingStep)
end

-- Local values: mission, handToolSystem
function HandTool:delete()
	if not self.isDeleted then
		g_currentMission:removeOwnedItem(self)
		g_messageCenter:unsubscribeAll(self)
		local v59_ = g_currentMission.handToolSystem
		if self.holder ~= nil then
			self:setHolder(nil, true)
		end
		if self.sharedLoadRequestId ~= nil then
			g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
			self.sharedLoadRequestId = nil
		end
		SpecializationUtil.raiseEvent(self, "onDelete")
		if self.rootNode ~= nil and entityExists(self.rootNode) then
			delete(self.rootNode)
			self.rootNode = nil
		end
		v59_:removeHandTool(self)
		if self.externalSoundsFile ~= nil then
			self.externalSoundsFile:delete()
			self.externalSoundsFile = nil
		end
		HandTool:superClass().delete(self)
		self.isDeleted = true
	end
end

function HandTool:writeStream(streamId, connection)
	HandTool:superClass().writeStream(self, streamId, connection)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.configFileName))
	streamWriteBool(streamId, self.canBeDropped)
end

-- Local values: filename, canBeDropped, data, asyncCallbackFunction
function HandTool:readStream(streamId, connection, objectId)
	HandTool:superClass().readStream(self, streamId, connection, objectId)
	local v67_ = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
	local v68_ = streamReadBool(streamId)
	if self.loadingStep == SpecializationLoadStep.CREATED then
		local v69_ = HandToolLoadingData.new()
		v69_:setFilename(v67_)
		v69_:setOwnerFarmId(self.ownerFarmId)
		v69_:setCanBeDropped(v68_)
		v69_:loadHandToolOnClient(self, function(_, p70_, p71_)
			if p71_ == HandToolLoadingState.OK then
				g_client:onObjectFinishedAsyncLoading(p70_)
			else
				Logging.error("Failed to load handtool on client")
				printCallstack()
			end
		end, nil)
	else
		Logging.error("Try to intialize loading of a handtool that is already loading!")
	end
end

-- Local values: holder
function HandTool:postWriteStream(streamId, connection)
	local v75_ = self:getHolder()
	if streamWriteBool(streamId, v75_ ~= nil) then
		NetworkUtil.writeNodeObject(streamId, v75_)
		streamWriteBool(streamId, self:getIsHeld())
	end
	SpecializationUtil.raiseEvent(self, "onWriteStream", streamId, connection)
end

function HandTool:postReadStream(streamId, connection)
	if streamReadBool(streamId) then
		self.pendingHolderObjectId = NetworkUtil.readNodeObjectId(streamId)
		self.isHoldingPending = streamReadBool(streamId)
		self:raiseActive()
	end
	SpecializationUtil.raiseEvent(self, "onReadStream", streamId, connection)
	self:setLoadingStep(SpecializationLoadStep.SYNCHRONIZED)
end

function HandTool:writeUpdateStream(streamId, connection, dirtyMask)
	SpecializationUtil.raiseEvent(self, "onWriteUpdateStream", streamId, connection, dirtyMask)
end

function HandTool:readUpdateStream(streamId, timestamp, connection)
	SpecializationUtil.raiseEvent(self, "onReadUpdateStream", streamId, timestamp, connection)
end

function HandTool:getNeedsSaving()
	return self.canBeSaved
end

function HandTool:getCanBeDropped()
	return self.canBeDropped
end

-- Local values: id, spec, name
function HandTool:saveToXMLFile(xmlFile, key, usedModNames)
	xmlFile:setValue(key .. "#uniqueId", self.uniqueId)
	xmlFile:setValue(key .. "#farmId", self:getOwnerFarmId() or -1)
	xmlFile:setValue(key .. "#age", self.age)
	if self.holder ~= nil then
		xmlFile:setValue(key .. ".holder#uniqueId", self.holder:getUniqueId())
	end
	for v93_, v94_ in pairs(self.specializations) do
		local v95_ = self.specializationNames[v93_]
		if v94_.saveToXMLFile ~= nil then
			v94_.saveToXMLFile(self, xmlFile, key .. "." .. v95_, usedModNames)
		end
	end
end

function HandTool:getUniqueId()
	return self.uniqueId
end

function HandTool:setUniqueId(uniqueId)
	self.uniqueId = uniqueId
end

function HandTool:register(alreadySent)
	HandTool:superClass().register(self, alreadySent)
	SpecializationUtil.raiseEvent(self, "onRegistered", alreadySent)
end

function HandTool:getIsSynchronized()
	return self.loadingStep == SpecializationLoadStep.SYNCHRONIZED
end

function HandTool:getHolder()
	return self.holder
end

-- Local values: lastHolder, lastOwner, success
function HandTool:setHolder(holder, noEventSend)
	if holder == nil or holder ~= self.holder then
		HandToolSetHolderEvent.sendEvent(self, holder, noEventSend)
		if self.holder ~= nil then
			local v106_ = self.holder
			self.holder = nil
			v106_:onDropHandTool(self)
		end
		local v107_ = self.holder
		if holder ~= nil then
			if holder:onPickupHandTool(self) then
				self.holder = holder
				if self.rootNode ~= nil then
					setVisibility(self.rootNode, true)
				end
			else
				holder = nil
			end
		end
		SpecializationUtil.raiseEvent(self, "onHandToolHolderChanged", holder, v107_)
	else
		Logging.devInfo("HandTool.setHolder: Tried to set same holder %q (%s) again for handtool %q (%s)", holder, holder:getUniqueId(), self.configFileName, self.uniqueId)
	end
end

-- Local values: holder, mission, holder, carryingPlayer
function HandTool:update(dt)
	if self.pendingHolder ~= nil then
		self:setHolder(self.pendingHolder)
		self.pendingHolder = nil
	end
	if self.pendingHolderObjectId ~= nil then
		local v110_ = NetworkUtil.getObject(self.pendingHolderObjectId)
		if v110_ ~= nil then
			if v110_:getCanPickupHandTool(self) then
				self:setHolder(v110_, true)
				if self.isHoldingPending and self.carryingPlayer ~= nil then
					self.carryingPlayer:setCurrentHandTool(self, true)
				end
			end
			self.pendingHolderObjectId = nil
			self.isHoldingPending = nil
		end
		self:raiseActive()
	end
	if self.pendingHolderUniqueId ~= nil then
		local v111_ = g_currentMission:getObjectByUniqueId(self.pendingHolderUniqueId)
		if v111_ ~= nil then
			self:setHolder(v111_)
			self.pendingHolderUniqueId = nil
		end
		self:raiseActive()
	end
	SpecializationUtil.raiseEvent(self, "onPreUpdate", dt)
	SpecializationUtil.raiseEvent(self, "onUpdate", dt)
	SpecializationUtil.raiseEvent(self, "onPostUpdate", dt)
	if self:getIsHeld() then
		local v112_ = self:getCarryingPlayer()
		if v112_ ~= nil and v112_:getIsControlled() then
			self:raiseActive()
		end
	end
end

function HandTool:updateTick(dt)
	SpecializationUtil.raiseEvent(self, "onUpdateTick", dt)
end

function HandTool:draw()
	SpecializationUtil.raiseEvent(self, "onDraw")
end

-- Local values: player
function HandTool:startHolding()
	self:raiseActive()
	self.isHoldStarting = true
	local v117_ = self.carryingPlayer
	if v117_ ~= nil and (v117_:getForceHandToolFirstPerson() and self.shouldLockFirstPerson ~= nil) then
		self.wasInFirstPerson = v117_.camera.isFirstPerson
		if self.shouldLockFirstPerson then
			v117_.camera:lockFirstPersonMode()
		else
			v117_.camera:lockThirdPersonMode()
		end
	end
	self.isHeld = true
	self:attachTool()
	SpecializationUtil.raiseEvent(self, "onHeldStart", v117_)
	self:clearActionEvents()
	if v117_ ~= nil and v117_.isOwner then
		self:registerActionEvents()
	end
	self.isHoldStarting = false
end

-- Local values: carryingPlayer
function HandTool:stopHolding()
	self.isHoldEnding = true
	local v119_ = self:getCarryingPlayer()
	if v119_ ~= nil and (v119_:getForceHandToolFirstPerson() and self.shouldLockFirstPerson ~= nil) then
		v119_.camera:unlockSwitching()
		v119_.camera:switchToPerspective(self.wasInFirstPerson)
	end
	self.isHeld = false
	self:detachTool()
	SpecializationUtil.raiseEvent(self, "onHeldEnd")
	self:clearActionEvents()
	if v119_ ~= nil and v119_.isOwner then
		self:registerActionEvents()
	end
	self.isHoldEnding = false
end

function HandTool:getIsCarried()
	return self.carryingPlayer ~= nil
end

-- Local values: lastCarryingPlayer
function HandTool:setCarryingPlayer(player)
	local v123_ = self.carryingPlayer
	self.carryingPlayer = player
	SpecializationUtil.raiseEvent(self, "onCarryingPlayerChanged", player, v123_)
	self:clearActionEvents()
	if player ~= nil and player.isOwner then
		self:registerActionEvents()
	end
end

function HandTool:getCarryingPlayer()
	return self.carryingPlayer
end

function HandTool:periodChanged()
	self.age = self.age + 1
end

function HandTool:getPrice()
	return self.price
end

-- Local values: storeItem
function HandTool:getSellPrice()
	local v128_ = g_storeManager:getItemByXMLFilename(self.configFileName)
	return HandTool.calculateSellPrice(v128_, self.age, self:getPrice())
end

function HandTool:getDailyUpkeep()
	return 0
end

-- Local values: ageInYears, ageFactor
function HandTool.calculateSellPrice(storeItem, age, price)
	local v131_ = age / Environment.PERIODS_IN_YEAR
	local v132_ = -0.1 * math.log(v131_) + 0.75
	local v133_ = price * math.min(v132_, 0.8)
	local v134_ = price * 0.03
	return math.max(v133_, v134_)
end

-- Local values: carryingPlayer
function HandTool:getIsActiveForInput(mustBeHeld)
	local v137_ = self:getCarryingPlayer()
	if v137_ == nil or not v137_.isOwner then
		return false
	else
		return (not mustBeHeld or self:getIsHeld()) and true or false
	end
end

function HandTool:getIsHeld()
	if self:getIsCarried() then
		return self.isHeld
	else
		return false
	end
end

-- Local values: carryingPlayer
function HandTool:setCarryingPlayerShown()
	self:attachTool()
	local v140_ = self:getCarryingPlayer()
	if v140_ ~= nil and v140_.isOwner then
		self:clearActionEvents()
		self:registerActionEvents()
	end
	SpecializationUtil.raiseEvent(self, "onCarryingPlayerShown")
	self:raiseActive()
end

-- Local values: carryingPlayer
function HandTool:setCarryingPlayerHidden()
	self:detachTool()
	local v142_ = self:getCarryingPlayer()
	if v142_ ~= nil and v142_.isOwner then
		self:clearActionEvents(true)
	end
	SpecializationUtil.raiseEvent(self, "onCarryingPlayerHidden")
end

function HandTool:setCarryingPlayerStyleChanged()
	SpecializationUtil.raiseEvent(self, "onCarryingPlayerStyleChanged")
end

function HandTool:setCarryingPlayerEnteredVehicle()
	SpecializationUtil.raiseEvent(self, "onCarryingPlayerEnteredVehicle")
end

function HandTool:setCarryingPlayerExitedVehicle()
	SpecializationUtil.raiseEvent(self, "onCarryingPlayerExitedVehicle")
end

-- Local values: storeItem
function HandTool:getName()
	local v147_ = g_storeManager:getItemByXMLFilename(self.configFileName)
	if v147_ == nil then
		return nil
	else
		return v147_.name
	end
end

function HandTool:getShowInHandToolsOverview()
	return self:getCanBeDropped()
end

function HandTool:setCarryingPlayerPerspectiveChanged(isFirstPerson)
	if not (self.isHoldEnding or self.isHoldStarting) then
		self:detachTool()
		self:attachTool()
		SpecializationUtil.raiseEvent(self, "onCarryingPlayerPerspectiveSwitched", isFirstPerson)
	end
end

function HandTool:attachTool()
	if self:getIsHeld() then
		if self.carryingPlayer:getForceHandToolFirstPerson() and self.carryingPlayer.camera.isFirstPerson then
			self:attachToolToCamera()
		else
			self:attachToolToHand()
		end
		if self.rootNode ~= nil then
			setVisibility(self.rootNode, true)
		end
	end
end

function HandTool:detachTool()
	if self.rootNode ~= nil then
		setVisibility(self.rootNode, false)
		unlink(self.rootNode)
	end
end

-- Local values: playerModel, handNode
function HandTool:attachToolToHand()
	if not self:getIsHeld() or (self.carryingPlayer.graphicsComponent == nil or self.carryingPlayer.graphicsComponent.model == nil) then
		Logging.error("Invalid player configuration or tool is not held, cannot equip hand tool")
		return false
	end
	if self.rootNode == nil then
		return false
	end
	local v154_ = self.carryingPlayer.graphicsComponent.model
	if self.handNode ~= nil then
		local v155_ = v154_.thirdPersonRightHandNode
		if self.useLeftHand then
			v155_ = v154_.thirdPersonLeftHandNode
		end
		HandToolUtil.linkAndTransformRelativeToParent(self.rootNode, self.handNode, v155_)
		return true
	end
	Logging.warning("Handtool %s is missing hand node, using no offset!", self.typeName)
	link(v154_.thirdPersonRightHandNode, self.rootNode)
	setTranslation(self.rootNode, 0, 0, 0)
	setRotation(self.rootNode, 0, 0, 0)
	return false
end

function HandTool:attachToolToCamera()
	if self:getIsHeld() and self.rootNode ~= nil then
		if self.firstPersonNode == nil then
			Logging.warning("Handtool %s is missing first person node, using no offset!", self.typeName)
			link(self:getCarryingPlayer().camera.pitchNode, self.rootNode)
			setTranslation(self.rootNode, 0, 0, 0)
			setRotation(self.rootNode, 0, 0, 0)
		else
			HandToolUtil.linkAndTransformRelativeToParent(self.rootNode, self.firstPersonNode, self:getCarryingPlayer().camera.pitchNode)
		end
	else
		return
	end
end

function HandTool:attachToolToCharacter() end

function HandTool:registerActionEvents()
	g_inputBinding:beginActionEventsModification(PlayerInputComponent.INPUT_CONTEXT_NAME)
	SpecializationUtil.raiseEvent(self, "onRegisterActionEvents")
	g_inputBinding:endActionEventsModification()
end

-- Local values: inputAction, actionEvent
function HandTool:clearActionEvents(clearCarriedActionEvents)
	g_inputBinding:beginActionEventsModification(PlayerInputComponent.INPUT_CONTEXT_NAME)
	for v159_, v160_ in pairs(self.actionEvents) do
		g_inputBinding:removeActionEvent(v160_.actionEventId)
		self.actionEvents[v159_] = nil
	end
	g_inputBinding:endActionEventsModification()
end

-- Local values: actionEvents, state, actionEventId, otherEvent
function HandTool:addActionEvent(inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, reportAnyDeviceCollision)
	local v172_ = self.actionEvents
	if v172_[inputAction] == nil then
		local v173_, v174_, v175_ = g_inputBinding:registerActionEvent(inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, true, reportAnyDeviceCollision)
		if v173_ then
			v172_[inputAction] = {
				["actionEventId"] = v174_,
				["inputAction"] = inputAction
			}
			if not string.isNilOrWhitespace(customIconName) then
				g_inputBinding:setActionEventIcon(v174_, customIconName)
			end
		end
		return v173_, v174_, v175_
	end
	Logging.warning("Tried to bind two actions to input %s on tool %s!", inputAction, self.typeName)
end

-- Local values: uiScale, width, height, crosshairFilename, crosshair
function HandTool:createCrosshairOverlayFromFile(filename, sizePixels)
	local v179_ = sizePixels or HandTool.DEFAULT_CROSSHAIR_SIZE_PIXELS
	local v180_ = g_gameSettings:getValue("uiScale")
	local v181_, v182_ = getNormalizedScreenValues(v179_ * v180_, v179_ * v180_)
	local v183_ = Utils.getFilename(filename, self.baseDirectory)
	local v184_ = Overlay.new(v183_, 0.5, 0.5, v181_, v182_)
	v184_:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_CENTER)
	v184_:setColor(HandTool.DEFAULT_CROSSHAIR_COLOR:unpack())
	return v184_
end

-- Local values: uiScale, width, height, crosshair
function HandTool:createCrosshairOverlay(identifier, sizePixels)
	local v187_ = sizePixels or HandTool.DEFAULT_CROSSHAIR_SIZE_PIXELS
	local v188_ = g_gameSettings:getValue("uiScale")
	local v189_, v190_ = getNormalizedScreenValues(v187_ * v188_, v187_ * v188_)
	local v191_ = g_overlayManager:createOverlay(identifier, 0.5, 0.5, v189_, v190_)
	if v191_ == nil then
		return nil
	end
	v191_:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_CENTER)
	v191_:setColor(HandTool.DEFAULT_CROSSHAIR_COLOR:unpack())
	return v191_
end

-- Local values: _, spec, rootParentNode, rootNodePositionX, rootNodePositionY, rootNodePositionZ, rootParentPositionX, rootParentPositionY, rootParentPositionZ
function HandTool:debugDraw(x, y, textSize)
	for _, v196_ in ipairs(self.eventListeners.onDebugDraw) do
		y = v196_.onDebugDraw(self, x, y, textSize) or y
	end
	if self.rootNode ~= nil then
		local v197_ = getParent(self.rootNode)
		local v198_, v199_, v200_ = getWorldTranslation(self.rootNode)
		if v197_ ~= nil and entityExists(v197_) then
			local v201_, v202_, v203_ = getWorldTranslation(v197_)
			DebugLine.renderBetweenPositions(v198_, v199_, v200_, v201_, v202_, v203_, Color.PRESETS.GREEN, false, "Tool>Parent")
			DebugUtil.drawDebugNode(v197_, "root parent")
		end
		DebugUtil.drawDebugNode(self.rootNode, "root")
		if self.handNode ~= nil then
			DebugUtil.drawDebugNode(self.handNode, "hand")
			return y
		end
		if self.firstPersonNode ~= nil then
			DebugUtil.drawDebugNode(self.firstPersonNode, "fps")
		end
	end
	return y
end
