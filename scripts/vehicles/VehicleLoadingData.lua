-- Local values: VehicleLoadingData_mt
VehicleLoadingData = {}
VehicleLoadingData.MIN_SPAWN_PLACE_WIDTH = 4
VehicleLoadingData.MIN_SPAWN_PLACE_LENGTH = 4
VehicleLoadingData.MIN_SPAWN_PLACE_HEIGHT = 3
VehicleLoadingData.SPAWN_WIDTH_OFFSET = 1
local VehicleLoadingData_mt = Class(VehicleLoadingData)

-- Upvalues: VehicleLoadingData_mt
-- Local values: self
function VehicleLoadingData.new(customMt)
	-- upvalues: (copy) VehicleLoadingData_mt
	local v3_ = customMt or VehicleLoadingData_mt
	local v4_ = setmetatable({}, v3_)
	v4_.isValid = false
	v4_.validLocation = true
	v4_.storeItem = nil
	v4_.vehicles = {}
	v4_.vehiclesToLoad = 0
	v4_.loadingVehicles = {}
	v4_.loadedVehicles = {}
	v4_.loadingState = nil
	v4_.savegameData = nil
	v4_.configurations = {}
	v4_.boughtConfigurations = {}
	v4_.configurationData = {}
	v4_.saleItem = nil
	v4_.propertyState = VehiclePropertyState.OWNED
	v4_.ownerFarmId = AccessHandler.EVERYONE
	v4_.isRegistered = true
	v4_.forceServer = false
	v4_.isSaved = true
	v4_.addToPhysics = true
	v4_.price = nil
	v4_.position = { 0, 0, 0 }
	v4_.rotation = { 0, 0, 0 }
	v4_.ignoreShopOffset = false
	v4_.centerVehicle = true
	v4_.customParameters = {}
	return v4_
end

-- Local values: storeItem
function VehicleLoadingData:setFilename(filename)
	local v7_ = g_storeManager:getItemByXMLFilename(filename)
	if v7_ == nil then
		Logging.error("Unable to find vehicle storeitem for \'%s\'", filename)
		printCallstack()
	else
		self:setStoreItem(v7_)
	end
end

-- Local values: _, bundleItem
function VehicleLoadingData:setStoreItem(storeItem)
	if storeItem ~= nil then
		self.storeItem = storeItem
		self.rotation[2] = storeItem.rotation
		self.vehicles = {}
		if self.storeItem.bundleInfo == nil then
			local v10_ = self.vehicles
			local v11_ = {
				["xmlFilename"] = storeItem.xmlFilename
			}
			table.insert(v10_, v11_)
		else
			self.attacherInfo = self.storeItem.bundleInfo.attacherInfo
			for _, v12_ in pairs(self.storeItem.bundleInfo.bundleItems) do
				local v13_ = self.vehicles
				local v14_ = {
					["xmlFilename"] = v12_.xmlFilename,
					["offset"] = v12_.offset,
					["rotationOffset"] = v12_.rotationOffset
				}
				table.insert(v13_, v14_)
			end
		end
	end
	self.isValid = #self.vehicles > 0
end

function VehicleLoadingData:setPropertyState(propertyState)
	self.propertyState = propertyState
end

function VehicleLoadingData:setOwnerFarmId(ownerFarmId)
	self.ownerFarmId = ownerFarmId
end

-- Local values: name, ids, id, _
function VehicleLoadingData:setSaleItem(saleItem)
	self.saleItem = saleItem
	if saleItem ~= nil then
		for v21_, v22_ in pairs(saleItem.boughtConfigurations) do
			if self.boughtConfigurations[v21_] == nil then
				self.boughtConfigurations[v21_] = {}
			end
			for v23_, _ in pairs(v22_) do
				self.boughtConfigurations[v21_][v23_] = true
			end
		end
	end
end

