-- Local values: WildlifeInstanceCompanion_mt
WildlifeInstanceCompanion = {}
local WildlifeInstanceCompanion_mt = Class(WildlifeInstanceCompanion, WildlifeInstance)

-- Upvalues: WildlifeInstanceCompanion_mt
-- Local values: self
function WildlifeInstanceCompanion.new(species, customMt)
	-- upvalues: (copy) WildlifeInstanceCompanion_mt
	local v4_ = WildlifeInstance.new(species, customMt or WildlifeInstanceCompanion_mt)
	v4_.companionId = nil
	v4_.numAnimals = 0
	return v4_
end

function WildlifeInstanceCompanion:delete()
	if self.companionId ~= nil then
		delete(self.companionId)
		self.companionId = nil
	end
	WildlifeInstanceCompanion:superClass().delete(self)
end

function WildlifeInstanceCompanion:getNumAnimals()
	return self.numAnimals
end

function WildlifeInstanceCompanion:setNumAnimals(numAnimals)
	self.numAnimals = numAnimals
end

-- Local values: terrainY
function WildlifeInstanceCompanion:calculateDistanceFrom(positionX, positionZ)
	if self.companionId == nil then
		return math.huge
	end
	local v12_ = getTerrainHeightAtWorldPos(g_terrainNode, positionX, 0, positionZ)
	return getCompanionClosestDistance(self.companionId, positionX, v12_, positionZ)
end

-- Local values: companionAnimalType, companionId, groundMask, obstacleMask, waterMask
function WildlifeInstanceCompanion:spawnAt(x, y, z)
	WildlifeInstanceCompanion:superClass().spawnAt(self, x, y, z)
	if self.companionId ~= nil then
		delete(self.companionId)
		self.companionId = nil
	end
	local v17_ = self.species.companionAnimalType or CompanionAnimalType.DEER
	local v18_ = createAnimalCompanionManager(v17_, self.species.filename, "species.companion", x, y, z, g_terrainNode, false, true, self.numAnimals, AudioGroup.ENVIRONMENT)
	if v18_ ~= 0 then
		self.companionId = v18_
		local v19_ = CollisionFlag.TERRAIN
		local v20_ = CollisionFlag.STATIC_OBJECT + CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE + CollisionFlag.PLAYER + CollisionFlag.BUILDING
		local v21_ = CollisionFlag.WATER
		setCompanionCollisionMask(self.companionId, v19_, v20_, v21_)
		self.foliageBendingNodes = {}
	end
end

-- Local values: _, foliagBendingNode
function WildlifeInstanceCompanion:despawn()
	for _, v23_ in ipairs(self.foliageBendingNodes) do
		g_currentMission.foliageBendingSystem:destroyObject(v23_)
	end
	table.clear(self.foliageBendingNodes)
	if self.companionId ~= nil then
		delete(self.companionId)
		self.companionId = nil
	end
	self.numAnimals = 0
	self.isInitialized = nil
	WildlifeInstanceCompanion:superClass().despawn(self)
end

-- Local values: playerNode, foliageBendingArea, minX, maxX, minZ, maxZ, yOffset, nodes, _, node, foliageBendingId
function WildlifeInstanceCompanion:update(dt)
	WildlifeInstanceCompanion:superClass().update(dt)
	if self.companionId ~= nil then
		local v26_ = g_localPlayer:getCurrentRootNode()
		if v26_ ~= nil then
			setCompanionAvoidPlayer(self.companionId, v26_, self.species.fleeDistance)
		end
		if not self.isInitialized and isCompanionReady(self.companionId) then
			self.isInitialized = true
			local v27_ = self.species.foliageBendingArea
			if v27_ ~= nil then
				local v28_ = v27_.minX
				local v29_ = v27_.maxX
				local v30_ = v27_.minZ
				local v31_ = v27_.maxZ
				local v32_ = v27_.yOffset
				local v33_ = getCompanionNodes(self.companionId)
				for _, v34_ in ipairs(v33_) do
					local v35_ = g_currentMission.foliageBendingSystem:createRectangle(v28_, v29_, v30_, v31_, v32_, v34_)
					local v36_ = self.foliageBendingNodes
					table.insert(v36_, v35_)
				end
			end
		end
	end
end

-- Local values: nodes, index, node
function WildlifeInstanceCompanion:drawDebug()
	if self.isInitialized then
		local v38_ = getCompanionNodes(self.companionId)
		for v39_, v40_ in ipairs(v38_) do
			DebugText.renderAtNode(v40_, string.format("%s companion:%d\nnode:%d #%d", self.species.name, self.companionId, v40_, v39_), DebugUtil.getDebugColor(self.companionId), 0.015)
		end
	end
end
