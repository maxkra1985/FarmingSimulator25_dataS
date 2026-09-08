-- Local values: Ferry_mt
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
	local v2_ = Ferry.xmlSchema
	v2_:register(XMLValueType.STRING, "ferry.annotation", "Copyright annotation")
	v2_:register(XMLValueType.NODE_INDEX, "ferry.vessel#node", "The visuals of the vessel")
	v2_:register(XMLValueType.FLOAT, "ferry.vessel#speedKmh", "The vessel speed in kmh")
	v2_:register(XMLValueType.NODE_INDEX, "ferry.vessel.trigger#node", "The mount trigger for objects")
	v2_:register(XMLValueType.VECTOR_3, "ferry.vessel.shallowWaterObstacle#size", "obstacle size (x y z) centered on vessel node")
	SoundManager.registerSampleXMLPaths(v2_, "ferry.vessel.sounds", "start")
	SoundManager.registerSampleXMLPaths(v2_, "ferry.vessel.sounds", "stop")
	SoundManager.registerSampleXMLPaths(v2_, "ferry.vessel.sounds", "driving")
	EffectManager.registerEffectXMLPaths(v2_, "ferry.vessel.exhaustEffects")
	v2_:register(XMLValueType.NODE_INDEX, "ferry.spline#node", "The spline node")
	v2_:register(XMLValueType.NODE_INDEX, "ferry.spline.crossing(?)#node", "A spline crossing node")
	v2_:register(XMLValueType.NODE_INDEX, "ferry.activationTriggers.activationTrigger(?)#node", "An activation trigger")
	v2_:register(XMLValueType.NODE_INDEX, "ferry.barrierTriggers.barrierTrigger(?)#node", "A barrier trigger")
	AnimatedObject.registerXMLPaths(v2_, "ferry.animatedObjects")
	v2_:register(XMLValueType.STRING, "ferry.stateMachine.states.state(?)#name", "State name")
	v2_:register(XMLValueType.STRING, "ferry.stateMachine.states.state(?)#class", "State class")
	FerryState.registerXMLPaths(v2_, "ferry.stateMachine.states.state(?)")
	FerryStateDriving.registerXMLPaths(v2_, "ferry.stateMachine.states.state(?)")
	v2_:register(XMLValueType.STRING, "ferry.stateMachine.transitions.transition(?)#from", "State name from")
	v2_:register(XMLValueType.STRING, "ferry.stateMachine.transitions.transition(?)#to", "State name to")
	local v3_ = OnCreateObjectSystem.xmlSchemaSavegame
	v3_:register(XMLValueType.BOOL, "onCreateLoadedObjects.object(?).ferry#isMounted")
	v3_:register(XMLValueType.FLOAT, "onCreateLoadedObjects.object(?).ferry#time")
	v3_:register(XMLValueType.STRING, "onCreateLoadedObjects.object(?).ferry#state")
	v3_:register(XMLValueType.STRING, "onCreateLoadedObjects.object(?).ferry.vehicle(?)#uniqueId")
	v3_:register(XMLValueType.INT, "onCreateLoadedObjects.object(?).ferry.splitShape(?)#splitShapePart1")
	v3_:register(XMLValueType.INT, "onCreateLoadedObjects.object(?).ferry.splitShape(?)#splitShapePart2")
	v3_:register(XMLValueType.INT, "onCreateLoadedObjects.object(?).ferry.splitShape(?)#splitShapePart3")
	v3_:register(XMLValueType.INT, "onCreateLoadedObjects.object(?).ferry.animatedObject(?)#index")
	AnimatedObject.registerSavegameXMLPaths(v3_, "onCreateLoadedObjects.object(?).ferry.animatedObject(?)")
end)

