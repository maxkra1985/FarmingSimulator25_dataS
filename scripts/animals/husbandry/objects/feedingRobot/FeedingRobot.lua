-- Local values: FeedingRobot_mt
FeedingRobot = {}
local FeedingRobot_mt = Class(FeedingRobot, Object)
InitStaticObjectClass(FeedingRobot, "FeedingRobot")
g_xmlManager:addCreateSchemaFunction(function()
	FeedingRobot.xmlSchema = XMLSchema.new("feedingRobot")
end)
g_xmlManager:addInitSchemaFunction(function()
	local v2_ = FeedingRobot.xmlSchema
	v2_:register(XMLValueType.STRING, "feedingRobot.filename", "Feeding robot i3d file", nil, true)
	v2_:register(XMLValueType.NODE_INDEX, "feedingRobot.robot#node", "Robot node")
	v2_:register(XMLValueType.NODE_INDEX, "feedingRobot.robot.door#node", "Robot door node")
	v2_:register(XMLValueType.FLOAT, "feedingRobot.robot.door#maxY", "Robot door maxY")
	v2_:register(XMLValueType.FLOAT, "feedingRobot.robot.door#maxRotZ", "Robot door maxRotZ")
	v2_:register(XMLValueType.FLOAT, "feedingRobot.robot.door#duration", "Robot door duration")
	v2_:register(XMLValueType.FLOAT, "feedingRobot.robot#maxSpeed", "Max Speed", 0)
	v2_:register(XMLValueType.FLOAT, "feedingRobot.robot#acceleration", "Max acceleration", 1)
	v2_:register(XMLValueType.FLOAT, "feedingRobot.robot#deceleration", "Max deceleration", -1)
	v2_:register(XMLValueType.NODE_INDEX, "feedingRobot.robot#triggerNode", "Vehicle and player trigger node")
	v2_:register(XMLValueType.STRING, "feedingRobot.stateMachine.states.state(?)#name", "State name")
	v2_:register(XMLValueType.STRING, "feedingRobot.stateMachine.states.state(?)#class", "State class")
	FeedingRobotState.registerXMLPaths(v2_, "feedingRobot.stateMachine.states.state(?)")
	FeedingRobotStateFilling.registerXMLPaths(v2_, "feedingRobot.stateMachine.states.state(?)")
	FeedingRobotStateWait.registerXMLPaths(v2_, "feedingRobot.stateMachine.states.state(?)")
	FeedingRobotStateDriving.registerXMLPaths(v2_, "feedingRobot.stateMachine.states.state(?)")
	I3DUtil.registerI3dMappingXMLPaths(v2_, "feedingRobot")
	v2_:register(XMLValueType.NODE_INDEX, "feedingRobot.playerTrigger#node", "Vehicle and player trigger node")
	v2_:register(XMLValueType.STRING, "feedingRobot.stateMachine.transitions.transition(?)#from", "State name from")
	v2_:register(XMLValueType.STRING, "feedingRobot.stateMachine.transitions.transition(?)#to", "State name to")
	AnimatedObject.registerXMLPaths(v2_, "feedingRobot.animatedObjects")
	AnimationManager.registerAnimationNodesXMLPaths(v2_, "feedingRobot.robot.mixer.animationNodes")
	EffectManager.registerEffectXMLPaths(v2_, "feedingRobot.robot.dischargeEffects")
	v2_:register(XMLValueType.NODE_INDEX, "feedingRobot.robot.fillPlane#node", "Fillplane base node")
	v2_:register(XMLValueType.INT, "feedingRobot.robot.fillPlane#capacity", "Fillplane capacity")
	v2_:register(XMLValueType.STRING, "feedingRobot.robot.mixer#recipe", "Recipe filltype")
	FillPlaneUtil.registerFillPlaneXMLPaths(v2_, "feedingRobot.robot.fillPlane")
	SoundManager.registerSampleXMLPaths(v2_, "feedingRobot.robot.sounds", "driving")
	SoundManager.registerSampleXMLPaths(v2_, "feedingRobot.robot.sounds", "discharging")
	UnloadTrigger.registerTriggerXMLPaths(v2_, "feedingRobot.unloadingSpots.unloadingSpot(?)")
	FillPlane.registerXMLPaths(v2_, "feedingRobot.unloadingSpots.unloadingSpot(?).fillPlane")
	v2_:register(XMLValueType.NODE_INDEX, "feedingRobot.unloadingSpots.unloadingSpot(?).fillVolume#node", "Fillplane base node")
	FillPlaneUtil.registerFillPlaneXMLPaths(v2_, "feedingRobot.unloadingSpots.unloadingSpot(?).fillVolume")
	v2_:register(XMLValueType.STRING, "feedingRobot.unloadingSpots.unloadingSpot(?)#capacity", "Unloading spot capacity")
	v2_:register(XMLValueType.STRING, "feedingRobot.unloadingSpots.unloadingSpot(?)#fillTypes", "Unloading spot filltypes")
	v2_:register(XMLValueType.STRING, "feedingRobot.unloadingSpots.unloadingSpot(?)#fillTypeCategories", "Unloading spot filltype categories")
	v2_:register(XMLValueType.NODE_INDEX, "feedingRobot.unloadingSpots.unloadingSpot(?)#markerNode", "Unloading spot marker")
	AnimationManager.registerAnimationNodesXMLPaths(v2_, "feedingRobot.unloadingSpots.unloadingSpot(?).dischargeAnimationNodes")
	EffectManager.registerEffectXMLPaths(v2_, "feedingRobot.unloadingSpots.unloadingSpot(?).dischargeEffects")
	SoundManager.registerSampleXMLPaths(v2_, "feedingRobot.unloadingSpots.unloadingSpot(?).sounds", "discharging")
end)

