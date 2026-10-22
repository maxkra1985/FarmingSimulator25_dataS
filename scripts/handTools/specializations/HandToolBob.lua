HandToolBob = {}
HandToolBob.AMPLITUDE_VERTICAL = 0.005
HandToolBob.AMPLITUDE_HORIZONTAL = 0.003
HandToolBob.FREQUENCY = 7
HandToolBob.REFERENCE_SPEED = 1.6
HandToolBob.SMOOTHING = 0.008
HandToolBob.IDLE_AMPLITUDE_VERTICAL = 0.0015
HandToolBob.IDLE_AMPLITUDE_HORIZONTAL = 0.001
HandToolBob.IDLE_FREQUENCY = 1.2
HandToolBob.PHASE_LIMIT = 6.283185307179586
function HandToolBob.registerXMLPaths(xmlSchema)
	xmlSchema:setXMLSpecializationType("HandToolBob")
	xmlSchema:register(XMLValueType.NODE_INDEX, "handTool.bob.node(?)#node", "Node the bob offset is applied to")
	xmlSchema:register(XMLValueType.FLOAT, "handTool.bob.node(?)#bobAmplitudeVertical", "Vertical bob amplitude of the held tool in first person, in metres", tostring(HandToolBob.AMPLITUDE_VERTICAL))
	xmlSchema:register(XMLValueType.FLOAT, "handTool.bob.node(?)#bobAmplitudeHorizontal", "Horizontal sway amplitude of the held tool in first person, in metres", tostring(HandToolBob.AMPLITUDE_HORIZONTAL))
	xmlSchema:register(XMLValueType.FLOAT, "handTool.bob.node(?)#bobFrequency", "Step cadence of the bob, in radians of phase per second of walking", tostring(HandToolBob.FREQUENCY))
	xmlSchema:register(XMLValueType.FLOAT, "handTool.bob.node(?)#bobReferenceSpeed", "Player speed in metres per second at which the bob reaches full amplitude", tostring(HandToolBob.REFERENCE_SPEED))
	xmlSchema:register(XMLValueType.FLOAT, "handTool.bob.node(?)#bobIdleAmplitudeVertical", "Vertical amplitude of the constant idle bob while standing still, in metres", tostring(HandToolBob.IDLE_AMPLITUDE_VERTICAL))
	xmlSchema:register(XMLValueType.FLOAT, "handTool.bob.node(?)#bobIdleAmplitudeHorizontal", "Horizontal amplitude of the constant idle bob while standing still, in metres", tostring(HandToolBob.IDLE_AMPLITUDE_HORIZONTAL))
	xmlSchema:register(XMLValueType.FLOAT, "handTool.bob.node(?)#bobIdleFrequency", "Cadence of the idle bob, in radians of phase per second", tostring(HandToolBob.IDLE_FREQUENCY))
	xmlSchema:setXMLSpecializationType()
end
function HandToolBob.registerFunctions(handToolType)
	SpecializationUtil.registerFunction(handToolType, "getIsBobActive", HandToolBob.getIsBobActive)
	SpecializationUtil.registerFunction(handToolType, "updateBobNode", HandToolBob.updateBobNode)
	SpecializationUtil.registerFunction(handToolType, "resetBobNode", HandToolBob.resetBobNode)
end
function HandToolBob.registerEventListeners(handToolType)
	SpecializationUtil.registerEventListener(handToolType, "onLoad", HandToolBob)
	SpecializationUtil.registerEventListener(handToolType, "onUpdate", HandToolBob)
	SpecializationUtil.registerEventListener(handToolType, "onHeldEnd", HandToolBob)
end
function HandToolBob.prerequisitesPresent(specializations)
	return true
