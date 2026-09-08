-- Local values: LoadingStation_mt
LoadingStation = {}
local LoadingStation_mt = Class(LoadingStation, Object)
InitStaticObjectClass(LoadingStation, "LoadingStation")

-- Upvalues: LoadingStation_mt
-- Local values: self
function LoadingStation.new(isServer, isClient, customMt)
	-- upvalues: (copy) LoadingStation_mt
	local v5_ = Object.new(isServer, isClient, customMt or LoadingStation_mt)
	v5_.sourceStorages = {}
	v5_.loadTriggers = {}
	return v5_
end

-- Local values: stationName, fillTypeCategories, fillTypes, _, fillType, fillTypeNames, fillTypes, _, fillType
function LoadingStation:load(components, xmlFile, key, customEnv, i3dMappings, rootNode)
	self.rootNode = rootNode or xmlFile:getValue(key .. "#node", rootNode, components, i3dMappings)
	if self.rootNode == nil then
		Logging.xmlError(xmlFile, "Missing node defined in \'%s\'", key)
		return false
	end
	self.supportedFillTypes = {}
	self.aiSupportedFillTypes = {}
	self.rootNodeName = getName(self.rootNode)
	local v12_ = xmlFile:getValue(key .. "#stationName", nil)
	if v12_ then
		v12_ = g_i18n:convertText(v12_)
	end
	self.stationName = v12_
	self.storageRadius = xmlFile:getValue(key .. "#storageRadius", 50)
	self.supportsExtension = xmlFile:getValue(key .. "#supportsExtension", false)
	self.owningPlaceable = nil
	self.hasStoragePerFarm = false
	xmlFile:iterate(key .. ".loadTrigger", function(_, p13_)
		-- upvalues: (copy) xmlFile, (copy) self, (copy) components, (copy) i3dMappings
		local v14_ = xmlFile:getValue(p13_ .. "#class", "LoadTrigger")
		local v15_ = ClassUtil.getClassObject(v14_)
		if v15_ == nil then
			Logging.xmlError(xmlFile, "LoadTrigger class \'%s\' not defined for \'%s\'", v14_, p13_)
			return
		else
			local v16_ = v15_.new(self.isServer, self.isClient)
			if v16_:load(components, xmlFile, p13_, i3dMappings, self.rootNode) then
				v16_:setSource(self)
				v16_:register(true)
				local v17_ = self.loadTriggers
				table.insert(v17_, v16_)
			else
				v16_:delete()
			end
		end
	end)
	self.basicFillTypes = {}
	local v18_ = XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, key, "fillTypeCategories", self.rootNode)
	if v18_ ~= nil then
		local v19_ = g_fillTypeManager:getFillTypesByCategoryNames(v18_, "Warning: LoadingStation has invalid fillTypeCategory \'%s\'.")
		for _, v20_ in pairs(v19_) do
			self.basicFillTypes[v20_] = true
		end
	end
	local v21_ = XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, key, "fillTypes", self.rootNode)
	if v21_ ~= nil then
		local v22_ = g_fillTypeManager:getFillTypesByNames(v21_, "Warning: LoadingStation has invalid fillType \'%s\'.")
		for _, v23_ in pairs(v22_) do
			self.basicFillTypes[v23_] = true
		end
	end
	self:updateSupportedFillTypes()
	return true
end

-- Local values: _, loadTrigger, _, storage
function LoadingStation:delete()
	if self.loadTriggers ~= nil then
		for _, v25_ in ipairs(self.loadTriggers) do
			v25_:delete()
		end
	end
	if self.sourceStorages ~= nil then
		for _, v26_ in pairs(self.sourceStorages) do
			v26_:removeLoadingStation(self)
		end
		table.clear(self.sourceStorages)
	end
	LoadingStation:superClass().delete(self)
end

-- Local values: _, loadTrigger, loadTriggerId
function LoadingStation:readStream(streamId, connection)
	LoadingStation:superClass().readStream(self, streamId, connection)
	if connection:getIsServer() then
		for _, v30_ in ipairs(self.loadTriggers) do
			local v31_ = NetworkUtil.readNodeObjectId(streamId)
			v30_:readStream(streamId, connection)
			g_client:finishRegisterObject(v30_, v31_)
		end
	end
end

-- Local values: _, loadTrigger
function LoadingStation:writeStream(streamId, connection)
	LoadingStation:superClass().writeStream(self, streamId, connection)
	if not connection:getIsServer() then
		for _, v35_ in ipairs(self.loadTriggers) do
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v35_))
			v35_:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, v35_)
		end
	end