function FeedingRobot.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. ".unloadingSpot(?)#index", "Unloading spot index")
	schema:register(XMLValueType.INT, basePath .. ".unloadingSpot(?)#fillLevel", "Unloading spot filllevel")
end

-- Upvalues: FeedingRobot_mt
-- Local values: self
function FeedingRobot.new(isServer, isClient, owner, baseDirectory, customMt)
	-- upvalues: (copy) FeedingRobot_mt
	local v10_ = Object.new(isServer, isClient, customMt or FeedingRobot_mt)
	v10_.owner = owner
	v10_.baseDirectory = baseDirectory
	v10_.i3dMappings = {}
	v10_.components = {}
	v10_.isLoadingFinished = false
	v10_.requestedStart = false
	v10_.reachedStopPoint = false
	v10_.spline = {}
	v10_.spline.nodes = {}
	v10_.spline.time = 0
	v10_.spline.timeSent = 0
	v10_.spline.length = 0
	v10_.spline.feedingLength = 0
	v10_.spline.feedingFactor = 0
	v10_.spline.dirtyFlag = v10_:getNextDirtyFlag()
	v10_.spline.timeInterpolator = InterpolationTime.new(1.2)
	v10_.spline.interpolator = InterpolatorSplineTime.new(0, false)
	v10_.fillTypeToUnloadingSpot = {}
	v10_.unloadingSpots = {}
	v10_.dirtyFlagFillLevel = v10_:getNextDirtyFlag()
	v10_.robot = nil
	v10_.playerTrigger = nil
	v10_.stateChangedListeners = {}
	v10_.animatedObjects = {}
	v10_.stateMachineNextIndex = 0
	v10_.stateIndex = nil
	v10_.state = {}
	v10_.stateMachine = {}
	v10_.stateTransitions = {}
	return v10_
end

-- Local values: xmlFile, i3dFilename, arguments
function FeedingRobot:load(linkNode, filename, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArgs)
	local v17_ = XMLFile.load("feedingRobot", filename, FeedingRobot.xmlSchema)
	if v17_ == nil then
		return false
	end
	self.configFileName = filename
	local v18_ = Utils.getFilename(v17_:getValue("feedingRobot.filename"), self.baseDirectory)
	self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(v18_, true, false, self.onI3DFileLoaded, self, {
		["xmlFile"] = v17_,
		["linkNode"] = linkNode,
		["asyncCallbackFunction"] = asyncCallbackFunction,
		["asyncCallbackObject"] = asyncCallbackObject,
		["asyncCallbackArgs"] = asyncCallbackArgs
	})
	return true
end

-- Local values: _, animatedObject, _, spot, _, unloadTrigger
function FeedingRobot:delete()
	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
		self.sharedLoadRequestId = nil
	end
	if self.animatedObjects ~= nil then
		for _, v20_ in ipairs(self.animatedObjects) do
			v20_:delete()
		end
		self.animatedObjects = nil
	end
	if self.isServer then
		if self.robot ~= nil then
			removeTrigger(self.robot.trigger)
		end
		if self.playerTrigger ~= nil then
			removeTrigger(self.playerTrigger)
		end
	end
	if self.robot ~= nil then
		g_animationManager:deleteAnimations(self.robot.mixerAnimationNodes)
		g_effectManager:deleteEffects(self.robot.dischargeEffects)
		g_soundManager:deleteSamples(self.robot.samples)
	end
	if self.unloadingSpots ~= nil then
		for _, v21_ in ipairs(self.unloadingSpots) do
			for _, v22_ in ipairs(v21_.unloadTriggers) do
				v22_:delete()
			end
			v21_.unloadTriggers = {}
			if v21_.markerNode ~= nil then
				g_currentMission:removeTriggerMarker(v21_.markerNode)
				v21_.markerNode = nil
			end
			g_animationManager:deleteAnimations(v21_.dischargeAnimationNodes)
			g_effectManager:deleteEffects(v21_.dischargeEffects)
			g_soundManager:deleteSamples(v21_.samples)
		end
	end
	if self.rootNode ~= nil then
		delete(self.rootNode)
		self.rootNode = nil
	end
	FeedingRobot:superClass().delete(self)
end

