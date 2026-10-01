AutomaticArmControlForwarder = {}
AutomaticArmControlForwarder.STATE_NONE = 0
AutomaticArmControlForwarder.STATE_MOVE_UP = 1
AutomaticArmControlForwarder.STATE_ALIGN_X = 2
AutomaticArmControlForwarder.STATE_ALIGN_Z = 3
AutomaticArmControlForwarder.STATE_ALIGN_Y = 4
AutomaticArmControlForwarder.STATE_FINISHED = 5
AutomaticArmControlForwarder.NEXT_STATE = { [AutomaticArmControlForwarder.STATE_MOVE_UP] = AutomaticArmControlForwarder.STATE_ALIGN_X, [AutomaticArmControlForwarder.STATE_ALIGN_X] = AutomaticArmControlForwarder.STATE_ALIGN_Z, [AutomaticArmControlForwarder.STATE_ALIGN_Z] = AutomaticArmControlForwarder.STATE_ALIGN_Y, [AutomaticArmControlForwarder.STATE_ALIGN_Y] = AutomaticArmControlForwarder.STATE_FINISHED }
function AutomaticArmControlForwarder.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Cylindered, specializations)
end
function AutomaticArmControlForwarder.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("automaticArmControlForwarder", g_i18n:getText("shop_configuration"), "automaticArmControlForwarder", VehicleConfigurationItem)
	local schema = Vehicle.xmlSchema
	schema:setXMLSpecializationType("AutomaticArmControlForwarder")
	AutomaticArmControlForwarder.registerXMLPaths(schema, "vehicle.automaticArmControlForwarder")
	AutomaticArmControlForwarder.registerXMLPaths(schema, "vehicle.automaticArmControlForwarder.automaticArmControlForwarderConfigurations.automaticArmControlForwarderConfiguration(?)")
	schema:setXMLSpecializationType()
end
function AutomaticArmControlForwarder.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. "#requiresEasyArmControl", "If 'true' then it is only available if easy arm control is enabled", true)
	schema:register(XMLValueType.FLOAT, basePath .. "#foldMinLimit", "Min. folding time to activate the automatic control", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#foldMaxLimit", "Max. folding time to activate the automatic control", 1)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#rootNode", "Root reference node (placed inside the X alignment arm with Z facing in working direction)")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".treeTrigger(?)#node", "Tree detection trigger")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".xAlignment#movingToolNode", "Moving tool to do alignment on X axis (most likely Y-Rot tool)")
	schema:register(XMLValueType.FLOAT, basePath .. ".xAlignment#speedScale", "Speed scale used to control the moving tool", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".xAlignment#offset", "X alignment offset from tree detection node", "Automatically calculated with the difference on X between xAlignment and zAlignment node")
	schema:register(XMLValueType.ANGLE, basePath .. ".xAlignment#threshold", "X alignment angle threshold (if angle to target is below this value the Y and Z alignment will start)", 1)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".zAlignment#movingToolNode", "Moving tool to do alignment on Z axis (EasyArmControl Z Target)")
	schema:register(XMLValueType.FLOAT, basePath .. ".zAlignment#speedScale", "Speed scale used to control the moving tool", 1)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".zAlignment#referenceNode", "Reference node which is tried to be moved right in front of the tree")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".yAlignment#movingToolNode", "Moving tool to do alignment on Y axis (EasyArmControl Y Target)")
	schema:register(XMLValueType.FLOAT, basePath .. ".yAlignment#speedScale", "Speed scale used to control the moving tool", 1)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".yAlignment#referenceNode", "Reference node which is tried to be moved right in front of the tree")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".yAlignment.moveUp#referenceNode", "Reference node for the height before X alignment is performed")
	schema:register(XMLValueType.FLOAT, basePath .. ".yAlignment.moveUp#maxOffset", "Max. X offset from the reference node to move up the crane before rotating it out (also the min. x offset when moving the crane in)")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".xToolAlignment#movingToolNode", "Moving tool to do alignment on X axis (most likely Y-Rot tool)")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".xToolAlignment#referenceNode", "Reference node for angle offset calculation (needs to be inside the moving tool)")
	schema:register(XMLValueType.FLOAT, basePath .. ".xToolAlignment#speedScale", "Speed scale used to control the moving tool", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".xToolAlignment#offset", "X alignment offset from tree detection node", "Automatically calculated with the difference on X between xAlignment and zAlignment node")
	schema:register(XMLValueType.ANGLE, basePath .. ".xToolAlignment#threshold", "X alignment angle threshold (if angle to target is below this value the Y and Z alignment will start)", 1)
	TargetTreeMarker.registerXMLPaths(schema, basePath .. ".treeMarker")
	schema:register(XMLValueType.COLOR, basePath .. ".treeMarker#targetColor", "Color of tree is available to alignment, but not ready for cut yet", "2 2 0")
	schema:register(XMLValueType.COLOR, basePath .. ".treeMarker#tooThickColor", "Color of tree is too thick to be cut", "2 0 0")
