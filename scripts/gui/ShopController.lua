-- Local values: ShopController_mt
ShopController = {}
local ShopController_mt = Class(ShopController)
ShopController.MAX_ATTRIBUTES_PER_ROW = 5
ShopController.COINS_CATEGORY = "COINS"
ShopController.SALES_CATEGORY = "SALES"
ShopController.EMPTY_FILENAME = "data/store/store_empty.png"
function ShopController.new()
	-- upvalues: (copy) ShopController_mt
	local v2_ = ShopController_mt
	local v3_ = setmetatable({}, v2_)
	v3_.client = nil
	v3_.currentMission = nil
	v3_.playerFarm = nil
	v3_.playerFarmId = 0
	v3_.isInitialized = false
	v3_.isBuying = false
	v3_.isSelling = false
	v3_.buyVehicleNow = 0
	v3_.buyObjectNow = 0
	v3_.buyHandToolNow = 0
	v3_.displayBrands = {}
	v3_.displayBrandNames = {}
	v3_.displayBrandCategories = {}
	v3_.shopCategories = {}
	v3_.shopDLCCategories = {}
	v3_.displayPacks = {}
	v3_.displayDLCs = {}
	v3_.ownedFarmItems = {}
	v3_.leasedFarmItems = {}
	v3_.currentSellStoreItem = nil
	v3_.currentSellItem = nil
	v3_.buyItemFilename = nil
	v3_.buyItemPrice = 0
	v3_.buyItemIsFreeOfCharge = false
	v3_.buyItemConfigurations = nil
	v3_.buyItemIsLeasing = false
	v3_.buyItemLicensePlateData = nil
	v3_.updateShopItemsCallback = nil
	v3_.updateAllItemsCallback = nil
	v3_.switchToConfigurationCallback = nil
	v3_.saleItemBoughtCallback = nil
	g_messageCenter:subscribe(BuyVehicleEvent, v3_.onVehicleBuyEvent, v3_)
	g_messageCenter:subscribe(BuyObjectEvent, v3_.onObjectBuyEvent, v3_)
	g_messageCenter:subscribe(BuyHandToolEvent, v3_.onHandToolBuyEvent, v3_)
	g_messageCenter:subscribe(SellVehicleEvent, v3_.onVehicleSellEvent, v3_)
	g_messageCenter:subscribe(SellPlaceableEvent, v3_.onPlaceableSellEvent, v3_)
	g_messageCenter:subscribe(SellHandToolEvent, v3_.onHandToolSellEvent, v3_)
	return v3_
end

function ShopController:reset()
	self.isInitialized = false
	self.displayBrands = {}
	self.displayBrandNames = {}
	self.displayBrandCategories = {}
	self.shopCategories = {}
	self.shopDLCCategories = {}
	self.displayPacks = {}
	self.displayDLCs = {}
	self.ownedFarmItems = {}
	self.leasedFarmItems = {}
	self.currentSellItem = nil
	self.isBuying = false
	self.isSelling = false
end

function ShopController:delete()
	g_messageCenter:unsubscribeAll(self)
end

function ShopController:addBrandForDisplay(brand)
	local v8_ = self.displayBrands
	local v9_ = {
		["id"] = brand.index,
		["iconFilename"] = brand.imageShopOverview,
		["label"] = brand.title,
		["sortValue"] = brand.name
	}
	table.insert(v8_, v9_)
end

-- Local values: list, filename
function ShopController:addCategoryForDisplay(category, categoryList, itemFilename)
	if categoryList[category.type] == nil then
		categoryList[category.type] = {}
	end
	local v13_ = categoryList[category.type]
	local v14_ = category.image
	if v14_ ~= ShopController.EMPTY_FILENAME then
		itemFilename = v14_
	end
	local v15_ = {
		["id"] = category.name,
		["iconFilename"] = itemFilename,
		["label"] = category.title,
		["sortValue"] = category.orderId
	}
	table.insert(v13_, v15_)
end

