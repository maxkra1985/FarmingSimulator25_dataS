ExtendedSowingMachine = {}
ExtendedSowingMachine.MIN_SEED_RATE = 1
ExtendedSowingMachine.MAX_SEED_RATE = 3
ExtendedSowingMachine.DEFAULT_SEED_RATE = 2
ExtendedSowingMachine.SPEC_TABLE_NAME = "spec_" .. g_currentModName .. ".extendedSowingMachine"
source(g_currentModDirectory .. "scripts/hud/ExtendedSowingMachineHUDExtension.lua")

function ExtendedSowingMachine.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(SowingMachine, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(PrecisionFarmingStatistic, specializations)
	end
	return v2_
end

function ExtendedSowingMachine.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setSeedRateAutoMode", ExtendedSowingMachine.setSeedRateAutoMode)
	SpecializationUtil.registerFunction(vehicleType, "setManualSeedRate", ExtendedSowingMachine.setManualSeedRate)
	SpecializationUtil.registerFunction(vehicleType, "onTramlinesChanged", ExtendedSowingMachine.onTramlinesChanged)
end

function ExtendedSowingMachine.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "processSowingMachineArea", ExtendedSowingMachine.processSowingMachineArea)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "processOverSeedingArea", ExtendedSowingMachine.processOverSeedingArea)
end

function ExtendedSowingMachine.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ExtendedSowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", ExtendedSowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", ExtendedSowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", ExtendedSowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", ExtendedSowingMachine)
end

-- Local values: spec
function ExtendedSowingMachine:onLoad(savegame)
	local v7_ = self[ExtendedSowingMachine.SPEC_TABLE_NAME]
	v7_.seedRateAutoMode = true
	v7_.manualSeedRate = ExtendedSowingMachine.DEFAULT_SEED_RATE
	v7_.lastSeedRate = 0
	v7_.lastSeedRateIndex = 0
	v7_.lastRealChangedArea = 0
	v7_.lastGroundUpdateDistance = math.huge
	v7_.groundUpdateDistance = 4
	v7_.tramlineWidth = nil
	v7_.seedRateRecommendation = nil
	v7_.inputActionToggleAuto = InputAction.PRECISIONFARMING_SEED_RATE_MODE
	v7_.inputActionToggleRate = InputAction.PRECISIONFARMING_SEED_RATE
	v7_.texts = {}
	v7_.texts.inputToggleAutoModePos = g_i18n:getText("action_toggleSeedRateAutoModePos", self.customEnvironment)
	v7_.texts.inputToggleAutoModeNeg = g_i18n:getText("action_toggleSeedRateAutoModeNeg", self.customEnvironment)
	v7_.texts.inputChangeSeedRate = g_i18n:getText("action_changeManualSeedRate", self.customEnvironment)
	v7_.soilMap = g_precisionFarming.soilMap
	v7_.seedRateMap = g_precisionFarming.seedRateMap
	v7_.tramlineMap = g_precisionFarming.tramlineMap
	v7_.hudExtension = ExtendedSowingMachineHUDExtension.new(self)
	g_messageCenter:subscribe(MessageType.PRECISION_FARMING_TRAMLINES_CHANGED, self.onTramlinesChanged, self)
end

-- Local values: spec
function ExtendedSowingMachine:onDelete()
	local v9_ = self[ExtendedSowingMachine.SPEC_TABLE_NAME]
	if v9_.hudExtension ~= nil then
		v9_.hudExtension:delete()
	end
end

-- Local values: spec, workArea, x, z, lx, _, _, x1, _, z1, x2, _, z2, isOnField, _, soilTypeIndex, fruitTypeIndex, hud
function ExtendedSowingMachine:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v12_ = self[ExtendedSowingMachine.SPEC_TABLE_NAME]
	v12_.lastGroundUpdateDistance = v12_.lastGroundUpdateDistance + self.lastMovedDistance
	if v12_.lastGroundUpdateDistance > v12_.groundUpdateDistance then
		v12_.lastGroundUpdateDistance = 0
		local v13_ = self:getWorkAreaByIndex(1)
		if v13_ ~= nil then
			local v14_, _, _ = localToLocal(v13_.start, self.rootNode, 0, 0, 0)
			local v15_, v16_
			if math.abs(v14_) < 0.5 then
				local v17_
				v15_, v17_, v16_ = getWorldTranslation(v13_.start)
			else
				local v18_, _, v19_ = getWorldTranslation(v13_.start)
				local v20_, _, v21_ = getWorldTranslation(v13_.width)
				v15_ = (v18_ + v20_) * 0.5
				v16_ = (v19_ + v21_) * 0.5
			end
			local v22_, _ = FSDensityMapUtil.getFieldDataAtWorldPosition(v15_, 0, v16_)
			if v22_ then
				local v23_ = v12_.soilMap:getTypeIndexAtWorldPos(v15_, v16_)
				if v23_ > 0 then
					local v24_ = self.spec_sowingMachine.seeds[self.spec_sowingMachine.currentSeed]
					v12_.seedRateRecommendation = v12_.seedRateMap:getOptimalSeedRateByFruitTypeAndSoiltype(v24_, v23_)
				else
					v12_.seedRateRecommendation = nil
				end
				v12_.tramlineWidth = v12_.tramlineMap:getTramlineWidthAtWorldPos(v15_, v16_)
			else
				v12_.seedRateRecommendation = nil
				v12_.tramlineWidth = nil
			end
		end
	end
	if isActiveForInputIgnoreSelection and v12_.hudExtension ~= nil then
		g_currentMission.hud:addHelpExtension(v12_.hudExtension)
	end
