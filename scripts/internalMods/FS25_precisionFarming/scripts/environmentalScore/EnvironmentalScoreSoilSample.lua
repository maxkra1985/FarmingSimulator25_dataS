EnvironmentalScoreSoilSample = {}
EnvironmentalScoreSoilSample.TYPE_NONE = 1
EnvironmentalScoreSoilSample.TYPE_SAMPLED = 2
local EnvironmentalScoreSoilSample_mt = Class(EnvironmentalScoreSoilSample, EnvironmentalScoreValue)
function EnvironmentalScoreSoilSample.new(pfModule, customMt)
	local self = EnvironmentalScoreValue.new(pfModule, customMt or EnvironmentalScoreSoilSample_mt)
	self.xmlKey = "soilSample"
	self.typeWeights = { [EnvironmentalScoreSoilSample.TYPE_NONE] = 0, [EnvironmentalScoreSoilSample.TYPE_SAMPLED] = 1 }
	return self
end
function EnvironmentalScoreSoilSample:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
	if not EnvironmentalScoreTillage:superClass().loadFromXML(self, xmlFile, key, baseDirectory, configFileName, mapFilename) then
		return false
	else
		return true
	end
end
function EnvironmentalScoreSoilSample:update(dt) end
function EnvironmentalScoreSoilSample:getScore(farmlandId)
	local farmlandData = self:getFarmlandData(farmlandId)
	if farmlandData.clientScore ~= nil then
		return farmlandData.clientScore
	elseif farmlandData.samplePercentage < 0 then
		return 0.5
	else
		return farmlandData.samplePercentage
	end
end
function EnvironmentalScoreSoilSample:initFarmlandData()
	return { samplePercentage = -1 }
end
function EnvironmentalScoreSoilSample:loadFarmlandData(data, xmlFile, key)
	data.samplePercentage = xmlFile:getFloat(key .. "#samplePercentage", data.samplePercentage)
end
function EnvironmentalScoreSoilSample:saveFarmlandData(data, xmlFile, key)
	xmlFile:setFloat(key .. "#samplePercentage", data.samplePercentage)
end
function EnvironmentalScoreSoilSample:readFarmlandDataFromStream(data, streamId, connection)
	local score = MathUtil.round(streamReadUIntN(streamId, 8) / 255, 2)
	data.clientScore = score
end
function EnvironmentalScoreSoilSample:writeFarmlandDataToStream(data, streamId, connection)
	local score = self:getScore(data.farmlandId)
	streamWriteUIntN(streamId, score * 255, 8)
end
function EnvironmentalScoreSoilSample:onHarvestScoreReset(farmlandId)
	self:updateFarmlandSampleState(farmlandId)
end
function EnvironmentalScoreSoilSample:updateFarmlandSampleState(farmlandId)
	local farmlandData = self:getFarmlandData(farmlandId)
	local percentage = self.pfModule.coverMap:getFarmlandSampleState(farmlandId)
	farmlandData.samplePercentage = math.clamp(percentage, 0, 1)
end
function EnvironmentalScoreSoilSample:onFarmlandSampleStatesFinished(sampledPercentageByFarmlandId)
	for farmlandId, percentage in pairs(sampledPercentageByFarmlandId) do
		local farmlandData = self:getFarmlandData(farmlandId)
		farmlandData.samplePercentage = math.clamp(percentage, 0, 1)
	end
end
function EnvironmentalScoreSoilSample:overwriteGameFunctions(pfModule)
	if g_server ~= nil then
		pfModule:overwriteGameFunction(SoilSampler, "processSoilSampling", function(superFunc, vehicle, ...)
			superFunc(vehicle, ...)
			local spec = vehicle[SoilSampler.SPEC_TABLE_NAME]
			if spec.coverMap ~= nil then
				local x, _, z = getWorldTranslation(spec.samplingNode)
				local farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition(x, z)
				self:updateFarmlandSampleState(farmlandId)
			end
		end)
		pfModule:overwriteGameFunction(CoverMap, "onCoverUpdateFinished", function(superFunc, coverMap, farmId, farmlandId, sampledPercentageByFarmlandId)
			superFunc(coverMap, farmId, farmlandId, sampledPercentageByFarmlandId)
			self:onFarmlandSampleStatesFinished(sampledPercentageByFarmlandId)
		end)
		pfModule:overwriteGameFunction(CoverMap, "analyseArea", function(superFunc, coverMap, densityMapShape, state, farmId, farmlandId)
			superFunc(coverMap, densityMapShape, state, farmId, farmlandId)
			if farmlandId ~= nil then
				self:updateFarmlandSampleState(farmlandId)
			end
		end)
	end
end
