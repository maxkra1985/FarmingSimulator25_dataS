-- Local values: HandToolHolder_mt
HandToolHolder = {}
local HandToolHolder_mt = Class(HandToolHolder, Object)

function HandToolHolder.registerXMLPaths(schema, basePath)
	schema:setXMLSharedRegistration("HandToolHolder", basePath)
	schema:register(XMLValueType.STRING, basePath .. ".handToolHolder(?).holder#type", "The type of hand tool that this holder accepts")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".handToolHolder(?).holder#node", "The name of the node specifying the orientation of the held tool")
	schema:register(XMLValueType.STRING, basePath .. ".handToolHolder(?).holder#dummyFilename", "The filename of a dummy object that will be visible while player is in range")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".handToolHolder(?).clickBoxes.clickBox(?)#node", "The name of the clickbox node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".handToolHolder(?).trigger#node", "Player activation trigger")
	schema:register(XMLValueType.STRING, basePath .. ".handToolHolder(?).spawnedHandToolFilename", "The filepath of the hand tool that is spawned. If this is not nil, then only the spawned tool can be put into and taken out of this holder")
	schema:register(XMLValueType.L10N_STRING, basePath .. ".handToolHolder(?).actions#takeText", "The name of the localization string displayed when the player can take the tool")
	schema:register(XMLValueType.L10N_STRING, basePath .. ".handToolHolder(?).actions#storeText", "The name of the localization string displayed when the player can store a tool")
	schema:resetXMLSharedRegistration("HandToolHolder", basePath)
end

function HandToolHolder.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#uniqueId", nil, false)
end

-- Upvalues: HandToolHolder_mt
-- Local values: self
function HandToolHolder.new(parent, isServer, isClient, customMt)
	-- upvalues: (copy) HandToolHolder_mt
	local v10_ = Object.new(isServer, isClient, customMt or HandToolHolder_mt)
	v10_.parent = parent
	v10_.name = ""
	v10_.handTool = nil
	v10_.isPlayerInRange = false
	return v10_
end

-- Local values: dummyFilename, nodeIndex, clickBoxNodeKey, clickBox, spawnedHandToolFilename, data, takeText, storeText
function HandToolHolder:load(xmlFile, key, callback, callbackTarget, callbackArgs, components, i3dMappings, baseDirectory, customEnv)
	self.holderType = xmlFile:getValue(key .. ".holder#type", nil)
	self.holderNode = xmlFile:getValue(key .. ".holder#node", nil, components, i3dMappings)
	local v21_ = xmlFile:getValue(key .. ".holder#dummyFilename")
	if v21_ ~= nil then
		local v22_ = Utils.getFilename(v21_, baseDirectory)
		self.dummySharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(v22_, true, true, self.onDummyHandToolI3DLoaded, self, nil)
	end
	self.clickBoxes = {}
	for _, v23_ in xmlFile:iterator(key .. ".clickBoxes.clickBox") do
		local v24_ = xmlFile:getValue(v23_ .. "#node", nil, components, i3dMappings)
		if v24_ ~= nil then
			local v25_ = self.clickBoxes
			table.insert(v25_, v24_)
		end
	end
	self.activationTrigger = xmlFile:getValue(key .. ".trigger#node", nil, components, i3dMappings)
	if self.activationTrigger then
		addTrigger(self.activationTrigger, "onPlayerCallback", self)
	end
	self.callback = callback
	self.callbackTarget = callbackTarget
	self.callbackArgs = callbackArgs
	local v26_ = xmlFile:getValue(key .. ".spawnedHandToolFilename")
	if v26_ ~= nil then
		local v27_ = Utils.getFilename(v26_, baseDirectory)
		self.spawnedHandToolFilename = v27_
		local v28_ = HandToolLoadingData.new()
		v28_:setFilename(v27_)
		v28_:setOwnerFarmId(self:getOwnerFarmId())
		v28_:setIsRegistered(false)
		v28_:load(self.onSpawnedHandToolLoaded, self)
		self.pendingHandToolData = v28_
		self.isHandToolPending = true
	end
	local v29_ = xmlFile:getValue(key .. ".actions#takeText", "action_takeHandTool", customEnv, true)
	local v30_ = xmlFile:getValue(key .. ".actions#storeText", "action_returnHandTool", customEnv, true)
	self.activatable = HandToolHolderActivatable.new(self, v29_, v30_, self.activationTrigger == nil)
	if not self.isHandToolPending then
		self:onFinishedLoading()
	end
