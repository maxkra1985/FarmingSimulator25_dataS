AdditionalToolConnections = {}

function AdditionalToolConnections.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(AttacherJoints, specializations) or SpecializationUtil.hasSpecialization(Attachable, specializations)
end
function AdditionalToolConnections.initSpecialization()
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("AdditionalToolConnections")
	v2_:register(XMLValueType.STRING, "vehicle.additionalToolConnections.connection(?)#id", "Identifier of the tool connection")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.additionalToolConnections.connection(?)#movingPartNode", "Node of movingPart to set the reference node to the connection node")
	ObjectChangeUtil.registerObjectChangeXMLPaths(v2_, "vehicle.additionalToolConnections.connection(?)")
	v2_:addDelayedRegistrationFunc("AttacherJoint", function(p3_, p4_)
		p3_:register(XMLValueType.STRING, p4_ .. ".additionalToolConnection(?)#id", "Identifier of the tool connection")
		p3_:register(XMLValueType.NODE_INDEX, p4_ .. ".additionalToolConnection(?)#node", "Node to connect to")
	end)
	v2_:setXMLSpecializationType()
end

function AdditionalToolConnections.registerFunctions(vehicleType) end

function AdditionalToolConnections.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAttacherJointFromXML", AdditionalToolConnections.loadAttacherJointFromXML)
end

function AdditionalToolConnections.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AdditionalToolConnections)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", AdditionalToolConnections)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", AdditionalToolConnections)
end

-- Local values: spec
function AdditionalToolConnections:onPostLoad(savegame)
	local v_u_8_ = self.spec_additionalToolConnections
	v_u_8_.additionalToolConnections = {}
	self.xmlFile:iterate("vehicle.additionalToolConnections.connection", function(_, p9_)
		-- upvalues: (copy) self, (copy) v_u_8_
		local v10_ = self.xmlFile:getValue(p9_ .. "#id")
		local v11_ = self.xmlFile:getValue(p9_ .. "#movingPartNode", nil, self.components, self.i3dMappings)
		if v10_ == nil or v11_ == nil then
			Logging.xmlWarning(self.xmlFile, "Failed to load additionalToolConnection \'%s\'", p9_)
			return
		elseif self:getMovingPartByNode(v11_) == nil then
			Logging.xmlWarning(self.xmlFile, "Failed to find moving part for \'%s\' in \'%s\'", getName(v11_), p9_)
		else
			local v12_ = {
				["id"] = v10_,
				["movingPartNode"] = v11_,
				["objectChanges"] = {}
			}
			ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, p9_, v12_.objectChanges, self.components, self)
			ObjectChangeUtil.setObjectChanges(v12_.objectChanges, false, self, self.setMovingToolDirty)
			local v13_ = v_u_8_.additionalToolConnections
			table.insert(v13_, v12_)
		end
	end)
end
function AdditionalToolConnections.loadAttacherJointFromXML(p_u_14_, p15_, p_u_16_, p_u_17_, p18_, p19_, ...)
	if not p15_(p_u_14_, p_u_16_, p_u_17_, p18_, p19_, ...) then
		return false
	end
	p_u_16_.additionalToolConnections = p_u_16_.additionalToolConnections or {}
	p_u_17_:iterate(p18_ .. ".additionalToolConnection", function(_, p20_)
		-- upvalues: (copy) p_u_17_, (copy) p_u_14_, (copy) p_u_16_
		local v21_ = p_u_17_:getValue(p20_ .. "#id")
		local v22_ = p_u_17_:getValue(p20_ .. "#node", nil, p_u_14_.components, p_u_14_.i3dMappings)
		if v21_ == nil or v22_ == nil then
			Logging.xmlWarning(p_u_17_, "Failed to load additionalToolConnection \'%s\'", p20_)
		else
			p_u_16_.additionalToolConnections[v21_] = v22_
		end
	end)
	return true
end

-- Local values: spec, jointDesc, i, connection, node
function AdditionalToolConnections:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex, loadFromSavegame)
	local v26_ = self.spec_additionalToolConnections
	local v27_ = attacherVehicle:getAttacherJointByJointDescIndex(jointDescIndex)
	if v27_.additionalToolConnections ~= nil then
		for v28_ = 1, #v26_.additionalToolConnections do
			local v29_ = v26_.additionalToolConnections[v28_]
			local v30_ = v27_.additionalToolConnections[v29_.id]
			if v30_ ~= nil then
				self:setMovingPartReferenceNode(v29_.movingPartNode, v30_, true)
				ObjectChangeUtil.setObjectChanges(v29_.objectChanges, true, self, self.setMovingToolDirty)
			end
		end
	end
end

-- Local values: spec, i, connection
function AdditionalToolConnections:onPreDetach(attacherVehicle, implement)
	local v32_ = self.spec_additionalToolConnections
	for v33_ = 1, #v32_.additionalToolConnections do
		local v34_ = v32_.additionalToolConnections[v33_]
		self:setMovingPartReferenceNode(v34_.movingPartNode, nil, false)
		ObjectChangeUtil.setObjectChanges(v34_.objectChanges, false, self, self.setMovingToolDirty)
	end
end
