-- Local values: ActionVehicleReset_mt
ActionVehicleReset = {}
ActionVehicleReset.NAME = "vehicleReset"
local ActionVehicleReset_mt = Class(ActionVehicleReset)

function ActionVehicleReset.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle", nil, true)
	schema:register(XMLValueType.STRING, basePath .. "#targetVehicle", "Name of the target vehicle", nil, false)
	schema:register(XMLValueType.VECTOR_2, basePath .. "#offset", "Offset of the vehicle to the target vehicle", nil, false)
	schema:register(XMLValueType.VECTOR_2, basePath .. "#worldPosition", "Reset position of the vehicle", nil, false)
	schema:register(XMLValueType.ANGLE, basePath .. "#rotationY", "Y-rotation of the vehicle", 0, false)
end

-- Upvalues: ActionVehicleReset_mt
-- Local values: self
function ActionVehicleReset.new(vehicleName, worldX, worldZ, rotationY, targetVehicleName, offsetX, offsetZ, customMt)
	-- upvalues: (copy) ActionVehicleReset_mt
	local v12_ = customMt or ActionVehicleReset_mt
	local v13_ = setmetatable({}, v12_)
	v13_.vehicleName = vehicleName
	v13_.worldX = worldX
	v13_.worldZ = worldZ
	v13_.rotationY = rotationY
	v13_.targetVehicleName = targetVehicleName
	v13_.offsetX = offsetX
	v13_.offsetZ = offsetZ
	return v13_
end

-- Local values: vehicle, posX, posZ, rotY, _, targetVehicle
function ActionVehicleReset:run(tour, step)
	local v15_ = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if v15_ == nil then
		Logging.warning("ActionVehicleReset.run: Vehicle \'%s\' not found", self.vehicleName)
	end
	local v16_ = self.worldX
	local v17_ = self.worldZ
	local v18_ = self.rotationY
	if self.targetVehicleName ~= nil then
		local v19_ = g_guidedTourManager:getVehicleByName(self.targetVehicleName)
		if v19_ == nil then
			Logging.warning("ActionVehicleReset.run: Target vehicle \'%s\' not found", self.targetVehicleName)
			return true
		end
		local v20_
		v16_, v20_, v17_ = localToWorld(v19_.rootNode, self.offsetX or 0, 0, self.offsetZ or 0)
		local v21_, v22_
		v21_, v18_, v22_ = localRotationToWorld(v19_.rootNode, 0, self.rotationY, 0)
	end
	if v16_ == nil then
		Logging.warning("ActionVehicleReset.run: No position to reset defined for target vehicle \'%s\'", self.vehicleName)
		return true
	else
		g_currentMission:teleportVehicle(v15_, v16_, v17_, v18_)
		return true
	end
end

-- Local values: vehicleName, worldPosX, worldPosZ, rotationY, targetVehicleName, offsetX, offsetZ
function ActionVehicleReset.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v25_ = xmlFile:getValue(key .. "#vehicle")
	local v26_, v27_ = xmlFile:getValue(key .. "#worldPosition")
	local v28_ = xmlFile:getValue(key .. "#rotationY", 0)
	local v29_ = xmlFile:getValue(key .. "#targetVehicle")
	local v30_, v31_ = xmlFile:getValue(key .. "#offset")
	if v25_ == nil then
		Logging.warning("ActionVehicleReset.createFromXML: No vehicle defined", v25_)
		return nil
	else
		if v29_ == nil then
			if v26_ == nil or v27_ == nil then
				Logging.warning("ActionVehicleReset.createFromXML: No world postion given to reset vehicle \'%s\'", v25_)
				return nil
			end
		elseif v30_ == nil or v31_ == nil then
			Logging.warning("ActionVehicleReset.createFromXML: No offset given for targetVehicle \'%s\'", v29_)
			return nil
		end
		return ActionVehicleReset.new(v25_, v26_, v27_, v28_, v29_, v30_, v31_)
	end
end
g_guidedTourManager:registerActionClass(ActionVehicleReset.NAME, ActionVehicleReset)
