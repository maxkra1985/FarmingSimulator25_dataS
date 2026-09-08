-- Local values: FerryStateWaiting_mt
FerryStateWaiting = {}
local FerryStateWaiting_mt = Class(FerryStateWaiting, FerryState)

-- Upvalues: FerryStateWaiting_mt
-- Local values: self
function FerryStateWaiting.new(ferry, customMt)
	-- upvalues: (copy) FerryStateWaiting_mt
	local v4_ = FerryState.new(ferry, customMt or FerryStateWaiting_mt)
	v4_.isFinished = false
	return v4_
end

function FerryStateWaiting:isDone()
	if FerryStateWaiting:superClass().isDone(self) then
		return self.isFinished
	else
		return false
	end
end

function FerryStateWaiting:deactivate()
	FerryStateWaiting:superClass().deactivate(self)
	self.isFinished = false
end

function FerryStateWaiting:getCanFinishState()
	return true
end

function FerryStateWaiting:finish()
	self.isFinished = true
end
