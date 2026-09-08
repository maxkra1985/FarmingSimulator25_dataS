-- Local values: ActionVehicleDismissHelper_mt
ActionVehicleDismissHelper = {}
ActionVehicleDismissHelper.NAME = "vehicleDismissHelper"
local ActionVehicleDismissHelper_mt = Class(ActionVehicleDismissHelper)

function ActionVehicleDismissHelper.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle", nil, true)
end

-- Upvalues: ActionVehicleDismissHelper_mt
-- Local values: self
function ActionVehicleDismissHelper.new(vehicleName, customMt)
	-- upvalues: (copy) ActionVehicleDismissHelper_mt
	local v6_ = customMt or ActionVehicleDismissHelper_mt
	local v7_ = setmetatable({}, v6_)
	v7_.vehicleName = vehicleName
	return v7_
end

-- Local values: vehicle
function ActionVehicleDismissHelper:run(tour, step)
	local v9_ = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if v9_ == nil then
		Logging.warning("ActionVehicleDismissHelper.run: Vehicle \'%s\' not found", self.vehicleName)
	end
	if v9_.stopCurrentAIJob ~= nil then
		v9_:stopCurrentAIJob()
	end
	return true
end

-- Local values: vehicleName
function ActionVehicleDismissHelper.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v12_ = xmlFile:getValue(key .. "#vehicle")
	if v12_ == nil then
		return nil
	else
		return ActionVehicleDismissHelper.new(v12_)
	end
end
g_guidedTourManager:registerActionClass(ActionVehicleDismissHelper.NAME, ActionVehicleDismissHelper)
