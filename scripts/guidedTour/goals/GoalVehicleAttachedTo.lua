-- Local values: GoalVehicleAttachedTo_mt
GoalVehicleAttachedTo = {}
GoalVehicleAttachedTo.NAME = "vehicleAttachedTo"
local GoalVehicleAttachedTo_mt = Class(GoalVehicleAttachedTo)

function GoalVehicleAttachedTo.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Identifier of the vehicle", nil, true)
	schema:register(XMLValueType.STRING, basePath .. "#attachment", "Identifier of the attachment", nil, true)
end

-- Upvalues: GoalVehicleAttachedTo_mt
-- Local values: self
function GoalVehicleAttachedTo.new(vehicleName, attachmentName, customMt)
	-- upvalues: (copy) GoalVehicleAttachedTo_mt
	local v7_ = customMt or GoalVehicleAttachedTo_mt
	local v8_ = setmetatable({}, v7_)
	v8_.vehicleName = vehicleName
	v8_.attachmentName = attachmentName
	return v8_
end

function GoalVehicleAttachedTo:activate(tour, step)
	self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if self.vehicle == nil then
		Logging.warning("GoalVehicleAttachedTo.activate: Vehicle \'%s\' not found", self.vehicleName)
	else
		self.attachment = g_guidedTourManager:getVehicleByName(self.attachmentName)
		if self.attachment == nil then
			Logging.warning("GoalVehicleAttachedTo.activate: Attachment \'%s\' not found", self.attachmentName)
		end
	end
end

function GoalVehicleAttachedTo:deactivate()
	self.vehicle = nil
	self.attachment = nil
end

-- Local values: rootVehicle
function GoalVehicleAttachedTo:isAchieved()
	return (self.vehicle == nil or self.attachment == nil) and true or self.attachment.rootVehicle == self.vehicle
end

-- Local values: vehicleName, attachmentName
function GoalVehicleAttachedTo.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v14_ = xmlFile:getValue(key .. "#vehicle")
	if v14_ == nil then
		Logging.xmlWarning(xmlFile, "Missing \'vehicle\' for \'%s\'", key)
		return nil
	end
	local v15_ = xmlFile:getValue(key .. "#attachment")
	if v15_ ~= nil then
		return GoalVehicleAttachedTo.new(v14_, v15_)
	end
	Logging.xmlWarning(xmlFile, "Missing \'attachment\' for \'%s\'", key)
	return nil
end
g_guidedTourManager:registerGoalClass(GoalVehicleAttachedTo.NAME, GoalVehicleAttachedTo)
