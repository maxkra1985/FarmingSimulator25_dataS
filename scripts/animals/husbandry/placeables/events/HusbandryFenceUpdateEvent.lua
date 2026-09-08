-- Local values: HusbandryFenceUpdateEvent_mt
HusbandryFenceUpdateEvent = {}
local HusbandryFenceUpdateEvent_mt = Class(HusbandryFenceUpdateEvent, Event)
InitStaticEventClass(HusbandryFenceUpdateEvent, "HusbandryFenceUpdateEvent")
function HusbandryFenceUpdateEvent.emptyNew()
	-- upvalues: (copy) HusbandryFenceUpdateEvent_mt
	return Event.new(HusbandryFenceUpdateEvent_mt)
end

-- Local values: self
function HusbandryFenceUpdateEvent.new(placeable, deleteCustomizableSegments)
	local v4_ = HusbandryFenceUpdateEvent.emptyNew()
	v4_.placeable = placeable
	v4_.deleteCustomizableSegments = deleteCustomizableSegments
	return v4_
end

function HusbandryFenceUpdateEvent:readStream(streamId, connection)
	self.placeable = NetworkUtil.readNodeObject(streamId)
	self.deleteCustomizableSegments = streamReadBool(streamId)
	self:run(connection)
end

function HusbandryFenceUpdateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.placeable)
	streamWriteBool(streamId, self.deleteCustomizableSegments)
end

function HusbandryFenceUpdateEvent:run(connection)
	if self.placeable ~= nil and self.placeable:getIsSynchronized() then
		if self.deleteCustomizableSegments then
			self.placeable:deleteCustomizableSegments()
		end
		self.placeable:finalizeHusbandryFence()
	end
end
