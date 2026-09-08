ExtendedSprayer = {}
ExtendedSprayer.SPEC_NAME = g_currentModName .. ".extendedSprayer"
ExtendedSprayer.SPEC_TABLE_NAME = "spec_" .. g_currentModName .. ".extendedSprayer"
source(g_currentModDirectory .. "scripts/hud/ExtendedSprayerHUDExtension.lua")

function ExtendedSprayer.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(Sprayer, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(PrecisionFarmingStatistic, specializations)
	end
	return v2_
end
function ExtendedSprayer.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("pulseWidthModulation", g_i18n:getText("configuration_pulseWidthModulation"), "sprayer", VehicleConfigurationItem)
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("ExtendedSprayer")
	v3_:register(XMLValueType.BOOL, "vehicle.sprayer.pulseWidthModulationConfigurations#isAlwaysActive", "Pulse width modulation is always active", false)
	v3_:register(XMLValueType.BOOL, "vehicle.sprayer.speedDependentApplication#isSupported", "Spreader / sprayer does automatically reduce the application rate while driving slower", "by default supported on all except sprayers")
	v3_:setXMLSpecializationType()
end

function ExtendedSprayer.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setSprayAmountAutoMode", ExtendedSprayer.setSprayAmountAutoMode)
	SpecializationUtil.registerFunction(vehicleType, "setSprayAmountManualValue", ExtendedSprayer.setSprayAmountManualValue)
	SpecializationUtil.registerFunction(vehicleType, "setSprayAmountAutoFruitTypeIndex", ExtendedSprayer.setSprayAmountAutoFruitTypeIndex)
	SpecializationUtil.registerFunction(vehicleType, "setSprayAmountDefaultFruitRequirementIndex", ExtendedSprayer.setSprayAmountDefaultFruitRequirementIndex)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentSprayerMode", ExtendedSprayer.getCurrentSprayerMode)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentNitrogenLevelOffset", ExtendedSprayer.getCurrentNitrogenLevelOffset)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentNitrogenUsageLevelOffset", ExtendedSprayer.getCurrentNitrogenUsageLevelOffset)
	SpecializationUtil.registerFunction(vehicleType, "getUseExtendedSprayerHudExtension", ExtendedSprayer.getUseExtendedSprayerHudExtension)
	SpecializationUtil.registerFunction(vehicleType, "getShowExtendedSprayerHudExtension", ExtendedSprayer.getShowExtendedSprayerHudExtension)
	SpecializationUtil.registerFunction(vehicleType, "getIsUsingExactNitrogenAmount", ExtendedSprayer.getIsUsingExactNitrogenAmount)
	SpecializationUtil.registerFunction(vehicleType, "getIsPrecisionSprayingRequired", ExtendedSprayer.getIsPrecisionSprayingRequired)
	SpecializationUtil.registerFunction(vehicleType, "preProcessExtUnderRootFertilizerArea", ExtendedSprayer.preProcessExtUnderRootFertilizerArea)
	SpecializationUtil.registerFunction(vehicleType, "updateWorkAreaSubSectionData", ExtendedSprayer.updateWorkAreaSubSectionData)
	SpecializationUtil.registerFunction(vehicleType, "processWorkAreaSubSectionData", ExtendedSprayer.processWorkAreaSubSectionData)
end

function ExtendedSprayer.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateWorkAreaWidth", ExtendedSprayer.updateWorkAreaWidth)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSprayerUsage", ExtendedSprayer.getSprayerUsage)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "processSprayerArea", ExtendedSprayer.processSprayerArea)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "changeSeedIndex", ExtendedSprayer.changeSeedIndex)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSprayerDoubledAmountActive", ExtendedSprayer.getSprayerDoubledAmountActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateSprayerEffects", ExtendedSprayer.updateSprayerEffects)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateExtendedSprayerNozzleEffectState", ExtendedSprayer.updateExtendedSprayerNozzleEffectState)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setSprayerAITerrainDetailProhibitedRange", ExtendedSprayer.setSprayerAITerrainDetailProhibitedRange)
end

function ExtendedSprayer.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onChangedFillType", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onVariableWorkWidthSectionChanged", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", ExtendedSprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", ExtendedSprayer)
end

-- Local values: spec
function ExtendedSprayer:onPreLoad(savegame)
	local v8_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
	if g_precisionFarming ~= nil then
		v8_.soilMap = g_precisionFarming.soilMap
		v8_.pHMap = g_precisionFarming.pHMap
		v8_.nitrogenMap = g_precisionFarming.nitrogenMap
	end
end

-- Local values: spec, _, _, nMaxValue, sprayerFillUnitIndex, _, workArea, _, workArea, _, workArea
function ExtendedSprayer:onLoad(savegame)
	local v10_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
	v10_.pwmEnabled = (self.configurations.pulseWidthModulation or 1) > 1
	v10_.spotSprayEnabled = (self.configurations.weedSpotSpray or 1) > 1
	if self.xmlFile:getValue("vehicle.sprayer.pulseWidthModulationConfigurations#isAlwaysActive", false) then
		v10_.pwmEnabled = true
	end
	if self.spec_sowingMachine ~= nil then
		v10_.pwmEnabled = true
	end
	v10_.texts = {}
	v10_.texts.toggleSprayAmountAutoModePos = g_i18n:getText("action_toggleSprayAmountAutoModePos", self.customEnvironment)
	v10_.texts.toggleSprayAmountAutoModeNeg = g_i18n:getText("action_toggleSprayAmountAutoModeNeg", self.customEnvironment)
	v10_.texts.toggleSprayAmountAutoManual = g_i18n:getText("action_toggleSprayAmountManual", self.customEnvironment)
	v10_.texts.toggleSprayDefaultFruitRequirement = g_i18n:getText("action_toggleSprayDefaultFruitRequirement", self.customEnvironment)
	v10_.lastLitersPerHectar = 0
	v10_.lastNitrogenProportion = 0
	v10_.lastRegularUsage = 0
	v10_.lastTouchedSoilType = 0
	v10_.lastTouchedSoilTypeSent = 0
	v10_.lastGroundUpdateDistance = math.huge
	v10_.groundUpdateDistance = 2
	v10_.phActualValue = 0
	v10_.phActualValueSent = 0
	v10_.phTargetValue = 0
	v10_.phTargetValueSent = 0
	v10_.nActualValue = 0
	v10_.nActualValueSent = 0
	v10_.nTargetValue = 0
	v10_.nTargetValueSent = 0
	v10_.sprayAmountAutoMode = true
	v10_.sprayAmountAutoModeChangeAllowed = true
	v10_.sprayAmountManual = 1
	v10_.sprayAmountManualMin = 1
	v10_.sprayAmountManualMax = 1
	v10_.inputActionToggleAuto = InputAction.PRECISIONFARMING_SPRAY_AMOUNT_MODE
	v10_.inputActionToggleSprayAmount = InputAction.PRECISIONFARMING_SPRAY_AMOUNT
	v10_.isDoingMissionWork = false
	local _, _, v11_ = v10_.nitrogenMap:getMinMaxValue()
	v10_.sprayAmountManualMax = v11_ - 1
	v10_.attachStateChanged = false
	v10_.nApplyAutoModeFruitType = FruitType.UNKNOWN
	v10_.nApplyAutoModeFruitTypeSent = FruitType.UNKNOWN
	v10_.nApplyAutoModeFruitRequirementDefaultIndex = 1
	v10_.nApplyAutoModeFruitTypeRequiresDefaultMode = false
	v10_.lastAreaChangeTime = -math.huge
	v10_.lastSprayerEffectState = true
	v10_.densityMapParallelogram = DensityMapParallelogram.new()
	v10_.densityMapPolygon = DensityMapPolygon.new()
	v10_.densityMapPolygon:addPolygonPoint(0, 0)
	v10_.densityMapPolygon:addPolygonPoint(0, 0)
	v10_.densityMapPolygon:addPolygonPoint(0, 0)
	v10_.densityMapPolygon:addPolygonPoint(0, 0)
	local v12_ = self:getSprayerFillUnitIndex()
	v10_.isSlurryTanker = self:getFillUnitAllowsFillType(v12_, FillType.LIQUIDMANURE) or self:getFillUnitAllowsFillType(v12_, FillType.DIGESTATE)
	v10_.isManureSpreader = self:getFillUnitAllowsFillType(v12_, FillType.MANURE)
	v10_.isSolidFertilizerSprayer = self:getFillUnitAllowsFillType(v12_, FillType.FERTILIZER) or self:getFillUnitAllowsFillType(v12_, FillType.LIME)
	v10_.isLiquidFertilizerSprayer = self:getFillUnitAllowsFillType(v12_, FillType.LIQUIDFERTILIZER)
	v10_.speedDependentApplication = self.xmlFile:getValue("vehicle.sprayer.speedDependentApplication#isSupported", not v10_.isLiquidFertilizerSprayer)
	v10_.usageValuesDirtyFlag = self:getNextDirtyFlag()
	if self:getUseExtendedSprayerHudExtension() then
		v10_.hudExtension = ExtendedSprayerHUDExtension.new(self)
	end
	v10_.sprayerWorkAreas = self:getTypedWorkAreas(WorkAreaType.SPRAYER)
	v10_.sowingMachineWorkAreas = self:getTypedWorkAreas(WorkAreaType.SOWINGMACHINE)
	v10_.cultivatorWorkAreas = self:getTypedWorkAreas(WorkAreaType.CULTIVATOR)
	v10_.workAreas = {}
	for _, v13_ in pairs(v10_.sprayerWorkAreas) do
		local v14_ = v10_.workAreas
		table.insert(v14_, v13_)
	end
	for _, v15_ in pairs(v10_.sowingMachineWorkAreas) do
		local v16_ = v10_.workAreas
		table.insert(v16_, v15_)
	end
	for _, v17_ in pairs(v10_.cultivatorWorkAreas) do
		local v18_ = v10_.workAreas
		table.insert(v18_, v17_)
	end
	v10_.useFertilizerSprayType = #v10_.cultivatorWorkAreas > 0 and true or #v10_.sowingMachineWorkAreas > 0
	local v19_, v20_, v21_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
	v10_.groundTypeMapId = v19_
	v10_.groundTypeFirstChannel = v20_
	v10_.groundTypeNumChannels = v21_
end

