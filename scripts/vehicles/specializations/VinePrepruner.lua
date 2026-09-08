VinePrepruner = {}
VinePrepruner.PRUNER_NODE_XML_KEY = "vehicle.vinePrepruner.prunerNode(?)"
function VinePrepruner.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("VinePrepruner")
	v1_:register(XMLValueType.STRING, "vehicle.vinePrepruner#fruitType", "Fruit type")
	local v2_ = VinePrepruner.PRUNER_NODE_XML_KEY
	v1_:register(XMLValueType.NODE_INDEX, v2_ .. "#node", "Pruner node that adjusts translation depending on raycast distance")
	v1_:register(XMLValueType.FLOAT, v2_ .. "#offset", "Offset from raycast node to center of pruning unit", 0.5)
	v1_:register(XMLValueType.INT, v2_ .. "#axis", "Move axis", 1)
	v1_:register(XMLValueType.INT, v2_ .. "#direction", "Translation direction", 1)
	v1_:register(XMLValueType.FLOAT, v2_ .. "#transMin", "Min. translation", 0)
	v1_:register(XMLValueType.FLOAT, v2_ .. "#transMax", "Max. translation", 1)
	v1_:register(XMLValueType.FLOAT, v2_ .. "#transSpeed", "Translation speed (m/sec)", 0.5)
	v1_:register(XMLValueType.INT, v2_ .. "#numBits", "Number of bits to sync state in multiplayer", 8)
	v1_:register(XMLValueType.STRING, "vehicle.vinePrepruner.poleAnimation#name", "Name of pole animation (will be triggered as soon as pole has been detected)")
	v1_:register(XMLValueType.FLOAT, "vehicle.vinePrepruner.poleAnimation#speedScale", "Animation speed scale", 1)
	v1_:register(XMLValueType.FLOAT, "vehicle.vinePrepruner.poleAnimation#poleThreshold", "Defines when the pole is detected as percentage of segment length", 0.1)
	EffectManager.registerEffectXMLPaths(v1_, "vehicle.vinePrepruner.effect")
	v1_:setXMLSpecializationType()
end

function VinePrepruner.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(VineDetector, specializations)
end

function VinePrepruner.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadPreprunerNodeFromXML", VinePrepruner.loadPreprunerNodeFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsPreprunerNodeActive", VinePrepruner.getIsPreprunerNodeActive)
end

function VinePrepruner.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", VinePrepruner.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanStartVineDetection", VinePrepruner.getCanStartVineDetection)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsValidVinePlaceable", VinePrepruner.getIsValidVinePlaceable)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "handleVinePlaceable", VinePrepruner.handleVinePlaceable)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIImplementUseVineSegment", VinePrepruner.getAIImplementUseVineSegment)
end

function VinePrepruner.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", VinePrepruner)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", VinePrepruner)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", VinePrepruner)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", VinePrepruner)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", VinePrepruner)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", VinePrepruner)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", VinePrepruner)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", VinePrepruner)
	SpecializationUtil.registerEventListener(vehicleType, "onAnimationPartChanged", VinePrepruner)
end

-- Local values: spec, fruitTypeName, fruitType
function VinePrepruner:onLoad(savegame)
	local v_u_8_ = self.spec_vinePrepruner
	local v9_ = self.xmlFile:getValue("vehicle.vinePrepruner#fruitType")
	local v10_ = g_fruitTypeManager:getFruitTypeByName(v9_)
	if v10_ == nil then
		v_u_8_.fruitTypeIndex = FruitType.GRAPE
	else
		v_u_8_.fruitTypeIndex = v10_.index
	end
	v_u_8_.prunerNodes = {}
	self.xmlFile:iterate("vehicle.vinePrepruner.prunerNode", function(_, p11_)
		-- upvalues: (copy) self, (copy) v_u_8_
		local v12_ = {}
		if self:loadPreprunerNodeFromXML(self.xmlFile, p11_, v12_) then
			local v13_ = v_u_8_.prunerNodes
			table.insert(v13_, v12_)
		end
	end)
	v_u_8_.poleAnimation = {}
	v_u_8_.poleAnimation.name = self.xmlFile:getValue("vehicle.vinePrepruner.poleAnimation#name")
	v_u_8_.poleAnimation.speedScale = self.xmlFile:getValue("vehicle.vinePrepruner.poleAnimation#speedScale", 1)
	v_u_8_.poleAnimation.poleThreshold = 1 - self.xmlFile:getValue("vehicle.vinePrepruner.poleAnimation#poleThreshold", 0.1)
	v_u_8_.lastWorkTime = -10000
	v_u_8_.effectState = false
	if self.isClient then
		v_u_8_.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.vinePrepruner.effect", self.components, self, self.i3dMappings)
	end
	v_u_8_.dirtyFlag = self:getNextDirtyFlag()
