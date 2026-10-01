ActionVehicleBlockAIStop = {}
ActionVehicleBlockAIStop.NAME = "vehicleBlockAIStop"
local ActionVehicleBlockAIStop_mt = Class(ActionVehicleBlockAIStop)
function ActionVehicleBlockAIStop.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle. If not defined the current vehicle is used", nil, false)
	schema:register(XMLValueType.BOOL, basePath .. "#isBlocked", "Value if ai start is blocked or not", nil, true)
end
function ActionVehicleBlockAIStop.new(vehicleName, isBlocked, customMt)
	local self = setmetatable({}, customMt or ActionVehicleBlockAIStop_mt)
	self.vehicleName = vehicleName
	self.isBlocked = isBlocked
	return self
end
function ActionVehicleBlockAIStop:run(tour, step)
	local vehicle = g_localPlayer:getCurrentVehicle()
	if self.vehicleName ~= nil then
		vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	end
	if vehicle == nil then
		return false
	else
		if vehicle.setIsAIStopAllowed ~= nil then
			vehicle:setIsAIStopAllowed(not self.isBlocked)
		end
		return true
	end
end
function ActionVehicleBlockAIStop.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local vehicleName = xmlFile:getValue(key .. "#vehicle")
	local isBlocked = xmlFile:getValue(key .. "#isBlocked")
	if vehicleName ~= nil and isBlocked ~= nil then
		return ActionVehicleBlockAIStop.new(vehicleName, isBlocked)
	end
	return nil
end
g_guidedTourManager:registerActionClass(ActionVehicleBlockAIStop.NAME, ActionVehicleBlockAIStop)
