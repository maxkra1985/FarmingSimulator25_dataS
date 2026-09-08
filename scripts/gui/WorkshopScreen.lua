-- Local values: WorkshopScreen_mt
WorkshopScreen = {}
local WorkshopScreen_mt = Class(WorkshopScreen, ScreenElement)
function WorkshopScreen.register()
	local v2_ = WorkshopScreen.new()
	g_gui:loadGui("dataS/gui/WorkshopScreen.xml", "WorkshopScreen", v2_)
	return v2_
end

-- Upvalues: WorkshopScreen_mt
-- Local values: self
function WorkshopScreen.new(target, custom_mt)
	-- upvalues: (copy) WorkshopScreen_mt
	local v5_ = WorkshopScreen:superClass().new(target, custom_mt or WorkshopScreen_mt)
	v5_.vehicles = {}
	return v5_
end

-- Local values: newGui, vehicles
function WorkshopScreen.createFromExistingGui(gui, guiName)
	local v8_ = WorkshopScreen.new()
	local v9_ = gui.vehicles
	g_gui.guis[guiName]:delete()
	g_gui.guis[guiName].target:delete()
	FocusManager:deleteGuiFocusData("WorkshopScreen")
	g_gui:loadGui(gui.xmlFilename, guiName, v8_)
	v8_:setVehicles(v9_)
	g_workshopScreen = v8_
	return v8_
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
		return
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

-- Local values: areChangesMade, vehicle, configName, configValue, playerVehicle
function WorkshopScreen:setConfigurations(vehicleBuyData, vehicleId)
	g_shopConfigScreen:onClickBack()
	if vehicleBuyData:isValid() then
		local v20_ = false
		local v21_ = NetworkUtil.getObject(vehicleId)
		if v21_ == nil then
			return
		end
		for v22_, v23_ in pairs(vehicleBuyData.configurations) do
			if v21_.configurations[v22_] ~= v23_ then
				v20_ = true
				break
			end
		end
		local v24_ = ConfigurationUtil.getConfigurationDataHasChanged(v21_.configFileName, vehicleBuyData.configurationData, v21_.configurationData) and true or v20_
		if v21_.getLicensePlatesDataIsEqual ~= nil and not v21_:getLicensePlatesDataIsEqual(vehicleBuyData.licensePlateData) and true or v24_ then
			local v25_ = g_localPlayer:getCurrentVehicle()
			if v25_ ~= nil and v21_ == v25_ then
				g_localPlayer:leaveVehicle()
			end
			g_client:getServerConnection():sendEvent(ChangeVehicleConfigEvent.new(v21_, vehicleBuyData))
			return
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
			if self.refreshTimer > 250 then
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

-- Local values: repairPrice, repaintPrice
function WorkshopScreen:setVehicle(vehicle)
	self.storeItem = nil
	self.canBeConfigured = false
	self.canBeSold = not self.mobileWorkshop
	if vehicle == nil then
		self.repairButton:setLocaKey("button_repair")
		self.repairButton:setDisabled(true)
		self.repaintButton:setLocaKey("button_repaint")
		self.repaintButton:setDisabled(true)
	else
		self.vehicle = vehicle
		self.storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
		if self.storeItem ~= nil then
			local v35_
			if self.storeItem.configurations == nil then
				v35_ = false
			else
				v35_ = vehicle.propertyState == VehiclePropertyState.OWNED
			end
			self.canBeConfigured = v35_
			local v36_ = self.storeItem.canBeSold
			if v36_ then
				v36_ = not self.mobileWorkshop
			end
			self.canBeSold = v36_
		end
		self.sellButton:setDisabled(false)
		if vehicle.propertyState == VehiclePropertyState.OWNED then
			self:setButtonText(g_i18n:getText("button_sell"))
		elseif vehicle.propertyState == VehiclePropertyState.LEASED then
			self:setButtonText(g_i18n:getText("button_return"))
		elseif vehicle.propertyState == VehiclePropertyState.MISSION then
			self.sellButton:setDisabled(true)
		end
		local v37_ = vehicle:getRepairPrice()
		if v37_ >= 1 then
			self.repairButton:setText(string.format("%s (%s)", g_i18n:getText("button_repair"), g_i18n:formatMoney(v37_, 0, true, true)))
		else
			self.repairButton:setLocaKey("button_repair")
		end
		self.repairButton:setDisabled(v37_ < 1)
		local v38_ = vehicle:getRepaintPrice()
		if v38_ >= 1 then
			self.repaintButton:setText(string.format("%s (%s)", g_i18n:getText("button_repaint"), g_i18n:formatMoney(v38_, 0, true, true)))
		else
			self.repaintButton:setLocaKey("button_repaint")
		end
		self.repaintButton:setDisabled(v38_ < 1 and true or vehicle.propertyState == VehiclePropertyState.MISSION)
	end
	self.configButton:setDisabled(not self.canBeConfigured)
	self.configButton:setVisible(Platform.gameplay.hasVehicleConfigs)
	self.sellButton:setDisabled(vehicle == nil and true or (self.isOwnWorkshop or (self.vehicle.propertyState == VehiclePropertyState.MISSION and true or not self.canBeSold)))
	local v39_ = self.sellButton
	local v40_ = vehicle ~= nil and not self.isOwnWorkshop
	if v40_ then
		v40_ = self.vehicle.propertyState ~= VehiclePropertyState.MISSION
	end
	v39_:setVisible(v40_)
	local v41_ = self.repaintButton
	local v42_ = not self.isOwnWorkshop
	if v42_ then
		v42_ = Platform.gameplay.hasVehicleDamage
	end
	v41_:setVisible(v42_)
	self.repairButton:setVisible(Platform.gameplay.hasVehicleDamage)
	self.dialogInfo:setVisible(vehicle == nil)
	self.buttonsBox:invalidateLayout()
