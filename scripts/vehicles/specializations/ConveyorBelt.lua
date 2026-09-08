ConveyorBelt = {}

function ConveyorBelt.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Dischargeable, specializations)
end
function ConveyorBelt.initSpecialization()
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("ConveyorBelt")
	AnimationManager.registerAnimationNodesXMLPaths(v2_, "vehicle.conveyorBelt.animationNodes")
	EffectManager.registerEffectXMLPaths(v2_, "vehicle.conveyorBelt.effects")
	v2_:register(XMLValueType.INT, "vehicle.conveyorBelt#dischargeNodeIndex", "Discharge node index", 1)
	v2_:register(XMLValueType.FLOAT, "vehicle.conveyorBelt#startPercentage", "Start unloading percentage", 0.9)
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.conveyorBelt.offset(?)#movingToolNode", "Moving tool node")
	v2_:register(XMLValueType.INT, "vehicle.conveyorBelt.offset(?).effect(?)#index", "Index of effect", 0)
	v2_:register(XMLValueType.FLOAT, "vehicle.conveyorBelt.offset(?).effect(?)#minOffset", "Min. offset", 0)
	v2_:register(XMLValueType.FLOAT, "vehicle.conveyorBelt.offset(?).effect(?)#maxOffset", "Max. offset", 1)
	v2_:register(XMLValueType.BOOL, "vehicle.conveyorBelt.offset(?).effect(?)#inverted", "Is inverted", false)
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.conveyorBelt.sounds", "belt")
	v2_:setXMLSpecializationType()
end

function ConveyorBelt.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getConveyorBeltFillLevel", ConveyorBelt.getConveyorBeltFillLevel)
	SpecializationUtil.registerFunction(vehicleType, "getConveyorBeltTargetObject", ConveyorBelt.getConveyorBeltTargetObject)
	SpecializationUtil.registerFunction(vehicleType, "getLoadTriggerMaxFillSpeed", ConveyorBelt.getLoadTriggerMaxFillSpeed)
end

function ConveyorBelt.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDischargeNodeEmptyFactor", ConveyorBelt.getDischargeNodeEmptyFactor)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "handleDischargeOnEmpty", ConveyorBelt.handleDischargeOnEmpty)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "handleDischarge", ConveyorBelt.handleDischarge)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsEnterable", ConveyorBelt.getIsEnterable)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitAllowsFillType", ConveyorBelt.getFillUnitAllowsFillType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitFreeCapacity", ConveyorBelt.getFillUnitFreeCapacity)
end

function ConveyorBelt.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ConveyorBelt)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", ConveyorBelt)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", ConveyorBelt)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", ConveyorBelt)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", ConveyorBelt)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", ConveyorBelt)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", ConveyorBelt)
	SpecializationUtil.registerEventListener(vehicleType, "onMovingToolChanged", ConveyorBelt)
end

