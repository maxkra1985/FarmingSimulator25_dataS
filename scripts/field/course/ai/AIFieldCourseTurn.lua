-- Local values: AIFieldCourseTurn_mt
AIFieldCourseTurn = {}
local AIFieldCourseTurn_mt = Class(AIFieldCourseTurn)

-- Upvalues: AIFieldCourseTurn_mt
-- Local values: self
function AIFieldCourseTurn.new(turnData, segments)
	-- upvalues: (copy) AIFieldCourseTurn_mt
	local v4_ = AIFieldCourseTurn_mt
	local v5_ = setmetatable({}, v4_)
	v5_.turnData = turnData
	v5_.segments = segments
	v5_.offset = 0
	v5_.cost = 1
	v5_.numNextSegmentIntersections = 0
	v5_.numBoundaryIntersections = 0
	v5_.length = 0
	v5_:updateLength()
	return v5_
end

-- Local values: _, segment
function AIFieldCourseTurn:updateLength()
	self.length = 0
	for _, v7_ in ipairs(self.segments) do
		self.length = self.length + v7_:getLength()
	end
end

-- Local values: position, x, z, phi, _, segment, delta, wx, wz
function AIFieldCourseTurn:getPosition(alpha)
	local v10_ = alpha * self.length
	local v11_ = 0
	local v12_ = 0
	local v13_ = 0
	for _, v14_ in ipairs(self.segments) do
		local v15_ = math.min(v10_, v14_:getLength())
		v11_, v12_, v13_ = v14_:move(v11_, v12_, v13_, v15_, self.turnData.turnRadius)
		v10_ = v10_ - v15_
		if v10_ <= 0 then
			break
		end
	end
	return self.turnData.sx + self.turnData.sDirX * v11_ - self.turnData.sDirZ * v12_, self.turnData.sz + self.turnData.sDirZ * v11_ + self.turnData.sDirX * v12_, v13_
end

-- Local values: remainingLength, segmentIndex, remainingSegmentLength, x, z, phi, segment, delta, wx, wz, startX, startZ, startPhi, i, wx, wz
function AIFieldCourseTurn:iterate(distance, func, extraLength)
	if #self.segments ~= 0 then
		local v20_ = distance / self.turnData.turnRadius
		if extraLength ~= nil then
			extraLength = extraLength / self.turnData.turnRadius
		end
		local v21_ = self.length
		func(self.turnData.sx, self.turnData.sz, self.segments[1].drivingDirection)
		local v22_ = 1
		local v23_ = nil
		local v24_ = 0
		local v25_ = 0
		local v26_ = 0
		while v21_ > 0 and self.segments[v22_] ~= nil do
			local v27_ = self.segments[v22_]
			if v23_ == nil then
				v23_ = v27_:getLength()
			end
			local v28_ = math.min(v20_, v21_, v23_)
			local v29_, v30_, v31_ = v27_:move(v24_, v25_, v26_, v28_, self.turnData.turnRadius)
			func(self.turnData.sx + self.turnData.sDirX * v29_ - self.turnData.sDirZ * v30_, self.turnData.sz + self.turnData.sDirZ * v29_ + self.turnData.sDirX * v30_, v27_.drivingDirection, false)
			v21_ = v21_ - v28_
			local v32_ = v23_ - v28_
			v23_ = math.min(v32_, v21_)
			if v23_ <= 0 then
				if extraLength == nil or extraLength <= 0 then
					v26_ = v31_
					v25_ = v30_
					v24_ = v29_
				else
					v26_ = v31_
					v25_ = v30_
					v24_ = v29_
					for _ = 0, extraLength, v20_ do
						v29_, v30_, v31_ = v27_:move(v29_, v30_, v31_, math.min(v20_, extraLength), self.turnData.turnRadius)
						func(self.turnData.sx + self.turnData.sDirX * v29_ - self.turnData.sDirZ * v30_, self.turnData.sz + self.turnData.sDirZ * v29_ + self.turnData.sDirX * v30_, v27_.drivingDirection, true)
					end
				end
				v22_ = v22_ + 1
				v23_ = nil
			else
				v26_ = v31_
				v25_ = v30_
				v24_ = v29_
			end
		end
	end
