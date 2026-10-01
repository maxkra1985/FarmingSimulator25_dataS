MathUtil = {}
function MathUtil.isNan(value)
	return not (value == value)
end
function MathUtil.isInt(number)
	return math.round(number) == number
end
function MathUtil.isInf(number)
	return number == -math.huge or number == math.huge
end
function MathUtil.isFinite(number)
	return not (MathUtil.isNan(number) or MathUtil.isInf(number))
end
function MathUtil.getIsValidTransformationValue(...)
	local number = nil
	for i = 1, select("#", ...) do
		number = select(i, ...)
		if number == nil then
			return false
		end
		if tonumber(number) == nil then
			return false
		end
		if number ~= number then
			return false
		end
		if number == math.huge then
			return false
		end
		if number == -math.huge then
			return false
		end
	end
	return true
end
function MathUtil.randomFloat(lowerValue, upperValue)
	return lowerValue + math.random() * (upperValue - lowerValue)
end
function MathUtil.round(value, precision)
	if value == nil then
		return nil
	elseif precision then
		local exp = 10 ^ precision
		return math.floor(value * exp + 0.5) / exp
	else
		return math.floor(value + 0.5)
	end
end
function MathUtil.roundToStep(value, step)
	if value == nil then
		return nil
	end
	step = step or 0.5
	if 0 <= value then
		return math.floor(value / step + 0.5) * step
	else
		return math.ceil(value / step - 0.5) * step
	end
end
function MathUtil.degToRad(degValue)
	if degValue ~= nil then
		return math.rad(degValue)
	else
		return 0
	end
end
function MathUtil.lerp(v1, v2, alpha)
	return v1 + (v2 - v1) * alpha
end
function MathUtil.inverseLerp(v1, v2, cv)
	if math.abs(v1 - v2) < 0.0001 then
		return 0
	else
		return math.clamp((cv - v1) / (v2 - v1), 0, 1)
	end
end
function MathUtil.timeLerp(startTime, endTime, currentTime)
	if startTime == endTime then
		return 0
	else
		if endTime < startTime then
			local diff = 24 - startTime
			startTime = 0
			endTime = endTime + diff
			currentTime = (currentTime + diff) % 24
		end
		return (currentTime - startTime) / (endTime - startTime)
	end
end
function MathUtil.getIsOutOfBounds(value, limit1, limit2)
	if limit1 < limit2 then
		return value < limit1 or limit2 < value
	else
		return limit1 < value or value < limit2
	end
end
function MathUtil.getFlooredPercent(value, maxValue)
	local percent = 0
	if 0 < maxValue then
		percent = math.floor(value / maxValue * 100)
		if 99 < percent and value < maxValue then
			percent = 99
			return percent
		end
		if percent < 1 and 0 < value then
			percent = 1
		end
	end
	return percent
end
function MathUtil.getFlooredBounded(value, minValue, maxValue)
	if value == minValue then
		return minValue
	elseif value == maxValue then
		return maxValue
	else
		return math.min(math.max(math.floor(value), minValue + 1), maxValue - 1)
	end
end
function MathUtil.getValidLimit(limit)
	while limit < -3.141592653589793 do
		limit = limit + 6.283185307179586
	end
	while 3.141592653589793 < limit do
		limit = limit - 6.283185307179586
	end
	return limit
end
function MathUtil.getAngleDifference(alpha, beta)
	local a = alpha - beta
	return MathUtil.getValidLimit(a)
end
function MathUtil.eulerToDirection(yaw, pitch)
	local xzLength = math.cos(-pitch)
	return xzLength * math.sin(yaw), math.sin(-pitch), xzLength * math.cos(yaw)
end
function MathUtil.directionToPitchYaw(directionX, directionY, directionZ)
	return math.asin(-directionY), math.atan2(directionX, directionZ)
end
function MathUtil.vector2Length(x, y)
	return math.sqrt(x * x + y * y)
end
function MathUtil.vector2LengthSq(x, y)
	return x * x + y * y
end
function MathUtil.vector2Normalize(x, y)
	local length = math.sqrt(x * x + y * y)
	return x / length, y / length
end
function MathUtil.vector2SetLength(x, y, length)
	x, y = MathUtil.vector2Normalize(x, y)
	x = x * length
	y = y * length
	return x, y
end
function MathUtil.vector2Lerp(x1, y1, x2, y2, alpha)
	return x1 + (x2 - x1) * alpha, y1 + (y2 - y1) * alpha
end
function MathUtil.vector3Length(x, y, z)
	return math.sqrt(x * x + y * y + z * z)
end
function MathUtil.vector3LengthSq(x, y, z)
	return x * x + y * y + z * z
end
function MathUtil.vector3Normalize(x, y, z)
	local length = MathUtil.vector3Length(x, y, z)
	return x / length, y / length, z / length
end
function MathUtil.vector3SetLength(x, y, z, length)
	x, y, z = MathUtil.vector3Normalize(x, y, z)
	x = x * length
	y = y * length
	z = z * length
	return x, y, z
end
function MathUtil.vector3Clamp(x, y, z, minVal, maxVal)
	local length = MathUtil.vector3Length(x, y, z)
	if 0 < length then
		length = math.clamp(length, minVal, maxVal)
		x, y, z = MathUtil.vector3SetLength(x, y, z, length)
	end
	return x, y, z
end
function MathUtil.vector3Lerp(x1, y1, z1, x2, y2, z2, alpha)
	return x1 + (x2 - x1) * alpha, y1 + (y2 - y1) * alpha, z1 + (z2 - z1) * alpha
end
MathUtil.lerp3 = MathUtil.vector3Lerp
function MathUtil.inverseVector3Lerp(x1, y1, z1, x2, y2, z2, c1, c2, c3)
	local alpha1 = MathUtil.inverseLerp(x1, x2, c1)
	local alpha2 = MathUtil.inverseLerp(y1, y2, c2)
	local alpha3 = MathUtil.inverseLerp(z1, z2, c3)
	local value = 0
	if x1 ~= x2 then
		value = alpha1
		return value
	elseif y1 ~= y2 then
		value = alpha2
		return value
	else
		if z1 ~= z2 then
			value = alpha3
		end
		return value
	end
