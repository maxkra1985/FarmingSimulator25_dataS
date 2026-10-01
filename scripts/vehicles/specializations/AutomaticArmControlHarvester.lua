AutomaticArmControlHarvester = {}
AutomaticArmControlHarvester.STATE_NONE = 0
AutomaticArmControlHarvester.STATE_MOVE_BACK = 1
AutomaticArmControlHarvester.STATE_ALIGN_X = 2
AutomaticArmControlHarvester.STATE_ALIGN_Z = 3
AutomaticArmControlHarvester.STATE_FINISHED = 4
AutomaticArmControlHarvester.NEXT_STATE = { { [AutomaticArmControlHarvester.STATE_NONE] = AutomaticArmControlHarvester.STATE_MOVE_BACK, [AutomaticArmControlHarvester.STATE_MOVE_BACK] = AutomaticArmControlHarvester.STATE_ALIGN_X, [AutomaticArmControlHarvester.STATE_ALIGN_X] = AutomaticArmControlHarvester.STATE_ALIGN_Z, [AutomaticArmControlHarvester.STATE_ALIGN_Z] = AutomaticArmControlHarvester.STATE_FINISHED }, [-1] = { [AutomaticArmControlHarvester.STATE_NONE] = AutomaticArmControlHarvester.STATE_ALIGN_Z, [AutomaticArmControlHarvester.STATE_ALIGN_Z] = AutomaticArmControlHarvester.STATE_ALIGN_X, [AutomaticArmControlHarvester.STATE_ALIGN_X] = AutomaticArmControlHarvester.STATE_FINISHED } }
AutomaticArmControlHarvester.INVALID_REASON_NONE = 0
AutomaticArmControlHarvester.INVALID_REASON_NO_ACCESS = 1
AutomaticArmControlHarvester.INVALID_REASON_TOO_THICK = 2
AutomaticArmControlHarvester.INVALID_REASON_WRONG_TYPE = 3
function AutomaticArmControlHarvester.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Cylindered, specializations)
end
function AutomaticArmControlHarvester.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("automaticArmControlHarvester", g_i18n:getText("shop_configuration"), "automaticArmControlHarvester", VehicleConfigurationItem)
	local schema = Vehicle.xmlSchema
	schema:setXMLSpecializationType("AutomaticArmControlHarvester")
	AutomaticArmControlHarvester.registerXMLPaths(schema, "vehicle.automaticArmControlHarvester")
	AutomaticArmControlHarvester.registerXMLPaths(schema, "vehicle.automaticArmControlHarvester.automaticArmControlHarvesterConfigurations.automaticArmControlHarvesterConfiguration(?)")
	schema:setXMLSpecializationType()
end
function AutomaticArmControlHarvester.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. "#requiresEasyArmControl", "If 'true' then it is only available if easy arm control is enabled", true)
	schema:register(XMLValueType.FLOAT, basePath .. "#foldMinLimit", "Min. folding time to activate the automatic control", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#foldMaxLimit", "Max. folding time to activate the automatic control", 1)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#returnPositionNode", "This node is used as target if no tree to align has been found (only for platforms with automatic vehicle control)")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".treeDetectionNode#node", "Tree detection node")
	schema:register(XMLValueType.FLOAT, basePath .. ".treeDetectionNode#minRadius", "Min. distance to tree", 5)
	schema:register(XMLValueType.FLOAT, basePath .. ".treeDetectionNode#maxRadius", "Max. distance to tree", 10)
	schema:register(XMLValueType.ANGLE, basePath .. ".treeDetectionNode#maxAngle", "Max. angle to the target tree", 45)
	schema:register(XMLValueType.FLOAT, basePath .. ".treeDetectionNode#cutHeight", "Tree cur height measured from terrain height", 0.4)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".xAlignment#movingToolNode", "Moving tool to do alignment on X axis (most likely Y-Rot tool)")
	schema:register(XMLValueType.FLOAT, basePath .. ".xAlignment#speedScale", "Speed scale used to control the moving tool", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".xAlignment#offset", "X alignment offset from tree detection node", "Automatically calculated with the difference on X between xAlignment and zAlignment node")
	schema:register(XMLValueType.ANGLE, basePath .. ".xAlignment#threshold", "X alignment angle threshold (if angle to target is below this value the Y and Z alignment will start)", 1)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".xAlignment#referenceNode", "Reference node which should be at the top pivot point of the cutter")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".zAlignment#movingToolNode", "Moving tool to do alignment on Z axis (EasyArmControl Z Target)")
	schema:register(XMLValueType.FLOAT, basePath .. ".zAlignment#speedScale", "Speed scale used to control the moving tool", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".zAlignment#moveBackDistance", "Distance the arm is moved back behind the tree first to start the x alignment", 2)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".zAlignment#referenceNode", "Reference node which is tried to be moved right in front of the tree")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".yAlignment#movingToolNode", "Moving tool to do alignment on Y axis (EasyArmControl Y Target)")
	schema:register(XMLValueType.FLOAT, basePath .. ".yAlignment#speedScale", "Speed scale used to control the moving tool", 1)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".yAlignment#referenceNode", "Reference node which is tried to be moved right in front of the tree")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".alignmentNode(?)#movingToolNode", "MovingTool node which is aligned according to attributes")
	schema:register(XMLValueType.ANGLE, basePath .. ".alignmentNode(?)#rotation", "Target rotation")
	schema:register(XMLValueType.FLOAT, basePath .. ".alignmentNode(?)#translation", "Target translation")
	schema:register(XMLValueType.FLOAT, basePath .. ".alignmentNode(?)#speedScale", "Speed scale used to reach the target rotation/translation", 1)
	schema:register(XMLValueType.BOOL, basePath .. ".alignmentNode(?)#isPrerequisite", "Defines if this moving tool is first brought into the target position before the real alignment starts", false)
	TargetTreeMarker.registerXMLPaths(schema, basePath .. ".treeMarker")
	schema:register(XMLValueType.COLOR, basePath .. ".treeMarker#targetColor", "Color if tree is available to alignment, but not ready for cut yet", "2 2 0")
	schema:register(XMLValueType.COLOR, basePath .. ".treeMarker#tooThickColor", "Color if tree is too thick to be cut", "2 0 0")
	schema:register(XMLValueType.FLOAT, basePath .. ".treeMarker#treeOffset", "Offset from tree to marker", 0.025)