-- Local values: xmlFile, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArgs, numChildren, i, component, _, component, duration, maxValue, recipeFillTypeName, recipeFillTypeIndex, recipe, _, ingredient, info, _, fillType, maxNumStates, _, unloadingKey, spot, fillTypeCategories, fillTypeNames, fillTypes, _, unloadTrigger, firstFillType, _, unloadTrigger, _, fillType, baseNode, fillVolumeNode
function FeedingRobot:onI3DFileLoaded(node, failedReason, args)
	local v_u_26_ = args.xmlFile
	local v27_ = args.asyncCallbackFunction
	local v28_ = args.asyncCallbackObject
	local v29_ = args.asyncCallbackArgs
	if node == 0 then
		::l2::
		v_u_26_:delete()
		v27_(v28_, self, v29_)
		return
	end
	for v30_ = 0, getNumOfChildren(node) - 1 do
		local v31_ = {
			["node"] = getChildAt(node, v30_)
		}
		local v32_ = self.components
		table.insert(v32_, v31_)
	end
	if #self.components == 0 then
		Logging.xmlError(v_u_26_, "Unable to get feedingRobot components")
		v_u_26_:delete()
		v27_(v28_, self, v29_)
		return
	end
	I3DUtil.loadI3DMapping(v_u_26_, "feedingRobot", self.components, self.i3dMappings)
	for _, v33_ in ipairs(self.components) do
		link(args.linkNode, v33_.node)
	end
	self.rootNode = node
	self.robot = {}
	self.robot.node = v_u_26_:getValue("feedingRobot.robot#node", nil, self.components, self.i3dMappings)
	if self.isClient then
		self.robot.mixerAnimationNodes = g_animationManager:loadAnimations(v_u_26_, "feedingRobot.robot.mixer.animationNodes", self.components, self, self.i3dMappings)
		self.robot.dischargeEffects = g_effectManager:loadEffect(v_u_26_, "feedingRobot.robot.dischargeEffects", self.components, self, self.i3dMappings)
		self.robot.samples = {}
		self.robot.samples.driving = g_soundManager:loadSampleFromXML(v_u_26_, "feedingRobot.robot.sounds", "driving", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		self.robot.samples.discharging = g_soundManager:loadSampleFromXML(v_u_26_, "feedingRobot.robot.sounds", "discharging", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
	self.robot.maxSpeed = v_u_26_:getValue("feedingRobot.robot#maxSpeed", 1) / 3600
	self.robot.speed = 0
	self.robot.acceleration = v_u_26_:getValue("feedingRobot.robot#acceleration", 1) / 3600
	self.robot.deceleration = v_u_26_:getValue("feedingRobot.robot#deceleration", -1) / 3600
	if self.robot.deceleration > 0 then
		self.robot.deceleration = -self.robot.deceleration
	end
	self.robot.door = {}
	self.robot.door.node = v_u_26_:getValue("feedingRobot.robot.door#node", nil, self.components, self.i3dMappings)
	self.robot.door.maxY = v_u_26_:getValue("feedingRobot.robot.door#maxY", nil)
	self.robot.door.maxRotZ = v_u_26_:getAngle("feedingRobot.robot.door#maxRotZ", nil)
	local v34_ = v_u_26_:getValue("feedingRobot.robot.door#duration", 1) * 1000
	local v35_ = self.robot.door.maxY or (self.robot.door.maxRotZ or 0)
	self.robot.door.speed = v35_ / v34_
	self.robot.door.isOpen = false
	local v36_ = v_u_26_:getValue("feedingRobot.robot.mixer#recipe", "")
	local v37_ = g_fillTypeManager:getFillTypeIndexByName(v36_)
	if v37_ == nil then
		Logging.xmlError(v_u_26_, "Recipe filltype \'%s\' not defined.", v36_)
	end
	local v38_ = g_currentMission.animalFoodSystem:getRecipeByFillTypeIndex(v37_)
	if v38_ == nil then
		Logging.xmlError(v_u_26_, "Recipe \'%s\' not defined.", v36_)
	else
		self.infos = {}
		for _, v39_ in pairs(v38_.ingredients) do
			local v40_ = {
				["title"] = v39_.title,
				["text"] = "",
				["fillTypes"] = {}
			}
			for _, v41_ in ipairs(v39_.fillTypes) do
				local v42_ = v40_.fillTypes
				table.insert(v42_, v41_)
			end
			local v43_ = self.infos
			table.insert(v43_, v40_)
		end
	end
	self.robot.recipe = v38_
	self.robot.fillPlane = {}
	self.robot.fillPlane.baseNode = v_u_26_:getValue("feedingRobot.robot.fillPlane#node", nil, self.components, self.i3dMappings)
	self.robot.fillPlane.capacity = v_u_26_:getValue("feedingRobot.robot.fillPlane#capacity", 2000)
	self.robot.fillPlane.fillLevel = 0
	self.robot.fillPlane.node = FillPlaneUtil.createFromXML(v_u_26_, "feedingRobot.robot.fillPlane", self.robot.fillPlane.baseNode, self.robot.fillPlane.capacity)
	if self.robot.fillPlane.node ~= nil then
		FillPlaneUtil.assignDefaultMaterialsFromTerrain(self.robot.fillPlane.node, g_terrainNode)
		FillPlaneUtil.setFillType(self.robot.fillPlane.node, v37_)
		setVisibility(self.robot.fillPlane.node, false)
	end
	self.robot.trigger = v_u_26_:getValue("feedingRobot.robot#triggerNode", nil, self.components, self.i3dMappings)
	self.robot.objectsInTrigger = {}
	self.robot.isBlocked = false
	if self.isServer then
		addTrigger(self.robot.trigger, "onRobotTrigger", self)
	end
	self.playerTrigger = v_u_26_:getValue("feedingRobot.playerTrigger#node", nil, self.components, self.i3dMappings)
	self.nodesInPlayerTrigger = {}
	if self.isServer then
		addTrigger(self.playerTrigger, "onPlayerTrigger", self)
	end
	v_u_26_:iterate("feedingRobot.animatedObjects.animatedObject", function(p44_, p45_)
		-- upvalues: (copy) self, (copy) v_u_26_
		local v46_ = AnimatedObject.new(self.isServer, self.isClient)
		v46_:setOwnerFarmId(self:getOwnerFarmId(), false)
		if v46_:load(self.components, v_u_26_, p45_, self.configFileName, self.i3dMappings) then
			local v47_ = self.animatedObjects
			table.insert(v47_, v46_)
		else
			Logging.xmlError(v_u_26_, "Failed to load animated object %i", p44_)
		end
	end)
	local v_u_48_ = 255
	v_u_26_:iterate("feedingRobot.stateMachine.states.state", function(_, p49_)
		-- upvalues: (copy) self, (copy) v_u_26_, (copy) v_u_48_
		if self.stateMachineNextIndex > 255 then
			Logging.xmlWarning(v_u_26_, "Maximum number of states reached (%d)", 255)
			return
		else
			local v50_ = string.upper(v_u_26_:getValue(p49_ .. "#name", ""))
			if self.state[v50_] == nil then
				local v51_ = v_u_26_:getValue(p49_ .. "#class", "")
				local v52_ = ClassUtil.getClassObject(v51_)
				if v52_ == nil then
					Logging.xmlError(v_u_26_, "State class \'%s\' not defined for \'%s\'", v51_, p49_)
				else
					local v53_ = self.stateMachineNextIndex
					self.state[v50_] = v53_
					local v54_ = v52_.new(self)
					v54_:load(v_u_26_, p49_)
					self.stateMachine[v53_] = v54_
					self.stateMachineNextIndex = self.stateMachineNextIndex + 1
					if self.stateIndex == nil then
						self.stateIndex = v53_
					end
				end
			else
				Logging.xmlError(v_u_26_, "State \'%s\' at \'%s\' already defined", v50_, p49_)
				return
			end
		end
	end)
	if self.state.PAUSED == nil then
		Logging.xmlError(v_u_26_, "Mandatory state \'PAUSED\' not defined")
		v_u_26_:delete()
		v27_(v28_, self, v29_)
		return
	end
	if self.state.DRIVING == nil then
		Logging.xmlError(v_u_26_, "Mandatory state \'DRIVING\' not defined")
		v_u_26_:delete()
		v27_(v28_, self, v29_)
		return
	end
	v_u_26_:iterate("feedingRobot.stateMachine.transitions.transition", function(_, p55_)
		-- upvalues: (copy) v_u_26_, (copy) self
		local v56_ = string.upper(v_u_26_:getValue(p55_ .. "#from", ""))
		local v57_ = self.state[v56_]
		if v57_ == nil then
			Logging.xmlError(v_u_26_, "Invalid state. Transition from name \'%s\' not defined for \'%s\'", v56_, p55_)
			return
		else
			local v58_ = string.upper(v_u_26_:getValue(p55_ .. "#to", ""))
			local v59_ = self.state[v58_]
			if v59_ == nil then
				Logging.xmlError(v_u_26_, "Invalid state. Transition to name \'%s\' not defined for \'%s\'", v58_, p55_)
			else
				self.stateTransitions[v57_] = v59_
			end
		end
	end)
	for _, v60_ in v_u_26_:iterator("feedingRobot.unloadingSpots.unloadingSpot") do
		local v61_ = {
			["unloadTriggers"] = UnloadTrigger.createTriggers(self.isServer, self.isClient, v_u_26_, v60_, self.components, self, nil, self.i3dMappings),
			["capacity"] = v_u_26_:getInt(v60_ .. "#capacity", 1000)
		}
		v61_.FILLLEVEL_NUM_BITS = MathUtil.getNumRequiredBits(v61_.capacity)
		v61_.fillLevel = 0
		v61_.fillTypes = {}
		v61_.markerNode = v_u_26_:getValue(v60_ .. "#markerNode", nil, self.components, self.i3dMappings)
		if v61_.markerNode ~= nil then
			g_currentMission:addTriggerMarker(v61_.markerNode)
		end
		local v62_ = v_u_26_:getValue(v60_ .. "#fillTypeCategories")
		local v63_ = v_u_26_:getValue(v60_ .. "#fillTypes")
		local v64_
		if v62_ == nil or v63_ ~= nil then
			if v62_ == nil and v63_ ~= nil then
				v64_ = g_fillTypeManager:getFillTypesByNames(v63_, "Warning: \'" .. tostring(v60_) .. "\' has invalid fillType \'%s\'.")
				goto l46
			end
			Logging.xmlWarning(v_u_26_, "\'%s\' An \'unloadingSpot\' entry needs either the \'fillTypeCategories\' or \'fillTypes\' attribute.", v60_)
			for _, v65_ in ipairs(v61_.unloadTriggers) do
				v65_:delete()
			end
		else
			v64_ = g_fillTypeManager:getFillTypesByCategoryNames(v62_, "Warning: \'" .. tostring(v60_) .. "\' has invalid fillTypeCategory \'%s\'.")
			::l46::
			local v66_ = nil
			for _, v67_ in ipairs(v61_.unloadTriggers) do
				v67_.fillTypes = {}
				for _, v68_ in pairs(v64_) do
					table.addElement(v61_.fillTypes, v68_)
					self.fillTypeToUnloadingSpot[v68_] = v61_
					v67_.fillTypes[v68_] = true
					v66_ = v66_ or v68_
				end
			end
			v61_.samples = {}
			v61_.samples.discharging = g_soundManager:loadSampleFromXML(v_u_26_, v60_ .. ".sounds", "discharging", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
			v61_.dischargeAnimationNodes = g_animationManager:loadAnimations(v_u_26_, v60_ .. ".dischargeAnimationNodes", self.components, self, self.i3dMappings)
			v61_.dischargeEffects = g_effectManager:loadEffect(v_u_26_, v60_ .. ".dischargeEffects", self.components, self, self.i3dMappings)
			g_effectManager:setEffectTypeInfo(v61_.dischargeEffects, v66_)
			if v_u_26_:hasProperty(v60_ .. ".fillPlane") then
				v61_.fillPlane = FillPlane.new()
				v61_.fillPlane:load(self.components, v_u_26_, v60_ .. ".fillPlane", self.i3dMappings)
				FillPlaneUtil.assignDefaultMaterialsFromTerrain(v61_.fillPlane.node, g_terrainNode)
				FillPlaneUtil.setFillType(v61_.fillPlane.node, v66_)
				setShaderParameter(v61_.fillPlane.node, "isCustomShape", 1, 0, 0, 0, false)
			elseif v_u_26_:hasProperty(v60_ .. ".fillVolume") then
				local v69_ = v_u_26_:getValue(v60_ .. ".fillVolume#node", nil, self.components, self.i3dMappings)
				local v70_ = FillPlaneUtil.createFromXML(v_u_26_, v60_ .. ".fillVolume", v69_, v61_.capacity)
				if v70_ ~= nil then
					v61_.fillVolume = {}
					v61_.fillVolume.baseNode = v69_
					v61_.fillVolume.node = v70_
					v61_.fillVolume.fillLevel = 0
					FillPlaneUtil.assignDefaultMaterialsFromTerrain(v70_, g_terrainNode)
					FillPlaneUtil.setFillType(v70_, v66_)
					setVisibility(v70_, false)
				end
			end
			local v71_ = self.unloadingSpots
			table.insert(v71_, v61_)
		end
	end
	if self.finishedSplines then
		self:setSplineTime(0)
	end
	self:raiseActive()
	goto l2
end

-- Local values: _, component, _, animatedObject, _, spot, _, unloadTrigger
function FeedingRobot:finalizePlacement()
	for _, v73_ in ipairs(self.components) do
		addToPhysics(v73_.node)
	end
	for _, v74_ in ipairs(self.animatedObjects) do
		v74_:register(true)
	end
	for _, v75_ in ipairs(self.unloadingSpots) do
		for _, v76_ in ipairs(v75_.unloadTriggers) do
			v76_:register(true)
		end
	end
	self.isLoadingFinished = true
end

-- Local values: stateIndex, splineTime, _, animatedObject, animatedObjectId, _, spot, _, unloadTrigger, unloadTriggerId
function FeedingRobot:readStream(streamId, connection)
	FeedingRobot:superClass().readStream(self, streamId, connection)
	if connection:getIsServer() then
		self:setState((streamReadUInt8(streamId)))
		local v80_ = streamReadFloat32(streamId)
		self.spline.interpolator:setValue(v80_)
		self.spline.timeInterpolator:reset()
		self.spline.time = v80_
		for _, v81_ in ipairs(self.animatedObjects) do
			local v82_ = NetworkUtil.readNodeObjectId(streamId)
			v81_:readStream(streamId, connection)
			g_client:finishRegisterObject(v81_, v82_)
		end
		for _, v83_ in ipairs(self.unloadingSpots) do
			for _, v84_ in ipairs(v83_.unloadTriggers) do
				local v85_ = NetworkUtil.readNodeObjectId(streamId)
				v84_:readStream(streamId, connection)
				g_client:finishRegisterObject(v84_, v85_)
			end
			v83_.fillLevel = streamReadUIntN(streamId, v83_.FILLLEVEL_NUM_BITS)
			self:updateUnloadingSpot(v83_)
		end
		self:raiseActive()
	end
end

-- Local values: _, animatedObject, _, spot, _, unloadTrigger
function FeedingRobot:writeStream(streamId, connection)
	FeedingRobot:superClass().writeStream(self, streamId, connection)
	if not connection:getIsServer() then
		streamWriteUInt8(streamId, self.stateIndex)
		streamWriteFloat32(streamId, self.spline.timeSent)
		for _, v89_ in ipairs(self.animatedObjects) do
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v89_))
			v89_:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, v89_)
		end
		for _, v90_ in ipairs(self.unloadingSpots) do
			for _, v91_ in ipairs(v90_.unloadTriggers) do
				NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v91_))
				v91_:writeStream(streamId, connection)
				g_server:registerObjectInStream(connection, v91_)
			end
			streamWriteUIntN(streamId, v90_.fillLevel, v90_.FILLLEVEL_NUM_BITS)
		end
	end
