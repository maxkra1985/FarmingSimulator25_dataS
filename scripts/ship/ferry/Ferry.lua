Ferry = {}
Ferry.ERROR_SUCCESS = 0
Ferry.ERROR_FAILED_ALREADY_MOVING = 1
Ferry.ERROR_FAILED_BLOCKED = 2
Ferry.ERROR_FAILED_BARRIERS_BLOCKED = 3
Ferry.ERROR_SEND_NUM_BITS = 2
local Ferry_mt = Class(Ferry, Object)
InitStaticObjectClass(Ferry, "Ferry")
g_xmlManager:addCreateSchemaFunction(function()
	Ferry.xmlSchema = XMLSchema.new("ferry")
end)
g_xmlManager:addInitSchemaFunction(function()
	local schema = Ferry.xmlSchema
	schema:register(XMLValueType.STRING, "ferry.annotation", "Copyright annotation")
	schema:register(XMLValueType.NODE_INDEX, "ferry.vessel#node", "The visuals of the vessel")
	schema:register(XMLValueType.FLOAT, "ferry.vessel#speedKmh", "The vessel speed in kmh")
	schema:register(XMLValueType.NODE_INDEX, "ferry.vessel.trigger#node", "The mount trigger for objects")
	schema:register(XMLValueType.VECTOR_3, "ferry.vessel.shallowWaterObstacle#size", "obstacle size (x y z) centered on vessel node")
	SoundManager.registerSampleXMLPaths(schema, "ferry.vessel.sounds", "start")
	SoundManager.registerSampleXMLPaths(schema, "ferry.vessel.sounds", "stop")
	SoundManager.registerSampleXMLPaths(schema, "ferry.vessel.sounds", "driving")
	EffectManager.registerEffectXMLPaths(schema, "ferry.vessel.exhaustEffects")
	schema:register(XMLValueType.NODE_INDEX, "ferry.spline#node", "The spline node")
	schema:register(XMLValueType.NODE_INDEX, "ferry.spline.crossing(?)#node", "A spline crossing node")
	schema:register(XMLValueType.NODE_INDEX, "ferry.activationTriggers.activationTrigger(?)#node", "An activation trigger")
	schema:register(XMLValueType.NODE_INDEX, "ferry.barrierTriggers.barrierTrigger(?)#node", "A barrier trigger")
	AnimatedObject.registerXMLPaths(schema, "ferry.animatedObjects")
	schema:register(XMLValueType.STRING, "ferry.stateMachine.states.state(?)#name", "State name")
	schema:register(XMLValueType.STRING, "ferry.stateMachine.states.state(?)#class", "State class")
	FerryState.registerXMLPaths(schema, "ferry.stateMachine.states.state(?)")
	FerryStateDriving.registerXMLPaths(schema, "ferry.stateMachine.states.state(?)")
	schema:register(XMLValueType.STRING, "ferry.stateMachine.transitions.transition(?)#from", "State name from")
	schema:register(XMLValueType.STRING, "ferry.stateMachine.transitions.transition(?)#to", "State name to")
	local savegameSchema = OnCreateObjectSystem.xmlSchemaSavegame
	local savegameKey = "onCreateLoadedObjects.object(?).ferry"
	savegameSchema:register(XMLValueType.BOOL, "onCreateLoadedObjects.object(?).ferry" .. "#isMounted")
	savegameSchema:register(XMLValueType.FLOAT, "onCreateLoadedObjects.object(?).ferry" .. "#time")
	savegameSchema:register(XMLValueType.STRING, "onCreateLoadedObjects.object(?).ferry" .. "#state")
	savegameSchema:register(XMLValueType.STRING, "onCreateLoadedObjects.object(?).ferry" .. ".vehicle(?)#uniqueId")
	savegameSchema:register(XMLValueType.INT, "onCreateLoadedObjects.object(?).ferry" .. ".splitShape(?)#splitShapePart1")
	savegameSchema:register(XMLValueType.INT, "onCreateLoadedObjects.object(?).ferry" .. ".splitShape(?)#splitShapePart2")
	savegameSchema:register(XMLValueType.INT, "onCreateLoadedObjects.object(?).ferry" .. ".splitShape(?)#splitShapePart3")
	savegameSchema:register(XMLValueType.INT, "onCreateLoadedObjects.object(?).ferry" .. ".animatedObject(?)#index")
	AnimatedObject.registerSavegameXMLPaths(savegameSchema, "onCreateLoadedObjects.object(?).ferry" .. ".animatedObject(?)")
end)
function Ferry:onCreate(node)
	local xmlFilename = getUserAttribute(node, "xmlFilename")
	if xmlFilename == nil then
		Logging.warning("Missing 'xmlFilename' user attribute for ferry root node '%s'", getName(node))
		return
	end
	local ferry = Ferry.new(g_server ~= nil, g_client ~= nil, node)
	if ferry:load(xmlFilename, g_currentMission.baseDirectory) then
		g_currentMission.onCreateObjectSystem:add(ferry, true)
		ferry:register(true)
	else
		ferry:delete()
	end
