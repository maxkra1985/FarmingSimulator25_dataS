WorkAreaTypeManager = {}
WorkAreaType = nil
local WorkAreaTypeManager_mt = Class(WorkAreaTypeManager, AbstractManager)
function WorkAreaTypeManager.new(customMt)
	local self = AbstractManager.new(customMt or WorkAreaTypeManager_mt)
	return self
end
function WorkAreaTypeManager:initDataStructures()
	self.workAreaTypes = {}
	self.workAreaTypeNameToInt = {}
	self.workAreaTypeNameToDesc = {}
	WorkAreaType = self.workAreaTypeNameToInt
end
function WorkAreaTypeManager:addWorkAreaType(name, attractWildlife, isAIArea, isSteeringAssistArea)
	if name == nil then
		Logging.error("WorkArea name missing!")
	elseif self.workAreaTypeNameToInt[name] ~= nil then
		Logging.error("WorkArea name '%s' is already in use!", name)
	else
		name = string.upper(name)
		local entry = {}
		entry.name = name
		entry.index = #self.workAreaTypes + 1
		entry.attractWildlife = Utils.getNoNil(attractWildlife, false)
		entry.isAIArea = Utils.getNoNil(isAIArea, false)
		entry.isSteeringAssistArea = Utils.getNoNil(isSteeringAssistArea, false)
		self.workAreaTypeNameToInt[name] = entry.index
		self.workAreaTypeNameToDesc[name] = entry
		table.insert(self.workAreaTypes, entry)
		print("  Register workAreaType '" .. name .. "'")
	end
end
function WorkAreaTypeManager:getWorkAreaTypeNameByIndex(index)
	local workAreaType = self.workAreaTypes[index]
	if workAreaType then
		return workAreaType.name
	else
		return nil
	end
end
function WorkAreaTypeManager:getWorkAreaTypeIndexByName(name)
	if name ~= nil then
		return self.workAreaTypeNameToInt[string.upper(name)]
	else
		return nil
	end
end
function WorkAreaTypeManager:getConfigurationDescByName(name)
	if name ~= nil then
		return self.workAreaTypeNameToDesc[string.upper(name)]
	else
		return nil
	end
end
function WorkAreaTypeManager:getWorkAreaTypeByIndex(index)
	return self.workAreaTypes[index]
end
function WorkAreaTypeManager:getWorkAreaTypeIsAIArea(index)
	if self.workAreaTypes[index] ~= nil then
		return self.workAreaTypes[index].isAIArea
	else
		return false
	end
end
function WorkAreaTypeManager:getWorkAreaTypeIsSteeringAssistArea(index)
	if self.workAreaTypes[index] ~= nil then
		return self.workAreaTypes[index].isSteeringAssistArea
	else
		return false
	end
end
g_workAreaTypeManager = WorkAreaTypeManager.new()
