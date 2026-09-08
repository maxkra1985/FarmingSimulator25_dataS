-- Local values: FieldCourseVisual_mt
FieldCourseVisual = {}
FieldCourseVisual.ACTIVE_LINE_UPDATE_THRESHOLD = 2.5
FieldCourseVisual.NUM_VISIBLE_TILES = 3
FieldCourseVisual.TERRAIN_OFFSET = 0.05
FieldCourseVisual.VISUALS = {}
FieldCourseVisual.VISUALS[false] = {}
FieldCourseVisual.VISUALS[false].ACTIVE = {
	{
		0,
		1,
		0,
		1
	},
	0.25,
	2.25,
	true
}
FieldCourseVisual.VISUALS[false].AVAILABLE = {
	{
		1,
		0.3,
		0,
		1
	},
	0.25,
	5,
	true
}
FieldCourseVisual.VISUALS[false].INACTIVE = {
	{
		0.8,
		0.8,
		0.8,
		1
	},
	1,
	1.25,
	true
}
FieldCourseVisual.VISUALS[false].WORKED = {
	{
		0.2,
		0.2,
		0.2,
		1
	},
	0.5,
	0.75,
	true
}
FieldCourseVisual.VISUALS[false].TOOL_SIDE = {
	{
		0,
		0,
		1,
		1
	},
	1,
	1,
	true
}
FieldCourseVisual.VISUALS[false].HIDDEN = {
	{
		0,
		0,
		0,
		1
	},
	0,
	0,
	false
}
FieldCourseVisual.VISUALS[true] = {}
FieldCourseVisual.VISUALS[true].ACTIVE = {
	{
		0.0423,
		0.2502,
		0.8069,
		1
	},
	0.25,
	9,
	true,
	{
		0.9473,
		0.5271,
		0,
		0.015,
		1
	}
}
FieldCourseVisual.VISUALS[true].AVAILABLE = {
	{
		0.9473,
		0.5271,
		0,
		1
	},
	0.25,
	9,
	true,
	{
		0.0423,
		0.2502,
		0.8069,
		0.015,
		1
	}
}
FieldCourseVisual.VISUALS[true].INACTIVE = {
	{
		0.8,
		0.8,
		0.8,
		1
	},
	1,
	2.5,
	true
}
FieldCourseVisual.VISUALS[true].WORKED = {
	{
		0.2,
		0.2,
		0.2,
		1
	},
	0.5,
	1.5,
	true
}
FieldCourseVisual.VISUALS[true].TOOL_SIDE = {
	{
		0,
		0.0742,
		0.0513,
		1
	},
	2,
	3,
	true,
	nil,
	{ 1, 0.75 }
}
FieldCourseVisual.VISUALS[true].HIDDEN = {
	{
		0,
		0,
		0,
		1
	},
	0,
	0,
	false
}
FieldCourseVisual.VISUALS_FILENAME = "data/shared/ai/fieldCourseVisuals.i3d"
source("dataS/scripts/field/course/FieldCourseVisualTile.lua")
local FieldCourseVisual_mt = Class(FieldCourseVisual)
function FieldCourseVisual.new()
	-- upvalues: (copy) FieldCourseVisual_mt
	local v2_ = FieldCourseVisual_mt
	local v3_ = setmetatable({}, v2_)
	v3_.fieldCourse = nil
	v3_.vehicle = nil
	v3_.rootSegmentsByLength = {}
	v3_.lineSegmentPoolByLength = {}
	v3_.segmentIndexToData = {}
	v3_.lastActiveSegmentIndex = -1
	v3_.lastSteeringIsEnabled = false
	v3_.lastActiveSegmentIsLeft = false
	v3_.lastCameraPosition = { 0, 0 }
	v3_.lastSideOffsetReversed = false
	v3_.updateDirty = false
	v3_.isColorBlindMode = Utils.getNoNil(g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE), false)
	v3_.tiles = {}
	v3_.linkNode = createTransformGroup("FieldCourseVisual_linkNode")
	link(getRootNode(), v3_.linkNode)
	setVisibility(v3_.linkNode, false)
	v3_.loadRequestId = g_i3DManager:loadI3DFileAsync(FieldCourseVisual.VISUALS_FILENAME, true, false, FieldCourseVisual.onVisualsLoaded, v3_, nil)
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_COLORBLIND_MODE], v3_.onColorBlindModeChanged, v3_)
	return v3_
end

