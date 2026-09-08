-- Local values: GetAdminAnswerEvent_mt
GetAdminAnswerEvent = {}
local GetAdminAnswerEvent_mt = Class(GetAdminAnswerEvent, Event)
InitStaticEventClass(GetAdminAnswerEvent, "GetAdminAnswerEvent")
GetAdminAnswerEvent.ACCESS_GRANTED = 0
GetAdminAnswerEvent.ACCESS_DENIED = 1
GetAdminAnswerEvent.NOT_SUPPORTED = 2
GetAdminAnswerEvent.sendNumBits = 2
function GetAdminAnswerEvent.emptyNew()
	-- upvalues: (copy) GetAdminAnswerEvent_mt
	return Event.new(GetAdminAnswerEvent_mt)
end

-- Local values: self
function GetAdminAnswerEvent.new(state)
	local v3_ = GetAdminAnswerEvent.emptyNew()
	v3_.state = state
	return v3_
end

function GetAdminAnswerEvent:readStream(streamId, connection)
	self.state = streamReadUIntN(streamId, GetAdminAnswerEvent.sendNumBits)
	self:run(connection)
end

function GetAdminAnswerEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.state, GetAdminAnswerEvent.sendNumBits)
end

-- Local values: text, dialogType
function GetAdminAnswerEvent:run(connection)
	if connection:getIsServer() then
		local v11_ = g_i18n:getText("ui_adminLoginNotSupported")
		local v12_ = DialogElement.TYPE_WARNING
		if self.state == GetAdminAnswerEvent.ACCESS_GRANTED then
			v11_ = g_i18n:getText("ui_adminLoginGranted")
			v12_ = DialogElement.TYPE_INFO
		elseif self.state == GetAdminAnswerEvent.ACCESS_DENIED then
			v11_ = g_i18n:getText("ui_wrongPassword")
		end
		if self.state == GetAdminAnswerEvent.ACCESS_GRANTED then
			g_messageCenter:publish(GetAdminAnswerEvent, true)
		end
		InfoDialog.show(v11_, nil, nil, v12_)
	else
		printError("Error: GetAdminAnswerEvent: This is a server to client event!")
	end
end
