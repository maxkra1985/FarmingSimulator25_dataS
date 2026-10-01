VehicleLoadingData = {}
VehicleLoadingData.MIN_SPAWN_PLACE_WIDTH = 4
VehicleLoadingData.MIN_SPAWN_PLACE_LENGTH = 4
VehicleLoadingData.MIN_SPAWN_PLACE_HEIGHT = 3
VehicleLoadingData.SPAWN_WIDTH_OFFSET = 1
local VehicleLoadingData_mt = Class(VehicleLoadingData)
function VehicleLoadingData.new(customMt)
	local self = setmetatable({}, customMt or VehicleLoadingData_mt)
	self.isValid = false
	self.validLocation = true
	self.storeItem = nil
	self.vehicles = {}
	self.vehiclesToLoad = 0
	self.loadingVehicles = {}
	self.loadedVehicles = {}
	self.loadingState = nil
	self.savegameData = nil
	self.configurations = {}
	self.boughtConfigurations = {}
	self.configurationData = {}
	self.saleItem = nil
	self.propertyState = VehiclePropertyState.OWNED
	self.ownerFarmId = AccessHandler.EVERYONE
	self.isRegistered = true
	self.forceServer = false
	self.isSaved = true
	self.addToPhysics = true
	self.price = nil
	self.position = { 0, 0, 0 }
	self.rotation = { 0, 0, 0 }
	self.ignoreShopOffset = false
	self.centerVehicle = true
	self.customParameters = {}
	return self
end
function VehicleLoadingData:setFilename(filename)
	local storeItem = g_storeManager:getItemByXMLFilename(filename)
	if storeItem ~= nil then
		self:setStoreItem(storeItem)
	else
		Logging.error("Unable to find vehicle storeitem for '%s'", filename)
		printCallstack()
	end
end
function VehicleLoadingData:setStoreItem(storeItem)
	if storeItem ~= nil then
		self.storeItem = storeItem
		self.rotation[2] = storeItem.rotation
		self.vehicles = {}
		if self.storeItem.bundleInfo ~= nil then
			self.attacherInfo = self.storeItem.bundleInfo.attacherInfo
			for _, bundleItem in pairs(self.storeItem.bundleInfo.bundleItems) do
				table.insert(self.vehicles, { xmlFilename = bundleItem.xmlFilename, offset = bundleItem.offset, rotationOffset = bundleItem.rotationOffset })
			end
		else
			table.insert(self.vehicles, { xmlFilename = storeItem.xmlFilename })
		end
	end
	self.isValid = 0 < #self.vehicles
end
function VehicleLoadingData:setPropertyState(propertyState)
	self.propertyState = propertyState
end
function VehicleLoadingData:setOwnerFarmId(ownerFarmId)
	self.ownerFarmId = ownerFarmId
end
function VehicleLoadingData:setSaleItem(saleItem)
	self.saleItem = saleItem
	if saleItem ~= nil then
		for name, ids in pairs(saleItem.boughtConfigurations) do
			if self.boughtConfigurations[name] == nil then
				self.boughtConfigurations[name] = {}
			end
			for id, _ in pairs(ids) do
				self.boughtConfigurations[name][id] = true
			end
		end
	end
end
function VehicleLoadingData:setSavegameData(savegameData)
	self.savegameData = savegameData
	if self.storeItem ~= nil and (savegameData ~= nil and savegameData.xmlFile ~= nil) then
		self.configurations, self.boughtConfigurations, self.configurationData = ConfigurationUtil.loadConfigurationsFromXMLFile(self.storeItem.xmlFilename, savegameData.xmlFile, savegameData.key .. ".configuration")
		for _, key in savegameData.xmlFile:iterator(savegameData.key .. ".boughtConfiguration") do
			local name = savegameData.xmlFile:getValue(key .. "#name")
			local id = savegameData.xmlFile:getValue(key .. "#id")
			if name ~= nil then
				if id ~= nil then
					if self.boughtConfigurations[name] == nil then
						self.boughtConfigurations[name] = {}
					end
					local configIndex = ConfigurationUtil.getConfigIdBySaveId(self.storeItem.xmlFilename, name, id)
					if configIndex == nil then
						continue
					end
					self.boughtConfigurations[name][configIndex] = true
				else
					Logging.xmlWarning(savegameData.xmlFile, "Invalid bought configuration in '%s'!", savegameData.key)
				end
			end
		end
	end
