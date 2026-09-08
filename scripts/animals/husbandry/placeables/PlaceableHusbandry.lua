PlaceableHusbandry = {}

function PlaceableHusbandry.prerequisitesPresent(self)
	return true
end

function PlaceableHusbandry.registerEvents(placeableType)
	SpecializationUtil.registerEvent(placeableType, "onHusbandryFillLevelChanged")
	SpecializationUtil.registerEvent(placeableType, "onFinishedFeeding")
end

function PlaceableHusbandry.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "onAddedStorageToLoadingStation", PlaceableHusbandry.onAddedStorageToLoadingStation)
	SpecializationUtil.registerFunction(placeableType, "onRemovedStorageFromLoadingStation", PlaceableHusbandry.onRemovedStorageFromLoadingStation)
	SpecializationUtil.registerFunction(placeableType, "onAddedStorageToUnloadingStation", PlaceableHusbandry.onAddedStorageToUnloadingStation)
	SpecializationUtil.registerFunction(placeableType, "onRemovedStorageFromUnloadingStation", PlaceableHusbandry.onRemovedStorageFromUnloadingStation)
	SpecializationUtil.registerFunction(placeableType, "updateFeeding", PlaceableHusbandry.updateFeeding)
	SpecializationUtil.registerFunction(placeableType, "updateProduction", PlaceableHusbandry.updateProduction)
	SpecializationUtil.registerFunction(placeableType, "updateOutput", PlaceableHusbandry.updateOutput)
	SpecializationUtil.registerFunction(placeableType, "getGlobalProductionFactor", PlaceableHusbandry.getGlobalProductionFactor)
	SpecializationUtil.registerFunction(placeableType, "getProductionFactor", PlaceableHusbandry.getProductionFactor)
	SpecializationUtil.registerFunction(placeableType, "getConditionInfos", PlaceableHusbandry.getConditionInfos)
	SpecializationUtil.registerFunction(placeableType, "getFoodInfos", PlaceableHusbandry.getFoodInfos)
	SpecializationUtil.registerFunction(placeableType, "getAnimalInfos", PlaceableHusbandry.getAnimalInfos)
	SpecializationUtil.registerFunction(placeableType, "getAnimalDescription", PlaceableHusbandry.getAnimalDescription)
	SpecializationUtil.registerFunction(placeableType, "getHusbandryCapacity", PlaceableHusbandry.getHusbandryCapacity)
	SpecializationUtil.registerFunction(placeableType, "getHusbandryFreeCapacity", PlaceableHusbandry.getHusbandryFreeCapacity)
	SpecializationUtil.registerFunction(placeableType, "addHusbandryFillLevelFromTool", PlaceableHusbandry.addHusbandryFillLevelFromTool)
	SpecializationUtil.registerFunction(placeableType, "removeHusbandryFillLevel", PlaceableHusbandry.removeHusbandryFillLevel)
	SpecializationUtil.registerFunction(placeableType, "getHusbandryFillLevel", PlaceableHusbandry.getHusbandryFillLevel)
	SpecializationUtil.registerFunction(placeableType, "getHusbandryIsFillTypeSupported", PlaceableHusbandry.getHusbandryIsFillTypeSupported)
end

function PlaceableHusbandry.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableHusbandry.setOwnerFarmId)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableHusbandry.collectPickObjects)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getCanBePlacedAt", PlaceableHusbandry.getCanBePlacedAt)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "canBuy", PlaceableHusbandry.canBuy)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getNeedHourChanged", PlaceableHusbandry.getNeedHourChanged)
end

function PlaceableHusbandry.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandry)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHusbandry)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableHusbandry)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableHusbandry)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableHusbandry)
	SpecializationUtil.registerEventListener(placeableType, "onReadUpdateStream", PlaceableHusbandry)
	SpecializationUtil.registerEventListener(placeableType, "onWriteUpdateStream", PlaceableHusbandry)
	SpecializationUtil.registerEventListener(placeableType, "onHourChanged", PlaceableHusbandry)
	SpecializationUtil.registerEventListener(placeableType, "onBuy", PlaceableHusbandry)
end

