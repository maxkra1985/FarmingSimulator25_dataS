LivestockTrailer = {}
source("dataS/scripts/vehicles/specializations/activatables/LivestockTrailerActivatable.lua")
function LivestockTrailer.initSpecialization()
	g_storeManager:addSpecType("numAnimalsCow", "shopListAttributeIconCow", LivestockTrailer.loadSpecValueNumberAnimalsCow, LivestockTrailer.getSpecValueNumberAnimalsCow, StoreSpecies.VEHICLE)
	g_storeManager:addSpecType("numAnimalsPig", "shopListAttributeIconPig", LivestockTrailer.loadSpecValueNumberAnimalsPig, LivestockTrailer.getSpecValueNumberAnimalsPig, StoreSpecies.VEHICLE)
	g_storeManager:addSpecType("numAnimalsSheep", "shopListAttributeIconSheep", LivestockTrailer.loadSpecValueNumberAnimalsSheep, LivestockTrailer.getSpecValueNumberAnimalsSheep, StoreSpecies.VEHICLE)
	g_storeManager:addSpecType("numAnimalsHorse", "shopListAttributeIconHorse", LivestockTrailer.loadSpecValueNumberAnimalsHorse, LivestockTrailer.getSpecValueNumberAnimalsHorse, StoreSpecies.VEHICLE)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("LivestockTrailer")
	v1_:register(XMLValueType.STRING, "vehicle.livestockTrailer.animal(?)#type", "Animal type name")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.livestockTrailer.animal(?)#node", "Animal node")
	v1_:register(XMLValueType.INT, "vehicle.livestockTrailer.animal(?)#numSlots", "Number of slots")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.livestockTrailer.loadTrigger#node", "Load trigger node")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.livestockTrailer.spawnPlaces.spawnPlace(?)#node", "Unload spawn places")
	v1_:register(XMLValueType.FLOAT, "vehicle.livestockTrailer.spawnPlaces.spawnPlace(?)#width", "Unloading width", 15)
	v1_:setXMLSpecializationType()
	local v2_ = Vehicle.xmlSchemaSavegame
	v2_:register(XMLValueType.STRING, "vehicles.vehicle(?).livestockTrailer#animalType", "Animal type name")
	AnimalClusterSystem.registerSavegameXMLPaths(v2_, "vehicles.vehicle(?).livestockTrailer")
end

function LivestockTrailer.prerequisitesPresent(specializations)
	return true
end

function LivestockTrailer.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentAnimalType", LivestockTrailer.getCurrentAnimalType)
	SpecializationUtil.registerFunction(vehicleType, "getSupportsAnimalType", LivestockTrailer.getSupportsAnimalType)
	SpecializationUtil.registerFunction(vehicleType, "getSupportsAnimalSubType", LivestockTrailer.getSupportsAnimalSubType)
	SpecializationUtil.registerFunction(vehicleType, "setLoadingTrigger", LivestockTrailer.setLoadingTrigger)
	SpecializationUtil.registerFunction(vehicleType, "getLoadingTrigger", LivestockTrailer.getLoadingTrigger)
	SpecializationUtil.registerFunction(vehicleType, "updateAnimals", LivestockTrailer.updateAnimals)
	SpecializationUtil.registerFunction(vehicleType, "updatedClusters", LivestockTrailer.updatedClusters)
	SpecializationUtil.registerFunction(vehicleType, "clearAnimals", LivestockTrailer.clearAnimals)
	SpecializationUtil.registerFunction(vehicleType, "addAnimals", LivestockTrailer.addAnimals)
	SpecializationUtil.registerFunction(vehicleType, "addCluster", LivestockTrailer.addCluster)
	SpecializationUtil.registerFunction(vehicleType, "getClusters", LivestockTrailer.getClusters)
	SpecializationUtil.registerFunction(vehicleType, "getRideablesInTrigger", LivestockTrailer.getRideablesInTrigger)
	SpecializationUtil.registerFunction(vehicleType, "getClusterById", LivestockTrailer.getClusterById)
	SpecializationUtil.registerFunction(vehicleType, "getClusterSystem", LivestockTrailer.getClusterSystem)
	SpecializationUtil.registerFunction(vehicleType, "getNumOfAnimals", LivestockTrailer.getNumOfAnimals)
	SpecializationUtil.registerFunction(vehicleType, "getMaxNumOfAnimals", LivestockTrailer.getMaxNumOfAnimals)
	SpecializationUtil.registerFunction(vehicleType, "getNumOfFreeAnimalSlots", LivestockTrailer.getNumOfFreeAnimalSlots)
	SpecializationUtil.registerFunction(vehicleType, "onAnimalLoaded", LivestockTrailer.onAnimalLoaded)
	SpecializationUtil.registerFunction(vehicleType, "onAnimalLoadTriggerCallback", LivestockTrailer.onAnimalLoadTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "getAnimalUnloadPlaces", LivestockTrailer.getAnimalUnloadPlaces)
	SpecializationUtil.registerFunction(vehicleType, "setAnimalScreenController", LivestockTrailer.setAnimalScreenController)
	SpecializationUtil.registerFunction(vehicleType, "onAnimalRideableDeleted", LivestockTrailer.onAnimalRideableDeleted)
