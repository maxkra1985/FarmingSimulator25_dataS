FieldStateDialog = {}
local FieldStateDialog_mt = Class(FieldStateDialog, DialogElement)
FieldStateDialog.COURSE_MIN_WORKING_WIDTH = 1
FieldStateDialog.COURSE_MAX_WORKING_WIDTH = 30
FieldStateDialog.COURSE_DEFAULT_WORKING_WIDTH = 6
FieldStateDialog.COURSE_MIN_NUM_HEADLANDS = 1
FieldStateDialog.COURSE_MAX_NUM_HEADLANDS = 6
FieldStateDialog.COURSE_DEFAULT_NUM_HEADLANDS = 2
FieldStateDialog.COURSE_PERCENTAGE_STEP = 5
FieldStateDialog.COURSE_DEFAULT_PERCENTAGE = 100
FieldStateDialog.COURSE_WORK_DIRECTION_STEP = 5
FieldStateDialog.COURSE_WORK_DIRECTION_AUTOMATIC = -1
FieldStateDialog.OPTION_STATE_YES = 2
FieldStateDialog.ORDER_STATE_HEADLANDS_FIRST = 1
function FieldStateDialog.register()
	local fieldStateDialog = FieldStateDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/FieldStateDialog.xml", "FieldStateDialog", fieldStateDialog)
	FieldStateDialog.INSTANCE = fieldStateDialog
end
function FieldStateDialog.show(fieldId, fruitTypeName, growthState, groundTypeName, angle, groundLayer, fertilizerState, plowingState, weedState, limeState, stubbleState, buyField, removeFoliage)
	if FieldStateDialog.INSTANCE ~= nil then
		g_gui:showDialog("FieldStateDialog")
		FieldStateDialog.INSTANCE:setFieldId(fieldId)
		FieldStateDialog.INSTANCE:setFruitName(fruitTypeName, growthState)
		FieldStateDialog.INSTANCE:setGroundType(groundTypeName, angle)
		FieldStateDialog.INSTANCE:setGroundLayer(groundLayer)
		FieldStateDialog.INSTANCE:setFertilizerState(fertilizerState)
		FieldStateDialog.INSTANCE:setPlowingState(plowingState)
		FieldStateDialog.INSTANCE:setWeedState(weedState)
		FieldStateDialog.INSTANCE:setLimeState(limeState)
		FieldStateDialog.INSTANCE:setStubbleState(stubbleState)
		FieldStateDialog.INSTANCE:setBuyField(buyField)
		FieldStateDialog.INSTANCE:setRemoveFoliage(removeFoliage)
	end
end
function FieldStateDialog.new(target, custom_mt)
	local self = ColorPickerDialog.new(target, custom_mt or FieldStateDialog_mt)
	return self
end
function FieldStateDialog.createFromExistingGui(gui, guiName)
	FieldStateDialog.register()
	FieldStateDialog.show()
