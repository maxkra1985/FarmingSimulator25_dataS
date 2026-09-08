MathUtil = {}

function MathUtil.isNan(value)
	return value ~= value
end

function MathUtil.isInt(number)
	return math.round(number) == number
end

function MathUtil.isInf(number)
	return number == -math.huge and true or number == math.huge
end

function MathUtil.isFinite(number)
	return not (MathUtil.isNan(number) or MathUtil.isInf(number))
end
function MathUtil.getIsValidTransformationValue(...)
	for v5_ = 1, select("#", ...) do
		local v6_ = select(v5_, ...)
		if v6_ == nil then
			return false
		end
		if tonumber(v6_) == nil then
			return false
		end
		if v6_ ~= v6_ then
			return false
		end
		if v6_ == math.huge then
			return false
		end
		if v6_ == -math.huge then
			return false
		end
	end
	return true
end

function MathUtil.randomFloat(lowerValue, upperValue)
	return lowerValue + math.random() * (upperValue - lowerValue)
end

-- Local values: exp
function MathUtil.round(value, precision)
	if value == nil then
		return nil
	end
	if not precision then
		local v11_ = value + 0.5
		return math.floor(v11_)
	end
	local v12_ = 10 ^ precision
	local v13_ = value * v12_ + 0.5
	return math.floor(v13_) / v12_
end

function MathUtil.roundToStep(value, step)
	if value == nil then
		return nil
	else
		local v16_ = step or 0.5
		if value >= 0 then
			local v17_ = value / v16_ + 0.5
			return math.floor(v17_) * v16_
		else
			local v18_ = value / v16_ - 0.5
			return math.ceil(v18_) * v16_
		end
	end
end

function MathUtil.degToRad(degValue)
	return degValue == nil and 0 or math.rad(degValue)
end

function MathUtil.lerp(v1, v2, alpha)
	return v1 + (v2 - v1) * alpha
end

function MathUtil.inverseLerp(v1, v2, cv)
	local v26_ = v1 - v2
	if math.abs(v26_) < 0.0001 then
		return 0
	end
	local v27_ = (cv - v1) / (v2 - v1)
	return math.clamp(v27_, 0, 1)
end

-- Local values: diff
function MathUtil.timeLerp(startTime, endTime, currentTime)
	if startTime == endTime then
		return 0
	end
	if endTime < startTime then
		local v31_ = 24 - startTime
		endTime = endTime + v31_
		currentTime = (currentTime + v31_) % 24
		startTime = 0
	end
	return (currentTime - startTime) / (endTime - startTime)
end

function MathUtil.getIsOutOfBounds(value, limit1, limit2)
	if limit1 < limit2 then
		return value < limit1 and true or limit2 < value
	else
		return limit1 < value and true or value < limit2
	end
end

-- Local values: percent
function MathUtil.getFlooredPercent(value, maxValue)
	local v37_
	if maxValue > 0 then
		local v38_ = value / maxValue * 100
		local v39_ = math.floor(v38_)
		if v39_ > 99 and value < maxValue then
			return 99
		end
		v37_ = v39_ < 1 and value > 0 and 1 or v39_
	else
		v37_ = 0
	end
	return v37_
end

function MathUtil.getFlooredBounded(value, minValue, maxValue)
	if value == minValue then
		return minValue
	end
	if value == maxValue then
		return maxValue
	end
	local v43_ = math.floor(value)
	local v44_ = minValue + 1
	local v45_ = math.max(v43_, v44_)
	local v46_ = maxValue - 1
	return math.min(v45_, v46_)
end

function MathUtil.getValidLimit(limit)
	while limit < -3.141592653589793 do
		limit = limit + 6.283185307179586
	end
	while limit > 3.141592653589793 do
		limit = limit - 6.283185307179586
	end
	return limit
end

-- Local values: a
function MathUtil.getAngleDifference(alpha, beta)
	local v50_ = alpha - beta
	return MathUtil.getValidLimit(v50_)
end

-- Local values: xzLength
function MathUtil.eulerToDirection(yaw, pitch)
	local v53_ = -pitch
	local v54_ = math.cos(v53_)
	local v55_ = v54_ * math.sin(yaw)
	local v56_ = -pitch
	return v55_, math.sin(v56_), v54_ * math.cos(yaw)
end

function MathUtil.directionToPitchYaw(directionX, directionY, directionZ)
	local v60_ = -directionY
	return math.asin(v60_), math.atan2(directionX, directionZ)
end

function MathUtil.vector2Length(x, y)
	local v63_ = x * x + y * y
	return math.sqrt(v63_)
end

function MathUtil.vector2LengthSq(x, y)
	return x * x + y * y
end

-- Local values: length
function MathUtil.vector2Normalize(x, y)
	local v68_ = x * x + y * y
	local v69_ = math.sqrt(v68_)
	return x / v69_, y / v69_
end

function MathUtil.vector2SetLength(x, y, length)
	local v73_, v74_ = MathUtil.vector2Normalize(x, y)
	return v73_ * length, v74_ * length
end

function MathUtil.vector2Lerp(x1, y1, x2, y2, alpha)
	return x1 + (x2 - x1) * alpha, y1 + (y2 - y1) * alpha
end

function MathUtil.vector3Length(x, y, z)
	local v83_ = x * x + y * y + z * z
	return math.sqrt(v83_)
end

function MathUtil.vector3LengthSq(x, y, z)
	return x * x + y * y + z * z
end

-- Local values: length
function MathUtil.vector3Normalize(x, y, z)
	local v90_ = MathUtil.vector3Length(x, y, z)
	return x / v90_, y / v90_, z / v90_
end

function MathUtil.vector3SetLength(x, y, z, length)
	local v95_, v96_, v97_ = MathUtil.vector3Normalize(x, y, z)
	return v95_ * length, v96_ * length, v97_ * length
end

-- Local values: length
function MathUtil.vector3Clamp(x, y, z, minVal, maxVal)
	local v103_ = MathUtil.vector3Length(x, y, z)
	if v103_ > 0 then
		local v104_ = math.clamp(v103_, minVal, maxVal)
		x, y, z = MathUtil.vector3SetLength(x, y, z, v104_)
	end
	return x, y, z
end

function MathUtil.vector3Lerp(x1, y1, z1, x2, y2, z2, alpha)
	return x1 + (x2 - x1) * alpha, y1 + (y2 - y1) * alpha, z1 + (z2 - z1) * alpha
end
MathUtil.lerp3 = MathUtil.vector3Lerp

