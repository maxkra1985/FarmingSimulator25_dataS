-- Local values: PlaceableSiloActivatable_mt, PlaceableSiloRefillEvent_mt
PlaceableSilo = {}
PlaceableSilo.PRICE_SELL_FACTOR = 0.7
PlaceableSilo.REFILL_PRICE_FACTOR = 1.1
PlaceableSilo.INFO_TRIGGER_NUM_DISPLAYED_FILLTYPES = 6

function PlaceableSilo.prerequisitesPresent(specializations)
	return true
end

function PlaceableSilo.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableSilo.collectPickObjects)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableSilo.setOwnerFarmId)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "canBeSold", PlaceableSilo.canBeSold)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableSilo.updateInfo)
end

function PlaceableSilo.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "setAmount", PlaceableSilo.setAmount)
	SpecializationUtil.registerFunction(placeableType, "refillAmount", PlaceableSilo.refillAmount)
	SpecializationUtil.registerFunction(placeableType, "getFillLevels", PlaceableSilo.getFillLevels)
	SpecializationUtil.registerFunction(placeableType, "onPlayerActionTriggerCallback", PlaceableSilo.onPlayerActionTriggerCallback)
end

function PlaceableSilo.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableSilo)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableSilo)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableSilo)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableSilo)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableSilo)
	SpecializationUtil.registerEventListener(placeableType, "onSell", PlaceableSilo)
end

function PlaceableSilo.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Silo")
	schema:register(XMLValueType.STRING, basePath .. ".silo#sellWarningText", "Sell warning text")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".silo#playerActionTrigger", "Trigger for player interaction")
	schema:register(XMLValueType.BOOL, basePath .. ".silo.storages#perFarm", "Silo is per farm", false)
	schema:register(XMLValueType.BOOL, basePath .. ".silo.storages#foreignSilo", "Shows as foreign silo in the menu", false)
	UnloadingStation.registerXMLPaths(schema, basePath .. ".silo.unloadingStation")
	LoadingStation.registerXMLPaths(schema, basePath .. ".silo.loadingStation")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".silo.storages.storage(?)#node", "Storage node")
	Storage.registerXMLPaths(schema, basePath .. ".silo.storages.storage(?)")
	schema:setXMLSpecializationType()
end

function PlaceableSilo.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Silo")
	schema:register(XMLValueType.INT, basePath .. ".storage(?)#index", "Storage index")
	Storage.registerSavegameXMLPaths(schema, basePath .. ".storage(?)")
	schema:setXMLSpecializationType()
end
function PlaceableSilo.initSpecialization()
	g_storeManager:addSpecType("siloVolume", "shopListAttributeIconCapacity", PlaceableSilo.loadSpecValueVolume, PlaceableSilo.getSpecValueVolume, StoreSpecies.PLACEABLE)
end

-- Local values: spec, xmlFile, numStorageSets, i, storageKey, j, storage
function PlaceableSilo:onLoad(savegame)
	local v9_ = self.spec_silo
	local v10_ = self.xmlFile
	v9_.playerActionTrigger = v10_:getValue("placeable.silo#playerActionTrigger", nil, self.components, self.i3dMappings)
	if v9_.playerActionTrigger ~= nil then
		v9_.activatable = PlaceableSiloActivatable.new(self)
	end
	v9_.storagePerFarm = v10_:getValue("placeable.silo.storages#perFarm", false)
	v9_.foreignSilo = v10_:getValue("placeable.silo.storages#foreignSilo", v9_.storagePerFarm)
	v9_.unloadingStation = UnloadingStation.new(self.isServer, self.isClient)
	v9_.unloadingStation:load(self.components, v10_, "placeable.silo.unloadingStation", self.customEnvironment, self.i3dMappings, self.components[1].node)
	v9_.unloadingStation.owningPlaceable = self
	v9_.unloadingStation.hasStoragePerFarm = v9_.storagePerFarm
	v9_.loadingStation = LoadingStation.new(self.isServer, self.isClient)
	v9_.loadingStation:load(self.components, v10_, "placeable.silo.loadingStation", self.customEnvironment, self.i3dMappings, self.components[1].node)
	v9_.loadingStation.owningPlaceable = self
	v9_.loadingStation.hasStoragePerFarm = v9_.storagePerFarm
	v9_.fillTypesAndLevelsAuxiliary = {}
	v9_.fillTypeToFillTypeStorageTable = {}
	v9_.infoTriggerFillTypesAndLevels = {}
	local v11_ = v9_.storagePerFarm and FarmManager.MAX_NUM_FARMS or 1
	local v12_ = not g_currentMission.missionDynamicInfo.isMultiplayer and 1 or v11_
	v9_.storages = {}
	local v13_ = 0
	while true do
		local v14_ = string.format("placeable.silo.storages.storage(%d)", v13_)
		if not v10_:hasProperty(v14_) then
			break
		end
		for v15_ = 1, v12_ do
			local v16_ = Storage.new(self.isServer, self.isClient)
			if v16_:load(self.components, v10_, v14_, self.i3dMappings, self.baseDirectory) then
				v16_.ownerFarmId = v15_
				v16_.foreignSilo = v9_.foreignSilo
				local v17_ = v9_.storages
				table.insert(v17_, v16_)
			end
		end
		v13_ = v13_ + 1
	end
	v9_.sellWarningText = g_i18n:convertText(v10_:getValue("placeable.silo#sellWarningText", "$l10n_info_siloExtensionNotEmpty"))
