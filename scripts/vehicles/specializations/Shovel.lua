Shovel = {}
Shovel.SHOVEL_NODE_XML_KEY = "vehicle.shovel.shovelNode(?)"

function Shovel.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(FillUnit, specializations) and (SpecializationUtil.hasSpecialization(FillVolume, specializations) and SpecializationUtil.hasSpecialization(Dischargeable, specializations))
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(BunkerSiloInteractor, specializations)
	end
	return v2_
end
function Shovel.initSpecialization()
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("Shovel")
	v3_:register(XMLValueType.BOOL, "vehicle.shovel#ignoreFillUnitFillType", "Ignore fill unit fill type", false)
	v3_:register(XMLValueType.BOOL, "vehicle.shovel#useSpeedLimit", "Use speed limit while shovel is turned on", false)
	v3_:register(XMLValueType.NODE_INDEX, Shovel.SHOVEL_NODE_XML_KEY .. "#node", "Shovel node")
	v3_:register(XMLValueType.INT, Shovel.SHOVEL_NODE_XML_KEY .. "#fillUnitIndex", "Fill unit index", 1)
	v3_:register(XMLValueType.INT, Shovel.SHOVEL_NODE_XML_KEY .. "#loadInfoIndex", "Load info index", 1)
	v3_:register(XMLValueType.FLOAT, Shovel.SHOVEL_NODE_XML_KEY .. "#width", "Shovel node width", 1)
	v3_:register(XMLValueType.FLOAT, Shovel.SHOVEL_NODE_XML_KEY .. "#length", "Shovel node length", 0.5)
	v3_:register(XMLValueType.FLOAT, Shovel.SHOVEL_NODE_XML_KEY .. "#yOffset", "Shovel node y offset", 0)
	v3_:register(XMLValueType.FLOAT, Shovel.SHOVEL_NODE_XML_KEY .. "#zOffset", "Shovel node z offset", 0)
	v3_:register(XMLValueType.BOOL, Shovel.SHOVEL_NODE_XML_KEY .. "#needsMovement", "Needs movement", true)
	v3_:register(XMLValueType.FLOAT, Shovel.SHOVEL_NODE_XML_KEY .. "#fillLitersPerSecond", "Fill liters per second", "inf.")
	v3_:register(XMLValueType.ANGLE, Shovel.SHOVEL_NODE_XML_KEY .. "#maxPickupAngle", "Max. pickup angle")
	v3_:register(XMLValueType.BOOL, Shovel.SHOVEL_NODE_XML_KEY .. "#needsAttacherVehicle", "Needs attacher vehicle connected", true)
	v3_:register(XMLValueType.BOOL, Shovel.SHOVEL_NODE_XML_KEY .. "#resetFillLevel", "Reset fill level to zero while the shovel node is not active", false)
	v3_:register(XMLValueType.BOOL, Shovel.SHOVEL_NODE_XML_KEY .. "#ignoreFillLevel", "Ignore fill level of the fill unit while filling", false)
	v3_:register(XMLValueType.BOOL, Shovel.SHOVEL_NODE_XML_KEY .. "#ignoreFarmlandState", "Ignore farmland state for pickup", false)
	v3_:register(XMLValueType.BOOL, Shovel.SHOVEL_NODE_XML_KEY .. ".smoothing#allowed", "Leveler smoothes while driving backward", false)
	v3_:register(XMLValueType.FLOAT, Shovel.SHOVEL_NODE_XML_KEY .. ".smoothing#radius", "Smooth ground radius", 0.5)
	v3_:register(XMLValueType.FLOAT, Shovel.SHOVEL_NODE_XML_KEY .. ".smoothing#overlap", "Radius overlap", 1.7)
	v3_:register(XMLValueType.INT, "vehicle.shovel.dischargeInfo#dischargeNodeIndex", "Discharge node index", 1)
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.shovel.dischargeInfo#node", "Discharge info node")
	v3_:register(XMLValueType.ANGLE, "vehicle.shovel.dischargeInfo#minSpeedAngle", "Discharge info min. speed angle")
	v3_:register(XMLValueType.ANGLE, "vehicle.shovel.dischargeInfo#maxSpeedAngle", "Discharge info max. speed angle")
	EffectManager.registerEffectXMLPaths(v3_, "vehicle.shovel.fillEffect")
	v3_:setXMLSpecializationType()
