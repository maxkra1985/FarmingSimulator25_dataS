-- Local values: AbstractBaleObject, AbstractBaleObject_mt, recursiveCopyShaderParameter, AbstractPackedBaleObject, AbstractPackedBaleObject_mt, AbstractPalletObject, AbstractPalletObject_mt, PlaceableObjectStorageActivatable_mt, PlaceableObjectStorageManualStoreActivatable_mt
PlaceableObjectStorage = {}
source("dataS/scripts/placeables/specializations/events/PlaceableObjectStorageErrorEvent.lua")
source("dataS/scripts/placeables/specializations/events/PlaceableObjectStorageStoreEvent.lua")
source("dataS/scripts/placeables/specializations/events/PlaceableObjectStorageUnloadEvent.lua")
PlaceableObjectStorage.COLLISION_MASK = CollisionFlag.VEHICLE + CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.TREE + CollisionFlag.PLAYER
PlaceableObjectStorage.NUM_BITS_OBJECT_INFO = 8
PlaceableObjectStorage.NUM_BITS_AMOUNT = 16
PlaceableObjectStorage.MAX_HUD_INFO_ENTRIES = 10

function PlaceableObjectStorage.prerequisitesPresent(self)
	return true
end

function PlaceableObjectStorage.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "canBeSold", PlaceableObjectStorage.canBeSold)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableObjectStorage.updateInfo)
end

function PlaceableObjectStorage.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "getObjectStorageSupportsFillType", PlaceableObjectStorage.getObjectStorageSupportsFillType)
	SpecializationUtil.registerFunction(placeableType, "getObjectStorageSupportsObject", PlaceableObjectStorage.getObjectStorageSupportsObject)
	SpecializationUtil.registerFunction(placeableType, "getObjectStorageCanStoreObject", PlaceableObjectStorage.getObjectStorageCanStoreObject)
	SpecializationUtil.registerFunction(placeableType, "getIsBaleSupportedByUnloadTrigger", PlaceableObjectStorage.getIsBaleSupportedByUnloadTrigger)
	SpecializationUtil.registerFunction(placeableType, "addObjectToObjectStorage", PlaceableObjectStorage.addObjectToObjectStorage)
	SpecializationUtil.registerFunction(placeableType, "addAbstactObjectToObjectStorage", PlaceableObjectStorage.addAbstactObjectToObjectStorage)
	SpecializationUtil.registerFunction(placeableType, "removeAbstractObjectsFromStorage", PlaceableObjectStorage.removeAbstractObjectsFromStorage)
	SpecializationUtil.registerFunction(placeableType, "spawnNextObjectStorageObject", PlaceableObjectStorage.spawnNextObjectStorageObject)
	SpecializationUtil.registerFunction(placeableType, "removeAbstractObjectFromStorage", PlaceableObjectStorage.removeAbstractObjectFromStorage)
	SpecializationUtil.registerFunction(placeableType, "setObjectStorageObjectInfosDirty", PlaceableObjectStorage.setObjectStorageObjectInfosDirty)
	SpecializationUtil.registerFunction(placeableType, "updateDirtyObjectStorageObjectInfos", PlaceableObjectStorage.updateDirtyObjectStorageObjectInfos)
	SpecializationUtil.registerFunction(placeableType, "updateObjectStorageObjectInfos", PlaceableObjectStorage.updateObjectStorageObjectInfos)
	SpecializationUtil.registerFunction(placeableType, "getObjectStorageObjectInfos", PlaceableObjectStorage.getObjectStorageObjectInfos)
	SpecializationUtil.registerFunction(placeableType, "updateObjectStorageVisualAreas", PlaceableObjectStorage.updateObjectStorageVisualAreas)
	SpecializationUtil.registerFunction(placeableType, "getHasPendingManualStoreObjects", PlaceableObjectStorage.getHasPendingManualStoreObjects)
	SpecializationUtil.registerFunction(placeableType, "storePendingManualObjects", PlaceableObjectStorage.storePendingManualObjects)
	SpecializationUtil.registerFunction(placeableType, "updateManualStoreActivatable", PlaceableObjectStorage.updateManualStoreActivatable)
	SpecializationUtil.registerFunction(placeableType, "onObjectStoragePlayerTriggerCallback", PlaceableObjectStorage.onObjectStoragePlayerTriggerCallback)
	SpecializationUtil.registerFunction(placeableType, "onObjectStorageObjectTriggerCallback", PlaceableObjectStorage.onObjectStorageObjectTriggerCallback)
	SpecializationUtil.registerFunction(placeableType, "onObjectStorageSpawnOverlapCallback", PlaceableObjectStorage.onObjectStorageSpawnOverlapCallback)
end

function PlaceableObjectStorage.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableObjectStorage)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableObjectStorage)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableObjectStorage)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableObjectStorage)
	SpecializationUtil.registerEventListener(placeableType, "onReadUpdateStream", PlaceableObjectStorage)
	SpecializationUtil.registerEventListener(placeableType, "onWriteUpdateStream", PlaceableObjectStorage)
	SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableObjectStorage)
end



function PlaceableObjectStorage.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("ObjectStorage")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".objectStorage.playerTrigger#node", "Player trigger node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".objectStorage.objectTrigger#node", "Object trigger node")
	schema:register(XMLValueType.STRING, basePath .. ".objectStorage#fillTypeCategories", "List of supported fill type categories (if no fill types defined, all are allowed)")
	schema:register(XMLValueType.STRING, basePath .. ".objectStorage#fillTypes", "List of supported fill types (if no fill types defined, all are allowed)")
	schema:register(XMLValueType.BOOL, basePath .. ".objectStorage#supportsBales", "Bales can be stored", true)
	schema:register(XMLValueType.BOOL, basePath .. ".objectStorage#supportsPallets", "Pallets can be stored", true)
	schema:register(XMLValueType.STRING, basePath .. ".objectStorage.supportedObject(?)#filename", "End part of the xml filename that can be stored (pallet or bale)")
	schema:register(XMLValueType.INT, basePath .. ".objectStorage.supportedObject(?)#amount", "Amount of this single object that can be stored (total capacity of the storage will still limit on top of this)", "unlimited")
	schema:register(XMLValueType.STRING, basePath .. ".objectStorage.supportedObject(?)#fillType", "FillType name to show in the shop")
	schema:register(XMLValueType.INT, basePath .. ".objectStorage#capacity", "Max. capacity", 250)
	schema:register(XMLValueType.FLOAT, basePath .. ".objectStorage#maxLength", "Max. length of objects to store", "unlimited")
	schema:register(XMLValueType.FLOAT, basePath .. ".objectStorage#maxHeight", "Max. height of objects to store", "unlimited")
	schema:register(XMLValueType.FLOAT, basePath .. ".objectStorage#maxWidth", "Max. width of objects to store", "unlimited")
	schema:register(XMLValueType.INT, basePath .. ".objectStorage#maxUnloadAmount", "Max. amount of objects that can be unloaded at a time", 25)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".objectStorage.spawnAreas.spawnArea(?)#startNode", "Start node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".objectStorage.spawnAreas.spawnArea(?)#endNode", "End node")
	schema:register(XMLValueType.FLOAT, basePath .. ".objectStorage.spawnAreas.spawnArea(?)#maxHeight", "Max. stacked height of spawned objects in the area", 3)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".objectStorage.storageAreas.storageArea(?)#startNode", "Start node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".objectStorage.storageAreas.storageArea(?)#endNode", "End node")
	schema:register(XMLValueType.FLOAT, basePath .. ".objectStorage.storageAreas.storageArea(?)#maxHeight", "Max. stacked height of spawned objects in the area", 3)
	schema:setXMLSpecializationType()
end

-- Local values: _, abstractObject
function PlaceableObjectStorage.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".object(?)#className", "Object class name")
	for _, v8_ in pairs(PlaceableObjectStorage.ABSTRACT_OBJECTS) do
		v8_.registerXMLPaths(schema, basePath .. ".object(?)")
	end
end
function PlaceableObjectStorage.initSpecialization()
	g_storeManager:addSpecType("objectStorageCapacity", "shopListAttributeIconCapacity", PlaceableObjectStorage.loadSpecValueCapacity, PlaceableObjectStorage.getSpecValueCapacity, StoreSpecies.PLACEABLE)
	g_storeManager:addSpecType("objectStorageFillTypes", "shopListAttributeIconFillTypes", PlaceableObjectStorage.loadSpecValueFillTypes, PlaceableObjectStorage.getSpecValueFillTypes, StoreSpecies.PLACEABLE)
end

