GoalVehicleFillLevel = {}
GoalVehicleFillLevel.NAME = "vehicleFillLevel"
local GoalVehicleFillLevel_mt = Class(GoalVehicleFillLevel)
function GoalVehicleFillLevel.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Identifier of the vehicle", nil, true)
	schema:register(XMLValueType.INT, basePath .. "#fillUnit", "Fillunit index of the vehicle", nil, true)
	schema:register(XMLValueType.FLOAT, basePath .. "#below", "Filllevel of the vehicle (below)", nil, false)
	schema:register(XMLValueType.FLOAT, basePath .. "#above", "Filllevel of the vehicle (above)", nil, false)
end
function GoalVehicleFillLevel.new(vehicleName, fillUnitIndex, below, above, customMt)
	local self = setmetatable({}, customMt or GoalVehicleFillLevel_mt)
	self.vehicleName = vehicleName
	self.fillUnitIndex = fillUnitIndex
	self.below = below
	self.above = above
	return self
end
function GoalVehicleFillLevel:activate(tour, step)
	self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if self.vehicle == nil then
		Logging.warning("GoalVehicleFillLevel.activate: Vehicle '%s' not found", self.vehicleName)
	end
end
function GoalVehicleFillLevel:deactivate()
	self.vehicle = nil
end
function GoalVehicleFillLevel:isAchieved()
	if self.vehicle == nil then
		return true
	end
	local fillLevel = self.vehicle:getFillUnitFillLevel(self.fillUnitIndex)
	if fillLevel == nil then
		return true
	elseif self.below ~= nil then
		return fillLevel < self.below
	elseif self.above ~= nil then
		return self.above < fillLevel
	else
		return true
	end
end
function GoalVehicleFillLevel.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local vehicleName = xmlFile:getValue(key .. "#vehicle")
	if vehicleName == nil then
		Logging.xmlWarning(xmlFile, "Missing 'vehicle' for '%s'", key)
		return nil
	end
	local fillUnitIndex = xmlFile:getValue(key .. "#fillUnit")
	if fillUnitIndex == nil then
		Logging.xmlWarning(xmlFile, "Missing 'fillUnit' for '%s'", key)
		return nil
	else
		local below = xmlFile:getValue(key .. "#below")
		local above = xmlFile:getValue(key .. "#above")
		if below == nil and above == nil then
			Logging.xmlWarning(xmlFile, "Missing 'below' or 'above' for '%s'", key)
			return nil
		end
		return GoalVehicleFillLevel.new(vehicleName, fillUnitIndex, below, above)
	end
end
g_guidedTourManager:registerGoalClass(GoalVehicleFillLevel.NAME, GoalVehicleFillLevel)
