-- Local values: AIMessageErrorCouldNotPrepare_mt
AIMessageErrorCouldNotPrepare = {}
local AIMessageErrorCouldNotPrepare_mt = Class(AIMessageErrorCouldNotPrepare, AIMessage)

-- Upvalues: AIMessageErrorCouldNotPrepare_mt
-- Local values: self
function AIMessageErrorCouldNotPrepare.new(vehicle, customMt)
	-- upvalues: (copy) AIMessageErrorCouldNotPrepare_mt
	local v4_ = AIMessage.new(customMt or AIMessageErrorCouldNotPrepare_mt)
	v4_.vehicle = vehicle
	return v4_
end

-- Local values: i18nText, vehicleName, helperName
function AIMessageErrorCouldNotPrepare:getMessage(job)
	local v7_ = self:getI18NText()
	local v8_ = self.vehicle == nil and "" or self.vehicle:getName()
	local v9_ = "Unknown"
	if job ~= nil then
		v9_ = job:getHelperName() or v9_
	end
	return string.format(v7_, v9_, v8_)
end

function AIMessageErrorCouldNotPrepare:getI18NText()
	return g_i18n:getText("ai_messageErrorCouldNotPrepare")
end

function AIMessageErrorCouldNotPrepare:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
end

function AIMessageErrorCouldNotPrepare:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
end
