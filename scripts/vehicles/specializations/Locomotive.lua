source("dataS/scripts/vehicles/specializations/events/LocomotiveStateEvent.lua")
Locomotive = {}
Locomotive.STATE_NONE = 0
Locomotive.STATE_MANUAL_TRAVEL_ACTIVE = 1
Locomotive.STATE_MANUAL_TRAVEL_INACTIVE = 2
Locomotive.STATE_AUTOMATIC_TRAVEL_ACTIVE = 3
Locomotive.STATE_REQUESTED_POSITION = 4
Locomotive.STATE_REQUESTED_POSITION_BRAKING = 5
Locomotive.NUM_BITS_STATE = 3
Locomotive.AUTOMATIC_DRIVE_DELAY = 1500000

function Locomotive.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(SplineVehicle, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(Drivable, specializations)
	end
	return v2_
end
function Locomotive.initSpecialization()
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("Locomotive")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.locomotive.powerArm#node", "Power arm node")
	v3_:setXMLSpecializationType()
end

function Locomotive.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onAutomatedTrainTravelActive")
end

function Locomotive.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getDownhillForce", Locomotive.getDownhillForce)
	SpecializationUtil.registerFunction(vehicleType, "getLocomotiveSpeed", Locomotive.getLocomotiveSpeed)
	SpecializationUtil.registerFunction(vehicleType, "setRequestedSplinePosition", Locomotive.setRequestedSplinePosition)
	SpecializationUtil.registerFunction(vehicleType, "getDistanceToRequestedPosition", Locomotive.getDistanceToRequestedPosition)
	SpecializationUtil.registerFunction(vehicleType, "setLocomotiveState", Locomotive.setLocomotiveState)
	SpecializationUtil.registerFunction(vehicleType, "startAutomatedTrainTravel", Locomotive.startAutomatedTrainTravel)
	SpecializationUtil.registerFunction(vehicleType, "notifyPlayerFarmChanged", Locomotive.notifyPlayerFarmChanged)
end

function Locomotive.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMotorStarted", Locomotive.getIsMotorStarted)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateVehiclePhysics", Locomotive.updateVehiclePhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsReadyForAutomatedTrainTravel", Locomotive.getIsReadyForAutomatedTrainTravel)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "alignToSplineTime", Locomotive.alignToSplineTime)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setTrainSystem", Locomotive.setTrainSystem)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFullName", Locomotive.getFullName)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreSurfaceSoundsActive", Locomotive.getAreSurfaceSoundsActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTraveledDistanceStatsActive", Locomotive.getTraveledDistanceStatsActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsEnterable", Locomotive.getIsEnterable)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMapHotspotVisible", Locomotive.getIsMapHotspotVisible)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeReset", Locomotive.getCanBeReset)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getStopMotorOnLeave", Locomotive.getStopMotorOnLeave)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getMapHotspotPosition", Locomotive.getMapHotspotPosition)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getMotorRpmReal", Locomotive.getMotorRpmReal)
end

function Locomotive.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Locomotive)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Locomotive)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Locomotive)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Locomotive)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Locomotive)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", Locomotive)
	SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", Locomotive)
end

-- Local values: spec
function Locomotive:onLoad(savegame)
	local v9_ = self.spec_locomotive
	self.serverMass = 1
	v9_.powerArm = self.xmlFile:getValue("vehicle.locomotive.powerArm#node", nil, self.components, self.i3dMappings)
	v9_.electricitySpline = nil
	v9_.lastVirtualRpm = self:getMotor():getMinRpm()
	v9_.speed = 0
	v9_.lastAcceleration = 0
	v9_.nextMovingDirection = 0
	v9_.sellingDirection = 1
	v9_.startBrakeDistance = 0
	v9_.startBrakeSpeed = 0
	self:setLocomotiveState(Locomotive.STATE_NONE)
	v9_.motor = self:getMotor()
	v9_.doStartCheck = true
	g_messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, self.notifyPlayerFarmChanged, self)
	g_messageCenter:subscribe(MessageType.PLAYER_CREATED, self.notifyPlayerFarmChanged, self)
end

function Locomotive:onDelete()
	g_messageCenter:unsubscribeAll(self)
end

function Locomotive:onReadStream(streamId, connection)
	self.spec_locomotive.state = streamReadUIntN(streamId, Locomotive.NUM_BITS_STATE)
end

function Locomotive:onWriteStream(streamId, connection)
	streamWriteUIntN(streamId, self.spec_locomotive.state, Locomotive.NUM_BITS_STATE)
