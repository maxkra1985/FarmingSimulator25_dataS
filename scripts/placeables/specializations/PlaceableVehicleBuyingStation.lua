PlaceableVehicleBuyingStation = {}
source("dataS/scripts/placeables/specializations/activatables/VehicleBuyingStationActivatable.lua")
source("dataS/scripts/placeables/specializations/events/PlaceableVehicleBuyingStationEvent.lua")

function PlaceableVehicleBuyingStation.prerequisitesPresent(specializations)
	return true
end

function PlaceableVehicleBuyingStation.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableVehicleBuyingStation)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableVehicleBuyingStation)
end

function PlaceableVehicleBuyingStation.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "buyVehicle", PlaceableVehicleBuyingStation.buyVehicle)
	SpecializationUtil.registerFunction(placeableType, "onVehicleBuyingStationTriggerCallback", PlaceableVehicleBuyingStation.onVehicleBuyingStationTriggerCallback)
end

function PlaceableVehicleBuyingStation.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("PlaceableVehicleBuyingStation")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".vehicleBuyingStation.trigger#node", "trigger node")
	schema:register(XMLValueType.STRING, basePath .. ".vehicleBuyingStation.trigger#text", "trigger text")
	schema:register(XMLValueType.STRING, basePath .. ".vehicleBuyingStation#title", "Shop title")
	schema:register(XMLValueType.STRING, basePath .. ".vehicleBuyingStation#description", "Shop description")
	schema:register(XMLValueType.STRING, basePath .. ".vehicleBuyingStation.message#bought", "Vehicle bought message")
	schema:register(XMLValueType.STRING, basePath .. ".vehicleBuyingStation.message#failed", "Vehicle failed message")
	schema:register(XMLValueType.STRING, basePath .. ".vehicleBuyingStation.message#noSpace", "Vehicle no space message")
	schema:register(XMLValueType.STRING, basePath .. ".vehicleBuyingStation.message#noPermission", "Vehicle no permission message")
	schema:register(XMLValueType.STRING, basePath .. ".vehicleBuyingStation.message#noMoney", "Vehicle no money message")
	schema:register(XMLValueType.STRING, basePath .. ".vehicleBuyingStation.storeItem(?)#xmlFilename", "Vehicle storeitem xml config file")
	schema:register(XMLValueType.INT, basePath .. ".vehicleBuyingStation.storeItem(?)#price", "Vehicle costs")
	schema:register(XMLValueType.INT, basePath .. ".vehicleBuyingStation.storeItem(?)#transportCosts", "Vehicle transportation costs")
	PlacementUtil.registerXMLPaths(schema, basePath .. ".vehicleBuyingStation")
	schema:setXMLSpecializationType()
end

