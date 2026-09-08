SaltSpreader = {}
function SaltSpreader.initSpecialization()
	g_workAreaTypeManager:addWorkAreaType("saltSpreader", false, false, false)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("SaltSpreader")
	v1_:register(XMLValueType.INT, "vehicle.saltSpreader#fillUnitIndex", "Fill unit index", 1)
	v1_:register(XMLValueType.INT, "vehicle.saltSpreader#unloadInfoIndex", "Unload info index", 1)
	v1_:register(XMLValueType.INT, "vehicle.saltSpreader#usageWorkArea", "Width of this work area is used as multiplier for usage")
	v1_:register(XMLValueType.FLOAT, "vehicle.saltSpreader#usage", "Salt usage in liter per second", 1)
	EffectManager.registerEffectXMLPaths(v1_, "vehicle.saltSpreader.effects")
	v1_:setXMLSpecializationType()
end

function SaltSpreader.prerequisitesPresent(specializations)
	local v3_ = SpecializationUtil.hasSpecialization(WorkArea, specializations)
	if v3_ then
		v3_ = SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
	end
	return v3_
end

function SaltSpreader.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "processSaltSpreaderArea", SaltSpreader.processSaltSpreaderArea)
end

function SaltSpreader.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", SaltSpreader.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", SaltSpreader.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", SaltSpreader.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreControlledActionsAllowed", SaltSpreader.getAreControlledActionsAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", SaltSpreader.getCanBeTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTurnedOnNotAllowedWarning", SaltSpreader.getTurnedOnNotAllowedWarning)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getVariableWorkWidthUsage", SaltSpreader.getVariableWorkWidthUsage)
end

function SaltSpreader.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", SaltSpreader)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", SaltSpreader)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", SaltSpreader)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", SaltSpreader)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", SaltSpreader)
end

-- Local values: spec
function SaltSpreader:onLoad(savegame)
	local v8_ = self.spec_saltSpreader
	v8_.fillUnitIndex = self.xmlFile:getValue("vehicle.saltSpreader#fillUnitIndex", 1)
	v8_.unloadInfoIndex = self.xmlFile:getValue("vehicle.saltSpreader#unloadInfoIndex", 1)
	v8_.usageWorkArea = self.xmlFile:getValue("vehicle.saltSpreader#usageWorkArea")
	v8_.usage = self.xmlFile:getValue("vehicle.saltSpreader#usage", 1) / 1000
	if self.isClient then
		v8_.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.saltSpreader.effects", self.components, self, self.i3dMappings)
	end
	v8_.fillToolWarning = g_i18n:getText("info_firstFillTheTool")
	v8_.snowSystem = g_currentMission.snowSystem
	if not self.isServer then
		SpecializationUtil.removeEventListener(self, "onUpdateTick", SaltSpreader)
	end
end

-- Local values: spec
function SaltSpreader:onDelete()
	local v10_ = self.spec_saltSpreader
	g_effectManager:deleteEffects(v10_.effects)
end

-- Local values: spec, fillLevel, usageMultiplier, usage, unloadInfo
function SaltSpreader:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self:getIsTurnedOn() then
		local v13_ = self.spec_saltSpreader
		if self:getFillUnitFillLevel(v13_.fillUnitIndex) > 0 then
			local v14_ = v13_.usageWorkArea == nil and 1 or self:getWorkAreaWidth(v13_.usageWorkArea)
			local v15_ = v13_.usage * dt * v14_
			local v16_ = self:getFillVolumeUnloadInfo(v13_.unloadInfoIndex)
			self:addFillUnitFillLevel(self:getOwnerFarmId(), v13_.fillUnitIndex, -v15_, self:getFillUnitFillType(v13_.fillUnitIndex), ToolType.UNDEFINED, v16_)
			return
		end
		self:setIsTurnedOn(false)
	end
end

-- Local values: spec, fillTypeIndex
function SaltSpreader:onTurnedOn()
	if self.isClient then
		local v18_ = self.spec_saltSpreader
		local v19_ = self:getFillUnitFillType(v18_.fillUnitIndex)
		if v19_ ~= FillType.UNKNOWN then
			g_effectManager:setEffectTypeInfo(v18_.effects, v19_)
			g_effectManager:startEffects(v18_.effects)
		end
	end
end

-- Local values: spec
function SaltSpreader:onTurnedOff()
	if self.isClient then
		local v21_ = self.spec_saltSpreader
		g_effectManager:stopEffects(v21_.effects)
	end
end

function SaltSpreader:doCheckSpeedLimit(superFunc)
	return superFunc(self) or self:getIsTurnedOn()
end

function SaltSpreader:getDirtMultiplier(superFunc)
	if self:getIsTurnedOn() then
		return superFunc(self) + self:getWorkDirtMultiplier()
	else
		return superFunc(self)
	end
end

function SaltSpreader:getWearMultiplier(superFunc)
	if self:getIsTurnedOn() then
		return superFunc(self) + self:getWorkWearMultiplier()
	else
		return superFunc(self)
	end
end

-- Local values: spec
function SaltSpreader:getAreControlledActionsAllowed(superFunc)
	local v30_ = self.spec_saltSpreader
	if self:getFillUnitFillLevel(v30_.fillUnitIndex) <= 0 then
		return false, v30_.fillToolWarning
	else
		return superFunc(self)
	end
end

-- Local values: spec
function SaltSpreader:getCanBeTurnedOn(superFunc)
	if self:getFillUnitFillLevel(self.spec_saltSpreader.fillUnitIndex) <= 0 then
		return false
	else
		return superFunc(self)
	end
end

-- Local values: spec
function SaltSpreader:getTurnedOnNotAllowedWarning(superFunc)
	local v35_ = self.spec_saltSpreader
	if self:getFillUnitFillLevel(v35_.fillUnitIndex) <= 0 then
		return v35_.fillToolWarning
	else
		return superFunc(self)
	end
end

-- Local values: usage, spec, usageMultiplier
function SaltSpreader:getVariableWorkWidthUsage(superFunc)
	local v38_ = superFunc(self)
	if v38_ ~= nil then
		return v38_
	end
	if not self:getIsTurnedOn() then
		return 0
	end
	local v39_ = self.spec_saltSpreader
	local v40_ = v39_.usageWorkArea == nil and 1 or self:getWorkAreaWidth(v39_.usageWorkArea)
	return v39_.usage * v40_ * 1000 * 60
end
function SaltSpreader.getDefaultSpeedLimit()
	return 20
end

-- Local values: xs, _, zs, xw, _, zw, xh, _, zh
function SaltSpreader:processSaltSpreaderArea(workArea)
	if not self.isServer then
		return 0, 0
	end
	local v43_, _, v44_ = getWorldTranslation(workArea.start)
	local v45_, _, v46_ = getWorldTranslation(workArea.width)
	local v47_, _, v48_ = getWorldTranslation(workArea.height)
	return self.spec_saltSpreader.snowSystem:saltArea(v43_, v44_, v45_, v46_, v47_, v48_)
end
