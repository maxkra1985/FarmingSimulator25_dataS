-- Local values: ReedsSheppPath_mt, getPolarCoordinates, normalizeRotation
ReedsSheppPath = {}
local ReedsSheppPath_mt = Class(ReedsSheppPath)

-- Upvalues: ReedsSheppPath_mt
-- Local values: self, z, _, x, dx, _, dz
function ReedsSheppPath.new(turnData, forcedDirection)
	-- upvalues: (copy) ReedsSheppPath_mt
	local v4_ = ReedsSheppPath_mt
	local v5_ = setmetatable({}, v4_)
	v5_.turnData = turnData
	v5_.forcedDirection = forcedDirection or 0
	v5_.sAngle = MathUtil.getYRotationFromDirection(turnData.sDirX, turnData.sDirZ)
	v5_.eAngle = MathUtil.getYRotationFromDirection(turnData.eDirX, turnData.eDirZ)
	v5_.helperTransformGroup = createTransformGroup("helper")
	link(getRootNode(), v5_.helperTransformGroup)
	setTranslation(v5_.helperTransformGroup, turnData.sx, 0, turnData.sz)
	setDirection(v5_.helperTransformGroup, turnData.sDirX, 0, turnData.sDirZ, 0, 1, 0)
	local v6_, _, v7_ = worldToLocal(v5_.helperTransformGroup, turnData.ex, 0, turnData.ez)
	local v8_, _, v9_ = worldDirectionToLocal(v5_.helperTransformGroup, turnData.eDirX, 0, turnData.eDirZ)
	v5_.phi = MathUtil.getYRotationFromDirection(v8_, v9_)
	local v10_ = v6_ / turnData.turnRadius
	local v11_ = v7_ / turnData.turnRadius
	v5_.z = v10_
	v5_.x = v11_
	delete(v5_.helperTransformGroup)
	return v5_
end

-- Local values: _, func, segments, _, func, segments, segments
function ReedsSheppPath:generate(callback)
	if self.forcedDirection == 0 then
		for _, v14_ in pairs(ReedsSheppPath.PATH_FUNCTIONS) do
			local v15_ = v14_(self.x, self.z, self.phi)
			if v15_ ~= nil then
				callback(AIFieldCourseTurn.new(self.turnData, v15_))
			end
			local v16_ = v14_(-self.x, self.z, -self.phi)
			if v16_ ~= nil then
				callback(AIFieldCourseTurn.new(self.turnData, self:inverseDirection(v16_)))
			end
			local v17_ = v14_(self.x, -self.z, -self.phi)
			if v17_ ~= nil then
				callback(AIFieldCourseTurn.new(self.turnData, self:inverseSteering(v17_)))
			end
			local v18_ = v14_(-self.x, -self.z, self.phi)
			if v18_ ~= nil then
				callback(AIFieldCourseTurn.new(self.turnData, self:inverse(v18_)))
			end
		end
	else
		for _, v19_ in pairs(ReedsSheppPath.FORWARD_FUNCTIONS) do
			if self.forcedDirection == 1 then
				local v20_ = v19_(self.x, self.z, self.phi)
				if v20_ ~= nil then
					callback(AIFieldCourseTurn.new(self.turnData, v20_))
				end
			else
				local v21_ = v19_(-self.x, -self.z, self.phi)
				if v21_ ~= nil then
					callback(AIFieldCourseTurn.new(self.turnData, self:inverse(v21_)))
				end
			end
		end
	end
end

-- Local values: _, segment
function ReedsSheppPath:inverseSteering(segments)
	for _, v23_ in ipairs(segments) do
		v23_:inverseSteering()
	end
	return segments
end

-- Local values: _, segment
function ReedsSheppPath:inverseDirection(segments)
	for _, v25_ in ipairs(segments) do
		v25_:inverseDirection()
	end
	return segments
end