function PlaceableHusbandry.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")
	schema:register(XMLValueType.STRING, basePath .. ".husbandry#saveId", "Save id")
	schema:register(XMLValueType.BOOL, basePath .. ".husbandry#hasStatistics", "Has statistics", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".husbandry.production#threshold", "Threshold for production increase", 0.5)
	schema:register(XMLValueType.FLOAT, basePath .. ".husbandry.production#increasePerHour", "Production increase if production factor bigger then threshold", 0.1)
	schema:register(XMLValueType.FLOAT, basePath .. ".husbandry.production#decreasePerHour", "Production increase if production factor less then threshold", 0.2)
	UnloadingStation.registerXMLPaths(schema, basePath .. ".husbandry.unloadingStation")
	Storage.registerXMLPaths(schema, basePath .. ".husbandry.storage")
	LoadingStation.registerXMLPaths(schema, basePath .. ".husbandry.loadingStation")
	schema:setXMLSpecializationType()
end

function PlaceableHusbandry.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")
	schema:register(XMLValueType.STRING, basePath .. ".module(?)#name", "Name of module")
	schema:register(XMLValueType.FLOAT, basePath .. "#globalProductionFactor", "Global production factor")
	schema:register(XMLValueType.FLOAT, basePath .. "#productionFactor", "Production factor")
	Storage.registerSavegameXMLPaths(schema, basePath .. ".storage")
	schema:setXMLSpecializationType()
end

-- Local values: spec, xmlFile
function PlaceableHusbandry:onLoad(savegame)
	local v10_ = self.spec_husbandry
	local v11_ = self.xmlFile
	v10_.fillLevelChangedListener = {}
	v10_.targetStorages = {}
	v10_.hideFromPricesMenu = true
	v10_.globalProductionFactor = 0
	v10_.productionFactor = 0
	v10_.husbandryDirtyFlag = self:getNextDirtyFlag()
	if v11_:hasProperty("placeable.husbandry.unloadingStation") then
		v10_.unloadingStation = UnloadingStation.new(self.isServer, self.isClient)
		if not v10_.unloadingStation:load(self.components, v11_, "placeable.husbandry.unloadingStation", self.customEnvironment, self.i3dMappings, self.components[1].node) then
			v10_.unloadingStation:delete()
			Logging.xmlError(v11_, "Failed to load unloading station")
			self:setLoadingState(PlaceableLoadingState.ERROR)
			return
		end
		v10_.unloadingStation.owningPlaceable = self
		v10_.unloadingStation.hasStoragePerFarm = false
	end
	if v11_:hasProperty("placeable.husbandry.storage") then
		v10_.storage = Storage.new(self.isServer, self.isClient)
		if not v10_.storage:load(self.components, v11_, "placeable.husbandry.storage", self.i3dMappings, self.baseDirectory) then
			v10_.storage:delete()
			Logging.xmlError(v11_, "Failed to load storage")
			self:setLoadingState(PlaceableLoadingState.ERROR)
			return
		end
	end
	if v11_:hasProperty("placeable.husbandry.loadingStation") then
		v10_.loadingStation = LoadingStation.new(self.isServer, self.isClient)
		if not v10_.loadingStation:load(self.components, v11_, "placeable.husbandry.loadingStation", self.customEnvironment, self.i3dMappings, self.components[1].node) then
			v10_.loadingStation:delete()
			Logging.xmlError(v11_, "Failed to load loading station")
			self:setLoadingState(PlaceableLoadingState.ERROR)
			return
		end
		v10_.loadingStation.owningPlaceable = self
		v10_.loadingStation.hasStoragePerFarm = false
	end
	function v10_.fillLevelChangedCallback(p12_, p13_)
		-- upvalues: (copy) self
		SpecializationUtil.raiseEvent(self, "onHusbandryFillLevelChanged", p12_, p13_)
	end
	local v14_ = v11_:getValue("placeable.husbandry.production#threshold", 0.25)
	local v15_ = math.abs(v14_)
	v10_.productionThreshold = math.clamp(v15_, 0.01, 0.99)
	local v16_ = v11_:getValue("placeable.husbandry.production#increasePerHour", 0.1)
	v10_.productionChangePerHourIncrease = math.abs(v16_)
	local v17_ = v11_:getValue("placeable.husbandry.production#decreasePerHour", 0.2)
	v10_.productionChangePerHourDecrease = math.abs(v17_)
	v10_.dirtyFlag = self:getNextDirtyFlag()
