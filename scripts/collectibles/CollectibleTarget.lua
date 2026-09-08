-- Local values: CollectibleTarget_mt
CollectibleTarget = {}
local CollectibleTarget_mt = Class(CollectibleTarget)

function CollectibleTarget:onCreate(node)
	g_currentMission:addNonUpdateable(CollectibleTarget.new(node))
end

-- Upvalues: CollectibleTarget_mt
-- Local values: self
function CollectibleTarget.new(node)
	-- upvalues: (copy) CollectibleTarget_mt
	local v4_ = CollectibleTarget_mt
	local v5_ = setmetatable({}, v4_)
	v5_.node = node
	g_currentMission.collectiblesSystem:addCollectibleTarget(v5_)
	return v5_
end

function CollectibleTarget:delete()
	g_currentMission.collectiblesSystem:removeCollectibleTarget(self)
end
