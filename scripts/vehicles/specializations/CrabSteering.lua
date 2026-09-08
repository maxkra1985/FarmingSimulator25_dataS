source("dataS/scripts/vehicles/specializations/events/SetCrabSteeringEvent.lua")
CrabSteering = {}
source("dataS/scripts/gui/hud/extensions/CrabSteeringHUDExtension.lua")
CrabSteering.STEERING_SEND_NUM_BITS = 3

function CrabSteering.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(Drivable, specializations) and SpecializationUtil.hasSpecialization(Wheels, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
	end
	return v2_
end
function CrabSteering.initSpecialization()
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("CrabSteering")
	v3_:register(XMLValueType.FLOAT, "vehicle.crabSteering#distFromCompJointToCenterOfBackWheels", "Distance from component joint to center of back wheels")
	v3_:register(XMLValueType.FLOAT, "vehicle.crabSteering#aiSteeringModeIndex", "AI steering mode index", 1)
	v3_:register(XMLValueType.FLOAT, "vehicle.crabSteering#toggleSpeedFactor", "Toggle speed factor", 1)
	CrabSteering.registerSteeringModeXMLPaths(v3_, "vehicle.crabSteering.steeringMode(?)")
	CrabSteering.registerSteeringModeXMLPaths(v3_, "vehicle.crabSteering.crabSteeringConfiguration(?).steeringMode(?)")
	Dashboard.registerDashboardXMLPaths(v3_, "vehicle.crabSteering.dashboards", { "state" })
	Dashboard.addDelayedRegistrationFunc(v3_, function(p4_, p5_)
		p4_:register(XMLValueType.VECTOR_N, p5_ .. "#states", "Crab steering states which activate the dashboard")
	end)
	v3_:register(XMLValueType.INT, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).wheels#crabSteeringIndex", "Crab steering configuration index")
	v3_:setXMLSpecializationType()
	Vehicle.xmlSchemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).crabSteering#state", "Current steering mode", 1)
end

function CrabSteering.registerSteeringModeXMLPaths(schema, basePath)
	schema:addDelayedRegistrationPath(basePath, "CrabSteering:steeringMode")
	schema:register(XMLValueType.L10N_STRING, basePath .. "#name", "Steering mode name")
	schema:register(XMLValueType.STRING, basePath .. "#inputBindingName", "Input action name")
	schema:register(XMLValueType.INT, basePath .. ".wheel(?)#index", "Wheel Index")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".wheel(?)#node", "Wheel Node")
	schema:register(XMLValueType.ANGLE, basePath .. ".wheel(?)#offset", "Rotation offset", 0)
	schema:register(XMLValueType.BOOL, basePath .. ".wheel(?)#locked", "Steering is locked", false)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".steeringCenter#node", "Custom steering center node")
	schema:register(XMLValueType.FLOAT, basePath .. ".steeringCenter#turningRadius", "Turning radius to use with custom steering node")
	schema:register(XMLValueType.FLOAT, basePath .. ".aiAutomaticSteering#lookAheadDistance", "Distance for aiming onto the wayline when this steering mode is active")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".steeringNode(?)#node", "Steering node")
	schema:register(XMLValueType.ANGLE, basePath .. ".steeringNode(?)#offset", "Rotation offset", 0)
	schema:register(XMLValueType.BOOL, basePath .. ".steeringNode(?)#locked", "Steering is locked", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".steeringNode(?)#rotScale", "Scale of rotation")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".node(?)#node", "Node to adjust when the steering mode is active")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".node(?)#rotation", "Rotation when steering mode is active")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".node(?)#translation", "Translation when steering mode is active")
	schema:register(XMLValueType.ANGLE, basePath .. ".articulatedAxis#offset", "Articulated axis offset angle", 0)
	schema:register(XMLValueType.BOOL, basePath .. ".articulatedAxis#locked", "Articulated axis is locked", false)
	schema:register(XMLValueType.VECTOR_N, basePath .. ".articulatedAxis#wheelIndices", "Wheel indices")
	schema:register(XMLValueType.STRING, basePath .. ".animation(?)#name", "Change animation name")
	schema:register(XMLValueType.FLOAT, basePath .. ".animation(?)#speed", "Animation speed", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".animation(?)#stopTime", "Animation stop time")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".steeringWheel#node", "Steering wheel node")
	schema:register(XMLValueType.ANGLE, basePath .. ".steeringWheel#indoorRotation", "Steering wheel indoor rotation", 0)
	schema:register(XMLValueType.ANGLE, basePath .. ".steeringWheel#outdoorRotation", "Steering wheel outdoor rotation", 0)
end