-- Local values: alpha1, alpha2, alpha3, value
function MathUtil.inverseVector3Lerp(x1, y1, z1, x2, y2, z2, c1, c2, c3)
	local v121_ = MathUtil.inverseLerp(x1, x2, c1)
	local v122_ = MathUtil.inverseLerp(y1, y2, c2)
	local v123_ = MathUtil.inverseLerp(z1, z2, c3)
	local v124_ = 0
	if x1 ~= x2 then
		return v121_
	end
	if y1 ~= y2 then
		return v122_
	end
	if z1 == z2 then
		v123_ = v124_
	end
	return v123_
end

function MathUtil.vector3ArrayLerp(v1, v2, alpha)
	return v1[1] + (v2[1] - v1[1]) * alpha, v1[2] + (v2[2] - v1[2]) * alpha, v1[3] + (v2[3] - v1[3]) * alpha
end

-- Local values: alpha1, alpha2, alpha3, value
function MathUtil.inverseVector3ArrayLerp(v1, v2, cv)
	local v131_ = MathUtil.inverseLerp(v1[1], v2[1], cv[1])
	local v132_ = MathUtil.inverseLerp(v1[2], v2[2], cv[2])
	local v133_ = MathUtil.inverseLerp(v1[3], v2[3], cv[3])
	local v134_ = 0
	if v1[1] ~= v2[1] then
		return v131_
	end
	if v1[2] ~= v2[2] then
		return v132_
	end
	if v1[3] == v2[3] then
		v133_ = v134_
	end
	return v133_
end

function MathUtil.vector3Transformation(x, y, z, m11, m12, m13, m21, m22, m23, m31, m32, m33)
	return x * m11 + y * m21 + z * m31, x * m12 + y * m22 + z * m32, x * m13 + y * m23 + z * m33
end

-- Local values: normX, normY, normZ
function MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, xOffset, yOffset, zOffset)
	local v159_, v160_, v161_ = MathUtil.crossProduct(upX, upY, upZ, dirX, dirY, dirZ)
	return x + v159_ * xOffset + upX * yOffset + dirX * zOffset, y + v160_ * xOffset + upY * yOffset + dirY * zOffset, z + v161_ * xOffset + upZ * yOffset + dirZ * zOffset
end

function MathUtil.dotProduct(ax, ay, az, bx, by, bz)
	return ax * bx + ay * by + az * bz
end

function MathUtil.crossProduct(ax, ay, az, bx, by, bz)
	return ay * bz - az * by, az * bx - ax * bz, ax * by - ay * bx
end

-- Local values: dot, length1, length2
function MathUtil.getVectorAngleDifference(dirX1, dirY1, dirZ1, dirX2, dirY2, dirZ2)
	local v180_ = dirX1 * dirX2 + dirY1 * dirY2 + dirZ1 * dirZ2
	local v181_ = dirX1 * dirX1 + dirY1 * dirY1 + dirZ1 * dirZ1
	local v182_ = math.sqrt(v181_)
	local v183_ = dirX2 * dirX2 + dirY2 * dirY2 + dirZ2 * dirZ2
	local v184_ = v180_ / (v182_ * math.sqrt(v183_) + 1e-6)
	return math.acos(v184_)
end

-- Local values: dot1, dot2
function MathUtil.getSignedAngleBetweenVectors2D(dirX1, dirZ1, dirX2, dirZ2)
	local v189_ = dirX1 * dirX2 + dirZ1 * dirZ2
	local v190_ = dirZ1 * dirX2 + -dirX1 * dirZ2
	return math.acos(v189_) * math.sign(v190_)
end

function MathUtil.getYRotationFromDirection(dx, dz)
	return math.atan2(dx, dz)
end

function MathUtil.getDirectionFromYRotation(rotY)
	return math.sin(rotY), math.cos(rotY)
end

-- Local values: rot, len
function MathUtil.getRotationLimitedVector2(x, y, minRot, maxRot)
	local v198_ = -math.atan2(y, x)
	if v198_ < minRot or maxRot < v198_ then
		if v198_ < minRot then
			maxRot = minRot
		end
		local v199_ = x * x + y * y
		local v200_ = math.sqrt(v199_)
		local v201_ = -maxRot
		x = math.cos(v201_) * v200_
		local v202_ = -maxRot
		y = math.sin(v202_) * v200_
	end
	return x, y
end

-- Local values: num, num2, num3, num4, num5, num6, num7, num8, num9, num10, num11, num12, x, y, z
function MathUtil.quaternionVectorMultiplication(quatX, quatY, quatZ, quatW, vecX, vecY, vecZ)
	local v210_ = quatX * 2
	local v211_ = quatY * 2
	local v212_ = quatZ * 2
	local v213_ = quatX * v210_
	local v214_ = quatY * v211_
	local v215_ = quatZ * v212_
	local v216_ = quatX * v211_
	local v217_ = quatX * v212_
	local v218_ = quatY * v212_
	local v219_ = quatW * v210_
	local v220_ = quatW * v211_
	local v221_ = quatW * v212_
	return (1 - (v214_ + v215_)) * vecX + (v216_ - v221_) * vecY + (v217_ + v220_) * vecZ, (v216_ + v221_) * vecX + (1 - (v213_ + v215_)) * vecY + (v218_ - v219_) * vecZ, (v217_ - v220_) * vecX + (v218_ + v219_) * vecY + (1 - (v213_ + v214_)) * vecZ
end

-- Local values: dx, dz, dot
function MathUtil.projectOnLine(px, pz, lineX, lineZ, normlineDirX, normlineDirZ)
	local v228_ = px - lineX
	local v229_ = pz - lineZ
	local v230_ = v228_ * normlineDirX + v229_ * normlineDirZ
	return lineX + normlineDirX * v230_, lineZ + normlineDirZ * v230_
end

-- Local values: dx, dz, dot
function MathUtil.getProjectOnLineParameter(px, pz, lineX, lineZ, normlineDirX, normlineDirZ)
	local v237_ = px - lineX
	local v238_ = pz - lineZ
	return v237_ * normlineDirX + v238_ * normlineDirZ
end

function MathUtil.quaternionMult(x, y, z, w, x1, y1, z1, w1)
	return y * z1 - z * y1 + w * x1 + x * w1, z * x1 - x * z1 + w * y1 + y * w1, x * y1 - y * x1 + w * z1 + z * w1, w * w1 - x * x1 - y * y1 - z * z1
end

-- Local values: len
function MathUtil.quaternionNormalized(x, y, z, w)
	local v251_ = x * x + y * y + z * z + w * w
	local v252_ = math.sqrt(v251_)
	if v252_ > 0 then
		v252_ = 1 / v252_
	end
	return x * v252_, y * v252_, z * v252_, w * v252_
end

