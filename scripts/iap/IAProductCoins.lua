IAProductCoins = {}
local IAProductCoins_mt = Class(IAProductCoins, IAProduct)
function IAProductCoins.new(productId, isConsumable)
	local self = IAProduct.new(productId, isConsumable, IAProductCoins_mt)
	return self
end
function IAProductCoins:loadFromXMLFile(xmlFile, key)
	if not IAProductCoins:superClass().loadFromXMLFile(self, xmlFile, key) then
		return false
	end
	self.coins = xmlFile:getInt(key .. "#coins")
	if self.coins == nil then
		Logging.xmlWarning(xmlFile, "Failed to load IAP Product. Missing coins definition. (%s)", key)
		return false
	else
		return true
	end
end
function IAProductCoins:getDisplayItem(oldStoreItem, concreteItem, attributeIconProfiles, attributeValues, iconFilenames, functionText, orderValue, numOwned, numLeased, saleItem)
	local storeItem = { product = self }
	storeItem.name = self:getId()
	storeItem.isInAppPurchase = true
	storeItem.isInAppPurchaseConsumable = true
	storeItem.priceText = self:getPriceText()
	storeItem.title = self:getTitle()
	storeItem.imageFilename = self:getImageFilename()
	storeItem.canBeRecovered = g_inAppPurchaseController:getHasPendingPurchase(self)
	return ShopDisplayItem.new(storeItem, nil, nil, nil, nil, g_i18n:getText("function_coins"), self.productId)
end
function IAProductCoins:onProductBought(callback)
	local mission = g_currentMission
	if mission ~= nil then
		mission:addPurchasedMoney(self.coins)
		mission:saveSavegame()
	end
	IAProductCoins:superClass().onProductBought(self, callback)
end