-- Local values: spec
function PlaceableObjectStorage:onLoad(savegame)
	local v_u_10_ = self.spec_objectStorage
	v_u_10_.playerTriggerNode = self.xmlFile:getValue("placeable.objectStorage.playerTrigger#node", nil, self.components, self.i3dMappings)
	if v_u_10_.playerTriggerNode == nil then
		Logging.xmlWarning(self.xmlFile, "Missing player trigger for object storage")
	else
		addTrigger(v_u_10_.playerTriggerNode, "onObjectStoragePlayerTriggerCallback", self)
	end
	if self.isServer then
		v_u_10_.objectTriggerNode = self.xmlFile:getValue("placeable.objectStorage.objectTrigger#node", nil, self.components, self.i3dMappings)
		if v_u_10_.objectTriggerNode == nil then
			Logging.xmlWarning(self.xmlFile, "Missing object trigger for object storage")
		else
			addTrigger(v_u_10_.objectTriggerNode, "onObjectStorageObjectTriggerCallback", self)
		end
	end
	v_u_10_.supportedFillTypes = g_fillTypeManager:getFillTypesFromXML(self.xmlFile, "placeable.objectStorage#fillTypeCategories", "placeable.objectStorage#fillTypes", false)
	v_u_10_.supportsBales = self.xmlFile:getValue("placeable.objectStorage#supportsBales", true)
	v_u_10_.supportsPallets = self.xmlFile:getValue("placeable.objectStorage#supportsPallets", true)
	v_u_10_.supportedObjects = {}
	self.xmlFile:iterate("placeable.objectStorage.supportedObject", function(_, p11_)
		-- upvalues: (copy) self, (copy) v_u_10_
		local v12_ = {
			["filename"] = self.xmlFile:getValue(p11_ .. "#filename")
		}
		if v12_.filename ~= nil then
			v12_.amount = self.xmlFile:getValue(p11_ .. "#amount", math.huge)
			local v13_ = v_u_10_.supportedObjects
			table.insert(v13_, v12_)
		end
	end)
	v_u_10_.capacity = self.xmlFile:getValue("placeable.objectStorage#capacity", 250)
	v_u_10_.maxLength = self.xmlFile:getValue("placeable.objectStorage#maxLength", math.huge)
	v_u_10_.maxHeight = self.xmlFile:getValue("placeable.objectStorage#maxHeight", math.huge)
	v_u_10_.maxWidth = self.xmlFile:getValue("placeable.objectStorage#maxWidth", math.huge)
	v_u_10_.maxUnloadAmount = self.xmlFile:getValue("placeable.objectStorage#maxUnloadAmount", 25)
	v_u_10_.objectSpawn = {}
	v_u_10_.objectSpawn.isActive = false
	v_u_10_.objectSpawn.connection = nil
	v_u_10_.objectSpawn.objectInfoIndex = 1
	v_u_10_.objectSpawn.numObjectsToSpawn = 0
	v_u_10_.objectSpawn.overlapIsActive = false
	v_u_10_.objectSpawn.overlapObjectCount = 0
	v_u_10_.objectSpawn.nextSpawnPosition = { 0, 0, 0 }
	v_u_10_.objectSpawn.spawnAreaIndex = 1
	v_u_10_.objectSpawn.spawnAreaData = {
		0,
		0,
		0,
		0,
		0,
		1
	}
	v_u_10_.objectSpawn.spawnedObjects = {}
	v_u_10_.objectSpawn.area = {}
	self.xmlFile:iterate("placeable.objectStorage.spawnAreas.spawnArea", function(_, p14_)
		-- upvalues: (copy) self, (copy) v_u_10_
		local v15_ = {
			["startNode"] = self.xmlFile:getValue(p14_ .. "#startNode", nil, self.components, self.i3dMappings),
			["endNode"] = self.xmlFile:getValue(p14_ .. "#endNode", nil, self.components, self.i3dMappings)
		}
		if v15_.startNode == nil or v15_.endNode == nil then
			Logging.xmlWarning(self.xmlFile, "Incomplete spawn area definition in \'%s\'", p14_)
		else
			local v16_, _, v17_ = localToLocal(v15_.endNode, v15_.startNode, 0, 0, 0)
			v15_.sizeX = v16_
			v15_.sizeZ = v17_
			v15_.maxHeight = self.xmlFile:getValue(p14_ .. "#maxHeight", 3)
			local v18_ = v_u_10_.objectSpawn.area
			table.insert(v18_, v15_)
		end
	end)
	v_u_10_.storageArea = {}
	v_u_10_.storageArea.spawnNode = createTransformGroup("storageAreaSpawnNode")
	link(self.rootNode, v_u_10_.storageArea.spawnNode)
	v_u_10_.storageArea.spawnAreaIndex = 1
	v_u_10_.storageArea.spawnAreaData = {
		0,
		0,
		0,
		0,
		0,
		1
	}
	v_u_10_.storageArea.area = {}
	self.xmlFile:iterate("placeable.objectStorage.storageAreas.storageArea", function(_, p19_)
		-- upvalues: (copy) self, (copy) v_u_10_
		local v20_ = {
			["startNode"] = self.xmlFile:getValue(p19_ .. "#startNode", nil, self.components, self.i3dMappings),
			["endNode"] = self.xmlFile:getValue(p19_ .. "#endNode", nil, self.components, self.i3dMappings)
		}
		if v20_.startNode == nil or v20_.endNode == nil then
			Logging.xmlWarning(self.xmlFile, "Incomplete spawn area definition in \'%s\'", p19_)
		else
			local v21_, _, v22_ = localToLocal(v20_.endNode, v20_.startNode, 0, 0, 0)
			v20_.sizeX = v21_
			v20_.sizeZ = v22_
			v20_.maxHeight = self.xmlFile:getValue(p19_ .. "#maxHeight", 3)
			local v23_ = v_u_10_.storageArea.area
			table.insert(v23_, v20_)
		end
	end)
	v_u_10_.storedObjects = {}
	v_u_10_.objectInfos = {}
	v_u_10_.pendingObjects = {}
	v_u_10_.lastPendingManualObjectsState = false
	v_u_10_.numStoredObjects = 0
	v_u_10_.objectInfosUpdateTimer = 0
	v_u_10_.pendingVisualAreaUpdates = {}
	v_u_10_.texts = {}
	v_u_10_.texts.warningNotEmpty = g_i18n:getText("info_objectStorageNotEmpty")
	v_u_10_.texts.totalCapacity = g_i18n:getText("ui_silos_totalCapacity")
	v_u_10_.texts.otherElements = g_i18n:getText("helpLine_IconOverview_Others")
	v_u_10_.activatable = PlaceableObjectStorageActivatable.new(self)
	v_u_10_.manualStoreActivatable = PlaceableObjectStorageManualStoreActivatable.new(self)
	v_u_10_.dirtyFlag = self:getNextDirtyFlag()
end

function PlaceableObjectStorage:loadFromXMLFile(xmlFile, key)
	xmlFile:iterate(key .. ".object", function(_, p27_)
		-- upvalues: (copy) xmlFile, (copy) self
		local v28_ = xmlFile:getValue(p27_ .. "#className")
		if v28_ == nil then
			Logging.xmlWarning(xmlFile, "Unable to find object class \'%s\' for stored object in \'%s\'", v28_, p27_)
		else
			local v29_ = PlaceableObjectStorage.ABSTRACT_OBJECTS_BY_CLASS_NAME[v28_]
			if v29_ ~= nil then
				v29_.loadFromXMLFile(self, xmlFile, p27_)
				return
			end
		end
	end)
	self:setObjectStorageObjectInfosDirty()
end

-- Local values: spec, i, object, objectKey
function PlaceableObjectStorage:saveToXMLFile(xmlFile, key, usedModNames)
	local v33_ = self.spec_objectStorage
	for v34_ = 1, #v33_.storedObjects do
		local v35_ = v33_.storedObjects[v34_]
		local v36_ = string.format("%s.object(%d)", key, v34_ - 1)
		xmlFile:setValue(v36_ .. "#className", v35_.REFERENCE_CLASS_NAME)
		v35_:saveToXMLFile(self, xmlFile, v36_)
	end
end

-- Local values: spec, i, object, _
function PlaceableObjectStorage:onDelete()
	local v38_ = self.spec_objectStorage
	if v38_.playerTriggerNode ~= nil then
		removeTrigger(v38_.playerTriggerNode)
	end
	if v38_.objectTriggerNode ~= nil then
		removeTrigger(v38_.objectTriggerNode)
	end
	if v38_.storedObjects ~= nil then
		for v39_ = #v38_.storedObjects, 1, -1 do
			v38_.storedObjects[v39_]:delete()
			v38_.storedObjects[v39_] = nil
		end
	end
	v38_.numStoredObjects = 0
	if v38_.pendingObjects ~= nil then
		for v40_, _ in pairs(v38_.pendingObjects) do
			v40_:removeDeleteListener(self, PlaceableObjectStorage.onPendingObjectDelete)
			v38_.pendingObjects[v40_] = nil
		end
	end
	g_currentMission.activatableObjectsSystem:removeActivatable(v38_.activatable)
	g_currentMission.activatableObjectsSystem:removeActivatable(v38_.manualStoreActivatable)
end

-- Local values: spec, numObjectInfos, i, objectInfo, abstractObjectId, abstractObjectClass, i
function PlaceableObjectStorage:onReadStream(streamId, connection)
	if connection:getIsServer() then
		local v44_ = self.spec_objectStorage
		v44_.objectInfos = {}
		for _ = 1, streamReadUIntN(streamId, PlaceableObjectStorage.NUM_BITS_OBJECT_INFO) do
			local v45_ = {
				["numObjects"] = streamReadUIntN(streamId, PlaceableObjectStorage.NUM_BITS_AMOUNT)
			}
			local v46_ = streamReadUIntN(streamId, 2)
			v45_.objects = { PlaceableObjectStorage.ABSTRACT_OBJECTS_BY_ID[v46_].readStream(streamId, connection) }
			local v47_ = v44_.objectInfos
			table.insert(v47_, v45_)
		end
		v44_.numStoredObjects = 0
		for v48_ = 1, #v44_.objectInfos do
			v44_.numStoredObjects = v44_.numStoredObjects + v44_.objectInfos[v48_].numObjects
		end
		self:updateObjectStorageVisualAreas()
	end
end

