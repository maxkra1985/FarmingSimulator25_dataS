source("dataS/scripts/vehicles/specializations/events/RidgeMarkerSetStateEvent.lua")
RidgeMarker = {}
RidgeMarker.SEND_NUM_BITS = 3
RidgeMarker.MAX_NUM_RIDGEMARKERS = 2 ^ RidgeMarker.SEND_NUM_BITS
RidgeMarker.CLIENT_DM_UPDATE_RADIUS = 50
function RidgeMarker.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("ridgeMarker", g_i18n:getText("configuration_ridgeMarker"), "ridgeMarker", VehicleConfigurationItem)
	g_workAreaTypeManager:addWorkAreaType("ridgemarker", false, false, false)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("RidgeMarker")
	RidgeMarker.registerRidgeMarkerXMLPaths(v1_, "vehicle.ridgeMarker")
	RidgeMarker.registerRidgeMarkerXMLPaths(v1_, "vehicle.ridgeMarker.ridgeMarkerConfigurations.ridgeMarkerConfiguration(?)")
	RidgeMarker.registerRidgeMarkerAreaXMLPaths(v1_, WorkArea.WORK_AREA_XML_KEY)
	RidgeMarker.registerRidgeMarkerAreaXMLPaths(v1_, WorkArea.WORK_AREA_XML_CONFIG_KEY)
	v1_:register(XMLValueType.STRING, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#ridgeMarkerAnim", "Ridge marker animation")
	v1_:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#ridgeMarkerAnimTimeMax", "Animation max. time for activation", 0.99)
	v1_:setXMLSpecializationType()
	Vehicle.xmlSchemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).ridgeMarker#state", "Ridge marker state")
end

function RidgeMarker.registerRidgeMarkerXMLPaths(schema, baseKey)
	schema:register(XMLValueType.STRING, baseKey .. "#inputButton", "Input action name", "IMPLEMENT_EXTRA4")
	schema:register(XMLValueType.STRING, baseKey .. ".marker(?)#animName", "Animation name")
	schema:register(XMLValueType.FLOAT, baseKey .. ".marker(?)#minWorkLimit", "Min. work limit", 0.99)
	schema:register(XMLValueType.FLOAT, baseKey .. ".marker(?)#maxWorkLimit", "Max. work limit", 1)
	schema:register(XMLValueType.FLOAT, baseKey .. ".marker(?)#liftedAnimTime", "Lifted animation time")
	schema:register(XMLValueType.INT, baseKey .. ".marker(?)#workAreaIndex", "Work area index")
	schema:register(XMLValueType.FLOAT, baseKey .. "#foldMinLimit", "Fold min. limit", 0)
	schema:register(XMLValueType.FLOAT, baseKey .. "#foldMaxLimit", "Fold max. limit", 1)
	schema:register(XMLValueType.INT, baseKey .. "#foldDisableDirection", "Fold disable direction")
	schema:register(XMLValueType.BOOL, baseKey .. "#onlyActiveWhenLowered", "Only active while lowered", true)
	schema:register(XMLValueType.NODE_INDEX, baseKey .. "#directionNode", "Direction node")
end

function RidgeMarker.registerRidgeMarkerAreaXMLPaths(schema, baseKey)
	schema:register(XMLValueType.NODE_INDEX, baseKey .. ".ridgeMarkerArea#node", "Around this node the ridge marker areas are generated")
	schema:register(XMLValueType.FLOAT, baseKey .. ".ridgeMarkerArea#size", "Width and length of area and test area", 0.25)
	schema:register(XMLValueType.FLOAT, baseKey .. ".ridgeMarkerArea#testAreaOffset", "Offset of test area in positive z direction", 0.2)
end

function RidgeMarker.prerequisitesPresent(specializations)
	local v7_ = SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
	if v7_ then
		v7_ = SpecializationUtil.hasSpecialization(WorkArea, specializations)
	end
	return v7_
end

function RidgeMarker.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadRidgeMarker", RidgeMarker.loadRidgeMarker)
	SpecializationUtil.registerFunction(vehicleType, "setRidgeMarkerState", RidgeMarker.setRidgeMarkerState)
	SpecializationUtil.registerFunction(vehicleType, "canFoldRidgeMarker", RidgeMarker.canFoldRidgeMarker)
	SpecializationUtil.registerFunction(vehicleType, "processRidgeMarkerArea", RidgeMarker.processRidgeMarkerArea)
end

