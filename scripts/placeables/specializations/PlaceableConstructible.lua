PlaceableConstructible = {}
source("dataS/scripts/placeables/specializations/constructible/ConstructibleStateEvent.lua")
source("dataS/scripts/placeables/specializations/constructible/ConstructibleState.lua")
source("dataS/scripts/placeables/specializations/constructible/ConstructibleStateBuilding.lua")
source("dataS/scripts/placeables/specializations/constructible/ConstructibleStateFinalize.lua")

function PlaceableConstructible.prerequisitesPresent(specializations)
	return true
end

function PlaceableConstructible.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "setConstructibleState", PlaceableConstructible.setConstructibleState)
	SpecializationUtil.registerFunction(placeableType, "finalizeConstruction", PlaceableConstructible.finalizeConstruction)
	SpecializationUtil.registerFunction(placeableType, "getConstructibleFillLevel", PlaceableConstructible.getConstructibleFillLevel)
	SpecializationUtil.registerFunction(placeableType, "getConstructibleSupportsFillType", PlaceableConstructible.getConstructibleSupportsFillType)
	SpecializationUtil.registerFunction(placeableType, "removeConstructibleFillLevel", PlaceableConstructible.removeConstructibleFillLevel)
	SpecializationUtil.registerFunction(placeableType, "getConstructibleStateIndexByName", PlaceableConstructible.getConstructibleStateIndexByName)
	SpecializationUtil.registerFunction(placeableType, "setConstructiblePreviewState", PlaceableConstructible.setConstructiblePreviewState)
	SpecializationUtil.registerFunction(placeableType, "getConstructibleStateIndex", PlaceableConstructible.getConstructibleStateIndex)
	SpecializationUtil.registerFunction(placeableType, "resetConstructibleToState", PlaceableConstructible.resetConstructibleToState)
	SpecializationUtil.registerFunction(placeableType, "consoleCommandFinishConstructionState", PlaceableConstructible.consoleCommandFinishConstructionState)
	SpecializationUtil.registerFunction(placeableType, "getNumFinishedConstructibleStates", PlaceableConstructible.getNumFinishedConstructibleStates)
end

function PlaceableConstructible.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableConstructible.collectPickObjects)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableConstructible.updateInfo)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableConstructible.setOwnerFarmId)
end

function PlaceableConstructible.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableConstructible)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableConstructible)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableConstructible)
	SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableConstructible)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableConstructible)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableConstructible)
	SpecializationUtil.registerEventListener(placeableType, "onReadUpdateStream", PlaceableConstructible)
	SpecializationUtil.registerEventListener(placeableType, "onWriteUpdateStream", PlaceableConstructible)
	SpecializationUtil.registerEventListener(placeableType, "onInfoTriggerEnter", PlaceableConstructible)
	SpecializationUtil.registerEventListener(placeableType, "onInfoTriggerLeave", PlaceableConstructible)
end

function PlaceableConstructible.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Constructible")
	schema:register(XMLValueType.STRING, basePath .. ".constructible.stateMachine.states.state(?)#name", "State name")
	schema:register(XMLValueType.STRING, basePath .. ".constructible.stateMachine.states.state(?)#class", "State class")
	schema:register(XMLValueType.BOOL, basePath .. ".constructible.stateMachine.states.state(?)#isStartState", "Marks a state as starting state")
	schema:register(XMLValueType.BOOL, basePath .. ".constructible.stateMachine.states.state(?)#isPreviewState", "State is shown while placing the placeable or used in the icon generator")
	ConstructibleState.registerXMLPaths(schema, basePath .. ".constructible.stateMachine.states.state(?)")
	ConstructibleStateBuilding.registerXMLPaths(schema, basePath .. ".constructible.stateMachine.states.state(?)")
	ConstructibleStateFinalize.registerXMLPaths(schema, basePath .. ".constructible.stateMachine.states.state(?)")
	schema:register(XMLValueType.STRING, basePath .. ".constructible.stateMachine.transitions.transition(?)#from", "State name from")
	schema:register(XMLValueType.STRING, basePath .. ".constructible.stateMachine.transitions.transition(?)#to", "State name to")
	SellingStation.registerXMLPaths(schema, basePath .. ".constructible.sellingStation")
	Storage.registerXMLPaths(schema, basePath .. ".constructible.storage")
	schema:setXMLSpecializationType()
