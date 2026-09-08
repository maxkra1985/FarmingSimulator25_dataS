-- Local values: Storage_mt
Storage = {}
local Storage_mt = Class(Storage, Object)
InitStaticObjectClass(Storage, "Storage")

function Storage.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Storage node")
	schema:register(XMLValueType.FLOAT, basePath .. "#capacity", "Total capacity", 100000)
	schema:register(XMLValueType.FLOAT, basePath .. "#fillLevelSyncThreshold", "Fill level difference needed for synchronization in Multiplayer", 1)
	schema:register(XMLValueType.BOOL, basePath .. "#supportsMultipleFillTypes", "If true capacity can be used by multiple fill types at the same time. If false only one filltype is allowed", true)
	schema:register(XMLValueType.FLOAT, basePath .. "#costsPerFillLevelAndDay", "Costs per fill level and day", 0)
	schema:register(XMLValueType.STRING, basePath .. "#fillTypeCategories", "Supported fill type categories")
	schema:register(XMLValueType.STRING, basePath .. "#fillTypes", "Supported fill types")
	schema:register(XMLValueType.BOOL, basePath .. "#isExtension", "If storage is an extension")
	schema:register(XMLValueType.STRING, basePath .. ".capacity(?)#fillType", "Custom filltype capacity")
	schema:register(XMLValueType.FLOAT, basePath .. ".capacity(?)#capacity", "Custom filltype capacity")
	schema:register(XMLValueType.STRING, basePath .. ".startFillLevel(?)#fillType", "Start filllevel fill type")
	schema:register(XMLValueType.FLOAT, basePath .. ".startFillLevel(?)#fillLevel", "Start filllevel")
	FillPlane.registerXMLPaths(schema, basePath .. ".fillPlane(?)")
	schema:register(XMLValueType.STRING, basePath .. ".fillPlane(?)#className", "Fillplane controller class")
	schema:register(XMLValueType.STRING, basePath .. ".fillPlane(?)#fillType", "Fillplane fill type")
	FillPlaneUtil.registerFillPlaneXMLPaths(schema, basePath .. ".dynamicFillPlane")
	schema:register(XMLValueType.STRING, basePath .. ".dynamicFillPlane#defaultFillType", "Fillplane default filltype")
end

function Storage.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#farmId", "Owner farm land id", 0)
	schema:register(XMLValueType.STRING, basePath .. ".node(?)#fillType", "Fill type name")
	schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#fillLevel", "Fill level", 0)
end

-- Upvalues: Storage_mt
-- Local values: self
function Storage.new(isServer, isClient, customMt)
	-- upvalues: (copy) Storage_mt
	local v9_ = Object.new(isServer, isClient, customMt or Storage_mt)
	v9_.unloadingStations = {}
	v9_.loadingStations = {}
	v9_.fillLevelChangedListeners = {}
	v9_.rootNode = 0
	v9_.foreignSilo = false
	return v9_
end

