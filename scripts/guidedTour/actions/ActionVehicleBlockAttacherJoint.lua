-- Local values: ActionVehicleBlockAttacherJoint_mt
ActionVehicleBlockAttacherJoint = {}
ActionVehicleBlockAttacherJoint.NAME = "vehicleBlockAttacherJoint"
local ActionVehicleBlockAttacherJoint_mt = Class(ActionVehicleBlockAttacherJoint)

function ActionVehicleBlockAttacherJoint.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle. If not defined the current vehicle is used", nil, true)
	schema:register(XMLValueType.INT, basePath .. "#attacherJointIndex", "Index of the attacher joint", nil, true)
	schema:register(XMLValueType.BOOL, basePath .. "#isBlocked", "Value if detaching is blocked or not", nil, true)
end

-- Upvalues: ActionVehicleBlockAttacherJoint_mt
-- Local values: self
function ActionVehicleBlockAttacherJoint.new(vehicleName, attacherJointIndex, isBlocked, customMt)
	-- upvalues: (copy) ActionVehicleBlockAttacherJoint_mt
	local v8_ = customMt or ActionVehicleBlockAttacherJoint_mt
	local v9_ = setmetatable({}, v8_)
	v9_.vehicleName = vehicleName
	v9_.attacherJointIndex = attacherJointIndex
	v9_.isBlocked = isBlocked
	return v9_
end

-- Local values: vehicle
function ActionVehicleBlockAttacherJoint:run(tour, step)
	local v11_ = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if v11_ == nil then
		Logging.warning("ActionVehicleBlockAttacherJoint.run: Vehicle \'%s\' not found", self.vehicleName)
		return false
	elseif v11_.setAttacherJointBlocked == nil then
		Logging.warning("ActionVehicleBlockAttacherJoint.run: Vehicle \'%s\' does not have attacher joints", self.vehicleName)
		return false
	else
		v11_:setAttacherJointBlocked(self.attacherJointIndex, self.isBlocked)
		return true
	end
end

-- Local values: vehicleName, attacherJointIndex, isBlocked
function ActionVehicleBlockAttacherJoint.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v14_ = xmlFile:getValue(key .. "#vehicle")
	local v15_ = xmlFile:getValue(key .. "#attacherJointIndex")
	local v16_ = xmlFile:getValue(key .. "#isBlocked")
	if v14_ == nil or (v15_ == nil or v16_ == nil) then
		return nil
	else
		return ActionVehicleBlockAttacherJoint.new(v14_, v15_, v16_)
	end
end
g_guidedTourManager:registerActionClass(ActionVehicleBlockAttacherJoint.NAME, ActionVehicleBlockAttacherJoint)
