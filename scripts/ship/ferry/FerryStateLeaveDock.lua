FerryStateLeaveDock = {}
local FerryStateLeaveDock_mt = Class(FerryStateLeaveDock, FerryState)
function FerryStateLeaveDock.new(ferry, customMt)
	local self = FerryState.new(ferry, customMt or FerryStateLeaveDock_mt)
	return self
end
function FerryStateLeaveDock:deactivate()
	FerryStateLeaveDock:superClass().deactivate(self)
	self.ferry:mountObjects()
end
