AIDrivable = {}
AIDrivable.STATES = {}
AIDrivable.STATES[AgentState.DRIVING] = "driving"
AIDrivable.STATES[AgentState.BLOCKED] = "blocked"
AIDrivable.STATES[AgentState.PLANNING] = "planning"
AIDrivable.STATES[AgentState.NOT_REACHABLE] = "not_reachable"
AIDrivable.STATES[AgentState.TARGET_REACHED] = "target_reached"
AIDrivable.TRAILER_LIMIT = 4

function AIDrivable.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(AIVehicle, specializations) and SpecializationUtil.hasSpecialization(AIJobVehicle, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(Drivable, specializations)
	end
	return v2_
end
function AIDrivable.initSpecialization()
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("AI")
	AIDrivable.registerAgentXMLPaths(v3_, "vehicle.ai.agent")
	v3_:setXMLSpecializationType()
end
function AIDrivable.postInitSpecialization()
	local v4_ = Vehicle.xmlSchema
	for _, v5_ in pairs(g_vehicleConfigurationManager:getConfigurations()) do
		local v6_ = v5_.configurationKey .. "(?)"
		v4_:setXMLSharedRegistration("configAIAgent", v6_)
		AIDrivable.registerAgentXMLPaths(v4_, v6_ .. ".aiAgent")
		v4_:resetXMLSharedRegistration("configAIAgent", v6_)
	end
end

function AIDrivable.registerAgentXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. "#width", "AI vehicle width")
	schema:register(XMLValueType.FLOAT, basePath .. "#length", "AI vehicle length")
	schema:register(XMLValueType.FLOAT, basePath .. "#lengthOffset", "AI vehicle length offset")
	schema:register(XMLValueType.FLOAT, basePath .. "#height", "AI vehicle height")
	schema:register(XMLValueType.FLOAT, basePath .. "#frontOffset", "AI vehicle front offset")
	schema:register(XMLValueType.VECTOR_N, basePath .. "#frontWheelIndices", "List of wheels (indices) that are used for steering")
	schema:register(XMLValueType.NODE_INDICES, basePath .. "#frontWheelNodes", "List of wheels (nodes) that are used for steering")
	schema:register(XMLValueType.FLOAT, basePath .. "#maxBrakeAcceleration", "AI vehicle max brake acceleration")
	schema:register(XMLValueType.FLOAT, basePath .. "#maxCentripetalAcceleration", "AI vehicle max centripetal acceleration")
	schema:register(XMLValueType.FLOAT, basePath .. "#maxTurningRadius", "Max. turning radius (overwrites value detected from ackermann steering)")
end

function AIDrivable.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onAIDrivablePrepare")
	SpecializationUtil.registerEvent(vehicleType, "onAIDriveableStart")
	SpecializationUtil.registerEvent(vehicleType, "onAIDriveableActive")
	SpecializationUtil.registerEvent(vehicleType, "onAIDriveableEnd")
end

function AIDrivable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "consoleCommandSetTurnRadius", AIDrivable.consoleCommandSetTurnRadius)
	SpecializationUtil.registerFunction(vehicleType, "consoleCommandMove", AIDrivable.consoleCommandMove)
	SpecializationUtil.registerFunction(vehicleType, "consoleCommandClearPath", AIDrivable.consoleCommandClearPath)
	SpecializationUtil.registerFunction(vehicleType, "createAgent", AIDrivable.createAgent)
	SpecializationUtil.registerFunction(vehicleType, "deleteAgent", AIDrivable.deleteAgent)
	SpecializationUtil.registerFunction(vehicleType, "setAITarget", AIDrivable.setAITarget)
	SpecializationUtil.registerFunction(vehicleType, "unsetAITarget", AIDrivable.unsetAITarget)
	SpecializationUtil.registerFunction(vehicleType, "stopAIDriving", AIDrivable.stopAIDriving)
	SpecializationUtil.registerFunction(vehicleType, "reachedAITarget", AIDrivable.reachedAITarget)
	SpecializationUtil.registerFunction(vehicleType, "getAIRootNode", AIDrivable.getAIRootNode)
	SpecializationUtil.registerFunction(vehicleType, "setAIRootNodeDirty", AIDrivable.setAIRootNodeDirty)
	SpecializationUtil.registerFunction(vehicleType, "getAIRootNodeMinZOffset", AIDrivable.getAIRootNodeMinZOffset)
	SpecializationUtil.registerFunction(vehicleType, "getAIRootNodeMaxZOffset", AIDrivable.getAIRootNodeMaxZOffset)
	SpecializationUtil.registerFunction(vehicleType, "getAIRootNodeBoundingBox", AIDrivable.getAIRootNodeBoundingBox)
	SpecializationUtil.registerFunction(vehicleType, "getAIAllowsBackwards", AIDrivable.getAIAllowsBackwards)
	SpecializationUtil.registerFunction(vehicleType, "drawDebugAIAgent", AIDrivable.drawDebugAIAgent)
	SpecializationUtil.registerFunction(vehicleType, "debugGetAgentHasSpaceAt", AIDrivable.debugGetAgentHasSpaceAt)
	SpecializationUtil.registerFunction(vehicleType, "loadAgentInfoFromXML", AIDrivable.loadAgentInfoFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getAIAgentSize", AIDrivable.getAIAgentSize)
	SpecializationUtil.registerFunction(vehicleType, "getAIAgentMaxBrakeAcceleration", AIDrivable.getAIAgentMaxBrakeAcceleration)
	SpecializationUtil.registerFunction(vehicleType, "updateAIAgentAttachments", AIDrivable.updateAIAgentAttachments)
	SpecializationUtil.registerFunction(vehicleType, "addAIAgentAttachment", AIDrivable.addAIAgentAttachment)
	SpecializationUtil.registerFunction(vehicleType, "startNewAIAgentAttachmentChain", AIDrivable.startNewAIAgentAttachmentChain)
	SpecializationUtil.registerFunction(vehicleType, "updateAIAgentAttachmentOffsetData", AIDrivable.updateAIAgentAttachmentOffsetData)
	SpecializationUtil.registerFunction(vehicleType, "updateAIAgentPoseData", AIDrivable.updateAIAgentPoseData)
	SpecializationUtil.registerFunction(vehicleType, "prepareForAIDriving", AIDrivable.prepareForAIDriving)
	SpecializationUtil.registerFunction(vehicleType, "getAITurningRadius", AIDrivable.getAITurningRadius)
end

function AIDrivable.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanStartAIVehicle", AIDrivable.getCanStartAIVehicle)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIJobSupported", AIDrivable.getIsAIJobSupported)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanHaveAIVehicleObstacle", AIDrivable.getCanHaveAIVehicleObstacle)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIReadyToDrive", AIDrivable.getIsAIReadyToDrive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIPreparingToDrive", AIDrivable.getIsAIPreparingToDrive)
end

