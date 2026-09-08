-- Local values: Subsidies_mt
Subsidies = {}
Subsidies.MOD_NAME = g_currentModName
local Subsidies_mt = Class(Subsidies)

-- Upvalues: Subsidies_mt
-- Local values: self
function Subsidies.new(pfModule, customMt)
	-- upvalues: (copy) Subsidies_mt
	local v3_ = customMt or Subsidies_mt
	local v4_ = setmetatable({}, v3_)
	v4_.moneyChangeTypeCoverCrop = MoneyType.register("other", "info_subsidiesCoverCrop", Subsidies.MOD_NAME)
	return v4_
end

-- Local values: missionInfo, mapXMLFilename, mapXMLFile
function Subsidies:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
	local v8_ = XMLFile.wrap(xmlFile)
	if g_server ~= nil then
		g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.onPeriodChanged, self)
	end
	self.coverCropBonusFruitTypes = {}
	self.infoTaskResults = {}
	self.pendingInfoTasks = {}
	self.lastBonusByFarm = {}
	self.coverCropBonusByName = {}
	self:loadCoverCropBonusFromXML(v8_, key .. ".coverCropBonus")
	local v9_ = g_currentMission.missionInfo
	local v10_ = Utils.getFilename(v9_.mapXMLFilename, g_currentMission.baseDirectory)
	local v11_ = XMLFile.load("MapXML", v10_)
	if v11_ ~= nil then
		self:loadCoverCropBonusFromXML(v11_, "map.precisionFarming.subsidies.coverCropBonus")
		v11_:delete()
	end
	return true
end

-- Local values: _, fruitTypeKey, fruitTypeName, fruitType, bonusPerHa, data
function Subsidies:loadCoverCropBonusFromXML(xmlFile, key)
	for _, v15_ in xmlFile:iterator(key .. ".fruitType") do
		local v16_ = xmlFile:getString(v15_ .. "#name")
		if v16_ == nil then
			Logging.xmlWarning(xmlFile, "Missing fruit type for cover crop bonus \'%s\'", v15_)
		else
			local v17_ = g_fruitTypeManager:getFruitTypeByName(v16_)
			if v17_ ~= nil then
				local v18_ = xmlFile:getVector(v15_ .. "#bonusPerHa", nil, 3)
				if v18_ == nil then
					Logging.xmlWarning(xmlFile, "Missing/Invalid bonusPerHa for cover crop bonus \'%s\'", v15_)
				else
					local v19_ = {
						["fruitType"] = v17_.index,
						["bonusPerHa"] = v18_
					}
					local v20_ = self.coverCropBonusFruitTypes
					table.insert(v20_, v17_)
					self.coverCropBonusByName[v17_.name] = v19_
				end
			end
		end
	end
end

function Subsidies:delete()
	g_messageCenter:unsubscribeAll(self)
end

function Subsidies:overwriteGameFunctions(pfModule) end

-- Local values: parts, fruitTypeName, foliageState, data, fruitType, ha
function Subsidies:getBonusByLabelAndArea(label, pixels)
	local v25_ = string.split(label, "|")
	local v26_ = v25_[1]
	local v27_ = v25_[2]
	local v28_ = tonumber(v27_)
	local v29_ = self.coverCropBonusByName[v26_]
	if v29_ ~= nil then
		local v30_ = g_fruitTypeManager:getFruitTypeByName(v26_)
		if v28_ > 1 and (v30_.cutState == 0 or v28_ < v30_.cutState) then
			local v31_ = MathUtil.areaToHa(pixels, g_currentMission:getFruitPixelsToSqm())
			return v29_.bonusPerHa[g_currentMission.missionInfo.economicDifficulty] * v31_
		end
	end
	return 0
end

-- Local values: infoTask, farmId, farmlandId, label, numPixels, bonus, resultFarmId, results, label, pixels, bonus, _farmId, lastBonus
function Subsidies:onFieldInfoTaskFinished(ftGrowthStatePixels, totalTouchedPixels, callbackArgs)
	local v35_ = callbackArgs.infoTask
	local v36_ = callbackArgs.farmId
	local v37_ = callbackArgs.farmlandId
	if self.infoTaskResults[v36_] == nil then
		self.infoTaskResults[v36_] = {}
	end
	g_precisionFarming.farmlandStatistics:resetStatistic(v37_, false)
	for v38_, v39_ in pairs(ftGrowthStatePixels) do
		local v40_ = self:getBonusByLabelAndArea(v38_, v39_)
		if v40_ > 0 then
			g_precisionFarming.farmlandStatistics:updateStatistic(v37_, "subsidies", v40_)
		end
		if self.infoTaskResults[v36_][v38_] == nil then
			self.infoTaskResults[v36_][v38_] = 0
		end
		self.infoTaskResults[v36_][v38_] = self.infoTaskResults[v36_][v38_] + v39_
	end
	table.removeElement(self.pendingInfoTasks, v35_)
	if #self.pendingInfoTasks == 0 then
		for v41_, v42_ in pairs(self.infoTaskResults) do
			for v43_, v44_ in pairs(v42_) do
				local v45_ = self:getBonusByLabelAndArea(v43_, v44_)
				if self.lastBonusByFarm[v41_] == nil then
					self.lastBonusByFarm[v41_] = 0
				end
				self.lastBonusByFarm[v41_] = self.lastBonusByFarm[v41_] + v45_
			end
		end
	end
	for v46_, v47_ in pairs(self.lastBonusByFarm) do
		if v47_ ~= 0 then
			g_currentMission:addMoney(v47_, v46_, self.moneyChangeTypeCoverCrop, true)
			g_currentMission:showMoneyChange(self.moneyChangeTypeCoverCrop, nil, nil, v36_)
		end
	end
end

-- Local values: _, farmland, farmlandId, field, area, infoTask
function Subsidies:onPeriodChanged(currentPeriod)
	if currentPeriod == SeasonPeriod.LATE_WINTER then
		self.lastBonusByFarm = {}
		self.infoTaskResults = {}
		for _, v50_ in ipairs(g_farmlandManager.sortedFarmlands) do
			local v51_ = v50_:getId()
			if v50_.isOwned then
				local v52_ = g_fieldManager:getFieldById(v51_)
				if v52_ ~= nil then
					local v53_ = v52_:getDensityMapPolygon()
					local v54_ = FieldGetInfoTask.new()
					v54_:setArea(v53_)
					v54_:setFruitTypes(self.coverCropBonusFruitTypes)
					v54_:setCallback(self.onFieldInfoTaskFinished, self, {
						["infoTask"] = v54_,
						["farmId"] = v50_.farmId,
						["farmlandId"] = v51_
					})
					local v55_ = self.pendingInfoTasks
					table.insert(v55_, v54_)
					v54_:enqueue()
				end
			end
		end
	end
end
