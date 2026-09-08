-- Local values: EnvironmentalScoreNitrogen_mt
EnvironmentalScoreNitrogen = {}
EnvironmentalScoreNitrogen.COMPRESSION = 1000
local EnvironmentalScoreNitrogen_mt = Class(EnvironmentalScoreNitrogen, EnvironmentalScoreValue)

-- Upvalues: EnvironmentalScoreNitrogen_mt
-- Local values: self
function EnvironmentalScoreNitrogen.new(pfModule, customMt)
	-- upvalues: (copy) EnvironmentalScoreNitrogen_mt
	local v4_ = EnvironmentalScoreValue.new(pfModule, customMt or EnvironmentalScoreNitrogen_mt)
	v4_.xmlKey = "nitrogen"
	return v4_
end

-- Local values: i, baseKey, nOffset, score, nitrogenMap
function EnvironmentalScoreNitrogen:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
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
		local v13_ = getXMLFloat(xmlFile, v12_ .. "#nOffset") or 0
		local v14_ = getXMLFloat(xmlFile, v12_ .. "#score") or 0
		local v15_ = g_precisionFarming.nitrogenMap
		if v15_ ~= nil then
			v13_ = v13_ / v15_:getNitrogenFromChangedStates(1)
		end
		self.scoreCurve:addKeyframe({
			v14_,
			["time"] = v13_
		})
		v11_ = v11_ + 1
	end
	return true
end

function EnvironmentalScoreNitrogen:update(dt) end

-- Local values: farmlandData, averageOffset
function EnvironmentalScoreNitrogen:getScore(farmlandId)
	local v18_ = self:getFarmlandData(farmlandId)
	if v18_.clientScore ~= nil then
		return v18_.clientScore
	end
	if v18_.harvestedArea <= 0 then
		return 0.5
	end
	local v19_ = v18_.nOffsetSum / v18_.harvestedArea * EnvironmentalScoreNitrogen.COMPRESSION
	return self.scoreCurve:get(v19_)
end

function EnvironmentalScoreNitrogen:initFarmlandData()
	return {
		["harvestedArea"] = 0,
		["nOffsetSum"] = 0,
		["pendingReset"] = false
	}
end

function EnvironmentalScoreNitrogen:loadFarmlandData(data, xmlFile, key)
	data.harvestedArea = xmlFile:getFloat(key .. "#harvestedArea", data.harvestedArea)
	data.nOffsetSum = xmlFile:getFloat(key .. "#nOffsetSum", data.nOffsetSum)
	data.pendingReset = xmlFile:getBool(key .. "#pendingReset", data.pendingReset)
end

function EnvironmentalScoreNitrogen:saveFarmlandData(data, xmlFile, key)
	xmlFile:setFloat(key .. "#harvestedArea", data.harvestedArea)
	xmlFile:setFloat(key .. "#nOffsetSum", data.nOffsetSum)
	xmlFile:setBool(key .. "#pendingReset", data.pendingReset)
end

-- Local values: score
function EnvironmentalScoreNitrogen:readFarmlandDataFromStream(data, streamId, connection)
	data.clientScore = MathUtil.round(streamReadUIntN(streamId, 8) / 255, 2)
end

-- Local values: score
function EnvironmentalScoreNitrogen:writeFarmlandDataToStream(data, streamId, connection)
	local v31_ = self:getScore(data.farmlandId)
	streamWriteUIntN(streamId, v31_ * 255, 8)
end

-- Local values: farmlandData
function EnvironmentalScoreNitrogen:onHarvestScoreReset(farmlandId)
	self:getFarmlandData(farmlandId).pendingReset = true
end

-- Local values: farmlandData
function EnvironmentalScoreNitrogen:addWorkedArea(farmlandId, area, nOffset)
	local v38_ = area / EnvironmentalScoreNitrogen.COMPRESSION
	local v39_ = nOffset / EnvironmentalScoreNitrogen.COMPRESSION
	local v40_ = self:getFarmlandData(farmlandId)
	if v40_.pendingReset then
		v40_.harvestedArea = 0
		v40_.nOffsetSum = 0
		v40_.pendingReset = false
	end
	v40_.harvestedArea = v40_.harvestedArea + v38_
	v40_.nOffsetSum = v40_.nOffsetSum + v38_ * v39_
end

function EnvironmentalScoreNitrogen:overwriteGameFunctions(pfModule)
	if g_server ~= nil then
		pfModule:overwriteGameFunction(HarvestExtension, "setLastScoringValues", function(p43_, p44_, p45_, p46_, p47_, p48_, p49_, p50_, p51_, p52_)
			-- upvalues: (copy) self
			p43_(p44_, p45_, p46_, p47_, p48_, p49_, p50_, p51_, p52_)
			if p47_ ~= nil and (p48_ ~= nil and (p45_ > 0 and p46_ ~= nil)) then
				local v53_ = p47_ - p48_
				if p51_ then
					v53_ = math.min(v53_, 0)
				end
				self:addWorkedArea(p46_, p45_, v53_)
			end
		end)
	end
end
