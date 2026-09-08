-- Local values: CoverMapDensityMapTask_mt
CoverMapDensityMapTask = {}
local CoverMapDensityMapTask_mt = Class(CoverMapDensityMapTask, DensityMapUpdateTask)

function CoverMapDensityMapTask.registerXMLPaths(schema, basePath)
	DensityMapUpdateTask.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#farmId", "Id of the farm")
	schema:register(XMLValueType.INT, basePath .. "#farmlandId", "Id of the farmland")
end

-- Upvalues: CoverMapDensityMapTask_mt
-- Local values: self
function CoverMapDensityMapTask.new(customMt)
	-- upvalues: (copy) CoverMapDensityMapTask_mt
	local v5_ = CoverMapDensityMapTask:superClass().new(customMt or CoverMapDensityMapTask_mt)
	v5_.farmId = nil
	v5_.farmlandId = nil
	v5_.multiModifier = nil
	v5_.farmlandIds = nil
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
	v5_.sampleStateNumMatchingPixels = {}
	return v5_
end

function CoverMapDensityMapTask:saveToXMLFile(xmlFile, key)
	xmlFile:setString(key .. "#status", DensityMapUpdateTaskState.getName(self.state))
	if self.state == DensityMapUpdateTaskState.RUNNING then
		xmlFile:setFloat(key .. ".area#currentMinZ", self.currentMinZ)
		xmlFile:setFloat(key .. ".area#currentMaxZ", self.currentMaxZ)
	end
	if self.farmId ~= nil then
		xmlFile:setInt(key .. "#farmId", self.farmId)
	end
	if self.farmlandId ~= nil then
		xmlFile:setInt(key .. "#farmlandId", self.farmlandId)
	end
end

-- Local values: farmId, farmlandId
function CoverMapDensityMapTask:loadFromXMLFile(xmlFile, key)
	local v16_ = xmlFile:getInt(key .. "#farmId")
	if v16_ ~= nil then
		self.farmId = v16_
	end
	local v17_ = xmlFile:getInt(key .. "#farmlandId")
	if v17_ ~= nil then
		self.farmlandId = v17_
	end
	self.state = DensityMapUpdateTaskState.getByName(xmlFile:getString(key .. "#status")) or DensityMapUpdateTaskState.CREATED
	if self.state == DensityMapUpdateTaskState.RUNNING then
		self.currentMinZ = xmlFile:getFloat(key .. ".area#currentMinZ")
		self.currentMaxZ = xmlFile:getFloat(key .. ".area#currentMaxZ")
	end
	if g_precisionFarming ~= nil and g_precisionFarming.coverMap ~= nil then
		local v18_, v19_ = g_precisionFarming.coverMap:getCoverMultiModifier(v16_, v17_)
		self.multiModifier = v18_
		self.farmlandIds = v19_
	end
	if self.state == DensityMapUpdateTaskState.RUNNING then
		self:start()
	end
	return true
end

function CoverMapDensityMapTask:setData(farmId, farmlandId)
	self.farmId = farmId
	self.farmlandId = farmlandId
	local v23_, v24_ = g_precisionFarming.coverMap:getCoverMultiModifier(farmId, farmlandId)
	self.multiModifier = v23_
	self.farmlandIds = v24_
end

function CoverMapDensityMapTask:prepare() end

function CoverMapDensityMapTask:enqueue(immediate)
	g_precisionFarming.densityMapUpdater:addUpdateTask(self, immediate)
end

-- Local values: farmland, minX, minZ, maxX, maxZ
function CoverMapDensityMapTask:start()
	if self.multiModifier == nil then
		Logging.error("CoverMapDensityMapTask:start() - MultiModifier not set!")
		return false
	end
	if self.state == DensityMapUpdateTaskState.RUNNING or self.state == DensityMapUpdateTaskState.FINISHED then
		return false
	end
	self.state = DensityMapUpdateTaskState.RUNNING
	self:prepare()
	if self.farmlandId ~= nil then
		local v28_ = g_farmlandManager:getFarmlandById(self.farmlandId)
		if v28_ ~= nil and v28_.getBoundingBox ~= nil then
			local v29_, v30_, v31_, v32_ = v28_:getBoundingBox()
			if v29_ ~= nil then
				self.minX = v29_
				self.maxX = v31_
				self.minZ = v30_
				self.maxZ = v32_
			end
		end
	end
	if self.currentMinZ == nil then
		self.currentMinZ = self.minZ
		local v33_ = self.minZ + self.maxRegionPerFrame
		local v34_ = self.maxZ
		self.currentMaxZ = math.min(v33_, v34_)
	end
	return true
end

-- Local values: multiModifier, startTime, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, sliceNumMatchingPixels, label, value
function CoverMapDensityMapTask:update(dt)
	if self.state == DensityMapUpdateTaskState.RUNNING then
		local v36_ = self.multiModifier
		self.frames = self.frames + 1
		local v37_ = getTimeSec()
		while getTimeSec() - v37_ < self.frameBudget do
			v36_:updateParallelogramWorldCoords(self.minX, self.currentMinZ, self.maxX, self.currentMinZ, self.minX, self.currentMaxZ, DensityCoordType.POINT_POINT_POINT)
			local v38_ = {}
			v36_:execute(nil, v38_)
			for v39_, v40_ in pairs(v38_) do
				self.sampleStateNumMatchingPixels[v39_] = (self.sampleStateNumMatchingPixels[v39_] or 0) + v40_
			end
			self.currentMinZ = self.currentMaxZ
			local v41_ = self.currentMinZ + self.maxRegionPerFrame
			local v42_ = self.maxZ
			self.currentMaxZ = math.min(v41_, v42_)
			if self.currentMinZ >= self.maxZ then
				break
			end
		end
		self.totalTime = self.totalTime + (getTimeSec() - v37_)
		if self.currentMinZ < self.maxZ then
			return
		end
		if g_precisionFarming ~= nil and g_precisionFarming.coverMap ~= nil then
			g_precisionFarming:updatePrecisionFarmingOverlays()
			g_precisionFarming.coverMap:setMinimapRequiresUpdate(true)
		end
		self:setFinished()
	end
end

-- Local values: sampledPercentageByFarmlandId, _, farmlandId, fieldLabel, sampledLabel, areaField, areaSampled
function CoverMapDensityMapTask:getSampledPercentageByFarmlandId()
	local v44_ = {}
	if self.farmlandIds == nil then
		return v44_
	end
	for _, v45_ in ipairs(self.farmlandIds) do
		local v46_ = "field_" .. tostring(v45_)
		local v47_ = "sampled_" .. tostring(v45_)
		local v48_ = self.sampleStateNumMatchingPixels[v46_] or 0
		local v49_ = self.sampleStateNumMatchingPixels[v47_] or 0
		if v48_ > 0 then
			v44_[v45_] = v49_ / v48_
		else
			v44_[v45_] = 0
		end
	end
	return v44_
end

function CoverMapDensityMapTask:setFinished()
	Logging.devInfo("CoverMapDensityMapTask: Finished after %d frames / %.1f ms", self.frames, self.totalTime * 1000)
	self.state = DensityMapUpdateTaskState.FINISHED
	if g_precisionFarming ~= nil and g_precisionFarming.coverMap ~= nil then
		g_precisionFarming.coverMap:onCoverUpdateFinished(self.farmId, self.farmlandId, self:getSampledPercentageByFarmlandId())
	end
end
