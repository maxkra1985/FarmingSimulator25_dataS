-- Local values: GoalVehicleInTrigger_mt
GoalVehicleInTrigger = {}
GoalVehicleInTrigger.NAME = "vehicleInTrigger"
local GoalVehicleInTrigger_mt = Class(GoalVehicleInTrigger)

function GoalVehicleInTrigger.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.VECTOR_2, basePath .. "#worldPosition", "World position of trigger. X and Z values only", nil, true)
	schema:register(XMLValueType.FLOAT, basePath .. "#worldPositionY", "World y position. If defined the y position will not be calculated based on the terrain", nil, false)
	schema:register(XMLValueType.ANGLE, basePath .. "#worldRotationY", "World rotation y", nil, false)
	schema:register(XMLValueType.FLOAT, basePath .. "#radius", "Trigger distance", 2, false)
	schema:register(XMLValueType.FLOAT, basePath .. "#height", "Trigger height", 10, false)
	schema:register(XMLValueType.BOOL, basePath .. "#showMarker", "Show navigation marker", true, false)
	schema:register(XMLValueType.FLOAT, basePath .. "#terrainOffsetY", "Navigation marker terrain offset", 0, false)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle", nil, true)
end

-- Upvalues: GoalVehicleInTrigger_mt
-- Local values: self
function GoalVehicleInTrigger.new(vehicleName, worldPosX, worldPosY, worldPosZ, radius, height, worldRotY, showMarker, terrainOffsetY, customMt)
	-- upvalues: (copy) GoalVehicleInTrigger_mt
	local v14_ = customMt or GoalVehicleInTrigger_mt
	local v15_ = setmetatable({}, v14_)
	v15_.vehicleName = vehicleName
	v15_.worldPosX = worldPosX
	v15_.worldPosY = worldPosY
	v15_.worldPosZ = worldPosZ
	v15_.worldRotY = worldRotY
	v15_.radius = radius
	v15_.height = height or 10
	v15_.showMarker = showMarker
	v15_.terrainOffsetY = terrainOffsetY or 0
	return v15_
end

-- Local values: dirX, dirY, dirZ
function GoalVehicleInTrigger:activate(tour, step)
	self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if self.vehicle == nil then
		Logging.warning("GoalVehicleInTrigger.activate: Vehicle \'%s\' not found", self.vehicleName)
	else
		if self.worldPosY == nil then
			self.worldPosY = getTerrainHeightAtWorldPos(g_terrainNode, self.worldPosX, 0, self.worldPosZ)
		end
		if self.showMarker then
			local v17_, v18_, v19_
			if self.worldRotY == nil then
				v17_ = nil
				v18_ = nil
				v19_ = nil
			else
				local v20_, v21_ = MathUtil.getDirectionFromYRotation(self.worldRotY)
				v17_, v18_, v19_ = MathUtil.vector3Normalize(v20_, 0, v21_)
			end
			g_currentMission.navigationSystem:navigateTo(self.worldPosX, self.worldPosY, self.worldPosZ, v17_, v18_, v19_)
			self.mapHotspot = TourHotspot.new()
			g_currentMission:addMapHotspot(self.mapHotspot)
			self.mapHotspot:setWorldPosition(self.worldPosX, self.worldPosZ)
		end
	end
end

function GoalVehicleInTrigger:deactivate()
	if self.showMarker then
		g_currentMission.navigationSystem:stop()
		g_currentMission:removeMapHotspot(self.mapHotspot)
		self.mapHotspot:delete()
	end
	self.vehicle = nil
end

function GoalVehicleInTrigger:isAchieved()
	if self.vehicle == nil then
		return true
	end
	self.isVehicleInRange = false
	overlapCylinder(self.worldPosX, self.worldPosY + self.height * 0.5, self.worldPosZ, self.radius, self.height, Axis.Y, "onVehicleCallback", self, CollisionFlag.VEHICLE, true, true, false, false)
	return self.isVehicleInRange
end

-- Local values: object
function GoalVehicleInTrigger:onVehicleCallback(transformId)
	if transformId ~= 0 and g_currentMission:getNodeObject(transformId) == self.vehicle then
		self.isVehicleInRange = true
	end
end

-- Local values: vehicleName, worldPosX, worldPosZ, worldPosY, worldRotY, radius, height, showMarker, terrainOffsetY
function GoalVehicleInTrigger.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v28_ = xmlFile:getValue(key .. "#vehicle")
	if v28_ == nil then
		Logging.xmlWarning(xmlFile, "Missing \'vehicle\' for \'%s\'", key)
		return nil
	end
	local v29_, v30_ = xmlFile:getValue(key .. "#worldPosition")
	if v29_ == nil or v30_ == nil then
		Logging.xmlWarning(xmlFile, "Missing \'worldPosition\' for \'%s\'", key)
		return nil
	end
	local v31_ = xmlFile:getValue(key .. "#worldPositionY")
	local v32_ = xmlFile:getValue(key .. "#worldRotationY")
	local v33_ = xmlFile:getValue(key .. "#radius", 2)
	local v34_ = xmlFile:getValue(key .. "#height", 10)
	local v35_ = xmlFile:getValue(key .. "#showMarker", true)
	local v36_ = xmlFile:getValue(key .. "#terrainOffsetY", 0)
	return GoalVehicleInTrigger.new(v28_, v29_, v31_, v30_, v33_, v34_, v32_, v35_, v36_)
end
g_guidedTourManager:registerGoalClass(GoalVehicleInTrigger.NAME, GoalVehicleInTrigger)
