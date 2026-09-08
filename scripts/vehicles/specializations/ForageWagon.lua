ForageWagon = {}
function ForageWagon.initSpecialization()
	g_workAreaTypeManager:addWorkAreaType("forageWagon", false, false, true)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("ForageWagon")
	v1_:register(XMLValueType.INT, "vehicle.forageWagon#workAreaIndex", "Work area index", 1)
	v1_:register(XMLValueType.INT, "vehicle.forageWagon#fillUnitIndex", "Fill unit index", 1)
	v1_:register(XMLValueType.INT, "vehicle.forageWagon#loadInfoIndex", "Load info index", 1)
	v1_:register(XMLValueType.FLOAT, "vehicle.forageWagon#maxPickupLitersPerSecond", "Max. pickup liters per second", 500)
	v1_:register(XMLValueType.INT, "vehicle.forageWagon.additives#fillUnitIndex", "Additives fill unit index")
	v1_:register(XMLValueType.FLOAT, "vehicle.forageWagon.additives#usage", "Usage per picked up liter", 0.0000275)
	v1_:register(XMLValueType.STRING, "vehicle.forageWagon.additives#fillTypes", "Fill types to apply additives", "GRASS_WINDROW")
	v1_:register(XMLValueType.FLOAT, "vehicle.forageWagon.startFillEffect#fillStartDelay", "if defined the filling of the fill unit will be delayed until this time has passed", 0)
	v1_:register(XMLValueType.FLOAT, "vehicle.forageWagon.startFillEffect#fillStartFadeOff", "Fade out fill level for start fill effect (fillLevel 0: density 1 | fillLevel at fillStartFadeOff: density 0)", 0)
	v1_:register(XMLValueType.VECTOR_3, "vehicle.forageWagon.fillVolume#loadScrollSpeed", "Scroll speed while loading", "0 0 0")
	v1_:register(XMLValueType.VECTOR_3, "vehicle.forageWagon.fillVolume#dischargeScrollSpeed", "Scroll speed while unloading", "0 0 0")
	v1_:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#rotateOnlyIfFillLevelIncreased", "Rotate only if fill level increased", false)
	EffectManager.registerEffectXMLPaths(v1_, "vehicle.forageWagon.fillEffect")
	EffectManager.registerEffectXMLPaths(v1_, "vehicle.forageWagon.startFillEffect")
	v1_:setXMLSpecializationType()
end

function ForageWagon.prerequisitesPresent(specializations)
	local v3_ = SpecializationUtil.hasSpecialization(FillUnit, specializations) and (SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations) and SpecializationUtil.hasSpecialization(Pickup, specializations))
	if v3_ then
		v3_ = SpecializationUtil.hasSpecialization(WorkArea, specializations)
	end
	return v3_
end

function ForageWagon.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "processForageWagonArea", ForageWagon.processForageWagonArea)
	SpecializationUtil.registerFunction(vehicleType, "setFillEffectActive", ForageWagon.setFillEffectActive)
	SpecializationUtil.registerFunction(vehicleType, "fillForageWagon", ForageWagon.fillForageWagon)
end

function ForageWagon.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSpeedRotatingPartFromXML", ForageWagon.loadSpeedRotatingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", ForageWagon.getIsWorkAreaActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", ForageWagon.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConsumingLoad", ForageWagon.getConsumingLoad)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSpeedRotatingPartActive", ForageWagon.getIsSpeedRotatingPartActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillVolumeUVScrollSpeed", ForageWagon.getFillVolumeUVScrollSpeed)
end

function ForageWagon.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ForageWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", ForageWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", ForageWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", ForageWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", ForageWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", ForageWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", ForageWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", ForageWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", ForageWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", ForageWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", ForageWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", ForageWagon)
end

