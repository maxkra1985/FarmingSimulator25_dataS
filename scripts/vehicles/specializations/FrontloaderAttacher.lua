FrontloaderAttacher = {}

function FrontloaderAttacher.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(AttacherJoints, specializations)
end

function FrontloaderAttacher.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", FrontloaderAttacher)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetachImplement", FrontloaderAttacher)
	SpecializationUtil.registerEventListener(vehicleType, "onPreAttachImplement", FrontloaderAttacher)
end
function FrontloaderAttacher.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("frontloader", g_i18n:getText("configuration_frontloaderAttacher"), nil, VehicleConfigurationItem)
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("FrontloaderAttacher")
	v3_:register(XMLValueType.BOOL, "vehicle.frontloaderConfigurations.frontloaderConfiguration(?).attacherJoint#frontAxisLimitJoint", "Front axis joint will be limited while attached", true)
	v3_:register(XMLValueType.INT, "vehicle.frontloaderConfigurations.frontloaderConfiguration(?).attacherJoint#frontAxisJoint", "Front axis joint index", 1)
	v3_:setXMLSpecializationType()
end

-- Local values: spec, key, frontAxisLimitJoint, frontAxisJoint
function FrontloaderAttacher:onLoad(savegame)
	if self.configurations.frontloader ~= nil then
		local v5_ = self.spec_frontloaderAttacher
		local v6_ = string.format("vehicle.frontloaderConfigurations.frontloaderConfiguration(%d)", self.configurations.frontloader - 1)
		if self.xmlFile:hasProperty(v6_ .. ".attacherJoint") and self.xmlFile:getValue(v6_ .. ".attacherJoint#frontAxisLimitJoint", true) then
			local v7_ = self.xmlFile:getValue(v6_ .. ".attacherJoint#frontAxisJoint", 1)
			if self.componentJoints[v7_] == nil then
				Logging.xmlWarning(self.xmlFile, "Invalid front-axis joint \'%s\' for frontloader attacher.", v7_)
			else
				v5_.frontAxisJoint = v7_
			end
		end
	end
	if not self.isServer or self.spec_frontloaderAttacher.frontAxisJoint == nil then
		SpecializationUtil.removeEventListener(self, "onPreDetachImplement", FrontloaderAttacher)
		SpecializationUtil.removeEventListener(self, "onPreAttachImplement", FrontloaderAttacher)
	end
end

-- Local values: spec, attacherJoint, attacherJointIndex, attacherJoints, i
function FrontloaderAttacher:onPreDetachImplement(implement)
	local v10_ = self.spec_frontloaderAttacher
	if v10_.frontAxisJoint ~= nil then
		local v11_ = implement.jointDescIndex
		local v12_ = self:getAttacherJoints()
		local v13_
		if v12_ == nil then
			v13_ = nil
		else
			v13_ = v12_[v11_]
		end
		if v13_ ~= nil and v13_.jointType == AttacherJoints.JOINTTYPE_ATTACHABLEFRONTLOADER then
			for v14_ = 1, 3 do
				self:setComponentJointRotLimit(self.componentJoints[v10_.frontAxisJoint], v14_, -v10_.rotLimit[v14_], v10_.rotLimit[v14_])
			end
		end
	end
end

-- Local values: spec, attacherJoint, attacherJoints, i
function FrontloaderAttacher:onPreAttachImplement(attachable, inputJointDescIndex, jointDescIndex, loadFromSavegame)
	local v17_ = self.spec_frontloaderAttacher
	if v17_.frontAxisJoint ~= nil then
		local v18_ = self:getAttacherJoints()
		local v19_
		if v18_ == nil then
			v19_ = nil
		else
			v19_ = v18_[jointDescIndex]
		end
		if v19_ ~= nil and v19_.jointType == AttacherJoints.JOINTTYPE_ATTACHABLEFRONTLOADER then
			local v20_ = {}
			local v21_ = self.componentJoints[v17_.frontAxisJoint].rotLimit
			__set_list(v20_, 1, {unpack(v21_)})
			v17_.rotLimit = v20_
			for v22_ = 1, 3 do
				self:setComponentJointRotLimit(self.componentJoints[v17_.frontAxisJoint], v22_, 0, 0)
			end
		end
	end
end
