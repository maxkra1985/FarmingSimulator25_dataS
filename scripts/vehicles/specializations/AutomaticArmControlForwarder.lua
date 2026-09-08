AutomaticArmControlForwarder = {}
AutomaticArmControlForwarder.STATE_NONE = 0
AutomaticArmControlForwarder.STATE_MOVE_UP = 1
AutomaticArmControlForwarder.STATE_ALIGN_X = 2
AutomaticArmControlForwarder.STATE_ALIGN_Z = 3
AutomaticArmControlForwarder.STATE_ALIGN_Y = 4
AutomaticArmControlForwarder.STATE_FINISHED = 5
AutomaticArmControlForwarder.NEXT_STATE = {
	[AutomaticArmControlForwarder.STATE_MOVE_UP] = AutomaticArmControlForwarder.STATE_ALIGN_X,
	[AutomaticArmControlForwarder.STATE_ALIGN_X] = AutomaticArmControlForwarder.STATE_ALIGN_Z,
	[AutomaticArmControlForwarder.STATE_ALIGN_Z] = AutomaticArmControlForwarder.STATE_ALIGN_Y,
	[AutomaticArmControlForwarder.STATE_ALIGN_Y] = AutomaticArmControlForwarder.STATE_FINISHED
}

function AutomaticArmControlForwarder.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Cylindered, specializations)
end
function AutomaticArmControlForwarder.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("automaticArmControlForwarder", g_i18n:getText("shop_configuration"), "automaticArmControlForwarder", VehicleConfigurationItem)
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("AutomaticArmControlForwarder")
	AutomaticArmControlForwarder.registerXMLPaths(v2_, "vehicle.automaticArmControlForwarder")
	AutomaticArmControlForwarder.registerXMLPaths(v2_, "vehicle.automaticArmControlForwarder.automaticArmControlForwarderConfigurations.automaticArmControlForwarderConfiguration(?)")
	v2_:setXMLSpecializationType()
end

function AutomaticArmControlForwarder.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. "#requiresEasyArmControl", "If \'true\' then it is only available if easy arm control is enabled", true)
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

