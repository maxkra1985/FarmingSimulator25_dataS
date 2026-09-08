-- Local values: AIMessageErrorImplementWrongWay_mt
AIMessageErrorImplementWrongWay = {}
local AIMessageErrorImplementWrongWay_mt = Class(AIMessageErrorImplementWrongWay, AIMessage)

-- Upvalues: AIMessageErrorImplementWrongWay_mt
-- Local values: self
function AIMessageErrorImplementWrongWay.new(customMt)
	-- upvalues: (copy) AIMessageErrorImplementWrongWay_mt
	return AIMessage.new(customMt or AIMessageErrorImplementWrongWay_mt)
end

function AIMessageErrorImplementWrongWay:getI18NText()
	return g_i18n:getText("ai_messageErrorImplementWrongWay")
end
