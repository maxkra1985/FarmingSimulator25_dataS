-- Local values: FerryStateArriveDock_mt
FerryStateArriveDock = {}
local FerryStateArriveDock_mt = Class(FerryStateArriveDock, FerryState)

-- Upvalues: FerryStateArriveDock_mt
-- Local values: self
function FerryStateArriveDock.new(ferry, customMt)
	-- upvalues: (copy) FerryStateArriveDock_mt
	return FerryState.new(ferry, customMt or FerryStateArriveDock_mt)
end

function FerryStateArriveDock:deactivate()
	FerryStateArriveDock:superClass().deactivate(self)
	self.ferry:unmountObjects()
end
