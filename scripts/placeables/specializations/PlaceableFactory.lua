PlaceableFactory = {}
source("dataS/scripts/placeables/specializations/activatables/FactoryActivatable.lua")

function PlaceableFactory.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(PlaceableSellingStation, specializations)
end

function PlaceableFactory.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "onMeshI3DFileLoaded", PlaceableFactory.onMeshI3DFileLoaded)
	SpecializationUtil.registerFunction(placeableType, "updateRemainingAmount", PlaceableFactory.updateRemainingAmount)
	SpecializationUtil.registerFunction(placeableType, "setMeshProgress", PlaceableFactory.setMeshProgress)
	SpecializationUtil.registerFunction(placeableType, "createFactoryItem", PlaceableFactory.createFactoryItem)
	SpecializationUtil.registerFunction(placeableType, "sellFactoryItem", PlaceableFactory.sellFactoryItem)
	SpecializationUtil.registerFunction(placeableType, "getCapacity", PlaceableFactory.getCapacity)
	SpecializationUtil.registerFunction(placeableType, "getFillLevel", PlaceableFactory.getFillLevel)
	SpecializationUtil.registerFunction(placeableType, "removeFillLevel", PlaceableFactory.removeFillLevel)
	SpecializationUtil.registerFunction(placeableType, "playerTriggerCallback", PlaceableFactory.playerTriggerCallback)
	SpecializationUtil.registerFunction(placeableType, "buyRequest", PlaceableFactory.buyRequest)
	SpecializationUtil.registerFunction(placeableType, "updateInfoData", PlaceableFactory.updateInfoData)
end

function PlaceableFactory.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableFactory.updateInfo)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableFactory.setOwnerFarmId)
end

function PlaceableFactory.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableFactory)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableFactory)
	SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableFactory)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableFactory)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableFactory)
	SpecializationUtil.registerEventListener(placeableType, "onReadUpdateStream", PlaceableFactory)
	SpecializationUtil.registerEventListener(placeableType, "onWriteUpdateStream", PlaceableFactory)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableFactory)
	SpecializationUtil.registerEventListener(placeableType, "onInfoTriggerEnter", PlaceableFactory)
	SpecializationUtil.registerEventListener(placeableType, "onInfoTriggerLeave", PlaceableFactory)
end

function PlaceableFactory.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("PlaceableFactory")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".factory#playerTrigger", "")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".factory.item#linkNode", "")
	schema:register(XMLValueType.STRING, basePath .. ".factory.item#filename", "")
	schema:register(XMLValueType.INT, basePath .. ".factory.item#reward", "")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".factory.item.progressiveVisibilityMesh.mesh(?)#node", "")
	schema:register(XMLValueType.STRING, basePath .. ".factory.item.progressiveVisibilityMesh.mesh(?)#id", "")
	schema:register(XMLValueType.INT, basePath .. ".factory.item.progressiveVisibilityMesh.mesh(?)#indexMin", "")
	schema:register(XMLValueType.INT, basePath .. ".factory.item.progressiveVisibilityMesh.mesh(?)#indexMax", "")
	schema:register(XMLValueType.STRING, basePath .. ".factory.production.input(?)#fillType", "")
	schema:register(XMLValueType.FLOAT, basePath .. ".factory.production.input(?)#amount", "")
	schema:register(XMLValueType.FLOAT, basePath .. ".factory.production.input(?)#usagePerHour", "")
	schema:register(XMLValueType.STRING, basePath .. ".factory.production.output#fillType", "")
	schema:register(XMLValueType.STRING, basePath .. ".factory.production#meshId", "")
	SellingStation.registerXMLPaths(schema, basePath .. ".factory.sellingStation")
	Storage.registerXMLPaths(schema, basePath .. ".factory.storage")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".factory.sounds", "active")
	schema:setXMLSpecializationType()
end

function PlaceableFactory.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".input(?)#fillType", "")
	schema:register(XMLValueType.FLOAT, basePath .. ".input(?)#remainingAmount", "")
	Storage.registerSavegameXMLPaths(schema, basePath .. ".storage")
end

