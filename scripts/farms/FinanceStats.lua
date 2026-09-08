-- Local values: FinanceStats_mt, i, statName
FinanceStats = {}
local FinanceStats_mt = Class(FinanceStats)
if GS_IS_MOBILE_VERSION then
	FinanceStats.statNames = {
		"harvestIncome",
		"incomeBga",
		"soldVehicles",
		"soldAnimals",
		"soldBales",
		"soldWool",
		"soldMilk",
		"soldProducts",
		"soldWood",
		"wagePayment",
		"newVehiclesCost",
		"newAnimalsCost",
		"fieldPurchase",
		"constructionCost",
		"propertyMaintenance",
		"purchaseFuel",
		"purchaseSeeds",
		"purchaseFertilizer",
		"animalUpkeep",
		"other"
	}
else
	FinanceStats.statNames = {
		"newVehiclesCost",
		"soldVehicles",
		"newHandtoolsCost",
		"soldHandtools",
		"newAnimalsCost",
		"soldAnimals",
		"constructionCost",
		"soldBuildings",
		"fieldPurchase",
		"fieldSelling",
		"vehicleRunningCost",
		"vehicleLeasingCost",
		"propertyMaintenance",
		"propertyIncome",
		"productionCosts",
		"soldWood",
		"soldBales",
		"soldWool",
		"soldMilk",
		"soldProducts",
		"purchaseFuel",
		"purchaseSeeds",
		"purchaseFertilizer",
		"purchaseSaplings",
		"purchaseWater",
		"purchaseBales",
		"purchasePallets",
		"harvestIncome",
		"incomeBga",
		"missionIncome",
		"wagePayment",
		"other",
		"loanInterest"
	}
end
FinanceStats.statNameToIndex = {}
FinanceStats.statNamesI18n = {}
FinanceStats.filledI18N = false
for v2_, v3_ in ipairs(FinanceStats.statNames) do
	FinanceStats.statNameToIndex[v3_] = v2_
end

-- Upvalues: FinanceStats_mt
-- Local values: self, _, statName
function FinanceStats.new(customMt)
	-- upvalues: (copy) FinanceStats_mt
	local v5_ = customMt or FinanceStats_mt
	local v6_ = setmetatable({}, v5_)
	for _, v7_ in ipairs(FinanceStats.statNames) do
		v6_[v7_] = 0
		FinanceStats.statNamesI18n[v7_] = g_i18n:getText("finance_" .. v7_)
	end
	return v6_
end

-- Local values: _, statName
function FinanceStats:saveToXMLFile(xmlFile, key)
	for _, v11_ in ipairs(self.statNames) do
		xmlFile:setFloat(key .. "." .. v11_, self[v11_])
	end
end

-- Local values: _, statName
function FinanceStats:loadFromXMLFile(xmlFile, key)
	for _, v15_ in ipairs(self.statNames) do
		self[v15_] = xmlFile:getFloat(key .. "." .. v15_, 0)
	end
end

-- Local values: _, statName
function FinanceStats:merge(other)
	for _, v18_ in ipairs(self.statNames) do
		self[v18_] = self[v18_] + other[v18_]
	end
end
