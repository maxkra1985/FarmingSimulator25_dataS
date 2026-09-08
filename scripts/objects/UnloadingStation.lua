-- Local values: UnloadingStation_mt
UnloadingStation = {}
UnloadingStation.FX_DURATION = 5000
local UnloadingStation_mt = Class(UnloadingStation, Object)
InitStaticObjectClass(UnloadingStation, "UnloadingStation")

-- Upvalues: UnloadingStation_mt
-- Local values: self
function UnloadingStation.new(isServer, isClient, customMt)
	-- upvalues: (copy) UnloadingStation_mt
	return Object.new(isServer, isClient, customMt or UnloadingStation_mt)
end

-- Local values: stationName, k, trigger, _, fillplaneKey, node, fillTypes, fillplane, _, fillTypeIndex, _, baseDirectory
function UnloadingStation:load(components, xmlFile, key, customEnv, i3dMappings, rootNode)
	self.rootNode = rootNode or xmlFile:getValue(key .. "#node", rootNode, components, i3dMappings)
	if self.rootNode == nil then
		Logging.xmlError(xmlFile, "Missing node defined in \'%s\'", key)
		return false
	end
	self.rootNodeName = getName(self.rootNode)
	self.xmlKey = key
	local v11_ = xmlFile:getValue(key .. "#stationName", nil)
	if v11_ then
		v11_ = g_i18n:convertText(v11_)
	end
	self.stationName = v11_
	self.storageRadius = xmlFile:getValue(key .. "#storageRadius", 50)
	self.hideFromPricesMenu = xmlFile:getValue(key .. "#hideFromPricesMenu", false)
	self.supportsExtension = xmlFile:getValue(key .. "#supportsExtension", false)
	self.isTrainStation = xmlFile:getValue(key .. "#isTrainStation", false)
	self.isPalletStation = xmlFile:getValue(key .. "#isPalletStation", false)
	self.owningPlaceable = nil
	self.hasStoragePerFarm = false
	self.targetStorages = {}
	self.supportedFillTypes = {}
	self.aiSupportedFillTypes = {}
	self.unloadTriggers = UnloadTrigger.createTriggers(self.isServer, self.isClient, xmlFile, key, components, self, nil, i3dMappings)
	for v12_, v13_ in ipairs(self.unloadTriggers) do
		if v13_.fillTypes == nil or next(v13_.fillTypes) == nil then
			Logging.xmlWarning(xmlFile, "Unloading station trigger \'%d\' has no filltypes defined", v12_)
		end
		v13_:register(true)
	end
	for _, v14_ in xmlFile:iterator(key .. ".simpleFillplane") do
		local v15_ = xmlFile:getValue(v14_ .. "#node", nil, components, i3dMappings)
		if v15_ ~= nil then
			local v16_ = g_fillTypeManager:loadCombinedFillTypesFromConfig(xmlFile, v14_)
			if v16_ == nil then
				Logging.xmlWarning(xmlFile, "No filltypes defined for %q", v14_)
			else
				if self.simpleFillplanes == nil then
					self.simpleFillplanes = {}
					self.fillTypeIndexToFillplane = {}
					g_messageCenter:subscribe(MessageType.DAY_CHANGED, UnloadingStation.dayChanged, self)
				end
				local v17_ = {
					["node"] = v15_,
					["hideTime"] = 0
				}
				local v18_ = self.simpleFillplanes
				table.insert(v18_, v17_)
				for _, v19_ in ipairs(v16_) do
					if self.fillTypeIndexToFillplane[v19_] == nil then
						self.fillTypeIndexToFillplane[v19_] = {}
					end
					local v20_ = self.fillTypeIndexToFillplane[v19_]
					table.insert(v20_, v17_)
				end
				setVisibility(v15_, false)
			end
		end
	end
	if self.isClient then
		local _, v21_ = Utils.getModNameAndBaseDirectory(xmlFile:getFilename())
		self.samples = {
			["idle"] = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "idle", v21_, components, 1, AudioGroup.ENVIRONMENT, i3dMappings, nil),
			["active"] = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "active", v21_, components, 1, AudioGroup.ENVIRONMENT, i3dMappings, nil)
		}
		self.animations = g_animationManager:loadAnimations(xmlFile, key .. ".animationNodes", components, self, i3dMappings)
		self.effects = g_effectManager:loadEffect(xmlFile, key .. ".effectNodes", components, self, i3dMappings)
		self.hasFx = (self.samples.active ~= nil or #self.animations > 0) and true or #self.effects > 0
		self.fxTimer = nil
		self.fxActive = false
		g_soundManager:playSample(self.samples.idle)
	end
	self:updateSupportedFillTypes()
	self:validateUnloadTriggers(xmlFile, key)
	return true
end

-- Local values: _, unloadTrigger, storage, _
function UnloadingStation:delete()
	if self.unloadTriggers ~= nil then
		for _, v23_ in pairs(self.unloadTriggers) do
			v23_:delete()
		end
		table.clear(self.unloadTriggers)
	end
	if self.samples ~= nil then
		g_soundManager:stopSamples(self.samples)
		g_soundManager:deleteSamples(self.samples)
		table.clear(self.samples)
	end
	if self.animations ~= nil then
		g_animationManager:deleteAnimations(self.animations)
		table.clear(self.animations)
	end
	if self.effects ~= nil then
		g_effectManager:deleteEffects(self.effects)
		table.clear(self.effects)
	end
	if self.fxTimer ~= nil then
		self.fxTimer:delete()
		self.fxTimer = nil
	end
	if self.targetStorages ~= nil then
		for v24_, _ in pairs(self.targetStorages) do
			v24_:removeUnloadingStation(self)
		end
		table.clear(self.targetStorages)
	end
	g_messageCenter:unsubscribeAll(self)
	self.owningPlaceable = nil
	UnloadingStation:superClass().delete(self)
end

-- Local values: _, unloadTrigger, unloadTriggerId
function UnloadingStation:readStream(streamId, connection)
	UnloadingStation:superClass().readStream(self, streamId, connection)
	if connection:getIsServer() then
		for _, v28_ in ipairs(self.unloadTriggers) do
			local v29_ = NetworkUtil.readNodeObjectId(streamId)
			v28_:readStream(streamId, connection)
			g_client:finishRegisterObject(v28_, v29_)
		end
	end
end

-- Local values: _, unloadTrigger
function UnloadingStation:writeStream(streamId, connection)
	UnloadingStation:superClass().writeStream(self, streamId, connection)
	if not connection:getIsServer() then
		for _, v33_ in ipairs(self.unloadTriggers) do
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v33_))
			v33_:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, v33_)
		end
	end
