-- Local values: InGameMenuStatisticsFrame_mt
InGameMenuStatisticsFrame = {}
local InGameMenuStatisticsFrame_mt = Class(InGameMenuStatisticsFrame, TabbedMenuFrameElement)
InGameMenuStatisticsFrame.COLUMN_NAME = 1
InGameMenuStatisticsFrame.COLUMN_AGE = 2
InGameMenuStatisticsFrame.COLUMN_HOURS = 3
InGameMenuStatisticsFrame.COLUMN_HOLDER = 3
InGameMenuStatisticsFrame.COLUMN_DAMAGE = 4
InGameMenuStatisticsFrame.COLUMN_LEASING = 5
InGameMenuStatisticsFrame.COLUMN_VALUE = 6
InGameMenuStatisticsFrame.SORT_ORDER_DESC = 1
InGameMenuStatisticsFrame.SORT_ORDER_ASC = 2
InGameMenuStatisticsFrame.FINANCES = {
	["PAST_PERIOD_COUNT"] = GS_IS_MOBILE_VERSION and 3 or 4,
	["LOAN_STEP"] = 5000
}
InGameMenuStatisticsFrame.SUB_CATEGORY = {
	["PRICES"] = 1,
	["VEHICLE_OVERVIEW"] = 2,
	["HANDTOOLS"] = 3,
	["FINANCES"] = 4,
	["STATISTICS"] = 5
}
InGameMenuStatisticsFrame.CELL_NAME_DETAIL = "detailTemplate"
InGameMenuStatisticsFrame.CELL_NAME_VALUE = "valueTemplate"
InGameMenuStatisticsFrame.CELL_NAME_FILL_TYPES = "fillTypesTemplate"
InGameMenuStatisticsFrame.CELL_NAME_PRODUCT = "fillTypeCell"
InGameMenuStatisticsFrame.CELL_NAME_STATION = "sellingStationCell"
function InGameMenuStatisticsFrame.register()
	local v2_ = InGameMenuStatisticsFrame.new()
	g_gui:loadGui("dataS/gui/InGameMenuStatisticsFrame.xml", "StatisticsFrame", v2_, true)
end

-- Upvalues: InGameMenuStatisticsFrame_mt
-- Local values: self
function InGameMenuStatisticsFrame.new(target, custom_mt)
	-- upvalues: (copy) InGameMenuStatisticsFrame_mt
	local v5_ = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuStatisticsFrame_mt)
	v5_.isInitialized = false
	v5_.statsIndices = {}
	v5_.statisticsLists = {}
	v5_.client = nil
	v5_.environment = nil
	v5_.playerFarm = nil
	v5_.currentMoneyUnitText = ""
	v5_.updateTimeFinancesStats = 0
	v5_.menuButtonInfo = {}
	v5_.hasCustomMenuButtons = true
	v5_.fillTypes = {}
	v5_.currentStationData = {}
	v5_.currentAcceptedFillTypes = {}
	v5_.clonedPricesElements = {}
	v5_.monthTexts = {}
	v5_.fluctuationPoints = {}
	v5_.sellingStationMode = false
	v5_.vehicles = {}
	v5_.sortByColumn = InGameMenuStatisticsFrame.COLUMN_NAME
	v5_.sortOrder = InGameMenuStatisticsFrame.SORT_ORDER_ASC
	v5_.sortIcons = {}
	v5_.detailsCache = {}
	v5_.detailsTemplates = {}
	v5_.clonedElements = {}
	v5_.marqueeBoxes = {}
	v5_.handTools = {}
	v5_.sortByColumnHandTools = InGameMenuStatisticsFrame.COLUMN_NAME
	v5_.sortOrderHandTools = InGameMenuStatisticsFrame.SORT_ORDER_ASC
	v5_.sortIconsHandTools = {}
	return v5_
end

-- Local values: newGui
function InGameMenuStatisticsFrame.createFromExistingGui(gui, guiName)
	local v8_ = InGameMenuStatisticsFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v8_, true)
	return v8_
end

-- Local values: k, clonedElement, k, clone, k, clone, k, cell, l, clone
function InGameMenuStatisticsFrame:delete()
	self.separatorTemplate:delete()
	self.monthTextTemplate:delete()
	for v10_, v11_ in pairs(self.clonedPricesElements) do
		v11_:delete()
		self.clonedPricesElements[v10_] = nil
	end
	for v12_, v13_ in pairs(self.clonedElements) do
		v13_:delete()
		self.clonedElements[v12_] = nil
	end
	for v14_, v15_ in pairs(self.detailsTemplates) do
		v15_:delete()
		self.detailsTemplates[v14_] = nil
	end
	for v16_, v17_ in pairs(self.detailsCache) do
		for v18_, v19_ in pairs(v17_) do
			v19_:delete()
			self.detailsCache[v16_][v18_] = nil
		end
		self.detailsCache[v16_] = nil
	end
	self.vehicles = {}
	self.handTools = {}
	InGameMenuStatisticsFrame:superClass().delete(self)
end

-- Local values: index, button, clonedText, clonedSeparator, i, oldSmoothScrollTo, oldSliderValueChanged
function InGameMenuStatisticsFrame:initialize()
	InGameMenuStatisticsFrame:superClass().initialize(self)
	for v_u_21_, v22_ in pairs(self.subCategoryTabs) do
		v22_:getDescendantByName("background").getIsSelected = function()
			-- upvalues: (copy) v_u_21_, (copy) self
			return v_u_21_ == self.subCategoryPaging:getState()
		end
		function v22_.getIsSelected()
			-- upvalues: (copy) v_u_21_, (copy) self
			return v_u_21_ == self.subCategoryPaging:getState()
		end
	end
	self.separatorTemplate:unlinkElement()
	self.monthTextTemplate:unlinkElement()
	FocusManager:removeElement(self.separatorTemplate)
	FocusManager:removeElement(self.monthTextTemplate)
	self.separatorTemplate:clone(self.fluctuationsLayoutBg)
	for v23_ = 1, 12 do
		local v24_ = self.monthTextTemplate:clone(self.fluctuationsLayoutBg)
		v24_:setText(g_i18n:formatPeriod(v23_, true))
		local v25_ = self.clonedPricesElements
		table.insert(v25_, v24_)
		local v26_ = self.monthTexts
		table.insert(v26_, v24_)
		local v27_ = self.separatorTemplate:clone(self.fluctuationsLayoutBg)
		local v28_ = self.clonedPricesElements
		table.insert(v28_, v27_)
	end
	self.fluctuationsLayoutBg:invalidateLayout()
	self.backButtonInfo = {
		["inputAction"] = InputAction.MENU_BACK
	}
	self.nextPageButtonInfo = {
		["inputAction"] = InputAction.MENU_PAGE_NEXT,
		["text"] = g_i18n:getText("ui_ingameMenuNext"),
		["callback"] = self.onPageNext
	}
	self.prevPageButtonInfo = {
		["inputAction"] = InputAction.MENU_PAGE_PREV,
		["text"] = g_i18n:getText("ui_ingameMenuPrev"),
		["callback"] = self.onPagePrevious
	}
	self.menuButtonInfoDefault = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
	self.hotspotButtonInfo = {
		["inputAction"] = InputAction.MENU_ACCEPT,
		["text"] = InGameMenuStatisticsFrame.L10N_SYMBOL.SET_MARKER,
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonHotspot()
		end
	}
	self.sellingStationModeButtonInfo = {
		["inputAction"] = InputAction.MENU_CANCEL,
		["text"] = InGameMenuStatisticsFrame.L10N_SYMBOL.LIST_STATIONS,
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonChangeSellingStationMode()
		end
	}
	self.menuButtonInfoPrices = {
		self.backButtonInfo,
		self.nextPageButtonInfo,
		self.prevPageButtonInfo,
		self.sellingStationModeButtonInfo
	}
	self.menuButtonInfoPricesWithHotspot = {
		self.backButtonInfo,
		self.nextPageButtonInfo,
		self.prevPageButtonInfo,
		self.sellingStationModeButtonInfo,
		self.hotspotButtonInfo
	}
	self.menuButtonInfo[InGameMenuStatisticsFrame.SUB_CATEGORY.PRICES] = self.menuButtonInfoDefault
	self.sellVehicleButtonInfo = {
		["inputAction"] = InputAction.MENU_CANCEL,
		["text"] = g_i18n:getText("button_sell"),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonSell()
		end
	}
	self.returnVehicleButtonInfo = {
		["inputAction"] = InputAction.MENU_CANCEL,
		["text"] = g_i18n:getText("button_return"),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonSell()
		end
	}
	self.viewVehicleOnMapButtonInfo = {
		["inputAction"] = InputAction.MENU_ACTIVATE,
		["text"] = g_i18n:getText("button_viewOnMap"),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onVehicleViewOnMap()
		end
	}
	self.menuButtonInfo[InGameMenuStatisticsFrame.SUB_CATEGORY.VEHICLE_OVERVIEW] = {
		self.backButtonInfo,
		self.nextPageButtonInfo,
		self.prevPageButtonInfo,
		self.viewVehicleOnMapButtonInfo,
		self.sellVehicleButtonInfo
	}
	self:buildCellDatabase()
	self.sellHandToolButtonInfo = {
		["inputAction"] = InputAction.MENU_CANCEL,
		["text"] = g_i18n:getText("button_sell"),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonSellHandTool()
		end
	}
	self.storeHandToolButtonInfo = {
		["inputAction"] = InputAction.MENU_ACTIVATE,
		["text"] = g_i18n:getText("button_store"),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onStoreHandTool()
		end
	}
	self.pickUpHandToolButtonInfo = {
		["inputAction"] = InputAction.MENU_ACTIVATE,
		["text"] = g_i18n:getText("button_pickUp"),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onPickUpHandTool()
		end
	}
	self.borrowButtonInfo = {
		["inputAction"] = InputAction.MENU_ACTIVATE,
		["text"] = "",
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonBorrow()
		end
	}
	self.repayButtonInfo = {
		["inputAction"] = InputAction.MENU_CANCEL,
		["text"] = "",
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonRepay()
		end
	}
	self.menuButtonInfo[InGameMenuStatisticsFrame.SUB_CATEGORY.FINANCES] = {
		self.backButtonInfo,
		self.nextPageButtonInfo,
		self.prevPageButtonInfo,
		self.borrowButtonInfo,
		self.repayButtonInfo
	}
	self.menuButtonInfo[InGameMenuStatisticsFrame.SUB_CATEGORY.STATISTICS] = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
	local v_u_29_ = self.statisticsList1.smoothScrollTo
	function self.statisticsList1.smoothScrollTo(_, p30_)
		-- upvalues: (copy) v_u_29_, (copy) self
		v_u_29_(self.statisticsList1, p30_)
		v_u_29_(self.statisticsList2, p30_)
	end
	function self.statisticsList2.smoothScrollTo(_, p31_)
		-- upvalues: (copy) v_u_29_, (copy) self
		v_u_29_(self.statisticsList1, p31_)
		v_u_29_(self.statisticsList2, p31_)
	end
	local v_u_32_ = self.statisticsList1.onSliderValueChanged
	function self.statisticsList1.onSliderValueChanged(_, p33_, p34_, p35_)
		-- upvalues: (copy) v_u_32_, (copy) self
		v_u_32_(self.statisticsList1, p33_, p34_, p35_)
		v_u_32_(self.statisticsList2, p33_, p34_, p35_)
	end
	self.subCategoryPaging:setState(1)
end

