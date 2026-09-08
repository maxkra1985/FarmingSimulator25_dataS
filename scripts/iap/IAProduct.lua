-- Local values: IAProduct_mt
IAProduct = {}
local IAProduct_mt = Class(IAProduct)

-- Upvalues: IAProduct_mt
-- Local values: self
function IAProduct.new(productId, isConsumable, customMt)
	-- upvalues: (copy) IAProduct_mt
	local v5_ = customMt or IAProduct_mt
	local v6_ = setmetatable({}, v5_)
	v6_.productId = productId
	v6_.isConsumable = isConsumable
	return v6_
end

function IAProduct:loadFromXMLFile(xmlFile, key)
	self.imageFilename = xmlFile:getString(key .. "#imageFilename")
	return true
end

function IAProduct:getId()
	return self.productId
end

function IAProduct:getPriceText()
	return g_inAppPurchaseController:getIsAvailable() and (inAppGetProductPrice(self.productId) or "Unknown") or g_i18n:getText("ui_modUnavailable")
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