end

function UnloadingStation:loadFromXMLFile(xmlFile, key)
	return true
end

function UnloadingStation:saveToXMLFile(xmlFile, key, usedModNames) end

function UnloadingStation:getName()
	return self.stationName or self.owningPlaceable and self.owningPlaceable:getName() or "Unloading Station"
end

-- Local values: _, unloadTrigger, supportsAI, fillType, _
function UnloadingStation:updateSupportedFillTypes()
	self.supportedFillTypes = {}
	self.aiSupportedFillTypes = {}
	for _, v36_ in pairs(self.unloadTriggers) do
		if v36_.fillTypes ~= nil then
			local v37_ = v36_:getSupportAIUnloading()
			for v38_, _ in pairs(v36_.fillTypes) do
				self.supportedFillTypes[v38_] = true
				if v37_ then
					self.aiSupportedFillTypes[v38_] = true
				end
			end
		end
	end
end

-- Local values: storageFillTypes, hasMatchingFillType, fillType, _
function UnloadingStation:addTargetStorage(storage)
	if storage == nil then
		return false
	end
	local v41_ = storage.getFreeCapacity
	assert(v41_)
	local v42_ = storage.getIsFillTypeSupported ~= nil
	assert(v42_)
	local v43_ = storage.setFillLevel ~= nil
	assert(v43_)
	local v44_ = storage.getFillLevel ~= nil
	assert(v44_)
	local v45_ = storage.fillTypes
	if storage.supportedFillTypes ~= nil then
		v45_ = storage.supportedFillTypes
	end
	local v46_ = false
	for v47_, _ in pairs(v45_) do
		if self.supportedFillTypes[v47_] ~= nil then
			v46_ = true
			break
		end
	end
	if not v46_ then
		return false
	end
	self.targetStorages[storage] = storage
	storage:addUnloadingStation(self)
	return true
end

function UnloadingStation:removeTargetStorage(storage)
	if storage ~= nil then
		storage:removeUnloadingStation(self)
		self.targetStorages[storage] = nil
	end
end

function UnloadingStation:getIsFillTypeSupported(fillTypeIndex)
	return self.supportedFillTypes[fillTypeIndex] ~= nil
end

function UnloadingStation:getSupportedFillTypes()
	return self.supportedFillTypes
end

function UnloadingStation:getIsFillTypeAISupported(fillTypeIndex)
	return self.aiSupportedFillTypes[fillTypeIndex] ~= nil
end

function UnloadingStation:getAISupportedFillTypes()
	return self.aiSupportedFillTypes
end