-- Local values: fCos, fAngle, fSin, fInvSin, fCoeff0, fCoeff1
function MathUtil.slerpQuaternion(x1, y1, z1, w1, x2, y2, z2, w2, t)
	local v262_ = x1 * x2 + y1 * y2 + z1 * z2 + w1 * w2
	local v263_ = math.acos(v262_)
	if math.abs(v263_) < 0.01 then
		return x1, y1, z1, w1
	end
	local v264_ = 1 / math.sin(v263_)
	local v265_ = (1 - t) * v263_
	local v266_ = math.sin(v265_) * v264_
	local v267_ = t * v263_
	local v268_ = math.sin(v267_) * v264_
	return x1 * v266_ + x2 * v268_, y1 * v266_ + y2 * v268_, z1 * v266_ + z2 * v268_, w1 * v266_ + w2 * v268_
end

function MathUtil.normalizeRotationForShortestPath(targetRotation, curRotation)
	while curRotation < targetRotation do
		targetRotation = targetRotation - 6.283185307179586
	end
	while targetRotation < curRotation do
		targetRotation = targetRotation + 6.283185307179586
	end
	if targetRotation - curRotation > curRotation + 6.283185307179586 - targetRotation then
		targetRotation = targetRotation - 6.283185307179586
	end
	return targetRotation
end

-- Local values: c, x, y, z, w, len
function MathUtil.nlerpQuaternionShortestPath(x1, y1, z1, w1, x2, y2, z2, w2, t)
	local v280_, v281_, v282_, v283_
	if x1 * x2 + y1 * y2 + z1 * z2 + w1 * w2 < 0 then
		v280_ = x1 + (-x2 - x1) * t
		v281_ = y1 + (-y2 - y1) * t
		v282_ = z1 + (-z2 - z1) * t
		v283_ = w1 + (-w2 - w1) * t
	else
		v280_ = x1 + (x2 - x1) * t
		v281_ = y1 + (y2 - y1) * t
		v282_ = z1 + (z2 - z1) * t
		v283_ = w1 + (w2 - w1) * t
	end
	local v284_ = v280_ * v280_ + v281_ * v281_ + v282_ * v282_ + v283_ * v283_
	local v285_ = 1 / math.sqrt(v284_)
	return v280_ * v285_, v281_ * v285_, v282_ * v285_, v283_ * v285_
end

-- Local values: fCos, fAngle, fSin, fInvSin, fCoeff0, fCoeff1, x, y, z, w, len
function MathUtil.slerpQuaternionShortestPath(x1, y1, z1, w1, x2, y2, z2, w2, t)
	local v295_ = x1 * x2 + y1 * y2 + z1 * z2 + w1 * w2
	local v296_ = math.clamp(v295_, -1, 1)
	local v297_ = math.acos(v296_)
	if math.abs(v297_) < 0.01 then
		return x1, y1, z1, w1
	end
	local v298_ = 1 / math.sin(v297_)
	local v299_ = (1 - t) * v297_
	local v300_ = math.sin(v299_) * v298_
	local v301_ = t * v297_
	local v302_ = math.sin(v301_) * v298_
	if v295_ >= 0 then
		return x1 * v300_ + x2 * v302_, y1 * v300_ + y2 * v302_, z1 * v300_ + z2 * v302_, w1 * v300_ + w2 * v302_
	end
	local v303_ = -v300_
	local v304_ = x1 * v303_ + x2 * v302_
	local v305_ = y1 * v303_ + y2 * v302_
	local v306_ = z1 * v303_ + z2 * v302_
	local v307_ = w1 * v303_ + w2 * v302_
	local v308_ = v304_ * v304_ + v305_ * v305_ + v306_ * v306_ + v307_ * v307_
	local v309_ = 1 / math.sqrt(v308_)
	return v304_ * v309_, v305_ * v309_, v306_ * v309_, v307_ * v309_
end

-- Local values: c
function MathUtil.quaternionMadShortestPath(x, y, z, w, x1, y1, z1, w1, t)
	if x * x1 + y * y1 + z * z1 + w * w1 < 0 then
		return x - x1 * t, y - y1 * t, z - z1 * t, w - w1 * t
	else
		return x + x1 * t, y + y1 * t, z + z1 * t, w + w1 * t
	end
end

-- Local values: d2x, d2z, x, z, lx, lz, distance, tx
function MathUtil.getDistanceToRectangle2D(posX, posZ, sx, sz, dx, dz, length, widthHalf)
	local v327_ = -dz
	local v328_ = posX - sx
	local v329_ = posZ - sz
	local v330_ = v328_ * dx + v329_ * dz
	local v331_ = v328_ * v327_ + v329_ * dx
	if v330_ >= 0 and v330_ <= length then
		local v332_ = math.abs(v331_) - widthHalf
		return math.max(v332_, 0)
	else
		local v333_ = length >= v330_ and 0 or length
		if widthHalf < v331_ then
			local v334_ = (v330_ - v333_) * (v330_ - v333_) + (v331_ - widthHalf) * (v331_ - widthHalf)
			return math.sqrt(v334_)
		elseif v331_ < -widthHalf then
			local v335_ = (v330_ - v333_) * (v330_ - v333_) + (v331_ + widthHalf) * (v331_ + widthHalf)
			return math.sqrt(v335_)
		else
			local v336_ = v330_ - v333_
			return math.abs(v336_)
		end
	end
end

-- Local values: t, distance, case, ex, ez
function MathUtil.getSignedDistanceToLineSegment2D(x, z, sx, sz, dx, dz, length)
	local v344_ = (x - sx) * dx + (z - sz) * dz
	if v344_ >= 0 and v344_ <= length then
		return (sz - z) * dx - (sx - x) * dz, 0
	end
	if v344_ < 0 then
		local v345_ = (sx - x) * (sx - x) + (sz - z) * (sz - z)
		return math.sqrt(v345_), 1
	end
	local v346_ = sx + length * dx
	local v347_ = sz + length * dz
	local v348_ = (v346_ - x) * (v346_ - x) + (v347_ - z) * (v347_ - z)
	return math.sqrt(v348_), 2
end

-- Local values: div, t1, t2
function MathUtil.getLineLineIntersection2D(x1, z1, dirX1, dirZ1, x2, z2, dirX2, dirZ2)
	local v357_ = dirX1 * dirZ2 - dirX2 * dirZ1
	if math.abs(v357_) < 0.00001 then
		return false
	else
		return true, (dirX2 * (z1 - z2) - dirZ2 * (x1 - x2)) / v357_, (dirX1 * (z1 - z2) - dirZ1 * (x1 - x2)) / v357_
	end
end

