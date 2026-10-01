PushHandTool = {}
PushHandTool.PLAYER_COLLISION_MASK = PlayerCCT.DEFAULT_MOVEMENT_COLLISION_MASK
source("dataS/scripts/vehicles/specializations/events/PushHandToolDriveModeEvent.lua")
function PushHandTool.initSpecialization()
	local schema = Vehicle.xmlSchema
	schema:setXMLSpecializationType("PushHandTool")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.pushHandTool.raycast#node1", "Front raycast node")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.pushHandTool.raycast#node2", "Back raycast node")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.pushHandTool.raycast#playerNode", "Player node to adjust")
	schema:register(XMLValueType.FLOAT, "vehicle.pushHandTool.raycast#positionSmoothnessFactor", "Defines how delayed the player position can be (lower value is a higher delay)", 1)
	schema:register(XMLValueType.FLOAT, "vehicle.pushHandTool.raycast#positionSmoothnessFactorReverse", "Smoothness factor while reversing", "same as #positionSmoothnessFactor")
	schema:register(XMLValueType.FLOAT, "vehicle.pushHandTool.raycast#positionSmoothnessFactorSteering", "Defines additional delay when the vehicle is fully steered (high value is a higher delay)", 0.15)
	schema:register(XMLValueType.VECTOR_N, "vehicle.pushHandTool.wheels#front", "Indices of front wheels")
	schema:register(XMLValueType.VECTOR_N, "vehicle.pushHandTool.wheels#back", "Indices of back wheels")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.pushHandTool.handle#node", "Handle node")
	schema:register(XMLValueType.FLOAT, "vehicle.pushHandTool.handle#upperLimit", "Max. upper distance between handle node and hand ik root node", 0.4)
	schema:register(XMLValueType.FLOAT, "vehicle.pushHandTool.handle#lowerLimit", "Max. lower distance between handle node and hand ik root node", 0.4)
	schema:register(XMLValueType.FLOAT, "vehicle.pushHandTool.handle#interpolateDistance", "Interpolation distance if limit is exceeded", 0.4)
	schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.handle#minRot", "Min. rotation of handle", -20)
	schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.handle#maxRot", "Max. rotation of handle", 20)
	schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.spine#rotationForward", "Spine rotation while moving forward")
	schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.spine#rotationBackward", "Spine rotation while moving backward")
	schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.spine#rotationIdle", "Spine rotation while in idle position")
	schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.spine#speed", "Speed of adjustment (degree per second)", 10)
	schema:register(XMLValueType.VECTOR_3, "vehicle.pushHandTool.spine#ratio", "Ratio between the 3 spine nodes to apply the rotation", "0.33 0.33 0.33")
	IKUtil.registerIKChainTargetsXMLPaths(schema, "vehicle.pushHandTool.ikChains")
	EffectManager.registerEffectXMLPaths(schema, "vehicle.pushHandTool.effect")
	schema:register(XMLValueType.STRING, "vehicle.pushHandTool.driveMode#animationName", "Name of toggle mode animation", 0)
	schema:register(XMLValueType.FLOAT, "vehicle.pushHandTool.driveMode#animationSpeed", "Animation speed scale", 1)
	schema:register(XMLValueType.FLOAT, "vehicle.pushHandTool.driveMode#maxSpeed", "Max. vehicle speed while drive mode is enabled")
	schema:register(XMLValueType.FLOAT, "vehicle.pushHandTool.driveMode#gearRatio", "Min. gear ratio while drive mode is enabled")
	VehicleCharacter.registerCharacterXMLPaths(schema, "vehicle.pushHandTool.driveMode.characterNode")
	schema:register(XMLValueType.STRING, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#chainId", "Chain identifier string", 20)
	schema:register(XMLValueType.INT, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#nodeIndex", "Index of node")
	schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#minRx", "Min. X rotation")
	schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#maxRx", "Max. X rotation")
	schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#minRy", "Min. Y rotation")
	schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#maxRy", "Max. Y rotation")
	schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#minRz", "Min. Z rotation")
	schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#maxRz", "Max. Z rotation")
	schema:register(XMLValueType.FLOAT, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#damping", "Damping")
	schema:register(XMLValueType.BOOL, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#localLimits", "Local limits")
	ConditionalAnimation.registerXMLPaths(schema, "vehicle.pushHandTool.playerConditionalAnimation")
	schema:setXMLSpecializationType()
	local schemaSavegame = Vehicle.xmlSchemaSavegame
	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).pushHandTool#driveModeIsActive", "DriveMode is active")
end
function PushHandTool.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Enterable, specializations)
end
function PushHandTool.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getRaycastPosition", PushHandTool.getRaycastPosition)
	SpecializationUtil.registerFunction(vehicleType, "playerRaycastCallback", PushHandTool.playerRaycastCallback)
	SpecializationUtil.registerFunction(vehicleType, "postAnimationUpdate", PushHandTool.postAnimationUpdate)
	SpecializationUtil.registerFunction(vehicleType, "customVehicleCharacterLoaded", PushHandTool.customVehicleCharacterLoaded)
	SpecializationUtil.registerFunction(vehicleType, "setPushHandToolDriveMode", PushHandTool.setPushHandToolDriveMode)
end
function PushHandTool.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setVehicleCharacter", PushHandTool.setVehicleCharacter)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "deleteVehicleCharacter", PushHandTool.deleteVehicleCharacter)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowCharacterVisibilityUpdate", PushHandTool.getAllowCharacterVisibilityUpdate)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setActiveCameraIndex", PushHandTool.setActiveCameraIndex)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", PushHandTool.getIsFoldAllowed)
end
function PushHandTool.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", PushHandTool)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", PushHandTool)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", PushHandTool)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", PushHandTool)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", PushHandTool)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", PushHandTool)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", PushHandTool)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", PushHandTool)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", PushHandTool)
	SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", PushHandTool)
	SpecializationUtil.registerEventListener(vehicleType, "onCameraChanged", PushHandTool)
	SpecializationUtil.registerEventListener(vehicleType, "onVehicleCharacterChanged", PushHandTool)