end
function MathUtil.vector3ArrayLerp(v1, v2, alpha)
	return v1[1] + (v2[1] - v1[1]) * alpha, v1[2] + (v2[2] - v1[2]) * alpha, v1[3] + (v2[3] - v1[3]) * alpha
end
function MathUtil.inverseVector3ArrayLerp(v1, v2, cv)
	local alpha1 = MathUtil.inverseLerp(v1[1], v2[1], cv[1])
	local alpha2 = MathUtil.inverseLerp(v1[2], v2[2], cv[2])
	local alpha3 = MathUtil.inverseLerp(v1[3], v2[3], cv[3])
	local value = 0
	if v1[1] ~= v2[1] then
		value = alpha1
		return value
	elseif v1[2] ~= v2[2] then
		value = alpha2
		return value
	else
		if v1[3] ~= v2[3] then
			value = alpha3
		end
		return value
	end
end
function MathUtil.vector3Transformation(x, y, z, m11, m12, m13, m21, m22, m23, m31, m32, m33)
	return x * m11 + y * m21 + z * m31, x * m12 + y * m22 + z * m32, x * m13 + y * m23 + z * m33
end
function MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, xOffset, yOffset, zOffset)
	local normX, normY, normZ = MathUtil.crossProduct(upX, upY, upZ, dirX, dirY, dirZ)
	x = x + normX * xOffset + upX * yOffset + dirX * zOffset
	y = y + normY * xOffset + upY * yOffset + dirY * zOffset
	z = z + normZ * xOffset + upZ * yOffset + dirZ * zOffset
	return x, y, z
end
function MathUtil.dotProduct(ax, ay, az, bx, by, bz)
	return ax * bx + ay * by + az * bz
end
function MathUtil.crossProduct(ax, ay, az, bx, by, bz)
	return ay * bz - az * by, az * bx - ax * bz, ax * by - ay * bx
end
function MathUtil.getVectorAngleDifference(dirX1, dirY1, dirZ1, dirX2, dirY2, dirZ2)
	local dot = dirX1 * dirX2 + dirY1 * dirY2 + dirZ1 * dirZ2
	local length1 = math.sqrt(dirX1 * dirX1 + dirY1 * dirY1 + dirZ1 * dirZ1)
	local length2 = math.sqrt(dirX2 * dirX2 + dirY2 * dirY2 + dirZ2 * dirZ2)
	return math.acos(dot / (length1 * length2 + 0.000001))
end
function MathUtil.getSignedAngleBetweenVectors2D(dirX1, dirZ1, dirX2, dirZ2)
	local dot1 = dirX1 * dirX2 + dirZ1 * dirZ2
	local dot2 = dirZ1 * dirX2 + -dirX1 * dirZ2
	return math.acos(dot1) * math.sign(dot2)
end
function MathUtil.getYRotationFromDirection(dx, dz)
	return math.atan2(dx, dz)
end
function MathUtil.getDirectionFromYRotation(rotY)
	return math.sin(rotY), math.cos(rotY)
end
function MathUtil.getRotationLimitedVector2(x, y, minRot, maxRot)
	local rot = -math.atan2(y, x)
	if rot < minRot or maxRot < rot then
		rot = rot < minRot and minRot or maxRot
		local len = math.sqrt(x * x + y * y)
		x = math.cos(-rot) * len
		y = math.sin(-rot) * len
	end
	return x, y
end
function MathUtil.quaternionVectorMultiplication(quatX, quatY, quatZ, quatW, vecX, vecY, vecZ)
	local num = quatX * 2
	local num2 = quatY * 2
	local num3 = quatZ * 2
	local num4 = quatX * num
	local num5 = quatY * num2
	local num6 = quatZ * num3
	local num7 = quatX * num2
	local num8 = quatX * num3
	local num9 = quatY * num3
	local num10 = quatW * num
	local num11 = quatW * num2
	local num12 = quatW * num3
	local x = (1 - (num5 + num6)) * vecX + (num7 - num12) * vecY + (num8 + num11) * vecZ
	local y = (num7 + num12) * vecX + (1 - (num4 + num6)) * vecY + (num9 - num10) * vecZ
	local z = (num8 - num11) * vecX + (num9 + num10) * vecY + (1 - (num4 + num5)) * vecZ
	return x, y, z
end
function MathUtil.projectOnLine(px, pz, lineX, lineZ, normlineDirX, normlineDirZ)
	local dx = px - lineX
	local dz = pz - lineZ
	local dot = dx * normlineDirX + dz * normlineDirZ
	return lineX + normlineDirX * dot, lineZ + normlineDirZ * dot
end
function MathUtil.getProjectOnLineParameter(px, pz, lineX, lineZ, normlineDirX, normlineDirZ)
	local dx = px - lineX
	local dz = pz - lineZ
	local dot = dx * normlineDirX + dz * normlineDirZ
	return dot
end
function MathUtil.quaternionMult(x, y, z, w, x1, y1, z1, w1)
	return y * z1 - z * y1 + w * x1 + x * w1, z * x1 - x * z1 + w * y1 + y * w1, x * y1 - y * x1 + w * z1 + z * w1, w * w1 - x * x1 - y * y1 - z * z1
end
function MathUtil.quaternionNormalized(x, y, z, w)
	local len = math.sqrt(x * x + y * y + z * z + w * w)
	if 0 < len then
		len = 1 / len
	end
	return x * len, y * len, z * len, w * len