function RidgeMarker.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", RidgeMarker.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", RidgeMarker.getIsWorkAreaActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSpeedRotatingPartFromXML", RidgeMarker.loadSpeedRotatingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSpeedRotatingPartActive", RidgeMarker.getIsSpeedRotatingPartActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", RidgeMarker.getCanBeSelected)
end

function RidgeMarker.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", RidgeMarker)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", RidgeMarker)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", RidgeMarker)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", RidgeMarker)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", RidgeMarker)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", RidgeMarker)
	SpecializationUtil.registerEventListener(vehicleType, "onSetLowered", RidgeMarker)
	SpecializationUtil.registerEventListener(vehicleType, "onFoldStateChanged", RidgeMarker)
	SpecializationUtil.registerEventListener(vehicleType, "onAIImplementStart", RidgeMarker)
end

-- Local values: spec, configurationId, configKey, inputButtonStr, i, key, ridgeMarker
function RidgeMarker:onLoad(savegame)
	local v12_ = self.spec_ridgeMarker
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.ridgeMarkers", "vehicle.ridgeMarker")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.ridgeMarkers.ridgeMarker", "vehicle.ridgeMarker.marker")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.ridgeMarker.ridgeMarker", "vehicle.ridgeMarker.marker")
	local v13_ = Utils.getNoNil(self.configurations.ridgeMarker, 1)
	local v14_ = string.format("vehicle.ridgeMarker.ridgeMarkerConfigurations.ridgeMarkerConfiguration(%d)", v13_ - 1)
	local v15_ = not self.xmlFile:hasProperty(v14_) and "vehicle.ridgeMarker" or v14_
	local v16_ = self.xmlFile:getValue(v15_ .. "#inputButton")
	if v16_ ~= nil then
		v12_.ridgeMarkerInputButton = InputAction[v16_]
	end
	v12_.ridgeMarkerInputButton = Utils.getNoNil(v12_.ridgeMarkerInputButton, InputAction.IMPLEMENT_EXTRA4)
	v12_.ridgeMarkers = {}
	v12_.workAreaToRidgeMarker = {}
	local v17_ = 0
	while true do
		local v18_ = string.format("%s.marker(%d)", v15_, v17_)
		if not self.xmlFile:hasProperty(v18_) then
			break
		end
		if #v12_.ridgeMarkers >= RidgeMarker.MAX_NUM_RIDGEMARKERS - 1 then
			Logging.xmlError(self.xmlFile, "Too many ridgeMarker states. Only %d states are supported!", RidgeMarker.MAX_NUM_RIDGEMARKERS - 1)
			break
		end
		local v19_ = {}
		if self:loadRidgeMarker(self.xmlFile, v18_, v19_) then
			local v20_ = v12_.ridgeMarkers
			table.insert(v20_, v19_)
			v12_.workAreaToRidgeMarker[v19_.workAreaIndex] = v19_
		end
		v17_ = v17_ + 1
	end
	v12_.numRigdeMarkers = #v12_.ridgeMarkers
	v12_.ridgeMarkerMinFoldTime = self.xmlFile:getValue(v15_ .. "#foldMinLimit", 0)
	v12_.ridgeMarkerMaxFoldTime = self.xmlFile:getValue(v15_ .. "#foldMaxLimit", 1)
	v12_.foldDisableDirection = self.xmlFile:getValue(v15_ .. "#foldDisableDirection")
	v12_.onlyActiveWhenLowered = self.xmlFile:getValue(v15_ .. "#onlyActiveWhenLowered", true)
	v12_.ridgeMarkerState = 0
	v12_.directionNode = self.xmlFile:getValue(v15_ .. "#directionNode", nil, self.components, self.i3dMappings)
	if not self.isClient then
		SpecializationUtil.removeEventListener(self, "onUpdateTick", RidgeMarker)
	end
end

-- Local values: spec, state
function RidgeMarker:onPostLoad(savegame)
	local v23_ = self.spec_ridgeMarker
	if v23_.numRigdeMarkers > 0 and savegame ~= nil then
		local v24_ = savegame.xmlFile:getValue(savegame.key .. ".ridgeMarker#state")
		if v24_ ~= nil then
			self:setRidgeMarkerState(v24_, true)
			if v24_ ~= 0 then
				AnimatedVehicle.updateAnimationByName(self, v23_.ridgeMarkers[v24_].animName, 9999999, true)
			end
		end
	end
end

