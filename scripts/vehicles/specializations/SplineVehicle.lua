SplineVehicle = {}

function SplineVehicle.prerequisitesPresent(specializations)
	return true
end
function SplineVehicle.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("SplineVehicle")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.splineVehicle.dollies#frontNode", "Front node")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.splineVehicle.dollies#backNode", "Back node")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.splineVehicle.dollies#dolly1Node", "Front dolly node")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.splineVehicle.dollies#dolly2Node", "Back dolly node")
	v1_:register(XMLValueType.BOOL, "vehicle.splineVehicle.dollies#alignDollys", "Align dollies", true)
	v1_:register(XMLValueType.BOOL, Dischargeable.DISCHARGE_NODE_XML_PATH .. "#needsIsEntered", "Vehicle needs to be entered to do raycasting", true)
	v1_:register(XMLValueType.BOOL, Dischargeable.DISCHARGE_NODE_CONFIG_XML_PATH .. "#needsIsEntered", "Vehicle needs to be entered to do raycasting", true)
	v1_:setXMLSpecializationType()
end

function SplineVehicle.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getFrontToBackDistance", SplineVehicle.getFrontToBackDistance)
	SpecializationUtil.registerFunction(vehicleType, "getSplineTimeFromDistance", SplineVehicle.getSplineTimeFromDistance)
	SpecializationUtil.registerFunction(vehicleType, "getSplinePositionAndTimeFromDistance", SplineVehicle.getSplinePositionAndTimeFromDistance)
	SpecializationUtil.registerFunction(vehicleType, "alignToSplineTime", SplineVehicle.alignToSplineTime)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentSplinePosition", SplineVehicle.getCurrentSplinePosition)
	SpecializationUtil.registerFunction(vehicleType, "setSplineSpeed", SplineVehicle.setSplineSpeed)
end

function SplineVehicle.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getLastSpeed", SplineVehicle.getLastSpeed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setTrainSystem", SplineVehicle.setTrainSystem)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCurrentSurfaceSound", SplineVehicle.getCurrentSurfaceSound)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreSurfaceSoundsActive", SplineVehicle.getAreSurfaceSoundsActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDischargeNodeActive", SplineVehicle.getIsDischargeNodeActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDischargeNode", SplineVehicle.loadDischargeNode)
end

function SplineVehicle.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", SplineVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", SplineVehicle)
end

-- Local values: spec
function SplineVehicle:onLoad(savegame)
	local v6_ = self.spec_splineVehicle
	v6_.frontNode = self.xmlFile:getValue("vehicle.splineVehicle.dollies#frontNode", nil, self.components, self.i3dMappings)
	v6_.backNode = self.xmlFile:getValue("vehicle.splineVehicle.dollies#backNode", nil, self.components, self.i3dMappings)
	v6_.frontToBackDistance = calcDistanceFrom(v6_.frontNode, v6_.backNode)
	v6_.dolly1Node = self.xmlFile:getValue("vehicle.splineVehicle.dollies#dolly1Node", nil, self.components, self.i3dMappings)
	v6_.dolly2Node = self.xmlFile:getValue("vehicle.splineVehicle.dollies#dolly2Node", nil, self.components, self.i3dMappings)
	v6_.dollyToDollyDistance = calcDistanceFrom(v6_.dolly1Node, v6_.dolly2Node)
	v6_.rootNodeToBackDistance = calcDistanceFrom(v6_.backNode, self.rootNode)
	v6_.rootNodeToFrontDistance = calcDistanceFrom(v6_.frontNode, self.rootNode)
	v6_.alignDollys = self.xmlFile:getValue("vehicle.splineVehicle.dollies#alignDollys", true)
	v6_.splinePosition = 0
	v6_.lastSplinePosition = 0
	v6_.currentSplinePosition = 0
	v6_.splinePositionSpeed = 0
	v6_.splinePositionSpeedReal = 0
	v6_.splineSpeed = 0
end

function SplineVehicle:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.trainSystem ~= nil then
		self.trainSystem:updateRailroadVehiclePositions(dt)
	end
end

-- Local values: spec
function SplineVehicle:setTrainSystem(superFunc, trainSystem)
	superFunc(self, trainSystem)
	local v12_ = self.spec_splineVehicle
	v12_.splineLength = trainSystem:getSplineLength()
	v12_.frontToBackSplineTime = v12_.frontToBackDistance / v12_.splineLength
	v12_.dollyToDollySplineTime = v12_.dollyToDollyDistance / v12_.splineLength
	v12_.rootNodeToBackSplineTime = v12_.rootNodeToBackDistance / v12_.splineLength
	v12_.rootNodeToFrontSplineTime = v12_.rootNodeToFrontDistance / v12_.splineLength
end

-- Local values: spec
function SplineVehicle:setSplineSpeed(speed, speedReal)
	local v16_ = self.spec_splineVehicle
	v16_.splinePositionSpeed = speed
	v16_.splinePositionSpeedReal = speedReal
end

function SplineVehicle:getCurrentSplinePosition()
	return self.spec_splineVehicle.splinePosition
end

function SplineVehicle:getFrontToBackDistance()
	return self.spec_splineVehicle.frontToBackDistance