end

-- Local values: splineTime, _, spot
function FeedingRobot:readUpdateStream(streamId, timestamp, connection)
	FeedingRobot:superClass().readUpdateStream(self, streamId, timestamp, connection)
	if connection:getIsServer() then
		if streamReadBool(streamId) then
			local v96_ = streamReadFloat32(streamId)
			self.spline.timeInterpolator:startNewPhaseNetwork()
			self.spline.interpolator:setTargetValue(v96_)
		end
		if streamReadBool(streamId) then
			for _, v97_ in ipairs(self.unloadingSpots) do
				v97_.fillLevel = streamReadUIntN(streamId, v97_.FILLLEVEL_NUM_BITS)
				self:updateUnloadingSpot(v97_)
			end
		end
	end
end

-- Local values: _, spot
function FeedingRobot:writeUpdateStream(streamId, connection, dirtyMask)
	FeedingRobot:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v102_ = streamWriteBool
		local v103_ = self.spline.dirtyFlag
		if v102_(streamId, bit32.band(dirtyMask, v103_) ~= 0) then
			streamWriteFloat32(streamId, self.spline.timeSent)
		end
		local v104_ = streamWriteBool
		local v105_ = self.dirtyFlagFillLevel
		if v104_(streamId, bit32.band(dirtyMask, v105_) ~= 0) then
			for _, v106_ in ipairs(self.unloadingSpots) do
				streamWriteUIntN(streamId, v106_.fillLevel, v106_.FILLLEVEL_NUM_BITS)
			end
		end
	end
