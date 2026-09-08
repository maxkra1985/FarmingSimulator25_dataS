AttacherJointControl = {}
AttacherJointControl.ALPHA_NUM_BITS = 8
AttacherJointControl.ALPHA_MAX_VALUE = 2 ^ AttacherJointControl.ALPHA_NUM_BITS - 1

function AttacherJointControl.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Attachable, specializations)
end
function AttacherJointControl.initSpecialization()
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("AttacherJointControl")
	v2_:register(XMLValueType.ANGLE, "vehicle.attacherJointControl#maxTiltAngle", "Max tilt angle", 25)
	v2_:register(XMLValueType.BOOL, "vehicle.attacherJointControl#supportsDamping", "Supports damping of Y axis", false)
	v2_:register(XMLValueType.FLOAT, "vehicle.attacherJointControl#dampingOffset", "Distance from attacher joint to damping reference point (m)", 2)
	v2_:register(XMLValueType.STRING, "vehicle.attacherJointControl.control(?)#controlFunction", "Control script function (controlAttacherJointHeight or controlAttacherJointTilt)")
	v2_:register(XMLValueType.STRING, "vehicle.attacherJointControl.control(?)#controlAxis", "Name of input action")
	v2_:register(XMLValueType.STRING, "vehicle.attacherJointControl.control(?)#iconName", "Name of icon")
	v2_:registerAutoCompletionDataSource("vehicle.attacherJointControl.control(?)#iconName", "$dataS/axisIcons.xml", "axisIcons.icon#name")
	v2_:register(XMLValueType.BOOL, "vehicle.attacherJointControl.control(?)#invertControlAxis", "Invert control axis", false)
	v2_:register(XMLValueType.FLOAT, "vehicle.attacherJointControl.control(?)#mouseSpeedFactor", "Mouse speed factor", 1)
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.attacherJointControl.sounds", "hydraulic")
	v2_:register(XMLValueType.BOOL, Attachable.INPUT_ATTACHERJOINT_XML_KEY .. "#isControllable", "Is controllable", false)
	v2_:register(XMLValueType.BOOL, Attachable.INPUT_ATTACHERJOINT_CONFIG_XML_KEY .. "#isControllable", "Is controllable", false)
	v2_:setXMLSpecializationType()
end

function AttacherJointControl.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "controlAttacherJoint", AttacherJointControl.controlAttacherJoint)
	SpecializationUtil.registerFunction(vehicleType, "controlAttacherJointHeight", AttacherJointControl.controlAttacherJointHeight)
	SpecializationUtil.registerFunction(vehicleType, "controlAttacherJointTilt", AttacherJointControl.controlAttacherJointTilt)
	SpecializationUtil.registerFunction(vehicleType, "getControlAttacherJointDirection", AttacherJointControl.getControlAttacherJointDirection)
	SpecializationUtil.registerFunction(vehicleType, "getIsAttacherJointControlDampingAllowed", AttacherJointControl.getIsAttacherJointControlDampingAllowed)
end

function AttacherJointControl.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadInputAttacherJoint", AttacherJointControl.loadInputAttacherJoint)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "registerLoweringActionEvent", AttacherJointControl.registerLoweringActionEvent)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getLoweringActionEventState", AttacherJointControl.getLoweringActionEventState)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", AttacherJointControl.getCanBeSelected)
end

function AttacherJointControl.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AttacherJointControl)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", AttacherJointControl)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", AttacherJointControl)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", AttacherJointControl)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", AttacherJointControl)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", AttacherJointControl)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AttacherJointControl)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", AttacherJointControl)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", AttacherJointControl)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", AttacherJointControl)
end

