-- Local values: AIMessageErrorVehicleBroken_mt
AIMessageErrorVehicleBroken = {}
local AIMessageErrorVehicleBroken_mt = Class(AIMessageErrorVehicleBroken, AIMessage)

-- Upvalues: AIMessageErrorVehicleBroken_mt
-- Local values: self
function AIMessageErrorVehicleBroken.new(customMt)
	-- upvalues: (copy) AIMessageErrorVehicleBroken_mt
	return AIMessage.new(customMt or AIMessageErrorVehicleBroken_mt)
end

function AIMessageErrorVehicleBroken:getI18NText()
	return g_i18n:getText("ai_messageErrorVehicleBroken")
end