end

-- Local values: spec, storageSystem
function PlaceableHusbandry:onDelete()
	local v19_ = self.spec_husbandry
	local v20_ = g_currentMission.storageSystem
	if v19_.unloadingStation ~= nil then
		v20_:removeStorageFromUnloadingStations(v19_.storage, { v19_.unloadingStation })
		v20_:removeUnloadingStation(v19_.unloadingStation, self)
		v19_.unloadingStation:delete()
		v19_.unloadingStation = nil
	end
	if v19_.loadingStation ~= nil then
		if v19_.loadingStation:getIsFillTypeSupported(FillType.LIQUIDMANURE) then
			g_currentMission:removeLiquidManureLoadingStation(v19_.loadingStation)
		end
		v20_:removeStorageFromLoadingStations(v19_.storage, { v19_.loadingStation })
		v20_:removeLoadingStation(v19_.loadingStation, self)
		v19_.loadingStation:delete()
		v19_.loadingStation = nil
	end
	if v19_.storage ~= nil then
		v20_:removeStorage(v19_.storage)
		v19_.storage:delete()
		v19_.storage = nil
	end
	g_messageCenter:unsubscribe(MessageType.STORAGE_ADDED_TO_LOADING_STATION, self)
	g_messageCenter:unsubscribe(MessageType.STORAGE_REMOVED_FROM_LOADING_STATION, self)
	g_messageCenter:unsubscribe(MessageType.STORAGE_ADDED_TO_UNLOADING_STATION, self)
	g_messageCenter:unsubscribe(MessageType.STORAGE_REMOVED_FROM_UNLOADING_STATION, self)
	g_currentMission.husbandrySystem:removePlaceable(self)
end

-- Local values: spec, storage, unloadingStation, storageSystem, loadingStation, farmId, newFarmId, storagesInRange, _, storageInRange
function PlaceableHusbandry:onFinalizePlacement()
	local v22_ = self.spec_husbandry
	g_messageCenter:subscribe(MessageType.STORAGE_ADDED_TO_LOADING_STATION, self.onAddedStorageToLoadingStation, self)
	g_messageCenter:subscribe(MessageType.STORAGE_REMOVED_FROM_LOADING_STATION, self.onRemovedStorageFromLoadingStation, self)
	g_messageCenter:subscribe(MessageType.STORAGE_ADDED_TO_UNLOADING_STATION, self.onAddedStorageToUnloadingStation, self)
	g_messageCenter:subscribe(MessageType.STORAGE_REMOVED_FROM_UNLOADING_STATION, self.onRemovedStorageFromUnloadingStation, self)
	local v23_ = v22_.storage
	local v24_ = v22_.unloadingStation
	local v25_ = g_currentMission.storageSystem
	local v26_ = v22_.loadingStation
	local v27_ = self:getOwnerFarmId()
	local v28_
	if v27_ == AccessHandler.EVERYONE then
		v28_ = AccessHandler.NOBODY
	else
		v28_ = v27_
	end
	if v26_ ~= nil then
		v26_:setOwnerFarmId(v28_, true)
		v26_:register(true)
		v25_:addLoadingStation(v26_, self)
		if v26_:getIsFillTypeSupported(FillType.LIQUIDMANURE) then
			g_currentMission:addLiquidManureLoadingStation(v26_)
		end
	end
	if v24_ ~= nil then
		v24_:setOwnerFarmId(v28_, true)
		v24_:register(true)
		v25_:addUnloadingStation(v24_, self)
	end
	if v23_ ~= nil then
		v23_:setOwnerFarmId(v28_, true)
		v23_:register(true)
		v25_:addStorage(v23_)
		if v24_ ~= nil then
			v25_:addStorageToUnloadingStation(v23_, v24_)
		end
		if v26_ ~= nil then
			v25_:addStorageToLoadingStation(v23_, v26_)
		end
	end
	if v28_ ~= AccessHandler.NOBODY and v24_ ~= nil then
		local v29_ = v25_:getStorageExtensionsInRange(v24_, v27_)
		for _, v30_ in ipairs(v29_) do
			if v24_.targetStorages[v30_] == nil then
				v25_:addStorageToUnloadingStation(v30_, v24_)
			end
			if v26_ ~= nil and v26_.sourceStorages[v30_] == nil then
				v25_:addStorageToLoadingStation(v30_, v26_)
			end
		end
	end
	g_currentMission.husbandrySystem:addPlaceable(self)
