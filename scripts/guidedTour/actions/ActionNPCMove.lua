ActionNPCMove = {}
ActionNPCMove.NAME = "npcMove"
local ActionNPCMove_mt = Class(ActionNPCMove)
function ActionNPCMove.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#npc", "Name of the npc", nil, true)
	schema:register(XMLValueType.BOOL, basePath .. "#reset", "If NPC should be reset", nil, false)
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#offset", "Target position of the npc (offset to rootnode or vehicle)", nil, false)
	schema:register(XMLValueType.VECTOR_ROT, basePath .. "#offsetRotation", "Target rotation of the npc (offset rotation to rootnode or vehicle)", nil, false)
	schema:register(XMLValueType.BOOL, basePath .. "#alignToTerrain", "The npc position will be aligned to the terrain", false, false)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle the npc position should be offset to", nil, false)
end
function ActionNPCMove.new(npcName, reset, vehicleName, offsetX, offsetY, offsetZ, offsetRotX, offsetRotY, offsetRotZ, distance, alignToTerrain, customMt)
	local self = setmetatable({}, customMt or ActionNPCMove_mt)
	self.npcName = npcName
	self.reset = reset
	self.vehicleName = vehicleName
	self.offsetX = offsetX
	self.offsetY = offsetY
	self.offsetZ = offsetZ
	self.offsetRotX = offsetRotX
	self.offsetRotY = offsetRotY
	self.offsetRotZ = offsetRotZ
	self.alignToTerrain = alignToTerrain
	return self
end
function ActionNPCMove:run(tour, step)
	local npc = g_npcManager:getNPCByName(self.npcName)
	if npc == nil then
		return false
	elseif self.reset then
		local spot = tour:getNPCSpot(self.npcName)
		local currentSpot = npc:getSpot()
		if currentSpot == nil or currentSpot == spot then
			spot.isAvailable = false
			npc:setSpot(nil)
		end
		return true
	else
		local vehicle = nil
		if self.vehicleName ~= nil then
			vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
			if vehicle == nil then
				Logging.warning("ActionNPCMove.run: Vehicle '%s' not found", self.vehicleName)
				return false
			end
		end
		local spot = tour:getNPCSpot(self.npcName)
		if spot == nil then
			Logging.warning("ActionNPCMove.run: Cannot create spot for npc '%s'", self.npcName)
			return false
		else
			spot.isAvailable = true
			if vehicle ~= nil then
				spot.x, spot.y, spot.z = localToWorld(vehicle.rootNode, self.offsetX, self.offsetY, self.offsetZ)
				spot.rx, spot.ry, spot.rz = localRotationToWorld(vehicle.rootNode, self.offsetRotX, self.offsetRotY, self.offsetRotZ)
			else
				spot.x = self.offsetX
				spot.y = self.offsetY
				spot.z = self.offsetZ
				spot.rx = self.offsetRotX
				spot.ry = self.offsetRotY
				spot.rz = self.offsetRotZ
			end
			if self.alignToTerrain then
				spot.y = getTerrainHeightAtWorldPos(g_terrainNode, spot.x, 0, spot.z)
			end
			npc:setSpot(spot)
			return true
		end
	end
end
function ActionNPCMove.createFromXML(xmlFile, key, baseDirectory, customEnvironment, stepIndex)
	local npcName = xmlFile:getValue(key .. "#npc")
	if npcName == nil then
		Logging.xmlWarning(xmlFile, "Missing 'npc' for '%s'", key)
		return nil
	else
		local offsetX = nil
		local offsetY = nil
		local offsetZ = nil
		local offsetRotX = nil
		local offsetRotY = nil
		local offsetRotZ = nil
		local vehicleName = nil
		local alignToTerrain = nil
		local reset = xmlFile:getValue(key .. "#reset")
		if not reset then
			offsetX, offsetY, offsetZ = xmlFile:getValue(key .. "#offset")
			if offsetX == nil or offsetY == nil or offsetZ == nil then
				Logging.xmlWarning(xmlFile, "Missing 'offset' for '%s'", key)
				return nil
			end
			offsetRotX, offsetRotY, offsetRotZ = xmlFile:getValue(key .. "#offsetRotation")
			if offsetRotX == nil or offsetRotY == nil or offsetRotZ == nil then
				Logging.xmlWarning(xmlFile, "Missing 'offsetRotation' for '%s'", key)
				return nil
			end
			vehicleName = xmlFile:getValue(key .. "#vehicle")
			alignToTerrain = xmlFile:getValue(key .. "#alignToTerrain", false)
		end
		return ActionNPCMove.new(npcName, reset, vehicleName, offsetX, offsetY, offsetZ, offsetRotX, offsetRotY, offsetRotZ, alignToTerrain)
	end
end
g_guidedTourManager:registerActionClass(ActionNPCMove.NAME, ActionNPCMove)
