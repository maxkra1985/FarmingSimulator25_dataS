Leveler = {}
Leveler.LEVELER_NODE_XML_KEY = "vehicle.leveler.levelerNode(?)"
Leveler.LEVEL_NUM_BITS = 8
Leveler.LEVEL_MAX_VALUE = 2 ^ Leveler.LEVEL_NUM_BITS - 1
Leveler.COLLISION_MASK = CollisionFlag.STATIC_OBJECT + CollisionFlag.BUILDING

function Leveler.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(FillUnit, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(BunkerSiloInteractor, specializations)
	end
	return v2_
end
function Leveler.initSpecialization()
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("Leveler")
	local v4_ = Leveler.LEVELER_NODE_XML_KEY
	v3_:register(XMLValueType.NODE_INDEX, v4_ .. "#node", "Leveler node")
	v3_:register(XMLValueType.FLOAT, v4_ .. "#width", "Width")
	v3_:register(XMLValueType.FLOAT, v4_ .. "#zOffset", "Z axis offset", 0)
	v3_:register(XMLValueType.FLOAT, v4_ .. "#yOffset", "Y axis offset", 0)
	v3_:register(XMLValueType.FLOAT, v4_ .. "#minDropWidth", "Min. drop width", "half of width")
	v3_:register(XMLValueType.FLOAT, v4_ .. "#maxDropWidth", "Max. drop width", "width value")
	v3_:register(XMLValueType.FLOAT, v4_ .. "#minDropDirOffset", "Min. drop direction offset", 0.7)
	v3_:register(XMLValueType.FLOAT, v4_ .. "#maxDropDirOffset", "Max. drop direction offset", 0.7)
	v3_:register(XMLValueType.INT, v4_ .. "#numHeightLimitChecks", "Number of height limit checks", 6)
	v3_:register(XMLValueType.BOOL, v4_ .. "#alignToWorldY", "Defines if the leveler node is aligned to worlds Y axis", true)
	v3_:register(XMLValueType.BOOL, v4_ .. ".smoothing#allowed", "Leveler smoothes while driving backward", true)
	v3_:register(XMLValueType.FLOAT, v4_ .. ".smoothing#radius", "Smooth ground radius", 0.5)
	v3_:register(XMLValueType.FLOAT, v4_ .. ".smoothing#overlap", "Radius overlap", 1.7)
	v3_:register(XMLValueType.INT, v4_ .. ".smoothing#direction", "Smooth direction (if set to \'0\' it smooths in both directions)", -1)
	v3_:register(XMLValueType.INT, v4_ .. "#fillUnitIndex", "Fill unit index", "Value of vehicle.leveler#fillUnitIndex")
	v3_:register(XMLValueType.NODE_INDEX, v4_ .. ".occlusionAreas.occlusionArea(?)#startNode", "Start node")
	v3_:register(XMLValueType.NODE_INDEX, v4_ .. ".occlusionAreas.occlusionArea(?)#widthNode", "Width node")
	v3_:register(XMLValueType.NODE_INDEX, v4_ .. ".occlusionAreas.occlusionArea(?)#heightNode", "Height node")
	v3_:register(XMLValueType.INT, "vehicle.leveler.pickUpDirection", "Pick up direction", 1)
	v3_:register(XMLValueType.INT, "vehicle.leveler#fillUnitIndex", "Fill unit index")
	v3_:register(XMLValueType.FLOAT, "vehicle.leveler#maxFillLevelPerMS", "Max. fill level change rate as reference for effect and force", 20)
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.leveler.force#node", "Force node")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.leveler.force#directionNode", "Force direction node")
	v3_:register(XMLValueType.FLOAT, "vehicle.leveler.force#maxForce", "Max. force in kN", 0)
	v3_:register(XMLValueType.INT, "vehicle.leveler.force#direction", "Driving direction for applying force", 1)
	v3_:register(XMLValueType.BOOL, "vehicle.leveler#ignoreFarmlandState", "If set to true the farmland underneath the leveler does not need to be bought to actually work", false)
	EffectManager.registerEffectXMLPaths(v3_, "vehicle.leveler.effects")
	v3_:setXMLSpecializationType()
end

function Leveler.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getIsLevelerPickupNodeActive", Leveler.getIsLevelerPickupNodeActive)
	SpecializationUtil.registerFunction(vehicleType, "loadLevelerNodeFromXML", Leveler.loadLevelerNodeFromXML)
	SpecializationUtil.registerFunction(vehicleType, "onLevelerRaycastCallback", Leveler.onLevelerRaycastCallback)
end

function Leveler.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAttacherJointControlDampingAllowed", Leveler.getIsAttacherJointControlDampingAllowed)
end

function Leveler.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Leveler)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Leveler)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Leveler)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Leveler)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Leveler)
end