-- Local values: _, tile, i, i, j
function FieldCourseVisual:delete()
	if self.loadRequestId ~= nil then
		g_i3DManager:cancelStreamI3DFile(self.loadRequestId)
		self.loadRequestId = nil
	end
	self:setActiveSteeringFieldCourse(nil)
	for _, v5_ in ipairs(self.tiles) do
		v5_:reset()
	end
	if self.rootSegmentsByLength ~= nil then
		for v6_ = #self.rootSegmentsByLength, 1, -1 do
			delete(self.rootSegmentsByLength[v6_])
		end
		self.rootSegmentsByLength = nil
	end
	if self.lineSegmentPoolByLength ~= nil then
		for v7_ = #self.lineSegmentPoolByLength, 1, -1 do
			for v8_ = #self.lineSegmentPoolByLength[v7_], 1, -1 do
				delete(self.lineSegmentPoolByLength[v7_][v8_])
			end
		end
		self.lineSegmentPoolByLength = nil
	end
	if self.linkNode ~= nil then
		delete(self.linkNode)
		self.linkNode = nil
	end
	g_messageCenter:unsubscribeAll(self)
end

-- Local values: _, tile
function FieldCourseVisual:setActiveSteeringFieldCourse(fieldCourse, vehicle)
	self.fieldCourse = fieldCourse
	self.vehicle = vehicle
	for _, v12_ in ipairs(self.tiles) do
		v12_:reset()
	end
	if fieldCourse == nil then
		g_fieldCourseManager:removeUpdateable(self)
		self.fieldCourseSettings = nil
	else
		g_fieldCourseManager:addUpdateable(self)
		self.fieldCourseSettings = fieldCourse.fieldCourseSettings
	end
	setVisibility(self.linkNode, fieldCourse ~= nil)
	self.updateDirty = true
end