end

function LivestockTrailer.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAdditionalComponentMass", LivestockTrailer.getAdditionalComponentMass)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSellPrice", LivestockTrailer.getSellPrice)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "dayChanged", LivestockTrailer.dayChanged)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "periodChanged", LivestockTrailer.periodChanged)
end

function LivestockTrailer.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", LivestockTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", LivestockTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", LivestockTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", LivestockTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", LivestockTrailer)
end

-- Local values: spec, i, key, place, animalTypeStr, animalTypeIndex, parent, numSlots, j, slotNode, trigger
function LivestockTrailer:onLoad(savegame)
	local v_u_7_ = self.spec_livestockTrailer
	v_u_7_.animalPlaces = {}
	v_u_7_.animalTypeIndexToPlaces = {}
	local v8_ = 0
	while true do
		local v9_ = string.format("vehicle.livestockTrailer.animal(%d)", v8_)
		if not self.xmlFile:hasProperty(v9_) then
			break
		end
		local v10_ = {
			["numUsed"] = 0
		}
		local v11_ = self.xmlFile:getValue(v9_ .. "#type")
		local v12_ = g_currentMission.animalSystem:getTypeIndexByName(v11_)
		if v12_ == nil then
			Logging.xmlWarning(self.xmlFile, "Animal type \'%s\' could not be found!", v11_)
			break
		end
		v10_.animalTypeIndex = v12_
		v10_.slots = {}
		local v13_ = self.xmlFile:getValue(v9_ .. "#node", nil, self.components, self.i3dMappings)
		local v14_ = self.xmlFile:getValue(v9_ .. "#numSlots", 0)
		local v15_ = math.abs(v14_)
		if getNumOfChildren(v13_) < v15_ then
			Logging.xmlWarning(self.xmlFile, "numSlots is greater than available children for \'%s\'", v9_)
			v15_ = getNumOfChildren(v13_)
		end
		for v16_ = 0, v15_ - 1 do
			local v17_ = getChildAt(v13_, v16_)
			local v18_ = v10_.slots
			table.insert(v18_, {
				["linkNode"] = v17_,
				["loadedMesh"] = nil,
				["place"] = v10_
			})
		end
		local v19_ = v_u_7_.animalPlaces
		table.insert(v19_, v10_)
		v_u_7_.animalTypeIndexToPlaces[v10_.animalTypeIndex] = v10_
		v8_ = v8_ + 1
	end
	local v20_ = self.xmlFile:getValue("vehicle.livestockTrailer.loadTrigger#node", nil, self.components, self.i3dMappings)
	if v20_ ~= nil then
		addTrigger(v20_, "onAnimalLoadTriggerCallback", self)
		v_u_7_.triggerNode = v20_
	end
	v_u_7_.rideablesInTrigger = {}
	v_u_7_.spawnPlaces = {}
	self.xmlFile:iterate("vehicle.livestockTrailer.spawnPlaces.spawnPlace", function(_, p21_)
		-- upvalues: (copy) self, (copy) v_u_7_
		local v22_ = self.xmlFile:getValue(p21_ .. "#node", nil, self.components, self.i3dMappings)
		local v23_ = self.xmlFile:getValue(p21_ .. "#width", 5)
		if v22_ ~= nil then
			local v24_ = v_u_7_.spawnPlaces
			table.insert(v24_, {
				["node"] = v22_,
				["width"] = v23_
			})
		end
	end)
	if #v_u_7_.spawnPlaces > 0 or v_u_7_.triggerNode ~= nil then
		v_u_7_.activatable = LivestockTrailerActivatable.new(self)
		if g_currentMission ~= nil then
			g_currentMission.activatableObjectsSystem:addActivatable(v_u_7_.activatable)
		end
	end
	v_u_7_.clusterSystem = AnimalClusterSystem.new(self.isServer, self)
	g_messageCenter:subscribe(AnimalClusterUpdateEvent, self.updatedClusters, self)
	v_u_7_.loadingTrigger = nil
	v_u_7_.animalScreenController = nil
	if g_currentMission ~= nil then
		g_currentMission.husbandrySystem:addLivestockTrailer(self)
	end