function CrabSteering.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadCrabSteeringModeFromXML", CrabSteering.loadCrabSteeringModeFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getCanToggleCrabSteering", CrabSteering.getCanToggleCrabSteering)
	SpecializationUtil.registerFunction(vehicleType, "getCrabSteeringModeAvailable", CrabSteering.getCrabSteeringModeAvailable)
	SpecializationUtil.registerFunction(vehicleType, "getNumCrabSteeringModesAvailable", CrabSteering.getNumCrabSteeringModesAvailable)
	SpecializationUtil.registerFunction(vehicleType, "setCrabSteering", CrabSteering.setCrabSteering)
	SpecializationUtil.registerFunction(vehicleType, "getCrabSteeringMode", CrabSteering.getCrabSteeringMode)
	SpecializationUtil.registerFunction(vehicleType, "setNextCrabSteeringMode", CrabSteering.setNextCrabSteeringMode)
	SpecializationUtil.registerFunction(vehicleType, "updateArticulatedAxisRotation", CrabSteering.updateArticulatedAxisRotation)
end

function CrabSteering.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWheelFromXML", CrabSteering.loadWheelFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateSteeringAngle", CrabSteering.updateSteeringAngle)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", CrabSteering.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWheelsFromXML", CrabSteering.loadWheelsFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateSteeringWheel", CrabSteering.updateSteeringWheel)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "startFieldWorker", CrabSteering.startFieldWorker)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIAutomaticSteeringLookAheadDistance", CrabSteering.getAIAutomaticSteeringLookAheadDistance)
end

function CrabSteering.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", CrabSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", CrabSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", CrabSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", CrabSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", CrabSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", CrabSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", CrabSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", CrabSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", CrabSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", CrabSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", CrabSteering)
end

-- Local values: spec, baseKey, configKey, _, key, mode
function CrabSteering:onLoad(savegame)
	local v12_ = self.spec_crabSteering
	v12_.state = 1
	v12_.stateMax = -1
	v12_.configurationIndex = v12_.configurationIndex or 1
	v12_.distFromCompJointToCenterOfBackWheels = self.xmlFile:getValue("vehicle.crabSteering#distFromCompJointToCenterOfBackWheels")
	v12_.aiSteeringModeIndex = self.xmlFile:getValue("vehicle.crabSteering#aiSteeringModeIndex", 1)
	v12_.toggleSpeedFactor = self.xmlFile:getValue("vehicle.crabSteering#toggleSpeedFactor", 1)
	v12_.currentArticulatedAxisOffset = 0
	v12_.articulatedAxisOffsetChanged = false
	v12_.articulatedAxisLastAngle = 0
	v12_.articulatedAxisChangingTime = 0
	local v13_ = string.format("vehicle.crabSteering.crabSteeringConfiguration(%d)", v12_.configurationIndex - 1)
	local v14_ = not self.xmlFile:hasProperty(v13_) and "vehicle.crabSteering" or v13_
	v12_.steeringModes = {}
	for _, v15_ in self.xmlFile:iterator(v14_ .. ".steeringMode") do
		local v16_ = {}
		if self:loadCrabSteeringModeFromXML(self.xmlFile, v15_, v16_) then
			local v17_ = v12_.steeringModes
			table.insert(v17_, v16_)
			v16_.index = #v12_.steeringModes
		end
	end
	v12_.stateMax = #v12_.steeringModes
	if v12_.stateMax > 2 ^ CrabSteering.STEERING_SEND_NUM_BITS - 1 then
		Logging.xmlError(self.xmlFile, "CrabSteering only supports %d steering modes!", 2 ^ CrabSteering.STEERING_SEND_NUM_BITS - 1)
	end
	v12_.hasSteeringModes = v12_.stateMax > 0
	if v12_.hasSteeringModes then
		self.customSteeringAngleFunction = true
		v12_.hudExtension = CrabSteeringHUDExtension.new(self)
		self:setCrabSteering(1, true)
	else
		SpecializationUtil.removeEventListener(self, "onReadStream", CrabSteering)
		SpecializationUtil.removeEventListener(self, "onWriteStream", CrabSteering)
		SpecializationUtil.removeEventListener(self, "onReadUpdateStream", CrabSteering)
		SpecializationUtil.removeEventListener(self, "onWriteUpdateStream", CrabSteering)
		SpecializationUtil.removeEventListener(self, "onUpdateTick", CrabSteering)
		SpecializationUtil.removeEventListener(self, "onDraw", CrabSteering)
		SpecializationUtil.removeEventListener(self, "onAIImplementStart", CrabSteering)
		SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", CrabSteering)
	end
end

-- Local values: spec, state
function CrabSteering:onPostLoad(savegame)
	if savegame ~= nil and not savegame.resetVehicles then
		local v20_ = self.spec_crabSteering
		if v20_.hasSteeringModes and savegame.xmlFile:hasProperty(savegame.key .. ".crabSteering") then
			local v21_ = savegame.xmlFile:getValue(savegame.key .. ".crabSteering#state", 1)
			local v22_ = v20_.stateMax
			self:setCrabSteering(math.clamp(v21_, 1, v22_), true)
			AnimatedVehicle.updateAnimations(self, 99999999, true)
			self:forceUpdateWheelPhysics(99999999)
		end
	end
end

-- Local values: spec
function CrabSteering:onDelete()
	local v24_ = self.spec_crabSteering
	if v24_.hudExtension ~= nil then
		v24_.hudExtension:delete()
	end
end