end

-- Local values: spec, splineLength, currentPosition, requestedPosition, targetDirection, brakeAcceleration, brakeDistance, brakePoint, pendingDirectionChange, brakeAcceleration, brakeDistance
function Locomotive:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v17_ = self.spec_locomotive
	if v17_.doStartCheck and self.trainSystem ~= nil then
		if self.trainSystem:getIsRented() then
			self:setLocomotiveState(Locomotive.STATE_MANUAL_TRAVEL_ACTIVE)
		else
			self:startAutomatedTrainTravel()
		end
		self:raiseActive()
		v17_.doStartCheck = false
	end
	if self.isServer then
		if v17_.state == Locomotive.STATE_AUTOMATIC_TRAVEL_ACTIVE then
			self:raiseActive()
			self:updateVehiclePhysics(1, 0, 0, dt)
			SpecializationUtil.raiseEvent(self, "onAutomatedTrainTravelActive", dt)
			return
		end
		if v17_.state == Locomotive.STATE_REQUESTED_POSITION then
			if v17_.requestedSplinePosition ~= nil then
				local v18_ = self.trainSystem:getSplineLength()
				local v19_ = self:getCurrentSplinePosition() % 1
				local v20_ = v17_.requestedSplinePosition % 1
				local v21_ = v20_ - v19_
				local v22_ = math.sign(v21_)
				local v23_ = Locomotive.getBrakeAcceleration(self)
				local v24_ = v17_.speed ^ 2 / (2 * v23_)
				local v25_ = math.abs(v24_)
				local v26_ = (v20_ - v25_ / v18_ * v22_) % 1
				if (v22_ == self.movingDirection and true or self.movingDirection == 0) and (v22_ >= 0 and (v26_ < v19_ and v19_ < v26_ + 0.5) or v22_ < 0 and (v19_ < v26_ and v26_ - 0.5 < v19_)) then
					self:setLocomotiveState(Locomotive.STATE_REQUESTED_POSITION_BRAKING)
					v17_.startBrakeDistance = v25_
					v17_.startBrakeSpeed = v17_.speed
				else
					self:updateVehiclePhysics(v22_, 0, 0, dt)
				end
				self:raiseActive()
				return
			end
		elseif v17_.state == Locomotive.STATE_REQUESTED_POSITION_BRAKING then
			local v27_ = Locomotive.getBrakeAcceleration(self)
			local v28_ = v17_.startBrakeSpeed ^ 2 / (2 * v27_)
			if math.abs(v28_) < v17_.startBrakeDistance - 10 then
				self:setLocomotiveState(Locomotive.STATE_REQUESTED_POSITION)
			end
			if self.movingDirection > 0 then
				self:updateVehiclePhysics(-1, 0, 0, dt)
			else
				self:updateVehiclePhysics(1, 0, 0, dt)
			end
			self:raiseActive()
			if v17_.speed == 0 then
				self:setLocomotiveState(Locomotive.STATE_MANUAL_TRAVEL_ACTIVE)
				self:stopMotor()
				return
			end
		elseif v17_.state == Locomotive.STATE_MANUAL_TRAVEL_INACTIVE then
			if self.movingDirection > 0 then
				self:updateVehiclePhysics(-1, 0, 0, dt)
			elseif self.movingDirection < 0 then
				self:updateVehiclePhysics(1, 0, 0, dt)
			end
			self:raiseActive()
			return
		end
	elseif v17_.state == Locomotive.STATE_AUTOMATIC_TRAVEL_ACTIVE or (v17_.state == Locomotive.STATE_REQUESTED_POSITION or v17_.state == Locomotive.STATE_REQUESTED_POSITION_BRAKING) then
		self:raiseActive()
	end
end

-- Local values: spec, spline, electricitySplineLength, splineLength
function Locomotive:setTrainSystem(superFunc, trainSystem)
	superFunc(self, trainSystem)
	local v32_ = self.spec_locomotive
	if v32_.powerArm ~= nil then
		local v33_ = trainSystem:getElectricitySpline()
		if v33_ ~= nil then
			local v34_ = trainSystem:getElectricitySplineLength()
			local v35_ = v34_ - trainSystem:getSplineLength()
			v32_.splineDiff = math.abs(v35_)
			v32_.electricitySplineSearchTime = v32_.splineDiff * 5 / v34_
			v32_.electricitySpline = v33_
		end
	end
end

-- Local values: storeItem
function Locomotive:getFullName(superFunc)
	return g_storeManager:getItemByXMLFilename(self.configFileName).name