end

-- Local values: spec, storageSystem, _, storage, _, storage
function PlaceableSilo:onDelete()
	local v19_ = self.spec_silo
	local v20_ = g_currentMission.storageSystem
	if v19_.storages ~= nil then
		for _, v21_ in ipairs(v19_.storages) do
			if v19_.unloadingStation ~= nil then
				v20_:removeStorageFromUnloadingStations(v21_, { v19_.unloadingStation })
			end
			if v19_.loadingStation ~= nil then
				v20_:removeStorageFromLoadingStations(v21_, { v19_.loadingStation })
			end
			v21_:removeFillLevelChangedListeners(v19_.storageFilLLevelChangedCallback)
			v20_:removeStorage(v21_)
		end
		for _, v22_ in ipairs(v19_.storages) do
			v22_:delete()
		end
	end
	if v19_.unloadingStation ~= nil then
		v20_:removeUnloadingStation(v19_.unloadingStation, self)
		v19_.unloadingStation:delete()
	end
	if v19_.loadingStation ~= nil then
		if v19_.loadingStation:getIsFillTypeSupported(FillType.LIQUIDMANURE) then
			g_currentMission:removeLiquidManureLoadingStation(v19_.loadingStation)
		end
		v20_:removeLoadingStation(v19_.loadingStation, self)
		v19_.loadingStation:delete()
	end
	g_currentMission.activatableObjectsSystem:removeActivatable(v19_.activatable)
	if v19_.playerActionTrigger ~= nil then
		removeTrigger(v19_.playerActionTrigger)
	end
end

-- Local values: spec, storageSystem, _, storage, storagesInRange, _, storage, _, storage
function PlaceableSilo:onFinalizePlacement()
	local v24_ = self.spec_silo
	local v25_ = g_currentMission.storageSystem
	v24_.unloadingStation:register(true)
	v25_:addUnloadingStation(v24_.unloadingStation, self)
	if v24_.loadingStation ~= nil then
		v24_.loadingStation:register(true)
		v25_:addLoadingStation(v24_.loadingStation, self)
		if v24_.loadingStation:getIsFillTypeSupported(FillType.LIQUIDMANURE) then
			g_currentMission:addLiquidManureLoadingStation(v24_.loadingStation)
		end
	end
	for _, v26_ in ipairs(v24_.storages) do
		if not v24_.storagePerFarm then
			v26_:setOwnerFarmId(self:getOwnerFarmId(), true)
		end
		v25_:addStorage(v26_)
		v26_:register(true)
		v25_:addStorageToUnloadingStation(v26_, v24_.unloadingStation)
		v25_:addStorageToLoadingStation(v26_, v24_.loadingStation)
	end
	local v27_ = v25_:getStorageExtensionsInRange(v24_.unloadingStation, self:getOwnerFarmId())
	if v27_ ~= nil then
		for _, v28_ in ipairs(v27_) do
			if v24_.unloadingStation.targetStorages[v28_] == nil then
				v25_:addStorageToUnloadingStation(v28_, v24_.unloadingStation)
			end
		end
	end
	local v29_ = v25_:getStorageExtensionsInRange(v24_.loadingStation, self:getOwnerFarmId())
	if v29_ ~= nil then
		for _, v30_ in ipairs(v29_) do
			if v24_.loadingStation.sourceStorages[v30_] == nil then
				v25_:addStorageToLoadingStation(v30_, v24_.loadingStation)
			end
		end
	end
	if v24_.playerActionTrigger ~= nil then
		addTrigger(v24_.playerActionTrigger, "onPlayerActionTriggerCallback", self)
	end
