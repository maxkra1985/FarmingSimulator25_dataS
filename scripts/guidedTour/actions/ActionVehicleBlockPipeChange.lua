ActionVehicleBlockPipeChange = {}
ActionVehicleBlockPipeChange.NAME = "vehicleBlockPipeChange"
local ActionVehicleBlockPipeChange_mt = Class(ActionVehicleBlockPipeChange)
function ActionVehicleBlockPipeChange.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle. If not defined the current vehicle is used", nil, false)
	schema:register(XMLValueType.BOOL, basePath .. "#isBlocked", "Value if folding is blocked or not", nil, true)
end
function ActionVehicleBlockPipeChange.new(vehicleName, isBlocked, customMt)
	local self = setmetatable({}, customMt or ActionVehicleBlockPipeChange_mt)
	self.vehicleName = vehicleName
	self.isBlocked = isBlocked
	return self
end
function ActionVehicleBlockPipeChange:run(tour, step)
	local vehicle = g_localPlayer:getCurrentVehicle()
	if self.vehicleName ~= nil then
		vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	end
	if vehicle == nil then
		return false
	else
		if vehicle.setIsPipeStateChangeAllowed ~= nil then
			vehicle:setIsPipeStateChangeAllowed(not self.isBlocked)
		end
		return true
	end
end
function ActionVehicleBlockPipeChange.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local vehicleName = xmlFile:getValue(key .. "#vehicle")
	local isBlocked = xmlFile:getValue(key .. "#isBlocked")
	if vehicleName ~= nil and isBlocked ~= nil then
		return ActionVehicleBlockPipeChange.new(vehicleName, isBlocked)
	end
	return nil
end
g_guidedTourManager:registerActionClass(ActionVehicleBlockPipeChange.NAME, ActionVehicleBlockPipeChange)