-- Local values: spec, objectInfos, i, objectInfo
function PlaceableObjectStorage:onWriteStream(streamId, connection)
	if not connection:getIsServer() then
		local v52_ = self.spec_objectStorage.objectInfos
		streamWriteUIntN(streamId, #v52_, PlaceableObjectStorage.NUM_BITS_OBJECT_INFO)
		for v53_ = 1, #v52_ do
			local v54_ = v52_[v53_]
			streamWriteUIntN(streamId, v54_.numObjects, PlaceableObjectStorage.NUM_BITS_AMOUNT)
			streamWriteUIntN(streamId, v54_.objects[1].ABSTRACT_OBJECT_ID, 2)
			v54_.objects[1]:writeStream(streamId, connection)
		end
	end
end

-- Local values: spec
function PlaceableObjectStorage:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		if streamReadBool(streamId) then
			PlaceableObjectStorage.onReadStream(self, streamId, connection)
		end
		local v58_ = self.spec_objectStorage
		if streamReadBool(streamId) then
			g_currentMission.activatableObjectsSystem:addActivatable(v58_.manualStoreActivatable)
			return
		end
		g_currentMission.activatableObjectsSystem:removeActivatable(v58_.manualStoreActivatable)
	end
end

function PlaceableObjectStorage:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v63_ = streamWriteBool
		local v64_ = self.spec_objectStorage.dirtyFlag
		if v63_(streamId, bit32.band(dirtyMask, v64_) ~= 0) then
			PlaceableObjectStorage.onWriteStream(self, streamId, connection)
		end
		streamWriteBool(streamId, self:getHasPendingManualStoreObjects())
	end
end

-- Local values: spec, spawnArea, objectInfo, objectToSpawn, ox, oy, oz, _, _, _, _, cx, cy, cz, rx, ry, rz, object, _, canStoreObject, _, i, pendingVisualAreaUpdate
function PlaceableObjectStorage:onUpdate(dt)
	local v67_ = self.spec_objectStorage
	if self.isServer then
		if v67_.objectSpawn.isActive then
			if not v67_.objectSpawn.overlapIsActive then
				if v67_.objectSpawn.overlapObjectCount == 0 then
					local v68_ = v67_.objectSpawn.area[v67_.objectSpawn.spawnAreaIndex]
					local v69_ = v67_.objectInfos[v67_.objectSpawn.objectInfoIndex]
					local v70_ = v69_.objects[1]
					local v71_, v72_, v73_, _, _, _, _ = v70_:getSpawnInfo()
					local v74_, v75_, v76_ = localToWorld(v68_.startNode, v67_.objectSpawn.nextSpawnPosition[1] + v71_, v67_.objectSpawn.nextSpawnPosition[2] + v72_, v67_.objectSpawn.nextSpawnPosition[3] + v73_)
					local v77_, v78_, v79_ = getWorldRotation(v68_.startNode)
					if v70_ ~= nil then
						self:removeAbstractObjectFromStorage(v70_, v74_, v75_, v76_, v77_, v78_, v79_)
						table.remove(v69_.objects, 1)
					end
					v67_.objectSpawn.numObjectsToSpawn = v67_.objectSpawn.numObjectsToSpawn - 1
				end
				self:spawnNextObjectStorageObject(v67_.objectSpawn.overlapObjectCount == 0)
			end
			self:raiseActive()
		end
		for v80_, _ in pairs(v67_.pendingObjects) do
			local v81_, _ = self:getObjectStorageCanStoreObject(v80_, true)
			if v81_ then
				self:addObjectToObjectStorage(v80_)
				self:setObjectStorageObjectInfosDirty()
				v67_.pendingObjects[v80_] = nil
				v80_:removeDeleteListener(self, PlaceableObjectStorage.onPendingObjectDelete)
				self:updateManualStoreActivatable()
			else
				self:raiseActive()
			end
		end
	end
	if v67_.objectInfosUpdateTimer > 0 then
		v67_.objectInfosUpdateTimer = v67_.objectInfosUpdateTimer - dt
		if v67_.objectInfosUpdateTimer <= 0 then
			self:updateObjectStorageObjectInfos()
			self:updateObjectStorageVisualAreas()
			self:raiseDirtyFlags(v67_.dirtyFlag)
			v67_.objectInfosUpdateTimer = 0
		end
		self:raiseActive()
	end
	for v82_ = #v67_.pendingVisualAreaUpdates, 1, -1 do
		if v67_.pendingVisualAreaUpdates[v82_].spawnNextObjectInfo() then
			self:raiseActive()
		else
			table.remove(v67_.pendingVisualAreaUpdates, v82_)
		end
	end
end

-- Local values: spec, found, i
function PlaceableObjectStorage:getObjectStorageSupportsFillType(fillTypeIndex)
	local v85_ = self.spec_objectStorage
	if fillTypeIndex == nil or fillTypeIndex == FillType.UNKNOWN then
		return #v85_.supportedFillTypes == 0
	end
	local v86_ = #v85_.supportedFillTypes == 0
	for v87_ = 1, #v85_.supportedFillTypes do
		if fillTypeIndex == v85_.supportedFillTypes[v87_] then
			v86_ = true
		end
	end
	return v86_ and true or false
end

-- Local values: spec, abstractObjectClass, i
function PlaceableObjectStorage:getObjectStorageSupportsObject(object)
	local v90_ = self.spec_objectStorage
	local v91_ = PlaceableObjectStorage.ABSTRACT_OBJECTS_BY_CLASS_NAME[ClassUtil.getClassNameByObject(object)]
	if v91_ ~= nil and not v91_.isObjectSupported(self, object) then
		return false
	end
	for v92_ = 1, #v90_.storedObjects do
		if object == v90_.storedObjects[v92_]:getRealObject() then
			return false
		end
	end
	return true
end

-- Local values: spec, isSupported, filename, i, supportedObject, storedAmount, j, objectFilename, abstractObjectClass
function PlaceableObjectStorage:getObjectStorageCanStoreObject(object, automatically)
	local v96_ = self.spec_objectStorage
	if v96_.objectSpawn.isActive then
		return false
	end
	if #v96_.storedObjects >= v96_.capacity then
		return false, PlaceableObjectStorageErrorEvent.ERROR_STORAGE_IS_FULL
	end
	if #v96_.supportedObjects > 0 then
		local v97_ = object.configFileName or object.xmlFilename
		local v98_ = false
		for v99_ = 1, #v96_.supportedObjects do
			local v100_ = v96_.supportedObjects[v99_]
			if v97_:endsWith(v100_.filename) then
				local v101_ = 0
				v98_ = true
				for v102_ = 1, #v96_.storedObjects do
					if v96_.storedObjects[v102_]:getXMLFilename() == v97_ then
						v101_ = v101_ + 1
					end
				end
				if v100_.amount <= v101_ then
					return false, PlaceableObjectStorageErrorEvent.ERROR_MAX_AMOUNT_FOR_OBJECT_REACHED
				end
			end
		end
		if not v98_ then
			return false, PlaceableObjectStorageErrorEvent.ERROR_OBJECT_NOT_SUPPORTED
		end
	end
	local v103_ = PlaceableObjectStorage.ABSTRACT_OBJECTS_BY_CLASS_NAME[ClassUtil.getClassNameByObject(object)]
	if v103_ ~= nil then
		if not v103_.canStoreObject(self, object) then
			return false
		end
		if automatically and not v103_.canStoreObjectAutomatically(self, object) then
			return false
		end
	end
	return true
end

function PlaceableObjectStorage:getIsBaleSupportedByUnloadTrigger(bale)
	return self:getObjectStorageSupportsObject(bale)
end

-- Local values: abstractObjectClass, abstractObject
function PlaceableObjectStorage:addObjectToObjectStorage(object, loadedFromSavegame)
	local v109_ = PlaceableObjectStorage.ABSTRACT_OBJECTS_BY_CLASS_NAME[ClassUtil.getClassNameByObject(object)]
	if v109_ ~= nil then
		local v110_ = v109_.new()
		v110_:addToStorage(self, object, loadedFromSavegame)
		self:addAbstactObjectToObjectStorage(v110_)
	end
end

-- Local values: spec
function PlaceableObjectStorage:addAbstactObjectToObjectStorage(abstractObject)
	local v113_ = self.spec_objectStorage
	local v114_ = v113_.storedObjects
	table.insert(v114_, abstractObject)
	v113_.numStoredObjects = #v113_.storedObjects
end

-- Local values: spec, i
function PlaceableObjectStorage:removeAbstractObjectsFromStorage(objectInfoIndex, amount, connection)
	local v119_ = self.spec_objectStorage
	if not v119_.objectSpawn.isActive then
		if v119_.objectInfosUpdateTimer ~= 0 then
			return
		end
		if v119_.objectInfos[objectInfoIndex] == nil or v119_.objectInfos[objectInfoIndex].numObjects < amount then
			return
		end
		v119_.objectSpawn.isActive = true
		v119_.objectSpawn.connection = connection
		v119_.objectSpawn.objectInfoIndex = objectInfoIndex
		v119_.objectSpawn.numObjectsToSpawn = amount
		v119_.objectSpawn.overlapIsActive = false
		v119_.objectSpawn.overlapObjectCount = 0
		v119_.objectSpawn.spawnAreaIndex = 1
		local v120_ = v119_.objectSpawn.spawnAreaData
		local v121_ = v119_.objectSpawn.spawnAreaData
		local v122_ = v119_.objectSpawn.spawnAreaData
		local v123_ = v119_.objectSpawn.spawnAreaData
		local v124_ = v119_.objectSpawn.spawnAreaData
		local v125_ = v119_.objectSpawn.spawnAreaData
		v120_[1] = 0
		v121_[2] = 0
		v122_[3] = 0
		v123_[4] = 0
		v124_[5] = 0
		v125_[6] = math.huge
		for v126_ = #v119_.objectSpawn.spawnedObjects, 1, -1 do
			v119_.objectSpawn.spawnedObjects[v126_] = nil
		end
		self:spawnNextObjectStorageObject()
	end
end
function PlaceableObjectStorage.getNextSpawnAreaAndOffset(p127_, p128_, p129_, p130_, p131_, p132_, p133_, p134_, p135_, p136_, p137_, p138_, p139_)
	local v140_ = p127_[p128_]
	if v140_ == nil then
		return nil
	elseif v140_.sizeX <= p134_ then
		return PlaceableObjectStorage.getNextSpawnAreaAndOffset(p127_, p128_ + 1, 0, 0, 0, 0, 0, p134_, p135_, p136_, p137_, math.huge, false)
	elseif v140_.sizeZ <= p136_ then
		return PlaceableObjectStorage.getNextSpawnAreaAndOffset(p127_, p128_ + 1, 0, 0, 0, 0, 0, p134_, p135_, p136_, p137_, math.huge, false)
	else
		local v141_ = p129_ + p134_ * 0.5
		local v142_ = p131_ + p136_ * 0.5
		local v143_ = math.max(p135_, 0.1)
		local v144_ = v140_.maxHeight / v143_
		local v145_ = math.floor(v144_)
		local v146_
		if p138_ < math.min(p137_, v145_) and p139_ ~= false then
			v146_ = p138_ + 1
			v142_ = v142_ - p136_
			p130_ = (v146_ - 1) * v143_
		else
			v146_ = 1
		end
		local v147_ = v142_ + p136_ * 0.5
		local v148_ = math.max(p133_, v147_)
		if v140_.sizeZ < v148_ then
			return PlaceableObjectStorage.getNextSpawnAreaAndOffset(p127_, p128_, p132_, p130_, 0, p132_, 0, p134_, v143_, p136_, p137_, math.huge, p139_)
		else
			local v149_ = v141_ + p134_ * 0.5
			local v150_ = math.max(p132_, v149_)
			if v140_.sizeX < v141_ then
				return PlaceableObjectStorage.getNextSpawnAreaAndOffset(p127_, p128_ + 1, 0, 0, 0, 0, 0, p134_, v143_, p136_, p137_, math.huge, false)
			else
				return p128_, v141_, p130_, v142_, v141_ - p134_ * 0.5, 0, v142_ + p136_ * 0.5, v150_, v148_, v146_
			end
		end
	end
end

-- Local values: spec, spawnErrorId, objectInfo, objectToSpawn, limitedObjectId, errorId, _, _, _, width, height, length, maxStackHeight, areaIndex, spawnX, spawnY, spawnZ, offsetX, offsetY, offsetZ, nextOffsetX, nextOffsetZ, stackIndex, spawnArea, cx, cy, cz, rx, ry, rz, i
function PlaceableObjectStorage:spawnNextObjectStorageObject(lastSuccess)
	local v153_ = self.spec_objectStorage
	local v154_ = nil
	if v153_.objectSpawn.numObjectsToSpawn > 0 then
		local v155_ = v153_.objectInfos[v153_.objectSpawn.objectInfoIndex].objects[1]
		local v156_, v157_ = v155_:getLimitedObjectId()
		if v156_ == nil or g_currentMission.slotSystem:getCanAddLimitedObjects(v156_, 1) then
			local _, _, _, v158_, v159_, v160_, v161_ = v155_:getSpawnInfo()
			local v162_ = v161_ > 1.001 and math.huge or v161_
			local v163_, v164_, v165_, v166_, v167_, v168_, v169_, v170_, v171_, v172_ = PlaceableObjectStorage.getNextSpawnAreaAndOffset(v153_.objectSpawn.area, v153_.objectSpawn.spawnAreaIndex, v153_.objectSpawn.spawnAreaData[1], v153_.objectSpawn.spawnAreaData[2], v153_.objectSpawn.spawnAreaData[3], v153_.objectSpawn.spawnAreaData[4], v153_.objectSpawn.spawnAreaData[5], v158_, v159_, v160_, v162_, v153_.objectSpawn.spawnAreaData[6], lastSuccess)
			if v163_ ~= nil then
				local v173_ = v153_.objectSpawn
				local v174_ = v153_.objectSpawn.spawnAreaData
				local v175_ = v153_.objectSpawn.spawnAreaData
				local v176_ = v153_.objectSpawn.spawnAreaData
				local v177_ = v153_.objectSpawn.spawnAreaData
				local v178_ = v153_.objectSpawn.spawnAreaData
				local v179_ = v153_.objectSpawn.spawnAreaData
				v173_.spawnAreaIndex = v163_
				v174_[1] = v167_
				v175_[2] = v168_
				v176_[3] = v169_
				v177_[4] = v170_
				v178_[5] = v171_
				v179_[6] = v172_
				local v180_ = v153_.objectSpawn.area[v153_.objectSpawn.spawnAreaIndex]
				local v181_, v182_, v183_ = localToWorld(v180_.startNode, v164_, v165_ + v159_ * 0.5, v166_)
				local v184_, v185_, v186_ = getWorldRotation(v180_.startNode)
				local v187_ = v153_.objectSpawn.nextSpawnPosition
				local v188_ = v153_.objectSpawn.nextSpawnPosition
				local v189_ = v153_.objectSpawn.nextSpawnPosition
				v187_[1] = v164_
				v188_[2] = v165_
				v189_[3] = v166_
				v153_.objectSpawn.overlapIsActive = true
				v153_.objectSpawn.overlapObjectCount = 0
				overlapBoxAsync(v181_, v182_, v183_, v184_, v185_, v186_, v158_ * 0.5, v159_ * 0.5, v160_ * 0.5, "onObjectStorageSpawnOverlapCallback", self, PlaceableObjectStorage.COLLISION_MASK, true, true, false, true)
				self:raiseActive()
				return
			end
		else
			v154_ = v157_
		end
	end
	if v153_.objectSpawn.isActive then
		if v153_.objectSpawn.numObjectsToSpawn > 0 and (v153_.objectSpawn.connection ~= nil and g_server ~= nil) then
			v153_.objectSpawn.connection:sendEvent(PlaceableObjectStorageErrorEvent.new(self, v154_ or PlaceableObjectStorageErrorEvent.ERROR_NOT_ENOUGH_SPACE))
		end
		v153_.objectSpawn.isActive = false
		v153_.objectSpawn.connection = nil
		v153_.objectSpawn.objectInfoIndex = 1
		v153_.objectSpawn.numObjectsToSpawn = 0
		for v190_ = #v153_.objectSpawn.spawnedObjects, 1, -1 do
			v153_.objectSpawn.spawnedObjects[v190_] = nil
		end
		self:setObjectStorageObjectInfosDirty()
	end
end

-- Local values: spec, i
function PlaceableObjectStorage:removeAbstractObjectFromStorage(abstractObject, x, y, z, rx, ry, rz)
	local v199_ = self.spec_objectStorage
	for v200_ = 1, #v199_.storedObjects do
		if v199_.storedObjects[v200_] == abstractObject then
			table.remove(v199_.storedObjects, v200_)
			abstractObject:removeFromStorage(self, x, y, z, rx, ry, rz, PlaceableObjectStorage.onObjectFromStorageSpawned)
		end
	end
	v199_.numStoredObjects = #v199_.storedObjects
end

-- Local values: spec
function PlaceableObjectStorage:onObjectFromStorageSpawned(spawnedObject)
	local v203_ = self.spec_objectStorage
	if v203_.objectSpawn.isActive then
		local v204_ = v203_.objectSpawn.spawnedObjects
		table.insert(v204_, spawnedObject)
	end
end

-- Local values: spec
function PlaceableObjectStorage:setObjectStorageObjectInfosDirty()
	self.spec_objectStorage.objectInfosUpdateTimer = 1000
	self:raiseActive()
end

-- Local values: spec
function PlaceableObjectStorage:updateDirtyObjectStorageObjectInfos()
	if self.spec_objectStorage.objectInfosUpdateTimer > 0 then
		self:updateObjectStorageObjectInfos()
	end
end

-- Local values: spec, objectInfos, i, object, foundInfo, j, objectInfo, objectInfo
function PlaceableObjectStorage:updateObjectStorageObjectInfos()
	local v208_ = self.spec_objectStorage
	local v209_ = {}
	for v210_ = 1, #v208_.storedObjects do
		local v211_ = v208_.storedObjects[v210_]
		local v212_ = false
		for v213_ = 1, #v209_ do
			local v214_ = v209_[v213_]
			if v211_:getIsIdentical(v214_.objects[1]) then
				local v215_ = v214_.objects
				table.insert(v215_, v211_)
				v214_.numObjects = #v214_.objects
				v212_ = true
			end
		end
		if not v212_ then
			table.insert(v209_, {
				["objects"] = { v211_ },
				["numObjects"] = 1
			})
		end
	end
	table.sort(v209_, function(p216_, p217_)
		local _, _, _, v218_, _, _, _ = p216_.objects[1]:getSpawnInfo()
		local _, _, _, v219_, _, _, _ = p217_.objects[1]:getSpawnInfo()
		return v218_ < v219_
	end)
	v208_.objectInfos = v209_
end

function PlaceableObjectStorage:getObjectStorageObjectInfos()
	return self.spec_objectStorage.objectInfos
end

-- Local values: spec, area, oldSpawnNode, pendingVisualAreaUpdate, i, objectInfo, objectToSpawn, ox, oy, oz, width, height, length, maxStackHeight, j, areaIndex, spawnX, spawnY, spawnZ, offsetX, offsetY, offsetZ, nextOffsetX, nextOffsetZ, stackIndex, spawnArea, cx, cy, cz, rx, ry, rz
function PlaceableObjectStorage:updateObjectStorageVisualAreas()
	local v222_ = self.spec_objectStorage
	local v223_ = v222_.storageArea
	local v224_ = v223_.spawnNode
	v223_.spawnNode = createTransformGroup("storageAreaSpawnNode")
	link(self.rootNode, v223_.spawnNode)
	setVisibility(v223_.spawnNode, false)
	local v_u_226_ = {
		["oldSpawnNode"] = v224_,
		["newSpawnNode"] = v223_.spawnNode,
		["objectInfosToSpawn"] = {},
		["spawnNextObjectInfo"] = function()
			-- upvalues: (copy) v_u_226_
			if #v_u_226_.objectInfosToSpawn <= 0 then
				delete(v_u_226_.oldSpawnNode)
				if entityExists(v_u_226_.newSpawnNode) then
					setVisibility(v_u_226_.newSpawnNode, true)
				end
				return false
			end
			local v225_ = v_u_226_.objectInfosToSpawn[1]
			v225_.objects[1]:spawnVisualObjects(v225_.visualSpawnInfos)
			table.remove(v_u_226_.objectInfosToSpawn, 1)
			return true
		end
	}
	local v227_ = v223_.spawnAreaData
	local v228_ = v223_.spawnAreaData
	local v229_ = v223_.spawnAreaData
	local v230_ = v223_.spawnAreaData
	local v231_ = v223_.spawnAreaData
	local v232_ = v223_.spawnAreaData
	v223_.spawnAreaIndex = 1
	v227_[1] = 0
	v228_[2] = 0
	v229_[3] = 0
	v230_[4] = 0
	v231_[5] = 0
	v232_[6] = math.huge
	for v233_ = 1, #v222_.objectInfos do
		local v234_ = v222_.objectInfos[v233_]
		v234_.visualSpawnInfos = {}
		v223_.spawnAreaData[6] = math.huge
		local v235_, v236_, v237_, v238_, v239_, v240_, v241_ = v234_.objects[1]:getSpawnInfo()
		local v242_ = v241_ > 1.001 and math.huge or v241_
		for _ = 1, v234_.numObjects do
			local v243_, v244_, v245_, v246_, v247_, v248_, v249_, v250_, v251_, v252_ = PlaceableObjectStorage.getNextSpawnAreaAndOffset(v223_.area, v223_.spawnAreaIndex, v223_.spawnAreaData[1], v223_.spawnAreaData[2], v223_.spawnAreaData[3], v223_.spawnAreaData[4], v223_.spawnAreaData[5], v238_, v239_, v240_, v242_, v223_.spawnAreaData[6], true)
			if v243_ ~= nil then
				local v253_ = v223_.spawnAreaData
				local v254_ = v223_.spawnAreaData
				local v255_ = v223_.spawnAreaData
				local v256_ = v223_.spawnAreaData
				local v257_ = v223_.spawnAreaData
				local v258_ = v223_.spawnAreaData
				v223_.spawnAreaIndex = v243_
				v253_[1] = v247_
				v254_[2] = v248_
				v255_[3] = v249_
				v256_[4] = v250_
				v257_[5] = v251_
				v258_[6] = v252_
				local v259_ = v223_.area[v223_.spawnAreaIndex]
				local v260_, v261_, v262_ = localToLocal(v259_.startNode, v223_.spawnNode, v244_ + v235_, v245_ + v236_, v246_ + v237_)
				local v263_, v264_, v265_ = localRotationToLocal(v259_.startNode, v223_.spawnNode, 0, 0, 0)
				local v266_ = v234_.visualSpawnInfos
				local v267_ = {
					v223_.spawnNode,
					v260_,
					v261_,
					v262_,
					v263_,
					v264_,
					v265_
				}
				table.insert(v266_, v267_)
			end
		end
		if #v234_.visualSpawnInfos > 0 then
			local v268_ = v_u_226_.objectInfosToSpawn
			table.insert(v268_, v234_)
		end
	end
	if v_u_226_.spawnNextObjectInfo() then
		local v269_ = v222_.pendingVisualAreaUpdates
		table.insert(v269_, v_u_226_)
		self:raiseActive()
	end
end

-- Local values: spec, object, num, canStoreObject, _
function PlaceableObjectStorage:getHasPendingManualStoreObjects()
	local v271_ = self.spec_objectStorage
	for v272_, v273_ in pairs(v271_.pendingObjects) do
		if v273_ > 0 then
			local v274_, _ = self:getObjectStorageCanStoreObject(v272_, true)
			if not v274_ then
				local v275_, _ = self:getObjectStorageCanStoreObject(v272_, false)
				if v275_ then
					return true
				end
			end
		end
	end
	return false
end

-- Local values: spec, object, num, canStoreObject, _
function PlaceableObjectStorage:storePendingManualObjects()
	local v277_ = self.spec_objectStorage
	for v278_, v279_ in pairs(v277_.pendingObjects) do
		if v279_ > 0 then
			local v280_, _ = self:getObjectStorageCanStoreObject(v278_, true)
			if not v280_ then
				local v281_, _ = self:getObjectStorageCanStoreObject(v278_, false)
				if v281_ then
					self:addObjectToObjectStorage(v278_, false)
					self:setObjectStorageObjectInfosDirty()
					v277_.pendingObjects[v278_] = nil
					v278_:removeDeleteListener(self, PlaceableObjectStorage.onPendingObjectDelete)
				end
			end
		end
	end
	self:updateManualStoreActivatable()
end

-- Local values: spec, pendingManualObjectsState
function PlaceableObjectStorage:updateManualStoreActivatable()
	local v283_ = self.spec_objectStorage
	local v284_ = self:getHasPendingManualStoreObjects()
	if v284_ ~= v283_.lastPendingManualObjectsState then
		v283_.lastPendingManualObjectsState = v284_
		if v284_ then
			g_currentMission.activatableObjectsSystem:addActivatable(v283_.manualStoreActivatable)
		else
			g_currentMission.activatableObjectsSystem:removeActivatable(v283_.manualStoreActivatable)
		end
		self:raiseDirtyFlags(v283_.dirtyFlag)
	end
end

-- Local values: spec
function PlaceableObjectStorage:onObjectStoragePlayerTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if g_localPlayer ~= nil and otherId == g_localPlayer.rootNode then
		local v289_ = self.spec_objectStorage
		if onEnter then
			g_currentMission.activatableObjectsSystem:addActivatable(v289_.activatable)
			return
		end
		if onLeave then
			g_currentMission.activatableObjectsSystem:removeActivatable(v289_.activatable)
		end
	end
end

-- Local values: spec
function PlaceableObjectStorage:onPendingObjectDelete(object)
	local v292_ = self.spec_objectStorage
	if v292_.pendingObjects[object] ~= nil then
		v292_.pendingObjects[object] = nil
	end
end

-- Local values: object, canStoreObject, errorId, spec, object, spec
function PlaceableObjectStorage:onObjectStorageObjectTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if onEnter then
		local v297_ = g_currentMission:getNodeObject(otherId)
		if v297_ ~= nil then
			if self:getObjectStorageSupportsObject(v297_) then
				local v298_, v299_ = self:getObjectStorageCanStoreObject(v297_, true)
				if v298_ then
					self:addObjectToObjectStorage(v297_, false)
					self:setObjectStorageObjectInfosDirty()
				else
					if v299_ ~= nil and g_server ~= nil then
						g_server:broadcastEvent(PlaceableObjectStorageErrorEvent.new(self, v299_), true, nil, self)
					end
					local v300_ = self.spec_objectStorage
					v300_.pendingObjects[v297_] = (v300_.pendingObjects[v297_] or 0) + 1
					v297_:addDeleteListener(self, PlaceableObjectStorage.onPendingObjectDelete)
					self:updateManualStoreActivatable()
					self:raiseActive()
				end
			end
			if v297_:isa(Vehicle) and SpecializationUtil.hasSpecialization(BaleLoader, v297_.specializations) then
				v297_:addBaleUnloadTrigger(self)
				return
			end
		end
	elseif onLeave then
		local v301_ = g_currentMission:getNodeObject(otherId)
		if v301_ ~= nil then
			local v302_ = self.spec_objectStorage
			v302_.pendingObjects[v301_] = (v302_.pendingObjects[v301_] or 0) - 1
			if v302_.pendingObjects[v301_] <= 0 then
				v302_.pendingObjects[v301_] = nil
				v301_:removeDeleteListener(self, PlaceableObjectStorage.onPendingObjectDelete)
			end
			self:updateManualStoreActivatable()
			if v301_:isa(Vehicle) and SpecializationUtil.hasSpecialization(BaleLoader, v301_.specializations) then
				v301_:removeBaleUnloadTrigger(self)
			end
		end
	end
end

-- Local values: spec, object, i
function PlaceableObjectStorage:onObjectStorageSpawnOverlapCallback(objectId)
	local v305_ = self.spec_objectStorage
	v305_.objectSpawn.overlapIsActive = false
	if objectId ~= 0 and not getHasTrigger(objectId) then
		local v306_ = g_currentMission:getNodeObject(objectId)
		if v306_ ~= nil then
			for v307_ = 1, #v305_.objectSpawn.spawnedObjects do
				if v306_ == v305_.objectSpawn.spawnedObjects[v307_] then
					return
				end
			end
		end
		v305_.objectSpawn.overlapObjectCount = v305_.objectSpawn.overlapObjectCount + 1
	end
end

-- Local values: spec
function PlaceableObjectStorage:canBeSold(superFunc)
	local v310_ = self.spec_objectStorage
	if #v310_.objectInfos > 0 then
		return true, v310_.texts.warningNotEmpty
	else
		return superFunc(self)
	end
end

-- Local values: spec, numObjectInfos, i, objectInfo, title, sumOthers, i
function PlaceableObjectStorage:updateInfo(superFunc, infoTable)
	superFunc(self, infoTable)
	local v314_ = self.spec_objectStorage
	local v315_ = {
		["title"] = v314_.texts.totalCapacity,
		["text"] = string.format("%d / %d", v314_.numStoredObjects, v314_.capacity)
	}
	table.insert(infoTable, v315_)
	local v316_ = #v314_.objectInfos
	local v317_ = PlaceableObjectStorage.MAX_HUD_INFO_ENTRIES
	for v318_ = 1, math.min(v316_, v317_) do
		local v319_ = v314_.objectInfos[v318_]
		if v319_.objects[1] ~= nil then
			local v320_ = v319_.objects[1]:getDialogText()
			if utf8Strlen(v320_) > 32 then
				v320_ = utf8Substr(v320_, 0, 32) .. "..."
			end
			local v321_ = {
				["title"] = v320_
			}
			local v322_ = v319_.numObjects
			v321_.text = tostring(v322_)
			table.insert(infoTable, v321_)
		end
	end
	if PlaceableObjectStorage.MAX_HUD_INFO_ENTRIES < v316_ then
		local v323_ = 0
		for v324_ = PlaceableObjectStorage.MAX_HUD_INFO_ENTRIES + 1, v316_ do
			v323_ = v323_ + v314_.objectInfos[v324_].numObjects
		end
		local v325_ = {
			["title"] = v314_.texts.otherElements,
			["text"] = tostring(v323_)
		}
		table.insert(infoTable, v325_)
	end
end

-- Local values: totalCapacity, limitedObjectAmount
function PlaceableObjectStorage.loadSpecValueCapacity(xmlFile, customEnvironment, baseDir)
	if not xmlFile:hasProperty("placeable.objectStorage") then
		return nil
	end
	local v327_ = xmlFile:getValue("placeable.objectStorage#capacity", 250)
	local v_u_328_ = 0
	xmlFile:iterate("placeable.objectStorage.supportedObject", function(_, p329_)
		-- upvalues: (copy) xmlFile, (ref) v_u_328_
		if xmlFile:getValue(p329_ .. "#filename") ~= nil then
			v_u_328_ = v_u_328_ + xmlFile:getValue(p329_ .. "#amount")
		end
	end)
	if v_u_328_ > 0 then
		local v330_ = v_u_328_
		v327_ = math.min(v327_, v330_)
	end
	return v327_
end

function PlaceableObjectStorage.getSpecValueCapacity(storeItem, realItem)
	if storeItem.specs.objectStorageCapacity == nil then
		return nil
	else
		return string.format("%d %s", storeItem.specs.objectStorageCapacity, g_i18n:getText("unit_pieces"))
	end
end

-- Local values: fillTypes
function PlaceableObjectStorage.loadSpecValueFillTypes(xmlFile, customEnvironment, baseDir)
	local v_u_333_ = {}
	xmlFile:iterate("placeable.objectStorage.supportedObject", function(_, p334_)
		-- upvalues: (copy) xmlFile, (copy) v_u_333_
		local v335_ = xmlFile:getValue(p334_ .. "#fillType")
		if v335_ ~= nil then
			local v336_ = g_fillTypeManager:getFillTypeIndexByName(string.upper(v335_))
			if v336_ ~= nil then
				local v337_ = v_u_333_
				table.insert(v337_, v336_)
			end
		end
	end)
	return v_u_333_
end

-- Local values: fillTypes
function PlaceableObjectStorage.getSpecValueFillTypes(storeItem, realItem)
	local v339_ = storeItem.specs.objectStorageFillTypes
	if v339_ == nil or #v339_ == 0 then
		return nil
	else
		return v339_
	end
end
PlaceableObjectStorage.ABSTRACT_OBJECTS_BY_CLASS_NAME = {}
PlaceableObjectStorage.ABSTRACT_OBJECTS_BY_ID = {}
PlaceableObjectStorage.ABSTRACT_OBJECTS = {}
function PlaceableObjectStorage.addAbstractObjectClass(p340_)
	PlaceableObjectStorage.ABSTRACT_OBJECTS_BY_CLASS_NAME[p340_.REFERENCE_CLASS_NAME] = p340_
	local v341_ = PlaceableObjectStorage.ABSTRACT_OBJECTS
	table.insert(v341_, p340_)
	p340_.ABSTRACT_OBJECT_ID = #PlaceableObjectStorage.ABSTRACT_OBJECTS
	PlaceableObjectStorage.ABSTRACT_OBJECTS_BY_ID[p340_.ABSTRACT_OBJECT_ID] = p340_
end
local v_u_342_ = {}
local v_u_343_ = Class(v_u_342_)
v_u_342_.REFERENCE_CLASS_NAME = "Bale"
function v_u_342_.registerXMLPaths(p344_, p345_)
	Bale.registerSavegameXMLPaths(p344_, p345_)
end
function v_u_342_.new()
	-- upvalues: (copy) v_u_343_
	local v346_ = v_u_343_
	return setmetatable({}, v346_)
end

function v_u_342_:delete()
	if self.baleObject ~= nil then
		self.baleObject:delete()
	end
end


function v_u_342_.isObjectSupported(storage, object)
	if storage.spec_objectStorage.supportsBales then
		return storage:getObjectStorageSupportsFillType(object:getFillType()) and true or false
	else
		return false
	end
end

-- Local values: _, bWidth, bHeight, bLength, bDiameter, _

-- Upvalues: AbstractPalletObject
-- Local values: size
function v_u_342_.canStoreObject(storage, object)
	local _, v352_, v353_, v354_, v355_, _ = g_baleManager:getBaleInfoByXMLFilename(object.xmlFilename)
	if (v354_ or v355_) > storage.spec_objectStorage.maxLength or ((v353_ or v355_) > storage.spec_objectStorage.maxHeight or storage.spec_objectStorage.maxWidth < v352_) then
		return false
	else
		return object.dynamicMountType == MountableObject.MOUNT_TYPE_NONE or (object.mountObject == nil or object.mountObject.spec_baleLoader == nil and object.mountObject.spec_baleWrapper == nil)
	end
end


function v_u_342_.canStoreObjectAutomatically(storage, object)
	return object.dynamicMountType == MountableObject.MOUNT_TYPE_NONE
end

-- Local values: x, y, z, rx, ry, rz, baleAttributes, baleObject
function v_u_342_:addToStorage(storage, object, loadedFromSavegame)
	if object.isFermenting then
		local v361_, v362_, v363_ = getWorldTranslation(storage.rootNode)
		local v364_, v365_, v366_ = getWorldRotation(storage.rootNode)
		if loadedFromSavegame then
			removeFromPhysics(object.nodeId)
			setVisibility(object.nodeId, false)
			setWorldTranslation(object.nodeId, v361_, v362_, v363_)
			setWorldRotation(object.nodeId, v364_, v365_, v366_)
			object:unregister()
			object:setNeedsSaving(false)
			self.baleObject = object
		else
			local v367_ = object:getBaleAttributes()
			object:delete()
			local v368_ = Bale.new(storage.isServer, storage.isClient)
			if v368_:loadFromConfigXML(v367_.xmlFilename, v361_, v362_, v363_, v364_, v365_, v366_, v367_.uniqueId) then
				v368_:applyBaleAttributes(v367_)
				v368_:setNeedsSaving(false)
				removeFromPhysics(v368_.nodeId)
				setVisibility(v368_.nodeId, false)
			end
			self.baleObject = v368_
		end
	else
		self.baleAttributes = object:getBaleAttributes()
		object:delete()
	end
	g_farmManager:updateFarmStats(storage:getOwnerFarmId(), "storedBales", 1)
end

-- Local values: baleObject, quatX, quatY, quatZ, quatW
function v_u_342_:removeFromStorage(storage, x, y, z, rx, ry, rz, spawnedCallback)
	local v378_
	if self.baleObject == nil then
		v378_ = Bale.new(storage.isServer, storage.isClient)
		if v378_:loadFromConfigXML(self.baleAttributes.xmlFilename, x, y, z, rx, ry, rz, self.baleAttributes.uniqueId) then
			v378_:applyBaleAttributes(self.baleAttributes)
			v378_:register()
		end
	else
		addToPhysics(self.baleObject.nodeId)
		setVisibility(self.baleObject.nodeId, true)
		local v379_, v380_, v381_, v382_ = mathEulerToQuaternion(rx, ry, rz)
		self.baleObject:setLocalPositionQuaternion(x, y, z, v379_, v380_, v381_, v382_, true)
		self.baleObject:register()
		self.baleObject:setNeedsSaving(true)
		v378_ = self.baleObject
	end
	if v378_.isRoundbale then
		removeFromPhysics(v378_.nodeId)
		rotateAboutLocalAxis(v378_.nodeId, 1.5707963267948966, 1, 0, 0)
		addToPhysics(v378_.nodeId)
	end
	g_farmManager:updateFarmStats(storage:getOwnerFarmId(), "storedBales", -1)
	spawnedCallback(storage, v378_)
end

-- Upvalues: AbstractBaleObject
-- Local values: self

-- Upvalues: AbstractPalletObject
-- Local values: self
function v_u_342_.readStream(streamId, connection)
	-- upvalues: (copy) v_u_342_
	local v384_ = v_u_342_.new()
	v384_.baleAttributes = {}
	v384_.baleAttributes.xmlFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
	v384_.baleAttributes.fillLevel = streamReadFloat32(streamId)
	v384_.baleAttributes.fillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
	v384_.baleAttributes.wrappingState = streamReadBool(streamId) and 1 or 0
	v384_.baleAttributes.variationIndex = streamReadUIntN(streamId, Bale.NUM_BITS_VARIATION) + 1
	return v384_
end

function v_u_342_:writeStream(streamId, connection)
	if self.baleObject == nil then
		streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.baleAttributes.xmlFilename))
		streamWriteFloat32(streamId, self.baleAttributes.fillLevel)
		streamWriteUIntN(streamId, self.baleAttributes.fillType, FillTypeManager.SEND_NUM_BITS)
		streamWriteBool(streamId, self.baleAttributes.wrappingState ~= 0)
		streamWriteUIntN(streamId, self.baleAttributes.variationIndex - 1, Bale.NUM_BITS_VARIATION)
	else
		streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.baleObject.xmlFilename))
		streamWriteFloat32(streamId, self.baleObject:getFillLevel())
		streamWriteUIntN(streamId, self.baleObject:getFillType(), FillTypeManager.SEND_NUM_BITS)
		streamWriteBool(streamId, self.baleObject.wrappingState ~= 0)
		streamWriteUIntN(streamId, self.baleObject.variationIndex - 1, Bale.NUM_BITS_VARIATION)
	end