end
function VehicleLoadingData:setConfigurations(configurations)
	if configurations ~= nil then
		self.configurations = configurations
	else
		self.configurations = {}
	end
end
function VehicleLoadingData:setBoughtConfigurations(boughtConfigurations)
	if boughtConfigurations ~= nil then
		self.boughtConfigurations = boughtConfigurations
	else
		self.boughtConfigurations = {}
	end
end
function VehicleLoadingData:setConfigurationData(configurationData)
	if configurationData ~= nil then
		self.configurationData = configurationData
	else
		self.configurationData = {}
	end
end
function VehicleLoadingData:getConfigurations(configFileName)
	local configurations = table.clone(self.configurations, math.huge)
	local boughtConfigurations = table.clone(self.boughtConfigurations, math.huge)
	local configurationData = table.clone(self.configurationData, math.huge)
	local storeItem = g_storeManager:getItemByXMLFilename(configFileName)
	if storeItem ~= nil and storeItem ~= self.storeItem then
		for configName, configId in pairs(configurations) do
			local isValid = true
			if storeItem.configurations == nil then
				isValid = false
			elseif storeItem.configurations[configName] == nil then
				isValid = false
			else
				local configItems = storeItem.configurations[configName]
				if configItems[configId] == nil then
					isValid = false
				end
			end
			if isValid then
				continue
			end
			configurations[configName] = nil
			boughtConfigurations[configName] = nil
		end
	end
	if storeItem ~= nil and storeItem.configurations ~= nil then
		for configName, configItems in pairs(storeItem.configurations) do
			local configIndex = configurations[configName]
			if configIndex == nil then
				configIndex = ConfigurationUtil.getDefaultConfigIdFromItems(configItems)
				configurations[configName] = configIndex
			end
			if configItems[configIndex] == nil then
				continue
			end
			local configItem = configItems[configIndex]
			if configItem.dependentConfigurations == nil then
				continue
			end
			for _, dependentConfig in ipairs(configItem.dependentConfigurations) do
				configurations[dependentConfig.name] = dependentConfig.index
			end
		end
	end
	return configurations, boughtConfigurations, configurationData
end
function VehicleLoadingData:setIsRegistered(isRegistered)
	self.isRegistered = isRegistered
end
function VehicleLoadingData:setForceServer(forceServer)
	self.forceServer = forceServer
end
function VehicleLoadingData:setIsSaved(isSaved)
	self.isSaved = isSaved
end
function VehicleLoadingData:setAddToPhysics(addToPhysics)
	self.addToPhysics = addToPhysics
end
function VehicleLoadingData:setCustomParameter(name, value)
	self.customParameters[name] = value
end
function VehicleLoadingData:getCustomParameter(name)
	return self.customParameters[name]
end
function VehicleLoadingData:setPosition(x, y, z, terrainOffset)
	if y == nil then
		y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + (terrainOffset or 0)
	end
	self.position[1] = x
	self.position[2] = y
	self.position[3] = z
end
function VehicleLoadingData:setRotation(rx, ry, rz)
	self.rotation[1] = rx
	self.rotation[2] = ry
	self.rotation[3] = rz
end
function VehicleLoadingData:setSpawnNode(node)
	self.position[1], self.position[2], self.position[3] = getWorldTranslation(node)
	self.rotation[1], self.rotation[2], self.rotation[3] = getWorldRotation(node)
end
function VehicleLoadingData:setIgnoreShopOffset(ignoreShopOffset)
	self.ignoreShopOffset = ignoreShopOffset
end
function VehicleLoadingData:setComponentPositionData(vehicle)
	self.componentPositionData = {}
	for i, component in ipairs(vehicle.components) do
		self.componentPositionData[i] = { translation = { getWorldTranslation(component.node) }, rotation = { getWorldRotation(component.node) } }
	end