-- Local values: _, segment
function ReedsSheppPath:inverse(segments)
	for _, v27_ in ipairs(segments) do
		v27_:inverseSteering()
		v27_:inverseDirection()
	end
	return segments
end
ReedsSheppPath.PATH_FUNCTIONS = {}
ReedsSheppPath.PATH_FUNCTIONS[1] = function(p28_, p29_, p30_)
	local v31_ = {}
	local v32_ = p28_ - math.sin(p30_)
	local v33_ = p29_ - 1 + math.cos(p30_)
	local v34_ = MathUtil.vector2Length(v32_, v33_)
	local v35_ = MathUtil.getYRotationFromDirection(v33_, v32_)
	local v36_ = (p30_ - v35_) % 6.283185307179586
	if v36_ < -3.141592653589793 then
		v36_ = v36_ + 6.283185307179586
	elseif v36_ > 3.141592653589793 then
		v36_ = v36_ - 6.283185307179586
	end
	local v37_ = AIFieldCourseTurnSegment.new
	local v38_ = AIFieldCourseTurnSegmentType.LEFT
	table.insert(v31_, v37_(v35_, v38_, 1))
	local v39_ = AIFieldCourseTurnSegment.new
	local v40_ = AIFieldCourseTurnSegmentType.STRAIGHT
	table.insert(v31_, v39_(v34_, v40_, 1))
	local v41_ = AIFieldCourseTurnSegment.new
	local v42_ = AIFieldCourseTurnSegmentType.LEFT
	table.insert(v31_, v41_(v36_, v42_, 1))
	return v31_
end
ReedsSheppPath.PATH_FUNCTIONS[2] = function(p43_, p44_, p45_)
	local v46_ = p45_ % 6.283185307179586
	if v46_ < -3.141592653589793 then
		v46_ = v46_ + 6.283185307179586
	elseif v46_ > 3.141592653589793 then
		v46_ = v46_ - 6.283185307179586
	end
	local v47_ = p43_ + math.sin(v46_)
	local v48_ = p44_ - 1 - math.cos(v46_)
	local v49_ = MathUtil.vector2Length(v47_, v48_)
	local v50_ = MathUtil.getYRotationFromDirection(v48_, v47_)
	local v51_ = v49_ * v49_
	if v51_ < 4 then
		return nil
	end
	local v52_ = v51_ - 4
	local v53_ = math.sqrt(v52_)
	local v54_ = (v50_ + math.atan2(2, v53_)) % 6.283185307179586
	if v54_ < -3.141592653589793 then
		v54_ = v54_ + 6.283185307179586
	elseif v54_ > 3.141592653589793 then
		v54_ = v54_ - 6.283185307179586
	end
	local v55_ = (v54_ - v46_) % 6.283185307179586
	if v55_ < -3.141592653589793 then
		v55_ = v55_ + 6.283185307179586
	elseif v55_ > 3.141592653589793 then
		v55_ = v55_ - 6.283185307179586
	end
	local v56_ = {}
	local v57_ = AIFieldCourseTurnSegment.new
	local v58_ = AIFieldCourseTurnSegmentType.LEFT
	table.insert(v56_, v57_(v54_, v58_, 1))
	local v59_ = AIFieldCourseTurnSegment.new
	local v60_ = AIFieldCourseTurnSegmentType.STRAIGHT
	table.insert(v56_, v59_(v53_, v60_, 1))
	local v61_ = AIFieldCourseTurnSegment.new
	local v62_ = AIFieldCourseTurnSegmentType.RIGHT
	table.insert(v56_, v61_(v55_, v62_, 1))
	return v56_
