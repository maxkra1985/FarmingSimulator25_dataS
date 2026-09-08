-- Local values: ShopMenu_mt
ShopMenu = {}
local ShopMenu_mt = Class(ShopMenu, TabbedMenuWithDetails)
ShopMenu.LIST_CELL_NAME_CATEGORY = "category"
ShopMenu.LIST_CELL_NAME_BRAND = "brand"
ShopMenu.LIST_CELL_NAME_PACKS = "packs"
ShopMenu.LIST_CELL_NAME_DLC = "dlc"
ShopMenu.LIST_EMPTY_CELL_NAME_CATEGORY = "categoryEmpty"
ShopMenu.LIST_EMPTY_CELL_NAME_BRAND = "brandEmpty"
ShopMenu.LIST_EMPTY_CELL_NAME_DLC = "dlcEmpty"
ShopMenu.SLOTS_USAGE_CRITICAL_THRESHOLD = 0.9
function ShopMenu.register()
	ShopCategoriesFrame.register()
	ShopItemsFrame.register()
	ShopOthersFrame.register()
	local v2_ = ShopMenu.new()
	g_gui:loadGui("dataS/gui/ShopMenu.xml", "ShopMenu", v2_)
	return v2_
end

-- Upvalues: ShopMenu_mt
-- Local values: self
function ShopMenu.new(target, customMt)
	-- upvalues: (copy) ShopMenu_mt
	local v5_ = TabbedMenuWithDetails.new(target, customMt or ShopMenu_mt)
	v5_.performBackgroundBlur = true
	v5_.gameState = GameState.MENU_SHOP
	v5_.restorePageIndex = 2
	v5_.useStack = true
	v5_.playerFarm = nil
	v5_.playerFarmId = 0
	v5_.currentUserId = -1
	v5_.paused = false
	v5_.client = nil
	v5_.server = nil
	v5_.isMasterUser = false
	v5_.isServer = false
	v5_.selectedDisplayElement = nil
	v5_.currentDisplayItems = nil
	v5_.defaultMenuButtonInfo = {}
	v5_.shopMenuButtonInfo = {}
	v5_.buyButtonInfo = {}
	v5_.shopDetailsButtonInfo = {}
	v5_.shopDetailsButtonInfoWithCombinations = {}
	v5_.itemDetailsButtonInfo = {}
	v5_.garageMenuButtonInfo = {}
	v5_.switchOwnedLeasedButtonInfo = {}
	v5_.sellButtonInfo = {}
	v5_.showCategoriesButtonInfo = {}
	v5_.showDLCsButtonInfo = {}
	v5_.showDLCVehiclesButtonInfo = {}
	v5_.backButtonInfo = {}
	g_shopConfigScreen:setRequestExitCallback(v5_:makeSelfCallback(v5_.exitMenuFromConfig))
	g_messageCenter:subscribe(MessageType.STORE_ITEMS_RELOADED, v5_.onStoreItemsReloaded, v5_)
	g_messageCenter:subscribe(MessageType.CURRENT_MISSION_LOADED, v5_.onMissionLoaded, v5_)
	v5_.showDLCsPage = true
	return v5_
end

-- Local values: newGui
function ShopMenu.createFromExistingGui(gui, guiName)
	ShopCategoriesFrame.createFromExistingGui(g_gui.frames.shopCategories.target, "ShopCategoriesFrame")
	ShopItemsFrame.createFromExistingGui(g_gui.frames.shopItems.target, "ShopItemsFrame")
	ShopOthersFrame.createFromExistingGui(g_gui.frames.shopOthers.target, "ShopOthersFrame")
	local v8_ = ShopMenu.new()
	g_gui.guis.ShopMenu:delete()
	g_gui.guis.ShopMenu.target:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v8_)
	v8_.client = gui.client
	v8_.server = gui.server
	v8_:onLoadMapFinished()
	v8_:setPlayerFarm(gui.playerFarm)
	v8_:setCurrentUserId(gui.currentUserId)
	return v8_
end

function ShopMenu:setClient(client)
	self.client = client
	g_shopController:setClient(client)
end

function ShopMenu:setServer(server)
	self.server = server
	self.isServer = server ~= nil
end

function ShopMenu:onVehicleSaleChanged()
	self.pageUsedSale:setDisplayItems(g_shopController:getItemsByCategory(ShopController.SALES_CATEGORY))
end

-- Local values: vehicleFilename
function ShopMenu:onMissionLoaded()
	local v15_ = StartParams.getValue("viewVehicleFilename")
	if v15_ ~= nil then
		self:viewVehicle(v15_)
	end
end

function ShopMenu:onLoadMapFinished()
	self:initializePages()
end

