StrawBlower = {}

function StrawBlower.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(FillUnit, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(Trailer, specializations)
	end
	return v2_
end
function StrawBlower.initSpecialization()
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("StrawBlower")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.strawBlower.baleTrigger#node", "Bale trigger node")
	v3_:register(XMLValueType.INT, "vehicle.strawBlower#fillUnitIndex", "Fill unit index", 1)
	AnimationManager.registerAnimationNodesXMLPaths(v3_, "vehicle.strawBlower.animationNodes")
	SoundManager.registerSampleXMLPaths(v3_, "vehicle.strawBlower.sounds", "start")
	SoundManager.registerSampleXMLPaths(v3_, "vehicle.strawBlower.sounds", "stop")
	SoundManager.registerSampleXMLPaths(v3_, "vehicle.strawBlower.sounds", "work")
	v3_:setXMLSpecializationType()
end

function StrawBlower.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "strawBlowerBaleTriggerCallback", StrawBlower.strawBlowerBaleTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "onDeleteStrawBlowerObject", StrawBlower.onDeleteStrawBlowerObject)
end

function StrawBlower.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDrawFirstFillText", StrawBlower.getDrawFirstFillText)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowDynamicMountFillLevelInfo", StrawBlower.getAllowDynamicMountFillLevelInfo)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addFillUnitFillLevel", StrawBlower.addFillUnitFillLevel)
end

function StrawBlower.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", StrawBlower)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", StrawBlower)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", StrawBlower)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", StrawBlower)
	SpecializationUtil.registerEventListener(vehicleType, "onDischargeStateChanged", StrawBlower)
end

-- Local values: spec, fillUnit
function StrawBlower:onLoad(savegame)
	local v9_ = self.spec_strawBlower
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.strawBlower.baleTrigger#index", "vehicle.strawBlower.baleTrigger#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.strawBlower.doorAnimation#name", "vehicle.foldable.foldingParts.foldingPart.animationName")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.strawBlower.balePickupTrigger", "vehicle.autoLoaderBales.trigger")
	v9_.triggeredBales = {}
	if self.isServer then
		v9_.triggerId = self.xmlFile:getValue("vehicle.strawBlower.baleTrigger#node", nil, self.components, self.i3dMappings)
		if v9_.triggerId ~= nil then
			addTrigger(v9_.triggerId, "strawBlowerBaleTriggerCallback", self)
		end
	end
	if self.isClient then
		v9_.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.strawBlower.animationNodes", self.components, self, self.i3dMappings)
		v9_.samples = {}
		v9_.samples.start = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.strawBlower.sounds", "start", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v9_.samples.stop = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.strawBlower.sounds", "stop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v9_.samples.work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.strawBlower.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
	v9_.fillUnitIndex = self.xmlFile:getValue("vehicle.strawBlower#fillUnitIndex", 1)
	local v10_ = self:getFillUnitByIndex(v9_.fillUnitIndex)
	v10_.synchronizeFullFillLevel = true
	v10_.needsSaving = false
	if savegame ~= nil and not savegame.resetVehicles then
		self:addFillUnitFillLevel(self:getOwnerFarmId(), v9_.fillUnitIndex, -math.huge, FillType.UNKNOWN, ToolType.UNDEFINED)
	end
	if not self.isServer then
		SpecializationUtil.removeEventListener(self, "onUpdateTick", StrawBlower)
	end
end

-- Local values: spec, bale, _
function StrawBlower:onDelete()
	local v12_ = self.spec_strawBlower
	if v12_.triggerId ~= nil then
		removeTrigger(v12_.triggerId)
	end
	if v12_.triggeredBales ~= nil then
		for v13_, _ in pairs(v12_.triggeredBales) do
			if entityExists(v13_.nodeId) then
				I3DUtil.wakeUpObject(v13_.nodeId)
				v13_.allowPickup = true
			end
			if v13_.removeDeleteListener ~= nil then
				v13_:removeDeleteListener(self, "onDeleteStrawBlowerObject")
			end
		end
		table.clear(v12_.triggeredBales)
	end
	g_soundManager:deleteSamples(v12_.samples)
	g_animationManager:deleteAnimations(v12_.animationNodes)
end

-- Local values: spec, bale
function StrawBlower:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v15_ = self.spec_strawBlower
	if v15_.currentBale == nil and self:getFillUnitSupportsToolType(v15_.fillUnitIndex, ToolType.BALE) then
		local v16_ = next(v15_.triggeredBales)
		if v16_ ~= nil then
			self:setFillUnitCapacity(v15_.fillUnitIndex, v16_:getFillLevel())
			self:addFillUnitFillLevel(self:getOwnerFarmId(), v15_.fillUnitIndex, -math.huge, FillType.UNKNOWN, ToolType.UNDEFINED)
			self:addFillUnitFillLevel(self:getOwnerFarmId(), v15_.fillUnitIndex, v16_:getFillLevel(), v16_:getFillType(), ToolType.BALE)
			v15_.currentBale = v16_
		end
	end
end

