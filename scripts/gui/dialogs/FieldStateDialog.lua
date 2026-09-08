-- Local values: FieldStateDialog_mt
FieldStateDialog = {}
local FieldStateDialog_mt = Class(FieldStateDialog, DialogElement)
function FieldStateDialog.register()
	local v2_ = FieldStateDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/FieldStateDialog.xml", "FieldStateDialog", v2_)
	FieldStateDialog.INSTANCE = v2_
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

-- Upvalues: FieldStateDialog_mt
-- Local values: self
function FieldStateDialog.new(target, custom_mt)
	-- upvalues: (copy) FieldStateDialog_mt
	return ColorPickerDialog.new(target, custom_mt or FieldStateDialog_mt)
end

function FieldStateDialog.createFromExistingGui(gui, guiName)
	FieldStateDialog.register()
	FieldStateDialog.show()
end

-- Local values: fieldGroundSystem, texts, _, fruitType, groundTypeTexts, _, groundType, groundAngleTexts, maxValue, numSteps, i, angle, sprayTypeTexts, _, sprayType, sprayLevelTexts, i, maxPlowLevel, plowLevelTexts, i, maxLimeLevel, limeLevelTexts, i, maxRollerLevel, rollerLevelTexts, i, maxStubbleShredLevel, stubbleShredLevelTexts, i, stoneSystem, stoneTexts, weedTexts
function FieldStateDialog:onOpen()
	FieldStateDialog:superClass().onOpen(self)
	self.buyField = nil
	local v19_ = g_currentMission.fieldGroundSystem
	local v20_ = { "UNKNOWN" }
	for _, v21_ in ipairs(g_fruitTypeManager:getFruitTypes()) do
		local v22_ = v21_.name
		table.insert(v20_, v22_)
	end
	self.fruitTypes:setTexts(v20_)
	self.fruitTypes:setState(1, true)
	local v23_ = {}
	for _, v24_ in ipairs(FieldGroundType.getAllOrdered()) do
		local v25_ = FieldGroundType.getName
		table.insert(v23_, v25_(v24_))
	end
	self.groundTypes:setTexts(v23_)
	self.groundAngleValues = {}
	local v26_ = v19_:getMaxValue(FieldDensityMap.GROUND_ANGLE) + 1
	self.groundAngleStep = 3.141592653589793 / v26_
	local v27_ = {}
	for v28_ = 1, v26_ do
		local v29_ = (v28_ - 1) * self.groundAngleStep
		local v30_ = string.format
		local v31_ = math.deg(v29_)
		table.insert(v27_, v30_("%.1f \194\176", v31_))
		local v32_ = self.groundAngleValues
		table.insert(v32_, v29_)
	end
	self.groundAngles:setTexts(v27_)
	local v33_ = {}
	for _, v34_ in ipairs(FieldSprayType.getAllOrdered()) do
		local v35_ = FieldSprayType.getName
		table.insert(v33_, v35_(v34_))
	end
	self.sprayTypes:setTexts(v33_)
	local v36_ = {}
	for v37_ = 0, v19_:getMaxValue(FieldDensityMap.SPRAY_LEVEL) do
		local v38_ = tostring(v37_)
		table.insert(v36_, v38_)
	end
	self.sprayLevel:setTexts(v36_)
	local v39_ = {}
	for v40_ = 0, Platform.gameplay.usePlowCounter and (v19_:getMaxValue(FieldDensityMap.PLOW_LEVEL) or 0) or 0 do
		local v41_ = tostring(v40_)
		table.insert(v39_, v41_)
	end
	self.plowLevel:setTexts(v39_)
	local v42_ = {}
	for v43_ = 0, Platform.gameplay.useLimeCounter and (v19_:getMaxValue(FieldDensityMap.LIME_LEVEL) or 0) or 0 do
		local v44_ = tostring(v43_)
		table.insert(v42_, v44_)
	end
	self.limeLevel:setTexts(v42_)
	local v45_ = {}
	for v46_ = 0, Platform.gameplay.useRolling and (v19_:getMaxValue(FieldDensityMap.ROLLER_LEVEL) or 0) or 0 do
		local v47_ = tostring(v46_)
		table.insert(v45_, v47_)
	end
	self.rollerLevel:setTexts(v45_)
	local v48_ = {}
	for v49_ = 0, Platform.gameplay.useStubbleShred and v19_:getMaxValue(FieldDensityMap.STUBBLE_SHRED_LEVEL) or 0 do
		local v50_ = tostring(v49_)
		table.insert(v48_, v50_)
	end
	self.stubbleShredLevel:setTexts(v48_)
	local v51_ = g_currentMission.stoneSystem
	if v51_ ~= nil and v51_:getMapHasStones() then
		self.stoneLevels = {
			0,
			1,
			2,
			3,
			4,
			5
		}
		self.stones:setTexts({
			"Invisible",
			"Small",
			"Medium",
			"Big",
			"Picked",
			"Blocked after picked"
		})
	end
	self.weed:setTexts({
		"invisible",
		"invisible dense",
		"small alive",
		"small dense alive",
		"big alive",
		"small dense weeded alive",
		"small dead",
		"small dense dead",
		"big dead"
	})
