-- Local values: GreatDemandsEvent_mt
GreatDemandsEvent = {}
local GreatDemandsEvent_mt = Class(GreatDemandsEvent, Event)
InitStaticEventClass(GreatDemandsEvent, "GreatDemandsEvent")
function GreatDemandsEvent.emptyNew()
	-- upvalues: (copy) GreatDemandsEvent_mt
	return Event.new(GreatDemandsEvent_mt)
end

-- Local values: self
function GreatDemandsEvent.new(greatDemands)
	local v3_ = GreatDemandsEvent.emptyNew()
	v3_.greatDemands = greatDemands
	return v3_
end

-- Local values: numberOfDemands, i, greatDemand, sellStation, isRunning
function GreatDemandsEvent:readStream(streamId, connection)
	for v7_ = 1, streamReadUInt8(streamId) do
		local v8_ = g_currentMission.economyManager:getGreatDemandById(v7_)
		v8_.isValid = streamReadBool(streamId)
		if v8_.isValid then
			v8_.sellStation = NetworkUtil.readNodeObject(streamId)
			v8_.fillTypeIndex = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
			v8_.demandMultiplier = streamReadFloat32(streamId)
			v8_.demandStart.day = streamReadInt32(streamId)
			v8_.demandStart.hour = streamReadInt32(streamId)
			v8_.demandDuration = streamReadInt32(streamId)
			local v9_ = streamReadBool(streamId)
			local v10_
			if v9_ then
				v10_ = not v8_.isRunning
			else
				v10_ = v9_
			end
			v8_.needsStarting = v10_
			local v11_ = not v9_
			if v11_ then
				v11_ = v8_.isRunning
			end
			v8_.needsStopping = v11_
		elseif v8_.isRunning then
			v8_.needsStopping = true
		end
	end
	self:run(connection)
end

-- Local values: _, greatDemand
function GreatDemandsEvent:writeStream(streamId, connection)
	streamWriteUInt8(streamId, #self.greatDemands)
	for _, v14_ in ipairs(self.greatDemands) do
		if streamWriteBool(streamId, v14_.isValid) then
			NetworkUtil.writeNodeObject(streamId, v14_.sellStation)
			streamWriteUIntN(streamId, v14_.fillTypeIndex, FillTypeManager.SEND_NUM_BITS)
			streamWriteFloat32(streamId, v14_.demandMultiplier)
			streamWriteInt32(streamId, v14_.demandStart.day)
			streamWriteInt32(streamId, v14_.demandStart.hour)
			streamWriteInt32(streamId, v14_.demandDuration)
			streamWriteBool(streamId, v14_.isRunning)
		end
	end
end

-- Local values: _, demand
function GreatDemandsEvent:run(connection)
	if connection:getIsServer() then
		for _, v16_ in pairs(g_currentMission.economyManager.greatDemands) do
			if v16_.needsStarting then
				g_currentMission.economyManager:startGreatDemand(v16_)
				v16_.needsStarting = false
			end
			if v16_.needsStopping then
				g_currentMission.economyManager:stopGreatDemand(v16_)
				v16_.needsStopping = false
			end
		end
	end
end