function UnloadingStation:getIsFillTypeAllowed(fillTypeIndex, extraAttributes)
	return true
end

-- Local values: freeCapacity, _, targetStorage
function UnloadingStation:getFreeCapacity(fillTypeIndex, farmId)
	local v59_ = 0
	for _, v60_ in pairs(self.targetStorages) do
		if farmId == nil or self:hasFarmAccessToStorage(farmId, v60_) then
			v59_ = v59_ + v60_:getFreeCapacity(fillTypeIndex)
		end
	end
	return v59_
end

-- Local values: capacity, _, targetStorage, storageCapacity
function UnloadingStation:getCapacity(fillTypeIndex, farmId)
	local v64_ = 0
	for _, v65_ in pairs(self.targetStorages) do
		if self:hasFarmAccessToStorage(farmId, v65_) and v65_:getIsFillTypeSupported(fillTypeIndex) then
			local v66_ = v65_:getCapacity(fillTypeIndex)
			if v66_ ~= nil then
				v64_ = v64_ + v66_
			end
		end
	end
	return v64_
end

-- Local values: fillLevel, _, targetStorage
function UnloadingStation:getFillLevel(fillTypeIndex, farmId)
	local v70_ = 0
	for _, v71_ in pairs(self.targetStorages) do
		if self:hasFarmAccessToStorage(farmId, v71_) then
			v70_ = v70_ + v71_:getFillLevel(fillTypeIndex)
		end
	end
	return v70_
end

function UnloadingStation:getIsToolTypeAllowed(toolType)
	return true
end

-- Local values: movedFillLevel, _, targetStorage, oldFillLevel, newFillLevel
function UnloadingStation:addFillLevelFromTool(farmId, deltaFillLevel, fillType, fillInfo, toolType, extraAttributes)
	local v78_ = deltaFillLevel >= 0
	assert(v78_)
	local v79_ = 0
	if self:getIsFillTypeAllowed(fillType) and self:getIsToolTypeAllowed(toolType) then
		for _, v80_ in pairs(self.targetStorages) do
			if self:hasFarmAccessToStorage(farmId, v80_) then
				if v80_:getFreeCapacity(fillType) > 0 then
					local v81_ = v80_:getFillLevel(fillType)
					v80_:setFillLevel(v81_ + deltaFillLevel, fillType, fillInfo)
					v79_ = v79_ + (v80_:getFillLevel(fillType) - v81_)
				end
				if deltaFillLevel - 0.001 <= v79_ then
					self:startFx(fillType)
					v79_ = deltaFillLevel
					break
				end
			end
		end
	end
	self:activateSimpleFillplanes(fillType)
	return v79_
end

-- Local values: fillplanes, _, fillplane
function UnloadingStation:activateSimpleFillplanes(fillTypeIndex)
	if self.fillTypeIndexToFillplane ~= nil then
		local v84_ = self.fillTypeIndexToFillplane[fillTypeIndex]
		if v84_ ~= nil then
			for _, v85_ in ipairs(v84_) do
				setVisibility(v85_.node, true)
			end
		end
	end
end

function UnloadingStation:startFx(fillType)
	if self.isClient and self.hasFx then
		if self.fxTimer == nil then
			self.fxTimer = Timer.new(UnloadingStation.FX_DURATION):setFinishCallback(function()
				-- upvalues: (copy) self
				if self.isClient then
					g_soundManager:stopSample(self.samples.active)
					g_animationManager:stopAnimations(self.animations)
					g_effectManager:stopEffects(self.effects)
					self.fxActive = false
				end
			end)
		end
		self.fxTimer:start()
		if not self.fxActive then
			g_soundManager:playSample(self.samples.active)
			g_animationManager:startAnimations(self.animations)
			g_effectManager:setEffectTypeInfo(self.effects, fillType)
			g_effectManager:startEffects(self.effects)
			self.fxActive = true
		end
	end
end

-- Local values: _, targetStorage
function UnloadingStation:getIsFillAllowedFromFarm(farmId)
	for _, v90_ in pairs(self.targetStorages) do
		if self:hasFarmAccessToStorage(farmId, v90_) then
			return true
		end
	end
	return false
end

-- Local values: mission
function UnloadingStation:hasFarmAccessToStorage(farmId, storage)
	if self.hasStoragePerFarm then
		return farmId == storage:getOwnerFarmId()
	else
		return g_currentMission.accessHandler:canFarmAccess(farmId, storage, true)
	end
end