-- Local values: spec, baseKey, i, key, control, controlFunc, actionBindingName, iconName
function AttacherJointControl:onLoad(savegame)
	local v7_ = self.spec_attacherJointControl
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.attacherJointControl.control1", "vehicle.attacherJointControl.control with #controlFunction \'controlAttacherJointHeight\'")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.attacherJointControl.control2", "vehicle.attacherJointControl.control with #controlFunction \'controlAttacherJointTilt\'")
	v7_.maxTiltAngle = self.xmlFile:getValue("vehicle.attacherJointControl#maxTiltAngle", 25)
	v7_.heightTargetAlpha = -1
	v7_.supportsDamping = self.xmlFile:getValue("vehicle.attacherJointControl#supportsDamping", false)
	v7_.dampingOffset = self.xmlFile:getValue("vehicle.attacherJointControl#dampingOffset", 2)
	v7_.nextHeightDampingUpdateTime = 0
	v7_.controls = {}
	v7_.nameToControl = {}
	local v8_ = 0
	while true do
		local v9_ = string.format("%s.control(%d)", "vehicle.attacherJointControl", v8_)
		if not self.xmlFile:hasProperty(v9_) then
			break
		end
		local v10_ = {}
		local v11_ = self.xmlFile:getValue(v9_ .. "#controlFunction")
		if v11_ == nil or self[v11_] == nil then
			Logging.xmlWarning(self.xmlFile, "Unknown control function \'%s\' for attacher joint control \'%s\'", tostring(v11_), v9_)
			break
		end
		v10_.func = self[v11_]
		if v10_.func == self.controlAttacherJointHeight then
			v7_.heightController = v10_
		end
		if v10_.func == self.controlAttacherJointTilt then
			v7_.tiltController = v10_
		end
		local v12_ = self.xmlFile:getValue(v9_ .. "#controlAxis")
		if v12_ == nil or InputAction[v12_] == nil then
			Logging.xmlWarning(self.xmlFile, "Unknown control axis \'%s\' for attacher joint control \'%s\'", tostring(v12_), v9_)
			break
		end
		v10_.controlAction = InputAction[v12_]
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, v9_ .. "#controlAxisIcon", v9_ .. "#iconName")
		local v13_ = self.xmlFile:getValue(v9_ .. "#iconName", "")
		if InputHelpElement.AXIS_ICON[v13_] == nil then
			v13_ = (self.customEnvironment or "") .. v13_
		end
		v10_.axisActionIcon = v13_
		v10_.invertAxis = self.xmlFile:getValue(v9_ .. "#invertControlAxis", false)
		v10_.mouseSpeedFactor = self.xmlFile:getValue(v9_ .. "#mouseSpeedFactor", 1)
		v10_.moveAlpha = 0
		v10_.moveAlphaSent = 0
		v10_.moveAlphaLastManual = 0
		v7_.nameToControl[v12_] = v10_
		local v14_ = v7_.controls
		table.insert(v14_, v10_)
		v8_ = v8_ + 1
	end
	if self.isClient then
		v7_.lastMoveTime = 0
		v7_.samples = {}
		v7_.samples.hydraulic = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.attacherJointControl.sounds", "hydraulic", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
	v7_.jointDesc = nil
	v7_.dirtyFlagClient = self:getNextDirtyFlag()
	v7_.dirtyFlagServer = self:getNextDirtyFlag()
	if #v7_.controls == 0 then
		SpecializationUtil.removeEventListener(self, "onReadStream", AttacherJointControl)
		SpecializationUtil.removeEventListener(self, "onWriteStream", AttacherJointControl)
		SpecializationUtil.removeEventListener(self, "onReadUpdateStream", AttacherJointControl)
		SpecializationUtil.removeEventListener(self, "onWriteUpdateStream", AttacherJointControl)
		SpecializationUtil.removeEventListener(self, "onUpdate", AttacherJointControl)
		SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", AttacherJointControl)
		SpecializationUtil.removeEventListener(self, "onPostAttach", AttacherJointControl)
		SpecializationUtil.removeEventListener(self, "onPreDetach", AttacherJointControl)
	end
end

-- Local values: spec
function AttacherJointControl:onDelete()
	local v16_ = self.spec_attacherJointControl
	if self.isClient and v16_.samples ~= nil then
		g_soundManager:deleteSample(v16_.samples.hydraulic)
	end
end