-- Local values: spec, key, itemI3DFilename, arguments, sellingStation, outputTypeStr, outputType, production, _, inputKey, fillTypeStr, fillType, amount, usagePerHour, usagePerSecond
function PlaceableFactory:onLoad(savegame)
	local v10_ = self.spec_factory
	v10_.itemLinkNode = self.xmlFile:getValue("placeable.factory.item#linkNode", nil, self.components, self.i3dMappings)
	local v11_ = Utils.getFilename(self.xmlFile:getValue("placeable.factory.item#filename"), self.baseDirectory)
	v10_.itemReward = self.xmlFile:getValue("placeable.factory.item#reward", 100000)
	v10_.idToMesh = {}
	v10_.meshes = {}
	local v12_ = {
		["loadingTask"] = self:createLoadingTask(v10_)
	}
	v10_.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(v11_, true, false, self.onMeshI3DFileLoaded, self, v12_)
	local v13_ = self.spec_sellingStation.sellingStation
	v13_.owningPlaceable = self
	function v13_.getStoreGoods(_, _, _)
		return true
	end
	function v13_.getSkipSell(_, _, _)
		-- upvalues: (copy) self
		return self:getOwnerFarmId() ~= AccessHandler.EVERYONE
	end
	v10_.storage = Storage.new(self.isServer, self.isClient)
	v10_.storage:load(self.components, self.xmlFile, "placeable.factory.storage", self.i3dMappings, self.baseDirectory)
	v10_.storage:register(true)
	v10_.storage:addFillLevelChangedListeners(function()
		-- upvalues: (copy) self
		self:raiseActive()
	end)
	function v10_.storageFillLevelChangedCallback()
		-- upvalues: (copy) self
		self:updateInfoData()
	end
	v10_.fillTypesAndLevelsAuxiliary = {}
	v10_.fillTypeToFillTypeStorageTable = {}
	v10_.infoTriggerFillTypesAndLevels = {}
	v10_.infoTableEntryStorage = {
		["title"] = g_i18n:getText("statistic_storage"),
		["accentuate"] = true
	}
	v13_:addTargetStorage(v10_.storage)
	v10_.playerTrigger = self.xmlFile:getValue("placeable.factory#playerTrigger", nil, self.components, self.i3dMappings)
	if v10_.playerTrigger ~= nil then
		addTrigger(v10_.playerTrigger, "playerTriggerCallback", self)
		setVisibility(v10_.playerTrigger, self:getOwnerFarmId() == AccessHandler.EVERYONE)
	end
	v10_.activatable = FactoryActivatable.new(self)
	v10_.totalAmount = 0
	v10_.inputs = {}
	v10_.hasInputMaterials = true
	v10_.progress = 0
	v10_.progressLastSynced = 0
	v10_.progressNumBits = 7
	v10_.progressDirtyFlag = self:getNextDirtyFlag()
	self.inputFillTypeIdsArray = {}
	self.outputFillTypeIdsArray = {}
	local v14_ = self.xmlFile:getValue("placeable.factory.production.output#fillType")
	local v15_ = g_fillTypeManager:getFillTypeByName(v14_)
	self.productions = {}
	local v16_ = {
		["inputs"] = {},
		["outputs"] = {},
		["cyclesPerMonth"] = 1,
		["costsPerActiveMonth"] = 0
	}
	if v15_ ~= nil then
		v16_.primaryProductFillType = v15_.index
		v16_.name = v15_.title
		local v17_ = self.outputFillTypeIdsArray
		local v18_ = v15_.index
		table.insert(v17_, v18_)
		local v19_ = v16_.outputs
		local v20_ = {
			["type"] = v15_.index,
			["amount"] = 1,
			["isFactory"] = true
		}
		table.insert(v19_, v20_)
	end
	for _, v21_ in self.xmlFile:iterator("placeable.factory.production.input") do
		local v22_ = self.xmlFile:getValue(v21_ .. "#fillType")
		local v23_ = g_fillTypeManager:getFillTypeByName(v22_)
		if v23_ == nil then
			Logging.xmlWarning(self.xmlFile, "Unknown fillType \'%s\' in \'%s\'", v22_, v21_)
			break
		end
		if not v10_.storage:getIsFillTypeSupported(v23_.index) then
			Logging.xmlWarning(self.xmlFile, "Filltype \'%s\' in \'%s\' not supported by storage", v23_.name, v21_)
			break
		end
		local v24_ = self.xmlFile:getValue(v21_ .. "#amount")
		local v25_ = self.xmlFile:getValue(v21_ .. "#usagePerHour")
		local v26_ = v25_ / 60 / 60
		v10_.totalAmount = v10_.totalAmount + v24_
		local v27_ = v10_.inputs
		local v28_ = {
			["fillType"] = v23_,
			["amount"] = v24_,
			["remainingAmount"] = v24_,
			["usagePerSecond"] = v26_,
			["infoTableEntry"] = {
				["title"] = v23_.title,
				["text"] = g_i18n:formatVolume(v24_)
			}
		}
		table.insert(v27_, v28_)
		local v29_ = v16_.inputs
		local v30_ = {
			["type"] = v23_.index,
			["amount"] = v24_
		}
		table.insert(v29_, v30_)
		local v31_ = v16_.cyclesPerMonth
		local v32_ = v24_ * g_currentMission.environment.timeAdjustment / (v25_ * 24)
		v16_.cyclesPerMonth = math.max(v31_, v32_)
		local v33_ = self.inputFillTypeIdsArray
		local v34_ = v23_.index
		table.insert(v33_, v34_)
	end
	local v35_ = self.productions
	table.insert(v35_, v16_)
	v10_.samples = {}
	v10_.samples.active = g_soundManager:loadSampleFromXML(self.xmlFile, "placeable.factory.sounds", "active", self.baseDirectory, self.components, 0, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
	v10_.isSoundPlaying = false
end

-- Local values: spec, components, boatKey, index, nodeKey, node, id, indexMin, indexMax, mesh, _, mesh
function PlaceableFactory:onMeshI3DFileLoaded(i3dFileRoot, failedReason, args)
	local v39_ = self.spec_factory
	if i3dFileRoot ~= 0 then
		v39_.itemRoot = i3dFileRoot
		local v40_ = {}
		I3DUtil.loadI3DComponents(i3dFileRoot, v40_)
		for _, v41_ in self.xmlFile:iterator("placeable.factory.item.progressiveVisibilityMesh.mesh") do
			local v42_ = self.xmlFile:getValue(v41_ .. "#node", nil, v40_)
			if not getHasClassId(v42_, ClassIds.SHAPE) then
				Logging.xmlError(self.xmlFile, "node \'%s\' at \'%s\' is not a shape", getName(v42_), v41_)
				break
			end
			if not getHasShaderParameter(v42_, "hideByIndex") then
				Logging.xmlError(self.xmlFile, "mesh \'%s\' at \'%s\' does not have required shader parameter \'hideByIndex\'", getName(v42_), v41_)
				break
			end
			local v43_ = self.xmlFile:getValue(v41_ .. "#id")
			local v44_ = self.xmlFile:getValue(v41_ .. "#indexMin", 0)
			local v45_ = self.xmlFile:getValue(v41_ .. "#indexMax")
			if v45_ == nil then
				v45_ = getUserAttribute(v42_, "hideByIndexMaxIndex")
				if v44_ == nil then
					Logging.xmlError(self.xmlFile, "Cannot retrieve indexMax from shape material and value is also not set in xml at \'%s\'", getName(v42_), v41_)
					break
				end
			end
			if v39_.idToMesh[v43_] ~= nil then
				Logging.xmlError(self.xmlFile, "id \'%s\' at \'%s\' already in use", v43_, v41_)
				break
			end
			local v46_ = {
				["node"] = v42_,
				["childIndex"] = getChildIndex(v42_),
				["id"] = v43_,
				["index"] = #v39_.meshes + 1,
				["indexMin"] = v44_,
				["indexMax"] = v45_,
				["lastValue"] = -1,
				["dirtyFlag"] = self:getNextDirtyFlag(),
				["numBits"] = MathUtil.getNumRequiredBits(v45_)
			}
			v39_.idToMesh[v43_] = v46_
			local v47_ = v39_.meshes
			table.insert(v47_, v46_)
		end
	end
	self:createFactoryItem()
	for _, v48_ in ipairs(v39_.meshes) do
		self:setMeshProgress(v48_.id, 1)
	end
	self:finishLoadingTask(args.loadingTask)
	self:raiseActive()
end

-- Local values: spec
function PlaceableFactory:onDelete()
	local v50_ = self.spec_factory
	g_currentMission.productionChainManager:removeFactory(self)
	g_currentMission.activatableObjectsSystem:removeActivatable(v50_.activatable)
	if v50_.samples ~= nil then
		g_soundManager:deleteSamples(v50_.samples)
		v50_.samples = nil
	end
	if v50_.playerTrigger ~= nil then
		removeTrigger(v50_.playerTrigger)
		v50_.playerTrigger = nil
	end
	if v50_.itemRoot ~= nil then
		delete(v50_.itemRoot)
		v50_.itemRoot = nil
	end
	if v50_.storage ~= nil then
		v50_.storage:delete()
		v50_.storage = nil
	end
	if v50_.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(v50_.sharedLoadRequestId)
		v50_.sharedLoadRequestId = nil
	end
end

-- Local values: spec
function PlaceableFactory:saveToXMLFile(xmlFile, key, usedModNames)
	local v54_ = self.spec_factory
	xmlFile:setSortedTable(key .. ".input", v54_.inputs, function(p55_, p56_)
		-- upvalues: (copy) xmlFile
		xmlFile:setValue(p55_ .. "#fillType", p56_.fillType.name)
		xmlFile:setValue(p55_ .. "#remainingAmount", p56_.remainingAmount)
	end)
	v54_.storage:saveToXMLFile(xmlFile, key .. ".storage")
end

-- Local values: spec, _, inputKey, fillType, remainingAmount, _, input
function PlaceableFactory:loadFromXMLFile(xmlFile, key)
	local v60_ = self.spec_factory
	for _, v61_ in xmlFile:iterator(key .. ".input") do
		local v62_ = g_fillTypeManager:getFillTypeByName(xmlFile:getValue(v61_ .. "#fillType"))
		local v63_ = xmlFile:getValue(v61_ .. "#remainingAmount")
		for _, v64_ in ipairs(v60_.inputs) do
			if v64_.fillType == v62_ then
				self:updateRemainingAmount(v64_, v63_)
			end
		end
	end
	v60_.storage:loadFromXMLFile(xmlFile, key .. ".storage")
end

-- Local values: spec, storageId, meshIndex, mesh, hideByIndexValue, progress
function PlaceableFactory:onReadStream(streamId, connection)
	local v68_ = self.spec_factory
	local v69_ = NetworkUtil.readNodeObjectId(streamId)
	v68_.storage:readStream(streamId, connection)
	g_client:finishRegisterObject(v68_.storage, v69_)
	v68_.hasInputMaterials = streamReadBool(streamId)
	v68_.progress = NetworkUtil.readCompressedPercentages(streamId, v68_.progressNumBits)
	for _, v70_ in ipairs(v68_.meshes) do
		local v71_ = streamReadUIntN(streamId, v70_.numBits)
		local v72_ = MathUtil.inverseLerp(v70_.indexMax, v70_.indexMin, v71_)
		self:setMeshProgress(v70_.id, v72_)
	end
end

-- Local values: spec, meshIndex, mesh
function PlaceableFactory:onWriteStream(streamId, connection)
	local v76_ = self.spec_factory
	NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v76_.storage))
	v76_.storage:writeStream(streamId, connection)
	g_server:registerObjectInStream(connection, v76_.storage)
	streamWriteBool(streamId, v76_.hasInputMaterials)
	NetworkUtil.writeCompressedPercentages(streamId, v76_.progress, v76_.progressNumBits)
	for _, v77_ in ipairs(v76_.meshes) do
		streamWriteUIntN(streamId, v77_.lastValue, v77_.numBits)
	end