end
function VehicleLoadingData:applyPositionData(vehicle)
	if not self.validLocation then
		return false
	elseif self.componentPositionData ~= nil then
		for i = 1, #vehicle.components do
			local data = self.componentPositionData[i]
			if data ~= nil then
				vehicle:setWorldPosition(data.translation[1], data.translation[2], data.translation[3], data.rotation[1], data.rotation[2], data.rotation[3], i, true)
			else
				vehicle:setDefaultComponentPosition(i)
			end
		end
		return true
	else
		if self.savegameData ~= nil then
			local savegame = self.savegameData
			if savegame.useNewPosition then
				return self:resetVehiclePosition(vehicle)
			end
			if savegame.resetVehicles and not savegame.keepPosition then
				return self:resetVehiclePosition(vehicle)
			end
			local componentPositions = {}
			for _componentIndex, componentKey in savegame.xmlFile:iterator(savegame.key .. ".component") do
				local componentIndex = savegame.xmlFile:getValue(componentKey .. "#index")
				local x, y, z = savegame.xmlFile:getValue(componentKey .. "#position")
				local xRot, yRot, zRot = savegame.xmlFile:getValue(componentKey .. "#rotation")
				if not MathUtil.getIsValidTransformationValue(x, y, z) or not MathUtil.getIsValidTransformationValue(xRot, yRot, zRot) then
					Logging.xmlWarning(savegame.xmlFile, "Invalid component position in '%s' (%s)!", savegame.key, vehicle.configFileName)
					return self:resetVehiclePosition(vehicle)
				end
				if componentPositions[componentIndex] ~= nil then
					Logging.xmlWarning(savegame.xmlFile, "Duplicate component index '%s' in '%s' (%s)!", componentIndex, savegame.key, vehicle.configFileName)
				else
					componentPositions[componentIndex] = { x = x, y = y, z = z, xRot = xRot, yRot = yRot, zRot = zRot }
				end
			end
			if next(componentPositions) == nil then
				return self:resetVehiclePosition(vehicle)
			else
				for i = 1, #vehicle.components do
					local position = componentPositions[i]
					if position ~= nil then
						vehicle:setWorldPosition(position.x, position.y, position.z, position.xRot, position.yRot, position.zRot, i, true)
					else
						vehicle:setDefaultComponentPosition(i)
					end
				end
				return true
			end
		end
		local x, y, z, rx, ry, rz = self:getPositionAndRotation(vehicle)
		vehicle:setAbsolutePosition(x, y, z, rx, ry, rz)
		return true
	end
end
function VehicleLoadingData:resetVehiclePosition(vehicle)
	local resetPlaces, usedPlaces = vehicle:getResetPlaces()
	if self:setLoadingPlace(resetPlaces, usedPlaces) then
		vehicle:setAbsolutePosition(self.position[1], self.position[2], self.position[3], self.rotation[1], self.rotation[2], self.rotation[3])
		return true
	else
		return false
	end
end
function VehicleLoadingData:getPositionAndRotation(vehicle)
	local offset = nil
	local rotationOffset = nil
	for index, loadingVehicle in ipairs(self.loadingVehicles) do
		if loadingVehicle == vehicle then
			offset = self.vehicles[index].offset
			rotationOffset = self.vehicles[index].rotationOffset
		end
	end
	if not self.ignoreShopOffset and self.storeItem ~= nil then
		for configName, configIndex in pairs(self.configurations) do
			local configItems = self.storeItem.configurations[configName]
			if configItems == nil then
				continue
			end
			local configItem = configItems[configIndex]
			if configItem == nil then
				continue
			end
			if configItem.shopTranslationOffset ~= nil and offset == nil then
				offset = configItem.shopTranslationOffset
			end
			if configItem.shopRotationOffset == nil then
				continue
			end
			if rotationOffset == nil then
				rotationOffset = configItem.shopRotationOffset
			end
		end
		local shopTransOffset = self.storeItem.shopTranslationOffset
		if shopTransOffset ~= nil and offset == nil then
			offset = shopTransOffset
		end
		local rotOffset = self.storeItem.shopRotationOffset
		if rotOffset ~= nil and rotationOffset == nil then
			rotationOffset = rotOffset
		end
	end
	local x = self.position[1]
	local y = self.position[2]
	local z = self.position[3]
	local rx = self.rotation[1]
	local ry = self.rotation[2]
	local rz = self.rotation[3]
	if offset ~= nil or rotationOffset ~= nil then
		local tempPositionNode = createTransformGroup("tempPositionNode")
		setWorldTranslation(tempPositionNode, x, y, z)
		setWorldRotation(tempPositionNode, rx, ry, rz)
		if offset ~= nil then
			local ox = offset[1]
			local oy = offset[2]
			local oz = offset[3]
			if self.centerVehicle then
				local size = StoreItemUtil.getSizeValues(self.storeItem.xmlFilename, "vehicle", self.storeItem.rotation, self.configurations)
				ox = ox - size.widthOffset
				oz = oz - size.lengthOffset
			end
			x, y, z = localToWorld(tempPositionNode, ox, oy, oz)
		end
		if rotationOffset ~= nil then
			rx, ry, rz = localRotationToWorld(tempPositionNode, rotationOffset[1], rotationOffset[2], rotationOffset[3])
		end
		delete(tempPositionNode)
	end
	return x, y, z, rx, ry, rz
