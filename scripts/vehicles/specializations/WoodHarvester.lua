source("dataS/scripts/vehicles/specializations/events/WoodHarvesterCutLengthEvent.lua")
source("dataS/scripts/vehicles/specializations/events/WoodHarvesterCutTreeEvent.lua")
source("dataS/scripts/vehicles/specializations/events/WoodHarvesterDropTreeEvent.lua")
source("dataS/scripts/vehicles/specializations/events/WoodHarvesterHeaderTiltEvent.lua")
source("dataS/scripts/vehicles/specializations/events/WoodHarvesterOnCutTreeEvent.lua")
source("dataS/scripts/vehicles/specializations/events/WoodHarvesterOnDelimbTreeEvent.lua")
WoodHarvester = {}
WoodHarvester.NUM_BITS_CUT_LENGTH = 5
WoodHarvester.HEADER_JOINT_TILT_XML_KEY = "vehicle.woodHarvester.headerJointTilt"

function WoodHarvester.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
end
function WoodHarvester.initSpecialization()
	g_storeManager:addSpecType("woodHarvesterMaxTreeSize", "shopListAttributeIconMaxTreeSize", WoodHarvester.loadSpecValueMaxTreeSize, WoodHarvester.getSpecValueMaxTreeSize, StoreSpecies.VEHICLE)
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("WoodHarvester")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.woodHarvester.cutNode#node", "Cut node")
	v2_:register(XMLValueType.FLOAT, "vehicle.woodHarvester.cutNode#maxRadius", "Max. radius", 1)
	v2_:register(XMLValueType.FLOAT, "vehicle.woodHarvester.cutNode#sizeY", "Size Y", 1)
	v2_:register(XMLValueType.FLOAT, "vehicle.woodHarvester.cutNode#sizeZ", "Size Z", 1)
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.woodHarvester.cutNode#attachNode", "Attach node")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.woodHarvester.cutNode#attachReferenceNode", "Attach reference node")
	v2_:register(XMLValueType.FLOAT, "vehicle.woodHarvester.cutNode#attachMoveSpeed", "Attach move speed", 3)
	v2_:register(XMLValueType.INT, "vehicle.woodHarvester.cutNode#releasedComponentJointIndex", "Released component joint")
	v2_:register(XMLValueType.ANGLE, "vehicle.woodHarvester.cutNode#releasedComponentJointRotLimitXSpeed", "Released component joint rot limit X speed", 100)
	v2_:register(XMLValueType.INT, "vehicle.woodHarvester.cutNode#releasedComponentJoint2Index", "Released component joint 2")
	v2_:register(XMLValueType.STRING, WoodHarvester.HEADER_JOINT_TILT_XML_KEY .. "#animationName", "Header tilt animation")
	v2_:register(XMLValueType.FLOAT, WoodHarvester.HEADER_JOINT_TILT_XML_KEY .. "#speedFactor", "Speed of header tilt animation", 1)
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.woodHarvester.delimbNode#node", "Delimb node")
	v2_:register(XMLValueType.FLOAT, "vehicle.woodHarvester.delimbNode#sizeX", "Delimb size X", 0.1)
	v2_:register(XMLValueType.FLOAT, "vehicle.woodHarvester.delimbNode#sizeY", "Delimb size Y", 1)
	v2_:register(XMLValueType.FLOAT, "vehicle.woodHarvester.delimbNode#sizeZ", "Delimb size Z", 1)
	v2_:register(XMLValueType.BOOL, "vehicle.woodHarvester.delimbNode#delimbOnCut", "Delimb on cut", false)
	v2_:register(XMLValueType.FLOAT, "vehicle.woodHarvester.cutLengths#min", "Min. cut length", 1)
	v2_:register(XMLValueType.FLOAT, "vehicle.woodHarvester.cutLengths#max", "Max. cut length", 5)
	v2_:register(XMLValueType.FLOAT, "vehicle.woodHarvester.cutLengths#step", "Cut length steps", 0.5)
	v2_:register(XMLValueType.VECTOR_N, "vehicle.woodHarvester.cutLengths#values", "Multiple lengths that are available separated by blank space")
	v2_:register(XMLValueType.INT, "vehicle.woodHarvester.cutLengths#startIndex", "Default selected cut length index", 1)
	EffectManager.registerEffectXMLPaths(v2_, "vehicle.woodHarvester.cutEffects")
	EffectManager.registerEffectXMLPaths(v2_, "vehicle.woodHarvester.delimbEffects")
	AnimationManager.registerAnimationNodesXMLPaths(v2_, "vehicle.woodHarvester.forwardingNodes")
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.woodHarvester.sounds", "cut")
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.woodHarvester.sounds", "delimb")
	v2_:register(XMLValueType.STRING, "vehicle.woodHarvester.cutAnimation#name", "Cut animation name")
	v2_:register(XMLValueType.FLOAT, "vehicle.woodHarvester.cutAnimation#speedScale", "Cut animation speed scale")
	v2_:register(XMLValueType.FLOAT, "vehicle.woodHarvester.cutAnimation#cutTime", "Cut animation cut time")
	v2_:register(XMLValueType.STRING, "vehicle.woodHarvester.grabAnimation#name", "Grab animation name")
	v2_:register(XMLValueType.FLOAT, "vehicle.woodHarvester.grabAnimation#speedScale", "Grab animation speed scale")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.woodHarvester.treeSizeMeasure#node", "Tree size measure node")
	v2_:register(XMLValueType.FLOAT, "vehicle.woodHarvester.treeSizeMeasure#rotMaxRadius", "Max. tree size as reference for grab animation", 1)
	v2_:register(XMLValueType.FLOAT, "vehicle.woodHarvester.treeSizeMeasure#rotMaxAnimTime", "Grab animation time which reflects the rotMaxRadius (0-1)", 1)
	Dashboard.registerDashboardXMLPaths(v2_, "vehicle.woodHarvester.dashboards", { "cutLength", "curCutLength", "diameter" })
	v2_:setXMLSpecializationType()
	local v3_ = Vehicle.xmlSchemaSavegame
	v3_:register(XMLValueType.INT, "vehicles.vehicle(?).woodHarvester#currentCutLengthIndex", "Current cut length selection index", 1)
	v3_:register(XMLValueType.BOOL, "vehicles.vehicle(?).woodHarvester#isTurnedOn", "Harvester is turned on", false)
	v3_:register(XMLValueType.VECTOR_4, "vehicles.vehicle(?).woodHarvester#lastTreeSize", "Last dimensions of tree to cutNode")
	v3_:register(XMLValueType.INT, "vehicles.vehicle(?).woodHarvester#lastCutAttachDirection", "Last tree attach direction")
	v3_:register(XMLValueType.VECTOR_3, "vehicles.vehicle(?).woodHarvester#lastTreeJointPos", "Last tree joint position in local space of splitShape")
	v3_:register(XMLValueType.BOOL, "vehicles.vehicle(?).woodHarvester#hasAttachedSplitShape", "Has split shape attached", false)
end

function WoodHarvester.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onCutTree")
end

function WoodHarvester.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "woodHarvesterSplitShapeCallback", WoodHarvester.woodHarvesterSplitShapeCallback)
	SpecializationUtil.registerFunction(vehicleType, "setLastTreeDiameter", WoodHarvester.setLastTreeDiameter)
	SpecializationUtil.registerFunction(vehicleType, "findSplitShapesInRange", WoodHarvester.findSplitShapesInRange)
	SpecializationUtil.registerFunction(vehicleType, "cutTree", WoodHarvester.cutTree)
	SpecializationUtil.registerFunction(vehicleType, "onDelimbTree", WoodHarvester.onDelimbTree)
	SpecializationUtil.registerFunction(vehicleType, "getCanSplitShapeBeAccessed", WoodHarvester.getCanSplitShapeBeAccessed)
	SpecializationUtil.registerFunction(vehicleType, "loadWoodHarvesterHeaderTiltFromXML", WoodHarvester.loadWoodHarvesterHeaderTiltFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsWoodHarvesterTiltStateAllowed", WoodHarvester.getIsWoodHarvesterTiltStateAllowed)
	SpecializationUtil.registerFunction(vehicleType, "setWoodHarvesterTiltState", WoodHarvester.setWoodHarvesterTiltState)
	SpecializationUtil.registerFunction(vehicleType, "setWoodHarvesterCutLengthIndex", WoodHarvester.setWoodHarvesterCutLengthIndex)
	SpecializationUtil.registerFunction(vehicleType, "dropWoodHarvesterTree", WoodHarvester.dropWoodHarvesterTree)
end

function WoodHarvester.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", WoodHarvester.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoConsumePtoPower", WoodHarvester.getDoConsumePtoPower)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConsumingLoad", WoodHarvester.getConsumingLoad)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", WoodHarvester.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSupportsAutoTreeAlignment", WoodHarvester.getSupportsAutoTreeAlignment)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAutoTreeAlignmentAllowed", WoodHarvester.getIsAutoTreeAlignmentAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAutoAlignHasValidTree", WoodHarvester.getAutoAlignHasValidTree)
end

function WoodHarvester.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", WoodHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", WoodHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", WoodHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", WoodHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", WoodHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", WoodHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", WoodHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", WoodHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", WoodHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", WoodHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", WoodHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", WoodHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", WoodHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", WoodHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", WoodHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", WoodHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", WoodHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onCutTree", WoodHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onVehicleSettingChanged", WoodHarvester)
end