-- Local values: _, key, name, id, configIndex
function VehicleLoadingData:setSavegameData(savegameData)
	self.savegameData = savegameData
	if self.storeItem ~= nil and (savegameData ~= nil and savegameData.xmlFile ~= nil) then
		local v26_, v27_, v28_ = ConfigurationUtil.loadConfigurationsFromXMLFile(self.storeItem.xmlFilename, savegameData.xmlFile, savegameData.key .. ".configuration")
		self.configurations = v26_
		self.boughtConfigurations = v27_
		self.configurationData = v28_
		for _, v29_ in savegameData.xmlFile:iterator(savegameData.key .. ".boughtConfiguration") do
			local v30_ = savegameData.xmlFile:getValue(v29_ .. "#name")
			local v31_ = savegameData.xmlFile:getValue(v29_ .. "#id")
			if v30_ == nil or v31_ == nil then
				Logging.xmlWarning(savegameData.xmlFile, "Invalid bought configuration in \'%s\'!", savegameData.key)
			else
				if self.boughtConfigurations[v30_] == nil then
					self.boughtConfigurations[v30_] = {}
				end
				local v32_ = ConfigurationUtil.getConfigIdBySaveId(self.storeItem.xmlFilename, v30_, v31_)
				if v32_ ~= nil then
					self.boughtConfigurations[v30_][v32_] = true
				end
			end
		end
	end
end

function VehicleLoadingData:setConfigurations(configurations)
	if configurations == nil then
		self.configurations = {}
	else
		self.configurations = configurations
	end
end

function VehicleLoadingData:setBoughtConfigurations(boughtConfigurations)
	if boughtConfigurations == nil then
		self.boughtConfigurations = {}
	else
		self.boughtConfigurations = boughtConfigurations
	end
end

function VehicleLoadingData:setConfigurationData(configurationData)
	if configurationData == nil then
		self.configurationData = {}
	else
		self.configurationData = configurationData
	end
end

-- Local values: configurations, boughtConfigurations, configurationData, storeItem, configName, configId, isValid, configItems, configName, configItems, configIndex, configItem, _, dependentConfig
function VehicleLoadingData:getConfigurations(configFileName)
	local v41_ = table.clone(self.configurations, math.huge)
	local v42_ = table.clone(self.boughtConfigurations, math.huge)
	local v43_ = table.clone(self.configurationData, math.huge)
	local v44_ = g_storeManager:getItemByXMLFilename(configFileName)
	if v44_ ~= nil and v44_ ~= self.storeItem then
		for v45_, v46_ in pairs(v41_) do
			local v47_ = true
			if v44_.configurations == nil or v44_.configurations[v45_] == nil then
				v47_ = false
			elseif v44_.configurations[v45_][v46_] == nil then
				v47_ = false
			end
			if not v47_ then
				v41_[v45_] = nil
				v42_[v45_] = nil
			end
		end
	end
	if v44_ ~= nil and v44_.configurations ~= nil then
		for v48_, v49_ in pairs(v44_.configurations) do
			local v50_ = v41_[v48_]
			if v50_ == nil then
				v50_ = ConfigurationUtil.getDefaultConfigIdFromItems(v49_)
				v41_[v48_] = v50_
			end
			if v49_[v50_] ~= nil then
				local v51_ = v49_[v50_]
				if v51_.dependentConfigurations ~= nil then
					for _, v52_ in ipairs(v51_.dependentConfigurations) do
						v41_[v52_.name] = v52_.index
					end
				end
			end
		end
	end
	return v41_, v42_, v43_
end

function VehicleLoadingData:setIsRegistered(isRegistered)
	self.isRegistered = isRegistered
end

function VehicleLoadingData:setForceServer(forceServer)
	self.forceServer = forceServer
end

function VehicleLoadingData:setIsSaved(isSaved)
	self.isSaved = isSaved
end

function VehicleLoadingData:setAddToPhysics(addToPhysics)
	self.addToPhysics = addToPhysics
end

function VehicleLoadingData:setCustomParameter(name, value)
	self.customParameters[name] = value
end

function VehicleLoadingData:getCustomParameter(name)
	return self.customParameters[name]
end

function VehicleLoadingData:setPosition(x, y, z, terrainOffset)
	if y == nil then
		y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + (terrainOffset or 0)
	end
	local v71_ = self.position
	local v72_ = self.position
	local v73_ = self.position
	v71_[1] = x
	v72_[2] = y
	v73_[3] = z
