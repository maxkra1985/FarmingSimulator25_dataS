-- Local values: moneyTypeId, moneyTypeIdToType
MoneyType = {}
local moneyTypeId = 0
local moneyTypeIdToType = {}
local function v7_(p3_, p4_, p5_)
	-- upvalues: (ref) moneyTypeId, (copy) moneyTypeIdToType
	moneyTypeId = moneyTypeId + 1
	local v6_ = {
		["id"] = moneyTypeId,
		["statistic"] = p3_,
		["title"] = p4_,
		["customEnv"] = p5_
	}
	moneyTypeIdToType[moneyTypeId] = v6_
	return v6_
end
MoneyType.register = v7_
local function v14_(p8_, p9_, p10_, p11_)
	-- upvalues: (copy) moneyTypeIdToType, (ref) moneyTypeId
	local v12_ = moneyTypeIdToType[p8_]
	if v12_ == nil then
		v12_ = {
			["id"] = p8_,
			["statistic"] = p9_,
			["title"] = p10_,
			["customEnv"] = p11_
		}
		moneyTypeIdToType[p8_] = v12_
	end
	local v13_ = moneyTypeId
	moneyTypeId = math.max(v13_, p8_)
	return v12_
end
MoneyType.registerWithId = v14_

-- Upvalues: moneyTypeIdToType
function MoneyType.getMoneyTypeById(id)
	-- upvalues: (copy) moneyTypeIdToType
	return moneyTypeIdToType[id]
end

function MoneyType.getMoneyTypeByName(name)
	if name == nil then
		return nil
	end
	local v17_ = string.upper(name)
	return MoneyType[v17_]
end
local function v18_()
	-- upvalues: (ref) moneyTypeId
	moneyTypeId = MoneyType.LAST_ID
end
MoneyType.reset = v18_
MoneyType.OTHER = MoneyType.register("other", "finance_other")
MoneyType.SHOP_VEHICLE_BUY = MoneyType.register("newVehiclesCost", "finance_newVehiclesCost")
MoneyType.SHOP_VEHICLE_SELL = MoneyType.register("soldVehicles", "finance_soldVehicles")
MoneyType.SHOP_PROPERTY_BUY = MoneyType.register("constructionCost", "finance_constructionCost")
MoneyType.SHOP_PROPERTY_SELL = MoneyType.register("soldBuildings", "finance_soldBuildings")
MoneyType.SHOP_HANDTOOL_BUY = MoneyType.register("newHandtoolsCost", "finance_newHandtoolsCost")
MoneyType.SHOP_HANDTOOL_SELL = MoneyType.register("soldHandtools", "finance_soldHandtools")
MoneyType.SOLD_MILK = MoneyType.register("soldMilk", "finance_soldMilk")
MoneyType.HARVEST_INCOME = MoneyType.register("harvestIncome", "finance_harvestIncome")
MoneyType.AI = MoneyType.register("wagePayment", "finance_wagePayment")
MoneyType.MISSIONS = MoneyType.register("missionIncome", "finance_missionIncome")
MoneyType.SOLD_ANIMALS = MoneyType.register("soldAnimals", "finance_soldAnimals")
MoneyType.NEW_ANIMALS_COST = MoneyType.register("newAnimalsCost", "finance_newAnimalsCost")
MoneyType.ANIMAL_UPKEEP = MoneyType.register("animalUpkeep", "finance_animalUpkeep")
MoneyType.PURCHASE_SEEDS = MoneyType.register("purchaseSeeds", "finance_purchaseSeeds")
MoneyType.PURCHASE_FERTILIZER = MoneyType.register("purchaseFertilizer", "finance_purchaseFertilizer")
MoneyType.PURCHASE_FUEL = MoneyType.register("purchaseFuel", "finance_purchaseFuel")
MoneyType.PURCHASE_SAPLINGS = MoneyType.register("purchaseSaplings", "finance_purchaseSaplings")
MoneyType.PURCHASE_WATER = MoneyType.register("purchaseWater", "finance_purchaseWater")
MoneyType.PURCHASE_BALES = MoneyType.register("purchaseBales", "finance_purchaseBales")
MoneyType.PURCHASE_PALLETS = MoneyType.register("purchasePallets", "finance_purchasePallets")
MoneyType.PURCHASE_CONSUMABLES = MoneyType.register("purchaseConsumable", "finance_purchaseConsumable")
MoneyType.FIELD_BUY = MoneyType.register("fieldPurchase", "finance_fieldPurchase")
MoneyType.FIELD_SELL = MoneyType.register("fieldSelling", "finance_fieldSelling")
MoneyType.LEASING_COSTS = MoneyType.register("vehicleLeasingCost", "finance_vehicleLeasingCost")
MoneyType.LOAN_INTEREST = MoneyType.register("loanInterest", "finance_loanInterest")
MoneyType.VEHICLE_RUNNING_COSTS = MoneyType.register("vehicleRunningCost", "finance_vehicleRunningCost")
MoneyType.VEHICLE_REPAIR = MoneyType.register("vehicleRunningCost", "finance_vehicleRunningCost")
MoneyType.PROPERTY_MAINTENANCE = MoneyType.register("propertyMaintenance", "finance_propertyMaintenance")
MoneyType.PROPERTY_INCOME = MoneyType.register("propertyIncome", "finance_propertyIncome")
MoneyType.LOAN = MoneyType.register("loan", "finance_other")
MoneyType.PRODUCTION_COSTS = MoneyType.register("productionCosts", "finance_productionCosts")
MoneyType.SOLD_PRODUCTS = MoneyType.register("soldProducts", "finance_soldProducts")
MoneyType.INCOME_BGA = MoneyType.register("incomeBga", "finance_incomeBga")
MoneyType.SOLD_WOOD = MoneyType.register("soldWood", "finance_soldWood")
MoneyType.SOLD_BALES = MoneyType.register("soldBales", "finance_soldBales")
MoneyType.BOUGHT_MATERIALS = MoneyType.register("expenses", "finance_other")
MoneyType.TRANSFER = MoneyType.register("other", "finance_transfer")
MoneyType.COLLECTIBLE = MoneyType.register("other", "finance_collectible")
MoneyType.LAST_ID = moneyTypeId
