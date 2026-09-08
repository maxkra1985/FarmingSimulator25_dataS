-- Local values: Placeable_mt
Placeable = {}
source("dataS/scripts/placeables/PlaceableNameEvent.lua")
local Placeable_mt = Class(Placeable, Object)
InitStaticObjectClass(Placeable, "Placeable")
Placeable.DEBUG_NETWORK = false
Placeable.DEBUG_NETWORK_UPDATE = false
Placeable.SELL_AND_DELETE = 0
Placeable.SELL_AND_SPECTATOR_FARM = 1
Placeable.DESTRUCTION = {
	["SELL"] = 1,
	["PER_NODE"] = 2
}
Placeable.UNDO_DURATION = 900000
g_xmlManager:addCreateSchemaFunction(function()
	Placeable.xmlSchema = XMLSchema.new("placeable")
	g_storeManager:addSpeciesXMLSchema(StoreSpecies.PLACEABLE, Placeable.xmlSchema)
	g_placeableTypeManager:setXMLSchema(Placeable.xmlSchema)
	Placeable.xmlSchemaSavegame = XMLSchema.new("savegame_placeables")
end)

-- Local values: parent, placeableSystem
function Placeable.onCreate(_, nodeId)
	local v3_ = getParent(nodeId)
	while v3_ ~= 0 do
		if getUserAttribute(v3_, "onCreate") == "Placeable.onCreate" then
			Logging.i3dError(nodeId, "Node uses \'Placeable.onCreate\' script callback as a child of \'%s\' which already uses \'Placeable.onCreate\', ignoring this definition. Ensure placeables are not nested in the map!", I3DUtil.getNodeNameAndIndexPath(v3_))
			return
		end
		v3_ = getParent(v3_)
	end
	g_currentMission.placeableSystem:addMapPlaceableNode(nodeId)
end

function Placeable.registerEvents(placeableType)
	SpecializationUtil.registerEvent(placeableType, "onPreLoad")
	SpecializationUtil.registerEvent(placeableType, "onLoad")
	SpecializationUtil.registerEvent(placeableType, "onPostLoad")
	SpecializationUtil.registerEvent(placeableType, "onPreLoadFinished")
	SpecializationUtil.registerEvent(placeableType, "onLoadFinished")
	SpecializationUtil.registerEvent(placeableType, "onRegistered")
	SpecializationUtil.registerEvent(placeableType, "onPreDelete")
	SpecializationUtil.registerEvent(placeableType, "onDelete")
	SpecializationUtil.registerEvent(placeableType, "onSave")
	SpecializationUtil.registerEvent(placeableType, "onReadStream")
	SpecializationUtil.registerEvent(placeableType, "onWriteStream")
	SpecializationUtil.registerEvent(placeableType, "onReadUpdateStream")
	SpecializationUtil.registerEvent(placeableType, "onWriteUpdateStream")
	SpecializationUtil.registerEvent(placeableType, "onDirtyMaskCleared")
	SpecializationUtil.registerEvent(placeableType, "onPreFinalizePlacement")
	SpecializationUtil.registerEvent(placeableType, "onFinalizePlacement")
	SpecializationUtil.registerEvent(placeableType, "onPostFinalizePlacement")
	SpecializationUtil.registerEvent(placeableType, "onUpdate")
	SpecializationUtil.registerEvent(placeableType, "onUpdateTick")
	SpecializationUtil.registerEvent(placeableType, "onDraw")
	SpecializationUtil.registerEvent(placeableType, "onDrawDebug")
	SpecializationUtil.registerEvent(placeableType, "onHourChanged")
	SpecializationUtil.registerEvent(placeableType, "onMinuteChanged")
	SpecializationUtil.registerEvent(placeableType, "onDayChanged")
	SpecializationUtil.registerEvent(placeableType, "onPeriodChanged")
	SpecializationUtil.registerEvent(placeableType, "onWeatherChanged")
	SpecializationUtil.registerEvent(placeableType, "onFarmlandStateChanged")
	SpecializationUtil.registerEvent(placeableType, "onBuy")
	SpecializationUtil.registerEvent(placeableType, "onSell")
	SpecializationUtil.registerEvent(placeableType, "onOwnerChanged")
end

function Placeable.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "register", Placeable.register)
	SpecializationUtil.registerFunction(placeableType, "getPosition", Placeable.getPosition)
	SpecializationUtil.registerFunction(placeableType, "getIsOnFarmland", Placeable.getIsOnFarmland)
	SpecializationUtil.registerFunction(placeableType, "getFarmlandId", Placeable.getFarmlandId)
	SpecializationUtil.registerFunction(placeableType, "setPose", Placeable.setPose)
	SpecializationUtil.registerFunction(placeableType, "setOwnerFarmId", Placeable.setOwnerFarmId)
	SpecializationUtil.registerFunction(placeableType, "setLoadingStep", Placeable.setLoadingStep)
	SpecializationUtil.registerFunction(placeableType, "setLoadingState", Placeable.setLoadingState)
	SpecializationUtil.registerFunction(placeableType, "addToPhysics", Placeable.addToPhysics)
	SpecializationUtil.registerFunction(placeableType, "removeFromPhysics", Placeable.removeFromPhysics)
	SpecializationUtil.registerFunction(placeableType, "collectPickObjects", Placeable.collectPickObjects)
	SpecializationUtil.registerFunction(placeableType, "getNeedWeatherChanged", Placeable.getNeedWeatherChanged)
	SpecializationUtil.registerFunction(placeableType, "getNeedHourChanged", Placeable.getNeedHourChanged)
	SpecializationUtil.registerFunction(placeableType, "getNeedMinuteChanged", Placeable.getNeedMinuteChanged)
	SpecializationUtil.registerFunction(placeableType, "getNeedDayChanged", Placeable.getNeedDayChanged)
	SpecializationUtil.registerFunction(placeableType, "getName", Placeable.getName)
	SpecializationUtil.registerFunction(placeableType, "getImageFilename", Placeable.getImageFilename)
	SpecializationUtil.registerFunction(placeableType, "getCanBeRenamedByFarm", Placeable.getCanBeRenamedByFarm)
	SpecializationUtil.registerFunction(placeableType, "setName", Placeable.setName)
	SpecializationUtil.registerFunction(placeableType, "getPrice", Placeable.getPrice)
	SpecializationUtil.registerFunction(placeableType, "canBuy", Placeable.canBuy)
	SpecializationUtil.registerFunction(placeableType, "getCanBePlacedAt", Placeable.getCanBePlacedAt)
	SpecializationUtil.registerFunction(placeableType, "canBeSold", Placeable.canBeSold)
	SpecializationUtil.registerFunction(placeableType, "getDestructionMethod", Placeable.getDestructionMethod)
	SpecializationUtil.registerFunction(placeableType, "previewNodeDestructionNodes", Placeable.previewNodeDestructionNodes)
	SpecializationUtil.registerFunction(placeableType, "performNodeDestruction", Placeable.performNodeDestruction)
	SpecializationUtil.registerFunction(placeableType, "updateOwnership", Placeable.updateOwnership)
	SpecializationUtil.registerFunction(placeableType, "setOverlayColor", Placeable.setOverlayColor)
	SpecializationUtil.registerFunction(placeableType, "setOverlayColorNodes", Placeable.setOverlayColorNodes)
	SpecializationUtil.registerFunction(placeableType, "getDailyUpkeep", Placeable.getDailyUpkeep)
	SpecializationUtil.registerFunction(placeableType, "getSellPrice", Placeable.getSellPrice)
	SpecializationUtil.registerFunction(placeableType, "setPreviewPosition", Placeable.setPreviewPosition)
	SpecializationUtil.registerFunction(placeableType, "setPropertyState", Placeable.setPropertyState)
	SpecializationUtil.registerFunction(placeableType, "getPropertyState", Placeable.getPropertyState)
	SpecializationUtil.registerFunction(placeableType, "setVisibility", Placeable.setVisibility)
	SpecializationUtil.registerFunction(placeableType, "getIsSynchronized", Placeable.getIsSynchronized)
	SpecializationUtil.registerFunction(placeableType, "getIsPreplaced", Placeable.getIsPreplaced)
