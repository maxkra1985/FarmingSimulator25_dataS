-- Local values: FootballShootEvent_mt
FootballShootEvent = {}
local FootballShootEvent_mt = Class(FootballShootEvent, Event)
InitStaticEventClass(FootballShootEvent, "FootballShootEvent")
function FootballShootEvent.emptyNew()
	-- upvalues: (copy) FootballShootEvent_mt
	return Event.new(FootballShootEvent_mt)
end

-- Local values: self
function FootballShootEvent.new(football, dirX, dirZ, angleDeg, velocity, shotType)
	local v8_ = FootballShootEvent.emptyNew()
	v8_.football = football
	v8_.dirX = dirX
	v8_.dirZ = dirZ
	v8_.angleDeg = angleDeg
	v8_.velocity = velocity
	v8_.shotType = shotType
	return v8_
end

-- Local values: self
function FootballShootEvent.newServerToClient(football, shotType)
	local v11_ = FootballShootEvent.emptyNew()
	v11_.football = football
	v11_.shotType = shotType
	return v11_
end

-- Local values: football, rot, yRot, angleDeg, velocity, dirX, dirZ, shotType, football, shotType
function FootballShootEvent:readStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.readNodeObject(streamId):onShot((streamReadUIntN(streamId, 2)))
	else
		local v14_ = NetworkUtil.readNodeObject(streamId)
		local v15_ = streamReadUIntN(streamId, 9)
		local v16_ = math.rad(v15_)
		local v17_ = streamReadUIntN(streamId, 9)
		local v18_ = streamReadUInt8(streamId) * 0.1
		local v19_, v20_ = MathUtil.getDirectionFromYRotation(v16_)
		v14_:shoot(v19_, v20_, v17_, v18_, streamReadUIntN(streamId, 2), connection)
	end
end

-- Local values: yRot
function FootballShootEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		local v24_ = MathUtil.getYRotationFromDirection(self.dirX, self.dirZ) % 6.283185307179586
		NetworkUtil.writeNodeObject(streamId, self.football)
		streamWriteUIntN(streamId, math.deg(v24_), 9)
		streamWriteUIntN(streamId, self.angleDeg, 9)
		streamWriteUInt8(streamId, self.velocity * 10)
		streamWriteUIntN(streamId, self.shotType, 2)
	else
		NetworkUtil.writeNodeObject(streamId, self.football)
		streamWriteUIntN(streamId, self.shotType, 2)
	end
end

function FootballShootEvent:run(connection) end
