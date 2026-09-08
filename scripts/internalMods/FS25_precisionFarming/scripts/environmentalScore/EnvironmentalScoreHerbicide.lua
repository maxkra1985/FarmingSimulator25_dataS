-- Local values: EnvironmentalScoreHerbicide_mt
EnvironmentalScoreHerbicide = {}
EnvironmentalScoreHerbicide.TYPE_SPOT_SPRAY = 1
EnvironmentalScoreHerbicide.TYPE_FULL_SPRAY = 2
EnvironmentalScoreHerbicide.TYPE_MECHANICAL = 3
local EnvironmentalScoreHerbicide_mt = Class(EnvironmentalScoreHerbicide, EnvironmentalScoreValue)

-- Upvalues: EnvironmentalScoreHerbicide_mt
-- Local values: self
function EnvironmentalScoreHerbicide.new(pfModule, customMt)
	-- upvalues: (copy) EnvironmentalScoreHerbicide_mt
	local v4_ = EnvironmentalScoreValue.new(pfModule, customMt or EnvironmentalScoreHerbicide_mt)
	v4_.xmlKey = "herbicide"
	return v4_
end

function EnvironmentalScoreHerbicide:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
	return EnvironmentalScoreTillage:superClass().loadFromXML(self, xmlFile, key, baseDirectory, configFileName, mapFilename) and true or false
end

function EnvironmentalScoreHerbicide:update(dt) end

-- Local values: farmlandData, sum, score
function EnvironmentalScoreHerbicide:getScore(farmlandId)
	local v13_ = self:getFarmlandData(farmlandId)
	if v13_.clientScore ~= nil then
		return v13_.clientScore
	end
	local v14_ = 0 + v13_.areaByType[1] + v13_.areaByType[2] + v13_.areaByType[3]
	if v14_ == 0 then
		return 0.5
	end
	local v15_ = 0 + v13_.areaByType[EnvironmentalScoreHerbicide.TYPE_SPOT_SPRAY] / v14_ * 1 + v13_.areaByType[EnvironmentalScoreHerbicide.TYPE_FULL_SPRAY] / v14_ * 0.6 + v13_.areaByType[EnvironmentalScoreHerbicide.TYPE_MECHANICAL] / v14_ * 0.75
	return math.clamp(v15_, 0, 1)
end

function EnvironmentalScoreHerbicide:initFarmlandData()
	local v16_ = {
		["areaByType"] = {
			[EnvironmentalScoreHerbicide.TYPE_SPOT_SPRAY] = 0,
			[EnvironmentalScoreHerbicide.TYPE_FULL_SPRAY] = 0,
			[EnvironmentalScoreHerbicide.TYPE_MECHANICAL] = 0
		},
		["pendingReset"] = false
	}
	return v16_
end

function EnvironmentalScoreHerbicide:loadFarmlandData(data, xmlFile, key)
	data.areaByType[EnvironmentalScoreHerbicide.TYPE_SPOT_SPRAY] = xmlFile:getFloat(key .. "#spotSpray", data.areaByType[EnvironmentalScoreHerbicide.TYPE_SPOT_SPRAY])
	data.areaByType[EnvironmentalScoreHerbicide.TYPE_FULL_SPRAY] = xmlFile:getFloat(key .. "#fullSpray", data.areaByType[EnvironmentalScoreHerbicide.TYPE_FULL_SPRAY])
	data.areaByType[EnvironmentalScoreHerbicide.TYPE_MECHANICAL] = xmlFile:getFloat(key .. "#mechanical", data.areaByType[EnvironmentalScoreHerbicide.TYPE_MECHANICAL])
	data.pendingReset = xmlFile:getBool(key .. "#pendingReset", data.pendingReset)
end

function EnvironmentalScoreHerbicide:saveFarmlandData(data, xmlFile, key)
	xmlFile:setFloat(key .. "#spotSpray", data.areaByType[EnvironmentalScoreHerbicide.TYPE_SPOT_SPRAY])
	xmlFile:setFloat(key .. "#fullSpray", data.areaByType[EnvironmentalScoreHerbicide.TYPE_FULL_SPRAY])
	xmlFile:setFloat(key .. "#mechanical", data.areaByType[EnvironmentalScoreHerbicide.TYPE_MECHANICAL])
	xmlFile:setBool(key .. "#pendingReset", data.pendingReset)
