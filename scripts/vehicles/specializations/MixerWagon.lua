source("dataS/scripts/vehicles/specializations/events/MixerWagonBaleNotAcceptedEvent.lua")
MixerWagon = {}
source("dataS/scripts/gui/hud/extensions/MixerWagonHUDExtension.lua")

function MixerWagon.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(Trailer, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
	end
	return v2_
end
function MixerWagon.initSpecialization()
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("MixerWagon")
	AnimationManager.registerAnimationNodesXMLPaths(v3_, "vehicle.mixerWagon.mixAnimationNodes")
	AnimationManager.registerAnimationNodesXMLPaths(v3_, "vehicle.mixerWagon.pickupAnimationNodes")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.mixerWagon.baleTriggers.baleTrigger(?)#node", "Bale trigger node")
	v3_:register(XMLValueType.FLOAT, "vehicle.mixerWagon.baleTriggers.baleTrigger(?)#pickupSpeed", "Bale pickup speed in liter per second", 500)
	v3_:register(XMLValueType.BOOL, "vehicle.mixerWagon.baleTriggers.baleTrigger(?)#needsSetIsTurnedOn", "Vehicle needs to be turned on to pickup bales with this trigger", false)
	v3_:register(XMLValueType.BOOL, "vehicle.mixerWagon.baleTriggers.baleTrigger(?)#useEffect", "Filling effect is played while picking up a bale", false)
	v3_:register(XMLValueType.TIME, "vehicle.mixerWagon#mixingTime", "Mixing time after the fill level was changed", 5)
	v3_:register(XMLValueType.INT, "vehicle.mixerWagon#fillUnitIndex", "Fill unit index", 1)
	v3_:register(XMLValueType.STRING, "vehicle.mixerWagon#recipe", "Recipe fill type name")
	EffectManager.registerEffectXMLPaths(v3_, "vehicle.mixerWagon.fillEffect")
	v3_:setXMLSpecializationType()
	Vehicle.xmlSchemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).mixerWagon.fillType(?)#fillLevel", "Fill level", 0)
end

function MixerWagon.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "mixerWagonBaleTriggerCallback", MixerWagon.mixerWagonBaleTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "onMixerWagonBaleDeleted", MixerWagon.onMixerWagonBaleDeleted)
end

function MixerWagon.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addFillUnitFillLevel", MixerWagon.addFillUnitFillLevel)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitAllowsFillType", MixerWagon.getFillUnitAllowsFillType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDischargeFillType", MixerWagon.getDischargeFillType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsBaleAutoLoadable", MixerWagon.getIsBaleAutoLoadable)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoConsumePtoPower", MixerWagon.getDoConsumePtoPower)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConsumingLoad", MixerWagon.getConsumingLoad)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsPowerTakeOffActive", MixerWagon.getIsPowerTakeOffActive)
end

function MixerWagon.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", MixerWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", MixerWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", MixerWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", MixerWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", MixerWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", MixerWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", MixerWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", MixerWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", MixerWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", MixerWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", MixerWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", MixerWagon)
end

