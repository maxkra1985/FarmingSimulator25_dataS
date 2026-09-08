Enterable = {}
Enterable.ADDITIONAL_CHARACTER_XML_KEY = "vehicle.enterable.additionalCharacter"
Enterable.NICKNAME_RENDER_DISTANCE = 100
source("dataS/scripts/vehicles/specializations/events/VehiclePlayerStyleChangedEvent.lua")

function Enterable.prerequisitesPresent(self)
	return true
end
function Enterable.initSpecialization()
	Vehicle.INTERACTION_FLAG_ENTERABLE = Vehicle.registerInteractionFlag("ENTERABLE")
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("Enterable")
	v1_:register(XMLValueType.BOOL, "vehicle.enterable#isTabbable", "Vehicle is tabbable", true)
	v1_:register(XMLValueType.BOOL, "vehicle.enterable#canBeEnteredFromMenu", "Vehicle can be entered from menu", "same as #isTabbable")
	v1_:register(XMLValueType.BOOL, "vehicle.enterable.forceSelectionOnEnter", "Vehicle is selected on entering", false)
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.enterable.enterReferenceNode#node", "Enter reference node")
	v1_:register(XMLValueType.FLOAT, "vehicle.enterable.enterReferenceNode#interactionRadius", "Interaction radius", 6)
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.enterable.exitPoint#node", "Exit point")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.enterable.nicknameRenderNode#node", "Nickname rendering node", "root node")
	v1_:register(XMLValueType.VECTOR_TRANS, "vehicle.enterable.nicknameRenderNode#offset", "Nickname rendering offset")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.enterable.reverb#referenceNode", "Reference node for reverb calculations", "center of vehicle +2m Y")
	v1_:register(XMLValueType.STRING, "vehicle.enterable.enterAnimation#name", "Enter animation name")
	v1_:register(XMLValueType.STRING, "vehicle.enterable#customPlayerStylePresetName", "Custom player style preset")
	VehicleCharacter.registerCharacterXMLPaths(v1_, "vehicle.enterable.characterNode")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.enterable.additionalCharacter#node", "Additional character node")
	VehicleCharacter.registerCharacterXMLPaths(v1_, "vehicle.enterable.additionalCharacter")
	VehicleCamera.registerCameraXMLPaths(v1_, "vehicle.enterable.cameras.camera(?)")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.enterable.characterTargetNodeModifier(?)#node", "Target node")
	v1_:register(XMLValueType.STRING, "vehicle.enterable.characterTargetNodeModifier(?)#poseId", "Modifier pose id")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.enterable.characterTargetNodeModifier(?).state(?)#node", "State node")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.enterable.characterTargetNodeModifier(?).state(?)#referenceNode", "State is activated if this node moves or rotates")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.enterable.characterTargetNodeModifier(?).state(?)#directionReferenceNode", "State node is align to this node")
	v1_:register(XMLValueType.BOOL, "vehicle.enterable.characterTargetNodeModifier(?).state(?)#referenceNodeMovement", "The state is active as long as the reference node is moving/rotating. By default it\'s active while translation/rotation is different compared to the original state.", false)
	v1_:register(XMLValueType.STRING, "vehicle.enterable.characterTargetNodeModifier(?).state(?)#poseId", "Pose id")
	v1_:register(XMLValueType.FLOAT, "vehicle.enterable.characterTargetNodeModifier(?)#transitionTime", "Time between state changes", 0.1)
	v1_:register(XMLValueType.FLOAT, "vehicle.enterable.characterTargetNodeModifier(?)#transitionIdleDelay", "State is changed after this delay", 0.5)
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.enterable.mirrors.mirror(?)#node", "Mirror node")
	v1_:register(XMLValueType.INT, "vehicle.enterable.mirrors.mirror(?)#prio", "Priority", 2)
	Dashboard.registerDashboardXMLPaths(v1_, "vehicle.enterable.dashboards", {
		"time",
		"timeHours",
		"timeMinutes",
		"operatingTime",
		"outsideTemperature"
	})
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.enterable.sounds", "rain(?)")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.enterable.sounds", "hail(?)")
	v1_:register(XMLValueType.BOOL, Dashboard.GROUP_XML_KEY .. "#isEntered", "Is entered")
	v1_:addDelayedRegistrationFunc("Cylindered:movingTool", function(p2_, p3_)
		p2_:register(XMLValueType.BOOL, p3_ .. "#updateCharacterTargetModifier", "Update character target modifier state", false)
	end)
	v1_:addDelayedRegistrationFunc("Cylindered:movingPart", function(p4_, p5_)
		p4_:register(XMLValueType.BOOL, p5_ .. "#updateCharacterTargetModifier", "Update character target modifier state", false)
	end)
	v1_:setXMLSpecializationType()
	local v6_ = Vehicle.xmlSchemaSavegame
	VehicleCamera.registerCameraSavegameXMLPaths(v6_, "vehicles.vehicle(?).enterable.camera(?)")
	v6_:register(XMLValueType.INT, "vehicles.vehicle(?).enterable#activeCameraIndex", "Index of active camera", 1)
	v6_:register(XMLValueType.BOOL, "vehicles.vehicle(?).enterable#isTabbable", "Is tabbable", true)
	v6_:register(XMLValueType.BOOL, "vehicles.vehicle(?).enterable#isLeavingAllowed", "Is leaving allowed", true)
end

function Enterable.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onEnterVehicle")
	SpecializationUtil.registerEvent(vehicleType, "onLeaveVehicle")
	SpecializationUtil.registerEvent(vehicleType, "onCameraChanged")
	SpecializationUtil.registerEvent(vehicleType, "onVehicleCharacterChanged")
end

function Enterable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "onPlayerEnterVehicle", Enterable.onPlayerEnterVehicle)
	SpecializationUtil.registerFunction(vehicleType, "doLeaveVehicle", Enterable.doLeaveVehicle)
	SpecializationUtil.registerFunction(vehicleType, "onPlayerLeaveVehicle", Enterable.onPlayerLeaveVehicle)
	SpecializationUtil.registerFunction(vehicleType, "setActiveCameraIndex", Enterable.setActiveCameraIndex)
	SpecializationUtil.registerFunction(vehicleType, "addToolCameras", Enterable.addToolCameras)
	SpecializationUtil.registerFunction(vehicleType, "removeToolCameras", Enterable.removeToolCameras)
	SpecializationUtil.registerFunction(vehicleType, "getExitNode", Enterable.getExitNode)
	SpecializationUtil.registerFunction(vehicleType, "getUserPlayerStyle", Enterable.getUserPlayerStyle)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentPlayerStyle", Enterable.getCurrentPlayerStyle)
	SpecializationUtil.registerFunction(vehicleType, "setVehicleCharacter", Enterable.setVehicleCharacter)
	SpecializationUtil.registerFunction(vehicleType, "vehicleCharacterLoaded", Enterable.vehicleCharacterLoaded)
	SpecializationUtil.registerFunction(vehicleType, "onPlayerStyleChanged", Enterable.onPlayerStyleChanged)
	SpecializationUtil.registerFunction(vehicleType, "setRandomVehicleCharacter", Enterable.setRandomVehicleCharacter)
	SpecializationUtil.registerFunction(vehicleType, "restoreVehicleCharacter", Enterable.restoreVehicleCharacter)
	SpecializationUtil.registerFunction(vehicleType, "deleteVehicleCharacter", Enterable.deleteVehicleCharacter)
	SpecializationUtil.registerFunction(vehicleType, "getFormattedOperatingTime", Enterable.getFormattedOperatingTime)
	SpecializationUtil.registerFunction(vehicleType, "loadCharacterTargetNodeModifier", Enterable.loadCharacterTargetNodeModifier)
	SpecializationUtil.registerFunction(vehicleType, "updateCharacterTargetNodeModifier", Enterable.updateCharacterTargetNodeModifier)
	SpecializationUtil.registerFunction(vehicleType, "setCharacterTargetNodeStateDirty", Enterable.setCharacterTargetNodeStateDirty)
	SpecializationUtil.registerFunction(vehicleType, "resetCharacterTargetNodeStateDefaults", Enterable.resetCharacterTargetNodeStateDefaults)
	SpecializationUtil.registerFunction(vehicleType, "setMirrorVisible", Enterable.setMirrorVisible)
	SpecializationUtil.registerFunction(vehicleType, "getIsTabbable", Enterable.getIsTabbable)
	SpecializationUtil.registerFunction(vehicleType, "setIsTabbable", Enterable.setIsTabbable)
	SpecializationUtil.registerFunction(vehicleType, "getIsEnterable", Enterable.getIsEnterable)
	SpecializationUtil.registerFunction(vehicleType, "getIsEnterableFromMenu", Enterable.getIsEnterableFromMenu)
	SpecializationUtil.registerFunction(vehicleType, "getIsEntered", Enterable.getIsEntered)
	SpecializationUtil.registerFunction(vehicleType, "getIsControlled", Enterable.getIsControlled)
	SpecializationUtil.registerFunction(vehicleType, "getIsEnteredForInput", Enterable.getIsEnteredForInput)
	SpecializationUtil.registerFunction(vehicleType, "getControllerName", Enterable.getControllerName)
	SpecializationUtil.registerFunction(vehicleType, "getActiveCamera", Enterable.getActiveCamera)
	SpecializationUtil.registerFunction(vehicleType, "getVehicleCharacter", Enterable.getVehicleCharacter)
	SpecializationUtil.registerFunction(vehicleType, "getAllowCharacterVisibilityUpdate", Enterable.getAllowCharacterVisibilityUpdate)
	SpecializationUtil.registerFunction(vehicleType, "getDisableVehicleCharacterOnLeave", Enterable.getDisableVehicleCharacterOnLeave)
	SpecializationUtil.registerFunction(vehicleType, "loadCamerasFromXML", Enterable.loadCamerasFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadAdditionalCharacterFromXML", Enterable.loadAdditionalCharacterFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsAdditionalCharacterActive", Enterable.getIsAdditionalCharacterActive)
	SpecializationUtil.registerFunction(vehicleType, "getCanLeave", Enterable.getCanLeave)
	SpecializationUtil.registerFunction(vehicleType, "getCanLeaveVehicle", Enterable.getCanLeaveVehicle)
	SpecializationUtil.registerFunction(vehicleType, "getCanLeaveRideable", Enterable.getCanLeaveRideable)
	SpecializationUtil.registerFunction(vehicleType, "getIsLeavingAllowed", Enterable.getIsLeavingAllowed)
	SpecializationUtil.registerFunction(vehicleType, "setIsLeavingAllowed", Enterable.setIsLeavingAllowed)
	SpecializationUtil.registerFunction(vehicleType, "onEnterableMirrorSettingChanged", Enterable.onEnterableMirrorSettingChanged)
