-- Local values: AIMessageErrorNoValidFillTypeLoaded_mt
AIMessageErrorNoValidFillTypeLoaded = {}
local AIMessageErrorNoValidFillTypeLoaded_mt = Class(AIMessageErrorNoValidFillTypeLoaded, AIMessage)

-- Upvalues: AIMessageErrorNoValidFillTypeLoaded_mt
-- Local values: self
function AIMessageErrorNoValidFillTypeLoaded.new(customMt)
	-- upvalues: (copy) AIMessageErrorNoValidFillTypeLoaded_mt
	return AIMessage.new(customMt or AIMessageErrorNoValidFillTypeLoaded_mt)
end

function AIMessageErrorNoValidFillTypeLoaded:getI18NText()
	return g_i18n:getText("ai_messageErrorNoValidFillTypeLoaded")
end
