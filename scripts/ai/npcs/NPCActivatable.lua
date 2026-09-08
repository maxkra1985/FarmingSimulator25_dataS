-- Local values: NPCActivatable_mt
NPCActivatable = {}
local NPCActivatable_mt = Class(NPCActivatable)

-- Upvalues: NPCActivatable_mt
-- Local values: self
function NPCActivatable.new(npc, interactionAngleThreshold)
	-- upvalues: (copy) NPCActivatable_mt
	local v4_ = NPCActivatable_mt
	local v5_ = setmetatable({}, v4_)
	v5_.npc = npc
	v5_.interactionAngleThreshold = interactionAngleThreshold or 1.0471975511965976
	v5_.activateText = g_i18n:getText("action_startConversation")
	return v5_
end

-- Local values: npcDirX, _, npcDirZ, angle
function NPCActivatable:getIsActivatable(dirX, dirY, dirZ)
	if not self.npc:getCanInteract() then
		return false
	end
	if g_localPlayer == nil then
		return false
	end
	local v9_, _, v10_ = self.npc:getFacingDirection()
	local v11_ = MathUtil.getVectorAngleDifference(v9_, 0, v10_, dirX, 0, dirZ)
	return math.abs(v11_) <= self.interactionAngleThreshold
end

-- Local values: x, _, z, distance
function NPCActivatable:getDistance(posX, posY, posZ)
	if self.npc.node == 0 then
		return math.huge
	end
	local v15_, _, v16_ = getWorldTranslation(self.npc.node)
	return MathUtil.vector2Length(posX - v15_, posZ - v16_)
end

function NPCActivatable:run()
	self.npc:requestConversation(g_localPlayer)
end