-- Local values: spec, state
function CrabSteering:onRegisterDashboardValueTypes()
	local v_u_26_ = self.spec_crabSteering
	local v27_ = DashboardValueType.new("crabSteering", "state")
	v27_:setValue(v_u_26_, function(_, p28_)
		-- upvalues: (copy) v_u_26_
		if p28_.crabSteeringStates == nil then
			return v_u_26_.state
		end
		local v29_ = false
		for _, v30_ in pairs(p28_.crabSteeringStates) do
			if v_u_26_.state == v30_ then
				v29_ = true
			end
		end
		return v29_
	end)
	v27_:setAdditionalFunctions(function(_, p31_, p32_, p33_, _)
		p33_.crabSteeringStates = p31_:getValue(p32_ .. "#states", nil, true)
		return true
	end)
	v27_:setPollUpdate(false)
	self:registerDashboardValueType(v27_)
end

-- Local values: spec
function CrabSteering:saveToXMLFile(xmlFile, key, usedModNames)
	local v37_ = self.spec_crabSteering
	if v37_.hasSteeringModes then
		xmlFile:setValue(key .. "#state", v37_.state)
	end
end

-- Local values: state
function CrabSteering:onReadStream(streamId, connection)
	self:setCrabSteering(streamReadUIntN(streamId, CrabSteering.STEERING_SEND_NUM_BITS), true)
	AnimatedVehicle.updateAnimations(self, 99999999, true)
	self:forceUpdateWheelPhysics(99999999)
end

-- Local values: spec
function CrabSteering:onWriteStream(streamId, connection)
	local v42_ = self.spec_crabSteering
	streamWriteUIntN(streamId, v42_.state, CrabSteering.STEERING_SEND_NUM_BITS)
end

-- Local values: specArticulatedAxis
function CrabSteering:onReadUpdateStream(streamId, timestamp, connection)
	local v45_ = self.spec_articulatedAxis
	if v45_ ~= nil and v45_.componentJoint ~= nil then
		v45_.curRot = streamReadFloat32(streamId)
	end
end

-- Local values: specArticulatedAxis
function CrabSteering:onWriteUpdateStream(streamId, connection, dirtyMask)
	local v48_ = self.spec_articulatedAxis
	if v48_ ~= nil and v48_.componentJoint ~= nil then
		streamWriteFloat32(streamId, v48_.curRot)
	end
end

-- Local values: spec
function CrabSteering:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isServer then
		local v50_ = self.spec_crabSteering
		if not self:getCrabSteeringModeAvailable(v50_.steeringModes[v50_.state]) then
			self:setNextCrabSteeringMode(1)
		end
	end
end

-- Local values: spec, hud
function CrabSteering:onDraw()
	local v52_ = self.spec_crabSteering
	if v52_.hudExtension ~= nil then
		g_currentMission.hud:addHelpExtension(v52_.hudExtension)
	end
end