end
function MathUtil.slerpQuaternion(x1, y1, z1, w1, x2, y2, z2, w2, t)
	local fCos = x1 * x2 + y1 * y2 + z1 * z2 + w1 * w2
	local fAngle = math.acos(fCos)
	if math.abs(fAngle) < 0.01 then
		return x1, y1, z1, w1
	else
		local fSin = math.sin(fAngle)
		local fInvSin = 1 / fSin
		local fCoeff0 = math.sin((1 - t) * fAngle) * fInvSin
		local fCoeff1 = math.sin(t * fAngle) * fInvSin
		return x1 * fCoeff0 + x2 * fCoeff1, y1 * fCoeff0 + y2 * fCoeff1, z1 * fCoeff0 + z2 * fCoeff1, w1 * fCoeff0 + w2 * fCoeff1
	end
end
function MathUtil.normalizeRotationForShortestPath(targetRotation, curRotation)
	while curRotation < targetRotation do
		targetRotation = targetRotation - 6.283185307179586
	end
	while targetRotation < curRotation do
		targetRotation = targetRotation + 6.283185307179586
	end
	if curRotation + 6.283185307179586 - targetRotation < targetRotation - curRotation then
		targetRotation = targetRotation - 6.283185307179586
	end
	return targetRotation
end
function MathUtil.nlerpQuaternionShortestPath(x1, y1, z1, w1, x2, y2, z2, w2, t)
	local c = x1 * x2 + y1 * y2 + z1 * z2 + w1 * w2
	local x = nil
	local y = nil
	local z = nil
	local w = nil
	if c < 0 then
		x = x1 + (-x2 - x1) * t
		y = y1 + (-y2 - y1) * t
		z = z1 + (-z2 - z1) * t
		w = w1 + (-w2 - w1) * t
	else
		x = x1 + (x2 - x1) * t
		y = y1 + (y2 - y1) * t
		z = z1 + (z2 - z1) * t
		w = w1 + (w2 - w1) * t
	end
	local len = 1 / math.sqrt(x * x + y * y + z * z + w * w)
	return x * len, y * len, z * len, w * len
end
function MathUtil.slerpQuaternionShortestPath(x1, y1, z1, w1, x2, y2, z2, w2, t)
	local fCos = x1 * x2 + y1 * y2 + z1 * z2 + w1 * w2
	local fAngle = math.acos(math.clamp(fCos, -1, 1))
	if math.abs(fAngle) < 0.01 then
		return x1, y1, z1, w1
	end
	local fSin = math.sin(fAngle)
	local fInvSin = 1 / fSin
	local fCoeff0 = math.sin((1 - t) * fAngle) * fInvSin
	local fCoeff1 = math.sin(t * fAngle) * fInvSin
	if fCos < 0 then
		fCoeff0 = -fCoeff0
		local x = x1 * fCoeff0 + x2 * fCoeff1
		local y = y1 * fCoeff0 + y2 * fCoeff1
		local z = z1 * fCoeff0 + z2 * fCoeff1
		local w = w1 * fCoeff0 + w2 * fCoeff1
		local len = 1 / math.sqrt(x * x + y * y + z * z + w * w)
		return x * len, y * len, z * len, w * len
	else
		return x1 * fCoeff0 + x2 * fCoeff1, y1 * fCoeff0 + y2 * fCoeff1, z1 * fCoeff0 + z2 * fCoeff1, w1 * fCoeff0 + w2 * fCoeff1
	end
end
function MathUtil.quaternionMadShortestPath(x, y, z, w, x1, y1, z1, w1, t)
	local c = x * x1 + y * y1 + z * z1 + w * w1
	if c < 0 then
		return x - x1 * t, y - y1 * t, z - z1 * t, w - w1 * t
	else
		return x + x1 * t, y + y1 * t, z + z1 * t, w + w1 * t
	end
end
function MathUtil.getDistanceToRectangle2D(posX, posZ, sx, sz, dx, dz, length, widthHalf)
	local d2x = -dz
	local d2z = dx
	local x = posX - sx
	local z = posZ - sz
	local lx = x * dx + z * dz
	local lz = x * d2x + z * d2z
	local distance = nil
	if 0 <= lx and lx <= length then
		distance = math.max(math.abs(lz) - widthHalf, 0)
		return distance
	end
	local tx = 0
	if length < lx then
		tx = length
	end
	if widthHalf < lz then
		distance = math.sqrt((lx - tx) * (lx - tx) + (lz - widthHalf) * (lz - widthHalf))
		return distance
	elseif lz < -widthHalf then
		distance = math.sqrt((lx - tx) * (lx - tx) + (lz + widthHalf) * (lz + widthHalf))
		return distance
	else
		distance = math.abs(lx - tx)
		return distance
	end
end
function MathUtil.getSignedDistanceToLineSegment2D(x, z, sx, sz, dx, dz, length)
	local t = (x - sx) * dx + (z - sz) * dz
	local distance = nil
	local case = nil
	if 0 <= t and t <= length then
		distance = (sz - z) * dx - (sx - x) * dz
		case = 0
		return distance, case
	end
	if t < 0 then
		distance = math.sqrt((sx - x) * (sx - x) + (sz - z) * (sz - z))
		case = 1
		return distance, case
	else
		local ex = sx + length * dx
		local ez = sz + length * dz
		distance = math.sqrt((ex - x) * (ex - x) + (ez - z) * (ez - z))
		case = 2
		return distance, case
	end
end
function MathUtil.getLineLineIntersection2D(x1, z1, dirX1, dirZ1, x2, z2, dirX2, dirZ2)
	local div = dirX1 * dirZ2 - dirX2 * dirZ1
	if math.abs(div) < 0.00001 then
		return false
	else
		local t1 = (dirX2 * (z1 - z2) - dirZ2 * (x1 - x2)) / div
		local t2 = (dirX1 * (z1 - z2) - dirZ1 * (x1 - x2)) / div
		return true, t1, t2
	end
end
function MathUtil.getLineSegmentsIntersection(ax1, az1, ax2, az2, bx1, bz1, bx2, bz2)
	local denominator = (bz2 - bz1) * (ax2 - ax1) - (bx2 - bx1) * (az2 - az1)
	if denominator ~= 0 then
		local uA = ((bx2 - bx1) * (az1 - bz1) - (bz2 - bz1) * (ax1 - bx1)) / denominator
		local uB = ((ax2 - ax1) * (az1 - bz1) - (az2 - az1) * (ax1 - bx1)) / denominator
		if 0 < uA and (uA < 1 and (0 < uB and uB < 1)) then
			local x = ax1 + uA * (ax2 - ax1)
			local z = az1 + uA * (az2 - az1)
			return true, x, z
		end
	end
	return false, 0, 0