end
ReedsSheppPath.PATH_FUNCTIONS[3] = function(p63_, p64_, p65_)
	local v66_ = p63_ - math.sin(p65_)
	local v67_ = p64_ - 1 + math.cos(p65_)
	local v68_ = MathUtil.vector2Length(v66_, v67_)
	local v69_ = MathUtil.getYRotationFromDirection(v67_, v66_)
	if v68_ > 4 then
		return nil
	end
	local v70_ = v68_ / 4
	local v71_ = math.acos(v70_)
	local v72_ = (v69_ + 1.5707963267948966 + v71_) % 6.283185307179586
	if v72_ < -3.141592653589793 then
		v72_ = v72_ + 6.283185307179586
	elseif v72_ > 3.141592653589793 then
		v72_ = v72_ - 6.283185307179586
	end
	local v73_ = (3.141592653589793 - 2 * v71_) % 6.283185307179586
	if v73_ < -3.141592653589793 then
		v73_ = v73_ + 6.283185307179586
	elseif v73_ > 3.141592653589793 then
		v73_ = v73_ - 6.283185307179586
	end
	local v74_ = (p65_ - v72_ - v73_) % 6.283185307179586
	if v74_ < -3.141592653589793 then
		v74_ = v74_ + 6.283185307179586
	elseif v74_ > 3.141592653589793 then
		v74_ = v74_ - 6.283185307179586
	end
	local v75_ = {}
	local v76_ = AIFieldCourseTurnSegment.new
	local v77_ = AIFieldCourseTurnSegmentType.LEFT
	table.insert(v75_, v76_(v72_, v77_, 1))
	local v78_ = AIFieldCourseTurnSegment.new
	local v79_ = AIFieldCourseTurnSegmentType.RIGHT
	table.insert(v75_, v78_(v73_, v79_, -1))
	local v80_ = AIFieldCourseTurnSegment.new
	local v81_ = AIFieldCourseTurnSegmentType.LEFT
	table.insert(v75_, v80_(v74_, v81_, 1))
	return v75_
end
ReedsSheppPath.PATH_FUNCTIONS[4] = function(p82_, p83_, p84_)
	local v85_ = p82_ - math.sin(p84_)
	local v86_ = p83_ - 1 + math.cos(p84_)
	local v87_ = MathUtil.vector2Length(v85_, v86_)
	local v88_ = MathUtil.getYRotationFromDirection(v86_, v85_)
	if v87_ > 4 then
		return nil
	end
	local v89_ = v87_ / 4
	local v90_ = math.acos(v89_)
	local v91_ = (v88_ + 1.5707963267948966 + v90_) % 6.283185307179586
	if v91_ < -3.141592653589793 then
		v91_ = v91_ + 6.283185307179586
	elseif v91_ > 3.141592653589793 then
		v91_ = v91_ - 6.283185307179586
	end
	local v92_ = (3.141592653589793 - 2 * v90_) % 6.283185307179586
	if v92_ < -3.141592653589793 then
		v92_ = v92_ + 6.283185307179586
	elseif v92_ > 3.141592653589793 then
		v92_ = v92_ - 6.283185307179586
	end
	local v93_ = (v91_ + v92_ - p84_) % 6.283185307179586
	if v93_ < -3.141592653589793 then
		v93_ = v93_ + 6.283185307179586
	elseif v93_ > 3.141592653589793 then
		v93_ = v93_ - 6.283185307179586
	end
	local v94_ = {}
	local v95_ = AIFieldCourseTurnSegment.new
	local v96_ = AIFieldCourseTurnSegmentType.LEFT
	table.insert(v94_, v95_(v91_, v96_, 1))
	local v97_ = AIFieldCourseTurnSegment.new
	local v98_ = AIFieldCourseTurnSegmentType.RIGHT
	table.insert(v94_, v97_(v92_, v98_, -1))
	local v99_ = AIFieldCourseTurnSegment.new
	local v100_ = AIFieldCourseTurnSegmentType.LEFT
	table.insert(v94_, v99_(v93_, v100_, -1))
	return v94_
