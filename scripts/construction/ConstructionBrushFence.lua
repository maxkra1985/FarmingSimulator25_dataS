-- Local values: ConstructionBrushFence_mt
ConstructionBrushFence = {}
local ConstructionBrushFence_mt = Class(ConstructionBrushFence, ConstructionBrush)
ConstructionBrushFence.ERROR = {
	["MININUM_LENGTH"] = 100,
	["MINIMUM_ANGLE"] = 101,
	["MAXIMUM_ANGLE"] = 102,
	["COLLISION"] = 103,
	["NOT_ENOUGH_MONEY"] = 104,
	["CANNOT_BE_PLACED_HERE"] = 105
}
ConstructionBrushFence.ERROR_MESSAGES = {
	[ConstructionBrushFence.ERROR.MININUM_LENGTH] = "ui_construction_distanceTooShort",
	[ConstructionBrushFence.ERROR.MINIMUM_ANGLE] = "ui_construction_cornerAngleTooLarge",
	[ConstructionBrushFence.ERROR.MAXIMUM_ANGLE] = "ui_construction_terrainTooSteep",
	[ConstructionBrushFence.ERROR.COLLISION] = "ui_construction_collidesWithItem",
	[ConstructionBrushFence.ERROR.NOT_ENOUGH_MONEY] = "ui_construction_notEnoughMoney",
	[ConstructionBrushFence.ERROR.CANNOT_BE_PLACED_HERE] = "ui_construction_cannotBePlacedHere"
}
ConstructionBrushFence.MINIMUM_LENGTH = 0.5
ConstructionBrushFence.MINIMUM_ANGLE = 0.5235987755982988
ConstructionBrushFence.SNAP_DISTANCE = 0.4
ConstructionBrushFence.LAST_SNAPPING_STATE = false
ConstructionBrushFence.OVERLAP_COLLISION_MASK = CollisionMask.ALL - CollisionFlag.TERRAIN - CollisionFlag.TERRAIN_DISPLACEMENT - CollisionFlag.TRIGGER - CollisionFlag.GROUND_TIP_BLOCKING

-- Upvalues: ConstructionBrushFence_mt
-- Local values: self
function ConstructionBrushFence.new(subclass_mt, cursor)
	-- upvalues: (copy) ConstructionBrushFence_mt
	local v4_ = ConstructionBrushFence:superClass().new(subclass_mt or ConstructionBrushFence_mt, cursor)
	v4_.supportsPrimaryButton = true
	v4_.supportsSecondaryButton = true
	v4_.supportsTertiaryButton = true
	v4_.needsOverlayReset = {}
	v4_.requiredPermission = Farm.PERMISSION.BUY_PLACEABLE
	v4_.parallelSnappingEnabled = false
	v4_.doFindPlaceable = false
	v4_.supportsSnapping = true
	v4_.snappingActive = ConstructionBrushFence.LAST_SNAPPING_STATE
	v4_.snappingAngleDeg = 7.5
	v4_.snappingSize = 0.25
	return v4_
end

function ConstructionBrushFence:delete()
	ConstructionBrushFence:superClass().delete(self)
	self.doFindPlaceable = false
end

function ConstructionBrushFence:activate()
	ConstructionBrushFence:superClass().activate(self)
	self.cursor:setRotationEnabled(false)
	self.cursor:setShape(GuiTopDownCursor.SHAPES.CIRCLE)
	self.cursor:setShapeSize(0.3)
	self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SUCCESS)
	self.cursor:setTerrainOnly(true)
	g_messageCenter:subscribe(PlaceableFenceAddSegmentEvent, self.onFenceSegmentCreated, self)
	self:acquirePlaceable()
end

function ConstructionBrushFence:deactivate()
	self:releasePlaceable()
	self.fence = nil
	self.doFindPlaceable = false
	self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SELECT, nil)
	self:resetErrorOverlays()
	g_messageCenter:unsubscribeAll(self)
	ConstructionBrushFence:superClass().deactivate(self)
end

function ConstructionBrushFence:setFilename(xmlFilename)
	if not self.isActive then
		self.xmlFilename = xmlFilename
	end
end