end
function MathUtil.getLineSegmentsIntersectionParameter(ax1, az1, ax2, az2, bx1, bz1, bx2, bz2)
	local denominator = (bz2 - bz1) * (ax2 - ax1) - (bx2 - bx1) * (az2 - az1)
	if denominator ~= 0 then
		local uA = ((bx2 - bx1) * (az1 - bz1) - (bz2 - bz1) * (ax1 - bx1)) / denominator
		local uB = ((ax2 - ax1) * (az1 - bz1) - (az2 - az1) * (ax1 - bx1)) / denominator
		if 0 < uA and (uA < 1 and (0 < uB and uB < 1)) then
			return true, uA, uB
		end
	end
	return false, 0, 0
end
function MathUtil.getAreLineSegmentsIntersecting(ax1, az1, ax2, az2, bx1, bz1, bx2, bz2, allowEndStartSamePos)
	if ax1 ~= bx1 or az1 ~= bz1 or ax2 ~= bx2 or az2 ~= bz2 then
		if ax2 == bx1 and (az2 == bz1 and (ax1 == bx2 and az1 == bz2)) then
			return true
		end
		local getOrientation = function(x1, z1, x2, z2, x3, z3)
			local value = (z2 - z1) * (x3 - x2) - (x2 - x1) * (z3 - z2)
			if 0 < value then
				return 1
			elseif value < 0 then
				return 2
			else
				return 0
			end
		end
		local value = (az2 - az1) * (bx1 - ax2) - (ax2 - ax1) * (bz1 - az2)
		local o1 = 0 < value and 1 or (value < 0 and 2 or 0)
		local value = (az2 - az1) * (bx2 - ax2) - (ax2 - ax1) * (bz2 - az2)
		local o2 = 0 < value and 1 or (value < 0 and 2 or 0)
		local value = (bz2 - bz1) * (ax1 - bx2) - (bx2 - bx1) * (az1 - bz2)
		local o3 = 0 < value and 1 or (value < 0 and 2 or 0)
		local value = (bz2 - bz1) * (ax2 - bx2) - (bx2 - bx1) * (az2 - bz2)
		local o4 = 0 < value and 1 or (value < 0 and 2 or 0)
		if o1 ~= o2 and (o3 ~= o4 and (allowEndStartSamePos and ((ax1 ~= bx1 or az1 ~= bz1) and ((ax1 ~= bx2 or az1 ~= bz2) and (ax2 ~= bx1 or az2 ~= bz1))))) then
			if ax2 == bx2 and az2 == bz2 then
				return false
			end
			return true, false
		end
		local onSegment = function(x1, z1, x2, z2, x3, z3)
			if allowEndStartSamePos then
				return false
			else
				return false
			end
		end
		if o1 == 0 and onSegment(ax1, az1, bx1, bz1, ax2, az2) then
			return true, true
		end
		if o2 == 0 and onSegment(ax1, az1, bx2, bz2, ax2, az2) then
			return true, true
		end
		if o3 == 0 and onSegment(bx1, bz1, ax1, az1, bx2, bz2) then
			return true, true
		end
		if o4 == 0 and onSegment(bx1, bz1, ax2, az2, bx2, bz2) then
			return true, true
		end
		return false
	end
end
function MathUtil.getLineBoundingVolumeIntersect(ax1, ay1, ax2, ay2, bx1, by1, bx2, by2)
	local _v40 = false
	if math.min(ax1, ax2) <= math.max(bx1, bx2) then
		_v40 = false
		if math.min(bx1, bx2) <= math.max(ax1, ax2) then
			_v40 = false
			if math.min(ay1, ay2) <= math.max(by1, by2) then
				_v40 = math.min(by1, by2) <= math.max(ay1, ay2)
			end
		end
	end
	return _v40
end
function MathUtil.hasRectangleLineIntersection2D(x1, z1, dirX1, dirZ1, dirX2, dirZ2, x3, z3, dirX3, dirZ3)
	local dir1Length = MathUtil.vector2Length(dirX1, dirZ1)
	local dir2Length = MathUtil.vector2Length(dirX2, dirZ2)
	local dir3Length = MathUtil.vector2Length(dirX3, dirZ3)
	if dir1Length == 0 then
		dir1Length = 1
	end
	if dir2Length == 0 then
		dir2Length = 1
	end
	if dir3Length == 0 then
		dir3Length = 1
	end
	local dirX1_norm = dirX1 / dir1Length
	local dirZ1_norm = dirZ1 / dir1Length
	local dirX2_norm = dirX2 / dir2Length
	local dirZ2_norm = dirZ2 / dir2Length
	local dirX3_norm = dirX3 / dir3Length
	local dirZ3_norm = dirZ3 / dir3Length
	local intersects, t1, t2 = MathUtil.getLineLineIntersection2D(x3, z3, dirX3_norm, dirZ3_norm, x1, z1, dirX1_norm, dirZ1_norm)
	if intersects and (0 < t1 and (t1 < dir3Length and (0 < t2 and t2 < dir1Length))) then
		return true
	end
	intersects, t1, t2 = MathUtil.getLineLineIntersection2D(x3, z3, dirX3_norm, dirZ3_norm, x1, z1, dirX2_norm, dirZ2_norm)
	if intersects and (0 < t1 and (t1 < dir3Length and (0 < t2 and t2 < dir2Length))) then
		return true
	end
	intersects, t1, t2 = MathUtil.getLineLineIntersection2D(x3, z3, dirX3_norm, dirZ3_norm, x1 + dirX1, z1 + dirZ1, dirX2_norm, dirZ2_norm)
	if intersects and (0 < t1 and (t1 < dir3Length and (0 < t2 and t2 < dir2Length))) then
		return true
	end
	intersects, t1, t2 = MathUtil.getLineLineIntersection2D(x3, z3, dirX3_norm, dirZ3_norm, x1 + dirX2, z1 + dirZ2, dirX1_norm, dirZ1_norm)
	if intersects and (0 < t1 and (t1 < dir3Length and (0 < t2 and t2 < dir1Length))) then
		return true
	end
	local p1 = MathUtil.getProjectOnLineParameter(x3, z3, x1, z1, dirX1_norm, dirZ1_norm)
	local p2 = MathUtil.getProjectOnLineParameter(x3, z3, x1, z1, dirX2_norm, dirZ2_norm)
	if 0 < p1 and (p1 < dir1Length and (0 < p2 and p2 < dir2Length)) then
		p1 = MathUtil.getProjectOnLineParameter(x3 + dirX3, z3 + dirZ3, x1, z1, dirX1_norm, dirZ1_norm)
		p2 = MathUtil.getProjectOnLineParameter(x3 + dirX3, z3 + dirZ3, x1, z1, dirX2_norm, dirZ2_norm)
		if 0 < p1 and (p1 < dir1Length and (0 < p2 and p2 < dir2Length)) then
			return true
		end
	end
	return false
