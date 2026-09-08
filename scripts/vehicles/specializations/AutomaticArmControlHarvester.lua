AutomaticArmControlHarvester = {}
AutomaticArmControlHarvester.STATE_NONE = 0
AutomaticArmControlHarvester.STATE_MOVE_BACK = 1
AutomaticArmControlHarvester.STATE_ALIGN_X = 2
AutomaticArmControlHarvester.STATE_ALIGN_Z = 3
AutomaticArmControlHarvester.STATE_FINISHED = 4
local v1_ = AutomaticArmControlHarvester
local v2_ = {
	[1] = {
		[AutomaticArmControlHarvester.STATE_NONE] = AutomaticArmControlHarvester.STATE_MOVE_BACK,
		[AutomaticArmControlHarvester.STATE_MOVE_BACK] = AutomaticArmControlHarvester.STATE_ALIGN_X,
		[AutomaticArmControlHarvester.STATE_ALIGN_X] = AutomaticArmControlHarvester.STATE_ALIGN_Z,
		[AutomaticArmControlHarvester.STATE_ALIGN_Z] = AutomaticArmControlHarvester.STATE_FINISHED
	},
	[-1] = {
		[AutomaticArmControlHarvester.STATE_NONE] = AutomaticArmControlHarvester.STATE_ALIGN_Z,
		[AutomaticArmControlHarvester.STATE_ALIGN_Z] = AutomaticArmControlHarvester.STATE_ALIGN_X,
		[AutomaticArmControlHarvester.STATE_ALIGN_X] = AutomaticArmControlHarvester.STATE_FINISHED
	}
}
v1_.NEXT_STATE = v2_
AutomaticArmControlHarvester.INVALID_REASON_NONE = 0
AutomaticArmControlHarvester.INVALID_REASON_NO_ACCESS = 1
AutomaticArmControlHarvester.INVALID_REASON_TOO_THICK = 2
AutomaticArmControlHarvester.INVALID_REASON_WRONG_TYPE = 3

function AutomaticArmControlHarvester.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Cylindered, specializations)
end
function AutomaticArmControlHarvester.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("automaticArmControlHarvester", g_i18n:getText("shop_configuration"), "automaticArmControlHarvester", VehicleConfigurationItem)
	local v4_ = Vehicle.xmlSchema
	v4_:setXMLSpecializationType("AutomaticArmControlHarvester")
	AutomaticArmControlHarvester.registerXMLPaths(v4_, "vehicle.automaticArmControlHarvester")
	AutomaticArmControlHarvester.registerXMLPaths(v4_, "vehicle.automaticArmControlHarvester.automaticArmControlHarvesterConfigurations.automaticArmControlHarvesterConfiguration(?)")
	v4_:setXMLSpecializationType()
end

function AutomaticArmControlHarvester.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. "#requiresEasyArmControl", "If \'true\' then it is only available if easy arm control is enabled", true)
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

function AutomaticArmControlHarvester.registerFunctions(self)
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

function AutomaticArmControlHarvester.registerOverwrittenFunctions(self) end

function AutomaticArmControlHarvester.registerEventListeners(self)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AutomaticArmControlHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AutomaticArmControlHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", AutomaticArmControlHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", AutomaticArmControlHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", AutomaticArmControlHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AutomaticArmControlHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", AutomaticArmControlHarvester)
	SpecializationUtil.registerEventListener(vehicleType, "onRootVehicleChanged", AutomaticArmControlHarvester)
end