end

function WorkshopScreen:setButtonText(text)
	self.sellButton:setText(text)
end

-- Local values: fullWidth, minSize
function WorkshopScreen:setStatusBarValue(bar, value)
	local v47_ = (bar.lastStatusBarValue or -1) - value
	if math.abs(v47_) > 0.01 then
		local v48_ = bar.parent.size[1] - bar.margin[1] * 2
		local v49_ = bar.startSize == nil and 0 or bar.startSize[1] + bar.endSize[1]
		local v50_ = v48_ * math.min(value, 1)
		bar:setSize(math.max(v49_, v50_), nil)
		bar.lastStatusBarValue = value
	end
end

-- Local values: balance
function WorkshopScreen:updateBalanceText()
	local v52_ = g_currentMission == nil and 0 or (g_currentMission:getMoney() or 0)
	self.lastBalance = v52_
	self.balanceElement:setValue(v52_)
	if v52_ > 0 then
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

-- Local values: text, callback, target, yesSound
function WorkshopScreen:onClickRepair()
	if self.vehicle == nil or self.vehicle:getRepairPrice(true) < 1 then
		return false
	end
	local v55_ = string.format(g_i18n:getText("ui_repairDialog"), g_i18n:formatMoney(self.vehicle:getRepairPrice(true)))
	local v56_ = self.onYesNoRepairDialog
	local v57_ = GuiSoundPlayer.SOUND_SAMPLES.CONFIG_WRENCH
	YesNoDialog.show(v56_, self, v55_, nil, nil, nil, nil, v57_)
	return true
end

-- Local values: text, callback, target, yesSound
function WorkshopScreen:onClickRepaint()
	if self.vehicle == nil or self.vehicle:getRepaintPrice() < 1 then
		return false
	end
	local v59_ = string.format(g_i18n:getText("ui_repaintDialog"), g_i18n:formatMoney(self.vehicle:getRepaintPrice()))
	local v60_ = self.onYesNoRepaintDialog
	local v61_ = GuiSoundPlayer.SOUND_SAMPLES.CONFIG_SPRAY
	YesNoDialog.show(v60_, self, v59_, nil, nil, nil, nil, v61_)
	return true
end

-- Local values: changePrice, vehicle, storeItem
function WorkshopScreen:onClickConfigure()
	if not self.canBeConfigured then
		return true
	end
	local v63_ = EconomyManager.CONFIG_CHANGE_PRICE
	local v64_ = self.isOwnWorkshop and 0 or v63_
	local v65_ = self.vehicle
	local v66_ = self.storeItem
	self:changeScreen(ShopConfigScreen, nil, WorkshopScreen)
	g_shopConfigScreen:setReturnScreenClass(WorkshopScreen)
	g_shopConfigScreen:setStoreItem(v66_, v65_, nil, v64_)
	g_shopConfigScreen:setCallbacks(self.setConfigurations, self)
	return false
end

-- Local values: storeItem
function WorkshopScreen:onClickSell()
	if self.vehicle == nil or (self.isOwnWorkshop or (self.vehicle.propertyState == VehiclePropertyState.MISSION or not self.canBeSold)) then
		return true
	end
	local v68_ = g_storeManager:getItemByXMLFilename(self.vehicle.configFileName)
	g_shopController:sell(v68_, self.vehicle, true)
	return false
end

function WorkshopScreen:getNumberOfItemsInSection(list, section)
	return #self.vehicles
end

-- Local values: vehicle, brandName, brand
function WorkshopScreen:populateCellForItemInSection(list, section, index, cell)
	local v73_ = self.vehicles[index]
	cell:getAttribute("icon"):setImageFilename(v73_:getImageFilename())
	local v74_ = g_brandManager:getBrandByIndex(v73_:getBrand())
	local v75_ = v74_ == nil and "" or v74_.title .. " "
	cell:getAttribute("name"):setText(v75_ .. v73_:getName())
	self:setVehicleDetails(self.vehicles[index], cell)
