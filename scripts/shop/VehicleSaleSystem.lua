VehicleSaleSystem = {}
VehicleSaleSystem.MINIMUM_ITEM_VALUE = 10000
VehicleSaleSystem.MAX_MULTIPLAYER_ITEMS = 20
VehicleSaleSystem.MIN_MULTIPLAYER_ITEM_DURATION = 20
VehicleSaleSystem.MAX_MULTIPLAYER_ITEM_DURATION = 40
VehicleSaleSystem.MULTIPLAYER_ACCEPT_CHANCE = 0.8
VehicleSaleSystem.MAX_GENERATED_ITEMS = 5
VehicleSaleSystem.MIN_GENERATED_ITEM_DURATION = 20
VehicleSaleSystem.MAX_GENERATED_ITEM_DURATION = 40
VehicleSaleSystem.GENERATED_HOURLY_CHANCE = 3 / VehicleSaleSystem.MIN_GENERATED_ITEM_DURATION
VehicleSaleSystem.BUYPRICE_FACTOR = 1.1
local VehicleSaleSystem_mt = Class(VehicleSaleSystem)
function VehicleSaleSystem.new(mission)
	local self = setmetatable({}, VehicleSaleSystem_mt)
	self.mission = mission
	self.items = {}
	self.numGeneratedItems = 0
	self.numMultiplayerItems = 0
	self.isEnabled = Platform.gameplay.hasVehicleSales
	self.nextFreeId = 1
	self.freeIds = {}
	g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.onHourChanged, self)
	return self
end
function VehicleSaleSystem:delete(customMt)
	g_messageCenter:unsubscribeAll(self)
end
function VehicleSaleSystem:loadFromXMLFile(xmlFilename)
	if not self.isEnabled then
		return true
	end
	local xmlFile = XMLFile.loadIfExists("vehicleSaleXML", xmlFilename)
	if xmlFile == nil then
		self:generateInitialSales()
		return false
	else
		xmlFile:iterate("sales.item", function(_, key)
			local item = {}
			item.id = #self.items + 1
			item.timeLeft = xmlFile:getInt(key .. "#timeLeft")
			item.isGenerated = xmlFile:getBool(key .. "#isGenerated")
			item.xmlFilename = xmlFile:getString(key .. "#xmlFilename")
			item.boughtConfigurations = {}
			item.age = xmlFile:getInt(key .. "#age")
			item.price = xmlFile:getInt(key .. "#price")
			item.damage = xmlFile:getFloat(key .. "#damage")
			item.wear = xmlFile:getFloat(key .. "#wear")
			item.operatingTime = xmlFile:getFloat(key .. "#operatingTime") * 1000
			item.configSetIndex = xmlFile:getInt(key .. "#configSetIndex")
			local storeItem = g_storeManager:getItemByXMLFilename(item.xmlFilename)
			if storeItem == nil then
				Logging.xmlWarning(xmlFile, "Store item for sale item '%s' could not be found, ignoring this item", item.xmlFilename)
			else
				xmlFile:iterate(key .. ".boughtConfiguration", function(_, cKey)
					local name = xmlFile:getString(cKey .. "#name")
					local value = xmlFile:getString(cKey .. "#id")
					if storeItem.configurations[name] == nil then
						return
					else
						local id = nil
						for _, config in ipairs(storeItem.configurations[name]) do
							if config.saveId == value then
								id = config.index
								break
							end
						end
						if id ~= nil then
							if item.boughtConfigurations[name] == nil then
								item.boughtConfigurations[name] = {}
							end
							item.boughtConfigurations[name][id] = true
						end
					end
				end)
				if item.isGenerated then
					self.numGeneratedItems = self.numGeneratedItems + 1
				else
					self.numMultiplayerItems = self.numMultiplayerItems + 1
				end
				table.insert(self.items, item)
			end
		end)
		self.nextFreeId = #self.items + 1
		xmlFile:delete()
		return true
	end
end
function VehicleSaleSystem:saveToXMLFile(xmlFilename)
	if not self.isEnabled then
		return
	end
	local xmlFile = XMLFile.create("vehicleSaleXML", xmlFilename, "sales")
	if xmlFile == nil then
		return
	else
		xmlFile:setSortedTable("sales.item", self.items, function(key, item, _)
			xmlFile:setInt(key .. "#timeLeft", item.timeLeft)
			xmlFile:setBool(key .. "#isGenerated", item.isGenerated)
			xmlFile:setString(key .. "#xmlFilename", item.xmlFilename)
			xmlFile:setInt(key .. "#age", item.age)
			xmlFile:setInt(key .. "#price", item.price)
			xmlFile:setFloat(key .. "#damage", item.damage)
			xmlFile:setFloat(key .. "#wear", item.wear)
			xmlFile:setFloat(key .. "#operatingTime", item.operatingTime / 1000)
			if item.configSetIndex ~= nil then
				xmlFile:setInt(key .. "#configSetIndex", item.configSetIndex)
			end
			local storeItem = g_storeManager:getItemByXMLFilename(item.xmlFilename)
			local i = 0
			for name, ids in pairs(item.boughtConfigurations) do
				for id, _ in pairs(ids) do
					if storeItem.configurations[name] ~= nil then
						if storeItem.configurations[name][id] ~= nil then
							local cKey = string.format("%s.boughtConfiguration(%d)", key, i)
							xmlFile:setString(cKey .. "#name", name)
							xmlFile:setString(cKey .. "#id", tostring(storeItem.configurations[name][id].saveId))
							i = i + 1
						else
							Logging.warning("Configuration '%s' on %s has invalid id %s (is bought but does not exist)", name, storeItem.xmlFilename, id)
						end
					end
				end
			end
		end)
		xmlFile:save()
		xmlFile:delete()
		return true
	end