function AIDrivable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AIDrivable)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AIDrivable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AIDrivable)
	SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", AIDrivable)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", AIDrivable)
	SpecializationUtil.registerEventListener(vehicleType, "onCruiseControlSpeedChanged", AIDrivable)
end

-- Local values: spec
function AIDrivable:onLoad(savegame)
	local v14_ = self.spec_aiDrivable
	v14_.agentInfo = {}
	v14_.agentInfo.isValid = false
	self:loadAgentInfoFromXML(self.xmlFile, v14_.agentInfo)
	v14_.maxSpeed = math.huge
	v14_.isRunning = false
	v14_.useManualDriving = false
	v14_.lastState = nil
	v14_.lastIsBlocked = false
	v14_.lastMaxSpeed = 0
	v14_.cruiseControlLimit = math.huge
	v14_.stuckTime = 0
	v14_.agentId = nil
	v14_.targetX = nil
	v14_.targetY = nil
	v14_.targetZ = nil
	v14_.targetDirX = nil
	v14_.targetDirY = nil
	v14_.targetDirZ = nil
	v14_.lastNoSpaceAtStart = false
	v14_.lastNoSpaceAtTarget = false
	v14_.aiRootNodeBoundingBox = {
		0,
		1,
		0,
		1,
		0,
		1
	}
	v14_.attachments = {}
	v14_.attachmentChains = {}
	v14_.attachmentChainIndex = 1
	v14_.attachmentsTrailerOffsetData = {}
	v14_.attachmentsMaxWidth = 0
	v14_.attachmentsMaxHeight = 0
	v14_.attachmentsMaxLengthOffsetPos = 0
	v14_.attachmentsMaxLengthOffsetNeg = 0
	v14_.poseData = {}
	v14_.debugVehicle = nil
	v14_.debugSizeBox = DebugBox.new()
	v14_.debugSizeBox:setColorRGBA(0, 1, 1)
	v14_.debugSizeBox:setText("agentSize")
	v14_.debugSizeBox:setTextSize(0.012)
	v14_.debugFrontMarker = DebugGizmo.new()
	v14_.debugDump = nil
end

-- Local values: spec, aiRootNode, _, attacherJoint, node, xDir, yDir, zDir, xUp, yUp, zUp, x, y, z, _, _, zOffset, z, numPositions, i, wheelNode, wheel, _, _, rz, i, wheelIndex, wheel, _, _, rz
function AIDrivable:onPostLoad()
	local v16_ = self.spec_aiDrivable
	local v17_ = self:getAIRootNode()
	v16_.attacherJointOffsets = {}
	if self.getAttacherJoints ~= nil then
		for _, v18_ in ipairs(self:getAttacherJoints()) do
			local v19_ = v18_.jointTransform
			local v20_, v21_, v22_ = localDirectionToLocal(v19_, v17_, 0, 0, 1)
			local v23_, v24_, v25_ = localDirectionToLocal(v19_, v17_, 0, 1, 0)
			local v26_, v27_, v28_ = localToLocal(v19_, v17_, 0, 0, 0)
			local v29_ = v16_.attacherJointOffsets
			table.insert(v29_, {
				["x"] = v26_,
				["y"] = v27_,
				["z"] = v28_,
				["xDir"] = v20_,
				["yDir"] = v21_,
				["zDir"] = v22_,
				["xUp"] = v23_,
				["yUp"] = v24_,
				["zUp"] = v25_
			})
		end
	end
	if v16_.agentInfo.isDefined then
		if v16_.agentInfo.width == nil or (v16_.agentInfo.length == nil or v16_.agentInfo.height == nil) then
			v16_.agentInfo.width = v16_.agentInfo.width or self.size.width
			v16_.agentInfo.height = v16_.agentInfo.height or self.size.height
			if v16_.agentInfo.length == nil then
				v16_.agentInfo.length = self.size.length
				local _, _, v30_ = localToLocal(v17_, self.rootNode, 0, 0, 0)
				v16_.agentInfo.lengthOffset = -v30_ + self.size.lengthOffset
			end
		end
		if v16_.agentInfo.frontWheelIndices ~= nil or v16_.agentInfo.frontWheelNodes ~= nil then
			local v31_ = 0
			local v32_ = 0
			if v16_.agentInfo.frontWheelNodes == nil or #v16_.agentInfo.frontWheelNodes <= 0 then
				if v16_.agentInfo.frontWheelIndices ~= nil and #v16_.agentInfo.frontWheelIndices > 0 then
					for _, v33_ in ipairs(v16_.agentInfo.frontWheelIndices) do
						local v34_ = self:getWheelFromWheelIndex(v33_)
						if v34_ == nil then
							Logging.xmlWarning(self.xmlFile, "Unknown wheel index \'%d\' found for ai agent definition.", v33_)
						else
							local _, _, v35_ = localToLocal(v34_.repr, v17_, 0, 0, 0)
							v31_ = v31_ + v35_
							v32_ = v32_ + 1
						end
					end
				end
			else
				for _, v36_ in ipairs(v16_.agentInfo.frontWheelNodes) do
					local v37_ = self:getWheelByWheelNode(v36_)
					if v37_ == nil then
						Logging.xmlWarning(self.xmlFile, "Node wheel for node \'%s\' found for ai agent definition.", getName(v36_))
					else
						local _, _, v38_ = localToLocal(v37_.repr, v17_, 0, 0, 0)
						v31_ = v31_ + v38_
						v32_ = v32_ + 1
					end
				end
			end
			if v32_ > 0 then
				v16_.agentInfo.frontOffset = v31_ / v32_
			end
		end
	end
	v16_.agentInfo.isValid = (v16_.agentInfo.width ~= nil or v16_.agentInfo.length ~= nil) and true or v16_.agentInfo.height ~= nil
	v16_.debugSizeBox:setText(string.format("agentSize\nw:%.2f l:%.2f h:%.2f", v16_.agentInfo.width or 0, v16_.agentInfo.length or 0, v16_.agentInfo.height or 0))
	self:setAIRootNodeDirty()
end

