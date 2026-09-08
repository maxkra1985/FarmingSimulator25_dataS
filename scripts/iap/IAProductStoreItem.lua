-- Local values: IAProductStoreItem_mt
IAProductStoreItem = {}
local IAProductStoreItem_mt = Class(IAProductStoreItem, IAProduct)
IAProductStoreItem.ADDITIONAL_SPECS = {}
IAProductStoreItem.ADDITIONAL_SPECS.workingWidth = true
IAProductStoreItem.COMBINED_SPECS = {}
IAProductStoreItem.COMBINED_SPECS.slots = true

-- Upvalues: IAProductStoreItem_mt
-- Local values: self
function IAProductStoreItem.new(productId, isConsumable)
	-- upvalues: (copy) IAProductStoreItem_mt
	local v4_ = IAProduct.new(productId, isConsumable, IAProductStoreItem_mt)
	v4_.items = {}
	v4_.pendingStoreItemPurchases = {}
	return v4_
end

function IAProductStoreItem:loadFromXMLFile(xmlFile, key)
	if not IAProductStoreItem:superClass().loadFromXMLFile(self, xmlFile, key) then
		return false
	end
	self.title = xmlFile:getString(key .. "#title")
	self.imageFilename = xmlFile:getString(key .. "#imageFilename")
	xmlFile:iterate(key .. ".item", function(_, p8_)
		-- upvalues: (copy) xmlFile, (copy) self
		local v9_ = xmlFile:getString(p8_ .. "#xmlFilename")
		if v9_ ~= nil then
			local v10_ = self.items
			table.insert(v10_, v9_)
		end
	end)
	if #self.items ~= 0 then
		return true
	end
	Logging.xmlWarning(xmlFile, "Failed to load IAP Product. Missing xmlFilename definition. (%s)", key)
	return false
end

-- Local values: text
function IAProductStoreItem:onVehicleBuyEvent(errorCode)
	if errorCode == BuyVehicleEvent.STATE_SUCCESS then
		if #self.pendingStoreItemPurchases > 0 then
			g_client:getServerConnection():sendEvent(BuyVehicleEvent.new(self.pendingStoreItemPurchases[1], false, {}, false, g_currentMission:getFarmId(), nil, nil, 0))
			table.remove(self.pendingStoreItemPurchases, 1)
		else
			g_messageCenter:unsubscribe(BuyVehicleEvent, self)
			self:onProductBoughtFinished(true)
		end
	else
		self.pendingStoreItemPurchases = {}
		local v13_
		if errorCode == BuyVehicleEvent.STATE_NO_SPACE then
			v13_ = g_i18n:getText(ShopController.L10N_SYMBOL.WARNING_NO_SPACE)
		else
			v13_ = nil
		end
		g_messageCenter:unsubscribe(BuyVehicleEvent, self)
		self:onProductBoughtFinished(false, v13_)
		return
	end
end

-- Local values: i
function IAProductStoreItem:getIsStoreItemOfProduct(storeItem)
	for v16_ = 1, #self.items do
		if storeItem.xmlFilename == self.items[v16_] then
			return true
		end
	end
	return false
end

-- Local values: title, names, i, storeItem, storeItem, i, otherItem, otherDisplayItem, profileIndex, profile, specType, profileIndex2
function IAProductStoreItem:getDisplayItem(oldStoreItem, concreteItem, attributeIconProfiles, attributeValues, iconFilenames, functionText, orderValue, numOwned, numLeased, saleItem)
	if oldStoreItem.xmlFilename ~= self.items[1] then
		return nil
	end
	local v28_ = oldStoreItem.name
	if self.title ~= nil then
		local v29_ = {}
		for v30_ = 1, #self.items do
			local v31_ = g_storeManager:getItemByXMLFilename(self.items[v30_])
			if v31_ ~= nil then
				local v32_ = v31_.name
				table.insert(v29_, v32_)
			end
		end
		v28_ = string.format(self.title, unpack(v29_))
	end
	local v33_ = {
		["name"] = self:getId(),
		["isInAppPurchase"] = true,
		["isInAppPurchaseConsumable"] = false,
		["priceText"] = self:getPriceText(),
		["title"] = v28_,
		["brandIndex"] = oldStoreItem.brandIndex,
		["imageFilename"] = self.imageFilename or oldStoreItem.imageFilename,
		["xmlFilename"] = oldStoreItem.xmlFilename,
		["product"] = self,
		["canBeRecovered"] = g_inAppPurchaseController:getHasPendingPurchase(self)
	}
	if #self.items > 0 then
		for v34_ = 2, #self.items do
			local v35_ = g_storeManager:getItemByXMLFilename(self.items[v34_])
			local v36_ = g_shopController:makeDisplayItem(v35_, nil, nil, nil, true)
			if v36_ ~= nil then
				for v37_ = 1, #v36_.attributeIconProfiles do
					local v38_ = v36_.attributeIconProfiles[v37_]
					local v39_ = g_storeManager:getSpecTypeByProfile(v38_)
					if IAProductStoreItem.ADDITIONAL_SPECS[v39_.name] then
						local v40_ = v36_.attributeIconProfiles[v37_]
						table.insert(attributeIconProfiles, v40_)
						local v41_ = v36_.attributeValues[v37_]
						table.insert(attributeValues, v41_)
					end
					if IAProductStoreItem.COMBINED_SPECS[v39_.name] then
						for v42_ = 1, #attributeIconProfiles do
							if attributeIconProfiles[v42_] == v39_.profile then
								local v43_ = attributeValues[v42_]
								local v44_ = tonumber(v43_)
								local v45_ = v36_.attributeValues[v37_]
								local v46_ = v44_ + tonumber(v45_)
								attributeValues[v42_] = tostring(v46_)
							end
						end
					end
				end
			end
		end
	end
	return ShopDisplayItem.new(v33_, concreteItem, attributeIconProfiles, attributeValues, iconFilenames, functionText, orderValue, numOwned, numLeased, saleItem)
end

-- Local values: mission, i, storeItem
function IAProductStoreItem:onProductBought(callback)
	if g_currentMission ~= nil then
		for v49_ = 1, #self.items do
			if g_storeManager:getItemByXMLFilename(self.items[v49_]) == nil then
				Logging.error("Unable to buy IAP store item \'%s", self.items[v49_])
			else
				local v50_ = self.pendingStoreItemPurchases
				local v51_ = self.items[v49_]
				table.insert(v50_, v51_)
			end
		end
		if #self.pendingStoreItemPurchases > 0 then
			self.boughtCallback = callback
			g_messageCenter:subscribe(BuyVehicleEvent, self.onVehicleBuyEvent, self)
			g_client:getServerConnection():sendEvent(BuyVehicleEvent.new(self.pendingStoreItemPurchases[1], false, {}, false, g_currentMission:getFarmId(), nil, nil, 0))
			table.remove(self.pendingStoreItemPurchases, 1)
			return
		end
	end
	callback(false)
end

-- Local values: mission
function IAProductStoreItem:onProductBoughtFinished(success, warningText)
	local v55_ = g_currentMission
	if v55_ ~= nil then
		v55_:saveSavegame()
	end
	self.boughtCallback(success, warningText)
	self.boughtCallback = nil
end