end

function LoadingStation:loadFromXMLFile(xmlFile, key)
	return true
end

function LoadingStation:saveToXMLFile(xmlFile, key, usedModNames) end

function LoadingStation:getName()
	return self.stationName or self.owningPlaceable and self.owningPlaceable:getName() or "Loading Station"
end

function LoadingStation:raiseActive()
	LoadingStation:superClass().raiseActive(self)
	if self.owningPlaceable ~= nil then
		self.owningPlaceable:raiseActive()
	end
end

-- Local values: hasMatchingFillType, fillType, _
function LoadingStation:addSourceStorage(storage)
	if storage == nil then
		return false
	end
	local v40_ = storage.getIsFillTypeSupported ~= nil
	assert(v40_, "LoadingStation:addSourceStorage: invalid storage given, missing function getIsFillTypeSupported")
	local v41_ = storage.setFillLevel ~= nil
	assert(v41_)
	local v42_ = storage.getFillLevel ~= nil
	assert(v42_)
	local v43_ = storage.getFillLevels ~= nil
	assert(v43_)
	local v44_ = storage.getSupportedFillTypes ~= nil
	assert(v44_)
	local v45_ = false
	for v46_, _ in pairs(storage.fillTypes) do
		if self.supportedFillTypes[v46_] ~= nil then
			v45_ = true
		end
	end
	if not v45_ then
		return false
	end
	self.sourceStorages[storage] = storage
	storage:addLoadingStation(self)
	return true
end

function LoadingStation:removeSourceStorage(storage)
	if storage ~= nil then
		storage:removeLoadingStation(self)
		self.sourceStorages[storage] = nil
	end
end

-- Local values: _, loadTrigger, supportsAI, fillType, _, fillTypeIndex, _
function LoadingStation:updateSupportedFillTypes()
	self.supportedFillTypes = {}
	self.aiSupportedFillTypes = {}
	for _, v50_ in pairs(self.loadTriggers) do
		local v51_ = v50_:getSupportAILoading()
		for v52_, _ in pairs(v50_.fillTypes) do
			self.supportedFillTypes[v52_] = true
			if v51_ then
				self.aiSupportedFillTypes[v52_] = true
			end
		end
	end
	for v53_, _ in pairs(self.basicFillTypes) do
		self.supportedFillTypes[v53_] = true
	end
end

function LoadingStation:getSupportedFillTypes()
	return self.supportedFillTypes
end

function LoadingStation:getIsFillTypeSupported(fillTypeIndex)
	return self.supportedFillTypes[fillTypeIndex] ~= nil
end

function LoadingStation:getIsFillTypeAISupported(fillTypeIndex)
	return self.aiSupportedFillTypes[fillTypeIndex] ~= nil
end

function LoadingStation:getAISupportedFillTypes()
	return self.aiSupportedFillTypes
end

-- Local values: fillLevel, _, sourceStorage
function LoadingStation:getFillLevel(fillType, farmId)
	local v63_ = 0
	for _, v64_ in pairs(self.sourceStorages) do
		if self:hasFarmAccessToStorage(farmId, v64_) then
			v63_ = v63_ + v64_:getFillLevel(fillType)
		end
	end
	return v63_
end

-- Local values: fillLevels, _, sourceStorage, fillType, fillLevel
function LoadingStation:getAllFillLevels(farmId)
	local v67_ = {}
	for _, v68_ in pairs(self.sourceStorages) do
		if self:hasFarmAccessToStorage(farmId, v68_) then
			for v69_, v70_ in pairs(v68_:getFillLevels()) do
				v67_[v69_] = Utils.getNoNil(v67_[v69_], 0) + v70_
			end
		end
	end
	return v67_
end

