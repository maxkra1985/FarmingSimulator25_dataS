source("dataS/scripts/vehicles/specializations/events/SetDischargeStateEvent.lua")
Dischargeable = {}
Dischargeable.DISCHARGE_STATE_OFF = 0
Dischargeable.DISCHARGE_STATE_OBJECT = 1
Dischargeable.DISCHARGE_STATE_GROUND = 2
Dischargeable.SEND_NUM_BITS_DISCHARGE_STATE = 2
Dischargeable.DISCHARGE_REASON_NOT_ALLOWED_HERE = 1
Dischargeable.DISCHARGE_REASON_NO_FREE_CAPACITY = 2
Dischargeable.DISCHARGE_REASON_FILLTYPE_NOT_SUPPORTED = 3
Dischargeable.DISCHARGE_REASON_TOOLTYPE_NOT_SUPPORTED = 4
Dischargeable.DISCHARGE_REASON_NO_ACCESS = 5
Dischargeable.DISCHARGE_REASON_NO_ACCESS_LAND = 6
Dischargeable.DISCHARGE_WARNINGS = {}
Dischargeable.DISCHARGE_WARNINGS[Dischargeable.DISCHARGE_REASON_NOT_ALLOWED_HERE] = "warning_actionNotAllowedHere"
Dischargeable.DISCHARGE_WARNINGS[Dischargeable.DISCHARGE_REASON_FILLTYPE_NOT_SUPPORTED] = "warning_notAcceptedHere"
Dischargeable.DISCHARGE_WARNINGS[Dischargeable.DISCHARGE_REASON_TOOLTYPE_NOT_SUPPORTED] = "warning_notAcceptedTool"
Dischargeable.DISCHARGE_WARNINGS[Dischargeable.DISCHARGE_REASON_NO_FREE_CAPACITY] = "warning_noMoreFreeCapacity"
Dischargeable.DISCHARGE_WARNINGS[Dischargeable.DISCHARGE_REASON_NO_ACCESS] = "warning_youDontHaveAccessToThis"
Dischargeable.DISCHARGE_WARNINGS[Dischargeable.DISCHARGE_REASON_NO_ACCESS_LAND] = "warning_youDontHaveAccessToThisLand"
Dischargeable.DISCHARGE_NODE_XML_PATH = "vehicle.dischargeable.dischargeNode(?)"
Dischargeable.DISCHARGE_NODE_CONFIG_XML_PATH = "vehicle.dischargeable.dischargeableConfigurations.dischargeableConfiguration(?).dischargeNode(?)"

function Dischargeable.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(FillUnit, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(FillVolume, specializations)
	end
	return v2_
end
function Dischargeable.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("dischargeable", g_i18n:getText("configuration_dischargeable"), "dischargeable", VehicleConfigurationItem)
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("Dischargeable")
	Dischargeable.registerXMLPaths(v3_, "vehicle.dischargeable")
	Dischargeable.registerXMLPaths(v3_, "vehicle.dischargeable.dischargeableConfigurations.dischargeableConfiguration(?)")
	Dashboard.registerDashboardXMLPaths(v3_, "vehicle.dischargeable.dashboards", { "activeDischargeNode", "dischargeState" })
	v3_:register(XMLValueType.INT, "vehicle.dischargeable.dashboards.dashboard(?)#dischargeNodeIndex", "Index of discharge node")
	v3_:setXMLSpecializationType()
	Vehicle.xmlSchemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).dischargeable#isAllowed", "If is dicharge allowed", nil)
end

function Dischargeable.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. "#requiresTipOcclusionArea", "Requires tip occlusion area", true)
	schema:register(XMLValueType.BOOL, basePath .. "#consumePower", "While in discharge state, PTO power is consumed", true)
	schema:register(XMLValueType.BOOL, basePath .. "#stopDischargeOnDeactivate", "Stop discharge if the vehicle is deactivated", true)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".dischargeNode(?)#node", "Discharge node")
	schema:register(XMLValueType.INT, basePath .. ".dischargeNode(?)#fillUnitIndex", "Fill unit index")
	schema:register(XMLValueType.INT, basePath .. ".dischargeNode(?)#unloadInfoIndex", "Unload info index", 1)
	schema:register(XMLValueType.BOOL, basePath .. ".dischargeNode(?)#stopDischargeOnEmpty", "Stop discharge if fill unit empty", true)
	schema:register(XMLValueType.BOOL, basePath .. ".dischargeNode(?)#canDischargeToGround", "Can discharge to ground", true)
	schema:register(XMLValueType.BOOL, basePath .. ".dischargeNode(?)#canDischargeToObject", "Can discharge to object", true)
	schema:register(XMLValueType.BOOL, basePath .. ".dischargeNode(?)#canDischargeToVehicle", "Can discharge to other vehicles", "same as canDischargeToObject")
	schema:register(XMLValueType.BOOL, basePath .. ".dischargeNode(?)#canStartDischargeAutomatically", "Can start discharge automatically", false)
	schema:register(XMLValueType.BOOL, basePath .. ".dischargeNode(?)#canStartGroundDischargeAutomatically", "Can start discharge to ground automatically", false)
	schema:register(XMLValueType.BOOL, basePath .. ".dischargeNode(?)#stopDischargeIfNotPossible", "Stop discharge if not possible", "default \'true\' while having discharge trigger")
	schema:register(XMLValueType.BOOL, basePath .. ".dischargeNode(?)#canDischargeToGroundAnywhere", "Can discharge to ground independent of land owned state", false)
	schema:register(XMLValueType.BOOL, basePath .. ".dischargeNode(?)#canDischargeToMissionGround", "Can discharge to ground if an active mission is running on the farmland", false)
	schema:register(XMLValueType.BOOL, basePath .. ".dischargeNode(?)#canFillOwnVehicle", "Discharge node can fill other fill units of the vehicle itself", false)
	schema:register(XMLValueType.BOOL, basePath .. ".dischargeNode(?)#limitGroundTipToFillLevel", "Limit the amount that is dropped on the ground to the fill level of the tool (Otherwise it will tip the min. amount possible even if the fill level is below.)", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".dischargeNode(?)#emptySpeed", "Empty speed in l/sec", "fill unit capacity")
	schema:register(XMLValueType.TIME, basePath .. ".dischargeNode(?)#effectTurnOffThreshold", "After this time has passed and nothing has been harvested the effects are turned off", 0.25)
	schema:register(XMLValueType.STRING, basePath .. ".dischargeNode(?)#toolType", "Tool type", "dischargable")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".dischargeNode(?).info#node", "Discharge info node", "Discharge node")
	schema:register(XMLValueType.FLOAT, basePath .. ".dischargeNode(?).info#width", "Discharge info width", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".dischargeNode(?).info#length", "Discharge info length", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".dischargeNode(?).info#zOffset", "Discharge info Z axis offset", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".dischargeNode(?).info#yOffset", "Discharge info y axis offset", 2)
	schema:register(XMLValueType.BOOL, basePath .. ".dischargeNode(?).info#limitToGround", "Discharge info is limited to ground", true)
	schema:register(XMLValueType.BOOL, basePath .. ".dischargeNode(?).info#useRaycastHitPosition", "Discharge info uses raycast hit position", false)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".dischargeNode(?).raycast#node", "Raycast node", "Discharge node")
	schema:register(XMLValueType.BOOL, basePath .. ".dischargeNode(?).raycast#useWorldNegYDirection", "Use world negative Y Direction", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".dischargeNode(?).raycast#yOffset", "Y Offset", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".dischargeNode(?).raycast#maxDistance", "Max. raycast distance", 10)
	schema:register(XMLValueType.FLOAT, basePath .. ".dischargeNode(?)#maxDistance", "Max. raycast distance", 10)
	schema:register(XMLValueType.STRING, basePath .. ".dischargeNode(?).fillType#converterName", "Converter to be used to convert the fill types")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".dischargeNode(?).trigger#node", "Discharge trigger node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".dischargeNode(?).activationTrigger#node", "Discharge activation trigger node")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath .. ".dischargeNode(?).distanceObjectChanges")
	schema:register(XMLValueType.FLOAT, basePath .. ".dischargeNode(?).distanceObjectChanges#threshold", "Defines at which raycast distance the object changes", 0.5)
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath .. ".dischargeNode(?).stateObjectChanges")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath .. ".dischargeNode(?).nodeActiveObjectChanges")
	EffectManager.registerEffectXMLPaths(schema, basePath .. ".dischargeNode(?).effects")
	schema:register(XMLValueType.BOOL, basePath .. ".dischargeNode(?)#playSound", "Play discharge sound", true)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".dischargeNode(?)#soundNode", "Sound link node", "Discharge node")
	schema:register(XMLValueType.STRING, basePath .. ".dischargeNode(?).animation#name", "Name of animation to play while discharging")
	schema:register(XMLValueType.FLOAT, basePath .. ".dischargeNode(?).animation#speed", "Animation speed while discharging", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".dischargeNode(?).animation#resetSpeed", "Animation speed while discharge has been stopped", 1)
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".dischargeNode(?)", "dischargeSound")
	schema:register(XMLValueType.BOOL, basePath .. ".dischargeNode(?).dischargeSound#overwriteSharedSound", "Overwrite shared discharge sound with sound defined in discharge node", false)
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".dischargeNode(?)", "dischargeStateSound(?)")
	AnimationManager.registerAnimationNodesXMLPaths(schema, basePath .. ".dischargeNode(?).animationNodes")
	AnimationManager.registerAnimationNodesXMLPaths(schema, basePath .. ".dischargeNode(?).effectAnimationNodes")
end

