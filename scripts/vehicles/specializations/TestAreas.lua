TestAreas = {}
function TestAreas.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("TestAreas")
	v1_:register(XMLValueType.BOOL, WorkArea.WORK_AREA_XML_KEY .. ".testAreas#autoGenerate", "Automatically generate test areas", false)
	v1_:register(XMLValueType.NODE_INDEX, WorkArea.WORK_AREA_XML_KEY .. ".testAreas#rootNode", "Root node as reference for width")
	v1_:register(XMLValueType.NODE_INDEX, WorkArea.WORK_AREA_XML_KEY .. ".testAreas#startNode", "Left node reference for automatic calculation")
	v1_:register(XMLValueType.NODE_INDEX, WorkArea.WORK_AREA_XML_KEY .. ".testAreas#widthNode", "Right node reference for automatic calculation")
	v1_:register(XMLValueType.FLOAT, WorkArea.WORK_AREA_XML_KEY .. ".testAreas#zOffset", "Offset in Z direction", 0)
	v1_:register(XMLValueType.FLOAT, WorkArea.WORK_AREA_XML_KEY .. ".testAreas#xOffset", "Offset for both sides mirrored (negative value will shrink area, positive will increase area on both sides)", 0)
	v1_:register(XMLValueType.FLOAT, WorkArea.WORK_AREA_XML_KEY .. ".testAreas#length", "Length of area itself", 0.5)
	v1_:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_KEY .. ".testAreas#numAreas", "Number of used areas", 10)
	v1_:register(XMLValueType.FLOAT, WorkArea.WORK_AREA_XML_KEY .. ".testAreas#areaWidthScale", "Width percentage of each individual area", 0.9)
	v1_:register(XMLValueType.FLOAT, WorkArea.WORK_AREA_XML_KEY .. ".testAreas#scale", "Scale of test areas over width of work area", 1)
	v1_:register(XMLValueType.NODE_INDEX, WorkArea.WORK_AREA_XML_KEY .. ".testAreas.testArea(?)#startNode", "Start Node")
	v1_:register(XMLValueType.NODE_INDEX, WorkArea.WORK_AREA_XML_KEY .. ".testAreas.testArea(?)#widthNode", "Width Node")
	v1_:register(XMLValueType.NODE_INDEX, WorkArea.WORK_AREA_XML_KEY .. ".testAreas.testArea(?)#heightNode", "Height Node")
	v1_:register(XMLValueType.BOOL, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".testAreas#autoGenerate", "Automatically generate test areas", false)
	v1_:register(XMLValueType.NODE_INDEX, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".testAreas#rootNode", "Root node as reference for width")
	v1_:register(XMLValueType.NODE_INDEX, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".testAreas#startNode", "Left node reference for automatic calculation")
	v1_:register(XMLValueType.NODE_INDEX, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".testAreas#widthNode", "Right node reference for automatic calculation")
	v1_:register(XMLValueType.FLOAT, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".testAreas#zOffset", "Offset in Z direction", 0)
	v1_:register(XMLValueType.FLOAT, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".testAreas#xOffset", "Offset for both sides mirrored (negative value will shrink area, positive will increase area on both sides)", 0)
	v1_:register(XMLValueType.FLOAT, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".testAreas#length", "Length of area itself", 0.5)
	v1_:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".testAreas#numAreas", "Number of used areas", 10)
	v1_:register(XMLValueType.FLOAT, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".testAreas#areaWidthScale", "Width percentage of each individual area", 0.9)
	v1_:register(XMLValueType.FLOAT, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".testAreas#scale", "Scale of test areas over width of work area", 1)
	v1_:register(XMLValueType.NODE_INDEX, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".testAreas.testArea(?)#startNode", "Start Node")
	v1_:register(XMLValueType.NODE_INDEX, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".testAreas.testArea(?)#widthNode", "Width Node")
	v1_:register(XMLValueType.NODE_INDEX, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".testAreas.testArea(?)#heightNode", "Height Node")
	v1_:setXMLSpecializationType()
