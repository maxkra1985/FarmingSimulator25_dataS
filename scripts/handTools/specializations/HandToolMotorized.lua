HandToolMotorized = {}

-- Local values: basePath
function HandToolMotorized.registerXMLPaths(xmlSchema)
	xmlSchema:setXMLSpecializationType("HandToolMotorized")
	xmlSchema:register(XMLValueType.FLOAT, "handTool.motorized.motor#startTime", "The amount of milliseconds it takes for the motor to start", 0, false)
	xmlSchema:register(XMLValueType.FLOAT, "handTool.motorized.motor#minRPM", "The RPM of the tool when it is not being used", nil, false)
	xmlSchema:register(XMLValueType.FLOAT, "handTool.motorized.motor#maxRPM", "The RPM of the tool when it has no load and is being used", nil, false)
	xmlSchema:register(XMLValueType.FLOAT, "handTool.motorized.motor#rpmGainSpeed", "The amount of RPM that can be gained per second", nil, false)
	xmlSchema:register(XMLValueType.FLOAT, "handTool.motorized.motor#rpmLossSpeed", "The amount of RPM that can be lost per second", nil, false)
	xmlSchema:register(XMLValueType.FLOAT, "handTool.motorized.motor#rpmVariability", "Variability in rpm while the tool has full load", 0)
	xmlSchema:register(XMLValueType.FLOAT, "handTool.motorized.motor#rpmVariabilityChange", "Variability change factor (the higher, the faster changes the random variability)", 1)
	xmlSchema:register(XMLValueType.VECTOR_3, "handTool.motorized.vibrations#amount", "The base vibration amount along the 3 axes of the tool", nil, false)
	xmlSchema:register(XMLValueType.NODE_INDEX, "handTool.motorized.vibrations#node", "The name of the node that is vibrated", nil, false)
	SoundManager.registerSampleXMLPaths(xmlSchema, "handTool.motorized.sounds", "start")
	SoundManager.registerSampleXMLPaths(xmlSchema, "handTool.motorized.sounds", "stop")
	SoundManager.registerSampleXMLPaths(xmlSchema, "handTool.motorized.sounds", "idle")
	EffectManager.registerEffectXMLPaths(xmlSchema, "handTool.motorized.exhaustEffects")
	xmlSchema:setXMLSpecializationType()
end

function HandToolMotorized.registerFunctions(handToolType)
	SpecializationUtil.registerFunction(handToolType, "getTimeToReachRPM", HandToolMotorized.getTimeToReachRPM)
	SpecializationUtil.registerFunction(handToolType, "getRPMGainPerSecond", HandToolMotorized.getRPMGainPerSecond)
	SpecializationUtil.registerFunction(handToolType, "setRPMGainPerSecond", HandToolMotorized.setRPMGainPerSecond)
	SpecializationUtil.registerFunction(handToolType, "getRPMLossPerSecond", HandToolMotorized.getRPMLossPerSecond)
	SpecializationUtil.registerFunction(handToolType, "setRPMLossPerSecond", HandToolMotorized.setRPMLossPerSecond)
	SpecializationUtil.registerFunction(handToolType, "getCurrentLoad", HandToolMotorized.getCurrentLoad)
	SpecializationUtil.registerFunction(handToolType, "setCurrentLoad", HandToolMotorized.setCurrentLoad)
	SpecializationUtil.registerFunction(handToolType, "getCurrentRPM", HandToolMotorized.getCurrentRPM)
	SpecializationUtil.registerFunction(handToolType, "setCurrentRPM", HandToolMotorized.setCurrentRPM)
	SpecializationUtil.registerFunction(handToolType, "getMinRPM", HandToolMotorized.getMinRPM)
	SpecializationUtil.registerFunction(handToolType, "getTargetRPM", HandToolMotorized.getTargetRPM)
	SpecializationUtil.registerFunction(handToolType, "getMaxRPM", HandToolMotorized.getMaxRPM)
	SpecializationUtil.registerFunction(handToolType, "setTargetRPM", HandToolMotorized.setTargetRPM)
	SpecializationUtil.registerFunction(handToolType, "setTargetRPMToIdle", HandToolMotorized.setTargetRPMToIdle)
	SpecializationUtil.registerFunction(handToolType, "setTargetRPMToMax", HandToolMotorized.setTargetRPMToMax)
	SpecializationUtil.registerFunction(handToolType, "updateRPM", HandToolMotorized.updateRPM)
	SpecializationUtil.registerFunction(handToolType, "updateSounds", HandToolMotorized.updateSounds)
	SpecializationUtil.registerFunction(handToolType, "updateVibrations", HandToolMotorized.updateVibrations)
