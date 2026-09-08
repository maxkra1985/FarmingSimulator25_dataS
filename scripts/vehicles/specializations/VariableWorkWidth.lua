source("dataS/scripts/vehicles/specializations/events/VariableWorkWidthStateEvent.lua")
VariableWorkWidth = {}
VariableWorkWidth.SEND_NUM_BITS = 6
source("dataS/scripts/gui/hud/extensions/VariableWorkWidthHUDExtension.lua")

function VariableWorkWidth.prerequisitesPresent(self)
	return true
end
function VariableWorkWidth.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("variableWorkWidth", g_i18n:getText("configuration_workingWidth"), "variableWorkWidth", VehicleConfigurationItem)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("VariableWorkWidth")
	VariableWorkWidth.registerSectionPaths(v1_, "vehicle.variableWorkWidth")
	VariableWorkWidth.registerSectionPaths(v1_, "vehicle.variableWorkWidth.variableWorkWidthConfigurations.variableWorkWidthConfiguration(?)")
	v1_:register(XMLValueType.INT, "vehicle.variableWorkWidth#widthReferenceWorkAreaIndex", "Width of this work area is used as reference for the HUD display", 1)
	v1_:register(XMLValueType.INT, "vehicle.variableWorkWidth#defaultStateLeft", "Default state on left side", "Max. possible state")
	v1_:register(XMLValueType.INT, "vehicle.variableWorkWidth#defaultStateRight", "Default state on right side", "Max. possible state")
	v1_:register(XMLValueType.BOOL, "vehicle.variableWorkWidth#aiKeepCurrentWidth", "Defines if the ai should keep the current width or change it", false)
	v1_:register(XMLValueType.INT, "vehicle.variableWorkWidth#aiStateLeft", "AI state on left side", "Max. possible state")
	v1_:register(XMLValueType.INT, "vehicle.variableWorkWidth#aiStateRight", "AI state on right side", "Max. possible state")
	v1_:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_KEY .. ".section#index", "Section index (Section needs to be active to activate workArea)")
	v1_:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".section#index", "Section index (Section needs to be active to activate workArea)")
	v1_:setXMLSpecializationType()
	local v2_ = Vehicle.xmlSchemaSavegame
	v2_:register(XMLValueType.INT, "vehicles.vehicle(?).variableWorkWidth#leftSide", "Left side section states", "Max. state")
	v2_:register(XMLValueType.INT, "vehicles.vehicle(?).variableWorkWidth#rightSide", "Right side section states", "Max. state")
end

function VariableWorkWidth.registerSectionPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. ".sections.section(?)#isLeft", "Section side", false)
	schema:register(XMLValueType.BOOL, basePath .. ".sections.section(?)#isCenter", "Is center section", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".sections.section(?)#width", "Section max. width as percentage [0..1]", "Automatically calculated")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".sections.section(?)#maxWidthNode", "Position of this node defines max. width of this section")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".sections.section(?).effect(?)#node", "Effect to deactivate/activate")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".sectionNodes.sectionNode(?)#node", "Section node")
	schema:register(XMLValueType.BOOL, basePath .. ".sectionNodes.sectionNode(?)#isLeft", "Section node")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".sectionNodes.sectionNode(?)#minTrans", "Min. translation")
	schema:register(XMLValueType.FLOAT, basePath .. ".sectionNodes.sectionNode(?)#minTransX", "Min. X translation")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".sectionNodes.sectionNode(?)#maxTrans", "Max. translation")
	schema:register(XMLValueType.FLOAT, basePath .. ".sectionNodes.sectionNode(?)#maxTransX", "Max. X translation")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".sectionNodes.sectionNode(?)#minRot", "Min. rotation")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".sectionNodes.sectionNode(?)#endRot", "Max. rotation")
	schema:register(XMLValueType.INT, basePath .. ".sectionNodes.sectionNode(?)#workAreaIndex", "Work area index", 1)
end

function VariableWorkWidth.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onVariableWorkWidthSectionChanged")
end