-- Local values: previousButton, _, icon, button
function InGameMenuStatisticsFrame:onGuiSetupFinished()
	InGameMenuStatisticsFrame:superClass().onGuiSetupFinished(self)
	local v37_ = nil
	for _, v38_ in pairs(self.sortIcons) do
		local v39_ = v38_[InGameMenuStatisticsFrame.SORT_ORDER_ASC].parent
		if v37_ == nil then
			FocusManager:linkElements(self.vehiclesList, FocusManager.TOP, v39_)
			FocusManager:linkElements(self.vehiclesList, FocusManager.LEFT, v39_)
		else
			FocusManager:linkElements(v39_, FocusManager.LEFT, v37_)
			FocusManager:linkElements(v37_, FocusManager.RIGHT, v39_)
		end
		v37_ = v39_
	end
	FocusManager:linkElements(self.vehiclesList, FocusManager.RIGHT, v37_)
end

-- Local values: listIndex, list, statsPerList, k, _
function InGameMenuStatisticsFrame:initializeLists()
	if not self.isInitialized then
		local v41_ = self.statisticsLists
		local v42_ = self.statisticsList1
		table.insert(v41_, v42_)
		if self.statisticsList2 ~= nil then
			if GS_IS_MOBILE_VERSION then
				self.statisticsList2:delete()
			else
				local v43_ = self.statisticsLists
				local v44_ = self.statisticsList2
				table.insert(v43_, v44_)
			end
		end
		self.statsData = self.playerFarm.stats:getStatisticData()
		local v45_ = #self.statsData / 2
		local v46_ = math.ceil(v45_)
		local v47_ = nil
		local v48_ = 0
		for v49_, _ in ipairs(self.statsData) do
			if v47_ == nil or v46_ <= #self.statsIndices[v47_] then
				v48_ = v48_ + 1
				v47_ = self.statisticsLists[v48_]
				if v47_ == nil then
					break
				end
				self.statsIndices[v47_] = {}
			end
			local v50_ = self.statsIndices[v47_]
			table.insert(v50_, v49_)
		end
		self.isInitialized = true
	end
end

function InGameMenuStatisticsFrame:getMenuButtonInfo()
	return self.menuButtonInfo[self.subCategoryPaging:getState()]
end

-- Local values: mission, isMultiplayer, isSingleplayerOrIsInFarm, subCategories, index, button, subCategoryIndex
function InGameMenuStatisticsFrame:onFrameOpen(element)
	local v53_ = g_currentMission
	self.itemDetailsMap:setIngameMap(v53_.hud:getIngameMap())
	InGameMenuStatisticsFrame:superClass().onFrameOpen(self)
	local v54_ = v53_.missionDynamicInfo.isMultiplayer
	local v55_ = not v54_ or g_localPlayer.farmId ~= FarmManager.SPECTATOR_FARM_ID
	local v56_ = {}
	for v57_, v58_ in pairs(self.subCategoryTabs) do
		if v57_ == InGameMenuStatisticsFrame.SUB_CATEGORY.STATISTICS then
			v58_:setVisible(not v54_)
			if not v54_ then
				local v59_ = tostring(v57_)
				table.insert(v56_, v59_)
			end
		else
			v58_:setVisible(v55_)
			if v55_ then
				local v60_ = tostring(v57_)
				table.insert(v56_, v60_)
			end
		end
	end
	self.subCategoryBox:invalidateLayout()
	self.subCategoryPaging:setTexts(v56_)
	self.subCategoryPaging:setSize(self.subCategoryBox.maxFlowSize + 140 * g_pixelSizeScaledX)
	self:onMoneyChange()
	g_messageCenter:subscribe(MessageType.MONEY_CHANGED, self.onMoneyChange, self)
	self:updateMoneyUnit()
	self:updateFinances()
	self:updateFinancesLoanButtons()
	g_messageCenter:subscribe(PlayerPermissionsEvent, self.updateFinancesLoanButtons, self)
	g_messageCenter:subscribe(ChangeLoanEvent, self.updateFinances, self)
	self:initializeLists()
	self:updateStatistics()
	self:updateVehicles()
	self.detailBox:setVisible(#self.vehicles > 0)
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.MONEY_UNIT], self.updateVehicles, self)
	g_messageCenter:subscribe(MessageType.VEHICLE_REMOVED, self.onVehicleSellEvent, self)
	g_messageCenter:subscribe(MessageType.VEHICLE_ADDED, self.onVehicleBuyEvent, self)
	if self.customFilter ~= nil then
		self.ingameMapBase:applyCustomFilter(self.customFilter)
	end
	self:updateHandTools()
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.MONEY_UNIT], self.updateHandTools, self)
	g_messageCenter:subscribe(MessageType.HANDTOOL_REMOVED, self.onHandToolSellEvent, self)
	g_messageCenter:subscribe(MessageType.HANDTOOL_ADDED, self.onHandToolBuyEvent, self)
	g_messageCenter:subscribe(HandToolSetHolderEvent, self.onHandToolSetHolderEvent, self)
	self:rebuildTable()
	self:updateTodayBar()
	g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.onHourChanged, self)
	local v61_ = self.subCategoryPaging:getState()
	self:updateSubCategoryPages(v61_)
	if v61_ == InGameMenuStatisticsFrame.SUB_CATEGORY.PRICES then
		FocusManager:setFocus(self.productList)
		return
	elseif v61_ == InGameMenuStatisticsFrame.SUB_CATEGORY.VEHICLE_OVERVIEW then
		FocusManager:setFocus(self.vehiclesList)
		return
	elseif v61_ == InGameMenuStatisticsFrame.SUB_CATEGORY.FINANCES then
		FocusManager:setFocus(self.financesList)
	end
end

-- Local values: mission
function InGameMenuStatisticsFrame:onFrameClose()
	InGameMenuStatisticsFrame:superClass().onFrameClose(self)
	g_messageCenter:unsubscribeAll(self)
	g_currentMission:showMoneyChange(MoneyType.LOAN)
	self.itemDetailsMap:onClose()
	self.ingameMapBase:restoreDefaultFilter()
	self.currentStationData = {}
end

function InGameMenuStatisticsFrame:setInGameMap(ingameMap)
	self.itemDetailsMap:setIngameMap(ingameMap)
	self.ingameMapBase = ingameMap
	if ingameMap ~= nil then
		self.customFilter = ingameMap:createCustomFilter(true)
	end
end

-- Local values: mission, farm, i
function InGameMenuStatisticsFrame:update(dt)
	InGameMenuStatisticsFrame:superClass().update(self, dt)
	self:updateMarqueeAnimation(dt)
	local v67_ = g_currentMission
	if not v67_:getIsServer() and self.updateTimeFinancesStats < v67_.time then
		self.updateTimeFinancesStats = v67_.time + 5000
		local v68_ = g_farmManager:getFarmById(g_localPlayer.farmId)
		if v68_.stats.financesHistoryVersionCounter ~= v68_.stats.financesHistoryVersionCounterLocal then
			v68_.stats.financesHistoryVersionCounterLocal = v68_.stats.financesHistoryVersionCounter
			for v69_ = 1, InGameMenuStatisticsFrame.FINANCES.PAST_PERIOD_COUNT do
				self.client:getServerConnection():sendEvent(FinanceStatsEvent.new(v69_, v68_.farmId))
			end
		end
	end
end

-- Local values: isPricesFrame, i, yPos, yPosEnd, xPos, xPosEnd
function InGameMenuStatisticsFrame:draw()
	local v71_ = self.subCategoryPaging:getState() == InGameMenuStatisticsFrame.SUB_CATEGORY.PRICES
	if v71_ and (self.hasAnyFluctuations and not self.sellingStationMode) then
		drawDashedLine(self.todayBar.absPosition[1], self.todayBar.absPosition[2] + self.todayBar.absSize[2], self.todayBar.absSize[1], self.todayBar.absSize[2], -7 * g_pixelSizeY, -6 * g_pixelSizeY, 1, 1, 1, 1, false)
	end
	InGameMenuStatisticsFrame:superClass().draw(self)
	if v71_ and (self.hasAnyFluctuations and not self.sellingStationMode) then
		for v72_, v73_ in pairs(self.fluctuationPoints) do
			local v74_ = self.fluctuationPoints[v72_ + 1]
			if v74_ ~= nil then
				local v75_ = self.monthTexts[v72_].absPosition[1] + self.monthTexts[v72_].absSize[1] * 0.5
				local v76_ = self.monthTexts[v72_ + 1].absPosition[1] + self.monthTexts[v72_ + 1].absSize[1] * 0.5
				drawLine2D(v75_, v73_ + self.fluctuationsContainer.absPosition[2], v76_, v74_ + self.fluctuationsContainer.absPosition[2], g_pixelSizeX * 4, 1, 1, 1, 1)
			end
		end
	end
end

-- Local values: box, time, contentWidth, visibleWidth, scrollAmount, scrollLengthFactor, scrollDuration, alpha, offset
function InGameMenuStatisticsFrame:updateMarqueeAnimation(dt)
	for v79_, v80_ in pairs(self.marqueeBoxes) do
		local v81_ = v79_.absSize[1]
		local v82_ = v79_.parent.absSize[1]
		local v83_ = v81_ - v82_
		local v84_ = 5000 * (v81_ / v82_)
		local v85_ = v80_ + dt
		if v84_ <= v85_ then
			v85_ = -v84_
		end
		v79_:setPosition(-(v83_ * MathUtil.smoothstep(0.1, 0.9, math.abs(v85_) / v84_)))
		self.marqueeBoxes[v79_] = v85_
	end
end

function InGameMenuStatisticsFrame:getData()
	return self.playerFarm.stats:getStatisticData()
end

-- Local values: mission, accessHandler, _, vehicle, item, name, text, value, opHoursText, opHoursValue, damageText, damageValue, leasingText, leasingValue, sellValueText, sellValue
function InGameMenuStatisticsFrame:updateVehicles()
	self.vehicles = {}
	if g_localPlayer ~= nil then
		local v88_ = g_currentMission
		local v89_ = v88_.accessHandler
		for _, v90_ in ipairs(v88_.vehicleSystem.vehicles) do
			if v89_:canPlayerAccess(v90_) and (v90_:getShowInVehiclesOverview() and g_localPlayer.farmId == v90_:getOwnerFarmId()) then
				local v91_ = {
					["vehicle"] = v90_,
					["columns"] = {}
				}
				local v92_ = v90_:getFullName()
				v91_.columns[InGameMenuStatisticsFrame.COLUMN_NAME] = {
					["text"] = v92_,
					["value"] = v92_
				}
				local v93_ = {
					["text"] = Vehicle.getSpecValueAge(nil, v90_),
					["value"] = v90_.age
				}
				v91_.columns[InGameMenuStatisticsFrame.COLUMN_AGE] = v93_
				local v94_, v95_
				if v90_.getOperatingTime == nil then
					v94_ = "-"
					v95_ = 0
				else
					v94_ = Vehicle.getSpecValueOperatingTime(nil, v90_)
					v95_ = v90_:getOperatingTime()
				end
				v91_.columns[InGameMenuStatisticsFrame.COLUMN_HOURS] = {
					["text"] = v94_,
					["value"] = v95_
				}
				local v96_, v97_
				if SpecializationUtil.hasSpecialization(Wearable, v90_.specializations) then
					v96_ = v90_:getDamageAmount()
					local v98_ = g_i18n
					local v99_ = (1 - v96_) * 100
					v97_ = v98_:formatNumber(math.ceil(v99_), 0) .. " %"
				else
					v97_ = "-"
					v96_ = 0
				end
				v91_.columns[InGameMenuStatisticsFrame.COLUMN_DAMAGE] = {
					["text"] = v97_,
					["value"] = v96_
				}
				local v100_, v101_
				if v90_.propertyState == VehiclePropertyState.LEASED then
					v100_ = v90_.price * (EconomyManager.DEFAULT_RUNNING_LEASING_FACTOR + EconomyManager.PER_DAY_LEASING_FACTOR)
					v101_ = g_i18n:formatMoney(v100_)
				else
					v101_ = "-"
					v100_ = 0
				end
				v91_.columns[InGameMenuStatisticsFrame.COLUMN_LEASING] = {
					["text"] = v101_,
					["value"] = v100_
				}
				local v102_, v103_
				if v90_.propertyState == VehiclePropertyState.OWNED then
					v102_ = v90_:getSellPrice()
					v103_ = g_i18n:formatMoney(v102_)
				else
					v103_ = "-"
					v102_ = 0
				end
				v91_.columns[InGameMenuStatisticsFrame.COLUMN_VALUE] = {
					["text"] = v103_,
					["value"] = v102_
				}
				local v104_ = self.vehicles
				table.insert(v104_, v91_)
			end
		end
	end
	self:updateView()