end
function PushHandTool:onLoad(savegame)
	local spec = self.spec_pushHandTool
	spec.animationParameters = {}
	spec.animationParameters.absSmoothedForwardVelocity = { id = 1, value = 0, type = 1 }
	spec.animationParameters.smoothedForwardVelocity = { id = 2, value = 0, type = 1 }
	spec.animationParameters.accelerate = { id = 3, value = false, type = 0 }
	spec.animationParameters.leftRightWeight = { id = 4, value = 0, type = 1 }
	spec.raycastNode1 = self.xmlFile:getValue("vehicle.pushHandTool.raycast#node1", nil, self.components, self.i3dMappings)
	spec.raycastNode2 = self.xmlFile:getValue("vehicle.pushHandTool.raycast#node2", nil, self.components, self.i3dMappings)
	spec.playerNode = self.xmlFile:getValue("vehicle.pushHandTool.raycast#playerNode", nil, self.components, self.i3dMappings)
	spec.playerTargetNode = createTransformGroup("playerTargetNode")
	if spec.playerNode ~= nil then
		link(getParent(spec.playerNode), spec.playerTargetNode)
		setTranslation(spec.playerTargetNode, getTranslation(spec.playerNode))
	end
	spec.positionSmoothnessFactor = self.xmlFile:getValue("vehicle.pushHandTool.raycast#positionSmoothnessFactor", 1)
	spec.positionSmoothnessFactorReverse = self.xmlFile:getValue("vehicle.pushHandTool.raycast#positionSmoothnessFactorReverse", spec.positionSmoothnessFactor)
	spec.positionSmoothnessFactorSteering = self.xmlFile:getValue("vehicle.pushHandTool.raycast#positionSmoothnessFactorSteering", 0.15)
	local frontWheels = self.xmlFile:getValue("vehicle.pushHandTool.wheels#front", nil, true)
	spec.frontWheels = {}
	if frontWheels ~= nil then
		for i = 1, #frontWheels do
			local wheel = self:getWheelFromWheelIndex(frontWheels[i])
			if wheel == nil then
				continue
			end
			table.insert(spec.frontWheels, wheel)
		end
	end
	local backWheels = self.xmlFile:getValue("vehicle.pushHandTool.wheels#back", nil, true)
	spec.backWheels = {}
	if backWheels ~= nil then
		for i = 1, #backWheels do
			local wheel = self:getWheelFromWheelIndex(backWheels[i])
			if wheel == nil then
				continue
			end
			table.insert(spec.backWheels, wheel)
		end
	end
	spec.handle = {}
	spec.handle.node = self.xmlFile:getValue("vehicle.pushHandTool.handle#node", nil, self.components, self.i3dMappings)
	spec.handle.upperLimit = self.xmlFile:getValue("vehicle.pushHandTool.handle#upperLimit", 0.4)
	spec.handle.lowerLimit = self.xmlFile:getValue("vehicle.pushHandTool.handle#lowerLimit", 0.4)
	spec.handle.interpolateDistance = self.xmlFile:getValue("vehicle.pushHandTool.handle#interpolateDistance", 0.4)
	spec.handle.minRot = self.xmlFile:getValue("vehicle.pushHandTool.handle#minRot", -20)
	spec.handle.maxRot = self.xmlFile:getValue("vehicle.pushHandTool.handle#maxRot", 20)
	spec.spine = {}
	spec.spine.node = nil
	spec.spine.rotationForward = self.xmlFile:getValue("vehicle.pushHandTool.spine#rotationForward")
	spec.spine.rotationBackward = self.xmlFile:getValue("vehicle.pushHandTool.spine#rotationBackward")
	spec.spine.rotationIdle = self.xmlFile:getValue("vehicle.pushHandTool.spine#rotationIdle")
	spec.spine.speed = self.xmlFile:getValue("vehicle.pushHandTool.spine#speed", 10) * 0.001
	spec.spine.ratio = self.xmlFile:getValue("vehicle.pushHandTool.spine#ratio", "0.33 0.33 0.33", true)
	spec.spine.currentRotation = spec.spine.rotationIdle
	spec.spine.doAdjustment = spec.spine.rotationForward ~= nil and spec.spine.rotationBackward ~= nil and spec.spine.rotationIdle ~= nil
	spec.characterIKNodes = {}
	spec.ikChainTargets = {}
	IKUtil.loadIKChainTargets(self.xmlFile, "vehicle.pushHandTool.ikChains", self.components, spec.ikChainTargets, self.i3dMappings)
	spec.lastRaycastPosition = { 0, 0, 0, 0 }
	spec.lastRaycastHit = false
	if self.isClient then
		spec.cutterEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.pushHandTool.effect", self.components, self, self.i3dMappings)
	end
	spec.customChainLimits = {}
	self.xmlFile:iterate("vehicle.pushHandTool.customChainLimits.customChainLimit", function(index, key)
		local entry = {}
		entry.chainId = self.xmlFile:getValue(key .. "#chainId")
		entry.nodeIndex = self.xmlFile:getValue(key .. "#nodeIndex")
		if entry.chainId ~= nil and entry.nodeIndex ~= nil then
			entry.minRx = self.xmlFile:getValue(key .. "#minRx")
			entry.maxRx = self.xmlFile:getValue(key .. "#maxRx")
			entry.minRy = self.xmlFile:getValue(key .. "#minRy")
			entry.maxRy = self.xmlFile:getValue(key .. "#maxRy")
			entry.minRz = self.xmlFile:getValue(key .. "#minRz")
			entry.maxRz = self.xmlFile:getValue(key .. "#maxRz")
			entry.damping = self.xmlFile:getValue(key .. "#damping")
			entry.localLimits = self.xmlFile:getValue(key .. "#localLimits")
			table.insert(spec.customChainLimits, entry)
		end
	end)
	spec.driveMode = {}
	spec.driveMode.animationName = self.xmlFile:getValue("vehicle.pushHandTool.driveMode#animationName")
	spec.driveMode.animationSpeed = self.xmlFile:getValue("vehicle.pushHandTool.driveMode#animationSpeed", 1)
	spec.driveMode.baseSpeed = self.spec_motorized.motor.maxForwardSpeed
	spec.driveMode.baseGearRatio = self.spec_motorized.motor.minForwardGearRatio
	spec.driveMode.maxSpeed = self.xmlFile:getValue("vehicle.pushHandTool.driveMode#maxSpeed")
	if spec.driveMode.maxSpeed ~= nil then
		spec.driveMode.maxSpeed = spec.driveMode.maxSpeed / 3.6
	end
	spec.driveMode.gearRatio = self.xmlFile:getValue("vehicle.pushHandTool.driveMode#gearRatio")
	spec.driveMode.vehicleCharacter = VehicleCharacter.new(self)
	if spec.driveMode.vehicleCharacter ~= nil and not spec.driveMode.vehicleCharacter:load(self.xmlFile, "vehicle.pushHandTool.driveMode.characterNode") then
		spec.driveMode.vehicleCharacter = nil
	end
	spec.driveMode.isActive = false
	spec.effectDirtyFlag = self:getNextDirtyFlag()
	spec.effectsAreRunning = false
	spec.lastFruitTypeIndex = FruitType.UNKNOWN
	spec.lastFruitGrowthState = 0
	spec.raycastsValid = true
	spec.lastSmoothSpeed = 0
	if self.setTestAreaRequirements ~= nil then
		self:setTestAreaRequirements(FruitType.GRASS, nil, false)
	end
	spec.postAnimationCallback = addPostAnimationCallback(self.postAnimationUpdate, self)
