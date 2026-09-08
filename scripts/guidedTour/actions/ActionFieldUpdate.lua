-- Local values: ActionFieldUpdate_mt
ActionFieldUpdate = {}
ActionFieldUpdate.NAME = "fieldUpdate"
local ActionFieldUpdate_mt = Class(ActionFieldUpdate)

function ActionFieldUpdate.registerXMLPaths(schema, basePath)
	FieldUpdateTask.registerXMLPaths(schema, basePath)
end

-- Upvalues: ActionFieldUpdate_mt
-- Local values: self
function ActionFieldUpdate.new(updateTask, customMt)
	-- upvalues: (copy) ActionFieldUpdate_mt
	local v6_ = customMt or ActionFieldUpdate_mt
	local v7_ = setmetatable({}, v6_)
	v7_.updateTask = updateTask
	v7_.loadedFromSavegame = false
	return v7_
end

function ActionFieldUpdate:loadFromXMLFile(xmlFile, key)
	self.loadedFromSavegame = true
	return true
end

function ActionFieldUpdate:run(tour, step)
	if not self.loadedFromSavegame then
		g_fieldManager:addFieldUpdateTask(self.updateTask)
	end
	return true
end

-- Local values: updateTask
function ActionFieldUpdate.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v12_ = FieldUpdateTask.new()
	if v12_:loadFromXMLFile(xmlFile, key) then
		return ActionFieldUpdate.new(v12_)
	else
		return nil
	end
end
g_guidedTourManager:registerActionClass(ActionFieldUpdate.NAME, ActionFieldUpdate)
