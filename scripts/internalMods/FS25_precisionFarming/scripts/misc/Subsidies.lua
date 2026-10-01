Subsidies = {}
Subsidies.MOD_NAME = g_currentModName
local Subsidies_mt = Class(Subsidies)
function Subsidies.new(pfModule, customMt)
	local self = setmetatable({}, customMt or Subsidies_mt)
	self.moneyChangeTypeCoverCrop = MoneyType.register("other", "info_subsidiesCoverCrop", Subsidies.MOD_NAME)
	return self
end
function Subsidies:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
	xmlFile = XMLFile.wrap(xmlFile)
	if g_server ~= nil then
		g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.onPeriodChanged, self)
	end
	self.coverCropBonusFruitTypes = {}
	self.infoTaskResults = {}
	self.pendingInfoTasks = {}
	self.lastBonusByFarm = {}
	self.coverCropBonusByName = {}
	self:loadCoverCropBonusFromXML(xmlFile, key .. ".coverCropBonus")
	local missionInfo = g_currentMission.missionInfo
	local mapXMLFilename = Utils.getFilename(missionInfo.mapXMLFilename, g_currentMission.baseDirectory)
	local mapXMLFile = XMLFile.load("MapXML", mapXMLFilename)
	if mapXMLFile ~= nil then
		self:loadCoverCropBonusFromXML(mapXMLFile, "map.precisionFarming.subsidies.coverCropBonus")
		mapXMLFile:delete()
	end
	return true
end
function Subsidies:loadCoverCropBonusFromXML(xmlFile, key)
	for _, fruitTypeKey in xmlFile:iterator(key .. ".fruitType") do
		local fruitTypeName = xmlFile:getString(fruitTypeKey .. "#name")
		if fruitTypeName ~= nil then
			local fruitType = g_fruitTypeManager:getFruitTypeByName(fruitTypeName)
			if fruitType == nil then
				continue
			end
			local bonusPerHa = xmlFile:getVector(fruitTypeKey .. "#bonusPerHa", nil, 3)
			if bonusPerHa ~= nil then
				local data = { ["fruitType"] = fruitType.index, ["bonusPerHa"] = bonusPerHa }
				table.insert(self.coverCropBonusFruitTypes, fruitType)
				self.coverCropBonusByName[fruitType.name] = data
			else
				Logging.xmlWarning(xmlFile, "Missing/Invalid bonusPerHa for cover crop bonus '%s'", fruitTypeKey)
			end
		else
			Logging.xmlWarning(xmlFile, "Missing fruit type for cover crop bonus '%s'", fruitTypeKey)
		end
	end
end
function Subsidies:delete()
	g_messageCenter:unsubscribeAll(self)
end
function Subsidies:overwriteGameFunctions(pfModule) end
function Subsidies:getBonusByLabelAndArea(label, pixels)
	local parts = string.split(label, "|")
	local fruitTypeName = parts[1]
	local foliageState = tonumber(parts[2])
	local data = self.coverCropBonusByName[fruitTypeName]
	if data ~= nil then
		local fruitType = g_fruitTypeManager:getFruitTypeByName(fruitTypeName)
		if 1 < foliageState and (fruitType.cutState == 0 or foliageState < fruitType.cutState) then
			local ha = MathUtil.areaToHa(pixels, g_currentMission:getFruitPixelsToSqm())
			return data.bonusPerHa[g_currentMission.missionInfo.economicDifficulty] * ha
		end
	end
	return 0
end
function Subsidies:onFieldInfoTaskFinished(ftGrowthStatePixels, totalTouchedPixels, callbackArgs)
	local infoTask = callbackArgs.infoTask
	local farmId = callbackArgs.farmId
	local farmlandId = callbackArgs.farmlandId
	if self.infoTaskResults[farmId] == nil then
		self.infoTaskResults[farmId] = {}
	end
	g_precisionFarming.farmlandStatistics:resetStatistic(farmlandId, false)
	for label, numPixels in pairs(ftGrowthStatePixels) do
		local bonus = self:getBonusByLabelAndArea(label, numPixels)
		if 0 < bonus then
			g_precisionFarming.farmlandStatistics:updateStatistic(farmlandId, "subsidies", bonus)
		end
		if self.infoTaskResults[farmId][label] == nil then
			self.infoTaskResults[farmId][label] = 0
		end
		self.infoTaskResults[farmId][label] = self.infoTaskResults[farmId][label] + numPixels
	end
	table.removeElement(self.pendingInfoTasks, infoTask)
	if #self.pendingInfoTasks == 0 then
		for resultFarmId, results in pairs(self.infoTaskResults) do
			for label, pixels in pairs(results) do
				local bonus = self:getBonusByLabelAndArea(label, pixels)
				if self.lastBonusByFarm[resultFarmId] == nil then
					self.lastBonusByFarm[resultFarmId] = 0
				end
				self.lastBonusByFarm[resultFarmId] = self.lastBonusByFarm[resultFarmId] + bonus
			end
		end
	end
	for _farmId, lastBonus in pairs(self.lastBonusByFarm) do
		if lastBonus == 0 then
			continue
		end
		g_currentMission:addMoney(lastBonus, _farmId, self.moneyChangeTypeCoverCrop, true)
		g_currentMission:showMoneyChange(self.moneyChangeTypeCoverCrop, nil, nil, farmId)
	end
end
function Subsidies:onPeriodChanged(currentPeriod)
	if currentPeriod == SeasonPeriod.LATE_WINTER then
		self.lastBonusByFarm = {}
		self.infoTaskResults = {}
		for _, farmland in ipairs(g_farmlandManager.sortedFarmlands) do
			local farmlandId = farmland:getId()
			if farmland.isOwned then
				local field = g_fieldManager:getFieldById(farmlandId)
				if field == nil then
					continue
				end
				local area = field:getDensityMapPolygon()
				local infoTask = FieldGetInfoTask.new()
				infoTask:setArea(area)
				infoTask:setFruitTypes(self.coverCropBonusFruitTypes)
				infoTask:setCallback(self.onFieldInfoTaskFinished, self, { infoTask = infoTask, farmlandId = farmlandId, farmId = farmland.farmId })
				table.insert(self.pendingInfoTasks, infoTask)
				infoTask:enqueue()
			end
		end
	end
end