end
function AutomaticArmControlHarvester.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getSupportsAutoTreeAlignment", AutomaticArmControlHarvester.getSupportsAutoTreeAlignment)
	SpecializationUtil.registerFunction(vehicleType, "getIsAutoTreeAlignmentAllowed", AutomaticArmControlHarvester.getIsAutoTreeAlignmentAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getAutoAlignHasValidTree", AutomaticArmControlHarvester.getAutoAlignHasValidTree)
	SpecializationUtil.registerFunction(vehicleType, "getAutoAlignTreeMarkerState", AutomaticArmControlHarvester.getAutoAlignTreeMarkerState)
	SpecializationUtil.registerFunction(vehicleType, "setTreeArmAlignmentInput", AutomaticArmControlHarvester.setTreeArmAlignmentInput)
	SpecializationUtil.registerFunction(vehicleType, "doTreeArmAlignment", AutomaticArmControlHarvester.doTreeArmAlignment)
	SpecializationUtil.registerFunction(vehicleType, "getIsAutomaticAlignmentActive", AutomaticArmControlHarvester.getIsAutomaticAlignmentActive)
	SpecializationUtil.registerFunction(vehicleType, "getAutomaticAlignmentCurrentTarget", AutomaticArmControlHarvester.getAutomaticAlignmentCurrentTarget)
	SpecializationUtil.registerFunction(vehicleType, "getAutomaticAlignmentInvalidTreeReason", AutomaticArmControlHarvester.getAutomaticAlignmentInvalidTreeReason)
	SpecializationUtil.registerFunction(vehicleType, "getBestTreeToAutoAlign", AutomaticArmControlHarvester.getBestTreeToAutoAlign)
	SpecializationUtil.registerFunction(vehicleType, "onTreeAutoOverlapCallback", AutomaticArmControlHarvester.onTreeAutoOverlapCallback)
	SpecializationUtil.registerFunction(vehicleType, "getTreeAutomaticOverwrites", AutomaticArmControlHarvester.getTreeAutomaticOverwrites)
end
function AutomaticArmControlHarvester.registerOverwrittenFunctions(vehicleType) end
function AutomaticArmControlHarvester.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AutomaticArmControlHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AutomaticArmControlHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", AutomaticArmControlHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", AutomaticArmControlHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", AutomaticArmControlHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AutomaticArmControlHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", AutomaticArmControlHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onRootVehicleChanged", AutomaticArmControlHarvester)
end
function AutomaticArmControlHarvester:onLoad(savegame)
	local spec = self.spec_automaticArmControlHarvester
	local configurationId = Utils.getNoNil(self.configurations.automaticArmControlHarvester, 1)
	local configKey = string.format("vehicle.automaticArmControlHarvester.automaticArmControlHarvesterConfigurations.automaticArmControlHarvesterConfiguration(%d)", configurationId - 1)
	if not self.xmlFile:hasProperty(configKey) then
		configKey = "vehicle.automaticArmControlHarvester"
	end
	spec.alignmentNodes = {}
	self.xmlFile:iterate(configKey .. ".alignmentNode", function(index, nodeKey)
		local alignmentNode = {}
		alignmentNode.movingToolNode = self.xmlFile:getValue(nodeKey .. "#movingToolNode", nil, self.components, self.i3dMappings)
		alignmentNode.rotation = self.xmlFile:getValue(nodeKey .. "#rotation")
		alignmentNode.translation = self.xmlFile:getValue(nodeKey .. "#translation")
		if alignmentNode.movingToolNode ~= nil and (alignmentNode.rotation ~= nil or alignmentNode.translation ~= nil) then
			alignmentNode.speedScale = self.xmlFile:getValue(nodeKey .. "#speedScale", 1)
			alignmentNode.isPrerequisite = self.xmlFile:getValue(nodeKey .. "#isPrerequisite", false)
			table.insert(spec.alignmentNodes, alignmentNode)
		end
	end)
	spec.xAlignment = {}
	spec.zAlignment = {}
	spec.yAlignment = {}
	spec.treeDetectionNode = self.xmlFile:getValue(configKey .. ".treeDetectionNode#node", nil, self.components, self.i3dMappings)
	if spec.treeDetectionNode ~= nil then
		spec.treeDetectionNodeMinRadius = self.xmlFile:getValue(configKey .. ".treeDetectionNode#minRadius", 5)
		spec.treeDetectionNodeMaxRadius = self.xmlFile:getValue(configKey .. ".treeDetectionNode#maxRadius", 10)
		spec.treeDetectionNodeMaxAngle = self.xmlFile:getValue(configKey .. ".treeDetectionNode#maxAngle", 45)
		spec.treeDetectionNodeCutHeight = self.xmlFile:getValue(configKey .. ".treeDetectionNode#cutHeight", 0.4)
		spec.treeDetectionNodeCutHeightSafetyOffset = 0.075
		spec.foundTrees = {}
		spec.foundValidTargetServer = false
		spec.lastFoundValidTarget = false
		spec.lastTargetTrans = { 0, 0, 0 }
		spec.lastRadius = 1
		spec.state = AutomaticArmControlHarvester.STATE_NONE
		spec.xAlignment = {}
		spec.xAlignment.movingToolNode = self.xmlFile:getValue(configKey .. ".xAlignment#movingToolNode", nil, self.components, self.i3dMappings)
		spec.xAlignment.speedScale = self.xmlFile:getValue(configKey .. ".xAlignment#speedScale", 1)
		spec.xAlignment.offset = self.xmlFile:getValue(configKey .. ".xAlignment#offset")
		spec.xAlignment.threshold = self.xmlFile:getValue(configKey .. ".xAlignment#threshold", 1)
		spec.xAlignment.referenceNode = self.xmlFile:getValue(configKey .. ".xAlignment#referenceNode", nil, self.components, self.i3dMappings)
		spec.zAlignment = {}
		spec.zAlignment.movingToolNode = self.xmlFile:getValue(configKey .. ".zAlignment#movingToolNode", nil, self.components, self.i3dMappings)
		spec.zAlignment.speedScale = self.xmlFile:getValue(configKey .. ".zAlignment#speedScale", 1)
		spec.zAlignment.moveBackDistance = self.xmlFile:getValue(configKey .. ".zAlignment#moveBackDistance", 2)
		spec.zAlignment.referenceNode = self.xmlFile:getValue(configKey .. ".zAlignment#referenceNode", nil, self.components, self.i3dMappings)
		spec.yAlignment = {}
		spec.yAlignment.movingToolNode = self.xmlFile:getValue(configKey .. ".yAlignment#movingToolNode", nil, self.components, self.i3dMappings)
		spec.yAlignment.speedScale = self.xmlFile:getValue(configKey .. ".yAlignment#speedScale", 1)
		spec.yAlignment.referenceNode = self.xmlFile:getValue(configKey .. ".yAlignment#referenceNode", nil, self.components, self.i3dMappings)
		spec.treeMarker = TargetTreeMarker.new(self, self.rootNode)
		spec.treeMarker:loadFromXML(self.xmlFile, configKey .. ".treeMarker", self.baseDirectory)
		spec.treeMarker.cutColor = { spec.treeMarker.color[1], spec.treeMarker.color[2], spec.treeMarker.color[3] }
		spec.treeMarker.targetColor = self.xmlFile:getValue(configKey .. ".treeMarker#targetColor", "2 2 0", true)
		spec.treeMarker.tooThickColor = self.xmlFile:getValue(configKey .. ".treeMarker#tooThickColor", "2 0 0", true)
		spec.treeMarker.treeOffset = self.xmlFile:getValue(configKey .. ".treeMarker#treeOffset", 0.025)
		spec.requiresEasyArmControl = self.xmlFile:getValue(configKey .. "#requiresEasyArmControl", true)
		spec.foldMinLimit = self.xmlFile:getValue(configKey .. "#foldMinLimit", 0)
		spec.foldMaxLimit = self.xmlFile:getValue(configKey .. "#foldMaxLimit", 1)
		spec.returnPositionNode = self.xmlFile:getValue(configKey .. "#returnPositionNode", nil, self.components, self.i3dMappings)
		spec.pendingArmReturn = false
		if spec.xAlignment.offset == nil and (spec.yAlignment.referenceNode ~= nil and spec.xAlignment.movingToolNode ~= nil) then
			local offset, _, _ = localToLocal(spec.yAlignment.referenceNode, spec.xAlignment.movingToolNode, 0, 0, 0)
			spec.xAlignment.offset = -offset
		end
		spec.controlInputLastValue = 0
		spec.controlInputTimer = 0
		spec.invalidTreeReason = AutomaticArmControlHarvester.INVALID_REASON_NONE
		spec.dirtyFlag = self:getNextDirtyFlag()
		if Platform.gameplay.automaticVehicleControl then
			SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", AutomaticArmControlHarvester)
		end
	else
		spec.xAlignment.offset = self.xmlFile:getValue(configKey .. ".xAlignment#offset")
		spec.zAlignment.referenceNode = self.xmlFile:getValue(configKey .. ".zAlignment#referenceNode", nil, self.components, self.i3dMappings)
		spec.yAlignment.referenceNode = self.xmlFile:getValue(configKey .. ".yAlignment#referenceNode", nil, self.components, self.i3dMappings)
		SpecializationUtil.removeEventListener(self, "onDelete", AutomaticArmControlHarvester)
		SpecializationUtil.removeEventListener(self, "onUpdate", AutomaticArmControlHarvester)
		SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", AutomaticArmControlHarvester)
	end
end
function AutomaticArmControlHarvester:onPostLoad(savegame)
	local spec = self.spec_automaticArmControlHarvester
	if spec.xAlignment.movingToolNode ~= nil then
		spec.xAlignment.movingTool = self:getMovingToolByNode(spec.xAlignment.movingToolNode)
	end
	if spec.zAlignment.movingToolNode ~= nil then
		spec.zAlignment.movingTool = self:getMovingToolByNode(spec.zAlignment.movingToolNode)
	end
	if spec.yAlignment.movingToolNode ~= nil then
		spec.yAlignment.movingTool = self:getMovingToolByNode(spec.yAlignment.movingToolNode)
	end
	for i = #spec.alignmentNodes, 1, -1 do
		local alignmentNode = spec.alignmentNodes[i]
		alignmentNode.movingTool = self:getMovingToolByNode(alignmentNode.movingToolNode)
		if alignmentNode.movingTool == nil then
			table.remove(spec.alignmentNodes, i)
		end
	end
end
function AutomaticArmControlHarvester:onDelete()
	local spec = self.spec_automaticArmControlHarvester
	if spec.treeMarker ~= nil then
		spec.treeMarker:delete()
	end
end
function AutomaticArmControlHarvester:onReadUpdateStream(streamId, timestamp, connection)
	local spec = self.spec_automaticArmControlHarvester
	if spec.treeDetectionNode ~= nil then
		if not connection:getIsServer() then
			if streamReadBool(streamId) then
				spec.controlInputLastValue = streamReadBool(streamId) and 1 or 0
				spec.controlInputTimer = 250
			end
		elseif streamReadBool(streamId) then
			spec.foundValidTargetServer = streamReadBool(streamId)
		end
	end
end
function AutomaticArmControlHarvester:onWriteUpdateStream(streamId, connection, dirtyMask)
	local spec = self.spec_automaticArmControlHarvester
	if spec.treeDetectionNode ~= nil then
		if connection:getIsServer() then
			if streamWriteBool(streamId, bit32.band(dirtyMask, spec.dirtyFlag) ~= 0) then
				streamWriteBool(streamId, spec.controlInputLastValue ~= 0)
			end
		elseif streamWriteBool(streamId, bit32.band(dirtyMask, spec.dirtyFlag) ~= 0) then
			streamWriteBool(streamId, spec.foundValidTargetServer)
		end
	end
end
function AutomaticArmControlHarvester:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_automaticArmControlHarvester
	spec.invalidTreeReason = AutomaticArmControlHarvester.INVALID_REASON_NONE
	local foundValidTarget = false
	local hasSplitShape = false
	local hasValidRadius = false
	local showTargetMarker = false
	if self:getIsAutoTreeAlignmentAllowed() then
		local bestTreeId, invalidTreeId, invalidTreeReason = self:getBestTreeToAutoAlign(spec.treeDetectionNode, spec.foundTrees)
		if bestTreeId ~= nil then
			local wx, wy, wz = getWorldTranslation(bestTreeId)
			wy = math.max(wy, getTerrainHeightAtWorldPos(g_terrainNode, wx, wy, wz) + spec.treeDetectionNodeCutHeight + spec.treeDetectionNodeCutHeightSafetyOffset)
			local x, y, z, dx, dy, dz, radius = SplitShapeUtil.getTreeOffsetPosition(bestTreeId, wx, wy, wz, 3)
			if x ~= nil then
				spec.treeMarker:setPosition(x, y, z, dx, dy, dz, radius + spec.treeMarker.treeOffset, 0)
				hasSplitShape, hasValidRadius = self:getAutoAlignTreeMarkerState(radius)
				if hasSplitShape then
					spec.treeMarker:setColor(spec.treeMarker.cutColor[1], spec.treeMarker.cutColor[2], spec.treeMarker.cutColor[3], false)
				else
					local color = hasValidRadius and spec.treeMarker.targetColor or spec.treeMarker.tooThickColor
					if spec.state == AutomaticArmControlHarvester.STATE_NONE then
						spec.treeMarker:setColor(color[1], color[2], color[3], false)
					else
						spec.treeMarker:setColor(color[1], color[2], color[3], true)
					end
				end
				spec.lastRadius = radius
				spec.lastTargetTrans[1] = x
				spec.lastTargetTrans[2] = y
				spec.lastTargetTrans[3] = z
				foundValidTarget = true
				showTargetMarker = true
			end
		elseif invalidTreeId ~= nil then
			local wx, wy, wz = getWorldTranslation(invalidTreeId)
			wy = math.max(wy, getTerrainHeightAtWorldPos(g_terrainNode, wx, wy, wz) + spec.treeDetectionNodeCutHeight + spec.treeDetectionNodeCutHeightSafetyOffset)
			local x, y, z, dx, dy, dz, radius = SplitShapeUtil.getTreeOffsetPosition(invalidTreeId, wx, wy, wz, 3)
			if x ~= nil then
				spec.treeMarker:setPosition(x, y, z, dx, dy, dz, radius + spec.treeMarker.treeOffset, 0)
				spec.treeMarker:setColor(spec.treeMarker.tooThickColor[1], spec.treeMarker.tooThickColor[2], spec.treeMarker.tooThickColor[3], false)
				showTargetMarker = true
				spec.invalidTreeReason = invalidTreeReason
			end
		end
		for i = #spec.foundTrees, 1, -1 do
			spec.foundTrees[i] = nil
		end
		if not Platform.gameplay.automaticVehicleControl and spec.state ~= AutomaticArmControlHarvester.STATE_NONE then
			table.insert(spec.foundTrees, bestTreeId)
		end
		local x, y, z = getWorldTranslation(spec.treeDetectionNode)
		overlapSphereAsync(x, y, z, spec.treeDetectionNodeMaxRadius, "onTreeAutoOverlapCallback", self, CollisionFlag.TREE, false, false, true, false)
	end
	if self.isClient then
		local targetFound = spec.foundValidTargetServer and foundValidTarget and isActiveForInputIgnoreSelection
		if not targetFound then
			local _v234 = showTargetMarker and g_woodCuttingMarkerEnabled
		end
		spec.treeMarker:setIsActive(_v234)
		AutomaticArmControlHarvester.updateActionEvents(self, targetFound)
	end
	if self.isServer then
		if foundValidTarget ~= spec.lastFoundValidTarget then
			spec.foundValidTargetServer = foundValidTarget
			spec.lastFoundValidTarget = foundValidTarget
			self:raiseDirtyFlags(spec.dirtyFlag)
			spec.state = AutomaticArmControlHarvester.STATE_NONE
		end
		if Platform.gameplay.automaticVehicleControl then
			if self:getIsTurnedOn() then
				if foundValidTarget and spec.state ~= AutomaticArmControlHarvester.STATE_FINISHED then
					self:doTreeArmAlignment(spec.lastTargetTrans[1], spec.lastTargetTrans[2], spec.lastTargetTrans[3], 1)
				end
			elseif spec.pendingArmReturn then
				if spec.returnPositionNode ~= nil then
					local tx, ty, tz = getWorldTranslation(spec.returnPositionNode)
					self:doTreeArmAlignment(tx, ty, tz, -1)
					if spec.state == AutomaticArmControlHarvester.STATE_FINISHED then
						spec.pendingArmReturn = false
					end
				else
					spec.pendingArmReturn = false
				end
			end
		end
		if 0 < spec.controlInputTimer then
			spec.controlInputTimer = spec.controlInputTimer - dt
			if spec.controlInputTimer <= 0 then
				spec.controlInputLastValue = 0
				spec.controlInputTimer = 0
			end
			self:setTreeArmAlignmentInput(spec.controlInputLastValue)
		end
	end
end
function AutomaticArmControlHarvester:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_automaticArmControlHarvester
		self:clearActionEventsTable(spec.actionEvents)
		if isActiveForInputIgnoreSelection then
			local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.TREE_AUTOMATIC_ALIGN, self, AutomaticArmControlHarvester.actionEvent, true, false, true, true, nil)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
			AutomaticArmControlHarvester.updateActionEvents(self, false)
		end
	end