-- Local values: fillTypeCategories, fillTypeNames, fillTypes, _, fillType, fillType, _, usedCapacity, _, fillPlaneKey, fillTypeName, fillType, fillPlaneClass, fillPlaneClassName, fillPlane, defaultFillTypeName, defaultFillTypeIndex, fillPlane
function Storage:load(components, xmlFile, key, i3dMappings, baseDirectory)
	self.rootNode = xmlFile:getValue(key .. "#node", components[1].node, components, i3dMappings)
	self.costsPerFillLevelAndDay = xmlFile:getValue(key .. "#costsPerFillLevelAndDay") or 0
	self.capacity = xmlFile:getValue(key .. "#capacity", 100000)
	self.fillLevelSyncThreshold = xmlFile:getValue(key .. "#fillLevelSyncThreshold", 1)
	self.supportsMultipleFillTypes = xmlFile:getValue(key .. "#supportsMultipleFillTypes", true)
	self.capacities = {}
	self.fillTypes = {}
	self.fillLevels = {}
	self.fillLevelsLastSynced = {}
	self.fillLevelsLastPublished = {}
	self.sortedFillTypes = {}
	local v16_ = xmlFile:getValue(key .. "#fillTypeCategories")
	local v17_ = xmlFile:getValue(key .. "#fillTypes")
	local v18_ = nil
	if v16_ == nil or v17_ ~= nil then
		if v16_ == nil and v17_ ~= nil then
			v18_ = g_fillTypeManager:getFillTypesByNames(v17_, "Warning: \'" .. tostring(key) .. "\' has invalid fillType \'%s\'.")
		end
	else
		v18_ = g_fillTypeManager:getFillTypesByCategoryNames(v16_, "Warning: \'" .. tostring(key) .. "\' has invalid fillTypeCategory \'%s\'.")
	end
	if v18_ ~= nil then
		for _, v19_ in pairs(v18_) do
			self.fillTypes[v19_] = true
		end
	end
	xmlFile:iterate(key .. ".capacity", function(_, p20_)
		-- upvalues: (copy) xmlFile, (copy) self
		local v21_ = xmlFile:getValue(p20_ .. "#fillType")
		local v22_ = g_fillTypeManager:getFillTypeIndexByName(v21_)
		if v22_ == nil then
			Logging.xmlWarning(xmlFile, "FillType \'%s\' not defined for \'%s\'", v21_, p20_)
		else
			self.fillTypes[v22_] = true
			local v23_ = xmlFile:getValue(p20_ .. "#capacity", 100000)
			self.capacities[v22_] = v23_
		end
	end)
	if table.size(self.fillTypes) == 0 then
		Logging.xmlError(xmlFile, "\'Storage\' entry %s needs either the \'fillTypeCategories\', \'fillTypes\' attribute or fillType specific capacities.", key)
		return false
	end
	for v24_, _ in pairs(self.fillTypes) do
		local v25_ = self.sortedFillTypes
		table.insert(v25_, v24_)
		self.fillLevels[v24_] = 0
		self.fillLevelsLastSynced[v24_] = 0
		self.fillLevelsLastPublished[v24_] = 0
	end
	table.sort(self.sortedFillTypes)
	local v_u_26_ = 0
	xmlFile:iterate(key .. ".startFillLevel", function(_, p27_)
		-- upvalues: (copy) xmlFile, (copy) self, (ref) v_u_26_
		local v28_ = xmlFile:getValue(p27_ .. "#fillType")
		local v29_ = g_fillTypeManager:getFillTypeIndexByName(v28_)
		if v29_ == nil then
			Logging.xmlWarning(xmlFile, "FillType \'%s\' not defined for \'%s\'", v28_, p27_)
			return
		elseif self.fillLevels[v29_] == nil then
			Logging.xmlWarning(xmlFile, "FillType \'%s\' not supported for \'%s\'", v28_, p27_)
			return
		else
			local v30_ = xmlFile:getValue(p27_ .. "#fillLevel")
			if self.supportsMultipleFillTypes then
				if self.capacities[v29_] == nil then
					local v31_ = self.capacity - v_u_26_
					local v32_ = math.clamp(v30_, 0, v31_)
					v_u_26_ = v_u_26_ + v32_
					self.fillLevels[v29_] = v32_
				else
					local v33_ = self.capacities[v29_]
					local v34_ = math.clamp(v30_, 0, v33_)
					self.fillLevels[v29_] = v34_
				end
			elseif v_u_26_ == 0 then
				local v35_ = self.capacities[v29_] or self.capacity
				local v36_ = math.clamp(v30_, 0, v35_)
				v_u_26_ = v36_
				self.fillLevels[v29_] = v36_
			else
				Logging.xmlWarning(xmlFile, "Failed to set start fill level for \'%s\' because only one filltype allowed at the same time for \'%s\'", v28_, p27_)
			end
		end
	end)
	self.fillPlanes = {}
	for _, v37_ in xmlFile:iterator(key .. ".fillPlane") do
		local v38_ = xmlFile:getValue(v37_ .. "#fillType")
		local v39_ = g_fillTypeManager:getFillTypeIndexByName(v38_)
		if v39_ ~= nil then
			local v40_ = xmlFile:getString(v37_ .. "#className")
			local v41_
			if v40_ == nil then
				v41_ = nil
			else
				v41_ = ClassUtil.getClassObject(v40_)
				if v41_ == nil then
					Logging.xmlError(xmlFile, "Fillplane Class \'%s\' not defined!", v40_)
				end
			end
			local v42_ = (v41_ or FillPlane).new()
			if v42_:load(components, xmlFile, v37_, i3dMappings, baseDirectory) then
				self.fillPlanes[v39_] = v42_
			else
				v42_:delete()
			end
		end
	end
	self.dynamicFillPlaneBaseNode = xmlFile:getValue(key .. ".dynamicFillPlane#node", nil, components, i3dMappings)
	if self.dynamicFillPlaneBaseNode ~= nil then
		local v43_ = xmlFile:getValue(key .. ".dynamicFillPlane#defaultFillType")
		local v44_ = g_fillTypeManager:getFillTypeIndexByName(v43_) or self.sortedFillTypes[1]
		local v45_ = FillPlaneUtil.createFromXML(xmlFile, key .. ".dynamicFillPlane", self.dynamicFillPlaneBaseNode, self.capacities[v44_] or self.capacity)
		if v45_ ~= nil then
			FillPlaneUtil.assignDefaultMaterialsFromTerrain(v45_, g_terrainNode)
			FillPlaneUtil.setFillType(v45_, v44_)
			self.dynamicFillPlane = v45_
		end
	end
	self.isExtension = xmlFile:getValue(key .. "#isExtension", false)
	self.storageDirtyFlag = self:getNextDirtyFlag()
	g_messageCenter:subscribe(MessageType.FARM_DELETED, self.farmDestroyed, self)
	return true