end

-- Local values: spec, unloadingStationId, loadingStationId, storageId
function PlaceableHusbandry:onReadStream(streamId, connection)
	local v34_ = self.spec_husbandry
	if v34_.unloadingStation ~= nil then
		local v35_ = NetworkUtil.readNodeObjectId(streamId)
		v34_.unloadingStation:readStream(streamId, connection)
		g_client:finishRegisterObject(v34_.unloadingStation, v35_)
	end
	if v34_.loadingStation ~= nil then
		local v36_ = NetworkUtil.readNodeObjectId(streamId)
		v34_.loadingStation:readStream(streamId, connection)
		g_client:finishRegisterObject(v34_.loadingStation, v36_)
	end
	if v34_.storage ~= nil then
		local v37_ = NetworkUtil.readNodeObjectId(streamId)
		v34_.storage:readStream(streamId, connection)
		g_client:finishRegisterObject(v34_.storage, v37_)
	end
	v34_.globalProductionFactor = streamReadUInt8(streamId) / 255
	v34_.productionFactor = streamReadUInt8(streamId) / 255
end

-- Local values: spec
function PlaceableHusbandry:onWriteStream(streamId, connection)
	local v41_ = self.spec_husbandry
	if v41_.unloadingStation ~= nil then
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v41_.unloadingStation))
		v41_.unloadingStation:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, v41_.unloadingStation)
	end
	if v41_.loadingStation ~= nil then
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v41_.loadingStation))
		v41_.loadingStation:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, v41_.loadingStation)
	end
	if v41_.storage ~= nil then
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v41_.storage))
		v41_.storage:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, v41_.storage)
	end
	streamWriteUInt8(streamId, MathUtil.round(v41_.globalProductionFactor * 255))
	streamWriteUInt8(streamId, MathUtil.round(v41_.productionFactor * 255))
end

-- Local values: spec
function PlaceableHusbandry:onReadUpdateStream(streamId, connection)
	local v44_ = self.spec_husbandry
	v44_.globalProductionFactor = streamReadUInt8(streamId) / 100
	v44_.productionFactor = streamReadUInt8(streamId) / 100
end

-- Local values: spec
function PlaceableHusbandry:onWriteUpdateStream(streamId, connection)
	local v47_ = self.spec_husbandry
	streamWriteUInt8(streamId, MathUtil.round(v47_.globalProductionFactor * 100))
	streamWriteUInt8(streamId, MathUtil.round(v47_.productionFactor * 100))
end

-- Local values: spec
function PlaceableHusbandry:saveToXMLFile(xmlFile, key, usedModNames)
	local v52_ = self.spec_husbandry
	if v52_.storage ~= nil then
		v52_.storage:saveToXMLFile(xmlFile, key .. ".storage", usedModNames)
	end
	xmlFile:setValue(key .. "#globalProductionFactor", v52_.globalProductionFactor)
	xmlFile:setValue(key .. "#productionFactor", v52_.productionFactor)
end

-- Local values: spec
function PlaceableHusbandry:loadFromXMLFile(xmlFile, key)
	local v56_ = self.spec_husbandry
	if v56_.storage ~= nil then
		v56_.storage:loadFromXMLFile(xmlFile, key .. ".storage")
	end
	v56_.globalProductionFactor = xmlFile:getValue(key .. "#globalProductionFactor", v56_.globalProductionFactor)
	v56_.productionFactor = xmlFile:getValue(key .. "#productionFactor", v56_.productionFactor)
end

