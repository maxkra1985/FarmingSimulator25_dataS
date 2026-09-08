-- Local values: FerryActivatable_mt
FerryActivatable = {}
local FerryActivatable_mt = Class(FerryActivatable)

-- Upvalues: FerryActivatable_mt
-- Local values: self
function FerryActivatable.new(ferry)
	-- upvalues: (copy) FerryActivatable_mt
	local v3_ = FerryActivatable_mt
	local v4_ = setmetatable({}, v3_)
	v4_.ferry = ferry
	v4_.trigger = nil
	v4_.activateText = g_i18n:getText("action_startFerry")
	return v4_
end

function FerryActivatable:setTrigger(trigger)
	self.trigger = trigger
end

function FerryActivatable:getIsActivatable()
	return self.ferry:getCanActivateDriving() and true or false
end

-- Local values: x, _, z, distance
function FerryActivatable:getDistance(posX, posY, posZ)
	local v11_, _, v12_ = getWorldTranslation(self.trigger)
	return MathUtil.vector2Length(posX - v11_, posZ - v12_)
end

function FerryActivatable:run()
	self.ferry:start()
end