end

function Shovel.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadShovelNode", Shovel.loadShovelNode)
	SpecializationUtil.registerFunction(vehicleType, "getShovelNodeIsActive", Shovel.getShovelNodeIsActive)
	SpecializationUtil.registerFunction(vehicleType, "getCanShovelAtPosition", Shovel.getCanShovelAtPosition)
	SpecializationUtil.registerFunction(vehicleType, "getShovelTipFactor", Shovel.getShovelTipFactor)
	SpecializationUtil.registerFunction(vehicleType, "getIsShovelEffectState", Shovel.getIsShovelEffectState)
end

function Shovel.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDischargeNodeActive", Shovel.getIsDischargeNodeActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDischargeNodeEmptyFactor", Shovel.getDischargeNodeEmptyFactor)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "handleDischarge", Shovel.handleDischarge)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "handleDischargeOnEmpty", Shovel.handleDischargeOnEmpty)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "handleDischargeRaycast", Shovel.handleDischargeRaycast)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleDischargeToObject", Shovel.getCanToggleDischargeToObject)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleDischargeToGround", Shovel.getCanToggleDischargeToGround)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Shovel.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Shovel.doCheckSpeedLimit)
end

function Shovel.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Shovel)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Shovel)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Shovel)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Shovel)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Shovel)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Shovel)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Shovel)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", Shovel)
end

-- Local values: spec, i, key, shovelNode, minSpeedAngle, maxSpeedAngle
function Shovel:onLoad(savegame)
	local v8_ = self.spec_shovel
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.shovel#pickUpNode", "vehicle.shovel.shovelNode#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.shovel#pickUpWidth", "vehicle.shovel.shovelNode#width")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.shovel#pickUpLength", "vehicle.shovel.shovelNode#length")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.shovel#pickUpYOffset")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.shovel#pickUpRequiresMovement", "vehicle.shovel.shovelNode#needsMovement")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.shovel#pickUpNeedsToBeTurnedOn", "vehicle.shovel.shovelNode#needsActivation")
	v8_.ignoreFillUnitFillType = self.xmlFile:getValue("vehicle.shovel#ignoreFillUnitFillType", false)
	v8_.useSpeedLimit = self.xmlFile:getValue("vehicle.shovel#useSpeedLimit", false)
	v8_.shovelNodes = {}
	local v9_ = 0
	while true do
		local v10_ = string.format("vehicle.shovel.shovelNode(%d)", v9_)
		if not self.xmlFile:hasProperty(v10_) then
			break
		end
		local v11_ = {}
		if self:loadShovelNode(self.xmlFile, v10_, v11_) then
			local v12_ = v8_.shovelNodes
			table.insert(v12_, v11_)
		end
		v9_ = v9_ + 1
	end
	v8_.shovelDischargeInfo = {}
	v8_.shovelDischargeInfo.dischargeNodeIndex = self.xmlFile:getValue("vehicle.shovel.dischargeInfo#dischargeNodeIndex", 1)
	v8_.shovelDischargeInfo.node = self.xmlFile:getValue("vehicle.shovel.dischargeInfo#node", nil, self.components, self.i3dMappings)
	if v8_.shovelDischargeInfo.node ~= nil then
		local v13_ = self.xmlFile:getValue("vehicle.shovel.dischargeInfo#minSpeedAngle")
		local v14_ = self.xmlFile:getValue("vehicle.shovel.dischargeInfo#maxSpeedAngle")
		if v13_ == nil or v14_ == nil then
			Logging.xmlWarning(self.xmlFile, "Missing \'minSpeedAngle\' or \'maxSpeedAngle\' for dischargeNode \'vehicle.shovel.dischargeInfo\'")
			return false
		end
		v8_.shovelDischargeInfo.minSpeedAngle = v13_
		v8_.shovelDischargeInfo.maxSpeedAngle = v14_
	end
	if self.isClient then
		v8_.fillEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.shovel.fillEffect", self.components, self, self.i3dMappings)
		v8_.fillEffectTime = 0
	end
	v8_.effectDirtyFlag = self:getNextDirtyFlag()
	v8_.loadingFillType = FillType.UNKNOWN
	v8_.lastValidFillType = FillType.UNKNOWN
	v8_.smoothAccumulation = 0
	if #v8_.shovelNodes == 0 then
		SpecializationUtil.removeEventListener(self, "onReadStream", Shovel)
		SpecializationUtil.removeEventListener(self, "onWriteStream", Shovel)
		SpecializationUtil.removeEventListener(self, "onReadUpdateStream", Shovel)
		SpecializationUtil.removeEventListener(self, "onWriteUpdateStream", Shovel)
		SpecializationUtil.removeEventListener(self, "onUpdateTick", Shovel)
		SpecializationUtil.removeEventListener(self, "onFillUnitFillLevelChanged", Shovel)
	end
	return true
