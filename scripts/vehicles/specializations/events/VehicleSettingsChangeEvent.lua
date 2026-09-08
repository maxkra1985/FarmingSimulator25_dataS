-- Local values: VehicleSettingsChangeEvent_mt
VehicleSettingsChangeEvent = {}
local VehicleSettingsChangeEvent_mt = Class(VehicleSettingsChangeEvent, Event)
InitStaticEventClass(VehicleSettingsChangeEvent, "VehicleSettingsChangeEvent")
function VehicleSettingsChangeEvent.emptyNew()
	-- upvalues: (copy) VehicleSettingsChangeEvent_mt
	return Event.new(VehicleSettingsChangeEvent_mt)
end

-- Local values: self
function VehicleSettingsChangeEvent.new(vehicle, settings, state)
	local v4_ = VehicleSettingsChangeEvent.emptyNew()
	v4_.vehicle = vehicle
	v4_.settings = settings
	return v4_
end

-- Local values: vehicle, numSettings, isValid, i, index, state
function VehicleSettingsChangeEvent:readStream(streamId, connection)
	local v6_ = NetworkUtil.readNodeObject(streamId)
	local v7_ = streamReadUInt8(streamId)
	local v8_
	if v6_ == nil then
		v8_ = false
	else
		v8_ = v6_:getIsSynchronized()
	end
	for _ = 1, v7_ do
		local v9_ = streamReadUInt8(streamId)
		local v10_
		if streamReadBool(streamId) then
			v10_ = streamReadBool(streamId)
		else
			v10_ = streamReadUInt8(streamId)
		end
		if v8_ then
			v6_:setVehicleSettingState(v9_, v10_, true)
		end
	end
end

-- Local values: numSettingsToSend, i, i, setting
function VehicleSettingsChangeEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	local v13_ = 0
	for v14_ = 1, #self.settings do
		if self.settings[v14_].isDirty then
			v13_ = v13_ + 1
		end
	end
	streamWriteUInt8(streamId, v13_)
	for v15_ = 1, #self.settings do
		local v16_ = self.settings[v15_]
		if v16_.isDirty then
			streamWriteUInt8(streamId, v16_.index)
			if streamWriteBool(streamId, v16_.isBool) then
				streamWriteBool(streamId, v16_.state)
			else
				streamWriteUInt8(streamId, v16_.state)
			end
			v16_.isDirty = false
		end
	end
end

function VehicleSettingsChangeEvent:run(connection) end