-- Local values: selectCategoryCallback, clickItemCategoryCallback
function ShopMenu:initializePages()
	g_inAppPurchaseController:load()
	self.clickBackCallback = self:makeSelfCallback(self.onButtonBack)
	g_shopController:setCurrentMission(g_currentMission)
	g_shopController:setClient(g_client)
	g_shopController:setUpdateShopItemsCallback(self:makeSelfCallback(self.updateCurrentDisplayItems))
	g_shopController:setUpdateAllItemsCallback(self:makeSelfCallback(self.updateCurrentDisplayItems))
	g_shopController:setSaleItemBoughtCallback(self.closeConfigScreen, self)
	g_shopController:setSwitchToConfigurationCallback(self.showConfigurationScreen, self)
	g_shopController:load()
	local v18_ = self:makeSelfCallback(self.onSelectCategory)
	self.pageShopBrands:initialize(g_shopController:getBrandCategories(), g_shopController:getBrandNames(), self:makeSelfCallback(self.onClickBrand), v18_, g_i18n:getText(ShopMenu.L10N_SYMBOL.HEADER_BRANDS), ShopMenu.SLICE_ID.BRANDS, ShopMenu.LIST_CELL_NAME_BRAND, ShopMenu.LIST_EMPTY_CELL_NAME_CATEGORY)
	local v19_ = self:makeSelfCallback(self.onClickItemCategory)
	self.pageShopVehicles:initialize(g_storeManager:getCategoryTypes(), g_shopController:getShopCategories(), v19_, v18_, g_i18n:getText(ShopMenu.L10N_SYMBOL.HEADER_VEHICLES), ShopMenu.SLICE_ID.VEHICLES, ShopMenu.LIST_CELL_NAME_CATEGORY, ShopMenu.LIST_EMPTY_CELL_NAME_CATEGORY)
	self.pageShopDLCs:initialize(g_shopController:getDLCCategoryTypes(), g_shopController:getDLCCategories(), self:makeSelfCallback(self.onClickDLCs), v18_, g_i18n:getText(ShopMenu.L10N_SYMBOL.HEADER_DLCS), ShopMenu.SLICE_ID.DLCS, ShopMenu.LIST_CELL_NAME_DLC, ShopMenu.LIST_EMPTY_CELL_NAME_DLC)
	self.pageShopDLCVehicles:initialize(g_storeManager:getCategoryTypes(), g_shopController:getShopDLCCategories(), self:makeSelfCallback(self.onClickDLCCategory), v18_, g_i18n:getText(ShopMenu.L10N_SYMBOL.HEADER_DLCS), ShopMenu.SLICE_ID.DLCS, ShopMenu.LIST_CELL_NAME_CATEGORY, ShopMenu.LIST_EMPTY_CELL_NAME_CATEGORY)
	self.pageShopPacks:initialize(g_shopController:getStorePackTypes(), g_shopController:getStorePacks(), self:makeSelfCallback(self.onClickPack), v18_, g_i18n:getText(ShopMenu.L10N_SYMBOL.HEADER_PACKS), ShopMenu.SLICE_ID.PACKS, ShopMenu.LIST_CELL_NAME_PACKS, ShopMenu.LIST_EMPTY_CELL_NAME_CATEGORY)
	self.pageShopOthers:initialize(v18_, g_i18n:getText(ShopMenu.L10N_SYMBOL.HEADER_OTHERS), ShopMenu.SLICE_ID.OTHERS)
	self.pageUsedSale:initialize()
	self.pageUsedSale:setItemClickCallback(self:makeClickBuyItemCallback())
	self.pageUsedSale:setItemSelectCallback(self:makeSelfCallback(self.onSelectItemBuyDetail))
	self.pageUsedSale:setHeader(g_i18n:getText("ui_usedVehicleSale"), ShopMenu.SLICE_ID.SALE)
	self.pageUsedSale:setCategory(nil, g_i18n:getText("ui_usedVehicleSale"))
	self.pageShopItemDetails:initialize()
	self.pageShopItemDetails:setItemClickCallback(self:makeClickBuyItemCallback())
	self.pageShopItemDetails:setItemSelectCallback(self:makeSelfCallback(self.onSelectItemBuyDetail))
	self.pageShopItemCombinations:initialize()
	self.pageShopItemCombinations:setItemClickCallback(self:makeClickBuyItemCallback())
	self.pageShopItemCombinations:setItemSelectCallback(self:makeSelfCallback(self.onSelectItemBuyDetail))
end

-- Local values: orderedDefaultPages, i, pageDef, page, predicate, sliceId
function ShopMenu:setupMenuPages()
	local v21_ = {
		{ self.pageShopBrands, self:makeIsShopBrandsEnabledPredicate(), ShopMenu.SLICE_ID.BRANDS },
		{ self.pageShopVehicles, self:makeIsShopVehiclesEnabledPredicate(), ShopMenu.SLICE_ID.VEHICLES },
		{ self.pageShopPacks, self:makeIsShopPacksEnabledPredicate(), ShopMenu.SLICE_ID.PACKS },
		{ self.pageUsedSale, self:makeIsShopUsedEnabledPredicate(), ShopMenu.SLICE_ID.SALE },
		{ self.pageShopDLCs, self:makeIsDLCPageEnabledPredicate(), ShopMenu.SLICE_ID.DLCS },
		{ self.pageShopDLCVehicles, self:makeIsDLCVehiclesPageEnabledPredicate(), ShopMenu.SLICE_ID.DLCS },
		{ self.pageShopOthers, self:makeIsShopOthersEnabledPredicate(), ShopMenu.SLICE_ID.OTHERS },
		{ self.pageShopItemDetails, self:makeIsShopItemsEnabledPredicate(), ShopMenu.SLICE_ID.VEHICLES },
		{ self.pageShopItemCombinations, self:makeIsShopCombinationsEnabledPredicate(), ShopMenu.SLICE_ID.SALE }
	}
	for v22_, v23_ in ipairs(v21_) do
		local v24_, v25_, v26_ = unpack(v23_)
		self:registerPage(v24_, v22_, v25_)
		self:addPageTab(v24_, nil, nil, v26_)
	end
	self:rebuildTabList()
end