end

-- Local values: sortByColumn, sortOrder, column, icons, isSortedByColumn
function InGameMenuStatisticsFrame:updateView()
	local v_u_106_ = self.sortByColumn
	local v_u_107_ = self.sortOrder
	for v108_, v109_ in pairs(self.sortIcons) do
		local v110_ = v108_ == v_u_106_
		local v111_ = v109_[InGameMenuStatisticsFrame.SORT_ORDER_DESC]
		local v112_
		if v110_ then
			v112_ = v_u_107_ == InGameMenuStatisticsFrame.SORT_ORDER_DESC
		else
			v112_ = v110_
		end
		v111_:setVisible(v112_)
		local v113_ = v109_[InGameMenuStatisticsFrame.SORT_ORDER_ASC]
		if v110_ then
			v110_ = v_u_107_ == InGameMenuStatisticsFrame.SORT_ORDER_ASC
		end
		v113_:setVisible(v110_)
	end
	table.sort(self.vehicles, function(p114_, p115_)
		-- upvalues: (copy) v_u_106_, (copy) v_u_107_
		local v116_ = p114_.columns[v_u_106_].value
		local v117_ = p115_.columns[v_u_106_].value
		if v116_ == v117_ then
			v116_ = p114_.columns[InGameMenuStatisticsFrame.COLUMN_NAME].value
			v117_ = p115_.columns[InGameMenuStatisticsFrame.COLUMN_NAME].value
			if v116_ == v117_ then
				v116_ = p114_.columns[InGameMenuStatisticsFrame.COLUMN_VALUE].value
				v117_ = p115_.columns[InGameMenuStatisticsFrame.COLUMN_VALUE].value
			end
		end
		if v_u_107_ == InGameMenuStatisticsFrame.SORT_ORDER_DESC then
			return v117_ < v116_
		else
			return v116_ < v117_
		end
	end)
	self.vehiclesList:reloadData()
	self.detailBox:setVisible(self.vehiclesList:getItemCount() > 0)
	self:updateMenuButtons()
end

-- Local values: priceStr, defaultPrice, discount, price
function InGameMenuStatisticsFrame:getStoreItemDisplayPrice(storeItem, saleItem)
	if saleItem == nil then
		if storeItem.isInAppPurchase then
			return storeItem.price
		end
		local v120_ = g_currentMission.economyManager:getBuyPrice(storeItem)
		return g_i18n:formatMoney(v120_, 0, true, true)
	else
		local v121_ = StoreItemUtil.getPriceWithBoughtConfigurations(storeItem, saleItem.boughtConfigurations, "price")
		local v122_ = v121_ <= 0 and 0 or -(1 - saleItem.price / v121_) * 100
		return string.format("%s (%d%%)", g_i18n:formatMoney(saleItem.price, 0, true, true), v122_)
	end
end

-- Local values: layoutsToInvalidate, k, clone, layout, _, k, _, i, name, brand
function InGameMenuStatisticsFrame:assignItemAttributeData(displayItem)
	local v125_ = {}
	for v126_, v127_ in pairs(self.clonedElements) do
		if v125_[v127_.parent] == nil then
			v125_[v127_.parent] = true
		end
		v127_:delete()
		self.clonedElements[v126_] = nil
	end
	for v128_, _ in pairs(v125_) do
		v128_:invalidateLayout()
	end
	for v129_, _ in pairs(self.marqueeBoxes) do
		self.marqueeBoxes[v129_] = nil
	end
	for v130_ = #self.attributesLayout.elements, 1, -1 do
		self:queueDetailsCell(self.attributesLayout.elements[v130_])
	end
	self:assignItemTextData(displayItem)
	self:assignItemFillTypesData(InGameMenuStatisticsFrame.PROFILE.ICON_FILL_TYPES, displayItem.fillTypeIconFilenames)
	self:assignItemFillTypesData(InGameMenuStatisticsFrame.PROFILE.ICON_FILL_TYPES, displayItem.foodFillTypeIconFilenames)
	self:assignItemFillTypesData(InGameMenuStatisticsFrame.PROFILE.ICON_SEED_FILL_TYPES, displayItem.seedTypeIconFilenames)
	local v131_ = displayItem.storeItem.name
	if displayItem.concreteItem ~= nil and displayItem.concreteItem.getName ~= nil then
		v131_ = displayItem.concreteItem:getName()
	end
	local v132_ = g_brandManager:getBrandByIndex(displayItem.storeItem.brandIndex)
	if displayItem.concreteItem ~= nil and displayItem.concreteItem.getBrand ~= nil then
		v132_ = g_brandManager:getBrandByIndex(displayItem.concreteItem:getBrand())
	end
	if v132_ ~= nil and v132_.name ~= "NONE" then
		v131_ = v132_.title .. " " .. v131_
	end
	self.itemDetailsName:setText(v131_)
	self.itemDetailsImage:setVisible(displayItem.storeItem ~= nil)
	if displayItem.concreteItem ~= nil then
		self.itemDetailsImage:setImageFilename(displayItem.concreteItem:getImageFilename())
	end
	self.attributesLayout:invalidateLayout()
end

-- Local values: storeItem, i, value, cell, icon, text, profile
function InGameMenuStatisticsFrame:assignItemTextData(displayItem)
	if Platform.isMobile and self.attrVehicleValue ~= nil then
		local v135_ = displayItem.storeItem
		self.attrVehicleValue:setText(self:getStoreItemDisplayPrice(v135_))
		self.attrVehicleValue:setVisible(not v135_.isInAppPurchase)
		self.attrVehicleValueIcon:setVisible(not v135_.isInAppPurchase)
	end
	for v136_, v137_ in pairs(displayItem.attributeValues) do
		local v138_ = self:dequeueDetailsCell(InGameMenuStatisticsFrame.CELL_NAME_DETAIL)
		local v139_ = v138_:getDescendantByName("icon")
		local v140_ = v138_:getDescendantByName("text")
		local v141_ = displayItem.attributeIconProfiles[v136_]
		if v141_ ~= nil and v141_ ~= "" then
			v140_:setText(v137_)
			v139_:applyProfile(v141_)
		end
		v138_:setSize(v139_.absSize[1] + v139_.margin[1] + v140_.absSize[1], nil)
	end
end

-- Local values: totalWidth, cell, cellIcon, iconsLayout, _, iconFilename, icon, maxWidth, parentSize, iconsLayoutSize
function InGameMenuStatisticsFrame:assignItemFillTypesData(baseIconProfile, iconFilenames)
	if #iconFilenames > 0 then
		local v145_ = self:dequeueDetailsCell(InGameMenuStatisticsFrame.CELL_NAME_FILL_TYPES)
		local v146_ = v145_:getDescendantByName("icon")
		local v147_ = v145_:getDescendantByName("iconsLayout")
		v146_:applyProfile(baseIconProfile)
		local v148_ = 0
		for _, v149_ in pairs(iconFilenames) do
			local v150_ = self.fruitIconTemplate:clone(v147_)
			v150_:setVisible(true)
			local v151_ = self.clonedElements
			table.insert(v151_, v150_)
			v150_:applyProfile(InGameMenuStatisticsFrame.PROFILE.ICON_FRUIT_TYPE)
			v150_:setImageFilename(v149_)
			v148_ = v148_ + v150_.absSize[1] + v150_.margin[1] + v150_.margin[3]
		end
		local v152_ = self.attributesLayout.absSize[1] * 0.91
		local v153_ = math.min(v152_, v148_)
		local v154_ = v153_ + v146_.absSize[1] + v146_.margin[1]
		v147_:setSize(v148_, nil)
		v147_:setPosition(0, nil)
		v147_.parent:setSize(v153_, nil)
		v147_:invalidateLayout()
		if v154_ < v148_ then
			self.marqueeBoxes[v147_] = 0
			return
		end
		self.marqueeBoxes[v147_] = nil
	end
end

-- Local values: mission, accessHandler, _, handTool, item, name, brand, text, value, holderText, holder
function InGameMenuStatisticsFrame:updateHandTools()
	self.handTools = {}
	if g_localPlayer ~= nil then
		local v156_ = g_currentMission
		local v157_ = v156_.accessHandler
		for _, v158_ in ipairs(v156_.handToolSystem.handTools) do
			if v157_:canPlayerAccess(v158_) and (v158_:getShowInHandToolsOverview() and g_localPlayer.farmId == v158_:getOwnerFarmId()) then
				local v159_ = {
					["handTool"] = v158_,
					["columns"] = {}
				}
				local v160_ = v158_:getName()
				local v161_ = v158_.brand
				if v161_ ~= nil and v161_.title ~= "None" then
					v160_ = v161_.title .. " " .. v160_
				end
				v159_.columns[InGameMenuStatisticsFrame.COLUMN_NAME] = {
					["text"] = v160_,
					["value"] = v160_
				}
				local v162_ = {
					["text"] = Vehicle.getSpecValueAge(nil, v158_),
					["value"] = v158_.age
				}
				v159_.columns[InGameMenuStatisticsFrame.COLUMN_AGE] = v162_
				local v163_ = v158_:getHolder()
				local v164_ = v163_ == nil and "-" or v163_:getHolderName()
				v159_.columns[InGameMenuStatisticsFrame.COLUMN_HOLDER] = {
					["text"] = v164_,
					["value"] = v164_
				}
				local v165_ = self.handTools
				table.insert(v165_, v159_)
			end
		end
	end
	self:updateViewHandTools()
end

-- Local values: sortByColumn, sortOrder, column, icons, isSortedByColumn
function InGameMenuStatisticsFrame:updateViewHandTools()
	local v_u_167_ = self.sortByColumnHandTools
	local v_u_168_ = self.sortOrderHandTools
	for v169_, v170_ in pairs(self.sortIconsHandTools) do
		local v171_ = v169_ == v_u_167_
		local v172_ = v170_[InGameMenuStatisticsFrame.SORT_ORDER_DESC]
		local v173_
		if v171_ then
			v173_ = v_u_168_ == InGameMenuStatisticsFrame.SORT_ORDER_DESC
		else
			v173_ = v171_
		end
		v172_:setVisible(v173_)
		local v174_ = v170_[InGameMenuStatisticsFrame.SORT_ORDER_ASC]
		if v171_ then
			v171_ = v_u_168_ == InGameMenuStatisticsFrame.SORT_ORDER_ASC
		end
		v174_:setVisible(v171_)
	end
	table.sort(self.handTools, function(p175_, p176_)
		-- upvalues: (copy) v_u_167_, (copy) v_u_168_
		local v177_ = p175_.columns[v_u_167_].value
		local v178_ = p176_.columns[v_u_167_].value
		if v177_ == v178_ then
			v177_ = p175_.columns[InGameMenuStatisticsFrame.COLUMN_NAME].value
			v178_ = p176_.columns[InGameMenuStatisticsFrame.COLUMN_NAME].value
			if v177_ == v178_ then
				v177_ = p175_.columns[InGameMenuStatisticsFrame.COLUMN_HOLDER].value
				v178_ = p176_.columns[InGameMenuStatisticsFrame.COLUMN_HOLDER].value
			end
		end
		if v_u_168_ == InGameMenuStatisticsFrame.SORT_ORDER_DESC then
			return v178_ < v177_
		else
			return v177_ < v178_
		end
	end)
	self.handToolsList:reloadData()
