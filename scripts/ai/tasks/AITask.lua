-- Local values: AITask_mt
AITask = {}
local AITask_mt = Class(AITask)

-- Upvalues: AITask_mt
-- Local values: self
function AITask.new(isServer, job, customMt)
	-- upvalues: (copy) AITask_mt
	local v5_ = customMt or AITask_mt
	local v6_ = setmetatable({}, v5_)
	v6_.isServer = isServer
	v6_.job = job
	v6_.isFinished = false
	v6_.isRunning = false
	v6_.markAsFinished = false
	return v6_
end

function AITask:delete() end

function AITask:update(dt) end

function AITask:start()
	self.isFinished = false
	self.isRunning = true
	if self.markAsFinished then
		self.isFinished = true
		self.markAsFinished = false
	end
end

function AITask:skip()
	if self.isRunning then
		self.isFinished = true
	else
		self.markAsFinished = true
	end
end

function AITask:stop(wasJobStopped)
	self.isRunning = false
	self.markAsFinished = false
end

function AITask:reset()
	self.isFinished = false
end

function AITask:validate(ignoreUnsetParameters)
	return true, nil
end

function AITask:getIsFinished()
	return self.isFinished
end
