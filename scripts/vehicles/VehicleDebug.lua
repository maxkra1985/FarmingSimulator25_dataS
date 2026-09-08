VehicleDebug = {}
VehicleDebug.DEBUG_COLORS = {
	Color.new(1, 0, 0, 1),
	Color.new(0, 1, 0, 1),
	Color.new(0, 0, 1, 1),
	Color.new(1, 1, 0, 1),
	Color.new(1, 0, 1, 1),
	Color.new(0, 1, 1, 1),
	Color.new(1, 1, 1, 1)
}
VehicleDebug.COLOR = {}
VehicleDebug.COLOR.ACTIVE = Color.new(0.5, 1, 0.5, 1)
VehicleDebug.COLOR.INACTIVE = Color.new(1, 0.1, 0.1, 1)
VehicleDebug.COLOR.GREY = Color.new(0.2, 0.2, 0.2, 1)
VehicleDebug.NONE = 0
VehicleDebug.DEBUG = 1
VehicleDebug.DEBUG_PHYSICS = 2
VehicleDebug.DEBUG_TUNING = 3
VehicleDebug.DEBUG_TRANSMISSION = 4
VehicleDebug.DEBUG_ATTRIBUTES = 5
VehicleDebug.DEBUG_ATTACHER_JOINTS = 6
VehicleDebug.DEBUG_AI = 7
VehicleDebug.DEBUG_SOUNDS = 8
VehicleDebug.DEBUG_ANIMATIONS = 9
VehicleDebug.STATE_NAMES = {}
VehicleDebug.STATE_NAMES[VehicleDebug.NONE] = "None"
VehicleDebug.STATE_NAMES[VehicleDebug.DEBUG] = "Values"
VehicleDebug.STATE_NAMES[VehicleDebug.DEBUG_PHYSICS] = "Physics"
VehicleDebug.STATE_NAMES[VehicleDebug.DEBUG_TUNING] = "Tuning"
VehicleDebug.STATE_NAMES[VehicleDebug.DEBUG_TRANSMISSION] = "Transmission"
VehicleDebug.STATE_NAMES[VehicleDebug.DEBUG_ATTRIBUTES] = "Attributes"
VehicleDebug.STATE_NAMES[VehicleDebug.DEBUG_ATTACHER_JOINTS] = "Attacher Joints"
VehicleDebug.STATE_NAMES[VehicleDebug.DEBUG_AI] = "AI"
VehicleDebug.STATE_NAMES[VehicleDebug.DEBUG_SOUNDS] = "Sounds"
VehicleDebug.STATE_NAMES[VehicleDebug.DEBUG_ANIMATIONS] = "Animations"
VehicleDebug.NUM_STATES = 9
VehicleDebug.state = 0
VehicleDebug.selectedAnimation = 0
if g_isDevelopmentVersion then
	VehicleDebug.state = 0
end

-- Local values: newState, n, stateIndex, stateName
function VehicleDebug.consoleCommandVehicleDebug(unusedSelf, stateStr)
	local v2_ = VehicleDebug.DEBUG
	if stateStr ~= nil then
		local v3_ = tonumber(stateStr)
		if v3_ == nil then
			for v4_, v5_ in pairs(VehicleDebug.STATE_NAMES) do
				if string.startsWith(string.lower(v5_), string.lower(stateStr)) then
					v2_ = v4_
				end
			end
		else
			v2_ = v3_
		end
	end
	VehicleDebug.setState(v2_)
	return string.format("VehicleDebug set to \'%s\'", VehicleDebug.STATE_NAMES[VehicleDebug.state])
end

-- Local values: i, _, actionEventId, i, _, upperEventId, _, lowerEventId, _, vehicle, wheelMaskUpdated, _, vehicle, i, wheel, ret, _, vehicle
function VehicleDebug.setState(state)
	if VehicleDebug.state == 0 then
		VehicleDebug.debugActionEvents = {}
		for v7_ = 1, VehicleDebug.NUM_STATES do
			local _, v8_ = g_inputBinding:registerActionEvent(InputAction["DEBUG_VEHICLE_" .. v7_], VehicleDebug, VehicleDebug.debugActionCallback, false, true, false, true, v7_)
			g_inputBinding:setActionEventTextVisibility(v8_, false)
			local v9_ = VehicleDebug.debugActionEvents
			table.insert(v9_, v8_)
		end
	elseif state == 0 then
		for v10_ = 1, #VehicleDebug.debugActionEvents do
			g_inputBinding:removeActionEvent(VehicleDebug.debugActionEvents[v10_])
		end
	end
	if state == VehicleDebug.DEBUG_ATTACHER_JOINTS then
		if VehicleDebug.attacherJointUpperEventId == nil and VehicleDebug.attacherJointLowerEventId == nil then
			local _, v11_ = g_inputBinding:registerActionEvent(InputAction.AXIS_FRONTLOADER_ARM, VehicleDebug, VehicleDebug.moveUpperRotation, false, false, true, true)
			g_inputBinding:setActionEventTextVisibility(v11_, false)
			VehicleDebug.attacherJointUpperEventId = v11_
			local _, v12_ = g_inputBinding:registerActionEvent(InputAction.AXIS_FRONTLOADER_TOOL, VehicleDebug, VehicleDebug.moveLowerRotation, false, false, true, true)
			g_inputBinding:setActionEventTextVisibility(v12_, false)
			VehicleDebug.attacherJointLowerEventId = v12_
		end
	else
		g_inputBinding:removeActionEvent(VehicleDebug.attacherJointUpperEventId)
		g_inputBinding:removeActionEvent(VehicleDebug.attacherJointLowerEventId)
		VehicleDebug.attacherJointUpperEventId = nil
		VehicleDebug.attacherJointLowerEventId = nil
	end
	if state == VehicleDebug.DEBUG_AI and g_currentMission ~= nil then
		for _, v13_ in pairs(g_currentMission.vehicleSystem.vehicles) do
			if v13_.spec_aiDrivable ~= nil and (v13_:getIsActiveForInput(true, true) and v13_.spec_aiDrivable.agentId ~= nil) then
				enableVehicleNavigationAgentDebugRendering(v13_.spec_aiDrivable.agentId, true)
			end
		end
	end
	local v14_ = false
	if state == VehicleDebug.DEBUG_TUNING then
		WheelPhysics.COLLISION_MASK = CollisionMask.ALL - CollisionFlag.TERRAIN_DISPLACEMENT
		v14_ = true
	elseif VehicleDebug.state == VehicleDebug.DEBUG_TUNING and WheelPhysics.COLLISION_MASK ~= CollisionMask.ALL then
		WheelPhysics.COLLISION_MASK = CollisionMask.ALL
		v14_ = true
	end
	if v14_ then
		for _, v15_ in pairs(g_currentMission.vehicleSystem.vehicles) do
			if v15_.getWheels ~= nil then
				for _, v16_ in ipairs(v15_:getWheels()) do
					v16_.physics:updateBase()
				end
			end
		end
	end
	local v17_ = false
	if VehicleDebug.state == state then
		VehicleDebug.state = 0
	else
		VehicleDebug.state = state
		v17_ = true
	end
	if g_currentMission ~= nil then
		for _, v18_ in pairs(g_currentMission.vehicleSystem.vehicles) do
			v18_:updateSelectableObjects()
			v18_:updateActionEvents()
			v18_:setSelectedVehicle(v18_)
		end
	end
	return v17_
end

-- Local values: motorSpec, motor, _, graph
function VehicleDebug:delete()
	if self.isServer then
		local v20_ = self.spec_motorized
		if v20_ ~= nil then
			local v21_ = v20_.motor
			if v21_ ~= nil then
				if v21_.debugCurveOverlay ~= nil then
					delete(v21_.debugCurveOverlay)
				end
				if v21_.debugTorqueGraph ~= nil then
					v21_.debugTorqueGraph:delete()
				end
				if v21_.debugPowerGraph ~= nil then
					v21_.debugPowerGraph:delete()
				end
				if v21_.debugGraphs ~= nil then
					for _, v22_ in ipairs(v21_.debugGraphs) do
						v22_:delete()
					end
				end
				if v21_.debugLoadGraph ~= nil then
					v21_.debugLoadGraph:delete()
				end
				if v21_.debugLoadGraphSmooth ~= nil then
					v21_.debugLoadGraphSmooth:delete()
				end
				if v21_.debugLoadGraphSound ~= nil then
					v21_.debugLoadGraphSound:delete()
				end
				if v21_.debugRPMGraphSmooth ~= nil then
					v21_.debugRPMGraphSmooth:delete()
				end
				if v21_.debugRPMGraphSound ~= nil then
					v21_.debugRPMGraphSound:delete()
				end
				if v21_.debugRPMGraph ~= nil then
					v21_.debugRPMGraph:delete()
				end
				if v21_.debugAccelerationGraph ~= nil then
					v21_.debugAccelerationGraph:delete()
				end
			end
		end
	end
end

function VehicleDebug:debugActionCallback(actionName, inputValue, callbackState, isAnalog)
	if VehicleDebug.state ~= callbackState then
		VehicleDebug.setState(callbackState)
		log(string.format("VehicleDebug set to \'%s\'", VehicleDebug.STATE_NAMES[VehicleDebug.state]))
	end
end

function VehicleDebug.updateDebug(vehicle, dt)
	if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
		VehicleDebug.drawDebugAttributeRendering(vehicle)
	elseif VehicleDebug.state == VehicleDebug.DEBUG_ATTACHER_JOINTS then
		VehicleDebug.drawDebugAttacherJoints(vehicle)
	elseif VehicleDebug.state == VehicleDebug.DEBUG_AI then
		VehicleDebug.drawDebugAIRendering(vehicle)
	elseif VehicleDebug.state == VehicleDebug.DEBUG_TUNING then
		VehicleDebug.updateTuningDebugRendering(vehicle, dt)
	end
	if VehicleDebug.state == VehicleDebug.DEBUG and (vehicle:getIsActiveForInput() or vehicle.rootVehicle ~= g_localPlayer:getCurrentVehicle()) then
		VehicleDebug.drawDebugValues(vehicle)
	end
end

-- Local values: v, i, partSize, x
function VehicleDebug.drawDebug(vehicle)
	if vehicle.getIsEntered ~= nil and vehicle:getIsEntered() then
		local v27_ = vehicle:getSelectedVehicle()
		if v27_ ~= nil then
			vehicle = v27_
		end
		if VehicleDebug.state == VehicleDebug.DEBUG_PHYSICS then
			VehicleDebug.drawDebugRendering(vehicle)
		elseif VehicleDebug.state == VehicleDebug.DEBUG_SOUNDS then
			VehicleDebug.drawSoundDebugValues(vehicle)
		elseif VehicleDebug.state == VehicleDebug.DEBUG_ANIMATIONS then
			VehicleDebug.drawAnimationDebug(vehicle)
		elseif VehicleDebug.state == VehicleDebug.DEBUG_TRANSMISSION then
			VehicleDebug.drawTransmissionDebug(vehicle)
		elseif VehicleDebug.state == VehicleDebug.DEBUG_TUNING then
			VehicleDebug.drawTuningDebug(vehicle)
		end
		if VehicleDebug.state > 0 then
			setTextAlignment(RenderText.ALIGN_CENTER)
			for v28_ = 1, VehicleDebug.NUM_STATES do
				local v29_ = 1 / (VehicleDebug.NUM_STATES + 1) * v28_
				if VehicleDebug.state == v28_ then
					setTextColor(0, 1, 0, 1)
					renderText(v29_, 0.01, 0.03, string.format("%s", VehicleDebug.STATE_NAMES[v28_]))
				else
					setTextColor(1, 1, 0, 1)
					renderText(v29_, 0.01, 0.015, string.format("SHIFT + %d: \'%s\'", v28_, VehicleDebug.STATE_NAMES[v28_]))
				end
			end
			setTextColor(1, 1, 1, 1)
			setTextAlignment(RenderText.ALIGN_LEFT)
		end
	end
end

-- Local values: i, i, _, actionEventId
function VehicleDebug.registerActionEvents(vehicle)
	if vehicle.getIsEntered ~= nil and (vehicle:getIsEntered() and VehicleDebug.state == VehicleDebug.DEBUG_ANIMATIONS) then
		vehicle:addActionEvent(vehicle.actionEvents, InputAction.DEBUG_PLAYER_ENABLE, vehicle, function()
			VehicleDebug.selectedAnimation = VehicleDebug.selectedAnimation + 1
		end, false, true, false, true, nil)
	end
	if VehicleDebug.state > 0 then
		if VehicleDebug.debugActionEvents ~= nil then
			for v31_ = 1, #VehicleDebug.debugActionEvents do
				g_inputBinding:removeActionEvent(VehicleDebug.debugActionEvents[v31_])
			end
		end
		VehicleDebug.debugActionEvents = {}
		for v32_ = 1, 9 do
			local _, v33_ = g_inputBinding:registerActionEvent(InputAction["DEBUG_VEHICLE_" .. v32_], VehicleDebug, VehicleDebug.debugActionCallback, false, true, false, true, v32_)
			g_inputBinding:setActionEventTextVisibility(v33_, false)
			local v34_ = VehicleDebug.debugActionEvents
			table.insert(v34_, v33_)
		end
	end
end

-- Local values: vx, _, vz, fieldOwned, str1, str2, str3, str4, motorSpec, diffSpeed, motor, torque, neededPtoTorque, motorPower, ptoPower, ptoLoad, fuelFillUnitIndex, fillLevel, fillType, unit, defFillUnitIndex, fillLevel, airFillUnitIndex, fillLevel, lastSpeedReal, slip, brakePedal, force, textSize
function VehicleDebug:drawBaseDebugRendering(x, y)
	local v38_, _, v39_ = getWorldTranslation(self.components[1].node)
	local v40_ = g_farmlandManager:getIsOwnedByFarmAtWorldPosition(g_currentMission:getFarmId(), v38_, v39_)
	local v41_ = ""
	local v42_ = ""
	local v43_ = ""
	local v44_ = ""
	local v45_ = self.spec_motorized
	local v46_
	if v45_ == nil then
		v46_ = nil
	else
		local v47_ = v45_.motor
		local v48_ = v47_:getMotorAvailableTorque()
		local v49_ = v47_:getMotorExternalTorque()
		local v50_ = v47_:getMotorRotSpeed() * (v48_ - v49_) * 1000
		local v51_ = v41_ .. "motor:\n"
		local v52_ = v42_ .. string.format("%1.2frpm\n", v47_:getNonClampedMotorRpm())
		local v53_ = v51_ .. "clutch:\n"
		local v54_ = v52_ .. string.format("%1.2frpm\n", v47_:getClutchRotSpeed() * 30 / 3.141592653589793)
		local v55_ = v53_ .. "available power:\n"
		local v56_ = v54_ .. string.format("%1.2fhp %1.2fkW\n", v50_ / 735.49875, v50_ / 1000)
		local v57_ = v55_ .. "gear:\n"
		local v58_ = v56_ .. string.format("%d %d (%d, %1.2f)\n", v47_.gear, v47_.targetGear * v47_.currentDirection, v47_.activeGearGroupIndex or 0, v47_:getGearRatio())
		v41_ = v57_ .. "motor load:\n"
		v42_ = v58_ .. string.format("%1.2fkN %1.2fkN\n", v48_, v47_:getMotorAppliedTorque())
		local v59_ = v47_:getNonClampedMotorRpm() * 3.141592653589793 / 30 * v49_
		local v60_ = v49_ / v47_:getPeakTorque()
		local v61_ = v43_ .. "pto load:\n"
		local v62_ = v44_ .. string.format("%.2f%% %.2fhp %.2fkW %1.2fkN\n", v60_ * 100, v59_ * 1.359621, v59_, v49_)
		local v63_ = v61_ .. "motor load:\n"
		local v64_ = v62_ .. string.format("%.2f%%\n", v45_.smoothedLoadPercentage * 100)
		local v65_ = v63_ .. "motor rpm for sounds:\n"
		local v66_ = v64_ .. string.format("%drpm\n", v47_:getLastMotorRpm())
		v43_ = v65_ .. "brakeForce:\n"
		v44_ = v66_ .. string.format("%.2f (max. %.2f)\n", (self.spec_wheels or {
			["brakePedal"] = 0
		}).brakePedal, self:getBrakeForce() * 0.5)
		local v67_ = self:getConsumerFillUnitIndex(FillType.DIESEL) or (self:getConsumerFillUnitIndex(FillType.ELECTRICCHARGE) or self:getConsumerFillUnitIndex(FillType.METHANE))
		if v67_ ~= nil then
			local v68_ = self:getFillUnitFillLevel(v67_)
			local v69_ = self:getFillUnitFillType(v67_)
			local v70_ = v69_ == FillType.ELECTRICCHARGE and "kw" or (v69_ == FillType.METHANE and "kg" or "l")
			v43_ = v43_ .. string.format("%s:\n", g_fillTypeManager:getFillTypeNameByIndex(v69_))
			v44_ = v44_ .. string.format("%.2f%s/h (%.2f%s)\n", v45_.lastFuelUsage, v70_, v68_, v70_)
		end
		local v71_ = self:getConsumerFillUnitIndex(FillType.DEF)
		if v71_ ~= nil then
			local v72_ = self:getFillUnitFillLevel(v71_)
			v43_ = v43_ .. "DEF:\n"
			v44_ = v44_ .. string.format("%.2fl/h (%.2fl)\n", v45_.lastDefUsage, v72_)
		end
		local v73_ = self:getConsumerFillUnitIndex(FillType.AIR)
		if v73_ ~= nil then
			local v74_ = self:getFillUnitFillLevel(v73_)
			v43_ = v43_ .. "AIR:\n"
			v44_ = v44_ .. string.format("%.2fl/sec (%.2fl)\n", v45_.lastAirUsage, v74_)
		end
		v46_ = v47_.differentialRotSpeed * 3.6
	end
	local v75_ = v41_ .. "vel acc[m/s2]:\n"
	local v76_ = v42_ .. string.format("%1.4f\n", self.lastSpeedAcceleration * 1000 * 1000)
	local v77_, v78_
	if v46_ == nil then
		v77_ = v75_ .. "vel[km/h]:\n"
		v78_ = v76_ .. string.format("%1.3f\n", self:getLastSpeed())
	else
		local v79_ = v75_ .. "vel[km/h]:\n"
		local v80_ = v76_ .. string.format("%1.3f\n", self:getLastSpeed())
		local v81_ = self.lastSpeedReal * 3600
		local v82_ = (v46_ <= 0.01 or v81_ <= 0.01) and 0 or (v46_ / v81_ - 1) * 100
		v77_ = v79_ .. "differential[km/h]:\n"
		v78_ = v80_ .. string.format("%1.3f (slip: %d%%)\n", v46_, v82_)
	end
	local v83_ = v77_ .. "field owned:\n"
	local v84_ = v78_ .. tostring(v40_) .. "\n"
	local v85_ = v83_ .. "mass:\n"
	local v86_ = v84_ .. string.format("%1.1fkg\n", self:getTotalMass(true) * 1000)
	local v87_ = v85_ .. "mass incl. attach:\n"
	local v88_ = v86_ .. string.format("%1.1fkg\n", self:getTotalMass() * 1000)
	if self.spec_attachable ~= nil then
		local v89_ = self.spec_wheels == nil and 0 or self.spec_wheels.brakePedal
		local v90_ = self:getBrakeForce() / 10
		v87_ = v87_ .. "brakeForce:\n"
		v88_ = v88_ .. string.format("%1.2f / %1.2f\n", v90_ * v89_, v90_)
	end
	local v91_ = getCorrectTextSize(0.02)
	Utils.renderMultiColumnText(x, y, v91_, { v87_, v88_ }, 0.008, { RenderText.ALIGN_RIGHT, RenderText.ALIGN_LEFT })
	Utils.renderMultiColumnText(x + 0.22, y, v91_, { v43_, v44_ }, 0.008, { RenderText.ALIGN_RIGHT, RenderText.ALIGN_LEFT })
	return getTextHeight(v91_, v87_), getTextHeight(v91_, v43_)
