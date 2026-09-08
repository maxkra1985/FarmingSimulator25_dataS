PlaceableDestructible = {}
source("dataS/scripts/placeables/specializations/activatables/DestructibleActivatable.lua")
source("dataS/scripts/placeables/specializations/events/PlaceableDestructibleRepairEvent.lua")
source("dataS/scripts/placeables/specializations/events/PlaceableDestructibleDestructedEvent.lua")

function PlaceableDestructible.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Destructible")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".destructible.trigger#node", "Trigger", nil, false)
	schema:register(XMLValueType.STRING, basePath .. ".destructible.destruct.transition(?)#from", "State name from", nil, false)
	schema:register(XMLValueType.STRING, basePath .. ".destructible.destruct.transition(?)#to", "State name to", nil, false)
	schema:register(XMLValueType.FLOAT, basePath .. ".destructible.repair#bonus", "Bonus for repairing an unowned building", nil, false)
	schema:register(XMLValueType.STRING, basePath .. ".destructible.repair.transition(?)#from", "State name from", nil, false)
	schema:register(XMLValueType.STRING, basePath .. ".destructible.repair.transition(?)#to", "State name to", nil, false)
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".destructible.sounds", "destructed")
	schema:setXMLSpecializationType()
end

function PlaceableDestructible.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. ".repairingFarm#id", "")
end

function PlaceableDestructible.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(PlaceableConstructible, specializations)
end

function PlaceableDestructible.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "destruct", PlaceableDestructible.destruct)
	SpecializationUtil.registerFunction(placeableType, "destructed", PlaceableDestructible.destructed)
	SpecializationUtil.registerFunction(placeableType, "startRepairDestructible", PlaceableDestructible.startRepairDestructible)
	SpecializationUtil.registerFunction(placeableType, "getCanRepairDestructible", PlaceableDestructible.getCanRepairDestructible)
	SpecializationUtil.registerFunction(placeableType, "onDestructibleTriggerCallback", PlaceableDestructible.onDestructibleTriggerCallback)
	SpecializationUtil.registerFunction(placeableType, "getCanBeDestructedByTwister", PlaceableDestructible.getCanBeDestructedByTwister)
	SpecializationUtil.registerFunction(placeableType, "startedRepairDestructible", PlaceableDestructible.startedRepairDestructible)
end

function PlaceableDestructible.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "finalizeConstruction", PlaceableDestructible.finalizeConstruction)
end

function PlaceableDestructible.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableDestructible)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableDestructible)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableDestructible)
end