end

-- Local values: spec
function Shovel:onDelete()
	local v16_ = self.spec_shovel
	g_effectManager:deleteEffects(v16_.fillEffects)
end

-- Local values: spec
function Shovel:onReadStream(streamId, connection)
	self.spec_shovel.loadingFillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
end

-- Local values: spec
function Shovel:onWriteStream(streamId, connection)
	local v21_ = self.spec_shovel
	streamWriteUIntN(streamId, v21_.loadingFillType, FillTypeManager.SEND_NUM_BITS)
end

-- Local values: spec
function Shovel:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local v25_ = self.spec_shovel
		if streamReadBool(streamId) then
			v25_.loadingFillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
		end
	end
end

-- Local values: spec
function Shovel:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v30_ = self.spec_shovel
		local v31_ = streamWriteBool
		local v32_ = v30_.effectDirtyFlag
		if v31_(streamId, bit32.band(dirtyMask, v32_) ~= 0) then
			streamWriteUIntN(streamId, v30_.loadingFillType, FillTypeManager.SEND_NUM_BITS)
		end
	end
end

-- Local values: spec, validPickupFillType, _, shovelNode, fillLevel, capacity, freeCapacity, pickupFillType, minValidLiter, sx, sy, sz, ex, ey, ez, innerRadius, radius, fillDelta, lineOffset, loadInfo, fillLevel, _, dy, _, angle, smoothAmount, rounded
function Shovel:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v35_ = self.spec_shovel
	if self.isServer then
		local v36_ = FillType.UNKNOWN
		for _, v37_ in pairs(v35_.shovelNodes) do
			local v38_
			if self:getShovelNodeIsActive(v37_) then
				local v39_ = self:getFillUnitFillLevel(v37_.fillUnitIndex)
				local v40_ = self:getFillUnitCapacity(v37_.fillUnitIndex)
				local v41_
				if v37_.ignoreFillLevel then
					v41_ = math.huge
				else
					local v42_ = v40_ - v39_
					local v43_ = v37_.fillUnitIndex
					v41_ = math.min(v42_, self:getFillUnitFreeCapacity(v43_))
				end
				local v44_ = v37_.fillLitersPerSecond * dt
				local v45_ = math.min(v41_, v44_)
				if v45_ > 0 then
					v38_ = self:getFillUnitFillType(v37_.fillUnitIndex)
					if v39_ / v40_ < self:getFillTypeChangeThreshold() then
						v38_ = FillType.UNKNOWN
					end
					local v46_ = g_densityMapHeightManager:getMinValidLiterValue(v38_) or 0
					local v47_, v48_, v49_ = localToWorld(v37_.node, -v37_.width * 0.5, v37_.yOffset, v37_.zOffset)
					local v50_, v51_, v52_ = localToWorld(v37_.node, v37_.width * 0.5, v37_.yOffset, v37_.zOffset)
					local v53_ = v37_.length
					if self:getCanShovelAtPosition(v37_) then
						if v38_ == FillType.UNKNOWN or v35_.ignoreFillUnitFillType then
							v38_ = DensityMapHeightUtil.getFillTypeAtLine(v47_, v48_, v49_, v50_, v51_, v52_, v53_)
						end
						if v38_ == FillType.UNKNOWN or not (self:getFillUnitSupportsFillType(v37_.fillUnitIndex, v38_) and self:getFillUnitAllowsFillType(v37_.fillUnitIndex, v38_)) then
							v38_ = v36_
						else
							local v54_, v55_ = DensityMapHeightUtil.tipToGroundAroundLine(self, -v45_ - v46_, v38_, v47_, v48_, v49_, v50_, v51_, v52_, v53_, nil, v37_.lineOffset, true, nil)
							v37_.lineOffset = v55_
							if not v37_.ignoreFillLevel and v45_ < -v54_ then
								self:setFillUnitCapacity(v37_.fillUnitIndex, v39_ - v54_)
								v37_.capacityChanged = true
							end
							if v54_ < 0 then
								local v56_ = self:getFillVolumeLoadInfo(v37_.loadInfoIndex)
								self:addFillUnitFillLevel(self:getOwnerFarmId(), v37_.fillUnitIndex, -v54_, v38_, ToolType.UNDEFINED, v56_)
								self:notifiyBunkerSilo(v54_, v38_, (v47_ + v50_) * 0.5, (v48_ + v51_) * 0.5, (v49_ + v52_) * 0.5)
							else
								v38_ = v36_
							end
						end
					else
						v38_ = v36_
					end
				else
					v38_ = v36_
				end
			elseif v37_.resetFillLevel then
				local v57_ = self:getFillUnitFillLevel(v37_.fillUnitIndex)
				if v57_ > 0 then
					self:addFillUnitFillLevel(self:getOwnerFarmId(), v37_.fillUnitIndex, -v57_, self:getFillUnitFillType(v37_.fillUnitIndex), ToolType.UNDEFINED)
					v38_ = v36_
				else
					v38_ = v36_
				end
			else
				v38_ = v36_
			end
			if v37_.allowsSmoothing then
				local _, v58_, _ = localDirectionToWorld(v37_.node, 0, 0, 1)
				if math.acos(v58_) > v37_.maxPickupAngle then
					local v59_ = 0
					if self.lastSpeedReal > 0.0002 then
						local v60_ = v35_.smoothAccumulation
						local v61_ = self.lastMovedDistance * 0.5
						local v62_ = 0.0003 * dt
						v59_ = v60_ + math.max(v61_, v62_)
						v35_.smoothAccumulation = v59_ - DensityMapHeightUtil.getRoundedHeightValue(v59_)
					else
						v35_.smoothAccumulation = 0
					end
					if v59_ > 0 then
						DensityMapHeightUtil.smoothAroundLine(v37_.node, v37_.width, v37_.smoothGroundRadius, v37_.smoothOverlap, v59_, true)
						v36_ = v38_
					else
						v36_ = v38_
					end
				else
					v36_ = v38_
				end
			else
				v36_ = v38_
			end
		end
		if v36_ == FillType.UNKNOWN then
			v35_.fillEffectTime = v35_.fillEffectTime - dt
			if v35_.fillEffectTime > 0 then
				v36_ = v35_.loadingFillType
			end
		else
			v35_.fillEffectTime = 500
		end
		if v35_.loadingFillType ~= v36_ then
			v35_.loadingFillType = v36_
			self:raiseDirtyFlags(v35_.effectDirtyFlag)
		end
	end
	if self.isClient then
		if v35_.loadingFillType ~= FillType.UNKNOWN then
			g_effectManager:setEffectTypeInfo(v35_.fillEffects, v35_.loadingFillType)
			g_effectManager:startEffects(v35_.fillEffects)
			return
		end
		g_effectManager:stopEffects(v35_.fillEffects)
	end