end
function Placeable.init()
	local v6_ = Placeable.xmlSchema
	v6_:register(XMLValueType.STRING, "placeable#type", "Placeable type", nil, true)
	v6_:registerAutoCompletionDataSource("placeable#type", "$dataS/placeableTypes.xml", "placeableTypes.type#name")
	v6_:register(XMLValueType.STRING, "placeable.annotation", "Annotation", nil, false)
	v6_:register(XMLValueType.STRING, "placeable.base.filename", "Placeable i3d file", nil, true)
	v6_:register(XMLValueType.BOOL, "placeable.base.canBeRenamed", "Placeable can be renamed by player", false)
	v6_:register(XMLValueType.BOOL, "placeable.base.boughtWithFarmland", "Placeable is bough with farmland", false)
	v6_:register(XMLValueType.BOOL, "placeable.base.buysFarmland", "Placeable buys farmland it is placed on", false)
	v6_:register(XMLValueType.FLOAT, "placeable.base.buysFarmland#priceScale", "Price scale for the farmland price", 1)
	v6_:register(XMLValueType.BOOL, "placeable.base.canBeDeleted", "Placeable can be deleted by the player, set to false if it should be set farm 0 on sell instead", true)
	StoreManager.registerStoreDataXMLPaths(v6_, "placeable")
	I3DUtil.registerI3dMappingXMLPaths(v6_, "placeable")
	local v7_ = Placeable.xmlSchemaSavegame
	v7_:register(XMLValueType.BOOL, "placeables.placeable(?)#isDeleted", "If the preplaced placeable is deleted in the savegame")
	v7_:register(XMLValueType.BOOL, "placeables.placeable(?)#isPreplaced", "If the placeable is preplaced in the map")
	v7_:register(XMLValueType.STRING, "placeables.placeable(?)#uniqueId", "Placeable\'s unique id")
	v7_:register(XMLValueType.BOOL, "placeables#loadAnyFarmInSingleplayer", "Load any farm in singleplayer. Causes any placeable with any farmId to be loaded.", false)
	v7_:register(XMLValueType.INT, "placeables#version", "Version of map placeables file")
	v7_:register(XMLValueType.STRING, "placeables.placeable(?)#name", "Custom name set by player to be used instead of store item name")
	v7_:register(XMLValueType.STRING, "placeables.placeable(?)#nameL10nKey", "custom l10n key for name set in preplaced/default placeables xml")
	v7_:register(XMLValueType.STRING, "placeables.placeable(?).customImage#filename", "Path to a custom image file")
	v7_:register(XMLValueType.VECTOR_TRANS, "placeables.placeable(?)#position", "Position")
	v7_:register(XMLValueType.VECTOR_ROT, "placeables.placeable(?)#rotation", "Rotation")
	v7_:register(XMLValueType.STRING, "placeables.placeable(?)#filename", "Path to xml filename")
	v7_:register(XMLValueType.FLOAT, "placeables.placeable(?)#age", "Age of placeable in months.", 0)
	v7_:register(XMLValueType.FLOAT, "placeables.placeable(?)#price", "Price of placeable")
	v7_:register(XMLValueType.INT, "placeables.placeable(?)#farmId", "Owner farmland", 0)
	v7_:register(XMLValueType.BOOL, "placeables.placeable(?)#defaultFarmProperty", "Is property of default farm. Causes object to be removed on non-starter games.", false)
	v7_:register(XMLValueType.BOOL, "placeables.placeable(?)#canBeDeletedOverwrite", "Placeable can be deleted", false)
	v7_:register(XMLValueType.BOOL, "placeables.placeable(?)#boughtWithFarmlandOverwrite", "Placeable is bought with farmland overwritten by savegame", false)
	v7_:register(XMLValueType.STRING, "placeables.placeable(?)#modName", "Name of mod")
	v7_:register(XMLValueType.INT, "placeables.placeable(?)#sinceVersion", "Version of xml file when this placeable was added. Will cause placeable to appear on older, existing saves")
	v7_:register(XMLValueType.STRING, "placeables.placeable(?)#tourId", "Tour id")
	for v8_, v9_ in pairs(g_placeableSpecializationManager:getSpecializations()) do
		local v10_ = ClassUtil.getClassObject(v9_.className)
		if v10_ ~= nil then
			if rawget(v10_, "registerXMLPaths") then
				v10_.registerXMLPaths(v6_, "placeable")
			end
			if rawget(v10_, "registerSavegameXMLPaths") then
				v10_.registerSavegameXMLPaths(v7_, "placeables.placeable(?)" .. "." .. v8_)
			end
		end
	end
	g_storeManager:addSpecType("placeableSlots", "shopListAttributeIconSlots", nil, Placeable.getSpecValueSlots, StoreSpecies.PLACEABLE)
	g_placeableConfigurationManager:addConfigurationType("color", g_i18n:getText("configuration_color"), nil, PlaceableConfigurationItemColor)
end
function Placeable.postInit()
	local v11_ = Placeable.xmlSchema
	local v12_ = Placeable.xmlSchemaSavegame
	local v13_ = g_placeableConfigurationManager:getConfigurations()
	for _, v14_ in pairs(v13_) do
		if v14_.itemClass.registerXMLPaths ~= nil then
			v14_.itemClass.registerXMLPaths(v11_, v14_.configurationsKey, v14_.configurationKey .. "(?)")
		end
		if v14_.itemClass.registerSavegameXMLPaths ~= nil then
			v14_.itemClass.registerSavegameXMLPaths(v12_, "placeables.placeable(?).configuration(?)")
			v14_.itemClass.registerSavegameXMLPaths(v12_, "placeables.placeable(?).boughtConfiguration(?)")
		end
	end
end

