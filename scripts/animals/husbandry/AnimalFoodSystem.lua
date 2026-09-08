-- Local values: AnimalFoodSystem_mt
AnimalFoodSystem = {}
local AnimalFoodSystem_mt = Class(AnimalFoodSystem)
AnimalFoodSystem.FOOD_CONSUME_TYPE_SERIAL = 1
AnimalFoodSystem.FOOD_CONSUME_TYPE_PARALLEL = 2
g_xmlManager:addCreateSchemaFunction(function()
	AnimalFoodSystem.xmlSchema = XMLSchema.new("animalFood")
end)
g_xmlManager:addInitSchemaFunction(function()
	local v2_ = AnimalFoodSystem.xmlSchema
	v2_:register(XMLValueType.STRING, "animalFood.animals.animal(?)#animalType", "Animal type name")
	v2_:register(XMLValueType.STRING, "animalFood.animals.animal(?)#consumptionType", "Food consumption type", "SERIAL")
	v2_:register(XMLValueType.STRING, "animalFood.animals.animal(?).foodGroup(?)#title", "Food group title")
	v2_:register(XMLValueType.FLOAT, "animalFood.animals.animal(?).foodGroup(?)#productionWeight", "Food group production weight", 0)
	v2_:register(XMLValueType.FLOAT, "animalFood.animals.animal(?).foodGroup(?)#eatWeight", "Food group eat weight", 1)
	v2_:register(XMLValueType.STRING, "animalFood.animals.animal(?).foodGroup(?)#fillTypes", "Food group fill types")
	v2_:register(XMLValueType.STRING, "animalFood.mixtures.mixture(?)#fillType", "Mixture fill type")
	v2_:register(XMLValueType.STRING, "animalFood.mixtures.mixture(?)#animalType", "Mixture animal type")
	v2_:register(XMLValueType.FLOAT, "animalFood.mixtures.mixture(?).ingredient(?)#weight", "Mixture ingredient weight", 0)
	v2_:register(XMLValueType.STRING, "animalFood.mixtures.mixture(?).ingredient(?)#fillTypes", "Mixture ingredient fill types")
	v2_:register(XMLValueType.STRING, "animalFood.recipes.recipe(?)#fillType", "Recipe fill type")
	v2_:register(XMLValueType.STRING, "animalFood.recipes.recipe(?).ingredient(?)#name", "Ingredient name")
	v2_:register(XMLValueType.STRING, "animalFood.recipes.recipe(?).ingredient(?)#title", "Ingredient title")
	v2_:register(XMLValueType.INT, "animalFood.recipes.recipe(?).ingredient(?)#minPercentage", "Ingredient min percentage")
	v2_:register(XMLValueType.INT, "animalFood.recipes.recipe(?).ingredient(?)#maxPercentage", "Ingredient max percentage")
	v2_:register(XMLValueType.STRING, "animalFood.recipes.recipe(?).ingredient(?)#fillTypes", "Ingredient fill types")
end)

-- Upvalues: AnimalFoodSystem_mt
-- Local values: self
function AnimalFoodSystem.new(mission, customMt)
	-- upvalues: (copy) AnimalFoodSystem_mt
	local v5_ = customMt or AnimalFoodSystem_mt
	local v6_ = setmetatable({}, v5_)
	v6_.mission = mission
	v6_.animalFood = {}
	v6_.indexToAnimalFood = {}
	v6_.animalTypeIndexToFood = {}
	v6_.mixtures = {}
	v6_.recipes = {}
	v6_.recipeFillTypeIndexToRecipe = {}
	v6_.animalMixtures = {}
	v6_.mixtureFillTypeIndexToMixture = {}
	return v6_
end

function AnimalFoodSystem:delete() end

-- Local values: filename, xmlFileFood, modMapName, _
function AnimalFoodSystem:loadMapData(xmlFile, missionInfo)
	local v9_ = getXMLString(xmlFile, "map.animals.food#filename")
	if v9_ == nil or v9_ == "" then
		Logging.xmlInfo(xmlFile, "No animals food xml given at \'map.animals.food#filename\'")
		return false
	else
		local v10_ = Utils.getFilename(v9_, self.mission.baseDirectory)
		local v11_ = XMLFile.load("animalFood", v10_, AnimalFoodSystem.xmlSchema)
		if v11_ == nil then
			return false
		else
			local v12_, _ = Utils.getModNameAndBaseDirectory(v10_)
			self.customEnvironment = v12_
			if self:loadAnimalFood(v11_, self.mission.baseDirectory) then
				if self:loadMixtures(v11_, self.mission.baseDirectory) then
					if self:loadRecipes(v11_, self.mission.baseDirectory) then
						v11_:delete()
						return true
					else
						v11_:delete()
						return false
					end
				else
					v11_:delete()
					return false
				end
			else
				v11_:delete()
				return false
			end
		end
	end