-- Local values: foundBrands, foundCategory, foundDLCCategory, foundDLCs, displayMods, displayDLCs, _, storeItem, brand, isDLCItem, i, category, categoryName, info, displayPacks, _, pack, lastLetter, i, brand, letter, list, _, subTable, _, subTable, _, subTable, _, subTable
function ShopController:load()
	if not self.isInitialized then
		local v17_ = {}
		local v18_ = {}
		local v19_ = {}
		local v20_ = {}
		local v21_ = {}
		local v22_ = {}
		for _, v23_ in ipairs(g_storeManager:getItems()) do
			if v23_.showInStore and (#v23_.categoryNames ~= 0 and (v23_.species ~= StoreSpecies.PLACEABLE and (v23_.species ~= StoreSpecies.ANIMAL and (v23_.extraContentId == nil or g_extraContentSystem:getIsItemIdUnlocked(v23_.extraContentId))))) then
				local v24_ = g_brandManager:getBrandByIndex(v23_.brandIndex)
				if v24_ ~= nil and (not v17_[v23_.brandIndex] and (v23_.species == StoreSpecies.VEHICLE or v23_.species == StoreSpecies.HANDTOOL)) then
					v17_[v23_.brandIndex] = true
					if v24_.name ~= "NONE" then
						self:addBrandForDisplay(v24_)
					end
				end
				local v25_
				if v23_.customEnvironment == nil then
					v25_ = false
				else
					v25_ = v23_.species == StoreSpecies.VEHICLE and true or v23_.species == StoreSpecies.HANDTOOL
				end
				for v26_ = 1, #v23_.categoryNames do
					local v27_ = g_storeManager:getCategoryByName(v23_.categoryNames[v26_])
					if v27_ ~= nil then
						local v28_ = v23_.categoryNames[v26_]
						if not v18_[v28_] then
							v18_[v28_] = true
							self:addCategoryForDisplay(v27_, self.shopCategories, v23_.imageFilename)
						end
						if v25_ and not v19_[v28_] then
							v19_[v28_] = true
							self:addCategoryForDisplay(v27_, self.shopDLCCategories, v23_.imageFilename)
						end
					end
				end
				if v25_ and v20_[v23_.customEnvironment] == nil then
					local v29_ = {
						["id"] = v23_.customEnvironment,
						["isMod"] = v23_.isMod,
						["label"] = v23_.dlcTitle,
						["iconFilename"] = g_modManager:getModIconByName(v23_.customEnvironment),
						["sortValue"] = (v23_.isMod and "" or "    ") .. v23_.dlcTitle
					}
					v20_[v23_.customEnvironment] = true
					if v23_.isMod then
						table.insert(v21_, v29_)
					else
						table.insert(v22_, v29_)
					end
				end
			end
		end
		if #v22_ > 0 then
			self.displayDLCs[utf8ToUpper(g_i18n:getText(ShopController.L10N_SYMBOL.CATEGORY_DLC))] = v22_
		end
		if #v21_ > 0 then
			self.displayDLCs[utf8ToUpper(g_i18n:getText(ShopController.L10N_SYMBOL.CATEGORY_MODS))] = v21_
		end
		local v30_ = {}
		for _, v31_ in pairs(g_storeManager:getPacks()) do
			local v32_ = {
				["id"] = v31_.name,
				["iconFilename"] = v31_.image,
				["label"] = v31_.title,
				["sortValue"] = v31_.orderId
			}
			table.insert(v30_, v32_)
		end
		self.displayPacks[utf8ToUpper(g_i18n:getText(ShopController.L10N_SYMBOL.CATEGORY_PACKS))] = v30_
		if Platform.hasInAppPurchases then
			self:addCategoryForDisplay(g_storeManager:getCategoryByName(ShopController.COINS_CATEGORY))
		end
		table.sort(self.displayBrands, ShopController.brandSortFunction)
		local v33_ = nil
		for _, v34_ in ipairs(self.displayBrands) do
			local v35_ = utf8ToUpper(utf8Substr(v34_.label, 0, 1))
			if v33_ ~= v35_ then
				self.displayBrandNames[v35_] = {}
				local v36_ = self.displayBrandCategories
				table.insert(v36_, {
					["name"] = v35_
				})
				v33_ = v35_
			end
			local v37_ = self.displayBrandNames[v35_]
			table.insert(v37_, v34_)
		end
		for _, v38_ in pairs(self.shopCategories) do
			table.sort(v38_, ShopController.categorySortFunction)
		end
		for _, v39_ in pairs(self.shopDLCCategories) do
			table.sort(v39_, ShopController.categorySortFunction)
		end
		for _, v40_ in pairs(self.displayPacks) do
			table.sort(v40_, ShopController.categorySortFunction)
		end
		for _, v41_ in pairs(self.displayDLCs) do
			table.sort(v41_, ShopController.brandSortFunction)
		end
		self.isInitialized = true
	end
end

function ShopController:setClient(client)
	self.client = client
end

function ShopController:setCurrentMission(currentMission)
	self.currentMission = currentMission
	g_inAppPurchaseController:setMission(currentMission)
end

function ShopController:setPlayerFarm(playerFarm)
	self.playerFarm = playerFarm
	if playerFarm == nil then
		self.playerFarmId = 0
	else
		self.playerFarmId = playerFarm.farmId
	end
end

function ShopController:setUpdateShopItemsCallback(callback, target)
	function self.updateShopItemsCallback()
		-- upvalues: (copy) callback, (copy) target
		callback(target)
	end
end

function ShopController:setUpdateAllItemsCallback(callback, target)
	function self.updateAllItemsCallback()
		-- upvalues: (copy) callback, (copy) target
		callback(target)
	end
end

function ShopController:setSaleItemBoughtCallback(callback, target)
	function self.saleItemBoughtCallback()
		-- upvalues: (copy) callback, (copy) target
		callback(target)
	end
end

function ShopController:setSwitchToConfigurationCallback(callback, target)
	function self.switchToConfigurationCallback(...)
		-- upvalues: (copy) callback, (copy) target
		callback(target, ...)
	end
end

-- Local values: filteredItems, storeItem, itemInfos, _, concreteItem, filteredItemInfos
function ShopController.filterOwnedItemsByFarmId(ownedFarmItems, farmId)
	local v62_ = {}
	for v63_, v64_ in pairs(ownedFarmItems) do
		for _, v65_ in pairs(v64_.items) do
			if v65_:getOwnerFarmId() == farmId then
				local v66_ = v62_[v63_]
				if v66_ == nil then
					v66_ = {}
					v62_[v63_] = v66_
					v66_.storeItem = v63_
					v66_.numItems = 0
					v66_.items = {}
				end
				v66_.numItems = v66_.numItems + 1
				v66_.items[v65_] = v65_
			end
		end
	end
	return v62_
end

function ShopController:setOwnedFarmItems(ownedFarmItems, playerFarmId)
	self.ownedFarmItems = ShopController.filterOwnedItemsByFarmId(ownedFarmItems, playerFarmId)
end

function ShopController:setLeasedFarmItems(leasedFarmItems, playerFarmId)
	self.leasedFarmItems = ShopController.filterOwnedItemsByFarmId(leasedFarmItems, playerFarmId)
end

function ShopController:update(dt)
	if self.buyVehicleNow > 0 then
		if self.buyVehicleNow == 2 then
			self.buyVehicleNow = 0
			self.client:getServerConnection():sendEvent(BuyVehicleEvent.new(self.vehicleBuyData))
			if not self.buyItemIsFreeOfCharge then
				self.updateShopItemsCallback()
			end
		else
			self.buyVehicleNow = self.buyVehicleNow + 1
		end
	end
	if self.buyObjectNow > 0 then
		if self.buyObjectNow == 2 then
			self.buyObjectNow = 0
			self.client:getServerConnection():sendEvent(BuyObjectEvent.new(self.buyItemFilename, self.buyItemIsFreeOfCharge, self.playerFarmId))
			if not self.buyItemIsFreeOfCharge then
				self.updateShopItemsCallback()
			end
		else
			self.buyObjectNow = self.buyObjectNow + 1
		end
	end
	if self.buyHandToolNow > 0 then
		if self.buyHandToolNow == 2 then
			self.buyHandToolNow = 0
			self.client:getServerConnection():sendEvent(BuyHandToolEvent.new(self.handToolBuyData))
			if not self.buyItemIsFreeOfCharge then
				self.updateShopItemsCallback()
				return
			end
		else
			self.buyHandToolNow = self.buyHandToolNow + 1
		end
	end
end

-- Local values: attributeIconProfiles, attributeValues, addAttribute, usedSpecs, addSpecFromVehicle, addSpec, _, specDesc, fillTypesSpec, seedFillTypeSpec, foodFillTypesSpec, prodPointInputFillTypesSpec, prodPointOutputFillTypesSpec, sellingStationFillTypesSpec, buyingStationFillTypesSpec, objectStorageFillTypesSpec, fillTypeIconFilenames, seedTypeIconFilenames, foodFillTypeIconFilenames, prodPointInputFillTypeIconFilenames, prodPointOutputFillTypeIconFilenames, sellingStationFillTypesIconFilenames, buyingStationFillTypesIconFilenames, objectStorageFillTypesIconFilenames, getIconFilenamesForSpec, _, bundleItem, configName, data, iconFilenames, descriptionText, category, numOwned, numLeased, _, product, _, product
function ShopController:makeDisplayItem(storeItem, realItem, configurations, saleItem, ignoreInAppPurchase)
	StoreItemUtil.loadSpecsFromXML(storeItem)
	local v_u_80_ = {}
	local v_u_81_ = {}
	if configurations == nil then
		configurations = storeItem.defaultConfigurationIds
	end
	local v_u_82_ = {
		["fillTypes"] = true,
		["seedFillTypes"] = true,
		["animalFoodFillTypes"] = true,
		["prodPointInputFillTypes"] = true,
		["prodPointOutputFillTypes"] = true,
		["sellingStationFillTypes"] = true,
		["buyingStationFillTypes"] = true,
		["objectStorageFillTypes"] = true,
		["powerConfig"] = true
	}
	local function v_u_94_(p83_, p84_, p85_, p86_, p87_, p88_)
		-- upvalues: (copy) v_u_82_, (copy) v_u_80_, (copy) v_u_81_
		if v_u_82_[p83_] == nil then
			if p86_ == nil then
				if p88_ ~= nil then
					p87_ = p88_.configurations
				end
			else
				p87_ = p86_.configurations
			end
			if p84_.getValueFunc ~= nil then
				local v89_, v90_ = p84_.getValueFunc(p85_, p86_, p87_, p88_)
				if v89_ ~= nil then
					local v91_ = v_u_80_
					local v92_ = v_u_81_
					local v93_ = v90_ or p84_.profile
					if v93_ ~= nil and v89_ ~= nil then
						table.insert(v91_, v93_)
						table.insert(v92_, v89_)
					end
					v_u_82_[p83_] = true
				end
			end
		end
	end
	local function v100_(p95_)
		-- upvalues: (copy) storeItem, (copy) v_u_94_, (copy) realItem, (ref) configurations, (copy) saleItem
		if Platform.gameplay.disabledShopSpecValues[p95_] ~= true then
			local v96_ = g_storeManager:getSpecTypeByName(p95_)
			if v96_ ~= nil and v96_.species == storeItem.species then
				v_u_94_(p95_, v96_, storeItem, realItem, configurations, saleItem)
				if storeItem.bundleInfo ~= nil then
					for _, v97_ in ipairs(storeItem.bundleInfo.bundleItems) do
						if configurations == nil then
							configurations = {}
						end
						for v98_, v99_ in pairs(v97_.preSelectedConfigurations) do
							configurations[v98_] = v99_.configValue
						end
						v_u_94_(p95_, v96_, v97_.item, nil, configurations, saleItem)
					end
				end
			end
		end
	end
	v100_("operatingTime")
	v100_("power")
	v100_("transmission")
	v100_("fuel")
	v100_("electricCharge")
	v100_("methane")
	v100_("maxSpeed")
	v100_("neededPower")
	v100_("incomePerHour")
	v100_("capacity")
	v100_("weight")
	v100_("additionalWeight")
	v100_("wheels")
	v100_("balerBaleDensity")
	v100_("balerBaleSizeRound")
	v100_("balerBaleSizeSquare")
	v100_("baleWrapperBaleSizeRound")
	v100_("baleWrapperBaleSizeSquare")
	v100_("inlineWrapperBaleSizeRound")
	v100_("inlineWrapperBaleSizeSquare")
	v100_("baleLoaderBaleSizeRound")
	v100_("baleLoaderBaleSizeSquare")
	v100_("woodHarvesterMaxTreeSize")
	v100_("licensePlate")
	if self.currentMission.slotSystem:getAreSlotsVisible() then
		v100_("slots")
		v100_("placeableSlots")
	else
		v_u_82_.slots = true
		v_u_82_.placeableSlots = true
	end
	if realItem == nil or (realItem.propertyState == VehiclePropertyState.OWNED or saleItem ~= nil) then
		v100_("dailyUpkeep")
	else
		v_u_82_.dailyUpkeep = true
	end
	if storeItem.lifetime ~= 0 or saleItem ~= nil then
		v100_("age")
	end
	for _, v101_ in ipairs(g_storeManager:getSpecTypes()) do
		if v_u_82_[v101_.name] == nil then
			v100_(v101_.name)
		end
	end
	local v102_ = g_storeManager:getSpecTypeByName("fillTypes")
	local v103_ = g_storeManager:getSpecTypeByName("seedFillTypes")
	local v104_ = g_storeManager:getSpecTypeByName("animalFoodFillTypes")
	local v105_ = g_storeManager:getSpecTypeByName("prodPointInputFillTypes")
	local v106_ = g_storeManager:getSpecTypeByName("prodPointOutputFillTypes")
	local v107_ = g_storeManager:getSpecTypeByName("sellingStationFillTypes")
	local v108_ = g_storeManager:getSpecTypeByName("buyingStationFillTypes")
	local v109_ = g_storeManager:getSpecTypeByName("objectStorageFillTypes")
	local v110_ = nil
	local v111_ = nil
	local v112_ = nil
	local v113_ = nil
	local v114_ = nil
	local v115_ = nil
	local v116_ = nil
	local v117_ = nil
	local function v127_(p118_, p119_, p120_, p121_)
		local v122_ = {}
		if p118_ ~= nil then
			local v123_ = p118_.getValueFunc(p119_, p120_, p121_)
			if v123_ ~= nil then
				for _, v124_ in pairs(v123_) do
					local v125_ = g_fillTypeManager:getFillTypeByIndex(v124_)
					if v125_ ~= nil then
						local v126_ = v125_.hudOverlayFilename
						table.insert(v122_, v126_)
					end
				end
			end
		end
		return v122_
	end
	if storeItem.bundleInfo == nil then
		v110_ = v127_(v102_, storeItem, realItem)
		v111_ = v127_(v103_, storeItem, realItem)
		v112_ = v127_(v104_, storeItem, realItem)
		v113_ = v127_(v105_, storeItem, realItem)
		v114_ = v127_(v106_, storeItem, realItem)
		v115_ = v127_(v107_, storeItem, realItem)
		v116_ = v127_(v108_, storeItem, realItem)
		v117_ = v127_(v109_, storeItem, realItem)
	else
		for _, v128_ in ipairs(storeItem.bundleInfo.bundleItems) do
			configurations = configurations == nil and {} or configurations
			for v129_, v130_ in pairs(v128_.preSelectedConfigurations) do
				configurations[v129_] = v130_.configValue
			end
			v110_ = v127_(v102_, v128_.item, nil, configurations)
			v111_ = v127_(v103_, v128_.item, nil, configurations)
			v112_ = v127_(v104_, v128_.item, nil, configurations)
		end
	end
	local v131_ = {
		["fillTypeIconFilenames"] = v110_,
		["seedTypeIconFilenames"] = v111_,
		["foodFillTypeIconFilenames"] = v112_,
		["prodPointInputFillTypeIconFilenames"] = v113_,
		["prodPointOutputFillTypeIconFilenames"] = v114_,
		["sellingStationFillTypesIconFilenames"] = v115_,
		["buyingStationFillTypesIconFilenames"] = v116_,
		["objectStorageFillTypesIconFilenames"] = v117_
	}
	local v132_ = storeItem.functions and (table.concat(storeItem.functions, " ") or "") or ""
	local v133_ = g_storeManager:getCategoryByName(storeItem.categoryName)
	local v134_ = nil
	local v135_ = nil
	if g_currentMission ~= nil then
		if StoreItemUtil.getIsLeasable(storeItem) then
			v134_ = g_currentMission:getNumOwnedItems(storeItem, g_currentMission:getFarmId())
			if not GS_IS_MOBILE_VERSION then
				v135_ = g_currentMission:getNumLeasedItems(storeItem, g_currentMission:getFarmId())
			end
		elseif not StoreItemUtil.getIsObject(storeItem) then
			v134_ = g_currentMission:getNumOfItems(storeItem, self.playerFarmId)
		end
	end
	if Platform.hasInAppPurchases and not ignoreInAppPurchase then
		for _, v136_ in ipairs(g_inAppPurchaseController:getProducts()) do
			if v136_:isa(IAProductStoreItem) and (v136_:getIsStoreItemOfProduct(storeItem) and not v136_:getHasBeenBought()) then
				return v136_:getDisplayItem(storeItem, realItem, v_u_80_, v_u_81_, v131_, v132_, v133_.orderId, v134_, v135_, saleItem)
			end
		end
	end
	if Platform.hasInAppPurchases and not ignoreInAppPurchase then
		for _, v137_ in ipairs(g_inAppPurchaseController:getProducts()) do
			if v137_:isa(IAProductStoreItem) and (v137_:getIsStoreItemOfProduct(storeItem) and not v137_:getHasBeenBought()) then
				return v137_:getDisplayItem(storeItem, realItem, v_u_80_, v_u_81_, v131_, v132_, v133_.orderId, v134_, v135_, saleItem)
			end
		end
	end
	return ShopDisplayItem.new(storeItem, realItem, v_u_80_, v_u_81_, v131_, v132_, v133_.orderId, v134_, v135_, saleItem)
end

-- Local values: newDisplayItems, _, oldDisplayItem, storeItem, newDisplayItem
function ShopController:updateDisplayItems(displayItems)
	local v140_ = {}
	for _, v141_ in ipairs(displayItems) do
		local v142_ = g_storeManager:getItemByXMLFilename(v141_.storeItem.xmlFilename)
		if v142_ == nil then
			table.insert(v140_, v141_)
		else
			local v143_ = self:makeDisplayItem(v142_, nil)
			table.insert(v140_, v143_)
		end
	end
	return v140_
end

-- Local values: displayItems, storeItem, itemInfos, concreteItem, displayItem
function ShopController:getOwnedItems()
	local v145_ = {}
	for v146_, v147_ in pairs(self.ownedFarmItems) do
		for v148_ in pairs(v147_.items) do
			if v146_.canBeSold then
				local v149_ = self:makeDisplayItem(v146_, v148_)
				table.insert(v145_, v149_)
			end
		end
	end
	table.sort(v145_, ShopController.displayItemSortFunction)
	return v145_
end

-- Local values: displayItems, storeItem, itemInfos, concreteItem, displayItem
function ShopController:getLeasedItems()
	local v151_ = {}
	for v152_, v153_ in pairs(self.leasedFarmItems) do
		for v154_ in pairs(v153_.items) do
			local v155_ = self:makeDisplayItem(v152_, v154_)
			table.insert(v151_, v155_)
		end
	end
	table.sort(v151_, ShopController.displayItemSortFunction)
	return v151_
end

function ShopController:getOwnedFarmItems()
	return self.ownedFarmItems
end

function ShopController:getLeasedFarmItems()
	return self.leasedFarmItems
end

function ShopController:getBrands()
	return self.displayBrands
end

function ShopController:getBrandCategories()
	return self.displayBrandCategories
end

function ShopController:getBrandNames()
	return self.displayBrandNames
end

function ShopController:getShopCategories()
	return self.shopCategories
end

function ShopController:getShopDLCCategories()
	return self.shopDLCCategories
end

function ShopController:getVehicleCategories()
	return self.displayVehicleCategories
end

function ShopController:getToolCategories()
	return self.displayToolCategories
end

function ShopController:getObjectCategories()
	return self.displayObjectCategories
end

function ShopController:getPlaceableCategories()
	return self.displayPlaceableCategories
end

-- Local values: items, salesCategory, brand, _, storeItem, sale, isUnlocked, displayItem
function ShopController:getItemsByBrand(brandId)
	local v169_ = g_storeManager:getCategoryByName("sales")
	local v170_ = g_brandManager:getBrandByIndex(brandId)
	local v171_ = {}
	for _, v172_ in pairs(g_storeManager:getItems()) do
		local v173_
		if g_currentMission == nil then
			v173_ = nil
		else
			local v174_, v175_
			v174_, v175_, v173_ = g_currentMission.economyManager:getBuyPrice(v172_)
		end
		local v176_ = v172_.extraContentId == nil and true or g_extraContentSystem:getIsItemIdUnlocked(v172_.extraContentId)
		if not v172_.isBundleItem and (v176_ and (v172_.showInStore and (v172_.brandIndex == brandId or v173_ ~= nil and v170_.title == v169_.title))) and (v172_.species == StoreSpecies.VEHICLE or v172_.species == StoreSpecies.HANDTOOL) then
			local v177_ = self:makeDisplayItem(v172_)
			table.insert(v171_, v177_)
		end
	end
	return v171_
end

-- Local values: items, _, storeItem, displayItem
function ShopController:getItemsByStoreItems(storeItems)
	local v180_ = {}
	for _, v181_ in ipairs(storeItems) do
		local v182_ = self:makeDisplayItem(v181_)
		table.insert(v180_, v182_)
	end
	return v180_
end

-- Local values: items, _, storeItem, isUnlocked, isDLCItem, i, displayItem
function ShopController:getItemsByCategory(categoryName, onlyDLCItems)
	if categoryName == ShopController.COINS_CATEGORY then
		return self:getCoinItems()
	end
	if categoryName == ShopController.SALES_CATEGORY then
		return self:getSaleItems()
	end
	local v186_ = {}
	for _, v187_ in pairs(g_storeManager:getItems()) do
		local v188_ = v187_.extraContentId == nil and true or g_extraContentSystem:getIsItemIdUnlocked(v187_.extraContentId)
		local v189_
		if v187_.customEnvironment == nil then
			v189_ = false
		else
			v189_ = v187_.species == StoreSpecies.VEHICLE
		end
		if not v187_.isBundleItem and (v188_ and (v187_.showInStore and (v187_.species == StoreSpecies.VEHICLE or v187_.species == StoreSpecies.HANDTOOL))) then
			for v190_ = 1, #v187_.categoryNames do
				if categoryName == v187_.categoryNames[v190_] and (not onlyDLCItems or v189_) then
					local v191_ = self:makeDisplayItem(v187_)
					table.insert(v186_, v191_)
					break
				end
			end
		end
	end
	return v186_
end

-- Local values: list, items, _, item, storeItem, displayItem
function ShopController:getSaleItems()
	local v193_ = g_currentMission.vehicleSaleSystem:getItems()
	local v194_ = {}
	for _, v195_ in ipairs(v193_) do
		local v196_ = self:makeDisplayItem(g_storeManager:getItemByXMLFilename(v195_.xmlFilename), nil, v195_.configurations, v195_)
		table.insert(v194_, v196_)
	end
	return v194_
end

-- Local values: input, items, storeItem, itemInfos, add, concreteItem, displayItem
function ShopController:getItemsByCategoryOwnedOrLeased(categoryName, owned, leased)
	if categoryName == ShopController.COINS_CATEGORY then
		return self:getCoinItems()
	end
	local v201_ = {}
	if owned then
		v201_ = self.ownedFarmItems
	elseif leased then
		v201_ = self.leasedFarmItems
	end
	local v202_ = {}
	for v203_, v204_ in pairs(v201_) do
		local v205_ = false
		if v203_.canBeSold and (v203_.showInStore or v203_.isBundleItem) then
			v205_ = v203_.categoryName == categoryName and true or v205_
		end
		if v205_ then
			if owned then
				v205_ = self.ownedFarmItems[v203_] ~= nil
			elseif leased then
				v205_ = self.leasedFarmItems[v203_] ~= nil
			end
		end
		if v205_ then
			for v206_ in pairs(v204_.items) do
				local v207_ = self:makeDisplayItem(v203_, v206_)
				table.insert(v202_, v207_)
			end
		end
	end
	table.sort(v202_, ShopController.displayItemSortFunction)
	return v202_
end

-- Local values: output, categories, storeItem, itemInfos, imageFilename, _, concreteItem, categoryName, iconFilename, category
function ShopController:getOwnedCategories()
	local v209_ = {}
	local v210_ = {}
	for v211_, v212_ in pairs(self.ownedFarmItems) do
		if v211_.canBeSold and (v211_.showInStore or v211_.isBundleItem) and (v211_.species == StoreSpecies.VEHICLE and v209_[v211_.categoryName] == nil) then
			local v213_ = v211_.imageFilename
			for _, v214_ in pairs(v212_.items) do
				if v214_.getImageFilename ~= nil then
					v213_ = v214_:getImageFilename()
				end
			end
			v209_[v211_.categoryName] = v213_
		end
	end
	for v215_, v216_ in pairs(v209_) do
		local v217_ = g_storeManager:getCategoryByName(v215_)
		if v217_ ~= nil then
			local v218_ = {
				["id"] = v217_.name,
				["iconFilename"] = v216_,
				["label"] = v217_.title,
				["sortValue"] = v217_.orderId
			}
			table.insert(v210_, v218_)
		end
	end
	table.sort(v210_, ShopController.categorySortFunction)
	return v210_
end

-- Local values: output, categories, storeItem, _, categoryName, iconFilename, category
function ShopController:getLeasedCategories()
	local v220_ = {}
	local v221_ = {}
	for v222_, _ in pairs(self.leasedFarmItems) do
		v220_[v222_.categoryName] = v222_.imageFilename
	end
	for v223_, v224_ in pairs(v220_) do
		local v225_ = g_storeManager:getCategoryByName(v223_)
		if v225_ ~= nil then
			local v226_ = {
				["id"] = v225_.name,
				["iconFilename"] = v224_,
				["label"] = v225_.title,
				["sortValue"] = v225_.orderId
			}
			table.insert(v221_, v226_)
		end
	end
	return v221_
end

function ShopController:getDLCCategories()
	return self.displayDLCs
end

function ShopController:getDLCCategoryTypes()
	return {
		{
			["name"] = utf8ToUpper(g_i18n:getText(ShopController.L10N_SYMBOL.CATEGORY_DLC))
		},
		{
			["name"] = utf8ToUpper(g_i18n:getText(ShopController.L10N_SYMBOL.CATEGORY_MODS))
		}
	}
end

function ShopController:getStorePacks()
	return self.displayPacks
end

function ShopController:getStorePackTypes()
	return {
		{
			["name"] = utf8ToUpper(g_i18n:getText(ShopController.L10N_SYMBOL.CATEGORY_PACKS))
		}
	}
end

-- Local values: items, packItems, i, storeItem, displayItem
function ShopController:getItemsByPack(packName)
	local v231_ = {}
	local v232_ = g_storeManager:getPackItems(packName)
	if v232_ == nil then
		return v231_
	end
	for v233_ = 1, #v232_ do
		local v234_ = g_storeManager:getItemByXMLFilename(v232_[v233_])
		if v234_ == nil then
			Logging.warning("Vehicle \'%s\' not found! Ignoring it for vehicle pack \'%s\'.", v232_[v233_], packName)
		elseif not v234_.isBundleItem and v234_.showInStore then
			local v235_ = self:makeDisplayItem(v234_)
			table.insert(v231_, v235_)
		end
	end
	return v231_
end

-- Local values: items, _, storeItem, displayItem
function ShopController:getItemsByDLC(dlcId)
	local v238_ = {}
	for _, v239_ in pairs(g_storeManager:getItems()) do
		if not v239_.isBundleItem and (v239_.showInStore and (v239_.customEnvironment == dlcId and (v239_.species == StoreSpecies.VEHICLE or (v239_.species == StoreSpecies.HANDTOOL or v239_.species == StoreSpecies.OBJECT)))) then
			local v240_ = self:makeDisplayItem(v239_)
			table.insert(v238_, v240_)
		end
	end
	return v238_
end

-- Local values: items, _, xmlFilename, storeItem, displayItem
function ShopController:getItemsWithFilenames(filenames)
	local v243_ = {}
	for _, v244_ in ipairs(filenames) do
		local v245_ = g_storeManager:getItemByXMLFilename(v244_)
		if v245_ ~= nil and (not v245_.isBundleItem and v245_.showInStore) then
			local v246_ = self:makeDisplayItem(v245_)
			table.insert(v243_, v246_)
		end
	end
	return v243_
end

-- Local values: items, alreadyAddedStoreItems, _, combinationData, combinationItems, _, item, displayItem
function ShopController:getItemsFromCombinations(combinations)
	local v249_ = {}
	local v250_ = {}
	for _, v251_ in ipairs(combinations) do
		local v252_ = g_storeManager:getItemsByCombinationData(v251_)
		for _, v253_ in ipairs(v252_) do
			if not v249_[v253_.storeItem] then
				local v254_ = self:makeDisplayItem(v253_.storeItem, nil, v253_.configData)
				v254_.configurations = v253_.configData
				v249_[v253_.storeItem] = true
				table.insert(v250_, v254_)
			end
		end
	end
	return v250_
end

-- Local values: enoughMoney, enoughSlots, enoughItems
function ShopController:canBeBought(storeItem, price)
	local v258_ = self.currentMission == nil and true or price <= g_currentMission:getMoney()
	local v259_ = self.currentMission.slotSystem:hasEnoughSlots(storeItem)
	if v258_ then
		if not v259_ then
			InfoDialog.show(g_i18n:getText(ShopController.L10N_SYMBOL.WARNING_NOT_ENOUGH_SLOTS), DialogElement.TYPE_WARNING)
		end
	else
		InfoDialog.show(g_i18n:getText(ShopController.L10N_SYMBOL.WARNING_NOT_ENOUGH_MONEY), DialogElement.TYPE_WARNING)
	end
	local v260_
	if storeItem.maxItemCount == nil then
		v260_ = true
	elseif storeItem.maxItemCount == nil then
		v260_ = false
	else
		v260_ = self.currentMission:getNumOfItems(storeItem, self.playerFarmId) < storeItem.maxItemCount
	end
	if not v260_ then
		InfoDialog.show(g_i18n:getText(ShopController.L10N_SYMBOL.WARNING_TOO_MANY_PLACEABLES), DialogElement.TYPE_WARNING)
	end
	if v259_ then
		if not v258_ then
			v260_ = v258_
		end
	else
		v260_ = v259_
	end
	return v260_
end

-- Local values: price
function ShopController:buy(storeItem, saleItem, isFreeOfCharge, configurations)
	if self.isSelling then
		return
	else
		local v266_
		if isFreeOfCharge then
			v266_ = 0
		elseif saleItem == nil then
			v266_ = self.currentMission.economyManager:getBuyPrice(storeItem)
		else
			v266_ = saleItem.price
		end
		if StoreItemUtil.getIsVehicle(storeItem) then
			self:buyVehicle(storeItem, saleItem, v266_, isFreeOfCharge, configurations)
		elseif self:canBeBought(storeItem, v266_) then
			if StoreItemUtil.getIsObject(storeItem) then
				self:buyObject(storeItem, v266_, isFreeOfCharge)
				return
			end
			if StoreItemUtil.getIsHandTool(storeItem) then
				self:buyHandTool(storeItem, v266_, isFreeOfCharge)
			end
		end
	end
end

function ShopController:buyVehicle(vehicleStoreItem, saleItem, price, isFreeOfCharge, configurations)
	self.buyItemFilename = vehicleStoreItem.xmlFilename
	self.buyItemPrice = price
	self.buyItemIsFreeOfCharge = isFreeOfCharge or false
	self.buyItemConfigurations = nil
	self.buyItemLicensePlateData = nil
	self.buyItemIsLeasing = false
	self.buyItemSaleItem = saleItem
	if StoreItemUtil.getCanBeShownInConfigScreen(vehicleStoreItem) and Platform.hasConfigScreen then
		self.switchToConfigurationCallback(vehicleStoreItem, saleItem, configurations)
	elseif self:canBeBought(vehicleStoreItem, price) then
		self:finalizeBuy()
	end
end

function ShopController:onYesNoBuyObject(yes)
	if yes then
		self.isBuying = true
		self.buyObjectNow = 1
	end
end

-- Local values: text, callback, target
function ShopController:buyObject(objectStoreItem, price, isFreeOfCharge)
	local v279_ = string.format(g_i18n:getText(ShopController.L10N_SYMBOL.BUY_CONFIRMATION), g_i18n:formatMoney(price, 0, true, true))
	local v280_ = self.onYesNoBuyObject
	YesNoDialog.show(v280_, self, v279_)
	self.buyItemFilename = objectStoreItem.xmlFilename
	self.buyItemPrice = price
	self.buyItemIsFreeOfCharge = isFreeOfCharge
	self.buyItemConfigurations = nil
	self.buyItemLicensePlateData = nil
	self.buyItemIsLeasing = false
end

function ShopController:onYesNoBuyHandtool(yes)
	if yes then
		self.isBuying = true
		self.buyHandToolNow = 1
	end
end

-- Local values: handToolBuyData, text, callback, target
function ShopController:buyHandTool(handToolStoreItem, price, isFreeOfCharge)
	local v286_ = BuyHandToolData.new()
	v286_:setStoreItem(handToolStoreItem)
	v286_:setOwnerFarmId(self.playerFarmId)
	v286_:setPrice(price)
	if v286_:isValid() then
		v286_:updatePrice()
		self.handToolBuyData = v286_
		local v287_ = string.format(g_i18n:getText(ShopController.L10N_SYMBOL.BUY_CONFIRMATION), g_i18n:formatMoney(price, 0, true, true))
		local v288_ = self.onYesNoBuyHandtool
		YesNoDialog.show(v288_, self, v287_)
	end
end

-- Local values: canBeSold, warning, sellPrice
function ShopController:sell(storeItem, concreteItem, isDirectSell)
	self.isSelling = true
	self.currentSellStoreItem = storeItem
	self.currentSellItem = concreteItem
	if StoreItemUtil.getIsPlaceable(storeItem) then
		if self.currentMission:getNumOwnedItems(storeItem, g_currentMission:getFarmId()) == 1 then
			local v293_, v294_ = concreteItem:canBeSold()
			if v294_ == nil then
				self:sellPlaceableWarningInfoClickOk(true)
				return
			elseif v293_ then
				YesNoDialog.show(self.sellPlaceableWarningInfoClickOk, self, v294_, nil, g_i18n:getText("button_ok"), g_i18n:getText("button_cancel"))
			else
				InfoDialog.show(v294_, nil, nil, DialogElement.TYPE_WARNING)
				self.isSelling = false
			end
		end
		if self.currentMission:getNumOwnedItems(storeItem, g_currentMission:getFarmId()) > 1 then
			self:onSellCallback(true)
			return
		end
	else
		local v295_
		if concreteItem == ShopDisplayItem.NO_CONCRETE_ITEM then
			v295_ = self.currentMission.economyManager:getSellPrice(storeItem)
		else
			v295_ = self.currentMission.economyManager:getSellPrice(concreteItem)
		end
		if isDirectSell then
			v295_ = v295_ * EconomyManager.DIRECT_SELL_MULTIPLIER
		end
		SellItemDialog.show(self.onSellCallback, self, concreteItem, v295_, storeItem, isDirectSell)
	end
end

function ShopController:sellPlaceableWarningInfoClickOk(yes)
	if yes then
		SellItemDialog.show(self.onSellCallback, self, self.currentSellItem, g_currentMission.economyManager:getSellPrice(self.currentSellItem))
	end
end

function ShopController:onSellCallback(yes, isDirectSell)
	self.isSelling = false
	if yes then
		self:onSellItem(self.currentSellStoreItem, self.currentSellItem, isDirectSell)
		self.currentSellItem = nil
	end
end

function ShopController:onSellItem(storeItem, concreteItem, isDirectSell)
	if self.isSelling then
		return
	elseif StoreItemUtil.getIsPlaceable(storeItem) then
		self:sellPlaceable(storeItem, concreteItem)
		return
	elseif StoreItemUtil.getIsHandTool(storeItem) then
		self:sellHandTool(concreteItem)
	else
		self:sellVehicle(concreteItem, isDirectSell)
	end
end

-- Local values: text
function ShopController:sellHandTool(handTool)
	self.isSelling = true
	if self.currentMission:getHasPlayerPermission(Farm.PERMISSION.SELL_VEHICLE) then
		local v307_ = g_i18n:getText(ShopController.L10N_SYMBOL.SELLING_VEHICLE)
		MessageDialog.show(v307_)
		if NetworkUtil.getObjectId(handTool) == nil then
			self:onHandToolSellFailed(SellVehicleEvent.SELL_NO_PERMISSION)
		else
			self.client:getServerConnection():sendEvent(SellHandToolEvent.new(handTool))
		end
	else
		self:onHandToolSellFailed(SellVehicleEvent.SELL_NO_PERMISSION)
		return
	end
end

-- Local values: text, text
function ShopController:sellVehicle(vehicle, isDirectSell)
	self.isSelling = true
	if self.currentMission:getHasPlayerPermission(Farm.PERMISSION.SELL_VEHICLE) and vehicle == self.currentMission.controlledVehicle then
		g_localPlayer:leaveVehicle()
	end
	if vehicle.propertyState == VehiclePropertyState.OWNED then
		local v311_ = g_i18n:getText(ShopController.L10N_SYMBOL.SELLING_VEHICLE)
		MessageDialog.show(v311_)
	else
		local v312_ = g_i18n:getText(ShopController.L10N_SYMBOL.RETURNING_VEHICLE)
		MessageDialog.show(v312_)
	end
	if NetworkUtil.getObjectId(vehicle) == nil then
		self:onVehicleSellFailed(vehicle.propertyState == VehiclePropertyState.OWNED, SellVehicleEvent.SELL_NO_PERMISSION)
	else
		self.client:getServerConnection():sendEvent(SellVehicleEvent.new(vehicle, isDirectSell and EconomyManager.DIRECT_SELL_MULTIPLIER or 1, isDirectSell))
	end
end

function ShopController:setConfigurations(vehicleBuyData)
	if vehicleBuyData:isValid() then
		vehicleBuyData:updatePrice()
		self.vehicleBuyData = vehicleBuyData
		g_currentMission:setLastCreatedLicensePlate(vehicleBuyData.licensePlateData)
		self:finalizeBuy()
	end
end

-- Local values: text
function ShopController:finalizeBuy()
	self.isBuying = true
	self.buyVehicleNow = 1
	local v316_ = g_i18n:getText(ShopController.L10N_SYMBOL.BUYING_VEHICLE)
	if self.buyItemIsLeasing then
		v316_ = g_i18n:getText(ShopController.L10N_SYMBOL.LEASING_VEHICLE)
	end
	MessageDialog.show(v316_)
end

function ShopController:onHandToolSellEvent(errorCode)
	if errorCode == SellHandToolEvent.STATE_SUCCESS then
		self:onHandToolSold()
	else
		self:onHandToolSellFailed(errorCode)
	end
end

function ShopController:onHandToolSold()
	g_gui:closeAllDialogs()
	InfoDialog.show(g_i18n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_SUCCESS), self.onSoldCallback, self, DialogElement.TYPE_INFO)