-- Local values: spec, configurationId, configKey, offset, _, _
function AutomaticArmControlForwarder:onLoad(savegame)
	local v_u_8_ = self.spec_automaticArmControlForwarder
	local v9_ = Utils.getNoNil(self.configurations.automaticArmControlForwarder, 1)
	local v10_ = string.format("vehicle.automaticArmControlForwarder.automaticArmControlForwarderConfigurations.automaticArmControlForwarderConfiguration(%d)", v9_ - 1)
	local v11_ = not self.xmlFile:hasProperty(v10_) and "vehicle.automaticArmControlForwarder" or v10_
	v_u_8_.xAlignment = {}
	v_u_8_.zAlignment = {}
	v_u_8_.yAlignment = {}
	v_u_8_.xToolAlignment = {}
	v_u_8_.rootNode = self.xmlFile:getValue(v11_ .. "#rootNode", nil, self.components, self.i3dMappings)
	if v_u_8_.rootNode == nil then
		SpecializationUtil.removeEventListener(self, "onDelete", AutomaticArmControlForwarder)
		SpecializationUtil.removeEventListener(self, "onUpdate", AutomaticArmControlForwarder)
		SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", AutomaticArmControlForwarder)
	else
		v_u_8_.treeTriggers = {}
		self.xmlFile:iterate(v11_ .. ".treeTrigger", function(_, p12_)
			-- upvalues: (copy) self, (copy) v_u_8_
			local v13_ = self.xmlFile:getValue(p12_ .. "#node", nil, self.components, self.i3dMappings)
			if v13_ ~= nil then
				addTrigger(v13_, "onTreeAutoTriggerCallback", self)
				local v14_ = v_u_8_.treeTriggers
				table.insert(v14_, v13_)
			end
		end)
		v_u_8_.foundTrees = {}
		v_u_8_.foundValidTargetServer = false
		v_u_8_.lastFoundValidTarget = false
		v_u_8_.lastTargetRadius = 1
		v_u_8_.lastTargetTrans = { 0, 0, 0 }
		v_u_8_.lastTargetDirection = { 0, 0, 1 }
		v_u_8_.lastTreeId = nil
		v_u_8_.state = AutomaticArmControlForwarder.STATE_NONE
		v_u_8_.xAlignment = {}
		v_u_8_.xAlignment.movingToolNode = self.xmlFile:getValue(v11_ .. ".xAlignment#movingToolNode", nil, self.components, self.i3dMappings)
		v_u_8_.xAlignment.speedScale = self.xmlFile:getValue(v11_ .. ".xAlignment#speedScale", 1)
		v_u_8_.xAlignment.offset = self.xmlFile:getValue(v11_ .. ".xAlignment#offset")
		v_u_8_.xAlignment.threshold = self.xmlFile:getValue(v11_ .. ".xAlignment#threshold", 1)
		v_u_8_.zAlignment = {}
		v_u_8_.zAlignment.movingToolNode = self.xmlFile:getValue(v11_ .. ".zAlignment#movingToolNode", nil, self.components, self.i3dMappings)
		v_u_8_.zAlignment.speedScale = self.xmlFile:getValue(v11_ .. ".zAlignment#speedScale", 1)
		v_u_8_.zAlignment.referenceNode = self.xmlFile:getValue(v11_ .. ".zAlignment#referenceNode", nil, self.components, self.i3dMappings)
		v_u_8_.yAlignment = {}
		v_u_8_.yAlignment.movingToolNode = self.xmlFile:getValue(v11_ .. ".yAlignment#movingToolNode", nil, self.components, self.i3dMappings)
		v_u_8_.yAlignment.speedScale = self.xmlFile:getValue(v11_ .. ".yAlignment#speedScale", 1)
		v_u_8_.yAlignment.referenceNode = self.xmlFile:getValue(v11_ .. ".yAlignment#referenceNode", nil, self.components, self.i3dMappings)
		v_u_8_.yAlignment.upReferenceNode = self.xmlFile:getValue(v11_ .. ".yAlignment.moveUp#referenceNode", nil, self.components, self.i3dMappings)
		v_u_8_.yAlignment.upMaxOffset = self.xmlFile:getValue(v11_ .. ".yAlignment.moveUp#maxOffset", 2)
		v_u_8_.xToolAlignment = {}
		v_u_8_.xToolAlignment.movingToolNode = self.xmlFile:getValue(v11_ .. ".xToolAlignment#movingToolNode", nil, self.components, self.i3dMappings)
		v_u_8_.xToolAlignment.referenceNode = self.xmlFile:getValue(v11_ .. ".xToolAlignment#referenceNode", nil, self.components, self.i3dMappings)
		v_u_8_.xToolAlignment.speedScale = self.xmlFile:getValue(v11_ .. ".xToolAlignment#speedScale", 1)
		v_u_8_.xToolAlignment.offset = self.xmlFile:getValue(v11_ .. ".xToolAlignment#offset")
		v_u_8_.xToolAlignment.threshold = self.xmlFile:getValue(v11_ .. ".xToolAlignment#threshold", 1)
		v_u_8_.treeMarker = TargetTreeMarker.new(self, self.rootNode)
		v_u_8_.treeMarker:loadFromXML(self.xmlFile, v11_ .. ".treeMarker", self.baseDirectory)
		v_u_8_.treeMarker.cutColor = { v_u_8_.treeMarker.color[1], v_u_8_.treeMarker.color[2], v_u_8_.treeMarker.color[3] }
		v_u_8_.treeMarker.targetColor = self.xmlFile:getValue(v11_ .. ".treeMarker#targetColor", "2 2 0", true)
		v_u_8_.treeMarker.tooThickColor = self.xmlFile:getValue(v11_ .. ".treeMarker#tooThickColor", "2 0 0", true)
		v_u_8_.requiresEasyArmControl = self.xmlFile:getValue(v11_ .. "#requiresEasyArmControl", true)
		v_u_8_.foldMinLimit = self.xmlFile:getValue(v11_ .. "#foldMinLimit", 0)
		v_u_8_.foldMaxLimit = self.xmlFile:getValue(v11_ .. "#foldMaxLimit", 1)
		if v_u_8_.xAlignment.offset == nil and (v_u_8_.yAlignment.referenceNode ~= nil and v_u_8_.xAlignment.movingToolNode ~= nil) then
			local v15_, _, _ = localToLocal(v_u_8_.yAlignment.referenceNode, v_u_8_.xAlignment.movingToolNode, 0, 0, 0)
			v_u_8_.xAlignment.offset = -v15_
		end
		v_u_8_.controlInputLastValue = 0
		v_u_8_.controlInputTimer = 0
		v_u_8_.dirtyFlag = self:getNextDirtyFlag()
		if Platform.gameplay.automaticVehicleControl then
			SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", AutomaticArmControlForwarder)
			return
		end
	end
