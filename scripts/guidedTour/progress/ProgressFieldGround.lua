-- Local values: ProgressFieldGround_mt
ProgressFieldGround = {}
ProgressFieldGround.NAME = "fieldGround"
local ProgressFieldGround_mt = Class(ProgressFieldGround, Progress)

function ProgressFieldGround.registerXMLPaths(schema, basePath)
	ProgressFieldGround:superClass().registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#fieldId", "Id of the field", nil, true)
	schema:register(XMLValueType.STRING, basePath .. "#groundType", "Name of the ground type", "CULTIVATED", false)
	DensityMapCircle.registerXMLPaths(schema, basePath .. ".area")
	DensityMapParallelogram.registerXMLPaths(schema, basePath .. ".area")
	DensityMapPolygon.registerXMLPaths(schema, basePath .. ".area")
end

-- Upvalues: ProgressFieldGround_mt
-- Local values: self
function ProgressFieldGround.new(title, description, fieldId, area, groundTypeName, customMt)
	-- upvalues: (copy) ProgressFieldGround_mt
	local v10_ = Progress.new(title, description, customMt or ProgressFieldGround_mt)
	v10_.fieldId = fieldId
	v10_.area = area
	v10_.groundTypeName = groundTypeName
	v10_.maxRegionPerFrame = 30
	return v10_
end

-- Local values: modifier, _, numPixels, totalNumPixels
function ProgressFieldGround:update(dt)
	ProgressFieldGround:superClass().update(self, dt)
	local v13_ = self.densityMapModifier
	if v13_ ~= nil then
		v13_:setPolygonClipRegion(self.currentMinY, self.currentMaxY)
		local _, v14_, v15_ = v13_:executeGet(self.filter)
		if self.totalNumPixels == nil then
			self.tempTotalPixels = self.tempTotalPixels + v15_
		end
		self.tempProgressPixels = self.tempProgressPixels + v14_
		self.currentMinY = self.currentMaxY
		local v16_ = self.currentMinY + self.maxRegionPerFrame
		local v17_ = self.maxY
		self.currentMaxY = math.min(v16_, v17_)
		if self.currentMinY == self.maxY then
			self.currentMinY = self.minY
			local v18_ = self.minY + self.maxRegionPerFrame
			local v19_ = self.maxY
			self.currentMaxY = math.max(v18_, v19_)
			if self.totalNumPixels == nil then
				self.totalNumPixels = self.tempTotalPixels
			end
			self.progressPixels = self.tempProgressPixels
			self.tempProgressPixels = 0
		end
	end
end

-- Local values: field, fieldGroundSystem, fieldGroundValue, densityMapId, firstChannel, numChannels, modifier, area
function ProgressFieldGround:activate(tour, step)
	local v23_ = g_fieldManager:getFieldById(self.fieldId)
	if v23_ == nil then
		Logging.warning("ProgressFieldGround.activate: No field given")
		return
	else
		local v24_ = g_currentMission.fieldGroundSystem
		local v25_ = FieldGroundType.getValueByName(self.groundTypeName)
		if v25_ == nil then
			Logging.warning("ProgressFieldGround.activate: Field ground type \'%s\' not defined!", self.groundTypeName)
			return
		else
			local v26_, v27_, v28_ = v24_:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			local v29_ = DensityMapModifier.new(v26_, v27_, v28_, g_terrainNode)
			local v30_ = self.area
			if v30_ == nil then
				v30_ = v23_:getDensityMapPolygon()
			end
			if v30_ == nil then
				Logging.warning("ProgressFieldGround.activate: No area given")
			else
				ProgressFieldGround:superClass().activate(self, tour, step)
				self.filter = DensityMapFilter.new(v29_)
				self.filter:setValueCompareParams(DensityValueCompareType.EQUAL, v25_)
				v30_:applyToModifier(v29_)
				local v31_, v32_ = v29_:getPolygonMinMaxZ()
				self.minY = v31_
				self.maxY = v32_
				self.currentMinY = self.minY
				local v33_ = self.minY + self.maxRegionPerFrame
				local v34_ = self.maxY
				self.currentMaxY = math.max(v33_, v34_)
				self.densityMapModifier = v29_
				self.totalPixels = nil
				self.tempTotalPixels = 0
				self.progressPixels = 0
				self.tempProgressPixels = 0
			end
		end
	end
end

function ProgressFieldGround:deactivate()
	self.filter = nil
	self.densityMapModifier = nil
	ProgressFieldGround:superClass().deactivate(self)
end

-- Local values: progress
function ProgressFieldGround:getProgress()
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

-- Local values: fieldId, title, description, groundTypeName, area
function ProgressFieldGround.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v40_ = xmlFile:getValue(key .. "#fieldId")
	if v40_ == nil then
		Logging.xmlWarning(xmlFile, "Missing \'fieldId\' for \'%s\'", key)
		return nil
	end
	local v41_ = xmlFile:getValue(key .. "#title", nil, customEnvironment, false)
	local v42_ = xmlFile:getValue(key .. "#description", nil, customEnvironment, false)
	local v43_ = xmlFile:getValue(key .. "#groundType", "CULTIVATED")
	local v44_ = DensityMapParallelogram.createFromXMLFile(xmlFile, key .. ".area")
	if v44_ == nil then
		v44_ = DensityMapCircle.createFromXMLFile(xmlFile, key .. ".area")
	end
	if v44_ == nil then
		v44_ = DensityMapPolygon.createFromXMLFile(xmlFile, key .. ".area")
	end
	return ProgressFieldGround.new(v41_, v42_, v40_, v44_, v43_)
end
g_guidedTourManager:registerProgressClass(ProgressFieldGround.NAME, ProgressFieldGround)