function Dischargeable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadDischargeNode", Dischargeable.loadDischargeNode)
	SpecializationUtil.registerFunction(vehicleType, "setCurrentDischargeNodeIndex", Dischargeable.setCurrentDischargeNodeIndex)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentDischargeNode", Dischargeable.getCurrentDischargeNode)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentDischargeNodeIndex", Dischargeable.getCurrentDischargeNodeIndex)
	SpecializationUtil.registerFunction(vehicleType, "getDischargeTargetObject", Dischargeable.getDischargeTargetObject)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentDischargeObject", Dischargeable.getCurrentDischargeObject)
	SpecializationUtil.registerFunction(vehicleType, "discharge", Dischargeable.discharge)
	SpecializationUtil.registerFunction(vehicleType, "dischargeToGround", Dischargeable.dischargeToGround)
	SpecializationUtil.registerFunction(vehicleType, "dischargeToObject", Dischargeable.dischargeToObject)
	SpecializationUtil.registerFunction(vehicleType, "setManualDischargeState", Dischargeable.setManualDischargeState)
	SpecializationUtil.registerFunction(vehicleType, "setDischargeState", Dischargeable.setDischargeState)
	SpecializationUtil.registerFunction(vehicleType, "getDischargeState", Dischargeable.getDischargeState)
	SpecializationUtil.registerFunction(vehicleType, "getDischargeFillType", Dischargeable.getDischargeFillType)
	SpecializationUtil.registerFunction(vehicleType, "getCanDischargeToGround", Dischargeable.getCanDischargeToGround)
	SpecializationUtil.registerFunction(vehicleType, "getCanDischargeAtPosition", Dischargeable.getCanDischargeAtPosition)
	SpecializationUtil.registerFunction(vehicleType, "getCanDischargeToLand", Dischargeable.getCanDischargeToLand)
	SpecializationUtil.registerFunction(vehicleType, "getCanDischargeToObject", Dischargeable.getCanDischargeToObject)
	SpecializationUtil.registerFunction(vehicleType, "getDischargeNotAllowedWarning", Dischargeable.getDischargeNotAllowedWarning)
	SpecializationUtil.registerFunction(vehicleType, "getCanToggleDischargeToObject", Dischargeable.getCanToggleDischargeToObject)
	SpecializationUtil.registerFunction(vehicleType, "getCanToggleDischargeToGround", Dischargeable.getCanToggleDischargeToGround)
	SpecializationUtil.registerFunction(vehicleType, "getIsPossibleToDischargeToObject", Dischargeable.getIsPossibleToDischargeToObject)
	SpecializationUtil.registerFunction(vehicleType, "getIsDischargeNodeActive", Dischargeable.getIsDischargeNodeActive)
	SpecializationUtil.registerFunction(vehicleType, "setIsDischargeAllowed", Dischargeable.setIsDischargeAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getDischargeNodeEmptyFactor", Dischargeable.getDischargeNodeEmptyFactor)
	SpecializationUtil.registerFunction(vehicleType, "getDischargeNodeAutomaticDischarge", Dischargeable.getDischargeNodeAutomaticDischarge)
	SpecializationUtil.registerFunction(vehicleType, "getDischargeNodeByNode", Dischargeable.getDischargeNodeByNode)
	SpecializationUtil.registerFunction(vehicleType, "updateRaycast", Dischargeable.updateRaycast)
	SpecializationUtil.registerFunction(vehicleType, "updateDischargeInfo", Dischargeable.updateDischargeInfo)
	SpecializationUtil.registerFunction(vehicleType, "raycastCallbackDischargeNode", Dischargeable.raycastCallbackDischargeNode)
	SpecializationUtil.registerFunction(vehicleType, "finishDischargeRaycast", Dischargeable.finishDischargeRaycast)
	SpecializationUtil.registerFunction(vehicleType, "getDischargeNodeByIndex", Dischargeable.getDischargeNodeByIndex)
	SpecializationUtil.registerFunction(vehicleType, "handleDischargeOnEmpty", Dischargeable.handleDischargeOnEmpty)
	SpecializationUtil.registerFunction(vehicleType, "handleDischargeNodeChanged", Dischargeable.handleDischargeNodeChanged)
	SpecializationUtil.registerFunction(vehicleType, "handleDischarge", Dischargeable.handleDischarge)
	SpecializationUtil.registerFunction(vehicleType, "handleDischargeRaycast", Dischargeable.handleDischargeRaycast)
	SpecializationUtil.registerFunction(vehicleType, "handleFoundDischargeObject", Dischargeable.handleFoundDischargeObject)
	SpecializationUtil.registerFunction(vehicleType, "setDischargeEffectDistance", Dischargeable.setDischargeEffectDistance)
	SpecializationUtil.registerFunction(vehicleType, "setDischargeEffectActive", Dischargeable.setDischargeEffectActive)
	SpecializationUtil.registerFunction(vehicleType, "updateDischargeSound", Dischargeable.updateDischargeSound)
	SpecializationUtil.registerFunction(vehicleType, "dischargeTriggerCallback", Dischargeable.dischargeTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "onDeleteDischargeTriggerObject", Dischargeable.onDeleteDischargeTriggerObject)
	SpecializationUtil.registerFunction(vehicleType, "dischargeActivationTriggerCallback", Dischargeable.dischargeActivationTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "onDeleteActivationTriggerObject", Dischargeable.onDeleteActivationTriggerObject)
	SpecializationUtil.registerFunction(vehicleType, "setForcedFillTypeIndex", Dischargeable.setForcedFillTypeIndex)
end

function Dischargeable.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRequiresTipOcclusionArea", Dischargeable.getRequiresTipOcclusionArea)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Dischargeable.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoConsumePtoPower", Dischargeable.getDoConsumePtoPower)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsPowerTakeOffActive", Dischargeable.getIsPowerTakeOffActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowLoadTriggerActivation", Dischargeable.getAllowLoadTriggerActivation)
end

function Dischargeable.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onDischargeStateChanged")
	SpecializationUtil.registerEvent(vehicleType, "onDischargeTargetObjectChanged")
end

function Dischargeable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Dischargeable)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Dischargeable)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", Dischargeable)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Dischargeable)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Dischargeable)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Dischargeable)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Dischargeable)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Dischargeable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Dischargeable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Dischargeable)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Dischargeable)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", Dischargeable)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Dischargeable)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", Dischargeable)
end

-- Local values: spec, coverConfigurationId, configKey
function Dischargeable:onLoad(savegame)
	local v_u_11_ = self.spec_dischargeable
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.pipeEffect", "vehicle.dischargeable.dischargeNode.effects")
	local v12_ = Utils.getNoNil(self.configurations.dischargeable, 1)
	local v13_ = string.format("vehicle.dischargeable.dischargeableConfigurations.dischargeableConfiguration(%d)", v12_ - 1)
	local v14_ = not self.xmlFile:hasProperty(v13_) and "vehicle.dischargeable" or v13_
	v_u_11_.isDischargeAllowed = true
	v_u_11_.dischargeNodes = {}
	v_u_11_.fillUnitDischargeNodeMapping = {}
	v_u_11_.dischargNodeMapping = {}
	v_u_11_.triggerToDischargeNode = {}
	v_u_11_.activationTriggerToDischargeNode = {}
	v_u_11_.requiresTipOcclusionArea = self.xmlFile:getValue(v14_ .. "#requiresTipOcclusionArea", true)
	v_u_11_.consumePower = self.xmlFile:getValue(v14_ .. "#consumePower", true)
	v_u_11_.stopDischargeOnDeactivate = self.xmlFile:getValue(v14_ .. "#stopDischargeOnDeactivate", true)
	v_u_11_.dischargedLiters = 0
	self.xmlFile:iterate(v14_ .. ".dischargeNode", function(_, p15_)
		-- upvalues: (copy) self, (copy) v_u_11_
		local v16_ = {}
		if self:loadDischargeNode(self.xmlFile, p15_, v16_) then
			local v17_
			if v_u_11_.dischargNodeMapping[v16_.node] == nil then
				v17_ = true
			else
				Logging.xmlWarning(self.xmlFile, "DischargeNode \'%d | %s\' already defined. Discharge nodes need to be unique. Ignoring it!", v16_.node, getName(v16_.node))
				v17_ = false
			end
			if v16_.trigger.node ~= nil and v_u_11_.triggerToDischargeNode[v16_.trigger.node] ~= nil then
				Logging.xmlWarning(self.xmlFile, "DischargeNode trigger \'%d | %s\' already defined. DischargeNode triggers need to be unique. Ignoring it!", v16_.trigger.node, getName(v16_.trigger.node))
				v17_ = false
			end
			if v16_.activationTrigger.node ~= nil and v_u_11_.activationTriggerToDischargeNode[v16_.activationTrigger.node] ~= nil then
				Logging.xmlWarning(self.xmlFile, "DischargeNode activationTrigger \'%d | %s\' already defined. DischargeNode activationTriggers need to be unique. Ignoring it!", v16_.activationTrigger.node, getName(v16_.activationTrigger.node))
				v17_ = false
			end
			if self.getFillUnitExists ~= nil and not self:getFillUnitExists(v16_.fillUnitIndex) then
				Logging.xmlWarning(self.xmlFile, "FillUnit with index \'%d\' does not exist for discharge node \'%s\'. Ignoring discharge node!", v16_.fillUnitIndex, p15_)
				v17_ = false
			end
			if v17_ then
				local v18_ = v_u_11_.dischargeNodes
				table.insert(v18_, v16_)
				v16_.index = #v_u_11_.dischargeNodes
				v_u_11_.fillUnitDischargeNodeMapping[v16_.fillUnitIndex] = v16_
				v_u_11_.dischargNodeMapping[v16_.node] = v16_
				if v16_.trigger.node ~= nil then
					v_u_11_.triggerToDischargeNode[v16_.trigger.node] = v16_
				end
				if v16_.activationTrigger.node ~= nil then
					v_u_11_.activationTriggerToDischargeNode[v16_.activationTrigger.node] = v16_
				end
			end
		end
	end)
	local v19_ = v_u_11_.requiresTipOcclusionArea
	if v19_ then
		v19_ = #v_u_11_.dischargeNodes > 0
	end
	v_u_11_.requiresTipOcclusionArea = v19_
	v_u_11_.currentDischargeState = Dischargeable.DISCHARGE_STATE_OFF
	v_u_11_.currentRaycast = nil
	v_u_11_.forcedFillTypeIndex = nil
	v_u_11_.raycastCollisionMask = CollisionFlag.FILLABLE + CollisionFlag.VEHICLE + CollisionFlag.TERRAIN
	v_u_11_.isAsyncRaycastActive = false
	v_u_11_.currentRaycast = {}
	self:setCurrentDischargeNodeIndex(1)
	v_u_11_.dirtyFlag = self:getNextDirtyFlag()
	if #v_u_11_.dischargeNodes == 0 then
		SpecializationUtil.removeEventListener(self, "onPostLoad", Dischargeable)
		SpecializationUtil.removeEventListener(self, "onReadStream", Dischargeable)
		SpecializationUtil.removeEventListener(self, "onWriteStream", Dischargeable)
		SpecializationUtil.removeEventListener(self, "onReadUpdateStream", Dischargeable)
		SpecializationUtil.removeEventListener(self, "onWriteUpdateStream", Dischargeable)
		SpecializationUtil.removeEventListener(self, "onUpdate", Dischargeable)
		SpecializationUtil.removeEventListener(self, "onUpdateTick", Dischargeable)
		SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", Dischargeable)
		SpecializationUtil.removeEventListener(self, "onFillUnitFillLevelChanged", Dischargeable)
		SpecializationUtil.removeEventListener(self, "onDeactivate", Dischargeable)
	end
end

-- Local values: spec
function Dischargeable:onPostLoad(savegame)
	local v22_ = self.spec_dischargeable
	if savegame ~= nil and not savegame.resetVehicles then
		v22_.isDischargeAllowed = savegame.xmlFile:getValue(savegame.key .. ".dischargeable#isAllowed", v22_.isDischargeAllowed)
	end
end

-- Local values: spec
function Dischargeable:saveToXMLFile(xmlFile, key, usedModNames)
	local v26_ = self.spec_dischargeable
	xmlFile:setValue(key .. "#isAllowed", v26_.isDischargeAllowed)
end

-- Local values: spec, activeDischargeNode, dischargeState
function Dischargeable:onRegisterDashboardValueTypes()
	local v28_ = self.spec_dischargeable
	local v29_ = DashboardValueType.new("dischargeable", "activeDischargeNode")
	v29_:setValue(self, function(_, p30_)
		-- upvalues: (copy) self
		local v31_
		if p30_.dischargeNodeIndex == nil then
			v31_ = false
		else
			v31_ = self:getCurrentDischargeNodeIndex() == p30_.dischargeNodeIndex
		end
		return v31_
	end)
	v29_:setAdditionalFunctions(Dischargeable.dashboardDischargeAttributes)
	v29_:setPollUpdate(false)
	self:registerDashboardValueType(v29_)
	local v32_ = DashboardValueType.new("dischargeable", "dischargeState")
	v32_:setValue(v28_, "currentDischargeState")
	v32_:setValueCompare(Dischargeable.DISCHARGE_STATE_OBJECT, Dischargeable.DISCHARGE_STATE_GROUND)
	v32_:setPollUpdate(false)
	self:registerDashboardValueType(v32_)
end

-- Local values: spec, _, dischargeNode, trigger, object, _, trigger, object, _
function Dischargeable:onDelete()
	local v34_ = self.spec_dischargeable
	if v34_.dischargeNodes ~= nil then
		for _, v35_ in ipairs(v34_.dischargeNodes) do
			g_effectManager:deleteEffects(v35_.effects)
			g_soundManager:deleteSample(v35_.sample)
			g_soundManager:deleteSample(v35_.dischargeSample)
			g_soundManager:deleteSamples(v35_.dischargeStateSamples)
			g_animationManager:deleteAnimations(v35_.animationNodes)
			g_animationManager:deleteAnimations(v35_.effectAnimationNodes)
			if v35_.trigger.node ~= nil then
				local v36_ = v35_.trigger
				removeTrigger(v36_.node)
				for v37_, _ in pairs(v36_.objects) do
					if v37_.removeDeleteListener ~= nil then
						v37_:removeDeleteListener(self, "onDeleteDischargeTriggerObject")
					end
				end
				table.clear(v36_.objects)
				v36_.numObjects = 0
			end
			if v35_.activationTrigger.node ~= nil then
				local v38_ = v35_.activationTrigger
				removeTrigger(v38_.node)
				for v39_, _ in pairs(v38_.objects) do
					if v39_.removeDeleteListener ~= nil then
						v39_:removeDeleteListener(self, "onDeleteActivationTriggerObject")
					end
				end
				table.clear(v38_.objects)
				v38_.numObjects = 0
			end
		end
	end
	v34_.dischargeNodes = nil