end

-- Local values: spec
function AutomaticArmControlForwarder:onPostLoad(savegame)
	local v17_ = self.spec_automaticArmControlForwarder
	if v17_.xAlignment.movingToolNode ~= nil then
		v17_.xAlignment.movingTool = self:getMovingToolByNode(v17_.xAlignment.movingToolNode)
	end
	if v17_.zAlignment.movingToolNode ~= nil then
		v17_.zAlignment.movingTool = self:getMovingToolByNode(v17_.zAlignment.movingToolNode)
	end
	if v17_.yAlignment.movingToolNode ~= nil then
		v17_.yAlignment.movingTool = self:getMovingToolByNode(v17_.yAlignment.movingToolNode)
	end
	if v17_.xToolAlignment.movingToolNode ~= nil then
		v17_.xToolAlignment.movingTool = self:getMovingToolByNode(v17_.xToolAlignment.movingToolNode)
	end
end

-- Local values: spec, i
function AutomaticArmControlForwarder:onDelete()
	local v19_ = self.spec_automaticArmControlForwarder
	if v19_.treeMarker ~= nil then
		v19_.treeMarker:delete()
	end
	if v19_.treeTriggers ~= nil then
		for v20_ = 1, #v19_.treeTriggers do
			removeTrigger(v19_.treeTriggers[v20_])
		end
		v19_.treeTriggers = nil
	end
end

-- Local values: spec
function AutomaticArmControlForwarder:onReadUpdateStream(streamId, timestamp, connection)
	local v24_ = self.spec_automaticArmControlForwarder
	if v24_.rootNode ~= nil then
		if connection:getIsServer() then
			if streamReadBool(streamId) then
				v24_.foundValidTargetServer = streamReadBool(streamId)
			end
		elseif streamReadBool(streamId) then
			v24_.controlInputLastValue = streamReadBool(streamId) and 1 or 0
			v24_.controlInputTimer = 250
			return
		end
	end
end

-- Local values: spec
function AutomaticArmControlForwarder:onWriteUpdateStream(streamId, connection, dirtyMask)
	local v29_ = self.spec_automaticArmControlForwarder
	if v29_.rootNode ~= nil then
		if connection:getIsServer() then
			local v30_ = streamWriteBool
			local v31_ = v29_.dirtyFlag
			if v30_(streamId, bit32.band(dirtyMask, v31_) ~= 0) then
				streamWriteBool(streamId, v29_.controlInputLastValue ~= 0)
				return
			end
		else
			local v32_ = streamWriteBool
			local v33_ = v29_.dirtyFlag
			if v32_(streamId, bit32.band(dirtyMask, v33_) ~= 0) then
				streamWriteBool(streamId, v29_.foundValidTargetServer)
			end
		end
	end
end

