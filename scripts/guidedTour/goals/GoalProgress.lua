-- Local values: GoalProgress_mt
GoalProgress = {}
GoalProgress.NAME = "progress"
local GoalProgress_mt = Class(GoalProgress)

function GoalProgress.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#progressIndex", "Id of the progress", nil, true)
	schema:register(XMLValueType.FLOAT, basePath .. "#minProgress", "Min progress (0-1)", 0.2, false)
end

-- Upvalues: GoalProgress_mt
-- Local values: self
function GoalProgress.new(progressIndex, minProgress, customMt)
	-- upvalues: (copy) GoalProgress_mt
	local v7_ = customMt or GoalProgress_mt
	local v8_ = setmetatable({}, v7_)
	v8_.progressIndex = progressIndex
	v8_.minProgress = minProgress
	return v8_
end

function GoalProgress:activate(tour, step)
	self.progress = step:getProgressByIndex(self.progressIndex)
	if self.progress == nil then
		Logging.warning("GoalProgress.activate: Progress \'%d\' not defined!", self.progressIndex)
	end
end

function GoalProgress:deactivate()
	self.progress = nil
end

-- Local values: progress
function GoalProgress:isAchieved()
	if self.progress == nil then
		return true
	end
	local v13_ = self.progress:getProgress()
	return v13_ == nil and true or self.minProgress <= v13_
end

-- Local values: progressIndex, minProgress
function GoalProgress.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v16_ = xmlFile:getValue(key .. "#progressIndex")
	if v16_ == nil then
		Logging.xmlWarning(xmlFile, "Missing \'progressIndex\' for \'%s\'", key)
		return nil
	else
		local v17_ = xmlFile:getValue(key .. "#minProgress", 0.2)
		return GoalProgress.new(v16_, v17_)
	end
end
g_guidedTourManager:registerGoalClass(GoalProgress.NAME, GoalProgress)
