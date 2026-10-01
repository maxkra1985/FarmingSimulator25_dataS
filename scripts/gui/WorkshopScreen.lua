WorkshopScreen = {}
local WorkshopScreen_mt = Class(WorkshopScreen, ScreenElement)
WorkshopScreen.L10N_SYMBOL = { CONFIGURATION_CHANGED = "shop_messageConfigurationChanged", CONFIGURATION_CHANGE_FAILED = "shop_messageConfigurationChangeFailed", CONFIGURATION_NO_PERMISSION = "shop_messageNoPermissionToBuyVehicleText", CONFIGURATION_NOT_ENOUGH_MONEY = "shop_messageNotEnoughMoneyToBuy" }
function WorkshopScreen.register()
	local workshopScreen = WorkshopScreen.new()
	g_gui:loadGui("dataS/gui/WorkshopScreen.xml", "WorkshopScreen", workshopScreen)
	return workshopScreen
end
function WorkshopScreen.new(target, custom_mt)
	local self = WorkshopScreen:superClass().new(target, custom_mt or WorkshopScreen_mt)
	self.vehicles = {}
	return self
end
function WorkshopScreen.createFromExistingGui(gui, guiName)
	local newGui = WorkshopScreen.new()
	local vehicles = gui.vehicles
	g_gui.guis[guiName]:delete()
	g_gui.guis[guiName].target:delete()
	FocusManager:deleteGuiFocusData("WorkshopScreen")
	g_gui:loadGui(gui.xmlFilename, guiName, newGui)
	newGui:setVehicles(vehicles)
	g_workshopScreen = newGui
	return newGui
end
function WorkshopScreen:onOpen()
	WorkshopScreen:superClass().onOpen(self)
	self:updateBalanceText()
	g_messageCenter:subscribe(SellVehicleEvent, self.onVehicleSellEvent, self)
	g_messageCenter:subscribe(MessageType.MONEY_CHANGED, self.updateBalanceText, self)
	g_messageCenter:subscribe(MessageType.VEHICLE_REPAIRED, self.onVehicleRepairEvent, self)
	g_messageCenter:subscribe(MessageType.VEHICLE_REPAINTED, self.onVehicleRepaintEvent, self)
	self.refreshTimer = 0
	if self.isMobileWorkshop then
		self.headerText:setText(g_i18n:getText("ui_mobileWorkshop"))
	elseif self.isOwnWorkshop then
		self.headerText:setText(g_i18n:getText("ui_sellOrCustomizeVehicleTitle"))
	else
		self.headerText:setText(g_i18n:getText("ui_dealer"))
	end
end
function WorkshopScreen:onClose()
	WorkshopScreen:superClass().onClose(self)
	self.vehicle = nil
	self.owner = nil
	g_messageCenter:unsubscribeAll(self)
	g_currentMission:showMoneyChange(MoneyType.SHOP_VEHICLE_BUY)
	g_currentMission:showMoneyChange(MoneyType.SHOP_VEHICLE_SELL)
end
function WorkshopScreen:setSellingPoint(sellingPoint, isDealer, isOwnWorkshop, isMobileWorkshop)
	self.owner = sellingPoint
	self.isDealer = isDealer
	self.isOwnWorkshop = isOwnWorkshop
	self.isMobileWorkshop = isMobileWorkshop
end
function WorkshopScreen:setConfigurations(vehicleBuyData, vehicleId)
	g_shopConfigScreen:onClickBack()
	if vehicleBuyData:isValid() then
		local areChangesMade = false
		local vehicle = NetworkUtil.getObject(vehicleId)
		if vehicle == nil then
			return
		end
		for configName, configValue in pairs(vehicleBuyData.configurations) do
			if vehicle.configurations[configName] ~= configValue then
				areChangesMade = true
				break
			end
		end
		if ConfigurationUtil.getConfigurationDataHasChanged(vehicle.configFileName, vehicleBuyData.configurationData, vehicle.configurationData) then
			areChangesMade = true
		end
		if vehicle.getLicensePlatesDataIsEqual ~= nil and not vehicle:getLicensePlatesDataIsEqual(vehicleBuyData.licensePlateData) then
			areChangesMade = true
		end
		if areChangesMade then
			local playerVehicle = g_localPlayer:getCurrentVehicle()
			if playerVehicle ~= nil and vehicle == playerVehicle then
				g_localPlayer:leaveVehicle()
			end
			g_client:getServerConnection():sendEvent(ChangeVehicleConfigEvent.new(vehicle, vehicleBuyData, self.isOwnWorkshop))
		end
	else
		self:onClickBack()
		if self.owner ~= nil then
			self.owner:openMenu()
		end
	end
