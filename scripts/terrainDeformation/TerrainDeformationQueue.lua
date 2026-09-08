-- Local values: TerrainDeformationQueue_mt
TerrainDeformationQueue = {}
local TerrainDeformationQueue_mt = Class(TerrainDeformationQueue)
function TerrainDeformationQueue.new()
	-- upvalues: (copy) TerrainDeformationQueue_mt
	local v2_ = TerrainDeformationQueue_mt
	local v3_ = setmetatable({}, v2_)
	v3_.jobQueue = {}
	v3_.nextId = 0
	v3_.currentJob = nil
	v3_.cancelling = false
	return v3_
end

function TerrainDeformationQueue:update(dt)
	if not self.cancelling then
		while self:tryRunJob() do

		end
	end
end

-- Local values: job
function TerrainDeformationQueue:queueJob(terrainDeformation, previewOnly, callbackFuncName, callbackObject, callbackArgs)
	self.nextId = self.nextId + 1
	local v11_ = {
		["id"] = self.nextId,
		["deformer"] = terrainDeformation,
		["previewOnly"] = previewOnly,
		["callbackFuncName"] = callbackFuncName,
		["callbackObject"] = callbackObject,
		["callbackArgs"] = callbackArgs
	}
	local v12_ = self.jobQueue
	table.insert(v12_, v11_)
	return self.nextId
end

function TerrainDeformationQueue:tryRunJob()
	if self.currentJob or not self.jobQueue[1] then
		return false
	end
	self.currentJob = self.jobQueue[1]
	table.remove(self.jobQueue, 1)
	if self.currentJob.deformer then
		self.currentJob.deformer:apply(self.currentJob.previewOnly, "onJobComplete", self, self.currentJob.callbackArgs)
	else
		self:onJobComplete(TerrainDeformation.STATE_SUCCESS, 0, "")
	end
	return true
end

function TerrainDeformationQueue:onJobComplete(errorCode, displacedVolume, blockedObjectName, callbackArgs)
	if self.currentJob.callbackFuncName == nil then
		self.currentJob.deformer:delete()
	elseif self.currentJob.callbackObject then
		if self.currentJob.callbackObject[self.currentJob.callbackFuncName] == nil then
			Logging.warning("TerrainDeformationQueue:onJobComplete: no function %q for callback target %q", self.currentJob.callbackFuncName, ClassUtil.getClassNameByObject(self.currentJob.callbackObject))
		else
			self.currentJob.callbackObject[self.currentJob.callbackFuncName](self.currentJob.callbackObject, errorCode, displacedVolume, blockedObjectName, callbackArgs)
		end
	elseif _G[self.currentJob.callbackFuncName] == nil then
		Logging.warning("TerrainDeformationQueue:onJobComplete: no function %q in global scope", self.currentJob.callbackFuncName)
	else
		_G[self.currentJob.callbackFuncName](errorCode, displacedVolume, blockedObjectName, callbackArgs)
	end
	self.currentJob = nil
end

-- Local values: k, job
function TerrainDeformationQueue:cancelJob(jobId)
	for v21_, v22_ in ipairs(self.jobQueue) do
		if v22_.id == jobId then
			table.remove(self.jobQueue, v21_)
			return true
		end
	end
	return false
end

function TerrainDeformationQueue:cancelAllJobs()
	self.cancelling = true
	if self.currentJob then
		self.currentJob.deformer:cancel()
	end
	while self.jobQueue[1] do
		self.currentJob = self.jobQueue[1]
		table.remove(self.jobQueue, 1)
		self:onJobComplete(TerrainDeformation.STATE_CANCELLED, 0, "")
	end
	self.currentJob = nil
	self.cancelling = false
end
g_terrainDeformationQueue = TerrainDeformationQueue.new()