end

-- Local values: spec, meshIndex, mesh, hideByIndexValue, progress
function PlaceableFactory:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local v81_ = self.spec_factory
		v81_.hasInputMaterials = streamReadBool(streamId)
		if streamReadBool(streamId) then
			v81_.progress = NetworkUtil.readCompressedPercentages(streamId, v81_.progressNumBits)
		end
		for _, v82_ in ipairs(v81_.meshes) do
			if streamReadBool(streamId) then
				local v83_ = streamReadUIntN(streamId, v82_.numBits)
				local v84_ = MathUtil.inverseLerp(v82_.indexMax, v82_.indexMin, v83_)
				self:setMeshProgress(v82_.id, v84_)
			end
		end
	end
end

-- Local values: spec, meshIndex, mesh
function PlaceableFactory:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v89_ = self.spec_factory
		streamWriteBool(streamId, v89_.hasInputMaterials)
		local v90_ = streamWriteBool
		local v91_ = v89_.progressDirtyFlag
		if v90_(streamId, bit32.band(dirtyMask, v91_) ~= 0) then
			NetworkUtil.writeCompressedPercentages(streamId, v89_.progress, v89_.progressNumBits)
			v89_.progressLastSynced = v89_.progress
		end
		for _, v92_ in ipairs(v89_.meshes) do
			local v93_ = streamWriteBool
			local v94_ = v92_.dirtyFlag
			if v93_(streamId, bit32.band(dirtyMask, v94_) ~= 0) then
				streamWriteUIntN(streamId, v92_.lastValue, v92_.numBits)
			end
		end
	end
