-- Local values: PalletShopDialog_mt
PalletShopDialog = {}
local PalletShopDialog_mt = Class(PalletShopDialog, YesNoDialog)
function PalletShopDialog.register()
	local v2_ = PalletShopDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/PalletShopDialog.xml", "PalletShopDialog", v2_)
	PalletShopDialog.INSTANCE = v2_
end

-- Local values: dialog
function PalletShopDialog.show(callback, target, items, maxQuantity, title)
	if PalletShopDialog.INSTANCE ~= nil then
		local v8_ = PalletShopDialog.INSTANCE
		v8_:setCallback(callback, target)
		v8_:setTitle(title)
		v8_:setItems(items, maxQuantity)
		g_gui:showDialog("PalletShopDialog")
	end
end

-- Upvalues: PalletShopDialog_mt
-- Local values: self
function PalletShopDialog.new(target, custom_mt)
	-- upvalues: (copy) PalletShopDialog_mt
	local v11_ = YesNoDialog.new(target, custom_mt or PalletShopDialog_mt)
	v11_.selectedFillType = nil
	v11_.areButtonsDisabled = false
	v11_.lastSelectedFillType = nil
	return v11_
end

-- Local values: callback, target, items, maxQuantity
function PalletShopDialog.createFromExistingGui(gui, guiName)
	PalletShopDialog.register()
	local v13_ = gui.callbackFunc
	local v14_ = gui.target
	local v15_ = gui.items
	local v16_ = gui.maxQuantity
	PalletShopDialog.show(v13_, v14_, v15_, v16_)
end

function PalletShopDialog:onOpen()
	PalletShopDialog:superClass().onOpen(self)
	FocusManager:setFocus(self.itemsElement)
end

function PalletShopDialog:onYes()
	if self.areButtonsDisabled then
		return true
	end
	self:sendCallback(self.lastSelectedIndex, self.quantityElement:getState())
	return false
end

function PalletShopDialog:onNo(forceBack, usedMenuButton)
	self:sendCallback(nil, nil)
	return false
end

function PalletShopDialog:sendCallback(index, quantity)
	if self.inputDelay >= self.time then
		return true
	end
	self:close()
	if self.callbackFunc ~= nil then
		if self.target == nil then
			self.callbackFunc(index, quantity, self.callbackArgs)
		else
			self.callbackFunc(self.target, index, quantity, self.callbackArgs)
		end
	end
	return false
end

-- Local values: item
function PalletShopDialog:onClickItems(state)
	self:setButtonDisabled(false)
	local v25_ = self.items[state]
	self.lastSelectedIndex = state
	self.palletIconElement:setImageFilename(v25_.imageFilename)
	self:updatePrices()
end

function PalletShopDialog:onClickQuantity()
	self:updatePrices()
end

-- Local values: item, quantity, price, total
function PalletShopDialog:updatePrices()
	local v28_ = self.items[self.lastSelectedIndex]
	local v29_ = self.quantityElement:getState()
	local v30_ = v28_.price
	local v31_ = v28_.price * v29_
	self.basePriceText:setText(g_i18n:formatMoney(v30_, 0, true, false))
	self.totalPriceText:setText(g_i18n:formatMoney(v31_, 0, true, false))
end

-- Local values: selectedId, itemTitles, k, item, quantities, i
function PalletShopDialog:setItems(items, maxQuantity)
	self.items = items
	self.maxQuantity = maxQuantity
	self.itemsMapping = {}
	local v35_ = {}
	local v36_ = 1
	for v37_, v38_ in ipairs(items) do
		local v39_ = v38_.title
		table.insert(v35_, v39_)
		if v37_ == self.lastSelectedIndex then
			v36_ = v37_
		end
	end
	self.itemsElement:setTexts(v35_)
	self.itemsElement:setState(v36_, true)
	local v40_ = {}
	for v41_ = 1, maxQuantity do
		local v42_ = tostring(v41_) .. "x"
		table.insert(v40_, v42_)
	end
	self.quantityElement:setTexts(v40_)
end

function PalletShopDialog:setButtonDisabled(disabled)
	self.areButtonsDisabled = disabled
	self.yesButton:setDisabled(disabled)
end
