-- Local values: FieldCourseVisualTile_mt
FieldCourseVisualTile = {}
FieldCourseVisualTile.TILE_SIZE = 32
local FieldCourseVisualTile_mt = Class(FieldCourseVisualTile)

-- Upvalues: FieldCourseVisualTile_mt
-- Local values: self
function FieldCourseVisualTile.new(fieldCourseVisual)
	-- upvalues: (copy) FieldCourseVisualTile_mt
	local v3_ = FieldCourseVisualTile_mt
	local v4_ = setmetatable({}, v3_)
	v4_.fieldCourseVisual = fieldCourseVisual
	v4_.visualSegments = {}
	v4_.toolSideSegments = {}
	v4_.sideOffsetSegmentsLeft = {}
	v4_.sideOffsetSegmentsRight = {}
	v4_.index = -1
	v4_.isValid = false
	v4_.foliageDataPlaneId = g_fruitTypeManager:getDefaultDataPlaneId()
	return v4_
end

-- Local values: i, i, i, i
function FieldCourseVisualTile:reset()
	for v6_ = #self.visualSegments, 1, -1 do
		self.fieldCourseVisual:releaseVisualSegment(self.visualSegments[v6_])
		table.remove(self.visualSegments, v6_)
	end
	for v7_ = #self.toolSideSegments, 1, -1 do
		self.fieldCourseVisual:releaseVisualSegment(self.toolSideSegments[v7_])
		table.remove(self.toolSideSegments, v7_)
	end
	for v8_ = #self.sideOffsetSegmentsLeft, 1, -1 do
		self.fieldCourseVisual:releaseVisualSegment(self.sideOffsetSegmentsLeft[v8_])
		table.remove(self.sideOffsetSegmentsLeft, v8_)
	end
	for v9_ = #self.sideOffsetSegmentsRight, 1, -1 do
		self.fieldCourseVisual:releaseVisualSegment(self.sideOffsetSegmentsRight[v9_])
		table.remove(self.sideOffsetSegmentsRight, v9_)
	end
	self.index = -1
	self.isValid = false
end

-- Local values: numRows, tilePositionZ, tilePositionX
function FieldCourseVisualTile:init(index)
	self.index = index
	self.isValid = true
	local v12_ = g_currentMission.terrainSize / FieldCourseVisualTile.TILE_SIZE
	local v13_ = index / v12_
	local v14_ = math.floor(v13_)
	self.tileMinX = (index - v14_ * v12_) * FieldCourseVisualTile.TILE_SIZE - g_currentMission.terrainSize * 0.5
	self.tileMinZ = v14_ * FieldCourseVisualTile.TILE_SIZE - g_currentMission.terrainSize * 0.5
	self.tileMaxX = self.tileMinX + FieldCourseVisualTile.TILE_SIZE
	self.tileMaxZ = self.tileMinZ + FieldCourseVisualTile.TILE_SIZE
	self:fillTile(self.fieldCourseVisual.fieldCourse.segments, self.visualSegments, true)
end

-- Local values: i, segmentIndex, segment
function FieldCourseVisualTile:fillTile(segments, target, doReset)
	if doReset then
		for v19_ = #target, 1, -1 do
			self.fieldCourseVisual:releaseVisualSegment(target[v19_])
			table.remove(target, v19_)
		end
	end
	for v20_, v21_ in ipairs(segments) do
		self:fillTileBySegment(v21_, v20_, target)
	end
end

-- Local values: i, i, i
function FieldCourseVisualTile:resetAdditionalSegments()
	for v23_ = #self.toolSideSegments, 1, -1 do
		self.fieldCourseVisual:releaseVisualSegment(self.toolSideSegments[v23_])
		table.remove(self.toolSideSegments, v23_)
	end
	for v24_ = #self.sideOffsetSegmentsLeft, 1, -1 do
		self.fieldCourseVisual:releaseVisualSegment(self.sideOffsetSegmentsLeft[v24_])
		table.remove(self.sideOffsetSegmentsLeft, v24_)
	end
	for v25_ = #self.sideOffsetSegmentsRight, 1, -1 do
		self.fieldCourseVisual:releaseVisualSegment(self.sideOffsetSegmentsRight[v25_])
		table.remove(self.sideOffsetSegmentsRight, v25_)
	end
end