end

-- Local values: spec, _, shovelNode, fillUnit
function Shovel:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData, appliedDelta)
	if self.isServer then
		local v65_ = self.spec_shovel
		for _, v66_ in pairs(v65_.shovelNodes) do
			if v66_.fillUnitIndex == fillUnitIndex and v66_.capacityChanged then
				local v67_ = self:getFillUnitByIndex(fillUnitIndex)
				if v67_.fillLevel <= v67_.defaultCapacity then
					self:setFillUnitCapacity(fillUnitIndex, v67_.defaultCapacity)
					v66_.capacityChanged = false
				end
			end
		end
	end
end

function Shovel:loadShovelNode(xmlFile, key, shovelNode)
	shovelNode.node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	if shovelNode.node == nil then
		Logging.xmlWarning(self.xmlFile, "Missing \'node\' for shovelNode \'%s\'!", key)
		return false
	end
	shovelNode.fillUnitIndex = xmlFile:getValue(key .. "#fillUnitIndex", 1)
	shovelNode.loadInfoIndex = xmlFile:getValue(key .. "#loadInfoIndex", 1)
	shovelNode.width = xmlFile:getValue(key .. "#width", 1)
	shovelNode.length = xmlFile:getValue(key .. "#length", 0.5)
	shovelNode.yOffset = xmlFile:getValue(key .. "#yOffset", 0)
	shovelNode.zOffset = xmlFile:getValue(key .. "#zOffset", 0)
	shovelNode.needsMovement = xmlFile:getValue(key .. "#needsMovement", true)
	shovelNode.lastPosition = { 0, 0, 0 }
	shovelNode.fillLitersPerSecond = xmlFile:getValue(key .. "#fillLitersPerSecond", math.huge) / 1000
	shovelNode.maxPickupAngle = xmlFile:getValue(key .. "#maxPickupAngle")
	shovelNode.needsAttacherVehicle = xmlFile:getValue(key .. "#needsAttacherVehicle", true)
	shovelNode.resetFillLevel = xmlFile:getValue(key .. "#resetFillLevel", false)
	shovelNode.ignoreFillLevel = xmlFile:getValue(key .. "#ignoreFillLevel", false)
	shovelNode.ignoreFarmlandState = xmlFile:getValue(key .. "#ignoreFarmlandState", false)
	shovelNode.allowsSmoothing = xmlFile:getValue(key .. ".smoothing#allowed", false)
	shovelNode.smoothGroundRadius = xmlFile:getValue(key .. ".smoothing#radius", 0.5)
	shovelNode.smoothOverlap = xmlFile:getValue(key .. ".smoothing#overlap", 1.7)
	return true
