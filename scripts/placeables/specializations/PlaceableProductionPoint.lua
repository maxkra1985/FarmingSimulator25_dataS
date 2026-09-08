PlaceableProductionPoint = {}

function PlaceableProductionPoint.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(PlaceableInfoTrigger, specializations)
end

function PlaceableProductionPoint.registerEvents(placeableType)
	SpecializationUtil.registerEvent(placeableType, "onOutputFillTypesChanged")
	SpecializationUtil.registerEvent(placeableType, "onProductionStatusChanged")
end

function PlaceableProductionPoint.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "outputsChanged", PlaceableProductionPoint.outputsChanged)
	SpecializationUtil.registerFunction(placeableType, "productionStatusChanged", PlaceableProductionPoint.productionStatusChanged)
end

function PlaceableProductionPoint.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableProductionPoint.setOwnerFarmId)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableProductionPoint.collectPickObjects)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "canBuy", PlaceableProductionPoint.canBuy)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableProductionPoint.updateInfo)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "finalizeConstruction", PlaceableProductionPoint.finalizeConstruction)
end

function PlaceableProductionPoint.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableProductionPoint)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableProductionPoint)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableProductionPoint)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableProductionPoint)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableProductionPoint)
	SpecializationUtil.registerEventListener(placeableType, "onBuy", PlaceableProductionPoint)
end

-- Local values: registerPlaceableSchema, schema, basePath, schema, basePath
function PlaceableProductionPoint.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("ProductionPoint")
	ProductionPoint.registerXMLPaths(schema, basePath .. ".productionPoint")
	local v8_ = basePath .. ".productionPoint"
	schema:register(XMLValueType.BOOL, v8_ .. "#isFinalized", "If the production point is finalized and ready on start. E.g. constructible")
	ProductionPoint.registerXMLPaths(schema, basePath .. ".productionPoint.productionPointConfigurations.productionPointConfiguration(?).productionPoint")
	local v9_ = basePath .. ".productionPoint.productionPointConfigurations.productionPointConfiguration(?).productionPoint"
	schema:register(XMLValueType.BOOL, v9_ .. "#isFinalized", "If the production point is finalized and ready on start. E.g. constructible")
	schema:setXMLSpecializationType()
end

function PlaceableProductionPoint.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("ProductionPoint")
	ProductionPoint.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType()
end
function PlaceableProductionPoint.initSpecialization()
	g_storeManager:addSpecType("prodPointInputFillTypes", "shopListAttributeIconInput", ProductionPoint.loadSpecValueInputFillTypes, ProductionPoint.getSpecValueInputFillTypes, StoreSpecies.PLACEABLE)
	g_storeManager:addSpecType("prodPointOutputFillTypes", "shopListAttributeIconOutput", ProductionPoint.loadSpecValueOutputFillTypes, ProductionPoint.getSpecValueOutputFillTypes, StoreSpecies.PLACEABLE)
	g_placeableConfigurationManager:addConfigurationType("productionPoint", g_i18n:getText("configuration_productionPoint"), "productionPoint", PlaceableConfigurationItem)
end

-- Local values: spec, productionPointConfigurationId, configKey, productionPoint
function PlaceableProductionPoint:onLoad(savegame)
	local v13_ = self.spec_productionPoint
	local v14_ = Utils.getNoNil(self.configurations.productionPoint, 1)
	local v15_ = string.format("placeable.productionPoint.productionPointConfigurations.productionPointConfiguration(%d).productionPoint", v14_ - 1)
	local v16_ = not self.xmlFile:hasProperty(v15_) and "placeable.productionPoint" or v15_
	local v17_ = ProductionPoint.new(self.isServer, self.isClient, self.baseDirectory)
	v17_.owningPlaceable = self
	if v17_:load(self.components, self.xmlFile, v16_, self.customEnvironment, self.i3dMappings) then
		v13_.productionPoint = v17_
		v13_.isFinalized = self.xmlFile:getBool(v16_ .. "#isFinalized", true)
		if not v13_.isFinalized then
			v17_.isFinalized = false
			v17_.unloadingStation.hideFromPricesMenu = true
			v13_.unloadingStationDefaultAllowMissions = v17_.unloadingStation.allowMissions
			v17_.unloadingStation.allowMissions = false
			return
		end
	else
		v17_:delete()
		self:setLoadingState(PlaceableLoadingState.ERROR)
	end
end

-- Local values: spec
function PlaceableProductionPoint:onDelete()
	local v19_ = self.spec_productionPoint
	if v19_.productionPoint ~= nil then
		v19_.productionPoint:delete()
		v19_.productionPoint = nil
	end
end