end

-- Local values: spec
function VinePrepruner:onDelete()
	local v15_ = self.spec_vinePrepruner
	g_effectManager:deleteEffects(v15_.effects)
end

function VinePrepruner:onReadStream(streamId, connection)
	VinePrepruner.readPrePrunerFromStream(self, streamId, true)
end

function VinePrepruner:onWriteStream(streamId, connection)
	VinePrepruner.writePrePrunerToStream(self, streamId)
end

function VinePrepruner:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		VinePrepruner.readPrePrunerFromStream(self, streamId)
	end
end

-- Local values: spec
function VinePrepruner:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v27_ = self.spec_vinePrepruner
		local v28_ = streamWriteBool
		local v29_ = v27_.dirtyFlag
		if v28_(streamId, bit32.band(dirtyMask, v29_) ~= 0) then
			VinePrepruner.writePrePrunerToStream(self, streamId)
		end
	end
end

-- Local values: spec, i, prunerNode, maxValue, rawValue, effectState
function VinePrepruner:readPrePrunerFromStream(streamId, forceState)
	local v33_ = self.spec_vinePrepruner
	for v34_ = 1, #v33_.prunerNodes do
		local v35_ = v33_.prunerNodes[v34_]
		local v36_ = 2 ^ v35_.numBits - 1
		v35_.transTarget = streamReadUIntN(streamId, v35_.numBits) / v36_ * (v35_.transMax - v35_.transMin) + v35_.transMin
		if forceState then
			v35_.curTrans[v35_.axis] = v35_.transTarget
			setTranslation(v35_.node, v35_.curTrans[1], v35_.curTrans[2], v35_.curTrans[3])
		end
	end
	local v37_ = streamReadBool(streamId)
	if v37_ ~= v33_.effectState then
		v33_.effectState = v37_
		if v37_ then
			g_effectManager:setEffectTypeInfo(v33_.effects, nil, v33_.fruitTypeIndex, nil)
			g_effectManager:startEffects(v33_.effects)
			return
		end
		g_effectManager:stopEffects(v33_.effects)
	end
end

-- Local values: spec, i, prunerNode, maxValue, state
function VinePrepruner:writePrePrunerToStream(streamId)
	local v40_ = self.spec_vinePrepruner
	for v41_ = 1, #v40_.prunerNodes do
		local v42_ = v40_.prunerNodes[v41_]
		local v43_ = 2 ^ v42_.numBits - 1
		local v44_ = (v42_.transTarget - v42_.transMin) / (v42_.transMax - v42_.transMin)
		streamWriteUIntN(streamId, v44_ * v43_, v42_.numBits)
	end
	streamWriteBool(streamId, v40_.effectState)
end

-- Local values: spec, i, prunerNode, curTrans, moveDirection, func, effectState
function VinePrepruner:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v47_ = self.spec_vinePrepruner
	for v48_ = 1, #v47_.prunerNodes do
		local v49_ = v47_.prunerNodes[v48_]
		if self:getIsPreprunerNodeActive(v49_) then
			local v50_ = v49_.curTrans[v49_.axis]
			if v49_.transTarget ~= v50_ then
				local v51_ = v49_.transTarget - v50_
				local v52_ = math.sign(v51_)
				local v53_ = v52_ >= 0 and math.min or math.max
				v49_.curTrans[v49_.axis] = v53_(v50_ + v49_.transSpeed * dt * v52_, v49_.transTarget)
				setTranslation(v49_.node, v49_.curTrans[1], v49_.curTrans[2], v49_.curTrans[3])
			end
		end
	end
	if self.isServer then
		local v54_ = v47_.lastWorkTime + 1000 > g_time
		if v54_ ~= v47_.effectState then
			v47_.effectState = v54_
			if self.isClient then
				if v54_ then
					g_effectManager:setEffectTypeInfo(v47_.effects, nil, v47_.fruitTypeIndex, nil)
					g_effectManager:startEffects(v47_.effects)
				else
					g_effectManager:stopEffects(v47_.effects)
				end
			end
			self:raiseDirtyFlags(v47_.dirtyFlag)
		end
	end
end

function VinePrepruner:onTurnedOff()
	self:cancelVineDetection()
end

-- Local values: spec, i, prunerNode
function VinePrepruner:onAnimationPartChanged(node)
	local v58_ = self.spec_vinePrepruner
	for v59_ = 1, #v58_.prunerNodes do
		local v60_ = v58_.prunerNodes[v59_]
		if v60_.node == node then
			local v61_ = v60_.curTrans
			local v62_ = v60_.curTrans
			local v63_ = v60_.curTrans
			local v64_, v65_, v66_ = getTranslation(v60_.node)
			v61_[1] = v64_
			v62_[2] = v65_
			v63_[3] = v66_
		end
	end
