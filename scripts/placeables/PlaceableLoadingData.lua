PlaceableLoadingData = {}
local PlaceableLoadingData_mt = Class(PlaceableLoadingData)
function PlaceableLoadingData.new(customMt)
	local self = setmetatable({}, customMt or PlaceableLoadingData_mt)
	self.storeItem = nil
	self.validLocation = true
	self.placeable = nil
	self.isValid = false
	self.propertyState = PlaceablePropertyState.OWNED
	self.ownerFarmId = AccessHandler.EVERYONE
	self.forceServer = false
	self.isSaved = true
	self.uniqueId = nil
	self.loadingState = nil
	self.savegameData = nil
	self.configurations = {}
	self.boughtConfigurations = {}
	self.configurationData = {}
	self.isRegistered = true
	self.preplacedIndex = nil
	self.price = nil
	self.position = { 0, 0, 0 }
	self.rotation = { 0, 0, 0 }
	self.customParameters = {}
	return self
end
function PlaceableLoadingData:setFilename(filename)
	local storeItem = g_storeManager:getItemByXMLFilename(filename)
	if storeItem ~= nil then
		self:setStoreItem(storeItem)
	else
		Logging.error("Unable to find placeable storeitem for '%s'", filename)
		printCallstack()
	end
end
function PlaceableLoadingData:setStoreItem(storeItem)
	if storeItem ~= nil then
		self.storeItem = storeItem
		self.rotation[2] = storeItem.rotation
		self.placeable = { xmlFilename = storeItem.xmlFilename }
	end
	self.isValid = self.placeable ~= nil
end
function PlaceableLoadingData:setPropertyState(propertyState)
	self.propertyState = propertyState
end
function PlaceableLoadingData:setOwnerFarmId(ownerFarmId)
	self.ownerFarmId = ownerFarmId
end
function PlaceableLoadingData:setSavegameData(savegameData)
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
function PlaceableLoadingData:setPreplacedIndex(index)
	self.preplacedIndex = index
end
function PlaceableLoadingData:getPreplacedIndex()
	return self.preplacedIndex
end
function PlaceableLoadingData:setUniqueId(uniqueId)
	self.uniqueId = uniqueId
end
function PlaceableLoadingData:getUniqueId()
	return self.uniqueId
end
function PlaceableLoadingData:setConfigurations(configurations)
	if configurations ~= nil then
		self.configurations = configurations
	else
		self.configurations = {}
	end
end
function PlaceableLoadingData:setBoughtConfigurations(boughtConfigurations)
	if boughtConfigurations ~= nil then
		self.boughtConfigurations = boughtConfigurations
	else
		self.boughtConfigurations = {}
	end
end
function PlaceableLoadingData:setConfigurationData(configurationData)
	if configurationData ~= nil then
		self.configurationData = configurationData
	else
		self.configurationData = {}
	end
end
function PlaceableLoadingData:getConfigurations(configFileName)
	local configurations = table.clone(self.configurations, math.huge)
	local boughtConfigurations = table.clone(self.boughtConfigurations, math.huge)
	local configurationData = table.clone(self.configurationData, math.huge)
	local storeItem = g_storeManager:getItemByXMLFilename(configFileName)
	if storeItem ~= nil and storeItem.configurations ~= nil then
		for configName, configId in pairs(configurations) do
			if storeItem.configurations[configName] == nil then
				configurations[configName] = nil
				boughtConfigurations[configName] = nil
			end
		end
	end
	if self.storeItem.configurations ~= nil then
		for configName, configItems in pairs(self.storeItem.configurations) do
			local configIndex = configurations[configName]
			if configIndex == nil then
				configurations[configName] = ConfigurationUtil.getDefaultConfigIdFromItems(configItems)
			end
		end
	end
	return configurations, boughtConfigurations, configurationData
end
function PlaceableLoadingData:setIsRegistered(isRegistered)
	self.isRegistered = isRegistered
end
function PlaceableLoadingData:setForceServer(forceServer)
	self.forceServer = forceServer
end
function PlaceableLoadingData:setIsSaved(isSaved)
	self.isSaved = isSaved
end
function PlaceableLoadingData:setCustomParameter(name, value)
	self.customParameters[name] = value
end
function PlaceableLoadingData:getCustomParameter(name)
	return self.customParameters[name]
end
function PlaceableLoadingData:setPosition(x, y, z)
	if y == nil then
		y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
	end
	self.position[1] = x
	self.position[2] = y
	self.position[3] = z