end

-- Local values: score
function EnvironmentalScoreHerbicide:readFarmlandDataFromStream(data, streamId, connection)
	data.clientScore = MathUtil.round(streamReadUIntN(streamId, 8) / 255, 2)
end

-- Local values: score
function EnvironmentalScoreHerbicide:writeFarmlandDataToStream(data, streamId, connection)
	local v28_ = self:getScore(data.farmlandId)
	streamWriteUIntN(streamId, v28_ * 255, 8)
end

-- Local values: farmlandData
function EnvironmentalScoreHerbicide:onHarvestScoreReset(farmlandId)
	self:getFarmlandData(farmlandId).pendingReset = true
end

-- Local values: farmlandData
function EnvironmentalScoreHerbicide:addWorkedArea(farmlandId, area, type)
	local v35_ = self:getFarmlandData(farmlandId)
	if v35_.pendingReset then
		v35_.areaByType[EnvironmentalScoreHerbicide.TYPE_SPOT_SPRAY] = 0
		v35_.areaByType[EnvironmentalScoreHerbicide.TYPE_FULL_SPRAY] = 0
		v35_.areaByType[EnvironmentalScoreHerbicide.TYPE_MECHANICAL] = 0
		v35_.pendingReset = false
	end
	v35_.areaByType[type] = v35_.areaByType[type] + area
end

function EnvironmentalScoreHerbicide:overwriteGameFunctions(pfModule)
	if g_server ~= nil then
		pfModule:overwriteGameFunction(Sprayer, "processSprayerArea", function(p38_, p39_, p40_, p41_)
			-- upvalues: (copy) self
			local v42_, v43_ = p38_(p39_, p40_, p41_)
			if v42_ > 0 and p39_.spec_sprayer.workAreaParameters.sprayFillType == FillType.HERBICIDE then
				local v44_, _, v45_ = getWorldTranslation(p39_.rootNode)
				local v46_ = g_farmlandManager:getFarmlandIdAtWorldPosition(v44_, v45_)
				if v46_ ~= nil then
					local _ = p39_[WeedSpotSpray.SPEC_TABLE_NAME]
					if p39_.getIsSpotSprayEnabled ~= nil and p39_:getIsSpotSprayEnabled() then
						self:addWorkedArea(v46_, v42_, EnvironmentalScoreHerbicide.TYPE_SPOT_SPRAY)
						return v42_, v43_
					end
					self:addWorkedArea(v46_, v42_, EnvironmentalScoreHerbicide.TYPE_FULL_SPRAY)
				end
			end
			return v42_, v43_
		end)
		pfModule:overwriteGameFunction(Weeder, "processWeederArea", function(p47_, p48_, p49_, p50_)
			-- upvalues: (copy) self
			local v51_, v52_ = p47_(p48_, p49_, p50_)
			if v51_ > 0 then
				local v53_, _, v54_ = getWorldTranslation(p48_.rootNode)
				local v55_ = g_farmlandManager:getFarmlandIdAtWorldPosition(v53_, v54_)
				if v55_ ~= nil then
					self:addWorkedArea(v55_, v51_, EnvironmentalScoreHerbicide.TYPE_MECHANICAL)
				end
			end
			return v51_, v52_
		end)
		pfModule:overwriteGameFunction(HarvestExtension, "setLastScoringValues", function(p56_, p57_, p58_, p59_, p60_, p61_, p62_, p63_, p64_, p65_)
			-- upvalues: (copy) self
			p56_(p57_, p58_, p59_, p60_, p61_, p62_, p63_, p64_, p65_)
			if p65_ ~= nil and (p65_ == FillType.GRASS or p65_ == FillType.GRASS_WINDROW) and (p58_ > 0 and p59_ ~= nil) then
				self:addWorkedArea(p59_, p58_, EnvironmentalScoreHerbicide.TYPE_SPOT_SPRAY)
			end
		end)
	end
end