-- Local values: spec, isStillBlocked, isCurrentlyBlocked, isBlocked, aiRootNode, x, y, z, lastSpeed, maxSpeed, tx, _, tz, dirX, dirY, dirZ, curvature, maxSpeedCurvature, status
function AIDrivable:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v41_ = self.spec_aiDrivable
	if self.isServer and v41_.isRunning then
		local v42_ = v41_.lastIsBlocked
		if v42_ then
			v42_ = self:getLastSpeed() < 5
		end
		local v43_ = v41_.lastMaxSpeed
		local v44_
		if math.abs(v43_) > 0 then
			v44_ = self:getLastSpeed() < 1
		else
			v44_ = false
		end
		if v44_ or v42_ then
			v41_.stuckTime = v41_.stuckTime + dt
		else
			v41_.stuckTime = 0
		end
		local v45_ = v41_.stuckTime > 5000
		local v46_ = self:getAIRootNode()
		local v47_, v48_, v49_ = getWorldTranslation(v46_)
		v41_.distanceToTarget = MathUtil.vector2Length(v47_ - v41_.targetX, v49_ - v41_.targetZ)
		local v50_ = self.lastSpeedReal * self.movingDirection * 1000
		local v51_ = v41_.maxSpeed
		local v52_ = v41_.cruiseControlLimit
		local v53_ = math.min(v51_, v52_)
		if v41_.useManualDriving then
			local v54_, _, v55_ = worldToLocal(v46_, v41_.targetX, v41_.targetY, v41_.targetZ)
			AIVehicleUtil.driveToPoint(self, dt, 1, true, true, v54_, v55_, v53_, false)
			v41_.lastMaxSpeed = v53_
			if v41_.distanceToTarget < 0.5 then
				self:reachedAITarget()
			end
		else
			local v56_, v57_, v58_ = localDirectionToWorld(v46_, 0, 0, 1)
			self:updateAIAgentPoseData()
			local v59_, v60_, v61_ = getVehicleNavigationAgentNextCurvature(v41_.agentId, v41_.poseData, (math.abs(v50_)))
			if v41_.debugDump ~= nil then
				v41_.debugDump:addData(dt, v47_, v48_, v49_, v56_, v57_, v58_, v50_, v59_, v53_, v61_)
			end
			if v61_ == AgentState.DRIVING then
				local v62_ = v60_ * 3.6
				v53_ = math.min(v62_, v53_)
				AIVehicleUtil.driveAlongCurvature(self, dt, v59_, v53_, 1)
				if v53_ == 0 then
					v45_ = false
				end
			elseif v61_ == AgentState.PLANNING then
				self:stopAIDriving()
				self:brake(1)
				v45_ = false
			elseif v61_ == AgentState.BLOCKED then
				self:stopAIDriving()
				v45_ = true
			elseif v61_ == AgentState.TARGET_REACHED then
				self:reachedAITarget()
				v45_ = false
			elseif v61_ == AgentState.NOT_REACHABLE then
				self:stopCurrentAIJob(AIMessageErrorNotReachable.new())
				v45_ = false
			end
			v41_.lastState = v61_
			v41_.lastMaxSpeed = v53_
		end
		if v41_.debugVehicle ~= nil then
			v41_.debugVehicle:update(dt)
		end
		if not v45_ and v41_.stuckTime > 5000 then
			v41_.stuckTime = 0
		end
		if v45_ and not v41_.lastIsBlocked then
			g_server:broadcastEvent(AIVehicleIsBlockedEvent.new(self, true), true, nil, self)
		elseif not v45_ and v41_.lastIsBlocked then
			g_server:broadcastEvent(AIVehicleIsBlockedEvent.new(self, false), true, nil, self)
		end
		v41_.lastIsBlocked = v45_
		SpecializationUtil.raiseEvent(self, "onAIDriveableActive")
	end
end

-- Local values: spec, trailerData, navigationMapId, agent, width, length, lengthOffset, frontOffset, height, maxBrakeAcceleration, maxCentripetalAcceleration, minTurningRadius, minLandingTurningRadius, allowBackwards
function AIDrivable:createAgent(helperIndex)
	if self.isServer then
		local v64_ = self.spec_aiDrivable
		v64_.cruiseControlLimit = math.huge
		self:updateAIAgentAttachments()
		local v65_ = v64_.attachmentsTrailerOffsetData
		local v66_ = g_currentMission.aiSystem:getNavigationMap()
		local v67_ = v64_.agentInfo
		local v68_, v69_, v70_, v71_, v72_ = self:getAIAgentSize()
		local v73_ = self:getAIAgentMaxBrakeAcceleration()
		local v74_ = v67_.maxCentripetalAcceleration
		local v75_ = self:getAITurningRadius(v67_.maxTurningRadius or self.maxTurningRadius)
		local v76_ = self:getAIAllowsBackwards()
		v64_.agentId = createVehicleNavigationAgent(v66_, v75_, v75_, v76_, v68_, v72_, v69_, v70_, v71_, v73_, v74_, v65_)
		setName(v64_.agentId, string.format("%s - %s", getName(v64_.agentId), self.configFileNameClean))
		g_currentMission.aiSystem:addAgent(v64_.agentId, self)
		self:setAIVehicleObstacleStateDirty()
		if g_currentMission.aiSystem.debugEnabled then
			if v64_.debugVehicle ~= nil then
				v64_.debugVehicle:delete()
			end
			v64_.debugVehicle = AIDebugVehicle.new(self, { math.random(), math.random(), math.random() })
			if v64_.debugDump ~= nil then
				v64_.debugDump:delete()
			end
			v64_.debugDump = AIDebugDump.new(self, v64_.agentId)
			v64_.debugDump:startRecording(v75_, v76_, v68_, v69_, v70_, v71_, v73_, v74_)
		end
		if VehicleDebug.state == VehicleDebug.DEBUG_AI then
			enableVehicleNavigationAgentDebugRendering(v64_.agentId, true)
		end
	end
end

-- Local values: spec
function AIDrivable:deleteAgent()
	local v78_ = self.spec_aiDrivable
	v78_.isRunning = false
	self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF, true)
	if v78_.debugDump ~= nil then
		v78_.debugDump:delete()
		v78_.debugDump = nil
	end
	if v78_.agentId ~= nil then
		if g_currentMission ~= nil and g_currentMission.aiSystem ~= nil then
			g_currentMission.aiSystem:removeAgent(v78_.agentId)
		end
		delete(v78_.agentId)
		v78_.agentId = nil
	end
	self:setAIVehicleObstacleStateDirty()
end