-- Local values: cx, _, cz, segment, _, tile, segments, segmentIndex, segment, visualData, _, tile, vx, vy, vz, qx, qy, qz, qw, extendX, extendY, extendZ
function FieldCourseVisual:update(dt)
	if self.vehicle == nil or (not self.vehicle:getIsActiveForInput(true) or (g_noHudModeEnabled or not g_gameSettings:getValue(GameSettings.SETTING.STEERING_ASSIST_LINES))) then
		setVisibility(self.linkNode, false)
		return
	end
	setVisibility(self.linkNode, true)
	local v14_, _, v15_ = getWorldTranslation(g_cameraManager:getActiveCamera())
	local v16_ = self.lastCameraPosition[1] - v14_
	if math.abs(v16_) <= FieldCourseVisual.ACTIVE_LINE_UPDATE_THRESHOLD then
		local v17_ = self.lastCameraPosition[2] - v15_
		if math.abs(v17_) <= FieldCourseVisual.ACTIVE_LINE_UPDATE_THRESHOLD and not self.updateDirty then
			::l9::
			if self.lastActiveSegmentIndex ~= self.fieldCourse.currentSegmentIndex or (self.lastActiveSegmentIsLeft ~= self.fieldCourse.currentSegmentIsLeft or (self.lastSteeringIsEnabled ~= self.fieldCourse.vehicleSteeringEnabled or self.updateDirty)) then
				if self.lastActiveSegmentIndex ~= self.fieldCourse.currentSegmentIndex or self.updateDirty then
					local v18_ = self.fieldCourse.segments[self.fieldCourse.currentSegmentIndex]
					if v18_ == nil then
						self.toolSideSegmentLeft = nil
						self.toolSideSegmentRight = nil
						self.toolSideOffsetSegmentLeft = nil
						self.toolSideOffsetSegmentRight = nil
					else
						self.toolSideSegmentLeft = table.clone(v18_, 3)
						FieldCourseUtil.segmentApplySideOffset(self.toolSideSegmentLeft, -(self.fieldCourseSettings.implementWidth * 0.5))
						self.toolSideSegmentRight = table.clone(v18_, 3)
						FieldCourseUtil.segmentApplySideOffset(self.toolSideSegmentRight, self.fieldCourseSettings.implementWidth * 0.5)
						if not (v18_.isHeadlandSegment or v18_.isIslandSegment) then
							FieldCourseUtil.extendSegmentToBoundary(self.toolSideSegmentLeft.positions, self.fieldCourse.rootBoundaryLine)
							FieldCourseUtil.extendSegmentToBoundary(self.toolSideSegmentRight.positions, self.fieldCourse.rootBoundaryLine)
						end
						if self.fieldCourseSettings.sideOffset ~= 0 then
							self.toolSideOffsetSegmentLeft = table.clone(v18_, 3)
							FieldCourseUtil.segmentApplySideOffset(self.toolSideOffsetSegmentLeft, self.fieldCourseSettings.sideOffset)
							self.toolSideOffsetSegmentRight = table.clone(v18_, 3)
							FieldCourseUtil.segmentApplySideOffset(self.toolSideOffsetSegmentRight, -self.fieldCourseSettings.sideOffset)
						end
					end
					for _, v19_ in ipairs(self.tiles) do
						if v19_.isValid then
							v19_:resetAdditionalSegments()
							v19_:fillAdditionalTileSegment(self.toolSideSegmentLeft, self.fieldCourse.currentSegmentIndex, true, false, false)
							v19_:fillAdditionalTileSegment(self.toolSideSegmentRight, self.fieldCourse.currentSegmentIndex, true, false, false)
							v19_:fillAdditionalTileSegment(self.toolSideOffsetSegmentLeft, self.fieldCourse.currentSegmentIndex, false, true, false)
							v19_:fillAdditionalTileSegment(self.toolSideOffsetSegmentRight, self.fieldCourse.currentSegmentIndex, false, false, true)
						end
					end
				end
				local v20_ = self.fieldCourse.segments
				for v21_, _ in ipairs(v20_) do
					local v22_
					if self.fieldCourse.vehicleSteeringEnabled then
						if v21_ == self.fieldCourse.currentSegmentIndex then
							v22_ = FieldCourseVisual.VISUALS[self.isColorBlindMode].ACTIVE
						else
							v22_ = FieldCourseVisual.VISUALS[self.isColorBlindMode].HIDDEN
						end
					elseif v21_ == self.fieldCourse.currentSegmentIndex then
						v22_ = FieldCourseVisual.VISUALS[self.isColorBlindMode].AVAILABLE
					elseif self.fieldCourse.segmentStates[v21_] then
						v22_ = FieldCourseVisual.VISUALS[self.isColorBlindMode].WORKED
					else
						v22_ = FieldCourseVisual.VISUALS[self.isColorBlindMode].INACTIVE
					end
					self.segmentIndexToData[v21_] = v22_
				end
				for _, v23_ in ipairs(self.tiles) do
					if v23_.isValid then
						v23_:setSegmentData(self.segmentIndexToData, self.fieldCourse.vehicleSteeringEnabled, self.fieldCourse.currentSegmentIsLeft, self.fieldCourse.currentSegmentIndex)
					end
				end
				self.lastActiveSegmentIndex = self.fieldCourse.currentSegmentIndex
				self.lastActiveSegmentIsLeft = self.fieldCourse.currentSegmentIsLeft
				self.lastSteeringIsEnabled = self.fieldCourse.vehicleSteeringEnabled
			end
			local v24_, v25_, v26_, v27_, v28_, v29_, v30_, v31_, v32_, v33_ = self.vehicle:getAIRootNodeBoundingBox()
			local v34_ = v31_ + 1
			local v35_ = v32_ + 1
			local v36_ = v33_ + 1
			setMaterialCustomParameter(self.lineMaterial, "boxPosition", v24_, v25_, v26_, 0, true)
			setMaterialCustomParameter(self.lineMaterial, "boxQuaternion", v27_, v28_, v29_, v30_, true)
			setMaterialCustomParameter(self.lineMaterial, "boxHalfExtent", v34_, v35_, v36_, 0, true)
			self.updateDirty = false
			return
		end
	end
	self:updateTiles(v14_, v15_)
	self.lastCameraPosition[1] = v14_
	self.lastCameraPosition[2] = v15_
	goto l9
end

