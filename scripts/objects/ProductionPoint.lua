-- Local values: ProductionPoint_mt
source("dataS/scripts/objects/ProductionPointActivatable.lua")
ProductionPoint = {}
ProductionPoint.NO_PALLET_SPACE_COOLDOWN = 15000
ProductionPoint.DIRECT_SELL_PRICE_FACTOR = 0.9
ProductionPoint.DIRECT_DELIVERY_PRICE = 0.000035000000000000004
ProductionPoint.OUTPUT_MODE = {}
ProductionPoint.OUTPUT_MODE.KEEP = 0
ProductionPoint.OUTPUT_MODE.DIRECT_SELL = 1
ProductionPoint.OUTPUT_MODE.AUTO_DELIVER = 2
ProductionPoint.OUTPUT_MODE_NUM_BITS = 2
ProductionPoint.PROD_STATUS = {}
ProductionPoint.PROD_STATUS.INACTIVE = 0
ProductionPoint.PROD_STATUS.RUNNING = 1
ProductionPoint.PROD_STATUS.MISSING_INPUTS = 2
ProductionPoint.PROD_STATUS.NO_OUTPUT_SPACE = 3
ProductionPoint.PROD_STATUS_NUM_BITS = 2
ProductionPoint.PROD_STATUS_TO_L10N = {
	[ProductionPoint.PROD_STATUS.INACTIVE] = "ui_production_status_inactive",
	[ProductionPoint.PROD_STATUS.RUNNING] = "ui_production_status_running",
	[ProductionPoint.PROD_STATUS.MISSING_INPUTS] = "ui_production_status_materialsMissing",
	[ProductionPoint.PROD_STATUS.NO_OUTPUT_SPACE] = "ui_production_status_outOfSpace"
}
local ProductionPoint_mt = Class(ProductionPoint, Object)

function ProductionPoint.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#name", "Name of the Production Point", "unnamed production point")
	schema:register(XMLValueType.BOOL, basePath .. ".productions#sharedThroughputCapacity", "Productions slow each other down if active at the same time", true)
	schema:register(XMLValueType.STRING, basePath .. ".productions.production(?)#id", "Unique string used for identifying the production", nil, true)
	schema:register(XMLValueType.L10N_STRING, basePath .. ".productions.production(?)#name", "Name of the production used inside the UI", "unnamed production")
	schema:register(XMLValueType.STRING, basePath .. ".productions.production(?)#params", "Optional parameters formatted into #name")
	schema:register(XMLValueType.FLOAT, basePath .. ".productions.production(?)#cyclesPerMonth", "Number of performed production cycles per ingame month (divided by the number of enabled productions, unless sharedThroughputCapacity is set to false)", 1440)
	schema:register(XMLValueType.FLOAT, basePath .. ".productions.production(?)#cyclesPerHour", "Number of production cycles per ingame hour per day (==month) (divided by the number of enabled productions, unless sharedThroughputCapacity is set to false)", 60)
	schema:register(XMLValueType.FLOAT, basePath .. ".productions.production(?)#cyclesPerMinute", "Number of performed production cycles per ingame minute (divided by the number of enabled productions)", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".productions.production(?)#costsPerActiveMonth", "Costs per ingame hour if this production is enabled per ingame month (regardless of whether it is producing or not)", 1440)
	schema:register(XMLValueType.FLOAT, basePath .. ".productions.production(?)#costsPerActiveHour", "Costs per ingame hour if this production is enabled per day (==month) (regardless of whether it is producing or not)", 60)
	schema:register(XMLValueType.FLOAT, basePath .. ".productions.production(?)#costsPerActiveMinute", "Costs per ingame minute if this production is enabled (regardless of whether it is producing or not)", 1)
	schema:register(XMLValueType.STRING, basePath .. ".productions.production(?).inputs.input(?)#fillType", "Input fillType", nil, true)
	schema:register(XMLValueType.FLOAT, basePath .. ".productions.production(?).inputs.input(?)#amount", "Used amount per cycle", 1)
	schema:register(XMLValueType.STRING, basePath .. ".productions.production(?).outputs.output(?)#fillType", "Output fillType", nil, true)
	schema:register(XMLValueType.FLOAT, basePath .. ".productions.production(?).outputs.output(?)#amount", "Produced amount per cycle", 1)
	schema:register(XMLValueType.BOOL, basePath .. ".productions.production(?).outputs.output(?)#sellDirectly", "Directly sell produced amount", false)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".playerTrigger#node", "", "")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "active")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "idle")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".productions.production(?).sounds", "active")
	AnimationManager.registerAnimationNodesXMLPaths(schema, basePath .. ".animationNodes")
	AnimationManager.registerAnimationNodesXMLPaths(schema, basePath .. ".productions.production(?).animationNodes")
	EffectManager.registerEffectXMLPaths(schema, basePath .. ".effectNodes")
	EffectManager.registerEffectXMLPaths(schema, basePath .. ".productions.production(?).effectNodes")
	SellingStation.registerXMLPaths(schema, basePath .. ".sellingStation")
	LoadingStation.registerXMLPaths(schema, basePath .. ".loadingStation")
	PalletSpawner.registerXMLPaths(schema, basePath .. ".palletSpawner")
	Storage.registerXMLPaths(schema, basePath .. ".storage")
end

function ProductionPoint.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#palletSpawnCooldown", "remaining cooldown duration of pallet spawner")
	schema:register(XMLValueType.FLOAT, basePath .. "#productionCostsToClaim", "production costs yet to be claimed from the owning player")
	schema:register(XMLValueType.STRING, basePath .. ".directSellFillType(?)", "fillType currently configured to be directly sold")
	schema:register(XMLValueType.STRING, basePath .. ".autoDeliverFillType(?)", "fillType currently configured to be automatically delivered")
	schema:register(XMLValueType.STRING, basePath .. ".production(?)#id", "Unique id of the production")
	schema:register(XMLValueType.BOOL, basePath .. ".production(?)#isEnabled", "State of the production")
	Storage.registerSavegameXMLPaths(schema, basePath .. ".storage")
end
InitStaticObjectClass(ProductionPoint, "ProductionPoint")

-- Upvalues: ProductionPoint_mt
-- Local values: self
function ProductionPoint.new(isServer, isClient, baseDirectory, customMt)
	-- upvalues: (copy) ProductionPoint_mt
	local v10_ = Object.new(isServer, isClient, customMt or ProductionPoint_mt)
	v10_.baseDirectory = baseDirectory
	v10_.owningPlaceable = nil
	v10_.isOwned = false
	v10_.mission = g_currentMission
	v10_.activeProductions = {}
	v10_.minuteFactorTimescaled = v10_.mission:getEffectiveTimeScale() / 1000 / 60
	v10_.waitingForPalletToSpawn = false
	v10_.palletSpawnCooldown = 0
	v10_.palletLimitReached = false
	v10_.isFinalized = true
	v10_.dirtyFlag = v10_:getNextDirtyFlag()
	v10_.inputFillLevels = {}
	v10_.productionCostsToClaim = 0
	v10_.soldFillTypesToPayOut = {}
	v10_.activatable = ProductionPointActivatable.new(v10_)
	g_messageCenter:subscribe(MessageType.TIMESCALE_CHANGED, v10_.onTimescaleChanged, v10_)
	v10_.infoTables = {
		["activeProds"] = {
			["title"] = g_i18n:getText("infohud_activeProductions"),
			["accentuate"] = true
		},
		["noActiveProd"] = {
			["title"] = g_i18n:getText("infohud_noActiveProduction"),
			["accentuate"] = true
		},
		["storage"] = {
			["title"] = g_i18n:getText("ui_productions_buildingStorage"),
			["accentuate"] = true
		},
		["storageEmpty"] = {
			["title"] = "",
			["text"] = g_i18n:getText("infohud_storageIsEmpty")
		},
		["palletLimitReached"] = {
			["title"] = g_i18n:getText("infohud_tooManyPallets"),
			["accentuate"] = true
		}
	}
	return v10_