end

function VehicleLoadingData:setRotation(rx, ry, rz)
	local v78_ = self.rotation
	local v79_ = self.rotation
	local v80_ = self.rotation
	v78_[1] = rx
	v79_[2] = ry
	v80_[3] = rz
end

function VehicleLoadingData:setSpawnNode(node)
	local v83_ = self.position
	local v84_ = self.position
	local v85_ = self.position
	local v86_, v87_, v88_ = getWorldTranslation(node)
	v83_[1] = v86_
	v84_[2] = v87_
	v85_[3] = v88_
	local v89_ = self.rotation
	local v90_ = self.rotation
	local v91_ = self.rotation
	local v92_, v93_, v94_ = getWorldRotation(node)
	v89_[1] = v92_
	v90_[2] = v93_
	v91_[3] = v94_
end

function VehicleLoadingData:setIgnoreShopOffset(ignoreShopOffset)
	self.ignoreShopOffset = ignoreShopOffset
end

-- Local values: i, component
function VehicleLoadingData:setComponentPositionData(vehicle)
	self.componentPositionData = {}
	for v99_, v100_ in ipairs(vehicle.components) do
		self.componentPositionData[v99_] = {
			["translation"] = { getWorldTranslation(v100_.node) },
			["rotation"] = { getWorldRotation(v100_.node) }
		}
	end
end

-- Local values: i, data, savegame, componentPositions, _componentIndex, componentKey, componentIndex, x, y, z, xRot, yRot, zRot, i, position, x, y, z, rx, ry, rz
function VehicleLoadingData:applyPositionData(vehicle)
	if not self.validLocation then
		return false
	end
	if self.componentPositionData ~= nil then
		for v103_ = 1, #vehicle.components do
			local v104_ = self.componentPositionData[v103_]
			if v104_ == nil then
				vehicle:setDefaultComponentPosition(v103_)
			else
				vehicle:setWorldPosition(v104_.translation[1], v104_.translation[2], v104_.translation[3], v104_.rotation[1], v104_.rotation[2], v104_.rotation[3], v103_, true)
			end
		end
		return true
	end
	if self.savegameData == nil then
		local v105_, v106_, v107_, v108_, v109_, v110_ = self:getPositionAndRotation(vehicle)
		vehicle:setAbsolutePosition(v105_, v106_, v107_, v108_, v109_, v110_)
		return true
	end
	local v111_ = self.savegameData
	if v111_.useNewPosition then
		return self:resetVehiclePosition(vehicle)
	end
	if v111_.resetVehicles and not v111_.keepPosition then
		return self:resetVehiclePosition(vehicle)
	end
	local v112_ = {}
	for _, v113_ in v111_.xmlFile:iterator(v111_.key .. ".component") do
		local v114_ = v111_.xmlFile:getValue(v113_ .. "#index")
		local v115_, v116_, v117_ = v111_.xmlFile:getValue(v113_ .. "#position")
		local v118_, v119_, v120_ = v111_.xmlFile:getValue(v113_ .. "#rotation")
		if not (MathUtil.getIsValidTransformationValue(v115_, v116_, v117_) and MathUtil.getIsValidTransformationValue(v118_, v119_, v120_)) then
			Logging.xmlWarning(v111_.xmlFile, "Invalid component position in \'%s\' (%s)!", v111_.key, vehicle.configFileName)
			return self:resetVehiclePosition(vehicle)
		end
		if v112_[v114_] == nil then
			v112_[v114_] = {
				["x"] = v115_,
				["y"] = v116_,
				["z"] = v117_,
				["xRot"] = v118_,
				["yRot"] = v119_,
				["zRot"] = v120_
			}
		else
			Logging.xmlWarning(v111_.xmlFile, "Duplicate component index \'%s\' in \'%s\' (%s)!", v114_, v111_.key, vehicle.configFileName)
		end
	end
	if next(v112_) == nil then
		return self:resetVehiclePosition(vehicle)
	end
	for v121_ = 1, #vehicle.components do
		local v122_ = v112_[v121_]
		if v122_ == nil then
			vehicle:setDefaultComponentPosition(v121_)
		else
			vehicle:setWorldPosition(v122_.x, v122_.y, v122_.z, v122_.xRot, v122_.yRot, v122_.zRot, v121_, true)
		end
	end
	return true
