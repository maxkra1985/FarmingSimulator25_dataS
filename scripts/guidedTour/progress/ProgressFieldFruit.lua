-- Local values: ProgressFieldFruit_mt
ProgressFieldFruit = {}
ProgressFieldFruit.NAME = "fieldFruit"
local ProgressFieldFruit_mt = Class(ProgressFieldFruit, Progress)

function ProgressFieldFruit.registerXMLPaths(schema, basePath)
	ProgressFieldFruit:superClass().registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#fieldId", "Id of the field", nil, true)
	schema:register(XMLValueType.STRING, basePath .. "#fruitType", "Name of the fruit type", nil, true)
	schema:register(XMLValueType.STRING, basePath .. "#growthState", "Name of the growth state", nil, true)
	DensityMapCircle.registerXMLPaths(schema, basePath .. ".area")
	DensityMapParallelogram.registerXMLPaths(schema, basePath .. ".area")
	DensityMapPolygon.registerXMLPaths(schema, basePath .. ".area")
end

-- Upvalues: ProgressFieldFruit_mt
-- Local values: self
function ProgressFieldFruit.new(title, description, fieldId, area, fruitTypeName, growthStateName, customMt)
	-- upvalues: (copy) ProgressFieldFruit_mt
	local v11_ = Progress.new(title, description, customMt or ProgressFieldFruit_mt)
	v11_.fieldId = fieldId
	v11_.area = area
	v11_.fruitTypeName = fruitTypeName
	v11_.growthStateName = growthStateName
	v11_.maxRegionPerFrame = 30
	return v11_
end

-- Local values: modifier, _, numPixels, totalNumPixels
function ProgressFieldFruit:update(dt)
	ProgressFieldFruit:superClass().update(self, dt)
	local v14_ = self.densityMapModifier
	if v14_ ~= nil then
		v14_:setPolygonClipRegion(self.currentMinY, self.currentMaxY)
		local _, v15_, v16_ = v14_:executeGet(self.filter)
		if self.totalNumPixels == nil then
			self.tempTotalPixels = self.tempTotalPixels + v16_
		end
		self.tempProgressPixels = self.tempProgressPixels + v15_
		self.currentMinY = self.currentMaxY
		local v17_ = self.currentMinY + self.maxRegionPerFrame
		local v18_ = self.maxY
		self.currentMaxY = math.min(v17_, v18_)
		if self.currentMinY == self.maxY then
			self.currentMinY = self.minY
			local v19_ = self.minY + self.maxRegionPerFrame
			local v20_ = self.maxY
			self.currentMaxY = math.max(v19_, v20_)
			if self.totalNumPixels == nil then
				self.totalNumPixels = self.tempTotalPixels
			end
			self.progressPixels = self.tempProgressPixels
			self.tempProgressPixels = 0
		end
	end
end

-- Local values: field, fruitType, growthState, densityMapId, firstChannel, numChannels, modifier, area
function ProgressFieldFruit:activate(tour, step)
	local v24_ = g_fieldManager:getFieldById(self.fieldId)
	if v24_ == nil then
		Logging.warning("GoalFieldFruitProgress.activate: No field given")
		return
	else
		local v25_ = g_fruitTypeManager:getFruitTypeByName(self.fruitTypeName)
		if v25_ == nil then
			Logging.warning("GoalFieldFruitProgress.activate: Fruit type \'%s\' not defined!", self.fruitTypeName)
			return
		else
			local v26_ = v25_:getGrowthStateByName(self.growthStateName)
			if v26_ == nil then
				Logging.warning("GoalFieldFruitProgress.activate: Fruit type \'%s\' has no growth state \'%s\' defined!", self.fruitTypeName, self.growthStateName)
				return
			else
				local v27_, v28_, v29_ = v25_:getDataPlaneInfo()
				if v27_ == nil then
					Logging.warning("GoalFieldFruitProgress.activate: Fruit type \'%s\' not available on current map!", self.fruitTypeName)
					return
				else
					local v30_ = DensityMapModifier.new(v27_, v28_, v29_, g_terrainNode)
					local v31_ = self.area
					if v31_ == nil then
						v31_ = v24_:getDensityMapPolygon()
					end
					if v31_ == nil then
						Logging.warning("GoalFieldFruitProgress.activate: No area given")
					else
						ProgressFieldFruit:superClass().activate(self, tour, step)
						self.filter = DensityMapFilter.new(v30_)
						self.filter:setValueCompareParams(DensityValueCompareType.EQUAL, v26_)
						v31_:applyToModifier(v30_)
						local v32_, v33_ = v30_:getPolygonMinMaxZ()
						self.minY = v32_
						self.maxY = v33_
						self.currentMinY = self.minY
						local v34_ = self.minY + self.maxRegionPerFrame
						local v35_ = self.maxY
						self.currentMaxY = math.max(v34_, v35_)
						self.densityMapModifier = v30_
						self.totalPixels = nil
						self.tempTotalPixels = 0
						self.progressPixels = 0
						self.tempProgressPixels = 0
					end
				end
			end
		end
	end
end

function ProgressFieldFruit:deactivate()
	self.filter = nil
	self.densityMapModifier = nil
	ProgressFieldFruit:superClass().deactivate(self)
end

-- Local values: progress
function ProgressFieldFruit:getProgress()
	if self.densityMapModifier == nil then
		return nil
	elseif self.totalNumPixels == nil then
		return 0
	elseif self.totalNumPixels == 0 then
		return nil
	else
		return self.progressPixels / self.totalNumPixels
	end
end

-- Local values: fieldId, title, description, fruitTypeName, growthStateName, area
function ProgressFieldFruit.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v41_ = xmlFile:getValue(key .. "#fieldId")
	if v41_ == nil then
		Logging.xmlWarning(xmlFile, "Missing \'fieldId\' for \'%s\'", key)
		return nil
	end
	local v42_ = xmlFile:getValue(key .. "#title", nil, customEnvironment, false)
	local v43_ = xmlFile:getValue(key .. "#description", nil, customEnvironment, false)
	local v44_ = xmlFile:getValue(key .. "#fruitType")
	local v45_ = xmlFile:getValue(key .. "#growthState")
	local v46_ = DensityMapParallelogram.createFromXMLFile(xmlFile, key .. ".area")
	if v46_ == nil then
		v46_ = DensityMapCircle.createFromXMLFile(xmlFile, key .. ".area")
	end
	if v46_ == nil then
		v46_ = DensityMapPolygon.createFromXMLFile(xmlFile, key .. ".area")
	end
	return ProgressFieldFruit.new(v42_, v43_, v41_, v46_, v44_, v45_)
end
g_guidedTourManager:registerProgressClass(ProgressFieldFruit.NAME, ProgressFieldFruit)
