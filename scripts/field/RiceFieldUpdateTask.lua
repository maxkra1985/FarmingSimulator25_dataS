-- Local values: RiceFieldUpdateTask_mt
RiceFieldUpdateTask = {}
local RiceFieldUpdateTask_mt = Class(RiceFieldUpdateTask, DensityMapUpdateTask)

function RiceFieldUpdateTask.registerXMLPaths(schema, basePath)
	DensityMapUpdateTask.registerXMLPaths(schema, basePath)
end

-- Upvalues: RiceFieldUpdateTask_mt
-- Local values: self
function RiceFieldUpdateTask.new(customMt)
	-- upvalues: (copy) RiceFieldUpdateTask_mt
	local v5_ = RiceFieldUpdateTask:superClass().new(customMt or RiceFieldUpdateTask_mt)
	v5_.multiModifier = DensityMapMultiModifier.new()
	return v5_
end

function RiceFieldUpdateTask:saveToXMLFile(xmlFile, key)
	RiceFieldUpdateTask:superClass().saveToXMLFile(self, xmlFile, key)
end

function RiceFieldUpdateTask:loadFromXMLFile(xmlFile, key)
	RiceFieldUpdateTask:superClass().loadFromXMLFile(self, xmlFile, key)
	if self.state == DensityMapUpdateTaskState.RUNNING then
		self:start()
	end
	return true
end

-- Local values: _, desc, modifier, fruitReqWaterFilter, growthState, hasTooLittleWater, hasTooMuchWater, replacementFoliageState, percentageToReplace, filterThreshold
function RiceFieldUpdateTask:performPerlinNoiseDestruction(fruitTypes, waterFillLevelPerSqm, perlinFilter)
	for _, v16_ in ipairs(fruitTypes) do
		if v16_.minWaterLitersPerSqm == nil and v16_.maxWaterLitersPerSqm == nil then
			return
		end
		local v17_ = v16_:getModifier()
		local v18_ = v16_:getFilter()
		for v19_ = v16_.numGrowthStates, 1, -1 do
			local v20_
			if v16_.minWaterLitersPerSqm[v19_] == nil then
				v20_ = false
			else
				v20_ = waterFillLevelPerSqm < v16_.minWaterLitersPerSqm[v19_]
			end
			local v21_
			if v16_.maxWaterLitersPerSqm[v19_] == nil then
				v21_ = false
			else
				v21_ = v16_.maxWaterLitersPerSqm[v19_] < waterFillLevelPerSqm
			end
			if v20_ or v21_ then
				local v22_ = v16_.penaltyStateName[v19_] and (v16_:getGrowthStateByName(v16_.penaltyStateName[v19_]) or 0) or 0
				local v23_ = 10000 * (1 - (v16_.penaltyPercentage and (v16_.penaltyPercentage[v19_] or 0.1) or 0.1))
				perlinFilter:setValueCompareParams(DensityValueCompareType.GREATER, v23_)
				v18_:setValueCompareParams(DensityValueCompareType.EQUAL, v19_ + 1)
				self.multiModifier:addExecuteSet(v22_, v17_, perlinFilter, v18_)
			end
		end
	end
end

function RiceFieldUpdateTask:enqueue()
	g_fieldManager:addFieldUpdateTask(self)
end

-- Local values: multiModifier
function RiceFieldUpdateTask:start(_, immediate)
	if self.area == nil then
		self.state = DensityMapUpdateTaskState.FINISHED
		Logging.warning("Missing area for RiceFieldUpdateTask")
	else
		self.state = DensityMapUpdateTaskState.RUNNING
		local v27_ = self.multiModifier
		self.area:applyToModifier(v27_)
		local v28_, v29_ = v27_:getPolygonMinMaxZ()
		self.minY = v28_
		self.maxY = v29_
		if self.minY ~= nil then
			if self.currentMinY == nil then
				self.currentMinY = self.minY
				self.currentMaxY = self.minY + self.maxRegionPerFrame
			end
			if immediate then
				self.currentMinY = self.minY
				self.currentMaxY = self.maxY
			end
		end
	end
end

-- Local values: multiModifier
function RiceFieldUpdateTask:update(dt)
	if self.state == DensityMapUpdateTaskState.RUNNING then
		local v31_ = self.multiModifier
		if self.currentMinY ~= nil then
			v31_:setPolygonClipRegion(self.currentMinY, self.currentMaxY)
		end
		v31_:execute()
		if self.minY == nil then
			self.state = DensityMapUpdateTaskState.FINISHED
		else
			self.currentMinY = self.currentMaxY
			local v32_ = self.currentMinY + self.maxRegionPerFrame
			local v33_ = self.maxY
			self.currentMaxY = math.min(v32_, v33_)
			if self.currentMinY == self.maxY then
				self.state = DensityMapUpdateTaskState.FINISHED
				return
			end
		end
	end
end
