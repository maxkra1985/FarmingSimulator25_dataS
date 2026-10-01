WheelDebug = {}
function WheelDebug.new(wheel)
	local self = setmetatable({}, { __index = WheelDebug })
	self.wheel = wheel
	self.vehicle = wheel.vehicle
	return self
end
function WheelDebug:delete()
	if self.lateralFrictionGraph ~= nil then
		self.lateralFrictionGraph:delete()
	end
	if self.longitudalFrictionGraph ~= nil then
		self.longitudalFrictionGraph:delete()
	end
	if self.longitudalFrictionSlipOverlay ~= nil then
		delete(self.longitudalFrictionSlipOverlay)
	end
	if self.lateralFrictionSlipOverlay ~= nil then
		delete(self.lateralFrictionSlipOverlay)
	end
end
function WheelDebug:drawSlipGraphs()
	if not self.wheel.physics.wheelShapeCreated then
		return
	else
		local longSlip, latSlip = getWheelShapeSlip(self.wheel.node, self.wheel.physics.wheelShape)
		local gravity = 9.81
		local tireLoad = getWheelShapeContactForce(self.wheel.node, self.wheel.physics.wheelShape)
		if tireLoad ~= nil then
			local nx, ny, nz = getWheelShapeContactNormal(self.wheel.node, self.wheel.physics.wheelShape)
			local dx, dy, dz = localDirectionToWorld(self.wheel.node, 0, -1, 0)
			tireLoad = -tireLoad * MathUtil.dotProduct(dx, dy, dz, nx, ny, nz)
			tireLoad = tireLoad + math.max(ny * 9.81, 0) * self.wheel.physics.mass
		else
			tireLoad = 0
		end
		local longMaxSlip = 1
		local latMaxSlip = 0.9
		local sizeX = 0.11
		local sizeY = 0.15
		local spacingX = 0.028
		local spacingY = 0.013
		local x = 0.028 + 0.138 * (self.wheel.wheelIndex - 1)
		local longY = 0.837
		local latY = 0.6739999999999999
		local numGraphValues = 20
		if self.longitudalFrictionGraph == nil then
			self.longitudalFrictionGraph = Graph.new(20, x, 0.837, 0.11, 0.15, 0, 0.0001, true, "", Graph.STYLE_LINES)
			self.longitudalFrictionGraph:setColor(1, 1, 1, 1)
		else
			self.longitudalFrictionGraph.left = x
			self.longitudalFrictionGraph.bottom = longY
			self.longitudalFrictionGraph.width = sizeX
			self.longitudalFrictionGraph.height = sizeY
		end
		self.longitudalFrictionGraph.maxValue = 0.01
		for s = 1, 20 do
			local longForce, _ = computeWheelShapeTireForces(self.wheel.node, self.wheel.physics.wheelShape, (s - 1) / 19 * 1, latSlip, tireLoad)
			self.longitudalFrictionGraph:setValue(s, longForce)
			self.longitudalFrictionGraph.maxValue = math.max(self.longitudalFrictionGraph.maxValue, longForce)
		end
		if self.lateralFrictionGraph == nil then
			self.lateralFrictionGraph = Graph.new(20, x, 0.6739999999999999, 0.11, 0.15, 0, 0.0001, true, "", Graph.STYLE_LINES)
			self.lateralFrictionGraph:setColor(1, 1, 1, 1)
		else
			self.lateralFrictionGraph.left = x
			self.lateralFrictionGraph.bottom = latY
			self.lateralFrictionGraph.width = sizeX
			self.lateralFrictionGraph.height = sizeY
		end
		self.lateralFrictionGraph.maxValue = 0.01
		for s = 1, 20 do
			local _, latForce = computeWheelShapeTireForces(self.wheel.node, self.wheel.physics.wheelShape, longSlip, (s - 1) / 19 * 0.9, tireLoad)
			latForce = math.abs(latForce)
			self.lateralFrictionGraph:setValue(s, latForce)
			self.lateralFrictionGraph.maxValue = math.max(self.lateralFrictionGraph.maxValue, latForce)
		end
		if self.longitudalFrictionSlipOverlay == nil then
			self.longitudalFrictionSlipOverlay = createImageOverlay("dataS/menu/base/graph_pixel.png")
			setOverlayColor(self.longitudalFrictionSlipOverlay, 0, 1, 0, 0.2)
		end
		if self.lateralFrictionSlipOverlay == nil then
			self.lateralFrictionSlipOverlay = createImageOverlay("dataS/menu/base/graph_pixel.png")
			setOverlayColor(self.lateralFrictionSlipOverlay, 0, 1, 0, 0.2)
		end
		self.longitudalFrictionGraph:draw()
		self.lateralFrictionGraph:draw()
		local longForce, latForce = computeWheelShapeTireForces(self.wheel.node, self.wheel.physics.wheelShape, longSlip, latSlip, tireLoad)
		renderOverlay(self.longitudalFrictionSlipOverlay, x, 0.837, sizeX * math.min(math.abs(longSlip) / 1, 1), sizeY * math.min(math.abs(longForce) / self.longitudalFrictionGraph.maxValue, 1))
		renderOverlay(self.lateralFrictionSlipOverlay, x, 0.6739999999999999, sizeX * math.min(math.abs(latSlip) / 0.9, 1), sizeY * math.min(math.abs(latForce) / self.lateralFrictionGraph.maxValue, 1))
	end
