-- Local values: FoliageBendingSystem_mt
FoliageBendingSystem = {}
local FoliageBendingSystem_mt = Class(FoliageBendingSystem)
FoliageBendingSystem.maxNumObjects = 64

-- Upvalues: FoliageBendingSystem_mt
-- Local values: self
function FoliageBendingSystem.new(customMt)
	-- upvalues: (copy) FoliageBendingSystem_mt
	local v3_ = customMt or FoliageBendingSystem_mt
	local v4_ = setmetatable({}, v3_)
	v4_.systemId = createFoliageBendingSystem(FoliageBendingSystem.maxNumObjects, 32)
	return v4_
end

function FoliageBendingSystem:delete()
	if self.systemId ~= 0 then
		delete(self.systemId)
	end
end

function FoliageBendingSystem:setTerrainTransformGroup(terrainTransformGroup)
	setFoliageBendingSystem(terrainTransformGroup, self.systemId)
end

function FoliageBendingSystem:createRectangle(minX, maxX, minZ, maxZ, yOffset, parentTransformGroup)
	return createFoliageBendingRectangle(self.systemId, minX, maxX, minZ, maxZ, yOffset, parentTransformGroup)
end

function FoliageBendingSystem:destroyObject(id)
	destroyFoliageBendingObject(self.systemId, id)
end