end

function HandToolMotorized.registerEventListeners(handToolType)
	SpecializationUtil.registerEventListener(handToolType, "onDelete", HandToolMotorized)
	SpecializationUtil.registerEventListener(handToolType, "onLoad", HandToolMotorized)
	SpecializationUtil.registerEventListener(handToolType, "onUpdate", HandToolMotorized)
	SpecializationUtil.registerEventListener(handToolType, "onWriteUpdateStream", HandToolMotorized)
	SpecializationUtil.registerEventListener(handToolType, "onReadUpdateStream", HandToolMotorized)
	SpecializationUtil.registerEventListener(handToolType, "onHeldStart", HandToolMotorized)
	SpecializationUtil.registerEventListener(handToolType, "onHeldEnd", HandToolMotorized)
	SpecializationUtil.registerEventListener(handToolType, "onDebugDraw", HandToolMotorized)
end

function HandToolMotorized.prerequisitesPresent(specializations)
	return true
end

-- Local values: spec, baseKey
function HandToolMotorized:onLoad(xmlFile, baseDirectory)
	local v7_ = self.spec_motorized
	v7_.dirtyFlag = self:getNextDirtyFlag()
	v7_.currentLoad = 0
	v7_.startTime = xmlFile:getValue("handTool.motorized.motor#startTime", 0)
	v7_.minRPM = xmlFile:getValue("handTool.motorized.motor#minRPM", 10)
	v7_.maxRPM = xmlFile:getValue("handTool.motorized.motor#maxRPM", 100)
	v7_.rpmGainPerSecond = xmlFile:getValue("handTool.motorized.motor#rpmGainSpeed", v7_.maxRPM - v7_.minRPM)
	v7_.rpmLossPerSecond = xmlFile:getValue("handTool.motorized.motor#rpmLossSpeed", v7_.maxRPM - v7_.minRPM)
	v7_.rpmVariability = xmlFile:getValue("handTool.motorized.motor#rpmVariability", 0)
	v7_.rpmVariabilityChange = xmlFile:getValue("handTool.motorized.motor#rpmVariabilityChange", 1)
	v7_.currentRPM = v7_.minRPM
	v7_.targetRPM = v7_.currentRPM
	v7_.vibrationNode = xmlFile:getValue("handTool.motorized.vibrations#node", nil, self.components, self.i3dMappings)
	local v8_, v9_, v10_ = xmlFile:getValue("handTool.motorized.vibrations#amount", "0 0 0")
	v7_.vibrationAmountX = v8_
	v7_.vibrationAmountY = v9_
	v7_.vibrationAmountZ = v10_
	if self.isClient then
		v7_.samples = {}
		v7_.samples.start = g_soundManager:loadSampleFromXML(xmlFile, "sounds.motorized.sounds", "start", baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v7_.samples.idle = g_soundManager:loadSampleFromXML(xmlFile, "sounds.motorized.sounds", "idle", baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v7_.samples.stop = g_soundManager:loadSampleFromXML(xmlFile, "sounds.motorized.sounds", "stop", baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		self.exhaustEffects = g_effectManager:loadEffect(xmlFile, "handTool.motorized.exhaustEffects", self.components, self, self.i3dMappings)
	end
end

-- Local values: spec
function HandToolMotorized:onDelete()
	if self.isClient then
		local v12_ = self.spec_motorized
		g_soundManager:deleteSamples(v12_.samples)
		g_effectManager:deleteEffects(v12_.fillEffects)
	end
end

-- Local values: spec
function HandToolMotorized:onWriteUpdateStream(streamId, connection, dirtyMask)
	local v16_ = self.spec_motorized
	local v17_ = streamWriteBool
	local v18_ = v16_.dirtyFlag
	if v17_(streamId, bit32.band(dirtyMask, v18_) ~= 0) then
		NetworkUtil.writeCompressedPercentages(streamId, MathUtil.inverseLerp(v16_.minRPM, v16_.maxRPM, v16_.currentRPM), 8)
		NetworkUtil.writeCompressedPercentages(streamId, v16_.currentLoad, 8)
	end
end

-- Local values: spec, currentRPM, currentLoad, carryingPlayer
function HandToolMotorized:onReadUpdateStream(streamId, timestamp, connection)
	if streamReadBool(streamId) then
		local v22_ = self.spec_motorized
		local v23_ = NetworkUtil.readCompressedPercentages(streamId, 8) * (v22_.maxRPM - v22_.minRPM) + v22_.minRPM
		local v24_ = NetworkUtil.readCompressedPercentages(streamId, 8)
		local v25_ = self:getCarryingPlayer()
		if not connection:getIsServer() or v25_ ~= nil and not v25_.isOwner then
			self:setCurrentRPM(v23_)
			self:setCurrentLoad(v24_)
		end
	end
end

-- Local values: spec, samples
function HandToolMotorized:onHeldStart()
	if self.isClient then
		local v27_ = self.spec_motorized
		local v28_ = v27_.samples
		if not g_soundManager:getIsSamplePlaying(v28_.idle) then
			g_soundManager:stopSample(v28_.stop)
			g_soundManager:playSample(v28_.start)
			g_soundManager:playSample(v28_.idle, 0, v28_.start)
		end
		g_effectManager:startEffects(v27_.exhaustEffects)
	end
end

-- Local values: spec, samples
function HandToolMotorized:onHeldEnd()
	if self.isClient then
		local v30_ = self.spec_motorized
		local v31_ = v30_.samples
		g_soundManager:stopSample(v31_.start)
		g_soundManager:stopSample(v31_.idle)
		g_soundManager:playSample(v31_.stop)
		g_effectManager:stopEffects(v30_.exhaustEffects)
	end
end

function HandToolMotorized:onUpdate(dt)
	self:updateRPM(dt)
	if self.isClient then
		self:updateSounds(dt)
		self:updateVibrations(dt)
	end
end

-- Local values: spec, targetRPM, t, randomOffset, direction, limit, change, currentRPM
function HandToolMotorized:updateRPM(dt)
	local v36_ = self.spec_motorized
	if v36_.currentRPM ~= v36_.targetRPM then
		local v37_ = v36_.targetRPM
		if v36_.rpmVariability > 0 then
			local v38_ = g_currentMission.time * v36_.rpmVariabilityChange
			local v39_ = v38_ * 0.00157
			local v40_ = math.sin(v39_) * 0.4
			local v41_ = v38_ * 0.00414
			local v42_ = v40_ + math.sin(v41_) * 0.4
			local v43_ = v38_ * 0.00628
			local v44_ = v42_ + math.sin(v43_) * 0.2
			v37_ = v37_ - math.abs(v44_) * (v36_.targetRPM / v36_.maxRPM) * (0.1 + v36_.currentLoad * 0.9) * v36_.maxRPM * v36_.rpmVariability
		end
		local v45_ = v37_ - v36_.currentRPM
		local v46_ = math.sign(v45_)
		local v47_ = v46_ > 0 and math.min or math.max
		local v48_ = v46_ >= 0 and v36_.rpmGainPerSecond or v36_.rpmLossPerSecond
		self:setCurrentRPM((v47_(v36_.currentRPM + v48_ * dt * 0.001 * v46_, v37_)))
	end
end

-- Local values: spec, rpmPercentage
function HandToolMotorized:updateSounds(dt)
	local v50_ = self.spec_motorized
	local v51_ = MathUtil.inverseLerp(v50_.minRPM, v50_.maxRPM, v50_.currentRPM)
	g_soundManager:setSampleLoopSynthesisParameters(v50_.samples.idle, v51_, self:getCurrentLoad())
end

-- Local values: spec, rpmAmount, vibrationScale, vibrationX, vibrationY, vibrationZ
function HandToolMotorized:updateVibrations(dt)
	local v53_ = self.spec_motorized
	local v54_ = MathUtil.inverseLerp(v53_.minRPM, v53_.maxRPM, v53_.currentRPM)
	local v55_ = 1 - math.clamp(v54_, 0, 1)
	local v56_ = MathUtil.lerp(0.05, 1, v55_) * (1 - v53_.currentLoad)
	local v57_ = MathUtil.randomFloat(-v53_.vibrationAmountX, v53_.vibrationAmountX) * v56_
	local v58_ = MathUtil.randomFloat(-v53_.vibrationAmountY, v53_.vibrationAmountY) * v56_
	local v59_ = MathUtil.randomFloat(-v53_.vibrationAmountZ, v53_.vibrationAmountZ) * v56_
	setTranslation(v53_.vibrationNode, v57_, v58_, v59_)
end

-- Local values: spec, rpmDelta, rpmDirection, rpmPerSecond
function HandToolMotorized:getTimeToReachRPM(rpm)
	local v62_ = self.spec_motorized
	if v62_.currentRPM == rpm then
		return 0
	end
	local v63_ = rpm - v62_.currentRPM
	local v64_ = math.sign(v63_) >= 0 and v62_.rpmGainPerSecond or v62_.rpmLossPerSecond
	return math.abs(v63_) / v64_
end

function HandToolMotorized:getRPMGainPerSecond()
	return self.spec_motorized.rpmGainPerSecond
end

function HandToolMotorized:setRPMGainPerSecond(rpmGainPerSecond)
	self.spec_motorized.rpmGainPerSecond = rpmGainPerSecond
end

function HandToolMotorized:getRPMLossPerSecond()
	return self.spec_motorized.rpmLossPerSecond
end

function HandToolMotorized:setRPMLossPerSecond(rpmLossPerSecond)
	self.spec_motorized.rpmLossPerSecond = rpmLossPerSecond
end

function HandToolMotorized:getCurrentLoad()
	return self.spec_motorized.currentLoad
end

-- Local values: spec, carryingPlayer
function HandToolMotorized:setCurrentLoad(currentLoad)
	local v74_ = self.spec_motorized
	local v75_ = math.clamp(currentLoad, 0, 1)
	local v76_ = v74_.currentLoad - v75_
	if math.abs(v76_) > 0.01 then
		local v77_ = self:getCarryingPlayer()
		if self.isServer or v77_ ~= nil and v77_.isOwner then
			self:raiseDirtyFlags(v74_.dirtyFlag)
		end
	end
	v74_.currentLoad = v75_
end

function HandToolMotorized:getCurrentRPM()
	return self.spec_motorized.currentRPM
end

-- Local values: spec, carryingPlayer
function HandToolMotorized:setCurrentRPM(currentRPM)
	local v81_ = self.spec_motorized
	local v82_ = v81_.minRPM
	local v83_ = v81_.maxRPM
	local v84_ = math.clamp(currentRPM, v82_, v83_)
	local v85_ = v81_.currentRPM - v84_
	if math.abs(v85_) > 1 then
		local v86_ = self:getCarryingPlayer()
		if self.isServer or v86_ ~= nil and v86_.isOwner then
			self:raiseDirtyFlags(v81_.dirtyFlag)
		end
	end
	v81_.currentRPM = v84_
end

function HandToolMotorized:getTargetRPM()
	return self.spec_motorized.targetRPM
end

function HandToolMotorized:getMaxRPM()
	return self.spec_motorized.maxRPM
end

function HandToolMotorized:getMinRPM()
	return self.spec_motorized.minRPM
end

-- Local values: spec
function HandToolMotorized:setTargetRPM(targetRPM)
	local v92_ = self.spec_motorized
	local v93_ = v92_.minRPM
	local v94_ = v92_.maxRPM
	v92_.targetRPM = math.clamp(targetRPM, v93_, v94_)
end

function HandToolMotorized:setTargetRPMToIdle()
	self:setTargetRPM(self.spec_motorized.minRPM)
end

function HandToolMotorized:setTargetRPMToMax()
	self:setTargetRPM(self.spec_motorized.maxRPM)
end

-- Local values: spec, rpmAmount, vibrationScale
function HandToolMotorized:onDebugDraw(x, y, textSize)
	local v101_ = self.spec_motorized
	local v102_ = DebugUtil.renderTextLine(x, y, textSize, string.format("Current RPM: %d", v101_.currentRPM))
	local v103_ = DebugUtil.renderTextLine(x, v102_, textSize, string.format("Target RPM: %d", v101_.targetRPM))
	local v104_ = DebugUtil.renderTextLine(x, v103_, textSize, string.format("Current Load: %d%%", v101_.currentLoad * 100))
	local v105_ = MathUtil.inverseLerp(v101_.minRPM, v101_.maxRPM, v101_.currentRPM)
	local v106_ = 1 - math.clamp(v105_, 0, 1)
	local v107_ = MathUtil.lerp(0.05, 1, v106_) * (1 - v101_.currentLoad)
	return DebugUtil.renderTextLine(x, v104_, textSize, string.format("Vibration: %d%%", v107_ * 100))
end
