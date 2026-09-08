-- Local values: VehicleSystem_mt
VehicleSystem = {}
VehicleSystem.UNIQUE_ID_PREFIX = "vehicle"
local VehicleSystem_mt = Class(VehicleSystem)

-- Upvalues: VehicleSystem_mt
-- Local values: self
function VehicleSystem.new(mission, customMt)
	-- upvalues: (copy) VehicleSystem_mt
	local v4_ = customMt or VehicleSystem_mt
	local v5_ = setmetatable({}, v4_)
	v5_.mission = mission
	v5_.vehicles = {}
	v5_.pendingVehicleLoadingData = {}
	v5_.pendingVehicleSavegameLoadings = {}
	v5_.vehicleByUniqueId = {}
	v5_.wetVehicles = {}
	v5_.enterables = {}
	v5_.lastEnteredVehicleIndex = 1
	v5_.inputAttacherJoints = {}
	v5_.interactiveVehicles = {}
	v5_.vehiclesToDelete = {}
	v5_.isReloadRunning = false
	if g_addCheatCommands then
		addConsoleCommand("gsVehicleShowDistance", "Shows the distance between vehicle and cam", "consoleCommandShowVehicleDistance", v5_)
	end
	if v5_.mission:getIsServer() then
		addConsoleCommand("gsVehicleReload", "Reloads currently entered vehicle or vehicles within a range when second radius parameter is given", "consoleCommandReloadVehicle", v5_, "[resetVehicle]; [radiusAroundPlayer]")
		if g_addCheatCommands then
			addConsoleCommand("gsPalletAdd", "Adds a pallet", "consoleCommandAddPallet", v5_, "fillTypeName; [fillAmount]; [worldX]; [worldZ]")
			addConsoleCommand("gsVehicleFuelSet", "Sets the vehicle fuel level", "consoleCommandSetFuel", v5_)
			addConsoleCommand("gsVehicleTemperatureSet", "Sets the vehicle motor temperature", "consoleCommandSetMotorTemperature", v5_)
			addConsoleCommand("gsFillUnitAdd", "Changes a fillUnit with given filllevel and filltype", "consoleCommandFillUnitAdd", v5_, "fillUnitIndex; fillTypeName; [amount]")
			addConsoleCommand("gsVehicleOperatingTimeSet", "Sets the vehicle operating time", "consoleCommandSetOperatingTime", v5_)
			addConsoleCommand("gsVehicleAddDirt", "Adds a given amount to current dirt amount", "consoleCommandAddDirtAmount", v5_)
			addConsoleCommand("gsVehicleAddWear", "Adds a given amount to current wear amount", "consoleCommandAddWearAmount", v5_)
			addConsoleCommand("gsVehicleAddWetness", "Adds a given amount to current wetness amount", "consoleCommandAddWetnessAmount", v5_)
			addConsoleCommand("gsVehicleAddDamage", "Adds a given amount to current damage amount", "consoleCommandAddDamageAmount", v5_)
			addConsoleCommand("gsVehicleLoadAll", "Load all vehicles", "consoleCommandLoadAllVehicles", v5_, "[loadConfigs]; [modsOnly]; [palletsOnly]; [verbose]", true)
		end
		if g_addTestCommands then
			addConsoleCommand("gsVehicleToggleRandomFail", "Toggles random vehicle load failing", "consoleCommandVehicleToggleRandomFail", v5_)
			addConsoleCommand("gsVehicleRemoveAll", "Removes all vehicles from current mission", "consoleCommandVehicleRemoveAll", v5_, nil, true)
			addConsoleCommand("gsExportVehicleSets", "Exports vehicle sets", "consoleCommandExportVehicleSets", v5_)
		end
	end
	if g_addTestCommands then
		addConsoleCommand("gsVehiclesPendingLoadings", "Prints the pending vehicle loadings", "consoleCommandPrintPendingLoadings", v5_)
	end
	g_messageCenter:subscribe(BuyVehicleEvent, v5_.onVehicleBuyEvent, v5_)
	return v5_
end

-- Local values: i, k, vehicle, i, vehicle
function VehicleSystem:delete()
	for v7_ = #self.pendingVehicleLoadingData, 1, -1 do
		self.pendingVehicleLoadingData[v7_]:cancelLoading()
	end
	for v8_, v9_ in pairs(self.vehiclesToDelete) do
		v9_:delete(true)
		self.vehiclesToDelete[v8_] = nil
	end
	for v10_ = #self.vehicles, 1, -1 do
		self.vehicles[v10_]:delete(true)
	end
	if self.savegameXMLFile ~= nil then
		self.savegameXMLFile:delete()
		self.savegameXMLFile = nil
	end
	self.mission = nil
	self.vehicles = {}
	self.vehicleByUniqueId = {}
	self.wetVehicles = {}
	self.enterables = {}
	self.interactiveVehicles = {}
	g_messageCenter:unsubscribeAll(self)
	removeConsoleCommand("gsVehicleShowDistance")
	removeConsoleCommand("gsVehicleReload")
	removeConsoleCommand("gsPalletAdd")
	removeConsoleCommand("gsVehicleFuelSet")
	removeConsoleCommand("gsVehicleTemperatureSet")
	removeConsoleCommand("gsFillUnitAdd")
	removeConsoleCommand("gsVehicleOperatingTimeSet")
	removeConsoleCommand("gsVehicleAddDirt")
	removeConsoleCommand("gsVehicleAddWear")
	removeConsoleCommand("gsVehicleAddWetness")
	removeConsoleCommand("gsVehicleAddDamage")
	removeConsoleCommand("gsVehicleLoadAll")
	removeConsoleCommand("gsVehicleRemoveAll")
	removeConsoleCommand("gsExportVehicleSets")
	removeConsoleCommand("gsVehiclesPendingLoadings")
end

-- Local values: numDeleted, i, vehicle
function VehicleSystem:deleteAll()
	local v12_ = #self.vehicles
	for v13_ = #self.vehicles, 1, -1 do
		self.vehicles[v13_]:delete()
	end
	return v12_
end

-- Local values: numDeleted, i, vehicle
function VehicleSystem:deleteAllPallets()
	local v15_ = 0
	for v16_ = #self.vehicles, 1, -1 do
		local v17_ = self.vehicles[v16_]
		if v17_.isPallet then
			v17_:delete()
			v15_ = v15_ + 1
		end
	end
	return v15_
end

-- Local values: weather, indoorMask, rainScale, timeScale, timeSinceLastRain, temperature, _, vehicle, x, _, z, isInside, timeScale, vehicle, _
function VehicleSystem:update(dt)
	if self.debugVehiclesToBeLoaded ~= nil then
		self:consoleCommandLoadAllVehiclesNext()
	end
	if g_server ~= nil then
		local v20_ = g_currentMission.environment.weather
		local v21_ = g_currentMission.indoorMask
		if v20_:getRainFallScale() > 0.1 then
			local v22_ = g_currentMission:getEffectiveTimeScale()
			local v23_ = v20_:getTimeSinceLastRain()
			local v24_ = v20_:getCurrentTemperature()
			if v23_ < 30 and v24_ > 0 then
				for _, v25_ in pairs(self.vehicles) do
					if not v25_:getIsInShowroom() and v25_.updateWetness ~= nil then
						local v26_, _, v27_ = getWorldTranslation(v25_.rootNode)
						if v21_:getIsIndoorAtWorldPosition(v26_, v27_) then
							v25_:updateWetness(false, dt * v22_)
							if not v25_:getIsWet() then
								self.wetVehicles[v25_] = nil
							end
						else
							v25_:updateWetness(true, dt * v22_)
							if v25_:getIsWet() then
								self.wetVehicles[v25_] = v25_
							end
						end
					end
				end
				return
			end
		elseif next(self.wetVehicles) ~= nil then
			local v28_ = g_currentMission:getEffectiveTimeScale()
			for v29_, _ in pairs(self.wetVehicles) do
				v29_:updateWetness(false, dt * v28_)
				if not v29_:getIsWet() then
					self.wetVehicles[v29_] = nil
				end
			end
		end
	end