function ConstructionBrushFence:setIsGate(isGate, gateIndex)
	if isGate then
		self.gateIndex = gateIndex
	else
		self.gateIndex = nil
	end
end

function ConstructionBrushFence:setParameters(filename, isGate, gateIndex)
	if isGate == "true" then
		self:setIsGate(true, (tonumber(gateIndex)))
	else
		self:setIsGate(false)
	end
	self:setFilename(filename)
end

function ConstructionBrushFence:setStoreItem(storeItem, configrations, configurationData)
	if not self.isActive then
		self.storeItem = storeItem
	end
end

function ConstructionBrushFence:canCancel()
	local v20_
	if self.fence == nil then
		v20_ = false
	else
		v20_ = self.fence:getPreviewSegment() ~= nil
	end
	return v20_
end

-- Local values: singletonStoreItem, data
function ConstructionBrushFence:acquirePlaceable()
	if self.xmlFilename == nil then
		Logging.warning("Fence brush has no placeable set")
		return
	else
		self.fence = self:findPlaceable()
		self:setInputTextDirty()
		if self.fence == nil then
			local v22_ = g_storeManager:getItemByXMLFilename(self.xmlFilename)
			local v23_ = BuyPlaceableData.new()
			v23_:setStoreItem(v22_)
			v23_:setPosition(0, PlacementUtil.NETHER_HEIGHT - 1, 0)
			v23_:setRotation(0, 0, 0)
			v23_:setConfigurations({})
			v23_:setOwnerFarmId(g_localPlayer.farmId)
			v23_:setDisplacementCosts(0)
			v23_:setModifyTerrain(false)
			v23_:setIsFreeOfCharge(true)
			g_messageCenter:subscribe(BuyPlaceableEvent, self.onPlaceableCreated, self)
			g_client:getServerConnection():sendEvent(BuyPlaceableEvent.new(v23_))
		elseif self.fence:getHasParallelSnapping() then
			self.parallelSnappingEnabled = true
		end
	end
end

-- Local values: farmId, existingPlaceableInstance
function ConstructionBrushFence:findPlaceable()
	local v25_ = g_currentMission:getFarmId()
	return g_currentMission.placeableSystem:getExistingPlaceableByXMLFilename(self.xmlFilename, v25_)
end

function ConstructionBrushFence:onPlaceableCreated(errorCode, price, serverObjectId)
	g_messageCenter:unsubscribe(BuyPlaceableEvent, self)
	if errorCode == BuyPlaceableEvent.STATE_FAILED_TO_LOAD then
		self.cursor:setErrorMessage("Loading failed")
	else
		self.doFindPlaceable = true
	end
end

function ConstructionBrushFence:releasePlaceable()
	if self.fence ~= nil then
		if self.fence:getNumSequments() == 0 then
			g_client:getServerConnection():sendEvent(SellPlaceableEvent.new(self.fence, true, false, false))
		elseif self.fence:getPreviewSegment() ~= nil then
			self.fence:setPreviewSegment(nil)
		end
		if self.previewPole ~= nil then
			delete(self.previewPole)
			self.previewPole = nil
		end
		self.fence = nil
		self:setInputTextDirty()
	end
end