end
function AutomaticArmControlForwarder.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getIsAutoTreeAlignmentAllowed", AutomaticArmControlForwarder.getIsAutoTreeAlignmentAllowed)
	SpecializationUtil.registerFunction(vehicleType, "setTreeArmAlignmentInput", AutomaticArmControlForwarder.setTreeArmAlignmentInput)
	SpecializationUtil.registerFunction(vehicleType, "doTreeArmAlignment", AutomaticArmControlForwarder.doTreeArmAlignment)
	SpecializationUtil.registerFunction(vehicleType, "resetAutomaticAlignment", AutomaticArmControlForwarder.resetAutomaticAlignment)
	SpecializationUtil.registerFunction(vehicleType, "getIsAutomaticAlignmentActive", AutomaticArmControlForwarder.getIsAutomaticAlignmentActive)
	SpecializationUtil.registerFunction(vehicleType, "getIsAutomaticAlignmentFinished", AutomaticArmControlForwarder.getIsAutomaticAlignmentFinished)
	SpecializationUtil.registerFunction(vehicleType, "getAutomaticAlignmentTargetTree", AutomaticArmControlForwarder.getAutomaticAlignmentTargetTree)
	SpecializationUtil.registerFunction(vehicleType, "getAutomaticAlignmentAvailableTargetTree", AutomaticArmControlForwarder.getAutomaticAlignmentAvailableTargetTree)
	SpecializationUtil.registerFunction(vehicleType, "getAutomaticAlignmentCurrentTarget", AutomaticArmControlForwarder.getAutomaticAlignmentCurrentTarget)
	SpecializationUtil.registerFunction(vehicleType, "getBestTreeToAutoAlign", AutomaticArmControlForwarder.getBestTreeToAutoAlign)
	SpecializationUtil.registerFunction(vehicleType, "onTreeAutoTriggerCallback", AutomaticArmControlForwarder.onTreeAutoTriggerCallback)
end
function AutomaticArmControlForwarder.registerOverwrittenFunctions(vehicleType) end
function AutomaticArmControlForwarder.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AutomaticArmControlForwarder)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AutomaticArmControlForwarder)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", AutomaticArmControlForwarder)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", AutomaticArmControlForwarder)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", AutomaticArmControlForwarder)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AutomaticArmControlForwarder)
	SpecializationUtil.registerEventListener(vehicleType, "onAutoLoadForwaderMountedTree", AutomaticArmControlForwarder)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", AutomaticArmControlForwarder)