-- Local values: inputBindingName, _, wheelKey, wheelEntry, wheel, _, steeringNodeKey, steeringNodeEntry, steeringNode, _, nodeKey, nodeEntry, specArticulatedAxis, _, animKey, animation, node, _, ry, _
function CrabSteering:loadCrabSteeringModeFromXML(xmlFile, key, mode)
	mode.name = self.xmlFile:getValue(key .. "#name", "", self.customEnvironment, false)
	local v56_ = self.xmlFile:getValue(key .. "#inputBindingName")
	if v56_ ~= nil then
		if InputAction[v56_] == nil then
			Logging.xmlWarning(self.xmlFile, "Invalid inputBindingname \'%s\' for \'%s\'", tostring(v56_), key)
		else
			mode.inputAction = InputAction[v56_]
		end
	end
	mode.steeringCenterNode = self.xmlFile:getValue(key .. ".steeringCenter#node", nil, self.components, self.i3dMappings)
	mode.turningRadius = self.xmlFile:getValue(key .. ".steeringCenter#turningRadius")
	mode.automaticSteeringLookAheadDistance = self.xmlFile:getValue(key .. ".aiAutomaticSteering#lookAheadDistance")
	mode.wheels = {}
	for _, v57_ in self.xmlFile:iterator(key .. ".wheel") do
		local v58_ = {
			["wheelIndex"] = self.xmlFile:getValue(v57_ .. "#index"),
			["wheelNode"] = self.xmlFile:getValue(v57_ .. "#node", nil, self.components, self.i3dMappings)
		}
		if v58_.wheelNode == nil then
			::l8::
			v58_.offset = self.xmlFile:getValue(v57_ .. "#offset", 0)
			v58_.locked = self.xmlFile:getValue(v57_ .. "#locked", false)
			if v58_.wheelIndex == nil then
				::l15::
				local v59_ = mode.wheels
				table.insert(v59_, v58_)
			else
				v58_.wheel = self:getWheelFromWheelIndex(v58_.wheelIndex)
				if v58_.wheel ~= nil then
					goto l15
				end
				local v60_ = Logging.xmlError
				local v61_ = self.xmlFile
				local v62_ = v58_.wheelIndex
				v60_(v61_, "Invalid wheel \'%s\' for \'%s\'", tostring(v62_), v57_)
			end
		else
			local v63_ = self:getWheelByWheelNode(v58_.wheelNode)
			if v63_ == nil then
				Logging.xmlError(self.xmlFile, "Invalid wheel node \'%s\' for \'%s\'", self.xmlFile:getString(v57_ .. "#node"), v57_)
			else
				if v63_.physics.rotSpeed ~= 0 then
					v58_.wheelIndex = v63_.wheelIndex
					v58_.wheel = v63_
					goto l8
				end
				Logging.xmlError(self.xmlFile, "Invalid wheel node \'%s\' for \'%s\'. Wheel needs to have a rotSpeed defined!", self.xmlFile:getString(v57_ .. "#node"), v57_)
			end
		end
	end
	mode.steeringNodes = {}
	for _, v64_ in self.xmlFile:iterator(key .. ".steeringNode") do
		local v65_ = {
			["node"] = self.xmlFile:getValue(v64_ .. "#node", nil, self.components, self.i3dMappings)
		}
		if v65_.node ~= nil then
			local v66_ = self:getSteeringNodeByNode(v65_.node)
			if v66_ == nil then
				Logging.xmlError(self.xmlFile, "Invalid steering node \'%s\' for \'%s\'", getName(v65_.node), v64_)
			else
				v65_.steeringNode = v66_
				v65_.offset = self.xmlFile:getValue(v64_ .. "#offset", 0)
				v65_.locked = self.xmlFile:getValue(v64_ .. "#locked", false)
				v65_.rotScale = self.xmlFile:getValue(v64_ .. "#rotScale")
				local v67_ = mode.steeringNodes
				table.insert(v67_, v65_)
			end
		end
	end
	mode.nodes = {}
	for _, v68_ in self.xmlFile:iterator(key .. ".node") do
		local v69_ = {
			["node"] = self.xmlFile:getValue(v68_ .. "#node", nil, self.components, self.i3dMappings)
		}
		if v69_.node ~= nil then
			v69_.rotation = self.xmlFile:getValue(v68_ .. "#rotation", nil, true)
			v69_.translation = self.xmlFile:getValue(v68_ .. "#translation", nil, true)
			local v70_ = mode.nodes
			table.insert(v70_, v69_)
		end
	end
	local v71_ = self.spec_articulatedAxis
	if v71_ ~= nil and v71_.componentJoint ~= nil then
		mode.articulatedAxis = {}
		mode.articulatedAxis.rotSpeedBackUp = v71_.rotSpeed
		mode.articulatedAxis.offset = self.xmlFile:getValue(key .. ".articulatedAxis#offset", 0)
		mode.articulatedAxis.locked = self.xmlFile:getValue(key .. ".articulatedAxis#locked", false)
		mode.articulatedAxis.wheelIndices = self.xmlFile:getValue(key .. ".articulatedAxis#wheelIndices", nil, true)
	end
	mode.animations = {}
	for _, v72_ in self.xmlFile:iterator(key .. ".animation") do
		local v73_ = {
			["animName"] = self.xmlFile:getValue(v72_ .. "#name"),
			["animSpeed"] = self.xmlFile:getValue(v72_ .. "#speed", 1),
			["stopTime"] = self.xmlFile:getValue(v72_ .. "#stopTime")
		}
		if v73_.animName == nil or not self:getAnimationExists(v73_.animName) then
			local v74_ = Logging.xmlWarning
			local v75_ = self.xmlFile
			local v76_ = v73_.animName
			v74_(v75_, "Invalid animation \'%s\' for \'%s\'", tostring(v76_), v72_)
		else
			local v77_ = mode.animations
			table.insert(v77_, v73_)
		end
	end
	local v78_ = self.xmlFile:getValue(key .. ".steeringWheel#node", nil, self.components, self.i3dMappings)
	if v78_ ~= nil then
		mode.steeringWheel = {}
		mode.steeringWheel.node = v78_
		local _, v79_, _ = getRotation(mode.steeringWheel.node)
		mode.steeringWheel.lastRotation = v79_
		mode.steeringWheel.indoorRotation = self.xmlFile:getValue(key .. ".steeringWheel#indoorRotation", 0)
		mode.steeringWheel.outdoorRotation = self.xmlFile:getValue(key .. ".steeringWheel#outdoorRotation", 0)
	end
	return true
end

function CrabSteering:getCanToggleCrabSteering()
	return true, nil
end

function CrabSteering:getCrabSteeringModeAvailable(mode)
	return true
end

-- Local values: spec, numModes, k, mode
function CrabSteering:getNumCrabSteeringModesAvailable()
	local v81_ = self.spec_crabSteering
	local v82_ = 0
	for _, v83_ in ipairs(v81_.steeringModes) do
		if self:getCrabSteeringModeAvailable(v83_) then
			v82_ = v82_ + 1
		end
	end
	return v82_
end