end
function AutomaticArmControlHarvester:actionEvent(actionName, inputValue, callbackState, isAnalog)
	self:setTreeArmAlignmentInput(inputValue)
end
function AutomaticArmControlHarvester:updateActionEvents(state)
	local spec = self.spec_automaticArmControlHarvester
	local actionEvent = spec.actionEvents[InputAction.TREE_AUTOMATIC_ALIGN]
	if actionEvent ~= nil then
		g_inputBinding:setActionEventActive(actionEvent.actionEventId, state)
	end
end
function AutomaticArmControlHarvester:onRootVehicleChanged(rootVehicle)
	local spec = self.spec_automaticArmControlHarvester
	local actionController = rootVehicle.actionController
	if actionController ~= nil then
		if spec.controlledAction ~= nil then
			spec.controlledAction:updateParent(actionController)
			return
		else
			spec.controlledAction = actionController:registerAction("automaticArmControlHarvester", nil, 4)
			spec.controlledAction:setCallback(self, AutomaticArmControlHarvester.actionControllerEvent)
			spec.controlledAction:setFinishedFunctions(self, function(vehicle)
				return not spec.pendingArmReturn
			end, true, true)
			spec.controlledAction:setActionIcons("WOOD_SAW", "WOOD_SAW", true)
			return
		end
	end
	if spec.controlledAction ~= nil then
		spec.controlledAction:remove()
		spec.controlledAction = nil
	end