end
function MathUtil.getCircleCircleIntersection(x1, y1, r1, x2, y2, r2)
	local dx = x2 - x1
	local dy = y2 - y1
	local dist = MathUtil.vector2Length(dx, dy)
	if dist == 0 and (x1 == x2 and y1 == y2) then
		return nil
	end
	if r1 + r2 < dist then
		return nil
	elseif dist < math.abs(r1 - r2) then
		return nil
	elseif dist == r1 + r2 then
		local x = (x1 - x2) / (r1 + r2) * r1 + x2
		local y = (y1 - y2) / (r1 + r2) * r1 + y2
		return x, y
	else
		local a = (r1 * r1 - r2 * r2 + dist * dist) / (2 * dist)
		local v2x = x1 + dx * a / dist
		local v2y = y1 + dy * a / dist
		local h = math.sqrt(r1 * r1 - a * a)
		local rx = -dy * (h / dist)
		local ry = dx * (h / dist)
		return v2x + rx, v2y + ry, v2x - rx, v2y - ry
	end
end
function MathUtil.hasSphereSphereIntersection(x1, y1, z1, r1, x2, y2, z2, r2)
	local dx = x2 - x1
	local dy = y2 - y1
	local dz = z2 - z1
	local rsum = r1 + r2
	return dx * dx + dy * dy + dz * dz <= rsum * rsum
end
function MathUtil.getHasCircleLineIntersection(circleX, circleZ, radius, lineStartX, lineStartZ, lineEndX, lineEndZ)
	local n = math.abs((lineEndX - lineStartX) * (lineStartZ - circleZ) - (lineStartX - circleX) * (lineEndZ - lineStartZ))
	local d = math.sqrt((lineEndX - lineStartX) * (lineEndX - lineStartX) + (lineEndZ - lineStartZ) * (lineEndZ - lineStartZ))
	local dist = n / d
	if radius < dist then
		return false
	end
	local d1 = math.sqrt((circleX - lineStartX) * (circleX - lineStartX) + (circleZ - lineStartZ) * (circleZ - lineStartZ))
	if d < d1 - radius then
		return false
	end
	local d2 = math.sqrt((circleX - lineEndX) * (circleX - lineEndX) + (circleZ - lineEndZ) * (circleZ - lineEndZ))
	if d < d2 - radius then
		return false
	else
		return true
	end
end
function MathUtil.getCircleLineIntersection(circleX, circleZ, radius, lineStartX, lineStartZ, lineEndX, lineEndZ, limitToLineSegment)
	local x1 = lineStartX - circleX
	local z1 = lineStartZ - circleZ
	local x2 = lineEndX - circleX
	local z2 = lineEndZ - circleZ
	local dx = x2 - x1
	local dz = z2 - z1
	local dr = (dx ^ 2 + dz ^ 2) ^ 0.5
	local d = x1 * z2 - x2 * z1
	local dis = radius ^ 2 * dr ^ 2 - d ^ 2
	if dis < 0 then
		return false
	else
		local sign = dz < 0 and 1 or -1
		local ix1 = circleX + (d * dz + sign * (dz < 0 and -1 or 1) * dx * dis ^ 0.5) / dr ^ 2
		local iz1 = circleZ + (-d * dx + sign * math.abs(dz) * dis ^ 0.5) / dr ^ 2
		local ix2 = circleX + (d * dz - sign * (dz < 0 and -1 or 1) * dx * dis ^ 0.5) / dr ^ 2
		local iz2 = circleZ + (-d * dx - sign * math.abs(dz) * dis ^ 0.5) / dr ^ 2
		if limitToLineSegment ~= false then
			local fraction1 = nil
			local fraction2 = nil
			if math.abs(dz) < math.abs(dx) then
				fraction1 = (ix1 - lineStartX) / dx
				fraction2 = (ix2 - lineStartX) / dx
			else
				fraction1 = (iz1 - lineStartZ) / dz
				fraction2 = (iz2 - lineStartZ) / dz
			end
			if fraction1 < 0 or 1 < fraction1 then
				ix1 = nil
				iz1 = nil
			end
			if fraction2 < 0 or 1 < fraction2 then
				ix2 = nil
				iz2 = nil
			end
		end
		return ix1 ~= nil or ix2 ~= nil, ix1, iz1, ix2, iz2
	end