-- Local values: denominator, uA, uB, x, z
function MathUtil.getLineSegmentsIntersection(ax1, az1, ax2, az2, bx1, bz1, bx2, bz2)
	local v366_ = (bz2 - bz1) * (ax2 - ax1) - (bx2 - bx1) * (az2 - az1)
	if v366_ ~= 0 then
		local v367_ = ((bx2 - bx1) * (az1 - bz1) - (bz2 - bz1) * (ax1 - bx1)) / v366_
		local v368_ = ((ax2 - ax1) * (az1 - bz1) - (az2 - az1) * (ax1 - bx1)) / v366_
		if v367_ > 0 and (v367_ < 1 and (v368_ > 0 and v368_ < 1)) then
			return true, ax1 + v367_ * (ax2 - ax1), az1 + v367_ * (az2 - az1)
		end
	end
	return false, 0, 0
end

-- Local values: denominator, uA, uB
function MathUtil.getLineSegmentsIntersectionParameter(ax1, az1, ax2, az2, bx1, bz1, bx2, bz2)
	local v377_ = (bz2 - bz1) * (ax2 - ax1) - (bx2 - bx1) * (az2 - az1)
	if v377_ ~= 0 then
		local v378_ = ((bx2 - bx1) * (az1 - bz1) - (bz2 - bz1) * (ax1 - bx1)) / v377_
		local v379_ = ((ax2 - ax1) * (az1 - bz1) - (az2 - az1) * (ax1 - bx1)) / v377_
		if v378_ > 0 and (v378_ < 1 and (v379_ > 0 and v379_ < 1)) then
			return true, v378_, v379_
		end
	end
	return false, 0, 0
end

-- Local values: x1, z1, x2, z2, x3, z3, getOrientation, value, x1, z1, x2, z2, x3, z3, o1, value, x1, z1, x2, z2, x3, z3, o2, value, x1, z1, x2, z2, x3, z3, o3, value, o4, onSegment
function MathUtil.getAreLineSegmentsIntersecting(ax1, az1, ax2, az2, bx1, bz1, bx2, bz2, allowEndStartSamePos)
	if ax1 == bx1 and (az1 == bz1 and (ax2 == bx2 and az2 == bz2)) or ax2 == bx1 and (az2 == bz1 and (ax1 == bx2 and az1 == bz2)) then
		return true
	else
		local v389_ = (az2 - az1) * (bx1 - ax2) - (ax2 - ax1) * (bz1 - az2)
		local v390_ = v389_ > 0 and 1 or (v389_ < 0 and 2 or 0)
		local v391_ = (az2 - az1) * (bx2 - ax2) - (ax2 - ax1) * (bz2 - az2)
		local v392_ = v391_ > 0 and 1 or (v391_ < 0 and 2 or 0)
		local v393_ = (bz2 - bz1) * (ax1 - bx2) - (bx2 - bx1) * (az1 - bz2)
		local v394_ = v393_ > 0 and 1 or (v393_ < 0 and 2 or 0)
		local v395_ = (bz2 - bz1) * (ax2 - bx2) - (bx2 - bx1) * (az2 - bz2)
		local v396_ = v395_ > 0 and 1 or (v395_ < 0 and 2 or 0)
		if v390_ == v392_ or v394_ == v396_ then
			local function v405_(p397_, p398_, p399_, p400_, p401_, p402_)
				-- upvalues: (copy) allowEndStartSamePos
				if allowEndStartSamePos then
					local v403_
					if p399_ < math.max(p397_, p401_) and (math.min(p397_, p401_) < p399_ and p400_ < math.max(p398_, p402_)) then
						v403_ = math.min(p398_, p402_) < p400_
					else
						v403_ = false
					end
					return v403_
				else
					local v404_
					if p399_ <= math.max(p397_, p401_) and (math.min(p397_, p401_) <= p399_ and p400_ <= math.max(p398_, p402_)) then
						v404_ = math.min(p398_, p402_) <= p400_
					else
						v404_ = false
					end
					return v404_
				end
			end
			if v390_ == 0 and v405_(ax1, az1, bx1, bz1, ax2, az2) then
				return true, true
			elseif v392_ == 0 and v405_(ax1, az1, bx2, bz2, ax2, az2) then
				return true, true
			elseif v394_ == 0 and v405_(bx1, bz1, ax1, az1, bx2, bz2) then
				return true, true
			elseif v396_ == 0 and v405_(bx1, bz1, ax2, az2, bx2, bz2) then
				return true, true
			else
				return false
			end
		elseif allowEndStartSamePos and (ax1 == bx1 and az1 == bz1 or (ax1 == bx2 and az1 == bz2 or (ax2 == bx1 and az2 == bz1 or ax2 == bx2 and az2 == bz2))) then
			return false
		else
			return true, false
		end
	end
end

function MathUtil.getLineBoundingVolumeIntersect(ax1, ay1, ax2, ay2, bx1, by1, bx2, by2)
	local v414_
	if math.min(ax1, ax2) <= math.max(bx1, bx2) and (math.max(ax1, ax2) >= math.min(bx1, bx2) and math.min(ay1, ay2) <= math.max(by1, by2)) then
		v414_ = math.max(ay1, ay2) >= math.min(by1, by2)
	else
		v414_ = false
	end
	return v414_
end

-- Local values: dir1Length, dir2Length, dir3Length, dirX1_norm, dirZ1_norm, dirX2_norm, dirZ2_norm, dirX3_norm, dirZ3_norm, intersects, t1, t2, p1, p2
function MathUtil.hasRectangleLineIntersection2D(x1, z1, dirX1, dirZ1, dirX2, dirZ2, x3, z3, dirX3, dirZ3)
	local v425_ = MathUtil.vector2Length(dirX1, dirZ1)
	local v426_ = MathUtil.vector2Length(dirX2, dirZ2)
	local v427_ = MathUtil.vector2Length(dirX3, dirZ3)
	local v428_ = v425_ == 0 and 1 or v425_
	local v429_ = v426_ == 0 and 1 or v426_
	local v430_ = v427_ == 0 and 1 or v427_
	local v431_ = dirX1 / v428_
	local v432_ = dirZ1 / v428_
	local v433_ = dirX2 / v429_
	local v434_ = dirZ2 / v429_
	local v435_ = dirX3 / v430_
	local v436_ = dirZ3 / v430_
	local v437_, v438_, v439_ = MathUtil.getLineLineIntersection2D(x3, z3, v435_, v436_, x1, z1, v431_, v432_)
	if v437_ and (v438_ > 0 and (v438_ < v430_ and (v439_ > 0 and v439_ < v428_))) then
		return true
	end
	local v440_, v441_, v442_ = MathUtil.getLineLineIntersection2D(x3, z3, v435_, v436_, x1, z1, v433_, v434_)
	if v440_ and (v441_ > 0 and (v441_ < v430_ and (v442_ > 0 and v442_ < v429_))) then
		return true
	end
	local v443_, v444_, v445_ = MathUtil.getLineLineIntersection2D(x3, z3, v435_, v436_, x1 + dirX1, z1 + dirZ1, v433_, v434_)
	if v443_ and (v444_ > 0 and (v444_ < v430_ and (v445_ > 0 and v445_ < v429_))) then
		return true
	end
	local v446_, v447_, v448_ = MathUtil.getLineLineIntersection2D(x3, z3, v435_, v436_, x1 + dirX2, z1 + dirZ2, v431_, v432_)
	if v446_ and (v447_ > 0 and (v447_ < v430_ and (v448_ > 0 and v448_ < v428_))) then
		return true
	end
	local v449_ = MathUtil.getProjectOnLineParameter(x3, z3, x1, z1, v431_, v432_)
	local v450_ = MathUtil.getProjectOnLineParameter(x3, z3, x1, z1, v433_, v434_)
	if v449_ > 0 and (v449_ < v428_ and (v450_ > 0 and v450_ < v429_)) then
		local v451_ = MathUtil.getProjectOnLineParameter(x3 + dirX3, z3 + dirZ3, x1, z1, v431_, v432_)
		local v452_ = MathUtil.getProjectOnLineParameter(x3 + dirX3, z3 + dirZ3, x1, z1, v433_, v434_)
		if v451_ > 0 and (v451_ < v428_ and (v452_ > 0 and v452_ < v429_)) then
			return true
		end
	end
	return false
