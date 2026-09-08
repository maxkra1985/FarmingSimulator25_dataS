-- Local values: ToolTypeManager_mt
ToolType = nil
ToolTypeManager = {}
local ToolTypeManager_mt = Class(ToolTypeManager, AbstractManager)

-- Upvalues: ToolTypeManager_mt
-- Local values: self
function ToolTypeManager.new(customMt)
	-- upvalues: (copy) ToolTypeManager_mt
	return AbstractManager.new(customMt or ToolTypeManager_mt)
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
	local v7_ = string.upper(name)
	if ClassUtil.getIsValidIndexName(v7_) then
		if ToolType[v7_] == nil then
			local v8_ = self.indexToName
			table.insert(v8_, v7_)
			self.nameToInt[v7_] = #self.indexToName
		end
		return ToolType[v7_]
	else
		printWarning("Warning: \'" .. tostring(v7_) .. "\' is not a valid name for a toolType. Ignoring toolType!")
		return nil
	end
end

function ToolTypeManager:getToolTypeNameByIndex(index)
	return self.indexToName[index] == nil and "UNDEFINED" or self.indexToName[index]
end

function ToolTypeManager:getToolTypeIndexByName(name)
	local v13_ = string.upper(name)
	if self.nameToInt[v13_] == nil then
		return ToolType.UNDEFINED
	else
		return self.nameToInt[v13_]
	end
end

function ToolTypeManager:getNumberOfToolTypes()
	return #self.indexToName
end
g_toolTypeManager = ToolTypeManager.new()
