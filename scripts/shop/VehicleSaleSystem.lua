-- Local values: VehicleSaleSystem_mt
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

-- Upvalues: VehicleSaleSystem_mt
-- Local values: self
function VehicleSaleSystem.new(mission)
	-- upvalues: (copy) VehicleSaleSystem_mt
	local v3_ = VehicleSaleSystem_mt
	local v4_ = setmetatable({}, v3_)
	v4_.mission = mission
	v4_.items = {}
	v4_.numGeneratedItems = 0
	v4_.numMultiplayerItems = 0
	v4_.isEnabled = Platform.gameplay.hasVehicleSales
	v4_.nextFreeId = 1
	v4_.freeIds = {}
	g_messageCenter:subscribe(MessageType.HOUR_CHANGED, v4_.onHourChanged, v4_)
	return v4_
end

function VehicleSaleSystem:delete(customMt)
	g_messageCenter:unsubscribeAll(self)
end

-- Local values: xmlFile
function VehicleSaleSystem:loadFromXMLFile(xmlFilename)
	if not self.isEnabled then
		return true
	end
	local v_u_8_ = XMLFile.loadIfExists("vehicleSaleXML", xmlFilename)
	if v_u_8_ == nil then
		self:generateInitialSales()
		return false
	end
	v_u_8_:iterate("sales.item", function(_, p9_)
		-- upvalues: (copy) self, (copy) v_u_8_
		local v_u_10_ = {
			["id"] = #self.items + 1,
			["timeLeft"] = v_u_8_:getInt(p9_ .. "#timeLeft"),
			["isGenerated"] = v_u_8_:getBool(p9_ .. "#isGenerated"),
			["xmlFilename"] = v_u_8_:getString(p9_ .. "#xmlFilename"),
			["boughtConfigurations"] = {},
			["age"] = v_u_8_:getInt(p9_ .. "#age"),
			["price"] = v_u_8_:getInt(p9_ .. "#price"),
			["damage"] = v_u_8_:getFloat(p9_ .. "#damage"),
			["wear"] = v_u_8_:getFloat(p9_ .. "#wear"),
			["operatingTime"] = v_u_8_:getFloat(p9_ .. "#operatingTime") * 1000,
			["configSetIndex"] = v_u_8_:getInt(p9_ .. "#configSetIndex")
		}
		local v_u_11_ = g_storeManager:getItemByXMLFilename(v_u_10_.xmlFilename)
		if v_u_11_ == nil then
			Logging.xmlWarning(v_u_8_, "Store item for sale item \'%s\' could not be found, ignoring this item", v_u_10_.xmlFilename)
		else
			v_u_8_:iterate(p9_ .. ".boughtConfiguration", function(_, p12_)
				-- upvalues: (ref) v_u_8_, (copy) v_u_11_, (copy) v_u_10_
				local v13_ = v_u_8_:getString(p12_ .. "#name")
				local v14_ = v_u_8_:getString(p12_ .. "#id")
				if v_u_11_.configurations[v13_] == nil then
					return
				end
				local v15_ = nil
				for _, v16_ in ipairs(v_u_11_.configurations[v13_]) do
					if v16_.saveId == v14_ then
						v15_ = v16_.index
						break
					end
				end
				if v15_ ~= nil then
					if v_u_10_.boughtConfigurations[v13_] == nil then
						v_u_10_.boughtConfigurations[v13_] = {}
					end
					v_u_10_.boughtConfigurations[v13_][v15_] = true
				end
			end)
			if v_u_10_.isGenerated then
				self.numGeneratedItems = self.numGeneratedItems + 1
			else
				self.numMultiplayerItems = self.numMultiplayerItems + 1
			end
			local v17_ = self.items
			table.insert(v17_, v_u_10_)
		end
	end)
	self.nextFreeId = #self.items + 1
	v_u_8_:delete()
	return true
end

-- Local values: xmlFile
function VehicleSaleSystem:saveToXMLFile(xmlFilename)
	if self.isEnabled then
		local v_u_20_ = XMLFile.create("vehicleSaleXML", xmlFilename, "sales")
		if v_u_20_ ~= nil then
			v_u_20_:setSortedTable("sales.item", self.items, function(p21_, p22_, _)
				-- upvalues: (copy) v_u_20_
				v_u_20_:setInt(p21_ .. "#timeLeft", p22_.timeLeft)
				v_u_20_:setBool(p21_ .. "#isGenerated", p22_.isGenerated)
				v_u_20_:setString(p21_ .. "#xmlFilename", p22_.xmlFilename)
				v_u_20_:setInt(p21_ .. "#age", p22_.age)
				v_u_20_:setInt(p21_ .. "#price", p22_.price)
				v_u_20_:setFloat(p21_ .. "#damage", p22_.damage)
				v_u_20_:setFloat(p21_ .. "#wear", p22_.wear)
				v_u_20_:setFloat(p21_ .. "#operatingTime", p22_.operatingTime / 1000)
				if p22_.configSetIndex ~= nil then
					v_u_20_:setInt(p21_ .. "#configSetIndex", p22_.configSetIndex)
				end
				local v23_ = g_storeManager:getItemByXMLFilename(p22_.xmlFilename)
				local v24_ = 0
				for v25_, v26_ in pairs(p22_.boughtConfigurations) do
					for v27_, _ in pairs(v26_) do
						if v23_.configurations[v25_] == nil or v23_.configurations[v25_][v27_] == nil then
							Logging.warning("Configuration \'%s\' on %s has invalid id %s (is bought but does not exist)", v25_, v23_.xmlFilename, v27_)
						else
							local v28_ = string.format("%s.boughtConfiguration(%d)", p21_, v24_)
							v_u_20_:setString(v28_ .. "#name", v25_)
							local v29_ = v_u_20_
							local v30_ = v28_ .. "#id"
							local v31_ = v23_.configurations[v25_][v27_].saveId
							v29_:setString(v30_, (tostring(v31_)))
							v24_ = v24_ + 1
						end
					end
				end
			end)
			v_u_20_:save()
			v_u_20_:delete()
			return true
		end
	end