end

-- Local values: _, vehicle
function VehicleSystem:draw()
	for _, v31_ in pairs(self.enterables) do
		v31_:drawUIInfo()
	end
end

-- Local values: k, vehicle
function VehicleSystem:deleteMarkedVehicles()
	for v33_, v34_ in pairs(self.vehiclesToDelete) do
		v34_:delete(true)
		self.vehiclesToDelete[v33_] = nil
	end
end

function VehicleSystem:markVehicleForDeletion(vehicle)
	self.vehiclesToDelete[vehicle] = vehicle
end

function VehicleSystem:addVehicle(vehicle)
	if vehicle == nil or vehicle:isa(Vehicle) == nil then
		Logging.error("Given object is not a vehicle")
		return false
	end
	if vehicle:getUniqueId() ~= nil and self.vehicleByUniqueId[vehicle:getUniqueId()] ~= nil then
		local v39_ = Logging.warning
		local v40_ = vehicle:getUniqueId()
		local v41_ = self.vehicleByUniqueId[vehicle:getUniqueId()]
		v39_("Tried to add existing vehicle with unique id of %s! Existing: %s, new: %s", v40_, tostring(v41_), (tostring(vehicle)))
		return false
	end
	if vehicle:getUniqueId() == nil then
		vehicle:setUniqueId(Utils.getUniqueId(vehicle, self.vehicleByUniqueId, VehicleSystem.UNIQUE_ID_PREFIX))
	end
	table.addElement(self.vehicles, vehicle)
	self.vehicleByUniqueId[vehicle:getUniqueId()] = vehicle
	if vehicle.getIsWet ~= nil and vehicle:getIsWet() then
		self.wetVehicles[vehicle] = vehicle
	end
	g_messageCenter:publish(MessageType.VEHICLE_ADDED)
	return true
end

-- Local values: uniqueId
function VehicleSystem:removeVehicle(vehicle)
	table.removeElement(self.vehicles, vehicle)
	local v44_ = vehicle:getUniqueId()
	if v44_ ~= nil and self.vehicleByUniqueId[v44_] == vehicle then
		self.vehicleByUniqueId[v44_] = nil
	end
	self.wetVehicles[vehicle] = nil
	g_messageCenter:publish(MessageType.VEHICLE_REMOVED)
end

function VehicleSystem:getVehicleByUniqueId(uniqueId)
	return self.vehicleByUniqueId[uniqueId]
end

function VehicleSystem:addPendingVehicleLoad(vehicleLoadingData)
	table.addElement(self.pendingVehicleLoadingData, vehicleLoadingData)
end

function VehicleSystem:removePendingVehicleLoad(vehicleLoadingData)
	table.removeElement(self.pendingVehicleLoadingData, vehicleLoadingData)
end

function VehicleSystem:getNumPendingVehicles()
	return #self.pendingVehicleLoadingData
end

-- Local values: i
function VehicleSystem:canStartMission()
	for v53_ = 1, #self.vehicles do
		if not self.vehicles[v53_]:getIsSynchronized() then
			return false
		end
	end
	return #self.pendingVehicleLoadingData <= 0
end

function VehicleSystem:addEnterableVehicle(vehicle)
	table.addElement(self.enterables, vehicle)
end

function VehicleSystem:removeEnterableVehicle(vehicle)
	table.removeElement(self.enterables, vehicle)
	local v58_ = self.lastEnteredVehicleIndex
	local v59_ = #self.enterables
	local v60_ = math.min(v58_, v59_)
	self.lastEnteredVehicleIndex = math.max(1, v60_)
end

-- Local values: i
function VehicleSystem:setEnteredVehicle(vehicle)
	for v63_ = 1, #self.enterables do
		if self.enterables[v63_] == vehicle then
			self.lastEnteredVehicleIndex = v63_
			return
		end
	end
end

-- Local values: numVehicles, index, i, enterable, found, _, enterable
function VehicleSystem:getNextEnterableVehicle(currentVehicle, delta)
	local v67_ = #self.enterables
	if v67_ == 0 then
		return nil
	end
	local v68_ = 1
	if g_localPlayer:getIsInVehicle() and currentVehicle ~= nil then
		for v69_, _ in ipairs(self.enterables) do
			if currentVehicle == self.enterables[v69_] then
				v68_ = v69_ + delta
				break
			end
		end
	elseif delta > 0 then
		v68_ = self.lastEnteredVehicleIndex
	else
		v68_ = v67_
	end
	local v70_ = false
	for _ = 1, v67_ do
		local v71_ = self.enterables[v68_]
		if v71_ ~= nil and (v71_:getIsTabbable() and v71_:getIsEnterable()) then
			v70_ = true
			break
		end
		v68_ = v68_ + delta
		if v67_ < v68_ then
			v68_ = 1
		elseif v68_ < 1 then
			v68_ = v67_
		end
	end
	if v70_ then
		return self.enterables[v68_]
	else
		return nil
	end
end

-- Local values: inputAttacherJointInfo
function VehicleSystem:registerInputAttacherJoint(vehicle, inputAttacherJointIndex, inputAttacherJoint)
	local v76_ = {
		["vehicle"] = vehicle,
		["jointIndex"] = inputAttacherJointIndex,
		["inputAttacherJoint"] = inputAttacherJoint,
		["node"] = inputAttacherJoint.node,
		["jointType"] = inputAttacherJoint.jointType,
		["translation"] = { getWorldTranslation(inputAttacherJoint.node) }
	}
	table.addElement(self.inputAttacherJoints, v76_)
	return v76_
end

-- Local values: x, y, z
function VehicleSystem:updateInputAttacherJoint(inputAttacherJointInfo)
	local v78_, v79_, v80_ = getWorldTranslation(inputAttacherJointInfo.node)
	local v81_ = inputAttacherJointInfo.translation
	local v82_ = inputAttacherJointInfo.translation
	local v83_ = inputAttacherJointInfo.translation
	v81_[1] = v78_
	v82_[2] = v79_
	v83_[3] = v80_
end

function VehicleSystem:removeInputAttacherJoint(inputAttacherJointInfo)
	table.removeElement(self.inputAttacherJoints, inputAttacherJointInfo)
end

function VehicleSystem:addInteractiveVehicle(vehicle)
	self.interactiveVehicles[vehicle] = vehicle
end

function VehicleSystem:removeInteractiveVehicle(vehicle)
	self.interactiveVehicles[vehicle] = nil
end

