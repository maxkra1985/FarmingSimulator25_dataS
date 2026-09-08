
-- Local values: self, fieldCourseSettings
function AIFieldCourseTurnData(sx, sz, sDirX, sDirZ, ex, ez, eDirX, eDirZ, segment1, segment1Direction, segment2, segment2Direction, aiFieldCourse, turnRadius)
	local v_u_15_ = {
		["startOffset"] = 0,
		["endOffset"] = 0,
		["sx"] = sx,
		["sz"] = sz,
		["sDirX"] = sDirX,
		["sDirZ"] = sDirZ,
		["ex"] = ex,
		["ez"] = ez,
		["eDirX"] = eDirX,
		["eDirZ"] = eDirZ,
		["segment1"] = segment1,
		["segment2"] = segment2,
		["segment1Direction"] = segment1Direction,
		["segment2Direction"] = segment2Direction,
		["fieldRootBoundary"] = aiFieldCourse.fieldRootBoundary,
		["validPathBoundary"] = aiFieldCourse.validPathBoundary,
		["protectedBoundary"] = aiFieldCourse.protectedBoundary,
		["islands"] = aiFieldCourse.islands
	}
	local v16_ = aiFieldCourse.fieldCourseSettings
	v_u_15_.turnRadius = turnRadius or v16_.minTurnRadius
	v_u_15_.canTurnBackward = v16_.canTurnBackward
	v_u_15_.allowStraightReversing = v16_.allowStraightReversing
	v_u_15_.implementWidth = v16_.implementWidth
	v_u_15_.toolFrontOffset = v16_.toolFrontOffset
	v_u_15_.toolBackOffset = v16_.toolBackOffset
	function v_u_15_.clone(p17_, p18_, p19_)
		-- upvalues: (copy) v_u_15_
		if p18_ == false or p19_ == false then
			local v20_ = p17_:rawClone()
			v20_.originalTurnData = p17_.originalTurnData
			if not p18_ then
				v20_.segment1 = nil
				v20_.segment1Direction = 1
			end
			if not p19_ then
				v20_.segment2 = nil
				v20_.segment2Direction = 1
			end
			return v20_
		end
		local v21_ = {}
		local v22_ = {
			["__index"] = v_u_15_
		}
		setmetatable(v21_, v22_)
		v21_.originalTurnData = p17_.originalTurnData
		v21_.startOffset = p17_.startOffset
		v21_.endOffset = p17_.endOffset
		local v23_ = p17_.sx
		local v24_ = p17_.sz
		local v25_ = p17_.sDirX
		local v26_ = p17_.sDirZ
		v21_.sx = v23_
		v21_.sz = v24_
		v21_.sDirX = v25_
		v21_.sDirZ = v26_
		local v27_ = p17_.ex
		local v28_ = p17_.ez
		local v29_ = p17_.eDirX
		local v30_ = p17_.eDirZ
		v21_.ex = v27_
		v21_.ez = v28_
		v21_.eDirX = v29_
		v21_.eDirZ = v30_
		return v21_
	end
	function v_u_15_.rawClone(p31_)
		-- upvalues: (copy) sx, (copy) sz, (copy) sDirX, (copy) sDirZ, (copy) ex, (copy) ez, (copy) eDirX, (copy) eDirZ, (copy) segment1, (copy) segment1Direction, (copy) segment2, (copy) segment2Direction, (copy) aiFieldCourse, (copy) turnRadius
		local v32_ = AIFieldCourseTurnData(sx, sz, sDirX, sDirZ, ex, ez, eDirX, eDirZ, segment1, segment1Direction, segment2, segment2Direction, aiFieldCourse, turnRadius)
		v32_.startOffset = p31_.startOffset
		v32_.endOffset = p31_.endOffset
		local v33_ = p31_.sx
		local v34_ = p31_.sz
		local v35_ = p31_.sDirX
		local v36_ = p31_.sDirZ
		v32_.sx = v33_
		v32_.sz = v34_
		v32_.sDirX = v35_
		v32_.sDirZ = v36_
		local v37_ = p31_.ex
		local v38_ = p31_.ez
		local v39_ = p31_.eDirX
		local v40_ = p31_.eDirZ
		v32_.ex = v37_
		v32_.ez = v38_
		v32_.eDirX = v39_
		v32_.eDirZ = v40_
		local v41_ = p31_.segment1
		local v42_ = p31_.segment2
		v32_.segment1 = v41_
		v32_.segment2 = v42_
		local v43_ = p31_.segment1Direction
		local v44_ = p31_.segment2Direction
		v32_.segment1Direction = v43_
		v32_.segment2Direction = v44_
		v32_.fieldRootBoundary = p31_.fieldRootBoundary
		v32_.validPathBoundary = p31_.validPathBoundary
		v32_.protectedBoundary = p31_.protectedBoundary
		v32_.islands = p31_.islands
		v32_.turnRadius = p31_.turnRadius
		v32_.canTurnBackward = p31_.canTurnBackward
		v32_.allowStraightReversing = p31_.allowStraightReversing
		v32_.implementWidth = p31_.implementWidth
		v32_.toolFrontOffset = p31_.toolFrontOffset
		v32_.toolBackOffset = p31_.toolBackOffset
		return v32_
	end
	function v_u_15_.offset(_, p45_, p46_, p47_)
		-- upvalues: (copy) v_u_15_
		local v48_ = {}
		local v49_ = {
			["__index"] = v_u_15_
		}
		setmetatable(v48_, v49_)
		v48_.originalTurnData = v_u_15_
		v48_.startOffset = p45_ or (v48_.startOffset or 0)
		v48_.endOffset = p46_ or (v48_.endOffset or 0)
		if v48_.segment1 ~= nil then
			local v50_, v51_, v52_, v53_ = AIFieldCourseUtil.getSegmentPositionAndDirection(false, v48_.segment1, v48_.segment1Direction, v48_.startOffset, p47_)
			v48_.sx = v50_
			v48_.sz = v51_
			v48_.sDirX = v52_
			v48_.sDirZ = v53_
		end
		if v48_.segment2 ~= nil then
			local v54_, v55_, v56_, v57_ = AIFieldCourseUtil.getSegmentPositionAndDirection(true, v48_.segment2, v48_.segment2Direction, v48_.endOffset, p47_)
			v48_.ex = v54_
			v48_.ez = v55_
			v48_.eDirX = v56_
			v48_.eDirZ = v57_
		end
		return v48_
	end
	return v_u_15_
end
