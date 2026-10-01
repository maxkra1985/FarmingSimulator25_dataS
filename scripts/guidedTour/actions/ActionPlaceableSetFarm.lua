ActionPlaceableSetFarm = {}
ActionPlaceableSetFarm.NAME = "placeableSetFarm"
local ActionPlaceableSetFarm_mt = Class(ActionPlaceableSetFarm)
function ActionPlaceableSetFarm.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#placeable", "Name of the placeable", nil, true)
	schema:register(XMLValueType.STRING, basePath .. "#farmId", "The owner farm id of the placeable", nil, true)
end
function ActionPlaceableSetFarm.new(placeableName, farmId, customMt)
	local self = setmetatable({}, customMt or ActionPlaceableSetFarm_mt)
	self.placeableName = placeableName
	self.farmId = farmId
	return self
end
function ActionPlaceableSetFarm:run(tour, step)
	local placeable = g_guidedTourManager:getPlaceableByName(self.placeableName)
	if placeable == nil then
		Logging.warning("ActionPlaceableSetFarm.run: Placeable '%s' not found", self.placeableName)
		return true
	else
		placeable:setOwnerFarmId(self.farmId, false)
		return true
	end
end
function ActionPlaceableSetFarm.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local placeableName = xmlFile:getValue(key .. "#placeable")
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
	if placeableName ~= nil and farmId ~= nil then
		return ActionPlaceableSetFarm.new(placeableName, farmId)
	end
	return nil
end
g_guidedTourManager:registerActionClass(ActionPlaceableSetFarm.NAME, ActionPlaceableSetFarm)
