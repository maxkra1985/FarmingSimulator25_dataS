-- Local values: YarderTowerSetTargetEvent_mt
YarderTowerSetTargetEvent = {}
local YarderTowerSetTargetEvent_mt = Class(YarderTowerSetTargetEvent, Event)
InitStaticEventClass(YarderTowerSetTargetEvent, "YarderTowerSetTargetEvent")
function YarderTowerSetTargetEvent.emptyNew()
	-- upvalues: (copy) YarderTowerSetTargetEvent_mt
	return Event.new(YarderTowerSetTargetEvent_mt)
end

-- Local values: self
function YarderTowerSetTargetEvent.new(object, state, x, y, z)
	local v7_ = YarderTowerSetTargetEvent.emptyNew()
	v7_.object = object
	v7_.state = state
	v7_.x = x
	v7_.y = y
	v7_.z = z
	return v7_
end

function YarderTowerSetTargetEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadBool(streamId)
	if self.state then
		self.x = streamReadFloat32(streamId)
		self.y = streamReadFloat32(streamId)
		self.z = streamReadFloat32(streamId)
	end
	self:run(connection)
end

function YarderTowerSetTargetEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	if streamWriteBool(streamId, self.state) then
		streamWriteFloat32(streamId, self.x)
		streamWriteFloat32(streamId, self.y)
		streamWriteFloat32(streamId, self.z)
	end
end

-- Local values: spec
function YarderTowerSetTargetEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end
	if self.object ~= nil and self.object:getIsSynchronized() then
		local v15_ = self.object.spec_yarderTower
		if self.x ~= nil then
			v15_.mainRope.isValid = true
			local v16_ = v15_.mainRope.target
			local v17_ = v15_.mainRope.target
			local v18_ = v15_.mainRope.target
			local v19_ = self.x
			local v20_ = self.y
			local v21_ = self.z
			v16_[1] = v19_
			v17_[2] = v20_
			v18_[3] = v21_
		end
		self.object:setYarderTargetActive(self.state, true)
	end
end

function YarderTowerSetTargetEvent.sendEvent(vehicle, state, x, y, z, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(YarderTowerSetTargetEvent.new(vehicle, state, x, y, z), nil, nil, vehicle)
			return
		end
		g_client:getServerConnection():sendEvent(YarderTowerSetTargetEvent.new(vehicle, state, x, y, z))
	end
end
