-- Local values: SellItemDialog_mt
SellItemDialog = {}
local SellItemDialog_mt = Class(SellItemDialog, YesNoDialog)
function SellItemDialog.register()
	local v2_ = SellItemDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/SellItemDialog.xml", "SellItemDialog", v2_)
	SellItemDialog.INSTANCE = v2_
end

-- Local values: dialog
function SellItemDialog.show(callback, target, item, price, storeItem, isDirectSell)
	if SellItemDialog.INSTANCE ~= nil then
		local v9_ = SellItemDialog.INSTANCE
		v9_:setItem(item, price, storeItem)
		v9_:setCallback(callback, target, isDirectSell)
		g_gui:showDialog("SellItemDialog")
	end
end

-- Upvalues: SellItemDialog_mt
-- Local values: self
function SellItemDialog.new(target, custom_mt)
	-- upvalues: (copy) SellItemDialog_mt
	local v12_ = YesNoDialog.new(target, custom_mt or SellItemDialog_mt)
	v12_.selectedFillType = nil
	v12_.areButtonsDisabled = false
	return v12_
end

-- Local values: item, price, storeItem, callback, target
function SellItemDialog.createFromExistingGui(gui, guiName)
	SellItemDialog.register()
	local v14_ = gui.item
	local v15_ = v14_.price
	local v16_ = gui.storeItem
	local v17_ = gui.callbackFunc
	local v18_ = gui.target
	SellItemDialog.show(v17_, v18_, v14_, v15_, v16_)
end

function SellItemDialog:onClose()
	self.item = nil
	self.storeItem = nil
	SellItemDialog:superClass().onClose(self)
end

-- Local values: imageFilename, name, sellPrice, title
function SellItemDialog:setItem(item, price, storeItem)
	local v24_ = "dataS/menu/black.png"
	local v25_ = "unknown"
	local v26_ = g_i18n:formatMoney(Utils.getNoNil(price, 0), 0, true, true)
	if item == nil then
		if storeItem ~= nil then
			v24_ = storeItem.imageFilename
			v25_ = storeItem.name
		end
	else
		storeItem = storeItem or g_storeManager:getItemByXMLFilename(item.configFileName)
		if storeItem ~= nil then
			v24_ = storeItem.imageFilename
			v25_ = storeItem.name
		end
		if item.getFullName == nil then
			if item.getName ~= nil then
				v25_ = item:getName()
			end
		else
			v25_ = item:getFullName()
		end
		if item.getImageFilename ~= nil then
			v24_ = item:getImageFilename()
		end
	end
	self.dialogImageElement:setImageFilename(v24_)
	self.dialogItemNameElement:setText(v25_)
	local v27_ = g_i18n:getText("ui_sellItem")
	if item == nil or item.propertyState ~= VehiclePropertyState.LEASED then
		self.dialogItemPriceElement:setVisible(true)
	else
		v27_ = g_i18n:getText("button_return")
		self.dialogItemPriceElement:setVisible(false)
		v26_ = "-"
	end
	self.headerText:setText(v27_)
	self.dialogItemPriceElement:setText(v26_)
	self.item = item
	self.storeItem = storeItem
end