end

function Enterable.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsActive", Enterable.getIsActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsActiveForInput", Enterable.getIsActiveForInput)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDistanceToNode", Enterable.getDistanceToNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getInteractionHelp", Enterable.getInteractionHelp)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "interact", Enterable.interact)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsInteractive", Enterable.getIsInteractive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleSelectable", Enterable.getCanToggleSelectable)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleAttach", Enterable.getCanToggleAttach)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getActiveFarm", Enterable.getActiveFarm)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDashboardGroupFromXML", Enterable.loadDashboardGroupFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDashboardGroupActive", Enterable.getIsDashboardGroupActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "mountDynamic", Enterable.mountDynamic)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsInUse", Enterable.getIsInUse)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadExtraDependentParts", Enterable.loadExtraDependentParts)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateExtraDependentParts", Enterable.updateExtraDependentParts)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMapHotspotVisible", Enterable.getIsMapHotspotVisible)
end

function Enterable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Enterable)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Enterable)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Enterable)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", Enterable)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Enterable)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Enterable)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Enterable)
	SpecializationUtil.registerEventListener(vehicleType, "onPreUpdate", Enterable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Enterable)
	SpecializationUtil.registerEventListener(vehicleType, "onPostUpdate", Enterable)
	SpecializationUtil.registerEventListener(vehicleType, "onDrawUIInfo", Enterable)
	SpecializationUtil.registerEventListener(vehicleType, "onPreRegisterActionEvents", Enterable)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Enterable)
	SpecializationUtil.registerEventListener(vehicleType, "onSetBroken", Enterable)
end

-- Local values: spec, i, key, modifier, allMirrors, _, key, node, materialId, customShaderVariation, prio, shapesObjectMask, node, _
function Enterable:onLoad(savegame)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.mirrors.mirror(0)#index", "vehicle.enterable.mirrors.mirror(0)#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.enterReferenceNode", "vehicle.enterable.enterReferenceNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.enterReferenceNode#index", "vehicle.enterable.enterReferenceNode#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.enterable.enterReferenceNode#index", "vehicle.enterable.enterReferenceNode#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.exitPoint", "vehicle.enterable.exitPoint")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.exitPoint#index", "vehicle.enterable.exitPoint#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.enterable.exitPoint#index", "vehicle.enterable.exitPoint#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.characterNode", "vehicle.enterable.characterNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.characterNode#index", "vehicle.enterable.characterNode#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.enterable.characterNode#index", "vehicle.enterable.characterNode#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.nicknameRenderNode", "vehicle.enterable.nicknameRenderNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.enterAnimation", "vehicle.enterable.enterAnimation")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cameras.camera1", "vehicle.enterable.cameras.camera")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.enterable.cameras.camera1", "vehicle.enterable.cameras.camera")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.indoorHud.time", "vehicle.enterable.dashboards.dashboard with valueType \'time\'")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.indoorHud.operatingTime", "vehicle.enterable.dashboards.dashboard with valueType \'operatingTime\'")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.enterable.nicknameRenderNode#index", "vehicle.enterable.nicknameRenderNode#node")
	local v13_ = self.spec_enterable
	v13_.isTabbable = self.xmlFile:getValue("vehicle.enterable#isTabbable", true)
	v13_.canBeEnteredFromMenu = self.xmlFile:getValue("vehicle.enterable#canBeEnteredFromMenu", v13_.isTabbable)
	v13_.isEntered = false
	v13_.isControlled = false
	v13_.playerStyle = nil
	v13_.canUseEnter = true
	v13_.controllerFarmId = 0
	v13_.controllerUserId = 0
	v13_.isLeavingAllowed = true
	v13_.lastCameraWasInside = false
	v13_.disableCharacterOnLeave = true
	v13_.enterText = string.format("%s (%s)", g_i18n:getText("button_enterVehicle"), g_i18n:getText("passengerSeat_driver"))
	v13_.forceSelectionOnEnter = self.xmlFile:getValue("vehicle.enterable.forceSelectionOnEnter", false)
	v13_.enterReferenceNode = self.xmlFile:getValue("vehicle.enterable.enterReferenceNode#node", nil, self.components, self.i3dMappings)
	v13_.exitPoint = self.xmlFile:getValue("vehicle.enterable.exitPoint#node", nil, self.components, self.i3dMappings)
	v13_.interactionRadius = self.xmlFile:getValue("vehicle.enterable.enterReferenceNode#interactionRadius", 6)
	v13_.vehicleCharacter = VehicleCharacter.new(self)
	if v13_.vehicleCharacter ~= nil and not v13_.vehicleCharacter:load(self.xmlFile, "vehicle.enterable.characterNode", self.i3dMappings) then
		v13_.vehicleCharacter = nil
	end
	self:loadAdditionalCharacterFromXML(self.xmlFile)
	v13_.nicknameRendering = {}
	v13_.nicknameRendering.node = self.xmlFile:getValue("vehicle.enterable.nicknameRenderNode#node", nil, self.components, self.i3dMappings)
	v13_.nicknameRendering.offset = self.xmlFile:getValue("vehicle.enterable.nicknameRenderNode#offset", nil, true)
	if v13_.nicknameRendering.node == nil then
		if v13_.vehicleCharacter == nil or v13_.vehicleCharacter.characterDistanceRefNode == nil then
			v13_.nicknameRendering.node = self.components[1].node
		else
			v13_.nicknameRendering.node = v13_.vehicleCharacter.characterDistanceRefNode
			if v13_.nicknameRendering.offset == nil then
				v13_.nicknameRendering.offset = { 0, 1.5, 0 }
			end
		end
	end
	if v13_.nicknameRendering.offset == nil then
		v13_.nicknameRendering.offset = { 0, 4, 0 }
	end
	v13_.enterAnimation = self.xmlFile:getValue("vehicle.enterable.enterAnimation#name")
	if v13_.enterAnimation ~= nil and not self:getAnimationExists(v13_.enterAnimation) then
		Logging.xmlWarning(self.xmlFile, "Unable to find enter animation \'%s\'", v13_.enterAnimation)
	end
	v13_.customPlayerStylePresetName = self.xmlFile:getString("vehicle.enterable#customPlayerStylePresetName")
	self:loadCamerasFromXML(self.xmlFile, savegame)
	if v13_.numCameras == 0 then
		Logging.xmlError(self.xmlFile, "No cameras defined!")
		self:setLoadingState(VehicleLoadingState.ERROR)
	else
		v13_.characterTargetNodeReferenceToState = {}
		v13_.characterTargetNodeStatesDirty = false
		v13_.characterTargetNodeModifiers = {}
		local v14_ = 0
		while true do
			local v15_ = string.format("vehicle.enterable.characterTargetNodeModifier(%d)", v14_)
			if not self.xmlFile:hasProperty(v15_) then
				break
			end
			local v16_ = {}
			if self:loadCharacterTargetNodeModifier(v16_, self.xmlFile, v15_) then
				local v17_ = v13_.characterTargetNodeModifiers
				table.insert(v17_, v16_)
			end
			v14_ = v14_ + 1
		end
		local v18_ = {}
		if g_isDevelopmentVersion then
			I3DUtil.getNodesByShaderParam(self.rootNode, "reflectionScale", v18_)
		end
		v13_.mirrors = {}
		for _, v19_ in self.xmlFile:iterator("vehicle.enterable.mirrors.mirror") do
			local v20_ = self.xmlFile:getValue(v19_ .. "#node", nil, self.components, self.i3dMappings)
			if v20_ ~= nil then
				if getHasClassId(v20_, ClassIds.SHAPE) then
					local v21_ = getMaterial(v20_, 0)
					if getMaterialCustomShaderVariation(v21_) == "useCustomReflectionCamera" then
						v18_[v20_] = nil
						setVisibility(v20_, false)
					else
						local v22_ = self.xmlFile:getValue(v19_ .. "#prio", 2)
						local v23_ = ObjectMask.SHAPE_VIS_MIRROR
						local v24_ = ObjectMask.SHAPE_VIS_MIRROR_ONLY
						local v25_ = bit32.bor(v23_, v24_)
						setReflectionMapObjectMasks(v20_, v25_, ObjectMask.LIGHT_VIS_MIRROR, true)
						if getObjectMask(v20_) == 0 then
							setObjectMask(v20_, 16711807)
						end
						local v26_ = v13_.mirrors
						local v27_ = {
							["node"] = v20_,
							["prio"] = v22_,
							["cosAngle"] = 1,
							["parentNode"] = getParent(v20_)
						}
						table.insert(v26_, v27_)
						v18_[v20_] = nil
					end
				else
					Logging.xmlWarning(self.xmlFile, "given node %q for mirror %q is not of type SHAPE, ignoring", getName(v20_), v19_)
				end
			end
		end
		for v28_, _ in pairs(v18_) do
			Logging.xmlError(self.xmlFile, "Found Mesh \'%s\' with mirrorShader that is not entered in the vehicle XML", getName(v28_))
		end
		self:setMirrorVisible(v13_.cameras[v13_.camIndex].useMirror)
		v13_.lastIsRaining = false
		v13_.lastIsHailing = false
		v13_.weatherObject = g_currentMission.environment.weather
		if self.isClient then
			v13_.rainSamples = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.enterable.sounds", "rain", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
			v13_.hasRainSamples = #v13_.rainSamples > 0
			v13_.hailSamples = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.enterable.sounds", "hail", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
			v13_.hasHailSamples = #v13_.hailSamples > 0
		end
		v13_.reverbReferenceNode = self.xmlFile:getValue("vehicle.enterable.reverb#referenceNode", nil, self.components, self.i3dMappings)
		if v13_.reverbReferenceNode == nil then
			v13_.reverbReferenceNode = createTransformGroup("ReverebRefNode")
			link(self.rootNode, v13_.reverbReferenceNode)
			setTranslation(v13_.reverbReferenceNode, 0, 2, 0)
		end
		v13_.dirtyFlag = self:getNextDirtyFlag()
		v13_.playerHotspot = PlayerHotspot.new()
		v13_.playerHotspot:setVehicle(self)
		self.needWaterInfo = true
		g_currentMission.vehicleSystem:addInteractiveVehicle(self)
		g_currentMission.vehicleSystem:addEnterableVehicle(self)
		g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.MAX_NUM_MIRRORS], self.onEnterableMirrorSettingChanged, self)
	end