-- Local values: spec, recipeFillTypeName, recipeFillTypeIndex, recipe, _, ingredient, entry, _, fillTypeIndex, fillUnit
function MixerWagon:onLoad(savegame)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.mixerWagonBaleTrigger#index", "vehicle.mixerWagon.baleTrigger#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.mixerWagon.baleTrigger#index", "vehicle.mixerWagon.baleTrigger#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.mixerWagonPickupStartSound", "vehicle.turnOnVehicle.sounds.start")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.mixerWagonPickupStopSound", "vehicle.turnOnVehicle.sounds.stop")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.mixerWagonPickupSound", "vehicle.turnOnVehicle.sounds.work")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.mixerWagonRotatingParts.mixerWagonRotatingPart#type", "vehicle.mixerWagon.mixAnimationNodes.animationNode", "mixerWagonMix")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.mixerWagonRotatingParts.mixerWagonRotatingPart#type", "vehicle.mixerWagon.pickupAnimationNodes.animationNode", "mixerWagonPickup")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.mixerWagonRotatingParts.mixerWagonScroller", "vehicle.mixerWagon.pickupAnimationNodes.pickupAnimationNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.mixerWagon.baleTrigger#node", "vehicle.mixerWagon.baleTriggers.baleTrigger#node")
	local v_u_8_ = self.spec_mixerWagon
	if self.isClient then
		v_u_8_.mixAnimationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.mixerWagon.mixAnimationNodes", self.components, self, self.i3dMappings)
		v_u_8_.pickupAnimationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.mixerWagon.pickupAnimationNodes", self.components, self, self.i3dMappings)
		v_u_8_.fillEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.mixerWagon.fillEffect", self.components, self, self.i3dMappings)
		v_u_8_.fillEffectsFillType = FillType.UNKNOWN
		v_u_8_.fillEffectsState = false
	end
	if self.isServer then
		v_u_8_.baleTriggers = {}
		self.xmlFile:iterate("vehicle.mixerWagon.baleTriggers.baleTrigger", function(_, p9_)
			-- upvalues: (copy) self, (copy) v_u_8_
			local v10_ = {
				["node"] = self.xmlFile:getValue(p9_ .. "#node", nil, self.components, self.i3dMappings)
			}
			if v10_.node ~= nil then
				addTrigger(v10_.node, "mixerWagonBaleTriggerCallback", self)
				v10_.pickupSpeed = self.xmlFile:getValue(p9_ .. "#pickupSpeed", 500) / 1000
				v10_.needsSetIsTurnedOn = self.xmlFile:getValue(p9_ .. "#needsSetIsTurnedOn", false)
				v10_.useEffect = self.xmlFile:getValue(p9_ .. "#useEffect", false)
				v10_.balesInTrigger = {}
				local v11_ = v_u_8_.baleTriggers
				table.insert(v11_, v10_)
			end
		end)
	end
	v_u_8_.activeTimerMax = self.xmlFile:getValue("vehicle.mixerWagon#mixingTime", 5)
	v_u_8_.activeTimer = 0
	v_u_8_.fillUnitIndex = self.xmlFile:getValue("vehicle.mixerWagon#fillUnitIndex", 1)
	v_u_8_.mixerWagonFillTypes = {}
	v_u_8_.fillTypeToMixerWagonFillType = {}
	local v12_ = self.xmlFile:getValue("vehicle.mixerWagon#recipe")
	if v12_ ~= nil then
		local v13_ = g_fillTypeManager:getFillTypeIndexByName(v12_)
		if v13_ == nil then
			Logging.xmlError(self.xmlFile, "MixerWagon recipe \'%s\' not defined!", v12_)
		end
		local v14_ = g_currentMission.animalFoodSystem:getRecipeByFillTypeIndex(v13_)
		if v14_ == nil then
			Logging.xmlWarning(self.xmlFile, "MixerWagon recipe \'%s\' not defined!", v12_)
		end
		if v14_ ~= nil then
			for _, v15_ in ipairs(v14_.ingredients) do
				local v16_ = {
					["fillLevel"] = 0,
					["fillTypes"] = {},
					["name"] = v15_.name,
					["minPercentage"] = v15_.minPercentage,
					["maxPercentage"] = v15_.maxPercentage,
					["ratio"] = v15_.ratio
				}
				for _, v17_ in ipairs(v15_.fillTypes) do
					v16_.fillTypes[v17_] = true
					v_u_8_.fillTypeToMixerWagonFillType[v17_] = v16_
				end
				local v18_ = v_u_8_.mixerWagonFillTypes
				table.insert(v18_, v16_)
			end
		end
	end
	if #v_u_8_.mixerWagonFillTypes > 0 then
		local v19_ = self:getFillUnitByIndex(v_u_8_.fillUnitIndex)
		if v19_ ~= nil then
			v19_.needsSaving = false
			v19_.synchronizeFillLevel = false
		end
	end
	v_u_8_.dirtyFlag = self:getNextDirtyFlag()
	v_u_8_.effectDirtyFlag = self:getNextDirtyFlag()
	v_u_8_.hudExtension = MixerWagonHUDExtension.new(self)
end

-- Local values: spec, i, entry, fillTypeKey, fillLevel
function MixerWagon:onPostLoad(savegame)
	if savegame ~= nil then
		local v22_ = self.spec_mixerWagon
		for v23_, v24_ in ipairs(v22_.mixerWagonFillTypes) do
			local v25_ = savegame.key .. string.format(".mixerWagon.fillType(%d)#fillLevel", v23_ - 1)
			local v26_ = savegame.xmlFile:getValue(v25_, 0)
			if v26_ > 0 then
				self:addFillUnitFillLevel(self:getOwnerFarmId(), v22_.fillUnitIndex, v26_, next(v24_.fillTypes), ToolType.UNDEFINED, nil)
			end
		end
	end
	if self.spec_hudInfoTrigger == nil or self.spec_hudInfoTrigger.triggerNode == nil then
		Logging.xmlDevWarning(self.xmlFile, "Missing hudInfoTrigger for mixer wagon. Required for external mixer wagon hud visibility!")
	end
