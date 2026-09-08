SupportVehicle = {}

function SupportVehicle.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(AttacherJoints, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(Mountable, specializations)
	end
	return v2_
end
function SupportVehicle.initSpecialization()
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("SupportVehicle")
	v3_:register(XMLValueType.STRING, "vehicle.supportVehicle#filename", "Path to support vehicle xml")
	v3_:register(XMLValueType.INT, "vehicle.supportVehicle#attacherJointIndex", "Attacher joint index on support vehicle", 1)
	v3_:register(XMLValueType.INT, "vehicle.supportVehicle#inputAttacherJointIndex", "Input attacher joint index on own vehicle", 1)
	v3_:register(XMLValueType.FLOAT, "vehicle.supportVehicle#terrainOffset", "Spawn Offset from terrain for the support vehicle", 0.2)
	v3_:register(XMLValueType.FLOAT, "vehicle.supportVehicle#spawnOffset", "Tool will be moved this distance away in X direction of the attacher joint", 0.75)
	v3_:register(XMLValueType.STRING, "vehicle.supportVehicle.configuration(?)#name", "Configuration name")
	v3_:register(XMLValueType.INT, "vehicle.supportVehicle.configuration(?)#id", "Configuration id")
	v3_:setXMLSpecializationType()
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

-- Local values: spec, baseKey, filename, storeItem, size, i, configurationKey, name, id
function SupportVehicle:onLoad(savegame)
	local v8_ = self.spec_supportVehicle
	v8_.attacherJointIndex = self.xmlFile:getValue("vehicle.supportVehicle#attacherJointIndex", 1)
	v8_.inputAttacherJointIndex = self.xmlFile:getValue("vehicle.supportVehicle#inputAttacherJointIndex", 1)
	v8_.terrainOffset = self.xmlFile:getValue("vehicle.supportVehicle#terrainOffset", 0.2)
	v8_.spawnOffset = self.xmlFile:getValue("vehicle.supportVehicle#spawnOffset", 0.75)
	v8_.heightChecks = {}
	local v9_ = self.xmlFile:getValue("vehicle.supportVehicle#filename")
	if v9_ ~= nil then
		v8_.filename = Utils.getFilename(v9_, self.customEnvironment)
		local v10_ = g_storeManager:getItemByXMLFilename(v8_.filename)
		if v10_ == nil then
			Logging.xmlWarning(self.xmlFile, "Unable to find support vehicle \'%s\'.", v9_)
			v8_.filename = nil
		else
			v8_.storeItem = v10_
			local v11_ = StoreItemUtil.getSizeValues(v10_.xmlFilename, "vehicle", v10_.rotation)
			local v12_ = v8_.heightChecks
			local v13_ = { v11_.width / 2 + v11_.widthOffset, v11_.length / 2 + v11_.lengthOffset }
			table.insert(v12_, v13_)
			local v14_ = v8_.heightChecks
			local v15_ = { -v11_.width / 2 + v11_.widthOffset, v11_.length / 2 + v11_.lengthOffset }
			table.insert(v14_, v15_)
			local v16_ = v8_.heightChecks
			local v17_ = { v11_.width / 2 + v11_.widthOffset, -v11_.length / 2 + v11_.lengthOffset }
			table.insert(v16_, v17_)
			local v18_ = v8_.heightChecks
			local v19_ = { -v11_.width / 2 + v11_.widthOffset, -v11_.length / 2 + v11_.lengthOffset }
			table.insert(v18_, v19_)
		end
	end
	v8_.configurations = {}
	local v20_ = 0
	while true do
		local v21_ = string.format("%s.configuration(%d)", "vehicle.supportVehicle", v20_)
		if not self.xmlFile:hasProperty(v21_) then
			break
		end
		local v22_ = self.xmlFile:getValue(v21_ .. "#name")
		local v23_ = self.xmlFile:getValue(v21_ .. "#id")
		if v22_ ~= nil and v23_ ~= nil then
			v8_.configurations[v22_] = v23_
		end
		v20_ = v20_ + 1
	end
	v8_.firstRun = true
	v8_.loadedSupportVehicle = nil
	v8_.isLoadingSupportVehicle = false
	if not self.isServer or v8_.storeItem == nil then
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

-- Local values: spec, attacherVehicle
function SupportVehicle:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v27_ = self.spec_supportVehicle
	if v27_.firstRun and not g_currentMission.vehicleSystem.isReloadRunning then
		if self:getAttacherVehicle() == nil then
			self:addSupportVehicle(false)
		elseif v27_.supportVehicle == nil then
			local v28_ = self:getAttacherVehicle()
			if v28_.configFileName == v27_.filename then
				v27_.supportVehicle = v28_
				v27_.supportVehicle:setIsSupportVehicle()
				self:setReducedComponentMass(true)
			end
		end
		v27_.firstRun = false
	end
end

-- Local values: spec, inputAttacherJoint, x, y, z, dirX, _, dirZ, xRot, yRot, zRot, data
function SupportVehicle:addSupportVehicle(isDetach)
	local v31_ = self.spec_supportVehicle
	if v31_.storeItem ~= nil and (v31_.supportVehicle == nil and (not v31_.isLoadingSupportVehicle and v31_.loadedSupportVehicle == nil)) then
		local v32_ = self:getInputAttacherJointByJointDescIndex(v31_.inputAttacherJointIndex)
		if v32_ ~= nil then
			local v33_, _, v34_ = getWorldTranslation(v32_.node)
			if isDetach == true then
				local v35_, _, v36_ = localDirectionToWorld(v32_.node, 1, 0, 0)
				v33_ = v33_ + v35_ * v31_.spawnOffset
				v34_ = v34_ + v36_ * v31_.spawnOffset
			end
			local v37_ = getTerrainHeightAtWorldPos(g_terrainNode, v33_, 0, v34_) + v31_.terrainOffset
			local v38_, v39_, v40_ = localRotationToWorld(v32_.node, -3.141592653589793, 0, -3.141592653589793)
			v31_.isLoadingSupportVehicle = true
			local v41_ = VehicleLoadingData.new()
			v41_:setStoreItem(v31_.storeItem)
			v41_:setPosition(v33_, v37_, v34_)
			v41_:setRotation(v38_, v39_, v40_)
			v41_:setPropertyState(VehiclePropertyState.NONE)
			v41_:setOwnerFarmId(self:getActiveFarm())
			v41_:setConfigurations(v31_.configurations)
			v41_:load(SupportVehicle.supportVehicleLoaded, self, {
				["isDetach"] = isDetach
			})
		end
	end
end

-- Local values: spec, _, vehicle
function SupportVehicle:supportVehicleLoaded(vehicles, vehicleLoadState, asyncCallbackArguments)
	local v46_ = self.spec_supportVehicle
	if vehicleLoadState == VehicleLoadingState.OK and #vehicles > 0 then
		if self.isDeleted then
			for _, v47_ in ipairs(vehicles) do
				v47_:delete()
			end
		else
			v46_.loadedSupportVehicle = vehicles[1]
			if asyncCallbackArguments.isDetach ~= true then
				self:enableSupportVehicle()
			end
		end
	end
	v46_.isLoadingSupportVehicle = false
end

-- Local values: spec, vehicle, inputAttacherJoint, offset, rotOffset, attacherJoint, x, y, z, rx, ry, rz, ox, oy, oz
function SupportVehicle:enableSupportVehicle()
	local v49_ = self.spec_supportVehicle
	if v49_.loadedSupportVehicle ~= nil then
		local v50_ = v49_.loadedSupportVehicle
		v49_.loadedSupportVehicle = nil
		v50_:setIsSupportVehicle()
		self:setReducedComponentMass(true)
		local v51_ = self:getInputAttacherJointByJointDescIndex(v49_.inputAttacherJointIndex)
		if v51_ ~= nil then
			local v52_ = v51_.jointOrigOffsetComponent
			local v53_ = v51_.jointOrigRotOffsetComponent
			if v50_.getAttacherJointByJointDescIndex ~= nil then
				local v54_ = v50_:getAttacherJointByJointDescIndex(v49_.attacherJointIndex)
				if v54_ ~= nil then
					local v55_, v56_, v57_ = getWorldTranslation(v50_.rootNode)
					local v58_, v59_, v60_ = getWorldRotation(v50_.rootNode)
					local v61_, v62_, v63_ = localDirectionToWorld(v50_.rootNode, v54_.jointOrigOffsetComponent[1], 0, v54_.jointOrigOffsetComponent[3])
					local v64_ = v55_ - v61_
					local v65_ = v56_ - v62_
					local v66_ = v57_ - v63_
					local v67_ = getTerrainHeightAtWorldPos(g_terrainNode, v64_, 0, v66_) + v49_.terrainOffset
					local v68_ = math.max(v67_, v65_)
					v50_:removeFromPhysics()
					v50_:setAbsolutePosition(v64_, v68_, v66_, v58_, v59_, v60_)
					v50_:addToPhysics()
					local v69_, v70_, v71_ = localToWorld(v54_.jointTransform, unpack(v52_))
					local v72_, v73_, v74_ = localRotationToWorld(v54_.jointTransform, unpack(v53_))
					self:removeFromPhysics()
					self:setAbsolutePosition(v69_, v70_, v71_, v72_, v73_, v74_)
					self:addToPhysics()
					v50_:attachImplement(self, v49_.inputAttacherJointIndex, v49_.attacherJointIndex, true, nil, nil, true)
					self.rootVehicle:updateSelectableObjects()
					self.rootVehicle:setSelectedVehicle(self)
					v49_.supportVehicle = v50_
					return
				end
			end
		end
		v50_:delete()
	end
end

-- Local values: spec
function SupportVehicle:removeSupportVehicle()
	local v76_ = self.spec_supportVehicle
	if v76_.supportVehicle ~= nil and not v76_.supportVehicle.isDeleted then
		v76_.supportVehicle:delete()
	end
	v76_.supportVehicle = nil
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
	if self.spec_supportVehicle.supportVehicle == nil then
		return superFunc(self)
	else
		return self.spec_supportVehicle.supportVehicle:getAttacherVehicle() == nil
	end
end

-- Local values: spec
function SupportVehicle:getIsReadyToFinishDetachProcess(superFunc)
	local v84_ = self.spec_supportVehicle
	return not (superFunc(self) and v84_.isLoadingSupportVehicle) or v84_.loadedSupportVehicle ~= nil
end

function SupportVehicle:startDetachProcess(superFunc, noEventSend)
	if not self.isDeleting then
		self:addSupportVehicle(true)
	end
	return superFunc(self, noEventSend)
end