-- Local values: spec, currentMode, _, anim, curTime, newMode, _, anim, curTime, speed, _, steeringNodeData, steeringNode, rotMin, rotMax, inverted, _, wheelProperties, _, node
function CrabSteering:setCrabSteering(state, noEventSend)
	local v87_ = self.spec_crabSteering
	if noEventSend == nil or noEventSend == false then
		if g_server == nil then
			g_client:getServerConnection():sendEvent(SetCrabSteeringEvent.new(self, state))
		else
			g_server:broadcastEvent(SetCrabSteeringEvent.new(self, state), nil, nil, self)
		end
	end
	if state ~= v87_.state then
		local v88_ = v87_.steeringModes[v87_.state]
		if v88_.animations ~= nil then
			for _, v89_ in pairs(v88_.animations) do
				local v90_ = self:getAnimationTime(v89_.animName)
				if v89_.stopTime == nil then
					self:playAnimation(v89_.animName, -v89_.animSpeed, v90_, noEventSend)
				end
			end
		end
		local v91_ = v87_.steeringModes[state]
		if v91_.animations ~= nil then
			for _, v92_ in pairs(v91_.animations) do
				local v93_ = self:getAnimationTime(v92_.animName)
				if v92_.stopTime == nil then
					self:playAnimation(v92_.animName, v92_.animSpeed, v93_, noEventSend)
				else
					self:setAnimationStopTime(v92_.animName, v92_.stopTime)
					local v94_ = v92_.stopTime < v93_ and -1 or 1
					self:playAnimation(v92_.animName, v94_, v93_, noEventSend)
				end
			end
		end
		for _, v95_ in pairs(v91_.steeringNodes) do
			local v96_ = v95_.steeringNode
			v96_.offsetTarget = v95_.offset
			local v97_ = v96_.offsetTarget - v96_.offset
			v96_.offsetTargetSpeed = math.abs(v97_) / (1 / v87_.toggleSpeedFactor * 1000)
			if v95_.locked then
				v96_.rotScaleTarget = 0
			else
				v96_.rotScaleTarget = v95_.rotScale or v96_.rotScaleOrig
			end
			if v91_.steeringCenterNode == nil then
				local v98_ = v96_.rotMinOrig
				local v99_ = v96_.rotMaxOrig
				v96_.rotMin = v98_
				v96_.rotMax = v99_
				local v100_ = v96_.rotSpeedOrig
				local v101_ = v96_.rotSpeedNegOrig
				v96_.rotSpeed = v100_
				v96_.rotSpeedNeg = v101_
			else
				self.spec_wheels.steeringCenterNode = v91_.steeringCenterNode
				self:setAIRootNodeDirty()
				local v102_, v103_, v104_ = Wheels.getAckermannSteeringAngles(v96_.node, v91_.steeringCenterNode, v91_.turningRadius or self.spec_wheels.maxTurningRadius)
				v96_.rotMin = v102_
				v96_.rotMax = v103_
				local v105_ = v103_ / self.wheelSteeringDuration
				local v106_ = -v102_ / self.wheelSteeringDuration
				v96_.rotSpeed = v105_
				v96_.rotSpeedNeg = v106_
				if v104_ then
					local v107_ = -v96_.rotSpeedNeg
					local v108_ = -v96_.rotSpeed
					v96_.rotSpeed = v107_
					v96_.rotSpeedNeg = v108_
				end
			end
			local v109_ = v96_.rotScaleTarget - v96_.rotScale
			v96_.rotScaleTargetSpeed = math.abs(v109_) / (1 / v87_.toggleSpeedFactor * 1000)
		end
		for _, v110_ in pairs(v91_.wheels) do
			v110_.wheel.steeringOffset = v110_.wheel.steeringOffset or 0
			local v111_ = v110_.wheel
			local v112_ = v110_.offset - v110_.wheel.steeringOffset
			v111_.steeringOffsetSpeed = math.abs(v112_) / (1 / v87_.toggleSpeedFactor * 1000)
		end
		for _, v113_ in ipairs(v91_.nodes) do
			if v113_.rotation ~= nil then
				setRotation(v113_.node, v113_.rotation[1], v113_.rotation[2], v113_.rotation[3])
			end
			if v113_.translation ~= nil then
				setTranslation(v113_.node, v113_.translation[1], v113_.translation[2], v113_.translation[3])
			end
			if self.setMovingToolDirty ~= nil then
				self:setMovingToolDirty(v113_.node)
			end
		end
	end
	v87_.state = state
	if self.isClient and self.updateDashboardValueType ~= nil then
		self:updateDashboardValueType("crabSteering.state")
	end
end

-- Local values: spec
function CrabSteering:getCrabSteeringMode()
	local v115_ = self.spec_crabSteering
	if v115_.steeringModes == nil then
		return nil
	else
		return v115_.steeringModes[v115_.state]
	end
end

-- Local values: spec, state, valid, i
function CrabSteering:setNextCrabSteeringMode(direction)
	local v118_ = self.spec_crabSteering
	local v119_ = v118_.state
	local v120_ = false
	for _ = 1, v118_.stateMax do
		v119_ = v119_ + direction
		if v118_.stateMax < v119_ then
			v119_ = 1
		elseif v119_ < 1 then
			v119_ = v118_.stateMax
		end
		if self:getCrabSteeringModeAvailable(v118_.steeringModes[v119_]) then
			v120_ = true
			break
		end
	end
	if v120_ then
		if v119_ ~= v118_.state then
			self:setCrabSteering(v119_)
		end
	end