end
function VehicleSaleSystem:sendAllToClient(connection)
	for i = 1, #self.items do
		connection:sendEvent(VehicleSaleAddEvent.new(self.items[i]))
	end
end
function VehicleSaleSystem:generateInitialSales()
	for i = 1, VehicleSaleSystem.MAX_GENERATED_ITEMS - 1 do
		local randomVehicle = self:generateRandomVehicle()
		if randomVehicle == nil then
			continue
		end
		self:addSale(randomVehicle)
	end
end
function VehicleSaleSystem:getItems()
	return self.items
end
function VehicleSaleSystem:getSaleById(id)
	for _, item in ipairs(self.items) do
		if item.id == id then
			return item
		end
	end
	return nil
end
function VehicleSaleSystem:getFreeId()
	if 0 < #self.freeIds then
		return table.remove(self.freeIds)
	else
		local id = self.nextFreeId
		self.nextFreeId = self.nextFreeId + 1
		return id
	end
end
function VehicleSaleSystem:onHourChanged()
	if not self.isEnabled or not self.mission:getIsServer() then
		return
	end
	if self.numGeneratedItems < VehicleSaleSystem.MAX_GENERATED_ITEMS and math.random() < VehicleSaleSystem.GENERATED_HOURLY_CHANCE then
		local randomVehicle = self:generateRandomVehicle()
		if randomVehicle ~= nil then
			self:addSale(randomVehicle)
		end
	end
	for i = #self.items, 1, -1 do
		local item = self.items[i]
		item.timeLeft = item.timeLeft - 1
		local storeItem = g_storeManager:getItemByXMLFilename(item.xmlFilename)
		if item.timeLeft <= 0 or storeItem == nil then
			self:removeSale(item, i)
		end
	end
end
function VehicleSaleSystem:addSale(item, noEventSend)
	table.insert(self.items, item)
	if self.isEnabled and self.mission:getIsServer() then
		item.id = self:getFreeId()
		if item.isGenerated then
			self.numGeneratedItems = self.numGeneratedItems + 1
		else
			self.numMultiplayerItems = self.numMultiplayerItems + 1
		end
		if not noEventSend then
			g_server:broadcastEvent(VehicleSaleAddEvent.new(item))
		end
	end
	g_messageCenter:publish(MessageType.VEHICLE_SALES_CHANGED)
