-- Local values: FarmlandStatsDialog_mt
FarmlandStatsDialog = {}
FarmlandStatsDialog.MOD_NAME = g_currentModName
FarmlandStatsDialog.MOD_DIR = g_currentModDirectory
local FarmlandStatsDialog_mt = Class(FarmlandStatsDialog, MessageDialog)
function FarmlandStatsDialog.register()
	local v2_ = FarmlandStatsDialog.new()
	g_gui:loadGui(FarmlandStatsDialog.MOD_DIR .. "gui/FarmlandStatsDialog.xml", "FarmlandStatsDialog", v2_)
	FarmlandStatsDialog.INSTANCE = v2_
end

-- Upvalues: FarmlandStatsDialog_mt
-- Local values: self
function FarmlandStatsDialog.new(target, custom_mt)
	-- upvalues: (copy) FarmlandStatsDialog_mt
	local v5_ = FarmlandStatsDialog:superClass().new(target, custom_mt or FarmlandStatsDialog_mt)
	v5_.farmlandId = 0
	v5_.fieldNumber = 0
	v5_.fieldArea = 0
	v5_.statistic = nil
	v5_.showTotal = false
	return v5_
end

-- Local values: farmlandStatistics, text, setChangePercentageElement, buildValueDisplay, totalCosts, totalRegularCosts, costs, regularCosts, subsidies, yieldWeight, yieldBestPrice, earningsIncreasePct, earningsIncrease, costIncrease, totalEarnings, result
function FarmlandStatsDialog:setData(farmlandId, fieldNumber, fieldArea, statistic)
	self.farmlandId = farmlandId
	self.fieldNumber = fieldNumber
	self.fieldArea = fieldArea
	self.statistic = statistic
	local v_u_11_ = g_precisionFarming.farmlandStatistics
	local v12_
	if fieldNumber == 0 then
		v12_ = string.format(g_i18n:getText("ui_economicAnalysisHeaderAdditionalField"), fieldArea)
	else
		v12_ = string.format(g_i18n:getText("ui_economicAnalysisHeaderField"), fieldNumber, fieldArea)
	end
	self.economicAnalysisHeaderField:setText(v12_)
	self.economicAnalysisHeaderValues:setText(g_i18n:getText(self.showTotal and "ui_economicAnalysisHeaderValuesTotal" or "ui_economicAnalysisHeaderValuesPeriod"))
	local function v_u_23_(p13_, p14_, p15_, p16_, p17_)
		local v18_ = 0
		if p14_ == p15_ then
			p13_:setText("")
			return v18_
		end
		local v19_ = nil
		local v20_ = ""
		if p15_ == 0 then
			if math.floor(p16_ or 0) == 0 then
				v20_ = ""
			else
				v20_ = string.format("(%s%s)", p16_ > 0 and "+" or "", g_i18n:formatMoney(p16_))
				v19_ = p16_ > 0
				v18_ = 100
			end
		else
			local v21_ = -100 * (1 - p14_ / p15_)
			v18_ = math.floor(v21_)
			if v18_ ~= 0 then
				local v22_ = v18_ <= 0 and "(%d%%)" or "(+%d%%)"
				v20_ = string.format(v22_, v18_)
				v19_ = v18_ > 0
			end
		end
		if p17_ == true then
			v19_ = not v19_
		end
		p13_:applyProfile(v19_ and "farmlandStatsDialogChangeNeg" or "farmlandStatsDialogChangePos", true)
		p13_:setText(v20_)
		return v18_
	end
	local function v48_(p24_, p25_, p26_, p27_, p28_, p29_, p30_, p31_, p32_, p33_, p34_, p35_, p36_, p37_)
		-- upvalues: (copy) v_u_11_, (copy) self, (copy) v_u_23_
		if p34_ == nil then
			p34_ = " l"
		elseif p34_:len() > 0 then
			p34_ = " " .. p34_
		end
		local v38_ = p24_:getValue(p26_, p27_)
		if p28_ == nil then
			p28_ = v38_
		elseif type(p28_) == "string" then
			p28_ = p24_:getValue(p26_, p28_)
		elseif type(p28_) ~= "number" then
			p28_ = v38_
		end
		local v39_ = p35_ or v_u_11_:getFillLevelPrice(v38_, p29_)
		local v40_ = p36_ or v_u_11_:getFillLevelWeight(v38_, p29_)
		if p31_ then
			local v41_ = "%d" .. p34_
			if p33_ then
				v41_ = "%.1f" .. p34_
			else
				v38_ = MathUtil.round(v38_)
			end
			if p30_ then
				v41_ = v41_ .. " | %.1f t"
			end
			self.statAmountText[p25_]:setText(string.format(v41_, v38_, v40_))
		else
			self.statAmountText[p25_]:setText("")
		end
		if p32_ == nil or p32_ then
			self.statCostText[p25_]:setText(g_i18n:formatMoney(v39_))
		else
			self.statCostText[p25_]:setText("")
		end
		local v42_ = v_u_23_(self.statPercentageText[p25_], v38_, p28_, v39_, p37_)
		local v43_ = p32_ == false and 0 or v42_
		local v44_ = math.floor(v39_)
		local v45_ = math.max(v44_)
		local v46_ = v39_ * (-v43_ * 0.01 + 1)
		local v47_ = math.floor(v46_)
		return v45_, math.max(v47_, 0)
	end
	local v49_, v50_ = v48_(statistic, 1, self.showTotal, "numSoilSamples", 0, "soilSamples", false, true, true, false, "", statistic:getValue(self.showTotal, "soilSampleCosts"))
	local v51_ = 0 + v49_
	local v52_ = 0 + v50_
	local v53_, v54_ = v48_(statistic, 2, self.showTotal, "usedLime", "usedLimeRegular", FillType.LIME, true, true, true, false)
	local v55_ = v51_ + v53_
	local v56_ = v52_ + v54_
	local v57_, v58_ = v48_(statistic, 3, self.showTotal, "usedMineralFertilizer", "usedMineralFertilizerRegular", FillType.FERTILIZER, true, true, true, false)
	local v59_ = v55_ + v57_
	local v60_ = v56_ + v58_
	local v61_, v62_ = v48_(statistic, 4, self.showTotal, "usedLiquidFertilizer", "usedLiquidFertilizerRegular", FillType.LIQUIDFERTILIZER, false, true, true, false)
	local v63_ = v59_ + v61_
	local v64_ = v60_ + v62_
	v48_(statistic, 5, self.showTotal, "usedManure", "usedManureRegular", FillType.MANURE, true, true, false, false)
	v48_(statistic, 6, self.showTotal, "usedLiquidManure", "usedLiquidManureRegular", FillType.LIQUIDMANURE, false, true, false, false)
	local v65_, v66_ = v48_(statistic, 7, self.showTotal, "usedSeeds", "usedSeedsRegular", FillType.SEEDS, true, true, true, false)
	local v67_ = v63_ + v65_
	local v68_ = v64_ + v66_
	local v69_, v70_ = v48_(statistic, 8, self.showTotal, "usedHerbicide", "usedHerbicideRegular", FillType.HERBICIDE, false, true, true, false)
	local v71_ = v67_ + v69_
	local v72_ = v68_ + v70_
	local v73_, v74_ = v48_(statistic, 9, self.showTotal, "usedFuel", nil, FillType.DIESEL, false, true, true, true)
	local v75_ = v71_ + v73_
	local v76_ = v72_ + v74_
	local v77_, v78_ = v48_(statistic, 10, self.showTotal, "vehicleCosts", nil, 0, false, false, true, false)
	local v79_ = v75_ + v77_
	local v80_ = v76_ + v78_
	local v81_, v82_ = v48_(statistic, 11, self.showTotal, "helperCosts", nil, 0, false, false, true, false)
	local v83_ = v79_ + v81_
	local v84_ = v80_ + v82_
	local v85_ = statistic:getValue(self.showTotal, "subsidies")
	v48_(statistic, 12, self.showTotal, v85_, 0, 0, false, false, true, false, nil, v85_, 0, false)
	local v86_ = statistic:getValue(self.showTotal, "yieldWeight")
	local v87_ = statistic:getValue(self.showTotal, "yieldBestPrice")
	v48_(statistic, 13, self.showTotal, "yield", "yieldRegular", 0, true, true, true, false, nil, v87_, v86_, true)
	local v88_ = statistic:getValue(self.showTotal, "yield")
	local v89_ = statistic:getValue(self.showTotal, "yieldRegular")
	local v90_ = v88_ / math.max(v89_, 0.01)
	local v91_ = v90_ == 0 and 0 or v87_ - v87_ / v90_
	local v92_ = v84_ - v83_
	v_u_23_(self.statTotalCostPercentageText, v83_, 0, math.abs(v92_), false)
	v_u_23_(self.statTotalEarningsPercentageText, v87_, 0, v91_, true)
	v_u_23_(self.statTotalPercentageText, v87_, 0, v92_ + v91_, true)
	local v93_ = v87_ + v85_
	local v94_ = v93_ - v83_
	self.statTotalCostText:setText(g_i18n:formatMoney(v83_))
	self.statTotalEarningsText:setText(g_i18n:formatMoney(v93_))
	self.statTotalText:setText(g_i18n:formatMoney(v94_))