end
function Ferry.new(isServer, isClient, node, customMt)
	local self = Object.new(isServer, isClient, customMt or Ferry_mt)
	self.rootNode = node
	self.saveId = getName(node)
	self.animatedObjects = {}
	self.isMounted = false
	self.nodesInBarrierTrigger = {}
	self.stateMachineNextIndex = 0
	self.stateIndex = nil
	self.state = {}
	self.stateMachine = {}
	self.stateTransitions = {}
	self.lastSpeed = 0
	self.mountedNodes = {}
	self.nodesInTrigger = {}
	return self
end
function Ferry:load(xmlFilename, baseDirectory)
	xmlFilename = Utils.getFilename(xmlFilename, baseDirectory)
	local xmlFile = XMLFile.load("ferry", xmlFilename, Ferry.xmlSchema)
	if xmlFile == nil then
		Logging.warning("Could not open ferry config file '%s'", xmlFilename)
		return false
	end
	self.veselNode = xmlFile:getValue("ferry.vessel#node", nil, self.rootNode, nil)
	self.triggerNode = xmlFile:getValue("ferry.vessel.trigger#node", nil, self.rootNode, nil)
	if self.triggerNode == nil then
		Logging.xmlWarning(xmlFile, "Missing trigger node")
		xmlFile:delete()
		return false
	end
	if not getHasTrigger(self.triggerNode) then
		Logging.xmlWarning(xmlFile, "Trigger node '%s' has no trigger flag set", getName(self.triggerNode))
		xmlFile:delete()
		return false
	end
	self.triggerCallbackId = addTrigger(self.triggerNode, "onObjectCallback", self, false, self.onObjectCallback)
	self.swsObstacleSize = xmlFile:getValue("ferry.vessel.shallowWaterObstacle#size", nil, true)
	self.activationTriggers = {}
	for _, triggerKey in xmlFile:iterator("ferry.activationTriggers.activationTrigger") do
		local activationTrigger = xmlFile:getValue(triggerKey .. "#node", nil, self.rootNode, nil)
		if activationTrigger == nil then
			Logging.xmlWarning(xmlFile, "Invalid activation trigger node in '%s'", triggerKey)
		elseif not getHasTrigger(activationTrigger) then
			Logging.xmlWarning(xmlFile, "Activationtrigger node '%s' has no trigger flag set in '%s'", getName(activationTrigger), triggerKey)
		else
			local callbackId = addTrigger(activationTrigger, "onActivationTriggerCallback", self, false, self.onActivationTriggerCallback)
			table.insert(self.activationTriggers, { node = activationTrigger, callbackId = callbackId })
		end
	end
	self.barrierTriggers = {}
	for _, triggerKey in xmlFile:iterator("ferry.barrierTriggers.barrierTrigger") do
		local barrierTrigger = xmlFile:getValue(triggerKey .. "#node", nil, self.rootNode, nil)
		if barrierTrigger == nil then
			Logging.xmlWarning(xmlFile, "Invalid barrier trigger node in '%s'", triggerKey)
		elseif not getHasTrigger(barrierTrigger) then
			Logging.xmlWarning(xmlFile, "Barrier Trigger node '%s' has no trigger flag set in '%s'", getName(barrierTrigger), triggerKey)
		else
			local callbackId = addTrigger(barrierTrigger, "onBarrierTriggerCallback", self, false, self.onBarrierTriggerCallback)
			table.insert(self.barrierTriggers, { node = barrierTrigger, callbackId = callbackId })
		end
	end
	for _, animObjectKey in xmlFile:iterator("ferry.animatedObjects.animatedObject") do
		local animatedObject = AnimatedObject.new(self.isServer, self.isClient)
		animatedObject:setOwnerFarmId(self:getOwnerFarmId(), false)
		if animatedObject:load(self.rootNode, xmlFile, animObjectKey, xmlFilename, nil) then
			table.insert(self.animatedObjects, animatedObject)
		else
			Logging.xmlError(xmlFile, "Failed to load animated object '%s'", animObjectKey)
		end
	end
	if self.isClient then
		self.samples = {}
		self.samples.driving = g_soundManager:loadSampleFromXML(xmlFile, "ferry.vessel.sounds", "driving", baseDirectory, self.rootNode, 0, AudioGroup.VEHICLE, nil, self)
		self.samples.start = g_soundManager:loadSampleFromXML(xmlFile, "ferry.vessel.sounds", "start", baseDirectory, self.rootNode, 1, AudioGroup.VEHICLE, nil, self)
		self.samples.stop = g_soundManager:loadSampleFromXML(xmlFile, "ferry.vessel.sounds", "stop", baseDirectory, self.rootNode, 1, AudioGroup.VEHICLE, nil, self)
		self.exhaustEffects = g_effectManager:loadEffect(xmlFile, "ferry.vessel.exhaustEffects", self.rootNode, self, nil)
	end
	local maxNumStates = 255
	for _, stateKey in xmlFile:iterator("ferry.stateMachine.states.state") do
		if maxNumStates < self.stateMachineNextIndex then
			Logging.xmlError(xmlFile, "Maximum number of states reached (%d)", 255)
			return false
		end
		local stateName = string.upper(xmlFile:getValue(stateKey .. "#name", ""))
		if self.state[stateName] ~= nil then
			Logging.xmlError(xmlFile, "State '%s' at '%s' already defined", stateName, stateKey)
			return false
		end
		local stateClassName = xmlFile:getValue(stateKey .. "#class", "")
		local class = ClassUtil.getClassObject(stateClassName)
		if class == nil then
			Logging.xmlError(xmlFile, "State class '%s' not defined for '%s'", stateClassName, stateKey)
			return false
		end
		local state = class.new(self)
		state.name = stateName
		if not state:load(xmlFile, stateKey) then
			Logging.xmlError(xmlFile, "State '%s' could not be loaded for '%s'", stateName, stateKey)
			return false
		end
		local stateIndex = self.stateMachineNextIndex
		self.state[stateName] = stateIndex
		self.stateMachine[stateIndex] = state
		self.stateMachineNextIndex = self.stateMachineNextIndex + 1
		if self.stateIndex == nil then
			self.stateIndex = stateIndex
		end
	end
	for _, transitionKey in xmlFile:iterator("ferry.stateMachine.transitions.transition") do
		local stateFromName = string.upper(xmlFile:getValue(transitionKey .. "#from", ""))
		local stateFromIndex = self.state[stateFromName]
		if stateFromIndex == nil then
			Logging.xmlError(xmlFile, "Invalid state. Transition from name '%s' not defined for '%s'", stateFromName, transitionKey)
			return false
		end
		local stateToName = string.upper(xmlFile:getValue(transitionKey .. "#to", ""))
		local stateToIndex = self.state[stateToName]
		if stateToIndex == nil then
			Logging.xmlError(xmlFile, "Invalid state. Transition to name '%s' not defined for '%s'", stateToName, transitionKey)
			return false
		end
		self.stateTransitions[stateFromIndex] = stateToIndex
	end
	self.splineNode = xmlFile:getValue("ferry.spline#node", nil, self.rootNode, nil)
	if self.splineNode == nil then
		Logging.xmlWarning(xmlFile, "Missing spline node for ferry")
		xmlFile:delete()
		return false
	else
		self.crossingNodes = {}
		for _, crossingKey in xmlFile:iterator("ferry.spline.crossing") do
			local crossingNode = xmlFile:getValue(crossingKey .. "#node", nil, self.rootNode, nil)
			if crossingNode == nil then
				continue
			end
			table.insert(self.crossingNodes, crossingNode)
			g_currentMission.shipSystem:addCrossingNode(self, crossingNode)
		end
		local maxSpeedMps = MathUtil.kmhToMps(xmlFile:getValue("ferry.vessel#speedKmh", 5))
		local splineLength = getSplineLength(self.splineNode)
		self.durationMs = splineLength / maxSpeedMps * 1000
		self.deltaSplineTimePerMs = 1 / self.durationMs
		self.splineLength = splineLength
		self.lastSplineTime = 0
		self.currentSplineTime = 0
		self.currentSplineTimeSent = 0
		self.updateThreshold = 0
		self.isMoving = false
		if self.isServer then
			self.dirtyFlag = self:getNextDirtyFlag()
			self.updateThreshold = 0.05 / splineLength
		else
			self.networkTimeInterpolator = InterpolationTime.new(1.2)
			self.networkSplineTimeInterpolator = InterpolatorSplineTime.new(0, false)
		end
		self.activatable = FerryActivatable.new(self)
		for _, animatedObject in ipairs(self.animatedObjects) do
			animatedObject:register(true)
		end
		g_currentMission.shipSystem:addSpline(self.splineNode, self)
		xmlFile:delete()
		self.nodes = {}
		I3DUtil.iterateRecursively(self.rootNode, function(node, _)
			if getRigidBodyType(node) ~= RigidBodyType.NONE then
				self.nodes[node] = true
			end
		end)
		self.mapHotspot = FerryHotspot.new(self)
		g_currentMission:addMapHotspot(self.mapHotspot)
		return true
	end