end
function HandToolBob:onLoad(xmlFile)
	local spec = self.spec_bob
	spec.bobNodes = {}
	for _, key in self.xmlFile:iterator("handTool.bob.node") do
		local node = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
		if node == nil then
			Logging.warning("HandToolBob: bob node %q could not be resolved in %q", tostring(key), tostring(self.configFileName))
		else
			local baseX, baseY, baseZ = getTranslation(node)
			local bobNode = {}
			bobNode.node = node
			bobNode.baseTranslation = { baseX, baseY, baseZ }
			bobNode.amplitudeVertical = self.xmlFile:getFloat(key .. "#bobAmplitudeVertical", HandToolBob.AMPLITUDE_VERTICAL)
			bobNode.amplitudeHorizontal = self.xmlFile:getFloat(key .. "#bobAmplitudeHorizontal", HandToolBob.AMPLITUDE_HORIZONTAL)
			bobNode.frequency = self.xmlFile:getFloat(key .. "#bobFrequency", HandToolBob.FREQUENCY)
			bobNode.referenceSpeed = math.max(self.xmlFile:getFloat(key .. "#bobReferenceSpeed", HandToolBob.REFERENCE_SPEED), 0.0001)
			bobNode.idleAmplitudeVertical = self.xmlFile:getFloat(key .. "#bobIdleAmplitudeVertical", HandToolBob.IDLE_AMPLITUDE_VERTICAL)
			bobNode.idleAmplitudeHorizontal = self.xmlFile:getFloat(key .. "#bobIdleAmplitudeHorizontal", HandToolBob.IDLE_AMPLITUDE_HORIZONTAL)
			bobNode.idleFrequency = self.xmlFile:getFloat(key .. "#bobIdleFrequency", HandToolBob.IDLE_FREQUENCY)
			bobNode.bobPhase = 0
			bobNode.idlePhase = 0
			bobNode.bobSpeedFactor = 0
			bobNode.isBobbing = false
			bobNode.offsetX = 0
			bobNode.offsetY = 0
			table.insert(spec.bobNodes, bobNode)
		end
	end
end
function HandToolBob:onUpdate(dt)
	local spec = self.spec_bob
	if #spec.bobNodes == 0 then
		return
	else
		local isActive = self:getIsBobActive()
		local speed = 0
		if isActive then
			speed = self:getCarryingPlayer():getGraphicalSpeed()
		end
		for _, bobNode in ipairs(spec.bobNodes) do
			self:updateBobNode(bobNode, dt, isActive, speed)
		end
	end
end
function HandToolBob:onHeldEnd()
	local spec = self.spec_bob
	for _, bobNode in ipairs(spec.bobNodes) do
		self:resetBobNode(bobNode)
	end
end
function HandToolBob:getIsBobActive()
	if not self:getIsHeld() then
		return false
	else
		local player = self:getCarryingPlayer()
		if player == nil or player ~= g_localPlayer then
			return false
		end
		return false
	end
end
function HandToolBob:updateBobNode(bobNode, dt, isActive, speed)
	local baseTranslation = bobNode.baseTranslation
	if not isActive then
		if bobNode.isBobbing then
			self:resetBobNode(bobNode)
		end
	else
		bobNode.isBobbing = true
		local targetFactor = math.min(speed / bobNode.referenceSpeed, 1)
		local smoothing = math.min(dt * HandToolBob.SMOOTHING, 1)
		bobNode.bobSpeedFactor = bobNode.bobSpeedFactor + (targetFactor - bobNode.bobSpeedFactor) * smoothing
		bobNode.idlePhase = (bobNode.idlePhase + dt * 0.001 * bobNode.idleFrequency) % HandToolBob.PHASE_LIMIT
		bobNode.bobPhase = (bobNode.bobPhase + dt * 0.001 * bobNode.frequency * bobNode.bobSpeedFactor) % HandToolBob.PHASE_LIMIT
		local idleOffsetX = math.cos(bobNode.idlePhase) * bobNode.idleAmplitudeHorizontal
		local idleOffsetY = math.sin(bobNode.idlePhase) * bobNode.idleAmplitudeVertical
		local walkOffsetX = math.cos(bobNode.bobPhase) * bobNode.amplitudeHorizontal * bobNode.bobSpeedFactor
		local walkOffsetY = math.sin(bobNode.bobPhase * 2) * bobNode.amplitudeVertical * bobNode.bobSpeedFactor
		bobNode.offsetX = idleOffsetX + walkOffsetX
		bobNode.offsetY = idleOffsetY + walkOffsetY
		setTranslation(bobNode.node, baseTranslation[1] + bobNode.offsetX, baseTranslation[2] + bobNode.offsetY, baseTranslation[3])
	end
end
function HandToolBob:resetBobNode(bobNode)
	local baseTranslation = bobNode.baseTranslation
	setTranslation(bobNode.node, baseTranslation[1], baseTranslation[2], baseTranslation[3])
	bobNode.bobPhase = 0
	bobNode.idlePhase = 0
	bobNode.bobSpeedFactor = 0
	bobNode.isBobbing = false
	bobNode.offsetX = 0
	bobNode.offsetY = 0
end