end

-- Local values: _, list
function InGameMenuStatisticsFrame:updateStatistics()
	self.statsData = self.playerFarm.stats:getStatisticData()
	for _, v180_ in ipairs(self.statisticsLists) do
		v180_:reloadData()
	end
end

function InGameMenuStatisticsFrame:setClient(client)
	self.client = client
end

function InGameMenuStatisticsFrame:setEnvironment(environment)
	self.environment = environment
end

function InGameMenuStatisticsFrame:setPlayerFarm(playerFarm)
	self.playerFarm = playerFarm
end

-- Local values: currentPeriod, i, pastPeriod, stats
function InGameMenuStatisticsFrame:updateFinances()
	local v188_ = self.environment.currentPeriod
	for v189_ = 1, InGameMenuStatisticsFrame.FINANCES.PAST_PERIOD_COUNT do
		local v190_ = v188_ - v189_
		self.pastDayHeader[v189_]:setText(g_i18n:formatPeriod(v190_, false))
	end
	self.pastDayHeader[0]:setText(g_i18n:formatPeriod(v188_, false))
	self.financesList:reloadData()
	local v191_ = self.playerFarm.stats
	self:updateFinancesFooter(v191_.finances, v191_.financesHistory)
	self:updateFinancesLoanButtons()
end

-- Local values: allowChangeLoan, isBorrowEnabled, isRepayEnabled
function InGameMenuStatisticsFrame:updateFinancesLoanButtons()
	if Platform.gameplay.hasLoans then
		local v193_ = self:hasPlayerLoanPermission()
		local v194_
		if self.playerFarm.loan < self.playerFarm.loanMax then
			v194_ = v193_
		else
			v194_ = false
		end
		if self.playerFarm.loan > 0 then
			if self.playerFarm.money < InGameMenuStatisticsFrame.FINANCES.LOAN_STEP then
				v193_ = false
			end
		else
			v193_ = false
		end
		self.borrowButtonInfo.disabled = not v194_
		self.repayButtonInfo.disabled = not v193_
		self:setMenuButtonInfoDirty()
	end
end

-- Local values: borrowTemplate, text, repayTemplate
function InGameMenuStatisticsFrame:updateMoneyUnit()
	self.currentMoneyUnitText = g_i18n:getCurrencySymbol(true)
	if Platform.gameplay.hasLoans then
		local v196_ = g_i18n:getText(InGameMenuStatisticsFrame.L10N_SYMBOL.BUTTON_BORROW)
		local v197_ = string.gsub(v196_, InGameMenuStatisticsFrame.L10N_SYMBOL.CURRENCY, self.currentMoneyUnitText)
		self.borrowButtonInfo.text = v197_
		local v198_ = g_i18n:getText(InGameMenuStatisticsFrame.L10N_SYMBOL.BUTTON_REPAY)
		local v199_ = string.gsub(v198_, InGameMenuStatisticsFrame.L10N_SYMBOL.CURRENCY, self.currentMoneyUnitText)
		self.repayButtonInfo.text = v199_
	end
end

function InGameMenuStatisticsFrame:updateFinancesFooter(currentFinances, pastFinances)
	self:updateBalance()
	if Platform.gameplay.hasLoans then
		self:updateLoan()
	end
	self:updateDayTotals(currentFinances, pastFinances)
end

-- Local values: currentBalance, balanceMoneyText, balanceProfile
function InGameMenuStatisticsFrame:updateBalance()
	local v204_ = self.playerFarm:getBalance()
	local v205_ = g_i18n:formatMoney(v204_, 0, false)
	local v206_ = InGameMenuStatisticsFrame.PROFILE.VALUE_CELL_NEUTRAL
	if math.floor(v204_) <= -1 then
		v206_ = InGameMenuStatisticsFrame.PROFILE.VALUE_CELL_NEGATIVE
	end
	self.balanceText:applyProfile(v206_, true)
	self.balanceText:setText(v205_ .. " " .. self.currentMoneyUnitText)
end

