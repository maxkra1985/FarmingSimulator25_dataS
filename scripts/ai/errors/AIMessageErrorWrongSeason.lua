-- Local values: AIMessageErrorWrongSeason_mt
AIMessageErrorWrongSeason = {}
local AIMessageErrorWrongSeason_mt = Class(AIMessageErrorWrongSeason, AIMessage)

-- Upvalues: AIMessageErrorWrongSeason_mt
-- Local values: self
function AIMessageErrorWrongSeason.new(customMt)
	-- upvalues: (copy) AIMessageErrorWrongSeason_mt
	return AIMessage.new(customMt or AIMessageErrorWrongSeason_mt)
end

function AIMessageErrorWrongSeason:getI18NText()
	return g_i18n:getText("ai_messageErrorWrongSeason")
end
