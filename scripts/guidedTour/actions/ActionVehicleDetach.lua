-- Local values: ActionVehicleDetach_mt
ActionVehicleDetach = {}
ActionVehicleDetach.NAME = "vehicleDetach"
local ActionVehicleDetach_mt = Class(ActionVehicleDetach)

function ActionVehicleDetach.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle", nil, true)
end

-- Upvalues: ActionVehicleDetach_mt
-- Local values: self
function ActionVehicleDetach.new(vehicleName, customMt)
	-- upvalues: (copy) ActionVehicleDetach_mt
	local v6_ = customMt or ActionVehicleDetach_mt
	local v7_ = setmetatable({}, v6_)
	v7_.vehicleName = vehicleName
	return v7_
end

-- Local values: vehicle, attacherVehicle
function ActionVehicleDetach:run(tour, step)
	local v9_ = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if v9_ == nil then
		Logging.warning("ActionVehicleDetach.run: Vehicle \'%s\' not found", self.vehicleName)
	end
	if v9_.getAttacherVehicle == nil then
		return true
	end
	local v10_ = v9_:getAttacherVehicle()
	if v10_ ~= nil then
		v10_:detachImplementByObject(v9_)
	end
	return true
end

-- Local values: vehicleName
function ActionVehicleDetach.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v13_ = xmlFile:getValue(key .. "#vehicle")
	if v13_ == nil then
		return nil
	else
		return ActionVehicleDetach.new(v13_)
	end
end
g_guidedTourManager:registerActionClass(ActionVehicleDetach.NAME, ActionVehicleDetach)
