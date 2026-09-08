-- Local values: Progress_mt
Progress = {}
local Progress_mt = Class(Progress)

function Progress.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.L10N_STRING, basePath .. "#title", "Title of the progress", nil, false)
	schema:register(XMLValueType.L10N_STRING, basePath .. "#description", "Desciption of the progress", nil, false)
end

-- Upvalues: Progress_mt
-- Local values: self
function Progress.new(title, description, customMt)
	-- upvalues: (copy) Progress_mt
	local v7_ = customMt or Progress_mt
	local v8_ = setmetatable({}, v7_)
	v8_.title = title
	v8_.description = description
	return v8_
end

function Progress:update(dt)
	self.progressBar.progress = self:getProgress() or 0
	g_currentMission.hud:markSideNotificationProgressBarForDrawing(self.progressBar)
end

function Progress:activate(tour, step)
	self.progressBar = g_currentMission.hud:addSideNotificationProgressBar(self.title, self.description, 0)
end

function Progress:deactivate()
	g_currentMission.hud:removeSideNotificationProgressBar(self.progressBar)
end

function Progress:getProgress()
	return nil
end
