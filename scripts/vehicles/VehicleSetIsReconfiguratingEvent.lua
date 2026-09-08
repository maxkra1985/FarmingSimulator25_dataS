-- Local values: VehicleSetIsReconfiguratingEvent_mt
VehicleSetIsReconfiguratingEvent = {}
local VehicleSetIsReconfiguratingEvent_mt = Class(VehicleSetIsReconfiguratingEvent, Event)
InitStaticEventClass(VehicleSetIsReconfiguratingEvent, "VehicleSetIsReconfiguratingEvent")
function VehicleSetIsReconfiguratingEvent.emptyNew()
	-- upvalues: (copy) VehicleSetIsReconfiguratingEvent_mt
	return Event.new(VehicleSetIsReconfiguratingEvent_mt)
end

-- Local values: self
function VehicleSetIsReconfiguratingEvent.new(object)
	local v3_ = VehicleSetIsReconfiguratingEvent.emptyNew()
	v3_.object = object
	return v3_
end

function VehicleSetIsReconfiguratingEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object.isReconfigurating = true
	end
end

function VehicleSetIsReconfiguratingEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
end