-- Local values: spec
function RidgeMarker:saveToXMLFile(xmlFile, key, usedModNames)
	local v28_ = self.spec_ridgeMarker
	if v28_.numRigdeMarkers > 0 then
		xmlFile:setValue(key .. "#state", v28_.ridgeMarkerState)
	end
end

-- Local values: spec, state
function RidgeMarker:onReadStream(streamId, connection)
	local v31_ = self.spec_ridgeMarker
	if v31_.numRigdeMarkers > 0 then
		local v32_ = streamReadUIntN(streamId, RidgeMarker.SEND_NUM_BITS)
		self:setRidgeMarkerState(v32_, true)
		if v32_ ~= 0 then
			AnimatedVehicle.updateAnimationByName(self, v31_.ridgeMarkers[v32_].animName, 9999999, true)
		end
	end
end

-- Local values: spec
function RidgeMarker:onWriteStream(streamId, connection)
	local v35_ = self.spec_ridgeMarker
	if v35_.numRigdeMarkers > 0 then
		streamWriteUIntN(streamId, v35_.ridgeMarkerState, RidgeMarker.SEND_NUM_BITS)
	end
end

function RidgeMarker:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	RidgeMarker.updateActionEvents(self)
end

function RidgeMarker:loadRidgeMarker(xmlFile, key, ridgeMarker)
	ridgeMarker.animName = xmlFile:getValue(key .. "#animName")
	ridgeMarker.minWorkLimit = xmlFile:getValue(key .. "#minWorkLimit", 0.99)
	ridgeMarker.maxWorkLimit = xmlFile:getValue(key .. "#maxWorkLimit", 1)
	ridgeMarker.liftedAnimTime = xmlFile:getValue(key .. "#liftedAnimTime")
	ridgeMarker.workAreaIndex = xmlFile:getValue(key .. "#workAreaIndex")
	if ridgeMarker.workAreaIndex ~= nil then
		return true
	end
	Logging.xmlWarning(self.xmlFile, "Missing \'workAreaIndex\' for ridgeMarker \'%s\'!", key)
	return false
end

-- Local values: spec, animTime, animTime
function RidgeMarker:setRidgeMarkerState(state, noEventSend)
	local v44_ = self.spec_ridgeMarker
	if v44_.ridgeMarkerState ~= state then
		RidgeMarkerSetStateEvent.sendEvent(self, state, noEventSend)
		if v44_.ridgeMarkerState ~= 0 then
			local v45_ = self:getAnimationTime(v44_.ridgeMarkers[v44_.ridgeMarkerState].animName)
			self:playAnimation(v44_.ridgeMarkers[v44_.ridgeMarkerState].animName, -1, v45_, true)
		end
		v44_.ridgeMarkerState = state
		if v44_.ridgeMarkerState ~= 0 then
			if v44_.ridgeMarkers[v44_.ridgeMarkerState].liftedAnimTime ~= nil and not self:getIsLowered(true) then
				self:setAnimationStopTime(v44_.ridgeMarkers[v44_.ridgeMarkerState].animName, v44_.ridgeMarkers[v44_.ridgeMarkerState].liftedAnimTime)
			end
			local v46_ = self:getAnimationTime(v44_.ridgeMarkers[v44_.ridgeMarkerState].animName)
			self:playAnimation(v44_.ridgeMarkers[v44_.ridgeMarkerState].animName, 1, v46_, true)
		end
	end
end

-- Local values: spec, foldAnimTime, foldableSpec
function RidgeMarker:canFoldRidgeMarker(state)
	local v49_ = self.spec_ridgeMarker
	if self.getFoldAnimTime ~= nil then
		local v50_ = self:getFoldAnimTime()
		if v50_ < v49_.ridgeMarkerMinFoldTime or v49_.ridgeMarkerMaxFoldTime < v50_ then
			return false
		end
	end
	local v51_ = self.spec_foldable
	return (state == 0 or (v51_.moveToMiddle or (v49_.foldDisableDirection == nil or v49_.foldDisableDirection ~= v51_.foldMoveDirection and v51_.foldMoveDirection ~= 0))) and true or false
end

