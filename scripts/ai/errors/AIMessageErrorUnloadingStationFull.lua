-- Local values: AIMessageErrorUnloadingStationFull_mt
AIMessageErrorUnloadingStationFull = {}
local AIMessageErrorUnloadingStationFull_mt = Class(AIMessageErrorUnloadingStationFull, AIMessage)

-- Upvalues: AIMessageErrorUnloadingStationFull_mt
-- Local values: self
function AIMessageErrorUnloadingStationFull.new(customMt)
	-- upvalues: (copy) AIMessageErrorUnloadingStationFull_mt
	return AIMessage.new(customMt or AIMessageErrorUnloadingStationFull_mt)
end

function AIMessageErrorUnloadingStationFull:getI18NText()
	return g_i18n:getText("ai_messageErrorUnloadingStationFull")
end
