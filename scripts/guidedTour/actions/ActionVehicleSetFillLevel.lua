ActionVehicleSetFillLevel = {}
ActionVehicleSetFillLevel.NAME = "vehicleSetFillLevel"
local ActionVehicleSetFillLevel_mt = Class(ActionVehicleSetFillLevel)
function ActionVehicleSetFillLevel.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle", nil, true)
	schema:register(XMLValueType.INT, basePath .. "#fillUnitIndex", "Affected fillunit index", nil, true)
	schema:register(XMLValueType.FLOAT, basePath .. "#fillLevel", "Target filllevel", nil, true)
end
function ActionVehicleSetFillLevel.new(vehicleName, fillUnitIndex, fillLevel, customMt)
	local self = setmetatable({}, customMt or ActionVehicleSetFillLevel_mt)
	self.vehicleName = vehicleName
	self.fillUnitIndex = fillUnitIndex
	self.fillLevel = fillLevel
	return self
end
function ActionVehicleSetFillLevel:run(tour, step)
	local vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if vehicle == nil then
		Logging.warning("ActionVehicleSetFillLevel.run: Vehicle '%s' not found", self.vehicleName)
	end
	local fillUnitIndex = self.fillUnitIndex
	local fillTypeIndex = vehicle:getFillUnitFillType(fillUnitIndex)
	local fillLevel = vehicle:getFillUnitFillLevel(fillUnitIndex)
	local farmId = vehicle:getOwnerFarmId()
	local toolType = ToolType.UNDEFINED
	local fillPositionData = nil
	local fillLevelDelta = self.fillLevel - fillLevel
	vehicle:addFillUnitFillLevel(farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, nil)
	return true
end
function ActionVehicleSetFillLevel.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local vehicleName = xmlFile:getValue(key .. "#vehicle")
	local fillUnitIndex = xmlFile:getValue(key .. "#fillUnitIndex")
	local fillLevel = xmlFile:getValue(key .. "#fillLevel")
	if vehicleName ~= nil and (fillUnitIndex ~= nil and fillLevel ~= nil) then
		return ActionVehicleSetFillLevel.new(vehicleName, fillUnitIndex, fillLevel)
	end
	return nil
end
g_guidedTourManager:registerActionClass(ActionVehicleSetFillLevel.NAME, ActionVehicleSetFillLevel)