end

function FeedingRobot:loadFromXMLFile(xmlFile, key)
	xmlFile:iterate(key .. ".unloadingSpot", function(_, p110_)
		-- upvalues: (copy) xmlFile, (copy) self
		local v111_ = xmlFile:getValue(p110_ .. "#index")
		local v112_ = xmlFile:getValue(p110_ .. "#fillLevel")
		if v111_ ~= nil and v112_ ~= nil then
			local v113_ = self.unloadingSpots[v111_]
			if v113_ ~= nil then
				local v114_ = v113_.capacity
				v113_.fillLevel = math.clamp(v112_, 0, v114_)
				self:updateUnloadingSpot(v113_)
			end
		end
	end)
end

-- Local values: index, spotIndex, spot, spotKey
function FeedingRobot:saveToXMLFile(xmlFile, key, usedModNames)
	local v118_ = 0
	for v119_, v120_ in pairs(self.unloadingSpots) do
		local v121_ = string.format("%s.unloadingSpot(%d)", key, v118_)
		xmlFile:setValue(v121_ .. "#index", v119_)
		xmlFile:setValue(v121_ .. "#fillLevel", v120_.fillLevel)
		v118_ = v118_ + 1
	end
end

-- Local values: _, animatedObject
function FeedingRobot:setOwnerFarmId(ownerFarmId, noEventSend)
	FeedingRobot:superClass().setOwnerFarmId(self, ownerFarmId, noEventSend)
	for _, v125_ in ipairs(self.animatedObjects) do
		v125_:setOwnerFarmId(ownerFarmId, true)
	end