-- Local values: spec, cutReleasedComponentJointIndex, cutReleasedComponentJoint2Index, i, i
function WoodHarvester:onLoad(savegame)
	local v9_ = self.spec_woodHarvester
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.woodHarvester.delimbSound", "vehicle.woodHarvester.sounds.delimb")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.woodHarvester.cutSound", "vehicle.woodHarvester.sounds.cut")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.woodHarvester.treeSizeMeasure#index", "vehicle.woodHarvester.treeSizeMeasure#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.woodHarvester.forwardingWheels.wheel(0)", "vehicle.woodHarvester.forwardingNodes.animationNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.woodHarvester.cutParticleSystems", "vehicle.woodHarvester.cutEffects")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.woodHarvester.delimbParticleSystems", "vehicle.woodHarvester.delimbEffects")
	v9_.curSplitShape = nil
	v9_.attachedSplitShape = nil
	v9_.hasAttachedSplitShape = false
	v9_.isAttachedSplitShapeMoving = false
	v9_.attachedSplitShapeLastDelimbTime = 0
	v9_.attachedSplitShapeX = 0
	v9_.attachedSplitShapeY = 0
	v9_.attachedSplitShapeZ = 0
	v9_.attachedSplitShapeTargetY = 0
	v9_.attachedSplitShapeLastCutY = 0
	v9_.attachedSplitShapeStartY = 0
	v9_.attachedSplitShapeOnlyMove = false
	v9_.attachedSplitShapeOnlyMoveDelay = 0
	v9_.attachedSplitShapeMoveEffectActive = false
	v9_.attachedSplitShapeDelimbEffectActive = false
	v9_.cutTimer = -1
	v9_.lastCutEventTime = 0
	v9_.cutEventCoolDownTime = 1000
	v9_.automaticCuttingEnabled = true
	v9_.automaticCuttingIsDirty = false
	v9_.lastTreeSize = nil
	v9_.lastTreeJointPos = nil
	v9_.loadedSplitShapeFromSavegame = false
	v9_.cutNode = self.xmlFile:getValue("vehicle.woodHarvester.cutNode#node", nil, self.components, self.i3dMappings)
	v9_.cutMaxRadius = self.xmlFile:getValue("vehicle.woodHarvester.cutNode#maxRadius", 1)
	v9_.cutSizeY = self.xmlFile:getValue("vehicle.woodHarvester.cutNode#sizeY", 1)
	v9_.cutSizeZ = self.xmlFile:getValue("vehicle.woodHarvester.cutNode#sizeZ", 1)
	v9_.cutAttachNode = self.xmlFile:getValue("vehicle.woodHarvester.cutNode#attachNode", nil, self.components, self.i3dMappings)
	v9_.cutAttachReferenceNode = self.xmlFile:getValue("vehicle.woodHarvester.cutNode#attachReferenceNode", nil, self.components, self.i3dMappings)
	v9_.cutAttachMoveSpeed = self.xmlFile:getValue("vehicle.woodHarvester.cutNode#attachMoveSpeed", 3) * 0.001
	local v10_ = self.xmlFile:getValue("vehicle.woodHarvester.cutNode#releasedComponentJointIndex")
	if v10_ ~= nil then
		v9_.cutReleasedComponentJoint = self.componentJoints[v10_]
		v9_.cutReleasedComponentJointRotLimitX = 0
		v9_.cutReleasedComponentJointRotLimitXSpeed = self.xmlFile:getValue("vehicle.woodHarvester.cutNode#releasedComponentJointRotLimitXSpeed", 100) * 0.001
	end
	local v11_ = self.xmlFile:getValue("vehicle.woodHarvester.cutNode#releasedComponentJoint2Index")
	if v11_ ~= nil then
		v9_.cutReleasedComponentJoint2 = self.componentJoints[v11_]
		v9_.cutReleasedComponentJoint2RotLimitX = 0
		v9_.cutReleasedComponentJoint2RotLimitXSpeed = self.xmlFile:getValue("vehicle.woodHarvester.cutNode#releasedComponentJointRotLimitXSpeed", 100) * 0.001
	end
	v9_.headerJointTilt = {}
	if not self:loadWoodHarvesterHeaderTiltFromXML(v9_.headerJointTilt, self.xmlFile, "vehicle.woodHarvester.headerJointTilt") then
		v9_.headerJointTilt = nil
	end
	if v9_.cutAttachReferenceNode ~= nil and v9_.cutAttachNode ~= nil then
		v9_.cutAttachHelperNode = createTransformGroup("helper")
		link(v9_.cutAttachReferenceNode, v9_.cutAttachHelperNode)
		setTranslation(v9_.cutAttachHelperNode, 0, 0, 0)
		setRotation(v9_.cutAttachHelperNode, 0, 0, 0)
	end
	v9_.cutAttachDirection = 1
	v9_.lastCutAttachDirection = 1
	v9_.delimbNode = self.xmlFile:getValue("vehicle.woodHarvester.delimbNode#node", nil, self.components, self.i3dMappings)
	v9_.delimbSizeX = self.xmlFile:getValue("vehicle.woodHarvester.delimbNode#sizeX", 0.1)
	v9_.delimbSizeY = self.xmlFile:getValue("vehicle.woodHarvester.delimbNode#sizeY", 1)
	v9_.delimbSizeZ = self.xmlFile:getValue("vehicle.woodHarvester.delimbNode#sizeZ", 1)
	v9_.delimbOnCut = self.xmlFile:getValue("vehicle.woodHarvester.delimbNode#delimbOnCut", false)
	v9_.cutLengthMin = self.xmlFile:getValue("vehicle.woodHarvester.cutLengths#min", 1)
	v9_.cutLengthMax = self.xmlFile:getValue("vehicle.woodHarvester.cutLengths#max", 5)
	v9_.cutLengthStep = self.xmlFile:getValue("vehicle.woodHarvester.cutLengths#step", 0.5)
	v9_.cutLengths = self.xmlFile:getValue("vehicle.woodHarvester.cutLengths#values", nil, true)
	if v9_.cutLengths == nil or #v9_.cutLengths == 0 then
		v9_.cutLengths = {}
		for v12_ = v9_.cutLengthMin, v9_.cutLengthMax, v9_.cutLengthStep do
			local v13_ = v9_.cutLengths
			table.insert(v13_, v12_)
		end
	else
		for v14_ = 1, #v9_.cutLengths do
			if v9_.cutLengths[v14_] == 0 then
				v9_.cutLengths[v14_] = math.huge
			end
		end
	end
	local v15_ = self.xmlFile:getValue("vehicle.woodHarvester.cutLengths#startIndex", 1)
	local v16_ = #v9_.cutLengths
	v9_.currentCutLengthIndex = math.clamp(v15_, 1, v16_)
	v9_.currentCutLength = v9_.cutLengths[v9_.currentCutLengthIndex] or 1
	if self.isClient then
		v9_.cutEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.woodHarvester.cutEffects", self.components, self, self.i3dMappings)
		v9_.delimbEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.woodHarvester.delimbEffects", self.components, self, self.i3dMappings)
		v9_.forwardingNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.woodHarvester.forwardingNodes", self.components, self, self.i3dMappings)
		v9_.samples = {}
		v9_.samples.cut = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.woodHarvester.sounds", "cut", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v9_.samples.delimb = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.woodHarvester.sounds", "delimb", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v9_.isCutSamplePlaying = false
		v9_.isDelimbSamplePlaying = false
	end
	v9_.cutAnimation = {}
	v9_.cutAnimation.name = self.xmlFile:getValue("vehicle.woodHarvester.cutAnimation#name")
	v9_.cutAnimation.speedScale = self.xmlFile:getValue("vehicle.woodHarvester.cutAnimation#speedScale", 1)
	v9_.cutAnimation.cutTime = self.xmlFile:getValue("vehicle.woodHarvester.cutAnimation#cutTime", 1)
	v9_.grabAnimation = {}
	v9_.grabAnimation.name = self.xmlFile:getValue("vehicle.woodHarvester.grabAnimation#name")
	v9_.grabAnimation.speedScale = self.xmlFile:getValue("vehicle.woodHarvester.grabAnimation#speedScale", 1)
	v9_.treeSizeMeasure = {}
	v9_.treeSizeMeasure.node = self.xmlFile:getValue("vehicle.woodHarvester.treeSizeMeasure#node", nil, self.components, self.i3dMappings)
	v9_.treeSizeMeasure.rotMaxRadius = self.xmlFile:getValue("vehicle.woodHarvester.treeSizeMeasure#rotMaxRadius", 1)
	v9_.treeSizeMeasure.rotMaxAnimTime = self.xmlFile:getValue("vehicle.woodHarvester.treeSizeMeasure#rotMaxAnimTime", 1)
	v9_.warnInvalidTree = false
	v9_.warnInvalidTreeRadius = false
	v9_.warnInvalidTreePosition = false
	v9_.warnTreeNotOwned = false
	v9_.lastDiameter = 0
	v9_.texts = {}
	v9_.texts.actionChangeCutLength = g_i18n:getText("action_woodHarvesterChangeCutLength")
	v9_.texts.woodHarvesterTiltHeader = g_i18n:getText("action_woodHarvesterTiltHeader")
	v9_.texts.uiMax = g_i18n:getText("ui_max")
	v9_.texts.unitMeterShort = g_i18n:getText("unit_mShort")
	v9_.texts.actionCut = g_i18n:getText("action_woodHarvesterCut")
	v9_.texts.warningFoldingTreeMounted = g_i18n:getText("warning_foldingTreeMounted")
	v9_.texts.warningTreeTooThick = g_i18n:getText("warning_treeTooThick")
	v9_.texts.warningTreeTooThickAtPosition = g_i18n:getText("warning_treeTooThickAtPosition")
	v9_.texts.warningTreeTypeNotSupported = g_i18n:getText("warning_treeTypeNotSupported")
	v9_.texts.warningYouDontHaveAccessToThisLand = g_i18n:getText("warning_youAreNotAllowedToCutThisTree")
	v9_.texts.warningFirstTurnOnTheTool = string.format(g_i18n:getText("warning_firstTurnOnTheTool"), self.typeDesc)
	self:registerVehicleSetting(GameSettings.SETTING.WOOD_HARVESTER_AUTO_CUT, true)
