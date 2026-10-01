ActionVehicleSetFarm = {}
ActionVehicleSetFarm.NAME = "vehicleSetFarm"
local ActionVehicleSetFarm_mt = Class(ActionVehicleSetFarm)
function ActionVehicleSetFarm.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle", nil, true)
	schema:register(XMLValueType.STRING, basePath .. "#farmId", "The owner farm id of the vehicle", nil, true)
end
function ActionVehicleSetFarm.new(vehicleName, farmId, customMt)
	local self = setmetatable({}, customMt or ActionVehicleSetFarm_mt)
	self.vehicleName = vehicleName
	self.farmId = farmId
	return self
end
function ActionVehicleSetFarm:run(tour, step)
	local vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if vehicle == nil then
		Logging.warning("ActionVehicleSetFarm.run: Vehicle '%s' not found", self.vehicleName)
		return true
	else
		vehicle:setOwnerFarmId(self.farmId, false)
		return true
	end
end
function ActionVehicleSetFarm.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local vehicleName = xmlFile:getValue(key .. "#vehicle")
	local farmIdStr = xmlFile:getValue(key .. "#farmId")
	local farmId = nil
	local farmIdStrLower = string.lower(farmIdStr)
	if farmIdStrLower == "spectator" then
		farmId = FarmManager.SPECTATOR_FARM_ID
	elseif farmIdStrLower == "tour" then
		farmId = FarmManager.GUIDED_TOUR_FARM_ID
	elseif farmIdStrLower == "nobody" then
		farmId = AccessHandler.NOBODY
	elseif farmIdStrLower == "default" then
		farmId = FarmManager.SINGLEPLAYER_FARM_ID
	else
		farmId = tonumber(farmIdStr)
	end
	if vehicleName ~= nil and farmId ~= nil then
		return ActionVehicleSetFarm.new(vehicleName, farmId)
	end
	return nil
end
g_guidedTourManager:registerActionClass(ActionVehicleSetFarm.NAME, ActionVehicleSetFarm)