-- Local values: spec, i, key, levelerNode
function Leveler:onLoad(savegame)
	local v9_ = self.spec_leveler
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.leveler.levelerNode#index", "vehicle.leveler.levelerNode#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.levelerEffects", "vehicle.leveler.effects")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.leveler.levelerNode(0)#minDropHeight")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.leveler.levelerNode(0)#maxDropHeight")
	v9_.pickUpDirection = self.xmlFile:getValue("vehicle.leveler.pickUpDirection", 1)
	v9_.maxFillLevelPerMS = self.xmlFile:getValue("vehicle.leveler#maxFillLevelPerMS", 35)
	v9_.fillUnitIndex = self.xmlFile:getValue("vehicle.leveler#fillUnitIndex")
	v9_.nodes = {}
	local v10_ = 0
	while true do
		local v11_ = string.format("vehicle.leveler.levelerNode(%d)", v10_)
		if not self.xmlFile:hasProperty(v11_) then
			break
		end
		local v12_ = {}
		if self:loadLevelerNodeFromXML(v12_, self.xmlFile, v11_) then
			v12_.vehicle = self
			v12_.onLevelerRaycastCallback = self.onLevelerRaycastCallback
			local v13_ = v9_.nodes
			table.insert(v13_, v12_)
		end
		v10_ = v10_ + 1
	end
	v9_.litersToPickup = 0
	v9_.smoothAccumulation = 0
	v9_.lastFillLevelMoved = 0
	v9_.lastFillLevelMovedPct = 0
	v9_.lastFillLevelMovedTarget = 0
	v9_.lastFillLevelMovedBuffer = 0
	v9_.lastFillLevelMovedBufferTime = 300
	v9_.lastFillLevelMovedBufferTimer = 0
	v9_.forceNode = self.xmlFile:getValue("vehicle.leveler.force#node", nil, self.components, self.i3dMappings)
	v9_.forceDirNode = self.xmlFile:getValue("vehicle.leveler.force#directionNode", v9_.forceNode, self.components, self.i3dMappings)
	v9_.maxForce = self.xmlFile:getValue("vehicle.leveler.force#maxForce", 0)
	v9_.lastForce = 0
	v9_.forceDir = self.xmlFile:getValue("vehicle.leveler.force#direction", 1)
	v9_.ignoreFarmlandState = self.xmlFile:getValue("vehicle.leveler#ignoreFarmlandState", false)
	if self.isClient then
		v9_.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.leveler.effects", self.components, self, self.i3dMappings)
	end
	if #v9_.nodes == 0 then
		SpecializationUtil.removeEventListener(self, "onUpdate", Leveler)
	end
	v9_.dirtyFlag = self:getNextDirtyFlag()
end

-- Local values: spec
function Leveler:onDelete()
	local v15_ = self.spec_leveler
	g_effectManager:deleteEffects(v15_.effects)
end

-- Local values: spec
function Leveler:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		self.spec_leveler.lastFillLevelMovedPct = streamReadUIntN(streamId, Leveler.LEVEL_NUM_BITS) / Leveler.LEVEL_MAX_VALUE
	end
end

-- Local values: spec
function Leveler:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v23_ = self.spec_leveler
		local v24_ = streamWriteBool
		local v25_ = v23_.dirtyFlag
		if v24_(streamId, bit32.band(dirtyMask, v25_) ~= 0) then
			streamWriteUIntN(streamId, v23_.lastFillLevelMovedPct * Leveler.LEVEL_MAX_VALUE, Leveler.LEVEL_NUM_BITS)
		end
	end
