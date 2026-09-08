WheelDebug = {}

-- Local values: self
function WheelDebug.new(wheel)
	local v2_ = {
		["__index"] = WheelDebug
	}
	local v3_ = setmetatable({}, v2_)
	v3_.wheel = wheel
	v3_.vehicle = wheel.vehicle
	return v3_
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

-- Local values: longSlip, latSlip, gravity, tireLoad, nx, ny, nz, dx, dy, dz, longMaxSlip, latMaxSlip, sizeX, sizeY, spacingX, spacingY, x, longY, latY, numGraphValues, s, longForce, _, s, _, latForce, longForce, latForce
function WheelDebug:drawSlipGraphs()
	if self.wheel.physics.wheelShapeCreated then
		local v6_, v7_ = getWheelShapeSlip(self.wheel.node, self.wheel.physics.wheelShape)
		local v8_ = getWheelShapeContactForce(self.wheel.node, self.wheel.physics.wheelShape)
		local v9_
		if v8_ == nil then
			v9_ = 0
		else
			local v10_, v11_, v12_ = getWheelShapeContactNormal(self.wheel.node, self.wheel.physics.wheelShape)
			local v13_, v14_, v15_ = localDirectionToWorld(self.wheel.node, 0, -1, 0)
			local v16_ = -v8_ * MathUtil.dotProduct(v13_, v14_, v15_, v10_, v11_, v12_)
			local v17_ = v11_ * 9.81
			v9_ = v16_ + math.max(v17_, 0) * self.wheel.physics.mass
		end
		local v18_ = 0.11
		local v19_ = 0.15
		local v20_ = 0.028 + 0.138 * (self.wheel.wheelIndex - 1)
		local v21_ = 0.837
		local v22_ = 0.6739999999999999
		if self.longitudalFrictionGraph == nil then
			self.longitudalFrictionGraph = Graph.new(20, v20_, 0.837, 0.11, 0.15, 0, 0.0001, true, "", Graph.STYLE_LINES)
			self.longitudalFrictionGraph:setColor(1, 1, 1, 1)
		else
			local v23_ = self.longitudalFrictionGraph
			local v24_ = self.longitudalFrictionGraph
			local v25_ = self.longitudalFrictionGraph
			local v26_ = self.longitudalFrictionGraph
			v23_.left = v20_
			v24_.bottom = v21_
			v25_.width = v18_
			v26_.height = v19_
		end
		self.longitudalFrictionGraph.maxValue = 0.01
		for v27_ = 1, 20 do
			local v28_, _ = computeWheelShapeTireForces(self.wheel.node, self.wheel.physics.wheelShape, (v27_ - 1) / 19 * 1, v7_, v9_)
			self.longitudalFrictionGraph:setValue(v27_, v28_)
			local v29_ = self.longitudalFrictionGraph
			local v30_ = self.longitudalFrictionGraph.maxValue
			v29_.maxValue = math.max(v30_, v28_)
		end
		if self.lateralFrictionGraph == nil then
			self.lateralFrictionGraph = Graph.new(20, v20_, 0.6739999999999999, 0.11, 0.15, 0, 0.0001, true, "", Graph.STYLE_LINES)
			self.lateralFrictionGraph:setColor(1, 1, 1, 1)
		else
			local v31_ = self.lateralFrictionGraph
			local v32_ = self.lateralFrictionGraph
			local v33_ = self.lateralFrictionGraph
			local v34_ = self.lateralFrictionGraph
			v31_.left = v20_
			v32_.bottom = v22_
			v33_.width = v18_
			v34_.height = v19_
		end
		self.lateralFrictionGraph.maxValue = 0.01
		for v35_ = 1, 20 do
			local _, v36_ = computeWheelShapeTireForces(self.wheel.node, self.wheel.physics.wheelShape, v6_, (v35_ - 1) / 19 * 0.9, v9_)
			local v37_ = math.abs(v36_)
			self.lateralFrictionGraph:setValue(v35_, v37_)
			local v38_ = self.lateralFrictionGraph
			local v39_ = self.lateralFrictionGraph.maxValue
			v38_.maxValue = math.max(v39_, v37_)
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
		local v40_, v41_ = computeWheelShapeTireForces(self.wheel.node, self.wheel.physics.wheelShape, v6_, v7_, v9_)
		local v42_ = renderOverlay
		local v43_ = self.longitudalFrictionSlipOverlay
		local v44_ = math.abs(v6_) / 1
		local v45_ = v18_ * math.min(v44_, 1)
		local v46_ = math.abs(v40_) / self.longitudalFrictionGraph.maxValue
		v42_(v43_, v20_, 0.837, v45_, v19_ * math.min(v46_, 1))
		local v47_ = renderOverlay
		local v48_ = self.lateralFrictionSlipOverlay
		local v49_ = math.abs(v7_) / 0.9
		local v50_ = v18_ * math.min(v49_, 1)
		local v51_ = math.abs(v41_) / self.lateralFrictionGraph.maxValue
		v47_(v48_, v20_, 0.6739999999999999, v50_, v19_ * math.min(v51_, 1))
	end