end
function Ferry:delete()
	g_currentMission.onCreateObjectSystem:remove(self)
	g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
	g_currentMission.shipSystem:removeSpline(self.splineNode, self)
	if self.crossingNodes ~= nil then
		for _, crossingNode in ipairs(self.crossingNodes) do
			g_currentMission.shipSystem:removeCrossingNode(self, crossingNode)
		end
	end
	if self.activationTriggers ~= nil then
		for _, trigger in ipairs(self.activationTriggers) do
			removeTrigger(trigger.node, trigger.callbackId)
		end
	end
	if self.barrierTriggers ~= nil then
		for _, trigger in ipairs(self.barrierTriggers) do
			removeTrigger(trigger.node, trigger.callbackId)
		end
	end
	if self.triggerCallbackId ~= nil then
		removeTrigger(self.triggerNode, self.triggerCallbackId)
	end
	if self.animatedObjects ~= nil then
		for _, animatedObject in ipairs(self.animatedObjects) do
			animatedObject:delete()
		end
		self.animatedObjects = nil
	end
	if self.samples ~= nil then
		g_soundManager:deleteSamples(self.samples)
	end
	if self.exhaustEffects ~= nil then
		g_effectManager:deleteEffects(self.exhaustEffects)
	end
	if self.mapHotspot ~= nil then
		g_currentMission:removeMapHotspot(self.mapHotspot)
		self.mapHotspot:delete()
	end
	Ferry:superClass().delete(self)