-- Local values: spec, owner
function PlaceableProductionPoint:onFinalizePlacement()
	local v21_ = self.spec_productionPoint
	if v21_.productionPoint ~= nil then
		if self.getHasBuyingTrigger ~= nil and self:getHasBuyingTrigger() then
			v21_.productionPoint.useInteractionTriggerForBuying = false
		end
		v21_.productionPoint:register(true)
		local v22_ = self:getOwnerFarmId()
		if not v21_.isFinalized then
			v22_ = AccessHandler.EVERYONE
		end
		v21_.productionPoint:setOwnerFarmId(v22_)
		v21_.productionPoint:findStorageExtensions()
		v21_.productionPoint:updateFxState()
	end
end

function PlaceableProductionPoint:updateInfo(superFunc, infoTable)
	superFunc(self, infoTable)
	self.spec_productionPoint.productionPoint:updateInfo(infoTable)
end

function PlaceableProductionPoint:outputsChanged(outputs, state)
	SpecializationUtil.raiseEvent(self, "onOutputFillTypesChanged", outputs, state)
end

function PlaceableProductionPoint:productionStatusChanged(production, status)
	SpecializationUtil.raiseEvent(self, "onProductionStatusChanged", production, status)
end

-- Local values: spec, productionPointId
function PlaceableProductionPoint:onReadStream(streamId, connection)
	local v35_ = self.spec_productionPoint
	if v35_.productionPoint ~= nil then
		local v36_ = NetworkUtil.readNodeObjectId(streamId)
		v35_.productionPoint:readStream(streamId, connection)
		g_client:finishRegisterObject(v35_.productionPoint, v36_)
	end
end

-- Local values: spec
function PlaceableProductionPoint:onWriteStream(streamId, connection)
	local v40_ = self.spec_productionPoint
	if v40_.productionPoint ~= nil then
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v40_.productionPoint))
		v40_.productionPoint:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, v40_.productionPoint)
	end
end

-- Local values: spec
function PlaceableProductionPoint:loadFromXMLFile(xmlFile, key)
	local v44_ = self.spec_productionPoint
	if v44_.productionPoint ~= nil then
		v44_.productionPoint:loadFromXMLFile(xmlFile, key)
	end
end

-- Local values: spec
function PlaceableProductionPoint:saveToXMLFile(xmlFile, key, usedModNames)
	local v49_ = self.spec_productionPoint
	if v49_.productionPoint ~= nil then
		v49_.productionPoint:saveToXMLFile(xmlFile, key, usedModNames)
	end
end

-- Local values: spec, owner
function PlaceableProductionPoint:setOwnerFarmId(superFunc, farmId, noEventSend)
	superFunc(self, farmId, noEventSend)
	local v54_ = self.spec_productionPoint
	if v54_.productionPoint ~= nil then
		local v55_ = self:getOwnerFarmId()
		if not v54_.isFinalized then
			v55_ = AccessHandler.EVERYONE
		end
		v54_.productionPoint:setOwnerFarmId(v55_)
		if not v54_.isFinalized then
			g_currentMission.productionChainManager:removeProductionPoint(v54_.productionPoint)
		end
	end
end

-- Local values: spec, i, loadTrigger, i, unloadTrigger
function PlaceableProductionPoint:collectPickObjects(superFunc, node)
	local v59_ = self.spec_productionPoint
	if v59_.productionPoint.loadingStation ~= nil then
		for v60_ = 1, #v59_.productionPoint.loadingStation.loadTriggers do
			if node == v59_.productionPoint.loadingStation.loadTriggers[v60_].triggerNode then
				return
			end
		end
	end
	for v61_ = 1, #v59_.productionPoint.unloadingStation.unloadTriggers do
		if node == v59_.productionPoint.unloadingStation.unloadTriggers[v61_].exactFillRootNode then
			return
		end
	end
	superFunc(self, node)
end

function PlaceableProductionPoint:canBuy(superFunc)
	if g_currentMission.productionChainManager:getHasFreeSlots() then
		return superFunc(self)
	else
		return false, g_i18n:getText("warning_maxNumOfProdPointsReached")
	end
end

-- Local values: serverFarmId, numProductionPoints, _, existingPlaceable
function PlaceableProductionPoint:onBuy()
	local v64_ = g_currentMission:getFarmId()
	local v65_ = 0
	for _, v66_ in ipairs(g_currentMission.placeableSystem.placeables) do
		if v66_:getOwnerFarmId() == v64_ and v66_.spec_productionPoint ~= nil then
			v65_ = v65_ + 1
		end
	end
	g_achievementManager:tryUnlock("NumProductionPoints", v65_)
end

-- Local values: spec
function PlaceableProductionPoint:finalizeConstruction(superFunc)
	superFunc(self)
	local v69_ = self.spec_productionPoint
	if v69_.productionPoint ~= nil then
		v69_.isFinalized = true
		v69_.productionPoint.isFinalized = true
		v69_.productionPoint:setOwnerFarmId(self:getOwnerFarmId(), true)
		v69_.productionPoint.unloadingStation.hideFromPricesMenu = false
		v69_.productionPoint.unloadingStation.allowMissions = v69_.unloadingStationDefaultAllowMissions
	end
end