-- Local values: unloadTrigger, _, trigger, x, z, xDir, zDir
function UnloadingStation:getAITargetPositionAndDirection(fillType)
	local v96_ = nil
	for _, v97_ in ipairs(self.unloadTriggers) do
		if v97_:getSupportAIUnloading() and (fillType == FillType.UNKNOWN or v97_:getIsFillTypeAllowed(fillType)) then
			v96_ = v97_
			break
		end
	end
	if v96_ == nil then
		return nil
	end
	local v98_, v99_, v100_, v101_ = v96_:getAITargetPositionAndDirection()
	return v98_, v99_, v100_, v101_, v96_
end

-- Local values: _, unloadTrigger
function UnloadingStation:setOwnerFarmId(farmId, noEventSend)
	UnloadingStation:superClass().setOwnerFarmId(self, farmId, noEventSend)
	for _, v105_ in ipairs(self.unloadTriggers) do
		v105_:setOwnerFarmId(farmId, true)
	end
end

-- Local values: _, fillplane
function UnloadingStation:dayChanged()
	for _, v107_ in ipairs(self.simpleFillplanes) do
		setVisibility(v107_.node, false)
	end
end

-- Local values: fillTypeIndex, _, fillTypeDesc, isValid, _, unloadTrigger, isValid, _, unloadTrigger, isValid, _, unloadTrigger
function UnloadingStation:validateUnloadTriggers(xmlFile, key)
	for v111_, _ in pairs(self.supportedFillTypes) do
		local v112_ = g_fillTypeManager:getFillTypeByIndex(v111_)
		if v112_.isPalletType then
			local v113_ = false
			for _, v114_ in pairs(self.unloadTriggers) do
				if v114_.fillTypes[v111_] ~= nil then
					if ClassUtil.getClassObjectByObject(v114_) == PalletUnloadTrigger then
						v113_ = true
					elseif v114_.exactFillRootNode == nil and ClassUtil.getClassObjectByObject(v114_) == UnloadTrigger then
						v113_ = true
					end
				end
			end
			if not v113_ then
				Logging.xmlDevWarning(xmlFile, "UnloadingStation does not have a PalletUnloadTrigger for fillType \'%s\'", g_fillTypeManager:getFillTypeNameByIndex(v111_))
			end
		end
		if not (self.isTrainStation or self.isPalletStation) then
			if v112_.isBaleType then
				local v115_ = false
				for _, v116_ in pairs(self.unloadTriggers) do
					if v116_.fillTypes[v111_] ~= nil then
						if ClassUtil.getClassObjectByObject(v116_) == BaleUnloadTrigger then
							v115_ = true
						elseif v116_.exactFillRootNode == nil and ClassUtil.getClassObjectByObject(v116_) == UnloadTrigger then
							v115_ = true
						end
					end
				end
				if not (v115_ or string.contains(key, "husbandry")) then
					Logging.xmlWarning(xmlFile, "UnloadingStation does not have a BaleUnloadTrigger for fillType \'%s\'", g_fillTypeManager:getFillTypeNameByIndex(v111_))
				end
			end
			if v112_.isBulkType then
				local v117_ = false
				for _, v118_ in pairs(self.unloadTriggers) do
					if ClassUtil.getClassObjectByObject(v118_) == UnloadTrigger and v118_.fillTypes[v111_] ~= nil then
						v117_ = true
					end
				end
				if not v117_ then
					Logging.xmlWarning(xmlFile, "UnloadingStation does not have a regular UnloadTrigger for fillType \'%s\'", g_fillTypeManager:getFillTypeNameByIndex(v111_))
				end
			end
		end
	end
end

function UnloadingStation.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Unloading station node")
	schema:register(XMLValueType.STRING, basePath .. "#stationName", "Station name", "LoadingStation")
	schema:register(XMLValueType.FLOAT, basePath .. "#storageRadius", "Inside of this radius storages can be placed", 50)
	schema:register(XMLValueType.BOOL, basePath .. "#hideFromPricesMenu", "Hide station from prices menu", false)
	schema:register(XMLValueType.BOOL, basePath .. "#supportsExtension", "Supports extensions", false)
	schema:register(XMLValueType.BOOL, basePath .. "#isTrainStation", "Is part of the train system", false)
	schema:register(XMLValueType.BOOL, basePath .. "#isPalletStation", "At this selling station good can be unloaded only as pallets", false)
	UnloadTrigger.registerTriggerXMLPaths(schema, basePath)
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "active")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "idle")
	AnimationManager.registerAnimationNodesXMLPaths(schema, basePath .. ".animationNodes")
	EffectManager.registerEffectXMLPaths(schema, basePath .. ".effectNodes")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".simpleFillplane(?)#node", "A fillplane that should be visible after unloading")
	FillTypeManager.registerConfigXMLFilltypes(schema, basePath .. ".simpleFillplane(?)")
end