end

function PlaceableConstructible.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. ".state#index", "")
	schema:register(XMLValueType.STRING, basePath .. ".state#name", "")
	ConstructibleStateBuilding.registerSavegameXMLPaths(schema, basePath)
	Storage.registerSavegameXMLPaths(schema, basePath .. ".storage")
end

-- Local values: spec, maxNumStates, dirtyFlags, maxNumDirtyFlags, stateMachineNextIndex, _, stateKey, stateName, stateClassName, class, stateIndex, dirtyFlagIndex, dirtyFlag, state, _, transitionKey, stateFromName, stateFromIndex, stateToName, stateToIndex
function PlaceableConstructible:onLoad(savegame)
	local v9_ = self.spec_constructible
	v9_.unloadingStation = SellingStation.new(self.isServer, self.isClient)
	v9_.unloadingStation:load(self.components, self.xmlFile, "placeable.constructible.sellingStation", self.customEnvironment, self.i3dMappings, self.components[1].node)
	v9_.unloadingStation.owningPlaceable = self
	function v9_.unloadingStation.getStoreGoods(_, _, _)
		return true
	end
	function v9_.unloadingStation.getSkipSell(_, _, _)
		-- upvalues: (copy) self
		return self:getOwnerFarmId() ~= AccessHandler.EVERYONE
	end
	v9_.unloadingStation:register(true)
	v9_.storage = Storage.new(self.isServer, self.isClient)
	v9_.storage:load(self.components, self.xmlFile, "placeable.constructible.storage", self.i3dMappings, self.baseDirectory)
	v9_.storage:register(true)
	v9_.storage:addFillLevelChangedListeners(function()
		-- upvalues: (copy) self
		self:raiseActive()
	end)
	v9_.fillTypesAndLevelsAuxiliary = {}
	v9_.fillTypeToFillTypeStorageTable = {}
	v9_.infoTriggerFillTypesAndLevels = {}
	v9_.infoTableEntryStorage = {
		["title"] = g_i18n:getText("statistic_storage"),
		["accentuate"] = true
	}
	v9_.unloadingStation:addTargetStorage(v9_.storage)
	g_currentMission.storageSystem:addUnloadingStation(v9_.unloadingStation, self)
	g_currentMission.economyManager:addSellingStation(v9_.unloadingStation)
	v9_.stateMachine = {}
	v9_.stateNameToIndex = {}
	v9_.stateTransitions = {}
	v9_.stateIndex = -1
	v9_.startStateIndex = 1
	v9_.previewStateIndex = 1
	v9_.statesDirtyMask = 0
	local v10_ = 255
	local v11_ = 1
	local v12_ = {}
	local v13_ = 10
	for _, v14_ in self.xmlFile:iterator("placeable.constructible.stateMachine.states.state") do
		if v10_ < v11_ then
			Logging.xmlWarning(self.xmlFile, "Maximum number of states reached (%d)", 255)
			break
		end
		local v15_ = string.upper(self.xmlFile:getValue(v14_ .. "#name", ""))
		if v9_.stateNameToIndex[v15_] ~= nil then
			Logging.xmlError(self.xmlFile, "State \'%s\' already defined", v15_, v14_)
			break
		end
		local v16_ = self.xmlFile:getValue(v14_ .. "#class", "")
		local v17_ = ClassUtil.getClassObject(v16_)
		if v17_ == nil then
			Logging.xmlError(self.xmlFile, "State class \'%s\' at \'%s\' not defined", v16_, v14_)
			break
		end
		if not v17_:isa(ConstructibleState) then
			Logging.xmlError(self.xmlFile, "State class \'%s\' is not a ConstructibleState at \'%s\'", v16_, v14_)
			break
		end
		if #v12_ < v13_ then
			table.insert(v12_, self:getNextDirtyFlag())
		end
		v9_.stateNameToIndex[v15_] = v11_
		local v18_ = v12_[(v11_ - 1) % 10 + 1]
		local v19_ = v17_.new(self, v18_)
		v19_:load(self.xmlFile, v14_)
		v9_.stateMachine[v11_] = v19_
		local v20_ = v9_.statesDirtyMask
		v9_.statesDirtyMask = bit32.bor(v20_, v18_)
		if self.xmlFile:getValue(v14_ .. "#isStartState") then
			v9_.startStateIndex = v11_
		end
		if self.xmlFile:getValue(v14_ .. "#isPreviewState") then
			v9_.previewStateIndex = v11_
		end
		v11_ = v11_ + 1
	end
	for _, v21_ in self.xmlFile:iterator("placeable.constructible.stateMachine.transitions.transition") do
		local v22_ = string.upper(self.xmlFile:getValue(v21_ .. "#from", ""))
		local v23_ = v9_.stateNameToIndex[v22_]
		if v23_ == nil then
			Logging.xmlError(self.xmlFile, "Invalid state. Transition from name \'%s\' not defined for \'%s\'", v22_, v21_)
			break
		end
		local v24_ = string.upper(self.xmlFile:getValue(v21_ .. "#to", ""))
		local v25_ = v9_.stateNameToIndex[v24_]
		if v25_ == nil then
			Logging.xmlError(self.xmlFile, "Invalid state. Transition to name \'%s\' not defined for \'%s\'", v24_, v21_)
			break
		end
		v9_.stateTransitions[v23_] = v25_
	end
	if self.propertyState == PlaceablePropertyState.CONSTRUCTION_PREVIEW then
		self:setConstructiblePreviewState()
	end