end

function CrabSteering:loadWheelFromXML(superFunc, wheel)
	if not superFunc(self, wheel) then
		return false
	end
	wheel.steeringOffset = 0
	wheel.forceSteeringAngleUpdate = true
	return true
end

-- Local values: spec, specDriveable, currentMode, i, wheelProperties, rotScale, delta, direction, change, limit, rotSpeed, f
function CrabSteering:updateSteeringAngle(superFunc, wheel, dt, steeringAngle)
	local v129_ = self.spec_crabSteering
	local v130_ = self.spec_drivable
	if v129_.stateMax == 0 then
		return superFunc(self, wheel, dt, steeringAngle)
	end
	local v131_ = v129_.steeringModes[v129_.state]
	for v132_ = 1, #v131_.wheels do
		local v133_ = v131_.wheels[v132_]
		if v133_.wheelIndex == wheel.wheelIndex then
			if wheel.rotSpeedBackUp == nil then
				wheel.rotSpeedBackUp = wheel.physics.rotSpeed
			end
			if wheel.rotSpeedBackUp ~= 0 then
				local v134_
				if self.lastSpeed == 0 then
					v134_ = 0
				else
					local v135_ = 1 / (self.lastSpeed * v130_.speedRotScale + v130_.speedRotScaleOffset)
					v134_ = math.min(v135_, 1)
				end
				local v136_ = dt * 0.001 * self.autoRotateBackSpeed * v134_ * v129_.toggleSpeedFactor
				if wheel.steeringOffset ~= v133_.offset then
					local v137_ = v133_.offset - wheel.steeringOffset
					local v138_ = math.sign(v137_)
					local v139_ = dt * v133_.wheel.steeringOffsetSpeed * v138_
					wheel.steeringOffset = (v138_ > 0 and math.min or math.max)(wheel.steeringOffset + v139_, v133_.offset)
				end
				if v133_.locked then
					if wheel.physics.steeringAngle > wheel.steeringOffset or wheel.steeringOffset < steeringAngle then
						local v140_ = wheel.steeringOffset
						local v141_ = wheel.physics.steeringAngle
						local v142_ = math.min(v141_, steeringAngle) - v136_
						steeringAngle = math.max(v140_, v142_)
					elseif wheel.physics.steeringAngle < wheel.steeringOffset or steeringAngle < wheel.steeringOffset then
						local v143_ = wheel.steeringOffset
						local v144_ = wheel.physics.steeringAngle
						local v145_ = math.max(v144_, steeringAngle) + v136_
						steeringAngle = math.min(v143_, v145_)
					end
					if steeringAngle == wheel.steeringOffset then
						wheel.physics.rotSpeed = 0
					elseif wheel.physics.rotSpeed < 0 then
						local v146_ = wheel.physics
						local v147_ = wheel.physics.rotSpeed + v136_
						v146_.rotSpeed = math.min(0, v147_)
					elseif wheel.physics.rotSpeed > 0 then
						local v148_ = wheel.physics
						local v149_ = wheel.physics.rotSpeed - v136_
						v148_.rotSpeed = math.max(0, v149_)
					end
				else
					local v150_
					if self.rotatedTime > 0 then
						v150_ = (wheel.physics.rotMax - wheel.steeringOffset) / self.wheelSteeringDuration
						if wheel.rotSpeedBackUp < 0 then
							v150_ = (wheel.physics.rotMin - wheel.steeringOffset) / self.wheelSteeringDuration
						end
					else
						v150_ = -(wheel.physics.rotMin - wheel.steeringOffset) / self.wheelSteeringDuration
						if wheel.rotSpeedBackUp < 0 then
							v150_ = -(wheel.physics.rotMax - wheel.steeringOffset) / self.wheelSteeringDuration
						end
					end
					if wheel.physics.rotSpeed < wheel.rotSpeedBackUp then
						local v151_ = wheel.physics
						local v152_ = wheel.rotSpeedBackUp
						local v153_ = wheel.physics.rotSpeed + v136_
						v151_.rotSpeed = math.min(v152_, v153_)
					elseif wheel.physics.rotSpeed > wheel.rotSpeedBackUp then
						local v154_ = wheel.physics
						local v155_ = wheel.rotSpeedBackUp
						local v156_ = wheel.physics.rotSpeed - v136_
						v154_.rotSpeed = math.max(v155_, v156_)
					end
					local v157_ = wheel.physics.rotSpeed / wheel.rotSpeedBackUp
					steeringAngle = wheel.steeringOffset + self.rotatedTime * v157_ * v150_
				end
				local v158_ = wheel.physics.rotMin
				local v159_ = wheel.physics.rotMax
				return math.clamp(steeringAngle, v158_, v159_)
			end
			break
		end
	end
	return steeringAngle
end