-- Local values: spec, additivesFillTypeNames
function ForageWagon:onLoad(savegame)
	local v8_ = self.spec_forageWagon
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.forageWagon#turnedOnTipScrollerSpeedFactor")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnRotationNodes.turnedOnRotationNode#type", "vehicle.turnOnVehicle.rotationNodes.rotationNode", "forageWagon")
	v8_.isFilling = false
	v8_.isFillingSent = false
	v8_.lastFillType = FillType.UNKNOWN
	v8_.lastFillTypeSent = FillType.UNKNOWN
	v8_.fillTimer = 0
	v8_.workAreaIndex = self.xmlFile:getValue("vehicle.forageWagon#workAreaIndex", 1)
	v8_.fillUnitIndex = self.xmlFile:getValue("vehicle.forageWagon#fillUnitIndex", 1)
	v8_.loadInfoIndex = self.xmlFile:getValue("vehicle.forageWagon#loadInfoIndex", 1)
	v8_.additives = {}
	v8_.additives.fillUnitIndex = self.xmlFile:getValue("vehicle.forageWagon.additives#fillUnitIndex")
	v8_.additives.available = self:getFillUnitByIndex(v8_.additives.fillUnitIndex) ~= nil
	v8_.additives.usage = self.xmlFile:getValue("vehicle.forageWagon.additives#usage", 0.0000275)
	local v9_ = self.xmlFile:getValue("vehicle.forageWagon.additives#fillTypes", "GRASS_WINDROW")
	v8_.additives.fillTypes = g_fillTypeManager:getFillTypesByNames(v9_, "Warning: \'" .. self.xmlFile:getFilename() .. "\' has invalid fillType \'%s\'.")
	v8_.loadUVScrollSpeed = self.xmlFile:getValue("vehicle.forageWagon.fillVolume#loadScrollSpeed", "0 0 0", true)
	v8_.dischargeUVScrollSpeed = self.xmlFile:getValue("vehicle.forageWagon.fillVolume#dischargeScrollSpeed", "0 0 0", true)
	v8_.maxPickupLitersPerSecond = self.xmlFile:getValue("vehicle.forageWagon#maxPickupLitersPerSecond", 500)
	if self.isClient then
		v8_.fillEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.forageWagon.fillEffect", self.components, self, self.i3dMappings)
		v8_.startFillEffect = g_effectManager:loadEffect(self.xmlFile, "vehicle.forageWagon.startFillEffect", self.components, self, self.i3dMappings)
	end
	v8_.fillStartEffectDelay = self.xmlFile:getValue("vehicle.forageWagon.startFillEffect#fillStartDelay", 0) * 0.001
	v8_.fillStartEffectTimer = 0
	v8_.fillStartEffectFadeOff = self.xmlFile:getValue("vehicle.forageWagon.startFillEffect#fillStartFadeOff", 0)
	v8_.workAreaParameters = {}
	v8_.workAreaParameters.forcedFillType = FillType.UNKNOWN
	v8_.workAreaParameters.lastPickupLiters = 0
	v8_.workAreaParameters.litersToFill = 0
	v8_.pickUpLitersBuffer = ValueBuffer.new(750)
	if v8_.startFillEffect == nil or #v8_.startFillEffect == 0 then
		SpecializationUtil.removeEventListener(self, "onFillUnitFillLevelChanged", ForageWagon)
	end
	v8_.dirtyFlag = self:getNextDirtyFlag()
end

-- Local values: spec
function ForageWagon:onDelete()
	local v11_ = self.spec_forageWagon
	g_effectManager:deleteEffects(v11_.fillEffects)
	g_effectManager:deleteEffects(v11_.startFillEffect)
end

-- Local values: spec
function ForageWagon:onReadStream(streamId, connection)
	local v14_ = self.spec_forageWagon
	v14_.isFilling = streamReadBool(streamId)
	v14_.lastFillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
	self:setFillEffectActive(v14_.isFilling)
end

-- Local values: spec
function ForageWagon:onWriteStream(streamId, connection)
	local v17_ = self.spec_forageWagon
	streamWriteBool(streamId, v17_.isFillingSent)
	streamWriteUIntN(streamId, v17_.lastFillType, FillTypeManager.SEND_NUM_BITS)
