-- Local values: TramlineMapDensityMapTask_mt
TramlineMapDensityMapTask = {}
local TramlineMapDensityMapTask_mt = Class(TramlineMapDensityMapTask, DensityMapUpdateTask)

function TramlineMapDensityMapTask.registerXMLPaths(schema, basePath)
	DensityMapUpdateTask.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#farmlandId", "Id of the farmland")
end

-- Upvalues: TramlineMapDensityMapTask_mt
-- Local values: self
function TramlineMapDensityMapTask.new(customMt)
	-- upvalues: (copy) TramlineMapDensityMapTask_mt
	local v5_ = TramlineMapDensityMapTask:superClass().new(customMt or TramlineMapDensityMapTask_mt)
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
	v5_.minY = v8_
	v5_.maxY = v9_
	return v5_
end

function TramlineMapDensityMapTask:saveToXMLFile(xmlFile, key)
	xmlFile:setString(key .. "#status", DensityMapUpdateTaskState.getName(self.state))
	if self.state == DensityMapUpdateTaskState.RUNNING then
		xmlFile:setFloat(key .. ".area#currentMinY", self.currentMinY)
		xmlFile:setFloat(key .. ".area#currentMaxY", self.currentMaxY)
	end
	if self.farmlandId ~= nil then
		xmlFile:setInt(key .. "#farmlandId", self.farmlandId)
	end
end

-- Local values: farmlandId
function TramlineMapDensityMapTask:loadFromXMLFile(xmlFile, key)
	local v16_ = xmlFile:getInt(key .. "#farmlandId")
	if v16_ ~= nil then
		self.farmlandId = v16_
	end
	self.state = DensityMapUpdateTaskState.getByName(xmlFile:getString(key .. "#status")) or DensityMapUpdateTaskState.CREATED
	if self.state == DensityMapUpdateTaskState.RUNNING then
		self.currentMinY = xmlFile:getFloat(key .. ".area#currentMinY")
		self.currentMaxY = xmlFile:getFloat(key .. ".area#currentMaxY")
	end
	if g_precisionFarming ~= nil and g_precisionFarming.tramlineMap ~= nil then
		self.multiModifier = g_precisionFarming.tramlineMap:getResetTramlinesMultiMudifier(v16_)
	end
	if self.state == DensityMapUpdateTaskState.RUNNING then
		self:start()
	end
	return true
end

function TramlineMapDensityMapTask:setData(farmlandId)
	self.farmlandId = farmlandId
	self.multiModifier = g_precisionFarming.tramlineMap:getResetTramlinesMultiMudifier(farmlandId)
end

-- Local values: farmland, settings, x, z
function TramlineMapDensityMapTask:prepare()
	local v20_ = g_farmlandManager:getFarmlandById(self.farmlandId)
	if v20_ == nil then
		Logging.warning("TramlineMapDensityMapTask:prepare() - Farmland with id %d not found!", self.farmlandId)
		self:setFinished()
	else
		local v21_ = FieldCourseSettings.new()
		v21_.implementWidth = 15
		v21_.numHeadlands = 1
		local v22_, v23_ = v20_:getIndicatorPosition()
		self.courseField = FieldCourseField.generateAtPosition(v22_, v23_, v21_, function(p24_, p25_)
			-- upvalues: (copy) self
			self.courseField = nil
			if p25_ then
				self.polygon = DensityMapPolygon.new()
				local v26_ = p24_.fieldRootBoundary.boundaryLine
				local v27_ = math.huge
				local v28_ = math.huge
				local v29_ = -math.huge
				local v30_ = -math.huge
				for v31_ = 1, #v26_ - 1 do
					local v32_ = v26_[v31_][1]
					local v33_ = v26_[v31_][2]
					self.polygon:addPolygonPoint(v32_, v33_)
					v27_ = math.min(v27_, v32_)
					v28_ = math.min(v28_, v33_)
					v29_ = math.max(v29_, v32_)
					v30_ = math.max(v30_, v33_)
				end
				local v34_ = self
				self.minX = v27_
				v34_.maxX = v29_
				local v35_ = self
				self.minY = v28_
				v35_.maxY = v30_
				self.currentMinY = self.minY
				local v36_ = self
				local v37_ = self.minY + self.maxRegionPerFrame
				v36_.currentMaxY = math.min(v37_, v30_)
				self.polygon:applyToModifier(self.multiModifier)
			else
				self:setFinished()
				Logging.devWarning("TramlineMapDensityMapTask: Failed to generate FieldCourseField for farmland %d", self.farmlandId)
			end
		end)
		if self.courseField.setIgnoreCollisions ~= nil then
			self.courseField:setIgnoreCollisions(true)
		end
		if self.courseField.setIgnoreIslands ~= nil then
			self.courseField:setIgnoreIslands(true)
		end
	end
end

function TramlineMapDensityMapTask:enqueue(immediate)
	g_precisionFarming.densityMapUpdater:addUpdateTask(self, immediate)
end

function TramlineMapDensityMapTask:start()
	if self.multiModifier == nil then
		Logging.error("TramlineMapDensityMapTask:start() - MultiModifier not set!")
		return false
	end
	if self.state == DensityMapUpdateTaskState.RUNNING or self.state == DensityMapUpdateTaskState.FINISHED then
		return false
	end
	self.state = DensityMapUpdateTaskState.RUNNING
	self:prepare()
	if self.currentMinY == nil then
		self.currentMinY = self.minY
		self.currentMaxY = self.minY + self.maxRegionPerFrame
	end
	return true
end

-- Local values: multiModifier, startTime
function TramlineMapDensityMapTask:update(dt)
	if self.state == DensityMapUpdateTaskState.RUNNING then
		self.frames = self.frames + 1
		if self.courseField ~= nil then
			self.courseField:update(dt, self.frameBudget)
			return
		end
		local v43_ = self.multiModifier
		local v44_ = getTimeSec()
		while getTimeSec() - v44_ < self.frameBudget do
			v43_:setPolygonClipRegion(self.currentMinY, self.currentMaxY)
			v43_:execute()
			self.currentMinY = self.currentMaxY
			local v45_ = self.currentMinY + self.maxRegionPerFrame
			local v46_ = self.maxY
			self.currentMaxY = math.min(v45_, v46_)
			if self.currentMinY >= self.maxY then
				break
			end
		end
		self.totalTime = self.totalTime + (getTimeSec() - v44_)
		if self.currentMinY < self.maxY then
			return
		end
		if g_precisionFarming ~= nil and g_precisionFarming.tramlineMap ~= nil then
			g_precisionFarming:updatePrecisionFarmingOverlays()
			g_precisionFarming.tramlineMap:setMinimapRequiresUpdate(true)
			g_precisionFarming.tramlineMap:onDensityMapUpdateFinished(self.farmlandId)
		end
		self:setFinished()
	end
end

function TramlineMapDensityMapTask:setFinished()
	Logging.devInfo("TramlineMapDensityMapTask: Finished after %d frames / %.1f ms (Farmland %d)", self.frames, self.totalTime * 1000, self.farmlandId)
	self.state = DensityMapUpdateTaskState.FINISHED
end