end

-- Local values: spec, specSowingMachine, fruitDesc, realHa, lastHa, usage, usageRegular, damage
function ExtendedSowingMachine:onEndWorkAreaProcessing(dt, hasProcessed)
	local v26_ = self[ExtendedSowingMachine.SPEC_TABLE_NAME]
	local v27_ = self.spec_sowingMachine
	if self.isServer and v27_.workAreaParameters.lastChangedArea > 0 then
		local v28_ = g_fruitTypeManager:getFruitTypeByIndex(v27_.workAreaParameters.seedsFruitType)
		local v29_ = MathUtil.areaToHa(v26_.lastRealChangedArea, g_currentMission:getFruitPixelsToSqm())
		local v30_ = MathUtil.areaToHa(v27_.workAreaParameters.lastChangedArea, g_currentMission:getFruitPixelsToSqm())
		local v31_ = v28_.seedUsagePerSqm * v30_ * 10000 * v27_.seedUsageScale
		local v32_ = v28_.seedUsagePerSqm * v29_ * 10000 * v27_.seedUsageScale
		local v33_ = self:getVehicleDamage()
		if v33_ > 0 then
			v31_ = v31_ * (1 + v33_ * SowingMachine.DAMAGED_USAGE_INCREASE)
			v32_ = v32_ * (1 + v33_ * SowingMachine.DAMAGED_USAGE_INCREASE)
		end
		if self.updatePFStatistic ~= nil then
			self:updatePFStatistic("usedSeeds", v31_)
			self:updatePFStatistic("usedSeedsRegular", v32_)
		end
	end
end

-- Local values: spec, _, actionEventId
function ExtendedSowingMachine:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v36_ = self[ExtendedSowingMachine.SPEC_TABLE_NAME]
		self:clearActionEventsTable(v36_.actionEvents)
		if isActiveForInputIgnoreSelection then
			local _, v37_ = self:addActionEvent(v36_.actionEvents, v36_.inputActionToggleAuto, self, ExtendedSowingMachine.actionEventToggleAuto, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v37_, GS_PRIO_HIGH)
			local _, v38_ = self:addActionEvent(v36_.actionEvents, v36_.inputActionToggleRate, self, ExtendedSowingMachine.actionEventChangeSeedRate, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v38_, GS_PRIO_HIGH)
			g_inputBinding:setActionEventText(v38_, v36_.texts.inputChangeSeedRate)
			ExtendedSowingMachine.updateActionEventState(self)
		end
		v36_.attachStateChanged = true
	end
end

-- Local values: spec
function ExtendedSowingMachine:setSeedRateAutoMode(state, noEventSend)
	local v42_ = self[ExtendedSowingMachine.SPEC_TABLE_NAME]
	if state == nil then
		state = not v42_.seedRateAutoMode
	end
	if state ~= v42_.seedRateAutoMode then
		v42_.seedRateAutoMode = state
		if self.isClient then
			ExtendedSowingMachine.updateActionEventState(self)
		end
		ExtendedSowingMachineRateEvent.sendEvent(self, v42_.seedRateAutoMode, v42_.manualSeedRate, noEventSend)
	end
end

-- Local values: spec
function ExtendedSowingMachine:setManualSeedRate(seedRate, noEventSend)
	local v46_ = self[ExtendedSowingMachine.SPEC_TABLE_NAME]
	local v47_ = ExtendedSowingMachine.MIN_SEED_RATE
	local v48_ = ExtendedSowingMachine.MAX_SEED_RATE
	local v49_ = math.clamp(seedRate, v47_, v48_)
	if v49_ ~= v46_.manualSeedRate then
		v46_.manualSeedRate = v49_
		ExtendedSowingMachineRateEvent.sendEvent(self, v46_.seedRateAutoMode, v46_.manualSeedRate, noEventSend)
	end
