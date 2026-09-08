-- Local values: IAProductCoins_mt
IAProductCoins = {}
local IAProductCoins_mt = Class(IAProductCoins, IAProduct)

-- Upvalues: IAProductCoins_mt
-- Local values: self
function IAProductCoins.new(productId, isConsumable)
	-- upvalues: (copy) IAProductCoins_mt
	return IAProduct.new(productId, isConsumable, IAProductCoins_mt)
end

function IAProductCoins:loadFromXMLFile(xmlFile, key)
	if not IAProductCoins:superClass().loadFromXMLFile(self, xmlFile, key) then
		return false
	end
	self.coins = xmlFile:getInt(key .. "#coins")
	if self.coins ~= nil then
		return true
	end
	Logging.xmlWarning(xmlFile, "Failed to load IAP Product. Missing coins definition. (%s)", key)
	return false
end

-- Local values: storeItem
function IAProductCoins:getDisplayItem(oldStoreItem, concreteItem, attributeIconProfiles, attributeValues, iconFilenames, functionText, orderValue, numOwned, numLeased, saleItem)
	local v8_ = {
		["name"] = self:getId(),
		["isInAppPurchase"] = true,
		["isInAppPurchaseConsumable"] = true,
		["priceText"] = self:getPriceText(),
		["title"] = self:getTitle(),
		["imageFilename"] = self:getImageFilename(),
		["product"] = self,
		["canBeRecovered"] = g_inAppPurchaseController:getHasPendingPurchase(self)
	}
	return ShopDisplayItem.new(v8_, nil, nil, nil, nil, g_i18n:getText("function_coins"), self.productId)
end

-- Local values: mission
function IAProductCoins:onProductBought(callback)
	local v11_ = g_currentMission
	if v11_ ~= nil then
		v11_:addPurchasedMoney(self.coins)
		v11_:saveSavegame()
	end
	IAProductCoins:superClass().onProductBought(self, callback)
end
