ChurchClock = {}
local ChurchClock_mt = Class(ChurchClock)
function ChurchClock:onCreate(node)
	if not g_currentMission.isLoadingMap then
		Logging.i3dWarning(node, "ChurchClock:onCreate() can only be used within the map itself, not placeables")
	else
		g_currentMission:addNonUpdateable(ChurchClock.new(node))
	end
end
function ChurchClock.new(node)
	local self = setmetatable({}, ChurchClock_mt)
	self.clocks = {}
	for i = 0, getNumOfChildren(node) - 1 do
		local clockNode = getChildAt(node, i)
		if clockNode == nil then
			continue
		end
		local shortHand = getChildAt(clockNode, 0)
		local longHand = getChildAt(clockNode, 1)
		if shortHand == nil or longHand == nil then
			continue
		end
		table.insert(self.clocks, { shortHand = shortHand, longHand = longHand })
	end
	self.hasClocks = 0 < #self.clocks
	if self.hasClocks then
		g_messageCenter:subscribe(MessageType.MINUTE_CHANGED, self.minuteChanged, self)
	end
	return self
end
function ChurchClock:delete()
	g_messageCenter:unsubscribeAll(self)
end
function ChurchClock:minuteChanged()
	if self.hasClocks then
		local shortHandRot = 6.283185307179586 * (g_currentMission.environment.dayTime / 43200000)
		local longHandRot = 6.283185307179586 * (g_currentMission.environment.dayTime / 3600000)
		for _, c in pairs(self.clocks) do
			setRotation(c.shortHand, 0, 0, -shortHandRot)
			setRotation(c.longHand, 0, 0, -longHandRot)
		end
	end
end
