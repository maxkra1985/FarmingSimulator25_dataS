ToolType = nil
ToolTypeManager = {}
local ToolTypeManager_mt = Class(ToolTypeManager, AbstractManager)
function ToolTypeManager.new(customMt)
	local self = AbstractManager.new(customMt or ToolTypeManager_mt)
	return self
end
function ToolTypeManager:initDataStructures()
	self.indexToName = {}
	self.nameToInt = {}
	ToolType = self.nameToInt
end
function ToolTypeManager:loadMapData()
	ToolTypeManager:superClass().loadMapData(self)
	self:addToolType("undefined")
	self:addToolType("dischargeable")
	self:addToolType("pallet")
	self:addToolType("trigger")
	self:addToolType("bale")
	return true
end
function ToolTypeManager:addToolType(name)
	name = string.upper(name)
	if not ClassUtil.getIsValidIndexName(name) then
		printWarning("Warning: '" .. tostring(name) .. "' is not a valid name for a toolType. Ignoring toolType!")
		return nil
	else
		if ToolType[name] == nil then
			table.insert(self.indexToName, name)
			self.nameToInt[name] = #self.indexToName
		end
		return ToolType[name]
	end
end
function ToolTypeManager:getToolTypeNameByIndex(index)
	if self.indexToName[index] ~= nil then
		return self.indexToName[index]
	else
		return "UNDEFINED"
	end
end
function ToolTypeManager:getToolTypeIndexByName(name)
	name = string.upper(name)
	if self.nameToInt[name] ~= nil then
		return self.nameToInt[name]
	else
		return ToolType.UNDEFINED
	end
end
function ToolTypeManager:getNumberOfToolTypes()
	return #self.indexToName
end
g_toolTypeManager = ToolTypeManager.new()