end
function VehicleLoadingData:setLoadingPlace(places, usedPlaces, spawnOffset, ignoreMinSpawnItemSize)
	if self.storeItem ~= nil then
		local yRot = self.storeItem.rotation
		if self.storeItem.spawnRotationOffset ~= nil then
			yRot = yRot + self.storeItem.spawnRotationOffset[2]
		end
		local size = StoreItemUtil.getSizeValues(self.storeItem.xmlFilename, "vehicle", yRot, self.configurations)
		if ignoreMinSpawnItemSize ~= true then
			size.width = math.max(size.width, VehicleLoadingData.MIN_SPAWN_PLACE_WIDTH)
			size.length = math.max(size.length, VehicleLoadingData.MIN_SPAWN_PLACE_LENGTH)
			size.height = math.max(size.height, VehicleLoadingData.MIN_SPAWN_PLACE_HEIGHT)
			if self.storeItem.spawnSizeOffset ~= nil then
				size.width = size.width + self.storeItem.spawnSizeOffset[1]
				size.length = size.length + self.storeItem.spawnSizeOffset[2]
				size.height = size.height + self.storeItem.spawnSizeOffset[3]
			end
		end
		size.width = size.width + (spawnOffset or VehicleLoadingData.SPAWN_WIDTH_OFFSET)
		local x, y, z, place, width, _ = PlacementUtil.getPlace(places, size, usedPlaces, true, true, false, true)
		if x == nil then
			self.validLocation = false
			return false
		else
			PlacementUtil.markPlaceUsed(usedPlaces, place, width)
			self.position[1] = x
			self.position[2] = y
			self.position[3] = z
			self.rotation[2] = self.rotation[2] + MathUtil.getYRotationFromDirection(place.dirPerpX, place.dirPerpZ)
			if self.storeItem.spawnRotationOffset ~= nil then
				self.rotation[2] = self.rotation[2] + self.storeItem.spawnRotationOffset[2]
			end
			return true
		end
	end
	Logging.error("No store item set before VehicleLoadingData:setLoadingPlace call")
	printCallstack()
	return false
end
function VehicleLoadingData:load(callback, callbackTarget, callbackArguments)
	g_currentMission.vehicleSystem:addPendingVehicleLoad(self)
	self.callback = callback
	self.callbackTarget = callbackTarget
	self.callbackArguments = callbackArguments
	self.vehiclesToLoad = #self.vehicles
	self.loadingVehicles = {}
	self.loadedVehicles = {}
	self.loadingState = VehicleLoadingState.OK
	for _, vehicleData in ipairs(self.vehicles) do
		vehicleData.vehicleType, vehicleData.vehicleClass = g_vehicleTypeManager:getObjectTypeFromXML(vehicleData.xmlFilename)
		if vehicleData.vehicleType == nil or vehicleData.vehicleClass == nil then
			self.loadingState = VehicleLoadingState.ERROR
			if self.callback ~= nil then
				self.callback(self.callbackTarget, self.loadedVehicles, self.loadingState, self.callbackArguments)
				self.callback = nil
				self.callbackTarget = nil
				self.callbackArguments = nil
			end
			g_currentMission.vehicleSystem:removePendingVehicleLoad(self)
			return
		end
	end
	for _, vehicleData in ipairs(self.vehicles) do
		self:loadVehicle(vehicleData)
	end
end
function VehicleLoadingData:loadVehicle(vehicleData)
	local isServer = self.forceServer or g_currentMission:getIsServer()
	local isClient = self.forceServer or g_currentMission:getIsClient()
	local vehicle = vehicleData.vehicleClass.new(isServer, isClient)
	vehicle:setFilename(vehicleData.xmlFilename)
	vehicle:setConfigurations(self:getConfigurations(vehicleData.xmlFilename))
	vehicle:setType(vehicleData.vehicleType)
	vehicle:setLoadCallback(self.onVehicleLoaded, self, nil)
	vehicle:load(self)
	table.insert(self.loadingVehicles, vehicle)