end

-- Local values: spec, fillType, _, levelerNode, _, effect, _, levelerNode, x0, y0, z0, x1, y1, z1, ownerFarmId, pickedUpFillLevel, fillType, fillLevel, newFillType, heightType, innerRadius, outerRadius, capacity, dirY, dirX, dirZ, sx, sy, sz, ex, ey, ez, _, sy2, _, _, ey2, _, delta, numHeightLimitChecks, movementY, i, t, xi, yi, zi, hi, lastPickUpPerMS, f, width, sx, sy, sz, ex, ey, ez, yOffset, leftOver, dropOffset, wx, wy, wz, tx, ty, tz, rDirX, rDirY, rDirZ, distance, smoothAmount, rounded, smoothFactor, oldPercentage, dx, dy, dz, px, py, pz
function Leveler:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v28_ = self.spec_leveler
	if self.isClient then
		local v29_ = FillType.UNKNOWN
		for _, v30_ in pairs(v28_.nodes) do
			v29_ = self:getFillUnitLastValidFillType(v30_.fillUnitIndex)
			if v29_ ~= FillType.UNKNOWN then
				break
			end
		end
		if v29_ == FillType.UNKNOWN or v28_.lastFillLevelMovedPct <= 0 then
			g_effectManager:stopEffects(v28_.effects)
		else
			g_effectManager:setEffectTypeInfo(v28_.effects, v29_)
			g_effectManager:startEffects(v28_.effects)
			for _, v31_ in pairs(v28_.effects) do
				if v31_:isa(LevelerEffect) or v31_:isa(SnowPlowMotionPathEffect) then
					v31_:setFillLevel(v28_.lastFillLevelMovedPct)
					v31_:setLastVehicleSpeed(self.movingDirection * self:getLastSpeed())
				end
			end
		end
	end
	if self.isServer then
		for _, v32_ in pairs(v28_.nodes) do
			local v33_, v34_, v35_ = localToWorld(v32_.node, -v32_.halfWidth, v32_.yOffset, v32_.maxDropDirOffset)
			local v36_, v37_, v38_ = localToWorld(v32_.node, v32_.halfWidth, v32_.yOffset, v32_.maxDropDirOffset)
			if not v28_.ignoreFarmlandState then
				local v39_ = self:getOwnerFarmId()
				if not (g_farmlandManager:getCanAccessLandAtWorldPosition(v39_, v33_, v35_) and g_farmlandManager:getCanAccessLandAtWorldPosition(v39_, v36_, v38_)) then
					break
				end
			end
			local v40_ = 0
			local v41_ = self:getFillUnitFillType(v32_.fillUnitIndex)
			local v42_ = self:getFillUnitFillLevel(v32_.fillUnitIndex)
			local v43_
			if v41_ == FillType.UNKNOWN or v42_ < g_densityMapHeightManager:getMinValidLiterValue(v41_) + 0.001 then
				v43_ = DensityMapHeightUtil.getFillTypeAtLine(v33_, v34_, v35_, v36_, v37_, v38_, 0.5 * v32_.maxDropDirOffset)
				if v43_ == FillType.UNKNOWN or (v43_ == v41_ or not self:getFillUnitSupportsFillType(v32_.fillUnitIndex, v43_)) then
					v43_ = v41_
				else
					self:addFillUnitFillLevel(self:getOwnerFarmId(), v32_.fillUnitIndex, -math.huge)
				end
			else
				v43_ = v41_
			end
			local v44_ = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(v43_)
			if v43_ == FillType.UNKNOWN or v44_ == nil then
				v28_.lastFillLevelMovedBuffer = 0
				v28_.lastFillLevelMovedTarget = 0
			else
				local v45_ = 2
				local v46_ = self:getFillUnitCapacity(v32_.fillUnitIndex)
				local v47_
				if v32_.alignToWorldY then
					local v48_, v49_
					v48_, v47_, v49_ = localDirectionToWorld(v32_.referenceFrame, 0, 0, 1)
					I3DUtil.setWorldDirection(v32_.node, v48_, math.max(v47_, 0), v49_, 0, 1, 0)
				else
					v47_ = 0
				end
				if self:getIsLevelerPickupNodeActive(v32_) and (v28_.pickUpDirection == self.movingDirection and self.lastSpeed > 0.0001) then
					local v50_, v51_, v52_ = localToWorld(v32_.node, -v32_.halfWidth, v32_.yOffset, v32_.zOffset)
					local v53_, v54_, v55_ = localToWorld(v32_.node, v32_.halfWidth, v32_.yOffset, v32_.zOffset)
					if v47_ >= 0 then
						local _, v56_, _ = localToWorld(v32_.node, -v32_.halfWidth, v32_.yOffset, v32_.zOffset + 0.5)
						local _, v57_, _ = localToWorld(v32_.node, v32_.halfWidth, v32_.yOffset, v32_.zOffset + 0.5)
						v51_ = math.max(v51_, v56_)
						v54_ = math.max(v54_, v57_)
					end
					local v58_ = -(v46_ - self:getFillUnitFillLevel(v32_.fillUnitIndex))
					local v59_ = v32_.numHeightLimitChecks
					if v59_ > 0 then
						local v60_ = 0
						for v61_ = 0, v59_ do
							local v62_ = v61_ / v59_
							local v63_ = v50_ + (v53_ - v50_) * v62_
							local v64_ = v51_ + (v54_ - v51_) * v62_
							local v65_ = v52_ + (v55_ - v52_) * v62_
							local v66_ = DensityMapHeightUtil.getHeightAtWorldPos(v63_, v64_, v65_) - 0.05 - v64_
							v60_ = math.max(v60_, v66_)
						end
						if v60_ > 0 then
							v51_ = v51_ + v60_
							v54_ = v54_ + v60_
						end
					end
					local v67_, v68_ = DensityMapHeightUtil.tipToGroundAroundLine(self, v58_, v43_, v50_, v51_, v52_, v53_, v54_, v55_, 0.5, 2, v32_.lineOffsetPickUp, true, nil)
					v32_.lastPickUp = v67_
					v32_.lineOffsetPickUp = v68_
					if v32_.lastPickUp < 0 then
						if self.notifiyBunkerSilo ~= nil then
							self:notifiyBunkerSilo(v32_.lastPickUp, v43_, (v50_ + v53_) * 0.5, (v51_ + v54_) * 0.5, (v52_ + v55_) * 0.5)
						end
						v32_.lastPickUp = v32_.lastPickUp + v28_.litersToPickup
						v28_.litersToPickup = 0
						self:addFillUnitFillLevel(self:getOwnerFarmId(), v32_.fillUnitIndex, -v32_.lastPickUp, v43_, ToolType.UNDEFINED, nil)
						v40_ = v32_.lastPickUp
					end
				end
				local v69_ = -v40_
				v28_.lastFillLevelMovedBuffer = v28_.lastFillLevelMovedBuffer + v69_
				v28_.lastFillLevelMovedBufferTimer = v28_.lastFillLevelMovedBufferTimer + dt
				if v28_.lastFillLevelMovedBufferTimer > v28_.lastFillLevelMovedBufferTime then
					v28_.lastFillLevelMovedTarget = v28_.lastFillLevelMovedBuffer / v28_.lastFillLevelMovedBufferTimer
					v28_.lastFillLevelMovedBufferTimer = 0
					v28_.lastFillLevelMovedBuffer = 0
				end
				if self.movingDirection < 0 and self.lastSpeed * 3600 > 0.5 then
					v28_.lastFillLevelMovedBuffer = 0
				end
				local v70_ = self:getFillUnitFillLevel(v32_.fillUnitIndex)
				if v70_ > 0 then
					local v71_ = v70_ / v46_
					local v72_ = MathUtil.lerp(v32_.halfMinDropWidth, v32_.halfMaxDropWidth, v71_)
					local v73_, v74_, v75_ = localToWorld(v32_.node, -v72_, v32_.yOffset, v32_.zOffset)
					local v76_, v77_, v78_ = localToWorld(v32_.node, v72_, v32_.yOffset, v32_.zOffset)
					local v79_, v80_ = DensityMapHeightUtil.tipToGroundAroundLine(self, v70_, v43_, v73_, v74_ + -0.15, v75_, v76_, v77_ + -0.15, v78_, 0.5, 2, v32_.lineOffsetDrop1, true, nil)
					v32_.lastDrop1 = v79_
					v32_.lineOffsetDrop1 = v80_
					if v32_.lastDrop1 > 0 then
						local v81_ = v70_ - v32_.lastDrop1
						if v81_ <= g_densityMapHeightManager:getMinValidLiterValue(v43_) then
							v32_.lastDrop1 = v70_
							v28_.litersToPickup = v28_.litersToPickup + v81_
						end
						self:addFillUnitFillLevel(self:getOwnerFarmId(), v32_.fillUnitIndex, -v32_.lastDrop1, v43_, ToolType.UNDEFINED, nil)
					end
				end
				if self:getFillUnitFillLevel(v32_.fillUnitIndex) > 0 then
					local v82_ = MathUtil.lerp(v32_.minDropDirOffset, v32_.maxDropDirOffset, v28_.lastFillLevelMovedPct)
					local v83_, v84_, v85_ = localToWorld(v32_.node, 0, v32_.yOffset, 0)
					local v86_, v87_, v88_ = localToWorld(v32_.node, 0, v32_.yOffset, v32_.zOffset + v82_)
					v32_.raycastLastFillType = v43_
					v32_.raycastLastRadius = v45_
					v32_.raycastHitObject = false
					local v89_ = v86_ - v83_
					local v90_ = v87_ - v84_
					local v91_ = v88_ - v85_
					local v92_ = MathUtil.vector3Length(v89_, v90_, v91_)
					local v93_, v94_, v95_ = MathUtil.vector3Normalize(v89_, v90_, v91_)
					raycastAllAsync(v83_, v84_, v85_, v93_, v94_, v95_, v92_, "onLevelerRaycastCallback", v32_, Leveler.COLLISION_MASK)
				end
			end
			if v40_ < 0 and v43_ ~= FillType.UNKNOWN then
				self:notifiyBunkerSilo(v40_, v43_)
			end
			if v32_.allowsSmoothing and (v32_.smoothDirection == 0 or self.movingDirection == v32_.smoothDirection) then
				local v96_ = 0
				if self.lastSpeedReal > 0.0002 then
					local v97_ = v28_.smoothAccumulation
					local v98_ = self.lastMovedDistance * 0.5
					local v99_ = 0.0003 * dt
					v96_ = v97_ + math.max(v98_, v99_)
					v28_.smoothAccumulation = v96_ - DensityMapHeightUtil.getRoundedHeightValue(v96_)
				else
					v28_.smoothAccumulation = 0
				end
				if v96_ > 0 then
					DensityMapHeightUtil.smoothAroundLine(v32_.node, v32_.width, v32_.smoothGroundRadius, v32_.smoothOverlap, v96_, true)
				end
			end
		end
		local v100_ = v28_.lastFillLevelMovedTarget == 0 and 0.2 or 0.05
		v28_.lastFillLevelMoved = v28_.lastFillLevelMoved * (1 - v100_) + v28_.lastFillLevelMovedTarget * v100_
		if v28_.lastFillLevelMoved < 0.005 then
			v28_.lastFillLevelMoved = 0
		end
		local v101_ = v28_.lastFillLevelMovedPct
		local v102_ = v28_.lastFillLevelMoved / v28_.maxFillLevelPerMS
		local v103_ = math.min(v102_, 1)
		v28_.lastFillLevelMovedPct = math.max(v103_, 0)
		if v28_.lastFillLevelMovedPct ~= v101_ then
			self:raiseDirtyFlags(v28_.dirtyFlag)
		end
		if v28_.forceNode ~= nil and (self.movingDirection == v28_.forceDir and v28_.lastFillLevelMoved > 0) then
			v28_.lastForce = -v28_.maxForce * v28_.lastFillLevelMovedPct
			local v104_, v105_, v106_ = localDirectionToWorld(v28_.forceDirNode, 0, 0, v28_.lastForce)
			local v107_, v108_, v109_ = getCenterOfMass(v28_.forceNode)
			addForce(v28_.forceNode, v104_, v105_, v106_, v107_, v108_, v109_, true)
		end
	end