end

-- Local values: fieldId, field, state, x, z
function FieldStateDialog:setFieldId(fieldIdStr)
	if fieldIdStr ~= nil then
		self.fieldIds:setText(fieldIdStr)
		local v54_ = tonumber(fieldIdStr)
		if v54_ ~= nil then
			local v55_ = g_fieldManager:getFieldById(v54_)
			if v55_ ~= nil then
				local v56_ = v55_:getFieldState()
				local v57_, v58_ = v55_:getIndicatorPosition()
				v56_:update(v57_, v58_)
				self.fruitTypes:setState(v56_.fruitTypeIndex + 1, true)
				self.growthStates:setState(v56_.growthState, true)
				self.groundTypes:setState(v56_.groundType)
				self.weed:setState(v56_.weedState)
				self.sprayTypes:setState(v56_.sprayType)
				self.sprayLevel:setState(v56_.sprayLevel + 1)
				self.limeLevel:setState(v56_.limeLevel + 1)
				self.plowLevel:setState(v56_.plowLevel + 1)
				self.rollerLevel:setState(v56_.rollerLevel + 1)
				self.stubbleShredLevel:setState(v56_.stubbleShredLevel + 1)
			end
		end
	end
end

-- Local values: fruitTypeIndex
function FieldStateDialog:setFruitName(fruitTypeName, growthState)
	local v62_ = g_fruitTypeManager:getFruitTypeIndexByName(fruitTypeName)
	if v62_ ~= nil then
		self.fruitTypes:setState(v62_ + 1, true)
		self.growthStates:setState((growthState or 0) + 1, true)
	end
end

-- Local values: groundType, angle, matchingState, state, angleValue
function FieldStateDialog:setGroundType(groundTypeName, angleDeg)
	if groundTypeName == nil then
		return
	end
	local v66_ = FieldGroundType.getByName(groundTypeName)
	if v66_ == nil then
		Logging.warning("Unknown ground type name %q", groundTypeName)
		print("Available types: " .. FieldGroundType.getAllNames())
		return
	end
	self.groundTypes:setState(v66_)
	local v67_ = tonumber(angleDeg)
	if v67_ ~= nil then
		local v68_ = math.abs(v67_)
		local v69_ = math.rad(v68_) % 3.141592653589793
		local v70_ = MathUtil.snapValue(v69_, self.groundAngleStep)
		local v71_ = 1
		for v72_, v73_ in ipairs(self.groundAngleValues) do
			if MathUtil.equalEpsilon(v73_, v70_) then
				v71_ = v72_
				break
			end
		end
		self.groundAngles:setState(v71_)
	end
end

-- Local values: sprayType
function FieldStateDialog:setGroundLayer(groundLayer)
	if groundLayer == nil then
		return
	else
		local v76_ = FieldSprayType.getByName(groundLayer)
		if v76_ == nil then
			Logging.warning("Unknown ground layer name %q", groundLayer)
			print("Available layers: " .. FieldSprayType.getAllNames())
		else
			self.sprayTypes:setState(v76_)
		end
	end
end

function FieldStateDialog:setFertilizerState(fertilizerState)
	if fertilizerState ~= nil then
		self.sprayLevel:setState(fertilizerState + 1)
	end
end

function FieldStateDialog:setPlowingState(plowingState)
	if plowingState ~= nil then
		self.plowLevel:setState(plowingState + 1)
	end
end

function FieldStateDialog:setWeedState(weedState)
	if weedState ~= nil then
		self.weed:setState(weedState)
	end
end

function FieldStateDialog:setLimeState(limeState)
	if limeState ~= nil then
		self.limeLevel:setState(limeState + 1)
	end
end

function FieldStateDialog:setStubbleState(stubbleState)
	if stubbleState ~= nil then
		self.stubbleShredLevel:setState(stubbleState + 1)
	end
end

