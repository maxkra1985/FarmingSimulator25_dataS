-- Local values: EnvironmentalScorePH_mt
EnvironmentalScorePH = {}
EnvironmentalScorePH.COMPRESSION = 1000
local EnvironmentalScorePH_mt = Class(EnvironmentalScorePH, EnvironmentalScoreValue)

-- Upvalues: EnvironmentalScorePH_mt
-- Local values: self
function EnvironmentalScorePH.new(pfModule, customMt)
	-- upvalues: (copy) EnvironmentalScorePH_mt
	local v4_ = EnvironmentalScoreValue.new(pfModule, customMt or EnvironmentalScorePH_mt)
	v4_.xmlKey = "ph"
	return v4_
end

-- Local values: i, baseKey, phOffset, score, pHMap
function EnvironmentalScorePH:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
	if not EnvironmentalScoreTillage:superClass().loadFromXML(self, xmlFile, key, baseDirectory, configFileName, mapFilename) then
		return false
	end
	self.scoreCurve = AnimCurve.new(linearInterpolator1)
	local v11_ = 0
	while true do
		local v12_ = string.format("%s.scoreMapping.scoreValue(%d)", key, v11_)
		if not hasXMLProperty(xmlFile, v12_) then
			break
		end
		local v13_ = getXMLFloat(xmlFile, v12_ .. "#phOffset") or 0
		local v14_ = getXMLFloat(xmlFile, v12_ .. "#score") or 0
		local v15_ = g_precisionFarming.pHMap
		if v15_ ~= nil then
			v13_ = v13_ / v15_:getPhValueFromChangedStates(1)
		end
		self.scoreCurve:addKeyframe({
			v14_,
			["time"] = v13_
		})
		v11_ = v11_ + 1
	end
	return true
end

function EnvironmentalScorePH:update(dt) end

-- Local values: farmlandData, averageOffset
function EnvironmentalScorePH:getScore(farmlandId)
	local v18_ = self:getFarmlandData(farmlandId)
	if v18_.clientScore ~= nil then
		return v18_.clientScore
	end
	if v18_.harvestedArea <= 0 then
		return 0.5
	end
	local v19_ = v18_.phOffsetSum / v18_.harvestedArea * EnvironmentalScorePH.COMPRESSION
	return self.scoreCurve:get(v19_)
end

function EnvironmentalScorePH:initFarmlandData()
	return {
		["harvestedArea"] = 0,
		["phOffsetSum"] = 0,
		["pendingReset"] = false
	}
end

function EnvironmentalScorePH:loadFarmlandData(data, xmlFile, key)
	data.harvestedArea = xmlFile:getFloat(key .. "#harvestedArea", data.harvestedArea)
	data.phOffsetSum = xmlFile:getFloat(key .. "#phOffsetSum", data.phOffsetSum)
	data.pendingReset = xmlFile:getBool(key .. "#pendingReset", data.pendingReset)
end

function EnvironmentalScorePH:saveFarmlandData(data, xmlFile, key)
	xmlFile:setFloat(key .. "#harvestedArea", data.harvestedArea)
	xmlFile:setFloat(key .. "#phOffsetSum", data.phOffsetSum)
	xmlFile:setBool(key .. "#pendingReset", data.pendingReset)
end

-- Local values: score
function EnvironmentalScorePH:readFarmlandDataFromStream(data, streamId, connection)
	data.clientScore = MathUtil.round(streamReadUIntN(streamId, 8) / 255, 2)
end

-- Local values: score
function EnvironmentalScorePH:writeFarmlandDataToStream(data, streamId, connection)
	local v31_ = self:getScore(data.farmlandId)
	streamWriteUIntN(streamId, v31_ * 255, 8)
end

-- Local values: farmlandData
function EnvironmentalScorePH:onHarvestScoreReset(farmlandId)
	self:getFarmlandData(farmlandId).pendingReset = true
end

-- Local values: farmlandData
function EnvironmentalScorePH:addWorkedArea(farmlandId, area, nOffset)
	local v38_ = area / EnvironmentalScorePH.COMPRESSION
	local v39_ = nOffset / EnvironmentalScorePH.COMPRESSION
	local v40_ = self:getFarmlandData(farmlandId)
	if v40_.pendingReset then
		v40_.harvestedArea = 0
		v40_.phOffsetSum = 0
		v40_.pendingReset = false
	end
	v40_.harvestedArea = v40_.harvestedArea + v38_
	v40_.phOffsetSum = v40_.phOffsetSum + v38_ * v39_
end

function EnvironmentalScorePH:overwriteGameFunctions(pfModule)
	if g_server ~= nil then
		pfModule:overwriteGameFunction(HarvestExtension, "setLastScoringValues", function(p43_, p44_, p45_, p46_, p47_, p48_, p49_, p50_, p51_, p52_)
			-- upvalues: (copy) self
			p43_(p44_, p45_, p46_, p47_, p48_, p49_, p50_, p51_, p52_)
			if p49_ ~= nil and (p50_ ~= nil and (p45_ > 0 and p46_ ~= nil)) then
				self:addWorkedArea(p46_, p45_, p49_ - p50_)
			end
		end)
	end
end