end

-- Local values: referenceFrame, i, baseKey, entry
function Leveler:loadLevelerNodeFromXML(levelerNode, xmlFile, key)
	levelerNode.node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	if levelerNode.node == nil then
		return false
	end
	local v114_ = createTransformGroup("referenceFrame")
	link(getParent(levelerNode.node), v114_)
	setTranslation(v114_, getTranslation(levelerNode.node))
	setRotation(v114_, getRotation(levelerNode.node))
	levelerNode.referenceFrame = v114_
	levelerNode.zOffset = xmlFile:getValue(key .. "#zOffset", 0)
	levelerNode.yOffset = xmlFile:getValue(key .. "#yOffset", 0)
	levelerNode.width = xmlFile:getValue(key .. "#width")
	levelerNode.halfWidth = levelerNode.width * 0.5
	levelerNode.minDropWidth = xmlFile:getValue(key .. "#minDropWidth", levelerNode.width * 0.5)
	levelerNode.halfMinDropWidth = levelerNode.minDropWidth * 0.5
	levelerNode.maxDropWidth = xmlFile:getValue(key .. "#maxDropWidth", levelerNode.width)
	levelerNode.halfMaxDropWidth = levelerNode.maxDropWidth * 0.5
	levelerNode.minDropDirOffset = xmlFile:getValue(key .. "#minDropDirOffset", 0.7)
	levelerNode.maxDropDirOffset = xmlFile:getValue(key .. "#maxDropDirOffset", 0.7)
	levelerNode.numHeightLimitChecks = xmlFile:getValue(key .. "#numHeightLimitChecks", 6)
	levelerNode.alignToWorldY = xmlFile:getValue(key .. "#alignToWorldY", true)
	levelerNode.occlusionAreas = {}
	local v115_ = 0
	while true do
		local v116_ = string.format("%s.occlusionAreas.occlusionArea(%d)", key, v115_)
		if not xmlFile:hasProperty(v116_) then
			break
		end
		local v117_ = {
			["startNode"] = xmlFile:getValue(v116_ .. "#startNode", nil, self.components, self.i3dMappings),
			["widthNode"] = xmlFile:getValue(v116_ .. "#widthNode", nil, self.components, self.i3dMappings),
			["heightNode"] = xmlFile:getValue(v116_ .. "#heightNode", nil, self.components, self.i3dMappings)
		}
		if v117_.startNode == nil or (v117_.widthNode == nil or v117_.heightNode == nil) then
			Logging.xmlWarning(xmlFile, "Failed to load occlustion area \'%s\'. One or more nodes missing.", v116_)
		else
			local v118_ = levelerNode.occlusionAreas
			table.insert(v118_, v117_)
		end
		v115_ = v115_ + 1
	end
	levelerNode.allowsSmoothing = xmlFile:getValue(key .. ".smoothing#allowed", true)
	levelerNode.smoothGroundRadius = xmlFile:getValue(key .. ".smoothing#radius", 0.5)
	levelerNode.smoothOverlap = xmlFile:getValue(key .. ".smoothing#overlap", 1.7)
	levelerNode.smoothDirection = xmlFile:getValue(key .. ".smoothing#direction", -1)
	levelerNode.lineOffsetPickUp = nil
	levelerNode.lineOffsetDrop = nil
	levelerNode.lastPickUp = 0
	levelerNode.lastDrop = 0
	levelerNode.fillUnitIndex = xmlFile:getValue(key .. "#fillUnitIndex", self.spec_leveler.fillUnitIndex)
	if self:getFillUnitExists(levelerNode.fillUnitIndex) then
		return true
	end
	local v119_ = Logging.xmlWarning
	local v120_ = self.xmlFile
	local v121_ = levelerNode.fillUnitIndex
	v119_(v120_, "Unknown fillUnitIndex \'%s\' for leveler", (tostring(v121_)))
	return false