end

-- Local values: spec, i, camera
function Enterable:onPostLoad(savegame)
	local v31_ = self.spec_enterable
	for v32_ = 1, #v31_.cameras do
		v31_.cameras[v32_]:onPostLoad(savegame)
	end
	if savegame ~= nil and not savegame.resetVehicles then
		self:setIsTabbable(savegame.xmlFile:getValue(savegame.key .. ".enterable#isTabbable", v31_.isTabbable))
		v31_.camIndex = savegame.xmlFile:getValue(savegame.key .. ".enterable#activeCameraIndex", 1)
		v31_.isLeavingAllowed = savegame.xmlFile:getValue(savegame.key .. ".enterable#isLeavingAllowed", true)
	end
end

-- Local values: spec
function Enterable:onLoadFinished(savegame)
	local v34_ = self.spec_enterable
	if v34_.isControlled then
		v34_.playerHotspot:setOwnerFarmId(self:getActiveFarm())
		g_currentMission:addMapHotspot(v34_.playerHotspot)
	end
end

-- Local values: time, timeHours, timeMinutes, operatingTime, outsideTemperature
function Enterable:onRegisterDashboardValueTypes()
	local v36_ = DashboardValueType.new("enterable", "time")
	v36_:setValue(g_currentMission.environment, "getEnvironmentTime")
	self:registerDashboardValueType(v36_)
	local v37_ = DashboardValueType.new("enterable", "timeHours")
	v37_:setValue(g_currentMission.environment, function(p38_)
		local v39_ = p38_:getEnvironmentTime()
		return math.floor(v39_) + v39_ % 1 * 100 / 60
	end)
	self:registerDashboardValueType(v37_)
	local v40_ = DashboardValueType.new("enterable", "timeMinutes")
	v40_:setValue(g_currentMission.environment, function(p41_)
		return p41_:getEnvironmentTime() % 1 * 100
	end)
	self:registerDashboardValueType(v40_)
	local v42_ = DashboardValueType.new("enterable", "operatingTime")
	v42_:setValue(self, self.getFormattedOperatingTime)
	self:registerDashboardValueType(v42_)
	local v43_ = DashboardValueType.new("enterable", "outsideTemperature")
	v43_:setValue(g_currentMission.environment.weather, "getCurrentTemperature")
	self:registerDashboardValueType(v43_)
end

-- Local values: spec, player, _, camera
function Enterable:onDelete()
	local v45_ = self.spec_enterable
	if v45_.isControlled then
		local v46_ = g_currentMission.playerSystem:getPlayerByUserId(self.spec_enterable.controllerUserId)
		if v46_ ~= nil then
			v46_:leaveVehicle(self, true)
		end
	end
	if v45_.vehicleCharacter ~= nil then
		v45_.vehicleCharacter:delete()
		v45_.vehicleCharacter = nil
	end
	if v45_.cameras ~= nil then
		for _, v47_ in ipairs(v45_.cameras) do
			v47_:delete()
		end
	end
	if v45_.playerHotspot ~= nil then
		g_currentMission:removeMapHotspot(v45_.playerHotspot)
		v45_.playerHotspot:delete()
		v45_.playerHotspot = nil
	end
	g_soundManager:deleteSamples(v45_.rainSamples)
	g_soundManager:deleteSamples(v45_.hailSamples)
	v45_.weatherObject = nil
	g_currentMission.vehicleSystem:removeEnterableVehicle(self)
	g_currentMission.vehicleSystem:removeInteractiveVehicle(self)
end

-- Local values: spec, isControlled, userId, player
function Enterable:onReadStream(streamId, connection)
	self.spec_enterable.isTabbable = streamReadBool(streamId)
	if streamReadBool(streamId) then
		local v50_ = User.streamReadUserId(streamId)
		local v51_ = g_playerSystem:getPlayerByUserId(v50_)
		if v51_ ~= nil then
			v51_:onEnterVehicle(self)
		end
	end
end

-- Local values: spec
function Enterable:onWriteStream(streamId, connection)
	local v54_ = self.spec_enterable
	streamWriteBool(streamId, v54_.isTabbable)
	if streamWriteBool(streamId, v54_.isControlled) then
		User.streamWriteUserId(streamId, v54_.controllerUserId)
	end
end

