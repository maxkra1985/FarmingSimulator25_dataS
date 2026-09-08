-- Local values: RailroadCrossing_mt
RailroadCrossing = {}
RailroadCrossing.STATE_OPEN = 1
RailroadCrossing.STATE_CLOSING = 2
RailroadCrossing.STATE_CLOSED = 3
RailroadCrossing.STATE_OPENING = 4
RailroadCrossing.TRAFFIC_BLOCKING_NODE_MAX_DISTANCE = 2
local RailroadCrossing_mt = Class(RailroadCrossing)

function RailroadCrossing.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#rootNode", "Root node")
	schema:register(XMLValueType.FLOAT, basePath .. ".activation#startDistance", "Activation start distance", 50)
	schema:register(XMLValueType.FLOAT, basePath .. ".activation#endDistance", "Activation end distance", 50)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".gates.gate(?)#node", "Gate node")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".gates.gate(?)#startRot", "Start rotation")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".gates.gate(?)#startTrans", "Start translation")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".gates.gate(?)#endRot", "End rotation")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".gates.gate(?)#endTrans", "End translation")
	schema:register(XMLValueType.FLOAT, basePath .. ".gates.gate(?)#duration", "Move duration (sec)", 3)
	schema:register(XMLValueType.FLOAT, basePath .. ".gates.gate(?)#closingOffset", "Closing offset (sec)", 0)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".signals.signal(?)#node", "Signal node, can be self-illum shape, add optional real light as child")
	schema:register(XMLValueType.BOOL, basePath .. ".signals.signal(?)#alternatingLights", "True if light should blink in opposite", false)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".trafficBlockers.blocker(?)#node", "Traffic blocking node, also works for AI if it drives on a traffic system spline. Use one per road lane")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".aiNavigationBlockers.blocker(?)#node", "AI navigation blocking node. Only for ai splines, which are not part of the traffic system. Use one per spline")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".pedestrianBlockers.blocker(?)#node", "Pedestrian blocking node. Use one per spline")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "crossing")
end

-- Upvalues: RailroadCrossing_mt
-- Local values: self
function RailroadCrossing.new(isServer, isClient, trainSystem, nodeId, customMt)
	-- upvalues: (copy) RailroadCrossing_mt
	local v9_ = customMt or RailroadCrossing_mt
	local v10_ = setmetatable({}, v9_)
	v10_.trainSystem = trainSystem
	v10_.nodeId = nodeId
	v10_.isServer = isServer
	v10_.isClient = isClient
	v10_.state = RailroadCrossing.STATE_OPEN
	return v10_
end

