-- Local values: AIMessageErrorVineyardNotSupported_mt
AIMessageErrorVineyardNotSupported = {}
local AIMessageErrorVineyardNotSupported_mt = Class(AIMessageErrorVineyardNotSupported, AIMessage)

-- Upvalues: AIMessageErrorVineyardNotSupported_mt
-- Local values: self
function AIMessageErrorVineyardNotSupported.new(customMt)
	-- upvalues: (copy) AIMessageErrorVineyardNotSupported_mt
	return AIMessage.new(customMt or AIMessageErrorVineyardNotSupported_mt)
end

function AIMessageErrorVineyardNotSupported:getI18NText()
	return g_i18n:getText("ai_messageErrorVineyardNotSupported")
end