end

function FarmlandStatsDialog:onSwitchMode()
	self.showTotal = not self.showTotal
	if self.farmlandId ~= 0 then
		self:setData(self.farmlandId, self.fieldNumber, self.fieldArea, self.statistic)
	end
end

-- Local values: farmlandStatistics
function FarmlandStatsDialog:onReset()
	if self.farmlandId ~= 0 then
		g_precisionFarming.farmlandStatistics:resetStatistic(self.farmlandId, false)
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

-- Local values: dialog
function FarmlandStatsDialog.show(farmlandId, fieldNumber, fieldArea, statistic)
	if FarmlandStatsDialog.INSTANCE ~= nil then
		FarmlandStatsDialog.INSTANCE:setData(farmlandId, fieldNumber, fieldArea, statistic)
		g_gui:showDialog("FarmlandStatsDialog")
	end
end

-- Local values: farmlandId, fieldNumber, fieldArea, statistic
function FarmlandStatsDialog.createFromExistingGui(gui, guiName)
	FarmlandStatsDialog.register()
	local v103_ = gui.farmlandId
	local v104_ = gui.fieldNumber
	local v105_ = gui.fieldArea
	local v106_ = gui.statistic
	if v103_ ~= 0 then
		FarmlandStatsDialog.show(v103_, v104_, v105_, v106_)
	end
end