end

-- Local values: length
function FeedingRobot:addSpline(node, direction, isFeeding, stopAtEnd)
	local v131_ = getSplineLength(node)
	local v132_ = self.spline.nodes
	table.insert(v132_, {
		["node"] = node,
		["direction"] = direction,
		["length"] = v131_,
		["startTime"] = 0,
		["endTime"] = 0,
		["isFeeding"] = isFeeding,
		["stopAtEnd"] = stopAtEnd
	})
	self.spline.length = self.spline.length + v131_
	if isFeeding then
		self.spline.feedingLength = self.spline.feedingLength + v131_
	end
end

function FeedingRobot:finishSplines()
	self:updateSplineTimes()
	self.finishedSplines = true
	self:setSplineTime(0)
end

function FeedingRobot:addSplineWaitingPoint(fakeLength)
	local v136_ = self.spline.nodes
	table.insert(v136_, {
		["node"] = nil,
		["length"] = fakeLength,
		["startTime"] = 0,
		["endTime"] = 0,
		["isFeeding"] = false
	})
end

-- Local values: startTime, _, splineNode
function FeedingRobot:updateSplineTimes()
	local v138_ = 0
	for _, v139_ in ipairs(self.spline.nodes) do
		v139_.startTime = math.max(v138_, 0)
		local v140_ = v138_ + v139_.length / self.spline.length
		v139_.endTime = math.min(v140_, 1)
		v138_ = v139_.endTime
	end
end

-- Local values: state, nextStateIndex, interpolationAlpha, splineTime, validSplineTime, door, dir, _, y, _, _, _, z
function FeedingRobot:update(dt)
	if self.isLoadingFinished then
		local v143_ = self.stateMachine[self.stateIndex]
		if self.isServer then
			if v143_:isDone() then
				self:setState(self.stateTransitions[self.stateIndex])
				v143_ = self.stateMachine[self.stateIndex]
				self:raiseActive()
			elseif v143_:raiseActive() then
				self:raiseActive()
			end
		end
		v143_:update(dt)
		if not self.isServer and (self.isClient and self:getIsDriving()) then
			self.spline.timeInterpolator:update(dt)
			local v144_ = self.spline.timeInterpolator:getAlpha()
			local v145_ = self.spline.interpolator:getInterpolatedValue(v144_)
			self:setSplineTime((SplineUtil.getValidSplineTime(v145_)))
			if self.spline.timeInterpolator:isInterpolating() then
				self:raiseActive()
			end
		end
		local v146_ = self.robot.door
		local v147_ = v146_.isOpen and 1 or -1
		if v146_.maxY ~= nil then
			local _, v148_, _ = getTranslation(v146_.node)
			local v149_ = v148_ + v147_ * dt * v146_.speed
			local v150_ = v146_.maxY
			local v151_ = math.clamp(v149_, 0, v150_)
			setTranslation(v146_.node, 0, v151_, 0)
		end
		if v146_.maxRotZ ~= nil then
			local _, _, v152_ = getRotation(v146_.node)
			local v153_ = v152_ + v147_ * dt * v146_.speed
			local v154_ = v146_.maxRotZ
			local v155_ = math.clamp(v153_, 0, v154_)
			setRotation(v146_.node, 0, 0, v155_)
		end
	else
		self:raiseActive()
	end
end

-- Local values: node, _
function FeedingRobot:start()
	if self.isServer and self.stateIndex == self.state.PAUSED then
		for v157_, _ in pairs(self.nodesInPlayerTrigger) do
			if not entityExists(v157_) then
				self.nodesInPlayerTrigger[v157_] = nil
			end
		end
		if next(self.nodesInPlayerTrigger) == nil then
			self.requestedStart = true
			self:raiseActive()
		end
	end
end

function FeedingRobot:getIsDriving()
	local v159_
	if self.stateIndex == self.state.PAUSED or self.stateIndex == self.state.LOADING then
		v159_ = false
	else
		v159_ = self.stateIndex ~= self.state.RESET
	end
	return v159_
end

function FeedingRobot:addStateChangedListener(func)
	table.addElement(self.stateChangedListeners, func)
end

function FeedingRobot:resetRobot()
	self:setSplineTime(0)
	self.spline.interpolator:setValue(0)
	self.spline.timeInterpolator:reset()
end

function FeedingRobot:addSplineDelta(delta)
	self:setSplineTime(self.spline.time + delta / self.spline.length)
end