-- Upvalues: Placeable_mt
-- Local values: self
function Placeable.new(isServer, isClient, customMt)
	-- upvalues: (copy) Placeable_mt
	local v18_ = Object.new(isServer, isClient, customMt or Placeable_mt)
	v18_.finishedLoading = false
	v18_.rootNode = nil
	v18_.loadingState = PlaceableLoadingState.OK
	v18_.loadingStep = SpecializationLoadStep.CREATED
	v18_.isDeleting = false
	v18_.isDeleted = false
	v18_.isLoadedFromSavegame = false
	v18_.loadingTasks = {}
	v18_.readyForFinishLoading = false
	v18_.propertyState = PlaceablePropertyState.OWNED
	v18_.age = 0
	v18_.price = 0
	v18_.pickObjects = {}
	v18_.undoTimer = 0
	v18_.uniqueId = nil
	return v18_
end

function Placeable:setFilename(filename)
	self.configFileName = filename
	self.configFileNameClean = Utils.getFilenameInfo(filename, true)
	local v21_, v22_ = Utils.getModNameAndBaseDirectory(filename)
	self.customEnvironment = v21_
	self.baseDirectory = v22_
end

-- Local values: configName, _
function Placeable:setConfigurations(configurations, boughtConfigurations, configurationData)
	self.configurations = configurations
	self.boughtConfigurations = boughtConfigurations
	self.configurationData = configurationData or self.configurationData
	if self.configurationData == nil then
		self.configurationData = {}
	end
	self.sortedConfigurationNames = {}
	for v27_, _ in pairs(self.configurations) do
		local v28_ = self.sortedConfigurationNames
		table.insert(v28_, v27_)
	end
	table.sort(self.sortedConfigurationNames, function(p29_, p30_)
		return p29_ < p30_
	end)
end

-- Local values: configItem, configType
function Placeable:setType(typeDef)
	assertWithCallstack(self.configFileName ~= nil, "Setting placeable type without setting a filename previously. Call \'setFilename\' first!")
	if self.configurations ~= nil then
		local v33_ = ConfigurationUtil.getConfigItemByConfigId(self.configFileName, "placeableType", self.configurations.placeableType)
		if v33_ ~= nil and v33_.placeableType ~= nil then
			local v34_ = g_placeableTypeManager:getTypeByName(v33_.placeableType, self.customEnvironment)
			if v34_ == nil then
				Logging.warning("Unknown placeable type \'%s\' in configuration for \'%s\'", v33_.placeableType, self.configFileName)
			else
				typeDef = v34_
			end
		end
	end
	SpecializationUtil.initSpecializationsIntoTypeClass(g_placeableTypeManager, typeDef, self)
end

function Placeable:setLoadCallback(loadCallbackFunction, loadCallbackFunctionTarget, loadCallbackFunctionArguments)
	self.loadCallbackFunction = loadCallbackFunction
	self.loadCallbackFunctionTarget = loadCallbackFunctionTarget
	self.loadCallbackFunctionArguments = loadCallbackFunctionArguments
end

function Placeable:loadCallback()
	if self.loadCallbackFunction ~= nil then
		self.loadCallbackFunction(self.loadCallbackFunctionTarget, self, self.loadingState, self.loadCallbackFunctionArguments)
		self.loadCallbackFunctionTarget = nil
		self.loadCallbackFunctionArguments = nil
	end
end

-- Local values: placeableSystem, item, closestSet, closestSetMatches, configName, index, configName, _, defaultConfigId, configName, value, defaultConfigId, isPathValid, invalidDesc, preplacedNode
function Placeable:load(placeableLoadingData)
	self.placeableLoadingData = placeableLoadingData
	local v42_ = g_currentMission.placeableSystem
	self:setLoadingStep(SpecializationLoadStep.PRE_LOAD)
	if self.type == nil then
		Logging.xmlWarning(self.xmlFile, "Unable to find placeableType \'%s\'", self.typeName)
		self:setLoadingState(PlaceableLoadingState.ERROR)
		return self.loadingState
	end
	self.xmlFile = XMLFile.load("placeableXml", self.configFileName, Placeable.xmlSchema)
	self.savegame = placeableLoadingData.savegameData
	self.storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
	if self.storeItem ~= nil then
		self.brand = g_brandManager:getBrandByIndex(self.storeItem.brandIndex)
		self.lifetime = self.storeItem.lifetime
	end
	SpecializationUtil.copyTypeFunctionsInto(self.type, self)
	local v43_ = g_storeManager:getItemByXMLFilename(self.configFileName)
	if v43_ ~= nil and v43_.configurations ~= nil then
		if v43_.configurationSets ~= nil and (#v43_.configurationSets > 0 and not ConfigurationUtil.getConfigurationsMatchConfigSets(self.configurations, v43_.configurationSets)) then
			local v44_, v45_ = ConfigurationUtil.getClosestConfigurationSet(self.configurations, v43_.configurationSets)
			if v44_ ~= nil then
				for v46_, v47_ in pairs(v44_.configurations) do
					self.configurations[v46_] = v47_
				end
				Logging.xmlInfo(self.xmlFile, "Savegame configurations do not match the configuration sets! Apply closest configuration set \'%s\' with %d matching configurations.", v44_.name, v45_)
			end
		end
		for v48_, _ in pairs(v43_.configurations) do
			local v49_ = StoreItemUtil.getDefaultConfigId(v43_, v48_)
			if self.configurations[v48_] == nil then
				ConfigurationUtil.setConfiguration(self, v48_, v49_)
			end
			ConfigurationUtil.addBoughtConfiguration(g_placeableConfigurationManager, self, v48_, v49_)
		end
		for v50_, v51_ in pairs(self.configurations) do
			if v43_.configurations[v50_] == nil then
				Logging.xmlWarning(self.xmlFile, "Configurations are not present anymore. Ignoring this configuration (%s)!", v50_)
				self.configurations[v50_] = nil
				self.boughtConfigurations[v50_] = nil
			else
				local v52_ = StoreItemUtil.getDefaultConfigId(v43_, v50_)
				if #v43_.configurations[v50_] < v51_ then
					Logging.xmlWarning(self.xmlFile, "Configuration with index \'%d\' is not present anymore. Using default configuration instead!", v51_)
					if self.boughtConfigurations[v50_] ~= nil then
						self.boughtConfigurations[v50_][v51_] = nil
						if next(self.boughtConfigurations[v50_]) == nil then
							self.boughtConfigurations[v50_] = nil
						end
					end
					ConfigurationUtil.setConfiguration(self, v50_, v52_)
				else
					ConfigurationUtil.addBoughtConfiguration(g_placeableConfigurationManager, self, v50_, v51_)
				end
			end
		end
	end
	SpecializationUtil.createSpecializationEnvironments(self, function(p53_, p54_)
		-- upvalues: (copy) self
		Logging.xmlError(self.xmlFile, "The placeable specialization \'%s\' could not be added because variable \'%s\' already exists!", p53_, p54_)
		self:setLoadingState(PlaceableLoadingState.ERROR)
	end)
	SpecializationUtil.raiseEvent(self, "onPreLoad", self.savegame)
	if self.loadingState ~= PlaceableLoadingState.OK then
		Logging.xmlError(self.xmlFile, "Placeable pre-loading failed!")
		self.xmlFile:delete()
		return false
	end
	ConfigurationUtil.raiseConfigurationItemEvent(self, "onPreLoad")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "placeable.filename", "placeable.base.filename")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "placeable.dayNightObjects", "Visibility Condition-Tab in GIANTS Editor / Exporter")
	self.preplacedIndex = placeableLoadingData:getPreplacedIndex()
	self.isPreplaced = self.preplacedIndex ~= nil
	self.customImageFilename = nil
	self.i3dFilename = Utils.getFilename(self.xmlFile:getValue("placeable.base.filename"), self.baseDirectory)
	if self.isPreplaced then
		self.i3dFilename = placeableLoadingData.customI3DFilename or self.i3dFilename
	end
	if self.i3dFilename ~= nil then
		local v55_, v56_ = Utils.getPathIsValid(self.i3dFilename)
		if not v55_ then
			Logging.xmlWarning(self.xmlFile, "Filename contains %s, which are not allowed! (%s)", v56_, "placeable.base.filename")
		end
	end
	self:setLoadingStep(SpecializationLoadStep.AWAIT_I3D)
	if self.isPreplaced then
		local v57_ = v42_:getPreplacedNodeByIndex(self.preplacedIndex)
		if v57_ == nil then
			Logging.xmlError(self.xmlFile, "Placeable loading failed. Preplaced node not defined!")
			self.xmlFile:delete()
			return false
		end
		removeFromPhysics(v57_)
		self:i3dFileLoaded(v57_, LoadI3DFailedReason.NONE, nil, nil)
	else
		self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.i3dFilename, true, false, self.i3dFileLoaded, self)
	end
	return true
