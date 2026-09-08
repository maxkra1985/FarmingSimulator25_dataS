-- Local values: ShopConfigScreenExtension_mt
ShopConfigScreenExtension = {}
ShopConfigScreenExtension.MOD_NAME = g_currentModName
ShopConfigScreenExtension.MOD_DIR = g_currentModDirectory
ShopConfigScreenExtension.GUI_EXT_XML = g_currentModDirectory .. "gui/ShopConfigScreenExtension.xml"
ShopConfigScreenExtension.HEADER_SIZE = 75
local ShopConfigScreenExtension_mt = Class(ShopConfigScreenExtension)

-- Upvalues: ShopConfigScreenExtension_mt
-- Local values: self
function ShopConfigScreenExtension.new(customMt)
	-- upvalues: (copy) ShopConfigScreenExtension_mt
	local v3_ = customMt or ShopConfigScreenExtension_mt
	return setmetatable({}, v3_)
end

function ShopConfigScreenExtension:unloadMapData() end

function ShopConfigScreenExtension:delete() end

function ShopConfigScreenExtension:update(dt) end

-- Local values: configName, config, configData
function ShopConfigScreenExtension.getConfigWorkingWidth(storeItem, configurations)
	if storeItem.specs.workingWidthConfig == nil then
		if storeItem.specs.workingWidth ~= nil then
			return storeItem.specs.workingWidth.width or 0
		end
	else
		for v6_, v7_ in pairs(configurations) do
			if storeItem.specs.workingWidthConfig[v6_] ~= nil then
				local v8_ = storeItem.specs.workingWidthConfig[v6_][v7_]
				if v8_ ~= nil then
					return v8_.width
				end
			end
		end
	end
	return 0
end

-- Local values: workingWidth, priceSpotSpray, priceSeeAndSpray, pricePwm, spotSprayConfigs, pwmConfigs
function ShopConfigScreenExtension:updateConfigPrices(storeItem, configurations)
	StoreItemUtil.loadSpecsFromXML(storeItem)
	if storeItem.configurations ~= nil then
		local v11_ = ShopConfigScreenExtension.getConfigWorkingWidth(storeItem, configurations)
		local v12_, v13_, v14_ = g_precisionFarming:getSprayerConfigPrices()
		local v15_ = storeItem.configurations.weedSpotSpray
		if v15_ ~= nil then
			if v15_[2].overwrittenTitle == nil then
				v15_[2].price = v12_ * math.floor(v11_)
			else
				v15_[2].price = v13_ * math.floor(v11_)
			end
		end
		local v16_ = storeItem.configurations.pulseWidthModulation
		if v16_ ~= nil then
			v16_[2].price = v14_ * math.floor(v11_)
		end
	end
end

-- Local values: configSet
function ShopConfigScreenExtension:getIsConfigurationInConfigSet(storeItem, configSetIndex, configName)
	if storeItem ~= nil and #storeItem.configurationSets > 0 then
		local v20_ = storeItem.configurationSets[configSetIndex]
		if v20_ ~= nil and v20_.configurations[configName] then
			return true
		end
	end
	return false
end

