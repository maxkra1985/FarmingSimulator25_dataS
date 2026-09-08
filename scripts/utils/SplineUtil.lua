SplineUtil = {}

function SplineUtil.getValidSplineTime(t)
	return t % 1
end

-- Local values: splineLength, currentCheckDistance, stepCounter, t1, t2, fX, _, fZ, bX, _, bZ, fDistance, bDistance
function SplineUtil.getSplineTimeAtWorldPos(spline, t, posX, posZ, checkDistance, maxSteps)
	local v8_ = checkDistance / getSplineLength(spline)
	local v9_ = 0
	while true do
		local v10_ = SplineUtil.getValidSplineTime(t + v8_)
		local v11_ = SplineUtil.getValidSplineTime(t - v8_)
		local v12_, _, v13_ = getSplinePosition(spline, v10_)
		local v14_, _, v15_ = getSplinePosition(spline, v11_)
		local v16_ = MathUtil.vector2LengthSq(posX - v12_, posZ - v13_)
		local v17_ = MathUtil.vector2LengthSq(posX - v14_, posZ - v15_)
		v8_ = v8_ * 0.5
		if v16_ < v17_ then
			t = SplineUtil.getValidSplineTime(t + v8_)
		else
			t = SplineUtil.getValidSplineTime(t - v8_)
		end
		if maxSteps < v9_ then
			return t, v9_
		end
		v9_ = v9_ + 1
	end
end

-- Local values: dx, dy, dz
function SplineUtil.getSlopeAngle(spline, splineTime)
	local v20_, v21_, v22_ = getSplineDirection(spline, splineTime)
	local v23_ = v21_ / MathUtil.vector3Length(v20_, v21_, v22_)
	return math.acos(v23_) - 1.5707963267948966
end

-- Local values: splineLength, xSum, ySum, zSum, t, stepSize, i, x, y, z, x, y, z
function SplineUtil.getCenterPosition(splineNode, samples)
	if splineNode == nil then
		return nil
	end
	if not I3DUtil.getIsSpline(splineNode) then
		return nil
	end
	local v26_ = getSplineLength(splineNode)
	if v26_ == nil or v26_ <= 0 then
		return nil
	end
	local v27_ = samples or 100
	local v28_ = 1 / v27_
	local v29_ = 0
	local v30_ = 0
	local v31_ = 0
	local v32_ = 0
	for _ = 0, v27_ do
		local v33_, v34_, v35_ = getSplinePosition(splineNode, v29_)
		v30_ = v30_ + v33_
		v31_ = v31_ + v34_
		v32_ = v32_ + v35_
		local v36_ = v29_ + v28_
		v29_ = math.clamp(v36_, 0, 1)
	end
	if not getIsSplineClosed(splineNode) then
		local v37_, v38_, v39_ = getSplinePosition(splineNode, 0)
		v30_ = v30_ + v37_
		v31_ = v31_ + v38_
		v32_ = v32_ + v39_
		v27_ = v27_ + 1
	end
	return v30_ / v27_, v31_ / v27_, v32_ / v27_
end

-- Local values: positions, thresholdRad, splineLength, lastDirX, lastDirZ, t, x, y, z, dirX, _, dirZ, delta
function SplineUtil.convertToLinearSplineXZ(cubicSpline, thresholdAngleDeg, stepSizeInMeter)
	if not I3DUtil.getIsSpline(cubicSpline) then
		return nil
	end
	local v43_ = math.rad(thresholdAngleDeg or 5)
	local v44_ = getSplineLength(cubicSpline)
	local v45_ = 0
	local v46_ = nil
	local v47_ = {}
	local v48_ = stepSizeInMeter or 0.5
	local v49_ = nil
	while true do
		local v50_, v51_, v52_ = getSplinePosition(cubicSpline, v45_)
		local v53_, _, v54_ = getSplineDirection(cubicSpline, v45_)
		if v46_ == nil then
			v49_ = v54_
			v46_ = v53_
		end
		local v55_ = MathUtil.getVectorAngleDifference(v53_, 0, v54_, v46_, 0, v49_)
		if v45_ == 0 or (v45_ == 1 or v43_ < v55_) then
			table.insert(v47_, { v50_, v51_, v52_ })
		else
			v54_ = v49_
			v53_ = v46_
		end
		if v45_ >= 1 then
			return v47_
		end
		local v56_ = v45_ + v48_ / v44_
		v45_ = math.clamp(v56_, 0, 1)
		v49_ = v54_
		v46_ = v53_
	end
end

-- Local values: numCV, closestIndex, closestDistanceSq, closestX, closestY, closestZ, index, x, y, z, distanceSq
function SplineUtil.getClosestEditPoint(splineNode, posX, posY, posZ)
	if splineNode == nil or not I3DUtil.getIsSpline(splineNode) then
		return nil
	else
		local v61_ = getSplineNumOfCV(splineNode)
		if v61_ < 1 then
			return nil
		else
			local v62_ = math.huge
			local v63_ = -1
			local v64_ = nil
			local v65_ = nil
			local v66_ = nil
			for v67_ = 0, v61_ - 1 do
				local v68_, v69_, v70_ = getSplineEP(splineNode, v67_)
				local v71_ = MathUtil.vector3LengthSq(posX - v68_, posY - v69_, posZ - v70_)
				if v71_ < v62_ then
					v66_ = v70_
					v65_ = v69_
					v64_ = v68_
					v63_ = v67_
					v62_ = v71_
				end
			end
			if v63_ == -1 then
				return nil
			else
				return v63_, math.sqrt(v62_), v64_, v65_, v66_
			end
		end
	end
end

-- Local values: splineLength, x, y, z, splineTime, numCV, prevIndex, nextIndex, index, editPointTime
function SplineUtil.getClosestEditPointsOnCurve(splineNode, posX, posY, posZ, eps)
	if splineNode == nil or not I3DUtil.getIsSpline(splineNode) then
		return nil
	end
	local v77_ = getSplineLength(splineNode)
	if v77_ == nil or v77_ <= 0 then
		return nil
	end
	local v78_ = eps or 0.01 / v77_
	local v79_, v80_, v81_, v82_ = getClosestSplinePosition(splineNode, posX, posY, posZ, v78_)
	local v83_ = nil
	local v84_ = nil
	for v85_ = 0, getSplineNumOfCV(splineNode) - 1 do
		if getTimeAtSplineCV(splineNode, v85_) < v82_ then
			v84_ = v85_
		elseif v83_ == nil then
			v83_ = v85_
		end
	end
	return v79_, v80_, v81_, v82_, v84_, v83_
end
