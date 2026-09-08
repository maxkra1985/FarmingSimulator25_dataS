PushHandTool = {}
PushHandTool.PLAYER_COLLISION_MASK = PlayerCCT.DEFAULT_MOVEMENT_COLLISION_MASK
source("dataS/scripts/vehicles/specializations/events/PushHandToolDriveModeEvent.lua")
function PushHandTool.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("PushHandTool")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.pushHandTool.raycast#node1", "Front raycast node")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.pushHandTool.raycast#node2", "Back raycast node")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.pushHandTool.raycast#playerNode", "Player node to adjust")
	v1_:register(XMLValueType.FLOAT, "vehicle.pushHandTool.raycast#positionSmoothnessFactor", "Defines how delayed the player position can be (lower value is a higher delay)", 1)
	v1_:register(XMLValueType.FLOAT, "vehicle.pushHandTool.raycast#positionSmoothnessFactorReverse", "Smoothness factor while reversing", "same as #positionSmoothnessFactor")
	v1_:register(XMLValueType.FLOAT, "vehicle.pushHandTool.raycast#positionSmoothnessFactorSteering", "Defines additional delay when the vehicle is fully steered (high value is a higher delay)", 0.15)
	v1_:register(XMLValueType.VECTOR_N, "vehicle.pushHandTool.wheels#front", "Indices of front wheels")
	v1_:register(XMLValueType.VECTOR_N, "vehicle.pushHandTool.wheels#back", "Indices of back wheels")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.pushHandTool.handle#node", "Handle node")
	v1_:register(XMLValueType.FLOAT, "vehicle.pushHandTool.handle#upperLimit", "Max. upper distance between handle node and hand ik root node", 0.4)
	v1_:register(XMLValueType.FLOAT, "vehicle.pushHandTool.handle#lowerLimit", "Max. lower distance between handle node and hand ik root node", 0.4)
	v1_:register(XMLValueType.FLOAT, "vehicle.pushHandTool.handle#interpolateDistance", "Interpolation distance if limit is exceeded", 0.4)
	v1_:register(XMLValueType.ANGLE, "vehicle.pushHandTool.handle#minRot", "Min. rotation of handle", -20)
	v1_:register(XMLValueType.ANGLE, "vehicle.pushHandTool.handle#maxRot", "Max. rotation of handle", 20)
	v1_:register(XMLValueType.ANGLE, "vehicle.pushHandTool.spine#rotationForward", "Spine rotation while moving forward")
	v1_:register(XMLValueType.ANGLE, "vehicle.pushHandTool.spine#rotationBackward", "Spine rotation while moving backward")
	v1_:register(XMLValueType.ANGLE, "vehicle.pushHandTool.spine#rotationIdle", "Spine rotation while in idle position")
	v1_:register(XMLValueType.ANGLE, "vehicle.pushHandTool.spine#speed", "Speed of adjustment (degree per second)", 10)
	v1_:register(XMLValueType.VECTOR_3, "vehicle.pushHandTool.spine#ratio", "Ratio between the 3 spine nodes to apply the rotation", "0.33 0.33 0.33")
	IKUtil.registerIKChainTargetsXMLPaths(v1_, "vehicle.pushHandTool.ikChains")
	EffectManager.registerEffectXMLPaths(v1_, "vehicle.pushHandTool.effect")
	v1_:register(XMLValueType.STRING, "vehicle.pushHandTool.driveMode#animationName", "Name of toggle mode animation", 0)
	v1_:register(XMLValueType.FLOAT, "vehicle.pushHandTool.driveMode#animationSpeed", "Animation speed scale", 1)
	v1_:register(XMLValueType.FLOAT, "vehicle.pushHandTool.driveMode#maxSpeed", "Max. vehicle speed while drive mode is enabled")
	v1_:register(XMLValueType.FLOAT, "vehicle.pushHandTool.driveMode#gearRatio", "Min. gear ratio while drive mode is enabled")
	VehicleCharacter.registerCharacterXMLPaths(v1_, "vehicle.pushHandTool.driveMode.characterNode")
	v1_:register(XMLValueType.STRING, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#chainId", "Chain identifier string", 20)
	v1_:register(XMLValueType.INT, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#nodeIndex", "Index of node")
	v1_:register(XMLValueType.ANGLE, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#minRx", "Min. X rotation")
	v1_:register(XMLValueType.ANGLE, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#maxRx", "Max. X rotation")
	v1_:register(XMLValueType.ANGLE, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#minRy", "Min. Y rotation")
	v1_:register(XMLValueType.ANGLE, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#maxRy", "Max. Y rotation")
	v1_:register(XMLValueType.ANGLE, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#minRz", "Min. Z rotation")
	v1_:register(XMLValueType.ANGLE, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#maxRz", "Max. Z rotation")
	v1_:register(XMLValueType.FLOAT, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#damping", "Damping")
	v1_:register(XMLValueType.BOOL, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#localLimits", "Local limits")
	ConditionalAnimation.registerXMLPaths(v1_, "vehicle.pushHandTool.playerConditionalAnimation")
	v1_:setXMLSpecializationType()
	Vehicle.xmlSchemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).pushHandTool#driveModeIsActive", "DriveMode is active")
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

-- Local values: spec, frontWheels, i, wheel, backWheels, i, wheel
function PushHandTool:onLoad(savegame)
	local v_u_7_ = self.spec_pushHandTool
	v_u_7_.animationParameters = {}
	v_u_7_.animationParameters.absSmoothedForwardVelocity = {
		["id"] = 1,
		["value"] = 0,
		["type"] = 1
	}
	v_u_7_.animationParameters.smoothedForwardVelocity = {
		["id"] = 2,
		["value"] = 0,
		["type"] = 1
	}
	v_u_7_.animationParameters.accelerate = {
		["id"] = 3,
		["value"] = false,
		["type"] = 0
	}
	v_u_7_.animationParameters.leftRightWeight = {
		["id"] = 4,
		["value"] = 0,
		["type"] = 1
	}
	v_u_7_.raycastNode1 = self.xmlFile:getValue("vehicle.pushHandTool.raycast#node1", nil, self.components, self.i3dMappings)
	v_u_7_.raycastNode2 = self.xmlFile:getValue("vehicle.pushHandTool.raycast#node2", nil, self.components, self.i3dMappings)
	v_u_7_.playerNode = self.xmlFile:getValue("vehicle.pushHandTool.raycast#playerNode", nil, self.components, self.i3dMappings)
	v_u_7_.playerTargetNode = createTransformGroup("playerTargetNode")
	if v_u_7_.playerNode ~= nil then
		link(getParent(v_u_7_.playerNode), v_u_7_.playerTargetNode)
		setTranslation(v_u_7_.playerTargetNode, getTranslation(v_u_7_.playerNode))
	end
	v_u_7_.positionSmoothnessFactor = self.xmlFile:getValue("vehicle.pushHandTool.raycast#positionSmoothnessFactor", 1)
	v_u_7_.positionSmoothnessFactorReverse = self.xmlFile:getValue("vehicle.pushHandTool.raycast#positionSmoothnessFactorReverse", v_u_7_.positionSmoothnessFactor)
	v_u_7_.positionSmoothnessFactorSteering = self.xmlFile:getValue("vehicle.pushHandTool.raycast#positionSmoothnessFactorSteering", 0.15)
	local v8_ = self.xmlFile:getValue("vehicle.pushHandTool.wheels#front", nil, true)
	v_u_7_.frontWheels = {}
	if v8_ ~= nil then
		for v9_ = 1, #v8_ do
			local v10_ = self:getWheelFromWheelIndex(v8_[v9_])
			if v10_ ~= nil then
				local v11_ = v_u_7_.frontWheels
				table.insert(v11_, v10_)
			end
		end
	end
	local v12_ = self.xmlFile:getValue("vehicle.pushHandTool.wheels#back", nil, true)
	v_u_7_.backWheels = {}
	if v12_ ~= nil then
		for v13_ = 1, #v12_ do
			local v14_ = self:getWheelFromWheelIndex(v12_[v13_])
			if v14_ ~= nil then
				local v15_ = v_u_7_.backWheels
				table.insert(v15_, v14_)
			end
		end
	end
	v_u_7_.handle = {}
	v_u_7_.handle.node = self.xmlFile:getValue("vehicle.pushHandTool.handle#node", nil, self.components, self.i3dMappings)
	v_u_7_.handle.upperLimit = self.xmlFile:getValue("vehicle.pushHandTool.handle#upperLimit", 0.4)
	v_u_7_.handle.lowerLimit = self.xmlFile:getValue("vehicle.pushHandTool.handle#lowerLimit", 0.4)
	v_u_7_.handle.interpolateDistance = self.xmlFile:getValue("vehicle.pushHandTool.handle#interpolateDistance", 0.4)
	v_u_7_.handle.minRot = self.xmlFile:getValue("vehicle.pushHandTool.handle#minRot", -20)
	v_u_7_.handle.maxRot = self.xmlFile:getValue("vehicle.pushHandTool.handle#maxRot", 20)
	v_u_7_.spine = {}
	v_u_7_.spine.node = nil
	v_u_7_.spine.rotationForward = self.xmlFile:getValue("vehicle.pushHandTool.spine#rotationForward")
	v_u_7_.spine.rotationBackward = self.xmlFile:getValue("vehicle.pushHandTool.spine#rotationBackward")
	v_u_7_.spine.rotationIdle = self.xmlFile:getValue("vehicle.pushHandTool.spine#rotationIdle")
	v_u_7_.spine.speed = self.xmlFile:getValue("vehicle.pushHandTool.spine#speed", 10) * 0.001
	v_u_7_.spine.ratio = self.xmlFile:getValue("vehicle.pushHandTool.spine#ratio", "0.33 0.33 0.33", true)
	v_u_7_.spine.currentRotation = v_u_7_.spine.rotationIdle
	local v16_ = v_u_7_.spine
	local v17_
	if v_u_7_.spine.rotationForward == nil or v_u_7_.spine.rotationBackward == nil then
		v17_ = false
	else
		v17_ = v_u_7_.spine.rotationIdle ~= nil
	end
	v16_.doAdjustment = v17_
	v_u_7_.characterIKNodes = {}
	v_u_7_.ikChainTargets = {}
	IKUtil.loadIKChainTargets(self.xmlFile, "vehicle.pushHandTool.ikChains", self.components, v_u_7_.ikChainTargets, self.i3dMappings)
	v_u_7_.lastRaycastPosition = {
		0,
		0,
		0,
		0
	}
	v_u_7_.lastRaycastHit = false
	if self.isClient then
		v_u_7_.cutterEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.pushHandTool.effect", self.components, self, self.i3dMappings)
	end
	v_u_7_.customChainLimits = {}
	self.xmlFile:iterate("vehicle.pushHandTool.customChainLimits.customChainLimit", function(_, p18_)
		-- upvalues: (copy) self, (copy) v_u_7_
		local v19_ = {
			["chainId"] = self.xmlFile:getValue(p18_ .. "#chainId"),
			["nodeIndex"] = self.xmlFile:getValue(p18_ .. "#nodeIndex")
		}
		if v19_.chainId ~= nil and v19_.nodeIndex ~= nil then
			v19_.minRx = self.xmlFile:getValue(p18_ .. "#minRx")
			v19_.maxRx = self.xmlFile:getValue(p18_ .. "#maxRx")
			v19_.minRy = self.xmlFile:getValue(p18_ .. "#minRy")
			v19_.maxRy = self.xmlFile:getValue(p18_ .. "#maxRy")
			v19_.minRz = self.xmlFile:getValue(p18_ .. "#minRz")
			v19_.maxRz = self.xmlFile:getValue(p18_ .. "#maxRz")
			v19_.damping = self.xmlFile:getValue(p18_ .. "#damping")
			v19_.localLimits = self.xmlFile:getValue(p18_ .. "#localLimits")
			local v20_ = v_u_7_.customChainLimits
			table.insert(v20_, v19_)
		end
	end)
	v_u_7_.driveMode = {}
	v_u_7_.driveMode.animationName = self.xmlFile:getValue("vehicle.pushHandTool.driveMode#animationName")
	v_u_7_.driveMode.animationSpeed = self.xmlFile:getValue("vehicle.pushHandTool.driveMode#animationSpeed", 1)
	v_u_7_.driveMode.baseSpeed = self.spec_motorized.motor.maxForwardSpeed
	v_u_7_.driveMode.baseGearRatio = self.spec_motorized.motor.minForwardGearRatio
	v_u_7_.driveMode.maxSpeed = self.xmlFile:getValue("vehicle.pushHandTool.driveMode#maxSpeed")
	if v_u_7_.driveMode.maxSpeed ~= nil then
		v_u_7_.driveMode.maxSpeed = v_u_7_.driveMode.maxSpeed / 3.6
	end
	v_u_7_.driveMode.gearRatio = self.xmlFile:getValue("vehicle.pushHandTool.driveMode#gearRatio")
	v_u_7_.driveMode.vehicleCharacter = VehicleCharacter.new(self)
	if v_u_7_.driveMode.vehicleCharacter ~= nil and not v_u_7_.driveMode.vehicleCharacter:load(self.xmlFile, "vehicle.pushHandTool.driveMode.characterNode") then
		v_u_7_.driveMode.vehicleCharacter = nil
	end
	v_u_7_.driveMode.isActive = false
	v_u_7_.effectDirtyFlag = self:getNextDirtyFlag()
	v_u_7_.effectsAreRunning = false
	v_u_7_.lastFruitTypeIndex = FruitType.UNKNOWN
	v_u_7_.lastFruitGrowthState = 0
	v_u_7_.raycastsValid = true
	v_u_7_.lastSmoothSpeed = 0
	if self.setTestAreaRequirements ~= nil then
		self:setTestAreaRequirements(FruitType.GRASS, nil, false)
	end
	v_u_7_.postAnimationCallback = addPostAnimationCallback(self.postAnimationUpdate, self)
end

-- Local values: spec
function PushHandTool:onPostLoad(savegame)
	local v23_ = self.spec_pushHandTool
	if savegame ~= nil and savegame.xmlFile:getValue(savegame.key .. ".pushHandTool#driveModeIsActive", false) then
		self:setPushHandToolDriveMode(true, true)
		AnimatedVehicle.updateAnimationByName(self, v23_.driveMode.animationName, 99999, true)
	end
end

-- Local values: spec
function PushHandTool:onDelete()
	local v25_ = self.spec_pushHandTool
	g_effectManager:deleteEffects(v25_.cutterEffects)
	removePostAnimationCallback(v25_.postAnimationCallback)
end

-- Local values: spec
function PushHandTool:saveToXMLFile(xmlFile, key, usedModNames)
	local v29_ = self.spec_pushHandTool
	if v29_.driveMode.animationName ~= nil then
		xmlFile:setValue(key .. "#driveModeIsActive", v29_.driveMode.isActive)
	end
end

-- Local values: spec
function PushHandTool:onReadStream(streamId, connection)
	local v32_ = self.spec_pushHandTool
	self:setPushHandToolDriveMode(streamReadBool(streamId), true)
	AnimatedVehicle.updateAnimationByName(self, v32_.driveMode.animationName, 99999, true)
end

-- Local values: spec
function PushHandTool:onWriteStream(streamId, connection)
	local v35_ = self.spec_pushHandTool
	streamWriteBool(streamId, v35_.driveMode.isActive)
end

-- Local values: spec, effectsAreRunning
function PushHandTool:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local v39_ = self.spec_pushHandTool
		local v40_ = streamReadBool(streamId)
		if v40_ then
			v39_.lastFruitGrowthState = streamReadUIntN(streamId, 4)
			v39_.lastFruitTypeIndex = streamReadUIntN(streamId, FruitTypeManager.SEND_NUM_BITS)
		end
		if v40_ ~= v39_.effectsAreRunning then
			v39_.effectsAreRunning = v40_
			if not v40_ then
				g_effectManager:stopEffects(v39_.cutterEffects)
			end
		end
	end
end

-- Local values: spec
function PushHandTool:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v44_ = self.spec_pushHandTool
		if streamWriteBool(streamId, v44_.effectsAreRunning) then
			streamWriteUIntN(streamId, v44_.lastFruitGrowthState, 4)
			streamWriteUIntN(streamId, v44_.lastFruitTypeIndex, FruitTypeManager.SEND_NUM_BITS)
		end
	end
end

-- Local values: spec, currentTestAreaMinX, currentTestAreaMaxX, testAreaMinX, testAreaMaxX, reset, t, inputFruitType, inputGrowthState, isActive, specMower, lastSpeed, avgSpeed, numWheels, _, wheel, wheelSpeed, character, _, parameter, targetRotation, direction, limit, x1, y1, z1, x2, y2, z2, tx, ty, tz, dirX, dirY, dirZ, cx, cy, cz, smoothFactor, moveX, moveY, moveZ, newX, newY, newZ, direction, dirY2, _, fcx, fcy, fcz, numFrontWheels, i, wheel, wx, wy, wz, bcx, bcy, bcz, numBackWheels, i, wheel, wx, wy, wz, wDirX, wDirY, wDirZ, dir, upX, upY, upZ, character
function PushHandTool:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v47_ = self.spec_pushHandTool
	if self.getTestAreaWidthByWorkAreaIndex ~= nil then
		if self:getIsTurnedOn() and self:getLastSpeed() > 0.5 then
			local v48_, v49_, v50_, v51_ = self:getTestAreaWidthByWorkAreaIndex(1)
			local v52_
			if v48_ == -math.huge and v49_ == math.huge then
				v48_ = 0
				v49_ = 0
				v52_ = true
			else
				v52_ = false
			end
			local v53_
			if self.movingDirection > 0 then
				v53_ = v48_ * -1
				v48_ = v49_ * -1
				if v48_ >= v53_ then
					local v54_ = v53_
					v53_ = v48_
					v48_ = v54_
				end
			else
				v53_ = v49_
			end
			local v55_, v56_, v57_
			if self.isServer then
				v55_ = FruitType.UNKNOWN
				v56_ = 3
				if self.spec_mower ~= nil then
					local v58_ = self.spec_mower
					if g_time - v58_.workAreaParameters.lastCutTime < 500 then
						v55_ = v58_.workAreaParameters.lastInputFruitType
						v56_ = v58_.workAreaParameters.lastInputGrowthState
					end
				end
				v57_ = not v52_
				if v57_ then
					if v55_ == nil then
						v57_ = false
					else
						v57_ = v55_ ~= FruitType.UNKNOWN
					end
				end
				if v57_ then
					if not v47_.effectsAreRunning then
						v47_.effectsAreRunning = true
						self:raiseDirtyFlags(v47_.effectDirtyFlag)
					end
				elseif v47_.effectsAreRunning then
					g_effectManager:stopEffects(v47_.cutterEffects)
					v47_.effectsAreRunning = false
					self:raiseDirtyFlags(v47_.effectDirtyFlag)
				end
				v47_.lastFruitTypeIndex = v55_
				v47_.lastFruitGrowthState = v56_
			else
				v55_ = v47_.lastFruitTypeIndex
				v56_ = v47_.lastFruitGrowthState
				v57_ = v47_.effectsAreRunning
				if v57_ then
					v57_ = v47_.lastFruitTypeIndex ~= FruitType.UNKNOWN
				end
			end
			if v57_ then
				g_effectManager:setEffectTypeInfo(v47_.cutterEffects, nil, v55_, v56_)
				g_effectManager:setMinMaxWidth(v47_.cutterEffects, v48_, v53_, v48_ / v50_, v53_ / v51_, v52_)
				g_effectManager:startEffects(v47_.cutterEffects)
			end
		elseif v47_.effectsAreRunning then
			g_effectManager:stopEffects(v47_.cutterEffects)
			v47_.effectsAreRunning = false
			self:raiseDirtyFlags(v47_.effectDirtyFlag)
		end
	end
	local v59_ = self.lastSignedSpeed * 1000
	local v60_ = 0
	local v61_ = 0
	for _, v62_ in pairs(v47_.backWheels) do
		if v62_.physics.netInfo.xDriveSpeed ~= nil then
			v60_ = v60_ + MathUtil.rpmToMps(v62_.physics.netInfo.xDriveSpeed / 6.283185307179586 * 60, v62_.physics.radius) * 1000
			v61_ = v61_ + 1
		end
	end
	if v61_ > 0 then
		v59_ = v60_ / v61_
	end
	v47_.lastSmoothSpeed = v47_.lastSmoothSpeed * 0.9 + v59_ * 0.1
	v47_.animationParameters.smoothedForwardVelocity.value = v47_.lastSmoothSpeed
	local v63_ = v47_.animationParameters.absSmoothedForwardVelocity
	local v64_ = v47_.lastSmoothSpeed
	v63_.value = math.abs(v64_)
	v47_.animationParameters.leftRightWeight.value = self.rotatedTime
	v47_.animationParameters.accelerate.value = self:getAccelerationAxis() > 0
	if self:getIsEntered() or (self:getIsControlled() or self:getIsAIActive()) then
		local v65_ = self:getVehicleCharacter()
		if v65_ ~= nil and (v65_.animationCharsetId ~= nil and v65_.animationPlayer ~= nil) then
			for _, v66_ in pairs(v47_.animationParameters) do
				if v66_.type == 0 then
					setConditionalAnimationBoolValue(v65_.animationPlayer, v66_.id, v66_.value)
				elseif v66_.type == 1 then
					setConditionalAnimationFloatValue(v65_.animationPlayer, v66_.id, v66_.value)
				end
			end
			setConditionalAnimationSpecificParameterIds(v65_.animationPlayer, v47_.animationParameters.absSmoothedForwardVelocity.id, 0)
			updateConditionalAnimation(v65_.animationPlayer, dt)
		end
		if v47_.driveMode.vehicleCharacter ~= nil and (v47_.driveMode.isActive and not self:getIsAnimationPlaying(v47_.driveMode.animationName)) then
			v47_.driveMode.vehicleCharacter:update(dt)
		end
	end
	if v47_.spine.doAdjustment then
		local v67_ = v47_.spine.rotationIdle
		if self:getLastSpeed() > 0.75 then
			if self.movingDirection > 0 then
				v67_ = v47_.spine.rotationForward
			elseif self.movingDirection < 0 then
				v67_ = v47_.spine.rotationBackward
			end
		end
		local v68_ = v67_ - v47_.spine.currentRotation
		local v69_ = math.sign(v68_)
		local v70_ = v69_ > 0 and math.min or math.max
		v47_.spine.currentRotation = v70_(v47_.spine.currentRotation + v69_ * dt * v47_.spine.speed, v67_)
	end
	if v47_.raycastNode1 ~= nil and (v47_.raycastNode2 ~= nil and (v47_.playerNode ~= nil and (#v47_.frontWheels >= 1 and #v47_.backWheels >= 1))) then
		local v71_, v72_, v73_ = self:getRaycastPosition(v47_.raycastNode1)
		local v74_, v75_, v76_ = self:getRaycastPosition(v47_.raycastNode2)
		if v71_ ~= nil and v74_ ~= nil then
			local v77_ = (v71_ + v74_) * 0.5
			local v78_ = (v72_ + v75_) * 0.5
			local v79_ = (v73_ + v76_) * 0.5
			setWorldTranslation(v47_.playerTargetNode, v77_, v78_, v79_)
			local v80_ = v71_ - v74_
			local v81_ = v72_ - v75_
			local v82_ = v73_ - v76_
			local v83_, v84_, v85_ = MathUtil.vector3Normalize(v80_, v81_, v82_)
			if v47_.lastYDirection == nil then
				v47_.lastYDirection = v84_
			else
				v84_ = v47_.lastYDirection * 0.9 + v84_ * 0.1
				v47_.lastYDirection = v84_
			end
			I3DUtil.setWorldDirection(v47_.playerTargetNode, v83_, v84_, v85_, 0, 1, 0)
			if v47_.lastWorldTrans == nil then
				v47_.lastWorldTrans = { getWorldTranslation(v47_.playerNode) }
			end
			local v86_ = v47_.lastWorldTrans[1]
			local v87_ = v47_.lastWorldTrans[2]
			local v88_ = v47_.lastWorldTrans[3]
			local v89_ = self.rotatedTime / 0.5
			local v90_ = math.abs(v89_)
			local v91_ = (0.3 - math.min(v90_, 1) * v47_.positionSmoothnessFactorSteering) * (self.movingDirection > 0 and v47_.positionSmoothnessFactor or v47_.positionSmoothnessFactorReverse)
			local v92_ = (v86_ - v77_) * v91_
			local v93_ = (v87_ - v78_) * v91_
			local v94_ = (v88_ - v79_) * v91_
			local v95_ = v86_ - v92_
			local v96_ = v87_ - v93_
			local v97_ = v88_ - v94_
			setWorldTranslation(v47_.playerNode, v95_, v96_, v97_)
			local v98_ = v47_.lastWorldTrans
			local v99_ = v47_.lastWorldTrans
			local v100_ = v47_.lastWorldTrans
			v98_[1] = v95_
			v99_[2] = v96_
			v100_[3] = v97_
			local v101_ = self.movingDirection
			local v102_ = v101_ == 0 and 1 or v101_
			local v103_, v104_, v105_ = localToWorld(v47_.playerTargetNode, 0, 0, 0.2 * v102_)
			local v106_ = v103_ - v95_
			local v107_ = v104_ - v96_
			local v108_ = v105_ - v97_
			local v109_, _, v110_ = MathUtil.vector3Normalize(v106_, v107_, v108_)
			if v102_ < 0 then
				v109_ = -v109_
				v110_ = -v110_
			end
			local v111_ = #v47_.frontWheels
			local v112_ = 0
			local v113_ = 0
			local v114_ = 0
			for v115_ = 1, v111_ do
				local v116_ = v47_.frontWheels[v115_]
				local v117_ = v116_.physics.netInfo.x
				local v118_ = v116_.physics.netInfo.y
				local v119_ = v116_.physics.netInfo.z
				local v120_ = v118_ - v116_.physics.radius
				local v121_, v122_, v123_ = localToWorld(v116_.node, v117_, v120_, v119_)
				v112_ = v112_ + v121_
				v113_ = v113_ + v122_
				v114_ = v114_ + v123_
			end
			local v124_ = v112_ / v111_
			local v125_ = v113_ / v111_
			local v126_ = v114_ / v111_
			local v127_ = #v47_.backWheels
			local v128_ = 0
			local v129_ = 0
			local v130_ = 0
			for v131_ = 1, v127_ do
				local v132_ = v47_.backWheels[v131_]
				local v133_ = v132_.physics.netInfo.x
				local v134_ = v132_.physics.netInfo.y
				local v135_ = v132_.physics.netInfo.z
				local v136_ = v134_ - v132_.physics.radius
				local v137_, v138_, v139_ = localToWorld(v132_.node, v133_, v136_, v135_)
				v128_ = v128_ + v137_
				v129_ = v129_ + v138_
				v130_ = v130_ + v139_
			end
			local v140_ = v128_ / v127_
			local v141_ = v129_ / v127_
			local v142_ = v130_ / v127_
			local v143_ = v140_ - v124_
			local v144_ = v141_ - v125_
			local v145_ = v142_ - v126_
			local _, v146_, _ = MathUtil.vector3Normalize(v143_, v144_, v145_)
			local v147_ = v146_ < 0 and 1 or -1
			local v148_ = math.abs(v146_)
			local v149_ = v146_ + math.min(0.15, v148_) * v147_
			local v150_, v151_, v152_ = localDirectionToWorld(self.rootNode, 0, 1, 0)
			local v153_ = v151_ + 0.5
			local v154_, v155_, v156_ = MathUtil.vector3Normalize(v150_, v153_, v152_)
			I3DUtil.setWorldDirection(v47_.playerNode, v109_, v149_, v110_, v154_, v155_, v156_)
			v47_.raycastsValid = true
			return
		end
		if v47_.raycastsValid and self:getIsEntered() then
			v47_.raycastsValid = false
			local v157_ = self:getVehicleCharacter()
			if v157_ ~= nil then
				v157_:setCharacterVisibility(false)
			end
			self:setActiveCameraIndex(self.spec_enterable.camIndex)
		end
	end
end

-- Local values: spec, _, actionEventId
function PushHandTool:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v160_ = self.spec_pushHandTool
		if v160_.driveMode.vehicleCharacter ~= nil then
			self:clearActionEventsTable(v160_.actionEvents)
			if isActiveForInputIgnoreSelection then
				local _, v161_ = self:addPoweredActionEvent(v160_.actionEvents, InputAction.IMPLEMENT_EXTRA4, self, PushHandTool.actionEventToggleDriveMode, false, true, false, true, 1)
				g_inputBinding:setActionEventTextPriority(v161_, GS_PRIO_NORMAL)
				g_inputBinding:setActionEventText(v161_, g_i18n:getText("action_changeDriveMode"))
			end
		end
	end
end

function PushHandTool:actionEventToggleDriveMode(actionName, inputValue, callbackState, isAnalog)
	self:setPushHandToolDriveMode()
end

-- Local values: enterableSpec, spec
function PushHandTool:setVehicleCharacter(superFunc, playerStyle)
	local v165_ = self.spec_enterable
	if v165_.vehicleCharacter ~= nil then
		v165_.vehicleCharacter:unloadCharacter()
		v165_.vehicleCharacter:loadCharacter(playerStyle, self, self.customVehicleCharacterLoaded)
	end
	local v166_ = self.spec_pushHandTool
	if v166_.driveMode.vehicleCharacter ~= nil and playerStyle ~= nil then
		v166_.driveMode.vehicleCharacter:loadCharacter(playerStyle, self, PushHandTool.driveModeVehicleCharacterLoaded, {})
	end
end

-- Local values: spec
function PushHandTool:deleteVehicleCharacter(superFunc)
	superFunc(self)
	local v169_ = self.spec_pushHandTool
	if v169_.driveMode.vehicleCharacter ~= nil then
		v169_.driveMode.vehicleCharacter:unloadCharacter()
	end
end

-- Local values: enterableSpec, character, spec, name, ikChain, k, nodeData, duplicate, parent, k, nodeData, ikChainId, target, name, ikChain, i, node, minRx, maxRx, minRy, maxRy, minRz, maxRz, damping, localLimits, j, customLimit, key, parameter
function PushHandTool:customVehicleCharacterLoaded(loadingState, arguments)
	local v172_ = self.spec_enterable
	if loadingState == HumanModelLoadingState.OK then
		local v173_ = v172_.vehicleCharacter
		if v173_ ~= nil then
			v173_:updateVisibility()
		end
		SpecializationUtil.raiseEvent(self, "onVehicleCharacterChanged", v173_)
		local v174_ = self.spec_pushHandTool
		v174_.characterIKNodes = {}
		v174_.spine.node = v173_.playerModel.thirdPersonSpineNode
		for v175_, v176_ in pairs(v173_.playerModel.ikChains) do
			if v174_.ikChainTargets[v175_] ~= nil then
				for _, v177_ in pairs(v176_.nodes) do
					if v174_.characterIKNodes[v177_.node] == nil then
						local v178_ = createTransformGroup(getName(v177_.node) .. "_ikChain")
						local v179_ = getParent(v177_.node)
						if v174_.characterIKNodes[v179_] ~= nil then
							v179_ = v174_.characterIKNodes[v179_]
						end
						link(v179_, v178_)
						setTranslation(v178_, getTranslation(v177_.node))
						setRotation(v178_, getRotation(v177_.node))
						v174_.characterIKNodes[v177_.node] = v178_
					end
				end
			end
			for _, v180_ in pairs(v176_.nodes) do
				if v174_.characterIKNodes[v180_.node] ~= nil then
					v180_.node = v174_.characterIKNodes[v180_.node]
				end
			end
		end
		v173_.ikChainTargets = v174_.ikChainTargets
		for v181_, v182_ in pairs(v174_.ikChainTargets) do
			IKUtil.setTarget(v173_.playerModel.ikChains, v181_, v182_)
		end
		v174_.ikChains = v173_.playerModel.ikChains
		for v183_, v184_ in pairs(v173_.playerModel.ikChains) do
			v184_.ikChainSolver = IKChain.new(#v184_.nodes)
			for v185_, v186_ in ipairs(v184_.nodes) do
				local v187_ = v186_.minRx
				local v188_ = v186_.maxRx
				local v189_ = v186_.minRy
				local v190_ = v186_.maxRy
				local v191_ = v186_.minRz
				local v192_ = v186_.maxRz
				local v193_ = v186_.damping
				local v194_ = v186_.localLimits
				for v195_ = 1, #v174_.customChainLimits do
					local v196_ = v174_.customChainLimits[v195_]
					if v196_.chainId == v183_ and v196_.nodeIndex == v185_ then
						v187_ = v196_.minRx or v187_
						v188_ = v196_.maxRx or v188_
						v189_ = v196_.minRy or v189_
						v190_ = v196_.maxRy or v190_
						v191_ = v196_.minRz or v191_
						v192_ = v196_.maxRz or v192_
						v193_ = v196_.damping or v193_
						if v196_.localLimits ~= nil then
							v194_ = v196_.localLimits
						end
					end
				end
				v184_.ikChainSolver:setJointTransformGroup(v185_ - 1, v186_.node, v187_, v188_, v189_, v190_, v191_, v192_, v193_, v194_)
			end
			v184_.numIterations = 40
			v184_.positionThreshold = 0.0001
		end
		v173_:setDirty()
		if v173_ ~= nil and (v173_.animationCharsetId ~= nil and v173_.animationPlayer ~= nil) then
			for v197_, v198_ in pairs(v174_.animationParameters) do
				conditionalAnimationRegisterParameter(v173_.animationPlayer, v198_.id, v198_.type, v197_)
			end
			initConditionalAnimation(v173_.animationPlayer, v173_.animationCharsetId, self.configFileName, "vehicle.pushHandTool.playerConditionalAnimation")
			conditionalAnimationZeroiseTrackTimes(v173_.animationPlayer)
		end
	end
end

-- Local values: spec, activeCamera
function PushHandTool:driveModeVehicleCharacterLoaded(loadingState, arguments)
	if loadingState == HumanModelLoadingState.OK then
		local v201_ = self.spec_pushHandTool
		if v201_.driveMode.vehicleCharacter ~= nil then
			local v202_ = self:getActiveCamera()
			if v202_ ~= nil then
				v201_.driveMode.vehicleCharacter:setCharacterVisibility(not v202_.isInside)
			end
			v201_.driveMode.vehicleCharacter:updateIKChains()
		end
	end
end

-- Local values: spec, character
function PushHandTool:setPushHandToolDriveMode(driveModeState, noEventSend)
	local v206_ = self.spec_pushHandTool
	if driveModeState == nil then
		driveModeState = not v206_.driveMode.isActive
	end
	if v206_.driveMode.isActive ~= driveModeState then
		v206_.driveMode.isActive = driveModeState
		self.spec_motorized.motor.maxForwardSpeed = driveModeState and v206_.driveMode.maxSpeed or v206_.driveMode.baseSpeed
		self.spec_motorized.motor.minForwardGearRatio = driveModeState and v206_.driveMode.gearRatio or v206_.driveMode.baseGearRatio
		self.spec_drivable.cruiseControl.maxSpeed = self.spec_motorized.motor.maxForwardSpeed * 3.6
		local v207_ = self.spec_drivable.cruiseControl.speed
		local v208_ = self.spec_drivable.cruiseControl.maxSpeed
		self:setCruiseControlMaxSpeed(math.min(v207_, v208_), nil)
		self:playAnimation(v206_.driveMode.animationName, driveModeState and v206_.driveMode.animationSpeed or -v206_.driveMode.animationSpeed, self:getAnimationTime(v206_.driveMode.animationName), true)
		self:setFoldState(self.spec_foldable.turnOnFoldDirection, false, true)
		if v206_.driveMode.vehicleCharacter ~= nil then
			local v209_ = self:getVehicleCharacter()
			if v209_ ~= nil then
				v209_:setCharacterVisibility(false)
			end
		end
	end
	PushHandToolDriveModeEvent.sendEvent(self, driveModeState, noEventSend)
end

-- Local values: activeCamera, spec
function PushHandTool:getAllowCharacterVisibilityUpdate(superFunc)
	if superFunc(self) then
		if self:getIsEntered() then
			local v212_ = self:getActiveCamera()
			if v212_ ~= nil and v212_.isInside then
				return false
			end
		end
		local v213_ = self.spec_pushHandTool
		if v213_.raycastsValid then
			if v213_.driveMode.isActive and v213_.driveMode.vehicleCharacter ~= nil then
				return false
			else
				return (v213_.driveMode.vehicleCharacter == nil or not self:getIsAnimationPlaying(v213_.driveMode.animationName)) and true or false
			end
		else
			return false
		end
	else
		return false
	end
end

-- Local values: spec, specEnterable, activeCamera, i, camera
function PushHandTool:setActiveCameraIndex(superFunc, index)
	if not self.spec_pushHandTool.raycastsValid then
		local v217_ = self.spec_enterable
		index = v217_.numCameras < index and 1 or index
		if v217_.cameras[index].isInside then
			for v218_, v219_ in pairs(v217_.cameras) do
				if not v219_.isInside then
					index = v218_
					break
				end
			end
		end
	end
	return superFunc(self, index)
end

-- Local values: spec
function PushHandTool:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	if self.spec_pushHandTool.driveMode.isActive then
		return false
	else
		return superFunc(self, direction, onAiTurnOn)
	end
end

-- Local values: hideCharacter, activeCamera, spec, character
function PushHandTool:onEnterVehicle(isControlling)
	local v226_ = false
	if isControlling then
		local v227_ = self:getActiveCamera()
		v226_ = v227_ ~= nil and v227_.isInside and true or v226_
	end
	if not self.spec_pushHandTool.raycastsValid and true or v226_ then
		local v228_ = self:getVehicleCharacter()
		if v228_ ~= nil then
			v228_:setCharacterVisibility(false)
		end
	end
end

-- Local values: spec, character
function PushHandTool:onCameraChanged(activeCamera, camIndex)
	if self:getIsEntered() then
		local v231_ = self.spec_pushHandTool
		local v232_ = self:getVehicleCharacter()
		if v232_ ~= nil and activeCamera.isInside then
			v232_:setCharacterVisibility(false)
		end
		if v231_.driveMode.vehicleCharacter ~= nil then
			v231_.driveMode.vehicleCharacter:setCharacterVisibility(not activeCamera.isInside)
		end
	end
end

-- Local values: activeCamera, spec
function PushHandTool:onVehicleCharacterChanged(character)
	if self:getIsEntered() and character ~= nil then
		local v235_ = self:getActiveCamera()
		if v235_ ~= nil and v235_.isInside then
			character:setCharacterVisibility(false)
		end
	end
	if character == nil then
		local v236_ = self.spec_pushHandTool
		v236_.characterIKNodes = {}
		v236_.spine.node = nil
	end
end

-- Local values: spec, yDifference, name, ikChain, node, targetNode, x, y, z, alpha, alpha, spine1, spine2, chainId, target, target, source, ikChainId, target
function PushHandTool:postAnimationUpdate(dt)
	if self.isActive then
		local v238_ = self.spec_pushHandTool
		if v238_.raycastsValid and (v238_.handle.node ~= nil and v238_.ikChains ~= nil) then
			local v239_ = nil
			for v240_, v241_ in pairs(v238_.ikChains) do
				local v242_ = v241_.nodes[1].node
				if v242_ ~= nil and v238_.ikChainTargets[v240_] ~= nil then
					local v243_ = v238_.ikChainTargets[v240_].targetNode
					if v243_ ~= nil then
						local v244_, v245_, v246_ = getRotation(v238_.handle.node)
						setRotation(v238_.handle.node, 0, 0, 0)
						if v239_ == nil then
							v239_ = calcDistanceFrom(v242_, v243_)
						else
							v239_ = (v239_ + calcDistanceFrom(v242_, v243_)) / 2
						end
						setRotation(v238_.handle.node, v244_, v245_, v246_)
					end
				end
			end
			if v239_ ~= nil then
				if v239_ < v238_.handle.upperLimit then
					local v247_ = (v238_.handle.upperLimit - v239_) / v238_.handle.interpolateDistance
					setRotation(v238_.handle.node, v238_.handle.minRot * v247_, 0, 0)
				elseif v238_.handle.lowerLimit < v239_ then
					local v248_ = (v239_ - v238_.handle.lowerLimit) / v238_.handle.interpolateDistance
					setRotation(v238_.handle.node, v238_.handle.maxRot * v248_, 0, 0)
				end
			end
		end
		if v238_.spine.node ~= nil and v238_.spine.doAdjustment then
			setRotation(v238_.spine.node, 0, 0, v238_.spine.currentRotation * v238_.spine.ratio[1])
			local v249_ = getChildAt(v238_.spine.node, 0)
			setRotation(v249_, 0, 0, v238_.spine.currentRotation * v238_.spine.ratio[2])
			local v250_ = getChildAt(v249_, 0)
			setRotation(v250_, 0, 0, v238_.spine.currentRotation * v238_.spine.ratio[3])
		end
		if (not (v238_.driveMode.isActive or self:getIsAnimationPlaying(v238_.driveMode.animationName)) or v238_.driveMode.vehicleCharacter == nil) and v238_.ikChains ~= nil then
			for v251_, _ in pairs(v238_.ikChainTargets) do
				IKUtil.setIKChainDirty(v238_.ikChains, v251_)
			end
			IKUtil.updateIKChains(v238_.ikChains)
			for v252_, v253_ in pairs(v238_.characterIKNodes) do
				if entityExists(v252_) and entityExists(v253_) then
					setTranslation(v252_, getTranslation(v253_))
					setRotation(v252_, getRotation(v253_))
				end
			end
			for v254_, v255_ in pairs(v238_.ikChainTargets) do
				IKUtil.setIKChainPose(v238_.ikChains, v254_, v255_.poseId)
			end
		end
	end
end

-- Local values: spec, x, y, z, dirX, dirY, dirZ
function PushHandTool:getRaycastPosition(node)
	local v258_ = self.spec_pushHandTool
	local v259_, v260_, v261_ = getWorldTranslation(node)
	local v262_, v263_, v264_ = localDirectionToWorld(node, 0, -1, 0)
	local v265_ = v263_ * 1.5
	v258_.lastRaycastHit = false
	raycastAll(v259_, v260_, v261_, v262_, v265_, v264_, 2, "playerRaycastCallback", self, PushHandTool.PLAYER_COLLISION_MASK)
	if not v258_.lastRaycastHit or (v258_.lastRaycastPosition[4] <= 0.35 or v258_.lastRaycastPosition[2] >= v260_ - 0.25) then
		return nil
	end
	local v266_ = v258_.lastRaycastPosition
	return unpack(v266_)
end

-- Local values: spec, vehicle
function PushHandTool:playerRaycastCallback(hitObjectId, x, y, z, distance)
	local v273_ = self.spec_pushHandTool
	local v274_ = g_currentMission.nodeToObject[hitObjectId]
	if v274_ ~= nil and v274_ == self then
		return true
	end
	v273_.lastRaycastPosition[1] = x
	v273_.lastRaycastPosition[2] = y
	v273_.lastRaycastPosition[3] = z
	v273_.lastRaycastPosition[4] = distance
	v273_.lastRaycastHit = true
	return false
end
