-- Local values: VehicleSaleAddEvent_mt
VehicleSaleAddEvent = {}
local VehicleSaleAddEvent_mt = Class(VehicleSaleAddEvent, Event)
InitStaticEventClass(VehicleSaleAddEvent, "VehicleSaleAddEvent")
function VehicleSaleAddEvent.emptyNew()
	-- upvalues: (copy) VehicleSaleAddEvent_mt
	return Event.new(VehicleSaleAddEvent_mt)
end

-- Local values: self
function VehicleSaleAddEvent.new(saleItem)
	local v3_ = VehicleSaleAddEvent.emptyNew()
	v3_.saleItem = saleItem
	return v3_
end

-- Local values: saleItem, numConfigurations, i, name, id
function VehicleSaleAddEvent:readStream(streamId, connection)
	local v7_ = {
		["id"] = streamReadUInt8(streamId),
		["xmlFilename"] = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId)),
		["age"] = streamReadUInt16(streamId),
		["price"] = streamReadInt32(streamId),
		["damage"] = NetworkUtil.readCompressedPercentages(streamId, 10),
		["wear"] = NetworkUtil.readCompressedPercentages(streamId, 10),
		["operatingTime"] = streamReadFloat32(streamId),
		["boughtConfigurations"] = {}
	}
	for _ = 1, streamReadUInt8(streamId) do
		local v8_ = g_vehicleConfigurationManager:getConfigurationNameByIndex(streamReadUIntN(streamId, ConfigurationUtil.SEND_NUM_BITS))
		local v9_ = streamReadUIntN(streamId, ConfigurationUtil.SEND_NUM_BITS)
		if v7_.boughtConfigurations[v8_] == nil then
			v7_.boughtConfigurations[v8_] = {}
		end
		v7_.boughtConfigurations[v8_][v9_] = true
	end
	self.saleItem = v7_
	self:run(connection)
end

-- Local values: saleItem, config, name, ids, id, _, i
function VehicleSaleAddEvent:writeStream(streamId, connection)
	local v12_ = self.saleItem
	streamWriteUInt8(streamId, v12_.id)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(v12_.xmlFilename))
	streamWriteUInt16(streamId, v12_.age)
	streamWriteInt32(streamId, v12_.price)
	NetworkUtil.writeCompressedPercentages(streamId, v12_.damage, 10)
	NetworkUtil.writeCompressedPercentages(streamId, v12_.wear, 10)
	streamWriteFloat32(streamId, v12_.operatingTime)
	local v13_ = {}
	for v14_, v15_ in pairs(v12_.boughtConfigurations) do
		for v16_, _ in pairs(v15_) do
			local v17_ = {
				["nameId"] = g_vehicleConfigurationManager:getConfigurationIndexByName(v14_),
				["configId"] = v16_
			}
			table.insert(v13_, v17_)
		end
	end
	streamWriteUInt8(streamId, #v13_)
	for v18_ = 1, #v13_ do
		streamWriteUIntN(streamId, v13_[v18_].nameId, ConfigurationUtil.SEND_NUM_BITS)
		streamWriteUIntN(streamId, v13_[v18_].configId, ConfigurationUtil.SEND_NUM_BITS)
	end
end

function VehicleSaleAddEvent:run(connection)
	if connection:getIsServer() then
		g_currentMission.vehicleSaleSystem:addSale(self.saleItem, true)
	end
end