end

function TestAreas.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(WorkArea, specializations)
end

function TestAreas.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "readTestAreasStream", TestAreas.readTestAreasStream)
	SpecializationUtil.registerFunction(vehicleType, "writeTestAreasStream", TestAreas.writeTestAreasStream)
	SpecializationUtil.registerFunction(vehicleType, "generateTestAreasForWorkArea", TestAreas.generateTestAreasForWorkArea)
	SpecializationUtil.registerFunction(vehicleType, "calculateTestAreaDimensions", TestAreas.calculateTestAreaDimensions)
	SpecializationUtil.registerFunction(vehicleType, "registerTestAreaForWorkArea", TestAreas.registerTestAreaForWorkArea)
	SpecializationUtil.registerFunction(vehicleType, "setTestAreaRequirements", TestAreas.setTestAreaRequirements)
	SpecializationUtil.registerFunction(vehicleType, "getIsTestAreaActive", TestAreas.getIsTestAreaActive)
	SpecializationUtil.registerFunction(vehicleType, "processTestArea", TestAreas.processTestArea)
	SpecializationUtil.registerFunction(vehicleType, "getTestAreaWidthByWorkAreaIndex", TestAreas.getTestAreaWidthByWorkAreaIndex)
	SpecializationUtil.registerFunction(vehicleType, "getTestAreaChargeByWorkAreaIndex", TestAreas.getTestAreaChargeByWorkAreaIndex)
end

function TestAreas.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", TestAreas.loadWorkAreaFromXML)
end

function TestAreas.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", TestAreas)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", TestAreas)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", TestAreas)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", TestAreas)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", TestAreas)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", TestAreas)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", TestAreas)
end

-- Local values: spec
function TestAreas:onPreLoad(savegame)
	local v7_ = self.spec_testAreas
	v7_.testAreas = {}
	v7_.testAreasByWorkArea = {}
	v7_.testAreasByWorkAreaIndex = {}
	v7_.testAreaDirtyFlag = self:getNextDirtyFlag()
end

-- Local values: spec, workArea, testAreas
function TestAreas:onPostLoad(savegame)
	local v9_ = self.spec_testAreas
	for v10_, v11_ in pairs(v9_.testAreasByWorkArea) do
		v9_.testAreasByWorkAreaIndex[v10_.index] = v11_
	end
end

function TestAreas:onReadStream(streamId, connection)
	self:readTestAreasStream(streamId, connection)
end

function TestAreas:onWriteStream(streamId, connection)
	self:writeTestAreasStream(streamId, connection)
end

function TestAreas:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		self:readTestAreasStream(streamId, connection)
	end
end

function TestAreas:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v25_ = streamWriteBool
		local v26_ = self.spec_testAreas.testAreaDirtyFlag
		if v25_(streamId, bit32.band(dirtyMask, v26_) ~= 0) then
			self:writeTestAreasStream(streamId, connection)
		end
	end
end

-- Local values: spec, i, startIndex, endIndex, hadFruitContact, i, testArea, i, testArea, i
function TestAreas:readTestAreasStream(streamId, connection)
	local v29_ = self.spec_testAreas
	for v30_ = 1, #v29_.testAreas do
		v29_.testAreas[v30_].hasContact = false
	end
	local v31_ = false
	local v32_ = 0
	local v33_ = 0
	for v34_ = 1, #v29_.testAreas do
		local v35_ = v29_.testAreas[v34_]
		v35_.hasContact = streamReadBool(streamId)
		if v35_.hasContact then
			v32_ = v34_
			v31_ = true
			break
		end
	end
	if v31_ then
		for v36_ = #v29_.testAreas, 1, -1 do
			local v37_ = v29_.testAreas[v36_]
			v37_.hasContact = streamReadBool(streamId)
			if v37_.hasContact then
				v33_ = v36_
				break
			end
		end
	end
	if v32_ ~= 0 and v33_ ~= 0 then
		for v38_ = v32_, v33_ do
			v29_.testAreas[v38_].hasContact = true
		end
	end