function ShopMenu:setupMenuButtonInfo()
	ShopMenu:superClass().setupMenuButtonInfo(self)
	self.backButtonInfo = {
		["inputAction"] = InputAction.MENU_BACK,
		["text"] = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_BACK),
		["callback"] = self.clickBackCallback
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
	self.selectButtonInfo = {
		["inputAction"] = InputAction.MENU_ACCEPT,
		["text"] = g_i18n:getText("button_select"),
		["callback"] = self.onButtonSelect
	}
	self.searchButtonInfo = {
		["inputAction"] = InputAction.MENU_EXTRA_2,
		["text"] = g_i18n:getText("button_search"),
		["callback"] = self.onButtonSearch
	}
	self.defaultMenuButtonInfo = {
		self.backButtonInfo,
		self.nextPageButtonInfo,
		self.prevPageButtonInfo,
		self.selectButtonInfo
	}
	self.defaultMenuButtonInfoByActions[InputAction.MENU_BACK] = self.defaultMenuButtonInfo[1]
	self.defaultButtonActionCallbacks = {
		[InputAction.MENU_BACK] = self.clickBackCallback
	}
	if Platform.isMobile then
		self.shopMenuButtonInfo = { self.backButtonInfo }
	else
		self.shopMenuButtonInfo = {
			self.backButtonInfo,
			self.nextPageButtonInfo,
			self.prevPageButtonInfo,
			self.selectButtonInfo
		}
	end
	self.showCategoriesButtonInfo = {
		["inputAction"] = InputAction.MENU_ACTIVATE,
		["text"] = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_SHOW_CATEGORIES),
		["callback"] = self:makeSelfCallback(self.showCategories),
		["profile"] = "buttonSwitch"
	}
	self.showBrandsButtonInfo = {
		["inputAction"] = InputAction.MENU_ACTIVATE,
		["text"] = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_SHOW_BRANDS),
		["callback"] = self:makeSelfCallback(self.showBrands),
		["profile"] = "buttonSwitch"
	}
	if Platform.isMobile then
		self.shopMenuButtonInfoBrands = { self.backButtonInfo, self.showBrandsButtonInfo }
	else
		self.shopMenuButtonInfoBrands = {
			self.backButtonInfo,
			self.nextPageButtonInfo,
			self.prevPageButtonInfo,
			self.selectButtonInfo,
			self.searchButtonInfo
		}
	end
	if Platform.isMobile then
		self.shopMenuButtonInfoCategories = { self.backButtonInfo, self.showCategoriesButtonInfo }
	else
		self.shopMenuButtonInfoCategories = {
			self.backButtonInfo,
			self.nextPageButtonInfo,
			self.prevPageButtonInfo,
			self.selectButtonInfo,
			self.searchButtonInfo
		}
	end
	self.showDLCsButtonInfo = {
		["inputAction"] = InputAction.MENU_ACTIVATE,
		["text"] = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_SHOW_PACKS),
		["callback"] = self:makeSelfCallback(self.showDLCs),
		["profile"] = "buttonSwitch"
	}
	self.showDLCVehiclesButtonInfo = {
		["inputAction"] = InputAction.MENU_ACTIVATE,
		["text"] = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_SHOW_CATEGORIES),
		["callback"] = self:makeSelfCallback(self.showDLCVehicles),
		["profile"] = "buttonSwitch"
	}
	self.shopMenuButtonInfoDLCs = {
		self.backButtonInfo,
		self.nextPageButtonInfo,
		self.prevPageButtonInfo,
		self.showDLCVehiclesButtonInfo,
		self.selectButtonInfo
	}
	self.shopMenuButtonInfoDLCVehicles = {
		self.backButtonInfo,
		self.nextPageButtonInfo,
		self.prevPageButtonInfo,
		self.showDLCsButtonInfo,
		self.selectButtonInfo
	}
	self.shopMenuButtonsInfoOthers = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
	self.buyButtonInfo = {
		["inputAction"] = InputAction.MENU_ACCEPT,
		["text"] = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_BUY),
		["callback"] = self:makeSelfCallback(self.onButtonAcceptItem),
		["profile"] = "buttonBuy"
	}
	self.itemDetailsButtonInfo = {
		["inputAction"] = InputAction.MENU_CANCEL,
		["text"] = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_INFO),
		["callback"] = self:makeSelfCallback(self.onButtonInfo),
		["profile"] = "buttonShowInfo"
	}
	if Platform.isMobile then
		self.shopDetailsButtonInfo = { self.backButtonInfo, self.buyButtonInfo, self.itemDetailsButtonInfo }
	else
		self.shopDetailsButtonInfo = {
			self.backButtonInfo,
			self.nextPageButtonInfo,
			self.prevPageButtonInfo,
			self.buyButtonInfo
		}
	end
	self.combinationsButtonInfo = {
		["inputAction"] = InputAction.MENU_EXTRA_2,
		["text"] = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_COMBINATIONS),
		["callback"] = self:makeSelfCallback(self.onButtonCombinations),
		["profile"] = "buttonCombinations"
	}
	if Platform.isMobile then
		self.shopDetailsButtonInfoWithCombinations = {
			self.backButtonInfo,
			self.buyButtonInfo,
			self.combinationsButtonInfo,
			self.itemDetailsButtonInfo
		}
	else
		self.shopDetailsButtonInfoWithCombinations = {
			self.backButtonInfo,
			self.nextPageButtonInfo,
			self.prevPageButtonInfo,
			self.combinationsButtonInfo,
			self.buyButtonInfo
		}
	end
	self.sellButtonInfo = {
		["inputAction"] = InputAction.MENU_ACCEPT,
		["text"] = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_SELL),
		["callback"] = self:makeSelfCallback(self.onButtonAcceptItem),
		["profile"] = "buttonSell"
	}
	self.hotspotButtonInfo = {
		["inputAction"] = InputAction.MENU_CANCEL,
		["text"] = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_HOTSPOT),
		["callback"] = self:makeSelfCallback(self.onButtonToggleHotspot),
		["profile"] = "buttonHotspot"
	}
	if Platform.isMobile then
		self.garageMenuButtonInfo = { self.backButtonInfo }
	else
		self.garageMenuButtonInfo = {
			self.backButtonInfo,
			self.nextPageButtonInfo,
			self.prevPageButtonInfo,
			self.hotspotButtonInfo
		}
	end
end

function ShopMenu:onGuiSetupFinished()
	ShopMenu:superClass().onGuiSetupFinished(self)
	self:setupMenuPages()
end

function ShopMenu:setPlayerFarm(farm)
	self.playerFarm = farm
	if farm == nil then
		self.playerFarmId = 0
	else
		self.playerFarmId = farm.farmId
	end
	g_shopController:setPlayerFarm(farm)
	if self:getIsOpen() then
		self:updatePages()
	end
end

function ShopMenu:setCurrentMission(currentMission)
	g_shopController:setCurrentMission(currentMission)
end

function ShopMenu:setCurrentUserId(currentUserId)
	self.currentUserId = currentUserId
end

function ShopMenu:exitMenuFromConfig()
	g_shopConfigScreen:changeScreen(ShopMenu)
	self:exitMenu()
end

function ShopMenu:reset()
	ShopMenu:superClass().reset(self)
	g_shopController:reset()
	self.isMasterUser = false
	self.isServer = false
	self.selectedDisplayElement = nil
	self.selectedCategory = nil
	if GS_IS_MOBILE_VERSION then
		self.restorePageIndex = 2
	end
end

function ShopMenu:onOpen()
	self:onVehicleSaleChanged()
	ShopMenu:superClass().onOpen(self)
	self:onMoneyChange()
	g_messageCenter:subscribe(MessageType.MONEY_CHANGED, self.onMoneyChange, self)
	g_messageCenter:subscribe(MessageType.VEHICLE_REPAIRED, self.onVehicleRepairRepaintEvent, self)
	g_messageCenter:subscribe(MessageType.VEHICLE_REPAINTED, self.onVehicleRepairRepaintEvent, self)
	g_messageCenter:subscribe(MessageType.VEHICLE_SALES_CHANGED, self.onVehicleSaleChanged, self)
end