end

-- Local values: spec, usedAmount, hasInputMaterials, i, input, amount, delta, progress, _, mesh, _, mesh, i, input
function PlaceableFactory:onUpdate(dt)
	local v97_ = self.spec_factory
	if not self.isServer then
		::l2::
		if self.isClient and v97_.samples.active ~= nil then
			if v97_.hasInputMaterials then
				if not v97_.isSoundPlaying then
					g_soundManager:playSample(v97_.samples.active)
					v97_.isSoundPlaying = true
					return
				end
			elseif v97_.isSoundPlaying then
				g_soundManager:stopSample(v97_.samples.active)
				v97_.isSoundPlaying = false
			end
		end
		return
	end
	local v98_ = 0
	local v99_ = false
	for _, v100_ in ipairs(v97_.inputs) do
		v98_ = v98_ + (v100_.amount - v100_.remainingAmount)
		if v100_.remainingAmount > 0 then
			local v101_ = v100_.usagePerSecond / 1000 * (dt * g_currentMission.missionInfo.timeScale)
			local v102_ = self:removeFillLevel(v100_.fillType.index, v101_)
			if v102_ > 0 then
				self:updateRemainingAmount(v100_, v100_.remainingAmount - v102_)
				v99_ = true
			end
		end
	end
	local v103_ = v98_ / v97_.totalAmount
	if v103_ >= 0.001 then
		local v104_ = v97_.progressLastSynced - v103_
		if math.abs(v104_) < 0.01 then
			::l10::
			v97_.progress = v103_
			for _, v105_ in ipairs(v97_.meshes) do
				self:setMeshProgress(v105_.id, v97_.progress)
			end
			if v99_ or v99_ ~= v97_.hasInputMaterials then
				self:raiseActive()
			end
			v97_.hasInputMaterials = v99_
			if v97_.progress >= 1 then
				self:sellFactoryItem()
				for _, v106_ in ipairs(v97_.meshes) do
					self:setMeshProgress(v106_.id, 0)
				end
				for _, v107_ in ipairs(v97_.inputs) do
					self:updateRemainingAmount(v107_, v107_.amount)
				end
			end
			goto l2
		end
	end
	self:raiseDirtyFlags(v97_.progressDirtyFlag)
	goto l10