end

-- Local values: spec, xmlFile, key
function LivestockTrailer:onLoadFinished(savegame)
	if savegame ~= nil and not savegame.resetVehicles then
		local v27_ = self.spec_livestockTrailer
		local v28_ = savegame.xmlFile
		local v29_ = savegame.key
		v27_.clusterSystem:loadFromXMLFile(v28_, v29_ .. ".livestockTrailer")
		v27_.clusterSystem:updateNow()
	end
end

-- Local values: spec, _, vehicle
function LivestockTrailer:onDelete()
	self:clearAnimals()
	g_messageCenter:unsubscribe(AnimalClusterUpdateEvent, self)
	if g_currentMission ~= nil then
		g_currentMission.husbandrySystem:removeLivestockTrailer(self)
	end
	local v31_ = self.spec_livestockTrailer
	if v31_.triggerNode ~= nil then
		removeTrigger(v31_.triggerNode)
	end
	if v31_.activatable ~= nil then
		g_currentMission.activatableObjectsSystem:removeActivatable(v31_.activatable)
	end
	if v31_.rideablesInTrigger ~= nil then
		for _, v32_ in ipairs(v31_.rideablesInTrigger) do
			v32_:removeDeleteListener(self, "onAnimalRideableDeleted")
		end
		table.clear(v31_.rideablesInTrigger)
	end
	if v31_.loadingTrigger ~= nil then
		v31_.loadingTrigger:setLoadingTrailer(nil)
		v31_.loadingTrigger = nil
	end
end

-- Local values: spec
function LivestockTrailer:saveToXMLFile(xmlFile, key, usedModNames)
	self.spec_livestockTrailer.clusterSystem:saveToXMLFile(xmlFile, key, usedModNames)
end

-- Local values: spec
function LivestockTrailer:onReadStream(streamId, connection)
	self.spec_livestockTrailer.clusterSystem:readStream(streamId, connection)
end

-- Local values: spec
function LivestockTrailer:onWriteStream(streamId, connection)
	self.spec_livestockTrailer.clusterSystem:writeStream(streamId, connection)
end

function LivestockTrailer:getSupportsAnimalType(animalTypeIndex)
	return self.spec_livestockTrailer.animalTypeIndexToPlaces[animalTypeIndex] ~= nil
end

-- Local values: animalSystem, subType, animalType
function LivestockTrailer:getSupportsAnimalSubType(subTypeIndex)
	local v47_ = g_currentMission.animalSystem
	return self:getSupportsAnimalType(v47_:getTypeByIndex(v47_:getSubTypeByIndex(subTypeIndex).typeIndex).typeIndex)
end

-- Local values: spec, clusters, animalSystem, subTypeIndex, subType, animalType
function LivestockTrailer:getCurrentAnimalType()
	local v49_ = self.spec_livestockTrailer.clusterSystem:getClusters()
	if #v49_ == 0 then
		return nil
	end
	local v50_ = g_currentMission.animalSystem
	return v50_:getTypeByIndex(v50_:getSubTypeByIndex((v49_[1]:getSubTypeIndex())).typeIndex)
end

function LivestockTrailer:setLoadingTrigger(trigger)
	self.spec_livestockTrailer.loadingTrigger = trigger
end

function LivestockTrailer:getLoadingTrigger()
	return self.spec_livestockTrailer.loadingTrigger
end

function LivestockTrailer:setAnimalScreenController(controller)
	self.spec_livestockTrailer.animalScreenController = controller
end