-- Local values: spec, i
function Enterable:saveToXMLFile(xmlFile, key, usedModNames)
	local v59_ = self.spec_enterable
	for v60_ = 1, #v59_.cameras do
		v59_.cameras[v60_]:saveToXMLFile(xmlFile, string.format("%s.camera(%d)", key, v60_ - 1), usedModNames)
	end
	xmlFile:setValue(key .. "#activeCameraIndex", v59_.camIndex)
	xmlFile:setValue(key .. "#isTabbable", v59_.isTabbable)
	xmlFile:setValue(key .. "#isLeavingAllowed", v59_.isLeavingAllowed)
end

-- Local values: spec, name
function Enterable:saveStatsToXMLFile(xmlFile, key)
	if self.spec_enterable.isControlled then
		local v64_ = self:getControllerName()
		if v64_ ~= nil then
			setXMLString(xmlFile, key .. "#controller", HTMLUtil.encodeToHTML(v64_))
		end
	end
	return nil
end

-- Local values: spec, keepDirty, referenceNode, states, _, state
function Enterable:onPreUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v66_ = self.spec_enterable
	if v66_.characterTargetNodeStatesDirty then
		local v67_ = false
		for v68_, v69_ in pairs(v66_.characterTargetNodeReferenceToState) do
			for _, v70_ in ipairs(v69_) do
				if v70_.dirtyFrameOffset ~= nil and v70_.dirtyFrameOffset > 0 then
					v70_.dirtyFrameOffset = v70_.dirtyFrameOffset - 1
					if v70_.dirtyFrameOffset <= 0 then
						self:setCharacterTargetNodeStateDirty(v68_, false)
						v70_.dirtyFrameOffset = nil
					end
					v67_ = true
				end
			end
		end
		if not v67_ then
			v66_.characterTargetNodeStatesDirty = false
		end
	end
end

-- Local values: spec, _, modifier, character, node, targets, isRaining, isHailing, x, y, z, dirX, dirY, dirZ
function Enterable:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self:getIsControlled() then
		if self.isClient then
			local v74_ = self.spec_enterable
			for _, v75_ in ipairs(v74_.characterTargetNodeModifiers) do
				self:updateCharacterTargetNodeModifier(dt, v75_)
			end
			if self:getIsAdditionalCharacterActive() ~= v74_.additionalCharacterActive then
				v74_.additionalCharacterActive = not v74_.additionalCharacterActive
				local v76_ = self:getVehicleCharacter()
				if v76_ ~= nil then
					local v77_ = v74_.defaultCharacterNode
					local v78_ = v74_.defaultCharacterTargets
					if v74_.additionalCharacterActive then
						v78_ = v74_.additionalCharacterTargets
						v77_ = v74_.additionalCharacterNode
					end
					v76_:setIKChainTargets(v78_)
					v76_.characterNode = v77_
					if v76_.playerModel.rootNode ~= nil then
						link(v77_, v76_.playerModel.rootNode)
					end
				end
			end
			if v74_.hasRainSamples then
				local v79_ = v74_.weatherObject:getRainFallScale() > 0
				if v79_ ~= v74_.lastIsRaining then
					if v79_ then
						g_soundManager:playSamples(v74_.rainSamples)
					else
						g_soundManager:stopSamples(v74_.rainSamples)
					end
					v74_.lastIsRaining = v79_
				end
			end
			if v74_.hasHailSamples then
				local v80_ = v74_.weatherObject:getIsHailing()
				if v80_ ~= v74_.lastIsHailing then
					if v80_ then
						g_soundManager:playSamples(v74_.hailSamples)
					else
						g_soundManager:stopSamples(v74_.hailSamples)
					end
					v74_.lastIsHailing = v80_
				end
			end
			if isActiveForInputIgnoreSelection then
				local v81_, v82_, v83_ = getWorldTranslation(self.rootNode)
				local v84_, v85_, v86_ = localDirectionToWorld(self.rootNode, 0, 0, 1)
				g_currentMission.activatableObjectsSystem:setPosition(v81_, v82_, v83_)
				g_currentMission.activatableObjectsSystem:setDirection(v84_, v85_, v86_)
			end
		end
		self.rootVehicle:raiseActive()
	end
end

-- Local values: spec
function Enterable:onPostUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v89_ = self.spec_enterable
	if self.isClient then
		if v89_.isEntered and (v89_.vehicleCharacter ~= nil and (v89_.vehicleCharacter.characterSpineNode ~= nil and v89_.vehicleCharacter.characterSpineSpeedDepended)) then
			v89_.vehicleCharacter:setSpineDirty(self.lastSpeedAcceleration)
		end
		if self.finishedFirstUpdate then
			if self:getIsEntered() then
				v89_.activeCamera:update(dt)
			end
			if self:getAllowCharacterVisibilityUpdate() and v89_.vehicleCharacter ~= nil then
				v89_.vehicleCharacter:updateVisibility()
			end
		end
		if self:getIsControlled() then
			if v89_.vehicleCharacter ~= nil then
				v89_.vehicleCharacter:update(dt)
			end
			if v89_.activeCamera ~= nil and v89_.activeCamera.useMirror then
				self:setMirrorVisible(true)
			end
		end
	end
end

-- Local values: spec, visible, distance, x, y, z
function Enterable:onDrawUIInfo()
	local v91_ = self.spec_enterable
	local v92_ = not (g_gui:getIsGuiVisible() or g_noHudModeEnabled)
	if v92_ then
		v92_ = g_gameSettings:getValue(GameSettings.SETTING.SHOW_MULTIPLAYER_NAMES)
	end
	if not v91_.isEntered and (self.isClient and (v91_.isControlled and (v92_ and (self:getIsActive() and calcDistanceFrom(v91_.nicknameRendering.node, g_cameraManager:getActiveCamera()) <= Enterable.NICKNAME_RENDER_DISTANCE)))) then
		local v93_, v94_, v95_ = getWorldTranslation(v91_.nicknameRendering.node)
		local v96_ = v93_ + v91_.nicknameRendering.offset[1]
		local v97_ = v94_ + v91_.nicknameRendering.offset[2]
		local v98_ = v95_ + v91_.nicknameRendering.offset[3]
		Utils.renderTextAtWorldPosition(v96_, v97_, v98_, self:getControllerName(), getCorrectTextSize(0.02), 0)
	end
end

-- Local values: spec, i, cameraKey, camera
function Enterable:loadCamerasFromXML(xmlFile, savegame)
	local v102_ = self.spec_enterable
	XMLUtil.checkDeprecatedXMLElements(xmlFile, "vehicle.cameras.camera(0)#index", "vehicle.enterable.cameras.camera(0)#node")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, "vehicle.cameras.camera(0).raycastNode(0)#index", "vehicle.enterable.cameras.camera(0).raycastNode(0)#node")
	v102_.cameras = {}
	local v103_ = 0
	while true do
		local v104_ = string.format("vehicle.enterable.cameras.camera(%d)", v103_)
		if not xmlFile:hasProperty(v104_) then
			break
		end
		local v105_ = VehicleCamera.new(self)
		if v105_:loadFromXML(xmlFile, v104_, savegame, v103_) then
			local v106_ = v102_.cameras
			table.insert(v106_, v105_)
		end
		v103_ = v103_ + 1
	end
	v102_.numCameras = #v102_.cameras
	v102_.camIndex = 1
end

-- Local values: spec
function Enterable:loadAdditionalCharacterFromXML(xmlFile)
	local v109_ = self.spec_enterable
	v109_.additionalCharacterNode = xmlFile:getValue("vehicle.enterable.additionalCharacter#node", nil, self.components, self.i3dMappings)
	v109_.additionalCharacterTargets = {}
	IKUtil.loadIKChainTargets(xmlFile, "vehicle.enterable.additionalCharacter", self.components, v109_.additionalCharacterTargets, self.i3dMappings)
	v109_.additionalCharacterActive = false
	if v109_.vehicleCharacter ~= nil then
		v109_.defaultCharacterNode = v109_.vehicleCharacter.characterNode
		v109_.defaultCharacterTargets = v109_.vehicleCharacter:getIKChainTargets()
	end
end

function Enterable.getIsAdditionalCharacterActive(self)
	return false
end

