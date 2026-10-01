IAProduct = {}
local IAProduct_mt = Class(IAProduct)
function IAProduct.new(productId, isConsumable, customMt)
	local self = setmetatable({}, customMt or IAProduct_mt)
	self.productId = productId
	self.isConsumable = isConsumable
	return self
end
function IAProduct:loadFromXMLFile(xmlFile, key)
	self.imageFilename = xmlFile:getString(key .. "#imageFilename")
	return true
end
function IAProduct:getId()
	return self.productId
end
function IAProduct:getPriceText()
	if g_inAppPurchaseController:getIsAvailable() then
		return inAppGetProductPrice(self.productId) or "Unknown"
	else
		return g_i18n:getText("ui_modUnavailable")
	end
end
function IAProduct:getTitle()
	return inAppGetProductDescription(self.productId) or "Unknown"
end
function IAProduct:getImageFilename()
	return self.imageFilename
end
function IAProduct:getHasBeenBought()
	if self.isConsumable then
		return false
	else
		return inAppGetProductPurchaseState(self.productId) == InAppPurchasePurchaseState.PURCHASED
	end
end
function IAProduct:getDisplayItem()
	return nil
end
function IAProduct:onProductBought(callback)
	callback(true)
end