end

-- Local values: name, usedProdIds, loadingStationKey, palletSpawnerKey, fillTypeId, pallet, inputFillTypeIndex, fillTypeName, outputFillTypeIndex, fillTypeName, i, production, x, input, x, output, supportedFillType, _
function ProductionPoint:load(components, xmlFile, key, customEnv, i3dMappings)
	self.node = components[1].node
	local v17_ = xmlFile:getValue(key .. "#name")
	if v17_ then
		v17_ = g_i18n:convertText(v17_, customEnv)
	end
	self.name = v17_
	self.productions = {}
	self.productionsIdToObj = {}
	self.inputFillTypeIds = {}
	self.inputFillTypeIdsArray = {}
	self.outputFillTypeIds = {}
	self.outputFillTypeIdsArray = {}
	self.outputFillTypeIdsDirectSell = {}
	self.outputFillTypeIdsAutoDeliver = {}
	self.outputFillTypeIdsToPallets = {}
	self.sharedThroughputCapacity = xmlFile:getValue(key .. ".productions#sharedThroughputCapacity", true)
	local v_u_18_ = {}
	xmlFile:iterate(key .. ".productions.production", function(p19_, p20_)
		-- upvalues: (copy) xmlFile, (copy) customEnv, (copy) v_u_18_, (copy) self, (copy) components, (copy) i3dMappings
		local v_u_21_ = {
			["id"] = xmlFile:getValue(p20_ .. "#id"),
			["name"] = xmlFile:getValue(p20_ .. "#name", nil, customEnv, false)
		}
		local v22_ = xmlFile:getValue(p20_ .. "#params")
		if v22_ ~= nil then
			v_u_21_.name = g_i18n:insertTextParams(v_u_21_.name, v22_, customEnv, xmlFile)
		end
		if not v_u_21_.id then
			Logging.xmlError(xmlFile, "missing id for production \'%s\'", v_u_21_.name or p19_)
			return false
		end
		for v23_ = 1, #v_u_18_ do
			if v_u_18_[v23_] == v_u_21_.id then
				Logging.xmlError(xmlFile, "production id \'%s\' already in use", v_u_21_.id)
				return false
			end
		end
		local v24_ = v_u_18_
		local v25_ = v_u_21_.id
		table.insert(v24_, v25_)
		local v26_ = xmlFile:getValue(p20_ .. "#cyclesPerMonth")
		local v27_ = xmlFile:getValue(p20_ .. "#cyclesPerHour")
		local v28_ = xmlFile:getValue(p20_ .. "#cyclesPerMinute")
		v_u_21_.cyclesPerMinute = v26_ and v26_ / 60 / 24 or (v27_ and v27_ / 60 or (v28_ or 1))
		v_u_21_.cyclesPerHour = v27_ or v_u_21_.cyclesPerMinute * 60
		v_u_21_.cyclesPerMonth = v26_ or v_u_21_.cyclesPerHour * 24
		local v29_ = xmlFile:getValue(p20_ .. "#costsPerActiveMinute")
		local v30_ = xmlFile:getValue(p20_ .. "#costsPerActiveHour")
		local v31_ = xmlFile:getValue(p20_ .. "#costsPerActiveMonth")
		v_u_21_.costsPerActiveMinute = v31_ and v31_ / 60 / 24 or v30_ and v30_ / 60 or (v29_ or 1)
		v_u_21_.costsPerActiveHour = v30_ or v_u_21_.costsPerActiveMinute * 60
		v_u_21_.costsPerActiveMonth = v31_ or v_u_21_.costsPerActiveHour * 24
		v_u_21_.status = ProductionPoint.PROD_STATUS.INACTIVE
		v_u_21_.inputs = {}
		xmlFile:iterate(p20_ .. ".inputs.input", function(_, p32_)
			-- upvalues: (ref) xmlFile, (ref) self, (copy) v_u_21_
			local v33_ = {}
			local v34_ = xmlFile:getValue(p32_ .. "#fillType")
			v33_.type = g_fillTypeManager:getFillTypeIndexByName(v34_)
			if v33_.type == nil then
				Logging.xmlError(xmlFile, "Unable to load fillType \'%s\' for \'%s\'", v34_, p32_)
			else
				self.inputFillTypeIds[v33_.type] = true
				table.addElement(self.inputFillTypeIdsArray, v33_.type)
				v33_.amount = xmlFile:getValue(p32_ .. "#amount", 1)
				local v35_ = v_u_21_.inputs
				table.insert(v35_, v33_)
			end
		end)
		if #v_u_21_.inputs ~= 0 then
			v_u_21_.outputs = {}
			v_u_21_.primaryProductFillType = nil
			local v_u_36_ = 0
			xmlFile:iterate(p20_ .. ".outputs.output", function(_, p37_)
				-- upvalues: (ref) xmlFile, (ref) self, (copy) v_u_21_, (ref) v_u_36_
				local v38_ = {}
				local v39_ = xmlFile:getValue(p37_ .. "#fillType")
				v38_.type = g_fillTypeManager:getFillTypeIndexByName(v39_)
				if v38_.type == nil then
					Logging.xmlError(xmlFile, "Unable to load fillType \'%s\' for \'%s\'", v39_, p37_)
				else
					v38_.sellDirectly = xmlFile:getValue(p37_ .. "#sellDirectly", false)
					if v38_.sellDirectly then
						self.soldFillTypesToPayOut[v38_.type] = 0
					else
						self.outputFillTypeIds[v38_.type] = true
						table.addElement(self.outputFillTypeIdsArray, v38_.type)
					end
					v38_.amount = xmlFile:getValue(p37_ .. "#amount", 1)
					local v40_ = v_u_21_.outputs
					table.insert(v40_, v38_)
					if v_u_36_ < v38_.amount then
						v_u_21_.primaryProductFillType = v38_.type
						v_u_36_ = v38_.amount
					end
				end
			end)
			if #v_u_21_.outputs == 0 then
				Logging.xmlError(xmlFile, "No outputs for production \'%s\'", p20_)
			end
			if self.isClient then
				v_u_21_.samples = {}
				v_u_21_.samples.active = g_soundManager:loadSampleFromXML(xmlFile, p20_ .. ".sounds", "active", self.baseDirectory, components, 1, AudioGroup.ENVIRONMENT, i3dMappings, nil)
				v_u_21_.animationNodes = g_animationManager:loadAnimations(xmlFile, p20_ .. ".animationNodes", components, self, i3dMappings)
				v_u_21_.effects = g_effectManager:loadEffect(xmlFile, p20_ .. ".effectNodes", components, self, i3dMappings)
				g_effectManager:setEffectTypeInfo(v_u_21_.effects, FillType.UNKNOWN)
			end
			if self.productionsIdToObj[v_u_21_.id] ~= nil then
				Logging.xmlError(xmlFile, "production id \'%s\' already used", v_u_21_.id)
				return false
			end
			self.productionsIdToObj[v_u_21_.id] = v_u_21_
			local v41_ = self.productions
			table.insert(v41_, v_u_21_)
			v_u_21_.index = #self.productions
			return true
		end
		Logging.xmlError(xmlFile, "No inputs for production \'%s\'", p20_)
	end)
	if #self.productions == 0 then
		Logging.xmlError(xmlFile, "No valid productions defined")
	end
	if self.owningPlaceable == nil then
		printError("Error: ProductionPoint.owningPlaceable was not set before load()")
		return false
	end
	self.interactionTriggerNode = xmlFile:getValue(key .. ".playerTrigger#node", nil, components, i3dMappings)
	if self.interactionTriggerNode ~= nil then
		self.useInteractionTriggerForBuying = true
		addTrigger(self.interactionTriggerNode, "interactionTriggerCallback", self)
	end
	if self.isClient then
		self.samples = {}
		self.samples.idle = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "idle", self.baseDirectory, components, 1, AudioGroup.ENVIRONMENT, i3dMappings, nil)
		self.samples.active = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "active", self.baseDirectory, components, 1, AudioGroup.ENVIRONMENT, i3dMappings, nil)
		self.animationNodes = g_animationManager:loadAnimations(xmlFile, key .. ".animationNodes", components, self, i3dMappings)
		self.effects = g_effectManager:loadEffect(xmlFile, key .. ".effectNodes", components, self, i3dMappings)
		g_effectManager:setEffectTypeInfo(self.effects, FillType.UNKNOWN)
	end
	self.unloadingStation = SellingStation.new(self.isServer, self.isClient)
	self.unloadingStation:load(components, xmlFile, key .. ".sellingStation", self.customEnvironment, i3dMappings, components[1].node)
	function self.unloadingStation.getStoreGoods(_, p42_, _)
		-- upvalues: (copy) self
		local v43_ = self.owningPlaceable:getOwnerFarmId()
		return v43_ ~= AccessHandler.EVERYONE and (v43_ == p42_ or g_currentMission.accessHandler:canFarmAccess(p42_, self.owningPlaceable)) and true or false
	end
	function self.unloadingStation.getSkipSell(_, p44_, _)
		-- upvalues: (copy) self
		local v45_ = self.owningPlaceable:getOwnerFarmId()
		return v45_ ~= AccessHandler.EVERYONE and (v45_ == p44_ or g_currentMission.accessHandler:canFarmAccess(p44_, self.owningPlaceable)) and true or false
	end
	self.unloadingStation:register(true)
	local v46_ = key .. ".loadingStation"
	if xmlFile:hasProperty(v46_) then
		self.loadingStation = LoadingStation.new(self.isServer, self.isClient)
		if not self.loadingStation:load(components, xmlFile, v46_, self.customEnvironment, i3dMappings, components[1].node) then
			Logging.xmlError(xmlFile, "Unable to load loading station %s", v46_)
			return false
		end
		function self.loadingStation.hasFarmAccessToStorage(_, p47_)
			-- upvalues: (copy) self
			return p47_ == self.owningPlaceable:getOwnerFarmId()
		end
		self.loadingStation.owningPlaceable = self.owningPlaceable
		self.loadingStation:register(true)
	end
	local v48_ = key .. ".palletSpawner"
	if xmlFile:hasProperty(v48_) then
		self.palletSpawner = PalletSpawner.new(self.baseDirectory)
		if not self.palletSpawner:load(components, xmlFile, key .. ".palletSpawner", self.customEnvironment, i3dMappings) then
			Logging.xmlError(xmlFile, "Unable to load pallet spawner %s", v48_)
			return false
		end
	end
	if self.loadingStation == nil and self.palletSpawner == nil then
		Logging.xmlError(xmlFile, "No loading station or pallet spawner for production point")
		return false
	end
	if self.palletSpawner ~= nil then
		for v49_, v50_ in pairs(self.palletSpawner:getSupportedFillTypes()) do
			if self.outputFillTypeIds[v49_] then
				self.outputFillTypeIdsToPallets[v49_] = v50_
			end
		end
	end
	self.storage = Storage.new(self.isServer, self.isClient)
	self.storage:load(components, xmlFile, key .. ".storage", i3dMappings, self.baseDirectory)
	self.storage:register(true)
	if self.loadingStation ~= nil then
		if not self.loadingStation:addSourceStorage(self.storage) then
			Logging.xmlWarning(xmlFile, "Unable to add source storage ")
		end
		g_currentMission.storageSystem:addLoadingStation(self.loadingStation, self.owningPlaceable)
	end
	self.unloadingStation:addTargetStorage(self.storage)
	for v51_ in pairs(self.inputFillTypeIds) do
		if not self.unloadingStation:getIsFillTypeSupported(v51_) then
			local v52_ = g_fillTypeManager:getFillTypeNameByIndex(v51_)
			Logging.xmlWarning(xmlFile, "Input filltype \'%s\' is not supported by unloading station", v52_)
		end
	end
	for v53_ in pairs(self.outputFillTypeIds) do
		if (self.loadingStation == nil or not self.loadingStation:getIsFillTypeSupported(v53_)) and self.outputFillTypeIdsToPallets[v53_] == nil then
			local v54_ = g_fillTypeManager:getFillTypeNameByIndex(v53_)
			Logging.xmlWarning(xmlFile, "Output filltype \'%s\' is not supported by loading station or pallet spawner", v54_)
		end
	end
	self.unloadingStation.owningPlaceable = self.owningPlaceable
	g_currentMission.storageSystem:addUnloadingStation(self.unloadingStation, self.owningPlaceable)
	g_currentMission.economyManager:addSellingStation(self.unloadingStation)
	for v55_ = 1, #self.productions do
		local v56_ = self.productions[v55_]
		for v57_ = 1, #v56_.inputs do
			local v58_ = v56_.inputs[v57_]
			if not self.storage:getIsFillTypeSupported(v58_.type) then
				Logging.xmlError(xmlFile, "production point storage does not support fillType \'%s\' used as in input in production \'%s\'", g_fillTypeManager:getFillTypeNameByIndex(v58_.type), v56_.name)
				return false
			end
		end
		for v59_ = 1, #v56_.outputs do
			local v60_ = v56_.outputs[v59_]
			if not (v60_.sellDirectly or self.storage:getIsFillTypeSupported(v60_.type)) then
				Logging.xmlError(xmlFile, "production point storage does not support fillType \'%s\' used as an output in production \'%s\'", g_fillTypeManager:getFillTypeNameByIndex(v60_.type), v56_.name)
				return false
			end
		end
	end
	for v61_, _ in pairs(self.storage:getSupportedFillTypes()) do
		if not (self.inputFillTypeIds[v61_] or self.outputFillTypeIds[v61_]) then
			Logging.xmlWarning(xmlFile, "storage fillType \'%s\' not used as a production input or ouput", g_fillTypeManager:getFillTypeNameByIndex(v61_))
		end
	end
	return true