-- Local values: spec, _, effect, dischargeNode, capacity, i, key, movingToolNode, offset, j, effectKey, effectIndex, effect, entry
function ConveyorBelt:onLoad(savegame)
	local v7_ = self.spec_conveyorBelt
	if self.isClient then
		v7_.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.conveyorBelt.animationNodes", self.components, self, self.i3dMappings)
		v7_.samples = {}
		v7_.samples.belt = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.conveyorBelt.sounds", "belt", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
	v7_.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.conveyorBelt.effects", self.components, self, self.i3dMappings)
	v7_.currentDelay = 0.0001
	table.sort(v7_.effects, function(p8_, p9_)
		return p8_.startDelay < p9_.startDelay
	end)
	for _, v10_ in pairs(v7_.effects) do
		if v10_.planeFadeTime ~= nil then
			v7_.currentDelay = v7_.currentDelay + v10_.planeFadeTime
		end
		if v10_.setScrollUpdate ~= nil then
			v10_:setScrollUpdate(false)
		end
	end
	v7_.maxDelay = v7_.currentDelay
	v7_.morphStartPos = 0
	v7_.morphEndPos = 0
	v7_.isEffectDirty = true
	v7_.emptyFactor = 1
	v7_.scrollUpdateTime = 0
	v7_.lastScrollUpdate = false
	v7_.fillUnitIndex = 1
	v7_.startFillLevel = 0
	v7_.dischargeNodeIndex = self.xmlFile:getValue("vehicle.conveyorBelt#dischargeNodeIndex", 1)
	self:setCurrentDischargeNodeIndex(v7_.dischargeNodeIndex)
	local v11_ = self:getDischargeNodeByIndex(v7_.dischargeNodeIndex)
	local v12_
	if v11_ == nil then
		v12_ = 0
	else
		local v13_ = self:getFillUnitCapacity(v11_.fillUnitIndex)
		v7_.fillUnitIndex = v11_.fillUnitIndex
		v7_.startFillLevel = v13_ * self.xmlFile:getValue("vehicle.conveyorBelt#startPercentage", 0.9)
		v12_ = 0
	end
	while true do
		local v14_ = string.format("vehicle.conveyorBelt.offset(%d)", v12_)
		if not self.xmlFile:hasProperty(v14_) then
			break
		end
		local v15_ = self.xmlFile:getValue(v14_ .. "#movingToolNode", nil, self.components, self.i3dMappings)
		if v15_ == nil then
			Logging.xmlWarning(self.xmlFile, "Missing movingToolNode for conveyor offset \'%s\'!", v14_)
		else
			local v16_, v17_
			if v7_.offsets == nil then
				v7_.offsets = {}
				v16_ = 0
				v17_ = {
					["lastState"] = nil,
					["movingToolNode"] = v15_,
					["effects"] = {}
				}
			else
				v16_ = 0
				v17_ = {
					["lastState"] = nil,
					["movingToolNode"] = v15_,
					["effects"] = {}
				}
			end
			while true do
				local v18_ = string.format(v14_ .. ".effect(%d)", v16_)
				if not self.xmlFile:hasProperty(v18_) then
					break
				end
				local v19_ = self.xmlFile:getValue(v18_ .. "#index", 0)
				local v20_ = v7_.effects[v19_]
				if v20_ == nil or v20_.setOffset == nil then
					Logging.xmlWarning(self.xmlFile, "Effect index \'%d\' not found at \'%s\'!", v19_, v18_)
				else
					local v21_ = {
						["effect"] = v20_,
						["minValue"] = self.xmlFile:getValue(v18_ .. "#minOffset", 0) * 1000,
						["maxValue"] = self.xmlFile:getValue(v18_ .. "#maxOffset", 1) * 1000,
						["inverted"] = self.xmlFile:getValue(v18_ .. "#inverted", false)
					}
					local v22_ = v17_.effects
					table.insert(v22_, v21_)
				end
				v16_ = v16_ + 1
			end
			local v23_ = v7_.offsets
			table.insert(v23_, v17_)
		end
		v12_ = v12_ + 1
	end
	v7_.isFilling = false
	v7_.isScrolling = false
	v7_.dirtyFlag = self:getNextDirtyFlag()
end

-- Local values: spec, i, offset, movingTool
function ConveyorBelt:onPostLoad(savegame)
	local v25_ = self.spec_conveyorBelt
	if v25_.offsets ~= nil then
		if self.getMovingToolByNode == nil then
			Logging.xmlError(self.xmlFile, "\'Cylindered\' specialization is required to use conveyorBelt offsets!")
			v25_.offsets = nil
		else
			v25_.movingToolToOffset = {}
			for v26_ = #v25_.offsets, 1, -1 do
				local v27_ = v25_.offsets[v26_]
				local v28_ = self:getMovingToolByNode(v27_.movingToolNode)
				if v28_ == nil then
					Logging.xmlWarning(self.xmlFile, "No movingTool node \'%s\' defined for conveyor offset \'%d\'!", getName(v27_.movingToolNode), v26_)
					table.remove(v25_.offsets, v26_)
				else
					v27_.movingTool = v28_
					v25_.movingToolToOffset[v28_] = v27_
					ConveyorBelt.onMovingToolChanged(self, v28_, 0, 0)
				end
			end
			if #v25_.offsets == 0 then
				v25_.offsets = nil
				v25_.movingToolToOffset = nil
				return
			end
		end
	end
end

-- Local values: spec
function ConveyorBelt:onDelete()
	local v30_ = self.spec_conveyorBelt
	g_effectManager:deleteEffects(v30_.effects)
	g_animationManager:deleteAnimations(v30_.animationNodes)
	g_soundManager:deleteSamples(v30_.samples)
end

-- Local values: spec
function ConveyorBelt:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		local v34_ = self.spec_conveyorBelt
		v34_.isFilling = streamReadBool(streamId)
		v34_.isScrolling = streamReadBool(streamId)
	end
end

-- Local values: spec
function ConveyorBelt:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v39_ = self.spec_conveyorBelt
		local v40_ = streamWriteBool
		local v41_ = v39_.dirtyFlag
		if v40_(streamId, bit32.band(dirtyMask, v41_) ~= 0) then
			streamWriteBool(streamId, v39_.isFilling)
			streamWriteBool(streamId, v39_.isScrolling)
		end
	end
