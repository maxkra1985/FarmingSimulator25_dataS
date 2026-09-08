-- Local values: EnvironmentalScoreTillage_mt
EnvironmentalScoreTillage = {}
EnvironmentalScoreTillage.TYPE_NONE = 0
EnvironmentalScoreTillage.TYPE_DEEP_CULTIVATION = 1
EnvironmentalScoreTillage.TYPE_FLAT_CULTIVATION = 2
EnvironmentalScoreTillage.TYPE_DIRECT_PLANTING = 3
local EnvironmentalScoreTillage_mt = Class(EnvironmentalScoreTillage, EnvironmentalScoreValue)

-- Upvalues: EnvironmentalScoreTillage_mt
-- Local values: self
function EnvironmentalScoreTillage.new(pfModule, customMt)
	-- upvalues: (copy) EnvironmentalScoreTillage_mt
	local v4_ = EnvironmentalScoreValue.new(pfModule, customMt or EnvironmentalScoreTillage_mt)
	v4_.xmlKey = "tillage"
	v4_.typeWeights = {
		[EnvironmentalScoreTillage.TYPE_NONE] = 0.5,
		[EnvironmentalScoreTillage.TYPE_DEEP_CULTIVATION] = 0,
		[EnvironmentalScoreTillage.TYPE_FLAT_CULTIVATION] = 0.5,
		[EnvironmentalScoreTillage.TYPE_DIRECT_PLANTING] = 1
	}
	return v4_
end

function EnvironmentalScoreTillage:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
	return EnvironmentalScoreTillage:superClass().loadFromXML(self, xmlFile, key, baseDirectory, configFileName, mapFilename) and true or false
end

function EnvironmentalScoreTillage:update(dt) end

-- Local values: farmlandData, scorePct, i
function EnvironmentalScoreTillage:getScore(farmlandId)
	local v13_ = self:getFarmlandData(farmlandId)
	if v13_.clientScore ~= nil then
		return v13_.clientScore
	end
	local v14_ = 0
	if v13_.totalFieldArea > 0 then
		for v15_ = 0, #v13_.workedAreaByType do
			local v16_ = v13_.workedAreaByType[v15_] / v13_.totalFieldArea
			v14_ = v14_ + math.min(v16_, 1) * self.typeWeights[v15_]
		end
	else
		v14_ = self.typeWeights[EnvironmentalScoreTillage.TYPE_NONE]
	end
	return math.min(v14_, 1)
end

function EnvironmentalScoreTillage:initFarmlandData()
	local v17_ = {
		["totalFieldArea"] = 0,
		["workedAreaByType"] = {
			[EnvironmentalScoreTillage.TYPE_NONE] = math.huge,
			[EnvironmentalScoreTillage.TYPE_DEEP_CULTIVATION] = 0,
			[EnvironmentalScoreTillage.TYPE_FLAT_CULTIVATION] = 0,
			[EnvironmentalScoreTillage.TYPE_DIRECT_PLANTING] = 0
		}
	}
	return v17_
end

function EnvironmentalScoreTillage:loadFarmlandData(data, xmlFile, key)
	data.totalFieldArea = xmlFile:getFloat(key .. "#totalFieldArea", data.totalFieldArea)
	data.workedAreaByType[EnvironmentalScoreTillage.TYPE_NONE] = xmlFile:getFloat(key .. "#workedAreaNone", data.workedAreaByType[EnvironmentalScoreTillage.TYPE_NONE])
	data.workedAreaByType[EnvironmentalScoreTillage.TYPE_DEEP_CULTIVATION] = xmlFile:getFloat(key .. "#workedAreaDeep", data.workedAreaByType[EnvironmentalScoreTillage.TYPE_DEEP_CULTIVATION])
	data.workedAreaByType[EnvironmentalScoreTillage.TYPE_FLAT_CULTIVATION] = xmlFile:getFloat(key .. "#workedAreaFlat", data.workedAreaByType[EnvironmentalScoreTillage.TYPE_FLAT_CULTIVATION])
	data.workedAreaByType[EnvironmentalScoreTillage.TYPE_DIRECT_PLANTING] = xmlFile:getFloat(key .. "#workedAreaDirect", data.workedAreaByType[EnvironmentalScoreTillage.TYPE_DIRECT_PLANTING])
end

function EnvironmentalScoreTillage:saveFarmlandData(data, xmlFile, key)
	if data.workedAreaByType[EnvironmentalScoreTillage.TYPE_NONE] ~= math.huge then
		xmlFile:setFloat(key .. "#totalFieldArea", data.totalFieldArea)
		xmlFile:setFloat(key .. "#workedAreaNone", data.workedAreaByType[EnvironmentalScoreTillage.TYPE_NONE])
		xmlFile:setFloat(key .. "#workedAreaDeep", data.workedAreaByType[EnvironmentalScoreTillage.TYPE_DEEP_CULTIVATION])
		xmlFile:setFloat(key .. "#workedAreaFlat", data.workedAreaByType[EnvironmentalScoreTillage.TYPE_FLAT_CULTIVATION])
		xmlFile:setFloat(key .. "#workedAreaDirect", data.workedAreaByType[EnvironmentalScoreTillage.TYPE_DIRECT_PLANTING])
	end
