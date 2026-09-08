-- Local values: AIParameterGroup_mt
AIParameterGroup = {}
local AIParameterGroup_mt = Class(AIParameterGroup)

-- Upvalues: AIParameterGroup_mt
-- Local values: self
function AIParameterGroup.new(title, customMt)
	-- upvalues: (copy) AIParameterGroup_mt
	local v4_ = customMt or AIParameterGroup_mt
	local v5_ = setmetatable({}, v4_)
	v5_.parameters = {}
	v5_.title = title
	return v5_
end

function AIParameterGroup:getTitle()
	return self.title
end

function AIParameterGroup:addParameter(parameter)
	local v9_ = self.parameters
	table.insert(v9_, parameter)
end

function AIParameterGroup:getParameters()
	return self.parameters
end