-- Local values: xmlFilename, ferry
function Ferry:onCreate(node)
	local v5_ = getUserAttribute(node, "xmlFilename")
	if v5_ == nil then
		Logging.warning("Missing \'xmlFilename\' user attribute for ferry root node \'%s\'", getName(node))
		return
	else
		local v6_ = Ferry.new(g_server ~= nil, g_client ~= nil, node)
		if v6_:load(v5_, g_currentMission.baseDirectory) then
			g_currentMission.onCreateObjectSystem:add(v6_, true)
			v6_:register(true)
		else
			v6_:delete()
		end
	end
end

-- Upvalues: Ferry_mt
-- Local values: self
function Ferry.new(isServer, isClient, node, customMt)
	-- upvalues: (copy) Ferry_mt
	local v11_ = Object.new(isServer, isClient, customMt or Ferry_mt)
	v11_.rootNode = node
	v11_.saveId = getName(node)
	v11_.animatedObjects = {}
	v11_.isMounted = false
	v11_.nodesInBarrierTrigger = {}
	v11_.stateMachineNextIndex = 0
	v11_.stateIndex = nil
	v11_.state = {}
	v11_.stateMachine = {}
	v11_.stateTransitions = {}
	v11_.lastSpeed = 0
	v11_.mountedNodes = {}
	v11_.nodesInTrigger = {}
	return v11_
end

