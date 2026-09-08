-- Local values: SteeringFieldCourse_mt
SteeringFieldCourse = {}
SteeringFieldCourse.NUM_BITS_SEGMENT_INDEX = 11
SteeringFieldCourse.MAX_SEGMENT_INDEX = 2 ^ SteeringFieldCourse.NUM_BITS_SEGMENT_INDEX - 1
local SteeringFieldCourse_mt = Class(SteeringFieldCourse)

-- Upvalues: SteeringFieldCourse_mt
-- Local values: self, i
function SteeringFieldCourse.new(fieldCourse)
	-- upvalues: (copy) SteeringFieldCourse_mt
	local v3_ = SteeringFieldCourse_mt
	local v4_ = setmetatable({}, v3_)
	v4_.fieldCourse = fieldCourse
	v4_.fieldCourseSettings = fieldCourse.fieldCourseSettings
	v4_.segments = fieldCourse.segments
	v4_.rootBoundaryLine = fieldCourse.courseField.fieldRootBoundary.boundaryLine
	v4_.segmentStates = {}
	for v5_ = 1, #v4_.segments do
		v4_.segmentStates[v5_] = false
	end
	v4_.segmentStatesDirty = false
	v4_.currentSegment = nil
	v4_.currentSegmentIndex = -1
	v4_.currentSegmentIsLeft = false
	v4_.vehiclePosition = { 0, 0 }
	v4_.vehicleSteeringEnabled = false
	v4_.vehicleSteeringEnabledTimer = 0
	return v4_
end

function SteeringFieldCourse:writeStream(streamId, connection)
	self:writeSegmentStatesToStream(streamId, connection)
	self.fieldCourse:writeStream(streamId, connection)
end

-- Local values: segmentStates, numSegmentStates, i
function SteeringFieldCourse.readStream(streamId, connection, callback)
	local v_u_12_ = {}
	for v13_ = 1, streamReadUIntN(streamId, SteeringFieldCourse.NUM_BITS_SEGMENT_INDEX) do
		v_u_12_[v13_] = streamReadBool(streamId)
	end
	FieldCourse.readStream(streamId, connection, function(p14_)
		-- upvalues: (copy) v_u_12_, (copy) callback
		if p14_ == nil then
			callback(nil)
		else
			local v15_ = SteeringFieldCourse.new(p14_)
			for v16_ = 1, #v15_.segmentStates do
				v15_.segmentStates[v16_] = v_u_12_[v16_] or false
			end
			callback(v15_)
		end
	end)
end

-- Local values: numSegments, i
function SteeringFieldCourse:writeSegmentStatesToStream(streamId, connection)
	local v19_ = #self.segmentStates
	local v20_ = SteeringFieldCourse.MAX_SEGMENT_INDEX
	local v21_ = math.min(v19_, v20_)
	streamWriteUIntN(streamId, v21_, SteeringFieldCourse.NUM_BITS_SEGMENT_INDEX)
	for v22_ = 1, v21_ do
		streamWriteBool(streamId, self.segmentStates[v22_])
	end
end

-- Local values: numSegmentStates, i, state
function SteeringFieldCourse.readSegmentStatesFromStream(steeringFieldCourse, streamId, connection)
	for v25_ = 1, streamReadUIntN(streamId, SteeringFieldCourse.NUM_BITS_SEGMENT_INDEX) do
		local v26_ = streamReadBool(streamId)
		if steeringFieldCourse ~= nil then
			steeringFieldCourse.segmentStates[v25_] = v26_
		end
	end
end

-- Local values: workedLinesStr, i
function SteeringFieldCourse:saveToXML(xmlFile, key)
	self.fieldCourse:saveToXML(xmlFile, key)
	local v30_ = ""
	for v31_ = 1, #self.segmentStates do
		if self.segmentStates[v31_] then
			v30_ = v30_ .. string.format("%d ", v31_)
		end
	end
	xmlFile:setValue(key .. ".workedLines#indices", string.trim(v30_))
end