end

-- Local values: resetPlaces, usedPlaces
function VehicleLoadingData:resetVehiclePosition(vehicle)
	local v125_, v126_ = vehicle:getResetPlaces()
	if not self:setLoadingPlace(v125_, v126_) then
		return false
	end
	vehicle:setAbsolutePosition(self.position[1], self.position[2], self.position[3], self.rotation[1], self.rotation[2], self.rotation[3])
	return true
end

-- Local values: offset, rotationOffset, index, loadingVehicle, configName, configIndex, configItems, configItem, shopTransOffset, rotOffset, x, y, z, rx, ry, rz, tempPositionNode, ox, oy, oz, size
function VehicleLoadingData:getPositionAndRotation(vehicle)
	local v129_ = nil
	local v130_ = nil
	for v131_, v132_ in ipairs(self.loadingVehicles) do
		if v132_ == vehicle then
			v129_ = self.vehicles[v131_].offset
			v130_ = self.vehicles[v131_].rotationOffset
		end
	end
	local v133_, v134_
	if self.ignoreShopOffset or self.storeItem == nil then
		v133_ = v130_
		v134_ = v129_
	else
		for v135_, v136_ in pairs(self.configurations) do
			local v137_ = self.storeItem.configurations[v135_]
			if v137_ ~= nil then
				local v138_ = v137_[v136_]
				if v138_ ~= nil then
					if v138_.shopTranslationOffset ~= nil and v129_ == nil then
						v129_ = v138_.shopTranslationOffset
					end
					if v138_.shopRotationOffset ~= nil and v130_ == nil then
						v130_ = v138_.shopRotationOffset
					end
				end
			end
		end
		v134_ = self.storeItem.shopTranslationOffset
		if v134_ == nil then
			v134_ = v129_
		elseif v129_ ~= nil then
			v134_ = v129_
		end
		v133_ = self.storeItem.shopRotationOffset
		if v133_ == nil then
			v133_ = v130_
		elseif v130_ ~= nil then
			v133_ = v130_
		end
	end
	local v139_ = self.position[1]
	local v140_ = self.position[2]
	local v141_ = self.position[3]
	local v142_ = self.rotation[1]
	local v143_ = self.rotation[2]
	local v144_ = self.rotation[3]
	if v134_ ~= nil or v133_ ~= nil then
		local v145_ = createTransformGroup("tempPositionNode")
		setWorldTranslation(v145_, v139_, v140_, v141_)
		setWorldRotation(v145_, v142_, v143_, v144_)
		if v134_ ~= nil then
			local v146_ = v134_[1]
			local v147_ = v134_[2]
			local v148_ = v134_[3]
			if self.centerVehicle then
				local v149_ = StoreItemUtil.getSizeValues(self.storeItem.xmlFilename, "vehicle", self.storeItem.rotation, self.configurations)
				v146_ = v146_ - v149_.widthOffset
				v148_ = v148_ - v149_.lengthOffset
			end
			v139_, v140_, v141_ = localToWorld(v145_, v146_, v147_, v148_)
		end
		if v133_ ~= nil then
			v142_, v143_, v144_ = localRotationToWorld(v145_, v133_[1], v133_[2], v133_[3])
		end
		delete(v145_)
	end
	return v139_, v140_, v141_, v142_, v143_, v144_
end

