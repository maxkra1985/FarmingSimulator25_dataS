PlaceableBoatyard = {}
source("dataS/scripts/placeables/specializations/boatyard/BoatyardActivatable.lua")
source("dataS/scripts/placeables/specializations/boatyard/BoatyardState.lua")
source("dataS/scripts/placeables/specializations/boatyard/BoatyardStateBuilding.lua")
source("dataS/scripts/placeables/specializations/boatyard/BoatyardStateEvent.lua")
source("dataS/scripts/placeables/specializations/boatyard/BoatyardStateSetup.lua")
source("dataS/scripts/placeables/specializations/boatyard/BoatyardStateLaunching.lua")
source("dataS/scripts/placeables/specializations/boatyard/BoatyardStateMoving.lua")
source("dataS/scripts/placeables/specializations/boatyard/BoatyardStateRelease.lua")

function PlaceableBoatyard.prerequisitesPresent(specializations)
	return true
end

function PlaceableBoatyard.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "onBoatI3DFileLoaded", PlaceableBoatyard.onBoatI3DFileLoaded)
	SpecializationUtil.registerFunction(placeableType, "setMeshProgress", PlaceableBoatyard.setMeshProgress)
	SpecializationUtil.registerFunction(placeableType, "setState", PlaceableBoatyard.setState)
	SpecializationUtil.registerFunction(placeableType, "setSplineTime", PlaceableBoatyard.setSplineTime)
	SpecializationUtil.registerFunction(placeableType, "addSplineDistanceDelta", PlaceableBoatyard.addSplineDistanceDelta)
	SpecializationUtil.registerFunction(placeableType, "getSplineTime", PlaceableBoatyard.getSplineTime)
	SpecializationUtil.registerFunction(placeableType, "releaseBoat", PlaceableBoatyard.releaseBoat)
	SpecializationUtil.registerFunction(placeableType, "createBoat", PlaceableBoatyard.createBoat)
	SpecializationUtil.registerFunction(placeableType, "setWindValues", PlaceableBoatyard.setWindValues)
	SpecializationUtil.registerFunction(placeableType, "getFillLevel", PlaceableBoatyard.getFillLevel)
	SpecializationUtil.registerFunction(placeableType, "removeFillLevel", PlaceableBoatyard.removeFillLevel)
	SpecializationUtil.registerFunction(placeableType, "playerTriggerCallback", PlaceableBoatyard.playerTriggerCallback)
	SpecializationUtil.registerFunction(placeableType, "buyRequest", PlaceableBoatyard.buyRequest)
end

function PlaceableBoatyard.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableBoatyard.collectPickObjects)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableBoatyard.updateInfo)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableBoatyard.setOwnerFarmId)
end

function PlaceableBoatyard.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableBoatyard)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableBoatyard)
	SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableBoatyard)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableBoatyard)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableBoatyard)
	SpecializationUtil.registerEventListener(placeableType, "onReadUpdateStream", PlaceableBoatyard)
	SpecializationUtil.registerEventListener(placeableType, "onWriteUpdateStream", PlaceableBoatyard)
end

function PlaceableBoatyard.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Boatyard")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".boatyard#spline", "")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".boatyard#linkNode", "")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".boatyard#playerTrigger", "")
	schema:register(XMLValueType.STRING, basePath .. ".boatyard.boat#filename", "")
	schema:register(XMLValueType.INT, basePath .. ".boatyard.boat#reward", "")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".boatyard.boat.progressiveVisibilityMesh.mesh(?)#node", "")
	schema:register(XMLValueType.STRING, basePath .. ".boatyard.boat.progressiveVisibilityMesh.mesh(?)#id", "")
	schema:register(XMLValueType.INT, basePath .. ".boatyard.boat.progressiveVisibilityMesh.mesh(?)#indexMin", "")
	schema:register(XMLValueType.INT, basePath .. ".boatyard.boat.progressiveVisibilityMesh.mesh(?)#indexMax", "")
	schema:register(XMLValueType.STRING, basePath .. ".boatyard.stateMachine.states.state(?)#name", "State name")
	schema:register(XMLValueType.STRING, basePath .. ".boatyard.stateMachine.states.state(?)#class", "State class")
	BoatyardState.registerXMLPaths(schema, basePath .. ".boatyard.stateMachine.states.state(?)")
	BoatyardStateMoving.registerXMLPaths(schema, basePath .. ".boatyard.stateMachine.states.state(?)")
	BoatyardStateBuilding.registerXMLPaths(schema, basePath .. ".boatyard.stateMachine.states.state(?)")
	BoatyardStateLaunching.registerXMLPaths(schema, basePath .. ".boatyard.stateMachine.states.state(?)")
	schema:register(XMLValueType.STRING, basePath .. ".boatyard.stateMachine.transitions.transition(?)#from", "State name from")
	schema:register(XMLValueType.STRING, basePath .. ".boatyard.stateMachine.transitions.transition(?)#to", "State name to")
	schema:register(XMLValueType.FLOAT, basePath .. ".boatyard.sailingSplines#bobbingFreq", "")
	schema:register(XMLValueType.FLOAT, basePath .. ".boatyard.sailingSplines#bobbingAmount", "")
	schema:register(XMLValueType.FLOAT, basePath .. ".boatyard.sailingSplines#swayingFreq", "")
	schema:register(XMLValueType.FLOAT, basePath .. ".boatyard.sailingSplines#swayingAmount", "")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".boatyard.sailingSplines.spline(?)#node", "")
	SellingStation.registerXMLPaths(schema, basePath .. ".boatyard.sellingStation")
	Storage.registerXMLPaths(schema, basePath .. ".boatyard.storage")
	schema:setXMLSpecializationType()