end

-- Local values: dx, dy, dist, x, y, a, v2x, v2y, h, rx, ry
function MathUtil.getCircleCircleIntersection(x1, y1, r1, x2, y2, r2)
	local v459_ = x2 - x1
	local v460_ = y2 - y1
	local v461_ = MathUtil.vector2Length(v459_, v460_)
	if v461_ == 0 and (x1 == x2 and y1 == y2) then
		return nil
	end
	if r1 + r2 < v461_ then
		return nil
	end
	local v462_ = r1 - r2
	if v461_ < math.abs(v462_) then
		return nil
	end
	if v461_ == r1 + r2 then
		return (x1 - x2) / (r1 + r2) * r1 + x2, (y1 - y2) / (r1 + r2) * r1 + y2
	end
	local v463_ = (r1 * r1 - r2 * r2 + v461_ * v461_) / (2 * v461_)
	local v464_ = x1 + v459_ * v463_ / v461_
	local v465_ = y1 + v460_ * v463_ / v461_
	local v466_ = r1 * r1 - v463_ * v463_
	local v467_ = math.sqrt(v466_)
	local v468_ = -v460_ * (v467_ / v461_)
	local v469_ = v459_ * (v467_ / v461_)
	return v464_ + v468_, v465_ + v469_, v464_ - v468_, v465_ - v469_
end

-- Local values: dx, dy, dz, rsum
function MathUtil.hasSphereSphereIntersection(x1, y1, z1, r1, x2, y2, z2, r2)
	local v478_ = x2 - x1
	local v479_ = y2 - y1
	local v480_ = z2 - z1
	local v481_ = r1 + r2
	return v478_ * v478_ + v479_ * v479_ + v480_ * v480_ <= v481_ * v481_
end

-- Local values: n, d, dist, d1, d2
function MathUtil.getHasCircleLineIntersection(circleX, circleZ, radius, lineStartX, lineStartZ, lineEndX, lineEndZ)
	local v489_ = (lineEndX - lineStartX) * (lineStartZ - circleZ) - (lineStartX - circleX) * (lineEndZ - lineStartZ)
	local v490_ = math.abs(v489_)
	local v491_ = (lineEndX - lineStartX) * (lineEndX - lineStartX) + (lineEndZ - lineStartZ) * (lineEndZ - lineStartZ)
	local v492_ = math.sqrt(v491_)
	if radius < v490_ / v492_ then
		return false
	end
	local v493_ = (circleX - lineStartX) * (circleX - lineStartX) + (circleZ - lineStartZ) * (circleZ - lineStartZ)
	if v492_ < math.sqrt(v493_) - radius then
		return false
	end
	local v494_ = (circleX - lineEndX) * (circleX - lineEndX) + (circleZ - lineEndZ) * (circleZ - lineEndZ)
	return v492_ >= math.sqrt(v494_) - radius
end

-- Local values: x1, z1, x2, z2, dx, dz, dr, d, dis, sign, ix1, iz1, ix2, iz2, fraction1, fraction2
function MathUtil.getCircleLineIntersection(circleX, circleZ, radius, lineStartX, lineStartZ, lineEndX, lineEndZ, limitToLineSegment)
	local v503_ = lineStartX - circleX
	local v504_ = lineStartZ - circleZ
	local v505_ = lineEndX - circleX
	local v506_ = lineEndZ - circleZ
	local v507_ = v505_ - v503_
	local v508_ = v506_ - v504_
	local v509_ = (v507_ ^ 2 + v508_ ^ 2) ^ 0.5
	local v510_ = v503_ * v506_ - v505_ * v504_
	local v511_ = radius ^ 2 * v509_ ^ 2 - v510_ ^ 2
	if v511_ < 0 then
		return false
	end
	local v512_ = v508_ < 0 and 1 or -1
	local v513_ = circleX + (v510_ * v508_ + v512_ * (v508_ < 0 and -1 or 1) * v507_ * v511_ ^ 0.5) / v509_ ^ 2
	local v514_ = circleZ + (-v510_ * v507_ + v512_ * math.abs(v508_) * v511_ ^ 0.5) / v509_ ^ 2
	local v515_ = circleX + (v510_ * v508_ - v512_ * (v508_ < 0 and -1 or 1) * v507_ * v511_ ^ 0.5) / v509_ ^ 2
	local v516_ = circleZ + (-v510_ * v507_ - v512_ * math.abs(v508_) * v511_ ^ 0.5) / v509_ ^ 2
	if limitToLineSegment ~= false then
		local v517_, v518_
		if math.abs(v507_) > math.abs(v508_) then
			v517_ = (v513_ - lineStartX) / v507_
			v518_ = (v515_ - lineStartX) / v507_
		else
			v517_ = (v514_ - lineStartZ) / v508_
			v518_ = (v516_ - lineStartZ) / v508_
		end
		if v517_ < 0 or v517_ > 1 then
			v513_ = nil
			v514_ = nil
		end
		if v518_ < 0 or v518_ > 1 then
			v515_ = nil
			v516_ = nil
		end
	end
	return v513_ ~= nil and true or v515_ ~= nil, v513_, v514_, v515_, v516_
end

