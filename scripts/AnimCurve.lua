-- Local values: AnimCurve_mt
AnimCurve = {}

function linearInterpolator1(first, second, alpha)
	return second[1] + alpha * (first[1] - second[1])
end

-- Local values: oneMinusAlpha
function linearInterpolator2(first, second, alpha)
	local v7_ = 1 - alpha
	return first[1] * alpha + second[1] * v7_, first[2] * alpha + second[2] * v7_
end

-- Local values: oneMinusAlpha
function linearInterpolator3(first, second, alpha)
	local v11_ = 1 - alpha
	return first[1] * alpha + second[1] * v11_, first[2] * alpha + second[2] * v11_, first[3] * alpha + second[3] * v11_
end

-- Local values: oneMinusAlpha
function linearInterpolator4(first, second, alpha)
	local v15_ = 1 - alpha
	return first[1] * alpha + second[1] * v15_, first[2] * alpha + second[2] * v15_, first[3] * alpha + second[3] * v15_, first[4] * alpha + second[4] * v15_
end

-- Local values: i
function linearInterpolatorN(first, second, alpha, curValues)
	for v20_ = 1, #first do
		if first[v20_] ~= nil and second[v20_] ~= nil then
			curValues[v20_] = first[v20_] * alpha + second[v20_] * (1 - alpha)
		end
	end
	return unpack(curValues)
end

-- Local values: oneMinusAlpha
function linearInterpolatorTransRot(first, second, alpha)
	local v24_ = 1 - alpha
	return first.x * alpha + second.x * v24_, first.y * alpha + second.y * v24_, first.z * alpha + second.z * v24_, first.rx * alpha + second.rx * v24_, first.ry * alpha + second.ry * v24_, first.rz * alpha + second.rz * v24_
end

-- Local values: oneMinusAlpha
function linearInterpolatorTransRotScale(first, second, alpha)
	local v28_ = 1 - alpha
	return first.x * alpha + second.x * v28_, first.y * alpha + second.y * v28_, first.z * alpha + second.z * v28_, first.rx * alpha + second.rx * v28_, first.ry * alpha + second.ry * v28_, first.rz * alpha + second.rz * v28_, first.sx * alpha + second.sx * v28_, first.sy * alpha + second.sy * v28_, first.sz * alpha + second.sz * v28_
end

-- Local values: t2, t3, p0v, p3v, v
function catmullRomInterpolator1(p1, p2, p0, p3, t)
	local v34_ = 1 - t
	local v35_ = v34_ * v34_
	local v36_ = v35_ * v34_
	local v37_
	if p0 == nil then
		v37_ = 2 * p1.v - p2.v
	else
		v37_ = p0.v
	end
	local v38_
	if p3 == nil then
		v38_ = 2 * p2.v - p1.v
	else
		v38_ = p3.v
	end
	return 0.5 * (2 * p1.v + (-v37_ + p2.v) * v34_ + (2 * v37_ - 5 * p1.v + 4 * p2.v - v38_) * v35_ + (-v37_ + 3 * p1.v - 3 * p2.v + v38_) * v36_)
end

-- Local values: t2, t3, p0x, p0y, p0z, p3x, p3y, p3z, x, y, z
function catmullRomInterpolator3(p1, p2, p0, p3, t)
	local v44_ = 1 - t
	local v45_ = v44_ * v44_
	local v46_ = v45_ * v44_
	local v47_, v48_, v49_
	if p0 == nil then
		v47_ = 2 * p1.x - p2.x
		v48_ = 2 * p1.y - p2.y
		v49_ = 2 * p1.z - p2.z
	else
		v47_ = p0.x
		v48_ = p0.y
		v49_ = p0.z
	end
	local v50_, v51_, v52_
	if p3 == nil then
		v50_ = 2 * p2.x - p1.x
		v51_ = 2 * p2.y - p1.y
		v52_ = 2 * p2.z - p1.z
	else
		v50_ = p3.x
		v51_ = p3.y
		v52_ = p3.z
	end
	return 0.5 * (2 * p1.x + (-v47_ + p2.x) * v44_ + (2 * v47_ - 5 * p1.x + 4 * p2.x - v50_) * v45_ + (-v47_ + 3 * p1.x - 3 * p2.x + v50_) * v46_), 0.5 * (2 * p1.y + (-v48_ + p2.y) * v44_ + (2 * v48_ - 5 * p1.y + 4 * p2.y - v51_) * v45_ + (-v48_ + 3 * p1.y - 3 * p2.y + v51_) * v46_), 0.5 * (2 * p1.z + (-v49_ + p2.z) * v44_ + (2 * v49_ - 5 * p1.z + 4 * p2.z - v52_) * v45_ + (-v49_ + 3 * p1.z - 3 * p2.z + v52_) * v46_)
end

function quaternionInterpolator(p1, p2, t)
	return MathUtil.nlerpQuaternionShortestPath(p2.x, p2.y, p2.z, p2.w, p1.x, p1.y, p1.z, p1.w, t)
end