end

function PlaceableBoatyard.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. ".state#index", "")
	schema:register(XMLValueType.FLOAT, basePath .. "#splineTime", "")
	BoatyardStateBuilding.registerSavegameXMLPaths(schema, basePath)
	Storage.registerSavegameXMLPaths(schema, basePath .. ".storage")
end

-- Local values: spec, key, boatI3DFilename, arguments, maxNumStates, stateMachineXmlKey, _, stateKey, stateName, stateClassName, class, stateIndex, state, _, transitionKey, stateFromName, stateFromIndex, stateToName, stateToIndex, _, sailingSplineKey, sailingSpline, splineLength
function PlaceableBoatyard:onLoad(savegame)
	local v9_ = self.spec_boatyard
	v9_.spline = self.xmlFile:getValue("placeable.boatyard#spline", nil, self.components, self.i3dMappings)
	v9_.splineLength = getSplineLength(v9_.spline)
	v9_.splineTime = 0
	v9_.splineTimeInterpolator = InterpolationTime.new(1.2)
	v9_.splineInterpolator = InterpolatorValue.new(0)
	v9_.splineTimeDirtyFlag = self:getNextDirtyFlag()
	v9_.splineTimeChanged = false
	v9_.boatLinkNode = self.xmlFile:getValue("placeable.boatyard#linkNode", nil, self.components, self.i3dMappings)
	link(getRootNode(), v9_.boatLinkNode)
	local v10_ = self.xmlFile:getValue("placeable.boatyard.boat#filename")
	local v11_ = Utils.getFilename(v10_, self.baseDirectory)
	v9_.boatLaunchReward = self.xmlFile:getValue("placeable.boatyard.boat#reward", 100000)
	v9_.idToMesh = {}
	v9_.meshes = {}
	local v12_ = {
		["loadingTask"] = self:createLoadingTask(v9_)
	}
	v9_.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(v11_, true, false, self.onBoatI3DFileLoaded, self, v12_)
	v9_.unloadingStation = SellingStation.new(self.isServer, self.isClient)
	v9_.unloadingStation:load(self.components, self.xmlFile, "placeable.boatyard.sellingStation", self.customEnvironment, self.i3dMappings, self.components[1].node)
	v9_.unloadingStation.owningPlaceable = self
	function v9_.unloadingStation.getStoreGoods(_, _, _)
		return true
	end
	function v9_.unloadingStation.getSkipSell(_, _, _)
		-- upvalues: (copy) self
		return self:getOwnerFarmId() ~= AccessHandler.EVERYONE
	end
	function v9_.unloadingStation.getIsFillAllowedFromFarm(_, _)
		return true
	end
	v9_.unloadingStation:register(true)
	v9_.storage = Storage.new(self.isServer, self.isClient)
	v9_.storage:load(self.components, self.xmlFile, "placeable.boatyard.storage", self.i3dMappings, self.baseDirectory)
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
	v9_.playerTrigger = self.xmlFile:getValue("placeable.boatyard#playerTrigger", nil, self.components, self.i3dMappings)
	if v9_.playerTrigger ~= nil then
		addTrigger(v9_.playerTrigger, "playerTriggerCallback", self)
	end
	v9_.activatable = BoatyardActivatable.new(self)
	v9_.stateMachine = {}
	v9_.stateNameToIndex = {}
	v9_.stateTransitions = {}
	v9_.stateIndex = -1
	v9_.stateMachineNextIndex = 0
	v9_.statesDirtyMask = 0
	local v13_ = 255
	for _, v14_ in self.xmlFile:iterator("placeable.boatyard.stateMachine.states.state") do
		if v13_ < v9_.stateMachineNextIndex then
			Logging.xmlWarning(self.xmlFile, "Maximum number of states reached (%d)", 255)
			break
		end
		local v15_ = self.xmlFile:getValue(v14_ .. "#name", ""):upper()
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
		local v18_ = v9_.stateMachineNextIndex
		v9_.stateNameToIndex[v15_] = v18_
		local v19_ = v17_.new(self)
		v19_:load(self.xmlFile, v14_)
		v9_.stateMachine[v18_] = v19_
		v9_.statesDirtyMask = v9_.statesDirtyMask + v19_.dirtyFlag
		v9_.stateMachineNextIndex = v9_.stateMachineNextIndex + 1
	end
	for _, v20_ in self.xmlFile:iterator("placeable.boatyard.stateMachine.transitions.transition") do
		local v21_ = self.xmlFile:getValue(v20_ .. "#from", ""):upper()
		local v22_ = v9_.stateNameToIndex[v21_]
		if v22_ == nil then
			Logging.xmlError(self.xmlFile, "Invalid state. Transition from name \'%s\' not defined for \'%s\'", v21_, v20_)
			break
		end
		local v23_ = self.xmlFile:getValue(v20_ .. "#to", ""):upper()
		local v24_ = v9_.stateNameToIndex[v23_]
		if v24_ == nil then
			Logging.xmlError(self.xmlFile, "Invalid state. Transition to name \'%s\' not defined for \'%s\'", v23_, v20_)
			break
		end
		v9_.stateTransitions[v22_] = v24_
	end
	v9_.sailingSplines = {}
	v9_.boatBobbingFreq = self.xmlFile:getValue("placeable.boatyard.sailingSplines#bobbingFreq", 1) / 1000 / 3.141592653589793
	v9_.boatBobbingAmount = self.xmlFile:getValue("placeable.boatyard.sailingSplines#bobbingAmount", 0.05)
	v9_.boatSwayingFreq = self.xmlFile:getValue("placeable.boatyard.sailingSplines#swayingFreq", 0.8) / 1000 / 3.141592653589793
	v9_.boatSwayingAmount = self.xmlFile:getValue("placeable.boatyard.sailingSplines#swayingAmount", 0.025)
	for _, v25_ in self.xmlFile:iterator("placeable.boatyard.sailingSplines.spline") do
		local v26_ = self.xmlFile:getValue(v25_ .. "#node", nil, self.components, self.i3dMappings)
		local v27_ = getSplineLength(v26_)
		local v28_ = v9_.sailingSplines
		table.insert(v28_, {
			["node"] = v26_,
			["length"] = v27_
		})
	end
	v9_.nextSailingSplineIndex = math.random(1, #v9_.sailingSplines)
	v9_.boatsSailingLinkNode = createTransformGroup("sailingBoatsLinkNode")
	link(getRootNode(), v9_.boatsSailingLinkNode)
	v9_.boatsSailing = {}
	v9_.sailingAcc = 0.2
	v9_.windSpeed = 1
	g_currentMission.environment.weather.windUpdater:addWindChangedListener(self)
end

-- Local values: spec, components, boatKey
function PlaceableBoatyard:onBoatI3DFileLoaded(i3dFileRoot, failedReason, args)
	local v_u_32_ = self.spec_boatyard
	if i3dFileRoot ~= 0 then
		v_u_32_.boatRoot = i3dFileRoot
		local v_u_33_ = {}
		I3DUtil.loadI3DComponents(i3dFileRoot, v_u_33_)
		self.xmlFile:iterate("placeable.boatyard.boat.progressiveVisibilityMesh.mesh", function(_, p34_)
			-- upvalues: (copy) self, (copy) v_u_33_, (copy) v_u_32_
			local v35_ = self.xmlFile:getValue(p34_ .. "#node", nil, v_u_33_)
			if getHasClassId(v35_, ClassIds.SHAPE) then
				if getHasShaderParameter(v35_, "hideByIndex") then
					local v36_ = self.xmlFile:getValue(p34_ .. "#id")
					local v37_ = self.xmlFile:getValue(p34_ .. "#indexMin", 0)
					local v38_ = self.xmlFile:getValue(p34_ .. "#indexMax")
					if v_u_32_.idToMesh[v36_] == nil then
						local v39_ = {
							["node"] = v35_,
							["childIndex"] = getChildIndex(v35_),
							["id"] = v36_,
							["index"] = #v_u_32_.meshes + 1,
							["indexMin"] = v37_,
							["indexMax"] = v38_,
							["lastValue"] = -1,
							["dirtyFlag"] = self:getNextDirtyFlag(),
							["numBits"] = MathUtil.getNumRequiredBits(v38_)
						}
						v_u_32_.idToMesh[v36_] = v39_
						local v40_ = v_u_32_.meshes
						table.insert(v40_, v39_)
					else
						Logging.xmlError(self.xmlFile, "id \'%s\' at \'%s\' already in use", v36_, p34_)
					end
				else
					Logging.xmlError(self.xmlFile, "mesh \'%s\' at \'%s\' does not have required shader parameter \'hideByIndex\'", getName(v35_), p34_)
					return
				end
			else
				Logging.xmlError(self.xmlFile, "node \'%s\' at \'%s\' is not a shape", getName(v35_), p34_)
				return
			end
		end)
	end
	self:finishLoadingTask(args.loadingTask)
	self:raiseActive()
end

-- Local values: spec, _, state
function PlaceableBoatyard:onDelete()
	local v42_ = self.spec_boatyard
	g_currentMission.activatableObjectsSystem:removeActivatable(v42_.activatable)
	if v42_.unloadingStation ~= nil then
		g_currentMission.storageSystem:removeUnloadingStation(v42_.unloadingStation, self)
		g_currentMission.economyManager:removeSellingStation(v42_.unloadingStation)
		v42_.unloadingStation:delete()
	end
	if v42_.playerTrigger ~= nil then
		removeTrigger(v42_.playerTrigger)
		v42_.playerTrigger = nil
	end
	for _, v43_ in ipairs(v42_.stateMachine) do
		v43_:delete()
	end
	if v42_.boatRoot ~= nil then
		delete(v42_.boatRoot)
		v42_.boatRoot = nil
	end
	if v42_.boatLinkNode ~= nil then
		delete(v42_.boatLinkNode)
		v42_.boatLinkNode = nil
	end
	if v42_.boatsSailingLinkNode ~= nil then
		delete(v42_.boatsSailingLinkNode)
		v42_.boatsSailingLinkNode = nil
	end
	if v42_.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(v42_.sharedLoadRequestId)
		v42_.sharedLoadRequestId = nil
	end
end

-- Local values: spec, i, unloadTrigger
function PlaceableBoatyard:collectPickObjects(superFunc, node)
	local v47_ = self.spec_boatyard
	for v48_ = 1, #v47_.unloadingStation.unloadTriggers do
		if node == v47_.unloadingStation.unloadTriggers[v48_].exactFillRootNode then
			return
		end
	end
	superFunc(self, node)
end

-- Local values: spec, state
function PlaceableBoatyard:saveToXMLFile(xmlFile, key, usedModNames)
	local v53_ = self.spec_boatyard
	if v53_.stateIndex > 0 then
		xmlFile:setValue(key .. ".state#index", v53_.stateIndex)
		xmlFile:setValue(key .. "#splineTime", v53_.splineTime)
		v53_.stateMachine[v53_.stateIndex]:saveToXMLFile(xmlFile, key, usedModNames)
	end
	v53_.storage:saveToXMLFile(xmlFile, key .. ".storage")
end

-- Local values: spec, stateIndex, splineTimeLoaded, i, state
function PlaceableBoatyard:loadFromXMLFile(xmlFile, key)
	local v57_ = self.spec_boatyard
	local v58_ = xmlFile:getValue(key .. ".state#index") or 0
	local v59_ = xmlFile:getValue(key .. "#splineTime")
	for v60_ = 0, v58_ do
		self:setState(v60_)
	end
	if v59_ ~= nil then
		self:setSplineTime(v59_)
	end
	v57_.stateMachine[v57_.stateIndex]:loadFromXMLFile(xmlFile, key)
	v57_.storage:loadFromXMLFile(xmlFile, key .. ".storage")
end

-- Local values: spec, unloadingStationId, storageId, stateIndex, i, state, splineTime, meshIndex, mesh, hideByIndexValue, progress
function PlaceableBoatyard:onReadStream(streamId, connection)
	local v64_ = self.spec_boatyard
	local v65_ = NetworkUtil.readNodeObjectId(streamId)
	v64_.unloadingStation:readStream(streamId, connection)
	g_client:finishRegisterObject(v64_.unloadingStation, v65_)
	local v66_ = NetworkUtil.readNodeObjectId(streamId)
	v64_.storage:readStream(streamId, connection)
	g_client:finishRegisterObject(v64_.storage, v66_)
	local v67_ = streamReadUInt8(streamId)
	for v68_ = 0, v67_ do
		self:setState(v68_)
	end
	v64_.stateMachine[v67_]:onReadStream(streamId, connection)
	local v69_ = streamReadFloat32(streamId)
	v64_.splineTimeChanged = true
	v64_.splineInterpolator:setValue(v69_)
	v64_.splineTimeInterpolator:reset()
	for _, v70_ in ipairs(v64_.meshes) do
		local v71_ = streamReadUIntN(streamId, v70_.numBits)
		local v72_ = MathUtil.inverseLerp(v70_.indexMax, v70_.indexMin, v71_)
		self:setMeshProgress(v70_.id, v72_)
	end
	v64_.nextSailingSplineIndex = streamReadUInt8(streamId)
end

-- Local values: spec, state, meshIndex, mesh
function PlaceableBoatyard:onWriteStream(streamId, connection)
	local v76_ = self.spec_boatyard
	NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v76_.unloadingStation))
	v76_.unloadingStation:writeStream(streamId, connection)
	g_server:registerObjectInStream(connection, v76_.unloadingStation)
	NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v76_.storage))
	v76_.storage:writeStream(streamId, connection)
	g_server:registerObjectInStream(connection, v76_.storage)
	streamWriteUInt8(streamId, v76_.stateIndex)
	v76_.stateMachine[v76_.stateIndex]:onWriteStream(streamId, connection)
	streamWriteFloat32(streamId, v76_.splineTime)
	for _, v77_ in ipairs(v76_.meshes) do
		streamWriteUIntN(streamId, v77_.lastValue, v77_.numBits)
	end
	streamWriteUInt8(streamId, v76_.nextSailingSplineIndex)