end

-- Local values: storageSystem, storagesInRange, _, storage, storagesInRange, _, storage
function ProductionPoint:findStorageExtensions()
	local v63_ = g_currentMission.storageSystem
	if self.unloadingStation ~= nil then
		local v64_ = v63_:getStorageExtensionsInRange(self.unloadingStation, self:getOwnerFarmId())
		if v64_ ~= nil then
			for _, v65_ in ipairs(v64_) do
				if self.unloadingStation.targetStorages[v65_] == nil then
					v63_:addStorageToUnloadingStation(v65_, self.unloadingStation)
				end
			end
		end
	end
	if self.loadingStation ~= nil then
		local v66_ = v63_:getStorageExtensionsInRange(self.loadingStation, self:getOwnerFarmId())
		if v66_ ~= nil then
			for _, v67_ in ipairs(v66_) do
				if self.loadingStation.sourceStorages[v67_] == nil then
					v63_:addStorageToLoadingStation(v67_, self.loadingStation)
				end
			end
		end
		if self.loadingStation:getIsFillTypeSupported(FillType.LIQUIDMANURE) or self.loadingStation:getIsFillTypeSupported(FillType.DIGESTATE) then
			g_currentMission:addLiquidManureLoadingStation(self.loadingStation)
		end
	end
end