-- Local values: dirTargetX, dirTargetY, dirTargetZ, dirLineX, dirLineY, dirLineZ, lengthSq, dot, distance
function MathUtil.getClosestPointOnLineSegment(startX, startY, startZ, endX, endY, endZ, targetX, targetY, targetZ)
	local v528_ = targetX - startX
	local v529_ = targetY - startY
	local v530_ = targetZ - startZ
	local v531_ = endX - startX
	local v532_ = endY - startY
	local v533_ = endZ - startZ
	local v534_ = MathUtil.vector3LengthSq(v531_, v532_, v533_)
	local v535_ = MathUtil.dotProduct(v528_, v529_, v530_, v531_, v532_, v533_) / v534_
	if v535_ < 0 then
		return startX, startY, startZ, 0
	elseif v535_ > 1 then
		return endX, endY, endZ, 1
	else
		return startX + v531_ * v535_, startY + v532_ * v535_, startZ + v533_ * v535_, v535_
	end
end

-- Local values: px, py, norm, u, x, y, dx, dy, dist
function MathUtil.getDistanceToLineSegment2D(startX, startZ, endX, endZ, pointX, pointZ)
	local v542_ = endX - startX
	local v543_ = endZ - startZ
	local v544_ = v542_ * v542_ + v543_ * v543_
	local v545_ = ((pointX - startX) * v542_ + (pointZ - startZ) * v543_) / v544_
	local v546_ = v545_ > 1 and 1 or (v545_ < 0 and 0 or v545_)
	local v547_ = startX + v546_ * v542_
	local v548_ = startZ + v546_ * v543_
	local v549_ = v547_ - pointX
	local v550_ = v548_ - pointZ
	local v551_ = v549_ * v549_ + v550_ * v550_
	return math.sqrt(v551_)
end

-- Local values: dirX, dirZ, detA, detB, detC, n, m
function MathUtil.isPointInParallelogram(x, z, startX, startZ, widthX, widthZ, heightX, heightZ)
	local v560_ = x - startX
	local v561_ = z - startZ
	local v562_ = widthX * heightZ - heightX * widthZ
	local v563_ = v560_ * widthZ - widthX * v561_
	local v564_ = v560_ * heightZ - heightX * v561_
	local v565_ = -v563_ / v562_
	if v565_ >= 0 and v565_ <= 1 then
		local v566_ = v564_ / v562_
		if v566_ >= 0 and v566_ <= 1 then
			return true
		end
	end
	return false
end

-- Local values: dx, dy
function MathUtil.getPointPointDistance(x1, y1, x2, y2)
	local v571_ = x1 - x2
	local v572_ = y1 - y2
	local v573_ = v571_ * v571_ + v572_ * v572_
	return math.sqrt(v573_)
end

-- Local values: dx, dy
function MathUtil.getPointPointDistanceSquared(x1, y1, x2, y2)
	local v578_ = x1 - x2
	local v579_ = y1 - y2
	return v578_ * v578_ + v579_ * v579_
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

-- Local values: widthDirX, widthDirZ, heightDirX, heightDirZ, offsetStartDirX, offsetStartDirZ, alphaStart, moveStartLength, newStartWorldX, newStartWorldZ, offsetWidthDirX, offsetWidthDirZ, alphaWidth, moveWidthLength, newWidthWorldX, newWidthWorldZ, newHeightWorldX, newHeightWorldZ
function MathUtil.getWorldParallelogramOffset(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, offset)
	local v608_ = widthWorldX - startWorldX
	local v609_ = widthWorldZ - startWorldZ
	local v610_, v611_ = MathUtil.vector2Normalize(v608_, v609_)
	local v612_ = heightWorldX - startWorldX
	local v613_ = heightWorldZ - startWorldZ
	local v614_, v615_ = MathUtil.vector2Normalize(v612_, v613_)
	local v616_, v617_ = MathUtil.vector2Normalize(v610_ + v614_, v611_ + v615_)
	local v618_ = MathUtil.dotProduct(v610_, 0, v611_, v614_, 0, v615_)
	local v619_ = math.acos(v618_) * 0.5
	local v620_ = offset / math.sin(v619_)
	local v621_ = startWorldX - v620_ * v616_
	local v622_ = startWorldZ - v620_ * v617_
	local v623_, v624_ = MathUtil.vector2Normalize(v614_ - v610_, v615_ - v611_)
	local v625_ = MathUtil.dotProduct(v614_, 0, v615_, -v610_, 0, -v611_)
	local v626_ = math.acos(v625_) * 0.5
	local v627_ = offset / math.sin(v626_)
	return v621_, v622_, widthWorldX - v627_ * v623_, widthWorldZ - v627_ * v624_, heightWorldX + v627_ * v623_, heightWorldZ + v627_ * v624_
end

-- Local values: dirX, dirZ, normalX, normalZ, widthHalf, startX, startZ, widthX, widthZ, heightX, heightZ
function MathUtil.getWorldParallelogramFromLine(x, z, endX, endZ, width)
	local v633_, v634_ = MathUtil.vector2Normalize(endX - x, endZ - z)
	local v635_ = -v634_
	local v636_ = width * 0.5
	return x - v635_ * v636_, z - v633_ * v636_, x + v635_ * v636_, z + v633_ * v636_, endX - v635_ * v636_, endZ - v633_ * v636_
end

function MathUtil.getNumOfSetBits(bitmask)
	local v638_ = bit32.rshift(bitmask, 1)
	local v639_ = bitmask - bit32.band(v638_, 1431655765)
	local v640_ = bit32.band(v639_, 858993459)
	local v641_ = bit32.rshift(v639_, 2)
	local v642_ = v640_ + bit32.band(v641_, 858993459)
	local v643_ = v642_ + bit32.rshift(v642_, 4)
	local v644_ = bit32.band(v643_, 252645135) * 16843009
	return bit32.rshift(v644_, 24)
end
function MathUtil.bitsToMask(...)
	local v645_ = 0
	for v646_ = 1, select("#", ...) do
		local v647_ = select(v646_, ...)
		local v648_ = math.pow(2, v647_)
		v645_ = bit32.bor(v645_, v648_)
	end
	return v645_
end

-- Local values: bits, rest
function MathUtil.getBinary(number)
	local v650_ = {}
	while number > 0 do
		local v651_ = number % 2
		table.insert(v650_, v651_)
		number = (number - v651_) / 2
	end
	return v650_
end

-- Local values: bits, setBits, i, bit
function MathUtil.numberToSetBits(number)
	local v653_ = MathUtil.getBinary(number)
	local v654_ = {}
	for v655_, v656_ in ipairs(v653_) do
		if v656_ == 1 then
			local v657_ = v655_ - 1
			table.insert(v654_, v657_)
		end
	end
	return v654_
end

-- Local values: setBits, returnStr, i, bit
function MathUtil.numberToSetBitsStr(number, separator)
	local v660_ = MathUtil.numberToSetBits(number)
	local v661_ = ""
	local v662_ = separator or ", "
	for v663_, v664_ in ipairs(v660_) do
		if v663_ > 1 then
			v661_ = v661_ .. v662_
		end
		v661_ = v661_ .. v664_
	end
	return v661_