end

function v_u_342_:getRealObject()
	return self.baleObject
end

function v_u_342_:getXMLFilename()
	if self.baleObject == nil then
		if self.baleAttributes == nil then
			return nil
		else
			return self.baleAttributes.xmlFilename
		end
	else
		return self.baleObject.xmlFilename
	end
end

function v_u_342_:getIsIdentical(otherAbstractObject)
	if self.REFERENCE_CLASS_NAME ~= otherAbstractObject.REFERENCE_CLASS_NAME then
		return false
	end
	if self.baleObject ~= nil and otherAbstractObject.baleObject ~= nil then
		if self.baleObject:getFillType() ~= otherAbstractObject.baleObject:getFillType() then
			return false
		end
		if self.baleObject:getFillLevel() ~= otherAbstractObject.baleObject:getFillLevel() then
			return false
		end
		if self.baleObject.xmlFilename ~= otherAbstractObject.baleObject.xmlFilename then
			return false
		end
		if self.baleObject.variationIndex ~= otherAbstractObject.baleObject.variationIndex then
			return false
		end
		local v391_ = self.baleObject.wrappingState - otherAbstractObject.baleObject.wrappingState
		return math.abs(v391_) <= 0.1
	end
	if self.baleAttributes == nil or otherAbstractObject.baleAttributes == nil then
		return false
	end
	if self.baleAttributes.fillType ~= otherAbstractObject.baleAttributes.fillType then
		return false
	end
	if self.baleAttributes.fillLevel ~= otherAbstractObject.baleAttributes.fillLevel then
		return false
	end
	if self.baleAttributes.xmlFilename ~= otherAbstractObject.baleAttributes.xmlFilename then
		return false
	end
	if self.baleAttributes.variationIndex ~= otherAbstractObject.baleAttributes.variationIndex then
		return false
	end
	local v392_ = self.baleAttributes.wrappingState - otherAbstractObject.baleAttributes.wrappingState
	return math.abs(v392_) <= 0.1