end

-- Local values: spec, hadFruitContact, i, testArea, i, testArea
function TestAreas:writeTestAreasStream(streamId, connection)
	local v41_ = self.spec_testAreas
	local v42_ = false
	for v43_ = 1, #v41_.testAreas do
		local v44_ = v41_.testAreas[v43_]
		streamWriteBool(streamId, v44_.hasContact)
		if v44_.hasContact then
			v42_ = true
			break
		end
	end
	if v42_ then
		for v45_ = #v41_.testAreas, 1, -1 do
			local v46_ = v41_.testAreas[v45_]
			streamWriteBool(streamId, v46_.hasContact)
			if v46_.hasContact then
				break
			end
		end
	end
end

-- Local values: spec, workArea, testAreas, numTestAreas, chargedAreas, foundLeft, foundLeftIndex, i, testArea, fruitFound, i, testArea, x1, y1, z1, x2, y2, z2
function TestAreas:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v48_ = self.spec_testAreas
	for v49_, v50_ in pairs(v48_.testAreasByWorkArea) do
		if self:getIsWorkAreaActive(v49_) then
			v49_.testAreaCurrentWidthMin = -math.huge
			v49_.testAreaCurrentWidthMax = math.huge
			local v51_ = #v50_
			local v52_ = v51_
			local v53_ = -1
			local v54_ = false
			for v55_ = 1, v51_ do
				local v56_ = v50_[v55_]
				if self:processTestArea(v56_) then
					v49_.testAreaCurrentWidthMin = v56_.minWidthValue
					v49_.testAreaCurrentWidthMax = v56_.maxWidthValue
					v53_ = v55_
					v54_ = true
					break
				end
				v51_ = v51_ - 1
			end
			if v54_ then
				local v57_ = false
				for v58_ = v52_, v53_ + 1, -1 do
					local v59_ = v50_[v58_]
					if v57_ then
						v59_.hasContact = true
					elseif self:processTestArea(v59_) then
						v49_.testAreaCurrentWidthMax = v59_.maxWidthValue
						v57_ = true
					else
						v51_ = v51_ - 1
					end
				end
			end
			if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
				local v60_ = localToWorld
				local v61_ = v49_.testAreaRootNode
				local v62_ = v49_.testAreaCurrentWidthMin
				local v63_ = v49_.testAreaMinX
				local v64_, v65_, v66_ = v60_(v61_, math.max(v62_, v63_), 0, 0)
				local v67_ = localToWorld
				local v68_ = v49_.testAreaRootNode
				local v69_ = v49_.testAreaCurrentWidthMax
				local v70_ = v49_.testAreaMaxX
				local v71_, v72_, v73_ = v67_(v68_, math.min(v69_, v70_), 0, 0)
				drawDebugLine(v64_, v65_, v66_, 0, 1, 0, v64_, v65_ + 2, v66_, 0, 1, 0)
				drawDebugLine(v71_, v72_, v73_, 0, 1, 0, v71_, v72_ + 1, v73_, 0, 1, 0)
			end
		else
			v49_.testAreaCurrentWidthMin = -math.huge
			v49_.testAreaCurrentWidthMax = math.huge
		end
	end
end