function FieldCourseVisualTile:fillAdditionalTileSegment(segment, segmentIndex, isToolSideSegment, isSideOffsetSegmentLeft, isSideOffsetSegmentRight)
	if segment ~= nil then
		if isToolSideSegment then
			self:fillTileBySegment(segment, segmentIndex, self.toolSideSegments)
			return
		end
		if isSideOffsetSegmentLeft then
			self:fillTileBySegment(segment, segmentIndex, self.sideOffsetSegmentsLeft)
			return
		end
		if isSideOffsetSegmentRight then
			self:fillTileBySegment(segment, segmentIndex, self.sideOffsetSegmentsRight)
		end
	end
end

-- Local values: i, p1, p2, sx, sz, ex, ez, p1Inside, p2Inside, intersect, x, z, ix1, iz1, intersect, x, z, z1, z2, x1, x2
function FieldCourseVisualTile:fillTileBySegment(segment, segmentIndex, target)
	for v36_ = 1, #segment.positions - 1 do
		local v37_ = segment.positions[v36_]
		local v38_ = segment.positions[v36_ + 1]
		local v39_ = v37_[1]
		local v40_ = v37_[2]
		local v41_ = v38_[1]
		local v42_ = v38_[2]
		local v43_
		if self.tileMinX <= v39_ and (v39_ <= self.tileMaxX and self.tileMinZ <= v40_) then
			v43_ = v40_ <= self.tileMaxZ
		else
			v43_ = false
		end
		local v44_
		if self.tileMinX <= v41_ and (v41_ <= self.tileMaxX and self.tileMinZ <= v42_) then
			v44_ = v42_ <= self.tileMaxZ
		else
			v44_ = false
		end
		if v43_ and v44_ then
			self:addSegment(v39_, v40_, v41_, v42_, segmentIndex, target)
			::l18::
			if v39_ == self.tileMinX and v41_ == self.tileMinX then
				local v45_ = self.tileMinZ
				local v46_ = self.tileMaxZ
				local v47_ = math.clamp(v40_, v45_, v46_)
				local v48_ = self.tileMinZ
				local v49_ = self.tileMaxZ
				self:addSegment(v39_, v47_, v41_, math.clamp(v42_, v48_, v49_), segmentIndex, target)
			end
			if v40_ == self.tileMinZ and v42_ == self.tileMinZ then
				local v50_ = self.tileMinX
				local v51_ = self.tileMaxX
				local v52_ = math.clamp(v39_, v50_, v51_)
				local v53_ = self.tileMinX
				local v54_ = self.tileMaxX
				self:addSegment(v52_, v40_, math.clamp(v41_, v53_, v54_), v42_, segmentIndex, target)
			end
		else
			if v43_ or v44_ then
				local v55_, v56_, v57_ = MathUtil.getLineSegmentsIntersection(v39_, v40_, v41_, v42_, self.tileMinX, self.tileMinZ, self.tileMaxX, self.tileMinZ)
				if v55_ then
					if v43_ then
						self:addSegment(v39_, v40_, v56_, v57_, segmentIndex, target)
					else
						self:addSegment(v56_, v57_, v41_, v42_, segmentIndex, target)
					end
				else
					local v58_, v59_, v60_ = MathUtil.getLineSegmentsIntersection(v39_, v40_, v41_, v42_, self.tileMinX, self.tileMaxZ, self.tileMaxX, self.tileMaxZ)
					if v58_ then
						if v43_ then
							self:addSegment(v39_, v40_, v59_, v60_, segmentIndex, target)
						else
							self:addSegment(v59_, v60_, v41_, v42_, segmentIndex, target)
						end
					else
						local v61_, v62_, v63_ = MathUtil.getLineSegmentsIntersection(v39_, v40_, v41_, v42_, self.tileMinX, self.tileMinZ, self.tileMinX, self.tileMaxZ)
						if v61_ then
							if v43_ then
								self:addSegment(v39_, v40_, v62_, v63_, segmentIndex, target)
							else
								self:addSegment(v62_, v63_, v41_, v42_, segmentIndex, target)
							end
						else
							local v64_, v65_, v66_ = MathUtil.getLineSegmentsIntersection(v39_, v40_, v41_, v42_, self.tileMaxX, self.tileMinZ, self.tileMaxX, self.tileMaxZ)
							if v64_ then
								if v43_ then
									self:addSegment(v39_, v40_, v65_, v66_, segmentIndex, target)
								else
									self:addSegment(v65_, v66_, v41_, v42_, segmentIndex, target)
								end
							end
						end
					end
				end
				goto l18
			end
			local v67_, v68_, v69_ = MathUtil.getLineSegmentsIntersection(v39_, v40_, v41_, v42_, self.tileMinX, self.tileMinZ, self.tileMaxX, self.tileMinZ)
			if not v67_ then
				v68_ = nil
				v69_ = nil
			end
			local v70_, v71_, v72_ = MathUtil.getLineSegmentsIntersection(v39_, v40_, v41_, v42_, self.tileMinX, self.tileMaxZ, self.tileMaxX, self.tileMaxZ)
			if not v70_ then
				v72_ = v69_
				v71_ = v68_
				goto l40
			end
			if v68_ == nil then
				::l40::
				local v73_, v74_, v75_ = MathUtil.getLineSegmentsIntersection(v39_, v40_, v41_, v42_, self.tileMinX, self.tileMinZ, self.tileMinX, self.tileMaxZ)
				if not v73_ then
					v75_ = v72_
					v74_ = v71_
					goto l45
				end
				if v71_ == nil then
					::l45::
					local v76_, v77_, v78_ = MathUtil.getLineSegmentsIntersection(v39_, v40_, v41_, v42_, self.tileMaxX, self.tileMinZ, self.tileMaxX, self.tileMaxZ)
					if v76_ and v74_ ~= nil then
						self:addSegment(v74_, v75_, v77_, v78_, segmentIndex, target)
					end
					goto l18
				end
				self:addSegment(v71_, v72_, v74_, v75_, segmentIndex, target)
			else
				self:addSegment(v68_, v69_, v71_, v72_, segmentIndex, target)
			end
		end
	end
