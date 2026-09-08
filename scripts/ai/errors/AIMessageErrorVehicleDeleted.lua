-- Local values: AIMessageErrorVehicleDeleted_mt
AIMessageErrorVehicleDeleted = {}
local AIMessageErrorVehicleDeleted_mt = Class(AIMessageErrorVehicleDeleted, AIMessage)

-- Upvalues: AIMessageErrorVehicleDeleted_mt
-- Local values: self
function AIMessageErrorVehicleDeleted.new(customMt)
	-- upvalues: (copy) AIMessageErrorVehicleDeleted_mt
	return AIMessage.new(customMt or AIMessageErrorVehicleDeleted_mt)
end

function AIMessageErrorVehicleDeleted:getI18NText()
	return g_i18n:getText("ai_messageErrorVehicleDeleted")
end