end

-- Local values: spec, meshIndex, mesh, hideByIndexValue, progress, splineTime, _, state
function PlaceableBoatyard:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local v82_ = self.spec_boatyard
		for _, v83_ in ipairs(v82_.meshes) do
			if streamReadBool(streamId) then
				local v84_ = streamReadUIntN(streamId, v83_.numBits)
				local v85_ = MathUtil.inverseLerp(v83_.indexMax, v83_.indexMin, v84_)
				self:setMeshProgress(v83_.id, v85_)
			end
		end
		v82_.splineTimeChanged = streamReadBool(streamId)
		if v82_.splineTimeChanged then
			local v86_ = streamReadFloat32(streamId)
			v82_.splineTimeInterpolator:startNewPhaseNetwork()
			v82_.splineInterpolator:setTargetValue(v86_)
		end
		if streamReadBool(streamId) then
			for _, v87_ in ipairs(v82_.stateMachine) do
				if streamReadBool(streamId) then
					v87_:onReadUpdateStream(streamId, timestamp, connection)
				end
			end
		end
	end
end

-- Local values: spec, meshIndex, mesh, _, state
function PlaceableBoatyard:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v92_ = self.spec_boatyard
		for _, v93_ in ipairs(v92_.meshes) do
			if streamWriteBool(streamId, bitAND(dirtyMask, v93_.dirtyFlag) ~= 0) then
				streamWriteUIntN(streamId, v93_.lastValue, v93_.numBits)
			end
		end
		if streamWriteBool(streamId, bitAND(dirtyMask, v92_.splineTimeDirtyFlag) ~= 0) then
			streamWriteFloat32(streamId, v92_.splineTime)
		end
		if streamWriteBool(streamId, bitAND(dirtyMask, v92_.statesDirtyMask) ~= 0) then
			for _, v94_ in ipairs(v92_.stateMachine) do
				if streamWriteBool(streamId, bitAND(dirtyMask, v94_.dirtyFlag) ~= 0) then
					v94_:onWriteUpdateStream(streamId, connection, dirtyMask)
				end
			end
		end
	end
