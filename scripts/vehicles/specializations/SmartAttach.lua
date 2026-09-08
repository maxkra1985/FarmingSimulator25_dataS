-- Local values: SmartAttachActivatable_mt, SmartAttachEvent_mt
SmartAttach = {}
SmartAttach.DISTANCE_THRESHOLD = 3.5
SmartAttach.ABS_ANGLE_THRESHOLD = 0.3490658503988659

function SmartAttach.prerequisitesPresent(specializations)
	return true
end
function SmartAttach.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("SmartAttach")
	v1_:register(XMLValueType.STRING, "vehicle.smartAttach#jointType", "Joint type name")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.smartAttach#trigger", "Trigger node")
	v1_:setXMLSpecializationType()
end

function SmartAttach.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "smartAttachCallback", SmartAttach.smartAttachCallback)
	SpecializationUtil.registerFunction(vehicleType, "getCanBeSmartAttached", SmartAttach.getCanBeSmartAttached)
	SpecializationUtil.registerFunction(vehicleType, "doSmartAttach", SmartAttach.doSmartAttach)
end

function SmartAttach.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", SmartAttach)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", SmartAttach)
	SpecializationUtil.registerEventListener(vehicleType, "onPreAttach", SmartAttach)
end

-- Local values: spec, jointTypeStr, jointType, inputJointDescIndex, inputAttacherJoint, triggerNode
function SmartAttach:onLoad(savegame)
	local v5_ = self.spec_smartAttach
	v5_.inputJointDescIndex = nil
	local v6_ = self.xmlFile:getValue("vehicle.smartAttach#jointType")
	if v6_ ~= nil then
		local v7_ = AttacherJoints.jointTypeNameToInt[v6_]
		if v7_ == nil then
			printWarning("Warning: invalid jointType " .. v6_)
		else
			for v8_, v9_ in pairs(self:getInputAttacherJoints()) do
				if v9_.jointType == v7_ then
					v5_.inputJointDescIndex = v8_
					break
				end
			end
			v5_.jointType = v7_
			if v5_.inputJointDescIndex == nil then
				printWarning("Warning: SmartAttach jointType not defined in \'" .. self.configFileName .. "\'!")
			end
		end
	end
	local v10_ = self.xmlFile:getValue("vehicle.smartAttach#trigger", nil, self.components, self.i3dMappings)
	if v10_ ~= nil then
		v5_.trigger = v10_
		addTrigger(v5_.trigger, "smartAttachCallback", self)
	end
	v5_.targetVehicle = nil
	v5_.targetVehicleCount = 0
	v5_.jointDescIndex = nil
	v5_.activatable = SmartAttachActivatable.new(self)
end

-- Local values: spec
function SmartAttach:onDelete()
	local v12_ = self.spec_smartAttach
	if v12_.activatable ~= nil then
		g_currentMission.activatableObjectsSystem:removeActivatable(v12_.activatable)
		v12_.activatable = nil
	end
	if v12_.trigger ~= nil then
		removeTrigger(v12_.trigger)
		v12_.trigger = nil
	end
end

-- Local values: attacherVehicle
function SmartAttach:doSmartAttach(targetVehicle, inputJointDescIndex, jointDescIndex, noEventSend)
	SmartAttachEvent.sendEvent(self, targetVehicle, inputJointDescIndex, jointDescIndex, noEventSend)
	if self.isServer then
		local v18_ = self:getAttacherVehicle()
		if v18_ ~= nil then
			v18_:detachImplementByObject(self)
		end
		targetVehicle:attachImplement(self, inputJointDescIndex, jointDescIndex, false)
	end
end

-- Local values: spec, targetVehicle, activeForInput, attacherJoint, inputAttacherJoint, x1, _, z1, x2, _, z2, distance, yRot
function SmartAttach:getCanBeSmartAttached()
	local v20_ = self.spec_smartAttach
	local v21_ = v20_.targetVehicle
	if v21_ == nil then
		return false
	end
	if not (self:getIsActiveForInput(true) or v20_.targetVehicle:getIsActiveForInput(true)) then
		return false
	end
	local v22_ = v21_:getAttacherJoints()[v20_.jointDescIndex].jointTransform
	local v23_ = self:getInputAttacherJoints()[v20_.inputJointDescIndex].node
	local v24_, _, v25_ = getWorldTranslation(v22_)
	local v26_, _, v27_ = getWorldTranslation(v23_)
	local v28_ = MathUtil.vector2Length(v24_ - v26_, v25_ - v27_)
	local v29_ = Utils.getYRotationBetweenNodes(v22_, v23_)
	local v30_
	if v28_ < SmartAttach.DISTANCE_THRESHOLD then
		v30_ = math.abs(v29_) < SmartAttach.ABS_ANGLE_THRESHOLD
	else
		v30_ = false
	end
	return v30_
end

-- Local values: spec
function SmartAttach:onPreAttach()
	local v32_ = self.spec_smartAttach
	v32_.targetVehicle = nil
	v32_.targetVehicleCount = 0