-- Local values: spec, aiRootNode, cx, cy, cz, cDirX, cDirY, cDirZ
function AIDrivable:setAITarget(task, x, y, z, dirX, dirY, dirZ, maxSpeed, useManualDriving)
	local v89_ = self.spec_aiDrivable
	local v90_ = self:getAIRootNode()
	local v91_, v92_, v93_ = getWorldTranslation(v90_)
	local v94_, v95_, v96_ = localDirectionToWorld(v90_, 0, 0, 1)
	v89_.useManualDriving = Utils.getNoNil(useManualDriving, false)
	v89_.isRunning = true
	v89_.task = task
	v89_.maxSpeed = maxSpeed or math.huge
	v89_.targetX = x
	v89_.targetY = y
	v89_.targetZ = z
	v89_.targetDirX = dirX or 0
	v89_.targetDirY = dirY
	v89_.targetDirZ = dirZ or 0
	v89_.distanceToTarget = MathUtil.vector2Length(v91_ - x, v93_ - z)
	v89_.lastNoSpaceAtStart = false
	v89_.lastNoSpaceAtTarget = false
	if not v89_.useManualDriving and self.isServer then
		setVehicleNavigationAgentTarget(v89_.agentId, x, y, z, dirX, dirY, dirZ)
	end
	if v89_.debugVehicle ~= nil then
		v89_.debugVehicle:setTarget(x, y, z, dirX, dirY, dirZ)
	end
	if v89_.debugDump ~= nil then
		if useManualDriving then
			v89_.debugDump:stopPlanningRecording()
		else
			v89_.debugDump:stopPlanningRecording()
			v89_.debugDump:startPlanningRecording()
		end
		v89_.debugDump:setTarget(x, y, z, dirX, dirY, dirZ, v91_, v92_, v93_, v94_, v95_, v96_, v89_.maxSpeed)
	end
	SpecializationUtil.raiseEvent(self, "onAIDriveableStart")
end

-- Local values: spec, lastTask
function AIDrivable:reachedAITarget()
	local v98_ = self.spec_aiDrivable
	if self.isServer then
		local v99_ = v98_.task
		if v99_ ~= nil then
			v99_:onTargetReached()
		end
	end
end

-- Local values: spec
function AIDrivable:unsetAITarget()
	local v101_ = self.spec_aiDrivable
	v101_.isRunning = false
	v101_.task = nil
	v101_.useManualDriving = false
	self:stopAIDriving()
	SpecializationUtil.raiseEvent(self, "onAIDriveableEnd")
end

function AIDrivable:stopAIDriving()
	self:brake(1)
	self:stopVehicle()
	self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF, true)
end

function AIDrivable:getAIRootNode()
	return self.components[1].node
end

-- Local values: spec, aiRootNode, xOffsetPosX, xOffsetPosY, xOffsetPosZ, xOffsetNegX, xOffsetNegY, xOffsetNegZ, yOffsetPosX, yOffsetPosY, yOffsetPosZ, yOffsetNegX, yOffsetNegY, yOffsetNegZ, zOffsetPosX, zOffsetPosY, zOffsetPosZ, zOffsetNegX, zOffsetNegY, zOffsetNegZ, xOffset1, yOffset1, zOffset1, xOffset2, yOffset2, zOffset2, xOffset3, yOffset3, zOffset3, xOffset4, yOffset4, zOffset4, xOffset5, yOffset5, zOffset5, xOffset6, yOffset6, zOffset6, minXOffset, maxXOffset, minYOffset, maxYOffset, minZOffset, maxZOffset
function AIDrivable:setAIRootNodeDirty()
	local v105_ = self.spec_aiDrivable
	local v106_ = self:getAIRootNode()
	local v107_, v108_, v109_ = localToWorld(self.rootNode, self.size.widthOffset + self.size.width * 0.5, 0, 0)
	local v110_, v111_, v112_ = localToWorld(self.rootNode, self.size.widthOffset - self.size.width * 0.5, 0, 0)
	local v113_, v114_, v115_ = localToWorld(self.rootNode, 0, self.size.heightOffset + self.size.height, 0)
	local v116_, v117_, v118_ = localToWorld(self.rootNode, 0, self.size.heightOffset, 0)
	local v119_, v120_, v121_ = localToWorld(self.rootNode, 0, 0, self.size.lengthOffset + self.size.length * 0.5)
	local v122_, v123_, v124_ = localToWorld(self.rootNode, 0, 0, self.size.lengthOffset - self.size.length * 0.5)
	local v125_, v126_, v127_ = worldToLocal(v106_, v107_, v108_, v109_)
	local v128_, v129_, v130_ = worldToLocal(v106_, v110_, v111_, v112_)
	local v131_, v132_, v133_ = worldToLocal(v106_, v113_, v114_, v115_)
	local v134_, v135_, v136_ = worldToLocal(v106_, v116_, v117_, v118_)
	local v137_, v138_, v139_ = worldToLocal(v106_, v119_, v120_, v121_)
	local v140_, v141_, v142_ = worldToLocal(v106_, v122_, v123_, v124_)
	local v143_ = math.min(v125_, v128_, v131_, v134_, v137_, v140_)
	local v144_ = math.max(v125_, v128_, v131_, v134_, v137_, v140_)
	local v145_ = math.min(v126_, v129_, v132_, v135_, v138_, v141_)
	local v146_ = math.max(v126_, v129_, v132_, v135_, v138_, v141_)
	local v147_ = math.min(v127_, v130_, v133_, v136_, v139_, v142_)
	local v148_ = math.max(v127_, v130_, v133_, v136_, v139_, v142_)
	v105_.aiRootNodeBoundingBox[1] = v143_
	v105_.aiRootNodeBoundingBox[2] = v144_
	v105_.aiRootNodeBoundingBox[3] = v145_
	v105_.aiRootNodeBoundingBox[4] = v146_
	v105_.aiRootNodeBoundingBox[5] = v147_
	v105_.aiRootNodeBoundingBox[6] = v148_
end

-- Local values: spec
function AIDrivable:getAIRootNodeMinZOffset()
	return self.spec_aiDrivable.aiRootNodeBoundingBox[5]
end

-- Local values: spec
function AIDrivable:getAIRootNodeMaxZOffset()
	return self.spec_aiDrivable.aiRootNodeBoundingBox[6]
end

-- Local values: spec, boundingBox, aiRootNode, sizeX, sizeY, sizeZ, centerX, centerY, centerZ, vx, vy, vz, qx, qy, qz, qw
function AIDrivable:getAIRootNodeBoundingBox()
	local v152_ = self.spec_aiDrivable.aiRootNodeBoundingBox
	local v153_ = self:getAIRootNode()
	local v154_ = v152_[2] - v152_[1]
	local v155_ = v152_[4] - v152_[3]
	local v156_ = v152_[6] - v152_[5]
	local v157_ = v152_[1] + v154_ * 0.5
	local v158_ = v152_[3] + v155_ * 0.5
	local v159_ = v152_[5] + v156_ * 0.5
	local v160_, v161_, v162_ = localToWorld(v153_, v157_, v158_, v159_)
	local v163_, v164_, v165_, v166_ = getWorldQuaternion(v153_)
	return v160_, v161_, v162_, v163_, v164_, v165_, v166_, v154_ * 0.5, v155_ * 0.5, v156_ * 0.5