-- Local values: spec, specArticulatedAxis, specDriveable, currentMode, rotScale, delta, rotSpeed, f, wheels, curRot, alpha, count, _, wheelIndex, v, _, wheelIndex, wheel, axleSpeed, longSlip, _, fac, h, g, a, ls, beta, changingTime, pos
function CrabSteering:updateArticulatedAxisRotation(steeringAngle, dt)
	local v163_ = self.spec_crabSteering
	local v164_ = self.spec_articulatedAxis
	local v165_ = self.spec_drivable
	if v163_.stateMax == 0 then
		return steeringAngle
	end
	if not self.isServer then
		return v164_.curRot
	end
	local v166_ = v163_.steeringModes[v163_.state]
	if v166_.articulatedAxis == nil then
		return steeringAngle
	end
	local v167_ = 1 / (self.lastSpeed * v165_.speedRotScale + v165_.speedRotScaleOffset)
	local v168_ = math.min(v167_, 1)
	local v169_ = dt * 0.001 * self.autoRotateBackSpeed * v168_ * v163_.toggleSpeedFactor
	if v163_.currentArticulatedAxisOffset < v166_.articulatedAxis.offset then
		local v170_ = v166_.articulatedAxis.offset
		local v171_ = v163_.currentArticulatedAxisOffset + v169_
		v163_.currentArticulatedAxisOffset = math.min(v170_, v171_)
	elseif v163_.currentArticulatedAxisOffset > v166_.articulatedAxis.offset then
		local v172_ = v166_.articulatedAxis.offset
		local v173_ = v163_.currentArticulatedAxisOffset - v169_
		v163_.currentArticulatedAxisOffset = math.max(v172_, v173_)
	end
	if v166_.articulatedAxis.locked then
		if v164_.rotSpeed > 0 then
			local v174_ = v164_.rotSpeed - v169_
			v164_.rotSpeed = math.max(0, v174_)
		elseif v164_.rotSpeed < 0 then
			local v175_ = v164_.rotSpeed + v169_
			v164_.rotSpeed = math.min(0, v175_)
		end
	elseif v164_.rotSpeed > v166_.articulatedAxis.rotSpeedBackUp then
		local v176_ = v166_.articulatedAxis.rotSpeedBackUp
		local v177_ = v164_.rotSpeed - v169_
		v164_.rotSpeed = math.max(v176_, v177_)
	elseif v164_.rotSpeed < v166_.articulatedAxis.rotSpeedBackUp then
		local v178_ = v166_.articulatedAxis.rotSpeedBackUp
		local v179_ = v164_.rotSpeed + v169_
		v164_.rotSpeed = math.min(v178_, v179_)
	end
	local v180_
	if self.rotatedTime * v166_.articulatedAxis.rotSpeedBackUp > 0 then
		v180_ = (v164_.rotMax - v163_.currentArticulatedAxisOffset) / self.wheelSteeringDuration
	else
		v180_ = (v164_.rotMin - v163_.currentArticulatedAxisOffset) / self.wheelSteeringDuration
	end
	local v181_ = v164_.rotSpeed
	local v182_ = math.abs(v181_)
	local v183_ = v166_.articulatedAxis.rotSpeedBackUp
	local v184_ = v180_ * (v182_ / math.abs(v183_))
	local v185_ = v163_.currentArticulatedAxisOffset
	local v186_ = self.rotatedTime
	local v187_ = v185_ + math.abs(v186_) * v184_
	if v166_.articulatedAxis.wheelIndices == nil or (v163_.distFromCompJointToCenterOfBackWheels == nil or self.movingDirection < 0) then
		local v188_ = v163_.articulatedAxisChangingTime
		if v163_.articulatedAxisOffsetChanged then
			v163_.articulatedAxisOffsetChanged = false
			v188_ = 2500
		end
		if v188_ > 0 then
			local v189_ = v188_ / 2500
			v187_ = v187_ * (1 - v189_) + v163_.articulatedAxisLastAngle * v189_
			v163_.articulatedAxisChangingTime = v188_ - dt
		end
	else
		local v190_ = self:getWheels()
		local v191_ = v166_.articulatedAxis.rotSpeedBackUp
		local v192_ = math.sign(v191_) * v164_.curRot
		local v193_ = 0
		local v194_ = 0
		for _, v195_ in pairs(v166_.articulatedAxis.wheelIndices) do
			v193_ = v193_ + v190_[v195_].physics.steeringAngle
			v194_ = v194_ + 1
		end
		if v194_ > 0 then
			v193_ = v193_ / v194_
		end
		local v196_ = v193_ - v192_
		local v197_ = 0
		local v198_ = 0
		for _, v199_ in pairs(v166_.articulatedAxis.wheelIndices) do
			local v200_ = v190_[v199_]
			local v201_ = getWheelShapeAxleSpeed(v200_.node, v200_.physics.wheelShape)
			if v200_.physics.hasGroundContact then
				local v202_, _ = getWheelShapeSlip(v200_.node, v200_.physics.wheelShape)
				v197_ = v197_ + (1 - math.min(1, v202_)) * v201_ * v200_.physics.radius
				v198_ = v198_ + 1
			end
		end
		if v198_ > 0 then
			v197_ = v197_ / v198_
		end
		local v203_ = v197_ * 0.001 * dt
		local v204_ = math.sin(v196_) * v203_
		local v205_ = math.cos(v196_) * v203_
		local v206_ = v163_.distFromCompJointToCenterOfBackWheels - v205_
		local v207_ = math.atan2(v204_, v206_)
		local v208_ = v166_.articulatedAxis.rotSpeedBackUp
		v187_ = math.sign(v208_) * (v192_ + v207_)
		v163_.articulatedAxisOffsetChanged = true
		v163_.articulatedAxisLastAngle = v187_
	end
	local v209_ = v164_.rotMin
	local v210_ = v164_.rotMax
	local v211_ = math.min(v210_, v187_)
	return math.max(v209_, v211_)