-- Local values: cluster, i
function LivestockTrailer:addAnimals(subTypeIndex, numAnimals, age)
	local v60_ = g_currentMission.animalSystem:createClusterFromSubTypeIndex(subTypeIndex)
	if v60_:getSupportsMerging() then
		v60_.numAnimals = numAnimals
		v60_.age = age
		self:addCluster(v60_)
	else
		for v61_ = 1, numAnimals do
			if v61_ > 1 then
				v60_ = g_currentMission.animalSystem:createClusterFromSubTypeIndex(subTypeIndex)
			end
			v60_.numAnimals = 1
			v60_.age = age
			self:addCluster(v60_)
		end
	end
end

-- Local values: spec
function LivestockTrailer:addCluster(cluster)
	local v64_ = self.spec_livestockTrailer
	v64_.clusterSystem:addPendingAddCluster(cluster)
	v64_.clusterSystem:updateNow()
end

-- Local values: spec
function LivestockTrailer:getClusters()
	return self.spec_livestockTrailer.clusterSystem:getClusters()
end

-- Local values: spec
function LivestockTrailer:getRideablesInTrigger()
	return self.spec_livestockTrailer.rideablesInTrigger
end

-- Local values: spec
function LivestockTrailer:getClusterById(id)
	return self.spec_livestockTrailer.clusterSystem:getClusterById(id)
end

-- Local values: spec
function LivestockTrailer:getClusterSystem()
	return self.spec_livestockTrailer.clusterSystem
end

-- Local values: spec, clusters, subTypeIndex, subType, place
function LivestockTrailer:getNumOfAnimals()
	local v71_ = self.spec_livestockTrailer
	local v72_ = v71_.clusterSystem:getClusters()
	if #v72_ == 0 then
		return 0
	end
	local v73_ = v72_[1]:getSubTypeIndex()
	local v74_ = g_currentMission.animalSystem:getSubTypeByIndex(v73_)
	return v71_.animalTypeIndexToPlaces[v74_.typeIndex].usedSlots or 0
end

-- Local values: spec, currentAnimalType, place
function LivestockTrailer:getMaxNumOfAnimals(animalType)
	local v77_ = self.spec_livestockTrailer
	local v78_ = self:getCurrentAnimalType()
	if animalType == nil and v78_ == nil then
		return 0
	end
	if v78_ ~= nil and animalType ~= v78_ then
		return 0
	end
	local v79_ = animalType or v78_
	return self:getSupportsAnimalType(v79_.typeIndex) and #v77_.animalTypeIndexToPlaces[v79_.typeIndex].slots or 0
end

-- Local values: animalSystem, subType, animalType, used, total
function LivestockTrailer:getNumOfFreeAnimalSlots(subTypeIndex)
	local v82_ = g_currentMission.animalSystem
	local v83_ = v82_:getTypeByIndex(v82_:getSubTypeByIndex(subTypeIndex).typeIndex)
	local v84_ = self:getNumOfAnimals()
	return self:getMaxNumOfAnimals(v83_) - v84_
end

function LivestockTrailer:updatedClusters(trailer)
	if trailer == self then
		self:updateAnimals()
		self:setMassDirty()
	end
end

-- Local values: spec, slotIndex, clusters, animalType, place, _, cluster, i, slot, visual, filename, arguments, sharedLoadRequestId
function LivestockTrailer:updateAnimals()
	local v88_ = self.spec_livestockTrailer
	self:clearAnimals()
	local v89_ = 1
	local v90_ = v88_.clusterSystem:getClusters()
	local v91_ = self:getCurrentAnimalType()
	if v91_ ~= nil then
		local v92_ = v88_.animalTypeIndexToPlaces[v91_.typeIndex]
		v92_.usedSlots = 0
		for _, v93_ in ipairs(v90_) do
			for _ = 1, v93_:getNumAnimals() do
				local v94_ = v92_.slots[v89_]
				v94_.meshLoadingInProgress = true
				local v95_ = g_currentMission.animalSystem:getVisualByAge(v93_:getSubTypeIndex(), v93_:getAge())
				local v96_ = v95_.visualAnimal.filenamePosed
				v94_.filename = v96_
				v94_.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(v96_, false, false, self.onAnimalLoaded, self, {
					["slot"] = v94_,
					["visual"] = v95_
				})
				v89_ = v89_ + 1
				v92_.usedSlots = v92_.usedSlots + 1
			end
		end
	end
end

