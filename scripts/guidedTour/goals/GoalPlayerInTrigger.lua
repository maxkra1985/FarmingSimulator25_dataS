-- Local values: GoalPlayerInTrigger_mt
GoalPlayerInTrigger = {}
GoalPlayerInTrigger.NAME = "playerInTrigger"
local GoalPlayerInTrigger_mt = Class(GoalPlayerInTrigger)

function GoalPlayerInTrigger.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.VECTOR_2, basePath .. "#offset", "If vehicle is given offset is local to vehicle rootnode, else world positions are assumed. X and Z values only", nil, true)
	schema:register(XMLValueType.FLOAT, basePath .. "#offsetY", "Local y offset if vehicle is given, else terrain offset", 0, false)
	schema:register(XMLValueType.FLOAT, basePath .. "#radius", "Trigger distance", 2, false)
	schema:register(XMLValueType.BOOL, basePath .. "#showMarker", "Show navigation marker", true, false)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle the position should be offset to", nil, false)
	schema:register(XMLValueType.STRING, basePath .. "#npc", "Name of the npc the position should be offset to", nil, false)
end

-- Upvalues: GoalPlayerInTrigger_mt
-- Local values: self
function GoalPlayerInTrigger.new(vehicleName, npcName, offsetX, offsetY, offsetZ, radius, showMarker, customMt)
	-- upvalues: (copy) GoalPlayerInTrigger_mt
	local v12_ = customMt or GoalPlayerInTrigger_mt
	local v13_ = setmetatable({}, v12_)
	v13_.vehicleName = vehicleName
	v13_.npcName = npcName
	v13_.offsetX = offsetX
	v13_.offsetY = offsetY or 0
	v13_.offsetZ = offsetZ
	v13_.radius = radius
	v13_.height = 5
	v13_.axis = Axis.Y
	v13_.showMarker = showMarker
	return v13_
end

function GoalPlayerInTrigger:update(dt)
	self:updateTarget()
end

-- Local values: needUpdate
function GoalPlayerInTrigger:updateTarget()
	local v16_ = false
	if self.vehicle == nil then
		if self.npc ~= nil then
			local v17_, v18_, v19_ = self.npc:getPositionOffset(self.offsetX, self.offsetY, self.offsetZ)
			self.worldPosX = v17_
			self.worldPosY = v18_
			self.worldPosZ = v19_
			v16_ = true
		end
	else
		local v20_, v21_, v22_ = localToWorld(self.vehicle.rootNode, self.offsetX, self.offsetY, self.offsetZ)
		self.worldPosX = v20_
		self.worldPosY = v21_
		self.worldPosZ = v22_
		v16_ = true
	end
	if self.showMarker and v16_ then
		g_currentMission.navigationSystem:navigateTo(self.worldPosX, self.worldPosY, self.worldPosZ)
		self.mapHotspot:setWorldPosition(self.worldPosX, self.worldPosZ)
	end
end

function GoalPlayerInTrigger:activate(tour, step)
	if self.vehicleName == nil then
		if self.npcName == nil then
			self.worldPosX = self.offsetX
			self.worldPosZ = self.offsetZ
			self.worldPosY = getTerrainHeightAtWorldPos(g_terrainNode, self.worldPosX, 0, self.worldPosZ) + self.offsetY
		else
			self.npc = g_npcManager:getNPCByName(self.npcName)
			if self.npc == nil then
				Logging.warning("GoalPlayerInTrigger.activate: NPC \'%s\' not found", self.npcName)
				return
			end
			local v24_, v25_, v26_ = self.npc:getPositionOffset(self.offsetX, self.offsetY, self.offsetZ)
			self.worldPosX = v24_
			self.worldPosY = v25_
			self.worldPosZ = v26_
		end
	else
		self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
		if self.vehicle == nil then
			Logging.warning("GoalPlayerInTrigger.activate: Vehicle \'%s\' not found", self.vehicleName)
			return
		end
		local v27_, v28_, v29_ = localToWorld(self.vehicle.rootNode, self.offsetX, self.offsetY, self.offsetZ)
		self.worldPosX = v27_
		self.worldPosY = v28_
		self.worldPosZ = v29_
	end
	if self.showMarker then
		g_currentMission.navigationSystem:navigateTo(self.worldPosX, self.worldPosY, self.worldPosZ)
		self.mapHotspot = TourHotspot.new()
		g_currentMission:addMapHotspot(self.mapHotspot)
		self.mapHotspot:setWorldPosition(self.worldPosX, self.worldPosZ)
	end
end

function GoalPlayerInTrigger:deactivate()
	if self.showMarker then
		g_currentMission.navigationSystem:stop()
		g_currentMission:removeMapHotspot(self.mapHotspot)
		self.mapHotspot:delete()
		self.mapHotspot = nil
	end
	self.vehicle = nil
	self.npc = nil
end

function GoalPlayerInTrigger:isAchieved()
	if self.vehicleName ~= nil and self.vehicle == nil then
		return true
	end
	self.isPlayerInRange = false
	overlapCylinder(self.worldPosX, self.worldPosY + self.height * 0.5, self.worldPosZ, self.radius, self.height, self.axis, "onPlayerCallback", self, CollisionFlag.PLAYER, true, true, false, false)
	return self.isPlayerInRange
end

function GoalPlayerInTrigger:onPlayerCallback(transformId)
	if transformId ~= 0 and transformId == g_localPlayer.rootNode then
		self.isPlayerInRange = true
	end
end

-- Local values: offsetX, offsetZ, vehicleName, npcName, radius, showMarker, offsetY
function GoalPlayerInTrigger.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v36_, v37_ = xmlFile:getValue(key .. "#offset")
	if v36_ == nil or v37_ == nil then
		Logging.xmlWarning(xmlFile, "Missing \'offset\' for \'%s\'", key)
		return nil
	end
	local v38_ = xmlFile:getValue(key .. "#vehicle")
	local v39_ = xmlFile:getValue(key .. "#npc")
	local v40_ = xmlFile:getValue(key .. "#radius", 2)
	local v41_ = xmlFile:getValue(key .. "#showMarker", true)
	local v42_ = xmlFile:getValue(key .. "#offsetY", 0)
	return GoalPlayerInTrigger.new(v38_, v39_, v36_, v42_, v37_, v40_, v41_)
end
g_guidedTourManager:registerGoalClass(GoalPlayerInTrigger.NAME, GoalPlayerInTrigger)