end

-- Local values: maxLength, dirX, dirZ, length, offset, sx, sz, sy, l, segmentLength, lineSegment, yRot
function FieldCourseVisualTile:addSegment(x1, z1, x2, z2, segmentIndex, target)
	local v86_ = self.fieldCourseVisual:getMaxVisualLineLength()
	local v87_ = x2 - x1
	local v88_ = z2 - z1
	local v89_ = MathUtil.vector2Length(v87_, v88_)
	if v89_ > 0 then
		local v90_ = v87_ / v89_
		local v91_ = v88_ / v89_
		for v92_ = 0, v89_ - 0.01, v86_ do
			local v93_ = x1 + v90_ * v92_
			local v94_ = z1 + v91_ * v92_
			local v95_ = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, v93_, 0, v94_)
			local v96_ = v89_ - v92_
			local v97_ = math.min(v96_, v86_)
			if v97_ > 0 then
				local v98_ = math.ceil(v97_)
				local v99_ = math.min(v98_, v86_)
				local v100_ = self.fieldCourseVisual:getVisualSegment(v99_)
				setTranslation(v100_, v93_, v95_, v94_)
				local v101_ = MathUtil.getYRotationFromDirection(v90_, v91_)
				setRotation(v100_, 0, v101_, 0)
				setUserAttribute(v100_, "segmentIndex", UserAttributeType.INTEGER, segmentIndex)
				setShaderParameter(v100_, "intensitySize", nil, v97_ / v99_, nil, v99_, false)
				table.insert(target, v100_)
			end
		end
	end
end