end

-- Local values: _, animalFood, sumWeigths, eatWeights, _, foodGroup, _, foodGroup
function AnimalFoodSystem:loadAnimalFood(xmlFile)
	xmlFile:iterate("animalFood.animals.animal", function(_, p15_)
		-- upvalues: (copy) xmlFile, (copy) self
		local v16_ = xmlFile:getValue(p15_ .. "#animalType")
		local v17_ = self.mission.animalSystem:getTypeIndexByName(v16_)
		if v17_ == nil then
			Logging.xmlWarning(xmlFile, "Animal type \'%s\' not defined for foodgroup \'%s\'", v16_, p15_)
		else
			local v18_ = {}
			if self:loadAnimalFoodData(v18_, xmlFile, p15_) then
				v18_.index = #self.animalFood + 1
				v18_.animalTypeIndex = v17_
				local v19_ = self.animalFood
				table.insert(v19_, v18_)
				self.indexToAnimalFood[v18_.index] = v18_
				self.animalTypeIndexToFood[v17_] = v18_
				return
			end
		end
	end)
	for _, v20_ in pairs(self.animalFood) do
		if v20_.consumptionType == AnimalFoodSystem.FOOD_CONSUME_TYPE_PARALLEL then
			local v21_ = 0
			local v22_ = 0
			for _, v23_ in pairs(v20_.groups) do
				v21_ = v21_ + v23_.productionWeight
				v22_ = v22_ + v23_.eatWeight
			end
			for _, v24_ in pairs(v20_.groups) do
				if v21_ > 0 then
					v24_.productionWeight = v24_.productionWeight / v21_
				end
				if v22_ > 0 then
					v24_.eatWeight = v24_.eatWeight / v22_
				end
			end
		end
	end
	return true
end

-- Local values: consumptionType, consumptionTypeName, groups, usedFillTypes
function AnimalFoodSystem:loadAnimalFoodData(animalFood, xmlFile, key)
	local v29_ = AnimalFoodSystem.FOOD_CONSUME_TYPE_SERIAL
	local v30_ = xmlFile:getValue(key .. "#consumptionType", "SERIAL")
	if string.upper(v30_) == "PARALLEL" then
		v29_ = AnimalFoodSystem.FOOD_CONSUME_TYPE_PARALLEL
	end
	local v_u_31_ = {}
	local v_u_32_ = {}
	xmlFile:iterate(key .. ".foodGroup", function(_, p33_)
		-- upvalues: (copy) xmlFile, (copy) self, (copy) v_u_32_, (copy) v_u_31_
		local v34_ = xmlFile:getValue(p33_ .. "#title")
		if v34_ == nil then
			Logging.xmlError(xmlFile, "Missing title for animal food group \'%s\'", p33_)
			return false
		end
		local v35_ = {
			["title"] = g_i18n:convertText(v34_, self.customEnvironment),
			["productionWeight"] = xmlFile:getValue(p33_ .. "#productionWeight", 0),
			["eatWeight"] = xmlFile:getValue(p33_ .. "#eatWeight", 1),
			["fillTypes"] = {}
		}
		if self:getFillTypesFromXML(v35_.fillTypes, v_u_32_, xmlFile, p33_ .. "#fillTypes") then
			local v36_ = v_u_31_
			table.insert(v36_, v35_)
		end
	end)
	animalFood.groups = v_u_31_
	animalFood.consumptionType = v29_
	return true
end

-- Local values: _, mixture, sumWeigths, _, ingredient, _, ingredient
function AnimalFoodSystem:loadMixtures(xmlFile)
	xmlFile:iterate("animalFood.mixtures.mixture", function(_, p39_)
		-- upvalues: (copy) xmlFile, (copy) self
		local v40_ = xmlFile:getValue(p39_ .. "#fillType")
		if v40_ == nil then
			Logging.xmlError(xmlFile, "Missing fillType for food mixture \'%s\'", p39_)
			return false
		end
		local v41_ = g_fillTypeManager:getFillTypeIndexByName(v40_)
		if v41_ == nil then
			Logging.xmlError(xmlFile, "FillType \'%s\' not defined for food mixture \'%s\'", v40_, p39_)
			return false
		end
		if self.mixtureFillTypeIndexToMixture[v41_] ~= nil then
			Logging.xmlError(xmlFile, "FillType \'%s\' already defined for mixture \'%s\'", v40_, p39_)
			return false
		end
		local v42_ = xmlFile:getValue(p39_ .. "#animalType")
		if v42_ == nil then
			Logging.xmlError(xmlFile, "Missing animal type for food mixture \'%s\'", p39_)
			return false
		end
		local v43_ = self.mission.animalSystem:getTypeIndexByName(v42_)
		if v43_ == nil then
			Logging.xmlError(xmlFile, "Animal type \'%s\' not defined for food mixture \'%s\'", v42_, p39_)
			return false
		end
		local v44_ = {}
		if self:loadMixture(v44_, xmlFile, p39_) then
			v44_.index = #self.mixtures + 1
			local v45_ = self.mixtures
			table.insert(v45_, v44_)
			self.animalMixtures[v43_] = self.animalMixtures[v43_] or {}
			local v46_ = self.animalMixtures[v43_]
			table.insert(v46_, v41_)
			self.mixtureFillTypeIndexToMixture[v41_] = v44_
		end
	end)
	for _, v47_ in pairs(self.mixtures) do
		local v48_ = 0
		for _, v49_ in pairs(v47_.ingredients) do
			v48_ = v48_ + v49_.weight
		end
		if v48_ > 0 then
			for _, v50_ in pairs(v47_.ingredients) do
				v50_.weight = v50_.weight / v48_
			end
		end
	end
	return true