-- Local values: spec, _, control, moveAlpha
function AttacherJointControl:onReadStream(streamId, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		local v20_ = self.spec_attacherJointControl
		for _, v21_ in ipairs(v20_.controls) do
			self:controlAttacherJoint(v21_, streamReadUIntN(streamId, AttacherJointControl.ALPHA_NUM_BITS) / AttacherJointControl.ALPHA_MAX_VALUE, false, true)
		end
	end
end

-- Local values: spec, _, control
function AttacherJointControl:onWriteStream(streamId, connection)
	if not connection:getIsServer() then
		local v25_ = self.spec_attacherJointControl
		if streamWriteBool(streamId, v25_.jointDesc ~= nil) then
			for _, v26_ in ipairs(v25_.controls) do
				streamWriteUIntN(streamId, v26_.moveAlpha * AttacherJointControl.ALPHA_MAX_VALUE, AttacherJointControl.ALPHA_NUM_BITS)
			end
		end
	end
end

-- Local values: spec, _, control, moveAlpha, _, control, moveAlpha
function AttacherJointControl:onReadUpdateStream(streamId, timestamp, connection)
	local v30_ = self.spec_attacherJointControl
	if connection:getIsServer() then
		if streamReadBool(streamId) then
			for _, v31_ in ipairs(v30_.controls) do
				self:controlAttacherJoint(v31_, streamReadUIntN(streamId, AttacherJointControl.ALPHA_NUM_BITS) / AttacherJointControl.ALPHA_MAX_VALUE, false, true)
			end
		end
	elseif streamReadBool(streamId) then
		for _, v32_ in ipairs(v30_.controls) do
			self:controlAttacherJoint(v32_, streamReadUIntN(streamId, AttacherJointControl.ALPHA_NUM_BITS) / AttacherJointControl.ALPHA_MAX_VALUE, false, true)
		end
		return
	end
end

-- Local values: spec, _, control, _, control
function AttacherJointControl:onWriteUpdateStream(streamId, connection, dirtyMask)
	local v37_ = self.spec_attacherJointControl
	if connection:getIsServer() then
		local v38_ = streamWriteBool
		local v39_ = v37_.dirtyFlagClient
		if v38_(streamId, bit32.band(dirtyMask, v39_) ~= 0) then
			for _, v40_ in ipairs(v37_.controls) do
				streamWriteUIntN(streamId, v40_.moveAlpha * AttacherJointControl.ALPHA_MAX_VALUE, AttacherJointControl.ALPHA_NUM_BITS)
			end
			return
		end
	else
		local v41_ = streamWriteBool
		local v42_ = v37_.dirtyFlagServer
		if v41_(streamId, bit32.band(dirtyMask, v42_) ~= 0) then
			for _, v43_ in ipairs(v37_.controls) do
				streamWriteUIntN(streamId, v43_.moveAlpha * AttacherJointControl.ALPHA_MAX_VALUE, AttacherJointControl.ALPHA_NUM_BITS)
			end
		end
	end
end

-- Local values: spec, control, diff, moveTime, moveStep, newAlpha, inputJointDesc, delta, wX, wY, wZ, dirX, _, dirZ, posX, posY, posZ, _, vy, _
function AttacherJointControl:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v46_ = self.spec_attacherJointControl
	local v47_ = v46_.heightController
	if v47_ ~= nil and v46_.jointDesc ~= nil then
		if v46_.heightTargetAlpha ~= -1 then
			local v48_ = v46_.heightTargetAlpha - v47_.moveAlpha + 0.0001
			local v49_ = dt / (v48_ / (v46_.jointDesc.upperAlpha - v46_.jointDesc.lowerAlpha) * v46_.jointDesc.moveTime) * v48_
			if v48_ > 0 then
				v49_ = -v49_
			end
			local v50_ = v47_.moveAlpha + v49_
			self:controlAttacherJoint(v47_, v50_, v46_.nextHeightDampingUpdateTime < g_time, true)
			local v51_ = v46_.heightTargetAlpha - v50_
			if math.abs(v51_) < 0.01 then
				v46_.heightTargetAlpha = -1
			end
		end
		if self.isServer and (v46_.supportsDamping and v46_.nextHeightDampingUpdateTime < g_time) then
			local v52_ = self:getActiveInputAttacherJoint()
			local v53_ = 0
			if self:getIsAttacherJointControlDampingAllowed() then
				local v54_, v55_, v56_ = getWorldTranslation(v52_.node)
				local v57_, _, v58_ = localDirectionToWorld(v52_.node, v46_.dampingOffset, 0, 0)
				local v59_, v60_, v61_ = worldToLocal(self.components[1].node, v54_ + v57_, v55_, v56_ + v58_)
				local _, v62_, _ = getVelocityAtLocalPos(self.components[1].node, v59_, v60_, v61_)
				if math.abs(v62_) > 0.15 then
					v53_ = v62_ * 0.5
				end
			else
				v53_ = v47_.moveAlphaLastManual - v47_.moveAlpha
			end
			local v63_ = v53_ + (v47_.moveAlphaLastManual - v47_.moveAlpha) * 0.001 * dt
			if math.abs(v63_) > 0.0001 then
				local v64_ = v47_.moveAlpha + v63_
				v46_.heightTargetAlpha = math.clamp(v64_, 0, 1)
				if v46_.heightTargetAlpha <= 0 and v46_.tiltController ~= nil then
					local v65_ = v46_.tiltController
					local v66_ = v46_.tiltController.moveAlpha - v63_ * 0.1
					self:controlAttacherJoint(v65_, math.clamp(v66_, 0, 1), true)
				end
			end
		end
	end
	if v46_.lastMoveTime + 100 > g_time then
		if not g_soundManager:getIsSamplePlaying(v46_.samples.hydraulic) then
			g_soundManager:playSample(v46_.samples.hydraulic)
			return
		end
	elseif g_soundManager:getIsSamplePlaying(v46_.samples.hydraulic) then
		g_soundManager:stopSample(v46_.samples.hydraulic)
	end
end

-- Local values: spec, jointDesc, attacherVehicle
function AttacherJointControl:controlAttacherJoint(control, moveAlpha, automaticControl, noEventSend)
	local v72_ = self.spec_attacherJointControl
	local v73_ = v72_.jointDesc
	if self.isServer and v73_ ~= nil then
		moveAlpha = control.func(self, moveAlpha)
		self:getAttacherVehicle():updateAttacherJointRotation(v73_, self)
		if v73_.jointIndex ~= 0 then
			setJointFrame(v73_.jointIndex, 0, v73_.jointTransform)
		end
	end
	v72_.lastMoveTime = g_time
	if not automaticControl then
		v72_.nextHeightDampingUpdateTime = g_time + 100
		control.moveAlphaLastManual = control.moveAlpha
	end
	local v74_ = math.max(moveAlpha, 0)
	control.moveAlpha = math.min(v74_, 1)
	if noEventSend == nil or not noEventSend then
		local v75_ = control.moveAlphaSent - moveAlpha
		if math.abs(v75_) > 1 / AttacherJointControl.ALPHA_MAX_VALUE then
			control.moveAlphaSent = moveAlpha
			if self.isServer then
				self:raiseDirtyFlags(v72_.dirtyFlagServer)
			else
				self:raiseDirtyFlags(v72_.dirtyFlagClient)
			end
		end
	else
		control.moveAlphaSent = moveAlpha
	end
end

-- Local values: spec, jointDesc
function AttacherJointControl:controlAttacherJointHeight(moveAlpha)
	local v78_ = self.spec_attacherJointControl
	local v79_ = v78_.jointDesc
	if moveAlpha == nil then
		moveAlpha = v79_.moveAlpha
	end
	local v80_ = v79_.upperAlpha
	local v81_ = v79_.lowerAlpha
	local v82_ = math.clamp(moveAlpha, v80_, v81_)
	self:updateAttacherJointRotationNodes(v79_, v82_)
	v79_.moveAlpha = v82_
	self:updateAttacherJointRotation(v79_, self)
	v78_.lastHeightAlpha = v82_
	return v82_
end

-- Local values: spec, angle
function AttacherJointControl:controlAttacherJointTilt(moveAlpha)
	local v85_ = self.spec_attacherJointControl
	local v86_ = moveAlpha == nil and 0.5 or moveAlpha
	local v87_ = math.clamp(v86_, 0, 1)
	local v88_ = v85_.maxTiltAngle * -(v87_ - 0.5)
	v85_.jointDesc.upperRotationOffset = v85_.jointDesc.upperRotationOffsetBackup + v88_
	v85_.jointDesc.lowerRotationOffset = v85_.jointDesc.lowerRotationOffsetBackup + v88_
	return v87_
end

-- Local values: spec, lastAlpha
function AttacherJointControl:getControlAttacherJointDirection()
	local v90_ = self.spec_attacherJointControl
	if v90_.heightTargetAlpha ~= -1 then
		return v90_.heightTargetAlpha == v90_.jointDesc.upperAlpha
	end
	local v91_ = v90_.heightController.moveAlpha
	local v92_ = v91_ - v90_.jointDesc.lowerAlpha
	local v93_ = math.abs(v92_)
	local v94_ = v91_ - v90_.jointDesc.upperAlpha
	return math.abs(v94_) < v93_
end

-- Local values: attacherVehicle
function AttacherJointControl:getIsAttacherJointControlDampingAllowed()
	if self:getAttacherVehicle():getLastSpeed() < 0.5 then
		return false
	else
		return self.movingDirection > 0
	end
end

function AttacherJointControl:loadInputAttacherJoint(superFunc, xmlFile, key, inputAttacherJoint, i)
	if not superFunc(self, xmlFile, key, inputAttacherJoint, i) then
		return false
	end
	inputAttacherJoint.isControllable = xmlFile:getValue(key .. "#isControllable", false)
	return true
end

-- Local values: spec, _, actionEventId
function AttacherJointControl:registerLoweringActionEvent(superFunc, actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName)
	if self.spec_attacherJointControl.heightController then
		local _, v114_ = self:addPoweredActionEvent(actionEventsTable, InputAction.LOWER_IMPLEMENT, self, AttacherJointControl.actionEventAttacherJointControlSetPoint, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName)
		g_inputBinding:setActionEventTextPriority(v114_, GS_PRIO_HIGH)
		if inputAction == InputAction.LOWER_IMPLEMENT then
			return
		end
	end
	superFunc(self, actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName)
end

-- Local values: spec, showText, text
function AttacherJointControl:getLoweringActionEventState(superFunc)
	local v117_ = self.spec_attacherJointControl
	if not v117_.heightController then
		return superFunc(self)
	end
	local v118_ = v117_.jointDesc ~= nil
	local v119_
	if v118_ then
		if self:getControlAttacherJointDirection() then
			return v118_, string.format(g_i18n:getText("action_lowerOBJECT"), self.typeDesc)
		end
		v119_ = string.format(g_i18n:getText("action_liftOBJECT"), self.typeDesc)
	else
		v119_ = nil
	end
	return v118_, v119_
end

function AttacherJointControl:getCanBeSelected(superFunc)
	return true
end

-- Local values: spec, _, control, _, actionEventId
function AttacherJointControl:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v122_ = self.spec_attacherJointControl
		self:clearActionEventsTable(v122_.actionEvents)
		if isActiveForInputIgnoreSelection and v122_.jointDesc ~= nil then
			for _, v123_ in ipairs(v122_.controls) do
				local _, v124_ = self:addPoweredActionEvent(v122_.actionEvents, v123_.controlAction, self, AttacherJointControl.actionEventAttacherJointControl, false, false, true, true, nil, v123_.axisActionIcon)
				g_inputBinding:setActionEventTextPriority(v124_, GS_PRIO_NORMAL)
			end
		end
	end
end

-- Local values: spec, inputAttacherJoints, attacherJoints, jointDesc, _, control
function AttacherJointControl:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex, loadFromSavegame)
	local v130_ = self.spec_attacherJointControl
	local v131_ = self:getInputAttacherJoints()
	if v131_[inputJointDescIndex] ~= nil and v131_[inputJointDescIndex].isControllable then
		local v132_ = attacherVehicle:getAttacherJoints()[jointDescIndex]
		if v132_.upperAlpha == v132_.lowerAlpha then
			return
		end
		if v132_.allowsLoweringBackup == nil then
			v132_.allowsLoweringBackup = v132_.allowsLowering
		end
		v132_.allowsLowering = false
		v132_.upperRotationOffsetBackup = v132_.upperRotationOffset
		v132_.lowerRotationOffsetBackup = v132_.lowerRotationOffset
		v130_.jointDesc = v132_
		for _, v133_ in ipairs(v130_.controls) do
			v133_.moveAlpha = v133_.func(self)
		end
		if loadFromSavegame then
			if v130_.heightController ~= nil then
				self:controlAttacherJoint(v130_.heightController, v130_.jointDesc.upperAlpha, false)
			end
		else
			v130_.heightTargetAlpha = v130_.jointDesc.upperAlpha
		end
		self:requestActionEventUpdate()
	end
