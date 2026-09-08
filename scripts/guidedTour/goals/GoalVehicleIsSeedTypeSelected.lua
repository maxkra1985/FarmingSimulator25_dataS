-- Local values: GoalVehicleIsSeedTypeSelected_mt
GoalVehicleIsSeedTypeSelected = {}
GoalVehicleIsSeedTypeSelected.NAME = "vehicleIsSeedTypeSelected"
local GoalVehicleIsSeedTypeSelected_mt = Class(GoalVehicleIsSeedTypeSelected)

function GoalVehicleIsSeedTypeSelected.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Identifier of the vehicle", nil, true)
	schema:register(XMLValueType.STRING, basePath .. "#seedTypeName", "Name of the seedtype", nil, true)
end

-- Upvalues: GoalVehicleIsSeedTypeSelected_mt
-- Local values: self
function GoalVehicleIsSeedTypeSelected.new(vehicleName, seedTypeName, customMt)
	-- upvalues: (copy) GoalVehicleIsSeedTypeSelected_mt
	local v7_ = customMt or GoalVehicleIsSeedTypeSelected_mt
	local v8_ = setmetatable({}, v7_)
	v8_.vehicleName = vehicleName
	v8_.seedTypeName = seedTypeName
	return v8_
end

function GoalVehicleIsSeedTypeSelected:activate(tour, step)
	self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if self.vehicle == nil then
		Logging.warning("GoalVehicleIsSeedTypeSelected.activate: Vehicle \'%s\' not found", self.vehicleName)
		return
	else
		self.seedFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(self.seedTypeName)
		if self.seedFillTypeIndex == nil then
			Logging.warning("GoalVehicleIsSeedTypeSelected.activate: Invalid seed type name \'%s\'", self.seedTypeName)
		end
	end
end

function GoalVehicleIsSeedTypeSelected:deactivate()
	self.vehicle = nil
end

-- Local values: seedFillTypeIndex
function GoalVehicleIsSeedTypeSelected:isAchieved()
	if self.vehicle == nil then
		return true
	end
	local v12_ = self.vehicle:getSowingMachineSeedFillTypeIndex()
	return v12_ == nil and true or v12_ == self.seedFillTypeIndex
end

-- Local values: vehicleName, seedTypeName
function GoalVehicleIsSeedTypeSelected.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v15_ = xmlFile:getValue(key .. "#vehicle")
	if v15_ == nil then
		Logging.xmlWarning(xmlFile, "Missing \'vehicle\' for \'%s\'", key)
		return nil
	end
	local v16_ = xmlFile:getValue(key .. "#seedTypeName")
	if v16_ ~= nil then
		return GoalVehicleIsSeedTypeSelected.new(v15_, v16_)
	end
	Logging.xmlWarning(xmlFile, "Missing \'seedTypeName\' for \'%s\'", key)
	return nil
end
g_guidedTourManager:registerGoalClass(GoalVehicleIsSeedTypeSelected.NAME, GoalVehicleIsSeedTypeSelected)