end

-- Local values: spec, _, dischargeNode, distance, fillTypeIndex
function Dischargeable:onReadStream(streamId, connection)
	if connection:getIsServer() then
		local v43_ = self.spec_dischargeable
		for _, v44_ in ipairs(v43_.dischargeNodes) do
			if streamReadBool(streamId) then
				local v45_ = streamReadUIntN(streamId, 8) * v44_.maxDistance / 255
				v44_.dischargeDistance = v45_
				self:setDischargeEffectActive(v44_, true, true, (streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)))
				self:setDischargeEffectDistance(v44_, v45_)
			else
				self:setDischargeEffectActive(v44_, false, true)
			end
		end
		self:setDischargeState(streamReadUIntN(streamId, Dischargeable.SEND_NUM_BITS_DISCHARGE_STATE), true)
	end
end

-- Local values: spec, _, dischargeNode
function Dischargeable:onWriteStream(streamId, connection)
	if not connection:getIsServer() then
		local v49_ = self.spec_dischargeable
		for _, v50_ in ipairs(v49_.dischargeNodes) do
			if streamWriteBool(streamId, v50_.isEffectActiveSent) then
				local v51_ = streamWriteUIntN
				local v52_ = v50_.dischargeDistanceSent / v50_.maxDistance * 255
				local v53_ = math.floor(v52_)
				v51_(streamId, math.clamp(v53_, 1, 255), 8)
				streamWriteUIntN(streamId, self:getDischargeFillType(v50_), FillTypeManager.SEND_NUM_BITS)
			end
		end
		streamWriteUIntN(streamId, v49_.currentDischargeState, Dischargeable.SEND_NUM_BITS_DISCHARGE_STATE)
	end
end

-- Local values: spec, _, dischargeNode, distance, fillTypeIndex
function Dischargeable:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local v57_ = self.spec_dischargeable
		if streamReadBool(streamId) then
			for _, v58_ in ipairs(v57_.dischargeNodes) do
				if streamReadBool(streamId) then
					local v59_ = streamReadUIntN(streamId, 8) * v58_.maxDistance / 255
					v58_.dischargeDistance = v59_
					self:setDischargeEffectActive(v58_, true, true, (streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)))
					self:setDischargeEffectDistance(v58_, v59_)
				else
					self:setDischargeEffectActive(v58_, false, true)
				end
			end
		end
	end
end

-- Local values: spec, _, dischargeNode
function Dischargeable:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v64_ = self.spec_dischargeable
		local v65_ = streamWriteBool
		local v66_ = v64_.dirtyFlag
		if v65_(streamId, bit32.band(dirtyMask, v66_) ~= 0) then
			for _, v67_ in ipairs(v64_.dischargeNodes) do
				if streamWriteBool(streamId, v67_.isEffectActiveSent) then
					local v68_ = streamWriteUIntN
					local v69_ = v67_.dischargeDistanceSent / v67_.maxDistance * 255
					local v70_ = math.floor(v69_)
					v68_(streamId, math.clamp(v70_, 1, 255), 8)
					streamWriteUIntN(streamId, self:getDischargeFillType(v67_), FillTypeManager.SEND_NUM_BITS)
				end
			end
		end
	end
end

-- Local values: spec, dischargeNode
function Dischargeable:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v72_ = self.spec_dischargeable
	local v73_ = v72_.currentDischargeNode
	if v73_ ~= nil and (v73_.activationTrigger.numObjects > 0 or v72_.currentDischargeState ~= Dischargeable.DISCHARGE_STATE_OFF) then
		self:raiseActive()
	end
end

-- Local values: spec, dischargeNode, trigger, lastDischargeObject, nearestDistance, object, data, fillType, dischargeFailedReason, dischargeFailedReasonShowAuto, customNotAllowedWarning, allowFillType, allowToolType, freeSpace, accessible, exactFillRootNode, distance, fillLevel, emptySpeed, canDischargeToObject, canDischargeToGround, canDischarge, allowedToDischarge, isReadyToStartDischarge, isReadyForDischarge, emptyLiters, dischargedLiters, minDropReached, hasMinDropFillLevel, currentDischargeNode, warning, _, inactiveDischargeNode, _, dischargeNode
function Dischargeable:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v78_ = self.spec_dischargeable
	local v79_ = v78_.currentDischargeNode
	if v79_ ~= nil then
		if isActiveForInputIgnoreSelection then
			Dischargeable.updateActionEvents(self)
		end
		if self:getIsDischargeNodeActive(v79_) then
			local v80_ = v79_.trigger
			if v80_.numObjects > 0 then
				local v81_ = v79_.dischargeObject
				v79_.dischargeObject = nil
				v79_.dischargeHitObject = nil
				v79_.dischargeHitObjectUnitIndex = nil
				v79_.dischargeHitTerrain = false
				v79_.dischargeShape = nil
				v79_.dischargeDistance = 0
				v79_.dischargeFillUnitIndex = nil
				v79_.dischargeHit = false
				local v82_ = math.huge
				for v83_, v84_ in pairs(v80_.objects) do
					local v85_ = v78_.forcedFillTypeIndex
					if v85_ == nil then
						v85_ = self:getDischargeFillType(v79_)
					end
					local v86_ = nil
					local v87_ = false
					local v88_ = nil
					local v89_
					if v83_:getFillUnitSupportsFillType(v84_.fillUnitIndex, v85_) then
						local v90_ = v83_:getFillUnitAllowsFillType(v84_.fillUnitIndex, v85_)
						local v91_ = v83_:getFillUnitSupportsToolType(v84_.fillUnitIndex, ToolType.TRIGGER)
						local v92_ = v83_:getFillUnitFreeCapacity(v84_.fillUnitIndex, v85_, self:getActiveFarm()) > 0
						local v93_ = v83_:getIsFillAllowedFromFarm(self:getActiveFarm())
						if v90_ and (v91_ and v92_) then
							local v94_ = v83_:getFillUnitExactFillRootNode(v84_.fillUnitIndex)
							if v94_ == nil or not entityExists(v94_) then
								v89_ = v82_
							else
								v89_ = calcDistanceFrom(v79_.node, v94_)
								if v89_ < v82_ then
									v79_.dischargeObject = v83_
									v79_.dischargeHitTerrain = false
									v79_.dischargeShape = v84_.shape
									v79_.dischargeDistance = v89_
									v79_.dischargeFillUnitIndex = v84_.fillUnitIndex
									if v83_ ~= v81_ then
										SpecializationUtil.raiseEvent(self, "onDischargeTargetObjectChanged", v83_)
										self.rootVehicle:raiseActive()
									end
								else
									v89_ = v82_
								end
							end
						elseif v90_ then
							if v91_ then
								if v93_ then
									if v92_ then
										v89_ = v82_
									else
										v86_ = Dischargeable.DISCHARGE_REASON_NO_FREE_CAPACITY
										v89_ = v82_
									end
								else
									v86_ = Dischargeable.DISCHARGE_REASON_NO_ACCESS
									v89_ = v82_
								end
							else
								v86_ = Dischargeable.DISCHARGE_REASON_TOOLTYPE_NOT_SUPPORTED
								v89_ = v82_
							end
						else
							v86_ = Dischargeable.DISCHARGE_REASON_FILLTYPE_NOT_SUPPORTED
							v89_ = v82_
						end
						v79_.dischargeHitObject = v83_
						v79_.dischargeHitObjectUnitIndex = v84_.fillUnitIndex
					elseif v85_ == FillType.UNKNOWN then
						v89_ = v82_
					else
						v86_ = Dischargeable.DISCHARGE_REASON_FILLTYPE_NOT_SUPPORTED
						v89_ = v82_
					end
					if v86_ == Dischargeable.DISCHARGE_REASON_FILLTYPE_NOT_SUPPORTED or (v86_ == Dischargeable.DISCHARGE_REASON_NO_FREE_CAPACITY or v86_ == Dischargeable.DISCHARGE_REASON_NO_ACCESS) then
						v87_ = (v83_.isa == nil or not v83_:isa(Vehicle)) and true or v87_
					end
					if v86_ ~= nil and (v86_ ~= Dischargeable.DISCHARGE_REASON_FILLTYPE_NOT_SUPPORTED and v83_.getCustomDischargeNotAllowedWarning ~= nil) then
						v88_ = v83_:getCustomDischargeNotAllowedWarning()
					end
					if v79_.dischargeObject == nil and v86_ ~= nil then
						if v79_.dischargeFailedReason == nil or v86_ < v79_.dischargeFailedReason then
							v79_.dischargeFailedReason = v86_
							v79_.dischargeFailedReasonShowAuto = v87_
							v79_.customNotAllowedWarning = v88_
						end
					else
						v79_.dischargeFailedReason = nil
						v79_.dischargeFailedReasonShowAuto = false
						v79_.customNotAllowedWarning = nil
					end
					v79_.dischargeHit = true
					v82_ = v89_
				end
				if v81_ ~= nil and v79_.dischargeObject == nil then
					SpecializationUtil.raiseEvent(self, "onDischargeTargetObjectChanged", nil)
					self.rootVehicle:raiseActive()
				end
			elseif not v78_.isAsyncRaycastActive then
				self:updateRaycast(v79_)
			end
		else
			if v78_.currentDischargeState ~= Dischargeable.DISCHARGE_STATE_OFF then
				self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF, true)
			end
			if v79_.dischargeObject ~= nil then
				SpecializationUtil.raiseEvent(self, "onDischargeTargetObjectChanged", nil)
				self.rootVehicle:raiseActive()
			end
			v79_.dischargeObject = nil
			v79_.dischargeHitObject = nil
			v79_.dischargeHitObjectUnitIndex = nil
			v79_.dischargeHitTerrain = false
			v79_.dischargeShape = nil
			v79_.dischargeDistance = 0
			v79_.dischargeFillUnitIndex = nil
			v79_.dischargeHit = false
		end
		self:updateDischargeSound(v79_, dt)
		if self.isServer then
			if v78_.currentDischargeState == Dischargeable.DISCHARGE_STATE_OFF then
				if v79_.dischargeObject ~= nil then
					self:handleFoundDischargeObject(v79_)
				end
			else
				local v95_ = self:getFillUnitFillLevel(v79_.fillUnitIndex)
				local v96_ = self:getDischargeNodeEmptyFactor(v79_)
				local v97_ = self:getCanDischargeToObject(v79_)
				if v97_ then
					v97_ = v78_.currentDischargeState == Dischargeable.DISCHARGE_STATE_OBJECT
				end
				local v98_ = self:getCanDischargeToGround(v79_)
				if v98_ then
					v98_ = v78_.currentDischargeState == Dischargeable.DISCHARGE_STATE_GROUND
				end
				local v99_ = v97_ or v98_
				local v100_ = v79_.dischargeObject == nil and self:getCanDischargeToLand(v79_)
				if v100_ then
					v100_ = self:getCanDischargeAtPosition(v79_)
				end
				local v101_
				if v95_ > 0 and v96_ > 0 then
					if v100_ then
						v101_ = v99_
					else
						v101_ = v100_
					end
				else
					v101_ = false
				end
				self:setDischargeEffectActive(v79_, v101_)
				self:setDischargeEffectDistance(v79_, v79_.dischargeDistance)
				if (v79_.lastEffect == nil and true or v79_.lastEffect:getIsFullyVisible()) and (v100_ and v99_) then
					local v102_ = v79_.emptySpeed * v96_ * dt
					local v103_, v104_, v105_ = self:discharge(v79_, (math.min(v95_, v102_)))
					v78_.dischargedLiters = v103_
					self:handleDischarge(v79_, v103_, v104_, v105_)
				end
			end
			local v106_ = v79_.dischargeDistanceSent - v79_.dischargeDistance
			if math.abs(v106_) > 0.05 then
				self:raiseDirtyFlags(v78_.dirtyFlag)
				v79_.dischargeDistanceSent = v79_.dischargeDistance
			end
		end
	end
	if v78_.currentDischargeState == Dischargeable.DISCHARGE_STATE_OFF and (isActiveForInput and (self:getCanDischargeToObject(v78_.currentDischargeNode) and self:getCanToggleDischargeToObject())) then
		g_currentMission:showTipContext(self:getFillUnitFillType(v79_.fillUnitIndex))
	end
	if isActiveForInputIgnoreSelection and (v79_ ~= nil and (v79_.canStartDischargeAutomatically and (v79_.dischargeHit and (v79_.dischargeFailedReasonShowAuto and (v79_.dischargeFailedReason ~= nil and g_currentMission.time > 10000))))) then
		local v107_ = self:getDischargeNotAllowedWarning(v79_)
		g_currentMission:showBlinkingWarning(v107_, 5000)
	end
	if self.isServer then
		for _, v108_ in ipairs(v78_.dischargeNodes) do
			if v108_.stopEffectTime ~= nil then
				if v108_.stopEffectTime < g_time then
					self:setDischargeEffectActive(v108_, false, true)
					v108_.stopEffectTime = nil
				else
					self:raiseActive()
				end
			end
		end
	end
	if self.isClient then
		for _, v109_ in ipairs(v78_.dischargeNodes) do
			if g_soundManager:getIsSamplePlaying(v109_.dischargeSample) then
				self:raiseActive()
			end
			if v109_.sample ~= nil and g_soundManager:getIsSamplePlaying(v109_.sample) then
				self:raiseActive()
			end
		end
	end
