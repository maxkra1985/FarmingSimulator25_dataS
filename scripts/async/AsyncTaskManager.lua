-- Local values: AsyncTaskManager_mt
AsyncTaskManager = {}
AsyncTaskManager.MAX_MS_PER_FRAME = 0.5
local AsyncTaskManager_mt = Class(AsyncTaskManager)

-- Upvalues: AsyncTaskManager_mt
-- Local values: self
function AsyncTaskManager.new(customMt)
	-- upvalues: (copy) AsyncTaskManager_mt
	local v3_ = customMt or AsyncTaskManager_mt
	local v4_ = setmetatable({}, v3_)
	v4_:initDataStructures()
	return v4_
end

function AsyncTaskManager:initDataStructures()
	self.firstTask = nil
	self.lastTask = nil
	self.currentRunningTask = nil
	self.enabled = true
	self.doTracing = false
	self.executeSubTasksImmediately = self.doTracing and false
	self.allowedTimeMsPerFrame = nil
end

function AsyncTaskManager:runLambda(lambda)
	if self.doTracing then
		traceOn(2)
		lambda()
		traceOff()
	else
		lambda()
	end
end

-- Local values: taskCb
function AsyncTaskManager:addTask(lambda, name)
	if self.enabled then
		local v11_ = {
			["lambda"] = lambda,
			["nextTask"] = nil,
			["firstSubTask"] = nil,
			["lastSubTask"] = nil,
			["name"] = name
		}
		if self.currentRunningTask == nil then
			if self.doTracing then
				print("Deferred a lambda")
			end
			if self.firstTask == nil then
				self.firstTask = v11_
				self.lastTask = v11_
			else
				self.lastTask.nextTask = v11_
				self.lastTask = v11_
			end
		else
			if self.doTracing then
				print("Queued a sub-lambda")
			end
			if self.currentRunningTask.firstSubTask == nil then
				self.currentRunningTask.firstSubTask = v11_
				self.currentRunningTask.lastSubTask = v11_
			else
				self.currentRunningTask.lastSubTask.nextTask = v11_
				self.currentRunningTask.lastSubTask = v11_
			end
		end
	else
		self:runLambda(lambda)
		return
	end
end

function AsyncTaskManager:addSubtask(lambda, name)
	if self.executeSubTasksImmediately then
		self:runLambda(lambda)
		return
	elseif self.enabled and self.currentRunningTask ~= nil then
		self:addTask(lambda, name)
	else
		if self.enabled then
			printWarning("Warning: addSubtask is *not* queuing the task, because not inside a task")
			printCallstack()
		end
		self:runLambda(lambda)
	end
end

function AsyncTaskManager:hasTasks()
	return self.firstTask ~= nil
end

function AsyncTaskManager:flushAllTasks()
	self:initDataStructures()
	forceEndFrameRepeatMode()
end

-- Local values: taskCb
function AsyncTaskManager:runTopTask()
	if self.firstTask == nil then
		return false
	end
	local v18_ = self.firstTask
	self.firstTask = v18_.nextTask
	if self.firstTask == nil then
		self.lastTask = nil
	end
	self.currentRunningTask = v18_
	self:runLambda(v18_.lambda)
	self.currentRunningTask = nil
	if v18_.firstSubTask ~= nil then
		v18_.lastSubTask.nextTask = self.firstTask
		self.firstTask = v18_.firstSubTask
		if self.lastTask == nil then
			self.lastTask = v18_.lastSubTask
		end
	end
	return true
end

-- Local values: timer, maxTime
function AsyncTaskManager:update(dt)
	if self:hasTasks() then
		local v20_ = openIntervalTimer()
		if v20_ == -1 then
			self:runTopTask()
			return
		end
		local v21_ = self.allowedTimeMsPerFrame
		if not v21_ then
			v21_ = AsyncTaskManager.MAX_MS_PER_FRAME
		end
		while self:hasTasks() do
			self:runTopTask()
			if v21_ < readIntervalTimerMs(v20_) then
				break
			end
		end
		closeIntervalTimer(v20_)
	end
end

function AsyncTaskManager:setAllowedTimePerFrame(timePerFrameMs)
	self.allowedTimeMsPerFrame = timePerFrameMs
end
g_asyncTaskManager = AsyncTaskManager.new()
