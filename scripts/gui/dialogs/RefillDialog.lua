-- Local values: RefillDialog_mt
RefillDialog = {}
local RefillDialog_mt = Class(RefillDialog, YesNoDialog)
RefillDialog.FILL_AMOUNTS = {
	1,
	2,
	5,
	10,
	20,
	50,
	100,
	200,
	500,
	1000,
	2000,
	5000,
	10000,
	50000,
	100000
}
function RefillDialog.register()
	local v2_ = RefillDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/RefillDialog.xml", "RefillDialog", v2_)
	RefillDialog.INSTANCE = v2_
end

-- Local values: dialog
function RefillDialog.show(callback, target, freeCapacities, priceFactor)
	if RefillDialog.INSTANCE ~= nil then
		local v7_ = RefillDialog.INSTANCE
		v7_:setFreeCapacities(freeCapacities, priceFactor)
		v7_:setCallback(callback, target)
		g_gui:showDialog("RefillDialog")
	end
end

-- Upvalues: RefillDialog_mt
-- Local values: self
function RefillDialog.new(target, custom_mt)
	-- upvalues: (copy) RefillDialog_mt
	local v10_ = YesNoDialog.new(target, custom_mt or RefillDialog_mt)
	v10_.selectedFillAmount = nil
	v10_.fillTypeAmountMapping = {}
	v10_.amountMapping = {}
	v10_.priceMapping = {}
	v10_.selectedPrice = 0
	v10_.priceFactor = 2
	v10_.fillTypeMapping = {}
	v10_.selectedFillType = nil
	v10_.lastSelectedFillType = nil
	v10_.areButtonsDisabled = false
	return v10_
end

-- Local values: freeCapacities, priceFactor, callback, target
function RefillDialog.createFromExistingGui(gui, guiName)
	RefillDialog.register()
	local v12_ = gui.freeCapacities
	local v13_ = gui.priceFactor
	local v14_ = gui.callbackFunc
	local v15_ = gui.target
	RefillDialog.show(v14_, v15_, v12_, v13_)
end

function RefillDialog:onOpen()
	RefillDialog:superClass().onOpen(self)
	if self.fillTypesElement.disabled then
		FocusManager:setFocus(self.fillAmountsElement)
	else
		FocusManager:unsetFocus(self.fillTypesElement)
		FocusManager:setFocus(self.fillTypesElement)
	end
end

-- Local values: fillType, amount, price, formattedPrice, text, callback, target
function RefillDialog:onClickOk()
	if self.areButtonsDisabled then
		return true
	end
	local v18_ = g_fillTypeManager:getFillTypeByIndex(self.selectedFillType)
	local v19_ = self.selectedFillAmount
	local v20_ = self.selectedPrice
	local v21_ = g_i18n:formatMoney(v20_)
	local v22_ = string.format(g_i18n:getText("ui_buyProductAmount"), v19_, v18_.title, v21_)
	local v23_ = self.onBuyYesNo
	YesNoDialog.show(v23_, self, v22_)
	return false
end

-- Local values: enoughMoney
function RefillDialog:onBuyYesNo(yes)
	if yes then
		if g_currentMission:getMoney() >= self.selectedPrice then
			self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
			self.callbackArgs = self.selectedFillAmount
			self.lastSelectedFillType = self.selectedFillType
			self:sendCallback(self.selectedFillType, self.selectedFillAmount, self.selectedPrice)
			return
		end
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
		InfoDialog.show(g_i18n:getText("shop_messageNotEnoughMoneyToBuy"))
	end
end

function RefillDialog:onClickBack(forceBack, usedMenuButton)
	self:sendCallback(nil, nil, nil)
	return false
end

function RefillDialog:sendCallback(fillTypeIndex, amount, price)
	self:close()
	if self.callbackFunc ~= nil then
		if self.target ~= nil then
			self.callbackFunc(self.target, fillTypeIndex, amount, price)
			return
		end
		self.callbackFunc(fillTypeIndex, amount, price)
	end
end

function RefillDialog:onClickFillTypes(state)
	self.selectedFillType = self.fillTypeMapping[state]
	self:updateFillAmounts()
end

function RefillDialog:onClickFillAmount(state)
	self.selectedFillAmount = self.amountMapping[state]
	self.selectedPrice = self.priceMapping[state]
end

-- Local values: fillTypesTable, selectedId, numFillLevels, fillTypeIndex, freeCapacity, fillType, fillAmounts, i, fillAmount
function RefillDialog:setFreeCapacities(freeCapacities, priceFactor)
	self.fillTypeMapping = {}
	self.fillTypeAmountMapping = {}
	self.priceFactor = priceFactor or self.priceFactor
	local v38_ = 1
	local v39_ = {}
	local v40_ = 1
	for v41_, v42_ in pairs(freeCapacities) do
		local v43_ = g_fillTypeManager:getFillTypeByIndex(v41_)
		if v41_ == self.lastSelectedFillType then
			v40_ = v38_
		end
		local v44_ = v43_.title
		table.insert(v39_, v44_)
		local v45_ = self.fillTypeMapping
		table.insert(v45_, v41_)
		local v46_ = {}
		for v47_ = #RefillDialog.FILL_AMOUNTS, 1, -1 do
			local v48_ = RefillDialog.FILL_AMOUNTS[v47_]
			if v48_ < v42_ then
				table.insert(v46_, 1, v48_)
			end
		end
		if v42_ > 0 and (v42_ ~= math.huge and v42_ ~= v46_[#v46_]) then
			table.insert(v46_, v42_)
		end
		self.fillTypeAmountMapping[v41_] = v46_
		v38_ = v38_ + 1
	end
	self.fillTypesElement:setDisabled(#v39_ <= 1)
	self.fillTypesElement:setTexts(v39_)
	self.fillTypesElement:setState(v40_, true)
	self.freeCapacities = freeCapacities
	self.priceFactor = priceFactor
end

-- Local values: fillAmountTexts, fillAmounts, fillType, litersText, _, fillAmount, pricePerLiter, price, priceStr, text
function RefillDialog:updateFillAmounts()
	local v50_ = self.fillTypeAmountMapping[self.selectedFillType]
	self.amountMapping = {}
	self.priceMapping = {}
	local v51_ = g_fillTypeManager:getFillTypeByIndex(self.selectedFillType)
	local v52_ = g_i18n:getText("unit_liter")
	local v53_ = {}
	for _, v54_ in ipairs(v50_) do
		local v55_ = v51_.pricePerLiter * self.priceFactor * v54_
		local v56_ = g_i18n:formatMoney(v55_)
		local v57_ = string.format("%d %s (%s)", v54_, v52_, v56_)
		table.insert(v53_, v57_)
		local v58_ = self.amountMapping
		table.insert(v58_, v54_)
		local v59_ = self.priceMapping
		table.insert(v59_, v55_)
	end
	self.fillAmountsElement:setTexts(v53_)
	self.fillAmountsElement:setState(#v53_, true)
	self:setButtonDisabled(#v50_ == 0)
	self.fillAmountsElement:setDisabled(#v50_ == 0)
	if #v50_ == 0 then
		self.fillAmountText:setText("-")
	end
	if self.fillTypesElement.disabled and not self.fillAmountsElement.disabled then
		FocusManager:unsetFocus(self.fillAmountsElement)
		FocusManager:setFocus(self.fillAmountsElement)
	end
end

function RefillDialog:setButtonDisabled(disabled)
	self.messageBackground:setVisible(disabled)
	self.areButtonsDisabled = disabled
	self.yesButton:setDisabled(disabled)
end