-- Local values: spec, foundValidTarget, bestTreeId, wx, wy, wz, dx, dy, dz, radius, treeObject, targetFound
function AutomaticArmControlForwarder:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v37_ = self.spec_automaticArmControlForwarder
	local v38_ = false
	if self:getIsAutoTreeAlignmentAllowed() then
		local v39_ = v37_.lastTreeId
		if v37_.state == AutomaticArmControlForwarder.STATE_NONE or v37_.state == AutomaticArmControlForwarder.STATE_FINISHED then
			v39_ = self:getBestTreeToAutoAlign(v37_.rootNode, v37_.foundTrees)
		elseif v37_.foundTrees[v39_] == nil then
			v39_ = nil
		end
		if v39_ == nil or not entityExists(v39_) then
			v37_.lastTreeId = nil
		else
			local v40_, v41_, v42_, v43_, v44_, v45_, v46_
			if g_currentMission:getNodeObject(v39_) == nil then
				local v47_, v48_, v49_ = getWorldTranslation(v39_)
				v40_, v41_, v42_, v43_, v44_, v45_, v46_ = SplitShapeUtil.getTreeOffsetPosition(v39_, v47_, v48_, v49_, 3)
			else
				v40_, v41_, v42_ = getWorldTranslation(v39_)
				v43_, v44_, v45_ = localDirectionToWorld(v39_, 0, 0, 1)
				v46_ = getUserAttribute(v39_, "logRadius") or 0.5
			end
			if v40_ == nil then
				v37_.lastTreeId = nil
			else
				v37_.lastTreeId = v39_
				v37_.lastTargetRadius = v46_
				local v50_ = v37_.lastTargetTrans
				local v51_ = v37_.lastTargetTrans
				local v52_ = v37_.lastTargetTrans
				v50_[1] = v40_
				v51_[2] = v41_
				v52_[3] = v42_
				local v53_ = v37_.lastTargetDirection
				local v54_ = v37_.lastTargetDirection
				local v55_ = v37_.lastTargetDirection
				v53_[1] = v43_
				v54_[2] = v44_
				v55_[3] = v45_
				v38_ = true
			end
		end
	else
		v37_.lastTreeId = nil
	end
	if self.isClient then
		local v56_ = v37_.foundValidTargetServer
		if v56_ then
			if not v38_ then
				isActiveForInputIgnoreSelection = v38_
			end
		else
			isActiveForInputIgnoreSelection = v56_
		end
		v37_.treeMarker:setIsActive(isActiveForInputIgnoreSelection)
		if isActiveForInputIgnoreSelection then
			v37_.treeMarker:setPosition(v37_.lastTargetTrans[1], v37_.lastTargetTrans[2], v37_.lastTargetTrans[3], v37_.lastTargetDirection[1], v37_.lastTargetDirection[2], v37_.lastTargetDirection[3], v37_.lastTargetRadius + 0.005)
		end
		AutomaticArmControlForwarder.updateActionEvents(self, isActiveForInputIgnoreSelection)
	end
	if self.isServer then
		if v38_ ~= v37_.lastFoundValidTarget then
			v37_.foundValidTargetServer = v38_
			v37_.lastFoundValidTarget = v38_
			self:raiseDirtyFlags(v37_.dirtyFlag)
			v37_.state = AutomaticArmControlForwarder.STATE_NONE
		end
		if v37_.controlInputTimer > 0 then
			v37_.controlInputTimer = v37_.controlInputTimer - dt
			if v37_.controlInputTimer <= 0 then
				v37_.controlInputLastValue = 0
				v37_.controlInputTimer = 0
			end
			self:setTreeArmAlignmentInput(v37_.controlInputLastValue)
		end
	end
end

-- Local values: spec
function AutomaticArmControlForwarder:onAutoLoadForwaderMountedTree(treeNodeId)
	self.spec_automaticArmControlForwarder.foundTrees[treeNodeId] = nil
end

-- Local values: spec, _, actionEventId
function AutomaticArmControlForwarder:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v61_ = self.spec_automaticArmControlForwarder
		self:clearActionEventsTable(v61_.actionEvents)
		if isActiveForInputIgnoreSelection then
			local _, v62_ = self:addPoweredActionEvent(v61_.actionEvents, InputAction.TREE_AUTOMATIC_ALIGN, self, AutomaticArmControlForwarder.actionEvent, true, false, true, true, nil)
			g_inputBinding:setActionEventTextPriority(v62_, GS_PRIO_VERY_HIGH)
			AutomaticArmControlForwarder.updateActionEvents(self, false)
		end
	end
end

function AutomaticArmControlForwarder:actionEvent(actionName, inputValue, callbackState, isAnalog)
	self:setTreeArmAlignmentInput(inputValue)
end

-- Local values: spec, actionEvent
function AutomaticArmControlForwarder:updateActionEvents(state)
	local v67_ = self.spec_automaticArmControlForwarder.actionEvents[InputAction.TREE_AUTOMATIC_ALIGN]
	if v67_ ~= nil then
		g_inputBinding:setActionEventActive(v67_.actionEventId, state)
	end
end

-- Local values: spec, time
function AutomaticArmControlForwarder:getIsAutoTreeAlignmentAllowed()
	local v69_ = self.spec_automaticArmControlForwarder
	if self.getIsControlled ~= nil and not self:getIsControlled() then
		return false
	end
	if v69_.requiresEasyArmControl and (self.spec_cylindered.easyArmControl == nil or not self.spec_cylindered.easyArmControl.state) then
		return false
	end
	if self.getFoldAnimTime ~= nil then
		local v70_ = self:getFoldAnimTime()
		if v70_ < v69_.foldMinLimit or v69_.foldMaxLimit < v70_ then
			return false
		end
	end
	return true