-- Local values: spline, oldSplineTime, dischargeEffectActive, feedingLength, _, splineNode, rangeTime, node, robotNode, x, y, z, dirX, dirY, dirZ, feedingFactor, threshold
function FeedingRobot:setSplineTime(splineTime)
	if self.robot == nil then
		return
	end
	local v167_ = self.spline
	local v168_ = v167_.time
	local v169_ = math.clamp(splineTime, 0, 1)
	v167_.time = v169_
	local v170_ = 0
	local v171_ = false
	for _, v172_ in ipairs(v167_.nodes) do
		if self.isServer and (v168_ < v172_.endTime and (v172_.endTime < v169_ and v172_.stopAtEnd)) then
			v169_ = v172_.endTime
			self.reachedStopPoint = true
		end
		if v172_.startTime <= v169_ and v169_ <= v172_.endTime then
			local v173_ = (v169_ - v172_.startTime) / (v172_.endTime - v172_.startTime)
			local v174_ = v172_.node
			if v174_ ~= nil then
				local v175_ = self.robot.node
				local v176_, v177_, v178_ = getSplinePosition(v174_, v173_)
				local v179_, v180_, v181_ = getSplineDirection(v174_, v173_)
				local v182_, v183_, v184_ = worldDirectionToLocal(getParent(v175_), v179_, v180_, v181_)
				local v185_ = v182_ * v172_.direction
				local v186_ = v184_ * v172_.direction
				setWorldTranslation(v175_, v176_, v177_, v178_)
				setDirection(v175_, v185_, v183_, v186_, 0, 1, 0)
			end
			if v172_.isFeeding then
				v170_ = v170_ + v172_.length * v173_
				v171_ = true
			end
			break
		end
		if v172_.isFeeding then
			v170_ = v170_ + v172_.length
		end
	end
	local v187_ = self.spline.feedingLength <= 0 and 0 or v170_ / self.spline.feedingLength
	self.spline.feedingFactor = v187_
	if v171_ then
		if not g_soundManager:getIsSamplePlaying(self.robot.samples.discharging) then
			g_soundManager:playSample(self.robot.samples.discharging)
		end
		if not self.robot.dischargeEffectsActive then
			g_effectManager:setEffectTypeInfo(self.robot.dischargeEffects, self.robot.recipe.fillType)
			g_effectManager:startEffects(self.robot.dischargeEffects)
			self.robot.dischargeEffectsActive = true
		end
	else
		if g_soundManager:getIsSamplePlaying(self.robot.samples.discharging) then
			g_soundManager:stopSample(self.robot.samples.discharging)
		end
		if self.robot.dischargeEffectsActive then
			g_effectManager:stopEffects(self.robot.dischargeEffects)
			self.robot.dischargeEffectsActive = false
		end
	end
	self.robot.door.isOpen = v171_
	if self.isServer then
		local v188_ = 0.02 / self.spline.length
		local v189_ = self.spline.time - self.spline.timeSent
		if v188_ < math.abs(v189_) then
			self.spline.timeSent = self.spline.time
			self:raiseDirtyFlags(self.spline.dirtyFlag)
		end
	end
end

function FeedingRobot:getFeedingFactor()
	return self.spline.feedingFactor
end

-- Local values: oldStateIndex, oldState, state, _, func
function FeedingRobot:setState(newState)
	if newState ~= self.stateIndex then
		if self.isServer then
			g_server:broadcastEvent(FeedingRobotStateEvent.new(self, newState), false)
		end
		local v193_ = self.stateIndex
		self.stateIndex = newState
		local v194_ = self.stateMachine[v193_]
		local v195_ = self.stateMachine[newState]
		v194_:deactivate()
		v195_:activate()
		for _, v196_ in ipairs(self.stateChangedListeners) do
			v196_(self, newState)
		end
	end
end

function FeedingRobot:getState()
	return self.stateIndex
end

function FeedingRobot:setIsDriving(isDriving)
	if self.isClient then
		if isDriving then
			if not g_soundManager:getIsSamplePlaying(self.robot.samples.driving) then
				g_soundManager:playSample(self.robot.samples.driving)
				return
			end
		elseif g_soundManager:getIsSamplePlaying(self.robot.samples.driving) then
			g_soundManager:stopSamples(self.robot.samples)
		end
	end
end

function FeedingRobot:setMixingAnimationActive(isActive)
	if isActive then
		g_animationManager:startAnimations(self.robot.mixerAnimationNodes)
	else
		g_animationManager:stopAnimations(self.robot.mixerAnimationNodes)
	end
end

-- Local values: spot
function FeedingRobot:setUnloadingSpotActive(spotIndex, isActive)
	local v205_ = self.unloadingSpots[spotIndex]
	if v205_ ~= nil then
		if isActive then
			if not g_soundManager:getIsSamplePlaying(v205_.samples.discharging) then
				g_soundManager:playSample(v205_.samples.discharging)
			end
			g_effectManager:startEffects(v205_.dischargeEffects)
			g_animationManager:startAnimations(v205_.dischargeAnimationNodes)
			return
		end
		if g_soundManager:getIsSamplePlaying(v205_.samples.discharging) then
			g_soundManager:stopSample(v205_.samples.discharging)
		end
		g_effectManager:stopEffects(v205_.dischargeEffects)
		g_animationManager:stopAnimations(v205_.dischargeAnimationNodes)
	end
end

-- Local values: fillPlane, targetLevel, delta, node, x, y, z, d1x, d1y, d1z, d2x, d2y, d2z
function FeedingRobot:setFillScale(scale)
	local v208_ = self.robot.fillPlane
	if v208_ ~= nil and v208_.node ~= nil then
		local v209_ = scale * v208_.capacity
		local v210_ = v209_ - v208_.fillLevel
		if math.abs(v210_) > 1 then
			v208_.fillLevel = v209_
			local v211_ = v208_.node
			local v212_, v213_, v214_ = localToWorld(v211_, 0, 0, 0)
			local v215_, v216_, v217_ = localDirectionToWorld(v211_, 0.5, 0, 0)
			local v218_, v219_, v220_ = localDirectionToWorld(v211_, 0, 0, 0.5)
			fillPlaneAdd(v211_, v210_, v212_, v213_, v214_, v215_, v216_, v217_, v218_, v219_, v220_)
		end
		setVisibility(v208_.node, scale > 0)
	end
end

function FeedingRobot:onRobotTrigger(triggerId, otherId, onEnter, onLeave, onStay)
	if onEnter then
		if not I3DUtil.getIsLinkedToNode(self.robot.node, otherId) then
			self.robot.objectsInTrigger[otherId] = true
		end
	elseif onLeave then
		self.robot.objectsInTrigger[otherId] = nil
	end
	self.robot.isBlocked = next(self.robot.objectsInTrigger) ~= nil
end

