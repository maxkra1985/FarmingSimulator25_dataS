-- Local values: FieldGetInfoTask_mt
FieldGetInfoTask = {}
local FieldGetInfoTask_mt = Class(FieldGetInfoTask, DensityMapUpdateTask)

-- Upvalues: FieldGetInfoTask_mt
-- Local values: self
function FieldGetInfoTask.new(customMt)
	-- upvalues: (copy) FieldGetInfoTask_mt
	local v3_ = FieldGetInfoTask:superClass().new(customMt or FieldGetInfoTask_mt)
	v3_.fieldId = nil
	return v3_
end

function FieldGetInfoTask:setCallback(callbackFunc, callbackTarget, callbackArgs)
	self.callbackFunc = callbackFunc
	self.callbackTarget = callbackTarget
	self.callbackArgs = callbackArgs
end

function FieldGetInfoTask:setField(field)
	self.fieldId = field:getId()
end

-- Local values: field
function FieldGetInfoTask:getField()
	return g_fieldManager:getFieldById(self.fieldId)
end

-- Local values: terrainRootNode, _, desc, fruitModifier, foliageState, fruitFilter
function FieldGetInfoTask:setFruitTypes(fruits)
	local v13_ = g_terrainNode
	local v14_ = fruits or g_fruitTypeManager:getFruitTypes()
	self.multiModifier = DensityMapMultiModifier.new()
	for _, v15_ in pairs(v14_) do
		if v15_.terrainDataPlaneId ~= nil then
			local v16_ = DensityMapModifier.new(v15_.terrainDataPlaneId, v15_.startStateChannel, v15_.numStateChannels, v13_)
			for v17_ = 1, v15_.numFoliageStates do
				local v18_ = DensityMapFilter.new(v16_)
				v18_:setValueCompareParams(DensityValueCompareType.EQUAL, v17_)
				self.multiModifier:addExecuteGet(v15_.name .. "|" .. v17_, v16_, v18_)
			end
		end
	end
end

function FieldGetInfoTask:enqueue()
	g_fieldManager:addFieldUpdateTask(self)
end

-- Local values: field
function FieldGetInfoTask:start(immediate)
	if self.area == nil and self.fieldId ~= nil then
		local v22_ = g_fieldManager:getFieldById(self.fieldId)
		if v22_ ~= nil then
			self.area = v22_:getDensityMapPolygon()
		end
	end
	if self.area == nil then
		self.state = DensityMapUpdateTaskState.FINISHED
		Logging.warning("Missing area for FieldGetInfoTask")
	else
		self.state = DensityMapUpdateTaskState.RUNNING
		self.area:applyToModifier(self.multiModifier)
		local v23_, v24_ = self.multiModifier:getPolygonMinMaxZ()
		self.minY = v23_
		self.maxY = v24_
		self.numPixelsPerGrowthStage = {}
		self.totalNumTouchedPixels = 0
		self.multiModifier:resetStats()
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

-- Local values: _, numTouchedPixels
function FieldGetInfoTask:update(dt)
	if self.state == DensityMapUpdateTaskState.RUNNING then
		if self.currentMinY ~= nil then
			self.multiModifier:setPolygonClipRegion(self.currentMinY, self.currentMaxY)
		end
		local _, _, _, v26_ = self.multiModifier:execute(nil, self.numPixelsPerGrowthStage)
		self.totalNumTouchedPixels = self.totalNumTouchedPixels + v26_
		if self.minY == nil then
			self:onFinish()
		else
			self.currentMinY = self.currentMaxY
			local v27_ = self.currentMinY + self.maxRegionPerFrame
			local v28_ = self.maxY
			self.currentMaxY = math.min(v27_, v28_)
			if self.currentMinY == self.maxY then
				self:onFinish()
				return
			end
		end
	end
end

function FieldGetInfoTask:onFinish()
	self.state = DensityMapUpdateTaskState.FINISHED
	if self.callbackFunc ~= nil then
		if self.callbackTarget ~= nil then
			self.callbackFunc(self.callbackTarget, self.numPixelsPerGrowthStage, self.totalNumTouchedPixels, self.callbackArgs)
			return
		end
		self.callbackFunc(self.numPixelsPerGrowthStage, self.totalNumTouchedPixels, self.callbackArgs)
	end
end

function FieldGetInfoTask:getIsFinished()
	return self.state == DensityMapUpdateTaskState.FINISHED
end