end

-- Local values: xmlFilename, fillTypeTitle, fillLevel, baleTitle, isRoundbale, _, _, _, _, _
function v_u_342_:getDialogText()
	local v394_, v395_, v396_
	if self.baleObject == nil then
		v394_ = self.baleAttributes.xmlFilename
		v395_ = g_fillTypeManager:getFillTypeTitleByIndex(self.baleAttributes.fillType)
		v396_ = self.baleAttributes.fillLevel
	else
		v394_ = self.baleObject.xmlFilename
		v395_ = g_fillTypeManager:getFillTypeTitleByIndex(self.baleObject:getFillType())
		v396_ = self.baleObject:getFillLevel()
	end
	local v397_, _, _, _, _, _ = g_baleManager:getBaleInfoByXMLFilename(v394_, true)
	local v398_
	if v397_ then
		v398_ = g_i18n:getText("fillType_roundBale")
	else
		v398_ = g_i18n:getText("fillType_squareBale")
	end
	return string.format("%s (%s %s)", v398_, v395_, g_i18n:formatFluid(v396_))
end


function v_u_342_:getLimitedObjectId()
	return SlotSystem.LIMITED_OBJECT_BALE, PlaceableObjectStorageErrorEvent.ERROR_SLOT_LIMIT_REACHED_BALES
