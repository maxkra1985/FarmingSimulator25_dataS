-- Local values: AIMessage_mt
AIMessage = {}
local AIMessage_mt = Class(AIMessage)

-- Upvalues: AIMessage_mt
-- Local values: self
function AIMessage.new(customMt)
	-- upvalues: (copy) AIMessage_mt
	local v3_ = customMt or AIMessage_mt
	return setmetatable({}, v3_)
end

-- Local values: i18nText
function AIMessage:getMessage(job)
	local v6_ = self:getI18NText()
	if v6_ == nil then
		return ""
	elseif job == nil then
		return string.format(v6_, "Unknown")
	else
		return string.format(v6_, job:getHelperName() or "Unknown")
	end
end

function AIMessage:getI18NText()
	return nil
end

function AIMessage:getType()
	return AIMessageType.ERROR
end

function AIMessage:readStream(streamId, connection) end

function AIMessage:writeStream(streamId, connection) end