end

-- Local values: spec
function ForageWagon:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		local v21_ = self.spec_forageWagon
		v21_.isFilling = streamReadBool(streamId)
		v21_.lastFillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
		self:setFillEffectActive(v21_.isFilling)
	end
end

-- Local values: spec
function ForageWagon:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v26_ = self.spec_forageWagon
		local v27_ = streamWriteBool
		local v28_ = v26_.dirtyFlag
		if v27_(streamId, bit32.band(dirtyMask, v28_) ~= 0) then
			streamWriteBool(streamId, v26_.isFillingSent)
			streamWriteUIntN(streamId, v26_.lastFillType, FillTypeManager.SEND_NUM_BITS)
		end
	end
end

-- Local values: spec, isFilling
function ForageWagon:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v31_ = self.spec_forageWagon
	if self.isServer then
		local v32_
		if v31_.fillTimer > 0 then
			v31_.fillTimer = v31_.fillTimer - dt
			v32_ = true
		else
			v32_ = false
		end
		v31_.isFilling = v32_
		if v31_.isFilling ~= v31_.isFillingSent then
			self:raiseDirtyFlags(v31_.dirtyFlag)
			v31_.isFillingSent = v31_.isFilling
			self:setFillEffectActive(v31_.isFilling)
		end
		v31_.pickUpLitersBuffer:add(v31_.workAreaParameters.lastPickupLiters)
	end
end

-- Local values: spec, radius, lsx, lsy, lsz, lex, ley, lez, pickupLiters, supportedFillTypes, fillType, state, fillTypeSupported, i, additivesFillLevel, usage, availableUsage, realArea, area, width
function ForageWagon:processForageWagonArea(workArea)
	local v35_ = self.spec_forageWagon
	local v36_, v37_, v38_, v39_, v40_, v41_ = DensityMapHeightUtil.getLineByArea(workArea.start, workArea.width, workArea.height)
	local v42_ = 0
	if v35_.workAreaParameters.forcedFillType == FillType.UNKNOWN then
		local v43_ = self:getFillUnitSupportedFillTypes(v35_.fillUnitIndex)
		if v43_ ~= nil then
			for v44_, v45_ in pairs(v43_) do
				if v45_ then
					v42_ = -DensityMapHeightUtil.tipToGroundAroundLine(self, -math.huge, v44_, v36_, v37_, v38_, v39_, v40_, v41_, 0.5, nil, nil, false, nil)
					if v42_ > 0 then
						v35_.workAreaParameters.forcedFillType = v44_
						break
					end
				end
			end
		end
	else
		v42_ = -DensityMapHeightUtil.tipToGroundAroundLine(self, -math.huge, v35_.workAreaParameters.forcedFillType, v36_, v37_, v38_, v39_, v40_, v41_, 0.5, nil, nil, false, nil)
		if v35_.workAreaParameters.forcedFillType == FillType.GRASS_WINDROW then
			v42_ = v42_ - DensityMapHeightUtil.tipToGroundAroundLine(self, -math.huge, FillType.DRYGRASS_WINDROW, v36_, v37_, v38_, v39_, v40_, v41_, 0.5, nil, nil, false, nil)
		elseif v35_.workAreaParameters.forcedFillType == FillType.DRYGRASS_WINDROW then
			v42_ = v42_ - DensityMapHeightUtil.tipToGroundAroundLine(self, -math.huge, FillType.GRASS_WINDROW, v36_, v37_, v38_, v39_, v40_, v41_, 0.5, nil, nil, false, nil)
		end
	end
	if self.isServer and v35_.additives.available then
		local v46_ = false
		for v47_ = 1, #v35_.additives.fillTypes do
			if v35_.workAreaParameters.forcedFillType == v35_.additives.fillTypes[v47_] then
				v46_ = true
				break
			end
		end
		if v46_ then
			local v48_ = self:getFillUnitFillLevel(v35_.additives.fillUnitIndex)
			if v48_ > 0 then
				local v49_ = v35_.additives.usage * v42_
				if v49_ > 0 then
					local v50_ = v48_ / v49_
					v42_ = v42_ * (1 + 0.05 * math.min(v50_, 1))
					self:addFillUnitFillLevel(self:getOwnerFarmId(), v35_.additives.fillUnitIndex, -v49_, self:getFillUnitFillType(v35_.additives.fillUnitIndex), ToolType.UNDEFINED)
				end
			end
		end
	end
	workArea.lastPickUpLiters = v42_
	workArea.pickupParticlesActive = v42_ > 0
	v35_.workAreaParameters.lastPickupLiters = v35_.workAreaParameters.lastPickupLiters + v42_
	v35_.workAreaParameters.litersToFill = v35_.workAreaParameters.litersToFill + v42_
	if v35_.workAreaParameters.forcedFillType ~= FillType.UNKNOWN then
		v35_.lastFillType = v35_.workAreaParameters.forcedFillType
		if v35_.lastFillType ~= v35_.lastFillTypeSent then
			v35_.lastFillTypeSent = v35_.lastFillType
			self:raiseDirtyFlags(v35_.dirtyFlag)
		end
	end
	local v51_, v52_
	if self.movingDirection == 1 then
		v51_ = MathUtil.vector3Length(v36_ - v39_, v37_ - v40_, v38_ - v41_) * self.lastMovedDistance
		v52_ = v51_
	else
		v51_ = 0
		v52_ = 0
	end
	return v51_, v52_