-- Local values: lightsProfile
function RailroadCrossing:loadFromXML(xmlFile, key, components, i3dMappings)
	self.rootNode = xmlFile:getValue(key .. "#rootNode", nil, components, i3dMappings)
	self.startDistance = xmlFile:getValue(key .. ".activation#startDistance", 50)
	self.endDistance = xmlFile:getValue(key .. ".activation#endDistance", 50)
	self.isActive = false
	self.splinePositionTime = 0
	self.doCloseCrossing = false
	self.gateDirection = 1
	self.gates = {}
	self.signals = {}
	self.trafficBlockers = {}
	self.trafficBlockersPending = {}
	self.aiNavigationBlockers = {}
	self.aiNavigationBlockersPending = {}
	self.pedestrianBlockers = {}
	self.pedestrianBlockersPending = {}
	self.samples = {}
	xmlFile:iterate(string.format("%s.gates.gate", key), function(_, p16_)
		-- upvalues: (copy) xmlFile, (copy) components, (copy) i3dMappings, (copy) self
		local v17_ = xmlFile:getValue(p16_ .. "#node", nil, components, i3dMappings)
		if v17_ ~= nil then
			local v18_ = AnimCurve.new(linearInterpolatorTransRot)
			local v19_, v20_, v21_ = xmlFile:getValue(p16_ .. "#startRot", { getRotation(v17_) })
			local v22_, v23_, v24_ = xmlFile:getValue(p16_ .. "#startTrans", { getTranslation(v17_) })
			v18_:addKeyframe({
				["x"] = v22_,
				["y"] = v23_,
				["z"] = v24_,
				["rx"] = v19_,
				["ry"] = v20_,
				["rz"] = v21_,
				["time"] = 0
			})
			setTranslation(v17_, v22_, v23_, v24_)
			setRotation(v17_, v19_, v20_, v21_)
			local v25_, v26_, v27_ = xmlFile:getValue(p16_ .. "#endRot", { v19_, v20_, v21_ })
			local v28_, v29_, v30_ = xmlFile:getValue(p16_ .. "#endTrans", { v22_, v23_, v24_ })
			v18_:addKeyframe({
				["x"] = v28_,
				["y"] = v29_,
				["z"] = v30_,
				["rx"] = v25_,
				["ry"] = v26_,
				["rz"] = v27_,
				["time"] = 1
			})
			local v31_ = xmlFile:getValue(p16_ .. "#duration", 3) * 1000
			local v32_ = xmlFile:getValue(p16_ .. "#closingOffset", 0) * 1000
			local v33_ = self.gates
			table.insert(v33_, {
				["node"] = v17_,
				["animCurve"] = v18_,
				["duration"] = v31_,
				["closingOffset"] = v32_,
				["animTime"] = 0,
				["currentOffset"] = 0
			})
		end
	end)
	local v_u_34_ = g_gameSettings:getValue(GameSettings.SETTING.LIGHTS_PROFILE)
	xmlFile:iterate(string.format("%s.signals.signal", key), function(_, p35_)
		-- upvalues: (copy) xmlFile, (copy) components, (copy) i3dMappings, (copy) v_u_34_, (copy) self
		local v36_ = xmlFile:getValue(p35_ .. "#node", nil, components, i3dMappings)
		if v36_ ~= nil then
			setVisibility(v36_, false)
			local v37_ = {
				["node"] = v36_,
				["alternatingLights"] = xmlFile:getValue(p35_ .. "#alternatingLights", false),
				["lights"] = {}
			}
			for v38_ = 0, getNumOfChildren(v37_.node) - 1 do
				local v39_ = {
					["node"] = getChildAt(v37_.node, v38_)
				}
				if getNumOfChildren(v39_.node) > 0 then
					v39_.realLight = getChildAt(v39_.node, 0)
					if v_u_34_ >= GS_PROFILE_HIGH then
						v39_.defaultColor = { getLightColor(v39_.realLight) }
					else
						setVisibility(v39_.realLight, false)
						v39_.realLight = nil
					end
				end
				if v37_.alternatingLights and #v37_.lights % 2 == 0 then
					if getHasClassId(v39_.node, ClassIds.SHAPE) then
						setShaderParameter(v39_.node, "blinkOffset", 0.5, 0, 0, 0, false)
					end
					if v39_.realLight ~= nil then
						setLightColor(v39_.realLight, v39_.defaultColor[1] * 0.2, v39_.defaultColor[2] * 0.2, v39_.defaultColor[3] * 0.2)
					end
				end
				local v40_ = v37_.lights
				table.insert(v40_, v39_)
			end
			local v41_ = self.signals
			table.insert(v41_, v37_)
		end
	end)
	if g_server ~= nil then
		if g_currentMission.trafficSystem ~= nil then
			xmlFile:iterate(string.format("%s.trafficBlockers.blocker", key), function(_, p42_)
				-- upvalues: (copy) xmlFile, (copy) components, (copy) i3dMappings, (copy) self
				local v43_ = xmlFile:getValue(p42_ .. "#node", nil, components, i3dMappings)
				if v43_ ~= nil then
					local v44_ = self.trafficBlockersPending
					table.insert(v44_, {
						["blockerNode"] = v43_,
						["blockerKey"] = p42_
					})
				end
			end)
		end
		if g_currentMission.aiSystem ~= nil then
			xmlFile:iterate(string.format("%s.aiNavigationBlockers.blocker", key), function(_, p45_)
				-- upvalues: (copy) xmlFile, (copy) components, (copy) i3dMappings, (copy) self
				local v46_ = xmlFile:getValue(p45_ .. "#node", nil, components, i3dMappings)
				if v46_ ~= nil then
					local v47_ = self.aiNavigationBlockersPending
					table.insert(v47_, {
						["blockerNode"] = v46_,
						["blockerKey"] = p45_
					})
				end
			end)
		end
	end
	if g_currentMission.pedestrianSystem ~= nil then
		xmlFile:iterate(string.format("%s.pedestrianBlockers.blocker", key), function(_, p48_)
			-- upvalues: (copy) xmlFile, (copy) components, (copy) i3dMappings, (copy) self
			local v49_ = xmlFile:getValue(p48_ .. "#node", nil, components, i3dMappings)
			if v49_ ~= nil then
				local v50_ = self.pedestrianBlockersPending
				table.insert(v50_, {
					["blockerNode"] = v49_,
					["blockerKey"] = p48_
				})
			end
		end)
	end
	if g_client ~= nil then
		self.samples.crossing = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "crossing", g_currentMission.loadingMapBaseDirectory, components, 0, AudioGroup.ENVIRONMENT, i3dMappings, self)
		self.isCrossingSamplePlaying = false
	end
	self.trainSystem:addSplinePositionUpdateListener(self)
	return true
