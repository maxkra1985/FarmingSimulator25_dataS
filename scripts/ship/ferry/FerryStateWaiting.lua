FerryStateWaiting = {}
local FerryStateWaiting_mt = Class(FerryStateWaiting, FerryState)
function FerryStateWaiting.new(ferry, customMt)
	local self = FerryState.new(ferry, customMt or FerryStateWaiting_mt)
	self.isFinished = false
	return self
end
function FerryStateWaiting:isDone()
	if not FerryStateWaiting:superClass().isDone(self) then
		return false
	else
		return self.isFinished
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