-- Local values: spec, configurationId, configKey, offset, _, _
function AutomaticArmControlHarvester:onLoad(savegame)
	local v_u_10_ = self.spec_automaticArmControlHarvester
	local v11_ = Utils.getNoNil(self.configurations.automaticArmControlHarvester, 1)
	local v12_ = string.format("vehicle.automaticArmControlHarvester.automaticArmControlHarvesterConfigurations.automaticArmControlHarvesterConfiguration(%d)", v11_ - 1)
	local v13_ = not self.xmlFile:hasProperty(v12_) and "vehicle.automaticArmControlHarvester" or v12_
	v_u_10_.alignmentNodes = {}
	self.xmlFile:iterate(v13_ .. ".alignmentNode", function(_, p14_)
		-- upvalues: (copy) self, (copy) v_u_10_
		local v15_ = {
			["movingToolNode"] = self.xmlFile:getValue(p14_ .. "#movingToolNode", nil, self.components, self.i3dMappings),
			["rotation"] = self.xmlFile:getValue(p14_ .. "#rotation"),
			["translation"] = self.xmlFile:getValue(p14_ .. "#translation")
		}
		if v15_.movingToolNode ~= nil and (v15_.rotation ~= nil or v15_.translation ~= nil) then
			v15_.speedScale = self.xmlFile:getValue(p14_ .. "#speedScale", 1)
			v15_.isPrerequisite = self.xmlFile:getValue(p14_ .. "#isPrerequisite", false)
			local v16_ = v_u_10_.alignmentNodes
			table.insert(v16_, v15_)
		end
	end)
	v_u_10_.xAlignment = {}
	v_u_10_.zAlignment = {}
	v_u_10_.yAlignment = {}
	v_u_10_.treeDetectionNode = self.xmlFile:getValue(v13_ .. ".treeDetectionNode#node", nil, self.components, self.i3dMappings)
	if v_u_10_.treeDetectionNode == nil then
		v_u_10_.xAlignment.offset = self.xmlFile:getValue(v13_ .. ".xAlignment#offset")
		v_u_10_.zAlignment.referenceNode = self.xmlFile:getValue(v13_ .. ".zAlignment#referenceNode", nil, self.components, self.i3dMappings)
		v_u_10_.yAlignment.referenceNode = self.xmlFile:getValue(v13_ .. ".yAlignment#referenceNode", nil, self.components, self.i3dMappings)
		SpecializationUtil.removeEventListener(self, "onDelete", AutomaticArmControlHarvester)
		SpecializationUtil.removeEventListener(self, "onUpdate", AutomaticArmControlHarvester)
		SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", AutomaticArmControlHarvester)
	else
		v_u_10_.treeDetectionNodeMinRadius = self.xmlFile:getValue(v13_ .. ".treeDetectionNode#minRadius", 5)
		v_u_10_.treeDetectionNodeMaxRadius = self.xmlFile:getValue(v13_ .. ".treeDetectionNode#maxRadius", 10)
		v_u_10_.treeDetectionNodeMaxAngle = self.xmlFile:getValue(v13_ .. ".treeDetectionNode#maxAngle", 45)
		v_u_10_.treeDetectionNodeCutHeight = self.xmlFile:getValue(v13_ .. ".treeDetectionNode#cutHeight", 0.4)
		v_u_10_.treeDetectionNodeCutHeightSafetyOffset = 0.075
		v_u_10_.foundTrees = {}
		v_u_10_.foundValidTargetServer = false
		v_u_10_.lastFoundValidTarget = false
		v_u_10_.lastTargetTrans = { 0, 0, 0 }
		v_u_10_.lastRadius = 1
		v_u_10_.state = AutomaticArmControlHarvester.STATE_NONE
		v_u_10_.xAlignment = {}
		v_u_10_.xAlignment.movingToolNode = self.xmlFile:getValue(v13_ .. ".xAlignment#movingToolNode", nil, self.components, self.i3dMappings)
		v_u_10_.xAlignment.speedScale = self.xmlFile:getValue(v13_ .. ".xAlignment#speedScale", 1)
		v_u_10_.xAlignment.offset = self.xmlFile:getValue(v13_ .. ".xAlignment#offset")
		v_u_10_.xAlignment.threshold = self.xmlFile:getValue(v13_ .. ".xAlignment#threshold", 1)
		v_u_10_.xAlignment.referenceNode = self.xmlFile:getValue(v13_ .. ".xAlignment#referenceNode", nil, self.components, self.i3dMappings)
		v_u_10_.zAlignment = {}
		v_u_10_.zAlignment.movingToolNode = self.xmlFile:getValue(v13_ .. ".zAlignment#movingToolNode", nil, self.components, self.i3dMappings)
		v_u_10_.zAlignment.speedScale = self.xmlFile:getValue(v13_ .. ".zAlignment#speedScale", 1)
		v_u_10_.zAlignment.moveBackDistance = self.xmlFile:getValue(v13_ .. ".zAlignment#moveBackDistance", 2)
		v_u_10_.zAlignment.referenceNode = self.xmlFile:getValue(v13_ .. ".zAlignment#referenceNode", nil, self.components, self.i3dMappings)
		v_u_10_.yAlignment = {}
		v_u_10_.yAlignment.movingToolNode = self.xmlFile:getValue(v13_ .. ".yAlignment#movingToolNode", nil, self.components, self.i3dMappings)
		v_u_10_.yAlignment.speedScale = self.xmlFile:getValue(v13_ .. ".yAlignment#speedScale", 1)
		v_u_10_.yAlignment.referenceNode = self.xmlFile:getValue(v13_ .. ".yAlignment#referenceNode", nil, self.components, self.i3dMappings)
		v_u_10_.treeMarker = TargetTreeMarker.new(self, self.rootNode)
		v_u_10_.treeMarker:loadFromXML(self.xmlFile, v13_ .. ".treeMarker", self.baseDirectory)
		v_u_10_.treeMarker.cutColor = { v_u_10_.treeMarker.color[1], v_u_10_.treeMarker.color[2], v_u_10_.treeMarker.color[3] }
		v_u_10_.treeMarker.targetColor = self.xmlFile:getValue(v13_ .. ".treeMarker#targetColor", "2 2 0", true)
		v_u_10_.treeMarker.tooThickColor = self.xmlFile:getValue(v13_ .. ".treeMarker#tooThickColor", "2 0 0", true)
		v_u_10_.treeMarker.treeOffset = self.xmlFile:getValue(v13_ .. ".treeMarker#treeOffset", 0.025)
		v_u_10_.requiresEasyArmControl = self.xmlFile:getValue(v13_ .. "#requiresEasyArmControl", true)
		v_u_10_.foldMinLimit = self.xmlFile:getValue(v13_ .. "#foldMinLimit", 0)
		v_u_10_.foldMaxLimit = self.xmlFile:getValue(v13_ .. "#foldMaxLimit", 1)
		v_u_10_.returnPositionNode = self.xmlFile:getValue(v13_ .. "#returnPositionNode", nil, self.components, self.i3dMappings)
		v_u_10_.pendingArmReturn = false
		if v_u_10_.xAlignment.offset == nil and (v_u_10_.yAlignment.referenceNode ~= nil and v_u_10_.xAlignment.movingToolNode ~= nil) then
			local v17_, _, _ = localToLocal(v_u_10_.yAlignment.referenceNode, v_u_10_.xAlignment.movingToolNode, 0, 0, 0)
			v_u_10_.xAlignment.offset = -v17_
		end
		v_u_10_.controlInputLastValue = 0
		v_u_10_.controlInputTimer = 0
		v_u_10_.invalidTreeReason = AutomaticArmControlHarvester.INVALID_REASON_NONE
		v_u_10_.dirtyFlag = self:getNextDirtyFlag()
		if Platform.gameplay.automaticVehicleControl then
			SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", AutomaticArmControlHarvester)
			return
		end
	end