end

-- Local values: spec
function AutomaticArmControlForwarder:setTreeArmAlignmentInput(inputValue)
	local v73_ = self.spec_automaticArmControlForwarder
	if self.isServer then
		if inputValue > 0 and (v73_.state ~= AutomaticArmControlForwarder.STATE_FINISHED and v73_.foundValidTargetServer) then
			self:doTreeArmAlignment(v73_.lastTargetTrans[1], v73_.lastTargetTrans[2], v73_.lastTargetTrans[3], v73_.lastTargetDirection[1], v73_.lastTargetDirection[2], v73_.lastTargetDirection[3], 1)
			return
		end
		if inputValue == 0 then
			v73_.state = AutomaticArmControlForwarder.STATE_NONE
			return
		end
	else
		v73_.controlInputLastValue = inputValue
		if inputValue > 0 then
			self:raiseDirtyFlags(v73_.dirtyFlag)
		end
	end
end

-- Local values: spec, x, _, _, _, mainHasFinished, x, y, z, ttx, tty, ttz, _, toolHasFinished, _, _, lz, _, _, targetZ, offset, _, _, curY, _, offset
function AutomaticArmControlForwarder:doTreeArmAlignment(tx, ty, tz, dx, dy, dz, direction, forceMoveUp)
	local v83_ = self.spec_automaticArmControlForwarder
	if v83_.state == AutomaticArmControlForwarder.STATE_NONE then
		if forceMoveUp == true then
			v83_.state = AutomaticArmControlForwarder.STATE_MOVE_UP
		elseif v83_.yAlignment.referenceNode == nil or v83_.yAlignment.upReferenceNode == nil then
			v83_.state = AutomaticArmControlForwarder.STATE_ALIGN_X
		else
			local v84_, _, _ = localToLocal(v83_.yAlignment.referenceNode, v83_.yAlignment.upReferenceNode, 0, 0, 0)
			if direction == 1 and math.abs(v84_) < v83_.yAlignment.upMaxOffset or direction == -1 and math.abs(v84_) > v83_.yAlignment.upMaxOffset then
				v83_.state = AutomaticArmControlForwarder.STATE_MOVE_UP
			else
				v83_.state = AutomaticArmControlForwarder.STATE_ALIGN_X
			end
		end
	end
	if v83_.xAlignment.movingTool ~= nil and v83_.state == AutomaticArmControlForwarder.STATE_ALIGN_X then
		local _, v85_ = AutomaticArmControlForwarder.movingToolXAlignment(self, v83_.xAlignment.movingTool, tx, ty, tz, v83_.xAlignment.referenceNode, v83_.xAlignment.threshold, v83_.xAlignment.speedScale, v83_.xAlignment.offset)
		if v83_.xToolAlignment.movingTool == nil then
			if v85_ then
				v83_.state = AutomaticArmControlForwarder.NEXT_STATE[v83_.state]
			end
		else
			local v86_, v87_, v88_ = getWorldTranslation(v83_.xToolAlignment.referenceNode or v83_.xToolAlignment.movingTool.node)
			local v89_ = v86_ + dx
			local v90_ = v87_ + dy
			local v91_ = v88_ + dz
			local _, v92_ = AutomaticArmControlForwarder.movingToolXAlignment(self, v83_.xToolAlignment.movingTool, v89_, v90_, v91_, v83_.xToolAlignment.referenceNode, v83_.xToolAlignment.threshold, v83_.xToolAlignment.speedScale, v83_.xToolAlignment.offset, true)
			if v85_ and v92_ then
				v83_.state = AutomaticArmControlForwarder.NEXT_STATE[v83_.state]
			end
		end
	end
	if v83_.zAlignment.movingTool ~= nil and v83_.zAlignment.referenceNode ~= nil then
		local _, _, v93_ = worldToLocal(v83_.rootNode, tx, ty, tz)
		local _, _, v94_ = localToLocal(v83_.zAlignment.referenceNode, v83_.rootNode, 0, 0, 0)
		local v95_
		if v83_.state == AutomaticArmControlForwarder.STATE_ALIGN_Z then
			v95_ = v94_ - v93_
			if math.abs(v95_) < 0.03 then
				v83_.state = AutomaticArmControlForwarder.NEXT_STATE[v83_.state]
			end
		else
			v95_ = 0
		end
		if math.abs(v95_) > 0.03 then
			v83_.zAlignment.movingTool.externalMove = -(v95_ + 0.5 * math.sign(v95_)) * v83_.zAlignment.speedScale
		else
			v83_.zAlignment.movingTool.externalMove = 0
		end
	end
	if v83_.yAlignment.movingTool ~= nil and (v83_.yAlignment.referenceNode ~= nil and (v83_.state == AutomaticArmControlForwarder.STATE_ALIGN_Y or v83_.state == AutomaticArmControlForwarder.STATE_MOVE_UP)) then
		if v83_.state == AutomaticArmControlForwarder.STATE_MOVE_UP then
			local v96_, v97_
			v96_, ty, v97_ = getWorldTranslation(v83_.yAlignment.upReferenceNode)
		end
		local _, v98_, _ = getWorldTranslation(v83_.yAlignment.referenceNode)
		local v99_ = ty - v98_
		if math.abs(v99_) > 0.03 then
			v83_.yAlignment.movingTool.externalMove = (v99_ + 0.5 * math.sign(v99_)) * v83_.yAlignment.speedScale
			return
		end
		v83_.yAlignment.movingTool.externalMove = 0
		v83_.state = AutomaticArmControlForwarder.NEXT_STATE[v83_.state]
	end