-- Local values: x1, y1, z1, x2, y2, z2
function TestAreas:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	if not superFunc(self, workArea, xmlFile, key) then
		return false
	end
	if not Platform.gameplay.allowTestAreas and xmlFile:hasProperty(key .. ".testAreas") then
		Logging.xmlWarning(xmlFile, "TestAreas not allowed on this platform in \'%s\'", key)
	end
	workArea.automaticTestAreas = xmlFile:getValue(key .. ".testAreas#autoGenerate", false)
	workArea.testAreaRootNode = xmlFile:getValue(key .. ".testAreas#rootNode", nil, self.components, self.i3dMappings)
	workArea.testAreaStartNode = xmlFile:getValue(key .. ".testAreas#startNode", workArea.start, self.components, self.i3dMappings)
	workArea.testAreaWidthNode = xmlFile:getValue(key .. ".testAreas#widthNode", workArea.width, self.components, self.i3dMappings)
	workArea.testAreaXOffset = xmlFile:getValue(key .. ".testAreas#xOffset", 0)
	workArea.testAreaZOffset = xmlFile:getValue(key .. ".testAreas#zOffset", 0)
	workArea.testAreaNumAreas = xmlFile:getValue(key .. ".testAreas#numAreas", 10)
	workArea.testAreaLength = xmlFile:getValue(key .. ".testAreas#length", 0.5)
	workArea.testAreaWidthScale = xmlFile:getValue(key .. ".testAreas#areaWidthScale", 0.9)
	workArea.testAreaScale = xmlFile:getValue(key .. ".testAreas#scale", 1)
	workArea.testAreaMinX = 0
	workArea.testAreaMaxX = 0
	if workArea.automaticTestAreas then
		if workArea.testAreaRootNode == nil then
			workArea.testAreaRootNode = createTransformGroup("testAreaRootNode")
			link(getParent(workArea.testAreaStartNode), workArea.testAreaRootNode)
			local v79_, v80_, v81_ = getWorldTranslation(workArea.testAreaStartNode)
			local v82_, v83_, v84_ = getWorldTranslation(workArea.testAreaWidthNode)
			setWorldTranslation(workArea.testAreaRootNode, (v79_ + v82_) * 0.5, (v80_ + v83_) * 0.5, (v81_ + v84_) * 0.5)
		end
		self:generateTestAreasForWorkArea(workArea)
	else
		if workArea.testAreaRootNode == nil then
			workArea.testAreaRootNode = self.components[1].node
		end
		xmlFile:iterate(key .. ".testAreas.testArea", function(_, p85_)
			-- upvalues: (copy) xmlFile, (copy) self, (copy) workArea
			local v86_ = {
				["start"] = xmlFile:getValue(p85_ .. "#startNode", nil, self.components, self.i3dMappings),
				["width"] = xmlFile:getValue(p85_ .. "#widthNode", nil, self.components, self.i3dMappings),
				["height"] = xmlFile:getValue(p85_ .. "#heightNode", nil, self.components, self.i3dMappings)
			}
			if v86_.start ~= nil and (v86_.width ~= nil and v86_.height ~= nil) then
				self:calculateTestAreaDimensions(workArea, v86_)
				self:registerTestAreaForWorkArea(workArea, v86_)
			end
		end)
	end
	workArea.hasTestAreas = workArea.testAreaRootNode ~= nil
	workArea.testAreaCurrentWidthMin = -math.huge
	workArea.testAreaCurrentWidthMax = math.huge
	return true
end