-- Local values: spec, key, _, storeItemKey, xmlFilename, filename, storeItem, imageFilename, price, transportCosts, data, _, spawnPlaceKey, spawnPlace, title, description, text, callbackFunc
function PlaceableVehicleBuyingStation:onLoad(savegame)
	local v6_ = self.spec_vehicleBuyingStation
	v6_.triggerNode = self.xmlFile:getNode("placeable.vehicleBuyingStation.trigger#node", nil, self.components, self.i3dMappings)
	if v6_.triggerNode ~= nil then
		addTrigger(v6_.triggerNode, "onVehicleBuyingStationTriggerCallback", self)
		v6_.storeItems = {}
		for _, v7_ in self.xmlFile:iterator("placeable.vehicleBuyingStation.storeItem") do
			local v8_ = self.xmlFile:getString(v7_ .. "#xmlFilename")
			if string.isNilOrWhitespace(v8_) then
				Logging.xmlError(self.xmlFile, "xmlFilename missing for vehicle buying station %s", v7_)
			else
				local v9_ = Utils.getFilename(v8_, self.baseDirectory)
				local v10_ = g_storeManager:getItemByXMLFilename(v9_)
				if v10_ == nil then
					Logging.xmlError(self.xmlFile, "Could not find storeitem for xmlFilename \'%s\'", v9_)
				else
					local v11_ = v10_.imageFilename
					local v12_ = self.xmlFile:getInt(v7_ .. "#price", v10_.price)
					local v13_ = self.xmlFile:getInt(v7_ .. "#transportCosts", 15000)
					local v14_ = {
						["storeItem"] = v10_,
						["title"] = v10_.name,
						["price"] = v12_,
						["imageFilename"] = v11_,
						["transportCosts"] = v13_
					}
					table.addElement(v6_.storeItems, v14_)
				end
			end
		end
		v6_.sendNumBits = MathUtil.getNumRequiredBits(#v6_.storeItems)
		v6_.usedPlaces = {}
		v6_.spawnPlaces = {}
		for _, v15_ in self.xmlFile:iterator("placeable.vehicleBuyingStation.spawnPlaces.spawnPlace") do
			local v16_ = PlacementUtil.loadPlaceFromXML(self.xmlFile, v15_, self.components, self.i3dMappings)
			local v17_ = v6_.spawnPlaces
			table.insert(v17_, v16_)
		end
		if #v6_.spawnPlaces == 0 then
			Logging.xmlError(v6_.xmlFile, "No spawn place(s) defined for vehicle buying station %s%s", "placeable.vehicleBuyingStation", ".spawnPlaces")
			return false
		end
		v6_.vehicleBoughtMessage = self.xmlFile:getString("placeable.vehicleBuyingStation.message#bought")
		v6_.vehicleBuyingFailedMessage = self.xmlFile:getString("placeable.vehicleBuyingStation.message#failed")
		v6_.vehicleBuyingFailedNoSpaceMessage = self.xmlFile:getString("placeable.vehicleBuyingStation.message#noSpace")
		v6_.vehicleBuyingFailedNoPermissionMessage = self.xmlFile:getString("placeable.vehicleBuyingStation.message#noPermission")
		v6_.vehicleBuyingFailedNoMoneyMessage = self.xmlFile:getString("placeable.vehicleBuyingStation.message#noMoney")
		local v_u_18_ = g_i18n:convertText(self.xmlFile:getString("placeable.vehicleBuyingStation#title", "$l10n_ui_vehicleShopTitle"), self.customEnvironment)
		local v_u_19_ = g_i18n:convertText(self.xmlFile:getString("placeable.vehicleBuyingStation#description", "$l10n_ui_vehicleShopDescription"), self.customEnvironment)
		local v20_ = g_i18n:convertText(self.xmlFile:getString("placeable.vehicleBuyingStation.trigger#text", "$l10n_vehicleShop_open"), self.customEnvironment)
		v6_.activatable = VehicleBuyingStationActivatable.new(self, function()
			-- upvalues: (copy) self, (copy) v_u_18_, (copy) v_u_19_
			if g_currentMission:getHasPlayerPermission(Farm.PERMISSION.BUY_VEHICLE) then
				local v21_ = self.spec_vehicleBuyingStation
				VehicleShopDialog.show(PlaceableVehicleBuyingStation.vehicleShopCallback, self, v21_.storeItems, v_u_18_, v_u_19_)
			else
				InfoDialog.show(g_i18n:getText("shop_messageNoPermissionGeneral"))
			end
		end, v20_)
		return true
	end
	Logging.xmlError(self.xmlFile, "Missing triggerNode for vehicle buying station %s", "placeable.vehicleBuyingStation")
end

-- Local values: spec
function PlaceableVehicleBuyingStation:onDelete()
	local v23_ = self.spec_vehicleBuyingStation
	if v23_.triggerNode ~= nil then
		removeTrigger(v23_.triggerNode)
	end
end

-- Local values: spec
function PlaceableVehicleBuyingStation:onVehicleBuyingStationTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	local v28_ = self.spec_vehicleBuyingStation
	if (onEnter or onLeave) and (g_localPlayer and g_localPlayer.rootNode == otherId) then
		if onEnter then
			if Platform.isMobile and v28_.activatable:getIsActivatable() then
				v28_.activatable:run()
			else
				g_currentMission.activatableObjectsSystem:addActivatable(v28_.activatable)
			end
		end
		if onLeave then
			g_currentMission.activatableObjectsSystem:removeActivatable(v28_.activatable)
		end
	end
end

-- Local values: spec, data, totalPrice, enoughMoney, storeItem, enoughSlots, text, callback
function PlaceableVehicleBuyingStation:vehicleShopCallback(selectedIndex)
	if selectedIndex == nil then
		return
	else
		local v31_ = self.spec_vehicleBuyingStation.storeItems[selectedIndex]
		if v31_ == nil then
			return
		else
			local v32_ = v31_.price + v31_.transportCosts
			if v32_ <= 0 and true or v32_ <= g_currentMission:getMoney() then
				local v33_ = v31_.storeItem
				if g_currentMission.slotSystem:hasEnoughSlots(v33_) then
					local v34_ = string.namedFormat(g_i18n:getText("shop_doYouWantToBuyVehicle"), "price", g_i18n:formatMoney(v32_, 0, true, true))
					YesNoDialog.show(function(p35_)
						-- upvalues: (copy) self, (copy) selectedIndex
						if p35_ then
							MessageDialog.show(g_i18n:getText("shop_buyingVehicle"))
							g_client:getServerConnection():sendEvent(PlaceableVehicleBuyingStationEvent.new(self, g_localPlayer.farmId, selectedIndex))
							g_messageCenter:subscribeOneshot(PlaceableVehicleBuyingStationEvent, PlaceableVehicleBuyingStation.onVehicleBought, self)
						end
					end, nil, v34_)
				else
					InfoDialog.show(g_i18n:getText("shop_messageNotEnoughSlotsToBuy"), nil, nil, DialogElement.TYPE_WARNING)
				end
			else
				InfoDialog.show(g_i18n:getText("shop_messageNotEnoughMoneyToBuy"), nil, nil, DialogElement.TYPE_WARNING)
				return
			end
		end
	end
end

-- Local values: spec, text
function PlaceableVehicleBuyingStation:onVehicleBought(errorCode)
	MessageDialog.hide()
	local v38_ = self.spec_vehicleBuyingStation
	if errorCode == PlaceableVehicleBuyingStationEvent.STATE_SUCCESS then
		InfoDialog.show(g_i18n:convertText(v38_.vehicleBoughtMessage or "$l10n_shop_messageThanksForBuying", self.customEnvironment))
		g_currentMission:showMoneyChange(MoneyType.SHOP_VEHICLE_BUY)
	else
		local v39_ = g_i18n:convertText(v38_.vehicleBuyingFailedMessage or "$l10n_shop_messageFailedToLoadVehicle", self.customEnvironment)
		if errorCode == PlaceableVehicleBuyingStationEvent.STATE_NO_SPACE then
			v39_ = g_i18n:convertText(v38_.vehicleBuyingFailedNoSpaceMessage or "$l10n_shop_messageNoSpace", self.customEnvironment)
		elseif errorCode == PlaceableVehicleBuyingStationEvent.STATE_NO_PERMISSION then
			v39_ = g_i18n:convertText(v38_.vehicleBuyingFailedNoPermissionMessage or "$l10n_shop_messageNoPermissionToBuyVehicleText", self.customEnvironment)
		elseif errorCode == PlaceableVehicleBuyingStationEvent.STATE_NOT_ENOUGH_MONEY then
			v39_ = g_i18n:convertText(v38_.vehicleBuyingFailedNoMoneyMessage or "$l10n_shop_messageNotEnoughMoneyToBuy", self.customEnvironment)
		end
		InfoDialog.show(v39_, nil, nil, DialogElement.TYPE_WARNING)
	end
end

-- Local values: spec, data, storeItem, vehicleBuyData, buyCallback
function PlaceableVehicleBuyingStation:buyVehicle(farmId, storeItemIndex, callback)
	local v_u_44_ = self.spec_vehicleBuyingStation
	local v45_ = v_u_44_.storeItems[storeItemIndex]
	if v45_ == nil then
		callback()
	end
	local v46_ = v45_.storeItem
	local v47_ = BuyVehicleData.new()
	v47_:setStoreItem(v46_)
	v47_:setOwnerFarmId(farmId)
	v47_:setPrice(v45_.price + v45_.transportCosts)
	if v47_:isValid() then
		if v47_.price > g_currentMission:getMoney(farmId) then
			callback(PlaceableVehicleBuyingStationEvent.STATE_NOT_ENOUGH_MONEY)
		else
			v47_:buy(v_u_44_.spawnPlaces, v_u_44_.usedPlaces, function(_, _, p48_, _)
				-- upvalues: (copy) v_u_44_, (copy) callback
				for v49_ in pairs(v_u_44_.usedPlaces) do
					v_u_44_.usedPlaces[v49_] = nil
				end
				if p48_ == VehicleLoadingState.OK then
					callback(PlaceableVehicleBuyingStationEvent.STATE_SUCCESS)
				else
					callback(PlaceableVehicleBuyingStationEvent.STATE_FAILED_TO_LOAD)
				end
			end, nil, nil)
		end
	else
		callback(PlaceableVehicleBuyingStationEvent.STATE_FAILED_TO_LOAD)
		return
	end
end
