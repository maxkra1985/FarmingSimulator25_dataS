-- Local values: WorkAreaTypeManager_mt
WorkAreaTypeManager = {}
WorkAreaType = nil
local WorkAreaTypeManager_mt = Class(WorkAreaTypeManager, AbstractManager)

-- Upvalues: WorkAreaTypeManager_mt
-- Local values: self
function WorkAreaTypeManager.new(customMt)
	-- upvalues: (copy) WorkAreaTypeManager_mt
	return AbstractManager.new(customMt or WorkAreaTypeManager_mt)
end

function WorkAreaTypeManager:initDataStructures()
	self.workAreaTypes = {}
	self.workAreaTypeNameToInt = {}
	self.workAreaTypeNameToDesc = {}
	WorkAreaType = self.workAreaTypeNameToInt
end

-- Local values: entry
function WorkAreaTypeManager:addWorkAreaType(name, attractWildlife, isAIArea, isSteeringAssistArea)
	if name == nil then
		Logging.error("WorkArea name missing!")
		return
	elseif self.workAreaTypeNameToInt[name] == nil then
		local v9_ = string.upper(name)
		local v10_ = {
			["name"] = v9_,
			["index"] = #self.workAreaTypes + 1,
			["attractWildlife"] = Utils.getNoNil(attractWildlife, false),
			["isAIArea"] = Utils.getNoNil(isAIArea, false),
			["isSteeringAssistArea"] = Utils.getNoNil(isSteeringAssistArea, false)
		}
		self.workAreaTypeNameToInt[v9_] = v10_.index
		self.workAreaTypeNameToDesc[v9_] = v10_
		local v11_ = self.workAreaTypes
		table.insert(v11_, v10_)
		print("  Register workAreaType \'" .. v9_ .. "\'")
	else
		Logging.error("WorkArea name \'%s\' is already in use!", name)
	end
end

-- Local values: workAreaType
function WorkAreaTypeManager:getWorkAreaTypeNameByIndex(index)
	local v14_ = self.workAreaTypes[index]
	if v14_ then
		return v14_.name
	else
		return nil
	end
end

function WorkAreaTypeManager:getWorkAreaTypeIndexByName(name)
	if name == nil then
		return nil
	else
		return self.workAreaTypeNameToInt[string.upper(name)]
	end
end

function WorkAreaTypeManager:getConfigurationDescByName(name)
	if name == nil then
		return nil
	else
		return self.workAreaTypeNameToDesc[string.upper(name)]
	end
end

function WorkAreaTypeManager:getWorkAreaTypeByIndex(index)
	return self.workAreaTypes[index]
end

function WorkAreaTypeManager:getWorkAreaTypeIsAIArea(index)
	if self.workAreaTypes[index] == nil then
		return false
	else
		return self.workAreaTypes[index].isAIArea
	end
end

function WorkAreaTypeManager:getWorkAreaTypeIsSteeringAssistArea(index)
	if self.workAreaTypes[index] == nil then
		return false
	else
		return self.workAreaTypes[index].isSteeringAssistArea
	end
end
g_workAreaTypeManager = WorkAreaTypeManager.new()
