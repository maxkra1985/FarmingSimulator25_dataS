-- Local values: ActionVehicleAttach_mt
ActionVehicleAttach = {}
ActionVehicleAttach.NAME = "vehicleAttach"
local ActionVehicleAttach_mt = Class(ActionVehicleAttach)

function ActionVehicleAttach.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Identifier of the vehicle", nil, true)
	schema:register(XMLValueType.INT, basePath .. "#attacherJointIndex", "Index of the vehicle attacher joint", nil, true)
	schema:register(XMLValueType.STRING, basePath .. "#attachment", "Identifier of the attachment", nil, true)
	schema:register(XMLValueType.INT, basePath .. "#inputAttacherJointIndex", "Index of the attachment input attacher joint index", nil, true)
end

-- Upvalues: ActionVehicleAttach_mt
-- Local values: self
function ActionVehicleAttach.new(vehicleName, attacherJointIndex, attachmentName, inputAttacherJointIndex, customMt)
	-- upvalues: (copy) ActionVehicleAttach_mt
	local v9_ = customMt or ActionVehicleAttach_mt
	local v10_ = setmetatable({}, v9_)
	v10_.vehicleName = vehicleName
	v10_.attacherJointIndex = attacherJointIndex
	v10_.attachmentName = attachmentName
	v10_.inputAttacherJointIndex = inputAttacherJointIndex
	return v10_
end

-- Local values: vehicle, attacherJoint, attachment, inputAttacherJoint
function ActionVehicleAttach:run(tour, step)
	local v12_ = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if v12_ == nil then
		Logging.warning("ActionVehicleAttach.run: Vehicle \'%s\' not found", self.vehicleName)
	end
	if v12_.getAttacherJointByJointDescIndex == nil then
		Logging.warning("ActionVehicleAttach.run: Vehicle \'%s\' has no attacher joints", self.vehicleName)
		return
	elseif v12_:getAttacherJointByJointDescIndex(self.attacherJointIndex) == nil then
		Logging.warning("ActionVehicleAttach.run: Attacher joint \'%d\' not defined for vehicle \'%s\'", self.attacherJointIndex, self.vehicleName)
		return
	else
		local v13_ = g_guidedTourManager:getVehicleByName(self.attachmentName)
		if v13_ == nil then
			Logging.warning("ActionVehicleAttach.run: Attachment \'%s\' not found", self.attachmentName)
		else
			if v12_:getAttacherJointByJointDescIndex(self.inputAttacherJointIndex) ~= nil then
				v12_:attachImplement(v13_, self.inputAttacherJointIndex, self.attacherJointIndex, true, 1, false, true, false)
				return true
			end
			Logging.warning("ActionVehicleAttach.run: Input attacher joint \'%d\' not defined for vehicle \'%s\'", self.inputAttacherJointIndex, self.attachmentName)
		end
	end
end

-- Local values: vehicleName, attacherJointIndex, attachmentName, inputAttacherJointIndex
function ActionVehicleAttach.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v16_ = xmlFile:getValue(key .. "#vehicle")
	local v17_ = xmlFile:getValue(key .. "#attacherJointIndex")
	local v18_ = xmlFile:getValue(key .. "#attachment")
	local v19_ = xmlFile:getValue(key .. "#inputAttacherJointIndex")
	if v16_ == nil or (v17_ == nil or (v18_ == nil or v19_ == nil)) then
		return nil
	else
		return ActionVehicleAttach.new(v16_, v17_, v18_, v19_)
	end
end
g_guidedTourManager:registerActionClass(ActionVehicleAttach.NAME, ActionVehicleAttach)