-- Local values: i, production
function ProductionPoint:delete()
	g_messageCenter:unsubscribeAll(self)
	self.mission.activatableObjectsSystem:removeActivatable(self.activatable)
	self.activatable = nil
	g_currentMission.productionChainManager:removeProductionPoint(self)
	if self.interactionTriggerNode ~= nil then
		removeTrigger(self.interactionTriggerNode)
		self.interactionTriggerNode = nil
	end
	if self.samples ~= nil then
		g_soundManager:deleteSamples(self.samples)
		self.samples = nil
	end
	if self.animationNodes ~= nil then
		g_animationManager:deleteAnimations(self.animationNodes)
	end
	if self.effects ~= nil then
		g_effectManager:deleteEffects(self.effects)
	end
	if self.loadingStation ~= nil then
		g_currentMission.storageSystem:removeLoadingStation(self.loadingStation, self.owningPlaceable)
		if self.loadingStation:getIsFillTypeSupported(FillType.LIQUIDMANURE) or self.loadingStation:getIsFillTypeSupported(FillType.DIGESTATE) then
			g_currentMission:removeLiquidManureLoadingStation(self.loadingStation)
		end
		self.loadingStation:delete()
	end
	if self.unloadingStation ~= nil then
		g_currentMission.storageSystem:removeUnloadingStation(self.unloadingStation, self.owningPlaceable)
		g_currentMission.economyManager:removeSellingStation(self.unloadingStation)
		self.unloadingStation:delete()
	end
	if self.palletSpawner ~= nil then
		self.palletSpawner:delete()
	end
	if self.storage ~= nil then
		self.storage:delete()
	end
	for v69_ = 1, #self.productions do
		local v70_ = self.productions[v69_]
		g_soundManager:deleteSamples(v70_.samples)
		v70_.samples = nil
		g_animationManager:deleteAnimations(v70_.animationNodes)
		g_effectManager:deleteEffects(v70_.effects)
	end
	ProductionPoint:superClass().delete(self)
end

-- Local values: numSellFillTypes, i, fillType, numDeliverFillTypes, i, fillType, unloadingStationId, loadingStationId, storageId, numProductions, i, productionIndex, production, productionId, productionStatus
function ProductionPoint:readStream(streamId, connection)
	ProductionPoint:superClass().readStream(self, streamId, connection)
	if connection:getIsServer() then
		for _ = 1, streamReadUInt8(streamId) do
			self:setOutputDistributionMode(streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS), ProductionPoint.OUTPUT_MODE.DIRECT_SELL, true)
		end
		for _ = 1, streamReadUInt8(streamId) do
			self:setOutputDistributionMode(streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS), ProductionPoint.OUTPUT_MODE.AUTO_DELIVER, true)
		end
		local v74_ = NetworkUtil.readNodeObjectId(streamId)
		self.unloadingStation:readStream(streamId, connection)
		g_client:finishRegisterObject(self.unloadingStation, v74_)
		if self.loadingStation ~= nil then
			local v75_ = NetworkUtil.readNodeObjectId(streamId)
			self.loadingStation:readStream(streamId, connection)
			g_client:finishRegisterObject(self.loadingStation, v75_)
		end
		local v76_ = NetworkUtil.readNodeObjectId(streamId)
		self.storage:readStream(streamId, connection)
		g_client:finishRegisterObject(self.storage, v76_)
		for _ = 1, streamReadUInt8(streamId) do
			local v77_ = streamReadUInt8(streamId)
			local v78_ = self.productions[v77_]
			if v78_ ~= nil then
				self:setProductionState(v78_.id, true, true)
				local v79_ = streamReadUIntN(streamId, ProductionPoint.PROD_STATUS_NUM_BITS)
				self:setProductionStatus(v78_.id, v79_, true)
			end
		end
		self.palletLimitReached = streamReadBool(streamId)
	end
end

