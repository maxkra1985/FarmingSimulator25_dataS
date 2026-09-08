-- Local values: AIMessageSuccessFinishedJob_mt
AIMessageSuccessFinishedJob = {}
local AIMessageSuccessFinishedJob_mt = Class(AIMessageSuccessFinishedJob, AIMessage)

-- Upvalues: AIMessageSuccessFinishedJob_mt
-- Local values: self
function AIMessageSuccessFinishedJob.new(customMt)
	-- upvalues: (copy) AIMessageSuccessFinishedJob_mt
	return AIMessage.new(customMt or AIMessageSuccessFinishedJob_mt)
end

function AIMessageSuccessFinishedJob:getI18NText()
	return g_i18n:getText("ai_messageSuccessFinishedJob")
end

function AIMessageSuccessFinishedJob:getType()
	return AIMessageType.OK
end
