-- Local values: DubinsPath_mt
DubinsPath = {}
local DubinsPath_mt = Class(DubinsPath)

-- Upvalues: DubinsPath_mt
-- Local values: self, sAngle, eAngle, dx, dz, length, theta
function DubinsPath.new(turnData, forcedDirection)
	-- upvalues: (copy) DubinsPath_mt
	local v4_ = DubinsPath_mt
	local v5_ = setmetatable({}, v4_)
	v5_.turnData = turnData
	v5_.forcedDirection = forcedDirection or 0
	local v6_ = (MathUtil.getYRotationFromDirection(turnData.sDirX, turnData.sDirZ) - 1.5707963267948966) % 6.283185307179586
	local v7_ = (MathUtil.getYRotationFromDirection(turnData.eDirX, turnData.eDirZ) - 1.5707963267948966) % 6.283185307179586
	local v8_ = turnData.ex - turnData.sx
	local v9_ = turnData.ez - turnData.sz
	local v10_ = MathUtil.vector2Length(v8_, v9_)
	v5_.distance = v10_ / turnData.turnRadius
	local v11_ = (MathUtil.getYRotationFromDirection(v8_, v9_) - 1.5707963267948966) % 6.283185307179586
	v5_.alpha = (v6_ - v11_) % 6.283185307179586
	v5_.beta = (v7_ - v11_) % 6.283185307179586
	local v12_ = 3.141592653589793 - v11_
	if math.abs(v12_) < 0.001 and v5_.distance > 0 then
		local v13_ = v8_ / v10_
		local v14_ = v9_ / v10_
		local v15_ = v13_ - turnData.sDirX
		if math.abs(v15_) < 0.001 then
			local v16_ = v14_ - turnData.sDirZ
			if math.abs(v16_) < 0.001 then
				local v17_ = v13_ - turnData.eDirX
				if math.abs(v17_) < 0.001 then
					local v18_ = v14_ - turnData.eDirZ
					if math.abs(v18_) < 0.001 then
						v5_.straightSegmentOnly = true
					end
				end
			end
		end
	end
	return v5_
end

-- Local values: segments, _, func, segments
function DubinsPath:generate(callback)
	if self.forcedDirection >= 0 then
		if self.straightSegmentOnly then
			local v21_ = {}
			local v22_ = AIFieldCourseTurnSegment.new
			local v23_ = self.distance
			local v24_ = AIFieldCourseTurnSegmentType.STRAIGHT
			table.insert(v21_, v22_(v23_, v24_, 1))
			callback(AIFieldCourseTurn.new(self.turnData, v21_))
		end
		for _, v25_ in ipairs(DubinsPath.PATH_FUNCTIONS) do
			local v26_ = v25_(self.alpha, self.beta, self.distance)
			if v26_ ~= nil and #v26_ > 0 then
				callback(AIFieldCourseTurn.new(self.turnData, v26_))
			end
		end
	end
end
DubinsPath.PATH_FUNCTIONS = {}
DubinsPath.PATH_FUNCTIONS[1] = function(p27_, p28_, p29_)
	local v30_ = 6 - p29_ * p29_
	local v31_ = p27_ - p28_
	local v32_ = (v30_ + 2 * math.cos(v31_) + 2 * p29_ * (-math.sin(p27_) + math.sin(p28_))) / 8
	if math.abs(v32_) > 1 then
		return nil
	end
	local v33_ = {}
	local v34_ = (6.283185307179586 - math.acos(v32_)) % 6.283185307179586
	local v35_ = -p27_
	local v36_ = math.cos(p27_) - math.cos(p28_)
	local v37_ = p29_ + math.sin(p27_) - math.sin(p28_)
	local v38_ = (v35_ - math.atan2(v36_, v37_) + v34_ / 2) % 6.283185307179586
	local v39_ = (p28_ % 6.283185307179586 - p27_ - v38_ + v34_ % 6.283185307179586) % 6.283185307179586
	local v40_ = AIFieldCourseTurnSegment.new
	local v41_ = AIFieldCourseTurnSegmentType.LEFT
	table.insert(v33_, v40_(v38_, v41_, 1))
	local v42_ = AIFieldCourseTurnSegment.new
	local v43_ = AIFieldCourseTurnSegmentType.RIGHT
	table.insert(v33_, v42_(v34_, v43_, 1))
	local v44_ = AIFieldCourseTurnSegment.new
	local v45_ = AIFieldCourseTurnSegmentType.LEFT
	table.insert(v33_, v44_(v39_, v45_, 1))
	return v33_