end
function AutomaticArmControlForwarder:onLoad(savegame)
	local spec = self.spec_automaticArmControlForwarder
	local configurationId = Utils.getNoNil(self.configurations.automaticArmControlForwarder, 1)
	local configKey = string.format("vehicle.automaticArmControlForwarder.automaticArmControlForwarderConfigurations.automaticArmControlForwarderConfiguration(%d)", configurationId - 1)
	if not self.xmlFile:hasProperty(configKey) then
		configKey = "vehicle.automaticArmControlForwarder"
	end
	spec.xAlignment = {}
	spec.zAlignment = {}
	spec.yAlignment = {}
	spec.xToolAlignment = {}
	spec.rootNode = self.xmlFile:getValue(configKey .. "#rootNode", nil, self.components, self.i3dMappings)
	if spec.rootNode ~= nil then
		spec.treeTriggers = {}
		self.xmlFile:iterate(configKey .. ".treeTrigger", function(index, key)
			local triggerNode = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
			if triggerNode ~= nil then
				addTrigger(triggerNode, "onTreeAutoTriggerCallback", self)
				table.insert(spec.treeTriggers, triggerNode)
			end
		end)
		spec.foundTrees = {}
		spec.foundValidTargetServer = false
		spec.lastFoundValidTarget = false
		spec.lastTargetRadius = 1
		spec.lastTargetTrans = { 0, 0, 0 }
		spec.lastTargetDirection = { 0, 0, 1 }
		spec.lastTreeId = nil
		spec.state = AutomaticArmControlForwarder.STATE_NONE
		spec.xAlignment = {}
		spec.xAlignment.movingToolNode = self.xmlFile:getValue(configKey .. ".xAlignment#movingToolNode", nil, self.components, self.i3dMappings)
		spec.xAlignment.speedScale = self.xmlFile:getValue(configKey .. ".xAlignment#speedScale", 1)
		spec.xAlignment.offset = self.xmlFile:getValue(configKey .. ".xAlignment#offset")
		spec.xAlignment.threshold = self.xmlFile:getValue(configKey .. ".xAlignment#threshold", 1)
		spec.zAlignment = {}
		spec.zAlignment.movingToolNode = self.xmlFile:getValue(configKey .. ".zAlignment#movingToolNode", nil, self.components, self.i3dMappings)
		spec.zAlignment.speedScale = self.xmlFile:getValue(configKey .. ".zAlignment#speedScale", 1)
		spec.zAlignment.referenceNode = self.xmlFile:getValue(configKey .. ".zAlignment#referenceNode", nil, self.components, self.i3dMappings)
		spec.yAlignment = {}
		spec.yAlignment.movingToolNode = self.xmlFile:getValue(configKey .. ".yAlignment#movingToolNode", nil, self.components, self.i3dMappings)
		spec.yAlignment.speedScale = self.xmlFile:getValue(configKey .. ".yAlignment#speedScale", 1)
		spec.yAlignment.referenceNode = self.xmlFile:getValue(configKey .. ".yAlignment#referenceNode", nil, self.components, self.i3dMappings)
		spec.yAlignment.upReferenceNode = self.xmlFile:getValue(configKey .. ".yAlignment.moveUp#referenceNode", nil, self.components, self.i3dMappings)
		spec.yAlignment.upMaxOffset = self.xmlFile:getValue(configKey .. ".yAlignment.moveUp#maxOffset", 2)
		spec.xToolAlignment = {}
		spec.xToolAlignment.movingToolNode = self.xmlFile:getValue(configKey .. ".xToolAlignment#movingToolNode", nil, self.components, self.i3dMappings)
		spec.xToolAlignment.referenceNode = self.xmlFile:getValue(configKey .. ".xToolAlignment#referenceNode", nil, self.components, self.i3dMappings)
		spec.xToolAlignment.speedScale = self.xmlFile:getValue(configKey .. ".xToolAlignment#speedScale", 1)
		spec.xToolAlignment.offset = self.xmlFile:getValue(configKey .. ".xToolAlignment#offset")
		spec.xToolAlignment.threshold = self.xmlFile:getValue(configKey .. ".xToolAlignment#threshold", 1)
		spec.treeMarker = TargetTreeMarker.new(self, self.rootNode)
		spec.treeMarker:loadFromXML(self.xmlFile, configKey .. ".treeMarker", self.baseDirectory)
		spec.treeMarker.cutColor = { spec.treeMarker.color[1], spec.treeMarker.color[2], spec.treeMarker.color[3] }
		spec.treeMarker.targetColor = self.xmlFile:getValue(configKey .. ".treeMarker#targetColor", "2 2 0", true)
		spec.treeMarker.tooThickColor = self.xmlFile:getValue(configKey .. ".treeMarker#tooThickColor", "2 0 0", true)
		spec.requiresEasyArmControl = self.xmlFile:getValue(configKey .. "#requiresEasyArmControl", true)
		spec.foldMinLimit = self.xmlFile:getValue(configKey .. "#foldMinLimit", 0)
		spec.foldMaxLimit = self.xmlFile:getValue(configKey .. "#foldMaxLimit", 1)
		if spec.xAlignment.offset == nil and (spec.yAlignment.referenceNode ~= nil and spec.xAlignment.movingToolNode ~= nil) then
			local offset, _, _ = localToLocal(spec.yAlignment.referenceNode, spec.xAlignment.movingToolNode, 0, 0, 0)
			spec.xAlignment.offset = -offset
		end
		spec.controlInputLastValue = 0
		spec.controlInputTimer = 0
		spec.dirtyFlag = self:getNextDirtyFlag()
		if Platform.gameplay.automaticVehicleControl then
			SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", AutomaticArmControlForwarder)
		end
	else
		SpecializationUtil.removeEventListener(self, "onDelete", AutomaticArmControlForwarder)
		SpecializationUtil.removeEventListener(self, "onUpdate", AutomaticArmControlForwarder)
		SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", AutomaticArmControlForwarder)
	end