-- Local values: halfTerrainSize, numRows, centerX, centerZ, centerTileX, centerTiltZ, numVisibleTiles, tileClipDistance, _, tile, x, z, tx, tz, distance, tileIndex, _, tile, x, z, tx, tz, distance, tileIndex, hasTile, _, tile, tileToUse, _, tile, _, tile
function FieldCourseVisual:updateTiles(cx, cz)
	local v40_ = g_currentMission.terrainSize * 0.5
	local v41_ = cx + v40_
	local v42_ = cz + v40_
	local v43_ = g_currentMission.terrainSize / FieldCourseVisualTile.TILE_SIZE
	local v44_ = v41_ / FieldCourseVisualTile.TILE_SIZE
	local v45_ = v42_ / FieldCourseVisualTile.TILE_SIZE
	local v46_ = MathUtil.round(v44_)
	local v47_ = MathUtil.round(v45_)
	local v48_ = FieldCourseVisual.NUM_VISIBLE_TILES
	local v49_ = FieldCourseVisual.NUM_VISIBLE_TILES + 0.71
	for _, v50_ in ipairs(self.tiles) do
		v50_.isValid = false
	end
	for v51_ = -v48_, v48_ do
		for v52_ = -v48_, v48_ do
			local v53_ = v46_ + v51_
			local v54_ = v47_ + v52_
			if MathUtil.vector2Length(v53_ - v44_, v54_ - v45_) < v49_ then
				local v55_ = v53_ + v54_ * v43_
				for _, v56_ in ipairs(self.tiles) do
					if v56_.index == v55_ then
						v56_.isValid = true
						break
					end
				end
			end
		end
	end
	for v57_ = -v48_, v48_ do
		for v58_ = -v48_, v48_ do
			local v59_ = v46_ + v57_
			local v60_ = v47_ + v58_
			if MathUtil.vector2Length(v59_ - v44_, v60_ - v45_) < v49_ then
				local v61_ = v59_ + v60_ * v43_
				local v62_ = false
				for _, v63_ in ipairs(self.tiles) do
					if v63_.index == v61_ then
						v62_ = true
					end
				end
				if not v62_ then
					local v64_ = nil
					for _, v65_ in ipairs(self.tiles) do
						if not v65_.isValid then
							v64_ = v65_
							break
						end
					end
					if v64_ == nil then
						v64_ = FieldCourseVisualTile.new(self)
						local v66_ = self.tiles
						table.insert(v66_, v64_)
					end
					v64_:init(v61_)
					self.updateDirty = true
				end
			end
		end
	end
	for _, v67_ in ipairs(self.tiles) do
		if not v67_.isValid and v67_.index >= 0 then
			v67_:reset()
		end
	end
end

function FieldCourseVisual:getMaxVisualLineLength()
	return #self.rootSegmentsByLength
end

-- Local values: absLength, lineSegmentPool, lineSegment, lineSegment
function FieldCourseVisual:getVisualSegment(length)
	local v71_ = MathUtil.round(length)
	local v72_ = #self.rootSegmentsByLength
	local v73_ = math.clamp(v71_, 1, v72_)
	local v74_ = self.lineSegmentPoolByLength[v73_]
	if #v74_ > 0 then
		local v75_ = v74_[1]
		table.remove(v74_, 1)
		setVisibility(v75_, true)
		return v75_
	end
	local v76_ = clone(self.rootSegmentsByLength[v73_], false, false, false)
	link(self.linkNode, v76_)
	setVisibility(v76_, true)
	setMaterial(v76_, self.lineMaterial, 0)
	return v76_
end

-- Local values: absLength, lineSegmentPool
function FieldCourseVisual:releaseVisualSegment(lineSegment)
	local v79_ = getUserAttribute(lineSegment, "segmentLength")
	local v80_ = self.lineSegmentPoolByLength[v79_]
	if v80_ ~= nil then
		table.insert(v80_, lineSegment)
		setVisibility(lineSegment, false)
	end
end

-- Local values: i, lineSegment, i
function FieldCourseVisual:onVisualsLoaded(i3dNode)
	if i3dNode ~= 0 then
		for v83_ = 1, getNumOfChildren(i3dNode) do
			local v84_ = getChildAt(i3dNode, v83_ - 1)
			setVisibility(v84_, false)
			setObjectMask(v84_, 127)
			setUserAttribute(v84_, "segmentLength", UserAttributeType.INTEGER, v83_)
			self.rootSegmentsByLength[v83_] = v84_
			self.lineSegmentPoolByLength[v83_] = {}
			if self.lineMaterial == nil then
				setShaderParameter(v84_, "terrainOffset", math.random(), 0, 0, 0, false)
				self.lineMaterial = getMaterial(v84_, 0)
				setMaterialCustomParameter(self.lineMaterial, "terrainOffset", FieldCourseVisual.TERRAIN_OFFSET, 0, 0, 0, true)
			end
		end
		if self.linkNode ~= nil then
			for v85_ = 1, #self.rootSegmentsByLength do
				link(self.linkNode, self.rootSegmentsByLength[v85_])
			end
		end
		delete(i3dNode)
	end
	self.loadRequestId = nil
end

function FieldCourseVisual:onColorBlindModeChanged()
	self.isColorBlindMode = Utils.getNoNil(g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE), false)
	self.updateDirty = true
end
