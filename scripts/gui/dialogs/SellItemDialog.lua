SellItemDialog = {}
local SellItemDialog_mt = Class(SellItemDialog, YesNoDialog)
function SellItemDialog.register()
	local sellItemDialog = SellItemDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/SellItemDialog.xml", "SellItemDialog", sellItemDialog)
	SellItemDialog.INSTANCE = sellItemDialog
end
function SellItemDialog.show(callback, target, item, price, storeItem, isDirectSell)
	if SellItemDialog.INSTANCE ~= nil then
		local dialog = SellItemDialog.INSTANCE
		dialog:setItem(item, price, storeItem)
		dialog:setCallback(callback, target, isDirectSell)
		g_gui:showDialog("SellItemDialog")
	end
end
function SellItemDialog.new(target, custom_mt)
	local self = YesNoDialog.new(target, custom_mt or SellItemDialog_mt)
	self.selectedFillType = nil
	self.areButtonsDisabled = false
	return self
end
function SellItemDialog.createFromExistingGui(gui, guiName)
	SellItemDialog.register()
	local item = gui.item
	local price = item.price
	local storeItem = gui.storeItem
	local callback = gui.callbackFunc
	local target = gui.target
	SellItemDialog.show(callback, target, item, price, storeItem)
end
function SellItemDialog:onClose()
	self.item = nil
	self.storeItem = nil
	SellItemDialog:superClass().onClose(self)
end
function SellItemDialog:setItem(item, price, storeItem)
	local imageFilename = "dataS/menu/black.png"
	local name = "unknown"
	local sellPrice = g_i18n:formatMoney(Utils.getNoNil(price, 0), 0, true, true)
	if item ~= nil then
		storeItem = storeItem or g_storeManager:getItemByXMLFilename(item.configFileName)
		if storeItem ~= nil then
			imageFilename = storeItem.imageFilename
			name = storeItem.name
		end
		if item.getFullName ~= nil then
			name = item:getFullName()
		elseif item.getName ~= nil then
			name = item:getName()
		end
		if item.getImageFilename ~= nil then
			imageFilename = item:getImageFilename()
		end
	elseif storeItem ~= nil then
		imageFilename = storeItem.imageFilename
		name = storeItem.name
	end
	self.dialogImageElement:setImageFilename(imageFilename)
	self.dialogItemNameElement:setText(name)
	local title = g_i18n:getText("ui_sellItem")
	if item ~= nil then
		if item.propertyState == VehiclePropertyState.LEASED then
			title = g_i18n:getText("button_return")
			sellPrice = "-"
			self.dialogItemPriceElement:setVisible(false)
		else
			self.dialogItemPriceElement:setVisible(true)
		end
	end
	self.headerText:setText(title)
	self.dialogItemPriceElement:setText(sellPrice)
	self.item = item
	self.storeItem = storeItem
end