end

function Leveler:getIsLevelerPickupNodeActive(levelerNode)
	return self.getAttacherVehicle == nil and true or self:getAttacherVehicle() ~= nil
end

-- Local values: _, levelerNode, x, y, z, _, height
function Leveler:getIsAttacherJointControlDampingAllowed(superFunc)
	if not superFunc(self) then
		return false
	end
	for _, v125_ in pairs(self.spec_leveler.nodes) do
		local v126_, v127_, v128_ = getWorldTranslation(v125_.node)
		local _, v129_ = DensityMapHeightUtil.getHeightAtWorldPos(v126_, v127_, v128_)
		if v129_ == 0 then
			return false
		end
	end
	return true
end

-- Local values: self, spec, fillLevel, fillType, outerRadius, f, width, dropOffset, terrainHeightUpdater, i, occlusionArea, ox1, oy1, oz1, ox2, _, oz2, ox3, _, oz3, ox, oz, widthX, widthZ, heightX, heightZ, sx, sy, sz, ex, ey, ez, leftOver
function Leveler.onLevelerRaycastCallback(levelerNode, hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	local v133_ = levelerNode.vehicle
	if not (v133_.isDeleted or v133_.isDeleting) then
		local v134_ = v133_.spec_leveler
		if hitObjectId ~= 0 and hitObjectId ~= g_terrainNode then
			levelerNode.raycastHitObject = true
		end
		if isLast and not levelerNode.raycastHitObject then
			local v135_ = v133_:getFillUnitFillLevel(levelerNode.fillUnitIndex)
			if v135_ > 0 then
				local v136_ = levelerNode.raycastLastFillType
				local v137_ = levelerNode.raycastLastRadius
				local v138_ = v134_.lastFillLevelMovedPct
				local v139_ = MathUtil.lerp(levelerNode.halfMinDropWidth, levelerNode.halfMaxDropWidth, v138_)
				local v140_ = MathUtil.lerp(levelerNode.minDropDirOffset, levelerNode.maxDropDirOffset, v138_)
				local v141_ = g_densityMapHeightManager:getTerrainDetailHeightUpdater()
				if v141_ ~= nil then
					for v142_ = 1, #levelerNode.occlusionAreas do
						local v143_ = levelerNode.occlusionAreas[v142_]
						local v144_, v145_, v146_ = getWorldTranslation(v143_.startNode)
						local v147_, _, v148_ = getWorldTranslation(v143_.widthNode)
						local v149_, _, v150_ = getWorldTranslation(v143_.heightNode)
						local v151_, v152_, v153_, v154_, v155_, v156_ = MathUtil.getXZWidthAndHeight(v144_, v146_, v147_, v148_, v149_, v150_)
						addDensityMapHeightOcclusionArea(v141_, v151_, v145_, v152_, v153_, v145_, v154_, v155_, v145_, v156_, true)
					end
				end
				local v157_, v158_, v159_ = localToWorld(levelerNode.node, -v139_, levelerNode.yOffset, levelerNode.zOffset + v140_)
				local v160_, v161_, v162_ = localToWorld(levelerNode.node, v139_, levelerNode.yOffset, levelerNode.zOffset + v140_)
				local v163_, v164_ = DensityMapHeightUtil.tipToGroundAroundLine(v133_, v135_, v136_, v157_, v158_, v159_, v160_, v161_, v162_, 0, v137_, levelerNode.lineOffsetDrop2, false, nil)
				levelerNode.lastDrop2 = v163_
				levelerNode.lineOffsetDrop2 = v164_
				if levelerNode.lastDrop2 > 0 then
					local v165_ = v135_ - levelerNode.lastDrop2
					if v165_ <= g_densityMapHeightManager:getMinValidLiterValue(v136_) then
						levelerNode.lastDrop2 = v135_
						v134_.litersToPickup = v134_.litersToPickup + v165_
					end
					v133_:addFillUnitFillLevel(v133_:getOwnerFarmId(), levelerNode.fillUnitIndex, -levelerNode.lastDrop2, v136_, ToolType.UNDEFINED, nil)
				end
			end
		end
	end
end