end
function WheelDebug.getDebugValueHeader()
	return { "\n", "loSlip\n", "laSlip\n", "load\n", "frict.\n", "comp.\n", "rpm\n", "steer.\n", "radius\n", "loStiff\n", "laStiff\n", "mass[t]\n", "type\n", "deform\n", "contact\n" }
end
function WheelDebug:fillDebugValues(debugTable)
	local physics = self.wheel.physics
	if not physics.wheelShapeCreated then
		debugTable[1] = debugTable[1] .. "n/a\n"
		debugTable[2] = debugTable[2] .. "n/a\n"
		debugTable[3] = debugTable[3] .. "n/a\n"
		debugTable[4] = debugTable[4] .. "n/a\n"
		debugTable[5] = debugTable[5] .. "n/a\n"
		debugTable[6] = debugTable[6] .. "n/a\n"
		debugTable[7] = debugTable[7] .. "n/a\n"
		debugTable[8] = debugTable[8] .. "n/a\n"
		debugTable[9] = debugTable[9] .. "n/a\n"
		debugTable[10] = debugTable[10] .. "n/a\n"
		debugTable[11] = debugTable[11] .. "n/a\n"
		debugTable[12] = debugTable[12] .. "n/a\n"
		debugTable[13] = debugTable[13] .. "n/a\n"
		debugTable[14] = debugTable[14] .. "n/a\n"
		debugTable[15] = debugTable[15] .. "n/a\n"
	else
		local susp = 100 * (physics.netInfo.y - (physics.positionY + physics.deltaY - 1.2 * physics.suspTravel)) / physics.suspTravel - 20
		local rpm = getWheelShapeAxleSpeed(self.wheel.node, physics.wheelShape) * 30 / 3.141592653589793
		local longSlip, latSlip = getWheelShapeSlip(self.wheel.node, physics.wheelShape)
		debugTable[1] = debugTable[1] .. string.format("%d:\n", self.wheel.wheelIndex)
		debugTable[2] = debugTable[2] .. string.format("%2.2f\n", longSlip)
		debugTable[3] = debugTable[3] .. string.format("%2.2f\n", latSlip)
		debugTable[4] = debugTable[4] .. string.format("%2.2f\n", physics:getTireLoad())
		debugTable[5] = debugTable[5] .. string.format("%2.2f\n", physics.frictionScale * physics.tireGroundFrictionCoeff)
		debugTable[6] = debugTable[6] .. string.format("%1.0f%%\n", susp)
		debugTable[7] = debugTable[7] .. string.format("%3.1f\n", rpm)
		debugTable[8] = debugTable[8] .. string.format("%6.3f\n", math.deg(physics.steeringAngle))
		debugTable[9] = debugTable[9] .. string.format("%.2f\n", physics.radius)
		debugTable[10] = debugTable[10] .. string.format("%.2f\n", physics.maxLongStiffness)
		debugTable[11] = debugTable[11] .. string.format("%.2f\n", physics.maxLatStiffness)
		debugTable[12] = debugTable[12] .. string.format("%.2f\n", physics.mass)
		debugTable[13] = debugTable[13] .. string.format("%s\n", WheelsUtil.getTireTypeName(physics.tireType))
		local deformation = nil
		for _, visualWheel in ipairs(self.wheel.visualWheels) do
			for _, visualPart in ipairs(visualWheel.visualParts) do
				if visualPart.deformation == nil then
					continue
				end
				deformation = math.max(visualPart.deformation, deformation or 0)
			end
		end
		if deformation ~= nil then
			debugTable[14] = debugTable[14] .. string.format("%.3f\n", deformation)
		else
			debugTable[14] = debugTable[14] .. "-\n"
		end
		debugTable[15] = debugTable[15] .. string.format("%s\n", WheelContactType.getName(physics.contact))
	end
end
