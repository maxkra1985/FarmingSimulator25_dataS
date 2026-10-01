ActionFieldUpdate = {}
ActionFieldUpdate.NAME = "fieldUpdate"
local ActionFieldUpdate_mt = Class(ActionFieldUpdate)
function ActionFieldUpdate.registerXMLPaths(schema, basePath)
	FieldUpdateTask.registerXMLPaths(schema, basePath)
end
function ActionFieldUpdate.new(updateTask, customMt)
	local self = setmetatable({}, customMt or ActionFieldUpdate_mt)
	self.updateTask = updateTask
	self.loadedFromSavegame = false
	return self
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
function ActionFieldUpdate.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local updateTask = FieldUpdateTask.new()
	if updateTask:loadFromXMLFile(xmlFile, key) then
		return ActionFieldUpdate.new(updateTask)
	else
		return nil
	end
end
g_guidedTourManager:registerActionClass(ActionFieldUpdate.NAME, ActionFieldUpdate)