end

-- Local values: isActive, x, y, z, _, _, dz, _, dy, _, angle
function Shovel:getShovelNodeIsActive(shovelNode)
	local v74_ = true
	if shovelNode.needsMovement then
		local v75_, v76_, v77_ = getWorldTranslation(shovelNode.node)
		local _, _, v78_ = worldToLocal(shovelNode.node, shovelNode.lastPosition[1], shovelNode.lastPosition[2], shovelNode.lastPosition[3])
		if v74_ then
			v74_ = v78_ < 0
		end
		shovelNode.lastPosition[1] = v75_
		shovelNode.lastPosition[2] = v76_
		shovelNode.lastPosition[3] = v77_
	end
	if shovelNode.maxPickupAngle ~= nil then
		local _, v79_, _ = localDirectionToWorld(shovelNode.node, 0, 0, 1)
		if math.acos(v79_) > shovelNode.maxPickupAngle then
			return false
		end
	end
	if shovelNode.needsAttacherVehicle and (self.getAttacherVehicle ~= nil and self:getAttacherVehicle() == nil) then
		return false
	else
		return v74_
	end
end

-- Local values: spec, info
function Shovel:getIsDischargeNodeActive(superFunc, dischargeNode)
	local v83_ = self.spec_shovel.shovelDischargeInfo
	if v83_.node == nil or (v83_.dischargeNodeIndex ~= dischargeNode.index or self:getShovelTipFactor() ~= 0) then
		return superFunc(self, dischargeNode)
	else
		return false
	end
