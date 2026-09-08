-- Local values: NPCSpot_mt
NPCSpot = {}

function NPCSpot.registerXMLPaths(schema, key)
	schema:register(XMLValueType.NODE_INDEX, key .. "#node", "NPC spot node")
	schema:register(XMLValueType.STRING, key .. "#npcName", "NPC name")
	schema:register(XMLValueType.BOOL, key .. "#isStartSpot", "If spot is a spot at game start")
end

function NPCSpot.registerSavegameXMLPaths(schema, key)
	schema:register(XMLValueType.STRING, key .. "#uniqueId")
	schema:register(XMLValueType.STRING, key .. "#npcName")
	schema:register(XMLValueType.VECTOR_TRANS, key .. "#position")
	schema:register(XMLValueType.VECTOR_ROT, key .. "#rotation")
end

-- Local values: spot
function NPCSpot:onCreate(nodeId)
	local v6_ = NPCSpot.createFromNode(nodeId)
	if v6_ ~= nil then
		g_npcManager:addSpot(v6_)
	end
end
local v_u_7_ = Class(NPCSpot)

-- Upvalues: NPCSpot_mt
-- Local values: self
function NPCSpot.new(customMt)
	-- upvalues: (copy) v_u_7_
	local v9_ = customMt or v_u_7_
	return setmetatable({}, v9_)
end

-- Local values: node, npcName, npc
function NPCSpot:loadFromXMLFile(xmlFile, key, components, i3dMappings, uniqueId)
	local v16_ = xmlFile:getValue(key .. "#node", nil, components, i3dMappings)
	if v16_ == nil then
		Logging.xmlWarning(xmlFile, "No spot node defined for npc spot \'%s\'", key)
		return false
	end
	local v17_ = xmlFile:getValue(key .. "#npcName")
	if v17_ == nil then
		Logging.xmlWarning(xmlFile, "Missing \'npcName\' for npc spot \'%s\'", key)
		return false
	end
	local v18_ = g_npcManager:getNPCByName(v17_)
	if v18_ == nil then
		Logging.xmlWarning(xmlFile, "Used npcName \'%s\' not defined for npc spot \'%s\'", v17_, key)
		return false
	end
	self.node = v16_
	self.npc = v18_
	self.isStartSpot = xmlFile:getValue(key .. "#isStartSpot")
	self.needsSaving = false
	self.uniqueId = uniqueId
	return true
end

function NPCSpot:delete()
	g_npcManager:removeSpot(self)
end

function NPCSpot:saveToSavegameXMLFile(xmlFile, key)
	xmlFile:setValue(key .. "#uniqueId", self.uniqueId)
	xmlFile:setValue(key .. "#npcName", self.npc.name)
	xmlFile:setValue(key .. "#position", self.x, self.y, self.z)
	xmlFile:setValue(key .. "#rotation", self.rx, self.ry, self.rz)
end

-- Local values: npcName, npc
function NPCSpot:loadFromSavegameXMLFile(xmlFile, key)
	self.uniqueId = xmlFile:getValue(key .. "#uniqueId")
	local v26_ = xmlFile:getValue(key .. "#npcName")
	local v27_ = g_npcManager:getNPCByName(v26_)
	if v27_ == nil then
		Logging.xmlWarning(xmlFile, "NPC \'%s\' for spot \'%s\' not defined", v26_, key)
		return false
	end
	self.npc = v27_
	local v28_, v29_, v30_ = xmlFile:getValue(key .. "#position")
	self.x = v28_
	self.y = v29_
	self.z = v30_
	local v31_, v32_, v33_ = xmlFile:getValue(key .. "#rotation")
	self.rx = v31_
	self.ry = v32_
	self.rz = v33_
	self.needsSaving = true
	self.isAvailable = true
	return true
end