-- Local values: xmlFile, _, triggerKey, activationTrigger, callbackId, _, triggerKey, barrierTrigger, callbackId, _, animObjectKey, animatedObject, maxNumStates, _, stateKey, stateName, stateClassName, class, state, stateIndex, _, transitionKey, stateFromName, stateFromIndex, stateToName, stateToIndex, _, crossingKey, crossingNode, maxSpeedMps, splineLength, _, animatedObject
function Ferry:load(xmlFilename, baseDirectory)
	local v15_ = Utils.getFilename(xmlFilename, baseDirectory)
	local v16_ = XMLFile.load("ferry", v15_, Ferry.xmlSchema)
	if v16_ == nil then
		Logging.warning("Could not open ferry config file \'%s\'", v15_)
		return false
	end
	self.veselNode = v16_:getValue("ferry.vessel#node", nil, self.rootNode, nil)
	self.triggerNode = v16_:getValue("ferry.vessel.trigger#node", nil, self.rootNode, nil)
	if self.triggerNode == nil then
		Logging.xmlWarning(v16_, "Missing trigger node")
		v16_:delete()
		return false
	end
	if not getHasTrigger(self.triggerNode) then
		Logging.xmlWarning(v16_, "Trigger node \'%s\' has no trigger flag set", getName(self.triggerNode))
		v16_:delete()
		return false
	end
	self.triggerCallbackId = addTrigger(self.triggerNode, "onObjectCallback", self, false, self.onObjectCallback)
	self.swsObstacleSize = v16_:getValue("ferry.vessel.shallowWaterObstacle#size", nil, true)
	self.activationTriggers = {}
	for _, v17_ in v16_:iterator("ferry.activationTriggers.activationTrigger") do
		local v18_ = v16_:getValue(v17_ .. "#node", nil, self.rootNode, nil)
		if v18_ == nil then
			Logging.xmlWarning(v16_, "Invalid activation trigger node in \'%s\'", v17_)
		elseif getHasTrigger(v18_) then
			local v19_ = addTrigger(v18_, "onActivationTriggerCallback", self, false, self.onActivationTriggerCallback)
			local v20_ = self.activationTriggers
			table.insert(v20_, {
				["node"] = v18_,
				["callbackId"] = v19_
			})
		else
			Logging.xmlWarning(v16_, "Activationtrigger node \'%s\' has no trigger flag set in \'%s\'", getName(v18_), v17_)
		end
	end
	self.barrierTriggers = {}
	for _, v21_ in v16_:iterator("ferry.barrierTriggers.barrierTrigger") do
		local v22_ = v16_:getValue(v21_ .. "#node", nil, self.rootNode, nil)
		if v22_ == nil then
			Logging.xmlWarning(v16_, "Invalid barrier trigger node in \'%s\'", v21_)
		elseif getHasTrigger(v22_) then
			local v23_ = addTrigger(v22_, "onBarrierTriggerCallback", self, false, self.onBarrierTriggerCallback)
			local v24_ = self.barrierTriggers
			table.insert(v24_, {
				["node"] = v22_,
				["callbackId"] = v23_
			})
		else
			Logging.xmlWarning(v16_, "Barrier Trigger node \'%s\' has no trigger flag set in \'%s\'", getName(v22_), v21_)
		end
	end
	for _, v25_ in v16_:iterator("ferry.animatedObjects.animatedObject") do
		local v26_ = AnimatedObject.new(self.isServer, self.isClient)
		v26_:setOwnerFarmId(self:getOwnerFarmId(), false)
		if v26_:load(self.rootNode, v16_, v25_, v15_, nil) then
			local v27_ = self.animatedObjects
			table.insert(v27_, v26_)
		else
			Logging.xmlError(v16_, "Failed to load animated object \'%s\'", v25_)
		end
	end
	if self.isClient then
		self.samples = {}
		self.samples.driving = g_soundManager:loadSampleFromXML(v16_, "ferry.vessel.sounds", "driving", baseDirectory, self.rootNode, 0, AudioGroup.VEHICLE, nil, self)
		self.samples.start = g_soundManager:loadSampleFromXML(v16_, "ferry.vessel.sounds", "start", baseDirectory, self.rootNode, 1, AudioGroup.VEHICLE, nil, self)
		self.samples.stop = g_soundManager:loadSampleFromXML(v16_, "ferry.vessel.sounds", "stop", baseDirectory, self.rootNode, 1, AudioGroup.VEHICLE, nil, self)
		self.exhaustEffects = g_effectManager:loadEffect(v16_, "ferry.vessel.exhaustEffects", self.rootNode, self, nil)
	end
	local v28_ = 255
	for _, v29_ in v16_:iterator("ferry.stateMachine.states.state") do
		if v28_ < self.stateMachineNextIndex then
			Logging.xmlError(v16_, "Maximum number of states reached (%d)", 255)
			return false
		end
		local v30_ = string.upper(v16_:getValue(v29_ .. "#name", ""))
		if self.state[v30_] ~= nil then
			Logging.xmlError(v16_, "State \'%s\' at \'%s\' already defined", v30_, v29_)
			return false
		end
		local v31_ = v16_:getValue(v29_ .. "#class", "")
		local v32_ = ClassUtil.getClassObject(v31_)
		if v32_ == nil then
			Logging.xmlError(v16_, "State class \'%s\' not defined for \'%s\'", v31_, v29_)
			return false
		end
		local v33_ = v32_.new(self)
		v33_.name = v30_
		if not v33_:load(v16_, v29_) then
			Logging.xmlError(v16_, "State \'%s\' could not be loaded for \'%s\'", v30_, v29_)
			return false
		end
		local v34_ = self.stateMachineNextIndex
		self.state[v30_] = v34_
		self.stateMachine[v34_] = v33_
		self.stateMachineNextIndex = self.stateMachineNextIndex + 1
		if self.stateIndex == nil then
			self.stateIndex = v34_
		end
	end
	for _, v35_ in v16_:iterator("ferry.stateMachine.transitions.transition") do
		local v36_ = string.upper(v16_:getValue(v35_ .. "#from", ""))
		local v37_ = self.state[v36_]
		if v37_ == nil then
			Logging.xmlError(v16_, "Invalid state. Transition from name \'%s\' not defined for \'%s\'", v36_, v35_)
			return false
		end
		local v38_ = string.upper(v16_:getValue(v35_ .. "#to", ""))
		local v39_ = self.state[v38_]
		if v39_ == nil then
			Logging.xmlError(v16_, "Invalid state. Transition to name \'%s\' not defined for \'%s\'", v38_, v35_)
			return false
		end
		self.stateTransitions[v37_] = v39_
	end
	self.splineNode = v16_:getValue("ferry.spline#node", nil, self.rootNode, nil)
	if self.splineNode == nil then
		Logging.xmlWarning(v16_, "Missing spline node for ferry")
		v16_:delete()
		return false
	end
	self.crossingNodes = {}
	for _, v40_ in v16_:iterator("ferry.spline.crossing") do
		local v41_ = v16_:getValue(v40_ .. "#node", nil, self.rootNode, nil)
		if v41_ ~= nil then
			local v42_ = self.crossingNodes
			table.insert(v42_, v41_)
			g_currentMission.shipSystem:addCrossingNode(self, v41_)
		end
	end
	local v43_ = MathUtil.kmhToMps(v16_:getValue("ferry.vessel#speedKmh", 5))
	local v44_ = getSplineLength(self.splineNode)
	self.durationMs = v44_ / v43_ * 1000
	self.deltaSplineTimePerMs = 1 / self.durationMs
	self.splineLength = v44_
	self.lastSplineTime = 0
	self.currentSplineTime = 0
	self.currentSplineTimeSent = 0
	self.updateThreshold = 0
	self.isMoving = false
	if self.isServer then
		self.dirtyFlag = self:getNextDirtyFlag()
		self.updateThreshold = 0.05 / v44_
	else
		self.networkTimeInterpolator = InterpolationTime.new(1.2)
		self.networkSplineTimeInterpolator = InterpolatorSplineTime.new(0, false)
	end
	self.activatable = FerryActivatable.new(self)
	for _, v45_ in ipairs(self.animatedObjects) do
		v45_:register(true)
	end
	g_currentMission.shipSystem:addSpline(self.splineNode, self)
	v16_:delete()
	self.nodes = {}
	I3DUtil.iterateRecursively(self.rootNode, function(p46_, _)
		-- upvalues: (copy) self
		if getRigidBodyType(p46_) ~= RigidBodyType.NONE then
			self.nodes[p46_] = true
		end
	end)
	self.mapHotspot = FerryHotspot.new(self)
	g_currentMission:addMapHotspot(self.mapHotspot)
	return true