end

function AIDrivable:getAIAllowsBackwards()
	return false
end

function AIDrivable:onEnterVehicle(isControlling)
	if isControlling and self.isServer then
		addConsoleCommand("gsAISetTurnRadius", "Set Turn radius", "consoleCommandSetTurnRadius", self)
		addConsoleCommand("gsAIMoveVehicle", "Moves vehicles", "consoleCommandMove", self)
		addConsoleCommand("gsAIClearPath", "Clears debug path", "consoleCommandClearPath", self)
	end
end

function AIDrivable:onLeaveVehicle(wasEntered)
	if wasEntered then
		removeConsoleCommand("gsAISetTurnRadius")
		removeConsoleCommand("gsAIMoveVehicle")
		removeConsoleCommand("gsAIClearPath")
	end
end

-- Local values: spec
function AIDrivable:onCruiseControlSpeedChanged(speed, speedReverse)
	self.spec_aiDrivable.cruiseControlLimit = speed
end

-- Local values: _, vehicle
function AIDrivable:getIsAIReadyToDrive(superFunc)
	for _, v174_ in ipairs(self.rootVehicle.childVehicles) do
		if v174_ ~= self and (v174_.getIsAIReadyToDrive ~= nil and not v174_:getIsAIReadyToDrive()) then
			return false, v174_
		end
	end
	return superFunc(self)
end

-- Local values: _, vehicle
function AIDrivable:getIsAIPreparingToDrive(superFunc)
	for _, v177_ in ipairs(self.rootVehicle.childVehicles) do
		if v177_ ~= self and (v177_.getIsAIPreparingToDrive ~= nil and v177_:getIsAIPreparingToDrive()) then
			return true
		end
	end
	return superFunc(self)
end

-- Local values: spec, aiRootNode, groundOffset, yOffset, storeItem, width, length, lengthOffset, frontOffset, height, fx, fy, fz, dirX, dirY, dirZ, upX, upY, upZ, x, y, z, text, sx, _, sz, sy, lx, _, lz, rx, _, rz, dirX1, dirZ1, maxTurningRadius, currentTurnRadius, minRadius, revTime, debugString, wheelSpec, _, wheel, wsx, wsy, wsz, wdx, wdy, wdz, wlx, _, wlz, wrx, _, wrz, sign, cx, cz
function AIDrivable:drawDebugAIAgent()
	local v179_ = self.spec_aiDrivable
	if v179_.agentInfo.isValid then
		local v180_ = self:getAIRootNode()
		local v181_ = g_storeManager:getItemByXMLFilename(self.configFileName)
		local v182_ = (v181_ == nil or v181_.shopTranslationOffset == nil) and 0 or v181_.shopTranslationOffset[2]
		local v183_, v184_, v185_, v186_, v187_ = self:getAIAgentSize()
		v179_.debugSizeBox:createWithNode(v180_, v183_, v187_, v184_, 0, v187_ * 0.5 - v182_, v185_)
		v179_.debugSizeBox:draw()
		local v188_, v189_, v190_ = localToWorld(v180_, 0, 0, v186_)
		local v191_, v192_, v193_ = localDirectionToWorld(v180_, 0, 0, 1)
		local v194_, v195_, v196_ = localDirectionToWorld(v180_, 0, 1, 0)
		if v189_ > 0 then
			v189_ = getTerrainHeightAtWorldPos(g_terrainNode, v188_, 0, v190_) + 0.15
		end
		v179_.debugFrontMarker:createWithWorldPosAndDir(v188_, v189_, v190_, v191_, v192_, v193_, v194_, v195_, v196_, "FrontMarker", false, nil, 3)
		v179_.debugFrontMarker:draw()
		local v197_, v198_, v199_ = getWorldTranslation(v180_)
		if v179_.isRunning then
			local v200_
			if v179_.useManualDriving then
				v200_ = string.format("Distance: %.2f", v179_.distanceToTarget)
			else
				v200_ = AIDrivable.STATES[v179_.lastState]
			end
			Utils.renderTextAtWorldPosition(v197_, v198_ + 4, v199_, v200_, 0.015, 0, 1, 1, 1, 1)
		end
		if v179_.debugVehicle ~= nil then
			v179_.debugVehicle:setForcedY(v198_ + 0.1)
			v179_.debugVehicle:draw()
		end
		local v201_, _, v202_ = localToWorld(v180_, 0, 0.5, 0)
		local v203_ = getTerrainHeightAtWorldPos(g_terrainNode, v201_, 0, v202_) + 0.15
		local v204_, _, v205_ = localToWorld(v180_, 10, 0.5, 0)
		local v206_, _, v207_ = localToWorld(v180_, -10, 0.5, 0)
		drawDebugLine(v201_, v203_, v202_, 1, 0, 0, v204_, v203_, v205_, 1, 0, 0)
		drawDebugLine(v201_, v203_, v202_, 0, 1, 0, v206_, v203_, v207_, 0, 1, 0)
		local v208_, v209_ = MathUtil.vector2Normalize(v204_ - v201_, v205_ - v202_)
		local v210_ = self.maxTurningRadius
		local v211_ = self:getTurningRadiusByRotTime(self.rotatedTime)
		local v212_ = self:getAITurningRadius(self.maxTurningRadius)
		local v213_ = self:getSteeringRotTimeByCurvature(1 / (v211_ * (self.rotatedTime >= 0 and 1 or -1)))
		local v214_ = string.format("ReferenceRadius: %.3fm\nMinRadius: %.3fm\nCalc Radius: %.3f\nRotatedTime: %.3f\nRevTime: %.3f", v211_, v210_, v212_, self.rotatedTime, v213_)
		Utils.renderTextAtWorldPosition(v201_, v203_ + 5, v202_, v214_, getCorrectTextSize(0.012), 0)
		local v215_ = self.spec_wheels
		for _, v216_ in ipairs(v215_.wheels) do
			if v216_.physics.rotSpeed ~= 0 or self.spec_articulatedAxis ~= nil and self.spec_articulatedAxis.componentJoint ~= nil then
				local v217_, v218_, v219_ = localToWorld(v216_.repr, 0, 0, 0)
				local v220_, v221_, v222_ = localDirectionToWorld(v216_.driveNode, 1, 0, 0)
				local v223_ = v217_ + v220_ * 10
				local _ = v218_ + v221_ * 10
				local v224_ = v219_ + v222_ * 10
				local v225_ = v217_ + v220_ * -10
				local _ = v218_ + v221_ * -10
				local v226_ = v219_ + v222_ * -10
				drawDebugLine(v217_, v203_, v219_, 1, 0, 0, v223_, v203_, v224_, 1, 0, 0)
				drawDebugLine(v217_, v203_, v219_, 0, 1, 0, v225_, v203_, v226_, 0, 1, 0)
			end
		end
		if v215_.steeringCenterNode ~= nil then
			DebugGizmo.renderAtNode(v215_.steeringCenterNode, "SCN")
		end
		local v227_ = self.rotatedTime
		local v228_ = math.sign(v227_)
		local v229_ = v201_ + v228_ * v208_ * v211_
		local v230_ = v202_ + v228_ * v209_ * v211_
		DebugGizmo.renderAtPosition(v229_, v203_, v230_, v208_, 0, v209_, 0, 1, 0, "X")
		local v231_ = self.rotatedTime
		local v232_ = math.sign(v231_)
		local v233_ = v201_ + v232_ * v208_ * v212_
		local v234_ = v202_ + v232_ * v209_ * v212_
		DebugGizmo.renderAtPosition(v233_, v203_, v234_, v208_, 0, v209_, 0, 1, 0, "M")
	end
