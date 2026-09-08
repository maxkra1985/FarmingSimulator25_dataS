-- Local values: StorageSystem_mt
StorageSystem = {}
local StorageSystem_mt = Class(StorageSystem)

-- Upvalues: StorageSystem_mt
-- Local values: self
function StorageSystem.new(accessHandler, customMt)
	-- upvalues: (copy) StorageSystem_mt
	local v4_ = customMt or StorageSystem_mt
	local v5_ = setmetatable({}, v4_)
	v5_.accessHandler = accessHandler
	v5_.loadingStations = {}
	v5_.placeableLoadingStations = {}
	v5_.extendableLoadingStations = {}
	v5_.unloadingStations = {}
	v5_.placeableUnloadingStations = {}
	v5_.extendableUnloadingStations = {}
	v5_.storages = {}
	v5_.storageExtensions = {}
	v5_.palletBuyingStations = {}
	return v5_
end

function StorageSystem:delete() end

-- Local values: storage
function StorageSystem:consoleCommandToggleDebug()
	self.debugEnabled = not self.debugEnabled
	for v7_ in pairs(self.storages) do
		if self.debugEnabled then
			g_currentMission:addDrawable(v7_)
		else
			g_currentMission:removeDrawable(v7_)
		end
	end
	local v8_ = self.debugEnabled
	return "StorageSystem.debugEnabled=" .. tostring(v8_)
end

function StorageSystem:addStorage(storage)
	if storage == nil then
		return false
	end
	self.storages[storage] = storage
	if storage.isExtension then
		self.storageExtensions[storage] = storage
	end
	return true
end

function StorageSystem:removeStorage(storage)
	if storage == nil then
		return false
	end
	self.storages[storage] = nil
	self.storageExtensions[storage] = nil
	return true
end

function StorageSystem:hasStorage(storage)
	if storage == nil then
		return false
	else
		return self.storages[storage] ~= nil
	end
end

function StorageSystem:getStorages()
	return self.storages
end

-- Local values: storagesInRange, storage, _
function StorageSystem:getStorageExtensionsInRange(station, farmId)
	local v19_ = {}
	for v20_, _ in pairs(self.storageExtensions) do
		if self:getIsStationCompatible(station, v20_, farmId) then
			table.insert(v19_, v20_)
		end
	end
	return v19_
end

function StorageSystem:addLoadingStation(station, placeable)
	if station == nil then
		return false
	end
	self.loadingStations[station] = station
	g_messageCenter:publish(MessageType.LOADING_STATIONS_CHANGED)
	if placeable ~= nil then
		if self.placeableLoadingStations[placeable] == nil then
			self.placeableLoadingStations[placeable] = {}
		end
		local v24_ = self.placeableLoadingStations[placeable]
		table.insert(v24_, station)
	end
	if station.supportsExtension then
		self.extendableLoadingStations[station] = station
	end
	return true
end

-- Local values: k, s
function StorageSystem:removeLoadingStation(station, placeable)
	if station == nil then
		return false
	end
	self.loadingStations[station] = nil
	self.extendableLoadingStations[station] = nil
	if placeable ~= nil and self.placeableLoadingStations[placeable] ~= nil then
		for v28_, v29_ in ipairs(self.placeableLoadingStations[placeable]) do
			if station == v29_ then
				table.remove(self.placeableLoadingStations[placeable], v28_)
			end
		end
		if #self.placeableLoadingStations[placeable] == 0 then
			self.placeableLoadingStations[placeable] = nil
		end
	end
	g_messageCenter:publish(MessageType.LOADING_STATIONS_CHANGED)
	return true
end

-- Local values: k, s
function StorageSystem:getPlaceableLoadingStationIndex(placeable, station)
	if self.placeableLoadingStations[placeable] ~= nil then
		for v33_, v34_ in ipairs(self.placeableLoadingStations[placeable]) do
			if station == v34_ then
				return v33_
			end
		end
	end
	return nil
end

-- Local values: loadingStations
function StorageSystem:getPlaceableLoadingStation(placeable, index)
	local v38_ = self.placeableLoadingStations[placeable]
	if v38_ == nil then
		return nil
	else
		return v38_[index]
	end
end

function StorageSystem:getLoadingStations()
	return self.loadingStations
end

function StorageSystem:getIsLoadingStationAvailable(loadingStation)
	return self.loadingStations[loadingStation] ~= nil
end

function StorageSystem:addStorageToLoadingStation(storage, loadingStation)
	if not loadingStation:addSourceStorage(storage) then
		return false
	end
	g_messageCenter:publish(MessageType.STORAGE_ADDED_TO_LOADING_STATION, storage, loadingStation)
	return true
end

-- Local values: success, _, loadingStation
function StorageSystem:addStorageToLoadingStations(storage, loadingStations, farmId)
	local v47_ = false
	for _, v48_ in pairs(loadingStations) do
		if self:addStorageToLoadingStation(storage, v48_) then
			v47_ = true
		end
	end
	return v47_
end

-- Local values: success, _, loadingStation
function StorageSystem:removeStorageFromLoadingStations(storage, loadingStations)
	local v51_ = false
	for _, v52_ in pairs(loadingStations) do
		if v52_:removeSourceStorage(storage) then
			g_messageCenter:publish(MessageType.STORAGE_REMOVED_FROM_LOADING_STATION, storage, v52_)
			v51_ = true
		end
	end
	return v51_
end