end

-- Local values: _, crossingNode, _, trigger, _, trigger, _, animatedObject
function Ferry:delete()
	g_currentMission.onCreateObjectSystem:remove(self)
	g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
	g_currentMission.shipSystem:removeSpline(self.splineNode, self)
	if self.crossingNodes ~= nil then
		for _, v48_ in ipairs(self.crossingNodes) do
			g_currentMission.shipSystem:removeCrossingNode(self, v48_)
		end
	end
	if self.activationTriggers ~= nil then
		for _, v49_ in ipairs(self.activationTriggers) do
			removeTrigger(v49_.node, v49_.callbackId)
		end
	end
	if self.barrierTriggers ~= nil then
		for _, v50_ in ipairs(self.barrierTriggers) do
			removeTrigger(v50_.node, v50_.callbackId)
		end
	end
	if self.triggerCallbackId ~= nil then
		removeTrigger(self.triggerNode, self.triggerCallbackId)
	end
	if self.animatedObjects ~= nil then
		for _, v51_ in ipairs(self.animatedObjects) do
			v51_:delete()
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

-- Local values: stateIndex, _, animatedObject, animatedObjectId
function Ferry:readStream(streamId, connection, objectId)
	if connection:getIsServer() then
		self:setState((streamReadUInt8(streamId)))
		self.currentSplineTime = streamReadFloat32(streamId)
		self.networkSplineTimeInterpolator:setValue(self.currentSplineTime)
		self.networkTimeInterpolator:reset()
		for _, v55_ in ipairs(self.animatedObjects) do
			local v56_ = NetworkUtil.readNodeObjectId(streamId)
			v55_:readStream(streamId, connection)
			g_client:finishRegisterObject(v55_, v56_)
		end
	end
