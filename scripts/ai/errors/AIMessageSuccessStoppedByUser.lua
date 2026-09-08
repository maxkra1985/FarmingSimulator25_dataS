-- Local values: AIMessageSuccessStoppedByUser_mt
AIMessageSuccessStoppedByUser = {}
local AIMessageSuccessStoppedByUser_mt = Class(AIMessageSuccessStoppedByUser, AIMessage)

-- Upvalues: AIMessageSuccessStoppedByUser_mt
-- Local values: self
function AIMessageSuccessStoppedByUser.new(customMt)
	-- upvalues: (copy) AIMessageSuccessStoppedByUser_mt
	return AIMessage.new(customMt or AIMessageSuccessStoppedByUser_mt)
end

function AIMessageSuccessStoppedByUser:getI18NText()
	return g_i18n:getText("ai_messageSuccessStoppedByUser")
end

function AIMessageSuccessStoppedByUser:getType()
	return AIMessageType.OK
end
