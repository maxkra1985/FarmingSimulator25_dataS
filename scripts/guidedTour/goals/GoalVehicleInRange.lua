-- Local values: GoalVehicleInRange_mt
GoalVehicleInRange = {}
GoalVehicleInRange.NAME = "vehicleInRange"
local GoalVehicleInRange_mt = Class(GoalVehicleInRange)

function GoalVehicleInRange.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle", nil, true)
	schema:register(XMLValueType.STRING, basePath .. "#targetVehicle", "Name of the target vehicle", nil, true)
	schema:register(XMLValueType.VECTOR_2, basePath .. "#offset", "Offset from target vehicle", nil, true)
	schema:register(XMLValueType.FLOAT, basePath .. "#radius", "Trigger distance", 2, false)
	schema:register(XMLValueType.FLOAT, basePath .. "#height", "Trigger height", 10, false)
	schema:register(XMLValueType.BOOL, basePath .. "#showMarker", "Show navigation marker", true, false)
	schema:register(XMLValueType.INT, basePath .. "#exactFillRootNodeIndex", "Index of the fill rootnode", nil, false)
end

-- Upvalues: GoalVehicleInRange_mt
-- Local values: self
function GoalVehicleInRange.new(vehicleName, targetVehicleName, offsetX, offsetZ, radius, height, showMarker, exactFillRootNodeIndex, customMt)
	-- upvalues: (copy) GoalVehicleInRange_mt
	local v13_ = customMt or GoalVehicleInRange_mt
	local v14_ = setmetatable({}, v13_)
	v14_.vehicleName = vehicleName
	v14_.targetVehicleName = targetVehicleName
	v14_.offsetX = offsetX
	v14_.offsetZ = offsetZ
	v14_.radius = radius
	v14_.height = height or 10
	v14_.showMarker = showMarker
	v14_.exactFillRootNodeIndex = exactFillRootNodeIndex
	return v14_
end

function GoalVehicleInRange:activate(tour, step)
	self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if self.vehicle == nil then
		Logging.warning("GoalVehicleInRange.activate: Vehicle \'%s\' not found", self.vehicleName)
		return
	else
		self.targetVehicle = g_guidedTourManager:getVehicleByName(self.targetVehicleName)
		if self.targetVehicle == nil then
			Logging.warning("GoalVehicleInRange.activate: Target vehicle \'%s\' not found", self.targetVehicleName)
		end
	end
end

function GoalVehicleInRange:deactivate()
	if self.showMarker then
		g_currentMission.navigationSystem:stop()
	end
	self.vehicle = nil
	self.targetVehicle = nil
end

-- Local values: x, y, z, y, dirX, _, dirZ, dirY, mask
function GoalVehicleInRange:isAchieved()
	if self.vehicle == nil or self.targetVehicle == nil then
		return true
	end
	local v18_, _, v19_ = localToWorld(self.targetVehicle.rootNode, self.offsetX, 0, self.offsetZ)
	local v20_ = getTerrainHeightAtWorldPos(g_terrainNode, v18_, 0, v19_)
	local v21_, _, v22_ = localDirectionToWorld(self.targetVehicle.rootNode, 0, 0, 1)
	if self.showMarker then
		local v23_, v24_, v25_ = MathUtil.vector3Normalize(v21_, 0, v22_)
		g_currentMission.navigationSystem:navigateTo(v18_, v20_, v19_, v23_, v24_, v25_)
	end
	local v26_ = v20_ + self.height * 0.5
	local v27_ = CollisionFlag.VEHICLE
	if self.exactFillRootNodeIndex ~= nil then
		v27_ = CollisionFlag.FILLABLE
	end
	self.isVehicleInRange = false
	overlapCylinder(v18_, v26_, v19_, self.radius, self.height, Axis.Y, "onVehicleCallback", self, v27_, true, true, false, false)
	return self.isVehicleInRange
end

-- Local values: object
function GoalVehicleInRange:onVehicleCallback(hitActorId, subShapeIndex)
	if hitActorId ~= 0 and g_currentMission:getNodeObject(hitActorId) == self.vehicle then
		self.isVehicleInRange = true
	end
end

-- Local values: vehicleName, targetVehicleName, offsetX, offsetZ, radius, height, showMarker, exactFillRootNodeIndex
function GoalVehicleInRange.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v32_ = xmlFile:getValue(key .. "#vehicle")
	if v32_ == nil then
		Logging.xmlWarning(xmlFile, "Missing \'vehicle\' for \'%s\'", key)
		return nil
	end
	local v33_ = xmlFile:getValue(key .. "#targetVehicle")
	if v33_ == nil then
		Logging.xmlWarning(xmlFile, "Missing target vehicle for \'%s\'", key)
		return nil
	end
	local v34_, v35_ = xmlFile:getValue(key .. "#offset")
	if v34_ == nil or v35_ == nil then
		Logging.xmlWarning(xmlFile, "Missing \'offset\' for \'%s\'", key)
		return nil
	end
	local v36_ = xmlFile:getValue(key .. "#radius", 2)
	local v37_ = xmlFile:getValue(key .. "#height", 10)
	local v38_ = xmlFile:getValue(key .. "#showMarker", true)
	local v39_ = xmlFile:getValue(key .. "#exactFillRootNodeIndex")
	return GoalVehicleInRange.new(v32_, v33_, v34_, v35_, v36_, v37_, v38_, v39_)
end
g_guidedTourManager:registerGoalClass(GoalVehicleInRange.NAME, GoalVehicleInRange)
