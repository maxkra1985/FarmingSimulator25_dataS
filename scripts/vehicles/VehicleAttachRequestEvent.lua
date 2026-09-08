-- Local values: VehicleAttachRequestEvent_mt
VehicleAttachRequestEvent = {}
local VehicleAttachRequestEvent_mt = Class(VehicleAttachRequestEvent, Event)
InitStaticEventClass(VehicleAttachRequestEvent, "VehicleAttachRequestEvent")
function VehicleAttachRequestEvent.emptyNew()
	-- upvalues: (copy) VehicleAttachRequestEvent_mt
	return Event.new(VehicleAttachRequestEvent_mt)
end

-- Local values: self
function VehicleAttachRequestEvent.new(info)
	local v3_ = VehicleAttachRequestEvent.emptyNew()
	v3_.attacherVehicle = info.attacherVehicle
	v3_.attachable = info.attachable
	v3_.attacherVehicleJointDescIndex = info.attacherVehicleJointDescIndex
	v3_.attachableJointDescIndex = info.attachableJointDescIndex
	return v3_
end

function VehicleAttachRequestEvent:readStream(streamId, connection)
	self.attacherVehicle = NetworkUtil.readNodeObject(streamId)
	self.attachable = NetworkUtil.readNodeObject(streamId)
	self.attacherVehicleJointDescIndex = streamReadUIntN(streamId, 7)
	self.attachableJointDescIndex = streamReadUIntN(streamId, 7)
	self:run(connection)
end

function VehicleAttachRequestEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.attacherVehicle)
	NetworkUtil.writeNodeObject(streamId, self.attachable)
	streamWriteUIntN(streamId, self.attacherVehicleJointDescIndex, 7)
	streamWriteUIntN(streamId, self.attachableJointDescIndex, 7)
end

function VehicleAttachRequestEvent:run(connection)
	if not connection:getIsServer() and (self.attacherVehicle ~= nil and self.attacherVehicle:getIsSynchronized()) then
		self.attacherVehicle:attachImplementFromInfo(self)
	end
end
