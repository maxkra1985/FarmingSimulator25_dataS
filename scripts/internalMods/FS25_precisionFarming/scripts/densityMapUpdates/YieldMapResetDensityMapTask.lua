-- Local values: YieldMapResetDensityMapTask_mt
YieldMapResetDensityMapTask = {}
local YieldMapResetDensityMapTask_mt = Class(YieldMapResetDensityMapTask, DensityMapUpdateTask)

function YieldMapResetDensityMapTask.registerXMLPaths(schema, basePath)
	DensityMapUpdateTask.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#farmlandId", "Id of the farmland")
end

-- Upvalues: YieldMapResetDensityMapTask_mt
-- Local values: self
function YieldMapResetDensityMapTask.new(customMt)
	-- upvalues: (copy) YieldMapResetDensityMapTask_mt
	local v5_ = YieldMapResetDensityMapTask:superClass().new(customMt or YieldMapResetDensityMapTask_mt)
	v5_.farmlandId = nil
	v5_.multiModifier = nil
	v5_.frameBudget = 0.00025
	v5_.frames = 0
	v5_.totalTime = 0
	local v6_ = -g_currentMission.terrainSize * 0.5
	local v7_ = g_currentMission.terrainSize * 0.5
	v5_.minX = v6_
	v5_.maxX = v7_
	local v8_ = -g_currentMission.terrainSize * 0.5
	local v9_ = g_currentMission.terrainSize * 0.5
	v5_.minZ = v8_
	v5_.maxZ = v9_
	return v5_
end

function YieldMapResetDensityMapTask:saveToXMLFile(xmlFile, key)
	xmlFile:setString(key .. "#status", DensityMapUpdateTaskState.getName(self.state))
	if self.state == DensityMapUpdateTaskState.RUNNING then
		xmlFile:setFloat(key .. ".area#currentMinZ", self.currentMinZ)
		xmlFile:setFloat(key .. ".area#currentMaxZ", self.currentMaxZ)
	end
	if self.farmlandId ~= nil then
		xmlFile:setInt(key .. "#farmlandId", self.farmlandId)
	end
end

-- Local values: farmlandId
function YieldMapResetDensityMapTask:loadFromXMLFile(xmlFile, key)
	local v16_ = xmlFile:getInt(key .. "#farmlandId")
	if v16_ ~= nil then
		self.farmlandId = v16_
	end
	self.state = DensityMapUpdateTaskState.getByName(xmlFile:getString(key .. "#status")) or DensityMapUpdateTaskState.CREATED
	if self.state == DensityMapUpdateTaskState.RUNNING then
		self.currentMinZ = xmlFile:getFloat(key .. ".area#currentMinZ")
		self.currentMaxZ = xmlFile:getFloat(key .. ".area#currentMaxZ")
	end
	if g_precisionFarming ~= nil and g_precisionFarming.yieldMap ~= nil then
		self.multiModifier = g_precisionFarming.yieldMap:getResetMultiModifier(v16_)
	end
	if self.state == DensityMapUpdateTaskState.RUNNING then
		self:start()
	end
	return true
end

function YieldMapResetDensityMapTask:setData(farmlandId)
	self.farmlandId = farmlandId
	self.multiModifier = g_precisionFarming.yieldMap:getResetMultiModifier(farmlandId)
end

function YieldMapResetDensityMapTask:prepare() end

function YieldMapResetDensityMapTask:enqueue(immediate)
	g_precisionFarming.densityMapUpdater:addUpdateTask(self, immediate)
end

-- Local values: farmland, minX, minZ, maxX, maxZ
function YieldMapResetDensityMapTask:start()
	if self.multiModifier == nil then
		Logging.error("YieldMapResetDensityMapTask:start() - MultiModifier not set!")
		return false
	end
	if self.state == DensityMapUpdateTaskState.RUNNING or self.state == DensityMapUpdateTaskState.FINISHED then
		return false
	end
	self.state = DensityMapUpdateTaskState.RUNNING
	self:prepare()
	if self.farmlandId ~= nil then
		local v22_ = g_farmlandManager:getFarmlandById(self.farmlandId)
		if v22_ ~= nil and v22_.getBoundingBox ~= nil then
			local v23_, v24_, v25_, v26_ = v22_:getBoundingBox()
			if v23_ ~= nil then
				self.minX = v23_
				self.maxX = v25_
				self.minZ = v24_
				self.maxZ = v26_
			end
		end
	end
	if self.currentMinZ == nil then
		self.currentMinZ = self.minZ
		local v27_ = self.minZ + self.maxRegionPerFrame
		local v28_ = self.maxZ
		self.currentMaxZ = math.min(v27_, v28_)
	end
	return true
end

-- Local values: multiModifier, startTime, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ
function YieldMapResetDensityMapTask:update(dt)
	if self.state == DensityMapUpdateTaskState.RUNNING then
		local v30_ = self.multiModifier
		self.frames = self.frames + 1
		local v31_ = getTimeSec()
		while getTimeSec() - v31_ < self.frameBudget do
			v30_:updateParallelogramWorldCoords(self.minX, self.currentMinZ, self.maxX, self.currentMinZ, self.minX, self.currentMaxZ, DensityCoordType.POINT_POINT_POINT)
			v30_:execute()
			self.currentMinZ = self.currentMaxZ
			local v32_ = self.currentMinZ + self.maxRegionPerFrame
			local v33_ = self.maxZ
			self.currentMaxZ = math.min(v32_, v33_)
			if self.currentMinZ >= self.maxZ then
				break
			end
		end
		self.totalTime = self.totalTime + (getTimeSec() - v31_)
		if self.currentMinZ < self.maxZ then
			return
		end
		if g_precisionFarming ~= nil and g_precisionFarming.yieldMap ~= nil then
			g_precisionFarming:updatePrecisionFarmingOverlays()
			g_precisionFarming.yieldMap:setMinimapRequiresUpdate(true)
		end
		self:setFinished()
	end
end

function YieldMapResetDensityMapTask:setFinished()
	Logging.devInfo("YieldMapResetDensityMapTask: Finished after %d frames / %.1f ms", self.frames, self.totalTime * 1000)
	self.state = DensityMapUpdateTaskState.FINISHED
end