end
function MathUtil.getClosestPointOnLineSegment(startX, startY, startZ, endX, endY, endZ, targetX, targetY, targetZ)
	local dirTargetX = targetX - startX
	local dirTargetY = targetY - startY
	local dirTargetZ = targetZ - startZ
	local dirLineX = endX - startX
	local dirLineY = endY - startY
	local dirLineZ = endZ - startZ
	local lengthSq = MathUtil.vector3LengthSq(dirLineX, dirLineY, dirLineZ)
	local dot = MathUtil.dotProduct(dirTargetX, dirTargetY, dirTargetZ, dirLineX, dirLineY, dirLineZ)
	local distance = dot / lengthSq
	if distance < 0 then
		return startX, startY, startZ, 0
	elseif 1 < distance then
		return endX, endY, endZ, 1
	else
		return startX + dirLineX * distance, startY + dirLineY * distance, startZ + dirLineZ * distance, distance
	end
end
function MathUtil.getDistanceToLineSegment2D(startX, startZ, endX, endZ, pointX, pointZ)
	local px = endX - startX
	local py = endZ - startZ
	local norm = px * px + py * py
	local u = ((pointX - startX) * px + (pointZ - startZ) * py) / norm
	if 1 < u then
		u = 1
	elseif u < 0 then
		u = 0
	end
	local x = startX + u * px
	local y = startZ + u * py
	local dx = x - pointX
	local dy = y - pointZ
	local dist = math.sqrt(dx * dx + dy * dy)
	return dist
end
function MathUtil.isPointInParallelogram(x, z, startX, startZ, widthX, widthZ, heightX, heightZ)
	local dirX = x - startX
	local dirZ = z - startZ
	local detA = widthX * heightZ - heightX * widthZ
	local detB = dirX * widthZ - widthX * dirZ
	local detC = dirX * heightZ - heightX * dirZ
	local n = -detB / detA
	if 0 <= n and n <= 1 then
		local m = detC / detA
		if 0 <= m and m <= 1 then
			return true
		end
	end
	return false
end
function MathUtil.getPointPointDistance(x1, y1, x2, y2)
	local dx = x1 - x2
	local dy = y1 - y2
	return math.sqrt(dx * dx + dy * dy)
end
function MathUtil.getPointPointDistanceSquared(x1, y1, x2, y2)
	local dx = x1 - x2
	local dy = y1 - y2
	return dx * dx + dy * dy
end
function MathUtil.areaToHa(area, pixelToSqm)
	return area * pixelToSqm / 10000
end
function MathUtil.haToSqm(area)
	return area * 10000
end
function MathUtil.inchToM(inchValue)
	return inchValue * 0.0254
end
function MathUtil.mToInch(mValue)
	return mValue / 0.0254
end
function MathUtil.msToMinutes(ms)
	return ms / 60000
end
function MathUtil.msToHours(ms)
	return ms / 3600000
end
function MathUtil.msToDays(ms)
	return ms / 86400000
end
function MathUtil.minutesToMs(minutes)
	return minutes * 60 * 1000
end
function MathUtil.hoursToMs(hours)
	return hours * 60 * 60 * 1000
end
function MathUtil.daysToMs(days)
	return days * 24 * 60 * 60 * 1000
end
function MathUtil.mpsToKmh(mps)
	return mps * 3.6
end
function MathUtil.kmhToMps(kmh)
	return kmh / 3.6
end
function MathUtil.rpmToMps(rpm, radius)
	return rpm * radius * 0.00377 / 36