-- Local values: workedLinesStr
function SteeringFieldCourse.loadFromXML(xmlFile, key, callback)
	local v_u_35_ = xmlFile:getValue(key .. ".workedLines#indices")
	FieldCourse.loadFromXML(xmlFile, key, function(p36_)
		-- upvalues: (copy) v_u_35_, (copy) callback
		if p36_ == nil then
			callback(nil)
		else
			local v37_ = SteeringFieldCourse.new(p36_)
			local v38_ = string.split(v_u_35_, " ")
			for v39_ = 1, #v38_ do
				local v40_ = v38_[v39_]
				local v41_ = tonumber(v40_)
				if v37_.segmentStates[v41_] ~= nil then
					v37_.segmentStates[v41_] = true
				end
			end
			callback(v37_)
		end
	end)
end

function SteeringFieldCourse:getIsPointInsideBoundary(x, z)
	return self.fieldCourse.courseField == nil and true or self.fieldCourse.courseField:getIsPointInsideBoundary(x, z)
end

-- Local values: maxExtension, minDistanceValid, minDistanceValidSegmentIndex, minDistanceValidIsLeft, index, segment, lx, lz, lDirX, lDirZ, onLineX, onLineZ, distance, isLeft, angle, offsetX, offsetZ, dlx, dlz, isForward, offset, factor
function SteeringFieldCourse:updateVehicleData(dt, steeringEnabled, vx, vz, vDirX, vDirZ, sideOffsetReversed)
	if steeringEnabled ~= self.vehicleSteeringEnabled then
		self.vehicleSteeringEnabled = steeringEnabled
		self.vehicleSteeringEnabledTimer = 0
	end
	local v53_ = self.vehiclePosition
	local v54_ = self.vehiclePosition
	v53_[1] = vx
	v54_[2] = vz
	if steeringEnabled then
		self.vehicleSteeringEnabledTimer = self.vehicleSteeringEnabledTimer + dt
		if self.vehicleSteeringEnabledTimer > 2500 and (self.currentSegmentIndex > 0 and not self.segmentStates[self.currentSegmentIndex]) then
			self.segmentStates[self.currentSegmentIndex] = true
			self.segmentStatesDirty = true
		end
		return false
	end
	local v55_ = self.fieldCourseSettings.implementWidth * self.fieldCourseSettings.numHeadlands
	local v56_ = math.huge
	local v57_ = -1
	local v58_ = false
	for v59_, v60_ in ipairs(self.segments) do
		local v61_, v62_, v63_, v64_, v65_, v66_ = FieldCourseUtil.getClosestExtendedPositionAndDirectionOnSegment(vx, vz, v60_.positions, v55_)
		if v61_ ~= nil then
			local v67_ = MathUtil.vector2Length(vx - v61_, vz - v62_)
			local v68_ = self.fieldCourseSettings.implementWidth * 3
			local v69_ = self.fieldCourseSettings.sideOffset
			local v70_ = v68_ + math.abs(v69_)
			if v67_ < math.min(v70_, 20) then
				local v71_ = nil
				local v72_ = MathUtil.dotProduct(v63_, 0, v64_, vDirX, 0, vDirZ)
				local v73_ = math.acos(v72_)
				if v73_ < 0.8796459430051422 then
					v71_ = true
				elseif v73_ > 2.261946710584651 then
					v71_ = false
				end
				if v71_ ~= nil then
					local v74_ = vx - vDirX
					local v75_ = vz - vDirZ
					local v76_, v77_ = MathUtil.vector2Normalize(v65_ - v74_, v66_ - v75_)
					local v78_ = MathUtil.dotProduct(v76_, 0, v77_, vDirX, 0, vDirZ) > 0
					if sideOffsetReversed then
						v71_ = not v71_
					end
					local v79_ = (v71_ and 1 or -1) * self.fieldCourseSettings.sideOffset
					local v80_ = v61_ + v64_ * v79_
					local v81_ = v62_ - v63_ * v79_
					local v82_ = MathUtil.vector2Length(vx - v80_, vz - v81_)
					if v73_ > 1.5707963267948966 then
						v73_ = 3.141592653589793 - v73_
					end
					local v83_ = v73_ / 0.7853981633974483 - 0.25
					local v84_ = 1 + math.max(v83_, 0)
					if not v78_ then
						v84_ = v84_ * 1.5
					end
					local v85_ = v82_ * v84_
					if v85_ < v56_ then
						v58_ = v71_
						v57_ = v59_
						v56_ = v85_
					end
				end
			end
		end
	end
	return self:setCurrentSegmentIndex(v57_, v58_)