-- Local values: stationsInRange, station, _
function StorageSystem:getExtendableLoadingStationsInRange(storage, farmId, posX, posY, posZ)
	local v59_ = {}
	for v60_, _ in pairs(self.extendableLoadingStations) do
		if self:getIsStationCompatible(v60_, storage, farmId, posX, posY, posZ) then
			table.insert(v59_, v60_)
		end
	end
	return v59_
end

function StorageSystem:addUnloadingStation(station, placeable)
	if station == nil then
		return false
	end
	self.unloadingStations[station] = station
	g_messageCenter:publish(MessageType.UNLOADING_STATIONS_CHANGED)
	if placeable == nil then
		Logging.error("StorageSystem:addUnloadingStation(): no placeable given")
		printCallstack()
		return false
	end
	if self.placeableUnloadingStations[placeable] == nil then
		self.placeableUnloadingStations[placeable] = {}
	end
	local v64_ = self.placeableUnloadingStations[placeable]
	table.insert(v64_, station)
	if station.supportsExtension then
		self.extendableUnloadingStations[station] = station
	end
	return true
end

-- Local values: k, s
function StorageSystem:removeUnloadingStation(station, placeable)
	if station == nil then
		return false
	end
	self.unloadingStations[station] = nil
	self.extendableUnloadingStations[station] = nil
	if placeable ~= nil and self.placeableUnloadingStations[placeable] ~= nil then
		for v68_, v69_ in ipairs_reverse(self.placeableUnloadingStations[placeable]) do
			if station == v69_ then
				table.remove(self.placeableUnloadingStations[placeable], v68_)
			end
		end
		if #self.placeableUnloadingStations[placeable] == 0 then
			self.placeableUnloadingStations[placeable] = nil
		end
	end
	g_messageCenter:publish(MessageType.UNLOADING_STATIONS_CHANGED)
	return true
end

-- Local values: k, s
function StorageSystem:getPlaceableUnloadingStationIndex(placeable, station)
	if self.placeableUnloadingStations[placeable] ~= nil then
		for v73_, v74_ in ipairs(self.placeableUnloadingStations[placeable]) do
			if station == v74_ then
				return v73_
			end
		end
	end
	return nil
end

-- Local values: unloadingStations
function StorageSystem:getPlaceableUnloadingStation(placeable, index)
	local v78_ = self.placeableUnloadingStations[placeable]
	if v78_ == nil then
		return nil
	else
		return v78_[index]
	end
end

function StorageSystem:getUnloadingStations()
	return self.unloadingStations
end

function StorageSystem:getIsUnloadingStationAvailable(unloadingStation)
	return self.unloadingStations[unloadingStation] ~= nil
end

function StorageSystem:addStorageToUnloadingStation(storage, unloadingStation)
	if not unloadingStation:addTargetStorage(storage) then
		return false
	end
	g_messageCenter:publish(MessageType.STORAGE_ADDED_TO_UNLOADING_STATION, storage, unloadingStation)
	return true
end

-- Local values: success, _, unloadingStation
function StorageSystem:addStorageToUnloadingStations(storage, unloadingStations)
	local v87_ = false
	for _, v88_ in pairs(unloadingStations) do
		if self:addStorageToUnloadingStation(storage, v88_) then
			v87_ = true
		end
	end
	return v87_
end

-- Local values: success, _, unloadingStation
function StorageSystem:removeStorageFromUnloadingStations(storage, unloadingStations)
	local v91_ = false
	for _, v92_ in pairs(unloadingStations) do
		if v92_:removeTargetStorage(storage) then
			g_messageCenter:publish(MessageType.STORAGE_REMOVED_FROM_UNLOADING_STATION, storage, v92_)
			v91_ = true
		end
	end
	return v91_
end

-- Local values: stationsInRange, station, _
function StorageSystem:getExtendableUnloadingStationsInRange(storage, farmId, posX, posY, posZ)
	local v99_ = {}
	for v100_, _ in pairs(self.extendableUnloadingStations) do
		if self:getIsStationCompatible(v100_, storage, farmId, posX, posY, posZ) then
			table.insert(v99_, v100_)
		end
	end
	return v99_
end

-- Local values: hasRadius, canAccessTarget, distance, x, y, z, isInRange, hasMatchingFillType, fillType, _
function StorageSystem:getIsStationCompatible(station, storage, farmId, posX, posY, posZ)
	if station.storageRadius == nil or not self.accessHandler:canFarmAccess(farmId, station) then
		return false
	end
	local v108_
	if posX == nil or (posY == nil or posZ == nil) then
		v108_ = calcDistanceFrom(storage.rootNode, station.rootNode)
	else
		local v109_, v110_, v111_ = getWorldTranslation(station.rootNode)
		v108_ = MathUtil.vector3Length(v109_ - posX, v110_ - posY, v111_ - posZ)
	end
	if v108_ >= station.storageRadius then
		return false
	end
	local v112_ = false
	for v113_, _ in pairs(storage.fillTypes) do
		if station.supportedFillTypes[v113_] ~= nil then
			v112_ = true
		end
	end
	return v112_ and true or false
end

function StorageSystem:getPalletBuyingStations()
	return self.palletBuyingStations
end

function StorageSystem:addPalletBuyingStation(station)
	if station == nil then
		return false
	end
	self.palletBuyingStations[station] = station
	return true
end

function StorageSystem:removePalletBuyingStation(station)
	if station == nil then
		return false
	end
	self.palletBuyingStations[station] = nil
	return true
end