end
function AutomaticArmControlHarvester:actionControllerEvent(direction)
	local spec = self.spec_automaticArmControlHarvester
	if direction < 0 then
		spec.pendingArmReturn = true
	end
	spec.state = AutomaticArmControlHarvester.STATE_NONE
	return true
end
function AutomaticArmControlHarvester:getSupportsAutoTreeAlignment()
	return false
end
function AutomaticArmControlHarvester:getIsAutoTreeAlignmentAllowed()
	local spec = self.spec_automaticArmControlHarvester
	if self.getIsControlled ~= nil and not self:getIsControlled() then
		return false
	end
	if spec.requiresEasyArmControl and (self.spec_cylindered.easyArmControl == nil or not self.spec_cylindered.easyArmControl.state) then
		return false
	end
	if not self:getSupportsAutoTreeAlignment() then
		local isSupported = false
		for i = 1, #self.childVehicles do
			local childVehicle = self.childVehicles[i]
			if childVehicle == self or childVehicle.getSupportsAutoTreeAlignment == nil then
				continue
			end
			if childVehicle:getSupportsAutoTreeAlignment() then
				isSupported = true
				break
			end
		end
		if not isSupported then
			return false
		end
	end
	if self.getFoldAnimTime ~= nil then
		local time = self:getFoldAnimTime()
		if time < spec.foldMinLimit or spec.foldMaxLimit < time then
			return false
		end
	end
	return true
