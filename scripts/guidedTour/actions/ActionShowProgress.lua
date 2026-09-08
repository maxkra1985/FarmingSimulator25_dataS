-- Local values: ActionShowProgress_mt
ActionShowProgress = {}
ActionShowProgress.NAME = "showProgress"
local ActionShowProgress_mt = Class(ActionShowProgress)

function ActionShowProgress.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. "#isVisible", "If the progress bar is visible", nil, false)
end

-- Upvalues: ActionShowProgress_mt
-- Local values: self
function ActionShowProgress.new(isVisible, customMt)
	-- upvalues: (copy) ActionShowProgress_mt
	local v6_ = customMt or ActionShowProgress_mt
	local v7_ = setmetatable({}, v6_)
	v7_.isVisible = isVisible
	return v7_
end

function ActionShowProgress:run(tour, step)
	tour:setShowProgress(self.isVisible)
	return true
end

-- Local values: isVisible
function ActionShowProgress.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v12_ = xmlFile:getValue(key .. "#isVisible")
	if v12_ == nil then
		return nil
	else
		return ActionShowProgress.new(v12_)
	end
end
g_guidedTourManager:registerActionClass(ActionShowProgress.NAME, ActionShowProgress)