-- Local values: dirX, dirY, dirZ, workAreaWidth, areaWidth, totalOffset, areaSideOffset, index, startNode, widthNode, heightNode, startAreaX, endAreaX, testArea
function TestAreas:generateTestAreasForWorkArea(workArea)
	workArea.testAreaParent = createTransformGroup("testAreaParent")
	link(getParent(workArea.testAreaStartNode), workArea.testAreaParent)
	setTranslation(workArea.testAreaParent, getTranslation(workArea.testAreaStartNode))
	local v89_, v90_, v91_ = localToLocal(workArea.testAreaStartNode, workArea.testAreaWidthNode, 0, 0, 0)
	local v92_, v93_, v94_ = MathUtil.vector3Normalize(v89_, v90_, v91_)
	local v95_, v96_, v97_ = localDirectionToLocal(workArea.testAreaStartNode, getParent(workArea.testAreaStartNode), v92_, v93_, v94_)
	I3DUtil.setDirection(workArea.testAreaParent, v95_, v96_, v97_, 0, 1, 0)
	local v98_ = calcDistanceFrom(workArea.testAreaStartNode, workArea.testAreaWidthNode)
	local v99_ = v98_ * workArea.testAreaScale / workArea.testAreaNumAreas
	local v100_ = -v98_ * (1 - workArea.testAreaScale) * 0.5
	local v101_ = v99_ * (1 - workArea.testAreaWidthScale) * 0.5 + workArea.testAreaXOffset
	for v102_ = 1, workArea.testAreaNumAreas do
		local v103_ = createTransformGroup(string.format("testArea%dStart", v102_))
		local v104_ = createTransformGroup(string.format("testArea%dWidth", v102_))
		local v105_ = createTransformGroup(string.format("testArea%dHeight", v102_))
		link(workArea.testAreaParent, v103_)
		link(workArea.testAreaParent, v104_)
		link(workArea.testAreaParent, v105_)
		local v106_ = -((v102_ - 1) * v99_) - v101_ + v100_
		local v107_ = -(v102_ * v99_) + v101_ + v100_
		setTranslation(v103_, -(workArea.testAreaZOffset + workArea.testAreaLength), 0, v106_)
		setTranslation(v104_, -(workArea.testAreaZOffset + workArea.testAreaLength), 0, v107_)
		setTranslation(v105_, -workArea.testAreaZOffset, 0, v106_)
		local v108_ = {
			["start"] = v103_,
			["width"] = v104_,
			["height"] = v105_,
			["areaSideOffset"] = v101_
		}
		self:calculateTestAreaDimensions(workArea, v108_)
		self:registerTestAreaForWorkArea(workArea, v108_)
	end
end

-- Local values: startX, _, _, widthX, _, _
function TestAreas:calculateTestAreaDimensions(workArea, testArea)
	testArea.areaSideOffset = testArea.areaSideOffset or 0
	local v111_, _, _ = worldToLocal(workArea.testAreaRootNode, getWorldTranslation(testArea.start))
	local v112_, _, _ = worldToLocal(workArea.testAreaRootNode, getWorldTranslation(testArea.width))
	testArea.minWidthValue = v111_ + testArea.areaSideOffset
	testArea.maxWidthValue = v112_ - testArea.areaSideOffset
	local v113_ = workArea.testAreaMinX
	local v114_ = testArea.minWidthValue
	local v115_ = testArea.maxWidthValue
	workArea.testAreaMinX = math.min(v113_, v114_, v115_)
	local v116_ = workArea.testAreaMaxX
	local v117_ = testArea.minWidthValue
	local v118_ = testArea.maxWidthValue
	workArea.testAreaMaxX = math.max(v116_, v117_, v118_)
end

-- Local values: spec
function TestAreas:registerTestAreaForWorkArea(workArea, testArea)
	testArea.hasContact = false
	testArea.hasContactSent = false
	local v122_ = self.spec_testAreas
	if v122_.testAreasByWorkArea[workArea] == nil then
		v122_.testAreasByWorkArea[workArea] = {}
	end
	local v123_ = v122_.testAreasByWorkArea[workArea]
	table.insert(v123_, testArea)
	local v124_ = v122_.testAreas
	table.insert(v124_, testArea)
end

-- Local values: spec
function TestAreas:setTestAreaRequirements(fruitTypeIndex, fillTypeIndex, allowsForageGrowthState)
	local v129_ = self.spec_testAreas
	if fruitTypeIndex == FruitType.UNKNOWN then
		fruitTypeIndex = nil
	end
	if fillTypeIndex == FillType.UNKNOWN then
		fillTypeIndex = nil
	end
	v129_.fruitTypeIndex = fruitTypeIndex
	v129_.fillTypeIndex = fillTypeIndex
	v129_.allowsForageGrowthState = allowsForageGrowthState
end

function TestAreas:getIsTestAreaActive(testArea)
	return true
end