end

function Locomotive:getAreSurfaceSoundsActive(superFunc)
	return self:getLastSpeed() > 0.1
end

-- Local values: spec
function Locomotive:getTraveledDistanceStatsActive(superFunc)
	return self.spec_locomotive.state == Locomotive.STATE_MANUAL_TRAVEL_ACTIVE
end

-- Local values: spec
function Locomotive:getIsEnterable(superFunc)
	if not superFunc(self) then
		return false
	end
	if self.trainSystem ~= nil and not self.trainSystem:getIsTrainInDriveableRange() then
		return false
	end
	local v41_ = self.spec_locomotive
	return v41_.state == Locomotive.STATE_MANUAL_TRAVEL_ACTIVE and true or v41_.state == Locomotive.STATE_MANUAL_TRAVEL_INACTIVE
end

-- Local values: x, _, z
function Locomotive:getIsMapHotspotVisible(superFunc)
	if not superFunc(self) then
		return false
	end
	if self.trainSystem ~= nil and not self.trainSystem:getIsTrainInDriveableRange() then
		return false
	end
	local v44_, _, v45_ = getWorldTranslation(self.rootNode)
	return math.abs(v44_) <= g_currentMission.terrainSize * 0.5 and math.abs(v45_) <= g_currentMission.terrainSize * 0.5
end

function Locomotive:getMapHotspotPosition(superFunc)
	if self.trainSystem == nil then
		return 0, 0, 0
	else
		return self.trainSystem:getTrainPosition()
	end
end

function Locomotive:getMotorRpmReal(superFunc)
	return self.spec_locomotive.lastVirtualRpm
end

-- Local values: spec, currentPosition, requestedPosition
function Locomotive:setRequestedSplinePosition(splinePosition, noEventSend)
	local v50_ = self.spec_locomotive
	v50_.requestedSplinePosition = splinePosition
	self:setLocomotiveState(Locomotive.STATE_REQUESTED_POSITION, true)
	local v51_ = self:getCurrentSplinePosition()
	local v52_ = v50_.requestedSplinePosition
	if v50_.requestedSplinePosition < v51_ then
		local v53_ = v51_ - (v52_ + 1)
		local v54_ = math.abs(v53_)
		local v55_ = v51_ - v52_
		if v54_ < math.abs(v55_) then
			v50_.requestedSplinePosition = v52_ + 1
		end
	end
	if self.isServer then
		self:startMotor()
	end
end

-- Local values: spec, currentPosition, requestedPosition, distanceToGo
function Locomotive:getDistanceToRequestedPosition()
	local v57_ = self.spec_locomotive
	if v57_.state ~= Locomotive.STATE_REQUESTED_POSITION_BRAKING and v57_.state ~= Locomotive.STATE_REQUESTED_POSITION then
		return 0
	end
	local v58_ = self:getCurrentSplinePosition()
	local v59_ = v57_.requestedSplinePosition % 1 - v58_
	local v60_ = math.abs(v59_)
	return v57_.state == Locomotive.STATE_REQUESTED_POSITION_BRAKING and v60_ > 0.5 and 0 or v60_ * self.trainSystem:getSplineLength()
end

-- Local values: spec
function Locomotive:setLocomotiveState(state, noEventSend)
	self.spec_locomotive.state = state
	if state == Locomotive.STATE_AUTOMATIC_TRAVEL_ACTIVE then
		if self.setRandomVehicleCharacter ~= nil then
			self:setRandomVehicleCharacter()
		end
	elseif state == Locomotive.STATE_MANUAL_TRAVEL_ACTIVE then
		self:restoreVehicleCharacter()
	end
	if g_server ~= nil and not noEventSend then
		g_server:broadcastEvent(LocomotiveStateEvent.new(self, state), nil, nil, self)
	end
	self:raiseActive()
end

function Locomotive:startAutomatedTrainTravel()
	self:setLocomotiveState(Locomotive.STATE_AUTOMATIC_TRAVEL_ACTIVE)
	self:startMotor()
end

function Locomotive:notifyPlayerFarmChanged()
	if self.trainSystem ~= nil then
		local v66_ = self.trainSystem.isRented
		if v66_ then
			v66_ = g_localPlayer.farmId == self.trainSystem.rentFarmId
		end
		self:setIsTabbable(v66_)
	end
end

