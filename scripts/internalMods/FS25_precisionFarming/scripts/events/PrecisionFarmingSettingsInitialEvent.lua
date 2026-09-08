-- Local values: PrecisionFarmingSettingsInitialEvent_mt
PrecisionFarmingSettingsInitialEvent = {}
local PrecisionFarmingSettingsInitialEvent_mt = Class(PrecisionFarmingSettingsInitialEvent, Event)
InitEventClass(PrecisionFarmingSettingsInitialEvent, "PrecisionFarmingSettingsInitialEvent")
function PrecisionFarmingSettingsInitialEvent.emptyNew()
	-- upvalues: (copy) PrecisionFarmingSettingsInitialEvent_mt
	return Event.new(PrecisionFarmingSettingsInitialEvent_mt)
end

-- Local values: self
function PrecisionFarmingSettingsInitialEvent.new(settings)
	local v3_ = PrecisionFarmingSettingsInitialEvent.emptyNew()
	v3_.settings = settings
	return v3_
end

-- Local values: precisionFarmingSettings, _, setting
function PrecisionFarmingSettingsInitialEvent:readStream(streamId, connection)
	local v7_ = g_precisionFarming.precisionFarmingSettings
	for _, v8_ in ipairs(v7_.settings) do
		if v8_.isServerSetting then
			v8_.state = streamReadBool(streamId)
		end
	end
	self:run(connection)
end

-- Local values: precisionFarmingSettings, _, setting
function PrecisionFarmingSettingsInitialEvent:writeStream(streamId, connection)
	local v10_ = g_precisionFarming.precisionFarmingSettings
	for _, v11_ in ipairs(v10_.settings) do
		if v11_.isServerSetting then
			streamWriteBool(streamId, v11_.state == true)
		end
	end
end

-- Local values: precisionFarmingSettings, _, setting
function PrecisionFarmingSettingsInitialEvent:run(connection)
	local v12_ = g_precisionFarming.precisionFarmingSettings
	for _, v13_ in ipairs(v12_.settings) do
		if v13_.isServerSetting then
			v12_:onSettingChanged(v13_, true)
		end
	end
end