end

-- Local values: spec, state, nextStateIndex, interpolationAlpha, splineTime, boatSailingNode, boatAttrs, spline, bobbing, swaying, alpha, x, y, z, dx, dy, dz, ux, uy, uz, windFactor, x, y, z, dx, dy, dz
function PlaceableBoatyard:onUpdate(dt)
	local v97_ = self.spec_boatyard
	if self.isServer then
		local v98_ = v97_.stateMachine[v97_.stateIndex]
		if v98_:isDone() then
			self:setState(v97_.stateTransitions[v97_.stateIndex])
			v98_ = v97_.stateMachine[v97_.stateIndex]
			self:raiseActive()
		elseif v98_:raiseActive() then
			self:raiseActive()
		end
		v98_:update(dt)
	elseif self.isClient and v97_.splineTimeChanged then
		v97_.splineTimeInterpolator:update(dt)
		local v99_ = v97_.splineTimeInterpolator:getAlpha()
		self:setSplineTime((v97_.splineInterpolator:getInterpolatedValue(v99_)))
		if v97_.splineTimeInterpolator:isInterpolating() then
			self:raiseActive()
		end
	end
	for v100_, v101_ in pairs(v97_.boatsSailing) do
		local v102_ = v101_.spline
		local v103_ = v97_.boatBobbingAmount
		local v104_ = g_time * v97_.boatBobbingFreq
		local v105_ = v103_ * math.sin(v104_)
		local v106_ = v97_.boatSwayingAmount
		local v107_ = g_time * v97_.boatSwayingFreq
		local v108_ = v106_ * math.sin(v107_)
		if v101_.transitionTime < v101_.transitionDuration then
			local v109_ = v101_.transitionTime / v101_.transitionDuration
			local v110_, v111_, v112_ = MathUtil.vector3Lerp(v101_.startX, v101_.startY, v101_.startZ, v102_.startX, v102_.startY + v105_, v102_.startZ, v109_)
			setWorldTranslation(v100_, v110_, v111_, v112_)
			local v113_, v114_, v115_ = MathUtil.vector3Lerp(v101_.startDx, v101_.startDy, v101_.startDz, v102_.startDx, v102_.startDy, v102_.startDz, v109_)
			local v116_, v117_, v118_ = MathUtil.vector3Lerp(v101_.startUx, v101_.startUy, v101_.startUz, v108_, 1, 0, v109_)
			setDirection(v100_, v113_, v114_, v115_, v116_, v117_, v118_)
			v101_.transitionTime = v101_.transitionTime + dt
		else
			local v119_ = v97_.windSpeed / 15
			local v120_ = math.clamp(v119_, 0.5, 2)
			local v121_ = v101_.speed + v97_.sailingAcc * dt / 1000
			local v122_ = v120_ * 3
			v101_.speed = math.clamp(v121_, 0, v122_)
			v101_.splineTime = v101_.splineTime + v101_.speed / 1000 * dt / v102_.length
			local v123_, v124_, v125_ = getSplinePosition(v102_.node, v101_.splineTime)
			local v126_, v127_, v128_ = getSplineDirection(v102_.node, v101_.splineTime)
			setWorldTranslation(v100_, v123_, v124_ + v105_, v125_)
			setDirection(v100_, v126_, v127_, v128_, v108_, 1, 0)
			if v101_.splineTime >= 1 then
				v97_.boatsSailing[v100_] = nil
				delete(v100_)
			end
		end
	end
	if next(v97_.boatsSailing) then
		self:raiseActive()
	end
