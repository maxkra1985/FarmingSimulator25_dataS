ActionVehicleAttach = {}
ActionVehicleAttach.NAME = "vehicleAttach"
local ActionVehicleAttach_mt = Class(ActionVehicleAttach)
function ActionVehicleAttach.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Identifier of the vehicle", nil, true)
	schema:register(XMLValueType.INT, basePath .. "#attacherJointIndex", "Index of the vehicle attacher joint", nil, true)
	schema:register(XMLValueType.STRING, basePath .. "#attachment", "Identifier of the attachment", nil, true)
	schema:register(XMLValueType.INT, basePath .. "#inputAttacherJointIndex", "Index of the attachment input attacher joint index", nil, true)
end
function ActionVehicleAttach.new(vehicleName, attacherJointIndex, attachmentName, inputAttacherJointIndex, customMt)
	local self = setmetatable({}, customMt or ActionVehicleAttach_mt)
	self.vehicleName = vehicleName
	self.attacherJointIndex = attacherJointIndex
	self.attachmentName = attachmentName
	self.inputAttacherJointIndex = inputAttacherJointIndex
	return self
end
function ActionVehicleAttach:run(tour, step)
	local vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if vehicle == nil then
		Logging.warning("ActionVehicleAttach.run: Vehicle '%s' not found", self.vehicleName)
	end
	if vehicle.getAttacherJointByJointDescIndex == nil then
		Logging.warning("ActionVehicleAttach.run: Vehicle '%s' has no attacher joints", self.vehicleName)
		return
	end
	local attacherJoint = vehicle:getAttacherJointByJointDescIndex(self.attacherJointIndex)
	if attacherJoint == nil then
		Logging.warning("ActionVehicleAttach.run: Attacher joint '%d' not defined for vehicle '%s'", self.attacherJointIndex, self.vehicleName)
		return
	end
	local attachment = g_guidedTourManager:getVehicleByName(self.attachmentName)
	if attachment == nil then
		Logging.warning("ActionVehicleAttach.run: Attachment '%s' not found", self.attachmentName)
		return
	end
	local inputAttacherJoint = vehicle:getAttacherJointByJointDescIndex(self.inputAttacherJointIndex)
	if inputAttacherJoint == nil then
		Logging.warning("ActionVehicleAttach.run: Input attacher joint '%d' not defined for vehicle '%s'", self.inputAttacherJointIndex, self.attachmentName)
		return
	else
		vehicle:attachImplement(attachment, self.inputAttacherJointIndex, self.attacherJointIndex, true, 1, false, true, false)
		return true
	end
end
function ActionVehicleAttach.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local vehicleName = xmlFile:getValue(key .. "#vehicle")
	local attacherJointIndex = xmlFile:getValue(key .. "#attacherJointIndex")
	local attachmentName = xmlFile:getValue(key .. "#attachment")
	local inputAttacherJointIndex = xmlFile:getValue(key .. "#inputAttacherJointIndex")
	if vehicleName ~= nil and (attacherJointIndex ~= nil and (attachmentName ~= nil and inputAttacherJointIndex ~= nil)) then
		return ActionVehicleAttach.new(vehicleName, attacherJointIndex, attachmentName, inputAttacherJointIndex)
	end
	return nil
end
g_guidedTourManager:registerActionClass(ActionVehicleAttach.NAME, ActionVehicleAttach)