-- Local values: x, y, z, isNodeSegmentEndpoint, node, px, py, pz, segment, snapCheckDistance, px, py, pz, _, segment, previewSegment, dx, dz, dist, x1, z1, x2, z2, distance1, distance2, distancePole, snapX, snapZ, snapY, alignSegment, dx, dz, targetX, targetZ, targetY, snapDistance, px, py, pz, node, segment, snapSize
function ConstructionBrushFence:getSnappedCursorPosition()
	local v30_, v31_, v32_ = self.cursor:getHitTerrainPosition()
	local function v36_(p33_)
		local v34_ = getParent(p33_)
		local v35_ = getParent(v34_)
		return v34_ == getChildAt(v35_, 0) and true or v34_ == getChildAt(v35_, getNumOfChildren(v35_) - 1)
	end
	if v30_ == nil then
		local v37_ = self.cursor:getHitNode()
		if v37_ == nil then
			return nil
		else
			local v38_, v39_, v40_, v41_ = self.fence:getPolePosition(v37_)
			if v38_ == nil then
				return nil
			elseif self.fence:getAllowExtendingOnly() then
				if v36_(v37_) then
					return v38_, v39_, v40_, true, v41_
				else
					return v30_, v31_, v32_, false
				end
			else
				return v38_, v39_, v40_, true, v41_
			end
		end
	else
		if self.parallelSnappingEnabled then
			local v42_ = self.fence:getSnapCheckDistance()
			local v43_, v44_, v45_, _, v46_ = self.fence:getPoleNear(v30_, v31_, v32_, v42_)
			local v47_ = self.fence:getPreviewSegment()
			self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SELECT, nil)
			if v43_ ~= nil and v47_ == nil then
				if self.previewPoleCursor then
					self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SUCCESS, nil)
				end
				local v48_, v49_ = MathUtil.vector2Normalize(v46_.x2 - v46_.x1, v46_.z2 - v46_.z1)
				local v50_ = self.fence:getSnapDistance()
				local v51_ = -v49_ * v50_ + v43_
				local v52_ = v48_ * v50_ + v45_
				local v53_ = v49_ * v50_ + v43_
				local v54_ = -v48_ * v50_ + v45_
				local v55_ = MathUtil.vector2Length(v51_ - v30_, v52_ - v32_)
				local v56_ = MathUtil.vector2Length(v53_ - v30_, v54_ - v32_)
				local v57_ = MathUtil.vector2Length(v43_ - v30_, v45_ - v32_)
				if v55_ < v56_ then
					v54_ = v52_
					v53_ = v51_
				end
				self.parallelSnappingSegment = v46_
				local v58_ = getTerrainHeightAtWorldPos(g_terrainNode, v53_, 0, v54_)
				if self.fence:getMaxCornerAngle() == 0 and v57_ < v50_ * 0.4 then
					return v43_, v44_, v45_, true, v46_
				else
					return v53_, v58_, v54_, true
				end
			end
			if self.parallelSnappingSegment ~= nil and v47_ ~= nil then
				local v59_ = self.parallelSnappingSegment
				local v60_, v61_ = MathUtil.vector2Normalize(v59_.x2 - v59_.x1, v59_.z2 - v59_.z1)
				local v62_, v63_ = MathUtil.projectOnLine(v30_, v32_, v47_.x1, v47_.z1, v60_, v61_)
				return v62_, getTerrainHeightAtWorldPos(g_terrainNode, v62_, 0, v63_), v63_, true
			end
			self.parallelSnappingSegment = nil
		end
		local v64_ = self.fence:getPanelLength() * ConstructionBrushFence.SNAP_DISTANCE
		local v65_ = self.fence
		local v66_ = math.max(v64_, v65_:getSnapCheckDistance())
		local v67_, v68_, v69_, v70_, v71_ = self.fence:getPoleNear(v30_, v31_, v32_, v66_)
		if v67_ == nil or self.fence:getMaxCornerAngle() <= 0 then
			if self.snappingActive then
				local v72_ = 1 / self.snappingSize
				local v73_ = v30_ * v72_
				v30_ = math.floor(v73_) / v72_
				local v74_ = v32_ * v72_
				v32_ = math.floor(v74_) / v72_
			end
			return v30_, v31_, v32_, false
		elseif self.fence:getAllowExtendingOnly() then
			if v36_(v70_) then
				return v67_, v68_, v69_, true, v71_
			else
				return v30_, v31_, v32_, false
			end
		else
			return v67_, v68_, v69_, true, v71_
		end
	end
end

