NPCActivatable = {}
local NPCActivatable_mt = Class(NPCActivatable)
function NPCActivatable.new(npc, interactionAngleThreshold)
	local self = setmetatable({}, NPCActivatable_mt)
	self.npc = npc
	self.interactionAngleThreshold = interactionAngleThreshold or 1.0471975511965976
	self.activateText = g_i18n:getText("action_startConversation")
	return self
end
function NPCActivatable:getIsActivatable(dirX, dirY, dirZ)
	if not self.npc:getCanInteract() then
		return false
	end
	if g_localPlayer == nil then
		return false
	end
	local npcDirX, _, npcDirZ = self.npc:getFacingDirection()
	local angle = MathUtil.getVectorAngleDifference(npcDirX, 0, npcDirZ, dirX, 0, dirZ)
	if self.interactionAngleThreshold < math.abs(angle) then
		return false
	else
		return true
	end
end
function NPCActivatable:getDistance(posX, posY, posZ)
	if self.npc.node ~= 0 then
		local x, _, z = getWorldTranslation(self.npc.node)
		local distance = MathUtil.vector2Length(posX - x, posZ - z)
		return distance
	else
		return math.huge
	end
end
function NPCActivatable:run()
	self.npc:requestConversation(g_localPlayer)
end
