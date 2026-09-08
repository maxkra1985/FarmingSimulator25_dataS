PlaceableManureHeap = {}

function PlaceableManureHeap.prerequisitesPresent(specializations)
	return true
end

function PlaceableManureHeap.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableManureHeap.setOwnerFarmId)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableManureHeap.collectPickObjects)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getCanBePlacedAt", PlaceableManureHeap.getCanBePlacedAt)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableManureHeap.updateInfo)
end

function PlaceableManureHeap.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableManureHeap)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableManureHeap)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableManureHeap)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableManureHeap)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableManureHeap)
end

function PlaceableManureHeap.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("ManureHeap")
	ManureHeap.registerXMLPaths(schema, basePath .. ".manureHeap")
	schema:register(XMLValueType.BOOL, basePath .. ".manureHeap#needsBarn", "Can only be placed next to a barn", true)
	LoadingStation.registerXMLPaths(schema, basePath .. ".manureHeap.loadingStation")
	schema:setXMLSpecializationType()
end

function PlaceableManureHeap.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("ManureHeap")
	ManureHeap.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType()
end
function PlaceableManureHeap.initSpecialization()
	g_storeManager:addSpecType("manureHeapCapacity", "shopListAttributeIconCapacity", PlaceableManureHeap.loadSpecValueCapacity, PlaceableManureHeap.getSpecValueCapacity, StoreSpecies.PLACEABLE)
end

-- Local values: spec, xmlFile
function PlaceableManureHeap:onLoad(savegame)
	local v8_ = self.spec_manureHeap
	local v9_ = self.xmlFile
	v8_.loadingStation = LoadingStation.new(self.isServer, self.isClient)
	if not v8_.loadingStation:load(v8_.components, v9_, "placeable.manureHeap.loadingStation", self.customEnvironment, self.i3dMappings, self.components[1].node) then
		v8_.loadingStation:delete()
		v8_.loadingStation = nil
		return false
	end
	v8_.loadingStation.owningPlaceable = self
	v8_.loadingStation.hasStoragePerFarm = false
	v8_.manureHeap = ManureHeap.new(v8_.isServer, self.isClient)
	if not v8_.manureHeap:load(v8_.components, v9_, "placeable.manureHeap", self.customEnvironment, self.i3dMappings, self.components[1].node) then
		v8_.manureHeap:delete()
		v8_.manureHeap = nil
	end
	v8_.needsBarn = v9_:getValue("placeable.manureHeap#needsBarn", false)
	v8_.infoFillLevel = {
		["title"] = g_i18n:getText("fillType_manure"),
		["text"] = ""
	}
	return true
end

-- Local values: spec, storageSystem
function PlaceableManureHeap:onDelete()
	local v11_ = self.spec_manureHeap
	local v12_ = g_currentMission.storageSystem
	if v11_.manureHeap ~= nil then
		if v12_:hasStorage(v11_.manureHeap) then
			v12_:removeStorageFromUnloadingStations(v11_.manureHeap, v11_.manureHeap.unloadingStations)
			v12_:removeStorageFromLoadingStations(v11_.manureHeap, v11_.manureHeap.loadingStations)
			v12_:removeStorage(v11_.manureHeap)
		end
		v11_.manureHeap:delete()
		v11_.manureHeap = nil
	end
	if v11_.loadingStation ~= nil then
		if v11_.loadingStation:getIsFillTypeSupported(FillType.MANURE) then
			g_currentMission:removeManureLoadingStation(v11_.loadingStation)
		end
		v12_:removeLoadingStation(v11_.loadingStation, self)
		v11_.loadingStation:delete()
		v11_.loadingStation = nil
	end
end

-- Local values: spec, storageSystem, ownerFarmId, storagesInRange, _, storage, lastFoundUnloadingStations, lastFoundLoadingStations
function PlaceableManureHeap:onFinalizePlacement()
	local v14_ = self.spec_manureHeap
	local v15_ = g_currentMission.storageSystem
	local v16_ = self:getOwnerFarmId()
	if v14_.loadingStation ~= nil and v14_.manureHeap ~= nil then
		v14_.loadingStation:register(true)
		v15_:addLoadingStation(v14_.loadingStation, self)
		v14_.manureHeap:finalize()
		v14_.manureHeap:register(true)
		v14_.manureHeap:setOwnerFarmId(v16_, true)
		v15_:addStorage(v14_.manureHeap)
		v15_:addStorageToLoadingStation(v14_.manureHeap, v14_.loadingStation)
		if v14_.loadingStation:getIsFillTypeSupported(FillType.MANURE) then
			g_currentMission:addManureLoadingStation(v14_.loadingStation)
		end
		local v17_ = v15_:getStorageExtensionsInRange(v14_.loadingStation, v16_)
		for _, v18_ in ipairs(v17_) do
			if v14_.loadingStation.sourceStorages[v18_] == nil then
				v15_:addStorageToLoadingStation(v18_, v14_.loadingStation)
			end
		end
		local v19_ = v15_:getExtendableUnloadingStationsInRange(v14_.manureHeap, v16_)
		local v20_ = v15_:getExtendableLoadingStationsInRange(v14_.manureHeap, v16_)
		v15_:addStorageToUnloadingStations(v14_.manureHeap, v19_)
		v15_:addStorageToLoadingStations(v14_.manureHeap, v20_)
	end