end

-- Local values: spec, _, baleTrigger, bale, _
function MixerWagon:onDelete()
	local v28_ = self.spec_mixerWagon
	if v28_.baleTriggers ~= nil then
		for _, v29_ in ipairs(v28_.baleTriggers) do
			removeTrigger(v29_.node)
			for v30_, _ in pairs(v29_.balesInTrigger) do
				if v30_.removeDeleteListener ~= nil then
					v30_:removeDeleteListener(self, self.onMixerWagonBaleDeleted)
				end
			end
			table.clear(v29_.balesInTrigger)
		end
		table.clear(v28_.baleTriggers)
	end
	g_animationManager:deleteAnimations(v28_.mixAnimationNodes)
	g_animationManager:deleteAnimations(v28_.pickupAnimationNodes)
	g_effectManager:deleteEffects(v28_.fillEffects)
	if v28_.hudExtension ~= nil then
		g_currentMission.hud:removeInfoExtension(v28_.hudExtension)
		v28_.hudExtension:delete()
	end
end

-- Local values: spec, i, fillType, fillTypeKey
function MixerWagon:saveToXMLFile(xmlFile, key, usedModNames)
	local v34_ = self.spec_mixerWagon
	for v35_, v36_ in ipairs(v34_.mixerWagonFillTypes) do
		xmlFile:setValue(string.format("%s.fillType(%d)", key, v35_ - 1) .. "#fillLevel", v36_.fillLevel)
	end
end

-- Local values: spec, _, entry, fillLevel
function MixerWagon:onReadStream(streamId, connection)
	local v39_ = self.spec_mixerWagon
	for _, v40_ in ipairs(v39_.mixerWagonFillTypes) do
		local v41_ = streamReadFloat32(streamId)
		if v41_ > 0 then
			self:addFillUnitFillLevel(self:getOwnerFarmId(), v39_.fillUnitIndex, v41_, next(v40_.fillTypes), ToolType.UNDEFINED, nil)
		end
	end
	v39_.fillEffectsFillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
end

-- Local values: spec, _, entry
function MixerWagon:onWriteStream(streamId, connection)
	local v44_ = self.spec_mixerWagon
	for _, v45_ in ipairs(v44_.mixerWagonFillTypes) do
		streamWriteFloat32(streamId, v45_.fillLevel)
	end
	streamWriteUIntN(streamId, v44_.fillEffectsFillType, FillTypeManager.SEND_NUM_BITS)
end

-- Local values: spec, _, entry, fillLevel, delta
function MixerWagon:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local v49_ = self.spec_mixerWagon
		if streamReadBool(streamId) then
			for _, v50_ in ipairs(v49_.mixerWagonFillTypes) do
				local v51_ = streamReadFloat32(streamId) - v50_.fillLevel
				if v51_ ~= 0 then
					self:addFillUnitFillLevel(self:getOwnerFarmId(), v49_.fillUnitIndex, v51_, next(v50_.fillTypes), ToolType.UNDEFINED, nil)
				end
			end
		end
		if streamReadBool(streamId) then
			v49_.fillEffectsFillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
		end
	end
end

-- Local values: spec, _, entry
function MixerWagon:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v56_ = self.spec_mixerWagon
		local v57_ = streamWriteBool
		local v58_ = v56_.dirtyFlag
		if v57_(streamId, bit32.band(dirtyMask, v58_) ~= 0) then
			for _, v59_ in ipairs(v56_.mixerWagonFillTypes) do
				streamWriteFloat32(streamId, v59_.fillLevel)
			end
		end
		local v60_ = streamWriteBool
		local v61_ = v56_.effectDirtyFlag
		if v60_(streamId, bit32.band(dirtyMask, v61_) ~= 0) then
			streamWriteUIntN(streamId, v56_.fillEffectsFillType, FillTypeManager.SEND_NUM_BITS)
		end
	end
end