end

-- Local values: spec, i, alignmentNode
function AutomaticArmControlHarvester:onPostLoad(savegame)
	local v19_ = self.spec_automaticArmControlHarvester
	if v19_.xAlignment.movingToolNode ~= nil then
		v19_.xAlignment.movingTool = self:getMovingToolByNode(v19_.xAlignment.movingToolNode)
	end
	if v19_.zAlignment.movingToolNode ~= nil then
		v19_.zAlignment.movingTool = self:getMovingToolByNode(v19_.zAlignment.movingToolNode)
	end
	if v19_.yAlignment.movingToolNode ~= nil then
		v19_.yAlignment.movingTool = self:getMovingToolByNode(v19_.yAlignment.movingToolNode)
	end
	for v20_ = #v19_.alignmentNodes, 1, -1 do
		local v21_ = v19_.alignmentNodes[v20_]
		v21_.movingTool = self:getMovingToolByNode(v21_.movingToolNode)
		if v21_.movingTool == nil then
			table.remove(v19_.alignmentNodes, v20_)
		end
	end
end

-- Local values: spec
function AutomaticArmControlHarvester:onDelete()
	local v23_ = self.spec_automaticArmControlHarvester
	if v23_.treeMarker ~= nil then
		v23_.treeMarker:delete()
	end
end

-- Local values: spec
function AutomaticArmControlHarvester:onReadUpdateStream(streamId, timestamp, connection)
	local v27_ = self.spec_automaticArmControlHarvester
	if v27_.treeDetectionNode ~= nil then
		if connection:getIsServer() then
			if streamReadBool(streamId) then
				v27_.foundValidTargetServer = streamReadBool(streamId)
			end
		elseif streamReadBool(streamId) then
			v27_.controlInputLastValue = streamReadBool(streamId) and 1 or 0
			v27_.controlInputTimer = 250
			return
		end
	end
end

-- Local values: spec
function AutomaticArmControlHarvester:onWriteUpdateStream(streamId, connection, dirtyMask)
	local v32_ = self.spec_automaticArmControlHarvester
	if v32_.treeDetectionNode ~= nil then
		if connection:getIsServer() then
			local v33_ = streamWriteBool
			local v34_ = v32_.dirtyFlag
			if v33_(streamId, bit32.band(dirtyMask, v34_) ~= 0) then
				streamWriteBool(streamId, v32_.controlInputLastValue ~= 0)
				return
			end
		else
			local v35_ = streamWriteBool
			local v36_ = v32_.dirtyFlag
			if v35_(streamId, bit32.band(dirtyMask, v36_) ~= 0) then
				streamWriteBool(streamId, v32_.foundValidTargetServer)
			end
		end
	end
end