end
function FieldStateDialog:onOpen()
	FieldStateDialog:superClass().onOpen(self)
	self.buyField = nil
	local fieldGroundSystem = g_currentMission.fieldGroundSystem
	local texts = { "UNKNOWN" }
	for _, fruitType in ipairs(g_fruitTypeManager:getFruitTypes()) do
		table.insert(texts, fruitType.name)
	end
	self.fruitTypes:setTexts(texts)
	self.fruitTypes:setState(1, true)
	local groundTypeTexts = {}
	for _, groundType in ipairs(FieldGroundType.getAllOrdered()) do
		table.insert(groundTypeTexts, FieldGroundType.getName(groundType))
	end
	self.groundTypes:setTexts(groundTypeTexts)
	local groundAngleTexts = {}
	self.groundAngleValues = {}
	local maxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.GROUND_ANGLE) + 1
	self.groundAngleStep = 3.141592653589793 / maxValue
	for i = 1, maxValue do
		local angle = (i - 1) * self.groundAngleStep
		table.insert(groundAngleTexts, string.format("%.1f \194\176", math.deg(angle)))
		table.insert(self.groundAngleValues, angle)
	end
	self.groundAngles:setTexts(groundAngleTexts)
	local sprayTypeTexts = {}
	for _, sprayType in ipairs(FieldSprayType.getAllOrdered()) do
		table.insert(sprayTypeTexts, FieldSprayType.getName(sprayType))
	end
	self.sprayTypes:setTexts(sprayTypeTexts)
	local sprayLevelTexts = {}
	for i = 0, fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL) do
		table.insert(sprayLevelTexts, tostring(i))
	end
	self.sprayLevel:setTexts(sprayLevelTexts)
	self.plowLevel:setTexts({ "needs plowing", "is plowed" })
	local maxLimeLevel = Platform.gameplay.useLimeCounter and fieldGroundSystem:getMaxValue(FieldDensityMap.LIME_LEVEL) or 0
	local limeLevelTexts = {}
	for i = 0, maxLimeLevel do
		if i == 0 then
			table.insert(limeLevelTexts, "needs liming")
		elseif i == maxLimeLevel then
			table.insert(limeLevelTexts, "fully limed")
		else
			table.insert(limeLevelTexts, string.format("partly limed (%d/%d)", i, maxLimeLevel))
		end
	end
	self.limeLevel:setTexts(limeLevelTexts)
	self.rollerLevel:setTexts({ "needs rolling", "is rolled" })
	self.stubbleShredLevel:setTexts({ "not shredded", "is shredded" })
	local stoneSystem = g_currentMission.stoneSystem
	if stoneSystem ~= nil and stoneSystem:getMapHasStones() then
		local stoneTexts = { "Invisible", "Small", "Medium", "Big", "Picked", "Blocked after picked" }
		self.stoneLevels = { 0, 1, 2, 3, 4, 5 }
		self.stones:setTexts(stoneTexts)
	end
	local weedTexts = { "invisible", "invisible dense", "small alive", "small dense alive", "big alive", "small dense weeded alive", "small dead", "small dense dead", "big dead" }
	self.weed:setTexts(weedTexts)
	self.useFieldCourse:setTexts({ "No", "Yes" })
	self.useFieldCourse:setState(1, true)
	self.workHeadlands:setTexts({ "No", "Yes" })
	self.workHeadlands:setState(FieldStateDialog.OPTION_STATE_YES, true)
	self.orderMode:setTexts({ "Headlands first", "Up-down first" })
	self.orderMode:setState(2, true)
	local workingWidthTexts = {}
	for width = FieldStateDialog.COURSE_MIN_WORKING_WIDTH, FieldStateDialog.COURSE_MAX_WORKING_WIDTH do
		table.insert(workingWidthTexts, string.format("%d m", width))
	end
	self.workingWidth:setTexts(workingWidthTexts)
	self.workingWidth:setState(FieldStateDialog.COURSE_DEFAULT_WORKING_WIDTH - FieldStateDialog.COURSE_MIN_WORKING_WIDTH + 1, true)
	local numHeadlandsTexts = {}
	for num = FieldStateDialog.COURSE_MIN_NUM_HEADLANDS, FieldStateDialog.COURSE_MAX_NUM_HEADLANDS do
		table.insert(numHeadlandsTexts, tostring(num))
	end
	self.numHeadlands:setTexts(numHeadlandsTexts)
	self.numHeadlands:setState(FieldStateDialog.COURSE_DEFAULT_NUM_HEADLANDS - FieldStateDialog.COURSE_MIN_NUM_HEADLANDS + 1, true)
	local percentageTexts = {}
	for percentage = 0, 100, FieldStateDialog.COURSE_PERCENTAGE_STEP do
		table.insert(percentageTexts, tostring(percentage))
	end
	self.workPercentage:setTexts(percentageTexts)
	self.workPercentage:setState(FieldStateDialog.COURSE_DEFAULT_PERCENTAGE / FieldStateDialog.COURSE_PERCENTAGE_STEP + 1, true)
	local workDirectionTexts = { "Automatic" }
	self.workDirectionValues = { FieldStateDialog.COURSE_WORK_DIRECTION_AUTOMATIC }
	for degrees = 0, 180 - FieldStateDialog.COURSE_WORK_DIRECTION_STEP, FieldStateDialog.COURSE_WORK_DIRECTION_STEP do
		table.insert(workDirectionTexts, string.format("%d \194\176", degrees))
		table.insert(self.workDirectionValues, math.rad(degrees))
	end
	self.workDirection:setTexts(workDirectionTexts)
	self.workDirection:setState(1, true)
	self:setFieldCourseElementsDisabled(true)
	self.statusText:setText("")
