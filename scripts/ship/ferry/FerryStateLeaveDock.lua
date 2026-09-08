-- Local values: FerryStateLeaveDock_mt
FerryStateLeaveDock = {}
local FerryStateLeaveDock_mt = Class(FerryStateLeaveDock, FerryState)

-- Upvalues: FerryStateLeaveDock_mt
-- Local values: self
function FerryStateLeaveDock.new(ferry, customMt)
	-- upvalues: (copy) FerryStateLeaveDock_mt
	return FerryState.new(ferry, customMt or FerryStateLeaveDock_mt)
end

function FerryStateLeaveDock:deactivate()
	FerryStateLeaveDock:superClass().deactivate(self)
	self.ferry:mountObjects()
end
