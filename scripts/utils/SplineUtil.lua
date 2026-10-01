SplineUtil = {}
function SplineUtil.getValidSplineTime(t)
	return t % 1
end
function SplineUtil.getSplineTimeAtWorldPos(spline, t, posX, posZ, checkDistance, maxSteps)
	local splineLength = getSplineLength(spline)
	local currentCheckDistance = checkDistance / splineLength
	local stepCounter = 0
	while true do
		local t1 = SplineUtil.getValidSplineTime(t + currentCheckDistance)
		local t2 = SplineUtil.getValidSplineTime(t - currentCheckDistance)
		local fX, _, fZ = getSplinePosition(spline, t1)
		local bX, _, bZ = getSplinePosition(spline, t2)
		local fDistance = MathUtil.vector2LengthSq(posX - fX, posZ - fZ)
		local bDistance = MathUtil.vector2LengthSq(posX - bX, posZ - bZ)
		currentCheckDistance = currentCheckDistance * 0.5
		if fDistance >= bDistance then
			break
		end
		t = SplineUtil.getValidSplineTime(t + currentCheckDistance)
		if not (maxSteps < stepCounter) then
			stepCounter = stepCounter + 1
			continue
		end
		return t, stepCounter
	end
	t = SplineUtil.getValidSplineTime(t - currentCheckDistance)
end
function SplineUtil.getSlopeAngle(spline, splineTime)
	local dx, dy, dz = getSplineDirection(spline, splineTime)
	return math.acos(dy / MathUtil.vector3Length(dx, dy, dz)) - 1.5707963267948966
end
function SplineUtil.getCenterPosition(splineNode, samples)
	if splineNode == nil then
		return nil
	elseif I3DUtil.getIsSpline(splineNode) then
		local splineLength = getSplineLength(splineNode)
		if splineLength == nil or splineLength <= 0 then
			return nil
		end
		samples = samples or 100
		local xSum = 0
		local ySum = 0
		local zSum = 0
		local t = 0
		local stepSize = 1 / samples
		for i = 0, samples do
			local x, y, z = getSplinePosition(splineNode, t)
			xSum = xSum + x
			ySum = ySum + y
			zSum = zSum + z
			t = math.clamp(t + stepSize, 0, 1)
		end
		if not getIsSplineClosed(splineNode) then
			local x, y, z = getSplinePosition(splineNode, 0)
			xSum = xSum + x
			ySum = ySum + y
			zSum = zSum + z
			samples = samples + 1
		end
		return xSum / samples, ySum / samples, zSum / samples
	else
		return nil
	end
end
function SplineUtil.convertToLinearSplineXZ(cubicSpline, thresholdAngleDeg, stepSizeInMeter)
	if not I3DUtil.getIsSpline(cubicSpline) then
		return nil
	end
	thresholdAngleDeg = thresholdAngleDeg or 5
	stepSizeInMeter = stepSizeInMeter or 0.5
	local positions = {}
	local thresholdRad = math.rad(thresholdAngleDeg)
	local splineLength = getSplineLength(cubicSpline)
	local lastDirX = nil
	local lastDirZ = nil
	local t = 0
	while true do
		local x, y, z = getSplinePosition(cubicSpline, t)
		local dirX, _, dirZ = getSplineDirection(cubicSpline, t)
		if lastDirX ~= nil then
			break
		end
		lastDirX = dirX
		lastDirZ = dirZ
		break
	end
	while true do
		local delta = MathUtil.getVectorAngleDifference(dirX, 0, dirZ, lastDirX, 0, lastDirZ)
		if t == 0 or t == 1 or thresholdRad < delta then
			break
		end
		if t < 1 then
			t = math.clamp(t + stepSizeInMeter / splineLength, 0, 1)
		end
		return positions
	end
	table.insert(positions, { x, y, z })
	lastDirX = dirX
	lastDirZ = dirZ
end
function SplineUtil.getClosestEditPoint(splineNode, posX, posY, posZ)
	if splineNode == nil or not I3DUtil.getIsSpline(splineNode) then
		return nil
	end
	local numCV = getSplineNumOfCV(splineNode)
	if numCV < 1 then
		return nil
	end
	local closestIndex = -1
	local closestDistanceSq = math.huge
	local closestX = nil
	local closestY = nil
	local closestZ = nil
	for index = 0, numCV - 1 do
		local x, y, z = getSplineEP(splineNode, index)
		local distanceSq = MathUtil.vector3LengthSq(posX - x, posY - y, posZ - z)
		if distanceSq < closestDistanceSq then
			closestDistanceSq = distanceSq
			closestIndex = index
			closestX = x
			closestY = y
			closestZ = z
		end
	end
	if closestIndex == -1 then
		return nil
	else
		return closestIndex, math.sqrt(closestDistanceSq), closestX, closestY, closestZ
	end
end
function SplineUtil.getClosestEditPointsOnCurve(splineNode, posX, posY, posZ, eps)
	if splineNode == nil or not I3DUtil.getIsSpline(splineNode) then
		return nil
	end
	local splineLength = getSplineLength(splineNode)
	if splineLength == nil or splineLength <= 0 then
		return nil
	end
	eps = eps or 0.01 / splineLength
	local x, y, z, splineTime = getClosestSplinePosition(splineNode, posX, posY, posZ, eps)
	local numCV = getSplineNumOfCV(splineNode)
	local prevIndex = nil
	local nextIndex = nil
	for index = 0, numCV - 1 do
		local editPointTime = getTimeAtSplineCV(splineNode, index)
		if editPointTime < splineTime then
			prevIndex = index
		elseif nextIndex == nil then
			nextIndex = index
		end
	end
	return x, y, z, splineTime, prevIndex, nextIndex
end
