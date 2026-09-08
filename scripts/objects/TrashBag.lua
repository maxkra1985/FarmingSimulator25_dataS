-- Local values: TrashBag_mt
TrashBag = {}
local TrashBag_mt = Class(TrashBag)

function TrashBag.onCreate(id)
	g_currentMission:addNonUpdateable(TrashBag.new(id))
end

-- Upvalues: TrashBag_mt
-- Local values: self
function TrashBag.new(id)
	-- upvalues: (copy) TrashBag_mt
	local v4_ = TrashBag_mt
	local v5_ = setmetatable({}, v4_)
	v5_.id = id
	if math.random() > 0.5 then
		setVisibility(v5_.id, true)
	else
		setVisibility(v5_.id, false)
	end
	g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, v5_.onPeriodChanged, v5_)
	return v5_
end

function TrashBag:delete()
	g_messageCenter:unsubscribe(MessageType.DAY_CHANGED, self)
end

function TrashBag:onPeriodChanged()
	if g_currentMission ~= nil and g_currentMission.environment ~= nil then
		if g_currentMission.environment.currentPeriod == 1 then
			setVisibility(self.id, false)
			return
		end
		if not getVisibility(self.id) and math.random() > 0.666 then
			setVisibility(self.id, true)
		end
	end
end
