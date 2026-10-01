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
function PlaceableIncomePerHour:onLoad(savegame)
	local spec = self.spec_incomePerHour
	local xmlFile = self.xmlFile
	local configurationId = self.configurations.incomePerHour or 1
	local configKey = string.format("placeable.incomePerHour.incomePerHourConfigurations.incomePerHourConfiguration(%d)#incomePerHour", configurationId - 1)
	spec.incomePerHour = xmlFile:getValue(configKey) or xmlFile:getValue("placeable.incomePerHour", 0)
	spec.incomePerHourFactor = 1
	spec.isFinished = self.getNumFinishedConstructibleStates == nil
end
function PlaceableIncomePerHour:finalizeConstruction(superFunc)
	superFunc(self)
	local spec = self.spec_incomePerHour
	spec.isFinished = true
end
function PlaceableIncomePerHour:getNeedHourChanged(superFunc)
	return true
end
function PlaceableIncomePerHour:onHourChanged()
	if not self.isServer then
		return
	end
	local ownerFarmId = self:getOwnerFarmId()
	if ownerFarmId == FarmlandManager.NO_OWNER_FARM_ID then
		return
	end
	local spec = self.spec_incomePerHour
	if not spec.isFinished then
		return
	else
		local environment = g_currentMission.environment
		local incomePerHour = self:getIncomePerHour() * environment.timeAdjustment
		if incomePerHour ~= 0 then
			g_currentMission:addMoney(incomePerHour, ownerFarmId, MoneyType.PROPERTY_INCOME, true)
		end
	end
end
function PlaceableIncomePerHour:getIncomePerHour()
	local spec = self.spec_incomePerHour
	return spec.incomePerHour
end
function PlaceableIncomePerHour.loadSpecValueIncomePerHour(xmlFile, customEnvironment, baseDir)
	local incomePerHour = xmlFile:getValue("placeable.incomePerHour.incomePerHourConfigurations.incomePerHourConfiguration(0)#incomePerHour", xmlFile:getValue("placeable.incomePerHour", 0))
	local windTurbineIncomePerHour = xmlFile:getValue("placeable.windTurbine#incomePerHour", 0)
	local solarPanelsDefaultConfigIncomePerHour = xmlFile:getValue("placeable.solarPanels.solarPanelsConfigurations.solarPanelsConfiguration(0)#incomePerHour", 0)
	if incomePerHour == 0 and (windTurbineIncomePerHour == 0 and solarPanelsDefaultConfigIncomePerHour == 0) then
		return nil
	end
	return { incomePerHour, windTurbineIncomePerHour + solarPanelsDefaultConfigIncomePerHour }
end
function PlaceableIncomePerHour.getSpecValueIncomePerHour(storeItem, realItem)
	if storeItem.specs.incomePerHour == nil then
		return nil
	end
	local fixedIncome, variableIncome = unpack(storeItem.specs.incomePerHour)
	fixedIncome = fixedIncome * 24
	if variableIncome ~= 0 then
		variableIncome = variableIncome * 24
		local maxTotalIncome = fixedIncome + variableIncome
		return string.format("%s - %s / %s", g_i18n:formatMoney(fixedIncome, nil, false), g_i18n:formatMoney(maxTotalIncome), g_i18n:getText("ui_month"))
	else
		return string.format("%s / %s", g_i18n:formatMoney(fixedIncome), g_i18n:getText("ui_month"))
	end
end
