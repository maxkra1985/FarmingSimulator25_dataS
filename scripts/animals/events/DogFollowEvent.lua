-- Local values: DogFollowEvent_mt
DogFollowEvent = {}
local DogFollowEvent_mt = Class(DogFollowEvent, Event)
InitStaticEventClass(DogFollowEvent, "DogFollowEvent")
function DogFollowEvent.emptyNew()
	-- upvalues: (copy) DogFollowEvent_mt
	return Event.new(DogFollowEvent_mt)
end

-- Local values: self
function DogFollowEvent.new(dog, player)
	local v4_ = DogFollowEvent.emptyNew()
	v4_.dog = dog
	v4_.player = player
	v4_.follow = player ~= nil
	return v4_
end

function DogFollowEvent:readStream(streamId, connection)
	self.dog = NetworkUtil.readNodeObject(streamId)
	self.follow = streamReadBool(streamId)
	if self.follow then
		self.player = NetworkUtil.readNodeObject(streamId)
	end
	self:run(connection)
end

function DogFollowEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.dog)
	if streamWriteBool(streamId, self.follow) then
		NetworkUtil.writeNodeObject(streamId, self.player)
	end
end

function DogFollowEvent:run(connection)
	if self.dog ~= nil then
		if self.follow then
			if self.player ~= nil then
				self.dog:followEntity(self.player)
				return
			end
		else
			self.dog:goToSpawn()
		end
	end
end
