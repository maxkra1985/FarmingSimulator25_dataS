-- Local values: ActionPlaceableSetFarm_mt
ActionPlaceableSetFarm = {}
ActionPlaceableSetFarm.NAME = "placeableSetFarm"
local ActionPlaceableSetFarm_mt = Class(ActionPlaceableSetFarm)

function ActionPlaceableSetFarm.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#placeable", "Name of the placeable", nil, true)
	schema:register(XMLValueType.STRING, basePath .. "#farmId", "The owner farm id of the placeable", nil, true)
end

-- Upvalues: ActionPlaceableSetFarm_mt
-- Local values: self
function ActionPlaceableSetFarm.new(placeableName, farmId, customMt)
	-- upvalues: (copy) ActionPlaceableSetFarm_mt
	local v7_ = customMt or ActionPlaceableSetFarm_mt
	local v8_ = setmetatable({}, v7_)
	v8_.placeableName = placeableName
	v8_.farmId = farmId
	return v8_
end

-- Local values: placeable
function ActionPlaceableSetFarm:run(tour, step)
	local v10_ = g_guidedTourManager:getPlaceableByName(self.placeableName)
	if v10_ == nil then
		Logging.warning("ActionPlaceableSetFarm.run: Placeable \'%s\' not found", self.placeableName)
		return true
	else
		v10_:setOwnerFarmId(self.farmId, false)
		return true
	end
end

-- Local values: placeableName, farmIdStr, farmId, farmIdStrLower
function ActionPlaceableSetFarm.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v13_ = xmlFile:getValue(key .. "#placeable")
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
		return ActionPlaceableSetFarm.new(v13_, v16_)
	end
end
g_guidedTourManager:registerActionClass(ActionPlaceableSetFarm.NAME, ActionPlaceableSetFarm)