end

-- Local values: i
function VehicleSaleSystem:sendAllToClient(connection)
	for v34_ = 1, #self.items do
		connection:sendEvent(VehicleSaleAddEvent.new(self.items[v34_]))
	end
end

-- Local values: i, randomVehicle
function VehicleSaleSystem:generateInitialSales()
	for _ = 1, VehicleSaleSystem.MAX_GENERATED_ITEMS - 1 do
		local v36_ = self:generateRandomVehicle()
		if v36_ ~= nil then
			self:addSale(v36_)
		end
	end
end

function VehicleSaleSystem:getItems()
	return self.items
end

-- Local values: _, item
function VehicleSaleSystem:getSaleById(id)
	for _, v40_ in ipairs(self.items) do
		if v40_.id == id then
			return v40_
		end
	end
	return nil
end

-- Local values: id
function VehicleSaleSystem:getFreeId()
	if #self.freeIds > 0 then
		return table.remove(self.freeIds)
	end
	local v42_ = self.nextFreeId
	self.nextFreeId = self.nextFreeId + 1
	return v42_
end

-- Local values: randomVehicle, i, item, storeItem
function VehicleSaleSystem:onHourChanged()
	if self.isEnabled and self.mission:getIsServer() then
		if self.numGeneratedItems < VehicleSaleSystem.MAX_GENERATED_ITEMS and math.random() < VehicleSaleSystem.GENERATED_HOURLY_CHANCE then
			local v44_ = self:generateRandomVehicle()
			if v44_ ~= nil then
				self:addSale(v44_)
			end
		end
		for v45_ = #self.items, 1, -1 do
			local v46_ = self.items[v45_]
			v46_.timeLeft = v46_.timeLeft - 1
			local v47_ = g_storeManager:getItemByXMLFilename(v46_.xmlFilename)
			if v46_.timeLeft <= 0 or v47_ == nil then
				self:removeSale(v46_, v45_)
			end
		end
	end
end

function VehicleSaleSystem:addSale(item, noEventSend)
	local v51_ = self.items
	table.insert(v51_, item)
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

-- Local values: i, it
function VehicleSaleSystem:removeSale(item, index, noEventSend)
	if item == nil then
		return
	end
	if index == nil then
		for v56_, v57_ in ipairs(self.items) do
			if item == v57_ then
				index = v56_
				break
			end
		end
	end
	if index ~= nil then
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

-- Local values: i
function VehicleSaleSystem:removeSaleWithId(saleItemId)
	for v60_ = 1, #self.items do
		if self.items[v60_].id == saleItemId then
			table.remove(self.items, v60_)
			break
		end
	end
	g_messageCenter:publish(MessageType.VEHICLE_SALES_CHANGED)
end