end

-- Local values: spec, loadingStationId, manureHeapId
function PlaceableManureHeap:onReadStream(streamId, connection)
	local v24_ = self.spec_manureHeap
	if v24_.loadingStation ~= nil and v24_.manureHeap ~= nil then
		local v25_ = NetworkUtil.readNodeObjectId(streamId)
		v24_.loadingStation:readStream(streamId, connection)
		g_client:finishRegisterObject(v24_.loadingStation, v25_)
		local v26_ = NetworkUtil.readNodeObjectId(streamId)
		v24_.manureHeap:readStream(streamId, connection)
		g_client:finishRegisterObject(v24_.manureHeap, v26_)
	end
end

-- Local values: spec
function PlaceableManureHeap:onWriteStream(streamId, connection)
	local v30_ = self.spec_manureHeap
	if v30_.loadingStation ~= nil and v30_.manureHeap ~= nil then
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v30_.loadingStation))
		v30_.loadingStation:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, v30_.loadingStation)
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v30_.manureHeap))
		v30_.manureHeap:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, v30_.manureHeap)
	end
end

-- Local values: spec
function PlaceableManureHeap:loadFromXMLFile(xmlFile, key)
	local v34_ = self.spec_manureHeap
	if v34_.manureHeap ~= nil then
		v34_.manureHeap:loadFromXMLFile(xmlFile, key)
	end
end

-- Local values: spec
function PlaceableManureHeap:saveToXMLFile(xmlFile, key, usedModNames)
	local v39_ = self.spec_manureHeap
	if v39_.manureHeap ~= nil then
		v39_.manureHeap:saveToXMLFile(xmlFile, key, usedModNames)
	end
end

-- Local values: spec, storageSystem, storagesInRange, _, storage, lastFoundUnloadingStations, lastFoundLoadingStations
function PlaceableManureHeap:setOwnerFarmId(superFunc, farmId, noEventSend)
	superFunc(self, farmId, noEventSend)
	local v44_ = self.spec_manureHeap
	if self.isServer and v44_.manureHeap ~= nil then
		v44_.manureHeap:setOwnerFarmId(farmId, true)
	end
	local v45_ = g_currentMission.storageSystem
	if v44_.loadingStation ~= nil then
		local v46_ = v45_:getStorageExtensionsInRange(v44_.loadingStation, farmId)
		for _, v47_ in ipairs(v46_) do
			if v44_.loadingStation.sourceStorages[v47_] == nil then
				v45_:addStorageToLoadingStation(v47_, v44_.loadingStation)
			end
		end
	end
	if v44_.manureHeap ~= nil then
		local v48_ = v45_:getExtendableUnloadingStationsInRange(v44_.manureHeap, farmId)
		local v49_ = v45_:getExtendableLoadingStationsInRange(v44_.manureHeap, farmId)
		v45_:addStorageToUnloadingStations(v44_.manureHeap, v48_)
		v45_:addStorageToLoadingStations(v44_.manureHeap, v49_)
	end
end

-- Local values: spec, _, loadTrigger
function PlaceableManureHeap:collectPickObjects(superFunc, node)
	local v53_ = self.spec_manureHeap
	if v53_.loadingStation ~= nil then
		for _, v54_ in ipairs(v53_.loadingStation.loadTriggers) do
			if node == v54_.triggerNode then
				return
			end
		end
	end
	if v53_.manureHeap == nil or node ~= v53_.manureHeap.activationTriggerNode then
		superFunc(self, node)
	end
end

-- Local values: spec, storageSystem, lastFoundUnloadingStations
function PlaceableManureHeap:getCanBePlacedAt(superFunc, x, y, z, farmId)
	local v61_ = self.spec_manureHeap
	if v61_.manureHeap == nil then
		return false
	elseif v61_.needsBarn and #g_currentMission.storageSystem:getExtendableUnloadingStationsInRange(v61_.manureHeap, farmId, x, y, z) == 0 then
		return false, g_i18n:getText("warning_manureHeapNotNearBarn")
	else
		return superFunc(self, x, y, z, farmId)
	end
end

-- Local values: spec, fillLevel
function PlaceableManureHeap:updateInfo(superFunc, infoTable)
	superFunc(self, infoTable)
	local v65_ = self.spec_manureHeap
	if v65_.manureHeap ~= nil then
		local v66_ = v65_.manureHeap:getFillLevel(v65_.manureHeap.fillTypeIndex)
		v65_.infoFillLevel.text = string.format("%d l", v66_)
		local v67_ = v65_.infoFillLevel
		table.insert(infoTable, v67_)
	end
end

function PlaceableManureHeap.loadSpecValueCapacity(xmlFile, customEnvironment, baseDir)
	return xmlFile:getValue("placeable.manureHeap#capacity")
end

function PlaceableManureHeap.getSpecValueCapacity(storeItem, realItem)
	if storeItem.specs.manureHeapCapacity == nil then
		return nil
	else
		return g_i18n:formatVolume(storeItem.specs.manureHeapCapacity)
	end
end