-- Local values: xmlFile
function VehicleSystem:save(xmlFilename, usedModNames)
	local v93_ = XMLFile.create("vehiclesXML", xmlFilename, "vehicles", Vehicle.xmlSchemaSavegame)
	if v93_ ~= nil then
		self:saveToXML(self.vehicles, v93_, usedModNames)
		v93_:delete()
	end
end

-- Local values: xmlIndex, i, vehicle
function VehicleSystem:saveToXML(vehicles, xmlFile, usedModNames)
	if xmlFile ~= nil then
		local v98_ = 0
		for v99_, v100_ in ipairs(vehicles) do
			if v100_:getNeedsSaving() then
				self:saveVehicleToXML(v100_, xmlFile, v98_, v99_, usedModNames)
				v98_ = v98_ + 1
			end
		end
		xmlFile:save(false, true)
	end
end

-- Local values: vehicleKey, modName
function VehicleSystem:saveVehicleToXML(vehicle, xmlFile, index, i, usedModNames)
	local v105_ = string.format("vehicles.vehicle(%d)", index)
	local v106_ = vehicle.customEnvironment
	if v106_ ~= nil then
		if usedModNames ~= nil then
			usedModNames[v106_] = v106_
		end
		xmlFile:setValue(v105_ .. "#modName", v106_)
	end
	xmlFile:setValue(v105_ .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(vehicle.configFileName)))
	vehicle:saveToXMLFile(xmlFile, v105_, usedModNames)
end

