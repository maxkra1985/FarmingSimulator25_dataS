SupportVehicle = {}
function SupportVehicle.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(AttacherJoints, specializations) and SpecializationUtil.hasSpecialization(Mountable, specializations)
end
function SupportVehicle.initSpecialization()
	local schema = Vehicle.xmlSchema
	schema:setXMLSpecializationType("SupportVehicle")
	schema:register(XMLValueType.STRING, "vehicle.supportVehicle#filename", "Path to support vehicle xml")
	schema:register(XMLValueType.INT, "vehicle.supportVehicle#attacherJointIndex", "Attacher joint index on support vehicle", 1)
	schema:register(XMLValueType.INT, "vehicle.supportVehicle#inputAttacherJointIndex", "Input attacher joint index on own vehicle", 1)
	schema:register(XMLValueType.FLOAT, "vehicle.supportVehicle#terrainOffset", "Spawn Offset from terrain for the support vehicle", 0.2)
	schema:register(XMLValueType.FLOAT, "vehicle.supportVehicle#spawnOffset", "Tool will be moved this distance away in X direction of the attacher joint", 0.75)
	schema:register(XMLValueType.STRING, "vehicle.supportVehicle.configuration(?)#name", "Configuration name")
	schema:register(XMLValueType.INT, "vehicle.supportVehicle.configuration(?)#id", "Configuration id")
	schema:setXMLSpecializationType()
end
function SupportVehicle.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "addSupportVehicle", SupportVehicle.addSupportVehicle)
	SpecializationUtil.registerFunction(vehicleType, "enableSupportVehicle", SupportVehicle.enableSupportVehicle)
	SpecializationUtil.registerFunction(vehicleType, "removeSupportVehicle", SupportVehicle.removeSupportVehicle)
end
function SupportVehicle.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowMultipleAttachments", SupportVehicle.getAllowMultipleAttachments)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "resolveMultipleAttachments", SupportVehicle.resolveMultipleAttachments)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getShowAttachableMapHotspot", SupportVehicle.getShowAttachableMapHotspot)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsReadyToFinishDetachProcess", SupportVehicle.getIsReadyToFinishDetachProcess)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "startDetachProcess", SupportVehicle.startDetachProcess)
end
function SupportVehicle.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", SupportVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", SupportVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", SupportVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onPostDetach", SupportVehicle)
end
function SupportVehicle:onLoad(savegame)
	local spec = self.spec_supportVehicle
	local baseKey = "vehicle.supportVehicle"
	spec.attacherJointIndex = self.xmlFile:getValue("vehicle.supportVehicle" .. "#attacherJointIndex", 1)
	spec.inputAttacherJointIndex = self.xmlFile:getValue("vehicle.supportVehicle" .. "#inputAttacherJointIndex", 1)
	spec.terrainOffset = self.xmlFile:getValue("vehicle.supportVehicle" .. "#terrainOffset", 0.2)
	spec.spawnOffset = self.xmlFile:getValue("vehicle.supportVehicle" .. "#spawnOffset", 0.75)
	spec.heightChecks = {}
	local filename = self.xmlFile:getValue("vehicle.supportVehicle" .. "#filename")
	if filename ~= nil then
		spec.filename = Utils.getFilename(filename, self.customEnvironment)
		local storeItem = g_storeManager:getItemByXMLFilename(spec.filename)
		if storeItem ~= nil then
			spec.storeItem = storeItem
			local size = StoreItemUtil.getSizeValues(storeItem.xmlFilename, "vehicle", storeItem.rotation)
			table.insert(spec.heightChecks, { size.width / 2 + size.widthOffset, size.length / 2 + size.lengthOffset })
			table.insert(spec.heightChecks, { -size.width / 2 + size.widthOffset, size.length / 2 + size.lengthOffset })
			table.insert(spec.heightChecks, { size.width / 2 + size.widthOffset, -size.length / 2 + size.lengthOffset })
			table.insert(spec.heightChecks, { -size.width / 2 + size.widthOffset, -size.length / 2 + size.lengthOffset })
		else
			Logging.xmlWarning(self.xmlFile, "Unable to find support vehicle '%s'.", filename)
			spec.filename = nil
		end
	end
	spec.configurations = {}
	local i = 0
	while true do
		local configurationKey = string.format("%s.configuration(%d)", "vehicle.supportVehicle", i)
		if not self.xmlFile:hasProperty(configurationKey) then
			break
		end
		local name = self.xmlFile:getValue(configurationKey .. "#name")
		local id = self.xmlFile:getValue(configurationKey .. "#id")
		if name ~= nil and id ~= nil then
			spec.configurations[name] = id
		end
		i = i + 1
	end
	spec.firstRun = true
	spec.loadedSupportVehicle = nil
	spec.isLoadingSupportVehicle = false
	if not self.isServer or spec.storeItem == nil then
		SpecializationUtil.removeEventListener(self, "onDelete", SupportVehicle)
		SpecializationUtil.removeEventListener(self, "onUpdate", SupportVehicle)
		SpecializationUtil.removeEventListener(self, "onPostDetach", SupportVehicle)
	end
end
function SupportVehicle:onDelete()
	if not self.isReconfigurating then
		self:removeSupportVehicle()
	end
end
function SupportVehicle:onPostDetach(attacherVehicle, implement)
	self:enableSupportVehicle()
end
function SupportVehicle:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_supportVehicle
	if spec.firstRun and not g_currentMission.vehicleSystem.isReloadRunning then
		if self:getAttacherVehicle() == nil then
			self:addSupportVehicle(false)
		elseif spec.supportVehicle == nil then
			local attacherVehicle = self:getAttacherVehicle()
			if attacherVehicle.configFileName == spec.filename then
				spec.supportVehicle = attacherVehicle
				spec.supportVehicle:setIsSupportVehicle()
				self:setReducedComponentMass(true)
			end
		end
		spec.firstRun = false
	end