end

-- Local values: toolTypeStr, raycastMaxDistance, fillTypeConverterName
function Dischargeable:loadDischargeNode(xmlFile, key, entry)
	entry.isActive = true
	entry.node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	if entry.node == nil then
		Logging.xmlWarning(self.xmlFile, "Missing discharge \'node\' for dischargeNode \'%s\'", key)
		return false
	end
	entry.fillUnitIndex = xmlFile:getValue(key .. "#fillUnitIndex")
	if entry.fillUnitIndex == nil then
		Logging.xmlWarning(self.xmlFile, "Missing \'fillUnitIndex\' for dischargeNode \'%s\'", key)
		return false
	end
	entry.unloadInfoIndex = xmlFile:getValue(key .. "#unloadInfoIndex", 1)
	entry.stopDischargeOnEmpty = xmlFile:getValue(key .. "#stopDischargeOnEmpty", true)
	entry.canDischargeToGround = xmlFile:getValue(key .. "#canDischargeToGround", true)
	entry.canDischargeToObject = xmlFile:getValue(key .. "#canDischargeToObject", true)
	entry.canDischargeToVehicle = xmlFile:getValue(key .. "#canDischargeToVehicle", entry.canDischargeToObject)
	entry.canStartDischargeAutomatically = xmlFile:getValue(key .. "#canStartDischargeAutomatically", Platform.gameplay.automaticDischarge)
	entry.canStartGroundDischargeAutomatically = xmlFile:getValue(key .. "#canStartGroundDischargeAutomatically", false)
	entry.stopDischargeIfNotPossible = xmlFile:getValue(key .. "#stopDischargeIfNotPossible", xmlFile:hasProperty(key .. ".trigger#node"))
	entry.canDischargeToGroundAnywhere = xmlFile:getValue(key .. "#canDischargeToGroundAnywhere", false)
	entry.canDischargeToMissionGround = xmlFile:getValue(key .. "#canDischargeToMissionGround", false)
	entry.canFillOwnVehicle = xmlFile:getValue(key .. "#canFillOwnVehicle", false)
	entry.limitGroundTipToFillLevel = xmlFile:getValue(key .. "#limitGroundTipToFillLevel", false)
	entry.emptySpeed = xmlFile:getValue(key .. "#emptySpeed", self:getFillUnitCapacity(entry.fillUnitIndex)) / 1000 * Platform.gameplay.dischargeSpeedFactor
	entry.effectTurnOffThreshold = xmlFile:getValue(key .. "#effectTurnOffThreshold", 0.25)
	entry.lineOffset = 0
	entry.litersToDrop = 0
	local v114_ = xmlFile:getValue(key .. "#toolType", "dischargeable")
	entry.toolType = g_toolTypeManager:getToolTypeIndexByName(v114_)
	entry.info = {}
	entry.info.node = xmlFile:getValue(key .. ".info#node", entry.node, self.components, self.i3dMappings)
	if entry.info.node == entry.node then
		entry.info.node = createTransformGroup("dischargeInfoNode")
		link(entry.node, entry.info.node)
	end
	entry.info.width = xmlFile:getValue(key .. ".info#width", 1) / 2
	entry.info.length = xmlFile:getValue(key .. ".info#length", 1) / 2
	entry.info.zOffset = xmlFile:getValue(key .. ".info#zOffset", 0)
	entry.info.yOffset = xmlFile:getValue(key .. ".info#yOffset", 2)
	entry.info.limitToGround = xmlFile:getValue(key .. ".info#limitToGround", true)
	entry.info.useRaycastHitPosition = xmlFile:getValue(key .. ".info#useRaycastHitPosition", false)
	entry.trigger = {}
	entry.trigger.node = xmlFile:getValue(key .. ".trigger#node", nil, self.components, self.i3dMappings)
	if entry.trigger.node ~= nil then
		addTrigger(entry.trigger.node, "dischargeTriggerCallback", self)
		setTriggerReportStatics(entry.trigger.node, true)
	end
	entry.trigger.objects = {}
	entry.trigger.numObjects = 0
	entry.raycast = {}
	entry.raycast.node = xmlFile:getValue(key .. ".raycast#node", nil, self.components, self.i3dMappings)
	if entry.raycast.node == nil and entry.trigger.node == nil then
		entry.raycast.node = entry.node
	end
	entry.raycast.useWorldNegYDirection = xmlFile:getValue(key .. ".raycast#useWorldNegYDirection", false)
	entry.raycast.yOffset = xmlFile:getValue(key .. ".raycast#yOffset", 0)
	local v115_ = xmlFile:getValue(key .. ".raycast#maxDistance")
	entry.maxDistance = xmlFile:getValue(key .. "#maxDistance", v115_) or 10
	entry.dischargeObject = nil
	entry.dischargeHitObject = nil
	entry.dischargeHitObjectUnitIndex = nil
	entry.dischargeHitTerrain = false
	entry.dischargeShape = nil
	entry.dischargeDistance = 0
	entry.dischargeDistanceSent = 0
	entry.dischargeFillUnitIndex = nil
	entry.dischargeHit = false
	entry.activationTrigger = {}
	entry.activationTrigger.node = xmlFile:getValue(key .. ".activationTrigger#node", nil, self.components, self.i3dMappings)
	if entry.activationTrigger.node ~= nil then
		addTrigger(entry.activationTrigger.node, "dischargeActivationTriggerCallback", self)
	end
	entry.activationTrigger.objects = {}
	entry.activationTrigger.numObjects = 0
	local v116_ = xmlFile:getValue(key .. ".fillType#converterName")
	if v116_ ~= nil then
		entry.fillTypeConverter = g_fillTypeManager:getConverterDataByName(v116_)
	end
	entry.distanceObjectChanges = {}
	ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key .. ".distanceObjectChanges", entry.distanceObjectChanges, self.components, self)
	if #entry.distanceObjectChanges == 0 then
		entry.distanceObjectChanges = nil
	else
		entry.distanceObjectChangeThreshold = xmlFile:getValue(key .. ".distanceObjectChanges#threshold", 0.5)
		ObjectChangeUtil.setObjectChanges(entry.distanceObjectChanges, false, self, self.setMovingToolDirty)
	end
	entry.stateObjectChanges = {}
	ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key .. ".stateObjectChanges", entry.stateObjectChanges, self.components, self)
	if #entry.stateObjectChanges == 0 then
		entry.stateObjectChanges = nil
	else
		ObjectChangeUtil.setObjectChanges(entry.stateObjectChanges, false, self, self.setMovingToolDirty)
	end
	entry.nodeActiveObjectChanges = {}
	ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key .. ".nodeActiveObjectChanges", entry.nodeActiveObjectChanges, self.components, self)
	if #entry.nodeActiveObjectChanges == 0 then
		entry.nodeActiveObjectChanges = nil
	else
		ObjectChangeUtil.setObjectChanges(entry.nodeActiveObjectChanges, false, self, self.setMovingToolDirty)
	end
	entry.effects = g_effectManager:loadEffect(xmlFile, key .. ".effects", self.components, self, self.i3dMappings, math.huge)
	entry.animationName = xmlFile:getValue(key .. ".animation#name")
	entry.animationSpeed = xmlFile:getValue(key .. ".animation#speed", 1)
	entry.animationResetSpeed = xmlFile:getValue(key .. ".animation#resetSpeed", 1)
	if self.isClient then
		entry.playSound = xmlFile:getValue(key .. "#playSound", true)
		entry.soundNode = xmlFile:getValue(key .. "#soundNode", nil, self.components, self.i3dMappings)
		if entry.playSound then
			entry.dischargeSample = g_soundManager:loadSampleFromXML(self.xmlFile, key, "dischargeSound", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		end
		if xmlFile:getValue(key .. ".dischargeSound#overwriteSharedSound", false) then
			entry.playSound = false
		end
		entry.dischargeStateSamples = g_soundManager:loadSamplesFromXML(self.xmlFile, key, "dischargeStateSound", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		entry.animationNodes = g_animationManager:loadAnimations(self.xmlFile, key .. ".animationNodes", self.components, self, self.i3dMappings)
		entry.effectAnimationNodes = g_animationManager:loadAnimations(self.xmlFile, key .. ".effectAnimationNodes", self.components, self, self.i3dMappings)
	end
	entry.sentHitDistance = 0
	entry.isEffectActive = false
	entry.isEffectActiveSent = false
	entry.lastEffect = entry.effects[#entry.effects]
	return true
end

-- Local values: spec, i, node
function Dischargeable:setCurrentDischargeNodeIndex(dischargeNodeIndex)
	local v119_ = self.spec_dischargeable
	if v119_.currentDischargeNode ~= nil and v119_.dischargeNodes[dischargeNodeIndex] ~= v119_.currentDischargeNode then
		self:setDischargeEffectActive(v119_.currentDischargeNode, false, true)
		self:updateDischargeSound(v119_.currentDischargeNode, 99999)
		if v119_.dischargeNodes[dischargeNodeIndex] ~= v119_.currentDischargeNode then
			g_animationManager:stopAnimations(v119_.currentDischargeNode.animationNodes)
			g_animationManager:stopAnimations(v119_.currentDischargeNode.effectAnimationNodes)
		end
		g_soundManager:stopSamples(v119_.currentDischargeNode.dischargeStateSamples)
	end
	v119_.currentDischargeNode = v119_.dischargeNodes[dischargeNodeIndex]
	for v120_ = 1, #v119_.dischargeNodes do
		local v121_ = v119_.dischargeNodes[v120_]
		if v121_.nodeActiveObjectChanges ~= nil then
			ObjectChangeUtil.setObjectChanges(v121_.nodeActiveObjectChanges, v120_ == dischargeNodeIndex, self, self.setMovingToolDirty)
		end
	end
	if self.isClient and self.updateDashboardValueType ~= nil then
		self:updateDashboardValueType("dischargeable.activeDischargeNode")
	end
	self:handleDischargeNodeChanged()
end

-- Local values: spec
function Dischargeable:getCurrentDischargeNode()
	return self.spec_dischargeable.currentDischargeNode
end

-- Local values: spec
function Dischargeable:getCurrentDischargeNodeIndex()
	local v124_ = self.spec_dischargeable
	return v124_.currentDischargeNode == nil and 0 or v124_.currentDischargeNode.index
end

function Dischargeable:getDischargeTargetObject(dischargeNode)
	return dischargeNode.dischargeObject, dischargeNode.dischargeFillUnitIndex
end

function Dischargeable:getCurrentDischargeObject(dischargeNode)
	return dischargeNode.currentDischargeObject
end

-- Local values: spec
function Dischargeable:getRequiresTipOcclusionArea()
	return self.spec_dischargeable.requiresTipOcclusionArea
end

function Dischargeable:getCanBeSelected(superFunc)
	return true
end

function Dischargeable:getDoConsumePtoPower(superFunc)
	return self.spec_dischargeable.consumePower and self:getDischargeState() ~= Dischargeable.DISCHARGE_STATE_OFF and true or superFunc(self)
end

function Dischargeable:getIsPowerTakeOffActive(superFunc)
	return self.spec_dischargeable.consumePower and self:getDischargeState() ~= Dischargeable.DISCHARGE_STATE_OFF and true or superFunc(self)
end

-- Local values: spec, object
function Dischargeable:getAllowLoadTriggerActivation(superFunc, rootVehicle)
	if superFunc(self, rootVehicle) then
		return true
	end
	local v135_ = self.spec_dischargeable
	if v135_.currentDischargeNode ~= nil then
		local v136_ = v135_.currentDischargeNode.dischargeHitObject
		if v136_ ~= nil and v136_.getAllowLoadTriggerActivation ~= nil then
			if v136_ == rootVehicle then
				return false
			else
				return v136_:getAllowLoadTriggerActivation(rootVehicle)
			end
		end
	end
	return false
end

-- Local values: spec, dischargedLiters, minDropReached, hasMinDropFillLevel, object, fillUnitIndex
function Dischargeable:discharge(dischargeNode, emptyLiters)
	local v140_ = self.spec_dischargeable
	local v141_ = 0
	local v142_ = true
	local v143_ = true
	local v144_, v145_ = self:getDischargeTargetObject(dischargeNode)
	dischargeNode.currentDischargeObject = nil
	if v144_ == nil then
		if dischargeNode.dischargeHitTerrain and v140_.currentDischargeState == Dischargeable.DISCHARGE_STATE_GROUND then
			v141_, v142_, v143_ = self:dischargeToGround(dischargeNode, emptyLiters)
		end
	elseif v140_.currentDischargeState == Dischargeable.DISCHARGE_STATE_OBJECT then
		return self:dischargeToObject(dischargeNode, emptyLiters, v144_, v145_), v142_, v143_
	end
	return v141_, v142_, v143_
end

-- Local values: fillType, factor, fillLevel, minLiterToDrop, minDropReached, hasMinDropFillLevel, info, dischargedLiters, sx, sy, sz, ex, ey, ez, dropped, lineOffset, unloadInfo
function Dischargeable:dischargeToGround(dischargeNode, emptyLiters)
	if emptyLiters == 0 then
		return 0, false, false
	end
	local v149_, v150_ = self:getDischargeFillType(dischargeNode)
	local v151_ = self:getFillUnitFillLevel(dischargeNode.fillUnitIndex)
	local v152_ = g_densityMapHeightManager:getMinValidLiterValue(v149_)
	local v153_ = dischargeNode.litersToDrop + emptyLiters
	local v154_ = dischargeNode.emptySpeed * 250
	local v155_ = math.max(v154_, v152_)
	dischargeNode.litersToDrop = math.min(v153_, v155_)
	if dischargeNode.limitGroundTipToFillLevel then
		local v156_ = dischargeNode.litersToDrop
		dischargeNode.litersToDrop = math.min(v156_, v151_)
	end
	local v157_ = v152_ < dischargeNode.litersToDrop
	local v158_ = v152_ < v151_
	local v159_ = dischargeNode.info
	local v160_ = 0
	local v161_, v162_, v163_ = localToWorld(v159_.node, -v159_.width, 0, v159_.zOffset)
	local v164_, v165_, v166_ = localToWorld(v159_.node, v159_.width, 0, v159_.zOffset)
	local v167_ = v162_ + v159_.yOffset
	local v168_ = v165_ + v159_.yOffset
	if v159_.limitToGround then
		local v169_ = getTerrainHeightAtWorldPos(g_terrainNode, v161_, 0, v163_) + 0.1
		v167_ = math.max(v169_, v167_)
		local v170_ = getTerrainHeightAtWorldPos(g_terrainNode, v164_, 0, v166_) + 0.1
		v168_ = math.max(v170_, v168_)
	end
	local v171_, v172_ = DensityMapHeightUtil.tipToGroundAroundLine(self, dischargeNode.litersToDrop * v150_, v149_, v161_, v167_, v163_, v164_, v168_, v166_, v159_.length, nil, dischargeNode.lineOffset, true, nil, true)
	local v173_ = v171_ / v150_
	dischargeNode.lineOffset = v172_
	dischargeNode.litersToDrop = dischargeNode.litersToDrop - v173_
	if v173_ > 0 then
		local v174_ = self:getFillVolumeUnloadInfo(dischargeNode.unloadInfoIndex)
		v160_ = self:addFillUnitFillLevel(self:getOwnerFarmId(), dischargeNode.fillUnitIndex, -v173_, self:getFillUnitFillType(dischargeNode.fillUnitIndex), ToolType.UNDEFINED, v174_)
	end
	local v175_ = self:getFillUnitFillLevel(dischargeNode.fillUnitIndex)
	if v175_ > 0 and v175_ <= v152_ then
		dischargeNode.litersToDrop = v152_
	end
	return v160_, v157_, v158_
end

-- Local values: fillType, factor, supportsFillType, dischargedLiters, allowFillType, delta, unloadInfo
function Dischargeable:dischargeToObject(dischargeNode, emptyLiters, object, targetFillUnitIndex)
	local v181_, v182_ = self:getDischargeFillType(dischargeNode)
	local v183_
	if object:getFillUnitSupportsFillType(targetFillUnitIndex, v181_) and object:getFillUnitAllowsFillType(targetFillUnitIndex, v181_) then
		dischargeNode.currentDischargeObject = object
		local v184_ = object:addFillUnitFillLevel(self:getActiveFarm(), targetFillUnitIndex, emptyLiters * v182_, v181_, dischargeNode.toolType, dischargeNode.info) / v182_
		local v185_ = self:getFillVolumeUnloadInfo(dischargeNode.unloadInfoIndex)
		v183_ = self:addFillUnitFillLevel(self:getOwnerFarmId(), dischargeNode.fillUnitIndex, -v184_, self:getFillUnitFillType(dischargeNode.fillUnitIndex), ToolType.UNDEFINED, v185_)
	else
		v183_ = 0
	end
	return v183_
end

function Dischargeable:setManualDischargeState(state, noEventSend)
	self:setDischargeState(state, noEventSend)
end

-- Local values: spec, dischargeNode, i, node
function Dischargeable:setDischargeState(state, noEventSend)
	local v192_ = self.spec_dischargeable
	if state ~= v192_.currentDischargeState then
		SetDischargeStateEvent.sendEvent(self, state, noEventSend)
		v192_.currentDischargeState = state
		local v193_ = v192_.currentDischargeNode
		if self.isServer and state == Dischargeable.DISCHARGE_STATE_OFF then
			self:setDischargeEffectActive(v193_, false)
		end
		if self.isClient then
			if state == Dischargeable.DISCHARGE_STATE_OFF then
				g_animationManager:stopAnimations(v193_.animationNodes)
				g_soundManager:stopSamples(v193_.dischargeStateSamples)
			else
				g_animationManager:startAnimations(v193_.animationNodes)
				g_soundManager:playSamples(v193_.dischargeStateSamples)
			end
			if self.updateDashboardValueType ~= nil then
				self:updateDashboardValueType("dischargeable.dischargeState")
			end
		end
		for v194_ = 1, #v192_.dischargeNodes do
			local v195_ = v192_.dischargeNodes[v194_]
			if v195_.stateObjectChanges ~= nil then
				local v196_ = ObjectChangeUtil.setObjectChanges
				local v197_ = v195_.stateObjectChanges
				local v198_
				if state == Dischargeable.DISCHARGE_STATE_OFF then
					v198_ = false
				else
					v198_ = v195_ == v193_
				end
				v196_(v197_, v198_, self, self.setMovingToolDirty)
			end
		end
		if v193_.animationName ~= nil then
			if state == Dischargeable.DISCHARGE_STATE_OFF then
				self:playAnimation(v193_.animationName, -v193_.animationResetSpeed, self:getAnimationTime(v193_.animationName), true)
			else
				self:playAnimation(v193_.animationName, v193_.animationSpeed, self:getAnimationTime(v193_.animationName), true)
			end
		end
		SpecializationUtil.raiseEvent(self, "onDischargeStateChanged", state)
	end
end

function Dischargeable:getDischargeState()
	return self.spec_dischargeable.currentDischargeState
end

-- Local values: fillType, conversionFactor, conversion
function Dischargeable:getDischargeFillType(dischargeNode)
	local v202_ = self:getFillUnitFillType(dischargeNode.fillUnitIndex)
	local v203_ = 1
	if dischargeNode.fillTypeConverter ~= nil then
		local v204_ = dischargeNode.fillTypeConverter[v202_]
		if v204_ ~= nil then
			v202_ = v204_.targetFillTypeIndex
			v203_ = v204_.conversionFactor
		end
	end
	return v202_, v203_
end

-- Local values: fillTypeIndex
function Dischargeable:getCanDischargeToGround(dischargeNode)
	if not self.spec_dischargeable.isDischargeAllowed then
		return false
	end
	if dischargeNode == nil then
		return false
	end
	if not dischargeNode.dischargeHitTerrain then
		return false
	end
	if self:getFillUnitFillLevel(dischargeNode.fillUnitIndex) > 0 then
		local v207_ = self:getDischargeFillType(dischargeNode)
		if not DensityMapHeightUtil.getCanTipToGround(v207_) then
			return false
		end
	end
	return true
end

-- Local values: info, sx, _, sz, ex, _, ez, activeFarmId, mission
function Dischargeable:getCanDischargeToLand(dischargeNode)
	if dischargeNode == nil then
		return false
	elseif dischargeNode.canDischargeToGroundAnywhere then
		return true
	else
		local v210_ = dischargeNode.info
		local v211_, _, v212_ = localToWorld(v210_.node, -v210_.width, 0, v210_.zOffset)
		local v213_, _, v214_ = localToWorld(v210_.node, v210_.width, 0, v210_.zOffset)
		local v215_ = self:getActiveFarm()
		if dischargeNode.canDischargeToMissionGround then
			local v216_ = g_missionManager:getMissionAtWorldPosition(v211_, v212_)
			if v216_ == nil then
				v216_ = g_missionManager:getMissionAtWorldPosition(v213_, v214_)
			end
			if v216_ ~= nil and (v216_.farmId ~= nil and v216_.farmId == v215_) then
				return true
			end
		end
		if g_currentMission.accessHandler:canFarmAccessLand(v215_, v211_, v212_) then
			return g_currentMission.accessHandler:canFarmAccessLand(v215_, v213_, v214_) and true or false
		else
			return false
		end
	end
end

-- Local values: info, sx, sy, sz, ex, ey, ez, spec, fillType, testDrop
function Dischargeable:getCanDischargeAtPosition(dischargeNode)
	if dischargeNode == nil then
		return false
	end
	if self:getFillUnitFillLevel(dischargeNode.fillUnitIndex) > 0 then
		local v219_ = dischargeNode.info
		local v220_, v221_, v222_ = localToWorld(v219_.node, -v219_.width, 0, v219_.zOffset)
		local v223_, v224_, v225_ = localToWorld(v219_.node, v219_.width, 0, v219_.zOffset)
		local v226_ = self.spec_dischargeable
		if v226_.currentDischargeState == Dischargeable.DISCHARGE_STATE_OFF or v226_.currentDischargeState == Dischargeable.DISCHARGE_STATE_GROUND then
			local v227_ = v221_ + v219_.yOffset
			local v228_ = v224_ + v219_.yOffset
			if v219_.limitToGround then
				local v229_ = getTerrainHeightAtWorldPos(g_terrainNode, v220_, 0, v222_) + 0.1
				v227_ = math.max(v229_, v227_)
				local v230_ = getTerrainHeightAtWorldPos(g_terrainNode, v223_, 0, v225_) + 0.1
				v228_ = math.max(v230_, v228_)
			end
			local v231_ = self:getDischargeFillType(dischargeNode)
			local v232_ = g_densityMapHeightManager:getMinValidLiterValue(v231_)
			if not DensityMapHeightUtil.getCanTipToGroundAroundLine(self, v232_, v231_, v220_, v227_, v222_, v223_, v228_, v225_, v219_.length, nil, dischargeNode.lineOffset, true, nil, true) then
				return false
			end
		end
	end
	return true
end

-- Local values: object, fillType, allowFillType, mounter
function Dischargeable:getCanDischargeToObject(dischargeNode)
	if not self.spec_dischargeable.isDischargeAllowed then
		return false
	end
	if dischargeNode == nil then
		return false
	end
	local v235_ = dischargeNode.dischargeObject
	if v235_ == nil then
		return false
	end
	local v236_ = self:getDischargeFillType(dischargeNode)
	if not v235_:getFillUnitSupportsFillType(dischargeNode.dischargeFillUnitIndex, v236_) then
		return false
	end
	if not v235_:getFillUnitAllowsFillType(dischargeNode.dischargeFillUnitIndex, v236_) then
		return false
	end
	if v235_.getFillUnitFreeCapacity ~= nil and v235_:getFillUnitFreeCapacity(dischargeNode.dischargeFillUnitIndex, v236_, self:getActiveFarm()) <= 0 then
		return false
	end
	if v235_.getIsFillAllowedFromFarm ~= nil and not v235_:getIsFillAllowedFromFarm(self:getActiveFarm()) then
		return false
	end
	if self.getDynamicMountObject ~= nil then
		local v237_ = self:getDynamicMountObject()
		if v237_ ~= nil and not g_currentMission.accessHandler:canFarmAccess(v237_:getActiveFarm(), self, true) then
			return false
		end
	end
	return true
end

-- Local values: text, fillType, fillTypeDesc
function Dischargeable:getDischargeNotAllowedWarning(dischargeNode)
	local v240_ = g_i18n:getText(Dischargeable.DISCHARGE_WARNINGS[dischargeNode.dischargeFailedReason or Dischargeable.DISCHARGE_REASON_NOT_ALLOWED_HERE] or "warning_actionNotAllowedHere")
	if dischargeNode.customNotAllowedWarning ~= nil then
		v240_ = dischargeNode.customNotAllowedWarning
	end
	local v241_ = self:getDischargeFillType(dischargeNode)
	local v242_ = g_fillTypeManager:getFillTypeByIndex(v241_)
	return string.format(v240_, v242_.title)
end

-- Local values: spec, dischargeNode
function Dischargeable:getCanToggleDischargeToObject()
	local v244_ = self.spec_dischargeable.currentDischargeNode
	local v245_
	if v244_ == nil then
		v245_ = false
	else
		v245_ = v244_.canDischargeToObject
	end
	return v245_
end

-- Local values: spec, dischargeNode
function Dischargeable:getCanToggleDischargeToGround()
	local v247_ = self.spec_dischargeable.currentDischargeNode
	local v248_ = v247_ ~= nil and v247_.canDischargeToGround
	if v248_ then
		v248_ = not v247_.canStartGroundDischargeAutomatically
	end
	return v248_
end

-- Local values: spec, currentDischargeNode
function Dischargeable:getIsPossibleToDischargeToObject()
	local v250_ = self.spec_dischargeable
	if v250_.currentDischargeState ~= Dischargeable.DISCHARGE_STATE_OFF then
		return false
	end
	local v251_ = v250_.currentDischargeNode
	local v252_ = self:getIsActiveForInput() and self:getCanDischargeToObject(v251_)
	if v252_ then
		v252_ = self:getCanToggleDischargeToObject()
	end
	return v252_
end

function Dischargeable:getIsDischargeNodeActive(dischargeNode)
	return self.spec_dischargeable.isDischargeAllowed
end

function Dischargeable:setIsDischargeAllowed(isAllowed)
	self.spec_dischargeable.isDischargeAllowed = isAllowed
end

function Dischargeable:getDischargeNodeEmptyFactor(dischargeNode)
	return 1
end

function Dischargeable:getDischargeNodeAutomaticDischarge(dischargeNode)
	return dischargeNode.canStartDischargeAutomatically
end

function Dischargeable:getDischargeNodeByNode(node)
	return self.spec_dischargeable.dischargNodeMapping[node]
end

-- Local values: spec, raycast, x, y, z, dx, dy, dz
function Dischargeable:updateRaycast(dischargeNode)
	local v261_ = self.spec_dischargeable
	local v262_ = dischargeNode.raycast
	if v262_.node ~= nil then
		dischargeNode.lastDischargeObject = dischargeNode.dischargeObject
		dischargeNode.raycastDischargeObject = nil
		dischargeNode.raycastDischargeHitObject = nil
		dischargeNode.raycastDischargeHitObjectUnitIndex = nil
		dischargeNode.raycastDischargeHitTerrain = false
		dischargeNode.raycastDischargeShape = nil
		dischargeNode.raycastDischargeDistance = math.huge
		dischargeNode.raycastDischargeFillUnitIndex = nil
		dischargeNode.raycastDischargeHit = false
		dischargeNode.raycastDischargeFailedReason = nil
		local v263_, v264_, v265_ = getWorldTranslation(v262_.node)
		local v266_ = v264_ + v262_.yOffset
		local v267_, v268_, v269_
		if v262_.useWorldNegYDirection then
			v267_ = 0
			v268_ = 0
			v269_ = -1
		else
			v268_, v269_, v267_ = localDirectionToWorld(v262_.node, 0, -1, 0)
		end
		v261_.currentRaycastDischargeNode = dischargeNode
		v261_.currentRaycast = v262_
		v261_.isAsyncRaycastActive = true
		raycastAllAsync(v263_, v266_, v265_, v268_, v269_, v267_, dischargeNode.maxDistance, "raycastCallbackDischargeNode", self, v261_.raycastCollisionMask)
		if VehicleDebug.state == VehicleDebug.DEBUG then
			drawDebugLine(v263_, v266_, v265_, 0, 1, 0, v263_ + v268_ * dischargeNode.maxDistance, v266_ + v269_ * dischargeNode.maxDistance, v265_ + v267_ * dischargeNode.maxDistance, 0, 1, 0, true)
		end
	end
end

function Dischargeable:updateDischargeInfo(dischargeNode, x, y, z)
	if dischargeNode.info.useRaycastHitPosition then
		setWorldTranslation(dischargeNode.info.node, x, y, z)
	end
end

-- Local values: spec, dischargeNode, object, validObject, fillUnitIndex, fillType, dischargeFailedReason, dischargeFailedReasonShowAuto, customNotAllowedWarning, allowFillType, allowToolType, freeSpace, accessible
function Dischargeable:raycastCallbackDischargeNode(hitActorId, x, y, z, distance, nx, ny, nz, subShapeIndex, hitShapeId, isLast)
	if not (self.isDeleted or self.isDeleting) then
		local v282_ = self.spec_dischargeable
		local v283_ = v282_.currentRaycastDischargeNode
		if hitActorId ~= 0 then
			local v284_ = g_currentMission:getNodeObject(hitActorId)
			local v285_ = distance - v283_.raycast.yOffset
			if VehicleDebug.state == VehicleDebug.DEBUG then
				DebugGizmo.renderAtPositionSimple(x, y, z, string.format("hitActorId %d | %s; hitShape %d | %s; object %s", hitActorId, getName(hitActorId), hitShapeId, getName(hitShapeId), v284_))
			end
			local v286_
			if v284_ == nil then
				v286_ = false
			else
				v286_ = v284_ ~= self and true or v283_.canFillOwnVehicle
			end
			if v286_ and v285_ < 0 then
				if v284_.getFillUnitIndexFromNode ~= nil then
					if v286_ then
						v286_ = v284_:getFillUnitIndexFromNode(hitShapeId) ~= nil
					end
				end
				if not v283_.canDischargeToVehicle then
					if v286_ then
						v286_ = not v284_:isa(Vehicle)
					end
				end
			end
			if v286_ then
				if v284_.getFillUnitIndexFromNode ~= nil then
					local v287_ = v284_:getFillUnitIndexFromNode(hitShapeId)
					if v287_ == nil then
						if v283_.raycastDischargeHit then
							v283_.raycastDischargeDistance = v285_ + (v283_.raycastDischargeExtraDistance or 0)
							v283_.raycastDischargeExtraDistance = nil
							self:updateDischargeInfo(v283_, x, y, z)
							self:finishDischargeRaycast()
							return false
						end
					else
						local v288_ = v282_.forcedFillTypeIndex
						if v288_ == nil then
							v288_ = self:getDischargeFillType(v283_)
						end
						local v289_ = nil
						local v290_ = false
						local v291_ = nil
						if v284_:getFillUnitSupportsFillType(v287_, v288_) then
							local v292_ = v284_:getFillUnitAllowsFillType(v287_, v288_)
							local v293_ = v284_:getFillUnitSupportsToolType(v287_, v283_.toolType)
							local v294_ = v284_:getFillUnitFreeCapacity(v287_, v288_, self:getActiveFarm()) > 0
							local v295_ = v284_:getIsFillAllowedFromFarm(self:getActiveFarm())
							if v292_ and (v293_ and v294_) then
								v283_.raycastDischargeObject = v284_
								v283_.raycastDischargeShape = hitShapeId
								v283_.raycastDischargeDistance = v285_
								v283_.raycastDischargeFillUnitIndex = v287_
								if v284_.getFillUnitExtraDistanceFromNode ~= nil then
									v283_.raycastDischargeExtraDistance = v284_:getFillUnitExtraDistanceFromNode(hitShapeId)
								end
							elseif v292_ then
								if v293_ then
									if v295_ then
										if not v294_ then
											v289_ = Dischargeable.DISCHARGE_REASON_NO_FREE_CAPACITY
										end
									else
										v289_ = Dischargeable.DISCHARGE_REASON_NO_ACCESS
									end
								else
									v289_ = Dischargeable.DISCHARGE_REASON_TOOLTYPE_NOT_SUPPORTED
								end
							else
								v289_ = Dischargeable.DISCHARGE_REASON_FILLTYPE_NOT_SUPPORTED
							end
						elseif v288_ ~= FillType.UNKNOWN then
							v289_ = Dischargeable.DISCHARGE_REASON_FILLTYPE_NOT_SUPPORTED
						end
						if v289_ == Dischargeable.DISCHARGE_REASON_FILLTYPE_NOT_SUPPORTED or (v289_ == Dischargeable.DISCHARGE_REASON_NO_FREE_CAPACITY or v289_ == Dischargeable.DISCHARGE_REASON_NO_ACCESS) then
							v290_ = (v284_.isa == nil or not v284_:isa(Vehicle)) and true or v290_
						end
						if v289_ ~= nil and (v289_ ~= Dischargeable.DISCHARGE_REASON_FILLTYPE_NOT_SUPPORTED and v284_.getCustomDischargeNotAllowedWarning ~= nil) then
							v291_ = v284_:getCustomDischargeNotAllowedWarning()
						end
						if v283_.raycastDischargeObject == nil and v289_ ~= nil then
							if v283_.raycastDischargeFailedReason == nil or v289_ < v283_.raycastDischargeFailedReason then
								v283_.raycastDischargeFailedReason = v289_
								v283_.raycastDischargeFailedReasonShowAuto = v290_
								v283_.customNotAllowedWarning = v291_
							end
						else
							v283_.raycastDischargeFailedReason = nil
							v283_.raycastDischargeFailedReasonShowAuto = false
							v283_.customNotAllowedWarning = nil
						end
						v283_.raycastDischargeHit = true
						v283_.raycastDischargeHitObject = v284_
						v283_.raycastDischargeHitObjectUnitIndex = v287_
					end
				end
			elseif hitActorId == g_terrainNode then
				local v296_ = v283_.raycastDischargeDistance
				v283_.raycastDischargeDistance = math.min(v296_, v285_)
				v283_.raycastDischargeHitTerrain = true
				self:updateDischargeInfo(v283_, x, y, z)
				self:finishDischargeRaycast()
				return false
			end
		end
		if not isLast then
			return true
		end
		self:finishDischargeRaycast()
		return false
	end
end

-- Local values: spec, dischargeNode
function Dischargeable:finishDischargeRaycast()
	local v298_ = self.spec_dischargeable
	local v299_ = v298_.currentRaycastDischargeNode
	v299_.dischargeObject = v299_.raycastDischargeObject
	v299_.dischargeHitObject = v299_.raycastDischargeHitObject
	v299_.dischargeHitObjectUnitIndex = v299_.raycastDischargeHitObjectUnitIndex
	v299_.dischargeHitTerrain = v299_.raycastDischargeHitTerrain
	v299_.dischargeShape = v299_.raycastDischargeShape
	v299_.dischargeDistance = v299_.raycastDischargeDistance
	v299_.dischargeFillUnitIndex = v299_.raycastDischargeFillUnitIndex
	v299_.dischargeHit = v299_.raycastDischargeHit
	v299_.dischargeFailedReason = v299_.raycastDischargeFailedReason
	self:handleDischargeRaycast(v299_, v299_.dischargeObject, v299_.dischargeShape, v299_.dischargeDistance, v299_.dischargeFillUnitIndex, v299_.dischargeHitTerrain)
	v298_.isAsyncRaycastActive = false
	if v299_.lastDischargeObject ~= v299_.dischargeObject then
		SpecializationUtil.raiseEvent(self, "onDischargeTargetObjectChanged", v299_.dischargeObject)
		self.rootVehicle:raiseActive()
	end
end

-- Local values: spec
function Dischargeable:getDischargeNodeByIndex(index)
	return self.spec_dischargeable.dischargeNodes[index]
end

-- Local values: spec
function Dischargeable:handleDischargeOnEmpty(dischargeNode)
	if self.spec_dischargeable.currentDischargeNode.stopDischargeOnEmpty then
		self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF, true)
	end
end

function Dischargeable:handleDischargeNodeChanged() end

-- Local values: spec, canDrop
function Dischargeable:handleDischarge(dischargeNode, dischargedLiters, minDropReached, hasMinDropFillLevel)
	if self.spec_dischargeable.currentDischargeState == Dischargeable.DISCHARGE_STATE_GROUND then
		if dischargeNode.stopDischargeIfNotPossible and (dischargedLiters == 0 and ((minDropReached or not hasMinDropFillLevel) and true or false)) then
			self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF)
			return
		end
	elseif dischargeNode.stopDischargeIfNotPossible and dischargedLiters == 0 then
		self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF)
	end