end

-- Local values: score
function EnvironmentalScoreTillage:readFarmlandDataFromStream(data, streamId, connection)
	data.clientScore = MathUtil.round(streamReadUIntN(streamId, 8) / 255, 2)
end

-- Local values: score
function EnvironmentalScoreTillage:writeFarmlandDataToStream(data, streamId, connection)
	local v29_ = self:getScore(data.farmlandId)
	streamWriteUIntN(streamId, v29_ * 255, 8)
end

-- Local values: farmlandData, farmland, changedHa, toRemove, changed, i, change
function EnvironmentalScoreTillage:addWorkedArea(farmlandId, area, type)
	local v34_ = self:getFarmlandData(farmlandId)
	if v34_.workedAreaByType[EnvironmentalScoreTillage.TYPE_NONE] == math.huge then
		local v35_ = g_farmlandManager:getFarmlandById(farmlandId)
		if v35_ ~= nil and v35_.totalFieldArea ~= nil then
			v34_.totalFieldArea = v35_.totalFieldArea * 10000
			v34_.workedAreaByType[EnvironmentalScoreTillage.TYPE_NONE] = v34_.totalFieldArea
		end
	end
	local v36_ = MathUtil.areaToHa(area, g_currentMission:getFruitPixelsToSqm()) * 10000
	local v37_ = v36_
	while v36_ > 0 do
		local v38_ = false
		for v39_ = 0, #v34_.workedAreaByType - 1 do
			if v39_ ~= type and (v34_.workedAreaByType[v39_] > 0 and v36_ > 0) then
				local v40_ = v37_ / (#v34_.workedAreaByType - 1)
				local v41_ = v34_.workedAreaByType
				local v42_ = v34_.workedAreaByType[v39_] - v40_
				v41_[v39_] = math.max(v42_, 0)
				v36_ = v36_ - v40_
				v38_ = true
			end
		end
		if not v38_ then
			break
		end
	end
	if v36_ > 0 then
		v34_.workedAreaByType[type] = v34_.workedAreaByType[type] - v36_
	end
	v34_.workedAreaByType[type] = v34_.workedAreaByType[type] + v37_
end

function EnvironmentalScoreTillage:overwriteGameFunctions(pfModule)
	if g_server ~= nil then
		pfModule:overwriteGameFunction(Cultivator, "processCultivatorArea", function(p45_, p46_, ...)
			-- upvalues: (copy) self
			local v47_, v48_ = p45_(p46_, ...)
			if v47_ > 0 and p46_.getPFStatisticInfo ~= nil then
				local _, _, v49_ = p46_:getPFStatisticInfo()
				if v49_ ~= nil then
					self:addWorkedArea(v49_, v47_, p46_.spec_cultivator.useDeepMode and EnvironmentalScoreTillage.TYPE_DEEP_CULTIVATION or EnvironmentalScoreTillage.TYPE_FLAT_CULTIVATION)
				end
			end
			return v47_, v48_
		end)
		pfModule:overwriteGameFunction(SowingMachine, "processSowingMachineArea", function(p50_, p51_, ...)
			-- upvalues: (copy) self
			local v52_, v53_ = p50_(p51_, ...)
			if v52_ > 0 and p51_.getPFStatisticInfo ~= nil then
				local _, _, v54_ = p51_:getPFStatisticInfo()
				if v54_ ~= nil and p51_.spec_sowingMachine.useDirectPlanting then
					self:addWorkedArea(v54_, v52_, EnvironmentalScoreTillage.TYPE_DIRECT_PLANTING)
				end
			end
			return v52_, v53_
		end)
		pfModule:overwriteGameFunction(FertilizingSowingMachine, "processSowingMachineArea", function(p55_, p56_, ...)
			-- upvalues: (copy) self
			local v57_, v58_ = p55_(p56_, ...)
			if v57_ > 0 and p56_.getPFStatisticInfo ~= nil then
				local _, _, v59_ = p56_:getPFStatisticInfo()
				if v59_ ~= nil and p56_.spec_sowingMachine.useDirectPlanting then
					self:addWorkedArea(v59_, v57_, EnvironmentalScoreTillage.TYPE_DIRECT_PLANTING)
				end
			end
			return v57_, v58_
		end)
		pfModule:overwriteGameFunction(HarvestExtension, "setLastScoringValues", function(p60_, p61_, p62_, p63_, p64_, p65_, p66_, p67_, p68_, p69_)
			-- upvalues: (copy) self
			p60_(p61_, p62_, p63_, p64_, p65_, p66_, p67_, p68_, p69_)
			if p69_ ~= nil and (p69_ == FillType.GRASS or p69_ == FillType.GRASS_WINDROW) and (p62_ > 0 and p63_ ~= nil) then
				self:addWorkedArea(p63_, p62_, EnvironmentalScoreTillage.TYPE_DIRECT_PLANTING)
			end
		end)
	end
end