-- Local values: spec, newFarmId, loadingStation, unloadingStation, storageSystem, storagesInRange, _, storageInRange
function PlaceableHusbandry:setOwnerFarmId(superFunc, farmId, noEventSend)
	local v61_ = self.spec_husbandry
	superFunc(self, farmId, noEventSend)
	local v62_
	if farmId == AccessHandler.EVERYONE then
		v62_ = AccessHandler.NOBODY
	else
		v62_ = farmId
	end
	if v61_.storage ~= nil then
		v61_.storage:setOwnerFarmId(v62_, true)
	end
	local v63_ = v61_.loadingStation
	if v63_ ~= nil then
		v63_:setOwnerFarmId(v62_, true)
	end
	local v64_ = v61_.unloadingStation
	if v64_ ~= nil then
		v64_:setOwnerFarmId(v62_, true)
	end
	if v62_ ~= AccessHandler.NOBODY and v64_ ~= nil then
		local v65_ = g_currentMission.storageSystem
		local v66_ = v65_:getStorageExtensionsInRange(v64_, farmId)
		for _, v67_ in ipairs(v66_) do
			if v64_.targetStorages[v67_] == nil then
				v65_:addStorageToUnloadingStation(v67_, v64_)
			end
			if v63_ ~= nil and v63_.sourceStorages[v67_] == nil then
				v65_:addStorageToLoadingStation(v67_, v63_)
			end
		end
	end
end

-- Local values: spec, _, unloadTrigger, _, loadTrigger
function PlaceableHusbandry:collectPickObjects(superFunc, node, target)
	local v72_ = self.spec_husbandry
	if v72_.unloadingStation ~= nil then
		for _, v73_ in ipairs(v72_.unloadingStation.unloadTriggers) do
			if node == v73_.exactFillRootNode then
				return
			end
		end
	end
	if v72_.loadingStation ~= nil then
		for _, v74_ in ipairs(v72_.loadingStation.loadTriggers) do
			if node == v74_.triggerNode then
				return
			end
		end
	end
	superFunc(self, node, target)
end

function PlaceableHusbandry:getCanBePlacedAt(superFunc, x, y, z, farmId)
	if g_currentMission.husbandrySystem:getLimitReached() then
		return false, g_i18n:getText("warning_tooManyHusbandries")
	else
		return superFunc(self, x, y, z)
	end
end

function PlaceableHusbandry:canBuy(superFunc)
	if g_currentMission.husbandrySystem:getLimitReached() then
		return false, g_i18n:getText("warning_tooManyHusbandries")
	else
		return superFunc(self)
	end
end

-- Local values: spec, foodFactor, productionFactor, factor, changePerHour, delta
function PlaceableHusbandry:onHourChanged(currentHour)
	if self.isServer then
		local v83_ = self.spec_husbandry
		local v84_ = self:updateFeeding()
		SpecializationUtil.raiseEvent(self, "onFinishedFeeding")
		local v85_ = self:updateProduction(v84_)
		local v86_, v87_
		if v83_.productionThreshold < v85_ then
			v86_ = (v85_ - v83_.productionThreshold) / (1 - v83_.productionThreshold)
			v87_ = v83_.productionChangePerHourIncrease
		else
			v86_ = v85_ / v83_.productionThreshold - 1
			v87_ = v83_.productionChangePerHourDecrease
		end
		local v88_ = v87_ * v86_
		local v89_ = v83_.globalProductionFactor + v88_
		v83_.globalProductionFactor = math.clamp(v89_, 0, 1)
		self:updateOutput(v84_, v85_, v83_.globalProductionFactor)
		self:raiseDirtyFlags(v83_.dirtyFlag)
	end
end

-- Local values: spec, unloadingStation, storageSystem, loadingStation, storagesInRange, _, storageInRange
function PlaceableHusbandry:onBuy()
	local v91_ = self.spec_husbandry
	local v92_ = v91_.unloadingStation
	local v93_ = g_currentMission.storageSystem
	local v94_ = v91_.loadingStation
	if v92_ ~= nil then
		local v95_ = v93_:getStorageExtensionsInRange(v92_, self:getOwnerFarmId())
		for _, v96_ in ipairs(v95_) do
			if v92_.targetStorages[v96_] == nil then
				v93_:addStorageToUnloadingStation(v96_, v92_)
			end
			if v94_ ~= nil and v94_.sourceStorages[v96_] == nil then
				v93_:addStorageToLoadingStation(v96_, v94_)
			end
		end
	end
end

function PlaceableHusbandry:getNeedHourChanged(superFunc)
	return true
end

function PlaceableHusbandry.updateFeeding(self)
	return 1
end

-- Local values: spec
function PlaceableHusbandry:updateProduction(foodFactor)
	self.spec_husbandry.productionFactor = foodFactor
	return foodFactor
end