-- Local values: j, stateKey, node, state, spec
function Enterable:loadCharacterTargetNodeModifier(entry, xmlFile, xmlKey)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, xmlKey .. "#index", xmlKey .. "#node")
	entry.node = xmlFile:getValue(xmlKey .. "#node", nil, self.components, self.i3dMappings)
	if entry.node == nil then
		return false
	end
	entry.parent = getParent(entry.node)
	entry.translationOffset = { getTranslation(entry.node) }
	entry.rotationOffset = { getRotation(entry.node) }
	entry.poseId = xmlFile:getValue(xmlKey .. "#poseId")
	entry.states = {}
	local v114_ = 0
	while true do
		local v115_ = string.format("%s.state(%d)", xmlKey, v114_)
		if not xmlFile:hasProperty(v115_) then
			break
		end
		XMLUtil.checkDeprecatedXMLElements(xmlFile, v115_ .. "#index", v115_ .. "#node")
		local v116_ = xmlFile:getValue(v115_ .. "#node", nil, self.components, self.i3dMappings)
		if v116_ == nil then
			Logging.xmlWarning(self.xmlFile, "Missing node for state \'%s\'", v115_)
		else
			local v117_ = {
				["node"] = v116_,
				["referenceNode"] = xmlFile:getValue(v115_ .. "#referenceNode", nil, self.components, self.i3dMappings),
				["directionReferenceNode"] = xmlFile:getValue(v115_ .. "#directionReferenceNode", nil, self.components, self.i3dMappings),
				["referenceNodeMovement"] = xmlFile:getValue(v115_ .. "#referenceNodeMovement", false),
				["poseId"] = self.xmlFile:getValue(v115_ .. "#poseId")
			}
			if v117_.referenceNode ~= nil then
				v117_.defaultRotation = { getRotation(v117_.referenceNode) }
				v117_.defaultTranslation = { getTranslation(v117_.referenceNode) }
				local v118_ = self.spec_enterable
				if v118_.characterTargetNodeReferenceToState[v117_.referenceNode] == nil then
					v118_.characterTargetNodeReferenceToState[v117_.referenceNode] = {}
				end
				local v119_ = v118_.characterTargetNodeReferenceToState[v117_.referenceNode]
				table.insert(v119_, v117_)
				local v120_ = entry.states
				table.insert(v120_, v117_)
			end
		end
		v114_ = v114_ + 1
	end
	entry.transitionTime = self.xmlFile:getValue(xmlKey .. "#transitionTime", 0.1) * 1000
	entry.transitionAlpha = 1
	entry.transitionIdleDelay = self.xmlFile:getValue(xmlKey .. "#transitionIdleDelay", 0.5) * 1000
	entry.transitionIdleTime = 0
	return true
end

-- Local values: node, poseId, _, state, wx, wy, wz, lx, ly, lz, dx, dy, dz, isDirty, allowSwitch, transStartPos, transEndPos, rx, ry, rz, character, x, y, z, qx, qy, qz, qw
function Enterable:updateCharacterTargetNodeModifier(dt, modifier)
	local v124_ = modifier.parent
	local v125_ = modifier.poseId
	for _, v126_ in pairs(modifier.states) do
		if v126_.isActive then
			v124_ = v126_.node
			v125_ = v126_.poseId or v125_
			if v126_.directionReferenceNode ~= nil then
				local v127_, v128_, v129_ = getWorldTranslation(v126_.directionReferenceNode)
				local v130_, v131_, v132_ = getTranslation(v126_.node)
				local v133_, v134_, v135_ = worldToLocal(getParent(v126_.node), v127_, v128_, v129_)
				setDirection(v126_.node, v133_ - v130_, v134_ - v131_, v135_ - v132_, 0, 1, 0)
			end
		end
	end
	local v136_ = modifier.transitionAlpha < 1
	local v137_ = v124_ ~= modifier.parent
	if not v137_ then
		modifier.transitionIdleTime = modifier.transitionIdleTime + dt
		if modifier.transitionIdleTime > modifier.transitionIdleDelay then
			modifier.transitionIdleTime = 0
			v137_ = true
		end
	end
	if not v137_ or getParent(modifier.node) == v124_ then
		::l16::
		if v136_ then
			local v138_ = modifier.transitionAlpha + dt / modifier.transitionTime
			modifier.transitionAlpha = math.min(1, v138_)
			local v139_, v140_, v141_ = MathUtil.vector3ArrayLerp(modifier.transitionStartPos, modifier.transitionEndPos, modifier.transitionAlpha)
			setTranslation(modifier.node, v139_, v140_, v141_)
			local v142_, v143_, v144_, v145_ = MathUtil.slerpQuaternionShortestPath(modifier.transitionStartQuat[1], modifier.transitionStartQuat[2], modifier.transitionStartQuat[3], modifier.transitionStartQuat[4], modifier.transitionEndQuat[1], modifier.transitionEndQuat[2], modifier.transitionEndQuat[3], modifier.transitionEndQuat[4], modifier.transitionAlpha)
			setQuaternion(modifier.node, v142_, v143_, v144_, v145_)
		end
		return
	end
	local v146_ = { localToLocal(modifier.node, v124_, 0, 0, 0) }
	local v147_ = v124_ ~= modifier.parent and { 0, 0, 0 } or modifier.translationOffset
	modifier.transitionStartPos = v146_
	modifier.transitionEndPos = v147_
	local v148_ = v147_[1] - v146_[1]
	if math.abs(v148_) < 0.001 then
		local v149_ = v147_[2] - v146_[2]
		if math.abs(v149_) < 0.001 then
			local v150_ = v147_[3] - v146_[3]
			if math.abs(v150_) < 0.001 then
				modifier.transitionAlpha = 1
				::l24::
				v136_ = true
				local v151_, v152_, v153_ = localRotationToLocal(modifier.node, v124_, 0, 0, 0)
				modifier.transitionStartQuat = { mathEulerToQuaternion(v151_, v152_, v153_) }
				modifier.transitionEndQuat = {
					0,
					0,
					0,
					1
				}
				if v124_ == modifier.parent then
					local v154_ = {}
					local v155_ = mathEulerToQuaternion
					local v156_ = modifier.rotationOffset
					__set_list(v154_, 1, {v155_(unpack(v156_))})
					modifier.transitionEndQuat = v154_
				end
				link(v124_, modifier.node)
				if v125_ ~= nil then
					local v157_ = self:getVehicleCharacter()
					if v157_ ~= nil then
						v157_:setIKChainPoseByTarget(modifier.node, v125_)
					end
				end
				goto l16
			end
		end
	end
	modifier.transitionAlpha = 0
	goto l24
end

-- Local values: spec, states, i, state, rx, ry, rz, refX, refY, refZ, x, y, z
function Enterable:setCharacterTargetNodeStateDirty(referenceNode, forceActive)
	local v161_ = self.spec_enterable
	local v162_ = v161_.characterTargetNodeReferenceToState[referenceNode]
	if v162_ ~= nil then
		for v163_ = 1, #v162_ do
			local v164_ = v162_[v163_]
			v164_.isActive = forceActive == true
			local v165_, v166_, v167_ = getRotation(v164_.referenceNode)
			local v168_ = v164_.defaultRotation
			local v169_, v170_, v171_ = unpack(v168_)
			local v172_ = v165_ - v169_
			local v173_ = math.abs(v172_)
			local v174_ = v166_ - v170_
			local v175_ = v173_ + math.abs(v174_)
			local v176_ = v167_ - v171_
			if v175_ + math.abs(v176_) > 0.00001 then
				v164_.isActive = true
			end
			local v177_, v178_, v179_ = getTranslation(v164_.referenceNode)
			local v180_ = v164_.defaultTranslation
			local v181_, v182_, v183_ = unpack(v180_)
			local v184_ = v177_ - v181_
			local v185_ = math.abs(v184_)
			local v186_ = v178_ - v182_
			local v187_ = v185_ + math.abs(v186_)
			local v188_ = v179_ - v183_
			if v187_ + math.abs(v188_) > 0.00001 then
				v164_.isActive = true
			end
			if v164_.referenceNodeMovement then
				local v189_ = v164_.defaultRotation
				local v190_ = v164_.defaultRotation
				local v191_ = v164_.defaultRotation
				v189_[1] = v165_
				v190_[2] = v166_
				v191_[3] = v167_
				local v192_ = v164_.defaultTranslation
				local v193_ = v164_.defaultTranslation
				local v194_ = v164_.defaultTranslation
				v192_[1] = v177_
				v193_[2] = v178_
				v194_[3] = v179_
				if v164_.isActive then
					v164_.dirtyFrameOffset = 2
					v161_.characterTargetNodeStatesDirty = true
				end
			end
		end
	end
end

