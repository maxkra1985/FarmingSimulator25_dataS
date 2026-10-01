FerryActivatable = {}
local FerryActivatable_mt = Class(FerryActivatable)
function FerryActivatable.new(ferry)
	local self = setmetatable({}, FerryActivatable_mt)
	self.ferry = ferry
	self.trigger = nil
	self.activateText = g_i18n:getText("action_startFerry")
	return self
end
function FerryActivatable:setTrigger(trigger)
	self.trigger = trigger
end
function FerryActivatable:getIsActivatable()
	if self.ferry:getCanActivateDriving() then
		return true
	else
		return false
	end
end
function FerryActivatable:getDistance(posX, posY, posZ)
	local x, _, z = getWorldTranslation(self.trigger)
	local distance = MathUtil.vector2Length(posX - x, posZ - z)
	return distance
end
function FerryActivatable:run()
	self.ferry:start()
end