end
function Ferry:readStream(streamId, connection, objectId)
	if connection:getIsServer() then
		local stateIndex = streamReadUInt8(streamId)
		self:setState(stateIndex)
		self.currentSplineTime = streamReadFloat32(streamId)
		self.networkSplineTimeInterpolator:setValue(self.currentSplineTime)
		self.networkTimeInterpolator:reset()
		for _, animatedObject in ipairs(self.animatedObjects) do
			local animatedObjectId = NetworkUtil.readNodeObjectId(streamId)
			animatedObject:readStream(streamId, connection)
			g_client:finishRegisterObject(animatedObject, animatedObjectId)
		end
	end
end
function Ferry:writeStream(streamId, connection)
	if not connection:getIsServer() then
		streamWriteUInt8(streamId, self.stateIndex)
		streamWriteFloat32(streamId, self.currentSplineTimeSent)
		for _, animatedObject in ipairs(self.animatedObjects) do
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(animatedObject))
			animatedObject:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, animatedObject)
		end
	end
end
function Ferry:readUpdateStream(streamId, timestamp, connection)
	Ferry:superClass().readUpdateStream(self, streamId, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		local time = streamReadFloat32(streamId)
		self.networkSplineTimeInterpolator:setTargetValue(time)
		self.networkTimeInterpolator:startNewPhaseNetwork()
	end
end
function Ferry:writeUpdateStream(streamId, connection, dirtyMask)
	Ferry:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	if not connection:getIsServer() and streamWriteBool(streamId, bit32.band(dirtyMask, self.dirtyFlag) ~= 0) then
		streamWriteFloat32(streamId, self.currentSplineTimeSent)
	end
end
function Ferry:loadFromXMLFile(xmlFile, key)
	key = key .. ".ferry"
	self.isMounted = xmlFile:getValue(key .. "#isMounted", self.isMounted)
	local time = xmlFile:getValue(key .. "#time")
	if time ~= nil then
		self.currentSplineTime = time
		self.currentSplineTimeSent = time
		removeFromPhysics(self.veselNode)
		self:updatePosition()
		addToPhysics(self.veselNode)
	end
	local stateName = xmlFile:getValue(key .. "#state")
	if stateName ~= nil then
		local stateIndex = self.state[stateName]
		if stateIndex ~= nil then
			self:setState(stateIndex)
		end
	end
	for _, animKey in xmlFile:iterator(key .. ".animatedObject") do
		local index = xmlFile:getValue(animKey .. "#index")
		local animatedObject = self.animatedObjects[index]
		if animatedObject == nil then
			continue
		end
		animatedObject:loadFromXMLFile(xmlFile, animKey)
	end
	if self.isMounted then
		self.mountingPending = true
	end
	return true
end
function Ferry:saveToXMLFile(xmlFile, key, usedModNames)
	key = key .. ".ferry"
	xmlFile:setValue(key .. "#isMounted", self.isMounted)
	xmlFile:setValue(key .. "#time", self:getSplineTime())
	local state = self:getState()
	xmlFile:setValue(key .. "#state", state.name)
	for k, animObject in ipairs(self.animatedObjects) do
		local animKey = string.format("%s.animatedObject(%d)", key, k - 1)
		xmlFile:setValue(animKey .. "#index", k)
		animObject:saveToXMLFile(xmlFile, animKey)
	end
	local splitIndex = 0
	local vehicleIndex = 0
	for node, _ in pairs(self.mountedNodes) do
		if entityExists(node) then
			local object = g_currentMission:getNodeObject(node)
			if object ~= nil then
				if object:isa(Vehicle) then
					local vehicleKey = string.format("%s.vehicle(%d)", key, vehicleIndex)
					xmlFile:setValue(vehicleKey .. "#uniqueId", object:getUniqueId())
					vehicleIndex = vehicleIndex + 1
				end
			elseif getHasClassId(node, ClassIds.MESH_SPLIT_SHAPE) then
				local splitShapePart1, splitShapePart2, splitShapePart3 = getSaveableSplitShapeId(node)
				if splitShapePart1 == 0 or splitShapePart1 == nil then
					continue
				end
				local treeKey = string.format("%s.splitShape(%d)", key, splitIndex)
				xmlFile:setValue(treeKey .. "#splitShapePart1", splitShapePart1)
				xmlFile:setValue(treeKey .. "#splitShapePart2", splitShapePart2)
				xmlFile:setValue(treeKey .. "#splitShapePart3", splitShapePart3)
				splitIndex = splitIndex + 1
			end
		end
	end
end
function Ferry:setOwnerFarmId(ownerFarmId, noEventSend)
	Ferry:superClass().setOwnerFarmId(self, ownerFarmId, noEventSend)
	for _, animatedObject in ipairs(self.animatedObjects) do
		animatedObject:setOwnerFarmId(ownerFarmId, true)
	end
end
function Ferry:update(dt)
	Ferry:superClass().update(self, dt)
	if self.mountingPending then
		self:mountObjects()
		self.mountingPending = false
	end
	local state = self.stateMachine[self.stateIndex]
	if self.isServer then
		if state:isDone() then
			local nextStateIndex = self.stateTransitions[self.stateIndex]
			self:setState(nextStateIndex)
			self:raiseActive()
		elseif state:raiseActive() then
			self:raiseActive()
		end
	end
	state:update(dt)
	if not self.isServer and self.isClient then
		self.networkTimeInterpolator:update(dt)
		local interpolationAlpha = self.networkTimeInterpolator:getAlpha()
		self.currentSplineTime = self.networkSplineTimeInterpolator:getInterpolatedValue(interpolationAlpha)
		if self.networkTimeInterpolator:isInterpolating() then
			self:raiseActive()
		end
	end
	if self.isClient then
		self:updatePosition(dt)
	end
end
function Ferry:getSplineTimeDeltaPerMs()
	return self.deltaSplineTimePerMs
end
function Ferry:getSplineTime()
	return self.currentSplineTime
end
function Ferry:addSplineTimeDelta(delta)
	if not self.isServer then
		return
	else
		self.currentSplineTime = math.clamp(self.currentSplineTime + delta, 0, 1)
		local isDirty = self.currentSplineTime == 0 or self.currentSplineTime == 1 or self.updateThreshold < math.abs(self.currentSplineTime - self.currentSplineTimeSent)
		if isDirty then
			self.currentSplineTimeSent = self.currentSplineTime
			self:raiseDirtyFlags(self.dirtyFlag)
		end
	end
end
function Ferry:setState(newState)
	if newState ~= self.stateIndex then
		if self.isServer then
			g_server:broadcastEvent(FerryStateEvent.new(self, newState), false)
		end
		local oldStateIndex = self.stateIndex
		self.stateIndex = newState
		local oldState = self.stateMachine[oldStateIndex]
		local state = self.stateMachine[newState]
		oldState:deactivate()
		state:activate()
	end
end
function Ferry:getState()
	return self.stateMachine[self.stateIndex]
end
function Ferry:onActivationTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if (onEnter or onLeave) and (g_localPlayer ~= nil and otherId == g_localPlayer.rootNode) then
		if onEnter then
			self.activatable:setTrigger(triggerId)
			g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
		else
			g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
		end
		self:raiseActive()
	end
end
function Ferry:onBarrierTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if onEnter then
		self.nodesInBarrierTrigger[otherId] = (self.nodesInBarrierTrigger[otherId] or 0) + 1
	else
		if onLeave then
			self.nodesInBarrierTrigger[otherId] = self.nodesInBarrierTrigger[otherId] - 1
			if self.nodesInBarrierTrigger[otherId] == 0 then
				self.nodesInBarrierTrigger[otherId] = nil
			end
		end
	end
end
function Ferry:onObjectCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if (onEnter or onLeave) and self:getIsNodeSupported(otherId) then
		if onEnter then
			self.nodesInTrigger[otherId] = true
			return
		end
		self.nodesInTrigger[otherId] = nil
	end
end
function Ferry:getWorldPosition()
	return getWorldTranslation(self.veselNode)
end
function Ferry:getWorldRotation()
	return getWorldRotation(self.veselNode)
end
function Ferry:getIsNodeSupported(node)
	if self.nodes[node] ~= nil then
		return false
	else
		return true
	end
end
function Ferry:updatePosition(dt)
	local time = self.currentSplineTime
	if dt ~= nil then
		local delta = math.abs(self.lastSplineTime - self.currentSplineTime)
		local distance = delta * self.splineLength
		self.lastSpeed = distance / dt * 1000
	end
	self.lastSplineTime = time
	time = Tween.CURVE.EASE_IN_OUT(time)
	local x, y, z = getSplinePosition(self.splineNode, time)
	local dirX, dirY, dirZ = getSplineDirection(self.splineNode, time)
	local lx, ly, lz = getWorldTranslation(self.veselNode)
	setWorldTranslation(self.veselNode, x, y, z)
	setWorldDirection(self.veselNode, dirX, dirY, dirZ, 0, 1, 0)
	if self.mapHotspot ~= nil then
		local _, yRot, _ = getWorldRotation(self.veselNode)
		self.mapHotspot:setWorldPosition(x, z)
		self.mapHotspot:setWorldRotation(yRot)
	end
	if self.isServer then
		local vx = x - lx
		local vy = y - ly
		local vz = z - lz
		local length = MathUtil.vector3Length(vx, vy, vz)
		if 0.0001 < length then
			for node, _ in pairs(self.nodesInTrigger) do
				local object = g_currentMission:getNodeObject(node)
				if object == nil or object.moveCCTExternal == nil then
					continue
				end
				local touchingNode = object:getTouchingNode()
				if touchingNode == 0 then
					continue
				end
				vy = math.min(vy, -0.01)
				object:moveCCTExternal(vx, vy, vz)
			end
		end
	end
end
function Ferry:getIsAllowedToDrive()
	local durationMs = self.durationMs
	for _, crossingNode in ipairs(self.crossingNodes) do
		if g_currentMission.shipSystem:getIsShipCrossingPoint(crossingNode, durationMs) then
			return false
		end
	end
	return true
end
function Ferry:getCanActivateDriving()
	local state = self:getState()
	return state:getCanFinishState()
end
function Ferry:start(connection)
	if not self.isServer then
		g_client:getServerConnection():sendEvent(FerryStartEvent.new(self))
		return
	end
	local canActivateDriving = self:getCanActivateDriving()
	if canActivateDriving then
		local found = false
		for nodeId, _ in pairs(self.nodesInBarrierTrigger) do
			if entityExists(nodeId) then
				found = true
			else
				self.nodesInBarrierTrigger[nodeId] = nil
			end
		end
		if found then
			if connection ~= nil then
				connection:sendEvent(FerryStartEvent.newToClient(self, Ferry.ERROR_FAILED_BARRIERS_BLOCKED))
			else
				self:onStartFailed(Ferry.ERROR_FAILED_BARRIERS_BLOCKED)
			end
		else
			local isAllowedToDrive = self:getIsAllowedToDrive()
			if isAllowedToDrive then
				self:raiseActive()
				if connection ~= nil then
					connection:sendEvent(FerryStartEvent.newToClient(self, Ferry.ERROR_SUCCESS))
				end
				local state = self:getState()
				state:finish()
				self:onStarted()
			elseif connection == nil then
				self:onStartFailed(Ferry.ERROR_FAILED_BLOCKED)
			else
				connection:sendEvent(FerryStartEvent.newToClient(self, Ferry.ERROR_FAILED_BLOCKED))
			end
		end
	elseif connection == nil then
		self:onStartFailed(Ferry.ERROR_FAILED_BLOCKED)
	else
		connection:sendEvent(FerryStartEvent.newToClient(self, Ferry.ERROR_FAILED_ALREADY_MOVING))
	end
end
function Ferry:onStarted()
	Logging.devInfo("Ferry:onStarted")
end
function Ferry:onStartFailed(errorCode)
	Logging.devInfo("Ferry:onStartFailed. Errorcode %d", errorCode)
	if errorCode == Ferry.ERROR_FAILED_BLOCKED then
		g_currentMission:showBlinkingWarning(g_i18n:getText("warning_ferryBlockedByOtherShips", self.customEnvironment), 2000)
	elseif errorCode == Ferry.ERROR_FAILED_BARRIERS_BLOCKED then
		g_currentMission:showBlinkingWarning(g_i18n:getText("warning_ferryBarriersBlocked", self.customEnvironment), 2000)
	else
		if errorCode == Ferry.ERROR_FAILED_ALREADY_MOVING then
			g_currentMission:showBlinkingWarning(g_i18n:getText("warning_ferryAlreadyMoving", self.customEnvironment), 2000)
		end
	end
end
function Ferry:mountObjects()
	Logging.devInfo("Ferry:mountObjects")
	self.isMounted = true
	if self.isServer then
		local anchor = self.triggerNode
		local alreadyMountedObjects = {}
		for node, _ in pairs(self.nodesInTrigger) do
			if not entityExists(node) then
				self.nodesInTrigger[node] = nil
			else
				local object = g_currentMission:getNodeObject(node)
				if object ~= nil then
					if alreadyMountedObjects[object] == nil and object.moveCCTExternal == nil then
						alreadyMountedObjects[object] = true
						if object.setDynamicMountType ~= nil then
							object:setDynamicMountType(MountableObject.MOUNT_TYPE_DYNAMIC)
						end
						local constr = JointConstructor.new()
						constr:setActors(anchor, node)
						constr:setJointTransforms(node, node)
						constr:setRotationLimit(0, 0, 0)
						constr:setRotationLimit(1, 0, 0)
						constr:setRotationLimit(2, 0, 0)
						constr:setTranslationLimit(0, true, 0, 0)
						constr:setTranslationLimit(1, true, 0, 0)
						constr:setTranslationLimit(2, true, 0, 0)
						self.mountedNodes[node] = constr:finalize()
					end
				elseif getHasClassId(node, ClassIds.MESH_SPLIT_SHAPE) then
					if getSplitType(node) == 0 then
						continue
					end
					if alreadyMountedObjects[node] == nil then
						alreadyMountedObjects[node] = true
					end
				end
			end
		end
	end
end
function Ferry:unmountObjects()
	Logging.devInfo("Ferry:unmountObjects")
	for node, jointIndex in pairs(self.mountedNodes) do
		if entityExists(node) then
			removeJoint(jointIndex)
			local object = g_currentMission:getNodeObject(node)
			if object == nil or object.setDynamicMountType == nil then
				continue
			end
			object:setDynamicMountType(MountableObject.MOUNT_TYPE_NONE)
		end
	end
	self.mountedNodes = {}
	self.isMounted = false
end
function Ferry:startMotor()
	if self.isClient then
		local samples = self.samples
		if not g_soundManager:getIsSamplePlaying(samples.driving) then
			g_soundManager:stopSample(samples.stop)
			g_soundManager:playSample(samples.start)
			g_soundManager:playSample(samples.driving, 0, samples.start)
		end
		g_effectManager:startEffects(self.exhaustEffects)
	end
	if self.swsObstacle == nil and self.swsObstacleSize ~= nil then
		self.swsObstacle = g_currentMission.shallowWaterSimulation:addObstacle(self.veselNode, self.swsObstacleSize[1], self.swsObstacleSize[2], self.swsObstacleSize[3], function()
			local speed = self.lastSpeed
			local dx, _, dz = localDirectionToWorld(self.veselNode, 0, 0, 1)
			local yRot = MathUtil.getYRotationFromDirection(dx, dz)
			dx = dx * speed + speed * MathUtil.randomFloat(-0.1, 0.1)
			dz = dz * speed + speed * MathUtil.randomFloat(-0.1, 0.1)
			return dx, dz, yRot
		end)
	end
end
function Ferry:stopMotor()
	if self.isClient then
		local samples = self.samples
		g_soundManager:stopSample(samples.driving)
		g_soundManager:stopSample(samples.start)
		if not g_soundManager:getIsSamplePlaying(samples.stop) then
			g_soundManager:playSample(samples.stop)
		end
		g_effectManager:stopEffects(self.exhaustEffects)
	end
	if self.swsObstacle ~= nil then
		g_currentMission.shallowWaterSimulation:removeObstacle(self.swsObstacle)
		self.swsObstacle = nil
	end
end
function Ferry:addDynamicMountedObject(object) end
function Ferry:removeDynamicMountedObject(object, isDeleting) end