end

-- Local values: spec, parentFactor, info
function Shovel:getDischargeNodeEmptyFactor(superFunc, dischargeNode)
	local v87_ = self.spec_shovel
	local v88_ = superFunc(self, dischargeNode)
	local v89_ = v87_.shovelDischargeInfo
	if v89_.node == nil or v89_.dischargeNodeIndex ~= dischargeNode.index then
		return v88_
	else
		return v88_ * self:getShovelTipFactor()
	end
end

-- Local values: spec
function Shovel:handleDischarge(superFunc, dischargeNode, dischargedLiters, minDropReached, hasMinDropFillLevel)
	local v96_ = self.spec_shovel
	if dischargeNode.index ~= v96_.shovelDischargeInfo.dischargeNodeIndex or v96_.shovelDischargeInfo.node == nil then
		superFunc(self, dischargeNode, dischargedLiters, minDropReached, hasMinDropFillLevel)
	end
end

function Shovel:handleDischargeOnEmpty(superFunc, dischargedLiters, minDropReached, hasMinDropFillLevel)
	if self.spec_shovel.shovelDischargeInfo.node == nil then
		superFunc(self, dischargedLiters, minDropReached, hasMinDropFillLevel)
	end
end

-- Local values: spec, fillType, allowFillType, fillLevel, warning
function Shovel:handleDischargeRaycast(superFunc, dischargeNode, hitObject, hitShape, hitDistance, hitFillUnitIndex, hitTerrain)
	local v110_ = self.spec_shovel
	if v110_.shovelDischargeInfo.node == nil or v110_.shovelDischargeInfo.dischargeNodeIndex ~= dischargeNode.index then
		superFunc(self, dischargeNode, hitObject, hitShape, hitDistance, hitFillUnitIndex, hitTerrain)
	elseif hitObject == nil then
		if self:getFillUnitFillLevel(dischargeNode.fillUnitIndex) > 0 and (self:getShovelTipFactor() > 0 and self:getCanDischargeToGround(dischargeNode)) then
			if self:getCanDischargeToLand(dischargeNode) then
				if self:getCanDischargeAtPosition(dischargeNode) then
					self:setDischargeState(Dischargeable.DISCHARGE_STATE_GROUND, true)
					return
				end
				if self.isActiveForInputIgnoreSelectionIgnoreAI then
					local v111_ = self:getDischargeNotAllowedWarning(dischargeNode)
					g_currentMission:showBlinkingWarning(v111_, 500)
					return
				end
			elseif self.isActiveForInputIgnoreSelectionIgnoreAI then
				g_currentMission:showBlinkingWarning(g_i18n:getText("warning_youDontHaveAccessToThisLand"), 500)
				return
			end
		end
	else
		local v112_ = self:getDischargeFillType(dischargeNode)
		if hitObject:getFillUnitAllowsFillType(hitFillUnitIndex, v112_) and hitObject:getFillUnitFreeCapacity(hitFillUnitIndex, v112_, self:getOwnerFarmId()) > 0 then
			self:setDischargeState(Dischargeable.DISCHARGE_STATE_OBJECT, true)
			return
		end
		if self:getDischargeState() == Dischargeable.DISCHARGE_STATE_OBJECT then
			self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF, true)
			return
		end
	end
end

function Shovel:getCanToggleDischargeToObject(superFunc)
	if self.spec_shovel.shovelDischargeInfo.node == nil then
		return superFunc(self)
	else
		return false
	end
end