-- Local values: x, y, z, snapped, segment, pSegment, dx, dz, panelLength, recalculateY, length, prevSeqment, snapAngleDeg, prevdx, prevdz, prevRotY, rotY, diff, snappedAngle
function ConstructionBrushFence:getLimitedSnappedCursorPosition()
	local v76_, v77_, v78_, v79_, v80_ = self:getSnappedCursorPosition()
	local v81_ = self.fence:getPreviewSegment()
	if v76_ ~= nil and v81_ ~= nil then
		local v82_ = v76_ - v81_.x1
		local v83_ = v78_ - v81_.z1
		local v84_ = MathUtil.vector2Length(v82_, v83_)
		local v85_ = false
		local v86_, v87_
		if v84_ == 0 then
			v86_ = 1
			v87_ = 0
		else
			v86_, v87_ = MathUtil.vector2Normalize(v82_, v83_)
		end
		if self.gateIndex == nil then
			if self.fence:getIsPanelLengthFixed() then
				local v88_ = self.fence:getPanelLength()
				local v89_ = v84_ / v88_
				v84_ = math.floor(v89_) * v88_
				v85_ = true
			end
		else
			v84_ = self.fence:getGate(self.gateIndex).length
			v85_ = true
		end
		local v90_ = self.attachmentPointSegment
		local v91_ = self.fence:getSnapAngle()
		if v90_ ~= nil and v91_ ~= nil then
			local v92_ = v90_.x2 - v90_.x1
			local v93_ = v90_.z2 - v90_.z1
			local v94_, v95_ = MathUtil.vector2Normalize(v92_, v93_)
			local v96_ = MathUtil.getYRotationFromDirection(v94_, v95_) - MathUtil.getYRotationFromDirection(v86_, v87_)
			local v97_ = MathUtil.snapValue(math.deg(v96_), v91_)
			local v98_ = math.rad(v97_)
			v86_, v87_ = MathUtil.vector2Rotate(v94_, v95_, v98_)
			v85_ = true
		end
		v76_ = v81_.x1 + v86_ * v84_
		v78_ = v81_.z1 + v87_ * v84_
		if v85_ then
			v77_ = getTerrainHeightAtWorldPos(g_terrainNode, v76_, 0, v78_)
		end
	end
	return v76_, v77_, v78_, v79_, v80_
end

-- Local values: segment, prevSegment, alpha, dx, dz, dx, dz, dx, dz, beta, angle
function ConstructionBrushFence:getPreviewAngle()
	if self.fence:getPreviewSegment() == nil then
		return nil
	end
	local v100_ = self.fence:getPreviewSegment()
	local v101_ = self.attachmentPointSegment
	if v101_ == nil then
		return nil
	end
	local v102_
	if self.attachmentPointSegmentReversed then
		local v103_ = v101_.x2 - v101_.x1
		local v104_ = v101_.z2 - v101_.z1
		v102_ = MathUtil.getYRotationFromDirection(v103_, v104_)
	else
		local v105_ = v101_.x1 - v101_.x2
		local v106_ = v101_.z1 - v101_.z2
		v102_ = MathUtil.getYRotationFromDirection(v105_, v106_)
	end
	local v107_ = v100_.x1 - v100_.x2
	local v108_ = v100_.z1 - v100_.z2
	local v109_ = MathUtil.getYRotationFromDirection(v107_, v108_)
	local v110_ = MathUtil.getAngleDifference(v102_, v109_) - 3.141592653589793
	local v111_ = math.abs(v110_)
	if v111_ > 3.141592653589793 then
		v111_ = 3.141592653589793 - (v111_ - 3.141592653589793)
	end
	return 3.141592653589793 - v111_
end

-- Local values: price
function ConstructionBrushFence:getPrice(length)
	if self.gateIndex ~= nil then
		return self.storeItem.price
	end
	if length == nil then
		length = self.fence:getSegmentLength(self.fence:getPreviewSegment())
	end
	return length * self.storeItem.price
end