end

-- Local values: spec, doScrollUpdate, _, effect, isBeltActive, fillFactor, movedFactor, visualFactor, offset, _, effect, effectStart, effectEnd, offsetFactor, startMorphFactor, startMorph, endMorphFactor, endMorph
function ConveyorBelt:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v44_ = self.spec_conveyorBelt
	if not self.isServer then
		if v44_.isFilling then
			v44_.morphStartPos = 0
			local v45_ = v44_.morphEndPos
			local v46_ = v44_.fillUnitIndex
			v44_.morphEndPos = math.max(v45_, self:getFillUnitFillLevelPercentage(v46_))
			v44_.isEffectDirty = true
		end
		if v44_.isScrolling then
			v44_.scrollUpdateTime = 100
		end
	end
	local v47_ = v44_.scrollUpdateTime > 0
	if v47_ ~= v44_.lastScrollUpdate then
		if self.isClient then
			if v47_ then
				g_animationManager:startAnimations(v44_.animationNodes)
				g_soundManager:playSample(v44_.samples.belt)
			else
				g_animationManager:stopAnimations(v44_.animationNodes)
				g_soundManager:stopSample(v44_.samples.belt)
			end
			for _, v48_ in pairs(v44_.effects) do
				if v48_.setScrollUpdate ~= nil then
					v48_:setScrollUpdate(v47_)
				end
			end
		end
		v44_.lastScrollUpdate = v47_
	end
	local v49_ = v44_.scrollUpdateTime - dt
	v44_.scrollUpdateTime = math.max(v49_, 0)
	if self:getDischargeState() ~= Dischargeable.DISCHARGE_STATE_OFF then
		local v50_ = self:getFillUnitFillLevelPercentage(v44_.fillUnitIndex)
		if v50_ > 0.0001 then
			local v51_ = dt / v44_.currentDelay
			local v52_ = v44_.morphStartPos + v51_
			v44_.morphStartPos = math.clamp(v52_, 0, 1)
			local v53_ = v44_.morphEndPos + v51_
			v44_.morphEndPos = math.clamp(v53_, 0, 1)
			local v54_ = v44_.morphEndPos - v44_.morphStartPos
			v44_.emptyFactor = 1
			if v50_ < v54_ then
				local v55_ = v50_ / math.max(v54_, 0.001)
				v44_.emptyFactor = math.clamp(v55_, 0, 1)
			else
				local v56_ = v50_ - v54_
				v44_.offset = v56_
				local v57_ = v44_.morphStartPos
				local v58_ = (1 - v44_.morphStartPos) * v44_.currentDelay
				local v59_ = v57_ - v56_ / math.max(v58_, 0.001) * dt
				v44_.morphStartPos = math.clamp(v59_, 0, 1)
			end
			v44_.isEffectDirty = true
			v44_.scrollUpdateTime = dt * 3
		end
	end
	if v47_ then
		self:raiseActive()
	end
	if self.isClient and v44_.isEffectDirty then
		for _, v60_ in pairs(v44_.effects) do
			if v60_.setMorphPosition ~= nil then
				local v61_ = v60_.startDelay / v44_.currentDelay
				local v62_ = (v60_.startDelay + v60_.planeFadeTime - v60_.offset) / v44_.currentDelay
				local v63_ = v60_.offset / v60_.planeFadeTime
				local v64_ = v63_ + (v44_.morphStartPos - v61_) / (v62_ - v61_) * (1 - v63_)
				local v65_ = math.clamp(v64_, v63_, 1)
				local v66_ = v63_ + (v44_.morphEndPos - v61_) / (v62_ - v61_) * (1 - v63_)
				v60_:setMorphPosition(v65_, (math.clamp(v66_, v63_, 1)))
			end
		end
		v44_.isEffectDirty = false
	end
end

-- Local values: spec, fillLevel, currentDischargeNode, object
function ConveyorBelt:getConveyorBeltFillLevel()
	local v68_ = self:getFillUnitFillLevel(self.spec_conveyorBelt.fillUnitIndex)
	if self.getCurrentDischargeNode ~= nil then
		local v69_ = self:getCurrentDischargeNode().dischargeHitObject
		if v69_ ~= nil and v69_.getConveyorBeltFillLevel ~= nil then
			v68_ = v68_ + v69_:getConveyorBeltFillLevel()
		end
	end
	return v68_
end

