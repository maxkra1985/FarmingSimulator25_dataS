-- Local values: ActionVehicleSetFarm_mt
ActionVehicleSetFarm = {}
ActionVehicleSetFarm.NAME = "vehicleSetFarm"
local ActionVehicleSetFarm_mt = Class(ActionVehicleSetFarm)

function ActionVehicleSetFarm.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle", nil, true)
	schema:register(XMLValueType.STRING, basePath .. "#farmId", "The owner farm id of the vehicle", nil, true)
end

-- Upvalues: ActionVehicleSetFarm_mt
-- Local values: self
function ActionVehicleSetFarm.new(vehicleName, farmId, customMt)
	-- upvalues: (copy) ActionVehicleSetFarm_mt
	local v7_ = customMt or ActionVehicleSetFarm_mt
	local v8_ = setmetatable({}, v7_)
	v8_.vehicleName = vehicleName
	v8_.farmId = farmId
	return v8_
end

-- Local values: vehicle
function ActionVehicleSetFarm:run(tour, step)
	local v10_ = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if v10_ == nil then
		Logging.warning("ActionVehicleSetFarm.run: Vehicle \'%s\' not found", self.vehicleName)
		return true
	else
		v10_:setOwnerFarmId(self.farmId, false)
		return true
	end
end

-- Local values: vehicleName, farmIdStr, farmId, farmIdStrLower
function ActionVehicleSetFarm.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v13_ = xmlFile:getValue(key .. "#vehicle")
	local v14_ = xmlFile:getValue(key .. "#farmId")
	local v15_ = string.lower(v14_)
	local v16_
	if v15_ == "spectator" then
		v16_ = FarmManager.SPECTATOR_FARM_ID
	elseif v15_ == "tour" then
		v16_ = FarmManager.GUIDED_TOUR_FARM_ID
	elseif v15_ == "nobody" then
		v16_ = AccessHandler.NOBODY
	elseif v15_ == "default" then
		v16_ = FarmManager.SINGLEPLAYER_FARM_ID
	else
		v16_ = tonumber(v14_)
	end
	if v13_ == nil or v16_ == nil then
		return nil
	else
		return ActionVehicleSetFarm.new(v13_, v16_)
	end
end
g_guidedTourManager:registerActionClass(ActionVehicleSetFarm.NAME, ActionVehicleSetFarm)
