VehicleShopDialog = {}
local VehicleShopDialog_mt = Class(VehicleShopDialog, YesNoDialog)
function VehicleShopDialog.register()
	local vehicleShopDialog = VehicleShopDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/VehicleShopDialog.xml", "VehicleShopDialog", vehicleShopDialog)
	VehicleShopDialog.INSTANCE = vehicleShopDialog
end
function VehicleShopDialog.show(callback, target, items, title, description)
	if VehicleShopDialog.INSTANCE ~= nil then
		local dialog = VehicleShopDialog.INSTANCE
		dialog:setCallback(callback, target)
		dialog:setTitle(title)
		dialog:setDescription(description)
		dialog:setItems(items)
		g_gui:showDialog("VehicleShopDialog")
	end
end
function VehicleShopDialog.new(target, custom_mt)
	local self = YesNoDialog.new(target, custom_mt or VehicleShopDialog_mt)
	self.areButtonsDisabled = false
	return self
end
function VehicleShopDialog.createFromExistingGui(gui, guiName)
	VehicleShopDialog.register()
	local callback = gui.callbackFunc
	local target = gui.target
	local items = gui.items
	VehicleShopDialog.show(callback, target, items)
end
function VehicleShopDialog:onOpen()
	VehicleShopDialog:superClass().onOpen(self)
	FocusManager:setFocus(self.itemsElement)
end
function VehicleShopDialog:setTitle(title)
	VehicleShopDialog:superClass().setTitle(self, title or g_i18n:getText("ui_vehicleShopTitle"))
end
function VehicleShopDialog:setDescription(description)
	self.dialogDescriptionElement:setText(description or g_i18n:getText("ui_vehicleShopDescription"))
end
function VehicleShopDialog:onYes()
	if self.areButtonsDisabled then
		return true
	else
		self:sendCallback(self.lastSelectedIndex)
		return false
	end
end
function VehicleShopDialog:onNo(forceBack, usedMenuButton)
	self:sendCallback(nil, nil)
	return false
end
function VehicleShopDialog:sendCallback(index, quantity)
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
function VehicleShopDialog:onClickItems(state)
	self:setButtonDisabled(false)
	local item = self.items[state]
	self.lastSelectedIndex = state
	self.vehicleIconElement:setImageFilename(item.imageFilename)
	if item.storeItem ~= nil and 0 < #item.storeItem.functions then
		self.functionText:setText(item.storeItem.functions[1])
	end
	self:updatePrices()
end
function VehicleShopDialog:onClickQuantity()
	self:updatePrices()
end
function VehicleShopDialog:updatePrices()
	local item = self.items[self.lastSelectedIndex]
	local transportCosts = item.transportCosts or 0
	local price = item.price or 0
	local total = price + transportCosts
	self.transportPriceText:setText(g_i18n:formatMoney(transportCosts, 0, true, false))
	self.basePriceText:setText(g_i18n:formatMoney(price, 0, true, false))
	self.totalPriceText:setText(g_i18n:formatMoney(total, 0, true, false))
end
function VehicleShopDialog:setItems(items)
	self.items = items
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
end
function VehicleShopDialog:setButtonDisabled(disabled)
	self.areButtonsDisabled = disabled
	self.yesButton:setDisabled(disabled)
end
