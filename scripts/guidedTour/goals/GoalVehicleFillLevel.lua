-- Local values: GoalVehicleFillLevel_mt
GoalVehicleFillLevel = {}
GoalVehicleFillLevel.NAME = "vehicleFillLevel"
local GoalVehicleFillLevel_mt = Class(GoalVehicleFillLevel)

function GoalVehicleFillLevel.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Identifier of the vehicle", nil, true)
	schema:register(XMLValueType.INT, basePath .. "#fillUnit", "Fillunit index of the vehicle", nil, true)
	schema:register(XMLValueType.FLOAT, basePath .. "#below", "Filllevel of the vehicle (below)", nil, false)
	schema:register(XMLValueType.FLOAT, basePath .. "#above", "Filllevel of the vehicle (above)", nil, false)
end

-- Upvalues: GoalVehicleFillLevel_mt
-- Local values: self
function GoalVehicleFillLevel.new(vehicleName, fillUnitIndex, below, above, customMt)
	-- upvalues: (copy) GoalVehicleFillLevel_mt
	local v9_ = customMt or GoalVehicleFillLevel_mt
	local v10_ = setmetatable({}, v9_)
	v10_.vehicleName = vehicleName
	v10_.fillUnitIndex = fillUnitIndex
	v10_.below = below
	v10_.above = above
	return v10_
end

function GoalVehicleFillLevel:activate(tour, step)
	self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if self.vehicle == nil then
		Logging.warning("GoalVehicleFillLevel.activate: Vehicle \'%s\' not found", self.vehicleName)
	end
end

function GoalVehicleFillLevel:deactivate()
	self.vehicle = nil
end

-- Local values: fillLevel
function GoalVehicleFillLevel:isAchieved()
	if self.vehicle == nil then
		return true
	else
		local v14_ = self.vehicle:getFillUnitFillLevel(self.fillUnitIndex)
		if v14_ == nil then
			return true
		elseif self.below == nil then
			return self.above == nil and true or self.above < v14_
		else
			return v14_ < self.below
		end
	end
end

-- Local values: vehicleName, fillUnitIndex, below, above
function GoalVehicleFillLevel.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v17_ = xmlFile:getValue(key .. "#vehicle")
	if v17_ == nil then
		Logging.xmlWarning(xmlFile, "Missing \'vehicle\' for \'%s\'", key)
		return nil
	end
	local v18_ = xmlFile:getValue(key .. "#fillUnit")
	if v18_ == nil then
		Logging.xmlWarning(xmlFile, "Missing \'fillUnit\' for \'%s\'", key)
		return nil
	end
	local v19_ = xmlFile:getValue(key .. "#below")
	local v20_ = xmlFile:getValue(key .. "#above")
	if v19_ ~= nil or v20_ ~= nil then
		return GoalVehicleFillLevel.new(v17_, v18_, v19_, v20_)
	end
	Logging.xmlWarning(xmlFile, "Missing \'below\' or \'above\' for \'%s\'", key)
	return nil
end
g_guidedTourManager:registerGoalClass(GoalVehicleFillLevel.NAME, GoalVehicleFillLevel)