end

-- Local values: spec, speedScale, stopTime
function WoodHarvester:onPostLoad(savegame)
	local v18_ = self.spec_woodHarvester
	if v18_.grabAnimation.name ~= nil then
		local v19_ = -v18_.grabAnimation.speedScale
		local v20_ = v18_.grabAnimation.speedScale < 0 and 1 or 0
		self:playAnimation(v18_.grabAnimation.name, v19_, nil, true)
		self:setAnimationStopTime(v18_.grabAnimation.name, v20_)
		AnimatedVehicle.updateAnimationByName(self, v18_.grabAnimation.name, 99999999, true)
	end
end

-- Local values: spec, cutLengthIndex, lastTreeSize, lastTreeJointPos
function WoodHarvester:onLoadFinished(savegame)
	local v23_ = self.spec_woodHarvester
	if savegame ~= nil and not savegame.resetVehicles then
		self:setWoodHarvesterCutLengthIndex(savegame.xmlFile:getValue(savegame.key .. ".woodHarvester#currentCutLengthIndex", v23_.currentCutLengthIndex), true)
		if savegame.xmlFile:getValue(savegame.key .. ".woodHarvester#isTurnedOn", false) then
			self:setIsTurnedOn(true)
		end
		if v23_.grabAnimation.name ~= nil then
			AnimatedVehicle.updateAnimationByName(self, v23_.grabAnimation.name, 99999999, true)
		end
		local v24_ = savegame.xmlFile:getValue(savegame.key .. ".woodHarvester#lastTreeSize", nil, true)
		if v24_ ~= nil then
			v23_.lastTreeSize = v24_
		end
		local v25_ = savegame.xmlFile:getValue(savegame.key .. ".woodHarvester#lastTreeJointPos", nil, true)
		if v25_ ~= nil then
			v23_.lastTreeJointPos = v25_
		end
		v23_.lastCutAttachDirection = savegame.xmlFile:getValue(savegame.key .. ".woodHarvester#lastCutAttachDirection", v23_.lastCutAttachDirection)
		if savegame.xmlFile:getValue(savegame.key .. ".woodHarvester#hasAttachedSplitShape", false) and self:getIsTurnedOn() then
			self:findSplitShapesInRange(0.5, true)
			if v23_.curSplitShape ~= nil and v23_.curSplitShape ~= 0 then
				v23_.loadedSplitShapeFromSavegame = true
			end
		end
	end
end

-- Local values: spec, cutLength, curCutLength, diameter
function WoodHarvester:onRegisterDashboardValueTypes()
	local v_u_27_ = self.spec_woodHarvester
	local v28_ = DashboardValueType.new("woodHarvester", "cutLength")
	v28_:setValue(v_u_27_, function()
		-- upvalues: (copy) v_u_27_
		return v_u_27_.currentCutLength == math.huge and 9999999 or v_u_27_.currentCutLength * 100
	end)
	self:registerDashboardValueType(v28_)
	local v29_ = DashboardValueType.new("woodHarvester", "curCutLength")
	v29_:setValue(v_u_27_, function()
		-- upvalues: (copy) v_u_27_
		local v30_ = v_u_27_.attachedSplitShapeStartY - v_u_27_.attachedSplitShapeY
		return math.abs(v30_) * 100
	end)
	self:registerDashboardValueType(v29_)
	local v31_ = DashboardValueType.new("woodHarvester", "diameter")
	v31_:setValue(v_u_27_, function()
		-- upvalues: (copy) v_u_27_
		return v_u_27_.lastDiameter * 1000
	end)
	self:registerDashboardValueType(v31_)
end

-- Local values: spec
function WoodHarvester:onDelete()
	local v33_ = self.spec_woodHarvester
	if v33_.attachedSplitShapeJointIndex ~= nil then
		removeJoint(v33_.attachedSplitShapeJointIndex)
		v33_.attachedSplitShapeJointIndex = nil
	end
	if v33_.cutAttachHelperNode ~= nil then
		delete(v33_.cutAttachHelperNode)
	end
	g_effectManager:deleteEffects(v33_.cutEffects)
	g_effectManager:deleteEffects(v33_.delimbEffects)
	g_soundManager:deleteSamples(v33_.samples)
	g_animationManager:deleteAnimations(v33_.forwardingNodes)
end

-- Local values: spec
function WoodHarvester:saveToXMLFile(xmlFile, key, usedModNames)
	local v37_ = self.spec_woodHarvester
	xmlFile:setValue(key .. "#currentCutLengthIndex", v37_.currentCutLengthIndex)
	xmlFile:setValue(key .. "#isTurnedOn", self:getIsTurnedOn() or v37_.hasAttachedSplitShape)
	xmlFile:setValue(key .. "#hasAttachedSplitShape", v37_.hasAttachedSplitShape)
	xmlFile:setValue(key .. "#lastCutAttachDirection", v37_.lastCutAttachDirection)
	if v37_.hasAttachedSplitShape then
		if v37_.lastTreeSize ~= nil then
			local v38_ = key .. "#lastTreeSize"
			local v39_ = v37_.lastTreeSize
			xmlFile:setValue(v38_, unpack(v39_))
		end
		if v37_.lastTreeJointPos ~= nil then
			local v40_ = key .. "#lastTreeJointPos"
			local v41_ = v37_.lastTreeJointPos
			xmlFile:setValue(v40_, unpack(v41_))
		end
	end
end

-- Local values: spec, animTime, cutLengthIndex
function WoodHarvester:onReadStream(streamId, connection)
	local v44_ = self.spec_woodHarvester
	v44_.hasAttachedSplitShape = streamReadBool(streamId)
	if v44_.hasAttachedSplitShape then
		local v45_ = streamReadUIntN(streamId, 7) / 127
		self:setAnimationTime(v44_.grabAnimation.name, v45_, true)
		self:setAnimationTime(v44_.cutAnimation.name, 1, true)
	end
	v44_.isAttachedSplitShapeMoving = streamReadBool(streamId)
	self:setWoodHarvesterCutLengthIndex(streamReadUIntN(streamId, WoodHarvester.NUM_BITS_CUT_LENGTH), true)
end

-- Local values: spec, animTime
function WoodHarvester:onWriteStream(streamId, connection)
	local v48_ = self.spec_woodHarvester
	if streamWriteBool(streamId, v48_.hasAttachedSplitShape) then
		local v49_ = self:getAnimationTime(v48_.grabAnimation.name)
		streamWriteUIntN(streamId, v49_ * 127, 7)
	end
	streamWriteBool(streamId, v48_.isAttachedSplitShapeMoving)
	streamWriteUIntN(streamId, v48_.currentCutLengthIndex, WoodHarvester.NUM_BITS_CUT_LENGTH)
end

-- Local values: spec
function WoodHarvester:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local v53_ = self.spec_woodHarvester
		v53_.attachedSplitShapeMoveEffectActive = streamReadBool(streamId)
		if v53_.attachedSplitShapeMoveEffectActive then
			v53_.attachedSplitShapeDelimbEffectActive = streamReadBool(streamId)
			return
		end
		v53_.attachedSplitShapeDelimbEffectActive = false
	end
end

-- Local values: spec
function WoodHarvester:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v57_ = self.spec_woodHarvester
		if streamWriteBool(streamId, v57_.attachedSplitShapeMoveEffectActive) then
			streamWriteBool(streamId, v57_.attachedSplitShapeDelimbEffectActive)
		end
	end
end

