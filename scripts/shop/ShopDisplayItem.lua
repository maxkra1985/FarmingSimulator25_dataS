-- Local values: ShopDisplayItem_mt
ShopDisplayItem = {}
local ShopDisplayItem_mt = Class(ShopDisplayItem)
ShopDisplayItem.NO_CONCRETE_ITEM = {}

-- Upvalues: ShopDisplayItem_mt
-- Local values: self
function ShopDisplayItem.new(storeItem, concreteItem, attributeIconProfiles, attributeValues, iconFilenames, functionText, orderValue, numOwned, numLeased, saleItem)
	-- upvalues: (copy) ShopDisplayItem_mt
	local v12_ = ShopDisplayItem_mt
	local v13_ = setmetatable({}, v12_)
	v13_.storeItem = storeItem
	v13_.concreteItem = concreteItem or ShopDisplayItem.NO_CONCRETE_ITEM
	v13_.attributeIconProfiles = attributeIconProfiles or {}
	v13_.attributeValues = attributeValues or {}
	if iconFilenames ~= nil then
		v13_.fillTypeIconFilenames = iconFilenames.fillTypeIconFilenames or {}
		v13_.seedTypeIconFilenames = iconFilenames.seedTypeIconFilenames or {}
		v13_.foodFillTypeIconFilenames = iconFilenames.foodFillTypeIconFilenames or {}
		v13_.prodPointInputFillTypeIconFilenames = iconFilenames.prodPointInputFillTypeIconFilenames or {}
		v13_.prodPointOutputFillTypeIconFilenames = iconFilenames.prodPointOutputFillTypeIconFilenames or {}
		v13_.sellingStationFillTypesIconFilenames = iconFilenames.sellingStationFillTypesIconFilenames or {}
		v13_.buyingStationFillTypesIconFilenames = iconFilenames.buyingStationFillTypesIconFilenames or {}
		v13_.objectStorageFillTypesIconFilenames = iconFilenames.objectStorageFillTypesIconFilenames or {}
	end
	v13_.functionText = functionText
	v13_.orderValue = orderValue
	v13_.numOwned = numOwned
	v13_.numLeased = numLeased
	v13_.saleItem = saleItem
	return v13_
end

function ShopDisplayItem:getSellPrice()
	if self.saleItem == nil then
		if self.concreteItem == ShopDisplayItem.NO_CONCRETE_ITEM then
			return self.storeItem.price
		else
			return self.concreteItem:getSellPrice()
		end
	else
		return self.saleItem.price
	end
end

function ShopDisplayItem:getSortId()
	if self.concreteItem == ShopDisplayItem.NO_CONCRETE_ITEM then
		return self.storeItem.xmlFilename
	else
		return self.concreteItem.id
	end
end

function ShopDisplayItem:hasCombinationInfo()
	if self.saleItem == nil then
		if self.storeItem.specs == nil or self.storeItem.specs.combinations == nil then
			return false
		else
			return #self.storeItem.specs.combinations > 0
		end
	else
		return false
	end
end