end

function VinePrepruner:loadPreprunerNodeFromXML(xmlFile, key, prunerNode)
	prunerNode.node = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	if prunerNode.node == nil then
		return false
	end
	prunerNode.offset = self.xmlFile:getValue(key .. "#offset", 0.5)
	prunerNode.axis = self.xmlFile:getValue(key .. "#axis", 1)
	prunerNode.direction = self.xmlFile:getValue(key .. "#direction", 1)
	prunerNode.transMin = self.xmlFile:getValue(key .. "#transMin", 0)
	prunerNode.transMax = self.xmlFile:getValue(key .. "#transMax", 1)
	prunerNode.transSpeed = self.xmlFile:getValue(key .. "#transSpeed", 0.5) / 1000
	prunerNode.curTrans = { getTranslation(prunerNode.node) }
	prunerNode.transTarget = prunerNode.curTrans[prunerNode.axis]
	prunerNode.numBits = self.xmlFile:getValue(key .. "#numBits", 8)
	return true
end

function VinePrepruner:getIsPreprunerNodeActive(prunerNode)
	return true
end

-- Local values: isTurnedOn
function VinePrepruner:getCanStartVineDetection(superFunc)
	if superFunc(self) then
		if self:getIsTurnedOn() then
			return self.movingDirection ~= 0
		else
			return false
		end
	else
		return false
	end
end

-- Local values: spec
function VinePrepruner:getIsValidVinePlaceable(superFunc, placeable)
	if not superFunc(self, placeable) then
		return false
	end
	local v75_ = self.spec_vinePrepruner
	return placeable:getVineFruitType() == v75_.fruitTypeIndex
end

-- Local values: spec, startPosX, startPosY, startPosZ, currentPosX, currentPosY, currentPosZ, area, _, _, localStartZ, _, _, localCurrentZ, direction, posPercentage, i, prunerNode
function VinePrepruner:handleVinePlaceable(superFunc, node, placeable, x, y, z, distance)
	if not superFunc(self, node, placeable, x, y, z, distance) then
		return false
	end
	if placeable == nil then
		return false
	end
	local v84_ = self.spec_vinePrepruner
	local v85_, v86_, v87_ = self:getFirstVineHitPosition()
	local v88_, v89_, v90_ = self:getCurrentVineHitPosition()
	if placeable:prepareVine(node, v85_, v86_, v87_, v88_, v89_, v90_) > 0 then
		v84_.lastWorkTime = g_time
	end
	if v84_.poleAnimation.name ~= nil then
		local _, _, v91_ = worldToLocal(node, v85_, v86_, v87_)
		local _, _, v92_ = worldToLocal(node, v88_, v89_, v90_)
		local v93_ = v92_ - v91_
		local v94_ = math.sign(v93_) >= 0 and 1 or -1
		local v95_ = v92_ / placeable:getPanelLength()
		if v94_ < 0 then
			v95_ = 1 - v95_
		end
		if not self:getIsAnimationPlaying(v84_.poleAnimation.name) then
			if v84_.poleAnimation.poleThreshold < v95_ then
				if self:getAnimationTime(v84_.poleAnimation.name) < 0.5 then
					self:playAnimation(v84_.poleAnimation.name, v84_.poleAnimation.speedScale)
				end
			elseif self:getAnimationTime(v84_.poleAnimation.name) > 0.5 then
				self:playAnimation(v84_.poleAnimation.name, -v84_.poleAnimation.speedScale)
			end
		end
	end
	for v96_ = 1, #v84_.prunerNodes do
		local v97_ = v84_.prunerNodes[v96_]
		local v98_ = (distance - v97_.offset) * v97_.direction
		local v99_ = v97_.transMin
		local v100_ = v97_.transMax
		v97_.transTarget = math.clamp(v98_, v99_, v100_)
		self:raiseDirtyFlags(v84_.dirtyFlag)
	end
	return true
end

function VinePrepruner:getAIImplementUseVineSegment(superFunc, placeable, segment, segmentSide)
	if segmentSide >= 0 then
		return placeable:getHasSegmentTargetGrowthState(segment, self.spec_vinePrepruner.fruitTypeIndex, false, true)
	else
		return false
	end
end

function VinePrepruner:doCheckSpeedLimit(superFunc)
	return superFunc(self) or self:getIsTurnedOn()
end
function VinePrepruner.getDefaultSpeedLimit()
	return 5
end