end

function RailroadCrossing:delete()
	if self.isClient then
		g_soundManager:deleteSample(self.samples.crossing)
		self.samples.crossing = nil
	end
	self:setBlockingPositionsState(false)
end

function RailroadCrossing:findBlockingPositions()
	self:findTrafficSystemBlockingPositions()
	self.findAiBlockersNextFrame = true
	self:findPedestrianSystemBlockingPositions()
end

-- Local values: trafficSystem, _, blocker, blockerNode, blockerKey, wx, wy, wz, dx, dy, dz, splineId, splineTime
function RailroadCrossing:findTrafficSystemBlockingPositions()
	local v54_ = g_currentMission.trafficSystem
	if v54_ ~= nil then
		for _, v55_ in ipairs(self.trafficBlockersPending) do
			local v56_ = v55_.blockerNode
			local v57_ = v55_.blockerKey
			local v58_, v59_, v60_ = getWorldTranslation(v56_)
			local v61_, v62_, v63_ = localDirectionToWorld(v56_, 0, 0, 1)
			local v64_, v65_ = findTrafficSystemBlockingPositionInformation(v54_.trafficSystemId, v58_, v59_, v60_, v61_, v62_, v63_, RailroadCrossing.TRAFFIC_BLOCKING_NODE_MAX_DISTANCE)
			if v64_ == 0 then
				Logging.warning("Unable to find traffic spline for traffic blocker (%s) %s at %.1f %.1f %.1f", v57_, getName(v56_), getWorldTranslation(v56_))
			else
				local v66_ = self.trafficBlockers
				table.insert(v66_, {
					["blockerNode"] = v56_,
					["splineId"] = v64_,
					["splineTime"] = v65_
				})
			end
		end
	end
	self.trafficBlockersPending = nil
end

-- Local values: aiSystem, _, blocker, blockerNode, blockerKey, wx, wy, wz, dx, dy, dz, splineId, splineTime
function RailroadCrossing:findVehicleNavigationMapBlockingPositions()
	local v68_ = g_currentMission.aiSystem
	if v68_ ~= nil then
		for _, v69_ in ipairs(self.aiNavigationBlockersPending) do
			local v70_ = v69_.blockerNode
			local v71_ = v69_.blockerKey
			local v72_, v73_, v74_ = getWorldTranslation(v70_)
			local v75_, v76_, v77_ = localDirectionToWorld(v70_, 0, 0, 1)
			local v78_, v79_ = findVehicleNavigationMapBlockingPositionInformation(v68_.navigationMap, v72_, v73_, v74_, v75_, v76_, v77_, RailroadCrossing.TRAFFIC_BLOCKING_NODE_MAX_DISTANCE)
			if entityExists(v78_) then
				local v80_ = self.aiNavigationBlockers
				table.insert(v80_, {
					["blockerNode"] = v70_,
					["splineId"] = v78_,
					["splineTime"] = v79_
				})
			else
				Logging.warning("Unable to find ai navigation spline for ai navigation blocker (%s) %s at %.1f %.1f %.1f", v71_, getName(v70_), getWorldTranslation(v70_))
			end
		end
	end
	self.aiNavigationBlockersPending = nil