-- Local values: spec, mission, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, densityBits, densityType, groundType, x, _, z, x1, _, z1, x2, _, z2, wx, wz, hx, hz, worldToDensity, dx, _, dz, angle
function RidgeMarker:processRidgeMarkerArea(workArea, dt)
	local v54_ = self.spec_ridgeMarker
	local v55_ = g_currentMission
	local v56_, v57_, v58_ = v55_.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
	local v59_ = getDensityAtWorldPos(v56_, getWorldTranslation(workArea.testNode))
	local v60_ = bit32.rshift(v59_, v57_)
	local v61_ = 2 ^ v58_ - 1
	local v62_ = bit32.band(v60_, v61_)
	local v63_ = FieldGroundType.getTypeByValue(v62_)
	if v63_ ~= FieldGroundType.NONE then
		local v64_, _, v65_ = getWorldTranslation(workArea.start)
		local v66_, _, v67_ = getWorldTranslation(workArea.width)
		local v68_, _, v69_ = getWorldTranslation(workArea.height)
		local v70_ = v66_ - v64_
		local v71_ = v67_ - v65_
		local v72_ = v68_ - v64_
		local v73_ = v69_ - v65_
		local v74_ = v55_.terrainDetailMapSize / v55_.terrainSize
		local v75_ = v64_ * v74_ + 0.5
		local v76_ = math.floor(v75_) / v74_
		local v77_ = v65_ * v74_ + 0.5
		local v78_ = math.floor(v77_) / v74_
		local v79_ = v76_ + v70_
		local v80_ = v78_ + v71_
		local v81_ = v76_ + v72_
		local v82_ = v78_ + v73_
		FSDensityMapUtil.eraseTireTrack(v76_, v78_, v79_, v80_, v81_, v82_)
		if not self.isServer and self.currentUpdateDistance > RidgeMarker.CLIENT_DM_UPDATE_RADIUS then
			return 0, 0
		end
		local v83_, _, v84_ = localDirectionToWorld(v54_.directionNode or self.rootNode, 0, 0, 1)
		local v85_ = FSDensityMapUtil.convertToDensityMapAngle(MathUtil.getYRotationFromDirection(v83_, v84_), v55_.fieldGroundSystem:getGroundAngleMaxValue())
		if v63_ == FieldGroundType.PLOWED then
			FSDensityMapUtil.updateCultivatorArea(v76_, v78_, v79_, v80_, v81_, v82_, false, true, v85_, nil, nil, true)
		else
			FSDensityMapUtil.updatePlowArea(v76_, v78_, v79_, v80_, v81_, v82_, false, true, v85_, false, true)
		end
	end
	return 0, 0
end

-- Local values: ridgeMarkerNode, ridgeMarkerSize, ridgeMarkerTestOffset, testOffset
function RidgeMarker:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	local v91_ = xmlFile:getValue(key .. ".ridgeMarkerArea#node", nil, self.components, self.i3dMappings)
	local v92_ = xmlFile:getValue(key .. ".ridgeMarkerArea#size", 0.25) * 0.5
	local v93_ = xmlFile:getValue(key .. ".ridgeMarkerArea#testAreaOffset", 0.2)
	if v91_ ~= nil then
		workArea.start = createTransformGroup("ridgeMarkerAreaStart")
		link(v91_, workArea.start)
		setTranslation(workArea.start, v92_, 0, v92_)
		workArea.width = createTransformGroup("ridgeMarkerAreaWidth")
		link(v91_, workArea.width)
		setTranslation(workArea.width, -v92_, 0, v92_)
		workArea.height = createTransformGroup("ridgeMarkerAreaHeight")
		link(v91_, workArea.height)
		setTranslation(workArea.height, v92_, 0, -v92_)
		local v94_ = v93_ + 2 * v92_
		workArea.testNode = createTransformGroup("ridgeMarkerTestNode")
		link(v91_, workArea.testNode)
		setTranslation(workArea.testNode, 0, 0, v92_ + v94_)
	end
	if not superFunc(self, workArea, xmlFile, key) then
		return false
	end
	if workArea.type == WorkAreaType.RIDGEMARKER then
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. ".testArea#startNode", key .. ".ridgeMarkerArea#node")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. ".testArea#widthNode", key .. ".ridgeMarkerArea#node")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. ".testArea#heightNode", key .. ".ridgeMarkerArea#node")
	end
	if v91_ == nil then
		if workArea.type == WorkAreaType.RIDGEMARKER then
			Logging.xmlWarning(self.xmlFile, "Missing ridge marker node for ridge marker area \'%s\'", key)
		end
	elseif workArea.type == WorkAreaType.DEFAULT then
		workArea.type = WorkAreaType.RIDGEMARKER
	end
	return true
end