end

-- Local values: spec
function ForageWagon:setFillEffectActive(isActive)
	local v55_ = self.spec_forageWagon
	if isActive then
		g_effectManager:setEffectTypeInfo(v55_.fillEffects, v55_.lastFillType)
		g_effectManager:setEffectTypeInfo(v55_.startFillEffect, v55_.lastFillType)
		g_effectManager:startEffects(v55_.fillEffects)
		g_effectManager:startEffects(v55_.startFillEffect)
	else
		g_effectManager:stopEffects(v55_.fillEffects)
		g_effectManager:stopEffects(v55_.startFillEffect)
	end
end

-- Local values: spec, loadInfo, filledLiters
function ForageWagon:fillForageWagon()
	local v57_ = self.spec_forageWagon
	local v58_ = self:getFillVolumeLoadInfo(v57_.loadInfoIndex)
	local v59_ = self:addFillUnitFillLevel(self:getOwnerFarmId(), v57_.fillUnitIndex, v57_.workAreaParameters.litersToFill, v57_.lastFillType, ToolType.UNDEFINED, v58_)
	if v59_ + 0.01 < v57_.workAreaParameters.litersToFill then
		self:setIsTurnedOn(false)
		self:setPickupState(false)
	end
	v57_.workAreaParameters.litersToFill = v57_.workAreaParameters.litersToFill - v59_
	if v57_.workAreaParameters.litersToFill < 0.01 then
		v57_.workAreaParameters.litersToFill = 0
	end
end

function ForageWagon:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)
	if not superFunc(self, speedRotatingPart, xmlFile, key) then
		return false
	end
	speedRotatingPart.rotateOnlyIfFillLevelIncreased = xmlFile:getValue(key .. "#rotateOnlyIfFillLevelIncreased", false)
	return true
end

-- Local values: spec
function ForageWagon:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
	local v68_ = self.spec_forageWagon
	if speedRotatingPart.rotateOnlyIfFillLevelIncreased == nil or (not speedRotatingPart.rotateOnlyIfFillLevelIncreased or v68_.isFilling) then
		return superFunc(self, speedRotatingPart)
	else
		return false
	end
end