end
function FieldStateDialog:update(dt)
	FieldStateDialog:superClass().update(self, dt)
	local numPendingTasks = g_fieldManager:getNumPendingUpdateTasks()
	if 0 < numPendingTasks then
		self.statusText:setText(string.format("Updating fields... %d task(s) remaining", numPendingTasks))
	else
		self.statusText:setText("")
	end
end
function FieldStateDialog:setFieldId(fieldIdStr)
	if fieldIdStr ~= nil then
		self.fieldIds:setText(fieldIdStr)
		local fieldId = tonumber(fieldIdStr)
		if fieldId ~= nil then
			local field = g_fieldManager:getFieldById(fieldId)
			if field ~= nil then
				local state = field:getFieldState()
				local x, z = field:getIndicatorPosition()
				state:update(x, z)
				self.fruitTypes:setState(state.fruitTypeIndex + 1, true)
				self.growthStates:setState(state.growthState, true)
				self.groundTypes:setState(state.groundType)
				self.weed:setState(state.weedState)
				self.sprayTypes:setState(state.sprayType)
				self.sprayLevel:setState(state.sprayLevel + 1)
				self.limeLevel:setState(state.limeLevel + 1)
				self.plowLevel:setState(state.plowLevel + 1)
				self.rollerLevel:setState(state.rollerLevel + 1)
				self.stubbleShredLevel:setState(state.stubbleShredLevel + 1)
			end
		end
	end
end
function FieldStateDialog:setFruitName(fruitTypeName, growthState)
	local fruitTypeIndex = g_fruitTypeManager:getFruitTypeIndexByName(fruitTypeName)
	if fruitTypeIndex ~= nil then
		self.fruitTypes:setState(fruitTypeIndex + 1, true)
		self.growthStates:setState((growthState or 0) + 1, true)
	end
end
function FieldStateDialog:setGroundType(groundTypeName, angleDeg)
	if groundTypeName == nil then
		return
	end
	local groundType = FieldGroundType.getByName(groundTypeName)
	if groundType == nil then
		Logging.warning("Unknown ground type name %q", groundTypeName)
		print("Available types: " .. FieldGroundType.getAllNames())
	else
		self.groundTypes:setState(groundType)
		angleDeg = tonumber(angleDeg)
		if angleDeg ~= nil then
			local angle = math.rad(math.abs(angleDeg)) % 3.141592653589793
			angle = MathUtil.snapValue(angle, self.groundAngleStep)
			local matchingState = 1
			for state, angleValue in ipairs(self.groundAngleValues) do
				if MathUtil.equalEpsilon(angleValue, angle) then
					matchingState = state
					break
				end
			end
			self.groundAngles:setState(matchingState)
		end
	end
end
function FieldStateDialog:setGroundLayer(groundLayer)
	if groundLayer == nil then
		return
	end
	local sprayType = FieldSprayType.getByName(groundLayer)
	if sprayType == nil then
		Logging.warning("Unknown ground layer name %q", groundLayer)
		print("Available layers: " .. FieldSprayType.getAllNames())
	else
		self.sprayTypes:setState(sprayType)
	end