function VariableWorkWidth.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setVariableWorkWidthActive", VariableWorkWidth.setVariableWorkWidthActive)
	SpecializationUtil.registerFunction(vehicleType, "setSectionsActive", VariableWorkWidth.setSectionsActive)
	SpecializationUtil.registerFunction(vehicleType, "setSectionNodePercentage", VariableWorkWidth.setSectionNodePercentage)
	SpecializationUtil.registerFunction(vehicleType, "updateSections", VariableWorkWidth.updateSections)
	SpecializationUtil.registerFunction(vehicleType, "updateSectionStates", VariableWorkWidth.updateSectionStates)
	SpecializationUtil.registerFunction(vehicleType, "getEffectByNode", VariableWorkWidth.getEffectByNode)
	SpecializationUtil.registerFunction(vehicleType, "getVariableWorkWidth", VariableWorkWidth.getVariableWorkWidth)
	SpecializationUtil.registerFunction(vehicleType, "getVariableWorkWidthUsage", VariableWorkWidth.getVariableWorkWidthUsage)
end

function VariableWorkWidth.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", VariableWorkWidth.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", VariableWorkWidth.getIsWorkAreaActive)
end

function VariableWorkWidth.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", VariableWorkWidth)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", VariableWorkWidth)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", VariableWorkWidth)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", VariableWorkWidth)
	SpecializationUtil.registerEventListener(vehicleType, "onAIFieldWorkerStart", VariableWorkWidth)
	SpecializationUtil.registerEventListener(vehicleType, "onAIImplementStart", VariableWorkWidth)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", VariableWorkWidth)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", VariableWorkWidth)
end

