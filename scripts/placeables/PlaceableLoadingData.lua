-- Local values: PlaceableLoadingData_mt
PlaceableLoadingData = {}
local PlaceableLoadingData_mt = Class(PlaceableLoadingData)

-- Upvalues: PlaceableLoadingData_mt
-- Local values: self
function PlaceableLoadingData.new(customMt)
	-- upvalues: (copy) PlaceableLoadingData_mt
	local v3_ = customMt or PlaceableLoadingData_mt
	local v4_ = setmetatable({}, v3_)
	v4_.storeItem = nil
	v4_.validLocation = true
	v4_.placeable = nil
	v4_.isValid = false
	v4_.propertyState = PlaceablePropertyState.OWNED
	v4_.ownerFarmId = AccessHandler.EVERYONE
	v4_.forceServer = false
	v4_.isSaved = true
	v4_.uniqueId = nil
	v4_.loadingState = nil
	v4_.savegameData = nil
	v4_.configurations = {}
	v4_.boughtConfigurations = {}
	v4_.configurationData = {}
	v4_.isRegistered = true
	v4_.preplacedIndex = nil
	v4_.price = nil
	v4_.position = { 0, 0, 0 }
	v4_.rotation = { 0, 0, 0 }
	v4_.customParameters = {}
	return v4_
end

-- Local values: storeItem
function PlaceableLoadingData:setFilename(filename)
	local v7_ = g_storeManager:getItemByXMLFilename(filename)
	if v7_ == nil then
		Logging.error("Unable to find placeable storeitem for \'%s\'", filename)
		printCallstack()
	else
		self:setStoreItem(v7_)
	end
end

function PlaceableLoadingData:setStoreItem(storeItem)
	if storeItem ~= nil then
		self.storeItem = storeItem
		self.rotation[2] = storeItem.rotation
		self.placeable = {
			["xmlFilename"] = storeItem.xmlFilename
		}
	end
	self.isValid = self.placeable ~= nil
end

function PlaceableLoadingData:setPropertyState(propertyState)
	self.propertyState = propertyState
end

function PlaceableLoadingData:setOwnerFarmId(ownerFarmId)
	self.ownerFarmId = ownerFarmId
end

-- Local values: _, key, name, id, configIndex
function PlaceableLoadingData:setSavegameData(savegameData)
	self.savegameData = savegameData
	if self.storeItem ~= nil and (savegameData ~= nil and savegameData.xmlFile ~= nil) then
		local v16_, v17_, v18_ = ConfigurationUtil.loadConfigurationsFromXMLFile(self.storeItem.xmlFilename, savegameData.xmlFile, savegameData.key .. ".configuration")
		self.configurations = v16_
		self.boughtConfigurations = v17_
		self.configurationData = v18_
		for _, v19_ in savegameData.xmlFile:iterator(savegameData.key .. ".boughtConfiguration") do
			local v20_ = savegameData.xmlFile:getValue(v19_ .. "#name")
			local v21_ = savegameData.xmlFile:getValue(v19_ .. "#id")
			if v20_ == nil or v21_ == nil then
				Logging.xmlWarning(savegameData.xmlFile, "Invalid bought configuration in \'%s\'!", savegameData.key)
			else
				if self.boughtConfigurations[v20_] == nil then
					self.boughtConfigurations[v20_] = {}
				end
				local v22_ = ConfigurationUtil.getConfigIdBySaveId(self.storeItem.xmlFilename, v20_, v21_)
				if v22_ ~= nil then
					self.boughtConfigurations[v20_][v22_] = true
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
	if configurations == nil then
		self.configurations = {}
	else
		self.configurations = configurations
	end
end

function PlaceableLoadingData:setBoughtConfigurations(boughtConfigurations)
	if boughtConfigurations == nil then
		self.boughtConfigurations = {}
	else
		self.boughtConfigurations = boughtConfigurations
	end
end

function PlaceableLoadingData:setConfigurationData(configurationData)
	if configurationData == nil then
		self.configurationData = {}
	else
		self.configurationData = configurationData
	end
end