end

function PlaceableFactory:updateRemainingAmount(input, amount)
	input.remainingAmount = math.max(0, amount)
	input.infoTableEntry.text = g_i18n:formatVolume(input.remainingAmount)
end

-- Local values: oldFarmId, spec, sellingStation
function PlaceableFactory:setOwnerFarmId(superFunc, farmId)
	local v113_ = self:getOwnerFarmId()
	superFunc(self, farmId)
	local v114_ = self.spec_factory
	if v114_.playerTrigger ~= nil then
		setVisibility(v114_.playerTrigger, farmId == AccessHandler.EVERYONE)
	end
	if self.propertyState ~= PlaceablePropertyState.CONSTRUCTION_PREVIEW then
		g_currentMission.productionChainManager:removeFactory(self, v113_)
		local v115_ = self.spec_sellingStation.sellingStation
		if v115_ ~= nil then
			if farmId == AccessHandler.EVERYONE then
				g_currentMission.storageSystem:addUnloadingStation(v115_, self)
				g_currentMission.economyManager:addSellingStation(v115_)
			else
				g_currentMission.economyManager:removeSellingStation(v115_)
				g_currentMission.storageSystem:removeUnloadingStation(v115_, self)
			end
		end
		g_currentMission.productionChainManager:addFactory(self)
	end
