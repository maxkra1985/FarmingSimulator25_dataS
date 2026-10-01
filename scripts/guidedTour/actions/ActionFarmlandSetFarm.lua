ActionFarmlandSetFarm = {}
ActionFarmlandSetFarm.NAME = "farmlandSetFarm"
local ActionFarmlandSetFarm_mt = Class(ActionFarmlandSetFarm)
function ActionFarmlandSetFarm.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#farmlandId", "Id of the farmland", nil, true)
	schema:register(XMLValueType.STRING, basePath .. "#farmId", "The owner farm id of the vehicle", nil, true)
end
function ActionFarmlandSetFarm.new(farmlandId, farmId, customMt)
	local self = setmetatable({}, customMt or ActionFarmlandSetFarm_mt)
	self.farmlandId = farmlandId
	self.farmId = farmId
	return self
end
function ActionFarmlandSetFarm:loadFromXMLFile(xmlFile, key)
	self.loadedFromSavegame = true
	return true
end
function ActionFarmlandSetFarm:run(tour, step)
	if not self.loadedFromSavegame then
		local farmland = g_farmlandManager:getFarmlandById(self.farmlandId)
		if farmland == nil then
			Logging.warning("ActionFarmlandSetFarm.run: Farmland '%s' not found", self.farmlandId)
		end
		g_farmlandManager:setLandOwnership(self.farmlandId, self.farmId)
	end
	return true
end
function ActionFarmlandSetFarm.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local farmlandId = xmlFile:getValue(key .. "#farmlandId")
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
	if farmlandId ~= nil and farmId ~= nil then
		return ActionFarmlandSetFarm.new(farmlandId, farmId)
	end
	return nil
end
g_guidedTourManager:registerActionClass(ActionFarmlandSetFarm.NAME, ActionFarmlandSetFarm)