end
function PushHandTool:onPostLoad(savegame)
	local spec = self.spec_pushHandTool
	if savegame ~= nil and savegame.xmlFile:getValue(savegame.key .. ".pushHandTool#driveModeIsActive", false) then
		self:setPushHandToolDriveMode(true, true)
		AnimatedVehicle.updateAnimationByName(self, spec.driveMode.animationName, 99999, true)
	end
end
function PushHandTool:onDelete()
	local spec = self.spec_pushHandTool
	g_effectManager:deleteEffects(spec.cutterEffects)
	removePostAnimationCallback(spec.postAnimationCallback)
end
function PushHandTool:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_pushHandTool
	if spec.driveMode.animationName ~= nil then
		xmlFile:setValue(key .. "#driveModeIsActive", spec.driveMode.isActive)
	end
end
function PushHandTool:onReadStream(streamId, connection)
	local spec = self.spec_pushHandTool
	self:setPushHandToolDriveMode(streamReadBool(streamId), true)
	AnimatedVehicle.updateAnimationByName(self, spec.driveMode.animationName, 99999, true)
end
function PushHandTool:onWriteStream(streamId, connection)
	local spec = self.spec_pushHandTool
	streamWriteBool(streamId, spec.driveMode.isActive)
end
function PushHandTool:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local spec = self.spec_pushHandTool
		local effectsAreRunning = streamReadBool(streamId)
		if effectsAreRunning then
			spec.lastFruitGrowthState = streamReadUIntN(streamId, 4)
			spec.lastFruitTypeIndex = streamReadUIntN(streamId, FruitTypeManager.SEND_NUM_BITS)
		end
		if effectsAreRunning ~= spec.effectsAreRunning then
			spec.effectsAreRunning = effectsAreRunning
			if not effectsAreRunning then
				g_effectManager:stopEffects(spec.cutterEffects)
			end
		end
	end