end
function FieldStateDialog:setFertilizerState(fertilizerState)
	if fertilizerState == nil then
		return
	else
		self.sprayLevel:setState(fertilizerState + 1)
	end
end
function FieldStateDialog:setPlowingState(plowingState)
	if plowingState == nil then
		return
	else
		self.plowLevel:setState(plowingState + 1)
	end
end
function FieldStateDialog:setWeedState(weedState)
	if weedState == nil then
		return
	else
		self.weed:setState(weedState)
	end
end
function FieldStateDialog:setLimeState(limeState)
	if limeState == nil then
		return
	else
		self.limeLevel:setState(limeState + 1)
	end
end
function FieldStateDialog:setStubbleState(stubbleState)
	if stubbleState == nil then
		return
	else
		self.stubbleShredLevel:setState(stubbleState + 1)
	end
end
function FieldStateDialog:setBuyField(buyField)
	if not buyField then
		return
	else
		self.buyField = buyField
	end
end
function FieldStateDialog:setRemoveFoliage(removeFoliage)
	if not removeFoliage then
		return
	else
		self.fruitTypes:setState(1, true)
		self.growthStates:setState(1, true)
	end
end
function FieldStateDialog:updateGrowthStates()
	local state = self.fruitTypes:getState() - 1
	local texts = {}
	if state == 0 then
		table.insert(texts, "")
	else
		local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(state)
		for _, name in ipairs(fruitTypeDesc.growthStateToName) do
			table.insert(texts, name)
		end
		self.growthStates:setTexts(texts)
	end
end
function FieldStateDialog:onClickFruitType(state)
	self:updateGrowthStates()
	self.growthStates:setDisabled(state == 1)
end
function FieldStateDialog:onClickGrowthStates(growthState)
	local fruitTypeState = self.fruitTypes:getState() - 1
	if 0 < fruitTypeState then
		local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeState)
		if fruitTypeDesc ~= nil then
			if fruitTypeDesc:getIsCut(growthState) and fruitTypeDesc.harvestGroundType ~= nil then
				self.groundTypes:setState(fruitTypeDesc.harvestGroundType)
				return
			end
			if fruitTypeDesc.groundTypeChangeType ~= nil and fruitTypeDesc.groundTypeChangeGrowthState <= growthState then
				self.groundTypes:setState(fruitTypeDesc.groundTypeChangeType)
			end
		end
	end
end
function FieldStateDialog:onClickUseFieldCourse(state)
	self:setFieldCourseElementsDisabled(state ~= FieldStateDialog.OPTION_STATE_YES)
end
function FieldStateDialog:setFieldCourseElementsDisabled(disabled)
	self.workingWidth:setDisabled(disabled)
	self.numHeadlands:setDisabled(disabled)
	self.workHeadlands:setDisabled(disabled)
	self.orderMode:setDisabled(disabled)
	self.workDirection:setDisabled(disabled)
	self.workPercentage:setDisabled(disabled)
end
function FieldStateDialog:onClickOk()
	self:applySettings()
	self:close()
	return false
end
function FieldStateDialog:onClickApply()
	self:applySettings()
end
function FieldStateDialog:onClickQuickHarvestReady()
	local fruitTypeDesc = self:getSelectedFruitTypeDesc()
	if fruitTypeDesc == nil then
		Logging.warning("FieldStateDialog: select a crop first to apply the harvest ready quick setting")
	else
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		self.growthStates:setState(FieldStateDialog.getHarvestReadyGrowthState(fruitTypeDesc), true)
		self.weed:setState(1)
		self.sprayLevel:setState(fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL) + 1)
		if Platform.gameplay.useLimeCounter then
			self.limeLevel:setState(fieldGroundSystem:getMaxValue(FieldDensityMap.LIME_LEVEL) + 1)
		end
		if Platform.gameplay.usePlowCounter then
			self.plowLevel:setState(fieldGroundSystem:getMaxValue(FieldDensityMap.PLOW_LEVEL) + 1)
		end
	end
