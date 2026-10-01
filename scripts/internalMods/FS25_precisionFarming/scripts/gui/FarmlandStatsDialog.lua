FarmlandStatsDialog = {}
FarmlandStatsDialog.MOD_NAME = g_currentModName
FarmlandStatsDialog.MOD_DIR = g_currentModDirectory
local FarmlandStatsDialog_mt = Class(FarmlandStatsDialog, MessageDialog)
function FarmlandStatsDialog.register()
	local instance = FarmlandStatsDialog.new()
	g_gui:loadGui(FarmlandStatsDialog.MOD_DIR .. "gui/FarmlandStatsDialog.xml", "FarmlandStatsDialog", instance)
	FarmlandStatsDialog.INSTANCE = instance
end
function FarmlandStatsDialog.new(target, custom_mt)
	local self = FarmlandStatsDialog:superClass().new(target, custom_mt or FarmlandStatsDialog_mt)
	self.farmlandId = 0
	self.fieldNumber = 0
	self.fieldArea = 0
	self.statistic = nil
	self.showTotal = false
	return self
end
function FarmlandStatsDialog:setData(farmlandId, fieldNumber, fieldArea, statistic)
	self.farmlandId = farmlandId
	self.fieldNumber = fieldNumber
	self.fieldArea = fieldArea
	self.statistic = statistic
	local farmlandStatistics = g_precisionFarming.farmlandStatistics
	local text = nil
	if fieldNumber ~= 0 then
		text = string.format(g_i18n:getText("ui_economicAnalysisHeaderField"), fieldNumber, fieldArea)
	else
		text = string.format(g_i18n:getText("ui_economicAnalysisHeaderAdditionalField"), fieldArea)
	end
	self.economicAnalysisHeaderField:setText(text)
	self.economicAnalysisHeaderValues:setText(g_i18n:getText(self.showTotal and "ui_economicAnalysisHeaderValuesTotal" or "ui_economicAnalysisHeaderValuesPeriod"))
	local setChangePercentageElement = function(element, value, valueRegular, cost, inversePercentageColor)
		local pct = 0
		if value ~= valueRegular then
			local direction = nil
			local pctText = ""
			if valueRegular ~= 0 then
				pct = math.floor(-100 * (1 - value / valueRegular))
				if pct ~= 0 then
					local str = pct <= 0 and "(%d%%)" or "(+%d%%)"
					pctText = string.format(str, pct)
					direction = 0 < pct
				end
			elseif math.floor(cost or 0) ~= 0 then
				pctText = string.format("(%s%s)", 0 < cost and "+" or "", g_i18n:formatMoney(cost))
				pct = 100
				direction = 0 < cost
			else
				pctText = ""
			end
			if inversePercentageColor == true then
				direction = not direction
			end
			element:applyProfile(direction and "farmlandStatsDialogChangeNeg" or "farmlandStatsDialogChangePos", true)
			element:setText(pctText)
			return pct
		else
			element:setText("")
			return pct
		end
	end
	local buildValueDisplay = function(statistic, index, showTotal, name, nameRegular, fillTypeIndex, showWeight, showValue, showCost, showDetailedLiters, unitStr, cost, weight, inversePercentageColor)
		if unitStr == nil then
			unitStr = " l"
		elseif 0 < unitStr:len() then
			unitStr = " " .. unitStr
		end
		local value = statistic:getValue(showTotal, name)
		local valueRegular = value
		if nameRegular ~= nil then
			if type(nameRegular) == "string" then
				valueRegular = statistic:getValue(showTotal, nameRegular)
			elseif type(nameRegular) == "number" then
				valueRegular = nameRegular
			end
		end
		cost = cost or farmlandStatistics:getFillLevelPrice(value, fillTypeIndex)
		weight = weight or farmlandStatistics:getFillLevelWeight(value, fillTypeIndex)
		if showValue then
			local valueText = "%d" .. unitStr
			if showDetailedLiters then
				valueText = "%.1f" .. unitStr
			else
				value = MathUtil.round(value)
			end
			if showWeight then
				valueText = valueText .. " | %.1f t"
			end
			self.statAmountText[index]:setText(string.format(valueText, value, weight))
		else
			self.statAmountText[index]:setText("")
		end
		if showCost == nil or showCost then
			self.statCostText[index]:setText(g_i18n:formatMoney(cost))
		else
			self.statCostText[index]:setText("")
		end
		local percentageIncrease = setChangePercentageElement(self.statPercentageText[index], value, valueRegular, cost, inversePercentageColor)
		if showCost == false then
			percentageIncrease = 0
		end
		return math.max(math.floor(cost)), math.max(math.floor(cost * (-percentageIncrease * 0.01 + 1)), 0)
	end
	local totalCosts = 0
	local totalRegularCosts = 0
	local costs = nil
	local regularCosts = nil
	costs, regularCosts = buildValueDisplay(statistic, 1, self.showTotal, "numSoilSamples", 0, "soilSamples", false, true, true, false, "", statistic:getValue(self.showTotal, "soilSampleCosts"))
	totalCosts = totalCosts + costs
	totalRegularCosts = totalRegularCosts + regularCosts
	costs, regularCosts = buildValueDisplay(statistic, 2, self.showTotal, "usedLime", "usedLimeRegular", FillType.LIME, true, true, true, false)
	totalCosts = totalCosts + costs
	totalRegularCosts = totalRegularCosts + regularCosts
	costs, regularCosts = buildValueDisplay(statistic, 3, self.showTotal, "usedMineralFertilizer", "usedMineralFertilizerRegular", FillType.FERTILIZER, true, true, true, false)
	totalCosts = totalCosts + costs
	totalRegularCosts = totalRegularCosts + regularCosts
	costs, regularCosts = buildValueDisplay(statistic, 4, self.showTotal, "usedLiquidFertilizer", "usedLiquidFertilizerRegular", FillType.LIQUIDFERTILIZER, false, true, true, false)
	totalCosts = totalCosts + costs
	totalRegularCosts = totalRegularCosts + regularCosts
	buildValueDisplay(statistic, 5, self.showTotal, "usedManure", "usedManureRegular", FillType.MANURE, true, true, false, false)
	buildValueDisplay(statistic, 6, self.showTotal, "usedLiquidManure", "usedLiquidManureRegular", FillType.LIQUIDMANURE, false, true, false, false)
	costs, regularCosts = buildValueDisplay(statistic, 7, self.showTotal, "usedSeeds", "usedSeedsRegular", FillType.SEEDS, true, true, true, false)
	totalCosts = totalCosts + costs
	totalRegularCosts = totalRegularCosts + regularCosts
	costs, regularCosts = buildValueDisplay(statistic, 8, self.showTotal, "usedHerbicide", "usedHerbicideRegular", FillType.HERBICIDE, false, true, true, false)
	totalCosts = totalCosts + costs
	totalRegularCosts = totalRegularCosts + regularCosts
	costs, regularCosts = buildValueDisplay(statistic, 9, self.showTotal, "usedFuel", nil, FillType.DIESEL, false, true, true, true)
	totalCosts = totalCosts + costs
	totalRegularCosts = totalRegularCosts + regularCosts
	costs, regularCosts = buildValueDisplay(statistic, 10, self.showTotal, "vehicleCosts", nil, 0, false, false, true, false)
	totalCosts = totalCosts + costs
	totalRegularCosts = totalRegularCosts + regularCosts
	costs, regularCosts = buildValueDisplay(statistic, 11, self.showTotal, "helperCosts", nil, 0, false, false, true, false)
	totalCosts = totalCosts + costs
	totalRegularCosts = totalRegularCosts + regularCosts
	local subsidies = statistic:getValue(self.showTotal, "subsidies")
	buildValueDisplay(statistic, 12, self.showTotal, subsidies, 0, 0, false, false, true, false, nil, subsidies, 0, false)
	local yieldWeight = statistic:getValue(self.showTotal, "yieldWeight")
	local yieldBestPrice = statistic:getValue(self.showTotal, "yieldBestPrice")
	buildValueDisplay(statistic, 13, self.showTotal, "yield", "yieldRegular", 0, true, true, true, false, nil, yieldBestPrice, yieldWeight, true)
	local earningsIncreasePct = statistic:getValue(self.showTotal, "yield") / math.max(statistic:getValue(self.showTotal, "yieldRegular"), 0.01)
	local earningsIncrease = 0
	if earningsIncreasePct ~= 0 then
		earningsIncrease = yieldBestPrice - yieldBestPrice / earningsIncreasePct
	end
	local costIncrease = totalRegularCosts - totalCosts
	setChangePercentageElement(self.statTotalCostPercentageText, totalCosts, 0, math.abs(costIncrease), false)
	setChangePercentageElement(self.statTotalEarningsPercentageText, yieldBestPrice, 0, earningsIncrease, true)
	setChangePercentageElement(self.statTotalPercentageText, yieldBestPrice, 0, costIncrease + earningsIncrease, true)
	local totalEarnings = yieldBestPrice + subsidies
	local result = totalEarnings - totalCosts
	self.statTotalCostText:setText(g_i18n:formatMoney(totalCosts))
	self.statTotalEarningsText:setText(g_i18n:formatMoney(totalEarnings))
	self.statTotalText:setText(g_i18n:formatMoney(result))