end

-- Local values: age, operatingTime, sellPrice, minutes, hours
function WorkshopScreen:setVehicleDetails(vehicle, cell)
	local v79_, v80_
	if vehicle == nil then
		v79_ = 0
		v80_ = 0
	else
		v79_ = vehicle:getOperatingTime()
		v80_ = vehicle.age
		if vehicle.propertyState == VehiclePropertyState.OWNED then
			local v81_ = vehicle:getSellPrice() * EconomyManager.DIRECT_SELL_MULTIPLIER
			local v82_ = math.floor(v81_)
			local v83_ = math.min(v82_, vehicle:getPrice())
			cell:getAttribute("priceText"):setText(g_i18n:formatMoney(v83_))
		elseif vehicle.propertyState == VehiclePropertyState.LEASED then
			cell:getAttribute("priceText"):setText("-")
		elseif vehicle.propertyState == VehiclePropertyState.MISSION then
			cell:getAttribute("priceText"):setText("-")
		end
		if vehicle.getWearTotalAmount ~= nil then
			self:setStatusBarValue(cell:getAttribute("paintConditionBar"), 1 - vehicle:getWearTotalAmount())
		end
		local v84_ = cell:getAttribute("paintConditionBar").parent
		local v85_ = Platform.gameplay.hasVehicleDamage
		if v85_ then
			v85_ = vehicle.getWearTotalAmount ~= nil
		end
		v84_:setVisible(v85_)
		if vehicle.getDamageAmount ~= nil then
			self:setStatusBarValue(cell:getAttribute("conditionBar"), 1 - vehicle:getDamageAmount())
		end
		local v86_ = cell:getAttribute("conditionBar").parent
		local v87_ = Platform.gameplay.hasVehicleDamage
		if v87_ then
			v87_ = vehicle.getDamageAmount ~= nil
		end
		v86_:setVisible(v87_)
	end
	local v88_ = v79_ / 60000
	local v89_ = v88_ / 60
	local v90_ = math.floor(v89_)
	local v91_ = (v88_ - v90_ * 60) / 6
	local v92_ = math.floor(v91_) * 10
	cell:getAttribute("operatingHoursText"):setText(string.format(g_i18n:getText("shop_operatingTime"), v90_, v92_))
	cell:getAttribute("ageText"):setText(string.format(g_i18n:getText("shop_age"), string.format("%d", v80_)))
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

-- Local values: text
function WorkshopScreen:onVehicleSold(sellPrice, isOwned, ownerFarmId)
	local v101_ = g_i18n:getText("shop_messageSoldVehicle")
	if not isOwned then
		v101_ = g_i18n:getText("shop_messageReturnedVehicle")
	end
	InfoDialog.show(v101_, self.onInfoDialogCallback, self, DialogElement.TYPE_INFO)
end

-- Local values: text
function WorkshopScreen:onVehicleSellFailed(isOwned, errorCode)
	local v104_
	if isOwned then
		if errorCode == SellVehicleEvent.SELL_NO_PERMISSION then
			v104_ = g_i18n:getText("shop_messageNoPermissionToSellVehicleText")
		elseif errorCode == SellVehicleEvent.SELL_VEHICLE_IN_USE then
			v104_ = g_i18n:getText("shop_messageSellVehicleInUse")
		else
			v104_ = g_i18n:getText("shop_messageFailedToSellVehicle")
		end
	elseif errorCode == SellVehicleEvent.SELL_NO_PERMISSION then
		v104_ = g_i18n:getText("shop_messageNoPermissionToReturnVehicleText")
	elseif errorCode == SellVehicleEvent.SELL_VEHICLE_IN_USE then
		v104_ = g_i18n:getText("shop_messageReturnVehicleInUse")
	else
		v104_ = g_i18n:getText("shop_messageFailedToReturnVehicle")
	end
	InfoDialog.show(v104_)
end

function WorkshopScreen:onVehicleChanged(success)
	if self.owner ~= nil then
		self.owner:openMenu()
	end
	if success then
		InfoDialog.show(g_i18n:getText("shop_messageConfigurationChanged"), self.onInfoDialogCallback, self, DialogElement.TYPE_INFO)
	else
		InfoDialog.show(g_i18n:getText("shop_messageConfigurationChangeFailed"), self.onInfoDialogCallback, self)
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
	if isDirectSell then
		if errorCode == SellVehicleEvent.SELL_SUCCESS then
			self:onVehicleSold(sellPrice, isOwned, ownerFarmId)
		else
			self:onVehicleSellFailed(isOwned, errorCode)
		end
	else
		return
	end
end