-- Local values: spec
function Locomotive:onLeaveVehicle()
	local v68_ = self.spec_locomotive
	if v68_.state ~= Locomotive.STATE_AUTOMATIC_TRAVEL_ACTIVE then
		if self:getIsReadyForAutomatedTrainTravel() then
			v68_.automaticTravelStartTime = g_time + Locomotive.AUTOMATIC_DRIVE_DELAY
		end
		self:setLocomotiveState(Locomotive.STATE_MANUAL_TRAVEL_INACTIVE)
		self:raiseActive()
		v68_.requestedSplinePosition = nil
	end
end

-- Local values: spec
function Locomotive:onEnterVehicle()
	local v70_ = self.spec_locomotive
	v70_.requestedSplinePosition = nil
	v70_.automaticTravelStartTime = nil
	if not g_currentMission.missionInfo.automaticMotorStartEnabled and (v70_.state == Locomotive.STATE_AUTOMATIC_TRAVEL_ACTIVE or (v70_.state == Locomotive.STATE_REQUESTED_POSITION or v70_.state == Locomotive.STATE_REQUESTED_POSITION_BRAKING)) then
		self:startMotor(true)
	end
	self:setLocomotiveState(Locomotive.STATE_MANUAL_TRAVEL_ACTIVE)
end

function Locomotive:getIsReadyForAutomatedTrainTravel(superFunc)
	if self:getIsControlled() then
		return false
	else
		return superFunc(self)
	end
end

-- Local values: spec
function Locomotive:getIsMotorStarted(superFunc)
	local v75_ = self.spec_locomotive
	return superFunc(self) or ((v75_.state == Locomotive.STATE_AUTOMATIC_TRAVEL_ACTIVE or v75_.state == Locomotive.STATE_REQUESTED_POSITION) and true or v75_.state == Locomotive.STATE_REQUESTED_POSITION_BRAKING)
end

-- Local values: dirX, dirY, dirZ, angleX
function Locomotive:getDownhillForce()
	local v77_, v78_, v79_ = localDirectionToWorld(self.rootNode, 0, 0, 1)
	local v80_ = v78_ / MathUtil.vector3Length(v77_, v78_, v79_)
	local v81_ = math.acos(v80_) - 1.5707963267948966
	local v82_ = self.serverMass * 9.81
	local v83_ = -v81_
	return v82_ * math.sin(v83_)
end

function Locomotive:getLocomotiveSpeed()
	return self.spec_locomotive.speed
end

-- Local values: spec, downhillForce, maxBrakeForce, brakeForce, sign, brakeForceSum
function Locomotive:getBrakeAcceleration()
	local v86_ = self.spec_locomotive
	local v87_ = self:getDownhillForce()
	local v88_ = self.serverMass * 9.81 * 0.18
	local v89_ = v86_.speed
	if math.abs(v89_) >= 0.3 and self:getIsControlled() then
		v88_ = v88_ * 0.05
	end
	local v90_ = v88_ * (v86_.speed < 0 and -1 or 1)
	local v91_ = -v90_ - v87_
	if math.abs(v91_) < 0.0001 then
		v91_ = -v90_ - v87_ * 0.95
	end
	return 1 / self.serverMass * v91_
end

