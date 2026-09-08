-- Local values: DogFetchItemEvent_mt
DogFetchItemEvent = {}
local DogFetchItemEvent_mt = Class(DogFetchItemEvent, Event)
InitStaticEventClass(DogFetchItemEvent, "DogFetchItemEvent")
function DogFetchItemEvent.emptyNew()
	-- upvalues: (copy) DogFetchItemEvent_mt
	return Event.new(DogFetchItemEvent_mt)
end

-- Local values: self
function DogFetchItemEvent.new(dog, player, item)
	local v5_ = DogFetchItemEvent.emptyNew()
	v5_.dog = dog
	v5_.player = player
	v5_.item = item
	return v5_
end

function DogFetchItemEvent:readStream(streamId, connection)
	self.dog = NetworkUtil.readNodeObject(streamId)
	self.player = NetworkUtil.readNodeObject(streamId)
	self.item = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end

function DogFetchItemEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.dog)
	NetworkUtil.writeNodeObject(streamId, self.player)
	NetworkUtil.writeNodeObject(streamId, self.item)
end

function DogFetchItemEvent:run(connection)
	if self.dog ~= nil and (self.player ~= nil and self.item ~= nil) then
		self.dog:fetchItem(self.player, self.item)
	end
end
