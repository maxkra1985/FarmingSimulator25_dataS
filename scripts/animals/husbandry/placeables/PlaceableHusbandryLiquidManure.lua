PlaceableHusbandryLiquidManure = {}

function PlaceableHusbandryLiquidManure.prerequisitesPresent(specializations)
	return true
end

function PlaceableHusbandryLiquidManure.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateOutput", PlaceableHusbandryLiquidManure.updateOutput)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateProduction", PlaceableHusbandryLiquidManure.updateProduction)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableHusbandryLiquidManure.updateInfo)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getConditionInfos", PlaceableHusbandryLiquidManure.getConditionInfos)
end

function PlaceableHusbandryLiquidManure.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandryLiquidManure)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableHusbandryLiquidManure)
	SpecializationUtil.registerEventListener(placeableType, "onHusbandryAnimalsUpdate", PlaceableHusbandryLiquidManure)
end

function PlaceableHusbandryLiquidManure.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")
	local v5_ = basePath .. ".husbandry.liquidManure"
	schema:register(XMLValueType.FLOAT, v5_ .. ".manure#factor", "Factor to transform straw to manure", 1)
	schema:register(XMLValueType.BOOL, v5_ .. ".manure#active", "Enable manure production", true)
	schema:setXMLSpecializationType()
end

-- Local values: spec
function PlaceableHusbandryLiquidManure:onLoad(savegame)
	local v7_ = self.spec_husbandryLiquidManure
	v7_.litersPerHour = 0
	v7_.fillType = FillType.LIQUIDMANURE
	v7_.info = {
		["title"] = g_i18n:getText("fillType_liquidManure"),
		["text"] = ""
	}
end

-- Local values: spec
function PlaceableHusbandryLiquidManure:onFinalizePlacement()
	if not self:getHusbandryIsFillTypeSupported(self.spec_husbandryLiquidManure.fillType) then
		Logging.xmlWarning(self.xmlFile, "Missing filltype \'liquidManure\' in husbandry storage!")
	end
end

-- Local values: spec, liters
function PlaceableHusbandryLiquidManure:updateOutput(superFunc, foodFactor, productionFactor, globalProductionFactor)
	if self.isServer then
		local v14_ = self.spec_husbandryLiquidManure
		if v14_.litersPerHour > 0 then
			local v15_ = foodFactor * v14_.litersPerHour * g_currentMission.environment.timeAdjustment
			self:addHusbandryFillLevelFromTool(self:getOwnerFarmId(), v15_, v14_.fillType, nil, nil, nil)
		end
	end
	superFunc(self, foodFactor, productionFactor, globalProductionFactor)
end

-- Local values: factor, spec, freeCapacity
function PlaceableHusbandryLiquidManure:updateProduction(superFunc, foodFactor)
	local v19_ = superFunc(self, foodFactor)
	if self.isServer and self:getHusbandryFreeCapacity(self.spec_husbandryLiquidManure.fillType) <= 0 then
		v19_ = v19_ * 0.75
	end
	return v19_
end

-- Local values: spec, _, cluster, subType, liquidManure, age, litersPerAnimal, litersPerDay
function PlaceableHusbandryLiquidManure:onHusbandryAnimalsUpdate(clusters)
	local v22_ = self.spec_husbandryLiquidManure
	v22_.litersPerHour = 0
	for _, v23_ in ipairs(clusters) do
		local v24_ = g_currentMission.animalSystem:getSubTypeByIndex(v23_.subTypeIndex)
		if v24_ ~= nil then
			local v25_ = v24_.output.liquidManure
			if v25_ ~= nil then
				local v26_ = v25_:get((v23_:getAge())) * v23_:getNumAnimals()
				v22_.litersPerHour = v22_.litersPerHour + v26_ / 24
			end
		end
	end
end

-- Local values: infos, spec, fillType, info, capacity, ratio
function PlaceableHusbandryLiquidManure:getConditionInfos(superFunc)
	local v29_ = superFunc(self)
	local v30_ = self.spec_husbandryLiquidManure
	local v31_ = g_fillTypeManager:getFillTypeByIndex(v30_.fillType)
	if v31_ ~= nil then
		local v32_ = {
			["title"] = v31_.title,
			["value"] = self:getHusbandryFillLevel(v30_.fillType)
		}
		local v33_ = self:getHusbandryCapacity(v30_.fillType)
		local v34_ = 1
		if v33_ > 0 then
			v34_ = v32_.value / v33_
		else
			v32_.disabled = true
			v32_.title = string.format("%s (%s)", v32_.title, g_i18n:getText("info_husbandryMissingLiquidManureTank"))
		end
		v32_.ratio = math.clamp(v34_, 0, 1)
		v32_.invertedBar = true
		table.insert(v29_, v32_)
	end
	return v29_
end

-- Local values: spec, fillLevel
function PlaceableHusbandryLiquidManure:updateInfo(superFunc, infoTable)
	superFunc(self, infoTable)
	local v38_ = self.spec_husbandryLiquidManure
	local v39_ = self:getHusbandryFillLevel(v38_.fillType)
	v38_.info.text = string.format("%d l", v39_)
	local v40_ = v38_.info
	table.insert(infoTable, v40_)
end