-- Local values: spec, foundValidTarget, hasSplitShape, hasValidRadius, showTargetMarker, bestTreeId, invalidTreeId, invalidTreeReason, wx, wy, wz, x, y, z, dx, dy, dz, radius, color, wx, wy, wz, x, y, z, dx, dy, dz, radius, i, x, y, z, targetFound, tx, ty, tz
function AutomaticArmControlHarvester:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v40_ = self.spec_automaticArmControlHarvester
	v40_.invalidTreeReason = AutomaticArmControlHarvester.INVALID_REASON_NONE
	local v41_ = false
	local v42_ = false
	if self:getIsAutoTreeAlignmentAllowed() then
		local v43_, v44_, v45_ = self:getBestTreeToAutoAlign(v40_.treeDetectionNode, v40_.foundTrees)
		if v43_ == nil then
			if v44_ ~= nil then
				local v46_, v47_, v48_ = getWorldTranslation(v44_)
				local v49_ = getTerrainHeightAtWorldPos(g_terrainNode, v46_, v47_, v48_) + v40_.treeDetectionNodeCutHeight + v40_.treeDetectionNodeCutHeightSafetyOffset
				local v50_ = math.max(v47_, v49_)
				local v51_, v52_, v53_, v54_, v55_, v56_, v57_ = SplitShapeUtil.getTreeOffsetPosition(v44_, v46_, v50_, v48_, 3)
				if v51_ ~= nil then
					v40_.treeMarker:setPosition(v51_, v52_, v53_, v54_, v55_, v56_, v57_ + v40_.treeMarker.treeOffset, 0)
					v40_.treeMarker:setColor(v40_.treeMarker.tooThickColor[1], v40_.treeMarker.tooThickColor[2], v40_.treeMarker.tooThickColor[3], false)
					v40_.invalidTreeReason = v45_
					v42_ = true
				end
			end
		else
			local v58_, v59_, v60_ = getWorldTranslation(v43_)
			local v61_ = getTerrainHeightAtWorldPos(g_terrainNode, v58_, v59_, v60_) + v40_.treeDetectionNodeCutHeight + v40_.treeDetectionNodeCutHeightSafetyOffset
			local v62_ = math.max(v59_, v61_)
			local v63_, v64_, v65_, v66_, v67_, v68_, v69_ = SplitShapeUtil.getTreeOffsetPosition(v43_, v58_, v62_, v60_, 3)
			if v63_ ~= nil then
				v40_.treeMarker:setPosition(v63_, v64_, v65_, v66_, v67_, v68_, v69_ + v40_.treeMarker.treeOffset, 0)
				local v70_, v71_ = self:getAutoAlignTreeMarkerState(v69_)
				if v70_ then
					v40_.treeMarker:setColor(v40_.treeMarker.cutColor[1], v40_.treeMarker.cutColor[2], v40_.treeMarker.cutColor[3], false)
				else
					local v72_ = v71_ and v40_.treeMarker.targetColor or v40_.treeMarker.tooThickColor
					if v40_.state == AutomaticArmControlHarvester.STATE_NONE then
						v40_.treeMarker:setColor(v72_[1], v72_[2], v72_[3], false)
					else
						v40_.treeMarker:setColor(v72_[1], v72_[2], v72_[3], true)
					end
				end
				v40_.lastRadius = v69_
				local v73_ = v40_.lastTargetTrans
				local v74_ = v40_.lastTargetTrans
				local v75_ = v40_.lastTargetTrans
				v73_[1] = v63_
				v74_[2] = v64_
				v75_[3] = v65_
				v41_ = true
				v42_ = true
			end
		end
		for v76_ = #v40_.foundTrees, 1, -1 do
			v40_.foundTrees[v76_] = nil
		end
		if not Platform.gameplay.automaticVehicleControl and v40_.state ~= AutomaticArmControlHarvester.STATE_NONE then
			local v77_ = v40_.foundTrees
			table.insert(v77_, v43_)
		end
		local v78_, v79_, v80_ = getWorldTranslation(v40_.treeDetectionNode)
		overlapSphereAsync(v78_, v79_, v80_, v40_.treeDetectionNodeMaxRadius, "onTreeAutoOverlapCallback", self, CollisionFlag.TREE, false, false, true, false)
	end
	if self.isClient then
		local v81_ = v40_.foundValidTargetServer
		if v81_ then
			if not v41_ then
				isActiveForInputIgnoreSelection = v41_
			end
		else
			isActiveForInputIgnoreSelection = v81_
		end
		local v82_ = v40_.treeMarker
		if isActiveForInputIgnoreSelection or v42_ then
			v42_ = g_woodCuttingMarkerEnabled
		end
		v82_:setIsActive(v42_)
		AutomaticArmControlHarvester.updateActionEvents(self, isActiveForInputIgnoreSelection)
	end
	if self.isServer then
		if v41_ ~= v40_.lastFoundValidTarget then
			v40_.foundValidTargetServer = v41_
			v40_.lastFoundValidTarget = v41_
			self:raiseDirtyFlags(v40_.dirtyFlag)
			v40_.state = AutomaticArmControlHarvester.STATE_NONE
		end
		if Platform.gameplay.automaticVehicleControl then
			if self:getIsTurnedOn() then
				if v41_ and v40_.state ~= AutomaticArmControlHarvester.STATE_FINISHED then
					self:doTreeArmAlignment(v40_.lastTargetTrans[1], v40_.lastTargetTrans[2], v40_.lastTargetTrans[3], 1)
				end
			elseif v40_.pendingArmReturn then
				if v40_.returnPositionNode == nil then
					v40_.pendingArmReturn = false
				else
					local v83_, v84_, v85_ = getWorldTranslation(v40_.returnPositionNode)
					self:doTreeArmAlignment(v83_, v84_, v85_, -1)
					if v40_.state == AutomaticArmControlHarvester.STATE_FINISHED then
						v40_.pendingArmReturn = false
					end
				end
			end
		end
		if v40_.controlInputTimer > 0 then
			v40_.controlInputTimer = v40_.controlInputTimer - dt
			if v40_.controlInputTimer <= 0 then
				v40_.controlInputLastValue = 0
				v40_.controlInputTimer = 0
			end
			self:setTreeArmAlignmentInput(v40_.controlInputLastValue)
		end
	end