-- Local values: mission
function ShopMenu:onClose(element)
	ShopMenu:superClass().onClose(self)
	self.mouseDown = false
	self.alreadyClosed = true
	if not self.closingForConfigurationScreen then
		self.currentDisplayItems = nil
		local v38_ = g_currentMission
		v38_:showMoneyChange(MoneyType.SHOP_VEHICLE_BUY)
		v38_:showMoneyChange(MoneyType.SHOP_VEHICLE_SELL)
		v38_:showMoneyChange(MoneyType.SHOP_PROPERTY_BUY)
		v38_:showMoneyChange(MoneyType.SHOP_PROPERTY_SELL)
		v38_:showMoneyChange(MoneyType.SHOP_HANDTOOL_BUY)
		v38_:showMoneyChange(MoneyType.SHOP_HANDTOOL_SELL)
		v38_:showMoneyChange(MoneyType.LEASING_COSTS)
		v38_:showMoneyChange(MoneyType.PURCHASE_SEEDS)
		v38_:showMoneyChange(MoneyType.PURCHASE_FERTILIZER)
		v38_:showMoneyChange(MoneyType.PURCHASE_FUEL)
		v38_:showMoneyChange(MoneyType.PURCHASE_SAPLINGS)
		v38_:showMoneyChange(MoneyType.PURCHASE_PALLETS)
		v38_:showMoneyChange(MoneyType.PURCHASE_BALES)
		v38_:showMoneyChange(MoneyType.OTHER)
		v38_:showMoneyChange(MoneyType.BOUGHT_MATERIALS)
	end
	self.closingForConfigurationScreen = false
	g_messageCenter:unsubscribe(MessageType.MONEY_CHANGED, self)
	g_messageCenter:unsubscribe(MessageType.VEHICLE_REPAIRED, self)
	g_messageCenter:unsubscribe(MessageType.VEHICLE_REPAINTED, self)
	g_messageCenter:unsubscribe(MessageType.VEHICLE_SALES_CHANGED, self)
	if self.pageShopVehicles.overlayCache ~= nil then
		self.pageShopVehicles.overlayCache:clearCache()
	end
	if self.pageShopBrands.overlayCache ~= nil then
		self.pageShopBrands.overlayCache:clearCache()
	end
	if self.pageShopPacks.overlayCache ~= nil then
		self.pageShopPacks.overlayCache:clearCache()
	end
	if self.pageShopDLCs.overlayCache ~= nil then
		self.pageShopDLCs.overlayCache:clearCache()
	end
	if self.pageShopDLCVehicles.overlayCache ~= nil then
		self.pageShopDLCVehicles.overlayCache:clearCache()
	end
	if self.pageUsedSale.overlayCache ~= nil then
		self.pageUsedSale.overlayCache:clearCache()
	end
end

function ShopMenu:onButtonSelect()
	if self.selectedCategory == nil or self:getIsDetailMode() then
		if self.currentPage == self.pageShopOthers then
			self.pageShopOthers:onMenuAccept()
		end
	else
		self:getTopFrame():onOpenCategory()
	end
end

function ShopMenu:onButtonInfo()
	InfoDialog.show(self.selectedDisplayElement.functionText)
end

function ShopMenu:onButtonShop()
	self:popDetail()
end

-- Local values: combinations, items, details, title
function ShopMenu:onButtonCombinations()
	local v43_ = self.selectedDisplayElement.storeItem.specs.combinations
	local v44_ = g_shopController:getItemsFromCombinations(v43_)
	self.pageShopItemCombinations:setDisplayItems(v44_, false)
	local v45_ = self.pageShopItemDetails
	local v46_ = string.format(g_i18n:getText("ui_combinationsFor"), self.selectedDisplayElement.storeItem.name)
	self.pageShopItemCombinations:setCategory(v45_.rootName, v45_.categoryName, nil, v46_)
	self:pushDetail(self.pageShopItemCombinations)
	self.currentDisplayItems = v44_
end

function ShopMenu:onButtonSearch()
	self:openSeachDialog(nil)
end

-- Local values: text
function ShopMenu:openSeachDialog(defaultText)
	local v50_ = g_i18n:getText("modHub_search")
	TextInputDialog.show(self.onSearchTextEntered, self, defaultText, v50_, v50_, 40, v50_, nil, nil, false)
end

-- Local values: noResults, isSearching, success
function ShopMenu:onSearchTextEntered(text, ok)
	if ok then
		local v_u_54_ = true
		if g_storeManager:search(text, function(p55_)
			-- upvalues: (ref) v_u_54_, (copy) self, (copy) text
			MessageDialog.hide()
			v_u_54_ = false
			if #p55_ == 0 then
				InfoDialog.show(g_i18n:getText("ui_storeSearchingNoResults"), function()
					-- upvalues: (ref) self, (ref) text
					self:openSeachDialog(text)
				end)
			else
				local v56_ = {}
				for _, v57_ in ipairs(p55_) do
					local v58_ = v57_.ref
					table.insert(v56_, v58_)
				end
				local v59_ = g_shopController:getItemsByStoreItems(v56_)
				self.currentCategoryName = "Search results"
				self.currentDisplayItems = v59_
				self.currentCategoryFilter = nil
				self.currentItemDetailsType = ShopMenu.DETAILS.VEHICLE
				self.pageShopItemDetails:setDisplayItems(v59_)
				self.pageShopItemDetails:setCategory("", string.format("\"%s\"", text), ShopMenu.SLICE_ID.SEARCH)
				self:pushDetail(self.pageShopItemDetails)
				self.pageShopItemDetails:resetListSelection()
			end
		end) then
			if v_u_54_ then
				MessageDialog.show(g_i18n:getText("ui_storeSearching"))
			end
		else
			InfoDialog.show(g_i18n:getText("ui_storeSearchingNoResults"), function()
				-- upvalues: (copy) self, (copy) text
				self:openSeachDialog(text)
			end)
		end
	end
end

function ShopMenu:onVehicleRepairRepaintEvent(vehicle, _)
	if self.selectedDisplayElement ~= nil and self.selectedDisplayElement.concreteItem == vehicle then
		self:updateGarageButtonInfo(true, 1, self.selectedDisplayElement:hasCombinationInfo())
	end
end

function ShopMenu:onButtonAcceptItem()
	if self:getIsDetailMode() then
		self:getTopFrame():onOpenItem(nil, nil, nil, nil, true)
	end
end

function ShopMenu:setIsGamePaused(paused)
	self.paused = paused
	if self.currentPage ~= nil then
		self:updateButtonsPanel(self.currentPage)
	end
end

function ShopMenu:onDetailClosed(detailPage)
	self.currentDisplayItems = nil
end

function ShopMenu:update(dt)
	ShopMenu:superClass().update(self, dt)
	g_shopController:update(dt)
end

function ShopMenu:setConfigurations(vehicleBuyData)
	g_shopController:setConfigurations(vehicleBuyData)
end

-- Local values: enoughSlots
function ShopMenu:showConfigurationScreen(storeItem, saleItem, configurations)
	if g_currentMission.slotSystem:hasEnoughSlots(storeItem) then
		self.closingForConfigurationScreen = true
		self:changeScreen(ShopConfigScreen)
		g_shopConfigScreen:setReturnScreenClass(ShopMenu)
		g_shopConfigScreen:setStoreItem(storeItem, nil, saleItem, nil, configurations)
		g_shopConfigScreen:setCallbacks(self.setConfigurations, self)
	else
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
		InfoDialog.show(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.TOO_FEW_SLOTS))
	end
end

-- Local values: updatedDisplayItems
function ShopMenu:updateCurrentDisplayItems()
	if self.currentDisplayItems ~= nil then
		local v74_ = g_shopController:updateDisplayItems(self.currentDisplayItems)
		if #v74_ == 0 then
			self:onButtonBack()
			return
		end
		if self:getTopFrame() == self.pageShopItemCombinations then
			self.pageShopItemCombinations:setDisplayItems(v74_, false)
			return
		end
		self.pageShopItemDetails:setDisplayItems(v74_, false)
	end
