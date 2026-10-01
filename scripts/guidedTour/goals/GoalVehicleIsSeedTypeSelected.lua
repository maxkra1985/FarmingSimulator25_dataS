GoalVehicleIsSeedTypeSelected = {}
GoalVehicleIsSeedTypeSelected.NAME = "vehicleIsSeedTypeSelected"
local GoalVehicleIsSeedTypeSelected_mt = Class(GoalVehicleIsSeedTypeSelected)
function GoalVehicleIsSeedTypeSelected.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Identifier of the vehicle", nil, true)
	schema:register(XMLValueType.STRING, basePath .. "#seedTypeName", "Name of the seedtype", nil, true)
end
function GoalVehicleIsSeedTypeSelected.new(vehicleName, seedTypeName, customMt)
	local self = setmetatable({}, customMt or GoalVehicleIsSeedTypeSelected_mt)
	self.vehicleName = vehicleName
	self.seedTypeName = seedTypeName
	return self
end
function GoalVehicleIsSeedTypeSelected:activate(tour, step)
	self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if self.vehicle == nil then
		Logging.warning("GoalVehicleIsSeedTypeSelected.activate: Vehicle '%s' not found", self.vehicleName)
		return
	end
	self.seedFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(self.seedTypeName)
	if self.seedFillTypeIndex == nil then
		Logging.warning("GoalVehicleIsSeedTypeSelected.activate: Invalid seed type name '%s'", self.seedTypeName)
	end
end
function GoalVehicleIsSeedTypeSelected:deactivate()
	self.vehicle = nil
end
function GoalVehicleIsSeedTypeSelected:isAchieved()
	if self.vehicle == nil then
		return true
	end
	local seedFillTypeIndex = self.vehicle:getSowingMachineSeedFillTypeIndex()
	if seedFillTypeIndex == nil then
		return true
	else
		return seedFillTypeIndex == self.seedFillTypeIndex
	end
end
function GoalVehicleIsSeedTypeSelected.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local vehicleName = xmlFile:getValue(key .. "#vehicle")
	if vehicleName == nil then
		Logging.xmlWarning(xmlFile, "Missing 'vehicle' for '%s'", key)
		return nil
	end
	local seedTypeName = xmlFile:getValue(key .. "#seedTypeName")
	if seedTypeName == nil then
		Logging.xmlWarning(xmlFile, "Missing 'seedTypeName' for '%s'", key)
		return nil
	else
		return GoalVehicleIsSeedTypeSelected.new(vehicleName, seedTypeName)
	end
end
g_guidedTourManager:registerGoalClass(GoalVehicleIsSeedTypeSelected.NAME, GoalVehicleIsSeedTypeSelected)