function FieldStateDialog:setBuyField(buyField)
	if buyField then
		self.buyField = buyField
	end
end

function FieldStateDialog:setRemoveFoliage(removeFoliage)
	if removeFoliage then
		self.fruitTypes:setState(1, true)
		self.growthStates:setState(1, true)
	end
end

-- Local values: state, texts, fruitTypeDesc, _, name
function FieldStateDialog:updateGrowthStates()
	local v92_ = self.fruitTypes:getState() - 1
	local v93_ = {}
	if v92_ == 0 then
		table.insert(v93_, "")
	else
		local v94_ = g_fruitTypeManager:getFruitTypeByIndex(v92_)
		for _, v95_ in ipairs(v94_.growthStateToName) do
			table.insert(v93_, v95_)
		end
		self.growthStates:setTexts(v93_)
	end
end

function FieldStateDialog:onClickFruitType(state)
	self:updateGrowthStates()
	self.growthStates:setDisabled(state == 1)
end

-- Local values: fruitTypeState, fruitTypeDesc
function FieldStateDialog:onClickGrowthStates(growthState)
	local v100_ = self.fruitTypes:getState() - 1
	if v100_ > 0 then
		local v101_ = g_fruitTypeManager:getFruitTypeByIndex(v100_)
		if v101_ ~= nil then
			if v101_:getIsCut(growthState) and v101_.harvestGroundType ~= nil then
				self.groundTypes:setState(v101_.harvestGroundType)
				return
			end
			if v101_.groundTypeChangeType ~= nil and v101_.groundTypeChangeGrowthState <= growthState then
				self.groundTypes:setState(v101_.groundTypeChangeType)
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

-- Local values: fieldIds, idStrs, fields, _, idStr, id, field, fruitTypeIndex, growthState, state, fruitTypeDesc, groundType, groundAngle, sprayType, weedState, stoneLevel, sprayLevel, limeLevel, plowLevel, rollerLevel, stubbleShredLevel, _, field, fieldFarmland, task
function FieldStateDialog:applySettings()
	local v105_ = self.fieldIds:getText()
	local v106_ = string.split(v105_, ",")
	local v107_ = {}
	if #v106_ > 0 then
		for _, v108_ in ipairs(v106_) do
			local v109_ = string.trim(v108_)
			if string.lower(v109_) == "all" then
				v107_ = g_fieldManager:getFields()
				break
			end
			local v110_ = tonumber(v109_)
			local v111_ = g_fieldManager:getFieldById(v110_)
			if v111_ == nil then
				Logging.warning("Field \'%s\' not defined", v109_)
			else
				table.insert(v107_, v111_)
			end
		end
	end
	local v112_ = FruitType.UNKNOWN
	local v113_ = self.fruitTypes:getState()
	local v114_
	if v113_ > 1 then
		v112_ = g_fruitTypeManager:getFruitTypeByIndex(v113_ - 1).index
		v114_ = self.growthStates:getState()
	else
		v114_ = 0
	end
	local v115_ = self.groundTypes:getState()
	local v116_ = self.groundAngleValues[self.groundAngles:getState()]
	local v117_ = self.sprayTypes:getState()
	local v118_ = self.weed:getState()
	local v119_ = self.stoneLevels[self.stones:getState()]
	local v120_ = self.sprayLevel:getState() - 1
	local v121_ = self.limeLevel:getState() - 1
	local v122_ = self.plowLevel:getState() - 1
	local v123_ = self.rollerLevel:getState() - 1
	local v124_ = self.stubbleShredLevel:getState() - 1
	for _, v125_ in ipairs(v107_) do
		if self.buyField then
			local v126_ = v125_.farmland
			if v126_ ~= nil then
				v126_:setOwnerFarmId(g_localPlayer.farmId)
			end
		end
		local v127_ = FieldUpdateTask.new()
		v127_:setField(v125_)
		v127_:setArea(v125_:getDensityMapPolygon())
		v127_:setFruit(v112_, v114_)
		v127_:setWeedState(v118_)
		v127_:setStoneLevel(v119_)
		v127_:setGroundType(v115_)
		v127_:setGroundAngle(v116_)
		v127_:setSprayType(v117_)
		v127_:setSprayLevel(v120_)
		v127_:setLimeLevel(v121_)
		v127_:setPlowLevel(v122_)
		v127_:setRollerLevel(v123_)
		v127_:setStubbleShredLevel(v124_)
		v127_:resetDisplacement()
		v127_:clearTireTracks()
		g_fieldManager:addFieldUpdateTask(v127_)
	end
end