end

-- Local values: spec, farmId, i
function PlaceableConstructible:onFinalizePlacement(savegame)
	local v27_ = self.spec_constructible
	local v28_ = self:getOwnerFarmId()
	if v27_.unloadingStation ~= nil then
		v27_.unloadingStation:setOwnerFarmId(v28_, true)
	end
	if v27_.storage ~= nil then
		v27_.storage:setOwnerFarmId(v28_, true)
	end
	if self.isServer then
		if v27_.stateIndexPending == nil then
			self:setConstructibleState(v27_.startStateIndex)
		else
			for v29_ = 1, v27_.stateIndexPending do
				self:setConstructibleState(v29_)
			end
			if v27_.postFinalize ~= nil then
				v27_.postFinalize()
			end
			v27_.stateIndexPending = nil
			v27_.postFinalize = nil
		end
		self:raiseActive()
	end
end

-- Local values: spec, _, state
function PlaceableConstructible:onDelete()
	local v31_ = self.spec_constructible
	removeConsoleCommand("gsConstructibleFinishState")
	g_messageCenter:unsubscribeAll(self)
	if v31_.unloadingStation ~= nil then
		g_currentMission.storageSystem:removeUnloadingStation(v31_.unloadingStation, self)
		g_currentMission.economyManager:removeSellingStation(v31_.unloadingStation)
		v31_.unloadingStation:delete()
		v31_.unloadingStation = nil
	end
	if v31_.storage ~= nil then
		v31_.storage:delete()
		v31_.storage = nil
	end
	if v31_.stateMachine ~= nil then
		for _, v32_ in ipairs(v31_.stateMachine) do
			v32_:delete()
		end
		v31_.stateMachine = nil
	end
end

-- Local values: spec, i, unloadTrigger
function PlaceableConstructible:collectPickObjects(superFunc, node)
	local v36_ = self.spec_constructible
	for v37_ = 1, #v36_.unloadingStation.unloadTriggers do
		if node == v36_.unloadingStation.unloadTriggers[v37_].exactFillRootNode then
			return
		end
	end
	superFunc(self, node)
end

-- Local values: spec, state
function PlaceableConstructible:saveToXMLFile(xmlFile, key, usedModNames)
	local v42_ = self.spec_constructible
	if v42_.stateIndex ~= nil and v42_.stateIndex > 0 then
		local v43_ = v42_.stateMachine[v42_.stateIndex]
		xmlFile:setValue(key .. ".state#name", v43_.name)
		v43_:saveToXMLFile(xmlFile, key, usedModNames)
	end
	v42_.storage:saveToXMLFile(xmlFile, key .. ".storage")