-- Local values: spec, states, i, state
function Enterable:resetCharacterTargetNodeStateDefaults(referenceNode)
	local v197_ = self.spec_enterable.characterTargetNodeReferenceToState[referenceNode]
	if v197_ ~= nil then
		for v198_ = 1, #v197_ do
			local v199_ = v197_[v198_]
			local v200_ = v199_.defaultRotation
			local v201_ = v199_.defaultRotation
			local v202_ = v199_.defaultRotation
			local v203_, v204_, v205_ = getRotation(v199_.referenceNode)
			v200_[1] = v203_
			v201_[2] = v204_
			v202_[3] = v205_
			local v206_ = v199_.defaultTranslation
			local v207_ = v199_.defaultTranslation
			local v208_ = v199_.defaultTranslation
			local v209_, v210_, v211_ = getTranslation(v199_.referenceNode)
			v206_[1] = v209_
			v207_[2] = v210_
			v208_[3] = v211_
		end
	end
end

-- Local values: spec, rootAttacherVehicle, i, camera
function Enterable:onPlayerEnterVehicle(isControlling, playerStyle, farmId, userId)
	local v217_ = self.spec_enterable
	self:raiseActive()
	v217_.isControlled = true
	v217_.isEntered = isControlling
	v217_.playerStyle = playerStyle
	v217_.canUseEnter = false
	v217_.controllerFarmId = farmId
	v217_.controllerUserId = userId
	if v217_.forceSelectionOnEnter then
		local v218_ = self.rootVehicle
		if v218_ ~= self then
			v218_:setSelectedImplementByObject(self)
		end
	end
	if v217_.isEntered then
		if g_gameSettings:getValue(GameSettings.SETTING.IS_HEAD_TRACKING_ENABLED) and isHeadTrackingAvailable() then
			for v219_, v220_ in pairs(v217_.cameras) do
				if v220_.isInside then
					v217_.camIndex = v219_
					break
				end
			end
		end
		if g_gameSettings:getValue(GameSettings.SETTING.RESET_CAMERA) then
			v217_.camIndex = 1
		end
		self:setActiveCameraIndex(v217_.camIndex)
		g_currentMission.vehicleSystem:setEnteredVehicle(self)
	end
	if v217_.playerHotspot ~= nil then
		v217_.playerHotspot:setOwnerFarmId(self:getActiveFarm())
		g_currentMission:addMapHotspot(v217_.playerHotspot)
		v217_.playerHotspot:setPlayer(g_playerSystem:getPlayerByUserId(userId))
	end
	if not self:getIsAIActive() then
		self:setVehicleCharacter(playerStyle)
		if v217_.enterAnimation ~= nil and self.playAnimation ~= nil then
			self:playAnimation(v217_.enterAnimation, 1, nil, true)
		end
	end
	self.isActiveForLocalSound = self:getIsActiveForInput(true, true)
	SpecializationUtil.raiseEvent(self, "onEnterVehicle", isControlling)
	self.rootVehicle:raiseStateChange(VehicleStateChange.ENTER_VEHICLE, self, isControlling)
	if v217_.isEntered and self.isClient then
		g_messageCenter:subscribe(MessageType.INPUT_BINDINGS_CHANGED, self.requestActionEventUpdate, self)
		self:requestActionEventUpdate()
	end
	if self.isServer and (not isControlling and (g_currentMission.trafficSystem ~= nil and g_currentMission.trafficSystem.trafficSystemId ~= 0)) then
		addTrafficSystemPlayer(g_currentMission.trafficSystem.trafficSystemId, self.components[1].node)
	end
	self:activate()
end

-- Local values: spec
function Enterable:getCanLeave()
	return self.spec_enterable.isEntered
end

-- Local values: isNotHorse
function Enterable:getCanLeaveVehicle()
	local v223_ = self.spec_rideable == nil
	if v223_ then
		v223_ = self:getCanLeave()
	end
	return v223_
end

-- Local values: isHorse
function Enterable:getCanLeaveRideable()
	local v225_ = self.spec_rideable ~= nil
	if v225_ then
		v225_ = self:getCanLeave()
	end
	return v225_
end

function Enterable:getIsLeavingAllowed()
	return self.spec_enterable.isLeavingAllowed
end

function Enterable:setIsLeavingAllowed(isAllowed)
	self.spec_enterable.isLeavingAllowed = isAllowed
end

-- Local values: spec
function Enterable:onEnterableMirrorSettingChanged()
	local v230_ = self.spec_enterable
	self:setMirrorVisible(v230_.cameras[v230_.camIndex].useMirror)
end

function Enterable:doLeaveVehicle()
	if self:getCanLeave() and self:getIsLeavingAllowed() then
		g_localPlayer:leaveVehicle()
	end
end

-- Local values: spec, wasEntered
function Enterable:onPlayerLeaveVehicle()
	local v233_ = self.spec_enterable
	g_currentMission:removePauseListeners(self)
	local v234_ = v233_.isEntered
	if v233_.activeCamera ~= nil and v233_.isEntered then
		v233_.lastCameraWasInside = v233_.activeCamera.isInside
		v233_.activeCamera:onDeactivate()
		g_soundManager:setIsIndoor(false)
		g_currentMission.ambientSoundSystem:setIsIndoor(false)
		g_currentMission.environment.environmentMaskSystem:setIsIndoor(false)
		g_currentMission.activatableObjectsSystem:deactivate(Vehicle.INPUT_CONTEXT_NAME)
		if self.isClient then
			g_soundManager:stopSamples(v233_.rainSamples)
			v233_.lastIsRaining = false
			g_soundManager:stopSamples(v233_.hailSamples)
			v233_.lastIsHailing = false
		end
	end
	if v233_.playerHotspot ~= nil then
		g_currentMission:removeMapHotspot(v233_.playerHotspot)
		v233_.playerHotspot:setPlayer(nil)
	end
	v233_.isControlled = false
	v233_.isEntered = false
	v233_.playerIndex = 0
	v233_.playerColorIndex = 0
	v233_.canUseEnter = true
	v233_.controllerFarmId = 0
	v233_.controllerUserId = 0
	g_currentMission:setLastInteractionTime(200)
	if v233_.vehicleCharacter ~= nil and self:getDisableVehicleCharacterOnLeave() then
		self:deleteVehicleCharacter()
	end
	if v233_.enterAnimation ~= nil and self.playAnimation ~= nil then
		self:playAnimation(v233_.enterAnimation, -1, nil, true)
	end
	self:setMirrorVisible(false)
	SpecializationUtil.raiseEvent(self, "onLeaveVehicle", v234_)
	self.rootVehicle:raiseStateChange(VehicleStateChange.LEAVE_VEHICLE, self)
	if v234_ and self.isClient then
		g_messageCenter:unsubscribe(MessageType.INPUT_BINDINGS_CHANGED, self)
		self:requestActionEventUpdate()
		if g_touchHandler ~= nil then
			g_touchHandler:removeGestureListener(self.touchListenerDoubleTab)
		end
	end
	if self.isServer and (not v233_.isEntered and (g_currentMission.trafficSystem ~= nil and g_currentMission.trafficSystem.trafficSystemId ~= 0)) then
		removeTrafficSystemPlayer(g_currentMission.trafficSystem.trafficSystemId, self.components[1].node)
	end
	if self:getDeactivateOnLeave() then
		self:deactivate()
	end
end

function Enterable:getIsMapHotspotVisible(superFunc)
	if superFunc(self) then
		return not self.spec_enterable.isControlled
	else
		return false
	end
end

-- Local values: spec, activeCamera
function Enterable:setActiveCameraIndex(index)
	local v239_ = self.spec_enterable
	if v239_.camIndex ~= index or (v239_.activeCamera == nil or g_cameraManager.activeCameraNode ~= v239_.activeCamera.cameraNode) then
		if v239_.activeCamera ~= nil then
			v239_.activeCamera:onDeactivate()
		end
		v239_.camIndex = index
		if v239_.camIndex > v239_.numCameras then
			v239_.camIndex = 1
		end
		local v240_ = v239_.cameras[v239_.camIndex]
		v239_.activeCamera = v240_
		v240_:onActivate()
		g_soundManager:setIsIndoor(not v240_.useOutdoorSounds)
		g_currentMission.ambientSoundSystem:setIsIndoor(not v240_.useOutdoorSounds)
		g_currentMission.environment.environmentMaskSystem:setIsIndoor(not v240_.useOutdoorSounds)
		self:setMirrorVisible(v240_.useMirror)
		g_currentMission.environmentAreaSystem:setReferenceNode(v240_.cameraNode)
		SpecializationUtil.raiseEvent(self, "onCameraChanged", v240_, v239_.camIndex)
	end