end
function AutomaticArmControlForwarder:onPostLoad(savegame)
	local spec = self.spec_automaticArmControlForwarder
	if spec.xAlignment.movingToolNode ~= nil then
		spec.xAlignment.movingTool = self:getMovingToolByNode(spec.xAlignment.movingToolNode)
	end
	if spec.zAlignment.movingToolNode ~= nil then
		spec.zAlignment.movingTool = self:getMovingToolByNode(spec.zAlignment.movingToolNode)
	end
	if spec.yAlignment.movingToolNode ~= nil then
		spec.yAlignment.movingTool = self:getMovingToolByNode(spec.yAlignment.movingToolNode)
	end
	if spec.xToolAlignment.movingToolNode ~= nil then
		spec.xToolAlignment.movingTool = self:getMovingToolByNode(spec.xToolAlignment.movingToolNode)
	end
end
function AutomaticArmControlForwarder:onDelete()
	local spec = self.spec_automaticArmControlForwarder
	if spec.treeMarker ~= nil then
		spec.treeMarker:delete()
	end
	if spec.treeTriggers ~= nil then
		for i = 1, #spec.treeTriggers do
			removeTrigger(spec.treeTriggers[i])
		end
		spec.treeTriggers = nil
	end
end
function AutomaticArmControlForwarder:onReadUpdateStream(streamId, timestamp, connection)
	local spec = self.spec_automaticArmControlForwarder
	if spec.rootNode ~= nil then
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
function AutomaticArmControlForwarder:onWriteUpdateStream(streamId, connection, dirtyMask)
	local spec = self.spec_automaticArmControlForwarder
	if spec.rootNode ~= nil then
		if connection:getIsServer() then
			if streamWriteBool(streamId, bit32.band(dirtyMask, spec.dirtyFlag) ~= 0) then
				streamWriteBool(streamId, spec.controlInputLastValue ~= 0)
			end
		elseif streamWriteBool(streamId, bit32.band(dirtyMask, spec.dirtyFlag) ~= 0) then
			streamWriteBool(streamId, spec.foundValidTargetServer)
		end
	end