end

-- Local values: pedestrianSystem, _, blocker, blockerNode, blockerKey, wx, wy, wz, dx, dy, dz, splineId, splineTime, direction
function RailroadCrossing:findPedestrianSystemBlockingPositions()
	local v82_ = g_currentMission.pedestrianSystem
	for _, v83_ in ipairs(self.pedestrianBlockersPending) do
		local v84_ = v83_.blockerNode
		local v85_ = v83_.blockerKey
		local v86_, v87_, v88_ = getWorldTranslation(v84_)
		local v89_, v90_, v91_ = localDirectionToWorld(v84_, 0, 0, 1)
		local v92_, v93_, v94_ = findPedestrianSystemBlockingPositionInformation(v82_.pedestrianSystemId, v86_, v87_, v88_, v89_, v90_, v91_, RailroadCrossing.TRAFFIC_BLOCKING_NODE_MAX_DISTANCE)
		if v92_ == 0 then
			Logging.warning("Unable to find pedestrian spline for pedestrian blocker (%s) %s at %.1f %.1f %.1f", v85_, getName(v84_), getWorldTranslation(v84_))
		else
			local v95_ = self.pedestrianBlockers
			table.insert(v95_, {
				["blockerNode"] = v84_,
				["splineId"] = v92_,
				["splineTime"] = v93_,
				["direction"] = v94_
			})
		end
	end
	self.pedestrianBlockersPending = nil
end

-- Local values: trafficSystem, aiSystem, pedestrianSystem, _, blocker, _, blocker, _, blocker
function RailroadCrossing:setBlockingPositionsState(state)
	local v98_ = g_currentMission.trafficSystem
	local v99_ = g_currentMission.aiSystem
	local v100_ = g_currentMission.pedestrianSystem
	if v98_ ~= nil and v98_.trafficSystemId ~= nil then
		for _, v101_ in ipairs(self.trafficBlockers) do
			setTrafficSystemBlockingPositionState(v98_.trafficSystemId, v101_.splineId, v101_.splineTime, state)
		end
	end
	if v99_ ~= nil and v99_.navigationMap ~= nil then
		for _, v102_ in ipairs(self.aiNavigationBlockers) do
			setVehicleNavigationMapBlockingPositionState(v99_.navigationMap, v102_.splineId, v102_.splineTime, state)
		end
	end
	if v100_ ~= nil and v100_.pedestrianSystemId ~= nil then
		for _, v103_ in ipairs(self.pedestrianBlockers) do
			setPedestrianSystemBlockingPositionState(v100_.pedestrianSystemId, v103_.splineId, v103_.splineTime, v103_.direction, state)
		end
	end
end

function RailroadCrossing:setSplineTimeByPosition(t, splineLength)
	local v107_ = SplineUtil.getValidSplineTime(t)
	self.splinePositionTime = v107_
	self.startTime = v107_ - self.startDistance / splineLength
	self.endTime = v107_ + self.endDistance / splineLength
end

-- Local values: isAnimDone, shaderTime, alpha, alpha2, _, signal, k, light, currentAlpha
function RailroadCrossing:update(dt)
	if self.findAiBlockersNextFrame then
		self:findVehicleNavigationMapBlockingPositions()
		self.findAiBlockersNextFrame = nil
	end
	if (self.state == RailroadCrossing.STATE_CLOSING or self.state == RailroadCrossing.STATE_OPENING) and self:updateGates(dt, self.gateDirection) then
		if self.state == RailroadCrossing.STATE_CLOSING then
			self.state = RailroadCrossing.STATE_CLOSED
		elseif self.state == RailroadCrossing.STATE_OPENING then
			self:finishOpenGates()
		end
	end
	if self.state ~= RailroadCrossing.STATE_OPEN then
		local v110_ = getShaderTimeSec()
		local v111_ = 7 * v110_
		local v112_ = math.cos(v111_) + 0.2
		local v113_ = math.clamp(v112_, 0, 1)
		local v114_ = 7 * v110_ + 3.141592653589793
		local v115_ = math.cos(v114_) + 0.2
		local v116_ = math.clamp(v115_, 0, 1)
		for _, v117_ in ipairs(self.signals) do
			for v118_, v119_ in ipairs(v117_.lights) do
				if v119_.realLight ~= nil then
					local v120_
					if v117_.alternatingLights then
						if v118_ % 2 == 1 then
							v120_ = v116_
						else
							v120_ = v113_
						end
					else
						v120_ = v113_
					end
					setLightColor(v119_.realLight, v119_.defaultColor[1] * v120_, v119_.defaultColor[2] * v120_, v119_.defaultColor[3] * v120_)
				end
			end
		end
	end