end

function ShopMenu:onStoreItemsReloaded()
	self:updateCurrentDisplayItems()
end

function ShopMenu:inputEvent(action, value, eventUsed)
	local v80_ = ShopMenu:superClass().inputEvent(self, action, value, eventUsed)
	if not v80_ and action == InputAction.TOGGLE_STORE then
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.BACK)
		self:exitMenu()
		v80_ = true
	end
	return v80_
end

function ShopMenu:onClickMenu()
	self:exitMenu()
	return true
end

function ShopMenu:exitMenu()
	self.pageShopItemDetails:setDisplayItems(nil)
	self.pageShopItemCombinations:setDisplayItems(nil)
	self.pageUsedSale:setDisplayItems(nil)
	self.selectedDisplayElement = nil
	self.currentDisplayItems = nil
	ShopMenu:superClass().exitMenu(self)
end

function ShopMenu:onPageNext()
	if not Platform.isMobile then
		self:popToRoot()
		ShopMenu:superClass().onPageNext(self)
	end
end

function ShopMenu:onPagePrevious()
	if not Platform.isMobile then
		self:popToRoot()
		ShopMenu:superClass().onPagePrevious(self)
	end
end

-- Local values: farm, balanceMoneyText
function ShopMenu:onMoneyChange()
	if g_localPlayer ~= nil then
		local v86_ = g_farmManager:getFarmById(g_localPlayer.farmId)
		local v87_ = g_i18n:formatMoney(v86_.money, 0, true, false)
		self.pageShopItemDetails:setCurrentBalance(v86_.money, v87_)
		self.pageShopItemCombinations:setCurrentBalance(v86_.money, v87_)
		self.pageUsedSale:setCurrentBalance(v86_.money, v87_)
		self.pageShopVehicles:setCurrentBalance(v86_.money, v87_)
		self.pageShopBrands:setCurrentBalance(v86_.money, v87_)
		self.pageShopPacks:setCurrentBalance(v86_.money, v87_)
		self.pageShopDLCs:setCurrentBalance(v86_.money, v87_)
		self.pageShopDLCVehicles:setCurrentBalance(v86_.money, v87_)
	end
end

function ShopMenu:onSlotUsageChanged(currentSlotUsage, maxSlotUsage)
	if self.pageShopItemDetails ~= nil then
		self.pageShopItemDetails:setSlotsUsage(currentSlotUsage, maxSlotUsage)
	end
	if self.pageShopItemCombinations ~= nil then
		self.pageShopItemCombinations:setSlotsUsage(currentSlotUsage, maxSlotUsage)
	end
	if self.pageUsedSale ~= nil then
		self.pageUsedSale:setSlotsUsage(currentSlotUsage, maxSlotUsage)
	end
	if self.pageShopVehicles ~= nil then
		self.pageShopVehicles:setSlotsUsage(currentSlotUsage, maxSlotUsage)
	end
end

function ShopMenu:onSelectCategory(category, selectedElement)
	self.selectedCategory = category
end

-- Local values: isVehicle, isConfigurable, isHandTool
function ShopMenu:onSelectItemBuyDetail(displayItem, selectedElementIndex)
	self.selectedDisplayElement = displayItem
	local v95_ = StoreItemUtil.getIsVehicle(displayItem.storeItem)
	local v96_ = StoreItemUtil.getIsConfigurable(displayItem.storeItem)
	if v95_ and (v96_ and not Platform.isMobile) then
		self.buyButtonInfo.text = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_CUSTOMIZE)
	elseif v96_ or (StoreItemUtil.getIsHandTool(displayItem.storeItem) or Platform.isMobile) then
		self.buyButtonInfo.text = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_BUY)
	else
		self.buyButtonInfo.text = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_DETAILS)
	end
	if v95_ and (Platform.isMobile and displayItem.storeItem.canBeRecovered) then
		self.buyButtonInfo.text = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_RECOVER)
		self.buyButtonInfo.profile = "buttonRecover"
	elseif displayItem.storeItem.isInAppPurchase then
		if not displayItem.storeItem.isInAppPurchaseConsumable then
			self.buyButtonInfo.text = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_UNLOCK)
		end
		self.buyButtonInfo.profile = "buttonBuyIAP"
	elseif displayItem.storeItem.isInAppPurchase then
		self.buyButtonInfo.text = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_UNLOCK)
		self.buyButtonInfo.profile = "buttonBuyIAP"
	else
		self.buyButtonInfo.profile = "buttonBuy"
	end
	self:updateButtonsPanel(self.pageShopItemDetails)
end

-- Local values: concreteItem, itemPropertyState, isOwned
function ShopMenu:onSelectItemSellDetail(displayItem, selectedElementIndex)
	self.selectedDisplayElement = displayItem
	local v99_ = displayItem.concreteItem.propertyState
	self:updateGarageButtonInfo(v99_ == nil and true or v99_ ~= VehiclePropertyState.LEASED, 1, displayItem:hasCombinationInfo())
end

-- Local values: buttons, i
function ShopMenu:updateGarageButtonInfo(isOwned, numItems, hasCombinations)
	local v104_ = self:getPageButtonInfo(self.pageShopItemDetails)
	for v105_ = 1, #v104_ do
		v104_[v105_] = nil
	end
	local v106_ = self.backButtonInfo
	table.insert(v104_, v106_)
	if numItems > 0 then
		local v107_ = self.sellButtonInfo
		table.insert(v104_, v107_)
		if isOwned then
			self.sellButtonInfo.text = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_SELL)
		else
			self.sellButtonInfo.text = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_RETURN)
		end
	end
	if not Platform.isMobile and (self.selectedDisplayElement ~= nil and self.selectedDisplayElement.concreteItem.getMapHotspot ~= nil) then
		local v108_ = self.hotspotButtonInfo
		table.insert(v104_, v108_)
	end
	if hasCombinations then
		local v109_ = self.combinationsButtonInfo
		table.insert(v104_, v109_)
	end
	self:updateButtonsPanel(self.pageShopItemDetails)
end

