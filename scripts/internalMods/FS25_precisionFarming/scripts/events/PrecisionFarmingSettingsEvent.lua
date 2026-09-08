-- Local values: PrecisionFarmingSettingsEvent_mt
PrecisionFarmingSettingsEvent = {}
local PrecisionFarmingSettingsEvent_mt = Class(PrecisionFarmingSettingsEvent, Event)
InitEventClass(PrecisionFarmingSettingsEvent, "PrecisionFarmingSettingsEvent")
function PrecisionFarmingSettingsEvent.emptyNew()
	-- upvalues: (copy) PrecisionFarmingSettingsEvent_mt
	return Event.new(PrecisionFarmingSettingsEvent_mt)
end

-- Local values: self
function PrecisionFarmingSettingsEvent.new(setting)
	local v3_ = PrecisionFarmingSettingsEvent.emptyNew()
	v3_.setting = setting
	return v3_
end

-- Local values: precisionFarmingSettings, index, state
function PrecisionFarmingSettingsEvent:readStream(streamId, connection)
	local v7_ = g_precisionFarming.precisionFarmingSettings
	local v8_ = streamReadUIntN(streamId, v7_.settingIndexNumBits)
	local v9_ = streamReadBool(streamId)
	self.setting = v7_.settings[v8_]
	self.setting.state = v9_
	self:run(connection)
end

-- Local values: precisionFarmingSettings
function PrecisionFarmingSettingsEvent:writeStream(streamId, connection)
	local v12_ = g_precisionFarming.precisionFarmingSettings
	streamWriteUIntN(streamId, self.setting.index, v12_.settingIndexNumBits)
	streamWriteBool(streamId, self.setting.state == true)
end

-- Local values: precisionFarmingSettings
function PrecisionFarmingSettingsEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, nil)
	end
	g_precisionFarming.precisionFarmingSettings:onSettingChanged(self.setting, true)
end

function PrecisionFarmingSettingsEvent.sendEvent(setting, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(PrecisionFarmingSettingsEvent.new(setting), nil, nil, nil)
			return
		end
		g_client:getServerConnection():sendEvent(PrecisionFarmingSettingsEvent.new(setting))
	end
end
