PlaceableHusbandryAnimals = {}

function PlaceableHusbandryAnimals.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(PlaceableHusbandry, specializations)
end

function PlaceableHusbandryAnimals.registerEvents(placeableType)
	SpecializationUtil.registerEvent(placeableType, "onHusbandryAnimalsCreated")
	SpecializationUtil.registerEvent(placeableType, "onHusbandryAnimalsUpdate")
end

function PlaceableHusbandryAnimals.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "onExternalNavigationMeshLoaded", PlaceableHusbandryAnimals.onExternalNavigationMeshLoaded)
	SpecializationUtil.registerFunction(placeableType, "createNavigationMeshFromContour", PlaceableHusbandryAnimals.createNavigationMeshFromContour)
	SpecializationUtil.registerFunction(placeableType, "createNavigationMesh", PlaceableHusbandryAnimals.createNavigationMesh)
	SpecializationUtil.registerFunction(placeableType, "setMaxNumAnimals", PlaceableHusbandryAnimals.setMaxNumAnimals)
	SpecializationUtil.registerFunction(placeableType, "createHusbandry", PlaceableHusbandryAnimals.createHusbandry)
	SpecializationUtil.registerFunction(placeableType, "updateVisualAnimals", PlaceableHusbandryAnimals.updateVisualAnimals)
	SpecializationUtil.registerFunction(placeableType, "getNumOfFreeAnimalSlots", PlaceableHusbandryAnimals.getNumOfFreeAnimalSlots)
	SpecializationUtil.registerFunction(placeableType, "getNumOfAnimals", PlaceableHusbandryAnimals.getNumOfAnimals)
	SpecializationUtil.registerFunction(placeableType, "getMaxNumOfAnimals", PlaceableHusbandryAnimals.getMaxNumOfAnimals)
	SpecializationUtil.registerFunction(placeableType, "getNumOfClusters", PlaceableHusbandryAnimals.getNumOfClusters)
	SpecializationUtil.registerFunction(placeableType, "getSupportsAnimalSubType", PlaceableHusbandryAnimals.getSupportsAnimalSubType)
	SpecializationUtil.registerFunction(placeableType, "getClusters", PlaceableHusbandryAnimals.getClusters)
	SpecializationUtil.registerFunction(placeableType, "getCluster", PlaceableHusbandryAnimals.getCluster)
	SpecializationUtil.registerFunction(placeableType, "getClusterById", PlaceableHusbandryAnimals.getClusterById)
	SpecializationUtil.registerFunction(placeableType, "getClusterSystem", PlaceableHusbandryAnimals.getClusterSystem)
	SpecializationUtil.registerFunction(placeableType, "getAnimalTypeIndex", PlaceableHusbandryAnimals.getAnimalTypeIndex)
	SpecializationUtil.registerFunction(placeableType, "renameAnimal", PlaceableHusbandryAnimals.renameAnimal)
	SpecializationUtil.registerFunction(placeableType, "addCluster", PlaceableHusbandryAnimals.addCluster)
	SpecializationUtil.registerFunction(placeableType, "addAnimals", PlaceableHusbandryAnimals.addAnimals)
	SpecializationUtil.registerFunction(placeableType, "updatedClusters", PlaceableHusbandryAnimals.updatedClusters)
	SpecializationUtil.registerFunction(placeableType, "consoleCommandAddAnimals", PlaceableHusbandryAnimals.consoleCommandAddAnimals)
	SpecializationUtil.registerFunction(placeableType, "getAnimalSupportsRiding", PlaceableHusbandryAnimals.getAnimalSupportsRiding)
	SpecializationUtil.registerFunction(placeableType, "getAnimalCanBeRidden", PlaceableHusbandryAnimals.getAnimalCanBeRidden)
	SpecializationUtil.registerFunction(placeableType, "startRiding", PlaceableHusbandryAnimals.startRiding)
	SpecializationUtil.registerFunction(placeableType, "onLoadedRideable", PlaceableHusbandryAnimals.onLoadedRideable)
	SpecializationUtil.registerFunction(placeableType, "getIsInAnimalDeliveryArea", PlaceableHusbandryAnimals.getIsInAnimalDeliveryArea)
	SpecializationUtil.registerFunction(placeableType, "loadDeliveryArea", PlaceableHusbandryAnimals.loadDeliveryArea)
	SpecializationUtil.registerFunction(placeableType, "getOutdoorContourPolygon", PlaceableHusbandryAnimals.getOutdoorContourPolygon)
	SpecializationUtil.registerFunction(placeableType, "createNavigationMeshPlacementCollision", PlaceableHusbandryAnimals.createNavigationMeshPlacementCollision)
	SpecializationUtil.registerFunction(placeableType, "deleteNavigationMeshPlacementCollision", PlaceableHusbandryAnimals.deleteNavigationMeshPlacementCollision)
end

function PlaceableHusbandryAnimals.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getNeedDayChanged", PlaceableHusbandryAnimals.getNeedDayChanged)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableHusbandryAnimals.updateInfo)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateOutput", PlaceableHusbandryAnimals.updateOutput)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "canBeSold", PlaceableHusbandryAnimals.canBeSold)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getConditionInfos", PlaceableHusbandryAnimals.getConditionInfos)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getAnimalInfos", PlaceableHusbandryAnimals.getAnimalInfos)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getAnimalDescription", PlaceableHusbandryAnimals.getAnimalDescription)
end

function PlaceableHusbandryAnimals.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandryAnimals)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHusbandryAnimals)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableHusbandryAnimals)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableHusbandryAnimals)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableHusbandryAnimals)
	SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableHusbandryAnimals)
	SpecializationUtil.registerEventListener(placeableType, "onPeriodChanged", PlaceableHusbandryAnimals)
	SpecializationUtil.registerEventListener(placeableType, "onDayChanged", PlaceableHusbandryAnimals)
end