end
function AutomaticArmControlHarvester:getAutoAlignHasValidTree(radius)
	return false, false
end
function AutomaticArmControlHarvester:getAutoAlignTreeMarkerState(foundRadius, checkChildren)
	local splitShapeFound, hasValidRadius = self:getAutoAlignHasValidTree(foundRadius)
	if splitShapeFound then
		return splitShapeFound, hasValidRadius
	else
		if checkChildren ~= false then
			for i = 1, #self.childVehicles do
				local childVehicle = self.childVehicles[i]
				if childVehicle == self or childVehicle.getAutoAlignTreeMarkerState == nil then
					continue
				end
				local _splitShapeFound, _hasValidRadius = childVehicle:getAutoAlignTreeMarkerState(foundRadius, false)
				if _splitShapeFound then
					return _splitShapeFound, _hasValidRadius
				end
				hasValidRadius = hasValidRadius or _hasValidRadius
			end
		end
		return false, hasValidRadius
	end
end
function AutomaticArmControlHarvester:setTreeArmAlignmentInput(inputValue)
	local spec = self.spec_automaticArmControlHarvester
	if self.isServer then
		if 0 < inputValue and (spec.state ~= AutomaticArmControlHarvester.STATE_FINISHED and spec.foundValidTargetServer) then
			self:doTreeArmAlignment(spec.lastTargetTrans[1], spec.lastTargetTrans[2], spec.lastTargetTrans[3], 1)
			return
		end
		if inputValue == 0 then
			spec.state = AutomaticArmControlHarvester.STATE_NONE
		end
	else
		spec.controlInputLastValue = inputValue
		if 0 < inputValue then
			self:raiseDirtyFlags(spec.dirtyFlag)
		end
	end
