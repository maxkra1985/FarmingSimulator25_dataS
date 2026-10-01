FerryStateArriveDock = {}
local FerryStateArriveDock_mt = Class(FerryStateArriveDock, FerryState)
function FerryStateArriveDock.new(ferry, customMt)
	local self = FerryState.new(ferry, customMt or FerryStateArriveDock_mt)
	return self
end
function FerryStateArriveDock:deactivate()
	FerryStateArriveDock:superClass().deactivate(self)
	self.ferry:unmountObjects()
end