end

-- Local values: xmlFilename, isRoundbale, bWidth, bHeight, bLength, bDiameter, bMaxStackHeight, ox, oy, oz, width, height, length, maxStackHeight
function v_u_342_:getSpawnInfo()
	local v400_
	if self.baleObject == nil then
		v400_ = self.baleAttributes.xmlFilename
	else
		v400_ = self.baleObject.xmlFilename
	end
	local v401_, v402_, v403_, v404_, v405_, v406_ = g_baleManager:getBaleInfoByXMLFilename(v400_, true)
	local v407_ = v406_ or 1
	if v401_ then
		return 0, v402_ * 0.5, 0, v405_, v402_, v405_, v407_
	else
		return 0, v403_ * 0.5, 0, v402_, v403_, v404_, v407_
	end
end
local function v_u_418_(p408_, p409_, p410_)
	-- upvalues: (ref) v_u_418_
	if getHasClassId(p408_, ClassIds.SHAPE) and (getHasClassId(p409_, ClassIds.SHAPE) and (getHasShaderParameter(p408_, p410_) and getHasShaderParameter(p409_, p410_))) then
		local v411_, v412_, v413_, v414_ = getShaderParameter(p409_, p410_)
		setShaderParameter(p408_, p410_, v411_, v412_, v413_, v414_, false)
	end
	local v415_ = getNumOfChildren(p408_)
	local v416_ = getNumOfChildren
	for v417_ = 1, math.min(v415_, v416_(p409_)) do
		v_u_418_(getChildAt(p408_, v417_ - 1), getChildAt(p409_, v417_ - 1), p410_)
	end
end

-- Upvalues: recursiveCopyShaderParameter
-- Local values: xmlFilename, fillType, wrappingState, wrappingColor, variationIndex, baleId, sharedLoadRequestId, i, visualSpawnInfo, clonedBale, isRoundbale, _, _, _, _, _
function v_u_342_:spawnVisualObjects(visualSpawnInfos)
	-- upvalues: (ref) v_u_418_
	local v421_, v422_, v423_, v424_, v425_
	if self.baleObject == nil then
		v421_ = self.baleAttributes.xmlFilename
		v422_ = self.baleAttributes.fillType
		v423_ = self.baleAttributes.wrappingState
		v424_ = self.baleAttributes.wrappingColor
		v425_ = self.baleAttributes.variationIndex
	else
		v421_ = self.baleObject.xmlFilename
		v422_ = self.baleObject:getFillType()
		v423_ = self.baleObject.wrappingState
		v424_ = self.baleObject.wrappingColor
		v425_ = self.baleObject.variationIndex
	end
	local v426_, v427_ = Bale.createDummyBale(v421_, v422_, v425_, v423_, v424_)
	for v428_ = 1, #visualSpawnInfos do
		local v429_ = visualSpawnInfos[v428_]
		local v430_ = clone(v426_, false, false, false)
		v_u_418_(v430_, v426_, "wrappingState")
		v_u_418_(v430_, v426_, "colorScale")
		link(v429_[1], v430_)
		setTranslation(v430_, v429_[2], v429_[3], v429_[4])
		setRotation(v430_, v429_[5], v429_[6], v429_[7])
		local v431_, _, _, _, _, _ = g_baleManager:getBaleInfoByXMLFilename(v421_, true)
		if v431_ then
			rotateAboutLocalAxis(v430_, 1.5707963267948966, 1, 0, 0)
		end
	end
	delete(v426_)
	g_i3DManager:releaseSharedI3DFile(v427_)