-- Local values: yRot, size, x, y, z, place, width, _
function VehicleLoadingData:setLoadingPlace(places, usedPlaces, spawnOffset, ignoreMinSpawnItemSize)
	if self.storeItem == nil then
		Logging.error("No store item set before VehicleLoadingData:setLoadingPlace call")
		printCallstack()
		return false
	end
	local v155_ = self.storeItem.rotation
	if self.storeItem.spawnRotationOffset ~= nil then
		v155_ = v155_ + self.storeItem.spawnRotationOffset[2]
	end
	local v156_ = StoreItemUtil.getSizeValues(self.storeItem.xmlFilename, "vehicle", v155_, self.configurations)
	if ignoreMinSpawnItemSize ~= true then
		local v157_ = v156_.width
		local v158_ = VehicleLoadingData.MIN_SPAWN_PLACE_WIDTH
		v156_.width = math.max(v157_, v158_)
		local v159_ = v156_.length
		local v160_ = VehicleLoadingData.MIN_SPAWN_PLACE_LENGTH
		v156_.length = math.max(v159_, v160_)
		local v161_ = v156_.height
		local v162_ = VehicleLoadingData.MIN_SPAWN_PLACE_HEIGHT
		v156_.height = math.max(v161_, v162_)
		if self.storeItem.spawnSizeOffset ~= nil then
			v156_.width = v156_.width + self.storeItem.spawnSizeOffset[1]
			v156_.length = v156_.length + self.storeItem.spawnSizeOffset[2]
			v156_.height = v156_.height + self.storeItem.spawnSizeOffset[3]
		end
	end
	v156_.width = v156_.width + (spawnOffset or VehicleLoadingData.SPAWN_WIDTH_OFFSET)
	local v163_, v164_, v165_, v166_, v167_, _ = PlacementUtil.getPlace(places, v156_, usedPlaces, true, true, false, true)
	if v163_ == nil then
		self.validLocation = false
		return false
	end
	PlacementUtil.markPlaceUsed(usedPlaces, v166_, v167_)
	local v168_ = self.position
	local v169_ = self.position
	local v170_ = self.position
	v168_[1] = v163_
	v169_[2] = v164_
	v170_[3] = v165_
	self.rotation[2] = self.rotation[2] + MathUtil.getYRotationFromDirection(v166_.dirPerpX, v166_.dirPerpZ)
	if self.storeItem.spawnRotationOffset ~= nil then
		self.rotation[2] = self.rotation[2] + self.storeItem.spawnRotationOffset[2]
	end
	return true
end

-- Local values: _, vehicleData, _, vehicleData
function VehicleLoadingData:load(callback, callbackTarget, callbackArguments)
	g_currentMission.vehicleSystem:addPendingVehicleLoad(self)
	self.callback = callback
	self.callbackTarget = callbackTarget
	self.callbackArguments = callbackArguments
	self.vehiclesToLoad = #self.vehicles
	self.loadingVehicles = {}
	self.loadedVehicles = {}
	self.loadingState = VehicleLoadingState.OK
	for _, v175_ in ipairs(self.vehicles) do
		local v176_, v177_ = g_vehicleTypeManager:getObjectTypeFromXML(v175_.xmlFilename)
		v175_.vehicleType = v176_
		v175_.vehicleClass = v177_
		if v175_.vehicleType == nil or v175_.vehicleClass == nil then
			self.loadingState = VehicleLoadingState.ERROR
			if self.callback ~= nil then
				self.callback(self.callbackTarget, self.loadedVehicles, self.loadingState, self.callbackArguments)
				self.callback = nil
				self.callbackTarget = nil
				self.callbackArguments = nil
			end
			g_currentMission.vehicleSystem:removePendingVehicleLoad(self)
			return
		end
	end
	for _, v178_ in ipairs(self.vehicles) do
		self:loadVehicle(v178_)
	end
end

-- Local values: isServer, isClient, vehicle
function VehicleLoadingData:loadVehicle(vehicleData)
	local v181_ = self.forceServer or g_currentMission:getIsServer()
	local v182_ = self.forceServer or g_currentMission:getIsClient()
	local v183_ = vehicleData.vehicleClass.new(v181_, v182_)
	v183_:setFilename(vehicleData.xmlFilename)
	v183_:setConfigurations(self:getConfigurations(vehicleData.xmlFilename))
	v183_:setType(vehicleData.vehicleType)
	v183_:setLoadCallback(self.onVehicleLoaded, self, nil)
	v183_:load(self)
	local v184_ = self.loadingVehicles
	table.insert(v184_, v183_)
end