end
function AutomaticArmControlHarvester:doTreeArmAlignment(tx, ty, tz, direction)
	local spec = self.spec_automaticArmControlHarvester
	if not AutomaticArmControlHarvester.prepareAlignment(self, direction) then
		return
	else
		if spec.state == AutomaticArmControlHarvester.STATE_NONE then
			spec.state = AutomaticArmControlHarvester.NEXT_STATE[direction][spec.state]
		end
		local zAlignmentReferenceNode = spec.zAlignment.referenceNode
		local yAlignmentReferenceNode = spec.yAlignment.referenceNode
		local xAlignmentOffset = spec.xAlignment.offset or 0
		for i = 1, #self.childVehicles do
			local childVehicle = self.childVehicles[i]
			if childVehicle == self or childVehicle.getTreeAutomaticOverwrites == nil then
				continue
			end
			if not AutomaticArmControlHarvester.prepareAlignment(childVehicle, direction) then
				return
			end
			local _zAlignmentReferenceNode, _yAlignmentReferenceNode, _xAlignmentOffset = childVehicle:getTreeAutomaticOverwrites()
			zAlignmentReferenceNode = zAlignmentReferenceNode or _zAlignmentReferenceNode
			yAlignmentReferenceNode = yAlignmentReferenceNode or _yAlignmentReferenceNode
			if _xAlignmentOffset == nil then
				continue
			end
			xAlignmentOffset = xAlignmentOffset + _xAlignmentOffset
		end
		if spec.xAlignment.movingTool ~= nil and (spec.state ~= AutomaticArmControlHarvester.STATE_FINISHED and spec.state ~= AutomaticArmControlHarvester.STATE_MOVE_BACK) then
			local _ = 0
			local yOffset = 0
			if spec.xAlignment.referenceNode ~= nil then
				_, yOffset, _ = localToLocal(spec.xAlignment.referenceNode, spec.xAlignment.movingTool.node, 0, 0, 0)
			end
			local x, y, z = worldToLocal(spec.xAlignment.movingTool.node, tx, ty, tz)
			local dx, dy, dz = worldDirectionToLocal(spec.xAlignment.movingTool.node, 0, 1, 0)
			local length = nil
			length = 0.001 < math.abs(dy) and y / dy - yOffset or -yOffset
			local ltx = x - dx * length
			local lty = y - dy * length
			local ltz = z - dz * length
			local distance = MathUtil.vector2Length(ltx, ltz)
			local angle = math.atan((ltx + (xAlignmentOffset or 0)) / distance) * spec.xAlignment.speedScale
			local curRot = spec.xAlignment.movingTool.curRot[spec.xAlignment.movingTool.rotationAxis]
			local move = AutomaticArmControlHarvester.calculateMovingToolTargetMove(self, spec.xAlignment.movingTool, curRot + angle)
			if move ~= 0 then
				spec.xAlignment.movingTool.externalMove = move
			elseif math.abs(angle) < spec.xAlignment.threshold then
				if spec.state == AutomaticArmControlHarvester.STATE_ALIGN_X then
					spec.state = AutomaticArmControlHarvester.NEXT_STATE[direction][spec.state]
				end
			end
		end
		if spec.zAlignment.movingTool ~= nil and zAlignmentReferenceNode ~= nil then
			local _, _, lz = worldToLocal(spec.treeDetectionNode, tx, ty, tz)
			local _, _, targetZ = localToLocal(zAlignmentReferenceNode, spec.treeDetectionNode, 0, 0, 0)
			local offset = 0
			if spec.state == AutomaticArmControlHarvester.STATE_MOVE_BACK then
				offset = targetZ - (lz - spec.lastRadius - spec.zAlignment.moveBackDistance)
				if offset < spec.zAlignment.moveBackDistance * 0.5 then
					spec.state = AutomaticArmControlHarvester.NEXT_STATE[direction][spec.state]
				end
			elseif spec.state == AutomaticArmControlHarvester.STATE_ALIGN_Z then
				offset = targetZ - (lz - spec.lastRadius)
				if math.abs(offset) < 0.03 then
					spec.state = AutomaticArmControlHarvester.NEXT_STATE[direction][spec.state]
				end
			end
			if 0.03 < math.abs(offset) then
				spec.zAlignment.movingTool.externalMove = -(offset + 0.5 * math.sign(offset)) * spec.zAlignment.speedScale
			else
				spec.zAlignment.movingTool.externalMove = 0
			end
		end
		if spec.yAlignment.movingTool ~= nil and (yAlignmentReferenceNode ~= nil and spec.state == AutomaticArmControlHarvester.STATE_ALIGN_Z) then
			local curX, curY, curZ = getWorldTranslation(yAlignmentReferenceNode)
			local th = getTerrainHeightAtWorldPos(g_terrainNode, curX, curY, curZ)
			ty = ty - spec.treeDetectionNodeCutHeightSafetyOffset
			ty = math.max(ty, th + spec.treeDetectionNodeCutHeight)
			local offset = ty - curY
			if 0.03 < math.abs(offset) then
				spec.yAlignment.movingTool.externalMove = (offset + 0.5 * math.sign(offset)) * spec.yAlignment.speedScale
				return
			end
			spec.yAlignment.movingTool.externalMove = 0
		end
	end