end

-- Local values: spec
function PlaceableBoatyard:setOwnerFarmId(superFunc, farmId)
	superFunc(self, farmId)
	local v132_ = self.spec_boatyard
	if v132_.unloadingStation ~= nil then
		if farmId == AccessHandler.EVERYONE then
			g_currentMission.storageSystem:addUnloadingStation(v132_.unloadingStation, self)
			g_currentMission.economyManager:addSellingStation(v132_.unloadingStation)
		else
			g_currentMission.economyManager:removeSellingStation(v132_.unloadingStation)
			g_currentMission.storageSystem:removeUnloadingStation(v132_.unloadingStation, self)
		end
	end
	if v132_.playerTrigger ~= nil then
		setVisibility(v132_.playerTrigger, farmId == AccessHandler.EVERYONE)
	end
end

-- Local values: spec
function PlaceableBoatyard:setWindValues(windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor)
	self.spec_boatyard.windSpeed = windVelocity
end

-- Local values: spec, mesh, hideByIndexValue, node
function PlaceableBoatyard:setMeshProgress(meshId, percentage)
	local v138_ = self.spec_boatyard
	if v138_.boat ~= nil then
		local v139_ = v138_.idToMesh[meshId]
		if v139_ ~= nil then
			local v140_ = MathUtil.round(MathUtil.lerp(v139_.indexMax, v139_.indexMin, percentage))
			if v140_ ~= v139_.lastValue then
				local v141_ = getChildAt(v138_.boat, v139_.childIndex)
				setVisibility(v141_, percentage ~= 0)
				v139_.lastValue = v140_
				setShaderParameter(v141_, "hideByIndex", v140_, 0, 0, 0, false)
				if self.isServer then
					self:raiseDirtyFlags(v139_.dirtyFlag)
				end
			end
		end
	end