-- Local values: buttonInfo
function ShopMenu:getPageButtonInfo(page)
	if self:getIsDetailMode() then
		if self.selectedDisplayElement == nil or (not self.selectedDisplayElement:hasCombinationInfo() or self:getTopFrame() == self.pageShopItemCombinations) then
			return self.shopDetailsButtonInfo
		else
			return self.shopDetailsButtonInfoWithCombinations
		end
	elseif page == self.pageShopItemDetails then
		if self.selectedDisplayElement:hasCombinationInfo() and self:getTopFrame() ~= self.pageShopItemCombinations then
			return self.shopDetailsButtonInfoWithCombinations
		else
			return self.shopDetailsButtonInfo
		end
	elseif page == self.pageShopBrands then
		return self.shopMenuButtonInfoCategories
	elseif page == self.pageShopVehicles then
		return self.shopMenuButtonInfoBrands
	elseif page == self.pageShopDLCs then
		return self.shopMenuButtonInfoDLCs
	elseif page == self.pageShopDLCVehicles then
		return self.shopMenuButtonInfoDLCVehicles
	elseif page == self.pageShopOthers and self.pageShopOthers.gameplayHintSelector:getIsFocused() then
		return self.shopMenuButtonsInfoOthers
	else
		return self.shopMenuButtonInfo
	end
end

-- Local values: brandItems
function ShopMenu:onClickBrand(brandId, categoryDisplayName, categoryLabel, categorySliceId)
	local v116_ = g_shopController:getItemsByBrand(brandId)
	self.currentDisplayItems = v116_
	self.pageShopItemDetails:setDisplayItems(v116_, false)
	self.pageShopItemDetails:setCategory(g_i18n:getText(ShopMenu.L10N_SYMBOL.HEADER_BRANDS), categoryDisplayName, categorySliceId)
	self.currentItemDetailsType = ShopMenu.DETAILS.BRAND
	self.currentBrandId = brandId
	self:pushDetail(self.pageShopItemDetails)
	self.pageShopItemDetails:resetListSelection()
end

-- Local values: items
function ShopMenu:onClickPack(packName, categoryDisplayName, packLabel, categorySliceId)
	local v121_ = g_shopController:getItemsByPack(packName)
	self.currentDisplayItems = v121_
	self.pageShopItemDetails:setDisplayItems(v121_, false)
	self.pageShopItemDetails:setCategory(g_i18n:getText(ShopMenu.L10N_SYMBOL.HEADER_PACKS), categoryDisplayName, categorySliceId)
	self:pushDetail(self.pageShopItemDetails)
	self.pageShopItemDetails:resetListSelection()
end

-- Local values: items
function ShopMenu:onClickDLCs(dlcId, categoryDisplayName, dlcLabel, categorySliceId)
	local v127_ = g_shopController:getItemsByDLC(dlcId)
	self.currentDisplayItems = v127_
	self.pageShopItemDetails:setDisplayItems(v127_, false)
	self.pageShopItemDetails:setCategory(g_i18n:getText(ShopMenu.L10N_SYMBOL.HEADER_DLCS), categoryDisplayName, categorySliceId, dlcLabel)
	self:pushDetail(self.pageShopItemDetails)
	self.pageShopItemDetails:resetListSelection()
end

-- Local values: categoryItems
function ShopMenu:onClickDLCCategory(categoryName, baseCategoryDisplayName, categoryDisplayName, categorySliceId, filter)
	local v134_ = g_shopController:getItemsByCategory(categoryName, true)
	self.currentCategoryName = categoryName
	self.currentDisplayItems = v134_
	self.currentCategoryFilter = filter
	self.currentItemDetailsType = ShopMenu.DETAILS.VEHICLE
	self.pageShopItemDetails:setDisplayItems(v134_)
	self.pageShopItemDetails:setCategory(baseCategoryDisplayName, categoryDisplayName, categorySliceId)
	self:pushDetail(self.pageShopItemDetails)
	self.pageShopItemDetails:resetListSelection()
end

-- Local values: categoryItems, hasInAppPurchases, i, displayItem
function ShopMenu:onClickItemCategory(categoryName, baseCategoryDisplayName, categoryDisplayName, headerIconSlice, filter)
	local v141_ = g_shopController:getItemsByCategory(categoryName)
	self.currentCategoryName = categoryName
	self.currentDisplayItems = v141_
	self.currentCategoryFilter = filter
	self.currentItemDetailsType = ShopMenu.DETAILS.VEHICLE
	self.pageShopItemDetails:setDisplayItems(v141_)
	if categoryName == ShopController.COINS_CATEGORY and not g_inAppPurchaseController:getIsAvailable() then
		InfoDialog.show(g_i18n:getText("ui_iap_notAvailable"), nil, nil, DialogElement.TYPE_INFO)
		return
	end
	local v142_ = false
	for v143_ = 1, #self.currentDisplayItems do
		if self.currentDisplayItems[v143_].storeItem.isInAppPurchase then
			v142_ = true
			break
		end
	end
	if v142_ then
		g_inAppPurchaseController:setPendingPurchaseCallback(function()
			-- upvalues: (copy) self
			if self:getIsOpen() then
				self:updateCurrentDisplayItems()
			end
		end)
	else
		g_inAppPurchaseController:setPendingPurchaseCallback(nil)
	end
	self.pageShopItemDetails:setCategory(baseCategoryDisplayName, categoryDisplayName, headerIconSlice)
	self:pushDetail(self.pageShopItemDetails)
	self.pageShopItemDetails:resetListSelection()
end

-- Local values: storeItem, enoughMoney, price, enoughSlots, callback, text, callback, target
function ShopMenu:buyItem(displayItem)
	if GS_IS_MOBILE_VERSION then
		local v146_ = displayItem.storeItem
		if v146_.isInAppPurchase then
			self:purchaseInAppProduct(v146_.product)
			return
		else
			local v147_ = g_currentMission.economyManager:getBuyPrice(v146_)
			local v148_ = v147_ <= 0 and true or v147_ <= g_currentMission:getMoney()
			local v149_ = g_currentMission.slotSystem:hasEnoughSlots(v146_)
			if v148_ then
				if v149_ then
					self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
					local v150_ = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.CONFIRM_BUY), g_i18n:formatMoney(v147_, 0, true, true))
					self.currentBuyDialogItem = displayItem
					local v151_ = self.onYesNoBuy
					YesNoDialog.show(v151_, self, v150_)
				else
					self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
					InfoDialog.show(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.TOO_FEW_SLOTS))
				end
			else
				self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
				if g_inAppPurchaseController:getIsAvailable() then
					YesNoDialog.show(function(p152_, p153_)
						if p153_ then
							p152_:showCoinShop()
						end
					end, self, g_i18n:getText("shop_messageNotEnoughMoneyToBuy_buyCoins"), g_i18n:getText("ui_buy"))
				else
					InfoDialog.show(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.NOT_ENOUGH_MONEY_BUY))
				end
			end
		end
	else
		g_shopController:buy(displayItem.storeItem, displayItem.saleItem, false, displayItem.configurations)
		return
	end
end

