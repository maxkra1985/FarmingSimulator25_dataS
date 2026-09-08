-- Local values: ActionFarmlandSetFarm_mt
ActionFarmlandSetFarm = {}
ActionFarmlandSetFarm.NAME = "farmlandSetFarm"
local ActionFarmlandSetFarm_mt = Class(ActionFarmlandSetFarm)

function ActionFarmlandSetFarm.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#farmlandId", "Id of the farmland", nil, true)
	schema:register(XMLValueType.STRING, basePath .. "#farmId", "The owner farm id of the vehicle", nil, true)
end

-- Upvalues: ActionFarmlandSetFarm_mt
-- Local values: self
function ActionFarmlandSetFarm.new(farmlandId, farmId, customMt)
	-- upvalues: (copy) ActionFarmlandSetFarm_mt
	local v7_ = customMt or ActionFarmlandSetFarm_mt
	local v8_ = setmetatable({}, v7_)
	v8_.farmlandId = farmlandId
	v8_.farmId = farmId
	return v8_
end

function ActionFarmlandSetFarm:loadFromXMLFile(xmlFile, key)
	self.loadedFromSavegame = true
	return true
end

-- Local values: farmland
function ActionFarmlandSetFarm:run(tour, step)
	if not self.loadedFromSavegame then
		if g_farmlandManager:getFarmlandById(self.farmlandId) == nil then
			Logging.warning("ActionFarmlandSetFarm.run: Farmland \'%s\' not found", self.farmlandId)
		end
		g_farmlandManager:setLandOwnership(self.farmlandId, self.farmId)
	end
	return true
end

-- Local values: farmlandId, farmIdStr, farmId, farmIdStrLower
function ActionFarmlandSetFarm.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v13_ = xmlFile:getValue(key .. "#farmlandId")
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
		return ActionFarmlandSetFarm.new(v13_, v16_)
	end
end
g_guidedTourManager:registerActionClass(ActionFarmlandSetFarm.NAME, ActionFarmlandSetFarm)
