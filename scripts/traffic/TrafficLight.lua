-- Local values: TrafficLight_mt
TrafficLight = {}
TrafficLight.AMBER_DURATION_PER_KPH = 62.5
TrafficLight.BLOCKER_TYPES = {
	["TRAFFIC"] = 1,
	["PEDESTRIAN"] = 2,
	["AI"] = 3
}
local TrafficLight_mt = Class(TrafficLight, Object)
InitStaticObjectClass(TrafficLight, "TrafficLight")

-- Local values: xmlFilename, trafficLight
function TrafficLight.onCreate(_, node)
	local v3_ = getUserAttribute(node, "xmlFilename")
	if v3_ == nil then
		Logging.error("Missing \'xmlFilename\' string userattribute for traffic light \'%s\'", I3DUtil.getNodePath(node))
		return
	else
		local v4_ = Utils.getFilename(v3_, g_currentMission.loadingMapBaseDirectory)
		if fileExists(v4_) then
			local v5_ = TrafficLight.new()
			if v5_:loadFromXML(node, v4_) then
				g_currentMission.onCreateObjectSystem:add(v5_, false)
				v5_:register(true)
			else
				v5_:delete()
			end
		else
			Logging.error("Defined xmlFilename \'%s\' for traffic light \'%s\' does not exist", v4_, I3DUtil.getNodePath(node))
			return
		end
	end
end

-- Upvalues: TrafficLight_mt
-- Local values: self
function TrafficLight.new(customMt)
	-- upvalues: (copy) TrafficLight_mt
	local v7_ = Object.new(g_server ~= nil, g_client ~= nil, customMt or TrafficLight_mt)
	v7_.xmlFilename = nil
	v7_.pendingBlockingPositions = {}
	return v7_
end

function TrafficLight:delete()
	g_messageCenter:unsubscribeAll(self)
	TrafficLight:superClass().delete(self)
end