-- Local values: spec, specName
function ExtendedSprayer:onPostLoad(savegame)
	if savegame ~= nil and not savegame.resetVehicles then
		local v24_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
		local v25_ = ExtendedSprayer.SPEC_NAME
		self:setSprayAmountAutoMode(Utils.getNoNil(savegame.xmlFile:getBool(savegame.key .. "." .. v25_ .. "#sprayAmountAutoMode"), v24_.sprayAmountAutoMode), true)
		self:setSprayAmountManualValue(savegame.xmlFile:getInt(savegame.key .. "." .. v25_ .. "#sprayAmountManual") or v24_.sprayAmountManual, true)
	end
end

-- Local values: spec
function ExtendedSprayer:onDelete()
	local v27_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
	if v27_.hudExtension ~= nil then
		v27_.hudExtension:delete()
	end
end

-- Local values: spec
function ExtendedSprayer:saveToXMLFile(xmlFile, key, usedModNames)
	local v31_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
	xmlFile:setBool(key .. "#sprayAmountAutoMode", v31_.sprayAmountAutoMode)
	xmlFile:setInt(key .. "#sprayAmountManual", v31_.sprayAmountManual)
end

-- Local values: sprayAmountAutoMode, sprayAmountManual
function ExtendedSprayer:onReadStream(streamId, connection)
	local v34_ = streamReadBool(streamId)
	local v35_ = streamReadUIntN(streamId, NitrogenMap.NUM_BITS)
	self:setSprayAmountAutoMode(v34_, true)
	self:setSprayAmountManualValue(v35_, true)
end

-- Local values: spec
function ExtendedSprayer:onWriteStream(streamId, connection)
	local v38_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
	streamWriteBool(streamId, v38_.sprayAmountAutoMode)
	streamWriteUIntN(streamId, v38_.sprayAmountManual, NitrogenMap.NUM_BITS)
end

-- Local values: spec
function ExtendedSprayer:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local v42_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
		if streamReadBool(streamId) then
			v42_.phActualValue = streamReadUIntN(streamId, PHMap.NUM_BITS)
			v42_.phTargetValue = streamReadUIntN(streamId, PHMap.NUM_BITS)
			v42_.nActualValue = streamReadUIntN(streamId, NitrogenMap.NUM_BITS)
			v42_.nTargetValue = streamReadUIntN(streamId, NitrogenMap.NUM_BITS)
			v42_.lastTouchedSoilType = streamReadUIntN(streamId, 3)
			if streamReadBool(streamId) then
				self:setSprayAmountAutoFruitTypeIndex(streamReadUIntN(streamId, FruitTypeManager.SEND_NUM_BITS))
				return
			end
			self:setSprayAmountAutoFruitTypeIndex(nil)
		end
	end
end

-- Local values: spec
function ExtendedSprayer:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v47_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
		local v48_ = streamWriteBool
		local v49_ = v47_.usageValuesDirtyFlag
		if v48_(streamId, bit32.band(dirtyMask, v49_) ~= 0) then
			streamWriteUIntN(streamId, v47_.phActualValue, PHMap.NUM_BITS)
			streamWriteUIntN(streamId, v47_.phTargetValue, PHMap.NUM_BITS)
			streamWriteUIntN(streamId, v47_.nActualValue, NitrogenMap.NUM_BITS)
			streamWriteUIntN(streamId, v47_.nTargetValue, NitrogenMap.NUM_BITS)
			streamWriteUIntN(streamId, v47_.lastTouchedSoilType, 3)
			if streamWriteBool(streamId, v47_.nApplyAutoModeFruitType ~= nil) then
				streamWriteUIntN(streamId, v47_.nApplyAutoModeFruitType, FruitTypeManager.SEND_NUM_BITS)
			end
		end
	end
end

-- Local values: spec, _, workArea, isAllowed, sprayType, _, workArea, _, workArea, _, vehicle, _, workArea, hud
function ExtendedSprayer:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v51_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
	if self.isServer then
		if not self.finishedFirstUpdate then
			local v52_, v53_ = self:getCurrentSprayerMode()
			v51_.isLiming = v52_
			v51_.isFertilizing = v53_
			ExtendedSprayer.updateActionEventState(self)
			ExtendedSprayer.updateActionEventAutoModeDefault(self)
		end
		if self.finishedFirstUpdate then
			v51_.lastGroundUpdateDistance = v51_.lastGroundUpdateDistance + self.lastMovedDistance
			if v51_.lastGroundUpdateDistance > v51_.groundUpdateDistance then
				v51_.lastGroundUpdateDistance = 0
				for _, v54_ in pairs(v51_.sprayerWorkAreas) do
					local v55_ = true
					if v54_.sprayType ~= nil then
						local v56_ = self:getActiveSprayType()
						if v56_ ~= nil and v56_.index ~= v54_.sprayType then
							v55_ = false
						end
					end
					if v55_ then
						self:updateWorkAreaSubSectionData(v54_)
					end
				end
				for _, v57_ in pairs(v51_.sowingMachineWorkAreas) do
					self:updateWorkAreaSubSectionData(v57_)
				end
				for _, v58_ in pairs(v51_.cultivatorWorkAreas) do
					self:updateWorkAreaSubSectionData(v58_)
				end
				for _, v59_ in ipairs(self.rootVehicle.childVehicles) do
					if v59_["spec_pdlc_nexatPack.cultivatorSowingMachineExtension"] ~= nil then
						for _, v60_ in pairs(v59_.spec_workArea.workAreas) do
							if v60_.type == WorkAreaType.CULTIVATOR then
								if v60_.subSectionData == nil then
									self:updateWorkAreaWidth(0, v60_)
								end
								self:updateWorkAreaSubSectionData(v60_)
							end
						end
					end
				end
			end
		end
	end
	if self.isActiveForInputIgnoreSelectionIgnoreAI and (self:getShowExtendedSprayerHudExtension() and v51_.hudExtension ~= nil) then
		g_currentMission.hud:addHelpExtension(v51_.hudExtension)
	end
end

-- Local values: spec, isLiming, isFertilizing, _, _, _, _, mission, isDoingMissionWork
function ExtendedSprayer:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v62_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
	if self.isClient then
		if self:getIsTurnedOn() then
			ExtendedSprayer.updateSprayerEffectState(self)
		else
			v62_.lastSprayerEffectState = true
		end
	end
	local v63_, v64_ = self:getCurrentSprayerMode()
	if v63_ ~= v62_.isLiming or v64_ ~= v62_.isFertilizing then
		v62_.isLiming = v63_
		v62_.isFertilizing = v64_
		ExtendedSprayer.updateActionEventState(self)
		ExtendedSprayer.updateActionEventAutoModeDefault(self)
	end
	if self.isActiveForInputIgnoreSelectionIgnoreAI then
		ExtendedSprayer.updateMinimapActiveState(self)
		local _, _, _, _, v65_ = self:getPFStatisticInfo()
		local v66_ = v65_ == nil and v62_.sprayAmountAutoMode
		if v66_ then
			v66_ = v62_.nApplyAutoModeFruitTypeRequiresDefaultMode
		end
		if v62_.isDoingMissionWork ~= v66_ then
			v62_.isDoingMissionWork = v66_
			ExtendedSprayer.updateMinimapActiveState(self)
		end
	end
end

-- Local values: spec, _, _, pHMaxValue, _, _, nMaxValue
function ExtendedSprayer:onChangedFillType(fillUnitIndex, fillTypeIndex, oldFillTypeIndex)
	local v69_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
	if v69_.isSolidFertilizerSprayer and fillTypeIndex == FillType.LIME then
		local _, _, v70_ = v69_.pHMap:getMinMaxValue()
		v69_.sprayAmountManualMax = v70_ - 1
	else
		local _, _, v71_ = v69_.nitrogenMap:getMinMaxValue()
		v69_.sprayAmountManualMax = v71_ - 1
	end
end

function ExtendedSprayer:onTurnedOn()
	if self.isClient then
		ExtendedSprayer.updateSprayerEffectState(self, true)
	end
end

function ExtendedSprayer:onTurnedOff()
	if self.isClient then
		ExtendedSprayer.updateSprayerEffectState(self, true)
	end
end

-- Local values: spec
function ExtendedSprayer:onStateChange(state, data)
	local v76_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
	if state == VehicleStateChange.ATTACH or state == VehicleStateChange.DETACH then
		v76_.attachStateChanged = true
	end
end

-- Local values: vehicles, i, vehicle
function ExtendedSprayer:onVariableWorkWidthSectionChanged()
	local v78_ = self.rootVehicle.childVehicles
	for v79_ = 1, #v78_ do
		local v80_ = v78_[v79_]
		if SpecializationUtil.hasSpecialization(CropSensor, v80_.specializations) then
			v80_:updateCropSensorWorkingWidth()
		end
	end
	if self.isClient then
		ExtendedSprayer.updateSprayerEffectState(self, true)
	end
end