end

function MathUtil.getNumRequiredBits(integer)
	local v666_ = integer >= 0
	assert(v666_)
	if integer == 0 then
		return 1
	end
	local v667_ = math.log(integer, 2) + 1
	return math.floor(v667_)
end

function MathUtil.getBrightnessFromColor(r, g, b)
	return r * 0.2125 + g * 0.7154 + b * 0.0721
end

-- Local values: angle, maxAngle, zScale0, zScale1
function MathUtil.getHorizontalRotationFromDeviceGravity(x, y, z)
	if x == 0 and (y == 0 and z == 0) then
		return 0
	end
	local v674_
	if x <= 0 then
		local v675_ = 0.43633222222222223
		local v676_ = math.atan2(y, x)
		local v677_
		if v676_ < 0 then
			v677_ = v676_ + 3.141592653589793
		else
			v677_ = v676_ - 3.141592653589793
		end
		local v678_ = math.clamp(v677_, -0.43633222222222223, v675_)
		local v679_ = (0.9 - math.abs(z)) / 0.25
		v674_ = v678_ * math.clamp(v679_, 0, 1)
	else
		v674_ = 0
	end
	return v674_
end

-- Local values: STEER_DEADZONE, MAX_STEER_ANGLE, angle
function MathUtil.getSteeringAngleFromDeviceGravity(x, y, z)
	if x == 0 and (y == 0 and z == 0) then
		return 0
	end
	local v683_ = math.clamp(y, -1, 1)
	local v684_ = -math.asin(v683_)
	local v685_
	if v684_ > 0.06981315555555556 then
		v685_ = math.min(v684_, 0.43633222222222223) - 0.06981315555555556
	else
		v685_ = v684_ >= -0.06981315555555556 and 0 or math.max(v684_, -0.43633222222222223) + 0.06981315555555556
	end
	return v685_ / 0.36651906666666667
end

function MathUtil.catmullRom(p0, p1, p2, p3, t)
	return 0.5 * (2 * p1 + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t + (-p0 + 3 * p1 - 3 * p2 + p3) * t * t * t)
end

function MathUtil.equalEpsilon(a, b, epsilon)
	if a == nil or b == nil then
		return false
	end
	local v694_ = a - b
	return (epsilon or 0.0001) > math.abs(v694_)
end

-- Local values: currentIndex, floatIterator, floatIterator
function MathUtil.floatRange(startVal, endVal, step)
	if step ~= 0 and (step <= 0 or endVal >= startVal) and (step >= 0 or startVal >= endVal) then
		local v_u_698_ = 0
		return step > 0 and function()
			-- upvalues: (copy) startVal, (ref) v_u_698_, (copy) step, (copy) endVal
			local v699_ = startVal + v_u_698_ * step
			if endVal < v699_ then
				return nil
			end
			v_u_698_ = v_u_698_ + 1
			return v699_
		end or function()
			-- upvalues: (copy) startVal, (ref) v_u_698_, (copy) step, (copy) endVal
			local v700_ = startVal + v_u_698_ * step
			if v700_ < endVal then
				return nil
			end
			v_u_698_ = v_u_698_ + 1
			return v700_
		end
	end
	printError(string.format("Error: (%f, %f, %f) invalid arguments, range is endless", startVal, endVal, step))
	printCallstack()
	return function()
		return nil
	end
end

-- Local values: t
function MathUtil.smoothstep(min, max, x)
	local v704_ = (x - min) / (max - min)
	local v705_ = math.clamp(v704_, 0, 1)
	return v705_ * v705_ * (3 - 2 * v705_)
end

-- Local values: snappedValue
function MathUtil.snapValue(value, step)
	if step == 0 then
		return value
	end
	local v708_ = value / step
	return math.round(v708_) * step
end

-- Local values: fractionDigitIndex
function MathUtil.getIndexOfFirstNonZeroFractionDigit(number)
	local v710_ = math.abs(number)
	if v710_ == 0 then
		return 0
	end
	local v711_ = 0
	while v710_ < 1 do
		v710_ = v710_ * 10
		v711_ = v711_ + 1
	end
	return v711_
end

-- Local values: cosValue, sinValue, rotatedX, rotatedY
function MathUtil.vector2Rotate(x, y, angle)
	local v715_ = math.cos(angle)
	local v716_ = math.sin(angle)
	return x * v715_ - y * v716_, x * v716_ + y * v715_
end

-- Local values: size, node2Index, node1Index, node1, node2, x1, _, z1, x2, _, z2, averageHeight, width, edgeSize
function MathUtil.getPolygon2DSize(vertices)
	if vertices == nil or #vertices < 3 then
		return nil
	end
	local v718_ = #vertices
	local v719_ = 0
	for v720_ = 1, #vertices do
		local v721_ = vertices[v720_]
		local v722_ = vertices[v718_]
		local v723_, _, v724_ = getWorldTranslation(v721_)
		local v725_, _, v726_ = getWorldTranslation(v722_)
		local v727_ = (v724_ + v726_) * 0.5
		v719_ = v719_ + (v725_ - v723_) * v727_
		v718_ = v720_
	end
	return math.abs(v719_)
end