-- Local values: contour2D, placementCol, minX, _, minZ, maxX, _, maxZ
function NPCSpot:activate()
	local v35_ = createPlaneShapeFrom2DContour("npcSpotPlacementCollision", {
		-1,
		-1,
		1,
		-1,
		1,
		1,
		-1,
		1
	}, true)
	if v35_ ~= 0 then
		setIsNonRenderable(v35_, true)
		removeFromPhysics(v35_)
		link(getRootNode(), v35_)
		setWorldTranslation(v35_, self:getPosition())
		setWorldRotation(v35_, self:getRotation())
		setRigidBodyType(v35_, RigidBodyType.STATIC)
		setCollisionFilterGroup(v35_, CollisionFlag.PLACEMENT_BLOCKING)
		addToPhysics(v35_)
		local v36_, _, v37_ = localToWorld(v35_, -1, 0, -1)
		local v38_, _, v39_ = localToWorld(v35_, 1, 0, 1)
		self.placementCollisionNode = v35_
		self.placementCollisionArea = {
			v36_,
			v37_,
			v38_,
			v39_
		}
		g_densityMapHeightManager:setCollisionMapAreaDirty(v36_, v37_, v38_, v39_, true)
		g_currentMission.aiSystem:setAreaDirty(v36_, v38_, v37_, v39_)
	end
end

-- Local values: minX, minZ, maxX, maxZ
function NPCSpot:deactivate()
	if self.placementCollisionNode ~= nil then
		delete(self.placementCollisionNode)
		self.placementCollisionNode = nil
		local v41_ = self.placementCollisionArea
		local v42_, v43_, v44_, v45_ = unpack(v41_)
		g_densityMapHeightManager:setCollisionMapAreaDirty(v42_, v43_, v44_, v45_, true)
		g_currentMission.aiSystem:setAreaDirty(v42_, v44_, v43_, v45_)
	end
end

function NPCSpot:getIsAvailable()
	if self.node == nil then
		return self.isAvailable
	else
		return getVisibilityConditionEntityState(self.node)
	end
end

function NPCSpot:getPosition()
	if self.node == nil then
		return self.x, self.y, self.z
	else
		return getWorldTranslation(self.node)
	end
end

function NPCSpot:getRotation()
	if self.node == nil then
		return self.rx, self.ry, self.rz
	else
		return getWorldRotation(self.node)
	end
end

function NPCSpot:getUniqueId()
	return self.uniqueId
end

-- Local values: npcName, npc, uniqueId, spot
function NPCSpot.createFromNode(node)
	local v51_ = getUserAttribute(node, "npcName")
	if v51_ == nil then
		Logging.warning("Missing user attribute \'npcName\' for npc spot node \'%s\'", getName(node))
		return nil
	end
	local v52_ = g_npcManager:getNPCByName(v51_)
	if v52_ == nil then
		Logging.warning("Used npcName \'%s\' not defined for spot node \'%s\'", v51_, getName(node))
		return nil
	end
	local v53_ = getUserAttribute(node, "uniqueId")
	if v53_ == nil then
		Logging.warning("Missing user attribute \'uniqueId\' for npc spot node \'%s\'", getName(node))
		return nil
	end
	if g_npcManager:getSpotByUniqueId(v53_) ~= nil then
		Logging.warning("UniqueId \'%s\' already in use for npc spot node \'%s\'", v53_, getName(node))
		return nil
	end
	local v54_ = NPCSpot.new()
	v54_.node = node
	v54_.uniqueId = v53_
	v54_.npc = v52_
	v54_.isStartSpot = getUserAttribute(node, "isStartSpot")
	v54_.needsSaving = false
	return v54_
end

-- Local values: spot
function NPCSpot.create(uniqueId, npc, x, y, z, rx, ry, rz, needsSaving)
	local v64_ = NPCSpot.new()
	v64_.uniqueId = uniqueId
	v64_.npc = npc
	v64_.x = x
	v64_.y = y
	v64_.z = z
	v64_.rx = rx
	v64_.ry = ry
	v64_.rz = rz
	v64_.needsSaving = needsSaving
	return v64_
end