end

-- Local values: specWheels, debugTable, i, wheel, wx, wy, wz, textSize
function VehicleDebug:drawWheelInfoRendering(x, y)
	if self.isServer then
		local v95_ = self.spec_wheels
		if v95_ ~= nil and #v95_.wheels > 0 then
			local v96_ = WheelDebug.getDebugValueHeader()
			for v97_, v98_ in ipairs(v95_.wheels) do
				v98_.debug:fillDebugValues(v96_)
				if #v95_.wheels > 4 and DebugUtil.isNodeInCameraRange(v98_.repr, 30) then
					local v99_, v100_, v101_ = getWorldTranslation(v98_.repr)
					Utils.renderTextAtWorldPosition(v99_, v100_, v101_, string.format("%d\n%s", v97_, getName(v98_.driveNode or v98_.linkNode)), getCorrectTextSize(0.008))
				end
			end
			local v102_ = getCorrectTextSize(0.02)
			Utils.renderMultiColumnText(x, y, v102_, v96_, 0.008, { RenderText.ALIGN_RIGHT, RenderText.ALIGN_LEFT })
			return getTextHeight(v102_, v96_[1])
		end
	end
	return 0
end

-- Local values: specWheels, debugTable, _, axle, _, numLines, textSize
function VehicleDebug:drawAxleInfoRendering(x, y)
	if self.isServer then
		local v106_ = self.spec_wheels
		if v106_ ~= nil and #v106_.axles > 0 then
			local v107_ = WheelAxle.getDebugValueHeader()
			for _, v108_ in ipairs(v106_.axles) do
				v108_:fillDebugValues(v107_)
			end
			local _, v109_ = string.gsub(v107_[1], "\n", "")
			if v109_ > 1 then
				local v110_ = getCorrectTextSize(0.02)
				Utils.renderMultiColumnText(x, y, v110_, v107_, 0.008, { RenderText.ALIGN_RIGHT, RenderText.ALIGN_LEFT })
				return getTextHeight(v110_, v107_[1])
			end
		end
	end
	return 0
end

-- Local values: specWheels, i, wheel
function VehicleDebug:drawWheelSlipGraphs()
	if self.isServer then
		local v112_ = self.spec_wheels
		if v112_ ~= nil then
			for _, v113_ in ipairs(v112_.wheels) do
				v113_.debug:drawSlipGraphs()
			end
		end
	end
end

-- Local values: motorSpec, getSpeedsOfDifferential, getRatioOfDifferential, diffStrs, i, diff, speed1, speed2, speed1, speed2, ratio, ratio
function VehicleDebug:drawDifferentialInfoRendering(x, y)
	local v_u_117_ = self.spec_motorized
	if v_u_117_ ~= nil and v_u_117_.differentials ~= nil then
		local function v_u_128_(p118_)
			-- upvalues: (copy) self, (ref) v_u_128_, (copy) v_u_117_
			local v119_ = self.spec_wheels
			local v120_
			if p118_.diffIndex1IsWheel then
				local v121_ = v119_.wheels[p118_.diffIndex1]
				v120_ = not v121_.physics.wheelShapeCreated and 0 or getWheelShapeAxleSpeed(v121_.node, v121_.physics.wheelShape) * v121_.physics.radius
			else
				local v122_, v123_ = v_u_128_(v_u_117_.differentials[p118_.diffIndex1 + 1])
				v120_ = (v122_ + v123_) / 2
			end
			local v124_
			if p118_.diffIndex2IsWheel then
				local v125_ = v119_.wheels[p118_.diffIndex2]
				if v125_.physics.wheelShapeCreated then
					return v120_, getWheelShapeAxleSpeed(v125_.node, v125_.physics.wheelShape) * v125_.physics.radius
				end
				v124_ = 0
			else
				local v126_, v127_ = v_u_128_(v_u_117_.differentials[p118_.diffIndex2 + 1])
				v124_ = (v126_ + v127_) / 2
			end
			return v120_, v124_
		end
		local v129_ = v_u_128_
		local v130_ = {
			"\n",
			"torqueRatio\n",
			"maxSpeedRatio\n",
			"actualSpeedRatio\n"
		}
		for v131_, v132_ in pairs(v_u_117_.differentials) do
			v130_[1] = v130_[1] .. string.format("%d:\n", v131_)
			v130_[2] = v130_[2] .. string.format("%2.2f\n", v132_.torqueRatio)
			v130_[3] = v130_[3] .. string.format("%2.2f\n", v132_.maxSpeedRatio)
			local v133_, v134_ = v129_(v132_)
			local v135_ = math.abs(v133_)
			local v136_ = math.abs(v134_)
			local v137_ = math.max(v135_, v136_)
			local v138_ = math.abs(v133_)
			local v139_ = math.abs(v134_)
			local v140_ = math.min(v138_, v139_)
			local v141_ = v137_ / math.max(v140_, 0.001)
			v130_[4] = v130_[4] .. string.format("%2.2f\n", v141_)
		end
		Utils.renderMultiColumnText(x, y, getCorrectTextSize(0.02), v130_, 0.008, { RenderText.ALIGN_RIGHT, RenderText.ALIGN_LEFT })
	end
end

-- Local values: motorSpec, motor, curveOverlay, torqueCurve, numTorqueValues, minRpm, maxRpm, torqueGraph, powerGraph, numValues, s, rpm, torque, power, hpPower, posX, maxSpeed, debugGraphs, numVelocityValues, numGears, gears, gear, effTorqueGraph, effPowerGraph, effGearRatioGraph, effRpmGraph, s, speed, _, gearRatio, gearRpm, torque, power, hpPower, i, graph, _, graph
function VehicleDebug:drawMotorGraphs(x, y, sizeX, sizeY, horizontal)
	if self.isServer then
		local v148_ = self.spec_motorized
		if v148_ ~= nil then
			local v149_ = v148_.motor
			local v150_ = v149_.debugCurveOverlay
			if v150_ == nil then
				v150_ = createImageOverlay("dataS/menu/base/graph_pixel.png")
				setOverlayColor(v150_, 0, 1, 0, 0.2)
				v149_.debugCurveOverlay = v150_
			end
			local v151_ = v149_:getTorqueCurve()
			local v152_ = #v151_.keyframes
			local v153_ = v149_:getMinRpm()
			local v154_ = v151_.keyframes[1].time
			local v155_ = math.min(v153_, v154_)
			local v156_ = v149_:getMaxRpm()
			local v157_ = v151_.keyframes[v152_].time
			local v158_ = math.max(v156_, v157_)
			local v159_ = v149_.debugTorqueGraph
			local v160_ = v149_.debugPowerGraph
			if v159_ == nil then
				local v161_ = v152_ * 32
				v159_ = Graph.new(v161_, x, y, sizeX, sizeY, 0, 0.0001, true, "kN", Graph.STYLE_LINES)
				v159_:setColor(1, 1, 1, 1)
				v149_.debugTorqueGraph = v159_
				v160_ = Graph.new(v161_, x, y, sizeX, sizeY, 0, 0.0001, false, "", Graph.STYLE_LINES)
				v160_:setColor(1, 0, 0, 1)
				v149_.debugPowerGraph = v160_
				v159_.maxValue = 0.01
				v160_.maxValue = 0.01
				for v162_ = 1, v161_ do
					local v163_ = (v162_ - 1) / (v161_ - 1) * (v151_.keyframes[v152_].time - v151_.keyframes[1].time) + v151_.keyframes[1].time
					local v164_ = v149_:getTorqueCurveValue(v163_)
					local v165_ = v164_ * 1000 * v163_ * 3.141592653589793 / 30 / 735.49875
					local v166_ = (v163_ - v155_) / (v158_ - v155_)
					v159_:setValue(v162_, v164_)
					local v167_ = v159_.maxValue
					v159_.maxValue = math.max(v167_, v164_)
					v159_:setXPosition(v162_, v166_)
					v160_:setValue(v162_, v165_)
					local v168_ = v160_.maxValue
					v160_.maxValue = math.max(v168_, v165_)
					v160_:setXPosition(v162_, v166_)
				end
			else
				v159_.left = x
				v159_.bottom = y
				v159_.width = sizeX
				v159_.height = sizeY
				v160_.left = x
				v160_.bottom = y
				v160_.width = sizeX
				v160_.height = sizeY
			end
			v159_:draw()
			v160_:draw()
			local v169_ = renderOverlay
			local v170_ = (v149_:getNonClampedMotorRpm() - v155_) / (v158_ - v155_)
			v169_(v150_, x, y, sizeX * math.clamp(v170_, 0, 1), sizeY)
			if horizontal then
				x = x + sizeX + 0.013
			else
				y = y - sizeY - 0.013
			end
			local v171_ = v149_:getMaximumForwardSpeed()
			local v172_ = v149_.debugGraphs
			if v172_ == nil then
				local v173_ = 1
				local v174_ = v149_.forwardGears
				if v149_.currentDirection < 0 then
					v174_ = v149_.backwardGears or v174_
				end
				local v175_ = v149_.minForwardGearRatio == nil and v174_ ~= nil and #v174_ or v173_
				v172_ = {}
				v149_.debugGraphs = v172_
				for v176_ = 1, v175_ do
					local v177_ = Graph.new(20, x, y, sizeX, sizeY, 0, 0.0001, true, "kN", Graph.STYLE_LINES)
					v177_:setColor(1, 1, 1, 1)
					table.insert(v172_, v177_)
					local v178_ = Graph.new(20, x, y, sizeX, sizeY, 0, 0.0001, false, "", Graph.STYLE_LINES)
					v178_:setColor(1, 0, 0, 1)
					table.insert(v172_, v178_)
					local v179_ = Graph.new(20, x, y, sizeX, sizeY, 0, 0.0001, false, "", Graph.STYLE_LINES)
					v179_:setColor(0.35, 1, 0.85, 1)
					table.insert(v172_, v179_)
					local v180_ = Graph.new(20, x, y, sizeX, sizeY, 0, 0.0001, false, "", Graph.STYLE_LINES)
					v180_:setColor(0.18, 0.18, 1, 1)
					table.insert(v172_, v180_)
					v177_.maxValue = 0.01
					v178_.maxValue = 0.01
					v179_.maxValue = 0.01
					v180_.maxValue = 0.01
					for v181_ = 1, 20 do
						local v182_ = (v181_ - 1) / 19 * v171_
						local v183_
						if v175_ == 1 then
							local v184_
							v184_, v183_ = v149_:getBestGear(1, v182_ * 30 / 3.141592653589793, 0, math.huge, 0)
						else
							v183_ = v174_[v176_].ratio
						end
						local v185_ = v182_ * 30 / 3.141592653589793 * v183_
						local v186_ = v151_:get(v185_)
						local v187_ = v186_ * 1000 * v185_ * 3.141592653589793 / 30 / 735.49875
						if v155_ <= v185_ and v185_ <= v158_ then
							v177_:setValue(v181_, v186_)
							local v188_ = v177_.maxValue
							v177_.maxValue = math.max(v188_, v186_)
							v178_:setValue(v181_, v187_)
							local v189_ = v178_.maxValue
							v178_.maxValue = math.max(v189_, v187_)
							v179_:setValue(v181_, v183_)
							local v190_ = v179_.maxValue
							v179_.maxValue = math.max(v190_, v183_)
							v180_:setValue(v181_, v185_)
							local v191_ = v180_.maxValue
							v180_.maxValue = math.max(v191_, v185_)
						end
					end
				end
			else
				for v192_ = 1, #v172_ do
					local v193_ = v172_[v192_]
					v193_.left = x
					v193_.bottom = y
					v193_.width = sizeX
					v193_.height = sizeY
				end
			end
			for _, v194_ in pairs(v172_) do
				v194_:draw()
			end
			local v195_ = renderOverlay
			local v196_ = self.lastSpeedReal * 1000 / v171_
			v195_(v150_, x, y, sizeX * math.clamp(v196_, 0, 1), sizeY)
			if horizontal then
				x = x + sizeX + 0.013
			else
				y = y - sizeY - 0.013
			end
			VehicleDebug.drawMotorLoadGraph(self, x, y, sizeX, sizeY)
		end
	end
end

-- Local values: motorSpec, motor, numValues, loadGraph, loadGraphSmooth, loadGraphSound, rawLoad, i, sample
function VehicleDebug:drawMotorLoadGraph(x, y, sizeX, sizeY)
	if self.isServer then
		local v202_ = self.spec_motorized
		if v202_ ~= nil then
			local v203_ = v202_.motor
			local v204_ = v203_.debugLoadGraph
			local v205_ = v203_.debugLoadGraphSmooth
			local v206_ = v203_.debugLoadGraphSound
			if v204_ == nil then
				v204_ = Graph.new(500, x, y, sizeX, sizeY, 0, 100, true, "%", Graph.STYLE_LINES, 0.1, "time")
				v204_:setColor(1, 1, 1, 0.3)
				v203_.debugLoadGraph = v204_
				v205_ = Graph.new(500, x, y, sizeX, sizeY, 0, 100, false, "", Graph.STYLE_LINES)
				v205_:setColor(0, 1, 0, 1)
				v203_.debugLoadGraphSmooth = v205_
				v206_ = Graph.new(500, x, y, sizeX, sizeY, 0, 100, false, "", Graph.STYLE_LINES)
				v206_:setColor(0, 1, 1, 1)
				v203_.debugLoadGraphSound = v206_
			else
				v204_.left = x
				v204_.bottom = y
				v204_.width = sizeX
				v204_.height = sizeY
				v205_.left = x
				v205_.bottom = y
				v205_.width = sizeX
				v205_.height = sizeY
				v206_.left = x
				v206_.bottom = y
				v206_.width = sizeX
				v206_.height = sizeY
			end
			if v204_ ~= nil and (v205_ ~= nil and v206_ ~= nil) then
				local v207_ = v203_:getMotorAppliedTorque()
				local v208_ = v203_:getMotorAvailableTorque()
				v204_:addValue(v207_ / math.max(v208_, 0.0001) * 100, nil, true)
				v205_:addValue(v202_.smoothedLoadPercentage * 100, nil, true)
				for v209_ = 1, #v202_.motorSamples do
					local v210_ = v202_.motorSamples[v209_]
					if v210_.isGlsFile then
						v206_:addValue(getSampleLoopSynthesisLoadFactor(v210_.soundSample) * 100, nil, true)
						break
					end
				end
			end
			v204_:draw()
			v205_:draw()
			v206_:draw()
		end
	end
end