end
function PlaceableLoadingData:setRotation(rx, ry, rz)
	self.rotation[1] = rx
	self.rotation[2] = ry
	self.rotation[3] = rz
end
function PlaceableLoadingData:setSpawnNode(node)
	self.position[1], self.position[2], self.position[3] = getWorldTranslation(node)
	self.rotation[1], self.rotation[2], self.rotation[3] = getWorldRotation(node)
end
function PlaceableLoadingData:applyPositionData(placeable)
	if not self.validLocation then
		return false
	elseif self.preplacedIndex ~= nil then
		return true
	elseif self.savegameData ~= nil then
		local savegame = self.savegameData
		local x, y, z = savegame.xmlFile:getValue(savegame.key .. "#position")
		local xRot, yRot, zRot = savegame.xmlFile:getValue(savegame.key .. "#rotation")
		if x == nil or y == nil or z == nil or xRot == nil or yRot == nil or zRot == nil then
			Logging.xmlWarning(savegame.xmlFile, "Invalid position in '%s' (%s)!", savegame.key, placeable.configFileName)
			return false
		end
		placeable:setPose(x, y, z, xRot, yRot, zRot)
		return true
	else
		placeable:setPose(self.position[1], self.position[2], self.position[3], self.rotation[1], self.rotation[2], self.rotation[3])
		return true
	end
end
function PlaceableLoadingData:load(callback, callbackTarget, callbackArguments)
	g_currentMission.placeableSystem:addPendingPlaceableLoad(self)
	self.callback = callback
	self.callbackTarget = callbackTarget
	self.callbackArguments = callbackArguments
	self.loadingState = PlaceableLoadingState.OK
	self:loadPlaceable(self.placeable)
end
function PlaceableLoadingData:cancelLoading()
	self.canceledLoading = true
	if self.placeable ~= nil then
		self.placeable:delete()
	end
	if self.callback ~= nil then
		self.callback(self.callbackTarget, nil, PlaceableLoadingState.CANCELED, self.callbackArguments)
		self.callback = nil
		self.callbackTarget = nil
		self.callbackArguments = nil
	end
	g_currentMission.placeableSystem:removePendingPlaceableLoad(self)
end
function PlaceableLoadingData:loadPlaceable(placeableData)
	local placeableType, placeableClass = g_placeableTypeManager:getObjectTypeFromXML(placeableData.xmlFilename)
	if placeableType ~= nil then
		local isServer = self.forceServer or g_currentMission:getIsServer()
		local isClient = self.forceServer or g_currentMission:getIsClient()
		local placeable = placeableClass.new(isServer, isClient)
		placeable:setFilename(placeableData.xmlFilename)
		placeable:setConfigurations(self:getConfigurations(placeableData.xmlFilename))
		placeable:setType(placeableType)
		placeable:setLoadCallback(self.onPlacableLoaded, self, nil)
		placeable:load(self)
		self.placeable = placeable
	else
		self:onPlacableLoaded(nil, PlaceableLoadingState.ERROR)
	end
end
function PlaceableLoadingData:loadPlaceableOnClient(placeable, callback, callbackTarget)
	local placeableData = self.placeable
	local placeableType, _ = g_placeableTypeManager:getObjectTypeFromXML(placeableData.xmlFilename)
	if placeableType ~= nil then
		g_currentMission.placeableSystem:addPendingPlaceableLoad(self)
		local loadCallback = function(...)
			g_currentMission.placeableSystem:removePendingPlaceableLoad(self)
			callback(...)
		end
		placeable:setFilename(placeableData.xmlFilename)
		placeable:setConfigurations(self:getConfigurations(placeableData.xmlFilename))
		placeable:setType(placeableType)
		placeable:setLoadCallback(loadCallback, self, nil)
		placeable:load(self)
		self.placeable = placeable
	else
		self:onPlacableLoaded(nil, PlaceableLoadingState.ERROR)
	end
end
function PlaceableLoadingData:onPlacableLoaded(placeable, loadingState)
	if self.canceledLoading then
		return
	else
		if loadingState ~= PlaceableLoadingState.OK then
			self.loadingState = loadingState
			if placeable ~= nil then
				placeable:delete()
			end
		end
		if self.callback ~= nil then
			self.callback(self.callbackTarget, placeable, self.loadingState, self.callbackArguments)
			self.callback = nil
			self.callbackTarget = nil
			self.callbackArguments = nil
		end
		g_currentMission.placeableSystem:removePendingPlaceableLoad(self)
	end
end