end

-- Local values: spec, currentDischargeNode
function Dischargeable:handleDischargeRaycast(dischargeNode, object, shape, distance, illUnitIndex, hitTerrain)
	local v312_ = self.spec_dischargeable
	if self.isServer then
		if object == nil and v312_.currentDischargeState == Dischargeable.DISCHARGE_STATE_OBJECT then
			self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF)
		end
		if object == nil and (dischargeNode.canStartGroundDischargeAutomatically and (self:getCanDischargeToGround(dischargeNode) and (self:getCanDischargeToLand(dischargeNode) and self:getCanDischargeAtPosition(dischargeNode)))) then
			self:setDischargeState(Dischargeable.DISCHARGE_STATE_GROUND)
		end
	end
	local v313_ = v312_.currentDischargeNode
	if v313_.distanceObjectChanges ~= nil then
		ObjectChangeUtil.setObjectChanges(v313_.distanceObjectChanges, v313_.distanceObjectChangeThreshold < distance and true or v312_.currentDischargeState ~= Dischargeable.DISCHARGE_STATE_OFF, self, self.setMovingToolDirty)
	end
end

function Dischargeable:handleFoundDischargeObject(dischargeNode)
	if self:getDischargeNodeAutomaticDischarge(dischargeNode) then
		self:setDischargeState(Dischargeable.DISCHARGE_STATE_OBJECT)
	end