-- Local values: currentDischargeNode, object, targetFillUnitIndex
function ConveyorBelt:getConveyorBeltTargetObject()
	if self.getCurrentDischargeNode ~= nil then
		local v71_ = self:getCurrentDischargeNode()
		local v72_ = v71_.dischargeHitObject
		local v73_ = v71_.dischargeHitObjectUnitIndex
		if v72_ ~= nil then
			if v72_.getConveyorBeltTargetObject == nil then
				return v72_, v73_
			else
				return v72_:getConveyorBeltTargetObject()
			end
		end
	end
	return nil
end

-- Local values: maxSpeed, currentDischargeNode, object
function ConveyorBelt:getLoadTriggerMaxFillSpeed()
	local v75_
	if self.getCurrentDischargeNode == nil then
		v75_ = math.huge
	else
		local v76_ = self:getCurrentDischargeNode()
		v75_ = v76_.emptySpeed
		local v77_ = v76_.dischargeHitObject
		if v77_ ~= nil and v77_.getLoadTriggerMaxFillSpeed ~= nil then
			local v78_ = v77_:getLoadTriggerMaxFillSpeed()
			v75_ = math.min(v78_, v75_)
		end
	end
	return v75_
end

-- Local values: spec, parentFactor
function ConveyorBelt:getDischargeNodeEmptyFactor(superFunc, dischargeNode)
	local v82_ = self.spec_conveyorBelt
	local v83_ = superFunc(self, dischargeNode)
	if v82_.dischargeNodeIndex == dischargeNode.index then
		return v82_.morphEndPos ~= 1 and 0 or v82_.emptyFactor
	else
		return v83_
	end
end

-- Local values: spec
function ConveyorBelt:handleDischargeOnEmpty(superFunc, dischargeNode)
	local v87_ = self.spec_conveyorBelt
	if dischargeNode.index ~= v87_.dischargeNodeIndex then
		superFunc(self, dischargeNode)
	end
end

-- Local values: spec
function ConveyorBelt:handleDischarge(superFunc, dischargeNode, dischargedLiters, minDropReached, hasMinDropFillLevel)
	local v94_ = self.spec_conveyorBelt
	if dischargeNode.index ~= v94_.dischargeNodeIndex then
		superFunc(self, dischargeNode, dischargedLiters, minDropReached, hasMinDropFillLevel)
	end
end

function ConveyorBelt:getIsEnterable(superFunc)
	local v97_
	if self.getAttacherVehicle == nil or self:getAttacherVehicle() == nil then
		v97_ = superFunc(self)
	else
		v97_ = false
	end
	return v97_
end

-- Local values: currentDischargeNode, object, targetFillUnitIndex
function ConveyorBelt.getHasConveyorBeltLoop(rootVehicle, vehicle, fillUnitIndex)
	if vehicle.getCurrentDischargeNode ~= nil then
		local v101_ = vehicle:getCurrentDischargeNode()
		if v101_.fillUnitIndex == fillUnitIndex then
			local v102_ = v101_.dischargeHitObject
			local v103_ = v101_.dischargeHitObjectUnitIndex
			if v102_ ~= nil and (v102_.spec_conveyorBelt ~= nil and v103_ ~= nil) then
				return v102_ == rootVehicle and true or ConveyorBelt.getHasConveyorBeltLoop(rootVehicle, v102_, v103_)
			end
		end
	end
	return false
end

-- Local values: currentDischargeNode, object, targetFillUnitIndex, conversion
function ConveyorBelt:getFillUnitAllowsFillType(superFunc, fillUnitIndex, fillType)
	if not superFunc(self, fillUnitIndex, fillType) then
		return false
	end
	if not ConveyorBelt.getHasConveyorBeltLoop(self, self, fillUnitIndex) and self.getCurrentDischargeNode ~= nil then
		local v108_ = self:getCurrentDischargeNode()
		if v108_.fillUnitIndex == fillUnitIndex then
			local v109_ = v108_.dischargeHitObject
			local v110_ = v108_.dischargeHitObjectUnitIndex
			if v109_ ~= nil and (v109_.getFillUnitAllowsFillType ~= nil and v110_ ~= nil) then
				if v108_.fillTypeConverter ~= nil then
					local v111_ = v108_.fillTypeConverter[fillType]
					if v111_ ~= nil and v109_:getFillUnitAllowsFillType(v110_, v111_.targetFillTypeIndex) then
						return true
					end
				end
				return v109_:getFillUnitAllowsFillType(v110_, fillType)
			end
		end
	end
	return true
end