end
ReedsSheppPath.PATH_FUNCTIONS[5] = function(p101_, p102_, p103_)
	local v104_ = p101_ - math.sin(p103_)
	local v105_ = p102_ - 1 + math.cos(p103_)
	local v106_ = MathUtil.vector2Length(v104_, v105_)
	local v107_ = MathUtil.getYRotationFromDirection(v105_, v104_)
	if v106_ <= 0 or v106_ > 4 then
		return nil
	end
	local v108_ = 1 - v106_ * v106_ / 8
	local v109_ = math.acos(v108_)
	local v110_ = 2 * math.sin(v109_) / v106_
	local v111_ = math.clamp(v110_, -1, 1)
	local v112_ = math.asin(v111_)
	local v113_ = (v107_ + 1.5707963267948966 - v112_) % 6.283185307179586
	if v113_ < -3.141592653589793 then
		v113_ = v113_ + 6.283185307179586
	elseif v113_ > 3.141592653589793 then
		v113_ = v113_ - 6.283185307179586
	end
	local v114_ = (v113_ - v109_ - p103_) % 6.283185307179586
	if v114_ < -3.141592653589793 then
		v114_ = v114_ + 6.283185307179586
	elseif v114_ > 3.141592653589793 then
		v114_ = v114_ - 6.283185307179586
	end
	local v115_ = {}
	local v116_ = AIFieldCourseTurnSegment.new
	local v117_ = AIFieldCourseTurnSegmentType.LEFT
	table.insert(v115_, v116_(v113_, v117_, 1))
	local v118_ = AIFieldCourseTurnSegment.new
	local v119_ = AIFieldCourseTurnSegmentType.RIGHT
	table.insert(v115_, v118_(v109_, v119_, 1))
	local v120_ = AIFieldCourseTurnSegment.new
	local v121_ = AIFieldCourseTurnSegmentType.LEFT
	table.insert(v115_, v120_(v114_, v121_, -1))
	return v115_
end
ReedsSheppPath.PATH_FUNCTIONS[6] = function(p122_, p123_, p124_)
	local v125_ = p122_ + math.sin(p124_)
	local v126_ = p123_ - 1 - math.cos(p124_)
	local v127_ = MathUtil.vector2Length(v125_, v126_)
	local v128_ = MathUtil.getYRotationFromDirection(v126_, v125_)
	if v127_ > 4 then
		return nil
	end
	local v129_, v130_, v131_
	if v127_ <= 2 then
		local v132_ = (v127_ + 2) / 4
		local v133_ = math.acos(v132_)
		v129_ = (v128_ + 1.5707963267948966 + v133_) % 6.283185307179586
		if v129_ < -3.141592653589793 then
			v129_ = v129_ + 6.283185307179586
		elseif v129_ > 3.141592653589793 then
			v129_ = v129_ - 6.283185307179586
		end
		v130_ = v133_ % 6.283185307179586
		if v130_ < -3.141592653589793 then
			v130_ = v130_ + 6.283185307179586
		elseif v130_ > 3.141592653589793 then
			v130_ = v130_ - 6.283185307179586
		end
		v131_ = (p124_ - v129_ + 2 * v130_) % 6.283185307179586
		if v131_ < -3.141592653589793 then
			v131_ = v131_ + 6.283185307179586
		elseif v131_ > 3.141592653589793 then
			v131_ = v131_ - 6.283185307179586
		end
	else
		local v134_ = (v127_ - 2) / 4
		local v135_ = math.acos(v134_)
		v129_ = (v128_ + 1.5707963267948966 - v135_) % 6.283185307179586
		if v129_ < -3.141592653589793 then
			v129_ = v129_ + 6.283185307179586
		elseif v129_ > 3.141592653589793 then
			v129_ = v129_ - 6.283185307179586
		end
		v130_ = (3.141592653589793 - v135_) % 6.283185307179586
		if v130_ < -3.141592653589793 then
			v130_ = v130_ + 6.283185307179586
		elseif v130_ > 3.141592653589793 then
			v130_ = v130_ - 6.283185307179586
		end
		v131_ = (p124_ - v129_ + 2 * v130_) % 6.283185307179586
		if v131_ < -3.141592653589793 then
			v131_ = v131_ + 6.283185307179586
		elseif v131_ > 3.141592653589793 then
			v131_ = v131_ - 6.283185307179586
		end
	end
	local v136_ = {}
	local v137_ = AIFieldCourseTurnSegment.new
	local v138_ = AIFieldCourseTurnSegmentType.LEFT
	table.insert(v136_, v137_(v129_, v138_, 1))
	local v139_ = AIFieldCourseTurnSegment.new
	local v140_ = AIFieldCourseTurnSegmentType.RIGHT
	table.insert(v136_, v139_(v130_, v140_, 1))
	local v141_ = AIFieldCourseTurnSegment.new
	local v142_ = AIFieldCourseTurnSegmentType.LEFT
	table.insert(v136_, v141_(v130_, v142_, -1))
	local v143_ = AIFieldCourseTurnSegment.new
	local v144_ = AIFieldCourseTurnSegmentType.RIGHT
	table.insert(v136_, v143_(v131_, v144_, -1))
	return v136_