end

-- Local values: spec, unloadingStationId, loadingStationId, _, storage, storageId
function PlaceableSilo:onReadStream(streamId, connection)
	local v34_ = self.spec_silo
	local v35_ = NetworkUtil.readNodeObjectId(streamId)
	v34_.unloadingStation:readStream(streamId, connection)
	g_client:finishRegisterObject(v34_.unloadingStation, v35_)
	local v36_ = NetworkUtil.readNodeObjectId(streamId)
	v34_.loadingStation:readStream(streamId, connection)
	g_client:finishRegisterObject(v34_.loadingStation, v36_)
	for _, v37_ in ipairs(v34_.storages) do
		local v38_ = NetworkUtil.readNodeObjectId(streamId)
		v37_:readStream(streamId, connection)
		g_client:finishRegisterObject(v37_, v38_)
	end
end

-- Local values: spec, _, storage
function PlaceableSilo:onWriteStream(streamId, connection)
	local v42_ = self.spec_silo
	NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v42_.unloadingStation))
	v42_.unloadingStation:writeStream(streamId, connection)
	g_server:registerObjectInStream(connection, v42_.unloadingStation)
	NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v42_.loadingStation))
	v42_.loadingStation:writeStream(streamId, connection)
	g_server:registerObjectInStream(connection, v42_.loadingStation)
	for _, v43_ in ipairs(v42_.storages) do
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v43_))
		v43_:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, v43_)
	end
end

-- Local values: spec, foundNode, _, unloadTrigger, _, loadTrigger
function PlaceableSilo:collectPickObjects(superFunc, node)
	local v47_ = self.spec_silo
	local v48_ = false
	for _, v49_ in ipairs(v47_.unloadingStation.unloadTriggers) do
		if node == v49_.exactFillRootNode then
			v48_ = true
			break
		end
	end
	if not v48_ then
		for _, v50_ in ipairs(v47_.loadingStation.loadTriggers) do
			if node == v50_.triggerNode then
				v48_ = true
				break
			end
		end
	end
	if not v48_ then
		superFunc(self, node)
	end
end

-- Local values: spec, warning, totalFillLevel, fillTypeIndex, fillLevel, lowestSellPrice, _, unloadingStation, price, price, fillType
function PlaceableSilo:canBeSold(superFunc)
	local v52_ = self.spec_silo
	if v52_.storagePerFarm then
		return false, nil
	else
		local v53_ = v52_.sellWarningText .. "\n"
		v52_.totalFillTypeSellPrice = 0
		local v54_ = 0
		for v55_, v56_ in pairs(v52_.storages[1].fillLevels) do
			v54_ = v54_ + v56_
			if v56_ > 0 then
				local v57_ = math.huge
				for _, v58_ in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
					if v58_.owningPlaceable ~= nil and (v58_.isSellingPoint and v58_.acceptedFillTypes[v55_]) then
						local v59_ = v58_:getEffectiveFillTypePrice(v55_)
						if v59_ > 0 then
							v57_ = math.min(v57_, v59_)
						end
					end
				end
				local v60_ = v56_ * (v57_ == math.huge and 0.5 or v57_) * PlaceableSilo.PRICE_SELL_FACTOR
				local v61_ = g_fillTypeManager:getFillTypeByIndex(v55_)
				v53_ = string.format("%s%s (%s) - %s: %s\n", v53_, v61_.title, g_i18n:formatVolume(v56_), g_i18n:getText("ui_sellValue"), g_i18n:formatMoney(v60_, 0, true, true))
				v52_.totalFillTypeSellPrice = v52_.totalFillTypeSellPrice + v60_
			end
		end
		if v54_ > 0 then
			return true, v53_
		else
			return true, nil
		end
	end
end

-- Local values: spec
function PlaceableSilo:loadFromXMLFile(xmlFile, key)
	local v_u_65_ = self.spec_silo
	xmlFile:iterate(key .. ".storage", function(_, p66_)
		-- upvalues: (copy) xmlFile, (copy) v_u_65_
		local v67_ = xmlFile:getValue(p66_ .. "#index")
		if v67_ ~= nil and (v_u_65_.storages[v67_] ~= nil and not v_u_65_.storages[v67_]:loadFromXMLFile(xmlFile, p66_)) then
			return false
		end
	end)
end

