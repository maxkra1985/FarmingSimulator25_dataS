AIMessage = {}
local AIMessage_mt = Class(AIMessage)
function AIMessage.new(customMt)
	local self = setmetatable({}, customMt or AIMessage_mt)
	return self
end
function AIMessage:getMessage(job)
	local i18nText = self:getI18NText()
	if i18nText ~= nil then
		if job == nil then
			return string.format(i18nText, "Unknown")
		else
			return string.format(i18nText, job:getHelperName() or "Unknown")
		end
	end
	return ""
end
function AIMessage:getI18NText()
	return nil
end
function AIMessage:getType()
	return AIMessageType.ERROR
end
function AIMessage:readStream(streamId, connection) end
function AIMessage:writeStream(streamId, connection) end