end
function WorkshopScreen:update(dt)
	WorkshopScreen:superClass().update(self, dt)
	if self.vehicle ~= nil then
		if self.vehicle.isDeleted then
			table.removeElement(self.vehicles, self.vehicle)
			self.vehicle = nil
			self.list:reloadData()
			if #self.vehicles == 0 then
				self:setVehicle(nil)
			end
		elseif g_server == nil then
			self.refreshTimer = self.refreshTimer + dt
			if 250 < self.refreshTimer then
				self.refreshTimer = 0
				self:setVehicle(self.vehicle)
			end
		end
	end
	if self.needsListReload then
		self.list:reloadData()
		self.needsListReload = false
	end
end
function WorkshopScreen:setVehicles(vehicles)
	self.vehicles = vehicles
	self.list:reloadData()
	if #vehicles == 0 then
		self:setVehicle(nil)
	end
end
function WorkshopScreen:updateVehicles(sellingPoint, vehicles)
	if sellingPoint == self.owner then
		self:setVehicles(vehicles)
	end
end
function WorkshopScreen:setVehicle(vehicle)
	self.storeItem = nil
	self.canBeConfigured = false
	self.canBeSold = not self.mobileWorkshop
	if vehicle ~= nil then
		self.vehicle = vehicle
		self.storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
		if self.storeItem ~= nil then
			self.canBeConfigured = self.storeItem.configurations ~= nil and vehicle.propertyState == VehiclePropertyState.OWNED
			self.canBeSold = self.storeItem.canBeSold and not self.mobileWorkshop
		end
		self.sellButton:setDisabled(false)
		if vehicle.propertyState == VehiclePropertyState.OWNED then
			self:setButtonText(g_i18n:getText("button_sell"))
		elseif vehicle.propertyState == VehiclePropertyState.LEASED then
			self:setButtonText(g_i18n:getText("button_return"))
		elseif vehicle.propertyState == VehiclePropertyState.MISSION then
			self.sellButton:setDisabled(true)
		end
		local repairPrice = vehicle:getRepairPrice()
		if 1 <= repairPrice then
			self.repairButton:setText(string.format("%s (%s)", g_i18n:getText("button_repair"), g_i18n:formatMoney(repairPrice, 0, true, true)))
		else
			self.repairButton:setLocaKey("button_repair")
		end
		self.repairButton:setDisabled(repairPrice < 1)
		local repaintPrice = vehicle:getRepaintPrice()
		if 1 <= repaintPrice then
			self.repaintButton:setText(string.format("%s (%s)", g_i18n:getText("button_repaint"), g_i18n:formatMoney(repaintPrice, 0, true, true)))
		else
			self.repaintButton:setLocaKey("button_repaint")
		end
		self.repaintButton:setDisabled(repaintPrice < 1 or vehicle.propertyState == VehiclePropertyState.MISSION)
	else
		self.repairButton:setLocaKey("button_repair")
		self.repairButton:setDisabled(true)
		self.repaintButton:setLocaKey("button_repaint")
		self.repaintButton:setDisabled(true)
	end
	self.configButton:setDisabled(not self.canBeConfigured)
	self.configButton:setVisible(Platform.gameplay.hasVehicleConfigs)
	self.sellButton:setDisabled(true)
	self.sellButton:setVisible(vehicle ~= nil and not self.isOwnWorkshop and self.vehicle.propertyState ~= VehiclePropertyState.MISSION)
	self.repaintButton:setVisible(not self.isOwnWorkshop and Platform.gameplay.hasVehicleDamage)
	self.repairButton:setVisible(Platform.gameplay.hasVehicleDamage)
	self.dialogInfo:setVisible(vehicle == nil)
	self.buttonsBox:invalidateLayout()
end
function WorkshopScreen:setButtonText(text)
	self.sellButton:setText(text)
end
function WorkshopScreen:setStatusBarValue(bar, value)
	if 0.01 < math.abs((bar.lastStatusBarValue or -1) - value) then
		local fullWidth = bar.parent.size[1] - bar.margin[1] * 2
		local minSize = 0
		if bar.startSize ~= nil then
			minSize = bar.startSize[1] + bar.endSize[1]
		end
		bar:setSize(math.max(minSize, fullWidth * math.min(value, 1)), nil)
		bar.lastStatusBarValue = value
	end