-- Local values: components, xmlFile, i3dMapping, movementIndex, movementKey, movementId, signals, signalIndex, signalKey, red, amber, green, blockerIndex, blockerKey, blockerNode, blockerTypeStr, blockerType, phaseIds, phases, unusedMovements, phaseIndex, phaseKey, id, phaseMovements, movementIndex, movementKey, movementId, setTo, doBlockDefault, doBlock, phase, phaseArrangement, unusedPhases, phaseIndex, phaseKey, phaseId, phase, _, movement, blockerType, pendingBlockerData
function TrafficLight:loadFromXML(node, xmlFilename)
	self.xmlFilename = xmlFilename
	local v12_ = {}
	I3DUtil.loadI3DComponents(node, v12_)
	local v13_ = XMLFile.load("trafficLight", xmlFilename)
	if v13_ == nil then
		return false
	end
	local v14_ = {}
	I3DUtil.loadI3DMapping(v13_, nil, v12_, v14_)
	self.movements = {}
	for _, v15_ in v13_:iterator("trafficLight.movements.movement") do
		local v16_ = v13_:getString(v15_ .. "#id")
		if self.movements[v16_] == nil then
			local v17_ = nil
			for _, v18_ in v13_:iterator(v15_ .. ".signal") do
				local v19_ = v13_:getNode(v18_ .. "#red", nil, v12_, v14_)
				local v20_ = v13_:getNode(v18_ .. "#amber", nil, v12_, v14_)
				local v21_ = v13_:getNode(v18_ .. "#green", nil, v12_, v14_)
				if v19_ ~= nil or (v20_ ~= nil or v21_ ~= nil) then
					v17_ = v17_ or {}
					table.insert(v17_, {
						["red"] = v19_,
						["amber"] = v20_,
						["green"] = v21_
					})
				end
			end
			self.movements[v16_] = {
				["signals"] = v17_,
				["blockers"] = nil
			}
			for _, v22_ in v13_:iterator(v15_ .. ".blocker") do
				local v23_ = v13_:getNode(v22_ .. "#node", nil, v12_, v14_)
				if v23_ ~= nil then
					if getHasClassId(v23_, ClassIds.SHAPE) then
						Logging.xmlWarning(v13_, "Blocker node \'%s\' is of type shape", v22_)
					end
					local v24_ = v13_:getString(v22_ .. "#type")
					if v24_ == nil then
						Logging.xmlError(v13_, "No blocker type given for \'%s\'\nAvailable blocker types: %s", v22_, table.concatKeys(TrafficLight.BLOCKER_TYPES, ", "))
					else
						local v25_ = string.upper(v24_)
						local v26_ = TrafficLight.BLOCKER_TYPES[v25_]
						if v26_ == nil then
							Logging.xmlError(v13_, "Invalid blocker type \'%s\' for \'%s\'\nAvailable blocker types: %s", v26_, v22_, table.concatKeys(TrafficLight.BLOCKER_TYPES, ", "))
						else
							self:addBlockingPosition(v26_, v23_, v16_)
						end
					end
				end
			end
		else
			Logging.xmlWarning(v13_, "Movement id \'%s\' at \'%s\' already in use", v16_, v15_)
		end
	end
	local v27_ = table.clone(self.movements)
	local v28_ = {}
	local v29_ = {}
	for _, v30_ in v13_:iterator("trafficLight.phases.phase") do
		local v31_ = v13_:getString(v30_ .. "#id")
		if v28_[v31_] == nil then
			local v32_ = {}
			for _, v33_ in v13_:iterator(v30_ .. ".movement") do
				local v34_ = v13_:getString(v33_ .. "#id")
				if self.movements[v34_] == nil then
					Logging.xmlWarning(v13_, "Unknown movement id \'%s\' at \'%s\'", v34_, v33_)
				elseif v32_[v34_] == nil then
					local v35_ = v13_:getString(v33_ .. "#set")
					local v36_ = (v35_ == "RED" or v35_ == "RED_AMBER") and true or v35_ == "AMBER"
					v32_[v34_] = {
						["setTo"] = v35_,
						["doBlock"] = v13_:getBool(v33_ .. "#block", v36_)
					}
					v27_[v34_] = nil
				else
					Logging.xmlWarning(v13_, "Movement \'%s\' at \'%s\' already defined for phase \'%s\'", v34_, v33_, v31_)
				end
			end
			local v37_ = {
				["movements"] = v32_,
				["id"] = v31_,
				["index"] = #v29_ + 1
			}
			v28_[v31_] = v37_
			table.insert(v29_, v37_)
		else
			Logging.xmlWarning(v13_, "Phase id \'%s\' at \'%s\' already in use", v31_, v30_)
		end
	end
	if table.size(v27_) > 0 then
		Logging.xmlWarning(v13_, "traffic light has unused movements: %s", table.concatKeys(v27_, ", "))
	end
	local v38_ = table.clone(v28_)
	local v39_ = {}
	for _, v40_ in v13_:iterator("trafficLight.phaseArrangement.phase") do
		local v41_ = v13_:getString(v40_ .. "#id")
		local v42_ = v28_[v41_]
		if v42_ == nil then
			Logging.xmlWarning(v13_, "Unknown phase id \'%s\' at \'%s\'", v41_, v40_)
		else
			v38_[v41_] = nil
			local v43_ = {
				["phase"] = v42_,
				["duration"] = (v13_:getFloat(v40_ .. "#duration") or 5) * 1000
			}
			table.insert(v39_, v43_)
		end
	end
	if table.size(v38_) > 0 then
		Logging.xmlWarning(v13_, "traffic light has unused phases: %s", table.concatKeys(v38_, ", "))
	end
	for _, v44_ in pairs(self.movements) do
		self:setMovementState(v44_, "RED")
	end
	for v45_, v46_ in pairs(self.pendingBlockingPositions) do
		if #v46_ > 0 then
			if v45_ == TrafficLight.BLOCKER_TYPES.TRAFFIC then
				g_messageCenter:subscribeOneshot(MessageType.TRAFFIC_SYSTEM_LOADED, self.onTrafficSystemLoaded, self)
			elseif v45_ == TrafficLight.BLOCKER_TYPES.PEDESTRIAN then
				g_messageCenter:subscribeOneshot(MessageType.PEDESTRIAN_SYSTEM_LOADED, self.onPedestrianSystemLoaded, self)
			elseif v45_ == TrafficLight.BLOCKER_TYPES.AI then
				g_messageCenter:subscribeOneshot(MessageType.AI_SYSTEM_LOADED, self.onAISystemLoaded, self)
			end
		end
	end
	v13_:delete()
	self.node = node
	self.phases = v29_
	self.phasesNumBits = MathUtil.getNumRequiredBits(#self.phases)
	self.phaseArrangement = v39_
	if self.isServer then
		self.nextPhaseTime = g_time
		self.currentPhaseIndex = 1
		self.currentPhaseArrangementIndex = 1
		self.raiseActiveTimer = Timer.new()
		self.raiseActiveTimer:setFinishCallback(function()
			-- upvalues: (copy) self
			self:raiseActive()
		end)
		self.phaseDirtyFlag = self:getNextDirtyFlag()
	end
	self:setPhase(1)
	if self.isServer then
		self:raiseActive()
	end
	return true
end

-- Local values: maxDistanceFromSpline, spline, splineTime, direction, wx, wy, wz, dx, dy, dz, blockers
function TrafficLight:addBlockingPosition(blockerType, blockerNode, movementId)
	local v51_ = nil
	local v52_ = nil
	local v53_ = nil
	local v54_, v55_, v56_ = getWorldTranslation(blockerNode)
	local v57_, v58_, v59_ = localDirectionToWorld(blockerNode, 0, 0, 1)
	if blockerType == TrafficLight.BLOCKER_TYPES.TRAFFIC then
		if g_currentMission.trafficSystem == nil or g_currentMission.trafficSystem.trafficSystemId == nil then
			self.pendingBlockingPositions[blockerType] = self.pendingBlockingPositions[blockerType] or {}
			local v60_ = self.pendingBlockingPositions[blockerType]
			table.insert(v60_, {
				["movementId"] = movementId,
				["blockerNode"] = blockerNode
			})
			return nil
		end
		v51_, v52_ = findTrafficSystemBlockingPositionInformation(g_currentMission.trafficSystem.trafficSystemId, v54_, v55_, v56_, v57_, v58_, v59_, 1)
		if v51_ == 0 then
			Logging.xmlWarning(self.xmlFilename, "Unable to find spline in traffic blocker \'%s\' z-direction  at %.1f %.1f %.1f", I3DUtil.getNodePath(blockerNode), getWorldTranslation(blockerNode))
			return nil
		end
	elseif blockerType == TrafficLight.BLOCKER_TYPES.PEDESTRIAN then
		if g_currentMission.pedestrianSystem == nil or g_currentMission.pedestrianSystem.pedestrianSystemId == nil then
			self.pendingBlockingPositions[blockerType] = self.pendingBlockingPositions[blockerType] or {}
			local v61_ = self.pendingBlockingPositions[blockerType]
			table.insert(v61_, {
				["movementId"] = movementId,
				["blockerNode"] = blockerNode
			})
			return nil
		end
		v51_, v52_, v53_ = findPedestrianSystemBlockingPositionInformation(g_currentMission.pedestrianSystem.pedestrianSystemId, v54_, v55_, v56_, v57_, v58_, v59_, 1)
		if v51_ == 0 then
			Logging.xmlWarning(self.xmlFilename, "Unable to find spline in pedestrian blocker \'%s\' z-direction at %.1f %.1f %.1f", I3DUtil.getNodePath(blockerNode), getWorldTranslation(blockerNode))
			return nil
		end
	elseif blockerType == TrafficLight.BLOCKER_TYPES.AI then
		if g_currentMission.aiSystem == nil or g_currentMission.aiSystem.navigationMap == nil then
			self.pendingBlockingPositions[blockerType] = self.pendingBlockingPositions[blockerType] or {}
			local v62_ = self.pendingBlockingPositions[blockerType]
			table.insert(v62_, {
				["movementId"] = movementId,
				["blockerNode"] = blockerNode
			})
			return nil
		end
		v51_, v52_ = findVehicleNavigationMapBlockingPositionInformation(g_currentMission.aiSystem.navigationMap, v54_, v55_, v56_, v57_, v58_, v59_, 1)
		if not entityExists(v51_) then
			Logging.xmlWarning(self.xmlFilename, "Unable to find spline in vehicle navigation blocker \'%s\' z-direction  at %.1f %.1f %.1f", I3DUtil.getNodePath(blockerNode), getWorldTranslation(blockerNode))
			return nil
		end
	end
	local v63_ = self.movements[movementId].blockers or {}
	table.insert(v63_, {
		["blockerType"] = blockerType,
		["spline"] = v51_,
		["splineTime"] = v52_,
		["direction"] = v53_
	})
	self.movements[movementId].blockers = v63_
	self:setMovementBlocker(self.movements[movementId], true)
end

-- Local values: _, blockerData
function TrafficLight:onTrafficSystemLoaded()
	if self.pendingBlockingPositions[TrafficLight.BLOCKER_TYPES.TRAFFIC] ~= nil then
		for _, v65_ in ipairs(self.pendingBlockingPositions[TrafficLight.BLOCKER_TYPES.TRAFFIC]) do
			self:addBlockingPosition(TrafficLight.BLOCKER_TYPES.TRAFFIC, v65_.blockerNode, v65_.movementId)
		end
		self.pendingBlockingPositions[TrafficLight.BLOCKER_TYPES.TRAFFIC] = nil
		if next(self.pendingBlockingPositions) == nil then
			self.pendingBlockingPositions = nil
		end
	end
end

-- Local values: _, blockerData
function TrafficLight:onPedestrianSystemLoaded()
	if self.pendingBlockingPositions[TrafficLight.BLOCKER_TYPES.PEDESTRIAN] ~= nil then
		for _, v67_ in ipairs(self.pendingBlockingPositions[TrafficLight.BLOCKER_TYPES.PEDESTRIAN]) do
			self:addBlockingPosition(TrafficLight.BLOCKER_TYPES.PEDESTRIAN, v67_.blockerNode, v67_.movementId)
		end
		self.pendingBlockingPositions[TrafficLight.BLOCKER_TYPES.PEDESTRIAN] = nil
		if next(self.pendingBlockingPositions) == nil then
			self.pendingBlockingPositions = nil
		end
	end
end

-- Local values: _, blockerData
function TrafficLight:onAISystemLoaded()
	if self.pendingBlockingPositions[TrafficLight.BLOCKER_TYPES.AI] ~= nil then
		for _, v69_ in ipairs(self.pendingBlockingPositions[TrafficLight.BLOCKER_TYPES.AI]) do
			self:addBlockingPosition(TrafficLight.BLOCKER_TYPES.AI, v69_.blockerNode, v69_.movementId)
		end
		self.pendingBlockingPositions[TrafficLight.BLOCKER_TYPES.AI] = nil
		if next(self.pendingBlockingPositions) == nil then
			self.pendingBlockingPositions = nil
		end
	end
end

function TrafficLight:writeStream(streamId, connection)
	TrafficLight:superClass().writeStream(self, streamId, connection)
	if not connection:getIsServer() then
		streamWriteUIntN(streamId, self.currentPhaseIndex, self.phasesNumBits)
	end
end

function TrafficLight:readStream(streamId, connection, objectId)
	TrafficLight:superClass().readStream(self, streamId, connection)
	if connection:getIsServer() then
		self:setPhase(streamReadUIntN(streamId, self.phasesNumBits))
	end
end

function TrafficLight:writeUpdateStream(streamId, connection, dirtyMask)
	TrafficLight:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	local v80_ = streamWriteBool
	local v81_ = self.phaseDirtyFlag
	if v80_(streamId, bit32.band(dirtyMask, v81_) ~= 0) then
		streamWriteUIntN(streamId, self.currentPhaseIndex, self.phasesNumBits)
	end
end

function TrafficLight:readUpdateStream(streamId, timestamp, connection)
	TrafficLight:superClass().readUpdateStream(self, streamId, timestamp, connection)
	if streamReadBool(streamId) then
		self:setPhase(streamReadUIntN(streamId, self.phasesNumBits))
	end
end

-- Local values: phaseArrangement
function TrafficLight:update(dt)
	if self.isServer then
		if g_time >= self.nextPhaseTime then
			self.currentPhaseArrangementIndex = self.currentPhaseArrangementIndex + 1
			if self.currentPhaseArrangementIndex > #self.phaseArrangement then
				self.currentPhaseArrangementIndex = 1
			end
			self:setPhase(self.phaseArrangement[self.currentPhaseArrangementIndex].phase.index)
		elseif not self.raiseActiveTimer:getIsRunning() then
			self.raiseActiveTimer:setDuration(5000)
			self.raiseActiveTimer:start()
		end
	else
		return
	end
end

-- Local values: phase, _, movement, movementId, movementChange, movement, duration
function TrafficLight:setPhase(index)
	local v89_ = self.phases[index]
	if v89_ ~= nil then
		self.currentPhaseIndex = index
		if table.size(v89_.movements) == 0 then
			for _, v90_ in pairs(self.movements) do
				self:setMovementState(v90_, "RED")
			end
		else
			for v91_, v92_ in pairs(v89_.movements) do
				local v93_ = self.movements[v91_]
				if v93_.signals ~= nil then
					self:setMovementState(v93_, v92_.setTo)
				end
				if v93_.blockers ~= nil then
					self:setMovementBlocker(v93_, v92_.doBlock)
				end
			end
		end
		if self.isServer then
			local v94_ = self.phaseArrangement[self.currentPhaseArrangementIndex].duration
			self.nextPhaseTime = g_time + v94_
			self.raiseActiveTimer:setDuration(v94_)
			self.raiseActiveTimer:start()
			self:raiseDirtyFlags(self.phaseDirtyFlag)
		end
	end
end

-- Local values: _, signal
function TrafficLight:setMovementState(movement, state)
	if movement.signals ~= nil then
		for _, v97_ in ipairs(movement.signals) do
			if v97_.red ~= nil then
				setVisibility(v97_.red, state == "RED" and true or state == "RED_AMBER")
			end
			if v97_.amber ~= nil then
				setVisibility(v97_.amber, state == "AMBER" and true or state == "RED_AMBER")
			end
			if v97_.green ~= nil then
				setVisibility(v97_.green, state == "GREEN")
			end
		end
	end
end

-- Local values: _, blocker
function TrafficLight:setMovementBlocker(movement, doBlock)
	if movement.blockers ~= nil then
		for _, v100_ in ipairs(movement.blockers) do
			if v100_.blockerType == TrafficLight.BLOCKER_TYPES.TRAFFIC then
				setTrafficSystemBlockingPositionState(g_currentMission.trafficSystem.trafficSystemId, v100_.spline, v100_.splineTime, doBlock)
			elseif v100_.blockerType == TrafficLight.BLOCKER_TYPES.PEDESTRIAN then
				setPedestrianSystemBlockingPositionState(g_currentMission.pedestrianSystem.pedestrianSystemId, v100_.spline, v100_.splineTime, v100_.direction, doBlock)
			elseif v100_.blockerType == TrafficLight.BLOCKER_TYPES.AI then
				setVehicleNavigationMapBlockingPositionState(g_currentMission.aiSystem.navigationMap, v100_.spline, v100_.splineTime, doBlock)
			end
		end
	end
end

-- Local values: text
function TrafficLight:drawDebug()
	if not g_gui:getIsGuiVisible() and DebugUtil.isPositionInCameraRange(self.cx, self.cy, self.cz, 150) then
		local v102_ = string.format("        currentPhase = %s (index: %d) (dur: %.2fs)\n        nextPhaseTime = %d\n        g_time = %d\n        currentArrangement = %d", self.phases[self.currentPhaseIndex].id, self.currentPhaseIndex, self.raiseActiveTimer:getDuration() / 1000, self.nextPhaseTime, g_time, self.currentPhaseArrangementIndex)
		DebugText.renderAtPosition(self.cx, self.cy, self.cz, v102_, nil, 0.012)
	end
end
