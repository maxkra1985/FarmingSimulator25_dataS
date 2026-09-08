-- Local values: AIMessageErrorNoFieldFound_mt
AIMessageErrorNoFieldFound = {}
local AIMessageErrorNoFieldFound_mt = Class(AIMessageErrorNoFieldFound, AIMessage)

-- Upvalues: AIMessageErrorNoFieldFound_mt
-- Local values: self
function AIMessageErrorNoFieldFound.new(customMt)
	-- upvalues: (copy) AIMessageErrorNoFieldFound_mt
	return AIMessage.new(customMt or AIMessageErrorNoFieldFound_mt)
end

function AIMessageErrorNoFieldFound:getI18NText()
	return g_i18n:getText("ai_messageErrorNoFieldFound")
end