-- Local values: motorSpec, motor, numValues, rpmGraph, rpmGraphSmooth, rpmGraphSound, minSoundRpm, maxSoundRpm, i, sample, i, sample
function VehicleDebug:drawMotorRPMGraph(x, y, sizeX, sizeY)
	if self.isServer then
		local v216_ = self.spec_motorized
		if v216_ ~= nil then
			local v217_ = v216_.motor
			local v218_ = v217_.debugRPMGraph
			local v219_ = v217_.debugRPMGraphSmooth
			local v220_ = v217_.debugRPMGraphSound
			if v218_ == nil then
				v218_ = Graph.new(500, x, y, sizeX, sizeY, v217_:getMinRpm(), v217_:getMaxRpm(), true, " RPM", Graph.STYLE_LINES, 0.1, "")
				v218_:setColor(1, 1, 1, 0.3)
				v217_.debugRPMGraph = v218_
				v219_ = Graph.new(500, x, y, sizeX, sizeY, v217_:getMinRpm(), v217_:getMaxRpm(), false, "", Graph.STYLE_LINES)
				v219_:setColor(0, 1, 0, 1)
				v217_.debugRPMGraphSmooth = v219_
				local v221_ = v217_:getMinRpm()
				local v222_ = v217_:getMaxRpm()
				for v223_ = 1, #v216_.motorSamples do
					local v224_ = v216_.motorSamples[v223_]
					if v224_.isGlsFile then
						v221_ = getSampleLoopSynthesisMinRPM(v224_.soundSample)
						v222_ = getSampleLoopSynthesisMaxRPM(v224_.soundSample)
						break
					end
				end
				v220_ = Graph.new(500, x, y, sizeX, sizeY, v221_, v222_, false, "", Graph.STYLE_LINES)
				v220_:setColor(0, 1, 1, 1)
				v217_.debugRPMGraphSound = v220_
			else
				v218_.left = x
				v218_.bottom = y
				v218_.width = sizeX
				v218_.height = sizeY
				v219_.left = x
				v219_.bottom = y
				v219_.width = sizeX
				v219_.height = sizeY
				v220_.left = x
				v220_.bottom = y
				v220_.width = sizeX
				v220_.height = sizeY
			end
			if v218_ ~= nil and (v219_ ~= nil and v220_ ~= nil) then
				v218_:addValue(v217_:getLastRealMotorRpm(), nil, true)
				v219_:addValue(v217_:getLastModulatedMotorRpm(), nil, true)
				for v225_ = 1, #v216_.motorSamples do
					local v226_ = v216_.motorSamples[v225_]
					if v226_.isGlsFile then
						v220_:addValue(getSampleLoopSynthesisRPM(v226_.soundSample, false), nil, true)
						break
					end
				end
			end
			v218_:draw()
			v219_:draw()
			v220_:draw()
		end
	end
end

-- Local values: motorSpec, motor, numValues, accGraph
function VehicleDebug:drawMotorAccelerationGraph(x, y, sizeX, sizeY)
	if self.isServer then
		local v232_ = self.spec_motorized
		if v232_ ~= nil then
			local v233_ = v232_.motor
			local v234_ = v233_.debugAccelerationGraph
			if v234_ == nil then
				v234_ = Graph.new(250, x, y, sizeX, sizeY, 0, 1, true, " Load Factor", Graph.STYLE_LINES, 0.1, "")
				v234_:setColor(1, 1, 1, 0.3)
				v233_.debugAccelerationGraph = v234_
				v233_.debugAccelerationGraphAddValue = true
			else
				v234_.left = x
				v234_.bottom = y
				v234_.width = sizeX
				v234_.height = sizeY
			end
			if v234_ ~= nil then
				if v233_.debugAccelerationGraphAddValue then
					v234_:addValue(v233_.constantAccelerationCharge, nil, true)
				end
				v233_.debugAccelerationGraphAddValue = not v233_.debugAccelerationGraphAddValue
			end
			v234_:draw()
		end
	end
end

-- Local values: textHeight1, _, x, y, height
function VehicleDebug:drawDebugRendering()
	local v236_, _ = VehicleDebug.drawBaseDebugRendering(self, 0.015, 0.65)
	local v237_ = 0.64 - v236_ - 0.005
	local v238_ = VehicleDebug.drawWheelInfoRendering(self, 0.015, v237_)
	VehicleDebug.drawDifferentialInfoRendering(self, 0.015, v237_ - (v238_ + getCorrectTextSize(0.02)))
	VehicleDebug.drawAxleInfoRendering(self, 0.29500000000000004, v237_ - (v238_ + getCorrectTextSize(0.02)))
	VehicleDebug.drawWheelSlipGraphs(self)
	VehicleDebug.drawMotorGraphs(self, 0.65, 0.44, 0.25, 0.2, false)
end

-- Local values: textHeight1, _, x, y, height
function VehicleDebug:drawTuningDebug()
	local v240_, _ = VehicleDebug.drawBaseDebugRendering(self, 0.015, 0.9)
	local v241_ = 0.89 - v240_ - 0.005
	local v242_ = VehicleDebug.drawWheelInfoRendering(self, 0.015, v241_)
	VehicleDebug.drawDifferentialInfoRendering(self, 0.015, v241_ - (v242_ + getCorrectTextSize(0.02)))
	VehicleDebug.drawAxleInfoRendering(self, 0.29500000000000004, v241_ - (v242_ + getCorrectTextSize(0.02)))
end

-- Local values: textHeight1, _, str1, str2, motorSpec, motor, x, y, infoWidth, minWidthPerGear, gears, width, height, gearAreaWidth, groupRatioReal, groupRatio, numGears, gearWidth, gearMaxHeight, textOffset, maxDiffSpeed, i, numGearValues, offsetPerValue, lastDiffSpeedAfterChange, lastMaxPower, i, gear, minGearSpeed, maxGearSpeed, pos, h, gearX, posY, factor, bestGear, maxFactorGroup, diffSpeed, speedHeight
function VehicleDebug:drawTransmissionDebug()
	local v244_, _ = VehicleDebug.drawBaseDebugRendering(self, 0.015, 0.65)
	VehicleDebug.drawMotorGraphs(self, 0.01, 0.73, 0.25, 0.2, true)
	local v245_ = ""
	local v246_ = ""
	local v247_ = self.spec_motorized
	if v247_ ~= nil then
		local v248_ = v247_.motor
		local v249_ = v245_ .. "\ngear start values:\n"
		local v250_ = v246_ .. "\n\n"
		local v251_ = v249_ .. "peakPower:\n"
		local v252_ = v250_ .. string.format("%d/%dkW\n", v248_.startGearValues.availablePower, v248_.peakMotorPower)
		local v253_ = v251_ .. "maxForce:\n"
		local v254_ = v252_ .. string.format("%.2fkN\n", v248_.startGearValues.maxForce)
		local v255_ = v253_ .. "mass:\n"
		local v256_ = v254_ .. string.format("%.2fto\n", v248_.startGearValues.mass)
		local v257_ = v255_ .. "slope angle:\n"
		local v258_ = string.format
		local v259_ = v248_.startGearValues.slope
		local v260_ = v256_ .. v258_("%.2f\194\176\n", (math.deg(v259_)))
		local v261_ = v257_ .. "slope percentage:\n"
		local v262_ = string.format
		local v263_ = v248_.startGearValues.slope
		local v264_ = v260_ .. v262_("%.2f%%\n", math.atan(v263_) * 100)
		local v265_ = v261_ .. "dirDiffXZ:\n"
		local v266_ = v264_ .. string.format("%.2f\n", v248_.startGearValues.massDirectionDifferenceXZ)
		local v267_ = v265_ .. "dirDiffY:\n"
		local v268_ = v266_ .. string.format("%.2f\n", v248_.startGearValues.massDirectionDifferenceY)
		local v269_ = v267_ .. "dirFac:\n"
		local v270_ = v268_ .. string.format("%.2f\n", v248_.startGearValues.massDirectionFactor)
		local v271_ = v269_ .. "massFac:\n"
		local v272_ = v270_ .. string.format("%.2f\n", v248_.startGearValues.massFactor)
		local v273_ = v271_ .. "speedLimit:\n"
		local v274_ = v272_ .. string.format("%.1f / %.1f \n", v248_.speedLimit, self:getSpeedLimit(true))
		local v275_ = v273_ .. "auto shift allowed:\n"
		local v276_ = v274_ .. string.format("%s\n", self:getIsAutomaticShiftingAllowed())
		local v277_ = v275_ .. "gear/group change allowed:\n"
		local v278_ = v276_ .. string.format("%s/%s\n", v248_:getIsGearChangeAllowed(), v248_:getIsGearGroupChangeAllowed())
		local v279_ = v277_ .. "gear group shift timer:\n"
		local v280_ = v278_ .. string.format("%.1f/%.1f sec\n", v248_.gearGroupUpShiftTimer / 1000, v248_.gearGroupUpShiftTime / 1000)
		local v281_ = v279_ .. "clutch slipping simer:\n"
		local v282_ = v280_ .. string.format("%d ms\n", v248_.clutchSlippingTimer)
		local v283_ = v281_ .. "motor can run:\n"
		local v284_ = v282_ .. string.format("%s\n", v248_:getCanMotorRun())
		local v285_ = v283_ .. "stall timer:\n"
		local v286_ = v284_ .. string.format("%.2f\n", v248_.stallTimer)
		local v287_ = v285_ .. "turbo scale:\n"
		local v288_ = v286_ .. string.format("%d%%\n", v248_.lastTurboScale * 100)
		local v289_ = v287_ .. "blowOffValveState:\n"
		local v290_ = v288_ .. string.format("%d%%\n", v248_.blowOffValveState * 100)
		Utils.renderMultiColumnText(0.015, 0.65 - v244_, getCorrectTextSize(0.018), { v289_, v290_ }, 0.008, { RenderText.ALIGN_RIGHT, RenderText.ALIGN_LEFT })
		if v248_.forwardGears or v248_.backwardGears then
			local v291_ = v248_.forwardGears
			if v248_.currentDirection < 0 then
				v291_ = v248_.backwardGears or v291_
			end
			local v292_ = #v291_ * 0.035 + 0.05
			drawOutlineRect(0.222, 0.15, v292_, 0.35, g_pixelSizeX, g_pixelSizeY, 0, 0, 0, 1)
			drawFilledRect(0.222, 0.15, v292_, 0.35, 0, 0, 0, 0.4)
			local v293_ = v292_ - 0.05
			drawFilledRect(0.272, 0.15, g_pixelSizeX, 0.35, 0, 0, 0, 1)
			drawFilledRect(0.272, 0.46499999999999997, v293_, g_pixelSizeY, 0, 0, 0, 1)
			drawFilledRect(0.272, 0.255, v293_, g_pixelSizeY, 0, 0, 0, 1)
			local v294_ = v248_:getGearRatioMultiplier()
			local v295_ = v248_:getGearRatioMultiplier()
			local v296_ = math.abs(v295_)
			local v297_ = #v291_
			local v298_ = v293_ / v297_
			local v299_ = 1
			for v300_ = 1, v297_ do
				local v301_ = v248_.maxRpm * 3.141592653589793 / (30 * v291_[v300_].ratio * v296_) * 3.6
				v299_ = math.max(v299_, v301_)
			end
			local v302_ = nil
			local v303_ = nil
			for v304_ = 1, v297_ do
				local v305_ = v291_[v304_]
				v302_ = v302_ or v305_.lastDiffSpeedAfterChange
				v303_ = v303_ or v305_.lastMaxPower
				local v306_ = v248_.minRpm * 3.141592653589793 / (30 * v305_.ratio * v296_) * 3.6
				local v307_ = v248_.maxRpm * 3.141592653589793 / (30 * v305_.ratio * v296_) * 3.6
				local v308_ = v306_ / v299_ * 0.21
				local v309_ = (v307_ - v306_) / v299_ * 0.21
				local v310_ = 0.272 + v298_ * (v304_ - 1)
				local v311_ = 0.255 + g_pixelSizeY + v308_
				drawFilledRect(v310_, v311_, v298_, v309_, (v248_.gear == v304_ or not v305_.lastHasPower) and 0.05 or 1, (v248_.gear == v304_ or v305_.lastHasPower) and 1 or 0.05, 0.05, 0.85)
				setTextAlignment(RenderText.ALIGN_CENTER)
				renderText(v310_ + v298_ * 0.5, v311_ + 0.00375, 0.015, string.format("%.2f", v305_.ratio * v296_))
				local v312_ = v248_:getStartInGearFactor(v305_.ratio * v296_)
				if v312_ < v248_.startGearThreshold then
					setTextColor(0, 1, 0, 1)
				else
					setTextColor(1, 0, 0, 1)
				end
				renderText(v310_ + v298_ * 0.5, 0.255 + g_pixelSizeY + 0.21 - 0.015, 0.015, string.format("%.2f", v312_))
				if v294_ ~= v296_ then
					local v313_ = v248_:getStartInGearFactor(v305_.ratio * v294_)
					if v313_ < v248_.startGearThreshold then
						setTextColor(0, 1, 0, 1)
					else
						setTextColor(1, 0, 0, 1)
					end
					renderText(v310_ + v298_ * 0.5, 0.255 + g_pixelSizeY + 0.21 - 0.03, 0.012, string.format("%.2f", v313_))
				end
				setTextColor(1, 1, 1, 1)
				renderText(v310_ + v298_ * 0.5, 0.1575, 0.0125, string.format("%.2f %.2f", v305_.lastPowerFactor or 0, v305_.lastRpmFactor or 0))
				renderText(v310_ + v298_ * 0.5, 0.1785, 0.0125, string.format("%.2f %.2f", v305_.lastGearChangeFactor or 0, v305_.lastRpmPreferenceFactor or 0))
				if v305_.nextPowerValid then
					setTextColor(0, 1, 0, 1)
				else
					setTextColor(1, 0, 0, 1)
				end
				renderText(v310_ + v298_ * 0.5, 0.1995, 0.015, string.format("%d", v305_.lastNextPower or -1))
				if v305_.nextRpmValid then
					setTextColor(0, 1, 0, 1)
				else
					setTextColor(1, 0, 0, 1)
				end
				renderText(v310_ + v298_ * 0.5, 0.2205, 0.015, string.format("%d", v305_.lastNextRpm or -1))
				setTextColor(1, 1, 1, 1)
				renderText(v310_ + v298_ * 0.5, 0.2415, 0.015, string.format("%.2f", v305_.lastTradeoff or 0))
			end
			setTextAlignment(RenderText.ALIGN_CENTER)
			renderText(0.247, 0.255 + g_pixelSizeY + 0.21 - 0.015, 0.015, "startFactor")
			local v314_, v315_ = v248_:getBestStartGear(v248_.currentGears)
			renderText(0.247, 0.255 + g_pixelSizeY + 0.21 - 0.03, 0.015, string.format("best\ngroup %d\ngear %d", v315_, v314_))
			renderText(0.247, 0.1575, 0.01, "pwr/rpm")
			renderText(0.247, 0.1785, 0.01, "gearC/rpmPref")
			renderText(0.247, 0.1995, 0.01, string.format("nextPwr (%d)", v303_ or -1))
			renderText(0.247, 0.2205, 0.01, "nextRpm")
			renderText(0.247, 0.2415, 0.01, "tradeoff")
			local v316_ = v248_.differentialRotSpeed * 3.6
			local v317_ = math.abs(v316_)
			local v318_ = 0.255 + v317_ / v299_ * (0.21 - g_pixelSizeY) + g_pixelSizeY
			setTextBold(true)
			setTextAlignment(RenderText.ALIGN_CENTER)
			renderText(0.247, v318_ - 0.005, 0.015, string.format("%.2f", v317_))
			setTextBold(false)
			if v302_ ~= nil then
				setTextAlignment(RenderText.ALIGN_LEFT)
				renderText(0.277, 0.4774999999999999, 0.01, string.format("Speed after change: %.2fkm/h (%.1f sec)", v302_ * 3.6, v248_.gearChangeTime / 1000))
			end
			drawFilledRect(0.272, v318_, v293_, g_pixelSizeY, 0, 1, 0, 0.5)
		end
	end
end

