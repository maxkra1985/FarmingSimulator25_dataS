PlayerNetworkComponent = {}

-- Local values: self
function PlayerNetworkComponent.new(player, custom_mt)
	local v3_ = setmetatable({}, custom_mt)
	v3_.player = player
	return v3_
end

function PlayerNetworkComponent:reset() end

function PlayerNetworkComponent:preUpdate(dt) end

function PlayerNetworkComponent:update(dt) end

function PlayerNetworkComponent:updateTick(dt) end

function PlayerNetworkComponent:writeUpdateStream(streamId, connection, dirtyMask) end

function PlayerNetworkComponent:readUpdateStream(streamId, connection, timestamp) end

function PlayerNetworkComponent:debugDraw(x, y, textSize)
	return y
end
