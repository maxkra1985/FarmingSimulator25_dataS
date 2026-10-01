AIMessageErrorBlockedByObject = {}
local AIMessageErrorBlockedByObject_mt = Class(AIMessageErrorBlockedByObject, AIMessage)
function AIMessageErrorBlockedByObject.new(customMt)
	local self = AIMessage.new(customMt or AIMessageErrorBlockedByObject_mt)
	return self
end
function AIMessage:getI18NText()
	return g_i18n:getText("ai_messageErrorBlockedByObject")
end