-- Local values: spec, k, storage, storageKey
function PlaceableSilo:saveToXMLFile(xmlFile, key, usedModNames)
	local v72_ = self.spec_silo
	for v73_, v74_ in ipairs(v72_.storages) do
		local v75_ = string.format("%s.storage(%d)", key, v73_ - 1)
		xmlFile:setValue(v75_ .. "#index", v73_)
		v74_:saveToXMLFile(xmlFile, v75_, usedModNames)
	end
end

-- Local values: spec, _, storage
function PlaceableSilo:setOwnerFarmId(superFunc, farmId, noEventSend)
	local v80_ = self.spec_silo
	superFunc(self, farmId, noEventSend)
	if self.isServer and (not v80_.storagePerFarm and v80_.storages ~= nil) then
		for _, v81_ in ipairs(v80_.storages) do
			v81_:setOwnerFarmId(farmId, true)
		end
	end
end

-- Local values: spec, _, storage, capacity, moved
function PlaceableSilo:setAmount(fillType, amount)
	local v85_ = self.spec_silo
	for _, v86_ in ipairs(v85_.storages) do
		local v87_ = v86_:getFreeCapacity(fillType)
		if v87_ > 0 then
			local v88_ = math.min(amount, v87_)
			v86_:setFillLevel(v88_, fillType)
			amount = amount - v88_
		end
		if amount <= 0.001 then
			break
		end
	end
end

-- Local values: spec, _, storage, freeCapacity, moved, fillLevel
function PlaceableSilo:refillAmount(fillTypeIndex, amount, price)
	if fillTypeIndex == nil or (amount == nil or price == nil) then
		return
	elseif self.isServer then
		local v93_ = self.spec_silo
		for _, v94_ in ipairs(v93_.storages) do
			local v95_ = v94_:getFreeCapacity(fillTypeIndex)
			if v95_ > 0 then
				local v96_ = math.min(amount, v95_)
				v94_:setFillLevel(v94_:getFillLevel(fillTypeIndex) + v96_, fillTypeIndex)
				amount = amount - v96_
			end
			if amount <= 0.001 then
				break
			end
		end
		if self.isServer then
			g_currentMission:addMoney(-price, self:getOwnerFarmId(), MoneyType.BOUGHT_MATERIALS, true)
		end
		g_currentMission:showMoneyChange(MoneyType.BOUGHT_MATERIALS)
	else
		g_client:getServerConnection():sendEvent(PlaceableSiloRefillEvent.new(self, fillTypeIndex, amount, price))
	end
end

-- Local values: spec, validFillLevels, _, storage, fillTypeIndex, fillLevel
function PlaceableSilo:getFillLevels()
	local v98_ = self.spec_silo
	local v99_ = {}
	for _, v100_ in ipairs(v98_.storages) do
		for v101_, v102_ in pairs(v100_:getFillLevels()) do
			if self.fillTypes == nil or self.fillTypes[v101_] then
				v99_[v101_] = v102_
			end
		end
	end
	return v99_
end

-- Local values: spec
function PlaceableSilo:onSell()
	local v104_ = self.spec_silo
	if self.isServer and v104_.totalFillTypeSellPrice > 0 then
		g_currentMission:addMoney(v104_.totalFillTypeSellPrice, self:getOwnerFarmId(), MoneyType.HARVEST_INCOME, true, true)
	end
end

-- Local values: spec
function PlaceableSilo:onPlayerActionTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	local v108_ = self.spec_silo
	if self:getOwnerFarmId() == g_currentMission:getFarmId() and (g_localPlayer ~= nil and otherId == g_localPlayer.rootNode) then
		if onEnter then
			g_currentMission.activatableObjectsSystem:addActivatable(v108_.activatable)
			return
		end
		g_currentMission.activatableObjectsSystem:removeActivatable(v108_.activatable)
	end
end