function PlaceableHusbandryAnimals.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")
	local v8_ = basePath .. ".husbandry.animals"
	schema:register(XMLValueType.NODE_INDEX, v8_ .. ".navigation#rootNode", "Navigation mesh rootnode")
	schema:register(XMLValueType.NODE_INDEX, v8_ .. ".navigation#node", "Navigation mesh node")
	schema:register(XMLValueType.NODE_INDEX, v8_ .. ".navigation#shape", "Shape to generate navigation mesh from")
	schema:register(XMLValueType.STRING, v8_ .. ".navigation#filename", "Filename for an external navigation mesh")
	schema:register(XMLValueType.STRING, v8_ .. ".navigation#nodePath", "Nodepath for an external navigation mesh")
	schema:register(XMLValueType.STRING, v8_ .. "#type", "Animal type")
	schema:register(XMLValueType.STRING, v8_ .. "#filename", "Animal configuration file")
	schema:register(XMLValueType.FLOAT, v8_ .. "#placementRaycastDistance", "Placement raycast distance", 2)
	schema:register(XMLValueType.INT, v8_ .. "#maxNumAnimals", "Max number of animals", 16)
	schema:register(XMLValueType.INT, v8_ .. "#baseMaxNumAnimals", "Base max number of animals without outoor area", 16)
	schema:register(XMLValueType.INT, v8_ .. "#sqmPerAnimal", "Square meter need per animal")
	schema:register(XMLValueType.INT, v8_ .. "#maxNumVisualAnimals", "Max number of visual animals")
	schema:register(XMLValueType.NODE_INDEX, v8_ .. ".loadingTrigger#node", "Animal loading trigger")
	schema:register(XMLValueType.NODE_INDEX, v8_ .. ".deliveryAreas.deliveryArea(?)#startNode", "Animal delivery area start node")
	schema:register(XMLValueType.NODE_INDEX, v8_ .. ".deliveryAreas.deliveryArea(?)#widthNode", "Animal delivery area width node")
	schema:register(XMLValueType.NODE_INDEX, v8_ .. ".deliveryAreas.deliveryArea(?)#heightNode", "Animal delivery area height node")
	schema:setXMLSpecializationType()
end

function PlaceableHusbandryAnimals.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")
	AnimalClusterSystem.registerSavegameXMLPaths(schema, basePath .. ".clusters")
	schema:setXMLSpecializationType()
end
function PlaceableHusbandryAnimals.initSpecialization()
	g_storeManager:addSpecType("numberAnimals", "shopListAttributeIconCapacity", PlaceableHusbandryAnimals.loadSpecValueNumberAnimals, PlaceableHusbandryAnimals.getSpecValueNumberAnimals, StoreSpecies.PLACEABLE)
	if g_isDevelopmentVersion then
		addConsoleCommand("gsHusbandryAddAnimals", "Add or remove animals from husbandry where player is currently located", "consoleCommandAddAnimals", PlaceableHusbandryAnimals, "numAnimals; [subTypeIndex]")
		addConsoleCommand("gsHusbandryDebugToggle", "Toggle husbandry debug mode", "consoleCommandToggleDebug", PlaceableHusbandryAnimals)
	end
end
function PlaceableHusbandryAnimals.terminateSpecialization()
	if g_isDevelopmentVersion then
		removeConsoleCommand("gsHusbandryAddAnimals")
		removeConsoleCommand("gsHusbandryDebugToggle")
	end
end

