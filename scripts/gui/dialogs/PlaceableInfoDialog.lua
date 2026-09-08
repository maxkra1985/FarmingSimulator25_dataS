-- Local values: PlaceableInfoDialog_mt
PlaceableInfoDialog = {}
local PlaceableInfoDialog_mt = Class(PlaceableInfoDialog, DialogElement)
function PlaceableInfoDialog.register()
	local v2_ = PlaceableInfoDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/PlaceableInfoDialog.xml", "PlaceableInfoDialog", v2_)
	PlaceableInfoDialog.INSTANCE = v2_
end

-- Local values: dialog
function PlaceableInfoDialog.show(callback, placeable)
	if PlaceableInfoDialog.INSTANCE ~= nil then
		local v5_ = PlaceableInfoDialog.INSTANCE
		v5_:setCallback(callback)
		v5_:setPlaceable(placeable)
		g_gui:showDialog("PlaceableInfoDialog")
	end
end

-- Upvalues: PlaceableInfoDialog_mt
-- Local values: self
function PlaceableInfoDialog.new(target, custom_mt)
	-- upvalues: (copy) PlaceableInfoDialog_mt
	local v8_ = DialogElement.new(target, custom_mt or PlaceableInfoDialog_mt)
	v8_.inputDelay = 0
	return v8_
end

-- Local values: placeable, callback
function PlaceableInfoDialog.createFromExistingGui(gui, guiName)
	PlaceableInfoDialog.register()
	local v10_ = gui.placeable
	local v11_ = gui.callbackFunc
	PlaceableInfoDialog.show(v11_, v10_)
end

function PlaceableInfoDialog:onOpen()
	PlaceableInfoDialog:superClass().onOpen(self)
	self.inputDelay = self.time + 250
end

function PlaceableInfoDialog:onClose()
	g_messageCenter:unsubscribe(SellPlaceableEvent, self)
	self.callbackFunc = nil
	self.target = nil
	self.callbackArgs = nil
	self.placeable = nil
	PlaceableInfoDialog:superClass().onClose(self)
end

-- Local values: name, price, _forFullPrice, sellPrice, canRename, allowedToRename, imageFilename, canSell, allowedToSell
function PlaceableInfoDialog:setPlaceable(placeable)
	local v16_ = placeable:getName()
	local v17_, _ = placeable:getSellPrice()
	local v18_ = g_i18n:formatMoney(v17_)
	local v19_ = placeable:getCanBeRenamedByFarm(g_currentMission:getFarmId())
	local v20_ = g_currentMission:getHasPlayerPermission("buyPlaceable")
	local v21_ = placeable:getImageFilename()
	local v22_ = placeable:canBeSold() and placeable.storeItem.canBeSold
	if v22_ then
		v22_ = g_currentMission:getFarmId() == placeable:getOwnerFarmId()
	end
	local v23_ = g_currentMission:getHasPlayerPermission(Farm.PERMISSION.SELL_PLACEABLE)
	self.placeable = placeable
	if v21_ == nil then
		self.icon:setVisible(false)
	else
		self.icon:setImageFilename(v21_)
		self.icon:setVisible(true)
	end
	self.titleText:setText(v16_)
	self.priceText:setText(v18_)
	self.ageText:setText(string.format(g_i18n:getText("shop_age"), string.format("%d", placeable.age)))
	self.sellButton:setVisible(v22_)
	self.sellButton:setDisabled(not v23_)
	self.renameButton:setVisible(v19_)
	self.renameButton:setDisabled(not v20_)
	self.renameSeparator:setVisible(v19_)
	self.sellButton.parent:invalidateLayout()
	g_messageCenter:subscribe(SellPlaceableEvent, self.onPlaceableDestroyed, self)
	self.placeable = placeable
end

function PlaceableInfoDialog:setCallback(callbackFunc, target, args)
	self.callbackFunc = callbackFunc
	self.target = target
	self.callbackArgs = args
end

function PlaceableInfoDialog:onClickBack()
	if self.inputDelay >= self.time then
		return true
	end
	self:sendCallback(false)
	self:close()
	return false
end

function PlaceableInfoDialog:sendCallback(didSell)
	g_messageCenter:unsubscribe(SellPlaceableEvent, self)
	if self.callbackFunc ~= nil then
		if self.target ~= nil then
			self.callbackFunc(self.target, didSell, self.callbackArgs)
			return
		end
		self.callbackFunc(didSell, self.callbackArgs)
	end
end

-- Local values: price, forFullPrice, text, callback
function PlaceableInfoDialog:onClickSell()
	local v32_, v_u_33_ = self.placeable:getSellPrice()
	local v34_ = string.format(g_i18n:getText("ui_constructionSellConfirmation"), self.placeable:getName(), g_i18n:formatMoney(v32_, 0, true, true))
	YesNoDialog.show(function(p35_)
		-- upvalues: (copy) self, (copy) v_u_33_
		if p35_ then
			g_client:getServerConnection():sendEvent(SellPlaceableEvent.new(self.placeable, nil, v_u_33_))
		end
	end, nil, v34_)
end

-- Local values: text, defaultText, callback, dialogPrompt, imePrompt, confirmText
function PlaceableInfoDialog:onClickRename()
	local v37_ = g_i18n:getText("button_changeName")
	local v38_ = self.placeable:getName()
	local v39_ = g_i18n:getText("ui_enterName")
	local v40_ = g_i18n:getText("ui_enterName")
	local v41_ = g_i18n:getText("button_change")
	TextInputDialog.show(function(p42_, p43_)
		-- upvalues: (copy) self
		if p43_ then
			if not g_currentMission:getHasPlayerPermission("buyPlaceable") then
				InfoDialog.show(g_i18n:getText("shop_messageNoPermissionGeneral"), nil, nil, DialogElement.TYPE_WARNING)
				return
			end
			if string.isNilOrWhitespace(p42_) then
				self.placeable:setName(nil)
			else
				self.placeable:setName(string.trim(p42_))
			end
			g_messageCenter:unsubscribe(SellPlaceableEvent, self)
			self:setPlaceable(self.placeable)
		end
	end, nil, v38_, v39_, v40_, nil, v41_, nil, v37_)
end

function PlaceableInfoDialog:onPlaceableDestroyed()
	self:sendCallback(true)
	self:close()
end