end

-- Local values: text
function ShopController:onHandToolSellFailed(state)
	g_gui:closeAllDialogs()
	local v322_ = g_i18n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_FAILED)
	if state == SellHandToolEvent.STATE_IN_USE then
		v322_ = g_i18n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_IN_USE)
	elseif state == SellHandToolEvent.STATE_NO_PERMISSION then
		v322_ = g_i18n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_NO_PERMISSION)
	end
	InfoDialog.show(v322_, self.onSoldCallback, self, DialogElement.TYPE_WARNING)
end

function ShopController:onVehicleBuyEvent(errorCode, leaseVehicle, price)
	if errorCode == BuyVehicleEvent.STATE_SUCCESS then
		self:onVehicleBought(leaseVehicle, price)
	else
		self:onVehicleBuyFailed(leaseVehicle, errorCode)
	end
end

function ShopController:onVehicleBought(leaseVehicle, price)
	g_gui:closeAllDialogs()
	if leaseVehicle then
		InfoDialog.show(g_i18n:getText(ShopController.L10N_SYMBOL.LEASE_VEHICLE_SUCCESS), self.onBoughtCallback, self, DialogElement.TYPE_INFO)
	else
		InfoDialog.show(g_i18n:getText(ShopController.L10N_SYMBOL.BUY_VEHICLE_SUCCESS), self.onBoughtCallback, self, DialogElement.TYPE_INFO)
	end
	self.updateShopItemsCallback()