end
function AutomaticArmControlHarvester:calculateMovingToolTargetMove(movingTool, targetRot)
	local durationToStop = movingTool.lastRotSpeed / movingTool.rotAcceleration
	local rotSpeed = movingTool.lastRotSpeed
	local stopRot = movingTool.curRot[movingTool.rotationAxis]
	local deceleration = -movingTool.rotAcceleration * math.sign(durationToStop)
	for _ = 1, math.abs(durationToStop) do
		rotSpeed = rotSpeed + deceleration
		stopRot = stopRot + rotSpeed
	end
	local threshold = 0.001
	local state = nil
	local stopState = nil
	local targetState = nil
	if movingTool.rotMin ~= nil then
		if movingTool.rotMax ~= nil then
			state = Cylindered.getMovingToolState(self, movingTool)
			stopState = MathUtil.inverseLerp(movingTool.rotMin, movingTool.rotMax, stopRot)
			targetState = MathUtil.inverseLerp(movingTool.rotMin, movingTool.rotMax, targetRot)
		else
			local curRot = movingTool.curRot[movingTool.rotationAxis]
			curRot = MathUtil.normalizeRotationForShortestPath(curRot, targetRot)
			stopRot = MathUtil.normalizeRotationForShortestPath(stopRot, targetRot)
			state = curRot
			stopState = stopRot
			targetState = targetRot
			threshold = 0.0001
		end
	end
	local move = nil
	if targetState < state then
		move = -math.sign(movingTool.rotSpeed)
		if stopState < targetState then
			return 0
		end
	else
		move = math.sign(movingTool.rotSpeed)
		if targetState < stopState then
			return 0
		end
	end
	local offset = targetState - state
	if math.abs(offset) < threshold then
		return 0
	else
		return move
	end
