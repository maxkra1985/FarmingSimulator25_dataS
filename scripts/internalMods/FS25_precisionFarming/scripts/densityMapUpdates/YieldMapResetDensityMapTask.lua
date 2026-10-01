YieldMapResetDensityMapTask = {}
local YieldMapResetDensityMapTask_mt = Class(YieldMapResetDensityMapTask, DensityMapUpdateTask)
function YieldMapResetDensityMapTask.registerXMLPaths(schema, basePath)
	DensityMapUpdateTask.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#farmlandId", "Id of the farmland")
end
function YieldMapResetDensityMapTask.new(customMt)
	local self = YieldMapResetDensityMapTask:superClass().new(customMt or YieldMapResetDensityMapTask_mt)
	self.farmlandId = nil
	self.multiModifier = nil
	self.frameBudget = 0.00025
	self.frames = 0
	self.totalTime = 0
	self.minX = -g_currentMission.terrainSize * 0.5
	self.maxX = g_currentMission.terrainSize * 0.5
	self.minZ = -g_currentMission.terrainSize * 0.5
	self.maxZ = g_currentMission.terrainSize * 0.5
	return self
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
function YieldMapResetDensityMapTask:loadFromXMLFile(xmlFile, key)
	local farmlandId = xmlFile:getInt(key .. "#farmlandId")
	if farmlandId ~= nil then
		self.farmlandId = farmlandId
	end
	self.state = DensityMapUpdateTaskState.getByName(xmlFile:getString(key .. "#status")) or DensityMapUpdateTaskState.CREATED
	if self.state == DensityMapUpdateTaskState.RUNNING then
		self.currentMinZ = xmlFile:getFloat(key .. ".area#currentMinZ")
		self.currentMaxZ = xmlFile:getFloat(key .. ".area#currentMaxZ")
	end
	if g_precisionFarming ~= nil and g_precisionFarming.yieldMap ~= nil then
		self.multiModifier = g_precisionFarming.yieldMap:getResetMultiModifier(farmlandId)
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
function YieldMapResetDensityMapTask:start()
	if self.multiModifier == nil then
		Logging.error("YieldMapResetDensityMapTask:start() - MultiModifier not set!")
		return false
	elseif self.state == DensityMapUpdateTaskState.RUNNING or self.state == DensityMapUpdateTaskState.FINISHED then
		return false
	else
		self.state = DensityMapUpdateTaskState.RUNNING
		self:prepare()
		if self.farmlandId ~= nil then
			local farmland = g_farmlandManager:getFarmlandById(self.farmlandId)
			if farmland ~= nil and farmland.getBoundingBox ~= nil then
				local minX, minZ, maxX, maxZ = farmland:getBoundingBox()
				if minX ~= nil then
					self.minX = minX
					self.maxX = maxX
					self.minZ = minZ
					self.maxZ = maxZ
				end
			end
		end
		if self.currentMinZ == nil then
			self.currentMinZ = self.minZ
			self.currentMaxZ = math.min(self.minZ + self.maxRegionPerFrame, self.maxZ)
		end
		return true
	end
end
function YieldMapResetDensityMapTask:update(dt)
	if self.state == DensityMapUpdateTaskState.RUNNING then
		local multiModifier = self.multiModifier
		self.frames = self.frames + 1
		local startTime = getTimeSec()
		while getTimeSec() - startTime < self.frameBudget do
			local startWorldX = self.minX
			local startWorldZ = self.currentMinZ
			local widthWorldX = self.maxX
			local widthWorldZ = self.currentMinZ
			local heightWorldX = self.minX
			local heightWorldZ = self.currentMaxZ
			multiModifier:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
			multiModifier:execute()
			self.currentMinZ = self.currentMaxZ
			self.currentMaxZ = math.min(self.currentMinZ + self.maxRegionPerFrame, self.maxZ)
			if not (self.maxZ <= self.currentMinZ) then
				continue
			end
			self.totalTime = self.totalTime + (getTimeSec() - startTime)
			if self.currentMinZ < self.maxZ then
				return
			else
				if g_precisionFarming ~= nil and g_precisionFarming.yieldMap ~= nil then
					g_precisionFarming:updatePrecisionFarmingOverlays()
					g_precisionFarming.yieldMap:setMinimapRequiresUpdate(true)
				end
				self:setFinished()
				return
			end
		end
	end
end
function YieldMapResetDensityMapTask:setFinished()
	Logging.devInfo("YieldMapResetDensityMapTask: Finished after %d frames / %.1f ms", self.frames, self.totalTime * 1000)
	self.state = DensityMapUpdateTaskState.FINISHED
end