end

-- Local values: spec, agent, addDebugElements, padding, halfWidth, halfLength, testPoints, isBlocked, polygon, _, testPoint, wx, wy, wz, _, isBlocking, pointElem, text, textElem
function AIDrivable:debugGetAgentHasSpaceAt(x, y, z, dirX, dirY, dirZ, group)
	local v243_ = self.spec_aiDrivable
	local v244_ = v243_.agentInfo
	local v245_ = VehicleDebug.state ~= VehicleDebug.DEBUG_AI and g_currentMission.aiSystem
	if v245_ then
		v245_ = g_currentMission.aiSystem.splinesVisible or g_currentMission.aiSystem.debug.isCostRenderingActive
	end
	local v246_ = v244_.width / 2 + 0.3
	local v247_ = v244_.length / 2 + 0.3
	local v248_ = {
		{ MathUtil.transform(x, y, z, dirX, dirY, dirZ, 0, 1, 0, v246_, 0, -v247_ - v244_.lengthOffset) },
		{ MathUtil.transform(x, y, z, dirX, dirY, dirZ, 0, 1, 0, -v246_, 0, -v247_ - v244_.lengthOffset) },
		{ MathUtil.transform(x, y, z, dirX, dirY, dirZ, 0, 1, 0, -v246_, 0, v247_ - v244_.lengthOffset) },
		{ MathUtil.transform(x, y, z, dirX, dirY, dirZ, 0, 1, 0, v246_, 0, v247_ - v244_.lengthOffset) }
	}
	local v249_ = DebugPolygon.new()
	local v250_ = false
	for _, v251_ in ipairs(v248_) do
		local v252_ = v251_[1]
		local v253_ = v251_[2]
		local v254_ = v251_[3]
		local _, v255_ = getVehicleNavigationMapCostAtWorldPos(g_currentMission.aiSystem.navigationMap, v252_, v253_, v254_)
		v250_ = v255_ and true or v250_
		if v245_ then
			local v256_ = DebugPoint.new():createWithWorldPos(v252_, v253_, v254_, true, false):setColorRGBA(0, 1, 0, 0.8)
			if v255_ then
				v256_:setColorRGBA(1, 0, 0, 1)
			end
			g_debugManager:addElement(v256_, "AIAgentHasSpace")
			v249_:addPosition(v252_, v253_, v254_)
		end
	end
	if v245_ then
		local v257_ = string.format("%s\n%s\nagentId %d\nagentWidth %.3f\nagentLength %.3f\nagentLengthOffset %.3f", group, self.configFileName, v243_.agentId, v244_.width, v244_.length, v244_.lengthOffset)
		local v258_ = DebugText.new():createWithWorldPos(x, y, z, v257_, 0.015):setColorRGBA(0, 1, 0, 1)
		if v250_ then
			v258_:setColorRGBA(1, 0, 0, 1)
		end
		g_debugManager:addElement(v258_, "AIAgentHasSpace")
		v249_:setColor(v250_ and Color.PRESETS.RED or Color.PRESETS.GREEN):addToManager("AIAgentHasSpace")
	end
	return not v250_
end

-- Local values: baseSizeKey, name, id, configDesc, key
function AIDrivable:loadAgentInfoFromXML(xmlFile, agent)
	agent.width = xmlFile:getValue("vehicle.ai.agent#width")
	agent.length = xmlFile:getValue("vehicle.ai.agent#length")
	agent.height = xmlFile:getValue("vehicle.ai.agent#height")
	agent.lengthOffset = xmlFile:getValue("vehicle.ai.agent#lengthOffset", 0)
	agent.frontOffset = xmlFile:getValue("vehicle.ai.agent#frontOffset", 3)
	agent.frontWheelIndices = xmlFile:getValue("vehicle.ai.agent#frontWheelIndices", nil, true)
	agent.frontWheelNodes = xmlFile:getValue("vehicle.ai.agent#frontWheelNodes", nil, self.components, self.i3dMappings, true)
	agent.maxBrakeAcceleration = xmlFile:getValue("vehicle.ai.agent#maxBrakeAcceleration", 5)
	agent.maxCentripetalAcceleration = xmlFile:getValue("vehicle.ai.agent#maxCentripetalAcceleration", 1)
	agent.maxTurningRadius = xmlFile:getValue("vehicle.ai.agent#maxTurningRadius")
	agent.isDefined = xmlFile:hasProperty("vehicle.ai.agent")
	for v262_, v263_ in pairs(self.configurations) do
		local v264_ = g_vehicleConfigurationManager:getConfigurationDescByName(v262_)
		local v265_ = string.format("%s(%d).aiAgent", v264_.configurationKey, v263_ - 1)
		if xmlFile:hasProperty(v265_) then
			agent.width = xmlFile:getValue(v265_ .. "#width", agent.width)
			agent.length = xmlFile:getValue(v265_ .. "#length", agent.length)
			agent.height = xmlFile:getValue(v265_ .. "#height", agent.height)
			agent.lengthOffset = xmlFile:getValue(v265_ .. "#lengthOffset", agent.lengthOffset)
			agent.frontOffset = xmlFile:getValue(v265_ .. "#frontOffset", agent.frontOffset)
			agent.frontWheelIndices = xmlFile:getValue(v265_ .. "#frontWheelIndices", agent.frontWheelIndices, true)
			agent.frontWheelNodes = xmlFile:getValue(v265_ .. "#frontWheelNodes", agent.frontWheelNodes, self.components, self.i3dMappings, true)
			local v266_ = v265_ .. "#maxBrakeAcceleration"
			local v267_ = agent.maxBrakeAcceleration
			agent.maxBrakeAcceleration = math.min(xmlFile:getValue(v266_, v267_))
			local v268_ = v265_ .. "#maxCentripetalAcceleration"
			local v269_ = agent.maxCentripetalAcceleration
			agent.maxCentripetalAcceleration = math.min(xmlFile:getValue(v268_, v269_))
			agent.maxTurningRadius = xmlFile:getValue(v265_ .. "#maxTurningRadius", agent.maxTurningRadius)
			agent.isDefined = true
		end
	end