-- Local values: spec, lostShape, readyToCut, x, y, z, nx, ny, nz, yx, yy, yz, newTreeCut, currentSplitShape, splitTypeName, splitType, xD, yD, zD, nxD, nyD, nzD, yxD, yyD, yzD, vx, vy, vz, sizeX, doTreeCut, minY, maxY, minZ, maxZ, delimbOffset, lengthBelow, _, xD, yD, zD, nxD, nyD, nzD, yxD, yyD, yzD, vx, vy, vz, sizeX, total, _, farm, x, y, z, nx, ny, nz, yx, yy, yz, didDelimb, updateSplitShapeJoint, updateJointSavePosition, x, y, z, nx, ny, nz, _, lengthRem, dir, limit, dir, limit, x, y, z, nx, ny, nz, yx, yy, yz, shape, minY, maxY, minZ, maxZ, treeCenterX, treeCenterY, treeCenterZ, _
function WoodHarvester:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v60_ = self.spec_woodHarvester
	if self.isServer then
		local v61_ = false
		if v60_.attachedSplitShape == nil then
			if v60_.curSplitShape ~= nil and not entityExists(v60_.curSplitShape) then
				v60_.curSplitShape = nil
				v61_ = true
			end
		elseif not entityExists(v60_.attachedSplitShape) then
			v60_.attachedSplitShape = nil
			v60_.attachedSplitShapeJointIndex = nil
			v60_.isAttachedSplitShapeMoving = false
			v60_.attachedSplitShapeMoveEffectActive = false
			v60_.attachedSplitShapeDelimbEffectActive = false
			v60_.cutTimer = -1
			v61_ = true
		end
		if v61_ then
			SpecializationUtil.raiseEvent(self, "onCutTree", 0, false, false)
			if g_server ~= nil then
				g_server:broadcastEvent(WoodHarvesterOnCutTreeEvent.new(self, 0), nil, nil, self)
			end
		end
	end
	if self.isServer and (v60_.attachedSplitShape ~= nil or v60_.curSplitShape ~= nil) then
		if v60_.cutTimer > 0 then
			if v60_.cutAnimation.name == nil then
				local v62_ = v60_.cutTimer - dt
				v60_.cutTimer = math.max(v62_, 0)
			elseif self:getAnimationTime(v60_.cutAnimation.name) > v60_.cutAnimation.cutTime then
				v60_.cutTimer = 0
			end
		end
		if v60_.cutTimer == 0 then
			v60_.cutTimer = -1
			local v63_, v64_, v65_ = getWorldTranslation(v60_.cutNode)
			local v66_, v67_, v68_ = localDirectionToWorld(v60_.cutNode, 1, 0, 0)
			local v69_, v70_, v71_ = localDirectionToWorld(v60_.cutNode, 0, 1, 0)
			local v72_ = false
			local v73_
			if v60_.attachedSplitShapeJointIndex == nil then
				v73_ = v60_.curSplitShape
				v60_.curSplitShape = nil
				v72_ = true
			else
				removeJoint(v60_.attachedSplitShapeJointIndex)
				v60_.attachedSplitShapeJointIndex = nil
				v73_ = v60_.attachedSplitShape
				v60_.attachedSplitShape = nil
			end
			local v74_ = g_splitShapeManager:getSplitTypeByIndex(getSplitType(v73_))
			local v75_ = v74_ == nil and "" or v74_.name
			if v60_.delimbOnCut then
				local v76_, v77_, v78_ = getWorldTranslation(v60_.delimbNode)
				local v79_, v80_, v81_ = localDirectionToWorld(v60_.delimbNode, 1, 0, 0)
				local v82_, v83_, v84_ = localDirectionToWorld(v60_.delimbNode, 0, 1, 0)
				local v85_ = v63_ - v76_
				local v86_ = v64_ - v77_
				local v87_ = v65_ - v78_
				local v88_ = MathUtil.vector3Length(v85_, v86_, v87_)
				removeSplitShapeAttachments(v73_, v76_ + v85_ * 0.5, v77_ + v86_ * 0.5, v78_ + v87_ * 0.5, v79_, v80_, v81_, v82_, v83_, v84_, v88_ * 0.7 + v60_.delimbSizeX, v60_.delimbSizeY, v60_.delimbSizeZ)
			end
			v60_.attachedSplitShape = nil
			v60_.curSplitShape = nil
			v60_.prevSplitShape = v73_
			local v89_ = not v60_.loadedSplitShapeFromSavegame
			if getRigidBodyType(v73_) ~= RigidBodyType.STATIC and v72_ then
				v89_ = false
			end
			if v89_ then
				g_currentMission:removeKnownSplitShape(v73_)
				self.shapeBeingCut = v73_
				self.shapeBeingCutIsTree = getRigidBodyType(v73_) == RigidBodyType.STATIC
				self.shapeBeingCutIsNew = v72_
				splitShape(v73_, v63_, v64_, v65_, v66_, v67_, v68_, v69_, v70_, v71_, v60_.cutSizeY, v60_.cutSizeZ, "woodHarvesterSplitShapeCallback", self)
				g_treePlantManager:removingSplitShape(v73_)
			else
				local v90_ = 0
				local v91_, v92_, v93_, v94_
				if v60_.lastTreeSize == nil or not v60_.loadedSplitShapeFromSavegame then
					v91_, v92_, v93_, v94_ = testSplitShape(v73_, v63_, v64_, v65_, v66_, v67_, v68_, v69_, v70_, v71_, v60_.cutSizeY, v60_.cutSizeZ)
					if v91_ ~= nil then
						local v95_, _ = getSplitShapePlaneExtents(v73_, v63_, v64_, v65_, v66_, v67_, v68_)
						if v95_ ~= nil and v95_ > 0.01 then
							v90_ = -v95_
						end
					end
				else
					v91_ = v60_.lastTreeSize[1]
					v92_ = v60_.lastTreeSize[2]
					v93_ = v60_.lastTreeSize[3]
					v94_ = v60_.lastTreeSize[4]
				end
				if v91_ ~= nil then
					self:woodHarvesterSplitShapeCallback(v73_, false, true, v91_, v92_, v93_, v94_)
					g_messageCenter:publish(MessageType.TREE_SHAPE_MOUNTED, v73_, self)
					if v90_ ~= 0 then
						v60_.attachedSplitShapeTargetY = v60_.attachedSplitShapeLastCutY + v90_ * v60_.cutAttachDirection
						v60_.attachedSplitShapeOnlyMove = true
						v60_.attachedSplitShapeOnlyMoveDelay = 750
						self:onDelimbTree(true)
					end
				end
			end
			if v60_.attachedSplitShape == nil then
				SpecializationUtil.raiseEvent(self, "onCutTree", 0, false, false)
				if g_server ~= nil then
					g_server:broadcastEvent(WoodHarvesterOnCutTreeEvent.new(self, 0), nil, nil, self)
				end
			elseif v60_.delimbOnCut then
				local v96_, v97_, v98_ = getWorldTranslation(v60_.delimbNode)
				local v99_, v100_, v101_ = localDirectionToWorld(v60_.delimbNode, 1, 0, 0)
				local v102_, v103_, v104_ = localDirectionToWorld(v60_.delimbNode, 0, 1, 0)
				local v105_ = v63_ - v96_
				local v106_ = v64_ - v97_
				local v107_ = v65_ - v98_
				local v108_ = MathUtil.vector3Length(v105_, v106_, v107_)
				removeSplitShapeAttachments(v60_.attachedSplitShape, v96_ + v105_ * 3, v97_ + v106_ * 3, v98_ + v107_ * 3, v99_, v100_, v101_, v102_, v103_, v104_, v108_ * 3 + v60_.delimbSizeX, v60_.delimbSizeY, v60_.delimbSizeZ)
			end
			if v89_ and v72_ then
				local v109_, _ = g_farmManager:updateFarmStats(self:getActiveFarm(), "cutTreeCount", 1)
				if v109_ ~= nil then
					g_achievementManager:tryUnlock("CutTreeFirst", v109_)
					g_achievementManager:tryUnlock("CutTree", v109_)
				end
				if v75_ ~= "" then
					local v110_ = g_farmManager:getFarmById(self:getActiveFarm())
					if v110_ ~= nil then
						v110_.stats:updateTreeTypesCut(v75_)
					end
				end
			end
		end
		v60_.attachedSplitShapeMoveEffectActive = false
		v60_.attachedSplitShapeDelimbEffectActive = false
		if v60_.attachedSplitShape ~= nil and v60_.isAttachedSplitShapeMoving then
			if v60_.delimbNode ~= nil then
				local v111_, v112_, v113_ = getWorldTranslation(v60_.delimbNode)
				local v114_, v115_, v116_ = localDirectionToWorld(v60_.delimbNode, 1, 0, 0)
				local v117_, v118_, v119_ = localDirectionToWorld(v60_.delimbNode, 0, 1, 0)
				if removeSplitShapeAttachments(v60_.attachedSplitShape, v111_, v112_, v113_, v114_, v115_, v116_, v117_, v118_, v119_, v60_.delimbSizeX, v60_.delimbSizeY, v60_.delimbSizeZ) then
					v60_.attachedSplitShapeLastDelimbTime = g_time
				end
				if g_time - v60_.attachedSplitShapeLastDelimbTime < 500 then
					v60_.attachedSplitShapeDelimbEffectActive = true
				end
			end
			local v120_ = false
			local v121_ = false
			if v60_.attachedSplitShapeOnlyMove then
				if v60_.attachedSplitShapeOnlyMoveDelay <= 0 then
					local v122_ = v60_.attachedSplitShapeTargetY > v60_.attachedSplitShapeY and 1 or -1
					v60_.attachedSplitShapeY = (v60_.attachedSplitShapeTargetY > v60_.attachedSplitShapeY and math.min or math.max)(v60_.attachedSplitShapeY + v60_.cutAttachMoveSpeed * dt * v122_, v60_.attachedSplitShapeTargetY)
					if v60_.attachedSplitShapeY == v60_.attachedSplitShapeTargetY then
						v60_.isAttachedSplitShapeMoving = false
						v60_.attachedSplitShapeOnlyMove = false
						v60_.attachedSplitShapeLastCutY = v60_.attachedSplitShapeY
						v120_ = true
						v121_ = true
					else
						v120_ = true
						v121_ = true
					end
				else
					v60_.attachedSplitShapeOnlyMoveDelay = v60_.attachedSplitShapeOnlyMoveDelay - dt
				end
			elseif v60_.cutNode ~= nil and v60_.attachedSplitShapeJointIndex ~= nil then
				local v123_, v124_, v125_ = getWorldTranslation(v60_.cutAttachReferenceNode)
				local v126_, v127_, v128_ = localDirectionToWorld(v60_.cutAttachReferenceNode, 0, 1, 0)
				local _, v129_ = getSplitShapePlaneExtents(v60_.attachedSplitShape, v123_, v124_, v125_, v126_, v127_, v128_)
				if v129_ == nil or v129_ <= 0.1 then
					removeJoint(v60_.attachedSplitShapeJointIndex)
					v60_.attachedSplitShapeJointIndex = nil
					v60_.attachedSplitShape = nil
					self:onDelimbTree(false)
					if g_server ~= nil then
						g_server:broadcastEvent(WoodHarvesterOnDelimbTreeEvent.new(self, false), nil, nil, self)
					end
					SpecializationUtil.raiseEvent(self, "onCutTree", 0, false, false)
					if g_server ~= nil then
						g_server:broadcastEvent(WoodHarvesterOnCutTreeEvent.new(self, 0), nil, nil, self)
					end
				else
					local v130_ = v60_.attachedSplitShapeTargetY > v60_.attachedSplitShapeY and 1 or -1
					v60_.attachedSplitShapeY = (v60_.attachedSplitShapeTargetY > v60_.attachedSplitShapeY and math.min or math.max)(v60_.attachedSplitShapeY + v60_.cutAttachMoveSpeed * dt * v130_, v60_.attachedSplitShapeTargetY)
					if v60_.attachedSplitShapeY == v60_.attachedSplitShapeTargetY then
						self:onDelimbTree(false)
						if g_server == nil then
							v120_ = true
						else
							g_server:broadcastEvent(WoodHarvesterOnDelimbTreeEvent.new(self, false), nil, nil, self)
							v120_ = true
						end
					else
						v120_ = true
					end
				end
			end
			if v120_ and v60_.attachedSplitShapeJointIndex ~= nil then
				local v131_, v132_, v133_ = localToWorld(v60_.cutNode, 0.3, 0, 0)
				local v134_, v135_, v136_ = localDirectionToWorld(v60_.cutNode, 1, 0, 0)
				local v137_, v138_, v139_ = localDirectionToWorld(v60_.cutNode, 0, 1, 0)
				local v140_, v141_, v142_, v143_, v144_ = findSplitShape(v131_, v132_, v133_, v134_, v135_, v136_, v137_, v138_, v139_, v60_.cutSizeY, v60_.cutSizeZ)
				if v140_ == v60_.attachedSplitShape then
					local v145_, v146_, v147_ = localToWorld(v60_.cutNode, 0, (v141_ + v142_) * 0.5, (v143_ + v144_) * 0.5)
					local v148_, _, v149_ = worldToLocal(v60_.attachedSplitShape, v145_, v146_, v147_)
					v60_.attachedSplitShapeX = v148_
					v60_.attachedSplitShapeZ = v149_
					self:setLastTreeDiameter((v142_ - v141_ + v144_ - v143_) * 0.5)
				end
				local v150_, v151_, v152_ = localToWorld(v60_.attachedSplitShape, v60_.attachedSplitShapeX, v60_.attachedSplitShapeY, v60_.attachedSplitShapeZ)
				setJointPosition(v60_.attachedSplitShapeJointIndex, 1, v150_, v151_, v152_)
				if v121_ then
					v60_.lastTreeJointPos[1] = v60_.attachedSplitShapeX
					v60_.lastTreeJointPos[2] = v60_.attachedSplitShapeY
					v60_.lastTreeJointPos[3] = v60_.attachedSplitShapeZ
				end
			end
			v60_.attachedSplitShapeMoveEffectActive = v120_
		end
	end
	if self.isClient then
		if v60_.cutAnimation.name ~= nil then
			if self:getIsAnimationPlaying(v60_.cutAnimation.name) and self:getAnimationTime(v60_.cutAnimation.name) < v60_.cutAnimation.cutTime then
				if not v60_.isCutSamplePlaying then
					g_soundManager:playSample(v60_.samples.cut)
					v60_.isCutSamplePlaying = true
				end
				g_effectManager:setEffectTypeInfo(v60_.cutEffects, FillType.WOODCHIPS)
				g_effectManager:startEffects(v60_.cutEffects)
			else
				if v60_.isCutSamplePlaying then
					g_soundManager:stopSample(v60_.samples.cut)
					v60_.isCutSamplePlaying = false
				end
				g_effectManager:stopEffects(v60_.cutEffects)
			end
		end
		if v60_.attachedSplitShapeMoveEffectActive then
			if not v60_.isDelimbSamplePlaying then
				g_soundManager:playSample(v60_.samples.delimb)
				v60_.isDelimbSamplePlaying = true
			end
			g_effectManager:setEffectTypeInfo(v60_.delimbEffects, FillType.WOODCHIPS)
			g_effectManager:startEffects(v60_.delimbEffects)
			g_effectManager:setDensity(v60_.delimbEffects, v60_.attachedSplitShapeDelimbEffectActive and 1 or 0.1)
			g_animationManager:startAnimations(v60_.forwardingNodes)
			return
		end
		if v60_.isDelimbSamplePlaying then
			g_soundManager:stopSample(v60_.samples.delimb)
			v60_.isDelimbSamplePlaying = false
		end
		g_effectManager:stopEffects(v60_.delimbEffects)
		g_animationManager:stopAnimations(v60_.forwardingNodes)
	end