end

function Placeable:i3dFileLoaded(i3dNode, failedReason, args, i3dLoadingId)
	if i3dNode == 0 then
		self:setLoadingState(PlaceableLoadingState.ERROR)
		Logging.xmlError(self.xmlFile, "Placeable i3d loading failed!")
		self:loadCallback()
		return
	else
		self.i3dNode = i3dNode
		self.rootNode = self.i3dNode
		if self.isDeleted then
			self:setLoadingState(PlaceableLoadingState.CANCELED)
			self:loadCallback()
		else
			g_asyncTaskManager:addTask(function()
				-- upvalues: (copy) self
				self:loadFinished()
			end)
		end
	end
end

-- Local values: savegame, uniqueId, farmId, tourId, uniqueId
function Placeable:loadFinished()
	self:setLoadingState(PlaceableLoadingState.OK)
	self:setLoadingStep(SpecializationLoadStep.LOAD)
	local v61_ = self.savegame
	self.age = 0
	self.propertyState = self.placeableLoadingData.propertyState
	self:setOwnerFarmId(self.placeableLoadingData.ownerFarmId, true)
	if v61_ == nil then
		if self.isPreplaced then
			self:setUniqueId((self.placeableLoadingData:getUniqueId()))
		end
	else
		local v62_ = v61_.xmlFile:getValue(v61_.key .. "#uniqueId", nil)
		if v62_ ~= nil then
			self:setUniqueId(v62_)
		end
		if not v61_.ignoreFarmId then
			local v63_ = v61_.xmlFile:getValue(v61_.key .. "#farmId", AccessHandler.EVERYONE)
			if g_farmManager.mergedFarms ~= nil and g_farmManager.mergedFarms[v63_] ~= nil then
				v63_ = g_farmManager.mergedFarms[v63_]
			end
			self:setOwnerFarmId(v63_, true)
		end
		self.tourId = nil
		local v64_ = v61_.xmlFile:getValue(v61_.key .. "#tourId")
		if v64_ ~= nil then
			self.tourId = v64_
			g_guidedTourManager:addPlaceable(self, self.tourId)
		end
	end
	self.price = self.placeableLoadingData.price
	if self.price == 0 or self.price == nil then
		self.price = StoreItemUtil.getDefaultPrice(self.storeItem, self.configurations)
	end
	if self.rootNode == nil or not entityExists(self.rootNode) then
		Logging.xmlError(self.xmlFile, "Placeable rootnode was already deleted!")
		self:setLoadingState(PlaceableLoadingState.ERROR)
		self:loadCallback()
		return
	else
		self.components = {}
		I3DUtil.loadI3DComponents(self.i3dNode, self.components)
		if not self.isPreplaced then
			link(getRootNode(), self.i3dNode)
		end
		self.i3dNode = nil
		if self.numComponents == 0 then
			Logging.xmlWarning(self.xmlFile, "No components defined for placeable!")
			self:setLoadingState(PlaceableLoadingState.ERROR)
			self:loadCallback()
			return
		else
			self.i3dMappings = {}
			I3DUtil.loadI3DMapping(self.xmlFile, "placeable", self.components, self.i3dMappings)
			if self.placeableLoadingData:applyPositionData(self) then
				self.canBeRenamed = self.xmlFile:getValue("placeable.base.canBeRenamed", false)
				self.canBeDeleted = self.xmlFile:getValue("placeable.base.canBeDeleted", true)
				self.boughtWithFarmland = self.xmlFile:getValue("placeable.base.boughtWithFarmland", false)
				self.buysFarmland = self.xmlFile:getValue("placeable.base.buysFarmland", false)
				self.buysFarmlandPriceScale = self.xmlFile:getValue("placeable.base.buysFarmland#priceScale", 1)
				ConfigurationUtil.raiseConfigurationItemEvent(self, "onLoad")
				SpecializationUtil.raiseEvent(self, "onLoad", v61_)
				if self.loadingState == PlaceableLoadingState.OK then
					self:setLoadingStep(SpecializationLoadStep.POST_LOAD)
					SpecializationUtil.raiseEvent(self, "onPostLoad", v61_)
					if self.loadingState == PlaceableLoadingState.OK then
						ConfigurationUtil.raiseConfigurationItemEvent(self, "onPostLoad")
						SpecializationUtil.raiseEvent(self, "onPreLoadFinished", self.savegame)
						self:setVisibility(false)
						if not self.isPreplaced then
							self:removeFromPhysics()
						end
						if #self.loadingTasks == 0 then
							self:onFinishedLoading()
						else
							self.readyForFinishLoading = true
							self:setLoadingStep(SpecializationLoadStep.AWAIT_SUB_I3D)
						end
						if StartParams.getIsSet("scriptDebug") then
							g_debugManager:addDrawable(self)
						end
					else
						Logging.xmlError(self.xmlFile, "Placeable post-loading failed!")
						self:loadCallback()
					end
				else
					Logging.xmlError(self.xmlFile, "Placeable loading failed!")
					self:loadCallback()
					return
				end
			else
				self:setLoadingState(PlaceableLoadingState.NO_SPACE)
				self:loadCallback()
				return
			end
		end
	end
end