-- Local values: spec, xmlFile, animalTypeName, mission, navigationMeshShape, navMeshShapeValid, navigationMeshFilename, loadingTask, arguments, animalLoadingTriggerNode
function PlaceableHusbandryAnimals:onLoad(savegame)
	local v_u_12_ = self.spec_husbandryAnimals
	local v13_ = self.xmlFile
	v_u_12_.infoHealth = {
		["title"] = g_i18n:getText("ui_horseHealth"),
		["text"] = ""
	}
	v_u_12_.infoNumAnimals = {
		["title"] = g_i18n:getText("ui_numAnimals"),
		["text"] = ""
	}
	v_u_12_.updateVisuals = false
	local v14_ = v13_:getValue("placeable.husbandry.animals#type")
	if v14_ == nil then
		Logging.xmlError(v13_, "Missing animal type!")
		self:setLoadingState(PlaceableLoadingState.ERROR)
		return
	else
		v_u_12_.animalType = g_currentMission.animalSystem:getTypeByName(v14_)
		if v_u_12_.animalType == nil then
			Logging.xmlError(v13_, "Animal type \'%s\' not found!", v14_)
			self:setLoadingState(PlaceableLoadingState.ERROR)
		else
			v_u_12_.animalTypeIndex = v_u_12_.animalType.typeIndex
			v_u_12_.navigationMeshRootNode = v13_:getValue("placeable.husbandry.animals.navigation#rootNode", nil, self.components, self.i3dMappings)
			v_u_12_.navigationMesh = v13_:getValue("placeable.husbandry.animals.navigation#node", nil, self.components, self.i3dMappings)
			local v15_ = v13_:getValue("placeable.husbandry.animals.navigation#shape", nil, self.components, self.i3dMappings)
			if v15_ ~= nil then
				local v16_
				if getHasClassId(v15_, ClassIds.SHAPE) then
					v16_ = true
				else
					Logging.xmlError(v13_, "Given navigation shape %q at %q is not of type \'SHAPE\'", getName(v15_), "placeable.husbandry.animals.navigation#shape")
					v16_ = false
				end
				if getHasClassId(v15_, ClassIds.NAVIGATION_MESH) then
					Logging.xmlError(v13_, "Given navigation shape %q at %q is a navigation mesh instead of a regular shape", getName(v15_), "placeable.husbandry.animals.navigation#shape")
					v16_ = false
				end
				if v16_ and not getShapeIsCPUMesh(v15_) then
					Logging.xmlError(v13_, "Given navigation shape %q at %q is missing the \'CPU Mesh\' flag", getName(v15_), "placeable.husbandry.animals.navigation#shape")
					v16_ = false
				end
				if v16_ then
					setIsNonRenderable(v15_, true)
					v_u_12_.navigationMeshShape = v15_
				end
			end
			local v17_ = v13_:getValue("placeable.husbandry.animals.navigation#filename", nil)
			if v17_ ~= nil then
				local v18_ = Utils.getFilename(v17_, self.baseDirectory)
				local v19_ = self:createLoadingTask(v_u_12_)
				v_u_12_.navigationMeshNodePath = v13_:getValue("placeable.husbandry.animals.navigation#nodePath", "0")
				v_u_12_.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(v18_, true, false, self.onExternalNavigationMeshLoaded, self, {
					["loadingTask"] = v19_
				})
			end
			v_u_12_.outdoorContourPolygon = nil
			v_u_12_.placementRaycastDistance = v13_:getValue("placeable.husbandry.animals#placementRaycastDistance", 10)
			v_u_12_.sqmPerAnimal = self.xmlFile:getValue("placeable.husbandry.animals#sqmPerAnimal", v_u_12_.animalType.sqmPerAnimal)
			v_u_12_.configMaxNumAnimals = v13_:getValue("placeable.husbandry.animals#maxNumAnimals", 16)
			v_u_12_.baseMaxNumAnimals = self.xmlFile:getValue("placeable.husbandry.animals#baseMaxNumAnimals", v_u_12_.configMaxNumAnimals)
			v_u_12_.configMaxNumVisualAnimals = self.xmlFile:getValue("placeable.husbandry.animals#maxNumVisualAnimals")
			v_u_12_.clusterHusbandry = AnimalClusterHusbandry.new(self, v14_, 0)
			v_u_12_.clusterSystem = AnimalClusterSystem.new(self.isServer, self)
			g_messageCenter:subscribe(AnimalClusterUpdateEvent, self.updatedClusters, self)
			local v20_ = v13_:getValue("placeable.husbandry.animals.loadingTrigger#node", nil, self.components, self.i3dMappings)
			if v20_ ~= nil then
				v_u_12_.animalLoadingTrigger = AnimalLoadingTrigger.new(self.isServer, self.isClient)
				if not v_u_12_.animalLoadingTrigger:load(v20_, self) then
					v_u_12_.animalLoadingTrigger:delete()
				end
			end
			v_u_12_.deliveryAreas = {}
			self.xmlFile:iterate("placeable.husbandry.animals.deliveryAreas.deliveryArea", function(_, p21_)
				-- upvalues: (copy) self, (copy) v_u_12_
				local v22_ = {}
				if self:loadDeliveryArea(self.xmlFile, p21_, v22_) then
					local v23_ = v_u_12_.deliveryAreas
					table.insert(v23_, v22_)
				end
			end)
			v_u_12_.info = {
				["title"] = g_i18n:getText("statistic_productivity"),
				["text"] = ""
			}
			if not (self.isServer and g_isDevelopmentVersion) then
				removeConsoleCommand("gsHusbandryAddAnimals")
			end
		end
	end
end

-- Local values: spec, mission
function PlaceableHusbandryAnimals:onDelete()
	local v25_ = self.spec_husbandryAnimals
	g_messageCenter:unsubscribe(AnimalClusterUpdateEvent, self)
	g_messageCenter:unsubscribe(MessageType.CURRENT_MISSION_START, self)
	self:deleteNavigationMeshPlacementCollision()
	if v25_.clusterHusbandry ~= nil then
		g_currentMission.husbandrySystem:removeClusterHusbandry(v25_.clusterHusbandry)
		v25_.clusterHusbandry:delete()
		v25_.clusterHusbandry = nil
	end
	if v25_.animalLoadingTrigger ~= nil then
		v25_.animalLoadingTrigger:delete()
		v25_.animalLoadingTrigger = nil
	end
	if v25_.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(v25_.sharedLoadRequestId)
	end
end

function PlaceableHusbandryAnimals:onFinalizePlacement()
	self:createNavigationMesh()
	if self.isLoadedFromSavegame then
		g_messageCenter:subscribeOneshot(MessageType.CURRENT_MISSION_START, PlaceableHusbandryAnimals.onMissionStarted, self)
	end
end

-- Local values: spec
function PlaceableHusbandryAnimals:onReadStream(streamId, connection)
	self.spec_husbandryAnimals.clusterSystem:readStream(streamId, connection)
end

-- Local values: spec
function PlaceableHusbandryAnimals:onWriteStream(streamId, connection)
	self.spec_husbandryAnimals.clusterSystem:writeStream(streamId, connection)
end

-- Local values: spec
function PlaceableHusbandryAnimals:saveToXMLFile(xmlFile, key, usedModNames)
	self.spec_husbandryAnimals.clusterSystem:saveToXMLFile(xmlFile, key .. ".clusters", usedModNames)
end

-- Local values: spec
function PlaceableHusbandryAnimals:loadFromXMLFile(xmlFile, key)
	self.spec_husbandryAnimals.clusterSystem:loadFromXMLFile(xmlFile, key .. ".clusters")
end

-- Local values: spec
function PlaceableHusbandryAnimals:onUpdate(dt)
	local v42_ = self.spec_husbandryAnimals
	if self.isServer then
		v42_.clusterSystem:update(dt)
	end
	if v42_.clusterHusbandry ~= nil then
		v42_.clusterHusbandry:update(dt)
	end
	if v42_.updateVisuals then
		self:updateVisualAnimals()
		v42_.updateVisuals = false
	end
	if v42_.clusterHusbandry:getNeedsUpdate() then
		self:raiseActive()
	end
end

-- Local values: spec, loadingTask
function PlaceableHusbandryAnimals:onExternalNavigationMeshLoaded(node, failedReason, args)
	local v46_ = self.spec_husbandryAnimals
	local v47_ = args.loadingTask
	if node == 0 or node == nil then
		self:finishLoadingTask(v47_)
		Logging.error("Missing navigation mesh in external navigation mesh file!")
	else
		if v46_.navigationMeshRootNode ~= nil then
			v46_.navigationMesh = I3DUtil.indexToObject(node, v46_.navigationMeshNodePath)
			link(v46_.navigationMeshRootNode, v46_.navigationMesh)
		end
		delete(node)
		self:finishLoadingTask(v47_)
	end