end

-- Local values: text
function ShopController:onVehicleBuyFailed(leaseVehicle, errorCode)
	g_gui:closeAllDialogs()
	local v331_
	if errorCode == BuyVehicleEvent.STATE_NO_SPACE then
		v331_ = g_i18n:getText(ShopController.L10N_SYMBOL.WARNING_NO_SPACE)
	elseif errorCode == BuyVehicleEvent.STATE_NO_PERMISSION then
		v331_ = g_i18n:getText(ShopController.L10N_SYMBOL.BUY_VEHICLE_NO_PERMISSION)
	elseif errorCode == BuyVehicleEvent.STATE_NOT_ENOUGH_MONEY then
		v331_ = g_i18n:getText(ShopController.L10N_SYMBOL.WARNING_NOT_ENOUGH_MONEY)
	elseif errorCode == BuyVehicleEvent.STATE_TOO_MANY_BALES then
		v331_ = g_i18n:getText(ShopController.L10N_SYMBOL.WARNING_TOO_MANY_BALES)
	elseif errorCode == BuyVehicleEvent.STATE_TOO_MANY_PALLETS then
		v331_ = g_i18n:getText(ShopController.L10N_SYMBOL.WARNING_TOO_MANY_PALLETS)
	else
		v331_ = g_i18n:getText(ShopController.L10N_SYMBOL.BUY_VEHICLE_FAILED_TO_LOAD)
	end
	InfoDialog.show(v331_, self.onBoughtCallback, self, DialogElement.TYPE_WARNING)