function FeedingRobot:onPlayerTrigger(triggerId, otherId, onEnter, onLeave, onStay)
	if onEnter then
		self.nodesInPlayerTrigger[otherId] = true
	elseif onLeave then
		self.nodesInPlayerTrigger[otherId] = nil
	end
end

-- Local values: _, spot, _, unloadTrigger
function FeedingRobot:getIsNodeUsed(node)
	for _, v231_ in ipairs(self.unloadingSpots) do
		for _, v232_ in ipairs(v231_.unloadTriggers) do
			if v232_.exactFillRootNode == node or v232_.triggerNode == node then
				return true
			end
		end
	end
	return false
end

-- Local values: spot
function FeedingRobot:getFreeCapacity(fillTypeIndex)
	local v235_ = self.fillTypeToUnloadingSpot[fillTypeIndex]
	return v235_ == nil and 0 or v235_.capacity - v235_.fillLevel
end

-- Local values: spot
function FeedingRobot:getIsFillTypeAllowed(fillTypeIndex)
	return self.fillTypeToUnloadingSpot[fillTypeIndex] ~= nil
end

function FeedingRobot:getIsToolTypeAllowed(toolType)
	return true
end

-- Local values: spot
function FeedingRobot:addFillLevelFromTool(farmId, deltaFillLevel, fillTypeIndex, fillPositionData, toolType, extraAttributes)
	local v241_ = self.fillTypeToUnloadingSpot[fillTypeIndex]
	if v241_ == nil then
		return 0
	end
	if v241_.fillLevel >= v241_.capacity then
		return 0
	end
	local v242_ = v241_.capacity - v241_.fillLevel
	local v243_ = math.min(v242_, deltaFillLevel)
	if self.isServer then
		self:raiseDirtyFlags(self.dirtyFlagFillLevel)
	end
	v241_.fillLevel = v241_.fillLevel + v243_
	self:updateUnloadingSpot(v241_)
	return v243_
end

-- Local values: spot, absDelta, spotDelta
function FeedingRobot:removeFillLevel(deltaFillLevel, fillTypeIndex)
	local v247_ = self.fillTypeToUnloadingSpot[fillTypeIndex]
	local v248_ = math.abs(deltaFillLevel)
	if v247_ ~= nil then
		local v249_ = v247_.fillLevel
		local v250_ = math.min(v248_, v249_)
		v247_.fillLevel = v247_.fillLevel - v250_
		v248_ = v248_ - v250_
		if self.isServer then
			self:raiseDirtyFlags(self.dirtyFlagFillLevel)
		end
		self:updateUnloadingSpot(v247_)
	end
	return math.abs(deltaFillLevel) - v248_
end

-- Local values: fillLevel, spot
function FeedingRobot:getFillLevel(fillTypeIndex)
	local v253_ = 0
	local v254_ = self.fillTypeToUnloadingSpot[fillTypeIndex]
	if v254_ ~= nil then
		v253_ = v253_ + v254_.fillLevel
	end
	return v253_
end

-- Local values: newFillLevel, currentFillLevel, delta, node, x, y, z, d1x, d1y, d1z, d2x, d2y, d2z
function FeedingRobot:updateUnloadingSpot(spot)
	if spot.fillPlane == nil then
		if spot.fillVolume ~= nil then
			local v256_ = spot.fillLevel
			local v257_ = v256_ - spot.fillVolume.fillLevel
			local v258_ = spot.fillVolume.node
			if math.abs(v257_) > 10 then
				spot.fillVolume.fillLevel = v256_
				local v259_, v260_, v261_ = localToWorld(v258_, 0, 0, 0)
				local v262_, v263_, v264_ = localDirectionToWorld(v258_, 0.5, 0, 0)
				local v265_, v266_, v267_ = localDirectionToWorld(v258_, 0, 0, 0.5)
				fillPlaneAdd(v258_, v257_, v259_, v260_, v261_, v262_, v263_, v264_, v265_, v266_, v267_)
			end
			setVisibility(v258_, v256_ > 0)
		end
	else
		spot.fillPlane:setState(spot.fillLevel / spot.capacity)
	end
end

-- Local values: recipe, maxLiters, _, ingredient, fillLevel, _, fillType, _, ingredient, usedFillLevel, _, fillType, delta
function FeedingRobot:createFoodMixture(liters)
	if self.isServer then
		local v270_ = self.robot.recipe
		local v271_ = self.owner
		local v272_ = v270_.fillType
		local v273_ = math.min(liters, v271_:getFreeFoodCapacity(v272_))
		for _, v274_ in pairs(v270_.ingredients) do
			local v275_ = 0
			for _, v276_ in ipairs(v274_.fillTypes) do
				v275_ = v275_ + self:getFillLevel(v276_)
			end
			local v277_ = v275_ / v274_.ratio
			v273_ = math.min(v273_, v277_)
			if v273_ <= 0 then
				return
			end
		end
		for _, v278_ in pairs(v270_.ingredients) do
			local v279_ = v273_ * v278_.ratio
			for _, v280_ in ipairs(v278_.fillTypes) do
				v279_ = v279_ - self:removeFillLevel(v279_, v280_)
				if v279_ <= 0 then
					break
				end
			end
		end
		self.owner:addFood(self:getOwnerFarmId(), v273_, v270_.fillType, nil, nil, nil)
		self:start()
	end
end

-- Local values: _, info, fillLevel, _, fillType
function FeedingRobot:updateInfo(infoTable)
	if self.infos ~= nil then
		for _, v283_ in ipairs(self.infos) do
			local v284_ = 0
			for _, v285_ in ipairs(v283_.fillTypes) do
				v284_ = v284_ + self:getFillLevel(v285_)
			end
			v283_.text = string.format("%d l", v284_)
			table.insert(infoTable, v283_)
		end
	end
end