end
function VehicleSaleSystem:removeSale(item, index, noEventSend)
	if item == nil then
		return
	end
	if index == nil then
		for i, it in ipairs(self.items) do
			if item == it then
				index = i
				break
			end
		end
	end
	if index == nil then
		return
	else
		table.remove(self.items, index)
		if self.mission:getIsServer() then
			self.freeIds[#self.freeIds + 1] = item.id
			if item.isGenerated then
				self.numGeneratedItems = self.numGeneratedItems - 1
			else
				self.numMultiplayerItems = self.numMultiplayerItems - 1
			end
			if not noEventSend then
				g_server:broadcastEvent(VehicleSaleRemoveEvent.new(item.id))
			end
		end
		g_messageCenter:publish(MessageType.VEHICLE_SALES_CHANGED)
	end
end
function VehicleSaleSystem:removeSaleWithId(saleItemId)
	for i = 1, #self.items do
		if self.items[i].id == saleItemId then
			table.remove(self.items, i)
			break
		end
	end
	g_messageCenter:publish(MessageType.VEHICLE_SALES_CHANGED)
end
function VehicleSaleSystem:generateRandomVehicle()
	local items = g_storeManager:getItems()
	local storeItem = nil
	for try = 1, #items do
		local index = math.random(1, #items)
		local item = items[index]
		if StoreItemUtil.getIsVehicle(item) and (item.showInStore and (VehicleSaleSystem.MINIMUM_ITEM_VALUE <= item.price and item.extraContentId == nil)) then
			storeItem = item
			break
		end
	end
	if storeItem == nil then
		return nil
	else
		StoreItemUtil.loadSpecsFromXML(storeItem)
		local boughtConfigurations = {}
		if storeItem.configurations ~= nil then
			for name, configItems in pairs(storeItem.configurations) do
				if 1 < #configItems then
					local includedInSet = false
					for _, configSet in ipairs(storeItem.configurationSets) do
						if configSet.configurations[name] ~= nil then
							includedInSet = true
							break
						end
					end
					if includedInSet then
						continue
					end
					if math.random() < 0.15 then
						local defaultIndex = ConfigurationUtil.getDefaultConfigIdFromItems(configItems)
						for attempt = 1, 5 do
							local index = math.random(1, #configItems)
							if index ~= defaultIndex and configItems[index].isSelectable then
								boughtConfigurations[name] = {}
								boughtConfigurations[name][index] = true
								break
							end
						end
					end
				end
			end
		end
		local configSetIndex = nil
		local numConfigSets = #storeItem.configurationSets
		if 0 < numConfigSets and math.random() < 0.15 then
			local defaultIndex = 1
			for index, configSet in ipairs(storeItem.configurationSets) do
				if configSet.isDefault then
					defaultIndex = index
				end
			end
			for attempt = 1, 5 do
				local index = math.random(1, numConfigSets)
				if index ~= defaultIndex then
					configSetIndex = index
					break
				end
			end
		end
		local age = math.random(6, 40)
		local damage = math.random() * 0.4 + 0.2
		local wear = math.random() * 0.8 + 0.2
		local operatingTime = age * (math.random() * 0.8 + 0.5) * 60 * 60 * 1000
		local defaultPrice = StoreItemUtil.getDefaultPrice(storeItem, boughtConfigurations)
		local repairPrice = Wearable.calculateRepairPrice(defaultPrice, damage)
		local repaintPrice = Wearable.calculateRepaintPrice(defaultPrice, wear)
		local price = Vehicle.calculateSellPrice(storeItem, age, operatingTime, defaultPrice, repairPrice, repaintPrice)
		return { boughtConfigurations = boughtConfigurations, configSetIndex = configSetIndex, age = age, price = price, damage = damage, wear = wear, operatingTime = operatingTime, timeLeft = math.random(VehicleSaleSystem.MIN_GENERATED_ITEM_DURATION, VehicleSaleSystem.MAX_GENERATED_ITEM_DURATION), isGenerated = true, xmlFilename = storeItem.xmlFilename }
	end
end
function VehicleSaleSystem:onVehicleWillSell(vehicle)
	if not self.isEnabled then
		return
	end
	if not self.mission.missionDynamicInfo.isMultiplayer then
		return
	end
	if VehicleSaleSystem.MAX_MULTIPLAYER_ITEMS <= self.numMultiplayerItems then
		return
	end
	if VehicleSaleSystem.MULTIPLAYER_ACCEPT_CHANCE <= math.random() then
		return
	end
	local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
	if storeItem.price < VehicleSaleSystem.MINIMUM_ITEM_VALUE then
		return
	elseif not (vehicle.getCanBeAddedToSales ~= nil and not vehicle:getCanBeAddedToSales()) then
		local item = {}
		item.timeLeft = math.random(VehicleSaleSystem.MIN_MULTIPLAYER_ITEM_DURATION, VehicleSaleSystem.MAX_MULTIPLAYER_ITEM_DURATION)
		item.isGenerated = false
		item.xmlFilename = vehicle.configFileName
		item.boughtConfigurations = table.clone(vehicle.boughtConfigurations, 3)
		item.age = vehicle.age
		item.price = vehicle:getSellPrice() * VehicleSaleSystem.BUYPRICE_FACTOR
		item.damage = 0
		item.wear = 0
		item.operatingTime = vehicle.operatingTime
		if vehicle.getDamageAmount ~= nil then
			item.damage = vehicle:getDamageAmount()
		end
		if vehicle.getWearTotalAmount ~= nil then
			item.wear = vehicle:getWearTotalAmount()
		end
		self:addSale(item)
	end
end
function VehicleSaleSystem:onVehicleBought(saleItem)
	self:removeSale(saleItem)
end
function VehicleSaleSystem.consoleCommandRefresh(_, amount)
	if g_currentMission ~= nil then
		local self = g_currentMission.vehicleSaleSystem
		if self ~= nil then
			for i = #self.items, 1, -1 do
				self:removeSale(self.items[i])
			end
			for i = 1, amount or VehicleSaleSystem.MAX_GENERATED_ITEMS do
				local randomVehicle = self:generateRandomVehicle()
				if randomVehicle == nil then
					continue
				end
				self:addSale(randomVehicle)
				Logging.info("Generate Sale Item: %s age: %.1f price: %d damage: %.2f wear: %.2f", randomVehicle.xmlFilename, randomVehicle.age, randomVehicle.price, randomVehicle.damage, randomVehicle.wear)
				for name, configurations in pairs(randomVehicle.boughtConfigurations) do
					for id, _ in pairs(configurations) do
						Logging.info("    Configuration: %s index %d", name, id)
					end
				end
				if randomVehicle.configSetIndex == nil then
					continue
				end
				Logging.info("    ConfigurationSet: %d", randomVehicle.configSetIndex)
			end
		end
	end
end
addConsoleCommand("gsVehicleSaleSystemRefresh", "Generate new set of sale items", "consoleCommandRefresh", VehicleSaleSystem)