-- Local values: i, dayFinances, pastIndex, dayTotalProfile, dayTotal, _, statName, totalMoneyText
function InGameMenuStatisticsFrame:updateDayTotals(currentFinances, pastFinances)
	for v210_ = 1, InGameMenuStatisticsFrame.FINANCES.PAST_PERIOD_COUNT + 1 do
		local v211_
		if v210_ > 1 then
			v211_ = pastFinances[#pastFinances - (v210_ - 2)]
		else
			v211_ = currentFinances
		end
		local v212_ = InGameMenuStatisticsFrame.PROFILE.VALUE_CELL_NEUTRAL
		if v211_ == nil then
			self.totalText[v210_]:setText("")
		else
			local v213_ = 0
			for _, v214_ in pairs(v211_.statNames) do
				v213_ = v213_ + v211_[v214_]
			end
			local v215_ = g_i18n:formatMoney(v213_, 0, false)
			if math.floor(v213_) <= -1 then
				v212_ = InGameMenuStatisticsFrame.PROFILE.VALUE_CELL_NEGATIVE
			end
			self.totalText[v210_]:setText(v215_ .. " " .. self.currentMoneyUnitText)
		end
		self.totalText[v210_]:applyProfile(v212_, true)
	end
end

-- Local values: currentLoan, loanMoneyText, loanProfile
function InGameMenuStatisticsFrame:updateLoan()
	local v217_ = self.playerFarm:getLoan()
	local v218_ = g_i18n:formatMoney(-v217_, 0, false)
	local v219_ = InGameMenuStatisticsFrame.PROFILE.VALUE_CELL_NEUTRAL
	if v217_ > 0 then
		v219_ = InGameMenuStatisticsFrame.PROFILE.VALUE_CELL_NEGATIVE
	end
	self.loanText:applyProfile(v219_, true)
	self.loanText:setText(v218_ .. " " .. self.currentMoneyUnitText)
end

-- Local values: mission
function InGameMenuStatisticsFrame:hasPlayerLoanPermission()
	return g_currentMission:getHasPlayerPermission("farmManager")
end

-- Local values: subCategoryIndex, mission, hotspot, item, vehicle, storeItem, _, currentHandToolIndex, buttons, currentHandTool, holder
function InGameMenuStatisticsFrame:updateMenuButtons()
	local v221_ = self.subCategoryPaging:getState()
	local v222_ = g_currentMission
	if v221_ == InGameMenuStatisticsFrame.SUB_CATEGORY.PRICES then
		if self.sellingStationMode then
			self.sellingStationModeButtonInfo.text = g_i18n:getText(InGameMenuStatisticsFrame.L10N_SYMBOL.LIST_COMMODITIES)
		else
			self.sellingStationModeButtonInfo.text = g_i18n:getText(InGameMenuStatisticsFrame.L10N_SYMBOL.LIST_STATIONS)
		end
		local v223_ = self:getSelectedHotspot()
		if v223_ == nil or (self.sellingStationMode or FocusManager:getFocusedElement() ~= self.priceList) and (not self.sellingStationMode or FocusManager:getFocusedElement() ~= self.productList) then
			self.menuButtonInfo[InGameMenuStatisticsFrame.SUB_CATEGORY.PRICES] = self.menuButtonInfoPrices
		else
			if v223_ == v222_.currentMapTargetHotspot then
				self.hotspotButtonInfo.text = g_i18n:getText(InGameMenuStatisticsFrame.L10N_SYMBOL.REMOVE_MARKER)
			else
				self.hotspotButtonInfo.text = g_i18n:getText(InGameMenuStatisticsFrame.L10N_SYMBOL.SET_MARKER)
			end
			self.menuButtonInfo[InGameMenuStatisticsFrame.SUB_CATEGORY.PRICES] = self.menuButtonInfoPricesWithHotspot
		end
	elseif v221_ == InGameMenuStatisticsFrame.SUB_CATEGORY.VEHICLE_OVERVIEW then
		table.removeElement(self.menuButtonInfo[InGameMenuStatisticsFrame.SUB_CATEGORY.VEHICLE_OVERVIEW], self.viewVehicleOnMapButtonInfo)
		table.removeElement(self.menuButtonInfo[InGameMenuStatisticsFrame.SUB_CATEGORY.VEHICLE_OVERVIEW], self.sellVehicleButtonInfo)
		table.removeElement(self.menuButtonInfo[InGameMenuStatisticsFrame.SUB_CATEGORY.VEHICLE_OVERVIEW], self.returnVehicleButtonInfo)
		local v224_ = self.vehicles[self.vehiclesList:getSelectedIndexInSection()]
		if v224_ ~= nil and v224_.vehicle ~= nil then
			table.addElement(self.menuButtonInfo[InGameMenuStatisticsFrame.SUB_CATEGORY.VEHICLE_OVERVIEW], self.viewVehicleOnMapButtonInfo)
			local v225_ = v224_.vehicle
			if g_storeManager:getItemByXMLFilename(v225_.configFileName).canBeSold then
				if v225_.propertyState == VehiclePropertyState.LEASED then
					table.addElement(self.menuButtonInfo[InGameMenuStatisticsFrame.SUB_CATEGORY.VEHICLE_OVERVIEW], self.returnVehicleButtonInfo)
				else
					table.addElement(self.menuButtonInfo[InGameMenuStatisticsFrame.SUB_CATEGORY.VEHICLE_OVERVIEW], self.sellVehicleButtonInfo)
				end
			end
		end
	elseif v221_ == InGameMenuStatisticsFrame.SUB_CATEGORY.HANDTOOLS then
		local _, v226_ = self.handToolsList:getSelectedPath()
		local v227_ = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
		if self.handToolsList:getItemCount() > 0 and self.handTools[v226_] ~= nil then
			local v228_ = self.handTools[v226_]
			local v229_ = v228_.handTool:getHolder()
			if v229_ == nil then
				local v230_ = self.sellHandToolButtonInfo
				table.insert(v227_, v230_)
				local v231_ = self.pickUpHandToolButtonInfo
				table.insert(v227_, v231_)
			else
				if v229_:getCanPickupHandToolFromMenu(v228_) then
					local v232_ = self.pickUpHandToolButtonInfo
					table.insert(v227_, v232_)
				end
				if v229_ == g_localPlayer then
					local v233_ = self.sellHandToolButtonInfo
					table.insert(v227_, v233_)
					local v234_ = self.storeHandToolButtonInfo
					table.insert(v227_, v234_)
				end
			end
		end
		self.menuButtonInfo[InGameMenuStatisticsFrame.SUB_CATEGORY.HANDTOOLS] = v227_
	end
	self:setMenuButtonInfoDirty()
end

-- Local values: section, index, fillTypeDesc, prices, min, max, i, minPrice, maxPrice, range, hasAnyFluctuations, minPercent, maxPercent, month, percentageInView, posX, posX
function InGameMenuStatisticsFrame:updateFluctuations()
	if not self.sellingStationMode then
		local v236_, v237_ = self.productList:getSelectedPath()
		local v238_ = self.fillTypes[v236_][v237_].economy.history
		local v239_ = math.huge
		local v240_ = 0
		for v241_ = 1, 12 do
			local v242_ = v238_[v241_]
			v239_ = math.min(v239_, v242_)
			local v243_ = v238_[v241_]
			v240_ = math.max(v240_, v243_)
		end
		local v244_ = v239_ * 1000 * EconomyManager.getPriceMultiplier()
		local v245_ = v240_ * 1000 * EconomyManager.getPriceMultiplier()
		local v246_ = v240_ - v239_
		local v247_ = v239_ - v246_ * 0.2
		local v248_ = math.max(v247_, 0)
		local v249_ = v240_ + v246_ * 0.2
		local v250_ = v248_ ~= v249_
		self.noFluctuationsText:setVisible(not v250_)
		self.fluctuationsLayoutBg:setVisible(v250_)
		self.fluctuationPoints = {}
		self.fluctuationHigh:setVisible(v250_)
		self.fluctuationHigh:setValue(v245_)
		self.fluctuationLow:setVisible(v250_)
		self.fluctuationLow:setValue(v244_)
		self.hasAnyFluctuations = v250_
		if not v250_ then
			return
		end
		local v251_ = 0
		local v252_ = math.huge
		for v253_ = 1, 12 do
			local v254_ = (v238_[v253_] - v248_) / (v249_ - v248_)
			self.fluctuationPoints[v253_] = v254_ * self.fluctuationsContainer.absSize[2]
			if v254_ < v252_ then
				local v255_ = self.monthTexts[v253_].absPosition[1] + self.monthTexts[v253_].absSize[1] * 0.5 - self.fluctuationLow.absSize[1] * 0.5
				self.fluctuationLow:setAbsolutePosition(v255_, nil)
				v252_ = v254_
			end
			if v251_ < v254_ then
				local v256_ = self.monthTexts[v253_].absPosition[1] + self.monthTexts[v253_].absSize[1] * 0.5 - self.fluctuationHigh.absSize[1] * 0.5
				self.fluctuationHigh:setAbsolutePosition(v256_, nil)
				v251_ = v254_
			end
		end
	end
	self.priceList:reloadData()
end

-- Local values: mission, env, season, intoSeason, percentage, parentSize
function InGameMenuStatisticsFrame:updateTodayBar()
	local v258_ = g_currentMission.environment
	local v259_ = v258_.currentSeason - 1
	local v260_ = (v258_.currentDayInSeason - 1) / v258_:getDaysPerSeason()
	local v261_ = v259_ * 0.25 + v260_ * 0.25
	local v262_ = self.todayBar.parent.size[1]
	self.todayBar:setPosition(v262_ * v261_ + v262_ / (v258_:getDaysPerSeason() * 4) * 0.5, nil)
end

-- Local values: fruitTypes, otherTypes, _, fillTypeDesc, fillTypeSortFunc
function InGameMenuStatisticsFrame:rebuildTable()
	local v264_ = {}
	local v265_ = {}
	self.fillTypes = { v264_, v265_ }
	for _, v266_ in pairs(g_fillTypeManager:getFillTypes()) do
		if v266_.showOnPriceTable then
			if g_fruitTypeManager:getFruitTypeIndexByFillTypeIndex(v266_.index) then
				table.insert(v264_, v266_)
			else
				table.insert(v265_, v266_)
			end
		end
	end
	local function v269_(p267_, p268_)
		return p267_.title < p268_.title
	end
	table.sort(v264_, v269_)
	table.sort(v265_, v269_)
	self:updateStationData()
	self.productList:reloadData()
end

-- Local values: selectedIndex, stationData
function InGameMenuStatisticsFrame:getSelectedHotspot()
	local v271_ = self.priceList:getSelectedIndexInSection()
	if self.sellingStationMode then
		v271_ = self.productList:getSelectedIndexInSection()
	end
	if v271_ < 1 then
		return nil
	else
		local v272_ = self.currentStationData[v271_]
		if v272_ == nil or v272_.owningPlaceable == nil then
			return nil
		else
			return v272_.owningPlaceable:getHotspot(1)
		end
	end
end

-- Local values: totalCapacity, usedCapacity, mission, farmId, _, storage
function InGameMenuStatisticsFrame:getStorageFillLevel(fillType, farmSilo, usedStorages)
	local v276_ = g_currentMission
	local v277_ = v276_:getFarmId()
	local v278_ = 0
	local v279_ = 0
	for _, v280_ in pairs(v276_.storageSystem:getStorages()) do
		if usedStorages[v280_] == nil and (v280_:getOwnerFarmId() == v277_ and (v280_.foreignSilo ~= farmSilo and v280_:getIsFillTypeSupported(fillType.index))) then
			usedStorages[v280_] = true
			v278_ = v278_ + v280_:getFillLevel(fillType.index)
			v279_ = v279_ + v280_:getCapacity(fillType.index)
		end
	end
	if v279_ > 0 then
		return v278_, v279_
	else
		return -1, -1
	end
end

-- Local values: hotspot, mission
function InGameMenuStatisticsFrame:onButtonHotspot()
	local v282_ = self:getSelectedHotspot()
	local v283_ = g_currentMission
	if v282_ == nil then
		v283_:setMapTargetHotspot(nil)
	else
		if v283_.currentMapTargetHotspot == v282_ then
			v283_:setMapTargetHotspot(nil)
		else
			v283_:setMapTargetHotspot(v282_)
		end
		self:updateMenuButtons()
	end
end

function InGameMenuStatisticsFrame:onButtonChangeSellingStationMode()
	self.sellingStationMode = not self.sellingStationMode
	if self.sellingStationMode then
		self.priceList:applyProfile("fs25_pricesPriceListFull")
		self.priceListSliderBox:applyProfile("fs25_pricesPriceSliderBoxFull")
	else
		self.priceList:applyProfile("fs25_pricesPriceList")
		self.priceListSliderBox:applyProfile("fs25_pricesPriceSliderBox")
	end
	self.fluctuationsLayoutBg:setVisible(not self.sellingStationMode)
	self.fluctuationsContainer:setVisible(not self.sellingStationMode)
	self.headerProducts:setVisible(not self.sellingStationMode)
	self.headerStations:setVisible(self.sellingStationMode)
	self:updateStationData()
	self.productList:reloadData()
	self.priceList:reloadData()
end

-- Local values: item, vehicle, storeItem
function InGameMenuStatisticsFrame:onButtonSell()
	local v286_ = self.vehicles[self.vehiclesList:getSelectedIndexInSection()]
	if v286_ ~= nil and v286_.vehicle ~= nil then
		local v287_ = v286_.vehicle
		local v288_ = g_storeManager:getItemByXMLFilename(v287_.configFileName)
		g_shopController:sell(v288_, v287_)
	end
end

-- Local values: item, inGameMenu, mapPage
function InGameMenuStatisticsFrame:onVehicleViewOnMap()
	local v290_ = self.vehicles[self.vehiclesList:getSelectedIndexInSection()]
	local v291_ = g_inGameMenu
	v291_:openMapOverview()
	local v292_ = v291_.pageMapOverview
	if Platform.isMobile then
		v292_ = v291_.pageMapMobile
	end
	v292_:showMapHotspot(v290_.vehicle:getMapHotspot())
end

-- Local values: item, handTool, storeItem
function InGameMenuStatisticsFrame:onButtonSellHandTool()
	local v294_ = self.handTools[self.handToolsList:getSelectedIndexInSection()]
	if v294_ ~= nil and v294_.handTool ~= nil then
		local v295_ = v294_.handTool
		local v296_ = g_storeManager:getItemByXMLFilename(v295_.configFileName)
		g_shopController:sell(v296_, v295_)
	end
end

-- Local values: _, index, item, itemName, brand, title, text
function InGameMenuStatisticsFrame:onStoreHandTool()
	local _, v298_ = self.handToolsList:getSelectedPath()
	local v299_ = self.handTools[v298_]
	if v299_ ~= nil and v299_.handTool ~= nil then
		local v300_ = v299_.handTool:getName()
		local v301_ = v299_.handTool.brand
		if v301_ ~= nil and v301_.title ~= "None" then
			v300_ = v301_.title .. " " .. v300_
		end
		local v302_ = g_i18n:getText("ui_handToolStoreTitle")
		local v303_ = string.format(g_i18n:getText("ui_confirmationStoreHandtool"), v300_)
		YesNoDialog.show(self.onYesNoStoreHandTool, self, v303_, v302_)
	end
end

-- Local values: section, index, item, cell
function InGameMenuStatisticsFrame:onYesNoStoreHandTool(yes)
	if yes then
		local v306_, v307_ = self.handToolsList:getSelectedPath()
		local v308_ = self.handTools[v307_]
		if v308_ ~= nil and v308_.handTool ~= nil then
			v308_.handTool:setHolder(nil)
			local v309_ = self.handToolsList.sections[v306_].cells[v307_]
			if v309_ ~= nil then
				v309_:getAttribute("holder"):setText("-")
			end
		end
		self.handToolInfoDirty = true
		self:updateMenuButtons()
	end
end

-- Local values: _, index, item, handTool, itemName, brand, title, text
function InGameMenuStatisticsFrame:onPickUpHandTool()
	local _, v311_ = self.handToolsList:getSelectedPath()
	local v312_ = self.handTools[v311_]
	if v312_ ~= nil and v312_.handTool ~= nil then
		local v313_ = v312_.handTool
		if g_localPlayer:getReachedHandToolLimit(v313_) then
			InfoDialog.show(g_i18n:getText("ui_handToolLimitReached"))
			return
		end
		if not g_localPlayer:getCanPickupHandTool(v313_) then
			InfoDialog.show(g_i18n:getText("ui_handToolCannotBePickedUp"))
			return
		end
		local v314_ = v313_:getName()
		local v315_ = v313_.brand
		if v315_ ~= nil and v315_.title ~= "None" then
			v314_ = v315_.title .. " " .. v314_
		end
		local v316_ = g_i18n:getText("ui_handToolPickupTitle")
		local v317_ = string.format(g_i18n:getText("ui_confirmationPickupHandtool"), v314_)
		YesNoDialog.show(self.onYesNoPickUpHandTool, self, v317_, v316_)
	end
end

-- Local values: section, index, item, cell
function InGameMenuStatisticsFrame:onYesNoPickUpHandTool(yes)
	if yes then
		local v320_, v321_ = self.handToolsList:getSelectedPath()
		local v322_ = self.handTools[v321_]
		if v322_ ~= nil and v322_.handTool ~= nil then
			v322_.handTool:setHolder(g_localPlayer)
			local v323_ = self.handToolsList.sections[v320_].cells[v321_]
			if v323_ ~= nil then
				v323_:getAttribute("holder"):setText(g_localPlayer:getHolderName())
			end
		end
		self:updateMenuButtons()
	end
end

function InGameMenuStatisticsFrame:onButtonBorrow()
	if self:hasPlayerLoanPermission() then
		self.client:getServerConnection():sendEvent(ChangeLoanEvent.new(InGameMenuStatisticsFrame.FINANCES.LOAN_STEP, self.playerFarm.farmId))
	end
end

function InGameMenuStatisticsFrame:onButtonRepay()
	if self:hasPlayerLoanPermission() then
		self.client:getServerConnection():sendEvent(ChangeLoanEvent.new(-InGameMenuStatisticsFrame.FINANCES.LOAN_STEP, self.playerFarm.farmId))
	end
end

function InGameMenuStatisticsFrame:onHourChanged()
	self:updateFluctuations()
	self:updateTodayBar()
end

-- Local values: farm, moneyText
function InGameMenuStatisticsFrame:onMoneyChange()
	if g_localPlayer ~= nil then
		local v328_ = g_farmManager:getFarmById(g_localPlayer.farmId)
		if v328_.money <= -1 then
			self.currentBalanceText:applyProfile(ShopMenu.GUI_PROFILE.SHOP_MONEY_NEGATIVE, nil, true)
		else
			self.currentBalanceText:applyProfile(ShopMenu.GUI_PROFILE.SHOP_MONEY, nil, true)
		end
		local v329_ = g_i18n:formatMoney(v328_.money, 0, true, false)
		self.currentBalanceText:setText(v329_)
		if self.shopMoneyBox ~= nil then
			self.shopMoneyBox:invalidateLayout()
			self.shopMoneyBoxBg:setSize(self.shopMoneyBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
		end
	end
end

function InGameMenuStatisticsFrame:onVehicleSellEvent()
	self:updateVehicles()
end

function InGameMenuStatisticsFrame:onVehicleBuyEvent()
	self:updateVehicles()
end

function InGameMenuStatisticsFrame:onHandToolSellEvent()
	self:updateHandTools()
end

function InGameMenuStatisticsFrame:onHandToolBuyEvent()
	self:updateHandTools()
end

function InGameMenuStatisticsFrame:onHandToolSetHolderEvent()
	self:updateHandTools()
end

function InGameMenuStatisticsFrame:onClickPrices()
	self.subCategoryPaging:setState(InGameMenuStatisticsFrame.SUB_CATEGORY.PRICES, true)
end

function InGameMenuStatisticsFrame:onClickVehicleOverview()
	self.subCategoryPaging:setState(InGameMenuStatisticsFrame.SUB_CATEGORY.VEHICLE_OVERVIEW, true)
end

function InGameMenuStatisticsFrame:onClickHandTools()
	self.subCategoryPaging:setState(InGameMenuStatisticsFrame.SUB_CATEGORY.HANDTOOLS, true)
end

function InGameMenuStatisticsFrame:onClickFinances()
	self.subCategoryPaging:setState(InGameMenuStatisticsFrame.SUB_CATEGORY.FINANCES, true)
end

function InGameMenuStatisticsFrame:onClickStatistics()
	self.subCategoryPaging:setState(InGameMenuStatisticsFrame.SUB_CATEGORY.STATISTICS, true)
end

-- Local values: index, page
function InGameMenuStatisticsFrame:updateSubCategoryPages(subCategoryIndex)
	for v342_, v343_ in pairs(self.subCategoryPages) do
		v343_:setVisible(v342_ == subCategoryIndex)
	end
	self.categoryHeaderIcon:setImageSlice(nil, InGameMenuStatisticsFrame.HEADER_SLICES[subCategoryIndex])
	self.categoryHeaderText:setText(g_i18n:getText(InGameMenuStatisticsFrame.HEADER_TITLES[subCategoryIndex]))
	self.statisticsSlider:setHandleFocus(false)
	self.statisticsSliderBox:setVisible(true)
	if subCategoryIndex == InGameMenuStatisticsFrame.SUB_CATEGORY.PRICES then
		self.statisticsSliderBox:setVisible(false)
	elseif subCategoryIndex == InGameMenuStatisticsFrame.SUB_CATEGORY.VEHICLE_OVERVIEW then
		self.statisticsSlider:setDataElement(self.vehiclesList)
	elseif subCategoryIndex == InGameMenuStatisticsFrame.SUB_CATEGORY.HANDTOOLS then
		self.statisticsSlider:setDataElement(self.handToolsList)
	elseif subCategoryIndex == InGameMenuStatisticsFrame.SUB_CATEGORY.FINANCES then
		self.statisticsSlider:setDataElement(self.financesList)
		self:updateFinances()
	elseif subCategoryIndex == InGameMenuStatisticsFrame.SUB_CATEGORY.STATISTICS then
		self.statisticsSlider:setDataElement(self.statisticsList1)
		self.statisticsSlider:setHandleFocus(true)
	else
		self.statisticsSliderBox:setVisible(false)
	end
	FocusManager:setFocus(self.subCategoryPaging)
	self:updateMenuButtons()
end

function InGameMenuStatisticsFrame:getNumberOfSections(list)
	return list == self.productList and not self.sellingStationMode and #self.fillTypes or 1
end

-- Local values: numItems
function InGameMenuStatisticsFrame:getNumberOfItemsInSection(list, section)
	return list == self.financesList and #FinanceStats.statNames or (list == self.productList and not self.sellingStationMode and #self.fillTypes[section] or (list == self.priceList and self.sellingStationMode and #self.currentAcceptedFillTypes or ((list == self.productList and self.sellingStationMode or list == self.priceList and not self.sellingStationMode) and #self.currentStationData or (list == self.vehiclesList and #self.vehicles or (list == self.handToolsList and #self.handTools or (self.statsIndices == nil and 0 or (self.statsIndices[self.statisticsList1] ~= nil and #self.statsIndices[self.statisticsList1] or 0)))))))
end

function InGameMenuStatisticsFrame:getTitleForSectionHeader(list, section)
	if list == self.productList and not self.sellingStationMode then
		return g_i18n:getText(InGameMenuStatisticsFrame.PRICE_SECTIONS[section])
	else
		return nil
	end
end

-- Local values: stats, currentFinances, pastFinances, statsName, statsNameText, fillTypeDesc, usedStorages, localLiters, foreignLiters, stationData, profile, sellingStation, sellingAllowed, price, priceTrend, buyingStation, palletBuyingStation, isBuyingStation, price, stationData, fillTypeSection, fillTypeIndex, fillTypeDesc, mapHotspot, distanceText, x, _, z, hotspotX, hotspotZ, distance, profile, sellingStation, price, priceTrend, buyingStation, palletBuyingStation, isBuyingStation, price, item, vehicle, storeItem, nameElement, column, licensePlateText, ageProfile, maxVehicleAge, ageElement, hoursElement, damageProfile, damageElement, leasingElement, valueElement, item, handTool, storeItem, nameElement, column, ageProfile, maxVehicleAge, ageElement, holderElement, statsIndex, stats
function InGameMenuStatisticsFrame:populateCellForItemInSection(list, section, index, cell)
	if list == self.financesList then
		local v357_ = self.playerFarm.stats
		local v358_ = v357_.finances
		local v359_ = v357_.financesHistory
		local v360_ = FinanceStats.statNames[index]
		local v361_ = FinanceStats.statNamesI18n[v360_]
		cell:getAttribute("name"):setText(v361_)
		self:setPastDayFinances(cell:getAttribute("todayMinusFour"), v359_, 4, v360_)
		self:setPastDayFinances(cell:getAttribute("todayMinusThree"), v359_, 3, v360_)
		self:setPastDayFinances(cell:getAttribute("todayMinusTwo"), v359_, 2, v360_)
		self:setPastDayFinances(cell:getAttribute("todayMinusOne"), v359_, 1, v360_)
		self:setPastDayFinances(cell:getAttribute("today"), v358_, 0, v360_)
	elseif list == self.productList and not self.sellingStationMode or list == self.priceList and self.sellingStationMode then
		local v362_ = self.fillTypes[section][index]
		if self.sellingStationMode then
			v362_ = g_fillTypeManager:getFillTypeByIndex(self.currentAcceptedFillTypes[index])
		end
		cell:getAttribute("icon"):setVisible(true)
		cell:getAttribute("icon"):setImageFilename(v362_.hudOverlayFilename)
		cell:getAttribute("title"):setText(v362_.title)
		local v363_ = {}
		local v364_ = self:getStorageFillLevel(v362_, true, v363_)
		local v365_ = self:getStorageFillLevel(v362_, false, v363_)
		if v364_ < 0 and v365_ < 0 then
			cell:getAttribute("info"):setText("-")
		else
			cell:getAttribute("info"):setText(g_i18n:formatVolume(math.max(v364_, 0) + math.max(v365_, 0)))
		end
		cell:getAttribute("hotspot"):setVisible(false)
		cell:getAttribute("iconTrain"):setVisible(false)
		cell:getAttribute("iconPallet"):setVisible(false)
		if not self.sellingStationMode then
			return
		end
		local v366_ = self.currentStationData[self.currentStationIndex]
		local v367_ = InGameMenuStatisticsFrame.PROFILE.PRICE_NORMAL
		local v368_ = v366_.sellingStation
		local v369_
		if v368_ == nil then
			v369_ = false
		else
			v369_ = v368_:getIsFillTypeAllowed(v362_.index)
		end
		local v370_ = cell:getAttribute("price")
		local v371_
		if v368_ == nil then
			v371_ = false
		else
			v371_ = v369_
		end
		v370_:setVisible(v371_)
		if v368_ ~= nil and v369_ then
			local v372_ = v368_:getEffectiveFillTypePrice(v362_.index) * 1000
			cell:getAttribute("price"):setValue((tostring(v372_)))
			local v373_ = v368_:getCurrentPricingTrend(v362_.index)
			if v373_ ~= nil then
				if Utils.isBitSet(v373_, SellingStation.PRICE_GREAT_DEMAND) then
					v367_ = InGameMenuStatisticsFrame.PROFILE.PRICE_GREAT_DEMAND
				elseif Utils.isBitSet(v373_, SellingStation.PRICE_CLIMBING) then
					v367_ = InGameMenuStatisticsFrame.PROFILE.PRICE_CLIMBING
				elseif Utils.isBitSet(v373_, SellingStation.PRICE_FALLING) then
					v367_ = InGameMenuStatisticsFrame.PROFILE.PRICE_FALLING
				end
			end
		end
		cell:getAttribute("priceTrend"):applyProfile(v367_)
		local v374_ = v366_.buyingStation
		local v375_ = v366_.palletBuyingStation
		local v376_ = v374_ ~= nil and true or v375_ ~= nil
		cell:getAttribute("buyPrice"):setVisible(v376_)
		if v376_ then
			local v377_ = nil
			if v374_ == nil then
				if v375_:getHasPalletForFillType(v362_.index) then
					v377_ = v375_:getEffectivePricePerPallet(v362_.index)
				end
			else
				v377_ = v374_:getEffectiveFillTypePrice(v362_.index) * 1000
			end
			if v377_ == nil then
				cell:getAttribute("buyPrice"):setVisible(false)
			else
				cell:getAttribute("buyPrice"):setValue((tostring(v377_)))
			end
		end
	elseif list == self.productList and self.sellingStationMode or list == self.priceList and not self.sellingStationMode then
		local v378_ = self.currentStationData[index]
		local v379_, v380_ = self.productList:getSelectedPath()
		local v381_ = self.fillTypes[v379_][v380_]
		local v_u_382_
		if v378_.owningPlaceable == nil then
			v_u_382_ = nil
		else
			v_u_382_ = v378_.owningPlaceable:getHotspot(1) or nil
		end
		cell:getAttribute("hotspot"):setVisible(v_u_382_ ~= nil)
		if v_u_382_ ~= nil then
			cell:getAttribute("hotspot").getIsSelected = function()
				-- upvalues: (copy) v_u_382_
				local v383_ = g_currentMission
				local v384_
				if v383_.currentMapTargetHotspot == nil then
					v384_ = false
				else
					v384_ = v_u_382_ == v383_.currentMapTargetHotspot
				end
				return v384_
			end
		end
		cell:getAttribute("title"):setText(v378_.name)
		cell:getAttribute("iconTrain"):setVisible(v378_.isTrainStation)
		cell:getAttribute("iconPallet"):setVisible(v378_.isPalletStation)
		local v385_
		if v_u_382_ == nil then
			v385_ = "-"
		else
			local v386_, _, v387_ = getWorldTranslation(g_cameraManager:getActiveCamera())
			local v388_, v389_ = v_u_382_:getWorldPosition()
			local v390_ = MathUtil.vector2Length(v386_ - v388_, v387_ - v389_)
			v385_ = g_i18n:formatDistance(v390_, 0)
		end
		cell:getAttribute("info"):setText(v385_)
		cell:getAttribute("icon"):setVisible(false)
		if self.sellingStationMode then
			return
		end
		local v391_ = InGameMenuStatisticsFrame.PROFILE.PRICE_NORMAL
		local v392_ = v378_.sellingStation
		cell:getAttribute("price"):setVisible(v392_ ~= nil)
		if v392_ ~= nil then
			local v393_ = v392_:getEffectiveFillTypePrice(v381_.index) * 1000
			cell:getAttribute("price"):setValue((tostring(v393_)))
			local v394_ = v392_:getCurrentPricingTrend(v381_.index)
			if v394_ ~= nil then
				if Utils.isBitSet(v394_, SellingStation.PRICE_GREAT_DEMAND) then
					v391_ = InGameMenuStatisticsFrame.PROFILE.PRICE_GREAT_DEMAND
				elseif Utils.isBitSet(v394_, SellingStation.PRICE_CLIMBING) then
					v391_ = InGameMenuStatisticsFrame.PROFILE.PRICE_CLIMBING
				elseif Utils.isBitSet(v394_, SellingStation.PRICE_FALLING) then
					v391_ = InGameMenuStatisticsFrame.PROFILE.PRICE_FALLING
				end
			end
		end
		cell:getAttribute("priceTrend"):applyProfile(v391_)
		local v395_ = v378_.buyingStation
		local v396_ = v378_.palletBuyingStation
		local v397_ = v395_ ~= nil and true or v396_ ~= nil
		cell:getAttribute("buyPrice"):setVisible(v397_)
		if v397_ then
			local v398_
			if v395_ == nil then
				v398_ = v396_:getEffectivePricePerPallet(v381_.index)
			else
				v398_ = v395_:getEffectiveFillTypePrice(v381_.index) * 1000
			end
			cell:getAttribute("buyPrice"):setValue((tostring(v398_)))
			return
		end
	elseif list == self.vehiclesList then
		local v399_ = self.vehicles[index]
		local v400_ = v399_.vehicle
		local v401_ = g_storeManager:getItemByXMLFilename(v400_.configFileName)
		if v401_ ~= nil then
			cell:getAttribute("name"):setText(v399_.columns[InGameMenuStatisticsFrame.COLUMN_NAME].text)
			local v402_ = LicensePlates.getSpecValuePlateText(nil, v400_) or "-"
			cell:getAttribute("licensePlate"):setText(v402_)
			local v403_ = InGameMenuStatisticsFrame.PROFILE.VALUE_CELL_NEUTRAL
			if v401_.lifetime <= v400_.age then
				v403_ = InGameMenuStatisticsFrame.PROFILE.VALUE_CELL_NEGATIVE
			end
			local v404_ = cell:getAttribute("age")
			v404_:setText(v399_.columns[InGameMenuStatisticsFrame.COLUMN_AGE].text)
			v404_:applyProfile(v403_, true)
			cell:getAttribute("operatingHours"):setText(v399_.columns[InGameMenuStatisticsFrame.COLUMN_HOURS].text)
			local v405_ = InGameMenuStatisticsFrame.PROFILE.VALUE_CELL_NEUTRAL
			local v406_ = v399_.columns[InGameMenuStatisticsFrame.COLUMN_DAMAGE]
			if v406_.value >= InGameMenuStatisticsFrame.DAMAGE_NEGATIVE_THRESHOLD then
				v405_ = InGameMenuStatisticsFrame.PROFILE.VALUE_CELL_NEGATIVE
			end
			local v407_ = cell:getAttribute("damage")
			v407_:setText(v406_.text)
			v407_:applyProfile(v405_, true)
			cell:getAttribute("leasing"):setText(v399_.columns[InGameMenuStatisticsFrame.COLUMN_LEASING].text)
			cell:getAttribute("value"):setText(v399_.columns[InGameMenuStatisticsFrame.COLUMN_VALUE].text)
			return
		end
	elseif list == self.handToolsList then
		local v408_ = self.handTools[index]
		local v409_ = v408_.handTool
		local v410_ = g_storeManager:getItemByXMLFilename(v409_.configFileName)
		if v410_ ~= nil then
			cell:getAttribute("name"):setText(v408_.columns[InGameMenuStatisticsFrame.COLUMN_NAME].text)
			local v411_ = InGameMenuStatisticsFrame.PROFILE.VALUE_CELL_NEUTRAL
			if v410_.lifetime <= v409_.age then
				v411_ = InGameMenuStatisticsFrame.PROFILE.VALUE_CELL_NEGATIVE
			end
			local v412_ = cell:getAttribute("age")
			v412_:setText(v408_.columns[InGameMenuStatisticsFrame.COLUMN_AGE].text)
			v412_:applyProfile(v411_, true)
			cell:getAttribute("holder"):setText(v408_.columns[InGameMenuStatisticsFrame.COLUMN_HOLDER].text)
			return
		end
	else
		local v413_ = self.statsIndices[list][index]
		if v413_ == nil then
			cell:getAttribute("name"):setText("")
			cell:getAttribute("session"):setText("")
			cell:getAttribute("total"):setText("")
			return
		end
		local v414_ = self.statsData[v413_]
		cell:getAttribute("name"):setText(v414_.name)
		cell:getAttribute("session"):setText(v414_.valueSession)
		cell:getAttribute("total"):setText(v414_.valueTotal)
	end
end

-- Local values: value, profile, financeData, pastIndex, moneyValue, moneyText
function InGameMenuStatisticsFrame:setPastDayFinances(cell, financesData, dayIndex, statsName)
	if InGameMenuStatisticsFrame.FINANCES.PAST_PERIOD_COUNT >= dayIndex then
		local v420_ = "-"
		local v421_ = InGameMenuStatisticsFrame.PROFILE.VALUE_CELL_NEUTRAL
		if dayIndex > 0 then
			financesData = financesData[#financesData - (dayIndex - 1)]
		end
		if financesData ~= nil then
			local v422_ = financesData[statsName]
			v420_ = g_i18n:formatMoney(v422_, 0, false) .. " " .. self.currentMoneyUnitText
			if math.floor(v422_) <= -1 then
				v421_ = InGameMenuStatisticsFrame.PROFILE.VALUE_CELL_NEGATIVE
			end
		end
		cell:applyProfile(v421_, true)
		cell:setText(v420_)
	end
end

-- Local values: fillTypeDesc
function InGameMenuStatisticsFrame:onListSelectionChanged(list, section, index)
	if list == self.productList then
		if self.sellingStationMode then
			self.currentStationIndex = index
			self:updateAcceptedFillTypes(self.currentStationData[index])
			self.priceList:reloadData()
			self:updateMenuButtons()
		else
			self:updateStationData(self.fillTypes[section][index])
			self.noSellpointsText:setVisible(#self.currentStationData == 0)
			self.priceList:reloadData()
			self:updateFluctuations()
			self:updateMenuButtons()
		end
	elseif list == self.priceList then
		self:updateMenuButtons()
		return
	elseif list == self.vehiclesList then
		self:updateItemAttributeData(index)
		self:updateMenuButtons()
	elseif list == self.handToolsList then
		self:updateMenuButtons()
	end
end

-- Local values: placeableToStation, mission, _, station, owningPlaceable, stationData, foundFillType, fillTypeIndex, _, fillType, _, station, owningPlaceable, stationData, foundFillType, fillTypeIndex, _, fillType, _, placeable, stationData
function InGameMenuStatisticsFrame:updateStationData(fillTypeDesc)
	self.currentStationData = {}
	local v429_ = g_currentMission
	local v430_ = {}
	for _, v431_ in pairs(v429_.storageSystem:getUnloadingStations()) do
		if v431_:isa(SellingStation) and (not v431_.hideFromPricesMenu and (fillTypeDesc == nil or v431_:getIsFillTypeAllowed(fillTypeDesc.index))) then
			local v432_ = v431_.owningPlaceable
			local v433_ = v430_[v432_]
			if v433_ == nil then
				local v434_ = false
				for v435_, _ in pairs(v431_.supportedFillTypes) do
					local v436_ = g_fillTypeManager:getFillTypeByIndex(v435_)
					if v436_ ~= nil then
						if v436_.showOnPriceTable then
							v434_ = true
						end
					end
				end
				if v434_ then
					v433_ = {
						["name"] = v431_:getName(),
						["owningPlaceable"] = v432_
					}
					table.addElement(self.currentStationData, v433_)
					if v432_ ~= nil then
						v430_[v432_] = v433_
					end
					goto l8
				end
			else
				::l8::
				if v431_.isTrainStation then
					v433_.isTrainStation = true
				end
				if v431_.isPalletStation then
					v433_.isPalletStation = true
				end
				v433_.sellingStation = v431_
			end
		end
	end
	for _, v437_ in pairs(v429_.storageSystem:getLoadingStations()) do
		if v437_:isa(BuyingStation) and (fillTypeDesc == nil or v437_:getIsFillTypeSupported(fillTypeDesc.index)) then
			local v438_ = v437_.owningPlaceable
			local v439_ = v430_[v438_]
			if v439_ == nil then
				local v440_ = false
				for v441_, _ in pairs(v437_.supportedFillTypes) do
					local v442_ = g_fillTypeManager:getFillTypeByIndex(v441_)
					if v442_ ~= nil then
						if v442_.showOnPriceTable then
							v440_ = true
						end
					end
				end
				if v440_ then
					v439_ = {
						["name"] = v437_:getName(),
						["owningPlaceable"] = v438_
					}
					table.addElement(self.currentStationData, v439_)
					if v438_ ~= nil then
						v430_[v438_] = v439_
					end
					goto l28
				end
			else
				::l28::
				v439_.buyingStation = v437_
			end
		end
	end
	for _, v443_ in pairs(v429_.storageSystem:getPalletBuyingStations()) do
		if fillTypeDesc == nil or v443_:getHasPalletForFillType(fillTypeDesc.index) then
			local v444_ = v430_[v443_]
			if v444_ == nil then
				v444_ = {
					["name"] = v443_:getName(),
					["owningPlaceable"] = v443_
				}
				table.addElement(self.currentStationData, v444_)
				v430_[v443_] = v444_
			end
			v444_.isPalletStation = true
			v444_.palletBuyingStation = v443_
		end
	end
	table.sort(self.currentStationData, function(p445_, p446_)
		return p445_.name < p446_.name
	end)
end

-- Local values: sellingStation, fillTypeIndex, fillTypeDesc, buyingStation, fillTypeIndex, _, palletBuyingStation, fillTypeIndex, _
function InGameMenuStatisticsFrame:updateAcceptedFillTypes(placeable)
	self.currentAcceptedFillTypes = {}
	if placeable ~= nil then
		local v449_ = placeable.sellingStation
		if v449_ ~= nil then
			for v450_, _ in pairs(v449_.acceptedFillTypes) do
				table.addElement(self.currentAcceptedFillTypes, v450_)
			end
		end
		local v451_ = placeable.buyingStation
		if v451_ ~= nil then
			for v452_, _ in pairs(v451_.supportedFillTypes) do
				table.addElement(self.currentAcceptedFillTypes, v452_)
			end
		end
		local v453_ = placeable.palletBuyingStation
		if v453_ ~= nil then
			for v454_, _ in pairs(v453_.spec_palletBuyingStation.fillTypeIndexToPallet) do
				table.addElement(self.currentAcceptedFillTypes, v454_)
			end
		end
	end
end

-- Local values: vehicle, storeItem, displayItem, x, z
function InGameMenuStatisticsFrame:updateItemAttributeData(index)
	local v457_ = index or self.vehiclesList.selectedIndex
	local v458_ = self.vehicles[v457_].vehicle
	if v458_ ~= nil and v458_:getMapHotspot() ~= nil then
		local v459_ = g_storeManager:getItemByXMLFilename(v458_.configFileName)
		local v460_ = g_shopController:makeDisplayItem(v459_, v458_, v458_.configurations)
		local v461_, v462_ = v458_:getMapHotspot():getWorldPosition()
		self.itemDetailsMap:setCenterToWorldPosition(v461_, v462_)
		self.itemDetailsMap:setMapZoom(7)
		self.itemDetailsMap:setMapAlpha(1)
		if v460_ ~= nil and self:getIsVisible() then
			self:assignItemAttributeData(v460_)
			return
		end
	end
	self.detailBox:setVisible(false)
end

-- Local values: k, clone, i, element, name
function InGameMenuStatisticsFrame:buildCellDatabase()
	for v464_, v465_ in pairs(self.detailsTemplates) do
		v465_:delete()
		self.detailsTemplates[v464_] = nil
	end
	self.detailsTemplates = {}
	for v466_ = #self.attributesLayout.elements, 1, -1 do
		local v467_ = self.attributesLayout.elements[v466_]
		local v468_ = v467_.name
		self.detailsTemplates[v468_] = v467_:clone()
		self.detailsCache[v468_] = {}
	end
end

-- Local values: cell, cache
function InGameMenuStatisticsFrame:dequeueDetailsCell(name)
	if self.detailsTemplates[name] == nil then
		return nil
	end
	local v471_ = self.detailsCache[name]
	local v472_
	if #v471_ > 0 then
		v472_ = v471_[#v471_]
		v471_[#v471_] = nil
	else
		v472_ = self.detailsTemplates[name]:clone()
	end
	self.attributesLayout:addElement(v472_)
	return v472_
end

-- Local values: cache
function InGameMenuStatisticsFrame:queueDetailsCell(cell)
	local v475_ = self.detailsCache[cell.name]
	v475_[#v475_ + 1] = cell
	self.attributesLayout:removeElement(cell)
	cell:unlinkElement()
end

function InGameMenuStatisticsFrame:applySorting(column)
	if self.sortByColumn == column and self.sortOrder ~= InGameMenuStatisticsFrame.SORT_ORDER_ASC then
		self.sortOrder = InGameMenuStatisticsFrame.SORT_ORDER_ASC
	else
		self.sortOrder = InGameMenuStatisticsFrame.SORT_ORDER_DESC
	end
	self.sortByColumn = column
	self:updateView()
end

function InGameMenuStatisticsFrame:onClickButtonSortByName()
	self:applySorting(InGameMenuStatisticsFrame.COLUMN_NAME)
end

function InGameMenuStatisticsFrame:onClickButtonSortByAge()
	self:applySorting(InGameMenuStatisticsFrame.COLUMN_AGE)
end

function InGameMenuStatisticsFrame:onClickButtonSortByHours()
	self:applySorting(InGameMenuStatisticsFrame.COLUMN_HOURS)
end

function InGameMenuStatisticsFrame:onClickButtonSortByDamage()
	self:applySorting(InGameMenuStatisticsFrame.COLUMN_DAMAGE)
end

function InGameMenuStatisticsFrame:onClickButtonSortByLeasing()
	self:applySorting(InGameMenuStatisticsFrame.COLUMN_LEASING)
end

function InGameMenuStatisticsFrame:onClickButtonSortByValue()
	self:applySorting(InGameMenuStatisticsFrame.COLUMN_VALUE)
end

function InGameMenuStatisticsFrame:onCreateButtonSortByName(element)
	self.sortIcons[InGameMenuStatisticsFrame.COLUMN_NAME] = {
		[InGameMenuStatisticsFrame.SORT_ORDER_ASC] = element:getDescendantByName("iconAscending"),
		[InGameMenuStatisticsFrame.SORT_ORDER_DESC] = element:getDescendantByName("iconDescending")
	}
end

function InGameMenuStatisticsFrame:onCreateButtonSortByAge(element)
	self.sortIcons[InGameMenuStatisticsFrame.COLUMN_AGE] = {
		[InGameMenuStatisticsFrame.SORT_ORDER_ASC] = element:getDescendantByName("iconAscending"),
		[InGameMenuStatisticsFrame.SORT_ORDER_DESC] = element:getDescendantByName("iconDescending")
	}
end

function InGameMenuStatisticsFrame:onCreateButtonSortByHours(element)
	self.sortIcons[InGameMenuStatisticsFrame.COLUMN_HOURS] = {
		[InGameMenuStatisticsFrame.SORT_ORDER_ASC] = element:getDescendantByName("iconAscending"),
		[InGameMenuStatisticsFrame.SORT_ORDER_DESC] = element:getDescendantByName("iconDescending")
	}
end

function InGameMenuStatisticsFrame:onCreateButtonSortByDamage(element)
	self.sortIcons[InGameMenuStatisticsFrame.COLUMN_DAMAGE] = {
		[InGameMenuStatisticsFrame.SORT_ORDER_ASC] = element:getDescendantByName("iconAscending"),
		[InGameMenuStatisticsFrame.SORT_ORDER_DESC] = element:getDescendantByName("iconDescending")
	}
end

function InGameMenuStatisticsFrame:onCreateButtonSortByLeasing(element)
	self.sortIcons[InGameMenuStatisticsFrame.COLUMN_LEASING] = {
		[InGameMenuStatisticsFrame.SORT_ORDER_ASC] = element:getDescendantByName("iconAscending"),
		[InGameMenuStatisticsFrame.SORT_ORDER_DESC] = element:getDescendantByName("iconDescending")
	}
end

function InGameMenuStatisticsFrame:onCreateButtonSortByValue(element)
	self.sortIcons[InGameMenuStatisticsFrame.COLUMN_VALUE] = {
		[InGameMenuStatisticsFrame.SORT_ORDER_ASC] = element:getDescendantByName("iconAscending"),
		[InGameMenuStatisticsFrame.SORT_ORDER_DESC] = element:getDescendantByName("iconDescending")
	}
end

function InGameMenuStatisticsFrame:applySortingHandTools(column)
	if self.handToolInfoDirty then
		self:updateHandTools()
	end
	if self.sortByColumnHandTools == column and self.sortOrderHandTools ~= InGameMenuStatisticsFrame.SORT_ORDER_ASC then
		self.sortOrderHandTools = InGameMenuStatisticsFrame.SORT_ORDER_ASC
	else
		self.sortOrderHandTools = InGameMenuStatisticsFrame.SORT_ORDER_DESC
	end
	self.sortByColumnHandTools = column
	self:updateViewHandTools()
end

function InGameMenuStatisticsFrame:onClickButtonSortByNameHandTools()
	self:applySortingHandTools(InGameMenuStatisticsFrame.COLUMN_NAME)
end

function InGameMenuStatisticsFrame:onClickButtonSortByAgeHandTools()
	self:applySortingHandTools(InGameMenuStatisticsFrame.COLUMN_AGE)
end

function InGameMenuStatisticsFrame:onClickButtonSortByHolder()
	self:applySortingHandTools(InGameMenuStatisticsFrame.COLUMN_HOLDER)
end

function InGameMenuStatisticsFrame:onCreateButtonSortByNameHandTools(element)
	self.sortIconsHandTools[InGameMenuStatisticsFrame.COLUMN_NAME] = {
		[InGameMenuStatisticsFrame.SORT_ORDER_ASC] = element:getDescendantByName("iconAscending"),
		[InGameMenuStatisticsFrame.SORT_ORDER_DESC] = element:getDescendantByName("iconDescending")
	}
end

function InGameMenuStatisticsFrame:onCreateButtonSortByAgeHandTools(element)
	self.sortIconsHandTools[InGameMenuStatisticsFrame.COLUMN_AGE] = {
		[InGameMenuStatisticsFrame.SORT_ORDER_ASC] = element:getDescendantByName("iconAscending"),
		[InGameMenuStatisticsFrame.SORT_ORDER_DESC] = element:getDescendantByName("iconDescending")
	}
end

function InGameMenuStatisticsFrame:onCreateButtonSortByHolder(element)
	self.sortIconsHandTools[InGameMenuStatisticsFrame.COLUMN_HOLDER] = {
		[InGameMenuStatisticsFrame.SORT_ORDER_ASC] = element:getDescendantByName("iconAscending"),
		[InGameMenuStatisticsFrame.SORT_ORDER_DESC] = element:getDescendantByName("iconDescending")
	}
end
InGameMenuStatisticsFrame.DAMAGE_NEGATIVE_THRESHOLD = 0.8
InGameMenuStatisticsFrame.L10N_SYMBOL = {
	["WEEK_DAY_TEMPLATE"] = "ui_financesDay",
	["BUTTON_BORROW"] = "button_borrow5000",
	["BUTTON_REPAY"] = "button_repay5000",
	["BUTTON_NEXT"] = "",
	["BUTTON_PREV"] = "",
	["CURRENCY"] = "$CURRENCY_SYMBOL",
	["SILO_CAPACITY"] = "ui_silos_totalCapacity",
	["SET_MARKER"] = "action_tag",
	["REMOVE_MARKER"] = "action_untag",
	["LIST_STATIONS"] = "action_listStations",
	["LIST_COMMODITIES"] = "action_listCommodities"
}
InGameMenuStatisticsFrame.PROFILE = {
	["VALUE_CELL_NEUTRAL"] = "fs25_statisticsTextWhite",
	["VALUE_CELL_NEGATIVE"] = "fs25_statisticsTextRed",
	["PRICE_NORMAL"] = "fs25_pricesPriceListArrow",
	["PRICE_FALLING"] = "fs25_pricesPriceListArrowFalling",
	["PRICE_CLIMBING"] = "fs25_pricesPriceListArrowClimbing",
	["PRICE_GREAT_DEMAND"] = "fs25_pricesPriceListArrowGreatDemand",
	["ICON_FRUIT_TYPE"] = "fs25_itemDetailsFruitIcon",
	["ICON_FILL_TYPES"] = "shopListAttributeIconFillTypes",
	["ICON_SEED_FILL_TYPES"] = "shopListAttributeIconSeeds",
	["ICON_INPUT"] = "shopListAttributeIconInput",
	["ICON_OUTPUT"] = "shopListAttributeIconOutput"
}
InGameMenuStatisticsFrame.HEADER_SLICES = {
	[InGameMenuStatisticsFrame.SUB_CATEGORY.PRICES] = "gui.icon_ingameMenu_prices",
	[InGameMenuStatisticsFrame.SUB_CATEGORY.VEHICLE_OVERVIEW] = "gui.icon_vehicleDealer_machines",
	[InGameMenuStatisticsFrame.SUB_CATEGORY.HANDTOOLS] = "gui.icon_ingameMenu_handToolsOverview",
	[InGameMenuStatisticsFrame.SUB_CATEGORY.FINANCES] = "gui.icon_ingameMenu_finances",
	[InGameMenuStatisticsFrame.SUB_CATEGORY.STATISTICS] = "gui.icon_ingameMenu_finances"
}
InGameMenuStatisticsFrame.HEADER_TITLES = {
	[InGameMenuStatisticsFrame.SUB_CATEGORY.PRICES] = "ui_prices",
	[InGameMenuStatisticsFrame.SUB_CATEGORY.VEHICLE_OVERVIEW] = "ui_garageOverview",
	[InGameMenuStatisticsFrame.SUB_CATEGORY.HANDTOOLS] = "ui_handTools",
	[InGameMenuStatisticsFrame.SUB_CATEGORY.FINANCES] = "ui_finances",
	[InGameMenuStatisticsFrame.SUB_CATEGORY.STATISTICS] = "ui_statistics"
}
InGameMenuStatisticsFrame.PRICE_SECTIONS = { "helpLine_IconOverview_fillType", "ui_other" }