-- Local values: polygonPoints, _, vertex, x, _, z, sortQueue, getSegDistSq, pointToPolygonDist, createCell, getCentroidCell, minX, minY, maxX, maxY, k, p, width, height, cellSize, h, queue, push, pop, x, y, x, y, h, d, cell, element, bestCell, x, y, d, cell, bboxCell, cell, x, y, h, d, cell, element, x, y, h, d, cell, element, x, y, h, d, cell, element, x, y, h, d, cell, element
function MathUtil.getPolygonLabel(vertices, precision)
	local v_u_730_ = {}
	local v731_ = precision or 1
	for _, v732_ in ipairs(vertices) do
		local v733_, _, v734_ = getWorldTranslation(v732_)
		table.insert(v_u_730_, { v733_, v734_ })
	end
	local function v_u_746_(p735_, p736_, p737_, p738_)
		local v739_ = p737_[1]
		local v740_ = p737_[2]
		local v741_ = p738_[1] - v739_
		local v742_ = p738_[2] - v740_
		if v741_ ~= 0 or v742_ ~= 0 then
			local v743_ = ((p735_ - v739_) * v741_ + (p736_ - v740_) * v742_) / (v741_ * v741_ + v742_ * v742_)
			if v743_ > 1 then
				v739_ = p738_[1]
				v740_ = p738_[2]
			elseif v743_ > 0 then
				v739_ = v739_ + v741_ * v743_
				v740_ = v740_ + v742_ * v743_
			end
		end
		local v744_ = p735_ - v739_
		local v745_ = p736_ - v740_
		return v744_ * v744_ + v745_ * v745_
	end
	local function v_u_756_(p747_, p748_)
		-- upvalues: (copy) v_u_730_, (copy) v_u_746_
		local v749_ = #v_u_730_
		local v750_ = math.huge
		local v751_ = false
		for v752_ = 1, #v_u_730_ do
			local v753_ = v_u_730_[v752_]
			local v754_ = v_u_730_[v749_]
			if p748_ < v753_[2] ~= (p748_ < v754_[2]) and p747_ < (v754_[1] - v753_[1]) * (p748_ - v753_[2]) / (v754_[2] - v753_[2]) + v753_[1] then
				v751_ = not v751_
			end
			local v755_ = v_u_746_(p747_, p748_, v753_, v754_)
			v750_ = math.min(v750_, v755_)
			v749_ = v752_
		end
		return v750_ == 0 and 0 or (v751_ and 1 or -1) * math.sqrt(v750_)
	end
	local v757_ = nil
	local v758_ = nil
	local v759_ = nil
	local v760_ = nil
	local function v763_(p761_, p762_)
		return p761_.max < p762_.max
	end
	local function v778_()
		-- upvalues: (copy) v_u_730_, (copy) v_u_756_
		local v764_ = #v_u_730_
		local v765_ = 0
		local v766_ = 0
		local v767_ = 0
		for v768_ = 1, #v_u_730_ do
			local v769_ = v_u_730_[v768_]
			local v770_ = v_u_730_[v764_]
			local v771_ = v769_[1] * v770_[2] - v770_[1] * v769_[2]
			v765_ = v765_ + (v769_[1] + v770_[1]) * v771_
			v766_ = v766_ + (v769_[2] + v770_[2]) * v771_
			v767_ = v767_ + v771_ * 3
			v764_ = v768_
		end
		if v767_ == 0 then
			local v772_ = v_u_730_[1][0]
			local v773_ = v_u_730_[1][1]
			local v774_ = v_u_756_(v772_, v773_)
			return {
				["x"] = v772_,
				["y"] = v773_,
				["h"] = 0,
				["d"] = v774_,
				["max"] = v774_ + 0
			}
		else
			local v775_ = v765_ / v767_
			local v776_ = v766_ / v767_
			local v777_ = v_u_756_(v775_, v776_)
			return {
				["x"] = v775_,
				["y"] = v776_,
				["h"] = 0,
				["d"] = v777_,
				["max"] = v777_ + 0
			}
		end
	end
	for v779_, v780_ in ipairs(v_u_730_) do
		if v779_ == 1 or v780_[1] < v760_ then
			v760_ = v780_[1]
		end
		if v779_ == 1 or v780_[2] < v759_ then
			v759_ = v780_[2]
		end
		if v779_ == 1 or v758_ < v780_[1] then
			v758_ = v780_[1]
		end
		if v779_ == 1 or v757_ < v780_[2] then
			v757_ = v780_[2]
		end
	end
	local v781_ = v758_ - v760_
	local v782_ = v757_ - v759_
	local v783_ = math.min(v781_, v782_)
	local v784_ = v783_ / 2
	if v783_ == 0 then
		return v760_, v759_
	end
	local v785_ = {}
	for v786_ = v760_, v758_, v783_ do
		for v787_ = v759_, v757_, v783_ do
			local v788_ = v786_ + v784_
			local v789_ = v787_ + v784_
			local v790_ = v_u_756_(v788_, v789_)
			local v791_ = {
				["x"] = v788_,
				["y"] = v789_,
				["h"] = v784_,
				["d"] = v790_,
				["max"] = v790_ + v784_ * 1.4142135623730951
			}
			table.insert(v785_, v791_)
		end
	end
	local v792_ = v778_()
	local v793_ = v760_ + v781_ / 2
	local v794_ = v759_ + v782_ / 2
	local v795_ = v_u_756_(v793_, v794_)
	local v796_ = {
		["x"] = v793_,
		["y"] = v794_,
		["h"] = 0,
		["d"] = v795_,
		["max"] = v795_ + 0
	}
	if v796_.d <= v792_.d then
		v796_ = v792_
	end
	while #v785_ > 0 do
		table.sort(v785_, v763_)
		local v797_ = table.remove(v785_, 1)
		if v797_.d > v796_.d then
			v796_ = v797_
		end
		if v797_.max - v796_.d > v731_ then
			local v798_ = v797_.h / 2
			local v799_ = v797_.x - v798_
			local v800_ = v797_.y - v798_
			local v801_ = v_u_756_(v799_, v800_)
			local v802_ = {
				["x"] = v799_,
				["y"] = v800_,
				["h"] = v798_,
				["d"] = v801_,
				["max"] = v801_ + v798_ * 1.4142135623730951
			}
			table.insert(v785_, v802_)
			local v803_ = v797_.x + v798_
			local v804_ = v797_.y - v798_
			local v805_ = v_u_756_(v803_, v804_)
			local v806_ = {
				["x"] = v803_,
				["y"] = v804_,
				["h"] = v798_,
				["d"] = v805_,
				["max"] = v805_ + v798_ * 1.4142135623730951
			}
			table.insert(v785_, v806_)
			local v807_ = v797_.x - v798_
			local v808_ = v797_.y + v798_
			local v809_ = v_u_756_(v807_, v808_)
			local v810_ = {
				["x"] = v807_,
				["y"] = v808_,
				["h"] = v798_,
				["d"] = v809_,
				["max"] = v809_ + v798_ * 1.4142135623730951
			}
			table.insert(v785_, v810_)
			local v811_ = v797_.x + v798_
			local v812_ = v797_.y + v798_
			local v813_ = v_u_756_(v811_, v812_)
			local v814_ = {
				["x"] = v811_,
				["y"] = v812_,
				["h"] = v798_,
				["d"] = v813_,
				["max"] = v813_ + v798_ * 1.4142135623730951
			}
			table.insert(v785_, v814_)
		end
	end
	return v796_.x, v796_.y
end

-- Local values: curveStrength, linearAdjust, baseValue
function MathUtil.symmetricDipCurve(value, alpha, maxValue)
	local v818_ = 4 * alpha * maxValue
	local v819_ = -4 * alpha * maxValue
	return v818_ * value ^ 2 + v819_ * value + maxValue
end

-- Local values: valueString, number
function MathUtil.convertStringToNumber(value)
	local v821_ = string.trim(value)
	if v821_ == "" then
		return 0
	end
	local v822_ = string.gsub(v821_, "%s+", "")
	local v823_ = string.gsub(v822_, "_", "")
	local v824_ = string.gsub(v823_, ",", ".")
	return tonumber(v824_) or 0
end