-- Local values: directSellFillTypeId, autoDeliverFillTypeId, i, production
function ProductionPoint:writeStream(streamId, connection)
	ProductionPoint:superClass().writeStream(self, streamId, connection)
	if not connection:getIsServer() then
		streamWriteUInt8(streamId, table.size(self.outputFillTypeIdsDirectSell))
		for v83_ in pairs(self.outputFillTypeIdsDirectSell) do
			streamWriteUIntN(streamId, v83_, FillTypeManager.SEND_NUM_BITS)
		end
		streamWriteUInt8(streamId, table.size(self.outputFillTypeIdsAutoDeliver))
		for v84_ in pairs(self.outputFillTypeIdsAutoDeliver) do
			streamWriteUIntN(streamId, v84_, FillTypeManager.SEND_NUM_BITS)
		end
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.unloadingStation))
		self.unloadingStation:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, self.unloadingStation)
		if self.loadingStation ~= nil then
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.loadingStation))
			self.loadingStation:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, self.loadingStation)
		end
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.storage))
		self.storage:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, self.storage)
		streamWriteUInt8(streamId, #self.activeProductions)
		for v85_ = 1, #self.activeProductions do
			local v86_ = self.activeProductions[v85_]
			streamWriteUInt8(streamId, v86_.index)
			streamWriteUIntN(streamId, v86_.status, ProductionPoint.PROD_STATUS_NUM_BITS)
		end
		streamWriteBool(streamId, self.palletLimitReached)
	end
end

function ProductionPoint:readUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		self.palletLimitReached = streamReadBool(streamId)
	end
end

function ProductionPoint:writeUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		streamWriteBool(streamId, self.palletLimitReached)
	end
end

-- Local values: _, production
function ProductionPoint:setOwnerFarmId(farmId, noEventSend)
	if self.isServer then
		self:claimProductionCosts()
	end
	g_currentMission.productionChainManager:removeProductionPoint(self)
	ProductionPoint:superClass().setOwnerFarmId(self, farmId, noEventSend)
	self.isOwned = farmId ~= AccessHandler.EVERYONE
	if g_server ~= nil and g_currentMission.isRunning then
		for _, v96_ in pairs(self.productions) do
			self:setProductionState(v96_.id, not self.isOwned)
		end
	end
	if self.unloadingStation ~= nil then
		self.unloadingStation:setOwnerFarmId(farmId)
	end
	if self.loadingStation ~= nil then
		self.loadingStation:setOwnerFarmId(farmId)
	end
	if self.storage ~= nil then
		self.storage:setOwnerFarmId(farmId)
	end
	g_currentMission.productionChainManager:addProductionPoint(self)
end

-- Local values: fillUnitIndex, delta
function ProductionPoint:palletSpawnRequestCallback(pallet, status, fillType)
	self.waitingForPalletToSpawn = false
	if pallet == nil or (not pallet.addFillUnitFillLevel or fillType == nil) then
		self.palletSpawnCooldown = g_time + ProductionPoint.NO_PALLET_SPACE_COOLDOWN
		if status == PalletSpawner.PALLET_LIMITED_REACHED then
			if not self.palletLimitReached then
				self.palletLimitReached = true
				self:raiseDirtyFlags(self.dirtyFlag)
				return
			end
		else
			self.lastPalletFillTypeId = next(self.outputFillTypeIdsToPallets, self.lastPalletFillTypeId)
		end
	else
		if self.palletLimitReached then
			self.palletLimitReached = false
			self:raiseDirtyFlags(self.dirtyFlag)
		end
		local v101_ = pallet:getFirstValidFillUnitToFill(fillType)
		if not v101_ then
			printf("Error: No fillUnitIndex for fillType %s found, pallet: %s", g_fillTypeManager:getFillTypeNameByIndex(fillType), pallet.xmlFile.filename)
			return
		end
		local v102_ = pallet:addFillUnitFillLevel(self:getOwnerFarmId(), v101_, self.storage:getFillLevel(fillType), fillType, ToolType.UNDEFINED)
		if v102_ > 0 then
			self.storage:setFillLevel(self.storage:getFillLevel(fillType) - v102_, fillType)
			return
		end
	end
end

function ProductionPoint:updateFxState()
	if self.isClient then
		if #self.activeProductions > 0 and self.isFinalized then
			g_soundManager:stopSample(self.samples.idle)
			if not g_soundManager:getIsSamplePlaying(self.samples.active) then
				g_soundManager:playSample(self.samples.active)
			end
			g_animationManager:startAnimations(self.animationNodes)
			g_effectManager:startEffects(self.effects)
			return
		end
		g_soundManager:stopSample(self.samples.active)
		if not g_soundManager:getIsSamplePlaying(self.samples.idle) then
			g_soundManager:playSample(self.samples.idle)
		end
		g_animationManager:stopAnimations(self.animationNodes)
		g_effectManager:stopEffects(self.effects)
	end
end

function ProductionPoint:update(dt) end

-- Local values: dt, timeAdjust, numActiveProductions, minuteFactorTimescaledDt, minuteFactorDt, n, production, cyclesPerMinuteMinuteFactor, cyclesPerMinuteFactorNoTimescale, enoughInputResources, enoughOutputSpace, x, input, fillLevel, x, output, freeCapacity, factor, y, input, fillLevel, y, output, fillLevel, nextFillTypeId, fillTypeId, fillLevel, pallet
function ProductionPoint:updateProduction()
	if self.lastUpdatedTime == nil then
		self.lastUpdatedTime = g_time
		return
	end
	local v105_ = g_time - self.lastUpdatedTime
	local v106_ = math.clamp(v105_, 0, 30000)
	local v107_ = g_currentMission.environment.timeAdjustment
	local v108_ = #self.activeProductions
	if v108_ > 0 then
		local v109_ = v106_ * self.minuteFactorTimescaled * v107_
		local v110_ = v106_ / 60000 * v107_
		for v111_ = 1, v108_ do
			local v112_ = self.activeProductions[v111_]
			local v113_ = v112_.cyclesPerMinute * v109_
			local v114_ = v112_.cyclesPerMinute * v110_
			local v115_ = true
			local v116_ = true
			for v117_ = 1, #v112_.inputs do
				local v118_ = v112_.inputs[v117_]
				local v119_ = self:getFillLevel(v118_.type)
				self.inputFillLevels[v118_] = v119_
				if self.isOwned and v119_ < v118_.amount * v114_ then
					v115_ = false
					if v112_.status ~= ProductionPoint.PROD_STATUS.MISSING_INPUTS then
						v112_.status = ProductionPoint.PROD_STATUS.MISSING_INPUTS
						self.owningPlaceable:productionStatusChanged(v112_, ProductionPoint.PROD_STATUS.MISSING_INPUTS)
						self:setProductionStatus(v112_.id, v112_.status)
					end
					break
				end
			end
			if v115_ and self.isOwned then
				for v120_ = 1, #v112_.outputs do
					local v121_ = v112_.outputs[v120_]
					if not v121_.sellDirectly and self.storage:getFreeCapacity(v121_.type) < v121_.amount * v113_ then
						v116_ = false
						if v112_.status ~= ProductionPoint.PROD_STATUS.NO_OUTPUT_SPACE then
							v112_.status = ProductionPoint.PROD_STATUS.NO_OUTPUT_SPACE
							self:setProductionStatus(v112_.id, v112_.status)
						end
						break
					end
				end
			end
			if self.isOwned then
				self.productionCostsToClaim = self.productionCostsToClaim + v112_.costsPerActiveMinute * v109_
			end
			if not self.isOwned or v115_ and v116_ then
				local v122_ = v113_ / (self.sharedThroughputCapacity and v108_ and v108_ or 1)
				for v123_ = 1, #v112_.inputs do
					local v124_ = v112_.inputs[v123_]
					if self.loadingStation == nil then
						local v125_ = self.inputFillLevels[v124_]
						if v125_ and v125_ > 0 then
							self.storage:setFillLevel(v125_ - v124_.amount * v122_, v124_.type)
						end
					else
						self.loadingStation:removeFillLevel(v124_.type, v124_.amount * v122_, self.ownerFarmId)
					end
				end
				if self.isOwned then
					for v126_ = 1, #v112_.outputs do
						local v127_ = v112_.outputs[v126_]
						if v127_.sellDirectly then
							if self.isServer then
								self.soldFillTypesToPayOut[v127_.type] = self.soldFillTypesToPayOut[v127_.type] + v127_.amount * v122_
							end
						else
							local v128_ = self.storage:getFillLevel(v127_.type)
							self.storage:setFillLevel(v128_ + v127_.amount * v122_, v127_.type)
						end
					end
				end
				if v112_.status ~= ProductionPoint.PROD_STATUS.RUNNING then
					v112_.status = ProductionPoint.PROD_STATUS.RUNNING
					self.owningPlaceable:productionStatusChanged(v112_, v112_.status)
					ProductionPointProductionStatusEvent.sendEvent(self, v112_.index, v112_.status)
				end
				table.clear(self.inputFillLevels)
			end
		end
	end
	if self.isServer and (self.isOwned and (g_time > self.palletSpawnCooldown and not self.waitingForPalletToSpawn)) then
		local v129_ = nil
		while true do
			local v130_ = self.lastPalletFillTypeId
			if v130_ ~= nil and (self.outputFillTypeIdsDirectSell[v130_] == nil and self.outputFillTypeIdsAutoDeliver[v130_] == nil) then
				local v131_ = self.storage:getFillLevel(v130_)
				if v131_ > 0 then
					local v132_ = self.outputFillTypeIdsToPallets[v130_]
					if v132_ and v132_.capacity <= v131_ then
						v129_ = v130_
						break
					end
				end
			end
			self.lastPalletFillTypeId = next(self.outputFillTypeIdsToPallets, self.lastPalletFillTypeId)
			if self.lastPalletFillTypeId == nil then
				break
			end
		end
		if v129_ ~= nil then
			self.waitingForPalletToSpawn = true
			self.palletSpawner:spawnPallet(self:getOwnerFarmId(), v129_, self.palletSpawnRequestCallback, self)
		end
	end
	self.lastUpdatedTime = g_time
end

function ProductionPoint:updateTick(dt) end

-- Local values: localPlayer, playerNode, px, py, pz, ppx, ppy, ppz, distance, text, i, production, n, input, n, output
function ProductionPoint:draw()
	local v134_ = g_localPlayer
	local v135_ = (v134_:getCurrentVehicle() or {}).rootNode or (v134_ or {}).rootNode
	local v136_, v137_, v138_ = getWorldTranslation(v135_)
	local v139_, v140_, v141_ = getWorldTranslation(self.node)
	if MathUtil.vector3Length(v136_ - v139_, v137_ - v140_, v138_ - v141_) < 40 then
		local v142_ = {}
		local v143_ = string.format
		local v144_ = self:getName()
		local v145_ = self:tableId()
		local v146_ = self.ownerFarmId
		local v147_ = self.isOwned
		table.insert(v142_, v143_("PP %s (%s); ownerFarmId: %s; isOwned: %s", v144_, v145_, v146_, v147_))
		for v148_ = 1, #self.productions do
			local v149_ = self.productions[v148_]
			local v150_ = string.format
			local v151_ = v149_.id
			local v152_ = v149_.cyclesPerMinute
			local v153_ = table.hasElement
			local v154_ = self.activeProductions
			local v155_ = tostring(v153_(v154_, v149_))
			table.insert(v142_, v150_("  prodId \'%s\': cyclesPerMinute: %.2f; enabled: %s", v151_, v152_, v155_))
			for v156_ = 1, #v149_.inputs do
				local v157_ = v149_.inputs[v156_]
				local v158_ = string.format
				local v159_ = g_fillTypeManager:getFillTypeNameByIndex(v157_.type)
				local v160_ = v157_.amount
				table.insert(v142_, v158_("    i: %s: %.2f", v159_, v160_))
			end
			for v161_ = 1, #v149_.outputs do
				local v162_ = v149_.outputs[v161_]
				local v163_ = string.format
				local v164_ = g_fillTypeManager:getFillTypeNameByIndex(v162_.type)
				local v165_ = v162_.amount
				local v166_ = self.outputFillTypeIdsDirectSell[v162_.type] == true
				local v167_ = tostring(v166_)
				local v168_ = self.outputFillTypeIdsAutoDeliver[v162_.type] == true
				local v169_ = tostring(v168_)
				table.insert(v142_, v163_("    o: %s: %.2f; directSell:%s; autoDeliver:%s", v164_, v165_, v167_, v169_))
			end
		end
		local v170_ = string.format
		local v171_ = self.productionCostsToClaim
		table.insert(v142_, v170_("productionCostsToClaim : %.1f", v171_))
		local v172_ = string.format
		local v173_ = self.waitingForPalletToSpawn
		table.insert(v142_, v172_("waitingForPalletToSpawn: %s", v173_))
		if self.palletSpawnCooldown > g_time then
			local v174_ = string.format
			local v175_ = (self.palletSpawnCooldown - g_time) / 1000
			table.insert(v142_, v174_("palletSpawnCooldown: %.1f s", v175_))
		end
		self.debugText:setText(table.concat(v142_, "\n"))
		self.debugText:draw()
		self.storage:draw()
	end
end

function ProductionPoint:onTimescaleChanged()
	self.minuteFactorTimescaled = self.mission:getEffectiveTimeScale() / 1000 / 60
end

function ProductionPoint:claimProductionCosts()
	if self.isOwned and (self.isServer and self.productionCostsToClaim > 0) then
		self.mission:addMoney(-self.productionCostsToClaim, self.ownerFarmId, MoneyType.PRODUCTION_COSTS, true)
	end
	self.productionCostsToClaim = 0
end

-- Local values: fillTypeId, amount, moneyType
function ProductionPoint:updateBalaceDirectlySoldOutputs()
	if self.isOwned and self.isServer then
		for v179_, v180_ in pairs(self.soldFillTypesToPayOut) do
			local v181_ = MoneyType.HARVEST_INCOME
			if g_fillTypeManager:getIsFillTypeInCategory(v179_, "PRODUCT") then
				v181_ = MoneyType.SOLD_PRODUCTS
			elseif g_fillTypeManager:getIsFillTypeInCategory(v179_, "PRODUCT_BGA") then
				v181_ = MoneyType.INCOME_BGA
			end
			self.mission:addMoney(v180_ * g_currentMission.economyManager:getPricePerLiter(v179_), self.ownerFarmId, v181_, true)
			self.soldFillTypesToPayOut[v179_] = 0
		end
	end
end

-- Local values: outputFillTypeId, amount, revenue
function ProductionPoint:directlySellOutputs()
	for v183_ in pairs(self.outputFillTypeIdsDirectSell) do
		local v184_ = self.storage:getFillLevel(v183_)
		if v184_ > 0 then
			local v185_ = ProductionPoint.DIRECT_SELL_PRICE_FACTOR * v184_ * g_currentMission.economyManager:getPricePerLiter(v183_)
			self.mission:addMoney(v185_, self.ownerFarmId, MoneyType.SOLD_PRODUCTS, true)
			self.storage:setFillLevel(0, v183_)
		end
	end
end

-- Local values: palletSpawnCooldown, n
function ProductionPoint:loadFromXMLFile(xmlFile, key)
	local v189_ = xmlFile:getValue(key .. "#palletSpawnCooldown")
	if v189_ then
		self.palletSpawnCooldown = g_time + v189_
	end
	self.productionCostsToClaim = xmlFile:getValue(key .. "#productionCostsToClaim") or self.productionCostsToClaim
	if self.owningPlaceable.ownerFarmId == AccessHandler.EVERYONE then
		for v190_ = 1, #self.productions do
			self:setProductionState(self.productions[v190_].id, true)
		end
	end
	xmlFile:iterate(key .. ".production", function(_, p191_)
		-- upvalues: (copy) xmlFile, (copy) self
		local v192_ = xmlFile:getValue(p191_ .. "#id")
		local v193_ = xmlFile:getValue(p191_ .. "#isEnabled")
		if self.productionsIdToObj[v192_] == nil then
			Logging.xmlWarning(xmlFile, "Unknown production id \'%s\'", v192_)
		else
			self:setProductionState(v192_, v193_)
		end
	end)
	xmlFile:iterate(key .. ".directSellFillType", function(_, p194_)
		-- upvalues: (copy) xmlFile, (copy) self
		local v195_ = g_fillTypeManager:getFillTypeIndexByName(xmlFile:getValue(p194_))
		if v195_ then
			self:setOutputDistributionMode(v195_, ProductionPoint.OUTPUT_MODE.DIRECT_SELL)
		end
	end)
	xmlFile:iterate(key .. ".autoDeliverFillType", function(_, p196_)
		-- upvalues: (copy) xmlFile, (copy) self
		local v197_ = g_fillTypeManager:getFillTypeIndexByName(xmlFile:getValue(p196_))
		if v197_ then
			self:setOutputDistributionMode(v197_, ProductionPoint.OUTPUT_MODE.AUTO_DELIVER)
		end
	end)
	return self.storage:loadFromXMLFile(xmlFile, key .. ".storage") and true or false
end

-- Local values: xmlIndex, i, production, productionKey
function ProductionPoint:saveToXMLFile(xmlFile, key, usedModNames)
	if g_time < self.palletSpawnCooldown then
		xmlFile:setValue(key .. "#palletSpawnCooldown", self.palletSpawnCooldown - g_time)
	end
	if self.productionCostsToClaim ~= 0 then
		xmlFile:setValue(key .. "#productionCostsToClaim", self.productionCostsToClaim)
	end
	local v202_ = 0
	for v203_ = 1, #self.activeProductions do
		local v204_ = self.activeProductions[v203_]
		local v205_ = string.format("%s.production(%i)", key, v202_)
		xmlFile:setValue(v205_ .. "#id", v204_.id)
		xmlFile:setValue(v205_ .. "#isEnabled", true)
		v202_ = v202_ + 1
	end
	xmlFile:setTable(key .. ".directSellFillType", self.outputFillTypeIdsDirectSell, function(p206_, _, p207_)
		-- upvalues: (copy) xmlFile
		xmlFile:setValue(p206_, (g_fillTypeManager:getFillTypeNameByIndex(p207_)))
	end)
	xmlFile:setTable(key .. ".autoDeliverFillType", self.outputFillTypeIdsAutoDeliver, function(p208_, _, p209_)
		-- upvalues: (copy) xmlFile
		xmlFile:setValue(p208_, (g_fillTypeManager:getFillTypeNameByIndex(p209_)))
	end)
	self.storage:saveToXMLFile(xmlFile, key .. ".storage", usedModNames)
end

function ProductionPoint:getName()
	return self.name or self.owningPlaceable:getName()
end

-- Local values: production
function ProductionPoint:setProductionState(productionId, state, noEventSend)
	local v215_ = self.productionsIdToObj[productionId]
	if v215_ == nil then
		printError(string.format("Error: setProductionState(): unknown productionId \'%s\'", productionId))
	else
		if state then
			if not table.hasElement(self.activeProductions, v215_) then
				v215_.status = ProductionPoint.PROD_STATUS.RUNNING
				local v216_ = self.activeProductions
				table.insert(v216_, v215_)
			end
			if self.isClient then
				g_soundManager:playSamples(v215_.samples)
				g_animationManager:startAnimations(v215_.animationNodes)
				g_effectManager:startEffects(v215_.effects)
			end
		else
			table.removeElement(self.activeProductions, v215_)
			v215_.status = ProductionPoint.PROD_STATUS.INACTIVE
			if self.isClient then
				g_soundManager:stopSamples(v215_.samples)
				g_animationManager:stopAnimations(v215_.animationNodes)
				g_effectManager:stopEffects(v215_.effects)
			end
		end
		self.owningPlaceable:outputsChanged(v215_.outputs, state)
		ProductionPointProductionStateEvent.sendEvent(self, productionId, state, noEventSend)
	end
	if self.isClient then
		self:updateFxState()
	end
end

function ProductionPoint:getIsProductionEnabled(productionId)
	return table.hasElement(self.activeProductions, self.productionsIdToObj[productionId])
end

-- Local values: owningFarm, activeProduction, i, productionName, fillType, fillLevel, fillTypesDisplayed, i, i
function ProductionPoint:updateInfo(infoTable)
	local v221_ = g_farmManager:getFarmById(self:getOwnerFarmId())
	if v221_ ~= nil and not string.isNilOrWhitespace(v221_.name) then
		local v222_ = {
			["title"] = g_i18n:getText("fieldInfo_ownedBy"),
			["text"] = v221_.name
		}
		table.insert(infoTable, v222_)
	end
	if #self.activeProductions > 0 then
		local v223_ = self.infoTables.activeProds
		table.insert(infoTable, v223_)
		for v224_ = 1, #self.activeProductions do
			local v225_ = self.activeProductions[v224_]
			local v226_ = {
				["title"] = v225_.name or g_fillTypeManager:getFillTypeTitleByIndex(v225_.primaryProductFillType),
				["text"] = g_i18n:getText(ProductionPoint.PROD_STATUS_TO_L10N[self:getProductionStatus(v225_.id)])
			}
			table.insert(infoTable, v226_)
		end
	else
		local v227_ = self.infoTables.noActiveProd
		table.insert(infoTable, v227_)
	end
	local v228_ = self.infoTables.storage
	table.insert(infoTable, v228_)
	local v229_ = false
	for v230_ = 1, #self.inputFillTypeIdsArray do
		local v231_ = self.inputFillTypeIdsArray[v230_]
		local v232_ = self:getFillLevel(v231_)
		if v232_ > 1 then
			local v233_ = {
				["title"] = g_fillTypeManager:getFillTypeTitleByIndex(v231_),
				["text"] = g_i18n:formatVolume(v232_, 0)
			}
			table.insert(infoTable, v233_)
			v229_ = true
		end
	end
	for v234_ = 1, #self.outputFillTypeIdsArray do
		local v235_ = self.outputFillTypeIdsArray[v234_]
		local v236_ = self:getFillLevel(v235_)
		if v236_ > 1 then
			local v237_ = {
				["title"] = g_fillTypeManager:getFillTypeTitleByIndex(v235_),
				["text"] = g_i18n:formatVolume(v236_, 0)
			}
			table.insert(infoTable, v237_)
			v229_ = true
		end
	end
	if not v229_ then
		local v238_ = self.infoTables.storageEmpty
		table.insert(infoTable, v238_)
	end
	if self.palletLimitReached then
		local v239_ = self.infoTables.palletLimitReached
		table.insert(infoTable, v239_)
	end
end

function ProductionPoint:getProductionStatus(productionId)
	return self.productionsIdToObj[productionId].status
end

function ProductionPoint:setOutputDistributionMode(outputFillTypeId, mode, noEventSend)
	if self.outputFillTypeIds[outputFillTypeId] == nil then
		printf("Error: setOutputDistribution(): fillType \'%s\' is not an output fillType", g_fillTypeManager:getFillTypeNameByIndex(outputFillTypeId))
	else
		local v246_ = tonumber(mode)
		self.outputFillTypeIdsDirectSell[outputFillTypeId] = nil
		self.outputFillTypeIdsAutoDeliver[outputFillTypeId] = nil
		if v246_ == ProductionPoint.OUTPUT_MODE.DIRECT_SELL then
			self.outputFillTypeIdsDirectSell[outputFillTypeId] = true
		elseif v246_ == ProductionPoint.OUTPUT_MODE.AUTO_DELIVER then
			self.outputFillTypeIdsAutoDeliver[outputFillTypeId] = true
		elseif v246_ ~= ProductionPoint.OUTPUT_MODE.KEEP then
			printf("Error: setOutputDistribution(): Undefined mode \'%s\'", v246_)
			return
		end
		ProductionPointOutputModeEvent.sendEvent(self, outputFillTypeId, v246_, noEventSend)
	end
end

-- Local values: production
function ProductionPoint:setProductionStatus(productionId, status, noEventSend)
	local v251_ = tonumber(status)
	local v252_ = self.productionsIdToObj[productionId]
	v252_.status = v251_
	ProductionPointProductionStatusEvent.sendEvent(self, v252_.index, v251_, noEventSend)
end

function ProductionPoint:getOutputDistributionMode(outputFillTypeId)
	if self.outputFillTypeIdsDirectSell[outputFillTypeId] == nil then
		if self.outputFillTypeIdsAutoDeliver[outputFillTypeId] == nil then
			return ProductionPoint.OUTPUT_MODE.KEEP
		else
			return ProductionPoint.OUTPUT_MODE.AUTO_DELIVER
		end
	else
		return ProductionPoint.OUTPUT_MODE.DIRECT_SELL
	end
end

-- Local values: curMode
function ProductionPoint:toggleOutputDistributionMode(outputFillTypeId)
	if self.outputFillTypeIds[outputFillTypeId] ~= nil then
		local v257_ = self:getOutputDistributionMode(outputFillTypeId)
		if table.hasElement(ProductionPoint.OUTPUT_MODE, v257_ + 1) then
			self:setOutputDistributionMode(outputFillTypeId, v257_ + 1)
			return
		end
		self:setOutputDistributionMode(outputFillTypeId, 0)
	end
end

function ProductionPoint:getFillLevel(fillTypeId)
	if self.outputFillTypeIds[fillTypeId] == nil then
		return self.inputFillTypeIds[fillTypeId] == nil and 0 or self.unloadingStation:getFillLevel(fillTypeId, self.ownerFarmId)
	elseif self.loadingStation == nil then
		return self.storage:getFillLevel(fillTypeId)
	else
		return self.loadingStation:getFillLevel(fillTypeId, self.ownerFarmId)
	end
end

function ProductionPoint:getCapacity(fillTypeId)
	if self.outputFillTypeIds[fillTypeId] == nil then
		return self.inputFillTypeIds[fillTypeId] == nil and 0 or self.unloadingStation:getCapacity(fillTypeId, self.ownerFarmId)
	else
		return self.storage:getCapacity(fillTypeId)
	end
end

function ProductionPoint:tableId()
	return tostring(self):sub(10)
end

-- Local values: paddedName
function ProductionPoint:toString()
	local v264_ = self:getName() .. string.rep(" ", 25 - utf8Strlen(self:getName()))
	return string.format("PP %s (%s): productions:(%i/%i) - owner: %i", v264_, self:tableId(), #self.activeProductions, #self.productions, self.ownerFarmId)
end

-- Local values: fillTypeNames
function ProductionPoint.loadSpecValueInputFillTypes(xmlFile, customEnvironment, baseDir)
	local v_u_266_ = nil
	xmlFile:iterate("placeable.productionPoint.productions.production", function(_, p267_)
		-- upvalues: (copy) xmlFile, (ref) v_u_266_
		xmlFile:iterate(p267_ .. ".inputs.input", function(_, p268_)
			-- upvalues: (ref) xmlFile, (ref) v_u_266_
			local v269_ = xmlFile:getValue(p268_ .. "#fillType")
			v_u_266_ = v_u_266_ or {}
			v_u_266_[v269_] = true
		end)
	end)
	xmlFile:iterate("placeable.productionPoint.productionPointConfigurations.productionPointConfiguration(0).productionPoint.productions.production", function(_, p270_)
		-- upvalues: (copy) xmlFile, (ref) v_u_266_
		xmlFile:iterate(p270_ .. ".inputs.input", function(_, p271_)
			-- upvalues: (ref) xmlFile, (ref) v_u_266_
			local v272_ = xmlFile:getValue(p271_ .. "#fillType")
			v_u_266_ = v_u_266_ or {}
			v_u_266_[v272_] = true
		end)
	end)
	return v_u_266_
end

function ProductionPoint.getSpecValueInputFillTypes(storeItem, realItem)
	if storeItem.specs.prodPointInputFillTypes == nil then
		return nil
	else
		return g_fillTypeManager:getFillTypesByNames(table.concatKeys(storeItem.specs.prodPointInputFillTypes, " "))
	end
end

-- Local values: fillTypeNames
function ProductionPoint.loadSpecValueOutputFillTypes(xmlFile, customEnvironment, baseDir)
	local v_u_275_ = nil
	xmlFile:iterate("placeable.productionPoint.productions.production", function(_, p276_)
		-- upvalues: (copy) xmlFile, (ref) v_u_275_
		xmlFile:iterate(p276_ .. ".outputs.output", function(_, p277_)
			-- upvalues: (ref) xmlFile, (ref) v_u_275_
			local v278_ = xmlFile:getValue(p277_ .. "#fillType")
			v_u_275_ = v_u_275_ or {}
			v_u_275_[v278_] = true
		end)
	end)
	xmlFile:iterate("placeable.productionPoint.productionPointConfigurations.productionPointConfiguration(0).productionPoint.productions.production", function(_, p279_)
		-- upvalues: (copy) xmlFile, (ref) v_u_275_
		xmlFile:iterate(p279_ .. ".outputs.output", function(_, p280_)
			-- upvalues: (ref) xmlFile, (ref) v_u_275_
			local v281_ = xmlFile:getValue(p280_ .. "#fillType")
			v_u_275_ = v_u_275_ or {}
			v_u_275_[v281_] = true
		end)
	end)
	return v_u_275_
end

function ProductionPoint.getSpecValueOutputFillTypes(storeItem, realItem)
	if storeItem.specs.prodPointOutputFillTypes == nil then
		return nil
	else
		return g_fillTypeManager:getFillTypesByNames(table.concatKeys(storeItem.specs.prodPointOutputFillTypes, " "))
	end
end

function ProductionPoint:interactionTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if (onEnter or onLeave) and (g_localPlayer ~= nil and g_localPlayer.rootNode == otherId) then
		if onEnter then
			if Platform.gameplay.autoActivateTrigger and self.activatable:getIsActivatable() then
				self.activatable:run()
				return
			end
			self.activatable:updateText()
			self.mission.activatableObjectsSystem:addActivatable(self.activatable)
		end
		if onLeave then
			self.mission.activatableObjectsSystem:removeActivatable(self.activatable)
		end
	end
end

function ProductionPoint:openMenu()
	g_gui:showGui("InGameMenu")
	g_messageCenter:publish(MessageType.GUI_INGAME_OPEN_PRODUCTION_SCREEN, self)
end

-- Local values: storeItem, price, farmlandId, farmland, activatable, productionPoint, buyingEventCallback, dialogCallback, callback
function ProductionPoint:buyRequest(requestCallback, target)
	if g_guidedTourManager:getIsTourRunning() then
		InfoDialog.show(g_i18n:getText("guidedTour_feature_deactivated"))
	else
		local v291_ = g_storeManager:getItemByXMLFilename(self.owningPlaceable.configFileName)
		local v292_ = g_currentMission.economyManager:getBuyPrice(v291_) or self.owningPlaceable:getPrice()
		if self.owningPlaceable.buysFarmland and self.owningPlaceable.getFarmlandId ~= nil then
			local v293_ = self.owningPlaceable:getFarmlandId()
			local v294_ = g_farmlandManager:getFarmlandById(v293_)
			if v294_ ~= nil and g_farmlandManager:getFarmlandOwner(v293_) ~= self.mission:getFarmId() then
				v292_ = v292_ + v294_.price * self.owningPlaceable.buysFarmlandPriceScale
			end
		end
		local v_u_295_ = self.activatable
		local function v_u_298_(p296_)
			-- upvalues: (copy) self, (copy) v_u_295_, (copy) self
			if p296_ ~= nil then
				local v297_ = BuyExistingPlaceableEvent.DIALOG_MESSAGES[p296_]
				if v297_ ~= nil then
					InfoDialog.show(g_i18n:getText(v297_.text), nil, nil, v297_.dialogType)
				end
			end
			g_messageCenter:unsubscribe(BuyExistingPlaceableEvent, self)
			v_u_295_:updateText()
			self.owningPlaceable:onBuy()
		end
		YesNoDialog.show(function(p299_)
			-- upvalues: (copy) v_u_298_, (copy) self, (copy) requestCallback, (copy) target
			if p299_ then
				g_messageCenter:subscribe(BuyExistingPlaceableEvent, v_u_298_)
				g_client:getServerConnection():sendEvent(BuyExistingPlaceableEvent.new(self.owningPlaceable, self.mission:getFarmId()))
			end
			if requestCallback ~= nil then
				if target ~= nil then
					requestCallback(target, p299_)
					return
				end
				requestCallback(p299_)
			end
		end, nil, string.format(g_i18n:getText("dialog_buyBuildingFor"), self:getName(), g_i18n:formatMoney(v292_, 0, true)))
	end
end