end

function PlaceableHusbandryAnimals:createNavigationMesh()
	return self:createNavigationMeshFromContour()
end

-- Local values: spec, outdoorAreaSqm, navMeshAgentAttributes, agentHeight, agentRadius, agentMaxClimbMeters, agentMaxSlope, cellSize, cellHeight, minRegion, mergedRegion, maxEdgeLength, maxEdgeError, collisionMask, contourVertIndex, i, navMesh, success, buildNavMeshMask
function PlaceableHusbandryAnimals:createNavigationMeshFromContour(contourPositions)
	local v51_ = self.spec_husbandryAnimals
	v51_.outdoorContourPolygon = nil
	local v52_
	if contourPositions == nil or #contourPositions < 9 then
		v52_ = 0
	else
		local v53_ = v51_.animalType.navMeshAgentAttributes or {}
		local v54_ = v53_.height or 1.6
		local v55_ = v53_.radius or 0.1
		local v56_ = v53_.maxClimbMeters or 0.9
		local v57_ = v53_.maxSlope or 0.7853981633974483
		local v58_ = CollisionFlag.TREE + CollisionFlag.ANIMAL_NAV_MESH_BLOCKING
		v51_.outdoorContourPolygon = Polygon2D.new()
		v51_.outdoorContourPolygon:setVerticesFromXYZ(contourPositions)
		v52_ = v51_.outdoorContourPolygon:getArea()
		if PlaceableHusbandryAnimals.debugEnabled then
			local v59_ = 1
			for v60_ = 1, #contourPositions, 3 do
				DebugPoint.new():createWithWorldPos(contourPositions[v60_], 0, contourPositions[v60_ + 2], true):setText(string.format("NM contour v%d", v59_)):addToManager("NM-Contour")
				v59_ = v59_ + 1
			end
		end
		local v61_ = createNavMesh(string.format("PlaceableHusbandryAnimals_generatedNavMesh_%s", self.configFileNameClean or self.rootNode))
		link(v51_.navigationMeshRootNode or self.rootNode, v61_)
		local v62_
		if v51_.navigationMeshShape == nil then
			v62_ = buildNavMeshFromContour(v61_, contourPositions, g_terrainNode, v58_, 0.25, 0.2, v54_, v55_, v56_, v57_, 25, 25, 50, 1)
		else
			setShapeBuildNavMeshMask(v51_.navigationMeshShape, 254)
			v62_ = buildNavMeshFromShapesAndContour(v61_, v51_.navigationMeshShape, 254, contourPositions, g_terrainNode, v58_, 0.25, 0.2, v54_, v55_, v56_, v57_, 25, 25, 50, 1)
		end
		if not v62_ then
			Logging.error("buildNavMeshFromShapesAndContour for %q failed", self.configFileName)
			delete(v61_)
			return false
		end
		if v51_.navigationMesh ~= nil then
			delete(v51_.navigationMesh)
		end
		v51_.navigationMesh = v61_
		if v51_.placementCollisionNode ~= nil then
			delete(v51_.placementCollisionNode)
			v51_.placementCollisionNode = nil
		end
		self:createNavigationMeshPlacementCollision(contourPositions)
	end
	self:setMaxNumAnimals(v52_)
	self:createHusbandry()
	return true
end

-- Local values: spec, maxNumAnimals, numAnimalsOutdoor, maxNumVisualAnimals, profileClass, networkMaxNumAnimals, configDefinedMaxNumVisualAnimals
function PlaceableHusbandryAnimals:setMaxNumAnimals(outdoorAreaSqm)
	local v65_ = self.spec_husbandryAnimals
	local v66_ = v65_.baseMaxNumAnimals
	if outdoorAreaSqm ~= nil and v65_.sqmPerAnimal ~= nil then
		local v67_ = outdoorAreaSqm / v65_.sqmPerAnimal
		v66_ = v66_ + math.floor(v67_)
	end
	local v68_
	if v65_.animalTypeIndex == AnimalType.HORSE then
		v68_ = math.min(v66_, 16)
		v66_ = math.min(v66_, 16)
		if GS_IS_MOBILE_VERSION then
			v68_ = math.min(v68_, 8)
			v66_ = math.min(v66_, 8)
		end
	else
		local v69_ = Utils.getPerformanceClassId()
		v68_ = v69_ == GS_PROFILE_VERY_LOW and 8 or ((GS_PLATFORM_XBOX or v69_ == GS_PROFILE_LOW) and 10 or (GS_PROFILE_VERY_HIGH <= v69_ and 25 or (GS_PROFILE_HIGH <= v69_ and 20 or 16)))
		if GS_IS_MOBILE_VERSION then
			v68_ = math.min(v68_, 8)
		end
	end
	local v70_ = 2 ^ AnimalCluster.NUM_BITS_NUM_ANIMALS - 1
	local v71_ = math.min(v66_, v70_)
	local v72_ = v65_.configMaxNumVisualAnimals
	if v72_ == nil then
		v72_ = v68_
	else
		if v65_.configMaxNumAnimals < v72_ then
			v72_ = v65_.configMaxNumAnimals
		end
		if v72_ >= v68_ then
			v72_ = v68_
		end
	end
	v65_.maxNumVisualAnimals = v72_
	v65_.maxNumAnimals = v71_
	v65_.clusterHusbandry:setMaxNumVisualAnimals(v72_)
end