end

-- Local values: spec, stateName
function PlaceableConstructible:loadFromXMLFile(xmlFile, key)
	local v_u_47_ = self.spec_constructible
	local v48_ = xmlFile:getValue(key .. ".state#name")
	v_u_47_.stateIndexPending = v_u_47_.stateNameToIndex[v48_] or 1
	function v_u_47_.postFinalize()
		-- upvalues: (copy) v_u_47_, (copy) xmlFile, (copy) key
		v_u_47_.stateMachine[v_u_47_.stateIndexPending]:loadFromXMLFile(xmlFile, key)
	end
	v_u_47_.storage:loadFromXMLFile(xmlFile, key .. ".storage")
end

-- Local values: spec, unloadingStationId, storageId, stateIndex, i, state
function PlaceableConstructible:onReadStream(streamId, connection)
	local v52_ = self.spec_constructible
	local v53_ = NetworkUtil.readNodeObjectId(streamId)
	v52_.unloadingStation:readStream(streamId, connection)
	g_client:finishRegisterObject(v52_.unloadingStation, v53_)
	local v54_ = NetworkUtil.readNodeObjectId(streamId)
	v52_.storage:readStream(streamId, connection)
	g_client:finishRegisterObject(v52_.storage, v54_)
	local v55_ = streamReadUInt8(streamId)
	for v56_ = 1, v55_ do
		self:setConstructibleState(v56_)
	end
	v52_.stateMachine[v55_]:onReadStream(streamId, connection)
end

-- Local values: spec, state
function PlaceableConstructible:onWriteStream(streamId, connection)
	local v60_ = self.spec_constructible
	NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v60_.unloadingStation))
	v60_.unloadingStation:writeStream(streamId, connection)
	g_server:registerObjectInStream(connection, v60_.unloadingStation)
	NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v60_.storage))
	v60_.storage:writeStream(streamId, connection)
	g_server:registerObjectInStream(connection, v60_.storage)
	streamWriteUInt8(streamId, v60_.stateIndex)
	v60_.stateMachine[v60_.stateIndex]:onWriteStream(streamId, connection)
end

-- Local values: spec, _, state
function PlaceableConstructible:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local v65_ = self.spec_constructible
		if streamReadBool(streamId) then
			for _, v66_ in ipairs(v65_.stateMachine) do
				if streamReadBool(streamId) then
					v66_:onReadUpdateStream(streamId, timestamp, connection)
				end
			end
		end
	end
end

-- Local values: spec, _, state
function PlaceableConstructible:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v71_ = self.spec_constructible
		local v72_ = streamWriteBool
		local v73_ = v71_.statesDirtyMask
		if v72_(streamId, bit32.band(dirtyMask, v73_) ~= 0) then
			for _, v74_ in ipairs(v71_.stateMachine) do
				local v75_ = streamWriteBool
				local v76_ = v74_.dirtyFlag
				if v75_(streamId, bit32.band(dirtyMask, v76_) ~= 0) then
					v74_:onWriteUpdateStream(streamId, connection, dirtyMask)
				end
			end
		end
	end
end

-- Local values: spec, state, nextStateIndex
function PlaceableConstructible:onUpdate(dt)
	local v79_ = self.spec_constructible
	if self.isServer then
		local v80_ = v79_.stateMachine[v79_.stateIndex]
		if v80_ ~= nil then
			if v80_:isDone() then
				self:setConstructibleState(v79_.stateTransitions[v79_.stateIndex])
				v80_ = v79_.stateMachine[v79_.stateIndex]
				self:raiseActive()
			elseif v80_:raiseActive() then
				self:raiseActive()
			end
			if v80_ ~= nil then
				v80_:update(dt)
			end
		end
	end
end