end
function SupportVehicle:addSupportVehicle(isDetach)
	local spec = self.spec_supportVehicle
	if spec.storeItem ~= nil and (spec.supportVehicle == nil and (not spec.isLoadingSupportVehicle and spec.loadedSupportVehicle == nil)) then
		local inputAttacherJoint = self:getInputAttacherJointByJointDescIndex(spec.inputAttacherJointIndex)
		if inputAttacherJoint ~= nil then
			local x, y, z = getWorldTranslation(inputAttacherJoint.node)
			if isDetach == true then
				local dirX, _, dirZ = localDirectionToWorld(inputAttacherJoint.node, 1, 0, 0)
				x = x + dirX * spec.spawnOffset
				z = z + dirZ * spec.spawnOffset
			end
			y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + spec.terrainOffset
			local xRot, yRot, zRot = localRotationToWorld(inputAttacherJoint.node, -3.141592653589793, 0, -3.141592653589793)
			spec.isLoadingSupportVehicle = true
			local data = VehicleLoadingData.new()
			data:setStoreItem(spec.storeItem)
			data:setPosition(x, y, z)
			data:setRotation(xRot, yRot, zRot)
			data:setPropertyState(VehiclePropertyState.NONE)
			data:setOwnerFarmId(self:getActiveFarm())
			data:setConfigurations(spec.configurations)
			data:load(SupportVehicle.supportVehicleLoaded, self, { isDetach = isDetach })
		end
	end
end
function SupportVehicle:supportVehicleLoaded(vehicles, vehicleLoadState, asyncCallbackArguments)
	local spec = self.spec_supportVehicle
	if vehicleLoadState == VehicleLoadingState.OK and 0 < #vehicles then
		if not self.isDeleted then
			spec.loadedSupportVehicle = vehicles[1]
			if asyncCallbackArguments.isDetach ~= true then
				self:enableSupportVehicle()
			end
		else
			for _, vehicle in ipairs(vehicles) do
				vehicle:delete()
			end
		end
	end
	spec.isLoadingSupportVehicle = false
end
function SupportVehicle:enableSupportVehicle()
	local spec = self.spec_supportVehicle
	if spec.loadedSupportVehicle ~= nil then
		local vehicle = spec.loadedSupportVehicle
		spec.loadedSupportVehicle = nil
		vehicle:setIsSupportVehicle()
		self:setReducedComponentMass(true)
		local inputAttacherJoint = self:getInputAttacherJointByJointDescIndex(spec.inputAttacherJointIndex)
		if inputAttacherJoint ~= nil then
			local offset = inputAttacherJoint.jointOrigOffsetComponent
			local rotOffset = inputAttacherJoint.jointOrigRotOffsetComponent
			if vehicle.getAttacherJointByJointDescIndex ~= nil then
				local attacherJoint = vehicle:getAttacherJointByJointDescIndex(spec.attacherJointIndex)
				if attacherJoint ~= nil then
					local x, y, z = getWorldTranslation(vehicle.rootNode)
					local rx, ry, rz = getWorldRotation(vehicle.rootNode)
					local ox, oy, oz = localDirectionToWorld(vehicle.rootNode, attacherJoint.jointOrigOffsetComponent[1], 0, attacherJoint.jointOrigOffsetComponent[3])
					x = x - ox
					y = y - oy
					z = z - oz
					y = math.max(getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + spec.terrainOffset, y)
					vehicle:removeFromPhysics()
					vehicle:setAbsolutePosition(x, y, z, rx, ry, rz)
					vehicle:addToPhysics()
					x, y, z = localToWorld(attacherJoint.jointTransform, unpack(offset))
					rx, ry, rz = localRotationToWorld(attacherJoint.jointTransform, unpack(rotOffset))
					self:removeFromPhysics()
					self:setAbsolutePosition(x, y, z, rx, ry, rz)
					self:addToPhysics()
					vehicle:attachImplement(self, spec.inputAttacherJointIndex, spec.attacherJointIndex, true, nil, nil, true)
					self.rootVehicle:updateSelectableObjects()
					self.rootVehicle:setSelectedVehicle(self)
					spec.supportVehicle = vehicle
					return
				end
			end
		end
		vehicle:delete()
	end
end
function SupportVehicle:removeSupportVehicle()
	local spec = self.spec_supportVehicle
	if spec.supportVehicle ~= nil and not spec.supportVehicle.isDeleted then
		spec.supportVehicle:delete()
	end
	spec.supportVehicle = nil
	if self.isServer and self.components ~= nil then
		self:setReducedComponentMass(false)
	end
end
function SupportVehicle:getAllowMultipleAttachments(superFunc)
	return self.spec_supportVehicle.filename ~= nil
end
function SupportVehicle:resolveMultipleAttachments(superFunc)
	if self.isServer then
		self:removeSupportVehicle()
	end
	superFunc(self)
end
function SupportVehicle:getShowAttachableMapHotspot(superFunc)
	if self.spec_supportVehicle.supportVehicle ~= nil then
		return self.spec_supportVehicle.supportVehicle:getAttacherVehicle() == nil
	else
		return superFunc(self)
	end
end
function SupportVehicle:getIsReadyToFinishDetachProcess(superFunc)
	local spec = self.spec_supportVehicle
	return superFunc(self) and not not spec.isLoadingSupportVehicle and spec.loadedSupportVehicle ~= nil
end
function SupportVehicle:startDetachProcess(superFunc, noEventSend)
	if not self.isDeleting then
		self:addSupportVehicle(true)
	end
	return superFunc(self, noEventSend)
end