end
function AutomaticArmControlForwarder:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_automaticArmControlForwarder
	local foundValidTarget = false
	if self:getIsAutoTreeAlignmentAllowed() then
		local bestTreeId = spec.lastTreeId
		if spec.state == AutomaticArmControlForwarder.STATE_NONE or spec.state == AutomaticArmControlForwarder.STATE_FINISHED then
			bestTreeId = self:getBestTreeToAutoAlign(spec.rootNode, spec.foundTrees)
		else
			if spec.foundTrees[bestTreeId] == nil then
				bestTreeId = nil
			end
		end
		if bestTreeId ~= nil then
			if entityExists(bestTreeId) then
				local wx = nil
				local wy = nil
				local wz = nil
				local dx = nil
				local dy = nil
				local dz = nil
				local radius = nil
				local treeObject = g_currentMission:getNodeObject(bestTreeId)
				if treeObject ~= nil then
					wx, wy, wz = getWorldTranslation(bestTreeId)
					dx, dy, dz = localDirectionToWorld(bestTreeId, 0, 0, 1)
					radius = getUserAttribute(bestTreeId, "logRadius") or 0.5
				else
					wx, wy, wz = getWorldTranslation(bestTreeId)
					wx, wy, wz, dx, dy, dz, radius = SplitShapeUtil.getTreeOffsetPosition(bestTreeId, wx, wy, wz, 3)
				end
				if wx ~= nil then
					spec.lastTreeId = bestTreeId
					spec.lastTargetRadius = radius
					spec.lastTargetTrans[1] = wx
					spec.lastTargetTrans[2] = wy
					spec.lastTargetTrans[3] = wz
					spec.lastTargetDirection[1] = dx
					spec.lastTargetDirection[2] = dy
					spec.lastTargetDirection[3] = dz
					foundValidTarget = true
				else
					spec.lastTreeId = nil
				end
			else
				spec.lastTreeId = nil
			end
		end
	else
		spec.lastTreeId = nil
	end
	if self.isClient then
		local targetFound = spec.foundValidTargetServer and foundValidTarget and isActiveForInputIgnoreSelection
		spec.treeMarker:setIsActive(targetFound)
		if targetFound then
			spec.treeMarker:setPosition(spec.lastTargetTrans[1], spec.lastTargetTrans[2], spec.lastTargetTrans[3], spec.lastTargetDirection[1], spec.lastTargetDirection[2], spec.lastTargetDirection[3], spec.lastTargetRadius + 0.005)
		end
		AutomaticArmControlForwarder.updateActionEvents(self, targetFound)
	end
	if self.isServer then
		if foundValidTarget ~= spec.lastFoundValidTarget then
			spec.foundValidTargetServer = foundValidTarget
			spec.lastFoundValidTarget = foundValidTarget
			self:raiseDirtyFlags(spec.dirtyFlag)
			spec.state = AutomaticArmControlForwarder.STATE_NONE
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
function AutomaticArmControlForwarder:onAutoLoadForwaderMountedTree(treeNodeId)
	local spec = self.spec_automaticArmControlForwarder
	spec.foundTrees[treeNodeId] = nil
end
function AutomaticArmControlForwarder:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_automaticArmControlForwarder
		self:clearActionEventsTable(spec.actionEvents)
		if isActiveForInputIgnoreSelection then
			local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.TREE_AUTOMATIC_ALIGN, self, AutomaticArmControlForwarder.actionEvent, true, false, true, true, nil)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
			AutomaticArmControlForwarder.updateActionEvents(self, false)
		end
	end
end
function AutomaticArmControlForwarder:actionEvent(actionName, inputValue, callbackState, isAnalog)
	self:setTreeArmAlignmentInput(inputValue)
end
function AutomaticArmControlForwarder:updateActionEvents(state)
	local spec = self.spec_automaticArmControlForwarder
	local actionEvent = spec.actionEvents[InputAction.TREE_AUTOMATIC_ALIGN]
	if actionEvent ~= nil then
		g_inputBinding:setActionEventActive(actionEvent.actionEventId, state)
	end
end
function AutomaticArmControlForwarder:getIsAutoTreeAlignmentAllowed()
	local spec = self.spec_automaticArmControlForwarder
	if self.getIsControlled ~= nil and not self:getIsControlled() then
		return false
	end
	if spec.requiresEasyArmControl and (self.spec_cylindered.easyArmControl == nil or not self.spec_cylindered.easyArmControl.state) then
		return false
	end
	if self.getFoldAnimTime ~= nil then
		local time = self:getFoldAnimTime()
		if time < spec.foldMinLimit or spec.foldMaxLimit < time then
			return false
		end
	end
	return true
end
function AutomaticArmControlForwarder:setTreeArmAlignmentInput(inputValue)
	local spec = self.spec_automaticArmControlForwarder
	if self.isServer then
		if 0 < inputValue and (spec.state ~= AutomaticArmControlForwarder.STATE_FINISHED and spec.foundValidTargetServer) then
			self:doTreeArmAlignment(spec.lastTargetTrans[1], spec.lastTargetTrans[2], spec.lastTargetTrans[3], spec.lastTargetDirection[1], spec.lastTargetDirection[2], spec.lastTargetDirection[3], 1)
			return
		end
		if inputValue == 0 then
			spec.state = AutomaticArmControlForwarder.STATE_NONE
		end
	else
		spec.controlInputLastValue = inputValue
		if 0 < inputValue then
			self:raiseDirtyFlags(spec.dirtyFlag)
		end
	end