end

-- Local values: spec, _, actionEventId
function AutomaticArmControlHarvester:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v88_ = self.spec_automaticArmControlHarvester
		self:clearActionEventsTable(v88_.actionEvents)
		if isActiveForInputIgnoreSelection then
			local _, v89_ = self:addPoweredActionEvent(v88_.actionEvents, InputAction.TREE_AUTOMATIC_ALIGN, self, AutomaticArmControlHarvester.actionEvent, true, false, true, true, nil)
			g_inputBinding:setActionEventTextPriority(v89_, GS_PRIO_VERY_HIGH)
			AutomaticArmControlHarvester.updateActionEvents(self, false)
		end
	end
end

function AutomaticArmControlHarvester:actionEvent(actionName, inputValue, callbackState, isAnalog)
	self:setTreeArmAlignmentInput(inputValue)
end

-- Local values: spec, actionEvent
function AutomaticArmControlHarvester:updateActionEvents(state)
	local v94_ = self.spec_automaticArmControlHarvester.actionEvents[InputAction.TREE_AUTOMATIC_ALIGN]
	if v94_ ~= nil then
		g_inputBinding:setActionEventActive(v94_.actionEventId, state)
	end
end

-- Local values: spec, actionController
function AutomaticArmControlHarvester:onRootVehicleChanged(rootVehicle)
	local v_u_97_ = self.spec_automaticArmControlHarvester
	local v98_ = rootVehicle.actionController
	if v98_ == nil then
		if v_u_97_.controlledAction ~= nil then
			v_u_97_.controlledAction:remove()
			v_u_97_.controlledAction = nil
		end
		return
	elseif v_u_97_.controlledAction == nil then
		v_u_97_.controlledAction = v98_:registerAction("automaticArmControlHarvester", nil, 4)
		v_u_97_.controlledAction:setCallback(self, AutomaticArmControlHarvester.actionControllerEvent)
		v_u_97_.controlledAction:setFinishedFunctions(self, function(self)
			-- upvalues: (copy) v_u_97_
			return not v_u_97_.pendingArmReturn
		end, true, true)
		v_u_97_.controlledAction:setActionIcons("WOOD_SAW", "WOOD_SAW", true)
	else
		v_u_97_.controlledAction:updateParent(v98_)
	end
end

-- Local values: spec
function AutomaticArmControlHarvester:actionControllerEvent(direction)
	local v101_ = self.spec_automaticArmControlHarvester
	if direction < 0 then
		v101_.pendingArmReturn = true
	end
	v101_.state = AutomaticArmControlHarvester.STATE_NONE
	return true
end

function AutomaticArmControlHarvester.getSupportsAutoTreeAlignment(self)
	return false
end

-- Local values: spec, isSupported, i, childVehicle, time
function AutomaticArmControlHarvester:getIsAutoTreeAlignmentAllowed()
	local v103_ = self.spec_automaticArmControlHarvester
	if self.getIsControlled ~= nil and not self:getIsControlled() then
		return false
	end
	if v103_.requiresEasyArmControl and (self.spec_cylindered.easyArmControl == nil or not self.spec_cylindered.easyArmControl.state) then
		return false
	end
	if not self:getSupportsAutoTreeAlignment() then
		local v104_ = false
		for v105_ = 1, #self.childVehicles do
			local v106_ = self.childVehicles[v105_]
			if v106_ ~= self and (v106_.getSupportsAutoTreeAlignment ~= nil and v106_:getSupportsAutoTreeAlignment()) then
				v104_ = true
				break
			end
		end
		if not v104_ then
			return false
		end
	end
	if self.getFoldAnimTime ~= nil then
		local v107_ = self:getFoldAnimTime()
		if v107_ < v103_.foldMinLimit or v103_.foldMaxLimit < v107_ then
			return false
		end
	end
	return true
end

function AutomaticArmControlHarvester:getAutoAlignHasValidTree(radius)
	return false, false
end

-- Local values: splitShapeFound, hasValidRadius, i, childVehicle, _splitShapeFound, _hasValidRadius
function AutomaticArmControlHarvester:getAutoAlignTreeMarkerState(foundRadius, checkChildren)
	local v111_, v112_ = self:getAutoAlignHasValidTree(foundRadius)
	if v111_ then
		return v111_, v112_
	end
	if checkChildren ~= false then
		for v113_ = 1, #self.childVehicles do
			local v114_ = self.childVehicles[v113_]
			if v114_ ~= self and v114_.getAutoAlignTreeMarkerState ~= nil then
				local v115_, v116_ = v114_:getAutoAlignTreeMarkerState(foundRadius, false)
				if v115_ then
					return v115_, v116_
				end
				v112_ = v112_ or v116_
			end
		end
	end
	return false, v112_