end

-- Local values: spec, x, y, z, nx, ny, nz, yx, yy, yz, minY, maxY, minZ, maxZ, cutTooLow, _, actionEvent, showAction, dropActionEvent, lengthStr
function WoodHarvester:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v155_ = self.spec_woodHarvester
	v155_.warnInvalidTree = false
	v155_.warnInvalidTreeRadius = false
	v155_.warnInvalidTreePosition = false
	v155_.warnTreeNotOwned = false
	if self:getIsTurnedOn() and (v155_.attachedSplitShape == nil and v155_.cutNode ~= nil) then
		local v156_, v157_, v158_ = getWorldTranslation(v155_.cutNode)
		local v159_, v160_, v161_ = localDirectionToWorld(v155_.cutNode, 1, 0, 0)
		local v162_, v163_, v164_ = localDirectionToWorld(v155_.cutNode, 0, 1, 0)
		self:findSplitShapesInRange()
		if v155_.curSplitShape ~= nil then
			if entityExists(v155_.curSplitShape) then
				local v165_, v166_, v167_, v168_ = testSplitShape(v155_.curSplitShape, v156_, v157_, v158_, v159_, v160_, v161_, v162_, v163_, v164_, v155_.cutSizeY, v155_.cutSizeZ)
				if v165_ == nil then
					v155_.curSplitShape = nil
				else
					local _, v169_, _ = localToLocal(v155_.cutNode, v155_.curSplitShape, 0, v165_, v167_)
					local v170_ = v169_ < 0.01
					local _, v171_, _ = localToLocal(v155_.cutNode, v155_.curSplitShape, 0, v165_, v168_)
					local v172_ = v170_ or v171_ < 0.01
					local _, v173_, _ = localToLocal(v155_.cutNode, v155_.curSplitShape, 0, v166_, v167_)
					local v174_ = v172_ or v173_ < 0.01
					local _, v175_, _ = localToLocal(v155_.cutNode, v155_.curSplitShape, 0, v166_, v168_)
					if v174_ or v175_ < 0.01 then
						v155_.curSplitShape = nil
					end
				end
			else
				v155_.curSplitShape = nil
			end
		end
		if v155_.curSplitShape == nil and v155_.cutTimer > -1 then
			SpecializationUtil.raiseEvent(self, "onCutTree", 0, false, false)
			if g_server ~= nil then
				g_server:broadcastEvent(WoodHarvesterOnCutTreeEvent.new(self, 0), nil, nil, self)
			end
		end
	end
	if self.isServer and v155_.attachedSplitShape == nil then
		if v155_.cutReleasedComponentJoint ~= nil and v155_.cutReleasedComponentJointRotLimitX ~= 0 then
			local v176_ = v155_.cutReleasedComponentJointRotLimitX - v155_.cutReleasedComponentJointRotLimitXSpeed * dt
			v155_.cutReleasedComponentJointRotLimitX = math.max(0, v176_)
			setJointRotationLimit(v155_.cutReleasedComponentJoint.jointIndex, 0, true, 0, v155_.cutReleasedComponentJointRotLimitX)
		end
		if v155_.cutReleasedComponentJoint2 ~= nil and v155_.cutReleasedComponentJoint2RotLimitX ~= 0 then
			local v177_ = v155_.cutReleasedComponentJoint2RotLimitX - v155_.cutReleasedComponentJoint2RotLimitXSpeed * dt
			v155_.cutReleasedComponentJoint2RotLimitX = math.max(v177_, 0)
			setJointRotationLimit(v155_.cutReleasedComponentJoint2.jointIndex, 0, true, -v155_.cutReleasedComponentJoint2RotLimitX, v155_.cutReleasedComponentJoint2RotLimitX)
		end
	end
	if self.isServer and (self.playDelayedGrabAnimationTime ~= nil and self.playDelayedGrabAnimationTime < g_currentMission.time) then
		self.playDelayedGrabAnimationTime = nil
		if self:getAnimationTime(v155_.grabAnimation.name) > 0 and (v155_.grabAnimation.name ~= nil and v155_.attachedSplitShape == nil) then
			if v155_.grabAnimation.speedScale > 0 then
				self:setAnimationStopTime(v155_.grabAnimation.name, 0)
			else
				self:setAnimationStopTime(v155_.grabAnimation.name, 1)
			end
			self:playAnimation(v155_.grabAnimation.name, -v155_.grabAnimation.speedScale, self:getAnimationTime(v155_.grabAnimation.name), false)
		end
	end
	if self.isClient then
		local v178_ = v155_.actionEvents[InputAction.IMPLEMENT_EXTRA2]
		if v178_ ~= nil then
			local v179_ = false
			local v180_
			if v155_.hasAttachedSplitShape then
				v180_ = not v155_.isAttachedSplitShapeMoving and self:getAnimationTime(v155_.cutAnimation.name) == 1 and true or v179_
			else
				v180_ = v155_.curSplitShape ~= nil and true or v179_
			end
			g_inputBinding:setActionEventActive(v178_.actionEventId, v180_)
			local v181_ = v155_.actionEvents[InputAction.WOOD_HARVESTER_DROP]
			if v181_ ~= nil then
				g_inputBinding:setActionEventActive(v181_.actionEventId, v180_)
			end
		end
		local v182_ = v155_.actionEvents[InputAction.IMPLEMENT_EXTRA3]
		if v182_ ~= nil then
			g_inputBinding:setActionEventActive(v182_.actionEventId, not v155_.isAttachedSplitShapeMoving)
			if not v155_.isAttachedSplitShapeMoving then
				local v183_ = string.format("%.1f%s", v155_.currentCutLength, v155_.texts.unitMeterShort)
				if v155_.currentCutLength == math.huge then
					v183_ = v155_.texts.uiMax
				end
				g_inputBinding:setActionEventText(v182_.actionEventId, string.format(v155_.texts.actionChangeCutLength, v183_))
			end
		end
	end