end
function VehicleLoadingData:cancelLoading()
	self.canceledLoading = true
	for _, vehicle in ipairs(self.loadingVehicles) do
		vehicle:delete()
	end
	if self.callback ~= nil then
		self.callback(self.callbackTarget, {}, VehicleLoadingState.CANCELED, self.callbackArguments)
		self.callback = nil
		self.callbackTarget = nil
		self.callbackArguments = nil
	end
	g_currentMission.vehicleSystem:removePendingVehicleLoad(self)
end
function VehicleLoadingData:loadVehicleOnClient(vehicle, callback, callbackTarget)
	local vehicleData = self.vehicles[1]
	local vehicleType, _ = g_vehicleTypeManager:getObjectTypeFromXML(vehicleData.xmlFilename)
	if vehicleType ~= nil then
		g_currentMission.vehicleSystem:addPendingVehicleLoad(self)
		local loadCallback = function(...)
			g_currentMission.vehicleSystem:removePendingVehicleLoad(self)
			callback(...)
		end
		vehicle:setFilename(vehicleData.xmlFilename)
		vehicle:setConfigurations(self:getConfigurations(vehicleData.xmlFilename))
		vehicle:setType(vehicleType)
		vehicle:setLoadCallback(loadCallback, self, nil)
		vehicle:load(self)
	end
end
function VehicleLoadingData:onVehicleLoaded(vehicle, loadingState)
	if self.canceledLoading then
		return
	end
	if loadingState ~= VehicleLoadingState.OK then
		self.loadingState = loadingState
		vehicle:delete()
	else
		table.insert(self.loadedVehicles, vehicle)
		vehicle:setVisibility(false)
		vehicle:removeFromPhysics()
	end
	self.vehiclesToLoad = self.vehiclesToLoad - 1
	if self.vehiclesToLoad <= 0 and self.attacherInfo ~= nil then
		for _, attachInfo in pairs(self.attacherInfo) do
			if self.loadedVehicles[attachInfo.bundleElement0] == nil or self.loadedVehicles[attachInfo.bundleElement1] == nil then
				Logging.error("Not all vehicles for bundle item could be loaded")
				self.loadingState = VehicleLoadingState.ERROR
			else
			end
			if self.loadingState ~= VehicleLoadingState.OK then
				for i = #self.loadedVehicles, 1, -1 do
					self.loadedVehicles[i]:delete()
					self.loadedVehicles[i] = nil
				end
			else
				for _, loadedVehicle in ipairs(self.loadedVehicles) do
					loadedVehicle:setVisibility(true)
					if self.addToPhysics then
						loadedVehicle:addToPhysics()
					end
					if self.saleItem ~= nil then
						SpecializationUtil.raiseEvent(loadedVehicle, "onSaleItemSet", self.saleItem)
						loadedVehicle.operatingTime = self.saleItem.operatingTime
						loadedVehicle.age = self.saleItem.age
					end
					g_messageCenter:publish(MessageType.VEHICLE_LOADED, loadedVehicle)
				end
				if self.attacherInfo ~= nil then
					for _, attachInfo in pairs(self.attacherInfo) do
						local v1 = self.loadingVehicles[attachInfo.bundleElement0]
						local v2 = self.loadingVehicles[attachInfo.bundleElement1]
						if v1 ~= nil and (v2 ~= nil and v1.attachImplement ~= nil) then
							if v2.getInputAttacherJoints ~= nil then
								v1:attachImplement(v2, attachInfo.inputAttacherJointIndex, attachInfo.attacherJointIndex, true, nil, false, true)
							else
								Logging.warning("Unable to attach bundle items together. (implement '%s' to vehicle '%s')", v2:getName(), v1:getName())
							end
						end
					end
				end
			end
			if self.callback ~= nil then
				self.callback(self.callbackTarget, self.loadedVehicles, self.loadingState, self.callbackArguments)
				self.callback = nil
				self.callbackTarget = nil
				self.callbackArguments = nil
			end
			g_currentMission.vehicleSystem:removePendingVehicleLoad(self)
			return
		end
	end
end