-- Local values: w0, w3, w1, w2, x, y, z, w
function quaternionInterpolator2(p1, p2, p0, p3, t)
	local v61_ = 1 - t
	local v62_ = (1 - v61_) * 0.6
	local v63_ = v61_ * 0.6
	if p0 == nil then
		p0 = p1
		v62_ = 0
	end
	if p3 == nil then
		p3 = p2
		v63_ = 0
	end
	local v64_ = 1 - v61_ + v63_
	local v65_ = v61_ + v62_
	local v66_ = p0.x * v62_
	local v67_ = p0.y * v62_
	local v68_ = p0.z * v62_
	local v69_ = p0.w * v62_
	local v70_, v71_, v72_, v73_ = MathUtil.quaternionMadShortestPath(v66_, v67_, v68_, v69_, p1.x, p1.y, p1.z, p1.w, v64_)
	local v74_, v75_, v76_, v77_ = MathUtil.quaternionMadShortestPath(v70_, v71_, v72_, v73_, p2.x, p2.y, p2.z, p2.w, v65_)
	local v78_, v79_, v80_, v81_ = MathUtil.quaternionMadShortestPath(v74_, v75_, v76_, v77_, p3.x, p3.y, p3.z, p3.w, v63_)
	return MathUtil.quaternionNormalized(v78_, v79_, v80_, v81_)
end
local v_u_82_ = Class(AnimCurve)

-- Upvalues: AnimCurve_mt
-- Local values: self
function AnimCurve.new(interpolator, interpolatorDegree)
	-- upvalues: (copy) v_u_82_
	local v85_ = v_u_82_
	local v86_ = setmetatable({}, v85_)
	v86_.keyframes = {}
	v86_.interpolator = interpolator
	v86_.interpolatorDegree = interpolatorDegree or 2
	v86_.currentTime = 0
	v86_.maxTime = 0
	v86_.numKeyframes = 0
	return v86_
end

function AnimCurve:delete() end

function AnimCurve:reset()
	table.clear(self.keyframes)
	self.numKeyframes = 0
	self.currentTime = 0
	self.maxTime = 0
end

