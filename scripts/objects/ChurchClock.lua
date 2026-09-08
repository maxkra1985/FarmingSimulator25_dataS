-- Local values: ChurchClock_mt
ChurchClock = {}
local ChurchClock_mt = Class(ChurchClock)

function ChurchClock:onCreate(node)
	if g_currentMission.isLoadingMap then
		g_currentMission:addNonUpdateable(ChurchClock.new(node))
	else
		Logging.i3dWarning(node, "ChurchClock:onCreate() can only be used within the map itself, not placeables")
	end
end

-- Upvalues: ChurchClock_mt
-- Local values: self, i, clockNode, shortHand, longHand
function ChurchClock.new(node)
	-- upvalues: (copy) ChurchClock_mt
	local v4_ = ChurchClock_mt
	local v5_ = setmetatable({}, v4_)
	v5_.clocks = {}
	for v6_ = 0, getNumOfChildren(node) - 1 do
		local v7_ = getChildAt(node, v6_)
		if v7_ ~= nil then
			local v8_ = getChildAt(v7_, 0)
			local v9_ = getChildAt(v7_, 1)
			if v8_ ~= nil and v9_ ~= nil then
				local v10_ = v5_.clocks
				table.insert(v10_, {
					["shortHand"] = v8_,
					["longHand"] = v9_
				})
			end
		end
	end
	v5_.hasClocks = #v5_.clocks > 0
	if v5_.hasClocks then
		g_messageCenter:subscribe(MessageType.MINUTE_CHANGED, v5_.minuteChanged, v5_)
	end
	return v5_
end

function ChurchClock:delete()
	g_messageCenter:unsubscribeAll(self)
end

-- Local values: shortHandRot, longHandRot, _, c
function ChurchClock:minuteChanged()
	if self.hasClocks then
		local v13_ = 6.283185307179586 * (g_currentMission.environment.dayTime / 43200000)
		local v14_ = 6.283185307179586 * (g_currentMission.environment.dayTime / 3600000)
		for _, v15_ in pairs(self.clocks) do
			setRotation(v15_.shortHand, 0, 0, -v13_)
			setRotation(v15_.longHand, 0, 0, -v14_)
		end
	end
end
