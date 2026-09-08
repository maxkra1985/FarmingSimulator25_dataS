-- Local values: ActionPlayerSetSpawnPosition_mt
ActionPlayerSetSpawnPosition = {}
ActionPlayerSetSpawnPosition.NAME = "playerSetSpawnPosition"
local ActionPlayerSetSpawnPosition_mt = Class(ActionPlayerSetSpawnPosition)

function ActionPlayerSetSpawnPosition.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#worldPosition", "Target position of the npc", nil, false)
	schema:register(XMLValueType.ANGLE, basePath .. "#yaw", "The yaw of the player", nil, false)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "The spawn vehicle", nil, false)
	schema:register(XMLValueType.BOOL, basePath .. "#reset", "If true current settings will be reset", nil, false)
end

-- Upvalues: ActionPlayerSetSpawnPosition_mt
-- Local values: self
function ActionPlayerSetSpawnPosition.new(worldPosX, worldPosY, worldPosZ, yaw, vehicleName, customMt)
	-- upvalues: (copy) ActionPlayerSetSpawnPosition_mt
	local v10_ = customMt or ActionPlayerSetSpawnPosition_mt
	local v11_ = setmetatable({}, v10_)
	v11_.worldPosX = worldPosX
	v11_.worldPosY = worldPosY
	v11_.worldPosZ = worldPosZ
	v11_.yaw = yaw
	v11_.vehicleName = vehicleName
	return v11_
end

-- Local values: player, vehicle
function ActionPlayerSetSpawnPosition:run(tour, step)
	local v13_ = g_localPlayer
	v13_:setSpawnPosition(nil, nil, nil)
	v13_:setSpawnYaw(nil)
	v13_:setSpawnVehicle(nil)
	if self.worldPosX == nil then
		if self.vehicleName ~= nil then
			local v14_ = g_guidedTourManager:getVehicleByName(self.vehicleName)
			if v14_ == nil then
				Logging.warning("ActionPlayerSetSpawnPosition.run: Vehicle \'%s\' not found", self.vehicleName)
				return false
			end
			v13_:setSpawnVehicle(v14_)
		end
	else
		v13_:setSpawnPosition(self.worldPosX, self.worldPosY, self.worldPosZ)
		v13_:setSpawnYaw(self.yaw)
	end
	return true
end

-- Local values: worldPosX, worldPosY, worldPosZ, yaw, vehicleName
function ActionPlayerSetSpawnPosition.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v17_, v18_, v19_ = xmlFile:getValue(key .. "#worldPosition")
	local v20_ = xmlFile:getValue(key .. "#yaw")
	local v21_ = xmlFile:getValue(key .. "#vehicle")
	return ActionPlayerSetSpawnPosition.new(v17_, v18_, v19_, v20_, v21_)
end
g_guidedTourManager:registerActionClass(ActionPlayerSetSpawnPosition.NAME, ActionPlayerSetSpawnPosition)