function Shovel:getCanToggleDischargeToGround(superFunc)
	if self.spec_shovel.shovelDischargeInfo.node == nil then
		return superFunc(self)
	else
		return false
	end
end

-- Local values: spec, info, _, dy, _, angle
function Shovel:getShovelTipFactor()
	local v118_ = self.spec_shovel.shovelDischargeInfo
	if v118_.node ~= nil then
		local _, v119_, _ = localDirectionToWorld(v118_.node, 0, 0, 1)
		local v120_ = math.acos(v119_)
		if v118_.minSpeedAngle < v120_ then
			local v121_ = (v120_ - v118_.minSpeedAngle) / (v118_.maxSpeedAngle - v118_.minSpeedAngle)
			local v122_ = math.min(1, v121_)
			return math.max(0, v122_)
		end
	end
	return 0
end

-- Local values: spec
function Shovel:getIsShovelEffectState()
	local v124_ = self.spec_shovel
	return v124_.loadingFillType ~= FillType.UNKNOWN, v124_.loadingFillType
end

-- Local values: spec, multiplier
function Shovel:getWearMultiplier(superFunc)
	local v127_ = self.spec_shovel
	local v128_ = superFunc(self)
	if v127_.loadingFillType ~= FillType.UNKNOWN then
		v128_ = v128_ + self:getWorkWearMultiplier()
	end
	return v128_
end

function Shovel:doCheckSpeedLimit(superFunc)
	local v131_ = not superFunc(self) and self.spec_shovel.useSpeedLimit
	if v131_ then
		v131_ = self.getIsTurnedOn == nil and true or self:getIsTurnedOn()
	end
	return v131_
end

-- Local values: sx, _, sz, activeFarm, ex, _, ez, isStartOwned
function Shovel:getCanShovelAtPosition(shovelNode)
	if shovelNode == nil then
		return false
	elseif shovelNode.ignoreFarmlandState then
		return true
	else
		local v134_, _, v135_ = localToWorld(shovelNode.node, -shovelNode.width * 0.5, 0, 0)
		local v136_ = self:getActiveFarm()
		local v137_, _, v138_ = localToWorld(shovelNode.node, shovelNode.width * 0.5, 0, 0)
		if g_densityMapHeightManager:getIsInFreeAccessArea(v134_, v135_, v137_, v138_) then
			return true
		elseif g_currentMission.accessHandler:canFarmAccessLand(v136_, v134_, v135_) then
			return g_currentMission.accessHandler:canFarmAccessLand(v136_, v137_, v138_)
		else
			return false
		end
	end
end

-- Local values: spec, info, _, dy, _, angle, factor
function Shovel:updateDebugValues(values)
	local v141_ = self.spec_shovel.shovelDischargeInfo
	if v141_.node ~= nil then
		local _, v142_, _ = localDirectionToWorld(v141_.node, 0, 0, 1)
		local v143_ = math.acos(v142_)
		local v144_ = {
			["name"] = "angle",
			["value"] = math.deg(v143_)
		}
		table.insert(values, v144_)
		local v145_ = {
			["name"] = "minSpeedAngle"
		}
		local v146_ = v141_.minSpeedAngle
		v145_.value = math.deg(v146_)
		table.insert(values, v145_)
		local v147_ = {
			["name"] = "maxSpeedAngle"
		}
		local v148_ = v141_.maxSpeedAngle
		v147_.value = math.deg(v148_)
		table.insert(values, v147_)
		if v141_.minSpeedAngle < v143_ then
			local v149_ = (v143_ - v141_.minSpeedAngle) / (v141_.maxSpeedAngle - v141_.minSpeedAngle)
			local v150_ = math.min(1, v149_)
			local v151_ = {
				["name"] = "factor",
				["value"] = math.max(0, v150_)
			}
			table.insert(values, v151_)
			return
		end
		table.insert(values, {
			["name"] = "factor",
			["value"] = "Out of Range - 0"
		})
	end
end