end

function HandToolHolder:onDummyHandToolI3DLoaded(i3dNode, failedReason, args)
	if i3dNode ~= 0 then
		self.dummyHandTool = getChildAt(i3dNode, 0)
		link(self.holderNode, self.dummyHandTool)
		delete(i3dNode)
		self:updateDummyHandTool()
	end
end

function HandToolHolder:onSpawnedHandToolLoaded(handTool, loadingState)
	self.pendingHandToolData = nil
	if handTool == nil then
		Logging.error("Could not load spawned hand tool for HandToolHolder!")
		self.callback(self.callbackTarget, nil, self.callbackArgs)
	else
		self.spawnedHandTool = handTool
		handTool:setAttachedHolder(self)
		handTool:setHolder(self, true)
		if self.isRegistered then
			handTool:register(true)
		end
		if string.isNilOrWhitespace(self.spawnedHandToolFilename) then
			self.spawnedHandToolFilename = handTool.xmlFilename
		end
		self:onFinishedLoading()
	end
end

function HandToolHolder:onFinishedLoading()
	self.callback(self.callbackTarget, self, self.callbackArgs)
	g_currentMission.handToolSystem:addHandToolHolder(self)
	if self.activationTrigger == nil then
		g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
	end
end

-- Local values: handTool
function HandToolHolder:delete()
	local v37_ = self.handTool
	self.storeCallback = nil
	self.pickupCallback = nil
	if self.pendingHandToolData ~= nil then
		self.pendingHandToolData:cancelLoading()
		self.pendingHandToolData = nil
	end
	if v37_ ~= nil and v37_ ~= self.spawnedHandTool then
		v37_:setHolder(nil)
	end
	if self.spawnedHandTool ~= nil then
		self.spawnedHandTool:setHolder(nil, true)
		self.spawnedHandTool:delete()
	end
	if self.activationTrigger ~= nil then
		removeTrigger(self.activationTrigger)
		self.activationTrigger = nil
	end
	if self.dummySharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.dummySharedLoadRequestId)
		self.dummySharedLoadRequestId = nil
	end
	self.parent = nil
	g_currentMission.handToolSystem:removeHandToolHolder(self)
	g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
	HandToolHolder:superClass().delete(self)
end

function HandToolHolder:saveToXMLFile(xmlFile, key)
	xmlFile:setValue(key .. "#uniqueId", self.uniqueId)
end

-- Local values: uniqueId
function HandToolHolder:loadFromXMLFile(xmlFile, key)
	local v44_ = xmlFile:getValue(key .. "#uniqueId", nil)
	if v44_ ~= nil then
		self:setUniqueId(v44_)
	end
end

-- Local values: spawnedHandTool
function HandToolHolder:writeStream(streamId, connection)
	if not connection:getIsServer() then
		local v48_ = self.spawnedHandTool
		if streamWriteBool(streamId, v48_ ~= nil) then
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v48_))
			v48_:postWriteStream(streamId, connection)
			g_server:registerObjectInStream(connection, v48_)
		end
	end
end

-- Local values: spawnedHandTool, spawnedHandToolId
function HandToolHolder:readStream(streamId, connection, objectId)
	if connection:getIsServer() and streamReadBool(streamId) then
		local v52_ = self.spawnedHandTool
		local v53_ = NetworkUtil.readNodeObjectId(streamId)
		v52_:postReadStream(streamId, connection)
		g_client:finishRegisterObject(v52_, v53_)
	end
end

function HandToolHolder:register(alreadySent)
	HandToolHolder:superClass().register(self, alreadySent)
	if self.spawnedHandTool ~= nil and not self.spawnedHandTool.isRegistered then
		self.spawnedHandTool:register(true)
	end
end

function HandToolHolder:getUniqueId()
	return self.uniqueId
end

function HandToolHolder:setUniqueId(uniqueId)
	self.uniqueId = uniqueId
end

function HandToolHolder:getHolderName()
	return self.name