end

-- Local values: dx, _, dz, angle, curRot, move
function AutomaticArmControlForwarder:movingToolXAlignment(movingTool, tx, ty, tz, referenceNode, threshold, speedScale, offset, allowInversion)
	local v109_, _, v110_ = worldToLocal(referenceNode or movingTool.node, tx, ty, tz)
	local v111_, v112_ = MathUtil.vector2Normalize(v109_, v110_)
	local v113_ = MathUtil.getYRotationFromDirection(v111_, v112_) * speedScale
	if allowInversion == true then
		if v113_ > 1.5707963267948966 then
			v113_ = v113_ - 3.141592653589793
		elseif v113_ < -1.5707963267948966 then
			v113_ = v113_ + 3.141592653589793
		end
	end
	local v114_ = movingTool.curRot[movingTool.rotationAxis]
	local v115_ = AutomaticArmControlForwarder.calculateMovingToolTargetMove(self, movingTool, v114_ + v113_)
	if v115_ == 0 then
		if math.abs(v113_) < threshold then
			return v115_, true
		end
	else
		movingTool.externalMove = v115_
	end
	return v115_, false
end

-- Local values: durationToStop, rotSpeed, stopRot, deceleration, _, threshold, state, stopState, targetState, curRot, move, offset
function AutomaticArmControlForwarder:calculateMovingToolTargetMove(movingTool, targetRot)
	local v119_ = movingTool.lastRotSpeed / movingTool.rotAcceleration
	local v120_ = movingTool.lastRotSpeed
	local v121_ = movingTool.curRot[movingTool.rotationAxis]
	local v122_ = -movingTool.rotAcceleration * math.sign(v119_)
	local v123_ = MathUtil.round(v119_ / g_currentDt) * g_currentDt
	for _ = 1, math.abs(v123_) do
		v120_ = v120_ + v122_
		v121_ = v121_ + v120_
	end
	local v124_ = 0.001
	local v125_, v126_
	if movingTool.rotMin == nil or movingTool.rotMax == nil then
		local v127_ = movingTool.curRot[movingTool.rotationAxis]
		v125_ = MathUtil.normalizeRotationForShortestPath(v127_, targetRot)
		v126_ = MathUtil.normalizeRotationForShortestPath(v121_, targetRot)
		v124_ = 0.0001
	else
		v125_ = Cylindered.getMovingToolState(self, movingTool)
		v126_ = MathUtil.inverseLerp(movingTool.rotMin, movingTool.rotMax, v121_)
		targetRot = MathUtil.inverseLerp(movingTool.rotMin, movingTool.rotMax, targetRot)
	end
	local v128_
	if targetRot < v125_ then
		local v129_ = movingTool.rotSpeed
		v128_ = -math.sign(v129_)
		if v126_ < targetRot then
			return 0
		end
	else
		local v130_ = movingTool.rotSpeed
		v128_ = math.sign(v130_)
		if targetRot < v126_ then
			return 0
		end
	end
	local v131_ = targetRot - v125_
	return math.abs(v131_) < v124_ and 0 or v128_
end