-- Local values: items, storeItem, try, index, item, boughtConfigurations, name, configItems, includedInSet, _, configSet, defaultIndex, attempt, index, configSetIndex, numConfigSets, defaultIndex, index, configSet, attempt, index, age, damage, wear, operatingTime, defaultPrice, repairPrice, repaintPrice, price
function VehicleSaleSystem:generateRandomVehicle()
	local v61_ = g_storeManager:getItems()
	local v62_ = nil
	for _ = 1, #v61_ do
		local v63_ = v61_[math.random(1, #v61_)]
		if StoreItemUtil.getIsVehicle(v63_) and (v63_.showInStore and (v63_.price >= VehicleSaleSystem.MINIMUM_ITEM_VALUE and v63_.extraContentId == nil)) then
			v62_ = v63_
			break
		end
	end
	if v62_ == nil then
		return nil
	end
	StoreItemUtil.loadSpecsFromXML(v62_)
	local v64_ = {}
	if v62_.configurations ~= nil then
		for v65_, v66_ in pairs(v62_.configurations) do
			if #v66_ > 1 then
				local v67_ = false
				for _, v68_ in ipairs(v62_.configurationSets) do
					if v68_.configurations[v65_] ~= nil then
						v67_ = true
						break
					end
				end
				if not v67_ and math.random() < 0.15 then
					local v69_ = ConfigurationUtil.getDefaultConfigIdFromItems(v66_)
					for _ = 1, 5 do
						local v70_ = math.random(1, #v66_)
						if v70_ ~= v69_ and v66_[v70_].isSelectable then
							v64_[v65_] = {}
							v64_[v65_][v70_] = true
							break
						end
					end
				end
			end
		end
	end
	local v71_ = nil
	local v72_ = #v62_.configurationSets
	if v72_ > 0 and math.random() < 0.15 then
		local v73_ = 1
		for v74_, v75_ in ipairs(v62_.configurationSets) do
			if v75_.isDefault then
				v73_ = v74_
			end
		end
		for _ = 1, 5 do
			local v76_ = math.random(1, v72_)
			if v76_ ~= v73_ then
				v71_ = v76_
				break
			end
		end
	end
	local v77_ = math.random(6, 40)
	local v78_ = math.random() * 0.4 + 0.2
	local v79_ = math.random() * 0.8 + 0.2
	local v80_ = v77_ * (math.random() * 0.8 + 0.5) * 60 * 60 * 1000
	local v81_ = StoreItemUtil.getDefaultPrice(v62_, v64_)
	local v82_ = Wearable.calculateRepairPrice(v81_, v78_)
	local v83_ = Wearable.calculateRepaintPrice(v81_, v79_)
	local v84_ = Vehicle.calculateSellPrice(v62_, v77_, v80_, v81_, v82_, v83_)
	return {
		["timeLeft"] = math.random(VehicleSaleSystem.MIN_GENERATED_ITEM_DURATION, VehicleSaleSystem.MAX_GENERATED_ITEM_DURATION),
		["isGenerated"] = true,
		["xmlFilename"] = v62_.xmlFilename,
		["boughtConfigurations"] = v64_,
		["configSetIndex"] = v71_,
		["age"] = v77_,
		["price"] = v84_,
		["damage"] = v78_,
		["wear"] = v79_,
		["operatingTime"] = v80_
	}
end

-- Local values: storeItem, item
function VehicleSaleSystem:onVehicleWillSell(vehicle)
	if self.isEnabled then
		if self.mission.missionDynamicInfo.isMultiplayer then
			if self.numMultiplayerItems >= VehicleSaleSystem.MAX_MULTIPLAYER_ITEMS then
				return
			elseif math.random() >= VehicleSaleSystem.MULTIPLAYER_ACCEPT_CHANCE then
				return
			elseif g_storeManager:getItemByXMLFilename(vehicle.configFileName).price < VehicleSaleSystem.MINIMUM_ITEM_VALUE then
				return
			elseif vehicle.getCanBeAddedToSales == nil or vehicle:getCanBeAddedToSales() then
				local v87_ = {
					["timeLeft"] = math.random(VehicleSaleSystem.MIN_MULTIPLAYER_ITEM_DURATION, VehicleSaleSystem.MAX_MULTIPLAYER_ITEM_DURATION),
					["isGenerated"] = false,
					["xmlFilename"] = vehicle.configFileName,
					["boughtConfigurations"] = table.clone(vehicle.boughtConfigurations, 3),
					["age"] = vehicle.age,
					["price"] = vehicle:getSellPrice() * VehicleSaleSystem.BUYPRICE_FACTOR,
					["damage"] = 0,
					["wear"] = 0,
					["operatingTime"] = vehicle.operatingTime
				}
				if vehicle.getDamageAmount ~= nil then
					v87_.damage = vehicle:getDamageAmount()
				end
				if vehicle.getWearTotalAmount ~= nil then
					v87_.wear = vehicle:getWearTotalAmount()
				end
				self:addSale(v87_)
			end
		else
			return
		end
	else
		return
	end
end

function VehicleSaleSystem:onVehicleBought(saleItem)
	self:removeSale(saleItem)
end

-- Local values: self, i, i, randomVehicle, name, configurations, id, _
function VehicleSaleSystem.consoleCommandRefresh(_, amount)
	if g_currentMission ~= nil then
		local v91_ = g_currentMission.vehicleSaleSystem
		if v91_ ~= nil then
			for v92_ = #v91_.items, 1, -1 do
				v91_:removeSale(v91_.items[v92_])
			end
			for _ = 1, amount or VehicleSaleSystem.MAX_GENERATED_ITEMS do
				local v93_ = v91_:generateRandomVehicle()
				if v93_ ~= nil then
					v91_:addSale(v93_)
					Logging.info("Generate Sale Item: %s age: %.1f price: %d damage: %.2f wear: %.2f", v93_.xmlFilename, v93_.age, v93_.price, v93_.damage, v93_.wear)
					for v94_, v95_ in pairs(v93_.boughtConfigurations) do
						for v96_, _ in pairs(v95_) do
							Logging.info("    Configuration: %s index %d", v94_, v96_)
						end
					end
					if v93_.configSetIndex ~= nil then
						Logging.info("    ConfigurationSet: %d", v93_.configSetIndex)
					end
				end
			end
		end
	end
end
addConsoleCommand("gsVehicleSaleSystemRefresh", "Generate new set of sale items", "consoleCommandRefresh", VehicleSaleSystem)