end

-- Local values: offset, _, segment, hasDirectionChange, i, fieldBoundaryLine, _, island, boundary, checkIntersection, segmentIndex, segmentPosition, x, z, lx, lz, phi, lastX, lastZ, x1, z1, x2, z2, rootIntersections, _, island, boundary, segment, delta
function AIFieldCourseTurn:updateCost(allowProtectedBoundary, preferOneDrivingDirection)
	self.cost = 1
	self.numNextSegmentIntersections = 0
	self.numBoundaryIntersections = 0
	local v36_ = self.turnData.startOffset
	local v37_ = math.abs(v36_)
	local v38_ = self.turnData.endOffset
	local v39_ = v37_ + math.abs(v38_)
	if v39_ > 0 then
		self.cost = self.cost * (1 + v39_ / 10)
	end
	for _, v40_ in ipairs(self.segments) do
		if v40_.drivingDirection < 0 then
			self.cost = self.cost * 1.1
		end
	end
	local v41_ = false
	for v42_ = 1, #self.segments - 1 do
		if self.segments[v42_].drivingDirection ~= self.segments[v42_ + 1].drivingDirection then
			v41_ = true
		end
	end
	if not v41_ then
		if preferOneDrivingDirection then
			self.cost = self.cost * 0.7
		else
			self.cost = self.cost * 0.9
		end
	end
	local v_u_43_ = self.turnData.protectedBoundary.boundaryLine
	if allowProtectedBoundary then
		v_u_43_ = self.turnData.fieldRootBoundary.boundaryLine
	end
	if not (FieldCourseUtil.getIsPointInsideBoundary(self.turnData.sx, self.turnData.sz, v_u_43_) or FieldCourseUtil.getIsPointInsideBoundary(self.turnData.ex, self.turnData.ez, v_u_43_)) then
		self.cost = self.cost * 2
		self.numBoundaryIntersections = self.numBoundaryIntersections + 2
	end
	for _, v44_ in ipairs(self.turnData.islands) do
		local v45_ = v44_.protectedBoundary
		if allowProtectedBoundary then
			v45_ = v44_.rootBoundary
		end
		if FieldCourseUtil.getIsPointInsideBoundary(self.turnData.sx, self.turnData.sz, v45_.boundaryLine) and FieldCourseUtil.getIsPointInsideBoundary(self.turnData.ex, self.turnData.ez, v45_.boundaryLine) then
			self.cost = self.cost * 2
			self.numBoundaryIntersections = self.numBoundaryIntersections + 2
		end
	end
	local function v55_(p46_, p47_, p48_, p49_)
		-- upvalues: (copy) self, (ref) v_u_43_, (copy) allowProtectedBoundary
		if self.turnData.segment2 ~= nil then
			local v50_, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(p46_, p47_, p48_, p49_, self.turnData.segment2.positions)
			if v50_ then
				self.cost = self.cost * 1.25
				self.numNextSegmentIntersections = self.numNextSegmentIntersections + 1
			end
		end
		local v51_, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(p46_, p47_, p48_, p49_, v_u_43_)
		if v51_ then
			self.cost = self.cost * 2
			self.numBoundaryIntersections = self.numBoundaryIntersections + 1
		end
		for _, v52_ in ipairs(self.turnData.islands) do
			local v53_ = v52_.protectedBoundary
			if allowProtectedBoundary then
				v53_ = v52_.rootBoundary
			end
			local v54_, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(p46_, p47_, p48_, p49_, v53_.boundaryLine)
			if v54_ then
				self.cost = self.cost * 2
				self.numBoundaryIntersections = self.numBoundaryIntersections + 1
			end
		end
		return self.numBoundaryIntersections == 0
	end
	local v56_ = 1
	local v57_ = nil
	local v58_ = 0
	local v59_ = 0
	local v60_ = 0
	local v61_ = self.turnData.sx
	local v62_ = self.turnData.sz
	if self.turnData.startOffset < 0 then
		if not v55_(self.turnData.originalTurnData.sx, self.turnData.originalTurnData.sz, self.turnData.sx, self.turnData.sz) then
			return
		end
	elseif self.turnData.startOffset > 0 then
		local v63_ = self.turnData.originalTurnData.sx
		local v64_ = self.turnData.originalTurnData.sz
		local v65_ = self.turnData.sx
		local v66_ = self.turnData.sz
		local v67_ = FieldCourseUtil.getSegmentNumBoundaryIntersections(v63_, v64_, v65_, v66_, v_u_43_)
		if v67_ > 1 then
			self.numBoundaryIntersections = 1
			return
		end
		for _, v68_ in ipairs(self.turnData.islands) do
			local v69_ = v68_.protectedBoundary
			if allowProtectedBoundary then
				v69_ = v68_.rootBoundary
			end
			if v67_ + FieldCourseUtil.getSegmentNumBoundaryIntersections(v63_, v64_, v65_, v66_, v69_.boundaryLine) > 1 then
				self.numBoundaryIntersections = 1
				return
			end
		end
	end
	::l30::
	local v70_ = self.segments[v56_]
	while v70_ ~= nil and v70_.distance <= 1e-6 do
		v56_ = v56_ + 1
		v70_ = self.segments[v56_]
	end
	if v70_ == nil then
		if self.turnData.endOffset < 0 then
			v55_(self.turnData.originalTurnData.ex, self.turnData.originalTurnData.ez, self.turnData.ex, self.turnData.ez)
		end
		return
	end
	if v57_ == nil then
		v57_ = v70_.distance
	end
	local v71_ = math.min(1, v57_)
	if v70_.segmentType == AIFieldCourseTurnSegmentType.STRAIGHT then
		v71_ = v70_.distance
	end
	v58_, v59_, v60_ = v70_:move(v58_, v59_, v60_, v71_, self.turnData.turnRadius)
	v57_ = v57_ - v71_
	if v57_ <= 0 then
		v56_ = v56_ + 1
		v57_ = nil
	end
	local v72_ = self.turnData.sx + self.turnData.sDirX * v58_ - self.turnData.sDirZ * v59_
	local v73_ = self.turnData.sz + self.turnData.sDirZ * v58_ + self.turnData.sDirX * v59_
	if not v55_(v61_, v62_, v72_, v73_) then
		return
	end
	v61_ = v72_
	v62_ = v73_
	goto l30
