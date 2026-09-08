-- Local values: EnvironmentalScoreSoilSample_mt
EnvironmentalScoreSoilSample = {}
EnvironmentalScoreSoilSample.TYPE_NONE = 1
EnvironmentalScoreSoilSample.TYPE_SAMPLED = 2
local EnvironmentalScoreSoilSample_mt = Class(EnvironmentalScoreSoilSample, EnvironmentalScoreValue)

-- Upvalues: EnvironmentalScoreSoilSample_mt
-- Local values: self
function EnvironmentalScoreSoilSample.new(pfModule, customMt)
	-- upvalues: (copy) EnvironmentalScoreSoilSample_mt
	local v4_ = EnvironmentalScoreValue.new(pfModule, customMt or EnvironmentalScoreSoilSample_mt)
	v4_.xmlKey = "soilSample"
	v4_.typeWeights = {
		[EnvironmentalScoreSoilSample.TYPE_NONE] = 0,
		[EnvironmentalScoreSoilSample.TYPE_SAMPLED] = 1
	}
	return v4_
end

function EnvironmentalScoreSoilSample:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
	return EnvironmentalScoreTillage:superClass().loadFromXML(self, xmlFile, key, baseDirectory, configFileName, mapFilename) and true or false
end

function EnvironmentalScoreSoilSample:update(dt) end

-- Local values: farmlandData
function EnvironmentalScoreSoilSample:getScore(farmlandId)
	local v13_ = self:getFarmlandData(farmlandId)
	if v13_.clientScore == nil then
		return v13_.samplePercentage < 0 and 0.5 or v13_.samplePercentage
	else
		return v13_.clientScore
	end
end

function EnvironmentalScoreSoilSample:initFarmlandData()
	return {
		["samplePercentage"] = -1
	}
end

function EnvironmentalScoreSoilSample:loadFarmlandData(data, xmlFile, key)
	data.samplePercentage = xmlFile:getFloat(key .. "#samplePercentage", data.samplePercentage)
end

function EnvironmentalScoreSoilSample:saveFarmlandData(data, xmlFile, key)
	xmlFile:setFloat(key .. "#samplePercentage", data.samplePercentage)
end

-- Local values: score
function EnvironmentalScoreSoilSample:readFarmlandDataFromStream(data, streamId, connection)
	data.clientScore = MathUtil.round(streamReadUIntN(streamId, 8) / 255, 2)
end

-- Local values: score
function EnvironmentalScoreSoilSample:writeFarmlandDataToStream(data, streamId, connection)
	local v25_ = self:getScore(data.farmlandId)
	streamWriteUIntN(streamId, v25_ * 255, 8)
end

function EnvironmentalScoreSoilSample:onHarvestScoreReset(farmlandId)
	self:updateFarmlandSampleState(farmlandId)
end

-- Local values: farmlandData, percentage
function EnvironmentalScoreSoilSample:updateFarmlandSampleState(farmlandId)
	local v30_ = self:getFarmlandData(farmlandId)
	local v31_ = self.pfModule.coverMap:getFarmlandSampleState(farmlandId)
	v30_.samplePercentage = math.clamp(v31_, 0, 1)
end

-- Local values: farmlandId, percentage, farmlandData
function EnvironmentalScoreSoilSample:onFarmlandSampleStatesFinished(sampledPercentageByFarmlandId)
	for v34_, v35_ in pairs(sampledPercentageByFarmlandId) do
		self:getFarmlandData(v34_).samplePercentage = math.clamp(v35_, 0, 1)
	end
end

function EnvironmentalScoreSoilSample:overwriteGameFunctions(pfModule)
	if g_server ~= nil then
		pfModule:overwriteGameFunction(SoilSampler, "processSoilSampling", function(p38_, p39_, ...)
			-- upvalues: (copy) self
			p38_(p39_, ...)
			local v40_ = p39_[SoilSampler.SPEC_TABLE_NAME]
			if v40_.coverMap ~= nil then
				local v41_, _, v42_ = getWorldTranslation(v40_.samplingNode)
				self:updateFarmlandSampleState((g_farmlandManager:getFarmlandIdAtWorldPosition(v41_, v42_)))
			end
		end)
		pfModule:overwriteGameFunction(CoverMap, "onCoverUpdateFinished", function(p43_, p44_, p45_, p46_, p47_)
			-- upvalues: (copy) self
			p43_(p44_, p45_, p46_, p47_)
			self:onFarmlandSampleStatesFinished(p47_)
		end)
		pfModule:overwriteGameFunction(CoverMap, "analyseArea", function(p48_, p49_, p50_, p51_, p52_, p53_)
			-- upvalues: (copy) self
			p48_(p49_, p50_, p51_, p52_, p53_)
			if p53_ ~= nil then
				self:updateFarmlandSampleState(p53_)
			end
		end)
	end
end