-- Local values: spec, x, _, z, x1, _, z1, x2, _, z2, fruitValue, _, _, _, fillLevel, dx, dz, widthX, widthZ, heightX, heightZ, dx, dz, widthX, widthZ, heightX, heightZ
function TestAreas:processTestArea(testArea)
	local v132_ = self.spec_testAreas
	local v133_, _, v134_ = getWorldTranslation(testArea.start)
	local v135_, _, v136_ = getWorldTranslation(testArea.width)
	local v137_, _, v138_ = getWorldTranslation(testArea.height)
	if self.isServer and (v132_.fruitTypeIndex ~= nil or v132_.fillTypeIndex ~= nil) then
		if self:getIsTestAreaActive(testArea) then
			if v132_.fruitTypeIndex == nil then
				testArea.hasContact = DensityMapHeightUtil.getFillLevelAtArea(v132_.fillTypeIndex, v133_, v134_, v135_, v136_, v137_, v138_) > 0
			else
				local v139_, _, _, _ = FSDensityMapUtil.getFruitArea(v132_.fruitTypeIndex, v133_, v134_, v135_, v136_, v137_, v138_, nil, v132_.allowsForageGrowthState)
				testArea.hasContact = v139_ > 0
			end
			if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
				local v140_, v141_, v142_, v143_, v144_, v145_ = MathUtil.getXZWidthAndHeight(v133_, v134_, v135_, v136_, v137_, v138_)
				DebugUtil.drawDebugParallelogram(v140_, v141_, v142_, v143_, v144_, v145_, 0.2, testArea.hasContact and 0 or 1, testArea.hasContact and 1 or 0, 0, 0.5)
				DebugGizmo.renderAtNode(testArea.start, getName(testArea.start), true, 1, true)
				DebugGizmo.renderAtNode(testArea.width, getName(testArea.width), true, 1, true)
				DebugGizmo.renderAtNode(testArea.height, getName(testArea.height), true, 1, true)
			end
			if testArea.hasContactSent ~= testArea.hasContact then
				self:raiseDirtyFlags(v132_.testAreaDirtyFlag)
				testArea.hasContactSent = testArea.hasContact
			end
		end
	elseif (v132_.fruitTypeIndex ~= nil or v132_.fillTypeIndex ~= nil) and VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
		local v146_, v147_, v148_, v149_, v150_, v151_ = MathUtil.getXZWidthAndHeight(v133_, v134_, v135_, v136_, v137_, v138_)
		DebugUtil.drawDebugParallelogram(v146_, v147_, v148_, v149_, v150_, v151_, 0.2, testArea.hasContact and 0 or 1, testArea.hasContact and 1 or 0, 0, 0.5)
	end
	return testArea.hasContact
end

-- Local values: spec, workArea, width
function TestAreas:getTestAreaWidthByWorkAreaIndex(workAreaIndex)
	local v154_ = self.spec_testAreas
	local v155_ = self:getWorkAreaByIndex(workAreaIndex)
	if v155_ == nil then
		return -math.huge, math.huge, 0, 0, false
	end
	if v154_.testAreasByWorkAreaIndex[workAreaIndex] ~= nil then
		return v155_.testAreaCurrentWidthMin, v155_.testAreaCurrentWidthMax, v155_.testAreaMinX, v155_.testAreaMaxX, true
	end
	local v156_ = self:getWorkAreaWidth(workAreaIndex) * 0.5
	return -v156_, v156_, -v156_, v156_, false
end

-- Local values: spec, testAreas, charged, i
function TestAreas:getTestAreaChargeByWorkAreaIndex(workAreaIndex)
	local v159_ = self.spec_testAreas.testAreasByWorkAreaIndex[workAreaIndex]
	if v159_ == nil then
		return 1
	end
	local v160_ = 0
	for v161_ = 1, #v159_ do
		if v159_[v161_].hasContact then
			v160_ = v160_ + 1
		end
	end
	return v160_ / #v159_
end
