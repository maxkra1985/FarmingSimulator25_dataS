SpeedRotatingParts = {}
SpeedRotatingParts.DEFAULT_MAX_UPDATE_DISTANCE = 50
SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY = "vehicle.speedRotatingParts.speedRotatingPart(?)"

function SpeedRotatingParts.prerequisitesPresent(specializations)
	return true
end
function SpeedRotatingParts.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("SpeedRotatingParts")
	v1_:register(XMLValueType.NODE_INDEX, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#node", "Speed rotating part node")
	v1_:register(XMLValueType.NODE_INDICES, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#nodes", "Speed rotating part nodes (first node will be used as main repr node and the others just copy the rotation values)")
	v1_:register(XMLValueType.NODE_INDEX, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#shaderNode", "Speed rotating part shader node")
	v1_:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#useRotation", "Use shader rotation", true)
	v1_:register(XMLValueType.VECTOR_2, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#scrollScale", "Shader scroll speed")
	v1_:register(XMLValueType.INT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#shaderComponent", "Shader parameter component to control", "Default based on available shader attributes")
	v1_:register(XMLValueType.VECTOR_N, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#shaderComponentSpeeds", "Speed factor for different shader components (usable with \'vtxRotate\' shader variation)")
	v1_:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#scrollLength", "Shader scroll length")
	v1_:register(XMLValueType.NODE_INDEX, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#driveNode", "Drive node to apply x drive", "speedRotatingPart#node")
	v1_:register(XMLValueType.INT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#refComponentIndex", "Reference component index")
	v1_:register(XMLValueType.INT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#wheelIndex", "Reference wheel index")
	v1_:register(XMLValueType.NODE_INDICES, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#wheelNodes", "List of reference wheel nodes (repr or drive node). The average speed of the wheels WITH ground contact is used.")
	v1_:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#hasConfigWheels", "Defined wheels are part of configurations, so no warning is displayed while they are not found.", false)
	v1_:register(XMLValueType.NODE_INDEX, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#dirRefNode", "Direction reference node")
	v1_:register(XMLValueType.NODE_INDEX, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#dirFrameNode", "Direction reference frame")
	v1_:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#alignDirection", "Align direction", false)
	v1_:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#applySteeringAngle", "Apply steering angle", false)
	v1_:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#useWheelReprTranslation", "Apply wheel repr translation", true)
	v1_:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#updateXDrive", "Update X drive", true)
	v1_:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#versatileYRot", "Versatile Y rot", false)
	v1_:register(XMLValueType.ANGLE, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#minYRot", "Min. Y rotation")
	v1_:register(XMLValueType.ANGLE, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#maxYRot", "Max. Y rotation")
	v1_:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#wheelScale", "Wheel scale")
	v1_:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#radius", "Radius", 1)
	v1_:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#onlyActiveWhenLowered", "Only active if lowered", false)
	v1_:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#stopIfNotActive", "Stop if not active", false)
	v1_:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#fadeOutTime", "Fade out time", 3)
	v1_:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#activationSpeed", "Min. speed for activation", 1)
	v1_:register(XMLValueType.NODE_INDEX, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#speedReferenceNode", "Speed reference node")
	v1_:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#hasTireTracks", "Has Tire Tracks", false)
	v1_:register(XMLValueType.INT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#tireTrackAtlasIndex", "Index on tire track atlas", 0)
	v1_:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#tireTrackWidth", "Width of tire tracks", 0.5)
	v1_:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#tireTrackInverted", "Tire track texture inverted", false)
	v1_:register(XMLValueType.NODE_INDEX, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#tireTrackWheelNode", "Reference wheel for the tire tracks (radius, ground contact, etc)")
	v1_:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#maxUpdateDistance", "Max. distance from current camera to vehicle to update part", SpeedRotatingParts.DEFAULT_MAX_UPDATE_DISTANCE)
	v1_:setXMLSpecializationType()
end

function SpeedRotatingParts.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadSpeedRotatingPartFromXML", SpeedRotatingParts.loadSpeedRotatingPartFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsSpeedRotatingPartActive", SpeedRotatingParts.getIsSpeedRotatingPartActive)
	SpecializationUtil.registerFunction(vehicleType, "getSpeedRotatingPartDirection", SpeedRotatingParts.getSpeedRotatingPartDirection)
	SpecializationUtil.registerFunction(vehicleType, "updateSpeedRotatingPart", SpeedRotatingParts.updateSpeedRotatingPart)
end

function SpeedRotatingParts.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "validateWashableNode", SpeedRotatingParts.validateWashableNode)
end

function SpeedRotatingParts.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", SpeedRotatingParts)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", SpeedRotatingParts)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", SpeedRotatingParts)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", SpeedRotatingParts)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", SpeedRotatingParts)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", SpeedRotatingParts)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", SpeedRotatingParts)
end

-- Local values: spec, maxUpdateDistance, _, baseName, speedRotatingPart
function SpeedRotatingParts:onLoad(savegame)
	local v6_ = self.spec_speedRotatingParts
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.speedRotatingParts.speedRotatingPart(0)#index", "vehicle.speedRotatingParts.speedRotatingPart(0)#node")
	v6_.individualUpdateDistance = false
	v6_.speedRotatingParts = {}
	local v7_ = nil
	for _, v8_ in self.xmlFile:iterator("vehicle.speedRotatingParts.speedRotatingPart") do
		local v9_ = {}
		if self:loadSpeedRotatingPartFromXML(v9_, self.xmlFile, v8_) then
			local v10_ = v6_.speedRotatingParts
			table.insert(v10_, v9_)
			if v7_ ~= nil and v7_ ~= v9_.maxUpdateDistance then
				v6_.individualUpdateDistance = true
			end
			v7_ = v9_.maxUpdateDistance
		elseif v9_.tireTrackNodeIndex ~= nil then
			self:removeTireTrackNode(v9_.tireTrackNodeIndex)
		end
	end
	v6_.maxUpdateDistance = v7_ or SpeedRotatingParts.DEFAULT_MAX_UPDATE_DISTANCE
	v6_.dirtyFlag = self:getNextDirtyFlag()
	if #v6_.speedRotatingParts == 0 then
		SpecializationUtil.removeEventListener(self, "onReadStream", SpeedRotatingParts)
		SpecializationUtil.removeEventListener(self, "onWriteStream", SpeedRotatingParts)
		SpecializationUtil.removeEventListener(self, "onReadUpdateStream", SpeedRotatingParts)
		SpecializationUtil.removeEventListener(self, "onWriteUpdateStream", SpeedRotatingParts)
		SpecializationUtil.removeEventListener(self, "onUpdate", SpeedRotatingParts)
		SpecializationUtil.removeEventListener(self, "onUpdateTick", SpeedRotatingParts)
	end
end

-- Local values: spec, i, speedRotatingPart, yRot
function SpeedRotatingParts:onReadStream(streamId, connection)
	local v13_ = self.spec_speedRotatingParts
	for v14_ = 1, #v13_.speedRotatingParts do
		local v15_ = v13_.speedRotatingParts[v14_]
		if v15_.versatileYRot then
			v15_.steeringAngle = streamReadUIntN(streamId, 9) / 511 * 3.141592653589793 * 2
		end
	end
end

-- Local values: spec, i, speedRotatingPart, yRot
function SpeedRotatingParts:onWriteStream(streamId, connection)
	local v18_ = self.spec_speedRotatingParts
	for v19_ = 1, #v18_.speedRotatingParts do
		local v20_ = v18_.speedRotatingParts[v19_]
		if v20_.versatileYRot then
			local v21_ = v20_.steeringAngle % 6.283185307179586
			local v22_ = streamWriteUIntN
			local v23_ = v21_ / 6.283185307179586 * 511
			local v24_ = math.floor(v23_)
			v22_(streamId, math.clamp(v24_, 0, 511), 9)
		end
	end
end

-- Local values: hasUpdate, spec, i, speedRotatingPart, yRot
function SpeedRotatingParts:onReadUpdateStream(streamId, timestamp, connection)
	if connection.isServer and streamReadBool(streamId) then
		local v28_ = self.spec_speedRotatingParts
		for v29_ = 1, #v28_.speedRotatingParts do
			local v30_ = v28_.speedRotatingParts[v29_]
			if v30_.versatileYRot then
				v30_.steeringAngle = streamReadUIntN(streamId, 9) / 511 * 3.141592653589793 * 2
			end
		end
	end
end

-- Local values: spec, i, speedRotatingPart, yRot
function SpeedRotatingParts:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection.isServer then
		local v35_ = self.spec_speedRotatingParts
		local v36_ = streamWriteBool
		local v37_ = v35_.dirtyFlag
		if v36_(streamId, bit32.band(dirtyMask, v37_) ~= 0) then
			for v38_ = 1, #v35_.speedRotatingParts do
				local v39_ = v35_.speedRotatingParts[v38_]
				if v39_.versatileYRot then
					local v40_ = v39_.steeringAngle % 6.283185307179586
					local v41_ = streamWriteUIntN
					local v42_ = v40_ / 6.283185307179586 * 511
					local v43_ = math.floor(v42_)
					v41_(streamId, math.clamp(v43_, 0, 511), 9)
				end
			end
		end
	end
end

-- Local values: spec, i, speedRotatingPart
function SpeedRotatingParts:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v46_ = self.spec_speedRotatingParts
	if v46_.individualUpdateDistance or self.currentUpdateDistance < v46_.maxUpdateDistance then
		for v47_ = 1, #v46_.speedRotatingParts do
			local v48_ = v46_.speedRotatingParts[v47_]
			if (not v46_.individualUpdateDistance or self.currentUpdateDistance < v48_.maxUpdateDistance) and (v48_.isActive or v48_.lastSpeed ~= 0 and not v48_.stopIfNotActive) then
				self:updateSpeedRotatingPart(v48_, dt, v48_.isActive)
			end
		end
	end
end

-- Local values: spec, i, speedRotatingPart
function SpeedRotatingParts:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v50_ = self.spec_speedRotatingParts
	if v50_.individualUpdateDistance or self.currentUpdateDistance < v50_.maxUpdateDistance then
		for v51_ = 1, #v50_.speedRotatingParts do
			local v52_ = v50_.speedRotatingParts[v51_]
			if not v50_.individualUpdateDistance or self.currentUpdateDistance < v52_.maxUpdateDistance then
				v52_.isActive = self:getIsSpeedRotatingPartActive(v52_)
			end
		end
	end
end

-- Local values: componentIndex, node, wheelIndex, wheelNodes, wheels, wheel, _, wheelNode, wheel, _, wheel, activeFunc, wheel, baseRadius, radius
function SpeedRotatingParts:loadSpeedRotatingPartFromXML(speedRotatingPart, xmlFile, key)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#vtxPositionArrayFilename", "Array should be assigned properly inside i3d.")
	speedRotatingPart.reprNodes = xmlFile:getValue(key .. "#nodes", nil, self.components, self.i3dMappings, true)
	speedRotatingPart.repr = xmlFile:getValue(key .. "#node", speedRotatingPart.reprNodes[1], self.components, self.i3dMappings)
	speedRotatingPart.shaderNode = xmlFile:getValue(key .. "#shaderNode", nil, self.components, self.i3dMappings)
	if #speedRotatingPart.reprNodes > 0 and speedRotatingPart.reprNodes[1] == speedRotatingPart.repr then
		table.remove(speedRotatingPart.reprNodes, 1)
	end
	speedRotatingPart.shaderParameterName = "offsetUV"
	speedRotatingPart.shaderParameterPrevName = nil
	speedRotatingPart.shaderParameterComponent = 3
	speedRotatingPart.shaderParameterSpeedScale = 1
	speedRotatingPart.shaderParameterValues = {
		0,
		0,
		0,
		0
	}
	if speedRotatingPart.shaderNode ~= nil then
		speedRotatingPart.useShaderRotation = xmlFile:getValue(key .. "#useRotation", true)
		speedRotatingPart.scrollScale = xmlFile:getValue(key .. "#scrollScale", "1 0", true)
		speedRotatingPart.scrollLength = xmlFile:getValue(key .. "#scrollLength")
		if getHasShaderParameter(speedRotatingPart.shaderNode, "rotationAngle") then
			speedRotatingPart.shaderParameterName = "rotationAngle"
			speedRotatingPart.shaderParameterPrevName = "prevRotationAngle"
			speedRotatingPart.shaderParameterComponent = 1
			speedRotatingPart.shaderParameterSpeedScale = -1
		end
		if getHasShaderParameter(speedRotatingPart.shaderNode, "scrollPos") then
			speedRotatingPart.shaderParameterName = "scrollPos"
			speedRotatingPart.shaderParameterPrevName = "prevScrollPos"
			speedRotatingPart.shaderParameterComponent = 1
			speedRotatingPart.shaderParameterSpeedScale = 1
		end
		speedRotatingPart.shaderParameterComponent = xmlFile:getValue(key .. "#shaderComponent", speedRotatingPart.shaderParameterComponent)
		speedRotatingPart.shaderComponentSpeeds = xmlFile:getValue(key .. "#shaderComponentSpeeds", nil, true)
	end
	if speedRotatingPart.repr == nil and speedRotatingPart.shaderNode == nil then
		local v57_ = Logging.xmlWarning
		local v58_ = self.xmlFile
		local v59_ = getXMLString(xmlFile.handle, key .. "#node") or getXMLString(xmlFile.handle, key .. "#shaderNode")
		v57_(v58_, "Invalid speedRotationPart node \'%s\' in \'%s\'", tostring(v59_), key)
		return false
	end
	speedRotatingPart.driveNode = xmlFile:getValue(key .. "#driveNode", speedRotatingPart.repr, self.components, self.i3dMappings)
	local v60_ = xmlFile:getValue(key .. "#refComponentIndex")
	if v60_ == nil or self.components[v60_] == nil then
		speedRotatingPart.componentNode = self:getParentComponent((Utils.getNoNil(speedRotatingPart.driveNode, speedRotatingPart.shaderNode)))
	else
		speedRotatingPart.componentNode = self.components[v60_].node
	end
	speedRotatingPart.xDrive = 0
	local v61_ = xmlFile:getValue(key .. "#wheelIndex")
	local v62_ = xmlFile:getValue(key .. "#wheelNodes", nil, self.components, self.i3dMappings, true)
	if v61_ ~= nil or #v62_ > 0 then
		if self.getWheels == nil then
			Logging.xmlWarning(self.xmlFile, "wheelIndex for speedRotatingPart \'%s\' given, but no wheels loaded/defined", key)
		else
			local v63_ = {}
			if v61_ ~= nil then
				local v64_ = self:getWheelFromWheelIndex(v61_)
				if v64_ == nil then
					if not xmlFile:getValue(key .. "#hasConfigWheels", false) then
						Logging.xmlWarning(self.xmlFile, "Invalid wheel index \'%s\' for speedRotatingPart \'%s\'", v61_, key)
					end
				else
					table.insert(v63_, v64_)
				end
			end
			if #v62_ > 0 then
				for _, v65_ in ipairs(v62_) do
					local v66_ = self:getWheelByWheelNode(v65_)
					if v66_ == nil then
						if not xmlFile:getValue(key .. "#hasConfigWheels", false) then
							Logging.xmlWarning(self.xmlFile, "Invalid wheel node \'%s\' for speedRotatingPart \'%s\'", getName(v65_), key)
						end
					else
						table.insert(v63_, v66_)
					end
				end
			end
			if #v63_ == 0 then
				return false
			end
			for _, v67_ in ipairs(v63_) do
				v67_.syncContactState = true
				if not v67_.physics.isSynchronized then
					Logging.xmlWarning(self.xmlFile, "Referenced wheel \'%s\' for speedRotatingPart \'%s\' is not synchronized in multiplayer", getName(v67_.repr), key)
				end
			end
			speedRotatingPart.wheels = v63_
			speedRotatingPart.lastWheelXRot = {}
		end
	end
	speedRotatingPart.hasTireTracks = xmlFile:getValue(key .. "#hasTireTracks", false)
	speedRotatingPart.tireTrackAtlasIndex = xmlFile:getValue(key .. "#tireTrackAtlasIndex", 0)
	speedRotatingPart.tireTrackWidth = xmlFile:getValue(key .. "#tireTrackWidth", 0.5)
	speedRotatingPart.tireTrackInverted = xmlFile:getValue(key .. "#tireTrackInverted", false)
	speedRotatingPart.tireTrackWheelNode = xmlFile:getValue(key .. "#tireTrackWheelNode", nil, self.components, self.i3dMappings)
	if speedRotatingPart.hasTireTracks and Platform.gameplay.wheelTireTracks then
		local function v68_()
			-- upvalues: (copy) self, (copy) speedRotatingPart
			return self:getIsSpeedRotatingPartActive(speedRotatingPart)
		end
		local v69_
		if speedRotatingPart.wheels == nil then
			if speedRotatingPart.tireTrackWheelNode == nil then
				Logging.xmlWarning(self.xmlFile, "Tire tracks for speedRotationPart \'%s\' defined, but no wheels or tireTrackWheelNode given", key)
				return false
			end
			v69_ = self:getWheelByWheelNode(speedRotatingPart.tireTrackWheelNode)
		else
			v69_ = speedRotatingPart.wheels[1]
		end
		speedRotatingPart.tireTrackNodeIndex = self:addTireTrackNode(v69_, speedRotatingPart.componentNode, speedRotatingPart.driveNode, speedRotatingPart.tireTrackAtlasIndex, speedRotatingPart.tireTrackWidth, v69_.physics.radius, speedRotatingPart.tireTrackInverted, v68_)
	end
	speedRotatingPart.dirRefNode = xmlFile:getValue(key .. "#dirRefNode", nil, self.components, self.i3dMappings)
	speedRotatingPart.dirFrameNode = xmlFile:getValue(key .. "#dirFrameNode", nil, self.components, self.i3dMappings)
	speedRotatingPart.alignDirection = xmlFile:getValue(key .. "#alignDirection", false)
	speedRotatingPart.applySteeringAngle = xmlFile:getValue(key .. "#applySteeringAngle", false)
	speedRotatingPart.useWheelReprTranslation = xmlFile:getValue(key .. "#useWheelReprTranslation", true)
	speedRotatingPart.updateXDrive = xmlFile:getValue(key .. "#updateXDrive", true)
	speedRotatingPart.versatileYRot = xmlFile:getValue(key .. "#versatileYRot", false)
	if speedRotatingPart.versatileYRot and speedRotatingPart.repr == nil then
		Logging.xmlWarning(self.xmlFile, "Versatile speedRotationPart \'%s\' does not support shaderNodes", key)
		return false
	end
	speedRotatingPart.minYRot = xmlFile:getValue(key .. "#minYRot")
	speedRotatingPart.maxYRot = xmlFile:getValue(key .. "#maxYRot")
	speedRotatingPart.steeringAngle = 0
	speedRotatingPart.steeringAngleSent = 0
	speedRotatingPart.speedReferenceNode = xmlFile:getValue(key .. "#speedReferenceNode", nil, self.components, self.i3dMappings)
	if speedRotatingPart.speedReferenceNode ~= nil and speedRotatingPart.speedReferenceNode == speedRotatingPart.driveNode then
		Logging.xmlWarning(self.xmlFile, "Ignoring speedRotationPart \'%s\' because speedReferenceNode is identical with driveNode. Need to be different!", key)
		return false
	end
	speedRotatingPart.wheelScale = xmlFile:getValue(key .. "#wheelScale")
	if speedRotatingPart.wheelScale == nil then
		local v70_, v71_
		if speedRotatingPart.wheels == nil or speedRotatingPart.speedReferenceNode ~= nil then
			v70_ = 1
			v71_ = 1
		else
			v71_ = speedRotatingPart.wheels[1].physics.radius
			v70_ = speedRotatingPart.wheels[1].physics.radius
		end
		speedRotatingPart.wheelScale = v71_ / xmlFile:getValue(key .. "#radius", v70_)
	end
	speedRotatingPart.wheelScaleBackup = speedRotatingPart.wheelScale
	speedRotatingPart.onlyActiveWhenLowered = xmlFile:getValue(key .. "#onlyActiveWhenLowered", false)
	speedRotatingPart.stopIfNotActive = xmlFile:getValue(key .. "#stopIfNotActive", false)
	speedRotatingPart.fadeOutTime = xmlFile:getValue(key .. "#fadeOutTime", 3) * 1000
	speedRotatingPart.activationSpeed = xmlFile:getValue(key .. "#activationSpeed", 1)
	speedRotatingPart.lastSpeed = 0
	speedRotatingPart.lastDir = 1
	speedRotatingPart.maxUpdateDistance = xmlFile:getValue(key .. "#maxUpdateDistance", SpeedRotatingParts.DEFAULT_MAX_UPDATE_DISTANCE)
	if self.isServer and speedRotatingPart.versatileYRot then
		speedRotatingPart.maxUpdateDistance = math.huge
	end
	return true
end

function SpeedRotatingParts:getIsSpeedRotatingPartActive(speedRotatingPart)
	return not speedRotatingPart.onlyActiveWhenLowered and true or ((self.getIsLowered == nil or self:getIsLowered()) and true or false)
end

function SpeedRotatingParts:getSpeedRotatingPartDirection(speedRotatingPart)
	return 1
end

-- Local values: spec, speed, dir, _, newX, newY, newZ, dx, dy, dz, numWheelsWithContact, _, wheel, speedSum, numWheels, i, wheel, rotDiff, _, wheelIndex, _, posX, posY, posZ, steeringAngleSent, _, yTrans, _, upX, upY, upZ, dirX, dirY, dirZ, _, yTrans, _, steeringAngle, _, repr, _, repr, values, index, speedScale, pos
function SpeedRotatingParts:updateSpeedRotatingPart(speedRotatingPart, dt, isPartActive)
	local v78_ = self.spec_speedRotatingParts
	local v79_ = speedRotatingPart.lastSpeed
	local v80_ = speedRotatingPart.lastDir
	if speedRotatingPart.repr ~= nil and (self.isServer or not speedRotatingPart.versatileYRot) then
		local _, v81_, _ = getRotation(speedRotatingPart.repr)
		speedRotatingPart.steeringAngle = v81_
	end
	if not isPartActive then
		local v82_ = v79_ - speedRotatingPart.brakeForce
		v122_ = math.max(v82_, 0)
		if speedRotatingPart.wheels ~= nil then
			for v83_, _ in pairs(speedRotatingPart.lastWheelXRot) do
				speedRotatingPart.lastWheelXRot[v83_] = nil
			end
		end
		::l43::
		speedRotatingPart.lastSpeed = v122_
		speedRotatingPart.lastDir = v80_
		if speedRotatingPart.updateXDrive then
			speedRotatingPart.xDrive = (speedRotatingPart.xDrive + v122_ * v80_ * self:getSpeedRotatingPartDirection(speedRotatingPart) * speedRotatingPart.wheelScale) % 6.283185307179586
		end
		if speedRotatingPart.versatileYRot then
			if v122_ > 0.0017 and (self.isServer and self:getLastSpeed(true) > speedRotatingPart.activationSpeed) then
				local v84_, v85_, v86_ = localToLocal(speedRotatingPart.repr, speedRotatingPart.componentNode, 0, 0, 0)
				speedRotatingPart.steeringAngle = Utils.getVersatileRotation(speedRotatingPart.repr, speedRotatingPart.componentNode, dt, v84_, v85_, v86_, speedRotatingPart.steeringAngle, speedRotatingPart.minYRot, speedRotatingPart.maxYRot)
				local v87_ = speedRotatingPart.steeringAngle % 6.283185307179586 / 6.283185307179586 * 511
				local v88_ = math.floor(v87_)
				if v88_ ~= speedRotatingPart.steeringAngleSent then
					speedRotatingPart.steeringAngleSent = v88_
					self:raiseDirtyFlags(v78_.dirtyFlag)
				end
			end
		else
			if speedRotatingPart.componentNode ~= nil and (speedRotatingPart.dirRefNode ~= nil and not speedRotatingPart.alignDirection) then
				speedRotatingPart.steeringAngle = Utils.getYRotationBetweenNodes(speedRotatingPart.componentNode, speedRotatingPart.dirRefNode)
				local _, v89_, _ = localToLocal(speedRotatingPart.driveNode, speedRotatingPart.wheels[1].driveNode, 0, 0, 0)
				setTranslation(speedRotatingPart.driveNode, 0, v89_, 0)
			end
			if speedRotatingPart.dirRefNode ~= nil and speedRotatingPart.alignDirection then
				local v90_, v91_, v92_ = localDirectionToWorld(speedRotatingPart.dirFrameNode, 0, 1, 0)
				local v93_, v94_, v95_ = localDirectionToWorld(speedRotatingPart.dirRefNode, 0, 0, 1)
				I3DUtil.setWorldDirection(speedRotatingPart.repr, v93_, v94_, v95_, v90_, v91_, v92_, 2)
				if speedRotatingPart.wheels ~= nil and speedRotatingPart.useWheelReprTranslation then
					local _, v96_, _ = localToLocal(speedRotatingPart.wheels[1].driveNode, getParent(speedRotatingPart.repr), 0, 0, 0)
					setTranslation(speedRotatingPart.repr, 0, v96_, 0)
				end
			end
		end
		if speedRotatingPart.driveNode ~= nil then
			if speedRotatingPart.repr == speedRotatingPart.driveNode then
				local v97_ = speedRotatingPart.steeringAngle
				local v98_ = not speedRotatingPart.applySteeringAngle and 0 or v97_
				setRotation(speedRotatingPart.repr, speedRotatingPart.xDrive, v98_, 0)
				for _, v99_ in ipairs(speedRotatingPart.reprNodes) do
					setRotation(v99_, speedRotatingPart.xDrive, v98_, 0)
				end
			else
				if not speedRotatingPart.alignDirection and (speedRotatingPart.versatileYRot or speedRotatingPart.applySteeringAngle) then
					setRotation(speedRotatingPart.repr, 0, speedRotatingPart.steeringAngle, 0)
					for _, v100_ in ipairs(speedRotatingPart.reprNodes) do
						setRotation(v100_, 0, speedRotatingPart.steeringAngle, 0)
					end
				end
				setRotation(speedRotatingPart.driveNode, speedRotatingPart.xDrive, 0, 0)
			end
		end
		if speedRotatingPart.shaderNode ~= nil then
			if speedRotatingPart.useShaderRotation then
				local v101_ = speedRotatingPart.shaderParameterValues
				if speedRotatingPart.shaderComponentSpeeds == nil then
					if speedRotatingPart.scrollLength == nil then
						v101_[speedRotatingPart.shaderParameterComponent] = speedRotatingPart.xDrive * speedRotatingPart.shaderParameterSpeedScale
					else
						v101_[speedRotatingPart.shaderParameterComponent] = speedRotatingPart.xDrive * speedRotatingPart.shaderParameterSpeedScale % speedRotatingPart.scrollLength
					end
				else
					for v102_, v103_ in ipairs(speedRotatingPart.shaderComponentSpeeds) do
						if speedRotatingPart.scrollLength == nil then
							v101_[v102_] = speedRotatingPart.xDrive * speedRotatingPart.shaderParameterSpeedScale * v103_
						else
							v101_[v102_] = speedRotatingPart.xDrive * speedRotatingPart.shaderParameterSpeedScale * v103_ % speedRotatingPart.scrollLength
						end
					end
				end
				if speedRotatingPart.shaderParameterPrevName == nil then
					setShaderParameter(speedRotatingPart.shaderNode, speedRotatingPart.shaderParameterName, v101_[1], v101_[2], v101_[3], v101_[4], false)
				else
					g_animationManager:setPrevShaderParameter(speedRotatingPart.shaderNode, speedRotatingPart.shaderParameterName, v101_[1], v101_[2], v101_[3], v101_[4], false, speedRotatingPart.shaderParameterPrevName)
				end
			end
			local v104_ = speedRotatingPart.xDrive % 3.141592653589793 / 6.283185307179586
			setShaderParameter(speedRotatingPart.shaderNode, "offsetUV", v104_ * speedRotatingPart.scrollScale[1], v104_ * speedRotatingPart.scrollScale[2], 0, 0, false)
		end
		return
	end
	if speedRotatingPart.speedReferenceNode ~= nil then
		local v105_, v106_, v107_ = getWorldTranslation(speedRotatingPart.speedReferenceNode)
		if speedRotatingPart.lastPosition == nil then
			speedRotatingPart.lastPosition = { v105_, v106_, v107_ }
		end
		local v108_, v109_, v110_ = worldDirectionToLocal(speedRotatingPart.speedReferenceNode, v105_ - speedRotatingPart.lastPosition[1], v106_ - speedRotatingPart.lastPosition[2], v107_ - speedRotatingPart.lastPosition[3])
		v122_ = MathUtil.vector3Length(v108_, v109_, v110_)
		v80_ = v110_ > 0.001 and 1 or (v110_ < -0.001 and -1 or 0)
		local v111_ = speedRotatingPart.lastPosition
		local v112_ = speedRotatingPart.lastPosition
		local v113_ = speedRotatingPart.lastPosition
		v111_[1] = v105_
		v112_[2] = v106_
		v113_[3] = v107_
		::l16::
		speedRotatingPart.brakeForce = v122_ * dt / speedRotatingPart.fadeOutTime
		goto l43
	end
	if speedRotatingPart.wheels == nil then
		v122_ = self.lastSpeedReal * dt
		v80_ = self.movingDirection
		goto l16
	end
	local v114_ = 0
	for _, v115_ in ipairs(speedRotatingPart.wheels) do
		if v115_.physics.contact ~= WheelContactType.NONE then
			v114_ = v114_ + 1
		end
	end
	local v116_ = 0
	local v117_ = 0
	v80_ = 0
	for v118_, v119_ in ipairs(speedRotatingPart.wheels) do
		if speedRotatingPart.lastWheelXRot[v118_] == nil then
			speedRotatingPart.lastWheelXRot[v118_] = v119_.physics.netInfo.xDrive
		end
		if v119_.physics.contact ~= WheelContactType.NONE then
			::l28::
			local v120_ = v119_.physics.netInfo.xDrive - speedRotatingPart.lastWheelXRot[v118_]
			if v120_ > 3.141592653589793 then
				v120_ = v120_ - 6.283185307179586
			elseif v120_ < -3.141592653589793 then
				v120_ = v120_ + 6.283185307179586
			end
			v116_ = v116_ + math.abs(v120_)
			if math.sign(v120_) ~= 0 then
				v80_ = math.sign(v120_)
			end
			v117_ = v117_ + 1
			goto l31
		end
		if v114_ == 0 then
			local v121_ = v119_.physics.netInfo.xDriveSpeed
			if math.abs(v121_) > 0.01 then
				goto l28
			end
		end
		if #speedRotatingPart.wheels == 1 then
			goto l28
		end
		::l31::
		speedRotatingPart.lastWheelXRot[v118_] = v119_.physics.netInfo.xDrive
	end
	local v122_ = v117_ <= 0 and 0 or v116_ / v117_
	if not speedRotatingPart.versatileYRot then
		local _, v123_, _ = getRotation(speedRotatingPart.wheels[1].repr)
		speedRotatingPart.steeringAngle = v123_
	end
	goto l16
end

-- Local values: spec, _, speedRotatingPart, speedRotatingPartsNodes, _, repr, nodeData
function SpeedRotatingParts:validateWashableNode(superFunc, node)
	local v127_ = self.spec_speedRotatingParts
	for _, v128_ in pairs(v127_.speedRotatingParts) do
		if v128_.wheels ~= nil then
			local v129_ = {}
			if v128_.repr ~= nil then
				I3DUtil.getNodesByShaderParam(v128_.repr, "scratches_dirt_snow_wetness", v129_)
			end
			for _, v130_ in ipairs(v128_.reprNodes) do
				I3DUtil.getNodesByShaderParam(v130_, "scratches_dirt_snow_wetness", v129_)
			end
			if v128_.shaderNode ~= nil then
				I3DUtil.getNodesByShaderParam(v128_.shaderNode, "scratches_dirt_snow_wetness", v129_)
			end
			if v128_.driveNode ~= nil then
				I3DUtil.getNodesByShaderParam(v128_.driveNode, "scratches_dirt_snow_wetness", v129_)
			end
			if v129_[node] ~= nil then
				local v131_ = {
					["wheel"] = v128_.wheels[1]
				}
				v131_.fieldDirtMultiplier = v131_.wheel.physics.fieldDirtMultiplier
				v131_.streetDirtMultiplier = v131_.wheel.physics.streetDirtMultiplier
				v131_.waterWetnessFactor = v131_.wheel.physics.waterWetnessFactor
				v131_.minDirtPercentage = v131_.wheel.physics.minDirtPercentage
				v131_.maxDirtOffset = v131_.wheel.physics.maxDirtOffset
				v131_.dirtColorChangeSpeed = v131_.wheel.physics.dirtColorChangeSpeed
				v131_.isSnowNode = true
				return false, self.updateWheelDirtAmount, v131_.wheel, v131_
			end
		end
	end
	return superFunc(self, node)
end