end

-- Local values: spec
function AutomaticArmControlHarvester:setTreeArmAlignmentInput(inputValue)
	local v119_ = self.spec_automaticArmControlHarvester
	if self.isServer then
		if inputValue > 0 and (v119_.state ~= AutomaticArmControlHarvester.STATE_FINISHED and v119_.foundValidTargetServer) then
			self:doTreeArmAlignment(v119_.lastTargetTrans[1], v119_.lastTargetTrans[2], v119_.lastTargetTrans[3], 1)
			return
		end
		if inputValue == 0 then
			v119_.state = AutomaticArmControlHarvester.STATE_NONE
			return
		end
	else
		v119_.controlInputLastValue = inputValue
		if inputValue > 0 then
			self:raiseDirtyFlags(v119_.dirtyFlag)
		end
	end
end

-- Local values: spec, zAlignmentReferenceNode, yAlignmentReferenceNode, xAlignmentOffset, i, childVehicle, _zAlignmentReferenceNode, _yAlignmentReferenceNode, _xAlignmentOffset, _, yOffset, x, y, z, dx, dy, dz, length, ltx, lty, ltz, distance, angle, curRot, move, _, _, lz, _, _, targetZ, offset, curX, curY, curZ, th, offset
function AutomaticArmControlHarvester:doTreeArmAlignment(tx, ty, tz, direction)
	local v125_ = self.spec_automaticArmControlHarvester
	if AutomaticArmControlHarvester.prepareAlignment(self, direction) then
		if v125_.state == AutomaticArmControlHarvester.STATE_NONE then
			v125_.state = AutomaticArmControlHarvester.NEXT_STATE[direction][v125_.state]
		end
		local v126_ = v125_.zAlignment.referenceNode
		local v127_ = v125_.yAlignment.referenceNode
		local v128_ = v125_.xAlignment.offset or 0
		for v129_ = 1, #self.childVehicles do
			local v130_ = self.childVehicles[v129_]
			if v130_ ~= self and v130_.getTreeAutomaticOverwrites ~= nil then
				if not AutomaticArmControlHarvester.prepareAlignment(v130_, direction) then
					return
				end
				local v131_, v132_, v133_ = v130_:getTreeAutomaticOverwrites()
				v126_ = v126_ or v131_
				v127_ = v127_ or v132_
				if v133_ ~= nil then
					v128_ = v128_ + v133_
				end
			end
		end
		if v125_.xAlignment.movingTool ~= nil and (v125_.state ~= AutomaticArmControlHarvester.STATE_FINISHED and v125_.state ~= AutomaticArmControlHarvester.STATE_MOVE_BACK) then
			local v134_
			if v125_.xAlignment.referenceNode == nil then
				v134_ = 0
			else
				local v135_, v136_
				v135_, v134_, v136_ = localToLocal(v125_.xAlignment.referenceNode, v125_.xAlignment.movingTool.node, 0, 0, 0)
			end
			local v137_, v138_, v139_ = worldToLocal(v125_.xAlignment.movingTool.node, tx, ty, tz)
			local v140_, v141_, v142_ = worldDirectionToLocal(v125_.xAlignment.movingTool.node, 0, 1, 0)
			local v143_
			if math.abs(v141_) > 0.001 then
				v143_ = v138_ / v141_ - v134_
			else
				v143_ = -v134_
			end
			local v144_ = v137_ - v140_ * v143_
			local _ = v138_ - v141_ * v143_
			local v145_ = v139_ - v142_ * v143_
			local v146_ = MathUtil.vector2Length(v144_, v145_)
			local v147_ = (v144_ + (v128_ or 0)) / v146_
			local v148_ = math.atan(v147_) * v125_.xAlignment.speedScale
			local v149_ = v125_.xAlignment.movingTool.curRot[v125_.xAlignment.movingTool.rotationAxis]
			local v150_ = AutomaticArmControlHarvester.calculateMovingToolTargetMove(self, v125_.xAlignment.movingTool, v149_ + v148_)
			if v150_ == 0 then
				if math.abs(v148_) < v125_.xAlignment.threshold and v125_.state == AutomaticArmControlHarvester.STATE_ALIGN_X then
					v125_.state = AutomaticArmControlHarvester.NEXT_STATE[direction][v125_.state]
				end
			else
				v125_.xAlignment.movingTool.externalMove = v150_
			end
		end
		if v125_.zAlignment.movingTool ~= nil and v126_ ~= nil then
			local _, _, v151_ = worldToLocal(v125_.treeDetectionNode, tx, ty, tz)
			local _, _, v152_ = localToLocal(v126_, v125_.treeDetectionNode, 0, 0, 0)
			local v153_ = 0
			if v125_.state == AutomaticArmControlHarvester.STATE_MOVE_BACK then
				v153_ = v152_ - (v151_ - v125_.lastRadius - v125_.zAlignment.moveBackDistance)
				if v153_ < v125_.zAlignment.moveBackDistance * 0.5 then
					v125_.state = AutomaticArmControlHarvester.NEXT_STATE[direction][v125_.state]
				end
			elseif v125_.state == AutomaticArmControlHarvester.STATE_ALIGN_Z then
				v153_ = v152_ - (v151_ - v125_.lastRadius)
				if math.abs(v153_) < 0.03 then
					v125_.state = AutomaticArmControlHarvester.NEXT_STATE[direction][v125_.state]
				end
			end
			if math.abs(v153_) > 0.03 then
				v125_.zAlignment.movingTool.externalMove = -(v153_ + 0.5 * math.sign(v153_)) * v125_.zAlignment.speedScale
			else
				v125_.zAlignment.movingTool.externalMove = 0
			end
		end
		if v125_.yAlignment.movingTool ~= nil and (v127_ ~= nil and v125_.state == AutomaticArmControlHarvester.STATE_ALIGN_Z) then
			local v154_, v155_, v156_ = getWorldTranslation(v127_)
			local v157_ = getTerrainHeightAtWorldPos(g_terrainNode, v154_, v155_, v156_)
			local v158_ = ty - v125_.treeDetectionNodeCutHeightSafetyOffset
			local v159_ = v157_ + v125_.treeDetectionNodeCutHeight
			local v160_ = math.max(v158_, v159_) - v155_
			if math.abs(v160_) > 0.03 then
				v125_.yAlignment.movingTool.externalMove = (v160_ + 0.5 * math.sign(v160_)) * v125_.yAlignment.speedScale
				return
			end
			v125_.yAlignment.movingTool.externalMove = 0
		end
	end