end
function MathUtil.getXZWidthAndHeight(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	return startWorldX, startWorldZ, widthWorldX - startWorldX, widthWorldZ - startWorldZ, heightWorldX - startWorldX, heightWorldZ - startWorldZ
end
function MathUtil.getWorldParallelogramOffset(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, offset)
	local widthDirX = widthWorldX - startWorldX
	local widthDirZ = widthWorldZ - startWorldZ
	widthDirX, widthDirZ = MathUtil.vector2Normalize(widthDirX, widthDirZ)
	local heightDirX = heightWorldX - startWorldX
	local heightDirZ = heightWorldZ - startWorldZ
	heightDirX, heightDirZ = MathUtil.vector2Normalize(heightDirX, heightDirZ)
	local offsetStartDirX, offsetStartDirZ = MathUtil.vector2Normalize(widthDirX + heightDirX, widthDirZ + heightDirZ)
	local alphaStart = math.acos(MathUtil.dotProduct(widthDirX, 0, widthDirZ, heightDirX, 0, heightDirZ)) * 0.5
	local moveStartLength = offset / math.sin(alphaStart)
	local newStartWorldX = startWorldX - moveStartLength * offsetStartDirX
	local newStartWorldZ = startWorldZ - moveStartLength * offsetStartDirZ
	local offsetWidthDirX, offsetWidthDirZ = MathUtil.vector2Normalize(heightDirX - widthDirX, heightDirZ - widthDirZ)
	local alphaWidth = math.acos(MathUtil.dotProduct(heightDirX, 0, heightDirZ, -widthDirX, 0, -widthDirZ)) * 0.5
	local moveWidthLength = offset / math.sin(alphaWidth)
	local newWidthWorldX = widthWorldX - moveWidthLength * offsetWidthDirX
	local newWidthWorldZ = widthWorldZ - moveWidthLength * offsetWidthDirZ
	local newHeightWorldX = heightWorldX + moveWidthLength * offsetWidthDirX
	local newHeightWorldZ = heightWorldZ + moveWidthLength * offsetWidthDirZ
	return newStartWorldX, newStartWorldZ, newWidthWorldX, newWidthWorldZ, newHeightWorldX, newHeightWorldZ
end
function MathUtil.getWorldParallelogramFromLine(x, z, endX, endZ, width)
	local dirX, dirZ = MathUtil.vector2Normalize(endX - x, endZ - z)
	local normalX = -dirZ
	local normalZ = dirX
	local widthHalf = width * 0.5
	local startX = x - normalX * widthHalf
	local startZ = z - normalZ * widthHalf
	local widthX = x + normalX * widthHalf
	local widthZ = z + normalZ * widthHalf
	local heightX = endX - normalX * widthHalf
	local heightZ = endZ - normalZ * widthHalf
	return startX, startZ, widthX, widthZ, heightX, heightZ
end
function MathUtil.getNumOfSetBits(bitmask)
	bitmask = bitmask - bit32.band(bit32.rshift(bitmask, 1), 1431655765)
	bitmask = bit32.band(bitmask, 858993459) + bit32.band(bit32.rshift(bitmask, 2), 858993459)
	bitmask = bit32.band(bitmask + bit32.rshift(bitmask, 4), 252645135) * 16843009
	return bit32.rshift(bitmask, 24)
end
function MathUtil.bitsToMask(...)
	local mask = 0
	for i = 1, select("#", ...) do
		mask = bit32.bor(mask, math.pow(2, select(i, ...)))
	end
	return mask
end
function MathUtil.getBinary(number)
	local bits = {}
	while 0 < number do
		local rest = number % 2
		table.insert(bits, rest)
		number = (number - rest) / 2
	end
	return bits
end
function MathUtil.numberToSetBits(number)
	local bits = MathUtil.getBinary(number)
	local setBits = {}
	for i, bit in ipairs(bits) do
		if bit == 1 then
			table.insert(setBits, i - 1)
		end
	end
	return setBits
end
function MathUtil.numberToSetBitsStr(number, separator)
	local setBits = MathUtil.numberToSetBits(number)
	separator = separator or ", "
	local returnStr = ""
	for i, bit in ipairs(setBits) do
		if 1 < i then
			returnStr = returnStr .. separator
		end
		returnStr = returnStr .. bit
	end
	return returnStr
end
function MathUtil.getNumRequiredBits(integer)
	assert(0 <= integer)
	if integer == 0 then
		return 1
	else
		return math.floor(math.log(integer, 2) + 1)
	end
end
function MathUtil.getBrightnessFromColor(r, g, b)
	return r * 0.2125 + g * 0.7154 + b * 0.0721
end
function MathUtil.getHorizontalRotationFromDeviceGravity(x, y, z)
	if x == 0 and (y == 0 and z == 0) then
		return 0
	end
	local angle = 0
	if x <= 0 then
		local maxAngle = 0.43633222222222223
		angle = math.atan2(y, x)
		angle = angle < 0 and angle + 3.141592653589793 or angle - 3.141592653589793
		angle = math.clamp(angle, -0.43633222222222223, maxAngle)
		local zScale0 = 0.9
		local zScale1 = 0.65
		angle = angle * math.clamp((0.9 - math.abs(z)) / 0.25, 0, 1)
	end
	return angle
end
function MathUtil.getSteeringAngleFromDeviceGravity(x, y, z)
	if x == 0 and (y == 0 and z == 0) then
		return 0
	end
	local STEER_DEADZONE = 0.06981315555555556
	local MAX_STEER_ANGLE = 0.43633222222222223
	local angle = -math.asin(math.clamp(y, -1, 1))
	if STEER_DEADZONE < angle then
		angle = math.min(angle, 0.43633222222222223) - 0.06981315555555556
	elseif angle < -0.06981315555555556 then
		angle = math.max(angle, -0.43633222222222223) + 0.06981315555555556
	else
		angle = 0
	end
	angle = angle / 0.36651906666666667
	return angle
end
function MathUtil.catmullRom(p0, p1, p2, p3, t)
	return 0.5 * (2 * p1 + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t + (-p0 + 3 * p1 - 3 * p2 + p3) * t * t * t)
end
function MathUtil.equalEpsilon(a, b, epsilon)
	if a == nil or b == nil then
		return false
	end
	epsilon = epsilon or 0.0001
	return math.abs(a - b) < epsilon
end
function MathUtil.floatRange(startVal, endVal, step)
	if step == 0 or 0 < step and endVal < startVal or step < 0 and startVal < endVal then
		printError(string.format("Error: (%f, %f, %f) invalid arguments, range is endless", startVal, endVal, step))
		printCallstack()
		return function()
			return nil
		end
	end
	local currentIndex = 0
	if 0 < step then
		local floatIterator = function()
			local value = startVal + currentIndex * step
			if endVal < value then
				return nil
			else
				currentIndex = currentIndex + 1
				return value
			end
		end
		return floatIterator
	else
		local floatIterator = function()
			local value = startVal + currentIndex * step
			if value < endVal then
				return nil
			else
				currentIndex = currentIndex + 1
				return value
			end
		end
		return floatIterator
	end
end
function MathUtil.smoothstep(min, max, x)
	local t = math.clamp((x - min) / (max - min), 0, 1)
	return t * t * (3 - 2 * t)
end
function MathUtil.snapValue(value, step)
	if step == 0 then
		return value
	else
		local snappedValue = math.round(value / step) * step
		return snappedValue
	end
end
function MathUtil.getIndexOfFirstNonZeroFractionDigit(number)
	number = math.abs(number)
	if number == 0 then
		return 0
	else
		local fractionDigitIndex = 0
		while number < 1 do
			number = number * 10
			fractionDigitIndex = fractionDigitIndex + 1
		end
		return fractionDigitIndex
	end
end
function MathUtil.vector2Rotate(x, y, angle)
	local cosValue = math.cos(angle)
	local sinValue = math.sin(angle)
	local rotatedX = x * cosValue - y * sinValue
	local rotatedY = x * sinValue + y * cosValue
	return rotatedX, rotatedY
end
function MathUtil.getPolygon2DSize(vertices)
	if vertices == nil or #vertices < 3 then
		return nil
	end
	local size = 0
	local node2Index = #vertices
	for node1Index = 1, #vertices do
		local node1 = vertices[node1Index]
		local node2 = vertices[node2Index]
		local x1, _, z1 = getWorldTranslation(node1)
		local x2, _, z2 = getWorldTranslation(node2)
		local averageHeight = (z1 + z2) * 0.5
		local width = x2 - x1
		local edgeSize = width * averageHeight
		size = size + edgeSize
		node2Index = node1Index
	end
	return math.abs(size)
end
function MathUtil.getPolygonLabel(vertices, precision)
	precision = precision or 1
	local polygonPoints = {}
	for _, vertex in ipairs(vertices) do
		local x, _, z = getWorldTranslation(vertex)
		table.insert(polygonPoints, { x, z })
	end
	local sortQueue = function(a, b)
		if a.max < b.max then
			return true
		else
			return false
		end
	end
	local getSegDistSq = function(px, py, a, b)
		local x = a[1]
		local y = a[2]
		local dx = b[1] - x
		local dy = b[2] - y
		if dx ~= 0 or dy ~= 0 then
			local t = ((px - x) * dx + (py - y) * dy) / (dx * dx + dy * dy)
			if 1 < t then
				x = b[1]
				y = b[2]
			elseif 0 < t then
				x = x + dx * t
				y = y + dy * t
			end
		end
		dx = px - x
		dy = py - y
		return dx * dx + dy * dy
	end
	local pointToPolygonDist = function(x, y)
		local inside = false
		local minDistSq = math.huge
		local j = #polygonPoints
		for i = 1, #polygonPoints do
			local a = polygonPoints[i]
			local b = polygonPoints[j]
			if y < a[2] ~= (y < b[2]) and x < (b[1] - a[1]) * (y - a[2]) / (b[2] - a[2]) + a[1] then
				inside = not inside
			end
			minDistSq = math.min(minDistSq, getSegDistSq(x, y, a, b))
			j = i
		end
		if minDistSq == 0 then
			return 0
		else
			return (inside and 1 or -1) * math.sqrt(minDistSq)
		end
	end
	local createCell = function(x, y, h)
		local d = pointToPolygonDist(x, y)
		local cell = { x = x, y = y, h = h, d = d, max = d + h * 1.4142135623730951 }
		return cell
	end
	local getCentroidCell = function()
		local area = 0
		local x = 0
		local y = 0
		local j = #polygonPoints
		for i = 1, #polygonPoints do
			local a = polygonPoints[i]
			local b = polygonPoints[j]
			local f = a[1] * b[2] - b[1] * a[2]
			x = x + (a[1] + b[1]) * f
			y = y + (a[2] + b[2]) * f
			area = area + f * 3
			j = i
		end
		if area == 0 then
			local x = polygonPoints[1][0]
			local y = polygonPoints[1][1]
			local d = pointToPolygonDist(x, y)
			local cell = { x = x, y = y, h = 0, d = d, max = d + 0 }
			return cell
		else
			local x = x / area
			local y = y / area
			local d = pointToPolygonDist(x, y)
			local cell = { x = x, y = y, h = 0, d = d, max = d + 0 }
			return cell
		end
	end
	local minX = nil
	local minY = nil
	local maxX = nil
	local maxY = nil
	for k, p in ipairs(polygonPoints) do
		if k == 1 or p[1] < minX then
			minX = p[1]
		end
		if k == 1 or p[2] < minY then
			minY = p[2]
		end
		if k == 1 or maxX < p[1] then
			maxX = p[1]
		end
		if k == 1 or maxY < p[2] then
			maxY = p[2]
		end
	end
	local width = maxX - minX
	local height = maxY - minY
	local cellSize = math.min(width, height)
	local h = cellSize / 2
	if cellSize == 0 then
		return minX, minY
	else
		local queue = {}
		local push = function(element)
			table.insert(queue, element)
		end
		local pop = function()
			table.sort(queue, sortQueue)
			return table.remove(queue, 1)
		end
		for x = minX, maxX, cellSize do
			for y = minY, maxY, cellSize do
				local x = x + h
				local y = y + h
				local h = h
				local d = pointToPolygonDist(x, y)
				local cell = { x = x, y = y, h = h, d = d, max = d + h * 1.4142135623730951 }
				local element = cell
				table.insert(queue, element)
			end
		end
		local bestCell = getCentroidCell()
		local x = minX + width / 2
		local y = minY + height / 2
		local d = pointToPolygonDist(x, y)
		local cell = { x = x, y = y, h = 0, d = d, max = d + 0 }
		local bboxCell = cell
		if bestCell.d < bboxCell.d then
			bestCell = bboxCell
		end
		while 0 < #queue do
			table.sort(queue, sortQueue)
			local cell = table.remove(queue, 1)
			if bestCell.d < cell.d then
				bestCell = cell
			end
			if cell.max - bestCell.d <= precision then
				continue
			end
			h = cell.h / 2
			local x = cell.x - h
			local y = cell.y - h
			local h = h
			local d = pointToPolygonDist(x, y)
			local cell = { x = x, y = y, h = h, d = d, max = d + h * 1.4142135623730951 }
			local element = cell
			table.insert(queue, element)
			local x = cell.x + h
			local y = cell.y - h
			local h = h
			local d = pointToPolygonDist(x, y)
			local cell = { x = x, y = y, h = h, d = d, max = d + h * 1.4142135623730951 }
			local element = cell
			table.insert(queue, element)
			local x = cell.x - h
			local y = cell.y + h
			local h = h
			local d = pointToPolygonDist(x, y)
			local cell = { x = x, y = y, h = h, d = d, max = d + h * 1.4142135623730951 }
			local element = cell
			table.insert(queue, element)
			local x = cell.x + h
			local y = cell.y + h
			local h = h
			local d = pointToPolygonDist(x, y)
			local cell = { x = x, y = y, h = h, d = d, max = d + h * 1.4142135623730951 }
			local element = cell
			table.insert(queue, element)
		end
		return bestCell.x, bestCell.y
	end
end
function MathUtil.symmetricDipCurve(value, alpha, maxValue)
	local curveStrength = 4 * alpha * maxValue
	local linearAdjust = -4 * alpha * maxValue
	return curveStrength * value ^ 2 + linearAdjust * value + maxValue
end
function MathUtil.convertStringToNumber(value)
	local valueString = string.trim(value)
	if valueString == "" then
		return 0
	else
		valueString = string.gsub(valueString, "%s+", "")
		valueString = string.gsub(valueString, "_", "")
		valueString = string.gsub(valueString, ",", ".")
		local number = tonumber(valueString)
		return number or 0
	end
end
