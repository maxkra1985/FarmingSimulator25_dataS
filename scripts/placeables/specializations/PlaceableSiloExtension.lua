PlaceableSiloExtension = {}
PlaceableSiloExtension.PRICE_SELL_FACTOR = 0.6

function PlaceableSiloExtension.prerequisitesPresent(specializations)
	return true
end

function PlaceableSiloExtension.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableSiloExtension.setOwnerFarmId)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getCanBePlacedAt", PlaceableSiloExtension.getCanBePlacedAt)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "canBeSold", PlaceableSiloExtension.canBeSold)
end

function PlaceableSiloExtension.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableSiloExtension)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableSiloExtension)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableSiloExtension)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableSiloExtension)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableSiloExtension)
	SpecializationUtil.registerEventListener(placeableType, "onSell", PlaceableSiloExtension)
end

function PlaceableSiloExtension.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("SiloExtension")
	schema:register(XMLValueType.BOOL, basePath .. ".siloExtension.storage#foreignSilo", "Shows as foreign silo in the menu", false)
	schema:register(XMLValueType.L10N_STRING, basePath .. ".siloExtension#nearSiloWarning", "Warning that is shown if extension is not placed near another silo")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".siloExtension.storage#node", "Storage node")
	Storage.registerXMLPaths(schema, basePath .. ".siloExtension.storage")
	schema:setXMLSpecializationType()
end

function PlaceableSiloExtension.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("SiloExtension")
	Storage.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType()
end
function PlaceableSiloExtension.initSpecialization()
	g_storeManager:addSpecType("siloExtensionVolume", "shopListAttributeIconCapacity", PlaceableSiloExtension.loadSpecValueVolume, PlaceableSiloExtension.getSpecValueVolume, StoreSpecies.PLACEABLE)
end

-- Local values: spec, xmlFile, storageKey
function PlaceableSiloExtension:onLoad(savegame)
	local v8_ = self.spec_siloExtension
	local v9_ = self.xmlFile
	v8_.foreignSilo = v9_:getValue("placeable.siloExtension.storage#foreignSilo", false)
	if v9_:hasProperty("placeable.siloExtension.storage") then
		v8_.storage = Storage.new(self.isServer, self.isClient)
		v8_.storage:load(self.components, v9_, "placeable.siloExtension.storage", self.i3dMappings, self.baseDirectory)
		v8_.storage.foreignSilo = v8_.foreignSilo
	else
		Logging.xmlWarning(v9_, "Missing \'storage\' for siloExtension!")
	end
	v8_.nearSiloWarning = v9_:getValue("placeable.siloExtension#nearSiloWarning", "warning_siloExtensionNotNearSilo", self.customEnvironment)
end

-- Local values: spec, storageSystem
function PlaceableSiloExtension:onDelete()
	local v11_ = self.spec_siloExtension
	if v11_.storage ~= nil then
		local v12_ = g_currentMission.storageSystem
		if v12_:hasStorage(v11_.storage) then
			v12_:removeStorageFromUnloadingStations(v11_.storage, v11_.storage.unloadingStations)
			v12_:removeStorageFromLoadingStations(v11_.storage, v11_.storage.loadingStations)
			v12_:removeStorage(v11_.storage)
		end
		v11_.storage:delete()
	end
end

-- Local values: spec, storageSystem, ownerFarmId, lastFoundUnloadingStations, lastFoundLoadingStations
function PlaceableSiloExtension:onFinalizePlacement()
	local v14_ = self.spec_siloExtension
	if v14_.storage ~= nil then
		local v15_ = g_currentMission.storageSystem
		local v16_ = self:getOwnerFarmId()
		local v17_ = v15_:getExtendableUnloadingStationsInRange(v14_.storage, v16_)
		local v18_ = v15_:getExtendableLoadingStationsInRange(v14_.storage, v16_)
		v14_.storage:setOwnerFarmId(self:getOwnerFarmId(), true)
		v15_:addStorage(v14_.storage)
		v14_.storage:register(true)
		v15_:addStorageToUnloadingStations(v14_.storage, v17_)
		v15_:addStorageToLoadingStations(v14_.storage, v18_)
	end
end

-- Local values: spec, storageId
function PlaceableSiloExtension:onReadStream(streamId, connection)
	local v22_ = self.spec_siloExtension
	if v22_.storage ~= nil then
		local v23_ = NetworkUtil.readNodeObjectId(streamId)
		v22_.storage:readStream(streamId, connection)
		g_client:finishRegisterObject(v22_.storage, v23_)
	end
end