-- Local values: id, spec, name, boughtWithFarmlandSavegameOverwrite, canBeDeletedOverwrite, customImageFilename, nameL10nKey
function Placeable:onFinishedLoading()
	if self.propertyState == PlaceablePropertyState.CONSTRUCTION_PREVIEW then
		I3DUtil.iterateRecursively(self.rootNode, function(p66_)
			if getHasClassId(p66_, ClassIds.SHAPE) and getIsTerrainDecal(p66_) then
				setIsTerrainDecal(p66_, false)
				setIsNonRenderable(p66_, false)
			end
		end)
	end
	self:setVisibility(true)
	if self.isServer and self.savegame ~= nil then
		if getXMLString(self.savegame.xmlFile.handle, self.savegame.key .. "#mapBoundId") ~= nil then
			Logging.xmlWarning(self.savegame.xmlFile, "Attribute \'mapBoundId\' is not supported anymore for \'%s\'. Use \'isPreplaced\' and \'uniqueId\' instead!", self.savegame.key)
		end
		self.isLoadingFromSavegameXML = true
		for v67_, v68_ in pairs(self.specializations) do
			local v69_ = self.specializationNames[v67_]
			if v68_.loadFromXMLFile ~= nil then
				v68_.loadFromXMLFile(self, self.savegame.xmlFile, self.savegame.key .. "." .. v69_, self.savegame.reset)
			end
		end
		self.isLoadingFromSavegameXML = false
		local v70_ = self.savegame.xmlFile:getValue(self.savegame.key .. "#boughtWithFarmlandOverwrite")
		if v70_ ~= nil then
			self.boughtWithFarmlandSavegameOverwrite = v70_
		end
		local v71_ = self.savegame.xmlFile:getValue(self.savegame.key .. "#canBeDeletedOverwrite")
		if v71_ ~= nil then
			self.canBeDeletedOverwrite = v71_
		end
		local v72_ = self.savegame.xmlFile:getValue(self.savegame.key .. ".customImage#filename")
		if v72_ ~= nil then
			self.customImageFilename = NetworkUtil.convertFromNetworkFilename(v72_)
		end
		self.nameCustom = self.savegame.xmlFile:getValue(self.savegame.key .. "#name")
		local v73_ = self.savegame.xmlFile:getValue(self.savegame.key .. "#nameL10nKey")
		if v73_ ~= nil then
			self:setNameL10nKey(v73_)
		end
		self.age = self.savegame.xmlFile:getValue(self.savegame.key .. "#age", 0)
		self.price = self.savegame.xmlFile:getValue(self.savegame.key .. "#price", self.price)
		if not self.savegame.ignoreFarmId then
			self:setOwnerFarmId(self.savegame.xmlFile:getValue(self.savegame.key .. "#farmId", AccessHandler.EVERYONE), true)
		end
		self.isLoadedFromSavegame = true
	end
	self:setLoadingStep(SpecializationLoadStep.FINISHED)
	SpecializationUtil.raiseEvent(self, "onLoadFinished", self.savegame)
	if self.isLoadedFromSavegame then
		self:finalizePlacement()
	end
	if self.isServer then
		self:setLoadingStep(SpecializationLoadStep.SYNCHRONIZED)
	end
	self.finishedLoading = true
	if self.placeableLoadingData.isRegistered then
		self:register()
	end
	self:loadCallback()
	self.savegame = nil
end
function Placeable.onLoadingError(p74_, p75_, ...)
	if p74_.xmlFile == nil then
		Logging.error(p75_, ...)
	else
		Logging.xmlError(p74_.xmlFile, p75_, ...)
		p74_.xmlFile:delete()
		p74_.xmlFile = nil
	end
	p74_:setLoadingState(PlaceableLoadingState.ERROR)
	p74_:loadCallback()
end

function Placeable:createLoadingTask(target)
	return SpecializationUtil.createLoadingTask(self, target)
end

function Placeable:finishLoadingTask(task)
	SpecializationUtil.finishLoadingTask(self, task)
end

-- Local values: placeableSystem, _, node
function Placeable:finalizePlacement()
	SpecializationUtil.raiseEvent(self, "onPreFinalizePlacement")
	self:addToPhysics()
	local v81_ = g_currentMission.placeableSystem
	v81_:addPlaceable(self)
	if self.isPreplaced then
		v81_:addPreplacedPlaceable(self)
	end
	g_currentMission:addOwnedItem(self)
	self:collectPickObjects(self.rootNode)
	for _, v82_ in pairs(self.pickObjects) do
		g_currentMission:addNodeObject(v82_, self)
	end
	if self.boughtWithFarmlandSavegameOverwrite == nil and self.boughtWithFarmland or self.boughtWithFarmlandSavegameOverwrite then
		if self.isServer then
			self:updateOwnership()
		end
		g_messageCenter:subscribe(MessageType.FARMLAND_OWNER_CHANGED, self.onFarmlandStateChanged, self)
	end
	SpecializationUtil.raiseEvent(self, "onFinalizePlacement")
	SpecializationUtil.raiseEvent(self, "onPostFinalizePlacement")
	if self:getNeedWeatherChanged() then
		g_messageCenter:subscribe(MessageType.DAY_NIGHT_CHANGED, self.weatherChanged, self)
	end
	if self:getNeedHourChanged() then
		g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.hourChanged, self)
	end
	if self:getNeedMinuteChanged() then
		g_messageCenter:subscribe(MessageType.MINUTE_CHANGED, self.minuteChanged, self)
	end
	if self:getNeedDayChanged() then
		g_messageCenter:subscribe(MessageType.DAY_CHANGED, self.dayChanged, self)
	end
	g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.periodChanged, self)
	g_messageCenter:publish(MessageType.FARM_PROPERTY_CHANGED, self:getOwnerFarmId())
end

-- Local values: placeableSystem, _, node
function Placeable:delete(immediate)
	self.markedForDeletion = true
	if g_currentMission.isExitingGame or immediate then
		if self.isDeleted then
			Logging.devError("Trying to delete a already deleted placeable")
			printCallstack()
		else
			g_messageCenter:unsubscribeAll(self)
			if self.tourId ~= nil then
				g_guidedTourManager:removePlaceable(self.tourId)
			end
			self.isDeleting = true
			SpecializationUtil.raiseEvent(self, "onPreDelete")
			local v85_ = g_currentMission.placeableSystem
			v85_:removePlaceable(self)
			g_currentMission:removeOwnedItem(self)
			if self.sharedLoadRequestId ~= nil then
				g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
				self.sharedLoadRequestId = nil
			end
			for _, v86_ in pairs(self.pickObjects) do
				g_currentMission:removeNodeObject(v86_)
			end
			SpecializationUtil.raiseEvent(self, "onDelete")
			if not self.isPreplaced and self.rootNode ~= nil then
				delete(self.rootNode)
				self.rootNode = nil
			end
			if self.isPreplaced then
				v85_:removePreplacedPlaceable(self)
			end
			if self.xmlFile ~= nil then
				self.xmlFile:delete()
				self.xmlFile = nil
			end
			self.isDeleting = false
			self.isDeleted = true
			Placeable:superClass().delete(self)
		end
	else
		g_currentMission.placeableSystem:markPlaceableForDeletion(self)
		return
	end
end