end

-- Local values: spec
function AttacherJointControl:onPreDetach(attacherVehicle, implement)
	local v135_ = self.spec_attacherJointControl
	if v135_.jointDesc ~= nil then
		v135_.jointDesc.allowsLowering = v135_.jointDesc.allowsLoweringBackup
		v135_.jointDesc.upperRotationOffset = v135_.jointDesc.upperRotationOffsetBackup
		v135_.jointDesc.lowerRotationOffset = v135_.jointDesc.lowerRotationOffsetBackup
		v135_.jointDesc = nil
	end
end

-- Local values: spec, control, changedAlpha
function AttacherJointControl:actionEventAttacherJointControl(actionName, inputValue, callbackState, isAnalog)
	if math.abs(inputValue) > 0 then
		local v139_ = self.spec_attacherJointControl
		local v140_ = v139_.nameToControl[actionName]
		local v141_ = inputValue * v140_.mouseSpeedFactor * 0.025
		if v140_.invertAxis then
			v141_ = -v141_
		end
		self:controlAttacherJoint(v140_, v140_.moveAlpha + v141_, false)
		v139_.heightTargetAlpha = -1
	end
end

-- Local values: spec
function AttacherJointControl:actionEventAttacherJointControlSetPoint(actionName, inputValue, callbackState, isAnalog)
	local v143_ = self.spec_attacherJointControl
	if v143_.jointDesc ~= nil then
		if self:getControlAttacherJointDirection() then
			v143_.heightTargetAlpha = v143_.jointDesc.lowerAlpha
		else
			v143_.heightTargetAlpha = v143_.jointDesc.upperAlpha
		end
		v143_.nextHeightDampingUpdateTime = g_time + v143_.jointDesc.moveTime
	end
end