end

function ShopController:onObjectBuyEvent(errorCode, price)
	if errorCode == BuyObjectEvent.STATE_SUCCESS then
		self:onObjectBought(price)
	else
		self:onObjectBuyFailed(errorCode)
	end
end

function ShopController:onObjectBought(price)
	g_gui:closeAllDialogs()
	self.currentMission:addMoneyChange(-price, self.playerFarmId, MoneyType.SHOP_VEHICLE_BUY)
	InfoDialog.show(g_i18n:getText(ShopController.L10N_SYMBOL.BUY_OBJECT_SUCCESS), self.onBoughtCallback, self, DialogElement.TYPE_INFO)
end

function ShopController:onObjectBuyFailed(errorCode)
	g_gui:closeAllDialogs()
	if errorCode == BuyObjectEvent.STATE_NO_SPACE then
		InfoDialog.show(g_i18n:getText(ShopController.L10N_SYMBOL.WARNING_NO_SPACE), self.onBoughtCallback, self, DialogElement.TYPE_WARNING)
		return
	elseif errorCode == BuyObjectEvent.STATE_LIMIT_REACHED then
		InfoDialog.show(g_i18n:getText(ShopController.L10N_SYMBOL.WARNING_TOO_MANY_PALLETS), self.onBoughtCallback, self, DialogElement.TYPE_WARNING)
		return
	elseif errorCode == BuyObjectEvent.STATE_NOT_ENOUGH_MONEY then
		InfoDialog.show(g_i18n:getText(ShopController.L10N_SYMBOL.WARNING_NOT_ENOUGH_MONEY), self.onBoughtCallback, self, DialogElement.TYPE_WARNING)
	else
		InfoDialog.show(g_i18n:getText(ShopController.L10N_SYMBOL.LOAD_OBJECT_FAILED), self.onBoughtCallback, self, DialogElement.TYPE_WARNING)
	end