-- Local values: spec, configurationId, configKey, deleteListener, startRestriction, i, section, j, sectionNode, x, _, _, minX, maxX, sort
function VariableWorkWidth:onPostLoad(savegame)
	local v_u_11_ = self.spec_variableWorkWidth
	local v12_ = Utils.getNoNil(self.configurations.variableWorkWidth, 1)
	local v13_ = string.format("vehicle.variableWorkWidth.variableWorkWidthConfigurations.variableWorkWidthConfiguration(%d)", v12_ - 1)
	local v14_ = not self.xmlFile:hasProperty(v13_) and "vehicle.variableWorkWidth" or v13_
	local function v_u_18_(p15_, p16_)
		for v17_ = #p15_.effects, 1, -1 do
			if p15_.effects[v17_] == p16_ then
				p15_.effects[v17_] = nil
				return
			end
		end
	end
	local function v_u_20_(p19_)
		return p19_.isActive
	end
	v_u_11_.hasCenter = false
	v_u_11_.sections = {}
	v_u_11_.sectionsLeft = {}
	v_u_11_.sectionsRight = {}
	self.xmlFile:iterate(v14_ .. ".sections.section", function(_, p21_)
		-- upvalues: (copy) self, (copy) v_u_18_, (copy) v_u_20_, (copy) v_u_11_
		local v_u_22_ = {
			["isLeft"] = self.xmlFile:getValue(p21_ .. "#isLeft", false),
			["isCenter"] = self.xmlFile:getValue(p21_ .. "#isCenter", false),
			["maxWidthNode"] = self.xmlFile:getValue(p21_ .. "#maxWidthNode", nil, self.components, self.i3dMappings),
			["width"] = self.xmlFile:getValue(p21_ .. "#width"),
			["effects"] = {}
		}
		self.xmlFile:iterate(p21_ .. ".effect", function(_, p23_)
			-- upvalues: (ref) self, (ref) v_u_18_, (copy) v_u_22_, (ref) v_u_20_
			local v24_ = self.xmlFile:getValue(p23_ .. "#node", nil, self.components, self.i3dMappings)
			if v24_ ~= nil then
				local v25_ = self:getEffectByNode(v24_)
				if v25_ ~= nil then
					v25_:addDeleteListener(v_u_18_, v_u_22_, v25_)
					v25_:addStartRestriction(v_u_20_, v_u_22_)
					local v26_ = v_u_22_.effects
					table.insert(v26_, v25_)
				end
			end
		end)
		v_u_22_.isActive = true
		if v_u_22_.isLeft then
			local v27_ = v_u_11_.sectionsLeft
			table.insert(v27_, v_u_22_)
		elseif v_u_22_.isCenter then
			v_u_11_.hasCenter = true
		else
			local v28_ = v_u_11_.sectionsRight
			table.insert(v28_, v_u_22_)
		end
		local v29_ = v_u_11_.sections
		table.insert(v29_, v_u_22_)
		v_u_22_.index = #v_u_11_.sections
	end)
	v_u_11_.sectionNodes = {}
	v_u_11_.sectionNodesLeft = {}
	v_u_11_.sectionNodesRight = {}
	self.xmlFile:iterate(v14_ .. ".sectionNodes.sectionNode", function(_, p30_)
		-- upvalues: (copy) self, (copy) v_u_11_
		local v31_ = {
			["node"] = self.xmlFile:getValue(p30_ .. "#node", nil, self.components, self.i3dMappings)
		}
		if v31_.node ~= nil then
			v31_.isLeft = self.xmlFile:getValue(p30_ .. "#isLeft", false)
			v31_.startTrans = self.xmlFile:getValue(p30_ .. "#minTrans", nil, true)
			v31_.startTransX = self.xmlFile:getValue(p30_ .. "#minTransX")
			v31_.endTrans = self.xmlFile:getValue(p30_ .. "#maxTrans", nil, true)
			v31_.endTransX = self.xmlFile:getValue(p30_ .. "#maxTransX")
			v31_.startRot = self.xmlFile:getValue(p30_ .. "#minRot", nil, true)
			v31_.endRot = self.xmlFile:getValue(p30_ .. "#endRot", nil, true)
			if v31_.startTrans == nil and v31_.startTransX == nil then
				Logging.xmlWarning(self.xmlFile, "sectionNode \'%s\' needs either \'minTrans\' or \'minTransX\' set", p30_)
				return
			end
			if v31_.endTrans == nil and v31_.endTransX == nil then
				Logging.xmlWarning(self.xmlFile, "sectionNode \'%s\' needs either \'maxTrans\' or \'maxTransX\' set", p30_)
				return
			end
			v31_.workAreaIndex = self.xmlFile:getValue(p30_ .. "#workAreaIndex", 1)
			if v31_.isLeft then
				local v32_ = v_u_11_.sectionNodesLeft
				table.insert(v32_, v31_)
			else
				local v33_ = v_u_11_.sectionNodesRight
				table.insert(v33_, v31_)
			end
			local v34_ = v_u_11_.sectionNodes
			table.insert(v34_, v31_)
		end
	end)
	for v35_ = 1, #v_u_11_.sections do
		local v36_ = v_u_11_.sections[v35_]
		if v36_.maxWidthNode == nil then
			v36_.width = 0
		elseif not v36_.isCenter then
			for v37_ = 1, #v_u_11_.sectionNodes do
				local v38_ = v_u_11_.sectionNodes[v37_]
				if v38_.isLeft == v36_.isLeft then
					local v39_, _, _ = localToLocal(v36_.maxWidthNode, getParent(v38_.node), 0, 0, 0)
					local v40_ = v38_.startTransX or v38_.startTrans[1]
					local v41_ = v38_.endTransX or v38_.endTrans[1]
					local v42_ = (v39_ - v40_) / (v41_ - v40_)
					local v43_ = math.abs(v42_)
					v36_.width = math.clamp(v43_, 0, 1)
					v36_.widthAbs = v39_
					break
				end
			end
		end
		if v36_.width == nil then
			Logging.xmlWarning(self.xmlFile, "Unable to get width for section \'vehicle.variableWorkWidth.sections.section(%d)\'", v35_)
			v36_.width = 0
		end
	end
	local function v46_(p44_, p45_)
		return p44_.width < p45_.width
	end
	table.sort(v_u_11_.sectionsLeft, v46_)
	table.sort(v_u_11_.sectionsRight, v46_)
	v_u_11_.widthReferenceWorkArea = self.xmlFile:getValue("vehicle.variableWorkWidth#widthReferenceWorkAreaIndex", 1)
	v_u_11_.leftSideMax = #v_u_11_.sectionsLeft
	v_u_11_.leftSide = self.xmlFile:getValue("vehicle.variableWorkWidth#defaultStateLeft", v_u_11_.leftSideMax)
	v_u_11_.rightSideMax = #v_u_11_.sectionsRight
	v_u_11_.rightSide = self.xmlFile:getValue("vehicle.variableWorkWidth#defaultStateRight", v_u_11_.rightSideMax)
	v_u_11_.aiKeepCurrentWidth = self.xmlFile:getValue("vehicle.variableWorkWidth#aiKeepCurrentWidth", false)
	v_u_11_.aiStateLeft = self.xmlFile:getValue("vehicle.variableWorkWidth#aiStateLeft", v_u_11_.leftSideMax)
	v_u_11_.aiStateRight = self.xmlFile:getValue("vehicle.variableWorkWidth#aiStateRight", v_u_11_.rightSideMax)
	v_u_11_.minSideState = v_u_11_.hasCenter and 0 or 1
	if savegame ~= nil and not savegame.resetVehicles then
		local v47_ = savegame.xmlFile:getValue(savegame.key .. ".variableWorkWidth#leftSide", v_u_11_.leftSide)
		local v48_ = v_u_11_.leftSideMax
		v_u_11_.leftSide = math.min(v47_, v48_)
		local v49_ = savegame.xmlFile:getValue(savegame.key .. ".variableWorkWidth#rightSide", v_u_11_.rightSide)
		local v50_ = v_u_11_.rightSideMax
		v_u_11_.rightSide = math.min(v49_, v50_)
	end
	self:updateSections()
	v_u_11_.drawInputHelp = false
	v_u_11_.hasSections = #v_u_11_.sections > 0
	v_u_11_.isActive = v_u_11_.hasSections
	if v_u_11_.hasSections then
		v_u_11_.hudExtension = VariableWorkWidthHUDExtension.new(self)
	else
		SpecializationUtil.removeEventListener(self, "onReadStream", VariableWorkWidth)
		SpecializationUtil.removeEventListener(self, "onWriteStream", VariableWorkWidth)
	end
	if not (self.isClient and v_u_11_.hasSections) then
		SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", VariableWorkWidth)
	end
