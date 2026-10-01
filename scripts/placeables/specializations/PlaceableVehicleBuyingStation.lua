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
function PlaceableVehicleBuyingStation:onLoad(savegame)
	local spec = self.spec_vehicleBuyingStation
	local key = "placeable.vehicleBuyingStation"
	spec.triggerNode = self.xmlFile:getNode("placeable.vehicleBuyingStation" .. ".trigger#node", nil, self.components, self.i3dMappings)
	if spec.triggerNode == nil then
		Logging.xmlError(self.xmlFile, "Missing triggerNode for vehicle buying station %s", "placeable.vehicleBuyingStation")
		return
	end
	addTrigger(spec.triggerNode, "onVehicleBuyingStationTriggerCallback", self)
	spec.storeItems = {}
	for _, storeItemKey in self.xmlFile:iterator("placeable.vehicleBuyingStation" .. ".storeItem") do
		local xmlFilename = self.xmlFile:getString(storeItemKey .. "#xmlFilename")
		if string.isNilOrWhitespace(xmlFilename) then
			Logging.xmlError(self.xmlFile, "xmlFilename missing for vehicle buying station %s", storeItemKey)
		else
			local filename = Utils.getFilename(xmlFilename, self.baseDirectory)
			local storeItem = g_storeManager:getItemByXMLFilename(filename)
			if storeItem == nil then
				Logging.xmlError(self.xmlFile, "Could not find storeitem for xmlFilename '%s'", filename)
			else
				local imageFilename = storeItem.imageFilename
				local price = self.xmlFile:getInt(storeItemKey .. "#price", storeItem.price)
				local transportCosts = self.xmlFile:getInt(storeItemKey .. "#transportCosts", 15000)
				local data = { storeItem = storeItem, price = price, imageFilename = imageFilename, transportCosts = transportCosts }
				data.title = storeItem.name
				table.addElement(spec.storeItems, data)
			end
		end
	end
	spec.sendNumBits = MathUtil.getNumRequiredBits(#spec.storeItems)
	spec.usedPlaces = {}
	spec.spawnPlaces = {}
	for _, spawnPlaceKey in self.xmlFile:iterator("placeable.vehicleBuyingStation" .. ".spawnPlaces.spawnPlace") do
		local spawnPlace = PlacementUtil.loadPlaceFromXML(self.xmlFile, spawnPlaceKey, self.components, self.i3dMappings)
		table.insert(spec.spawnPlaces, spawnPlace)
	end
	if #spec.spawnPlaces == 0 then
		Logging.xmlError(spec.xmlFile, "No spawn place(s) defined for vehicle buying station %s%s", "placeable.vehicleBuyingStation", ".spawnPlaces")
		return false
	else
		spec.vehicleBoughtMessage = self.xmlFile:getString("placeable.vehicleBuyingStation" .. ".message#bought")
		spec.vehicleBuyingFailedMessage = self.xmlFile:getString("placeable.vehicleBuyingStation" .. ".message#failed")
		spec.vehicleBuyingFailedNoSpaceMessage = self.xmlFile:getString("placeable.vehicleBuyingStation" .. ".message#noSpace")
		spec.vehicleBuyingFailedNoPermissionMessage = self.xmlFile:getString("placeable.vehicleBuyingStation" .. ".message#noPermission")
		spec.vehicleBuyingFailedNoMoneyMessage = self.xmlFile:getString("placeable.vehicleBuyingStation" .. ".message#noMoney")
		local title = g_i18n:convertText(self.xmlFile:getString("placeable.vehicleBuyingStation" .. "#title", "$l10n_ui_vehicleShopTitle"), self.customEnvironment)
		local description = g_i18n:convertText(self.xmlFile:getString("placeable.vehicleBuyingStation" .. "#description", "$l10n_ui_vehicleShopDescription"), self.customEnvironment)
		local text = g_i18n:convertText(self.xmlFile:getString("placeable.vehicleBuyingStation" .. ".trigger#text", "$l10n_vehicleShop_open"), self.customEnvironment)
		local callbackFunc = function()
			if g_currentMission:getHasPlayerPermission(Farm.PERMISSION.BUY_VEHICLE) then
				local spec = self.spec_vehicleBuyingStation
				VehicleShopDialog.show(PlaceableVehicleBuyingStation.vehicleShopCallback, self, spec.storeItems, title, description)
			else
				InfoDialog.show(g_i18n:getText("shop_messageNoPermissionGeneral"))
			end
		end
		spec.activatable = VehicleBuyingStationActivatable.new(self, callbackFunc, text)
		return true
	end
end
function PlaceableVehicleBuyingStation:onDelete()
	local spec = self.spec_vehicleBuyingStation
	if spec.triggerNode ~= nil then
		removeTrigger(spec.triggerNode)
	end
end
function PlaceableVehicleBuyingStation:onVehicleBuyingStationTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	local spec = self.spec_vehicleBuyingStation
	if (onEnter or onLeave) and (g_localPlayer and g_localPlayer.rootNode == otherId) then
		if onEnter then
			if Platform.isMobile and spec.activatable:getIsActivatable() then
				spec.activatable:run()
				return
			end
			g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
			return
		end
		if onLeave then
			g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
		end
	end
end
function PlaceableVehicleBuyingStation:vehicleShopCallback(selectedIndex)
	if selectedIndex == nil then
		return
	end
	local spec = self.spec_vehicleBuyingStation
	local data = spec.storeItems[selectedIndex]
	if data == nil then
		return
	end
	local totalPrice = data.price + data.transportCosts
	local enoughMoney = 0 >= totalPrice or totalPrice <= g_currentMission:getMoney()
	if not enoughMoney then
		InfoDialog.show(g_i18n:getText("shop_messageNotEnoughMoneyToBuy"), nil, nil, DialogElement.TYPE_WARNING)
		return
	end
	local storeItem = data.storeItem
	local enoughSlots = g_currentMission.slotSystem:hasEnoughSlots(storeItem)
	if not enoughSlots then
		InfoDialog.show(g_i18n:getText("shop_messageNotEnoughSlotsToBuy"), nil, nil, DialogElement.TYPE_WARNING)
	else
		local text = string.namedFormat(g_i18n:getText("shop_doYouWantToBuyVehicle"), "price", g_i18n:formatMoney(totalPrice, 0, true, true))
		local callback = function(yes)
			if yes then
				MessageDialog.show(g_i18n:getText("shop_buyingVehicle"))
				g_client:getServerConnection():sendEvent(PlaceableVehicleBuyingStationEvent.new(self, g_localPlayer.farmId, selectedIndex))
				g_messageCenter:subscribeOneshot(PlaceableVehicleBuyingStationEvent, PlaceableVehicleBuyingStation.onVehicleBought, self)
			end
		end
		YesNoDialog.show(callback, nil, text)
	end
end
function PlaceableVehicleBuyingStation:onVehicleBought(errorCode)
	MessageDialog.hide()
	local spec = self.spec_vehicleBuyingStation
	if errorCode == PlaceableVehicleBuyingStationEvent.STATE_SUCCESS then
		InfoDialog.show(g_i18n:convertText(spec.vehicleBoughtMessage or "$l10n_shop_messageThanksForBuying", self.customEnvironment))
		g_currentMission:showMoneyChange(MoneyType.SHOP_VEHICLE_BUY)
	else
		local text = g_i18n:convertText(spec.vehicleBuyingFailedMessage or "$l10n_shop_messageFailedToLoadVehicle", self.customEnvironment)
		if errorCode == PlaceableVehicleBuyingStationEvent.STATE_NO_SPACE then
			text = g_i18n:convertText(spec.vehicleBuyingFailedNoSpaceMessage or "$l10n_shop_messageNoSpace", self.customEnvironment)
		elseif errorCode == PlaceableVehicleBuyingStationEvent.STATE_NO_PERMISSION then
			text = g_i18n:convertText(spec.vehicleBuyingFailedNoPermissionMessage or "$l10n_shop_messageNoPermissionToBuyVehicleText", self.customEnvironment)
		elseif errorCode == PlaceableVehicleBuyingStationEvent.STATE_NOT_ENOUGH_MONEY then
			text = g_i18n:convertText(spec.vehicleBuyingFailedNoMoneyMessage or "$l10n_shop_messageNotEnoughMoneyToBuy", self.customEnvironment)
		end
		InfoDialog.show(text, nil, nil, DialogElement.TYPE_WARNING)
	end
end
function PlaceableVehicleBuyingStation:buyVehicle(farmId, storeItemIndex, callback)
	local spec = self.spec_vehicleBuyingStation
	local data = spec.storeItems[storeItemIndex]
	if data == nil then
		callback()
	end
	local storeItem = data.storeItem
	local vehicleBuyData = BuyVehicleData.new()
	vehicleBuyData:setStoreItem(storeItem)
	vehicleBuyData:setOwnerFarmId(farmId)
	vehicleBuyData:setPrice(data.price + data.transportCosts)
	if not vehicleBuyData:isValid() then
		callback(PlaceableVehicleBuyingStationEvent.STATE_FAILED_TO_LOAD)
	elseif g_currentMission:getMoney(farmId) < vehicleBuyData.price then
		callback(PlaceableVehicleBuyingStationEvent.STATE_NOT_ENOUGH_MONEY)
	else
		local buyCallback = function(_, vehicles, loadingState, arguments)
			for k in pairs(spec.usedPlaces) do
				spec.usedPlaces[k] = nil
			end
			if loadingState == VehicleLoadingState.OK then
				callback(PlaceableVehicleBuyingStationEvent.STATE_SUCCESS)
			else
				callback(PlaceableVehicleBuyingStationEvent.STATE_FAILED_TO_LOAD)
			end
		end
		vehicleBuyData:buy(spec.spawnPlaces, spec.usedPlaces, buyCallback, nil, nil)
	end
end
