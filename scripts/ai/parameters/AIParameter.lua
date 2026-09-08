-- Local values: AIParameter_mt
AIParameter = {}
local AIParameter_mt = Class(AIParameter)

-- Upvalues: AIParameter_mt
-- Local values: self
function AIParameter.new(customMt)
	-- upvalues: (copy) AIParameter_mt
	local v3_ = customMt or AIParameter_mt
	local v4_ = setmetatable({}, v3_)
	v4_.type = AIParameterType.TEXT
	v4_.isValid = true
	return v4_
end

function AIParameter:readStream(streamId, connection) end

function AIParameter:writeStream(streamId, connection) end

function AIParameter:getType()
	return self.type
end

function AIParameter:getIsValid()
	return self.isValid
end

function AIParameter:setIsValid(isValid)
	self.isValid = isValid
end

function AIParameter:getCanBeChanged()
	return true
end

function AIParameter:getString()
	return ""
end