-- Local values: storeItem, shopTransOffset, rotOffset, offsetX, offsetY, offsetZ, _, implement, attacherJoint, i, heightNode, hx, hy, hz, ht, _, attacherJoint, additionalName, index, width, color, r, g, b, x1, y1, z1, x2, y2, z2, radius, x, y, z, upX, upY, upZ, dirX, dirY, dirZ, attacherVehicle, activeInputAttacherJoint, _, inputAttacherJoint, _, width, nearestCategory, r, g, b, x1, y1, z1, x2, y2, z2, radius, x, y, z, groundRaycastResult, i, wheel, typedColor, numTypes, _, workArea, color, startX, startY, startZ, widthX, widthY, widthZ, heightX, heightY, heightZ, x1, _, z1, x2, _, z2, x3, _, z3, x, z, y, isActive, textColor, width, length, dir1X, dir1Z, dir2X, dir2Z, cx, cz, _, occlusionArea, offset, _, bendingNode, drawLine, _, licensePlate, top, right, bottom, left, fillUnits, i, fillUnit, autoAimTarget, startFillLevel, percent, curZ, x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4, x5, y5, z5, dischargeNodes, i, dischargeNode, info, sx, sy, sz, ex, ey, ez, spec, camera, name, x, y, z, rotationNode, rx, ry, rz, text, _, camera, x, y, z, dirX, dirY, dirZ, upX, upY, upZ, i, component, x, y, z, dirX, dirY, dirZ, upX, upY, upZ, i, powerTakeOffOutput, size, x, y, z, dirX, dirY, dirZ, upX, upY, upZ, x, y, z, upX, upY, upZ, dirX, dirY, dirZ, i, targetNode, size, x, y, z, dirX, dirY, dirZ, upX, upY, upZ
function VehicleDebug.drawDebugAttributeRendering(vehicle)
	if vehicle.debugSizeOffsetNode == nil then
		vehicle.debugSizeOffsetNode = createTransformGroup("debugSizeOffsetNode")
		link(vehicle.rootNode, vehicle.debugSizeOffsetNode)
		local v320_ = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
		if v320_ ~= nil then
			local v321_ = v320_.shopTranslationOffset
			if v321_ ~= nil then
				setTranslation(vehicle.debugSizeOffsetNode, -v321_[1], -v321_[2], -v321_[3])
			end
			local v322_ = v320_.shopRotationOffset
			if v322_ ~= nil then
				setRotation(vehicle.debugSizeOffsetNode, -v322_[1], -v322_[2], -v322_[3])
			end
		end
	end
	local v323_ = vehicle.size.widthOffset
	local v324_ = vehicle.size.heightOffset + vehicle.size.height / 2
	local v325_ = vehicle.size.lengthOffset
	DebugBox.renderAtNodeWithOffset(vehicle.debugSizeOffsetNode, v323_, v324_, v325_, vehicle.size.width, vehicle.size.height, vehicle.size.length, Color.PRESETS.BLUE, true, "size")
	if vehicle.spec_attacherJoints ~= nil then
		for _, v326_ in pairs(vehicle.spec_attacherJoints.attachedImplements) do
			if v326_.object ~= nil then
				local v327_ = v326_.object:getActiveInputAttacherJoint()
				if #v327_.heightNodes > 0 then
					for v328_ = 1, #v327_.heightNodes do
						local v329_ = v327_.heightNodes[v328_]
						local v330_, v331_, v332_ = getWorldTranslation(v329_.node)
						local v333_ = getTerrainHeightAtWorldPos(g_terrainNode, v330_, v331_, v332_)
						DebugGizmo.renderAtNode(v329_.node, string.format("HeightNode: %.3f", v331_ - v333_))
					end
				end
			end
		end
		for _, v334_ in pairs(vehicle:getAttacherJoints()) do
			local v335_ = v334_.subTypes == nil and "" or (string.format(" (%s)", table.concat(v334_.subTypes, ", ")) or "")
			DebugGizmo.renderAtNode(v334_.jointTransform, getName(v334_.jointTransform) .. v335_, false, 0.3)
			if v334_.bottomArm ~= nil and v334_.bottomArm.referenceDistance ~= nil then
				for v336_, v337_ in pairs(AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY) do
					local v338_ = VehicleDebug.DEBUG_COLORS[v336_ + 1]
					if v337_ < v334_.bottomArm.minWidth or v334_.bottomArm.maxWidth < v337_ then
						v338_ = VehicleDebug.COLOR.GREY
					end
					local v339_, v340_, v341_ = v338_:unpack()
					local v342_, v343_, v344_ = localToWorld(v334_.bottomArm.translationNode, v337_ * 0.5, 0, v334_.bottomArm.referenceDistance * v334_.bottomArm.zScale)
					local v345_, v346_, v347_ = localToWorld(v334_.bottomArm.translationNode, -v337_ * 0.5, 0, v334_.bottomArm.referenceDistance * v334_.bottomArm.zScale)
					drawDebugLine(v342_, v343_ - 0.1, v344_, v339_, v340_, v341_, v342_, v343_ + 0.1, v344_, v339_, v340_, v341_, true)
					drawDebugLine(v345_, v346_ - 0.1, v347_, v339_, v340_, v341_, v345_, v346_ + 0.1, v347_, v339_, v340_, v341_, true)
					local v348_ = AttacherJoints.LOWER_LINK_BALL_SIZE_BY_CATEGORY[v336_] * 0.5
					DebugSphere.renderAtPosition(v342_, v343_, v344_, v348_, v338_, 10, true, false, nil)
					DebugSphere.renderAtPosition(v345_, v346_, v347_, v348_, v338_, 10, true, false, nil)
				end
			end
			if v334_.transNode ~= nil and getVisibility(v334_.transNode) then
				local v349_, v350_, v351_ = getWorldTranslation(v334_.transNode)
				local v352_, v353_, v354_ = localDirectionToWorld(v334_.jointTransform, 0, 1, 0)
				local v355_, v356_, v357_ = localDirectionToWorld(v334_.jointTransform, 0, 0, 1)
				local v358_ = v349_ - v357_ * 0.05
				local v359_ = v350_ + v356_ * 0.05
				local v360_ = v351_ + v355_ * 0.05
				DebugBox.renderAtPosition(v358_, v359_, v360_, v352_, v353_, v354_, v355_, v356_, v357_, 0.2, v334_.transNodeHeight, 0.3, Color.PRESETS.GREEN, true, nil, false)
			end
		end
	end
	if vehicle.spec_attachable ~= nil then
		local v_u_361_ = vehicle:getAttacherVehicle()
		local v362_ = vehicle:getActiveInputAttacherJoint()
		for _, v363_ in pairs(vehicle:getInputAttacherJoints()) do
			if v363_.jointType == AttacherJoints.JOINTTYPE_IMPLEMENT and v363_.bottomArm ~= nil then
				for _, v364_ in ipairs(v363_.bottomArm.widths) do
					local v365_ = AttacherJoints.getClosestLowerLinkCategoryIndex(v364_)
					local v366_, v367_, v368_ = VehicleDebug.DEBUG_COLORS[v365_ + 1]:unpack()
					local v369_, v370_, v371_ = localToWorld(v363_.node, 0, 0, v364_ * 0.5)
					local v372_, v373_, v374_ = localToWorld(v363_.node, 0, 0, -v364_ * 0.5)
					drawDebugLine(v369_, v370_ - 0.1, v371_, v366_, v367_, v368_, v369_, v370_ + 0.1, v371_, v366_, v367_, v368_, true)
					drawDebugLine(v372_, v373_ - 0.1, v374_, v366_, v367_, v368_, v372_, v373_ + 0.1, v374_, v366_, v367_, v368_, true)
					local v375_ = AttacherJoints.LOWER_LINK_BALL_SIZE_BY_CATEGORY[v365_] * 0.5
					DebugSphere.renderAtPosition(v369_, v370_, v371_, v375_, VehicleDebug.DEBUG_COLORS[v365_ + 1], 10, true, false, nil)
					DebugSphere.renderAtPosition(v372_, v373_, v374_, v375_, VehicleDebug.DEBUG_COLORS[v365_ + 1], 10, true, false, nil)
				end
			end
			if v362_ == nil or v363_ == v362_ then
				local v376_, v377_, v378_ = getWorldTranslation(v363_.node)
				drawDebugPoint(v376_, v377_, v378_, 1, 0, 0, 1)
				local v382_ = {
					["raycastCallback"] = function(p379_, p380_, _, _, _, p381_)
						-- upvalues: (copy) v_u_361_, (copy) vehicle
						if v_u_361_ ~= nil and v_u_361_.vehicleNodes[p380_] ~= nil then
							return true
						end
						if vehicle.vehicleNodes[p380_] ~= nil then
							return true
						end
						p379_.groundDistance = p381_
						return false
					end,
					["groundDistance"] = 0
				}
				raycastAll(v376_, v377_, v378_, 0, -1, 0, 4, "raycastCallback", v382_, CollisionFlag.TERRAIN + CollisionFlag.STATIC_OBJECT + CollisionFlag.BUILDING)
				drawDebugLine(v376_, v377_, v378_, 0, 1, 0, v376_, v377_ - v382_.groundDistance, v378_, 0, 1, 0)
				drawDebugPoint(v376_, v377_ - v382_.groundDistance, v378_, 1, 0, 0, 1)
				Utils.renderTextAtWorldPosition(v376_, v377_ + 0.1, v378_, string.format("%.4f", v382_.groundDistance), getCorrectTextSize(0.02), 0)
			end
		end
	end
	if vehicle.spec_wheels ~= nil then
		for _, v383_ in ipairs(vehicle:getWheels()) do
			v383_.destruction:drawAreas()
		end
	end
	if vehicle.spec_workArea ~= nil then
		local v384_ = {}
		local v385_ = 0
		for _, v386_ in pairs(vehicle.spec_workArea.workAreas) do
			local v387_ = v384_[v386_.type]
			if v387_ == nil then
				v385_ = v385_ + 1
				v387_ = VehicleDebug.DEBUG_COLORS[v385_]
				v384_[v386_.type] = v387_
			end
			local v388_, v389_, v390_ = getWorldTranslation(v386_.start)
			local v391_ = v389_ < 0 and -100 or getTerrainHeightAtWorldPos(g_terrainNode, v388_, 0, v390_) + 0.1
			local v392_, v393_, v394_ = getWorldTranslation(v386_.width)
			local v395_ = v393_ < 0 and -100 or getTerrainHeightAtWorldPos(g_terrainNode, v392_, 0, v394_) + 0.1
			local v396_, v397_, v398_ = getWorldTranslation(v386_.height)
			local v399_ = v397_ < 0 and -100 or getTerrainHeightAtWorldPos(g_terrainNode, v396_, 0, v398_) + 0.1
			DebugPlane.renderWithPositions(v388_, v391_, v390_, v392_, v395_, v394_, v396_, v399_, v398_, v387_, false)
			local v400_, _, v401_ = getWorldTranslation(v386_.start)
			local v402_, _, v403_ = getWorldTranslation(v386_.width)
			local v404_, _, v405_ = getWorldTranslation(v386_.height)
			local v406_ = v404_ + (v402_ - v404_) * 0.5
			local v407_ = v405_ + (v403_ - v405_) * 0.5
			local v408_ = getTerrainHeightAtWorldPos(g_terrainNode, v406_, 0, v407_) + 0.1
			local v409_ = v408_ < 0 and -100 or v408_
			local v410_ = vehicle:getIsWorkAreaActive(v386_) and VehicleDebug.COLOR.ACTIVE or VehicleDebug.COLOR.INACTIVE
			local v411_ = Utils.renderTextAtWorldPosition
			local v412_ = g_workAreaTypeManager
			local v413_ = v386_.type
			v411_(v406_, v409_, v407_, tostring(v412_:getWorkAreaTypeNameByIndex(v413_)), getCorrectTextSize(0.015), -getCorrectTextSize(0.015) * 0.5, v410_)
			if vehicle.spec_ridgeMarker ~= nil and (#vehicle.spec_ridgeMarker.ridgeMarkers > 0 and v386_.type == WorkAreaType.SOWINGMACHINE) then
				local v414_ = calcDistanceFrom(v386_.start, v386_.width)
				local v415_ = calcDistanceFrom(v386_.start, v386_.height)
				local v416_, v417_ = MathUtil.vector2Normalize(v400_ - v402_, v401_ - v403_)
				local v418_, v419_ = MathUtil.vector2Normalize(v404_ - v400_, v405_ - v401_)
				local v420_ = (v400_ + v402_) * 0.5
				local v421_ = (v401_ + v403_) * 0.5
				drawDebugLine(v420_ + v416_ * v414_, v409_, v421_ + v417_ * v414_, 0, 1, 1, v420_ + v416_ * v414_ + v418_ * v415_, v409_, v421_ + v417_ * v414_ + v419_ * v415_, 0, 1, 1, true)
				drawDebugLine(v420_ - v416_ * v414_, v409_, v421_ - v417_ * v414_, 0, 1, 1, v420_ - v416_ * v414_ + v418_ * v415_, v409_, v421_ - v417_ * v414_ + v419_ * v415_, 0, 1, 1, true)
			end
		end
	end
	if vehicle.getTipOcclusionAreas ~= nil then
		for _, v422_ in pairs(vehicle:getTipOcclusionAreas()) do
			DebugPlane.renderWithNodes(v422_.start, v422_.width, v422_.height, Color.PRESETS.YELLOW, true)
		end
	end
	if vehicle.spec_foliageBending ~= nil then
		for _, v423_ in ipairs(vehicle.spec_foliageBending.bendingNodes) do
			if v423_.isActive then
				DebugUtil.drawDebugRectangle(v423_.node, v423_.minX, v423_.maxX, v423_.minZ, v423_.maxZ, v423_.yOffset, 1, 0, 0)
				DebugUtil.drawDebugRectangle(v423_.node, v423_.minX - 0.25, v423_.maxX + 0.25, v423_.minZ - 0.25, v423_.maxZ + 0.25, v423_.yOffset, 0, 1, 0)
			end
		end
	end
	if vehicle.spec_licensePlates ~= nil then
		local function v441_(p424_, p425_, p426_, p427_, p428_)
			if math.abs(p425_) ~= math.huge then
				local v429_, v430_, v431_
				if p426_ == math.huge then
					v429_ = 0
					v430_ = 1
					v431_ = 0
					p426_ = 0.25
				else
					v429_ = 1
					v430_ = 0
					v431_ = 0
				end
				local v432_, v433_, v434_
				if p427_ == math.huge then
					p427_ = 0.25
					v432_ = 0
					v433_ = 1
					v434_ = 0
				else
					v432_ = 1
					v433_ = 0
					v434_ = 0
				end
				local v435_, v436_, v437_, v438_, v439_, v440_
				if p428_ then
					v435_, v436_, v437_ = localToWorld(p424_.node, p425_, p426_, 0)
					v438_, v439_, v440_ = localToWorld(p424_.node, p425_, -p427_, 0)
				else
					v435_, v436_, v437_ = localToWorld(p424_.node, p426_, p425_, 0)
					v438_, v439_, v440_ = localToWorld(p424_.node, -p427_, p425_, 0)
				end
				drawDebugLine(v435_, v436_, v437_, v429_, v430_, v431_, v438_, v439_, v440_, v432_, v433_, v434_)
			end
		end
		for _, v442_ in ipairs(vehicle.spec_licensePlates.licensePlates) do
			DebugGizmo.renderAtNode(v442_.node)
			local v443_ = v442_.placementArea[1]
			local v444_ = v442_.placementArea[2]
			local v445_ = v442_.placementArea[3]
			local v446_ = v442_.placementArea[4]
			v441_(v442_, v444_, v443_, v445_, true)
			v441_(v442_, -v446_, v443_, v445_, true)
			v441_(v442_, v443_, v444_, v446_, false)
			v441_(v442_, -v445_, v444_, v446_, false)
		end
	end
	if vehicle.spec_fillUnit ~= nil then
		local v447_ = vehicle:getFillUnits()
		for v448_ = 1, #v447_ do
			local v449_ = v447_[v448_]
			local v450_ = v449_.autoAimTarget
			if v450_.node ~= nil and (v450_.startZ ~= nil and v450_.endZ ~= nil) then
				local v451_ = v449_.capacity * v450_.startPercentage
				local v452_ = (v449_.fillLevel - v451_) / (v449_.capacity - v451_)
				local v453_ = math.clamp(v452_, 0, 1)
				if v450_.invert then
					v453_ = 1 - v453_
				end
				local v454_ = (v450_.endZ - v450_.startZ) * v453_ + v450_.startZ
				local v455_, v456_, v457_ = localToWorld(getParent(v450_.node), v450_.baseTrans[1], v450_.baseTrans[2], v450_.startZ)
				local v458_, v459_, v460_ = localToWorld(getParent(v450_.node), v450_.baseTrans[1], v450_.baseTrans[2], v450_.endZ)
				drawDebugLine(v455_, v456_, v457_, 0, 1, 0, v458_, v459_, v460_, 0, 1, 0, true)
				drawDebugLine(v455_, v456_, v457_, 1, 0, 0, v455_, v456_ + 0.2, v457_, 1, 0, 0, true)
				drawDebugLine(v458_, v459_, v460_, 1, 0, 0, v458_, v459_ + 0.2, v460_, 1, 0, 0, true)
				local v461_, v462_, v463_ = localToWorld(getParent(v450_.node), v450_.baseTrans[1], v450_.baseTrans[2], v454_)
				drawDebugLine(v461_, v462_, v463_, 0, 0, 1, v461_, v462_ - 0.5, v463_, 0, 0, 1, true)
				local v464_, v465_, v466_ = localToWorld(getParent(v450_.node), v450_.baseTrans[1] - 0.5, v450_.baseTrans[2], v450_.startZ + 0.75)
				local v467_, v468_, v469_ = localToWorld(getParent(v450_.node), v450_.baseTrans[1] + 0.5, v450_.baseTrans[2], v450_.startZ + 0.75)
				drawDebugLine(v464_, v465_, v466_, 0, 1, 1, v467_, v468_, v469_, 0, 1, 1, true)
				local v470_, v471_, v472_ = localToWorld(getParent(v450_.node), v450_.baseTrans[1] - 0.5, v450_.baseTrans[2], v450_.endZ - 0.75)
				local v473_, v474_, v475_ = localToWorld(getParent(v450_.node), v450_.baseTrans[1] + 0.5, v450_.baseTrans[2], v450_.endZ - 0.75)
				drawDebugLine(v470_, v471_, v472_, 0, 1, 1, v473_, v474_, v475_, 0, 1, 1, true)
			end
		end
	end
	if vehicle.spec_dischargeable ~= nil then
		local v476_ = vehicle.spec_dischargeable.dischargeNodes
		for v477_ = 1, #v476_ do
			local v478_ = v476_[v477_].info
			local v479_, v480_, v481_ = localToWorld(v478_.node, -v478_.width, 0, v478_.zOffset)
			local v482_, v483_, v484_ = localToWorld(v478_.node, v478_.width, 0, v478_.zOffset)
			drawDebugLine(v479_, v480_, v481_, 1, 0, 1, v482_, v483_, v484_, 1, 0, 1)
		end
	end
	if vehicle:getIsActiveForInput() and vehicle.spec_enterable ~= nil then
		local v485_ = vehicle.spec_enterable
		local v486_ = v485_.cameras[v485_.camIndex]
		if v486_ ~= nil then
			local v487_ = getName(v486_.cameraPositionNode)
			local v488_, v489_, v490_ = getTranslation(v486_.cameraPositionNode)
			local v491_ = v486_.cameraPositionNode
			if v486_.rotateNode ~= nil then
				v491_ = v486_.rotateNode
			end
			local v492_, v493_, v494_ = getRotation(v491_)
			if v486_.hasExtraRotationNode then
				v492_ = -((3.141592653589793 - v492_) % 6.283185307179586)
				v493_ = (v493_ + 3.141592653589793) % 6.283185307179586
				v494_ = (v494_ - 3.141592653589793) % 6.283185307179586
			end
			local v495_ = string.format("camera \'%s\': translation: %.2f %.2f %.2f  rotation: %.2f %.2f %.2f", v487_, v488_, v489_, v490_, math.deg(v492_), math.deg(v493_), (math.deg(v494_)))
			setTextAlignment(RenderText.ALIGN_CENTER)
			setTextColor(0, 0, 0, 1)
			renderText(0.5 + g_pixelSizeX, 0.95 - g_pixelSizeY, 0.02, v495_)
			renderText(0.5 + g_pixelSizeX, 0.98 - g_pixelSizeY, 0.05, "______________________________________________________________________")
			setTextColor(1, 1, 1, 1)
			renderText(0.5, 0.95, 0.02, v495_)
			renderText(0.5, 0.98, 0.05, "______________________________________________________________________")
			setTextAlignment(RenderText.ALIGN_LEFT)
		end
		for _, v496_ in ipairs(v485_.cameras) do
			if v496_.isInside then
				local v497_, v498_, v499_ = getWorldTranslation(v496_.cameraPositionNode)
				local v500_, v501_, v502_ = localDirectionToWorld(v496_.cameraPositionNode, 0, 0, 1)
				local v503_, v504_, v505_ = localDirectionToWorld(v496_.cameraPositionNode, 0, 1, 0)
				DebugGizmo.renderAtPosition(v497_, v498_, v499_, v500_, v501_, v502_, v503_, v504_, v505_, "", false, 0.7)
			end
		end
	end
	for v506_, v507_ in pairs(vehicle.components) do
		local v508_, v509_, v510_ = getCenterOfMass(v507_.node)
		local v511_, v512_, v513_ = localToWorld(v507_.node, v508_, v509_, v510_)
		local v514_, v515_, v516_ = localDirectionToWorld(v507_.node, 0, 0, 1)
		local v517_, v518_, v519_ = localDirectionToWorld(v507_.node, 0, 1, 0)
		DebugGizmo.renderAtPosition(v511_, v512_, v513_, v514_, v515_, v516_, v517_, v518_, v519_, "CoM comp" .. v506_, false, 0.7)
	end
	if vehicle.spec_ikChains ~= nil then
		IKUtil.debugDrawChains(vehicle.spec_ikChains.chains, true)
	end
	if vehicle.spec_powerTakeOffs ~= nil then
		for v520_ = 1, #vehicle.spec_powerTakeOffs.outputPowerTakeOffs do
			local v521_ = vehicle.spec_powerTakeOffs.outputPowerTakeOffs[v520_]
			if v521_.outputNode ~= nil then
				local v522_, v523_, v524_ = getWorldTranslation(v521_.outputNode)
				local v525_, v526_, v527_ = localDirectionToWorld(v521_.outputNode, 0, 0, 1)
				local v528_, v529_, v530_ = localDirectionToWorld(v521_.outputNode, 0, 1, 0)
				drawDebugLine(v522_, v523_, v524_, 0, 1, 0, v522_ + v528_ * 0.25, v523_ + v529_ * 0.25, v524_ + v530_ * 0.25, 0, 1, 0)
				drawDebugLine(v522_, v523_, v524_, 0, 0, 1, v522_ + v525_ * 0.25, v523_ + v526_ * 0.25, v524_ + v527_ * 0.25, 0, 0, 1)
				if v521_.connectedInput ~= nil then
					local v531_, v532_, v533_ = localToWorld(v521_.outputNode, 0, 0, -0.05)
					local v534_, v535_, v536_ = localDirectionToWorld(v521_.outputNode, 0, 1, 0)
					local v537_, v538_, v539_ = localDirectionToWorld(v521_.outputNode, 0, 0, -1)
					DebugBox.renderAtPosition(v531_, v532_, v533_, v534_, v535_, v536_, v537_, v538_, v539_, v521_.connectedInput.size, v521_.connectedInput.size, 0.1, Color.PRESETS.YELLOW, true, nil, false)
				end
			end
		end
	end
	if vehicle.spec_connectionHoses ~= nil then
		for v540_ = 1, #vehicle.spec_connectionHoses.targetNodes do
			local v541_ = vehicle.spec_connectionHoses.targetNodes[v540_]
			local v542_, v543_, v544_ = getWorldTranslation(v541_.node)
			local v545_, v546_, v547_ = localDirectionToWorld(v541_.node, 0, 0, -1)
			local v548_, v549_, v550_ = localDirectionToWorld(v541_.node, 0, 1, 0)
			drawDebugLine(v542_, v543_, v544_, 0, 1, 0, v542_ + v548_ * 0.1, v543_ + v549_ * 0.1, v544_ + v550_ * 0.1, 0, 1, 0)
			drawDebugLine(v542_, v543_, v544_, 0, 0, 1, v542_ + v545_ * 0.1, v543_ + v546_ * 0.1, v544_ + v547_ * 0.1, 0, 0, 1)
		end
	end
	if vehicle.spec_mountable ~= nil then
		if vehicle.spec_mountable.dynamicMountJointTransY ~= nil then
			DebugUtil.drawDebugRectangle(vehicle.rootNode, -vehicle.size.width * 0.5, vehicle.size.width * 0.5, -vehicle.size.length * 0.5, vehicle.size.length * 0.5, vehicle.spec_mountable.dynamicMountJointTransY, 0, 1, 0, 0.2, true)
		end
		if vehicle.spec_mountable.additionalMountDistance ~= 0 then
			DebugUtil.drawDebugRectangle(vehicle.rootNode, -vehicle.size.width * 0.5, vehicle.size.width * 0.5, -vehicle.size.length * 0.5, vehicle.size.length * 0.5, vehicle.spec_mountable.additionalMountDistance, 1, 1, 0, 0.2, true)
		end
	end
end

-- Local values: formatNumber, getClosestOffset, drawDebugNode, leftMarker, rightMarker, backMarker, reverserNode, sideOffset, _, aiRootNode, name, collisionTrigger, x, y, z, t, offsetY, IsOnlyAIImplement, _, vehicle2, root
function VehicleDebug.drawDebugAIRendering(vehicle)
	local function v_u_553_(p552_)
		if math.abs(p552_) < 0.001 then
			return "0.0"
		elseif math.abs(p552_) < 0.01 then
			return string.format("%.3f", p552_)
		elseif math.abs(p552_) < 0.1 then
			return string.format("%.2f", p552_)
		else
			return string.format("%.1f", p552_)
		end
	end
	local function v575_(p554_, p555_, p556_)
		-- upvalues: (copy) vehicle, (copy) v_u_553_
		local v557_
		if vehicle.rootVehicle.getAIRootNode == nil then
			v557_ = vehicle.rootNode
		else
			v557_ = vehicle.rootVehicle:getAIRootNode()
		end
		local v558_ = -math.huge
		local v559_ = math.huge
		if vehicle.spec_workArea ~= nil then
			local v560_, _, v561_ = localToLocal(p554_, v557_, 0, 0, 0)
			for _, v562_ in pairs(vehicle.spec_workArea.workAreas) do
				if p555_ == true then
					local _, _, v563_ = localToLocal(v562_.height, v557_, 0, 0, 0)
					local v564_ = v561_ - v563_
					if v564_ > 0 then
						v559_ = math.min(v559_, v564_)
					else
						v558_ = math.max(v558_, v564_)
					end
				elseif p556_ == true then
					local _, _, v565_ = localToLocal(v562_.start, v557_, 0, 0, 0)
					local v566_ = v561_ - v565_
					if v566_ > 0 then
						v559_ = math.min(v559_, v566_)
					else
						v558_ = math.max(v558_, v566_)
					end
					local _, _, v567_ = localToLocal(v562_.width, v557_, 0, 0, 0)
					local v568_ = v561_ - v567_
					if v568_ > 0 then
						v559_ = math.min(v559_, v568_)
					else
						v558_ = math.max(v558_, v568_)
					end
				else
					local v569_, _, _ = localToLocal(v562_.start, v557_, 0, 0, 0)
					local v570_ = v560_ - v569_
					if v570_ > 0 then
						v559_ = math.min(v559_, v570_)
					else
						v558_ = math.max(v558_, v570_)
					end
					local v571_, _, _ = localToLocal(v562_.width, v557_, 0, 0, 0)
					local v572_ = v560_ - v571_
					if v572_ > 0 then
						v559_ = math.min(v559_, v572_)
					else
						v558_ = math.max(v558_, v572_)
					end
					local v573_, _, _ = localToLocal(v562_.height, v557_, 0, 0, 0)
					local v574_ = v560_ - v573_
					if v574_ > 0 then
						v559_ = math.min(v559_, v574_)
					else
						v558_ = math.max(v558_, v574_)
					end
				end
			end
		end
		if math.abs(v558_) < math.abs(v559_) then
			return v_u_553_(v558_)
		else
			return v_u_553_(v559_)
		end
	end
	local function v590_(p576_, p577_, p578_)
		local v579_, v580_, v581_ = getWorldTranslation(p576_)
		local v582_ = getTerrainHeightAtWorldPos(g_terrainNode, v579_, 0, v581_)
		local v583_ = v580_ < 0 and -100 or v582_
		local v584_, v585_, v586_ = localDirectionToWorld(p576_, 0, 1, 0)
		local v587_, v588_, v589_ = localDirectionToWorld(p576_, 0, 0, 1)
		DebugGizmo.renderAtPosition(v579_, v583_ + (p578_ or 0), v581_, v587_, v588_, v589_, v584_, v585_, v586_, p577_, false, 0.5)
	end
	if vehicle.getAIMarkers ~= nil then
		if vehicle:getCanImplementBeUsedForAI() then
			local v591_, v592_, v593_ = vehicle:getAIMarkers()
			v590_(v591_, string.format("%s (x%sm z%sm)", getName(v591_), v575_(v591_), v575_(v591_, false, true)))
			v590_(v592_, string.format("%s (x%sm z%sm)", getName(v592_), v575_(v592_), v575_(v592_, false, true)))
			v590_(v593_, string.format("%s (z%sm)", getName(v593_), v575_(v593_, true)))
			local v594_ = vehicle:getAIToolReverserDirectionNode()
			if v594_ ~= nil then
				local v595_
				if vehicle.rootVehicle.getAIRootNode == nil then
					v595_ = nil
				else
					local v596_ = vehicle.rootVehicle:getAIRootNode()
					local v597_, v598_
					v595_, v597_, v598_ = localToLocal(v594_, v596_, 0, 0, 0)
				end
				local v599_ = v594_ == v593_ and "" or " " .. getName(v594_)
				v590_(v594_, string.format("reverser%s (x%sm)", v599_, v_u_553_(v595_ or 0)), 0.3)
			end
		end
		if not vehicle:getIsAIActive() then
			local v600_ = vehicle:getAIImplementCollisionTrigger()
			if v600_ ~= nil and v600_.node ~= nil then
				local v601_, v602_, v603_ = getWorldTranslation(v600_.node)
				local v604_ = getTerrainHeightAtWorldPos(g_terrainNode, v601_, 0, v603_)
				local v605_ = v602_ - (v602_ < 0 and -100 or v604_) - v600_.height * 0.5
				DebugUtil.drawDebugCube(v600_.node, v600_.width, v600_.height, v600_.length, 0, 0, 1, 0, -v605_, v600_.length * 0.5)
			end
		end
		local v606_ = true
		for _, v607_ in ipairs(vehicle.rootVehicle.childVehicles) do
			if v607_ ~= vehicle and (v607_.getCanImplementBeUsedForAI ~= nil and v607_:getCanImplementBeUsedForAI()) then
				v606_ = false
				break
			end
		end
		if (v606_ or vehicle:getIsSelected()) and (vehicle.spec_aiImplement ~= nil and vehicle.spec_aiImplement.debugArea ~= nil) then
			g_debugManager:addFrameElement(vehicle.spec_aiImplement.debugArea)
		end
	end
	if vehicle.drawDebugAIAgent ~= nil then
		vehicle:drawDebugAIAgent()
	end
	if vehicle.drawAIAgentAttachments ~= nil then
		vehicle:drawAIAgentAttachments()
	end
	if Platform.gameplay.automaticVehicleControl then
		local v608_ = vehicle.rootVehicle
		if v608_.getIsControlled ~= nil and (v608_:getIsControlled() and v608_.actionController ~= nil) then
			v608_.actionController:drawDebugRendering()
		end
	end
end

-- Local values: information, k, v, values, info, d
function VehicleDebug.drawDebugValues(vehicle)
	local v610_ = {}
	for v611_, v612_ in ipairs(vehicle.specializations) do
		if v612_.updateDebugValues ~= nil then
			local v613_ = {}
			v612_.updateDebugValues(vehicle, v613_)
			if #v613_ > 0 then
				local v614_ = {
					["title"] = vehicle.specializationNames[v611_],
					["content"] = v613_
				}
				table.insert(v610_, v614_)
			end
		end
	end
	local v615_ = DebugInfoTable.new()
	v615_:createWithNodeToCamera(vehicle.rootNode, v610_, 4, 0.05)
	g_debugManager:addFrameElement(v615_)
end

-- Local values: x, y, width, height, textSize, xSectionWidth, lineHeight, drawBar, drawModifiers, i, lineY, _, sample, isSurfaceSound, _, surfaceSound, showSample, typeIndex, type, _, attribute, _, _, available, modVolume, barX, barY, barW, barH, startX, modPitch, modLowPassGain, wheelsSpec, wx, wy, wz
function VehicleDebug.drawSoundDebugValues(vehicle)
	local v_u_617_ = 0.015
	local v618_ = 0.1 + g_pixelSizeX
	local function v_u_631_(p619_, p620_, p621_, p622_, p623_, p624_, p625_, p626_, p627_, p628_, p629_, p630_)
		-- upvalues: (copy) v_u_617_
		drawOutlineRect(p619_, p620_, p621_, p622_, g_pixelSizeX, g_pixelSizeY, 0, 0, 0, 1)
		drawFilledRect(p619_ + g_pixelSizeX, p620_ + g_pixelSizeY, p621_ - g_pixelSizeX * 2, p622_ - g_pixelSizeY * 2, 0, 0, 0, 0.4)
		drawFilledRect(p619_ + g_pixelSizeX, p620_ + g_pixelSizeY, p621_ * p623_ - g_pixelSizeX * 2, p622_ - g_pixelSizeY * 2, p626_, p627_, p628_, p629_)
		if p624_ ~= -1 then
			drawFilledRect(p619_ + p621_ * p624_, p620_, g_pixelSizeX, p622_, 1, 0, 0, 1)
		end
		setTextAlignment(RenderText.ALIGN_CENTER)
		renderText(p619_ + p621_ * 0.5, p620_ + p622_ - 0.0075 - g_pixelSizeY * 4, 0.012 * (p630_ or 1), p625_)
	end
	setTextColor(1, 1, 1, 1)
	local v632_ = 0.15
	local function v655_(p633_, p634_, p635_, p636_, p637_, p638_)
		-- upvalues: (copy) v_u_631_
		local v639_ = {}
		for v640_, v641_ in pairs(g_soundManager.modifierTypeIndexToDesc) do
			local v642_, v643_, v644_ = g_soundManager:getSampleModifierValue(p637_, p638_, v640_)
			if v644_ then
				local v645_ = {
					["changeValue"] = v642_,
					["t"] = v643_,
					["name"] = v641_.name
				}
				table.insert(v639_, v645_)
			end
		end
		if p637_.maxValuePerModifier == nil then
			p637_.maxValuePerModifier = {}
			for _, v646_ in pairs(g_soundManager.modifierTypeIndexToDesc) do
				p637_.maxValuePerModifier[v646_.name] = 0
			end
		end
		local v647_ = #v639_
		if v647_ > 0 then
			local v648_ = p635_ / v647_
			for v649_ = 1, v647_ do
				local v650_ = v639_[v649_]
				local v651_ = p637_.maxValuePerModifier
				local v652_ = v650_.name
				local v653_ = p637_.maxValuePerModifier[v650_.name]
				local v654_ = v650_.changeValue
				v651_[v652_] = math.max(v653_, v654_, 1)
				v_u_631_(p633_ + v648_ * (v649_ - 1), p634_, v648_ * (v649_ < v647_ and 0.95 or 1), p636_, v650_.changeValue / p637_.maxValuePerModifier[v650_.name], -1, string.format("%s raw:%.2f mod:%.2f", v650_.name, v650_.t, v650_.changeValue), 0, 0.5, 0, 0.3, 0.7)
			end
		end
	end
	local v656_ = 0.9
	local v657_ = 0.06
	local v658_ = 1
	for _, v659_ in pairs(g_soundManager.orderedSamples) do
		local v660_ = false
		for _, v661_ in pairs(g_currentMission.surfaceSounds) do
			if v661_.name == v659_.sampleName then
				v660_ = true
			end
		end
		if v659_.modifierTargetObject == vehicle and not v660_ then
			local v662_ = v659_.isGlsFile
			if not v662_ then
				for v663_, _ in pairs(g_soundManager.modifierTypeIndexToDesc) do
					for _, v664_ in pairs({ "volume", "pitch", "lowpassGain" }) do
						local _, _, v665_ = g_soundManager:getSampleModifierValue(v659_, v664_, v663_)
						v662_ = v662_ or v665_
						if v662_ then
							break
						end
					end
				end
			end
			if v662_ then
				v656_ = v656_ - 0.06
				drawOutlineRect(0.15, v656_, v618_, v657_ + g_pixelSizeY, g_pixelSizeX, g_pixelSizeY, 0, 0, 0, 1)
				drawOutlineRect(0.15, v656_, 0.7, v657_ + g_pixelSizeY, g_pixelSizeX, g_pixelSizeY, 0, 0, 0, 1)
				drawFilledRect(0.15, v656_, v618_, 0.06, 0, g_soundManager:getIsSamplePlaying(v659_) and 1 or 0, 0, 0.4)
				setTextAlignment(RenderText.ALIGN_CENTER)
				renderText(v632_ + v618_ * 0.5, v656_ + 0.06 - 0.012 - 0.0075, 0.018, v659_.sampleName)
				if v659_.isGlsFile then
					renderText(v632_ + v618_ * 0.5, v656_ + 0.06 - 0.024 - 0.0075, 0.012, string.format("loopSyn: rpm=%d load=%d%%", getSampleLoopSynthesisRPM(v659_.soundSample, false), getSampleLoopSynthesisLoadFactor(v659_.soundSample) * 100))
				end
				setTextAlignment(RenderText.ALIGN_RIGHT)
				renderText(v632_ + v618_ + v618_ * 0.6, v656_ + 0.06 - 0.015 - 0.0075, 0.015, "volume:")
				renderText(v632_ + v618_ + v618_ * 0.6, v656_ + 0.06 - 0.03 - 0.0075, 0.015, "pitch:")
				renderText(v632_ + v618_ + v618_ * 0.6, v656_ + 0.06 - 0.045 - 0.0075, 0.015, "lowpassGain:")
				local v666_ = g_soundManager:getModifierFactor(v659_, "volume")
				local v667_ = v659_.debugMaxVolume or 1
				local v668_ = v659_.current.volume * v666_
				local v669_ = v659_.current.volume
				v659_.debugMaxVolume = math.max(v667_, v668_, v669_)
				local v670_ = v632_ + v618_ + v618_ * 0.7
				local v671_ = v656_ + 0.06 - 0.015 - 0.0075
				local v672_ = 0.015
				v_u_631_(v670_, v671_, v618_, v672_, v659_.current.volume * v666_ / v659_.debugMaxVolume, v659_.current.volume / v659_.debugMaxVolume, string.format("%.2f", v659_.current.volume * v666_), 0, 0.5, 0, 0.4)
				local v673_ = v670_ + v618_ + v618_ * 0.1
				v655_(v673_, v671_, 1 - v673_ - 0.15 - v618_ * 0.1, v672_, v659_, "volume")
				local v674_ = g_soundManager:getModifierFactor(v659_, "pitch")
				local v675_ = v659_.debugMaxPitch or 1
				local v676_ = v659_.current.pitch * v674_
				local v677_ = v659_.current.pitch
				v659_.debugMaxPitch = math.max(v675_, v676_, v677_)
				local v678_ = v632_ + v618_ + v618_ * 0.7
				local v679_ = v656_ + 0.06 - 0.03 - 0.0075
				local v680_ = 0.015
				v_u_631_(v678_, v679_, v618_, v680_, v659_.current.pitch * v674_ / v659_.debugMaxPitch, v659_.current.pitch / v659_.debugMaxPitch, string.format("%.2f", v659_.current.pitch * v674_), 0.5, 0.5, 0, 0.4)
				local v681_ = v678_ + v618_ + v618_ * 0.1
				v655_(v681_, v679_, 1 - v681_ - 0.15, v680_, v659_, "pitch")
				local v682_ = g_soundManager:getModifierFactor(v659_, "lowpassGain")
				local v683_ = v659_.debugMaxLowPass or 1
				local v684_ = v659_.current.lowpassGain * v682_
				local v685_ = v659_.current.lowpassGain
				v659_.debugMaxLowPass = math.max(v683_, v684_, v685_)
				local v686_ = v632_ + v618_ + v618_ * 0.7
				local v687_ = v656_ + 0.06 - 0.045 - 0.0075
				local v688_ = 0.015
				v_u_631_(v686_, v687_, v618_, v688_, v659_.current.lowpassGain * v682_ / v659_.debugMaxLowPass, v659_.current.lowpassGain / v659_.debugMaxLowPass, string.format("%.2f", v659_.current.lowpassGain * v682_), 0, 0.5, 0.5, 0.4)
				local v689_ = v686_ + v618_ + v618_ * 0.1
				v655_(v689_, v687_, 1 - v689_ - 0.15, v688_, v659_, "lowpassGain")
			end
			v658_ = v658_ + 1
		end
	end
	local v690_ = vehicle.spec_wheels
	if v690_ then
		local v691_, v692_, v693_ = getWorldTranslation(vehicle.rootNode)
		Utils.renderTextAtWorldPosition(v691_, v692_, v693_, string.format("surfaceSound: %s", v690_.currentSurfaceSound and v690_.currentSurfaceSound.sampleName or "none"), 0.01)
	end
	setTextAlignment(RenderText.ALIGN_LEFT)
	VehicleDebug.drawMotorLoadGraph(vehicle, 0.2, 0.05, 0.25, 0.2)
	VehicleDebug.drawMotorRPMGraph(vehicle, 0.55, 0.05, 0.25, 0.2)
	VehicleDebug.drawMotorAccelerationGraph(vehicle, 0.2, 0.28, 0.25, 0.1)
end

-- Local values: x, y, width, height, textSize, textSize2, timeLineOffset, timeLineWidth, lineHeight, lineHeightPart, numAnims, spec, _, animation, selected, i, lineY, name, animation, widthPerMs, divider, j, startLineY, k, _, animPartIndex, part, animValue, index, partName, headTextSize, headLineHeight, sampleTimesPerSample, j, sample, filename, times, sampleName, timesIndex, timeData, r, g, b, a, minX, maxX, rx, ry, rwidth, rheight, animPartIndex, part, animValue, index
function VehicleDebug.drawAnimationDebug(vehicle)
	if vehicle.playAnimation ~= nil then
		local v695_ = 0.1 + g_pixelSizeX
		local v696_ = 0.7 - v695_ - g_pixelSizeX * 2
		local v697_ = vehicle.spec_animatedVehicle
		local v698_ = 0
		local v699_ = 0.05
		local v700_ = 0.15
		local v701_ = 0.0125
		for _, v702_ in pairs(v697_.animations) do
			if #v702_.parts > 0 then
				v698_ = v698_ + 1
			end
		end
		local v703_ = VehicleDebug.selectedAnimation % v698_ + 1
		setTextColor(1, 1, 1, 1)
		local v704_ = 1
		local v705_ = 0.9
		for v706_, v707_ in pairs(v697_.animations) do
			if #v707_.parts > 0 then
				local v708_ = v705_ - 0.05
				drawOutlineRect(0.15, v708_, 0.7, v699_ + g_pixelSizeY, g_pixelSizeX, g_pixelSizeY, 0, 0, 0, 1)
				drawFilledRect(0.15, v708_, 0.7, 0.05, 0, 0, 0, 0.4)
				drawFilledRect(v700_ + v695_ - g_pixelSizeX, v708_, g_pixelSizeX, 0.05, 0, 0, 0, 1)
				local v709_ = v696_ / v707_.duration
				local v710_ = v707_.duration < 2000 and 500 or 1000
				local v711_ = v707_.duration < 1000 and 100 or v710_
				local v712_ = v707_.duration / v711_
				for v713_ = 1, math.floor(v712_) do
					if v713_ * v711_ ~= v707_.duration then
						setTextAlignment(RenderText.ALIGN_CENTER)
						renderText(v700_ + v695_ + v709_ * v713_ * v711_, v708_ + 0.025 - 0.005, 0.01, string.format("%.1f", v713_ * v711_ / 1000))
						drawFilledRect(v700_ + v695_ + v709_ * v713_ * v711_, v708_, g_pixelSizeX, 0.015, 0, 0, 0, 1)
					end
				end
				setTextBold(v703_ == v704_)
				setTextAlignment(RenderText.ALIGN_CENTER)
				renderText(v700_ + v695_ * 0.5, v708_ + 0.025 - 0.0075, 0.015, v706_)
				setTextBold(false)
				if v703_ == v704_ then
					if v707_.lineHeightByPart == nil then
						v707_.lineHeightByPart = {}
						v705_ = v708_
					else
						v705_ = v708_
						for v714_, _ in pairs(v707_.lineHeightByPart) do
							v707_.lineHeightByPart[v714_] = nil
						end
					end
					for v715_ = 1, #v707_.parts do
						local v716_ = v707_.parts[v715_].animationValues[1]
						local v717_ = v716_.node or v716_.componentJoint
						if v717_ ~= nil and v707_.lineHeightByPart[v717_] == nil then
							v705_ = v705_ - 0.0125
							drawOutlineRect(0.15, v705_, 0.7, v701_ + g_pixelSizeY, g_pixelSizeX, g_pixelSizeY, 0, 0, 0, 1)
							drawFilledRect(0.15, v705_, 0.7, 0.0125, 0, 0, 0, 0.2)
							drawFilledRect(v700_ + v695_ - g_pixelSizeX, v705_, g_pixelSizeX, 0.0125, 0, 0, 0, 1)
							local v718_ = "unknown"
							if v716_.node == nil then
								if v716_.componentJoint ~= nil then
									v718_ = string.format("compJoint \'%d\'", v716_.componentJoint.index)
								end
							else
								v718_ = string.format("node \'%s\'", getName(v716_.node))
							end
							setTextAlignment(RenderText.ALIGN_CENTER)
							renderText(v700_ + v695_ * 0.5, v705_ + 0.00625 - 0.005 + g_pixelSizeY * 2, 0.01, v718_)
							v707_.lineHeightByPart[v717_] = v705_
						end
					end
					if #v707_.samples > 0 then
						v705_ = v705_ - 0.018750000000000003
						drawOutlineRect(0.15, v705_, 0.7, 0.018750000000000003 + g_pixelSizeY, g_pixelSizeX, g_pixelSizeY, 0, 0, 0, 1)
						drawFilledRect(0.15, v705_, 0.7, 0.018750000000000003, 0, 0, 0, 0.2)
						setTextAlignment(RenderText.ALIGN_CENTER)
						renderText(0.5, v705_ + 0.009375000000000001 - 0.0075 + g_pixelSizeY * 2, 0.015, "Sounds:")
					end
					local v719_ = {}
					for v720_ = 1, #v707_.samples do
						local v721_ = v707_.samples[v720_]
						if v719_[v721_.filename] == nil then
							v719_[v721_.filename] = {}
						end
						local v722_ = v719_[v721_.filename]
						local v723_ = {
							["sample"] = v721_,
							["startTime"] = v721_.startTime,
							["endTime"] = v721_.endTime,
							["loops"] = v721_.loops,
							["direction"] = v721_.direction
						}
						table.insert(v722_, v723_)
					end
					for _, v724_ in pairs(v719_) do
						v705_ = v705_ - 0.0125
						drawOutlineRect(0.15, v705_, 0.7, v701_ + g_pixelSizeY, g_pixelSizeX, g_pixelSizeY, 0, 0, 0, 1)
						drawFilledRect(0.15, v705_, 0.7, 0.0125, 0, 0, 0, 0.2)
						drawFilledRect(v700_ + v695_ - g_pixelSizeX, v705_, g_pixelSizeX, 0.0125, 0, 0, 0, 1)
						local v725_ = "unknown"
						for v726_ = 1, #v724_ do
							local v727_ = v724_[v726_]
							v725_ = v727_.sample.templateName or v727_.sample.sampleName
							local v728_ = 0
							local v729_
							if g_soundManager:getIsSamplePlaying(v727_.sample) then
								v729_ = 1
								if v727_.loops == 1 then
									v728_ = 1
								end
							else
								v729_ = 0
							end
							local v730_ = v700_ + v695_
							local v731_ = 0
							local v732_ = v705_ + 0.0012500000000000002 + g_pixelSizeY
							local v733_ = 0
							local v734_ = 0.010000000000000002 - g_pixelSizeY
							if v727_.startTime == nil or v727_.endTime ~= nil then
								if v727_.startTime == nil or (v727_.endTime == nil or v727_.loops ~= 0) then
									if v727_.startTime ~= nil and (v727_.endTime ~= nil and v727_.loops == 1) then
										local v735_ = v700_ + v695_ + v709_ * v727_.startTime - v709_ * 25
										local v736_ = math.max(v730_, v735_)
										local v737_ = v709_ * 50
										local v738_ = 0.85 - (v736_ + v737_)
										local v739_ = v737_ + math.min(v738_, 0)
										drawFilledRect(v736_, v732_, v739_, v734_, v728_, v729_, 0, 0.9)
										local v740_ = v700_ + v695_ + v709_ * v727_.endTime - v709_ * 25
										v731_ = math.max(v730_, v740_)
										local v741_ = v709_ * 50
										local v742_ = 0.85 - (v731_ + v741_)
										v733_ = v741_ + math.min(v742_, 0)
									end
								else
									v731_ = v700_ + v695_ + v709_ * v727_.startTime + v709_ * 5
									v733_ = v709_ * (v727_.endTime - v727_.startTime) - v709_ * 10
								end
							else
								local v743_ = v700_ + v695_ + v709_ * v727_.startTime - v709_ * 25
								v731_ = math.max(v730_, v743_)
								local v744_ = v709_ * 50
								local v745_ = 0.85 - (v731_ + v744_)
								v733_ = v744_ + math.min(v745_, 0)
							end
							drawFilledRect(v731_, v732_, v733_, v734_, v728_, v729_, 0, 0.9)
						end
						setTextAlignment(RenderText.ALIGN_CENTER)
						renderText(v700_ + v695_ * 0.5, v705_ + 0.00625 - 0.005 + g_pixelSizeY * 2, 0.01, v725_)
					end
					for v746_ = 1, #v707_.parts do
						local v747_ = v707_.parts[v746_]
						local v748_ = v747_.animationValues[1]
						local v749_ = v748_.node or v748_.componentJoint
						if v749_ ~= nil then
							drawFilledRect(v700_ + v695_ + v709_ * v747_.startTime, v707_.lineHeightByPart[v749_] + 0.0012500000000000002 + g_pixelSizeY, v709_ * v747_.duration, 0.010000000000000002 - g_pixelSizeY, 0, 0, 0, 0.9)
						end
					end
				else
					v705_ = v708_
				end
				drawFilledRect(v700_ + v695_ + v709_ * v707_.currentTime, v705_, g_pixelSizeX, v708_ - v705_ + 0.034999999999999996, 0, 1, 0, 1)
				setTextAlignment(RenderText.ALIGN_CENTER)
				renderText(v700_ + v695_ + v709_ * v707_.currentTime, v705_ + (v708_ - v705_) + 0.045000000000000005 - 0.005, 0.01, string.format("%.2f", v707_.currentTime / 1000))
				v704_ = v704_ + 1
			end
		end
		setTextAlignment(RenderText.ALIGN_LEFT)
	end
end

-- Local values: visualWheelIndex, wheels, i, wheel, x, y, z, offset, _, visualWheel, _, visualWheelPart, ox, oy, oz, wx, wy, wz, cx, cy, cz, widthOffset
function VehicleDebug.updateTuningDebugRendering(vehicle, dt)
	if vehicle.propertyState == VehiclePropertyState.SHOP_CONFIG then
		local v751_ = vehicle:getWheels()
		local v752_ = 0
		for v753_ = 1, #v751_ do
			local v754_ = v751_[v753_]
			local v755_, v756_, v757_ = getWorldTranslation(v751_[v753_].driveNodeDirectionNode)
			local v758_
			if v756_ < 50 then
				v758_ = v756_ + 100
			else
				v758_ = v756_ - getTerrainHeightAtWorldPos(g_terrainNode, v755_, 0, v757_)
			end
			drawDebugLine(v755_, v756_ - v754_.physics.radius, v757_, 0, 1, 0, v755_, v756_, v757_, 0, 1, 0, false)
			Utils.renderTextAtWorldPosition(v755_, v756_ - v754_.physics.radius * 0.5, v757_, string.format("%.3f", v758_), getCorrectTextSize(0.012), 0, 0, 1, 0, 1)
			for _, v759_ in ipairs(v754_.visualWheels) do
				for _, v760_ in ipairs(v759_.visualParts) do
					if v760_:isa(WheelVisualPartTire) then
						local v761_, v762_, v763_ = localToLocal(v760_.node, v754_.node, 0, 0, 0)
						local v764_, v765_, v766_ = localToWorld(v760_.node, 0, 0, 0)
						local v767_, v768_, v769_ = localToWorld(v754_.node, 0, v762_, v763_)
						drawDebugLine(v764_, v765_, v766_, 1, 0, 0, v767_, v768_, v769_, 1, 0, 0, false)
						Utils.renderTextAtWorldPosition(v764_, v765_, v766_, string.format("%.3f", math.abs(v761_) * 2), getCorrectTextSize(0.012), 0, 1, 0, 0, 1)
						local v770_ = v759_.width * 0.5 * (v754_.isLeft and 1 or -1)
						local v771_, _, _ = localToLocal(v760_.node, v754_.node, v770_, 0, 0)
						local v772_, v773_, v774_ = localToWorld(v760_.node, v770_, 0, 0)
						drawDebugLine(v772_, v773_ - 0.1, v774_, 0, 1, 1, v772_, v773_ + 0.1, v774_, 0, 1, 1, false)
						Utils.renderTextAtWorldPosition(v772_, v773_, v774_, string.format("%.3f", math.abs(v771_) * 2), getCorrectTextSize(0.012), 0, 0, 1, 1, 1)
					end
				end
				renderText(0.25, 0.1 + 0.02 * v752_, 0.018, string.format("%d - %s (%s)", v753_, v759_.externalXMLFilename, v759_.externalConfigId))
				v752_ = v752_ + 1
			end
		end
	end
end

-- Local values: self, groundRaycastResult, i, attacherJoint, trx, try, trz, rx, ry, rz, rx2, ry2, rz2, x, y, z, _, dy, _, angle, _, dxy, _, _, dy, _, angle, _, dxy, _, sx, sy, sz, _, y, _, wx, wy, wz, i, wheel, _, comY, _, forcePointY, tireLoad, nx, ny, nz, dx, dy, dz, gravity
function VehicleDebug.consoleCommandAnalyze(unusedSelf)
	if g_currentMission == nil or (g_localPlayer:getCurrentVehicle() == nil or not g_localPlayer:getCurrentVehicle().isServer) then
		return "Failed to analyze vehicle. Invalid controlled vehicle"
	end
	local v775_ = g_localPlayer:getCurrentVehicle():getSelectedVehicle()
	if v775_ == nil then
		v775_ = g_localPlayer:getCurrentVehicle()
	end
	print("Analyzing vehicle \'" .. v775_.configFileName .. "\'. Make sure vehicle is standing on a flat plane parallel to xz-plane")
	local v779_ = {
		["raycastCallback"] = function(p776_, p777_, _, _, _, p778_, _, _, _)
			if p776_.vehicle.vehicleNodes[p777_] ~= nil then
				return true
			end
			if p776_.vehicle.aiTrafficCollisionTrigger == p777_ then
				return true
			end
			if p777_ ~= g_terrainNode then
				printWarning("Warning: Vehicle is not standing on ground! " .. getName(p777_))
			end
			p776_.groundDistance = p778_
			return false
		end
	}
	if v775_.spec_attacherJoints ~= nil then
		for v780_, v781_ in ipairs(v775_.spec_attacherJoints.attacherJoints) do
			local v782_, v783_, v784_ = getRotation(v781_.jointTransform)
			local v785_ = setRotation
			local v786_ = v781_.jointTransform
			local v787_ = v781_.jointOrigRot
			v785_(v786_, unpack(v787_))
			if v781_.rotationNode ~= nil or v781_.rotationNode2 ~= nil then
				local v788_, v789_, v790_
				if v781_.rotationNode == nil then
					v788_ = nil
					v789_ = nil
					v790_ = nil
				else
					v788_, v789_, v790_ = getRotation(v781_.rotationNode)
				end
				local v791_, v792_, v793_
				if v781_.rotationNode2 == nil then
					v791_ = nil
					v792_ = nil
					v793_ = nil
				else
					v791_, v792_, v793_ = getRotation(v781_.rotationNode2)
				end
				if v781_.rotationNode ~= nil then
					local v794_ = setRotation
					local v795_ = v781_.rotationNode
					local v796_ = v781_.lowerRotation
					v794_(v795_, unpack(v796_))
				end
				if v781_.rotationNode2 ~= nil then
					local v797_ = setRotation
					local v798_ = v781_.rotationNode2
					local v799_ = v781_.lowerRotation2
					v797_(v798_, unpack(v799_))
				end
				local v800_, v801_, v802_ = getWorldTranslation(v781_.jointTransform)
				v779_.groundDistance = 0
				v779_.vehicle = v775_
				raycastAll(v800_, v801_, v802_, 0, -1, 0, 4, "raycastCallback", v779_, 4294967295)
				local v803_ = v779_.groundDistance - v781_.lowerDistanceToGround
				if math.abs(v803_) > 0.01 then
					print(string.format(" Issue found: Attacher joint %d has invalid lowerDistanceToGround. True value is: %.3f (Value in xml: %.3f)", v780_, MathUtil.round(v779_.groundDistance, 3), v781_.lowerDistanceToGround))
				end
				if v781_.rotationNode ~= nil and v781_.rotationNode2 ~= nil then
					local _, v804_, _ = localDirectionToWorld(v781_.jointTransform, 0, 1, 0)
					local v805_ = math.clamp(v804_, -1, 1)
					local v806_ = math.acos(v805_)
					local v807_ = math.deg(v806_)
					local _, v808_, _ = localDirectionToWorld(v781_.jointTransform, 1, 0, 0)
					if v808_ < 0 then
						v807_ = -v807_
					end
					local v809_ = v781_.lowerRotationOffset
					local v810_ = v807_ - math.deg(v809_)
					if math.abs(v810_) > 0.05 then
						local v811_ = print
						local v812_ = string.format
						local v813_ = v781_.lowerRotationOffset
						v811_(v812_(" Issue found: Attacher joint %d has invalid lowerRotationOffset. True value is: %.2f\194\176 (Value in xml: %.2f\194\176)", v780_, v807_, (math.deg(v813_))))
					end
				end
				if v781_.rotationNode ~= nil then
					local v814_ = setRotation
					local v815_ = v781_.rotationNode
					local v816_ = v781_.upperRotation
					v814_(v815_, unpack(v816_))
				end
				if v781_.rotationNode2 ~= nil then
					local v817_ = setRotation
					local v818_ = v781_.rotationNode2
					local v819_ = v781_.upperRotation2
					v817_(v818_, unpack(v819_))
				end
				local v820_, v821_, v822_ = getWorldTranslation(v781_.jointTransform)
				v779_.groundDistance = 0
				raycastAll(v820_, v821_, v822_, 0, -1, 0, 4, "raycastCallback", v779_, 4294967295)
				local v823_ = v779_.groundDistance - v781_.upperDistanceToGround
				if math.abs(v823_) > 0.01 then
					print(string.format(" Issue found: Attacher joint %d has invalid upperDistanceToGround. True value is: %.3f (Value in xml: %.3f)", v780_, MathUtil.round(v779_.groundDistance, 3), v781_.upperDistanceToGround))
				end
				if v781_.rotationNode ~= nil and v781_.rotationNode2 ~= nil then
					local _, v824_, _ = localDirectionToWorld(v781_.jointTransform, 0, 1, 0)
					local v825_ = math.clamp(v824_, -1, 1)
					local v826_ = math.acos(v825_)
					local v827_ = math.deg(v826_)
					local _, v828_, _ = localDirectionToWorld(v781_.jointTransform, 1, 0, 0)
					if v828_ < 0 then
						v827_ = -v827_
					end
					local v829_ = v781_.upperRotationOffset
					local v830_ = v827_ - math.deg(v829_)
					if math.abs(v830_) > 0.05 then
						local v831_ = print
						local v832_ = string.format
						local v833_ = v781_.upperRotationOffset
						v831_(v832_(" Issue found: Attacher joint %d has invalid upperRotationOffset. True value is: %.2f\194\176 (Value in xml: %.2f\194\176)", v780_, v827_, (math.deg(v833_))))
					end
				end
				if v781_.rotationNode ~= nil then
					setRotation(v781_.rotationNode, v788_, v789_, v790_)
				end
				if v781_.rotationNode2 ~= nil then
					setRotation(v781_.rotationNode2, v791_, v792_, v793_)
				end
			end
			setRotation(v781_.jointTransform, v782_, v783_, v784_)
			if v781_.transNode ~= nil then
				local v834_, v835_, v836_ = getTranslation(v781_.transNode)
				local _, v837_, _ = localToLocal(v781_.rootNode, getParent(v781_.transNode), 0, v781_.transNodeMinY, 0)
				setTranslation(v781_.transNode, v834_, v837_, v836_)
				v779_.groundDistance = 0
				v779_.vehicle = v775_
				local v838_, v839_, v840_ = getWorldTranslation(v781_.transNode)
				raycastAll(v838_, v839_, v840_, 0, -1, 0, 4, "raycastCallback", v779_, 4294967295)
				local v841_ = v779_.groundDistance - v781_.lowerDistanceToGround
				if math.abs(v841_) > 0.02 then
					print(string.format(" Issue found: Attacher joint %d has invalid lowerDistanceToGround. True value is: %.3f (Value in xml: %.3f)", v780_, MathUtil.round(v779_.groundDistance, 3), v781_.lowerDistanceToGround))
				end
				local _, v842_, _ = localToLocal(v781_.rootNode, getParent(v781_.transNode), 0, v781_.transNodeMaxY, 0)
				setTranslation(v781_.transNode, v834_, v842_, v836_)
				v779_.groundDistance = 0
				local v843_, v844_, v845_ = getWorldTranslation(v781_.transNode)
				raycastAll(v843_, v844_, v845_, 0, -1, 0, 4, "raycastCallback", v779_, 4294967295)
				local v846_ = v779_.groundDistance - v781_.upperDistanceToGround
				if math.abs(v846_) > 0.02 then
					print(string.format(" Issue found: Attacher joint %d has invalid upperDistanceToGround. True value is: %.3f (Value in xml: %.3f)", v780_, MathUtil.round(v779_.groundDistance, 3), v781_.upperDistanceToGround))
				end
				setTranslation(v781_.transNode, v834_, v835_, v836_)
			end
		end
	end
	if v775_.spec_wheels ~= nil then
		for v847_, v848_ in ipairs(v775_.spec_wheels.wheels) do
			if v848_.physics.wheelShapeCreated then
				local _, v849_, _ = getCenterOfMass(v848_.node)
				local v850_ = v848_.physics.positionY + v848_.physics.deltaY - v848_.physics.radius * v848_.physics.forcePointRatio
				if v849_ < v850_ then
					print(string.format(" Issue found: Wheel %d has force point higher than center of mass. %.2f > %.2f. This can lead to undesired driving behavior (inward-leaning).", v847_, v850_, v849_))
				end
				local v851_ = getWheelShapeContactForce(v848_.node, v848_.physics.wheelShape)
				if v851_ ~= nil then
					local v852_, v853_, v854_ = getWheelShapeContactNormal(v848_.node, v848_.physics.wheelShape)
					local v855_, v856_, v857_ = localDirectionToWorld(v848_.node, 0, -1, 0)
					local v858_ = -v851_ * MathUtil.dotProduct(v855_, v856_, v857_, v852_, v853_, v854_)
					local v859_ = v853_ * 9.81
					local v860_ = (v858_ + math.max(v859_, 0) * v848_:getMass()) / 9.81
					local v861_ = v860_ - v848_.physics.restLoad
					if math.abs(v861_) > 0.2 then
						print(string.format(" Issue found: Wheel %d has wrong restLoad. %.2f vs. %.2f in XML. Verify that this leads to the desired behavior.", v847_, v860_, v848_.physics.restLoad))
					end
				end
			end
		end
	end
	return "Analyzed vehicle"
end

-- Local values: vehicle, attacherVehicle, implement, jointDescIndex, jointDesc
function VehicleDebug:moveUpperRotation(actionName, inputValue, callbackState, isAnalog)
	if VehicleDebug.currentAttacherJointVehicle ~= nil and inputValue ~= 0 then
		local v863_ = VehicleDebug.currentAttacherJointVehicle
		if v863_.getAttacherVehicle ~= nil then
			local v864_ = v863_:getAttacherVehicle()
			if v864_ ~= nil then
				local v865_ = v864_:getImplementByObject(v863_)
				if v865_ ~= nil then
					local v866_ = v865_.jointDescIndex
					local v867_ = v864_.spec_attacherJoints.attacherJoints[v866_]
					if v867_.rotationNode ~= nil then
						local v868_ = v867_.upperRotation
						local v869_ = v867_.upperRotation[1]
						local v870_ = inputValue * 0.002 * 16
						v868_[1] = v869_ + math.rad(v870_)
						v867_.moveAlpha = v867_.moveAlpha - 0.001
						local v871_ = print
						local v872_ = v867_.upperRotation[1]
						v871_("upperRotation: " .. math.deg(v872_))
					end
				end
			end
		end
	end
end

-- Local values: vehicle, attacherVehicle, implement, jointDescIndex, jointDesc
function VehicleDebug:moveLowerRotation(actionName, inputValue, callbackState, isAnalog)
	if VehicleDebug.currentAttacherJointVehicle ~= nil and inputValue ~= 0 then
		local v874_ = VehicleDebug.currentAttacherJointVehicle
		if v874_.getAttacherVehicle ~= nil then
			local v875_ = v874_:getAttacherVehicle()
			if v875_ ~= nil then
				local v876_ = v875_:getImplementByObject(v874_)
				if v876_ ~= nil then
					local v877_ = v876_.jointDescIndex
					local v878_ = v875_.spec_attacherJoints.attacherJoints[v877_]
					if v878_.rotationNode ~= nil then
						local v879_ = v878_.lowerRotation
						local v880_ = v878_.lowerRotation[1]
						local v881_ = inputValue * 0.002 * 16
						v879_[1] = v880_ + math.rad(v881_)
						v878_.moveAlpha = v878_.moveAlpha - 0.001
						local v882_ = print
						local v883_ = v878_.lowerRotation[1]
						v882_("lowerRotation: " .. math.deg(v883_))
					end
				end
			end
		end
	end
end

-- Local values: exportVehicleScenegraph, vehicle, i
function VehicleDebug.consoleCommandExportScenegraph(unusedSelf, animationName, animationTime, additionalName)
	local function v_u_923_(p_u_887_)
		-- upvalues: (copy) additionalName
		local v888_ = getTimeSec()
		local v889_ = additionalName or ""
		local v890_ = string.format(getUserProfileAppPath() .. "scenegraph_%s%s.xml", p_u_887_.configFileNameClean, (tostring(v889_)))
		local v_u_891_ = XMLFile.create("scenegraph", v890_, "scenegraph", nil)
		local function v_u_917_(p892_, p893_, p894_, p895_, p896_)
			-- upvalues: (copy) v_u_891_, (copy) p_u_887_, (copy) v_u_917_
			local v897_ = p894_ .. string.format("(%d)", p895_)
			v_u_891_:setString(v897_ .. "#name", getName(p892_))
			v_u_891_:setString(v897_ .. "#indexPath", p893_)
			local v898_, v899_, v900_ = getTranslation(p892_)
			v_u_891_:setString(v897_ .. "#translation", v898_ .. " " .. v899_ .. " " .. v900_)
			local v901_, v902_, v903_ = getRotation(p892_)
			v_u_891_:setString(v897_ .. "#rotation", math.deg(v901_) .. " " .. math.deg(v902_) .. " " .. math.deg(v903_))
			if p896_ ~= nil then
				v_u_891_:setFloat(v897_ .. "#mass", p_u_887_:getComponentMass(p896_))
			end
			local v904_ = getNumOfChildren(p892_)
			if v904_ > 0 then
				local v905_ = 0
				local v906_ = 0
				local v907_ = 0
				local v908_ = 0
				for v909_ = 1, v904_ do
					local v910_ = getChildAt(p892_, v909_ - 1)
					local v911_
					if p893_ == nil then
						v911_ = "" .. v909_ - 1
					else
						v911_ = p893_ .. "|" .. v909_ - 1
					end
					local _ = v909_ - 1
					local v912_ = ".Node"
					local v913_
					if getHasClassId(v910_, ClassIds.SHAPE) then
						v913_ = v906_ + 1
						v912_ = ".Shape"
					elseif getHasClassId(v910_, ClassIds.LIGHT_SOURCE) then
						local v914_ = v907_ + 1
						v913_ = v906_
						v906_ = v907_
						v907_ = v914_
						v912_ = ".Light"
					elseif getHasClassId(v910_, ClassIds.TRANSFORM_GROUP) then
						local v915_ = v908_ + 1
						v913_ = v906_
						v906_ = v908_
						v908_ = v915_
						v912_ = ".TransformGroup"
					else
						local v916_ = v905_ + 1
						v913_ = v906_
						v906_ = v905_
						v905_ = v916_
					end
					v_u_917_(v910_, v911_, v897_ .. v912_, v906_, nil)
					v906_ = v913_
				end
			end
		end
		for v918_, v919_ in ipairs(p_u_887_.components) do
			local v920_ = v919_.node
			local v921_ = v918_ - 1
			v_u_917_(v920_, tostring(v921_) .. ">", "scenegraph.Shape", v918_ - 1, v919_)
		end
		v_u_891_:save()
		v_u_891_:delete()
		local v922_ = getTimeSec()
		Logging.info("Exported \'%s\' in %.1fms", v890_, (v922_ - v888_) * 1000)
	end
	if animationName == nil or animationTime == nil then
		if g_currentMission ~= nil and g_localPlayer ~= nil then
			local v924_ = g_localPlayer:getCurrentVehicle()
			if v924_ == nil then
				Logging.error("Please enter vehicle first!")
			else
				for v925_ = 1, #v924_.childVehicles do
					v_u_923_(v924_.childVehicles[v925_])
				end
			end
		end
	else
		local v_u_926_ = tonumber(animationTime)
		if VehicleDebug.defaultUpdateAnimationFunc == nil then
			VehicleDebug.defaultUpdateAnimationFunc = AnimatedVehicle.updateAnimation
		end
		function AnimatedVehicle.updateAnimation(p927_, p928_, p929_, p930_, p931_, p932_, ...)
			-- upvalues: (copy) animationName, (ref) v_u_926_, (copy) v_u_923_
			VehicleDebug.defaultUpdateAnimationFunc(p927_, p928_, p929_, p930_, p931_, p932_, ...)
			if p928_.name == animationName and (p928_.currentSpeed > 0 and v_u_926_ < p928_.currentTime or p928_.currentSpeed < 0 and p928_.currentTime < v_u_926_) then
				v_u_923_(p927_)
				AnimatedVehicle.updateAnimation = VehicleDebug.defaultUpdateAnimationFunc
				VehicleDebug.defaultUpdateAnimationFunc = nil
			end
		end
	end
end

function VehicleDebug.drawDebugAttacherJoints(vehicle)
	VehicleDebug.currentAttacherJointVehicle = vehicle
end
function VehicleDebug.consoleCommandMergeGroupDebug()
	local function v_u_939_(p934_)
		-- upvalues: (copy) v_u_939_
		if getHasClassId(p934_, ClassIds.SHAPE) then
			local _, v935_ = getShapeIsSkinned(p934_)
			if v935_ then
				if getHasShaderParameter(p934_, "colorScale") then
					local v936_ = VehicleMaterial.new()
					v936_:setTemplateName("plasticPainted")
					v936_:setColor(0, math.random(), math.random())
					v936_:apply(p934_)
				end
			elseif getHasShaderParameter(p934_, "colorScale") then
				local v937_ = VehicleMaterial.new()
				v937_:setTemplateName("plasticPainted")
				v937_:setColor(1, 0, 0)
				v937_:apply(p934_)
			end
		end
		for v938_ = 0, getNumOfChildren(p934_) - 1 do
			v_u_939_(getChildAt(p934_, v938_))
		end
	end
	if g_gui.currentGuiName == "ShopConfigScreen" then
		for _, v940_ in pairs(g_shopConfigScreen.previewVehicles) do
			for _, v941_ in ipairs(v940_.components) do
				v_u_939_(v941_.node)
			end
		end
	end
	if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
		local v942_ = g_localPlayer:getCurrentVehicle()
		for v943_ = 1, #v942_.childVehicles do
			for _, v944_ in ipairs(v942_.childVehicles[v943_].components) do
				v_u_939_(v944_.node)
			end
		end
	end
end
function VehicleDebug.consoleCommandCastShadow()
	local function v_u_949_(p945_)
		-- upvalues: (copy) v_u_949_
		if getHasClassId(p945_, ClassIds.SHAPE) then
			local v946_ = getMaterial(p945_, 0)
			if v946_ ~= 0 and string.contains(getMaterialCustomShaderFilename(v946_), "vehicleShader.xml") then
				local v947_ = VehicleMaterial.new()
				v947_:setTemplateName("plasticPainted")
				v947_:setColor(0, 0, 0)
				if getShapeCastShadowmap(p945_) then
					v947_:setColor(1, 1, 1)
				end
				v947_.diffuseMap = "data/shared/white_diffuse.dds"
				v947_:apply(p945_)
			end
		end
		for v948_ = 0, getNumOfChildren(p945_) - 1 do
			v_u_949_(getChildAt(p945_, v948_))
		end
	end
	if g_gui.currentGuiName == "ShopConfigScreen" then
		for _, v950_ in pairs(g_shopConfigScreen.previewVehicles) do
			for _, v951_ in ipairs(v950_.components) do
				v_u_949_(v951_.node)
			end
		end
	end
	if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
		local v952_ = g_localPlayer:getCurrentVehicle()
		for v953_ = 1, #v952_.childVehicles do
			for _, v954_ in ipairs(v952_.childVehicles[v953_].components) do
				v_u_949_(v954_.node)
			end
		end
	end
end
function VehicleDebug.consoleCommandDecalLayer()
	local function v_u_959_(p955_)
		-- upvalues: (copy) v_u_959_
		if getHasClassId(p955_, ClassIds.SHAPE) then
			local v956_ = getShapeDecalLayer(p955_)
			local v957_ = VehicleMaterial.new()
			v957_:setTemplateName("plasticPainted")
			v957_:setColor(1, 1, 1)
			if v956_ == 1 then
				v957_:setColor(1, 0, 0)
			elseif v956_ == 2 then
				v957_:setColor(0, 1, 0)
			elseif v956_ > 2 then
				v957_:setColor(0, 0, 1)
			end
			v957_.diffuseMap = "data/shared/white_diffuse.dds"
			v957_:apply(p955_)
		end
		for v958_ = 0, getNumOfChildren(p955_) - 1 do
			v_u_959_(getChildAt(p955_, v958_))
		end
	end
	if g_gui.currentGuiName == "ShopConfigScreen" then
		for _, v960_ in pairs(g_shopConfigScreen.previewVehicles) do
			for _, v961_ in ipairs(v960_.components) do
				v_u_959_(v961_.node)
			end
		end
	end
	if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
		local v962_ = g_localPlayer:getCurrentVehicle()
		for v963_ = 1, #v962_.childVehicles do
			for _, v964_ in ipairs(v962_.childVehicles[v963_].components) do
				v_u_959_(v964_.node)
			end
		end
	end
end

-- Local values: materialTemplate, targetMaterial, visualizeMaterialRec, _, loadedVehicle, _, component, vehicle, i, _, component
function VehicleDebug.consoleCommandDebugMaterial(_, materialTemplateName)
	if g_vehicleMaterialManager:getMaterialTemplateByName(materialTemplateName) == nil then
		Logging.error("Material template \'%s\' not found", materialTemplateName)
	else
		local v_u_966_ = VehicleMaterial.new()
		v_u_966_:setTemplateName(materialTemplateName)
		local function v_u_972_(p967_)
			-- upvalues: (copy) v_u_966_, (copy) v_u_972_
			if getHasClassId(p967_, ClassIds.SHAPE) then
				for v968_ = 1, getNumOfMaterials(p967_) do
					if v_u_966_:getIsApplied(p967_, getMaterial(p967_, v968_ - 1), false) then
						local v969_ = VehicleMaterial.new()
						v969_:setTemplateName("plasticPainted")
						v969_:setColor(0, 1, 0)
						v969_:applyToMaterial(p967_, v968_ - 1)
					else
						local v970_ = VehicleMaterial.new()
						v970_:setTemplateName("plasticPainted")
						v970_:setColor(1, 0, 0)
						v970_:applyToMaterial(p967_, v968_ - 1)
					end
				end
			end
			for v971_ = 0, getNumOfChildren(p967_) - 1 do
				v_u_972_(getChildAt(p967_, v971_))
			end
		end
		if g_gui.currentGuiName == "ShopConfigScreen" then
			for _, v973_ in pairs(g_shopConfigScreen.previewVehicles) do
				for _, v974_ in ipairs(v973_.components) do
					v_u_972_(v974_.node)
				end
			end
		end
		if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
			local v975_ = g_localPlayer:getCurrentVehicle()
			for v976_ = 1, #v975_.childVehicles do
				for _, v977_ in ipairs(v975_.childVehicles[v976_].components) do
					v_u_972_(v977_.node)
				end
			end
		end
	end
end

-- Local values: vehicle, i, childVehicle, str, index, attacherJointDesc, attacherJointDesc, j, node, j, node
function VehicleDebug.consoleCommandAttacherJointConnections(_, attacherJointIndex)
	local v979_ = tonumber(attacherJointIndex) or 1
	if VehicleDebug.DEBUG_ATTACHER_JOINT_INDEX == v979_ then
		Logging.info("Disconnect from attacher joint \'%s\'", v979_)
		VehicleDebug.DEBUG_ATTACHER_JOINT_INDEX = nil
		v979_ = nil
	else
		Logging.info("Connect to attacher joint \'%s\'", v979_)
		VehicleDebug.DEBUG_ATTACHER_JOINT_INDEX = v979_
	end
	if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
		local v980_ = g_localPlayer:getCurrentVehicle()
		for v981_ = 1, #v980_.childVehicles do
			local v982_ = v980_.childVehicles[v981_]
			if v982_.getAttacherJoints ~= nil then
				local v983_ = ""
				for v984_, v985_ in ipairs(v982_:getAttacherJoints()) do
					v983_ = v983_ .. string.format("%d-%s  ", v984_, getName(v985_.jointTransform))
					ObjectChangeUtil.setObjectChanges(v985_.changeObjects, false, v982_, v982_.setMovingToolDirty)
				end
				if v983_ ~= "" then
					Logging.info(v982_:getFullName() .. ": " .. v983_)
				end
			end
			if v982_.jointIndexDebugText ~= nil then
				g_debugManager:removeElement(v982_.jointIndexDebugText)
				v982_.jointIndexDebugText = nil
			end
			if v982_.steeringBarLeftDebugText ~= nil then
				g_debugManager:removeElement(v982_.steeringBarLeftDebugText)
				v982_.steeringBarLeftDebugText = nil
			end
			if v982_.steeringBarRightDebugText ~= nil then
				g_debugManager:removeElement(v982_.steeringBarRightDebugText)
				v982_.steeringBarRightDebugText = nil
			end
			local v986_ = v982_:getAttacherJointByJointDescIndex(v979_)
			if v986_ ~= nil then
				v982_.jointIndexDebugText = DebugGizmo.new():createWithNode(v986_.jointTransform, "j" .. tostring(v979_), nil, nil, 0.1, true)
				g_debugManager:addElement(v982_.jointIndexDebugText, nil, nil, math.huge)
				if v986_.steeringBarLeftNode ~= nil then
					v982_.steeringBarLeftDebugText = DebugGizmo.new():createWithNode(v986_.steeringBarLeftNode, "sl", nil, nil, 0.1, true)
					g_debugManager:addElement(v982_.steeringBarLeftDebugText, nil, nil, math.huge)
				end
				if v986_.steeringBarRightNode ~= nil then
					v982_.steeringBarRightDebugText = DebugGizmo.new():createWithNode(v986_.steeringBarRightNode, "sr", nil, nil, 0.1, true)
					g_debugManager:addElement(v982_.steeringBarRightDebugText, nil, nil, math.huge)
				end
				ObjectChangeUtil.setObjectChanges(v986_.changeObjects, true, v982_, v982_.setMovingToolDirty)
				for v987_ = 1, #v986_.visualNodes do
					local v988_ = v986_.visualNodes[v987_]
					setVisibility(v988_, true)
				end
				for v989_ = 1, #v986_.hideVisuals do
					local v990_ = v986_.hideVisuals[v989_]
					setVisibility(v990_, false)
				end
			end
			ConnectionHoses.consoleCommandTestSockets(v982_, v979_)
			PowerTakeOffs.consoleCommandTestConnection(v982_, v979_)
		end
	end
end

-- Local values: vehicle, i, childVehicle
function VehicleDebug.consoleCommandToolConnections(_, toolConnectionIndex)
	local v992_ = tonumber(toolConnectionIndex) or 1
	if VehicleDebug.DEBUG_TOOL_CONNECTION_INDEX == v992_ then
		Logging.info("Disconnect from tool connection \'%s\'", v992_)
		VehicleDebug.DEBUG_TOOL_CONNECTION_INDEX = nil
	else
		Logging.info("Connect to tool connection \'%s\'", v992_)
		VehicleDebug.DEBUG_TOOL_CONNECTION_INDEX = v992_
	end
	if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
		local v993_ = g_localPlayer:getCurrentVehicle()
		for v994_ = 1, #v993_.childVehicles do
			local v995_ = v993_.childVehicles[v994_]
			ConnectionHoses.consoleCommandTestToolConnection(v995_, VehicleDebug.DEBUG_TOOL_CONNECTION_INDEX)
		end
	end
end
function VehicleDebug.consoleCommandWheelDisplacement()
	if WheelPhysics.COLLISION_MASK == CollisionMask.ALL then
		WheelPhysics.COLLISION_MASK = CollisionMask.ALL - CollisionFlag.TERRAIN_DISPLACEMENT
		Logging.info("Disabled wheel interaction with displacement collision")
	else
		WheelPhysics.COLLISION_MASK = CollisionMask.ALL
		Logging.info("Enabled wheel interaction with displacement collision")
	end
	for _, v996_ in pairs(g_currentMission.vehicleSystem.vehicles) do
		if v996_.getWheels ~= nil then
			for _, v997_ in ipairs(v996_:getWheels()) do
				v997_.physics:updateBase()
			end
		end
	end
end
VehicleDebug.cylinderedUpdateDebugState = false
function VehicleDebug.consoleCommandCylinderedUpdate()
	VehicleDebug.cylinderedUpdateDebugState = not VehicleDebug.cylinderedUpdateDebugState
	local v998_ = print
	local v999_ = VehicleDebug.cylinderedUpdateDebugState
	v998_("Cylindered Update Debug: " .. tostring(v999_))
end
VehicleDebug.wetnessDebugState = false
function VehicleDebug.consoleCommandWetnessDebug()
	VehicleDebug.wetnessDebugState = not VehicleDebug.wetnessDebugState
	local v1000_ = print
	local v1001_ = VehicleDebug.wetnessDebugState
	v1000_("Wetness Debug: " .. tostring(v1001_))
	local function v_u_1014_(p1002_)
		local v1003_ = g_debugManager:getDebugMat()
		local v1004_ = setMaterialCustomShaderVariation(v1003_, "wetnessDebug", false)
		local v_u_1005_ = setMaterialDiffuseMapFromFile(v1004_, "data/shared/default_diffuse.dds", true, true, false)
		local function v_u_1012_(p1006_, p1007_)
			-- upvalues: (ref) v_u_1005_, (copy) v_u_1012_
			if p1006_.spec_washable == nil or p1006_.spec_washable.wetnessIgnoreNodes[p1007_] ~= true then
				if getHasClassId(p1007_, ClassIds.SHAPE) then
					for v1008_ = 1, getNumOfMaterials(p1007_) do
						local v1009_ = getMaterial(p1007_, v1008_ - 1)
						local v1010_ = getMaterialCustomShaderFilename(v1009_)
						if string.contains(v1010_, "vehicleShader.xml") then
							setMaterial(p1007_, v_u_1005_, v1008_ - 1)
							setShaderParameter(p1007_, "alpha", 1, 0, 0, 0, false, v1008_ - 1)
						end
					end
				end
				for v1011_ = 0, getNumOfChildren(p1007_) - 1 do
					v_u_1012_(p1006_, getChildAt(p1007_, v1011_))
				end
			end
		end
		for _, v1013_ in ipairs(p1002_.components) do
			v_u_1012_(p1002_, v1013_.node)
		end
	end
	if VehicleDebug.wetnessDebugState then
		if g_gui.currentGuiName == "ShopConfigScreen" then
			for _, v1015_ in pairs(g_shopConfigScreen.previewVehicles) do
				v_u_1014_(v1015_)
			end
		elseif g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
			local v1016_ = g_localPlayer:getCurrentVehicle()
			for v1017_ = 1, #v1016_.childVehicles do
				v_u_1014_(v1016_.childVehicles[v1017_])
			end
		end
		VehicleDebug.vehicleOnFinishedLoading = Vehicle.onFinishedLoading
		function Vehicle.onFinishedLoading(p1018_, ...)
			-- upvalues: (copy) v_u_1014_
			v_u_1014_(p1018_)
			VehicleDebug.vehicleOnFinishedLoading(p1018_, ...)
		end
	else
		if VehicleDebug.vehicleOnFinishedLoading ~= nil then
			Vehicle.onFinishedLoading = VehicleDebug.vehicleOnFinishedLoading
			VehicleDebug.vehicleOnFinishedLoading = nil
		end
		executeConsoleCommand("gsVehicleReload")
	end
end
VehicleDebug.wheelEffectDebugState = false
function VehicleDebug.consoleCommandWheelEffectsDebug()
	VehicleDebug.wheelEffectDebugState = not VehicleDebug.wheelEffectDebugState
	print("Wheel Effects Debug: " .. (VehicleDebug.wheelEffectDebugState and "Enabled" or "Disabled"))
end
function VehicleDebug.consoleCommandAutomaticMotorStart()
	local v1019_ = g_currentMission
	if v1019_.missionInfo.automaticMotorStartEnabled then
		v1019_:setAutomaticMotorStartEnabled(false, true)
		print("Automatic Motor Start: Disabled")
		if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
			local v1020_ = g_localPlayer:getCurrentVehicle()
			for _, v1021_ in ipairs(v1020_.childVehicles) do
				if v1021_.setMotorState ~= nil then
					v1021_:setMotorState(MotorState.OFF)
				end
			end
			return
		end
	else
		v1019_:setAutomaticMotorStartEnabled(true, true)
		print("Automatic Motor Start: Enabled")
	end
end
function VehicleDebug.consoleCommandCameraReset()
	if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
		local v1022_ = g_localPlayer:getCurrentVehicle()
		for _, v1023_ in ipairs(v1022_.childVehicles) do
			if v1023_.getActiveCamera ~= nil then
				local v1024_ = v1023_:getActiveCamera()
				if v1024_ ~= nil then
					v1024_:resetCamera()
				end
			end
		end
	end
end
addConsoleCommand("gsVehicleAnalyze", "Analyze vehicle", "VehicleDebug.consoleCommandAnalyze", nil)
addConsoleCommand("gsVehicleDebug", "Toggles the vehicle debug values rendering", "VehicleDebug.consoleCommandVehicleDebug", nil)
addConsoleCommand("gsVehicleExportScenegraph", "Exports the vehicle scenegraph to a xml file", "VehicleDebug.consoleCommandExportScenegraph", nil)
addConsoleCommand("gsVehicleDebugMergeGroups", "Visualizes all merge groups", "VehicleDebug.consoleCommandMergeGroupDebug", nil)
addConsoleCommand("gsVehicleDebugCastShadow", "Visualizes all shapes that cast shadows", "VehicleDebug.consoleCommandCastShadow", nil)
addConsoleCommand("gsVehicleDebugDecalLayer", "Visualizes all shapes with decal layer", "VehicleDebug.consoleCommandDecalLayer", nil)
addConsoleCommand("gsVehicleDebugMaterial", "Visualizes all shapes that got the given material template assigned", "VehicleDebug.consoleCommandDebugMaterial", nil, "materialTemplateName")
addConsoleCommand("gsVehicleDebugAttacherJointConnections", "Visualization of the connection hoses and power take offs per attacher joint", "VehicleDebug.consoleCommandAttacherJointConnections", nil, "jointIndex")
addConsoleCommand("gsVehicleDebugToolConnections", "Visualization of the tool connection hoses", "VehicleDebug.consoleCommandToolConnections", nil, "toolConnectionIndex")
addConsoleCommand("gsVehicleDebugToggleWheelDisplacement", "Toggles the interaction of the wheels with the displacement", "VehicleDebug.consoleCommandWheelDisplacement", nil)
addConsoleCommand("gsVehicleDebugCylinderedUpdateDebug", "Shows the name of each movingPart or movingTool that is updated", "VehicleDebug.consoleCommandCylinderedUpdate", nil)
addConsoleCommand("gsVehicleDebugWetness", "Visualizes the wetness masking of the vehicle", "VehicleDebug.consoleCommandWetnessDebug", nil)
addConsoleCommand("gsVehicleDebugWheelEffects", "Enabled the wheel effects all the time", "VehicleDebug.consoleCommandWheelEffectsDebug", nil)
addConsoleCommand("gsVehicleDebugMotorStart", "Enabled or disable automatic motor start setting via console command", "VehicleDebug.consoleCommandAutomaticMotorStart", nil)
addConsoleCommand("gsVehicleDebugCameraReset", "Resets the vehicle camera to default state", "VehicleDebug.consoleCommandCameraReset", nil)
if StartParams.getIsSet("vehicleDebugMode") then
	VehicleDebug.consoleCommandVehicleDebug(nil, StartParams.getValue("vehicleDebugMode"))
end