end

function SteeringFieldCourse:setCurrentSegmentIndex(segmentIndex, isLeft)
	if segmentIndex == self.currentSegmentIndex and isLeft == self.currentSegmentIsLeft then
		return false
	end
	self.currentSegment = self.segments[segmentIndex]
	if self.currentSegment == nil then
		self.currentSegmentIndex = -1
		self.currentSegmentIsLeft = false
	else
		self.currentSegmentIndex = segmentIndex
		if isLeft == nil then
			self.currentSegmentIsLeft = false
		else
			self.currentSegmentIsLeft = isLeft
		end
		if self.fieldCourseSettings.sideOffset ~= 0 then
			if self.currentSegmentIsLeft then
				self.currentSegment = table.clone(self.currentSegment, 3)
				FieldCourseBoundary.segmentApplySideOffset(self.currentSegment, self.fieldCourseSettings.sideOffset)
			else
				self.currentSegment = table.clone(self.currentSegment, 3)
				FieldCourseBoundary.segmentApplySideOffset(self.currentSegment, -self.fieldCourseSettings.sideOffset)
			end
		end
	end
	return true
end

function SteeringFieldCourse:resetCurrentSegment()
	self.vehicleSteeringEnabled = false
	if self.currentSegment == nil then
		return false
	end
	self.currentSegment = nil
	self.currentSegmentIndex = -1
	self.currentSegmentIsLeft = false
	return true
end

-- Local values: minDistance, minDistanceIndex, minDistanceHitX, minDistanceHitZ, numPositions, i, x1, z1, x2, z2, dirX, dirZ, length, dot, hitX, hitZ, distance
function SteeringFieldCourse.getClosestPositionSegment(segment, wx, wz)
	local v93_ = math.huge
	local v94_ = 0
	local v95_ = 0
	local v96_ = -1
	for v97_ = 1, #segment.positions - 1 do
		local v98_ = segment.positions[v97_][1]
		local v99_ = segment.positions[v97_][2]
		local v100_ = segment.positions[v97_ + 1][1]
		local v101_ = segment.positions[v97_ + 1][2]
		local v102_ = v100_ - v98_
		local v103_ = v101_ - v99_
		local v104_ = MathUtil.vector2Length(v102_, v103_)
		local v105_ = v102_ / v104_
		local v106_ = v103_ / v104_
		local v107_ = MathUtil.getProjectOnLineParameter(wx, wz, v98_, v99_, v105_, v106_)
		if v107_ >= 0 and v107_ <= v104_ then
			local v108_ = v98_ + v105_ * v107_
			local v109_ = v99_ + v106_ * v107_
			local v110_ = MathUtil.vector2Length(v108_ - wx, v109_ - wz)
			if v110_ < v93_ then
				v96_ = v97_
				v95_ = v109_
				v94_ = v108_
				v93_ = v110_
			end
		end
	end
	return v94_, v95_, v96_
end

