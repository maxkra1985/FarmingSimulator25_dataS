-- Local values: EnvironmentalScoreValue_mt
EnvironmentalScoreValue = {}
local EnvironmentalScoreValue_mt = Class(EnvironmentalScoreValue)

-- Upvalues: EnvironmentalScoreValue_mt
-- Local values: self
function EnvironmentalScoreValue.new(pfModule, customMt)
	-- upvalues: (copy) EnvironmentalScoreValue_mt
	local v4_ = customMt or EnvironmentalScoreValue_mt
	local v5_ = setmetatable({}, v4_)
	v5_.pfModule = pfModule
	v5_.xmlKey = "default"
	return v5_
end

function EnvironmentalScoreValue:initFarmlandData()
	return {}
end

function EnvironmentalScoreValue:getFarmlandData(farmlandId)
	if farmlandId ~= nil and self.farmlandDatas[farmlandId] == nil then
		self.farmlandDatas[farmlandId] = self:initFarmlandData()
		self.farmlandDatas[farmlandId].farmlandId = farmlandId
	end
	return self.farmlandDatas[farmlandId]
end

function EnvironmentalScoreValue:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
	self.farmlandDatas = {}
	return true
end

function EnvironmentalScoreValue:loadFromItemsXML(xmlFile, key)
	xmlFile:iterate(string.format("%s.%s.farmland", key, self.xmlKey), function(_, p12_)
		-- upvalues: (copy) xmlFile, (copy) self
		local v13_ = xmlFile:getInt(p12_ .. "#farmlandId")
		if v13_ ~= nil then
			self:loadFarmlandData(self:getFarmlandData(v13_), xmlFile, p12_)
		end
	end)
end

-- Local values: index, farmlandId, data, dataKey
function EnvironmentalScoreValue:saveToXMLFile(xmlFile, key, usedModNames)
	local v17_ = 0
	for v18_, v19_ in pairs(self.farmlandDatas) do
		local v20_ = string.format("%s.%s.farmland(%d)", key, self.xmlKey, v17_)
		xmlFile:setInt(v20_ .. "#farmlandId", v18_)
		self:saveFarmlandData(v19_, xmlFile, v20_)
		v17_ = v17_ + 1
	end
end

function EnvironmentalScoreValue:loadFarmlandData(data, xmlFile, key) end

function EnvironmentalScoreValue:saveFarmlandData(data, xmlFile, key) end

-- Local values: numFarmlandDatas, i, farmlandId, data
function EnvironmentalScoreValue:readStream(streamId, connection, farmId)
	for _ = 1, streamReadUIntN(streamId, g_farmlandManager.numberOfBits) do
		self:readFarmlandDataFromStream(self:getFarmlandData((streamReadUIntN(streamId, g_farmlandManager.numberOfBits))), streamId, connection)
	end
end

-- Local values: numFarmlandDatas, farmlandId, _, farmlandId, data
function EnvironmentalScoreValue:writeStream(streamId, connection, farmId)
	local v28_ = 0
	for v29_, _ in pairs(self.farmlandDatas) do
		if g_farmlandManager.farmlandMapping[v29_] == farmId then
			v28_ = v28_ + 1
		end
	end
	streamWriteUIntN(streamId, v28_, g_farmlandManager.numberOfBits)
	for v30_, v31_ in pairs(self.farmlandDatas) do
		if g_farmlandManager.farmlandMapping[v30_] == farmId then
			streamWriteUIntN(streamId, v30_, g_farmlandManager.numberOfBits)
			self:writeFarmlandDataToStream(v31_, streamId, connection)
		end
	end
end

function EnvironmentalScoreValue:readFarmlandDataFromStream(data, streamId, connection) end

function EnvironmentalScoreValue:writeFarmlandDataToStream(data, streamId, connection) end

function EnvironmentalScoreValue:update(dt) end

function EnvironmentalScoreValue:getScore()
	return 0.5
end

function EnvironmentalScoreValue:overwriteGameFunctions(pfModule)
	pfModule:overwriteGameFunction(FertilizingSowingMachine, "processSowingMachineArea", function(p34_, p35_, ...)
		-- upvalues: (copy) self
		local v36_, v37_ = p34_(p35_, ...)
		if v36_ > 0 and p35_.getPFStatisticInfo ~= nil then
			local _, _, v38_ = p35_:getPFStatisticInfo()
			if v38_ ~= nil and p35_.spec_sowingMachine.useDirectPlanting then
				self:addWorkedArea(v38_, v36_, EnvironmentalScoreTillage.TYPE_DIRECT_PLANTING)
			end
		end
		return v36_, v37_
	end)
end