end

-- Local values: positiveTimeOffset, _, _, _, t2
function SplineVehicle:getSplineTimeFromDistance(t, distance, stepSize)
	if self.trainSystem ~= nil then
		local v23_ = stepSize >= 0
		local _, _, _, v24_ = getSplinePositionWithDistance(self.trainSystem:getSpline(), t, distance, v23_, 0.01)
		return SplineUtil.getValidSplineTime(v24_)
	end
end

-- Local values: positiveTimeOffset, x, y, z, t2
function SplineVehicle:getSplinePositionAndTimeFromDistance(t, distance, stepSize)
	if self.trainSystem ~= nil then
		local v29_ = stepSize >= 0
		local v30_, v31_, v32_, v33_ = getSplinePositionWithDistance(self.trainSystem:getSpline(), t, distance, v29_, 0.01)
		return v30_, v31_, v32_, SplineUtil.getValidSplineTime(v33_)
	end
end

-- Local values: spec, splineLength, maxDiff, delta, p1x, p1y, p1z, t, wp1x, wp1y, wp1z, p2x, p2y, p2z, t2, wp2x, wp2y, wp2z, qx, qy, qz, qw, networkInterpolators, d1x, d1y, d1z, d2x, d2y, d2z, tBack
function SplineVehicle:alignToSplineTime(spline, yOffset, tFront)
	if self.trainSystem ~= nil then
		local v38_ = self.spec_splineVehicle
		local v39_ = v38_.trainSystem:getSplineLength()
		local v40_ = self.trainSystem:getLengthSplineTime()
		local v41_ = math.max(v40_, 0.25)
		local v42_ = tFront - v38_.splinePosition
		if v41_ < math.abs(v42_) then
			if v42_ > 0 then
				v42_ = v42_ - 1
			else
				v42_ = v42_ + 1
			end
		end
		self.movingDirection = 1
		if v42_ < 0 then
			self.movingDirection = -1
		end
		local v43_, v44_, v45_, v46_ = self:getSplinePositionAndTimeFromDistance(tFront, v38_.rootNodeToFrontDistance, -1.2 * v38_.rootNodeToFrontSplineTime)
		local v47_, v48_, v49_ = localToWorld(getParent(spline), v43_, v44_, v45_)
		local v50_, v51_, v52_, v53_ = self:getSplinePositionAndTimeFromDistance(v46_, v38_.dollyToDollyDistance, -1.2 * v38_.dollyToDollySplineTime)
		local v54_, v55_, v56_ = localToWorld(getParent(spline), v50_, v51_, v52_)
		setDirection(self.rootNode, v47_ - v54_, v48_ - v55_, v49_ - v56_, 0, 1, 0)
		local v57_, v58_, v59_, v60_ = getWorldQuaternion(self.rootNode)
		setWorldTranslation(self.rootNode, v47_, v48_ + yOffset, v49_)
		local v61_ = self.components[1].networkInterpolators
		v61_.quaternion:setQuaternion(v57_, v58_, v59_, v60_)
		v61_.position:setPosition(v47_, v48_ + yOffset, v49_)
		if v38_.alignDollys then
			local v62_, v63_, v64_ = getSplineDirection(spline, v46_)
			local v65_, v66_, v67_ = getSplineDirection(spline, v53_)
			local v68_, v69_, v70_ = localDirectionToLocal(spline, getParent(v38_.dolly1Node), v62_, v63_, v64_)
			local v71_, v72_, v73_ = localDirectionToLocal(spline, getParent(v38_.dolly2Node), v65_, v66_, v67_)
			setDirection(v38_.dolly1Node, v68_, v69_, v70_, 0, 1, 0)
			setDirection(v38_.dolly2Node, v71_, v72_, v73_, 0, 1, 0)
		end
		v38_.splinePosition = tFront
		return tFront - v38_.frontToBackDistance / v39_
	end
end

function SplineVehicle:getLastSpeed(superFunc, useAttacherVehicleSpeed)
	local v75_ = self.spec_splineVehicle.splinePositionSpeed * 3.6
	return math.abs(v75_)
end

function SplineVehicle:getCurrentSurfaceSound()
	return self.spec_wheels.surfaceNameToSound.railroad
end

-- Local values: rootVehicle
function SplineVehicle:getAreSurfaceSoundsActive(superFunc)
	local v78_ = self.rootVehicle
	return (v78_ == nil or v78_ == self) and true or v78_:getAreSurfaceSoundsActive()
end

function SplineVehicle:loadDischargeNode(superFunc, xmlFile, key, entry)
	if not superFunc(self, xmlFile, key, entry) then
		return false
	end
	entry.needsIsEntered = xmlFile:getValue(key .. "#needsIsEntered", true)
	return true
end

-- Local values: rootVehicle
function SplineVehicle:getIsDischargeNodeActive(superFunc, dischargeNode)
	if dischargeNode.needsIsEntered then
		local v87_ = self:getRootVehicle()
		if v87_ ~= nil and (v87_.getIsControlled ~= nil and not v87_:getIsControlled()) then
			return false
		end
	end
	return superFunc(self, dischargeNode)
end