-- Local values: segment, numPositions, distanceToEnd, wx, y, wz, ox, _, oz, minDistanceHitX, minDistanceHitZ, minDistanceIndex, x1, z1, x2, z2, segmentLength, minDistanceOffsetHitX, minDistanceOffsetHitZ, minDistanceOffsetIndex, tX, _, tZ, x1, z1, x2, z2, x3, z3, x4, z4, startDistance, endDistance, dirX, dirZ, dot, hitX, hitZ, tX, _, tZ, dirX, dirZ, dot, hitX, hitZ, tX, _, tZ
function SteeringFieldCourse:getSteeringTarget(aiRootNode, lookAHeadDistance, sideOffsetReversed)
	if self.currentSegment == nil then
		return 0, 0, nil
	else
		local v114_ = self.currentSegment
		local v115_ = #v114_.positions
		local v116_ = nil
		local v117_, v118_, v119_ = getWorldTranslation(aiRootNode)
		local v120_, _, v121_ = localToWorld(aiRootNode, 0, 0, lookAHeadDistance)
		local v122_, v123_, v124_ = SteeringFieldCourse.getClosestPositionSegment(v114_, v117_, v119_)
		if v124_ > 0 then
			if v124_ == 1 then
				local v125_ = v114_.positions[1][1]
				local v126_ = v114_.positions[1][2]
				local v127_ = v114_.positions[2][1]
				local v128_ = v114_.positions[2][2]
				local v129_ = MathUtil.vector2Length(v127_ - v125_, v128_ - v126_)
				v116_ = MathUtil.vector2Length(v122_ - v125_, v123_ - v126_)
				if v115_ == 2 and v129_ * 0.5 < v116_ then
					v116_ = v129_ - v116_
				end
			elseif v124_ == v115_ - 1 then
				v116_ = MathUtil.vector2Length(v122_ - v114_.positions[v115_][1], v123_ - v114_.positions[v115_][2])
			end
			local v130_, v131_, v132_ = SteeringFieldCourse.getClosestPositionSegment(v114_, v120_, v121_)
			if v132_ > 0 then
				local v133_, _, v134_ = worldToLocal(aiRootNode, v130_, v118_, v131_)
				return v133_, v134_, v116_
			end
		end
		local v135_ = v114_.positions[1][1]
		local v136_ = v114_.positions[1][2]
		local v137_ = v114_.positions[2][1]
		local v138_ = v114_.positions[2][2]
		local v139_ = v114_.positions[v115_][1]
		local v140_ = v114_.positions[v115_][2]
		local v141_ = v114_.positions[v115_ - 1][1]
		local v142_ = v114_.positions[v115_ - 1][2]
		if MathUtil.vector2Length(v135_ - v120_, v136_ - v121_) < MathUtil.vector2Length(v139_ - v120_, v140_ - v121_) then
			local v143_, v144_ = MathUtil.vector2Normalize(v135_ - v137_, v136_ - v138_)
			local v145_ = MathUtil.getProjectOnLineParameter(v120_, v121_, v135_, v136_, v143_, v144_)
			local v146_ = v135_ + v143_ * v145_
			local v147_ = v136_ + v144_ * v145_
			local v148_, _, v149_ = worldToLocal(aiRootNode, v146_, v118_, v147_)
			return v148_, v149_, v116_
		else
			local v150_, v151_ = MathUtil.vector2Normalize(v139_ - v141_, v140_ - v142_)
			local v152_ = MathUtil.getProjectOnLineParameter(v120_, v121_, v139_, v140_, v150_, v151_)
			local v153_ = v139_ + v150_ * v152_
			local v154_ = v140_ + v151_ * v152_
			local v155_, _, v156_ = worldToLocal(aiRootNode, v153_, v118_, v154_)
			return v155_, v156_, v116_
		end
	end
end

function SteeringFieldCourse:draw()
	if self.fieldCourse.courseField ~= nil then
		self.fieldCourse.courseField:draw()
	end
	if self.fieldCourse.fieldCourseSettings ~= nil then
		self.fieldCourse.fieldCourseSettings:draw()
	end
end

function SteeringFieldCourse.registerXMLPaths(schema, path)
	FieldCourseSettings.registerXMLPaths(schema, path .. ".fieldCourseSettings")
	FieldCourseField.registerXMLPaths(schema, path .. ".field")
	schema:register(XMLValueType.STRING, path .. ".workedLines#indices", "List of worked line indices")
end