end

-- Local values: spec, agent, width, height, length, lengthOffset
function AIDrivable:getAIAgentSize()
	local v271_ = self.spec_aiDrivable
	local v272_ = v271_.agentInfo
	if not v272_.isValid then
		return nil, nil, nil, nil, nil
	end
	local v273_ = v272_.width
	local v274_ = v271_.attachmentsMaxWidth
	local v275_ = math.max(v273_, v274_)
	local v276_ = v272_.height
	local v277_ = v271_.attachmentsMaxHeight
	local v278_ = math.max(v276_, v277_)
	local v279_ = v272_.length
	local v280_ = v272_.lengthOffset
	return v275_, v279_ + v271_.attachmentsMaxLengthOffsetPos - v271_.attachmentsMaxLengthOffsetNeg, v280_ + v271_.attachmentsMaxLengthOffsetPos * 0.5 + v271_.attachmentsMaxLengthOffsetNeg * 0.5, v272_.frontOffset, v278_
end

-- Local values: spec, agent
function AIDrivable:getAIAgentMaxBrakeAcceleration()
	return self.spec_aiDrivable.agentInfo.maxBrakeAcceleration
end

-- Local values: spec
function AIDrivable:updateAIAgentAttachments()
	local v283_ = self.spec_aiDrivable
	v283_.attachments = {}
	v283_.attachmentChains = {}
	v283_.attachmentChainIndex = 1
	v283_.attachmentsTrailerOffsetData = {}
	v283_.attachmentsMaxWidth = 0
	v283_.attachmentsMaxHeight = 0
	v283_.attachmentsMaxLengthOffsetPos = 0
	v283_.attachmentsMaxLengthOffsetNeg = 0
	self:collectAIAgentAttachments(self)
	self:updateAIAgentAttachmentOffsetData()
	self:updateAIAgentPoseData()
end

-- Local values: spec
function AIDrivable:addAIAgentAttachment(attachmentData, level)
	local v287_ = self.spec_aiDrivable
	local v288_ = v287_.attachmentsMaxWidth
	local v289_ = attachmentData.width
	v287_.attachmentsMaxWidth = math.max(v288_, v289_)
	local v290_ = v287_.attachmentsMaxHeight
	local v291_ = attachmentData.height
	v287_.attachmentsMaxHeight = math.max(v290_, v291_)
	attachmentData.level = level
	if v287_.attachmentChains[v287_.attachmentChainIndex] == nil then
		v287_.attachmentChains[v287_.attachmentChainIndex] = {}
	end
	local v292_ = v287_.attachments
	table.insert(v292_, attachmentData)
	local v293_ = v287_.attachmentChains[v287_.attachmentChainIndex]
	table.insert(v293_, attachmentData)
end

-- Local values: spec
function AIDrivable:startNewAIAgentAttachmentChain()
	local v295_ = self.spec_aiDrivable
	if v295_.attachmentChains[v295_.attachmentChainIndex] ~= nil then
		v295_.attachmentChainIndex = v295_.attachmentChainIndex + 1
	end
end

-- Local values: spec, _, agentLength, _, _, numTrailers, ci, chainAttachments, isDynamicChain, isStaticChain, parentSteeringCenterNode, i, agentAttachment, jointNode, attacherVehicleJointNode, _, _, tractorHitchOffset, trailerHitchOffset, centerOffset, hasCollision, aiRootNode, _, _, z1, _, _, z2, minZ, maxZ, zDiffNeg, zDiffPos
function AIDrivable:updateAIAgentAttachmentOffsetData()
	local v297_ = self.spec_aiDrivable
	if v297_.agentInfo.isValid then
		local _, v298_, _, _ = self:getAIAgentSize()
		local v299_ = 0
		for v300_ = 1, #v297_.attachmentChains do
			local v301_ = v297_.attachmentChains[v300_]
			local v302_ = self:getAIRootNode()
			local v303_ = true
			local v304_ = true
			for v305_ = 1, #v301_ do
				local v306_ = v301_[v305_]
				if v306_.rotCenterNode == nil or not v304_ then
					if v303_ then
						if v299_ > 0 then
							v304_ = false
						end
						if v306_.rotCenterNode == nil then
							local v307_ = self:getAIRootNode()
							local _, _, v308_ = localToLocal(v306_.rootNode, v307_, 0, 0, v306_.length * 0.5)
							local _, _, v309_ = localToLocal(v306_.rootNode, v307_, 0, 0, -v306_.length * 0.5)
							local v310_ = -v297_.agentInfo.length * 0.5 + v297_.agentInfo.lengthOffset
							local v311_ = v297_.agentInfo.length * 0.5 + v297_.agentInfo.lengthOffset
							local v312_ = v308_ - v310_
							local v313_ = v309_ - v310_
							local v314_ = math.min(0, v312_, v313_)
							local v315_ = v308_ - v311_
							local v316_ = v309_ - v311_
							local v317_ = math.max(0, v315_, v316_)
							local v318_ = v297_.attachmentsMaxLengthOffsetPos
							v297_.attachmentsMaxLengthOffsetPos = math.max(v318_, v317_)
							local v319_ = v297_.attachmentsMaxLengthOffsetNeg
							v297_.attachmentsMaxLengthOffsetNeg = math.min(v319_, v314_)
						end
					end
				elseif v299_ < AIDrivable.TRAILER_LIMIT then
					local v320_ = v306_.jointNode or v306_.jointNodeDynamic
					local v321_ = v306_.attacherVehicleJointNode or v320_
					if v321_ ~= nil and v320_ ~= nil then
						local _, _, v322_ = localToLocal(v321_, v302_, 0, 0, 0)
						local v323_
						if v306_.jointNodeToHitchOffset == nil then
							v323_ = v306_.trailerHitchOffset
						else
							v323_ = v306_.jointNodeToHitchOffset[v320_]
						end
						if v323_ ~= nil then
							local v324_ = v306_.lengthOffset + v298_ * 0.5 - v306_.length * 0.5
							local v325_ = v306_.hasCollision and 1 or 0
							local v326_ = v297_.attachmentsTrailerOffsetData
							table.insert(v326_, v322_)
							local v327_ = v297_.attachmentsTrailerOffsetData
							table.insert(v327_, v323_)
							local v328_ = v297_.attachmentsTrailerOffsetData
							table.insert(v328_, v324_)
							local v329_ = v297_.attachmentsTrailerOffsetData
							table.insert(v329_, v325_)
							v302_ = v306_.rotCenterNode
							v299_ = v299_ + 1
						end
					end
					v303_ = false
				end
			end
		end
	end