-- Local values: spec, _, place, _, slot
function LivestockTrailer:clearAnimals()
	local v98_ = self.spec_livestockTrailer
	if v98_.animalTypeIndexToPlaces ~= nil then
		for _, v99_ in pairs(v98_.animalTypeIndexToPlaces) do
			for _, v100_ in ipairs(v99_.slots) do
				if v100_.sharedLoadRequestId ~= nil then
					g_i3DManager:releaseSharedI3DFile(v100_.sharedLoadRequestId)
					v100_.sharedLoadRequestId = nil
				end
				if v100_.loadedMesh ~= nil then
					delete(v100_.loadedMesh)
					v100_.loadedMesh = nil
				end
			end
		end
	end
end

-- Local values: slot, visual, variations, tileU, tileV
function LivestockTrailer:onAnimalLoaded(i3dNode, failedReason, args)
	if i3dNode ~= 0 then
		local v103_ = args.slot
		local v104_ = args.visual
		link(v103_.linkNode, i3dNode)
		v103_.loadedMesh = i3dNode
		v103_.meshLoadingInProgress = false
		local v105_ = v104_.visualAnimal.variations[1]
		local v106_ = v105_.tileUIndex / v105_.numTilesU
		local v107_ = v105_.tileVIndex / v105_.numTilesV
		I3DUtil.setShaderParameterRec(i3dNode, "atlasInvSizeAndOffsetUV", 1 / v105_.numTilesU, 1 / v105_.numTilesV, v106_, v107_)
		I3DUtil.setShaderParameterRec(i3dNode, "dirt", 0, nil, nil, nil)
	end
end

-- Local values: additionalMass, spec, clusters, _, cluster, subTypeIndex, subType, fillTypeIndex, fillType
function LivestockTrailer:getAdditionalComponentMass(superFunc, component)
	local v111_ = superFunc(self, component)
	local v112_ = self.spec_livestockTrailer.clusterSystem:getClusters()
	for _, v113_ in ipairs(v112_) do
		local v114_ = v113_:getSubTypeIndex()
		local v115_ = g_currentMission.animalSystem:getSubTypeByIndex(v114_).fillTypeIndex
		v111_ = v111_ + g_fillTypeManager:getFillTypeByIndex(v115_).massPerLiter * v113_:getNumAnimals()
	end
	return v111_
end

-- Local values: sellPrice, spec, clusters, _, cluster, sellPriceCluster
function LivestockTrailer:getSellPrice(superFunc)
	local v118_ = superFunc(self)
	local v119_ = self.spec_livestockTrailer.clusterSystem:getClusters()
	for _, v120_ in ipairs(v119_) do
		v118_ = v118_ + v120_:getSellPrice() * v120_:getNumAnimals() * 0.75
	end
	return v118_
end

-- Local values: spec, clusters, _, cluster
function LivestockTrailer:dayChanged(superFunc)
	superFunc(self)
	local v123_ = self.spec_livestockTrailer.clusterSystem:getClusters()
	for _, v124_ in ipairs(v123_) do
		v124_:onDayChanged()
	end
end

-- Local values: spec, clusters, _, cluster
function LivestockTrailer:periodChanged(superFunc)
	superFunc(self)
	local v127_ = self.spec_livestockTrailer.clusterSystem:getClusters()
	for _, v128_ in ipairs(v127_) do
		v128_:onPeriodChanged()
	end
end

-- Local values: spec, vehicle, cluster, subTypeIndex
function LivestockTrailer:onAnimalLoadTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if onEnter or onLeave then
		local v133_ = self.spec_livestockTrailer
		local v134_ = g_currentMission.nodeToObject[otherId]
		if v134_ ~= nil and v134_.spec_rideable ~= nil then
			local v135_ = v134_:getCluster()
			if v135_ ~= nil and self:getSupportsAnimalSubType((v135_:getSubTypeIndex())) then
				if onEnter then
					table.addElement(v133_.rideablesInTrigger, v134_)
					v134_:addDeleteListener(self, "onAnimalRideableDeleted")
				else
					table.removeElement(v133_.rideablesInTrigger, v134_)
					v134_:removeDeleteListener(self, "onAnimalRideableDeleted")
				end
				if v133_.animalScreenController ~= nil then
					v133_.animalScreenController:onAnimalsChanged(self, nil)
				end
			end
		end
	end
end

-- Local values: spec
function LivestockTrailer:onAnimalRideableDeleted(rideable)
	local v138_ = self.spec_livestockTrailer
	table.removeElement(v138_.rideablesInTrigger, rideable)
	if v138_.animalScreenController ~= nil then
		v138_.animalScreenController:onAnimalsChanged(self, nil)
	end
