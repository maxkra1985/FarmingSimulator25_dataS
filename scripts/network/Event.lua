-- Local values: Event_mt
Event = {}
local Event_mt = Class(Event)

-- Upvalues: Event_mt
-- Local values: self
function Event.new(customMt, networkChannel)
	-- upvalues: (copy) Event_mt
	local v4_ = customMt or Event_mt
	local v5_ = setmetatable({}, v4_)
	v5_.networkChannel = networkChannel or NetworkNode.CHANNEL_SECONDARY
	v5_.queueCount = 0
	return v5_
end

function Event:delete() end

function Event:readStream(streamId, connection) end

function Event:writeStream(streamId, connection) end

function Event:run(connection) end