end

-- Local values: spec, _, toolCamera
function Enterable:addToolCameras(cameras)
	local v243_ = self.spec_enterable
	for _, v244_ in pairs(cameras) do
		local v245_ = v243_.cameras
		table.insert(v245_, v244_)
	end
	v243_.numCameras = #v243_.cameras
end

-- Local values: spec, isToolCameraActive, j, camera, _, toolCamera
function Enterable:removeToolCameras(cameras)
	local v248_ = self.spec_enterable
	local v249_ = false
	for v250_ = #v248_.cameras, 1, -1 do
		local v251_ = v248_.cameras[v250_]
		for _, v252_ in pairs(cameras) do
			if v252_ == v251_ then
				table.remove(v248_.cameras, v250_)
				if v250_ == v248_.camIndex then
					v249_ = true
				end
				break
			end
		end
	end
	v248_.numCameras = #v248_.cameras
	if v249_ then
		if v248_.activeCamera ~= nil then
			v248_.activeCamera:onDeactivate()
		end
		v248_.camIndex = 1
		self:setActiveCameraIndex(v248_.camIndex)
	end
end

-- Local values: spec
function Enterable:getExitNode(player)
	return self.spec_enterable.exitPoint
end

function Enterable:getUserPlayerStyle()
	return self.spec_enterable.playerStyle
end

-- Local values: spec
function Enterable:getCurrentPlayerStyle()
	local v256_ = self.spec_enterable
	if v256_.vehicleCharacter == nil then
		return nil
	else
		return v256_.vehicleCharacter:getPlayerStyle()
	end
end

-- Local values: spec, tempStyle, preset
function Enterable:setVehicleCharacter(playerStyle)
	local v259_ = self.spec_enterable
	self:deleteVehicleCharacter()
	if v259_.vehicleCharacter ~= nil then
		if v259_.customPlayerStylePresetName ~= nil then
			local v260_ = PlayerStyle.new()
			v260_:copyConfigurationFrom(playerStyle)
			v260_:copySelectionFrom(playerStyle)
			local v261_ = v260_:getPresetByName(v259_.customPlayerStylePresetName)
			if v261_ == nil then
				Logging.warning("CustomPlayerStylePresetName \'%s\' not defined for player", v259_.customPlayerStylePresetName)
			else
				v261_:applyToStyle(v260_)
				if v260_:isValid() then
					playerStyle = v260_
				end
			end
		end
		v259_.vehicleCharacter:loadCharacter(playerStyle, self, self.vehicleCharacterLoaded)
	end
end

-- Local values: spec
function Enterable:vehicleCharacterLoaded(loadingState, arguments)
	local v264_ = self.spec_enterable
	if loadingState == HumanModelLoadingState.OK then
		v264_.vehicleCharacter:updateVisibility()
		v264_.vehicleCharacter:updateIKChains()
	end
	SpecializationUtil.raiseEvent(self, "onVehicleCharacterChanged", v264_.vehicleCharacter)
	g_messageCenter:subscribe(MessageType.PLAYER_STYLE_CHANGED, self.onPlayerStyleChanged, self)
end

-- Local values: connection, currentUserId
function Enterable:onPlayerStyleChanged(style, userId)
	if self.isServer then
		local v268_ = self:getOwnerConnection()
		if v268_ ~= nil and g_currentMission.userManager:getUserIdByConnection(v268_) == userId then
			self:setVehicleCharacter(style)
			g_server:broadcastEvent(VehiclePlayerStyleChangedEvent.new(self, style))
		end
	end
end

-- Local values: spec, playerStyle
function Enterable:setRandomVehicleCharacter(helper)
	if self.spec_enterable.vehicleCharacter ~= nil then
		local v271_
		if helper == nil then
			v271_ = g_helperManager:getRandomHelperStyle()
		else
			v271_ = helper.playerStyle
		end
		self:setVehicleCharacter(v271_)
	end
end

-- Local values: spec
function Enterable:restoreVehicleCharacter()
	if self.spec_enterable.vehicleCharacter ~= nil then
		if self:getIsControlled() then
			self:setVehicleCharacter(self:getUserPlayerStyle())
			return
		end
		self:deleteVehicleCharacter()
	end
end

-- Local values: spec
function Enterable:deleteVehicleCharacter()
	local v274_ = self.spec_enterable
	SpecializationUtil.raiseEvent(self, "onVehicleCharacterChanged", nil)
	if v274_.vehicleCharacter ~= nil then
		v274_.vehicleCharacter:unloadCharacter()
	end
	g_messageCenter:unsubscribe(MessageType.PLAYER_STYLE_CHANGED, self)
end

-- Local values: minutes, hours, minutesString
function Enterable:getFormattedOperatingTime()
	local v276_ = self.operatingTime / 60000
	local v277_ = v276_ / 60
	local v278_ = math.floor(v277_)
	local v279_ = (v276_ - v278_ * 60) / 6
	local v280_ = math.floor(v279_)
	local v281_ = v278_ .. "." .. string.format("%02d", v280_ * 10)
	return tonumber(v281_)
end

-- Local values: spec
function Enterable:getIsActive(superFunc)
	local v284_ = self.spec_enterable
	return (v284_.isEntered or v284_.isControlled) and true or superFunc(self)
end

-- Local values: noOtherEnterableIsEntered, vehicles, _, vehicle
function Enterable:getIsActiveForInput(superFunc, ignoreSelection, activeForAI)
	if not superFunc(self, ignoreSelection, activeForAI) then
		return false
	end
	if g_currentMission.isPlayerFrozen then
		return false
	end
	if not self:getIsEnteredForInput() then
		local v289_ = self.rootVehicle:getChildVehicles()
		local v290_ = true
		for _, v291_ in ipairs(v289_) do
			if v291_.getIsEnteredForInput ~= nil and (v291_ ~= self and v291_:getIsEnteredForInput()) then
				v290_ = false
			end
		end
		if v290_ then
			return false
		end
	end
	return true
end

-- Local values: spec, superDistance, px, py, pz, vx, vy, vz, distance
function Enterable:getDistanceToNode(superFunc, node)
	local v295_ = self.spec_enterable
	local v296_ = superFunc(self, node)
	if v295_ == nil or v295_.enterReferenceNode == nil then
		return v296_
	end
	if not self:getIsControlled() then
		local v297_, v298_, v299_ = getWorldTranslation(node)
		local v300_, v301_, v302_ = getWorldTranslation(v295_.enterReferenceNode)
		local v303_ = MathUtil.vector3Length(v297_ - v300_, v298_ - v301_, v299_ - v302_)
		if v303_ < v295_.interactionRadius and v303_ < v296_ then
			self.interactionFlag = Vehicle.INTERACTION_FLAG_ENTERABLE
			return v303_
		end
	end
	return v296_
end

function Enterable:getInteractionHelp(superFunc)
	if self.interactionFlag == Vehicle.INTERACTION_FLAG_ENTERABLE then
		return self.spec_enterable.enterText
	else
		return superFunc(self)
	end
end

function Enterable:interact(superFunc, player)
	if self.interactionFlag == Vehicle.INTERACTION_FLAG_ENTERABLE then
		player:requestToEnterVehicle(self)
	else
		superFunc(self)
	end
end

function Enterable:getIsInteractive(superFunc)
	if self:getIsControlled() then
		return false
	else
		return superFunc(self)
	end
end

-- Local values: spec, numVisibleMirrors, _, mirror, dirX, dirY, dirZ, length, maxNumMirrors, _, mirror, _, mirror
function Enterable:setMirrorVisible(visible)
	local v313_ = self.spec_enterable
	if v313_.mirrors == nil or next(v313_.mirrors) == nil then
		return
	elseif visible then
		local v314_ = 0
		for _, v315_ in pairs(v313_.mirrors) do
			if v313_.activeCamera == nil or not (getEffectiveVisibility(v315_.parentNode) and getIsInCameraFrustum(v315_.node, v313_.activeCamera.cameraNode, g_presentedScreenAspectRatio)) then
				v315_.cosAngle = math.huge
			else
				local v316_, v317_, v318_ = localToLocal(v315_.node, v313_.activeCamera.cameraNode, 0, 0, 0)
				local v319_ = v317_ * g_screenAspectRatio
				local v320_ = MathUtil.vector3Length(v316_, v319_, v318_)
				v315_.cosAngle = -v318_ / v320_
			end
		end
		table.sort(v313_.mirrors, function(p321_, p322_)
			if p321_.prio == p322_.prio then
				return p321_.cosAngle > p322_.cosAngle
			else
				return p321_.prio < p322_.prio
			end
		end)
		local v323_ = g_gameSettings:getValue(GameSettings.SETTING.MAX_NUM_MIRRORS)
		for _, v324_ in ipairs(v313_.mirrors) do
			if getEffectiveVisibility(v324_.parentNode) then
				if v324_.cosAngle == math.huge or v314_ >= v323_ then
					setVisibility(v324_.node, false)
				else
					setVisibility(v324_.node, true)
					v314_ = v314_ + 1
				end
			end
		end
	else
		for _, v325_ in pairs(v313_.mirrors) do
			setVisibility(v325_.node, false)
		end
	end