-- Local values: spec, mission, collisionMaskFilter, husbandryId
function PlaceableHusbandryAnimals:createHusbandry()
	local v74_ = self.spec_husbandryAnimals
	if v74_.navigationMesh == nil then
		if self.isServer then
			Logging.xmlError(self.xmlFile, "Navigation mesh node not defined for animal husbandry!")
			printCallstack()
		end
		return
	elseif getHasClassId(v74_.navigationMesh, ClassIds.NAVIGATION_MESH) then
		if getNavMeshSurfaceArea(v74_.navigationMesh) == 0 then
			Logging.error("Given nav mesh %q has no surface area", getName(v74_.navigationMesh))
			return
		else
			local v75_ = g_currentMission
			local v76_ = CollisionMask.ANIMAL_SINGLEPLAYER
			if v75_.missionDynamicInfo.isMultiplayer then
				v76_ = CollisionMask.ANIMAL_MULTIPLAYER
			end
			v75_.husbandrySystem:removeClusterHusbandry(v74_.clusterHusbandry)
			local v77_ = v74_.clusterHusbandry:create(v74_.animalType.configFilename, v74_.navigationMesh, v74_.placementRaycastDistance, v76_)
			if v77_ == nil or v77_ == 0 then
				Logging.error("Could not create animal husbandry!")
			else
				if v77_ ~= nil then
					v75_.husbandrySystem:addClusterHusbandry(v74_.clusterHusbandry)
				end
				SpecializationUtil.raiseEvent(self, "onHusbandryAnimalsCreated", v77_)
			end
		end
	else
		Logging.error("Given mesh node \'%s\' is not a navigation mesh!", getName(v74_.navigationMesh))
		return
	end
end

-- Local values: spec
function PlaceableHusbandryAnimals:getOutdoorContourPolygon()
	return self.spec_husbandryAnimals.outdoorContourPolygon
end

-- Local values: spec, health, numAnimals, clusters, numClusters, _, cluster
function PlaceableHusbandryAnimals:updateInfo(superFunc, infoTable)
	superFunc(self, infoTable)
	local v82_ = self.spec_husbandryAnimals
	local v83_ = 0
	local v84_ = 0
	local v85_ = v82_.clusterSystem:getClusters()
	local v86_ = #v85_
	if v86_ > 0 then
		for _, v87_ in ipairs(v85_) do
			v83_ = v83_ + v87_.health
			v84_ = v84_ + v87_.numAnimals
		end
		v83_ = v83_ / v86_
	end
	v82_.infoNumAnimals.text = string.format("%d / %d", v84_, self:getMaxNumOfAnimals())
	v82_.infoHealth.text = string.format("%d %%", v83_)
	local v88_ = v82_.infoNumAnimals
	table.insert(infoTable, v88_)
	local v89_ = v82_.infoHealth
	table.insert(infoTable, v89_)
end

function PlaceableHusbandryAnimals:getNeedDayChanged(superFunc)
	return true
end

function PlaceableHusbandryAnimals:onMissionStarted(isNewSavegame)
	self:updateVisualAnimals()
end

-- Local values: spec, clusters
function PlaceableHusbandryAnimals:updateVisualAnimals()
	local v92_ = self.spec_husbandryAnimals
	local v93_ = v92_.clusterSystem:getClusters()
	v92_.clusterHusbandry:setClusters(v93_)
	self:raiseActive()
end

-- Local values: spec
function PlaceableHusbandryAnimals:getAnimalTypeIndex()
	return self.spec_husbandryAnimals.animalTypeIndex
end

-- Local values: spec, clusters, _, cluster
function PlaceableHusbandryAnimals:updateOutput(superFunc, foodFactor, productionFactor, globalProductionFactor)
	if self.isServer then
		local v100_ = self.spec_husbandryAnimals.clusterSystem:getClusters()
		for _, v101_ in ipairs(v100_) do
			v101_:updateHealth(foodFactor)
		end
		self:raiseActive()
	end
	superFunc(self, foodFactor, productionFactor, globalProductionFactor)
end

-- Local values: spec, clusters, totalNumAnimals, maxNumAnimals, freeSlots, mission, animalSystem, _, cluster, numNewAnimals, newCluster, subType
function PlaceableHusbandryAnimals:onPeriodChanged()
	if self.isServer then
		local v103_ = self.spec_husbandryAnimals
		local v104_ = v103_.clusterSystem:getClusters()
		local v105_ = self:getNumOfAnimals()
		local v106_ = self:getMaxNumOfAnimals() - v105_
		local v107_ = math.max(v106_, 0)
		local v108_ = g_currentMission.animalSystem
		for _, v109_ in ipairs(v104_) do
			v109_:onPeriodChanged()
			local v110_ = v109_:updateReproduction()
			if v110_ > 0 then
				local v111_ = math.min(v107_, v110_)
				if v111_ > 0 then
					local v112_ = v108_:createClusterFromSubTypeIndex(v109_:getSubTypeIndex())
					v112_.numAnimals = v111_
					v107_ = v107_ - v111_
					v103_.clusterSystem:addPendingAddCluster(v112_)
					local v113_ = v108_:getSubTypeByIndex(v109_:getSubTypeIndex())
					if v113_.statsBreedingName ~= nil then
						g_farmManager:updateFarmStats(self:getOwnerFarmId(), v113_.statsBreedingName, v112_.numAnimals)
					end
				end
			end
		end
		self:raiseActive()
	end
end

-- Local values: spec, clusters, _, cluster
function PlaceableHusbandryAnimals:onDayChanged()
	if self.isServer then
		local v115_ = self.spec_husbandryAnimals.clusterSystem:getClusters()
		for _, v116_ in ipairs(v115_) do
			v116_:onDayChanged()
		end
	end
end

-- Local values: spec, numAnimals, clusters, _, cluster
function PlaceableHusbandryAnimals:getNumOfAnimals()
	local v118_ = self.spec_husbandryAnimals.clusterSystem:getClusters()
	local v119_ = 0
	for _, v120_ in ipairs(v118_) do
		v119_ = v119_ + v120_.numAnimals
	end
	return v119_
end

-- Local values: spec
function PlaceableHusbandryAnimals:getMaxNumOfAnimals()
	local v122_ = self.spec_husbandryAnimals
	return v122_.maxNumAnimals or v122_.baseMaxNumAnimals
end

-- Local values: totalNumAnimals, maxNumAnimals
function PlaceableHusbandryAnimals:getNumOfFreeAnimalSlots()
	local v124_ = self:getNumOfAnimals()
	local v125_ = self:getMaxNumOfAnimals() - v124_
	return math.max(v125_, 0)
