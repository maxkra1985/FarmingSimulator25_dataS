-- Local values: FinanceStatsEvent_mt
FinanceStatsEvent = {}
local FinanceStatsEvent_mt = Class(FinanceStatsEvent, Event)
InitStaticEventClass(FinanceStatsEvent, "FinanceStatsEvent")
function FinanceStatsEvent.emptyNew()
	-- upvalues: (copy) FinanceStatsEvent_mt
	return Event.new(FinanceStatsEvent_mt)
end

-- Local values: self
function FinanceStatsEvent.new(historyIndex, farmId)
	local v4_ = FinanceStatsEvent.emptyNew()
	v4_.historyIndex = historyIndex
	v4_.farmId = farmId
	local v5_
	if historyIndex >= 0 then
		v5_ = historyIndex <= 255
	else
		v5_ = false
	end
	assert(v5_)
	return v4_
end

-- Local values: financesHistoryVersionCounter, readData, _, statName, money, farm, stats, finances, numHistoryEntries, _, statName, money
function FinanceStatsEvent:readStream(streamId, connection)
	self.historyIndex = streamReadUInt8(streamId)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	if connection:getIsServer() then
		if streamReadBool(streamId) then
			local v9_ = streamReadUIntN(streamId, 7)
			local v10_ = {}
			if streamReadBool(streamId) then
				for _, v11_ in ipairs(FinanceStats.statNames) do
					v10_[v11_] = streamReadFloat32(streamId)
				end
			end
			local v12_ = g_farmManager:getFarmById(self.farmId)
			if v12_ ~= nil then
				local v13_ = v12_.stats
				v13_.financesHistoryVersionCounter = v9_
				local v14_
				if self.historyIndex == 0 then
					v14_ = v13_.finances
				else
					local v15_ = #v13_.financesHistory
					if v15_ < self.historyIndex then
						for _ = 1, self.historyIndex - v15_ do
							local v16_ = v13_.financesHistory
							local v17_ = FinanceStats.new
							table.insert(v16_, 1, v17_())
						end
						v15_ = self.historyIndex
					end
					v14_ = v13_.financesHistory[v15_ - self.historyIndex + 1]
				end
				for v18_, v19_ in pairs(v10_) do
					v14_[v18_] = v19_
				end
				return
			end
		end
	else
		connection:sendEvent(self)
	end
end

-- Local values: farm, stats, financesHistoryVersionCounter, finances, numHistoryEntries, _, statName, money
function FinanceStatsEvent:writeStream(streamId, connection)
	streamWriteUInt8(streamId, self.historyIndex)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	if not connection:getIsServer() then
		local v23_ = g_farmManager:getFarmById(self.farmId)
		if streamWriteBool(streamId, v23_ ~= nil) then
			local v24_ = v23_.stats
			local v25_ = v24_.financesHistoryVersionCounter
			streamWriteUIntN(streamId, v25_, 7)
			local v26_ = nil
			if self.historyIndex == 0 then
				v26_ = v24_.finances
			else
				local v27_ = #v24_.financesHistory
				if self.historyIndex <= v27_ then
					v26_ = v24_.financesHistory[v27_ - self.historyIndex + 1]
				end
			end
			local v28_ = streamWriteBool
			local v29_
			if v26_ == nil then
				v29_ = false
			else
				v29_ = self.farmId ~= FarmManager.SPECTATOR_FARM_ID
			end
			if v28_(streamId, v29_) then
				for _, v30_ in ipairs(FinanceStats.statNames) do
					local v31_ = Utils.getNoNil(v26_[v30_], 0)
					streamWriteFloat32(streamId, v31_)
				end
			end
		end
	end
end

function FinanceStatsEvent:run(connection)
	printError("Error: FinanceStatsEvent is not allowed to be executed on a local client")
end