end

-- Local values: spec, vehicle, i, jointDesc, name, storeItem, object
function SmartAttach:smartAttachCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	local v37_ = self.spec_smartAttach
	if onEnter then
		local v38_ = g_currentMission.nodeToObject[otherActorId]
		if v38_ ~= nil then
			if v37_.targetVehicle == nil and (v38_ ~= nil and (v38_ ~= self and v38_.getAttacherJoints ~= nil)) then
				for v39_, v40_ in ipairs(v38_:getAttacherJoints()) do
					if v40_.jointIndex == 0 and v40_.jointType == v37_.jointType then
						v37_.targetVehicle = v38_
						v37_.jointDescIndex = v39_
						v37_.targetVehicleCount = 0
						local v41_ = Utils.getNoNil(self.typeDesc, "")
						local v42_ = g_storeManager:getItemByXMLFilename(string.lower(self.configFileName))
						if v42_ ~= nil then
							v41_ = v42_.name
						end
						if self:getAttacherVehicle() == nil then
							v37_.activatable.activateText = string.format(g_i18n:getText("action_doSmartAttachGround", self.customEnvironment), v41_)
						else
							v37_.activatable.activateText = string.format(g_i18n:getText("action_doSmartAttachTransform", self.customEnvironment), v41_)
						end
						g_currentMission.activatableObjectsSystem:addActivatable(v37_.activatable)
						break
					end
				end
			end
			if v38_ == v37_.targetVehicle then
				v37_.targetVehicleCount = v37_.targetVehicleCount + 1
				return
			end
		end
	elseif onLeave and v37_.targetVehicle ~= nil then
		local v43_ = g_currentMission.nodeToObject[otherActorId]
		if v43_ ~= nil and v43_ == v37_.targetVehicle then
			v37_.targetVehicleCount = v37_.targetVehicleCount - 1
			if v37_.targetVehicleCount <= 0 then
				v37_.targetVehicle = nil
				g_currentMission.activatableObjectsSystem:removeActivatable(v37_.activatable)
				v37_.targetVehicleCount = 0
			end
		end
	end
end
SmartAttachActivatable = {}
local v_u_44_ = Class(SmartAttachActivatable)

-- Upvalues: SmartAttachActivatable_mt
-- Local values: self
function SmartAttachActivatable.new(smartAttachVehicle)
	-- upvalues: (copy) v_u_44_
	local v46_ = v_u_44_
	local v47_ = setmetatable({}, v46_)
	v47_.smartAttachVehicle = smartAttachVehicle
	v47_.activateText = ""
	return v47_
end

function SmartAttachActivatable:getIsActivatable()
	return self.smartAttachVehicle:getCanBeSmartAttached()
end

-- Local values: vehicle, spec
function SmartAttachActivatable:run()
	local v50_ = self.smartAttachVehicle
	local v51_ = v50_.spec_smartAttach
	v50_:doSmartAttach(v51_.targetVehicle, v51_.inputJointDescIndex, v51_.jointDescIndex)
end
SmartAttachEvent = {}
local v_u_52_ = Class(SmartAttachEvent, Event)
InitStaticEventClass(SmartAttachEvent, "SmartAttachEvent")
function SmartAttachEvent.emptyNew()
	-- upvalues: (copy) v_u_52_
	return Event.new(v_u_52_)
end
function SmartAttachEvent.new(p53_, p54_, p55_, p56_)
	local v57_ = SmartAttachEvent.emptyNew()
	v57_.vehicle = p53_
	v57_.targetVehicle = p54_
	v57_.inputJointDescIndex = p55_
	v57_.jointDescIndex = p56_
	return v57_
end

function SmartAttachEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.targetVehicle = NetworkUtil.readNodeObject(streamId)
	self.inputJointDescIndex = streamReadUIntN(streamId, 7)
	self.jointDescIndex = streamReadUIntN(streamId, 7)
	self:run(connection)
end

function SmartAttachEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	NetworkUtil.writeNodeObject(streamId, self.targetVehicle)
	streamWriteUIntN(streamId, self.inputJointDescIndex, 7)
	streamWriteUIntN(streamId, self.jointDescIndex, 7)
end

function SmartAttachEvent:run(connection)
	self.vehicle:doSmartAttach(self.targetVehicle, self.inputJointDescIndex, self.jointDescIndex, true)
	if not connection:getIsServer() then
		g_server:broadcastEvent(SmartAttachEvent.new(self.vehicle, self.targetVehicle, self.inputJointDescIndex, self.jointDescIndex), nil, connection, self.vehicle)
	end
end

function SmartAttachEvent.sendEvent(vehicle, targetVehicle, inputJointDescIndex, jointDescIndex, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(SmartAttachEvent.new(vehicle, targetVehicle, inputJointDescIndex, jointDescIndex), nil, nil, vehicle)
			return
		end
		g_client:getServerConnection():sendEvent(SmartAttachEvent.new(vehicle, targetVehicle, inputJointDescIndex, jointDescIndex))
	end
end
