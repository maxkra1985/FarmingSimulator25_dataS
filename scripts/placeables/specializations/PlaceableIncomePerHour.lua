PlaceableIncomePerHour = {}

function PlaceableIncomePerHour.prerequisitesPresent(specializations)
	return true
end

function PlaceableIncomePerHour.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "getIncomePerHour", PlaceableIncomePerHour.getIncomePerHour)
end

function PlaceableIncomePerHour.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getNeedHourChanged", PlaceableIncomePerHour.getNeedHourChanged)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "finalizeConstruction", PlaceableIncomePerHour.finalizeConstruction)
end

function PlaceableIncomePerHour.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableIncomePerHour)
	SpecializationUtil.registerEventListener(placeableType, "onHourChanged", PlaceableIncomePerHour)
end

function PlaceableIncomePerHour.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("IncomePerHour")
	schema:register(XMLValueType.FLOAT, basePath .. ".incomePerHour.incomePerHourConfigurations.incomePerHourConfiguration(?)#incomePerHour", "Income per hour")
	schema:register(XMLValueType.FLOAT, basePath .. ".incomePerHour", "Income per hour")
	schema:setXMLSpecializationType()
end
function PlaceableIncomePerHour.initSpecialization()
	g_storeManager:addSpecType("incomePerHour", "shopListAttributeIconIncomePerHour", PlaceableIncomePerHour.loadSpecValueIncomePerHour, PlaceableIncomePerHour.getSpecValueIncomePerHour, StoreSpecies.PLACEABLE)
	g_placeableConfigurationManager:addConfigurationType("incomePerHour", g_i18n:getText("configuration_incomePerHour"), "incomePerHour", PlaceableConfigurationItem)
end

-- Local values: spec, xmlFile, configurationId, configKey
function PlaceableIncomePerHour:onLoad(savegame)
	local v7_ = self.spec_incomePerHour
	local v8_ = self.xmlFile
	local v9_ = self.configurations.incomePerHour or 1
	v7_.incomePerHour = v8_:getValue((string.format("placeable.incomePerHour.incomePerHourConfigurations.incomePerHourConfiguration(%d)#incomePerHour", v9_ - 1))) or v8_:getValue("placeable.incomePerHour", 0)
	v7_.incomePerHourFactor = 1
	v7_.isFinished = self.getNumFinishedConstructibleStates == nil
end

-- Local values: spec
function PlaceableIncomePerHour:finalizeConstruction(superFunc)
	superFunc(self)
	self.spec_incomePerHour.isFinished = true
end

function PlaceableIncomePerHour:getNeedHourChanged(superFunc)
	return true
end

-- Local values: ownerFarmId, spec, environment, incomePerHour
function PlaceableIncomePerHour:onHourChanged()
	if self.isServer then
		local v13_ = self:getOwnerFarmId()
		if v13_ == FarmlandManager.NO_OWNER_FARM_ID then
			return
		elseif self.spec_incomePerHour.isFinished then
			local v14_ = g_currentMission.environment
			local v15_ = self:getIncomePerHour() * v14_.timeAdjustment
			if v15_ ~= 0 then
				g_currentMission:addMoney(v15_, v13_, MoneyType.PROPERTY_INCOME, true)
			end
		end
	else
		return
	end
end

-- Local values: spec
function PlaceableIncomePerHour:getIncomePerHour()
	return self.spec_incomePerHour.incomePerHour
end

-- Local values: incomePerHour, windTurbineIncomePerHour, solarPanelsDefaultConfigIncomePerHour
function PlaceableIncomePerHour.loadSpecValueIncomePerHour(xmlFile, customEnvironment, baseDir)
	local v18_ = xmlFile:getValue("placeable.incomePerHour.incomePerHourConfigurations.incomePerHourConfiguration(0)#incomePerHour", xmlFile:getValue("placeable.incomePerHour", 0))
	local v19_ = xmlFile:getValue("placeable.windTurbine#incomePerHour", 0)
	local v20_ = xmlFile:getValue("placeable.solarPanels.solarPanelsConfigurations.solarPanelsConfiguration(0)#incomePerHour", 0)
	return (v18_ ~= 0 or (v19_ ~= 0 or v20_ ~= 0)) and { v18_, v19_ + v20_ } or nil
end

-- Local values: fixedIncome, variableIncome, maxTotalIncome
function PlaceableIncomePerHour.getSpecValueIncomePerHour(storeItem, realItem)
	if storeItem.specs.incomePerHour == nil then
		return nil
	end
	local v22_ = storeItem.specs.incomePerHour
	local v23_, v24_ = unpack(v22_)
	local v25_ = v23_ * 24
	if v24_ == 0 then
		return string.format("%s / %s", g_i18n:formatMoney(v25_), g_i18n:getText("ui_month"))
	end
	local v26_ = v25_ + v24_ * 24
	return string.format("%s - %s / %s", g_i18n:formatMoney(v25_, nil, false), g_i18n:formatMoney(v26_), g_i18n:getText("ui_month"))
end
