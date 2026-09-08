-- Local values: LadderTrigger_mt
LadderTrigger = {}
local LadderTrigger_mt = Class(LadderTrigger)

function LadderTrigger:onCreate(id)
	g_currentMission:addNonUpdateable(LadderTrigger.new(id))
end

-- Upvalues: LadderTrigger_mt
-- Local values: self
function LadderTrigger.new(node)
	-- upvalues: (copy) LadderTrigger_mt
	local v4_ = LadderTrigger_mt
	local v5_ = setmetatable({}, v4_)
	if g_currentMission:getIsClient() then
		v5_.triggerId = node
		if not CollisionFlag.getHasMaskFlagSet(node, CollisionFlag.PLAYER) then
			Logging.warning("Missing collision mask bit \'%d\'. Please add this bit to ladder trigger node \'%s\'", CollisionFlag.getBit(CollisionFlag.PLAYER), I3DUtil.getNodePath(node))
		end
		addTrigger(node, "triggerCallback", v5_)
	end
	return v5_
end

function LadderTrigger:delete()
	if self.triggerId ~= nil then
		removeTrigger(self.triggerId)
	end
end

function LadderTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if (onEnter or onLeave) and (g_localPlayer ~= nil and otherId == g_localPlayer.rootNode) then
		if onEnter then
			g_localPlayer.mover:setIsOnLadder(true)
			return
		end
		g_localPlayer.mover:setIsOnLadder(false)
	end
end