end

function ShopController:onHandToolBuyEvent(errorCode, price, wasPickedUp)
	if errorCode == BuyHandToolEvent.STATE_SUCCESS then
		self:onHandToolBought(price, wasPickedUp)
	else
		self:onHandToolBuyFailed(errorCode)
	end
end

function ShopController:onHandToolBought(price, wasPickedUp)
	g_gui:closeAllDialogs()
	if wasPickedUp then
		InfoDialog.show(g_i18n:getText(ShopController.L10N_SYMBOL.BUY_HANDTOOL_PICKED_UP), self.onBoughtCallback, self, DialogElement.TYPE_INFO)
	else
		InfoDialog.show(g_i18n:getText(ShopController.L10N_SYMBOL.BUY_HANDTOOL_INVENTORY), self.onBoughtCallback, self, DialogElement.TYPE_INFO)
	end
end

-- Local values: text
function ShopController:onHandToolBuyFailed(errorCode)
	g_gui:closeAllDialogs()
	local v347_ = g_i18n:getText(ShopController.L10N_SYMBOL.LOAD_OBJECT_FAILED)
	if errorCode == BuyHandToolEvent.STATE_NO_PERMISSION then
		v347_ = g_i18n:getText(ShopController.L10N_SYMBOL.BUY_VEHICLE_NO_PERMISSION)
	elseif errorCode == BuyHandToolEvent.STATE_NOT_ENOUGH_MONEY then
		v347_ = g_i18n:getText(ShopController.L10N_SYMBOL.WARNING_NOT_ENOUGH_MONEY)
	end
	InfoDialog.show(v347_, self.onBoughtCallback, self, DialogElement.TYPE_WARNING)