function AutomaticArmControlForwarder:resetAutomaticAlignment()
	self.spec_automaticArmControlForwarder.state = AutomaticArmControlForwarder.STATE_NONE
end

-- Local values: spec
function AutomaticArmControlForwarder:getIsAutomaticAlignmentActive()
	local v134_ = self.spec_automaticArmControlForwarder
	local v135_
	if v134_.state == AutomaticArmControlForwarder.STATE_NONE then
		v135_ = false
	else
		v135_ = v134_.state ~= AutomaticArmControlForwarder.STATE_FINISHED
	end
	return v135_
end

function AutomaticArmControlForwarder:getIsAutomaticAlignmentFinished()
	return self.spec_automaticArmControlForwarder.state == AutomaticArmControlForwarder.STATE_FINISHED
end

function AutomaticArmControlForwarder:getAutomaticAlignmentTargetTree()
	return self.spec_automaticArmControlForwarder.lastTreeId
end

-- Local values: spec
function AutomaticArmControlForwarder:getAutomaticAlignmentAvailableTargetTree()
	local v139_ = self.spec_automaticArmControlForwarder
	return self:getBestTreeToAutoAlign(v139_.rootNode, v139_.foundTrees)
end

-- Local values: spec
function AutomaticArmControlForwarder:getAutomaticAlignmentCurrentTarget()
	local v141_ = self.spec_automaticArmControlForwarder
	if v141_.lastFoundValidTarget then
		return v141_.lastTargetTrans[1], v141_.lastTargetTrans[2], v141_.lastTargetTrans[3], v141_.lastTargetDirection[1], v141_.lastTargetDirection[2], v141_.lastTargetDirection[3]
	else
		return nil, nil, nil, nil, nil, nil
	end
end

-- Local values: minFactor, minFactorTree, treeId, state, treeObject, distance, x, y, z, angle, factor
function AutomaticArmControlForwarder:getBestTreeToAutoAlign(referenceNode, trees)
	local v144_ = math.huge
	local v145_ = nil
	for v146_, v147_ in pairs(trees) do
		if v147_ and entityExists(v146_) then
			local v148_ = g_currentMission:getNodeObject(v146_)
			if v148_ == nil or v148_.dynamicMountType == MountableObject.MOUNT_TYPE_NONE then
				local v149_ = calcDistanceFrom(referenceNode, v146_)
				local v150_, v151_, v152_ = localToLocal(v146_, referenceNode, 0, 0, 0)
				local v153_, v154_ = MathUtil.vector2Normalize(v150_, v152_)
				local v155_ = MathUtil.getYRotationFromDirection(v153_, v154_)
				local v156_ = math.abs(v155_)
				local v157_ = math.deg(v156_) + v149_ * 2 - v151_ * 10
				if v157_ < v144_ then
					v145_ = v146_
					v144_ = v157_
				end
			end
		end
	end
	return v145_
end

-- Local values: spec
function AutomaticArmControlForwarder:onTreeAutoTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if getHasClassId(otherId, ClassIds.MESH_SPLIT_SHAPE) then
		local v162_ = self.spec_automaticArmControlForwarder
		if onEnter then
			v162_.foundTrees[otherId] = true
			return
		end
		if onLeave then
			v162_.foundTrees[otherId] = nil
		end
	end
end

-- Local values: ox, oy, oz, range, i, a1, a2, c, s, x1, y1, z1, x2, y2, z2
function AutomaticArmControlForwarder.drawDebugCircleRange(node, radius, steps, minRot, maxRot)
	local v168_ = maxRot - minRot
	local v169_ = 0
	local v170_ = 0
	for v171_ = 1, steps do
		local v172_ = 1.5707963267948966 + minRot + (v171_ - 1) / steps * v168_
		local v173_ = 1.5707963267948966 + minRot + v171_ / steps * v168_
		local v174_ = math.cos(v172_) * radius
		local v175_ = math.sin(v172_) * radius
		local v176_, v177_, v178_ = localToWorld(node, v169_ + v174_, 0, v170_ + v175_)
		local v179_ = math.cos(v173_) * radius
		local v180_ = math.sin(v173_) * radius
		local v181_, v182_, v183_ = localToWorld(node, v169_ + v179_, 0, v170_ + v180_)
		drawDebugLine(v176_, v177_, v178_, 1, 0, 0, v181_, v182_, v183_, 1, 0, 0)
	end
end
