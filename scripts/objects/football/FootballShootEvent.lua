FootballShootEvent = {}
local FootballShootEvent_mt = Class(FootballShootEvent, Event)
InitStaticEventClass(FootballShootEvent, "FootballShootEvent")
function FootballShootEvent.emptyNew()
	local self = Event.new(FootballShootEvent_mt)
	return self
end
function FootballShootEvent.new(football, dirX, dirZ, angleDeg, velocity, shotType)
	local self = FootballShootEvent.emptyNew()
	self.football = football
	self.dirX = dirX
	self.dirZ = dirZ
	self.angleDeg = angleDeg
	self.velocity = velocity
	self.shotType = shotType
	return self
end
function FootballShootEvent.newServerToClient(football, shotType)
	local self = FootballShootEvent.emptyNew()
	self.football = football
	self.shotType = shotType
	return self
end
function FootballShootEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		local football = NetworkUtil.readNodeObject(streamId)
		local rot = streamReadUIntN(streamId, 9)
		local yRot = math.rad(rot)
		local angleDeg = streamReadUIntN(streamId, 9)
		local velocity = streamReadUInt8(streamId) * 0.1
		local dirX, dirZ = MathUtil.getDirectionFromYRotation(yRot)
		local shotType = streamReadUIntN(streamId, 2)
		football:shoot(dirX, dirZ, angleDeg, velocity, shotType, connection)
	else
		local football = NetworkUtil.readNodeObject(streamId)
		local shotType = streamReadUIntN(streamId, 2)
		football:onShot(shotType)
	end
end
function FootballShootEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		local yRot = MathUtil.getYRotationFromDirection(self.dirX, self.dirZ)
		yRot = yRot % 6.283185307179586
		NetworkUtil.writeNodeObject(streamId, self.football)
		streamWriteUIntN(streamId, math.deg(yRot), 9)
		streamWriteUIntN(streamId, self.angleDeg, 9)
		streamWriteUInt8(streamId, self.velocity * 10)
		streamWriteUIntN(streamId, self.shotType, 2)
	else
		NetworkUtil.writeNodeObject(streamId, self.football)
		streamWriteUIntN(streamId, self.shotType, 2)
	end
end
function FootballShootEvent:run(connection) end