function PlaceableHusbandry:updateOutput(foodFactor, productionFactor, globalProductionFactor) end

-- Local values: spec
function PlaceableHusbandry:getGlobalProductionFactor()
	return self.spec_husbandry.globalProductionFactor
end

-- Local values: spec
function PlaceableHusbandry:getProductionFactor()
	return self.spec_husbandry.productionFactor
end

function PlaceableHusbandry:getConditionInfos()
	return {}
end

function PlaceableHusbandry:getFoodInfos()
	return {}
end

function PlaceableHusbandry:getAnimalInfos()
	return {}
end

function PlaceableHusbandry:getAnimalDescription(cluster)
	return ""
end

-- Local values: spec
function PlaceableHusbandry:getHusbandryCapacity(fillTypeIndex, farmId)
	local v104_ = self.spec_husbandry
	return v104_.unloadingStation == nil and 0 or v104_.unloadingStation:getCapacity(fillTypeIndex, farmId or self:getOwnerFarmId())
end

-- Local values: spec
function PlaceableHusbandry:getHusbandryFreeCapacity(fillTypeIndex, farmId)
	local v108_ = self.spec_husbandry
	return v108_.unloadingStation == nil and 0 or v108_.unloadingStation:getFreeCapacity(fillTypeIndex, farmId or self:getOwnerFarmId())
end

-- Local values: spec
function PlaceableHusbandry:addHusbandryFillLevelFromTool(farmId, deltaFillLevel, fillTypeIndex, fillPositionData, toolType, extraAttributes)
	local v116_ = self.spec_husbandry
	return v116_.unloadingStation == nil and 0 or v116_.unloadingStation:addFillLevelFromTool(farmId or self:getOwnerFarmId(), deltaFillLevel, fillTypeIndex, fillPositionData, toolType, extraAttributes)
end

-- Local values: spec
function PlaceableHusbandry:removeHusbandryFillLevel(farmId, deltaFillLevel, fillTypeIndex)
	local v121_ = self.spec_husbandry
	if v121_.loadingStation == nil then
		return deltaFillLevel
	else
		return v121_.loadingStation:removeFillLevel(fillTypeIndex, deltaFillLevel, farmId or self:getOwnerFarmId())
	end
end

-- Local values: spec
function PlaceableHusbandry:getHusbandryFillLevel(fillTypeIndex, farmId)
	local v125_ = self.spec_husbandry
	return v125_.unloadingStation == nil and 0 or v125_.unloadingStation:getFillLevel(fillTypeIndex, farmId or self:getOwnerFarmId())
end

-- Local values: spec
function PlaceableHusbandry:getHusbandryIsFillTypeSupported(fillTypeIndex)
	local v128_ = self.spec_husbandry
	if v128_.unloadingStation == nil then
		return false
	else
		return v128_.unloadingStation:getIsFillTypeSupported(fillTypeIndex)
	end
end

-- Local values: spec
function PlaceableHusbandry:onAddedStorageToLoadingStation(storage, loadingStation)
	local v132_ = self.spec_husbandry
	if v132_.loadingStation ~= nil and v132_.loadingStation == loadingStation then
		storage:addFillLevelChangedListeners(v132_.fillLevelChangedCallback)
	end
end

-- Local values: spec
function PlaceableHusbandry:onRemovedStorageFromLoadingStation(storage, loadingStation)
	local v136_ = self.spec_husbandry
	if v136_.loadingStation ~= nil and v136_.loadingStation == loadingStation then
		storage:removeFillLevelChangedListeners(v136_.fillLevelChangedCallback)
	end
end

-- Local values: spec
function PlaceableHusbandry:onAddedStorageToUnloadingStation(storage, unloadingStation)
	local v140_ = self.spec_husbandry
	if v140_.unloadingStation ~= nil and v140_.unloadingStation == unloadingStation then
		storage:addFillLevelChangedListeners(v140_.fillLevelChangedCallback)
	end
end

-- Local values: spec
function PlaceableHusbandry:onRemovedStorageFromUnloadingStation(storage, unloadingStation)
	local v144_ = self.spec_husbandry
	if v144_.unloadingStation ~= nil and v144_.unloadingStation == unloadingStation then
		storage:removeFillLevelChangedListeners(v144_.fillLevelChangedCallback)
	end
end