end

-- Local values: _, fillPlane
function Storage:delete()
	g_messageCenter:unsubscribeAll(self)
	if self.fillPlanes ~= nil then
		for _, v47_ in pairs(self.fillPlanes) do
			v47_:delete()
		end
		self.fillPlanes = nil
	end
	table.clear(self.unloadingStations)
	table.clear(self.loadingStations)
	table.clear(self.fillLevelChangedListeners)
	Storage:superClass().delete(self)
end

-- Local values: _, fillType, fillLevel
function Storage:readStream(streamId, connection)
	Storage:superClass().readStream(self, streamId, connection)
	for _, v51_ in ipairs(self.sortedFillTypes) do
		self:setFillLevel(not streamReadBool(streamId) and 0 or streamReadFloat32(streamId), v51_)
	end
end

-- Local values: _, fillType, fillLevel
function Storage:writeStream(streamId, connection)
	Storage:superClass().writeStream(self, streamId, connection)
	for _, v55_ in ipairs(self.sortedFillTypes) do
		local v56_ = self.fillLevels[v55_]
		if streamWriteBool(streamId, v56_ > 0) then
			streamWriteFloat32(streamId, v56_)
			self.fillLevelsLastSynced[v55_] = v56_
		end
	end
end

-- Local values: _, fillType, fillLevel
function Storage:readUpdateStream(streamId, timestamp, connection)
	Storage:superClass().readUpdateStream(self, streamId, timestamp, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		for _, v61_ in ipairs(self.sortedFillTypes) do
			self:setFillLevel(not streamReadBool(streamId) and 0 or streamReadFloat32(streamId), v61_)
		end
	end
end

-- Local values: _, fillType, fillLevel
function Storage:writeUpdateStream(streamId, connection, dirtyMask)
	Storage:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v66_ = streamWriteBool
		local v67_ = self.storageDirtyFlag
		if v66_(streamId, bit32.band(dirtyMask, v67_) ~= 0) then
			for _, v68_ in ipairs(self.sortedFillTypes) do
				local v69_ = self.fillLevels[v68_]
				if streamWriteBool(streamId, v69_ > 0) then
					streamWriteFloat32(streamId, v69_)
					self.fillLevelsLastSynced[v68_] = v69_
				end
			end
		end
	end
end

-- Local values: fillTypeIndex, fillLevel, i, siloKey, fillTypeStr, fillLevel, fillTypeIndex
function Storage:loadFromXMLFile(xmlFile, key)
	self:setOwnerFarmId(xmlFile:getValue(key .. "#farmId", AccessHandler.EVERYONE), true)
	for v73_, _ in pairs(self.fillLevels) do
		self.fillLevels[v73_] = 0
	end
	local v74_ = 0
	while true do
		local v75_ = string.format(key .. ".node(%d)", v74_)
		if not xmlFile:hasProperty(v75_) then
			break
		end
		local v76_ = xmlFile:getValue(v75_ .. "#fillType")
		local v77_ = xmlFile:getValue(v75_ .. "#fillLevel", 0)
		local v78_ = math.max(v77_, 0)
		local v79_ = g_fillTypeManager:getFillTypeIndexByName(v76_)
		if v79_ == nil then
			Logging.xmlWarning(xmlFile, "FillType Invalid filltype \'%s\'", v76_)
		elseif self.fillLevels[v79_] == nil then
			Logging.xmlWarning(xmlFile, "FillType \'%s\' is not supported by storage", v76_)
		else
			self:setFillLevel(v78_, v79_, nil)
		end
		v74_ = v74_ + 1
	end
	return true
end

-- Local values: index, fillTypeIndex, fillLevel, fillLevelKey, fillTypeName
function Storage:saveToXMLFile(xmlFile, key, usedModNames)
	xmlFile:setValue(key .. "#farmId", self:getOwnerFarmId())
	local v83_ = 0
	for v84_, v85_ in pairs(self.fillLevels) do
		if v85_ > 0 then
			local v86_ = string.format("%s.node(%d)", key, v83_)
			local v87_ = g_fillTypeManager:getFillTypeNameByIndex(v84_)
			xmlFile:setValue(v86_ .. "#fillType", v87_)
			xmlFile:setValue(v86_ .. "#fillLevel", v85_)
			v83_ = v83_ + 1
		end
	end
end

-- Local values: fillType, _
function Storage:empty()
	for v89_, _ in pairs(self.fillLevels) do
		self.fillLevels[v89_] = 0
		if self.isServer then
			self:raiseDirtyFlags(self.storageDirtyFlag)
		end
	end
end

-- Local values: fillType, fillPlane, fillLevel, capacity, factor
function Storage:updateFillPlanes()
	if self.fillPlanes ~= nil then
		for v91_, v92_ in pairs(self.fillPlanes) do
			local v93_ = self.fillLevels[v91_]
			local v94_ = self:getCapacity(v91_)
			v92_:setState(v94_ <= 0 and 1 or v93_ / v94_)
		end
	end
end

function Storage:getIsFillTypeSupported(fillType)
	return self.fillTypes[fillType] == true
end

function Storage:getFillLevel(fillType)
	return self.fillLevels[fillType] or 0
end

function Storage:getFillLevels()
	return self.fillLevels
end

function Storage:getCapacity(fillType)
	return self.capacities[fillType] or self.capacity
end

-- Local values: capacity, oldLevel, delta, newFillLevelInt, _, func, refNode, width, length, x, y, z, d1x, d1y, d1z, d2x, d2y, d2z, steps, _
function Storage:setFillLevel(fillLevel, fillType, fillInfo)
	local v106_ = self.capacities[fillType] or self.capacity
	local v107_ = math.clamp(fillLevel, 0, v106_)
	if self.fillLevels[fillType] == nil or v107_ == self.fillLevels[fillType] then
		::l4::
		return
	end
	local v108_ = self.fillLevels[fillType]
	self.fillLevels[fillType] = v107_
	local v109_ = self.fillLevels[fillType] - v108_
	local v110_ = MathUtil.round(self.fillLevels[fillType])
	if math.abs(v109_) > 0.1 or self.fillLevelsLastPublished[fillType] ~= v110_ then
		for _, v111_ in ipairs(self.fillLevelChangedListeners) do
			v111_(fillType, v109_)
		end
		self.fillLevelsLastPublished[fillType] = v110_
	end
	if self.isServer then
		if v107_ < 0.1 then
			::l15::
			self:raiseDirtyFlags(self.storageDirtyFlag)
			goto l13
		end
		local v112_ = self.fillLevelsLastSynced[fillType] - v107_
		if math.abs(v112_) >= self.fillLevelSyncThreshold or v106_ - v107_ < 0.1 then
			goto l15
		end
	end
	::l13::
	self:updateFillPlanes()
	if self.dynamicFillPlane ~= nil then
		FillPlaneUtil.setFillType(self.dynamicFillPlane, fillType)
		local v113_ = self.dynamicFillPlane
		local v114_, v115_
		if fillInfo == nil then
			v114_ = 1
			v115_ = 1
		else
			v113_ = fillInfo.node
			v115_ = fillInfo.length
			v114_ = fillInfo.width
		end
		local v116_, v117_, v118_ = localToWorld(v113_, 0, 0, 0)
		local v119_, v120_, v121_ = localDirectionToWorld(v113_, v114_, 0, 0)
		local v122_, v123_, v124_ = localDirectionToWorld(v113_, 0, 0, v115_)
		local v125_ = v109_ / 400
		local v126_ = math.floor(v125_)
		local v127_ = math.clamp(v126_, 1, 25)
		for _ = 1, v127_ do
			fillPlaneAdd(self.dynamicFillPlane, v109_ / v127_, v116_, v117_, v118_, v119_, v120_, v121_, v122_, v123_, v124_)
		end
	end
	goto l4
end

-- Local values: usedCapacity, _, fillLevel, capacity, usedCapacity, usedFillType, usedFillLevel
function Storage:getFreeCapacity(fillType)
	if self.fillLevels[fillType] == nil then
		return 0
	elseif self.supportsMultipleFillTypes then
		if self.capacities[fillType] ~= nil then
			local v130_ = self.capacities[fillType] - self.fillLevels[fillType]
			return math.max(v130_, 0)
		end
		local v131_ = 0
		for _, v132_ in pairs(self.fillLevels) do
			v131_ = v131_ + v132_
		end
		local v133_ = self.capacity - v131_
		return math.max(v133_, 0)
	else
		local v134_ = self.capacities[fillType] or self.capacity
		local v135_ = 0
		for v136_, v137_ in pairs(self.fillLevels) do
			if fillType == v136_ then
				v135_ = v137_
			elseif v137_ > 0 then
				return 0
			end
		end
		local v138_ = v134_ - v135_
		return math.max(v138_, 0)
	end
end

function Storage:getSupportedFillTypes()
	return self.fillTypes
end

-- Local values: fillLevelFactor, costs, _, fillLevel
function Storage:hourChanged()
	if self.isServer then
		local v141_ = self.costsPerFillLevelAndDay / 24 * EconomyManager.getCostMultiplier()
		local v142_ = 0
		for _, v143_ in pairs(self.fillLevels) do
			v142_ = v142_ + v143_ * v141_
		end
		g_currentMission:addMoney(-v142_, self:getOwnerFarmId(), MoneyType.PROPERTY_MAINTENANCE, true)
	end
end

function Storage:addUnloadingStation(station)
	self.unloadingStations[station] = station
end

function Storage:removeUnloadingStation(station)
	self.unloadingStations[station] = nil
end

function Storage:addLoadingStation(loadingStation)
	self.loadingStations[loadingStation] = loadingStation
end

function Storage:removeLoadingStation(loadingStation)
	self.loadingStations[loadingStation] = nil
end

-- Local values: fillType, accepted
function Storage:farmDestroyed(farmId)
	if self:getOwnerFarmId() == farmId then
		for v154_, v155_ in pairs(self.fillTypes) do
			if v155_ then
				self:setFillLevel(0, v154_)
			end
		end
	end
end

function Storage:addFillLevelChangedListeners(func)
	table.addElement(self.fillLevelChangedListeners, func)
end

function Storage:removeFillLevelChangedListeners(func)
	table.removeElement(self.fillLevelChangedListeners, func)
end

-- Local values: debugTable, content, fillType, accepted
function Storage:draw()
	local v161_ = DebugInfoTable.new()
	local v162_ = {}
	for v163_, v164_ in pairs(self.fillTypes) do
		if v164_ then
			local v165_ = {
				["name"] = g_fillTypeManager:getFillTypeNameByIndex(v163_),
				["value"] = string.format("%.3f / %.3f\n", self.fillLevels[v163_] or 0, self.capacities[v163_] or (self.capacity or -1))
			}
			table.insert(v162_, v165_)
		end
	end
	v161_:createWithNodeToCamera(self.rootNode, {
		{
			["title"] = "Storage (without extensions)",
			["content"] = v162_
		}
	}, 1, 0.05)
	g_debugManager:addFrameElement(v161_)
end