end
DubinsPath.PATH_FUNCTIONS[2] = function(p46_, p47_, p48_)
	local v49_ = math.cos(p47_) - math.cos(p46_)
	local v50_ = p48_ + math.sin(p46_) - math.sin(p47_)
	local v51_ = math.atan2(v49_, v50_)
	local v52_ = 2 + p48_ * p48_
	local v53_ = p46_ - p47_
	local v54_ = v52_ - 2 * math.cos(v53_) + 2 * p48_ * (math.sin(p46_) - math.sin(p47_))
	if v54_ < 0 then
		return nil
	end
	local v55_ = {}
	local v56_ = (v51_ - p46_) % 6.283185307179586
	local v57_ = math.sqrt(v54_)
	local v58_ = (p47_ - v51_) % 6.283185307179586
	local v59_ = AIFieldCourseTurnSegment.new
	local v60_ = AIFieldCourseTurnSegmentType.LEFT
	table.insert(v55_, v59_(v56_, v60_, 1))
	local v61_ = AIFieldCourseTurnSegment.new
	local v62_ = AIFieldCourseTurnSegmentType.STRAIGHT
	table.insert(v55_, v61_(v57_, v62_, 1))
	local v63_ = AIFieldCourseTurnSegment.new
	local v64_ = AIFieldCourseTurnSegmentType.LEFT
	table.insert(v55_, v63_(v58_, v64_, 1))
	return v55_
end
DubinsPath.PATH_FUNCTIONS[3] = function(p65_, p66_, p67_)
	local v68_ = p67_ + math.sin(p65_) + math.sin(p66_)
	local v69_ = -2 + p67_ * p67_
	local v70_ = p65_ - p66_
	local v71_ = v69_ + 2 * math.cos(v70_) + 2 * p67_ * (math.sin(p65_) + math.sin(p66_))
	if v71_ < 0 then
		return nil
	end
	local v72_ = {}
	local v73_ = math.sqrt(v71_)
	local v74_ = -math.cos(p65_) - math.cos(p66_)
	local v75_ = math.atan2(v74_, v68_) - math.atan2(-2, v73_)
	local v76_ = (v75_ - p65_) % 6.283185307179586
	local v77_ = (v75_ - p66_) % 6.283185307179586
	local v78_ = AIFieldCourseTurnSegment.new
	local v79_ = AIFieldCourseTurnSegmentType.LEFT
	table.insert(v72_, v78_(v76_, v79_, 1))
	local v80_ = AIFieldCourseTurnSegment.new
	local v81_ = AIFieldCourseTurnSegmentType.STRAIGHT
	table.insert(v72_, v80_(v73_, v81_, 1))
	local v82_ = AIFieldCourseTurnSegment.new
	local v83_ = AIFieldCourseTurnSegmentType.RIGHT
	table.insert(v72_, v82_(v77_, v83_, 1))
	return v72_