-- Local values: _, vehicle
function VehicleLoadingData:cancelLoading()
	self.canceledLoading = true
	for _, v186_ in ipairs(self.loadingVehicles) do
		v186_:delete()
	end
	if self.callback ~= nil then
		self.callback(self.callbackTarget, {}, VehicleLoadingState.CANCELED, self.callbackArguments)
		self.callback = nil
		self.callbackTarget = nil
		self.callbackArguments = nil
	end
	g_currentMission.vehicleSystem:removePendingVehicleLoad(self)
end

-- Local values: vehicleData, vehicleType, _, loadCallback
function VehicleLoadingData:loadVehicleOnClient(vehicle, callback, callbackTarget)
	local v190_ = self.vehicles[1]
	local v191_, _ = g_vehicleTypeManager:getObjectTypeFromXML(v190_.xmlFilename)
	if v191_ ~= nil then
		g_currentMission.vehicleSystem:addPendingVehicleLoad(self)
		vehicle:setFilename(v190_.xmlFilename)
		vehicle:setConfigurations(self:getConfigurations(v190_.xmlFilename))
		vehicle:setType(v191_)
		vehicle:setLoadCallback(function(...)
			-- upvalues: (copy) self, (copy) callback
			g_currentMission.vehicleSystem:removePendingVehicleLoad(self)
			callback(...)
		end, self, nil)
		vehicle:load(self)
	end
end

-- Local values: _, attachInfo, i, _, loadedVehicle, _, attachInfo, v1, v2
function VehicleLoadingData:onVehicleLoaded(vehicle, loadingState)
	if self.canceledLoading then
		return
	end
	if loadingState == VehicleLoadingState.OK then
		local v195_ = self.loadedVehicles
		table.insert(v195_, vehicle)
		vehicle:setVisibility(false)
		vehicle:removeFromPhysics()
	else
		self.loadingState = loadingState
		vehicle:delete()
	end
	self.vehiclesToLoad = self.vehiclesToLoad - 1
	if self.vehiclesToLoad <= 0 then
		if self.attacherInfo ~= nil then
			for _, v196_ in pairs(self.attacherInfo) do
				if self.loadedVehicles[v196_.bundleElement0] == nil or self.loadedVehicles[v196_.bundleElement1] == nil then
					Logging.error("Not all vehicles for bundle item could be loaded")
					self.loadingState = VehicleLoadingState.ERROR
					break
				end
			end
		end
		if self.loadingState == VehicleLoadingState.OK then
			for _, v197_ in ipairs(self.loadedVehicles) do
				v197_:setVisibility(true)
				if self.addToPhysics then
					v197_:addToPhysics()
				end
				if self.saleItem ~= nil then
					SpecializationUtil.raiseEvent(v197_, "onSaleItemSet", self.saleItem)
					v197_.operatingTime = self.saleItem.operatingTime
					v197_.age = self.saleItem.age
				end
				g_messageCenter:publish(MessageType.VEHICLE_LOADED, v197_)
			end
			if self.attacherInfo ~= nil then
				for _, v198_ in pairs(self.attacherInfo) do
					local v199_ = self.loadingVehicles[v198_.bundleElement0]
					local v200_ = self.loadingVehicles[v198_.bundleElement1]
					if v199_ == nil or (v200_ == nil or (v199_.attachImplement == nil or v200_.getInputAttacherJoints == nil)) then
						Logging.warning("Unable to attach bundle items together. (implement \'%s\' to vehicle \'%s\')", v200_:getName(), v199_:getName())
					else
						v199_:attachImplement(v200_, v198_.inputAttacherJointIndex, v198_.attacherJointIndex, true, nil, false, true)
					end
				end
			end
		else
			for v201_ = #self.loadedVehicles, 1, -1 do
				self.loadedVehicles[v201_]:delete()
				self.loadedVehicles[v201_] = nil
			end
		end
		if self.callback ~= nil then
			self.callback(self.callbackTarget, self.loadedVehicles, self.loadingState, self.callbackArguments)
			self.callback = nil
			self.callbackTarget = nil
			self.callbackArguments = nil
		end
		g_currentMission.vehicleSystem:removePendingVehicleLoad(self)
	end
end