end

-- Local values: attributes
function v_u_342_:saveToXMLFile(storage, xmlFile, key)
	if self.baleObject == nil then
		Bale.saveBaleAttributesToXMLFile(self.baleAttributes, xmlFile, key)
	else
		local v435_ = self.baleObject:getBaleAttributes()
		Bale.saveBaleAttributesToXMLFile(v435_, xmlFile, key)
	end
end

-- Upvalues: AbstractBaleObject
-- Local values: attributes, bale, self

-- Upvalues: AbstractPalletObject
-- Local values: attributes, storeItem, fillTypeName, self
function v_u_342_.loadFromXMLFile(storage, xmlFile, key)
	-- upvalues: (copy) v_u_342_
	local v439_ = {}
	Bale.loadBaleAttributesFromXMLFile(v439_, xmlFile, key, false)
	if v439_.isFermenting then
		local v440_ = Bale.new(storage.isServer, storage.isClient)
		if v440_:loadFromConfigXML(v439_.xmlFilename, 0, 0, 0, 0, 0, 0, v439_.uniqueId) then
			v440_:applyBaleAttributes(v439_)
			storage:addObjectToObjectStorage(v440_, true)
			return
		end
	else
		local v441_ = v_u_342_.new()
		v441_.baleAttributes = v439_
		storage:addAbstactObjectToObjectStorage(v441_)
		g_farmManager:updateFarmStats(storage:getOwnerFarmId(), "storedBales", 1)
	end
end
PlaceableObjectStorage.addAbstractObjectClass(v_u_342_)
local v442_ = {}
local v_u_443_ = Class(v442_, v_u_342_)
v442_.REFERENCE_CLASS_NAME = "PackedBale"
function v442_.new()
	-- upvalues: (copy) v_u_443_
	local v444_ = v_u_443_
	return setmetatable({}, v444_)
end
PlaceableObjectStorage.addAbstractObjectClass(v442_)
local v_u_445_ = {}
local v_u_446_ = Class(v_u_445_)
v_u_445_.REFERENCE_CLASS_NAME = "Vehicle"
function v_u_445_.registerXMLPaths(p447_, p448_)
	p447_:register(XMLValueType.INT, p448_ .. "#farmId", "Owner farm id")
	p447_:register(XMLValueType.STRING, p448_ .. "#filename", "Path to pallet xml file")
	p447_:register(XMLValueType.STRING, p448_ .. "#fillType", "Fill type")
	p447_:register(XMLValueType.FLOAT, p448_ .. "#fillLevel", "Fill level")
	p447_:register(XMLValueType.BOOL, p448_ .. "#isBigBag", "Is a big bag object")
	p447_:register(XMLValueType.STRING, p448_ .. ".configuration(?)#name", "Configuration name")
	p447_:register(XMLValueType.STRING, p448_ .. ".configuration(?)#id", "Configuration id")
end
function v_u_445_.new()
	-- upvalues: (copy) v_u_446_
	local v449_ = v_u_446_
	return setmetatable({}, v449_)
end

function v_u_445_:delete() end
function v_u_445_.isObjectSupported(p450_, p451_)
	if p450_.spec_objectStorage.supportsPallets then
		if p451_.isPallet then
			if p451_.propertyState == VehiclePropertyState.OWNED then
				if p451_.markedForDeletion or (p451_.isDeleted or p451_.isDeleting) then
					return false
				else
					return p450_:getObjectStorageSupportsFillType(p451_:getFillUnitFillType(p451_.spec_pallet.fillUnitIndex)) and true or false
				end
			else
				return false
			end
		else
			return false
		end
	else
		return false
	end
end
function v_u_445_.canStoreObject(p452_, p453_)
	-- upvalues: (copy) v_u_445_
	local v454_ = v_u_445_.getSize(p453_.configFileName)
	return v454_.length <= p452_.spec_objectStorage.maxLength and (v454_.height <= p452_.spec_objectStorage.maxHeight and v454_.width <= p452_.spec_objectStorage.maxWidth)
end
function v_u_445_.canStoreObjectAutomatically(_, p455_)
	return p455_.dynamicMountType == MountableObject.MOUNT_TYPE_NONE
end

-- Upvalues: AbstractPalletObject
-- Local values: k, v
function v_u_445_:addToStorage(storage, object, loadedFromSavegame)
	-- upvalues: (copy) v_u_445_
	self.palletAttributes = {}
	self.palletAttributes.ownerFarmId = object:getOwnerFarmId()
	self.palletAttributes.configFileName = object.configFileName
	self.palletAttributes.isBigBag = SpecializationUtil.hasSpecialization(BigBag, object.self)
	if object.getFillUnitByIndex ~= nil and object.spec_pallet.fillUnitIndex ~= nil then
		self.palletAttributes.fillType = object:getFillUnitFillType(object.spec_pallet.fillUnitIndex)
		self.palletAttributes.fillLevel = object:getFillUnitFillLevel(object.spec_pallet.fillUnitIndex)
	end
	self.palletAttributes.configurations = {}
	for v459_, v460_ in pairs(object.configurations) do
		self.palletAttributes.configurations[v459_] = v460_
	end
	object:delete()
	v_u_445_.getSize(self.palletAttributes.configFileName)
	g_farmManager:updateFarmStats(storage:getOwnerFarmId(), "storedPallets", 1)
end

-- Upvalues: AbstractPalletObject
-- Local values: data
function v_u_445_:removeFromStorage(storage, x, y, z, rx, ry, rz, spawnedCallback)
	-- upvalues: (copy) v_u_445_
	local v467_ = VehicleLoadingData.new()
	v467_:setFilename(self.palletAttributes.configFileName)
	v467_:setPosition(x, nil, z)
	v467_:setRotation(0, ry, 0)
	v467_:setPropertyState(VehiclePropertyState.OWNED)
	v467_:setOwnerFarmId(self.palletAttributes.ownerFarmId)
	v467_:setConfigurations(self.palletAttributes.configurations)
	v467_:load(v_u_445_.palletVehicleLoaded, self, { storage, spawnedCallback })
	g_farmManager:updateFarmStats(storage:getOwnerFarmId(), "storedPallets", -1)
end

-- Local values: vehicle, oldRemoveOnEmpty, ownerFarmId, fillUnitIndex
function v_u_445_:palletVehicleLoaded(vehicles, vehicleLoadState, asyncCallbackArguments)
	if vehicleLoadState == VehicleLoadingState.OK and #vehicles > 0 then
		local v472_ = vehicles[1]
		if self.palletAttributes.fillType ~= nil then
			local v473_ = v472_.spec_fillUnit.removeVehicleIfEmpty
			v472_.spec_fillUnit.removeVehicleIfEmpty = false
			local v474_ = v472_:getOwnerFarmId()
			local v475_ = v472_.spec_pallet.fillUnitIndex
			v472_:addFillUnitFillLevel(v474_, v475_, -math.huge, v472_:getFillUnitFillType(v472_.spec_pallet.fillUnitIndex), ToolType.UNDEFINED, nil)
			v472_:addFillUnitFillLevel(v474_, v475_, self.palletAttributes.fillLevel, self.palletAttributes.fillType, ToolType.UNDEFINED, nil)
			v472_.spec_fillUnit.removeVehicleIfEmpty = v473_
		end
		asyncCallbackArguments[2](asyncCallbackArguments[1], v472_)
	end
end
function v_u_445_.readStream(p476_, _)
	-- upvalues: (copy) v_u_445_
	local v477_ = v_u_445_.new()
	v477_.palletAttributes = {}
	v477_.palletAttributes.configFileName = NetworkUtil.convertFromNetworkFilename(streamReadString(p476_))
	v477_.palletAttributes.isBigBag = streamReadBool(p476_)
	if streamReadBool(p476_) then
		v477_.palletAttributes.fillLevel = streamReadFloat32(p476_)
		v477_.palletAttributes.fillType = streamReadUIntN(p476_, FillTypeManager.SEND_NUM_BITS)
		return v477_
	else
		v477_.palletAttributes.fillLevel = 0
		v477_.palletAttributes.fillType = nil
		return v477_
	end
end

function v_u_445_:writeStream(streamId, connection)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.palletAttributes.configFileName))
	streamWriteBool(streamId, self.palletAttributes.isBigBag)
	if streamWriteBool(streamId, self.palletAttributes.fillType ~= nil) then
		streamWriteFloat32(streamId, self.palletAttributes.fillLevel)
		streamWriteUIntN(streamId, self.palletAttributes.fillType, FillTypeManager.SEND_NUM_BITS)
	end
end

function v_u_445_:getRealObject()
	return nil
end

function v_u_445_:getXMLFilename()
	if self.palletAttributes == nil then
		return nil
	else
		return self.palletAttributes.configFileName
	end
end

function v_u_445_:getIsIdentical(otherAbstractObject)
	if self.REFERENCE_CLASS_NAME == otherAbstractObject.REFERENCE_CLASS_NAME then
		if self.palletAttributes.fillType == otherAbstractObject.palletAttributes.fillType then
			if self.palletAttributes.fillLevel == otherAbstractObject.palletAttributes.fillLevel then
				if self.palletAttributes.configFileName == otherAbstractObject.palletAttributes.configFileName then
					return self.palletAttributes.isBigBag == otherAbstractObject.palletAttributes.isBigBag
				else
					return false
				end
			else
				return false
			end
		else
			return false
		end
	else
		return false
	end
end

-- Local values: text, fillTypeTitle, fillLevel, storeItem
function v_u_445_:getDialogText()
	local v484_ = self.palletAttributes.isBigBag and "shopItem_bigBag" or "infohud_pallet"
	if self.palletAttributes.fillType == nil or self.palletAttributes.fillType == FillType.UNKNOWN then
		local v485_ = g_storeManager:getItemByXMLFilename(self.palletAttributes.configFileName)
		if v485_ == nil then
			return nil
		else
			return string.format("%s (%s)", g_i18n:getText(v484_), v485_.name)
		end
	else
		local v486_ = g_fillTypeManager:getFillTypeTitleByIndex(self.palletAttributes.fillType)
		local v487_ = self.palletAttributes.fillLevel
		return string.format("%s (%s %s)", g_i18n:getText(v484_), v486_, g_i18n:formatFluid(v487_))
	end
