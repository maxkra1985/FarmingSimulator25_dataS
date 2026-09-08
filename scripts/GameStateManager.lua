-- Local values: GameStateManager_mt
GameStateManager = {}
local GameStateManager_mt = Class(GameStateManager)

-- Upvalues: GameStateManager_mt
-- Local values: self
function GameStateManager.new(customMt)
	-- upvalues: (copy) GameStateManager_mt
	local v3_ = customMt or GameStateManager_mt
	local v4_ = setmetatable({}, v3_)
	v4_.gameState = GameState.STARTING
	return v4_
end

function GameStateManager:getGameStateIndexByName(name)
	if name == nil then
		return nil
	end
	local v6_ = string.upper(name)
	return GameState[v6_]
end

function GameStateManager:setGameState(newState)
	if newState ~= nil and self.gameState ~= newState then
		g_messageCenter:publish(MessageType.GAME_STATE_CHANGED, newState, self.gameState)
		self.gameState = newState
	end
end

function GameStateManager:getGameState()
	return self.gameState
end
g_gameStateManager = GameStateManager.new()