end
function WorkshopScreen:updateBalanceText()
	local balance = g_currentMission ~= nil and g_currentMission:getMoney() or 0
	self.lastBalance = balance
	self.balanceElement:setValue(balance)
	if 0 < balance then
		self.balanceElement:applyProfile(ShopMenu.GUI_PROFILE.SHOP_MONEY)
	else
		self.balanceElement:applyProfile(ShopMenu.GUI_PROFILE.SHOP_MONEY_NEGATIVE)
	end
	if self.moneyBox ~= nil then
		self.moneyBox:invalidateLayout()
		self.moneyBoxBg:setSize(self.moneyBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
	end
end
function WorkshopScreen:onClickBack(forceBack)
	WorkshopScreen:superClass().onClickBack(self)
	self.vehicle = nil
	self.vehicles = {}
	self:changeScreen(nil)
end
function WorkshopScreen:onClickRepair()
	if self.vehicle ~= nil and 1 <= self.vehicle:getRepairPrice(true) then
		local text = string.format(g_i18n:getText("ui_repairDialog"), g_i18n:formatMoney(self.vehicle:getRepairPrice(true)))
		local callback = self.onYesNoRepairDialog
		local yesSound = GuiSoundPlayer.SOUND_SAMPLES.CONFIG_WRENCH
		YesNoDialog.show(callback, self, text, nil, nil, nil, nil, yesSound)
		return true
	end
	return false
end
function WorkshopScreen:onClickRepaint()
	if self.vehicle ~= nil and 1 <= self.vehicle:getRepaintPrice() then
		local text = string.format(g_i18n:getText("ui_repaintDialog"), g_i18n:formatMoney(self.vehicle:getRepaintPrice()))
		local callback = self.onYesNoRepaintDialog
		local yesSound = GuiSoundPlayer.SOUND_SAMPLES.CONFIG_SPRAY
		YesNoDialog.show(callback, self, text, nil, nil, nil, nil, yesSound)
		return true
	end
	return false
end
function WorkshopScreen:onClickConfigure()
	if self.canBeConfigured then
		local vehicle = self.vehicle
		local storeItem = self.storeItem
		self:changeScreen(ShopConfigScreen, nil, WorkshopScreen)
		g_shopConfigScreen:setReturnScreenClass(WorkshopScreen)
		g_shopConfigScreen:setStoreItem(storeItem, vehicle, nil, self.isOwnWorkshop)
		g_shopConfigScreen:setCallbacks(self.setConfigurations, self)
		return false
	else
		return true
	end
end
function WorkshopScreen:onClickSell()
	if self.vehicle ~= nil and (not self.isOwnWorkshop and (self.vehicle.propertyState ~= VehiclePropertyState.MISSION and self.canBeSold)) then
		local storeItem = g_storeManager:getItemByXMLFilename(self.vehicle.configFileName)
		g_shopController:sell(storeItem, self.vehicle, true)
		return false
	end
	return true
end
function WorkshopScreen:getNumberOfItemsInSection(list, section)
	return #self.vehicles
end
function WorkshopScreen:populateCellForItemInSection(list, section, index, cell)
	local vehicle = self.vehicles[index]
	cell:getAttribute("icon"):setImageFilename(vehicle:getImageFilename())
	local brandName = ""
	local brand = g_brandManager:getBrandByIndex(vehicle:getBrand())
	if brand ~= nil then
		brandName = brand.title .. " "
	end
	cell:getAttribute("name"):setText(brandName .. vehicle:getName())
	self:setVehicleDetails(self.vehicles[index], cell)
end
function WorkshopScreen:setVehicleDetails(vehicle, cell)
	local age = 0
	local operatingTime = 0
	if vehicle ~= nil then
		operatingTime = vehicle:getOperatingTime()
		age = vehicle.age
		if vehicle.propertyState == VehiclePropertyState.OWNED then
			local sellPrice = math.min(math.floor(vehicle:getSellPrice() * EconomyManager.DIRECT_SELL_MULTIPLIER), vehicle:getPrice())
			cell:getAttribute("priceText"):setText(g_i18n:formatMoney(sellPrice))
		elseif vehicle.propertyState == VehiclePropertyState.LEASED then
			cell:getAttribute("priceText"):setText("-")
		elseif vehicle.propertyState == VehiclePropertyState.MISSION then
			cell:getAttribute("priceText"):setText("-")
		end
		if vehicle.getWearTotalAmount ~= nil then
			self:setStatusBarValue(cell:getAttribute("paintConditionBar"), 1 - vehicle:getWearTotalAmount())
		end
		cell:getAttribute("paintConditionBar").parent:setVisible(Platform.gameplay.hasVehicleDamage and vehicle.getWearTotalAmount ~= nil)
		if vehicle.getDamageAmount ~= nil then
			self:setStatusBarValue(cell:getAttribute("conditionBar"), 1 - vehicle:getDamageAmount())
		end
		cell:getAttribute("conditionBar").parent:setVisible(Platform.gameplay.hasVehicleDamage and vehicle.getDamageAmount ~= nil)
	end
	local minutes = operatingTime / 60000
	local hours = math.floor(minutes / 60)
	minutes = math.floor((minutes - hours * 60) / 6) * 10
	cell:getAttribute("operatingHoursText"):setText(string.format(g_i18n:getText("shop_operatingTime"), hours, minutes))
	cell:getAttribute("ageText"):setText(string.format(g_i18n:getText("shop_age"), string.format("%d", age)))
end
function WorkshopScreen:onListSelectionChanged(list, section, index)
	self:setVehicle(self.vehicles[index])
end
function WorkshopScreen:onInfoDialogCallback() end
function WorkshopScreen:onYesNoRepaintDialog(yes)
	if yes then
		if g_currentMission:getMoney() < self.vehicle:getRepaintPrice() then
			InfoDialog.show(g_i18n:getText("shop_messageNotEnoughMoneyToBuy"))
			return
		end
		g_client:getServerConnection():sendEvent(WearableRepaintEvent.new(self.vehicle))
	end
end
function WorkshopScreen:onYesNoRepairDialog(yes)
	if yes then
		if g_currentMission:getMoney() < self.vehicle:getRepairPrice() then
			InfoDialog.show(g_i18n:getText("shop_messageNotEnoughMoneyToBuy"))
			return
		end
		g_client:getServerConnection():sendEvent(WearableRepairEvent.new(self.vehicle, true))
	end
end
function WorkshopScreen:onVehicleSold(sellPrice, isOwned, ownerFarmId)
	local text = g_i18n:getText("shop_messageSoldVehicle")
	if not isOwned then
		text = g_i18n:getText("shop_messageReturnedVehicle")
	end
	InfoDialog.show(text, self.onInfoDialogCallback, self, DialogElement.TYPE_INFO)
end
function WorkshopScreen:onVehicleSellFailed(isOwned, errorCode)
	local text = nil
	if isOwned then
		if errorCode == SellVehicleEvent.SELL_NO_PERMISSION then
			text = g_i18n:getText("shop_messageNoPermissionToSellVehicleText")
		elseif errorCode == SellVehicleEvent.SELL_VEHICLE_IN_USE then
			text = g_i18n:getText("shop_messageSellVehicleInUse")
		else
			text = g_i18n:getText("shop_messageFailedToSellVehicle")
		end
	elseif errorCode == SellVehicleEvent.SELL_NO_PERMISSION then
		text = g_i18n:getText("shop_messageNoPermissionToReturnVehicleText")
	elseif errorCode == SellVehicleEvent.SELL_VEHICLE_IN_USE then
		text = g_i18n:getText("shop_messageReturnVehicleInUse")
	else
		text = g_i18n:getText("shop_messageFailedToReturnVehicle")
	end
	InfoDialog.show(text)
end
function WorkshopScreen:onVehicleChanged(errorCode)
	if self.owner ~= nil then
		self.owner:openMenu()
	end
	if errorCode == ChangeVehicleConfigEvent.STATE_SUCCESS then
		InfoDialog.show(g_i18n:getText(WorkshopScreen.L10N_SYMBOL.CONFIGURATION_CHANGED), self.onInfoDialogCallback, self, DialogElement.TYPE_INFO)
	else
		local text = g_i18n:getText(WorkshopScreen.L10N_SYMBOL.CONFIGURATION_CHANGE_FAILED)
		if errorCode == ChangeVehicleConfigEvent.STATE_NO_PERMISSION then
			text = g_i18n:getText(WorkshopScreen.L10N_SYMBOL.CONFIGURATION_NO_PERMISSION)
		elseif errorCode == ChangeVehicleConfigEvent.STATE_NOT_ENOUGH_MONEY then
			text = g_i18n:getText(WorkshopScreen.L10N_SYMBOL.CONFIGURATION_NOT_ENOUGH_MONEY)
		end
		InfoDialog.show(text, self.onInfoDialogCallback, self)
	end
end
function WorkshopScreen:onVehicleRepairEvent(vehicle, atSellingPoint)
	if vehicle == self.vehicle then
		self:setVehicle(vehicle)
	end
	self.needsListReload = true
end
function WorkshopScreen:onVehicleRepaintEvent(vehicle, atSellingPoint)
	if vehicle == self.vehicle then
		self:setVehicle(vehicle)
	end
	self.needsListReload = true
end
function WorkshopScreen:onVehicleSellEvent(isDirectSell, errorCode, sellPrice, isOwned, ownerFarmId)
	if not isDirectSell then
		return
	elseif errorCode == SellVehicleEvent.SELL_SUCCESS then
		self:onVehicleSold(sellPrice, isOwned, ownerFarmId)
	else
		self:onVehicleSellFailed(isOwned, errorCode)
	end
end