end
function AutomaticArmControlHarvester:prepareAlignment(direction)
	local spec = self.spec_automaticArmControlHarvester
	if direction == 1 then
		if self.getIsTurnedOn ~= nil and (not self:getIsTurnedOn() and self:getCanBeTurnedOn()) then
			self:setIsTurnedOn(true)
		end
		local spec_woodHarvester = self.spec_woodHarvester
		if spec_woodHarvester ~= nil and (spec_woodHarvester.headerJointTilt ~= nil and spec_woodHarvester.headerJointTilt.state) then
			self:setWoodHarvesterTiltState(false)
		end
	end
	for i = 1, #spec.alignmentNodes do
		local alignmentNode = spec.alignmentNodes[i]
		local move = 0
		if alignmentNode.rotation ~= nil then
			move = AutomaticArmControlHarvester.calculateMovingToolTargetMove(self, alignmentNode.movingTool, alignmentNode.rotation)
		end
		if move == 0 then
			continue
		end
		alignmentNode.movingTool.externalMove = move
		if alignmentNode.isPrerequisite then
			return false
		end
	end
	return true
end
function AutomaticArmControlHarvester:getIsAutomaticAlignmentActive()
	local spec = self.spec_automaticArmControlHarvester
	local _v9 = false
	if spec.state ~= AutomaticArmControlHarvester.STATE_NONE then
		_v9 = spec.state ~= AutomaticArmControlHarvester.STATE_FINISHED
	end
	return _v9
end
function AutomaticArmControlHarvester:getAutomaticAlignmentCurrentTarget()
	local spec = self.spec_automaticArmControlHarvester
	if spec.lastFoundValidTarget then
		return spec.lastTargetTrans[1], spec.lastTargetTrans[2], spec.lastTargetTrans[3], spec.lastRadius
	else
		return nil, nil, nil, nil
	end
end
function AutomaticArmControlHarvester:getAutomaticAlignmentInvalidTreeReason()
	return self.spec_automaticArmControlHarvester.invalidTreeReason
end
function AutomaticArmControlHarvester:getBestTreeToAutoAlign(referenceNode, trees)
	local minFactor = math.huge
	local minFactorTreeId = nil
	local invalidTreeId = nil
	local invalidTreeReason = nil
	for i = 1, #trees do
		local treeId = trees[i]
		if entityExists(treeId) and (getRigidBodyType(treeId) == RigidBodyType.STATIC and getHasClassId(treeId, ClassIds.MESH_SPLIT_SHAPE)) then
			if getIsSplitShapeSplit(treeId) then
				continue
			end
			local distance = calcDistanceFrom(referenceNode, treeId)
			local x, _, z = localToLocal(treeId, referenceNode, 0, 0, 0)
			x, z = MathUtil.vector2Normalize(x, z)
			local angle = MathUtil.getYRotationFromDirection(x, z)
			if math.abs(angle) < self.spec_automaticArmControlHarvester.treeDetectionNodeMaxAngle then
				if g_splitShapeManager:getSplitShapeAllowsHarvester(treeId) then
					local wx, _, wz = getWorldTranslation(treeId)
					if WoodHarvester.getCanSplitShapeBeAccessed(self, wx, wz, treeId) then
						local factor = math.abs(math.deg(angle)) + distance * 2
						if factor < minFactor then
							minFactor = factor
							minFactorTreeId = treeId
						end
					else
						invalidTreeId = treeId
						invalidTreeReason = AutomaticArmControlHarvester.INVALID_REASON_NO_ACCESS
					end
				else
					invalidTreeId = treeId
					invalidTreeReason = AutomaticArmControlHarvester.INVALID_REASON_WRONG_TYPE
				end
			end
		end
	end
	return minFactorTreeId, invalidTreeId, invalidTreeReason
end
function AutomaticArmControlHarvester:onTreeAutoOverlapCallback(objectId, ...)
	if not self.isDeleted and (objectId ~= 0 and (getHasClassId(objectId, ClassIds.SHAPE) and getUserAttribute(objectId, "isTreeStump") ~= true)) then
		local splitType = g_splitShapeManager:getSplitTypeByIndex(getSplitType(objectId))
		if splitType ~= nil then
			local spec = self.spec_automaticArmControlHarvester
			local x1, _, z1 = getWorldTranslation(spec.treeDetectionNode)
			local x2, _, z2 = getWorldTranslation(objectId)
			local distance = MathUtil.vector2Length(x1 - x2, z1 - z2)
			if spec.treeDetectionNodeMinRadius < distance and distance < spec.treeDetectionNodeMaxRadius then
				table.insert(spec.foundTrees, objectId)
			end
		end
	end
end
function AutomaticArmControlHarvester:getTreeAutomaticOverwrites()
	local spec = self.spec_automaticArmControlHarvester
	return spec.zAlignment.referenceNode, spec.yAlignment.referenceNode, spec.xAlignment.offset
end
function AutomaticArmControlHarvester.drawDebugCircleRange(node, radius, steps, minRot, maxRot)
	local ox = 0
	local oy = 0
	local oz = 0
	local range = maxRot - minRot
	for i = 1, steps do
		local a1 = 1.5707963267948966 + minRot + (i - 1) / steps * range
		local a2 = 1.5707963267948966 + minRot + i / steps * range
		local c = math.cos(a1) * radius
		local s = math.sin(a1) * radius
		local x1, y1, z1 = localToWorld(node, ox + c, 0, oz + s)
		c = math.cos(a2) * radius
		s = math.sin(a2) * radius
		local x2, y2, z2 = localToWorld(node, ox + c, 0, oz + s)
		drawDebugLine(x1, y1, z1, 1, 0, 0, x2, y2, z2, 1, 0, 0)
	end
end