end

-- Local values: isAnimDone, _, gate, sx, sy, sz, rx, ry, rz
function RailroadCrossing:updateGates(dt, direction)
	local v124_ = true
	for _, v125_ in ipairs(self.gates) do
		if v125_.currentOffset == 0 then
			local v126_ = v125_.animTime + direction * dt / v125_.duration
			v125_.animTime = math.clamp(v126_, 0, 1)
			local v127_, v128_, v129_, v130_, v131_, v132_ = v125_.animCurve:get(v125_.animTime)
			setTranslation(v125_.node, v127_, v128_, v129_)
			setRotation(v125_.node, v130_, v131_, v132_)
			if v124_ then
				v124_ = v125_.animTime == 0 and true or v125_.animTime == 1
			end
		else
			local v133_ = v125_.currentOffset - dt
			v125_.currentOffset = math.max(v133_, 0)
			v124_ = false
		end
	end
	return v124_
end

-- Local values: _, signal, _, gate
function RailroadCrossing:startClosingGates()
	self.state = RailroadCrossing.STATE_CLOSING
	for _, v135_ in ipairs(self.signals) do
		setVisibility(v135_.node, true)
	end
	for _, v136_ in ipairs(self.gates) do
		if v136_.animTime == 0 then
			v136_.currentOffset = v136_.closingOffset
		end
	end
	self.gateDirection = 1
	if g_client ~= nil and not self.isCrossingSamplePlaying then
		g_soundManager:playSample(self.samples.crossing)
		self.isCrossingSamplePlaying = true
	end
	self:setBlockingPositionsState(true)
end

function RailroadCrossing:startOpeningGates()
	self.state = RailroadCrossing.STATE_OPENING
	self.gateDirection = -1
end

-- Local values: _, signal
function RailroadCrossing:finishOpenGates()
	self.state = RailroadCrossing.STATE_OPEN
	for _, v139_ in ipairs(self.signals) do
		setVisibility(v139_.node, false)
	end
	if g_client ~= nil and self.isCrossingSamplePlaying then
		g_soundManager:stopSample(self.samples.crossing)
		self.isCrossingSamplePlaying = false
	end
	self:setBlockingPositionsState(false)
end

-- Local values: inRange
function RailroadCrossing:onSplinePositionTimeUpdate(startTime, endTime)
	local v143_ = SplineUtil.getValidSplineTime(startTime)
	local v144_ = SplineUtil.getValidSplineTime(endTime)
	local v145_
	if self.startTime < v143_ and v143_ < self.endTime then
		v145_ = true
	elseif self.startTime < v144_ then
		v145_ = v144_ < self.endTime
	else
		v145_ = false
	end
	if v145_ then
		if self.state == RailroadCrossing.STATE_OPEN or self.state == RailroadCrossing.STATE_OPENING then
			self:startClosingGates()
			return
		end
	elseif self.state == RailroadCrossing.STATE_CLOSED or self.state == RailroadCrossing.STATE_CLOSING then
		self:startOpeningGates()
	end
end

function RailroadCrossing.debugSetDebugNodeState(blockerDebugTable, blocked)
	if blockerDebugTable ~= nil then
		if blockerDebugTable.blockedPosGizmo ~= nil then
			if blocked then
				blockerDebugTable.blockedPosGizmo:setTextColor(Color.PRESETS.RED)
			else
				blockerDebugTable.blockedPosGizmo:setTextColor(Color.PRESETS.GREEN)
			end
		end
		if blockerDebugTable.spline ~= nil then
			setVisibility(blockerDebugTable.spline, blocked)
		end
	end
end