-- Local values: pSegment, y, err, canBePlaced, placingFailedMessage, length, verticalAngle, minY, maxY, price, angle, bx, bz, by, rx, ry, rz, ex, ey, ez, dynamics, statics, kinematics, exact
function ConstructionBrushFence:verifyPreview()
	local v115_ = self.fence:getPreviewSegment()
	local v116_ = getTerrainHeightAtWorldPos(g_terrainNode, v115_.x2, 0, v115_.z2)
	local v117_ = self:verifyAccess(v115_.x2, v116_, v115_.z2)
	if v117_ == nil then
		local v118_, v119_ = self.fence:getCanBePlacedAt(v115_.x2, 0, v115_.z2, g_currentMission:getFarmId())
		if v118_ then
			local v120_ = self.fence:getSegmentLength(v115_)
			if v120_ < self.fence:getPanelLength() * ConstructionBrushFence.MINIMUM_LENGTH then
				return ConstructionBrushFence.ERROR.MININUM_LENGTH
			else
				local v121_, v122_, v123_ = self.fence:getMaxVerticalAngleAndYForPreview()
				if self.fence:getMaxVerticalAngle() < v121_ or v115_.gateIndex ~= nil and self.fence:getMaxVerticalGateAngle() < v121_ then
					return ConstructionBrushFence.ERROR.MAXIMUM_ANGLE
				elseif self:getPrice(v120_) > g_currentMission:getMoney(self.fence:getOwnerFarmId()) then
					return ConstructionBrushFence.ERROR.NOT_ENOUGH_MONEY
				else
					local v124_ = self:getPreviewAngle()
					if self.parallelSnappingSegment == nil and (v124_ ~= nil and self.fence:getMaxCornerAngle() < v124_) then
						return ConstructionBrushFence.ERROR.MINIMUM_ANGLE
					else
						local v125_ = v115_.x1 / 2 + v115_.x2 / 2
						local v126_ = v115_.z1 / 2 + v115_.z2 / 2
						local v127_ = v122_ / 2 + v123_ / 2
						local v128_ = v115_.x2 - v115_.x1
						local v129_ = v115_.z2 - v115_.z1
						local v130_ = math.atan2(v128_, v129_) + 1.5707963267948966
						local v131_ = v120_ * 0.5 + self.fence:getBoundingCheckWidth() * 0.5
						local v132_ = v122_ - v123_
						local v133_ = math.abs(v132_) * 0.5 + 2
						local v134_ = self.fence:getBoundingCheckWidth() * 0.5
						self.hitAnyObjects = false
						overlapBox(v125_, v127_, v126_, 0, v130_, 0, v131_, v133_, v134_, "boxOverlapCallback", self, ConstructionBrushFence.OVERLAP_COLLISION_MASK, true, true, true, true)
						if self.hitAnyObjects then
							return ConstructionBrushFence.ERROR.COLLISION
						else
							return nil
						end
					end
				end
			end
		else
			return ConstructionBrushFence.ERROR.CANNOT_BE_PLACED_HERE, v119_
		end
	else
		return v117_
	end
end

-- Local values: object, _, panelVisuals, segment, pole, poleIndex, pSegment, setColoredNodes, poleVisuals
function ConstructionBrushFence:boxOverlapCallback(hitObjectId, x, y, z, distance)
	if hitObjectId ~= 0 and hitObjectId ~= g_terrainNode then
		local v137_ = g_currentMission:getNodeObject(hitObjectId)
		if v137_ ~= nil and v137_.setOverlayColor ~= nil then
			if v137_.findRaycastInfo == nil then
				v137_:setOverlayColor(1, 0, 0, 1)
				local v138_ = self.needsOverlayReset
				table.insert(v138_, v137_)
			else
				local _, v139_, v140_, v141_, v142_ = v137_:findRaycastInfo(hitObjectId)
				if v141_ ~= nil then
					local v143_ = self.fence:getPreviewSegment()
					if v137_ == self.fence and (MathUtil.equalEpsilon(v140_.poles[v142_], v143_.x1, 0.01) and MathUtil.equalEpsilon(v140_.poles[v142_ + 1], v143_.z1, 0.01) or (MathUtil.equalEpsilon(v140_.poles[v142_], v143_.x2, 0.01) and MathUtil.equalEpsilon(v140_.poles[v142_ + 1], v143_.z2, 0.01) or (MathUtil.equalEpsilon(v140_.poles[v142_ + 2], v143_.x1, 0.01) and MathUtil.equalEpsilon(v140_.poles[v142_ + 3], v143_.z1, 0.01) or MathUtil.equalEpsilon(v140_.poles[v142_ + 2], v143_.x2, 0.01) and MathUtil.equalEpsilon(v140_.poles[v142_ + 3], v143_.z2, 0.01)))) then
						return
					end
					local function v_u_147_(p144_)
						-- upvalues: (copy) self, (copy) v_u_147_
						if getHasClassId(p144_, ClassIds.SHAPE) then
							setShaderParameter(p144_, "placeableColorScale", 1, 0, 0, 1, false)
							local v145_ = self.needsOverlayReset
							table.insert(v145_, p144_)
						end
						for v146_ = 0, getNumOfChildren(p144_) - 1 do
							v_u_147_(getChildAt(p144_, v146_))
						end
					end
					if getNumOfChildren(v141_) > 1 then
						v_u_147_((getChildAt(v141_, 1)))
					end
					if v139_ ~= nil then
						v_u_147_(v139_)
					end
				end
			end
		end
		self.hitAnyObjects = true
	end