function RidgeMarker:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)
	if not superFunc(self, speedRotatingPart, xmlFile, key) then
		return false
	end
	speedRotatingPart.ridgeMarkerAnim = xmlFile:getValue(key .. "#ridgeMarkerAnim")
	speedRotatingPart.ridgeMarkerAnimTimeMax = xmlFile:getValue(key .. "#ridgeMarkerAnimTimeMax", 0.99)
	return true
end

function RidgeMarker:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
	if speedRotatingPart.ridgeMarkerAnim == nil or self:getAnimationTime(speedRotatingPart.ridgeMarkerAnim) >= speedRotatingPart.ridgeMarkerAnimTimeMax then
		return superFunc(self, speedRotatingPart)
	else
		return false
	end
end

function RidgeMarker:getCanBeSelected(superFunc)
	return true
end

-- Local values: spec, ridgeMarker, animTime
function RidgeMarker:getIsWorkAreaActive(superFunc, workArea)
	if workArea.type == WorkAreaType.RIDGEMARKER then
		local v106_ = self.spec_ridgeMarker
		if v106_.numRigdeMarkers == 0 then
			return false
		end
		local v107_ = v106_.workAreaToRidgeMarker[workArea.index]
		if v107_ ~= nil then
			local v108_ = self:getAnimationTime(v107_.animName)
			if v107_.maxWorkLimit < v108_ or v108_ < v107_.minWorkLimit then
				return false
			end
			if v106_.onlyActiveWhenLowered and not self:getIsLowered(false) then
				return false
			end
		end
	end
	return superFunc(self, workArea)
end

-- Local values: spec, _, actionEventId
function RidgeMarker:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v111_ = self.spec_ridgeMarker
		self:clearActionEventsTable(v111_.actionEvents)
		if isActiveForInputIgnoreSelection and v111_.numRigdeMarkers > 0 then
			local _, v112_ = self:addPoweredActionEvent(v111_.actionEvents, v111_.ridgeMarkerInputButton, self, RidgeMarker.actionEventToggleRidgeMarkers, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v112_, GS_PRIO_NORMAL)
			g_inputBinding:setActionEventText(v112_, g_i18n:getText("action_toggleRidgeMarker"))
		end
	end
end

-- Local values: spec, _, ridgeMarker, animTime, _, ridgeMarker, animTime
function RidgeMarker:onSetLowered(lowered)
	local v115_ = self.spec_ridgeMarker
	if lowered then
		for _, v116_ in pairs(v115_.ridgeMarkers) do
			if v116_.liftedAnimTime ~= nil then
				local v117_ = self:getAnimationTime(v116_.animName)
				if v117_ == v116_.liftedAnimTime then
					self:playAnimation(v116_.animName, 1, v117_, true)
				end
			end
		end
	else
		for _, v118_ in pairs(v115_.ridgeMarkers) do
			if v118_.liftedAnimTime ~= nil then
				local v119_ = self:getAnimationTime(v118_.animName)
				if v118_.liftedAnimTime < v119_ then
					self:setAnimationStopTime(v118_.animName, v118_.liftedAnimTime)
					self:playAnimation(v118_.animName, -1, v119_, true)
				end
			end
		end
	end
end

function RidgeMarker:onFoldStateChanged(direction, moveToMiddle)
	if not moveToMiddle and direction > 0 then
		self:setRidgeMarkerState(0, true)
	end
end

function RidgeMarker:onAIImplementStart()
	self:setRidgeMarkerState(0, true)
end

-- Local values: spec, newState
function RidgeMarker:actionEventToggleRidgeMarkers(actionName, inputValue, callbackState, isAnalog)
	local v125_ = self.spec_ridgeMarker
	local v126_ = (v125_.ridgeMarkerState + 1) % (v125_.numRigdeMarkers + 1)
	if self:canFoldRidgeMarker(v126_) then
		self:setRidgeMarkerState(v126_)
	end
end

-- Local values: spec, actionEvent, isVisible, newState
function RidgeMarker:updateActionEvents()
	local v128_ = self.spec_ridgeMarker
	local v129_ = v128_.actionEvents[v128_.ridgeMarkerInputButton]
	if v129_ ~= nil then
		local v130_ = v128_.numRigdeMarkers > 0 and self:canFoldRidgeMarker((v128_.ridgeMarkerState + 1) % (v128_.numRigdeMarkers + 1)) and true or false
		g_inputBinding:setActionEventActive(v129_.actionEventId, v130_)
	end
end
