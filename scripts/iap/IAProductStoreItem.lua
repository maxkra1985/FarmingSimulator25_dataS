IAProductStoreItem = {}
local IAProductStoreItem_mt = Class(IAProductStoreItem, IAProduct)
IAProductStoreItem.ADDITIONAL_SPECS = {}
IAProductStoreItem.ADDITIONAL_SPECS.workingWidth = true
IAProductStoreItem.COMBINED_SPECS = {}
IAProductStoreItem.COMBINED_SPECS.slots = true
function IAProductStoreItem.new(productId, isConsumable)
	local self = IAProduct.new(productId, isConsumable, IAProductStoreItem_mt)
	self.items = {}
	self.pendingStoreItemPurchases = {}
	return self
end
function IAProductStoreItem:loadFromXMLFile(xmlFile, key)
	if not IAProductStoreItem:superClass().loadFromXMLFile(self, xmlFile, key) then
		return false
	end
	self.title = xmlFile:getString(key .. "#title")
	self.imageFilename = xmlFile:getString(key .. "#imageFilename")
	xmlFile:iterate(key .. ".item", function(index, itemKey)
		local xmlFilename = xmlFile:getString(itemKey .. "#xmlFilename")
		if xmlFilename ~= nil then
			table.insert(self.items, xmlFilename)
		end
	end)
	if #self.items == 0 then
		Logging.xmlWarning(xmlFile, "Failed to load IAP Product. Missing xmlFilename definition. (%s)", key)
		return false
	else
		return true
	end
end
function IAProductStoreItem:onVehicleBuyEvent(errorCode)
	if errorCode ~= BuyVehicleEvent.STATE_SUCCESS then
		self.pendingStoreItemPurchases = {}
		local text = nil
		if errorCode == BuyVehicleEvent.STATE_NO_SPACE then
			text = g_i18n:getText(ShopController.L10N_SYMBOL.WARNING_NO_SPACE)
		end
		g_messageCenter:unsubscribe(BuyVehicleEvent, self)
		self:onProductBoughtFinished(false, text)
	elseif 0 >= #self.pendingStoreItemPurchases then
		g_messageCenter:unsubscribe(BuyVehicleEvent, self)
		self:onProductBoughtFinished(true)
	else
		g_client:getServerConnection():sendEvent(BuyVehicleEvent.new(self.pendingStoreItemPurchases[1], false, {}, false, g_currentMission:getFarmId(), nil, nil, 0))
		table.remove(self.pendingStoreItemPurchases, 1)
	end
end
function IAProductStoreItem:getIsStoreItemOfProduct(storeItem)
	for i = 1, #self.items do
		if storeItem.xmlFilename == self.items[i] then
			return true
		end
	end
	return false
end
function IAProductStoreItem:getDisplayItem(oldStoreItem, concreteItem, attributeIconProfiles, attributeValues, iconFilenames, functionText, orderValue, numOwned, numLeased, saleItem)
	if oldStoreItem.xmlFilename ~= self.items[1] then
		return nil
	else
		local title = oldStoreItem.name
		if self.title ~= nil then
			local names = {}
			for i = 1, #self.items do
				local storeItem = g_storeManager:getItemByXMLFilename(self.items[i])
				if storeItem == nil then
					continue
				end
				table.insert(names, storeItem.name)
			end
			title = string.format(self.title, unpack(names))
		end
		local storeItem = { title = title, product = self }
		storeItem.name = self:getId()
		storeItem.isInAppPurchase = true
		storeItem.isInAppPurchaseConsumable = false
		storeItem.priceText = self:getPriceText()
		storeItem.brandIndex = oldStoreItem.brandIndex
		storeItem.imageFilename = self.imageFilename or oldStoreItem.imageFilename
		storeItem.xmlFilename = oldStoreItem.xmlFilename
		storeItem.canBeRecovered = g_inAppPurchaseController:getHasPendingPurchase(self)
		if 0 < #self.items then
			for i = 2, #self.items do
				local otherItem = g_storeManager:getItemByXMLFilename(self.items[i])
				local otherDisplayItem = g_shopController:makeDisplayItem(otherItem, nil, nil, nil, true)
				if otherDisplayItem ~= nil then
					for profileIndex = 1, #otherDisplayItem.attributeIconProfiles do
						local profile = otherDisplayItem.attributeIconProfiles[profileIndex]
						local specType = g_storeManager:getSpecTypeByProfile(profile)
						if IAProductStoreItem.ADDITIONAL_SPECS[specType.name] then
							table.insert(attributeIconProfiles, otherDisplayItem.attributeIconProfiles[profileIndex])
							table.insert(attributeValues, otherDisplayItem.attributeValues[profileIndex])
						end
						if IAProductStoreItem.COMBINED_SPECS[specType.name] then
							for profileIndex2 = 1, #attributeIconProfiles do
								if attributeIconProfiles[profileIndex2] == specType.profile then
									attributeValues[profileIndex2] = tostring(tonumber(attributeValues[profileIndex2]) + tonumber(otherDisplayItem.attributeValues[profileIndex]))
								end
							end
						end
					end
				end
			end
		end
		return ShopDisplayItem.new(storeItem, concreteItem, attributeIconProfiles, attributeValues, iconFilenames, functionText, orderValue, numOwned, numLeased, saleItem)
	end
end
function IAProductStoreItem:onProductBought(callback)
	local mission = g_currentMission
	if mission ~= nil then
		for i = 1, #self.items do
			local storeItem = g_storeManager:getItemByXMLFilename(self.items[i])
			if storeItem ~= nil then
				table.insert(self.pendingStoreItemPurchases, self.items[i])
			else
				Logging.error("Unable to buy IAP store item '%s", self.items[i])
			end
		end
		if 0 < #self.pendingStoreItemPurchases then
			self.boughtCallback = callback
			g_messageCenter:subscribe(BuyVehicleEvent, self.onVehicleBuyEvent, self)
			g_client:getServerConnection():sendEvent(BuyVehicleEvent.new(self.pendingStoreItemPurchases[1], false, {}, false, g_currentMission:getFarmId(), nil, nil, 0))
			table.remove(self.pendingStoreItemPurchases, 1)
			return
		end
	end
	callback(false)
end
function IAProductStoreItem:onProductBoughtFinished(success, warningText)
	local mission = g_currentMission
	if mission ~= nil then
		mission:saveSavegame()
	end
	self.boughtCallback(success, warningText)
	self.boughtCallback = nil
end