-- Local values: numKeys
function AnimCurve:addKeyframe(keyframe, xmlFile, key)
	local v92_ = self.numKeyframes
	if v92_ > 0 and keyframe.time < self.keyframes[v92_].time then
		if xmlFile == nil then
			printError("Error: keyframes not strictly monotonic increasing")
		else
			if type(xmlFile) == "number" then
				xmlFile = g_xmlManager:getFileByHandle(xmlFile)
			end
			if xmlFile == nil then
				Logging.error("keyframes not strictly monotonic increasing at %s (%.3f)", key, keyframe.time)
			else
				Logging.xmlError(xmlFile, "keyframes not strictly monotonic increasing at %s (%.3f)", key, keyframe.time)
			end
		end
	end
	if self.interpolator == linearInterpolatorN and v92_ == 0 then
		self.curValues = table.create(#keyframe)
	end
	local v93_ = self.keyframes
	table.insert(v93_, keyframe)
	self.maxTime = keyframe.time
	self.numKeyframes = v92_ + 1
end

-- Local values: i
function AnimCurve:removeKeyframe(index)
	if index == nil or index >= 1 and #self.keyframes >= index then
		for v96_ = #self.keyframes - 1, index, -1 do
			self.keyframes[v96_ + 1].time = self.keyframes[v96_].time
		end
		table.remove(self.keyframes, index)
		self.maxTime = self.keyframes[#self.keyframes] and (self.keyframes[#self.keyframes].time or 0) or 0
		self.numKeyframes = self.numKeyframes - 1
	end
end

-- Local values: numKeys, maxValue, maxTime, i, value
function AnimCurve:getMaximum()
	local v98_ = #self.keyframes
	if v98_ == 0 then
		return 0, 0
	end
	if v98_ == 1 then
		return self:getFromKeyframes(self.keyframes[1], self.keyframes[1], 1, 1, 0), self.keyframes[1].time
	end
	local v99_ = self:getFromKeyframes(self.keyframes[1], self.keyframes[2], 1, 2, 0)
	local v100_ = self.keyframes[1].time
	for v101_ = 1, v98_ - 1 do
		local v102_ = self:getFromKeyframes(self.keyframes[v101_], self.keyframes[v101_ + 1], v101_, v101_ + 1, 1)
		if v99_ < v102_ then
			v100_ = self.keyframes[v101_ + 1].time
			v99_ = v102_
		end
	end
	return v99_, v100_
end

-- Local values: numKeys, first, second, firstI, secondI, i, time0, time1, alpha, timesOffset, segmentT, segmentLow, segmentHi, l, p
function AnimCurve:get(time)
	local v105_ = self.numKeyframes
	if v105_ == 0 then
		return
	end
	local v106_ = nil
	local v107_ = nil
	local v108_ = nil
	local v109_ = nil
	if v105_ >= 2 and self.keyframes[1].time <= time then
		if time < self.maxTime then
			for v110_ = 2, v105_ do
				v107_ = self.keyframes[v110_]
				if time <= v107_.time then
					v106_ = self.keyframes[v110_ - 1]
					v108_ = v110_ - 1
					v109_ = v110_
					break
				end
				v109_ = v110_
			end
		else
			v106_ = self.keyframes[v105_]
			v109_ = v105_
			v108_ = v109_
			v107_ = v106_
			local v111_ = v109_
			v109_ = v108_
			v111_ = v108_
			v108_ = v109_
		end
	else
		v106_ = self.keyframes[1]
		v107_ = v106_
	end
	local v112_ = v106_.time
	local v113_ = v107_.time
	local v114_ = v112_ >= v113_ and 0 or (v113_ - time) / (v113_ - v112_)
	if self.segmentTimes ~= nil and v108_ < v105_ then
		local v115_ = (v108_ - 1) * (self.numTimesPerKeyframe + 1) + 1
		local v116_ = time - v106_.time
		local v117_, v118_ = self:getInterval(v116_, self.segmentTimes, v115_, self.numTimesPerKeyframe + 1)
		local v119_ = self.segmentTimes[v118_ + v115_] - self.segmentTimes[v117_ + v115_]
		if v119_ > 0 then
			v117_ = v117_ + (v116_ - self.segmentTimes[v117_ + v115_]) / v119_
		end
		v114_ = 1 - v117_ / self.numTimesPerKeyframe
	end
	return self:getFromKeyframes(v106_, v107_, v108_, v109_, v114_)
end

-- Local values: beforeFirst, afterSecond, numKeys
function AnimCurve:getFromKeyframes(first, second, firstI, secondI, alpha)
	if self.interpolatorDegree == 2 then
		if self.interpolator == linearInterpolatorN then
			return self.interpolator(first, second, alpha, self.curValues)
		else
			return self.interpolator(first, second, alpha)
		end
	elseif self.interpolatorDegree == 3 then
		local v126_
		if firstI > 1 then
			v126_ = self.keyframes[firstI - 1]
		else
			v126_ = nil
		end
		local v127_
		if secondI < #self.keyframes then
			v127_ = self.keyframes[secondI + 1]
		else
			v127_ = nil
		end
		if self.interpolator == linearInterpolatorN then
			return self.interpolator(first, second, v126_, self.curValues)
		else
			return self.interpolator(first, second, v126_, v127_, alpha)
		end
	else
		return nil
	end
end

-- Local values: low, hi, kk
function AnimCurve:getInterval(time, times, timesOffset, numTimes)
	local v132_ = 0
	while numTimes - v132_ > 1 do
		local v133_ = (numTimes + v132_) / 2
		local v134_ = math.floor(v133_)
		if time < times[v134_ + timesOffset] then
			numTimes = v134_
			v134_ = v132_
		end
		v132_ = v134_
	end
	return v132_, numTimes
end

-- Local values: i, key, keyFrame
function AnimCurve:loadCurveFromXML(xmlFile, baseKey, loadFunc)
	local v139_ = 0
	while true do
		local v140_ = string.format("%s.key(%d)", baseKey, v139_)
		if not hasXMLProperty(xmlFile, v140_) then
			break
		end
		local v141_ = loadFunc(xmlFile, v140_)
		if v141_ ~= nil then
			self:addKeyframe(v141_)
		end
		v139_ = v139_ + 1
	end
end

-- Local values: time, value
function loadInterpolator1Curve(xmlFile, key)
	local v144_ = getXMLFloat(xmlFile, key .. "#time")
	local v145_ = getXMLFloat(xmlFile, key .. "#value")
	return v145_ ~= nil and {
		v145_,
		["time"] = v144_
	} or nil
end

-- Local values: time, values
function loadInterpolator2Curve(xmlFile, key)
	local v148_ = getXMLFloat(xmlFile, key .. "#time")
	local v149_ = string.getVector(getXMLString(xmlFile, key .. "#values"), 2)
	if v149_ == nil then
		return nil
	end
	v149_.time = v148_
	return v149_
end

-- Local values: time, values
function loadInterpolator3Curve(xmlFile, key)
	local v152_ = getXMLFloat(xmlFile, key .. "#time")
	local v153_ = string.getVector(getXMLString(xmlFile, key .. "#values"), 3)
	if v153_ == nil then
		return nil
	end
	v153_.time = v152_
	return v153_
end

-- Local values: time, values
function loadInterpolator4Curve(xmlFile, key)
	local v156_ = getXMLFloat(xmlFile, key .. "#time")
	local v157_ = string.getVector(getXMLString(xmlFile, key .. "#values"), 4)
	if v157_ == nil then
		return nil
	end
	v157_.time = v156_
	return v157_
end

function getLoadNamedInterpolatorCurve(names)
	return function(p159_, p160_)
		-- upvalues: (copy) names
		local v161_ = getXMLString(p159_, p160_ .. "#time")
		local v162_ = {}
		for _, v163_ in ipairs(names) do
			local v164_ = getXMLString(p159_, p160_ .. "#" .. v163_)
			if v164_ == nil then
				return nil
			end
			local v165_ = tonumber(v164_)
			table.insert(v162_, v165_)
		end
		v162_.time = tonumber(v161_)
		return v162_
	end
end