function ShopConfigScreenExtension:overwriteGameFunctions(pfModule)
	pfModule:overwriteGameFunction(ShopConfigScreen, "loadMapData", function(p23_, p24_, ...)
		-- upvalues: (copy) self
		p23_(p24_, ...)
		self.precisionFarmingInfoContainer = PrecisionFarmingGUI.loadAdditionalGUI("gui/ShopConfigScreenExtension.xml", p24_, p24_.elements[1])
		p24_.precisionFarmingInfoWindowBackgroundSizeOffset = p24_.precisionFarmingInfoWindowBackground.size[2] - p24_.precisionFarmingInfoWindow.size[2]
		self.precisionFarmingTexts = {}
		self.precisionFarmingTexts.cropSensorHeader = g_i18n:getText("shopInfo_cropSensorHeader", ShopConfigScreenExtension.MOD_NAME)
		self.precisionFarmingTexts.cropSensorText = g_i18n:getText("shopInfo_cropSensorText", ShopConfigScreenExtension.MOD_NAME)
		self.precisionFarmingTexts.manureSensorHeader = g_i18n:getText("shopInfo_manureSensorHeader", ShopConfigScreenExtension.MOD_NAME)
		self.precisionFarmingTexts.manureSensorText = g_i18n:getText("shopInfo_manureSensorText", ShopConfigScreenExtension.MOD_NAME)
		self.precisionFarmingTexts.weedSpotSprayHeader = g_i18n:getText("shopInfo_weedSpotSprayHeader", ShopConfigScreenExtension.MOD_NAME)
		self.precisionFarmingTexts.weedSpotSprayText = g_i18n:getText("shopInfo_weedSpotSprayText", ShopConfigScreenExtension.MOD_NAME)
		local v25_ = self
		local v26_ = {
			["cropSensor"] = {
				["lastIndex"] = 1,
				["lastChangeTime"] = 0,
				["title"] = g_i18n:getText("shopInfo_cropSensorHeader", ShopConfigScreenExtension.MOD_NAME),
				["text"] = g_i18n:getText("shopInfo_cropSensorText", ShopConfigScreenExtension.MOD_NAME)
			},
			["manureSensor"] = {
				["lastIndex"] = 1,
				["lastChangeTime"] = 0,
				["title"] = g_i18n:getText("shopInfo_manureSensorHeader", ShopConfigScreenExtension.MOD_NAME),
				["text"] = g_i18n:getText("shopInfo_manureSensorText", ShopConfigScreenExtension.MOD_NAME)
			},
			["weedSpotSpray"] = {
				["lastIndex"] = 1,
				["lastChangeTime"] = 0,
				["title"] = g_i18n:getText("shopInfo_weedSpotSprayHeader", ShopConfigScreenExtension.MOD_NAME),
				["text"] = g_i18n:getText("shopInfo_weedSpotSprayText", ShopConfigScreenExtension.MOD_NAME)
			},
			["pulseWidthModulation"] = {
				["lastIndex"] = 1,
				["lastChangeTime"] = 0,
				["title"] = g_i18n:getText("shopInfo_pulseWidthModulationHeader", ShopConfigScreenExtension.MOD_NAME),
				["text"] = g_i18n:getText("shopInfo_pulseWidthModulationText", ShopConfigScreenExtension.MOD_NAME)
			}
		}
		v25_.pfShopConfigurations = v26_
	end)
	pfModule:overwriteGameFunction(ShopConfigScreen, "onOpen", function(p27_, p28_, ...)
		-- upvalues: (copy) self
		p27_(p28_, ...)
		self.pfLastCropSensorConfigurationIndex = nil
		self.pfLastManureSensorConfigurationIndex = nil
		self.pfLastWeedSpotSpraySensorConfigurationIndex = nil
		if self.pfShopConfigurations ~= nil then
			for _, v29_ in pairs(self.pfShopConfigurations) do
				v29_.lastIndex = 1
				v29_.lastChangeTime = 0
			end
		end
	end)
	pfModule:overwriteGameFunction(ShopConfigScreen, "loadCurrentConfiguration", function(p30_, p31_, ...)
		-- upvalues: (copy) self
		p30_(p31_, ...)
		if p31_.configurations ~= nil and self.pfShopConfigurations ~= nil then
			for v32_, v33_ in pairs(self.pfShopConfigurations) do
				local v34_ = p31_.configurations[v32_]
				if v34_ ~= nil and v33_.lastIndex ~= v34_ then
					v33_.lastIndex = v34_
					v33_.lastChangeTime = g_time
				end
			end
			local v35_ = 0
			local v36_ = nil
			for v37_, v38_ in pairs(self.pfShopConfigurations) do
				if not self:getIsConfigurationInConfigSet(p31_.storeItem, p31_.currentConfigSet, v37_) then
					local v39_ = p31_.configurations[v37_]
					if v39_ ~= nil and (v39_ > 1 and v35_ < v38_.lastChangeTime) then
						v35_ = v38_.lastChangeTime
						v36_ = v38_
					end
				end
			end
			if v36_ == nil then
				for v40_, v41_ in pairs(self.pfShopConfigurations) do
					if not self:getIsConfigurationInConfigSet(p31_.storeItem, p31_.currentConfigSet, v40_) then
						local v42_ = p31_.configurations[v40_]
						if v42_ ~= nil and v42_ > 1 then
							v36_ = v41_
							break
						end
					end
				end
			end
			p31_.precisionFarmingInfoWindow:setVisible(v36_ ~= nil)
			if v36_ ~= nil then
				p31_.precisionFarmingInfoHeader:setText(v36_.title)
				p31_.precisionFarmingInfoText:setText(v36_.text)
				local _, v43_ = getNormalizedScreenValues(0, ShopConfigScreenExtension.HEADER_SIZE)
				local v44_ = p31_.precisionFarmingInfoText:getTextHeight(true) + v43_
				p31_.precisionFarmingInfoWindow:setSize(nil, v44_)
				p31_.precisionFarmingInfoWindowBackground:setSize(nil, v44_ + p31_.precisionFarmingInfoWindowBackgroundSizeOffset)
			end
		end
	end)
	pfModule:overwriteGameFunction(ShopConfigScreen, "updateDisplay", function(p45_, p46_, p47_, p48_, p49_, p50_, ...)
		-- upvalues: (copy) self
		self:updateConfigPrices(p46_.storeItem, p46_.configurations)
		return p45_(p46_, p47_, p48_, p49_, p50_, ...)
	end)
	pfModule:overwriteGameFunction(ShopConfigScreen, "updateData", function(p51_, p52_, p53_, p54_, p55_, ...)
		-- upvalues: (copy) self
		self:updateConfigPrices(p52_.storeItem, p52_.configurations)
		local v56_ = p52_.configurationToListElement.weedSpotSpray
		if v56_ ~= nil then
			local v57_ = v56_:getDescendantByName("price")
			p52_:setConfigPrice("weedSpotSpray", p52_.configurations.weedSpotSpray, v57_, p54_)
		end
		local v58_ = p52_.configurationToListElement.pulseWidthModulation
		if v58_ ~= nil then
			local v59_ = v58_:getDescendantByName("price")
			p52_:setConfigPrice("pulseWidthModulation", p52_.configurations.pulseWidthModulation, v59_, p54_)
		end
		return p51_(p52_, p53_, p54_, p55_, ...)
	end)
	pfModule:overwriteGameFunction(BuyVehicleData, "updatePrice", function(p60_, p61_, ...)
		-- upvalues: (copy) self
		self:updateConfigPrices(p61_.storeItem, p61_.configurations)
		return p60_(p61_, ...)
	end)
end