-- Local values: spec, _, actionEventId, _, actionEventId
function ExtendedSprayer:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v83_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
		self:clearActionEventsTable(v83_.actionEvents)
		v83_.pHMap:setRequireMinimapDisplay(false, self)
		v83_.nitrogenMap:setRequireMinimapDisplay(false, self)
		if isActiveForInputIgnoreSelection and self == ExtendedSprayer.getValidSprayerToUse(self) then
			if v83_.sprayAmountAutoModeChangeAllowed then
				local _, v84_ = self:addActionEvent(v83_.actionEvents, v83_.inputActionToggleAuto, self, ExtendedSprayer.actionEventToggleAuto, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(v84_, GS_PRIO_VERY_HIGH)
			end
			local _, v85_ = self:addActionEvent(v83_.actionEvents, v83_.inputActionToggleSprayAmount, self, ExtendedSprayer.actionEventChangeSprayAmount, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v85_, GS_PRIO_VERY_HIGH)
			g_inputBinding:setActionEventText(v85_, v83_.texts.toggleSprayAmountAutoManual)
			if self.spec_sowingMachine == nil then
				local _, v86_ = self:addActionEvent(v83_.actionEvents, InputAction.TOGGLE_SEEDS, self, ExtendedSprayer.actionEventChangeDefaultFruitRequirement, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(v86_, GS_PRIO_VERY_HIGH)
				g_inputBinding:setActionEventText(v86_, v83_.texts.toggleSprayDefaultFruitRequirement)
			end
			ExtendedSprayer.updateActionEventState(self)
			ExtendedSprayer.updateActionEventAutoModeDefault(self)
			ExtendedSprayer.updateMinimapActiveState(self)
		end
		v83_.attachStateChanged = true
	end
end

-- Local values: vehicleList, i, subVehicle
function ExtendedSprayer:getValidSprayerToUse()
	local v88_ = self.rootVehicle.childVehicles
	for v89_ = 1, #v88_ do
		local v90_ = v88_[v89_]
		if ExtendedSprayer.getIsVehicleValid(v90_) then
			return v90_
		end
	end
	return nil
end

function ExtendedSprayer.getIsVehicleValid(vehicle)
	if SpecializationUtil.hasSpecialization(ExtendedSprayer, vehicle.specializations) then
		if SpecializationUtil.hasSpecialization(WorkArea, vehicle.specializations) then
			if #vehicle.spec_workArea.workAreas == 0 then
				return false
			else
				return (not SpecializationUtil.hasSpecialization(ManureBarrel, vehicle.specializations) or vehicle.spec_manureBarrel.attachedTool == nil) and true or false
			end
		else
			return false
		end
	else
		return false
	end
end

function ExtendedSprayer:actionEventToggleAuto(actionName, inputValue, callbackState, isAnalog)
	self:setSprayAmountAutoMode()
end

-- Local values: spec
function ExtendedSprayer:actionEventChangeSprayAmount(actionName, inputValue, callbackState, isAnalog)
	self:setSprayAmountManualValue(self[ExtendedSprayer.SPEC_TABLE_NAME].sprayAmountManual + math.sign(inputValue))
end

-- Local values: spec
function ExtendedSprayer:actionEventChangeDefaultFruitRequirement(actionName, inputValue, callbackState, isAnalog)
	local v96_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
	self:setSprayAmountDefaultFruitRequirementIndex(v96_.nitrogenMap:getNextFruitRequirementIndex(v96_.nApplyAutoModeFruitRequirementDefaultIndex))
end

-- Local values: spec, actionEventToggleAuto, actionEventToggleSprayAmount
function ExtendedSprayer:updateActionEventState()
	local v98_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
	local v99_ = v98_.actionEvents[v98_.inputActionToggleAuto]
	if v99_ ~= nil then
		g_inputBinding:setActionEventActive(v99_.actionEventId, v98_.isLiming or v98_.isFertilizing)
		g_inputBinding:setActionEventText(v99_.actionEventId, v98_.sprayAmountAutoMode and v98_.texts.toggleSprayAmountAutoModeNeg or v98_.texts.toggleSprayAmountAutoModePos)
	end
	local v100_ = v98_.actionEvents[v98_.inputActionToggleSprayAmount]
	if v100_ ~= nil then
		local v101_ = g_inputBinding
		local v102_ = v100_.actionEventId
		local v103_ = not v98_.sprayAmountAutoMode
		if v103_ then
			v103_ = v98_.isLiming or v98_.isFertilizing
		end
		v101_:setActionEventActive(v102_, v103_)
	end
end

-- Local values: spec, actionEvent
function ExtendedSprayer:updateActionEventAutoModeDefault()
	local v105_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
	local v106_ = v105_.actionEvents[InputAction.TOGGLE_SEEDS]
	if v106_ ~= nil then
		local v107_ = g_inputBinding
		local v108_ = v106_.actionEventId
		local v109_ = v105_.isFertilizing and v105_.sprayAmountAutoMode
		if v109_ then
			v109_ = v105_.nApplyAutoModeFruitType == nil and true or v105_.nApplyAutoModeFruitType == FruitType.UNKNOWN
		end
		v107_:setActionEventActive(v108_, v109_)
	end
end

-- Local values: firstEmptySource, firstEmptySourceFillUnitIndex, fillUnitIndex, spec, _, supportedSprayType, _, src, vehicle, fillLevel
function ExtendedSprayer.getFillTypeSourceVehicle(sprayer)
	local v111_ = nil
	local v112_ = 1
	local v113_ = sprayer:getSprayerFillUnitIndex()
	if sprayer:getFillUnitFillLevel(v113_) <= 0 then
		local v114_ = sprayer.spec_sprayer
		for _, v115_ in ipairs(v114_.supportedSprayTypes) do
			for _, v116_ in ipairs(v114_.fillTypeSources[v115_]) do
				local v117_ = v116_.vehicle
				local v118_ = v117_:getFillUnitFillLevel(v116_.fillUnitIndex)
				if v117_:getFillUnitFillType(v116_.fillUnitIndex) == v115_ then
					if v118_ > 0 then
						return v117_, v116_.fillUnitIndex
					end
				elseif v118_ == 0 and v117_:getFillUnitSupportsFillType(v116_.fillUnitIndex, v115_) then
					v112_ = v116_.fillUnitIndex
					v111_ = v117_
				end
			end
		end
	end
	if sprayer:getIsAIActive() and sprayer:getFillUnitCapacity(v113_) == 0 then
		return v111_ or sprayer, v112_ or v113_
	else
		return sprayer, v113_
	end
end

-- Local values: sprayer, fillUnitIndex, fillType, spec
function ExtendedSprayer:getCurrentSprayerMode()
	local v120_, v121_ = ExtendedSprayer.getFillTypeSourceVehicle(self)
	local v122_ = v120_:getFillUnitFillType(v121_)
	if v122_ == FillType.UNKNOWN then
		if self:getIsAIActive() then
			return false, true
		end
		v122_ = v120_:getFillUnitLastValidFillType(v121_)
	end
	if v122_ == FillType.LIME then
		return true, false
	elseif self[ExtendedSprayer.SPEC_TABLE_NAME].nitrogenMap:getFillTypeIsFertilizer(v122_) then
		return false, true
	elseif v122_ == FillType.HERBICIDE then
		return false, false
	else
		return false, false
	end
end

function ExtendedSprayer:getCurrentNitrogenLevelOffset(lastChangeLevels)
	return 0
end

function ExtendedSprayer:getCurrentNitrogenUsageLevelOffset(lastChangeLevels)
	return 0
end

function ExtendedSprayer:getUseExtendedSprayerHudExtension()
	if SpecializationUtil.hasSpecialization(WorkArea, self.specializations) then
		return #self.spec_workArea.workAreas ~= 0
	else
		return false
	end
end

-- Local values: spec, sourceVehicle, sourceFillUnitIndex
function ExtendedSprayer:getShowExtendedSprayerHudExtension()
	local v125_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
	if not self.isClient then
		return false
	end
	if self.spec_manureBarrel ~= nil and self.spec_manureBarrel.attachedTool ~= nil then
		return false
	end
	if not (v125_.isSlurryTanker or v125_.isManureSpreader) then
		local v126_, v127_ = ExtendedSprayer.getFillTypeSourceVehicle(self)
		if v126_:getFillUnitFillLevel(v127_) <= 0 and not self:getIsAIActive() then
			return false
		end
		if not (v125_.isLiming or v125_.isFertilizing) then
			return false
		end
	end
	return true
end

function ExtendedSprayer:getIsUsingExactNitrogenAmount()
	return true
end

-- Local values: spec, _, _, _, isOnField, isActive, sprayer, fillUnitIndex
function ExtendedSprayer:updateMinimapActiveState()
	local v129_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
	local _, _, _, v130_ = self:getPFStatisticInfo()
	if v130_ then
		local v131_, v132_ = ExtendedSprayer.getFillTypeSourceVehicle(self)
		if v130_ then
			v130_ = v131_:getFillUnitFillLevel(v132_) > 0 and true or self:getIsAIActive()
		end
	end
	if v130_ then
		v130_ = v129_.isLiming or v129_.isFertilizing
	end
	if v129_.isLiming then
		v129_.pHMap:setRequireMinimapDisplay(v130_, self, self:getIsSelected())
	elseif v129_.isFertilizing then
		v129_.nitrogenMap:setRequireMinimapDisplay(v130_, self, self:getIsSelected())
		v129_.nitrogenMap:setMinimapMissionState(v129_.isDoingMissionWork)
	end
end

-- Local values: spec, dataUncovered, _, workArea
function ExtendedSprayer:getIsPrecisionSprayingRequired()
	local v134_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
	if v134_.isDoingMissionWork then
		return true
	end
	if v134_.sprayAmountAutoMode then
		local v135_ = false
		for _, v136_ in pairs(v134_.workAreas) do
			if v136_.isPrecisionFarmingDataUncovered then
				v135_ = true
				break
			end
		end
		if not v135_ then
			return true
		end
		if not v134_.pwmEnabled then
			if v134_.isLiming then
				if v134_.phActualValue >= v134_.phTargetValue then
					return false
				end
			elseif v134_.isFertilizing and v134_.nActualValue >= v134_.nTargetValue then
				return false
			end
		end
	end
	return true
end

-- Local values: spec, effectState, specSprayer, sprayType, fillType, _, _sprayType
function ExtendedSprayer:updateSprayerEffectState(force)
	local v139_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
	local v140_ = self:getIsPrecisionSprayingRequired() and self:getAreEffectsVisible()
	if v140_ then
		v140_ = self:getIsTurnedOn()
	end
	if v139_.lastSprayerEffectState ~= v140_ or force then
		local v141_ = self.spec_sprayer
		local v142_ = self:getActiveSprayType()
		if v140_ then
			local v143_ = self:getFillUnitLastValidFillType(self:getSprayerFillUnitIndex())
			if v143_ == FillType.UNKNOWN then
				v143_ = self:getFillUnitFirstSupportedFillType(self:getSprayerFillUnitIndex())
			end
			g_effectManager:setEffectTypeInfo(v141_.effects, v143_)
			g_effectManager:startEffects(v141_.effects)
			g_soundManager:playSamples(v141_.samples.spray)
			if v142_ ~= nil then
				g_effectManager:setEffectTypeInfo(v142_.effects, v143_)
				g_effectManager:startEffects(v142_.effects)
				g_animationManager:startAnimations(v142_.animationNodes)
				g_soundManager:playSamples(v142_.samples.spray)
			end
			g_animationManager:startAnimations(v141_.animationNodes)
		else
			g_effectManager:stopEffects(v141_.effects)
			g_soundManager:stopSamples(v141_.samples.spray)
			for _, v144_ in ipairs(v141_.sprayTypes) do
				g_effectManager:stopEffects(v144_.effects)
				g_animationManager:stopAnimations(v144_.animationNodes)
				g_soundManager:stopSamples(v144_.samples.spray)
			end
			g_animationManager:stopAnimations(v141_.animationNodes)
		end
		v139_.lastSprayerEffectState = v140_
	end
end

-- Local values: specWorkArea, spec, xOffset, _, _, isFertilizerSpreader, numMainDivisions, numSubDivisions, subSectionIndex, mainIndex, subIndex, subSectionData, index, _, index, _
function ExtendedSprayer:updateWorkAreaWidth(superFunc, workAreaIndex, workArea)
	superFunc(self, workAreaIndex)
	local v149_ = workArea or self.spec_workArea.workAreas[workAreaIndex]
	if v149_ ~= nil then
		local v150_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
		local v151_, _, _ = localToLocal(v149_.start, self.rootNode, 0, 0, 0)
		local v152_ = math.abs(v151_) < 0.1
		local v153_ = v149_.workWidth * 0.5
		local v154_ = math.ceil(v153_)
		local v155_
		if v152_ then
			local v156_ = v149_.workWidth * 0.5 * 0.5
			v154_ = math.ceil(v156_)
			v155_ = 2
		else
			v155_ = 1
		end
		if v155_ ~= v149_.numMainDivisions or v154_ ~= v149_.numSubDivisions then
			v149_.numMainDivisions = v155_
			v149_.numSubDivisions = v154_
			v149_.maxPHApplicationOffset = 0
			v149_.maxNApplicationOffset = 0
			v149_.subSectionData = {}
			local v157_ = 1
			for v158_ = 1, v149_.numMainDivisions do
				for v159_ = 1, v149_.numSubDivisions do
					local v160_
					if v149_.subSectionData[v157_] == nil then
						v149_.subSectionData[v157_] = {}
						v160_ = v149_.subSectionData[v157_]
					else
						v160_ = nil
					end
					v160_.index = v157_
					v160_.mainIndex = v158_
					v160_.subIndex = v159_
					v160_.isValid = false
					v160_.nitrogenLevel = 0
					v160_.nitrogenTargetLevel = 0
					v160_.phLevel = 0
					v160_.phTargetLevel = 0
					v160_.soilTypeIndex = 0
					v160_.fruitType = FruitType.UNKNOWN
					v160_.growthState = 0
					v160_.lastSpeed = 0
					v160_.phApplicationOffset = 0
					v160_.nApplicationOffset = 0
					if v149_.numMainDivisions > 1 and v149_.numSubDivisions > 1 then
						local v161_ = (v159_ - 1) / (v149_.numSubDivisions - 1) * 2.01
						v160_.phApplicationOffset = -math.floor(v161_)
						local v162_ = (v159_ - 1) / (v149_.numSubDivisions - 1) * 4.01
						v160_.nApplicationOffset = -math.floor(v162_)
						local v163_ = v149_.maxPHApplicationOffset
						local v164_ = v160_.phApplicationOffset
						local v165_ = math.abs(v164_)
						v149_.maxPHApplicationOffset = math.max(v163_, v165_)
						local v166_ = v149_.maxNApplicationOffset
						local v167_ = v160_.nApplicationOffset
						local v168_ = math.abs(v167_)
						v149_.maxNApplicationOffset = math.max(v166_, v168_)
					end
					v160_.lastDetectionX = 0
					v160_.lastDetectionZ = 0
					v157_ = v157_ + 1
				end
			end
			v149_.numSubSections = v157_ - 1
			v149_.nitrogenLevel = 0
			v149_.nitrogenTargetLevel = 0
			v149_.phLevel = 0
			v149_.phTargetLevel = 0
			v149_.lastSpeed = 0
			v149_.fruitType = FruitType.UNKNOWN
			if v149_.fruitTypes == nil then
				v149_.fruitTypes = {}
			end
			for v169_, _ in pairs(g_fruitTypeManager:getFruitTypes()) do
				v149_.fruitTypes[v169_] = 0
			end
			v149_.growthState = 0
			v149_.soilTypeIndex = 0
			if v149_.soilTypes == nil then
				v149_.soilTypes = {}
			end
			if v150_.soilMap ~= nil and v150_.soilMap.soilTypes ~= nil then
				for v170_, _ in pairs(v150_.soilMap.soilTypes) do
					v149_.soilTypes[v170_] = 0
				end
			end
			v150_.lastGroundUpdateDistance = math.huge
		end
	end
end

-- Local values: spec, specSpray, sprayType, fillType, lockSprayType, checkSubSectionPos, moveDirX, _, moveDirZ, worldStartX, y, worldStartZ, worldWidthX, _, worldWidthZ, worldHeightX, _, worldHeightZ, dirX, dirZ, width, subSectionWidth, i, subSectionData, checkX, checkZ, dirX, dirZ, width, subSectionWidth, i, subSectionData, checkX, checkZ, i, subSectionData, checkX, checkZ, index, _, index, _, numValidSubSections, numValidNTargetSections, i, subSectionData, i, subSectionData, maxSoilTypeIndex, maxSoilTypeCount, index, count, maxFruitTypeIndex, maxFruitTypeCount, index, count, fruitTypeIndex, applicationRate, _, i, subSectionData, difference, difference, i, subSectionData, nApplyAutoModeFruitType, _, adjustedToFruitType
function ExtendedSprayer:updateWorkAreaSubSectionData(workArea)
	local v_u_173_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
	local v_u_174_ = self.spec_sprayer.workAreaParameters.sprayType
	if v_u_174_ == nil then
		local v175_ = self:getFillUnitFirstSupportedFillType(self:getSprayerFillUnitIndex())
		v_u_174_ = g_sprayTypeManager:getSprayTypeIndexByFillTypeIndex(v175_)
	end
	local v_u_176_
	if v_u_173_.useFertilizerSprayType then
		v_u_176_ = SprayType.FERTILIZER
	else
		v_u_176_ = v_u_174_
	end
	if workArea.subSectionData == nil then
		self:updateWorkAreaWidth(workArea.index)
	end
	local function v198_(p177_, p178_, p179_, p180_, p181_, p182_)
		-- upvalues: (copy) self, (copy) v_u_173_, (ref) v_u_176_, (ref) v_u_174_
		local v183_, v184_, v185_ = worldToLocal(self.rootNode, p178_, p179_, p180_)
		local v186_, _, v187_ = getVelocityAtLocalPos(self.rootNode, v183_, v184_, v185_)
		p177_.lastSpeed = MathUtil.vector2Length(v186_, v187_) * 3.6
		p177_.isValid = v_u_173_.isLiming or v_u_173_.isFertilizing
		p177_.isUncovered = v_u_173_.isLiming or v_u_173_.isFertilizing
		local v188_, v189_
		if v_u_173_.isLiming then
			local v190_
			v188_, v189_, v190_ = v_u_173_.pHMap:getNextValidDetectionPoint(p178_, p180_, p181_, p182_, 10, v_u_176_)
			if v188_ == nil then
				p177_.isValid = false
				v189_ = p180_
				v188_ = p178_
			end
			if not v190_ then
				p177_.isUncovered = false
			end
		else
			v189_ = p180_
			v188_ = p178_
		end
		if v_u_173_.isFertilizing then
			local v191_
			v188_, v189_, v191_ = v_u_173_.nitrogenMap:getNextValidDetectionPoint(p178_, p180_, p181_, p182_, 10, v_u_176_)
			if v188_ == nil then
				p177_.isValid = false
				v189_ = p180_
				v188_ = p178_
			end
			if not v191_ then
				p177_.isUncovered = false
			end
		end
		local v192_ = p178_ - p177_.lastDetectionX
		if math.abs(v192_) <= 0.01 then
			local v193_ = p180_ - p177_.lastDetectionZ
			if math.abs(v193_) <= 0.01 then
				::l17::
				return
			end
		end
		p177_.soilTypeIndex = v_u_173_.soilMap:getTypeIndexAtWorldPos(v188_, v189_)
		if p177_.soilTypeIndex == 0 then
			p177_.isValid = false
		end
		if v_u_173_.isLiming then
			p177_.phLevel = v_u_173_.pHMap:getLevelAtWorldPos(v188_, v189_)
			p177_.phTargetLevel = v_u_173_.pHMap:getOptimalPHValueForSoilTypeIndex(p177_.soilTypeIndex) or p177_.phLevel
		end
		if v_u_173_.isFertilizing then
			p177_.nitrogenLevel = v_u_173_.nitrogenMap:getLevelAtWorldPos(v188_, v189_)
			if self.spec_sowingMachine == nil then
				local v194_, v195_ = FSDensityMapUtil.getFruitTypeIndexAtWorldPos(p178_, p180_)
				p177_.fruitTypeIndex = v194_
				p177_.growthState = v195_
				p177_.fruitTypeIndex = p177_.fruitTypeIndex or FruitType.UNKNOWN
				p177_.growthState = p177_.growthState or 0
				if p177_.fruitTypeIndex ~= FruitType.UNKNOWN then
					local v196_ = g_fruitTypeManager:getFruitTypeByIndex(p177_.fruitTypeIndex)
					if p177_.growthState > v196_.maxHarvestingGrowthState then
						p177_.fruitTypeIndex = FruitType.UNKNOWN
					end
				end
			else
				p177_.fruitTypeIndex = self.spec_sowingMachine.seeds[self.spec_sowingMachine.currentSeed]
				p177_.growthState = 0
			end
			local v197_, _ = v_u_173_.nitrogenMap:getNitrogenApplicationRate(p177_.nitrogenLevel, p177_.fruitTypeIndex, p177_.soilTypeIndex, v_u_174_)
			p177_.nitrogenTargetLevel = p177_.nitrogenLevel + (v197_ or 0)
		end
		p177_.lastDetectionX = p178_
		p177_.lastDetectionZ = p180_
		goto l17
	end
	if workArea.subSectionData ~= nil then
		local v199_, _, v200_ = localDirectionToWorld(workArea.start, 0, 0, 1)
		local v201_, v202_ = MathUtil.vector2Normalize(v199_, v200_)
		local v203_, v204_, v205_ = getWorldTranslation(workArea.start)
		local v206_, _, v207_ = getWorldTranslation(workArea.width)
		local v208_, _, v209_ = getWorldTranslation(workArea.height)
		if workArea.numMainDivisions == 1 then
			local v210_ = v206_ - v203_
			local v211_ = v207_ - v205_
			local v212_ = MathUtil.vector2Length(v210_, v211_)
			local v213_ = v210_ / v212_
			local v214_ = v211_ / v212_
			local v215_ = v212_ / workArea.numSubDivisions
			for v216_ = 1, workArea.numSubDivisions do
				v198_(workArea.subSectionData[v216_], v203_ + v213_ * (v216_ - 0.5) * v215_, v204_, v205_ + v214_ * (v216_ - 0.5) * v215_, v201_, v202_)
			end
		else
			local v217_ = v206_ - v203_
			local v218_ = v207_ - v205_
			local v219_ = MathUtil.vector2Length(v217_, v218_)
			local v220_ = v217_ / v219_
			local v221_ = v218_ / v219_
			local v222_ = v219_ / workArea.numSubDivisions
			for v223_ = 1, workArea.numSubDivisions do
				v198_(workArea.subSectionData[v223_], v203_ + v220_ * (v223_ - 0.5) * v222_, v204_, v205_ + v221_ * (v223_ - 0.5) * v222_, v201_, v202_)
			end
			local v224_ = v208_ - v203_
			local v225_ = v209_ - v205_
			local v226_ = MathUtil.vector2Length(v224_, v225_)
			local v227_ = v224_ / v226_
			local v228_ = v225_ / v226_
			local v229_ = v226_ / workArea.numSubDivisions
			for v230_ = 1, workArea.numSubDivisions do
				v198_(workArea.subSectionData[v230_ + workArea.numSubDivisions], v203_ + v227_ * (v230_ - 0.5) * v229_, v204_, v205_ + v228_ * (v230_ - 0.5) * v229_, v201_, v202_)
			end
		end
		workArea.nitrogenLevel = 0
		workArea.nitrogenLevelMax = 0
		workArea.nitrogenTargetLevel = 0
		workArea.phLevel = 0
		workArea.phLevelMax = 0
		workArea.phTargetLevel = 0
		workArea.lastSpeed = 0
		workArea.fruitTypeIndex = 0
		workArea.growthState = 0
		workArea.soilTypeIndex = 0
		workArea.isPrecisionFarmingDataUncovered = false
		if workArea.numSubSections > 0 then
			for v231_, _ in ipairs(workArea.fruitTypes) do
				workArea.fruitTypes[v231_] = 0
			end
			for v232_, _ in ipairs(workArea.soilTypes) do
				workArea.soilTypes[v232_] = 0
			end
			local v233_ = 0
			local v234_ = 0
			for v235_ = 1, workArea.numSubSections do
				local v236_ = workArea.subSectionData[v235_]
				if v236_.isValid then
					workArea.nitrogenLevel = workArea.nitrogenLevel + v236_.nitrogenLevel
					local v237_ = workArea.nitrogenLevelMax
					local v238_ = v236_.nitrogenLevel
					workArea.nitrogenLevelMax = math.max(v237_, v238_)
					workArea.phLevel = workArea.phLevel + v236_.phLevel
					local v239_ = workArea.phLevelMax
					local v240_ = v236_.phLevel
					workArea.phLevelMax = math.max(v239_, v240_)
					workArea.phTargetLevel = workArea.phTargetLevel + v236_.phTargetLevel
					workArea.lastSpeed = workArea.lastSpeed + v236_.lastSpeed
					if v236_.fruitTypeIndex ~= nil and v236_.fruitTypeIndex ~= FruitType.UNKNOWN then
						workArea.fruitTypes[v236_.fruitTypeIndex] = workArea.fruitTypes[v236_.fruitTypeIndex] + 1
						workArea.nitrogenTargetLevel = workArea.nitrogenTargetLevel + v236_.nitrogenTargetLevel
						v234_ = v234_ + 1
					end
					local v241_ = workArea.growthState
					local v242_ = v236_.growthState
					workArea.growthState = math.max(v241_, v242_)
					if v236_.soilTypeIndex ~= nil and v236_.soilTypeIndex ~= 0 then
						workArea.soilTypes[v236_.soilTypeIndex] = workArea.soilTypes[v236_.soilTypeIndex] + 1
					end
					v233_ = v233_ + 1
				end
				if v236_.isUncovered then
					workArea.isPrecisionFarmingDataUncovered = true
				end
			end
			if v233_ > 0 then
				local v243_ = workArea.nitrogenLevel / v233_
				workArea.nitrogenLevel = math.ceil(v243_)
				local v244_ = workArea.phLevel / v233_
				workArea.phLevel = math.ceil(v244_)
				local v245_ = workArea.phTargetLevel / v233_
				workArea.phTargetLevel = math.ceil(v245_)
				if v234_ > 0 then
					local v246_ = workArea.nitrogenTargetLevel / v234_
					workArea.nitrogenTargetLevel = math.ceil(v246_)
				end
				workArea.lastSpeed = MathUtil.round(workArea.lastSpeed / v233_)
			else
				for v247_ = 1, workArea.numSubSections do
					local v248_ = workArea.subSectionData[v247_]
					workArea.nitrogenLevel = workArea.nitrogenLevel + v248_.nitrogenLevel
					local v249_ = workArea.nitrogenLevelMax
					local v250_ = v248_.nitrogenLevel
					workArea.nitrogenLevelMax = math.max(v249_, v250_)
					workArea.nitrogenTargetLevel = workArea.nitrogenTargetLevel + v248_.nitrogenTargetLevel
					workArea.phLevel = workArea.phLevel + v248_.phLevel
					local v251_ = workArea.phLevelMax
					local v252_ = v248_.phLevel
					workArea.phLevelMax = math.max(v251_, v252_)
					workArea.phTargetLevel = workArea.phTargetLevel + v248_.phTargetLevel
					if v248_.fruitTypeIndex ~= nil and v248_.fruitTypeIndex ~= FruitType.UNKNOWN then
						workArea.fruitTypes[v248_.fruitTypeIndex] = workArea.fruitTypes[v248_.fruitTypeIndex] + 1
					end
					local v253_ = workArea.growthState
					local v254_ = v248_.growthState
					workArea.growthState = math.max(v253_, v254_)
					if v248_.soilTypeIndex ~= nil and v248_.soilTypeIndex ~= 0 then
						workArea.soilTypes[v248_.soilTypeIndex] = workArea.soilTypes[v248_.soilTypeIndex] + 1
					end
				end
				local v255_ = workArea.nitrogenLevel / workArea.numSubSections
				workArea.nitrogenLevel = math.ceil(v255_)
				local v256_ = workArea.nitrogenTargetLevel / workArea.numSubSections
				workArea.nitrogenTargetLevel = math.ceil(v256_)
				local v257_ = workArea.phLevel / workArea.numSubSections
				workArea.phLevel = math.ceil(v257_)
				local v258_ = workArea.phTargetLevel / workArea.numSubSections
				workArea.phTargetLevel = math.ceil(v258_)
			end
			local v259_ = 0
			local v260_ = 0
			for v261_, v262_ in ipairs(workArea.soilTypes) do
				if v259_ < v262_ then
					v260_ = v261_
					v259_ = v262_
				end
			end
			workArea.soilTypeIndex = v260_
			v_u_173_.lastTouchedSoilType = workArea.soilTypeIndex
			if self.spec_sowingMachine == nil then
				local v263_ = 0
				local v264_ = 0
				for v265_, v266_ in ipairs(workArea.fruitTypes) do
					if v263_ < v266_ then
						v264_ = v265_
						v263_ = v266_
					end
				end
				workArea.fruitTypeIndex = v264_
				if workArea.fruitTypeIndex == FruitType.UNKNOWN then
					local v267_ = v_u_173_.nApplyAutoModeFruitRequirementDefaultIndex
					local v268_, _ = v_u_173_.nitrogenMap:getNitrogenApplicationRate(workArea.nitrogenLevel, v267_, workArea.soilTypeIndex, v_u_174_)
					workArea.nitrogenTargetLevel = workArea.nitrogenLevel + (v268_ or 0)
					for v269_ = 1, workArea.numSubSections do
						local v270_ = workArea.subSectionData[v269_]
						if v270_.isValid then
							v270_.nitrogenTargetLevel = workArea.nitrogenTargetLevel
							v270_.fruitTypeIndex = workArea.fruitTypeIndex
						end
					end
				end
			else
				workArea.fruitTypeIndex = self.spec_sowingMachine.seeds[self.spec_sowingMachine.currentSeed]
			end
			if workArea.maxNApplicationOffset > 0 and workArea.nitrogenLevel < workArea.nitrogenTargetLevel then
				local v271_ = workArea.nitrogenLevelMax - workArea.nitrogenLevel
				if v271_ > 0 and v271_ <= workArea.maxNApplicationOffset + 0.01 then
					workArea.nitrogenLevel = workArea.nitrogenLevelMax
				end
			end
			if workArea.maxPHApplicationOffset > 0 and workArea.phLevel < workArea.phTargetLevel then
				local v272_ = workArea.phLevelMax - workArea.phLevel
				if v272_ > 0 and v272_ <= workArea.maxPHApplicationOffset + 0.01 then
					workArea.phLevel = workArea.phLevelMax
				end
			end
			for v273_ = 1, workArea.numSubSections do
				local v274_ = workArea.subSectionData[v273_]
				if not v274_.isValid then
					v274_.nitrogenLevel = workArea.nitrogenLevel
					v274_.nitrogenTargetLevel = workArea.nitrogenTargetLevel
					v274_.phLevel = workArea.phLevel
					v274_.phTargetLevel = workArea.phTargetLevel
					v274_.fruitTypeIndex = workArea.fruitTypeIndex
					v274_.soilTypeIndex = workArea.soilTypeIndex
				end
			end
			if v_u_173_.lastTouchedSoilTypeSent ~= v_u_173_.lastTouchedSoilType then
				self:raiseDirtyFlags(v_u_173_.usageValuesDirtyFlag)
				v_u_173_.lastTouchedSoilTypeSent = v_u_173_.lastTouchedSoilType
			end
			v_u_173_.phActualValue = workArea.phLevel
			v_u_173_.phTargetValue = v_u_173_.pHMap:getOptimalPHValueForSoilTypeIndex(workArea.soilTypeIndex) or workArea.phLevel
			if v_u_173_.phActualValue ~= v_u_173_.phActualValueSent or v_u_173_.phTargetValue ~= v_u_173_.phTargetValueSent then
				self:raiseDirtyFlags(v_u_173_.usageValuesDirtyFlag)
				v_u_173_.phActualValueSent = v_u_173_.phActualValue
				v_u_173_.phTargetValueSent = v_u_173_.phTargetValue
			end
			v_u_173_.nActualValue = workArea.nitrogenLevel
			local v275_ = FruitType.UNKNOWN
			if workArea.fruitTypeIndex ~= FruitType.UNKNOWN then
				local _, v276_ = v_u_173_.nitrogenMap:getNitrogenApplicationRate(workArea.nitrogenLevel, workArea.fruitTypeIndex, workArea.soilTypeIndex, self.spec_sprayer.workAreaParameters.sprayType)
				if v276_ then
					v275_ = workArea.fruitTypeIndex
				end
			end
			v_u_173_.nTargetValue = workArea.nitrogenTargetLevel
			if v_u_173_.nActualValue ~= v_u_173_.nActualValueSent or v_u_173_.nTargetValue ~= v_u_173_.nTargetValueSent then
				self:raiseDirtyFlags(v_u_173_.usageValuesDirtyFlag)
				v_u_173_.nActualValueSent = v_u_173_.nActualValue
				v_u_173_.nTargetValueSent = v_u_173_.nTargetValue
			end
			self:setSprayAmountAutoFruitTypeIndex(v275_)
			if v_u_173_.nApplyAutoModeFruitType ~= v_u_173_.nApplyAutoModeFruitTypeSent then
				self:raiseDirtyFlags(v_u_173_.usageValuesDirtyFlag)
				v_u_173_.nApplyAutoModeFruitTypeSent = v_u_173_.nApplyAutoModeFruitType
			end
		end
	end
end

-- Local values: spec, specSpray, sprayType, sprayVehicle, phDelta, nitrogenDelta, speedLimit, processSubSectionPos, worldStartX, _, worldStartZ, worldWidthX, _, worldWidthZ, worldHeightX, _, worldHeightZ, dirX, dirZ, width, subSectionWidth, i, subSectionData, sx, sz, wx, wz, hx, hz, cornerX, cornerZ, cornerDirX, cornerDirZ, cornerDistance, widthDirX, widthDirZ, width1, subSectionWidth1, subSectionWidth2, i, x1, z1, x2, z2, x3, z3, x4, z4, subSectionData, heightDirX, heightDirZ, width2, i, x1, z1, x2, z2, x3, z3, x4, z4, subSectionData
function ExtendedSprayer:processWorkAreaSubSectionData(workArea)
	if workArea.subSectionData ~= nil then
		local v_u_279_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
		local v280_ = self.spec_sprayer
		local v_u_281_ = v280_.workAreaParameters.sprayType
		local v_u_282_ = v280_.workAreaParameters.sprayVehicle
		if v_u_282_ == nil then
			v_u_282_ = ExtendedSprayer.getFillTypeSourceVehicle(self)
		end
		local v_u_283_
		if v_u_279_.isLiming then
			if v_u_279_.sprayAmountAutoMode then
				if workArea.soilTypeIndex == 0 then
					v_u_283_ = v_u_279_.pHMap:getDefaultLimeStateChange()
				else
					local v284_ = v_u_279_.phTargetValue - workArea.phLevel
					v_u_283_ = math.max(v284_, 0)
				end
			else
				v_u_283_ = v_u_279_.sprayAmountManual
			end
			if v_u_283_ == 0 and not v_u_279_.pwmEnabled then
				return
			end
		else
			v_u_283_ = 0
		end
		local v_u_285_
		if v_u_279_.isFertilizing then
			if v_u_279_.sprayAmountAutoMode then
				if workArea.soilTypeIndex == 0 then
					v_u_285_ = v_u_279_.nitrogenMap:getDefaultNitrogenStateChange()
				else
					local v286_ = v_u_279_.nTargetValue - workArea.nitrogenLevel
					v_u_285_ = math.max(v286_, 0)
				end
			else
				v_u_285_ = v_u_279_.sprayAmountManual
			end
			if v_u_285_ == 0 and not v_u_279_.pwmEnabled then
				return
			end
		else
			v_u_285_ = 0
		end
		local v_u_287_ = self:getRawSpeedLimit()
		local function v297_(p288_, p289_)
			-- upvalues: (copy) v_u_279_, (copy) v_u_281_, (ref) v_u_283_, (ref) v_u_282_, (ref) v_u_285_, (copy) v_u_287_
			if v_u_279_.isLiming then
				if v_u_279_.sprayAmountAutoMode then
					v_u_279_.pHMap:updatePHLevelAtArea(p289_, v_u_281_, p288_.phTargetLevel)
				else
					v_u_279_.pHMap:addPHLevelAtArea(p289_, v_u_281_, v_u_283_)
				end
			end
			if v_u_279_.isFertilizing then
				local v290_ = v_u_282_.getCurrentNitrogenLevelOffset == nil and 0 or v_u_282_:getCurrentNitrogenLevelOffset(p288_.nitrogenTargetLevel - p288_.nitrogenLevel)
				if v_u_279_.pwmEnabled then
					if v_u_279_.sprayAmountAutoMode then
						v_u_279_.nitrogenMap:updateNitrogenLevelAtArea(p289_, v_u_281_, p288_.nitrogenTargetLevel + v290_)
					else
						v_u_279_.nitrogenMap:addNitrogenLevelAtArea(p289_, v_u_281_, v_u_285_)
					end
				end
				local v291_
				if v_u_279_.pHMap.realisticSpreadOutputEnabled and not v_u_279_.speedDependentApplication then
					local v292_ = p288_.lastSpeed / v_u_287_
					local v293_ = 1 / math.max(v292_, 0.01)
					v291_ = math.min(v293_, 2)
				else
					v291_ = 1
				end
				local v294_ = not v_u_279_.pHMap.realisticSpreadPatternEnabled and 0 or p288_.nApplicationOffset
				local v295_ = MathUtil.round(v_u_285_ * v291_) + v290_ + v294_
				local v296_ = math.max(v295_, 1)
				v_u_279_.nitrogenMap:addNitrogenLevelAtArea(p289_, v_u_281_, v296_)
			end
		end
		local v298_, _, v299_ = getWorldTranslation(workArea.start)
		local v300_, _, v301_ = getWorldTranslation(workArea.width)
		local v302_, _, v303_ = getWorldTranslation(workArea.height)
		if workArea.numMainDivisions == 1 then
			local v304_ = v300_ - v298_
			local v305_ = v301_ - v299_
			local v306_ = MathUtil.vector2Length(v304_, v305_)
			local v307_ = v304_ / v306_
			local v308_ = v305_ / v306_
			local v309_ = v306_ / workArea.numSubDivisions
			for v310_ = 1, workArea.numSubDivisions do
				local v311_ = workArea.subSectionData[v310_]
				local v312_ = v298_ + v307_ * (v310_ - 1) * v309_
				local v313_ = v299_ + v308_ * (v310_ - 1) * v309_
				local v314_ = v298_ + v307_ * v310_ * v309_
				local v315_ = v299_ + v308_ * v310_ * v309_
				local v316_ = v302_ + v307_ * (v310_ - 1) * v309_
				local v317_ = v303_ + v308_ * (v310_ - 1) * v309_
				v_u_279_.densityMapParallelogram:updateFromWorldPositions(v312_, v313_, v314_, v315_, v316_, v317_)
				v297_(v311_, v_u_279_.densityMapParallelogram)
			end
		else
			local v318_ = v298_ + (v300_ - v298_) + (v302_ - v298_)
			local v319_ = v299_ + (v301_ - v299_) + (v303_ - v299_)
			local v320_ = v300_ - v318_
			local v321_ = v301_ - v319_
			local v322_ = MathUtil.vector2Length(v320_, v321_)
			local v323_ = v320_ / v322_
			local v324_ = v321_ / v322_
			local v325_ = v300_ - v298_
			local v326_ = v301_ - v299_
			local v327_ = MathUtil.vector2Length(v325_, v326_)
			local v328_ = v325_ / v327_
			local v329_ = v326_ / v327_
			local v330_ = v327_ / workArea.numSubDivisions
			local v331_ = v322_ / workArea.numSubDivisions
			for v332_ = 1, workArea.numSubDivisions do
				local v333_ = v298_ + v328_ * v332_ * v330_
				local v334_ = v299_ + v329_ * v332_ * v330_
				local v335_ = v298_ + v328_ * (v332_ - 1) * v330_
				local v336_ = v299_ + v329_ * (v332_ - 1) * v330_
				local v337_ = v318_ + v323_ * (v332_ - 1) * v331_
				local v338_ = v319_ + v324_ * (v332_ - 1) * v331_
				local v339_ = v318_ + v323_ * v332_ * v331_
				local v340_ = v319_ + v324_ * v332_ * v331_
				v_u_279_.densityMapPolygon:setPolygonPoint(1, v333_, v334_)
				v_u_279_.densityMapPolygon:setPolygonPoint(2, v335_, v336_)
				v_u_279_.densityMapPolygon:setPolygonPoint(3, v337_, v338_)
				v_u_279_.densityMapPolygon:setPolygonPoint(4, v339_, v340_)
				v297_(workArea.subSectionData[v332_], v_u_279_.densityMapPolygon)
			end
			local v341_ = v302_ - v298_
			local v342_ = v303_ - v299_
			local v343_ = MathUtil.vector2Length(v341_, v342_)
			local v344_ = v341_ / v343_
			local v345_ = v342_ / v343_
			local v346_ = v302_ - v318_
			local v347_ = v303_ - v319_
			local v348_ = MathUtil.vector2Length(v346_, v347_)
			local v349_ = v346_ / v348_
			local v350_ = v347_ / v348_
			local v351_ = v343_ / workArea.numSubDivisions
			local v352_ = v348_ / workArea.numSubDivisions
			for v353_ = 1, workArea.numSubDivisions do
				local v354_ = v298_ + v344_ * v353_ * v351_
				local v355_ = v299_ + v345_ * v353_ * v351_
				local v356_ = v298_ + v344_ * (v353_ - 1) * v351_
				local v357_ = v299_ + v345_ * (v353_ - 1) * v351_
				local v358_ = v318_ + v349_ * (v353_ - 1) * v352_
				local v359_ = v319_ + v350_ * (v353_ - 1) * v352_
				local v360_ = v318_ + v349_ * v353_ * v352_
				local v361_ = v319_ + v350_ * v353_ * v352_
				v_u_279_.densityMapPolygon:setPolygonPoint(1, v354_, v355_)
				v_u_279_.densityMapPolygon:setPolygonPoint(2, v356_, v357_)
				v_u_279_.densityMapPolygon:setPolygonPoint(3, v358_, v359_)
				v_u_279_.densityMapPolygon:setPolygonPoint(4, v360_, v361_)
				v297_(workArea.subSectionData[v353_ + workArea.numSubDivisions], v_u_279_.densityMapPolygon)
			end
		end
	end
end

-- Local values: usage, specSpray, usageScale, activeSprayType, workWidth, lastSpeed, spec, dataUncovered, _, workArea, minRate, changeValue, accumulatedChange, numSections, _, workArea, _, subSectionData, _, alpha, litersPerUpdate, literPerHectar, regularUsage, sprayVehicle, changeValue, accumulatedChange, numSections, _, workArea, _, subSectionData, _, workArea, _, subSectionData, _, alpha, nitrogenUsageLevelOffset, litersPerUpdate, literPerHectar, regularUsage, nitrogenProportion
function ExtendedSprayer:getSprayerUsage(superFunc, fillType, dt)
	local v366_ = superFunc(self, fillType, dt)
	if self:getIsTurnedOn() then
		local v367_ = self.spec_sprayer
		local v368_ = v367_.usageScale
		local v369_ = self:getActiveSprayType()
		if v369_ ~= nil then
			v368_ = v369_.usageScale
		end
		local v370_
		if v368_.workAreaIndex == nil then
			v370_ = v368_.workingWidth
		else
			v370_ = self:getWorkAreaWidth(v368_.workAreaIndex)
		end
		local v371_ = self:getLastSpeed()
		local v372_ = math.max(v371_, 1)
		local v373_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
		local v374_ = false
		for _, v375_ in pairs(v373_.workAreas) do
			if v375_.isPrecisionFarmingDataUncovered then
				v374_ = true
				break
			end
		end
		local v376_ = v373_.sprayAmountAutoMode and 0 or 1
		if v373_.isLiming then
			if v373_.pHMap ~= nil then
				local v377_
				if v373_.sprayAmountAutoMode then
					if v373_.pwmEnabled then
						local v378_ = 0
						local v379_ = 0
						for _, v380_ in pairs(v373_.workAreas) do
							if v380_.numSubSections > 0 then
								for _, v381_ in ipairs(v380_.subSectionData) do
									local v382_ = v381_.phTargetLevel - v381_.phLevel
									v378_ = v378_ + math.max(v382_, 0)
									v379_ = v379_ + 1
								end
							end
						end
						if v379_ > 0 then
							v377_ = v378_ / v379_
						else
							v377_ = 0
						end
					else
						local v383_ = v373_.phTargetValue - v373_.phActualValue
						v377_ = math.ceil(v383_)
						if v373_.pHMap.realisticSpreadOutputEnabled and not v373_.speedDependentApplication then
							v372_ = self:getRawSpeedLimit()
						end
					end
					if not v374_ then
						v377_ = v373_.pHMap:getDefaultLimeStateChange()
					end
				else
					local v384_ = v373_.sprayAmountManual
					v377_ = math.max(v384_, 1)
					if v373_.pHMap.realisticSpreadOutputEnabled and not v373_.speedDependentApplication then
						v372_ = self:getRawSpeedLimit()
					end
				end
				if self.getNumExtendedSprayerNozzleEffectsActive ~= nil then
					local _, v385_ = self:getNumExtendedSprayerNozzleEffectsActive()
					v377_ = v377_ * v385_
				end
				local v386_, v387_
				v366_, v386_, v387_ = v373_.pHMap:getLimeUsage(v370_, v372_, v377_, dt)
				v373_.lastRegularUsage = v387_
				v373_.lastLitersPerHectar = v386_
				v373_.lastNitrogenProportion = 0
			end
		elseif v373_.isFertilizing and v373_.nitrogenMap ~= nil then
			if v373_.isDoingMissionWork then
				v373_.lastRegularUsage = v366_
				v373_.lastLitersPerHectar = v366_ / dt * (10000 / v370_) / (self.speedLimit / 3600)
				v373_.lastNitrogenProportion = 0
			else
				local v388_ = v367_.workAreaParameters.sprayVehicle
				if v388_ == nil then
					v388_ = ExtendedSprayer.getFillTypeSourceVehicle(self)
				end
				local v389_
				if v373_.sprayAmountAutoMode then
					if v373_.pwmEnabled then
						local v390_ = 0
						local v391_ = 0
						for _, v392_ in pairs(v373_.sprayerWorkAreas) do
							if v392_.numSubSections > 0 then
								for _, v393_ in ipairs(v392_.subSectionData) do
									local v394_ = v393_.nitrogenTargetLevel - v393_.nitrogenLevel
									v390_ = v390_ + math.max(v394_, 0)
									v391_ = v391_ + 1
								end
							end
						end
						for _, v395_ in pairs(v373_.sowingMachineWorkAreas) do
							if v395_.numSubSections > 0 then
								for _, v396_ in ipairs(v395_.subSectionData) do
									local v397_ = v396_.nitrogenTargetLevel - v396_.nitrogenLevel
									v390_ = v390_ + math.max(v397_, 0)
									v391_ = v391_ + 1
								end
							end
						end
						if v391_ > 0 then
							v389_ = v390_ / v391_
						else
							v389_ = 0
						end
					else
						local v398_ = v373_.nTargetValue - v373_.nActualValue
						v389_ = math.ceil(v398_)
						if v373_.pHMap.realisticSpreadOutputEnabled and not v373_.speedDependentApplication then
							v372_ = self:getRawSpeedLimit()
						end
					end
					if not v374_ then
						v389_ = v373_.nitrogenMap:getDefaultNitrogenStateChange()
					end
				else
					local v399_ = v373_.sprayAmountManual
					v389_ = math.max(v399_, 1)
					if v373_.pHMap.realisticSpreadOutputEnabled and not v373_.speedDependentApplication then
						v372_ = self:getRawSpeedLimit()
					end
				end
				if self.getNumExtendedSprayerNozzleEffectsActive ~= nil then
					local _, v400_ = self:getNumExtendedSprayerNozzleEffectsActive()
					v389_ = v389_ * v400_
				end
				local v401_ = (v388_ == nil or v388_.getCurrentNitrogenUsageLevelOffset == nil) and 0 or (v388_:getCurrentNitrogenUsageLevelOffset(v389_) or 0)
				local v402_, v403_, v404_
				v366_, v402_, v403_, v404_ = v373_.nitrogenMap:getFertilizerUsage(v370_, v372_, math.max(v389_, v376_), fillType, dt, v373_.sprayAmountAutoMode, v373_.nApplyAutoModeFruitType, v373_.nActualValue, v401_)
				v373_.lastRegularUsage = v403_
				v373_.lastLitersPerHectar = v402_
				v373_.lastNitrogenProportion = v404_
			end
		end
		v366_ = self:getIsAIActive() and v366_ == 0 and 0.0001 or v366_
	end
	return v366_
end

-- Local values: specSpray, spec, sx, _, sz, wx, _, wz, hx, _, hz, changedArea, totalArea, desc, changedArea, totalArea, desc
function ExtendedSprayer:processSprayerArea(superFunc, workArea, dt)
	local v409_ = self.spec_sprayer
	local v410_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
	if v409_.workAreaParameters.sprayFillLevel <= 0 then
		return superFunc(self, workArea, dt)
	end
	if not (v410_.isLiming or v410_.isFertilizing) then
		return superFunc(self, workArea, dt)
	end
	local v411_, _, v412_ = getWorldTranslation(workArea.start)
	local v413_, _, v414_ = getWorldTranslation(workArea.width)
	local v415_, _, v416_ = getWorldTranslation(workArea.height)
	if not self.isServer then
		local v417_, v418_
		if self:getIsPrecisionSprayingRequired() then
			v417_, v418_ = superFunc(self, workArea, dt)
			if v417_ > 0 then
				v410_.nitrogenMap:setMinimapRequiresUpdate(true)
			end
		else
			v417_ = 0
			v418_ = 0
		end
		local v419_ = g_sprayTypeManager:getSprayTypeByIndex(v409_.workAreaParameters.sprayType)
		if v419_ ~= nil then
			FSDensityMapUtil.setGroundTypeLayerArea(v411_, v412_, v413_, v414_, v415_, v416_, v419_.sprayGroundType)
		end
		return v417_, v418_
	end
	if v409_.workAreaParameters.sprayType ~= workArea.lastSprayTypeIndex then
		workArea.lastSprayTypeIndex = v409_.workAreaParameters.sprayType
		self:updateWorkAreaSubSectionData(workArea)
	end
	v410_.densityMapParallelogram:updateFromWorldPositions(v411_, v412_, v413_, v414_, v415_, v416_)
	if v410_.isLiming then
		v410_.pHMap:preUpdatePHLevelAtArea(v410_.densityMapParallelogram, v409_.workAreaParameters.sprayType)
	end
	if v410_.isFertilizing then
		v410_.nitrogenMap:preUpdateNitrogenLevelAtArea(v410_.densityMapParallelogram, v409_.workAreaParameters.sprayType)
	end
	self:processWorkAreaSubSectionData(workArea)
	local v420_, v421_
	if self:getIsPrecisionSprayingRequired() then
		v420_, v421_ = superFunc(self, workArea, dt)
		if v420_ > 0 then
			v410_.nitrogenMap:setMinimapRequiresUpdate(true)
		end
	else
		v420_ = 0
		v421_ = 0
	end
	local v422_ = g_sprayTypeManager:getSprayTypeByIndex(v409_.workAreaParameters.sprayType)
	if v422_ ~= nil then
		FSDensityMapUtil.setGroundTypeLayerArea(v411_, v412_, v413_, v414_, v415_, v416_, v422_.sprayGroundType)
	end
	return v420_, v421_
end
function ExtendedSprayer.changeSeedIndex(p423_, p424_, ...)
	p424_(p423_, ...)
	p423_[ExtendedSprayer.SPEC_TABLE_NAME].lastGroundUpdateDistance = math.huge
end

function ExtendedSprayer:getSprayerDoubledAmountActive(superFunc, sprayTypeIndex)
	return false, false
end

function ExtendedSprayer:updateSprayerEffects(superFunc, force) end

-- Local values: isActive, amountScale, spec, x, y, z, densityBitsGround, groundTypeValue, groundType
function ExtendedSprayer:updateExtendedSprayerNozzleEffectState(superFunc, effectData, dt, isTurnedOn, lastSpeed)
	local v431_, v432_ = superFunc(self, effectData, dt, isTurnedOn, lastSpeed)
	if v431_ then
		local v433_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
		if (v433_.pwmEnabled or v433_.spotSprayEnabled) and (v433_.isLiming or v433_.isFertilizing) then
			local v434_, v435_, v436_ = localToWorld(effectData.effectNode, 0, 0, 1)
			local v437_ = getDensityAtWorldPos(v433_.groundTypeMapId, v434_, v435_, v436_)
			local v438_ = v433_.groundTypeFirstChannel
			local v439_ = bit32.rshift(v437_, v438_)
			local v440_ = 2 ^ v433_.groundTypeNumChannels - 1
			local v441_ = bit32.band(v439_, v440_)
			if FieldGroundType.getTypeByValue(v441_) == FieldGroundType.NONE then
				v431_ = false
			end
		end
	end
	return v431_, v432_
end

-- Local values: sprayTypeDesc, mission, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, mission, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, _, fruitType
function ExtendedSprayer:setSprayerAITerrainDetailProhibitedRange(superFunc, fillType)
	superFunc(self, fillType)
	if self:getUseSprayerAIRequirements() and self.addAITerrainDetailProhibitedRange ~= nil then
		self:clearAIFruitProhibitions()
		local v445_ = g_sprayTypeManager:getSprayTypeByFillTypeIndex(fillType)
		if v445_ ~= nil then
			if v445_.isFertilizer then
				local v446_, v447_, v448_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
				self:addAIFruitProhibitions(0, v445_.sprayGroundType, v445_.sprayGroundType, v446_, v447_, v448_)
			elseif v445_.isLime then
				local v449_, v450_, v451_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
				self:addAIFruitProhibitions(0, v445_.sprayGroundType, v445_.sprayGroundType, v449_, v450_, v451_)
			end
			if v445_.isHerbicide or (v445_.isFertilizer or v445_.isLime) then
				for _, v452_ in pairs(g_fruitTypeManager:getFruitTypes()) do
					if v452_.terrainDataPlaneId ~= nil and (string.lower(v452_.name) ~= "grass" and (v452_.minHarvestingGrowthState ~= nil and v452_.maxHarvestingGrowthState ~= nil)) then
						self:addAIFruitProhibitions(v452_.index, v452_.minHarvestingGrowthState, v452_.maxHarvestingGrowthState)
					end
				end
			end
		end
	end
end

-- Local values: spec, sx, _, sz, wx, _, wz, hx, _, hz, sprayTypeIndex
function ExtendedSprayer:preProcessExtUnderRootFertilizerArea(workArea, dt)
	local v455_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
	if self.isServer then
		local v456_, _, v457_ = getWorldTranslation(workArea.start)
		local v458_, _, v459_ = getWorldTranslation(workArea.width)
		local v460_, _, v461_ = getWorldTranslation(workArea.height)
		if v455_.nitrogenMap ~= nil then
			v455_.densityMapParallelogram:updateFromWorldPositions(v456_, v457_, v458_, v459_, v460_, v461_)
			local v462_ = SprayType.FERTILIZER
			v455_.nitrogenMap:preUpdateNitrogenLevelAtArea(v455_.densityMapParallelogram, v462_)
			self:processWorkAreaSubSectionData(workArea)
		end
	end
end

-- Local values: spec, specSprayer, sprayVehicle, usage, fillType, usageRegular
function ExtendedSprayer:onEndWorkAreaProcessing(dt, hasProcessed)
	local v464_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
	local v465_ = self.spec_sprayer
	if self.isServer and v465_.workAreaParameters.isActive then
		local v466_ = v465_.workAreaParameters.sprayVehicle
		local v467_ = v465_.workAreaParameters.usage
		local v468_ = v465_.workAreaParameters.sprayFillType
		if (v466_ ~= nil or self:getIsAIActive()) and self:getIsTurnedOn() then
			local v469_ = v464_.lastRegularUsage
			if v468_ == FillType.LIME then
				self:updatePFStatistic("usedLime", v467_)
				self:updatePFStatistic("usedLimeRegular", v469_)
				return
			end
			if v468_ == FillType.FERTILIZER then
				self:updatePFStatistic("usedMineralFertilizer", v467_)
				self:updatePFStatistic("usedMineralFertilizerRegular", v469_)
				return
			end
			if v468_ == FillType.LIQUIDFERTILIZER then
				self:updatePFStatistic("usedLiquidFertilizer", v467_)
				self:updatePFStatistic("usedLiquidFertilizerRegular", v469_)
				return
			end
			if v468_ == FillType.MANURE then
				self:updatePFStatistic("usedManure", v467_)
				self:updatePFStatistic("usedManureRegular", v469_)
				return
			end
			if v468_ == FillType.LIQUIDMANURE or v468_ == FillType.DIGESTATE then
				self:updatePFStatistic("usedLiquidManure", v467_)
				self:updatePFStatistic("usedLiquidManureRegular", v469_)
			end
		end
	end
end

-- Local values: spec
function ExtendedSprayer:setSprayAmountAutoMode(state, noEventSend)
	local v473_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
	if state == nil then
		state = not v473_.sprayAmountAutoMode
	end
	if not v473_.sprayAmountAutoModeChangeAllowed then
		state = false
	end
	v473_.sprayAmountAutoMode = state
	ExtendedSprayer.updateActionEventState(self)
	ExtendedSprayer.updateActionEventAutoModeDefault(self)
	ExtendedSprayerAmountEvent.sendEvent(self, v473_.sprayAmountAutoMode, v473_.sprayAmountManual, noEventSend)
end

-- Local values: spec
function ExtendedSprayer:setSprayAmountManualValue(value, noEventSend)
	local v477_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
	local v478_ = v477_.sprayAmountManualMin
	local v479_ = v477_.sprayAmountManualMax
	v477_.sprayAmountManual = math.clamp(value, v478_, v479_)
	ExtendedSprayer.updateActionEventState(self)
	ExtendedSprayerAmountEvent.sendEvent(self, v477_.sprayAmountAutoMode, v477_.sprayAmountManual, noEventSend)
end

-- Local values: spec
function ExtendedSprayer:setSprayAmountAutoFruitTypeIndex(index)
	local v482_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
	if index ~= v482_.nApplyAutoModeFruitType then
		v482_.nApplyAutoModeFruitType = index
		v482_.nApplyAutoModeFruitTypeRequiresDefaultMode = v482_.nitrogenMap:getFruitTypeRequirementRequiresDefaultMode(index)
		ExtendedSprayer.updateActionEventAutoModeDefault(self)
	end
end

-- Local values: spec
function ExtendedSprayer:setSprayAmountDefaultFruitRequirementIndex(index, noEventSend)
	local v486_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
	v486_.nApplyAutoModeFruitRequirementDefaultIndex = index
	v486_.lastGroundUpdateDistance = math.huge
	ExtendedSprayerDefaultFruitTypeEvent.sendEvent(self, index, noEventSend)
end

-- Local values: spec, addWorkArea, i, workArea, isAllowed, sprayType, i, workArea, i, workArea
function ExtendedSprayer:updateDebugValues(values)
	local v_u_489_ = self[ExtendedSprayer.SPEC_TABLE_NAME]
	local function v512_(p490_, p491_)
		-- upvalues: (copy) v_u_489_, (copy) values
		if p490_.subSectionData ~= nil then
			local v492_ = v_u_489_.nitrogenMap:getNitrogenValueFromInternalValue(p490_.nitrogenLevel)
			local v493_ = v_u_489_.nitrogenMap:getNitrogenValueFromInternalValue(p490_.nitrogenTargetLevel)
			local v494_ = v_u_489_.pHMap:getPhValueFromInternalValue(p490_.phLevel)
			local v495_ = v_u_489_.pHMap:getPhValueFromInternalValue(p490_.phTargetLevel)
			local v496_ = g_fruitTypeManager:getFruitTypeNameByIndex(p490_.fruitTypeIndex)
			local v497_ = v_u_489_.soilMap:getSoilTypeByIndex(p490_.soilTypeIndex)
			local v498_ = v497_ == nil and "Unknown" or v497_.name
			local v499_ = values
			local v500_ = {
				["name"] = string.format("Detected (%s)", p491_),
				["value"] = string.format("N %dkg pH %.3f FruitType: %s|%d Soil: %s (Target: N: %dkg | pH %.3f)", v492_, v494_, v496_, p490_.growthState, v498_, v493_, v495_)
			}
			table.insert(v499_, v500_)
			for v501_, v502_ in ipairs(p490_.subSectionData) do
				local v503_ = g_fruitTypeManager:getFruitTypeNameByIndex(v502_.fruitTypeIndex)
				local v504_ = v_u_489_.nitrogenMap:getNitrogenValueFromInternalValue(v502_.nitrogenLevel)
				local v505_ = v_u_489_.nitrogenMap:getNitrogenValueFromInternalValue(v502_.nitrogenTargetLevel)
				local v506_ = v_u_489_.pHMap:getPhValueFromInternalValue(v502_.phLevel)
				local v507_ = v_u_489_.pHMap:getPhValueFromInternalValue(v502_.phTargetLevel)
				local v508_ = v_u_489_.soilMap:getSoilTypeByIndex(v502_.soilTypeIndex)
				local v509_ = v508_ == nil and "Unknown" or v508_.name
				local v510_ = values
				local v511_ = {
					["name"] = string.format("Sub Section %d", v501_),
					["value"] = string.format("%dkg/%dkg pH %.3f/%.3f FruitType: %s|%d Soil: %s Speed: %.2fkm/h (%s)", v504_, v505_, v506_, v507_, v503_, v502_.growthState, v509_, v502_.lastSpeed, v502_.isValid and "Valid" or "Invalid")
				}
				table.insert(v510_, v511_)
			end
		end
	end
	for v513_, v514_ in pairs(v_u_489_.sprayerWorkAreas) do
		local v515_ = true
		if v514_.sprayType ~= nil then
			local v516_ = self:getActiveSprayType()
			if v516_ ~= nil and v516_.index ~= v514_.sprayType then
				v515_ = false
			end
		end
		if v515_ then
			v512_(v514_, "SPRAYER" .. tostring(v513_))
		end
	end
	for v517_, v518_ in pairs(v_u_489_.sowingMachineWorkAreas) do
		v512_(v518_, "SOWINGMACHINE" .. tostring(v517_))
	end
	for v519_, v520_ in pairs(v_u_489_.cultivatorWorkAreas) do
		v512_(v520_, "CULTIVATOR" .. tostring(v519_))
	end
end