-- Local values: spec, tipState, isTurnedOn, isDischarging, fillEffectsFillType, i, baleTrigger, bale, _, baleFillLevel, deltaFillLevel, fillType, state, fillType, state
function MixerWagon:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v64_ = self.spec_mixerWagon
	local v65_ = self:getTipState()
	local v66_ = self:getIsTurnedOn()
	local v67_ = v65_ == Trailer.TIPSTATE_OPENING and true or v65_ == Trailer.TIPSTATE_OPEN
	if self:getIsPowered() and (v64_.activeTimer > 0 or (v66_ or v67_)) then
		v64_.activeTimer = v64_.activeTimer - dt
		g_animationManager:startAnimations(v64_.mixAnimationNodes)
	else
		g_animationManager:stopAnimations(v64_.mixAnimationNodes)
	end
	if self.isServer then
		local v68_ = FillType.UNKNOWN
		if self:getFillUnitFreeCapacity(v64_.fillUnitIndex) > 0 then
			for v69_ = 1, #v64_.baleTriggers do
				local v70_ = v64_.baleTriggers[v69_]
				if not v70_.needsSetIsTurnedOn or self:getIsTurnedOn() then
					for v71_, _ in pairs(v70_.balesInTrigger) do
						local v72_ = v71_:getFillLevel()
						local v73_ = v70_.pickupSpeed * dt
						local v74_ = math.min(v73_, v72_)
						local v75_ = v71_:getFillType()
						local v76_ = v72_ - self:addFillUnitFillLevel(self:getOwnerFarmId(), v64_.fillUnitIndex, v74_, v75_, ToolType.BALE, nil)
						v71_:setFillLevel(v76_)
						if v76_ < 0.01 then
							v71_:delete()
							v70_.balesInTrigger[v71_] = nil
						end
						if v70_.useEffect then
							v68_ = v75_
						end
					end
				end
			end
		end
		local v77_
		if v68_ == FillType.UNKNOWN and self.getIsShovelEffectState ~= nil then
			local v78_
			v78_, v77_ = self:getIsShovelEffectState()
			if not v78_ then
				v77_ = v68_
			end
		else
			v77_ = v68_
		end
		if v64_.fillEffectsFillType ~= v77_ then
			v64_.fillEffectsFillType = v77_
			self:raiseDirtyFlags(v64_.effectDirtyFlag)
		end
	end
	if self.isClient then
		local v79_ = v64_.fillEffectsFillType ~= FillType.UNKNOWN
		if v79_ ~= v64_.fillEffectsState then
			if v79_ then
				g_effectManager:setEffectTypeInfo(v64_.fillEffects, v64_.fillEffectsFillType)
				g_effectManager:startEffects(v64_.fillEffects)
			else
				g_effectManager:stopEffects(v64_.fillEffects)
			end
			v64_.fillEffectsState = v79_
		end
	end
end

-- Local values: spec
function MixerWagon:onDraw()
	local v81_ = self.spec_mixerWagon
	if v81_.hudExtension ~= nil then
		g_currentMission.hud:addInfoExtension(v81_.hudExtension)
	end
end

-- Local values: bale, spec, i, baleTrigger
function MixerWagon:mixerWagonBaleTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if otherActorId ~= 0 then
		local v87_ = g_currentMission:getNodeObject(otherActorId)
		if v87_ ~= nil and v87_:isa(Bale) then
			local v88_ = self.spec_mixerWagon
			if self:getFillUnitSupportsFillType(v88_.fillUnitIndex, v87_:getFillType()) then
				for v89_ = 1, #v88_.baleTriggers do
					local v90_ = v88_.baleTriggers[v89_]
					if v90_.node == triggerId then
						if onEnter then
							v90_.balesInTrigger[v87_] = (v90_.balesInTrigger[v87_] or 0) + 1
							if v90_.balesInTrigger[v87_] == 1 then
								v87_:addDeleteListener(self, self.onMixerWagonBaleDeleted)
							end
						elseif onLeave then
							v90_.balesInTrigger[v87_] = (v90_.balesInTrigger[v87_] or 1) - 1
							if v90_.balesInTrigger[v87_] == 0 then
								v90_.balesInTrigger[v87_] = nil
								v87_:removeDeleteListener(self, self.onMixerWagonBaleDeleted)
							end
						end
					end
				end
				return
			end
			if onEnter and otherActorId == v87_.nodeId then
				g_currentMission:broadcastEventToFarm(MixerWagonBaleNotAcceptedEvent.new(), self:getOwnerFarmId(), true)
			end
		end
	end
end