end
ReedsSheppPath.PATH_FUNCTIONS[7] = function(p145_, p146_, p147_)
	local v148_ = p145_ + math.sin(p147_)
	local v149_ = p146_ - 1 - math.cos(p147_)
	local v150_ = MathUtil.vector2Length(v148_, v149_)
	local v151_ = MathUtil.getYRotationFromDirection(v149_, v148_)
	local v152_ = (20 - v150_ * v150_) / 16
	if v150_ <= 0 or (v150_ > 6 or (v152_ < 0 or v152_ > 1)) then
		return nil
	end
	local v153_ = math.acos(v152_)
	local v154_ = 2 * math.sin(v153_) / v150_
	local v155_ = math.clamp(v154_, -1, 1)
	local v156_ = math.asin(v155_)
	local v157_ = (v151_ + 1.5707963267948966 + v156_) % 6.283185307179586
	if v157_ < -3.141592653589793 then
		v157_ = v157_ + 6.283185307179586
	elseif v157_ > 3.141592653589793 then
		v157_ = v157_ - 6.283185307179586
	end
	local v158_ = (v157_ - p147_) % 6.283185307179586
	if v158_ < -3.141592653589793 then
		v158_ = v158_ + 6.283185307179586
	elseif v158_ > 3.141592653589793 then
		v158_ = v158_ - 6.283185307179586
	end
	local v159_ = {}
	local v160_ = AIFieldCourseTurnSegment.new
	local v161_ = AIFieldCourseTurnSegmentType.LEFT
	table.insert(v159_, v160_(v157_, v161_, 1))
	local v162_ = AIFieldCourseTurnSegment.new
	local v163_ = AIFieldCourseTurnSegmentType.RIGHT
	table.insert(v159_, v162_(v153_, v163_, -1))
	local v164_ = AIFieldCourseTurnSegment.new
	local v165_ = AIFieldCourseTurnSegmentType.LEFT
	table.insert(v159_, v164_(v153_, v165_, -1))
	local v166_ = AIFieldCourseTurnSegment.new
	local v167_ = AIFieldCourseTurnSegmentType.RIGHT
	table.insert(v159_, v166_(v158_, v167_, 1))
	return v159_
end
ReedsSheppPath.FORWARD_FUNCTIONS = {}
local v168_ = ReedsSheppPath.FORWARD_FUNCTIONS
local v169_ = ReedsSheppPath.PATH_FUNCTIONS[1]
table.insert(v168_, v169_)
local v170_ = ReedsSheppPath.FORWARD_FUNCTIONS
local v171_ = ReedsSheppPath.PATH_FUNCTIONS[2]
table.insert(v170_, v171_)
