-- Local values: FerryStartEvent_mt
FerryStartEvent = {}
local FerryStartEvent_mt = Class(FerryStartEvent, Event)
InitStaticEventClass(FerryStartEvent, "FerryStartEvent")
function FerryStartEvent.emptyNew()
	-- upvalues: (copy) FerryStartEvent_mt
	return Event.new(FerryStartEvent_mt)
end

-- Local values: self
function FerryStartEvent.new(ferry)
	local v3_ = FerryStartEvent.emptyNew()
	v3_.ferry = ferry
	return v3_
end

-- Local values: self
function FerryStartEvent.newToClient(ferry, errorCode)
	local v6_ = FerryStartEvent.emptyNew()
	v6_.ferry = ferry
	v6_.errorCode = errorCode
	return v6_
end

function FerryStartEvent:readStream(streamId, connection)
	self.ferry = NetworkUtil.readNodeObject(streamId)
	if connection:getIsServer() then
		self.errorCode = streamReadUIntN(streamId, Ferry.ERROR_SEND_NUM_BITS)
	end
	self:run(connection)
end

function FerryStartEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.ferry)
	if not connection:getIsServer() then
		streamWriteUIntN(streamId, self.errorCode, Ferry.ERROR_SEND_NUM_BITS)
	end
end

function FerryStartEvent:run(connection)
	if connection:getIsServer() then
		if self.errorCode == Ferry.ERROR_SUCCESS then
			self.ferry:onStarted()
		else
			self.ferry:onStartFailed(self.errorCode)
		end
	else
		self.ferry:start(connection)
		return
	end
end