function ShopMenu:onYesNoBuy(yes)
	if yes then
		g_shopController:buy(self.currentBuyDialogItem.storeItem, self.currentBuyDialogItem.saleItem, false)
	end
	self.currentBuyDialogItem = nil
end

function ShopMenu:purchaseInAppProduct(product)
	if not g_inAppPurchaseController:tryPerformPendingPurchase(product, function(p158_, p159_)
		-- upvalues: (copy) self
		if p158_ then
			InfoDialog.show(g_i18n:getText(ShopMenu.IAP_ERROR_TEXTS[InAppPurchase.ERROR_OK]), nil, nil, DialogElement.TYPE_INFO)
			self:updateCurrentDisplayItems()
		else
			local v160_ = g_i18n:getText(ShopMenu.IAP_ERROR_TEXTS[InAppPurchase.ERROR_FAILED])
			if p159_ ~= nil then
				v160_ = v160_ .. "\n" .. p159_
			end
			InfoDialog.show(v160_, nil, nil, DialogElement.TYPE_INFO)
		end
	end) then
		if not g_inAppPurchaseController:getIsAvailable() then
			InfoDialog.show(g_i18n:getText("ui_iap_notAvailable"), nil, nil, DialogElement.TYPE_INFO)
			return
		end
		g_inAppPurchaseController:purchase(product, function(_, p161_, p162_)
			if not p161_ then
				InfoDialog.show(g_i18n:getText(ShopMenu.IAP_ERROR_TEXTS[p162_]), nil, nil, DialogElement.TYPE_INFO)
			end
		end)
	end
end

function ShopMenu:showCoinShop()
	self:changeScreen(ShopMenu)
	self:goToPage(self.pageShopVehicles)
	self:onClickItemCategory(ShopController.COINS_CATEGORY, nil, g_i18n:getText("ui_coins"))
end

-- Local values: displayItem, vehicle
function ShopMenu:onButtonToggleHotspot()
	if self:getIsDetailMode() then
		local v165_ = self:getTopFrame():getSelectedDisplayItem().concreteItem
		if v165_:getMapHotspot() == g_currentMission.currentMapTargetHotspot then
			g_currentMission:setMapTargetHotspot()
			return
		end
		g_currentMission:setMapTargetHotspot(v165_:getMapHotspot())
	end
end

function ShopMenu:showCategories()
	self:goToPage(self.pageShopVehicles)
end

function ShopMenu:showBrands()
	self:goToPage(self.pageShopBrands)
end

function ShopMenu:showDLCs()
	self.showDLCsPage = true
	self:updatePages()
	self:goToPage(self.pageShopDLCs)
end

function ShopMenu:showDLCVehicles()
	self.showDLCsPage = false
	self:updatePages()
	self:goToPage(self.pageShopDLCVehicles)
end

function ShopMenu:closeConfigScreen()
	g_shopConfigScreen:changeScreen(ShopMenu)
end

function ShopMenu:onButtonConstruction()
	self:changeScreen(ConstructionScreen)
end

-- Local values: basePath, storeItem, category, i
function ShopMenu:viewVehicle(vehicleFilename)
	local v173_ = vehicleFilename:gsub("\\", "/")
	local v174_ = getAppBasePath()
	if v173_:startsWith(v174_) then
		v173_ = v173_:sub(v174_:len() + 1)
	end
	local v175_ = g_storeManager:getItemByXMLFilename(v173_)
	if v175_ ~= nil then
		g_gui:changeScreen(nil, ShopMenu)
		local v176_ = nil
		for v177_ = 1, #v175_.categoryNames do
			v176_ = g_storeManager:getCategoryByName(v175_.categoryNames[v177_])
			if v176_ ~= nil then
				break
			end
		end
		if v176_ ~= nil then
			self:onClickItemCategory(v176_.name, g_i18n:getText(ShopMenu.L10N_SYMBOL.HEADER_VEHICLES), v176_.title, self.currentCategoryFilter)
		end
		g_shopMenu:showConfigurationScreen(v175_, nil, nil)
	end
end

function ShopMenu:getIsDetailMode()
	return ShopMenu:superClass().getIsDetailMode(self) or self.currentPage == self.pageUsedSale
end

function ShopMenu:makeIsShopBrandsEnabledPredicate()
	return function()
		-- upvalues: (copy) self
		return not self:getIsDetailMode() or self.currentPage == self.pageUsedSale
	end
end

function ShopMenu:makeIsShopVehiclesEnabledPredicate()
	return function()
		-- upvalues: (copy) self
		return not self:getIsDetailMode() or self.currentPage == self.pageUsedSale
	end
end

function ShopMenu:makeIsShopToolsEnabledPredicate()
	return function()
		-- upvalues: (copy) self
		local v182_
		if self:getIsDetailMode() and self.currentPage ~= self.pageUsedSale then
			v182_ = false
		else
			v182_ = not GS_IS_MOBILE_VERSION
		end
		return v182_
	end
end

function ShopMenu:makeIsShopObjectsEnabledPredicate()
	return function()
		-- upvalues: (copy) self
		local v184_
		if self:getIsDetailMode() and self.currentPage ~= self.pageUsedSale then
			v184_ = false
		else
			v184_ = not GS_IS_MOBILE_VERSION
		end
		return v184_
	end
end

function ShopMenu:makeIsShopPacksEnabledPredicate()
	return function()
		-- upvalues: (copy) self
		local v186_
		if self:getIsDetailMode() and self.currentPage ~= self.pageUsedSale then
			v186_ = false
		else
			v186_ = not GS_IS_MOBILE_VERSION
		end
		return v186_
	end
end

function ShopMenu:makeIsShopUsedEnabledPredicate()
	return function()
		-- upvalues: (copy) self
		local v188_
		if self:getIsDetailMode() and self.currentPage ~= self.pageUsedSale then
			v188_ = false
		else
			v188_ = not GS_IS_MOBILE_VERSION
		end
		return v188_
	end
end

function ShopMenu:makeIsShopGarageEnabledPredicate()
	return function()
		-- upvalues: (copy) self
		return not self:getIsDetailMode() or self.currentPage == self.pageUsedSale
	end
end

function ShopMenu:makeIsShopLeasedEnabledPredicate()
	return function()
		-- upvalues: (copy) self
		local v191_
		if self:getIsDetailMode() and self.currentPage ~= self.pageUsedSale then
			v191_ = false
		else
			v191_ = not GS_IS_MOBILE_VERSION
		end
		return v191_
	end
end

function ShopMenu:makeIsShopOthersEnabledPredicate()
	return function()
		-- upvalues: (copy) self
		local v193_
		if self:getIsDetailMode() and self.currentPage ~= self.pageUsedSale then
			v193_ = false
		else
			v193_ = not GS_IS_MOBILE_VERSION
		end
		return v193_
	end
