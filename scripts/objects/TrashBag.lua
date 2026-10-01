TrashBag = {}
local TrashBag_mt = Class(TrashBag)
function TrashBag.onCreate(id)
	g_currentMission:addNonUpdateable(TrashBag.new(id))
end
function TrashBag.new(id)
	local self = setmetatable({}, TrashBag_mt)
	self.id = id
	if 0.5 < math.random() then
		setVisibility(self.id, true)
	else
		setVisibility(self.id, false)
	end
	g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.onPeriodChanged, self)
	return self
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
		if not getVisibility(self.id) and 0.666 < math.random() then
			setVisibility(self.id, true)
		end
	end
end