-- Local values: spec, _, transitionKey, stateFromName, stateFromIndex, stateToName, stateToIndex, _, transitionKey, stateFromName, stateFromIndex, stateToName, stateToIndex
function PlaceableDestructible:onLoad(savegame)
	local v10_ = self.spec_destructible
	v10_.destructTransitions = {}
	for _, v11_ in self.xmlFile:iterator("placeable.destructible.destruct.transition") do
		local v12_ = self.xmlFile:getValue(v11_ .. "#from", "")
		local v13_ = self:getConstructibleStateIndexByName(v12_)
		if v13_ == nil then
			Logging.xmlError(self.xmlFile, "Invalid state. Transition from name \'%s\' not defined for \'%s\'", v12_, v11_)
			break
		end
		local v14_ = self.xmlFile:getValue(v11_ .. "#to", "")
		local v15_ = self:getConstructibleStateIndexByName(v14_)
		if v15_ == nil then
			Logging.xmlError(self.xmlFile, "Invalid state. Transition to name \'%s\' not defined for \'%s\'", v14_, v11_)
			break
		end
		v10_.destructTransitions[v13_] = v15_
	end
	v10_.repairTransitions = {}
	for _, v16_ in self.xmlFile:iterator("placeable.destructible.repair.transition") do
		local v17_ = self.xmlFile:getValue(v16_ .. "#from", "")
		local v18_ = self:getConstructibleStateIndexByName(v17_)
		if v18_ == nil then
			Logging.xmlError(self.xmlFile, "Invalid state. Transition from name \'%s\' not defined for \'%s\'", v17_, v16_)
			break
		end
		local v19_ = self.xmlFile:getValue(v16_ .. "#to", "")
		local v20_ = self:getConstructibleStateIndexByName(v19_)
		if v20_ == nil then
			Logging.xmlError(self.xmlFile, "Invalid state. Transition to name \'%s\' not defined for \'%s\'", v19_, v16_)
			break
		end
		v10_.repairTransitions[v18_] = v20_
	end
	v10_.repairBonus = self.xmlFile:getValue("placeable.destructible.repair#bonus", nil)
	v10_.triggerNode = self.xmlFile:getValue("placeable.destructible.trigger#node", nil, self.components, self.i3dMappings)
	if v10_.triggerNode ~= nil and not CollisionFlag.getHasMaskFlagSet(v10_.triggerNode, CollisionFlag.PLAYER) then
		Logging.xmlWarning(self.xmlFile, "Trigger collision mask is missing bit \'TRIGGER_PLAYER\' (%d)", CollisionFlag.getBit(CollisionFlag.PLAYER))
	end
	if self.isClient then
		v10_.samples = {}
		v10_.samples.destructed = g_soundManager:loadSampleFromXML(self.xmlFile, "placeable.destructible.sounds", "destructed", self.baseDirectory, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
	end
	v10_.activatable = DestructibleActivatable.new(self)
end

-- Local values: spec
function PlaceableDestructible:onDelete()
	local v22_ = self.spec_destructible
	g_currentMission.activatableObjectsSystem:removeActivatable(v22_.activatable)
	if v22_.triggerNode ~= nil then
		removeTrigger(v22_.triggerNode)
		v22_.triggerNode = nil
	end
	g_soundManager:deleteSamples(v22_.samples)
end

-- Local values: spec
function PlaceableDestructible:onFinalizePlacement()
	local v24_ = self.spec_destructible
	if v24_.triggerNode ~= nil then
		addTrigger(v24_.triggerNode, "onDestructibleTriggerCallback", self)
	end
end

-- Local values: spec
function PlaceableDestructible:saveToXMLFile(xmlFile, key, usedModNames)
	local v28_ = self.spec_destructible
	if v28_.repairingFarmId ~= nil then
		xmlFile:setValue(key .. ".repairingFarm#id", v28_.repairingFarmId)
	end
end

-- Local values: spec, farmId, farm
function PlaceableDestructible:loadFromXMLFile(xmlFile, key)
	local v32_ = self.spec_destructible
	local v33_ = xmlFile:getValue(key .. ".repairingFarm#id")
	if v33_ ~= nil then
		if g_farmManager:getFarmById(v33_) ~= nil then
			v32_.repairingFarmId = v33_
			return
		end
		Logging.warning(xmlFile, "Repairing farm (Id \'%s\') does not exist anymore. Ignoring it in \'%s\'", v33_, key)
	end
end

-- Local values: spec, stateIndex
function PlaceableDestructible:getCanBeDestructedByTwister()
	local v35_ = self.spec_destructible
	local v36_ = self:getConstructibleStateIndex()
	return v35_.destructTransitions[v36_] ~= nil
end

-- Local values: spec
function PlaceableDestructible:destructed()
	local v38_ = self.spec_destructible
	if v38_.samples ~= nil then
		if g_soundManager:getIsSamplePlaying(v38_.samples.destructed) then
			g_soundManager:stopSample(v38_.samples.destructed)
		end
		g_soundManager:playSample(v38_.samples.destructed, 1)
	end
end

-- Local values: spec, stateIndex, newStateIndex
function PlaceableDestructible:destruct()
	local v40_ = self.isServer
	assert(v40_, "PlaceableDestructible.destruct is a server-only function")
	local v41_ = self.spec_destructible
	local v42_ = self:getConstructibleStateIndex()
	local v43_ = v41_.destructTransitions[v42_]
	if v43_ == nil then
		return false
	end
	self:setConstructibleState(v43_)
	g_server:broadcastEvent(PlaceableDestructibleDestructedEvent.new(self), true)
	return true
end

function PlaceableDestructible:startedRepairDestructible(wasSuccessful)
	if wasSuccessful then
		InfoDialog.show(g_i18n:getText("action_destructibleStartRepairing_successful"))
	else
		InfoDialog.show(g_i18n:getText("action_destructibleStartRepairing_failed"))
	end
end

-- Local values: ownerFarmId, owned, spec, stateIndex, newStateIndex
function PlaceableDestructible:startRepairDestructible(farmId)
	local v47_ = self:getOwnerFarmId()
	local v48_
	if v47_ == AccessHandler.EVERYONE then
		v48_ = false
	else
		if v47_ ~= farmId then
			return false
		end
		v48_ = true
	end
	local v49_ = self.spec_destructible
	local v50_ = self:getConstructibleStateIndex()
	local v51_ = v49_.repairTransitions[v50_]
	if v51_ == nil then
		return false
	end
	self:resetConstructibleToState(v51_)
	if self.isServer and not v48_ then
		v49_.repairingFarmId = farmId
	end
	return true
end

-- Local values: spec, stateIndex, ownerFarmId
function PlaceableDestructible:getCanRepairDestructible(farmId)
	local v54_ = self.spec_destructible
	local v55_ = self:getConstructibleStateIndex()
	if v54_.repairTransitions[v55_] == nil then
		return false
	end
	local v56_ = self:getOwnerFarmId()
	return v56_ == AccessHandler.EVERYONE and true or v56_ == farmId
end

-- Local values: spec
function PlaceableDestructible:finalizeConstruction(superFunc)
	local v58_ = self.spec_destructible
	if self.isServer and (v58_.repairingFarmId ~= nil and v58_.repairBonus ~= nil) then
		g_currentMission:addMoney(v58_.repairBonus, v58_.repairingFarmId, MoneyType.MISSIONS, false, true)
	end
	v58_.repairingFarmId = nil
end

-- Local values: spec
function PlaceableDestructible:onDestructibleTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay)
	if (onEnter or onLeave) and (g_localPlayer ~= nil and otherActorId == g_localPlayer.rootNode) then
		local v63_ = self.spec_destructible
		if onEnter then
			g_currentMission.activatableObjectsSystem:addActivatable(v63_.activatable)
			return
		end
		g_currentMission.activatableObjectsSystem:removeActivatable(v63_.activatable)
	end
end
