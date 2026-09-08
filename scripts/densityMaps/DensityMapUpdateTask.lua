-- Local values: DensityMapUpdateTask_mt
DensityMapUpdateTask = {}
local DensityMapUpdateTask_mt = Class(DensityMapUpdateTask)

function DensityMapUpdateTask.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#customName", "Custom name of the task", nil, false)
	schema:register(XMLValueType.STRING, basePath .. "#status", "Status of the task", nil, false)
	schema:register(XMLValueType.FLOAT, basePath .. ".area#currentMinY", "Current polygon minY clip region", nil, false)
	schema:register(XMLValueType.FLOAT, basePath .. ".area#currentMaxY", "Current polygon minY clip region", nil, false)
	DensityMapCircle.registerXMLPaths(schema, basePath .. ".area")
	DensityMapParallelogram.registerXMLPaths(schema, basePath .. ".area")
	DensityMapPolygon.registerXMLPaths(schema, basePath .. ".area")
end

-- Upvalues: DensityMapUpdateTask_mt
-- Local values: self
function DensityMapUpdateTask.new(customMt)
	-- upvalues: (copy) DensityMapUpdateTask_mt
	local v5_ = customMt or DensityMapUpdateTask_mt
	local v6_ = setmetatable({}, v5_)
	v6_.customName = nil
	v6_.area = nil
	v6_.state = DensityMapUpdateTaskState.CREATED
	v6_.minY = nil
	v6_.maxY = nil
	v6_.currentMinY = nil
	v6_.currentMaxY = nil
	v6_.needsSaving = nil
	v6_.maxRegionPerFrame = 30
	return v6_
end

function DensityMapUpdateTask:saveToXMLFile(xmlFile, key)
	if self.customName ~= nil then
		xmlFile:setValue(key .. "#customName", self.customName)
	end
	xmlFile:setValue(key .. "#status", DensityMapUpdateTaskState.getName(self.state))
	if self.state == DensityMapUpdateTaskState.RUNNING then
		xmlFile:setValue(key .. ".area#currentMinY", self.currentMinY)
		xmlFile:setValue(key .. ".area#currentMaxY", self.currentMaxY)
	end
	if self.area ~= nil then
		self.area:saveToXMLFile(xmlFile, key .. ".area")
	end
end

-- Local values: customName, area
function DensityMapUpdateTask:loadFromXMLFile(xmlFile, key)
	local v13_ = xmlFile:getValue(key .. "#customName")
	if v13_ ~= nil then
		self.customName = v13_
	end
	self.state = DensityMapUpdateTaskState.getByName(xmlFile:getValue(key .. "#status")) or DensityMapUpdateTaskState.CREATED
	if self.state == DensityMapUpdateTaskState.RUNNING then
		self.currentMinY = xmlFile:getValue(key .. ".area#currentMinY")
		self.currentMaxY = xmlFile:getValue(key .. ".area#currentMaxY")
	end
	if self.area == nil then
		local v14_ = DensityMapParallelogram.createFromXMLFile(xmlFile, key .. ".area")
		if v14_ == nil then
			v14_ = DensityMapPolygon.createFromXMLFile(xmlFile, key .. ".area")
			if v14_ == nil then
				v14_ = DensityMapCircle.createFromXMLFile(xmlFile, key .. ".area")
			end
		end
		self.area = v14_
	end
	return true
end

function DensityMapUpdateTask:setArea(area)
	self.area = area
end

function DensityMapUpdateTask:getName()
	return self.customName or tostring(self)
end

function DensityMapUpdateTask:setName(name)
	self.customName = name
end

-- Local values: taskName
function DensityMapUpdateTask:cancel()
	if self.state == DensityMapUpdateTaskState.RUNNING then
		self.state = DensityMapUpdateTaskState.FINISHED
		local v21_ = self:getName()
		Logging.devInfo("Canceled DensityMapUpdateTask for %s", v21_)
	end
end

function DensityMapUpdateTask:getIsFinished()
	return self.state == DensityMapUpdateTaskState.FINISHED
end

-- Local values: taskName
function DensityMapUpdateTask:setFinished()
	local v24_ = self:getName()
	Logging.devInfo("Finished DensityMapUpdateTask for %s", v24_)
	self.state = DensityMapUpdateTaskState.FINISHED
end

function DensityMapUpdateTask:setNeedsSaving(needsSaving)
	self.needsSaving = needsSaving
end