-- Local values: spec, farmId, fillType, fillLevel, fillType, fillLevel, numEntries, i, fillTypeAndLevel
function PlaceableSilo:updateInfo(superFunc, infoTable)
	superFunc(self, infoTable)
	local v112_ = self.spec_silo
	local v113_ = g_currentMission:getFarmId()
	for v114_, v115_ in pairs(v112_.loadingStation:getAllFillLevels(v113_)) do
		v112_.fillTypesAndLevelsAuxiliary[v114_] = (v112_.fillTypesAndLevelsAuxiliary[v114_] or 0) + v115_
	end
	table.clear(v112_.infoTriggerFillTypesAndLevels)
	for v116_, v117_ in pairs(v112_.fillTypesAndLevelsAuxiliary) do
		if v117_ > 0.1 then
			local v118_ = v112_.fillTypeToFillTypeStorageTable
			local v119_ = v112_.fillTypeToFillTypeStorageTable[v116_]
			if not v119_ then
				v119_ = {
					["fillType"] = v116_,
					["fillLevel"] = v117_
				}
			end
			v118_[v116_] = v119_
			v112_.fillTypeToFillTypeStorageTable[v116_].fillLevel = v117_
			local v120_ = v112_.infoTriggerFillTypesAndLevels
			local v121_ = v112_.fillTypeToFillTypeStorageTable[v116_]
			table.insert(v120_, v121_)
		end
	end
	table.clear(v112_.fillTypesAndLevelsAuxiliary)
	table.sort(v112_.infoTriggerFillTypesAndLevels, function(p122_, p123_)
		return p122_.fillLevel > p123_.fillLevel
	end)
	local v124_ = #v112_.infoTriggerFillTypesAndLevels
	local v125_ = PlaceableSilo.INFO_TRIGGER_NUM_DISPLAYED_FILLTYPES
	local v126_ = math.min(v124_, v125_)
	if v126_ > 0 then
		for v127_ = 1, v126_ do
			local v128_ = v112_.infoTriggerFillTypesAndLevels[v127_]
			local v129_ = {
				["title"] = g_fillTypeManager:getFillTypeTitleByIndex(v128_.fillType),
				["text"] = g_i18n:formatVolume(v128_.fillLevel, 0)
			}
			table.insert(infoTable, v129_)
		end
	else
		local v130_ = {
			["title"] = "",
			["text"] = g_i18n:getText("infohud_siloEmpty")
		}
		table.insert(infoTable, v130_)
	end
end

function PlaceableSilo.loadSpecValueVolume(xmlFile, customEnvironment, baseDir)
	return xmlFile:getValue("placeable.silo.storages.storage(0)#capacity")
end

function PlaceableSilo.getSpecValueVolume(storeItem, realItem)
	if storeItem.specs.siloVolume == nil then
		return nil
	else
		return g_i18n:formatVolume(storeItem.specs.siloVolume)
	end
end
PlaceableSiloActivatable = {}
local v_u_133_ = Class(PlaceableSiloActivatable)

-- Upvalues: PlaceableSiloActivatable_mt
-- Local values: self
function PlaceableSiloActivatable.new(placeable)
	-- upvalues: (copy) v_u_133_
	local v135_ = v_u_133_
	local v136_ = setmetatable({}, v135_)
	v136_.placeable = placeable
	v136_.activateText = g_i18n:getText("action_refillSilo")
	return v136_
end

-- Local values: freeCapacities, _, storage, fillType, fillLevel
function PlaceableSiloActivatable:run()
	local v138_ = {}
	for _, v139_ in pairs(self.placeable.spec_silo.storages) do
		for v140_, _ in pairs(v139_:getFillLevels()) do
			if v138_[v140_] == nil then
				v138_[v140_] = 0
			end
			v138_[v140_] = v138_[v140_] + v139_:getFreeCapacity(v140_)
		end
	end
	RefillDialog.show(self.placeable.refillAmount, self.placeable, v138_, PlaceableSilo.REFILL_PRICE_FACTOR)
end
PlaceableSiloRefillEvent = {}
local v_u_141_ = Class(PlaceableSiloRefillEvent, Event)
InitStaticEventClass(PlaceableSiloRefillEvent, "PlaceableSiloRefillEvent")
function PlaceableSiloRefillEvent.emptyNew()
	-- upvalues: (copy) v_u_141_
	return Event.new(v_u_141_)
end
function PlaceableSiloRefillEvent.new(p142_, p143_, p144_, p145_)
	local v146_ = PlaceableSiloRefillEvent.emptyNew()
	v146_.placeable = p142_
	v146_.fillTypeIndex = p143_
	v146_.amount = p144_
	v146_.price = p145_
	return v146_
end

function PlaceableSiloRefillEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.placeable)
	streamWriteInt32(streamId, self.amount)
	streamWriteInt32(streamId, self.price)
	streamWriteUIntN(streamId, self.fillTypeIndex, FillTypeManager.SEND_NUM_BITS)
end

function PlaceableSiloRefillEvent:readStream(streamId, connection)
	self.placeable = NetworkUtil.readNodeObject(streamId)
	self.amount = streamReadInt32(streamId)
	self.price = streamReadInt32(streamId)
	self.fillTypeIndex = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
	self:run(connection)
end

function PlaceableSiloRefillEvent:run(connection)
	if not connection:getIsServer() then
		self.placeable:refillAmount(self.fillTypeIndex, self.amount, self.price)
	end
end