end

-- Local values: x, y, z, _, _, err, msg, segment
function ConstructionBrushFence:update(dt)
	ConstructionBrushFence:superClass().update(self, dt)
	if self.doFindPlaceable then
		self.fence = self:findPlaceable()
		self:setInputTextDirty()
		if self.fence ~= nil then
			if self.fence:getHasParallelSnapping() then
				self.parallelSnappingEnabled = true
			end
			self.doFindPlaceable = false
		end
	end
	if self.fence == nil then
		if not self:hasPlayerPermission() then
			self.cursor:setErrorMessage(g_i18n:getText(ConstructionBrush.ERROR_MESSAGES[ConstructionBrush.ERROR.NO_PERMISSION]))
		end
		return
	else
		local v150_, v151_, v152_, _, _ = self:getLimitedSnappedCursorPosition()
		local v153_ = nil
		local v154_ = nil
		local v155_ = self.fence:getPreviewSegment()
		if v150_ == nil or v155_ == nil then
			if self.previewPole == nil then
				self.previewPole = self.fence:getPoleShapeForPreview()
				if self.previewPole == nil then
					self.previewPole = createTransformGroup("PreviewPole")
					self.previewPoleCursor = true
				else
					self.previewPoleCursor = false
				end
				link(getRootNode(), self.previewPole)
			end
			if self.previewPoleCursor then
				self.cursor:setShape(GuiTopDownCursor.SHAPES.CIRCLE)
				self.cursor:setShapeSize(1)
			end
			if v150_ ~= nil then
				setWorldTranslation(self.previewPole, v150_, v151_, v152_)
				v153_ = self:verifyAccess(v150_, v151_, v152_)
			end
			setVisibility(self.previewPole, self.cursor.isVisible)
		else
			if v155_.x2 ~= v150_ or v155_.z2 ~= v152_ then
				v155_.x2 = v150_
				v155_.z2 = v152_
				self.fence:setPreviewSegment(v155_)
			end
			if self.previewPole ~= nil then
				setVisibility(self.previewPole, false)
			end
			if self.previewPoleCursor then
				self.cursor:setShape(GuiTopDownCursor.SHAPES.NONE)
			end
			self:resetErrorOverlays()
			v153_, v154_ = self:verifyPreview()
		end
		if v153_ == nil then
			if self.fence:getPreviewSegment() ~= nil then
				self.cursor:setMessage(g_i18n:formatMoney(self:getPrice(), 0, true, true))
			end
		else
			self.cursor:setErrorMessage(v154_ or g_i18n:getText(ConstructionBrushFence.ERROR_MESSAGES[v153_] or ConstructionBrush.ERROR_MESSAGES[v153_]))
		end
	end
end

-- Local values: i, item
function ConstructionBrushFence:resetErrorOverlays()
	for v157_ = #self.needsOverlayReset, 1, -1 do
		local v158_ = self.needsOverlayReset[v157_]
		if type(v158_) == "number" then
			setShaderParameter(v158_, "placeableColorScale", 0, 0, 0, 0, false)
		else
			v158_:setOverlayColor(0, 0, 0, 0)
		end
		self.needsOverlayReset[v157_] = nil
	end
end

