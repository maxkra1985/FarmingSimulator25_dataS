-- Local values: TimedVisibility_mt
TimedVisibility = {}
local TimedVisibility_mt = Class(TimedVisibility)

function TimedVisibility.onCreate(id)
	g_currentMission:addNonUpdateable(TimedVisibility.new(id))
end

-- Upvalues: TimedVisibility_mt
-- Local values: self
function TimedVisibility.new(id)
	-- upvalues: (copy) TimedVisibility_mt
	local v4_ = TimedVisibility_mt
	local v5_ = setmetatable({}, v4_)
	v5_.id = id
	v5_.startHour = Utils.getNoNil(getUserAttribute(v5_.id, "startHour"), 0)
	v5_.endHour = Utils.getNoNil(getUserAttribute(v5_.id, "endHour"), 24)
	v5_.wrap = v5_.endHour < v5_.startHour
	if g_currentMission ~= nil and g_currentMission.environment ~= nil then
		v5_:hourChanged()
		g_messageCenter:subscribe(MessageType.HOUR_CHANGED, v5_.hourChanged, v5_)
	end
	return v5_
end

function TimedVisibility:delete()
	g_messageCenter:unsubscribeAll(self)
end

-- Local values: currentHour
function TimedVisibility:hourChanged()
	local v8_ = g_currentMission.environment.currentHour
	if self.wrap then
		setVisibility(self.id, self.startHour <= v8_ and true or v8_ < self.endHour)
	else
		local v9_ = setVisibility
		local v10_ = self.id
		local v11_
		if self.startHour <= v8_ then
			v11_ = v8_ < self.endHour
		else
			v11_ = false
		end
		v9_(v10_, v11_)
	end
end