end

-- Local values: ingredients, usedFillTypes
function AnimalFoodSystem:loadMixture(mixture, xmlFile, key)
	local v_u_55_ = {}
	local v_u_56_ = {}
	xmlFile:iterate(key .. ".ingredient", function(_, p57_)
		-- upvalues: (copy) xmlFile, (copy) self, (copy) v_u_56_, (copy) v_u_55_
		local v58_ = {
			["fillTypes"] = {},
			["weight"] = xmlFile:getValue(p57_ .. "#weight", 0)
		}
		if self:getFillTypesFromXML(v58_.fillTypes, v_u_56_, xmlFile, p57_ .. "#fillTypes") then
			local v59_ = v_u_55_
			table.insert(v59_, v58_)
		end
	end)
	mixture.ingredients = v_u_55_
	return true
end

function AnimalFoodSystem:loadRecipes(xmlFile)
	xmlFile:iterate("animalFood.recipes.recipe", function(_, p62_)
		-- upvalues: (copy) xmlFile, (copy) self
		local v63_ = xmlFile:getValue(p62_ .. "#fillType")
		if v63_ == nil then
			Logging.xmlError(xmlFile, "Missing fillType for recipe \'%s\'", p62_)
			return false
		end
		local v64_ = g_fillTypeManager:getFillTypeIndexByName(v63_)
		if v64_ == nil then
			Logging.xmlError(xmlFile, "Recipe filltype \'%s\' not defined for \'%s\'", v63_, p62_)
			return false
		end
		if self.recipeFillTypeIndexToRecipe[v64_] ~= nil then
			Logging.xmlError(xmlFile, "Recipe \'%s\' already defined in \'%s\'", v63_, p62_)
			return false
		end
		local v65_ = {}
		if self:loadRecipe(v65_, xmlFile, p62_) then
			v65_.index = #self.recipes + 1
			v65_.fillType = v64_
			local v66_ = self.recipes
			table.insert(v66_, v65_)
			self.recipeFillTypeIndexToRecipe[v64_] = v65_
		end
	end)
	return true
end

-- Local values: ingredients, sumRatios, usedFillTypes, _, ingredient
function AnimalFoodSystem:loadRecipe(recipe, xmlFile, key)
	local v_u_71_ = {}
	local v_u_72_ = 0
	local v_u_73_ = {}
	xmlFile:iterate(key .. ".ingredient", function(_, p74_)
		-- upvalues: (copy) xmlFile, (copy) self, (ref) v_u_72_, (copy) v_u_73_, (copy) v_u_71_
		local v75_ = {
			["name"] = xmlFile:getValue(p74_ .. "#name"),
			["title"] = g_i18n:convertText(xmlFile:getValue(p74_ .. "#title"), self.customEnvironment),
			["minPercentage"] = xmlFile:getValue(p74_ .. "#minPercentage", 0) / 100,
			["maxPercentage"] = xmlFile:getValue(p74_ .. "#maxPercentage", 75) / 100
		}
		v75_.ratio = v75_.maxPercentage - v75_.minPercentage
		v75_.fillTypes = {}
		v_u_72_ = v_u_72_ + v75_.ratio
		if self:getFillTypesFromXML(v75_.fillTypes, v_u_73_, xmlFile, p74_ .. "#fillTypes") then
			local v76_ = v_u_71_
			table.insert(v76_, v75_)
		end
	end)
	local v77_ = v_u_72_
	for _, v78_ in ipairs(v_u_71_) do
		v78_.ratio = v78_.ratio / v77_
	end
	if #v_u_71_ == 0 then
		Logging.xmlWarning(xmlFile, "No ingredients defined for recipe \'%s\'", key)
		return false
	else
		recipe.ingredients = v_u_71_
		return true
	end
end