end

function HandToolHolder:setHolderName(name)
	self.name = name
end

function HandToolHolder:getHandTool()
	return self.handTool
end

function HandToolHolder:getSpawnedHandTool()
	return self.spawnedHandTool
end

function HandToolHolder:getSpawnsHandTool()
	return self.spawnedHandToolFilename ~= nil
end

-- Local values: handToolHolderNode
function HandToolHolder:getHolderNodePair(handTool)
	if handTool.getHolsterNodeByType == nil then
		return nil, nil
	else
		local v67_ = handTool:getHolsterNodeByType(self.holderType)
		if v67_ == nil then
			return nil, nil
		else
			return self.holderNode, v67_
		end
	end
end

function HandToolHolder:getCanPickupHandToolFromMenu(handTool)
	return true
end

-- Local values: handToolHolderNode, handToolFarmId, holderFarmId, sameFarm
function HandToolHolder:getCanPickupHandTool(handTool)
	if self.handTool ~= nil then
		return false
	end
	if handTool == nil or handTool.spec_storable == nil then
		return false
	end
	if self:getSpawnsHandTool() then
		return self:getSpawnedHandTool() == handTool
	end
	local v70_ = handTool:getHolsterNodeByType(self.holderType)
	local v71_ = handTool:getOwnerFarmId() == self:getOwnerFarmId()
	if v70_ == nil then
		v71_ = false
	end
	return v71_
end

-- Local values: holderNode, handToolHolderNode
function HandToolHolder:onPickupHandTool(handTool)
	if handTool == nil then
		return false
	end
	if not self:getCanPickupHandTool(handTool) then
		return false
	end
	local v74_, v75_ = self:getHolderNodePair(handTool)
	if v74_ == nil or v75_ == nil then
		return false
	end
	self.handTool = handTool
	if self.storeCallback ~= nil then
		self.storeCallback(handTool)
	end
	HandToolUtil.linkAndTransformRelativeToParent(handTool.rootNode, v75_, v74_)
	if handTool.graphicalNode ~= handTool.rootNode then
		setTranslation(handTool.graphicalNode, 0, 0, 0)
		setRotation(handTool.graphicalNode, 0, 0, 0)
	end
	self:updateDummyHandTool()
	return true
end

function HandToolHolder:setPlayerInRange(isInRange)
	self.isPlayerInRange = isInRange
	self:updateDummyHandTool()
end

-- Local values: isVisible
function HandToolHolder:updateDummyHandTool()
	if self.dummyHandTool ~= nil then
		local v79_ = self.isPlayerInRange
		if v79_ then
			v79_ = self.handTool == nil
		end
		setVisibility(self.dummyHandTool, v79_)
	end
end

function HandToolHolder:onDropHandTool(handTool)
	if handTool ~= nil and handTool == self.handTool then
		unlink(handTool.rootNode)
		self.handTool = nil
		if self.pickupCallback ~= nil then
			self.pickupCallback(handTool)
		end
		self:updateDummyHandTool()
		return handTool
	end
end

-- Local values: holderNode, toolNode
function HandToolHolder:drawDebug()
	if self.handTool == nil then
		DebugGizmo.renderAtNode(self.holderNode)
	else
		local v83_, v84_ = self:getHolderNodePair(self:getHandTool())
		DebugGizmo.renderAtNode(v83_)
		DebugGizmo.renderAtNode(v84_)
	end
end

function HandToolHolder:setOwnerFarmId(farmId, noEventSend)
	HandToolHolder:superClass().setOwnerFarmId(self, farmId, noEventSend)
	if self.spawnedHandTool ~= nil then
		self.spawnedHandTool:setOwnerFarmId(farmId, true)
	end
end

function HandToolHolder:setStoreCallback(storeCallback)
	self.storeCallback = storeCallback
end

function HandToolHolder:setPickupCallback(pickupCallback)
	self.pickupCallback = pickupCallback
end

function HandToolHolder:onPlayerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if (onEnter or onLeave) and (g_localPlayer ~= nil and otherId == g_localPlayer.rootNode) then
		if onEnter then
			g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
			self:setPlayerInRange(true)
			return
		end
		g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
		self:setPlayerInRange(false)
	end
end