end

-- Local values: _, effect
function Dischargeable:setDischargeEffectDistance(dischargeNode, distance)
	if dischargeNode.isEffectActive and (dischargeNode.effects ~= nil and distance ~= math.huge) then
		for _, v318_ in pairs(dischargeNode.effects) do
			if v318_.setDistance ~= nil then
				v318_:setDistance(distance, g_terrainNode)
			end
		end
	end
end

function Dischargeable:setDischargeEffectActive(dischargeNode, isActive, force, fillTypeIndex)
	if isActive then
		if not dischargeNode.isEffectActive then
			if fillTypeIndex == nil then
				fillTypeIndex = self:getDischargeFillType(dischargeNode)
			end
			g_effectManager:setEffectTypeInfo(dischargeNode.effects, fillTypeIndex)
			g_effectManager:startEffects(dischargeNode.effects)
			g_animationManager:startAnimations(dischargeNode.effectAnimationNodes)
			dischargeNode.isEffectActive = true
		end
		dischargeNode.stopEffectTime = nil
	elseif force == nil or not force then
		if dischargeNode.stopEffectTime == nil then
			dischargeNode.stopEffectTime = g_time + dischargeNode.effectTurnOffThreshold
			self:raiseActive()
		end
	elseif dischargeNode.isEffectActive then
		g_effectManager:stopEffects(dischargeNode.effects)
		g_animationManager:stopAnimations(dischargeNode.effectAnimationNodes)
		dischargeNode.isEffectActive = false
	end
	if self.isServer and dischargeNode.isEffectActive ~= dischargeNode.isEffectActiveSent then
		self:raiseDirtyFlags(self.spec_dischargeable.dirtyFlag)
		dischargeNode.isEffectActiveSent = dischargeNode.isEffectActive
	end