-- Local values: x, y, z, snapped, segment, err, previewSegment, err, pSegment, price, event
function ConstructionBrushFence:onButtonPrimary()
	if self.fence == nil then
		return
	else
		local v160_, v161_, v162_, v163_, v164_ = self:getLimitedSnappedCursorPosition()
		if v160_ ~= nil then
			if self.fence:getPreviewSegment() == nil then
				if self:verifyAccess(v160_, v161_, v162_) == nil then
					local v165_ = self.fence
					local v166_
					if v163_ then
						v166_ = v164_ ~= nil
					else
						v166_ = v163_
					end
					local v167_ = v165_:createSegment(v160_, v162_, v160_, v162_, not v166_, self.gateIndex)
					if v163_ and v164_ ~= nil then
						self.attachmentPointSegment = v164_
						if v164_ ~= nil then
							local v168_ = MathUtil.equalEpsilon(v164_.x1, v160_, 0.01)
							if v168_ then
								v168_ = MathUtil.equalEpsilon(v164_.z1, v162_, 0.01)
							end
							self.attachmentPointSegmentReversed = v168_
						end
					end
					self.fence:setPreviewSegment(v167_)
					return
				end
			elseif self:verifyPreview() == nil then
				local v169_ = self.fence:getPreviewSegment()
				local v170_ = self:getPrice()
				local v171_ = PlaceableFenceAddSegmentEvent.new
				local v172_ = self.fence
				local v173_ = v169_.x1
				local v174_ = v169_.z1
				local v175_ = v169_.renderFirst
				if v163_ then
					v163_ = v164_ ~= nil
				end
				local v176_ = v171_(v172_, v173_, v174_, v160_, v162_, v175_, not v163_, v169_.gateIndex, v170_)
				g_client:getServerConnection():sendEvent(v176_)
				if self.fence.playPlaceSound ~= nil then
					self.fence:playPlaceSound()
				end
				if self.parallelSnappingEnabled then
					self.fence:setPreviewSegment(nil)
					self.attachmentPointSegment = nil
					self.attachmentPointSegmentReversed = nil
					self:resetErrorOverlays()
					return
				end
				v169_.x1 = v160_
				v169_.z1 = v162_
				v169_.renderFirst = false
				v169_.renderLast = true
				self.fence:setPreviewSegment(v169_)
				self.parallelSnappingSegment = nil
			end
		end
	end
end

function ConstructionBrushFence:onFenceSegmentCreated(fence, segment)
	if self.fence == fence then
		self.attachmentPointSegment = segment
		self.attachmentPointSegmentReversed = false
	end
end

function ConstructionBrushFence:onButtonSecondary()
	if self.fence ~= nil then
		if self.fence:getPreviewSegment() ~= nil then
			self.fence:setPreviewSegment(nil)
			self.attachmentPointSegment = nil
			self.attachmentPointSegmentReversed = nil
			self:resetErrorOverlays()
		end
	end
end

function ConstructionBrushFence:onButtonTertiary()
	if self.fence:getSupportsParallelSnapping() and self.fence:getMaxCornerAngle() > 0 then
		self.parallelSnappingEnabled = not self.parallelSnappingEnabled
		self:setInputTextDirty()
	end
end

function ConstructionBrushFence:onButtonSnapping()
	self.snappingActive = not self.snappingActive
	ConstructionBrushFence.LAST_SNAPPING_STATE = self.snappingActive
	self:setInputTextDirty()
end

function ConstructionBrushFence:cancel()
	self:onButtonSecondary()
end

function ConstructionBrushFence:getButtonPrimaryText()
	return "$l10n_input_CONSTRUCTION_PLACE_POLE"
end

function ConstructionBrushFence:getButtonSecondaryText()
	return "$l10n_input_CONSTRUCTION_FINISH"
end

function ConstructionBrushFence:getButtonTertiaryText()
	if self.fence == nil or (not self.fence:getSupportsParallelSnapping() or self.fence:getMaxCornerAngle() <= 0) then
		return nil
	else
		return string.format(g_i18n:getText("input_CONSTRUCTION_SNAP"), g_i18n:getText(self.parallelSnappingEnabled and "ui_on" or "ui_off"))
	end
end

function ConstructionBrushFence:getButtonSnappingText()
	return string.format("%s (%s)", g_i18n:getText("input_CONSTRUCTION_ACTION_SNAPPING"), g_i18n:getText(self.snappingActive and "ui_on" or "ui_off"))
end