end

-- Local values: spec, sellingStation
function PlaceableFactory:onFinalizePlacement()
	local v117_ = self.spec_factory
	if v117_.item ~= nil then
		addToPhysics(v117_.item)
	end
	if self.ownerFarmId ~= AccessHandler.EVERYONE then
		local v118_ = self.spec_sellingStation.sellingStation
		g_currentMission.economyManager:removeSellingStation(v118_)
		g_currentMission.storageSystem:removeUnloadingStation(v118_, self)
	end
end

-- Local values: spec, mesh, hideByIndexValue, node
function PlaceableFactory:setMeshProgress(meshId, percentage)
	local v122_ = self.spec_factory
	if v122_.item ~= nil then
		local v123_ = v122_.idToMesh[meshId]
		if v123_ ~= nil then
			local v124_ = MathUtil.round(MathUtil.lerp(v123_.indexMax, v123_.indexMin, percentage))
			if v124_ ~= v123_.lastValue then
				local v125_ = getChildAt(v122_.item, v123_.childIndex)
				setVisibility(v125_, percentage ~= 0)
				v123_.lastValue = v124_
				setShaderParameter(v125_, "hideByIndex", v124_, 0, 0, 0, false)
				if self.isServer then
					self:raiseDirtyFlags(v123_.dirtyFlag)
				end
			end
		end
	end
end

-- Local values: spec
function PlaceableFactory:createFactoryItem()
	local v127_ = self.spec_factory
	if v127_.itemLinkNode ~= nil and v127_.item == nil then
		v127_.item = clone(v127_.itemRoot, false, false, false)
		link(v127_.itemLinkNode, v127_.item)
	end
end

-- Local values: spec
function PlaceableFactory:sellFactoryItem()
	local v129_ = self.spec_factory
	if v129_.item ~= nil then
		if self.isServer and self:getOwnerFarmId() ~= AccessHandler.EVERYONE then
			g_currentMission:addMoney(v129_.itemReward * EconomyManager.getPriceMultiplier(), self:getOwnerFarmId(), MoneyType.SOLD_PRODUCTS, true, true)
		end
		self:raiseActive()
	end
end

-- Local values: spec
function PlaceableFactory:getCapacity(fillType)
	return self.spec_factory.storage:getCapacity(fillType)
end

-- Local values: spec
function PlaceableFactory:getFillLevel(fillType)
	return self.spec_factory.storage:getFillLevel(fillType)
end

-- Local values: spec, previousFillLevel
function PlaceableFactory:removeFillLevel(fillType, amount)
	local v137_ = self.spec_factory
	local v138_ = v137_.storage:getFillLevel(fillType)
	v137_.storage:setFillLevel(v138_ - amount, fillType)
	return v138_ - v137_.storage:getFillLevel(fillType)
end

-- Local values: spec, fillType, fillLevel, fillType, fillLevel
function PlaceableFactory:updateInfoData()
	local v140_ = self.spec_factory
	v140_.fillTypesAndLevelsAuxiliary = {}
	for v141_, v142_ in pairs(v140_.storage:getFillLevels()) do
		v140_.fillTypesAndLevelsAuxiliary[v141_] = (v140_.fillTypesAndLevelsAuxiliary[v141_] or 0) + v142_
	end
	table.clear(v140_.infoTriggerFillTypesAndLevels)
	for v143_, v144_ in pairs(v140_.fillTypesAndLevelsAuxiliary) do
		if v144_ > 0.1 then
			local v145_ = v140_.fillTypeToFillTypeStorageTable
			local v146_ = v140_.fillTypeToFillTypeStorageTable[v143_]
			if not v146_ then
				v146_ = {
					["fillType"] = v143_,
					["fillLevel"] = v144_
				}
			end
			v145_[v143_] = v146_
			v140_.fillTypeToFillTypeStorageTable[v143_].fillLevel = v144_
			local v147_ = v140_.infoTriggerFillTypesAndLevels
			local v148_ = v140_.fillTypeToFillTypeStorageTable[v143_]
			table.insert(v147_, v148_)
		end
	end
	table.clear(v140_.fillTypesAndLevelsAuxiliary)
	table.sort(v140_.infoTriggerFillTypesAndLevels, function(p149_, p150_)
		return p149_.fillLevel > p150_.fillLevel
	end)