end

-- Local values: spec, mission, animalSystem, subType
function PlaceableHusbandryAnimals:getSupportsAnimalSubType(subTypeIndex)
	local v128_ = self.spec_husbandryAnimals
	local v129_ = g_currentMission.animalSystem:getSubTypeByIndex(subTypeIndex)
	return v128_.animalTypeIndex == v129_.typeIndex
end

-- Local values: spec, clusters
function PlaceableHusbandryAnimals:getNumOfClusters()
	return #self.spec_husbandryAnimals.clusterSystem:getClusters()
end

-- Local values: spec
function PlaceableHusbandryAnimals:getClusters()
	return self.spec_husbandryAnimals.clusterSystem:getClusters()
end

-- Local values: spec
function PlaceableHusbandryAnimals:getCluster(index)
	return self.spec_husbandryAnimals.clusterSystem:getCluster(index)
end

-- Local values: spec
function PlaceableHusbandryAnimals:getClusterById(id)
	return self.spec_husbandryAnimals.clusterSystem:getClusterById(id)
end

-- Local values: spec
function PlaceableHusbandryAnimals:addCluster(cluster)
	if cluster ~= nil then
		self.spec_husbandryAnimals.clusterSystem:addPendingAddCluster(cluster)
		self:raiseActive()
	end
end

-- Local values: mission, animalSystem, cluster, i
function PlaceableHusbandryAnimals:addAnimals(subTypeIndex, numAnimals, age)
	local v142_ = g_currentMission.animalSystem
	local v143_ = v142_:createClusterFromSubTypeIndex(subTypeIndex)
	if v143_:getSupportsMerging() then
		v143_.numAnimals = numAnimals
		v143_.age = age
		v143_.subTypeIndex = subTypeIndex
		self:addCluster(v143_)
	else
		for _ = 1, numAnimals do
			local v144_ = v142_:createClusterFromSubTypeIndex(subTypeIndex)
			v144_.numAnimals = 1
			v144_.age = age
			self:addCluster(v144_)
		end
	end
end

-- Local values: spec
function PlaceableHusbandryAnimals:getClusterSystem()
	return self.spec_husbandryAnimals.clusterSystem
end

-- Local values: spec, clusters
function PlaceableHusbandryAnimals:updatedClusters(husbandry)
	if husbandry == self then
		local v148_ = self.spec_husbandryAnimals
		local v149_ = v148_.clusterSystem:getClusters()
		SpecializationUtil.raiseEvent(self, "onHusbandryAnimalsUpdate", v149_)
		g_messageCenter:publish(MessageType.HUSBANDRY_ANIMALS_CHANGED, self)
		v148_.updateVisuals = true
		self:raiseActive()
	end
end

-- Local values: spec, cluster
function PlaceableHusbandryAnimals:renameAnimal(clusterId, name, noEventSend)
	local v154_ = self.spec_husbandryAnimals
	AnimalNameEvent.sendEvent(self, clusterId, name, noEventSend)
	local v155_ = v154_.clusterSystem:getClusterById(clusterId)
	if v155_ ~= nil then
		v155_:setName(name)
	end
end

-- Local values: spec, cluster, filename
function PlaceableHusbandryAnimals:getAnimalSupportsRiding(clusterId)
	local v158_ = self.spec_husbandryAnimals.clusterSystem:getClusterById(clusterId)
	return v158_ ~= nil and v158_:getRidableFilename() ~= nil
end

-- Local values: mission
function PlaceableHusbandryAnimals:getAnimalCanBeRidden(clusterId)
	return g_currentMission.husbandrySystem:getCanAddRideable(self:getOwnerFarmId())
end

-- Local values: spec, cluster, x, y, z, rx, ry, rz, farmId, filename, arguments, data
function PlaceableHusbandryAnimals:startRiding(clusterId, player)
	if self.isServer then
		local v163_ = self.spec_husbandryAnimals
		local v164_ = v163_.clusterSystem:getClusterById(clusterId)
		if v164_ ~= nil then
			local v165_, v166_, v167_, v168_, v169_, v170_ = v163_.clusterHusbandry:getAnimalPosition(clusterId)
			if v165_ ~= nil then
				local v171_ = self:getOwnerFarmId()
				local v172_ = v164_:getRidableFilename()
				v164_:changeNumAnimals(-1)
				v163_.clusterSystem:updateNow()
				local v173_ = VehicleLoadingData.new()
				v173_:setFilename(v172_)
				v173_:setPosition(v165_, v166_, v167_)
				v173_:setRotation(v168_, v169_, v170_)
				v173_:setPropertyState(VehiclePropertyState.OWNED)
				v173_:setOwnerFarmId(v171_)
				v173_:load(self.onLoadedRideable, self, {
					["player"] = player,
					["cluster"] = v164_
				})
			end
		end
	else
		g_client:getServerConnection():sendEvent(AnimalRidingEvent.new(self, clusterId, player))
	end
end

-- Local values: cluster, spec, newCluster
function PlaceableHusbandryAnimals:onLoadedRideable(vehicles, vehicleLoadState, arguments)
	local v178_ = arguments.cluster
	if vehicleLoadState == VehicleLoadingState.OK and #vehicles ~= 0 then
		local v179_ = v178_:clone()
		v179_:changeNumAnimals(1)
		vehicles[1]:setCluster(v179_)
		vehicles[1]:setPlayerToEnter(arguments.player)
	else
		local v180_ = self.spec_husbandryAnimals
		v178_:changeNumAnimals(1)
		v180_.clusterSystem:updateNow()
	end
end