end

function CrabSteering:getCanBeSelected(superFunc)
	return self.spec_crabSteering.hasSteeringModes or superFunc(self)
end

function CrabSteering:loadWheelsFromXML(superFunc, xmlFile, key, wheelConfigurationI)
	superFunc(self, xmlFile, key, wheelConfigurationI)
	self.spec_crabSteering.configurationIndex = WheelXMLObject.getValueStatic(self.spec_wheels.wheelConfigurationId, self.spec_wheels.configurationIndexToParentConfigIndex, self.xmlFile, Wheels.CONFIG_XML_PATH, ".wheels", "#crabSteeringIndex")
end

-- Local values: spec, currentMode
function CrabSteering:updateSteeringWheel(superFunc, steeringWheel, dt, direction)
	if self.spec_crabSteering.hasSteeringModes then
		local v224_ = self.spec_crabSteering
		local v225_ = v224_.steeringModes[v224_.state]
		if v225_.steeringWheel ~= nil then
			steeringWheel = v225_.steeringWheel
		end
	end
	superFunc(self, steeringWheel, dt, direction)
end

-- Local values: spec
function CrabSteering:startFieldWorker(superFunc)
	self:setCrabSteering(self.spec_crabSteering.aiSteeringModeIndex)
	return superFunc(self)
end

-- Local values: spec, currentMode
function CrabSteering:getAIAutomaticSteeringLookAheadDistance(superFunc)
	if self.spec_crabSteering.hasSteeringModes then
		local v230_ = self.spec_crabSteering
		local v231_ = v230_.steeringModes[v230_.state]
		if v231_.automaticSteeringLookAheadDistance ~= nil then
			return v231_.automaticSteeringLookAheadDistance
		end
	end
	return superFunc(self)
end

-- Local values: spec, _, actionEventId, _, mode
function CrabSteering:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v234_ = self.spec_crabSteering
		if v234_.hasSteeringModes then
			self:clearActionEventsTable(v234_.actionEvents)
			if isActiveForInputIgnoreSelection then
				local _, v235_ = self:addPoweredActionEvent(v234_.actionEvents, InputAction.TOGGLE_CRABSTEERING, self, CrabSteering.actionEventToggleCrabSteeringModes, false, true, false, true, 1)
				g_inputBinding:setActionEventTextPriority(v235_, GS_PRIO_NORMAL)
				for _, v236_ in pairs(v234_.steeringModes) do
					if v236_.inputAction ~= nil then
						local _, v237_ = self:addPoweredActionEvent(v234_.actionEvents, v236_.inputAction, self, CrabSteering.actionEventSetCrabSteeringMode, false, true, false, true, nil)
						g_inputBinding:setActionEventTextVisibility(v237_, false)
						g_inputBinding:setActionEventTextPriority(v237_, GS_PRIO_NORMAL)
					end
				end
				local _, v238_ = self:addPoweredActionEvent(v234_.actionEvents, InputAction.TOGGLE_CRABSTEERING_BACK, self, CrabSteering.actionEventToggleCrabSteeringModes, false, true, false, true, -1)
				g_inputBinding:setActionEventTextVisibility(v238_, false)
			end
		end
	end
end

-- Local values: isAllowed, warning
function CrabSteering:actionEventToggleCrabSteeringModes(actionName, inputValue, callbackState, isAnalog)
	local v241_, v242_ = self:getCanToggleCrabSteering()
	if v241_ then
		self:setNextCrabSteeringMode(callbackState)
	elseif v242_ ~= nil then
		g_currentMission:showBlinkingWarning(v242_, 2000)
	end
end

-- Local values: isAllowed, warning, spec, state, i, mode
function CrabSteering:actionEventSetCrabSteeringMode(actionName, inputValue, callbackState, isAnalog)
	local v245_, v246_ = self:getCanToggleCrabSteering()
	if v245_ then
		local v247_ = self.spec_crabSteering
		local v248_ = v247_.state
		for v249_, v250_ in pairs(v247_.steeringModes) do
			if v250_.inputAction == InputAction[actionName] then
				v248_ = v249_
				break
			end
		end
		if v248_ ~= v247_.state and self:getCrabSteeringModeAvailable(v247_.steeringModes[v248_]) then
			self:setCrabSteering(v248_)
			return
		end
	elseif v246_ ~= nil then
		g_currentMission:showBlinkingWarning(v246_, 2000)
	end
end