-- Local values: spec, specDrivable, acceleration, interpDt, tractiveEffort, maxBrakeForce, downhillForce, reverserDirection, cruiseControlSpeed, a, a, brakeForce, motor, minRpm, maxRpm
function Locomotive:updateVehiclePhysics(superFunc, axisForward, axisSide, doHandbrake, dt)
	local v98_ = self.spec_locomotive
	local v99_ = self.spec_drivable
	local v100_ = superFunc(self, axisForward * v98_.sellingDirection, axisSide, doHandbrake, dt)
	local v101_ = g_physicsDt
	if g_server == nil then
		v101_ = g_physicsDtUnclamped
	end
	local v102_ = self.serverMass * 9.81 * 0.18
	local v103_ = self:getDownhillForce()
	local v104_ = math.min(300000, v102_)
	if self:getIsMotorStarted() then
		local v105_ = v99_ == nil and 1 or v99_.reverserDirection
		if self:getCruiseControlState() ~= Drivable.CRUISECONTROL_STATE_OFF then
			local v106_ = self:getCruiseControlSpeed() / 3.6
			if v98_.speed < v105_ * v106_ then
				v100_ = 1
			elseif v98_.speed > v105_ * v106_ then
				v100_ = -1
			end
		end
	else
		v104_ = v102_
	end
	if math.abs(v100_) < 0.001 then
		local v107_ = Locomotive.getBrakeAcceleration(self)
		if v98_.speed > 0 then
			local v108_ = v98_.speed + v107_ * dt / 1000
			v98_.speed = math.max(0, v108_)
		elseif v98_.speed < 0 then
			local v109_ = v98_.speed + v107_ * dt / 1000
			v98_.speed = math.min(0, v109_)
		elseif v102_ < math.abs(v103_) then
			v98_.speed = v98_.speed + v107_ * dt / 1000
		end
		if v98_.speed == 0 then
			v98_.hasStopped = true
		else
			v98_.hasStopped = false
		end
	else
		local v110_ = v98_.speed
		if math.abs(v110_) > 0.1 then
			v98_.hasStopped = false
		else
			local v111_ = v98_.speed
			if math.abs(v111_) == 0 then
				v98_.hasStopped = true
			end
		end
		if v98_.hasStopped == nil or v98_.hasStopped and math.abs(v100_) > 0.01 then
			v98_.nextMovingDirection = math.sign(v100_)
		end
		local v112_ = 0
		if v98_.nextMovingDirection == nil or v98_.nextMovingDirection * v100_ > 0 then
			local v113_ = v100_ * v104_
			v112_ = 1 / self.serverMass * (v113_ - 0 - v103_)
		else
			local v114_ = 0
			local v115_ = v98_.speed
			local v116_ = math.sign(v115_) * math.abs(v100_) * v102_
			local v117_ = v98_.speed
			if math.abs(v117_) < 0.1 then
				v98_.speed = 0
			else
				v112_ = 1 / self.serverMass * (v114_ - v116_ - v103_)
			end
		end
		v98_.speed = v98_.speed + v112_ * v101_ / 1000
	end
	local v118_ = v98_.motor
	if v98_.speed > 0 then
		local v119_ = v98_.speed
		local v120_ = v118_.maxForwardSpeed
		v98_.speed = math.min(v119_, v120_)
	elseif v98_.speed < 0 then
		local v121_ = v98_.speed
		local v122_ = -v118_.maxBackwardSpeed
		v98_.speed = math.max(v121_, v122_)
	end
	local v123_ = v118_.minRpm
	local v124_ = v118_.maxRpm
	if v98_.lastAcceleration * v98_.nextMovingDirection > 0 then
		local v125_ = v98_.lastVirtualRpm + 0.0005 * dt * (v124_ - v123_)
		v98_.lastVirtualRpm = math.min(v124_, v125_)
	else
		local v126_ = v98_.lastVirtualRpm - 0.001 * dt * (v124_ - v123_)
		v98_.lastVirtualRpm = math.max(v123_, v126_)
	end
	v118_:setEqualizedMotorRpm(v98_.lastVirtualRpm)
	v98_.lastAcceleration = v100_
end

-- Local values: retValue, spec, x, y, z, cx, cy, cz, _
function Locomotive:alignToSplineTime(superFunc, spline, yOffset, tFront)
	local v132_ = superFunc(self, spline, yOffset, tFront)
	if v132_ ~= nil then
		local v133_ = self.spec_locomotive
		if v133_.powerArm ~= nil and v133_.electricitySpline ~= nil then
			local v134_, v135_, v136_ = getWorldTranslation(v133_.powerArm)
			local v137_, v138_, v139_ = getWorldTranslation(g_cameraManager:getActiveCamera())
			if MathUtil.vector3Length(v134_ - v137_, v135_ - v138_, v136_ - v139_) < 50 then
				v132_ = SplineUtil.getValidSplineTime(v132_)
				local v140_, v141_, v142_, _ = getLocalClosestSplinePosition(v133_.electricitySpline, v132_, v133_.electricitySplineSearchTime, v134_, v135_, v136_, 0.01)
				local _, v143_, _ = worldToLocal(getParent(v133_.powerArm), v140_, v141_, v142_)
				local v144_, _, v145_ = getTranslation(v133_.powerArm)
				setTranslation(v133_.powerArm, v144_, v143_, v145_)
				if v133_.powerArm ~= nil then
					self:setMovingToolDirty(v133_.powerArm)
				end
			end
		end
	end
	if not self.isServer then
		self:updateMapHotspot()
	end
	return v132_
end

function Locomotive:getCanBeReset(superFunc)
	return false
end

function Locomotive:getStopMotorOnLeave(superFunc)
	return self.spec_locomotive.state == Locomotive.STATE_MANUAL_TRAVEL_ACTIVE and true or self.spec_locomotive.state == Locomotive.STATE_MANUAL_TRAVEL_INACTIVE
end