-- Local values: fillTypeNameStr, fillTypeNames, _, fillTypeName, fillTypeIndex
function AnimalFoodSystem:getFillTypesFromXML(fillTypes, usedFillTypes, xmlFile, key)
	local v83_ = xmlFile:getValue(key)
	if v83_ == nil then
		Logging.xmlError(xmlFile, "Missing fillTypes for ingredient \'%s\'", key)
		return false
	end
	local v84_ = string.split(v83_, " ")
	for _, v85_ in pairs(v84_) do
		local v86_ = g_fillTypeManager:getFillTypeIndexByName(v85_)
		if v86_ == nil then
			Logging.xmlWarning(xmlFile, "FillType \'%s\' not defined. Ignoring it", v85_)
		elseif usedFillTypes[v86_] == nil then
			table.addElement(fillTypes, v86_)
		else
			Logging.xmlWarning(xmlFile, "FillType \'%s\' already used in other ingredient", v85_)
		end
	end
	if #fillTypes ~= 0 then
		return true
	end
	Logging.xmlError(xmlFile, "No fillTypes defined - \'%s\'", key)
	return false
end

function AnimalFoodSystem:getAnimalFood(animalTypeIndex)
	return self.animalTypeIndexToFood[animalTypeIndex]
end

function AnimalFoodSystem:getRecipeByFillTypeIndex(fillTypeIndex)
	return self.recipeFillTypeIndexToRecipe[fillTypeIndex]
end

function AnimalFoodSystem:getMixtureByFillType(fillTypeIndex)
	return self.mixtureFillTypeIndexToMixture[fillTypeIndex]
end

function AnimalFoodSystem:getMixturesByAnimalTypeIndex(animalTypeIndex)
	return self.animalMixtures[animalTypeIndex]
end

-- Local values: animalFood
function AnimalFoodSystem:consumeFood(animalTypeIndex, amountToConsume, foodOwner, consumedFood)
	local v100_ = self.animalTypeIndexToFood[animalTypeIndex]
	if v100_ ~= nil then
		if v100_.consumptionType == AnimalFoodSystem.FOOD_CONSUME_TYPE_SERIAL then
			return self:consumeFoodSerially(amountToConsume, v100_.groups, foodOwner, consumedFood)
		end
		if v100_.consumptionType == AnimalFoodSystem.FOOD_CONSUME_TYPE_PARALLEL then
			return self:consumeFoodParallelly(amountToConsume, v100_.groups, foodOwner, consumedFood)
		end
	end
	return 0
end

-- Local values: productionWeight, totalAmountToConsume, _, foodGroup, oldAmount, deltaProdWeight
function AnimalFoodSystem:consumeFoodSerially(amount, foodGroups, foodOwner, consumedFood)
	local v106_ = 0
	if amount > 0 then
		local v107_ = amount
		for _, v108_ in ipairs(foodGroups) do
			local v109_ = self:consumeFoodGroup(v108_, amount, foodOwner, consumedFood)
			v106_ = v106_ + (amount - v109_) / v107_ * v108_.productionWeight
			amount = v109_
		end
	end
	return v106_
end

-- Local values: productionWeight, _, foodGroup, totalFillLevelInGroup, foodGroupConsume, consumeFood, ret, foodFactor
function AnimalFoodSystem:consumeFoodParallelly(amount, foodGroups, foodOwner, consumedFood)
	local v115_ = 0
	if amount > 0 then
		for _, v116_ in pairs(foodGroups) do
			local v117_ = self:getTotalFillLevelInGroup(v116_, foodOwner)
			local v118_ = amount * v116_.eatWeight
			local v119_ = math.min(v117_, v118_)
			v115_ = v115_ + (v119_ - self:consumeFoodGroup(v116_, v119_, foodOwner, consumedFood)) / v118_ * v116_.productionWeight
		end
	end
	return v115_
end

-- Local values: _, fillTypeIndex, fillLevel, currentFillLevel, amountToConsume, deltaConsumed
function AnimalFoodSystem:consumeFoodGroup(foodGroup, amount, foodOwner, consumedFood)
	for _, v124_ in pairs(foodGroup.fillTypes) do
		local v125_ = foodOwner:getAvailableFood(v124_)
		if v125_ ~= nil then
			local v126_ = math.min(amount, v125_)
			local v127_ = math.min(v125_, v126_)
			local v128_ = amount - v127_
			amount = math.max(v128_, 0)
			consumedFood[v124_] = v127_
			if amount == 0 then
				return amount
			end
		end
	end
	return amount
end

-- Local values: totalFillLevel, _, fillTypeIndex, fillLevel
function AnimalFoodSystem:getTotalFillLevelInGroup(foodGroup, foodOwner)
	local v131_ = 0
	for _, v132_ in pairs(foodGroup.fillTypes) do
		local v133_ = foodOwner:getAvailableFood(v132_)
		if v133_ ~= nil then
			v131_ = v131_ + v133_
		end
	end
	return v131_
end