-- Local values: spec
function PlaceableSiloExtension:onWriteStream(streamId, connection)
	local v27_ = self.spec_siloExtension
	if v27_.storage ~= nil then
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v27_.storage))
		v27_.storage:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, v27_.storage)
	end
end

-- Local values: canBePlaced, errorMessage, spec, storageSystem
function PlaceableSiloExtension:getCanBePlacedAt(superFunc, x, y, z, farmId)
	local v34_, v35_ = superFunc(self, x, y, z, farmId)
	if v34_ then
		local v36_ = self.spec_siloExtension
		if v36_.storage == nil then
			return false
		else
			v36_.lastFoundUnloadingStations = nil
			v36_.lastFoundLoadingStations = nil
			local v37_ = g_currentMission.storageSystem
			v36_.lastFoundUnloadingStations = v37_:getExtendableUnloadingStationsInRange(v36_.storage, farmId, x, y, z)
			v36_.lastFoundLoadingStations = v37_:getExtendableLoadingStationsInRange(v36_.storage, farmId, x, y, z)
			if #v36_.lastFoundUnloadingStations == 0 and #v36_.lastFoundLoadingStations == 0 then
				return false, v36_.nearSiloWarning
			else
				return true
			end
		end
	else
		return false, v35_
	end
end

-- Local values: spec, warning, totalFillLevel, fillTypeIndex, fillLevel, lowestSellPrice, _, unloadingStation, price, price, fillType
function PlaceableSiloExtension:canBeSold(superFunc)
	local v39_ = self.spec_siloExtension
	if v39_.storage == nil then
		return true, nil
	else
		local v40_ = g_i18n:getText("info_siloExtensionNotEmpty") .. "\n"
		v39_.totalFillTypeSellPrice = 0
		local v41_ = 0
		for v42_, v43_ in pairs(v39_.storage.fillLevels) do
			v41_ = v41_ + v43_
			if v43_ > 0 then
				local v44_ = math.huge
				for _, v45_ in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
					if v45_.owningPlaceable ~= nil and (v45_.isSellingPoint and v45_.acceptedFillTypes[v42_]) then
						local v46_ = v45_:getEffectiveFillTypePrice(v42_)
						if v46_ > 0 then
							v44_ = math.min(v44_, v46_)
						end
					end
				end
				local v47_ = v43_ * (v44_ == math.huge and 0.5 or v44_) * PlaceableSiloExtension.PRICE_SELL_FACTOR
				local v48_ = g_fillTypeManager:getFillTypeByIndex(v42_)
				v40_ = string.format("%s%s (%d %s) - %s: %s\n", v40_, v48_.title, g_i18n:getFluid(v43_), g_i18n:getText("unit_literShort"), g_i18n:getText("ui_sellValue"), g_i18n:formatMoney(v47_, 0, true, true))
				v39_.totalFillTypeSellPrice = v39_.totalFillTypeSellPrice + v47_
			end
		end
		if v41_ > 0 then
			return true, v40_
		else
			return true, nil
		end
	end
end

-- Local values: spec
function PlaceableSiloExtension:loadFromXMLFile(xmlFile, key)
	local v52_ = self.spec_siloExtension
	if v52_.storage ~= nil then
		v52_.storage:loadFromXMLFile(xmlFile, key)
	end
end

-- Local values: spec
function PlaceableSiloExtension:saveToXMLFile(xmlFile, key, usedModNames)
	local v57_ = self.spec_siloExtension
	if v57_.storage ~= nil then
		v57_.storage:saveToXMLFile(xmlFile, key, usedModNames)
	end
end

-- Local values: spec
function PlaceableSiloExtension:setOwnerFarmId(superFunc, farmId, noEventSend)
	local v62_ = self.spec_siloExtension
	superFunc(self, farmId, noEventSend)
	if self.isServer and v62_.storage ~= nil then
		v62_.storage:setOwnerFarmId(farmId, true)
	end
end

-- Local values: spec
function PlaceableSiloExtension:onSell()
	local v64_ = self.spec_siloExtension
	if self.isServer and v64_.totalFillTypeSellPrice > 0 then
		g_currentMission:addMoney(v64_.totalFillTypeSellPrice, self:getOwnerFarmId(), MoneyType.HARVEST_INCOME, true, true)
	end
end

function PlaceableSiloExtension.loadSpecValueVolume(xmlFile, customEnvironment, baseDir)
	return xmlFile:getValue("placeable.siloExtension.storage#capacity")
end

function PlaceableSiloExtension.getSpecValueVolume(storeItem, realItem)
	if storeItem.specs.siloExtensionVolume == nil then
		return nil
	else
		return g_i18n:formatVolume(storeItem.specs.siloExtensionVolume)
	end
end