-- Local values: start, width, height
function PlaceableHusbandryAnimals:loadDeliveryArea(xmlFile, key, area)
	local v185_ = xmlFile:getValue(key .. "#startNode", nil, self.components, self.i3dMappings)
	if v185_ == nil then
		Logging.xmlWarning(xmlFile, "Delivery area start node not defined for \'%s\'", key)
		return false
	end
	local v186_ = xmlFile:getValue(key .. "#widthNode", nil, self.components, self.i3dMappings)
	if v186_ == nil then
		Logging.xmlWarning(xmlFile, "Delivery area width node not defined for \'%s\'", key)
		return false
	end
	local v187_ = xmlFile:getValue(key .. "#heightNode", nil, self.components, self.i3dMappings)
	if v187_ == nil then
		Logging.xmlWarning(xmlFile, "Delivery area height node not defined for \'%s\'", key)
		return false
	end
	area.start = v185_
	area.width = v186_
	area.height = v187_
	return true
end

-- Local values: spec, inPolygon, _, deliveryArea, startX, _, startZ, widthX, _, widthZ, heightX, _, heightZ, inArea, px, _, pz
function PlaceableHusbandryAnimals:getIsInAnimalDeliveryArea(x, z)
	local v191_ = self.spec_husbandryAnimals
	if v191_.outdoorContourPolygon ~= nil then
		return v191_.outdoorContourPolygon:getIsPosInside(x, z)
	end
	for _, v192_ in ipairs(v191_.deliveryAreas) do
		local v193_, _, v194_ = getWorldTranslation(v192_.start)
		local v195_, _, v196_ = getWorldTranslation(v192_.width)
		local v197_, _, v198_ = getWorldTranslation(v192_.height)
		local v199_ = v195_ - v193_
		local v200_ = v196_ - v194_
		local v201_ = v197_ - v193_
		local v202_ = v198_ - v194_
		if MathUtil.isPointInParallelogram(x, z, v193_, v194_, v199_, v200_, v201_, v202_) then
			return true
		end
	end
	if #v191_.deliveryAreas == 0 then
		local v203_, _, v204_ = getWorldTranslation(self.rootNode)
		if MathUtil.vector2Length(v203_ - x, v204_ - z) < 30 then
			return true
		end
	end
	return false
end

-- Local values: data, maxNumAnimals, animalTypeName
function PlaceableHusbandryAnimals.loadSpecValueNumberAnimals(xmlFile, customEnvironment, baseDir)
	return xmlFile:hasProperty("placeable.husbandry.animals") and {
		["maxNumAnimals"] = xmlFile:getInt("placeable.husbandry.animals#maxNumAnimals", 16),
		["animalTypeName"] = xmlFile:getString("placeable.husbandry.animals#type")
	} or nil
end

-- Local values: data, profile, mission, animalTypeIndex
function PlaceableHusbandryAnimals.getSpecValueNumberAnimals(storeItem, realItem)
	local v207_ = storeItem.specs.numberAnimals
	if v207_ == nil then
		return nil
	end
	local v208_ = g_currentMission.animalSystem:getTypeIndexByName(v207_.animalTypeName)
	local v209_ = v208_ == AnimalType.COW and "shopListAttributeIconCow" or (v208_ == AnimalType.SHEEP and "shopListAttributeIconSheep" or (v208_ == AnimalType.HORSE and "shopListAttributeIconHorse" or (v208_ == AnimalType.PIG and "shopListAttributeIconPig" or (v208_ == AnimalType.CHICKEN and "shopListAttributeIconChicken" or nil))))
	return v207_.maxNumAnimals, v209_
end

function PlaceableHusbandryAnimals:canBeSold(superFunc)
	if self:getNumOfAnimals() > 0 then
		return false, g_i18n:getText("info_husbandryNotEmpty")
	else
		return superFunc(self)
	end
end

-- Local values: infos, spec, animalTypeIndex, globalProductionFactor, productionFactor, productivity
function PlaceableHusbandryAnimals:getConditionInfos(superFunc)
	local v214_ = superFunc(self)
	local v215_ = self.spec_husbandryAnimals
	local v216_ = self:getAnimalTypeIndex()
	if v216_ ~= AnimalType.HORSE and v216_ ~= AnimalType.PIG then
		local v217_ = self:getGlobalProductionFactor() * self:getProductionFactor()
		v215_.info.value = v217_
		v215_.info.ratio = v217_
		v215_.info.valueText = string.format("%s %%", g_i18n:formatNumber(v217_ * 100, 0))
		local v218_ = v215_.info
		table.insert(v214_, v218_)
	end
	return v214_
end

-- Local values: infos
function PlaceableHusbandryAnimals:getAnimalInfos(superFunc, cluster)
	local v222_ = superFunc(self)
	cluster:addInfos(v222_)
	return v222_
end

-- Local values: text, mission, visual
function PlaceableHusbandryAnimals:getAnimalDescription(superFunc, cluster)
	return superFunc(self, cluster) .. g_currentMission.animalSystem:getVisualByAge(cluster.subTypeIndex, cluster:getAge()).store.description
end