end

-- Local values: spec, oldStateIndex, oldState, state
function PlaceableBoatyard:setState(newStateIndex)
	local v144_ = self.spec_boatyard
	if self.isServer then
		g_server:broadcastEvent(BoatyardStateEvent.new(self, newStateIndex), false)
	end
	if newStateIndex ~= v144_.stateIndex then
		local v145_ = v144_.stateIndex
		v144_.stateIndex = newStateIndex
		local v146_ = v144_.stateMachine[v145_]
		local v147_ = v144_.stateMachine[newStateIndex]
		if v146_ ~= nil then
			v146_:deactivate()
		end
		v147_:activate()
	end
end

-- Local values: spec
function PlaceableBoatyard:createBoat()
	local v149_ = self.spec_boatyard
	if v149_.boat == nil then
		v149_.boat = clone(v149_.boatRoot, false, false, true)
		link(v149_.boatLinkNode, v149_.boat)
	end
end

-- Local values: spec, sailingSplineAttrs, boatSailing, x, y, z, rx, ry, rz, dx, dy, dz, ux, uy, uz, splineX, splineY, splineZ, splineTime, splineDx, splineDy, splineDz, distanceDifference, angleDifference
function PlaceableBoatyard:releaseBoat()
	local v151_ = self.spec_boatyard
	if v151_.boat ~= nil then
		local v152_ = v151_.sailingSplines[v151_.nextSailingSplineIndex]
		local v153_ = v151_.boat
		local v154_, v155_, v156_ = getWorldTranslation(v151_.boat)
		local v157_, v158_, v159_ = getWorldRotation(v151_.boat)
		link(v151_.boatsSailingLinkNode, v151_.boat)
		setWorldTranslation(v151_.boat, v154_, v155_, v156_)
		setWorldRotation(v151_.boat, v157_, v158_, v159_)
		local v160_, v161_, v162_ = localDirectionToWorld(v151_.boat, 0, 0, 1)
		local v163_, v164_, v165_ = localDirectionToWorld(v151_.boat, 0, 1, 0)
		local v166_, v167_, v168_, v169_ = getClosestSplinePosition(v152_.node, v154_, v155_, v156_, 0.2)
		local v170_, v171_, v172_ = getSplineDirection(v152_.node, v169_)
		v152_.startX = v166_
		v152_.startY = v167_
		v152_.startZ = v168_
		v152_.startDx = v170_
		v152_.startDy = v171_
		v152_.startDz = v172_
		local v173_ = MathUtil.vector3Length(v154_ - v166_, v155_ - v167_, v156_ - v168_)
		local v174_ = MathUtil.getVectorAngleDifference(v160_, v161_, v162_, v170_, v171_, v172_)
		local v175_ = math.deg(v174_)
		local v176_ = v151_.boatsSailing
		local v177_ = {
			["spline"] = v152_,
			["splineIndex"] = v151_.nextSailingSplineIndex,
			["splineTime"] = v169_,
			["speed"] = 0,
			["transitionTime"] = 0
		}
		local v178_ = v173_ * 4
		v177_.transitionDuration = math.max(v178_, v175_) * 1000
		v177_.startX = v154_
		v177_.startY = v155_
		v177_.startZ = v156_
		v177_.startDx = v160_
		v177_.startDy = v161_
		v177_.startDz = v162_
		v177_.startUx = v163_
		v177_.startUy = v164_
		v177_.startUz = v165_
		v176_[v153_] = v177_
		if self.isServer and self:getOwnerFarmId() ~= AccessHandler.EVERYONE then
			g_currentMission:addMoney(v151_.boatLaunchReward * EconomyManager.getPriceMultiplier(), self:getOwnerFarmId(), MoneyType.SOLD_PRODUCTS, true, true)
		end
		v151_.boat = nil
		v151_.nextSailingSplineIndex = 1 + v151_.nextSailingSplineIndex % #v151_.sailingSplines
		self:raiseActive()
	end
