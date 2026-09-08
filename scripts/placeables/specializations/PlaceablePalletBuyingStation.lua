PlaceablePalletBuyingStation = {}
source("dataS/scripts/placeables/specializations/activatables/PalletBuyingStationActivatable.lua")
source("dataS/scripts/placeables/specializations/events/PlaceablePalletBuyEvent.lua")

function PlaceablePalletBuyingStation.prerequisitesPresent(specializations)
	return true
end

function PlaceablePalletBuyingStation.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceablePalletBuyingStation)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceablePalletBuyingStation)
end

function PlaceablePalletBuyingStation.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "openShop", PlaceablePalletBuyingStation.openShop)
	SpecializationUtil.registerFunction(placeableType, "onActivationTriggerCallback", PlaceablePalletBuyingStation.onActivationTriggerCallback)
	SpecializationUtil.registerFunction(placeableType, "shopCallback", PlaceablePalletBuyingStation.shopCallback)
	SpecializationUtil.registerFunction(placeableType, "tryToSpawnPallets", PlaceablePalletBuyingStation.tryToSpawnPallets)
	SpecializationUtil.registerFunction(placeableType, "onPalletBought", PlaceablePalletBuyingStation.onPalletBought)
	SpecializationUtil.registerFunction(placeableType, "getHasPalletForFillType", PlaceablePalletBuyingStation.getHasPalletForFillType)
	SpecializationUtil.registerFunction(placeableType, "getEffectivePricePerPallet", PlaceablePalletBuyingStation.getEffectivePricePerPallet)
end

function PlaceablePalletBuyingStation.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("PlaceablePalletBuyingStation")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".palletBuyingStation#triggerNode", "trigger node")
	schema:register(XMLValueType.STRING, basePath .. ".palletBuyingStation#triggerText", "trigger text")
	schema:register(XMLValueType.STRING, basePath .. ".palletBuyingStation.fillType(?)#name", "Fill type name")
	schema:register(XMLValueType.FLOAT, basePath .. ".palletBuyingStation.fillType(?)#priceScale", "Price scale", 1)
	PalletSpawner.registerXMLPaths(schema, basePath .. ".palletBuyingStation.palletSpawner")
	schema:setXMLSpecializationType()
end

-- Local values: spec, key, palletSpawnerKey, i, fillTypeKey, fillTypeStr, fillType, fillTypeIndex, palletFilename, storeItem, priceScale, pallet, text
function PlaceablePalletBuyingStation:onLoad(savegame)
	local v6_ = self.spec_palletBuyingStation
	v6_.triggerNode = self.xmlFile:getValue("placeable.palletBuyingStation#triggerNode", nil, self.components, self.i3dMappings)
	if v6_.triggerNode ~= nil then
		addTrigger(v6_.triggerNode, "onActivationTriggerCallback", self)
		local v7_ = "placeable.palletBuyingStation.palletSpawner"
		if self.xmlFile:hasProperty(v7_) then
			v6_.palletSpawner = PalletSpawner.new(self.baseDirectory)
			if not v6_.palletSpawner:load(self.components, self.xmlFile, "placeable.palletBuyingStation.palletSpawner", self.customEnvironment, self.i3dMappings) then
				Logging.xmlError(self.xmlFile, "Unable to load pallet spawner %s", v7_)
				return
			end
		end
		v6_.pallets = {}
		v6_.fillTypeIndexToPallet = {}
		local v8_ = 0
		while true do
			local v9_ = string.format("placeable.palletBuyingStation.fillType(%d)", v8_)
			if not self.xmlFile:hasProperty(v9_) then
				break
			end
			local v10_ = self.xmlFile:getValue(v9_ .. "#name")
			local v11_ = g_fillTypeManager:getFillTypeByName(v10_)
			if v11_ ~= nil then
				local v12_ = v11_.index
				local v13_ = v11_.palletFilename
				local v14_ = g_storeManager:getItemByXMLFilename(v13_)
				local v15_ = self.xmlFile:getValue(v9_ .. "#priceScale", 1)
				local v16_ = {
					["imageFilename"] = v14_.imageFilename,
					["title"] = v11_.title,
					["price"] = MathUtil.round(v14_.price * v15_ * EconomyManager.getPriceMultiplier(v12_), 0),
					["fillTypeIndex"] = v12_
				}
				local v17_ = v6_.pallets
				table.insert(v17_, v16_)
				v6_.fillTypeIndexToPallet[v12_] = v16_
			end
			v8_ = v8_ + 1
		end
		local v18_ = g_i18n:getText(self.xmlFile:getValue("placeable.palletBuyingStation#triggerText", "palletShop_open"), self.customEnvironment)
		v6_.activatable = PalletBuyingStationActivatable.new(self, v18_)
		g_currentMission.storageSystem:addPalletBuyingStation(self)
		return true
	end
	Logging.xmlError(self.xmlFile, "Missing triggerNode for pallet buying station %s", "placeable.palletBuyingStation")
end

-- Local values: spec
function PlaceablePalletBuyingStation:onDelete()
	local v20_ = self.spec_palletBuyingStation
	g_currentMission.storageSystem:removePalletBuyingStation(self)
	if v20_.palletSpawner ~= nil then
		v20_.palletSpawner:delete()
	end
	if v20_.triggerNode ~= nil then
		removeTrigger(v20_.triggerNode)
	end
end