-- Local values: spec, i, baleTrigger
function MixerWagon:onMixerWagonBaleDeleted(bale)
	local v93_ = self.spec_mixerWagon
	for v94_ = 1, #v93_.baleTriggers do
		v93_.baleTriggers[v94_].balesInTrigger[bale] = nil
	end
end

-- Local values: spec, oldFillLevel, mixerWagonFillType, _, entry, delta, newFillLevel, _, entry, entryDelta, _, entry, ret, capacity, free, newFillLevel, _, fillType, newFillType, isSingleFilled, isForageOk, _, fillType, _, fillType
function MixerWagon:addFillUnitFillLevel(superFunc, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
	local v103_ = self.spec_mixerWagon
	if fillUnitIndex ~= v103_.fillUnitIndex then
		return superFunc(self, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
	end
	if #v103_.mixerWagonFillTypes == 0 then
		if fillLevelDelta ~= 0 and self:getIsSynchronized() then
			v103_.activeTimer = v103_.activeTimerMax
		end
		return superFunc(self, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
	end
	local v104_ = self:getFillUnitFillLevel(fillUnitIndex)
	local v105_ = v103_.fillTypeToMixerWagonFillType[fillTypeIndex]
	if fillTypeIndex == FillType.FORAGE and fillLevelDelta > 0 then
		for _, v106_ in pairs(v103_.mixerWagonFillTypes) do
			self:addFillUnitFillLevel(farmId, fillUnitIndex, fillLevelDelta * v106_.ratio, next(v106_.fillTypes), toolType, fillPositionData)
		end
		return fillLevelDelta
	end
	if v105_ == nil then
		if fillLevelDelta >= 0 or v104_ <= 0 then
			return 0
		end
		local v107_ = -v104_
		local v108_ = math.max(fillLevelDelta, v107_)
		local v109_ = 0
		for _, v110_ in pairs(v103_.mixerWagonFillTypes) do
			local v111_ = v108_ * (v110_.fillLevel / v104_)
			local v112_ = v110_.fillLevel + v111_
			v110_.fillLevel = math.max(v112_, 0)
			v109_ = v109_ + v110_.fillLevel
		end
		if v109_ < 0.1 then
			for _, v113_ in pairs(v103_.mixerWagonFillTypes) do
				v113_.fillLevel = 0
			end
			v108_ = -v104_
		end
		self:raiseDirtyFlags(v103_.dirtyFlag)
		return superFunc(self, farmId, fillUnitIndex, v108_, fillTypeIndex, toolType, fillPositionData)
	end
	local v114_ = self:getFillUnitCapacity(fillUnitIndex) - v104_
	if fillLevelDelta > 0 then
		v105_.fillLevel = v105_.fillLevel + math.min(v114_, fillLevelDelta)
		if self:getIsSynchronized() then
			v103_.activeTimer = v103_.activeTimerMax
		end
	else
		local v115_ = v105_.fillLevel + fillLevelDelta
		v105_.fillLevel = math.max(0, v115_)
	end
	local v116_ = 0
	for _, v117_ in pairs(v103_.mixerWagonFillTypes) do
		v116_ = v116_ + v117_.fillLevel
	end
	local v118_ = self:getFillUnitCapacity(fillUnitIndex)
	local v119_ = math.clamp(v116_, 0, v118_)
	local v120_ = FillType.UNKNOWN
	local v121_ = false
	local v122_ = false
	for _, v123_ in pairs(v103_.mixerWagonFillTypes) do
		if v119_ == v123_.fillLevel then
			v120_ = next(v105_.fillTypes)
			v122_ = true
			break
		end
	end
	if not v122_ then
		v121_ = true
		for _, v124_ in pairs(v103_.mixerWagonFillTypes) do
			if v124_.fillLevel < v124_.minPercentage * v119_ - 0.01 or v124_.fillLevel > v124_.maxPercentage * v119_ + 0.01 then
				v121_ = false
				break
			end
		end
	end
	if v121_ then
		v120_ = FillType.FORAGE
	elseif not v122_ then
		v120_ = FillType.FORAGE_MIXING
	end
	self:raiseDirtyFlags(v103_.dirtyFlag)
	self:setFillUnitFillType(fillUnitIndex, v120_)
	return superFunc(self, farmId, fillUnitIndex, v119_ - v104_, v120_, toolType, fillPositionData)
end

-- Local values: spec, mixerWagonFillType
function MixerWagon:getFillUnitAllowsFillType(superFunc, fillUnitIndex, fillTypeIndex)
	local v129_ = self.spec_mixerWagon
	return v129_.fillUnitIndex == fillUnitIndex and (#v129_.mixerWagonFillTypes > 0 and v129_.fillTypeToMixerWagonFillType[fillTypeIndex] ~= nil) and true or superFunc(self, fillUnitIndex, fillTypeIndex)
end

-- Local values: spec, fillUnitIndex, currentFillType, fillLevel, _, entry
function MixerWagon:getDischargeFillType(superFunc, dischargeNode)
	local v133_ = self.spec_mixerWagon
	local v134_ = dischargeNode.fillUnitIndex
	if v134_ ~= v133_.fillUnitIndex then
		return superFunc(self, dischargeNode)
	end
	local v135_ = self:getFillUnitFillType(v134_)
	local v136_ = self:getFillUnitFillLevel(v134_)
	if v135_ == FillType.FORAGE_MIXING and v136_ > 0 then
		for _, v137_ in pairs(v133_.mixerWagonFillTypes) do
			if v137_.fillLevel > 0 then
				v135_ = next(v137_.fillTypes)
				break
			end
		end
	end
	return v135_, 1
end

-- Local values: spec, i, baleTrigger, loadedFillTypeIndex
function MixerWagon:getIsBaleAutoLoadable(superFunc, bale)
	local v141_ = self.spec_mixerWagon
	if self:getIsTurnedOn() then
		for v142_ = 1, #v141_.baleTriggers do
			local v143_ = v141_.baleTriggers[v142_]
			if next(v143_.balesInTrigger) ~= nil then
				return false
			end
		end
		local v144_ = self:getFillUnitFillType(v141_.fillUnitIndex)
		if v144_ == FillType.UNKNOWN or bale:getFillType() == v144_ then
			if self:getFillUnitFreeCapacity(v141_.fillUnitIndex) <= 0 then
				return false
			else
				return superFunc(self, bale)
			end
		else
			return false
		end
	else
		return false
	end
end

function MixerWagon:getDoConsumePtoPower(superFunc)
	return self.spec_mixerWagon.activeTimer > 0 and true or superFunc(self)
end

-- Local values: value, count, loadPercentage
function MixerWagon:getConsumingLoad(superFunc)
	local v149_, v150_ = superFunc(self)
	return v149_ + (self.spec_mixerWagon.activeTimer > 0 and 1 or 0), v150_ + 1
end

function MixerWagon:getIsPowerTakeOffActive(superFunc)
	return self.spec_mixerWagon.activeTimer > 0 and true or superFunc(self)
end

-- Local values: spec, fillLevel, _, entry
function MixerWagon:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData, appliedDelta)
	local v155_ = self.spec_mixerWagon
	if v155_.fillUnitIndex == fillUnitIndex and self:getFillUnitFillLevel(fillUnitIndex) == 0 then
		for _, v156_ in pairs(v155_.mixerWagonFillTypes) do
			v156_.fillLevel = 0
		end
	end
end

-- Local values: spec
function MixerWagon:onTurnedOn()
	if self.isClient then
		local v158_ = self.spec_mixerWagon
		g_animationManager:startAnimations(v158_.pickupAnimationNodes)
	end
end

-- Local values: spec
function MixerWagon:onTurnedOff()
	if self.isClient then
		local v160_ = self.spec_mixerWagon
		g_animationManager:stopAnimations(v160_.pickupAnimationNodes)
	end
end

-- Local values: spec, _, mixerWagonFillType, fillTypes, fillTypeIndex, _
function MixerWagon:updateDebugValues(values)
	local v163_ = self.spec_mixerWagon
	local v164_ = {
		["name"] = "Forage isOK"
	}
	local v165_ = self:getFillUnitFillType(v163_.fillUnitIndex) == FillType.FORAGE
	v164_.value = tostring(v165_)
	table.insert(values, v164_)
	for _, v166_ in ipairs(v163_.mixerWagonFillTypes) do
		local v167_ = ""
		for v168_, _ in pairs(v166_.fillTypes) do
			local v169_ = g_fillTypeManager
			v167_ = v167_ .. " " .. tostring(v169_:getFillTypeNameByIndex(v168_))
		end
		local v170_ = {
			["name"] = v167_,
			["value"] = v166_.fillLevel
		}
		table.insert(values, v170_)
	end
end