end

-- Local values: _, animatedObject
function Ferry:writeStream(streamId, connection)
	if not connection:getIsServer() then
		streamWriteUInt8(streamId, self.stateIndex)
		streamWriteFloat32(streamId, self.currentSplineTimeSent)
		for _, v60_ in ipairs(self.animatedObjects) do
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v60_))
			v60_:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, v60_)
		end
	end
end

-- Local values: time
function Ferry:readUpdateStream(streamId, timestamp, connection)
	Ferry:superClass().readUpdateStream(self, streamId, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		local v64_ = streamReadFloat32(streamId)
		self.networkSplineTimeInterpolator:setTargetValue(v64_)
		self.networkTimeInterpolator:startNewPhaseNetwork()
	end
end

function Ferry:writeUpdateStream(streamId, connection, dirtyMask)
	Ferry:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v69_ = streamWriteBool
		local v70_ = self.dirtyFlag
		if v69_(streamId, bit32.band(dirtyMask, v70_) ~= 0) then
			streamWriteFloat32(streamId, self.currentSplineTimeSent)
		end
	end
end

-- Local values: time, stateName, stateIndex, _, animKey, index, animatedObject
function Ferry:loadFromXMLFile(xmlFile, key)
	local v74_ = key .. ".ferry"
	self.isMounted = xmlFile:getValue(v74_ .. "#isMounted", self.isMounted)
	local v75_ = xmlFile:getValue(v74_ .. "#time")
	if v75_ ~= nil then
		self.currentSplineTime = v75_
		self.currentSplineTimeSent = v75_
		removeFromPhysics(self.veselNode)
		self:updatePosition()
		addToPhysics(self.veselNode)
	end
	local v76_ = xmlFile:getValue(v74_ .. "#state")
	if v76_ ~= nil then
		local v77_ = self.state[v76_]
		if v77_ ~= nil then
			self:setState(v77_)
		end
	end
	for _, v78_ in xmlFile:iterator(v74_ .. ".animatedObject") do
		local v79_ = xmlFile:getValue(v78_ .. "#index")
		local v80_ = self.animatedObjects[v79_]
		if v80_ ~= nil then
			v80_:loadFromXMLFile(xmlFile, v78_)
		end
	end
	if self.isMounted then
		self.mountingPending = true
	end
	return true
end

-- Local values: state, k, animObject, animKey, splitIndex, vehicleIndex, node, _, object, vehicleKey, splitShapePart1, splitShapePart2, splitShapePart3, treeKey
function Ferry:saveToXMLFile(xmlFile, key, usedModNames)
	local v84_ = key .. ".ferry"
	xmlFile:setValue(v84_ .. "#isMounted", self.isMounted)
	xmlFile:setValue(v84_ .. "#time", self:getSplineTime())
	local v85_ = self:getState()
	xmlFile:setValue(v84_ .. "#state", v85_.name)
	for v86_, v87_ in ipairs(self.animatedObjects) do
		local v88_ = string.format("%s.animatedObject(%d)", v84_, v86_ - 1)
		xmlFile:setValue(v88_ .. "#index", v86_)
		v87_:saveToXMLFile(xmlFile, v88_)
	end
	local v89_ = 0
	local v90_ = 0
	for v91_, _ in pairs(self.mountedNodes) do
		if entityExists(v91_) then
			local v92_ = g_currentMission:getNodeObject(v91_)
			if v92_ == nil then
				if getHasClassId(v91_, ClassIds.MESH_SPLIT_SHAPE) then
					local v93_, v94_, v95_ = getSaveableSplitShapeId(v91_)
					if v93_ ~= 0 and v93_ ~= nil then
						local v96_ = string.format("%s.splitShape(%d)", v84_, v89_)
						xmlFile:setValue(v96_ .. "#splitShapePart1", v93_)
						xmlFile:setValue(v96_ .. "#splitShapePart2", v94_)
						xmlFile:setValue(v96_ .. "#splitShapePart3", v95_)
						v89_ = v89_ + 1
					end
				end
			elseif v92_:isa(Vehicle) then
				xmlFile:setValue(string.format("%s.vehicle(%d)", v84_, v90_) .. "#uniqueId", v92_:getUniqueId())
				v90_ = v90_ + 1
			end
		end
	end
end

-- Local values: _, animatedObject
function Ferry:setOwnerFarmId(ownerFarmId, noEventSend)
	Ferry:superClass().setOwnerFarmId(self, ownerFarmId, noEventSend)
	for _, v100_ in ipairs(self.animatedObjects) do
		v100_:setOwnerFarmId(ownerFarmId, true)
	end
end

-- Local values: state, nextStateIndex, interpolationAlpha
function Ferry:update(dt)
	Ferry:superClass().update(self, dt)
	if self.mountingPending then
		self:mountObjects()
		self.mountingPending = false
	end
	local v103_ = self.stateMachine[self.stateIndex]
	if self.isServer then
		if v103_:isDone() then
			self:setState(self.stateTransitions[self.stateIndex])
			self:raiseActive()
		elseif v103_:raiseActive() then
			self:raiseActive()
		end
	end
	v103_:update(dt)
	if not self.isServer and self.isClient then
		self.networkTimeInterpolator:update(dt)
		local v104_ = self.networkTimeInterpolator:getAlpha()
		self.currentSplineTime = self.networkSplineTimeInterpolator:getInterpolatedValue(v104_)
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

-- Local values: isDirty
function Ferry:addSplineTimeDelta(delta)
	if self.isServer then
		local v109_ = self.currentSplineTime + delta
		self.currentSplineTime = math.clamp(v109_, 0, 1)
		local v110_
		if self.currentSplineTime == 0 or self.currentSplineTime == 1 then
			v110_ = true
		else
			local v111_ = self.currentSplineTime - self.currentSplineTimeSent
			v110_ = math.abs(v111_) > self.updateThreshold
		end
		if v110_ then
			self.currentSplineTimeSent = self.currentSplineTime
			self:raiseDirtyFlags(self.dirtyFlag)
		end
	end
end

-- Local values: oldStateIndex, oldState, state
function Ferry:setState(newState)
	if newState ~= self.stateIndex then
		if self.isServer then
			g_server:broadcastEvent(FerryStateEvent.new(self, newState), false)
		end
		local v114_ = self.stateIndex
		self.stateIndex = newState
		local v115_ = self.stateMachine[v114_]
		local v116_ = self.stateMachine[newState]
		v115_:deactivate()
		v116_:activate()
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
	elseif onLeave then
		self.nodesInBarrierTrigger[otherId] = self.nodesInBarrierTrigger[otherId] - 1
		if self.nodesInBarrierTrigger[otherId] == 0 then
			self.nodesInBarrierTrigger[otherId] = nil
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
	return self.nodes[node] == nil
end

-- Local values: time, delta, distance, x, y, z, dirX, dirY, dirZ, lx, ly, lz, _, yRot, _, vx, vy, vz, length, node, _, object, touchingNode
function Ferry:updatePosition(dt)
	local v137_ = self.currentSplineTime
	if dt ~= nil then
		local v138_ = self.lastSplineTime - self.currentSplineTime
		self.lastSpeed = math.abs(v138_) * self.splineLength / dt * 1000
	end
	self.lastSplineTime = v137_
	local v139_ = Tween.CURVE.EASE_IN_OUT(v137_)
	local v140_, v141_, v142_ = getSplinePosition(self.splineNode, v139_)
	local v143_, v144_, v145_ = getSplineDirection(self.splineNode, v139_)
	local v146_, v147_, v148_ = getWorldTranslation(self.veselNode)
	setWorldTranslation(self.veselNode, v140_, v141_, v142_)
	setWorldDirection(self.veselNode, v143_, v144_, v145_, 0, 1, 0)
	if self.mapHotspot ~= nil then
		local _, v149_, _ = getWorldRotation(self.veselNode)
		self.mapHotspot:setWorldPosition(v140_, v142_)
		self.mapHotspot:setWorldRotation(v149_)
	end
	if self.isServer then
		local v150_ = v140_ - v146_
		local v151_ = v141_ - v147_
		local v152_ = v142_ - v148_
		if MathUtil.vector3Length(v150_, v151_, v152_) > 0.0001 then
			for v153_, _ in pairs(self.nodesInTrigger) do
				local v154_ = g_currentMission:getNodeObject(v153_)
				if v154_ ~= nil and (v154_.moveCCTExternal ~= nil and v154_:getTouchingNode() ~= 0) then
					v151_ = math.min(v151_, -0.01)
					v154_:moveCCTExternal(v150_, v151_, v152_)
				end
			end
		end
	end
end

-- Local values: durationMs, _, crossingNode
function Ferry:getIsAllowedToDrive()
	local v156_ = self.durationMs
	for _, v157_ in ipairs(self.crossingNodes) do
		if g_currentMission.shipSystem:getIsShipCrossingPoint(v157_, v156_) then
			return false
		end
	end
	return true
end

-- Local values: state
function Ferry:getCanActivateDriving()
	return self:getState():getCanFinishState()
end

-- Local values: canActivateDriving, found, nodeId, _, isAllowedToDrive, state
function Ferry:start(connection)
	if self.isServer then
		if self:getCanActivateDriving() then
			local v161_ = false
			for v162_, _ in pairs(self.nodesInBarrierTrigger) do
				if entityExists(v162_) then
					v161_ = true
				else
					self.nodesInBarrierTrigger[v162_] = nil
				end
			end
			if v161_ then
				if connection == nil then
					self:onStartFailed(Ferry.ERROR_FAILED_BARRIERS_BLOCKED)
				else
					connection:sendEvent(FerryStartEvent.newToClient(self, Ferry.ERROR_FAILED_BARRIERS_BLOCKED))
				end
			elseif self:getIsAllowedToDrive() then
				self:raiseActive()
				if connection ~= nil then
					connection:sendEvent(FerryStartEvent.newToClient(self, Ferry.ERROR_SUCCESS))
				end
				self:getState():finish()
				self:onStarted()
				return
			elseif connection == nil then
				self:onStartFailed(Ferry.ERROR_FAILED_BLOCKED)
			else
				connection:sendEvent(FerryStartEvent.newToClient(self, Ferry.ERROR_FAILED_BLOCKED))
			end
		elseif connection == nil then
			self:onStartFailed(Ferry.ERROR_FAILED_BLOCKED)
		else
			connection:sendEvent(FerryStartEvent.newToClient(self, Ferry.ERROR_FAILED_ALREADY_MOVING))
		end
	else
		g_client:getServerConnection():sendEvent(FerryStartEvent.new(self))
		return
	end
end

function Ferry:onStarted()
	Logging.devInfo("Ferry:onStarted")
end

function Ferry:onStartFailed(errorCode)
	Logging.devInfo("Ferry:onStartFailed. Errorcode %d", errorCode)
	if errorCode == Ferry.ERROR_FAILED_BLOCKED then
		g_currentMission:showBlinkingWarning(g_i18n:getText("warning_ferryBlockedByOtherShips", self.customEnvironment), 2000)
		return
	elseif errorCode == Ferry.ERROR_FAILED_BARRIERS_BLOCKED then
		g_currentMission:showBlinkingWarning(g_i18n:getText("warning_ferryBarriersBlocked", self.customEnvironment), 2000)
	elseif errorCode == Ferry.ERROR_FAILED_ALREADY_MOVING then
		g_currentMission:showBlinkingWarning(g_i18n:getText("warning_ferryAlreadyMoving", self.customEnvironment), 2000)
	end
end

-- Local values: anchor, alreadyMountedObjects, node, _, object, constr
function Ferry:mountObjects()
	Logging.devInfo("Ferry:mountObjects")
	self.isMounted = true
	if not self.isServer then
		::l2::
		return
	end
	local v166_ = self.triggerNode
	local v167_ = {}
	for v168_, _ in pairs(self.nodesInTrigger) do
		if entityExists(v168_) then
			local v169_ = g_currentMission:getNodeObject(v168_)
			if v169_ == nil then
				if not getHasClassId(v168_, ClassIds.MESH_SPLIT_SHAPE) or getSplitType(v168_) == 0 then
					goto l12
				end
				if v167_[v168_] == nil then
					v167_[v168_] = true
					goto l12
				end
			elseif v167_[v169_] == nil and v169_.moveCCTExternal == nil then
				v167_[v169_] = true
				if v169_.setDynamicMountType ~= nil then
					v169_:setDynamicMountType(MountableObject.MOUNT_TYPE_DYNAMIC)
				end
				::l12::
				local v170_ = JointConstructor.new()
				v170_:setActors(v166_, v168_)
				v170_:setJointTransforms(v168_, v168_)
				v170_:setRotationLimit(0, 0, 0)
				v170_:setRotationLimit(1, 0, 0)
				v170_:setRotationLimit(2, 0, 0)
				v170_:setTranslationLimit(0, true, 0, 0)
				v170_:setTranslationLimit(1, true, 0, 0)
				v170_:setTranslationLimit(2, true, 0, 0)
				self.mountedNodes[v168_] = v170_:finalize()
			end
		else
			self.nodesInTrigger[v168_] = nil
		end
	end
	goto l2
end

-- Local values: node, jointIndex, object
function Ferry:unmountObjects()
	Logging.devInfo("Ferry:unmountObjects")
	for v172_, v173_ in pairs(self.mountedNodes) do
		if entityExists(v172_) then
			removeJoint(v173_)
			local v174_ = g_currentMission:getNodeObject(v172_)
			if v174_ ~= nil and v174_.setDynamicMountType ~= nil then
				v174_:setDynamicMountType(MountableObject.MOUNT_TYPE_NONE)
			end
		end
	end
	self.mountedNodes = {}
	self.isMounted = false
end

-- Local values: samples
function Ferry:startMotor()
	if self.isClient then
		local v176_ = self.samples
		if not g_soundManager:getIsSamplePlaying(v176_.driving) then
			g_soundManager:stopSample(v176_.stop)
			g_soundManager:playSample(v176_.start)
			g_soundManager:playSample(v176_.driving, 0, v176_.start)
		end
		g_effectManager:startEffects(self.exhaustEffects)
	end
	if self.swsObstacle == nil and self.swsObstacleSize ~= nil then
		self.swsObstacle = g_currentMission.shallowWaterSimulation:addObstacle(self.veselNode, self.swsObstacleSize[1], self.swsObstacleSize[2], self.swsObstacleSize[3], function()
			-- upvalues: (copy) self
			local v177_ = self.lastSpeed
			local v178_, _, v179_ = localDirectionToWorld(self.veselNode, 0, 0, 1)
			local v180_ = MathUtil.getYRotationFromDirection(v178_, v179_)
			return v178_ * v177_ + v177_ * MathUtil.randomFloat(-0.1, 0.1), v179_ * v177_ + v177_ * MathUtil.randomFloat(-0.1, 0.1), v180_
		end)
	end
end

-- Local values: samples
function Ferry:stopMotor()
	if self.isClient then
		local v182_ = self.samples
		g_soundManager:stopSample(v182_.driving)
		g_soundManager:stopSample(v182_.start)
		if not g_soundManager:getIsSamplePlaying(v182_.stop) then
			g_soundManager:playSample(v182_.stop)
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