end

-- Local values: spec, aiRootNode, numTrailers, currentIndex, ci, chainAttachments, isDynamicChain, i, agentAttachment
function AIDrivable:updateAIAgentPoseData()
	local v331_ = self.spec_aiDrivable
	local v332_ = self:getAIRootNode()
	local v333_ = v331_.poseData
	local v334_ = v331_.poseData
	local v335_ = v331_.poseData
	local v336_, v337_, v338_ = getWorldTranslation(v332_)
	v333_[1] = v336_
	v334_[2] = v337_
	v335_[3] = v338_
	local v339_ = v331_.poseData
	local v340_ = v331_.poseData
	local v341_ = v331_.poseData
	local v342_, v343_, v344_ = localDirectionToWorld(v332_, 0, 0, 1)
	v339_[4] = v342_
	v340_[5] = v343_
	v341_[6] = v344_
	local v345_ = 0
	local v346_ = 6
	for v347_ = 1, #v331_.attachmentChains do
		local v348_ = v331_.attachmentChains[v347_]
		local v349_ = true
		for v350_ = 1, #v348_ do
			local v351_ = v348_[v350_]
			if v351_.rotCenterNode == nil or not v349_ then
				if v345_ > 0 then
					v349_ = false
				end
			elseif v345_ < AIDrivable.TRAILER_LIMIT then
				local v352_ = v331_.poseData
				local v353_ = v346_ + 1
				local v354_ = v331_.poseData
				local v355_ = v346_ + 2
				local v356_ = v331_.poseData
				local v357_ = v346_ + 3
				local v358_, v359_, v360_ = getWorldTranslation(v351_.rotCenterNode)
				v352_[v353_] = v358_
				v354_[v355_] = v359_
				v356_[v357_] = v360_
				local v361_ = v331_.poseData
				local v362_ = v346_ + 4
				local v363_ = v331_.poseData
				local v364_ = v346_ + 5
				local v365_ = v331_.poseData
				local v366_ = v346_ + 6
				local v367_, v368_, v369_ = localDirectionToWorld(v351_.rotCenterNode, 0, 0, 1)
				v361_[v362_] = v367_
				v363_[v364_] = v368_
				v365_[v366_] = v369_
				v345_ = v345_ + 1
				v346_ = v346_ + 6
			end
		end
	end
	while v346_ < #v331_.poseData do
		table.remove(v331_.poseData, #v331_.poseData)
	end
end

function AIDrivable:prepareForAIDriving()
	self:raiseAIEvent("onAIDrivablePrepare", "onAIImplementPrepareForTransport")
end

function AIDrivable:getAITurningRadius(minRadius)
	return minRadius
end

-- Local values: spec
function AIDrivable:getCanStartAIVehicle(superFunc)
	if self.spec_aiDrivable.agentInfo.isValid then
		return superFunc(self)
	else
		return false
	end
end

-- Local values: spec
function AIDrivable:getIsAIJobSupported(superFunc, jobName)
	if self.spec_aiDrivable.agentInfo.isValid then
		return superFunc(self, jobName)
	else
		return false
	end
end

-- Local values: spec
function AIDrivable:getCanHaveAIVehicleObstacle(superFunc)
	if self.spec_aiDrivable.agentId == nil then
		return superFunc(self)
	else
		return false
	end
end

-- Local values: spec
function AIDrivable:consoleCommandClearPath()
	local v380_ = self.spec_aiDrivable
	if v380_.debugVehicle ~= nil then
		v380_.debugVehicle:clear()
	end
	return string.format("Cleared AI paths of %s", self:getName())
end

-- Local values: rotatedTime, axisSide
function AIDrivable:consoleCommandSetTurnRadius(turnRadius)
	local v383_ = self:getSteeringRotTimeByCurvature(1 / (tonumber(turnRadius) or 10))
	local v384_
	if v383_ > 0 then
		v384_ = v383_ / -self.maxRotTime
	else
		v384_ = v383_ / self.minRotTime
	end
	local v385_ = self:getSteeringDirection() * v384_
	self.spec_drivable.axisSide = v385_
end

-- Local values: vehicles, attachedVehicles, _, vehicle, aiRootNode, dirX, dirY, dirZ, moveX, moveY, moveZ, currentTurnRadius, gizmo, x, y, z, _, vehicle, _, component, _, vehicle
function AIDrivable:consoleCommandMove(distance)
	local v388_ = self:getChildVehicles()
	local v389_ = {}
	for _, v390_ in ipairs(v388_) do
		v390_:removeFromPhysics()
		table.insert(v389_, v390_)
	end
	local v391_ = self:getAIRootNode()
	local v392_, v393_, v394_ = localDirectionToWorld(v391_, 1, 0, 0)
	local v395_ = v392_ * distance
	local v396_ = v393_ * distance
	local v397_ = v394_ * distance
	local v398_ = self:getTurningRadiusByRotTime(self.rotatedTime)
	local v399_ = DebugGizmo.new()
	local v400_, v401_, v402_ = localToWorld(v391_, v398_, 0.05, 0)
	v399_:createWithWorldPosAndDir(v400_, v401_, v402_, 0, 0, 1, 0, 1, 0, "", false, nil)
	g_debugManager:addElement(v399_)
	self.rotatedTime = self:getSteeringRotTimeByCurvature(1 / (-v398_ + distance))
	if self.rotatedTime < 0 then
		self.spec_wheels.axisSide = self.rotatedTime / -self.maxRotTime / self:getSteeringDirection()
	else
		self.spec_wheels.axisSide = self.rotatedTime / self.minRotTime / self:getSteeringDirection()
	end
	for _, v403_ in ipairs(v389_) do
		for _, v404_ in ipairs(v403_.components) do
			local v405_, v406_, v407_ = getWorldTranslation(v404_.node)
			setWorldTranslation(v404_.node, v405_ + v395_, v406_ + v396_, v407_ + v397_)
		end
	end
	for _, v408_ in ipairs(v389_) do
		v408_:addToPhysics()
	end
end
