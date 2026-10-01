PalletShopDialog = {}
local PalletShopDialog_mt = Class(PalletShopDialog, YesNoDialog)
function PalletShopDialog.register()
	local palletShopDialog = PalletShopDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/PalletShopDialog.xml", "PalletShopDialog", palletShopDialog)
	PalletShopDialog.INSTANCE = palletShopDialog
end
function PalletShopDialog.show(callback, target, items, maxQuantity, title)
	if PalletShopDialog.INSTANCE ~= nil then
		local dialog = PalletShopDialog.INSTANCE
		dialog:setCallback(callback, target)
		dialog:setTitle(title)
		dialog:setItems(items, maxQuantity)
		g_gui:showDialog("PalletShopDialog")
	end
end
function PalletShopDialog.new(target, custom_mt)
	local self = YesNoDialog.new(target, custom_mt or PalletShopDialog_mt)
	self.selectedFillType = nil
	self.areButtonsDisabled = false
	self.lastSelectedFillType = nil
	return self
end
function PalletShopDialog.createFromExistingGui(gui, guiName)
	PalletShopDialog.register()
	local callback = gui.callbackFunc
	local target = gui.target
	local items = gui.items
	local maxQuantity = gui.maxQuantity
	PalletShopDialog.show(callback, target, items, maxQuantity)
end
function PalletShopDialog:onOpen()
	PalletShopDialog:superClass().onOpen(self)
	FocusManager:setFocus(self.itemsElement)
end
function PalletShopDialog:onYes()
	if self.areButtonsDisabled then
		return true
	else
		self:sendCallback(self.lastSelectedIndex, self.quantityElement:getState())
		return false
	end
end
function PalletShopDialog:onNo(forceBack, usedMenuButton)
	self:sendCallback(nil, nil)
	return false
end
function PalletShopDialog:sendCallback(index, quantity)
	if self.inputDelay < self.time then
		self:close()
		if self.callbackFunc ~= nil then
			if self.target ~= nil then
				self.callbackFunc(self.target, index, quantity, self.callbackArgs)
			else
				self.callbackFunc(index, quantity, self.callbackArgs)
			end
		end
		return false
	else
		return true
	end
end
function PalletShopDialog:onClickItems(state)
	self:setButtonDisabled(false)
	local item = self.items[state]
	self.lastSelectedIndex = state
	self.palletIconElement:setImageFilename(item.imageFilename)
	self:updatePrices()
end
function PalletShopDialog:onClickQuantity()
	self:updatePrices()
end
function PalletShopDialog:updatePrices()
	local item = self.items[self.lastSelectedIndex]
	local quantity = self.quantityElement:getState()
	local price = item.price
	local total = item.price * quantity
	self.basePriceText:setText(g_i18n:formatMoney(price, 0, true, false))
	self.totalPriceText:setText(g_i18n:formatMoney(total, 0, true, false))
end
function PalletShopDialog:setItems(items, maxQuantity)
	self.items = items
	self.maxQuantity = maxQuantity
	self.itemsMapping = {}
	local selectedId = 1
	local itemTitles = {}
	for k, item in ipairs(items) do
		table.insert(itemTitles, item.title)
		if k == self.lastSelectedIndex then
			selectedId = k
		end
	end
	self.itemsElement:setTexts(itemTitles)
	self.itemsElement:setState(selectedId, true)
	local quantities = {}
	for i = 1, maxQuantity do
		table.insert(quantities, tostring(i) .. "x")
	end
	self.quantityElement:setTexts(quantities)
end
function PalletShopDialog:setButtonDisabled(disabled)
	self.areButtonsDisabled = disabled
	self.yesButton:setDisabled(disabled)
end
