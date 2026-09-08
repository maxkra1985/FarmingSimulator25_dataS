-- Local values: ActionVehicleSetFillLevel_mt
ActionVehicleSetFillLevel = {}
ActionVehicleSetFillLevel.NAME = "vehicleSetFillLevel"
local ActionVehicleSetFillLevel_mt = Class(ActionVehicleSetFillLevel)

function ActionVehicleSetFillLevel.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle", nil, true)
	schema:register(XMLValueType.INT, basePath .. "#fillUnitIndex", "Affected fillunit index", nil, true)
	schema:register(XMLValueType.FLOAT, basePath .. "#fillLevel", "Target filllevel", nil, true)
end

-- Upvalues: ActionVehicleSetFillLevel_mt
-- Local values: self
function ActionVehicleSetFillLevel.new(vehicleName, fillUnitIndex, fillLevel, customMt)
	-- upvalues: (copy) ActionVehicleSetFillLevel_mt
	local v8_ = customMt or ActionVehicleSetFillLevel_mt
	local v9_ = setmetatable({}, v8_)
	v9_.vehicleName = vehicleName
	v9_.fillUnitIndex = fillUnitIndex
	v9_.fillLevel = fillLevel
	return v9_
end

-- Local values: vehicle, fillUnitIndex, fillTypeIndex, fillLevel, farmId, toolType, fillPositionData, fillLevelDelta
function ActionVehicleSetFillLevel:run(tour, step)
	local v11_ = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if v11_ == nil then
		Logging.warning("ActionVehicleSetFillLevel.run: Vehicle \'%s\' not found", self.vehicleName)
	end
	local v12_ = self.fillUnitIndex
	local v13_ = v11_:getFillUnitFillType(v12_)
	local v14_ = v11_:getFillUnitFillLevel(v12_)
	local v15_ = v11_:getOwnerFarmId()
	local v16_ = ToolType.UNDEFINED
	v11_:addFillUnitFillLevel(v15_, v12_, self.fillLevel - v14_, v13_, v16_, nil)
	return true
end

-- Local values: vehicleName, fillUnitIndex, fillLevel
function ActionVehicleSetFillLevel.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v19_ = xmlFile:getValue(key .. "#vehicle")
	local v20_ = xmlFile:getValue(key .. "#fillUnitIndex")
	local v21_ = xmlFile:getValue(key .. "#fillLevel")
	if v19_ == nil or (v20_ == nil or v21_ == nil) then
		return nil
	else
		return ActionVehicleSetFillLevel.new(v19_, v20_, v21_)
	end
end
g_guidedTourManager:registerActionClass(ActionVehicleSetFillLevel.NAME, ActionVehicleSetFillLevel)
