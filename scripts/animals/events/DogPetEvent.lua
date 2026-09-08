-- Local values: DogPetEvent_mt
DogPetEvent = {}
local DogPetEvent_mt = Class(DogPetEvent, Event)
InitStaticEventClass(DogPetEvent, "DogPetEvent")
function DogPetEvent.emptyNew()
	-- upvalues: (copy) DogPetEvent_mt
	return Event.new(DogPetEvent_mt)
end

-- Local values: self
function DogPetEvent.new(dog)
	local v3_ = DogPetEvent.emptyNew()
	v3_.dog = dog
	return v3_
end

function DogPetEvent:readStream(streamId, connection)
	self.dog = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end

function DogPetEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.dog)
end

function DogPetEvent:run(connection)
	if self.dog ~= nil then
		self.dog:pet()
	end
end