-- Local values: freeCapacity, currentDischargeNode, object, targetFillUnitIndex
function ConveyorBelt:getFillUnitFreeCapacity(superFunc, fillUnitIndex, fillTypeIndex, farmId)
	local v117_ = superFunc(self, fillUnitIndex, fillTypeIndex, farmId)
	if not ConveyorBelt.getHasConveyorBeltLoop(self, self, fillUnitIndex) and self.getCurrentDischargeNode ~= nil then
		local v118_ = self:getCurrentDischargeNode()
		if v118_.fillUnitIndex == fillUnitIndex then
			local v119_ = v118_.dischargeHitObject
			local v120_ = v118_.dischargeHitObjectUnitIndex
			if v119_ ~= nil and (v119_.getFillUnitFreeCapacity ~= nil and v120_ ~= nil) then
				return v117_ + v119_:getFillUnitFreeCapacity(v120_, fillTypeIndex, farmId)
			end
		end
	end
	return v117_
end

-- Local values: spec, fillLevel, isFilling, isScrolling, _, effect
function ConveyorBelt:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillType, toolType, fillPositionData, appliedDelta)
	local v125_ = self.spec_conveyorBelt
	if v125_.fillUnitIndex == fillUnitIndex then
		local v126_ = self:getFillUnitFillLevel(fillUnitIndex)
		if self.isServer then
			local v127_ = false
			local v128_
			if fillLevelDelta > 0 then
				v125_.morphStartPos = 0
				local v129_ = v125_.morphEndPos
				local v130_ = v126_ / self:getFillUnitCapacity(fillUnitIndex)
				v125_.morphEndPos = math.max(v129_, v130_)
				v125_.isEffectDirty = true
				v128_ = true
			else
				v128_ = false
			end
			if fillLevelDelta ~= 0 then
				v125_.scrollUpdateTime = 100
				v127_ = true
			end
			if v128_ ~= v125_.isFilling or v127_ ~= v125_.isScrolling then
				v125_.isFilling = v128_
				v125_.isScrolling = v127_
				self:raiseDirtyFlags(v125_.dirtyFlag)
			end
		end
		if v126_ == 0 then
			g_effectManager:stopEffects(v125_.effects)
			v125_.morphStartPos = 0
			v125_.morphEndPos = 0
			v125_.isEffectDirty = true
			return
		end
		g_effectManager:setEffectTypeInfo(v125_.effects, fillType)
		for _, v131_ in pairs(v125_.effects) do
			g_effectManager:startEffect(v131_, true)
		end
	end
end

-- Local values: spec, offset, state, updateDelay, _, entry, effectState, _, effect
function ConveyorBelt:onMovingToolChanged(movingTool, speed, dt)
	local v134_ = self.spec_conveyorBelt
	if v134_.offsets ~= nil and v134_.movingToolToOffset ~= nil then
		local v135_ = v134_.movingToolToOffset[movingTool]
		if v135_ ~= nil then
			local v136_ = Cylindered.getMovingToolState(self, movingTool)
			if v136_ ~= v135_.lastState then
				local v137_ = false
				for _, v138_ in pairs(v135_.effects) do
					local v139_
					if v138_.inverted then
						v139_ = 1 - v136_
					else
						v139_ = v136_
					end
					v138_.effect:setOffset(MathUtil.lerp(v138_.minValue, v138_.maxValue, v139_))
					v134_.isEffectDirty = true
					v137_ = true
				end
				if v137_ then
					v134_.currentDelay = 0
					for _, v140_ in pairs(v134_.effects) do
						if v140_.planeFadeTime ~= nil then
							v134_.currentDelay = v134_.currentDelay + v140_.planeFadeTime - v140_.offset
						end
					end
				end
				v135_.lastState = v136_
			end
		end
	end
end

-- Local values: spec
function ConveyorBelt:updateDebugValues(values)
	local v143_ = self.spec_conveyorBelt
	local v144_ = {
		["name"] = "fillFactor",
		["value"] = self:getFillUnitFillLevelPercentage(v143_.fillUnitIndex)
	}
	table.insert(values, v144_)
	local v145_ = {
		["name"] = "visualFactor",
		["value"] = v143_.morphEndPos - v143_.morphStartPos
	}
	table.insert(values, v145_)
	local v146_ = {
		["name"] = "currentDelay",
		["value"] = v143_.currentDelay
	}
	table.insert(values, v146_)
	local v147_ = {
		["name"] = "offset",
		["value"] = v143_.offset
	}
	table.insert(values, v147_)
	local v148_ = {
		["name"] = "morphStartPos",
		["value"] = v143_.morphStartPos
	}
	table.insert(values, v148_)
	local v149_ = {
		["name"] = "morphEndPos",
		["value"] = v143_.morphEndPos
	}
	table.insert(values, v149_)
end