-- Local values: farmId, availableFillLevel, _, sourceStorage, freeCapacity, object, objectFillUnitIndex, usedFillLevel, appliedFillLevel, remainingFillLevel
function LoadingStation:addFillLevelToFillableObject(fillableObject, fillUnitIndex, fillTypeIndex, fillDelta, fillInfo, toolType)
	if fillableObject == nil or (fillTypeIndex == FillType.UNKNOWN or (fillDelta == 0 or toolType == nil)) then
		return 0
	end
	local v78_ = fillableObject:getOwnerFarmId()
	if fillableObject:isa(Vehicle) then
		v78_ = fillableObject:getActiveFarm()
	end
	local v79_ = 0
	for _, v80_ in pairs(self.sourceStorages) do
		if self:hasFarmAccessToStorage(v78_, v80_) then
			v79_ = v79_ + Utils.getNoNil(v80_:getFillLevel(fillTypeIndex), 0)
		end
	end
	local v81_ = math.min(fillDelta, v79_)
	if v81_ == 0 then
		return 0
	end
	local v82_ = fillableObject:getFillUnitFreeCapacity(fillUnitIndex)
	if fillableObject.getConveyorBeltTargetObject ~= nil then
		local v83_, v84_ = fillableObject:getConveyorBeltTargetObject()
		if v83_ ~= nil then
			v82_ = v83_:getFillUnitFreeCapacity(v84_)
		end
	end
	if fillableObject.getConveyorBeltFillLevel ~= nil then
		local v85_ = v82_ - fillableObject:getConveyorBeltFillLevel()
		v82_ = math.max(v85_, 0)
	end
	local v86_ = fillableObject:addFillUnitFillLevel(v78_, fillUnitIndex, math.min(v82_, v81_), fillTypeIndex, toolType, fillInfo)
	return v86_ - self:removeFillLevel(fillTypeIndex, v86_, v78_)
end

-- Local values: remainingDelta, _, sourceStorage, oldFillLevel, newFillLevel
function LoadingStation:removeFillLevel(fillTypeIndex, fillDelta, farmId)
	local v91_ = fillDelta
	for _, v92_ in pairs(self.sourceStorages) do
		if self:hasFarmAccessToStorage(farmId, v92_) then
			local v93_ = v92_:getFillLevel(fillTypeIndex)
			if v93_ > 0 then
				v92_:setFillLevel(v93_ - fillDelta, fillTypeIndex)
			end
			v91_ = v91_ - (v93_ - v92_:getFillLevel(fillTypeIndex))
			if v91_ < 0.0001 then
				return 0
			end
		end
	end
	return v91_
end

function LoadingStation:getSourceStorages()
	return self.sourceStorages
end

-- Local values: _, sourceStorage
function LoadingStation:getIsFillAllowedToFarm(farmId)
	for _, v97_ in pairs(self.sourceStorages) do
		if self:hasFarmAccessToStorage(farmId, v97_) then
			return true
		end
	end
	return false
end

function LoadingStation:hasFarmAccessToStorage(farmId, storage)
	if self.hasStoragePerFarm then
		return farmId == storage:getOwnerFarmId()
	else
		return g_currentMission.accessHandler:canFarmAccess(farmId, storage)
	end
end

-- Local values: loadTrigger, _, trigger, x, z, xDir, zDir
function LoadingStation:getAITargetPositionAndDirection(fillType)
	local v103_ = nil
	for _, v104_ in ipairs(self.loadTriggers) do
		if v104_:getSupportAILoading() and (fillType == FillType.UNKNOWN or v104_:getIsFillTypeSupported(fillType)) then
			v103_ = v104_
			break
		end
	end
	if v103_ == nil then
		return nil
	end
	local v105_, v106_, v107_, v108_ = v103_:getAITargetPositionAndDirection()
	return v105_, v106_, v107_, v108_, v103_
end

-- Local values: _, loadTrigger
function LoadingStation:setOwnerFarmId(farmId, noEventSend)
	LoadingStation:superClass().setOwnerFarmId(self, farmId, noEventSend)
	for _, v112_ in ipairs(self.loadTriggers) do
		v112_:setOwnerFarmId(farmId, true)
	end
end

function LoadingStation.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Loading station node")
	schema:register(XMLValueType.STRING, basePath .. "#stationName", "Station name", "LoadingStation")
	schema:register(XMLValueType.FLOAT, basePath .. "#storageRadius", "Inside of this radius storages can be placed", 50)
	schema:register(XMLValueType.BOOL, basePath .. "#supportsExtension", "Supports extensions", false)
	schema:register(XMLValueType.STRING, basePath .. "#fillTypes", "Basic supported filltypes")
	schema:register(XMLValueType.STRING, basePath .. "#fillTypeCategories", "Basic supported filltype categories")
	LoadTrigger.registerXMLPaths(schema, basePath .. ".loadTrigger(?)")
	schema:register(XMLValueType.STRING, basePath .. ".loadTrigger(?)#class", "Name of load trigger class")
end