end

-- Local values: spec
function VariableWorkWidth:onDelete()
	local v52_ = self.spec_variableWorkWidth
	if v52_.hudExtension ~= nil then
		g_currentMission.hud:removeInfoExtension(v52_.hudExtension)
		v52_.hudExtension:delete()
	end
end

-- Local values: spec
function VariableWorkWidth:saveToXMLFile(xmlFile, key, usedModNames)
	local v56_ = self.spec_variableWorkWidth
	if v56_.hasSections then
		xmlFile:setValue(key .. "#leftSide", v56_.leftSide)
		xmlFile:setValue(key .. "#rightSide", v56_.rightSide)
	end
end

-- Local values: leftSide, rightSide
function VariableWorkWidth:onReadStream(streamId, connection)
	self:setSectionsActive(streamReadUIntN(streamId, VariableWorkWidth.SEND_NUM_BITS), streamReadUIntN(streamId, VariableWorkWidth.SEND_NUM_BITS), true)
end

-- Local values: spec
function VariableWorkWidth:onWriteStream(streamId, connection)
	local v61_ = self.spec_variableWorkWidth
	streamWriteUIntN(streamId, v61_.leftSide, VariableWorkWidth.SEND_NUM_BITS)
	streamWriteUIntN(streamId, v61_.rightSide, VariableWorkWidth.SEND_NUM_BITS)
end

-- Local values: spec
function VariableWorkWidth:onDraw()
	local v63_ = self.spec_variableWorkWidth
	if v63_.hudExtension ~= nil and v63_.drawInputHelp then
		g_currentMission.hud:addInfoExtension(v63_.hudExtension)
	end