-- Local values: spec, i, state
function PlaceableConstructible:resetConstructibleToState(stateIndex)
	local v83_ = self.spec_constructible
	for v84_ = v83_.stateIndex, stateIndex, -1 do
		v83_.stateMachine[v84_]:reset()
	end
	self:setConstructibleState(stateIndex)
	v83_.storage:empty()
	g_currentMission.storageSystem:addUnloadingStation(v83_.unloadingStation, self)
	g_currentMission.economyManager:addSellingStation(v83_.unloadingStation)
end

-- Local values: spec
function PlaceableConstructible:getConstructibleStateIndex()
	return self.spec_constructible.stateIndex
end

-- Local values: spec
function PlaceableConstructible:getConstructibleStateIndexByName(name)
	return self.spec_constructible.stateNameToIndex[string.upper(name)]
end

-- Local values: i
function PlaceableConstructible:setConstructiblePreviewState()
	for v89_ = 1, self.spec_constructible.previewStateIndex do
		self:setConstructibleState(v89_)
	end
end

-- Local values: spec, oldStateIndex, oldState, state
function PlaceableConstructible:setConstructibleState(newStateIndex)
	local v92_ = self.spec_constructible
	if self.isServer and self.propertyState ~= PlaceablePropertyState.CONSTRUCTION_PREVIEW then
		g_server:broadcastEvent(ConstructibleStateEvent.new(self, newStateIndex), false)
	end
	if newStateIndex ~= v92_.stateIndex then
		local v93_ = v92_.stateIndex
		v92_.stateIndex = newStateIndex
		local v94_ = v92_.stateMachine[v93_]
		local v95_ = v92_.stateMachine[newStateIndex]
		if v94_ ~= nil then
			v94_:deactivate()
		end
		if v95_ ~= nil then
			v95_:activate()
			return
		end
		Logging.devWarning("PlaceableConstructible:setConstructibleState(): unable to get state for given state index %s for %q", newStateIndex, self.configFileName)
	end
end

-- Local values: spec
function PlaceableConstructible:finalizeConstruction()
	local v97_ = self.spec_constructible
	v97_.storage:empty()
	g_currentMission.storageSystem:removeUnloadingStation(v97_.unloadingStation, self)
	g_currentMission.economyManager:removeSellingStation(v97_.unloadingStation)
end

-- Local values: spec, finishedStates, numConstructibleStates, fillType, fillLevel, fillType, fillLevel, numEntries, i, fillTypeAndLevel, state
function PlaceableConstructible:updateInfo(superFunc, infoTable)
	superFunc(self, infoTable)
	local v101_ = self.spec_constructible
	local v102_, v103_ = self:getNumFinishedConstructibleStates()
	if v102_ < v103_ then
		local v104_ = {
			["title"] = g_i18n:getText("ui_construction_state"),
			["text"] = string.format("(%d / %d)", v102_, v103_)
		}
		table.insert(infoTable, v104_)
	end
	v101_.fillTypesAndLevelsAuxiliary = {}
	for v105_, v106_ in pairs(v101_.storage:getFillLevels()) do
		v101_.fillTypesAndLevelsAuxiliary[v105_] = (v101_.fillTypesAndLevelsAuxiliary[v105_] or 0) + v106_
	end
	table.clear(v101_.infoTriggerFillTypesAndLevels)
	for v107_, v108_ in pairs(v101_.fillTypesAndLevelsAuxiliary) do
		if v108_ > 0.1 then
			local v109_ = v101_.fillTypeToFillTypeStorageTable
			local v110_ = v101_.fillTypeToFillTypeStorageTable[v107_]
			if not v110_ then
				v110_ = {
					["fillType"] = v107_,
					["fillLevel"] = v108_
				}
			end
			v109_[v107_] = v110_
			v101_.fillTypeToFillTypeStorageTable[v107_].fillLevel = v108_
			local v111_ = v101_.infoTriggerFillTypesAndLevels
			local v112_ = v101_.fillTypeToFillTypeStorageTable[v107_]
			table.insert(v111_, v112_)
		end
	end
	table.clear(v101_.fillTypesAndLevelsAuxiliary)
	table.sort(v101_.infoTriggerFillTypesAndLevels, function(p113_, p114_)
		return p113_.fillLevel > p114_.fillLevel
	end)
	local v115_ = #v101_.infoTriggerFillTypesAndLevels
	local v116_ = math.min(v115_, 7)
	if v116_ > 0 then
		local v117_ = v101_.infoTableEntryStorage
		table.insert(infoTable, v117_)
		for v118_ = 1, v116_ do
			local v119_ = v101_.infoTriggerFillTypesAndLevels[v118_]
			local v120_ = {
				["title"] = g_fillTypeManager:getFillTypeTitleByIndex(v119_.fillType),
				["text"] = g_i18n:formatVolume(v119_.fillLevel, 0)
			}
			table.insert(infoTable, v120_)
		end
	end
	local v121_ = v101_.stateMachine[v101_.stateIndex]
	if v121_.updateInfo ~= nil then
		v121_:updateInfo(infoTable)
	end