end

function Enterable:getIsTabbable()
	return self.spec_enterable.isTabbable
end

function Enterable:setIsTabbable(isTabbable)
	if isTabbable == nil then
		isTabbable = false
	end
	self.spec_enterable.isTabbable = isTabbable
end

-- Local values: spec
function Enterable:getIsEnterable()
	local v330_ = self.spec_enterable
	local v331_ = v330_.enterReferenceNode ~= nil and v330_.exitPoint ~= nil and not (v330_.isBroken or v330_.isControlled)
	if v331_ then
		v331_ = g_currentMission.accessHandler:canPlayerAccess(self)
	end
	return v331_
end

function Enterable:getIsEnterableFromMenu()
	local v333_ = self:getIsEnterable()
	if v333_ then
		v333_ = self.spec_enterable.canBeEnteredFromMenu
	end
	return v333_
end

function Enterable:getIsEntered()
	return self.spec_enterable.isEntered
end

function Enterable:getIsControlled()
	return self.spec_enterable.isControlled
end

-- Local values: spec
function Enterable:getIsEnteredForInput()
	local v337_ = self.spec_enterable
	local v338_ = v337_.isEntered
	if v338_ then
		v338_ = v337_.isControlled
	end
	return v338_
end

-- Local values: user
function Enterable:getControllerName()
	local v340_
	if self.isServer then
		v340_ = g_currentMission.userManager:getUserByConnection(self:getOwnerConnection())
	else
		v340_ = g_currentMission.userManager:getUserByUserId(self.spec_enterable.controllerUserId)
	end
	return v340_ == nil and "" or v340_:getNickname()
end

function Enterable:getActiveCamera()
	return self.spec_enterable.activeCamera
end

function Enterable:getVehicleCharacter()
	return self.spec_enterable.vehicleCharacter
end

function Enterable:getAllowCharacterVisibilityUpdate()
	return true
end

function Enterable:getDisableVehicleCharacterOnLeave()
	return self.spec_enterable.disableCharacterOnLeave
end

function Enterable:getCanToggleSelectable(superFunc)
	return self:getIsEntered() and true or superFunc(self)
end

function Enterable:getCanToggleAttach(superFunc)
	if self:getIsEntered() then
		return superFunc(self)
	else
		return false
	end
end

-- Local values: spec, farmId
function Enterable:getActiveFarm(superFunc)
	local v350_ = self.spec_enterable.controllerFarmId
	if v350_ == 0 then
		return superFunc(self)
	else
		return v350_
	end
end

function Enterable:loadDashboardGroupFromXML(superFunc, xmlFile, key, group)
	if not superFunc(self, xmlFile, key, group) then
		return false
	end
	group.isEntered = xmlFile:getValue(key .. "#isEntered")
	return true
end

function Enterable:getIsDashboardGroupActive(superFunc, group)
	if group.isEntered == nil or group.isEntered == self:getIsEntered() then
		return superFunc(self, group)
	else
		return false
	end
end

-- Local values: spec
function Enterable:mountDynamic(superFunc, object, objectActorId, jointNode, mountType, forceAcceleration)
	if self.spec_enterable.isControlled then
		return false
	else
		return superFunc(self, object, objectActorId, jointNode, mountType, forceAcceleration)
	end
end

-- Local values: spec
function Enterable:getIsInUse(superFunc, connection)
	return self.spec_enterable.isControlled and self:getOwnerConnection() ~= connection and true or superFunc(self, connection)
end

function Enterable:loadExtraDependentParts(superFunc, xmlFile, baseName, entry)
	if not superFunc(self, xmlFile, baseName, entry) then
		return false
	end
	entry.updateCharacterTargetModifier = xmlFile:getValue(baseName .. "#updateCharacterTargetModifier", false)
	return true
end

function Enterable:updateExtraDependentParts(superFunc, part, dt)
	superFunc(self, part, dt)
	if part.updateCharacterTargetModifier then
		self:setCharacterTargetNodeStateDirty(part.node, false)
	end
end

-- Local values: spec
function Enterable:onPreRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	self:clearActionEventsTable(self.spec_enterable.actionEvents)
end

-- Local values: spec, _, actionEventId
function Enterable:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self:getIsEntered() then
		local v380_ = self.spec_enterable
		if g_touchHandler ~= nil then
			g_touchHandler:removeGestureListener(self.touchListenerDoubleTab)
		end
		if self:getIsActiveForInput(true, true) then
			g_localPlayer.inputComponent:registerGlobalPlayerActionEvents(Vehicle.INPUT_CONTEXT_NAME)
			local _, v381_ = self:addActionEvent(v380_.actionEvents, InputAction.ENTER, self, Enterable.actionEventLeave, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v381_, GS_PRIO_VERY_HIGH)
			g_inputBinding:setActionEventTextVisibility(v381_, false)
			if v380_.numCameras > 1 then
				local _, v382_ = self:addActionEvent(v380_.actionEvents, InputAction.CAMERA_SWITCH, self, Enterable.actionEventCameraSwitch, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(v382_, GS_PRIO_LOW)
				g_inputBinding:setActionEventTextVisibility(v382_, true)
			end
			local _, v383_ = self:addActionEvent(v380_.actionEvents, InputAction.CAMERA_ZOOM_IN_OUT, self, Enterable.actionEventCameraZoomInOut, false, true, true, true, nil)
			g_inputBinding:setActionEventTextPriority(v383_, GS_PRIO_LOW)
			g_inputBinding:setActionEventTextVisibility(v383_, false)
			local _, v384_ = self:addActionEvent(v380_.actionEvents, InputAction.RESET_HEAD_TRACKING, self, Enterable.actionEventResetHeadTracking, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v384_, GS_PRIO_VERY_LOW)
			g_inputBinding:setActionEventTextVisibility(v384_, false)
			if g_touchHandler ~= nil then
				self.touchListenerDoubleTab = g_touchHandler:registerGestureListener(TouchHandler.GESTURE_DOUBLE_TAP, Enterable.actionEventCameraSwitch, self)
			end
			g_inputBinding:endActionEventsModification()
			g_currentMission.activatableObjectsSystem:activate(Vehicle.INPUT_CONTEXT_NAME)
			g_inputBinding:beginActionEventsModification(Vehicle.INPUT_CONTEXT_NAME)
		end
	end
end

-- Local values: spec
function Enterable:onSetBroken()
	if self.spec_enterable.isEntered then
		g_localPlayer:leaveVehicle()
	end
end

function Enterable:actionEventLeave(actionName, inputValue, callbackState, isAnalog)
	self:doLeaveVehicle()
end

-- Local values: spec
function Enterable:actionEventCameraSwitch(actionName, inputValue, callbackState, isAnalog)
	if not g_gui:getIsGuiVisible() and self:getIsEntered() then
		self:setActiveCameraIndex(self.spec_enterable.camIndex + 1)
	end
end

-- Local values: spec, offset
function Enterable:actionEventCameraZoomInOut(actionName, inputValue, callbackState, isAnalog, isMouse, deviceCategory, binding)
	local v391_ = self.spec_enterable
	local v392_ = -0.2
	if isMouse then
		v392_ = v392_ * InputBinding.MOUSE_WHEEL_INPUT_FACTOR
	end
	local v393_ = v392_ * g_gameSettings:getValue(GameSettings.SETTING.CAMERA_ZOOM_SENSITIVITY)
	v391_.activeCamera:zoomSmoothly(v393_ * inputValue)
end

function Enterable:actionEventResetHeadTracking(actionName, inputValue, callbackState, isAnalog)
	centerHeadTracking()
end