end
function FieldStateDialog:onClickQuickHarvested()
	local fruitTypeDesc = self:getSelectedFruitTypeDesc()
	if fruitTypeDesc == nil then
		Logging.warning("FieldStateDialog: select a crop first to apply the harvested quick setting")
	else
		self.growthStates:setState(fruitTypeDesc.cutState, true)
	end
end
function FieldStateDialog:onClickQuickCultivated()
	self.fruitTypes:setState(1, true)
	self.growthStates:setState(1, true)
	self.groundTypes:setState(FieldGroundType.CULTIVATED)
	self.weed:setState(1)
	self.sprayTypes:setState(FieldSprayType.NONE)
	self.sprayLevel:setState(1)
end
function FieldStateDialog:getSelectedFruitTypeDesc()
	local state = self.fruitTypes:getState()
	if state <= 1 then
		return nil
	else
		return g_fruitTypeManager:getFruitTypeByIndex(state - 1)
	end
end
function FieldStateDialog.getHarvestReadyGrowthState(fruitTypeDesc)
	if fruitTypeDesc.maxPreparingGrowthState ~= -1 then
		return fruitTypeDesc.maxPreparingGrowthState
	else
		return fruitTypeDesc.maxHarvestingGrowthState
	end
end
function FieldStateDialog:getSelectedFields()
	local fieldIds = self.fieldIds:getText()
	local idStrs = string.split(fieldIds, ",")
	local fields = {}
	for _, idStr in ipairs(idStrs) do
		local idStr = string.trim(idStr)
		if string.lower(idStr) == "all" then
			return g_fieldManager:getFields()
		end
		local id = tonumber(idStr)
		local field = g_fieldManager:getFieldById(id)
		if field ~= nil then
			table.insert(fields, field)
		else
			Logging.warning("Field '%s' not defined", idStr)
		end
	end
	return fields
end
function FieldStateDialog:applySettings()
	local fields = self:getSelectedFields()
	local fruitTypeIndex = FruitType.UNKNOWN
	local growthState = 0
	local state = self.fruitTypes:getState()
	if 1 < state then
		local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(state - 1)
		fruitTypeIndex = fruitTypeDesc.index
		growthState = self.growthStates:getState()
	end
	local groundType = self.groundTypes:getState()
	local groundAngle = self.groundAngleValues[self.groundAngles:getState()]
	local sprayType = self.sprayTypes:getState()
	local weedState = self.weed:getState()
	local stoneLevel = self.stoneLevels[self.stones:getState()]
	local sprayLevel = self.sprayLevel:getState() - 1
	local limeLevel = self.limeLevel:getState() - 1
	local plowLevel = self.plowLevel:getState() - 1
	local rollerLevel = self.rollerLevel:getState() - 1
	local stubbleShredLevel = self.stubbleShredLevel:getState() - 1
	local stateValues = {}
	stateValues.fruitTypeIndex = fruitTypeIndex
	stateValues.growthState = growthState
	stateValues.weedState = weedState
	stateValues.stoneLevel = stoneLevel
	stateValues.groundType = groundType
	stateValues.groundAngle = groundAngle
	stateValues.sprayType = sprayType
	stateValues.sprayLevel = sprayLevel
	stateValues.limeLevel = limeLevel
	stateValues.plowLevel = plowLevel
	stateValues.rollerLevel = rollerLevel
	stateValues.stubbleShredLevel = stubbleShredLevel
	local useFieldCourse = self.useFieldCourse:getState() == FieldStateDialog.OPTION_STATE_YES
	self.courseGenerationId = (self.courseGenerationId or 0) + 1
	local courseGenerationId = self.courseGenerationId
	for _, field in ipairs(fields) do
		if self.buyField then
			local fieldFarmland = field.farmland
			if fieldFarmland ~= nil then
				fieldFarmland:setOwnerFarmId(g_localPlayer.farmId)
			end
		end
		if useFieldCourse then
			self:applyFieldCourse(field, stateValues, courseGenerationId)
		else
			self:applyFullField(field, stateValues)
		end
	end