function VehicleSystem:load(xmlFilename, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments, resetVehicles)
	self.savegameXMLFile = XMLFile.load("vehiclesXML", xmlFilename, Vehicle.xmlSchemaSavegame)
	if self.savegameXMLFile == nil then
		Logging.xmlError(xmlFilename, "Loading vehicles xml file failed")
		g_asyncTaskManager:addSubtask(function()
			-- upvalues: (copy) asyncCallbackFunction, (copy) asyncCallbackObject, (copy) asyncCallbackArguments
			asyncCallbackFunction(asyncCallbackObject, {}, VehicleLoadingState.ERROR, asyncCallbackArguments)
		end)
	else
		self:loadFromXMLFile(self.savegameXMLFile, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	end
end

-- Local values: savegameLoadingData, defaultItemsToSPFarm
function VehicleSystem:loadFromXMLFile(xmlFile, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments, resetVehicles, keepPosition)
	if self.loadedVehicles == nil then
		local v_u_119_ = xmlFile:getValue("vehicles#loadAnyFarmInSingleplayer", false)
		self.loadedVehicles = {}
		self.vehiclesToLoad = 0
		self.vehicleLoadingState = nil
		self.asyncCallbackFunction = asyncCallbackFunction
		self.asyncCallbackObject = asyncCallbackObject
		self.asyncCallbackArguments = asyncCallbackArguments
		xmlFile:iterate("vehicles.vehicle", function(_, p_u_120_)
			-- upvalues: (copy) self, (copy) xmlFile, (copy) v_u_119_, (copy) resetVehicles, (copy) keepPosition
			g_asyncTaskManager:addSubtask(function()
				-- upvalues: (ref) self, (ref) xmlFile, (copy) p_u_120_, (ref) v_u_119_, (ref) resetVehicles, (ref) keepPosition
				self:loadVehicleFromXML(xmlFile, p_u_120_, v_u_119_, resetVehicles, keepPosition)
			end)
		end)
		g_asyncTaskManager:addSubtask(function()
			-- upvalues: (copy) self
			if self.vehiclesToLoad <= 0 then
				if self.asyncCallbackFunction ~= nil then
					self.asyncCallbackFunction(self.asyncCallbackObject, self.loadedVehicles, VehicleLoadingState.OK, self.asyncCallbackArguments)
					self.asyncCallbackFunction = nil
					self.asyncCallbackObject = nil
					self.asyncCallbackArguments = nil
				end
				self.loadedVehicles = nil
				self.vehicleLoadingState = nil
				self:updatePendingSavegameLoadings()
			end
		end)
	else
		local v121_ = self.pendingVehicleSavegameLoadings
		table.insert(v121_, {
			["xmlFile"] = xmlFile,
			["asyncCallbackFunction"] = asyncCallbackFunction,
			["asyncCallbackObject"] = asyncCallbackObject,
			["asyncCallbackArguments"] = asyncCallbackArguments,
			["resetVehicles"] = resetVehicles,
			["keepPosition"] = keepPosition
		})
	end
end

-- Local values: missionInfo, missionDynamicInfo, filename, defaultProperty, farmId, loadForCompetitive, loadDefaultProperty, allowedToLoad, storeItem, savegame, data
function VehicleSystem:loadVehicleFromXML(xmlFile, key, defaultItemsToSPFarm, resetVehicles, keepPosition)
	local v128_ = g_currentMission.missionInfo
	local v129_ = g_currentMission.missionDynamicInfo
	local v130_ = xmlFile:getValue(key .. "#filename")
	local v131_ = xmlFile:getValue(key .. "#defaultFarmProperty", false)
	local v132_ = xmlFile:getValue(key .. "#farmId")
	local v133_ = v131_ and v128_.isCompetitiveMultiplayer
	if v133_ then
		v133_ = g_farmManager:getFarmById(v132_) ~= nil
	end
	local v134_ = v131_ and (v128_.loadDefaultFarm and not v129_.isMultiplayer)
	if v134_ then
		v134_ = v132_ == FarmManager.SINGLEPLAYER_FARM_ID and true or defaultItemsToSPFarm
	end
	if not v128_.isValid and (v131_ and not (v134_ or v133_)) then
		Logging.xmlInfo(xmlFile, "Vehicle \'%s\' is not allowed to be loaded", v130_)
		return false
	end
	local v135_ = NetworkUtil.convertFromNetworkFilename(v130_)
	local v136_ = g_storeManager:getItemByXMLFilename(v135_)
	if v136_ == nil then
		Logging.xmlWarning(xmlFile, "Unable to retrieve store item for vehicle xml \'%s\'", v135_)
		return false
	end
	local v137_ = {
		["xmlFile"] = xmlFile,
		["key"] = key,
		["ignoreFarmId"] = false,
		["resetVehicles"] = resetVehicles,
		["keepPosition"] = keepPosition
	}
	if v134_ and (defaultItemsToSPFarm and v132_ ~= FarmManager.SINGLEPLAYER_FARM_ID) then
		v132_ = FarmManager.SINGLEPLAYER_FARM_ID
		v137_.ignoreFarmId = true
	end
	if not g_currentMission.slotSystem:hasEnoughSlots(v136_) then
		g_currentMission:addMoney(v136_.price, v132_, MoneyType.SHOP_VEHICLE_SELL, true)
		Logging.xmlWarning(xmlFile, "Too many slots in use. Selling vehicle \'%s\' for \'%d\'", v135_, v136_.price)
		return false
	end
	self.vehiclesToLoad = self.vehiclesToLoad + 1
	local v138_ = VehicleLoadingData.new()
	v138_:setStoreItem(v136_)
	v138_:setSavegameData(v137_)
	v138_:setAddToPhysics(false)
	v138_:load(self.loadVehicleFinished, self)
	return true
end

-- Local values: _, vehicle, _, loadedVehicle
function VehicleSystem:loadVehicleFinished(vehicles, loadingState)
	if loadingState == VehicleLoadingState.OK then
		for _, v142_ in ipairs(vehicles) do
			local v143_ = self.loadedVehicles
			table.insert(v143_, v142_)
		end
	else
		self.vehicleLoadingState = self.vehicleLoadingState or loadingState
	end
	self.vehiclesToLoad = self.vehiclesToLoad - 1
	if self.vehiclesToLoad <= 0 then
		for _, v144_ in ipairs(self.loadedVehicles) do
			v144_:addToPhysics()
		end
		if self.asyncCallbackFunction ~= nil then
			self.asyncCallbackFunction(self.asyncCallbackObject, self.loadedVehicles, self.vehicleLoadingState or VehicleLoadingState.OK, self.asyncCallbackArguments)
			self.asyncCallbackFunction = nil
			self.asyncCallbackObject = nil
			self.asyncCallbackArguments = nil
		end
		self.loadedVehicles = nil
		self.vehicleLoadingState = nil
		self:updatePendingSavegameLoadings()
	end
end

-- Local values: savegameLoadingData
function VehicleSystem:updatePendingSavegameLoadings()
	if #self.pendingVehicleSavegameLoadings > 0 then
		local v146_ = self.pendingVehicleSavegameLoadings[1]
		table.remove(self.pendingVehicleSavegameLoadings, 1)
		self:loadFromXMLFile(v146_.xmlFile, v146_.asyncCallbackFunction, v146_.asyncCallbackObject, v146_.asyncCallbackArguments, v146_.resetVehicles, v146_.keepPosition)
	end
end

-- Local values: serverFarmId, numDrivables, numVehicles, _, item
function VehicleSystem:onVehicleBuyEvent(errorCode, leaseVehicle, price)
	local v148_ = g_currentMission:getFarmId()
	local v149_ = 0
	local v150_ = 0
	for _, v151_ in ipairs(self.vehicles) do
		if v151_:getOwnerFarmId() == v148_ then
			if v151_.spec_drivable == nil then
				if v151_.spec_attachable ~= nil and v151_.spec_bigBag == nil then
					v149_ = v149_ + 1
				end
			else
				v150_ = v150_ + 1
				v149_ = v149_ + 1
			end
		end
	end
	g_achievementManager:tryUnlock("NumDrivables", v150_)
	g_achievementManager:tryUnlock("NumVehiclesSmall", v149_)
	g_achievementManager:tryUnlock("NumVehiclesLarge", v149_)
end

-- Local values: vehicle, parentId
function VehicleSystem:getVehicleByNodeId(nodeId, subShapeId)
	local v154_
	if nodeId == subShapeId then
		v154_ = g_currentMission.nodeToObject[nodeId]
	else
		v154_ = nil
		while subShapeId ~= 0 do
			if g_currentMission.nodeToObject[subShapeId] ~= nil then
				v154_ = g_currentMission.nodeToObject[subShapeId]
				break
			end
			subShapeId = getParent(subShapeId)
		end
	end
	if v154_ == nil or (v154_.isa == nil or not v154_:isa(Vehicle)) then
		return nil
	else
		return v154_
	end
end

-- Local values: _, pendingData, _, vehicle
function VehicleSystem:consoleCommandPrintPendingLoadings()
	Logging.info("Pending Vehicle Loadings:")
	for _, v156_ in ipairs(self.pendingVehicleLoadingData) do
		Logging.info("    - %s (Num pending: %d | State: %s)", v156_.storeItem == nil and "Unknown" or (v156_.storeItem.xmlFilename or "Unknown"), v156_.vehiclesToLoad, VehicleLoadingState.getName(v156_.loadingState))
	end
	Logging.info("Pending Vehicles:")
	for _, v157_ in ipairs(self.vehicles) do
		if not v157_:getIsSynchronized() then
			Logging.info("    - LoadingState: %s (%s) | LoadingStep: %s (%s) | %s", VehicleLoadingState.getName(v157_.loadingState), v157_.loadingState, SpecializationUtil.getLoadingStepName(v157_.loadingStep), v157_.loadingStep, v157_.configFileName)
		end
	end
end

function VehicleSystem:consoleCommandShowVehicleDistance(active)
	g_showVehicleDistance = Utils.getNoNil(active, not g_showVehicleDistance)
end

-- Local values: usage, posX, posY, posZ, affectedVehicles, usedVehicles, usedModNames, addVehicleToReload, _, v, vx, vy, vz, xmlFile, _, vehicle, _, vehicle, steerableId, asyncCallbackFunction
function VehicleSystem:consoleCommandReloadVehicle(resetVehicle, radius)
	if g_gui.currentGuiName == "ShopMenu" or g_gui.currentGuiName == "ShopConfigScreen" then
		return "Error: Reload not supported while in shop!"
	end
	if self.isReloadRunning then
		return "Error: Reloading of vehicles already in progress!"
	end
	if not self.mission:getIsServer() or self.mission.missionDynamicInfo.isMultiplayer then
		return "Error: Reloading only available in SP"
	end
	local v_u_162_ = Utils.stringToBoolean(resetVehicle)
	local v163_ = tonumber(radius) or 0
	local v164_, v165_, v166_ = g_localPlayer:getPosition()
	g_soundManager:reloadSoundTemplates()
	g_vehicleMaterialManager:loadMaterialTemplates(VehicleMaterialManager.DEFAULT_TEMPLATES_FILENAME)
	g_vehicleMaterialManager:loadMaterialTemplates(VehicleMaterialManager.DEFAULT_BRAND_TEMPLATES_FILENAME)
	local v_u_167_ = {}
	local v_u_168_ = {}
	local v169_ = {}
	local function v_u_174_(p170_, p171_)
		-- upvalues: (copy) v_u_168_, (copy) v_u_174_
		if p170_.isVehicleSaved then
			p170_.isReconfigurating = true
			table.insert(p171_, p170_)
			v_u_168_[p170_] = true
			if p170_ ~= nil and p170_.getAttachedImplements ~= nil then
				local v172_ = p170_:getAttachedImplements()
				for _, v173_ in pairs(v172_) do
					v_u_174_(v173_.object, p171_)
				end
				return
			end
		else
			p170_:delete()
		end
	end
	if g_localPlayer:getCurrentVehicle() ~= nil then
		v_u_174_(g_localPlayer:getCurrentVehicle(), v_u_167_)
	end
	if v163_ ~= 0 then
		for _, v175_ in pairs(self.vehicles) do
			if v175_ ~= g_localPlayer:getCurrentVehicle() then
				local v176_, v177_, v178_ = getWorldTranslation(v175_.rootNode)
				if MathUtil.vector3Length(v176_ - v164_, v177_ - v165_, v178_ - v166_) < v163_ and v_u_168_[v175_.rootVehicle] == nil then
					v_u_174_(v175_.rootVehicle, v_u_167_)
				end
			end
		end
	end
	if #v_u_167_ == 0 then
		return "Warning: No vehicle reloaded. Enter a vehicle first or use the command with the radius parameter given, e.g. \'gsVehicleReload false 25\'\nUsage: gsVehicleReload [resetVehicle] [radius]"
	end
	local v_u_179_ = XMLFile.create("reloadVehiclesXMLFile", "", "vehicles", Vehicle.xmlSchemaSavegame)
	if v_u_179_ == nil then
		return "Error: Unable to create XML for saving vehicles"
	end
	simulatePhysics(false)
	self.isReloadRunning = true
	for _, v180_ in ipairs(v_u_167_) do
		self.vehicleByUniqueId[v180_:getUniqueId()] = nil
	end
	self:saveToXML(v_u_167_, v_u_179_, v169_)
	for _, v181_ in ipairs(v_u_167_) do
		v181_:removeFromPhysics()
	end
	local v_u_182_
	if g_localPlayer:getCurrentVehicle() == nil then
		v_u_182_ = nil
	else
		v_u_182_ = g_localPlayer:getCurrentVehicle():getUniqueId()
	end
	g_i3DManager:clearEntireSharedI3DFileCache(false)
	local function v_u_190_(_, p183_, p184_, _)
		-- upvalues: (copy) v_u_167_, (ref) v_u_182_, (copy) self, (copy) v_u_179_
		local v185_ = true
		if p184_ == VehicleLoadingState.OK then
			if #p183_ == #v_u_167_ then
				for _, v186_ in pairs(v_u_167_) do
					v186_:delete()
				end
				if v_u_182_ ~= nil then
					for _, v187_ in pairs(p183_) do
						if v187_:getUniqueId() == v_u_182_ then
							g_localPlayer:requestToEnterVehicle(v187_)
						end
					end
				end
			else
				Logging.error("Not all vehicles could be reloaded")
				v185_ = false
			end
		else
			Logging.error("Failed to load vehicles")
			v185_ = false
		end
		if not v185_ then
			for _, v188_ in pairs(p183_) do
				v188_:delete()
			end
			for _, v189_ in ipairs(v_u_167_) do
				v189_:addToPhysics()
				self.vehicleByUniqueId[v189_:getUniqueId()] = v189_
			end
		end
		v_u_179_:delete()
		self.isReloadRunning = false
		simulatePhysics(true)
		if v185_ then
			Logging.info("%d vehicle(s) reloaded", #v_u_167_)
		end
	end
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self, (copy) v_u_179_, (copy) v_u_190_, (ref) v_u_162_
		self:loadFromXMLFile(v_u_179_, v_u_190_, nil, nil, v_u_162_, true)
	end)
end

-- Local values: pallets, _, fillType, localPlayer, x, _, z, dirX, dirZ, _, fillType, palletFillType, bestMatch, xmlFilename, x, y, z, dirX, dirZ, yOffset, collisionMask, objectId, _, hitY, _, _, asyncCallbackFunction, farmId, data
function VehicleSystem:consoleCommandAddPallet(palletFillTypeName, amount, worldX, worldZ)
	local v196_ = {}
	for _, v197_ in pairs(g_fillTypeManager:getFillTypes()) do
		if v197_.palletFilename ~= nil then
			v196_[v197_.name] = v197_.palletFilename
		end
	end
	if palletFillTypeName == nil then
		Logging.error("Error: no fillType given")
		return
	else
		local v198_ = g_localPlayer
		if string.lower(palletFillTypeName) == "all" then
			local v199_, _, v200_ = v198_:getPosition()
			local v201_, v202_ = v198_:getCurrentFacingDirection()
			for _, v203_ in pairs(g_fillTypeManager:getFillTypes()) do
				if v203_.palletFilename ~= nil then
					v199_ = v199_ + v201_ * 3
					v200_ = v200_ + v202_ * 3
					self:consoleCommandAddPallet(v203_.name, amount, v199_, v200_)
				end
			end
			return
		else
			local v_u_204_ = string.upper(palletFillTypeName)
			local v_u_205_ = g_fillTypeManager:getFillTypeIndexByName(v_u_204_)
			if v_u_205_ == nil then
				Logging.error("Error: Invalid pallet fillType \'%s\'", v_u_204_)
				local v206_ = Utils.getClosestMatchingString(v_u_204_, table.toList(v196_))
				if v206_ ~= nil then
					print(string.format("Did you mean %q?", v206_))
				end
				return string.format("Valid types are %s", table.concatKeys(v196_, ", "))
			else
				local v207_ = v196_[v_u_204_]
				if v207_ == nil then
					Logging.error("Error: no pallet for given fillType \'%s\'", v_u_204_)
				else
					local v208_, v209_, v210_ = v198_:getPosition()
					local v211_, v212_ = v198_:getCurrentFacingDirection()
					local v213_ = v208_ + v211_ * 4
					local v214_ = v210_ + v212_ * 4
					local v215_ = tonumber(worldX) or v213_
					local v216_ = tonumber(worldZ) or v214_
					local v217_ = Platform.gameplay.hasDynamicPallets and 0.2 or 0
					local v218_ = CollisionFlag.STATIC_OBJECT + CollisionFlag.TERRAIN + CollisionFlag.TERRAIN_DELTA + CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE
					local v219_, _, v220_, _, _ = RaycastUtil.raycastClosest(v215_, v209_ + 25, v216_, 0, -1, 0, 40, v218_)
					if v219_ == nil then
						v220_ = getTerrainHeightAtWorldPos(g_terrainNode, v215_, v209_, v216_)
					end
					local v221_ = self.mission:getFarmId()
					local v222_ = (v221_ == FarmManager.SPECTATOR_FARM_ID or not v221_) and 1 or v221_
					local v223_ = VehicleLoadingData.new()
					v223_:setFilename(v207_)
					v223_:setPosition(v215_, v220_ + v217_, v216_)
					v223_:setPropertyState(VehiclePropertyState.OWNED)
					v223_:setOwnerFarmId(v222_)
					v223_:load(function(_, p224_, p225_, _)
						-- upvalues: (copy) amount, (copy) v_u_205_, (ref) v_u_204_
						if p225_ ~= VehicleLoadingState.OK then
							printError("Error: Failed to load pallet")
							return
						end
						local v226_ = p224_[1]
						local v227_ = v226_:getFillUnits()
						local v228_ = amount
						local v229_ = tonumber(v228_) or math.huge
						local v230_ = 0
						for _, v231_ in ipairs(v227_) do
							if v226_:getFillUnitSupportsFillType(v231_.fillUnitIndex, v_u_205_) then
								v230_ = v230_ + v226_:addFillUnitFillLevel(1, v231_.fillUnitIndex, v229_, v_u_205_, ToolType.UNDEFINED, nil)
								v229_ = v229_ - v230_
								if v229_ <= 0 then
									break
								end
							end
						end
						print(string.format("Loaded pallet with %dl of %s", v230_, v_u_204_))
					end)
				end
			end
		end
	end
end

-- Local values: vehicle, fillUnitIndex, fillLevel, delta
function VehicleSystem:consoleCommandSetFuel(fuelLevel)
	if not self.mission:getIsServer() then
		return "Not available on clients"
	end
	if fuelLevel == nil then
		return "No fuellevel given! Usage: gsVehicleFuelSet <fuelLevel>"
	end
	local v234_ = Utils.getNoNil(tonumber(fuelLevel), 10000000000)
	local v235_ = g_localPlayer:getCurrentVehicle()
	if v235_ == nil then
		return "Enter a vehicle first!"
	end
	if v235_.getConsumerFillUnitIndex == nil then
		return "Vehicle has no consumer"
	end
	local v236_ = v235_:getConsumerFillUnitIndex(FillType.DIESEL) or (v235_:getConsumerFillUnitIndex(FillType.ELECTRICCHARGE) or v235_:getConsumerFillUnitIndex(FillType.METHANE))
	if v236_ == nil then
		return "No Fuel filltype supported!"
	end
	local v237_ = v234_ - v235_:getFillUnitFillLevel(v236_)
	v235_:addFillUnitFillLevel(self.mission:getFarmId(), v236_, v237_, v235_:getFillUnitFirstSupportedFillType(v236_), ToolType.UNDEFINED, nil)
	return "Added fuel"
end

-- Local values: vehicle, spec
function VehicleSystem:consoleCommandSetMotorTemperature(temperature)
	if not self.mission:getIsServer() then
		return "Not available on clients"
	end
	if temperature == nil then
		return "No temperature given! Usage: gsVehicleTemperatureSet <temperature>"
	end
	local v240_ = Utils.getNoNil(tonumber(temperature), 0)
	local v241_ = g_localPlayer:getCurrentVehicle()
	if v241_ == nil then
		return "Enter a vehicle first!"
	end
	local v242_ = v241_.spec_motorized
	if v242_ == nil then
		return "Vehicle has no motor"
	end
	local v243_ = v242_.motorTemperature
	local v244_ = v242_.motorTemperature.valueMin
	local v245_ = v242_.motorTemperature.valueMax
	v243_.value = math.clamp(v240_, v244_, v245_)
	return "Set motor temperature to " .. v242_.motorTemperature.value
end

-- Local values: usage, mission, player, controlledVehicle, fillableVehicle, selectedObject, targetNode, object, farmId, getSupportedFilltypesString, fillTypeIndex, capacity, fillUnitSupportsFillType, fillLevel
function VehicleSystem:consoleCommandFillUnitAdd(fillUnitIndex, fillTypeName, amount)
	local v250_ = self.mission
	local v251_ = g_localPlayer
	local v252_ = v251_:getCurrentVehicle()
	local v253_ = nil
	if v252_ ~= nil and v252_.getSelectedObject ~= nil then
		local v254_ = v252_:getSelectedObject()
		if v254_ ~= nil and v254_.vehicle.addFillUnitFillLevel ~= nil then
			v253_ = v254_.vehicle
		end
	end
	if v253_ ~= nil or (v252_ == nil or v252_.addFillUnitFillLevel == nil) then
		v252_ = v253_
	end
	local v_u_255_
	if v252_ == nil then
		v_u_255_ = v250_:getNodeObject((v251_.targeter:getClosestTargetedNodeFromType(PlayerInputComponent)))
		if v_u_255_ == nil or (not v_u_255_:isa(Vehicle) or v_u_255_.addFillUnitFillLevel == nil) then
			v_u_255_ = v252_
		end
	else
		v_u_255_ = v252_
	end
	local v256_ = v250_:getFarmId()
	if v_u_255_ == nil or v_u_255_.getFillUnitSupportedToolTypes == nil then
		return "Error: could not find a fillable vehicle!"
	else
		local function v263_()
			-- upvalues: (ref) v_u_255_
			local v257_ = {}
			for v258_, v259_ in pairs(v_u_255_:debugGetSupportedFillTypesPerFillUnit()) do
				local v260_ = string.format
				local v261_ = table.concat
				local v262_ = g_fillTypeManager:getFillTypeNamesByIndices(v259_)
				table.insert(v257_, v260_("FillUnit %d - FillTypes: %s", v258_, v261_(v262_, " ")))
			end
			return "Available FillUnits and supported FillTypes:\n" .. table.concat(v257_, "\n")
		end
		if fillUnitIndex == nil or fillTypeName == nil then
			return "Error: Missing parameters.\nUsage: \'gsFillUnitAdd <fillUnitIndex> <fillTypeName> [amount]\'"
		elseif v250_:getIsServer() then
			local v264_ = tonumber(fillUnitIndex)
			local v265_ = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
			local v266_ = tonumber(amount)
			if v264_ == nil then
				return "Error: Missing fillUnitIndex!\nUsage: \'gsFillUnitAdd <fillUnitIndex> <fillTypeName> [amount]\'"
			elseif v_u_255_:getFillUnitExists(v264_) then
				if v265_ == nil then
					Logging.error("Unknown fillType \'%s\'!\n%s", fillTypeName, (v263_()))
					return
				else
					local v267_ = v_u_255_:getFillUnitCapacity(v264_)
					if v267_ == 0 then
						Logging.error("Selected Vehicle \'%s\' cannot be filled. Capacity is 0!", v_u_255_:getName())
					else
						if v_u_255_:getFillUnitSupportsFillType(v264_, v265_) then
							local v268_ = v266_ or v267_
							if v268_ == 0 then
								v268_ = -v267_
							end
							v_u_255_:addFillUnitFillLevel(v256_, v264_, v268_, v265_, ToolType.UNDEFINED)
							local v269_ = v_u_255_:getFillUnitFillLevel(v264_)
							local v270_ = v_u_255_:getFillUnitFillType(v264_)
							local v271_ = Utils.getNoNil(g_fillTypeManager:getFillTypeNameByIndex(v270_), "unknown")
							return string.format("new fillLevel: %.1f, fillType: %d (%s)", v269_, v270_, v271_)
						end
						Logging.error("fillUnit \'%d\' in \'%s\' does not support fillType \'%s\'\n%s", v264_, v_u_255_:getName(), fillTypeName, (v263_()))
					end
				end
			else
				Logging.error("FillUnit \'%d\' in \'%s\' does not exist!\n%s", v264_, v_u_255_:getName(), (v263_()))
				return
			end
		else
			return "Error: \'gsFillUnitAdd\' can only be called on server side!"
		end
	end
end

-- Local values: controlledVehicle
function VehicleSystem:consoleCommandSetOperatingTime(operatingTime)
	if not self.mission:getIsServer() then
		return "Not available on clients"
	end
	if operatingTime == nil then
		return "No operatingTime given! Usage: gsVehicleOperatingTimeSet <operatingTime (h)>"
	end
	local v274_ = (tonumber(operatingTime) or 0) * 1000 * 60 * 60
	local v275_ = g_localPlayer:getCurrentVehicle()
	if v275_ == nil then
		return "Enter a vehicle first!"
	end
	if v275_.setOperatingTime == nil then
		return "Vehicle has no operating time"
	end
	v275_:setOperatingTime(v274_)
	return string.format("Set operating time to %.1f", v274_)
end

-- Local values: controlledVehicle, _, vehicle, prevDirtAmount
function VehicleSystem:consoleCommandAddDirtAmount(amount)
	if not self.mission:getIsServer() then
		return "Error: Not available on clients"
	end
	local v278_ = tonumber(amount) or 0
	local v279_ = g_localPlayer:getCurrentVehicle()
	if v279_ == nil then
		return "Error: Enter a vehicle first!"
	end
	for _, v280_ in pairs(v279_.rootVehicle.childVehicles) do
		if v280_.setDirtAmount ~= nil then
			local v281_ = v280_:getDirtAmount()
			v280_:setDirtAmount(v281_ + v278_)
			Logging.info("Set dirt amount of vehicle \'%s\' from %.2f to %.2f", v280_:getName(), v281_, v280_:getDirtAmount())
		end
	end
end

-- Local values: controlledVehicle, _, vehicle
function VehicleSystem:consoleCommandAddWearAmount(amount)
	if not self.mission:getIsServer() then
		return "Error: Not available on clients"
	end
	local v284_ = tonumber(amount) or 0
	local v285_ = g_localPlayer:getCurrentVehicle()
	if v285_ == nil then
		return "Error: Enter a vehicle first!"
	end
	for _, v286_ in pairs(v285_.rootVehicle.childVehicles) do
		if v286_.addWearAmount ~= nil then
			v286_:addWearAmount(v284_)
		end
	end
	return string.format("Added wear to vehicles (Amount: %.2f)", v284_)
end

-- Local values: controlledVehicle, _, vehicle
function VehicleSystem:consoleCommandAddWetnessAmount(amount)
	if not self.mission:getIsServer() then
		return "Error: Not available on clients"
	end
	local v289_ = tonumber(amount) or 0
	local v290_ = g_localPlayer:getCurrentVehicle()
	if v290_ == nil then
		return "Error: Enter a vehicle first!"
	end
	for _, v291_ in pairs(v290_.rootVehicle.childVehicles) do
		if v291_.addWetnessAmount ~= nil then
			v291_:addWetnessAmount(v289_)
		end
	end
	return string.format("Added wetness to vehicles (Amount: %.2f)", v289_)
end

-- Local values: controlledVehicle, _, vehicle
function VehicleSystem:consoleCommandAddDamageAmount(amount)
	if not self.mission:getIsServer() then
		return "Error: Not available on clients"
	end
	local v294_ = tonumber(amount) or 0
	local v295_ = g_localPlayer:getCurrentVehicle()
	if v295_ == nil then
		return "Error: Enter a vehicle first!"
	end
	for _, v296_ in pairs(v295_.rootVehicle.childVehicles) do
		if v296_.addDamageAmount ~= nil then
			v296_:addDamageAmount(v294_)
		end
	end
	return string.format("Added damage to vehicles (Amount: %.2f)", v294_)
end

-- Local values: _, storeItem, defaultConfigs, defaultSetIndex, i, name, index, name, configItems, includedInSet, i, configSet, usedAsDependentConfig, _, otherConfigItems, _, otherConfigItem, _, dependentConfig, _, configItem, i, configSet, configs, configs, i, configSet, configs, name, index, _, fillType, storeItem, modStr
function VehicleSystem:consoleCommandLoadAllVehicles(loadConfigs, modsOnly, palletsOnly, verbose)
	if not self.mission:getIsServer() and self.mission.missionDynamicInfo.isMultiplayer then
		return "Error: Command not allowed in multiplayer"
	end
	if self.debugVehiclesToBeLoaded ~= nil then
		return "Error: Loading task is currently running!"
	end
	local v302_ = string.lower(loadConfigs or "false") == "true"
	local v303_ = string.lower(modsOnly or "false") == "true"
	local v304_ = string.lower(palletsOnly or "false") == "true"
	local v305_ = string.lower(verbose or "false") == "true"
	self.debugVehiclesToBeLoaded = {}
	self.debugVehiclesLoaded = {}
	self.debugVehiclesTotal = 0
	self.debugVehiclesToBeLoadedStartTime = g_time
	I3DManager.VERBOSE_LOADING = v305_
	if v304_ then
		for _, v306_ in pairs(g_fillTypeManager:getFillTypes()) do
			if v306_.palletFilename ~= nil then
				local v307_ = g_storeManager:getItemByXMLFilename(v306_.palletFilename)
				local v308_ = self.debugVehiclesToBeLoaded
				table.insert(v308_, {
					["storeItem"] = v307_,
					["configurations"] = {}
				})
			end
		end
	else
		for _, v309_ in pairs(g_storeManager:getItems()) do
			if StoreItemUtil.getIsVehicle(v309_) and (not v303_ or (v309_.isMod or v309_.dlcTitle ~= "")) then
				local v310_ = v309_.defaultConfigurationIds == nil and {} or table.clone(v309_.defaultConfigurationIds)
				if #v309_.configurationSets > 0 then
					local v311_ = 1
					for v312_ = 1, #v309_.configurationSets do
						if v309_.configurationSets[v312_].isDefault then
							v311_ = v312_
							break
						end
					end
					for v313_, v314_ in pairs(v309_.configurationSets[v311_].configurations) do
						v310_[v313_] = v314_
					end
				end
				local v315_ = self.debugVehiclesToBeLoaded
				table.insert(v315_, {
					["storeItem"] = v309_,
					["configurations"] = v310_
				})
				self.debugVehiclesTotal = self.debugVehiclesTotal + 1
				if v302_ then
					if v309_.configurations ~= nil then
						for v316_, v317_ in pairs(v309_.configurations) do
							if #v317_ > 1 then
								local v318_ = false
								for v319_ = 1, #v309_.configurationSets do
									if v309_.configurationSets[v319_].configurations[v316_] ~= nil then
										v318_ = true
										break
									end
								end
								local v320_ = false
								if not v318_ then
									for _, v321_ in pairs(v309_.configurations) do
										for _, v322_ in ipairs(v321_) do
											if v322_.dependentConfigurations ~= nil then
												for _, v323_ in ipairs(v322_.dependentConfigurations) do
													if v323_.name == v316_ then
														v320_ = true
														break
													end
												end
											end
										end
									end
								end
								if not (v318_ or v320_) then
									for _, v324_ in ipairs(v317_) do
										if v324_.isSelectable then
											if #v309_.configurationSets > 0 then
												for v325_ = 1, #v309_.configurationSets do
													local v326_ = v309_.configurationSets[v325_]
													local v327_ = table.clone(v326_.configurations)
													v327_[v316_] = v324_.index
													local v328_ = self.debugVehiclesToBeLoaded
													table.insert(v328_, {
														["storeItem"] = v309_,
														["configurations"] = v327_
													})
												end
											else
												local v329_ = {
													[v316_] = v324_.index
												}
												local v330_ = self.debugVehiclesToBeLoaded
												table.insert(v330_, {
													["storeItem"] = v309_,
													["configurations"] = v329_
												})
											end
										end
									end
								end
							end
						end
					end
					for v331_ = 1, #v309_.configurationSets do
						local v332_ = v309_.configurationSets[v331_]
						local v333_ = {}
						for v334_, v335_ in pairs(v332_.configurations) do
							v333_[v334_] = v335_
						end
						local v336_ = self.debugVehiclesToBeLoaded
						table.insert(v336_, {
							["storeItem"] = v309_,
							["configurations"] = v333_
						})
					end
				end
			end
		end
	end
	self.debugVehiclesTotalConfigs = #self.debugVehiclesToBeLoaded
	local v337_ = v303_ and "mod " or ""
	if v302_ then
		return print(string.format("Loading %i %svehicles with all configs...", self.debugVehiclesTotal, v337_))
	else
		return print(string.format("Loading %i %svehicles (add first param \'true\' to include configs, add second param \'true\' to only load mods, add third param \'true\' to only load pallets, add fourth param \'verbose\' to print i3d loading messages)...", self.debugVehiclesTotal, v337_))
	end
end

-- Local values: i, vehicle, vehicleData, totalTime, _, vehicle, configString, name, index, asyncCallbackFunction, data, localPlayer, x, y, z, dirX, dirZ
function VehicleSystem:consoleCommandLoadAllVehiclesNext()
	if self.debugVehiclesLoaded ~= nil then
		for v339_ = #self.debugVehiclesLoaded, 1, -1 do
			local v340_ = self.debugVehiclesLoaded[v339_]
			v340_.deleteFrameCounter = v340_.deleteFrameCounter - 1
			if v340_.deleteFrameCounter <= 0 then
				v340_:delete()
				table.remove(self.debugVehiclesLoaded, v339_)
			end
		end
	end
	if self.debugVehiclesToBeLoaded == nil then
		return
	elseif self.debugVehiclesLoadingCount == nil or self.debugVehiclesLoadingCount <= 0 then
		if not self.debugVehiclesLoading then
			local v341_ = table.remove(self.debugVehiclesToBeLoaded, 1)
			if v341_ == nil then
				local v342_ = g_time - self.debugVehiclesToBeLoadedStartTime
				print(string.format("Successfully loaded and removed all vehicles in %.1f seconds!", v342_ / 1000))
				self.debugVehiclesToBeLoaded = nil
				self.debugVehiclesLoadingCount = nil
				for _, v343_ in pairs(self.debugVehiclesLoaded) do
					v343_:delete()
				end
				self.debugVehiclesLoaded = {}
				I3DManager.VERBOSE_LOADING = true
				return
			end
			local v344_
			if next(v341_.configurations) == nil then
				v344_ = "None"
			else
				v344_ = ""
				for v345_, v346_ in pairs(v341_.configurations) do
					if v344_ ~= "" then
						v344_ = v344_ .. ", "
					end
					v344_ = v344_ .. string.format("%s:%d", v345_, v346_)
				end
			end
			Logging.info("Loading vehicle %d/%d: %s (Configuration: %s)", self.debugVehiclesTotalConfigs - #self.debugVehiclesToBeLoaded, self.debugVehiclesTotalConfigs, v341_.storeItem.xmlFilename, v344_)
			local v347_ = VehicleLoadingData.new()
			local v348_ = g_localPlayer
			local v349_, v350_, v351_ = v348_:getPosition()
			local v352_, v353_ = v348_:getCurrentFacingDirection()
			v347_:setPosition(v349_ + v352_ * 10, v350_, v351_ + v353_ * 10)
			v347_:setStoreItem(v341_.storeItem)
			v347_:setConfigurations(v341_.configurations)
			v347_:setIsRegistered(false)
			v347_:setIsSaved(false)
			self.debugVehiclesLoading = true
			v347_:load(function(_, p354_, _, _)
				-- upvalues: (copy) self
				self.debugVehiclesLoading = false
				for _, v355_ in pairs(p354_) do
					v355_:removeFromPhysics()
					local v356_ = self.debugVehiclesLoaded
					table.insert(v356_, v355_)
					v355_.deleteFrameCounter = 2
				end
			end, nil, nil)
		end
	end
end

-- Local values: numDeleted, i, vehicle
function VehicleSystem:consoleCommandVehicleRemoveAll()
	local v358_ = 0
	for v359_ = #self.vehicles, 1, -1 do
		local v360_ = self.vehicles[v359_]
		if v360_.trainSystem == nil and not v360_.isPallet then
			v360_:delete()
			v358_ = v358_ + 1
		end
	end
	return string.format("Deleted %i vehicle(s)! Excluded train and pallets", v358_)
end

function VehicleSystem:consoleCommandVehicleToggleRandomFail()
	Vehicle.DEBUG_RANDOM_FAIL_LOADING = not Vehicle.DEBUG_RANDOM_FAIL_LOADING
	return string.format("Vehicle.DEBUG_RANDOM_FAIL_LOADING: %s", Vehicle.DEBUG_RANDOM_FAIL_LOADING)
end

-- Local values: rootVehicles, _, v, rootVehicle, addVehicle, vehicleSetIndex, _, vehicle, xmlFile, key, children, vehicleIndex, childToIndex, k, childVehicle, vehicleKey, attacherIndex, k, child, attacherVehicle, attachKey, rootVehicleIndex, attachVehicleIndex, implement, inputAttacherJointIndex, xmlString
function VehicleSystem:consoleCommandExportVehicleSets()
	local v362_ = {}
	for _, v363_ in ipairs(self.vehicles) do
		local v364_ = v363_:getRootVehicle()
		if v364_ ~= nil then
			v362_[v364_] = v364_
		end
	end
	setFileLogPrefixTimestamp(false)
	local function v377_(p365_, p366_, p367_, p368_)
		setXMLString(p365_, p366_ .. ".xmlFilename", p367_.configFileName)
		setXMLFloat(p365_, p366_ .. ".rotY", 0)
		setXMLFloat(p365_, p366_ .. ".captainFoldingState", 0)
		local v369_, v370_, v371_ = localToLocal(p367_.rootNode, p368_.rootNode, 0, 0, 0)
		setXMLString(p365_, p366_ .. ".offset", string.format("%.2f %.2f %.2f", v369_, v370_, v371_))
		local v372_ = 0
		for v373_, v374_ in pairs(p367_.configurations) do
			local v375_ = ConfigurationUtil.getSaveIdByConfigId(p367_.configFileName, v373_, v374_)
			if v375_ ~= nil then
				local v376_ = string.format("%s.configurations.configuration(%d)", p366_, v372_)
				setXMLString(p365_, v376_ .. "#name", v373_)
				setXMLString(p365_, v376_ .. "#id", v375_)
				v372_ = v372_ + 1
			end
		end
	end
	for _, v378_ in pairs(v362_) do
		local v379_ = loadXMLFileFromMemory("vehicleSets", "<vehicleSets></vehicleSets>")
		local v380_ = string.format("vehicleSets.vehicleSet(%d)", 0)
		local v381_ = v378_:getChildVehicles()
		local v382_ = 0
		local v383_ = {}
		for v384_ = #v381_, 1, -1 do
			local v385_ = v381_[v384_]
			v377_(v379_, string.format("%s.vehicle(%d)", v380_, v382_), v385_, v378_)
			v382_ = v382_ + 1
			v383_[v385_] = v382_
		end
		local v386_ = 0
		for v387_ = #v381_, 1, -1 do
			local v388_ = v381_[v387_]
			local v389_
			if v388_.getAttacherVehicle == nil then
				v389_ = nil
			else
				v389_ = v388_:getAttacherVehicle()
			end
			if v389_ ~= nil then
				local v390_ = string.format("%s.attach(%d)", v380_, v386_)
				local v391_ = v383_[v389_]
				local v392_ = v383_[v388_]
				local v393_ = v389_:getImplementByObject(v388_)
				local v394_ = v388_:getActiveInputAttacherJointDescIndex()
				setXMLInt(v379_, v390_ .. "#element0", v391_)
				setXMLInt(v379_, v390_ .. "#element1", v392_)
				setXMLInt(v379_, v390_ .. "#attacherJointIndex", v393_.jointDescIndex)
				setXMLInt(v379_, v390_ .. "#inputAttacherJointIndex", v394_)
				v386_ = v386_ + 1
			end
		end
		local v395_ = saveXMLFileToMemory(v379_)
		print(v395_)
		delete(v379_)
	end
	setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
end