end

-- Local values: durationToStop, rotSpeed, stopRot, deceleration, _, threshold, state, stopState, targetState, curRot, move, offset
function AutomaticArmControlHarvester:calculateMovingToolTargetMove(movingTool, targetRot)
	local v164_ = movingTool.lastRotSpeed / movingTool.rotAcceleration
	local v165_ = movingTool.lastRotSpeed
	local v166_ = movingTool.curRot[movingTool.rotationAxis]
	local v167_ = -movingTool.rotAcceleration * math.sign(v164_)
	for _ = 1, math.abs(v164_) do
		v165_ = v165_ + v167_
		v166_ = v166_ + v165_
	end
	local v168_ = 0.001
	local v169_, v170_
	if movingTool.rotMin == nil or movingTool.rotMax == nil then
		local v171_ = movingTool.curRot[movingTool.rotationAxis]
		v169_ = MathUtil.normalizeRotationForShortestPath(v171_, targetRot)
		v170_ = MathUtil.normalizeRotationForShortestPath(v166_, targetRot)
		v168_ = 0.0001
	else
		v169_ = Cylindered.getMovingToolState(self, movingTool)
		v170_ = MathUtil.inverseLerp(movingTool.rotMin, movingTool.rotMax, v166_)
		targetRot = MathUtil.inverseLerp(movingTool.rotMin, movingTool.rotMax, targetRot)
	end
	local v172_
	if targetRot < v169_ then
		local v173_ = movingTool.rotSpeed
		v172_ = -math.sign(v173_)
		if v170_ < targetRot then
			return 0
		end
	else
		local v174_ = movingTool.rotSpeed
		v172_ = math.sign(v174_)
		if targetRot < v170_ then
			return 0
		end
	end
	local v175_ = targetRot - v169_
	return math.abs(v175_) < v168_ and 0 or v172_
end

-- Local values: spec, spec_woodHarvester, i, alignmentNode, move
function AutomaticArmControlHarvester:prepareAlignment(direction)
	local v178_ = self.spec_automaticArmControlHarvester
	if direction == 1 then
		if self.getIsTurnedOn ~= nil and (not self:getIsTurnedOn() and self:getCanBeTurnedOn()) then
			self:setIsTurnedOn(true)
		end
		local v179_ = self.spec_woodHarvester
		if v179_ ~= nil and (v179_.headerJointTilt ~= nil and v179_.headerJointTilt.state) then
			self:setWoodHarvesterTiltState(false)
		end
	end
	for v180_ = 1, #v178_.alignmentNodes do
		local v181_ = v178_.alignmentNodes[v180_]
		local v182_ = v181_.rotation == nil and 0 or AutomaticArmControlHarvester.calculateMovingToolTargetMove(self, v181_.movingTool, v181_.rotation)
		if v182_ ~= 0 then
			v181_.movingTool.externalMove = v182_
			if v181_.isPrerequisite then
				return false
			end
		end
	end
	return true
end

-- Local values: spec
function AutomaticArmControlHarvester:getIsAutomaticAlignmentActive()
	local v184_ = self.spec_automaticArmControlHarvester
	local v185_
	if v184_.state == AutomaticArmControlHarvester.STATE_NONE then
		v185_ = false
	else
		v185_ = v184_.state ~= AutomaticArmControlHarvester.STATE_FINISHED
	end
	return v185_