end

function ShopController:onVehicleSellEvent(isDirectSell, errorCode, sellPrice, isOwned)
	g_gui:closeAllDialogs()
	if isDirectSell then
		self:onSoldCallback()
		return
	elseif errorCode == SellVehicleEvent.SELL_SUCCESS then
		self:onVehicleSold(sellPrice, isOwned)
	else
		self:onVehicleSellFailed(isOwned, errorCode)
	end
end

-- Local values: text
function ShopController:onVehicleSold(sellPrice, isOwned)
	g_gui:closeAllDialogs()
	local v355_ = g_i18n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_SUCCESS)
	if not isOwned then
		v355_ = g_i18n:getText(ShopController.L10N_SYMBOL.RETURN_VEHICLE_SUCCESS)
	end
	InfoDialog.show(v355_, self.onSoldCallback, self, DialogElement.TYPE_INFO)
end

-- Local values: text
function ShopController:onVehicleSellFailed(isOwned, errorCode)
	g_gui:closeAllDialogs()
	local v359_
	if isOwned then
		if errorCode == SellVehicleEvent.SELL_NO_PERMISSION then
			v359_ = g_i18n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_NO_PERMISSION)
		elseif errorCode == SellVehicleEvent.SELL_VEHICLE_IN_USE then
			v359_ = g_i18n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_IN_USE)
		elseif errorCode == SellVehicleEvent.SELL_LAST_VEHICLE then
			v359_ = g_i18n:getText(ShopController.L10N_SYMBOL.SELL_LAST_VEHICLE_FAILED)
		else
			v359_ = g_i18n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_FAILED)
		end
	elseif errorCode == SellVehicleEvent.SELL_NO_PERMISSION then
		v359_ = g_i18n:getText(ShopController.L10N_SYMBOL.RETURN_VEHICLE_NO_PERMISSION)
	elseif errorCode == SellVehicleEvent.SELL_VEHICLE_IN_USE then
		v359_ = g_i18n:getText(ShopController.L10N_SYMBOL.RETURN_VEHICLE_IN_USE)
	elseif errorCode == SellVehicleEvent.SELL_LAST_VEHICLE then
		v359_ = g_i18n:getText(ShopController.L10N_SYMBOL.RETURN_LAST_VEHICLE_FAILED)
	else
		v359_ = g_i18n:getText(ShopController.L10N_SYMBOL.RETURN_VEHICLE_FAILED)
	end
	InfoDialog.show(v359_, self.onSoldCallback, self, DialogElement.TYPE_WARNING)
