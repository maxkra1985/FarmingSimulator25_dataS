-- Local values: ActionNPCMove_mt
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

-- Upvalues: ActionNPCMove_mt
-- Local values: self
function ActionNPCMove.new(npcName, reset, vehicleName, offsetX, offsetY, offsetZ, offsetRotX, offsetRotY, offsetRotZ, distance, alignToTerrain, customMt)
	-- upvalues: (copy) ActionNPCMove_mt
	local v15_ = customMt or ActionNPCMove_mt
	local v16_ = setmetatable({}, v15_)
	v16_.npcName = npcName
	v16_.reset = reset
	v16_.vehicleName = vehicleName
	v16_.offsetX = offsetX
	v16_.offsetY = offsetY
	v16_.offsetZ = offsetZ
	v16_.offsetRotX = offsetRotX
	v16_.offsetRotY = offsetRotY
	v16_.offsetRotZ = offsetRotZ
	v16_.alignToTerrain = alignToTerrain
	return v16_
end

-- Local values: npc, spot, currentSpot, vehicle, spot
function ActionNPCMove:run(tour, step)
	local v19_ = g_npcManager:getNPCByName(self.npcName)
	if v19_ == nil then
		return false
	end
	if self.reset then
		local v20_ = tour:getNPCSpot(self.npcName)
		local v21_ = v19_:getSpot()
		if v21_ == nil or v21_ == v20_ then
			v20_.isAvailable = false
			v19_:setSpot(nil)
		end
		return true
	end
	local v22_
	if self.vehicleName == nil then
		v22_ = nil
	else
		v22_ = g_guidedTourManager:getVehicleByName(self.vehicleName)
		if v22_ == nil then
			Logging.warning("ActionNPCMove.run: Vehicle \'%s\' not found", self.vehicleName)
			return false
		end
	end
	local v23_ = tour:getNPCSpot(self.npcName)
	if v23_ == nil then
		Logging.warning("ActionNPCMove.run: Cannot create spot for npc \'%s\'", self.npcName)
		return false
	end
	v23_.isAvailable = true
	if v22_ == nil then
		local v24_ = self.offsetX
		local v25_ = self.offsetY
		local v26_ = self.offsetZ
		v23_.x = v24_
		v23_.y = v25_
		v23_.z = v26_
		local v27_ = self.offsetRotX
		local v28_ = self.offsetRotY
		local v29_ = self.offsetRotZ
		v23_.rx = v27_
		v23_.ry = v28_
		v23_.rz = v29_
	else
		local v30_, v31_, v32_ = localToWorld(v22_.rootNode, self.offsetX, self.offsetY, self.offsetZ)
		v23_.x = v30_
		v23_.y = v31_
		v23_.z = v32_
		local v33_, v34_, v35_ = localRotationToWorld(v22_.rootNode, self.offsetRotX, self.offsetRotY, self.offsetRotZ)
		v23_.rx = v33_
		v23_.ry = v34_
		v23_.rz = v35_
	end
	if self.alignToTerrain then
		v23_.y = getTerrainHeightAtWorldPos(g_terrainNode, v23_.x, 0, v23_.z)
	end
	v19_:setSpot(v23_)
	return true
end

-- Local values: npcName, offsetX, offsetY, offsetZ, offsetRotX, offsetRotY, offsetRotZ, vehicleName, alignToTerrain, reset
function ActionNPCMove.createFromXML(xmlFile, key, baseDirectory, customEnvironment, stepIndex)
	local v38_ = xmlFile:getValue(key .. "#npc")
	if v38_ == nil then
		Logging.xmlWarning(xmlFile, "Missing \'npc\' for \'%s\'", key)
		return nil
	end
	local v39_ = xmlFile:getValue(key .. "#reset")
	local v40_, v41_, v42_, v43_, v44_, v45_, v46_, v47_
	if v39_ then
		v40_ = nil
		v41_ = nil
		v42_ = nil
		v43_ = nil
		v44_ = nil
		v45_ = nil
		v46_ = nil
		v47_ = nil
	else
		v43_, v44_, v45_ = xmlFile:getValue(key .. "#offset")
		if v43_ == nil or (v44_ == nil or v45_ == nil) then
			Logging.xmlWarning(xmlFile, "Missing \'offset\' for \'%s\'", key)
			return nil
		end
		v46_, v47_, v40_ = xmlFile:getValue(key .. "#offsetRotation")
		if v46_ == nil or (v47_ == nil or v40_ == nil) then
			Logging.xmlWarning(xmlFile, "Missing \'offsetRotation\' for \'%s\'", key)
			return nil
		end
		v42_ = xmlFile:getValue(key .. "#vehicle")
		v41_ = xmlFile:getValue(key .. "#alignToTerrain", false)
	end
	return ActionNPCMove.new(v38_, v39_, v42_, v43_, v44_, v45_, v46_, v47_, v40_, v41_)
end
g_guidedTourManager:registerActionClass(ActionNPCMove.NAME, ActionNPCMove)
