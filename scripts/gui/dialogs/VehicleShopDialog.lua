-- Local values: VehicleShopDialog_mt
VehicleShopDialog = {}
local VehicleShopDialog_mt = Class(VehicleShopDialog, YesNoDialog)
function VehicleShopDialog.register()
	local v2_ = VehicleShopDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/VehicleShopDialog.xml", "VehicleShopDialog", v2_)
	VehicleShopDialog.INSTANCE = v2_
end

-- Local values: dialog
function VehicleShopDialog.show(callback, target, items, title, description)
	if VehicleShopDialog.INSTANCE ~= nil then
		local v8_ = VehicleShopDialog.INSTANCE
		v8_:setCallback(callback, target)
		v8_:setTitle(title)
		v8_:setDescription(description)
		v8_:setItems(items)
		g_gui:showDialog("VehicleShopDialog")
	end
end

-- Upvalues: VehicleShopDialog_mt
-- Local values: self
function VehicleShopDialog.new(target, custom_mt)
	-- upvalues: (copy) VehicleShopDialog_mt
	local v11_ = YesNoDialog.new(target, custom_mt or VehicleShopDialog_mt)
	v11_.areButtonsDisabled = false
	return v11_
end

-- Local values: callback, target, items
function VehicleShopDialog.createFromExistingGui(gui, guiName)
	VehicleShopDialog.register()
	local v13_ = gui.callbackFunc
	local v14_ = gui.target
	local v15_ = gui.items
	VehicleShopDialog.show(v13_, v14_, v15_)
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
	end
	self:sendCallback(self.lastSelectedIndex)
	return false
end

function VehicleShopDialog:onNo(forceBack, usedMenuButton)
	self:sendCallback(nil, nil)
	return false
end

function VehicleShopDialog:sendCallback(index, quantity)
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
function VehicleShopDialog:onClickItems(state)
	self:setButtonDisabled(false)
	local v28_ = self.items[state]
	self.lastSelectedIndex = state
	self.vehicleIconElement:setImageFilename(v28_.imageFilename)
	if v28_.storeItem ~= nil and #v28_.storeItem.functions > 0 then
		self.functionText:setText(v28_.storeItem.functions[1])
	end
	self:updatePrices()
end

function VehicleShopDialog:onClickQuantity()
	self:updatePrices()
end

-- Local values: item, transportCosts, price, total
function VehicleShopDialog:updatePrices()
	local v31_ = self.items[self.lastSelectedIndex]
	local v32_ = v31_.transportCosts or 0
	local v33_ = v31_.price or 0
	local v34_ = v33_ + v32_
	self.transportPriceText:setText(g_i18n:formatMoney(v32_, 0, true, false))
	self.basePriceText:setText(g_i18n:formatMoney(v33_, 0, true, false))
	self.totalPriceText:setText(g_i18n:formatMoney(v34_, 0, true, false))
end

-- Local values: selectedId, itemTitles, k, item
function VehicleShopDialog:setItems(items)
	self.items = items
	self.itemsMapping = {}
	local v37_ = {}
	local v38_ = 1
	for v39_, v40_ in ipairs(items) do
		local v41_ = v40_.title
		table.insert(v37_, v41_)
		if v39_ == self.lastSelectedIndex then
			v38_ = v39_
		end
	end
	self.itemsElement:setTexts(v37_)
	self.itemsElement:setState(v38_, true)
end

function VehicleShopDialog:setButtonDisabled(disabled)
	self.areButtonsDisabled = disabled
	self.yesButton:setDisabled(disabled)
end
