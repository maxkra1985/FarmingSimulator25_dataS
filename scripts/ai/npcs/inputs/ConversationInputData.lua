-- Local values: ConversationInputData_mt
ConversationInputData = {}
local ConversationInputData_mt = Class(ConversationInputData)

-- Upvalues: ConversationInputData_mt
-- Local values: self
function ConversationInputData.new(customMt)
	-- upvalues: (copy) ConversationInputData_mt
	local v3_ = customMt or ConversationInputData_mt
	local v4_ = setmetatable({}, v3_)
	v4_:reset()
	return v4_
end

function ConversationInputData:delete()
	self:reset()
end

function ConversationInputData:reset()
	self.inputData = {}
end

function ConversationInputData:setData(name, value)
	self.inputData[name] = value
end

function ConversationInputData:getData(name)
	return self.inputData[name]
end
