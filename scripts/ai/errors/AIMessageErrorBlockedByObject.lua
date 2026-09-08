-- Local values: AIMessageErrorBlockedByObject_mt
AIMessageErrorBlockedByObject = {}
local AIMessageErrorBlockedByObject_mt = Class(AIMessageErrorBlockedByObject, AIMessage)

-- Upvalues: AIMessageErrorBlockedByObject_mt
-- Local values: self
function AIMessageErrorBlockedByObject.new(customMt)
	-- upvalues: (copy) AIMessageErrorBlockedByObject_mt
	return AIMessage.new(customMt or AIMessageErrorBlockedByObject_mt)
end

function AIMessage:getI18NText()
	return g_i18n:getText("ai_messageErrorBlockedByObject")
end
