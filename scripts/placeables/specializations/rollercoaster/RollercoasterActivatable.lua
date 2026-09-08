-- Local values: RollercoasterActivatable_mt
RollercoasterActivatable = {}
local RollercoasterActivatable_mt = Class(RollercoasterActivatable)

-- Upvalues: RollercoasterActivatable_mt
-- Local values: self
function RollercoasterActivatable.new(rollercoaster)
	-- upvalues: (copy) RollercoasterActivatable_mt
	local v3_ = RollercoasterActivatable_mt
	local v4_ = setmetatable({}, v3_)
	v4_.rollercoaster = rollercoaster
	v4_.activateText = g_i18n:getText("action_rideRollercoaster")
	return v4_
end

function RollercoasterActivatable:getIsActivatable()
	return self.rollercoaster:getCanEnter()
end

-- Local values: seatIndex
function RollercoasterActivatable:run()
	if self.rollercoaster:getCanEnter() and self.rollercoaster:getFreeSeatIndex() ~= nil then
		g_client:getServerConnection():sendEvent(RollercoasterPassengerEnterRequestEvent.new(self.rollercoaster, g_localPlayer))
	end
end