-- Local values: data, filename, isPreplaced, preplacedIndex, placeableSystem, uniqueId, posX, posY, posZ, rotX, rotY, rotZ, configurations, boughtConfigurations, configurationData, asyncCallbackFunction
function Placeable:readStream(streamId, connection, objectId)
	Placeable:superClass().readStream(self, streamId, connection, objectId)
	local v91_ = PlaceableLoadingData.new()
	local v92_
	if streamReadBool(streamId) then
		local v93_ = streamReadUInt16(streamId)
		local v94_ = g_currentMission.placeableSystem
		v92_ = v94_:getPreplacedFilenameByIndex(v93_)
		local v95_ = v94_:getPreplacedUniqueIdByIndex(v93_)
		v91_:setPreplacedIndex(v93_)
		v91_:setFilename(v92_)
		v91_:setUniqueId(v95_)
	else
		v92_ = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
		local v96_ = streamReadFloat32(streamId)
		local v97_ = streamReadFloat32(streamId)
		local v98_ = streamReadFloat32(streamId)
		local v99_ = streamReadFloat32(streamId)
		local v100_ = streamReadFloat32(streamId)
		local v101_ = streamReadFloat32(streamId)
		v91_:setFilename(v92_)
		v91_:setPosition(v96_, v97_, v98_)
		v91_:setRotation(v99_, v100_, v101_)
	end
	local v102_, v103_, v104_ = ConfigurationUtil.readConfigurationsFromStream(g_placeableConfigurationManager, streamId, connection, v92_)
	self.propertyState = PlaceablePropertyState.readStream(streamId)
	v91_:setPropertyState(self.propertyState)
	v91_:setOwnerFarmId(self.ownerFarmId)
	v91_:setConfigurations(v102_)
	v91_:setBoughtConfigurations(v103_)
	v91_:setConfigurationData(v104_)
	if self.loadingStep == SpecializationLoadStep.CREATED then
		v91_:loadPlaceableOnClient(self, function(_, p105_, p106_)
			if p106_ == PlaceableLoadingState.OK then
				g_client:onObjectFinishedAsyncLoading(p105_)
			else
				Logging.error("Failed to load placeable on client")
				printCallstack()
			end
		end, nil)
	else
		Logging.error("Try to intialize loading of a placeable that is already loading!")
	end
end

-- Local values: x, y, z, x_rot, y_rot, z_rot
function Placeable:writeStream(streamId, connection)
	Placeable:superClass().writeStream(self, streamId, connection)
	if streamWriteBool(streamId, self.isPreplaced) then
		streamWriteUInt16(streamId, self.preplacedIndex)
	else
		streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.configFileName))
		local v110_, v111_, v112_ = getTranslation(self.rootNode)
		local v113_, v114_, v115_ = getRotation(self.rootNode)
		streamWriteFloat32(streamId, v110_)
		streamWriteFloat32(streamId, v111_)
		streamWriteFloat32(streamId, v112_)
		streamWriteFloat32(streamId, v113_)
		streamWriteFloat32(streamId, v114_)
		streamWriteFloat32(streamId, v115_)
	end
	ConfigurationUtil.writeConfigurationsToStream(g_placeableConfigurationManager, streamId, connection, self.configFileName, self.configurations, self.boughtConfigurations, self.configurationData)
	PlaceablePropertyState.writeStream(streamId, self.propertyState)
end

-- Local values: _, spec, className, startBits, nameL10nKey
function Placeable:postReadStream(streamId, connection)
	self:finalizePlacement()
	if Placeable.DEBUG_NETWORK then
		print("-------------------------------------------------------------")
		print(self.configFileName)
		for _, v119_ in ipairs(self.eventListeners.onReadStream) do
			local v120_ = ClassUtil.getClassName(v119_)
			local v121_ = streamGetReadOffset(streamId)
			v119_.onReadStream(self, streamId, connection)
			print("  " .. tostring(v120_) .. " read " .. streamGetReadOffset(streamId) - v121_ .. " bits")
		end
	else
		SpecializationUtil.raiseEvent(self, "onReadStream", streamId, connection)
	end
	if streamReadBool(streamId) then
		self:setName(streamReadString(streamId), true)
	end
	if streamReadBool(streamId) then
		self:setNameL10nKey((streamReadString(streamId)))
	end
	if streamReadBool(streamId) then
		self.customImageFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
	end
	self:setLoadingStep(SpecializationLoadStep.SYNCHRONIZED)
	self:raiseActive()
end

-- Local values: _, spec, className, startBits
function Placeable:postWriteStream(streamId, connection)
	if Placeable.DEBUG_NETWORK then
		print("-------------------------------------------------------------")
		print(self.configFileName)
		for _, v125_ in ipairs(self.eventListeners.onWriteStream) do
			local v126_ = ClassUtil.getClassName(v125_)
			local v127_ = streamGetWriteOffset(streamId)
			v125_.onWriteStream(self, streamId, connection)
			print("  " .. tostring(v126_) .. " Wrote " .. streamGetWriteOffset(streamId) - v127_ .. " bits")
		end
	else
		SpecializationUtil.raiseEvent(self, "onWriteStream", streamId, connection)
	end
	if streamWriteBool(streamId, self.nameCustom ~= nil) then
		streamWriteString(streamId, self.nameCustom)
	end
	if streamWriteBool(streamId, self.nameL10nKey ~= nil) then
		streamWriteString(streamId, self.nameL10nKey)
	end
	if streamWriteBool(streamId, self.customImageFilename ~= nil) then
		streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.customImageFilename))
	end
end

-- Local values: _, spec, className, startBits
function Placeable:readUpdateStream(streamId, timestamp, connection)
	if Placeable.DEBUG_NETWORK_UPDATE then
		print("-------------------------------------------------------------")
		print(self.configFileName)
		for _, v132_ in ipairs(self.eventListeners.onReadUpdateStream) do
			local v133_ = ClassUtil.getClassName(v132_)
			local v134_ = streamGetReadOffset(streamId)
			v132_.onReadUpdateStream(self, streamId, timestamp, connection)
			print("  " .. tostring(v133_) .. " read " .. streamGetReadOffset(streamId) - v134_ .. " bits")
		end
	else
		SpecializationUtil.raiseEvent(self, "onReadUpdateStream", streamId, timestamp, connection)
	end
end

-- Local values: _, spec, className, startBits
function Placeable:writeUpdateStream(streamId, connection, dirtyMask)
	if Placeable.DEBUG_NETWORK_UPDATE then
		print("-------------------------------------------------------------")
		print(self.configFileName)
		for _, v139_ in ipairs(self.eventListeners.onWriteUpdateStream) do
			local v140_ = ClassUtil.getClassName(v139_)
			local v141_ = streamGetWriteOffset(streamId)
			v139_.onWriteUpdateStream(self, streamId, connection, dirtyMask)
			print("  " .. tostring(v140_) .. " Wrote " .. streamGetWriteOffset(streamId) - v141_ .. " bits")
		end
	else
		SpecializationUtil.raiseEvent(self, "onWriteUpdateStream", streamId, connection, dirtyMask)
	end
end