-- Local values: spec
function StrawBlower:addFillUnitFillLevel(superFunc, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
	if fillUnitIndex == self.spec_strawBlower.fillUnitIndex then
		local v25_ = self:getFillUnitCapacity(fillUnitIndex)
		local v26_ = self:getFillUnitFillLevel(fillUnitIndex) + fillLevelDelta
		self:setFillUnitCapacity(fillUnitIndex, (math.max(v25_, v26_)))
	end
	return superFunc(self, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
end

-- Local values: spec, object, object, triggerCount
function StrawBlower:strawBlowerBaleTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	local v31_ = self.spec_strawBlower
	if onEnter then
		if otherActorId ~= 0 then
			local v32_ = g_currentMission:getNodeObject(otherActorId)
			if v32_ ~= nil and (v32_:isa(Bale) and (g_currentMission.accessHandler:canFarmAccess(self:getActiveFarm(), v32_) and (v32_:getAllowPickup() and self:getFillUnitSupportsFillType(v31_.fillUnitIndex, v32_:getFillType())))) then
				v31_.triggeredBales[v32_] = Utils.getNoNil(v31_.triggeredBales[v32_], 0) + 1
				v32_.allowPickup = false
				if v31_.triggeredBales[v32_] == 1 and v32_.addDeleteListener ~= nil then
					v32_:addDeleteListener(self, "onDeleteStrawBlowerObject")
					return
				end
			end
		end
	elseif onLeave and otherActorId ~= 0 then
		local v33_ = g_currentMission:getNodeObject(otherActorId)
		if v33_ ~= nil then
			local v34_ = v31_.triggeredBales[v33_]
			if v34_ ~= nil then
				if v34_ == 1 then
					v31_.triggeredBales[v33_] = nil
					v33_.allowPickup = true
					if v33_ == v31_.currentBale then
						v31_.currentBale = nil
						self:addFillUnitFillLevel(self:getOwnerFarmId(), v31_.fillUnitIndex, -math.huge, self:getFillUnitFillType(v31_.fillUnitIndex), ToolType.UNDEFINED)
					end
					if v33_.removeDeleteListener ~= nil then
						v33_:removeDeleteListener(self, "onDeleteStrawBlowerObject")
						return
					end
				else
					v31_.triggeredBales[v33_] = v34_ - 1
				end
			end
		end
	end
end

-- Local values: spec
function StrawBlower:onDeleteStrawBlowerObject(object)
	local v37_ = self.spec_strawBlower
	if v37_.triggeredBales[object] ~= nil then
		v37_.triggeredBales[object] = nil
		if object == v37_.currentBale then
			v37_.currentBale = nil
			self:addFillUnitFillLevel(self:getOwnerFarmId(), v37_.fillUnitIndex, -math.huge, self:getFillUnitFillType(v37_.fillUnitIndex), ToolType.UNDEFINED)
		end
	end
end

-- Local values: spec
function StrawBlower:getDrawFirstFillText(superFunc)
	local v40_ = self.spec_strawBlower
	return superFunc(self) or self:getFillUnitFillLevel(v40_.fillUnitIndex) <= 0
end

function StrawBlower:getAllowDynamicMountFillLevelInfo(superFunc)
	return false
end

-- Local values: spec, newFillLevel, bale, baleOwner
function StrawBlower:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData, appliedDelta)
	local v44_ = self.spec_strawBlower
	if fillUnitIndex == v44_.fillUnitIndex then
		local v45_ = self:getFillUnitFillLevel(v44_.fillUnitIndex)
		if self.isServer then
			local v46_ = v44_.currentBale
			if v46_ ~= nil then
				if v45_ <= 0.01 then
					if self.removeDynamicMountedObject ~= nil then
						self:removeDynamicMountedObject(v46_)
					end
					local v47_ = v46_:getOwnerFarmId()
					v46_:delete()
					v44_.currentBale = nil
					v44_.triggeredBales[v46_] = nil
					self:setFillUnitCapacity(v44_.fillUnitIndex, 1)
					self:addFillUnitFillLevel(v47_, v44_.fillUnitIndex, -math.huge, FillType.UNKNOWN, ToolType.UNDEFINED)
					return
				end
				if v45_ < v46_:getFillLevel() and fillTypeIndex == v46_:getFillType() then
					v46_:setFillLevel(v45_)
					return
				end
			end
		elseif v45_ <= 0 then
			self:setFillUnitCapacity(v44_.fillUnitIndex, 1)
		end
	end
end

-- Local values: spec, samples
function StrawBlower:onDischargeStateChanged(state)
	local v50_ = self.spec_strawBlower
	local v51_ = v50_.samples
	if self.isClient then
		if state ~= Dischargeable.DISCHARGE_STATE_OFF then
			g_soundManager:stopSample(v51_.work)
			g_soundManager:stopSample(v51_.stop)
			g_soundManager:playSample(v51_.start)
			g_soundManager:playSample(v51_.work, 0, v51_.start)
			g_animationManager:startAnimations(v50_.animationNodes)
			return
		end
		g_soundManager:stopSample(v51_.start)
		g_soundManager:stopSample(v51_.work)
		g_soundManager:playSample(v51_.stop)
		g_animationManager:stopAnimations(v50_.animationNodes)
	end
end