-- Local values: hasSideOffset, _, segment, segmentIndex, data, visibility, color, borderColor, dashNumLength, toolData, _, segment, color, borderColor, dashNumLength, _, segment, segmentIndex, data, visibility, color, borderColor, dashNumLength, _, segment, segmentIndex, data, visibility, color, borderColor, dashNumLength
function FieldCourseVisualTile:setSegmentData(segmentToData, isEnabled, isLeft, activeSegmentIndex)
	local v106_ = self.fieldCourseVisual.fieldCourseSettings.sideOffset ~= 0
	for _, v107_ in ipairs(self.visualSegments) do
		local v108_ = getUserAttribute(v107_, "segmentIndex")
		local v109_ = segmentToData[v108_]
		if v109_ ~= nil then
			if v106_ and v108_ == activeSegmentIndex then
				v109_ = FieldCourseVisual.VISUALS[self.fieldCourseVisual.isColorBlindMode].INACTIVE
			end
			local v110_ = v109_[4]
			if v110_ then
				local v111_ = v109_[1]
				setShaderParameter(v107_, "emitColor", v111_[1], v111_[2], v111_[3], v111_[4], false)
				setShaderParameter(v107_, "intensitySize", v109_[2], nil, v109_[3], nil, false)
				local v112_ = v109_[5]
				if v112_ == nil then
					setShaderParameter(v107_, "borderColor", nil, nil, nil, 1, false)
				else
					setShaderParameter(v107_, "borderColor", v112_[1], v112_[2], v112_[3], v112_[4], false)
				end
				local v113_ = v109_[6]
				if v113_ == nil then
					setShaderParameter(v107_, "dashNumLength", 0, nil, nil, nil, false)
				else
					setShaderParameter(v107_, "dashNumLength", v113_[1], v113_[2], nil, nil, false)
				end
			end
			setVisibility(v107_, v110_)
		end
	end
	local v114_ = FieldCourseVisual.VISUALS[self.fieldCourseVisual.isColorBlindMode].TOOL_SIDE
	for _, v115_ in ipairs(self.toolSideSegments) do
		local v116_ = v114_[1]
		setShaderParameter(v115_, "emitColor", v116_[1], v116_[2], v116_[3], v116_[4], false)
		setShaderParameter(v115_, "intensitySize", v114_[2], nil, v114_[3], nil, false)
		local v117_ = v114_[5]
		if v117_ == nil then
			setShaderParameter(v115_, "borderColor", nil, nil, nil, 1, false)
		else
			setShaderParameter(v115_, "borderColor", v117_[1], v117_[2], v117_[3], v117_[4], false)
		end
		local v118_ = v114_[6]
		if v118_ == nil then
			setShaderParameter(v115_, "dashNumLength", 0, nil, nil, nil, false)
		else
			setShaderParameter(v115_, "dashNumLength", v118_[1], v118_[2], nil, nil, false)
		end
	end
	for _, v119_ in ipairs(self.sideOffsetSegmentsLeft) do
		local v120_ = segmentToData[getUserAttribute(v119_, "segmentIndex")]
		if v120_ ~= nil then
			local v121_ = v120_[4] and isLeft
			if v121_ then
				local v122_ = v120_[1]
				setShaderParameter(v119_, "emitColor", v122_[1], v122_[2], v122_[3], v122_[4], false)
				setShaderParameter(v119_, "intensitySize", v120_[2], nil, v120_[3], nil, false)
				local v123_ = v120_[5]
				if v123_ == nil then
					setShaderParameter(v119_, "borderColor", nil, nil, nil, 1, false)
				else
					setShaderParameter(v119_, "borderColor", v123_[1], v123_[2], v123_[3], v123_[4], false)
				end
				local v124_ = v120_[6]
				if v124_ == nil then
					setShaderParameter(v119_, "dashNumLength", 0, nil, nil, nil, false)
				else
					setShaderParameter(v119_, "dashNumLength", v124_[1], v124_[2], nil, nil, false)
				end
			end
			setVisibility(v119_, v121_)
		end
	end
	for _, v125_ in ipairs(self.sideOffsetSegmentsRight) do
		local v126_ = segmentToData[getUserAttribute(v125_, "segmentIndex")]
		if v126_ ~= nil then
			local v127_ = v126_[4]
			if v127_ then
				v127_ = not isLeft
			end
			if v127_ then
				local v128_ = v126_[1]
				setShaderParameter(v125_, "emitColor", v128_[1], v128_[2], v128_[3], v128_[4], false)
				setShaderParameter(v125_, "intensitySize", v126_[2], nil, v126_[3], nil, false)
				local v129_ = v126_[5]
				if v129_ == nil then
					setShaderParameter(v125_, "borderColor", nil, nil, nil, 1, false)
				else
					setShaderParameter(v125_, "borderColor", v129_[1], v129_[2], v129_[3], v129_[4], false)
				end
				local v130_ = v126_[6]
				if v130_ == nil then
					setShaderParameter(v125_, "dashNumLength", 0, nil, nil, nil, false)
				else
					setShaderParameter(v125_, "dashNumLength", v130_[1], v130_[2], nil, nil, false)
				end
			end
			setVisibility(v125_, v127_)
		end
	end
end

-- Local values: title
function FieldCourseVisualTile:debugDraw()
	local v132_ = string.format("Tile %d\nNumSegments: %d\nSeg Data Update: %.5fms", self.index, #self.visualSegments, self.segmentDataTime or -1)
	DebugPlane.renderWithPositions(self.tileMinX, 0, self.tileMinZ, self.tileMinX, 0, self.tileMaxZ, self.tileMaxX, 0, self.tileMinZ, self.color, true, false, true, false, v132_, nil)
end