end

function ShopMenu:makeIsShopItemsEnabledPredicate()
	return function()
		-- upvalues: (copy) self
		local v195_ = ShopMenu:superClass().getIsDetailMode(self)
		if v195_ then
			v195_ = self:getTopFrame() == self.pageShopItemDetails and true or self.currentPage == self.pageUsedSale
		end
		return v195_
	end
end

function ShopMenu:makeIsShopCombinationsEnabledPredicate()
	return function()
		-- upvalues: (copy) self
		local v197_ = self:getIsDetailMode()
		if v197_ then
			if self:getTopFrame() == self.pageShopItemCombinations then
				v197_ = not GS_IS_MOBILE_VERSION
			else
				v197_ = false
			end
		end
		return v197_
	end
end

function ShopMenu:makeIsDLCPageEnabledPredicate()
	return function()
		-- upvalues: (copy) self
		local v199_ = Platform.supportsMods
		if v199_ then
			if table.size(g_shopController:getDLCCategories()) > 0 then
				v199_ = self.showDLCsPage
			else
				v199_ = false
			end
		end
		return v199_
	end
end

function ShopMenu:makeIsDLCVehiclesPageEnabledPredicate()
	return function()
		-- upvalues: (copy) self
		local v201_ = Platform.supportsMods
		if v201_ then
			if table.size(g_shopController:getDLCCategories()) > 0 then
				v201_ = not self.showDLCsPage
			else
				v201_ = false
			end
		end
		return v201_
	end
end

function ShopMenu:makeClickBuyItemCallback()
	return function(p203_)
		-- upvalues: (copy) self
		self:buyItem(p203_)
	end
end

function ShopMenu:makeClickSellItemCallback()
	return function(p204_)
		g_shopController:sell(p204_.storeItem, p204_.concreteItem)
	end
end
ShopMenu.SLICE_ID = {
	["VEHICLES"] = "gui.icon_vehicleDealer_machines",
	["BRANDS"] = "gui.icon_vehicleDealer_brands",
	["DLCS"] = "gui.icon_vehicleDealer_mods",
	["PACKS"] = "gui.icon_vehicleDealer_packs",
	["SALE"] = "gui.icon_vehicleDealer_sale",
	["OTHERS"] = "gui.icon_others",
	["SEARCH"] = "gui.icon_vehicleDealer_search"
}
ShopMenu.L10N_SYMBOL = {
	["HEADER_BRANDS"] = "ui_brands",
	["HEADER_VEHICLES"] = GS_IS_MOBILE_VERSION and "ui_categories" or "ui_vehicles",
	["HEADER_TOOLS"] = "ui_tools",
	["HEADER_PLACEABLES"] = "category_placeables",
	["HEADER_OBJECTS"] = "ui_objects",
	["HEADER_ANIMALS"] = "category_animals",
	["HEADER_SALES"] = "category_sales",
	["HEADER_GARAGE_OWNED"] = "ui_garageOwned",
	["HEADER_GARAGE_LEASED"] = "ui_garageLeased",
	["HEADER_PACKS"] = "ui_storePacks",
	["HEADER_OTHERS"] = "ui_storeOthers",
	["HEADER_DLCS"] = "ui_modsAndDlcs",
	["LEASED_ITEMS"] = "shop_leasedItems",
	["OWNED_ITEMS"] = "shop_ownedItems",
	["BUTTON_BACK"] = "button_back",
	["BUTTON_GARAGE"] = "button_garage",
	["BUTTON_INFO"] = "button_detail",
	["BUTTON_SHOP"] = "ui_shop",
	["BUTTON_CUSTOMIZE"] = "button_configurate",
	["BUTTON_BUY"] = "button_buy",
	["BUTTON_DETAILS"] = "button_detail",
	["BUTTON_SELL"] = "button_sell",
	["BUTTON_RETURN"] = "button_return",
	["BUTTON_BRANDS"] = "button_shop_brands",
	["BUTTON_CATEGORIES"] = "button_shop_categories",
	["BUTTON_RECOVER"] = "button_recover",
	["BUTTON_UNLOCK"] = "ui_iap_unlock",
	["BUTTON_COMBINATIONS"] = "ui_combinations",
	["BUTTON_HOTSPOT"] = "button_showOnMap",
	["BUTTON_SHOW_CATEGORIES"] = "button_showCategories",
	["BUTTON_SHOW_BRANDS"] = "button_showBrands",
	["BUTTON_SHOW_PACKS"] = "button_showPacks",
	["NOT_ENOUGH_MONEY_BUY"] = "shop_messageNotEnoughMoneyToBuy",
	["MESSAGE_NO_PERMISSION"] = "shop_messageNoPermissionGeneral"
}
ShopMenu.DETAILS = {
	["BRAND"] = 1,
	["VEHICLE"] = 2
}
ShopMenu.FILTER = {
	["OWNED"] = 1,
	["LEASED"] = 2
}
ShopMenu.GUI_PROFILE = {
	["SHOP_MONEY"] = "fs25_shopMoney",
	["SHOP_MONEY_NEGATIVE"] = "fs25_shopMoneyNeg",
	["SHOP_MONEY_BG"] = "fs25_shopMoneyBoxBg",
	["SHOP_MONEY_SLOTS_BG"] = "fs25_shopMoneySlotsBoxBg"
}
ShopMenu.IAP_ERROR_TEXTS = {
	[InAppPurchase.ERROR_FAILED] = "ui_iap_errorFailed",
	[InAppPurchase.ERROR_NETWORK_UNAVAILABLE] = "ui_iap_errorNetworkUnavailable",
	[InAppPurchase.ERROR_CANCELLED] = "ui_iap_errorCancelled",
	[InAppPurchase.ERROR_PURCHASE_IN_PROGRESS] = "ui_iap_purchaseInProgress",
	[InAppPurchase.ERROR_OK] = "ui_iap_purchaseComplete",
	[InAppPurchase.ERROR_PENDING_PAYMENT] = "ui_iap_pendingPayment"
}
ShopMenu.IAP_ERROR_TEXTS = {
	[InAppPurchase.ERROR_FAILED] = "ui_iap_errorFailed",
	[InAppPurchase.ERROR_NETWORK_UNAVAILABLE] = "ui_iap_errorNetworkUnavailable",
	[InAppPurchase.ERROR_CANCELLED] = "ui_iap_errorCancelled",
	[InAppPurchase.ERROR_PURCHASE_IN_PROGRESS] = "ui_iap_purchaseInProgress",
	[InAppPurchase.ERROR_OK] = "ui_iap_purchaseComplete",
	[InAppPurchase.ERROR_PENDING_PAYMENT] = "ui_iap_pendingPayment"
}