-- Local values: configurations, boughtConfigurations, configurationData, storeItem, configName, configId, configName, configItems, configIndex
function PlaceableLoadingData:getConfigurations(configFileName)
	local v37_ = table.clone(self.configurations, math.huge)
	local v38_ = table.clone(self.boughtConfigurations, math.huge)
	local v39_ = table.clone(self.configurationData, math.huge)
	local v40_ = g_storeManager:getItemByXMLFilename(configFileName)
	if v40_ ~= nil and v40_.configurations ~= nil then
		for v41_, _ in pairs(v37_) do
			if v40_.configurations[v41_] == nil then
				v37_[v41_] = nil
				v38_[v41_] = nil
			end
		end
	end
	if self.storeItem.configurations ~= nil then
		for v42_, v43_ in pairs(self.storeItem.configurations) do
			if v37_[v42_] == nil then
				v37_[v42_] = ConfigurationUtil.getDefaultConfigIdFromItems(v43_)
			end
		end
	end
	return v37_, v38_, v39_
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
	local v59_ = self.position
	local v60_ = self.position
	local v61_ = self.position
	v59_[1] = x
	v60_[2] = y
	v61_[3] = z
end

function PlaceableLoadingData:setRotation(rx, ry, rz)
	local v66_ = self.rotation
	local v67_ = self.rotation
	local v68_ = self.rotation
	v66_[1] = rx
	v67_[2] = ry
	v68_[3] = rz
end

function PlaceableLoadingData:setSpawnNode(node)
	local v71_ = self.position
	local v72_ = self.position
	local v73_ = self.position
	local v74_, v75_, v76_ = getWorldTranslation(node)
	v71_[1] = v74_
	v72_[2] = v75_
	v73_[3] = v76_
	local v77_ = self.rotation
	local v78_ = self.rotation
	local v79_ = self.rotation
	local v80_, v81_, v82_ = getWorldRotation(node)
	v77_[1] = v80_
	v78_[2] = v81_
	v79_[3] = v82_
end

-- Local values: savegame, x, y, z, xRot, yRot, zRot
function PlaceableLoadingData:applyPositionData(placeable)
	if self.validLocation then
		if self.preplacedIndex == nil then
			if self.savegameData == nil then
				placeable:setPose(self.position[1], self.position[2], self.position[3], self.rotation[1], self.rotation[2], self.rotation[3])
				return true
			else
				local v85_ = self.savegameData
				local v86_, v87_, v88_ = v85_.xmlFile:getValue(v85_.key .. "#position")
				local v89_, v90_, v91_ = v85_.xmlFile:getValue(v85_.key .. "#rotation")
				if v86_ == nil or (v87_ == nil or (v88_ == nil or (v89_ == nil or (v90_ == nil or v91_ == nil)))) then
					Logging.xmlWarning(v85_.xmlFile, "Invalid position in \'%s\' (%s)!", v85_.key, placeable.configFileName)
					return false
				else
					placeable:setPose(v86_, v87_, v88_, v89_, v90_, v91_)
					return true
				end
			end
		else
			return true
		end
	else
		return false
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

-- Local values: placeableType, placeableClass, isServer, isClient, placeable
function PlaceableLoadingData:loadPlaceable(placeableData)
	local v99_, v100_ = g_placeableTypeManager:getObjectTypeFromXML(placeableData.xmlFilename)
	if v99_ == nil then
		self:onPlacableLoaded(nil, PlaceableLoadingState.ERROR)
	else
		local v101_ = self.forceServer or g_currentMission:getIsServer()
		local v102_ = self.forceServer or g_currentMission:getIsClient()
		local v103_ = v100_.new(v101_, v102_)
		v103_:setFilename(placeableData.xmlFilename)
		v103_:setConfigurations(self:getConfigurations(placeableData.xmlFilename))
		v103_:setType(v99_)
		v103_:setLoadCallback(self.onPlacableLoaded, self, nil)
		v103_:load(self)
		self.placeable = v103_
	end
end

-- Local values: placeableData, placeableType, _, loadCallback
function PlaceableLoadingData:loadPlaceableOnClient(placeable, callback, callbackTarget)
	local v107_ = self.placeable
	local v108_, _ = g_placeableTypeManager:getObjectTypeFromXML(v107_.xmlFilename)
	if v108_ == nil then
		self:onPlacableLoaded(nil, PlaceableLoadingState.ERROR)
	else
		g_currentMission.placeableSystem:addPendingPlaceableLoad(self)
		placeable:setFilename(v107_.xmlFilename)
		placeable:setConfigurations(self:getConfigurations(v107_.xmlFilename))
		placeable:setType(v108_)
		placeable:setLoadCallback(function(...)
			-- upvalues: (copy) self, (copy) callback
			g_currentMission.placeableSystem:removePendingPlaceableLoad(self)
			callback(...)
		end, self, nil)
		placeable:load(self)
		self.placeable = placeable
	end
end

function PlaceableLoadingData:onPlacableLoaded(placeable, loadingState)
	if not self.canceledLoading then
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
