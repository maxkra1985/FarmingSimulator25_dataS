FieldStateDialog = {}
local FieldStateDialog_mt = Class(FieldStateDialog, DialogElement)
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
	local maxPlowLevel = Platform.gameplay.usePlowCounter and fieldGroundSystem:getMaxValue(FieldDensityMap.PLOW_LEVEL) or 0
	local plowLevelTexts = {}
	for i = 0, maxPlowLevel do
		table.insert(plowLevelTexts, tostring(i))
	end
	self.plowLevel:setTexts(plowLevelTexts)
	local maxLimeLevel = Platform.gameplay.useLimeCounter and fieldGroundSystem:getMaxValue(FieldDensityMap.LIME_LEVEL) or 0
	local limeLevelTexts = {}
	for i = 0, maxLimeLevel do
		table.insert(limeLevelTexts, tostring(i))
	end
	self.limeLevel:setTexts(limeLevelTexts)
	local maxRollerLevel = Platform.gameplay.useRolling and fieldGroundSystem:getMaxValue(FieldDensityMap.ROLLER_LEVEL) or 0
	local rollerLevelTexts = {}
	for i = 0, maxRollerLevel do
		table.insert(rollerLevelTexts, tostring(i))
	end
	self.rollerLevel:setTexts(rollerLevelTexts)
	local maxStubbleShredLevel = Platform.gameplay.useStubbleShred and fieldGroundSystem:getMaxValue(FieldDensityMap.STUBBLE_SHRED_LEVEL) or 0
	local stubbleShredLevelTexts = {}
	for i = 0, maxStubbleShredLevel do
		table.insert(stubbleShredLevelTexts, tostring(i))
	end
	self.stubbleShredLevel:setTexts(stubbleShredLevelTexts)
	local stoneSystem = g_currentMission.stoneSystem
	if stoneSystem ~= nil and stoneSystem:getMapHasStones() then
		local stoneTexts = { "Invisible", "Small", "Medium", "Big", "Picked", "Blocked after picked" }
		self.stoneLevels = { 0, 1, 2, 3, 4, 5 }
		self.stones:setTexts(stoneTexts)
	end
	local weedTexts = { "invisible", "invisible dense", "small alive", "small dense alive", "big alive", "small dense weeded alive", "small dead", "small dense dead", "big dead" }
	self.weed:setTexts(weedTexts)
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
function FieldStateDialog:onClickOk()
	self:applySettings()
	self:close()
	return false
end
function FieldStateDialog:onClickApply()
	self:applySettings()
end
function FieldStateDialog:applySettings()
	local fieldIds = self.fieldIds:getText()
	local idStrs = string.split(fieldIds, ",")
	local fields = {}
	if 0 < #idStrs then
		for _, idStr in ipairs(idStrs) do
			local idStr = string.trim(idStr)
			if string.lower(idStr) == "all" then
				fields = g_fieldManager:getFields()
				break
			end
			local id = tonumber(idStr)
			local field = g_fieldManager:getFieldById(id)
			if field ~= nil then
				table.insert(fields, field)
			else
				Logging.warning("Field '%s' not defined", idStr)
			end
		end
	end
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
	for _, field in ipairs(fields) do
		if self.buyField then
			local fieldFarmland = field.farmland
			if fieldFarmland ~= nil then
				fieldFarmland:setOwnerFarmId(g_localPlayer.farmId)
			end
		end
		local task = FieldUpdateTask.new()
		task:setField(field)
		task:setArea(field:getDensityMapPolygon())
		task:setFruit(fruitTypeIndex, growthState)
		task:setWeedState(weedState)
		task:setStoneLevel(stoneLevel)
		task:setGroundType(groundType)
		task:setGroundAngle(groundAngle)
		task:setSprayType(sprayType)
		task:setSprayLevel(sprayLevel)
		task:setLimeLevel(limeLevel)
		task:setPlowLevel(plowLevel)
		task:setRollerLevel(rollerLevel)
		task:setStubbleShredLevel(stubbleShredLevel)
		task:resetDisplacement()
		task:clearTireTracks()
		g_fieldManager:addFieldUpdateTask(task)
	end
end