end

-- Local values: spec, places, _, spawnPlace, node, x, y, z, place
function LivestockTrailer:getAnimalUnloadPlaces()
	local v140_ = self.spec_livestockTrailer
	local v141_ = {}
	for _, v142_ in ipairs(v140_.spawnPlaces) do
		local v143_ = v142_.node
		local v144_, v145_, v146_ = getWorldTranslation(v143_)
		local v147_ = {
			["startX"] = v144_,
			["startY"] = v145_,
			["startZ"] = v146_
		}
		local v148_, v149_, v150_ = getWorldRotation(v143_)
		v147_.rotX = v148_
		v147_.rotY = v149_
		v147_.rotZ = v150_
		local v151_, v152_, v153_ = localDirectionToWorld(v143_, 1, 0, 0)
		v147_.dirX = v151_
		v147_.dirY = v152_
		v147_.dirZ = v153_
		local v154_, v155_, v156_ = localDirectionToWorld(v143_, 0, 0, 1)
		v147_.dirPerpX = v154_
		v147_.dirPerpY = v155_
		v147_.dirPerpZ = v156_
		v147_.yOffset = 1
		v147_.maxWidth = math.huge
		v147_.maxLength = math.huge
		v147_.maxHeight = math.huge
		v147_.width = v142_.width
		table.insert(v141_, v147_)
	end
	return v141_
end

-- Local values: maxNumAnimals, i, root, key, typeName
function LivestockTrailer.loadSpecValueNumberAnimals(xmlFile, customEnvironment, baseDir, animalTypeName)
	local v159_ = xmlFile:getRootName()
	local v160_ = 0
	local v161_ = nil
	while true do
		local v162_ = string.format("%s.livestockTrailer.animal(%d)", v159_, v160_)
		if not xmlFile:hasProperty(v162_) then
			break
		end
		local v163_ = xmlFile:getValue(v162_ .. "#type")
		if v163_ ~= nil and string.lower(v163_) == string.lower(animalTypeName) then
			return xmlFile:getValue(v162_ .. "#numSlots", 0)
		end
		v160_ = v160_ + 1
	end
	return v161_
end

function LivestockTrailer.loadSpecValueNumberAnimalsCow(xmlFile, customEnvironment, baseDir)
	return LivestockTrailer.loadSpecValueNumberAnimals(xmlFile, customEnvironment, baseDir, "cow")
end

function LivestockTrailer.loadSpecValueNumberAnimalsPig(xmlFile, customEnvironment, baseDir)
	return LivestockTrailer.loadSpecValueNumberAnimals(xmlFile, customEnvironment, baseDir, "pig")
end

function LivestockTrailer.loadSpecValueNumberAnimalsSheep(xmlFile, customEnvironment, baseDir)
	return LivestockTrailer.loadSpecValueNumberAnimals(xmlFile, customEnvironment, baseDir, "sheep")
end

function LivestockTrailer.loadSpecValueNumberAnimalsHorse(xmlFile, customEnvironment, baseDir)
	return LivestockTrailer.loadSpecValueNumberAnimals(xmlFile, customEnvironment, baseDir, "horse")
end

function LivestockTrailer.getSpecValueNumberAnimals(storeItem, realItem, specName)
	if storeItem.specs[specName] == nil then
		return nil
	else
		return string.format("%d %s", storeItem.specs[specName], g_i18n:getText("unit_pieces"))
	end
end

function LivestockTrailer.getSpecValueNumberAnimalsCow(storeItem, realItem)
	return LivestockTrailer.getSpecValueNumberAnimals(storeItem, realItem, "numAnimalsCow")
end

function LivestockTrailer.getSpecValueNumberAnimalsPig(storeItem, realItem)
	return LivestockTrailer.getSpecValueNumberAnimals(storeItem, realItem, "numAnimalsPig")
end

function LivestockTrailer.getSpecValueNumberAnimalsSheep(storeItem, realItem)
	return LivestockTrailer.getSpecValueNumberAnimals(storeItem, realItem, "numAnimalsSheep")
end

function LivestockTrailer.getSpecValueNumberAnimalsHorse(storeItem, realItem)
	return LivestockTrailer.getSpecValueNumberAnimals(storeItem, realItem, "numAnimalsHorse")
end