end

-- Local values: backwardLength, _, segment
function AIFieldCourseTurn:getOverallCost()
	local v75_ = 0
	for _, v76_ in ipairs(self.segments) do
		if v76_.drivingDirection < 0 then
			v75_ = v75_ + v76_.distance
		end
	end
	return (self.length - v75_) * self.cost + v75_ * self.cost * 1.15
end

-- Local values: x, z, _, steps, step, position, lastX, lastZ, lastY, alpha, y, sr, sg, sb
function AIFieldCourseTurn:draw(r, g, b)
	if self.length > 0 then
		local v81_ = self.turnData.sx
		local v82_ = self.turnData.sz
		local v83_ = self.length / (1 / self.turnData.turnRadius)
		local v84_ = math.ceil(v83_)
		local v85_ = self.length / v84_
		for v86_ = v85_, self.length + 0.01, v85_ do
			local v87_ = getTerrainHeightAtWorldPos(g_terrainNode, v81_, 0, v82_) + 0.5
			local v88_ = v86_ / self.length
			local v89_, v90_, _ = self:getPosition(v88_)
			local v91_ = getTerrainHeightAtWorldPos(g_terrainNode, v89_, 0, v90_) + 0.5
			local v92_ = r or v88_
			local v93_ = g or 1 - v88_
			local v94_ = b or 0
			drawDebugLine(v81_, v87_, v82_, v92_, v93_, v94_, v89_, v91_, v90_, v92_, v93_, v94_, true)
			v82_ = v90_
			v81_ = v89_
		end
	end
end