end
function FieldStateDialog:applyFullField(field, stateValues)
	local task = FieldUpdateTask.new()
	task:setField(field)
	task:setArea(field:getDensityMapPolygon())
	self:applyStateValuesToTask(task, stateValues, stateValues.groundAngle)
	g_fieldManager:addFieldUpdateTask(task)
end
function FieldStateDialog:applyFieldCourse(field, stateValues, courseGenerationId)
	local workingWidth = self.workingWidth:getState() - 1 + FieldStateDialog.COURSE_MIN_WORKING_WIDTH
	local numHeadlands = self.numHeadlands:getState() - 1 + FieldStateDialog.COURSE_MIN_NUM_HEADLANDS
	local percentage = (self.workPercentage:getState() - 1) * FieldStateDialog.COURSE_PERCENTAGE_STEP / 100
	local workHeadlands = self.workHeadlands:getState() == FieldStateDialog.OPTION_STATE_YES
	local headlandsFirst = self.orderMode:getState() == FieldStateDialog.ORDER_STATE_HEADLANDS_FIRST
	local settings = FieldCourseSettings.new()
	settings.implementWidth = workingWidth
	settings.numHeadlands = numHeadlands
	settings.workHeadlands = workHeadlands
	settings.headlandsFirst = headlandsFirst
	settings.workDirection = self.workDirectionValues[self.workDirection:getState()]
	local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(stateValues.fruitTypeIndex)
	if fruitTypeDesc ~= nil and fruitTypeDesc.plantSeparation ~= nil then
		settings.rowSpacing = fruitTypeDesc.plantSeparation[1]
		settings.rowSnapAngle = fruitTypeDesc.directionSnapAngle
	end
	local x, z = field:getIndicatorPosition()
	local oppositeStateValues = nil
	if percentage < 1 then
		oppositeStateValues = self:buildOppositeHarvestStateValues(stateValues)
	end
	FieldCourse.generateUICourseByFieldPosition(x, z, settings, function(fieldCourse)
		if courseGenerationId ~= self.courseGenerationId then
			return
		elseif fieldCourse == nil then
			Logging.warning("FieldStateDialog: could not generate field course for field '%s'", tostring(field:getId()))
		else
			local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			local onFieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			onFieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
			local maxLength = fieldCourse.totalLength * percentage
			local workedLength = 0
			for _, segment in ipairs(fieldCourse.segments) do
				if segment.isTurn or not workHeadlands and segment.isHeadlandSegment then
					continue
				end
				local values = stateValues
				if maxLength <= workedLength then
					if oppositeStateValues == nil then
						break
					end
					values = oppositeStateValues
				end
				self:enqueueSegmentTask(field, fieldCourse, segment, workingWidth, values, onFieldFilter)
				workedLength = workedLength + segment.length
			end
		end
	end)
end
function FieldStateDialog:buildOppositeHarvestStateValues(stateValues)
	local fruitTypeDesc = self:getSelectedFruitTypeDesc()
	if fruitTypeDesc == nil then
		return nil
	else
		local growthState = stateValues.growthState
		local isHarvestReady = fruitTypeDesc:getIsHarvestReady(growthState) or fruitTypeDesc:getIsPreparable(growthState)
		local oppositeGrowthState = nil
		if isHarvestReady then
			oppositeGrowthState = fruitTypeDesc.cutState
		elseif fruitTypeDesc:getIsCut(growthState) then
			oppositeGrowthState = FieldStateDialog.getHarvestReadyGrowthState(fruitTypeDesc)
		else
			return nil
		end
		if oppositeGrowthState == nil or oppositeGrowthState == 0 then
			return nil
		end
		local oppositeStateValues = {}
		for key, value in pairs(stateValues) do
			oppositeStateValues[key] = value
		end
		oppositeStateValues.growthState = oppositeGrowthState
		local oppositeGroundType = self:getGroundTypeForGrowthState(fruitTypeDesc, oppositeGrowthState)
		if oppositeGroundType ~= nil then
			oppositeStateValues.groundType = oppositeGroundType
		end
		return oppositeStateValues
	end