end

-- Local values: spec
function ExtendedSowingMachine:onTramlinesChanged()
	self[ExtendedSowingMachine.SPEC_TABLE_NAME].lastGroundUpdateDistance = math.huge
end

-- Local values: changedArea, totalArea, spec, specSowingMachine, workAreaParameters, sx, _, sz, wx, _, wz, hx, _, hz, fruitType, realUsage, realSeedRate, realSeedRateIndex, fruitDesc, usageOffset
function ExtendedSowingMachine:processSowingMachineArea(superFunc, workArea, dt)
	local v55_, v56_ = superFunc(self, workArea, dt)
	if v55_ > 0 then
		local v57_ = self[ExtendedSowingMachine.SPEC_TABLE_NAME]
		local v58_ = self.spec_sowingMachine.workAreaParameters
		v57_.lastRealChangedArea = v58_.lastChangedArea
		local v59_, _, v60_ = getWorldTranslation(workArea.start)
		local v61_, _, v62_ = getWorldTranslation(workArea.width)
		local v63_, _, v64_ = getWorldTranslation(workArea.height)
		local v65_ = v58_.seedsFruitType
		local v66_, v67_, v68_ = v57_.seedRateMap:updateSeedArea(v59_, v60_, v61_, v62_, v63_, v64_, v65_, v57_.seedRateAutoMode, v57_.manualSeedRate)
		if v68_ ~= nil then
			local v69_ = v66_ / g_fruitTypeManager:getFruitTypeByIndex(v65_).seedUsagePerSqm
			v58_.lastChangedArea = v57_.lastRealChangedArea * v69_
			v57_.lastSeedRate = v67_
			v57_.lastSeedRateIndex = v68_
		end
	end
	return v55_, v56_
end

-- Local values: changedArea, totalArea, spec, specSowingMachine, workAreaParameters, sx, _, sz, wx, _, wz, hx, _, hz, fruitType, realUsage, realSeedRate, realSeedRateIndex, fruitDesc, usageOffset
function ExtendedSowingMachine:processOverSeedingArea(superFunc, workArea, dt)
	local v74_, v75_ = superFunc(self, workArea, dt)
	if v74_ > 0 then
		local v76_ = self[ExtendedSowingMachine.SPEC_TABLE_NAME]
		local v77_ = self.spec_sowingMachine.workAreaParameters
		v76_.lastRealChangedArea = v77_.lastChangedArea
		local v78_, _, v79_ = getWorldTranslation(workArea.start)
		local v80_, _, v81_ = getWorldTranslation(workArea.width)
		local v82_, _, v83_ = getWorldTranslation(workArea.height)
		local v84_ = v77_.seedsFruitType
		local v85_, v86_, v87_ = v76_.seedRateMap:updateSeedArea(v78_, v79_, v80_, v81_, v82_, v83_, v84_, v76_.seedRateAutoMode, v76_.manualSeedRate)
		if v87_ ~= nil then
			local v88_ = v85_ / g_fruitTypeManager:getFruitTypeByIndex(v84_).seedUsagePerSqm
			v77_.lastChangedArea = v76_.lastRealChangedArea * v88_
			v76_.lastSeedRate = v86_
			v76_.lastSeedRateIndex = v87_
		end
	end
	return v74_, v75_
end

function ExtendedSowingMachine:actionEventToggleAuto(actionName, inputValue, callbackState, isAnalog)
	self:setSeedRateAutoMode()
end
function ExtendedSowingMachine.actionEventChangeSeedRate(p90_, _, p91_, _, _, ...)
	p90_:setManualSeedRate(p90_[ExtendedSowingMachine.SPEC_TABLE_NAME].manualSeedRate + math.sign(p91_))
end

-- Local values: spec, actionEventToggleAuto, actionEventToggleRate
function ExtendedSowingMachine:updateActionEventState()
	local v93_ = self[ExtendedSowingMachine.SPEC_TABLE_NAME]
	local v94_ = v93_.actionEvents[v93_.inputActionToggleAuto]
	if v94_ ~= nil then
		g_inputBinding:setActionEventText(v94_.actionEventId, v93_.seedRateAutoMode and v93_.texts.inputToggleAutoModeNeg or v93_.texts.inputToggleAutoModePos)
	end
	local v95_ = v93_.actionEvents[v93_.inputActionToggleRate]
	if v95_ ~= nil then
		g_inputBinding:setActionEventActive(v95_.actionEventId, not v93_.seedRateAutoMode)
	end
end