end

-- Local values: fillType, isInDischargeState, isEffectActive, lastEffectVisible, effectsStillActive, sharedSample
function Dischargeable:updateDischargeSound(dischargeNode, dt)
	if self.isClient then
		local v327_ = self:getDischargeFillType(dischargeNode)
		local v328_ = self.spec_dischargeable.currentDischargeState ~= Dischargeable.DISCHARGE_STATE_OFF
		local v329_ = dischargeNode.isEffectActive
		if v329_ then
			v329_ = v327_ ~= FillType.UNKNOWN
		end
		local v330_ = dischargeNode.lastEffect == nil and true or dischargeNode.lastEffect:getIsVisible()
		local v331_
		if dischargeNode.lastEffect == nil then
			v331_ = false
		else
			v331_ = dischargeNode.lastEffect:getIsVisible()
		end
		if (v328_ and v329_ or v331_) and v330_ then
			if dischargeNode.playSound and v327_ ~= FillType.UNKNOWN then
				local v332_ = g_fillTypeManager:getSampleByFillType(v327_)
				if v332_ ~= nil then
					if v332_ == dischargeNode.sharedSample then
						if not g_soundManager:getIsSamplePlaying(dischargeNode.sample) then
							g_soundManager:playSample(dischargeNode.sample)
						end
					else
						if dischargeNode.sample ~= nil then
							g_soundManager:deleteSample(dischargeNode.sample)
						end
						dischargeNode.sample = g_soundManager:cloneSample(v332_, dischargeNode.node or dischargeNode.soundNode, self)
						dischargeNode.sharedSample = v332_
						g_soundManager:playSample(dischargeNode.sample)
					end
				end
			end
			if dischargeNode.dischargeSample ~= nil and not g_soundManager:getIsSamplePlaying(dischargeNode.dischargeSample) then
				g_soundManager:playSample(dischargeNode.dischargeSample)
			end
			dischargeNode.turnOffSoundTimer = 250
			return
		end
		if dischargeNode.turnOffSoundTimer ~= nil and dischargeNode.turnOffSoundTimer > 0 then
			dischargeNode.turnOffSoundTimer = dischargeNode.turnOffSoundTimer - dt
			if dischargeNode.turnOffSoundTimer <= 0 then
				if dischargeNode.playSound and g_soundManager:getIsSamplePlaying(dischargeNode.sample) then
					g_soundManager:stopSample(dischargeNode.sample)
				end
				if dischargeNode.dischargeSample ~= nil and g_soundManager:getIsSamplePlaying(dischargeNode.dischargeSample) then
					g_soundManager:stopSample(dischargeNode.dischargeSample)
				end
				dischargeNode.turnOffSoundTimer = 0
			end
		end
	end
end

-- Local values: spec, object, fillUnitIndex, dischargeNode, validObject, trigger
function Dischargeable:dischargeTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	local v339_ = self.spec_dischargeable
	if onEnter or onLeave then
		local v340_ = g_currentMission:getNodeObject(otherActorId)
		if v340_ ~= nil and (v340_ ~= self and v340_.getFillUnitIndexFromNode ~= nil) then
			local v341_ = v340_:getFillUnitIndexFromNode(otherShapeId)
			local v342_ = v339_.triggerToDischargeNode[triggerId]
			local v343_ = v341_ ~= nil
			if not v342_.canDischargeToVehicle then
				if v343_ then
					v343_ = not v340_:isa(Vehicle)
				end
			end
			if v342_ ~= nil and v343_ then
				local v344_ = v342_.trigger
				if onEnter then
					if v344_.objects[v340_] == nil then
						v344_.objects[v340_] = {
							["count"] = 0,
							["fillUnitIndex"] = v341_,
							["shape"] = otherShapeId
						}
						v344_.numObjects = v344_.numObjects + 1
						v340_:addDeleteListener(self, "onDeleteDischargeTriggerObject")
					end
					v344_.objects[v340_].count = v344_.objects[v340_].count + 1
					self:raiseActive()
					return
				end
				if onLeave then
					v344_.objects[v340_].count = v344_.objects[v340_].count - 1
					if v344_.objects[v340_].count == 0 then
						v344_.objects[v340_] = nil
						v344_.numObjects = v344_.numObjects - 1
						if v340_ == v342_.dischargeObject then
							v342_.dischargeObject = nil
							v342_.dischargeHitTerrain = false
							v342_.dischargeShape = nil
							v342_.dischargeDistance = 0
							v342_.dischargeFillUnitIndex = nil
						end
						v340_:removeDeleteListener(self, "onDeleteDischargeTriggerObject")
					end
				end
			end
		end
	end
end

-- Local values: spec, _, dischargeNode, trigger
function Dischargeable:onDeleteDischargeTriggerObject(object)
	local v347_ = self.spec_dischargeable
	for _, v348_ in pairs(v347_.triggerToDischargeNode) do
		local v349_ = v348_.trigger
		if object == v348_.dischargeObject then
			v348_.dischargeObject = nil
			v348_.dischargeHitTerrain = false
			v348_.dischargeShape = nil
			v348_.dischargeDistance = 0
			v348_.dischargeFillUnitIndex = nil
		end
		if v349_.objects[object] ~= nil then
			v349_.objects[object] = nil
			v349_.numObjects = v349_.numObjects - 1
		end
	end