-- Local values: spec
function PlaceablePalletBuyingStation:onActivationTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	local v25_ = self.spec_palletBuyingStation
	if (onEnter or onLeave) and (g_localPlayer and g_localPlayer.rootNode == otherId) then
		if onEnter then
			if Platform.isMobile and v25_.activatable:getIsActivatable() then
				v25_.activatable:run()
			else
				g_currentMission.activatableObjectsSystem:addActivatable(v25_.activatable)
			end
		end
		if onLeave then
			g_currentMission.activatableObjectsSystem:removeActivatable(v25_.activatable)
		end
	end
end

-- Local values: spec
function PlaceablePalletBuyingStation:getHasPalletForFillType(fillTypeIndex)
	return self.spec_palletBuyingStation.fillTypeIndexToPallet[fillTypeIndex]
end

-- Local values: spec, pallet
function PlaceablePalletBuyingStation:getEffectivePricePerPallet(fillTypeIndex)
	local v30_ = self.spec_palletBuyingStation.fillTypeIndexToPallet[fillTypeIndex]
	if v30_ ~= nil then
		return v30_.price
	end
end

-- Local values: spec
function PlaceablePalletBuyingStation:openShop()
	if g_currentMission:getHasPlayerPermission(Farm.PERMISSION.BUY_VEHICLE) then
		local v32_ = self.spec_palletBuyingStation
		PalletShopDialog.show(self.shopCallback, self, v32_.pallets, 10, self.storeItem.name)
	else
		InfoDialog.show(g_i18n:getText("shop_messageNoPermissionGeneral"))
	end
end

-- Local values: spec, pallet, totalPrice, enoughMoney, enoughSlots, text, callback
function PlaceablePalletBuyingStation:shopCallback(selectedIndex, quantity)
	if selectedIndex == nil or quantity == nil then
		return
	else
		local v_u_36_ = self.spec_palletBuyingStation.pallets[selectedIndex]
		if v_u_36_ == nil then
			return
		else
			local v37_ = v_u_36_.price * quantity
			if v37_ <= 0 and true or v37_ <= g_currentMission:getMoney() then
				if g_currentMission.slotSystem:getCanAddLimitedObjects(SlotSystem.LIMITED_OBJECT_PALLET, quantity) then
					local v38_ = string.format(g_i18n:getText("shop_doYouWantToBuyPallet", self.customEnvironment), g_i18n:formatMoney(v37_, 0, true, true))
					YesNoDialog.show(function(p39_)
						-- upvalues: (copy) self, (copy) v_u_36_, (copy) quantity
						if p39_ then
							MessageDialog.show(g_i18n:getText("shop_buyingPallets", self.customEnvironment))
							g_client:getServerConnection():sendEvent(PlaceablePalletBuyEvent.new(self, g_localPlayer.farmId, v_u_36_.fillTypeIndex, quantity, v_u_36_.price))
							g_messageCenter:subscribeOneshot(PlaceablePalletBuyEvent, PlaceablePalletBuyingStation.onPalletBought, self)
						end
					end, nil, v38_)
				else
					InfoDialog.show(g_i18n:getText("shop_messageNotEnoughSlotsToBuy", self.customEnvironment))
				end
			else
				InfoDialog.show(g_i18n:getText("shop_messageNotEnoughMoneyToBuy", self.customEnvironment))
				return
			end
		end
	end
end

-- Local values: spec, numBoughtPallets, onPalletsSpawned
function PlaceablePalletBuyingStation:tryToSpawnPallets(farmId, fillTypeIndex, quantity, callback)
	local v_u_45_ = self.spec_palletBuyingStation
	local v_u_46_ = 0
	if v_u_45_.palletSpawner ~= nil then
		local function v_u_51_(_, p47_, p48_, p49_)
			-- upvalues: (ref) v_u_46_, (copy) farmId, (copy) quantity, (copy) v_u_45_, (copy) fillTypeIndex, (copy) v_u_51_, (copy) callback
			if p47_ == nil then
				callback(p48_, v_u_46_)
				return
			else
				v_u_46_ = v_u_46_ + 1
				local v50_ = p47_:getFirstValidFillUnitToFill(p49_)
				if v50_ then
					p47_:addFillUnitFillLevel(farmId, v50_, math.huge, p49_, ToolType.UNDEFINED)
				end
				if v_u_46_ < quantity then
					v_u_45_.palletSpawner:spawnPallet(farmId, fillTypeIndex, v_u_51_, nil)
				else
					callback(p48_, v_u_46_)
				end
			end
		end
		v_u_45_.palletSpawner:spawnPallet(farmId, fillTypeIndex, v_u_51_, nil)
	end
end

-- Local values: text
function PlaceablePalletBuyingStation:onPalletBought(errorCode, numBoughtPallets)
	MessageDialog.hide()
	if errorCode == PalletSpawner.RESULT_SUCCESS then
		InfoDialog.show(g_i18n:getText("shop_messageAllPalletsBought", self.customEnvironment))
	else
		local v55_ = g_i18n:getText("shop_messagePalletsCouldNotBeLoaded", self.customEnvironment)
		if errorCode == PalletSpawner.RESULT_NO_SPACE then
			v55_ = g_i18n:getText("shop_messageNotEnoughSpaceToBuyAllPallets", self.customEnvironment)
		elseif errorCode == PalletSpawner.PALLET_LIMITED_REACHED then
			v55_ = g_i18n:getText("shop_messageNotEnoughSlotsToBuyAllPallets", self.customEnvironment)
		end
		if numBoughtPallets > 0 then
			v55_ = v55_ .. "\n" .. string.format(g_i18n:getText("shop_buyingPalletsAmount", self.customEnvironment), numBoughtPallets)
		end
		InfoDialog.show(v55_, nil, nil, DialogElement.TYPE_WARNING)
	end
end