end
function v_u_445_.getLimitedObjectId(self)
	return SlotSystem.LIMITED_OBJECT_PALLET, PlaceableObjectStorageErrorEvent.ERROR_SLOT_LIMIT_REACHED_PALLETS
end

-- Upvalues: AbstractPalletObject
-- Local values: size
function v_u_445_:getSpawnInfo()
	-- upvalues: (copy) v_u_445_
	local v489_ = v_u_445_.getSize(self.palletAttributes.configFileName)
	return v489_.widthOffset, v489_.heightOffset, v489_.lengthOffset, v489_.width, v489_.height, v489_.length, 1
end

-- Upvalues: AbstractPalletObject
-- Local values: data
function v_u_445_:spawnVisualObjects(visualSpawnInfos)
	-- upvalues: (copy) v_u_445_
	local v492_ = VehicleLoadingData.new()
	v492_:setFilename(self.palletAttributes.configFileName)
	v492_:setPropertyState(VehiclePropertyState.OWNED)
	v492_:setOwnerFarmId(self.palletAttributes.ownerFarmId)
	v492_:setConfigurations(self.palletAttributes.configurations)
	v492_:setRotation(0, 0, 0)
	v492_:setIsRegistered(false)
	v492_:setIsSaved(false)
	v492_:load(v_u_445_.visualPalletVehicleLoaded, self, { visualSpawnInfos })
end

-- Upvalues: recursiveCopyShaderParameter
-- Local values: vehicle, visualSpawnInfos, vehicleRootNode, i, component, i, visualSpawnInfo, clonedPallet
function v_u_445_:visualPalletVehicleLoaded(vehicles, vehicleLoadState, asyncCallbackArguments)
	-- upvalues: (ref) v_u_418_
	if vehicleLoadState == VehicleLoadingState.OK and #vehicles > 0 then
		local v497_ = vehicles[1]
		local v498_ = asyncCallbackArguments[1]
		if self.palletAttributes.fillType ~= nil then
			v497_.spec_fillUnit.removeVehicleIfEmpty = false
			v497_:addFillUnitFillLevel(v497_:getOwnerFarmId(), v497_.spec_pallet.fillUnitIndex, -math.huge, v497_:getFillUnitFillType(v497_.spec_pallet.fillUnitIndex), ToolType.UNDEFINED, nil)
			v497_:addFillUnitFillLevel(v497_:getOwnerFarmId(), v497_.spec_pallet.fillUnitIndex, self.palletAttributes.fillLevel, self.palletAttributes.fillType, ToolType.UNDEFINED, nil)
		end
		if v497_.updatePalletStraps ~= nil then
			v497_:updatePalletStraps()
		end
		if v497_.spec_animatedVehicle ~= nil then
			AnimatedVehicle.updateAnimations(v497_, 99999, true)
		end
		v497_:setVisibility(true)
		local v499_ = createTransformGroup("vehicleRootNode")
		for v500_ = 1, #v497_.components do
			local v501_ = v497_.components[v500_]
			link(v499_, v501_.node)
		end
		for v502_ = 1, #v498_ do
			local v503_ = v498_[v502_]
			if entityExists(v503_[1]) then
				local v504_ = clone(v499_, false, false, false)
				link(v503_[1], v504_)
				setTranslation(v504_, v503_[2], v503_[3], v503_[4])
				setRotation(v504_, v503_[5], v503_[6], v503_[7])
				v_u_418_(v504_, v499_, "hideByIndex")
			end
		end
		v497_:delete(true)
		delete(v499_)
	end
end

-- Local values: index, configName, configId, configKey, saveId
function v_u_445_:saveToXMLFile(storage, xmlFile, key)
	xmlFile:setValue(key .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.palletAttributes.configFileName)))
	xmlFile:setValue(key .. "#farmId", self.palletAttributes.ownerFarmId)
	xmlFile:setValue(key .. "#isBigBag", self.palletAttributes.isBigBag)
	if self.palletAttributes.fillType ~= nil then
		xmlFile:setValue(key .. "#fillType", g_fillTypeManager:getFillTypeNameByIndex(self.palletAttributes.fillType))
		xmlFile:setValue(key .. "#fillLevel", self.palletAttributes.fillLevel)
	end
	local v508_ = 0
	for v509_, v510_ in pairs(self.palletAttributes.configurations) do
		local v511_ = string.format("%s.configuration(%d)", key, v508_)
		local v512_ = ConfigurationUtil.getSaveIdByConfigId(self.palletAttributes.configFileName, v509_, v510_)
		if v512_ ~= nil then
			xmlFile:setValue(v511_ .. "#name", v509_)
			xmlFile:setValue(v511_ .. "#id", v512_)
		end
		v508_ = v508_ + 1
	end
end
function v_u_445_.loadFromXMLFile(p513_, p_u_514_, p515_)
	-- upvalues: (copy) v_u_445_
	local v_u_516_ = {
		["configFileName"] = NetworkUtil.convertFromNetworkFilename(p_u_514_:getValue(p515_ .. "#filename")),
		["isBigBag"] = p_u_514_:getValue(p515_ .. "#isBigBag", false)
	}
	if g_storeManager:getItemByXMLFilename(v_u_516_.configFileName) == nil then
		Logging.info("Pallet could not be loaded into the storage. Path does not exist anymore. (%s)", v_u_516_.configFileName)
	else
		v_u_516_.ownerFarmId = p_u_514_:getValue(p515_ .. "#farmId", AccessHandler.EVERYONE)
		local v517_ = p_u_514_:getValue(p515_ .. "#fillType")
		if v517_ ~= nil then
			v_u_516_.fillType = g_fillTypeManager:getFillTypeIndexByName(v517_)
			v_u_516_.fillLevel = p_u_514_:getValue(p515_ .. "#fillLevel", 0)
		end
		v_u_516_.configurations = {}
		p_u_514_:iterate(p515_ .. ".configuration", function(_, p518_)
			-- upvalues: (copy) p_u_514_, (copy) v_u_516_
			local v519_ = p_u_514_:getValue(p518_ .. "#name")
			local v520_ = p_u_514_:getValue(p518_ .. "#id")
			local v521_ = ConfigurationUtil.getConfigIdBySaveId(v_u_516_.configFileName, v519_, v520_)
			if v521_ ~= nil then
				v_u_516_.configurations[v519_] = v521_
			end
		end)
		local v522_ = v_u_445_.new()
		v522_.palletAttributes = v_u_516_
		p513_:addAbstactObjectToObjectStorage(v522_)
		v_u_445_.getSize(v522_.palletAttributes.configFileName)
		g_farmManager:updateFarmStats(p513_:getOwnerFarmId(), "storedPallets", 1)
	end
end
v_u_445_.configFileNameToSize = {}

-- Upvalues: AbstractPalletObject
function v_u_445_.getSize(configFileName)
	-- upvalues: (copy) v_u_445_
	if v_u_445_.configFileNameToSize[configFileName] ~= nil then
		return v_u_445_.configFileNameToSize[configFileName]
	end
	v_u_445_.configFileNameToSize[configFileName] = StoreItemUtil.getSizeValues(configFileName, "vehicle", 0, {})
	return v_u_445_.configFileNameToSize[configFileName]
end
PlaceableObjectStorage.addAbstractObjectClass(v_u_445_)
PlaceableObjectStorageActivatable = {}
local v_u_524_ = Class(PlaceableObjectStorageActivatable)
function PlaceableObjectStorageActivatable.new(p525_)
	-- upvalues: (copy) v_u_524_
	local v526_ = v_u_524_
	local v527_ = setmetatable({}, v526_)
	v527_.objectStorage = p525_
	v527_.activateText = g_i18n:getText("action_objectStorageMenu")
	v527_.warningText = g_i18n:getText("warning_objectStorageIsEmpty")
	return v527_
end

function PlaceableObjectStorageActivatable:getIsActivatable()
	if g_currentMission.accessHandler:canPlayerAccess(self.objectStorage) then
		return not self.objectStorage.spec_objectStorage.objectSpawn.isActive
	else
		return false
	end
end

-- Local values: objectInfos
function PlaceableObjectStorageActivatable:run()
	self.objectStorage:updateDirtyObjectStorageObjectInfos()
	local v530_ = self.objectStorage:getObjectStorageObjectInfos()
	if v530_ == nil or #v530_ <= 0 then
		g_currentMission:showBlinkingWarning(string.format(self.warningText, self.objectStorage:getName()), 2000)
	else
		ObjectStorageDialog.show(self.onObjectInfoSelected, self, self.objectStorage:getName(), v530_, self.objectStorage.spec_objectStorage.maxUnloadAmount)
	end
end

-- Local values: tx, ty, tz
function PlaceableObjectStorageActivatable:getDistance(x, y, z)
	if self.objectStorage.spec_objectStorage.playerTriggerNode == nil then
		return math.huge
	end
	local v535_, v536_, v537_ = getWorldTranslation(self.objectStorage.spec_objectStorage.playerTriggerNode)
	return MathUtil.vector3Length(x - v535_, y - v536_, z - v537_)
end

function PlaceableObjectStorageActivatable:onObjectInfoSelected(objectInfoIndex, amount)
	if objectInfoIndex ~= nil and amount ~= nil then
		g_client:getServerConnection():sendEvent(PlaceableObjectStorageUnloadEvent.new(self.objectStorage, objectInfoIndex, amount))
	end
end
PlaceableObjectStorageManualStoreActivatable = {}
local v_u_541_ = Class(PlaceableObjectStorageManualStoreActivatable)
function PlaceableObjectStorageManualStoreActivatable.new(p542_)
	-- upvalues: (copy) v_u_541_
	local v543_ = v_u_541_
	local v544_ = setmetatable({}, v543_)
	v544_.objectStorage = p542_
	v544_.activateText = g_i18n:getText("button_unload")
	return v544_
end

function PlaceableObjectStorageManualStoreActivatable:getIsActivatable()
	return g_currentMission.accessHandler:canPlayerAccess(self.objectStorage) and true or false
end

function PlaceableObjectStorageManualStoreActivatable:run()
	g_client:getServerConnection():sendEvent(PlaceableObjectStorageStoreEvent.new(self.objectStorage))
end

-- Local values: tx, ty, tz
function PlaceableObjectStorageManualStoreActivatable:getDistance(x, y, z)
	if self.objectStorage.spec_objectStorage.objectTriggerNode == nil then
		return math.huge
	end
	local v551_, v552_, v553_ = getWorldTranslation(self.objectStorage.spec_objectStorage.objectTriggerNode)
	return MathUtil.vector3Length(x - v551_, y - v552_, z - v553_)
end