-- Local values: id, spec, name
function Placeable:saveToXMLFile(xmlFile, key, usedModNames)
	xmlFile:setValue(key .. "#uniqueId", self.uniqueId)
	if not self.isPreplaced then
		xmlFile:setValue(key .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.configFileName)))
		xmlFile:setValue(key .. "#position", getTranslation(self.rootNode))
		xmlFile:setValue(key .. "#rotation", getRotation(self.rootNode))
	end
	xmlFile:setValue(key .. "#age", self.age)
	xmlFile:setValue(key .. "#price", self.price)
	xmlFile:setValue(key .. "#farmId", self:getOwnerFarmId() or 1)
	if self.tourId ~= nil then
		xmlFile:setValue(key .. "#tourId", self.tourId)
	end
	if self.canBeRenamed and (self.nameCustom ~= nil and self.nameCustom:trim() ~= "") then
		xmlFile:setValue(key .. "#name", self.nameCustom)
	end
	if self.nameL10nKey ~= nil and g_i18n:hasText(self.nameL10nKey, self.customEnvironment) then
		xmlFile:setValue(key .. "#nameL10nKey", self.nameL10nKey)
	end
	if self.boughtWithFarmlandSavegameOverwrite ~= nil then
		xmlFile:setValue(key .. "#boughtWithFarmlandOverwrite", self.boughtWithFarmlandSavegameOverwrite)
	end
	if self.canBeDeletedOverwrite ~= nil then
		xmlFile:setValue(key .. "#canBeDeletedOverwrite", self.canBeDeletedOverwrite)
	end
	if self.customImageFilename ~= nil then
		xmlFile:setValue(key .. ".customImage#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.customImageFilename)))
	end
	ConfigurationUtil.saveConfigurationsToXMLFile(self.configFileName, xmlFile, key .. ".configuration", self.configurations, self.boughtConfigurations, self.configurationData)
	for v146_, v147_ in pairs(self.specializations) do
		local v148_ = self.specializationNames[v146_]
		if v147_.saveToXMLFile ~= nil then
			v147_.saveToXMLFile(self, xmlFile, key .. "." .. v148_, usedModNames)
		end
	end
end

function Placeable:getIsBeingDeleted()
	return self.markedForDeletion or (self.isDeleting or self.isDeleted)
end

function Placeable:setPropertyState(state)
	self.propertyState = state
end

function Placeable:getPropertyState()
	return self.propertyState
end

function Placeable:getPosition()
	return getWorldTranslation(self.rootNode)
end

-- Local values: x, _, z
function Placeable:getFarmlandId()
	local v155_, _, v156_ = getWorldTranslation(self.rootNode)
	return g_farmlandManager:getFarmlandIdAtWorldPosition(v155_, v156_)
end

-- Local values: posX, _, posZ, placeableFarmlandId
function Placeable:getIsOnFarmland(farmlandId)
	local v159_, _, v160_ = getWorldTranslation(self.rootNode)
	return g_farmlandManager:getFarmlandIdAtWorldPosition(v159_, v160_) == farmlandId
end

-- Local values: oldX, oldY, oldZ, oldRotX, oldRotY, oldRotZ
function Placeable:setPose(x, y, z, rotX, rotY, rotZ)
	self:removeFromPhysics()
	local v168_, v169_, v170_ = getWorldTranslation(self.rootNode)
	local v171_, v172_, v173_ = getWorldRotation(self.rootNode)
	setWorldTranslation(self.rootNode, x or v168_, y or v169_, z or v170_)
	setWorldRotation(self.rootNode, rotX or v171_, rotY or v172_, rotZ or v173_)
	self:addToPhysics()
end

-- Local values: _, component
function Placeable:setVisibility(state)
	for _, v176_ in pairs(self.components) do
		setVisibility(v176_.node, state)
	end
end

function Placeable:getIsSynchronized()
	return self.loadingStep == SpecializationLoadStep.SYNCHRONIZED
end

function Placeable:getIsPreplaced()
	return self.isPreplaced
end

function Placeable:getNeedsSaving()
	return true
end

function Placeable:getUniqueId()
	return self.uniqueId
end

function Placeable:setUniqueId(uniqueId)
	self.uniqueId = uniqueId
end

function Placeable:update(dt)
	SpecializationUtil.raiseEvent(self, "onUpdate", dt)
end

function Placeable:updateTick(dt)
	SpecializationUtil.raiseEvent(self, "onUpdateTick", dt)
end

function Placeable:draw()
	SpecializationUtil.raiseEvent(self, "onDraw")
end

function Placeable:drawDebug()
	SpecializationUtil.raiseEvent(self, "onDrawDebug")
end

function Placeable:getName()
	local v189_ = not self.nameCustom and (not self.nameL10n and self.storeItem)
	if v189_ then
		v189_ = self.storeItem.name
	end
	return v189_
end

function Placeable:getImageFilename()
	return self.customImageFilename or self.storeItem.imageFilename
end

function Placeable:getCanBeRenamedByFarm(farmId)
	local v193_ = self.canBeRenamed
	if v193_ then
		v193_ = self:getOwnerFarmId() == farmId
	end
	return v193_
end

function Placeable:setName(name, noEventSend)
	if not self.canBeRenamed then
		return false
	end
	if name and name:trim() == "" then
		return false
	end
	PlaceableNameEvent.sendEvent(self, name, noEventSend)
	self.nameCustom = name
	g_messageCenter:publish(MessageType.UNLOADING_STATIONS_CHANGED)
	g_messageCenter:publish(MessageType.LOADING_STATIONS_CHANGED)
	return true
end

-- Local values: mapCustomEnv
function Placeable:setNameL10nKey(nameL10nKey)
	local v199_ = string.gsub(nameL10nKey, "$l10n_", "")
	local v200_ = g_currentMission.missionInfo.customEnvironment
	if g_i18n:hasText(v199_, v200_) then
		self.nameL10nKey = v199_
		self.nameL10n = g_i18n:getText(v199_, v200_)
	end
end

-- Local values: serverFarmId, numPlaceables, _, existingPlaceable
function Placeable:onBuy()
	SpecializationUtil.raiseEvent(self, "onBuy")
	local v202_ = g_currentMission:getFarmId()
	local v203_ = 0
	for _, v204_ in ipairs(g_currentMission.placeableSystem.placeables) do
		if v204_:getOwnerFarmId() == v202_ then
			v203_ = v203_ + 1
		end
	end
	g_achievementManager:tryUnlock("NumPlaceables", v203_)
end

function Placeable:onSell()
	g_messageCenter:publish(MessageType.FARM_PROPERTY_CHANGED, self:getOwnerFarmId())
	SpecializationUtil.raiseEvent(self, "onSell")
end

function Placeable:getPrice()
	return self.price
end

-- Local values: storeItem, maxItemCount
function Placeable:canBuy()
	local v208_ = self.storeItem
	return v208_.maxItemCount == nil and true or g_currentMission:getNumOfItems(v208_, g_currentMission:getFarmId()) < v208_.maxItemCount
end

function Placeable:getCanBePlacedAt(x, y, z, farmId)
	return true, nil
end

function Placeable:canBeSold()
	return true, nil
end

function Placeable:getDestructionMethod()
	return Placeable.DESTRUCTION.SELL
end

function Placeable:previewNodeDestructionNodes(node)
	return nil
end

function Placeable:performNodeDestruction(node)
	return false, false
end

function Placeable:onFarmlandStateChanged(farmlandId, farmId, loadFromSavegame)
	if (self.boughtWithFarmlandSavegameOverwrite == nil and self.boughtWithFarmland or self.boughtWithFarmlandSavegameOverwrite) and self:getIsOnFarmland(farmlandId) then
		self:updateOwnership()
	end
end

function Placeable:onOwnerChanged() end

function Placeable:register(alreadySent)
	Placeable:superClass().register(self, alreadySent)
	SpecializationUtil.raiseEvent(self, "onRegistered", alreadySent)
end

function Placeable:clearDirtyMask()
	self.dirtyMask = 0
	SpecializationUtil.raiseEvent(self, "onDirtyMaskCleared")
end

function Placeable:setOwnerFarmId(farmId, noEventSend)
	if self.buysFarmland then
		g_farmlandManager:setLandOwnership(self:getFarmlandId(), farmId)
	end
	Placeable:superClass().setOwnerFarmId(self, farmId, noEventSend)
	if self.loadingStep > SpecializationLoadStep.LOAD then
		SpecializationUtil.raiseEvent(self, "onOwnerChanged")
	end
	if self.propertyState ~= PlaceablePropertyState.CONSTRUCTION_PREVIEW then
		g_currentMission:removeOwnedItem(self)
		g_currentMission:addOwnedItem(self)
	end
end

-- Local values: storeItem, farmId
function Placeable:updateOwnership()
	if self.isServer then
		local v218_ = g_storeManager:getItemByXMLFilename(self.configFileName)
		if v218_ == nil then
			Logging.error("Missing storeItem for placeable \'%s\'", self.configFileName)
		else
			local v219_ = g_farmlandManager:getFarmlandOwner(self:getFarmlandId())
			if (not v218_.canBeSold or self.boughtWithFarmlandSavegameOverwrite == nil and self.boughtWithFarmland or self.boughtWithFarmlandSavegameOverwrite) and v219_ == FarmlandManager.NO_OWNER_FARM_ID then
				v219_ = AccessHandler.NOBODY
			end
			if self.ownerFarmId ~= v219_ then
				self:setOwnerFarmId(v219_)
			end
		end
	else
		return
	end
end

-- Local values: name
function Placeable:setLoadingState(loadingState)
	if PlaceableLoadingState.getName(loadingState) == nil then
		printCallstack()
		Logging.error("Invalid loading state \'%s\'!", loadingState)
	else
		self.loadingState = loadingState
	end
end

-- Local values: numChildren, i
function Placeable:collectPickObjects(node)
	if getRigidBodyType(node) ~= RigidBodyType.NONE then
		local v224_ = self.pickObjects
		table.insert(v224_, node)
	end
	for v225_ = 1, getNumOfChildren(node) do
		self:collectPickObjects(getChildAt(node, v225_ - 1))
	end
end

function Placeable:setLoadingStep(loadingStep)
	SpecializationUtil.setLoadingStep(self, loadingStep)
end

-- Local values: i
function Placeable:setOverlayColor(r, g, b, alpha)
	if self.overlayColorNodes == nil then
		self.overlayColorNodes = {}
		self:setOverlayColorNodes(self.rootNode, self.overlayColorNodes)
	end
	for v233_ = 1, #self.overlayColorNodes do
		setShaderParameter(self.overlayColorNodes[v233_], "placeableColorScale", r, g, b, alpha, false)
	end
end

-- Local values: numChildren, i
function Placeable:setOverlayColorNodes(node, nodeTable)
	if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, "placeableColorScale") then
		nodeTable[#nodeTable + 1] = node
	end
	for v237_ = 0, getNumOfChildren(node) - 1 do
		self:setOverlayColorNodes(getChildAt(node, v237_), nodeTable)
	end
end

-- Local values: storeItem, multiplier, ageMultiplier
function Placeable:getDailyUpkeep()
	local v239_ = self.storeItem
	local v240_
	if v239_.lifetime == nil or v239_.lifetime == 0 then
		v240_ = 1
	else
		local v241_ = self.age / v239_.lifetime
		local v242_ = math.min(v241_, 1)
		v240_ = 1 + EconomyManager.MAX_DAILYUPKEEP_MULTIPLIER * v242_
	end
	return StoreItemUtil.getDailyUpkeep(v239_, self.configurations) * v240_
end

function Placeable:getSellPrice()
	if self.undoTimer > g_time - Placeable.UNDO_DURATION and (self.undoTimer > g_currentMission.lastConstructionScreenOpenTime and g_currentMission.lastConstructionScreenOpenTime > 0) then
		return self.price, true
	else
		return self:getMonetaryValue(), false
	end
end

-- Local values: priceMultiplier, maxAge
function Placeable:getMonetaryValue()
	local v245_ = 0.5
	local v246_ = self.storeItem.lifetime
	if v246_ ~= nil and v246_ ~= 0 then
		local v247_ = self.age / v246_
		local v248_ = -3.5 * math.min(v247_, 1)
		v245_ = v245_ * math.exp(v248_)
	end
	local v249_ = self.price * math.max(v245_, 0.05)
	return math.floor(v249_)
end

-- Local values: farmlandId, isOnPublicGround, isPreplaced
function Placeable:getSellAction()
	local v251_ = self:getFarmlandId()
	local v252_
	if v251_ == nil then
		v252_ = false
	else
		v252_ = g_farmlandManager:getFarmlandOwner(v251_) == FarmManager.SPECTATOR_FARM_ID
	end
	if self:getIsPreplaced() and (v252_ or not self.canBeDeleted) then
		return Placeable.SELL_AND_SPECTATOR_FARM
	elseif self.canBeDeletedOverwrite == false then
		return Placeable.SELL_AND_SPECTATOR_FARM
	else
		return Placeable.SELL_AND_DELETE
	end
end

function Placeable:addToPhysics()
	if self.rootNode ~= nil then
		addToPhysics(self.rootNode)
	end
end

function Placeable:removeFromPhysics()
	if self.rootNode ~= nil then
		removeFromPhysics(self.rootNode)
	end
end

function Placeable:setPreviewPosition(x, y, z, rotX, rotY, rotZ)
	setWorldTranslation(self.rootNode, x, y, z)
	setRotation(self.rootNode, 0, rotY, 0)
end

function Placeable:getNeedWeatherChanged()
	return false
end

function Placeable:weatherChanged()
	SpecializationUtil.raiseEvent(self, "onWeatherChanged")
end

function Placeable:getNeedHourChanged()
	return false
end

function Placeable:hourChanged(hour)
	SpecializationUtil.raiseEvent(self, "onHourChanged", hour)
end

function Placeable:getNeedMinuteChanged()
	return false
end

function Placeable:minuteChanged(minute)
	SpecializationUtil.raiseEvent(self, "onMinuteChanged", minute)
end

function Placeable:getNeedDayChanged()
	return false
end

function Placeable:dayChanged(day)
	SpecializationUtil.raiseEvent(self, "onDayChanged", day)
end

function Placeable:periodChanged(period)
	self.age = self.age + 1
	SpecializationUtil.raiseEvent(self, "onPeriodChanged", period)
end

-- Local values: numOwned, slotUsage
function Placeable.getSpecValueSlots(storeItem, realItem)
	local v270_ = g_currentMission:getNumOfItems(storeItem)
	local v271_ = g_currentMission.slotSystem:getStoreItemSlotUsage(storeItem, v270_ == 0)
	return string.format("+%0d $SLOTS$", v271_)
end
