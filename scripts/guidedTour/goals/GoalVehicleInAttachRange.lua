-- Local values: GoalVehicleInAttachRange_mt
GoalVehicleInAttachRange = {}
GoalVehicleInAttachRange.NAME = "vehicleInAttachRange"
local GoalVehicleInAttachRange_mt = Class(GoalVehicleInAttachRange)

function GoalVehicleInAttachRange.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Identifier of the vehicle", nil, true)
	schema:register(XMLValueType.INT, basePath .. "#attacherJointIndex", "Index of the vehicle attacher joint", nil, true)
	schema:register(XMLValueType.STRING, basePath .. "#attachment", "Identifier of the attachment", nil, true)
	schema:register(XMLValueType.INT, basePath .. "#inputAttacherJointIndex", "Index of the attachment input attacher joint index", nil, true)
end

-- Upvalues: GoalVehicleInAttachRange_mt
-- Local values: self
function GoalVehicleInAttachRange.new(vehicleName, attacherJointIndex, attachmentName, inputAttacherJointIndex, customMt)
	-- upvalues: (copy) GoalVehicleInAttachRange_mt
	local v9_ = customMt or GoalVehicleInAttachRange_mt
	local v10_ = setmetatable({}, v9_)
	v10_.vehicleName = vehicleName
	v10_.attacherJointIndex = attacherJointIndex
	v10_.attachmentName = attachmentName
	v10_.inputAttacherJointIndex = inputAttacherJointIndex
	return v10_
end

-- Local values: vehicle, attacherJoint, attachment, inputAttacherJoint
function GoalVehicleInAttachRange:activate(tour, step)
	local v12_ = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if v12_ == nil then
		Logging.warning("GoalVehicleInAttachRange.activate: Vehicle \'%s\' not found", self.vehicleName)
		return
	elseif v12_.getAttacherJointByJointDescIndex == nil then
		Logging.warning("GoalVehicleInAttachRange.activate: Vehicle \'%s\' has not attacher joints", self.vehicleName)
		return
	elseif v12_:getAttacherJointByJointDescIndex(self.attacherJointIndex) == nil then
		Logging.warning("GoalVehicleInAttachRange.activate: Attacher joint \'%d\' not defined for vehicle \'%s\'", self.attacherJointIndex, self.vehicleName)
		return
	else
		local v13_ = g_guidedTourManager:getVehicleByName(self.attachmentName)
		if v13_ == nil then
			Logging.warning("GoalVehicleInAttachRange.activate: Attachment \'%s\' not found", self.attachmentName)
			return
		elseif v12_:getAttacherJointByJointDescIndex(self.inputAttacherJointIndex) == nil then
			Logging.warning("GoalVehicleInAttachRange.activate: Input attacher joint \'%d\' not defined for vehicle \'%s\'", self.inputAttacherJointIndex, self.attachmentName)
		else
			self.vehicle = v12_
			self.attachment = v13_
		end
	end
end

function GoalVehicleInAttachRange:deactivate()
	g_currentMission.navigationSystem:stop()
	self.vehicle = nil
	self.attachment = nil
end

-- Local values: inputJointDesc, node, x, y, z, dirX, _, dirZ, attacherVehicle, attacherVehicleJointDescIndex, attachable, attachableJointDescIndex
function GoalVehicleInAttachRange:isAchieved()
	if self.vehicle == nil then
		return true
	else
		local v16_ = self.attachment:getInputAttacherJointByJointDescIndex(self.inputAttacherJointIndex).node
		local v17_, v18_, v19_ = getWorldTranslation(v16_)
		local v20_, _, v21_ = localDirectionToWorld(v16_, 1, 0, 0)
		g_currentMission.navigationSystem:navigateTo(v17_, v18_, v19_, v20_, 0, v21_)
		local v22_, v23_, v24_, v25_ = self.vehicle:getAttachableInfo()
		if v22_ == self.vehicle then
			if v23_ == self.attacherJointIndex then
				if v24_ == self.attachment then
					return v25_ == self.inputAttacherJointIndex
				else
					return false
				end
			else
				return false
			end
		else
			return false
		end
	end
end

-- Local values: vehicleName, attacherJointIndex, attachmentName, inputAttacherJointIndex
function GoalVehicleInAttachRange.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v28_ = xmlFile:getValue(key .. "#vehicle")
	if v28_ == nil then
		Logging.xmlWarning(xmlFile, "Missing \'vehicle\' for \'%s\'", key)
		return nil
	end
	local v29_ = xmlFile:getValue(key .. "#attacherJointIndex")
	if v29_ == nil then
		Logging.xmlWarning(xmlFile, "Missing \'attacherJointIndex\' for \'%s\'", key)
		return nil
	end
	local v30_ = xmlFile:getValue(key .. "#attachment")
	if v30_ == nil then
		Logging.xmlWarning(xmlFile, "Missing \'attachment\' for \'%s\'", key)
		return nil
	end
	local v31_ = xmlFile:getValue(key .. "#inputAttacherJointIndex")
	if v31_ ~= nil then
		return GoalVehicleInAttachRange.new(v28_, v29_, v30_, v31_)
	end
	Logging.xmlWarning(xmlFile, "Missing \'inputAttacherJointIndex\' for \'%s\'", key)
	return nil
end
g_guidedTourManager:registerGoalClass(GoalVehicleInAttachRange.NAME, GoalVehicleInAttachRange)