-- Local values: spec, minX, maxX, minZ, maxZ, maxY, contour2D, i, placementCol, x, _y, z
function PlaceableHusbandryAnimals:createNavigationMeshPlacementCollision(contourPositions3D)
	local v228_ = self.spec_husbandryAnimals
	local v229_ = table.create(#contourPositions3D * 2 / 3)
	local v230_ = math.huge
	local v231_ = -math.huge
	local v232_ = math.huge
	local v233_ = -math.huge
	local v234_ = -math.huge
	for v235_ = 1, #contourPositions3D, 3 do
		v229_[#v229_ + 1] = contourPositions3D[v235_]
		v229_[#v229_ + 1] = contourPositions3D[v235_ + 2]
		local v236_ = contourPositions3D[v235_]
		v230_ = math.min(v236_, v230_)
		local v237_ = contourPositions3D[v235_]
		v231_ = math.max(v237_, v231_)
		local v238_ = contourPositions3D[v235_ + 2]
		v232_ = math.min(v238_, v232_)
		local v239_ = contourPositions3D[v235_ + 2]
		v233_ = math.max(v239_, v233_)
		local v240_ = contourPositions3D[v235_ + 1]
		v234_ = math.max(v234_, v240_)
	end
	local v241_ = createPlaneShapeFrom2DContour("husbandryPlacementCol", v229_, true)
	if v241_ == 0 then
		Logging.error("Unable to create husbandry placement collision shape")
		DebugUtil.printListAsTriples(contourPositions3D)
		return false
	end
	self:deleteNavigationMeshPlacementCollision()
	setIsNonRenderable(v241_, true)
	removeFromPhysics(v241_)
	local v242_, _, v243_ = getWorldTranslation(v241_)
	link(self.rootNode, v241_)
	setWorldTranslation(v241_, v242_, v234_, v243_)
	setWorldRotation(v241_, 0, 0, 0)
	setRigidBodyType(v241_, RigidBodyType.STATIC)
	setCollisionFilter(v241_, CollisionFlag.PLACEMENT_BLOCKING, 1)
	addToPhysics(v241_)
	v228_.placementCollisionNode = v241_
	v228_.placementCollisionArea = {
		v230_,
		v232_,
		v231_,
		v233_
	}
	g_densityMapHeightManager:setCollisionMapAreaDirty(v230_, v232_, v231_, v233_, true)
	g_currentMission.aiSystem:setAreaDirty(v230_, v231_, v232_, v233_)
	return true
end

-- Local values: spec, minX, minZ, maxX, maxZ
function PlaceableHusbandryAnimals:deleteNavigationMeshPlacementCollision()
	local v245_ = self.spec_husbandryAnimals
	if v245_.placementCollisionNode ~= nil then
		delete(v245_.placementCollisionNode)
		v245_.placementCollisionNode = nil
		local v246_ = v245_.placementCollisionArea
		local v247_, v248_, v249_, v250_ = unpack(v246_)
		g_densityMapHeightManager:setCollisionMapAreaDirty(v247_, v248_, v249_, v250_, true)
		g_currentMission.aiSystem:setAreaDirty(v247_, v249_, v248_, v250_)
	end
end

-- Local values: usage, x, y, z, mask, husbandryInstance, spec, globalSubTypeIndex, mission, newCluster, remainingAnimals, _, cluster
function PlaceableHusbandryAnimals.consoleCommandAddAnimals(_, numAnimals, subTypeIndex)
	local v253_, v254_, v255_ = getWorldTranslation(g_cameraManager:getActiveCamera())
	local v256_ = CollisionFlag.STATIC_OBJECT + CollisionFlag.BUILDING + CollisionFlag.ANIMAL_POSITIONING + CollisionFlag.GROUND_TIP_BLOCKING + CollisionFlag.PLACEMENT_BLOCKING + CollisionFlag.TRIGGER
	raycastAll(v253_, v254_ + 100, v255_, 0, -1, 0, 110, "consoleCommandAddAnimalsRaycastCallback", PlaceableHusbandryAnimals, v256_)
	local v257_ = PlaceableHusbandryAnimals.consoleCommandCurrentHusbandry
	PlaceableHusbandryAnimals.consoleCommandCurrentHusbandry = nil
	if v257_ == nil then
		return "Error: No husbandry found. Enter a husbandry with the player first"
	end
	local v258_ = v257_.spec_husbandryAnimals
	local v259_ = tonumber(numAnimals) or 0
	local v260_ = tonumber(subTypeIndex)
	if v259_ <= 0 then
		if v259_ >= 0 then
			return "Error: Invalid number of animals\nUsage: gsHusbandryAddAnimals numAnimals [subTypeIndex]\nUse negative number to remove animals"
		end
		local v261_ = v259_
		for _, v262_ in pairs(v257_:getClusters()) do
			if v260_ == nil or v262_:getSubTypeIndex() == v260_ then
				v259_ = v262_:changeNumAnimals(v259_)
			end
			if v259_ >= 0 then
				break
			end
		end
		if v261_ == v259_ then
			return v260_ == nil and "Error: Husbandry has no animals" or "Error: Husbandry has no animals of subtype " .. v260_
		end
		local v263_ = string.format
		local v264_ = v261_ - v259_
		return v263_("Removed %d animal(s)", (math.abs(v264_)))
	end
	if v257_:getNumOfFreeAnimalSlots() == 0 then
		return "Error: Husbandry is full"
	end
	local v265_ = math.min(v259_, v257_:getNumOfFreeAnimalSlots())
	local v266_ = tonumber(v260_) or 1
	local v267_ = v258_.animalType.subTypes[v266_]
	if v267_ == nil then
		return "Error: Invalid subtype index\nUsage: gsHusbandryAddAnimals numAnimals [subTypeIndex]\nUse negative number to remove animals"
	end
	local v268_ = g_currentMission.animalSystem:createClusterFromSubTypeIndex(v267_)
	v268_.numAnimals = v265_
	v258_.clusterSystem:addPendingAddCluster(v268_)
	v257_:raiseActive()
	return "Added " .. v265_ .. " animal(s)"
end

-- Local values: mission, object
function PlaceableHusbandryAnimals.consoleCommandAddAnimalsRaycastCallback(_, actorId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	if actorId ~= 0 then
		local v270_ = g_currentMission:getNodeObject(actorId)
		if v270_ ~= nil and (v270_:isa(Placeable) and SpecializationUtil.hasSpecialization(PlaceableHusbandryAnimals, v270_.specializations)) then
			PlaceableHusbandryAnimals.consoleCommandCurrentHusbandry = v270_
			return false
		end
	end
	return true
end
function PlaceableHusbandryAnimals.consoleCommandToggleDebug()
	PlaceableHusbandryAnimals.debugEnabled = not PlaceableHusbandryAnimals.debugEnabled
	executeConsoleCommand(string.format("showNavMesh %s", PlaceableHusbandryAnimals.debugEnabled), false)
	if not PlaceableHusbandryAnimals.debugEnabled then
		g_debugManager:removeGroup("NM-Contour")
		g_debugManager:removeGroup("PlaceableHusbandryMeadow")
	end
	return string.format("PlaceableHusbandryAnimals.debugEnabled=%s", PlaceableHusbandryAnimals.debugEnabled)
end