end

-- Local values: spec, object, fillUnitIndex, dischargeNode, trigger
function Dischargeable:dischargeActivationTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	local v356_ = self.spec_dischargeable
	if onEnter or onLeave then
		local v357_ = g_currentMission:getNodeObject(otherActorId)
		if v357_ ~= nil and (v357_ ~= self and v357_.getFillUnitIndexFromNode ~= nil) then
			local v358_ = v357_:getFillUnitIndexFromNode(otherShapeId)
			local v359_ = v356_.activationTriggerToDischargeNode[triggerId]
			if v359_ ~= nil and v358_ ~= nil then
				local v360_ = v359_.activationTrigger
				if onEnter then
					if v360_.objects[v357_] == nil then
						v360_.objects[v357_] = {
							["count"] = 0,
							["fillUnitIndex"] = v358_,
							["shape"] = otherShapeId
						}
						v360_.numObjects = v360_.numObjects + 1
						v357_:addDeleteListener(self, "onDeleteActivationTriggerObject")
					end
					v360_.objects[v357_].count = v360_.objects[v357_].count + 1
					self:raiseActive()
					return
				end
				if onLeave then
					v360_.objects[v357_].count = v360_.objects[v357_].count - 1
					if v360_.objects[v357_].count == 0 then
						v360_.objects[v357_] = nil
						v360_.numObjects = v360_.numObjects - 1
						v357_:removeDeleteListener(self, "onDeleteActivationTriggerObject")
					end
				end
			end
		end
	end
end

-- Local values: spec, _, dischargeNode, trigger
function Dischargeable:onDeleteActivationTriggerObject(object)
	local v363_ = self.spec_dischargeable
	for _, v364_ in pairs(v363_.activationTriggerToDischargeNode) do
		local v365_ = v364_.activationTrigger
		if v365_.objects[object] ~= nil then
			v365_.objects[object] = nil
			v365_.numObjects = v365_.numObjects - 1
		end
	end
end

function Dischargeable:setForcedFillTypeIndex(fillTypeIndex)
	self.spec_dischargeable.forcedFillTypeIndex = fillTypeIndex
end

-- Local values: spec, _, actionEventId, _, actionEventId
function Dischargeable:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v370_ = self.spec_dischargeable
		self:clearActionEventsTable(v370_.actionEvents)
		if isActiveForInputIgnoreSelection then
			if self:getCanToggleDischargeToGround() then
				local _, v371_ = self:addPoweredActionEvent(v370_.actionEvents, InputAction.TOGGLE_TIPSTATE_GROUND, self, Dischargeable.actionEventToggleDischargeToGround, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(v371_, GS_PRIO_NORMAL)
			end
			if self:getCanToggleDischargeToObject() then
				local _, v372_ = self:addPoweredActionEvent(v370_.actionEvents, InputAction.TOGGLE_TIPSTATE, self, Dischargeable.actionEventToggleDischarging, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(v372_, GS_PRIO_VERY_HIGH)
			end
			Dischargeable.updateActionEvents(self)
		end
	end
end

-- Local values: spec, dischargeNode, fillLevel
function Dischargeable:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillType, toolType, fillPositionData, appliedDelta)
	local v375_ = self.spec_dischargeable.fillUnitDischargeNodeMapping[fillUnitIndex]
	if v375_ ~= nil and self:getFillUnitFillLevel(fillUnitIndex) == 0 then
		self:handleDischargeOnEmpty(v375_)
	end
end

-- Local values: spec
function Dischargeable:onDeactivate()
	local v377_ = self.spec_dischargeable
	if v377_.stopDischargeOnDeactivate and v377_.currentDischargeState ~= Dischargeable.DISCHARGE_STATE_OFF then
		self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF, true)
	end
end

-- Local values: spec
function Dischargeable:onStateChange(state, data)
	if state == VehicleStateChange.MOTOR_TURN_OFF and not self:getIsPowered() then
		local v380_ = self.spec_dischargeable
		if v380_.stopDischargeOnDeactivate and v380_.currentDischargeState ~= Dischargeable.DISCHARGE_STATE_OFF then
			self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF, true)
		end
	end
end

-- Local values: spec, currentDischargeNode, state, _, dischargeNode, object
function Dischargeable:updateDebugValues(values)
	local v383_ = self.spec_dischargeable
	local v384_ = v383_.currentDischargeNode
	local v385_ = v383_.currentDischargeState == Dischargeable.DISCHARGE_STATE_OBJECT and "OBJECT" or (v383_.currentDischargeState == Dischargeable.DISCHARGE_STATE_GROUND and "GROUND" or "OFF")
	table.insert(values, {
		["name"] = "state",
		["value"] = v385_
	})
	local v386_ = {
		["name"] = "getCanDischargeToObject",
		["value"] = tostring(self:getCanDischargeToObject(v384_))
	}
	table.insert(values, v386_)
	local v387_ = {
		["name"] = "getCanDischargeToGround",
		["value"] = tostring(self:getCanDischargeToGround(v384_))
	}
	table.insert(values, v387_)
	local v388_ = {
		["name"] = "dischargedLiters"
	}
	local v389_ = v383_.dischargedLiters
	v388_.value = tostring(v389_)
	table.insert(values, v388_)
	local v390_ = {
		["name"] = "currentNode",
		["value"] = tostring(v384_)
	}
	table.insert(values, v390_)
	for _, v391_ in ipairs(v383_.dischargeNodes) do
		local v392_ = {
			["name"] = "--->",
			["value"] = tostring(v391_)
		}
		table.insert(values, v392_)
		local v393_
		if v391_.dischargeObject == nil then
			v393_ = nil
		else
			local v394_ = v391_.dischargeObject.configFileName
			v393_ = tostring(v394_)
		end
		local v395_ = {
			["name"] = "object",
			["value"] = tostring(v393_)
		}
		table.insert(values, v395_)
		local v396_ = {
			["name"] = "distance",
			["value"] = v391_.dischargeDistance
		}
		table.insert(values, v396_)
		local v397_ = {
			["name"] = "effect"
		}
		local v398_ = v391_.isEffectActive
		v397_.value = tostring(v398_)
		table.insert(values, v397_)
		local v399_ = {
			["name"] = "fillLevel"
		}
		local v400_ = v391_.fillUnitIndex
		v399_.value = tostring(self:getFillUnitFillLevel(v400_))
		table.insert(values, v399_)
		local v401_ = {
			["name"] = "litersToDrop"
		}
		local v402_ = v391_.litersToDrop
		v401_.value = tostring(v402_)
		table.insert(values, v401_)
		local v403_ = {
			["name"] = "emptyFactor",
			["value"] = tostring(self:getDischargeNodeEmptyFactor(v391_))
		}
		table.insert(values, v403_)
		local v404_ = {
			["name"] = "emptySpeed",
			["value"] = tostring(self:getDischargeNodeEmptyFactor(v391_))
		}
		table.insert(values, v404_)
		local v405_ = {
			["name"] = "readyForDischarge"
		}
		local v406_ = v391_.lastEffect == nil and true or v391_.lastEffect:getIsFullyVisible()
		v405_.value = tostring(v406_)
		table.insert(values, v405_)
		local v407_ = {
			["name"] = "objectsInTrigger"
		}
		local v408_ = v391_.trigger.numObjects
		v407_.value = tostring(v408_)
		table.insert(values, v407_)
		local v409_ = {
			["name"] = "objectsInActivationTrigger"
		}
		local v410_ = v391_.activationTrigger.numObjects
		v409_.value = tostring(v410_)
		table.insert(values, v409_)
	end
end

-- Local values: spec, currentDischargeNode
function Dischargeable:actionEventToggleDischargeToGround(actionName, inputValue, callbackState, isAnalog)
	if self:getCanToggleDischargeToGround() then
		local v412_ = self.spec_dischargeable
		local v413_ = v412_.currentDischargeNode
		if v412_.currentDischargeState == Dischargeable.DISCHARGE_STATE_OFF then
			if self:getCanDischargeToGround(v413_) then
				if self:getCanDischargeToLand(v413_) then
					if self:getCanDischargeAtPosition(v413_) then
						self:setManualDischargeState(Dischargeable.DISCHARGE_STATE_GROUND)
					else
						g_currentMission:showBlinkingWarning(g_i18n:getText("warning_actionNotAllowedHere"), 5000)
					end
				else
					g_currentMission:showBlinkingWarning(g_i18n:getText("warning_youDontHaveAccessToThisLand"), 5000)
					return
				end
			end
		else
			self:setManualDischargeState(Dischargeable.DISCHARGE_STATE_OFF)
		end
	end
end

-- Local values: spec, currentDischargeNode, warning
function Dischargeable:actionEventToggleDischarging(actionName, inputValue, callbackState, isAnalog)
	if self:getCanToggleDischargeToObject() then
		local v415_ = self.spec_dischargeable
		local v416_ = v415_.currentDischargeNode
		if v415_.currentDischargeState == Dischargeable.DISCHARGE_STATE_OFF then
			if self:getCanDischargeToObject(v416_) then
				self:setManualDischargeState(Dischargeable.DISCHARGE_STATE_OBJECT)
				return
			end
			if v416_.dischargeHit and self:getDischargeFillType(v416_) ~= FillType.UNKNOWN then
				local v417_ = self:getDischargeNotAllowedWarning(v416_)
				g_currentMission:showBlinkingWarning(v417_, 5000)
				return
			end
		else
			self:setManualDischargeState(Dischargeable.DISCHARGE_STATE_OFF)
		end
	end
end

-- Local values: spec, actionEventTip, actionEventTipGround, showTip, showTipGround, currentDischargeNode
function Dischargeable:updateActionEvents()
	local v419_ = self.spec_dischargeable
	local v420_ = v419_.actionEvents[InputAction.TOGGLE_TIPSTATE]
	local v421_ = v419_.actionEvents[InputAction.TOGGLE_TIPSTATE_GROUND]
	local v422_ = false
	local v423_ = false
	if v419_.currentDischargeState == Dischargeable.DISCHARGE_STATE_OFF then
		if v420_ ~= nil or v421_ ~= nil then
			local v424_ = v419_.currentDischargeNode
			if self:getIsDischargeNodeActive(v424_) then
				if v420_ == nil or not (self:getCanDischargeToObject(v424_) and self:getCanToggleDischargeToObject()) then
					if v421_ ~= nil and (self:getCanDischargeToGround(v424_) and self:getCanToggleDischargeToGround()) then
						g_inputBinding:setActionEventText(v421_.actionEventId, g_i18n:getText("action_startTipToGround"))
						v423_ = true
					end
				else
					g_inputBinding:setActionEventText(v420_.actionEventId, g_i18n:getText("action_startOverloading"))
					v422_ = true
				end
			end
		end
	elseif v419_.currentDischargeState == Dischargeable.DISCHARGE_STATE_GROUND then
		if v421_ ~= nil then
			g_inputBinding:setActionEventText(v421_.actionEventId, g_i18n:getText("action_stopTipToGround"))
			v423_ = true
		end
	elseif v420_ ~= nil then
		g_inputBinding:setActionEventText(v420_.actionEventId, g_i18n:getText("action_stopOverloading"))
		v422_ = true
	end
	if v420_ ~= nil then
		g_inputBinding:setActionEventTextVisibility(v420_.actionEventId, v422_)
	end
	if v421_ ~= nil then
		g_inputBinding:setActionEventTextVisibility(v421_.actionEventId, v423_)
	end
end

function Dischargeable:dashboardDischargeAttributes(xmlFile, key, dashboard, isActive)
	dashboard.dischargeNodeIndex = xmlFile:getValue(key .. "#dischargeNodeIndex")
	return true
end