end

function ShopController:onPlaceableSellEvent(errorCode, sellPrice, showSoldPopup)
	if errorCode == SellPlaceableEvent.STATE_SUCCESS then
		if showSoldPopup then
			self:onPlaceableSold(sellPrice)
			return
		end
	else
		self:onPlaceableSellFailed(errorCode)
	end
end

function ShopController:onPlaceableSold(sellPrice)
	g_gui:closeAllDialogs()
	InfoDialog.show(g_i18n:getText(ShopController.L10N_SYMBOL.SELL_OBJECT_SUCCESS), self.onSoldCallback, self, DialogElement.TYPE_INFO)
end

-- Local values: text
function ShopController:onPlaceableSellFailed(state)
	g_gui:closeAllDialogs()
	local v367_ = g_i18n:getText(ShopController.L10N_SYMBOL.SELL_OBJECT_FAILED)
	if state == SellPlaceableEvent.STATE_IN_USE then
		v367_ = g_i18n:getText(ShopController.L10N_SYMBOL.SELL_OBJECT_IN_USE)
	elseif state == SellPlaceableEvent.STATE_NO_PERMISSION then
		v367_ = g_i18n:getText(ShopController.L10N_SYMBOL.NO_PERMISSION)
	end
	InfoDialog.show(v367_, self.onSoldCallback, self, DialogElement.TYPE_WARNING)
end

function ShopController:onBoughtCallback()
	self.isBuying = false
	self.updateAllItemsCallback()
	if self.buyItemSaleItem ~= nil then
		self.saleItemBoughtCallback()
	end
end

function ShopController:onSoldCallback()
	self.isSelling = false
	self.updateAllItemsCallback()
end

function ShopController.brandSortFunction(item1, item2)
	return utf8ToUpper(item1.sortValue) < utf8ToUpper(item2.sortValue)
end

function ShopController.categorySortFunction(item1, item2)
	return item1.sortValue < item2.sortValue
end

-- Local values: sellPrice1, sellPrice2
function ShopController.displayItemSortFunction(item1, item2)
	if item1.orderValue == item2.orderValue then
		local v376_ = item1:getSellPrice()
		local v377_ = item2:getSellPrice()
		if v376_ == v377_ then
			return item1:getSortId() > item2:getSortId()
		else
			return v377_ < v376_
		end
	else
		return item1.orderValue < item2.orderValue
	end
end

-- Local values: list, _, product
function ShopController:getCoinItems()
	local v378_ = {}
	if not g_inAppPurchaseController:getIsAvailable() then
		return v378_
	end
	for _, v379_ in ipairs(g_inAppPurchaseController:getProducts()) do
		if v379_:isa(IAProductCoins) then
			table.insert(v378_, v379_:getDisplayItem(nil))
		end
	end
	return v378_
end
ShopController.PROFILE = {
	["ICON_OWNED"] = "shopListAttributeIconOwned",
	["ICON_LEASED"] = "shopListAttributeIconLeased"
}
ShopController.L10N_SYMBOL = {
	["BUY_CONFIRMATION"] = "shop_doYouWantToBuy",
	["BUY_ALREADY_OWNED"] = "shop_messageAlreadyOwned",
	["CANNOT_SELL_TOUR_ITEMS"] = "shop_messageTourItemsCannotBeSold",
	["RETURNING_VEHICLE"] = "shop_messageReturningVehicle",
	["SELLING_VEHICLE"] = "shop_messageSellingVehicle",
	["LEASING_VEHICLE"] = "shop_messageLeasingVehicle",
	["BUYING_VEHICLE"] = "shop_messageBuyingVehicle",
	["LEASE_VEHICLE_SUCCESS"] = "shop_messageLeasingReady",
	["BUY_VEHICLE_SUCCESS"] = "shop_messagePurchaseReady",
	["BUY_VEHICLE_FAILED_TO_LOAD"] = "shop_messageFailedToLoadVehicle",
	["BUY_VEHICLE_NO_PERMISSION"] = "shop_messageNoPermissionToBuyVehicleText",
	["BUY_OBJECT_SUCCESS"] = "shop_messageGardenCenterPurchaseReady",
	["WARNING_NO_SPACE"] = "shop_messageNoSpace",
	["WARNING_NOT_ENOUGH_SLOTS"] = "shop_messageNotEnoughSlotsToBuy",
	["WARNING_NOT_ENOUGH_MONEY"] = "shop_messageNotEnoughMoneyToBuy",
	["WARNING_TOO_MANY_BALES"] = "warning_tooManyBales",
	["WARNING_TOO_MANY_PALLETS"] = "warning_tooManyPallets",
	["WARNING_TOO_MANY_PLACEABLES"] = "warning_tooManyPlaceables",
	["BUY_HANDTOOL_INVENTORY"] = "shop_messageBoughtHandToolInventory",
	["BUY_HANDTOOL_PICKED_UP"] = "shop_messageBoughtHandToolPickedUp",
	["LOAD_OBJECT_FAILED"] = "shop_messageFailedToLoadObject",
	["RETURN_VEHICLE_SUCCESS"] = "shop_messageReturnedVehicle",
	["RETURN_VEHICLE_NO_PERMISSION"] = "shop_messageNoPermissionToReturnVehicleText",
	["RETURN_VEHICLE_IN_USE"] = "shop_messageReturnVehicleInUse",
	["RETURN_VEHICLE_FAILED"] = "shop_messageFailedToReturnVehicle",
	["RETURN_LAST_VEHICLE_FAILED"] = "shop_messageFailedToReturnLastVehicleText",
	["SELL_VEHICLE_SUCCESS"] = "shop_messageSoldVehicle",
	["SELL_VEHICLE_FAILED"] = "shop_messageFailedToSellVehicle",
	["SELL_VEHICLE_IN_USE"] = "shop_messageSellVehicleInUse",
	["SELL_VEHICLE_NO_PERMISSION"] = "shop_messageNoPermissionToSellVehicleText",
	["SELL_LAST_VEHICLE_FAILED"] = "shop_messageFailedToSellLastVehicleText",
	["SELL_OBJECT_SUCCESS"] = "shop_messageSoldObject",
	["SELL_OBJECT_FAILED"] = "shop_messageFailedToSellObject",
	["SELL_OBJECT_IN_USE"] = "shop_messageObjectInUse",
	["NO_PERMISSION"] = "shop_messageNoPermissionGeneral",
	["CATEGORY_DLC"] = "modHub_dlc",
	["CATEGORY_MODS"] = "button_mods",
	["CATEGORY_PACKS"] = "ui_storePacks"
}