end
DubinsPath.PATH_FUNCTIONS[4] = function(p84_, p85_, p86_)
	local v87_ = 6 - p86_ * p86_
	local v88_ = p84_ - p85_
	local v89_ = (v87_ + 2 * math.cos(v88_) + 2 * p86_ * (math.sin(p84_) - math.sin(p85_))) / 8
	if math.abs(v89_) > 1 then
		return nil
	end
	local v90_ = {}
	local v91_ = (6.283185307179586 - math.acos(v89_)) % 6.283185307179586
	local v92_ = math.cos(p84_) - math.cos(p85_)
	local v93_ = p86_ - math.sin(p84_) + math.sin(p85_)
	local v94_ = (p84_ - math.atan2(v92_, v93_) + v91_ / 2 % 6.283185307179586) % 6.283185307179586
	local v95_ = (p84_ - p85_ - v94_ + v91_ % 6.283185307179586) % 6.283185307179586
	local v96_ = AIFieldCourseTurnSegment.new
	local v97_ = AIFieldCourseTurnSegmentType.RIGHT
	table.insert(v90_, v96_(v94_, v97_, 1))
	local v98_ = AIFieldCourseTurnSegment.new
	local v99_ = AIFieldCourseTurnSegmentType.LEFT
	table.insert(v90_, v98_(v91_, v99_, 1))
	local v100_ = AIFieldCourseTurnSegment.new
	local v101_ = AIFieldCourseTurnSegmentType.RIGHT
	table.insert(v90_, v100_(v95_, v101_, 1))
	return v90_
end
DubinsPath.PATH_FUNCTIONS[5] = function(p102_, p103_, p104_)
	local v105_ = p104_ - math.sin(p102_) - math.sin(p103_)
	local v106_ = -2 + p104_ * p104_
	local v107_ = p102_ - p103_
	local v108_ = v106_ + 2 * math.cos(v107_) - 2 * p104_ * (math.sin(p102_) + math.sin(p103_))
	if v108_ < 0 then
		return nil
	end
	local v109_ = {}
	local v110_ = math.sqrt(v108_)
	local v111_ = math.cos(p102_) + math.cos(p103_)
	local v112_ = math.atan2(v111_, v105_) - math.atan2(2, v110_)
	local v113_ = (p102_ - v112_) % 6.283185307179586
	local v114_ = (p103_ - v112_) % 6.283185307179586
	local v115_ = AIFieldCourseTurnSegment.new
	local v116_ = AIFieldCourseTurnSegmentType.RIGHT
	table.insert(v109_, v115_(v113_, v116_, 1))
	local v117_ = AIFieldCourseTurnSegment.new
	local v118_ = AIFieldCourseTurnSegmentType.STRAIGHT
	table.insert(v109_, v117_(v110_, v118_, 1))
	local v119_ = AIFieldCourseTurnSegment.new
	local v120_ = AIFieldCourseTurnSegmentType.LEFT
	table.insert(v109_, v119_(v114_, v120_, 1))
	return v109_
end
DubinsPath.PATH_FUNCTIONS[6] = function(p121_, p122_, p123_)
	local v124_ = p123_ - math.sin(p121_) + math.sin(p122_)
	local v125_ = math.cos(p121_) - math.cos(p122_)
	local v126_ = math.atan2(v125_, v124_)
	local v127_ = 2 + p123_ * p123_
	local v128_ = p121_ - p122_
	local v129_ = v127_ - 2 * math.cos(v128_) + 2 * p123_ * (math.sin(p122_) - math.sin(p121_))
	if v129_ < 0 then
		return nil
	end
	local v130_ = {}
	local v131_ = (p121_ - v126_) % 6.283185307179586
	local v132_ = math.sqrt(v129_)
	local v133_ = (-p122_ + v126_) % 6.283185307179586
	local v134_ = AIFieldCourseTurnSegment.new
	local v135_ = AIFieldCourseTurnSegmentType.RIGHT
	table.insert(v130_, v134_(v131_, v135_, 1))
	local v136_ = AIFieldCourseTurnSegment.new
	local v137_ = AIFieldCourseTurnSegmentType.STRAIGHT
	table.insert(v130_, v136_(v132_, v137_, 1))
	local v138_ = AIFieldCourseTurnSegment.new
	local v139_ = AIFieldCourseTurnSegmentType.RIGHT
	table.insert(v130_, v138_(v133_, v139_, 1))
	return v130_
end