end

-- Local values: spec, _, actionEventIdLeft, _, actionEventIdRight, _, actionEventIdToggle
function VariableWorkWidth:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	local v66_ = self.spec_variableWorkWidth
	self:clearActionEventsTable(v66_.actionEvents)
	if isActiveForInputIgnoreSelection then
		if v66_.isActive then
			local _, v67_ = self:addActionEvent(v66_.actionEvents, InputAction.VARIABLE_WORK_WIDTH_LEFT, self, VariableWorkWidth.actionEventWorkWidthLeft, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v67_, GS_PRIO_HIGH)
			local _, v68_ = self:addActionEvent(v66_.actionEvents, InputAction.VARIABLE_WORK_WIDTH_RIGHT, self, VariableWorkWidth.actionEventWorkWidthRight, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v68_, GS_PRIO_HIGH)
			local _, v69_ = self:addActionEvent(v66_.actionEvents, InputAction.VARIABLE_WORK_WIDTH_TOGGLE, self, VariableWorkWidth.actionEventWorkWidthToggle, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v69_, GS_PRIO_HIGH)
			v66_.drawInputHelp = g_inputBinding:getActionEventsHasBinding(v67_) or (g_inputBinding:getActionEventsHasBinding(v68_) or g_inputBinding:getActionEventsHasBinding(v69_))
			return
		end
		v66_.drawInputHelp = false
	end
end

-- Local values: spec
function VariableWorkWidth:actionEventWorkWidthLeft(actionName, inputValue, callbackState, isAnalog)
	local v72_ = self.spec_variableWorkWidth
	self:setSectionsActive(v72_.leftSide - inputValue, v72_.rightSide)
end

-- Local values: spec
function VariableWorkWidth:actionEventWorkWidthRight(actionName, inputValue, callbackState, isAnalog)
	local v75_ = self.spec_variableWorkWidth
	self:setSectionsActive(v75_.leftSide, v75_.rightSide - inputValue)
end

-- Local values: spec, minValue, newState
function VariableWorkWidth:actionEventWorkWidthToggle(actionName, inputValue, callbackState, isAnalog)
	local v77_ = self.spec_variableWorkWidth
	local v78_ = v77_.leftSide
	local v79_ = v77_.rightSide
	local v80_ = math.min(v78_, v79_) - 1
	if v80_ < v77_.minSideState then
		local v81_ = v77_.leftSideMax
		local v82_ = v77_.rightSideMax
		v80_ = math.min(v81_, v82_)
	end
	self:setSectionsActive(v80_, v80_)
end

-- Local values: spec
function VariableWorkWidth:onAIFieldWorkerStart()
	if self.isServer then
		local v84_ = self.spec_variableWorkWidth
		if not v84_.aiKeepCurrentWidth then
			self:setSectionsActive(v84_.aiStateLeft, v84_.aiStateRight)
		end
	end
end

-- Local values: spec
function VariableWorkWidth:onAIImplementStart()
	if self.isServer then
		local v86_ = self.spec_variableWorkWidth
		if not v86_.aiKeepCurrentWidth then
			self:setSectionsActive(v86_.aiStateLeft, v86_.aiStateRight)
		end
	end
end

-- Local values: spec
function VariableWorkWidth:setVariableWorkWidthActive(isActive)
	local v89_ = self.spec_variableWorkWidth
	v89_.isActive = isActive
	if self.isServer and not isActive then
		self:setSectionsActive(v89_.leftSideMax, v89_.rightSideMax)
	end
	self:requestActionEventUpdate()
end

-- Local values: spec
function VariableWorkWidth:setSectionsActive(leftSide, rightSide, noEventSend)
	local v94_ = self.spec_variableWorkWidth
	local v95_ = v94_.leftSideMax
	local v96_ = math.clamp(leftSide, 0, v95_)
	local v97_ = v94_.rightSideMax
	local v98_ = math.clamp(rightSide, 0, v97_)
	if v94_.leftSide ~= v96_ or v94_.rightSide ~= v98_ then
		v94_.leftSide = v96_
		v94_.rightSide = v98_
		self:updateSections()
		VariableWorkWidthStateEvent.sendEvent(self, v94_.leftSide, v94_.rightSide, noEventSend)
	end