end

-- Local values: spec, numEntries, i, fillTypeAndLevel, _, input
function PlaceableFactory:updateInfo(superFunc, infoTable)
	superFunc(self, infoTable)
	local v154_ = self.spec_factory
	if v154_.hasInputMaterials then
		local v155_ = #v154_.infoTriggerFillTypesAndLevels
		local v156_ = math.min(v155_, 7)
		if v156_ > 0 then
			local v157_ = v154_.infoTableEntryStorage
			table.insert(infoTable, v157_)
			for v158_ = 1, v156_ do
				local v159_ = v154_.infoTriggerFillTypesAndLevels[v158_]
				local v160_ = {
					["title"] = g_fillTypeManager:getFillTypeTitleByIndex(v159_.fillType),
					["text"] = g_i18n:formatVolume(v159_.fillLevel, 0)
				}
				table.insert(infoTable, v160_)
			end
		end
	else
		local v161_ = {
			["title"] = g_i18n:getText("ui_production_status_materialsMissing"),
			["accentuate"] = true
		}
		table.insert(infoTable, v161_)
		for _, v162_ in ipairs(v154_.inputs) do
			local v163_ = {
				["title"] = "   " .. g_fillTypeManager:getFillTypeTitleByIndex(v162_.fillType.index)
			}
			table.insert(infoTable, v163_)
		end
	end
	local v164_ = {
		["title"] = g_i18n:getText("contract_progress"),
		["text"] = string.format("%.1f%%", v154_.progress * 100),
		["accentuate"] = true
	}
	table.insert(infoTable, v164_)
end

-- Local values: spec
function PlaceableFactory:onInfoTriggerEnter(nodeId)
	local v166_ = self.spec_factory
	if not v166_.hasStorageListener then
		self:updateInfoData()
		v166_.storage:addFillLevelChangedListeners(v166_.storageFillLevelChangedCallback)
		v166_.hasStorageListener = true
	end
end

-- Local values: spec
function PlaceableFactory:onInfoTriggerLeave(nodeId)
	local v168_ = self.spec_factory
	if v168_.hasStorageListener then
		v168_.storage:removeFillLevelChangedListeners(v168_.storageFillLevelChangedCallback)
		v168_.hasStorageListener = false
	end
end

-- Local values: spec
function PlaceableFactory:playerTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if (onEnter or onLeave) and (g_localPlayer ~= nil and g_localPlayer.rootNode == otherId) then
		local v173_ = self.spec_factory
		if onEnter then
			if Platform.isMobile and v173_.activatable:getIsActivatable() then
				v173_.activatable:run()
				return
			end
			g_currentMission.activatableObjectsSystem:addActivatable(v173_.activatable)
		end
		if onLeave then
			g_currentMission.activatableObjectsSystem:removeActivatable(v173_.activatable)
		end
	end
end

-- Local values: price, buyingEventCallback, dialogCallback, callback, text
function PlaceableFactory:buyRequest(requestCallback, target)
	local v177_ = self:getPrice()
	local function v_u_180_(p178_)
		-- upvalues: (copy) self
		if p178_ ~= nil then
			local v179_ = BuyExistingPlaceableEvent.DIALOG_MESSAGES[p178_]
			if v179_ ~= nil then
				InfoDialog.show(g_i18n:getText(v179_.text), nil, nil, v179_.dialogType)
			end
		end
		g_messageCenter:unsubscribe(BuyExistingPlaceableEvent, self)
	end
	local v181_ = string.format(g_i18n:getText("dialog_buyBuildingFor"), self:getName(), g_i18n:formatMoney(v177_, 0, true))
	YesNoDialog.show(function(p182_, _)
		-- upvalues: (copy) v_u_180_, (copy) self, (copy) requestCallback, (copy) target
		if p182_ then
			g_messageCenter:subscribe(BuyExistingPlaceableEvent, v_u_180_)
			g_client:getServerConnection():sendEvent(BuyExistingPlaceableEvent.new(self, g_currentMission:getFarmId()))
		end
		if requestCallback ~= nil then
			if target ~= nil then
				requestCallback(target, p182_)
				return
			end
			requestCallback(p182_)
		end
	end, nil, v181_)
end