-- Local values: spec
function ForageWagon:getFillVolumeUVScrollSpeed(superFunc, fillVolumeIndex)
	local v72_ = self.spec_forageWagon
	if v72_.isFilling then
		return v72_.loadUVScrollSpeed[1], v72_.loadUVScrollSpeed[2], v72_.loadUVScrollSpeed[3]
	elseif self:getDischargeState() == Dischargeable.DISCHARGE_STATE_OFF then
		return superFunc(self, fillVolumeIndex)
	else
		return v72_.dischargeUVScrollSpeed[1], v72_.dischargeUVScrollSpeed[2], v72_.dischargeUVScrollSpeed[3]
	end
end

-- Local values: spec, forageWagonArea
function ForageWagon:getIsWorkAreaActive(superFunc, workArea)
	local v76_ = self.spec_forageWagon
	local v77_ = self.spec_workArea.workAreas[v76_.workAreaIndex]
	if v77_ == nil or (workArea ~= v77_ or self:getIsTurnedOn() and self:allowPickingUp()) then
		return superFunc(self, workArea)
	else
		return false
	end
end

function ForageWagon:doCheckSpeedLimit(superFunc)
	local v80_ = not superFunc(self) and self:getIsTurnedOn()
	if v80_ then
		v80_ = self:getIsLowered()
	end
	return v80_
end

-- Local values: value, count, spec, loadPercentage
function ForageWagon:getConsumingLoad(superFunc)
	local v83_, v84_ = superFunc(self)
	local v85_ = self.spec_forageWagon
	return v83_ + v85_.pickUpLitersBuffer:get(1000) / v85_.maxPickupLitersPerSecond, v84_ + 1
end

-- Local values: spec, fillLevel
function ForageWagon:onStartWorkAreaProcessing(dt)
	local v87_ = self.spec_forageWagon
	v87_.workAreaParameters.forcedFillType = FillType.UNKNOWN
	local v88_ = self:getFillUnitFillLevel(v87_.fillUnitIndex)
	if self:getFillTypeChangeThreshold(v87_.fillUnitIndex) < v88_ then
		v87_.workAreaParameters.forcedFillType = self:getFillUnitFillType(v87_.fillUnitIndex)
	end
	if v88_ == 0 and (v87_.fillStartEffectDelay > 0 and v87_.fillStartEffectTimer <= 0) then
		v87_.fillStartEffectTimer = v87_.fillStartEffectDelay
	end
	v87_.workAreaParameters.lastPickupLiters = 0
end

-- Local values: spec, allowToFill
function ForageWagon:onEndWorkAreaProcessing(dt, hasProcessed)
	local v91_ = self.spec_forageWagon
	if self.isServer and v91_.workAreaParameters.lastPickupLiters > 0 then
		local v92_ = true
		if v91_.fillStartEffectTimer > 0 then
			v91_.fillStartEffectTimer = v91_.fillStartEffectTimer - dt
			if v91_.fillStartEffectTimer > 0 then
				v92_ = false
			end
		end
		if v92_ then
			self:fillForageWagon()
		end
		v91_.fillTimer = 500
	end
end

-- Local values: spec
function ForageWagon:onTurnedOff()
	local v94_ = self.spec_forageWagon
	if self.isClient then
		v94_.fillTimer = 0
		self:setFillEffectActive(false)
	end
end

-- Local values: spec
function ForageWagon:onDeactivate()
	if self.isClient then
		self.spec_forageWagon.fillTimer = 0
		self:setFillEffectActive(false)
	end
end

-- Local values: spec, density
function ForageWagon:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData, appliedDelta)
	if self.isClient then
		local v97_ = self.spec_forageWagon
		local v98_
		if v97_.fillStartEffectFadeOff > 0 then
			local v99_ = self:getFillUnitFillLevel(v97_.fillUnitIndex) / v97_.fillStartEffectFadeOff
			v98_ = 1 - math.min(v99_, 1)
		else
			v98_ = 1
		end
		g_effectManager:setDensity(v97_.startFillEffect, v98_)
	end
end
function ForageWagon.getDefaultSpeedLimit()
	return 20
end