end
function AutomaticArmControlForwarder:doTreeArmAlignment(tx, ty, tz, dx, dy, dz, direction, forceMoveUp)
	local spec = self.spec_automaticArmControlForwarder
	if spec.state == AutomaticArmControlForwarder.STATE_NONE then
		if forceMoveUp ~= true then
			if spec.yAlignment.referenceNode ~= nil then
				if spec.yAlignment.upReferenceNode ~= nil then
					local x, _, _ = localToLocal(spec.yAlignment.referenceNode, spec.yAlignment.upReferenceNode, 0, 0, 0)
					if direction == 1 then
						if math.abs(x) < spec.yAlignment.upMaxOffset or direction == -1 and spec.yAlignment.upMaxOffset < math.abs(x) then
							spec.state = AutomaticArmControlForwarder.STATE_MOVE_UP
						else
							spec.state = AutomaticArmControlForwarder.STATE_ALIGN_X
						end
					end
				else
					spec.state = AutomaticArmControlForwarder.STATE_ALIGN_X
				end
			end
		else
			spec.state = AutomaticArmControlForwarder.STATE_MOVE_UP
		end
	end
	if spec.xAlignment.movingTool ~= nil and spec.state == AutomaticArmControlForwarder.STATE_ALIGN_X then
		local _, mainHasFinished = AutomaticArmControlForwarder.movingToolXAlignment(self, spec.xAlignment.movingTool, tx, ty, tz, spec.xAlignment.referenceNode, spec.xAlignment.threshold, spec.xAlignment.speedScale, spec.xAlignment.offset)
		if spec.xToolAlignment.movingTool ~= nil then
			local x, y, z = getWorldTranslation(spec.xToolAlignment.referenceNode or spec.xToolAlignment.movingTool.node)
			local ttx = x + dx
			local tty = y + dy
			local ttz = z + dz
			local _, toolHasFinished = AutomaticArmControlForwarder.movingToolXAlignment(self, spec.xToolAlignment.movingTool, ttx, tty, ttz, spec.xToolAlignment.referenceNode, spec.xToolAlignment.threshold, spec.xToolAlignment.speedScale, spec.xToolAlignment.offset, true)
			if mainHasFinished and toolHasFinished then
				spec.state = AutomaticArmControlForwarder.NEXT_STATE[spec.state]
			end
		elseif mainHasFinished then
			spec.state = AutomaticArmControlForwarder.NEXT_STATE[spec.state]
		end
	end
	if spec.zAlignment.movingTool ~= nil and spec.zAlignment.referenceNode ~= nil then
		local _, _, lz = worldToLocal(spec.rootNode, tx, ty, tz)
		local _, _, targetZ = localToLocal(spec.zAlignment.referenceNode, spec.rootNode, 0, 0, 0)
		local offset = 0
		if spec.state == AutomaticArmControlForwarder.STATE_ALIGN_Z then
			offset = targetZ - lz
			if math.abs(offset) < 0.03 then
				spec.state = AutomaticArmControlForwarder.NEXT_STATE[spec.state]
			end
		end
		if 0.03 < math.abs(offset) then
			spec.zAlignment.movingTool.externalMove = -(offset + 0.5 * math.sign(offset)) * spec.zAlignment.speedScale
		else
			spec.zAlignment.movingTool.externalMove = 0
		end
	end
	if spec.yAlignment.movingTool ~= nil and (spec.yAlignment.referenceNode ~= nil and (spec.state == AutomaticArmControlForwarder.STATE_ALIGN_Y or spec.state == AutomaticArmControlForwarder.STATE_MOVE_UP)) then
		if spec.state == AutomaticArmControlForwarder.STATE_MOVE_UP then
			local _ = nil
			_, ty, _ = getWorldTranslation(spec.yAlignment.upReferenceNode)
		end
		local _, curY, _ = getWorldTranslation(spec.yAlignment.referenceNode)
		local offset = ty - curY
		if 0.03 < math.abs(offset) then
			spec.yAlignment.movingTool.externalMove = (offset + 0.5 * math.sign(offset)) * spec.yAlignment.speedScale
			return
		end
		spec.yAlignment.movingTool.externalMove = 0
		spec.state = AutomaticArmControlForwarder.NEXT_STATE[spec.state]
	end