end

-- Local values: spec, x, y, z, dx, dy, dz, jitter
function PlaceableBoatyard:setSplineTime(splineTime, resetInterpolation)
	local v182_ = self.spec_boatyard
	v182_.splineTime = math.clamp(splineTime, 0, 1)
	if self.isServer then
		self:raiseDirtyFlags(v182_.splineTimeDirtyFlag)
	elseif resetInterpolation and self.isClient then
		v182_.splineInterpolator:setValue(splineTime)
	end
	local v183_, v184_, v185_ = getSplinePosition(v182_.spline, v182_.splineTime)
	setWorldTranslation(v182_.boatLinkNode, v183_, v184_, v185_)
	local v186_, v187_, v188_ = getSplineDirection(v182_.spline, v182_.splineTime)
	local v189_ = v182_.splineTime * v182_.splineLength * 2
	local v190_ = 0.002 * math.sin(v189_)
	setDirection(v182_.boatLinkNode, -v186_, -v187_, -v188_, v190_, 1, 0)
end

-- Local values: spec, increment
function PlaceableBoatyard:addSplineDistanceDelta(distance)
	local v193_ = self.spec_boatyard
	local v194_ = distance / v193_.splineLength
	self:setSplineTime(v193_.splineTime + v194_)
	return v193_.splineTime, v194_
end

-- Local values: spec
function PlaceableBoatyard:getSplineTime()
	return self.spec_boatyard.splineTime
end