end

-- Local values: spec
function PlaceableConstructible:getConstructibleFillLevel(fillType)
	return self.spec_constructible.storage:getFillLevel(fillType)
end

-- Local values: spec
function PlaceableConstructible:getConstructibleSupportsFillType(fillType)
	return self.spec_constructible.storage:getIsFillTypeSupported(fillType)
end

-- Local values: spec, previousFillLevel
function PlaceableConstructible:removeConstructibleFillLevel(fillType, amount)
	local v129_ = self.spec_constructible
	local v130_ = v129_.storage:getFillLevel(fillType)
	v129_.storage:setFillLevel(v130_ - amount, fillType)
	return v130_ - v129_.storage:getFillLevel(fillType)
end

-- Local values: spec
function PlaceableConstructible:setOwnerFarmId(superFunc, farmId, noEventSend)
	superFunc(self, farmId, noEventSend)
	local v135_ = self.spec_constructible
	if v135_ ~= nil then
		if v135_.unloadingStation ~= nil then
			v135_.unloadingStation:setOwnerFarmId(farmId, true)
		end
		if v135_.storage ~= nil then
			v135_.storage:setOwnerFarmId(farmId, true)
		end
	end
end

-- Local values: spec
function PlaceableConstructible:onInfoTriggerEnter(nodeId)
	if self.spec_constructible ~= nil then
		addConsoleCommand("gsConstructibleFinishState", "Finishes current construction state", "consoleCommandFinishConstructionState", self)
	end
end

-- Local values: spec
function PlaceableConstructible:onInfoTriggerLeave(nodeId)
	if self.spec_constructible ~= nil then
		removeConsoleCommand("gsConstructibleFinishState")
	end
end

-- Local values: spec, nextStateIndex
function PlaceableConstructible:consoleCommandFinishConstructionState()
	local v139_ = self.spec_constructible
	if v139_ ~= nil then
		local v140_ = v139_.stateTransitions[v139_.stateIndex]
		if v140_ ~= nil then
			self:setConstructibleState(v140_)
			self:raiseActive()
			return
		end
		Logging.info("No next state found")
	end
end

-- Local values: spec, numConstructibleStates, finishedStates, i, state
function PlaceableConstructible:getNumFinishedConstructibleStates()
	local v142_ = self.spec_constructible
	local v143_ = 0
	local v144_ = -2
	for v145_, v146_ in ipairs(v142_.stateMachine) do
		if v146_:getIsConstructibleState() then
			if v145_ ~= v142_.isPreviewState then
				v144_ = v144_ + 1
			end
			if v145_ < v142_.stateIndex then
				v143_ = v143_ + 1
			end
		end
	end
	return v143_, v144_
end

-- Local values: fillTypeNames, _, stateKey, _, inputKey, fillTypeName
function PlaceableConstructible.loadSpecValueFillTypes(xmlFile, customEnvironment, baseDir, resultTable)
	if not xmlFile:hasProperty("placeable.constructible") then
		return resultTable
	end
	local v149_ = resultTable or {}
	for _, v150_ in xmlFile:iterator("placeable.constructible.stateMachine.states.state") do
		for _, v151_ in xmlFile:iterator(v150_ .. ".input") do
			v149_[xmlFile:getString(v151_ .. "#fillType")] = true
		end
	end
	return v149_
end