end

-- Local values: spec
function WoodHarvester:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v187_ = self.spec_woodHarvester
	if isActiveForInputIgnoreSelection and (isSelected and (self:getIsTurnedOn() and v187_.cutNode ~= nil)) then
		if v187_.warnInvalidTreeRadius then
			g_currentMission:showBlinkingWarning(v187_.texts.warningTreeTooThick, 100)
			return
		end
		if v187_.warnInvalidTreePosition then
			g_currentMission:showBlinkingWarning(v187_.texts.warningTreeTooThickAtPosition, 100)
			return
		end
		if v187_.warnInvalidTree then
			g_currentMission:showBlinkingWarning(v187_.texts.warningTreeTypeNotSupported, 100)
			return
		end
		if v187_.warnTreeNotOwned then
			g_currentMission:showBlinkingWarning(v187_.texts.warningYouDontHaveAccessToThisLand, 100)
		end
	end
end

-- Local values: spec, _, actionEventId
function WoodHarvester:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v190_ = self.spec_woodHarvester
		self:clearActionEventsTable(v190_.actionEvents)
		if isActiveForInputIgnoreSelection then
			local _, v191_ = self:addPoweredActionEvent(v190_.actionEvents, InputAction.IMPLEMENT_EXTRA2, self, WoodHarvester.actionEventCutTree, false, true, true, true, nil)
			g_inputBinding:setActionEventTextPriority(v191_, GS_PRIO_HIGH)
			g_inputBinding:setActionEventText(v191_, v190_.texts.actionCut)
			local _, v192_ = self:addActionEvent(v190_.actionEvents, InputAction.IMPLEMENT_EXTRA3, self, WoodHarvester.actionEventSetCutlength, false, true, false, true, 1)
			g_inputBinding:setActionEventTextPriority(v192_, GS_PRIO_HIGH)
			local _, v193_ = self:addActionEvent(v190_.actionEvents, InputAction.TOGGLE_CUT_LENGTH_BACK, self, WoodHarvester.actionEventSetCutlength, false, true, false, true, -1)
			g_inputBinding:setActionEventTextVisibility(v193_, false)
			local _, v194_ = self:addActionEvent(v190_.actionEvents, InputAction.WOOD_HARVESTER_DROP, self, WoodHarvester.actionEventDropTree, false, true, false, true, nil)
			g_inputBinding:setActionEventTextVisibility(v194_, true)
			g_inputBinding:setActionEventTextPriority(v194_, GS_PRIO_NORMAL)
			if v190_.headerJointTilt ~= nil then
				local _, v195_ = self:addActionEvent(v190_.actionEvents, InputAction.TOGGLE_WOOD_HARVESTER_TILT, self, WoodHarvester.actionEventTiltHeader, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(v195_, GS_PRIO_HIGH)
				g_inputBinding:setActionEventText(v195_, v190_.texts.woodHarvesterTiltHeader)
			end
		end
	end
end

-- Local values: spec
function WoodHarvester:onDeactivate()
	self.spec_woodHarvester.curSplitShape = nil
	self:setLastTreeDiameter(0)
end

-- Local values: spec
function WoodHarvester:onTurnedOn()
	local v198_ = self.spec_woodHarvester
	self.playDelayedGrabAnimationTime = nil
	if v198_.grabAnimation.name ~= nil and v198_.attachedSplitShape == nil then
		if v198_.grabAnimation.speedScale > 0 then
			self:setAnimationStopTime(v198_.grabAnimation.name, 1)
		else
			self:setAnimationStopTime(v198_.grabAnimation.name, 0)
		end
		self:playAnimation(v198_.grabAnimation.name, v198_.grabAnimation.speedScale, self:getAnimationTime(v198_.grabAnimation.name), true)
	end
	self:setLastTreeDiameter(0)
end

-- Local values: spec
function WoodHarvester:onTurnedOff()
	local v200_ = self.spec_woodHarvester
	if v200_.grabAnimation.name ~= nil and v200_.attachedSplitShape == nil then
		self.playDelayedGrabAnimationTime = g_currentMission.time + 500
		if v200_.grabAnimation.speedScale > 0 then
			self:setAnimationStopTime(v200_.grabAnimation.name, 1)
		else
			self:setAnimationStopTime(v200_.grabAnimation.name, 0)
		end
		self:playAnimation(v200_.grabAnimation.name, v200_.grabAnimation.speedScale, self:getAnimationTime(v200_.grabAnimation.name), true)
	end
	if self.isClient then
		g_effectManager:stopEffects(v200_.delimbEffects)
		g_effectManager:stopEffects(v200_.cutEffects)
		g_soundManager:stopSamples(v200_.samples)
		v200_.isCutSamplePlaying = false
		v200_.isDelimbSamplePlaying = false
	end
end

function WoodHarvester:onStateChange(state, data)
	if self.isServer and (state == VehicleStateChange.MOTOR_TURN_ON and (self.spec_woodHarvester.attachedSplitShape ~= nil and self:getCanBeTurnedOn())) then
		self:setIsTurnedOn(true)
	end
end

function WoodHarvester:getCanSplitShapeBeAccessed(x, z, shape)
	return g_splitShapeManager:getIsShapeCutAllowed(x, z, shape, self:getActiveFarm(), self:getOwnerConnection())
end

function WoodHarvester:loadWoodHarvesterHeaderTiltFromXML(headerTilt, xmlFile, key)
	headerTilt.animationName = xmlFile:getValue(key .. "#animationName")
	if headerTilt.animationName == nil then
		return false
	end
	headerTilt.speedFactor = xmlFile:getValue(key .. "#speedFactor", 1)
	headerTilt.state = false
	headerTilt.lastState = nil
	return true
end

function WoodHarvester:getIsWoodHarvesterTiltStateAllowed(headerTilt)
	return true
end

-- Local values: spec
function WoodHarvester:setWoodHarvesterTiltState(state, noEventSend)
	local v213_ = self.spec_woodHarvester
	if state == nil then
		state = not v213_.headerJointTilt.state
	end
	if state ~= v213_.headerJointTilt.state then
		v213_.headerJointTilt.state = state
		self:playAnimation(v213_.headerJointTilt.animationName, state and 1 or -1, self:getAnimationTime(v213_.headerJointTilt.animationName), true)
	end
	WoodHarvesterHeaderTiltEvent.sendEvent(self, state, noEventSend)
end

-- Local values: spec
function WoodHarvester:setWoodHarvesterCutLengthIndex(index, noEventSend)
	local v217_ = self.spec_woodHarvester
	if index ~= v217_.currentCutLengthIndex then
		v217_.currentCutLengthIndex = index
		v217_.currentCutLength = v217_.cutLengths[v217_.currentCutLengthIndex] or 1
	end
	WoodHarvesterCutLengthEvent.sendEvent(self, index, noEventSend)
end

-- Local values: spec
function WoodHarvester:dropWoodHarvesterTree(noEventSend)
	if self.isServer then
		local v220_ = self.spec_woodHarvester
		if v220_.attachedSplitShapeJointIndex ~= nil then
			removeJoint(v220_.attachedSplitShapeJointIndex)
			v220_.attachedSplitShapeJointIndex = nil
		end
		v220_.attachedSplitShape = nil
		self:onDelimbTree(false)
		g_server:broadcastEvent(WoodHarvesterOnDelimbTreeEvent.new(self, false), nil, nil, self)
		SpecializationUtil.raiseEvent(self, "onCutTree", 0, false, false)
		g_server:broadcastEvent(WoodHarvesterOnCutTreeEvent.new(self, 0), nil, nil, self)
	end
	WoodHarvesterDropTreeEvent.sendEvent(self, noEventSend)
end

-- Local values: spec, x, y, z, nx, ny, nz, yx, yy, yz, shape, minY, maxY, minZ, maxZ, treeDx, treeDy, treeDz, cosTreeAngle, angleLimit, angle, radius
function WoodHarvester:findSplitShapesInRange(yOffset, skipCutAnimation)
	local v224_ = self.spec_woodHarvester
	if v224_.attachedSplitShape == nil and v224_.cutNode ~= nil then
		local v225_, v226_, v227_ = localToWorld(v224_.cutNode, yOffset or 0, 0, 0)
		local v228_, v229_, v230_ = localDirectionToWorld(v224_.cutNode, 1, 0, 0)
		local v231_, v232_, v233_ = localDirectionToWorld(v224_.cutNode, 0, 1, 0)
		if v224_.curSplitShape == nil and (v224_.cutReleasedComponentJoint == nil or v224_.cutReleasedComponentJointRotLimitX == 0) then
			local v234_, v235_, v236_, v237_, v238_ = findSplitShape(v225_, v226_, v227_, v228_, v229_, v230_, v231_, v232_, v233_, v224_.cutSizeY, v224_.cutSizeZ)
			if v234_ ~= 0 then
				if not g_splitShapeManager:getSplitShapeAllowsHarvester(v234_) then
					v224_.warnInvalidTree = true
					return
				end
				if self:getCanSplitShapeBeAccessed(v225_, v227_, v234_) then
					local v239_, v240_, v241_ = localDirectionToWorld(v234_, 0, 1, 0)
					local v242_ = MathUtil.dotProduct(v228_, v229_, v230_, v239_, v240_, v241_)
					local v243_ = getRigidBodyType(v234_) == RigidBodyType.STATIC and 0.2617 or 0.6981
					local v244_ = math.acos(v242_) - 1.57079
					local v245_ = 1.57079 - math.abs(v244_)
					if v245_ <= v243_ then
						local v246_ = v236_ - v235_
						local v247_ = v238_ - v237_
						if math.max(v246_, v247_) * 0.5 * v242_ > v224_.cutMaxRadius then
							v224_.warnInvalidTreeRadius = true
							local v248_, v249_, v250_ = localToWorld(v224_.cutNode, yOffset or 1, 0, 0)
							local v251_, v252_, v253_, v254_, v255_ = findSplitShape(v248_, v249_, v250_, v228_, v229_, v230_, v231_, v232_, v233_, v224_.cutSizeY, v224_.cutSizeZ)
							if v251_ ~= 0 then
								local v256_ = v253_ - v252_
								local v257_ = v255_ - v254_
								if math.max(v256_, v257_) * 0.5 * math.cos(v245_) <= v224_.cutMaxRadius then
									v224_.warnInvalidTreeRadius = false
									v224_.warnInvalidTreePosition = true
									return
								end
							end
						else
							local v258_ = v236_ - v235_
							local v259_ = v238_ - v237_
							self:setLastTreeDiameter((math.max(v258_, v259_)))
							v224_.curSplitShape = v234_
							if skipCutAnimation then
								self:setAnimationTime(v224_.cutAnimation.name, 1, true)
								v224_.cutTimer = 0
								return
							end
						end
					end
				else
					v224_.warnTreeNotOwned = true
				end
			end
		end
	end
end

-- Local values: spec
function WoodHarvester:cutTree(length, noEventSend)
	local v263_ = self.spec_woodHarvester
	WoodHarvesterCutTreeEvent.sendEvent(self, length, noEventSend)
	if self.isServer then
		if length == 0 then
			if v263_.attachedSplitShape ~= nil or v263_.curSplitShape ~= nil then
				if v263_.attachedSplitShape == nil and (v263_.curSplitShape ~= nil and getRigidBodyType(v263_.curSplitShape) ~= RigidBodyType.STATIC) then
					v263_.cutTimer = 0
					if v263_.cutAnimation.name ~= nil then
						self:setAnimationTime(v263_.cutAnimation.name, 0, true)
						self:playAnimation(v263_.cutAnimation.name, 999999, self:getAnimationTime(v263_.cutAnimation.name))
					end
				else
					v263_.cutTimer = 100
					if v263_.cutAnimation.name ~= nil then
						self:setAnimationTime(v263_.cutAnimation.name, 0, true)
						self:playAnimation(v263_.cutAnimation.name, v263_.cutAnimation.speedScale, self:getAnimationTime(v263_.cutAnimation.name))
					end
				end
			end
		elseif length > 0 and v263_.attachedSplitShape ~= nil then
			v263_.attachedSplitShapeTargetY = v263_.attachedSplitShapeLastCutY + length * v263_.cutAttachDirection
			self:onDelimbTree(true)
			if g_server ~= nil then
				g_server:broadcastEvent(WoodHarvesterOnDelimbTreeEvent.new(self, true), nil, nil, self)
			end
		end
	end
	v263_.automaticCuttingIsDirty = false
end

-- Local values: spec, targetAnimTime
function WoodHarvester:onCutTree(radius, isNewTree, loadedFromSavegame)
	local v267_ = self.spec_woodHarvester
	if radius > 0 then
		if self.isClient then
			if v267_.grabAnimation.name ~= nil then
				local v268_ = radius / v267_.treeSizeMeasure.rotMaxRadius
				local v269_ = math.min(v268_, 1) * v267_.treeSizeMeasure.rotMaxAnimTime
				if v267_.grabAnimation.speedScale < 0 then
					v269_ = 1 - v269_
				end
				self:setAnimationStopTime(v267_.grabAnimation.name, v269_)
				if self:getAnimationTime(v267_.grabAnimation.name) < v269_ then
					self:playAnimation(v267_.grabAnimation.name, v267_.grabAnimation.speedScale, self:getAnimationTime(v267_.grabAnimation.name), true)
				else
					self:playAnimation(v267_.grabAnimation.name, -v267_.grabAnimation.speedScale, self:getAnimationTime(v267_.grabAnimation.name), true)
				end
			end
			self:setLastTreeDiameter(2 * radius)
		end
		v267_.hasAttachedSplitShape = true
	else
		if v267_.grabAnimation.name ~= nil then
			if v267_.grabAnimation.speedScale > 0 then
				self:setAnimationStopTime(v267_.grabAnimation.name, 1)
			else
				self:setAnimationStopTime(v267_.grabAnimation.name, 0)
			end
			self:playAnimation(v267_.grabAnimation.name, v267_.grabAnimation.speedScale, self:getAnimationTime(v267_.grabAnimation.name), true)
		end
		v267_.hasAttachedSplitShape = false
		v267_.cutTimer = -1
		if self.isServer and (v267_.headerJointTilt ~= nil and v267_.headerJointTilt.lastState ~= nil) then
			self:setWoodHarvesterTiltState(v267_.headerJointTilt.lastState)
			v267_.headerJointTilt.lastState = nil
		end
	end
	if loadedFromSavegame and v267_.grabAnimation.name ~= nil then
		AnimatedVehicle.updateAnimationByName(self, v267_.grabAnimation.name, 99999999, true)
	end
end

function WoodHarvester:onVehicleSettingChanged(gameSettingId, state)
	if gameSettingId == GameSettings.SETTING.WOOD_HARVESTER_AUTO_CUT then
		self.spec_woodHarvester.automaticCuttingEnabled = state
	end
end

-- Local values: spec
function WoodHarvester:onDelimbTree(state)
	local v275_ = self.spec_woodHarvester
	if state then
		v275_.isAttachedSplitShapeMoving = true
		return
	else
		v275_.isAttachedSplitShapeMoving = false
		if self.isServer then
			if v275_.automaticCuttingEnabled then
				self:cutTree(0)
			else
				v275_.automaticCuttingIsDirty = true
			end
		else
			v275_.automaticCuttingIsDirty = not v275_.automaticCuttingEnabled
			return
		end
	end
end

-- Local values: spec, treeCenterX, treeCenterY, treeCenterZ, cutAttachDirection, loadedSplitShapeFromSavegame, x, y, z, dx, dy, dz, _, treeYDirection, _, upx, upy, upz, sideX, sideY, sizeZ, constr, radius
function WoodHarvester:woodHarvesterSplitShapeCallback(shape, isBelow, isAbove, minY, maxY, minZ, maxZ)
	local v284_ = self.spec_woodHarvester
	g_currentMission:addKnownSplitShape(shape)
	g_treePlantManager:addingSplitShape(shape, self.shapeBeingCut, self.shapeBeingCutIsTree)
	if v284_.attachedSplitShape == nil and (isAbove and (not isBelow and (v284_.cutAttachNode ~= nil and v284_.cutAttachReferenceNode ~= nil))) then
		v284_.attachedSplitShape = shape
		v284_.lastTreeSize = {
			minY,
			maxY,
			minZ,
			maxZ
		}
		local v285_, v286_, v287_ = localToWorld(v284_.cutNode, 0, (minY + maxY) * 0.5, (minZ + maxZ) * 0.5)
		local v288_ = nil
		local v289_ = v284_.loadedSplitShapeFromSavegame
		if v289_ then
			if v284_.lastTreeJointPos ~= nil then
				local v290_ = localToWorld
				local v291_ = v284_.lastTreeJointPos
				v285_, v286_, v287_ = v290_(shape, unpack(v291_))
				v288_ = v284_.lastCutAttachDirection
			end
			v284_.loadedSplitShapeFromSavegame = false
		end
		v284_.lastTreeJointPos = { worldToLocal(shape, v285_, v286_, v287_) }
		local v292_, v293_, v294_ = localToWorld(v284_.cutAttachReferenceNode, 0, 0, (maxZ - minZ) * 0.5)
		local v295_, v296_, v297_ = localDirectionToWorld(shape, 0, 0, 1)
		local _, v298_, _ = localDirectionToLocal(shape, v284_.cutAttachReferenceNode, 0, 1, 0)
		v284_.cutAttachDirection = v288_ or (v298_ > 0 and 1 or -1)
		v284_.lastCutAttachDirection = v284_.cutAttachDirection
		local v299_, v300_, v301_ = localDirectionToWorld(v284_.cutAttachReferenceNode, 0, v284_.cutAttachDirection, 0)
		local v302_, v303_, v304_ = MathUtil.crossProduct(v299_, v300_, v301_, v295_, v296_, v297_)
		local v305_, v306_, v307_ = MathUtil.crossProduct(v302_, v303_, v304_, v299_, v300_, v301_)
		I3DUtil.setWorldDirection(v284_.cutAttachHelperNode, v305_, v306_, v307_, v299_, v300_, v301_, 2)
		local v308_ = JointConstructor.new()
		v308_:setActors(v284_.cutAttachNode, shape)
		v308_:setJointTransforms(v284_.cutAttachHelperNode, shape)
		v308_:setJointWorldPositions(v292_, v293_, v294_, v285_, v286_, v287_)
		v308_:setRotationLimit(0, 0, 0)
		v308_:setRotationLimit(1, 0, 0)
		v308_:setRotationLimit(2, 0, 0)
		v308_:setEnableCollision(false)
		v284_.attachedSplitShapeJointIndex = v308_:finalize()
		if v284_.cutReleasedComponentJoint ~= nil then
			v284_.cutReleasedComponentJointRotLimitX = 2.827433388230814
			if v284_.cutReleasedComponentJoint.jointIndex ~= 0 then
				setJointRotationLimit(v284_.cutReleasedComponentJoint.jointIndex, 0, true, 0, v284_.cutReleasedComponentJointRotLimitX)
			end
		end
		if v284_.cutReleasedComponentJoint2 ~= nil then
			v284_.cutReleasedComponentJoint2RotLimitX = 2.827433388230814
			if v284_.cutReleasedComponentJoint2.jointIndex ~= 0 then
				setJointRotationLimit(v284_.cutReleasedComponentJoint2.jointIndex, 0, true, -v284_.cutReleasedComponentJoint2RotLimitX, v284_.cutReleasedComponentJoint2RotLimitX)
			end
		end
		if v284_.headerJointTilt ~= nil and (v284_.headerJointTilt.state and v284_.headerJointTilt.lastState == nil) then
			v284_.headerJointTilt.lastState = v284_.headerJointTilt.state
			self:setWoodHarvesterTiltState(false)
		end
		local v309_, v310_, v311_ = worldToLocal(shape, v285_, v286_, v287_)
		v284_.attachedSplitShapeX = v309_
		v284_.attachedSplitShapeY = v310_
		v284_.attachedSplitShapeZ = v311_
		v284_.attachedSplitShapeLastCutY = v284_.attachedSplitShapeY
		v284_.attachedSplitShapeStartY = v284_.attachedSplitShapeY
		v284_.attachedSplitShapeTargetY = v284_.attachedSplitShapeY
		local v312_ = (maxY - minY + (maxZ - minZ)) / 4
		SpecializationUtil.raiseEvent(self, "onCutTree", v312_, self.shapeBeingCutIsNew, v289_)
		if g_server ~= nil then
			g_server:broadcastEvent(WoodHarvesterOnCutTreeEvent.new(self, v312_), nil, nil, self)
		end
	end
end

-- Local values: spec
function WoodHarvester:setLastTreeDiameter(diameter)
	self.spec_woodHarvester.lastDiameter = diameter
end

function WoodHarvester:getCanBeSelected(superFunc)
	return true
end

function WoodHarvester:getDoConsumePtoPower(superFunc)
	return superFunc(self) or self:getIsTurnedOn()
end

-- Local values: value, count, loadPercentage, spec
function WoodHarvester:getConsumingLoad(superFunc)
	local v319_, v320_ = superFunc(self)
	local v321_ = self.spec_woodHarvester
	return v319_ + ((v321_.isAttachedSplitShapeMoving or self:getIsAnimationPlaying(v321_.cutAnimation.name)) and 1 or 0), v320_ + 1
end

-- Local values: spec
function WoodHarvester:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	local v326_ = self.spec_woodHarvester
	if v326_.hasAttachedSplitShape then
		return false, v326_.texts.warningFoldingTreeMounted
	else
		return superFunc(self, direction, onAiTurnOn)
	end
end

function WoodHarvester:getSupportsAutoTreeAlignment(superFunc)
	return true
end

-- Local values: spec
function WoodHarvester:getIsAutoTreeAlignmentAllowed(superFunc)
	if self.spec_woodHarvester.hasAttachedSplitShape then
		return false
	else
		return superFunc(self)
	end
end

-- Local values: spec
function WoodHarvester:getAutoAlignHasValidTree(superFunc, radius)
	local v331_ = self.spec_woodHarvester
	return v331_.curSplitShape ~= nil, radius <= v331_.cutMaxRadius
end

-- Local values: spec
function WoodHarvester:actionEventCutTree(actionName, inputValue, callbackState, isAnalog)
	local v333_ = self.spec_woodHarvester
	if self:getIsTurnedOn() then
		if g_time - v333_.lastCutEventTime > v333_.cutEventCoolDownTime then
			if v333_.hasAttachedSplitShape then
				if not v333_.isAttachedSplitShapeMoving and self:getAnimationTime(v333_.cutAnimation.name) == 1 then
					if v333_.automaticCuttingIsDirty then
						self:cutTree(0)
						v333_.lastCutEventTime = g_time
					else
						self:cutTree(v333_.currentCutLength)
						v333_.lastCutEventTime = g_time
					end
				end
			elseif v333_.curSplitShape ~= nil and v333_.cutTimer == -1 then
				self:cutTree(0)
				v333_.lastCutEventTime = g_time
				return
			end
		end
	else
		g_currentMission:showBlinkingWarning(v333_.texts.warningFirstTurnOnTheTool, 2000)
	end
end

-- Local values: spec, cutLengthIndex
function WoodHarvester:actionEventSetCutlength(actionName, inputValue, callbackState, isAnalog)
	local v336_ = self.spec_woodHarvester
	if not v336_.isAttachedSplitShapeMoving then
		local v337_ = v336_.currentCutLengthIndex + callbackState
		self:setWoodHarvesterCutLengthIndex(#v336_.cutLengths < v337_ and 1 or (v337_ < 1 and #v336_.cutLengths or v337_))
	end
end

function WoodHarvester:actionEventDropTree(actionName, inputValue, callbackState, isAnalog)
	self:dropWoodHarvesterTree()
end

-- Local values: spec
function WoodHarvester:actionEventTiltHeader(actionName, inputValue, callbackState, isAnalog)
	local v340_ = self.spec_woodHarvester
	if self:getIsWoodHarvesterTiltStateAllowed(v340_.headerJointTilt) and not v340_.hasAttachedSplitShape then
		self:setWoodHarvesterTiltState()
	end
end

function WoodHarvester.loadSpecValueMaxTreeSize(xmlFile, customEnvironment, baseDir)
	return xmlFile:getValue("vehicle.woodHarvester.cutNode#maxRadius")
end

-- Local values: value, str
function WoodHarvester.getSpecValueMaxTreeSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	if storeItem.specs.woodHarvesterMaxTreeSize == nil then
		return nil
	else
		local v345_ = storeItem.specs.woodHarvesterMaxTreeSize * 2 * 100
		local v346_ = string.format("%d%s", MathUtil.round(v345_), g_i18n:getText("unit_cmShort"))
		if returnValues and returnRange then
			return v345_, v345_, v346_
		elseif returnValues then
			return v345_, v346_
		else
			return v346_
		end
	end
end
