PlaceableFarmhouse = {}
source("dataS/scripts/placeables/specializations/activatables/FarmhouseActivatable.lua")

function PlaceableFarmhouse.prerequisitesPresent(specializations)
	return true
end

function PlaceableFarmhouse.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "farmhouseSleepingTriggerCallback", PlaceableFarmhouse.farmhouseSleepingTriggerCallback)
	SpecializationUtil.registerFunction(placeableType, "getSleepCamera", PlaceableFarmhouse.getSleepCamera)
	SpecializationUtil.registerFunction(placeableType, "getSpawnWorldPosition", PlaceableFarmhouse.getSpawnWorldPosition)
	SpecializationUtil.registerFunction(placeableType, "getSpawnPoint", PlaceableFarmhouse.getSpawnPoint)
	SpecializationUtil.registerFunction(placeableType, "getIsAllowedToSleep", PlaceableFarmhouse.getIsAllowedToSleep)
end

function PlaceableFarmhouse.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "finalizeConstruction", PlaceableFarmhouse.finalizeConstruction)
end

function PlaceableFarmhouse.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableFarmhouse)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableFarmhouse)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableFarmhouse)
end

function PlaceableFarmhouse.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Farmhouse")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".farmhouse#spawnNode", "Player spawn node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".farmhouse.sleeping#triggerNode", "Sleeping trigger")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".farmhouse.sleeping#cameraNode", "Camera while sleeping")
	schema:register(XMLValueType.BOOL, basePath .. ".farmhouse.sleeping#isFreeForAll", "Marks if everybody can sleep there")
	schema:register(XMLValueType.BOOL, basePath .. ".farmhouse#isFinalized", "If the farmhouse is finalized and ready on start. E.g. constructible")
	schema:setXMLSpecializationType()
end

function PlaceableFarmhouse.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Farmhouse")
	schema:register(XMLValueType.BOOL, basePath .. "#isFreeForAll", "Marks if everybody can sleep there")
	schema:setXMLSpecializationType()
end

-- Local values: spec, sleepingTriggerKey, cameraKey, camera
function PlaceableFarmhouse:onLoad(savegame)
	local v9_ = self.spec_farmhouse
	v9_.activatable = FarmhouseActivatable.new(self)
	v9_.spawnNode = self.xmlFile:getValue("placeable.farmhouse#spawnNode", nil, self.components, self.i3dMappings)
	if v9_.spawnNode == nil then
		Logging.xmlError(self.xmlFile, "No spawn node defined for farmhouse")
		v9_.spawnNode = self.rootNode
	end
	v9_.sleepingTrigger = self.xmlFile:getValue("placeable.farmhouse.sleeping#triggerNode", nil, self.components, self.i3dMappings)
	if v9_.sleepingTrigger ~= nil then
		if not CollisionFlag.getHasMaskFlagSet(v9_.sleepingTrigger, CollisionFlag.PLAYER) then
			Logging.warning("%s sleep trigger \'%s\' does not have \'TRIGGER_PLAYER\' bit (%s) set", self.configFileName, "placeable.farmhouse.sleeping#triggerNode", CollisionFlag.getBit(CollisionFlag.PLAYER))
		end
		addTrigger(v9_.sleepingTrigger, "farmhouseSleepingTriggerCallback", self)
	end
	local v10_ = self.xmlFile:getValue("placeable.farmhouse.sleeping#cameraNode", nil, self.components, self.i3dMappings)
	if v10_ then
		if getHasClassId(v10_, ClassIds.CAMERA) then
			v9_.sleepingCamera = v10_
			g_cameraManager:addCamera(v10_, nil, false)
		else
			Logging.xmlError(self.xmlFile, "Sleeping camera node \'%s\' (%s) is not a camera!", getName(v10_), "placeable.farmhouse.sleeping#cameraNode")
		end
	end
	v9_.isFreeForAll = self.xmlFile:getValue("placeable.farmhouse.sleeping#isFreeForAll", false)
	v9_.isFinalized = self.xmlFile:getBool("placeable.farmhouse#isFinalized", true)
end

-- Local values: spec, isFreeForAll
function PlaceableFarmhouse:loadFromXMLFile(xmlFile, key)
	local v14_ = self.spec_farmhouse
	local v15_ = xmlFile:getValue(key .. "#isFreeForAll")
	if v15_ ~= nil then
		v14_.isFreeForAll = v15_
	end
end

function PlaceableFarmhouse:saveToXMLFile(xmlFile, key, usedModNames)
	xmlFile:setValue(key .. "#isFreeForAll", self.spec_farmhouse.isFreeForAll)
end

-- Local values: spec
function PlaceableFarmhouse:onFinalizePlacement()
	if self.spec_farmhouse.isFinalized then
		g_currentMission.placeableSystem:addFarmhouse(self)
	end
end

-- Local values: spec
function PlaceableFarmhouse:finalizeConstruction(superFunc)
	superFunc(self)
	self.spec_farmhouse.isFinalized = true
	if self.propertyState ~= PlaceablePropertyState.CONSTRUCTION_PREVIEW then
		g_currentMission.placeableSystem:addFarmhouse(self)
	end
end

-- Local values: spec
function PlaceableFarmhouse:onDelete()
	local v23_ = self.spec_farmhouse
	g_currentMission.activatableObjectsSystem:removeActivatable(v23_.activatable)
	g_currentMission.placeableSystem:removeFarmhouse(self)
	if v23_.sleepingTrigger ~= nil then
		removeTrigger(v23_.sleepingTrigger)
	end
	if v23_.sleepingCamera ~= nil then
		g_cameraManager:removeCamera(v23_.sleepingCamera)
	end
end

-- Local values: spec
function PlaceableFarmhouse:getSpawnPoint()
	local v25_ = self.spec_farmhouse
	if v25_.isFinalized then
		return v25_.spawnNode
	else
		return nil
	end
end

-- Local values: spec
function PlaceableFarmhouse:getSpawnWorldPosition()
	local v27_ = self.spec_farmhouse
	if v27_.isFinalized then
		return getWorldTranslation(v27_.spawnNode)
	else
		return nil
	end
end

function PlaceableFarmhouse:getSleepCamera()
	return self.spec_farmhouse.sleepingCamera
end

function PlaceableFarmhouse:getIsAllowedToSleep(playerFarmId)
	if g_guidedTourManager:getIsTourRunning() then
		return false
	else
		return playerFarmId == self:getOwnerFarmId() and true or (self.spec_farmhouse.isFreeForAll and true or false)
	end
end

-- Local values: spec
function PlaceableFarmhouse:farmhouseSleepingTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if (onEnter or onLeave) and (g_localPlayer ~= nil and otherActorId == g_localPlayer.rootNode) then
		local v35_ = self.spec_farmhouse
		if onEnter then
			g_currentMission.activatableObjectsSystem:addActivatable(v35_.activatable)
			return
		end
		g_currentMission.activatableObjectsSystem:removeActivatable(v35_.activatable)
	end
end