end

-- Local values: i, sectionNode, _, y, z, x
function VariableWorkWidth:setSectionNodePercentage(sectionNodes, percentage)
	local v102_ = math.min(percentage, 1)
	local v103_ = math.max(v102_, 0)
	for v104_ = 1, #sectionNodes do
		local v105_ = sectionNodes[v104_]
		if v105_.startTrans ~= nil and v105_.endTrans ~= nil then
			setTranslation(v105_.node, MathUtil.vector3ArrayLerp(v105_.startTrans, v105_.endTrans, v103_))
		end
		if v105_.startTransX ~= nil and v105_.endTransX ~= nil then
			local _, v106_, v107_ = getTranslation(v105_.node)
			local v108_ = MathUtil.lerp(v105_.startTransX, v105_.endTransX, v103_)
			setTranslation(v105_.node, v108_, v106_, v107_)
		end
		if v105_.startRot ~= nil and v105_.endRot ~= nil then
			setRotation(v105_.node, MathUtil.vector3ArrayLerp(v105_.startRot, v105_.endRot, v103_))
		end
		if v105_.workAreaIndex ~= nil then
			self:updateWorkAreaWidth(v105_.workAreaIndex)
		end
	end
end

-- Local values: spec, leftSectionWidth, rightSectionWidth
function VariableWorkWidth:updateSections()
	local v110_ = self.spec_variableWorkWidth
	self:updateSectionStates(v110_.sectionsLeft, v110_.leftSide)
	self:updateSectionStates(v110_.sectionsRight, v110_.rightSide)
	local v111_ = v110_.leftSide == 0 and 0 or v110_.sectionsLeft[v110_.leftSide].width
	self:setSectionNodePercentage(v110_.sectionNodesLeft, v111_)
	local v112_ = v110_.rightSide == 0 and 0 or v110_.sectionsRight[v110_.rightSide].width
	self:setSectionNodePercentage(v110_.sectionNodesRight, v112_)
	SpecializationUtil.raiseEvent(self, "onVariableWorkWidthSectionChanged")
end

-- Local values: i, section, j, effect
function VariableWorkWidth:updateSectionStates(sections, state)
	for v115_ = 1, #sections do
		local v116_ = sections[v115_]
		v116_.isActive = v115_ <= state
		for v117_ = 1, #v116_.effects do
			local v118_ = v116_.effects[v117_]
			if not v116_.isActive and v118_:isRunning() then
				v118_:stop()
			end
		end
	end
end

function VariableWorkWidth:getEffectByNode(node) end

-- Local values: spec, sections, maxWidth, i, section
function VariableWorkWidth:getVariableWorkWidth(isLeft)
	local v121_ = self.spec_variableWorkWidth
	local v122_ = isLeft and v121_.sectionsLeft or v121_.sectionsRight
	if #v122_ == 0 then
		return 1, 1, false
	end
	local v123_ = nil
	for v124_ = #v122_, 1, -1 do
		local v125_ = v122_[v124_]
		v123_ = v123_ or v125_.widthAbs
		if v125_.isActive then
			return v125_.widthAbs, v123_, true
		end
	end
	return 0, v123_ or 1, true
end

function VariableWorkWidth.getVariableWorkWidthUsage(self)
	return nil
end

function VariableWorkWidth:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	workArea.sectionIndex = xmlFile:getValue(key .. ".section#index")
	return superFunc(self, workArea, xmlFile, key)
end

-- Local values: section
function VariableWorkWidth:getIsWorkAreaActive(superFunc, workArea)
	if workArea.sectionIndex ~= nil then
		local v134_ = self.spec_variableWorkWidth.sections[workArea.sectionIndex]
		if v134_ ~= nil and not v134_.isActive then
			return false
		end
	end
	return superFunc(self, workArea)
end