end

-- Local values: spec
function AutomaticArmControlHarvester:getAutomaticAlignmentCurrentTarget()
	local v187_ = self.spec_automaticArmControlHarvester
	if v187_.lastFoundValidTarget then
		return v187_.lastTargetTrans[1], v187_.lastTargetTrans[2], v187_.lastTargetTrans[3], v187_.lastRadius
	else
		return nil, nil, nil, nil
	end
end

function AutomaticArmControlHarvester:getAutomaticAlignmentInvalidTreeReason()
	return self.spec_automaticArmControlHarvester.invalidTreeReason
end

-- Local values: minFactor, minFactorTreeId, invalidTreeId, invalidTreeReason, i, treeId, distance, x, _, z, angle, wx, _, wz, factor
function AutomaticArmControlHarvester:getBestTreeToAutoAlign(referenceNode, trees)
	local v192_ = math.huge
	local v193_ = nil
	local v194_ = nil
	local v195_ = nil
	for v196_ = 1, #trees do
		local v197_ = trees[v196_]
		if entityExists(v197_) and (getRigidBodyType(v197_) == RigidBodyType.STATIC and (getHasClassId(v197_, ClassIds.MESH_SPLIT_SHAPE) and not getIsSplitShapeSplit(v197_))) then
			local v198_ = calcDistanceFrom(referenceNode, v197_)
			local v199_, _, v200_ = localToLocal(v197_, referenceNode, 0, 0, 0)
			local v201_, v202_ = MathUtil.vector2Normalize(v199_, v200_)
			local v203_ = MathUtil.getYRotationFromDirection(v201_, v202_)
			if math.abs(v203_) < self.spec_automaticArmControlHarvester.treeDetectionNodeMaxAngle then
				if g_splitShapeManager:getSplitShapeAllowsHarvester(v197_) then
					local v204_, _, v205_ = getWorldTranslation(v197_)
					if WoodHarvester.getCanSplitShapeBeAccessed(self, v204_, v205_, v197_) then
						local v206_ = math.deg(v203_)
						local v207_ = math.abs(v206_) + v198_ * 2
						if v207_ < v192_ then
							v193_ = v197_
							v192_ = v207_
						end
					else
						v195_ = AutomaticArmControlHarvester.INVALID_REASON_NO_ACCESS
						v194_ = v197_
					end
				else
					v195_ = AutomaticArmControlHarvester.INVALID_REASON_WRONG_TYPE
					v194_ = v197_
				end
			end
		end
	end
	return v193_, v194_, v195_
end
function AutomaticArmControlHarvester.onTreeAutoOverlapCallback(p208_, p209_, ...)
	if not p208_.isDeleted and (p209_ ~= 0 and (getHasClassId(p209_, ClassIds.SHAPE) and (getUserAttribute(p209_, "isTreeStump") ~= true and g_splitShapeManager:getSplitTypeByIndex(getSplitType(p209_)) ~= nil))) then
		local v210_ = p208_.spec_automaticArmControlHarvester
		local v211_, _, v212_ = getWorldTranslation(v210_.treeDetectionNode)
		local v213_, _, v214_ = getWorldTranslation(p209_)
		local v215_ = MathUtil.vector2Length(v211_ - v213_, v212_ - v214_)
		if v210_.treeDetectionNodeMinRadius < v215_ and v215_ < v210_.treeDetectionNodeMaxRadius then
			local v216_ = v210_.foundTrees
			table.insert(v216_, p209_)
		end
	end
end

-- Local values: spec
function AutomaticArmControlHarvester:getTreeAutomaticOverwrites()
	local v218_ = self.spec_automaticArmControlHarvester
	return v218_.zAlignment.referenceNode, v218_.yAlignment.referenceNode, v218_.xAlignment.offset
end

-- Local values: ox, oy, oz, range, i, a1, a2, c, s, x1, y1, z1, x2, y2, z2
function AutomaticArmControlHarvester.drawDebugCircleRange(node, radius, steps, minRot, maxRot)
	local v224_ = maxRot - minRot
	local v225_ = 0
	local v226_ = 0
	for v227_ = 1, steps do
		local v228_ = 1.5707963267948966 + minRot + (v227_ - 1) / steps * v224_
		local v229_ = 1.5707963267948966 + minRot + v227_ / steps * v224_
		local v230_ = math.cos(v228_) * radius
		local v231_ = math.sin(v228_) * radius
		local v232_, v233_, v234_ = localToWorld(node, v225_ + v230_, 0, v226_ + v231_)
		local v235_ = math.cos(v229_) * radius
		local v236_ = math.sin(v229_) * radius
		local v237_, v238_, v239_ = localToWorld(node, v225_ + v235_, 0, v226_ + v236_)
		drawDebugLine(v232_, v233_, v234_, 1, 0, 0, v237_, v238_, v239_, 1, 0, 0)
	end
end