end
function WheelDebug.getDebugValueHeader()
	return {
		"\n",
		"loSlip\n",
		"laSlip\n",
		"load\n",
		"frict.\n",
		"comp.\n",
		"rpm\n",
		"steer.\n",
		"radius\n",
		"loStiff\n",
		"laStiff\n",
		"mass[t]\n",
		"type\n",
		"deform\n",
		"contact\n"
	}
end

-- Local values: physics, susp, rpm, longSlip, latSlip, deformation, _, visualWheel, _, visualPart
function WheelDebug:fillDebugValues(debugTable)
	local v54_ = self.wheel.physics
	if v54_.wheelShapeCreated then
		local v55_ = 100 * (v54_.netInfo.y - (v54_.positionY + v54_.deltaY - 1.2 * v54_.suspTravel)) / v54_.suspTravel - 20
		local v56_ = getWheelShapeAxleSpeed(self.wheel.node, v54_.wheelShape) * 30 / 3.141592653589793
		local v57_, v58_ = getWheelShapeSlip(self.wheel.node, v54_.wheelShape)
		debugTable[1] = debugTable[1] .. string.format("%d:\n", self.wheel.wheelIndex)
		debugTable[2] = debugTable[2] .. string.format("%2.2f\n", v57_)
		debugTable[3] = debugTable[3] .. string.format("%2.2f\n", v58_)
		debugTable[4] = debugTable[4] .. string.format("%2.2f\n", v54_:getTireLoad())
		debugTable[5] = debugTable[5] .. string.format("%2.2f\n", v54_.frictionScale * v54_.tireGroundFrictionCoeff)
		debugTable[6] = debugTable[6] .. string.format("%1.0f%%\n", v55_)
		debugTable[7] = debugTable[7] .. string.format("%3.1f\n", v56_)
		local v59_ = debugTable[8]
		local v60_ = string.format
		local v61_ = v54_.steeringAngle
		debugTable[8] = v59_ .. v60_("%6.3f\n", (math.deg(v61_)))
		debugTable[9] = debugTable[9] .. string.format("%.2f\n", v54_.radius)
		debugTable[10] = debugTable[10] .. string.format("%.2f\n", v54_.maxLongStiffness)
		debugTable[11] = debugTable[11] .. string.format("%.2f\n", v54_.maxLatStiffness)
		debugTable[12] = debugTable[12] .. string.format("%.2f\n", v54_.mass)
		debugTable[13] = debugTable[13] .. string.format("%s\n", WheelsUtil.getTireTypeName(v54_.tireType))
		local v62_ = nil
		for _, v63_ in ipairs(self.wheel.visualWheels) do
			for _, v64_ in ipairs(v63_.visualParts) do
				if v64_.deformation ~= nil then
					local v65_ = v64_.deformation
					v62_ = math.max(v65_, v62_ or 0)
				end
			end
		end
		if v62_ == nil then
			debugTable[14] = debugTable[14] .. "-\n"
		else
			debugTable[14] = debugTable[14] .. string.format("%.3f\n", v62_)
		end
		debugTable[15] = debugTable[15] .. string.format("%s\n", WheelContactType.getName(v54_.contact))
	else
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
	end
end