end
function PushHandTool:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_pushHandTool
		if streamWriteBool(streamId, spec.effectsAreRunning) then
			streamWriteUIntN(streamId, spec.lastFruitGrowthState, 4)
			streamWriteUIntN(streamId, spec.lastFruitTypeIndex, FruitTypeManager.SEND_NUM_BITS)
		end
	end
end
function PushHandTool:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_pushHandTool
	if self.getTestAreaWidthByWorkAreaIndex ~= nil and self:getIsTurnedOn() then
		if 0.5 < self:getLastSpeed() then
			local currentTestAreaMinX, currentTestAreaMaxX, testAreaMinX, testAreaMaxX = self:getTestAreaWidthByWorkAreaIndex(1)
			local reset = false
			if currentTestAreaMinX == -math.huge and currentTestAreaMaxX == math.huge then
				currentTestAreaMinX = 0
				currentTestAreaMaxX = 0
				reset = true
			end
			if 0 < self.movingDirection then
				currentTestAreaMinX = currentTestAreaMinX * -1
				currentTestAreaMaxX = currentTestAreaMaxX * -1
				if currentTestAreaMaxX < currentTestAreaMinX then
					local t = currentTestAreaMinX
					currentTestAreaMinX = currentTestAreaMaxX
					currentTestAreaMaxX = t
				end
			end
			local inputFruitType = nil
			local inputGrowthState = nil
			local isActive = nil
			if self.isServer then
				inputFruitType = FruitType.UNKNOWN
				inputGrowthState = 3
				if self.spec_mower ~= nil then
					local specMower = self.spec_mower
					if g_time - specMower.workAreaParameters.lastCutTime < 500 then
						inputFruitType = specMower.workAreaParameters.lastInputFruitType
						inputGrowthState = specMower.workAreaParameters.lastInputGrowthState
					end
				end
				isActive = not reset and inputFruitType ~= nil and inputFruitType ~= FruitType.UNKNOWN
				if isActive then
					if not spec.effectsAreRunning then
						spec.effectsAreRunning = true
						self:raiseDirtyFlags(spec.effectDirtyFlag)
					end
				elseif spec.effectsAreRunning then
					g_effectManager:stopEffects(spec.cutterEffects)
					spec.effectsAreRunning = false
					self:raiseDirtyFlags(spec.effectDirtyFlag)
				end
				spec.lastFruitTypeIndex = inputFruitType
				spec.lastFruitGrowthState = inputGrowthState
			else
				inputFruitType = spec.lastFruitTypeIndex
				inputGrowthState = spec.lastFruitGrowthState
				isActive = spec.effectsAreRunning and spec.lastFruitTypeIndex ~= FruitType.UNKNOWN
			end
			if isActive then
				g_effectManager:setEffectTypeInfo(spec.cutterEffects, nil, inputFruitType, inputGrowthState)
				g_effectManager:setMinMaxWidth(spec.cutterEffects, currentTestAreaMinX, currentTestAreaMaxX, currentTestAreaMinX / testAreaMinX, currentTestAreaMaxX / testAreaMaxX, reset)
				g_effectManager:startEffects(spec.cutterEffects)
			end
		elseif spec.effectsAreRunning then
			g_effectManager:stopEffects(spec.cutterEffects)
			spec.effectsAreRunning = false
			self:raiseDirtyFlags(spec.effectDirtyFlag)
		end
	end
	local lastSpeed = self.lastSignedSpeed * 1000
	local avgSpeed = 0
	local numWheels = 0
	for _, wheel in pairs(spec.backWheels) do
		if wheel.physics.netInfo.xDriveSpeed == nil then
			continue
		end
		local wheelSpeed = MathUtil.rpmToMps(wheel.physics.netInfo.xDriveSpeed / 6.283185307179586 * 60, wheel.physics.radius) * 1000
		avgSpeed = avgSpeed + wheelSpeed
		numWheels = numWheels + 1
	end
	if 0 < numWheels then
		lastSpeed = avgSpeed / numWheels
	end
	spec.lastSmoothSpeed = spec.lastSmoothSpeed * 0.9 + lastSpeed * 0.1
	spec.animationParameters.smoothedForwardVelocity.value = spec.lastSmoothSpeed
	spec.animationParameters.absSmoothedForwardVelocity.value = math.abs(spec.lastSmoothSpeed)
	spec.animationParameters.leftRightWeight.value = self.rotatedTime
	spec.animationParameters.accelerate.value = 0 < self:getAccelerationAxis()
	if self:getIsEntered() or self:getIsControlled() or self:getIsAIActive() then
		local character = self:getVehicleCharacter()
		if character ~= nil and (character.animationCharsetId ~= nil and character.animationPlayer ~= nil) then
			for _, parameter in pairs(spec.animationParameters) do
				if parameter.type == 0 then
					setConditionalAnimationBoolValue(character.animationPlayer, parameter.id, parameter.value)
				elseif parameter.type == 1 then
					setConditionalAnimationFloatValue(character.animationPlayer, parameter.id, parameter.value)
				end
			end
			setConditionalAnimationSpecificParameterIds(character.animationPlayer, spec.animationParameters.absSmoothedForwardVelocity.id, 0)
			updateConditionalAnimation(character.animationPlayer, dt)
		end
		if spec.driveMode.vehicleCharacter ~= nil and (spec.driveMode.isActive and not self:getIsAnimationPlaying(spec.driveMode.animationName)) then
			spec.driveMode.vehicleCharacter:update(dt)
		end
	end
	if spec.spine.doAdjustment then
		local targetRotation = spec.spine.rotationIdle
		if 0.75 < self:getLastSpeed() then
			if 0 < self.movingDirection then
				targetRotation = spec.spine.rotationForward
			elseif self.movingDirection < 0 then
				targetRotation = spec.spine.rotationBackward
			end
		end
		local direction = math.sign(targetRotation - spec.spine.currentRotation)
		local limit = 0 < direction and math.min or math.max
		spec.spine.currentRotation = limit(spec.spine.currentRotation + direction * dt * spec.spine.speed, targetRotation)
	end
	if spec.raycastNode1 ~= nil and (spec.raycastNode2 ~= nil and (spec.playerNode ~= nil and (1 <= #spec.frontWheels and 1 <= #spec.backWheels))) then
		local x1, y1, z1 = self:getRaycastPosition(spec.raycastNode1)
		local x2, y2, z2 = self:getRaycastPosition(spec.raycastNode2)
		if x1 ~= nil and x2 ~= nil then
			local tx = (x1 + x2) * 0.5
			local ty = (y1 + y2) * 0.5
			local tz = (z1 + z2) * 0.5
			setWorldTranslation(spec.playerTargetNode, tx, ty, tz)
			local dirX = x1 - x2
			local dirY = y1 - y2
			local dirZ = z1 - z2
			dirX, dirY, dirZ = MathUtil.vector3Normalize(dirX, dirY, dirZ)
			if spec.lastYDirection == nil then
				spec.lastYDirection = dirY
			else
				dirY = spec.lastYDirection * 0.9 + dirY * 0.1
				spec.lastYDirection = dirY
			end
			I3DUtil.setWorldDirection(spec.playerTargetNode, dirX, dirY, dirZ, 0, 1, 0)
			if spec.lastWorldTrans == nil then
				spec.lastWorldTrans = { getWorldTranslation(spec.playerNode) }
			end
			local cx = spec.lastWorldTrans[1]
			local cy = spec.lastWorldTrans[2]
			local cz = spec.lastWorldTrans[3]
			local smoothFactor = (0.3 - math.min(math.abs(self.rotatedTime / 0.5), 1) * spec.positionSmoothnessFactorSteering) * (0 < self.movingDirection and spec.positionSmoothnessFactor or spec.positionSmoothnessFactorReverse)
			local moveX = (cx - tx) * smoothFactor
			local moveY = (cy - ty) * smoothFactor
			local moveZ = (cz - tz) * smoothFactor
			local newX = cx - moveX
			local newY = cy - moveY
			local newZ = cz - moveZ
			setWorldTranslation(spec.playerNode, newX, newY, newZ)
			spec.lastWorldTrans[1] = newX
			spec.lastWorldTrans[2] = newY
			spec.lastWorldTrans[3] = newZ
			local direction = self.movingDirection
			if direction == 0 then
				direction = 1
			end
			tx, ty, tz = localToWorld(spec.playerTargetNode, 0, 0, 0.2 * direction)
			local dirY2 = nil
			local _ = nil
			dirX = tx - newX
			dirY2 = ty - newY
			dirZ = tz - newZ
			dirX, _, dirZ = MathUtil.vector3Normalize(dirX, dirY2, dirZ)
			if direction < 0 then
				dirX = -dirX
				dirZ = -dirZ
			end
			local fcx = 0
			local fcy = 0
			local fcz = 0
			local numFrontWheels = #spec.frontWheels
			for i = 1, numFrontWheels do
				local wheel = spec.frontWheels[i]
				local wx = wheel.physics.netInfo.x
				local wy = wheel.physics.netInfo.y
				local wz = wheel.physics.netInfo.z
				wy = wy - wheel.physics.radius
				wx, wy, wz = localToWorld(wheel.node, wx, wy, wz)
				fcx = fcx + wx
				fcy = fcy + wy
				fcz = fcz + wz
			end
			fcx = fcx / numFrontWheels
			fcy = fcy / numFrontWheels
			fcz = fcz / numFrontWheels
			local bcx = 0
			local bcy = 0
			local bcz = 0
			local numBackWheels = #spec.backWheels
			for i = 1, numBackWheels do
				local wheel = spec.backWheels[i]
				local wx = wheel.physics.netInfo.x
				local wy = wheel.physics.netInfo.y
				local wz = wheel.physics.netInfo.z
				wy = wy - wheel.physics.radius
				wx, wy, wz = localToWorld(wheel.node, wx, wy, wz)
				bcx = bcx + wx
				bcy = bcy + wy
				bcz = bcz + wz
			end
			bcx = bcx / numBackWheels
			bcy = bcy / numBackWheels
			bcz = bcz / numBackWheels
			local wDirX = bcx - fcx
			local wDirY = bcy - fcy
			local wDirZ = bcz - fcz
			_, wDirY, _ = MathUtil.vector3Normalize(wDirX, wDirY, wDirZ)
			local dir = wDirY < 0 and 1 or -1
			dirY = wDirY + math.min(0.15, math.abs(wDirY)) * dir
			local upX, upY, upZ = localDirectionToWorld(self.rootNode, 0, 1, 0)
			upY = upY + 0.5
			upX, upY, upZ = MathUtil.vector3Normalize(upX, upY, upZ)
			I3DUtil.setWorldDirection(spec.playerNode, dirX, dirY, dirZ, upX, upY, upZ)
			spec.raycastsValid = true
			return
		end
		if spec.raycastsValid and self:getIsEntered() then
			spec.raycastsValid = false
			local character = self:getVehicleCharacter()
			if character ~= nil then
				character:setCharacterVisibility(false)
			end
			self:setActiveCameraIndex(self.spec_enterable.camIndex)
		end
	end
end
function PushHandTool:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_pushHandTool
		if spec.driveMode.vehicleCharacter ~= nil then
			self:clearActionEventsTable(spec.actionEvents)
			if isActiveForInputIgnoreSelection then
				local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA4, self, PushHandTool.actionEventToggleDriveMode, false, true, false, true, 1)
				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
				g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("action_changeDriveMode"))
			end
		end
	end
end
function PushHandTool:actionEventToggleDriveMode(actionName, inputValue, callbackState, isAnalog)
	self:setPushHandToolDriveMode()
end
function PushHandTool:setVehicleCharacter(superFunc, playerStyle)
	local enterableSpec = self.spec_enterable
	if enterableSpec.vehicleCharacter ~= nil then
		enterableSpec.vehicleCharacter:unloadCharacter()
		enterableSpec.vehicleCharacter:loadCharacter(playerStyle, self, self.customVehicleCharacterLoaded)
	end
	local spec = self.spec_pushHandTool
	if spec.driveMode.vehicleCharacter ~= nil and playerStyle ~= nil then
		spec.driveMode.vehicleCharacter:loadCharacter(playerStyle, self, PushHandTool.driveModeVehicleCharacterLoaded, {})
	end
end
function PushHandTool:deleteVehicleCharacter(superFunc)
	superFunc(self)
	local spec = self.spec_pushHandTool
	if spec.driveMode.vehicleCharacter ~= nil then
		spec.driveMode.vehicleCharacter:unloadCharacter()
	end
end
function PushHandTool:customVehicleCharacterLoaded(loadingState, arguments)
	local enterableSpec = self.spec_enterable
	if loadingState == HumanModelLoadingState.OK then
		local character = enterableSpec.vehicleCharacter
		if character ~= nil then
			character:updateVisibility()
		end
		SpecializationUtil.raiseEvent(self, "onVehicleCharacterChanged", character)
		local spec = self.spec_pushHandTool
		spec.characterIKNodes = {}
		spec.spine.node = character.playerModel.thirdPersonSpineNode
		for name, ikChain in pairs(character.playerModel.ikChains) do
			if spec.ikChainTargets[name] ~= nil then
				for k, nodeData in pairs(ikChain.nodes) do
					if spec.characterIKNodes[nodeData.node] == nil then
						local duplicate = createTransformGroup(getName(nodeData.node) .. "_ikChain")
						local parent = getParent(nodeData.node)
						if spec.characterIKNodes[parent] ~= nil then
							parent = spec.characterIKNodes[parent]
						end
						link(parent, duplicate)
						setTranslation(duplicate, getTranslation(nodeData.node))
						setRotation(duplicate, getRotation(nodeData.node))
						spec.characterIKNodes[nodeData.node] = duplicate
					end
				end
			end
			for k, nodeData in pairs(ikChain.nodes) do
				if spec.characterIKNodes[nodeData.node] == nil then
					continue
				end
				nodeData.node = spec.characterIKNodes[nodeData.node]
			end
		end
		character.ikChainTargets = spec.ikChainTargets
		for ikChainId, target in pairs(spec.ikChainTargets) do
			IKUtil.setTarget(character.playerModel.ikChains, ikChainId, target)
		end
		spec.ikChains = character.playerModel.ikChains
		for name, ikChain in pairs(character.playerModel.ikChains) do
			ikChain.ikChainSolver = IKChain.new(#ikChain.nodes)
			for i, node in ipairs(ikChain.nodes) do
				local minRx = node.minRx
				local maxRx = node.maxRx
				local minRy = node.minRy
				local maxRy = node.maxRy
				local minRz = node.minRz
				local maxRz = node.maxRz
				local damping = node.damping
				local localLimits = node.localLimits
				for j = 1, #spec.customChainLimits do
					local customLimit = spec.customChainLimits[j]
					if customLimit.chainId == name and customLimit.nodeIndex == i then
						minRx = customLimit.minRx or minRx
						maxRx = customLimit.maxRx or maxRx
						minRy = customLimit.minRy or minRy
						maxRy = customLimit.maxRy or maxRy
						minRz = customLimit.minRz or minRz
						maxRz = customLimit.maxRz or maxRz
						damping = customLimit.damping or damping
						if customLimit.localLimits == nil then
							continue
						end
						localLimits = customLimit.localLimits
					end
				end
				ikChain.ikChainSolver:setJointTransformGroup(i - 1, node.node, minRx, maxRx, minRy, maxRy, minRz, maxRz, damping, localLimits)
			end
			ikChain.numIterations = 40
			ikChain.positionThreshold = 0.0001
		end
		character:setDirty()
		if character ~= nil and (character.animationCharsetId ~= nil and character.animationPlayer ~= nil) then
			for key, parameter in pairs(spec.animationParameters) do
				conditionalAnimationRegisterParameter(character.animationPlayer, parameter.id, parameter.type, key)
			end
			initConditionalAnimation(character.animationPlayer, character.animationCharsetId, self.configFileName, "vehicle.pushHandTool.playerConditionalAnimation")
			conditionalAnimationZeroiseTrackTimes(character.animationPlayer)
		end
	end
end
function PushHandTool:driveModeVehicleCharacterLoaded(loadingState, arguments)
	if loadingState == HumanModelLoadingState.OK then
		local spec = self.spec_pushHandTool
		if spec.driveMode.vehicleCharacter ~= nil then
			local activeCamera = self:getActiveCamera()
			if activeCamera ~= nil then
				spec.driveMode.vehicleCharacter:setCharacterVisibility(not activeCamera.isInside)
			end
			spec.driveMode.vehicleCharacter:updateIKChains()
		end
	end
end
function PushHandTool:setPushHandToolDriveMode(driveModeState, noEventSend)
	local spec = self.spec_pushHandTool
	if driveModeState == nil then
		driveModeState = not spec.driveMode.isActive
	end
	if spec.driveMode.isActive ~= driveModeState then
		spec.driveMode.isActive = driveModeState
		self.spec_motorized.motor.maxForwardSpeed = driveModeState and spec.driveMode.maxSpeed or spec.driveMode.baseSpeed
		self.spec_motorized.motor.minForwardGearRatio = driveModeState and spec.driveMode.gearRatio or spec.driveMode.baseGearRatio
		self.spec_drivable.cruiseControl.maxSpeed = self.spec_motorized.motor.maxForwardSpeed * 3.6
		self:setCruiseControlMaxSpeed(math.min(self.spec_drivable.cruiseControl.speed, self.spec_drivable.cruiseControl.maxSpeed), nil)
		self:playAnimation(spec.driveMode.animationName, driveModeState and spec.driveMode.animationSpeed or -spec.driveMode.animationSpeed, self:getAnimationTime(spec.driveMode.animationName), true)
		self:setFoldState(self.spec_foldable.turnOnFoldDirection, false, true)
		if spec.driveMode.vehicleCharacter ~= nil then
			local character = self:getVehicleCharacter()
			if character ~= nil then
				character:setCharacterVisibility(false)
			end
		end
	end
	PushHandToolDriveModeEvent.sendEvent(self, driveModeState, noEventSend)
end
function PushHandTool:getAllowCharacterVisibilityUpdate(superFunc)
	if not superFunc(self) then
		return false
	end
	if self:getIsEntered() then
		local activeCamera = self:getActiveCamera()
		if activeCamera ~= nil and activeCamera.isInside then
			return false
		end
	end
	local spec = self.spec_pushHandTool
	if not spec.raycastsValid then
		return false
	elseif spec.driveMode.isActive and spec.driveMode.vehicleCharacter ~= nil then
		return false
	elseif spec.driveMode.vehicleCharacter ~= nil and self:getIsAnimationPlaying(spec.driveMode.animationName) then
		return false
	else
		return true
	end
end
function PushHandTool:setActiveCameraIndex(superFunc, index)
	local spec = self.spec_pushHandTool
	if not spec.raycastsValid then
		local specEnterable = self.spec_enterable
		if specEnterable.numCameras < index then
			index = 1
		end
		local activeCamera = specEnterable.cameras[index]
		if activeCamera.isInside then
			for i, camera in pairs(specEnterable.cameras) do
				if not camera.isInside then
					index = i
					break
				end
			end
		end
	end
	return superFunc(self, index)
end
function PushHandTool:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	local spec = self.spec_pushHandTool
	if spec.driveMode.isActive then
		return false
	else
		return superFunc(self, direction, onAiTurnOn)
	end
end
function PushHandTool:onEnterVehicle(isControlling)
	local hideCharacter = false
	if isControlling then
		local activeCamera = self:getActiveCamera()
		if activeCamera ~= nil and activeCamera.isInside then
			hideCharacter = true
		end
	end
	local spec = self.spec_pushHandTool
	if not spec.raycastsValid then
		hideCharacter = true
	end
	if hideCharacter then
		local character = self:getVehicleCharacter()
		if character ~= nil then
			character:setCharacterVisibility(false)
		end
	end
end
function PushHandTool:onCameraChanged(activeCamera, camIndex)
	if self:getIsEntered() then
		local spec = self.spec_pushHandTool
		local character = self:getVehicleCharacter()
		if character ~= nil and activeCamera.isInside then
			character:setCharacterVisibility(false)
		end
		if spec.driveMode.vehicleCharacter ~= nil then
			spec.driveMode.vehicleCharacter:setCharacterVisibility(not activeCamera.isInside)
		end
	end
end
function PushHandTool:onVehicleCharacterChanged(character)
	if self:getIsEntered() and character ~= nil then
		local activeCamera = self:getActiveCamera()
		if activeCamera ~= nil and activeCamera.isInside then
			character:setCharacterVisibility(false)
		end
	end
	if character == nil then
		local spec = self.spec_pushHandTool
		spec.characterIKNodes = {}
		spec.spine.node = nil
	end
end
function PushHandTool:postAnimationUpdate(dt)
	if self.isActive then
		local spec = self.spec_pushHandTool
		if spec.raycastsValid and (spec.handle.node ~= nil and spec.ikChains ~= nil) then
			local yDifference = nil
			for name, ikChain in pairs(spec.ikChains) do
				local node = ikChain.nodes[1].node
				if node == nil or spec.ikChainTargets[name] == nil then
					continue
				end
				local targetNode = spec.ikChainTargets[name].targetNode
				if targetNode == nil then
					continue
				end
				local x, y, z = getRotation(spec.handle.node)
				setRotation(spec.handle.node, 0, 0, 0)
				if yDifference == nil then
					yDifference = calcDistanceFrom(node, targetNode)
				else
					yDifference = (yDifference + calcDistanceFrom(node, targetNode)) / 2
				end
				setRotation(spec.handle.node, x, y, z)
			end
			if yDifference ~= nil then
				if yDifference < spec.handle.upperLimit then
					local alpha = (spec.handle.upperLimit - yDifference) / spec.handle.interpolateDistance
					setRotation(spec.handle.node, spec.handle.minRot * alpha, 0, 0)
				elseif spec.handle.lowerLimit < yDifference then
					local alpha = (yDifference - spec.handle.lowerLimit) / spec.handle.interpolateDistance
					setRotation(spec.handle.node, spec.handle.maxRot * alpha, 0, 0)
				end
			end
		end
		if spec.spine.node ~= nil and spec.spine.doAdjustment then
			setRotation(spec.spine.node, 0, 0, spec.spine.currentRotation * spec.spine.ratio[1])
			local spine1 = getChildAt(spec.spine.node, 0)
			setRotation(spine1, 0, 0, spec.spine.currentRotation * spec.spine.ratio[2])
			local spine2 = getChildAt(spine1, 0)
			setRotation(spine2, 0, 0, spec.spine.currentRotation * spec.spine.ratio[3])
		end
		if not spec.driveMode.isActive and (self:getIsAnimationPlaying(spec.driveMode.animationName) and (spec.driveMode.vehicleCharacter == nil and spec.ikChains ~= nil)) then
			for chainId, target in pairs(spec.ikChainTargets) do
				IKUtil.setIKChainDirty(spec.ikChains, chainId)
			end
			IKUtil.updateIKChains(spec.ikChains)
			for target, source in pairs(spec.characterIKNodes) do
				if entityExists(target) and entityExists(source) then
					setTranslation(target, getTranslation(source))
					setRotation(target, getRotation(source))
				end
			end
			for ikChainId, target in pairs(spec.ikChainTargets) do
				IKUtil.setIKChainPose(spec.ikChains, ikChainId, target.poseId)
			end
		end
	end
end
function PushHandTool:getRaycastPosition(node)
	local spec = self.spec_pushHandTool
	local x, y, z = getWorldTranslation(node)
	local dirX, dirY, dirZ = localDirectionToWorld(node, 0, -1, 0)
	dirY = dirY * 1.5
	spec.lastRaycastHit = false
	raycastAll(x, y, z, dirX, dirY, dirZ, 2, "playerRaycastCallback", self, PushHandTool.PLAYER_COLLISION_MASK)
	if spec.lastRaycastHit and (0.35 < spec.lastRaycastPosition[4] and spec.lastRaycastPosition[2] < y - 0.25) then
		return unpack(spec.lastRaycastPosition)
	end
	return nil
end
function PushHandTool:playerRaycastCallback(hitObjectId, x, y, z, distance)
	local spec = self.spec_pushHandTool
	local vehicle = g_currentMission.nodeToObject[hitObjectId]
	if vehicle ~= nil and vehicle == self then
		return true
	end
	spec.lastRaycastPosition[1] = x
	spec.lastRaycastPosition[2] = y
	spec.lastRaycastPosition[3] = z
	spec.lastRaycastPosition[4] = distance
	spec.lastRaycastHit = true
	return false
end