end
function AutomaticArmControlForwarder:movingToolXAlignment(movingTool, tx, ty, tz, referenceNode, threshold, speedScale, offset, allowInversion)
	local dx, _, dz = worldToLocal(referenceNode or movingTool.node, tx, ty, tz)
	dx, dz = MathUtil.vector2Normalize(dx, dz)
	local angle = MathUtil.getYRotationFromDirection(dx, dz) * speedScale
	if allowInversion == true then
		if 1.5707963267948966 < angle then
			angle = angle - 3.141592653589793
		elseif angle < -1.5707963267948966 then
			angle = angle + 3.141592653589793
		end
	end
	local curRot = movingTool.curRot[movingTool.rotationAxis]
	local move = AutomaticArmControlForwarder.calculateMovingToolTargetMove(self, movingTool, curRot + angle)
	if move ~= 0 then
		movingTool.externalMove = move
	elseif math.abs(angle) < threshold then
		return move, true
	end
	return move, false
end
function AutomaticArmControlForwarder:calculateMovingToolTargetMove(movingTool, targetRot)
	local durationToStop = movingTool.lastRotSpeed / movingTool.rotAcceleration
	local rotSpeed = movingTool.lastRotSpeed
	local stopRot = movingTool.curRot[movingTool.rotationAxis]
	local deceleration = -movingTool.rotAcceleration * math.sign(durationToStop)
	durationToStop = MathUtil.round(durationToStop / g_currentDt) * g_currentDt
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
function AutomaticArmControlForwarder:resetAutomaticAlignment()
	self.spec_automaticArmControlForwarder.state = AutomaticArmControlForwarder.STATE_NONE
end
function AutomaticArmControlForwarder:getIsAutomaticAlignmentActive()
	local spec = self.spec_automaticArmControlForwarder
	local _v9 = false
	if spec.state ~= AutomaticArmControlForwarder.STATE_NONE then
		_v9 = spec.state ~= AutomaticArmControlForwarder.STATE_FINISHED
	end
	return _v9
end
function AutomaticArmControlForwarder:getIsAutomaticAlignmentFinished()
	return self.spec_automaticArmControlForwarder.state == AutomaticArmControlForwarder.STATE_FINISHED
end
function AutomaticArmControlForwarder:getAutomaticAlignmentTargetTree()
	return self.spec_automaticArmControlForwarder.lastTreeId
end
function AutomaticArmControlForwarder:getAutomaticAlignmentAvailableTargetTree()
	local spec = self.spec_automaticArmControlForwarder
	return self:getBestTreeToAutoAlign(spec.rootNode, spec.foundTrees)
end
function AutomaticArmControlForwarder:getAutomaticAlignmentCurrentTarget()
	local spec = self.spec_automaticArmControlForwarder
	if spec.lastFoundValidTarget then
		return spec.lastTargetTrans[1], spec.lastTargetTrans[2], spec.lastTargetTrans[3], spec.lastTargetDirection[1], spec.lastTargetDirection[2], spec.lastTargetDirection[3]
	else
		return nil, nil, nil, nil, nil, nil
	end
end
function AutomaticArmControlForwarder:getBestTreeToAutoAlign(referenceNode, trees)
	local minFactor = math.huge
	local minFactorTree = nil
	for treeId, state in pairs(trees) do
		if state and entityExists(treeId) then
			local treeObject = g_currentMission:getNodeObject(treeId)
			if treeObject == nil or treeObject.dynamicMountType == MountableObject.MOUNT_TYPE_NONE then
				local distance = calcDistanceFrom(referenceNode, treeId)
				local x, y, z = localToLocal(treeId, referenceNode, 0, 0, 0)
				x, z = MathUtil.vector2Normalize(x, z)
				local angle = math.abs(MathUtil.getYRotationFromDirection(x, z))
				local factor = math.deg(angle) + distance * 2 - y * 10
				if factor < minFactor then
					minFactor = factor
					minFactorTree = treeId
				end
			end
		end
	end
	return minFactorTree
end
function AutomaticArmControlForwarder:onTreeAutoTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if getHasClassId(otherId, ClassIds.MESH_SPLIT_SHAPE) then
		local spec = self.spec_automaticArmControlForwarder
		if onEnter then
			spec.foundTrees[otherId] = true
			return
		end
		if onLeave then
			spec.foundTrees[otherId] = nil
		end
	end
end
function AutomaticArmControlForwarder.drawDebugCircleRange(node, radius, steps, minRot, maxRot)
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