-- Local values: spec
function PlaceableBoatyard:getFillLevel(fillType)
	return self.spec_boatyard.storage:getFillLevel(fillType)
end

-- Local values: spec, previousFillLevel
function PlaceableBoatyard:removeFillLevel(fillType, amount)
	local v201_ = self.spec_boatyard
	local v202_ = v201_.storage:getFillLevel(fillType)
	v201_.storage:setFillLevel(v202_ - amount, fillType)
	return v202_ - v201_.storage:getFillLevel(fillType)
end

-- Local values: spec, fillType, fillLevel, fillType, fillLevel, numEntries, i, fillTypeAndLevel, state
function PlaceableBoatyard:updateInfo(superFunc, infoTable)
	superFunc(self, infoTable)
	local v206_ = self.spec_boatyard
	v206_.fillTypesAndLevelsAuxiliary = {}
	for v207_, v208_ in pairs(v206_.storage:getFillLevels()) do
		v206_.fillTypesAndLevelsAuxiliary[v207_] = (v206_.fillTypesAndLevelsAuxiliary[v207_] or 0) + v208_
	end
	table.clear(v206_.infoTriggerFillTypesAndLevels)
	for v209_, v210_ in pairs(v206_.fillTypesAndLevelsAuxiliary) do
		if v210_ > 0.1 then
			local v211_ = v206_.fillTypeToFillTypeStorageTable
			local v212_ = v206_.fillTypeToFillTypeStorageTable[v209_]
			if not v212_ then
				v212_ = {
					["fillType"] = v209_,
					["fillLevel"] = v210_
				}
			end
			v211_[v209_] = v212_
			v206_.fillTypeToFillTypeStorageTable[v209_].fillLevel = v210_
			local v213_ = v206_.infoTriggerFillTypesAndLevels
			local v214_ = v206_.fillTypeToFillTypeStorageTable[v209_]
			table.insert(v213_, v214_)
		end
	end
	table.clear(v206_.fillTypesAndLevelsAuxiliary)
	table.sort(v206_.infoTriggerFillTypesAndLevels, function(p215_, p216_)
		return p215_.fillLevel > p216_.fillLevel
	end)
	local v217_ = #v206_.infoTriggerFillTypesAndLevels
	local v218_ = math.min(v217_, 7)
	if v218_ > 0 then
		local v219_ = v206_.infoTableEntryStorage
		table.insert(infoTable, v219_)
		for v220_ = 1, v218_ do
			local v221_ = v206_.infoTriggerFillTypesAndLevels[v220_]
			local v222_ = {
				["title"] = g_fillTypeManager:getFillTypeTitleByIndex(v221_.fillType),
				["text"] = g_i18n:formatVolume(v221_.fillLevel, 0)
			}
			table.insert(infoTable, v222_)
		end
	end
	local v223_ = v206_.stateMachine[v206_.stateIndex]
	if v223_.updateInfo ~= nil then
		v223_:updateInfo(infoTable)
	end
end

-- Local values: spec
function PlaceableBoatyard:playerTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if (onEnter or onLeave) and (g_localPlayer ~= nil and g_localPlayer.rootNode == otherId) then
		local v228_ = self.spec_boatyard
		if onEnter then
			if Platform.isMobile and v228_.activatable:getIsActivatable() then
				v228_.activatable:run()
				return
			end
			g_currentMission.activatableObjectsSystem:addActivatable(v228_.activatable)
		end
		if onLeave then
			g_currentMission.activatableObjectsSystem:removeActivatable(v228_.activatable)
		end
	end
end

-- Local values: price, buyingEventCallback, dialogCallback, callback, text
function PlaceableBoatyard:buyRequest()
	local v230_ = self:getPrice()
	local function v_u_233_(p231_)
		-- upvalues: (copy) self
		if p231_ ~= nil then
			local v232_ = BuyExistingPlaceableEvent.DIALOG_MESSAGES[p231_]
			if v232_ ~= nil then
				InfoDialog.show(g_i18n:getText(v232_.text), nil, nil, v232_.dialogType)
			end
		end
		g_messageCenter:unsubscribe(BuyExistingPlaceableEvent, self)
	end
	local v234_ = string.format(g_i18n:getText("dialog_buyBuildingFor"), self:getName(), g_i18n:formatMoney(v230_, 0, true))
	YesNoDialog.show(function(p235_, _)
		-- upvalues: (copy) v_u_233_, (copy) self
		if p235_ then
			g_messageCenter:subscribe(BuyExistingPlaceableEvent, v_u_233_)
			g_client:getServerConnection():sendEvent(BuyExistingPlaceableEvent.new(self, g_currentMission:getFarmId()))
		end
	end, nil, v234_)
end