end
function FarmlandStatsDialog:onSwitchMode()
	self.showTotal = not self.showTotal
	if self.farmlandId ~= 0 then
		self:setData(self.farmlandId, self.fieldNumber, self.fieldArea, self.statistic)
	end
end
function FarmlandStatsDialog:onReset()
	if self.farmlandId ~= 0 then
		local farmlandStatistics = g_precisionFarming.farmlandStatistics
		farmlandStatistics:resetStatistic(self.farmlandId, false)
		self:setData(self.farmlandId, self.fieldNumber, self.fieldArea, self.statistic)
		if g_server == nil and g_client ~= nil then
			g_client:getServerConnection():sendEvent(FarmlandStatisticsResetEvent.new(self.farmlandId))
		end
	end
end
function FarmlandStatsDialog:onCloseButton()
	self:close()
	self.farmlandId = 0
	self.fieldNumber = 0
	self.fieldArea = 0
	self.statistic = nil
	self.showTotal = false
end
function FarmlandStatsDialog.show(farmlandId, fieldNumber, fieldArea, statistic)
	if FarmlandStatsDialog.INSTANCE ~= nil then
		local dialog = FarmlandStatsDialog.INSTANCE
		dialog:setData(farmlandId, fieldNumber, fieldArea, statistic)
		g_gui:showDialog("FarmlandStatsDialog")
	end
end
function FarmlandStatsDialog.createFromExistingGui(gui, guiName)
	FarmlandStatsDialog.register()
	local farmlandId = gui.farmlandId
	local fieldNumber = gui.fieldNumber
	local fieldArea = gui.fieldArea
	local statistic = gui.statistic
	if farmlandId ~= 0 then
		FarmlandStatsDialog.show(farmlandId, fieldNumber, fieldArea, statistic)
	end
end