end
function FieldStateDialog:getGroundTypeForGrowthState(fruitTypeDesc, growthState)
	if fruitTypeDesc:getIsCut(growthState) and fruitTypeDesc.harvestGroundType ~= nil then
		return fruitTypeDesc.harvestGroundType
	end
	if fruitTypeDesc.groundTypeChangeType ~= nil and fruitTypeDesc.groundTypeChangeGrowthState <= growthState then
		return fruitTypeDesc.groundTypeChangeType
	end
	return nil
end
function FieldStateDialog:enqueueSegmentTask(field, fieldCourse, segment, workingWidth, stateValues, onFieldFilter)
	local polygon = self:buildSegmentStripPolygon(segment, workingWidth)
	if polygon == nil then
		return
	else
		local firstPos = segment.positions[1]
		local lastPos = segment.positions[#segment.positions]
		local dirX, dirZ = MathUtil.vector2Normalize(lastPos[1] - firstPos[1], lastPos[2] - firstPos[2])
		local segmentAngle = MathUtil.getYRotationFromDirection(dirX, dirZ) % 3.141592653589793
		local task = FieldUpdateTask.new()
		task:setField(field)
		task:setArea(polygon)
		task:addFilter(onFieldFilter)
		self:applyStateValuesToTask(task, stateValues, segmentAngle)
		g_fieldManager:addFieldUpdateTask(task)
	end
end
function FieldStateDialog:applyStateValuesToTask(task, stateValues, groundAngle)
	task:setFruit(stateValues.fruitTypeIndex, stateValues.growthState)
	task:setWeedState(stateValues.weedState)
	task:setStoneLevel(stateValues.stoneLevel)
	task:setGroundType(stateValues.groundType)
	task:setGroundAngle(groundAngle)
	task:setSprayType(stateValues.sprayType)
	task:setSprayLevel(stateValues.sprayLevel)
	task:setLimeLevel(stateValues.limeLevel)
	task:setPlowLevel(stateValues.plowLevel)
	task:setRollerLevel(stateValues.rollerLevel)
	task:setStubbleShredLevel(stateValues.stubbleShredLevel)
	task:resetDisplacement()
	task:clearTireTracks()
end
function FieldStateDialog:buildSegmentStripPolygon(segment, workingWidth)
	if #segment.positions < 2 then
		return nil
	else
		local halfWidth = workingWidth * 0.5
		local positions = {}
		for _, pos in ipairs(segment.positions) do
			table.insert(positions, { pos[1], pos[2] })
		end
		FieldCourseUtil.extendSegment(positions, 1, halfWidth)
		FieldCourseUtil.extendSegment(positions, -1, halfWidth)
		local numPositions = #positions
		local polygon = DensityMapPolygon.new()
		for i = 1, numPositions do
			local pairIndex = math.min(i, numPositions - 1)
			local p1 = positions[pairIndex]
			local p2 = positions[pairIndex + 1]
			local dirX, dirZ = MathUtil.vector2Normalize(p2[1] - p1[1], p2[2] - p1[2])
			polygon:addPolygonPoint(positions[i][1] - dirZ * halfWidth, positions[i][2] + dirX * halfWidth)
		end
		for i = numPositions, 1, -1 do
			local pairIndex = math.min(i, numPositions - 1)
			local p1 = positions[pairIndex]
			local p2 = positions[pairIndex + 1]
			local dirX, dirZ = MathUtil.vector2Normalize(p2[1] - p1[1], p2[2] - p1[2])
			polygon:addPolygonPoint(positions[i][1] + dirZ * halfWidth, positions[i][2] - dirX * halfWidth)
		end
		return polygon
	end
end
